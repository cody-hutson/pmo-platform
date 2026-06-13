#!/usr/bin/env bash
# append-pipeline-event.sh — Pipeline event log writer
# Appends one row to the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md
# (canonical default: ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/),
# per the schema at release/references/standards/pipeline-event-log-schema.md.
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

# ─── Path resolution ─────────────────────────────────────────────────────────
#
# Repo root is TWO levels up from this script (release/tools/) — NOT three. The
# prior `../../..` walked above the repo and, from a worktree at
# .claude/worktrees/<name>/release/tools/, mis-anchored entirely (the extinct-path
# log-writer bug).
#
# The event log is OPERATOR-INSTANCE content (gitignored, not in the repo tree):
# it lives at <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md per the
# schema doc + core/standards/depersonalization-spec.md §4. Resolution order
# (mirrors the cleanup-orphan-state.sh / automated-closeout.sh WORKSPACE_ROOT
# precedent): env override → operator.toml → canonical default
# (${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/).

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
SCHEMA_FILE="$REPO_ROOT/release/references/standards/pipeline-event-log-schema.md"

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
WRITE_LOG="$EVALS_RESULTS_PATH/pipeline-event-log-write.log"

# ─── Enum definitions (parsed from pipeline-event-log-schema.md § 3) ─────────
#
# The event-type enum and per-type literal subtypes are read DATA-DRIVEN from the
# schema's § 3 table (the source of truth) so the validator cannot drift out of
# sync with the doc. Only backtick-wrapped tokens are extracted, so parenthetical
# prose in a cell (which may itself contain "/" — e.g. ALIGNED/DIVERGED/MISALIGNED)
# never leaks into the enum. Falls back to a static mirror if the schema is
# unreadable (e.g. invoked outside the repo tree). The `iteration` subtypes are a
# PREFIX pattern (`dt-eng-pass-N` / `qa-dt-pass-N`), not literal enum members, so
# they remain a hardcoded prefix list — validated by starts-with, below.

# Parse the schema § 3 table → "type|subtype subtype …" lines on stdout.
# Each data row: | `type` | description | `s1` / `s2` / … |
# We extract col-1's backtick token as the type and col-3's backtick tokens as
# the literal subtypes. The `iteration` row's subtypes are ignored here (prefix-
# validated separately).
parse_schema_enum() {
  [[ -r "$SCHEMA_FILE" ]] || return 1
  # Field map with FS="|" on a leading-pipe row "| col1 | col2 | col3 |":
  #   $1="" (before leading pipe)  $2=col1 (type)  $3=col2 (description)
  #   $4=col3 (subtypes)  $5="" (after trailing pipe)
  # Taking col-3 ($4) ONLY means a backtick token in the description ($3) — e.g.
  # a doc link — cannot leak into the subtype list.
  awk -F'|' '
    # Bound the scan to the "## 3." section ONLY, so other tables in the doc
    # (the §11 mode table, the §11.3 field-rationale table, etc.) cannot leak
    # bogus event types into the enum.
    /^## 3\./        { in_s3 = 1; next }
    in_s3 && /^## /  { in_s3 = 0 }
    # Table rows whose col-1 is a backtick-quoted token. Token char class allows
    # "." so subtypes like `phase-0.5-row` are captured whole.
    in_s3 && $2 ~ /^ *`[a-z0-9.-]+` *$/ {
      t = $2; sub(/^ *`/, "", t); sub(/` *$/, "", t)   # type from col-1
      rest = $4                                          # subtypes from col-3 ONLY
      subs = ""
      while (match(rest, /`[a-z0-9.-]+`/)) {
        tok = substr(rest, RSTART+1, RLENGTH-2)
        subs = (subs == "" ? tok : subs " " tok)
        rest = substr(rest, RSTART+RLENGTH)
      }
      print t "|" subs
    }
  ' "$SCHEMA_FILE"
}

# Build the enum from the schema (or static fallback). bash 3.2 (the macOS system
# bash this corpus pins to via PATH=/usr/bin:/bin) has NO associative arrays, so
# the map is held as two plain strings:
#   EVENT_TYPES   — space-separated list of valid event types
#   SUBTYPES_LINES — one "type<TAB>subtype subtype …" line per type (looked up by
#                    validate_subtype via a tab-anchored grep)
# `iteration` carries no literal subtype line — its subtypes are a PREFIX pattern.

