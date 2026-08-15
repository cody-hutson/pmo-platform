#!/bin/bash
# tests/block-gh-path-leak.test.sh — synthetic PreToolUse Bash-payload tests for
# block-gh-path-leak.sh (#1137; deployment + coverage completed under #1850).
#
# Covers: path leaks in gh issue/PR bodies via the three authoring forms (inline
# --body, --body-file content, -F body=@ content, gh api -f body=); generalized-
# pointer ALLOW; read-command (view/list) skip; non-gh skip; the path-leak:allow
# marker; the warn / enforce / off mode infrastructure; and the EXCLUSIVITY of this
# hook's own mode file against the shared .mode.
#
# Mode surface: this hook reads ${HOOK_DIR}/.gh-path-leak-mode, NOT the shared
# ${HOOK_DIR}/.mode, and reads it exclusively — no fallback in either direction.
# Both files are saved and restored by the cleanup trap, because the exclusivity
# cases must set the shared file to a value that would change the outcome if it
# were consulted.
#
# Hermetic: the hook resolves the shared primitive co-located (deployed layout) or
# via the repo fallback (core/deploy/tools/) — both yield path_leak_scan_line; the
# test owns its referenced body-files in a temp dir. No dependence on the ambient
# repo. Summary line matches the test-runner contract: "Total: N  PASS: N  FAIL: N".

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-gh-path-leak.sh"
MODE_FILE="${HOOK_DIR}/.gh-path-leak-mode"
SHARED_MODE_FILE="${HOOK_DIR}/.mode"
WARN_LOG="${HOOK_DIR}/gh-path-leak-warn-log.jsonl"
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
ORIGINAL_SHARED=""; [ -f "$SHARED_MODE_FILE" ] && ORIGINAL_SHARED="$(cat "$SHARED_MODE_FILE")"
cleanup() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
  if [ -n "$ORIGINAL_SHARED" ]; then /usr/bin/printf '%s' "$ORIGINAL_SHARED" > "$SHARED_MODE_FILE"; else /bin/rm -f "$SHARED_MODE_FILE"; fi
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
# A home path under a FORMER synthetic-fixture username is a leak like any other. The
# shared primitive used to subtract ten common account names, so this exact body passed
# silently on this surface; the username axis is gone and the marker (see the ALLOWED
# case below) is now the sole content-level escape. Proves the #5075 catch arm on a real
# consumer, not only at predicate level — the primitive's own self-test cannot show that
# a hook actually blocks.
test_case "enforce: gh api issues -f body= former-fixture username BLOCKED" \
  "gh api repos/o/r/issues -f body='/Users/user/x'" 2 "BLOCK-GH-PATH-001"
test_case "enforce: gh issue create generalized pointer ALLOWED" \
  "gh issue create --title T --body-file ${WORK}/clean.md" 0
test_case "enforce: gh issue view (read, no body) ALLOWED" \
  "gh issue view 123" 0
test_case "enforce: non-gh command ALLOWED" \
  "ls -la /tmp" 0
test_case "enforce: path-leak:allow marker ALLOWED" \
  "gh issue create --title T --body 'ref /Users/realuser/x  # path-leak: allow'" 0

# --- WARN: leak WARNs (exit 0 + message) ---
# The pattern deliberately runs PAST the comma to pin the MODE-FILE NAME in the notice.
# Truncating at "WARN (would-block" leaves the one operator-facing instruction for
# changing the posture uncovered by any gate — and under the shipped warn posture that
# line is the only branch that ever executes, so a name that has gone stale there sends
# every operator to edit a file this hook does not read.
set_mode warn
test_case "warn: leak WARNs not blocks, and the notice names THIS hook's mode file" \
  "gh issue create --title T --body-file ${WORK}/leak_machine.md" 0 \
  "WARN \\(would-block, \\.gh-path-leak-mode=warn\\)"
test_case "warn: the notice names all three sanctioned escapes" \
  "gh issue create --title T --body-file ${WORK}/leak_machine.md" 0 \
  "path-leak: allow.*CLAUDE_HOOK_BYPASS=1.*\\.gh-path-leak-mode=off"

# --- OFF: no action ---
set_mode off
test_case "off: leak not flagged" \
  "gh issue create --title T --body-file ${WORK}/leak_machine.md" 0

