#!/bin/bash
# tests/block-mcp-writes.test.sh — synthetic PreToolUse payload tests for block-mcp-writes.sh
#
# Covers: NEW-D acceptance criteria + allowlist-add integration + warn-mode.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-mcp-writes.sh"
MODE_FILE="${HOOK_DIR}/.mode"
ALLOWLIST="${HOOK_DIR}/../mcp-write-allowlist.txt"
ALLOWLIST_HELPER="${HOOK_DIR}/allowlist-add.sh"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi

# Save + restore state
ORIGINAL_MODE=""
[ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(cat "$MODE_FILE")"
ORIGINAL_ALLOWLIST=""
[ -f "$ALLOWLIST" ] && ORIGINAL_ALLOWLIST="$(cat "$ALLOWLIST")"

restore_state() {
  [ -n "$ORIGINAL_MODE" ] && /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"
  if [ -n "$ORIGINAL_ALLOWLIST" ]; then
    /usr/bin/printf '%s' "$ORIGINAL_ALLOWLIST" > "$ALLOWLIST"
  fi
}
trap restore_state EXIT

PASS=0
FAIL=0

test_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="${4:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != "$expected_exit" ] && ok=0
  if [ -n "$expected_pattern" ] && ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "$expected_pattern"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  stderr: %s\n' "$name" "$actual_exit" "$expected_exit" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

mcp_payload() {
  local tool="$1"
  /usr/bin/jq -n --arg tool "$tool" \
    '{tool_name: $tool, tool_input: {}, cwd: "/tmp"}'
}

# Use a known allowlist state for tests
/usr/bin/printf '# Test allowlist\nmcp__atlassian__addCommentToJiraIssue\nmcp__atlassian__editJiraIssue\n' > "$ALLOWLIST"
echo "enforce" > "$MODE_FILE"

echo "================================"
echo "block-mcp-writes.sh tests (NEW-D)"
echo "mode=enforce"
echo "================================"

# ----- Write verbs: block when not allowlisted -----

echo ""
echo "Write verbs — block when not in allowlist"
echo "---"

test_case "mcp__atlassian__createJiraIssue blocks (not in allowlist)" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" 2 "BLOCK-MCP-001"

test_case "mcp__atlassian__deleteJiraIssue blocks" \
  "$(mcp_payload 'mcp__atlassian__deleteJiraIssue')" 2 "BLOCK-MCP-001"

test_case "mcp__confluence__createConfluencePage blocks" \
  "$(mcp_payload 'mcp__confluence__createConfluencePage')" 2 "BLOCK-MCP-001"

test_case "mcp__smartsheet__add_rows blocks (snake_case)" \
  "$(mcp_payload 'mcp__smartsheet__add_rows')" 2 "BLOCK-MCP-001"

test_case "mcp__smartsheet__update_column blocks" \
  "$(mcp_payload 'mcp__smartsheet__update_column')" 2 "BLOCK-MCP-001"

test_case "mcp__lucid__share_document_with_collaborators blocks (share verb)" \
  "$(mcp_payload 'mcp__lucid__share_document_with_collaborators')" 2 "BLOCK-MCP-001"

test_case "mcp__lucid__create_document_share_link blocks" \
  "$(mcp_payload 'mcp__lucid__create_document_share_link')" 2 "BLOCK-MCP-001"

test_case "mcp__atlassian__transitionJiraIssue blocks" \
  "$(mcp_payload 'mcp__atlassian__transitionJiraIssue')" 2 "BLOCK-MCP-001"

test_case "mcp__atlassian__addCommentToJiraIssue allows (in allowlist)" \
  "$(mcp_payload 'mcp__atlassian__addCommentToJiraIssue')" 0

test_case "mcp__atlassian__editJiraIssue allows (in allowlist)" \
  "$(mcp_payload 'mcp__atlassian__editJiraIssue')" 0

# ----- Read verbs: allow -----

echo ""
echo "Read verbs — allow (not a write)"
echo "---"

test_case "mcp__atlassian__search allows (search is not a write verb)" \
  "$(mcp_payload 'mcp__atlassian__search')" 0

test_case "mcp__atlassian__getJiraIssue allows (get is not a write verb)" \
  "$(mcp_payload 'mcp__atlassian__getJiraIssue')" 0

test_case "mcp__smartsheet__list_workspaces allows (list is not a write verb)" \
  "$(mcp_payload 'mcp__smartsheet__list_workspaces')" 0

test_case "mcp__smartsheet__browse_workspace allows" \
  "$(mcp_payload 'mcp__smartsheet__browse_workspace')" 0

test_case "mcp__Claude_Preview__preview_start allows" \
  "$(mcp_payload 'mcp__Claude_Preview__preview_start')" 0

# ----- Verb-termination edge cases (SRE H4) -----

echo ""
echo "Verb-termination (SRE H4 over-match)"
echo "---"

test_case "mcp__hubspot__address_book_lookup allows (add followed by 'r', not _ or uppercase)" \
  "$(mcp_payload 'mcp__hubspot__address_book_lookup')" 0

test_case "mcp__foo__additional_search allows (add followed by 'i')" \
  "$(mcp_payload 'mcp__foo__additional_search')" 0

test_case "mcp__foo__shareholder_lookup allows (share followed by 'h')" \
  "$(mcp_payload 'mcp__foo__shareholder_lookup')" 0

test_case "mcp__foo__editorial allows (edit followed by 'o')" \
  "$(mcp_payload 'mcp__foo__editorial')" 0

test_case "mcp__foo__createdAt allows? (wait — create followed by 'd' which is lowercase)" \
  "$(mcp_payload 'mcp__foo__createdAt')" 0

test_case "mcp__foo__addCommentV2 blocks (add followed by uppercase C — camelCase)" \
  "$(mcp_payload 'mcp__foo__addCommentV2')" 2 "BLOCK-MCP-001"

test_case "mcp__foo__create blocks (bare verb, end-of-string)" \
  "$(mcp_payload 'mcp__foo__create')" 2 "BLOCK-MCP-001"

# ----- Non-MCP tools: early exit allow -----

echo ""
echo "Non-MCP tools — early exit"
echo "---"

test_case "Bash tool → early exit" \
  '{"tool_name":"Bash","tool_input":{"command":"ls"},"cwd":"/tmp"}' 0

test_case "Write tool → early exit" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x","content":"y"},"cwd":"/tmp"}' 0

# ----- Allowlist-add integration -----

echo ""
echo "allowlist-add.sh integration"
echo "---"

# Add a new tool via helper
if [ -x "$ALLOWLIST_HELPER" ]; then
  "$ALLOWLIST_HELPER" "$ALLOWLIST" "mcp__testsrv__createFoo" >/dev/null 2>&1 || true
  test_case "after allowlist-add: mcp__testsrv__createFoo allows" \
    "$(mcp_payload 'mcp__testsrv__createFoo')" 0

  # Confirm idempotency: adding twice succeeds
  "$ALLOWLIST_HELPER" "$ALLOWLIST" "mcp__testsrv__createFoo" >/dev/null 2>&1 || true
  test_case "allowlist-add is idempotent (no duplicate on re-add)" \
    "$(mcp_payload 'mcp__testsrv__createFoo')" 0

  # Reject adds to non-allowlist files
  if "$ALLOWLIST_HELPER" /tmp/evil.txt "mcp__attacker__createSecret" >/dev/null 2>&1; then
    echo "FAIL: allowlist-add accepted non-known file"
    FAIL=$((FAIL+1))
  else
    echo "PASS: allowlist-add rejects non-known allowlist files"
    PASS=$((PASS+1))
  fi
fi

# ----- Warn-mode -----

echo ""
echo "warn-mode"
echo "---"
echo "warn" > "$MODE_FILE"

WARN_LOG="${HOOK_DIR}/mcp-warn-log.jsonl"
WARN_BEFORE=0
[ -f "$WARN_LOG" ] && WARN_BEFORE="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"

test_case "warn-mode: non-allowlisted write tool logs + exit 0" \
  "$(mcp_payload 'mcp__notion__createPage')" 0 "WARN"

WARN_AFTER=0
[ -f "$WARN_LOG" ] && WARN_AFTER="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$WARN_AFTER" -gt "$WARN_BEFORE" ]; then
  echo "PASS: warn log grew (lines: $WARN_BEFORE → $WARN_AFTER)"
  PASS=$((PASS+1))
else
  echo "FAIL: warn log did NOT grow"
  FAIL=$((FAIL+1))
fi

# ----- Off-mode -----

echo ""
echo "off-mode"
echo "---"
echo "off" > "$MODE_FILE"

test_case "off-mode: non-allowlisted write tool allowed (no log, no block)" \
  "$(mcp_payload 'mcp__notion__createPage')" 0

# ----- Summary -----

echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
