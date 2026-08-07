#!/usr/bin/env bash
set -euo pipefail
# blast-radius.sh — File reference fan-out tracer for Stage 5 Solutioning
# Source: Stage 5 Solutioning tooling.
# See release/references/protocols/blast-radius-protocol.md for usage.

# ---------------------------------------------------------------------------
# Version metadata (the contract is the schema, not the implementation)
# ---------------------------------------------------------------------------
readonly CLI_VERSION="0.1.0"
readonly SCHEMA_VERSION="1"

# ---------------------------------------------------------------------------
# Pinned PATH for tool discipline (per bypass-mode-readiness.md posture)
# ---------------------------------------------------------------------------
PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"
# Deterministic byte-order collation for every sort in this script (#675). A single
# script-level export is inherited by every subprocess sort — covering the bare sorts
# (:392 build_scan_list, :624 compute_second_order) and rendering the inline #92 pins
# (:551, :702) redundant — so no locale-exposed sort can crash on a non-UTF-8 byte under
# a UTF-8 LANG. Collation-only: it changes tie-order among equal keys, never which rows
# survive or their counts.
export LC_ALL=C

# ---------------------------------------------------------------------------
# Shared schema-v1 emitter (the single home of the output contract). This script
# owns doc-corpus fan-out DISCOVERY; the schema-v1 EMIT (the first_order[] object
# roll-up + the top-level envelope) lives in the sourced library so the doc tracer
# and the domain tracer emit one identical contract. See ADR-068. Sourced relative
# to this script so it resolves under any checkout / worktree.
# ---------------------------------------------------------------------------
_BLAST_RADIUS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd -P)"
# shellcheck source=lib/schema-v1-emit.sh
. "${_BLAST_RADIUS_LIB_DIR}/schema-v1-emit.sh"

# ---------------------------------------------------------------------------
# Exit codes
# ---------------------------------------------------------------------------
readonly EXIT_OK=0
readonly EXIT_INTERNAL=1
readonly EXIT_BAD_TARGET=2
readonly EXIT_EXCLUDED_TARGET=3
readonly EXIT_MISSING_DEP=4
# 5 is NOT free. domain-blast-radius.sh already owns EXIT_SCANNER_NOT_IMPLEMENTED=5, and
# both tracers emit one shared schema-v1 contract — so a consumer switching on exit code
# must be able to tell "the domain scanner is unavailable" apart from "your result was
# truncated". 6 is the next free code across that two-tool family.
readonly EXIT_PARTIAL=6

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
HARD_CAP_DEPTH=4
DEFAULT_DEPTH=2
# Deterministic second-order fan-out cap. 300 sits above the observed corpus maximum
# first-order fan-out (246), so it cannot fire on today's corpus and changes no output
# today; it converts future corpus growth from an unbounded run into a marked partial.
# Deliberately NOT a wall-clock timeout: a timeout makes the same input produce different
# output on a loaded machine, and this tool's output is a design artifact consumed by
# Stage-8 verification, where non-reproducible impact analysis is disqualifying. A cap on
# a sorted list is reproducible for a given input; a stopwatch is not. 0 = unlimited.
DEFAULT_MAX_EXPAND=300

# ---------------------------------------------------------------------------
# Argument parsing state
# ---------------------------------------------------------------------------
ARG_FORMAT=""
ARG_DEPTH="$DEFAULT_DEPTH"
ARG_INCLUDE_MIRRORS=0
ARG_ROOT=""
ARG_NO_COLOR=0
declare -a ARG_EXCLUDE_ADDITIONAL=()
ARG_TARGET=""
ARG_MODE=""   # "" = default doc-reference tracer; "structural" = path-move consumer sweep (#3120)
ARG_MAX_EXPAND="$DEFAULT_MAX_EXPAND"

# ---------------------------------------------------------------------------
# Partial-result state. Set ONLY by compute_second_order when the fan-out cap fires.
# When set, the run emits an explicit marker (JSON .partial / .partial_reason /
# .stats.partial, and a visible line in the table and md presenters) AND exits
# EXIT_PARTIAL — so a truncated run cannot be read downstream as "no blast radius".
# ---------------------------------------------------------------------------
PARTIAL=0
PARTIAL_REASON=""

# Self-test fixture root. Script-scope on purpose: the EXIT trap that removes it fires
# AFTER run_self_test has returned, so a `local` would already be out of scope and
# `set -u` would turn the cleanup into an unbound-variable error — which would make a
# 13/13 PASS suite still exit non-zero.
SELFTEST_TMPDIR=""

# ---------------------------------------------------------------------------
# Default exclusions (hardcoded; --exclude adds to these)
# ---------------------------------------------------------------------------
declare -a DEFAULT_EXCLUSIONS=(
  ".git/"
  "pmo-platform/packages/"
  "projects/"
  "node_modules/"
  ".claude/skills/"
  ".claude/worktrees/"     # worktree copies are duplicate corpora, not referrers (#3300; mirrors domain-blast-radius.sh)
)

# Default scanned file types
declare -a SCANNED_TYPES=(
  "md"
  "sh"
  "json"
  "yml"
  "yaml"
  "toml"
)

# ---------------------------------------------------------------------------
# Color helpers (matches account-switcher.sh convention)
# ---------------------------------------------------------------------------
use_color() {
  if [ "$ARG_NO_COLOR" = "1" ]; then
    return 1
  fi
  [ -t 1 ] || return 1
  return 0
}

c_bold()  { if use_color; then printf '\033[1m'; fi; }
c_dim()   { if use_color; then printf '\033[2m'; fi; }
c_red()   { if use_color; then printf '\033[31m'; fi; }
c_green() { if use_color; then printf '\033[32m'; fi; }
c_blue()  { if use_color; then printf '\033[34m'; fi; }
c_reset() { if use_color; then printf '\033[0m'; fi; }

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
err() {
  c_red >&2
  printf 'blast-radius: ERROR: %s\n' "$*" >&2
  c_reset >&2
}

# ---------------------------------------------------------------------------
# Usage banner
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
blast-radius.sh — File reference fan-out tracer for Stage 5 Solutioning

USAGE
  blast-radius.sh [OPTIONS] <target_file>
  blast-radius.sh --mode=structural [OPTIONS] <old_path>

OPTIONS
  --mode=MODE           (default) doc-reference tracer, or 'structural' for the
                        path-move consumer sweep (who hard-codes an OLD path literal?).
                        In structural mode <old_path> is a path STRING to search for —
                        a directory prefix or a single path — and need NOT exist on disk
                        (the whole point: it was moved away). No basename tokenization.
  --format=FORMAT       Output presenter: json | table | md
                        Default: table if stdout is a tty, json otherwise
  --depth=N             Recursion depth for second-order detection (default path only)
                        Default: 2; hard cap: $HARD_CAP_DEPTH
  --max-expand=N        Cap the number of first-order referrers expanded for second-order
                        detection. The first-order list is sorted reference_count DESC,
                        path ASC, so truncation is deterministic and keeps the
                        highest-signal referrers. When the cap fires the run emits an
                        explicit partial-result marker and exits $EXIT_PARTIAL.
                        Default: $DEFAULT_MAX_EXPAND; 0 = unlimited.
  --include-mirrors     Include mirror-pair references in output (filtered by default)
  --root=PATH           Repo root for scanning
                        Default: \$(git rev-parse --show-toplevel)
  --exclude=GLOB        Additional exclusion path-prefix; repeatable
  --no-color            Disable ANSI color in table output
  -h, --help            Show this help and exit
  --version             Show CLI version + schema version and exit
  --self-test           Run the built-in hermetic regression suite and exit

