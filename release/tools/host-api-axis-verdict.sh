#!/usr/bin/env bash
# selftest-runner: macos
#   Read by release/tools/check-selftest-coverage.py, which runs this tool's --self-test
#   in the "Close-out automation smoke (macOS)" job: a required context, where the
#   ubuntu discovery job is not. The pin is a property of this tool. The gate it
#   implements runs before every spoke launch on the operator's macOS hub, under
#   /bin/bash 3.2, and a regression that merged past an advisory check would make that
#   gate inert or wrong on every launch. Arm BASH32-REPLAY re-runs two replays under
#   /bin/bash 3.x wherever that interpreter is present, because the engine invokes
#   `bash` from PATH and a runner image may resolve a newer one.
#
# host-api-axis-verdict.sh — Checkpoint B's host-API axis, mechanized.
#
# WHAT IT IMPLEMENTS. The host-API axis of the pre-launch quota-budget gate, specified in
# release/references/standards/quota-budget-protocol.md § 4.3b. The hub runs it ONCE per
# routing turn, from the repository root, and reads the axis verdict from the HOST-API
# record only, and only when this tool exits 0. Any other exit is "not evaluated": the
# hub renders basis UNSTATED and the axis fails open. The rule's rationale lives in the
# protocol; this header states what the code does.
#
# THE INSTRUMENT. Metered probes, read in-band: each probe draws from the pool it reads,
# and the reading is the x-ratelimit-* counter the host returns on that same response.
#   core     one REST read of a repository-free endpoint (GET /versions), re-probed once
#            when its reading is not anchored.
#   graphql  two GraphQL reads, issued in sequence, of a query that selects a field
#            beyond the rate-limit object: a rateLimit-only query is not charged in a
#            started window, so it cannot declare a draw. Re-probed once, a third read,
#            when the two do not agree.
# Three metered requests per run, at most five. The pool-status endpoint is not an
# input: it was measured reporting an unstarted window while the enforcing counter
# showed hundreds of requests drawn.
#
# THE ANCHOR. A reading is individually anchored when ALL of these hold:
#   the response was answered (the refusal-reason classifier's class);
#   x-ratelimit-resource names the probed pool;
#   limit, remaining, used and reset are all present;
#   used >= 1 and remaining < limit — the probe's own draw is visible;
#   Date - 120 < reset <= Date + 3600 + 120, where Date is THAT response's own Date
#     header. No Date header, or an unparseable one, means not anchored. The local
#     clock is never read.
# Two GraphQL readings E (earlier) and L (later) AGREE when both are individually
# anchored, reset(L) = reset(E), and used(L) - used(E) >= 1. Other sessions can only add
# to `used`, so a later reading that has not advanced by the later probe's own draw is
# not a report of that probe. The draw clause is necessary, not sufficient: an uncharged
# pair under foreign traffic can pass it, which is why arm CHARGED-PROBE-SHAPE pins the
# query's shape.
#
# THE PROCEDURE, per pool. A quota refusal on any read makes the pool CONTRADICTED: it is
# exhaustion, and it dominates. Other failures do not end the procedure early.
#   core     read 1 anchored -> MEASURED. Otherwise read 2: anchored -> MEASURED.
#            Otherwise UNANCHORED when an answered read carried a counter, else UNSTATED.
#   graphql  reads 1 and 2 agree -> MEASURED from read 2 (agreement=pair). Otherwise read
#            3: agrees with read 2, else with read 1 -> MEASURED from read 3
#            (agreement=reprobe). Otherwise the most conservative individually-anchored
#            reading — the lowest remaining/limit, ties to the latest — is MEASURED
#            (agreement=unresolved, a calibration event). Otherwise UNANCHORED when an
#            answered read carried a counter, else UNSTATED.
# An unstarted-window reading (used 0, a full pool) is never individually anchored, so
# it can never be picked.
#
# BASIS -> VERDICT, per pool.
#   MEASURED      DEFER when remaining < 20 % of limit, otherwise PROCEED
#   UNANCHORED    DEFER; re-run at the next routing turn
#   CONTRADICTED  DEFER; the recovery its evidence supports (below)
#   UNSTATED      PROCEED — fail open, the reason rendered
# The axis renders DEFER when any modeled pool renders DEFER. No verdict token is minted.
#
# RECOVERY, per refused pool. A primary refusal: the refusing response's own reset epoch.
# A secondary refusal carrying retry-after: exactly that many seconds. Nothing published:
# at least min(60 * 2^N, 3600) seconds, N being the prior consecutive-refusal count the
# hub passes as --prior-refusals; never a timestamp. A reset is never borrowed from
# another pool.
#
# GRADES. An anchored core reading is [SOURCE], as a statement of the pool at the moment
# of the probe. An anchored graphql reading is [ASSUMPTION – CONFIRM] until three
# releases after its introduction pass with no calibration event. Headroom at launch is
# [ASSUMPTION – CONFIRM] for both pools: other sessions keep drawing after the probe.
#
# CALIBRATION. Every MEASURED or UNANCHORED pool reports used_zero (answered reads whose
# counter showed used 0), and graphql also reports agreement and reset_disagreements. A
# CALIBRATION EVENT is used_zero >= 1 on either pool, or graphql agreement=unresolved;
# the HOST-API record reports it, and the hub records it as a verification action item.
#
# MODES
#   (no arguments)       live: probe the host named by [adapters].repo_host.
#   --replay DIR         the same parser, classifier, anchor and verdict code, with the
#                        transport swapped for recorded responses: DIR/<pool>.<k>.out,
#                        .err and .rc for pool core|graphql and read k = 1..3. Where a
#                        later read has no file, the highest earlier one repeats.
#   --prior-refusals N   the consecutive-refusal count held on the open host-API DEFER
#                        action item; 0 when none is open. Combines with either mode.
#   --self-test          the hermetic arm suite (offline; replay fixtures only).
#   -h | --help          usage, exit 2.
#
# OUTPUT GRAMMAR (stdout; printed only once the run is complete)
#   HOST-API <PROCEED|DEFER> refusals_in_a_row=<k> calibration_event=<yes|no>
#   POOL <pool> <basis> verdict=<PROCEED|DEFER> reads=<n> <fields> reason=<text>
#   RENDER host-API <verdict> · <one segment per pool>[ · calibration event ...]
# The basis is the first token after the pool, so a consumer branches on it before it
# reads any counter. Counters are absent under UNSTATED and CONTRADICTED; under
# UNANCHORED they appear only as reported_*, never as a remaining figure; the
# calibration fields are absent under UNSTATED and CONTRADICTED, never 0. reason is the
# last field and runs to the end of the line. refusals_in_a_row is N+1 when any pool
# was refused this run, 0 when every modeled pool answered, and N otherwise: a probe
# failed, so the run proves nothing about the limit and the count carries over.
#
# EXIT CONTRACT
#   0  evaluated; the verdict is in the HOST-API record and nowhere else
#   2  usage error, or an [adapters].repo_host value outside the declared value space
#   3  scan-surface error: a library, the key declaration or its value space could not
#      be read, or a replay input is missing
#   any other value — an evaluator fault. There is no "1 = DEFER": bash's default error
#   status is 1, so a crashed evaluator must never read as a verdict.
#
# ADAPTER SELECTION, fresh on every run. The [adapters].repo_host value is read from the
# operator.toml under ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}; when the
# key is absent, the declared default applies. Both the default and the value space are
# parsed from the repo_host key entry inside the adapters section of
# core/config/operator-toml-schema.json. A value outside that value space exits 2: a typo
# is a configuration error, never a silent fallback. A value inside it that no arm below
# implements exits 0 with `POOL - UNSTATED no-probe-for-repo-host=<value>` and a PROCEED:
# it fails open, with the reason rendered, on that install only. The runtime never
# compares the value space with the implemented arms; arm ENUM-PARITY asserts that in CI.
#
# THE GITHUB SEAMS. _host_probe_rest and _host_probe_graphql are the only place a host
# command appears. The budget probe and the refusal-classification binding are named
# gaps of the repo_host interface (core/standards/repo-host-adapter-versioning.md § 3),
# owned by the repository-host abstraction work; until it declares them, they live here,
# behind the selector, and a later lift to an interface operation is a move rather than
# a rewrite. Responses are classified by the shared library
# release/tools/lib/host-refusal-class.sh, whose binding this tool does not restate.
#
# WHAT IT DOES NOT DO. No stored state, no event emission, no polling loop, and no floor
# calibration. The consecutive-refusal count lives on the hub's DEFER action item and
# arrives as an argument; this tool renders the wait and never waits.
#
# TEST SEAMS. PMO_PLATFORM_CONFIG_ROOT selects the operator config root.
# HOST_API_AXIS_SCHEMA overrides the key-declaration path; the self-test uses it for the
# runtime-unimplemented-host arm, and nothing else should.
#
# PORTABILITY. bash-3.2 portable (no associative arrays; empty-array expansions guarded);
# /usr/bin/python3 standard library for header and JSON parsing; no jq; never passes the
# host CLI's cache flag (/versions answers with a 60-second cache-control); no producer
# piped into an early-exiting reader. REPO_ROOT is derived from this file's location,
# never from the working directory.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd "$SCRIPT_DIR/../.." && pwd)"
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

_scan_error() {
  printf 'host-api-axis-verdict: scan-surface error — %s; no verdict is rendered (exit 3)\n' "$1" >&2
  exit 3
}

