#!/bin/bash
# audit-mcp-usage.sh — scan Claude Code session logs for MCP write-tool invocations.
#
# Output: unique fully-qualified MCP tool names (one per line, alphabetically sorted),
# filtered to those matching the write-verb pattern used by block-mcp-writes.sh.
#
# Usage:
#   ./audit-mcp-usage.sh                              # scan all session logs
#   ./audit-mcp-usage.sh --days 30                    # scan logs from last 30 days
#   ./audit-mcp-usage.sh --output .claude/mcp-write-allowlist.txt   # write to allowlist
#
# This is a ONE-SHOT seeding tool — not run by any hook at tool-call time.

set -euo pipefail

export PATH="/usr/bin:/bin"
readonly JQ="/usr/bin/jq"
readonly GREP="/usr/bin/grep"
readonly FIND="/usr/bin/find"
readonly SORT="/usr/bin/sort"
# Claude Code encodes the project dir as the workspace path with '/'→'-'.
# Derive from $HOME + the (optionally configured) workspace root, so no operator
# home path is embedded in the tracked hook.
readonly _amu_ws="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"
readonly SESSIONS_DIR="${HOME}/.claude/projects/$(printf '%s' "$_amu_ws" | /usr/bin/tr '/' '-')"

# Write-verb pattern (MUST stay in sync with block-mcp-writes.sh RULE-MCP-001)
readonly WRITE_VERBS='(create|edit|update|delete|add|transition|share|attach|permission|publish|invite|grant|export|copy|move|comment|post|send|email|upload|import|replace|insert|remove|archive)'

DAYS=""
OUTPUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="$2"; shift 2;;
    --output) OUTPUT="$2"; shift 2;;
    --help|-h)
      /usr/bin/printf 'Usage: %s [--days N] [--output PATH]\n' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

# Build find command for session logs
find_args=("$SESSIONS_DIR" -type f -name '*.jsonl')
if [ -n "$DAYS" ]; then
  find_args+=(-mtime "-${DAYS}")
fi

# Scan logs: extract tool names from tool_use blocks; filter to mcp__* with write verb;
# exact-verb-termination check via `(_|$)` (mirrors the hook's regex).
collected="$("$FIND" "${find_args[@]}" -print0 2>/dev/null | while IFS= read -r -d '' f; do
  # Each line in the jsonl may contain tool_use blocks; try both Messages API shape and session-log shape
  "$JQ" -r '
    .. | objects | select(.type == "tool_use") | .name
  ' "$f" 2>/dev/null || true
done)"

# Filter to MCP write verbs (pattern must match hook's regex)
# Verb termination: underscore (snake_case) OR uppercase (camelCase boundary) OR end-of-string
filtered="$(/usr/bin/printf '%s\n' "$collected" | "$GREP" -E "^mcp__[^_]+__${WRITE_VERBS}(_|[A-Z]|$)" || true)"

# Dedup and sort
unique="$(/usr/bin/printf '%s\n' "$filtered" | "$SORT" -u | "$GREP" -v '^$' || true)"

if [ -n "$OUTPUT" ]; then
  # Write header + entries
  {
    /usr/bin/printf '# MCP Write-Tool Allowlist — block-mcp-writes.sh BLOCK-MCP-001\n'
    /usr/bin/printf '#\n'
    /usr/bin/printf '# Pre-seeded from session-log audit: %s\n' "$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)"
    /usr/bin/printf '# Source: %s\n' "$SESSIONS_DIR"
    /usr/bin/printf '# Write verbs matched: %s\n' "$WRITE_VERBS"
    /usr/bin/printf '#\n'
    /usr/bin/printf '# Format: one fully-qualified tool name per line (grep -Fxq fixed-string match)\n'
    /usr/bin/printf '# Comments start with #. Add entries via ./.claude/hooks/allowlist-add.sh\n'
    /usr/bin/printf '#\n'
    /usr/bin/printf '# ---\n'
    /usr/bin/printf '\n'
    /usr/bin/printf '%s\n' "$unique"
  } > "$OUTPUT"
  count="$(/usr/bin/printf '%s\n' "$unique" | "$GREP" -c '^mcp__' || true)"
  /usr/bin/printf 'Wrote %s entries to %s\n' "$count" "$OUTPUT" >&2
else
  /usr/bin/printf '%s\n' "$unique"
fi
