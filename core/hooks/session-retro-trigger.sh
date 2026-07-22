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
# FAIL-OPEN, ALWAYS. Every error path exits 0 with no decision. A telemetry
# trigger must never be able to wedge a session; there is no input for which this
# hook blocks work.
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

  # End-to-end. Three runs against the real script, each in its own state dir.
  local self="${BASH_SOURCE[0]}" st_state out rc
  local stop_payload='{"session_id":"selftest-1","tool_call_count":40,"turn_count":9}'

  # (a) SHIPPED POSTURE: no [session_retro] block -> no decision, exit 0.
  st_state="$(mktemp -d)"
  out="$(printf '%s' "$stop_payload" | PMO_OPERATOR_TOML=/nonexistent/operator.toml \
        SESSION_RETRO_STATE_DIR="$st_state" bash "$self" 2>/dev/null)"; rc=$?
  [[ -z "$out" && "$rc" -eq 0 ]] || { echo "  FAIL: inert default must emit no decision and exit 0 (rc=$rc out=$out)"; fails=$((fails + 1)); }
  rm -rf "$st_state"

  # (b) ACTIVATED + enforce -> emits the block decision that re-enters the agent.
  tmp_toml="$(mktemp)"
  printf '%s\n' '[session_retro]' 'enabled = true' 'mode = "enforce"' 'sample = "all"' > "$tmp_toml"
  st_state="$(mktemp -d)"
  out="$(printf '%s' "$stop_payload" | PMO_OPERATOR_TOML="$tmp_toml" \
        SESSION_RETRO_STATE_DIR="$st_state" bash "$self" 2>/dev/null)"
  printf '%s' "$out" | grep -q '"decision"[[:space:]]*:[[:space:]]*"block"' \
    || { echo "  FAIL: enforce mode must emit a block decision (got: $out)"; fails=$((fails + 1)); }

  # (c) SENTINEL: the SAME session on a second Stop must be a silent no-op —
  #     without this, Stop re-fires every turn and the retro re-triggers itself.
  out="$(printf '%s' "$stop_payload" | PMO_OPERATOR_TOML="$tmp_toml" \
        SESSION_RETRO_STATE_DIR="$st_state" bash "$self" 2>/dev/null)"
  [[ -z "$out" ]] || { echo "  FAIL: sentinel must suppress the second Stop in a session (got: $out)"; fails=$((fails + 1)); }
  rm -rf "$st_state"; rm -f "$tmp_toml"

  if [[ "$fails" -gt 0 ]]; then
    echo "self-test: FAIL ($fails assertion(s))"
    exit 1
  fi
  echo "self-test: PASS"
  echo "  sampling predicate validated (all / almost_all / significant_only + garbage metadata)"
  echo "  section-scoped [session_retro] config read validated (no cross-table leak)"
  echo "  inert-by-default posture validated (absent config -> no decision, exit 0)"
  echo "  activated+enforce emits the block decision; once-per-session sentinel suppresses re-fire"
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
json_num() {  # json_num <key>
  printf '%s' "$PAYLOAD" | sed -n -E 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' | head -1
}

SESSION_ID="$(json_str session_id)"
[[ -n "$SESSION_ID" ]] || exit 0                      # no session identity -> cannot sentinel -> do nothing
SESSION_ID="$(printf '%s' "$SESSION_ID" | tr -cd 'A-Za-z0-9._-')"
[[ -n "$SESSION_ID" ]] || exit 0

# 3. Once-per-session sentinel. Written BEFORE any decision is emitted so that a
#    retro that fails midway — or the retro's own closing turn — cannot re-trigger.
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
SENTINEL="$STATE_DIR/$SESSION_ID"
[[ -e "$SENTINEL" ]] && exit 0

# 4. Sampling predicate over session metadata.
TOOL_CALLS="$(json_num tool_call_count)"
TURNS="$(json_num turn_count)"
SAMPLE="$(read_cfg sample almost_all)"
MIN_TOOL_CALLS="$(read_cfg min_tool_calls 12)"
MIN_TURNS="$(read_cfg min_turns 4)"
[[ "$MIN_TOOL_CALLS" =~ ^[0-9]+$ ]] || MIN_TOOL_CALLS=12
[[ "$MIN_TURNS"      =~ ^[0-9]+$ ]] || MIN_TURNS=4

if ! should_run "$SAMPLE" "${TOOL_CALLS:-0}" "${TURNS:-0}" "$MIN_TOOL_CALLS" "$MIN_TURNS"; then
  # A skip emits NOTHING (not a no-learning row) — "did not reflect" is not the
  # same signal as "reflected, found nothing".
  : > "$SENTINEL" 2>/dev/null || true
  exit 0
fi

: > "$SENTINEL" 2>/dev/null || true

# 5. Warn mode records the verdict and stops; enforce mode re-enters the agent.
if [[ "$MODE" != "enforce" ]]; then
  printf '%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION_ID" "would-fire" "sample=$SAMPLE" \
    >> "$STATE_DIR/verdict-log.tsv" 2>/dev/null || true
  exit 0
fi

printf '%s\n' '{"decision":"block","reason":"Session boundary reached and this session cleared the session-retro sampling threshold. Run the session-retro skill now: reflect on this session, emit any session-grained learnings (or an explicit no-learning row) via release/tools/append-pipeline-event.sh, then stop. Signal-only — make no other change."}'
exit 0
