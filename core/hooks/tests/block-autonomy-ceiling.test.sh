#!/bin/bash
# tests/block-autonomy-ceiling.test.sh — synthetic PreToolUse payload tests for
# block-autonomy-ceiling.sh (C5, #1163).
#
# Covers the #1163 ACs + the #1438 D7 fixture set:
#   - ceiling block:     above-ceiling action at recommend → exit 2
#   - ceiling pass:      at-ceiling action at recommend / bounded_auto → exit 0
#   - Tier-0 override:   governance-file Write at bounded_auto → STILL exit 2
#   - Tier-0 under warn: governance-file Write, .autonomy-mode=warn → STILL exit 2
#   - cross-domain:      pmo-platform cwd writing projects/ → exit 2 (Tier-0)
#   - warn-mode ceiling: above-ceiling, .autonomy-mode=warn → exit 0 + warn-log grows
#   - off-mode ceiling:  above-ceiling, .autonomy-mode=off → exit 0
#   - permissive default: unmapped tool call → exit 0
#   - non-mutation:      Read / WebFetch → exit 0 (out of matcher scope)
#   - bypass:            CLAUDE_HOOK_BYPASS=1 → exit 0 + bypass-log
#   - malformed JSON → exit 2
#
# The ceiling is controlled per-case via the cache file (read first by the hook):
#   0 = off, 1 = recommend, 2 = bounded_auto.
# Governance/cross-domain path detection anchors on CLAUDE_WORKSPACE_ROOT, which
# this harness pins to a temp workspace so fixtures are host-independent.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-autonomy-ceiling.sh"
MODE_FILE="${HOOK_DIR}/.autonomy-mode"
WARN_LOG="${HOOK_DIR}/autonomy-warn-log.jsonl"
BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; fi

# --- Pinned temp workspace + cache (host-independent) ---
# CLAUDE_WORKSPACE_ROOT pins the governance/cross-domain anchors; a temp HOME-like
# cache dir controls the resolved ceiling. We override the cache path by pointing
# HOME at a temp dir for the duration of each hook invocation (the hook resolves
# the cache under ${HOME}/.cache/pmo-platform/).
TEST_WS="$(/usr/bin/mktemp -d)"
TEST_HOME="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${TEST_HOME}/.cache/pmo-platform"
CACHE_FILE="${TEST_HOME}/.cache/pmo-platform/autonomy-ceiling"

export CLAUDE_WORKSPACE_ROOT="$TEST_WS"

