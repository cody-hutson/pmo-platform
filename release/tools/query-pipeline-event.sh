#!/usr/bin/env bash
# query-pipeline-event.sh — Pipeline event log reader with pre-canned queries
# Reads the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md
# (canonical default: ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/),
# per the schema at release/references/standards/pipeline-event-log-schema.md.
# Resolves the SAME log location as append-pipeline-event.sh (writer↔reader parity).
#
# Per the pipeline-event spec (Stage 5).
#
# Usage:
#   ./query-pipeline-event.sh --version v2.07a                                 # all events in release
#   ./query-pipeline-event.sh --version v2.07a --stage 12                      # release + stage filter
#   ./query-pipeline-event.sh --subject "<id>"                                  # all events for a given subject
#   ./query-pipeline-event.sh --event-type self-repair                         # all retries/escalates/rollbacks
#   ./query-pipeline-event.sh --event-type release-synthesis --event-subtype learnings-triple  # subtype filter
#   ./query-pipeline-event.sh --r-class                                        # EXPENSIVE + IRREVERSIBLE decisions
#   ./query-pipeline-event.sh --count                                          # row count summary
#
# Flags can compose:
#   ./query-pipeline-event.sh --version v2.07a --event-type decision --r-class
#
# Cross-surface JOIN pattern (run manually after this script; <RESULTS> is the
# resolved <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>, default
# ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results):
#   grep -h '#N' <RESULTS>/{pipeline-event-log,calibration-data,iteration-log}.md
#
# Exit codes: 0 = success (rows may be 0), 1 = file missing / invalid args

set -euo pipefail
export PATH="/usr/bin:/bin"

# ─── Path resolution ─────────────────────────────────────────────────────────
#
# MUST resolve to the SAME log location as append-pipeline-event.sh, so a row
# written by the append CLI is read back by this query CLI. Resolution mirrors
# the writer verbatim.
#
# Repo root is TWO levels up from this script (release/tools/) — NOT three. The
# prior `../../..` walked above the repo and, from a worktree at
# .claude/worktrees/<name>/release/tools/, mis-anchored entirely (the extinct-path
# reader bug, sibling to the writer's #590/#591/#679).
#
# The event log is OPERATOR-INSTANCE content (gitignored, not in the repo tree):
# it lives at <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md per the
# schema doc + core/standards/depersonalization-spec.md §4. Resolution order
# (mirrors append-pipeline-event.sh / cleanup-orphan-state.sh / automated-closeout.sh):
# env override → operator.toml → canonical default
# (${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/).

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# REPO_ROOT retained verbatim from append-pipeline-event.sh for resolution-block
# parity (the writer uses it for SCHEMA_FILE; the reader has no schema dependency,
# so it is unused here). Two levels up — NOT three; see header note above.
# shellcheck disable=SC2034
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Workspace root (env → operator.toml → default), per the cleanup-tool pattern.
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"
if [[ -z "$WORKSPACE_ROOT" ]]; then
  _operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [[ -r "$_operator_toml" ]]; then
    # `|| true`: an absent key makes grep exit non-zero, which would abort under
    # set -e / pipefail — tolerate it and fall through to the default.
    _wr=$( { grep -E '^claude_workspace_root' "$_operator_toml" 2>/dev/null || true; } | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -n "$_wr" ]] && WORKSPACE_ROOT="$_wr"
  fi
fi
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/Claude}"

# Operator-instance evals-results dir (env → operator.toml override → default).
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH> resolves verbatim when the operator.toml
# override is set; otherwise to the ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/<stem>/
# canonical default per depersonalization-spec.md §4.
EVALS_RESULTS_PATH="${EVALS_RESULTS_PATH:-}"
if [[ -z "$EVALS_RESULTS_PATH" ]]; then
  _operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [[ -r "$_operator_toml" ]]; then
    # `|| true`: this key is absent on instances that use the canonical default;
    # tolerate grep's non-zero exit under set -e / pipefail.
    _er=$( { grep -E '^operator_instance_evals_results_path' "$_operator_toml" 2>/dev/null || true; } | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -n "$_er" ]] && EVALS_RESULTS_PATH="$_er"
  fi
fi
EVALS_RESULTS_PATH="${EVALS_RESULTS_PATH:-${WORKSPACE_ROOT}/personal/pmo-instance/evals/results}"

LOG_FILE="$EVALS_RESULTS_PATH/pipeline-event-log.md"

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  /usr/bin/sed -n '11,26p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

VERSION=""
STAGE=""
SUBJECT=""
EVENT_TYPE=""
EVENT_SUBTYPE=""
R_CLASS=false
COUNT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --subject) SUBJECT="$2"; shift 2 ;;
    --event-type) EVENT_TYPE="$2"; shift 2 ;;
    --event-subtype) EVENT_SUBTYPE="$2"; shift 2 ;;
    --r-class) R_CLASS=true; shift ;;
    --count) COUNT=true; shift ;;
    --help|-h) usage ;;
    *) die "Unknown flag: $1" ;;
  esac
done

[[ -f "$LOG_FILE" ]] || die "Log file missing: $LOG_FILE"

# Extract data rows (skip the markdown header + separator)
# Data rows start with '| ' followed by a digit (ISO timestamp); other '|' lines
# are header or separator.
DATA_ROWS=$(/usr/bin/grep -E '^\| [0-9]{4}-[0-9]{2}-' "$LOG_FILE" 2>/dev/null || true)

# Apply filters (awk on pipe-delimited fields)
# FS is " | " (space-pipe-space). Leading "| " is NOT a delimiter (no leading
# space), so $1 retains the leading "| " and field indices shift by 1 from
# the visible column position. Actual field map:
#   $1="| ts_iso"  $2=version  $3=stage  $4=event_type  $5=event_subtype
#   $6=actor      $7=subject  $8=reversibility  $9=outcome  $10="payload |"

filter_awk='
BEGIN { FS = " \\| "; OFS = " | " }
{
  line = $0
  if (version != "" && $2 != version) next
  if (stage != "" && $3 != stage) next
  if (event_type != "" && $4 != event_type) next
  if (event_subtype != "" && $5 != event_subtype) next
  if (subject != "" && index($7, subject) == 0) next
  if (r_class == "true" && $8 != "EXPENSIVE" && $8 != "IRREVERSIBLE") next
  print line
}'

FILTERED=$(echo "$DATA_ROWS" | /usr/bin/awk \
  -v version="$VERSION" \
  -v stage="$STAGE" \
  -v event_type="$EVENT_TYPE" \
  -v event_subtype="$EVENT_SUBTYPE" \
  -v subject="$SUBJECT" \
  -v r_class="$R_CLASS" \
  "$filter_awk")

if [[ "$COUNT" == "true" ]]; then
  if [[ -z "$FILTERED" ]]; then
    echo "0"
  else
    echo "$FILTERED" | /usr/bin/wc -l | /usr/bin/tr -d ' '
  fi
  exit 0
fi

# Print header for readability, then filtered rows (empty body = legitimate result pre-cutover)
echo "| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
echo "|---|---|---|---|---|---|---|---|---|---|"
if [[ -n "$FILTERED" ]]; then
  echo "$FILTERED"
fi
