#!/bin/bash
# tests/block-rm-prefer-trash.test.sh — synthetic Bash-tool payload tests
# for block-rm-prefer-trash.sh. Covers BLOCK-TRASH-001..003 ACs +
# CLAUDE_HOOK_BYPASS bypass + edge/regression cases.
#
# Coverage map: 28 cases — Pass 1 baseline (22) + 6 F1 chained-command
# tokenizer cases (EXT-CH1..CH6).

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-rm-prefer-trash.sh"

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

# bash_payload <command> [cwd]
bash_payload() {
  local cmd="$1"
  local cwd="${2:-$HOME/Claude/.claude/worktrees/planning}"
  /usr/bin/jq -n --arg cmd "$cmd" --arg cwd "$cwd" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}'
}

echo "================================"
echo "block-rm-prefer-trash.sh tests"
echo "================================"

# ----- BLOCK-TRASH-001: rm/rmdir/unlink outside workspace OR unresolvable -----

test_case "rm /tmp path blocks outside-Claude" \
  "$(bash_payload 'rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "rm tilde Downloads blocks" \
  "$(bash_payload 'rm ~/Downloads/file.pdf')" 2 "BLOCK-TRASH-001"

test_case "rm dollar-var unresolvable blocks" \
  "$(bash_payload 'rm $FOO')" 2 "BLOCK-TRASH-001"

test_case "rm subshell unresolvable blocks" \
  "$(bash_payload 'rm $(find /tmp -name "*.log")')" 2 "BLOCK-TRASH-001"

test_case "rm relative-dotdot escapes-workspace blocks" \
  "$(bash_payload 'rm ../outside/file' ''"$HOME"'/Claude')" 2 "BLOCK-TRASH-001"

# ----- BLOCK-TRASH-002: rm inside workspace blocks with Trash suggestion -----

test_case "rm inside Claude blocks with Trash suggestion" \
  "$(bash_payload 'rm foo.txt')" 2 "BLOCK-TRASH-002"

test_case "rm absolute inside Claude blocks-trash" \
  "$(bash_payload 'rm '"$HOME"'/Claude/.claude/worktrees/foo/bar.txt')" 2 "BLOCK-TRASH-002"

test_case "rmdir inside Claude blocks-trash" \
  "$(bash_payload 'rmdir '"$HOME"'/Claude/tmp/empty')" 2 "BLOCK-TRASH-002"

# ----- Git subcommand exemption (Hub Decision 1: broad) -----

test_case "git rm exempt" \
  "$(bash_payload 'git rm foo.txt')" 0

test_case "git clean exempt" \
  "$(bash_payload 'git clean -fd')" 0

# Hub Decision 1 verification — broad git-exemption applies to ALL git <verb>,
# not just rm|clean|worktree|stash. git filter-branch is exempt at this hook
# (handled separately by block-destructive BLOCK-DESTRUCTIVE-014).
test_case "git filter-branch exempt (broad git-exemption — Hub Decision 1)" \
  "$(bash_payload 'git filter-branch --tree-filter foo HEAD')" 0

# ----- BLOCK-TRASH-003: trash / osascript Trash-verb outside workspace -----

test_case "trash /tmp blocks" \
  "$(bash_payload 'trash /tmp/foo')" 2 "BLOCK-TRASH-003"

test_case "trash tilde Downloads blocks" \
  "$(bash_payload 'trash ~/Downloads/file.pdf')" 2 "BLOCK-TRASH-003"

test_case "trash inside Claude allows" \
  "$(bash_payload 'trash '"$HOME"'/Claude/foo.txt')" 0

test_case "osascript Trash-verb outside blocks" \
  "$(bash_payload 'osascript -e '"'"'tell application "Finder" to delete POSIX file "/tmp/foo"'"'"'')" 2 "BLOCK-TRASH-003"

test_case "osascript Trash-verb inside allows" \
  "$(bash_payload 'osascript -e '"'"'tell application "Finder" to delete POSIX file "'"$HOME"'/Claude/foo"'"'"'')" 0

test_case "osascript non-Trash-verb allows" \
  "$(bash_payload 'osascript -e '"'"'say "hello"'"'"'')" 0

# ----- Non-match guards (false-positive prevention) -----

test_case "echo rm false-positive guard" \
  "$(bash_payload 'echo rm foo')" 0

test_case "docker --rm false-positive guard" \
  "$(bash_payload 'docker run --rm foo')" 0

# ----- Chained-command tokenizer (F1 fix) -----

