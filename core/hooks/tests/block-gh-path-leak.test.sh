#!/bin/bash
# tests/block-gh-path-leak.test.sh — synthetic PreToolUse Bash-payload tests for
# block-gh-path-leak.sh (#1137; deployment + coverage completed under #1850).
#
# Covers: path leaks in gh issue/PR bodies via the three authoring forms (inline
# --body, --body-file content, -F body=@ content, gh api -f body=); generalized-
# pointer ALLOW; read-command (view/list) skip; non-gh skip; the path-leak:allow
# marker; and the warn / enforce / off mode infrastructure.
#
# Hermetic: the hook resolves the shared primitive co-located (deployed layout) or
# via the repo fallback (core/deploy/tools/) — both yield path_leak_scan_line; the
# test owns its referenced body-files in a temp dir. No dependence on the ambient
# repo. Summary line matches the test-runner contract: "Total: N  PASS: N  FAIL: N".

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-gh-path-leak.sh"
MODE_FILE="${HOOK_DIR}/.mode"
JQ="/usr/bin/jq"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK" >&2; exit 1; }

# Referenced body-files for the --body-file / -F body=@ cases. Temp paths are under
# /var|/tmp (no /Users//home, no personal/pmo-instance) so the PATH the command
# references never itself trips the scan — only the file CONTENT does.
WORK="$(mktemp -d)"
/usr/bin/printf 'Context line.\nsee /Users/realuser/Claude/notes.md for the detail\n' > "${WORK}/leak_machine.md"
/usr/bin/printf 'ref /home/realuser/work/output\n'                                    > "${WORK}/leak_home.md"
/usr/bin/printf 'All set — see roadmaps/skill-matrix.md (operator-local per ADR-012).\n' > "${WORK}/clean.md"

ORIGINAL_MODE=""; [ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(cat "$MODE_FILE")"
cleanup() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
  [ -n "${WORK:-}" ] && /bin/rm -rf "$WORK"
}
trap cleanup EXIT

set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