EXIT CODES
  0  Success
  1  Internal error
  2  Bad target (default mode: not a regular file; structural mode: empty/outside-repo old path)
  3  Target is under an exclusion glob (default mode only)
  4  Missing dependency (jq not on PATH)
  6  Partial result: second-order expansion capped by --max-expand. Output IS produced
     and carries .partial = true — it is truncated, NOT "no blast radius".

EXAMPLES
  # Trace what references pipeline/stage-05-solutioning.md (table to terminal)
  blast-radius.sh release/references/pipeline/stage-05-solutioning.md

  # JSON output for downstream consumption
  blast-radius.sh --format=json --depth=1 CLAUDE.md

  # Include mirror-pair references (forensic mode)
  blast-radius.sh --include-mirrors .claude/rules/release-process.md

  # Structural/path-move sweep: who hard-codes the OLD release-notes dir path?
  blast-radius.sh --mode=structural --format=json release/releases/notes

DOCS
  See release/references/protocols/blast-radius-protocol.md (§ 13 for the structural mode)
EOF
}

# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit "$EXIT_OK"
        ;;
      --version)
        printf 'blast-radius %s (schema v%s)\n' "$CLI_VERSION" "$SCHEMA_VERSION"
        exit "$EXIT_OK"
        ;;
      --self-test)
        run_self_test
        exit $?
        ;;
      --format=*)
        ARG_FORMAT="${1#--format=}"
        ;;
      --format)
        shift
        ARG_FORMAT="${1:-}"
        ;;
      --depth=*)
        ARG_DEPTH="${1#--depth=}"
        ;;
      --depth)
        shift
        ARG_DEPTH="${1:-}"
        ;;
      --max-expand=*)
        ARG_MAX_EXPAND="${1#--max-expand=}"
        ;;
      --max-expand)
        shift
        ARG_MAX_EXPAND="${1:-}"
        ;;
      --include-mirrors)
        ARG_INCLUDE_MIRRORS=1
        ;;
      --mode=*)
        ARG_MODE="${1#--mode=}"
        ;;
      --mode)
        shift
        ARG_MODE="${1:-}"
        ;;
      --root=*)
        ARG_ROOT="${1#--root=}"
        ;;
      --root)
        shift
        ARG_ROOT="${1:-}"
        ;;
      --exclude=*)
        ARG_EXCLUDE_ADDITIONAL+=("${1#--exclude=}")
        ;;
      --exclude)
        shift
        ARG_EXCLUDE_ADDITIONAL+=("${1:-}")
        ;;
      --no-color)
        ARG_NO_COLOR=1
        ;;
      --)
        shift
        if [ $# -gt 0 ]; then
          ARG_TARGET="$1"
        fi
        ;;
      -*)
        err "Unknown option: $1"
        usage >&2
        exit "$EXIT_INTERNAL"
        ;;
      *)
        if [ -z "$ARG_TARGET" ]; then
          ARG_TARGET="$1"
        else
          err "Multiple targets specified: '$ARG_TARGET' and '$1' — provide only one"
          exit "$EXIT_INTERNAL"
        fi
        ;;
    esac
    shift
  done

  # Validate target presence
  if [ -z "$ARG_TARGET" ]; then
    err "No target file specified"
    usage >&2
    exit "$EXIT_INTERNAL"
  fi

  # Validate mode (#3120): empty = default doc-reference tracer; structural = path-move sweep.
  case "$ARG_MODE" in
    ""|structural) ;;
    *)
      err "Invalid --mode value: '$ARG_MODE' (must be 'structural', or omitted for the default doc-reference tracer)"
      exit "$EXIT_INTERNAL"
      ;;
  esac

  # Validate depth
  if ! [[ "$ARG_DEPTH" =~ ^[0-9]+$ ]]; then
    err "Invalid --depth value: '$ARG_DEPTH' (must be a non-negative integer)"
    exit "$EXIT_INTERNAL"
  fi
  if [ "$ARG_DEPTH" -gt "$HARD_CAP_DEPTH" ]; then
    err "--depth=$ARG_DEPTH exceeds hard cap $HARD_CAP_DEPTH"
    exit "$EXIT_INTERNAL"
  fi

  # Validate max-expand (non-negative integer; 0 = unlimited)
  if ! [[ "$ARG_MAX_EXPAND" =~ ^[0-9]+$ ]]; then
    err "Invalid --max-expand value: '$ARG_MAX_EXPAND' (must be a non-negative integer; 0 = unlimited)"
    exit "$EXIT_INTERNAL"
  fi

  # Validate format
  if [ -n "$ARG_FORMAT" ]; then
    case "$ARG_FORMAT" in
      json|table|md) ;;
      *)
        err "Invalid --format value: '$ARG_FORMAT' (must be json | table | md)"
        exit "$EXIT_INTERNAL"
        ;;
    esac
  else
    if [ -t 1 ]; then
      ARG_FORMAT="table"
    else
      ARG_FORMAT="json"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
check_deps() {
  if ! command -v jq >/dev/null 2>&1; then
    err "Missing dependency: jq (install via 'brew install jq' or ensure /usr/bin/jq exists)"
    exit "$EXIT_MISSING_DEP"
  fi
}

# ---------------------------------------------------------------------------
# Repo root resolution
# ---------------------------------------------------------------------------
resolve_root() {
  if [ -n "$ARG_ROOT" ]; then
    if [ ! -d "$ARG_ROOT" ]; then
      err "--root path does not exist or is not a directory: $ARG_ROOT"
      exit "$EXIT_INTERNAL"
    fi
    REPO_ROOT="$(cd "$ARG_ROOT" && pwd -P)"
    return
  fi

  if command -v git >/dev/null 2>&1; then
    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
      REPO_ROOT="$git_root"
      return
    fi
  fi

  REPO_ROOT="$(pwd -P)"
}

