#!/bin/bash
# block-skill-direct-edit.sh — PreToolUse hook enforcing pmo-skill-editor invocation
#
# Gate 2 of the dual-gate skill-discipline enforcement.
# Rejects direct Write/Edit to pmo-platform/skills/<skill>/SKILL.md, reference/*.md,
# or references/*.md on migrated skills unless a valid pmo-skill-editor session
# sentinel is present. Both singular and plural reference-dir paths are matched
# during the migration window; post-migration hardening to plural-only is
# deferred to a future release.
#
# Matcher scope: Write, Edit
#
# Rule ID range: BLOCK-SKILL-EDIT-001..099
#
# Pattern: mirrors .claude/hooks/block-destructive.sh architecture exactly
# (PATH pinning, fail-open-on-missing-jq, fail-closed-on-malformed-input,
# CLAUDE_HOOK_BYPASS escape hatch with audit, .mode file for warn/enforce/off).

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly JQ="/usr/bin/jq"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"

# --- METADATA ---
readonly HOOK_NAME="block-skill-direct-edit"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/skill-edit-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"
readonly PRIMARY_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"
# EXEMPTION_LIST resolves relative to the hook's own directory (matches
# block-destructive.sh's SCRIPT_ALLOWLIST pattern). This ensures the hook
# finds the exemption list in whichever checkout it runs from — primary or
# worktree — which matters during engineering before deployment to primary.
readonly EXEMPTION_LIST="${HOOK_DIR}/../skill-editor-exemption-list.txt"
readonly SENTINEL_TTL_SECONDS=1800  # 30 minutes

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-evaluation error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- DEPENDENCY CHECK (jq required; fail-OPEN on missing, matching block-destructive.sh) ---
if [ ! -x "$JQ" ] && ! command -v jq >/dev/null 2>&1; then
  log_error "DEPENDENCY-MISSING: jq not found (tried $JQ and PATH=$PATH)"
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-WARN] jq not found. Security hook DEGRADED (fail-open). Install: brew install jq (or ensure /usr/bin/jq exists).\n' "$HOOK_NAME" >&2
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

# --- SCOPE CHECK — only act on pmo-platform/skills/<skill>/SKILL.md, reference/*.md, or references/*.md ---
case "$FILE_PATH" in
  */pmo-platform/skills/*/SKILL.md|*/pmo-platform/skills/*/reference/*.md|*/pmo-platform/skills/*/references/*.md) ;;
  pmo-platform/skills/*/SKILL.md|pmo-platform/skills/*/reference/*.md|pmo-platform/skills/*/references/*.md) ;;
  *) exit 0 ;;
esac

# --- EXTRACT SKILL NAME ---
skill="$("$PRINTF" '%s' "$FILE_PATH" | /usr/bin/sed -nE 's|.*/?pmo-platform/skills/([^/]+)/.*|\1|p')"
if [ -z "$skill" ]; then
  log_error "SCOPE-PARSE-ERROR: could not extract skill name from $FILE_PATH"
  exit 0  # fail-open on parse failure (defensive)
fi

# --- EXEMPTION LIST check ---
if [ -f "$EXEMPTION_LIST" ] && "$GREP" -Fxq "$skill" "$EXEMPTION_LIST" 2>/dev/null; then
  exit 0  # canary or operator-exempted skill
fi

# --- PRE-MIGRATION pass-through ---
# Non-breaking on legacy: if the skill has NOT yet landed the migration marker
# (via per-skill migration commits), the gate is not yet active on that skill.
SKILL_MD="pmo-platform/skills/$skill/SKILL.md"
if [ ! -f "$SKILL_MD" ]; then
  # Try absolute-path form in case Claude's cwd differs from skill root
  SKILL_MD_ABS="${PRIMARY_ROOT}/pmo-platform/skills/$skill/SKILL.md"
  [ -f "$SKILL_MD_ABS" ] && SKILL_MD="$SKILL_MD_ABS"
fi
if [ -f "$SKILL_MD" ] && ! "$GREP" -qE '^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$' "$SKILL_MD"; then
  exit 0  # not yet gated
fi

# --- SENTINEL check ---
SENTINEL="pmo-platform/skills/$skill/.editor-session"
if [ ! -f "$SENTINEL" ]; then
  SENTINEL_ABS="${PRIMARY_ROOT}/pmo-platform/skills/$skill/.editor-session"
  [ -f "$SENTINEL_ABS" ] && SENTINEL="$SENTINEL_ABS"
fi

