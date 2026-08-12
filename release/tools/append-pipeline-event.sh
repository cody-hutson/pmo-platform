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
#       --version version-binding-lifecycle \   # milestone slug — NEVER a version
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
# `iteration` carries a line with an EMPTY subtype field: it contributes TYPE
# membership only. Its subtypes stay PREFIX-validated (`dt-eng-pass-N` /
# `qa-dt-pass-N`) by validate_subtype's short-circuit, which fires BEFORE the
# table lookup — so the empty field is never read.

# Static fallback (used only when the schema file is unreadable, e.g. invoked
# outside the repo tree). Its membership is asserted against § 3 BIDIRECTIONALLY
# by --self-test, so a one-sided edit to either site fails the self-test rather
# than shipping silently.
_FALLBACK_SUBTYPES_LINES="$(printf '%s\n' \
  "gate-outcome	g1-g2 g3-release-readiness dt-pass dt-conditional-pass dt-return qa-acceptance qa-rejection plan-review-go plan-review-no-go plan-review-readiness-scan goal-conformance" \
  "decision	d-class adr-closed adr-opened scope-lock a6-new-track-rationale a7-bundle-amend a7-bundle-rebundle a7-bundle-defer cross-d-upstream-compat empirical-verification-finding action-item-opened action-item-started action-item-resolved action-item-cancelled action-item-superseded queued-pending-approval approval-deferred cascade-sweep-block outcome-statement-authored delegation recommendation-choice-delta" \
  "escalation	tier-0 tier-1 tier-2 tier-3" \
  "self-repair	retry escalate rollback" \
  "iteration	" \
  "scope-change	tier-1-adjust tier-2-scope-change tier-3-plan-rejection redaction" \
  "re-review	phase-a0-row phase-0.5-row" \
  "deployment-status	deploy-skill deploy-harness deploy-package deploy-rules-mirror deploy-helper" \
  "release-synthesis	learnings-triple qc4-05-result qc4-06-result" \
  "test-run	suite-pass suite-fail suite-skip" \
  "spoke-launch	quota-reservation" \
  "session-retro	learning operator-feedback no-learning")"

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

# ─── Recognized payload labels (parsed from schema § 11.8) ───────────────────
#
# WHY THIS GATE EXISTS. The synthesizer terminates each payload field at the next
# RECOGNIZED label. An unrecognized label is therefore swallowed into the
# PRECEDING field's content and tokenized as if it were signal — one stray label
# after `theme:` inflated a single real cluster into three. The event log is
# append-only, so a bad row can never be deleted, only redacted. The read side is
# hardened too, but only a write-side gate stops the bad row existing.
#
# SCOPE — deliberately narrow, and empirically grounded. Only event types that
# DECLARE a label set in § 11.8 are validated: `release-synthesis` and
# `session-retro`, the two grains the synthesizer parses. A census of the live
# event log found the other event types (`decision`, `gate-outcome`, `escalation`,
# `test-run`) using open free-form payload keys across the great majority of rows;
# validating those would reject nearly every existing caller for no read-side
# benefit. An event type absent from § 11.8 is NOT validated — that is the design,
# not an omission.
#
# § 11.8 is the SINGLE AUTHORITY for the label set (schema over tool). Parsing it
# here rather than restating it is what keeps the two from drifting — the drift
# that shipped a 5-label schema against a 6-label tool.

# Parse the schema § 11.8 table → "key|label label …" lines on stdout, where the
# key is `event_type` or `event_type/event_subtype`.
# Row shape: | `source` … | `--event-type …` | `l1` / `l2` / … | clustered | zero-state |
# FS="|" on a leading-pipe row: $2=col1(source) $3=col2(filter) $4=col3(labels).
#
# THE KEY COMES FROM COL-2, NOT COL-1. § 11.8 declares each label set's SCOPE in
# col-2 (the "Input filter" cell) as `--event-type X [--event-subtype Y]`. Col-1
# is a `--source` enum value consumed by synthesize-release-learnings.sh and only
# coincidentally shaped like an event type. Reading col-1 as the key is what
# scoped validation by event_type alone, imposing the learnings-triple label set
# on every release-synthesis subtype and making qc4-05-result / qc4-06-result
# structurally un-emittable — zero such rows exist across the log's history.
parse_schema_labels() {
  [[ -r "$SCHEMA_FILE" ]] || return 1
  awk -F'|' '
    /^### 11\.8/       { in_s = 1; next }
    in_s && /^#{1,3} / { in_s = 0 }
    # col-1 must START with a backtick token (the source name); trailing prose in
    # the same cell — e.g. "(default — …)" — is ignored.
    in_s && $2 ~ /^ *`[a-z0-9-]+`/ {
      filt = $3; et = ""; es = ""                       # declared scope from col-2
      if (match(filt, /--event-type +[a-z0-9-]+/)) {
        t = substr(filt, RSTART, RLENGTH); sub(/^--event-type +/, "", t); et = t
      }
      if (match(filt, /--event-subtype +[a-z0-9.-]+/)) {
        t = substr(filt, RSTART, RLENGTH); sub(/^--event-subtype +/, "", t); es = t
      }
      # A row declaring no --event-type registers NOTHING rather than
      # mis-registering under a col-1 name. Fail closed on a malformed
      # declaration; this also skips the table HEADER row, whose col-1
      # (`--source`) satisfies the backtick test above.
      if (et == "") next
      key = (es == "" ? et : et "/" es)
      rest = $4; labels = ""                            # labels from col-3 ONLY
      while (match(rest, /`[a-z0-9-]+`/)) {
        tok = substr(rest, RSTART+1, RLENGTH-2)
        labels = (labels == "" ? tok : labels " " tok)
        rest = substr(rest, RSTART+RLENGTH)
      }
      if (labels != "") print key "|" labels
    }
  ' "$SCHEMA_FILE"
}