# ---------------------------------------------------------------------------
# Target resolution: absolute or repo-relative → repo-relative canonical form
# ---------------------------------------------------------------------------
resolve_target() {
  local input="$ARG_TARGET"
  local abs

  # Absolute path
  if [[ "$input" = /* ]]; then
    abs="$input"
  else
    # Try repo-relative first (relative to REPO_ROOT)
    if [ -e "$REPO_ROOT/$input" ]; then
      abs="$REPO_ROOT/$input"
    elif [ -e "$input" ]; then
      # Try cwd-relative
      abs="$(cd "$(dirname "$input")" && pwd -P)/$(basename "$input")"
    else
      err "Target file does not exist: $input"
      exit "$EXIT_BAD_TARGET"
    fi
  fi

  if [ ! -f "$abs" ]; then
    err "Target is not a regular file: $abs"
    exit "$EXIT_BAD_TARGET"
  fi

  # Normalize to repo-relative
  case "$abs" in
    "$REPO_ROOT"/*)
      TARGET_REL="${abs#"$REPO_ROOT"/}"
      ;;
    "$REPO_ROOT")
      err "Target equals repo root: $abs"
      exit "$EXIT_BAD_TARGET"
      ;;
    *)
      err "Target $abs is outside repo root $REPO_ROOT"
      exit "$EXIT_BAD_TARGET"
      ;;
  esac

  # Check target against exclusions
  if path_under_exclusion "$TARGET_REL"; then
    err "Target is under an exclusion: $TARGET_REL"
    exit "$EXIT_EXCLUDED_TARGET"
  fi
}

# ---------------------------------------------------------------------------
# Path-prefix exclusion test (returns 0 if path matches any exclusion)
# ---------------------------------------------------------------------------
path_under_exclusion() {
  local p="$1"
  local prefix
  for prefix in "${DEFAULT_EXCLUSIONS[@]}"; do
    case "$p" in
      "${prefix}"*) return 0 ;;
    esac
  done
  for prefix in "${ARG_EXCLUDE_ADDITIONAL[@]+"${ARG_EXCLUDE_ADDITIONAL[@]}"}"; do
    [ -z "$prefix" ] && continue
    case "$p" in
      "${prefix}"*) return 0 ;;
    esac
  done
  # Filter *.lock at any depth
  case "$p" in
    *.lock) return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Build scan file list (newline-delimited absolute paths)
# Writes to: SCAN_LIST_FILE
# ---------------------------------------------------------------------------
build_scan_list() {
  SCAN_LIST_FILE="$WORK_DIR/scan-list.txt"
  local find_args=( "$REPO_ROOT" )
  find_args+=( -type f )

  # Type filter: -name "*.md" -o -name "*.sh" -o ...
  find_args+=( "(" )
  local first=1 ext
  for ext in "${SCANNED_TYPES[@]}"; do
    if [ "$first" = "1" ]; then
      first=0
      find_args+=( -name "*.${ext}" )
    else
      find_args+=( -o -name "*.${ext}" )
    fi
  done
  find_args+=( ")" )

  # Stream find output, filter via path_under_exclusion in shell loop, write repo-relative
  find "${find_args[@]}" 2>/dev/null \
    | while IFS= read -r abs; do
        local rel="${abs#"$REPO_ROOT"/}"
        if ! path_under_exclusion "$rel"; then
          printf '%s\n' "$rel"
        fi
      done \
    | sort -u > "$SCAN_LIST_FILE"

  TOTAL_FILES_SCANNED=$(wc -l < "$SCAN_LIST_FILE" | tr -d ' ')
}

# ---------------------------------------------------------------------------
# Mirror-pair auto-detection
# Writes mirror partner mapping to MIRROR_MAP_FILE (format: "<a>\t<b>").
#
# Topology source of truth: core/deploy/deploy.sh Check 9 MIRROR_PAIRS. Keep
# this table in sync with that array. Each entry is the repo-relative SOURCE
# path; the second column is its canonical mirror partner.
#
# Reachability note: all mirrors deploy OUTWARD to $HOME/.claude/rules/, which
# is OUTSIDE the scanned REPO_ROOT and therefore never appears as a referrer in
# the scan list. We register those rows so --include-mirrors / filtered_mirrors
# reflect the true topology and TSV rows always name two distinct paths. A row is
# emitted only when its SOURCE exists in REPO_ROOT, so deploy-target-only halves
# never fabricate rows. (The former repo-internal core/governance/OPERATIONS.md
# <-> operations/OPERATIONS.md pair was RETIRED per #2213 — operations/OPERATIONS.md
# is now an SSOT pointer stub, not a byte-identical mirror; its link to the SSOT is
# a REAL edge that must NOT be mirror-suppressed. So in-scan suppression now bites
# nothing.)
# ---------------------------------------------------------------------------
detect_mirror_pairs() {
  MIRROR_MAP_FILE="$WORK_DIR/mirror-pairs.tsv"
  : > "$MIRROR_MAP_FILE"

  # <source-rel>\t<mirror-rel> — mirror of deploy.sh MIRROR_PAIRS (Check 9).
  # release-process.md source is release/governance/ (per #1104 correction).
  local -a pairs=(
    "core/rules/skill-deployment.md	.claude/rules/skill-deployment.md"
    "core/rules/bypass-mode-readiness.md	.claude/rules/bypass-mode-readiness.md"
    "core/rules/harness-deployment.md	.claude/rules/harness-deployment.md"
    "core/rules/doc-link-maintenance.md	.claude/rules/doc-link-maintenance.md"
    "core/rules/operations-bridge.md	.claude/rules/operations-bridge.md"
    "core/rules/git-workflow.md	.claude/rules/git-workflow.md"
    "core/rules/governance-files.md	.claude/rules/governance-files.md"
    "core/rules/decision-time-adherence.md	.claude/rules/decision-time-adherence.md"
    "core/rules/rename-reference-cascade.md	.claude/rules/rename-reference-cascade.md"
    "core/rules/analysis-mandate.md	.claude/rules/analysis-mandate.md"
    "release/governance/release-process.md	.claude/rules/release-process.md"
  )

  local entry src mir
  for entry in "${pairs[@]}"; do
    src="${entry%%$'\t'*}"
    mir="${entry##*$'\t'}"
    # Emit only when the in-repo SOURCE exists; mirror half may live at the
    # deploy target (outside REPO_ROOT) and is recorded for topology fidelity.
    if [ -f "$REPO_ROOT/$src" ]; then
      printf '%s\t%s\n' "$src" "$mir" >> "$MIRROR_MAP_FILE"
    fi
  done
}

# ---------------------------------------------------------------------------
# Get a target's mirror partner (empty if none)
# ---------------------------------------------------------------------------
mirror_partner() {
  local target="$1"
  if [ ! -s "$MIRROR_MAP_FILE" ]; then
    printf ''
    return
  fi
  local a b
  while IFS=$'\t' read -r a b; do
    if [ "$a" = "$target" ]; then
      printf '%s' "$b"
      return
    elif [ "$b" = "$target" ]; then
      printf '%s' "$a"
      return
    fi
  done < "$MIRROR_MAP_FILE"
  printf ''
}

# ---------------------------------------------------------------------------
# Find first-order referrers for a target
# Args:
#   $1 = target repo-relative path
#   $2 = output file (TSV: file\tline\tcount\tsnippet)
# ---------------------------------------------------------------------------
find_first_order() {
  local target="$1"
  local out="$2"

  # Compute T1, T2, T3 search tokens for the target (inlined; bash 3.2 has no namerefs).
  # T1 = full path, T2 = basename, T3 = path-suffix-from-component-2
  local t1="$target"
  local t2
  t2="$(basename "$target")"
  local t3
  case "$target" in
    */*/*) t3="${target#*/}" ;;
    *)     t3="$t2" ;;
  esac
  # If T3 collapsed to T1 (target was already 2-component), fall back to T2 for T3
  if [ "$t3" = "$t1" ]; then
    t3="$t2"
  fi

  # Basename-uniqueness pre-count (#3291) over the (worktree-excluded, #3300) scan list.
  # The target carries its own basename once, so bn_count == 1 means the basename is
  # genuinely unique; bn_count >= 2 means another scanned file shares it. This gates the
  # basename-shaped match below so a non-unique basename cannot over-count every same-named
  # file as blast radius. Depends on #3300: with worktree copies present every basename
  # reads as non-unique, so this classification is only correct on the de-duplicated list.
  local bn_count
  bn_count="$(awk -F/ '{print $NF}' "$SCAN_LIST_FILE" | grep -Fxc -- "$t2" 2>/dev/null || true)"
  [ -z "$bn_count" ] && bn_count=1

  local matches_raw="$WORK_DIR/matches-raw.txt"
  : > "$matches_raw"

  # Build a temp file of files to grep (exclude the target itself)
  local files_to_grep="$WORK_DIR/files-to-grep.txt"
  grep -vxF "$target" "$SCAN_LIST_FILE" > "$files_to_grep" || true

  if [ ! -s "$files_to_grep" ]; then
    : > "$out"
    return
  fi

  # Build absolute paths for grep input
  local files_abs="$WORK_DIR/files-abs.txt"
  awk -v root="$REPO_ROOT/" '{print root $0}' "$files_to_grep" > "$files_abs"

  # Grep each token with `-F` (literal string), `-H -n` (file + line)
  # We grep three times rather than build a complex regex — simpler, faster
  # in practice, and produces predictable output for line-level dedup.
  # BATCHED, not per-file. The prior form was `xargs -0 -I {} -n 1 grep ...`, where the
  # `-I` replacement-string flag implies `-L 1` and therefore forks ONE grep process per
  # input file. With N scanned files, K tokens fired (1-3, gated by the basename-
  # uniqueness rule) and F first-order referrers, a depth-2 run cost (1+F)*K*N process
  # spawns — six figures on a high-fan-in target, and the whole of the hang: the cost was
  # process CREATION, not bytes scanned. Batching drops spawns to the number of xargs
  # batches while leaving the bytes scanned identical — which is exactly why the output
  # is byte-identical before and after.
  #
  # `-H` is retained so a batch that resolves to a single file still emits the
  # `<abs>:<line>:` prefix the awk reassembly below requires. `--` is added so a token
  # beginning with `-` cannot be read as an option. xargs auto-splits at ARG_MAX without
  # `-I`, so arbitrarily large corpora stay safe. This is the same idiom
  # find_structural_consumers already uses — the fix converges the two code paths onto
  # one form rather than introducing a new one.
  grep_token() {
    local token="$1"
    [ -z "$token" ] && return
    # Explicit empty guard. Dropping `-I` also drops xargs' implicit no-run-on-empty
    # behavior on GNU (BSD xargs skips an empty batch; GNU xargs runs the command once
    # unless -r), and a `grep -F -H -n -- TOKEN` invoked with no file operands reads
    # STDIN and blocks. The callers already guarantee a non-empty list, so this guard is
    # belt-and-braces — but it is what makes the batched form portable across both greps
    # rather than correct-by-caller-accident. `-r`/`--no-run-if-empty` is GNU-only and
    # would not have been portable.
    [ -s "$files_abs" ] || return
    # xargs to feed file list (handles >ARG_MAX file counts safely)
    < "$files_abs" tr '\n' '\0' \
      | xargs -0 grep -F -H -n -- "$token" 2>/dev/null \
      || true
  }

  # Collect all match lines: <abs_path>:<line>:<text>
  # Adaptive uniqueness gate (#3291): T1 (full path) is always path-true and always fires.
  # The basename-shaped match (T2, and T3 when it has collapsed to the basename for a
  # 2-component target) is fired ONLY when the basename is unique across the scan list —
  # preserving today's behavior for the common unique case (AC-2). For a non-unique
  # basename we match path-anchored only: T3 fires only when it is a genuine
  # multi-component suffix (never the collapsed-to-basename form), and T2 (bare basename)
  # is dropped — so a shared basename reports only its path-true consumers (AC-1).
  {
    grep_token "$t1"
    if [ "$bn_count" -le 1 ]; then
      # Unique basename → today's behavior (T1 + T3 + T2).
      if [ "$t3" != "$t1" ]; then grep_token "$t3"; fi
      if [ "$t2" != "$t3" ] && [ "$t2" != "$t1" ]; then grep_token "$t2"; fi
    else
      # Non-unique basename → path-anchored only: T3 only as a real multi-component
      # suffix (t3 != t2 guards the shallow-path collapsed-to-basename case); T2 dropped.
      if [ "$t3" != "$t1" ] && [ "$t3" != "$t2" ]; then grep_token "$t3"; fi
    fi
  } > "$matches_raw"

  # Parse: <abs_path>:<line>:<text> → <rel>\t<line>\t<text>
  # Dedup by (rel, line). Compute reference_count per rel.
  local parsed="$WORK_DIR/parsed.tsv"
  awk -v root="$REPO_ROOT/" '
    BEGIN { FS=":"; OFS="\t" }
    {
      # Reassemble: first field = abs path; second = line; rest = text
      abs = $1
      line = $2
      text = $0
      # Strip "abs:line:" prefix from text
      prefix = abs ":" line ":"
      idx = index(text, prefix)
      if (idx == 1) {
        text = substr(text, length(prefix) + 1)
      }
      # Make rel
      rel = abs
      if (substr(rel, 1, length(root)) == root) {
        rel = substr(rel, length(root) + 1)
      }
      print rel, line, text
    }
  ' "$matches_raw" \
    | LC_ALL=C sort -u -t $'\t' -k1,1 -k2,2n > "$parsed"

  # Aggregate: per file, count of unique (file,line); emit one row per
  # (file, line) with reference_count for the file aggregated separately.
  # For simplicity, output: <rel>\t<line>\t<text>; downstream aggregator
  # rolls up reference_count.
  cp "$parsed" "$out"
}

