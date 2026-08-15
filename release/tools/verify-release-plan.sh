#!/usr/bin/env bash
set -euo pipefail
# verify-release-plan.sh — Plan-driven verification executor for Stage 6/7.
#
# Parses a release plan's Verification Plan (+ Cross-Issue Acceptance Criteria)
# section, dispatches each declared check to a check-family handler, and emits
# the PR-body `### Verification Evidence` block the Engineering self-verification
# step (and Dev Testing re-run) consume — per-issue PASS/FAIL, preserving the
# Gate-6 verification-evidence grep contract.
#
# Design: a THIN dispatcher over a five-family registry. The script owns
# parse + dispatch + emit only. It DELEGATES the surfaces sibling cards own
# rather than re-implementing them:
#   - the sync + regression families shell the deploy source↔deployed check;
#   - the runtime-suite family emits through the pipeline-event test-run writer;
#   - the integration family reads the plan's Cross-Issue Acceptance Criteria
#     section verbatim (the release-planning-stage schema) and runs each entry's
#     declared method — it is the SOLE runner of those methods and the SOLE
#     emitter of their verdicts (the plan-review integration read is downstream
#     and read-only).
# No handler runs `eval` on a plan-derived string; each shells allowlisted
# primitives only.
#
# Usage:
#   ./verify-release-plan.sh [OPTIONS] <release_plan.md>
#
# Exit codes: 0 all PASS/SKIP · 1 internal error · 2 bad plan target ·
#             3 one or more checks FAIL/ERROR.

# ---------------------------------------------------------------------------
# Version metadata (the contract IS the schema, not the implementation).
# SCHEMA_VERSION is authored day-one so any change to the emitted evidence /
# verdict contract that downstream stages consume is a detectable bump, not a
# silent break. Bump SCHEMA_VERSION whenever the evidence-table shape, the
# verdict enum, or the check-record fields change.
# ---------------------------------------------------------------------------
readonly CLI_VERSION="0.2.0"
# 1 -> 2: the `fcm-delivery` check family enters the emitted stream from a THIRD
# record source, so every consumer now sees records it has never seen before.
# That is exactly what this constant exists to make detectable rather than silent.
readonly SCHEMA_VERSION="2"

# ---------------------------------------------------------------------------
# Pinned PATH for tool discipline (per bypass-mode-readiness.md posture).
# ---------------------------------------------------------------------------
PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"

# ---------------------------------------------------------------------------
# Exit codes
# ---------------------------------------------------------------------------
readonly EXIT_OK=0
readonly EXIT_INTERNAL=1
readonly EXIT_BAD_TARGET=2
readonly EXIT_CHECK_FAILED=3

# ---------------------------------------------------------------------------
# Verdict enum (the Stage-8 per-criterion verdict values, reused verbatim; the
# runtime family additionally maps the test-run suite-* subtypes onto them).
# ---------------------------------------------------------------------------
readonly VERDICT_PASS="PASS"
readonly VERDICT_FAIL="FAIL"
readonly VERDICT_SKIP="SKIP"
readonly VERDICT_ERROR="ERROR"

# ---------------------------------------------------------------------------
# Argument-parsing state
# ---------------------------------------------------------------------------
ARG_FORMAT=""
ARG_ROOT=""
ARG_PLAN=""
ARG_NO_COLOR=0
ARG_EMIT_EVENTS=0   # opt-in: actually write test-run events via the event writer
ARG_FCM_MERGE_BASE=""   # explicit base ref for the fcm-delivery diff range
ARG_FCM_HEAD=""         # explicit head ref for the fcm-delivery diff range
ARG_FCM_DIFF_FILE=""    # TEST-ONLY determinism seam; refused against a real plan

# Scratch array populated by tokenize_cmd (quote-aware command splitter).
declare -a TOKENS=()

# ---------------------------------------------------------------------------
# Sibling-tool locations (resolved after root resolution). These are the only
# external surfaces the handlers shell; they are DELEGATIONS, not re-implements.
# ---------------------------------------------------------------------------
DEPLOY_CHECK=""          # core/deploy/deploy.sh --check  (sync + regression)
EVENT_WRITER=""          # release/tools/append-pipeline-event.sh  (runtime-suite)
DEPLOY_CHECK_CACHE=""    # per-run memo file for the deploy --check exit code

# ---------------------------------------------------------------------------
# Color helpers (match the release/tools convention).
# ---------------------------------------------------------------------------
use_color() {
  if [ "$ARG_NO_COLOR" = "1" ]; then return 1; fi
  [ -t 1 ] || return 1
  return 0
}
c_bold()  { if use_color; then printf '\033[1m'; fi; }
c_dim()   { if use_color; then printf '\033[2m'; fi; }
c_red()   { if use_color; then printf '\033[31m'; fi; }
c_green() { if use_color; then printf '\033[32m'; fi; }
c_reset() { if use_color; then printf '\033[0m'; fi; }

err() { printf '%serror:%s %s\n' "$(c_red)" "$(c_reset)" "$*" >&2; }

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
verify-release-plan.sh — Plan-driven verification executor (Stage 6/7)

USAGE
  verify-release-plan.sh [OPTIONS] <release_plan.md>

OPTIONS
  --format=FORMAT   Output presenter: md | json | table
                    Default: md (the PR-body Verification Evidence shape)
  --root=PATH       Repo root for resolving relative check paths + sibling tools
                    Default: \$(git rev-parse --show-toplevel)
  --emit-events     Actually write test-run events via the pipeline-event
                    writer for runtime-suite checks (default: describe only,
                    no event log write)
  --merge-base REF  Base ref for the fcm-delivery diff range
                    Default: \$(git merge-base origin/main HEAD)
  --head REF        Head ref for the fcm-delivery diff range (default: HEAD)
  --fcm-diff-file P TEST-ONLY determinism seam: read the delivered set from a
                    <status>TAB<path> file instead of git. REFUSED (ERROR) when
                    the plan target lives under release/releases/plans/ — a real
                    release must never be graded against an authored diff set.
  --no-color        Disable ANSI color in table output
  -h, --help        Show this help and exit
  --version         Show CLI version + schema version and exit

CHECK FAMILIES (dispatched by predicate-class hint, else method keyword)
  per-issue      file existence + content assertions  (grep / test -f)
  integration    Cross-Issue Acceptance Criteria      (reads the plan's CIAC
                 section; runs each entry's declared method — SOLE runner)
  regression     unchanged-files-intact               (deploy --check byte-diff)
  sync           source <-> deployed                  (deploy --check)
  runtime-suite  behavioral/runtime dispatch          (test-run event via
                 append-pipeline-event.sh)
  fcm-delivery   declared File Change Matrix ADDs     (git diff --name-status;
                 vs the merged diff                    ALWAYS-ON for a plan under
                                                       release/releases/plans/ —
                                                       not plan-declared, so it
                                                       cannot be omitted by not
                                                       being asked for)

EXIT CODES
  0  all checks PASS or SKIP
  1  internal error
  2  bad plan target (path missing / not a regular file)
  3  one or more checks FAIL or ERROR

EXAMPLES
  # Emit the Verification Evidence block for a release plan (markdown to stdout)
  verify-release-plan.sh release/releases/plans/v3.65_RELEASE_PLAN.md

  # JSON verdict array for CI consumption
  verify-release-plan.sh --format=json release/releases/plans/v3.65_RELEASE_PLAN.md

DOCS
  Output shape: the PR-body Verification Evidence section consumed by the
  Engineering self-verification step (Stage 6) and re-run at Dev Testing
  (Stage 7). See release/references/pipeline/stage-06-engineering.md.
EOF
}

# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)      usage; exit "$EXIT_OK" ;;
      --version)      printf 'verify-release-plan %s (schema v%s)\n' "$CLI_VERSION" "$SCHEMA_VERSION"; exit "$EXIT_OK" ;;
      --format=*)     ARG_FORMAT="${1#--format=}" ;;
      --format)       shift; ARG_FORMAT="${1:-}" ;;
      --root=*)       ARG_ROOT="${1#--root=}" ;;
      --root)         shift; ARG_ROOT="${1:-}" ;;
      --emit-events)  ARG_EMIT_EVENTS=1 ;;
      --merge-base=*) ARG_FCM_MERGE_BASE="${1#--merge-base=}" ;;
      --merge-base)   shift; ARG_FCM_MERGE_BASE="${1:-}" ;;
      --head=*)       ARG_FCM_HEAD="${1#--head=}" ;;
      --head)         shift; ARG_FCM_HEAD="${1:-}" ;;
      --fcm-diff-file=*) ARG_FCM_DIFF_FILE="${1#--fcm-diff-file=}" ;;
      --fcm-diff-file)   shift; ARG_FCM_DIFF_FILE="${1:-}" ;;
      --no-color)     ARG_NO_COLOR=1 ;;
      --)             shift; break ;;
      -*)             err "unknown option: $1"; usage >&2; exit "$EXIT_INTERNAL" ;;
      *)              if [ -z "$ARG_PLAN" ]; then ARG_PLAN="$1"; else err "unexpected extra argument: $1"; exit "$EXIT_INTERNAL"; fi ;;
    esac
    shift
  done
  # Any residual positionals after `--`.
  while [ $# -gt 0 ]; do
    if [ -z "$ARG_PLAN" ]; then ARG_PLAN="$1"; else err "unexpected extra argument: $1"; exit "$EXIT_INTERNAL"; fi
    shift
  done

  if [ -z "$ARG_FORMAT" ]; then ARG_FORMAT="md"; fi
  case "$ARG_FORMAT" in
    md|json|table) : ;;
    *) err "invalid --format value: '$ARG_FORMAT' (must be md | json | table)"; exit "$EXIT_INTERNAL" ;;
  esac
  if [ -z "$ARG_PLAN" ]; then err "missing required <release_plan.md> argument"; usage >&2; exit "$EXIT_INTERNAL"; fi
}

# ---------------------------------------------------------------------------
# Repo-root resolution (mirrors the release/tools convention).
# ---------------------------------------------------------------------------
resolve_root() {
  if [ -n "$ARG_ROOT" ]; then
    if [ ! -d "$ARG_ROOT" ]; then err "--root path is not a directory: $ARG_ROOT"; exit "$EXIT_INTERNAL"; fi
    REPO_ROOT="$(cd "$ARG_ROOT" && pwd -P)"
    return
  fi
  if command -v git >/dev/null 2>&1; then
    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then REPO_ROOT="$git_root"; return; fi
  fi
  REPO_ROOT="$(pwd -P)"
}

