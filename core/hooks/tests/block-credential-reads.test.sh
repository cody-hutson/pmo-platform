#!/bin/bash
# tests/block-credential-reads.test.sh — synthetic Read tool payload tests for block-credential-reads.sh
# Covers: NEW-E AC for Read-tool credential deny + CLAUDE_HOOK_BYPASS behavior.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-credential-reads.sh"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi

PASS=0
FAIL=0

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

read_payload() {
  local fp="$1"
  /usr/bin/jq -n --arg fp "$fp" --arg cwd "/tmp" \
    '{tool_name: "Read", tool_input: {file_path: $fp}, cwd: $cwd}'
}

echo "================================"
echo "block-credential-reads.sh tests"
echo "================================"

# SSH private keys → block
test_case "Read ~/.ssh/id_rsa blocks" \
  "$(read_payload '/Users/testuser/.ssh/id_rsa')" 2 "BLOCK-CREDENTIAL-READ-001"

test_case "Read ~/.ssh/id_ed25519 blocks" \
  "$(read_payload '/Users/testuser/.ssh/id_ed25519')" 2 "BLOCK-CREDENTIAL-READ-001"

test_case "Read ~/.ssh/config blocks" \
  "$(read_payload '/Users/testuser/.ssh/config')" 2 "BLOCK-CREDENTIAL-READ-001"

# SSH public keys → allow
test_case "Read ~/.ssh/id_rsa.pub allows" \
  "$(read_payload '/Users/testuser/.ssh/id_rsa.pub')" 0

test_case "Read ~/.ssh/id_ed25519.pub allows" \
  "$(read_payload '/Users/testuser/.ssh/id_ed25519.pub')" 0

# AWS credentials → block
test_case "Read ~/.aws/credentials blocks" \
  "$(read_payload '/Users/testuser/.aws/credentials')" 2 "BLOCK-CREDENTIAL-READ-002"

test_case "Read ~/.aws/config blocks" \
  "$(read_payload '/Users/testuser/.aws/config')" 2 "BLOCK-CREDENTIAL-READ-002"

# gh auth → block
test_case "Read ~/.config/gh/hosts.yml blocks" \
  "$(read_payload '/Users/testuser/.config/gh/hosts.yml')" 2 "BLOCK-CREDENTIAL-READ-003"

# .env variants → block
test_case "Read .env blocks" \
  "$(read_payload '/some/project/.env')" 2 "BLOCK-CREDENTIAL-READ-004"

test_case "Read .env.local blocks" \
  "$(read_payload '/some/project/.env.local')" 2 "BLOCK-CREDENTIAL-READ-004"

test_case "Read .env.production blocks" \
  "$(read_payload '/some/project/.env.production')" 2 "BLOCK-CREDENTIAL-READ-004"

# .env.example → allow
test_case "Read .env.example allows" \
  "$(read_payload '/some/project/.env.example')" 0

test_case "Read .env.sample allows" \
  "$(read_payload '/some/project/.env.sample')" 0

test_case "Read .env.template allows" \
  "$(read_payload '/some/project/.env.template')" 0

# SSH keys outside ~/.ssh → block
test_case "Read /backup/id_rsa blocks" \
  "$(read_payload '/backup/id_rsa')" 2 "BLOCK-CREDENTIAL-READ-005"

# *.pem, *.key → block
test_case "Read server.pem blocks" \
  "$(read_payload '/etc/ssl/server.pem')" 2 "BLOCK-CREDENTIAL-READ-006"

test_case "Read secret.key blocks" \
  "$(read_payload '/opt/app/secret.key')" 2 "BLOCK-CREDENTIAL-READ-006"

# Non-Read tools → early exit
test_case "Bash tool → early exit" \
  '{"tool_name":"Bash","tool_input":{"command":"ls"},"cwd":"/tmp"}' 0

test_case "Write tool → early exit" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x","content":"y"},"cwd":"/tmp"}' 0

# Non-credential Read → allow
test_case "Read README.md allows" \
  "$(read_payload '/project/README.md')" 0

test_case "Read /etc/hostname allows" \
  "$(read_payload '/etc/hostname')" 0

# CLAUDE_HOOK_BYPASS escape hatch
test_case "CLAUDE_HOOK_BYPASS=1 bypasses credential deny" \
  "$(read_payload '/Users/testuser/.ssh/id_rsa')" 0 "" "CLAUDE_HOOK_BYPASS=1"

# ----- Fail-CLOSED on missing jq (GHSA-9cjm-v22x-4x33 regression) -----
# jq resolution now lives in lib/dep-resolve.sh, so simulate a jq-less host by
# sandboxing BOTH the hook AND a copy of the helper with its three jq candidate paths
# rewritten to nonexistent locations. A control that cannot parse its input must DENY
# (exit 2 + DEPENDENCY-MISSING), never fail open.
_sbox="$(/usr/bin/mktemp -d)"; /bin/mkdir -p "$_sbox/lib"
/bin/cp "$HOOK" "$_sbox/block-credential-reads.sh"
/usr/bin/sed \
  -e 's#/usr/bin/jq#/nonexistent/jq-a#g' \
  -e 's#/opt/homebrew/bin/jq#/nonexistent/jq-b#g' \
  -e 's#/usr/local/bin/jq#/nonexistent/jq-c#g' \
  "${HOOK_DIR}/lib/dep-resolve.sh" > "$_sbox/lib/dep-resolve.sh"
_jqmiss_exit=0
_jqmiss_err="$(/usr/bin/printf '%s' '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"cwd":"/tmp"}' | /bin/bash "$_sbox/block-credential-reads.sh" 2>&1 >/dev/null)" || _jqmiss_exit="$?"
if [ "$_jqmiss_exit" = 2 ] && /usr/bin/printf '%s' "$_jqmiss_err" | /usr/bin/grep -qE 'DEPENDENCY-MISSING'; then
  /usr/bin/printf 'PASS: jq missing → fail CLOSED (exit 2 + DEPENDENCY-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq missing → expected exit 2 + DEPENDENCY-MISSING, got exit=%s\n  stderr: %s\n' "$_jqmiss_exit" "$_jqmiss_err"; FAIL=$((FAIL + 1))
fi

# ----- Escape hatch works even when jq is missing (GHSA-9cjm V1-F3 regression) -----
# The old ordering evaluated CLAUDE_HOOK_BYPASS AFTER the exit-2 dependency gate, so the
# escape hatch its own message advertised was dead in the missing-jq case. Assert it
# now short-circuits to exit 0 before the gate.
_byp_exit=0
/usr/bin/printf '%s' "$(read_payload '/Users/testuser/.ssh/id_rsa')" | /usr/bin/env CLAUDE_HOOK_BYPASS=1 /bin/bash "$_sbox/block-credential-reads.sh" >/dev/null 2>&1 || _byp_exit="$?"
/bin/rm -rf "$_sbox"
if [ "$_byp_exit" = 0 ]; then
  /usr/bin/printf 'PASS: CLAUDE_HOOK_BYPASS=1 works even when jq is unresolvable (V1-F3)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: bypass + jq-missing → expected exit 0, got exit=%s\n' "$_byp_exit"; FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