# --- Save + restore the hook's own mode file ---
ORIGINAL_MODE=""
[ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(/bin/cat "$MODE_FILE")"
restore_state() {
  if [ -n "$ORIGINAL_MODE" ]; then
    /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"
  else
    /bin/rm -f "$MODE_FILE"
  fi
  /bin/rm -rf "$TEST_WS" "$TEST_HOME"
}
trap restore_state EXIT

PASS=0
FAIL=0

# set_ceiling N — write the numeric ceiling to the pinned cache.
set_ceiling() { /usr/bin/printf '%s\n' "$1" > "$CACHE_FILE"; }
set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

# test_case name payload expected_exit [expected_pattern]
# Runs the hook with HOME pinned to the temp cache dir.
test_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="${4:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | HOME="$TEST_HOME" /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
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

# --- Payload builders ---
write_payload() {
  # write_payload file_path cwd
  /usr/bin/jq -n --arg fp "$1" --arg cwd "$2" \
    '{tool_name: "Write", tool_input: {file_path: $fp, content: "x"}, cwd: $cwd}'
}
edit_payload() {
  /usr/bin/jq -n --arg fp "$1" --arg cwd "$2" \
    '{tool_name: "Edit", tool_input: {file_path: $fp, old_string: "a", new_string: "b"}, cwd: $cwd}'
}
mcp_payload() {
  /usr/bin/jq -n --arg tool "$1" '{tool_name: $tool, tool_input: {}, cwd: "/tmp"}'
}
bash_payload() {
  /usr/bin/jq -n --arg cmd "$1" '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: "/tmp"}'
}

echo "================================"
echo "block-autonomy-ceiling.sh tests (C5 #1163)"
echo "workspace=$TEST_WS"
echo "================================"

# =====================================================================
# CEILING CHECK — block / pass (enforce mode)
# =====================================================================
echo ""
echo "Ceiling check (enforce mode)"
echo "---"
set_mode "enforce"

# At recommend (ceiling=1): a Tier-2 staging write EXCEEDS the ceiling → block.
set_ceiling 1
test_case "above-ceiling: 08-Generated write (Tier 2) at recommend → BLOCK" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/out.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-003"

# At recommend (ceiling=1): a Tier-1 stakeholder write is AT the ceiling → allow.
test_case "at-ceiling: projects stakeholder write (Tier 1) at recommend → ALLOW" \
  "$(write_payload "${TEST_WS}/projects/Default/01-Governance/plan.md" "${TEST_WS}/projects/Default")" \
  0

# At bounded_auto (ceiling=2): the Tier-2 staging write is AT the ceiling → allow.
set_ceiling 2
test_case "at-ceiling: 08-Generated write (Tier 2) at bounded_auto → ALLOW" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/out.md" "${TEST_WS}/projects/Default")" \
  0

# At off (ceiling=0): a Tier-1 write EXCEEDS the ceiling → block.
set_ceiling 0
test_case "above-ceiling: projects write (Tier 1) at off → BLOCK" \
  "$(write_payload "${TEST_WS}/projects/Default/01-Governance/plan.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-003"

# MCP write-verb tool (Tier 1) at off (ceiling=0) → block.
test_case "above-ceiling: mcp write-verb (Tier 1) at off → BLOCK" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  2 "BLOCK-AUTONOMY-003"

# MCP write-verb tool (Tier 1) at recommend (ceiling=1) → at ceiling → allow.
set_ceiling 1
test_case "at-ceiling: mcp write-verb (Tier 1) at recommend → ALLOW" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  0

# =====================================================================
# IRREDUCIBLE TIER-0 FLOOR — always block (mode + level independent)
# =====================================================================
echo ""
echo "Irreducible Tier-0 floor (always-block)"
echo "---"

# Governance-file Write at bounded_auto (highest ceiling) → STILL block (AC3).
set_ceiling 2
set_mode "enforce"
test_case "Tier-0 override: CLAUDE.md Write at bounded_auto → BLOCK (AC3)" \
  "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform/.claude/worktrees/wt")" \
  2 "BLOCK-AUTONOMY-001"

test_case "Tier-0 override: a SKILL.md Edit at bounded_auto → BLOCK" \
  "$(edit_payload "${TEST_WS}/pmo-platform/core/skills/foo/SKILL.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

test_case "Tier-0 override: settings.json Write at bounded_auto → BLOCK" \
  "$(write_payload "${TEST_WS}/.claude/settings.json" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

test_case "Tier-0 override: a hook file Write at bounded_auto → BLOCK" \
  "$(write_payload "${TEST_WS}/.claude/hooks/evil.sh" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# Governance-file Write under .autonomy-mode=warn → STILL block (proves Tier-0 is
# always-enforce, NOT warn-gated).
set_mode "warn"
test_case "Tier-0 override under warn: CLAUDE.md Write, mode=warn → STILL BLOCK" \
  "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform/.claude/worktrees/wt")" \
  2 "BLOCK-AUTONOMY-001"

# Governance-file Write under .autonomy-mode=off → STILL block.
set_mode "off"
test_case "Tier-0 override under off: OPERATIONS.md Write, mode=off → STILL BLOCK" \
  "$(write_payload "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# Cross-domain bridge write: pmo-platform cwd writing to projects/ → Tier-0 block.
set_mode "enforce"
set_ceiling 2
test_case "Tier-0: pmo-platform cwd writing projects/ → BLOCK (cross-domain)" \
  "$(write_payload "${TEST_WS}/projects/Default/notes.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-002"

# Cross-domain bridge write (converse): projects/ cwd writing pmo-platform/ → block.
test_case "Tier-0: projects cwd writing pmo-platform/ → BLOCK (cross-domain converse)" \
  "$(write_payload "${TEST_WS}/pmo-platform/core/foo.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-002"