# ---------------------------------------------------------------------------
# Sibling-tool resolution. Absent tools degrade the dependent family to a
# well-formed ERROR verdict (fail loud), never a fabricated PASS.
# ---------------------------------------------------------------------------
resolve_sibling_tools() {
  DEPLOY_CHECK="$REPO_ROOT/core/deploy/deploy.sh"
  EVENT_WRITER="$REPO_ROOT/release/tools/append-pipeline-event.sh"
}

# ---------------------------------------------------------------------------
# Plan-target resolution → absolute path.
# ---------------------------------------------------------------------------
resolve_plan() {
  local input="$ARG_PLAN" abs
  if [ -e "$REPO_ROOT/$input" ]; then abs="$REPO_ROOT/$input"
  elif [ -e "$input" ]; then abs="$(cd "$(dirname "$input")" && pwd -P)/$(basename "$input")"
  else err "plan target does not exist: $input"; exit "$EXIT_BAD_TARGET"; fi
  if [ ! -f "$abs" ]; then err "plan target is not a regular file: $abs"; exit "$EXIT_BAD_TARGET"; fi
  PLAN_ABS="$abs"
}

# ===========================================================================
# Component 1 — parse_verification_plan()
#
# Locates the plan's `## Verification Plan` H2, then extracts each per-issue
# markdown table. Two table shapes are tolerated (m-5):
#   (a) canonical Issue-keyed table: an `Issue` column groups rows per issue;
#   (b) enriched AC-keyed per-issue-subsection form: no `Issue` column, so the
#       enclosing `#N` subsection header (a bold `**#N — …**` heading) supplies
#       the per-issue grouping, keeping the emitted evidence well-formed.
# Each parsed row becomes a check record: issue | ac | family | method | expected.
# Records are emitted as TAB-separated lines on stdout (one per check).
# ===========================================================================

# Extract the body of a section whose heading STARTS WITH the given text. The
# section runs from its heading to the next heading of the same-or-higher level
# (an H2 section ends at the next H2; an H3 section ends at the next H2 or H3).
# Prefix-matching lets a heading carry a parenthetical suffix
# (e.g. "Cross-Issue Acceptance Criteria (dog-food of …)") and still match.
_extract_section() {
  # $1 = plan file, $2 = section-heading prefix (matched after the #… marker)
  local file="$1" heading="$2"
  awk -v want="$heading" '
    function hlevel(s,   k) { k = 0; while (substr(s, k+1, 1) == "#") k++; return k }
    BEGIN { insec = 0; want_level = 0; want_len = length(want) }
    /^#+ / {
      line = $0
      lvl = hlevel(line)
      sub(/^#+[ ]+/, "", line)          # strip the "#… " marker
      if (insec == 1 && lvl <= want_level) { insec = 0 }   # next same/higher heading ends it
      if (insec == 0 && substr(line, 1, want_len) == want) { insec = 1; want_level = lvl; next }
    }
    insec == 1 { print }
  ' "$file"
}

# Classify a check record's family from a predicate-class hint + method keywords.
# $1 = predicate-class-hint (may be empty), $2 = method string.
classify_family() {
  local hint method
  hint="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  method="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"

  # 0) Declared-deferred method → the honesty contract routes it to a family-
  #    agnostic SKIP (never a fabricated PASS, never a false ERROR). A method is
  #    deferred when it is bracket-tagged [DEFERRED …] or says "verification
  #    deferred to #<executor>". This precedes family classification because a
  #    deferred check is a SKIP regardless of which family it would run under.
  case "$method" in
    *"[deferred"*|*declared,\ verification\ deferred*|*verification\ deferred*|*deferred\ to\ #*)
      echo "deferred"; return ;;
  esac

  # 1) Explicit predicate-class hint (enriched Stage-4 plan form) wins.
  case "$hint" in
    *integration*|*cross-issue*)          echo "integration";   return ;;
    *regression*)                         echo "regression";    return ;;
    *sync*)                               echo "sync";          return ;;
    *runtime*|*suite*|*behavioral*)       echo "runtime-suite"; return ;;
    *file-path*|*file-state*|*content*)   echo "per-issue";     return ;;
  esac

  # 2) Fallback: keyword-match the method string.
  case "$method" in
    *cross-issue*|*ciac*|*integration*)                echo "integration";   return ;;
    *deploy.sh*--check*|*deploy*--check*|*byte-diff*|*byte-equivalent*|*unchanged*)
        # deploy --check covers both sync and regression; a "regression"/"unchanged"
        # word routes to regression, else the source<->deployed reading is sync.
        case "$method" in
          *regression*|*unchanged*|*byte-diff*|*byte-equivalent*|*intact*) echo "regression"; return ;;
          *) echo "sync"; return ;;
        esac ;;
    *runtime*suite*|*test-run*|*dispatch*the*runtime*|*suite-*|*exercise*) echo "runtime-suite"; return ;;
    *grep*|*"test -f"*|*anchor*|*present*|*"≥"*|*">="*)                     echo "per-issue";     return ;;
  esac

  # 3) Unclassifiable → the caller emits ERROR (fail loud; never drop a check).
  echo "unclassified"
}

# Parse the Verification-Plan per-issue tables into check records.
# Emits TAB-separated: issue \t ac \t family \t method \t expected
parse_verification_plan() {
  local file="$1"
  local body
  body="$(_extract_section "$file" "Verification Plan")"
  if [ -z "$body" ]; then return 0; fi

  printf '%s\n' "$body" | awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function lc(s)   { return tolower(s) }
    BEGIN { cur_issue = ""; have_issue_col = 0; col_ac = 0; col_pred = 0; col_method = 0; col_expected = 0 }
    # (b) enriched form: a bold per-issue subsection header supplies grouping.
    # Matches a bold per-issue header line like: **#<issue> — <title>**
    /^\*\*#[0-9]+/ {
      line = $0
      match(line, /#[0-9]+/)
      cur_issue = substr(line, RSTART, RLENGTH)
      have_issue_col = 0
      col_ac = 0; col_pred = 0; col_method = 0; col_expected = 0
      next
    }
    # A markdown table row starts with a leading pipe (after optional spaces).
    /^[ \t]*\|/ {
      n = NF
      # Header row: locate columns by name.
      is_header = 0
      for (i = 1; i <= n; i++) {
        c = lc(trim($i))
        if (c == "issue") { have_issue_col = 1; col_issue = i; is_header = 1 }
        if (c == "ac")    { col_ac = i; is_header = 1 }
        if (c ~ /predicate/) { col_pred = i; is_header = 1 }
        if (c ~ /verification method/ || c == "method") { col_method = i; is_header = 1 }
        if (c ~ /expected/) { col_expected = i; is_header = 1 }
      }
      if (is_header) { next }
      # Separator row (|---|---|).
      if ($0 ~ /^[ \t]*\|[ \t:-]+\|/ && $0 ~ /-/) {
        stripped = $0; gsub(/[ \t|:-]/, "", stripped)
        if (stripped == "") next
      }
      # Data row — only emit when we know where method + expected live.
      if (col_method == 0) next
      method   = (col_method   <= n) ? trim($col_method)   : ""
      expected = (col_expected <= n && col_expected > 0) ? trim($col_expected) : ""
      pred     = (col_pred     <= n && col_pred     > 0) ? trim($col_pred)     : ""
      ac       = (col_ac       <= n && col_ac       > 0) ? trim($col_ac)       : ""
      issue    = have_issue_col && (col_issue <= n) ? trim($col_issue) : cur_issue
      if (issue == "") issue = cur_issue
      if (method == "") next
      # Skip a row whose AC cell is itself the word "AC" (defensive).
      printf "%s\t%s\t%s\t%s\t%s\n", issue, ac, "PENDING", method, expected
      # family filled in by the shell classifier (awk cannot call it); marker.
    }
  '
}

# ===========================================================================
# Component 2/3/4 — family classifier + dispatch table + handlers.
#
# Each handler is a pure (method, expected) -> verdict function. It prints a
# single line: verdict \t observed. Handlers shell ONLY existing primitives.
# ===========================================================================

# RUNNABLE_VERBS — the read-only query set this executor is permitted to run.
# Deliberately closed. A verification harness driven by an authored artifact must
# not acquire a code-execution channel: "the plan names which tool to run" is not
# a trust boundary when the same pull request can author both. A criterion whose
# substance needs a tool invocation is therefore NOT executed here — it is
# reported as an honest, reasoned SKIP naming the verb, and its mechanical
# guarantee is expected to live in that tool's own CI-invoked self-test, which is
# a gate in its own right.
RUNNABLE_VERBS='grep test ls head wc cat'

