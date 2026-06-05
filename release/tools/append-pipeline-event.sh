#!/usr/bin/env bash
# append-pipeline-event.sh — Pipeline event log writer
# Appends one row to pmo-platform/engineering/evals/results/pipeline-event-log.md
# per the schema at pmo-platform/reference/standards/pipeline-event-log-schema.md.
#
# Per the pipeline-event spec (Stage 5).
#
# Usage:
#   ./append-pipeline-event.sh \
#       --version v2.07a \
#       --stage 5 \
#       --event-type decision \
#       --event-subtype scope-lock \
#       --actor operator \
#       --subject milestone:#N \
#       --reversibility EXPENSIVE \
#       --outcome resolved \
#       --payload 'verdict:approved; cross-d-scan:clean'
#
# Flags:
#   --dry-run     : validate + print row without appending
#   --self-test   : append a test row, verify, then revert; exit 0 on success
#   --help        : print usage
#
# Cutover: events captured strictly AFTER the cutover merge SHA. Writers are
# expected to honor the cutover; this script does not gate by version.
#
# Exit codes: 0 = success, 1 = validation failure, 2 = I/O failure

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
LOG_FILE="$REPO_ROOT/pmo-platform/engineering/evals/results/pipeline-event-log.md"
WRITE_LOG="$REPO_ROOT/pmo-platform/engineering/evals/results/pipeline-event-log-write.log"

# ─── Enum definitions (must match pipeline-event-log-schema.md § 3) ──────────

EVENT_TYPES=(
  gate-outcome
  decision
  escalation
  self-repair
  iteration
  scope-change
  re-review
  deployment-status
  release-synthesis
)

# Subtype enums, scoped per event_type
SUBTYPES_gate_outcome="g1-g2 g3-release-readiness dt-pass dt-conditional-pass dt-return qa-acceptance qa-rejection plan-review-go plan-review-no-go plan-review-readiness-scan goal-conformance"
SUBTYPES_decision="d-class adr-closed adr-opened scope-lock a6-new-track-rationale a7-bundle-amend a7-bundle-rebundle a7-bundle-defer cross-d-upstream-compat empirical-verification-finding outcome-statement-authored"
SUBTYPES_escalation="tier-0 tier-1 tier-2 tier-3"
SUBTYPES_self_repair="retry escalate rollback"
# Note: iteration subtypes use pattern `dt-eng-pass-N` or `qa-dt-pass-N` where N is
# the post-increment pass count. Validated as starts-with prefix.
SUBTYPES_iteration_prefixes="dt-eng-pass- qa-dt-pass-"
SUBTYPES_scope_change="tier-1-adjust tier-2-scope-change tier-3-plan-rejection redaction"
SUBTYPES_re_review="phase-a0-row phase-0.5-row"
SUBTYPES_deployment_status="deploy-skill deploy-harness deploy-package deploy-rules-mirror deploy-helper"
SUBTYPES_release_synthesis="learnings-triple qc4-05-result qc4-06-result"

REVERSIBILITY_VALUES="CHEAP MODERATE EXPENSIVE IRREVERSIBLE"
OUTCOME_VALUES="resolved pending escalated superseded"

# ─── Helpers ─────────────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,21p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# is_in_list "value" "space-separated list" — exit 0 if value in list
is_in_list() {
  local needle="$1"
  local haystack=" $2 "
  case "$haystack" in
    *" $needle "*) return 0 ;;
    *) return 1 ;;
  esac
}

# starts_with_any "value" "space-separated prefixes" — exit 0 if value starts with any prefix
starts_with_any() {
  local value="$1"
  shift
  local prefix
  for prefix in $*; do
    case "$value" in
      "$prefix"*) return 0 ;;
    esac
  done
  return 1
}

validate_subtype() {
  local event_type="$1"
  local subtype="$2"
  case "$event_type" in
    gate-outcome) is_in_list "$subtype" "$SUBTYPES_gate_outcome" ;;
    decision) is_in_list "$subtype" "$SUBTYPES_decision" ;;
    escalation) is_in_list "$subtype" "$SUBTYPES_escalation" ;;
    self-repair) is_in_list "$subtype" "$SUBTYPES_self_repair" ;;
    iteration) starts_with_any "$subtype" "$SUBTYPES_iteration_prefixes" ;;
    scope-change) is_in_list "$subtype" "$SUBTYPES_scope_change" ;;
    re-review) is_in_list "$subtype" "$SUBTYPES_re_review" ;;
    deployment-status) is_in_list "$subtype" "$SUBTYPES_deployment_status" ;;
    release-synthesis) is_in_list "$subtype" "$SUBTYPES_release_synthesis" ;;
    *) return 1 ;;
  esac
}