# Static fallback (schema unreadable, e.g. invoked outside the repo tree).
# Asserted against § 11.8 by --self-test, so a one-sided edit fails the test
# rather than shipping silently.
#
# Keys mirror the § 11.8 DECLARED FILTERS, not the col-1 source names:
# release-synthesis's filter names a subtype, so its key carries one;
# session-retro's filter names none, so its key stays type-level and all three
# of its subtypes resolve through the type-level rung of labels_for().
_FALLBACK_LABEL_SETS="$(printf '%s\n' \
  "release-synthesis/learnings-triple	surprise would-change watch-for" \
  "session-retro	session source theme domain learning reason")"

_schema_labels="$(parse_schema_labels 2>/dev/null || true)"
if [[ -n "$_schema_labels" ]]; then
  LABEL_SETS_LINES="$(printf '%s\n' "$_schema_labels" | sed 's/|/\t/')"
else
  LABEL_SETS_LINES="$_FALLBACK_LABEL_SETS"
fi

# Per-subtype FORBIDDEN labels. A `no-learning` row means "reflected, found
# nothing" and the emission contract requires it to carry no `theme:` — that is
# what makes it contribute no cluster signal. Enforcing it here means the
# zero-state holds by enforcement rather than by emitter discipline.
FORBIDDEN_LABELS_session_retro_no_learning="theme"

REVERSIBILITY_VALUES="CHEAP MODERATE EXPENSIVE IRREVERSIBLE"
OUTCOME_VALUES="resolved pending escalated superseded"

