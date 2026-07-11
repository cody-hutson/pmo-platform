#!/bin/bash
# tests/block-fs-boundary.test.sh — synthetic Bash-tool payload tests for
# block-fs-boundary.sh. Covers BLOCK-FS-BOUNDARY-001..003 ACs +
# CLAUDE_HOOK_BYPASS bypass + warn-mode + edge cases.
#
# Coverage map: Pass 1 baseline + AC parity for BLOCK-FS-BOUNDARY-001..003.
# Mode gating: tests run hook directly with .mode set to enforce via per-test
# env override (CLAUDE_HOOK_FORCE_MODE not implemented — tests instead exercise
# the natural-state .mode at $HOME/Claude/.claude/hooks/.mode by
# reading it via the hook's own discovery path; tests use isolated MODE_OVERRIDE
# via a temp .mode file when needed via TEST_MODE_FILE pattern).

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-fs-boundary.sh"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi

PASS=0
FAIL=0

# Save and override .mode for enforce-mode tests (most cases). The hook reads
# .mode at runtime; we set it to enforce here so blocks return exit 2 with a
# BLOCKED stderr message. Restore on exit.
MODE_FILE="${HOOK_DIR}/.mode"
MODE_BACKUP=""
if [ -f "$MODE_FILE" ]; then
  MODE_BACKUP="$(/bin/cat "$MODE_FILE")"
fi

restore_mode() {
  if [ -n "$MODE_BACKUP" ]; then
    /usr/bin/printf '%s' "$MODE_BACKUP" > "$MODE_FILE"
  elif [ -f "$MODE_FILE" ]; then
    /bin/rm -f "$MODE_FILE" 2>/dev/null || true
  fi
}
trap restore_mode EXIT

# Default test mode = enforce (so blocks return exit 2)
/usr/bin/printf 'enforce' > "$MODE_FILE"

test_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="${4:-}"
  local env_var="${5:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  if [ -n "$env_var" ]; then
    /usr/bin/printf '%s' "$payload" | /usr/bin/env "$env_var" /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  else
    /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  fi
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

# bash_payload <command> [cwd]
bash_payload() {
  local cmd="$1"
  local cwd="${2:-$HOME/Claude/.claude/worktrees/planning}"
  /usr/bin/jq -n --arg cmd "$cmd" --arg cwd "$cwd" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}'
}

echo "================================"
echo "block-fs-boundary.sh tests"
echo "================================"

# ----- BLOCK-FS-BOUNDARY-001: file-read verbs outside allowed roots -----