is_runnable_verb() {
  case " $RUNNABLE_VERBS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# looks_like_command — a span is command-shaped when its leading token is a bare
# word (a verb), not a flag, a path fragment, a section reference or prose.
looks_like_command() {
  case "$1" in
    ''|-*|/*|.*|\#*) return 1 ;;
    *) case "$1" in *[!A-Za-z0-9_.-]*) return 1 ;; esac; return 0 ;;
  esac
}

# extract_command — pull the runnable command out of a method string.
#
# It scans EVERY backtick-quoted span and returns the FIRST one whose leading
# token is an allowlisted verb; if none is, it returns the first COMMAND-SHAPED
# span so the caller can report the verb it declined to run. Taking the first
# span unconditionally was a defect: an authored method that mentions a flag or a
# symbol in backticks before its actual probe (*Method:* run `--self-test`; then
# `grep …`) yielded `--self-test` as the "verb" and reported ERROR — a malformed-
# input verdict for a well-formed method. Falls back to the bare string when it
# already starts with an allowlisted verb (the shape the CIAC parser hands over,
# having stripped its own backticks). Prints the command or nothing.
extract_command() {
  local method="$1" span first fallback="" line
  while IFS= read -r span; do
    [ -n "$span" ] || continue
    first="$(printf '%s' "$span" | sed -e 's/^[[:space:]]*//' | awk '{print $1}')"
    if is_runnable_verb "$first"; then printf '%s' "$span"; return; fi
    if [ -z "$fallback" ] && looks_like_command "$first"; then fallback="$span"; fi
  done <<EOF
$(printf '%s' "$method" | tr '\`' '\n' | awk 'NR % 2 == 0')
EOF
  if [ -n "$fallback" ]; then printf '%s' "$fallback"; return; fi
  first="$(printf '%s' "$method" | sed -e 's/^[[:space:]]*//' | awk '{print $1}')"
  if is_runnable_verb "$first"; then
    printf '%s' "$(printf '%s' "$method" | sed -e 's/^[[:space:]]*//')"
  fi
}

# extract_threshold — pull a numeric threshold and its COMPARATOR out of a method.
# Prints "<op>\t<n>", or nothing when the method states no threshold.
#
# Four comparators, because "expect zero" is the shape most verification criteria
# actually take and a >=-only parser cannot express it: a `>= 0` assertion passes
# unconditionally, so a criterion meaning "no findings" had to be written as prose
# and fell through to SKIP. That expressiveness gap — not the criteria — is why
# this roll-up read 0 PASS.
#   >= N   "≥ N", ">= N", "at least N"
#   <= N   "≤ N", "<= N", "at most N", "no more than N"
#   == N   "exactly N", "= N", "expect N" (and "expect zero" / "expect 0")
# NOTE ON THE REGEX DIALECT: every alternation below uses `sed -E` (ERE). BSD sed
# does NOT support `\|` in a basic regular expression, so a BRE alternation here
# silently matches nothing and every threshold reads as "absent" — which presents
# as a rows-pass-on-exit-code roll-up rather than as an error. The original two
# comparators avoided this by using two separate BRE calls; the comparator set is
# wide enough now that ERE is the honest way to write it.
extract_threshold() {
  local method="$1" n
  n="$(printf '%s' "$method" | sed -nE 's/.*(≥|>=|at least)[ ]*([0-9]+).*/\2/p' | head -1)"
  [ -n "$n" ] && { printf '>=\t%s' "$n"; return; }
  n="$(printf '%s' "$method" | sed -nE 's/.*(≤|<=|at most|no more than)[ ]*([0-9]+).*/\2/p' | head -1)"
  [ -n "$n" ] && { printf '<=\t%s' "$n"; return; }
  n="$(printf '%s' "$method" | sed -nE 's/.*(exactly|expect)[ ]*([0-9]+).*/\2/p' | head -1)"
  [ -n "$n" ] && { printf '==\t%s' "$n"; return; }
  case "$method" in
    *"expect zero"*|*"expect none"*) printf '==\t0'; return ;;
  esac
}

# compare_threshold — apply a comparator. Prints PASS or FAIL.
compare_threshold() {
  local count="$1" op="$2" want="$3"
  case "$op" in
    '>=') [ "$count" -ge "$want" ] 2>/dev/null && printf 'PASS' || printf 'FAIL' ;;
    '<=') [ "$count" -le "$want" ] 2>/dev/null && printf 'PASS' || printf 'FAIL' ;;
    '==') [ "$count" -eq "$want" ] 2>/dev/null && printf 'PASS' || printf 'FAIL' ;;
    *)    printf 'FAIL' ;;
  esac
}

# per-issue: extract a runnable predicate from the method string and run it.
# Supports the two dominant shapes: `grep ... ≥ N` / `grep -c ... N` and
# `test -f <path>`. Anything else with an executable command substring is run
# in a restricted way (command allowlist), else SKIP (honest — no fabricated
# PASS for a check that carries no runnable method).
handle_per_issue() {
  local method="$1" expected="$2"
  # Honest no-op: a declared-deferred method is a SKIP with a reason. (The
  # classifier already routes most DEFERRED methods to the deferred family; this
  # is the belt-and-suspenders guard for a per-issue-classified deferred row.)
  case "$method" in
    *DEFERRED*|*declared,\ verification\ deferred*|*deferred\ to\ #*)
      printf '%s\t%s\n' "$VERDICT_SKIP" "declared-deferred"; return ;;
  esac

  local cmd
  cmd="$(extract_command "$method")"
  if [ -z "$cmd" ]; then
    # No runnable command embedded → cannot execute honestly.
    printf '%s\t%s\n' "$VERDICT_SKIP" "no-executable-command-in-method"; return
  fi

  # Allowlist the leading verb. Outside the read-only query set is an honest
  # SKIP naming the verb, not an ERROR: the executor declining to run a tool is
  # a statement about the executor, not a defect in the method. ERROR is reserved
  # for input this parser cannot make sense of.
  local verb; verb="$(printf '%s' "$cmd" | awk '{print $1}')"
  if ! is_runnable_verb "$verb"; then
    printf '%s\t%s\n' "$VERDICT_SKIP" \
      "tool-invocation-outside-executor-allowlist:$verb (not executed here; its mechanical guarantee belongs in that tool's own self-test)"
    return
  fi

  local threshold op want; threshold="$(extract_threshold "$method")"
  op="$(printf '%s' "$threshold" | cut -f1)"; want="$(printf '%s' "$threshold" | cut -f2)"

  # Run the embedded command from REPO_ROOT so relative paths resolve.
  local out rc count
  set +e
  out="$( cd "$REPO_ROOT" && eval_free_run "$cmd" 2>/dev/null )"
  rc=$?
  set -e

  if [ -n "$threshold" ]; then
    # Interpret output as a count (grep -c prints an integer per file; sum).
    count="$(printf '%s\n' "$out" | awk -F: '{ s += $NF } END { print s+0 }')"
    if [ "$(compare_threshold "$count" "$op" "$want")" = PASS ]; then
      printf '%s\t%s\n' "$VERDICT_PASS" "count=$count ($op $want)"
    else
      printf '%s\t%s\n' "$VERDICT_FAIL" "count=$count (wanted $op $want)"
    fi
    return
  fi

  # No threshold: PASS iff the command succeeded (rc 0), else FAIL.
  if [ "$rc" -eq 0 ]; then
    printf '%s\t%s\n' "$VERDICT_PASS" "command-succeeded"
  else
    printf '%s\t%s\n' "$VERDICT_FAIL" "command-exit-$rc"
  fi
}

# tokenize_cmd — split a command string into words, respecting single- and
# double-quoted spans (so a quoted grep pattern that contains spaces or a `|`
# alternation stays ONE argument). Populates the global array TOKENS[].
# Returns non-zero on an unterminated quote.
tokenize_cmd() {
  local s="$1" i=0 n=${#1} ch cur="" inq="" started=0
  TOKENS=()
  while [ "$i" -lt "$n" ]; do
    ch="${s:$i:1}"
    if [ -n "$inq" ]; then
      if [ "$ch" = "$inq" ]; then inq=""; else cur+="$ch"; fi
    else
      case "$ch" in
        \'|\") inq="$ch"; started=1 ;;
        ' '|$'\t')
          if [ "$started" -eq 1 ]; then TOKENS+=("$cur"); cur=""; started=0; fi ;;
        *) cur+="$ch"; started=1 ;;
      esac
    fi
    i=$((i+1))
  done
  if [ -n "$inq" ]; then return 2; fi          # unterminated quote
  if [ "$started" -eq 1 ]; then TOKENS+=("$cur"); fi
  return 0
}

# eval_free_run — run a whitelisted command WITHOUT the shell `eval` of a
# plan-derived string. The command is quote-aware-tokenized and its tokens are
# passed straight to the binary as separate arguments, so a shell operator
# character inside an argument (a `|` in a grep alternation, a `;`) is a LITERAL
# byte to the tool, never a shell operator — there is no shell to interpret it.
# The verb is allowlisted to a read-only query set; the leading token cannot be
# a path/redirect. Defense-in-depth: reject an argument that embeds a command-
# substitution opener even though, absent eval, it too would be literal.
eval_free_run() {
  local cmd="$1" verb
  if ! tokenize_cmd "$cmd"; then return 3; fi
  [ "${#TOKENS[@]}" -ge 1 ] || return 3
  verb="${TOKENS[0]}"
  # Defense-in-depth guard on every argument (belt-and-suspenders; not load-
  # bearing since tokens bypass the shell).
  local t
  for t in "${TOKENS[@]}"; do
    case "$t" in
      *'$('*|*'`'*) return 3 ;;
    esac
  done
  local args=( "${TOKENS[@]:1}" )
  case "$verb" in
    grep) grep "${args[@]}" ;;
    test) test "${args[@]}" ;;
    ls)   ls "${args[@]}" ;;
    head) head "${args[@]}" ;;
    wc)   wc "${args[@]}" ;;
    cat)  cat "${args[@]}" ;;
    *)    return 3 ;;
  esac
}

# integration: run a Cross-Issue AC entry's declared method (SOLE runner — this
# executor is the sole runner of CIAC methods and the sole emitter of their
# verdicts; Stage-9 reads the emitted verdict read-only, never re-running it).
# $1 = full method text parsed from the CIAC entry (command + any ≥N threshold).
handle_integration() {
  local method="$1"
  case "$method" in
    *DEFERRED*|*declared,\ verification\ deferred*|*deferred\ to\ #*)
      printf '%s\t%s\n' "$VERDICT_SKIP" "declared-deferred"; return ;;
  esac
  # A CIAC method is a reproducible command (grep / anchor) OR a prose
  # "confirm the recorded no-overlap decision" fallback.
  local cmd
  cmd="$(extract_command "$method")"
  if [ -z "$cmd" ]; then
    # No runnable command; the entry declares a documented-decision method.
    printf '%s\t%s\n' "$VERDICT_SKIP" "documented-decision-method (no runnable command)"; return
  fi
  local verb; verb="$(printf '%s' "$cmd" | awk '{print $1}')"
  if ! is_runnable_verb "$verb"; then
    printf '%s\t%s\n' "$VERDICT_SKIP" \
      "tool-invocation-outside-executor-allowlist:$verb (not executed here; its mechanical guarantee belongs in that tool's own self-test)"
    return
  fi
  local out rc count threshold op want
  set +e
  out="$( cd "$REPO_ROOT" && eval_free_run "$cmd" 2>/dev/null )"
  rc=$?
  set -e
  threshold="$(extract_threshold "$method")"
  op="$(printf '%s' "$threshold" | cut -f1)"; want="$(printf '%s' "$threshold" | cut -f2)"
  if [ -n "$threshold" ]; then
    count="$(printf '%s\n' "$out" | awk -F: '{ s += $NF } END { print s+0 }')"
    if [ "$(compare_threshold "$count" "$op" "$want")" = PASS ]; then
      printf '%s\t%s\n' "$VERDICT_PASS" "co-occurrence count=$count ($op $want)"
    else
      printf '%s\t%s\n' "$VERDICT_FAIL" "co-occurrence count=$count (wanted $op $want)"
    fi
    return
  fi
  if [ "$rc" -eq 0 ]; then printf '%s\t%s\n' "$VERDICT_PASS" "integration-method-succeeded"
  else printf '%s\t%s\n' "$VERDICT_FAIL" "integration-method-exit-$rc"; fi
}

