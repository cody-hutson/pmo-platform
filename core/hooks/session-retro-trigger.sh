#!/usr/bin/env bash
# session-retro-trigger.sh — Stop hook that samples session boundaries and, when
# the operator has ACTIVATED it, asks the agent to run the `session-retro` skill
# before the session actually stops.
#
# hook-owner: core/skills/session-retro/references/sampling-and-trigger.md
#
# SHIPPED INERT. Per the v3.80 Collective Review decision D2(a), this release
# ships the hook SCRIPT and its settings-template registration, but NOT its
# activation: `[session_retro] enabled` defaults to false and `mode` defaults to
# "warn", so on every instance that has not opted in this hook reads config,
# exits 0, and changes nothing. Activation is two deliberate operator edits to
# operator.toml (enabled = true, then mode = "enforce" after the warn window).
#
# WHY `Stop` AND NOT `SessionEnd`: a shell hook cannot make the agent reason, and
# the retro IS a reflection. `Stop` is the only boundary hook that can re-enter
# the agent loop (via {"decision":"block","reason":…}); SessionEnd is cleanup-only.
# Full rationale: core/skills/session-retro/references/sampling-and-trigger.md § 4.
#
# `Stop` fires at EVERY assistant-turn boundary, not once per session, so a
# once-per-session sentinel is mandatory — without it the hook re-fires every
# turn AND the retro's own closing turn re-triggers it (an unbounded loop). The
# sentinel is written BEFORE the block decision is emitted, so even a retro that
# fails midway cannot loop.
#
# THE SENTINEL IS WRITTEN ON THE FIRE PATH ONLY. A guard written on the SKIP path
# decides the sampling predicate at turn 1 — structurally the least substantive
# turn of any session — and freezes it there, so the session can never become
# eligible as it grows. That conflation (one file acting as both the anti-loop
# guard, which must be terminal, and the sampling memo, which must not be) is the
# defect this hook was rewritten to close. The harness's own `stop_hook_active`
# flag is the native re-entry guard; do not hand-roll a replacement for it, and
# do not give the fire sentinel a second job.
#
# WHAT A `Stop` HOOK CAN AND CANNOT OBSERVE. It cannot observe session-terminality:
# every `Stop` is structurally identical and the last one is knowable only in
# hindsight. So this hook does NOT fire "at the end of the session" — it fires at
# the FIRST `Stop` at which the session clears the sampling threshold (a threshold
# CROSSING). That is the latest point that is both observable and guaranteed to
# occur; waiting longer trades "fires early" for "may never fire".
#
# FAIL-OPEN, ALWAYS. Every error path exits 0 with no decision. A telemetry
# trigger must never be able to wedge a session; there is no input for which this
# hook blocks work. Fail-QUIET is the companion rule: when session size cannot be
# determined, the session looks trivial and the hook SKIPS. It never fires on noise.
#
# Usage: invoked by the Claude Code harness with the Stop payload on stdin.
#        ./session-retro-trigger.sh --self-test   runs unit tests, no side effects
#
# Exit codes: 0 always (fail-open contract). A fire decision is carried in the
#             JSON emitted on stdout, never in the exit status.

set -uo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Hook-local state (sentinels + the warn-mode verdict log) lives beside the other
# hook state files (.mode, block-log.jsonl, skill-edit-warn-log.jsonl).
STATE_DIR="${SESSION_RETRO_STATE_DIR:-$SCRIPT_DIR/.session-retro-state}"

# State layout — two SINGLE-PURPOSE records, deliberately not one file:
#   fired/<session_id>    terminal. Written ONLY on the fire path, BEFORE the
#                         decision is emitted. Means "this session has fired";
#                         every later Stop in the session is a no-op.
#   stopcount/<session_id> non-terminal, FALLBACK ONLY. A per-session Stop tally,
#                         touched only when the transcript cannot be read.
#   verdict-log.tsv       append-only record of would-fire verdicts (warn mode).
#
# The skip path writes NOTHING. That is the whole point: a skip must leave the
# decision OPEN for the next Stop.
FIRED_DIR="$STATE_DIR/fired"
STOPCOUNT_DIR="$STATE_DIR/stopcount"
VERDICT_LOG="$STATE_DIR/verdict-log.tsv"