# ─── Release join key: the version grammar, SOURCED not copied ───────────────
# The `version` column is the release JOIN KEY and carries the milestone SLUG
# (§ 2a). The shipped `vX.Y` is NOT a key — it binds only at the Stage-12
# ref-CAS, after emission has begun, so a pre-claim row keyed by it is neither
# unique across releases nor stable within one.
#
# Deciding "is this value version-shaped" requires the canonical version
# grammar. That grammar has exactly ONE home — version-grammar.sh — whose
# consumer contract is binding: "SOURCE, do not copy. A copied-inline regex is
# a divergence defect." So this guard sources the library and calls
# `version_canonical`; it does not restate the regex. The empty positional is
# load-bearing: sourcing inherits the caller's "$@", and the library runs its
# own --self-test and exits when it sees `--self-test` as $1 (the same idiom is
# used by automated-closeout.sh and deploy.sh for this exact reason).
#
# Fail-closed on an absent library. The two files are siblings shipped in the
# same directory at the same commit, so absence means a broken checkout — and a
# guard that silently skips is the silent-failure class this guard exists to
# remove.
VERSION_GRAMMAR_LIB="$SCRIPT_DIR/version-grammar.sh"
if [[ -f "$VERSION_GRAMMAR_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$VERSION_GRAMMAR_LIB" ""
  _APE_HAVE_GRAMMAR=1
else
  _APE_HAVE_GRAMMAR=0
fi

# Reserved key for an emission with NO release context at all. Adopted from
# RELEASE_PROTOCOL.md § Versioning, which already uses `(none)` where a version
# key would sit and explicitly forbids synthesizing a placeholder version. It
# carries a parenthesis and no digits, so it can collide with neither the
# version grammar nor a milestone slug. A version-LESS release is a different
# case: it still keys by its own slug.
VERSION_KEY_NONE='(none)'

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

# Flatten a "type<TAB>subtype subtype …" table into comparable enum tokens:
# one bare `type` token per row (so a type-level divergence is visible even when
# the type carries zero literal subtypes) plus one `type/subtype` token per member.
# Sorted for comm(1). LC_ALL=C pins collation so sort and comm cannot disagree.
enum_tokens() {
  /usr/bin/awk -F'\t' 'NF {
      print $1
      n = split($2, a, " ")
      for (i = 1; i <= n; i++) if (a[i] != "") print $1 "/" a[i]
    }' | LC_ALL=C /usr/bin/sort -u
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

# labels_for <event_type> [<event_subtype>] — the recognized label set for this
# (type, subtype), resolved in three rungs:
#   1. exact      — a set declared for `type/subtype` (a § 11.8 row whose filter
#                   names both)
#   2. type-level — a set declared for `type` alone (a § 11.8 row whose filter
#                   names no subtype); every subtype of that type resolves here
#   3. empty      — no declared set reaches this pair; it is NOT label-validated
#                   (§ 11.8 Scope)
#
# The awk reads a here-string rather than a piped writer. `awk … exit` stops
# reading early; a writer piped into a short-circuiting reader can then die on
# the broken pipe, and `pipefail` promotes ITS status to the pipeline's — so a
# SUCCESSFUL match reports failure. The here-string removes the pipe, so the
# hazard cannot arise regardless of how large the registry grows.
labels_for() {
  local _t="$1" _s="${2:-}" _out
  if [[ -n "$_s" ]]; then
    _out="$(awk -F'\t' -v k="$_t/$_s" '$1==k{print $2; exit}' <<<"$LABEL_SETS_LINES")"
    if [[ -n "$_out" ]]; then
      printf '%s\n' "$_out"
      return 0
    fi
  fi
  awk -F'\t' -v k="$_t" '$1==k{print $2; exit}' <<<"$LABEL_SETS_LINES"
}

# payload_labels <payload> — every label token that OPENS a segment, one per line.
# Segments split on ';'. A segment whose first token is not `name:` yields nothing
# (free-text continuation is legitimate and is not a label).
payload_labels() {
  printf '%s' "$1" | tr ';' '\n' \
    | sed -n -E 's/^[[:space:]]*([A-Za-z][A-Za-z0-9_-]*):.*$/\1/p'
}

# validate_payload_labels <event_type> <subtype> <payload>
# Rejects an unrecognized label for a type that declares a set, and a label the
# subtype explicitly forbids. Dies with the recognized set named, so the caller is
# told what IS allowed rather than only what failed.
validate_payload_labels() {
  local event_type="$1" subtype="$2" payload="$3"
  local allowed lbl forbidden key
  allowed="$(labels_for "$event_type" "$subtype")"
  [[ -n "$allowed" ]] || return 0        # no declared set reaches this pair → not validated

  # Per-subtype forbidden set (variable-name-safe key: non-alphanumerics → _).
  key="$(printf '%s_%s' "$event_type" "$subtype" | tr -c 'A-Za-z0-9' '_')"
  eval "forbidden=\"\${FORBIDDEN_LABELS_${key}:-}\""

  while IFS= read -r lbl; do
    [[ -n "$lbl" ]] || continue
    if [[ -n "$forbidden" ]] && is_in_list "$lbl" "$forbidden"; then
      die "Payload label '${lbl}:' is forbidden on ${event_type}/${subtype} — a ${subtype} row must not carry it (see pipeline-event-log-schema.md § 11.8 and the session-retro emission contract)"
    fi
    is_in_list "$lbl" "$allowed" || die "Unrecognized payload label '${lbl}:' for event_type '${event_type}' (recognized: ${allowed}). An unrecognized label is swallowed into the preceding field by the synthesizer and tokenized as signal — see pipeline-event-log-schema.md § 11.8"
  done <<EOF
$(payload_labels "$payload")
EOF
  return 0
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

# validate_version_key <value> — exit 0 if admissible as the release join key.
#
# The predicate is NEGATIVE (reject the version grammar) rather than POSITIVE
# (assert a slug grammar), and that shape is forced by the corpus: milestone
# slugs have no enforced grammar — the shipped set contains uppercase segments
# and a parenthetical — so asserting one would reject real slugs. The version
# grammar, by contrast, is canonicalized exactly once and matches no real slug.
#
# Rejected:
#   (i)  a canonical release version (delegated to version_canonical)
#   (ii) an unresolved `{{...}}` substitution token — the caller did not expand it
# Admitted: the reserved `(none)` sentinel, and everything else (i.e. slugs).
validate_version_key() {
  local v="$1"
  # Trim surrounding whitespace and CR. No live value carries either, so this
  # changes no current verdict — but without it a CRLF caller slips `v4.07\r`
  # past an anchored match and re-opens the hole invisibly.
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  v="${v//$'\r'/}"

  [[ "$v" == "$VERSION_KEY_NONE" ]] && return 0
  case "$v" in *'{{'*|*'}}'*) return 2 ;; esac
  version_canonical "$v" && return 1
  return 0
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

  # ── § 3 ↔ static-fallback lockstep, asserted in BOTH directions ──────────
  # Direction 1 (§ 3 -> mirror): a member § 3 admits that the mirror does not.
  # Direction 2 (mirror -> § 3): a member the mirror admits that § 3 does not.
  # Evaluable ONLY when the schema is readable. When it is not, the assertion is
  # reported SKIP and the self-test proceeds: the fallback exists for AVAILABILITY,
  # so failing closed here would defeat the mechanism under test. The SKIP is an
  # EXPLICIT zero-state, never a silent pass.
  _mirror_tokens="$(printf '%s\n' "$_FALLBACK_SUBTYPES_LINES" | enum_tokens)"
  if [[ -n "$_schema_rows" ]]; then
    _schema_tokens="$(printf '%s\n' "$_schema_rows" | /usr/bin/sed 's/|/\t/' | enum_tokens)"
    _lock_missing="$(LC_ALL=C /usr/bin/comm -23 <(printf '%s\n' "$_schema_tokens") <(printf '%s\n' "$_mirror_tokens"))"
    _lock_extra="$(LC_ALL=C /usr/bin/comm -13 <(printf '%s\n' "$_schema_tokens") <(printf '%s\n' "$_mirror_tokens"))"
    if [[ -n "$_lock_missing" || -n "$_lock_extra" ]]; then
      echo "ERROR: self-test: § 3 <-> static-fallback lockstep BROKEN" >&2
      if [[ -n "$_lock_missing" ]]; then
        echo "  in § 3 but MISSING from _FALLBACK_SUBTYPES_LINES (add these):" >&2
        printf '    %s\n' $_lock_missing >&2
      fi
      if [[ -n "$_lock_extra" ]]; then
        echo "  in _FALLBACK_SUBTYPES_LINES but ABSENT from § 3 (remove, or add to § 3):" >&2
        printf '    %s\n' $_lock_extra >&2
      fi
      echo "  § 3 and the mirror are a two-site obligation: both change in ONE commit." >&2
      exit 1
    fi
    echo "self-test: § 3 <-> static-fallback lockstep OK ($(printf '%s\n' "$_schema_tokens" | /usr/bin/grep -c .) enum tokens, both directions)"
  else
    echo "self-test: § 3 <-> static-fallback lockstep SKIP (schema unreadable) — degraded-availability path; equality not evaluable"
  fi

  # ── Forced-fallback path: run the FULL self-test out-of-tree ─────────────
  # Copying the script two levels deep in a throwaway tree makes its REPO_ROOT
  # resolve there, so SCHEMA_FILE cannot be found and the static-fallback branch
  # is genuinely TAKEN (not simulated). The child's log is redirected into the
  # same temp tree, so the operator-instance log is never touched — and the
  # redirect additionally exercises seed_if_absent on a fresh instance, which
  # nothing else covers. _APE_SELFTEST_FALLBACK_CHILD bounds recursion at depth 1.
  if [[ -z "${_APE_SELFTEST_FALLBACK_CHILD:-}" ]]; then
    _ft_tmp="$(/usr/bin/mktemp -d)" || die "self-test: cannot create forced-fallback temp tree" 2
    trap '/bin/rm -rf "$_ft_tmp"' EXIT
    /bin/mkdir -p "$_ft_tmp/release/tools" || die "self-test: cannot populate forced-fallback temp tree" 2
    /bin/cp "${BASH_SOURCE[0]}" "$_ft_tmp/release/tools/append-pipeline-event.sh" \
      || die "self-test: cannot copy script into forced-fallback temp tree" 2
    # The grammar SSOT travels with the script. This probe forces the SCHEMA to
    # be unfindable (REPO_ROOT resolves into the temp tree) — it is not a probe
    # of a missing grammar library, and the child's join-key guard fails closed
    # without it. Copying it keeps the forced-fallback run exercising the real
    # emit path; the `enum source=static-fallback` liveness assertion below is
    # unaffected, since that branch keys on the schema, not on this library.
    /bin/cp "$VERSION_GRAMMAR_LIB" "$_ft_tmp/release/tools/version-grammar.sh" \
      || die "self-test: cannot copy version-grammar.sh into forced-fallback temp tree" 2
    if ! _ft_out="$(_APE_SELFTEST_FALLBACK_CHILD=1 EVALS_RESULTS_PATH="$_ft_tmp/evals" \
                    "$_ft_tmp/release/tools/append-pipeline-event.sh" --self-test 2>&1)"; then
      echo "ERROR: self-test: forced-fallback run FAILED" >&2
      printf '%s\n' "$_ft_out" >&2
      exit 1
    fi
    # Liveness assertion: the child MUST have taken the fallback branch. Without
    # this, a change to the REPO_ROOT resolution rule would silently turn the
    # whole probe into a no-op that still passes.
    case "$_ft_out" in
      *"enum source=static-fallback"*) : ;;
      *) die "self-test: forced-fallback run did NOT take the fallback branch — probe is a no-op" ;;
    esac
    echo "self-test: forced-fallback path PASS (out-of-tree child; enum source=static-fallback)"
  fi

  # Snapshot
  PRE_LINES=$(/usr/bin/wc -l < "$LOG_FILE" | /usr/bin/tr -d ' ')
  PRE_WRITE_LINES=$(/usr/bin/wc -l < "$WRITE_LOG" | /usr/bin/tr -d ' ')

  # Build & validate a test row
  TS_TEST="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  validate_ts_iso "$TS_TEST" || die "self-test: ts_iso format check failed"
  validate_subtype "decision" "scope-lock" || die "self-test: subtype validation failed"
  validate_subtype "decision" "cascade-sweep-block" || die "self-test: decision cascade-sweep-block subtype check failed"
  validate_subtype "decision" "delegation" || die "self-test: decision delegation subtype check failed"
  validate_subtype "self-repair" "retry" || die "self-test: self-repair subtype check failed"
  validate_subtype "iteration" "dt-eng-pass-2" || die "self-test: iteration prefix check failed"
  validate_subtype "test-run" "suite-pass" || die "self-test: test-run suite-pass subtype check failed"
  validate_subtype "test-run" "suite-fail" || die "self-test: test-run suite-fail subtype check failed"
  validate_subtype "test-run" "suite-skip" || die "self-test: test-run suite-skip subtype check failed"
  is_in_list "test-run" "$EVENT_TYPES" || die "self-test: test-run missing from EVENT_TYPES enum"
  validate_subtype "session-retro" "learning" || die "self-test: session-retro learning subtype check failed"
  validate_subtype "session-retro" "operator-feedback" || die "self-test: session-retro operator-feedback subtype check failed"
  validate_subtype "session-retro" "no-learning" || die "self-test: session-retro no-learning subtype check failed"
  is_in_list "session-retro" "$EVENT_TYPES" || die "self-test: session-retro missing from EVENT_TYPES enum"
  validate_actor "skill:session-retro" || die "self-test: actor 'skill:session-retro' check failed"
  validate_actor "hub" || die "self-test: actor 'hub' check failed"
  validate_actor "spoke:#1" || die "self-test: actor 'spoke:#N' check failed"
  validate_actor "skill:release-planner" || die "self-test: actor 'skill:NAME' check failed"
  validate_actor "operator" || die "self-test: actor 'operator' check failed"
  is_in_list "EXPENSIVE" "$REVERSIBILITY_VALUES" || die "self-test: reversibility enum check failed"
  is_in_list "resolved" "$OUTCOME_VALUES" || die "self-test: outcome enum check failed"

  # ── § 11.8 payload-label registry ────────────────────────────────────────
  # Report the SOURCE before asserting on it. The lockstep assertion below is
  # conditional on a successful schema parse, so an empty parse would silently
  # skip it and read as green — the false-negative this line exists to expose.
  echo "self-test: label source=$([[ -n "$_schema_labels" ]] && echo "schema-§11.8-data-driven" || echo static-fallback) ($(printf '%s\n' "$LABEL_SETS_LINES" | grep -c .) label sets)"
  # A READABLE schema that parses to nothing is the false-green case: the lockstep
  # assertion below would be skipped and the run would still report PASS. An
  # UNREADABLE schema is the legitimate degraded-availability path (the forced-
  # fallback child run exercises exactly that), so it is not an error.
  if [[ -r "$SCHEMA_FILE" && -z "$_schema_labels" ]]; then
    die "self-test: § 11.8 label parse returned nothing against a READABLE schema — the registry silently fell back, so the schema↔fallback lockstep would not have run"
  fi
  # BIDIRECTIONAL schema↔fallback assertion over the WHOLE label registry: a
  # one-sided edit to either surface fails here rather than shipping. This is the
  # check that would have caught the 5-label schema / 6-label tool drift.
  #
  # It asserts the registry as a TOKEN SET, not two hardcoded set names. The prior
  # form named `session-retro` and `release-synthesis` literally; once the registry
  # is keyed by the declared filter, `labels_for release-synthesis` (type-only)
  # returns "" on BOTH sides and that assertion passes VACUOUSLY — the same
  # false-green shape the readable-schema guard above exists to prevent. A
  # both-directions token comparison cannot go vacuous, and it drops the hardcoded
  # names along with the cascade liability they carried. `enum_tokens` is reused
  # verbatim: the label registry has the same `key<TAB>values` shape as the § 3
  # table it already flattens.
  if [[ -n "$_schema_labels" ]]; then
    _lbl_schema_tok="$(printf '%s\n' "$_schema_labels" | /usr/bin/sed 's/|/\t/' | enum_tokens)"
    _lbl_mirror_tok="$(printf '%s\n' "$_FALLBACK_LABEL_SETS" | enum_tokens)"
    _lbl_missing="$(LC_ALL=C /usr/bin/comm -23 <(printf '%s\n' "$_lbl_schema_tok") <(printf '%s\n' "$_lbl_mirror_tok"))"
    _lbl_extra="$(LC_ALL=C /usr/bin/comm -13 <(printf '%s\n' "$_lbl_schema_tok") <(printf '%s\n' "$_lbl_mirror_tok"))"
    if [[ -n "$_lbl_missing" || -n "$_lbl_extra" ]]; then
      echo "ERROR: self-test: § 11.8 <-> _FALLBACK_LABEL_SETS lockstep BROKEN" >&2
      if [[ -n "$_lbl_missing" ]]; then
        echo "  in § 11.8 but MISSING from the mirror:" >&2
        printf '    %s\n' $_lbl_missing >&2
      fi
      if [[ -n "$_lbl_extra" ]]; then
        echo "  in the mirror but ABSENT from § 11.8:" >&2
        printf '    %s\n' $_lbl_extra >&2
      fi
      echo "  § 11.8 and the mirror are a two-site obligation: both change in ONE commit." >&2
      exit 1
    fi
    echo "self-test: § 11.8 <-> mirror lockstep OK ($(printf '%s\n' "$_lbl_schema_tok" | grep -c .) tokens, both directions)"
  fi
  # `reason` must be recognized on a no-learning row — and asserting it through the
  # SUBTYPE form keeps the type-level fallback rung live rather than untested.
  is_in_list "reason" "$(labels_for session-retro no-learning)" \
    || die "self-test: 'reason' missing from the session-retro label set (no-learning rows carry it)"
  # Positive: a well-formed row of each grain validates.
  validate_payload_labels "session-retro" "learning" \
    "session:s1; source:friction; theme:over-building; domain:corpus-edit; learning:scope grew past the ask" \
    || die "self-test: well-formed session-retro payload rejected"
  validate_payload_labels "session-retro" "no-learning" "session:s6; reason:trivial-session" \
    || die "self-test: well-formed no-learning payload rejected"
  validate_payload_labels "release-synthesis" "learnings-triple" \
    "surprise: a; would-change: b; watch-for: c" \
    || die "self-test: well-formed release-synthesis payload rejected"
  # An event type that declares NO label set stays unvalidated (free-form keys).
  validate_payload_labels "decision" "scope-lock" "verdict:approved; ctx:anything-goes" \
    || die "self-test: undeclared-label-set event type must not be validated"
  # Free prose containing a colon is NOT a label (it does not open a segment).
  validate_payload_labels "session-retro" "learning" "theme:over-building; learning:the fix: do less" \
    || die "self-test: a colon inside free prose must not be read as a label"

  # ── (event_type, event_subtype) label scoping — the AC-2/AC-3 fixtures ──────
  # These two subtypes are declared in § 3 and required by the Stage-13 emit
  # table, but carry payload shapes their sibling learnings-triple does not.
  # Under event_type-only scoping they were structurally un-emittable: zero rows
  # across the log's entire history. The fixtures assert EMITTABILITY; they do
  # NOT canonicalize a payload-label convention for these subtypes.
  validate_payload_labels "release-synthesis" "qc4-05-result" \
    "invariant:AV-1; verdict:PASS; files:release/tools/append-pipeline-event.sh" \
    || die "self-test: a conforming qc4-05-result payload must emit — label scoping is not subtype-aware"
  validate_payload_labels "release-synthesis" "qc4-06-result" \
    "verdict:ATTAINED; outcome_excerpt:post-deploy main exhibits the AFTER state; evidence_anchor:release-plan-change-description" \
    || die "self-test: a conforming qc4-06-result payload must emit — label scoping is not subtype-aware"
  # Resolution-rung liveness: exact returns a set, type-level falls back, and an
  # undeclared subtype resolves to EMPTY (not validated). Asserting all three
  # rungs is what stops a partial implementation reading as green.
  [[ -n "$(labels_for release-synthesis learnings-triple)" ]] \
    || die "self-test: exact rung dead — release-synthesis/learnings-triple must resolve"
  [[ -z "$(labels_for release-synthesis qc4-06-result)" ]] \
    || die "self-test: qc4-06-result must resolve to NO declared set (§ 11.8 declares none)"
  [[ "$(labels_for session-retro learning)" == "$(labels_for session-retro)" ]] \
    || die "self-test: type-level fallback rung dead — session-retro/<subtype> must fall back to the type set"

  # Negative tests
  # THE DT-2 GUARD: an unrecognized label must be rejected at emit time.
  if ( validate_payload_labels "session-retro" "learning" \
       "session:s1; theme:over-building; mood:excited; domain:corpus-edit" ) 2>/dev/null; then
    die "self-test: unrecognized payload label 'mood:' must be rejected"
  fi
  # THE PA-5 GUARD: theme: on a no-learning row is forbidden by enforcement.
  if ( validate_payload_labels "session-retro" "no-learning" \
       "session:s6; reason:trivial; theme:over-building" ) 2>/dev/null; then
    die "self-test: 'theme:' on a no-learning row must be rejected"
  fi
  if ( validate_payload_labels "release-synthesis" "learnings-triple" \
       "surprise: a; mood: b" ) 2>/dev/null; then
    die "self-test: unrecognized label on release-synthesis must be rejected"
  fi
  # THE MUTATION PROOF (AC-3). This reject and the two qc4 ACCEPTS above are
  # COMPLEMENTARY, and no single-scope implementation satisfies all three:
  #   · event_type-only scoping (the defect) fails the two accepts;
  #   · union-of-all-subtypes scoping passes the accepts but fails this reject;
  #   · dropping the release-synthesis gate entirely fails this reject.
  # `verdict:` is the discriminating token precisely because it IS legal on a
  # sibling subtype — the `mood:` arm above cannot distinguish union scoping,
  # since `mood` is legal nowhere. Breaking (event_type, event_subtype)
  # resolution therefore fails this test by construction, with no hand-edit
  # required to demonstrate it.
  if ( validate_payload_labels "release-synthesis" "learnings-triple" \
       "surprise: a; verdict: ATTAINED" ) 2>/dev/null; then
    die "self-test: 'verdict:' must still be REJECTED on learnings-triple — the exact rung must bind, not widen"
  fi

  if validate_subtype "decision" "bogus-subtype" 2>/dev/null; then
    die "self-test: subtype rejection check failed (bogus accepted)"
  fi
  if validate_subtype "test-run" "suite-bogus" 2>/dev/null; then
    die "self-test: test-run subtype rejection check failed (suite-bogus accepted)"
  fi
  # Guards the § 3 parse against prose leakage: the session-retro row's col-3
  # parenthetical names the decision-anchored delta path, so a backtick around
  # that name would silently admit it as a session-retro subtype.
  if validate_subtype "session-retro" "recommendation-choice-delta" 2>/dev/null; then
    die "self-test: session-retro subtype rejection check failed (prose token leaked into the § 3 enum)"
  fi
  if validate_subtype "bogus-type" "anything" 2>/dev/null; then
    die "self-test: unknown event_type rejection check failed (bogus-type accepted)"
  fi
  if validate_actor "bogus" 2>/dev/null; then
    die "self-test: actor rejection check failed (bogus accepted)"
  fi

  # ─── Release join key (§ 2a) — a DISCRIMINATING control, not a smoke test ──
  # Two sensitivity arms (a value that MUST be rejected) and two specificity
  # arms (a value that MUST be accepted). A guard asserted only on its
  # rejections would still pass while false-rejecting every real slug; the
  # acceptance arms are what make this a control rather than a demonstration.
  [[ "$_APE_HAVE_GRAMMAR" -eq 1 ]] \
    || die "self-test: version-grammar.sh not sourced — the join-key guard would fail closed at emit; every assertion below would be vacuous"
  # Liveness: the guard must delegate to the SSOT, not to a local copy.
  declare -F version_canonical >/dev/null \
    || die "self-test: version_canonical is not in scope — the join-key guard is not sourcing the grammar SSOT"
  # Capture the guard's status without tripping `set -e` on its rejection path
  # (a bare non-zero statement would abort the run silently).
  _vk_rc() { local rc=0; validate_version_key "$1" || rc=$?; printf '%s' "$rc"; }
  # (A) sensitivity — a canonical release version is rejected.
  [[ "$(_vk_rc "v4.07")" -eq 1 ]] \
    || die "self-test: 'v4.07' (a release version) must be rejected as a join key"
  [[ "$(_vk_rc "v1.07.3")" -eq 1 ]] \
    || die "self-test: 'v1.07.3' (a three-component version) must be rejected as a join key"
  # (B) sensitivity — an unresolved substitution token is rejected.
  [[ "$(_vk_rc '{{RELEASE_VERSION}}')" -eq 2 ]] \
    || die "self-test: an unresolved '{{...}}' token must be rejected as a join key"
  # (C) specificity — a real milestone slug is accepted.
  validate_version_key "version-binding-lifecycle" \
    || die "self-test: a milestone slug must be ACCEPTED as the join key"
  # (D) specificity, near-miss — a LEADING-DIGIT slug is accepted. A sloppier
  # predicate (unanchored, or a positive lowercase-kebab grammar) catches this
  # one; the shipped slug set contains it, so a false rejection here is a
  # production outage rather than a test failure.
  validate_version_key "103-skill-suite-conformance-and-usability-ac" \
    || die "self-test: a leading-digit milestone slug must be ACCEPTED as the join key"
  validate_version_key "01-FNH-qa-change-release-hardening" \
    || die "self-test: an uppercase-segment milestone slug must be ACCEPTED as the join key"
  # (E) the reserved release-less sentinel is accepted; a synthesized
  # version-shaped placeholder is not — that distinction is the whole point.
  validate_version_key "$VERSION_KEY_NONE" \
    || die "self-test: the reserved '$VERSION_KEY_NONE' sentinel must be ACCEPTED"
  [[ "$(_vk_rc "v0.0.0")" -eq 1 ]] \
    || die "self-test: 'v0.0.0' (a synthesized version-shaped placeholder) must be rejected"
  # (F) CR/whitespace-carrying value must not slip past the anchored match.
  [[ "$(_vk_rc "$(printf 'v4.07\r')")" -eq 1 ]] \
    || die "self-test: a CR-carrying version value must still be rejected (trim before match)"
  echo "self-test: § 2a release join-key guard OK (2 reject arms + 5 accept arms + CR-trim; grammar SOURCED from version-grammar.sh)"

  # ─── Payload row-integrity: positive (multi-value) ───
  _pi_ok() { case "$1" in *$'\n'*|*$'\r'*) return 1;; esac
             case "$1 |" in *" | "*) return 1;; esac
             case "${1//\\|/}" in *"|"*) return 1;; esac; return 0; }
  _pi_ok 'triggers:[T1\|T2\|T3]; files_swept:4; verdict:UPDATE' \
    || die "self-test: escaped multi-value payload rejected (§ 4.3a positive case)"
  _pi_ok 'projects_to:calibration-data.md; verdict:Approved' \
    || die "self-test: pipe-free payload rejected"
  # Pins the delegation convention's RUNTIME form (single-valued, per § 3). The
  # source issue proposed documenting it as `chose:{spoke|hub-direct}` — a form
  # the bare-pipe guard below rejects. Emitting the documented example must work.
  _pi_ok 'chose:spoke; why:x; quota:PROCEED' \
    || die "self-test: delegation payload convention rejected"
  # ─── Payload row-integrity: negative (malformed) ───
  if _pi_ok 'triggers:[T1 | T2]';  then die "self-test: space-delimited pipe accepted (delimiter)"; fi
  if _pi_ok 'triggers:[T1] |';     then die "self-test: trailing ' |' accepted (row-junction split)"; fi
  if _pi_ok 'triggers:[T1|T2]';    then die "self-test: bare pipe accepted (reserved)"; fi
  if _pi_ok "$(printf 'a\nb')";    then die "self-test: newline payload accepted"; fi
  # ─── Arity invariant (the predicate's reason for existing) ───
  # Asserts the INVARIANT, not merely the predicate: a future edit that drifts
  # the predicate away from the delimiter contract fails here rather than
  # shipping green.
  _arity() { printf '%s\n' "| t | v | 5 | decision | scope-lock | hub | #1 | CHEAP | resolved | $1 |" \
             | /usr/bin/awk -F ' \\| ' '{print NF}'; }
  [[ "$(_arity 'triggers:[T1\|T2\|T3]')" -eq 10 ]] || die "self-test: escaped payload broke row arity"
  [[ "$(_arity 'triggers:[T1 | T2]')"    -eq 11 ]] || die "self-test: arity oracle miscalibrated"

  # Append a sentinel row, then revert. The key is SLUG-shaped: the fixture must
  # not model the version-shaped form § 2a forbids, or the tool's own test data
  # teaches the defect the tool now rejects.
  TEST_ROW="| ${TS_TEST} | selftest-sentinel-release | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | resolved | selftest-row;will-be-reverted |"
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
  echo "  § 11.8 payload labels validated (schema<->fallback lockstep; unrecognized label rejected)"
  echo "  no-learning rows reject 'theme:' by enforcement; undeclared-label-set types stay free-form"
  echo "  § 2a release join key enforced: version-grammar values + unresolved tokens rejected, slugs accepted"
  echo "  positive + negative tests passed"
  echo "  append + revert cycle confirmed (log + write-log)"
  exit 0
