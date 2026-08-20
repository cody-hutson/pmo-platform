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

# ----- EXT-POS: command-start position coverage (#5644) -----
#
# The anchor recognises a command start only at line-start or after `;&|`. Every case
# below is the IDENTICAL deletion of the IDENTICAL absolute literal, moved to a position
# the anchor could not see; each one allowed before the shared canonicalizer
# (core/hooks/lib/command-position.awk) landed. One case per closed family.

test_case "EXT-POS1: one-line function body blocks (grouping)" \
  "$(bash_payload 'cleanup() { rm -rf /tmp/foo; }')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS2: brace group blocks (grouping)" \
  "$(bash_payload '{ rm -rf /tmp/foo; }')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS3: subshell blocks (grouping)" \
  "$(bash_payload '( rm -rf /tmp/foo )')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS4: then-branch blocks (compound keyword)" \
  "$(bash_payload 'if true; then rm /tmp/foo; fi')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS5: do-body blocks (compound keyword)" \
  "$(bash_payload 'for f in a; do rm /tmp/foo; done')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS6: sudo prefix blocks (command-prefix word)" \
  "$(bash_payload 'sudo rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS7: assignment prefix blocks (VAR=value)" \
  "$(bash_payload 'FOO=1 rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS8: escaped verb blocks (backslash-rm)" \
  "$(bash_payload '\rm /tmp/foo')" 2 "BLOCK-TRASH-001"

# xargs feeds the verb from stdin, so there is no argv target to resolve. The
# canonicalizer emits the $XARGS-STDIN sentinel, which routes to the EXISTING
# unresolvable-under-strict-policy branch — no new rule ID, no new message.
test_case "EXT-POS9: xargs-fed rm blocks via the existing unresolvable branch" \
  "$(bash_payload 'echo /tmp/foo | xargs rm -rf')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS10: case-arm blocks (compound keyword)" \
  "$(bash_payload 'case x in a) rm /tmp/foo;; esac')" 2 "BLOCK-TRASH-001"

# ----- EXT-FP: false-positive guards for the widened positions (#5644) -----
#
# Shell text carried AS CONTENT is not a command. These are ordinary engineering commands
# and every one of them must stay allowed — a guard that fires on them gets disabled by
# the operator, which is a worse security outcome than the gap it closed. EXT-FP2 and
# EXT-FP3 were blocked BEFORE this change (the anchor matched the `;` inside the quoted
# span); quote-neutralisation is what makes them allow.

test_case "EXT-FP1: sed program containing rm allows" \
  "$(bash_payload 'sed '"'"'s/(rm foo)/X/'"'"' file.txt')" 0

test_case "EXT-FP2: writing a shell script as quoted content allows" \
  "$(bash_payload 'echo "cleanup() { rm -rf /tmp/x; }" > s.sh')" 0

test_case "EXT-FP3: printf of a quoted brace group allows" \
  "$(bash_payload 'printf '"'"'%s'"'"' '"'"'{ rm -rf /tmp/x; }'"'"'')" 0

test_case "EXT-FP4: grep alternation containing rm allows" \
  "$(bash_payload 'grep -E '"'"'(rm |mv)'"'"' file.txt')" 0

test_case "EXT-FP5: commit message mentioning rm allows" \
  "$(bash_payload 'git commit -m "guard the (rm foo) case"')" 0

test_case "EXT-FP6: brace EXPANSION is not a group command (no split)" \
  "$(bash_payload 'cat {a,b}.txt')" 0

test_case "EXT-FP7: escaped parens are literal, not grouping" \
  "$(bash_payload 'find . \( -name a \) -print')" 0

# ----- EXT-RES: residual boundary, pinned deliberately (#5644) -----
#
# This is an ALLOW assertion on purpose. `bash -c '…'` is the documented nested-shell
# residual in core/rules/bypass-mode-readiness.md, carrying an explicit deferral decision.
# Pinning it means a future parser migration has a fixture that MUST flip, rather than a
# silent behaviour change nobody notices.
test_case "EXT-RES1: nested-shell program string allows (documented residual, not a defect)" \
  "$(bash_payload 'bash -c '"'"'rm /tmp/foo'"'"'')" 0

# ----- CLAUDE_HOOK_BYPASS escape hatch -----

test_case "CLAUDE_HOOK_BYPASS bypass allows" \
  "$(bash_payload 'rm /tmp/foo')" 0 "" "CLAUDE_HOOK_BYPASS=1"

# ----- Malformed JSON (input validation) -----

test_case "malformed JSON input blocks" \
  'not-json' 2 "INPUT-INVALID"

# ----- Non-Bash tool (early exit) -----

test_case "Read tool early exit" \
  "$(/usr/bin/jq -n '{tool_name: "Read", tool_input: {file_path: "/tmp/x"}, cwd: "/tmp"}')" 0

# ----- DEPENDENCY GATE: missing jq must fail CLOSED (enforce posture) -----
# jq resolution lives in lib/dep-resolve.sh, so to simulate a jq-less host we
# sandbox BOTH the hook AND the helper: copy the hook to a temp dir and write a
# COPY of dep-resolve.sh whose three jq candidate paths are rewritten to a
# nonexistent path. A security control that cannot parse its input must DENY
# (exit 2), never allow (GHSA-9cjm-v22x-4x33).
dep_gate_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="$4"
  local sbx; sbx="$(/usr/bin/mktemp -d)"
  /bin/mkdir -p "${sbx}/lib"
  /bin/cp "$HOOK" "${sbx}/block-rm-prefer-trash.sh"
  # Rewrite every jq candidate path in the helper copy to a nonexistent path.
  /usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/jq#g' \
               -e 's#/opt/homebrew/bin/jq#/nonexistent/jq#g' \
               -e 's#/usr/local/bin/jq#/nonexistent/jq#g' \
    "${HOOK_DIR}/lib/dep-resolve.sh" > "${sbx}/lib/dep-resolve.sh"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "${sbx}/block-rm-prefer-trash.sh" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"; /bin/rm -rf "$sbx"
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

dep_gate_case "missing jq fails CLOSED (enforce, exit 2)" \
  "$(bash_payload 'rm /tmp/foo')" 2 "DEPENDENCY-MISSING"

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