# Same-domain write (projects cwd writing projects) is NOT cross-domain — and a
# non-governance projects path at bounded_auto is at/below ceiling → allow.
test_case "same-domain: projects cwd writing projects/ (non-gov) at bounded_auto → ALLOW" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/x.md" "${TEST_WS}/projects/Default")" \
  0

# =====================================================================
# WARN-MODE + OFF-MODE ceiling behavior (NOT the Tier-0 floor)
# =====================================================================
echo ""
echo "warn-mode / off-mode ceiling"
echo "---"

set_ceiling 0   # off ceiling → a Tier-1 mcp write EXCEEDS it
set_mode "warn"
WARN_BEFORE=0
[ -f "$WARN_LOG" ] && WARN_BEFORE="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"

test_case "warn-mode: above-ceiling mcp write → exit 0 + WARN" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  0 "WARN"

WARN_AFTER=0
[ -f "$WARN_LOG" ] && WARN_AFTER="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$WARN_AFTER" -gt "$WARN_BEFORE" ]; then
  echo "PASS: warn log grew (lines: $WARN_BEFORE → $WARN_AFTER)"; PASS=$((PASS + 1))
else
  echo "FAIL: warn log did NOT grow"; FAIL=$((FAIL + 1))
fi

set_mode "off"
test_case "off-mode: above-ceiling mcp write → exit 0 (no block)" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  0

# =====================================================================
# PERMISSIVE DEFAULT — unmapped actions allow
# =====================================================================
echo ""
echo "permissive default (unmapped → allow)"
echo "---"
set_mode "enforce"
set_ceiling 0   # most restrictive ceiling; unmapped MUST still allow

test_case "permissive: unmapped Bash command at off-ceiling → ALLOW" \
  "$(bash_payload 'ls -la /tmp')" \
  0

test_case "permissive: non-write mcp tool (search) at off-ceiling → ALLOW" \
  "$(mcp_payload 'mcp__atlassian__search')" \
  0

test_case "permissive: Write to an unmapped path (outside projects/) at off-ceiling → ALLOW" \
  "$(write_payload "/tmp/scratch.txt" "/tmp")" \
  0

# =====================================================================
# NON-MUTATION early exit (out of matcher scope)
# =====================================================================
echo ""
echo "non-mutation early exit"
echo "---"
set_ceiling 0

test_case "Read tool → early exit (out of scope)" \
  '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"cwd":"/tmp"}' \
  0

test_case "WebFetch tool → early exit (out of scope)" \
  '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com"},"cwd":"/tmp"}' \
  0

# =====================================================================
# BYPASS + malformed input
# =====================================================================
echo ""
echo "bypass + malformed input"
echo "---"
set_mode "enforce"
set_ceiling 2

BYPASS_BEFORE=0
[ -f "$BYPASS_LOG" ] && BYPASS_BEFORE="$(/usr/bin/wc -l < "$BYPASS_LOG" | /usr/bin/tr -d '[:space:]')"

# Bypass must allow even a Tier-0 governance write (env var set on the hook call).
bypass_stderr="$(/usr/bin/mktemp)"; bypass_exit=0
/usr/bin/printf '%s' "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform")" \
  | HOME="$TEST_HOME" CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" 2>"$bypass_stderr" >/dev/null || bypass_exit="$?"
/bin/rm -f "$bypass_stderr"
if [ "$bypass_exit" = 0 ]; then
  echo "PASS: CLAUDE_HOOK_BYPASS=1 allows Tier-0 write (exit 0)"; PASS=$((PASS + 1))
else
  echo "FAIL: bypass did not allow (exit=$bypass_exit)"; FAIL=$((FAIL + 1))
fi
BYPASS_AFTER=0
[ -f "$BYPASS_LOG" ] && BYPASS_AFTER="$(/usr/bin/wc -l < "$BYPASS_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$BYPASS_AFTER" -gt "$BYPASS_BEFORE" ]; then
  echo "PASS: bypass log grew (lines: $BYPASS_BEFORE → $BYPASS_AFTER)"; PASS=$((PASS + 1))
else
  echo "FAIL: bypass log did NOT grow"; FAIL=$((FAIL + 1))
fi

test_case "malformed JSON → exit 2" \
  'this is not json' \
  2 "INPUT-INVALID"