# Validate actor: hub | spoke:#N | operator | skill:NAME
validate_actor() {
  local actor="$1"
  case "$actor" in
    hub|operator) return 0 ;;
    spoke:\#*) [[ "$actor" =~ ^spoke:#[0-9]+$ ]] && return 0 ;;
    skill:*) [[ "$actor" =~ ^skill:[a-zA-Z0-9_-]+$ ]] && return 0 ;;
  esac
  return 1
}

validate_ts_iso() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
STAGE=""
EVENT_TYPE=""
EVENT_SUBTYPE=""
ACTOR=""
SUBJECT=""
REVERSIBILITY=""
OUTCOME=""
PAYLOAD=""
DRY_RUN=false
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --event-type) EVENT_TYPE="$2"; shift 2 ;;
    --event-subtype) EVENT_SUBTYPE="$2"; shift 2 ;;
    --actor) ACTOR="$2"; shift 2 ;;
    --subject) SUBJECT="$2"; shift 2 ;;
    --reversibility) REVERSIBILITY="$2"; shift 2 ;;
    --outcome) OUTCOME="$2"; shift 2 ;;
    --payload) PAYLOAD="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    --help|-h) usage ;;
    *) die "Unknown flag: $1" ;;
  esac
done

# ─── Self-test mode ──────────────────────────────────────────────────────────

if [[ "$SELF_TEST" == "true" ]]; then
  # Validates schema enums; appends a test row then reverts.
  if [[ ! -f "$LOG_FILE" ]]; then
    die "Log file missing: $LOG_FILE" 2
  fi

  # Snapshot
  PRE_LINES=$(/usr/bin/wc -l < "$LOG_FILE" | /usr/bin/tr -d ' ')
  PRE_WRITE_LINES=$(/usr/bin/wc -l < "$WRITE_LOG" | /usr/bin/tr -d ' ')

  # Build & validate a test row
  TS_TEST="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  validate_ts_iso "$TS_TEST" || die "self-test: ts_iso format check failed"
  validate_subtype "decision" "scope-lock" || die "self-test: subtype validation failed"
  validate_subtype "self-repair" "retry" || die "self-test: self-repair subtype check failed"
  validate_subtype "iteration" "dt-eng-pass-2" || die "self-test: iteration prefix check failed"
  validate_actor "hub" || die "self-test: actor 'hub' check failed"
  validate_actor "spoke:#1" || die "self-test: actor 'spoke:#N' check failed"
  validate_actor "skill:release-planner" || die "self-test: actor 'skill:NAME' check failed"
  validate_actor "operator" || die "self-test: actor 'operator' check failed"
  is_in_list "EXPENSIVE" "$REVERSIBILITY_VALUES" || die "self-test: reversibility enum check failed"
  is_in_list "resolved" "$OUTCOME_VALUES" || die "self-test: outcome enum check failed"

  # Negative tests
  if validate_subtype "decision" "bogus-subtype" 2>/dev/null; then
    die "self-test: subtype rejection check failed (bogus accepted)"
  fi
  if validate_actor "bogus" 2>/dev/null; then
    die "self-test: actor rejection check failed (bogus accepted)"
  fi

  # Append a sentinel row, then revert
  TEST_ROW="| ${TS_TEST} | v2.07a-selftest | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | resolved | selftest-row;will-be-reverted |"
  TEST_WRITE_LINE="${TS_TEST}	selftest-sha	hub	decision:scope-lock"

  printf '%s\n' "$TEST_ROW" >> "$LOG_FILE"
  printf '%s\n' "$TEST_WRITE_LINE" >> "$WRITE_LOG"

  POST_LINES=$(/usr/bin/wc -l < "$LOG_FILE" | /usr/bin/tr -d ' ')
  if [[ "$POST_LINES" -ne $((PRE_LINES + 1)) ]]; then
    # Cleanup attempt
    /usr/bin/head -n "$PRE_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && /bin/mv "$LOG_FILE.tmp" "$LOG_FILE"
    /usr/bin/head -n "$PRE_WRITE_LINES" "$WRITE_LOG" > "$WRITE_LOG.tmp" && /bin/mv "$WRITE_LOG.tmp" "$WRITE_LOG"
    die "self-test: append produced unexpected line count delta (expected +1, got $((POST_LINES - PRE_LINES)))"
  fi

  # Revert
  /usr/bin/head -n "$PRE_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && /bin/mv "$LOG_FILE.tmp" "$LOG_FILE"
  /usr/bin/head -n "$PRE_WRITE_LINES" "$WRITE_LOG" > "$WRITE_LOG.tmp" && /bin/mv "$WRITE_LOG.tmp" "$WRITE_LOG"

  # Confirm revert
  REVERT_LINES=$(/usr/bin/wc -l < "$LOG_FILE" | /usr/bin/tr -d ' ')
  if [[ "$REVERT_LINES" -ne "$PRE_LINES" ]]; then
    die "self-test: revert failed (expected $PRE_LINES lines, got $REVERT_LINES)"
  fi

  echo "self-test: PASS"
  echo "  schema enums validated (event_type, event_subtype, actor, reversibility, outcome)"
  echo "  positive + negative tests passed"
  echo "  append + revert cycle confirmed (log + write-log)"
  exit 0