fi

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: --version"

# ─── Release join-key admissibility (§ 2a) ───────────────────────────────────
# Placed on the same rung as the missing-field checks: an inadmissible key is a
# malformed call, not a content problem. The log is append-only and Vital
# retention (§ 4.1, § 7) — a bad row can never be deleted, only redacted — so
# this is a write-side gate by design, the same rationale § 11.8 states for the
# payload-label gate.
if [[ "$_APE_HAVE_GRAMMAR" -ne 1 ]]; then
  die "cannot validate --version: the canonical version grammar is missing at $VERSION_GRAMMAR_LIB. The release join key cannot be certified, and this gate fails closed rather than admitting an unvalidated key to an append-only log. Restore release/tools/version-grammar.sh." 2
fi
# `|| _vk_rc=$?` is load-bearing: under `set -e` a bare non-zero call would abort
# the run with a naked exit status and NONE of the messages below — a silent
# rejection, which is the exact failure shape this guard exists to remove.
_vk_rc=0
validate_version_key "$VERSION" || _vk_rc=$?
case "$_vk_rc" in
  1) die "--version '$VERSION' is a release VERSION, not a release join key. The key is the milestone SLUG (pipeline-event-log-schema.md § 2a; orchestration-playbook.md § 4a.2) — the shipped version binds only at the Stage-12 ref-CAS (ADR-092) and is neither unique across releases nor stable within one. Pass the milestone slug, or '$VERSION_KEY_NONE' for an emission with no release context." ;;
  2) die "--version '$VERSION' contains an unresolved substitution token; the caller did not expand it. Pass the resolved milestone slug (pipeline-event-log-schema.md § 2a)." ;;
