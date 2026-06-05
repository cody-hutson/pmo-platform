#!/bin/bash
# block-fragile-refs.sh — PreToolUse hook enforcing the reference-durability standard
#
# Reference-durability issue (v3.18-corpus-integrity-enforcement):
# Flags fragile references on net-new/modified content destined for durable-corpus
# paths, per core/standards/reference-durability-standard.md. Three detectors:
#   - Class L (BLOCK-FRAGILE-REF-001): markdown link sequences  ]( on a content line
#   - Class V (BLOCK-FRAGILE-REF-002): version-cutover apparatus (idiom + version token)
#   - Positional issue-reference (BLOCK-FRAGILE-REF-003): a bare #N outside a designated
#     reference block, OR a content-free #N inside one (rung-5 "summarize inline" guard)
#
# Matcher scope: Write, Edit
#
# Rule ID range: BLOCK-FRAGILE-REF-001..099
#
# Pattern: mirrors core/hooks/block-skill-direct-edit.sh architecture exactly
# (PATH pinning, fail-open-on-missing-jq, fail-closed-on-malformed-input,
# CLAUDE_HOOK_BYPASS escape hatch with audit, shared .mode file for warn/enforce/off).
#
# Detection scope rationale: the detector flags Class L + Class V wholesale and applies
# a POSITIONAL rule to issue references. It deliberately does NOT classify an issue
# reference as inline-grammar versus provenance-footnote — that classification cannot
# be separated lexically with acceptable precision. The positional rule (block-presence
# + line-self-description) is a deterministic shape test, not a semantic classifier.

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly JQ="/usr/bin/jq"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly AWK="/usr/bin/awk"
readonly SED="/usr/bin/sed"

# --- METADATA ---
readonly HOOK_NAME="block-fragile-refs"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/fragile-ref-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"
# ALLOWLIST resolves relative to the hook's own directory (matches the sibling hook's
# exemption-list pattern). This finds the allowlist in whichever checkout the hook runs
# from — primary or worktree — which matters during engineering before deployment.
readonly ALLOWLIST="${HOOK_DIR}/reference-durability-allowlist.txt"

# --- THE FLAGGED-CLASS PATTERNS (validated against core/hooks/testdata/cutover-fixtures.txt) ---
# Class L — markdown link sequence (fenced code blocks are stripped before scanning).
readonly LINK_RE='\]\('
# Class V — version-cutover apparatus. Keyed on the cutover IDIOM proximate to a version
# token, with bounded windows so a benign sentence naming a version does not match:
#   (a) version token within 40 non-period chars of "merge SHA"
#   (b) version token immediately governing "exempt" (optional release/itself/is)
#   (c) "applies to releases" / "Cutover applies|discipline|per" within 80 chars of a version token
#   (d) the "reflexive-pipeline-loop" cutover idiom
# A bare version label naming the current line ("v2.1 is now current") does NOT match.
readonly CUTOVER_RE='v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?[^.\n]{0,40}merge SHA|v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?([[:space:]]+(release|itself|is))*[[:space:]]+(is[[:space:]]+)?exempt|([Aa]pplies to releases|[Cc]utover[[:space:]]+(applies|discipline|per))[^.\n]{0,80}v[0-9]+\.[0-9]+|reflexive-pipeline-loop'
# Reference-block header (reuses the parser-clean anchor-regex shape; H1-H6, lenient colon).
readonly REFBLOCK_RE='^#{1,6}[[:space:]]+([Ii]ssue [Rr]eferences|[Rr]eferences|[Pp]rovenance|[Ss]ources?)[[:space:]]*:?[[:space:]]*$'
# A bare issue reference: a # followed by digits, optionally bracketed (matches #42, #[42]).
readonly ISSUEREF_RE='#\[?[0-9]+\]?'
# Minimum non-reference word count required on an in-block issue-reference line for it to
# count as self-describing (operationalizes the durability-ladder rung-5 "summarize inline").
readonly MIN_SELFDESCRIBE_WORDS=3

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-evaluation error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- DEPENDENCY CHECK (jq required; fail-OPEN on missing, matching the sibling hook) ---
if [ ! -x "$JQ" ] && ! command -v jq >/dev/null 2>&1; then
  log_error "DEPENDENCY-MISSING: jq not found (tried $JQ and PATH=$PATH)"
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-WARN] jq not found. Reference-durability hook DEGRADED (fail-open). Install: brew install jq (or ensure /usr/bin/jq exists).\n' "$HOOK_NAME" >&2
  exit 0
