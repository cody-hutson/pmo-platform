#!/bin/bash
# allowlist-add.sh — atomic-append helper for .claude/*-allowlist.txt files
#
# Part of: the bypass-permissions-readiness hardening.
#
# Usage:
#   ./.claude/hooks/allowlist-add.sh <allowlist-file> <entry> [--reason "why"]
#
# Validation:
#   - Allowlist file must be one of the known, hook-managed allowlists
#   - Entry must not be blank, must not already be present
#   - Append is atomic (mv-based)
#   - All additions are logged to .claude/hooks/allowlist-additions.log

set -euo pipefail

export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly DATE="/bin/date"
readonly PRINTF="/usr/bin/printf"
readonly MKTEMP="/usr/bin/mktemp"
readonly CAT="/bin/cat"
readonly MV="/bin/mv"

readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly CLAUDE_DIR="$(cd "${HOOK_DIR}/.." && pwd -P)"
readonly ADDITIONS_LOG="${HOOK_DIR}/allowlist-additions.log"

# Known allowlists (relative to $CLAUDE_DIR). Prevents appending to arbitrary files.
readonly KNOWN_ALLOWLISTS=(
  "${CLAUDE_DIR}/mcp-write-allowlist.txt"
  "${CLAUDE_DIR}/egress-allowlist.txt"
  "${CLAUDE_DIR}/webfetch-allowlist.txt"
  "${CLAUDE_DIR}/ssh-allowlist.txt"
  "${CLAUDE_DIR}/script-execution-allowlist.txt"
  "${CLAUDE_DIR}/skill-editor-exemption-list.txt"
  "${CLAUDE_DIR}/shell-injection-allowlist.txt"
  "${CLAUDE_DIR}/fs-boundary-allowlist.txt"
)

usage() {
  "$PRINTF" 'Usage: %s <allowlist-file> <entry> [--reason "why"]\n' "$0"
  "$PRINTF" '\nKnown allowlists:\n'
  for a in "${KNOWN_ALLOWLISTS[@]}"; do
    "$PRINTF" '  - %s\n' "$a"
  done
  exit 1
}

[ $# -ge 2 ] || usage

ALLOWLIST_FILE="$1"
ENTRY="$2"
REASON="${4:-(no reason given)}"

# Resolve allowlist file to absolute path
if [ -f "$ALLOWLIST_FILE" ]; then
  ALLOWLIST_ABS="$(cd "$(dirname "$ALLOWLIST_FILE")" && pwd -P)/$(basename "$ALLOWLIST_FILE")"
else
  # File doesn't exist — resolve what the path would be
  parent_dir="$(dirname "$ALLOWLIST_FILE")"
  if [ -d "$parent_dir" ]; then
    ALLOWLIST_ABS="$(cd "$parent_dir" && pwd -P)/$(basename "$ALLOWLIST_FILE")"
  else
    "$PRINTF" 'ERROR: parent directory does not exist: %s\n' "$parent_dir" >&2
    exit 1
  fi
fi

# Validate: target must be in the known-allowlist set
is_known=0
for a in "${KNOWN_ALLOWLISTS[@]}"; do
  if [ "$ALLOWLIST_ABS" = "$a" ]; then
    is_known=1
    break
  fi
done

if [ "$is_known" != 1 ]; then
  "$PRINTF" 'ERROR: %s is not a known allowlist file.\n' "$ALLOWLIST_ABS" >&2
  usage
fi

# Validate entry
if [ -z "$ENTRY" ]; then
  "$PRINTF" 'ERROR: empty entry\n' >&2
  exit 1
fi

# Reject entries with newlines / carriage returns (null bytes can't appear in bash vars)
case "$ENTRY" in
  *$'\n'*|*$'\r'*)
    "$PRINTF" 'ERROR: entry contains control characters\n' >&2
    exit 1
    ;;
esac

# Check if entry already present (comment-aware)
if [ -f "$ALLOWLIST_ABS" ] && "$GREP" -Fxq "$ENTRY" "$ALLOWLIST_ABS"; then
  "$PRINTF" 'Entry already present in %s:\n  %s\n' "$ALLOWLIST_ABS" "$ENTRY" >&2
  exit 0  # idempotent — not an error
fi

# Atomic append via temp-file rename
TMP="$("$MKTEMP" "${ALLOWLIST_ABS}.XXXXXX")"
if [ -f "$ALLOWLIST_ABS" ]; then
  "$CAT" "$ALLOWLIST_ABS" > "$TMP"
fi
# Ensure trailing newline before appending
if [ -s "$TMP" ] && [ "$(/usr/bin/tail -c 1 "$TMP")" != "" ]; then
  "$PRINTF" '\n' >> "$TMP"
fi
"$PRINTF" '%s\n' "$ENTRY" >> "$TMP"
"$MV" "$TMP" "$ALLOWLIST_ABS"

# Log the addition
ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ)"
"$PRINTF" '%s\t%s\t%s\t%s\n' "$ts" "$ALLOWLIST_ABS" "$ENTRY" "$REASON" >> "$ADDITIONS_LOG" 2>/dev/null || true

"$PRINTF" 'Added to %s:\n  %s\n' "$ALLOWLIST_ABS" "$ENTRY"
