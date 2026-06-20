#!/usr/bin/env bash
# compute-cycle-time.sh — Deployment cycle time computation for a release
# Per pmo-platform/reference/standards/deployment-cycle-time.md.
# Reads the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md
# (canonical default: ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/)
# via query-pipeline-event.sh (sibling tool; it resolves the log location).
#
# Per the Stage 5 spec.
#
# Cycle time = T_DEPLOY - T_GO, where:
#   T_GO     = MIN(ts_iso) of gate-outcome/plan-review-go events for the release
#   T_DEPLOY = MAX(ts_iso) of deployment-status/deploy-skill or deploy-harness
#              events for the release
# Both anchors source the ts_iso field per pipeline-event-log-schema.md § 2.
#
# Usage:
#   ./compute-cycle-time.sh <version>           # human-readable: "47m" or "2h17m" or "N/A"
#   ./compute-cycle-time.sh --version <version> # same as positional form
#   ./compute-cycle-time.sh <version> --seconds # integer seconds: "2820" or "N/A"
#   ./compute-cycle-time.sh <version> --iso     # detail: "T_GO=<iso>; T_DEPLOY=<iso>; delta=2820s"
#   ./compute-cycle-time.sh --self-test         # validate logic against synthetic input
#   ./compute-cycle-time.sh --help              # this help text
#
# Cutover: applies to releases entering Stage 12 strictly AFTER the cutover merge SHA.
# The cutover release itself: exempt. This script does not gate by version — caller honors cutover.
#
# Exit codes:
#   0 = success (rows may produce N/A — legitimate result for content-only releases
#       or pre-instrumentation-fill state)
#   1 = invalid args / log file missing
#   2 = malformed row (ts_iso parse failure — pipeline-event-log integrity violation,
#       escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# REPO_ROOT retained for resolution-block parity with the append/query event-log
# tools; this tool delegates all log-path resolution to query-pipeline-event.sh
# (QUERY_TOOL below), so REPO_ROOT is unused here. Two levels up — NOT three; the
# prior `../../..` mis-anchored above the repo from a worktree (the #430-class bug).
# shellcheck disable=SC2034
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
QUERY_TOOL="$SCRIPT_DIR/query-pipeline-event.sh"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,28p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
OUTPUT_FORMAT="human"   # human | seconds | iso
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --seconds) OUTPUT_FORMAT="seconds"; shift ;;
    --iso) OUTPUT_FORMAT="iso"; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *)
      # Positional: first non-flag arg is the version
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      else
        die "Unexpected positional arg: $1 (version already set to '$VERSION')"
      fi
      shift
      ;;
  esac
done

# ─── ISO8601 delta helpers ───────────────────────────────────────────────────

# Compute T_DEPLOY - T_GO in integer seconds.
# Input: two ISO8601 UTC timestamps (e.g., 2026-05-15T14:22:01Z).
# Output: integer seconds on stdout, exit 2 on parse failure.
compute_delta_seconds() {
  local t_go="$1"
  local t_deploy="$2"
  /usr/bin/python3 - "$t_go" "$t_deploy" <<'PY' || return 2
import sys
from datetime import datetime
try:
    t_go = datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
    t_deploy = datetime.fromisoformat(sys.argv[2].replace("Z", "+00:00"))
except ValueError as e:
    print(f"ts_iso parse failure: {e}", file=sys.stderr)
    sys.exit(2)
delta = t_deploy - t_go
print(int(delta.total_seconds()))
PY
}

# Format integer seconds as "47m" or "2h17m".
format_human() {
  local secs="$1"
  if [[ "$secs" -lt 3600 ]]; then
    /usr/bin/printf '%dm\n' "$((secs / 60))"
  else
    /usr/bin/printf '%dh%dm\n' "$((secs / 3600))" "$(((secs % 3600) / 60))"
  fi
}

# ─── Self-test mode ──────────────────────────────────────────────────────────

if [[ "$SELF_TEST" == "true" ]]; then
  # Test 1: ISO8601 delta arithmetic
  RESULT="$(compute_delta_seconds "2026-05-15T14:22:01Z" "2026-05-15T15:09:34Z")" || die "self-test: compute_delta_seconds failed"
  if [[ "$RESULT" != "2853" ]]; then
    die "self-test: delta arithmetic wrong (expected 2853, got $RESULT)"
  fi

  # Test 2: human formatter — sub-hour
  RESULT="$(format_human 2820)"
  if [[ "$RESULT" != "47m" ]]; then
    die "self-test: format_human(2820) wrong (expected '47m', got '$RESULT')"
  fi

  # Test 3: human formatter — over-hour
  RESULT="$(format_human 8220)"
  if [[ "$RESULT" != "2h17m" ]]; then
    die "self-test: format_human(8220) wrong (expected '2h17m', got '$RESULT')"
  fi

  # Test 4: human formatter — exactly one hour
  RESULT="$(format_human 3600)"
  if [[ "$RESULT" != "1h0m" ]]; then
    die "self-test: format_human(3600) wrong (expected '1h0m', got '$RESULT')"
  fi

  # Test 5: human formatter — zero
  RESULT="$(format_human 0)"
  if [[ "$RESULT" != "0m" ]]; then
    die "self-test: format_human(0) wrong (expected '0m', got '$RESULT')"
  fi

  # Test 6: query tool exists and is executable
  [[ -x "$QUERY_TOOL" ]] || die "self-test: query-pipeline-event.sh not executable at $QUERY_TOOL"

  # Test 7: malformed ISO8601 → exit 2
  if compute_delta_seconds "not-a-timestamp" "2026-05-15T15:09:34Z" >/dev/null 2>&1; then
    die "self-test: malformed ts_iso accepted (should exit 2)"
  fi

  echo "self-test: PASS"
  echo "  ISO8601 delta arithmetic validated"
  echo "  human formatter validated (sub-hour, over-hour, exact-hour, zero)"
  echo "  malformed-input rejection validated"
  echo "  query-pipeline-event.sh dependency validated"
  exit 0