# --- EXCLUSIVITY + SHIPPED DEFAULT ---
# The hook reads .gh-path-leak-mode and NOTHING else. Proving that needs arms whose
# PASS conditions a NON-exclusive build cannot also satisfy, which is why exit code
# alone is not enough: under a warn default, warn and off both exit 0, so an assertion
# keyed only to the exit code stops discriminating the moment the shipped posture is
# warn rather than enforce.
#
# Each arm removes the dedicated file (so the hook must resolve its in-script default)
# and sets the SHARED file to a value that would produce a DIFFERENT observable if it
# were consulted. The arms falsify opposite fallback directions and cannot agree:
#   shared=enforce -> a fallback would PROMOTE   -> caught by exit 2
#   shared=off     -> a fallback would SILENCE   -> caught by no warn-log growth
# The third arm is the sensitivity control: with the dedicated file PRESENT at enforce
# the hook must block, otherwise the first two arms would also pass on a hook that
# reads no mode file at all and unconditionally warns.
excl_case() {
  # excl_case <name> <shared-value> <dedicated: absent|VALUE> <expect_exit> <expect_growth> [pattern]
  local name="$1" shared="$2" dedicated="$3" expected_exit="$4" want_growth="$5" pattern="${6:-}"
  if [ "$dedicated" = "absent" ]; then /bin/rm -f "$MODE_FILE"; else /usr/bin/printf '%s' "$dedicated" > "$MODE_FILE"; fi
  /usr/bin/printf '%s' "$shared" > "$SHARED_MODE_FILE"
  local before=0
  [ -f "$WARN_LOG" ] && before="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d ' ')"
  local cmd="gh issue create --title T --body-file ${WORK}/leak_machine.md"
  local payload; payload="$("$JQ" -n --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')"
  local tmp; tmp="$(/usr/bin/mktemp)"; local rc=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp" >/dev/null || rc="$?"
  local err; err="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  local after=0
  [ -f "$WARN_LOG" ] && after="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d ' ')"
  local grew=0; [ "$after" -gt "$before" ] && grew=1
  local ok=1
  [ "$rc" != "$expected_exit" ] && ok=0
  [ "$grew" != "$want_growth" ] && ok=0
  [ -n "$pattern" ] && ! /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE "$pattern" && ok=0
  if [ "$ok" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (exit expected=%s actual=%s; warn-log growth expected=%s actual=%s)\n  stderr: %s\n' \
      "$name" "$expected_exit" "$rc" "$want_growth" "$grew" "$err"; FAIL=$((FAIL+1)); fi
}

excl_case "exclusive: shared .mode=enforce + dedicated ABSENT -> in-script warn, NOT promoted" \
  enforce absent 0 1 "WARN \\(would-block, \\.gh-path-leak-mode=warn\\)"
excl_case "exclusive: shared .mode=off + dedicated ABSENT -> in-script warn, NOT silenced" \
  off absent 0 1 "WARN \\(would-block, \\.gh-path-leak-mode=warn\\)"
excl_case "sensitivity: dedicated PRESENT at enforce -> blocks (the dedicated file IS read)" \
  off enforce 2 0 "BLOCK-GH-PATH-001"

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
  # The sandboxed hook reads its OWN mode file from the sandbox HOOK_DIR. Writing
  # ${SBOX}/.mode here would leave every mode case silently testing nothing and the
  # enforce case passing for the wrong reason (the in-script default, not the file).
  /usr/bin/printf '%s' "$smode" > "${SBOX}/.gh-path-leak-mode"
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

# Missing helper entirely → MODE-COUPLED, like the jq gate above it. enforce denies;
# warn/off degrade with the notice still on stderr, because an unusable helper must not
# block harder than a rule match would and in warn/off a match does not block.
/bin/rm -f "${SBOX}/lib/dep-resolve.sh"
sbox_case "missing-helper enforce: fail CLOSED (exit 2)" enforce "" 2 "LIB-MISSING.*fail-closed"
sbox_case "missing-helper warn: degrade (exit 0)"        warn    "" 0 "LIB-MISSING.*degraded"
sbox_case "missing-helper off: degrade (exit 0)"         off     "" 0 "LIB-MISSING.*degraded"

# A stale helper that also redefines get_mode must not choose the guard's own verdict.
# The guard sources the helper inside its own condition, so it is in the shell by the
# time the failure branch runs; the mode is snapshotted readonly above the guard so a
# sourced definition cannot overwrite it. Disk says enforce → must still deny.
/usr/bin/head -78 "${HOOK_DIR}/lib/dep-resolve.sh" > "${SBOX}/lib/dep-resolve.sh"
/usr/bin/printf 'get_mode() { /usr/bin/printf "off"; }\n' >> "${SBOX}/lib/dep-resolve.sh"
sbox_case "stale helper redefining get_mode + enforce: still fail CLOSED (readonly snapshot)" \
  enforce "" 2 "LIB-MISSING.*fail-closed"
/bin/rm -rf "$SBOX"

/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