# ---------------------------------------------------------------------------
# Structural mode (#3120): normalize the OLD-path target for a path-move sweep.
#
# UNLIKE resolve_target, this does NOT require an existing regular file — the whole
# point of the sweep is to find who still hard-codes a path that has MOVED AWAY (and
# so may no longer exist). It accepts a directory prefix or a single path, strips a
# leading ./ and REPO_ROOT/, drops one trailing slash (a dir-prefix query matches its
# sub-paths via grep -F substring regardless), and does NOT reject an excluded target
# (a moved-FROM path under an excluded tree is a valid query). Sets TARGET_REL.
# ---------------------------------------------------------------------------
normalize_structural_target() {
  local input="$ARG_TARGET"
  input="${input#./}"
  if [[ "$input" = /* ]]; then
    case "$input" in
      "$REPO_ROOT"/*) input="${input#"$REPO_ROOT"/}" ;;
      *)
        err "--mode=structural target is absolute but outside repo root ($REPO_ROOT): $ARG_TARGET"
        exit "$EXIT_BAD_TARGET"
        ;;
    esac
  fi
  input="${input%/}"
  if [ -z "$input" ]; then
    err "--mode=structural requires a non-empty old-path literal to search for"
    exit "$EXIT_BAD_TARGET"
  fi
  TARGET_REL="$input"
}

# ---------------------------------------------------------------------------
# Structural mode (#3120): find every file that hard-codes the OLD path literal.
#
# This is the consumer class the default doc-reference tracer and the software
# import-graph tracer are both blind to — the exact miss that silently broke the
# Stage-13 GitHub-Release emit for ~5 releases (#230 → RCA #3118). Over the (post-#3300)
# scan list it greps the OLD-path literal with `grep -F` — NO T1/T2/T3 basename
# tokenization (a structural consumer hard-codes the full path; basename matching would
# reintroduce the #3291 over-match class) — and rolls the hits up through the shared
# schema-v1 library with an EMPTY mirror partner (is_mirror always false). second_order
# is scoped out ([] / 0): a path-literal consumer sweep is first-order by nature.
#
# Field semantics for structural output (mirrors the domain tracer's F4 block):
#   first_order[].path            — repo-relative path of a file that hard-codes the old path
#   first_order[].reference_count — count of distinct (file,line) hits of the old-path literal
#   first_order[].matches[]       — up to 5 {line, snippet} of the hard-coded references
#   first_order[].is_mirror       — ALWAYS false (no mirror concept for a path sweep)
#   second_order / second_order_count — [] / 0 (scoped out; sweep is first-order)
#   stats.total_files_scanned     — the whole doc-corpus denominator (same as the default tracer)
#
# Args: $1 = normalized OLD path literal (TARGET_REL).
# Sets: FIRST_ORDER_* + FILTERED_MIRRORS_* + SECOND_ORDER_* globals build_json consumes.
# ---------------------------------------------------------------------------
find_structural_consumers() {
  local oldpath="$1"

  local matches_raw="$WORK_DIR/structural-matches-raw.txt"
  : > "$matches_raw"

  # Absolute paths for the whole scan list (no target-exclusion filter — the moved-FROM
  # path can be referenced anywhere, including in the file that used to hold it).
  local files_abs="$WORK_DIR/structural-files-abs.txt"
  awk -v root="$REPO_ROOT/" '{print root $0}' "$SCAN_LIST_FILE" > "$files_abs"

  if [ -s "$files_abs" ]; then
    # Batched grep (-H forces the filename prefix so single-match files still parse).
    < "$files_abs" tr '\n' '\0' \
      | xargs -0 grep -F -H -n -- "$oldpath" 2>/dev/null > "$matches_raw" \
      || true
  fi

  # Parse <abs>:<line>:<text> → <rel>\t<line>\t<text> (same reassembly find_first_order
  # uses; abs paths carry no colon so FS=":" splits cleanly). Bare sort — the script-level
  # LC_ALL=C export (#675) covers it; no inline pin per CIAC-4.
  local parsed="$WORK_DIR/structural-parsed.tsv"
  if [ -s "$matches_raw" ]; then
    awk -v root="$REPO_ROOT/" '
      BEGIN { FS=":"; OFS="\t" }
      {
        abs = $1
        line = $2
        text = $0
        prefix = abs ":" line ":"
        idx = index(text, prefix)
        if (idx == 1) { text = substr(text, length(prefix) + 1) }
        rel = abs
        if (substr(rel, 1, length(root)) == root) { rel = substr(rel, length(root) + 1) }
        print rel, line, text
      }
    ' "$matches_raw" \
      | sort -u -t $'\t' -k1,1 -k2,2n > "$parsed"
  else
    : > "$parsed"
  fi

  # Roll up via the shared schema-v1 library. Empty mirror partner => is_mirror false.
  local bundle
  bundle="$(aggregate_matches_v1 "$parsed" "" "$ARG_INCLUDE_MIRRORS")"

  FIRST_ORDER_JSON="$(printf '%s' "$bundle" | jq -c '.first_order')"
  FIRST_ORDER_COUNT="$(printf '%s' "$bundle" | jq -r '.first_order_count')"
  FILTERED_MIRRORS_JSON="$(printf '%s' "$bundle" | jq -c '.filtered_mirrors_detail')"
  FILTERED_MIRRORS_COUNT="$(printf '%s' "$bundle" | jq -r '.filtered_mirrors_count')"

  # second_order scoped out for a path-literal consumer sweep.
  SECOND_ORDER_JSON="$(jq -n '[]')"
  SECOND_ORDER_COUNT=0
}

# ---------------------------------------------------------------------------
# JSON escape a string for embedding in a JSON value
# Uses jq -R to produce a quoted JSON string.
# ---------------------------------------------------------------------------
json_escape() {
  printf '%s' "$1" | jq -Rs .
}

# ---------------------------------------------------------------------------
# Aggregate first-order TSV into JSON array
# Filters out the target's mirror partner (unless --include-mirrors).
# Args:
#   $1 = first-order TSV (file\tline\ttext)
#   $2 = target repo-relative path (for mirror partner lookup)
# Sets globals:
#   FIRST_ORDER_JSON     — JSON array of first-order entries
#   FIRST_ORDER_COUNT    — count of distinct files
#   FILTERED_MIRRORS_JSON — JSON array of filtered mirror entries
#   FILTERED_MIRRORS_COUNT — count of filtered mirror entries
# ---------------------------------------------------------------------------
aggregate_first_order() {
  local tsv="$1"
  local target="$2"
  local partner
  partner="$(mirror_partner "$target")"

  # Delegate the roll-up + first_order[] emit to the shared schema-v1 library
  # (single home of the {path, reference_count, matches, is_mirror} object). This
  # script owns only the doc-corpus DISCOVERY that produced $tsv; the EMIT is the
  # library's. Behavior is identical to the prior inline block — the library body
  # was extracted verbatim (regression-guarded by test_domain_blast_radius.sh).
  local bundle
  bundle="$(aggregate_matches_v1 "$tsv" "$partner" "$ARG_INCLUDE_MIRRORS")"

  FIRST_ORDER_JSON="$(printf '%s' "$bundle" | jq -c '.first_order')"
  FIRST_ORDER_COUNT="$(printf '%s' "$bundle" | jq -r '.first_order_count')"
  FILTERED_MIRRORS_JSON="$(printf '%s' "$bundle" | jq -c '.filtered_mirrors_detail')"
  FILTERED_MIRRORS_COUNT="$(printf '%s' "$bundle" | jq -r '.filtered_mirrors_count')"
}

# ---------------------------------------------------------------------------
# Compute second-order referrers from a list of first-order paths
# Args:
#   $1 = JSON array of first-order entries
#   $2 = original target path (excluded from second-order results)
# Sets:
#   SECOND_ORDER_JSON  — JSON array
#   SECOND_ORDER_COUNT — count
# ---------------------------------------------------------------------------
compute_second_order() {
  local fo_json="$1"
  local target="$2"

  SECOND_ORDER_JSON="$(jq -n '[]')"
  SECOND_ORDER_COUNT=0

  if [ "$ARG_DEPTH" -lt 2 ]; then
    return
  fi

  # Set of paths already in first-order + the original target
  local seen_file="$WORK_DIR/seen.txt"
  printf '%s\n' "$target" > "$seen_file"
  printf '%s' "$fo_json" | jq -r '.[].path' >> "$seen_file"
  sort -u "$seen_file" -o "$seen_file"

  # For each first-order entry path, find its referrers
  local fo_paths
  fo_paths="$(printf '%s' "$fo_json" | jq -r '.[].path')"
  if [ -z "$fo_paths" ]; then
    return
  fi

  # Deterministic fan-out cap (--max-expand), applied BEFORE the scan loop so it skips
  # whole referrer expansions rather than filtering their results afterwards. fo_json
  # arrives already sorted reference_count DESC, path ASC (aggregate_matches_v1), so the
  # truncation is reproducible for a given input and keeps the highest-signal referrers.
  # When it fires the run is explicitly marked partial and exits EXIT_PARTIAL — the whole
  # point is that a truncated run can never be mistaken for "no blast radius".
  if [ "$ARG_MAX_EXPAND" -gt 0 ]; then
    local fo_total
    fo_total="$(printf '%s\n' "$fo_paths" | grep -c . || true)"
    [ -z "$fo_total" ] && fo_total=0
    if [ "$fo_total" -gt "$ARG_MAX_EXPAND" ]; then
      fo_paths="$(printf '%s\n' "$fo_paths" | head -n "$ARG_MAX_EXPAND")"
      PARTIAL=1
      PARTIAL_REASON="second-order expansion capped at --max-expand=${ARG_MAX_EXPAND} of ${fo_total} first-order referrers"
      err "PARTIAL RESULT: ${PARTIAL_REASON}"
    fi
  fi

  local so_tsv="$WORK_DIR/so.tsv"
  : > "$so_tsv"

  local via tsv2
  while IFS= read -r via; do
    [ -z "$via" ] && continue
    tsv2="$WORK_DIR/so-${via//\//_}.tsv"
    find_first_order "$via" "$tsv2"
    # Mark each row with the via path
    awk -v via="$via" -F '\t' '{print $0 "\t" via}' "$tsv2" >> "$so_tsv"
  done <<EOF
$fo_paths
EOF

  if [ ! -s "$so_tsv" ]; then
    return
  fi

  # Filter out paths already in seen (target + first-order)
  local so_filtered="$WORK_DIR/so-filtered.tsv"
  awk -F '\t' -v seen="$seen_file" '
    BEGIN {
      while ((getline line < seen) > 0) {
        seen_set[line] = 1
      }
      close(seen)
    }
    {
      if (!($1 in seen_set)) print $0
    }
  ' "$so_tsv" > "$so_filtered"

  if [ ! -s "$so_filtered" ]; then
    return
  fi

  # Aggregate per (file): pick first via, count refs, store up to 5 matches
  local agg
  agg=$(awk -F '\t' '
    {
      file = $1
      line = $2
      text = $3
      via = $4
      sub(/^[ \t]+/, "", text)
      if (length(text) > 200) {
        text = substr(text, 1, 200) "…"
      }
      count[file]++
      if (!(file in first_via)) first_via[file] = via
      if (matches_count[file] < 5) {
        matches_count[file]++
        idx = matches_count[file]
        m_line[file SUBSEP idx] = line
        m_text[file SUBSEP idx] = text
      }
    }
    END {
      for (file in count) {
        printf "%s\t%d\t%s", file, count[file], first_via[file]
        for (i = 1; i <= matches_count[file]; i++) {
          printf "\t%d\t%s", m_line[file SUBSEP i], m_text[file SUBSEP i]
        }
        printf "\n"
      }
    }
  ' "$so_filtered")

  local sorted
  sorted=$(printf '%s\n' "$agg" | LC_ALL=C sort -t $'\t' -k2,2nr -k1,1)

  local entries="$(jq -n '[]')"
  local count=0
  local mirror_partner_path
  mirror_partner_path="$(mirror_partner "$target")"

  while IFS= read -r row; do
    [ -z "$row" ] && continue
    local file refcount via
    file="$(printf '%s' "$row" | awk -F '\t' '{print $1}')"
    refcount="$(printf '%s' "$row" | awk -F '\t' '{print $2}')"
    via="$(printf '%s' "$row" | awk -F '\t' '{print $3}')"

    local is_mirror=false
    if [ -n "$mirror_partner_path" ] && [ "$file" = "$mirror_partner_path" ]; then
      is_mirror=true
    fi

    # Skip mirror entries unless --include-mirrors
    if [ "$is_mirror" = "true" ] && [ "$ARG_INCLUDE_MIRRORS" = "0" ]; then
      continue
    fi

    local match_pairs
    match_pairs="$(printf '%s' "$row" | awk -F '\t' '{
      for (i = 4; i <= NF; i += 2) {
        if (i+1 <= NF) {
          print $i "\t" $(i+1)
        }
      }
    }')"

    local matches_json
    matches_json=$(
      printf '%s\n' "$match_pairs" \
        | jq -R -s '
            split("\n")
            | map(select(length > 0))
            | map(split("\t"))
            | map({line: (.[0] | tonumber), snippet: .[1]})
          '
    )

    local entry
    entry=$(jq -n \
      --arg path "$file" \
      --arg via "$via" \
      --argjson ref_count "$refcount" \
      --argjson matches "$matches_json" \
      --argjson depth "2" \
      --argjson is_mirror "$is_mirror" \
      '{path: $path, via: $via, reference_count: $ref_count, matches: $matches, depth: $depth, is_mirror: $is_mirror}')

    entries=$(printf '%s\n%s\n' "$entries" "$entry" | jq -s '.[0] + [.[1]]')
    count=$((count + 1))
  done <<EOF
$sorted
EOF

  SECOND_ORDER_JSON="$entries"
  SECOND_ORDER_COUNT="$count"
}

# ---------------------------------------------------------------------------
# Assemble the v1 JSON output document
# ---------------------------------------------------------------------------
build_json() {
  local elapsed="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local include_mirrors_json
  include_mirrors_json="$([ "$ARG_INCLUDE_MIRRORS" = "1" ] && echo true || echo false)"

  # Assert the tracer's schema version matches the sourced library before emit —
  # a skew fails loudly rather than shipping a mislabeled envelope.
  if [ "$SCHEMA_VERSION" != "$SCHEMA_V1_EMIT_VERSION" ]; then
    err "schema version skew: blast-radius=$SCHEMA_VERSION lib=$SCHEMA_V1_EMIT_VERSION"
    exit "$EXIT_INTERNAL"
  fi

  # Delegate the envelope assembly to the shared library (single home of the
  # schema-v1 top-level document). Behavior is byte-identical to the prior inline
  # jq — the assembly was extracted verbatim (regression-guarded).
  build_json_v1 \
    "$CLI_VERSION" \
    "$TARGET_REL" \
    "$timestamp" \
    "$REPO_ROOT" \
    "$ARG_DEPTH" \
    "$include_mirrors_json" \
    "$TOTAL_FILES_SCANNED" \
    "$FIRST_ORDER_COUNT" \
    "$SECOND_ORDER_COUNT" \
    "$FILTERED_MIRRORS_COUNT" \
    "$elapsed" \
    "$FIRST_ORDER_JSON" \
    "$SECOND_ORDER_JSON" \
    "$FILTERED_MIRRORS_JSON" \
    "$SCHEMA_VERSION"
}

# ---------------------------------------------------------------------------
# Table presenter (off the JSON)
# ---------------------------------------------------------------------------
render_table() {
  local json="$1"
  local target depth include_mirrors total first_count second_count filtered elapsed

  target=$(printf '%s' "$json" | jq -r '.target')
  depth=$(printf '%s' "$json" | jq -r '.depth')
  include_mirrors=$(printf '%s' "$json" | jq -r '.include_mirrors')
  total=$(printf '%s' "$json" | jq -r '.stats.total_files_scanned')
  first_count=$(printf '%s' "$json" | jq -r '.stats.first_order_count')
  second_count=$(printf '%s' "$json" | jq -r '.stats.second_order_count')
  filtered=$(printf '%s' "$json" | jq -r '.stats.filtered_mirrors')
  elapsed=$(printf '%s' "$json" | jq -r '.stats.elapsed_seconds')

  c_bold; printf 'Blast radius — '; c_reset; printf '%s\n' "$target"
  c_dim;  printf '  depth=%s  include_mirrors=%s  scanned=%s files  elapsed=%ss  filtered_mirrors=%s\n' \
    "$depth" "$include_mirrors" "$total" "$elapsed" "$filtered"
  c_reset

  # Visible on the degraded path so a human reading the table cannot mistake a truncated
  # run for a complete one (the JSON marker and exit 6 cover machine consumers).
  if [ "$(printf '%s' "$json" | jq -r '.partial // false')" = "true" ]; then
    c_red
    printf '  !! PARTIAL RESULT — %s\n' "$(printf '%s' "$json" | jq -r '.partial_reason')"
    printf '  !! Second-order results below are TRUNCATED, not complete.\n'
    c_reset
  fi

  printf '\n'
  c_bold; printf 'First-order referrers (%s)\n' "$first_count"; c_reset

  if [ "$first_count" -eq 0 ]; then
    c_dim; printf '  (none)\n'; c_reset
  else
    printf '%s' "$json" | jq -r '
      .first_order[]
      | "  " + (.reference_count|tostring) + "× " + .path + (if .is_mirror then " [MIRROR]" else "" end)
    '
  fi

  if [ "$depth" -ge 2 ]; then
    printf '\n'
    c_bold; printf 'Second-order referrers (%s)\n' "$second_count"; c_reset
    if [ "$second_count" -eq 0 ]; then
      c_dim; printf '  (none)\n'; c_reset
    else
      printf '%s' "$json" | jq -r '
        .second_order[]
        | "  " + (.reference_count|tostring) + "× " + .path + "  (via " + .via + ")" + (if .is_mirror then " [MIRROR]" else "" end)
      '
    fi
  fi

  if [ "$include_mirrors" = "true" ] || [ "$filtered" -gt 0 ]; then
    printf '\n'
    c_dim; printf 'Filtered mirror pairs: %s\n' "$filtered"; c_reset
    if [ "$filtered" -gt 0 ]; then
      printf '%s' "$json" | jq -r '
        .filtered_mirrors_detail[]
        | "  - " + .path + " (refs: " + (.reference_count|tostring) + ")"
      '
    fi
  fi

  c_dim
  printf '\nUse --format=json for machine-readable output. See release/references/protocols/blast-radius-protocol.md\n'
  c_reset
}

# ---------------------------------------------------------------------------
# Markdown presenter (off the JSON)
# ---------------------------------------------------------------------------
render_md() {
  local json="$1"
  local target depth include_mirrors total first_count second_count filtered elapsed scanned_at

  target=$(printf '%s' "$json" | jq -r '.target')
  depth=$(printf '%s' "$json" | jq -r '.depth')
  include_mirrors=$(printf '%s' "$json" | jq -r '.include_mirrors')
  total=$(printf '%s' "$json" | jq -r '.stats.total_files_scanned')
  first_count=$(printf '%s' "$json" | jq -r '.stats.first_order_count')
  second_count=$(printf '%s' "$json" | jq -r '.stats.second_order_count')
  filtered=$(printf '%s' "$json" | jq -r '.stats.filtered_mirrors')
  elapsed=$(printf '%s' "$json" | jq -r '.stats.elapsed_seconds')
  scanned_at=$(printf '%s' "$json" | jq -r '.scanned_at')

  printf '# Blast radius — `%s`\n\n' "$target"

  # Visible on the degraded path — same reason as the table presenter.
  if [ "$(printf '%s' "$json" | jq -r '.partial // false')" = "true" ]; then
    printf '> **!! PARTIAL RESULT** — %s\n>\n' "$(printf '%s' "$json" | jq -r '.partial_reason')"
    printf '> Second-order results below are TRUNCATED, not complete.\n\n'
  fi

  printf '| Stat | Value |\n|---|---|\n'
  printf '| scanned_at | %s |\n' "$scanned_at"
  printf '| depth | %s |\n' "$depth"
  printf '| include_mirrors | %s |\n' "$include_mirrors"
  printf '| total_files_scanned | %s |\n' "$total"
  printf '| first_order_count | %s |\n' "$first_count"
  printf '| second_order_count | %s |\n' "$second_count"
  printf '| filtered_mirrors | %s |\n' "$filtered"
  printf '| elapsed_seconds | %s |\n\n' "$elapsed"

  printf '## First-order referrers (%s)\n\n' "$first_count"
  if [ "$first_count" -eq 0 ]; then
    printf '_(none)_\n'
  else
    printf '| Refs | Path | Mirror? |\n|---:|---|:---:|\n'
    printf '%s' "$json" | jq -r '
      .first_order[]
      | [ (.reference_count|tostring), .path, (if .is_mirror then "✓" else "" end) ]
      | "| " + (.[0]) + " | `" + (.[1]) + "` | " + (.[2]) + " |"
    '
  fi

  if [ "$depth" -ge 2 ]; then
    printf '\n## Second-order referrers (%s)\n\n' "$second_count"
    if [ "$second_count" -eq 0 ]; then
      printf '_(none)_\n'
    else
      printf '| Refs | Path | Via | Mirror? |\n|---:|---|---|:---:|\n'
      printf '%s' "$json" | jq -r '
        .second_order[]
        | [ (.reference_count|tostring), .path, .via, (if .is_mirror then "✓" else "" end) ]
        | "| " + (.[0]) + " | `" + (.[1]) + "` | `" + (.[2]) + "` | " + (.[3]) + " |"
      '
    fi
  fi

  if [ "$filtered" -gt 0 ]; then
    printf '\n## Filtered mirror pairs (%s)\n\n' "$filtered"
    printf '%s' "$json" | jq -r '
      .filtered_mirrors_detail[]
      | "- `" + .path + "` (refs: " + (.reference_count|tostring) + ")"
    '
  fi
}

# ---------------------------------------------------------------------------
# Built-in regression suite (--self-test)
#
# 13 assertions in 3 groups. HERMETIC: every fixture lives in an isolated mktemp tree
# scanned via --root, so counts never depend on the surrounding repo. No network, no gh,
# no git. Runs in ~2s.
#
# The suite asserts STRUCTURE and COUNTS, never wall-clock. A timing assertion on a
# shared CI runner is a flake generator; asserting the defect shape directly is
# deterministic and still discriminates a regression, because the defect IS a shape
# (a per-file xargs replstr form) rather than a threshold.
#
# T1 is a structural regression guard on grep_token. T1z is its EXTRACTION CONTROL: it
# proves the awk range-scope actually pulled a non-empty function body AND that a
# deliberately wrong anchor yields nothing — so T1a's zero is a real zero rather than a
# zero-length haystack. T2 proves a clean run is provably non-empty and provably
# unmarked; T3 forces the bounded path and proves the marker fires, names the true
# total, and truncates for real. T2e and T3e are the specificity arms proving the
# marker is not always-on.
# ---------------------------------------------------------------------------
run_self_test() {
  local self="${BASH_SOURCE[0]}"
  local pass=0 fail=0

  st_ok()   { pass=$((pass + 1)); printf '  PASS  %s\n' "$1"; }
  st_bad()  { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }
  st_eq()   { # st_eq <expected> <actual> <label>
    if [ "$1" = "$2" ]; then st_ok "$3 [$2]"; else st_bad "$3 — expected '$1', got '$2'"; fi
  }
  st_true() { # st_true <rc> <label>   (rc 0 = pass)
    if [ "$1" = "0" ]; then st_ok "$2"; else st_bad "$2"; fi
  }

  if ! command -v jq >/dev/null 2>&1; then
    printf 'blast-radius --self-test: missing dependency jq\n' >&2
    return "$EXIT_MISSING_DEP"
  fi

  printf 'blast-radius.sh --self-test\n\n'

  # -------------------------------------------------------------------------
  # T1 — structural regression guard on grep_token (the defect shape itself)
  # -------------------------------------------------------------------------
  local body body_lines bogus_lines code hits rc
  body="$(awk '/^  grep_token\(\) \{$/{f=1} f{print} f && /^  \}$/{exit}' "$self")"
  body_lines="$(printf '%s\n' "$body" | grep -c . || true)"
  # Same extractor, deliberately wrong anchor — MUST yield nothing.
  bogus_lines="$(awk '/^  grep_token_NOT_A_REAL_ANCHOR\(\) \{$/{f=1} f{print} f && /^  \}$/{exit}' "$self" | grep -c . || true)"
  rc=0
  { [ "${body_lines:-0}" -ge 5 ] && [ "${bogus_lines:-0}" -eq 0 ]; } || rc=1
  st_true "$rc" "T1z CONTROL: grep_token body extracted (${body_lines:-0} lines); bogus anchor yields ${bogus_lines:-0}"

  # Strip comments before asserting on the CODE, so prose that merely names the retired
  # flag cannot fail the assertion (and so a defect cannot hide inside a comment).
  code="$(printf '%s\n' "$body" | awk '{ sub(/[[:space:]]*#.*$/, ""); print }')"

  # Bracket-expression `[-]` rather than `\-`: a stray backslash before `-` in an ERE is
  # undefined behavior that GNU grep warns about, and this suite runs on the GNU runner.
  # Catches both spellings of the retired form (`-I {}` and `-I{}`).
  hits="$(printf '%s\n' "$code" | grep -c -E -e '[[:space:]][-]I([[:space:]]|[{])|[[:space:]][-]n[[:space:]]+1([[:space:]]|$)' || true)"
  st_eq "0" "${hits:-0}" "T1a grep_token carries NO per-file xargs replstr form (-I / -n 1)"

  hits="$(printf '%s\n' "$code" | grep -c -F -e 'xargs -0 grep -F -H -n --' || true)"
  st_eq "1" "${hits:-0}" "T1b grep_token uses the batched xargs form"

  # -------------------------------------------------------------------------
  # Fixture: docs/target.md <- 12 referrers; refs/r01.md <- 5; refs/r12.md <- 2.
  # Every basename is unique across the tree, so the basename-uniqueness gate classifies
  # each target as unique and the token set fired is stable. r01 and r12 sit at opposite
  # ends of the tie-broken sort ON PURPOSE: capping at 3 keeps r01's expansion and drops
  # r12's, so T3d observes a real reduction rather than a cap that changed nothing.
  # -------------------------------------------------------------------------
  local fx i
  SELFTEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/blast-radius-selftest.XXXXXX")"
  trap 'rm -rf "${SELFTEST_TMPDIR:-}"' EXIT
  fx="$SELFTEST_TMPDIR"
  mkdir -p "$fx/docs" "$fx/refs" "$fx/so"
  printf 'the target; it references nothing\n' > "$fx/docs/target.md"
  for i in 01 02 03 04 05 06 07 08 09 10 11 12; do
    printf 'first-order referrer %s -> docs/target.md\n' "$i" > "$fx/refs/r${i}.md"
  done
  for i in 01 02 03 04 05; do
    printf 'second-order referrer %s -> refs/r01.md\n' "$i" > "$fx/so/s${i}.md"
  done
  for i in 01 02; do
    printf 'second-order referrer %s -> refs/r12.md\n' "$i" > "$fx/so/t${i}.md"
  done

  local out err_out bytes fo so partial reason
  out="$fx/out.json"; err_out="$fx/out.err"

  # -------------------------------------------------------------------------
  # T2 — bounded traversal + NON-EMPTY EXTRACTION on a clean run
  # -------------------------------------------------------------------------
  rc=0
  bash "$self" --root "$fx" --format=json --depth=2 docs/target.md > "$out" 2>"$err_out" || rc=$?
  st_eq "0" "$rc" "T2a clean depth-2 run exits 0"

  bytes="$(wc -c < "$out" | tr -d ' ')"
  rc=0; [ "${bytes:-0}" -gt 200 ] || rc=1
  st_true "$rc" "T2b clean run emits NON-EMPTY output (${bytes:-0} bytes) — not a silent 0-byte success"

  fo="$(jq -r '.stats.first_order_count' "$out" 2>/dev/null || echo ERR)"
  st_eq "12" "$fo" "T2c first_order_count"

  so="$(jq -r '.stats.second_order_count' "$out" 2>/dev/null || echo ERR)"
  st_eq "7" "$so" "T2d second_order_count (5 via refs/r01.md + 2 via refs/r12.md)"

  partial="$(jq -r '.partial // false' "$out" 2>/dev/null || echo ERR)"
  st_eq "false" "$partial" "T2e SPECIFICITY: a complete run carries NO partial marker"

  # -------------------------------------------------------------------------
  # T3 — partial-result contract: force the bounded path (AC-5)
  # -------------------------------------------------------------------------
  rc=0
  bash "$self" --root "$fx" --format=json --depth=2 --max-expand=3 docs/target.md > "$out" 2>"$err_out" || rc=$?
  st_eq "6" "$rc" "T3a a capped run exits EXIT_PARTIAL, NOT 0"

  partial="$(jq -r '.partial // false' "$out" 2>/dev/null || echo ERR)"
  st_eq "true" "$partial" "T3b a capped run carries .partial = true"

  reason="$(jq -r '.partial_reason // ""' "$out" 2>/dev/null || echo "")"
  rc=0
  { printf '%s' "$reason" | grep -q -F -e '--max-expand=3' \
    && printf '%s' "$reason" | grep -q -F -e 'of 12 first-order referrers'; } || rc=1
  st_true "$rc" "T3c partial_reason names BOTH the cap and the true total [${reason}]"

  fo="$(jq -r '.stats.first_order_count' "$out" 2>/dev/null || echo ERR)"
  so="$(jq -r '.stats.second_order_count' "$out" 2>/dev/null || echo ERR)"
  rc=0
  { [ "$fo" = "12" ] && [ "$so" = "5" ]; } || rc=1
  st_true "$rc" "T3d truncation is REAL and scoped: first_order still complete (fo=$fo of 12), second_order cut (so=$so of 7)"

  rc=0
  bash "$self" --root "$fx" --format=json --depth=2 --max-expand=0 docs/target.md > "$out" 2>"$err_out" || rc=$?
  partial="$(jq -r '.partial // false' "$out" 2>/dev/null || echo ERR)"
  so="$(jq -r '.stats.second_order_count' "$out" 2>/dev/null || echo ERR)"
  local rc2=0
  { [ "$rc" = "0" ] && [ "$partial" = "false" ] && [ "$so" = "7" ]; } || rc2=1
  st_true "$rc2" "T3e SPECIFICITY: --max-expand=0 (unlimited) exits 0, no marker, full so=7"

  printf '\n%s/%s assertions passed\n' "$pass" "$((pass + fail))"
  if [ "$fail" -gt 0 ]; then
    printf 'blast-radius --self-test: FAILED (%s)\n' "$fail" >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"
  check_deps

  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/blast-radius.XXXXXX")"
  trap 'rm -rf "$WORK_DIR"' EXIT

  resolve_root

  local start_ts end_ts elapsed
  start_ts=$(date +%s)

  if [ "$ARG_MODE" = "structural" ]; then
    # Path-move consumer sweep (#3120): a NEW query over the same (post-#3300) scan list.
    # Reuses build_scan_list / DEFAULT_EXCLUSIONS / SCANNED_TYPES verbatim; the default
    # doc-tracer path (find_first_order → aggregate → second_order) is NOT touched.
    normalize_structural_target
    build_scan_list
    find_structural_consumers "$TARGET_REL"
  else
    # Default doc-reference tracer — unchanged.
    resolve_target
    build_scan_list
    detect_mirror_pairs

    local fo_tsv="$WORK_DIR/first-order.tsv"
    find_first_order "$TARGET_REL" "$fo_tsv"
    aggregate_first_order "$fo_tsv" "$TARGET_REL"

    compute_second_order "$FIRST_ORDER_JSON" "$TARGET_REL"
  fi

  end_ts=$(date +%s)
  elapsed=$((end_ts - start_ts))
  elapsed="${elapsed}.0"

  local json
  json=$(build_json "$elapsed")

  # Partial-result marker, injected AFTER build_json and deliberately NOT inside
  # lib/schema-v1-emit.sh. Keeping it here means the shared library is untouched, so
  # domain-blast-radius.sh is untouched and schema_version does not bump. On a
  # non-truncated run the output is byte-identical to before this change — the keys
  # appear ONLY on the degraded path, so no existing consumer ever sees a new key.
  if [ "$PARTIAL" = "1" ]; then
    json="$(printf '%s' "$json" | jq --arg r "$PARTIAL_REASON" \
      '.partial = true | .partial_reason = $r | .stats.partial = true')"
  fi

  case "$ARG_FORMAT" in
    json)  printf '%s\n' "$json" ;;
    table) render_table "$json" ;;
    md)    render_md "$json" ;;
  esac

  # A capped run exits non-zero AND carries the marker — both limbs, not one. A consumer
  # that checks only the exit code catches it; a consumer that reads only the JSON
  # catches it. Neither can read a truncated result as "no blast radius".
  if [ "$PARTIAL" = "1" ]; then
    exit "$EXIT_PARTIAL"
  fi

  exit "$EXIT_OK"
}

main "$@"