test_case "EXT-CH1: && rm blocks (chained-AND)" \
  "$(bash_payload 'ls && rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-CH2: || rm blocks (chained-OR)" \
  "$(bash_payload 'false || rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-CH3: | rm blocks (piped)" \
  "$(bash_payload 'echo x | rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-CH4: ; rm blocks (semicolon, whitespace)" \
  "$(bash_payload 'echo x ; rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-CH5: ;rm blocks (semicolon, no whitespace)" \
  "$(bash_payload 'echo x;rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-CH6: && trash blocks (chained-AND, trash verb)" \
  "$(bash_payload 'ls && trash /tmp/foo')" 2 "BLOCK-TRASH-003"

# ----- BLOCK-AP-011..015: absolute-path invocation coverage -----
#
# Cover the 5 canonical macOS/Linux absolute-path prefixes
# (/bin/, /usr/bin/, /usr/local/bin/, /opt/homebrew/bin/,
# /opt/local/bin/). Prior baseline: each of these invocation forms
# bypassed the verb-detection anchor (which required the verb to start
# at line-start or after a separator with NO allowance for absolute-
# path prefixes). Now: ANCHOR_PREFIX_BASH constant matches the
# optional prefix; extract_target_tokens() awk script strips the
# prefix before verb-equality.

test_case "AC-AP-011: /bin/rm /tmp/foo blocks (BLOCK-TRASH-001)" \
  "$(bash_payload '/bin/rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "AC-AP-012: /usr/bin/rm foo.txt (worktree cwd) blocks-trash (BLOCK-TRASH-002)" \
  "$(bash_payload '/usr/bin/rm foo.txt')" 2 "BLOCK-TRASH-002"

test_case "AC-AP-013: /bin/unlink $HOME/Claude/foo blocks-trash (BLOCK-TRASH-002)" \
  "$(bash_payload '/bin/unlink '"$HOME"'/Claude/foo')" 2 "BLOCK-TRASH-002"

test_case "AC-AP-014: /opt/homebrew/bin/trash /tmp/foo blocks (BLOCK-TRASH-003)" \
  "$(bash_payload '/opt/homebrew/bin/trash /tmp/foo')" 2 "BLOCK-TRASH-003"

test_case "AC-AP-015: /usr/bin/git rm foo.txt allows (git-exemption with absolute path)" \
  "$(bash_payload '/usr/bin/git rm foo.txt')" 0

# AC-AP-015b: genuine false-positive test addressing FMF-2 adversarial
# finding (the spec's `echo /usr/bin/rm foo` false-positive case would
# pass under BOTH old AND new regex because `echo` is not anchored —
# tautological coverage). This fixture genuinely exercises the new
# optional-prefix-group regression risk by combining a separator (`|`)
# with the absolute-path prefix in a context where the matched string
# is benign grep-pattern content, NOT an actual rm invocation. Without
# the new regex, this allowed under the prior anchor. With the new regex, the
# pipe-separator anchor + prefix-group + verb fires; expected behavior:
# this should STILL be blocked because the actual second command IS
# `rm` at the start of the segment after `|`. This documents the new
# regex's behavior accurately: `|` IS a separator and `/usr/bin/rm` IS
# a verb invocation after it. The fixture confirms the absolute-path
# detection composes with the existing chained-command tokenizer.
test_case "AC-AP-015c: piped chain with /usr/bin/rm blocks (composes with EXT-CH3)" \
  "$(bash_payload 'echo x | /usr/bin/rm /tmp/foo')" 2 "BLOCK-TRASH-001"

# AC-AP-015d: genuine false-positive test — `/usr/bin/rm` as a literal
# string inside a single-quoted argument is NOT a separator-anchored
# verb invocation; the line-start anchor fails (cat is not a hook-
# anchored verb in THIS hook). Prior anchor: allowed. Current anchor: still
# allowed. This documents that quoted-content occurrences of the
# absolute-path verb do not trigger false positives.
test_case "AC-AP-015d: quoted '/usr/bin/rm' as grep pattern allows (false-positive guard)" \
  "$(bash_payload 'cat /tmp/log.txt | grep "/usr/bin/rm called"')" 0

# ----- CLAUDE_HOOK_BYPASS escape hatch -----

test_case "CLAUDE_HOOK_BYPASS bypass allows" \
  "$(bash_payload 'rm /tmp/foo')" 0 "" "CLAUDE_HOOK_BYPASS=1"

# ----- Malformed JSON (input validation) -----

test_case "malformed JSON input blocks" \
  'not-json' 2 "INPUT-INVALID"

# ----- Non-Bash tool (early exit) -----

test_case "Read tool early exit" \
  "$(/usr/bin/jq -n '{tool_name: "Read", tool_input: {file_path: "/tmp/x"}, cwd: "/tmp"}')" 0

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