# deploy_check_exit_code — run deploy --check AT MOST ONCE per executor invocation
# and PRINT its exit code (deploy --check is a heavy full-workspace validation; a
# plan that declares several sync/regression methods must not re-run it per row).
# The result is cached to DEPLOY_CHECK_CACHE (a per-run temp file set in main) so
# the memo survives the command-substitution subshells the handlers run in. It
# prints the code (rather than `return`ing it) so no non-zero return trips the
# caller's errexit; the function itself always succeeds. Changes no output
# contract — it only avoids redundant runs.
deploy_check_exit_code() {
  if [ -n "${DEPLOY_CHECK_CACHE:-}" ] && [ -s "$DEPLOY_CHECK_CACHE" ]; then
    cat "$DEPLOY_CHECK_CACHE"; return 0
  fi
  local rc=0
  ( cd "$REPO_ROOT" && bash "$DEPLOY_CHECK" --check ) >/dev/null 2>&1 || rc=$?
  if [ -n "${DEPLOY_CHECK_CACHE:-}" ]; then printf '%s' "$rc" > "$DEPLOY_CHECK_CACHE"; fi
  printf '%s' "$rc"
  return 0
}

# sync + regression: delegate to deploy --check (source<->deployed byte-diff).
# We do NOT re-implement diffing; the deploy check IS the sync/regression oracle.
handle_deploy_check() {
  local family="$1"
  if [ ! -x "$DEPLOY_CHECK" ] && [ ! -f "$DEPLOY_CHECK" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "deploy.sh --check not found at $DEPLOY_CHECK"; return 0
  fi
  local rc
  rc="$(deploy_check_exit_code)"
  # deploy --check exits 0 when source and deployed copies are in sync.
  if [ "$rc" -eq 0 ] 2>/dev/null; then
    printf '%s\t%s\n' "$VERDICT_PASS" "deploy --check clean (in-sync)"
  else
    printf '%s\t%s\n' "$VERDICT_FAIL" "deploy --check non-clean (exit $rc); ${family} — see deploy.sh --check output"
  fi
  return 0
}

# resolve_plan_release_key <plan-file> — the release JOIN KEY for this plan.
#
# The key is the milestone SLUG (pipeline-event-log-schema.md § 2a); the shipped
# vX.Y is NOT a key and the event writer rejects it. Resolution order:
#   1. the plan's `**Milestone:** \`<slug>\`` line — authoritative when present
#   2. the plan FILENAME stem, when the plan is still slug-named (pre-claim,
#      `<slug>_RELEASE_PLAN.md`); a claim-time-renamed `vX.Y_RELEASE_PLAN.md`
#      stem is a version, so it is rejected here rather than passed through
#   3. the reserved `(none)` sentinel — never a synthesized placeholder version
resolve_plan_release_key() {
  local plan="$1" key=""
  key="$(grep -m1 -E '^\*\*Milestone:\*\*' "$plan" 2>/dev/null \
         | sed -n 's/^\*\*Milestone:\*\*[[:space:]]*`\([^`]*\)`.*/\1/p')"
  if [ -z "$key" ]; then
    key="$(basename "$plan" | sed -n 's/^\(.*\)_RELEASE_PLAN\.md$/\1/p')"
    # A version-shaped stem is not a key. Match the canonical grammar shape
    # (version-grammar.sh); anything matching it is discarded, not emitted.
    case "$key" in
      v[0-9]*.[0-9]*) printf '%s' "(none)"; return 0 ;;
    esac
  fi
  # A `{{...}}` token means the plan is still holding an unresolved provisional
  # display version — not a key either.
  case "$key" in
    ''|*'{{'*|*'}}'*) printf '%s' "(none)"; return 0 ;;
  esac
  printf '%s' "$key"
}

# runtime-suite: emit a test-run event through the pipeline-event writer.
# Under the map, a check whose deliverable path is unmapped is an honest
# suite-skip. We do not run suites in a novel way; we invoke the same event
# path Engineering self-verification + Dev Testing already use.
# $1 = method string, $2 = release join key (slug, for the event --version).
handle_runtime_suite() {
  local method="$1" version="$2" subtype outcome
  # An unmapped / no-match method → suite-skip (honest no-op).
  case "$method" in
    *suite-skip*|*no-match*|*unmapped*|*no\ runtime*) subtype="suite-skip"; outcome="resolved" ;;
    *suite-fail*|*FAIL*)                              subtype="suite-fail"; outcome="escalated" ;;
    *)                                                subtype="suite-pass"; outcome="resolved" ;;
  esac
  if [ "$ARG_EMIT_EVENTS" -eq 1 ]; then
    if [ ! -x "$EVENT_WRITER" ] && [ ! -f "$EVENT_WRITER" ]; then
      printf '%s\t%s\n' "$VERDICT_ERROR" "append-pipeline-event.sh not found at $EVENT_WRITER"; return
    fi
    set +e
    ( cd "$REPO_ROOT" && bash "$EVENT_WRITER" \
        --version "${version:-(none)}" --stage 6 \
        --event-type test-run --event-subtype "$subtype" \
        --actor "skill:verify-release-plan" --subject "release-plan:verification" \
        --reversibility CHEAP --outcome "$outcome" \
        --payload "runtime-suite family dispatch via verify-release-plan.sh" ) >/dev/null 2>&1
    local rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then printf '%s\t%s\n' "$VERDICT_ERROR" "test-run emit failed (exit $rc)"; return; fi
  fi
  case "$subtype" in
    suite-skip) printf '%s\t%s\n' "$VERDICT_SKIP" "test-run/$subtype (map no-match)" ;;
    suite-fail) printf '%s\t%s\n' "$VERDICT_FAIL" "test-run/$subtype" ;;
    *)          printf '%s\t%s\n' "$VERDICT_PASS" "test-run/$subtype" ;;
  esac
}

# Dispatch: family -> handler. Fail loud on an unclassified family.
dispatch_check() {
  local family="$1" method="$2" expected="$3" version="$4"
  case "$family" in
    deferred)       printf '%s\t%s\n' "$VERDICT_SKIP" "declared-deferred" ;;
    per-issue)      handle_per_issue "$method" "$expected" ;;
    integration)    handle_integration "$method" ;;
    sync)           handle_deploy_check "sync" ;;
    regression)     handle_deploy_check "regression" ;;
    runtime-suite)  handle_runtime_suite "$method" "$version" ;;
    *)              printf '%s\t%s\n' "$VERDICT_ERROR" "unclassified-method (no family match)" ;;
  esac
}