PASS=0; FAIL=0
# test_case <name> <gh-command> <expected_exit> [expected_stderr_pattern]
test_case() {
  local name="$1" cmd="$2" expected_exit="$3" pattern="${4:-}"
  local payload; payload="$("$JQ" -n --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')"
  local tmp; tmp="$(/usr/bin/mktemp)"; local rc=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp" >/dev/null || rc="$?"
  local err; err="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  local ok=1
  [ "$rc" != "$expected_exit" ] && ok=0
  [ -n "$pattern" ] && ! /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE "$pattern" && ok=0
  if [ "$ok" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s)\n  stderr: %s\n' "$name" "$expected_exit" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}

# --- ENFORCE: leak BLOCKS (exit 2), clean/read/non-gh ALLOW (exit 0) ---
set_mode enforce
test_case "enforce: gh issue create --body-file machine-path leak BLOCKED" \
  "gh issue create --title T --body-file ${WORK}/leak_machine.md" 2 "BLOCK-GH-PATH-001"
test_case "enforce: gh issue create --body inline pmo-instance leak BLOCKED" \
  "gh issue create --title T --body 'see personal/pmo-instance/roadmaps/x.md'" 2 "BLOCK-GH-PATH-001"
test_case "enforce: gh pr comment -F body=@ /home leak BLOCKED" \
  "gh pr comment 5 -F body=@${WORK}/leak_home.md" 2 "BLOCK-GH-PATH-001"
test_case "enforce: gh api issues -f body= machine-path leak BLOCKED" \
  "gh api repos/o/r/issues -f body='/Users/realuser/x'" 2 "BLOCK-GH-PATH-001"
test_case "enforce: gh issue create generalized pointer ALLOWED" \
  "gh issue create --title T --body-file ${WORK}/clean.md" 0
test_case "enforce: gh issue view (read, no body) ALLOWED" \
  "gh issue view 123" 0
test_case "enforce: non-gh command ALLOWED" \
  "ls -la /tmp" 0
test_case "enforce: path-leak:allow marker ALLOWED" \
  "gh issue create --title T --body 'ref /Users/realuser/x  # path-leak: allow'" 0

# --- WARN: leak WARNs (exit 0 + message) ---
set_mode warn
test_case "warn: leak WARNs not blocks" \
  "gh issue create --title T --body-file ${WORK}/leak_machine.md" 0 "WARN \\(would-block"

# --- OFF: no action ---
set_mode off
test_case "off: leak not flagged" \
  "gh issue create --title T --body-file ${WORK}/leak_machine.md" 0

# --- MISSING JQ regression (GHSA-9cjm-v22x-4x33) ---
# jq resolution now lives in the shared helper lib/dep-resolve.sh, so to simulate a
# missing jq we sandbox BOTH files into a temp dir: the hook + a COPY of the helper
# whose three jq candidate paths are sed'd to nonexistent. This hook is mode-gated
# and ships warn, so missing-jq fails CLOSED (exit 2) ONLY in enforce; warn/off
# degrade to exit 0. A missing helper is a deployment-integrity failure → exit 2
# regardless of mode.
SBOX="$(mktemp -d)"
/bin/mkdir -p "${SBOX}/lib"
/bin/cp "$HOOK" "${SBOX}/block-gh-path-leak.sh"
/bin/cp "${HOOK_DIR}/../deploy/tools/path-leak-patterns.sh" "${SBOX}/path-leak-patterns.sh" 2>/dev/null || true
/usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/usr/bin/jq#' \
             -e 's#/opt/homebrew/bin/jq#/nonexistent/opt/homebrew/bin/jq#' \
             -e 's#/usr/local/bin/jq#/nonexistent/usr/local/bin/jq#' \
             "${HOOK_DIR}/lib/dep-resolve.sh" > "${SBOX}/lib/dep-resolve.sh"

# sbox_case <name> <mode> <extra-env> <expected_exit> [pattern]
sbox_case() {
  local name="$1" smode="$2" xenv="$3" expected_exit="$4" pattern="${5:-}"
  /usr/bin/printf '%s' "$smode" > "${SBOX}/.mode"
  local cmd="gh issue create --title T --body-file ${WORK}/leak_machine.md"
  local payload; payload="$("$JQ" -n --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')"
  local tmp; tmp="$(/usr/bin/mktemp)"; local rc=0
  /usr/bin/printf '%s' "$payload" | /usr/bin/env $xenv /bin/bash "${SBOX}/block-gh-path-leak.sh" 2>"$tmp" >/dev/null || rc="$?"
  local err; err="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  local ok=1
  [ "$rc" != "$expected_exit" ] && ok=0
  [ -n "$pattern" ] && ! /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE "$pattern" && ok=0
  if [ "$ok" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s)\n  stderr: %s\n' "$name" "$expected_exit" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}

sbox_case "missing-jq enforce: fail CLOSED (exit 2)" enforce "" 2 "DEPENDENCY-MISSING.*fail-closed"
sbox_case "missing-jq warn: degrade (exit 0)"        warn    "" 0 "DEPENDENCY-MISSING.*degraded"
sbox_case "missing-jq off: degrade (exit 0)"         off     "" 0 "DEPENDENCY-MISSING.*degraded"
sbox_case "missing-jq + CLAUDE_HOOK_BYPASS: exit 0"  enforce "CLAUDE_HOOK_BYPASS=1" 0

# Missing helper entirely → fail CLOSED (exit 2) regardless of mode.
/bin/rm -f "${SBOX}/lib/dep-resolve.sh"
sbox_case "missing-helper enforce: fail CLOSED (exit 2)" enforce "" 2 "LIB-MISSING.*fail-closed"
sbox_case "missing-helper off: fail CLOSED (exit 2)"     off     "" 2 "LIB-MISSING.*fail-closed"
/bin/rm -rf "$SBOX"

/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
