#!/usr/bin/env bash
set -euo pipefail
# domain-blast-radius.sh — Domain-keyed impact-analysis fan-out tracer.
#
# The executable counterpart to the Stage-5 Phase A3.1 domain-aware impact-analysis
# METHOD (release/references/pipeline/stage-05-solutioning.md A3.1) and the worked
# example in release/references/protocols/blast-radius-protocol.md § 12. Where
# blast-radius.sh traces the DOC corpus (markdown-tree path-string fan-out), this
# sibling traces a non-doc domain's dependency graph — v1 ships the `software`
# domain: a code import-graph fan-out (who imports the changed module?).
#
# SIBLING, not an extension (ADR-068): blast-radius.sh has no scanner-plug seam;
# forking its scan loop would put every reflexive doc-corpus A3 run at regression
# risk. This is a separate CLI that REUSES the schema-v1 output contract via the
# shared library release/tools/lib/schema-v1-emit.sh, so a consumer that pins to
# schema v1 (design-review-checklist.md §1) reads output from either tracer
# identically. The schema contract is shared as a LIBRARY, not by co-location.
#
# USAGE
#   domain-blast-radius.sh --domain=software [OPTIONS] <target>
#
# OPTIONS
#   --domain=DOMAIN   Impact-analysis domain: software (implemented) |
#                     web (component, stub) | enterprise-platform (solution, stub)
#   --depth=N         Traversal depth (default 2; hard cap 4). NOTE: the software
#                     scanner ships first-order only (depth-2 import-graph traversal
#                     is scoped out for v1 — see "second-order scope-out" below);
#                     the flag is accepted for envelope parity.
#   --format=FORMAT   json | table | md (default: table if tty, json otherwise)
#   --root=PATH       Repo root for scanning (default: git toplevel)
#   --exclude=GLOB    Additional exclusion path-prefix; repeatable. `.claude/worktrees/`
#                     is excluded BY DEFAULT (worktree copies inflate import counts).
#   --no-color        Disable ANSI color in table output
#   --version         Show CLI + schema version and exit
#   -h, --help        Show this help and exit
#
# EXIT CODES (mirror blast-radius.sh, plus 5)
#   0  Success
#   1  Internal error / unknown option / invalid --domain
#   2  Bad target (path doesn't exist or is not a regular file)
#   3  Target is under an exclusion glob
#   4  Missing dependency (jq not on PATH)
#   5  Scanner not yet implemented for the selected domain (web / enterprise-platform)
#
# --- SCHEMA-V1 FIELD SEMANTICS FOR THE SOFTWARE DOMAIN (F4) --------------------
# The envelope is the full schema-v1 shape emitted by the shared library, but three
# fields carry domain-specific meaning or are deliberately scoped out for v1. This
# is the contract the design-review-checklist §1 consumer must read for `domain:
# software` output (and the ADR-068 record states the same):
#
#   first_order[].path            — repo-relative path of the IMPORTING file (a file
#                                   that directly imports/requires the changed module).
#   first_order[].reference_count — count of distinct IMPORT/REQUIRE STATEMENT lines
#                                   to the target module in that file (a re-export
#                                   counts once; NOT doc mention-lines). This is the
#                                   unit that differs from the doc tracer.
#   first_order[].matches[]       — up to 5 {line, snippet} of the import statements.
#   first_order[].is_mirror       — ALWAYS false. Mirror-pair suppression is a
#                                   doc-corpus artifact; code imports have no mirror
#                                   concept. A deliberate documented constant.
#   stats.first_order_count       — distinct importing files.
#
#   second_order (+ .via, .depth) — SCOPED OUT for software v1: emitted as [] with
#     stats.second_order_count        stats.second_order_count = 0. Depth-2 import-graph
#                                     traversal (who imports the importers) is a named
#                                     follow-on, NOT claimed here — this tracer does not
#                                     over-claim full envelope parity. The doc tracer
#                                     DOES populate second_order[].via/.depth; the
#                                     software domain intentionally does not (ADR-068).
#   stats.total_files_scanned     — count of CODE files the scanner searched for
#                                   importers (the language-scoped candidate set), NOT
#                                   the whole-corpus file count the doc tracer reports.
#                                   Domain-specific denominator, documented here + ADR-068.
#   stats.filtered_mirrors        — always 0 (is_mirror is always false).
#   include_mirrors               — always false for this domain.
# ------------------------------------------------------------------------------
#
# See release/references/protocols/blast-radius-protocol.md § 12 for the method,
# core/ADRs/ADR-068-domain-fan-out-sibling-vs-extend.md for the architecture.