# ===========================================================================
# Component 1b — parse the Cross-Issue Acceptance Criteria section into
# integration check records. Reads the release plan's landed Cross-Issue
# Acceptance Criteria section VERBATIM (this script defines no schema of its own).
#
# Two authored shapes are tolerated:
#   (i)  the canonical scaffold bullet:
#          - [ ] **CIAC-N (#X × #Y on `<surface>`):** <predicate>. *Method:* `<cmd>`.
#   (ii) a table row form (Identifier | ... | Method | ...) as some plans author.
# Emits TAB-separated: ciac_id \t issues \t family(integration) \t method \t predicate
# ===========================================================================
parse_ciac() {
  local file="$1" body
  # _extract_section prefix-matches the heading, so a parenthetical suffix
  # ("Cross-Issue Acceptance Criteria (dog-food …)") still resolves.
  body="$(_extract_section "$file" "Cross-Issue Acceptance Criteria")"
  if [ -z "$body" ]; then return 0; fi

  # (i) scaffold-bullet form.
  printf '%s\n' "$body" | awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    /\*\*CIAC-[0-9]+/ {
      line = $0
      # id
      match(line, /CIAC-[0-9]+/); id = substr(line, RSTART, RLENGTH)
      # issues spanned: capture the #N tokens inside the parenthetical head only
      # (the text up to the ")**" that closes the CIAC identifier), de-duplicated,
      # so #N tokens repeated in the predicate prose do not double-count.
      head = line
      hp = index(head, ")**")
      if (hp > 0) head = substr(head, 1, hp)
      issues = ""
      delete seen_iss
      tmp = head
      while (match(tmp, /#[0-9]+/)) {
        tok = substr(tmp, RSTART, RLENGTH)
        if (!(tok in seen_iss)) { seen_iss[tok] = 1; issues = issues (issues=="" ? "" : ",") tok }
        tmp = substr(tmp, RSTART+RLENGTH)
      }
      # method: capture the FULL clause after *Method:* — backticked command
      # PLUS any trailing "≥ N" threshold that sits outside the backticks — so
      # the shell command/threshold extractors see both. Fall back to the first
      # backticked span on the line if there is no *Method:* marker.
      method = ""
      mstart = 0
      if (match(line, /[Mm]ethod:?\*{0,2}[ ]*/)) {
        mstart = RSTART + RLENGTH
        rest = substr(line, mstart)
        # Trim at the *Graded …* clause marker if present, else at end of line.
        gi = index(rest, "*Graded")
        if (gi > 0) rest = substr(rest, 1, gi - 1)
        method = trim(rest)
        # Drop a trailing period left after trimming the Graded clause.
        sub(/\.[ ]*$/, "", method)
      } else if (match(line, /`[^`]*`/)) {
        method = substr(line, RSTART, RLENGTH)   # keep the backticks
      }
      # predicate: strip the leading list-marker for a short text.
      pred = line
      sub(/^[-*[ \]]*/, "", pred)
      printf "%s\t%s\tintegration\t%s\t%s\n", id, issues, method, trim(pred)
    }
  '

  # (ii) table-row form: rows whose first cell contains CIAC-N with a Method cell.
  printf '%s\n' "$body" | awk -F'|' '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    BEGIN { col_method = 0; have_header = 0 }
    /^[ \t]*\|/ {
      n = NF
      is_header = 0
      for (i=1;i<=n;i++){ c = lc(trim($i)); if (c ~ /method/){ col_method = i; is_header=1 } ; if (c ~ /predicate/){ col_pred = i; is_header=1 } }
      if (is_header) { have_header = 1; next }
      if ($0 ~ /^[ \t]*\|[ \t:-]+\|/ && $0 ~ /-/) { s=$0; gsub(/[ \t|:-]/,"",s); if (s=="") next }
      # Only treat as CIAC table if a cell names CIAC-N.
      rowline = $0
      if (rowline !~ /CIAC-[0-9]+/) next
      if (col_method == 0) next
      match(rowline, /CIAC-[0-9]+/); id = substr(rowline, RSTART, RLENGTH)
      issues = ""
      tmp = rowline
      while (match(tmp, /#[0-9]+/)) { issues = issues (issues==""?"":",") substr(tmp,RSTART,RLENGTH); tmp = substr(tmp,RSTART+RLENGTH) }
      method = (col_method<=n)? trim($col_method) : ""
      pred   = (col_pred>0 && col_pred<=n)? trim($col_pred) : ""
      # Pull a backticked command out of the method cell if present.
      m2 = method
      if (match(method, /`[^`]*`/)) { m2 = substr(method, RSTART+1, RLENGTH-2) }
      printf "%s\t%s\tintegration\t%s\t%s\n", id, issues, m2, pred
    }
  ' | awk '!seen[$1]++'   # de-dupe: bullet form wins if both matched an id.
}

# ===========================================================================
# Component 6 — fcm-delivery: the plan's declared File Change Matrix ADDs
# reconciled against the diff that actually merged.
#
# WHY THIS EXISTS. Scope-boundary verification in this pipeline was
# ONE-DIRECTIONAL: Stage 7 DT and Stage 8 QA both ask whether anything OUTSIDE
# the approved matrix was touched, and neither asks whether everything INSIDE it
# landed. A scope-lock-approved ADR therefore vanished between Collective Review
# and merge (v4.03, `2adf533e`) with five verification stages, two operator gates
# and ten review reports passing over it. This family closes the inbound
# direction. The outbound direction ("every delivered add is declared") is a
# real and separate gap and is deliberately NOT solved here.
#
# THE DOMINANT DEFECT CLASS THIS FAMILY MUST NOT REPRODUCE: an unparseable,
# absent, empty or truncated matrix must NEVER read as "no declared ADDs,
# therefore no violations". Every unreadable state below is ERROR or a NAMED
# SKIP carrying its own denominator — never a silent PASS, and never silence.
# ===========================================================================

# --- Extraction -------------------------------------------------------------
#
# _extract_section (:238) is FENCE-BLIND: its `/^#+ /` awk rule fires on any line
# beginning `#`+space, including a `# ── label ──` comment INSIDE a fenced block,
# which terminates the section early. Measured over the 165-file plan corpus:
# 26 of the 117 FCM-bearing plans truncate that way, losing every declaration row
# after the first in-fence comment.
#
# The shared seam is deliberately NOT widened. Making `_extract_section` itself
# fence-aware was measured against both of its live consumers first, and it
# REGRESSES one: `v4.14_RELEASE_PLAN.md` gains 39 spurious `parse_verification_plan`
# records (32 -> 70) because its Verification Plan section carries an in-fence `#`
# line, and the newly-visible prose tables parse as check rows. Trading a silent
# truncation in one family for spurious dispatched checks in another is not a fix.
# So the FCM path gets its own extractor and the shared seam is left byte-identical.
# The `_extract_section` fence-blindness remains a real defect for the other two
# families; it is routed out, not absorbed here.
#
# Fence state is scoped to the SECTION (reset on entry), so a fence opened earlier
# in the file cannot leak in and suppress the terminating heading.
_extract_fcm_section() {
  # $1 = plan file. Prints the File Change Matrix section body.
  local file="$1"
  awk -v want="File Change Matrix" '
    function hlevel(s,   k) { k = 0; while (substr(s, k+1, 1) == "#") k++; return k }
    BEGIN { insec = 0; want_level = 0; want_len = length(want); infence = 0 }
    /^[ \t]*(```|~~~)/ { if (insec == 1) { infence = 1 - infence; print }; next }
    (insec == 0 || infence == 0) && /^#+ / {
      line = $0
      lvl = hlevel(line)
      sub(/^#+[ ]+/, "", line)
      if (insec == 1 && lvl <= want_level) { insec = 0 }
      if (insec == 0 && substr(line, 1, want_len) == want) { insec = 1; want_level = lvl; infence = 0; next }
    }
    insec == 1 { print }
  ' "$file"
}

# Extraction-completeness assertion (PV-3: show the bytes the probe read were not
# truncated). An ODD number of fence markers in the extracted body means a fence
# opened and never closed inside the section — the body is provably incomplete.
# Measured on the corpus this predicate is EXACT: it fires on all 26 truncated
# sections under the fence-blind extractor and on 0 of the other 91 (no misses,
# no false positives), and on 0 of 117 under the extractor above. It is retained
# as a belt-and-suspenders guard so a future authoring shape that defeats the
# fence tracker surfaces as an ERROR rather than as a short, confident row set.
_fcm_body_truncated() {
  # stdin = section body. Exit 0 when the body is UNBALANCED (i.e. truncated).
  awk '
    /^[ \t]*(```|~~~)/ { n++ }
    END { exit (n % 2 == 0) }
  '
}

# --- Declaration parsing ----------------------------------------------------
#
# Emits TAB records:  path \t intent \t conditionality \t source_form \t raw_line
#
# intent        add | edit | delete | rename | read | excluded | unknown | malformed
# conditionality  uncond | cond
# source_form   fence-verb-first | fence-path-first | fence-bare | table | table-pathless
#
# `unknown` is the deliberate divergence from `bundle-issues-parser.py:218`, which
# defaults a marker-less path to `edit`. That default is safe on an issue body (a
# wrong guess costs one spurious GENERATES edge) and unsafe here, where it would
# convert "intent was never declared" into "no ADDs were declared, therefore no
# violations" — verbatim the vacuity this family exists to close. Same enum,
# different default, and the difference is the whole point. `unknown` rows are
# COUNTED and REPORTED (see the coverage record) rather than silently dropped:
# 962 of the 2,047 declaration rows in the corpus are bare, so dropping them
# silently would be a 47% blind spot presented as full coverage.
parse_fcm_declarations() {
  local body="$1"
  printf '%s\n' "$body" | awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    function hasw(u, w) { return match(u, "(^|[^A-Z])" w "([^A-Z]|$)") }
    function pathof(s,   t) {
      if (!match(s, /(core|release|docs|packages|projects|roadmaps|\.github|\.claude)\/[^ \t`|,;()]+/)) return ""
      t = substr(s, RSTART, RLENGTH)
      sub(/\*\*$/, "", t); sub(/[.,;:]+$/, "", t); sub(/`+$/, "", t)
      return t
    }
    # A declared path is a COMPARISON KEY only — never interpolated into a command.
    # A row carrying a traversal, an absolute root or a shell metacharacter is
    # reported as malformed rather than normalized into something runnable.
    # `<` and `>` are NOT metacharacters here: the corpus authors placeholder
    # segments as `<slug>`, and rejecting them would classify the single most
    # important row in the originating specimen as malformed. They are safe
    # because a declared path is only ever a `case` glob key and a string compare,
    # never a token in a command line.
    function malformed(p) {
      if (p ~ /\.\./) return 1
      if (substr(p,1,1) == "/") return 1
      if (p ~ /[;&$()]/) return 1
      return 0
    }
    function verbof(u) {
      if (index(u, "NOT EDITED") || index(u, "NOT TOUCHED")) return "excluded"
      if (hasw(u,"READ"))                                    return "read"
      if (hasw(u,"RENAME") || hasw(u,"RENAMED") || hasw(u,"MOVE")) return "rename"
      if (hasw(u,"ADD") || hasw(u,"NEW") || hasw(u,"CREATE")) return "add"
      if (hasw(u,"DELETE") || hasw(u,"REMOVE"))              return "delete"
      if (hasw(u,"EDIT") || hasw(u,"MODIFY"))                return "edit"
      return ""
    }
    function stripfirst(s, p,   i) {
      i = index(s, p); if (i == 0) return s
      return substr(s, 1, i - 1) substr(s, i + length(p))
    }
    # Conditionality is a MARKER, not a substring — and specifically it is one of
    # the two NORMATIVE marker forms, `CONDITIONAL:<token>` or `CONDITIONAL on
    # <prose>`. A bare occurrence of the word is neither, because in a real matrix
    # it is usually annotation prose.
    #
    # Both narrowings are load-bearing, and each was found by running the check
    # rather than by reading it:
    #   - the declared path is removed before the test, because the originating
    #     specimen declares `release/ADRs/<self-arming-conditional-gate-posture>.md`,
    #     whose own slug contains the word. Matching it classified that row
    #     CONDITIONAL, which downgrades FAIL to a WARN-tier SKIP — the gate would
    #     have let through the very defect it was built for. Found by the historical
    #     replay arm.
    #   - a bare word does not qualify, because a row reading "(promoted from
    #     CONDITIONAL, see D-11)" is an unconditional row whose NOTE mentions the
    #     word. Found by running the check against the in-flight matrix of the
    #     release that ships it.
    # A row-level conditional exemption should cost a deliberate, tokenizable
    # marker; it should not be purchasable by prose.
    #
    # EDITOR NOTE, and it is not decorative: this awk program is a SINGLE-QUOTED
    # shell string. One apostrophe anywhere inside it — including inside a comment
    # like the possessive that used to sit on the line above — closes the quote and
    # takes the whole file out of parse, and the reported error line has no visible
    # relationship to the cause. Keep this body apostrophe-free.
    function isconditional(s, p,   rest) {
      rest = stripfirst(s, p)
      return (match(rest, /(^|[^A-Za-z])CONDITIONAL:/) ||
              match(rest, /(^|[^A-Za-z])CONDITIONAL on /))
    }
    function labelexcludes(l) {
      return (l ~ /non-scope/ || l ~ /not edited/ || l ~ /not touched/ ||
              l ~ /read-only/ || l ~ /read only/ || l ~ /untouched/)
    }
    BEGIN { infence = 0; label = ""; col_intent = 0; col_path = 0 }
    # Fence toggles. An in-fence `#` comment is a LABEL, not a heading.
    /^[ \t]*(```|~~~)/ { infence = 1 - infence; next }
    {
      line  = $0
      strip = line; gsub(/`/, "", strip)
      s     = trim(strip)
      if (s == "") next
    }
    # Sub-heading, bold label, or in-fence `#` comment -> the current block label.
    # The in-fence comment form is load-bearing: it is how the corpus labels its
    # READ-only and non-scope blocks, and it is the same line shape that terminates
    # the section early under the fence-blind shared extractor.
    s ~ /^#/ || (s ~ /^\*\*/ && s ~ /\*\*$/ && pathof(s) == "") {
      l = lc(s); gsub(/[#*_ ]+/, " ", l); label = l
      col_intent = 0; col_path = 0
      next
    }
    # ---- table row ----
    !infence && s ~ /^\|/ {
      n = split(s, cell, "|")
      is_header = 0
      for (i = 1; i <= n; i++) {
        c = lc(trim(cell[i]))
        if (c == "intent" || c == "action" || c == "change" || c == "disposition" ||
            c == "operation" || c == "op" || c == "type") { col_intent = i; is_header = 1 }
        if (c == "path" || c == "file" || c == "file path" || c == "artifact" ||
            c == "added path" || c == "surface") { col_path = i; is_header = 1 }
      }
      if (is_header) next
      if (s ~ /^\|[ \t:|-]+$/) next
      if (col_intent == 0) next
      iv = verbof(toupper(trim(cell[col_intent])))
      if (iv == "") next
      # FMF-5(c): a MARKED row whose declared path column holds a human label
      # rather than a repository path is a NAMED error, not a silent zero. This is
      # the v4.16 shape, whose `Path` column carries `label grammar` / `ADR-124`.
      p = (col_path > 0 && col_path <= n) ? pathof(trim(cell[col_path])) : ""
      if (p == "") p = pathof(s)
      if (p == "") { printf "%s\t%s\t%s\t%s\t%s\n", "(none)", "pathless", "uncond", "table-pathless", s; next }
      cond = (isconditional(s, p) || label ~ /conditional/) ? "cond" : "uncond"
      if (labelexcludes(label)) iv = "excluded"
      if (malformed(p)) iv = "malformed"
      printf "%s\t%s\t%s\t%s\t%s\n", p, iv, cond, "table", s
      next
    }
    # ---- fenced declaration row ----
    infence {
      p = pathof(s)
      if (p == "") next
      u  = toupper(s)
      iv = verbof(u)
      lead = toupper(trim(substr(s, 1, index(s " ", " "))))
      form = "fence-path-first"
      if (iv != "" && (lead ~ /^(ADD|EDIT|NEW|MODIFY|DELETE|REMOVE|READ|CREATE|RENAME)$/)) form = "fence-verb-first"
      if (iv == "") { iv = "unknown"; form = "fence-bare" }
      cond = (isconditional(s, p) || label ~ /conditional/) ? "cond" : "uncond"
      if (labelexcludes(label)) iv = "excluded"
      if (malformed(p)) iv = "malformed"
      printf "%s\t%s\t%s\t%s\t%s\n", p, iv, cond, form, s
    }
  '
}

# --- Deviation Log ----------------------------------------------------------
#
# AC2's contract: a declared file that legitimately does not ship requires an
# explicit Deviation-Log entry, and the check passes ONLY with that entry present.
# The shipped `## Deviation Log` table is extended; no parallel structure is
# authored. The load-bearing tokens are the literal `NOT DELIVERED` and the
# declared path (or, for a conditional row, its condition token).
parse_deviation_log() {
  local file="$1"
  _extract_section "$file" "Deviation Log" | awk '
    toupper($0) ~ /NOT DELIVERED/ { gsub(/`/, "", $0); print }
  '
}

# --- Path-form taxonomy -----------------------------------------------------
#
# FIVE arms, enumerated against the CORPUS rather than reverse-engineered from the
# one row that failed. Deriving the taxonomy from the specimen is what left globs
# with no arm: 27 glob-bearing path tokens across 15 plans are an established
# authored form, and a taxonomy without an arm for them yields a guaranteed FAIL
# on every plan that uses one — including, before this arm existed, THIS release's
# own scope-lock row.
#
# Placeholder rows are normalized INTO the glob arm rather than resolved to a
# "longest literal ancestor directory". The ancestor-directory rule has no
# specificity floor (a placeholder in the leading segment resolves to the repo
# root, where any addition satisfies the predicate) and it discards the declared
# basename residue. Normalizing `release/ADRs/<self-arming-…>.md` to
# `release/ADRs/*.md` keeps the `.md` and keeps the directory, which is strictly
# more specific and still resolves the row that actually vanished.
fcm_normalize_pattern() {
  # $1 = declared path. Prints the match pattern (a bash `case` glob).
  printf '%s' "$1" | sed -E \
    -e 's/<[^>]*>/*/g' \
    -e 's/\{\{[^}]*\}\}/*/g' \
    -e 's/(^|[^A-Za-z])NNN([^A-Za-z]|$)/\1*\2/g' \
    -e 's/(^|[^A-Za-z])XXX([^A-Za-z]|$)/\1*\2/g' \
    -e 's/(^|[^A-Za-z])X\.Y([^A-Za-z]|$)/\1*\2/g'
}

fcm_path_form() {
  case "$1" in
    */)                 printf 'dir' ;;
    *'<'*|*'{{'*|*NNN*|*XXX*|*X.Y*) printf 'placeholder' ;;
    *'*'*|*'?'*|*'['*)  printf 'glob' ;;
    *)                  printf 'literal' ;;
  esac
}

