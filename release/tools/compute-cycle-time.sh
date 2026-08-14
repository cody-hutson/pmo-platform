#!/usr/bin/env bash
# compute-cycle-time.sh — Deployment cycle time computation for a release
# Per release/references/standards/deployment-cycle-time.md.
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
#              events for the release THAT CARRY outcome=resolved
# Both anchors source the ts_iso field per pipeline-event-log-schema.md § 2.
#
# WHY T_DEPLOY REQUIRES outcome=resolved (#4215). A deploy in which every target
# FAILED is not a deploy. Before this conjunct existed, a release whose deploy rows
# all read outcome=escalated still produced a measured duration — the anchor read the
# subtype and ignored the outcome column entirely — so "Cycle-Time returns a value
# rather than N/A" was satisfiable by total failure and could not distinguish the goal
# being met from the goal being defeated. Restricting the anchor to resolved rows makes
# a failed deploy read N/A, which is the honest answer, and the N/A diagnostic below
# names WHICH kind of N/A it is so the two are never conflated again.
#
# WHY deploy-package IS NOT AN ANCHOR — a DECLARED narrowing, not an oversight. A
# package deploy is not evidence that the release's skills reached the install path, so
# anchoring cycle time on one would overstate what was observed. The bounded consequence
# is that a package-ONLY deploy yields no T_DEPLOY; that is structurally near-impossible
# because the deploy tool populates its package set only alongside skills.
#
# Usage:
#   ./compute-cycle-time.sh <release>           # human-readable: "47m" or "2h17m" or "N/A"
#   ./compute-cycle-time.sh --version <release> # same as positional form
#
# <release> is the MILESTONE SLUG — the release join key per
# pipeline-event-log-schema.md § 2a. Row selection routes through the query
# tool's --release (the § 2a ladder), so a legacy vX.Y still resolves; the slug
# is the canonical form. The flag keeps its --version spelling for caller
# compatibility.
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
  /usr/bin/sed -n '4,29p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
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

# ─── T_DEPLOY anchor-row selection (#4215) ───────────────────────────────────
#
# Reads pipe-delimited event rows on stdin, echoes only those eligible to anchor
# T_DEPLOY. Factored out of the main flow so the self-test can grade the PREDICATE
# rather than only the arithmetic around it — an inline filter is unreachable from a
# test, and an untestable filter is exactly the shape of control this release exists to
# eliminate.
#
# Field map under FS=" | ": the row's leading "| " has no preceding space, so it is not
# a delimiter — $1 retains it and reads "| <ts_iso>", $2 is version, $5 is event_subtype
# and $9 is outcome.
select_deploy_anchor_rows() {
  /usr/bin/awk -F ' \\| ' '($5 == "deploy-skill" || $5 == "deploy-harness") && $9 == "resolved" { print }'
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

  # ─── Group CT — T_DEPLOY anchor eligibility (#4215) ────────────────────────
  #
  # The predicate, not the arithmetic. Every arm is paired with the mutation that must
  # turn it red: delete the `&& $9 == "resolved"` conjunct from select_deploy_anchor_rows
  # and CT-2, CT-4 and CT-5 all fail. An arm whose mutation leaves it green is theatre.
  #
  # Fixture rows use the field layout query-pipeline-event.sh emits:
  #   "| ts | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
  CT_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-02T10:00:00Z | slug-a | 12 | deployment-status | deploy-skill | hub | skill:a | CHEAP | resolved | p |
| 2026-01-02T10:00:05Z | slug-a | 12 | deployment-status | deploy-harness | hub | harness:h | CHEAP | resolved | p |
| 2026-01-02T11:00:00Z | slug-a | 12 | deployment-status | deploy-skill | hub | skill:b | CHEAP | escalated | p |
| 2026-01-02T11:30:00Z | slug-a | 12 | deployment-status | deploy-package | hub | package:p | CHEAP | resolved | p |
| 2026-01-02T12:00:00Z | slug-a | 12 | deployment-status | deploy-skill | hub | skill:c | CHEAP | pending | p |
ROWS
)"

  # CT-1 — SENSITIVITY. The selector fires at all: the two resolved target rows are kept.
  #        Without this arm, every "excluded" assertion below would also pass on a
  #        selector that returns nothing, which proves nothing.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c . || true)"
  if [[ "$RESULT" != "2" ]]; then
    die "self-test: CT-1 selector must keep the 2 resolved deploy-skill/deploy-harness rows, got $RESULT"
  fi

  # CT-2 — THE PRF-1 ARM. An escalated deploy-skill row must NOT anchor T_DEPLOY. This
  #        is the case that previously produced a measured duration for a deploy in
  #        which nothing deployed.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c 'skill:b' || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-2 an escalated deploy row must NOT be anchor-eligible, got $RESULT"
  fi

  # CT-3 — the DECLARED narrowing: deploy-package is audit-only and never an anchor.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c 'deploy-package' || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-3 deploy-package must NOT be anchor-eligible (declared narrowing), got $RESULT"
  fi

  # CT-4 — outcome=pending is not a terminal success either. The conjunct is an
  #        ALLOWLIST on `resolved`, not a denylist on `escalated`, and this arm is what
  #        makes that difference observable.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c 'skill:c' || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-4 a pending deploy row must NOT be anchor-eligible, got $RESULT"
  fi

  # CT-5 — MAX over the ELIGIBLE set, not over all rows. The escalated row at 11:00 and
  #        the package row at 11:30 are both LATER than the last resolved target row at
  #        10:00:05, so a selector that leaked either would move the anchor forward and
  #        silently inflate every cycle time it reports.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows \
            | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); print t }' | /usr/bin/sort | /usr/bin/tail -1)"
  if [[ "$RESULT" != "2026-01-02T10:00:05Z" ]]; then
    die "self-test: CT-5 T_DEPLOY must be the MAX over ELIGIBLE rows (2026-01-02T10:00:05Z), got $RESULT"
  fi

  # CT-6 — SPECIFICITY. A log containing only non-eligible rows yields an empty
  #        selection, so CT-1's non-zero is the selector detecting rather than leaking.
  RESULT="$(printf '%s\n' "$CT_ROWS" | /usr/bin/grep -E 'escalated|pending|deploy-package' | select_deploy_anchor_rows | /usr/bin/grep -c . || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-6 a population of only non-eligible rows must select nothing, got $RESULT"
  fi

  echo "self-test: PASS"
  echo "  ISO8601 delta arithmetic validated"
  echo "  human formatter validated (sub-hour, over-hour, exact-hour, zero)"
  echo "  malformed-input rejection validated"
  echo "  query-pipeline-event.sh dependency validated"
  echo "  T_DEPLOY anchor eligibility validated (#4215, group CT):"
  echo "    CT-1 SENSITIVITY the selector keeps 2 resolved target rows / CT-2 an escalated deploy row is NOT an anchor (the defect: a totally-failed deploy used to yield a measured duration) / CT-3 deploy-package is audit-only, never an anchor (declared narrowing) / CT-4 outcome=pending is excluded — the conjunct is an allowlist on resolved, not a denylist on escalated / CT-5 MAX is taken over the ELIGIBLE set, so a later ineligible row cannot move the anchor forward / CT-6 SPECIFICITY a non-eligible-only population selects nothing"
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
# --release, NOT --version. The release join key is the milestone SLUG
# (pipeline-event-log-schema.md § 2a); a raw --version filter carrying a vX.Y
# matches ZERO slug-keyed rows, and this tool's `|| true` + empty-guard would
# then report N/A rather than erroring — a silent zero on the very metric the
# tool exists to produce. --release resolves through the § 2a ladder and
# accepts either form, so a legacy vX.Y argument still resolves.
GATE_ROWS="$("$QUERY_TOOL" --release "$VERSION" --event-type gate-outcome 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
T_GO=""
if [[ -n "$GATE_ROWS" ]]; then
  # Filter to plan-review-go subtype (field 5 in pipe-delimited row); take MIN(ts_iso)
  PLAN_REVIEW_GO_ROWS="$(echo "$GATE_ROWS" | /usr/bin/awk -F ' \\| ' '$5 == "plan-review-go" { print }')"
  if [[ -n "$PLAN_REVIEW_GO_ROWS" ]]; then
    # ts_iso is $1, NOT $2. FS is " | " (space-pipe-space) and the row's leading
    # "| " has no preceding space, so it is not a delimiter: $1 retains it and
    # reads "| <ts_iso>", $2 is the VERSION column. Strip the leading "| " and
    # take $1. (The $5 == subtype test above is already correct under this map.)
    # Sort by ts_iso; take first (earliest).
    T_GO="$(echo "$PLAN_REVIEW_GO_ROWS" | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); print t }' | /usr/bin/sort | /usr/bin/head -1)"
  fi