fi

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: --version"
[[ -z "$STAGE" ]] && die "Required: --stage"
[[ -z "$EVENT_TYPE" ]] && die "Required: --event-type"
[[ -z "$EVENT_SUBTYPE" ]] && die "Required: --event-subtype"
[[ -z "$ACTOR" ]] && die "Required: --actor"
[[ -z "$SUBJECT" ]] && die "Required: --subject"
[[ -z "$REVERSIBILITY" ]] && die "Required: --reversibility"
[[ -z "$OUTCOME" ]] && die "Required: --outcome"
# payload may be empty

# ─── Enum validation ─────────────────────────────────────────────────────────

[[ "$STAGE" =~ ^[0-9]+$ ]] || die "stage must be int: got '$STAGE'"
[[ "$STAGE" -ge 1 && "$STAGE" -le 13 ]] || die "stage must be 1..13: got $STAGE"

is_in_list "$EVENT_TYPE" "${EVENT_TYPES[*]}" || die "Invalid event_type: '$EVENT_TYPE' (allowed: ${EVENT_TYPES[*]})"
validate_subtype "$EVENT_TYPE" "$EVENT_SUBTYPE" || die "Invalid event_subtype '$EVENT_SUBTYPE' for event_type '$EVENT_TYPE' — see pipeline-event-log-schema.md § 3"
validate_actor "$ACTOR" || die "Invalid actor: '$ACTOR' (allowed: hub, operator, spoke:#N, skill:NAME)"
is_in_list "$REVERSIBILITY" "$REVERSIBILITY_VALUES" || die "Invalid reversibility: '$REVERSIBILITY' (allowed: $REVERSIBILITY_VALUES)"
is_in_list "$OUTCOME" "$OUTCOME_VALUES" || die "Invalid outcome: '$OUTCOME' (allowed: $OUTCOME_VALUES)"

# Payload length cap (§ 4.3)
if [[ ${#PAYLOAD} -gt 300 ]]; then
  die "Payload exceeds 300 char limit (got ${#PAYLOAD}); use a pointer to existing surface instead"
fi

# Reject pipe character in payload (would corrupt markdown table)
if [[ "$PAYLOAD" == *"|"* ]]; then
  die "Payload contains '|' (pipe character) — reserved as column separator; escape or replace before append"
fi

# ─── Build row ───────────────────────────────────────────────────────────────

TS_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ROW="| ${TS_ISO} | ${VERSION} | ${STAGE} | ${EVENT_TYPE} | ${EVENT_SUBTYPE} | ${ACTOR} | ${SUBJECT} | ${REVERSIBILITY} | ${OUTCOME} | ${PAYLOAD} |"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] would append row:"
  echo "$ROW"
  echo "[DRY-RUN] would append write-log entry"
  exit 0
fi

# ─── Append + log ────────────────────────────────────────────────────────────

[[ -f "$LOG_FILE" ]] || die "Log file missing: $LOG_FILE" 2
[[ -f "$WRITE_LOG" ]] || die "Write-log missing: $WRITE_LOG" 2

# Compute row SHA1 for write-log entry
ROW_SHA1="$(printf '%s' "$ROW" | /usr/bin/shasum | /usr/bin/awk '{print $1}')"

# Atomic single-row append (POSIX guarantees single-writer safety for rows < PIPE_BUF)
printf '%s\n' "$ROW" >> "$LOG_FILE"
printf '%s\t%s\t%s\t%s:%s\n' "$TS_ISO" "$ROW_SHA1" "$ACTOR" "$EVENT_TYPE" "$EVENT_SUBTYPE" >> "$WRITE_LOG"

echo "appended: pipeline-event-log.md ($EVENT_TYPE/$EVENT_SUBTYPE; subject=$SUBJECT)"