# --- MODE check ---
MODE="enforce"
if [ -f "$MODE_FILE" ]; then
  mode_raw="$(/bin/cat "$MODE_FILE" 2>/dev/null | /usr/bin/tr -d '[:space:]')"
  case "$mode_raw" in
    warn|enforce|off) MODE="$mode_raw" ;;
  esac
fi
[ "$MODE" = "off" ] && exit 0

# --- HELPERS ---
digest() {
  "$PRINTF" '%s' "$1" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

log_block() {
  local rule_id="$1"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input
  tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest
  input_digest="$(digest "$tool_input")"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg skill "$skill" --arg path "$FILE_PATH" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, skill:$skill, file_path:$path}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

log_warn() {
  local rule_id="$1"
  local reason="$2"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg skill "$skill" --arg path "$FILE_PATH" --arg reason "$reason" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, skill:$skill, file_path:$path, reason:$reason}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

apply_block() {
  local rule_id="$1"
  local reason="$2"
  local override="$3"
  if [ "$MODE" = "warn" ]; then
    log_warn "$rule_id" "$reason"
    "$PRINTF" '[CLAUDE-HOOK:%s:%s:WARN] %s (warn-mode active — not blocking; would block in enforce-mode)\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
    exit 0
  fi
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# Determine rule ID based on file type in scope
case "$FILE_PATH" in
  */SKILL.md|pmo-platform/skills/*/SKILL.md) RULE_ID="BLOCK-SKILL-EDIT-001" ;;
  *) RULE_ID="BLOCK-SKILL-EDIT-002" ;;
esac

# --- SENTINEL presence ---
if [ ! -f "$SENTINEL" ]; then
  apply_block "$RULE_ID" \
    "Direct edit to $FILE_PATH denied — no pmo-skill-editor session marker at pmo-platform/skills/$skill/.editor-session (skill has migration marker; gate active)." \
    "invoke pmo-skill-editor Mode A to start an editing session, OR exit claude and relaunch with CLAUDE_HOOK_BYPASS=1 claude"
fi

# --- SENTINEL parse ---
if ! "$JQ" -e . "$SENTINEL" >/dev/null 2>&1; then
  apply_block "$RULE_ID" \
    "Editor session sentinel at $SENTINEL is malformed (not valid JSON)" \
    "remove the sentinel and re-invoke pmo-skill-editor, OR set CLAUDE_HOOK_BYPASS=1"
fi

# --- TARGET-SKILL match ---
target_skill="$("$JQ" -r '.target_skill // empty' "$SENTINEL" 2>/dev/null)"
if [ "$target_skill" != "$skill" ]; then
  apply_block "$RULE_ID" \
    "Sentinel target_skill='$target_skill' does not match edit target '$skill'" \
    "ensure pmo-skill-editor session is on the correct skill, OR set CLAUDE_HOOK_BYPASS=1"
fi

# --- TTL check ---
started_at="$("$JQ" -r '.started_at // empty' "$SENTINEL" 2>/dev/null)"
if [ -z "$started_at" ]; then
  apply_block "$RULE_ID" \
    "Sentinel at $SENTINEL missing started_at field" \
    "re-invoke pmo-skill-editor, OR set CLAUDE_HOOK_BYPASS=1"
fi

# BSD date for ISO-8601 UTC parsing; trailing Z stripped for -f pattern
started_clean="${started_at%Z}"
started_epoch="$($DATE -j -u -f '%Y-%m-%dT%H:%M:%S' "$started_clean" '+%s' 2>/dev/null || echo '')"
now_epoch="$($DATE -u '+%s')"

if [ -z "$started_epoch" ]; then
  apply_block "$RULE_ID" \
    "Sentinel started_at='$started_at' is not a parseable ISO-8601 UTC timestamp" \
    "re-invoke pmo-skill-editor, OR set CLAUDE_HOOK_BYPASS=1"
fi

age=$((now_epoch - started_epoch))
if [ "$age" -lt 0 ]; then
  apply_block "$RULE_ID" \
    "Editor session sentinel has future timestamp (started_at=$started_at; current=$($DATE -u '+%Y-%m-%dT%H:%M:%SZ'))" \
    "reset system clock OR invoke pmo-skill-editor Mode A to regenerate sentinel"
fi
if [ "$age" -gt "$SENTINEL_TTL_SECONDS" ]; then
  apply_block "$RULE_ID" \
    "Editor session sentinel stale (age=${age}s > ${SENTINEL_TTL_SECONDS}s TTL); session expired" \
    "re-invoke pmo-skill-editor to refresh the session, OR set CLAUDE_HOOK_BYPASS=1"
fi

# All checks passed — allow
exit 0