_fault() {
  printf 'host-api-axis-verdict: evaluator fault — %s; no verdict is rendered\n' "$1" >&2
  exit 1
}

# The libraries are sourced before any work, and a failed source is a scan-surface error:
# an evaluator that cannot classify a response must not render a verdict about one.
_source_lib() {
  if [ -r "$SCRIPT_DIR/lib/$1" ] && . "$SCRIPT_DIR/lib/$1"; then return 0; fi
  _scan_error "cannot source release/tools/lib/$1"
}
_source_lib host-refusal-class.sh
_source_lib platform-toggle.sh
for _fn in host_refusal_class host_response_headers _pt_read_field; do
  declare -F "$_fn" >/dev/null 2>&1 || _scan_error "a sourced library did not define $_fn"
done
unset _fn

# The repo_host values this tool has a probe arm for. The runtime reads this for the
# configured value only; arm ENUM-PARITY asserts it equals the declared value space.
IMPLEMENTED_ARMS="github"

WINDOW=3600
SKEW=120
FLOOR_PCT=20
BACKOFF_BASE=60
BACKOFF_CAP=3600
PRIOR_MAX_DIGITS=9

CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME:-}/.config/pmo-platform}"
SCHEMA="${HOST_API_AXIS_SCHEMA:-$REPO_ROOT/core/config/operator-toml-schema.json}"

MODE="live"
REPLAY_DIR=""
PRIOR=0
EV_TMP=""
HOST=""
HOST_IMPLEMENTED=0

POOL_LINES=""
RENDER_SEGS=""
AXIS_DEFER=0
ANY_REFUSED=0
ANY_FAILED=0
CAL_EVENT=0

# ─── python helper (stdlib only): the key declaration, and one reading ───────────────
# schema FILE   -> "DEFAULT\t<v>" and one "ENUM\t<v>" per value of the repo_host key
#                  entry inside the adapters section; nothing when that entry is absent.
# reading FILE  -> one TAB line, "-" for an absent field (never an empty one):
#                  counter resource limit remaining used reset date retry_after
#                  read from a host_response_headers dump; header names matched exactly.
# shape FILE    -> "ok" when the graphql seam's query selects a field beyond the
#                  rate-limit object and neither seam passes the cache flag; else "bad".
_ev_py() {
  /usr/bin/python3 - "$@" <<'PY'
import email.utils, json, re, sys

INT = re.compile(r"^[0-9]+$")


def schema(path):
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    for sec in doc.get("sections") or []:
        if isinstance(sec, dict) and sec.get("name") == "adapters":
            for key in sec.get("keys") or []:
                if isinstance(key, dict) and key.get("key") == "repo_host":
                    out = []
                    if isinstance(key.get("default"), str) and key["default"].strip():
                        out.append("DEFAULT\t" + key["default"].strip())
                    for v in key.get("enum") or []:
                        if isinstance(v, str) and v.strip():
                            out.append("ENUM\t" + v.strip())
                    return "".join(line + "\n" for line in out)
    return ""


def reading(path):
    hdr = {}
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            name, tab, value = line.rstrip("\n").partition("\t")
            if tab:
                hdr.setdefault(name, value.strip())

    def num(name):
        v = hdr.get(name, "")
        return v if INT.match(v) else "-"

    counters = [num("x-ratelimit-" + n) for n in ("limit", "remaining", "used", "reset")]
    counter = "1" if any(c != "-" for c in counters) else "0"
    resource = re.sub(r"\s+", "_", hdr.get("x-ratelimit-resource", "")) or "-"
    date = "-"
    parsed = email.utils.parsedate_tz(hdr["date"]) if hdr.get("date") else None
    if parsed:
        date = str(email.utils.mktime_tz(parsed))
    return "\t".join([counter, resource] + counters + [date, num("retry-after")]) + "\n"


def seam(text, name):
    m = re.search(r"(?m)^" + re.escape(name) + r"\(\) \{\n(.*?)^\}", text, re.S)
    return m.group(1) if m else ""


def top_fields(selection):
    depth, out, word = 0, [], ""
    for ch in selection:
        if ch == "{":
            if depth == 0 and word:
                out.append(word)
                word = ""
            depth += 1
        elif ch == "}":
            depth -= 1
        elif depth == 0:
            if ch.isalnum() or ch == "_":
                word += ch
            else:
                if word:
                    out.append(word)
                word = ""
    if word:
        out.append(word)
    return out


def shape(path):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    rest, gql = seam(text, "_host_probe_rest"), seam(text, "_host_probe_graphql")
    if not rest or not gql or "--cache" in rest or "--cache" in gql:
        return "bad\n"
    m = re.search(r"query\{(.*)\}", gql)
    if not m:
        return "bad\n"
    inner, depth, end = m.group(1), 0, None
    for i, ch in enumerate(inner):
        depth += ch == "{"
        depth -= ch == "}"
        if depth < 0:
            end = i
            break
    fields = top_fields(inner if end is None else inner[:end])
    return "ok\n" if any(f != "rateLimit" for f in fields) and "rateLimit" in fields else "bad\n"


mode = sys.argv[1] if len(sys.argv) > 1 else ""
out = {"schema": schema, "reading": reading, "shape": shape}.get(mode)
if out is None:
    sys.exit(2)
sys.stdout.write(out(sys.argv[2]))
PY
}

# ─── the GitHub seams: the only place a host command appears ─────────────────────────
# _host_probe_rest OUT ERR — ONE metered read of the REST core pool. GET /versions is
# repository-free, so no repository needs resolving (the core pool is per credential),
# and its body carries no identity; only the response headers are read.
_host_probe_rest() {
  local rc=0
  gh api -i versions >"$1" 2>"$2" || rc=$?
  return "$rc"
}

# _host_probe_graphql OUT ERR — ONE metered read of the GraphQL pool. __typename is the
# charged selection beyond the rate-limit object: defined by the GraphQL specification on
# every server, and its body carries no account identifier.
_host_probe_graphql() {
  local rc=0
  gh api -i graphql -f query='query{__typename rateLimit{limit cost remaining used resetAt}}' >"$1" 2>"$2" || rc=$?
  return "$rc"
}

# ─── transport: the live seams, or the recorded responses ────────────────────────────
_replay_read() {
  local pool="$1" k="$2" out="$3" err="$4" j="$2"
  while [ "$j" -gt 1 ] && [ ! -e "$REPLAY_DIR/$pool.$j.rc" ]; do j=$((j - 1)); done
  local base="$REPLAY_DIR/$pool.$j"
  [ -r "$base.out" ] && [ -r "$base.err" ] && [ -r "$base.rc" ] \
    || _scan_error "the replay directory has no complete fixture for $pool read $k"
  /bin/cat "$base.out" >"$out"
  /bin/cat "$base.err" >"$err"
  PROBE_RC=""
  IFS= read -r PROBE_RC <"$base.rc" || true
}

_probe() {
  local pool="$1" k="$2" out="$3" err="$4" rc=0
  if [ -n "$REPLAY_DIR" ]; then
    _replay_read "$pool" "$k" "$out" "$err"
    return 0
  fi
  case "$pool" in
    core) _host_probe_rest "$out" "$err" || rc=$? ;;
    graphql) _host_probe_graphql "$out" "$err" || rc=$? ;;
  esac
  PROBE_RC="$rc"
}

# ─── one read: probe, classify, extract the reading ──────────────────────────────────
_do_read() {
  local pool="$1" k="$2" transport line prc=0 f1 f2 f3 f4 f5 f6 f7 f8
  case "$pool" in core) transport=rest ;; *) transport=graphql ;; esac
  local out="$EV_TMP/$pool.$k.out" err="$EV_TMP/$pool.$k.err" hdrs="$EV_TMP/$pool.$k.hdrs"
  _probe "$pool" "$k" "$out" "$err"
  line="$(host_refusal_class "$transport" "$out" "$err" "$PROBE_RC")" || prc=$?
  { [ "$prc" -eq 0 ] && [ -n "$line" ]; } \
    || _fault "the refusal classifier could not run on $pool read $k (return $prc)"
  IFS=$'\t' read -r f1 f2 f3 f4 <<<"$line"
  RD_CLASS[$k]="$f1"; RD_SUB[$k]="$f2"; RD_STATUS[$k]="$f3"; RD_REASON[$k]="$f4"
  prc=0
  host_response_headers "$out" >"$hdrs" || prc=$?
  [ "$prc" -eq 0 ] || _fault "the header parser could not run on $pool read $k"
  line="$(_ev_py reading "$hdrs")" || _fault "the reading parser could not run on $pool read $k"
  IFS=$'\t' read -r f1 f2 f3 f4 f5 f6 f7 f8 <<<"$line"
  RD_COUNTER[$k]="$f1"; RD_RESOURCE[$k]="$f2"; RD_LIMIT[$k]="$f3"; RD_REMAINING[$k]="$f4"
  RD_USED[$k]="$f5"; RD_RESET[$k]="$f6"; RD_DATE[$k]="$f7"; RD_RETRY[$k]="$f8"
  RD_ANCHORED[$k]=0
  RD_WHY[$k]="-"
  P_READS="$k"
}