# =====================================================================
# DEPENDENCY GATE — jq resolution now lives in lib/dep-resolve.sh
# (GHSA-9cjm-v22x-4x33). Because resolution is in the HELPER, simulating
# missing jq requires sandboxing BOTH files: a copy of the hook + a copy of
# dep-resolve.sh with all three jq candidate paths sed'd to nonexistent.
# WARN posture: a missing jq must DEGRADE to exit 0, never block — even in
# .autonomy-mode=enforce with a would-block payload. A MISSING helper, by
# contrast, is fail-CLOSED (exit 2): the hook cannot resolve its dependencies.
# =====================================================================
echo ""
echo "dependency gate (jq via helper; warn-degrade vs fail-closed)"
echo "---"

DEP_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${DEP_SANDBOX}/lib"
/bin/cp "$HOOK" "${DEP_SANDBOX}/block-autonomy-ceiling.sh"
# Broken helper: point every jq candidate at a nonexistent path.
/usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/jq#g' \
             -e 's#/opt/homebrew/bin/jq#/nonexistent/opt/jq#g' \
             -e 's#/usr/local/bin/jq#/nonexistent/local/jq#g' \
             "${HOOK_DIR}/lib/dep-resolve.sh" > "${DEP_SANDBOX}/lib/dep-resolve.sh"
/bin/chmod +x "${DEP_SANDBOX}/block-autonomy-ceiling.sh"

# A would-block Tier-0 governance write + enforce mode: proves the DEGRADE is
# not merely a warn-mode side effect — even the always-block floor yields exit 0
# when jq cannot be resolved (warn posture; do NOT fail closed).
/usr/bin/printf 'enforce' > "${DEP_SANDBOX}/.autonomy-mode"
dep_payload="$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform")"
dep_err="$(/usr/bin/mktemp)"; dep_exit=0
/usr/bin/printf '%s' "$dep_payload" \
  | HOME="$TEST_HOME" /bin/bash "${DEP_SANDBOX}/block-autonomy-ceiling.sh" 2>"$dep_err" >/dev/null || dep_exit="$?"
dep_stderr="$(/bin/cat "$dep_err")"; /bin/rm -f "$dep_err"
if [ "$dep_exit" = 0 ] && /usr/bin/printf '%s' "$dep_stderr" | /usr/bin/grep -qE "DEPENDENCY-WARN"; then
  echo "PASS: jq missing (helper sandboxed) → warn-DEGRADE exit 0 even for a Tier-0 write in enforce mode"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq-missing warn-degrade (exit=%s expected=0, want DEPENDENCY-WARN)\n  stderr: %s\n' "$dep_exit" "$dep_stderr"; FAIL=$((FAIL + 1))
fi

# Missing helper entirely → fail CLOSED (exit 2). The exact readable-before-source
# guard exists precisely so bash 3.2's exit-1-on-failed-source cannot fail OPEN.
NOHELPER_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "${NOHELPER_SANDBOX}/block-autonomy-ceiling.sh"
/bin/chmod +x "${NOHELPER_SANDBOX}/block-autonomy-ceiling.sh"
nohelper_err="$(/usr/bin/mktemp)"; nohelper_exit=0
/usr/bin/printf '%s' "$dep_payload" \
  | HOME="$TEST_HOME" /bin/bash "${NOHELPER_SANDBOX}/block-autonomy-ceiling.sh" 2>"$nohelper_err" >/dev/null || nohelper_exit="$?"
nohelper_stderr="$(/bin/cat "$nohelper_err")"; /bin/rm -f "$nohelper_err"
if [ "$nohelper_exit" = 2 ] && /usr/bin/printf '%s' "$nohelper_stderr" | /usr/bin/grep -qE "LIB-MISSING"; then
  echo "PASS: dep-resolve.sh missing → fail-CLOSED exit 2 (LIB-MISSING)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: helper-missing fail-closed (exit=%s expected=2, want LIB-MISSING)\n  stderr: %s\n' "$nohelper_exit" "$nohelper_stderr"; FAIL=$((FAIL + 1))
fi

/bin/rm -rf "$DEP_SANDBOX" "$NOHELPER_SANDBOX"

# =====================================================================
# Summary
# =====================================================================
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