test_case "cat ~/Documents blocks" \
  "$(bash_payload 'cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "cat /Users/otheruser blocks" \
  "$(bash_payload 'cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "head ~/Desktop blocks" \
  "$(bash_payload 'head ~/Desktop/foo.log')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "tail ~/Library/Mail blocks" \
  "$(bash_payload 'tail ~/Library/Mail/inbox')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "base64 ~/Library/Cookies blocks" \
  "$(bash_payload 'base64 ~/Library/Cookies/cookies.db')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "xxd /Users/otheruser blocks" \
  "$(bash_payload 'xxd /Users/otheruser/.bash_history')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "less ~/Pictures blocks" \
  "$(bash_payload 'less ~/Pictures/screenshot.png')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- BLOCK-FS-BOUNDARY-002: file-write verbs outside allowed roots -----

test_case "cp source outside Claude blocks" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "cp target outside Claude blocks" \
  "$(bash_payload 'cp /tmp/foo ~/Desktop/bar')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "mv source outside Claude blocks" \
  "$(bash_payload 'mv ~/Documents/old.txt /tmp/new.txt')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "tee ~/Desktop target blocks" \
  "$(bash_payload 'tee ~/Desktop/test.txt')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "dd of=~/Desktop target blocks" \
  "$(bash_payload 'dd if=/tmp/foo of='"$HOME"'/Desktop/bar.bin')" 2 "BLOCK-FS-BOUNDARY-002"

# ----- BLOCK-FS-BOUNDARY-003: unresolvable strict-policy -----

test_case "cat dollar-var unresolvable blocks" \
  "$(bash_payload 'cat $SECRET_FILE')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "cp subshell unresolvable blocks" \
  "$(bash_payload 'cp $(find / -name passwd) /tmp/x')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "tee backtick unresolvable blocks" \
  "$(bash_payload 'tee `echo /etc/hosts`')" 2 "BLOCK-FS-BOUNDARY-003"

# ----- Path-traversal escape (GHSA-9cjm-v22x-4x33 V2) -----
# A literal `..` component escapes an allowed root by prefix-matching BEFORE it
# is collapsed (/tmp/../etc prefix-matches allowed /tmp/ yet resolves to /etc).
# resolve_and_classify now rejects any `..` path-component up front (strict) —
# independent of the python3 normalizer, which previously fell back to the
# un-normalized path when python3 was absent (the second fail-open).
test_case "cat traversal escape blocks (.. token → strict)" \
  "$(bash_payload 'cat /tmp/../etc/passwd')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "tee traversal escape blocks (.. token → strict)" \
  "$(bash_payload 'tee /tmp/aaa/../../../etc/passwd')" 2 "BLOCK-FS-BOUNDARY-003"

# ----- Allowed roots — should pass (exit 0) -----

test_case "cat inside Claude allowed" \
  "$(bash_payload 'cat '"$HOME"'/Claude/CLAUDE.md')" 0

test_case "cat relative inside workspace allowed (cwd is workspace)" \
  "$(bash_payload 'cat README.md' ''"$HOME"'/Claude')" 0

test_case "cp inside Claude allowed" \
  "$(bash_payload 'cp '"$HOME"'/Claude/CLAUDE.md /tmp/c.bak')" 0

test_case "cat /tmp/foo allowed" \
  "$(bash_payload 'cat /tmp/foo')" 0

test_case "cat ~/Downloads allowed (operator-confirmed root)" \
  "$(bash_payload 'cat ~/Downloads/install.dmg.txt')" 0

test_case "cat ~/.claude config allowed" \
  "$(bash_payload 'cat ~/.claude/settings.json')" 0

# NOTE: Cowork install path contains "Application Support" with a space.
# Per documented v1 limitation (whitespace-tokenization shared with
# block-rm-prefer-trash.sh), unquoted paths-with-spaces tokenize into
# `$HOME/Library/Application` (blocked) plus
# `Support/...` (orphan token, skipped). Real-world Cowork access flows
# through `./deploy.sh --deploy` which is on the script-execution allowlist;
# the internal `cp` calls happen inside the script's bash subprocess and
# the hook never sees them. Direct unquoted cat of paths-with-spaces is
# accepted v1 residual per bypass-mode-readiness.md § Known Limitations.
test_case "Cowork install path quoted-form blocks (v1 limitation — unquoted whitespace path tokenizes)" \
  "$(bash_payload 'cat '"$HOME"'/Library/Application Support/Claude/local-agent-mode-sessions/foo/skills/daily-status/SKILL.md')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- Verbs that are NOT in v1 scope — should pass through (out-of-scope = allow) -----

test_case "grep not in v1 scope — allowed (out of scope by design)" \
  "$(bash_payload 'grep secret ~/Documents/file.txt')" 0

test_case "find not in v1 scope — allowed" \
  "$(bash_payload 'find ~/Documents -type f')" 0

test_case "ls not in v1 scope — allowed" \
  "$(bash_payload 'ls ~/Documents')" 0

# ----- Non-Bash tool calls — early exit -----

test_case "Read tool early exit" \
  '{"tool_name": "Read", "tool_input": {"file_path": "$HOME/Documents/foo"}}' 0

test_case "Edit tool early exit" \
  '{"tool_name": "Edit", "tool_input": {"file_path": "$HOME/Desktop/foo"}}' 0

# ----- CLAUDE_HOOK_BYPASS escape hatch -----

test_case "bypass env var allows blocked cat" \
  "$(bash_payload 'cat ~/Documents/foo')" 0 "" "CLAUDE_HOOK_BYPASS=1"

test_case "bypass env var allows blocked cp" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" 0 "" "CLAUDE_HOOK_BYPASS=1"

# ----- Absolute-path-aware verb anchor -----

test_case "/bin/cat outside Claude blocks (absolute-path-aware)" \
  "$(bash_payload '/bin/cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "/usr/bin/cp outside Claude blocks (absolute-path-aware)" \
  "$(bash_payload '/usr/bin/cp ~/Desktop/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002"

# ----- Chained-command tokenizer (F1 split) -----

test_case "ls && cat ~/Documents blocks (chained)" \
  "$(bash_payload 'ls && cat ~/Documents/foo')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "echo hi; cat ~/Desktop blocks (chained)" \
  "$(bash_payload 'echo hi; cat ~/Desktop/foo')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- Warn-mode behavior (.mode = warn → exit 0 with WARN log) -----

test_warn_case() {
  local name="$1"; local payload="$2"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf 'warn' > "$MODE_FILE"
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  /usr/bin/printf 'enforce' > "$MODE_FILE"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != 0 ] && ok=0
  if ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "WARN"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=0 with WARN in stderr)\n  stderr: %s\n' "$name" "$actual_exit" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

test_warn_case "warn-mode cat ~/Documents emits WARN exit 0" \
  "$(bash_payload 'cat ~/Documents/foo')"

test_warn_case "warn-mode cp source outside emits WARN exit 0" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')"

# ----- Off-mode behavior (.mode = off → exit 0 silently) -----

test_off_case() {
  local name="$1"; local payload="$2"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf 'off' > "$MODE_FILE"
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  /usr/bin/printf 'enforce' > "$MODE_FILE"
  /bin/rm -f "$tmp_stderr"
  if [ "$actual_exit" = 0 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=0)\n' "$name" "$actual_exit"
    FAIL=$((FAIL + 1))
  fi
}

test_off_case "off-mode cat ~/Documents silently allowed" \
  "$(bash_payload 'cat ~/Documents/foo')"

# ----- Empty/no-target commands — allow -----

test_case "bare cat with no args allowed" \
  "$(bash_payload 'cat')" 0

test_case "cat with all flags (no targets) allowed" \
  "$(bash_payload 'cat -n')" 0

# ----- Missing-jq dependency gate (GHSA-9cjm-v22x-4x33 regression) -----
# jq resolution now lives in the shared helper lib/dep-resolve.sh, so simulating
# missing jq requires sandboxing BOTH files: a copy of the hook plus a copy of
# the helper with all three jq candidate paths rewritten to nonexistent
# locations. This hook is mode-gated: a control that cannot parse its input must
# DENY in enforce mode (exit 2) and DEGRADE (exit 0, never block harder than a
# rule match) in warn mode.
_sb="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "$_sb/lib"
/bin/cp "$HOOK" "$_sb/block-fs-boundary.sh"; /bin/chmod +x "$_sb/block-fs-boundary.sh"
/usr/bin/sed \
  -e 's#/usr/bin/jq#/nonexistent/jq-a#g' \
  -e 's#/opt/homebrew/bin/jq#/nonexistent/jq-b#g' \
  -e 's#/usr/local/bin/jq#/nonexistent/jq-c#g' \
  "${HOOK_DIR}/lib/dep-resolve.sh" > "$_sb/lib/dep-resolve.sh"
_sb_hook="$_sb/block-fs-boundary.sh"
_sb_payload='{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"/tmp"}'

# enforce mode → fail CLOSED (exit 2 + DEPENDENCY-MISSING)
/usr/bin/printf 'enforce' > "$_sb/.mode"
_jqmiss_exit=0
_jqmiss_err="$(/usr/bin/printf '%s' "$_sb_payload" | /bin/bash "$_sb_hook" 2>&1 >/dev/null)" || _jqmiss_exit="$?"
if [ "$_jqmiss_exit" = 2 ] && /usr/bin/printf '%s' "$_jqmiss_err" | /usr/bin/grep -qE 'DEPENDENCY-MISSING'; then
  /usr/bin/printf 'PASS: jq missing (enforce) → fail CLOSED (exit 2 + DEPENDENCY-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq missing (enforce) → expected exit 2 + DEPENDENCY-MISSING, got exit=%s\n  stderr: %s\n' "$_jqmiss_exit" "$_jqmiss_err"; FAIL=$((FAIL + 1))
fi

# warn mode → DEGRADE (exit 0 + DEPENDENCY-DEGRADED); must not block harder than a match
/usr/bin/printf 'warn' > "$_sb/.mode"
_jqwarn_exit=0
_jqwarn_err="$(/usr/bin/printf '%s' "$_sb_payload" | /bin/bash "$_sb_hook" 2>&1 >/dev/null)" || _jqwarn_exit="$?"
if [ "$_jqwarn_exit" = 0 ] && /usr/bin/printf '%s' "$_jqwarn_err" | /usr/bin/grep -qE 'DEPENDENCY-DEGRADED'; then
  /usr/bin/printf 'PASS: jq missing (warn) → degrade (exit 0 + DEPENDENCY-DEGRADED)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq missing (warn) → expected exit 0 + DEPENDENCY-DEGRADED, got exit=%s\n  stderr: %s\n' "$_jqwarn_exit" "$_jqwarn_err"; FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$_sb"

# ----- Missing dependency helper → fail CLOSED (GHSA-9cjm-v22x-4x33) -----
# If lib/dep-resolve.sh is unreadable, bash 3.2 exits 1 on the failed source
# (non-blocking) — the readability guard converts that to a blocking exit 2.
_sb2="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "$_sb2/block-fs-boundary.sh"; /bin/chmod +x "$_sb2/block-fs-boundary.sh"
/usr/bin/printf 'enforce' > "$_sb2/.mode"   # no $_sb2/lib/dep-resolve.sh created
_libmiss_exit=0
_libmiss_err="$(/usr/bin/printf '%s' '{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"/tmp"}' | /bin/bash "$_sb2/block-fs-boundary.sh" 2>&1 >/dev/null)" || _libmiss_exit="$?"
/bin/rm -rf "$_sb2"
if [ "$_libmiss_exit" = 2 ] && /usr/bin/printf '%s' "$_libmiss_err" | /usr/bin/grep -qE 'LIB-MISSING'; then
  /usr/bin/printf 'PASS: dep helper missing → fail CLOSED (exit 2 + LIB-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: dep helper missing → expected exit 2 + LIB-MISSING, got exit=%s\n  stderr: %s\n' "$_libmiss_exit" "$_libmiss_err"; FAIL=$((FAIL + 1))
fi

# ----- Summary -----

echo ""
echo "================================"
TOTAL=$((PASS + FAIL))
/usr/bin/printf 'Total: %s  PASS: %s  FAIL: %s\n' "$TOTAL" "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