# ─── shared rendering helpers ─────────────────────────────────────────────────────────
_clock() {
  case "$1" in ''|*[!0-9]*) printf '%s' "-"; return 0 ;; esac
  printf '%02d:%02d:%02dZ' $(( ($1 % 86400) / 3600 )) $(( ($1 % 3600) / 60 )) $(( $1 % 60 ))
}

_floor() {
  if [ $(( $1 * 100 )) -lt $(( FLOOR_PCT * $2 )) ]; then printf 'DEFER'; else printf 'PROCEED'; fi
}

_phrase() {
  case "$1" in
    failed-transport) printf 'failed in transport' ;;
    failed-other) printf 'failed for another reason' ;;
    answered) printf 'answered with no counter' ;;
    *) printf '%s' "$1" ;;
  esac
}

# " (<status>)" for a response that carried a status line; nothing for one that did not.
_status_note() {
  if [ "$1" != "-" ]; then printf ' (%s)' "$1"; fi
  return 0
}

_pool_begin() {
  RD_CLASS=(); RD_SUB=(); RD_STATUS=(); RD_REASON=(); RD_COUNTER=(); RD_RESOURCE=()
  RD_LIMIT=(); RD_REMAINING=(); RD_USED=(); RD_RESET=(); RD_DATE=(); RD_RETRY=()
  RD_ANCHORED=(); RD_WHY=()
  P_READS=0
  P_USED_ZERO=0
  P_RESET_DIS=0
}

# _emit_pool POOL BASIS VERDICT OUTCOME FIELDS REASON SEGMENT
#   OUTCOME is the pool's contribution to refusals_in_a_row: refused | answered | failed.
_emit_pool() {
  POOL_LINES="${POOL_LINES}POOL $1 $2 verdict=$3 reads=${P_READS}${5:+ $5} reason=$6"$'\n'
  RENDER_SEGS="$RENDER_SEGS · $7"
  if [ "$3" = DEFER ]; then AXIS_DEFER=1; fi
  case "$4" in refused) ANY_REFUSED=1 ;; failed) ANY_FAILED=1 ;; esac
  return 0
}

# ─── the per-pool rule ────────────────────────────────────────────────────────────────
_anchor() {
  local p="$1" k="$2" why=""
  local d="${RD_DATE[$k]}" t="${RD_RESET[$k]}"
  if [ "${RD_CLASS[$k]}" != answered ]; then why=not-answered
  elif [ "${RD_COUNTER[$k]}" != 1 ]; then why=no-counter
  elif [ "${RD_RESOURCE[$k]}" = "-" ]; then why=resource-absent
  elif [ "${RD_RESOURCE[$k]}" != "$p" ]; then why=resource-mismatch
  elif [ "${RD_LIMIT[$k]}" = "-" ] || [ "${RD_REMAINING[$k]}" = "-" ] \
    || [ "${RD_USED[$k]}" = "-" ] || [ "$t" = "-" ]; then why=counter-incomplete
  elif [ "${RD_USED[$k]}" -lt 1 ]; then why=used-zero
  elif [ "${RD_REMAINING[$k]}" -ge "${RD_LIMIT[$k]}" ]; then why=remaining-full
  elif [ "$d" = "-" ]; then why=no-date-header
  elif [ "$t" -le $(( d - SKEW )) ] || [ "$t" -gt $(( d + WINDOW + SKEW )) ]; then
    why=reset-out-of-window
  fi
  if [ -z "$why" ]; then RD_ANCHORED[$k]=1; RD_WHY[$k]=anchored; else RD_WHY[$k]="$why"; fi
  return 0
}

# _read_and_judge POOL K — one read, its anchor and the used-zero tally. Returns 1 when
# the read was refused on quota grounds, so the caller stops: the refusal dominates.
_read_and_judge() {
  _do_read "$1" "$2"
  _anchor "$1" "$2"
  if [ "${RD_CLASS[$2]}" = answered ] && [ "${RD_USED[$2]}" = 0 ]; then
    case "${RD_RESOURCE[$2]}" in "$1"|-) P_USED_ZERO=$((P_USED_ZERO + 1)) ;; esac
  fi
  [ "${RD_CLASS[$2]}" != refused-quota ]
}

_agree() {
  [ "${RD_ANCHORED[$1]:-0}" = 1 ] && [ "${RD_ANCHORED[$2]:-0}" = 1 ] || return 1
  [ "${RD_RESET[$1]}" = "${RD_RESET[$2]}" ] || return 1
  [ $(( RD_USED[$2] - RD_USED[$1] )) -ge 1 ]
}

_resets_differ() {
  [ "${RD_RESET[$1]:--}" != "-" ] && [ "${RD_RESET[$2]:--}" != "-" ] \
    && [ "${RD_RESET[$1]}" != "${RD_RESET[$2]}" ]
}

# The re-probe matched no earlier reset: read 3 carries one, at least one of reads 1 and 2
# carries one, and read 3's equals none of them.
_reprobe_unmatched() {
  local t="${RD_RESET[3]:--}" k seen=0
  [ "$t" != "-" ] || return 1
  for k in 1 2; do
    [ "${RD_RESET[$k]:--}" != "-" ] || continue
    seen=1
    [ "${RD_RESET[$k]}" != "$t" ] || return 1
  done
  [ "$seen" = 1 ]
}

_most_conservative() {
  local k best=""
  for k in 1 2 3; do
    [ "$k" -le "$P_READS" ] || break
    [ "${RD_ANCHORED[$k]:-0}" = 1 ] || continue
    if [ -z "$best" ] \
      || [ $(( RD_REMAINING[k] * RD_LIMIT[best] )) -le $(( RD_REMAINING[best] * RD_LIMIT[k] )) ]; then
      best="$k"
    fi
  done
  printf '%s' "$best"
}

_backoff() {
  local n="$1" s="$BACKOFF_BASE"
  while [ "$n" -gt 0 ] && [ "$s" -lt "$BACKOFF_CAP" ]; do s=$((s * 2)); n=$((n - 1)); done
  if [ "$s" -gt "$BACKOFF_CAP" ]; then s="$BACKOFF_CAP"; fi
  printf '%s' "$s"
}

_measured() {
  local pool="$1" k="$2" agr="$3"
  local r="${RD_REMAINING[$k]}" l="${RD_LIMIT[$k]}" u="${RD_USED[$k]}" t="${RD_RESET[$k]}"
  local verdict grade label fields seg
  verdict="$(_floor "$r" "$l")"
  if [ "$pool" = core ]; then grade=SOURCE; label='[SOURCE]'
  else grade=ASSUMPTION-CONFIRM; label='[ASSUMPTION – CONFIRM]'; fi
  fields="grade=$grade remaining=$r limit=$l used=$u reset=$t used_zero=$P_USED_ZERO"
  seg="$pool MEASURED $r/$l $label reset $(_clock "$t")"
  if [ "$pool" = graphql ]; then
    fields="$fields agreement=$agr reset_disagreements=$P_RESET_DIS"
    case "$agr" in
      pair) seg="$seg (2 reads agree)" ;;
      reprobe) seg="$seg (the re-probe agrees)" ;;
      unresolved) seg="$seg (unresolved: the most conservative of $P_READS readings)" ;;
    esac
  fi
  if [ "$verdict" = DEFER ]; then seg="$seg — DEFER below the $FLOOR_PCT % floor until $(_clock "$t")"; fi
  if [ "$P_USED_ZERO" -ge 1 ] || [ "$agr" = unresolved ]; then CAL_EVENT=1; fi
  _emit_pool "$pool" MEASURED "$verdict" answered "$fields" anchored "$seg"
}

_contradicted() {
  local pool="$1" k="$2" sub="${RD_SUB[$2]}" rec txt s
  if [ "$sub" = primary ] && [ "${RD_RESET[$k]}" != "-" ]; then
    rec="reset:${RD_RESET[$k]}"; txt="resume after $(_clock "${RD_RESET[$k]}")"
  elif [ "$sub" = secondary ] && [ "${RD_RETRY[$k]}" != "-" ]; then
    rec="retry-after:${RD_RETRY[$k]}"; txt="retry after ${RD_RETRY[$k]} s"
  else
    s="$(_backoff "$PRIOR")"
    rec="backoff:$s"; txt="backoff ≥ $s s (refusal $((PRIOR + 1)) in a row)"
  fi
  _emit_pool "$pool" CONTRADICTED DEFER refused \
    "class=refused-quota subclass=$sub status=${RD_STATUS[$k]} recovery=$rec" "${RD_REASON[$k]}" \
    "$pool CONTRADICTED — refused on quota grounds ($sub); DEFER, $txt"
}

# No individually anchored reading: UNANCHORED when an answered read carried a counter,
# otherwise UNSTATED with the last read's class.
_no_anchor() {
  local pool="$1" k j="" fields reason outcome
  for k in 3 2 1; do
    if [ "${RD_CLASS[$k]:-}" = answered ] && [ "${RD_COUNTER[$k]:-0}" = 1 ]; then j="$k"; break; fi
  done
  if [ -n "$j" ]; then
    fields="reported_remaining=${RD_REMAINING[$j]} reported_limit=${RD_LIMIT[$j]}"
    fields="$fields reported_used=${RD_USED[$j]} reported_reset=${RD_RESET[$j]} used_zero=$P_USED_ZERO"
    if [ "$pool" = graphql ]; then fields="$fields agreement=- reset_disagreements=$P_RESET_DIS"; fi
    if [ "$P_USED_ZERO" -ge 1 ]; then CAL_EVENT=1; fi
    _emit_pool "$pool" UNANCHORED DEFER answered "$fields" "${RD_WHY[$j]}" \
      "$pool UNANCHORED — the reading does not reflect the probe's own draw (${RD_WHY[$j]}); DEFER, re-run at the next routing turn"
    return 0
  fi
  k="$P_READS"
  if [ "${RD_CLASS[$k]}" = answered ]; then outcome=answered; reason=no-counter
  else outcome=failed; reason="${RD_REASON[$k]}"; fi
  _emit_pool "$pool" UNSTATED PROCEED "$outcome" "class=${RD_CLASS[$k]} status=${RD_STATUS[$k]}" \
    "$reason" "$pool UNSTATED — $(_phrase "${RD_CLASS[$k]}")$(_status_note "${RD_STATUS[$k]}"): $reason; fails open"
}