esac

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

# ─── Payload row-integrity guard (§ 4.3a) ────────────────────────────────────
# Admissibility is defined by the ROW-INTEGRITY INVARIANT, not a character
# blacklist: the assembled row must be exactly one physical line splitting into
# exactly 10 fields under the canonical delimiter " | ". The payload MAY carry
# the escaped multi-value separator '\|'. It may NOT introduce anything that
# changes the assembled row's field arity or line count.
case "$PAYLOAD" in
  *$'\n'*|*$'\r'*)
    die "Payload contains a newline or CR — a row must be exactly one physical line" ;;
esac
# Test the payload IN ITS ROW CONTEXT: the row appends a trailing ' |', so a
# payload ending in ' |' forms the delimiter at the junction and splits the row.
case "${PAYLOAD} |" in
  *" | "*)
    die "Payload contains the column delimiter ' | ' (or ends with ' |') — reserved as the column separator; use '\\|' for a multi-value separator (see pipeline-event-log-schema.md § 4.3a)" ;;
esac
# Bare '|' stays reserved. Strip escaped separators, then reject any survivor.
_p_unescaped="${PAYLOAD//\\|/}"
case "$_p_unescaped" in
  *"|"*)
    die "Payload contains an unescaped '|' — the bare pipe stays reserved; write the multi-value separator as '\\|' (see pipeline-event-log-schema.md § 4.3a)" ;;
esac

# ─── Payload label validation (§ 11.8) ───────────────────────────────────────
# Only for event types that DECLARE a recognized-label set. A label token is one
# that OPENS a payload segment (string start, or immediately after a ';') — the
# same grammar the read side terminates fields on. A colon inside free prose is
# not a label and is left alone.
validate_payload_labels "$EVENT_TYPE" "$EVENT_SUBTYPE" "$PAYLOAD"

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