# ---------------------------------------------------------------------------
# Version metadata (the contract is the schema, not the implementation)
# ---------------------------------------------------------------------------
readonly CLI_VERSION="0.1.0"
readonly SCHEMA_VERSION="1"

# ---------------------------------------------------------------------------
# Pinned PATH for tool discipline (per bypass-mode-readiness.md posture)
# ---------------------------------------------------------------------------
PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"

# ---------------------------------------------------------------------------
# Shared schema-v1 emitter (the single home of the output contract) — sourced
# relative to this script so it resolves under any checkout / worktree.
# ---------------------------------------------------------------------------
_DBR_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd -P)"
# shellcheck source=lib/schema-v1-emit.sh
. "${_DBR_LIB_DIR}/schema-v1-emit.sh"

# ---------------------------------------------------------------------------
# Exit codes
# ---------------------------------------------------------------------------
readonly EXIT_OK=0
readonly EXIT_INTERNAL=1
readonly EXIT_BAD_TARGET=2
readonly EXIT_EXCLUDED_TARGET=3
readonly EXIT_MISSING_DEP=4
readonly EXIT_SCANNER_NOT_IMPLEMENTED=5

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
HARD_CAP_DEPTH=4
DEFAULT_DEPTH=2

# ---------------------------------------------------------------------------
# Argument parsing state
# ---------------------------------------------------------------------------
ARG_DOMAIN=""
ARG_FORMAT=""
ARG_DEPTH="$DEFAULT_DEPTH"
ARG_ROOT=""
ARG_NO_COLOR=0
declare -a ARG_EXCLUDE_ADDITIONAL=()
ARG_TARGET=""

# ---------------------------------------------------------------------------
# Default exclusions. `.claude/worktrees/` is excluded BY DEFAULT: worktree copies
# under the git toplevel double/triple-count importers (the scan-root worktree-leak
# inflation the Stage-5 A6.5 review flagged). --exclude adds to these.
# ---------------------------------------------------------------------------
declare -a DEFAULT_EXCLUSIONS=(
  ".git/"
  ".claude/worktrees/"
  "pmo-platform/packages/"
  "projects/"
  "node_modules/"
  ".claude/skills/"
)

# ---------------------------------------------------------------------------
# Code file types the software scanner searches for importers. Distinct from the
# doc tracer's SCANNED_TYPES (md/sh/json/yml/…): this is the language-source set
# an import edge can live in.
# ---------------------------------------------------------------------------
declare -a SOFTWARE_SCANNED_TYPES=(
  "py"
  "js"
  "jsx"
  "ts"
  "tsx"
  "mjs"
  "cjs"
  "sh"
  "bash"
  "c"
  "h"
  "cc"
  "cpp"
  "hpp"
)

# ---------------------------------------------------------------------------
# Color helpers
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
c_reset() { if use_color; then printf '\033[0m'; fi; }

err() {
  c_red >&2
  printf 'domain-blast-radius: ERROR: %s\n' "$*" >&2
  c_reset >&2
}

# ---------------------------------------------------------------------------
# Usage banner
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
domain-blast-radius.sh — Domain-keyed impact-analysis fan-out tracer

USAGE
  domain-blast-radius.sh --domain=software [OPTIONS] <target_file>

OPTIONS
  --domain=DOMAIN   software (implemented) | web (stub) | enterprise-platform (stub)
  --depth=N         Traversal depth (default $DEFAULT_DEPTH; hard cap $HARD_CAP_DEPTH).
                    software ships first-order only; second-order is scoped out for v1.
  --format=FORMAT   json | table | md   (default: table if tty, json otherwise)
  --root=PATH       Repo root for scanning (default: git toplevel)
  --exclude=GLOB    Additional exclusion path-prefix; repeatable
  --no-color        Disable ANSI color in table output
  --version         Show CLI + schema version and exit
  -h, --help        Show this help and exit

EXIT CODES
  0 Success  1 Internal/invalid-domain  2 Bad target  3 Excluded target
  4 Missing dep (jq)  5 Scanner not implemented for domain

EXAMPLE
  # Who imports scripts/utils.py? (software import-graph fan-out, JSON)
  domain-blast-radius.sh --domain=software --format=json release/skills/foo/scripts/utils.py