_pool_core() {
  if ! _read_and_judge core 1; then _contradicted core 1; return 0; fi
  if [ "${RD_ANCHORED[1]}" = 1 ]; then _measured core 1 -; return 0; fi
  if ! _read_and_judge core 2; then _contradicted core 2; return 0; fi
  if [ "${RD_ANCHORED[2]}" = 1 ]; then _measured core 2 -; return 0; fi
  _no_anchor core
}

_pool_graphql() {
  local best
  if ! _read_and_judge graphql 1; then _contradicted graphql 1; return 0; fi
  if ! _read_and_judge graphql 2; then _contradicted graphql 2; return 0; fi
  if _agree 1 2; then _measured graphql 2 pair; return 0; fi
  if _resets_differ 1 2; then P_RESET_DIS=$((P_RESET_DIS + 1)); fi
  if ! _read_and_judge graphql 3; then _contradicted graphql 3; return 0; fi
  if _agree 2 3 || _agree 1 3; then _measured graphql 3 reprobe; return 0; fi
  if _reprobe_unmatched; then P_RESET_DIS=$((P_RESET_DIS + 1)); fi
  best="$(_most_conservative)"
  if [ -n "$best" ]; then _measured graphql "$best" unresolved; return 0; fi
  _no_anchor graphql
}

# pool_verdict POOL — the anchored rule (quota-budget-protocol.md § 4.3b).
pool_verdict() {
  _pool_begin
  case "$1" in
    core) _pool_core ;;
    graphql) _pool_graphql ;;
  esac
}

# axis_record VERDICT — the HOST-API record.
axis_record() {
  local k=0 c=no
  if [ "$ANY_REFUSED" = 1 ]; then k=$((PRIOR + 1)); elif [ "$ANY_FAILED" = 1 ]; then k="$PRIOR"; fi
  if [ "$CAL_EVENT" = 1 ]; then c=yes; fi
  printf 'HOST-API %s refusals_in_a_row=%s calibration_event=%s\n' "$1" "$k" "$c"
}

# ─── selection ────────────────────────────────────────────────────────────────────────
_select_host() {
  local decl="" prc=0 default="" enum="" l configured
  [ -r "$SCHEMA" ] || _scan_error "the operator key declaration is not readable"
  decl="$(_ev_py schema "$SCHEMA")" || prc=$?
  [ "$prc" -eq 0 ] || _scan_error "the operator key declaration does not parse"
  while IFS= read -r l; do
    case "$l" in
      "DEFAULT"$'\t'*) default="${l#*$'\t'}" ;;
      "ENUM"$'\t'*) enum="$enum ${l#*$'\t'}" ;;
    esac
  done <<<"$decl"
  [ -n "${enum// /}" ] || _scan_error "parsed 0 values for [adapters].repo_host"
  [ -n "$default" ] || _scan_error "no declared default for [adapters].repo_host"
  configured="$(_pt_read_field "$CONFIG_ROOT/operator.toml" adapters repo_host)"
  HOST="${configured:-$default}"
  case " $enum " in
    *" $HOST "*) ;;
    *)
      printf 'host-api-axis-verdict: [adapters].repo_host is %s, outside the declared value space {%s}; a typo is a configuration error, never a silent fallback (exit 2)\n' \
        "'$HOST'" "${enum# }" >&2
      exit 2 ;;
  esac
  case " $IMPLEMENTED_ARMS " in *" $HOST "*) HOST_IMPLEMENTED=1 ;; *) HOST_IMPLEMENTED=0 ;; esac
}

# ─── arguments ────────────────────────────────────────────────────────────────────────
_usage() {
  printf '%s\n' 'usage: host-api-axis-verdict.sh [--replay DIR] [--prior-refusals N] | --self-test | -h' >&2
  exit 2
}

_set_prior() {
  case "$1" in
    ''|*[!0-9]*)
      printf 'host-api-axis-verdict: --prior-refusals takes a non-negative integer, got %s (exit 2)\n' "'$1'" >&2
      exit 2 ;;
  esac
  if [ "${#1}" -gt "$PRIOR_MAX_DIGITS" ]; then
    printf 'host-api-axis-verdict: --prior-refusals is out of range (more than %s digits) (exit 2)\n' "$PRIOR_MAX_DIGITS" >&2
    exit 2
  fi
  PRIOR=$((10#$1))
}

_parse_args() {
  if [ "$#" -eq 1 ] && [ "$1" = --self-test ]; then MODE=selftest; return 0; fi
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --replay) [ "$#" -ge 2 ] && [ -n "$2" ] || _usage; REPLAY_DIR="$2"; shift 2 ;;
      --prior-refusals) [ "$#" -ge 2 ] || _usage; _set_prior "$2"; shift 2 ;;
      *) _usage ;;
    esac
  done
  if [ -n "$REPLAY_DIR" ] && [ ! -d "$REPLAY_DIR" ]; then _scan_error "the replay directory does not exist"; fi
  return 0
}

# ─── the run ──────────────────────────────────────────────────────────────────────────
_report() {
  local v=PROCEED
  if [ "$AXIS_DEFER" = 1 ]; then v=DEFER; fi
  axis_record "$v"
  printf '%s' "$POOL_LINES"
  if [ "$CAL_EVENT" = 1 ]; then
    RENDER_SEGS="$RENDER_SEGS · calibration event (the hub records a verification action item)"
  fi
  printf 'RENDER host-API %s%s\n' "$v" "$RENDER_SEGS"
}

main() {
  _parse_args "$@"
  if [ "$MODE" = selftest ]; then self_test; return $?; fi
  _select_host
  if [ "$HOST_IMPLEMENTED" -ne 1 ]; then
    ANY_FAILED=1
    axis_record PROCEED
    printf 'POOL - UNSTATED no-probe-for-repo-host=%s\n' "$HOST"
    printf 'RENDER host-API PROCEED · UNSTATED — no probe arm for repo_host %s; fails open\n' "$HOST"
    return 0
  fi
  EV_TMP="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/host-api-axis.XXXXXX")" \
    || _scan_error "cannot create a temporary directory"
  trap '/bin/rm -rf "$EV_TMP"' EXIT
  pool_verdict core
  pool_verdict graphql
  _report
}

# ══════════════════════════════════════════════════════════════════════════════════════
# SELF-TEST — hermetic: replay fixtures in a temporary directory, no network, no host
# call, and no read of the operator's own config. Each arm runs this file as a child
# process. Fixtures follow the live byte layout: the status line with LF, headers with
# CRLF, one CRLF CRLF, then the body; Access-Control-Expose-Headers is kept verbatim (its
# value lists Retry-After and X-RateLimit-*, the substring trap); the OAuth-scope,
# SSO and request-id headers are dropped; no body carries an account identifier, and
# every refusal names user ID 0. "live" marks an arm built from a response recorded when
# the design was measured.
# ══════════════════════════════════════════════════════════════════════════════════════

ST=""; ST_CFG=""; ST_SCHEMA=""; ST_SELF=""; ST_BASH=""
ST_OUT=""; ST_RC=0; ST_ARM=""; ST_ARM_OK=1; ST_PASS=0; ST_FAILN=0; ST_FAILED=""

# The synthetic clock: D0 is a Date header and E0 its epoch. Recorded dates carry theirs.
D0='Sat, 26 Sep 2026 01:00:00 GMT'; E0=1790384400
_st_env=(
  'Access-Control-Allow-Origin: *'
  'Access-Control-Expose-Headers: ETag, Link, Location, Retry-After, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Used, X-RateLimit-Resource, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes, X-Poll-Interval, X-GitHub-Media-Type, X-GitHub-SSO, X-GitHub-Request-Id, Deprecation, Sunset, Warning'
  "Content-Security-Policy: default-src 'none'"
  'Content-Type: application/json; charset=utf-8'
  'Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin'
  'Server: github.com'
  'Strict-Transport-Security: max-age=31536000; includeSubdomains; preload'
  'Vary: Accept-Encoding, Accept, X-Requested-With'
  'X-Content-Type-Options: nosniff'
  'X-Frame-Options: deny'
  'X-Xss-Protection: 0'
)
ST_DOC='"documentation_url":"https://docs.github.com/rest/overview/rate-limits-for-the-rest-api"'
ST_MSG_PRIMARY='API rate limit exceeded for user ID 0.'
ST_MSG_SECONDARY='You have exceeded a secondary rate limit. Please wait a few minutes before you try again.'

