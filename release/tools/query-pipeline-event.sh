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
#   ./query-pipeline-event.sh --release <milestone-slug>                       # all events in a release (join-key aware)
#   ./query-pipeline-event.sh --release v2.07a                                 # same, resolved vX.Y -> slug via RELEASE_LOG
#   ./query-pipeline-event.sh --version v2.07a                                 # RAW version-column filter: matches ONLY rows literally keyed 'v2.07a' (legacy rows)
#   ./query-pipeline-event.sh --release <milestone-slug> --stage 12            # release + stage filter
#   ./query-pipeline-event.sh --subject "<id>"                                  # all events for a given subject
#   ./query-pipeline-event.sh --event-type self-repair                         # all retries/escalates/rollbacks
#   ./query-pipeline-event.sh --event-type release-synthesis --event-subtype learnings-triple  # subtype filter
#   ./query-pipeline-event.sh --event-subtype recommendation-choice-delta --window 5  # look-back: trailing 5 versions of rec↔choice deltas
#   ./query-pipeline-event.sh --event-type session-retro                       # per-session self-retro rows (all 3 subtypes)
#   ./query-pipeline-event.sh --event-type session-retro --event-subtype operator-feedback  # no-decision operator-feedback learnings only
#   ./query-pipeline-event.sh --r-class                                        # EXPENSIVE + IRREVERSIBLE decisions
#   ./query-pipeline-event.sh --count                                          # row count summary
#
# Flags can compose:
#   ./query-pipeline-event.sh --release <milestone-slug> --event-type decision --r-class
#
# --release vs --version (pipeline-event-log-schema.md § 2a):
#   --version is the RAW version-column filter and is unchanged.
#   --release resolves through the § 2a READ ladder: rung 1 matches the milestone SLUG
#   (canonical, 1:1); rung 3 additionally matches the legacy `vX.Y` value, which is NOT
#   unique — one legacy value has been measured spanning four releases. Rung-3 matches
#   are always announced on stderr, and escalate to an `INDETERMINATE:` notice when the
#   matched rows provably span more than one milestone. Ambiguity is REPORTED, never
#   resolved by guessing.
#
# --window N mixed-arity caveat: --window restricts to the trailing N DISTINCT `version`
#   values. Post-cutover that column holds milestone slugs BESIDE legacy `vX.Y` values,
#   so a trailing-N window may span a different number of real releases than N. Use
#   --release when the question is "which rows belong to release X".
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
# REPO_ROOT resolution is verbatim from append-pipeline-event.sh for resolution-block
# parity. It is now LOAD-BEARING here too: --release resolves the § 2a version<->milestone
# binding out of the in-repo RELEASE_LOG. Two levels up — NOT three; see header note above.
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
  # Line range tracks the Usage + Flags-compose + --release/--window notes block above.
  # Update BOTH when that block moves — a stale range prints the wrong help silently.
  /usr/bin/sed -n '11,40p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

VERSION=""
RELEASE=""
STAGE=""
SUBJECT=""
EVENT_TYPE=""
EVENT_SUBTYPE=""
R_CLASS=false
COUNT=false
WINDOW=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) RELEASE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --subject) SUBJECT="$2"; shift 2 ;;
    --event-type) EVENT_TYPE="$2"; shift 2 ;;
    --event-subtype) EVENT_SUBTYPE="$2"; shift 2 ;;
    --r-class) R_CLASS=true; shift ;;
    --count) COUNT=true; shift ;;
    --window) WINDOW="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) die "Unknown flag: $1" ;;
  esac
done

# --window N validation: positive integer when supplied (per-window look-back read-model)
if [[ -n "$WINDOW" ]]; then
  [[ "$WINDOW" =~ ^[0-9]+$ && "$WINDOW" -ge 1 ]] || die "--window must be a positive integer: got '$WINDOW'"
fi

[[ -f "$LOG_FILE" ]] || die "Log file missing: $LOG_FILE"