DOCS
  release/references/protocols/blast-radius-protocol.md § 12
  core/ADRs/ADR-068-domain-fan-out-sibling-vs-extend.md
EOF
}

# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit "$EXIT_OK" ;;
      --version)
        printf 'domain-blast-radius %s (schema v%s)\n' "$CLI_VERSION" "$SCHEMA_VERSION"
        exit "$EXIT_OK"
        ;;
      --domain=*) ARG_DOMAIN="${1#--domain=}" ;;
      --domain)   shift; ARG_DOMAIN="${1:-}" ;;
      --format=*) ARG_FORMAT="${1#--format=}" ;;
      --format)   shift; ARG_FORMAT="${1:-}" ;;
      --depth=*)  ARG_DEPTH="${1#--depth=}" ;;
      --depth)    shift; ARG_DEPTH="${1:-}" ;;
      --root=*)   ARG_ROOT="${1#--root=}" ;;
      --root)     shift; ARG_ROOT="${1:-}" ;;
      --exclude=*) ARG_EXCLUDE_ADDITIONAL+=("${1#--exclude=}") ;;
      --exclude)   shift; ARG_EXCLUDE_ADDITIONAL+=("${1:-}") ;;
      --no-color)  ARG_NO_COLOR=1 ;;
      --) shift; if [ $# -gt 0 ]; then ARG_TARGET="$1"; fi ;;
      -*)
        err "Unknown option: $1"; usage >&2; exit "$EXIT_INTERNAL" ;;
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

  if [ -z "$ARG_DOMAIN" ]; then
    err "No --domain specified (software | web | enterprise-platform)"
    usage >&2
    exit "$EXIT_INTERNAL"
  fi
  if [ -z "$ARG_TARGET" ]; then
    err "No target file specified"
    usage >&2
    exit "$EXIT_INTERNAL"
  fi
  if ! [[ "$ARG_DEPTH" =~ ^[0-9]+$ ]]; then
    err "Invalid --depth value: '$ARG_DEPTH' (must be a non-negative integer)"
    exit "$EXIT_INTERNAL"
  fi
  if [ "$ARG_DEPTH" -gt "$HARD_CAP_DEPTH" ]; then
    err "--depth=$ARG_DEPTH exceeds hard cap $HARD_CAP_DEPTH"
    exit "$EXIT_INTERNAL"
  fi
  if [ -n "$ARG_FORMAT" ]; then
    case "$ARG_FORMAT" in
      json|table|md) ;;
      *) err "Invalid --format value: '$ARG_FORMAT' (must be json | table | md)"; exit "$EXIT_INTERNAL" ;;
    esac
  else
    if [ -t 1 ]; then ARG_FORMAT="table"; else ARG_FORMAT="json"; fi
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
  return 1
}