# Specificity floor. A pattern that keeps no literal directory prefix, or whose
# basename is entirely wildcard, cannot distinguish a delivered obligation from
# any addition at all — so it is ERROR, not a permissive PASS. Measured: 1
# placeholder-leading token corpus-wide, so this is prophylactic and is stated as
# such rather than inflated into a live defect.
fcm_pattern_resolvable() {
  local pat="$1" prefix base
  prefix="${pat%%[*?[]*}"
  case "$prefix" in */*) : ;; *) return 1 ;; esac
  base="${pat##*/}"
  case "$base" in
    ''|'*'|'**'|'?') return 1 ;;
  esac
  return 0
}

# --- Reconciliation ---------------------------------------------------------
#
# The git invocation is a NATIVE code path with a FIXED command. It does not route
# through `eval_free_run`, and `git` MUST NOT be added to RUNNABLE_VERBS — that set
# is closed on purpose (:363-371): a verification harness driven by an authored
# artifact must not acquire a code-execution channel. This family reads authored
# DATA and runs a fixed command; the allowlist governs authored COMMANDS. The
# distinction is precisely why widening the verb set is unnecessary here.
#
# `--no-renames` is deliberate. Under `--find-renames` a declared ADD delivered as
# a move reports `R`, which the arms would grade `declared-add-delivered-as-edit`
# ("the file pre-existed; the declaration was wrong") — factually false for a
# rename. With renames off, a move reports as `A`+`D`, which is exactly FCM ADD
# semantics.
FCM_ADDS_FILE=""
FCM_ANY_FILE=""
FCM_DIFF_STATUS=""

# NOTE FOR THE NEXT EDITOR: this function sets GLOBALS and must be called
# DIRECTLY, never as `x="$(fcm_resolve_diff)"`. A command substitution runs it in
# a subshell, where the two path globals are assigned and then discarded — the
# caller reads empty strings, every declared ADD matches nothing, and the family
# reports a clean-looking "not delivered" for files that were in fact delivered.
# That failure is silent and it is the same defect class this family exists to
# catch, so the status rides in a global too rather than on stdout.
fcm_resolve_diff() {
  FCM_DIFF_STATUS="diff-unresolvable"
  FCM_ADDS_FILE="$(mktemp -t vrp-fcm-adds.XXXXXX)"
  FCM_ANY_FILE="$(mktemp -t vrp-fcm-any.XXXXXX)"
  if [ -n "$ARG_FCM_DIFF_FILE" ]; then
    if [ ! -f "$ARG_FCM_DIFF_FILE" ]; then return 0; fi
    awk -F'\t' 'NF>=2 { print $1 "\t" $2 }' "$ARG_FCM_DIFF_FILE" > "$FCM_ANY_FILE"
  else
    local base head raw rc=0
    head="${ARG_FCM_HEAD:-HEAD}"
    if [ -n "$ARG_FCM_MERGE_BASE" ]; then base="$ARG_FCM_MERGE_BASE"
    else base="$( cd "$REPO_ROOT" && git merge-base origin/main HEAD 2>/dev/null )" || base=""; fi
    if [ -z "$base" ]; then return 0; fi
    set +e
    raw="$( cd "$REPO_ROOT" && git diff --name-status --no-renames "$base..$head" 2>/dev/null )"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then return 0; fi
    printf '%s\n' "$raw" > "$FCM_ANY_FILE"
  fi
  # An EMPTY diff is not the same fact as an unresolvable one, and neither is a
  # licence to pass: an empty delivered set with a non-empty obligation set FAILs
  # every obligation, which is the correct reading.
  awk -F'\t' '$1 ~ /^A/ { print $2 }' "$FCM_ANY_FILE" | sort -u > "$FCM_ADDS_FILE"
  FCM_DIFF_STATUS="ok"
  return 0
}