fi

# --- READ & VALIDATE INPUT ---
INPUT="$(cat)"

if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON on stdin"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"

# Only handle Write and Edit (settings.json matchers constrain, but defense-in-depth)
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# --- CLAUDE_HOOK_BYPASS escape hatch ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$TOOL_NAME" \
    '{ts:$ts, hook:$hook, tool:$tool, action:"bypass"}' \
    >> "$BYPASS_LOG" 2>/dev/null || true
  exit 0
fi

FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
[ -z "$FILE_PATH" ] && exit 0

# --- SCOPE CHECK — act ONLY on durable-corpus paths ---
# Matches both absolute (worktree/primary) and repo-relative forms. Transient surfaces
# (chat, GitHub comments, operator-instance gitignored tree, PR bodies) are structurally
# out of reach — the hook only sees a Write/Edit file_path, so anything not matching a
# durable glob below exits 0 untouched.
case "$FILE_PATH" in
  */core/rules/*.md|core/rules/*.md) ;;
  */core/standards/*.md|core/standards/*.md) ;;
  */core/specs/*.md|core/specs/*.md) ;;
  */core/disciplines/*.md|core/disciplines/*.md) ;;
  */core/schemas/*.md|core/schemas/*.md) ;;
  */release/references/*.md|release/references/*.md) ;;
  */release/governance/*.md|release/governance/*.md) ;;
  */release/standards/*.md|release/standards/*.md) ;;
  */release/specs/*.md|release/specs/*.md) ;;
  */release/schemas/*.md|release/schemas/*.md) ;;
  */skills/*/SKILL.md|skills/*/SKILL.md) ;;
  */skills/*/references/*.md|skills/*/references/*.md) ;;
  */release/releases/plans/*_RELEASE_PLAN.md|release/releases/plans/*_RELEASE_PLAN.md) ;;
  *) exit 0 ;;
esac

# --- PATH ALLOWLIST check (glob-per-line; trailing slash = directory; # = comment) ---
if [ -f "$ALLOWLIST" ]; then
  while IFS= read -r _glob || [ -n "$_glob" ]; do
    # strip comments + whitespace
    _glob="${_glob%%#*}"
    _glob="$(printf '%s' "$_glob" | "$SED" 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "$_glob" ] && continue
    case "$_glob" in
      */) # directory prefix match (allow both absolute and relative)
        case "$FILE_PATH" in
          *"$_glob"*) exit 0 ;;
        esac
        ;;
      *)  # file/glob match
        case "$FILE_PATH" in
          $_glob|*"/$_glob") exit 0 ;;
        esac
        ;;
    esac
  done < "$ALLOWLIST"
fi

# --- EXTRACT INCOMING CONTENT ---
# Write carries .tool_input.content; Edit carries .tool_input.new_string.
CONTENT="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.content // .tool_input.new_string // empty')"
[ -z "$CONTENT" ] && exit 0

# --- PER-FILE OVERRIDE MARKERS (suppress a class for this file; matches still reported) ---
ALLOW_LINK=0
ALLOW_VERSION=0
if "$PRINTF" '%s\n' "$CONTENT" | "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-link[[:space:]]*-->'; then
  ALLOW_LINK=1
fi
if "$PRINTF" '%s\n' "$CONTENT" | "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-version-ref[[:space:]]*-->'; then
  ALLOW_VERSION=1
fi

# --- MODE check (shared harness .mode; warn|enforce|off) ---
MODE="warn"
if [ -f "$MODE_FILE" ]; then
  mode_raw="$(/bin/cat "$MODE_FILE" 2>/dev/null | /usr/bin/tr -d '[:space:]')"
  case "$mode_raw" in
    warn|enforce|off) MODE="$mode_raw" ;;
  esac
fi
[ "$MODE" = "off" ] && exit 0