fi

# ─── Extract T_DEPLOY (latest deploy-skill OR deploy-harness event) ──────────

DEPLOY_ROWS="$("$QUERY_TOOL" --release "$VERSION" --event-type deployment-status 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
T_DEPLOY=""
DEPLOY_ROW_COUNT=0
DEPLOY_TARGET_ROWS=""
if [[ -n "$DEPLOY_ROWS" ]]; then
  DEPLOY_ROW_COUNT="$(echo "$DEPLOY_ROWS" | /usr/bin/grep -c . || true)"
  # Anchor-eligible rows only: deploy-skill|deploy-harness AND outcome=resolved.
  DEPLOY_TARGET_ROWS="$(echo "$DEPLOY_ROWS" | select_deploy_anchor_rows)"
  if [[ -n "$DEPLOY_TARGET_ROWS" ]]; then
    # ts_iso is $1 minus the leading "| " — see the T_GO note above.
    T_DEPLOY="$(echo "$DEPLOY_TARGET_ROWS" | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); print t }' | /usr/bin/sort | /usr/bin/tail -1)"
  fi
fi

# ─── N/A determination + emission ────────────────────────────────────────────

if [[ -z "$T_GO" || -z "$T_DEPLOY" ]]; then
  # N/A — emit reason on stderr so the operator / caller can diagnose
  # The two N/A causes below are DIFFERENT FACTS and are reported as such. Collapsing
  # them into one message would recreate, one layer up, the very ambiguity the
  # outcome=resolved conjunct was added to remove: "no deploy happened" and "every
  # deploy target failed" would once again read identically to the operator.
  MISSING=""
  [[ -z "$T_GO" ]] && MISSING="${MISSING}no gate-outcome/plan-review-go event for $VERSION; "
  if [[ -z "$T_DEPLOY" ]]; then
    if [[ "$DEPLOY_ROW_COUNT" -gt 0 ]]; then
      MISSING="${MISSING}${DEPLOY_ROW_COUNT} deployment-status row(s) exist for $VERSION but NONE is an anchor-eligible deploy-skill/deploy-harness row with outcome=resolved — the deploy ran and its targets did not succeed. This is NOT the same as no deploy having occurred; "
    else
      MISSING="${MISSING}no deployment-status/deploy-skill or deploy-harness event for $VERSION; "
    fi
  fi
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