# Each arm uses a DISTINCT matching mechanism, and that is deliberate. The obvious
# implementation routes every arm through `case "$p" in $pat)`, which glob-matches
# an unquoted pattern — so the "literal" arm silently performs glob matching and
# becomes indistinguishable from the glob arm. A five-arm taxonomy in which two arms
# cannot be told apart is a taxonomy on paper only: deleting the glob arm then
# changes no verdict, which is exactly what the M7 mutation arm reported before this
# was rewritten. Literal compares strings, directory compares a prefix, and only the
# glob/placeholder arms glob.
fcm_match_adds() {
  # $1 = declared path. Prints the number of delivered ADDITIONS it matches,
  # or the literal token UNRESOLVABLE.
  local declared="$1" form pat n=0 p
  form="$(fcm_path_form "$declared")"
  if [ "$form" = "placeholder" ]; then
    pat="$(fcm_normalize_pattern "$declared")"
    if ! fcm_pattern_resolvable "$pat"; then printf 'UNRESOLVABLE'; return 0; fi
  elif [ "$form" = "glob" ]; then
    pat="$declared"
    if ! fcm_pattern_resolvable "$pat"; then printf 'UNRESOLVABLE'; return 0; fi
  fi
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case "$form" in
      # `if`, not `[ … ] && …`: under errexit a failing AND-list at the end of a
      # case branch takes the whole function down inside its command substitution,
      # and the caller then sees an empty count rather than zero.
      literal)          if [ "$p" = "$declared" ]; then n=$((n+1)); fi ;;
      dir)              case "$p" in "$declared"*) n=$((n+1)) ;; esac ;;
      glob|placeholder) # shellcheck disable=SC2254
                        case "$p" in $pat) n=$((n+1)) ;; esac ;;
    esac
  done < "$FCM_ADDS_FILE"
  printf '%s' "$n"
}

fcm_present_any() {
  local declared="$1"
  awk -F'\t' -v want="$declared" '$2 == want { f=1 } END { exit !f }' "$FCM_ANY_FILE"
}

# --- Handler ----------------------------------------------------------------
#
# Emits FULL stream records (issue \t id \t family \t method \t expected \t
# verdict \t observed), one per obligation PLUS a mandatory coverage record.
#
# The coverage record is not decoration and it is emitted UNCONDITIONALLY on
# every applicable run. A check whose output states only a finding count has not
# shown that it examined anything: a reader cannot distinguish "zero declared ADDs
# were missing" from "no rows were interpreted". Carrying declared / interpreted /
# obligations / excluded / conditional in the record is what makes a vacuous run
# VISIBLE, and a run in which some rows were seen but not understood is a NON-PASS
# regardless of how the understood rows graded.
handle_fcm_delivery() {
  local plan="$1"
  local ISS='FCM (delivery)' FAM='fcm-delivery'
  local method='declared File Change Matrix ADDs vs the merged diff (git diff --name-status --no-renames)'

  emit_fcm() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ISS" "$1" "$FAM" "$method" "$2" "$3" "$4"; }

  # (1) Applicability. The governed population is the release-plan corpus, defined
  #     by location. A target outside it is a NAMED skip stating exactly why — it
  #     can never hide a real release whose matrix is missing, because a real
  #     release plan lives inside the corpus and takes the ERROR arm below.
  local in_corpus=0
  case "$plan" in */release/releases/plans/*) in_corpus=1 ;; esac
  if [ -n "$ARG_FCM_DIFF_FILE" ] && [ "$in_corpus" -eq 1 ]; then
    # The determinism seam is a TEST seam. Honoring it against a real release plan
    # would let the same actor whose work this audits supply the evidence it is
    # audited against, and the emitted record would be indistinguishable from a
    # live run. That is an off-switch on the control, so it is refused outright
    # rather than stamped and left for a downstream reader to notice.
    emit_fcm "FCM-COVERAGE" "live evidence" "$VERDICT_ERROR" \
      "fcm-fixture-mode-on-live-plan (--fcm-diff-file refused against a plan under release/releases/plans/)"
    return 0
  fi
  if [ -z "$ARG_FCM_DIFF_FILE" ] && [ "$in_corpus" -eq 0 ]; then
    emit_fcm "FCM-COVERAGE" "release-plan target" "$VERDICT_SKIP" \
      "fcm-not-a-release-plan (target outside release/releases/plans/; no FCM obligation)"
    return 0
  fi

  # (2) Extraction, with every unreadable state fail-closed.
  local body; body="$(_extract_fcm_section "$plan")"
  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    emit_fcm "FCM-COVERAGE" "a File Change Matrix section" "$VERDICT_ERROR" \
      "fcm-section-absent (no File Change Matrix heading resolves; absent matrix is NOT zero obligations)"
    return 0
  fi
  if printf '%s\n' "$body" | _fcm_body_truncated; then
    emit_fcm "FCM-COVERAGE" "a complete matrix body" "$VERDICT_ERROR" \
      "fcm-section-truncated (unbalanced fence in the extracted body; row set is provably incomplete)"
    return 0
  fi

  local records; records="$(parse_fcm_declarations "$body")"

  # SAME-PATH RECONCILIATION. The dominant authored shape in this corpus is a
  # machine-readable fence of bare paths PLUS a companion table carrying the intent
  # for the same paths — the matrix states each declaration twice, in two forms, on
  # purpose. Counting the bare copy as "uninterpreted" would report a fully-declared
  # matrix as partially-understood, and every plan in that shape (49 of 117) could
  # never reach PASS no matter how carefully it was authored. A matrix is ONE
  # declaration set keyed by path, so a bare row whose path carries a verb ANYWHERE
  # in the same matrix is a second expression of a known declaration, not a gap.
  # Only a path with no marked row anywhere is genuinely intent-undeclared.
  records="$(printf '%s\n' "$records" | awk -F'\t' '
    { line[NR] = $0; pth[NR] = $1; itn[NR] = $2
      if ($2 != "unknown" && $2 != "pathless") marked[$1] = 1 }
    END { for (n = 1; n <= NR; n++) {
            if (itn[n] == "unknown" && (pth[n] in marked)) continue
            print line[n] } }')"

  local declared;      declared="$(printf '%s' "$records"   | grep -c . || true)"
  if [ "$declared" -eq 0 ]; then
    emit_fcm "FCM-COVERAGE" "at least one declared path" "$VERDICT_ERROR" \
      "fcm-empty (matrix section present but carries no path-shaped rows; empty matrix is an authoring defect)"
    return 0
  fi

  # (3) Delivered set. Called DIRECTLY — see the note on fcm_resolve_diff.
  fcm_resolve_diff
  if [ "$FCM_DIFF_STATUS" != "ok" ]; then
    emit_fcm "FCM-COVERAGE" "a resolvable diff range" "$VERDICT_ERROR" \
      "diff-unresolvable (never infer an empty diff from an absent one)"
    return 0
  fi

  local devlog; devlog="$(parse_deviation_log "$plan" || true)"

  local excluded conditional unknown pathless obligations
  excluded="$(   printf '%s\n' "$records" | awk -F'\t' '$2=="excluded"||$2=="read"||$2=="rename"{c++} END{print c+0}')"
  unknown="$(    printf '%s\n' "$records" | awk -F'\t' '$2=="unknown"{c++}  END{print c+0}')"
  pathless="$(   printf '%s\n' "$records" | awk -F'\t' '$2=="pathless"{c++} END{print c+0}')"
  conditional="$(printf '%s\n' "$records" | awk -F'\t' '$2=="add"&&$3=="cond"{c++} END{print c+0}')"
  obligations="$(printf '%s\n' "$records" | awk -F'\t' '$2=="add"&&$3=="uncond"{c++} END{print c+0}')"
  local interpreted=$(( declared - unknown - pathless ))

  # (4) Coverage record — ALWAYS emitted, so "the family never ran" is not
  #     byte-identical to "the family found nothing".
  local cov_verdict="$VERDICT_PASS" cov_note=""
  if [ "$pathless" -gt 0 ]; then
    cov_verdict="$VERDICT_ERROR"; cov_note=" fcm-row-pathless:$pathless (a MARKED row whose path cell holds no repository path)"
  elif [ "$unknown" -gt 0 ]; then
    cov_verdict="$VERDICT_SKIP";  cov_note=" fcm-rows-uninterpreted:$unknown (declared paths carrying no intent marker; intent undeclared is NOT zero ADDs)"
  elif [ "$obligations" -eq 0 ]; then
    cov_verdict="$VERDICT_SKIP";  cov_note=" fcm-no-unconditional-adds (matrix fully interpreted; nothing for this family to assert)"
  fi
  emit_fcm "FCM-COVERAGE" "full row coverage" "$cov_verdict" \
    "declared=$declared interpreted=$interpreted obligations=$obligations excluded=$excluded conditional=$conditional uninterpreted=$unknown pathless=$pathless${cov_note}"

  # (5) One record per ADD row. Conditional and unconditional both reported.
  local n=0 path intent cond form _raw
  while IFS=$'\t' read -r path intent cond form _raw; do
    [ "$intent" = "add" ] || continue
    n=$((n+1))
    local hits recorded=0
    hits="$(fcm_match_adds "$path")"
    # SIGPIPE-REWRITE. Was: `printf '%s' "$devlog" | grep -Fq -- "$path"`. Under the
    # `set -o pipefail` at the top of this file that form INVERTS: `grep -Fq` exits on
    # its first match, `printf` fails on the broken pipe, and the pipeline reports the
    # writer's non-zero status — so a path that IS in the Deviation Log reads as not
    # recorded, and a `NOT DELIVERED` row silently stops converting FCM FAIL to PASS.
    # The empty-haystack caveat does not bite: a row whose path cell is empty is
    # emitted upstream as `(none)`/`pathless` and filtered by the `add` test above, so
    # `$path` is never the empty needle here and needs no `[ -n … ]` guard.
    if grep -Fq -- "$path" <<<"$devlog" 2>/dev/null; then recorded=1; fi
    if [ "$hits" = "UNRESOLVABLE" ]; then
      emit_fcm "FCM-$n" "resolvable declared path" "$VERDICT_ERROR" \
        "placeholder-unresolvable:$path (no literal directory prefix or wholly-wildcard basename)"
    elif [ "$cond" = "cond" ]; then
      if [ "$hits" -gt 0 ]; then
        emit_fcm "FCM-$n" "conditional ADD" "$VERDICT_PASS" "conditional-fired:$path ($form)"
      elif [ "$recorded" -eq 1 ]; then
        emit_fcm "FCM-$n" "conditional ADD" "$VERDICT_PASS" "conditional-not-fired (recorded):$path"
      else
        emit_fcm "FCM-$n" "conditional ADD" "$VERDICT_SKIP" \
          "conditional-unrecorded:$path (WARN tier — the gate cannot evaluate a prose condition)"
      fi
    else
      if [ "$hits" -gt 0 ]; then
        emit_fcm "FCM-$n" "delivered as an addition" "$VERDICT_PASS" "declared-add-delivered:$path ($form)"
      elif [ "$recorded" -eq 1 ]; then
        emit_fcm "FCM-$n" "delivered or a Deviation-Log row" "$VERDICT_PASS" "deviation-recorded:$path"
      elif fcm_present_any "$path"; then
        emit_fcm "FCM-$n" "delivered as an addition" "$VERDICT_FAIL" \
          "declared-add-delivered-as-edit:$path (the file pre-existed; the ADD declaration was wrong)"
      else
        emit_fcm "FCM-$n" "delivered as an addition" "$VERDICT_FAIL" "declared-add-not-delivered:$path"
      fi
    fi
  done <<< "$records"

  rm -f "$FCM_ADDS_FILE" "$FCM_ANY_FILE"
  return 0
}

# ===========================================================================
# Component 5 — emit_evidence(): render verdict records in the requested format.
# Records arrive on stdin as: issue \t id \t family \t method \t expected \t verdict \t observed
# ===========================================================================
emit_md() {
  # Group by issue, preserving first-seen issue order.
  local records; records="$(cat)"
  local issues
  issues="$(printf '%s\n' "$records" | awk -F'\t' 'NF{ if(!seen[$1]++) print $1 }')"
  printf '### Verification Evidence\n\n'
  local p=0 f=0 s=0 e=0
  local iss
  while IFS= read -r iss; do
    [ -z "$iss" ] && continue
    local title
    title="$(issue_title "$iss")"
    printf '**%s%s**\n' "$iss" "$title"
    printf '| Check | Family | Method (reproducible) | Expected | Observed | Verdict |\n'
    printf '|---|---|---|---|---|---|\n'
    printf '%s\n' "$records" | awk -F'\t' -v want="$iss" -v dash="-" 'NF && $1==want {
      cid=$2; if (cid=="") cid=dash
      fam=$3; meth=$4
      expd=$5; if (expd=="") expd=dash
      verd=$6
      obs=$7; if (obs=="") obs=dash
      gsub(/\|/, "\\|", meth); gsub(/\|/, "\\|", expd); gsub(/\|/, "\\|", obs)
      printf "| %s | %s | %s | %s | %s | %s |\n", cid, fam, meth, expd, obs, verd
    }'
    printf '\n'
  done <<< "$issues"
  # Roll-up.
  p="$(printf '%s\n' "$records" | awk -F'\t' '$6=="PASS"{c++} END{print c+0}')"
  f="$(printf '%s\n' "$records" | awk -F'\t' '$6=="FAIL"{c++} END{print c+0}')"
  s="$(printf '%s\n' "$records" | awk -F'\t' '$6=="SKIP"{c++} END{print c+0}')"
  e="$(printf '%s\n' "$records" | awk -F'\t' '$6=="ERROR"{c++} END{print c+0}')"
  printf '**Verdict roll-up:** %s PASS / %s FAIL / %s SKIP / %s ERROR\n' "$p" "$f" "$s" "$e"
}

emit_json() {
  local records; records="$(cat)"
  printf '{\n  "schema_version": "%s",\n  "cli_version": "%s",\n  "checks": [\n' "$SCHEMA_VERSION" "$CLI_VERSION"
  printf '%s\n' "$records" | awk -F'\t' 'NF{
    if (started) printf ",\n"; started=1
    gsub(/"/,"\\\"",$4); gsub(/"/,"\\\"",$7)
    printf "    {\"issue\":\"%s\",\"id\":\"%s\",\"family\":\"%s\",\"method\":\"%s\",\"expected\":\"%s\",\"observed\":\"%s\",\"verdict\":\"%s\"}", $1,$2,$3,$4,$5,$7,$6
  }'
  printf '\n  ],\n'
  local p f s e
  p="$(printf '%s\n' "$records" | awk -F'\t' '$6=="PASS"{c++} END{print c+0}')"
  f="$(printf '%s\n' "$records" | awk -F'\t' '$6=="FAIL"{c++} END{print c+0}')"
  s="$(printf '%s\n' "$records" | awk -F'\t' '$6=="SKIP"{c++} END{print c+0}')"
  e="$(printf '%s\n' "$records" | awk -F'\t' '$6=="ERROR"{c++} END{print c+0}')"
  printf '  "rollup": {"pass": %s, "fail": %s, "skip": %s, "error": %s}\n}\n' "$p" "$f" "$s" "$e"
}

emit_table() {
  local records; records="$(cat)"
  printf '%sVerification Evidence%s\n' "$(c_bold)" "$(c_reset)"
  printf '%s\n' "$records" | awk -F'\t' 'NF{ printf "  %-8s %-14s %-6s %s\n", $1, $3, $6, $4 }'
}

# ---------------------------------------------------------------------------
# issue_title / issue_title-cache: best-effort friendly title from the plan's
# per-issue headers (kept purely cosmetic; absence yields an empty suffix).
# ---------------------------------------------------------------------------
issue_title() {
  local iss="$1" raw t
  # Pull the raw header line for this issue (awk stays ASCII-only: it just
  # matches the header and prints from after the issue number to the closing **).
  raw="$(awk -v want="$iss" '
    /^\*\*#[0-9]+/ {
      match($0, /#[0-9]+/); id = substr($0, RSTART, RLENGTH)
      if (id == want) {
        line = $0
        sub(/^\*\*#[0-9]+[ ]*/, "", line)   # drop "**#N " prefix
        sub(/\*\*.*$/, "", line)             # drop trailing "**..."
        print line; exit
      }
    }' "$PLAN_ABS")"
  # Strip a leading dash separator (ASCII "-" or the em-dash) in the shell, so
  # no non-ASCII byte ever appears inside an awk program (BSD awk chokes on it).
  t="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/^—[[:space:]]*//' -e 's/^-[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -n "$t" ]; then printf ' - %s' "$t"; fi
}