# --- FENCE STRIP — remove fenced code blocks (``` delimited) before scanning ---
# Detectors must not fire on illustrative content inside code fences.
STRIPPED="$("$PRINTF" '%s\n' "$CONTENT" | "$AWK" '
  /^[[:space:]]*```/ { infence = !infence; next }
  !infence { print }
')"

# --- DETECTORS ---
# Each detector returns matched lines (line-numbered against the stripped content) or empty.
link_matches=""
version_matches=""
issueref_matches=""

if [ "$ALLOW_LINK" -eq 0 ]; then
  link_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$LINK_RE" || true)"
fi
if [ "$ALLOW_VERSION" -eq 0 ]; then
  version_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$CUTOVER_RE" || true)"
fi

# Positional issue-reference detector (always on; not governed by the link/version markers).
# Pass 1: locate the FIRST reference-block header line number (0 = none present).
refblock_line="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$REFBLOCK_RE" | /usr/bin/head -1 | /usr/bin/cut -d: -f1 || true)"
[ -z "$refblock_line" ] && refblock_line=0

# Pass 2: walk each line; flag a bare issue ref that is (a) before the block / no block, or
# (b) inside the block but not self-describing (too few non-reference words on the line).
issueref_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$AWK" \
  -v refline="$refblock_line" \
  -v issuere="$ISSUEREF_RE" \
  -v minwords="$MIN_SELFDESCRIBE_WORDS" '
  BEGIN { infence = 0 }
  {
    line = $0
    # skip blank lines
    if (line ~ /^[[:space:]]*$/) next
    # does this line carry a bare issue reference?
    if (line !~ issuere) next
    in_block = (refline > 0 && NR >= refline)
    if (!in_block) {
      printf "%d:OUTSIDE-BLOCK:%s\n", NR, line
    } else {
      # self-describing check: count words that are NOT the issue reference token
      tmp = line
      gsub(issuere, " ", tmp)        # remove the issue ref(s)
      gsub(/^[#>*[:space:]-]+/, "", tmp)  # strip leading markdown/list punctuation
      n = split(tmp, parts, /[[:space:]]+/)
      words = 0
      for (i = 1; i <= n; i++) { if (parts[i] ~ /[A-Za-z]/) words++ }
      if (words < minwords) {
        printf "%d:CONTENT-FREE-IN-BLOCK:%s\n", NR, line
      }
    }
  }
' || true)"

# --- AGGREGATE + REPORT ---
have_findings=0
[ -n "$link_matches" ] && have_findings=1
[ -n "$version_matches" ] && have_findings=1
[ -n "$issueref_matches" ] && have_findings=1

[ "$have_findings" -eq 0 ] && exit 0

# --- LOGGING HELPERS ---
log_warn() {
  local rule_id="$1" reason="$2"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg path "$FILE_PATH" --arg reason "$reason" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, file_path:$path, reason:$reason}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

log_block() {
  local rule_id="$1"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg path "$FILE_PATH" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, file_path:$path}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# Build a human-readable finding summary for stderr.
build_report() {
  if [ -n "$link_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-001] Class L (markdown link) on:\n%s\n' "$link_matches"
  fi
  if [ -n "$version_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-002] Class V (version-cutover apparatus) on:\n%s\n' "$version_matches"
  fi
  if [ -n "$issueref_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-003] issue-reference placement on:\n%s\n' "$issueref_matches"
  fi
}

REPORT="$(build_report)"
readonly TEACH="Rewrite as an inline summary (durability-ladder rung 1-2), or confine an unavoidable issue reference to a designated reference block with a summary noun phrase. Per-file escape: add an HTML comment '<!-- reference-durability: allow-link -->' or '<!-- reference-durability: allow-version-ref -->'. See core/standards/reference-durability-standard.md."

if [ "$MODE" = "warn" ]; then
  [ -n "$link_matches" ]     && log_warn "BLOCK-FRAGILE-REF-001" "Class L markdown link in $FILE_PATH"
  [ -n "$version_matches" ]  && log_warn "BLOCK-FRAGILE-REF-002" "Class V version-cutover apparatus in $FILE_PATH"
  [ -n "$issueref_matches" ] && log_warn "BLOCK-FRAGILE-REF-003" "issue-reference placement in $FILE_PATH"
  "$PRINTF" '[CLAUDE-HOOK:%s:RULE:WARN] fragile reference(s) in %s (warn-mode active — not blocking; would block in enforce-mode):\n%s\n%s\n' \
    "$HOOK_NAME" "$FILE_PATH" "$REPORT" "$TEACH" >&2
  exit 0
fi

# enforce-mode
[ -n "$link_matches" ]     && log_block "BLOCK-FRAGILE-REF-001"
[ -n "$version_matches" ]  && log_block "BLOCK-FRAGILE-REF-002"
[ -n "$issueref_matches" ] && log_block "BLOCK-FRAGILE-REF-003"
"$PRINTF" '[CLAUDE-HOOK:%s:RULE] BLOCKED: fragile reference(s) in %s:\n%s\nOverride: %s\n' \
  "$HOOK_NAME" "$FILE_PATH" "$REPORT" "$TEACH" >&2
exit 2