# ─── --release: join-key-aware resolution (pipeline-event-log-schema.md § 2a) ──
#
# --release answers "which rows belong to release X"; --version answers "which rows
# carry this literal in the version column". They are different questions and both are
# retained. --release resolves its argument to a SET of acceptable version-column
# values through the § 2a ladder:
#
#   rung 1  the milestone SLUG                     canonical, 1:1 with the release
#   rung 3  the legacy `vX.Y` value                NOT unique — reported, never assumed
#
# Rung 2 (`subject` == `milestone:#N`) is not resolvable here: RELEASE_LOG records the
# milestone SLUG, never its number, so this tool has no slug->number mapping. Stating
# the bound rather than silently implementing three of four rungs.
#
# The two flags compose as an intersection when both are supplied (a raw-column filter
# applied on top of the resolved set), which is how you narrow a --release query to one
# of its keys.
RELEASE_KEYS=""
if [[ -n "$RELEASE" ]]; then
  RELEASE_LOG_FILE="${RELEASE_LOG_FILE:-$REPO_ROOT/release/releases/RELEASE_LOG.md}"
  [[ -f "$RELEASE_LOG_FILE" ]] || die "--release needs the RELEASE_LOG (the § 2a version<->milestone binding); not found at $RELEASE_LOG_FILE"

  # RELEASE_LOG 8-col schema: Version(1) Milestone(2) Issues(3) ReleasePR(4)
  # MergeSHA(5) Tag(6) State(7) Date(8). Emit "version|milestone" per release row.
  _rl_rows=$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$RELEASE_LOG_FILE" 2>/dev/null \
    | /usr/bin/awk -F ' \\| ' '{
        v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v);
        ms=$2; gsub(/`/,"",ms); sub(/^[[:space:]]*/,"",ms); sub(/[[:space:]]*$/,"",ms);
        print v "|" ms
      }') || _rl_rows=""

  _rel_ver=""; _rel_slug=""
  while IFS= read -r _rl; do
    [[ -n "$_rl" ]] || continue
    _v="${_rl%%|*}"; _m="${_rl##*|}"
    if [[ "$_m" == "$RELEASE" ]]; then _rel_slug="$_m"; _rel_ver="$_v"; break; fi
    if [[ "$_v" == "$RELEASE" ]]; then _rel_ver="$_v"; _rel_slug="$_m"; break; fi
  done <<<"$_rl_rows"

  if [[ -z "$_rel_slug" && -z "$_rel_ver" ]]; then
    # Not in RELEASE_LOG: treat the argument as a slug for an in-flight release (its
    # RELEASE_LOG row lands at Stage 12). Rung 1 only — there is no legacy value to add.
    _rel_slug="$RELEASE"
    echo "NOTE: '$RELEASE' has no RELEASE_LOG row yet (in-flight release?) — matching the slug alone (§ 2a rung 1)." >&2
  fi
  RELEASE_KEYS="$_rel_slug"
  [[ -n "$_rel_ver" && "$_rel_ver" != "$_rel_slug" ]] && RELEASE_KEYS="${RELEASE_KEYS}"$'\n'"${_rel_ver}"
fi

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

# release_keys is a SPACE-delimited, space-bracketed set (" slug vX.Y ") so membership is
# a whole-token test. Safe because neither a milestone slug nor a version literal
# contains a space. Empty ⇒ the --release filter is inert.
filter_awk='
BEGIN { FS = " \\| "; OFS = " | " }
{
  line = $0
  if (release_keys != "" && index(release_keys, " " $2 " ") == 0) next
  if (version != "" && $2 != version) next
  if (stage != "" && $3 != stage) next
  if (event_type != "" && $4 != event_type) next
  if (event_subtype != "" && $5 != event_subtype) next
  if (subject != "" && index($7, subject) == 0) next
  if (r_class == "true" && $8 != "EXPENSIVE" && $8 != "IRREVERSIBLE") next
  print line
}'

RELEASE_KEYS_SET=""
if [[ -n "$RELEASE_KEYS" ]]; then
  RELEASE_KEYS_SET=" $(echo "$RELEASE_KEYS" | /usr/bin/tr '\n' ' ')"
fi

FILTERED=$(echo "$DATA_ROWS" | /usr/bin/awk \
  -v version="$VERSION" \
  -v release_keys="$RELEASE_KEYS_SET" \
  -v stage="$STAGE" \
  -v event_type="$EVENT_TYPE" \
  -v event_subtype="$EVENT_SUBTYPE" \
  -v subject="$SUBJECT" \
  -v r_class="$R_CLASS" \
  "$filter_awk")

# Rung-3 disclosure. Rows matched only by the LEGACY `vX.Y` value are announced, and
# escalate to INDETERMINATE when they provably span more than one milestone — the § 2a
# rule that ambiguity is reported, never resolved by guessing. Silence here would be the
# whole defect: a legacy value measured spanning four releases, presented as one.
if [[ -n "$RELEASE" && -n "${_rel_ver:-}" && "${_rel_ver:-}" != "${_rel_slug:-}" && -n "$FILTERED" ]]; then
  _legacy_rows=$(echo "$FILTERED" | /usr/bin/awk -F ' \\| ' -v lv="$_rel_ver" '$2==lv' || true)
  if [[ -n "$_legacy_rows" ]]; then
    _legacy_n=$(echo "$_legacy_rows" | /usr/bin/grep -c . || true)
    _legacy_ms=$(echo "$_legacy_rows" | /usr/bin/awk -F ' \\| ' '$7 ~ /^milestone:#/ {print $7}' | /usr/bin/sort -u | /usr/bin/grep -c . || true)
    if [[ "${_legacy_ms:-0}" -gt 1 ]]; then
      echo "INDETERMINATE: ${_legacy_n} row(s) matched only by the legacy version '${_rel_ver}' (§ 2a rung 3), and they carry ${_legacy_ms} distinct milestone subjects — that value is NOT unique to this release. Treat these rows as release-INDETERMINATE; do not bind them to '${_rel_slug}'." >&2
    else
      echo "NOTE: ${_legacy_n} row(s) matched by the legacy version '${_rel_ver}' (§ 2a rung 3, best-effort). Only the ${_rel_slug}-keyed rows resolve 1:1." >&2
    fi
  fi
fi

# --window N: restrict the already-filtered rows to the trailing N DISTINCT version
# tags (matches synthesize-release-learnings.sh --window semantics: N versions, not N
# rows). Rows are in chronological write order, so the trailing N distinct versions are
# the last N version tokens to appear. A no-op when --window is unset.
if [[ -n "$WINDOW" && -n "$FILTERED" ]]; then
  FILTERED=$(echo "$FILTERED" | /usr/bin/awk -v win="$WINDOW" '
    BEGIN { FS = " \\| " }
    { rows[NR] = $0; ver[NR] = $2; n = NR }
    END {
      # Walk rows newest-first, collecting the trailing N distinct versions.
      keepcount = 0
      for (i = n; i >= 1; i--) {
        if (!(ver[i] in seen)) {
          if (keepcount >= win) continue
          seen[ver[i]] = 1
          keepcount++
        }
      }
      # Emit in original (chronological) order, keeping only rows in the kept set.
      for (i = 1; i <= n; i++) if (ver[i] in seen) print rows[i]
    }')
fi

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