# _fx DIR POOL K RC STATUS BODY [HEADER...] — one recorded response. STATUS "none" writes
# an empty stdout (no status line). ST_ERRTEXT, when set, becomes the response's stderr.
_fx() {
  local d="$1" pool="$2" k="$3" rc="$4" st="$5" body="$6" h
  shift 6
  local f="$d/$pool.$k"
  if [ "$st" = none ]; then
    : >"$f.out"
  else
    {
      printf 'HTTP/2.0 %s\n' "$st"
      for h in ${1+"$@"}; do printf '%s\r\n' "$h"; done
      printf '\r\n%s' "$body"
    } >"$f.out"
  fi
  printf '%s' "${ST_ERRTEXT:-}" >"$f.err"
  printf '%s\n' "$rc" >"$f.rc"
}

# _fx_ok DIR POOL K DATE LIMIT REMAINING USED RESET [RESOURCE] [BODY] — an answered read.
#   DATE "-" omits the Date header.
_fx_ok() {
  local d="$1" pool="$2" k="$3" date="$4" l="$5" r="$6" u="$7" t="$8" res="${9:-$2}" body="${10:-}"
  local -a dh=()
  if [ -z "$body" ]; then
    if [ "$pool" = core ]; then body='["2026-03-10","2022-11-28"]'
    else body="{\"data\":{\"__typename\":\"Query\",\"rateLimit\":{\"limit\":$l,\"cost\":1,\"remaining\":$r,\"used\":$u,\"resetAt\":\"2026-09-26T01:20:16Z\"}}}"; fi
  fi
  if [ "$date" != "-" ]; then dh=("Date: $date"); fi
  _fx "$d" "$pool" "$k" 0 "200 OK" "$body" "${_st_env[@]}" ${dh[@]+"${dh[@]}"} \
    "X-Ratelimit-Limit: $l" "X-Ratelimit-Remaining: $r" "X-Ratelimit-Reset: $t" \
    "X-Ratelimit-Resource: $res" "X-Ratelimit-Used: $u"
}

# _fx_refused DIR POOL K RC STATUS BODY [HEADER...] — an error response with the envelope.
_fx_refused() {
  local d="$1" pool="$2" k="$3" rc="$4" st="$5" body="$6"
  shift 6
  _fx "$d" "$pool" "$k" "$rc" "$st" "$body" "${_st_env[@]}" "Date: $D0" ${1+"$@"}
}

_st_healthy_core() { _fx_ok "$1" core 1 "$D0" 5000 4000 1000 $((E0 + 1800)); }
_st_healthy_gql() {
  _fx_ok "$1" graphql 1 "$D0" 5000 4100 900 $((E0 + 2400))
  _fx_ok "$1" graphql 2 "$D0" 5000 4099 901 $((E0 + 2400))
}

_st_dir() {
  local d="$ST/fx.$1"
  /bin/mkdir -p "$d"
  printf '%s' "$d"
}

_st_run() {
  ST_RC=0
  ST_OUT="$(PMO_PLATFORM_CONFIG_ROOT="$ST_CFG" HOST_API_AXIS_SCHEMA="$ST_SCHEMA" \
    "$ST_BASH" "$ST_SELF" "$@" 2>"$ST/stderr")" || ST_RC=$?
}

_st_arm() { ST_ARM="$1"; ST_ARM_OK=1; ST_CFG="$ST/cfg.github"; ST_SCHEMA=""; ST_SELF="$SELF"; ST_BASH="${BASH:-/bin/bash}"; }

_st_ok() {
  local desc="$1"
  shift
  if "$@"; then return 0; fi
  ST_ARM_OK=0
  printf '      fail: %s\n' "$desc" >&2
  return 0
}

_st_end() {
  if [ "$ST_ARM_OK" = 1 ]; then
    ST_PASS=$((ST_PASS + 1)); printf '  PASS  %s\n' "$ST_ARM" >&2
  else
    ST_FAILN=$((ST_FAILN + 1)); ST_FAILED="$ST_FAILED ${ST_ARM%% *}"; printf '  FAIL  %s\n' "$ST_ARM" >&2
  fi
}

# Output predicates over the last run.
_st_rc() { [ "$ST_RC" -eq "$1" ]; }
_st_line() {
  local l
  while IFS= read -r l; do
    case "$l" in $1) return 0 ;; esac
  done <<<"$ST_OUT"
  return 1
}
_st_no_hostapi() { ! _st_line 'HOST-API *'; }
_st_rec() {
  local l
  while IFS= read -r l; do
    case "$l" in "POOL $1 "*) printf '%s' "$l"; return 0 ;; esac
  done <<<"$ST_OUT"
  return 1
}
_st_fld() {
  local rec=" $1 " v
  case "$rec" in *" $2="*) ;; *) return 1 ;; esac
  v="${rec#* $2=}"
  if [ "$2" = reason ]; then v="${v% }"; else v="${v%% *}"; fi
  printf '%s' "$v"
}
_st_basis() { local r; r="$(_st_rec "$1")" || return 1; case "$r" in "POOL $1 $2 "*) return 0 ;; esac; return 1; }
_st_field_is() { local r v; r="$(_st_rec "$1")" || return 1; v="$(_st_fld "$r" "$2")" || return 1; [ "$v" = "$3" ]; }
_st_field_absent() { local r; r="$(_st_rec "$1")" || return 1; ! _st_fld "$r" "$2" >/dev/null; }
_st_render_has() { local l; l="$(_st_render)" || return 1; case "$l" in *"$1"*) return 0 ;; esac; return 1; }
# The RENDER segment of POOL shows MEASURED figures and carries a grade label.
_st_graded() {
  local l seg
  l="$(_st_render)" || return 1
  while :; do
    case "$l" in *" · "*) seg="${l%% · *}"; l="${l#* · }" ;; *) seg="$l"; l="" ;; esac
    case "$seg" in
      "$1 MEASURED "*)
        case "$seg" in *"[SOURCE]"*|*"[ASSUMPTION – CONFIRM]"*) return 0 ;; esac ;;
    esac
    [ -n "$l" ] || return 1
  done
}
_st_render() {
  local l
  while IFS= read -r l; do
    case "$l" in "RENDER "*) printf '%s' "$l"; return 0 ;; esac
  done <<<"$ST_OUT"
  return 1
}
# No line of the last run carries a URL, a request path, a numeric user ID or a node id.
_st_hygienic() {
  local l
  while IFS= read -r l; do
    case "$l" in
      *://*|*api.github.com*|*repos/*|*"user ID "[0-9]*|*_kgDO*|*MDQ6*|*MDEw*) return 1 ;;
    esac
  done <<<"$ST_OUT"
  return 0
}

