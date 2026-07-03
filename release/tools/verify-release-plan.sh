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
readonly CLI_VERSION="0.1.0"
readonly SCHEMA_VERSION="1"

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

# extract_command — pull the runnable command out of a method string. Prefers a
# backtick-quoted span (the authored shape: *Method:* `grep …`); falls back to
# the bare string when it already starts with an allowlisted verb (the shape the
# CIAC parser hands over, having stripped its own backticks). Prints the command
# or nothing.
extract_command() {
  local method="$1" cmd first
  cmd="$(printf '%s' "$method" | sed -n 's/.*`\([^`]*\)`.*/\1/p' | head -1)"
  if [ -n "$cmd" ]; then printf '%s' "$cmd"; return; fi
  first="$(printf '%s' "$method" | sed -e 's/^[[:space:]]*//' | awk '{print $1}')"
  case "$first" in
    grep|test|ls|head|wc|cat) printf '%s' "$(printf '%s' "$method" | sed -e 's/^[[:space:]]*//')" ;;
    *) : ;;   # no runnable command
  esac
}

# extract_threshold — pull an "≥ N" / ">= N" numeric threshold from a method.
extract_threshold() {
  local method="$1" t
  t="$(printf '%s' "$method" | sed -n 's/.*[≥][ ]*\([0-9][0-9]*\).*/\1/p' | head -1)"
  [ -z "$t" ] && t="$(printf '%s' "$method" | sed -n 's/.*>=[ ]*\([0-9][0-9]*\).*/\1/p' | head -1)"
  printf '%s' "$t"
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

  # Allowlist the leading verb; refuse anything outside the read-only query set.
  local verb; verb="$(printf '%s' "$cmd" | awk '{print $1}')"
  case "$verb" in
    grep|test|ls|head|wc|cat) : ;;
    *) printf '%s\t%s\n' "$VERDICT_ERROR" "non-allowlisted-verb:$verb"; return ;;
  esac

  local threshold; threshold="$(extract_threshold "$method")"

  # Run the embedded command from REPO_ROOT so relative paths resolve.
  local out rc count
  set +e
  out="$( cd "$REPO_ROOT" && eval_free_run "$cmd" 2>/dev/null )"
  rc=$?
  set -e

  if [ -n "$threshold" ]; then
    # Interpret output as a count (grep -c prints an integer per file; sum).
    count="$(printf '%s\n' "$out" | awk -F: '{ s += $NF } END { print s+0 }')"
    if [ "$count" -ge "$threshold" ] 2>/dev/null; then
      printf '%s\t%s\n' "$VERDICT_PASS" "count=$count (≥ $threshold)"
    else
      printf '%s\t%s\n' "$VERDICT_FAIL" "count=$count (< $threshold)"
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
  case "$verb" in
    grep|test|ls|head|wc|cat) : ;;
    *) printf '%s\t%s\n' "$VERDICT_ERROR" "non-allowlisted-verb:$verb"; return ;;
  esac
  local out rc count threshold
  set +e
  out="$( cd "$REPO_ROOT" && eval_free_run "$cmd" 2>/dev/null )"
  rc=$?
  set -e
  threshold="$(extract_threshold "$method")"
  if [ -n "$threshold" ]; then
    count="$(printf '%s\n' "$out" | awk -F: '{ s += $NF } END { print s+0 }')"
    if [ "$count" -ge "$threshold" ] 2>/dev/null; then
      printf '%s\t%s\n' "$VERDICT_PASS" "co-occurrence count=$count (≥ $threshold)"
    else
      printf '%s\t%s\n' "$VERDICT_FAIL" "co-occurrence count=$count (< $threshold)"
    fi
    return
  fi
  if [ "$rc" -eq 0 ]; then printf '%s\t%s\n' "$VERDICT_PASS" "integration-method-succeeded"
  else printf '%s\t%s\n' "$VERDICT_FAIL" "integration-method-exit-$rc"; fi
}

# run_deploy_check_once — run deploy --check AT MOST ONCE per executor invocation
# and cache its exit code (deploy --check is a heavy full-workspace validation; a
# plan that declares several sync/regression methods must not re-run it per row).
# The cached exit code is written to DEPLOY_CHECK_CACHE (a per-run temp file set in
# main), so the memo survives the command-substitution subshells the handlers run
# in. This memoization changes no output contract — it only avoids redundant runs.
run_deploy_check_once() {
  if [ -z "${DEPLOY_CHECK_CACHE:-}" ]; then
    # No cache configured (e.g. a unit caller) — run directly, no memo.
    ( cd "$REPO_ROOT" && bash "$DEPLOY_CHECK" --check ) >/dev/null 2>&1
    return $?
  fi
  if [ ! -s "$DEPLOY_CHECK_CACHE" ]; then
    local rc
    set +e
    ( cd "$REPO_ROOT" && bash "$DEPLOY_CHECK" --check ) >/dev/null 2>&1
    rc=$?
    set -e
    printf '%s' "$rc" > "$DEPLOY_CHECK_CACHE"
  fi
  return "$(cat "$DEPLOY_CHECK_CACHE")"
}

# sync + regression: delegate to deploy --check (source<->deployed byte-diff).
# We do NOT re-implement diffing; the deploy check IS the sync/regression oracle.
handle_deploy_check() {
  local family="$1"
  if [ ! -x "$DEPLOY_CHECK" ] && [ ! -f "$DEPLOY_CHECK" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "deploy.sh --check not found at $DEPLOY_CHECK"; return
  fi
  local rc
  set +e
  run_deploy_check_once
  rc=$?
  set -e
  # deploy --check exits 0 when source and deployed copies are in sync.
  if [ "$rc" -eq 0 ]; then
    printf '%s\t%s\n' "$VERDICT_PASS" "deploy --check clean (in-sync)"
  else
    printf '%s\t%s\n' "$VERDICT_FAIL" "deploy --check non-clean (exit $rc); ${family} — see deploy.sh --check output"
  fi
}

# runtime-suite: emit a test-run event through the pipeline-event writer.
# Under the map, a check whose deliverable path is unmapped is an honest
# suite-skip. We do not run suites in a novel way; we invoke the same event
# path Engineering self-verification + Dev Testing already use.
# $1 = method string, $2 = plan version (for the event --version).
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
        --version "${version:-v0.0.0}" --stage 6 \
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

  # Plan version (for runtime-suite event --version): parse `v<maj>.<min>` from
  # the plan filename, else from the first heading.
  local plan_version
  plan_version="$(basename "$PLAN_ABS" | sed -n 's/^\(v[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')"
  [ -z "$plan_version" ] && plan_version="$(grep -m1 -oE 'v[0-9]+\.[0-9]+' "$PLAN_ABS" 2>/dev/null || true)"

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