# Upper bound on the transcript bytes we will scan. Real transcripts run ~2 MB
# median and ~8 MB at the tail, so this is ~8x headroom; it exists only so a
# pathological file cannot stall a Stop, never as a tuning knob.
MAX_TRANSCRIPT_BYTES="${SESSION_RETRO_MAX_TRANSCRIPT_BYTES:-67108864}"

# operator.toml is the config surface (env override exists for the self-test).
OPERATOR_TOML="${PMO_OPERATOR_TOML:-${HOME}/.config/pmo-platform/operator.toml}"

# ─── Config resolution ───────────────────────────────────────────────────────
#
# Reads the `[session_retro]` block only — a bare grep would match a same-named
# key in another table. Section-scoped awk, defaults on absence. An absent block
# resolves to the inert defaults, which is the activation boundary (D2(a)).

# read_cfg <key> <default> — value of <key> inside [session_retro], or <default>.
read_cfg() {
  local key="$1" default="$2" val=""
  if [[ -r "$OPERATOR_TOML" ]]; then
    val="$(awk -v k="$key" '
      /^[[:space:]]*\[/ { in_s = ($0 ~ /^[[:space:]]*\[session_retro\]/) ? 1 : 0; next }
      in_s && $0 ~ ("^[[:space:]]*" k "[[:space:]]*=") {
        sub(/^[^=]*=[[:space:]]*/, "", $0)
        sub(/[[:space:]]*(#.*)?$/, "", $0)
        gsub(/"/, "", $0)
        print $0
        exit
      }
    ' "$OPERATOR_TOML" 2>/dev/null)" || val=""
  fi
  [[ -n "$val" ]] && printf '%s' "$val" || printf '%s' "$default"
}

# ─── Session-size derivation (the sampling INPUT SOURCE) ─────────────────────
#
# The predicate is computed from the TRANSCRIPT the Stop payload points at, not
# from payload counters. `transcript_path` is a key the payload actually carries;
# `tool_call_count` / `turn_count` never were, which is why an activated hook
# could never fire at the shipped default.
#
# Both counts are derived line-oriented (grep/sort/wc) rather than with a JSON
# parser: jq is not guaranteed present and a missing dependency must not wedge
# Stop. The transcript is JSONL, one entry per line, serialized compactly (no
# space after ':'), which is what makes the literal key match reliable.
#
# turns       = COUNT OF DISTINCT `requestId` values across the transcript.
#               One API request is one assistant turn. Note this is deliberately
#               NOT "count of assistant-role entries": Claude Code writes one
#               JSONL entry per CONTENT BLOCK (thinking / text / tool_use), so
#               assistant entries run ~3x the true turn count and would make
#               `min_turns` fire roughly three times earlier than the operator's
#               setting reads. Measured across the local transcript corpus:
#               median 188 assistant entries vs 61 distinct requestIds (~2.9x).
# tool_calls  = count of `"type":"tool_use"` occurrences.
#
# Both are monotone in session size, which is all the predicate needs.

# derive_counts <transcript_path> — prints "<tool_calls> <turns>", or nothing when
# the transcript cannot be read (the caller then falls back).
derive_counts() {
  local tp="$1" bytes tc tn
  [[ -n "$tp" && -r "$tp" && -f "$tp" ]] || return 1

  # Oversize guard. An unreadable size is treated as oversize (fail-quiet).
  bytes="$(wc -c < "$tp" 2>/dev/null | tr -d ' ')" || return 1
  [[ "$bytes" =~ ^[0-9]+$ ]] || return 1
  [[ "$bytes" -le "$MAX_TRANSCRIPT_BYTES" ]] || return 1

  # grep -o counts OCCURRENCES, not matching lines — correct even if a future
  # transcript format packs several content blocks onto one line.
  tc="$(grep -o '"type":"tool_use"' "$tp" 2>/dev/null | wc -l | tr -d ' ')"
  tn="$(grep -o '"requestId":"[^"]*"' "$tp" 2>/dev/null | sort -u | wc -l | tr -d ' ')"

  [[ "$tc" =~ ^[0-9]+$ ]] || tc=0
  [[ "$tn" =~ ^[0-9]+$ ]] || tn=0
  printf '%s %s' "$tc" "$tn"
}

# bump_stop_count <session_id> — FALLBACK ONLY (unreadable/oversize/absent
# transcript). Tallies Stops for this session and echoes the new count, used as a
# turn proxy. tool_calls is not derivable this way and is reported as 0, so under
# `almost_all` the turn axis alone must carry — and under `significant_only` the
# session simply skips, which is the safe direction.
#
# This is the ONLY per-turn write in the hook and it is deliberately confined to
# the fallback path. It is a DERIVED, IDEMPOTENT-IN-EFFECT progress tally, not a
# decision memo: re-deriving it changes nothing about whether the session already
# fired. Do not merge it with fired/<session_id>, and do not promote it onto the
# happy path — conflating a progress counter with a decision record is exactly
# the defect this hook was rewritten to remove.
bump_stop_count() {
  local sid="$1" f n
  mkdir -p "$STOPCOUNT_DIR" 2>/dev/null || { printf '0'; return 0; }
  f="$STOPCOUNT_DIR/$sid"
  n="$(cat "$f" 2>/dev/null || printf '0')"
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  n=$((n + 1))
  printf '%s' "$n" > "$f" 2>/dev/null || true
  printf '%s' "$n"
}

# ─── Sampling predicate ──────────────────────────────────────────────────────
#
# should_run <sample> <tool_calls> <turns> <min_tool_calls> <min_turns>
#   -> exit 0 = run, 1 = skip.
# Deterministic, metadata-only (no content inspection, no model call) — that is
# what makes it cheap enough to evaluate on every Stop.
should_run() {
  local sample="$1" tc="$2" tn="$3" min_tc="$4" min_tn="$5"
  # Non-numeric metadata is treated as "unknown" -> 0, which makes an unknown
  # session look trivial and therefore SKIP. Fail-quiet, never fire on noise.
  [[ "$tc" =~ ^[0-9]+$ ]] || tc=0
  [[ "$tn" =~ ^[0-9]+$ ]] || tn=0
  case "$sample" in
    all) return 0 ;;
    significant_only)
      [[ "$tc" -ge "$min_tc" && "$tn" -ge "$min_tn" ]] && return 0
      return 1
      ;;
    almost_all|*)
      # Skip ONLY when trivial on BOTH axes.
      [[ "$tc" -lt "$min_tc" && "$tn" -lt "$min_tn" ]] && return 1
      return 0
      ;;
  esac
}

# ─── Self-test ───────────────────────────────────────────────────────────────

run_self_test() {
  echo "self-test: starting"
  local fails=0
  _assert() {  # _assert <label> <expected 0|1> <actual 0|1>
    if [[ "$2" != "$3" ]]; then
      echo "  FAIL: $1 (expected exit $2, got $3)"
      fails=$((fails + 1))
    fi
  }

  # Sampling predicate — almost_all (default)
  should_run almost_all 20 10 12 4; _assert "almost_all: busy session runs" 0 $?
  should_run almost_all 20  1 12 4; _assert "almost_all: tool-heavy short session runs" 0 $?
  should_run almost_all  1 10 12 4; _assert "almost_all: talk-heavy session runs" 0 $?
  should_run almost_all  2  1 12 4; _assert "almost_all: trivial-on-both skips" 1 $?

  # significant_only — both floors required
  should_run significant_only 20 10 12 4; _assert "significant_only: both met runs" 0 $?
  should_run significant_only 20  1 12 4; _assert "significant_only: turns short skips" 1 $?
  should_run significant_only  2 10 12 4; _assert "significant_only: tools short skips" 1 $?

  # all — never skips, including the trivial case
  should_run all 0 0 12 4; _assert "all: trivial still runs" 0 $?

  # Unknown/garbage metadata is treated as trivial -> skip (fail-quiet)
  should_run almost_all "" "" 12 4;      _assert "almost_all: empty metadata skips" 1 $?
  should_run almost_all "abc" "-" 12 4;  _assert "almost_all: garbage metadata skips" 1 $?

  # Config resolution — absent file yields the INERT defaults (the D2(a) boundary)
  local saved_toml="$OPERATOR_TOML"
  OPERATOR_TOML="/nonexistent/operator.toml"
  [[ "$(read_cfg enabled false)" == "false" ]] || { echo "  FAIL: absent config must default enabled=false"; fails=$((fails + 1)); }
  [[ "$(read_cfg mode warn)" == "warn" ]]      || { echo "  FAIL: absent config must default mode=warn"; fails=$((fails + 1)); }

  # Config resolution — section-scoped: a same-named key in ANOTHER table must
  # not leak in (the bare-grep failure this awk exists to prevent).
  local tmp_toml
  tmp_toml="$(mktemp)" || { echo "  FAIL: mktemp"; fails=$((fails + 1)); }
  {
    echo '[automation]'
    echo 'enabled = true'
    echo ''
    echo '[session_retro]'
    echo 'enabled = false'
    echo 'mode = "enforce"'
    echo 'sample = "significant_only"'
    echo 'min_tool_calls = 30'
  } > "$tmp_toml"
  OPERATOR_TOML="$tmp_toml"
  [[ "$(read_cfg enabled true)" == "false" ]]            || { echo "  FAIL: section-scoped enabled read (leaked from [automation])"; fails=$((fails + 1)); }
  [[ "$(read_cfg mode warn)" == "enforce" ]]             || { echo "  FAIL: mode read"; fails=$((fails + 1)); }
  [[ "$(read_cfg sample almost_all)" == "significant_only" ]] || { echo "  FAIL: sample read"; fails=$((fails + 1)); }
  [[ "$(read_cfg min_tool_calls 12)" == "30" ]]          || { echo "  FAIL: min_tool_calls read"; fails=$((fails + 1)); }
  [[ "$(read_cfg missing_key fallback)" == "fallback" ]] || { echo "  FAIL: missing key must fall back"; fails=$((fails + 1)); }
  rm -f "$tmp_toml"
  OPERATOR_TOML="$saved_toml"

  # ── The PINNED payload fixture (R1) ────────────────────────────────────────
  #
  # Every end-to-end case below is driven from core/hooks/tests/fixtures/stop-payload.json,
  # which mirrors the LIVE harness contract rather than this script's assumptions.
  # A fixture built from the code's own premise cannot falsify that premise —
  # which is exactly how a predicate reading two non-existent payload fields
  # passed its own self-test.
  local self="${BASH_SOURCE[0]}"
  local fixture="$SCRIPT_DIR/tests/fixtures/stop-payload.json"
  local st_state out rc

  if [[ ! -r "$fixture" ]]; then
    echo "  FAIL: pinned Stop-payload fixture missing at $fixture"
    fails=$((fails + 1))
  else
    # R2 — NEGATIVE CONTROL. The payload has never carried these keys. If a future
    # editor re-introduces counter-reading and "fixes" the fixture to match, this
    # assertion fails first. This is the guard against repeating the original sin.
    if grep -q 'tool_call_count\|turn_count' "$fixture"; then
      echo "  FAIL: fixture must NOT contain tool_call_count/turn_count (the keys the Stop payload does not carry)"
      fails=$((fails + 1))
    fi
    # Positive control on the same fixture: the keys the payload DOES carry.
    local k
    for k in session_id transcript_path cwd hook_event_name stop_hook_active; do
      grep -q "\"$k\"" "$fixture" || { echo "  FAIL: fixture missing pinned key '$k'"; fails=$((fails + 1)); }
    done
  fi

  # payload_for <session_id> <transcript_path> — the pinned fixture with only the
  # session identity and transcript pointer substituted. Every other key keeps the
  # harness-pinned value, so the driver exercises the real payload shape.
  _payload_for() {
    sed -e "s#\"session_id\": \"[^\"]*\"#\"session_id\": \"$1\"#" \
        -e "s#\"transcript_path\": \"[^\"]*\"#\"transcript_path\": \"$2\"#" \
        "$fixture" | tr -d '\n'
  }

  # _append_turns <transcript> <turns_delta> <tools_delta> — grow a REAL transcript
  # JSONL the way Claude Code writes one: one entry per content block, all entries
  # of a turn sharing a requestId. Distinct requestIds == turns; "type":"tool_use"
  # occurrences == tool calls.
  _RQ=0
  _append_turns() {
    local f="$1" nturns="$2" ntools="$3" i
    for (( i = 0; i < nturns; i++ )); do
      _RQ=$((_RQ + 1))
      printf '{"type":"assistant","requestId":"req_%03d","message":{"role":"assistant","content":[{"type":"text","text":"t"}]}}\n' "$_RQ" >> "$f"
    done
    for (( i = 0; i < ntools; i++ )); do
      printf '{"type":"assistant","requestId":"req_%03d","message":{"role":"assistant","content":[{"type":"tool_use","name":"Bash","input":{}}]}}\n' "$_RQ" >> "$f"
    done
  }

  # _drive <sample> <mode> — run the issue's own 3/1 -> 9/3 -> 40/12 -> 95/28
  # sequence against ONE state dir and ONE growing transcript, invoking the REAL
  # script once per Stop. Echoes one line per Stop: "fire" or "silent".
  #
  # This is the shape the old self-test lacked. It drove the hook ONCE, against a
  # pure function, with invented counters — so it could not observe that the
  # predicate was decided at turn 1 and frozen.
  _drive() {
    local sample="$1" mode="$2" toml state tr o step
    toml="$(mktemp)"; state="$(mktemp -d)"; tr="$(mktemp -d)/transcript.jsonl"
    : > "$tr"
    printf '%s\n' '[session_retro]' 'enabled = true' "mode = \"$mode\"" "sample = \"$sample\"" > "$toml"
    # Seed a satisfied warn window (a prior session's would-fire verdict), which
    # is the real posture at the moment an operator flips to enforce. Without it
    # the PA-6 gate would degrade the first crossing and this driver would be
    # measuring PA-6 instead of the fire-point ordering it exists to measure.
    # PA-6 itself is asserted separately below, on a deliberately virgin state dir.
    printf '%s\t%s\t%s\t%s\n' "2026-01-01T00:00:00Z" "prior-session" "would-fire" "sample=$sample" \
      > "$state/verdict-log.tsv"
    _RQ=0
    # cumulative targets  3/1   9/3   40/12   95/28   ->  deltas below
    local turns_d=(1 2 9 16) tools_d=(3 6 31 55)
    for step in 0 1 2 3; do
      _append_turns "$tr" "${turns_d[$step]}" "${tools_d[$step]}"
      o="$(_payload_for "drv-$sample" "$tr" | PMO_OPERATOR_TOML="$toml" \
           SESSION_RETRO_STATE_DIR="$state" bash "$self" 2>/dev/null)"
      if printf '%s' "$o" | grep -q '"decision"'; then echo "fire"; else echo "silent"; fi
    done
    # R6 — after the fire, a Stop carrying stop_hook_active:true emits nothing.
    o="$(_payload_for "drv-$sample" "$tr" | sed 's/"stop_hook_active": false/"stop_hook_active": true/' \
         | PMO_OPERATOR_TOML="$toml" SESSION_RETRO_STATE_DIR="$state" bash "$self" 2>/dev/null)"
    if printf '%s' "$o" | grep -q '"decision"'; then echo "fire"; else echo "silent"; fi
    rm -rf "$state" "$(dirname "$tr")"; rm -f "$toml"
  }

  # (a) SHIPPED POSTURE: no [session_retro] block -> no decision, exit 0.
  st_state="$(mktemp -d)"
  out="$(_payload_for selftest-inert /nonexistent/transcript.jsonl \
        | PMO_OPERATOR_TOML=/nonexistent/operator.toml \
          SESSION_RETRO_STATE_DIR="$st_state" bash "$self" 2>/dev/null)"; rc=$?
  [[ -z "$out" && "$rc" -eq 0 ]] || { echo "  FAIL: inert default must emit no decision and exit 0 (rc=$rc out=$out)"; fails=$((fails + 1)); }
  rm -rf "$st_state"

  # ── R4: the multi-Stop sequence under `almost_all` (the shipped default) ────
  # THE load-bearing assertion. Stop 1 and Stop 2 are trivial on BOTH axes and
  # must skip WITHOUT writing any sentinel; Stop 3 crosses the tool-call floor and
  # must FIRE; Stop 4 must be a silent no-op because the session already fired.
  # A self-test that passes without this sequence executing is not a pass.
  local seq
  seq="$(_drive almost_all enforce | tr '\n' ',')"
  [[ "$seq" == "silent,silent,fire,silent,silent," ]] \
    || { echo "  FAIL: almost_all multi-Stop sequence expected silent,silent,fire,silent,silent got '$seq'"; fails=$((fails + 1)); }

  # ── R5: predicate x ordering interaction ───────────────────────────────────
  # significant_only needs BOTH floors, so it must NOT fire at Stop 2 (9/3) and
  # must fire at Stop 3 (40/12).
  seq="$(_drive significant_only enforce | tr '\n' ',')"
  [[ "$seq" == "silent,silent,fire,silent,silent," ]] \
    || { echo "  FAIL: significant_only multi-Stop sequence expected silent,silent,fire,silent,silent got '$seq'"; fails=$((fails + 1)); }

  # `all` ignores the floors entirely -> fires at Stop 1, exactly once.
  seq="$(_drive all enforce | tr '\n' ',')"
  [[ "$seq" == "fire,silent,silent,silent,silent," ]] \
    || { echo "  FAIL: all multi-Stop sequence expected fire,silent,silent,silent,silent got '$seq'"; fails=$((fails + 1)); }

  # ── The skip path must leave NO state (the QA-1 regression guard) ───────────
  # If a skip writes any per-session record, the predicate freezes at turn 1 and
  # the session can never become eligible. Assert the skip is genuinely stateless.
  local sk_toml sk_state sk_tr
  sk_toml="$(mktemp)"; sk_state="$(mktemp -d)"; sk_tr="$(mktemp -d)/t.jsonl"; : > "$sk_tr"
  printf '%s\n' '[session_retro]' 'enabled = true' 'mode = "warn"' 'sample = "almost_all"' > "$sk_toml"
  _RQ=0; _append_turns "$sk_tr" 1 3          # 3 tool calls / 1 turn -> trivial on both
  _payload_for skip-probe "$sk_tr" | PMO_OPERATOR_TOML="$sk_toml" \
    SESSION_RETRO_STATE_DIR="$sk_state" bash "$self" >/dev/null 2>&1
  [[ ! -e "$sk_state/fired/skip-probe" ]] \
    || { echo "  FAIL: a SKIP must not write the fire sentinel (that is the freeze-at-turn-1 defect)"; fails=$((fails + 1)); }
  [[ ! -s "$sk_state/verdict-log.tsv" ]] \
    || { echo "  FAIL: a SKIP must not record a would-fire verdict"; fails=$((fails + 1)); }
  rm -rf "$sk_state" "$(dirname "$sk_tr")"; rm -f "$sk_toml"

  # ── PA-6: enforce degrades to warn until the warn window is satisfied ───────
  # The FIRST enforce-mode crossing on a fresh state dir has no recorded verdict,
  # so it must NOT emit a block decision — it records `warn-window-unsatisfied`
  # instead. A refusal that emitted nothing would be indistinguishable from the
  # bug being fixed, so the degrade is deliberately observable.
  local ww_toml ww_state ww_tr ww_out
  ww_toml="$(mktemp)"; ww_state="$(mktemp -d)"; ww_tr="$(mktemp -d)/t.jsonl"; : > "$ww_tr"
  printf '%s\n' '[session_retro]' 'enabled = true' 'mode = "enforce"' 'sample = "all"' > "$ww_toml"
  _RQ=0; _append_turns "$ww_tr" 5 20
  ww_out="$(_payload_for ww-1 "$ww_tr" | PMO_OPERATOR_TOML="$ww_toml" \
            SESSION_RETRO_STATE_DIR="$ww_state" bash "$self" 2>/dev/null)"
  [[ -z "$ww_out" ]] \
    || { echo "  FAIL: enforce must degrade to warn on an unsatisfied warn window (got: $ww_out)"; fails=$((fails + 1)); }
  grep -q 'warn-window-unsatisfied' "$ww_state/verdict-log.tsv" 2>/dev/null \
    || { echo "  FAIL: the degrade must record warn-window-unsatisfied in the verdict log"; fails=$((fails + 1)); }
  # A SECOND session now finds a non-empty verdict log -> the window is satisfied
  # and enforce is permitted to emit the block decision.
  ww_out="$(_payload_for ww-2 "$ww_tr" | PMO_OPERATOR_TOML="$ww_toml" \
            SESSION_RETRO_STATE_DIR="$ww_state" bash "$self" 2>/dev/null)"
  printf '%s' "$ww_out" | grep -q '"decision"[[:space:]]*:[[:space:]]*"block"' \
    || { echo "  FAIL: enforce must emit the block decision once the warn window is satisfied (got: $ww_out)"; fails=$((fails + 1)); }
  rm -rf "$ww_state" "$(dirname "$ww_tr")"; rm -f "$ww_toml"

  # ── Fail-quiet: an unreadable transcript must SKIP, never fire ──────────────
  local fq_toml fq_state fq_out
  fq_toml="$(mktemp)"; fq_state="$(mktemp -d)"
  printf '%s\n' '[session_retro]' 'enabled = true' 'mode = "enforce"' 'sample = "almost_all"' > "$fq_toml"
  fq_out="$(_payload_for fq-1 /nonexistent/transcript.jsonl | PMO_OPERATOR_TOML="$fq_toml" \
            SESSION_RETRO_STATE_DIR="$fq_state" bash "$self" 2>/dev/null)"
  [[ -z "$fq_out" ]] \
    || { echo "  FAIL: an unreadable transcript must skip, never fire (got: $fq_out)"; fails=$((fails + 1)); }
  rm -rf "$fq_state"; rm -f "$fq_toml"

  # ── R7: MUTATION CHECK (documented reviewer procedure, not an assertion) ────
  # To prove this test has the power to fail, restore the old behaviour by hand:
  #   1. In the hook body, move the `: > "$FIRED_SENTINEL"` write ABOVE the
  #      `should_run` check (i.e. write the sentinel on the skip path too).
  #   2. Re-run `./session-retro-trigger.sh --self-test`.
  #   3. The almost_all sequence MUST change from silent,silent,fire,... to
  #      silent,silent,silent,... — Stop 3 stops firing, and the R4 assertion
  #      fails. If it still passes, this test is not testing what it claims.
  # Wiring that switch into the production hook to automate the check would be its
  # own debt, so it stays a one-edit manual falsification.

  if [[ "$fails" -gt 0 ]]; then
    echo "self-test: FAIL ($fails assertion(s))"
    exit 1
  fi
  echo "self-test: PASS"
  echo "  sampling predicate validated (all / almost_all / significant_only + garbage metadata)"
  echo "  section-scoped [session_retro] config read validated (no cross-table leak)"
  echo "  inert-by-default posture validated (absent config -> no decision, exit 0)"
  echo "  pinned Stop-payload fixture validated (+ negative control: no tool_call_count/turn_count)"
  echo "  multi-Stop sequence 3/1 -> 9/3 -> 40/12 -> 95/28 drives the REAL script against a REAL transcript:"
  echo "    almost_all      -> skip, skip, FIRE at Stop 3, no-op, no-op"
  echo "    significant_only-> skip, skip, FIRE at Stop 3, no-op, no-op"
  echo "    all             -> FIRE at Stop 1, then no-op"
  echo "  skip path writes NO state (predicate is re-evaluated, not frozen at turn 1)"
  echo "  stop_hook_active re-entry guard validated (retro's own closing turn emits nothing)"
  echo "  enforce degrades to warn until the verdict log holds a would-fire row"
  echo "  fail-quiet validated (unreadable transcript skips, never fires)"
  exit 0
}

if [[ "${1:-}" == "--self-test" ]]; then
  run_self_test
fi

# ─── Hook body ───────────────────────────────────────────────────────────────

# 1. Activation gate FIRST — cheapest possible exit for the overwhelmingly common
#    case (the feature is off). Nothing below runs on an un-opted-in instance.
ENABLED="$(read_cfg enabled false)"
MODE="$(read_cfg mode warn)"
[[ "$ENABLED" == "true" ]] || exit 0
[[ "$MODE" == "off" ]] && exit 0

# 2. Read the Stop payload. Never fail on malformed input.
PAYLOAD="$(cat 2>/dev/null || true)"

# Extract fields with a tolerant scalar-key match (no jq dependency in the hook
# path; jq is not guaranteed present and a missing dependency must not wedge Stop).
json_str() {  # json_str <key>
  printf '%s' "$PAYLOAD" | sed -n -E 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -1
}
json_bool() {  # json_bool <key> — prints true/false, empty when absent
  printf '%s' "$PAYLOAD" | sed -n -E 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*(true|false).*/\1/p' | head -1
}

# 3. Native re-entry guard. `stop_hook_active` is true precisely when the agent is
#    continuing BECAUSE a Stop hook blocked — i.e. this Stop is the retro's own
#    closing turn. This is the harness's own flag; it runs before any state read.
#    It is ADDITIVE safety: correctness does not depend on it (the fired/ sentinel
#    already covers the same case), so an absent key changes nothing.
[[ "$(json_bool stop_hook_active)" == "true" ]] && exit 0

SESSION_ID="$(json_str session_id)"
[[ -n "$SESSION_ID" ]] || exit 0                      # no session identity -> cannot sentinel -> do nothing
SESSION_ID="$(printf '%s' "$SESSION_ID" | tr -cd 'A-Za-z0-9._-')"
[[ -n "$SESSION_ID" ]] || exit 0

# 4. Fire sentinel — TERMINAL, and checked before any work. Its ONLY meaning is
#    "this session has already fired". A skip never writes it, so a session that
#    has not yet cleared the threshold is re-evaluated on every later Stop.
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
FIRED_SENTINEL="$FIRED_DIR/$SESSION_ID"
[[ -e "$FIRED_SENTINEL" ]] && exit 0

# 5. Derive session size from the transcript; fall back to a Stop tally when the
#    transcript cannot be read. Fail-quiet: an underivable session looks trivial.
TRANSCRIPT_PATH="$(json_str transcript_path)"
SAMPLE="$(read_cfg sample almost_all)"
MIN_TOOL_CALLS="$(read_cfg min_tool_calls 12)"
MIN_TURNS="$(read_cfg min_turns 4)"
[[ "$MIN_TOOL_CALLS" =~ ^[0-9]+$ ]] || MIN_TOOL_CALLS=12
[[ "$MIN_TURNS"      =~ ^[0-9]+$ ]] || MIN_TURNS=4

SIZE_SOURCE="transcript"
if _counts="$(derive_counts "$TRANSCRIPT_PATH")" && [[ -n "$_counts" ]]; then
  TOOL_CALLS="${_counts%% *}"
  TURNS="${_counts##* }"
else
  SIZE_SOURCE="stop-count-fallback"
  TOOL_CALLS=0
  TURNS="$(bump_stop_count "$SESSION_ID")"
fi

# 6. Predicate FAILS -> write NOTHING and exit. The decision stays open for the
#    next Stop, which is the entire correction: the session is re-evaluated as it
#    grows instead of being judged at its least substantive turn.
if ! should_run "$SAMPLE" "${TOOL_CALLS:-0}" "${TURNS:-0}" "$MIN_TOOL_CALLS" "$MIN_TURNS"; then
  exit 0
fi

# 7. Predicate PASSES -> this is the threshold crossing. Write the fire sentinel
#    FIRST, before any decision is emitted, so a retro that fails midway — or the
#    retro's own closing turn — cannot re-trigger.
mkdir -p "$FIRED_DIR" 2>/dev/null || exit 0
: > "$FIRED_SENTINEL" 2>/dev/null || true

VERDICT_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 8. `enforce` requires a satisfied warn window: at least one would-fire verdict
#    must already be recorded. The verdict log only accrues a row when the
#    predicate PASSES, so >=1 row proves an end-to-end path (activation ->
#    derivation -> predicate -> verdict) actually worked on a real session.
#
#    On an unsatisfied window we DEGRADE to warn rather than refuse. A refusal
#    that emits nothing is observationally identical to the bug being fixed;
#    degrading AND recording why is observable. Never a hard failure (fail-open).
WARN_WINDOW_OK=false
if [[ -s "$VERDICT_LOG" ]] && grep -q 'would-fire' "$VERDICT_LOG" 2>/dev/null; then
  WARN_WINDOW_OK=true
fi

if [[ "$MODE" == "enforce" && "$WARN_WINDOW_OK" != "true" ]]; then
  mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
  printf '%s\t%s\t%s\t%s\n' \
    "$VERDICT_TS" "$SESSION_ID" "would-fire" \
    "sample=$SAMPLE; size=$SIZE_SOURCE; tool_calls=$TOOL_CALLS; turns=$TURNS; warn-window-unsatisfied" \
    >> "$VERDICT_LOG" 2>/dev/null || true
  exit 0
fi

# 9. Warn mode records the verdict and stops; enforce mode re-enters the agent.
if [[ "$MODE" != "enforce" ]]; then
  printf '%s\t%s\t%s\t%s\n' \
    "$VERDICT_TS" "$SESSION_ID" "would-fire" \
    "sample=$SAMPLE; size=$SIZE_SOURCE; tool_calls=$TOOL_CALLS; turns=$TURNS" \
    >> "$VERDICT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\n' '{"decision":"block","reason":"This session cleared the session-retro sampling threshold. Run the session-retro skill now: reflect on this session, emit any session-grained learnings (or an explicit no-learning row) via release/tools/append-pipeline-event.sh, then stop. Signal-only — make no other change."}'
exit 0
