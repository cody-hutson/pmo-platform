#!/bin/bash
# block-mcp-writes.sh — PreToolUse hook blocking unallowlisted MCP write-tool invocations.
# hook-owner: core/rules/bypass-mode-readiness/block-mcp-writes.md
#
# Addresses Red Team H3 (MCP write exfil), SRE H4 (verb over-match), UX H7/H8
# (default-deny without pre-seed + self-mod guard conflict).
#
# Scope: tool_name matching `mcp__*` with a write verb suffix.
# Verb pattern: (create|edit|update|delete|add|transition|share|attach|permission|
#               publish|invite|grant|export|copy|move|comment|post|send|email|
#               upload|import|replace|insert|remove|archive)(_|[A-Z]|$)
#   - Termination with _, uppercase letter, or end-of-string handles both snake_case
#     and camelCase MCP tool naming conventions.
#
# Warn-mode: reads .claude/hooks/.mode (shared with block-egress.sh).
# Allowlist: .claude/mcp-write-allowlist.txt (grep -Fxq — fixed-string, whole-line).
# Allowlist is Claude-writable (NOT protected by NEW-B self-mod guard) via
# .claude/hooks/allowlist-add.sh.
#
# Rule ID range: BLOCK-MCP-001..099

set -euo pipefail

export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

readonly HOOK_NAME="block-mcp-writes"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/mcp-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"
readonly ALLOWLIST="${HOOK_DIR}/../mcp-write-allowlist.txt"

# --- SHARED DEPENDENCY RESOLVER (fail CLOSED if the helper is missing/invalid) ---
# Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed
# `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN.
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
if [ ! -r "$DEP_LIB" ] || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1; then
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
  exit 2
fi
JQ="$(resolve_jq)"; readonly JQ

# Write-verb pattern (MUST stay in sync with audit-mcp-usage.sh WRITE_VERBS)
readonly WRITE_VERB_RE='^mcp__[^_]+__(create|edit|update|delete|add|transition|share|attach|permission|publish|invite|grant|export|copy|move|comment|post|send|email|upload|import|replace|insert|remove|archive)(_|[A-Z]|$)'

# --- ERROR HANDLERS ---
log_error() {
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- MODE DETECTION (defined before the dependency gate so a missing-jq decision
# can be mode-aware: enforce fails CLOSED, warn/off degrade to non-blocking). ---
get_mode() {
  local mode="enforce"
  if [ -f "$MODE_FILE" ]; then
    mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo enforce)"
  fi
  case "$mode" in
    warn|enforce|off) "$PRINTF" '%s' "$mode" ;;
    *) "$PRINTF" 'enforce' ;;
  esac
}

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33: the escape hatch must not sit behind
# the very dependency gate it is meant to let you past). jq-OPTIONAL. ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$JQ" ]; then
    btool="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null || echo unknown)"
    bcwd="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty' 2>/dev/null || echo unknown)"
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$btool" --arg cwd "$bcwd" \
      '{ts:$ts, hook:$hook, tool:$tool, cwd:$cwd, action:"bypass"}' >> "$BYPASS_LOG" 2>/dev/null || true
  else
    "$PRINTF" '{"ts":"%s","hook":"%s","action":"bypass","note":"jq-unresolved"}\n' "$ts" "$HOOK_NAME" >> "$BYPASS_LOG" 2>/dev/null || true
  fi
  exit 0
fi

# --- Master-activation gate (#310) — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# .mode read (precedence: bypass -> master -> .mode -> rule). CLASS=workflow: master-OFF
# makes this hook inert (exit 0). Fail-toward-current-behavior: a missing lib does NOT
# gate, so the hook keeps its existing .mode enforcement (a read failure never disables a
# guard). Read jq-free from the durable XDG platform-config.toml [security_hooks]. ---
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-gated). A security control that cannot evaluate its input
# must not block SOFTER than a rule match would: in enforce it fails CLOSED (exit 2);
# in warn/off it degrades to a non-blocking stderr note + exit 0 — because a warn-mode
# rule match itself never blocks (GHSA-9cjm-v22x-4x33). Runs AFTER the bypass short-
# circuit. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _jqmiss_mode="$(get_mode)"
  if [ "$_jqmiss_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED] jq not found; .mode=%s so not blocking (degraded — MCP write checks skipped for this call).\n' "$HOOK_NAME" "$_jqmiss_mode" >&2
  exit 0
fi

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the .mode / rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --- EARLY EXIT: non-MCP tool calls ---
case "$TOOL_NAME" in
  mcp__*) ;;  # fall through to rule check
  *) exit 0 ;;
esac

# sha256 digest for log evidence
digest() {
  "$PRINTF" '%s' "$1" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

log_warn() {
  local rule_id="$1"; local reason="$2"; local tool_digest="$3"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg reason "$reason" --arg tool_digest "$tool_digest" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, tool_digest:$tool_digest}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

# block-log writer (append-only, JSONL) — writes on every enforce-mode block
log_block() {
  local rule_id="$1"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$("$PRINTF" '%s' "$tool_input" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

apply_block() {
  local rule_id="$1"; local reason="$2"; local override="$3"
  local mode; mode="$(get_mode)"
  local tool_digest; tool_digest="$(digest "$TOOL_NAME")"

  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$tool_digest"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
      exit 0
      ;;
    off)
      exit 0
      ;;
    enforce|*)
      log_block "$rule_id"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
      exit 2
      ;;
  esac
}

# ==========================================================================
# RULE: BLOCK-MCP-001 — MCP write-verb tools not in allowlist
# ==========================================================================

# Check if tool name matches write-verb pattern
if ! "$PRINTF" '%s' "$TOOL_NAME" | "$GREP" -qE "$WRITE_VERB_RE"; then
  # Tool is an MCP tool but not a write verb — allow
  exit 0
fi

# Tool matches write-verb pattern — check allowlist
if [ -f "$ALLOWLIST" ] && "$GREP" -Fxq "$TOOL_NAME" "$ALLOWLIST"; then
  # Allowlisted — allow
  exit 0
fi

# Not allowlisted — block (or warn, per mode)
apply_block "BLOCK-MCP-001" \
  "MCP write tool not in allowlist: ${TOOL_NAME}." \
  "add via './.claude/hooks/allowlist-add.sh .claude/mcp-write-allowlist.txt ${TOOL_NAME}' — or set CLAUDE_HOOK_BYPASS=1"