# Static fallback (used only when the schema file is unreadable, e.g. invoked
# outside the repo tree); kept in lockstep with § 3.
_FALLBACK_SUBTYPES_LINES="$(printf '%s\n' \
  "gate-outcome	g1-g2 g3-release-readiness dt-pass dt-conditional-pass dt-return qa-acceptance qa-rejection plan-review-go plan-review-no-go plan-review-readiness-scan goal-conformance" \
  "decision	d-class adr-closed adr-opened scope-lock a6-new-track-rationale a7-bundle-amend a7-bundle-rebundle a7-bundle-defer cross-d-upstream-compat empirical-verification-finding action-item-opened action-item-started action-item-resolved action-item-cancelled action-item-superseded queued-pending-approval approval-deferred outcome-statement-authored" \
  "escalation	tier-0 tier-1 tier-2 tier-3" \
  "self-repair	retry escalate rollback" \
  "scope-change	tier-1-adjust tier-2-scope-change tier-3-plan-rejection redaction" \
  "re-review	phase-a0-row phase-0.5-row" \
  "deployment-status	deploy-skill deploy-harness deploy-package deploy-rules-mirror deploy-helper" \
  "release-synthesis	learnings-triple qc4-05-result qc4-06-result" \
  "test-run	suite-pass suite-fail suite-skip")"

_schema_rows="$(parse_schema_enum 2>/dev/null || true)"
if [[ -n "$_schema_rows" ]]; then
  # parse_schema_enum emits "type|subtypes"; convert "|" → TAB for the lookup table.
  SUBTYPES_LINES="$(printf '%s\n' "$_schema_rows" | sed 's/|/\t/')"
else
  SUBTYPES_LINES="$_FALLBACK_SUBTYPES_LINES"
fi
# EVENT_TYPES = the first field (the type) of every line, space-joined.
EVENT_TYPES="$(printf '%s\n' "$SUBTYPES_LINES" | awk -F'\t' 'NF{print $1}' | tr '\n' ' ')"

# `iteration` subtypes are a PREFIX pattern, not literal members (validated below).
SUBTYPES_iteration_prefixes="dt-eng-pass- qa-dt-pass-"

REVERSIBILITY_VALUES="CHEAP MODERATE EXPENSIVE IRREVERSIBLE"
OUTCOME_VALUES="resolved pending escalated superseded"

# ─── Helpers ─────────────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '10,25p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# Seed the log + write-log if absent (first emit on a fresh operator instance).
# The log gets the schema header row; the write-log starts empty. Parent dir is
# created if missing (seed-if-absent with the schema header, so the first emit on
# a fresh operator instance does not fail).
seed_if_absent() {
  /bin/mkdir -p "$EVALS_RESULTS_PATH" 2>/dev/null \
    || die "cannot create evals-results dir: $EVALS_RESULTS_PATH" 2
  if [[ ! -f "$LOG_FILE" ]]; then
    {
      printf '%s\n\n' "# Pipeline Event Log"
      printf '%s\n\n' "Append-only structured audit rows per \`release/references/standards/pipeline-event-log-schema.md\`."
      printf '%s\n' "| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
      printf '%s\n' "|---|---|---|---|---|---|---|---|---|---|"
    } > "$LOG_FILE" || die "cannot seed log file: $LOG_FILE" 2
  fi
  [[ -f "$WRITE_LOG" ]] || : > "$WRITE_LOG" || die "cannot seed write-log: $WRITE_LOG" 2
}