self_test() {
  local d s n
  ST="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/host-api-axis-st.XXXXXX")" || _scan_error "cannot create a self-test directory"
  trap '/bin/rm -rf "$ST"' EXIT
  /bin/mkdir -p "$ST/cfg.github" "$ST/cfg.gitlab" "$ST/cfg.examplehost" "$ST/cfg.absent"
  printf '[adapters]\nrepo_host = "github"\n' >"$ST/cfg.github/operator.toml"
  printf '[adapters]\nrepo_host = "gitlab"\n' >"$ST/cfg.gitlab/operator.toml"
  printf '[adapters]\nrepo_host = "examplehost"\n' >"$ST/cfg.examplehost/operator.toml"
  printf '%s\n' '{"sections":[{"name":"adapters","keys":[{"key":"repo_host","default":"github","enum":["github","examplehost"]}]}]}' \
    >"$ST/schema.examplehost.json"
  printf 'host-api-axis-verdict self-test (bash %s)\n' "${BASH_VERSION:-unknown}" >&2

  # 1 — AC-3's discrimination arm on responses recorded at two live window rollovers: a
  # fresh core window that the probe itself started (used 1, reset = its own Date + 3600),
  # and a fresh GraphQL window read twice with the charged shape. Verdict and basis only.
  _st_arm "01 FRESH-WINDOW (live)"; d="$(_st_dir 01)"
  _fx_ok "$d" core 1 'Sat, 26 Sep 2026 00:22:49 GMT' 5000 4999 1 1790385769
  _fx_ok "$d" core 2 'Sat, 26 Sep 2026 00:22:50 GMT' 5000 4998 2 1790385769
  _fx_ok "$d" graphql 1 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 4997 3 1790385616
  _fx_ok "$d" graphql 2 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 4995 5 1790385616
  _st_run --replay "$d"
  _st_ok "exit 0" _st_rc 0
  _st_ok "HOST-API PROCEED" _st_line 'HOST-API PROCEED*'
  _st_ok "core MEASURED" _st_basis core MEASURED
  _st_ok "graphql MEASURED" _st_basis graphql MEASURED
  _st_end

  _st_arm "02 HEALTHY-PAIR-FIELDS"; d="$(_st_dir 02)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "graphql agreement=pair" _st_field_is graphql agreement pair
  _st_ok "graphql reset_disagreements=0" _st_field_is graphql reset_disagreements 0
  _st_ok "graphql used_zero=0" _st_field_is graphql used_zero 0
  _st_ok "graphql reads=2" _st_field_is graphql reads 2
  _st_ok "core reads=1" _st_field_is core reads 1
  _st_ok "core used_zero=0" _st_field_is core used_zero 0
  _st_end

  # 3, 4 — AC-2: a present reading of an unstarted window cannot reach PROCEED.
  _st_arm "03 UNSTARTED-AFTER-DRAW"; d="$(_st_dir 03)"
  _fx_ok "$d" core 1 "$D0" 5000 5000 0 $((E0 + 3600)); _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNANCHORED" _st_basis core UNANCHORED
  _st_ok "core used_zero=2 (both reads)" _st_field_is core used_zero 2
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  # (b) the remaining < limit clause on its own: a counter that shows a draw but a full
  # pool is not a report of the probe that drew
  d="$(_st_dir 03b)"
  _fx_ok "$d" core 1 "$D0" 5000 5000 1 $((E0 + 3600)); _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "(b) used 1 with a full pool -> UNANCHORED" _st_basis core UNANCHORED
  _st_ok "(b) reason=remaining-full" _st_field_is core reason remaining-full
  _st_end

  _st_arm "04 NO-DECLARED-DRAW (live)"; d="$(_st_dir 04)"
  # the pool-status endpoint's report, read one second into a fresh core window the
  # probe had already started: used 0, a full pool, a reset sliding to one hour out
  _fx_ok "$d" core 1 'Sat, 26 Sep 2026 00:22:50 GMT' 5000 5000 0 1790385770
  _fx_ok "$d" graphql 1 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 4997 3 1790385616
  _fx_ok "$d" graphql 2 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 4995 5 1790385616
  _st_run --replay "$d"
  _st_ok "core UNANCHORED" _st_basis core UNANCHORED
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  _st_ok "the unstarted figure is never rendered as remaining" _st_field_absent core remaining
  _st_end

  _st_arm "05 REPROBE-RECOVERS (core)"; d="$(_st_dir 05)"
  _fx_ok "$d" core 1 "$D0" 5000 4010 990 $((E0 - 900))
  _fx_ok "$d" core 2 "$D0" 5000 4009 991 $((E0 + 1800))
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core MEASURED" _st_basis core MEASURED
  _st_ok "core reads=2" _st_field_is core reads 2
  _st_end

  _st_arm "06 BELOW-FLOOR"; d="$(_st_dir 06)"
  _fx_ok "$d" core 1 "$D0" 5000 900 4100 $((E0 + 1800)); _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core MEASURED verdict=DEFER" _st_field_is core verdict DEFER
  _st_ok "core MEASURED" _st_basis core MEASURED
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  _st_end

  _st_arm "07 REST-PRIMARY-REFUSAL"; d="$(_st_dir 07)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_PRIMARY\",$ST_DOC,\"status\":\"403\"}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 0" "X-Ratelimit-Reset: $((E0 + 1800))" \
    "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 5000"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core CONTRADICTED" _st_basis core CONTRADICTED
  _st_ok "subclass=primary" _st_field_is core subclass primary
  _st_ok "recovery = the refusing response's reset" _st_field_is core recovery "reset:$((E0 + 1800))"
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  _st_end

  _st_arm "08 GRAPHQL-PRIMARY-REFUSAL"; d="$(_st_dir 08)"
  _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 1 "200 OK" "{\"errors\":[{\"type\":\"RATE_LIMITED\",\"message\":\"API rate limit already exceeded for user ID 0.\"}]}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 0" "X-Ratelimit-Reset: $((E0 + 2400))" \
    "X-Ratelimit-Resource: graphql" "X-Ratelimit-Used: 5000"
  _st_run --replay "$d"
  _st_ok "graphql CONTRADICTED" _st_basis graphql CONTRADICTED
  _st_ok "subclass=primary" _st_field_is graphql subclass primary
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  _st_end

  _st_arm "09 SECONDARY-RETRY-AFTER"; d="$(_st_dir 09)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_SECONDARY\",$ST_DOC}" \
    "Retry-After: 60" "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 4000" \
    "X-Ratelimit-Reset: $((E0 + 1800))" "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 1000"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core CONTRADICTED" _st_basis core CONTRADICTED
  _st_ok "subclass=secondary" _st_field_is core subclass secondary
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  _st_end

  _st_arm "10 SECONDARY-MESSAGE-ONLY"; d="$(_st_dir 10)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_SECONDARY\",$ST_DOC}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 4000" "X-Ratelimit-Reset: $((E0 + 1800))" \
    "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 1000"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core CONTRADICTED" _st_basis core CONTRADICTED
  _st_ok "subclass=secondary" _st_field_is core subclass secondary
  _st_end

  # 11 — (a) the host's primary-limit wording with no remaining-0 and no retry-after;
  # (b) binding row 10: a GraphQL 200 carrying RATE_LIMITED with no other signal.
  _st_arm "11 RATE-LIMIT-WORDING-ONLY"; d="$(_st_dir 11a)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_PRIMARY\",$ST_DOC}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 4000" "X-Ratelimit-Reset: $((E0 + 1800))" \
    "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 1000"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "(a) core CONTRADICTED" _st_basis core CONTRADICTED
  _st_ok "(a) subclass=unspecified" _st_field_is core subclass unspecified
  d="$(_st_dir 11b)"; _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 1 "200 OK" '{"errors":[{"type":"RATE_LIMITED","message":"Rate limited."}]}' \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 4000" "X-Ratelimit-Reset: $((E0 + 2400))" \
    "X-Ratelimit-Resource: graphql" "X-Ratelimit-Used: 1000"
  _st_run --replay "$d"
  _st_ok "(b) graphql CONTRADICTED" _st_basis graphql CONTRADICTED
  _st_ok "(b) subclass=unspecified" _st_field_is graphql subclass unspecified
  _st_end

  _st_arm "12 QUOTED-REFUSAL-IN-SUCCESS-BODY"; d="$(_st_dir 12)"
  _fx_ok "$d" core 1 "$D0" 5000 4000 1000 $((E0 + 1800)) core \
    "[\"$ST_MSG_PRIMARY\",\"$ST_MSG_SECONDARY\",\"abuse detection\"]"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core MEASURED, never CONTRADICTED" _st_basis core MEASURED
  _st_ok "HOST-API PROCEED" _st_line 'HOST-API PROCEED*'
  _st_end

  _st_arm "13 PERMISSION-403"; d="$(_st_dir 13)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"Resource not accessible by integration\",$ST_DOC,\"status\":\"403\"}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 4000" "X-Ratelimit-Reset: $((E0 + 1800))" \
    "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 1000"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNSTATED (the expose-headers value is never a retry-after)" _st_basis core UNSTATED
  _st_ok "class=failed-other" _st_field_is core class failed-other
  _st_ok "HOST-API PROCEED" _st_line 'HOST-API PROCEED*'
  _st_end

  _st_arm "14 AUTH-401"; d="$(_st_dir 14)"
  _fx_refused "$d" core 1 1 "401 Unauthorized" "{\"message\":\"Bad credentials\",$ST_DOC,\"status\":\"401\"}"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNSTATED" _st_basis core UNSTATED
  _st_ok "class=failed-other" _st_field_is core class failed-other
  _st_end

  _st_arm "15 NOT-FOUND-404"; d="$(_st_dir 15)"
  _fx_refused "$d" core 1 1 "404 Not Found" "{\"message\":\"Not Found\",$ST_DOC,\"status\":\"404\"}"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNSTATED" _st_basis core UNSTATED
  _st_ok "status=404" _st_field_is core status 404
  _st_end

  # 16 — (a) live: a GraphQL schema error, a 200 carrying errors with exit 1;
  # (b) binding row 6: a GraphQL 200 whose body is not JSON.
  _st_arm "16 GRAPHQL-SCHEMA-ERROR (live)"; d="$(_st_dir 16a)"; _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 1 "200 OK" \
    "{\"errors\":[{\"type\":\"undefinedField\",\"message\":\"Field 'noSuchFieldXyz' doesn't exist on type 'Query'\"}]}"
  _st_run --replay "$d"
  _st_ok "(a) graphql UNSTATED" _st_basis graphql UNSTATED
  _st_ok "(a) class=failed-other" _st_field_is graphql class failed-other
  d="$(_st_dir 16b)"; _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 0 "200 OK" '<html>upstream error</html>'
  _st_run --replay "$d"
  _st_ok "(b) graphql UNSTATED" _st_basis graphql UNSTATED
  _st_ok "(b) class=failed-other" _st_field_is graphql class failed-other
  _st_end

  _st_arm "17 TRANSPORT-FAILURE"; d="$(_st_dir 17)"
  ST_ERRTEXT='Get "https://api.github.com/versions": dial tcp: lookup api.github.com: no such host'
  _fx "$d" core 1 1 none ''
  ST_ERRTEXT=""
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNSTATED" _st_basis core UNSTATED
  _st_ok "class=failed-transport" _st_field_is core class failed-transport
  _st_ok "no URL anywhere in the output" _st_hygienic
  _st_ok "used_zero absent" _st_field_absent core used_zero
  _st_ok "agreement absent" _st_field_absent core agreement
  _st_ok "counters absent" _st_field_absent core remaining
  _st_end

  _st_arm "18 ANSWERED-NO-COUNTER"; d="$(_st_dir 18)"
  _fx "$d" core 1 0 "200 OK" '["2026-03-10","2022-11-28"]' "${_st_env[@]}" "Date: $D0"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNSTATED" _st_basis core UNSTATED
  _st_ok "class=answered" _st_field_is core class answered
  _st_ok "reason=no-counter" _st_field_is core reason no-counter
  _st_ok "used_zero absent" _st_field_absent core used_zero
  _st_ok "counters absent" _st_field_absent core remaining
  _st_ok "HOST-API PROCEED" _st_line 'HOST-API PROCEED*'
  _st_end

  _st_arm "19 RESET-IN-PAST"; d="$(_st_dir 19)"
  _fx_ok "$d" core 1 "$D0" 5000 4000 1000 $((E0 - 600)); _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNANCHORED" _st_basis core UNANCHORED
  _st_ok "reason=reset-out-of-window" _st_field_is core reason reset-out-of-window
  _st_end

  _st_arm "20 RESET-WITHIN-SKEW"; d="$(_st_dir 20)"
  _fx_ok "$d" core 1 "$D0" 5000 4000 1000 $((E0 - 60)); _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core MEASURED" _st_basis core MEASURED
  _st_end

  _st_arm "21 RESOURCE-MISMATCH"; d="$(_st_dir 21)"
  _fx_ok "$d" core 1 "$D0" 5000 4000 1000 $((E0 + 1800)) search; _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNANCHORED" _st_basis core UNANCHORED
  _st_ok "reason=resource-mismatch" _st_field_is core reason resource-mismatch
  _st_end

  _st_arm "22 MIXED-POOLS"; d="$(_st_dir 22a)"
  ST_ERRTEXT='error connecting to api.github.com'
  _fx "$d" core 1 1 none ''
  ST_ERRTEXT=""
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "(a) one UNSTATED pool and one healthy pool -> PROCEED" _st_line 'HOST-API PROCEED*'
  d="$(_st_dir 22b)"; _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_PRIMARY\"}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 0" "X-Ratelimit-Reset: $((E0 + 2400))" \
    "X-Ratelimit-Resource: graphql" "X-Ratelimit-Used: 5000"
  _st_run --replay "$d"
  _st_ok "(b) one healthy pool and one CONTRADICTED pool -> DEFER" _st_line 'HOST-API DEFER*'
  _st_end

  _st_arm "23 SELECTOR-OUT-OF-RANGE"; d="$(_st_dir 23)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  ST_CFG="$ST/cfg.gitlab"
  _st_run --replay "$d"
  _st_ok "exit 2" _st_rc 2
  _st_ok "no HOST-API record" _st_no_hostapi
  _st_end

  _st_arm "25 ABSENT-OPERATOR-TOML"; d="$(_st_dir 25)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  ST_CFG="$ST/cfg.absent"
  _st_run --replay "$d"
  _st_ok "exit 0 on the declared default" _st_rc 0
  _st_ok "a HOST-API record" _st_line 'HOST-API PROCEED*'
  _st_end

  _st_arm "26 FAULT-INJECTION"; d="$(_st_dir 26)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  printf 'x\n' >"$d/core.1.rc"
  _st_run --replay "$d"
  _st_ok "a non-zero exit" _st_rc_nonzero
  _st_ok "no HOST-API record" _st_no_hostapi
  _st_end

  _st_arm "27 RENDER-HYGIENE"; d="$(_st_dir 27a)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "(healthy) no URL, request path, user ID or node id" _st_hygienic
  _st_ok "(healthy) core carries a grade" _st_graded core
  _st_ok "(healthy) graphql carries a grade" _st_graded graphql
  d="$(_st_dir 27b)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_PRIMARY\",$ST_DOC}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 0" "X-Ratelimit-Reset: $((E0 + 1800))" \
    "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 5000"
  ST_ERRTEXT='Post "https://api.github.com/graphql": dial tcp: lookup api.github.com: no such host'
  _fx "$d" graphql 1 1 none ''
  ST_ERRTEXT=""
  _st_run --replay "$d"
  _st_ok "(refused + transport) no URL, request path, user ID or node id" _st_hygienic
  _st_end

  _st_arm "28 UNCHARGED-FRESH-WINDOW (live)"; d="$(_st_dir 28)"
  _st_healthy_core "$d"
  for n in 1 2 3; do
    _fx_ok "$d" graphql "$n" 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 5000 0 $((1790382017 + 3600))
  done
  _st_run --replay "$d"
  _st_ok "graphql UNANCHORED" _st_basis graphql UNANCHORED
  _st_ok "graphql used_zero=3" _st_field_is graphql used_zero 3
  _st_ok "HOST-API DEFER" _st_line 'HOST-API DEFER*'
  _st_end

  _st_arm "29 UNCHARGED-PAIR-QUIET (live)"; d="$(_st_dir 29)"
  _st_healthy_core "$d"
  _fx_ok "$d" graphql 1 'Sat, 26 Sep 2026 00:21:25 GMT' 5000 4908 92 1790385616
  _fx_ok "$d" graphql 2 'Sat, 26 Sep 2026 00:21:25 GMT' 5000 4908 92 1790385616
  _st_run --replay "$d"
  _st_ok "graphql MEASURED (the conservative reading)" _st_basis graphql MEASURED
  _st_ok "agreement=unresolved" _st_field_is graphql agreement unresolved
  _st_ok "a calibration event" _st_line 'HOST-API * calibration_event=yes'
  _st_end

  _st_arm "30 TWO-WINDOW-PAIR (live)"; d="$(_st_dir 30)"
  _st_healthy_core "$d"
  _fx_ok "$d" graphql 1 'Sat, 26 Sep 2026 00:07:01 GMT' 5000 4513 487 1790382015
  _fx_ok "$d" graphql 2 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 4997 3 1790385616
  _fx_ok "$d" graphql 3 'Sat, 26 Sep 2026 00:20:17 GMT' 5000 4995 5 1790385616
  _st_run --replay "$d"
  _st_ok "graphql MEASURED" _st_basis graphql MEASURED
  _st_ok "reset_disagreements=1" _st_field_is graphql reset_disagreements 1
  _st_ok "agreement=reprobe" _st_field_is graphql agreement reprobe
  _st_ok "remaining 4995 of 5000" _st_field_is graphql remaining 4995
  _st_end

  _st_arm "31 THREE-WAY-UNRESOLVED"; d="$(_st_dir 31)"
  _st_healthy_core "$d"
  _fx_ok "$d" graphql 1 "$D0" 5000 4800 200 $((E0 + 1000))
  _fx_ok "$d" graphql 2 "$D0" 5000 4500 500 $((E0 + 2000))
  _fx_ok "$d" graphql 3 "$D0" 5000 4700 300 $((E0 + 3000))
  _st_run --replay "$d"
  _st_ok "the lowest remaining/limit is chosen" _st_field_is graphql remaining 4500
  _st_ok "agreement=unresolved" _st_field_is graphql agreement unresolved
  _st_ok "reset_disagreements=2" _st_field_is graphql reset_disagreements 2
  _st_end

  _st_arm "32 PAIR-STALE-SAME-WINDOW"; d="$(_st_dir 32)"
  _st_healthy_core "$d"
  _fx_ok "$d" graphql 1 "$D0" 5000 4700 300 $((E0 + 2400))
  _fx_ok "$d" graphql 2 "$D0" 5000 4701 299 $((E0 + 2400))
  _fx_ok "$d" graphql 3 "$D0" 5000 4699 301 $((E0 + 2400))
  _st_run --replay "$d"
  _st_ok "agreement=reprobe" _st_field_is graphql agreement reprobe
  _st_ok "graphql reads=3" _st_field_is graphql reads 3
  _st_ok "reset_disagreements=0" _st_field_is graphql reset_disagreements 0
  _st_end

  _st_arm "33 CHARGED-PROBE-SHAPE"
  _st_ok "the graphql seam selects a field beyond the rate-limit object; no seam passes the cache flag" \
    _st_shape_is ok "$SELF"
  /bin/mkdir -p "$ST/shape"
  _st_mutate_query "$SELF" "$ST/shape/mutant.sh"
  _st_ok "the mutation landed" _st_differs "$SELF" "$ST/shape/mutant.sh"
  _st_ok "a rateLimit-only copy fails the same predicate" _st_shape_is bad "$ST/shape/mutant.sh"
  _st_end

  _st_arm "34 NO-DATE-HEADER"; d="$(_st_dir 34)"
  _fx_ok "$d" core 1 - 5000 4000 1000 $((E0 + 1800)); _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNANCHORED" _st_basis core UNANCHORED
  _st_ok "reason=no-date-header" _st_field_is core reason no-date-header
  _st_end

  _st_arm "35 USED-ZERO-COUNT"; d="$(_st_dir 35)"
  _fx_ok "$d" core 1 "$D0" 5000 4990 0 $((E0 + 1800))
  _fx_ok "$d" core 2 "$D0" 5000 4989 11 $((E0 + 1800))
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core MEASURED" _st_basis core MEASURED
  _st_ok "core used_zero=1" _st_field_is core used_zero 1
  _st_ok "a used-0 reading is not anchored, so core re-probes (reads=2)" _st_field_is core reads 2
  _st_ok "a calibration event" _st_line 'HOST-API * calibration_event=yes'
  _st_end

  _st_arm "36 GRAPHQL-SECONDARY-200"; d="$(_st_dir 36)"
  _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 1 "200 OK" "{\"errors\":[{\"message\":\"$ST_MSG_SECONDARY\"}]}" "Retry-After: 30"
  _st_run --replay "$d"
  _st_ok "graphql CONTRADICTED" _st_basis graphql CONTRADICTED
  _st_ok "subclass=secondary" _st_field_is graphql subclass secondary
  _st_ok "recovery = retry-after 30 s" _st_field_is graphql recovery retry-after:30
  _st_end

  _st_arm "37 GRAPHQL-SECONDARY-403"; d="$(_st_dir 37)"
  _st_healthy_core "$d"
  _fx_refused "$d" graphql 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_SECONDARY\",$ST_DOC}"
  _st_run --replay "$d"
  _st_ok "graphql CONTRADICTED" _st_basis graphql CONTRADICTED
  _st_ok "subclass=secondary" _st_field_is graphql subclass secondary
  _st_end

  _st_arm "38 REST-503-RETRY-AFTER"; d="$(_st_dir 38)"
  _fx_refused "$d" core 1 1 "503 Service Unavailable" '{"message":"Service Unavailable"}' "Retry-After: 30"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "core UNSTATED (a 503 is not quota-eligible)" _st_basis core UNSTATED
  _st_ok "class=failed-other" _st_field_is core class failed-other
  _st_end

  # 39 — no status line on a non-transport exit is failed-other, and its reason names the
  # exit; (d) binding row 3, an unparseable status line.
  _st_arm "39 NO-STATUS-NONTRANSPORT"
  for s in 4 127 0; do
    d="$(_st_dir "39.$s")"
    ST_ERRTEXT='To get started with GitHub CLI, please run:  gh auth login'
    _fx "$d" core 1 "$s" none ''
    ST_ERRTEXT=""
    _st_healthy_gql "$d"
    _st_run --replay "$d"
    _st_ok "(exit $s) core UNSTATED" _st_basis core UNSTATED
    _st_ok "(exit $s) class=failed-other" _st_field_is core class failed-other
    _st_ok "(exit $s) the reason names the exit" _st_field_is core reason "no status line (exit $s)"
  done
  d="$(_st_dir 39.d)"
  _fx "$d" core 1 0 "abc" '' "${_st_env[@]}"
  _st_healthy_gql "$d"
  _st_run --replay "$d"
  _st_ok "(d) an unparseable status line is failed-other" _st_field_is core class failed-other
  _st_end

  _st_arm "40 RUNTIME-UNIMPLEMENTED-HOST"; d="$(_st_dir 40)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  ST_CFG="$ST/cfg.examplehost"; ST_SCHEMA="$ST/schema.examplehost.json"
  _st_run --replay "$d"
  _st_ok "exit 0" _st_rc 0
  _st_ok "POOL - UNSTATED no-probe-for-repo-host" _st_line 'POOL - UNSTATED no-probe-for-repo-host=examplehost'
  _st_ok "HOST-API PROCEED" _st_line 'HOST-API PROCEED*'
  _st_end

  _st_arm "41 ENUM-PARITY"
  _st_ok "the tracked declaration's value space equals the implemented arms" \
    _st_parity "$REPO_ROOT/core/config/operator-toml-schema.json"
  _st_ok "a declaration with an added value fails the same predicate" \
    _st_parity_fails "$ST/schema.examplehost.json"
  _st_end

  _st_arm "42 LIBRARY-MISSING"; d="$(_st_dir 42)"
  _st_healthy_core "$d"; _st_healthy_gql "$d"
  /bin/mkdir -p "$ST/nolib/release/tools"
  /bin/cp "$SELF" "$ST/nolib/release/tools/host-api-axis-verdict.sh"
  ST_SELF="$ST/nolib/release/tools/host-api-axis-verdict.sh"
  _st_run --replay "$d"
  _st_ok "exit 3" _st_rc 3
  _st_ok "no HOST-API record" _st_no_hostapi
  _st_end

  _st_arm "43 BACKOFF"
  d="$(_st_dir 43)"
  _fx_refused "$d" core 1 1 "429 Too Many Requests" '{"message":"Too Many Requests"}'
  _st_healthy_gql "$d"
  for s in 0:60 1:120 2:240 6:3600 20:3600; do
    _st_run --replay "$d" --prior-refusals "${s%%:*}"
    _st_ok "N=${s%%:*} -> backoff ${s#*:} s" _st_field_is core recovery "backoff:${s#*:}"
  done
  _st_ok "the wait is rendered, with no timestamp" _st_render_has "backoff ≥ 3600 s (refusal 21 in a row)"
  _st_end

  _st_arm "44 PUBLISHED-RECOVERY"
  d="$(_st_dir 44a)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_SECONDARY\"}" "Retry-After: 17"
  _st_healthy_gql "$d"
  _st_run --replay "$d" --prior-refusals 3
  _st_ok "retry-after 17 at N=3 -> 17 s" _st_field_is core recovery retry-after:17
  d="$(_st_dir 44b)"
  _fx_refused "$d" core 1 1 "403 Forbidden" "{\"message\":\"$ST_MSG_PRIMARY\"}" \
    "X-Ratelimit-Limit: 5000" "X-Ratelimit-Remaining: 0" "X-Ratelimit-Reset: $((E0 + 1800))" \
    "X-Ratelimit-Resource: core" "X-Ratelimit-Used: 5000"
  _st_healthy_gql "$d"
  _st_run --replay "$d" --prior-refusals 3
  _st_ok "primary at N=3 -> the reset epoch" _st_field_is core recovery "reset:$((E0 + 1800))"
  _st_end

  _st_arm "45 REFUSALS-IN-A-ROW"
  d="$(_st_dir 45a)"
  _fx_refused "$d" core 1 1 "429 Too Many Requests" '{"message":"Too Many Requests"}'
  _st_healthy_gql "$d"
  _st_run --replay "$d" --prior-refusals 2
  _st_ok "refused -> N+1" _st_line 'HOST-API DEFER refusals_in_a_row=3 *'
  d="$(_st_dir 45b)"; _st_healthy_core "$d"; _st_healthy_gql "$d"
  _st_run --replay "$d" --prior-refusals 5
  _st_ok "every pool answered -> 0" _st_line 'HOST-API PROCEED refusals_in_a_row=0 *'
  d="$(_st_dir 45c)"
  ST_ERRTEXT='error connecting to api.github.com'
  _fx "$d" core 1 1 none ''
  ST_ERRTEXT=""
  _st_healthy_gql "$d"
  _st_run --replay "$d" --prior-refusals 4
  _st_ok "no refusal but a transport failure -> N" _st_line 'HOST-API PROCEED refusals_in_a_row=4 *'
  for s in -1 x ''; do
    _st_run --replay "$d" --prior-refusals "$s"
    _st_ok "--prior-refusals '$s' -> exit 2" _st_rc 2
  done
  _st_end

  _st_arm "46 BASH32-REPLAY"
  local v=""
  if [ -x /bin/bash ]; then v="$(/bin/bash -c 'printf %s "${BASH_VERSINFO[0]}"' 2>/dev/null)" || v=""; fi
  if [ "$v" = 3 ]; then
    ST_BASH=/bin/bash
    _st_run --replay "$ST/fx.01"
    _st_ok "arm 1's replay under /bin/bash 3.x exits 0" _st_rc 0
    _st_ok "arm 1's replay under /bin/bash 3.x renders a HOST-API record" _st_line 'HOST-API *'
    _st_run --replay "$ST/fx.07"
    _st_ok "arm 7's replay under /bin/bash 3.x exits 0" _st_rc 0
    _st_ok "arm 7's replay under /bin/bash 3.x renders a HOST-API record" _st_line 'HOST-API *'
    _st_end
  else
    ST_PASS=$((ST_PASS + 1))
    printf '  N/A   %s — not applicable: /bin/bash is not bash 3.x on this runner (major %s)\n' "$ST_ARM" "${v:-absent}" >&2
  fi

  if [ "$ST_FAILN" -eq 0 ]; then
    printf 'host-api-axis-verdict self-test: ALL PASS (%s arms)\n' "$ST_PASS"
    return 0
  fi
  printf 'host-api-axis-verdict self-test: %s FAILED of %s arms:%s\n' "$ST_FAILN" "$((ST_PASS + ST_FAILN))" "$ST_FAILED"
  return 1
}