fi

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: <version> (positional or --version)"

# Query tool must exist
[[ -x "$QUERY_TOOL" ]] || die "query-pipeline-event.sh missing or not executable at $QUERY_TOOL"

# ─── Extract T_GO (earliest plan-review-go event for the release) ────────────

# query-pipeline-event.sh filters event_type but not event_subtype; grep refines.
# Output schema (from query-pipeline-event.sh): header rows then data rows.
# Data row: "| ts_iso | version | stage | event_type | event_subtype | ..."
GATE_ROWS="$("$QUERY_TOOL" --version "$VERSION" --event-type gate-outcome 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
T_GO=""
if [[ -n "$GATE_ROWS" ]]; then
  # Filter to plan-review-go subtype (field 5 in pipe-delimited row); take MIN(ts_iso)
  PLAN_REVIEW_GO_ROWS="$(echo "$GATE_ROWS" | /usr/bin/awk -F ' \\| ' '$5 == "plan-review-go" { print }')"
  if [[ -n "$PLAN_REVIEW_GO_ROWS" ]]; then
    # Sort by ts_iso (field 2 after the leading '|'); take first (earliest)
    T_GO="$(echo "$PLAN_REVIEW_GO_ROWS" | /usr/bin/awk -F ' \\| ' '{ print $2 }' | /usr/bin/sort | /usr/bin/head -1)"
  fi
fi

# ─── Extract T_DEPLOY (latest deploy-skill OR deploy-harness event) ──────────

DEPLOY_ROWS="$("$QUERY_TOOL" --version "$VERSION" --event-type deployment-status 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
T_DEPLOY=""
if [[ -n "$DEPLOY_ROWS" ]]; then
  # Filter to deploy-skill OR deploy-harness subtype; take MAX(ts_iso)
  DEPLOY_TARGET_ROWS="$(echo "$DEPLOY_ROWS" | /usr/bin/awk -F ' \\| ' '$5 == "deploy-skill" || $5 == "deploy-harness" { print }')"
  if [[ -n "$DEPLOY_TARGET_ROWS" ]]; then
    T_DEPLOY="$(echo "$DEPLOY_TARGET_ROWS" | /usr/bin/awk -F ' \\| ' '{ print $2 }' | /usr/bin/sort | /usr/bin/tail -1)"
  fi
fi

# ─── N/A determination + emission ────────────────────────────────────────────

if [[ -z "$T_GO" || -z "$T_DEPLOY" ]]; then
  # N/A — emit reason on stderr so the operator / caller can diagnose
  MISSING=""
  [[ -z "$T_GO" ]] && MISSING="${MISSING}no gate-outcome/plan-review-go event for $VERSION; "
  [[ -z "$T_DEPLOY" ]] && MISSING="${MISSING}no deployment-status/deploy-skill or deploy-harness event for $VERSION; "
  echo "Cycle-Time: N/A (${MISSING%; })" >&2
  case "$OUTPUT_FORMAT" in
    seconds) echo "N/A" ;;
    iso) echo "T_GO=${T_GO:-N/A}; T_DEPLOY=${T_DEPLOY:-N/A}; delta=N/A" ;;
    human|*) echo "N/A" ;;
  esac
  exit 0
fi

# ─── Compute delta + format ──────────────────────────────────────────────────

DELTA_SECONDS="$(compute_delta_seconds "$T_GO" "$T_DEPLOY")" || die "ts_iso parse failure on ($T_GO, $T_DEPLOY)" 2

# Negative delta = pipeline-event-log integrity issue (T_DEPLOY before T_GO).
if [[ "$DELTA_SECONDS" -lt 0 ]]; then
  echo "WARNING: negative cycle-time ($DELTA_SECONDS s); T_DEPLOY=$T_DEPLOY before T_GO=$T_GO — pipeline-event-log integrity issue" >&2
fi

case "$OUTPUT_FORMAT" in
  seconds) echo "$DELTA_SECONDS" ;;
  iso) echo "T_GO=$T_GO; T_DEPLOY=$T_DEPLOY; delta=${DELTA_SECONDS}s" ;;
  human|*) format_human "$DELTA_SECONDS" ;;
esac