# truncate_to_lines <file> <n> — keep the first <n> lines of <file>. Handles n=0
# (BSD `head -n 0` is an error, so empty the file directly).
truncate_to_lines() {
  local f="$1" n="$2"
  if [[ "$n" -le 0 ]]; then
    : > "$f"
  else
    /usr/bin/head -n "$n" "$f" > "$f.tmp" && /bin/mv "$f.tmp" "$f"
  fi
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
  # `iteration` is the one PREFIX-validated type (subtypes carry a trailing N).
  if [[ "$event_type" == "iteration" ]]; then
    starts_with_any "$subtype" "$SUBTYPES_iteration_prefixes"
    return
  fi
  # All other types validate against the schema-derived literal subtype list.
  # Look up the type's line in SUBTYPES_LINES (tab-anchored), strip the type +
  # tab, and test membership. An unknown event_type matches no line → reject.
  local _subs
  _subs="$(printf '%s\n' "$SUBTYPES_LINES" | awk -F'\t' -v t="$event_type" '$1==t{print $2; exit}')"
  [[ -n "$_subs" ]] || return 1
  is_in_list "$subtype" "$_subs"
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
  # Assert the resolved path's parent is reachable, then seed if absent.
  [[ -d "$(dirname "$LOG_FILE")" ]] || /bin/mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null \
    || die "self-test: resolved log parent dir not creatable: $(dirname "$LOG_FILE")" 2
  seed_if_absent
  echo "self-test: resolved LOG_FILE=$LOG_FILE"
  echo "self-test: enum source=$([[ -n "$_schema_rows" ]] && echo schema-§3-data-driven || echo static-fallback) ($(printf '%s\n' $EVENT_TYPES | grep -c . ) event types)"

  # Snapshot
  PRE_LINES=$(/usr/bin/wc -l < "$LOG_FILE" | /usr/bin/tr -d ' ')
  PRE_WRITE_LINES=$(/usr/bin/wc -l < "$WRITE_LOG" | /usr/bin/tr -d ' ')

  # Build & validate a test row
  TS_TEST="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  validate_ts_iso "$TS_TEST" || die "self-test: ts_iso format check failed"
  validate_subtype "decision" "scope-lock" || die "self-test: subtype validation failed"
  validate_subtype "self-repair" "retry" || die "self-test: self-repair subtype check failed"
  validate_subtype "iteration" "dt-eng-pass-2" || die "self-test: iteration prefix check failed"
  validate_subtype "test-run" "suite-pass" || die "self-test: test-run suite-pass subtype check failed"
  validate_subtype "test-run" "suite-fail" || die "self-test: test-run suite-fail subtype check failed"
  validate_subtype "test-run" "suite-skip" || die "self-test: test-run suite-skip subtype check failed"
  is_in_list "test-run" "$EVENT_TYPES" || die "self-test: test-run missing from EVENT_TYPES enum"
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
  if validate_subtype "test-run" "suite-bogus" 2>/dev/null; then
    die "self-test: test-run subtype rejection check failed (suite-bogus accepted)"
  fi
  if validate_subtype "bogus-type" "anything" 2>/dev/null; then
    die "self-test: unknown event_type rejection check failed (bogus-type accepted)"
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
    truncate_to_lines "$LOG_FILE" "$PRE_LINES"
    truncate_to_lines "$WRITE_LOG" "$PRE_WRITE_LINES"
    die "self-test: append produced unexpected line count delta (expected +1, got $((POST_LINES - PRE_LINES)))"
  fi

  # Revert
  truncate_to_lines "$LOG_FILE" "$PRE_LINES"
  truncate_to_lines "$WRITE_LOG" "$PRE_WRITE_LINES"

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

is_in_list "$EVENT_TYPE" "$EVENT_TYPES" || die "Invalid event_type: '$EVENT_TYPE' (allowed: $EVENT_TYPES)"
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

# Seed the log + write-log if this is the first emit on a fresh operator instance.
seed_if_absent

# Compute row SHA1 for write-log entry
ROW_SHA1="$(printf '%s' "$ROW" | /usr/bin/shasum | /usr/bin/awk '{print $1}')"

# Atomic single-row append (POSIX guarantees single-writer safety for rows < PIPE_BUF)
printf '%s\n' "$ROW" >> "$LOG_FILE"
printf '%s\t%s\t%s\t%s:%s\n' "$TS_ISO" "$ROW_SHA1" "$ACTOR" "$EVENT_TYPE" "$EVENT_SUBTYPE" >> "$WRITE_LOG"

echo "appended: pipeline-event-log.md ($EVENT_TYPE/$EVENT_SUBTYPE; subject=$SUBJECT)"