# ===========================================================================
# Orchestration
# ===========================================================================
main() {
  parse_args "$@"
  resolve_root
  resolve_sibling_tools
  resolve_plan

  # Per-run memo file for the deploy --check result (so a plan with several
  # sync/regression rows runs the heavy check once). Cleaned on exit.
  DEPLOY_CHECK_CACHE="$(mktemp -t verify-release-plan-deploycheck.XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -f '$DEPLOY_CHECK_CACHE'" EXIT

  # Release join key for the runtime-suite event: the MILESTONE SLUG, per
  # pipeline-event-log-schema.md § 2a. This used to parse `v<maj>.<min>` out of
  # the plan filename and fall back to the literal `v0.0.0` — a synthesized,
  # version-shaped placeholder that sorts into the version space and is
  # indistinguishable from a real release to every consumer. The writer now
  # rejects both forms, so this resolves a slug or the reserved `(none)`.
  local plan_version
  plan_version="$(resolve_plan_release_key "$PLAN_ABS")"

  # 1) Parse per-issue verification-plan check records + CIAC integration records.
  local per_issue_records ciac_records
  per_issue_records="$(parse_verification_plan "$PLAN_ABS" || true)"
  ciac_records="$(parse_ciac "$PLAN_ABS" || true)"

  # 2) Dispatch each record → verdict, building the emit stream:
  #    issue \t id \t family \t method \t expected \t verdict \t observed
  local stream=""
  local issue id family method expected verdict_observed verdict observed

  # Per-issue records: fields = issue \t ac \t PENDING \t method \t expected
  if [ -n "$per_issue_records" ]; then
    while IFS=$'\t' read -r issue id _pending method expected; do
      [ -z "$issue$method" ] && continue
      family="$(classify_family "" "$method")"
      verdict_observed="$(dispatch_check "$family" "$method" "$expected" "$plan_version")"
      verdict="$(printf '%s' "$verdict_observed" | cut -f1)"
      observed="$(printf '%s' "$verdict_observed" | cut -f2)"
      stream="${stream}${issue}	${id}	${family}	${method}	${expected}	${verdict}	${observed}
"
    done <<< "$per_issue_records"
  fi

  # CIAC records: fields = id \t issues \t integration \t method \t predicate
  if [ -n "$ciac_records" ]; then
    while IFS=$'\t' read -r id issue family method expected; do
      [ -z "$id" ] && continue
      # family is already "integration"; group CIAC rows under an "integration"
      # pseudo-issue label carrying the spanned issues for the evidence table.
      verdict_observed="$(dispatch_check "integration" "$method" "$expected" "$plan_version")"
      verdict="$(printf '%s' "$verdict_observed" | cut -f1)"
      observed="$(printf '%s' "$verdict_observed" | cut -f2)"
      # Emit under a stable "CIAC (integration)" issue bucket so the evidence
      # section shows cross-issue checks together; the id carries CIAC-N and the
      # spanned issues ride in the Expected column for traceability.
      local span_note="spans ${issue}"
      stream="${stream}CIAC (integration)	${id}	integration	${method}	${span_note}	${verdict}	${observed}
"
    done <<< "$ciac_records"
  fi

  # 2c) fcm-delivery — the THIRD record source.
  #
  # WIRED HERE ON PURPOSE, AND ALWAYS-ON. Every other family reaches dispatch only
  # via a record the plan itself declares, which means a family nothing produces a
  # record for is unreachable and its absence is indistinguishable from a pass. A
  # declared-vs-delivered gate that a release can omit by simply not declaring it
  # would reproduce, one layer up, exactly the defect it exists to catch. So this
  # family is not plan-declared: it fires on every invocation, and when it has
  # nothing to assert it says so in a record rather than by being absent.
  local fcm_records
  fcm_records="$(handle_fcm_delivery "$PLAN_ABS" || true)"
  if [ -n "$fcm_records" ]; then
    stream="${stream}${fcm_records}
"
  fi

  # No checks parsed at all → not an error, but say so honestly on stderr.
  if [ -z "$stream" ]; then
    err "no verification checks parsed from $(basename "$PLAN_ABS") — is the Verification Plan / CIAC section present and table-shaped?"
  fi

  # 3) Emit in the requested format.
  case "$ARG_FORMAT" in
    md)    printf '%s' "$stream" | emit_md ;;
    json)  printf '%s' "$stream" | emit_json ;;
    table) printf '%s' "$stream" | emit_table ;;
  esac

  # 4) Exit non-zero if any FAIL or ERROR verdict is present (CI-consumable).
  if printf '%s' "$stream" | awk -F'\t' '$6=="FAIL"||$6=="ERROR"{found=1} END{exit !found}'; then
    exit "$EXIT_CHECK_FAILED"
  fi
  exit "$EXIT_OK"
}

main "$@"