_st_rc_nonzero() { [ "$ST_RC" -ne 0 ]; }
_st_differs() { ! /usr/bin/cmp -s "$1" "$2"; }
_st_shape_is() { local r; r="$(_ev_py shape "$2")" || return 1; [ "$r" = "$1" ]; }

# Write a copy of FILE whose graphql probe selects the rate-limit object alone.
_st_mutate_query() {
  local l
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in
      *"-f query='query{__typename rateLimit{"*) printf '%s\n' "${l/__typename rateLimit/rateLimit}" ;;
      *) printf '%s\n' "$l" ;;
    esac
  done <"$1" >"$2"
}

# The declared value space of FILE equals IMPLEMENTED_ARMS, in both directions.
_st_parity() {
  local decl l declared="" a
  decl="$(_ev_py schema "$1")" || return 1
  while IFS= read -r l; do
    case "$l" in "ENUM"$'\t'*) declared="$declared ${l#*$'\t'}" ;; esac
  done <<<"$decl"
  [ -n "${declared// /}" ] || return 1
  for a in $declared; do case " $IMPLEMENTED_ARMS " in *" $a "*) ;; *) return 1 ;; esac; done
  for a in $IMPLEMENTED_ARMS; do case " $declared " in *" $a "*) ;; *) return 1 ;; esac; done
  return 0
}
_st_parity_fails() { ! _st_parity "$1"; }

main "$@"