# ---------------------------------------------------------------------------
# Target resolution: absolute or repo-relative → repo-relative canonical form
# ---------------------------------------------------------------------------
resolve_target() {
  local input="$ARG_TARGET"
  local abs
  if [[ "$input" = /* ]]; then
    # Canonicalize the directory so a symlinked path (e.g. macOS /var -> /private/var,
    # as mktemp yields) resolves under a pwd -P repo root rather than reading as outside.
    if [ -e "$input" ]; then
      abs="$(cd "$(dirname "$input")" && pwd -P)/$(basename "$input")"
    else
      abs="$input"
    fi
  else
    if [ -e "$REPO_ROOT/$input" ]; then
      abs="$REPO_ROOT/$input"
    elif [ -e "$input" ]; then
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
  case "$abs" in
    "$REPO_ROOT"/*) TARGET_REL="${abs#"$REPO_ROOT"/}" ;;
    "$REPO_ROOT")   err "Target equals repo root: $abs"; exit "$EXIT_BAD_TARGET" ;;
    *)              err "Target $abs is outside repo root $REPO_ROOT"; exit "$EXIT_BAD_TARGET" ;;
  esac
  if path_under_exclusion "$TARGET_REL"; then
    err "Target is under an exclusion: $TARGET_REL"
    exit "$EXIT_EXCLUDED_TARGET"
  fi
}

# ---------------------------------------------------------------------------
# Build the code-file scan list for the software domain (newline-delimited
# repo-relative paths). Writes SCAN_LIST_FILE; sets TOTAL_FILES_SCANNED to the
# count of CODE files searched (domain-specific denominator per F4).
# ---------------------------------------------------------------------------
build_software_scan_list() {
  SCAN_LIST_FILE="$WORK_DIR/scan-list.txt"
  local find_args=( "$REPO_ROOT" -type f )
  find_args+=( "(" )
  local first=1 ext
  for ext in "${SOFTWARE_SCANNED_TYPES[@]}"; do
    if [ "$first" = "1" ]; then
      first=0
      find_args+=( -name "*.${ext}" )
    else
      find_args+=( -o -name "*.${ext}" )
    fi
  done
  find_args+=( ")" )

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
# Compute the language-native import tokens for a target code module.
#
# The import graph is discovered by matching how OTHER files name THIS module in
# their import/require/include statements. Emits one grep-token per line. Covers:
#   Python — the dotted module path (from repo root down to the file, minus .py) and
#            the bare module name: `from pkg.mod import`, `import pkg.mod`, `import mod`.
#   JS/TS  — the basename without extension and the relative-path stem, as they
#            appear in `from '...'` / `require('...')`: `foo`, `./foo`, `foo.js`.
#   C/C++  — the header basename as it appears in `#include "foo.h"`.
# Writes tokens (one per line) to IMPORT_TOKENS_FILE.
# ---------------------------------------------------------------------------
compute_import_tokens() {
  local target="$1"
  IMPORT_TOKENS_FILE="$WORK_DIR/import-tokens.txt"
  : > "$IMPORT_TOKENS_FILE"

  local base ext stem
  base="$(basename "$target")"
  ext="${base##*.}"
  stem="${base%.*}"

  # Always: the basename (as it appears in JS/TS/C include specifiers) and the stem.
  printf '%s\n' "$base" >> "$IMPORT_TOKENS_FILE"
  printf '%s\n' "$stem" >> "$IMPORT_TOKENS_FILE"

  case "$ext" in
    py)
      # Dotted module path from repo root: strip .py, translate / to .
      local dotted="${target%.py}"
      dotted="${dotted//\//.}"
      printf '%s\n' "$dotted" >> "$IMPORT_TOKENS_FILE"
      # Also the package-qualified tail forms (e.g. scripts.utils from a/b/scripts/utils.py)
      # so importers that use a shorter dotted path than the full repo path still match.
      local d="$dotted"
      while [[ "$d" == *.*.* ]]; do
        d="${d#*.}"
        printf '%s\n' "$d" >> "$IMPORT_TOKENS_FILE"
      done
      ;;
    js|jsx|ts|tsx|mjs|cjs)
      # relative-path stems commonly used in from '...' / require('...')
      printf './%s\n' "$stem" >> "$IMPORT_TOKENS_FILE"
      printf './%s\n' "$base" >> "$IMPORT_TOKENS_FILE"
      ;;
    c|h|cc|cpp|hpp)
      # header basename as written in #include "..."
      printf '%s\n' "$base" >> "$IMPORT_TOKENS_FILE"
      ;;
  esac

  # Dedup, drop empties
  sort -u "$IMPORT_TOKENS_FILE" -o "$IMPORT_TOKENS_FILE"
  sed -i.bak '/^$/d' "$IMPORT_TOKENS_FILE" 2>/dev/null || true
  rm -f "${IMPORT_TOKENS_FILE}.bak"
}

# ---------------------------------------------------------------------------
# software domain scanner — first-order import-graph fan-out.
#
# First-order = files that directly import/require/include the changed module.
# Produces a pre-aggregated match TSV ("<path>\t<line>\t<snippet>") of the import
# statement lines, then hands it to the shared aggregate_matches_v1 (empty mirror
# partner => is_mirror always false). Sets the FIRST_ORDER_* + SECOND_ORDER_* +
# FILTERED_MIRRORS_* globals build_json consumes.
#
# Import-statement discrimination: a line is an import ONLY if it BOTH names a token
# AND carries an import/require/include keyword — so a doc-comment mention of the
# module name is NOT counted (the doc-reference-vs-import-edge distinction § 12 draws).
# ---------------------------------------------------------------------------
scan_software() {
  local target="$1"

  compute_import_tokens "$target"

  local matches_raw="$WORK_DIR/matches-raw.txt"
  : > "$matches_raw"

  # Files to grep = the code scan list minus the target itself.
  local files_to_grep="$WORK_DIR/files-to-grep.txt"
  grep -vxF "$target" "$SCAN_LIST_FILE" > "$files_to_grep" || true

  if [ -s "$files_to_grep" ] && [ -s "$IMPORT_TOKENS_FILE" ]; then
    local files_abs="$WORK_DIR/files-abs.txt"
    awk -v root="$REPO_ROOT/" '{print root $0}' "$files_to_grep" > "$files_abs"

    # For each candidate file, find lines that (a) carry an import/require/include
    # keyword AND (b) name one of the target's import tokens. Two-stage grep:
    # first restrict to import-bearing lines, then keep those that mention a token.
    local tokens_pat="$WORK_DIR/tokens-pat.txt"
    # Escape regex metacharacters in tokens so they match literally.
    sed -e 's/[.[\*^$()+?{}|]/\\&/g' "$IMPORT_TOKENS_FILE" > "$tokens_pat"

    # import-keyword regex (language-native forms)
    local import_kw='(^|[^A-Za-z0-9_])(import|require|from|#include)([^A-Za-z0-9_]|$)'

    while IFS= read -r absf; do
      [ -z "$absf" ] && continue
      # grep -nE import-bearing lines, then filter to token-mentioning ones.
      grep -nE "$import_kw" "$absf" 2>/dev/null \
        | grep -Ff "$tokens_pat" 2>/dev/null \
        | while IFS= read -r hit; do
            # hit form: "<line>:<text>"; prepend the repo-rel path.
            local rel="${absf#"$REPO_ROOT"/}"
            local lno="${hit%%:*}"
            local txt="${hit#*:}"
            printf '%s\t%s\t%s\n' "$rel" "$lno" "$txt"
          done >> "$matches_raw" || true
    done < "$files_abs"
  fi

  # Dedup by (path,line), sorted deterministically — the TSV shape aggregate_matches_v1 expects.
  local parsed="$WORK_DIR/parsed.tsv"
  if [ -s "$matches_raw" ]; then
    LC_ALL=C sort -u -t $'\t' -k1,1 -k2,2n "$matches_raw" > "$parsed"
  else
    : > "$parsed"
  fi

  # Software domain: no mirror concept (empty partner => is_mirror always false),
  # mirrors never filtered.
  local bundle
  bundle="$(aggregate_matches_v1 "$parsed" "" "0")"

  FIRST_ORDER_JSON="$(printf '%s' "$bundle" | jq -c '.first_order')"
  FIRST_ORDER_COUNT="$(printf '%s' "$bundle" | jq -r '.first_order_count')"
  FILTERED_MIRRORS_JSON="$(printf '%s' "$bundle" | jq -c '.filtered_mirrors_detail')"
  FILTERED_MIRRORS_COUNT="$(printf '%s' "$bundle" | jq -r '.filtered_mirrors_count')"

  # second-order scoped OUT for software v1 (see header F4 note + ADR-068):
  # depth-2 import-graph traversal is a named follow-on, not claimed here.
  SECOND_ORDER_JSON="$(jq -n '[]')"
  SECOND_ORDER_COUNT=0
}

# ---------------------------------------------------------------------------
# Stub scanners — honest not-implemented (mirrors the § 12 opt-out posture). The
# plug-model is visible and the next wave has a named insertion point, without
# speculative component/solution logic (YAGNI).
# ---------------------------------------------------------------------------
scan_component() {
  err "scanner not yet implemented for domain: web (component dependency-tree fan-out is a named follow-on; use the § 12 manual opt-out record until it ships)"
  exit "$EXIT_SCANNER_NOT_IMPLEMENTED"
}
scan_solution() {
  err "scanner not yet implemented for domain: enterprise-platform (solution-component graph fan-out is a named follow-on; use the § 12 manual opt-out record until it ships)"
  exit "$EXIT_SCANNER_NOT_IMPLEMENTED"
}

# ---------------------------------------------------------------------------
# Domain → scanner dispatch (the plug-model selector).
# ---------------------------------------------------------------------------
dispatch_scanner() {
  local domain="$1"
  case "$domain" in
    software)                scan_software "$TARGET_REL" ;;
    web|component)           scan_component ;;
    enterprise-platform|solution) scan_solution ;;
    *)
      err "Invalid --domain: '$domain' (expected software | web | enterprise-platform)"
      exit "$EXIT_INTERNAL"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Build the schema-v1 document via the shared library.
# ---------------------------------------------------------------------------
build_json() {
  local elapsed="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Assert schema version parity with the sourced library before emit.
  if [ "$SCHEMA_VERSION" != "$SCHEMA_V1_EMIT_VERSION" ]; then
    err "schema version skew: domain-blast-radius=$SCHEMA_VERSION lib=$SCHEMA_V1_EMIT_VERSION"
    exit "$EXIT_INTERNAL"
  fi

  # include_mirrors is always false for non-doc domains (no mirror concept).
  build_json_v1 \
    "$CLI_VERSION" \
    "$TARGET_REL" \
    "$timestamp" \
    "$REPO_ROOT" \
    "$ARG_DEPTH" \
    "false" \
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
  local target depth total first_count second_count
  target=$(printf '%s' "$json" | jq -r '.target')
  depth=$(printf '%s' "$json" | jq -r '.depth')
  total=$(printf '%s' "$json" | jq -r '.stats.total_files_scanned')
  first_count=$(printf '%s' "$json" | jq -r '.stats.first_order_count')
  second_count=$(printf '%s' "$json" | jq -r '.stats.second_order_count')

  c_bold; printf 'Import-graph blast radius — '; c_reset; printf '%s\n' "$target"
  c_dim;  printf '  domain=%s  depth=%s  code_files_scanned=%s  (second-order scoped out for software v1)\n' \
    "$ARG_DOMAIN" "$depth" "$total"
  c_reset
  printf '\n'
  c_bold; printf 'First-order importers (%s)\n' "$first_count"; c_reset
  if [ "$first_count" -eq 0 ]; then
    c_dim; printf '  (none)\n'; c_reset
  else
    printf '%s' "$json" | jq -r '
      .first_order[]
      | "  " + (.reference_count|tostring) + "× " + .path
    '
  fi
  c_dim
  printf '\nUse --format=json for machine-readable output. See release/references/protocols/blast-radius-protocol.md § 12\n'
  c_reset
}

# ---------------------------------------------------------------------------
# Markdown presenter (off the JSON)
# ---------------------------------------------------------------------------
render_md() {
  local json="$1"
  local target depth total first_count second_count scanned_at
  target=$(printf '%s' "$json" | jq -r '.target')
  depth=$(printf '%s' "$json" | jq -r '.depth')
  total=$(printf '%s' "$json" | jq -r '.stats.total_files_scanned')
  first_count=$(printf '%s' "$json" | jq -r '.stats.first_order_count')
  second_count=$(printf '%s' "$json" | jq -r '.stats.second_order_count')
  scanned_at=$(printf '%s' "$json" | jq -r '.scanned_at')

  printf '# Import-graph blast radius — `%s`\n\n' "$target"
  printf '| Stat | Value |\n|---|---|\n'
  printf '| domain | %s |\n' "$ARG_DOMAIN"
  printf '| scanned_at | %s |\n' "$scanned_at"
  printf '| depth | %s |\n' "$depth"
  printf '| code_files_scanned | %s |\n' "$total"
  printf '| first_order_count | %s |\n' "$first_count"
  printf '| second_order_count | %s (scoped out for software v1) |\n\n' "$second_count"

  printf '## First-order importers (%s)\n\n' "$first_count"
  if [ "$first_count" -eq 0 ]; then
    printf '_(none)_\n'
  else
    printf '| Refs | Path |\n|---:|---|\n'
    printf '%s' "$json" | jq -r '
      .first_order[]
      | [ (.reference_count|tostring), .path ]
      | "| " + (.[0]) + " | `" + (.[1]) + "` |"
    '
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"
  check_deps

  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/domain-blast-radius.XXXXXX")"
  trap 'rm -rf "$WORK_DIR"' EXIT

  resolve_root
  resolve_target

  # Only the software path builds the code scan list; stub domains exit before this.
  case "$ARG_DOMAIN" in
    software) build_software_scan_list ;;
    *)        TOTAL_FILES_SCANNED=0 ;;
  esac

  local start_ts end_ts elapsed
  start_ts=$(date +%s)

  dispatch_scanner "$ARG_DOMAIN"

  end_ts=$(date +%s)
  elapsed=$((end_ts - start_ts))
  elapsed="${elapsed}.0"

  local json
  json=$(build_json "$elapsed")

  case "$ARG_FORMAT" in
    json)  printf '%s\n' "$json" ;;
    table) render_table "$json" ;;
    md)    render_md "$json" ;;
  esac

  exit "$EXIT_OK"
}

main "$@"
