#!/bin/bash
# tests/block-rm-prefer-trash.test.sh — synthetic Bash-tool payload tests
# for block-rm-prefer-trash.sh. Covers BLOCK-TRASH-001..003 ACs, the
# auto-memory Trash arm (MEM-*), the in-command working directory (CWD-*), the
# one-form target/root comparison (NORM-*), home-relative and non-literal target
# words (TILDE-*, NONLIT-*), CLAUDE_HOOK_BYPASS bypass + edge/regression cases.
#
# Coverage map: grouped below by rule and case family; the Summary block prints the
# live total (a hardcoded count here drifted before — do not reintroduce one).

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

# ----- HOME isolation: the fixture home (HOME-FIXTURE-01) -----
#
# The arms that pass "$RMT_HOME_ENV" assert INSIDE-workspace behaviour: an rm-family verb
# on a workspace target is redirected to the Trash (BLOCK-TRASH-002), and a Trash verb on
# one is allowed. The hook derives its default workspace root from HOME and normalizes it
# and the target in one call (NORM-* below), so a caller's HOME reached through a symlink —
# a `mktemp -d` directory under macOS's /var -> /private/var link, as the install
# regression's HOME-override step uses — no longer reads an inside target as outside. The
# fixture stays as isolation: each pinned arm's verdict depends on the workspace the hook
# derives, so it must not depend on the caller's HOME or on what the caller's own
# workspace holds.
#
# The lever is the fixture pattern block-fs-boundary.test.sh uses: a per-invocation env
# prefix on only the command that reads the HOME-derived input, here the hook, pointed at
# a fixture home that is canonical by construction. The fixture is never created: the
# hook classifies a path without requiring it to exist. Each pinned arm's payload and
# working directory are spelled from the fixture, so the target and the root the hook
# derives agree under any caller HOME. Every other arm keeps the caller's HOME.
RMT_FIXTURE_HOME="/nonexistent/rm-trash-fixture-home"
RMT_FIXTURE_OTHER_HOME="/nonexistent/rm-trash-other-home"
RMT_FIXTURE_CWD="${RMT_FIXTURE_HOME}/Claude/.claude/worktrees/planning"
RMT_HOME_ENV="HOME=${RMT_FIXTURE_HOME}"

# Probe-validity precondition: prove the lever is live, with BOTH arms observed, before
# any assertion depends on it. Sensitivity: under the fixture home, an rm of a target in
# the fixture's workspace is redirected to the Trash and the message names the fixture
# path, so the hook derived its root from the pinned HOME and the fixture is canonical.
# Specificity: the same payload under a second home is refused as outside the workspace,
# so the verdict follows HOME. The hook prefers CLAUDE_WORKSPACE_ROOT to HOME, so a caller
# that exports it defeats the lever; this arm names that failure instead of leaving seven
# unexplained ones.
rmt_home_probe() {   # $1 = HOME for the hook -> sets RMT_PROBE_EXIT and RMT_PROBE_ERR
  local rmt_payload; rmt_payload="$(bash_payload 'rm '"$RMT_FIXTURE_HOME"'/Claude/probe.txt' "$RMT_FIXTURE_CWD")"
  RMT_PROBE_EXIT=0
  RMT_PROBE_ERR="$(/usr/bin/printf '%s' "$rmt_payload" | /usr/bin/env "HOME=$1" /bin/bash "$HOOK" 2>&1 >/dev/null)" || RMT_PROBE_EXIT="$?"
}
rmt_home_probe "$RMT_FIXTURE_HOME"
rmt_in_exit="$RMT_PROBE_EXIT"; rmt_in_err="$RMT_PROBE_ERR"
rmt_home_probe "$RMT_FIXTURE_OTHER_HOME"
rmt_out_exit="$RMT_PROBE_EXIT"; rmt_out_err="$RMT_PROBE_ERR"
rmt_in_named=0
case "$rmt_in_err" in
  *"BLOCK-TRASH-002"*"${RMT_FIXTURE_HOME}/Claude/probe.txt"*) rmt_in_named=1 ;;
esac
rmt_out_named=0
case "$rmt_out_err" in
  *"BLOCK-TRASH-001"*) rmt_out_named=1 ;;
esac
if [ "$rmt_in_exit" = 2 ] && [ "$rmt_in_named" = 1 ] && [ "$rmt_out_exit" = 2 ] && [ "$rmt_out_named" = 1 ]; then
  /usr/bin/printf 'PASS: HOME-FIXTURE-01 fixture-home isolation live (sensitivity + specificity arms both observed)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: HOME-FIXTURE-01 fixture-home isolation NOT live, so the HOME-pinned arms below cannot be trusted (an exported CLAUDE_WORKSPACE_ROOT overrides HOME)\n  fixture home: exit=%s (expected 2), BLOCK-TRASH-002 naming the fixture path=%s (expected 1)\n  second home: exit=%s (expected 2), BLOCK-TRASH-001=%s (expected 1)\n  stderr (fixture): %s\n  stderr (second): %s\n' \
    "$rmt_in_exit" "$rmt_in_named" "$rmt_out_exit" "$rmt_out_named" "$rmt_in_err" "$rmt_out_err"
  FAIL=$((FAIL + 1))
fi

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
# These three run under the fixture home (HOME-FIXTURE-01); their workspace is the
# fixture's, so each payload and working directory is spelled from it.

test_case "rm inside Claude blocks with Trash suggestion" \
  "$(bash_payload 'rm foo.txt' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

test_case "rm absolute inside Claude blocks-trash" \
  "$(bash_payload 'rm '"$RMT_FIXTURE_HOME"'/Claude/.claude/worktrees/foo/bar.txt' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

test_case "rmdir inside Claude blocks-trash" \
  "$(bash_payload 'rmdir '"$RMT_FIXTURE_HOME"'/Claude/tmp/empty' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

# ----- Git subcommand exemption (Hub Decision 1: broad over git verbs; per segment, #8122) -----
# Every git verb is exempt, but only in its own segment: EXT-SEG below judges the line's others.

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

# This arm and the osascript inside-allow arm below run under the fixture home
# (HOME-FIXTURE-01).
test_case "trash inside Claude allows" \
  "$(bash_payload 'trash '"$RMT_FIXTURE_HOME"'/Claude/foo.txt' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"

test_case "osascript Trash-verb outside blocks" \
  "$(bash_payload 'osascript -e '"'"'tell application "Finder" to delete POSIX file "/tmp/foo"'"'"'')" 2 "BLOCK-TRASH-003"

test_case "osascript Trash-verb inside allows" \
  "$(bash_payload 'osascript -e '"'"'tell application "Finder" to delete POSIX file "'"$RMT_FIXTURE_HOME"'/Claude/foo"'"'"'' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"

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

# AC-AP-012 and AC-AP-013 run under the fixture home (HOME-FIXTURE-01). AC-AP-013's name
# still expands the caller's HOME, so its arm ID reads as it always has; its payload is
# spelled from the fixture.
test_case "AC-AP-012: /usr/bin/rm foo.txt (worktree cwd) blocks-trash (BLOCK-TRASH-002)" \
  "$(bash_payload '/usr/bin/rm foo.txt' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

test_case "AC-AP-013: /bin/unlink $HOME/Claude/foo blocks-trash (BLOCK-TRASH-002)" \
  "$(bash_payload '/bin/unlink '"$RMT_FIXTURE_HOME"'/Claude/foo' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

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

# AC-AP-016 (#8123 AC1): the keg-only Trash location the hook's own tier-2 suggestion names is a
# Trash invocation. It sits outside the shared prefix set (which stays byte-identical across the
# four anchor hooks), so the hook recognises it through one Trash-local constant that the
# suggestion, the Step-3 verb test and the segment walk all read. 016c is the inside control;
# 016d is the keg spelling with no operand, which #8122's target-less limb must also see (INT-4).
RMT_KEG="/opt/homebrew/opt/trash/bin/trash"
test_case "AC-AP-016: the keg-only Trash location with an outside target blocks (BLOCK-TRASH-003)" \
  "$(bash_payload "${RMT_KEG} /tmp/rmt-keg-016")" 2 "BLOCK-TRASH-003.*deletion outside"
test_case "AC-AP-016b: the keg-only Trash location after a separator with an outside target blocks" \
  "$(bash_payload "ls && ${RMT_KEG} /tmp/rmt-keg-016b")" 2 "BLOCK-TRASH-003.*deletion outside"
test_case "AC-AP-016c (control): the keg-only Trash location with an inside target allows" \
  "$(bash_payload "${RMT_KEG} ${RMT_FIXTURE_HOME}/Claude/keg-in" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "AC-AP-016d: the keg-only Trash location with no operand is refused (target-less, INT-4)" \
  "$(bash_payload "${RMT_KEG}")" 2 "BLOCK-TRASH-003.*does not name all its targets"
test_case "AC-AP-016e: the keg-only Trash location behind a wrapper with an outside target blocks" \
  "$(bash_payload "nice ${RMT_KEG} /tmp/rmt-keg-016e")" 2 "BLOCK-TRASH-003.*deletion outside"

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

# ----- EXT-POS (#8314): the canonicalizer walks a wrapper's own grammar -----
#
# The same deletion of the same absolute literal, reached through a wrapper's own option
# (EXT-POS11, 15, 18), an absolute-path wrapper (12), a wrapper missing from the set (13-15),
# a condition position (16) and a wrapper flag that takes no argument (17). Each allowed
# before the canonicalizer walked wrapper grammar.
test_case "EXT-POS11: env -u X rm blocks (wrapper option with a separate argument)" \
  "$(bash_payload 'env -u X rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS12: /usr/bin/sudo rm blocks (absolute-path wrapper)" \
  "$(bash_payload '/usr/bin/sudo rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS13: nice rm blocks (wrapper missing from the set)" \
  "$(bash_payload 'nice rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS14: stdbuf -oL rm blocks (wrapper missing from the set, attached option value)" \
  "$(bash_payload 'stdbuf -oL rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS15: timeout -s KILL 5 rm blocks (wrapper option, then its duration)" \
  "$(bash_payload 'timeout -s KILL 5 rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS16: if-condition rm blocks (condition position)" \
  "$(bash_payload 'if rm /tmp/foo ; then :; fi')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS17: time -p rm blocks (wrapper flag that takes no argument)" \
  "$(bash_payload 'time -p rm /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-POS18: xargs with its own option feeding rm blocks via the stdin sentinel" \
  "$(bash_payload 'printf x | xargs -n 1 rm')" 2 "BLOCK-TRASH-001"

# ----- EXT-APPEND (#8314, follow-up pass): the append form of a prefix assignment -----
#
# The canonicalizer read a NAME+=value word as the command word, so the deletion behind it was
# never at a command start. T1 is that deletion behind the append form; T1-CTL the same
# deletion behind a NAME=value word (EXT-POS7's class), refused before and after.
test_case "EXT-APPEND-T1-CTL: a NAME=value assignment then rm blocks (plain-form control)" \
  "$(bash_payload 'FOO=1 rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-APPEND-T1: an append-form assignment then rm blocks" \
  "$(bash_payload 'FOO+=1 rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

# ----- EXT-ORDER (#8314, DT pass 2): an assignment or a redirection is read as what it is -----
#
# The canonicalizer's default walk looked a token up as a wrapper word by its basename before
# it tested the token as an assignment or a redirection, so an assignment whose value ends in
# /timeout, or a redirection to a file named timeout, was read as the timeout wrapper, whose
# duration operand consumed the rm behind it. T1 and T2 are that deletion behind each shape;
# the CTLs are the plain form and the same deletion behind a plain assignment, refused before
# and after.
test_case "EXT-ORDER-T-CTL0: rm blocks (plain-form control)" \
  "$(bash_payload 'rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-ORDER-T-CTL1: an assignment with a plain value, then rm blocks" \
  "$(bash_payload 'X=1 rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-ORDER-T1: an assignment whose value's last path segment is timeout, then rm blocks" \
  "$(bash_payload 'X=/usr/bin/timeout rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-ORDER-T2: an output redirection to a file named timeout, then rm blocks" \
  "$(bash_payload '>/tmp/timeout rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

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

# ----- EXT-FP (#8314): wrapper grammar carried as content stays content -----
test_case "EXT-FP8: echoed wrapper-and-option text allows" \
  "$(bash_payload 'echo "nice -n 10 rm -rf /tmp/x"')" 0

test_case "EXT-FP9: commit message carrying a wrapped deletion allows" \
  "$(bash_payload 'git commit -m "if rm fails, sudo -u root rm -rf /tmp/x"')" 0

# ----- EXT-RA (#8314, re-based by #8122): a git command or a target-less verb behind a face -----
#
# Each sentinel puts a git command, or a target-less deletion verb, behind a face the
# canonicalizer resolves (a wrapper, a condition keyword, an absolute-path env), beside a
# deletion the hook refuses (T1-T5), or a target-less verb ahead of another verb's deletion
# (T6). The hook keeps no exit that allows on a match, so each is refused whatever the walk
# resolves. Each sentinel is paired below with a copy of the hook that puts one such exit back
# — the whole-line git exit on the widened text (M-TRASH-SEGWALK), or an exit on a target-less
# rm-family segment (M-TRASH-SEGVERB) — which allows it: the sentinel is shown able to fire.
test_case "EXT-RA-T1: a git status behind nice does not exempt the deletion beside it" \
  "$(bash_payload 'nice git status ; rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-RA-T2: a git condition does not exempt the deletion in its branch" \
  "$(bash_payload 'if git diff --quiet ; then rm -rf /tmp/foo ; fi')" 2 "BLOCK-TRASH-001"

test_case "EXT-RA-T3: a git log behind an absolute-path env does not exempt the deletion beside it" \
  "$(bash_payload '/usr/bin/env git log ; rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-RA-T4: a target-less rm behind nice does not end the evaluation before the trash call" \
  "$(bash_payload 'nice rm ; trash /etc/hosts')" 2 "BLOCK-TRASH-003"

test_case "EXT-RA-T5: a target-less rm behind a long sudo flag does not end the evaluation" \
  "$(bash_payload 'sudo --list rm ; trash /etc/hosts')" 2 "BLOCK-TRASH-003"

test_case "EXT-RA-T6: a target-less rm the widening promotes does not displace today's start-verb unlink" \
  "$(bash_payload 'nice rm ; sudo unlink /tmp/foo')" 2 "BLOCK-TRASH-001"

# The two lines the walk resolved BEFORE the wrapper grammar, which the exit view kept allowed.
# Every segment is judged now, so both are refused: the git segment and the target-less rm
# each cover only themselves.
test_case "EXT-RES-T1: a sudo-prefixed git status no longer exempts the deletion beside it (per-segment walk)" \
  "$(bash_payload 'sudo git status ; rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-RES-T2: a sudo-prefixed target-less rm no longer ends the evaluation (per-segment walk)" \
  "$(bash_payload 'sudo rm ; trash /etc/hosts')" 2 "BLOCK-TRASH-003"

# The pairs. Each mutant is a copy of the hook with exactly one marked line turned back into an
# exit that allows on a match, shown live first: it differs from the hook by that one line, and it
# parses. The sentinel's command through that copy must be allowed. The two sed programs are
# shared with the EXT-SEG pairs below.
SEG_SED_WALK='s/^:  # M-TRASH-SEGWALK$/if matches "${ANCHOR_PREFIX_BASH}"'"'"'git[[:space:]]+[^[:space:]]+'"'"'; then exit 0; fi  # M-TRASH-SEGWALK/'
SEG_SED_VERB='s/^\([[:space:]]*\)judge_targets "\$verb"  # M-TRASH-SEGVERB$/\1judge_targets "$verb"; [ -n "$(extract_bare_segments "$verb")" ] \&\& exit 0  # M-TRASH-SEGVERB/'
ra_dir="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-ra.XXXXXX" 2>/dev/null)" || ra_dir=""
ra_live() { # $1 = mutant file -> 0 when it differs from the hook by exactly one line and parses
  local n
  n="$(/usr/bin/diff "$HOOK" "$1" 2>/dev/null | /usr/bin/grep -c '^[<>]' || true)"
  [ "$n" = 2 ] && /bin/bash -n "$1" 2>/dev/null
}
ra_pair() { # $1 = arm label  $2 = mutant file  $3 = command
  local rc=0 err
  if ! ra_live "$2"; then
    /usr/bin/printf 'FAIL: %s the mutant is not live (it does not differ from the hook by exactly its one marked line, or does not parse)\n' "$1"
    FAIL=$((FAIL + 1)); return
  fi
  err="$(/usr/bin/printf '%s' "$(bash_payload "$3")" | /bin/bash "$2" 2>&1 >/dev/null)" || rc="$?"
  if [ "$rc" = 0 ]; then
    /usr/bin/printf 'PASS: %s the sentinel is allowed through the mutant, so it can fire\n' "$1"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s the mutant did not allow the sentinel (exit=%s): %s\n' "$1" "$rc" "$err"
    FAIL=$((FAIL + 1))
  fi
}
if [ -z "$ra_dir" ]; then
  /usr/bin/printf 'FAIL: EXT-RA pairs could not create a sandbox, so the pairs did not run\n'
  FAIL=$((FAIL + 1))
else
  /bin/mkdir -p "${ra_dir}/lib"
  /bin/cp "${HOOK_DIR}/lib/dep-resolve.sh" "${HOOK_DIR}/lib/command-position.awk" "${ra_dir}/lib/"
  /usr/bin/sed -e "$SEG_SED_WALK" "$HOOK" > "${ra_dir}/block-rm-prefer-trash-segwalk.sh"
  /usr/bin/sed -e "$SEG_SED_VERB" "$HOOK" > "${ra_dir}/block-rm-prefer-trash-segverb.sh"
  ra_pair "EXT-RA-T1-PAIR:" "${ra_dir}/block-rm-prefer-trash-segwalk.sh" 'nice git status ; rm -rf /tmp/foo'
  ra_pair "EXT-RA-T2-PAIR:" "${ra_dir}/block-rm-prefer-trash-segwalk.sh" 'if git diff --quiet ; then rm -rf /tmp/foo ; fi'
  ra_pair "EXT-RA-T3-PAIR:" "${ra_dir}/block-rm-prefer-trash-segwalk.sh" '/usr/bin/env git log ; rm -rf /tmp/foo'
  ra_pair "EXT-RA-T4-PAIR:" "${ra_dir}/block-rm-prefer-trash-segverb.sh" 'nice rm ; trash /etc/hosts'
  ra_pair "EXT-RA-T5-PAIR:" "${ra_dir}/block-rm-prefer-trash-segverb.sh" 'sudo --list rm ; trash /etc/hosts'
  ra_pair "EXT-RA-T6-PAIR:" "${ra_dir}/block-rm-prefer-trash-segverb.sh" 'nice rm ; sudo unlink /tmp/foo'
  case "${ra_dir##*/}" in rmt-ra.*) /bin/rm -rf "$ra_dir" ;; esac
fi

# ----- EXT-APPEND-X (#8314, follow-up pass): a git command or a target-less verb behind an append form -----
#
# The default walk steps over the append form of a prefix assignment (NAME+=value). Each sentinel
# puts a git command or a target-less deletion verb behind such a word, beside a deletion or a
# Trash call the hook refuses; each is refused before and after, now because every segment is
# judged.
test_case "EXT-APPEND-X1: a git status behind an append-form assignment does not exempt the deletion beside it (Step 1)" \
  "$(bash_payload 'FOO+=1 git status ; rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-APPEND-X2: a target-less rm behind an append-form assignment does not end the evaluation before the trash call (Step 2)" \
  "$(bash_payload 'FOO+=1 rm ; trash /etc/hosts')" 2 "BLOCK-TRASH-003"

test_case "EXT-APPEND-X3: a target-less rm behind an append-form assignment does not displace today's start-verb unlink (Step 2)" \
  "$(bash_payload 'FOO+=1 rm ; sudo unlink /tmp/foo')" 2 "BLOCK-TRASH-001"

test_case "EXT-APPEND-X4: a git log behind two append-form assignments does not exempt the deletion beside it (Step 1)" \
  "$(bash_payload 'FOO+=1 BAR+=2 git log ; rm -rf /tmp/foo')" 2 "BLOCK-TRASH-001"


# ----- CMDPOS-SKEW (#8314): the canonicalizer's version-skew canary -----
#
# This hook trusts the shared canonicalizer only after two probes: a one-line function body, and
# a wrapper carrying a separate-argument option before a benign word, whose canonical form exposes
# the word only on the walk that reads wrapper grammar (opened by the append form of a prefix
# assignment). A stale or damaged copy beside this hook passes the first probe and fails the
# second, so the hook fails CLOSED. Modelled by a copy whose nice row is removed (SKEW-01) and a
# copy whose walk reads the append form as the command word (SKEW-APPEND); the control is the same
# sandbox with the shipped copy. The hook reads neither the exit view nor the both view, so a copy
# without them is not refused here.
cps_root="$(/usr/bin/mktemp -d)"
cps_hooks="${cps_root}/.claude/hooks"
/bin/mkdir -p "${cps_hooks}/lib"
/bin/cp "${HOOK_DIR}/lib/"*.sh "${cps_hooks}/lib/" 2>/dev/null || true
/bin/cp "$HOOK" "${cps_hooks}/block-rm-prefer-trash.sh"
cps_run() { # $1 = command -> CPS_RC and CPS_ERR
  CPS_RC=0
  CPS_ERR="$( ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
      /usr/bin/printf '%s' "$(bash_payload "$1" "$cps_root")" | /bin/bash "${cps_hooks}/block-rm-prefer-trash.sh" 2>&1 >/dev/null ) )" || CPS_RC="$?"
}
cps_skew() { # $1 = arm label  $2 = sed program for the canonicalizer copy  $3 = what the copy lacks
  /usr/bin/sed -e "$2" "${HOOK_DIR}/lib/command-position.awk" > "${cps_hooks}/lib/command-position.awk"
  local live=0
  if ! /usr/bin/cmp -s "${HOOK_DIR}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk"; then live=1; fi
  cps_run 'echo hello'
  if [ "$live" = 1 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'PRIMITIVE-MISSING' <<<"$CPS_ERR"; then
    /usr/bin/printf 'PASS: %s a canonicalizer copy without %s fails the hook closed (exit 2, PRIMITIVE-MISSING)\n' "$1" "$3"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s a canonicalizer copy without %s did not fail the hook closed (mutant live=%s, exit=%s): %s\n' "$1" "$3" "$live" "$CPS_RC" "$CPS_ERR"
    FAIL=$((FAIL + 1))
  fi
}
cps_skew "CMDPOS-SKEW-01" 's/WROW\["nice"\]=1//' "the wrapper grammar"
# (#8314, follow-up pass) The second probe puts an append-form prefix assignment ahead of its
# wrapper, so a copy whose walk reads that word as the command word fails it too.
cps_skew "CMDPOS-SKEW-APPEND" '/CMDPOS-APPEND/s/[[]+[]]?=/=/' "the append form of a prefix assignment"
/bin/cp "${HOOK_DIR}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk"
cps_run 'echo hello'
cps_ctl_benign="$CPS_RC"
cps_run 'rm -rf /tmp/foo'
if [ "$cps_ctl_benign" = 0 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'BLOCK-TRASH-001' <<<"$CPS_ERR"; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-CTL the same sandbox with the shipped canonicalizer allows a benign command and refuses the plain form\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-CTL the sandbox with the shipped canonicalizer is not live (benign exit=%s, plain-form exit=%s)\n' "$cps_ctl_benign" "$CPS_RC"
  FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$cps_root"

# ----- AC-D020-NEUTRAL (#8444): transformation (e) moves no verdict of this hook -----
#
# (e) inserts `; ` before every assignment the canonicalizer's default walk skips, so a rule
# anchored on an assignment (BLOCK-DESTRUCTIVE-020, -023) reads it at a command start. No rule of
# this hook is anchored on an assignment, so (e) must move none of its verdicts. Shown, not
# argued: a copy of the canonicalizer with (e)'s two marked lines removed is built and shown live
# (it differs from the shipped copy by exactly those lines, and it parses). Then, on each witness,
# the exit view is byte-identical across the two copies, the default view is not (the witness
# really carries an (e) mark), and this hook returns the same exit code and the same message
# through either copy. The witnesses put a marked assignment ahead of a git command, of a
# target-less deletion verb and of a refused deletion, in plain form and behind a wrapper or a
# condition keyword; the control shows the sandbox live.
neu_root="$(/usr/bin/mktemp -d)"
neu_hooks="${neu_root}/.claude/hooks"
/bin/mkdir -p "${neu_hooks}/lib"
/bin/cp "${HOOK_DIR}/lib/"*.sh "${neu_hooks}/lib/" 2>/dev/null || true
/bin/cp "$HOOK" "${neu_hooks}/block-rm-prefer-trash.sh"
neu_ship="${HOOK_DIR}/lib/command-position.awk"
neu_noe="${neu_root}/command-position-no-e.awk"
/usr/bin/sed -e '/# (e) CMDPOS-E$/d' "$neu_ship" > "$neu_noe"
neu_n="$(/usr/bin/diff "$neu_ship" "$neu_noe" 2>/dev/null | /usr/bin/grep -c '^[<>]' || true)"
neu_live=0
if [ "$neu_n" = 2 ] && /usr/bin/awk -f "$neu_noe" </dev/null >/dev/null 2>&1; then neu_live=1; fi
if [ "$neu_live" = 1 ]; then
  /usr/bin/printf 'PASS: AC-D020-NEUTRAL-LIVE the copy without (e) differs from the shipped canonicalizer by exactly its two marked lines, and parses\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D020-NEUTRAL-LIVE the copy without (e) is not live (differing lines: %s, expected 2)\n' "${neu_n:-none}"
  FAIL=$((FAIL + 1))
fi
neu_view() { # $1 = canonicalizer copy  $2 = view (default | exit)  $3 = command -> stdout
  if [ "$2" = exit ]; then
    /usr/bin/awk -v CMDPOS_VIEW=exit -f "$1" <<<"$3" 2>/dev/null
  else
    /usr/bin/awk -f "$1" <<<"$3" 2>/dev/null
  fi
}
neu_run() { # $1 = canonicalizer copy  $2 = command -> NEU_RC and NEU_ERR
  /bin/cp "$1" "${neu_hooks}/lib/command-position.awk"
  NEU_RC=0
  NEU_ERR="$( ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
      /usr/bin/printf '%s' "$(bash_payload "$2" "$neu_root")" | /bin/bash "${neu_hooks}/block-rm-prefer-trash.sh" 2>&1 >/dev/null ) )" || NEU_RC="$?"
}
neu_case() { # $1 = arm label  $2 = command
  local ev_same=no dv_diff=no rc_ship err_ship
  if [ "$(neu_view "$neu_ship" exit "$2")" = "$(neu_view "$neu_noe" exit "$2")" ]; then ev_same=yes; fi
  if [ "$(neu_view "$neu_ship" default "$2")" != "$(neu_view "$neu_noe" default "$2")" ]; then dv_diff=yes; fi
  neu_run "$neu_ship" "$2"; rc_ship="$NEU_RC"; err_ship="$NEU_ERR"
  neu_run "$neu_noe" "$2"
  if [ "$neu_live" = 1 ] && [ "$ev_same" = yes ] && [ "$dv_diff" = yes ] \
     && [ "$rc_ship" = "$NEU_RC" ] && [ "$err_ship" = "$NEU_ERR" ]; then
    /usr/bin/printf 'PASS: %s exit view unchanged, default view marked, verdict unchanged through either copy (exit %s)\n' "$1" "$rc_ship"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s copy live=%s, exit view unchanged=%s, default view marked=%s, exit %s with (e) and %s without\n' \
      "$1" "$neu_live" "$ev_same" "$dv_diff" "$rc_ship" "$NEU_RC"
    FAIL=$((FAIL + 1))
  fi
}
neu_run "$neu_ship" 'echo hello'
neu_ctl_benign="$NEU_RC"
neu_run "$neu_ship" 'rm -rf /tmp/foo'
if [ "$neu_ctl_benign" = 0 ] && [ "$NEU_RC" = 2 ] && /usr/bin/grep -q 'BLOCK-TRASH-001' <<<"$NEU_ERR"; then
  /usr/bin/printf 'PASS: AC-D020-NEUTRAL-CTL the sandbox allows a benign command and refuses the plain-form deletion\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D020-NEUTRAL-CTL the sandbox is not live (benign exit=%s, plain-form exit=%s)\n' "$neu_ctl_benign" "$NEU_RC"
  FAIL=$((FAIL + 1))
fi
neu_case "AC-D020-NEUTRAL-1: a git command behind a marked assignment, beside a deletion (Step 1)" 'FOO=1 BAR=2 git status ; rm -rf /tmp/foo'
neu_case "AC-D020-NEUTRAL-2: a git command behind env and its assignment, beside a deletion (Step 1)" 'env FOO=1 git log ; rm -rf /tmp/foo'
neu_case "AC-D020-NEUTRAL-3: a target-less rm behind a marked assignment, before a trash call (Step 2)" 'FOO=1 BAR=2 rm ; trash /etc/hosts'
neu_case "AC-D020-NEUTRAL-4: a target-less rm behind env and its assignment, before an unlink (Step 2)" 'env FOO=1 rm ; sudo unlink /tmp/foo'
neu_case "AC-D020-NEUTRAL-5: a refused deletion behind a marked assignment" 'FOO=1 BAR=2 rm -rf /tmp/foo'
neu_case "AC-D020-NEUTRAL-6: a git condition behind a marked assignment, with a deletion in its branch" 'if FOO=1 git diff --quiet ; then rm -rf /tmp/foo ; fi'
/bin/rm -rf "$neu_root"

# ----- EXT-SEG (#8122): every segment of the line is judged -----
#
# The hook keeps no exit that allows on a match. A git command exempts only its own segment, and
# a deletion verb with no operand ends nothing: every rm-family verb, the Trash step and the Finder
# step are still judged on the line's other segments. A Trash segment that does not name all its
# targets on its line is refused under the strict policy (BLOCK-TRASH-003), and so, judged after
# every other step, is an rm, rmdir or unlink segment of that kind (BLOCK-TRASH-001). A trailing
# line-continuation backslash is not an operand, and a verb segment whose line continues does not
# show all its targets.
#   G    a git segment, then a deletion, a Trash call or a Finder delete of an outside path (AC1)
#   T    a target-less rm-family verb, then another verb's outside target (AC2). The arms that end
#        in an rm-family refusal assert the outside path, so a single-verb pick, which would refuse
#        with the no-operand message instead, is told apart. T0 is the same-verb control
#   B    a Trash segment with no operand, or whose line continues (AC3); B6 shows that the limb
#        never masks a refusal elsewhere on the line; B9 to B12 carry a redirection with an ampersand
#   D    a directory change whose operand follows a redirection with an ampersand
#   C    controls that stay allowed: git alone, commit messages inline and in a top-level quoted
#        here-document read by git, also behind -C <dir> (AC4), a describe-only use of a verb, an
#        untracking git rm. C20 is re-based: the continuation rule (EXT-CONT) refuses it now
#   P    pins: the declared allow-to-refuse moves, the declared over-blocks, a declared residual
#   MUT  each new marker shown load-bearing: a copy of the hook without it allows its sentinels. A
#        sentinel that continues onto a second line is refused by the continuation rule whatever the
#        marker, so the per-form markers' sentinels are single-line (EXT-CONT-EOF)
#   INT1 the heredoc-borne controls shown held by the here-document pre-pass: through a copy whose
#        pre-pass never removes a body (armed red), each is refused; through the hook it is allowed
SEG_OUT='deletion outside .*Path: (/private)?'
SEG_FH="$RMT_FIXTURE_HOME"
test_case "EXT-SEG-G1: a git segment, then && and a recursive rm of an outside path, is refused" \
  "$(bash_payload 'git status && rm -rf /tmp/seg-g1')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-G2: a git segment, then ; and a recursive rm of an outside path, is refused" \
  "$(bash_payload 'git status ; rm -rf /tmp/seg-g2')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-G3: a git segment by absolute path, then a recursive rm of an outside path, is refused" \
  "$(bash_payload '/usr/bin/git status ; rm -rf /tmp/seg-g3')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-G4: a git line, then a recursive rm of an outside path on the next line, is refused" \
  "$(bash_payload $'git status\nrm -rf /tmp/seg-g4')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-G5: a git segment, then a Trash call on an outside path, is refused" \
  "$(bash_payload 'git status ; trash /tmp/seg-g5')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-G6: a git segment, then a Finder delete of an outside path, is refused" \
  "$(bash_payload $'git status ; osascript -e \'tell application "Finder" to delete POSIX file "/tmp/seg-g6"\'')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-T0: a flags-only rm, then a recursive rm of an outside path (the same verb, refused before and after)" \
  "$(bash_payload 'rm -f ; rm -rf /tmp/seg-t0')" 2 "BLOCK-TRASH-001.*${SEG_OUT}/tmp/seg-t0"
test_case "EXT-SEG-T1: a flags-only rm, then unlink of an outside path, is refused on that path" \
  "$(bash_payload 'rm -f ; unlink /tmp/seg-t1')" 2 "BLOCK-TRASH-001.*${SEG_OUT}/tmp/seg-t1"
test_case "EXT-SEG-T2: a flags-only rm, then a Trash call on an outside path, is refused" \
  "$(bash_payload 'rm -f && trash /tmp/seg-t2')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-T3: a bare rmdir, then unlink of an outside path, is refused on that path" \
  "$(bash_payload 'rmdir ; unlink /tmp/seg-t3')" 2 "BLOCK-TRASH-001.*${SEG_OUT}/tmp/seg-t3"
test_case "EXT-SEG-T4: a bare rm, then a Finder delete of an outside path, is refused" \
  "$(bash_payload $'rm ; osascript -e \'tell application "Finder" to delete POSIX file "/tmp/seg-t4"\'')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-T5: a target-less rm behind a wrapper option, then unlink of an outside path behind the same wrapper, is refused on that path" \
  "$(bash_payload 'nice -n 5 rm ; nice -n 5 unlink /tmp/seg-t5')" 2 "BLOCK-TRASH-001.*${SEG_OUT}/tmp/seg-t5"
test_case "EXT-SEG-T6: a flags-only rm on one line, unlink of an outside path on the next, is refused on that path" \
  "$(bash_payload $'rm -f\nunlink /tmp/seg-t6')" 2 "BLOCK-TRASH-001.*${SEG_OUT}/tmp/seg-t6"
test_case "EXT-SEG-T7: an rm whose line continues past its flags does not show its targets and is refused" \
  "$(bash_payload $'rm -f \\\n/tmp/seg-t7')" 2 "BLOCK-TRASH-001.*does not name all its targets"
test_case "EXT-SEG-B1: a Trash call with no operand is refused" \
  "$(bash_payload 'trash')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-B2: a Trash call carrying only a verbose flag is refused" \
  "$(bash_payload 'trash -v')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-B3: a Trash call carrying only its empty-the-Trash and skip-confirmation flags is refused" \
  "$(bash_payload 'trash -e -y')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-B4: an inside Trash call, then a flags-only Trash call, is refused (per segment)" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b4 ; trash -v" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-SEG-B5: a flags-only Trash call behind a wrapper is refused" \
  "$(bash_payload 'nice trash -v')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-B6: a flags-only Trash call, then a recursive rm of an outside path, is refused on that path" \
  "$(bash_payload 'trash -v ; rm -rf /tmp/seg-b6')" 2 "BLOCK-TRASH-001.*${SEG_OUT}/tmp/seg-b6"
test_case "EXT-SEG-B7: a Trash call whose line continues past its flags is refused" \
  "$(bash_payload $'trash -v \\\n/tmp/seg-b7')" 2 "BLOCK-TRASH-003.*does not name all its targets"
test_case "EXT-SEG-B8: an inside Trash operand, a continued line, and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b8 \\"$'\n'"/tmp/seg-b8" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
SEG_C4=$'git commit -F - <<\'EOF\'\nfix the hook\nrm -rf build\nEOF'
SEG_C7=$'git commit -F - <<\'EOF\'\nnote: $(echo hi; rm -rf build) is text\nEOF'
SEG_C8=$'git commit -F - <<\'EOF\'\ndon\'t\nrm -rf build\nEOF'
SEG_C11=$'git -C /tmp/seg-repo commit -F - <<\'EOF\'\nrm -rf build\nEOF'
test_case "EXT-SEG-C1: git status alone is allowed" \
  "$(bash_payload 'git status')" 0
test_case "EXT-SEG-C2: a commit message carrying deletion-verb text inline is allowed" \
  "$(bash_payload 'git commit -m "rm stale files; unlink old"')" 0
test_case "EXT-SEG-C3: a multi-line inline message with a line that begins with a deletion verb is allowed" \
  "$(bash_payload $'git commit -m "first line\nrm -rf build\nlast line"')" 0
test_case "EXT-SEG-C4: a commit message from a top-level quoted here-document, a line beginning with a deletion verb, is allowed" \
  "$(bash_payload "$SEG_C4")" 0
test_case "EXT-SEG-C5: a message in a double-quoted substitution, with an apostrophe and a deletion line, is allowed (quote-masked)" \
  "$(bash_payload $'git commit -m "$(cat <<\'EOF\'\ndon\'t fix it\nrm -rf build\nEOF\n)"')" 0
test_case "EXT-SEG-C7: a here-document message carrying a substitution-shaped string before deletion text is allowed" \
  "$(bash_payload "$SEG_C7")" 0
test_case "EXT-SEG-C8: a here-document message with an unpaired apostrophe is allowed" \
  "$(bash_payload "$SEG_C8")" 0
test_case "EXT-SEG-C9: asking where the Trash program is does not run it and is allowed" \
  "$(bash_payload 'command -v trash')" 0
test_case "EXT-SEG-C10: untracking a file and committing is allowed" \
  "$(bash_payload 'git rm -r --cached foo && git commit -m "untrack foo"')" 0
test_case "EXT-SEG-C11: git -C <dir> commit with a here-document message carrying a deletion line is allowed" \
  "$(bash_payload "$SEG_C11")" 0
test_case "EXT-SEG-P1: a flags-only rm alone is refused (no operand)" \
  "$(bash_payload 'rm -f')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-P2: a flags-only rm inside a subshell group is refused (no operand)" \
  "$(bash_payload '( rm -rf )')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-P3: a Trash help request is refused (a declared over-block)" \
  "$(bash_payload 'trash --help')" 2 "BLOCK-TRASH-003"
test_case "EXT-SEG-P4: a commit message from an unquoted here-document with a deletion line is judged (a declared move)" \
  "$(bash_payload $'git commit -F - <<EOF\nrm -rf build\nEOF' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"
test_case "EXT-SEG-P5: an rm help request is refused (a declared over-block)" \
  "$(bash_payload 'rm --help')" 2 "BLOCK-TRASH-001"
test_case "EXT-SEG-P6: a Trash call continued onto a second line of inside operands is refused (a declared over-block)" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-p6a \\"$'\n'"${SEG_FH}/Claude/seg-p6b" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-SEG-P7: a Trash call with its empty-the-Trash flags and one inside operand is allowed (a declared residual)" \
  "$(bash_payload "trash -e -y ${SEG_FH}/Claude/seg-p7" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-P8: a here-document commit message on a command that pipes elsewhere is judged (a declared move)" \
  "$(bash_payload $'git commit -F - <<\'EOF\'\nrm -rf build\nEOF\ngit log --oneline | cat' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"
test_case "EXT-SEG-C6: a message in a double-quoted substitution with an unpaired double quote is judged (the declared move, Q1)" \
  "$(bash_payload $'git commit -m "$(cat <<\'EOF\'\nsay "hi\nrm -rf build\nEOF\n)"' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

# A redirection that carries an ampersand (Stage 7, #8122 F-03 and F-04). The walk cuts the line on every
# ampersand, and the canonicalizer reads one in a redirection as a separator too, so a Trash call with
# such a redirection lost the operands after it (B10 to B12, the dirs reader in D1) and the continuation
# test never saw its line continue (B9). The line's continuation is now read once per record (P9: the
# declared over-block that reading brings), and the operand reading goes on past the ampersand of an
# operator left without its word and past a both-streams redirection. C12 to C17 are the common shapes
# that stay allowed.
test_case "EXT-SEG-B9: an inside Trash operand, a descriptor duplication, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b9 2>&1 \\"$'\n'"/tmp/seg-b9" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B10: an outside Trash operand after a descriptor duplication on the same line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b10 2>&1 /tmp/seg-b10" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*${SEG_OUT}/tmp/seg-b10" "$RMT_HOME_ENV"
test_case "EXT-SEG-B11: an outside Trash operand after a both-streams redirection on the same line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b11 &>/dev/null /tmp/seg-b11" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*${SEG_OUT}/tmp/seg-b11" "$RMT_HOME_ENV"
test_case "EXT-SEG-B12: an outside Trash operand after a descriptor duplication spelled with a blank before its word is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b12 2>& 1 /tmp/seg-b12" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*${SEG_OUT}/tmp/seg-b12" "$RMT_HOME_ENV"
test_case "EXT-SEG-D1: a directory change whose operand follows a descriptor duplication moves a later relative Trash operand" \
  "$(bash_payload 'cd 2>&1 /tmp/seg-d1 && trash seg-d1-rel')" 2 "BLOCK-TRASH-003.*${SEG_OUT}/tmp/seg-d1/seg-d1-rel" "CLAUDE_WORKSPACE_ROOT=${HOME}"
test_case "EXT-SEG-P9: an inside Trash call on a line that continues past a later command is refused (a declared over-block)" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-p9 && echo done \\"$'\n'"more" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-C12: an inside Trash call with its error stream duplicated is allowed" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c12 2>&1" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-C13: an inside Trash call with output to the null device and its error stream duplicated is allowed" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c13 >/dev/null 2>&1" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-C14: an inside Trash call with both streams to the null device is allowed" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c14 &>/dev/null" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-C15: an inside Trash call that closes its error stream is allowed" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c15 2>&-" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-C16: two inside Trash operands either side of a descriptor duplication are allowed" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c16a 2>&1 ${SEG_FH}/Claude/seg-c16b" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-C17: an inside Trash call with its error stream duplicated into a pipe is allowed" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c17 2>&1 | tail -3" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
# A separator the line itself carries before a compound keyword or a command-prefix word ends the
# reading past a both-streams redirection: the canonicalizer marks such a word with a separator after
# it, not before, so the word is not an operand (C18 from a cwd outside the workspace, C19 a cd).
test_case "EXT-SEG-C18: an inside Trash call with both streams to the null device as an if condition is allowed" \
  "$(bash_payload "if trash ${SEG_FH}/Claude/seg-c18 &>/dev/null; then echo ok; fi" "$RMT_FIXTURE_OTHER_HOME")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-SEG-C19: a directory change with both streams to the null device as an if condition, then a relative inside Trash target, is allowed" \
  "$(bash_payload "if cd ${SEG_FH}/Claude/sub &>/dev/null; then trash seg-c19; fi" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
# A continued line whose backslash follows a redirection that carries an ampersand or a pipe (Stage 7
# re-verify, #8122 R-01). Where the walk cuts such a redirection, the backslash after it can become a
# new command word to the canonicalizer, which drops a single leading backslash from one, so the
# record's last word is no longer the backslash. B13 to B15 keep the backslash as a word; in B16 to
# B20 it is dropped, and what the canonicalizer leaves at the line's end — a redirection left without
# its word, or a both-streams redirection and then the separator it inserted — reads as a continued
# line too. Every one is refused. P10 is the declared over-block of that reading. C20 is a separator
# before the backslash, which begins the next line's command, so these readings allow it; the
# continuation rule (EXT-CONT) refuses it, a declared over-block.
test_case "EXT-SEG-B13: an inside Trash operand, an output duplication onto the error stream, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b13 >&2 \\"$'\n'"/tmp/seg-b13" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B14: an inside Trash operand, a descriptor duplication spelled with a blank before its word, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b14 2>& 1 \\"$'\n'"/tmp/seg-b14" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B15: an inside Trash operand, a closed error stream, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b15 2>&- \\"$'\n'"/tmp/seg-b15" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B16: an inside Trash operand, both streams truncated to a file, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b16 &>/dev/null \\"$'\n'"/tmp/seg-b16" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B17: an inside Trash operand, both streams appended to a file, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b17 &>>/dev/null \\"$'\n'"/tmp/seg-b17" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B18: an inside Trash operand, both streams redirected with a blank before the file, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b18 &> /dev/null \\"$'\n'"/tmp/seg-b18" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B19: an inside Trash operand, a descriptor duplication whose word is on the next line, and an outside operand after that word is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b19 2>& \\"$'\n'"1 /tmp/seg-b19" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-B20: an inside Trash operand, a clobbering output redirection whose file is on the next line, and an outside operand after that file is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-b20 >| \\"$'\n'"seg-b20-log /tmp/seg-b20" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-P10: an inside Trash call whose line ends in a both-streams redirection, a separator and one blank is refused (a declared over-block)" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-p10 &>/dev/null ; " "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-SEG-C20: an inside Trash call on a line that ends in a separator and a continuation backslash, then a plain command, is refused (re-based: a declared over-block of the continuation rule)" \
  "$(bash_payload "trash ${SEG_FH}/Claude/seg-c20 && \\"$'\n'"echo done" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*line continuation" "$RMT_HOME_ENV"

# ----- EXT-CONT (#8122, operator decision): a command that carries a line continuation -----
#
# Outside the quoted here-document bodies the pre-pass removes, a line that ends in an odd run of
# backslashes continues onto the next line, and the shell joins the two before it reads a word: a
# continuation can split a command word, or carry a wrapper option's argument or an assignment's value
# to the next line. An even run is literal backslashes and continues nothing, and a backslash that ends
# a comment continues nothing either, so the next line runs as its own command. On a command that
# carries such a run, the hook reads it twice — as judged, each line its own, and with every
# continuation joined — and refuses a deletion or Trash verb found in either reading, judged after every
# other step: BLOCK-TRASH-003 for a Trash call or a Finder delete, else BLOCK-TRASH-001. That rule
# decides every continued command; the per-form readings of EXT-SEG stay in place and still refuse
# first where they fire. Declared over-block: every command with a continuation and a deletion or Trash
# verb is refused, whatever the shell would join.
#   W    a continuation inside the command word: the shell runs the joined word
#   R    a continuation after each redirection form, complete or with its word on the next line (the
#        descriptor duplication, closing and both-streams forms are EXT-SEG-B9 and B13 to B20)
#   X    a continuation after a wrapper word, between a wrapper option and its argument, or after a keyword
#   A    a continuation after an assignment-shaped word, plain or append form
#   T    a run of three backslashes: a literal backslash, then a continuation
#   K    a backslash that ends a comment, which continues nothing; K3 is the residual neither reading sees
#   E    an even run of backslashes, which continues nothing (controls)
#   N    controls: a continued command with no deletion or Trash command, a quoted message, and a quoted
#        here-document body whose lines end in a backslash
#   EOF  a continuation backslash that ends the command, with no newline after it: nothing joins, so the
#        per-form readings alone refuse it; these are the single-line sentinels of their mutant pairs
#   MUT  each new marker shown load-bearing; DEC the rule shown deciding: a copy without the three
#        per-form readings refuses every continued EXT-SEG and R arm by this rule alone
CONT_RE='line continuation'
test_case "EXT-CONT-W1: an rm whose command word a continuation splits, of an outside path, is refused" \
  "$(bash_payload $'r\\\nm -rf /tmp/cont-w1')" 2 "BLOCK-TRASH-001.*${CONT_RE}"
test_case "EXT-CONT-W2: an rmdir whose command word a continuation splits, of an outside path, is refused" \
  "$(bash_payload $'rmd\\\nir /tmp/cont-w2')" 2 "BLOCK-TRASH-001.*${CONT_RE}"
test_case "EXT-CONT-W3: an unlink whose command word a continuation splits, of an outside path, is refused" \
  "$(bash_payload $'un\\\nlink /tmp/cont-w3')" 2 "BLOCK-TRASH-001.*${CONT_RE}"
test_case "EXT-CONT-W4: a Trash call whose command word a continuation splits, on an outside path, is refused" \
  "$(bash_payload $'tr\\\nash /tmp/cont-w4')" 2 "BLOCK-TRASH-003.*${CONT_RE}"
test_case "EXT-CONT-W5: a Trash call at the keg-only location whose command word a continuation splits is refused" \
  "$(bash_payload "${RMT_KEG%ash}\\"$'\n'"ash /tmp/cont-w5")" 2 "BLOCK-TRASH-003.*${CONT_RE}"
test_case "EXT-CONT-W6: a Finder delete whose command word a continuation splits, of an outside path, is refused" \
  "$(bash_payload $'osa\\\nscript -e \'tell application "Finder" to delete POSIX file "/tmp/cont-w6"\'')" 2 "BLOCK-TRASH-003.*${CONT_RE}"
test_case "EXT-CONT-W7: an rm by absolute path whose command word a continuation splits is refused" \
  "$(bash_payload $'/bin/r\\\nm -rf /tmp/cont-w7')" 2 "BLOCK-TRASH-001.*${CONT_RE}"
test_case "EXT-CONT-W8: an unlink whose command word two continuations split is refused" \
  "$(bash_payload $'un\\\nli\\\nnk /tmp/cont-w8')" 2 "BLOCK-TRASH-001.*${CONT_RE}"
test_case "EXT-CONT-R1: an inside Trash operand, output truncated to a file, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r1 >/dev/null \\"$'\n'"/tmp/cont-r1" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R2: an inside Trash operand, output appended to a file, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r2 >>/dev/null \\"$'\n'"/tmp/cont-r2" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R3: an inside Trash operand, a clobbering output redirection, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r3 >|/dev/null \\"$'\n'"/tmp/cont-r3" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R4: an inside Trash operand, a word-form duplication to a file, a continued line and an outside operand on the next line is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r4 >&/dev/null \\"$'\n'"/tmp/cont-r4" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R5: an inside Trash operand, a truncating redirection whose file is on the next line, and an outside operand after it is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r5 > \\"$'\n'"/tmp/cont-r5.log /tmp/cont-r5" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R6: an inside Trash operand, an appending redirection whose file is on the next line, and an outside operand after it is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r6 >> \\"$'\n'"/tmp/cont-r6.log /tmp/cont-r6" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R7: an inside Trash operand, a both-streams redirection whose file is on the next line, and an outside operand after it is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r7 &> \\"$'\n'"/tmp/cont-r7.log /tmp/cont-r7" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-R8: an inside Trash operand, a word-form duplication whose file is on the next line, and an outside operand after it is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-r8 >& \\"$'\n'"/tmp/cont-r8.log /tmp/cont-r8" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003" "$RMT_HOME_ENV"
test_case "EXT-CONT-X1: a continuation between a wrapper option and its argument, before a Trash call on an outside path, is refused" \
  "$(bash_payload $'nice -n \\\n5 trash /tmp/cont-x1')" 2 "BLOCK-TRASH-003.*${CONT_RE}"
test_case "EXT-CONT-X2: a continuation after a wrapper word, before its option and a Trash call on an outside path, is refused" \
  "$(bash_payload $'nice \\\n-n 5 trash /tmp/cont-x2')" 2 "BLOCK-TRASH-003.*${CONT_RE}"
test_case "EXT-CONT-X3: a continuation after a keyword, before a Trash call on an outside path, is refused" \
  "$(bash_payload $'if true; then \\\ntrash /tmp/cont-x3; fi')" 2 "BLOCK-TRASH-003"
test_case "EXT-CONT-A1: a continuation inside an assignment's value, before a Trash call on an outside path, is refused" \
  "$(bash_payload $'CONT_A1=\\\n1 trash /tmp/cont-a1')" 2 "BLOCK-TRASH-003.*${CONT_RE}"
test_case "EXT-CONT-A2: a continuation inside an append-form assignment's value, before an unlink of an outside path, is refused" \
  "$(bash_payload $'CONT_A2+=\\\n1 unlink /tmp/cont-a2')" 2 "BLOCK-TRASH-001.*${CONT_RE}"
test_case "EXT-CONT-A3: a continuation after a whole assignment, before a recursive rm of an outside path, is refused" \
  "$(bash_payload $'CONT_A3=1 \\\nrm -rf /tmp/cont-a3')" 2 "BLOCK-TRASH-001"
test_case "EXT-CONT-T1: a run of three backslashes inside a word that is then not a Trash verb is allowed (the joined reading keeps the literal backslash)" \
  "$(bash_payload $'tr\\\\\\\nash /tmp/cont-t1')" 0
test_case "EXT-CONT-T2: a run of three backslashes after an echo word, then an inside Trash call at the next line's start, is refused (a declared over-block)" \
  "$(bash_payload "echo cont-t2 \\\\\\"$'\n'"trash ${SEG_FH}/Claude/cont-t2" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*${CONT_RE}" "$RMT_HOME_ENV"
test_case "EXT-CONT-T3: a Trash call carrying a flag and a run of three backslashes before a newline is refused" \
  "$(bash_payload $'trash -v \\\\\\\n/tmp/cont-t3')" 2 "BLOCK-TRASH-003"
test_case "EXT-CONT-K1: a comment that ends in a backslash continues nothing: a Trash call on an outside path on the next line is refused" \
  "$(bash_payload $'echo cont-k1 # note \\\ntrash /tmp/cont-k1')" 2 "BLOCK-TRASH-003"
test_case "EXT-CONT-K2: a comment that ends in a backslash, then an inside Trash call on the next line, is refused (a declared over-block)" \
  "$(bash_payload "echo cont-k2 # note \\"$'\n'"trash ${SEG_FH}/Claude/cont-k2" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*${CONT_RE}" "$RMT_HOME_ENV"
test_case "EXT-CONT-K3: a comment that ends in a backslash, then an rm whose command word a continuation splits, is allowed (a declared residual: neither reading sees it)" \
  "$(bash_payload $'echo cont-k3 # note \\\nr\\\nm -rf /tmp/cont-k3')" 0
test_case "EXT-CONT-E1: an even run of backslashes continues nothing: an inside Trash call on the next line is allowed" \
  "$(bash_payload "echo cont-e1 \\\\"$'\n'"trash ${SEG_FH}/Claude/cont-e1" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "EXT-CONT-E2: an even run of backslashes inside a word continues nothing, so no deletion verb is formed, and is allowed" \
  "$(bash_payload $'r\\\\\nm -rf /tmp/cont-e2')" 0
test_case "EXT-CONT-N1: a continued echo with no deletion or Trash command is allowed" \
  "$(bash_payload $'echo cont-n1 \\\nmore')" 0
test_case "EXT-CONT-N2: a continued container run whose option names a deletion verb is allowed" \
  "$(bash_payload $'docker run \\\n--rm cont-n2')" 0
test_case "EXT-CONT-N3: a continued untracking git rm is allowed" \
  "$(bash_payload $'git rm \\\n--cached cont-n3')" 0
test_case "EXT-CONT-N4: a double-quoted commit message continued with a backslash onto a line of deletion-verb text is allowed" \
  "$(bash_payload $'git commit -m "fix the hook \\\nrm -rf build"')" 0
test_case "EXT-CONT-N5: a quoted here-document commit message whose body line ends in a backslash, then a deletion line, is allowed" \
  "$(bash_payload $'git commit -F - <<\'EOF\'\nfix the hook \\\nrm -rf build\nEOF')" 0
test_case "EXT-CONT-EOF1: a Trash call carrying only a flag and ending the command in a continuation backslash is refused" \
  "$(bash_payload 'trash -v \')" 2 "BLOCK-TRASH-003.*does not name all its targets"
test_case "EXT-CONT-EOF2: an rm carrying only a flag and ending the command in a continuation backslash is refused" \
  "$(bash_payload 'rm -f \')" 2 "BLOCK-TRASH-001.*does not name all its targets"
test_case "EXT-CONT-EOF3: an inside Trash operand and a continuation backslash ending the command is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-eof3 \\" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-CONT-EOF4: an inside Trash operand, a descriptor duplication and a continuation backslash ending the command is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-eof4 2>&1 \\" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"
test_case "EXT-CONT-EOF5: an inside Trash operand and a descriptor duplication left without its word at the command's end is refused" \
  "$(bash_payload "trash ${SEG_FH}/Claude/cont-eof5 2>&" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*does not name all its targets" "$RMT_HOME_ENV"

# The mutant pairs. Each copy differs from the hook by exactly its marked line, shown live first;
# each sentinel, refused through the hook, is allowed through its copy.
seg_dir="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-seg.XXXXXX" 2>/dev/null)" || seg_dir=""
seg_armed() { # $1 = arm label  $2 = copy  $3 = command -> refused through the copy
  local rc=0 err
  if ! ra_live "$2"; then
    /usr/bin/printf 'FAIL: %s the copy is not live (it does not differ from the hook by exactly its one marked line, or does not parse)\n' "$1"
    FAIL=$((FAIL + 1)); return
  fi
  err="$(/usr/bin/printf '%s' "$(bash_payload "$3")" | /bin/bash "$2" 2>&1 >/dev/null)" || rc="$?"
  if [ "$rc" = 2 ]; then
    /usr/bin/printf 'PASS: %s through the copy without the pre-pass the control is refused, so the pre-pass holds it\n' "$1"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s the copy without the pre-pass did not refuse the control (exit=%s): %s\n' "$1" "$rc" "$err"
    FAIL=$((FAIL + 1))
  fi
}
if [ -z "$seg_dir" ]; then
  /usr/bin/printf 'FAIL: EXT-SEG mutant pairs could not create a sandbox, so they did not run\n'
  FAIL=$((FAIL + 1))
else
  /bin/mkdir -p "${seg_dir}/lib"
  /bin/cp "${HOOK_DIR}/lib/dep-resolve.sh" "${HOOK_DIR}/lib/command-position.awk" "${seg_dir}/lib/"
  /usr/bin/sed -e "$SEG_SED_WALK" "$HOOK" > "${seg_dir}/block-rm-prefer-trash-segwalk.sh"
  /usr/bin/sed -e "$SEG_SED_VERB" "$HOOK" > "${seg_dir}/block-rm-prefer-trash-segverb.sh"
  /usr/bin/sed -e 's/^\([[:space:]]*\)if \[ -n "\$(extract_bare_segments trash)" ]; then  # M-TRASH-BARETRASH$/\1if false; then  # M-TRASH-BARETRASH/' \
    "$HOOK" > "${seg_dir}/block-rm-prefer-trash-baretrash.sh"
  /usr/bin/sed -e 's/^\([[:space:]]*\)if matches .*  # M-TRASH-BARERM$/\1if false; then  # M-TRASH-BARERM/' \
    "$HOOK" > "${seg_dir}/block-rm-prefer-trash-barerm.sh"
  /usr/bin/sed -e 's/^\([[:space:]]*\)EXCISED\$'"'"'\\n'"'"'?\*) COMMAND=.*$/\1EXCISED$'"'"'\\n'"'"'?*) : ;;/' \
    "$HOOK" > "${seg_dir}/block-rm-prefer-trash-nohd.sh"
  for seg_mk in RECCONT RECWORD RECBOTH REDIRAMP BOTHREDIR CONTLINE CONTUNJ CONTJOIN; do
    /usr/bin/sed -e 's/^\([[:space:]]*\).*  # M-TRASH-'"$seg_mk"'$/\1# M-TRASH-'"$seg_mk"' (removed)/' \
      "$HOOK" > "${seg_dir}/block-rm-prefer-trash-${seg_mk}.sh"
  done
  # DEC — the three per-form readings removed together, so only the continuation rule can refuse.
  /usr/bin/sed -e 's/^\([[:space:]]*\).*  # M-TRASH-RECCONT$/\1# M-TRASH-RECCONT (removed)/' \
    -e 's/^\([[:space:]]*\).*  # M-TRASH-RECWORD$/\1# M-TRASH-RECWORD (removed)/' \
    -e 's/^\([[:space:]]*\).*  # M-TRASH-RECBOTH$/\1# M-TRASH-RECBOTH (removed)/' \
    "$HOOK" > "${seg_dir}/block-rm-prefer-trash-noperform.sh"
  ra_pair "EXT-SEG-MUT-SEGWALK-G1:" "${seg_dir}/block-rm-prefer-trash-segwalk.sh" 'git status && rm -rf /tmp/seg-g1'
  ra_pair "EXT-SEG-MUT-SEGWALK-G5:" "${seg_dir}/block-rm-prefer-trash-segwalk.sh" 'git status ; trash /tmp/seg-g5'
  ra_pair "EXT-SEG-MUT-SEGVERB-T1:" "${seg_dir}/block-rm-prefer-trash-segverb.sh" 'rm -f ; unlink /tmp/seg-t1'
  ra_pair "EXT-SEG-MUT-SEGVERB-T2:" "${seg_dir}/block-rm-prefer-trash-segverb.sh" 'rm -f && trash /tmp/seg-t2'
  ra_pair "EXT-SEG-MUT-SEGVERB-T4:" "${seg_dir}/block-rm-prefer-trash-segverb.sh" $'rm ; osascript -e \'tell application "Finder" to delete POSIX file "/tmp/seg-t4"\''
  ra_pair "EXT-SEG-MUT-BARETRASH-B1:" "${seg_dir}/block-rm-prefer-trash-baretrash.sh" 'trash'
  ra_pair "EXT-SEG-MUT-BARETRASH-B2:" "${seg_dir}/block-rm-prefer-trash-baretrash.sh" 'trash -v'
  # The six sentinels below are single-line (re-based for the continuation rule, EXT-CONT): one that
  # continued onto a second line is refused by that rule through every one of these copies. Their
  # refusal through the hook is EXT-CONT-EOF1 to EOF5 and EXT-SEG-P10.
  ra_pair "EXT-SEG-MUT-BARETRASH-B7:" "${seg_dir}/block-rm-prefer-trash-baretrash.sh" 'trash -v \'
  ra_pair "EXT-SEG-MUT-BARERM-P1:" "${seg_dir}/block-rm-prefer-trash-barerm.sh" 'rm -f'
  ra_pair "EXT-SEG-MUT-BARERM-P2:" "${seg_dir}/block-rm-prefer-trash-barerm.sh" '( rm -rf )'
  ra_pair "EXT-SEG-MUT-BARERM-T7:" "${seg_dir}/block-rm-prefer-trash-barerm.sh" 'rm -f \'
  ra_pair "EXT-SEG-MUT-RECCONT-B8:" "${seg_dir}/block-rm-prefer-trash-RECCONT.sh" 'trash seg-mut-b8 \'
  ra_pair "EXT-SEG-MUT-RECCONT-B9:" "${seg_dir}/block-rm-prefer-trash-RECCONT.sh" 'trash seg-mut-b9 2>&1 \'
  ra_pair "EXT-SEG-MUT-RECWORD-B19:" "${seg_dir}/block-rm-prefer-trash-RECWORD.sh" 'trash seg-mut-b19 2>&'
  ra_pair "EXT-SEG-MUT-RECBOTH-B16:" "${seg_dir}/block-rm-prefer-trash-RECBOTH.sh" 'trash seg-mut-b16 &>/dev/null ; '
  # EXT-CONT: the continuation rule's three markers — the rule itself (CONTLINE), its reading of the
  # command as judged (CONTUNJ) and its joined reading (CONTJOIN).
  ra_pair "EXT-CONT-MUT-CONTLINE-W1:" "${seg_dir}/block-rm-prefer-trash-CONTLINE.sh" $'r\\\nm -rf /tmp/cont-w1'
  ra_pair "EXT-CONT-MUT-CONTLINE-W4:" "${seg_dir}/block-rm-prefer-trash-CONTLINE.sh" $'tr\\\nash /tmp/cont-w4'
  ra_pair "EXT-CONT-MUT-CONTLINE-W6:" "${seg_dir}/block-rm-prefer-trash-CONTLINE.sh" $'osa\\\nscript -e \'tell application "Finder" to delete POSIX file "/tmp/cont-w6"\''
  ra_pair "EXT-CONT-MUT-CONTJOIN-W1:" "${seg_dir}/block-rm-prefer-trash-CONTJOIN.sh" $'r\\\nm -rf /tmp/cont-w1'
  ra_pair "EXT-CONT-MUT-CONTJOIN-X1:" "${seg_dir}/block-rm-prefer-trash-CONTJOIN.sh" $'nice -n \\\n5 trash /tmp/cont-x1'
  ra_pair "EXT-CONT-MUT-CONTUNJ-K2:" "${seg_dir}/block-rm-prefer-trash-CONTUNJ.sh" $'echo cont-mut-k2 # note \\\ntrash cont-mut-k2'
  ra_pair "EXT-CONT-MUT-CONTUNJ-T2:" "${seg_dir}/block-rm-prefer-trash-CONTUNJ.sh" $'echo cont-mut-t2 \\\\\\\ntrash cont-mut-t2'
  # DEC: through the copy without the three per-form readings (shown live: exactly three lines differ,
  # and it parses), each continued arm is refused by the continuation rule alone.
  cont_decides() { # $1 = arm label  $2 = command (fixture home and working directory)
    local rc=0 err n
    n="$(/usr/bin/diff "$HOOK" "${seg_dir}/block-rm-prefer-trash-noperform.sh" 2>/dev/null | /usr/bin/grep -c '^[<>]' || true)"
    if [ "$n" != 6 ] || ! /bin/bash -n "${seg_dir}/block-rm-prefer-trash-noperform.sh" 2>/dev/null; then
      /usr/bin/printf 'FAIL: %s the copy without the per-form readings is not live (%s differing lines, expected 6, or it does not parse)\n' "$1" "${n:-none}"
      FAIL=$((FAIL + 1)); return
    fi
    err="$(/usr/bin/printf '%s' "$(bash_payload "$2" "$RMT_FIXTURE_CWD")" | /usr/bin/env "$RMT_HOME_ENV" /bin/bash "${seg_dir}/block-rm-prefer-trash-noperform.sh" 2>&1 >/dev/null)" || rc="$?"
    if [ "$rc" = 2 ] && /usr/bin/grep -qE "BLOCK-TRASH-003.*${CONT_RE}" <<<"$err"; then
      /usr/bin/printf 'PASS: %s without the per-form readings the continuation rule refuses it\n' "$1"
      PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s without the per-form readings it was not refused by the continuation rule (exit=%s): %s\n' "$1" "$rc" "$err"
      FAIL=$((FAIL + 1))
    fi
  }
  cont_nl=$'\n'
  cont_decides "EXT-CONT-DEC-B8:" "trash ${SEG_FH}/Claude/seg-b8 \\${cont_nl}/tmp/seg-b8"
  cont_decides "EXT-CONT-DEC-B9:" "trash ${SEG_FH}/Claude/seg-b9 2>&1 \\${cont_nl}/tmp/seg-b9"
  cont_decides "EXT-CONT-DEC-B13:" "trash ${SEG_FH}/Claude/seg-b13 >&2 \\${cont_nl}/tmp/seg-b13"
  cont_decides "EXT-CONT-DEC-B14:" "trash ${SEG_FH}/Claude/seg-b14 2>& 1 \\${cont_nl}/tmp/seg-b14"
  cont_decides "EXT-CONT-DEC-B15:" "trash ${SEG_FH}/Claude/seg-b15 2>&- \\${cont_nl}/tmp/seg-b15"
  cont_decides "EXT-CONT-DEC-B16:" "trash ${SEG_FH}/Claude/seg-b16 &>/dev/null \\${cont_nl}/tmp/seg-b16"
  cont_decides "EXT-CONT-DEC-B17:" "trash ${SEG_FH}/Claude/seg-b17 &>>/dev/null \\${cont_nl}/tmp/seg-b17"
  cont_decides "EXT-CONT-DEC-B18:" "trash ${SEG_FH}/Claude/seg-b18 &> /dev/null \\${cont_nl}/tmp/seg-b18"
  cont_decides "EXT-CONT-DEC-B19:" "trash ${SEG_FH}/Claude/seg-b19 2>& \\${cont_nl}1 /tmp/seg-b19"
  cont_decides "EXT-CONT-DEC-B20:" "trash ${SEG_FH}/Claude/seg-b20 >| \\${cont_nl}seg-b20-log /tmp/seg-b20"
  cont_decides "EXT-CONT-DEC-P6:" "trash ${SEG_FH}/Claude/seg-p6a \\${cont_nl}${SEG_FH}/Claude/seg-p6b"
  cont_decides "EXT-CONT-DEC-P9:" "trash ${SEG_FH}/Claude/seg-p9 && echo done \\${cont_nl}more"
  cont_decides "EXT-CONT-DEC-R1:" "trash ${SEG_FH}/Claude/cont-r1 >/dev/null \\${cont_nl}/tmp/cont-r1"
  cont_decides "EXT-CONT-DEC-R2:" "trash ${SEG_FH}/Claude/cont-r2 >>/dev/null \\${cont_nl}/tmp/cont-r2"
  cont_decides "EXT-CONT-DEC-R3:" "trash ${SEG_FH}/Claude/cont-r3 >|/dev/null \\${cont_nl}/tmp/cont-r3"
  cont_decides "EXT-CONT-DEC-R4:" "trash ${SEG_FH}/Claude/cont-r4 >&/dev/null \\${cont_nl}/tmp/cont-r4"
  cont_decides "EXT-CONT-DEC-R5:" "trash ${SEG_FH}/Claude/cont-r5 > \\${cont_nl}/tmp/cont-r5.log /tmp/cont-r5"
  cont_decides "EXT-CONT-DEC-R6:" "trash ${SEG_FH}/Claude/cont-r6 >> \\${cont_nl}/tmp/cont-r6.log /tmp/cont-r6"
  cont_decides "EXT-CONT-DEC-R7:" "trash ${SEG_FH}/Claude/cont-r7 &> \\${cont_nl}/tmp/cont-r7.log /tmp/cont-r7"
  cont_decides "EXT-CONT-DEC-R8:" "trash ${SEG_FH}/Claude/cont-r8 >& \\${cont_nl}/tmp/cont-r8.log /tmp/cont-r8"
  ra_pair "EXT-SEG-MUT-REDIRAMP-B10:" "${seg_dir}/block-rm-prefer-trash-REDIRAMP.sh" 'trash seg-mut-b10 2>&1 /tmp/seg-b10'
  ra_pair "EXT-SEG-MUT-BOTHREDIR-B11:" "${seg_dir}/block-rm-prefer-trash-BOTHREDIR.sh" 'trash seg-mut-b11 &>/dev/null /tmp/seg-b11'
  seg_armed "EXT-SEG-INT1-C4:" "${seg_dir}/block-rm-prefer-trash-nohd.sh" "$SEG_C4"
  seg_armed "EXT-SEG-INT1-C7:" "${seg_dir}/block-rm-prefer-trash-nohd.sh" "$SEG_C7"
  seg_armed "EXT-SEG-INT1-C8:" "${seg_dir}/block-rm-prefer-trash-nohd.sh" "$SEG_C8"
  seg_armed "EXT-SEG-INT1-C11:" "${seg_dir}/block-rm-prefer-trash-nohd.sh" "$SEG_C11"
  case "${seg_dir##*/}" in rmt-seg.*) /bin/rm -rf "$seg_dir" ;; esac
fi

# The keg coupling shown load-bearing (#8123 FM-3). The keg-only location reaches the segment walk
# through walk_segments(), the walk's one call site, so every mode receives it. A copy whose call
# site drops it, shown live first (one line from the hook, and it parses), allows both sentinels:
# the Step-3 verb test still fires, but neither the operand walk nor the target-less walk can see
# the call.
keg_dir="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-keg.XXXXXX" 2>/dev/null)" || keg_dir=""
if [ -z "$keg_dir" ]; then
  /usr/bin/printf 'FAIL: AC-AP-MUT-KEG pairs could not create a sandbox, so they did not run\n'
  FAIL=$((FAIL + 1))
else
  /bin/mkdir -p "${keg_dir}/lib"
  /bin/cp "${HOOK_DIR}/lib/dep-resolve.sh" "${HOOK_DIR}/lib/command-position.awk" "${keg_dir}/lib/"
  /usr/bin/sed -e 's/ -v keg="\$TRASH_KEG_DIR"\(.*  # M-TRASH-KEG\)$/\1/' \
    "$HOOK" > "${keg_dir}/block-rm-prefer-trash-keg.sh"
  ra_pair "AC-AP-MUT-KEG-016:" "${keg_dir}/block-rm-prefer-trash-keg.sh" "${RMT_KEG} /tmp/rmt-keg-016"
  ra_pair "AC-AP-MUT-KEG-016d:" "${keg_dir}/block-rm-prefer-trash-keg.sh" "${RMT_KEG}"
  case "${keg_dir##*/}" in rmt-keg.*) /bin/rm -rf "$keg_dir" ;; esac
fi

# ----- CWD-*: a relative target is judged from the directory the command can be in -----
#
# The payload cwd is where the call STARTS; a directory change earlier on the same line
# moves where a relative operand lands. Each arm runs under the fixture home
# (HOME-FIXTURE-01) from the fixture's worktree cwd, which is inside the workspace, so a
# verdict that names RMT_OUTSIDE can only come from following the in-command change. The
# outside directory sits under /nonexistent so realpath leaves it as typed (on macOS /tmp
# would come back as /private/tmp and the path assertions would test that instead).
RMT_OUTSIDE="/nonexistent/rm-trash-outside"
RMT_INSIDE_SUB="${RMT_FIXTURE_HOME}/Claude/sub"

# -- Followed: a change into a directory outside the workspace root --
test_case "CWD-01: trash of a relative target after cd outside the workspace blocks (BLOCK-TRASH-003)" \
  "$(bash_payload 'cd '"$RMT_OUTSIDE"' && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-02: rm -r of a relative target after cd outside names the outside path (BLOCK-TRASH-001)" \
  "$(bash_payload 'cd '"$RMT_OUTSIDE"' && rm -r victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-001.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-03: pushd outside then trash a relative target blocks" \
  "$(bash_payload 'pushd '"$RMT_OUTSIDE"' && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-04: a subshell group that changes directory outside blocks its relative trash" \
  "$(bash_payload '( cd '"$RMT_OUTSIDE"' && trash victim )' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-05: cd -- outside then trash a relative target blocks (option terminator on cd)" \
  "$(bash_payload 'cd -- '"$RMT_OUTSIDE"' && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-06: cd outside then trash -- relative target blocks (option terminator on trash)" \
  "$(bash_payload 'cd '"$RMT_OUTSIDE"' && trash -- victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-07: rm -- of a dash-led operand is judged as an operand, not skipped as a flag" \
  "$(bash_payload 'cd '"$RMT_OUTSIDE"' && rm -- -victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-001.*Path: ${RMT_OUTSIDE}/-victim" "$RMT_HOME_ENV"
test_case "CWD-08: a chain of relative cd .. that climbs out of the workspace blocks" \
  "$(bash_payload 'cd ../../.. && cd .. && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_FIXTURE_HOME}/victim" "$RMT_HOME_ENV"
test_case "CWD-09: bare cd goes to HOME, outside the workspace, and blocks a relative trash" \
  "$(bash_payload 'cd && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_FIXTURE_HOME}/victim" "$RMT_HOME_ENV"
test_case "CWD-10: cd to a home-relative directory outside the workspace blocks a relative trash" \
  "$(bash_payload 'cd ~/elsewhere && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_FIXTURE_HOME}/elsewhere/victim" "$RMT_HOME_ENV"
test_case "CWD-11: a semicolon-joined cd outside still blocks the relative trash after it" \
  "$(bash_payload 'cd '"$RMT_OUTSIDE"'; trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"
test_case "CWD-12: a change repeated by a function call blocks a relative trash in the function body" \
  "$(bash_payload 'f() { trash victim; }; cd '"$RMT_OUTSIDE"'; f' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*Path: ${RMT_OUTSIDE}/victim" "$RMT_HOME_ENV"

# -- Undeterminable: a change the hook cannot follow refuses a relative target under the
#    existing strict policy, with the same rule ID and a reason naming the basis --
test_case "CWD-13: cd to a variable operand makes a relative trash unresolvable" \
  "$(bash_payload 'cd "$SCRATCH" && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "CWD-14: cd - (previous directory) makes a relative trash unresolvable" \
  "$(bash_payload 'cd - && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "CWD-15: a directory-stack pushd form makes a relative trash unresolvable" \
  "$(bash_payload 'pushd +1 && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "CWD-16: popd makes a relative trash after it unresolvable" \
  "$(bash_payload 'pushd '"$RMT_INSIDE_SUB"' && popd && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "CWD-17: a relative cd repeated by a loop makes a relative trash unresolvable" \
  "$(bash_payload 'for i in 1 2 3 4 5; do cd ..; done; trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "CWD-18: a command that sets CDPATH makes a bare-name cd unresolvable" \
  "$(bash_payload 'CDPATH=/nonexistent cd sub && trash victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "CWD-19: rm after an undeterminable cd is refused under BLOCK-TRASH-001" \
  "$(bash_payload 'cd "$SCRATCH" && rm victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-001.*working directory" "$RMT_HOME_ENV"

# -- Controls: what must keep its verdict --
test_case "CWD-20 (control): trash of a relative target after cd inside the workspace allows" \
  "$(bash_payload 'cd '"$RMT_INSIDE_SUB"' && trash victim' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "CWD-21 (control): rm after cd inside redirects to Trash naming the path under that directory" \
  "$(bash_payload 'cd '"$RMT_INSIDE_SUB"' && rm victim' "$RMT_FIXTURE_CWD")" 2 \
  "BLOCK-TRASH-002.*: ${RMT_INSIDE_SUB}/victim" "$RMT_HOME_ENV"
test_case "CWD-22 (control): a relative trash with no directory change allows, judged from the payload cwd" \
  "$(bash_payload 'trash victim' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "CWD-23 (control): an absolute inside target is unaffected by a cd outside" \
  "$(bash_payload 'cd '"$RMT_OUTSIDE"' && trash '"$RMT_FIXTURE_HOME"'/Claude/foo.txt' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "CWD-24 (control): a cd that comes AFTER the target on the line does not move it" \
  "$(bash_payload 'cd '"$RMT_INSIDE_SUB"' && trash victim; cd '"$RMT_OUTSIDE"' && ls' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "CWD-25 (control): cd text inside a quoted string is content, not a directory change" \
  "$(bash_payload 'echo "cd '"$RMT_OUTSIDE"' && x" && trash victim' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "CWD-26 (control): a relative cd that stays inside the workspace allows" \
  "$(bash_payload 'cd .. && trash victim' "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"

# ----- TILDE / NONLIT (#8123 AC3, Q4): a target word is judged as the shell will expand it -----
#
# Every arm runs under the fixture home (HOME-FIXTURE-01) from the fixture's worktree cwd, so each
# home-relative operand below is INSIDE the workspace under the hook's own HOME. The must-refuse arms
# are refused only because the shell would act on another path.
#   TILDE    a line that names HOME as a word can change HOME before the verb runs, so no
#            home-relative word is expanded on it: a ~/ target, or a bare cd or cd ~/... before a
#            relative one. The word is read on the command as judged and again with its quotes and
#            backslashes removed (FM-2). A name composed by an expansion is a declared residual
#            (TILDE-P1). Another tilde prefix, or a zsh equals-word, is expanded where the hook does
#            not look (R3). RM1-RM3 are the rm-family rule-ID moves this makes, -002 to -001.
#   NONLIT   after the whole-word quote strip, a word carrying a brace, a backslash or a quote, a
#            wholly-quoted word whose body begins with ~, and a dot-leading glob component are not
#            literal (Q4): the shell acts on a different path from the one written. A quoted path
#            with a space reaches the resolver as such words, because the walk splits on whitespace
#            first. SENS is the plain spelling of NONLIT-01's destination; P1 to P5 are declared
#            over-blocks; the Finder delete's path goes through the same resolver (P2). Inside a
#            whole-word quote the shell keeps a backslash or a quote of the other kind, and the word
#            is refused all the same (P3 to P5); a brace there is removed by the canonicalizer before
#            the rule reads the word (CTL4).
TL_OTHER="$RMT_FIXTURE_OTHER_HOME"
TL_FH="$RMT_FIXTURE_HOME"
test_case "TILDE-01: a home-relative Trash target after an earlier segment assigns HOME is refused" \
  "$(bash_payload "HOME=${TL_OTHER}; trash ~/Claude/tl-01" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-02: the same after an exported HOME assignment is refused" \
  "$(bash_payload "export HOME=${TL_OTHER}; trash ~/Claude/tl-02" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-03: the same with HOME as a prefix assignment on the Trash command is refused (declared over-approximation)" \
  "$(bash_payload "HOME=${TL_OTHER} trash ~/Claude/tl-03" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-04: a home-relative cd after a HOME assignment leaves a relative Trash target unresolvable" \
  "$(bash_payload "HOME=${TL_OTHER}; cd ~/Claude/sub && trash tl-04" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*working directory" "$RMT_HOME_ENV"
test_case "TILDE-05: a declaration builtin spelling the HOME name with an embedded double-quote pair is refused (FM-2)" \
  "$(bash_payload "export \"HO\"ME=${TL_OTHER}; trash ~/Claude/tl-05" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-06: a name-operand builtin spelling the HOME name with a backslash is refused (FM-2)" \
  "$(bash_payload "printf -v H\\OME %s ${TL_OTHER}; trash ~/Claude/tl-06" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-07: a declaration builtin spelling the HOME name with an embedded single-quote pair is refused (FM-2)" \
  "$(bash_payload "typeset 'H'OME=${TL_OTHER}; trash ~/Claude/tl-07" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-P1: a HOME name composed by a parameter expansion is not seen (a declared residual, allowed)" \
  "$(bash_payload "n=HO; export \${n}ME=${TL_OTHER}; trash ~/Claude/tl-p1" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "TILDE-CTL1 (control): a home-relative inside Trash target on a line that does not name HOME is allowed" \
  "$(bash_payload "trash ~/Claude/tl-c1" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "TILDE-CTL2 (control): names that only contain HOME do not count" \
  "$(bash_payload "JAVA_HOME=/opt/j; HOMEBREW_NO_AUTO_UPDATE=1 trash ~/Claude/tl-c2" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "TILDE-CTL3 (control): a home-relative cd into the workspace, then a relative Trash target, with no HOME on the line" \
  "$(bash_payload "cd ~/Claude/sub && trash tl-c3" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "TILDE-08: a user-name tilde prefix is refused (R3)" \
  "$(bash_payload "trash ~root/tl-08" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*tilde prefix" "$RMT_HOME_ENV"
test_case "TILDE-09: the previous-directory tilde prefix is refused (R3)" \
  "$(bash_payload "trash ~-/tl-09" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*tilde prefix" "$RMT_HOME_ENV"
test_case "TILDE-10: a zsh equals-word is refused (R3)" \
  "$(bash_payload "trash =ls" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*equals-word" "$RMT_HOME_ENV"
test_case "TILDE-CTL4 (control): a relative operand with a tilde past its first character is allowed" \
  "$(bash_payload "trash tl-a~b" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "TILDE-RM1: rm of a home-relative inside target on a line that names HOME is refused under -001 (moved from -002)" \
  "$(bash_payload "HOME=${TL_OTHER}; rm ~/Claude/tl-rm1" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-001.*names HOME" "$RMT_HOME_ENV"
test_case "TILDE-RM2: rm of a user-name tilde target is refused under -001 (moved from -002)" \
  "$(bash_payload "rm ~root/tl-rm2" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-001.*tilde prefix" "$RMT_HOME_ENV"
test_case "TILDE-RM3: rm of a relative target after a HOME-dependent cd on a line that names HOME is refused under -001 (moved from -002)" \
  "$(bash_payload "HOME=${TL_OTHER}; cd ~/Claude/sub && rm tl-rm3" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-001.*working directory" "$RMT_HOME_ENV"
test_case "NONLIT-01: a dot-dot escape spelled with an empty quote pair inside the dot-dot is refused" \
  "$(bash_payload "trash ${TL_FH}/Claude/.''./nl-01" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-02: a dot-dot escape spelled with one dot backslash-escaped is refused" \
  "$(bash_payload "trash ${TL_FH}/Claude/.\\./nl-02" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
# A brace word is built in an assignment first: bash 3.2 brace-expands a double-quoted string
# inside a command substitution's argument list, which would hand the payload two words.
NL_03="trash ${TL_FH}/Claude/{..,nl}/nl-03"
NL_RM1="rm ${TL_FH}/Claude/{nl,rm1}"
test_case "NONLIT-03: a brace word whose first expansion is a dot-dot escape is refused" \
  "$(bash_payload "$NL_03" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-04: a wholly-quoted word whose body begins with a tilde is refused (R5: the shell keeps it literal)" \
  "$(bash_payload "trash \"~/Claude/nl-04\"" "$RMT_OUTSIDE")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-05: a dot-leading glob component is refused" \
  "$(bash_payload "trash ${TL_FH}/Claude/.*/nl-05" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-06: a quoted outside path with a space is refused (it was joined to the cwd as relative)" \
  "$(bash_payload "trash \"${RMT_OUTSIDE}/nl six/x\"" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-SENS (sensitivity): the plain spelling of NONLIT-01's destination is refused" \
  "$(bash_payload "trash ${TL_FH}/Claude/../nl-01" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*deletion outside" "$RMT_HOME_ENV"
test_case "NONLIT-CTL1 (control): an unquoted glob inside the workspace stays literal and is allowed" \
  "$(bash_payload "trash ${TL_FH}/Claude/nl-*.log" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "NONLIT-CTL2 (control): a wholly-quoted inside operand is allowed" \
  "$(bash_payload "trash \"${TL_FH}/Claude/nl-c2\"" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "NONLIT-CTL3 (control): a dot-leading component with no glob character is allowed" \
  "$(bash_payload "trash ${TL_FH}/Claude/.nl-hidden" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "NONLIT-P1: a quoted inside path with a space is refused (a declared over-block)" \
  "$(bash_payload "trash \"${TL_FH}/Claude/nl p1\"" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-P2: a Finder delete of an inside path carrying a brace is refused (a declared over-block)" \
  "$(bash_payload 'osascript -e '"'"'tell application "Finder" to delete POSIX file "'"${TL_FH}"'/Claude/{nl,p2}"'"'"'' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
NL_CTL4="trash '${TL_FH}/Claude/nl{c4}'"
test_case "NONLIT-P3: a wholly single-quoted inside target carrying a backslash is refused (a declared over-block)" \
  "$(bash_payload "trash '${TL_FH}/Claude/nl\\p3'" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-P4: a wholly single-quoted inside target carrying a double quote is refused (a declared over-block)" \
  "$(bash_payload "trash '${TL_FH}/Claude/nl\"p4'" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-P5: a wholly double-quoted inside target carrying an apostrophe is refused (a declared over-block)" \
  "$(bash_payload "trash \"${TL_FH}/Claude/nl'p5\"" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-003.*not a literal word" "$RMT_HOME_ENV"
test_case "NONLIT-CTL4 (control): a brace inside a wholly-quoted inside target never reaches the rule and is allowed" \
  "$(bash_payload "$NL_CTL4" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "NONLIT-RM1: rm of a brace-word inside target is refused under -001 (moved from -002)" \
  "$(bash_payload "$NL_RM1" "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-001.*not a literal word" "$RMT_HOME_ENV"

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

# ----- MEMORY-STORE ARM: auto-memory entry eviction (MEM-*) -----
#
# Every MEM case runs the hook with HOME pointed at a throwaway sandbox (the
# block-autonomy-ceiling.test.sh idiom) and CLAUDE_PROJECT_DIR cleared, unless a case sets
# it, so neither the operator's real settings and store nor a caller's project is read.
# Fixture names avoid the operator-memory-reference gate's patterns. MEM_ROOT is
# canonicalized at creation, so every path an arm writes is already the form the hook's
# normalizer gives back, and a message pattern can name it as typed.
MEM_ROOT=""
mem_root_raw="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-mem.XXXXXX" 2>/dev/null)" || mem_root_raw=""
if [ -n "$mem_root_raw" ] && [ -d "$mem_root_raw" ]; then
  MEM_ROOT="$(cd "$mem_root_raw" && /bin/pwd -P)" || MEM_ROOT=""
fi
MEM_ERR_FILE="${MEM_ROOT}/hook-stderr"

# mem_home <name> <settings-json|NONE> [noindex] — build a sandbox HOME under MEM_ROOT
mem_home() {
  local h="${MEM_ROOT}/$1"
  /bin/mkdir -p "$h/.claude" "$h/Claude" "$h/mem-store/sub" "$h/mem-store/dir-entry.md" "$h/elsewhere"
  /usr/bin/touch "$h/mem-store/entry-alpha.md" "$h/mem-store/notes.txt" "$h/mem-store/.hidden.md" \
    "$h/mem-store/sub/entry-beta.md" "$h/elsewhere/note.md" "$h/top.md"
  [ "${3:-}" = "noindex" ] || /usr/bin/touch "$h/mem-store/MEMORY.md"
  /bin/ln -s "$h/elsewhere/note.md" "$h/mem-store/link-out.md"
  /bin/ln -s "$h/mem-store/entry-alpha.md" "$h/elsewhere/alias-in.md"
  /bin/ln -s "$h/mem-store" "$h/link-store"
  [ "$2" = "NONE" ] || /usr/bin/printf '%s\n' "$2" > "$h/.claude/settings.json"
}

# mem_run <hook> <home> <project-dir|""> <payload> [hook-cwd] — run one hook invocation; sets
#   MEM_EXIT and writes the hook's stderr to MEM_ERR_FILE. An empty project dir clears
#   CLAUDE_PROJECT_DIR for the run. [hook-cwd] is the hook PROCESS's working directory, the
#   one the predicate's own relative lookups resolve against (the payload's cwd is another
#   thing: the hook reads it only to classify a relative operand). Default: this suite's.
mem_run() {
  MEM_EXIT=0
  local mem_dir="${5:-.}"
  if [ -n "$3" ]; then
    ( cd "$mem_dir" && /usr/bin/printf '%s' "$4" | /usr/bin/env "HOME=$2" "CLAUDE_PROJECT_DIR=$3" /bin/bash "$1" 2>"$MEM_ERR_FILE" >/dev/null ) || MEM_EXIT="$?"
  else
    ( cd "$mem_dir" && /usr/bin/printf '%s' "$4" | /usr/bin/env -u CLAUDE_PROJECT_DIR "HOME=$2" /bin/bash "$1" 2>"$MEM_ERR_FILE" >/dev/null ) || MEM_EXIT="$?"
  fi
}

# mem_report <name> <exit> [pattern] — test_case's assertion and PASS/FAIL reporting, read
#   from the stderr file the last mem_run wrote.
mem_report() {
  local ok=1
  [ "$MEM_EXIT" != "$2" ] && ok=0
  if [ -n "${3:-}" ] && ! /usr/bin/grep -qE "$3" "$MEM_ERR_FILE"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  stderr: %s\n' "$1" "$MEM_EXIT" "$2" "$(/bin/cat "$MEM_ERR_FILE")"
    FAIL=$((FAIL + 1))
  fi
}

# mem_case <name> <sandbox> <command> <exit> [pattern] [cwd] [hook-cwd] — one payload under one
#   sandbox HOME; [cwd] is the payload's working directory, [hook-cwd] the hook process's
mem_case() {
  local cwd="${6:-${MEM_ROOT}/$2/Claude/.claude/worktrees/planning}"
  mem_run "$HOOK" "${MEM_ROOT}/$2" "" "$(bash_payload "$3" "$cwd")" "${7:-}"
  mem_report "$1" "$4" "${5:-}"
}

# mem_hook_copy — a sandbox copy of the hook with the two libraries it cannot run without
#   (the dep_gate_case shape), so a case can change what the copy sees. Prints its directory.
mem_hook_copy() {
  local sbx
  sbx="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-copy.XXXXXX" 2>/dev/null)" || return 1
  /bin/mkdir -p "${sbx}/lib"
  /bin/cp "$HOOK" "${sbx}/block-rm-prefer-trash.sh"
  /bin/cp "${HOOK_DIR}/lib/dep-resolve.sh" "${HOOK_DIR}/lib/command-position.awk" "${sbx}/lib/"
  /usr/bin/printf '%s' "$sbx"
}

# mem_drop_copy <dir> — remove a mem_hook_copy directory, and nothing that is not one
mem_drop_copy() {
  case "${1##*/}" in
    rmt-copy.*) /bin/rm -rf "$1" ;;
  esac
}

# mem_normalizer_case <name> <python3-path> <exit> [pattern] — MEM-01's payload, run by a
#   sandbox copy whose pinned python3 is rewritten to the given path. FAILs if the copy does
#   not carry exactly that path (anti-vacuous).
mem_normalizer_case() {
  local sbx
  sbx="$(mem_hook_copy)" || sbx=""
  if [ -z "$sbx" ]; then
    /usr/bin/printf 'FAIL: %s (no sandbox copy of the hook)\n' "$1"; FAIL=$((FAIL + 1)); return
  fi
  /usr/bin/sed -e 's#^readonly PYTHON3="/usr/bin/python3"$#readonly PYTHON3="'"$2"'"#' \
    "$HOOK" > "${sbx}/block-rm-prefer-trash.sh"
  if [ "$(/usr/bin/grep -c -x -F "readonly PYTHON3=\"$2\"" "${sbx}/block-rm-prefer-trash.sh")" != 1 ]; then
    /usr/bin/printf 'FAIL: %s (the sandbox copy does not pin python3 to %s)\n' "$1" "$2"; FAIL=$((FAIL + 1))
    mem_drop_copy "$sbx"; return
  fi
  mem_run "${sbx}/block-rm-prefer-trash.sh" "${MEM_ROOT}/base" "" \
    "$(bash_payload "trash ${MEM_ROOT}/base/mem-store/entry-alpha.md" "${MEM_ROOT}/base/Claude/.claude/worktrees/planning")"
  mem_drop_copy "$sbx"
  mem_report "$1" "$3" "${4:-}"
}

# mem_admit_rows <log> — how many memory-store admission rows a log holds (0 if absent)
mem_admit_rows() {
  local n
  n="$(/usr/bin/grep -c -F '"action":"memory-evict-admit"' "$1" 2>/dev/null)" || n=0
  /usr/bin/printf '%s' "${n:-0}"
}

if [ -z "$MEM_ROOT" ]; then
  /usr/bin/printf 'FAIL: MEM sandbox root could not be created, so the MEM arms did not run\n'
  FAIL=$((FAIL + 1))
else
  mem_home base    '{"autoMemoryDirectory": "~/mem-store"}'
  mem_home link    NONE
  /usr/bin/printf '{"autoMemoryDirectory": "%s/link-store"}\n' "${MEM_ROOT}/link" > "${MEM_ROOT}/link/.claude/settings.json"
  mem_home nocfg   NONE
  mem_home badjson '{not json'
  mem_home relval  '{"autoMemoryDirectory": "mem-store"}'
  mem_home homeval '{"autoMemoryDirectory": "~/"}'
  /usr/bin/touch "${MEM_ROOT}/homeval/MEMORY.md"
  mem_home noidx   '{"autoMemoryDirectory": "~/mem-store"}' noindex
  mem_home scoped  NONE
  /bin/mkdir -p "${MEM_ROOT}/scoped/proj-shared/.claude" "${MEM_ROOT}/scoped/proj-local/.claude"
  /usr/bin/printf '%s\n' '{"autoMemoryDirectory": "~/mem-store"}' > "${MEM_ROOT}/scoped/proj-shared/.claude/settings.json"
  /usr/bin/printf '%s\n' '{"autoMemoryDirectory": "~/mem-store"}' > "${MEM_ROOT}/scoped/proj-local/.claude/settings.local.json"
  MB="${MEM_ROOT}/base"

  # -- Admitted: a Trash-verb move of one direct *.md entry of the declared store (AC-1). The
  #    arm admits an absolute operand only, bare or wholly quoted --
  mem_case "MEM-01 trash of a direct store entry is admitted" base \
    "trash ${MB}/mem-store/entry-alpha.md" 0
  mem_case "MEM-03 a Finder delete of a store entry is admitted" base \
    "osascript -e 'tell application \"Finder\" to delete POSIX file \"${MB}/mem-store/entry-alpha.md\"'" 0
  mem_case "MEM-04 an absolute-path trash of a store entry is admitted" base \
    "/opt/homebrew/bin/trash ${MB}/mem-store/entry-alpha.md" 0
  mem_case "MEM-05 a store declared through a symlink admits its entry (both sides canonicalized)" link \
    "trash ${MEM_ROOT}/link/mem-store/entry-alpha.md" 0
  mem_case "MEM-28 a single-quoted absolute store entry is admitted (the form the refusals suggest)" base \
    "trash '${MB}/mem-store/entry-alpha.md'" 0

  # -- Refused: a ~/ operand is not admitted, on the trash branch or the Finder branch. It
  #    meets the refusal every operand the arm does not admit meets, outside the workspace --
  mem_case "MEM-02 a ~/-prefixed store entry is refused (the arm admits an absolute operand only)" base \
    'trash ~/mem-store/entry-alpha.md' 2 'BLOCK-TRASH-003] BLOCKED: deletion outside Claude/ is forbidden'
  mem_case "MEM-29 a Finder delete given a ~/ path to a store entry is refused" base \
    "osascript -e 'tell application \"Finder\" to delete POSIX file \"~/mem-store/entry-alpha.md\"'" 2 \
    'BLOCK-TRASH-003] BLOCKED: deletion outside Claude/ is forbidden'

  # -- Refused: a permanent-deletion verb on an entry names the Trash move instead --
  mem_case "MEM-06 rm of a store entry is refused with the Trash move named" base \
    "rm ${MB}/mem-store/entry-alpha.md" 2 'BLOCK-TRASH-001] BLOCKED: permanent deletion of an auto-memory entry'
  mem_case "MEM-07 unlink of a store entry is refused with the Trash move named" base \
    "unlink ${MB}/mem-store/entry-alpha.md" 2 'BLOCK-TRASH-001] BLOCKED: permanent deletion of an auto-memory entry'

  # MEM-30: that refusal names exactly the eviction command the knowledge-architecture
  # discipline's encode-and-evict procedure documents, for the entry. It runs a sandbox copy
  # in the mem_normalizer_case shape, whose pinned tool path holds only the two tools the
  # hook calls by bare name, and FAILs if the copy does not carry exactly that path
  # (anti-vacuous).
  m30_name="MEM-30 the memory refusal names exactly the documented eviction command for the entry"
  m30_entry="${MB}/mem-store/entry-alpha.md"
  m30_fail=""
  m30_sbx="$(mem_hook_copy)" || m30_sbx=""
  if [ -z "$m30_sbx" ]; then
    m30_fail="no sandbox copy of the hook"
  else
    /bin/mkdir -p "${m30_sbx}/bin"
    /bin/ln -s /usr/bin/dirname "${m30_sbx}/bin/dirname"
    /bin/ln -s /bin/cat "${m30_sbx}/bin/cat"
    /usr/bin/sed -e 's#^export PATH="/usr/bin:/bin"$#export PATH="'"${m30_sbx}/bin"'"#' \
      "$HOOK" > "${m30_sbx}/block-rm-prefer-trash.sh"
    if [ "$(/usr/bin/grep -c -x -F "export PATH=\"${m30_sbx}/bin\"" "${m30_sbx}/block-rm-prefer-trash.sh")" != 1 ]; then
      m30_fail="the sandbox copy does not pin its tool path to ${m30_sbx}/bin"
    else
      mem_run "${m30_sbx}/block-rm-prefer-trash.sh" "$MB" "" \
        "$(bash_payload "rm ${m30_entry}" "${MB}/Claude/.claude/worktrees/planning")"
      m30_line="$(/usr/bin/grep -F 'BLOCK-TRASH-001] BLOCKED: permanent deletion of an auto-memory entry' "$MEM_ERR_FILE")"
      if [ "$MEM_EXIT" != 2 ] || [ -z "$m30_line" ]; then
        m30_fail="exit=${MEM_EXIT} (expected 2, the memory refusal): $(/bin/cat "$MEM_ERR_FILE")"
      else
        case "$m30_line" in
          *"instead: trash '${m30_entry}'") ;;
          *) m30_fail="the memory refusal does not name the documented eviction command for the entry" ;;
        esac
      fi
    fi
    mem_drop_copy "$m30_sbx"
  fi
  if [ -z "$m30_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "$m30_name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (%s)\n' "$m30_name" "$m30_fail"; FAIL=$((FAIL + 1))
  fi

  # MEM-31: that refusal names the documented eviction command with the entry operand as
  # it was typed (bare, wholly single-quoted or wholly double-quoted), its quotes stripped.
  # FAILs if the store path the fixture types does not resolve to another directory
  # (anti-vacuous).
  m31_name="MEM-31 the memory refusal names the documented eviction command with the operand as typed"
  m31_home="${MEM_ROOT}/typed"
  mem_home typed NONE
  /bin/mkdir -p "${m31_home}/mem store"
  /usr/bin/touch "${m31_home}/mem store/MEMORY.md" "${m31_home}/mem store/entry-alpha.md"
  /bin/ln -s "${m31_home}/mem store" "${m31_home}/store-link"
  /usr/bin/printf '{"autoMemoryDirectory": "%s/store-link"}\n' "$m31_home" > "${m31_home}/.claude/settings.json"
  m31_entry="${m31_home}/store-link/entry-alpha.md"
  m31_fail=""
  m31_real="$(cd "${m31_home}/store-link" 2>/dev/null && /bin/pwd -P)" || m31_real=""
  if [ -z "$m31_real" ] || [ "$m31_real" = "${m31_home}/store-link" ]; then
    m31_fail="  the store path the fixture types does not resolve to another directory"$'\n'
  else
    for m31_op in "$m31_entry" "'${m31_entry}'" "\"${m31_entry}\""; do
      mem_run "$HOOK" "$m31_home" "" "$(bash_payload "rm ${m31_op}" "${m31_home}/Claude/.claude/worktrees/planning")"
      m31_line="$(/usr/bin/grep -F 'BLOCK-TRASH-001] BLOCKED: permanent deletion of an auto-memory entry' "$MEM_ERR_FILE")"
      if [ "$MEM_EXIT" != 2 ] || [ -z "$m31_line" ]; then
        m31_fail="${m31_fail}  rm ${m31_op} -> exit=${MEM_EXIT} (expected 2, the memory refusal): $(/bin/cat "$MEM_ERR_FILE")"$'\n'
      else
        case "$m31_line" in
          *"instead: trash '${m31_entry}'") ;;
          *) m31_fail="${m31_fail}  rm ${m31_op} -> the memory refusal does not name the documented eviction command with the operand as typed"$'\n' ;;
        esac
      fi
    done
  fi
  if [ -z "$m31_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "$m31_name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n%s' "$m31_name" "$m31_fail"; FAIL=$((FAIL + 1))
  fi

  # -- Refused: every target that is not a direct *.md entry of the declared store (AC-2) --
  mem_case "MEM-08 an entry in a store subdirectory is refused" base \
    "trash ${MB}/mem-store/sub/entry-beta.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-09 a non-.md store file is refused" base \
    "trash ${MB}/mem-store/notes.txt" 2 "BLOCK-TRASH-003"

  # MEM-10: the index is never admitted — written as the hook reads it, or in a form the
  # shell would expand or unescape into it. The arm passes only when every form is refused.
  # Each expansion form also exists in the store as a literal file name, so the form names
  # an existing regular file as the hook reads it and only the operand's character rule
  # can refuse it — not a missing file.
  /usr/bin/touch "${MB}/mem-store/*.md" "${MB}/mem-store/{MEMORY,entry-alpha}.md" \
    "${MB}/mem-store/MEMORY\\.md" "${MB}/mem-store/'MEMORY'.md"
  m10_fail=""
  for m10_cmd in "trash ${MB}/mem-store/MEMORY.md" "trash ${MB}/mem-store/*.md" \
                 "trash ${MB}/mem-store/{MEMORY,entry-alpha}.md" "trash ${MB}/mem-store/MEMORY\.md" \
                 "trash ${MB}/mem-store/'MEMORY'.md"; do
    mem_run "$HOOK" "$MB" "" "$(bash_payload "$m10_cmd" "${MB}/Claude/.claude/worktrees/planning")"
    if [ "$MEM_EXIT" != 2 ] || ! /usr/bin/grep -qF "BLOCK-TRASH-003" "$MEM_ERR_FILE"; then
      m10_fail="${m10_fail}  ${m10_cmd} -> exit=${MEM_EXIT}: $(/bin/cat "$MEM_ERR_FILE")"$'\n'
    fi
  done
  if [ -z "$m10_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "MEM-10 the store index is refused, as written and through shell expansion"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n%s' "MEM-10 the store index is refused, as written and through shell expansion" "$m10_fail"
    FAIL=$((FAIL + 1))
  fi

  mem_case "MEM-11 the index in another case spelling is refused" base \
    "trash ${MB}/mem-store/memory.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-12 a directory named like an entry is refused" base \
    "trash ${MB}/mem-store/dir-entry.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-13 the store itself is refused" base \
    "trash ${MB}/mem-store" 2 "BLOCK-TRASH-003"
  mem_case "MEM-14 a dot-leading entry is refused" base \
    "trash ${MB}/mem-store/.hidden.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-15 a literal .. that resolves back inside the store is refused" base \
    "trash ${MB}/mem-store/sub/../entry-alpha.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-16 a .. that leaves the store is refused" base \
    "trash ${MB}/mem-store/../elsewhere/note.md" 2 "BLOCK-TRASH-003"
  # MEM-17 and MEM-24 run the hook PROCESS from the directory their rule's relative lookup
  # would resolve against — the store, and the sandbox home — so each passes only while its
  # own rule refuses, not because a relative name happens to find nothing.
  mem_case "MEM-17 a relative entry operand is refused" base \
    "trash entry-alpha.md" 2 "BLOCK-TRASH-003" "${MB}/mem-store" "${MB}/mem-store"

  # MEM-18: a symlink is never admitted as an entry, in either direction — one inside the
  # store that resolves out of it, and one outside the store that resolves into it (Trash
  # moves the link the operand names, not its referent). Both must be refused.
  m18_fail=""
  for m18_cmd in "trash ${MB}/mem-store/link-out.md" "trash ${MB}/elsewhere/alias-in.md"; do
    mem_run "$HOOK" "$MB" "" "$(bash_payload "$m18_cmd" "${MB}/Claude/.claude/worktrees/planning")"
    if [ "$MEM_EXIT" != 2 ] || ! /usr/bin/grep -qF "BLOCK-TRASH-003" "$MEM_ERR_FILE"; then
      m18_fail="${m18_fail}  ${m18_cmd} -> exit=${MEM_EXIT}: $(/bin/cat "$MEM_ERR_FILE")"$'\n'
    fi
  done
  if [ -z "$m18_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "MEM-18 a symlink is refused, escaping the store or reaching into it"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n%s' "MEM-18 a symlink is refused, escaping the store or reaching into it" "$m18_fail"
    FAIL=$((FAIL + 1))
  fi

  mem_case "MEM-19 an entry beside an outside target is refused as a whole" base \
    "trash ${MB}/mem-store/entry-alpha.md /tmp/foo" 2 "BLOCK-TRASH-003"
  mem_case "MEM-20 a target outside both roots is refused" base \
    "trash ${MB}/elsewhere/note.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-21 no user settings admits nothing" nocfg \
    "trash ${MEM_ROOT}/nocfg/mem-store/entry-alpha.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-22 malformed user settings admit nothing and are not a hook error" badjson \
    "trash ${MEM_ROOT}/badjson/mem-store/entry-alpha.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-23 malformed user settings leave the inside-workspace Trash allow intact" badjson \
    "trash ${MEM_ROOT}/badjson/Claude/foo.txt" 0
  mem_case "MEM-24 a relative store value admits nothing" relval \
    "trash ${MEM_ROOT}/relval/mem-store/entry-alpha.md" 2 "BLOCK-TRASH-003" "" "${MEM_ROOT}/relval"
  mem_case "MEM-25 a store equal to HOME admits nothing" homeval \
    "trash ${MEM_ROOT}/homeval/top.md" 2 "BLOCK-TRASH-003"
  mem_case "MEM-26 a store without its index admits nothing" noidx \
    "trash ${MEM_ROOT}/noidx/mem-store/entry-alpha.md" 2 "BLOCK-TRASH-003"
  mem_normalizer_case "MEM-27a an unusable python3 admits nothing (fail closed)" /nonexistent/python3 2 "BLOCK-TRASH-003"
  mem_normalizer_case "MEM-27b the normalizer sandbox admits with a usable python3 (control)" /usr/bin/python3 0

  # MEM-CD2: one admission-log row per admission, and none for a refusal. (a) An admission
  # adds exactly one compact row to the hook's block log, carrying the command's digest and
  # the working directory and no rule. (b) A command refused as a whole adds none. (c) A
  # sandbox copy admits while its log is writable (c1) and refuses once a row cannot be
  # written (c2). Rows are counted as a delta: a reused layout keeps its log across runs.
  cd2_fail=""
  cd2_log="${HOOK_DIR}/block-log.jsonl"
  cd2_cwd="${MB}/Claude/.claude/worktrees/planning"
  cd2_cmd="trash ${MB}/mem-store/entry-alpha.md"
  cd2_before="$(mem_admit_rows "$cd2_log")"
  mem_run "$HOOK" "$MB" "" "$(bash_payload "$cd2_cmd" "$cd2_cwd")"
  cd2_after="$(mem_admit_rows "$cd2_log")"
  if [ "$MEM_EXIT" != 0 ] || [ "$((cd2_after - cd2_before))" != 1 ]; then
    cd2_fail="${cd2_fail}  (a) admission: exit=${MEM_EXIT} (expected 0), rows ${cd2_before} -> ${cd2_after} (expected +1): $(/bin/cat "$MEM_ERR_FILE")"$'\n'
  else
    cd2_row="$(/usr/bin/grep -F '"action":"memory-evict-admit"' "$cd2_log")"
    cd2_row="${cd2_row##*$'\n'}"
    cd2_want="$(/usr/bin/printf '%s' "$cd2_cmd" | /usr/bin/shasum -a 256)"
    cd2_want="${cd2_want%% *}"
    cd2_got="$(/usr/bin/jq -r '[.hook, .tool, .input_digest, .cwd, (has("rule") | tostring)] | join("|")' <<< "$cd2_row" 2>/dev/null)" || cd2_got=""
    if [ "$cd2_got" != "block-rm-prefer-trash|Bash|${cd2_want:0:16}|${cd2_cwd}|false" ]; then
      cd2_fail="${cd2_fail}  (a) row fields: got '${cd2_got}', want 'block-rm-prefer-trash|Bash|${cd2_want:0:16}|${cd2_cwd}|false'"$'\n'
    fi
  fi
  cd2_before="$(mem_admit_rows "$cd2_log")"
  mem_run "$HOOK" "$MB" "" "$(bash_payload "${cd2_cmd} /tmp/foo" "$cd2_cwd")"
  cd2_after="$(mem_admit_rows "$cd2_log")"
  if [ "$MEM_EXIT" != 2 ] || [ "$cd2_after" != "$cd2_before" ]; then
    cd2_fail="${cd2_fail}  (b) refused command: exit=${MEM_EXIT} (expected 2), rows ${cd2_before} -> ${cd2_after} (expected +0)"$'\n'
  fi
  cd2_sbx="$(mem_hook_copy)" || cd2_sbx=""
  if [ -z "$cd2_sbx" ]; then
    cd2_fail="${cd2_fail}  (c) no sandbox copy of the hook"$'\n'
  else
    mem_run "${cd2_sbx}/block-rm-prefer-trash.sh" "$MB" "" "$(bash_payload "$cd2_cmd" "$cd2_cwd")"
    if [ "$MEM_EXIT" != 0 ] || [ "$(mem_admit_rows "${cd2_sbx}/block-log.jsonl")" != 1 ]; then
      cd2_fail="${cd2_fail}  (c1) writable log: exit=${MEM_EXIT} (expected 0), rows $(mem_admit_rows "${cd2_sbx}/block-log.jsonl") (expected 1)"$'\n'
    fi
    /bin/rm -f "${cd2_sbx}/block-log.jsonl"
    /bin/mkdir "${cd2_sbx}/block-log.jsonl"
    mem_run "${cd2_sbx}/block-rm-prefer-trash.sh" "$MB" "" "$(bash_payload "$cd2_cmd" "$cd2_cwd")"
    if [ "$MEM_EXIT" != 2 ] || ! /usr/bin/grep -qE 'BLOCK-TRASH-003] BLOCKED: the Trash move of an auto-memory entry could not be recorded' "$MEM_ERR_FILE"; then
      cd2_fail="${cd2_fail}  (c2) unwritable log: exit=${MEM_EXIT} (expected 2, the could-not-be-recorded refusal): $(/bin/cat "$MEM_ERR_FILE")"$'\n'
    fi
    mem_drop_copy "$cd2_sbx"
  fi
  if [ -z "$cd2_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "MEM-CD2 one admission-log row per admission, none for a refusal, and no admission without its row"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n%s' "MEM-CD2 one admission-log row per admission, none for a refusal, and no admission without its row" "$cd2_fail"
    FAIL=$((FAIL + 1))
  fi

  # MEM-FM3: a store declared outside user scope gets the memory-specific refusal, not the
  # generic cancel text — read from project scope through CLAUDE_PROJECT_DIR (i), and from
  # local scope through the working directory when CLAUDE_PROJECT_DIR is unset (ii). Neither
  # is ever admitted: project and local settings word the refusal, they never aim the arm.
  fm3_fail=""
  fm3_cmd="trash ${MEM_ROOT}/scoped/mem-store/entry-alpha.md"
  for fm3_case in "i|${MEM_ROOT}/scoped/proj-shared|${MEM_ROOT}/scoped/proj-shared" \
                  "ii||${MEM_ROOT}/scoped/proj-local"; do
    fm3_tag="${fm3_case%%|*}"; fm3_rest="${fm3_case#*|}"
    fm3_proj="${fm3_rest%%|*}"; fm3_cwd="${fm3_rest#*|}"
    mem_run "$HOOK" "${MEM_ROOT}/scoped" "$fm3_proj" "$(bash_payload "$fm3_cmd" "$fm3_cwd")"
    if [ "$MEM_EXIT" != 2 ] \
       || ! /usr/bin/grep -qE 'BLOCK-TRASH-003] BLOCKED: auto-memory entry in a store declared outside user scope' "$MEM_ERR_FILE" \
       || /usr/bin/grep -qF "cancel operation" "$MEM_ERR_FILE"; then
      fm3_fail="${fm3_fail}  (${fm3_tag}) exit=${MEM_EXIT} (expected 2, the memory-specific refusal): $(/bin/cat "$MEM_ERR_FILE")"$'\n'
    fi
  done
  if [ -z "$fm3_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "MEM-FM3 a store declared outside user scope gets the memory-specific refusal"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n%s' "MEM-FM3 a store declared outside user scope gets the memory-specific refusal" "$fm3_fail"
    FAIL=$((FAIL + 1))
  fi

  # CWD-27/28: the CWD-* family on a real filesystem, which the fixture home cannot give.
  # They reuse this block's canonical sandbox because each needs a directory the hook can
  # resolve: a symlink inside the workspace, and a hook copy with its normalizer swapped.
  #
  # CWD-27: a shell's cd is LOGICAL by default, so `..` from a directory reached through a
  # symlink climbs the path as typed, not the directory the link points to. Here the payload
  # cwd is a link to a directory two levels deeper; `cd ../..` lands the shell at the
  # sandbox home (outside the workspace) while the physical reading lands inside it. The arm
  # passes only if the logical reading is judged too. The control arm climbs one level,
  # where both readings stay inside, and must allow.
  /bin/mkdir -p "${MB}/Claude/deep/a/b"
  /bin/ln -s "${MB}/Claude/deep/a/b" "${MB}/Claude/lnk"
  mem_case "CWD-27 a logical cd .. through a symlinked cwd that leaves the workspace blocks" base \
    "cd ../.. && trash victim" 2 "BLOCK-TRASH-003.*Path: ${MB}/victim" "${MB}/Claude/lnk"
  mem_case "CWD-27b (control) a logical cd .. through a symlinked cwd that stays inside allows" base \
    "cd .. && trash victim" 0 "" "${MB}/Claude/lnk"

  # CWD-28: a directory change the hook cannot normalize is not followed on a raw join. A
  # sandbox copy whose pinned python3 is unusable must refuse a relative target after any
  # directory change (fail closed); the same copy with a usable python3 allows it (control).
  # FAILs if the copy does not carry exactly the pinned path (anti-vacuous).
  cwd28_fail=""
  for cwd28_case in "/nonexistent/python3|2" "/usr/bin/python3|0"; do
    cwd28_py="${cwd28_case%%|*}"; cwd28_want="${cwd28_case#*|}"
    cwd28_sbx="$(mem_hook_copy)" || cwd28_sbx=""
    if [ -z "$cwd28_sbx" ]; then
      cwd28_fail="${cwd28_fail}  ${cwd28_py}: no sandbox copy of the hook"$'\n'; continue
    fi
    /usr/bin/sed -e 's#^readonly PYTHON3="/usr/bin/python3"$#readonly PYTHON3="'"$cwd28_py"'"#' \
      "$HOOK" > "${cwd28_sbx}/block-rm-prefer-trash.sh"
    if [ "$(/usr/bin/grep -c -x -F "readonly PYTHON3=\"$cwd28_py\"" "${cwd28_sbx}/block-rm-prefer-trash.sh")" != 1 ]; then
      cwd28_fail="${cwd28_fail}  ${cwd28_py}: the sandbox copy does not pin python3 to that path"$'\n'
    else
      mem_run "${cwd28_sbx}/block-rm-prefer-trash.sh" "$MB" "" \
        "$(bash_payload "cd ${MB}/Claude/deep && trash victim" "${MB}/Claude/.claude/worktrees/planning")"
      if [ "$MEM_EXIT" != "$cwd28_want" ]; then
        cwd28_fail="${cwd28_fail}  ${cwd28_py}: exit=${MEM_EXIT} (expected ${cwd28_want}): $(/bin/cat "$MEM_ERR_FILE")"$'\n'
      elif [ "$cwd28_want" = 2 ] && ! /usr/bin/grep -qE 'BLOCK-TRASH-003.*working directory' "$MEM_ERR_FILE"; then
        cwd28_fail="${cwd28_fail}  ${cwd28_py}: refused, but not for the undeterminable working directory: $(/bin/cat "$MEM_ERR_FILE")"$'\n'
      fi
    fi
    mem_drop_copy "$cwd28_sbx"
  done
  if [ -z "$cwd28_fail" ]; then
    /usr/bin/printf 'PASS: %s\n' "CWD-28 an unusable normalizer refuses a relative target after a directory change, a usable one allows it"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n%s' "CWD-28 an unusable normalizer refuses a relative target after a directory change, a usable one allows it" "$cwd28_fail"
    FAIL=$((FAIL + 1))
  fi

  case "${MEM_ROOT##*/}" in
    rmt-mem.*) /bin/rm -rf "$MEM_ROOT" ;;
  esac
fi

# ----- NORM (#8123 AC2): the target and the workspace root are compared in one normalized form -----
#
# A root spelled other than its normalized form — through a symlink, with a trailing slash or a
# trailing dot segment — is compared in the form realpath gives it, by the same call that normalizes
# the target. When that call cannot run, a target is refused and never admitted as inside (R1). The
# sandbox base is canonical; `link` is a symlink to `real`, and HOME is spelled through the link, so
# the default root (HOME/Claude) is spelled other than its normalized form. NORM-00 proves that
# premise before any arm depends on it. NORM-05 and -06 run through the test-only seam: a sandbox
# copy whose pinned python3 line is rewritten (the copy must carry exactly that line once), with one
# unusable value per failure branch (absent, fails, prints nothing) and the real one as control.
# NORM-08 to -11 set the root explicitly: `/` and a relative root keep today's refusal (a relative
# root is never anchored to the hook process's own directory; NORM-11-MUT shows that guard live).
# NORM-12 and -13 give the normalizer a target whose normalized form spans two lines.
norm_raw="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-norm.XXXXXX" 2>/dev/null)" || norm_raw=""
NB=""
if [ -n "$norm_raw" ] && [ -d "$norm_raw" ]; then NB="$(cd "$norm_raw" && /bin/pwd -P)" || NB=""; fi
norm_run() { # $1 = hook  $2 = command  $3 = payload cwd  [$4 = workspace root; empty = unset] -> NORM_EXIT, NORM_ERR
  local p; p="$(bash_payload "$2" "$3")"
  NORM_EXIT=0
  if [ -n "${4:-}" ]; then
    NORM_ERR="$(cd "${NB}/real" && /usr/bin/printf '%s' "$p" | /usr/bin/env -u CLAUDE_PROJECT_DIR "HOME=${NB}/link" "CLAUDE_WORKSPACE_ROOT=$4" /bin/bash "$1" 2>&1 >/dev/null)" || NORM_EXIT="$?"
  else
    NORM_ERR="$(cd "${NB}/real" && /usr/bin/printf '%s' "$p" | /usr/bin/env -u CLAUDE_PROJECT_DIR -u CLAUDE_WORKSPACE_ROOT "HOME=${NB}/link" /bin/bash "$1" 2>&1 >/dev/null)" || NORM_EXIT="$?"
  fi
}
norm_case() { # $1 = name  $2 = hook  $3 = command  $4 = payload cwd  $5 = exit  [$6 = pattern]  [$7 = root]
  local ok=1
  norm_run "$2" "$3" "$4" "${7:-}"
  [ "$NORM_EXIT" != "$5" ] && ok=0
  if [ -n "${6:-}" ] && ! /usr/bin/grep -qE "$6" <<< "$NORM_ERR"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  stderr: %s\n' "$1" "$NORM_EXIT" "$5" "$NORM_ERR"; FAIL=$((FAIL + 1))
  fi
}
norm_seam_copy() { # $1 = python3 path -> prints the copy's directory; fails unless it pins exactly that path
  local sbx; sbx="$(mem_hook_copy)" || return 1
  /usr/bin/sed -e 's#^readonly PYTHON3="/usr/bin/python3"$#readonly PYTHON3="'"$1"'"#' "$HOOK" > "${sbx}/block-rm-prefer-trash.sh"
  if [ "$(/usr/bin/grep -c -x -F "readonly PYTHON3=\"$1\"" "${sbx}/block-rm-prefer-trash.sh")" != 1 ]; then mem_drop_copy "$sbx"; return 1; fi
  /usr/bin/printf '%s' "$sbx"
}
if [ -z "$NB" ]; then
  /usr/bin/printf 'FAIL: NORM sandbox base could not be created, so the NORM arms did not run\n'
  FAIL=$((FAIL + 1))
else
  /bin/mkdir -p "${NB}/real/Claude/.claude/worktrees/planning"
  /bin/ln -s "${NB}/real" "${NB}/link"
  NL_CWD="${NB}/link/Claude/.claude/worktrees/planning"
  norm_phys="$(cd "${NB}/link/Claude" 2>/dev/null && /bin/pwd -P)" || norm_phys=""
  if [ "$norm_phys" = "${NB}/real/Claude" ] && [ "$norm_phys" != "${NB}/link/Claude" ]; then
    /usr/bin/printf 'PASS: %s\n' "NORM-00 the root the hook derives is spelled through a symlink (its physical form differs)"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (physical form: %s)\n' "NORM-00 the root the hook derives is spelled through a symlink (its physical form differs)" "$norm_phys"; FAIL=$((FAIL + 1))
  fi
  norm_case "NORM-01: an inside Trash target spelled through the symlinked root is allowed" \
    "$HOOK" "trash ${NB}/link/Claude/n01" "$NL_CWD" 0
  norm_case "NORM-02: an inside Trash target spelled physically under the symlinked root is allowed" \
    "$HOOK" "trash ${NB}/real/Claude/n02" "$NL_CWD" 0
  norm_case "NORM-03: a dot-dot escape from the root spelled through the link is refused" \
    "$HOOK" "trash ${NB}/link/Claude/../n03" "$NL_CWD" 2 "BLOCK-TRASH-003.*deletion outside"
  norm_case "NORM-04: rm of an inside target spelled through the link is redirected to the Trash (-002)" \
    "$HOOK" "rm ${NB}/link/Claude/n04" "$NL_CWD" 2 "BLOCK-TRASH-002"
  for norm_py in /nonexistent/python3 /usr/bin/false /usr/bin/true /usr/bin/python3; do
    norm_sbx="$(norm_seam_copy "$norm_py")" || norm_sbx=""
    if [ -z "$norm_sbx" ]; then
      /usr/bin/printf 'FAIL: NORM-05 and NORM-06 [%s] (no seam copy pinned to that path)\n' "$norm_py"; FAIL=$((FAIL + 2)); continue
    fi
    if [ "$norm_py" = /usr/bin/python3 ]; then
      n5_exit=0; n5_pat=""; n6_pat="BLOCK-TRASH-003.*deletion outside"
    else
      n5_exit=2; n5_pat="BLOCK-TRASH-003.*normalizer"; n6_pat="$n5_pat"
    fi
    norm_case "NORM-05 [${norm_py}]: an inside target under the symlinked root, refused only when the normalizer cannot run" \
      "${norm_sbx}/block-rm-prefer-trash.sh" "trash ${NB}/link/Claude/n05" "$NL_CWD" "$n5_exit" "$n5_pat"
    norm_case "NORM-06 [${norm_py}]: a dot-dot escape from the symlinked root is refused in every mode" \
      "${norm_sbx}/block-rm-prefer-trash.sh" "trash ${NB}/link/Claude/../n06" "$NL_CWD" 2 "$n6_pat"
    mem_drop_copy "$norm_sbx"
  done
  norm_sbx="$(norm_seam_copy /nonexistent/python3)" || norm_sbx=""
  if [ -z "$norm_sbx" ]; then
    /usr/bin/printf 'FAIL: NORM-07 (no seam copy pinned to /nonexistent/python3)\n'; FAIL=$((FAIL + 1))
  else
    norm_case "NORM-07: with no normalizer, rm of an inside target is refused under -001 naming the normalizer (moved from -002)" \
      "${norm_sbx}/block-rm-prefer-trash.sh" "rm ${NB}/link/Claude/n07" "$NL_CWD" 2 "BLOCK-TRASH-001.*normalizer"
    mem_drop_copy "$norm_sbx"
  fi
  norm_case "NORM-08: a root of / does not admit every target (FM-4: today's refusal kept)" \
    "$HOOK" "trash ${NB}/real/n08" "$NL_CWD" 2 "BLOCK-TRASH-003" "/"
  norm_case "NORM-09: a root spelled with a trailing slash admits its inside target" \
    "$HOOK" "trash ${NB}/real/Claude/n09" "$NL_CWD" 0 "" "${NB}/real/Claude/"
  norm_case "NORM-10: a root spelled with a trailing dot segment admits its inside target" \
    "$HOOK" "trash ${NB}/real/Claude/n10" "$NL_CWD" 0 "" "${NB}/real/Claude/."
  norm_case "NORM-11: a relative root is not anchored to the hook process's directory (today's refusal kept)" \
    "$HOOK" "trash ${NB}/real/Claude/n11" "$NL_CWD" 2 "BLOCK-TRASH-003" "Claude"
  norm_sbx="$(mem_hook_copy)" || norm_sbx=""
  if [ -z "$norm_sbx" ]; then
    /usr/bin/printf 'FAIL: NORM-11-MUT (no sandbox copy of the hook)\n'; FAIL=$((FAIL + 1))
  else
    /usr/bin/sed -e 's/^\([[:space:]]*\).*  # M-TRASH-ROOTABS$/\1: # M-TRASH-ROOTABS (removed)/' "$HOOK" > "${norm_sbx}/block-rm-prefer-trash.sh"
    if ra_live "${norm_sbx}/block-rm-prefer-trash.sh"; then
      norm_case "NORM-11-MUT: a copy without the absolute-root guard admits NORM-11's target, so the guard holds it" \
        "${norm_sbx}/block-rm-prefer-trash.sh" "trash ${NB}/real/Claude/n11" "$NL_CWD" 0 "" "Claude"
    else
      /usr/bin/printf 'FAIL: NORM-11-MUT the copy is not live (it does not differ from the hook by exactly its one marked line, or does not parse)\n'; FAIL=$((FAIL + 1))
    fi
    mem_drop_copy "$norm_sbx"
  fi
  # NORM-12 and -13: an outside target reached through a link whose destination ends in a line break
  # normalizes to a path that spans two lines. The compare reads the normalizer's output only when it
  # is exactly the two paths and the sentinel, one line each, so such a target is refused as one the
  # hook cannot bring into one form, and it is never compared with a piece of itself (NORM-12-MUT shows
  # that check live). Both are refused on the pre-fix hooks too, so each pattern names the rule alone.
  /bin/mkdir -p "${NB}/out"
  /bin/ln -s "${NB}/out/n12"$'\n' "${NB}/out/n12-brk"
  norm_case "NORM-12: a Trash target through a link whose destination ends in a line break is refused" \
    "$HOOK" "trash ${NB}/out/n12-brk" "$NL_CWD" 2 "BLOCK-TRASH-003"
  norm_case "NORM-13: rm of a target through the same link is refused under -001, not read as inside" \
    "$HOOK" "rm ${NB}/out/n12-brk" "$NL_CWD" 2 "BLOCK-TRASH-001"
  norm_sbx="$(mem_hook_copy)" || norm_sbx=""
  if [ -z "$norm_sbx" ]; then
    /usr/bin/printf 'FAIL: NORM-12-MUT (no sandbox copy of the hook)\n'; FAIL=$((FAIL + 1))
  else
    /usr/bin/sed -e 's/^\([[:space:]]*\).*  # M-TRASH-NORMLINES$/\1: # M-TRASH-NORMLINES (removed)/' "$HOOK" > "${norm_sbx}/block-rm-prefer-trash.sh"
    if ra_live "${norm_sbx}/block-rm-prefer-trash.sh"; then
      norm_case "NORM-12-MUT: a copy without the three-line check admits NORM-12's target, so the check holds it" \
        "${norm_sbx}/block-rm-prefer-trash.sh" "trash ${NB}/out/n12-brk" "$NL_CWD" 0
    else
      /usr/bin/printf 'FAIL: NORM-12-MUT the copy is not live (it does not differ from the hook by exactly its one marked line, or does not parse)\n'; FAIL=$((FAIL + 1))
    fi
    mem_drop_copy "$norm_sbx"
  fi
  case "${NB##*/}" in rmt-norm.*) /bin/rm -rf "$NB" ;; esac
fi

# ----- AC-CPH-T* (#8314, DT pass 7): the hook clears the canonicalizer's long shapes inside the budget -----
#
# The shared canonicalizer's three changed sites — the basename step of a prefix word, the option-cluster
# walk and the split-string scan — each read their token once, so this hook, which canonicalizes every Bash
# command, clears one long command word, a long option cluster and a long split string in its short and
# long spelling inside the budget at 10, 20, 40 and 80 KB in en_US.UTF-8 and C, and allows each. The arms
# that see each site's cost apart from the rest of the hook are the false-positive control's AC-CP-L arms,
# on the canonicalizer alone, beside their sensitivity copy.
TRSC_LIMIT="${TRSC_LIMIT_DS:-200}"   # tenths of a second
# trsc_ratio <tenths> <limit> — a run's cost as a share of its budget, or "stopped" when the watchdog ended it:
# what a timed arm prints in place of a time, so no output line pairs a command's size with a time.
trsc_ratio() { if [ "$1" = -1 ]; then /usr/bin/printf stopped; else /usr/bin/awk -v d="$1" -v l="$2" 'BEGIN { printf "%.2f", (l > 0 ? d / l : 0) }'; fi; }
TRSC_BASE="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-cph.XXXXXX" 2>/dev/null)" || TRSC_BASE=""
# trsc_cmd <shape> <bytes> <file> — the head, as many units as fit, then the tail, built by doubling.
trsc_cmd() {
  local h u t
  case "$1" in
    word)    h='';                     u='a';    t='' ;;
    cluster) h='sudo -';               u='b';    t=' q' ;;
    split)   h='env -S-';              u='b';    t=' q' ;;
    lsplit)  h='env --split-string=-'; u='b';    t=' q' ;;
    segs)    h='';                     u='a; ';  t='a' ;;
  esac
  H="$h" U="$u" T="$t" LC_ALL=C /usr/bin/awk -v n="$2" 'BEGIN { h = ENVIRON["H"]; u = ENVIRON["U"]; t = ENVIRON["T"]
    m = int((n - length(h) - length(t)) / length(u)) * length(u); r = u; while (length(r) < m) r = r r
    printf "%s", h substr(r, 1, m) t }' > "$3"
}
# trsc_reap <pid> — stop a process and every process under it, children first, with KILL.
trsc_reap() {
  local c
  for c in $(/usr/bin/pgrep -P "$1" 2>/dev/null); do trsc_reap "$c"; done
  kill -9 "$1" 2>/dev/null
}
# trsc_timed <hook-file> <locale> <command-file> <limit> — the hook on the Bash payload of the command
# under a watchdog; sets TRSC_DS (tenths elapsed, -1 when stopped) and TRSC_EXIT.
TRSC_DS=0
TRSC_EXIT=0
trsc_timed() {
  local pay="${TRSC_BASE}/payload.json" pid n=0
  bash_payload "$(/bin/cat "$3")" > "$pay"
  LC_ALL="$2" /bin/bash "$1" < "$pay" > /dev/null 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$n" -ge "$4" ]; then
      trsc_reap "$pid"; wait "$pid" 2>/dev/null
      TRSC_DS=-1; TRSC_EXIT=-1; return 0
    fi
    /bin/sleep 0.1; n=$(( n + 1 ))
  done
  TRSC_EXIT=0; wait "$pid" || TRSC_EXIT=$?
  TRSC_DS="$n"
}
if [ -z "$TRSC_BASE" ]; then
  /usr/bin/printf 'FAIL: AC-CPH-T the timed arms could not create a sandbox, so they did not run\n'; FAIL=$((FAIL + 1))
else
  trsc_n=0
  for trsc_shape in word cluster split lsplit; do
    for trsc_kb in 10 20 40 80; do trsc_cmd "$trsc_shape" $(( trsc_kb * 1024 )) "${TRSC_BASE}/${trsc_shape}-${trsc_kb}.cmd"; done
    for trsc_loc in en_US.UTF-8 C; do
      for trsc_kb in 10 20 40 80; do
        trsc_n=$(( trsc_n + 1 ))
        trsc_timed "$HOOK" "$trsc_loc" "${TRSC_BASE}/${trsc_shape}-${trsc_kb}.cmd" "$TRSC_LIMIT"
        if [ "$TRSC_DS" != -1 ] && [ "$TRSC_EXIT" = 0 ]; then
          /usr/bin/printf 'PASS: %s\n' "AC-CPH-T${trsc_n}: the long ${trsc_shape} shape at ${trsc_kb} KB in ${trsc_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
        else
          /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPH-T${trsc_n}: the long ${trsc_shape} shape in ${trsc_loc} clears the hook inside the budget and is allowed — measured ratio $(trsc_ratio "${TRSC_DS}" "${TRSC_LIMIT}") of the budget, bound 1.00" \
            "\"stopped\" is the watchdog ending the run at the budget; exit=${TRSC_EXIT} (want 0)"; FAIL=$((FAIL + 1))
        fi
      done
    done
  done
fi
case "${TRSC_BASE##*/}" in rmt-cph.*) /bin/rm -rf "$TRSC_BASE" ;; esac

# ----- AC-CPV-T* (#8314, DT pass 7; re-based by #8122): one canonicalizer run per command -----
#
# The hook makes one run of the shared canonicalizer on a command, in its default view, and reads
# no other view. ONE reads the hook's source: one run on the command, none in the both view and
# none in the exit view. EQ holds the verdicts: a copy of this hook with a second, identical
# default-view run spliced in after the first is shown live (it differs only in that line, and it
# parses), then both copies judge a set of commands — the lines the removed exits once allowed,
# wrapped and quoted spellings, refused and allowed deletions and Trash calls — and must return the
# same exit code and the same message on each. T1 to T16 run the hook under a watchdog on one long
# command word and on a separator-dense command at 10, 20, 40 and 80 KB in en_US.UTF-8 and C, each
# inside the budget and allowed. R-U and R-C time the hook against the canonicalizer's default
# view alone on the 80 KB long word, the least of three interleaved runs of each: the hook costs at
# most CPV_BOUND times the one run. CTL is the instrument's sensitivity: the copy with the second
# run exceeds the bound on the same command in UTF-8.
CPV_BOUND="${CPV_BOUND:-1.75}"
CPV_LIMIT="${CPV_LIMIT_S:-60}"   # seconds a timed run may take before the watchdog stops it
CPV_BASE="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-cpv.XXXXXX" 2>/dev/null)" || CPV_BASE=""
CPV_ONE='COMMAND_CMDPOS="$("$PRINTF" '"'%s'"' "$COMMAND" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '"'%s'"' "$COMMAND")"
'
CPV_TWO='COMMAND_CMDPOS="$("$PRINTF" '"'%s'"' "$COMMAND" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '"'%s'"' "$COMMAND")"
COMMAND_CMDPOS="$("$PRINTF" '"'%s'"' "$COMMAND" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '"'%s'"' "$COMMAND")"
'
# ONE — the runs of the canonicalizer on the command, read from the hook's source.
cpv_runs="$(/usr/bin/awk '/^[ \t]*#/ { next } index($0, "-f \"$CMDPOS_AWK\"") && index($0, "\"$COMMAND\"") { n++; if (index($0, "-v CMDPOS_VIEW=both")) b++; if (index($0, "-v CMDPOS_VIEW=exit")) x++ }
  END { printf "%d %d %d", n, b, x }' "$HOOK")"
if [ "$cpv_runs" = "1 0 0" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-CPV-ONE: the hook runs the canonicalizer once on a command, in the default view, and never in the exit or both view"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPV-ONE: the hook runs the canonicalizer once on a command, in the default view" \
    "runs on the command / in the both view / in the exit view: ${cpv_runs} (want 1 0 0)"; FAIL=$((FAIL + 1))
fi
if [ -z "$CPV_BASE" ]; then
  /usr/bin/printf 'FAIL: AC-CPV the arms could not create a sandbox, so they did not run\n'; FAIL=$((FAIL + 1))
else
  /bin/mkdir -p "${CPV_BASE}/one/lib" "${CPV_BASE}/two/lib"
  for cpv_d in one two; do
    /bin/cp "${HOOK_DIR}/lib/"*.sh "${CPV_BASE}/${cpv_d}/lib/" 2>/dev/null || true
    /bin/cp "${HOOK_DIR}/lib/command-position.awk" "${CPV_BASE}/${cpv_d}/lib/"
  done
  /bin/cp "$HOOK" "${CPV_BASE}/one/block-rm-prefer-trash.sh"
  cpv_live=0
  if F="$CPV_ONE" T="$CPV_TWO" LC_ALL=C /usr/bin/awk 'BEGIN { f = ENVIRON["F"]; t = ENVIRON["T"] } { s = s $0 "\n" }
       END { i = index(s, f); if (i == 0 || index(substr(s, i + 1), f) > 0) exit 1
             printf "%s", substr(s, 1, i - 1) t substr(s, i + length(f)) }' "$HOOK" > "${CPV_BASE}/two/block-rm-prefer-trash.sh" \
     && /bin/bash -n "${CPV_BASE}/two/block-rm-prefer-trash.sh" 2>/dev/null \
     && ! /usr/bin/cmp -s "$HOOK" "${CPV_BASE}/two/block-rm-prefer-trash.sh"; then
    cpv_live=1
  fi
  # EQ — the same exit code and message through both copies.
  cpv_why=""; cpv_k=0
  while IFS= read -r cpv_c; do
    [ -n "$cpv_c" ] || continue
    cpv_k=$((cpv_k + 1))
    cpv_r1=0; cpv_r2=0
    cpv_e1="$( ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
        /usr/bin/printf '%s' "$(bash_payload "$cpv_c" "$CPV_BASE")" | /bin/bash "${CPV_BASE}/one/block-rm-prefer-trash.sh" 2>&1 >/dev/null ) )" || cpv_r1="$?"
    cpv_e2="$( ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
        /usr/bin/printf '%s' "$(bash_payload "$cpv_c" "$CPV_BASE")" | /bin/bash "${CPV_BASE}/two/block-rm-prefer-trash.sh" 2>&1 >/dev/null ) )" || cpv_r2="$?"
    [ "$cpv_r1" = "$cpv_r2" ] && [ "$cpv_e1" = "$cpv_e2" ] || cpv_why="${cpv_why} [${cpv_c}] exit ${cpv_r1} through one run, ${cpv_r2} through two;"
  done <<'CPV_EOF'
rm -rf /tmp/foo
echo hello
rm
sudo rm ; trash /etc/hosts
nice rm ; trash /etc/hosts
nice rm ; sudo unlink /tmp/foo
sudo --list rm ; trash /etc/hosts
FOO+=1 rm ; trash /etc/hosts
FOO+=1 rm ; sudo unlink /tmp/foo
rm -rf "/tmp/a b" ; echo "x; rm -rf /etc"
echo "rm -rf /tmp/foo"
\rm -rf /tmp/foo
xargs rm < /tmp/list
find /tmp -delete
trash /etc/hosts
unlink /tmp/foo ; rmdir /tmp/d
if true ; then rm -rf /tmp/foo ; fi
env -S-u x rm -rf /tmp/foo
osascript -e 'tell application "Finder" to delete POSIX file "/tmp/foo"'
git status ; rm -rf /tmp/foo
sudo git status ; rm -rf /tmp/foo
nice git status ; rm -rf /tmp/foo
if git diff --quiet ; then rm -rf /tmp/foo ; fi
/usr/bin/env git log ; rm -rf /tmp/foo
FOO+=1 git status ; rm -rf /tmp/foo
git rm -rf /tmp/foo
echo '; git status' ; rm -rf /tmp/foo
CPV_EOF
  if [ "$cpv_live" = 1 ] && [ -z "$cpv_why" ]; then
    /usr/bin/printf 'PASS: %s\n' "AC-CPV-EQ: through one run and through a second run spliced in, the hook returns the same exit code and message on ${cpv_k} commands"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPV-EQ: the hook's verdicts are the same through one run as through two" \
      "two-run copy live=${cpv_live};${cpv_why}"; FAIL=$((FAIL + 1))
  fi
  # T1-T16 — the hook inside the budget, by the AC-CPH-T timer above, writing its payload here.
  TRSC_BASE="$CPV_BASE"
  cpv_n=0
  for cpv_shape in word segs; do
    for cpv_kb in 10 20 40 80; do trsc_cmd "$cpv_shape" $(( cpv_kb * 1024 )) "${CPV_BASE}/${cpv_shape}-${cpv_kb}.cmd"; done
    for cpv_loc in en_US.UTF-8 C; do
      for cpv_kb in 10 20 40 80; do
        cpv_n=$(( cpv_n + 1 ))
        trsc_timed "$HOOK" "$cpv_loc" "${CPV_BASE}/${cpv_shape}-${cpv_kb}.cmd" "$TRSC_LIMIT"
        if [ "$TRSC_DS" != -1 ] && [ "$TRSC_EXIT" = 0 ]; then
          /usr/bin/printf 'PASS: %s\n' "AC-CPV-T${cpv_n}: the ${cpv_shape} shape at ${cpv_kb} KB in ${cpv_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
        else
          /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPV-T${cpv_n}: the long ${cpv_shape} shape in ${cpv_loc} clears the hook inside the budget and is allowed — measured ratio $(trsc_ratio "${TRSC_DS}" "${TRSC_LIMIT}") of the budget, bound 1.00" \
            "\"stopped\" is the watchdog ending the run at the budget; exit=${TRSC_EXIT} (want 0)"; FAIL=$((FAIL + 1))
        fi
      done
    done
  done
  # R and CTL — the hook against one run of the canonicalizer's default view, on the 80 KB long word.
  CPV_PY='import json, os, signal, subprocess, sys, threading, time
hook, awk, loc, reps, limit, cmdf = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), float(sys.argv[5]), sys.argv[6]
cmd = open(cmdf, "rb").read().decode("utf-8", "surrogateescape")
pay = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": os.environ.get("HOME", "/") + "/Claude/.claude/worktrees/planning"}).encode()
env = dict(os.environ, LC_ALL=loc)
def one(argv, stdin):
    # A blocking wait reads the run exactly; a wait with a timeout polls at steps that grow to
    # a twentieth of a second. The watchdog is a timer instead.
    stopped = []
    t0 = time.time()
    p = subprocess.Popen(argv, env=env, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    def stop():
        stopped.append(1)
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except OSError:
            pass
    dog = threading.Timer(limit, stop)
    dog.start()
    try:
        p.communicate(stdin)
    except OSError:
        pass
    p.wait()
    dog.cancel()
    return None if stopped else time.time() - t0
h, c = [], []
for _ in range(reps):
    h.append(one(["/bin/bash", hook], pay)); c.append(one(["/usr/bin/awk", "-f", awk, cmdf], b""))
print("-1 -1" if None in h or None in c else "%.3f %.3f" % (min(h), min(c)))'
  cpv_ratio() { # <hook> <locale> -> CPV_H, CPV_C (seconds; -1 when stopped) and CPV_OK
    local out
    out="$(/usr/bin/python3 -c "$CPV_PY" "$1" "${HOOK_DIR}/lib/command-position.awk" "$2" 3 "$CPV_LIMIT" "${CPV_BASE}/word-80.cmd" 2>/dev/null)" || out="-1 -1"
    CPV_H="${out% *}"; CPV_C="${out#* }"
    CPV_OK=0; CPV_RATIO=stopped
    [ "$CPV_H" = -1 ] || CPV_RATIO="$(/usr/bin/awk -v h="$CPV_H" -v c="$CPV_C" 'BEGIN { printf "%.2f", (c > 0 ? h / c : 0) }')"
    if [ "$CPV_H" != -1 ] && /usr/bin/awk -v h="$CPV_H" -v c="$CPV_C" -v b="$CPV_BOUND" 'BEGIN { exit !(c > 0 && h <= b * c) }'; then CPV_OK=1; fi
  }
  for cpv_loc in en_US.UTF-8 C; do
    cpv_ratio "$HOOK" "$cpv_loc"
    cpv_tag="U"; [ "$cpv_loc" = C ] && cpv_tag="C"
    if [ "$CPV_OK" = 1 ]; then
      /usr/bin/printf 'PASS: %s\n' "AC-CPV-R-${cpv_tag}: on the 80 KB long word in ${cpv_loc} the hook costs within ${CPV_BOUND} times one run of the canonicalizer"; PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPV-R-${cpv_tag}: on the 80 KB long word in ${cpv_loc} the hook costs at most ${CPV_BOUND} times one run of the canonicalizer — measured ratio ${CPV_RATIO}, bound ${CPV_BOUND}" \
        "\"stopped\" is the watchdog ending a run"; FAIL=$((FAIL + 1))
    fi
  done
  cpv_ratio "${CPV_BASE}/two/block-rm-prefer-trash.sh" en_US.UTF-8
  if [ "$cpv_live" = 1 ] && [ "$CPV_H" != -1 ] && [ "$CPV_OK" = 0 ]; then
    /usr/bin/printf 'PASS: %s\n' "AC-CPV-CTL: the copy with a second run costs beyond ${CPV_BOUND} times one run of the canonicalizer on the 80 KB long word in UTF-8 — the instrument sees the second run"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPV-CTL: the copy with two runs exceeds the bound (BROKEN PROBE) — measured ratio ${CPV_RATIO}, bound ${CPV_BOUND}" \
      "copy live=${cpv_live}"; FAIL=$((FAIL + 1))
  fi
  case "${CPV_BASE##*/}" in rmt-cpv.*) /bin/rm -rf "$CPV_BASE" ;; esac
fi

# ----- HDATA-* (#7644): a quoted here-document body read by a listed receiver is data -----
#
# A here-document whose delimiter is quoted ('D', "D", \D) has a body the shell neither expands nor
# runs. At the top level of a command, when the receiver is on the data-receiver list (cat; git
# commit|tag after at most one -C <dir>; gh issue|pr|release|api; python3 with the operand -) and
# nothing on the command can route the body to a program that runs it, the hook removes the body
# and its delimiter line from the text every rule reads. Every other shape keeps today's verdict.
#   AC1   a listed receiver, top level: refused today under -001, -002 or -003, allowed now.
#   TWIN  the same commands with their body and delimiter lines removed: allowed on both hooks. A
#         check of the excision mechanics, not a member of the declared set.
#   CWD   a directory change inside a data body no longer moves the working directory a later
#         relative deletion is judged from: refused today under -001, refused now under -002.
#   AC2 / AC3   controls: a deletion outside the body, and an unquoted body (its substitution is
#         expanded), stay refused.
#   RX    every receiver class that is not data, and every route to a program, stays refused.
#   ENCL  a quoted here-document inside a command substitution, a backtick or a subshell stays
#         judged on every shell: bash 3.2 ends such a body at an unbalanced ) inside an unquoted
#         substitution and runs the lines after it.
#   GIT   the git receiver, graded through a copy of the hook with the whole-line git exit
#         removed while that exit exists (it allows every git-headed line today).
#   PY / PIN   the declared residuals D-PyNested and D-Deferred, pinned.
#   CAP / COST the 20 000-character scan budget and the 4096-character line cap, and the cost.
#   MUT   each decline shown load-bearing: a copy of the hook without it allows its sentinels.
# Payloads are built as $'...' strings: a newline is \n, a tab \t, an apostrophe \'.
HD_AC1_A=$'cat > /tmp/hd-gen.sh <<\'EOF\'\nrm -f "$X"\nEOF'
HD_AC1_B=$'python3 - "/tmp/hd-run" <<\'PYEOF\'\nimport sys\nprint(sys.argv[1])\nrm -f "$FCM_ADDS" "$FCM_ANY"\nPYEOF'
HD_AC1_C=$'python3 - <<\'PYEOF\'\nrm = 1\nprint(rm)\nPYEOF'
HD_AC1_D=$'gh issue comment 1 --body-file - <<\'EOF\'\nrm -rf /tmp/hd-old\nEOF'
HD_AC1_F=$'cat <<-\'EOF\'\n\trm -rf /tmp/hd-f\n\tEOF'
HD_AC1_G=$'cat <<\\EOF\nrm -rf /tmp/hd-g\nEOF'
HD_AC1_H=$'cat <<"EOF"\nrm -rf /tmp/hd-h\nEOF'
HD_AC1_I=$'cat <<\'EOF\'\nrm -rf /tmp/hd-i\ndon\'t\nEOF'
HD_AC1_J=$'cat <<\'EOF\'\ntrash /etc/hd-j\nEOF'

test_case "HDATA-AC1-A: cat writing a file; a body line deletes a variable operand (-001 today)" \
  "$(bash_payload "$HD_AC1_A")" 0
test_case "HDATA-AC1-B: a python3 - program; a body line deletes variable operands (-001 today)" \
  "$(bash_payload "$HD_AC1_B")" 0
test_case "HDATA-AC1-C: a python3 - program; a variable named like the verb (-002 today)" \
  "$(bash_payload "$HD_AC1_C" "$RMT_FIXTURE_CWD")" 0 "" "$RMT_HOME_ENV"
test_case "HDATA-AC1-D: a gh body read from stdin; a body line deletes an outside path (-001 today)" \
  "$(bash_payload "$HD_AC1_D")" 0
test_case "HDATA-AC1-F: the tab-stripping form; a body line deletes an outside path (-001 today)" \
  "$(bash_payload "$HD_AC1_F")" 0
test_case "HDATA-AC1-G: the backslash-quoted delimiter; a body deletion line (-001 today)" \
  "$(bash_payload "$HD_AC1_G")" 0
test_case "HDATA-AC1-H: the double-quoted delimiter; a body deletion line (-001 today)" \
  "$(bash_payload "$HD_AC1_H")" 0
test_case "HDATA-AC1-I: a body with an unpaired apostrophe after a deletion line (-001 today)" \
  "$(bash_payload "$HD_AC1_I")" 0
test_case "HDATA-AC1-J: a body line is a Trash call on an outside path (-003 today)" \
  "$(bash_payload "$HD_AC1_J")" 0

test_case "HDATA-TWIN-A: AC1-A without its body and delimiter lines allows" \
  "$(bash_payload $'cat > /tmp/hd-gen.sh <<\'EOF\'')" 0
test_case "HDATA-TWIN-B: AC1-B without its body and delimiter lines allows" \
  "$(bash_payload $'python3 - "/tmp/hd-run" <<\'PYEOF\'')" 0
test_case "HDATA-TWIN-D: AC1-D without its body and delimiter lines allows" \
  "$(bash_payload $'gh issue comment 1 --body-file - <<\'EOF\'')" 0
test_case "HDATA-TWIN-I: AC1-I without its body and delimiter lines allows" \
  "$(bash_payload $'cat <<\'EOF\'')" 0

test_case "HDATA-CWD: a directory change inside a data body does not move the later relative deletion" \
  "$(bash_payload $'cat <<\'EOF\'\ncd /tmp\nEOF\nrm notes.txt' "$RMT_FIXTURE_CWD")" 2 "BLOCK-TRASH-002" "$RMT_HOME_ENV"

test_case "HDATA-AC2-A: an outside deletion after the delimiter line stays refused" \
  "$(bash_payload $'cat <<\'EOF\'\nhello\nEOF\nrm -rf /tmp/hd-a2')" 2 "BLOCK-TRASH-001"
test_case "HDATA-AC2-B: an outside deletion before the operator stays refused" \
  "$(bash_payload $'rm -rf /tmp/hd-b2; cat <<\'EOF\'\nhello\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-AC2-C: an outside deletion after a separator on the operator line stays refused" \
  "$(bash_payload $'cat <<\'EOF\'; rm -rf /tmp/hd-c2\nhello\nEOF')" 2 "BLOCK-TRASH-001"

HD_AC3_A=$'cat <<EOF\n$(true; rm -rf /tmp/hd-a3)\nEOF'
HD_AC3_B=$'cat <<EOF\nrm -rf /tmp/hd-b3\nEOF'
test_case "HDATA-AC3-A: an unquoted body whose substitution deletes after a separator stays refused" \
  "$(bash_payload "$HD_AC3_A")" 2 "BLOCK-TRASH-001"
test_case "HDATA-AC3-B: an unquoted plain body with an outside deletion stays refused" \
  "$(bash_payload "$HD_AC3_B")" 2 "BLOCK-TRASH-001"

HD_RX_SHELL=$'bash <<\'EOF\'\nrm -rf /tmp/hd-sh\nEOF'
HD_RX_PYC=$'python3 -c \'print(1)\' <<\'EOF\'\nrm -rf /tmp/hd-pyc\nEOF'
HD_RX_PATHQ=$'/tmp/hd-bin/cat <<\'EOF\'\nrm -rf /tmp/hd-pq\nEOF'
HD_RX_OSA=$'osascript <<\'EOF\'\ntell application "Finder" to delete POSIX file "/etc/hd-osa"\nEOF'
HD_RX_PIPE=$'cat <<\'EOF\' | sh\nrm -rf /tmp/hd-p\nEOF'
HD_RX_FUNC=$'cat() { bash; }; cat <<\'EOF\'\nrm -rf /tmp/hd-fn\nEOF'
HD_RX_FUNC2=$'cat ( ) { bash; }; cat <<\'EOF\'\nrm -rf /tmp/hd-fn2\nEOF'
HD_RX_EVAL=$'eval "$(cat <<\'EOF\'\nsay "hi\nrm -rf /tmp/hd-ev\nEOF\n)"'
test_case "HDATA-RX-SHELL: a shell reading the body as its script stays refused" \
  "$(bash_payload "$HD_RX_SHELL")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-SH: a shell reading its script from stdin stays refused" \
  "$(bash_payload $'sh -s <<\'EOF\'\nrm -rf /tmp/hd-sh2\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PIPE: a listed receiver piped into a shell stays refused" \
  "$(bash_payload "$HD_RX_PIPE")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PROCSUB: a listed receiver writing into a process substitution stays refused" \
  "$(bash_payload $'cat <<\'EOF\' > >(sh)\nrm -rf /tmp/hd-ps\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-EVAL: a substitution consumed by an evaluator stays refused" \
  "$(bash_payload "$HD_RX_EVAL")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ASSIGN: a substitution consumed by an assignment stays refused" \
  "$(bash_payload $'X="$(cat <<\'EOF\'\nsay "hi\nrm -rf /tmp/hd-as\nEOF\n)"')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PYC: a python3 -c program reading the body stays refused" \
  "$(bash_payload "$HD_RX_PYC")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PYM: a python3 -m module reading the body stays refused" \
  "$(bash_payload $'python3 -m json.tool <<\'EOF\'\nrm -rf /tmp/hd-pym\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PYSCRIPT: a python3 script operand reading the body stays refused" \
  "$(bash_payload $'python3 /tmp/hd-script.py <<\'EOF\'\nrm -rf /tmp/hd-pys\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PATHQ: a receiver named by a non-canonical path stays refused" \
  "$(bash_payload "$HD_RX_PATHQ")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-WRAP: a receiver behind a wrapper stays refused (a declared over-block)" \
  "$(bash_payload $'env cat <<\'EOF\'\nrm -rf /tmp/hd-w\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-GHEXT: a gh extension stays refused" \
  "$(bash_payload $'gh hd-ext <<\'EOF\'\nrm -rf /tmp/hd-gx\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-OSA: osascript reading its script from the body stays refused" \
  "$(bash_payload "$HD_RX_OSA")" 2 "BLOCK-TRASH-003"
test_case "HDATA-RX-MIXED: one data body beside one shell-script body stays refused" \
  "$(bash_payload $'cat <<\'EOF\'; bash <<\'EOS\'\nhello\nEOF\nrm -rf /tmp/hd-mx\nEOS')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-UNTERM: an unterminated body stays refused" \
  "$(bash_payload $'cat <<\'EOF\'\nrm -rf /tmp/hd-ut')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ARITH: a shift inside arithmetic on the same command stays refused" \
  "$(bash_payload $'echo $((1 << 2)); cat <<\'EOF\'\nrm -rf /tmp/hd-ar\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-FUNC: a listed name redefined as a function on the line stays refused" \
  "$(bash_payload "$HD_RX_FUNC")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-FUNC2: a function definition with blanks between its parentheses stays refused" \
  "$(bash_payload "$HD_RX_FUNC2")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ALIAS: a listed name redefined as an alias on the line stays refused" \
  "$(bash_payload $'alias cat=bash; cat <<\'EOF\'\nrm -rf /tmp/hd-al\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PATHVAR: a PATH assignment on the line stays refused" \
  "$(bash_payload $'PATH=/tmp/hd-bin:$PATH; cat <<\'EOF\'\nrm -rf /tmp/hd-pv\nEOF')" 2 "BLOCK-TRASH-001"
# zsh's definition tables. On zsh a name is redefined as a function, an alias or a command path by
# assigning to one of its tables, with no redefinition word on the line. A word that ends in one of
# those table names declines as the words above do, so the sibling tables (global and suffix
# aliases, the disabled forms) decline too. The control carries each name followed by a word
# character, which is not a table name.
HD_RX_ZFUNCS=$'functions[cat]=bash; cat <<\'EOF\'\nrm -rf /tmp/hd-zf\nEOF'
HD_RX_ZCOMMANDS=$'commands[cat]=/bin/sh; cat <<\'EOF\'\nrm -rf /tmp/hd-zc\nEOF'
test_case "HDATA-RX-ZFUNCS: a listed name redefined through zsh's function table stays refused" \
  "$(bash_payload "$HD_RX_ZFUNCS")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ZALIASES: a listed name redefined through zsh's alias table stays refused" \
  "$(bash_payload $'aliases[cat]=bash; cat <<\'EOF\'\nrm -rf /tmp/hd-za\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ZCOMMANDS: a listed name re-pointed through zsh's command-path table stays refused" \
  "$(bash_payload "$HD_RX_ZCOMMANDS")" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ZARRAY: zsh's alias table assigned as a whole array stays refused" \
  "$(bash_payload $'aliases+=(cat bash); cat <<\'EOF\'\nrm -rf /tmp/hd-zr\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ZSIBLING: a sibling table (global aliases) stays refused" \
  "$(bash_payload $'galiases[EOF]=x; cat <<\'EOF\'\nrm -rf /tmp/hd-zg\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-GITC: git with a global option defining an alias is not a listed receiver and stays refused (INT-GITC)" \
  "$(bash_payload $'git -c alias.hd=\'!sh\' hd <<\'EOF\'\nrm -rf /tmp/hd-gitc\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-ZPATH: a listed receiver writing to a path that carries a table name as a directory is data" \
  "$(bash_payload $'cat > /tmp/hd-cfg/commands/note.md <<\'EOF\'\nrm -rf /tmp/hd-zp\nEOF')" 0
test_case "HDATA-RX-ZCTL: a table name followed by a word character is not a table, so the body is data" \
  "$(bash_payload $': aliasesx functionsx commandsx; cat <<\'EOF\'\nrm -rf /tmp/hd-zn\nEOF')" 0
test_case "HDATA-RX-PEXP: the operator inside a parameter expansion, brace adjacent, stays refused" \
  "$(bash_payload $': ${X:-<<\'EOF\'}\nrm -rf /tmp/hd-pe\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PEXP2: the operator inside a double-quoted parameter expansion stays refused" \
  "$(bash_payload $': "${X:-<<\'EOF\'}"\nrm -rf /tmp/hd-pe2\nEOF')" 2 "BLOCK-TRASH-001"
test_case "HDATA-RX-PEXP3: the operator inside a parameter expansion, blank before the brace, stays refused" \
  "$(bash_payload $': ${X:-<<\'EOF\' }\nrm -rf /tmp/hd-pe3\nEOF')" 2 "BLOCK-TRASH-001"

HD_ENCL_A=$'gh pr create --title t --body "$(cat <<\'EOF\'\nsay "hi\nrm -rf /tmp/hd-ea\nEOF\n)"'
HD_ENCL_B=$'gh pr create --title t --body $(cat <<\'EOF\'\nnote)\nrm -rf /tmp/hd-eb\nEOF\n)'
# ENCL-C ends its subshell on a line that carries a command: a ")" alone on a line after the
# subshell's text reads as an empty parenthesis pair, a second decline (toward today's verdict)
# that would hold the sentinel through the ENCL mutant and hide whether the enclosure decline is live.
HD_ENCL_C=$'( cat <<\'EOF\'\nrm -rf /tmp/hd-ec\nEOF\necho done)'
test_case "HDATA-ENCL-A: a data body inside a double-quoted substitution stays judged" \
  "$(bash_payload "$HD_ENCL_A")" 2 "BLOCK-TRASH-001"
test_case "HDATA-ENCL-B: a data body inside an unquoted substitution, a body line with an unbalanced ), stays judged" \
  "$(bash_payload "$HD_ENCL_B")" 2 "BLOCK-TRASH-001"
test_case "HDATA-ENCL-C: a data body inside a subshell stays judged" \
  "$(bash_payload "$HD_ENCL_C")" 2 "BLOCK-TRASH-001"
test_case "HDATA-ENCL-D: a data body inside a backtick substitution stays judged" \
  "$(bash_payload $'X=`cat <<\'EOF\'\nrm -rf /tmp/hd-ed\nEOF\n`')" 2 "BLOCK-TRASH-001"

test_case "HDATA-PY-ODD: a python3 - program handing a string to a shell, odd quote parity (declared D-PyNested)" \
  "$(bash_payload $'python3 - <<\'PYEOF\'\nimport os\nos.system("""say "hi\nrm -rf /tmp/hd-py\n""")\nPYEOF')" 0
test_case "HDATA-PY-EVEN: the same program with balanced quoting allows (today and now)" \
  "$(bash_payload $'python3 - <<\'PYEOF\'\nimport os\nos.system("""say hi\nrm -rf /tmp/hd-py\n""")\nPYEOF')" 0
test_case "HDATA-PIN-DEFERRED: cat writes a script a later segment runs (declared D-Deferred)" \
  "$(bash_payload $'cat > /tmp/hd-run.sh <<\'EOF\'\nrm -rf /tmp/hd-dd\nEOF\nbash /tmp/hd-run.sh')" 0

# The budget: 20 000 scanned characters outside bodies, and a 4096-character line. hd_pad <n> prints
# n lines of 3800 characters each (a no-op command), so the scanned text sits under or over the cap.
hd_pad() { /usr/bin/awk -v n="$1" 'BEGIN { s = ": "; while (length(s) < 3800) s = s "a"; for (i = 0; i < n; i++) print s }'; }
HD_CAP_IN="$(hd_pad 5)"$'\ncat <<\'EOF\'\nrm -rf /tmp/hd-cap\nEOF'
HD_CAP_OVER="$(hd_pad 6)"$'\ncat <<\'EOF\'\nrm -rf /tmp/hd-cap\nEOF'
HD_CAP_LINE="$(/usr/bin/awk 'BEGIN { s = ": "; while (length(s) < 4100) s = s "a"; print s }')"$'\ncat <<\'EOF\'\nrm -rf /tmp/hd-cap\nEOF'
test_case "HDATA-CAP-IN: a data body after 19 000 scanned characters is read as data" \
  "$(bash_payload "$HD_CAP_IN")" 0
test_case "HDATA-CAP-OVER: past 20 000 scanned characters the command keeps today's verdict" \
  "$(bash_payload "$HD_CAP_OVER")" 2 "BLOCK-TRASH-001"
test_case "HDATA-CAP-LINE: a scanned line over 4096 characters keeps today's verdict" \
  "$(bash_payload "$HD_CAP_LINE")" 2 "BLOCK-TRASH-001"

# The cost at the cap: the hook on HDATA-CAP-IN against the same padding with no here-document,
# the least of three interleaved runs of each; the first may cost at most HD_COST_BOUND times the
# second.
HD_COST_BOUND="${HD_COST_BOUND:-1.5}"
HD_COST_PY='import os, subprocess, sys, time
hook, a, b = sys.argv[1], sys.argv[2].encode(), sys.argv[3].encode()
def one(pay):
    t0 = time.time()
    subprocess.run(["/bin/bash", hook], input=pay, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
    return time.time() - t0
x, y = [], []
for _ in range(3):
    x.append(one(a)); y.append(one(b))
print("%.3f %.3f" % (min(x), min(y)))'
hd_cost_out="$(/usr/bin/python3 -c "$HD_COST_PY" "$HOOK" "$(bash_payload "$HD_CAP_IN")" "$(bash_payload "$(hd_pad 5)"$'\ncat /dev/null')" 2>/dev/null)" || hd_cost_out=""
hd_cost_h="${hd_cost_out% *}"; hd_cost_c="${hd_cost_out#* }"
if [ -n "$hd_cost_out" ] && /usr/bin/awk -v h="$hd_cost_h" -v c="$hd_cost_c" -v b="$HD_COST_BOUND" 'BEGIN { exit !(c > 0 && h <= b * c) }'; then
  /usr/bin/printf 'PASS: %s\n' "HDATA-COST: at the cap the hook costs within ${HD_COST_BOUND} times the same command with no here-document"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "HDATA-COST: at the cap the hook costs at most ${HD_COST_BOUND} times the same command with no here-document" \
    "measured (seconds, with / without): ${hd_cost_out:-not measured}"; FAIL=$((FAIL + 1))
fi

# The git receiver (#7644 Q5). While the whole-line git exit (M-TRASH-GITEXEMPT) exists it allows
# every git-headed line, so these arms run through a copy of the hook whose exit line can never
# fire, shown live first (one line from the hook, and it parses). Once that exit is gone the arms
# run on the hook itself.
hd_dir="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rmt-hd.XXXXXX" 2>/dev/null)" || hd_dir=""
hd_git_hook="$HOOK"
if [ -z "$hd_dir" ]; then
  /usr/bin/printf 'FAIL: HDATA-GIT the arms could not create a sandbox, so they did not run\n'; FAIL=$((FAIL + 1))
else
  /bin/mkdir -p "${hd_dir}/lib"
  /bin/cp "${HOOK_DIR}/lib/dep-resolve.sh" "${HOOK_DIR}/lib/command-position.awk" "${hd_dir}/lib/"
  if /usr/bin/grep -q '# M-TRASH-GITEXEMPT$' "$HOOK"; then
    /usr/bin/sed -e 's/^if exit_matches \(.*# M-TRASH-GITEXEMPT\)$/if false \&\& exit_matches \1/' \
      "$HOOK" > "${hd_dir}/block-rm-prefer-trash-nogit.sh"
    hd_git_hook="${hd_dir}/block-rm-prefer-trash-nogit.sh"
    if ra_live "$hd_git_hook"; then
      /usr/bin/printf 'PASS: %s\n' "HDATA-GIT-LIVE: the copy without the whole-line git exit differs from the hook by that one line and parses"; PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s\n' "HDATA-GIT-LIVE: the copy without the whole-line git exit is not live"; FAIL=$((FAIL + 1))
    fi
  else
    /usr/bin/printf 'PASS: %s\n' "HDATA-GIT-LIVE: the hook carries no whole-line git exit, so the git arms run on the hook itself"; PASS=$((PASS + 1))
  fi
  hd_hook_saved="$HOOK"; HOOK="$hd_git_hook"
  test_case "HDATA-GIT-A: git commit reading its message from stdin; a body deletion line is data" \
    "$(bash_payload $'git commit -F - <<\'EOF\'\nrm -rf /tmp/hd-ga\nEOF')" 0
  test_case "HDATA-GIT-B: git -C <dir> commit reading its message from stdin is data" \
    "$(bash_payload $'git -C /tmp/hd-repo commit -F - <<\'EOF\'\nrm -rf /tmp/hd-gb\nEOF')" 0
  test_case "HDATA-GIT-C: git tag reading its message from stdin is data" \
    "$(bash_payload $'git tag -a v0 -F - <<\'EOF\'\nrm -rf /tmp/hd-gc\nEOF')" 0
  test_case "HDATA-GIT-D: git with a -c option is not a listed receiver and stays judged" \
    "$(bash_payload $'git -c core.editor=true commit -F - <<\'EOF\'\nrm -rf /tmp/hd-gd\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-E: git with two -C pairs is not a listed receiver and stays judged" \
    "$(bash_payload $'git -C /tmp/a -C /tmp/b commit -F - <<\'EOF\'\nrm -rf /tmp/hd-ge\nEOF')" 2 "BLOCK-TRASH-001"
  # git's edit option. With it, git opens the message in an editor, and an editor named earlier on
  # the line can be a program that runs the message file, which is the body. A git receiver whose
  # words after its subcommand carry that option in any spelling git accepts (short, long, a unique
  # prefix of the long form, a bundled short cluster, quoted; before or after the operator), or a
  # word an expansion could turn into it, is not a listed receiver, and the body stays judged.
  HD_GIT_EDIT_A=$'git commit -e -F - <<\'EOF\'\nrm -rf /tmp/hd-gea\nEOF'
  HD_GIT_EDIT_C=$'git commit -F - <<\'EOF\' --edit\nrm -rf /tmp/hd-gec\nEOF'
  HD_GIT_EDIT_D=$'git commit -se -F - <<\'EOF\'\nrm -rf /tmp/hd-ged\nEOF'
  HD_GIT_EDIT_J=$'git commit -F - $(printf %s x) <<\'EOF\'\nrm -rf /tmp/hd-gej\nEOF'
  test_case "HDATA-GIT-EDIT-A: git commit with the short edit option is not a listed receiver and stays judged" \
    "$(bash_payload "$HD_GIT_EDIT_A")" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-B: git commit with the long edit option stays judged" \
    "$(bash_payload $'git commit -F - --edit <<\'EOF\'\nrm -rf /tmp/hd-geb\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-C: the edit option after the operator stays judged" \
    "$(bash_payload "$HD_GIT_EDIT_C")" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-D: the edit option in a bundled short cluster stays judged" \
    "$(bash_payload "$HD_GIT_EDIT_D")" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-E: a unique prefix of the long edit option stays judged" \
    "$(bash_payload $'git commit --edi -F - <<\'EOF\'\nrm -rf /tmp/hd-gee\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-F: a quoted edit option stays judged" \
    "$(bash_payload $'git commit "-e" -F - <<\'EOF\'\nrm -rf /tmp/hd-gef\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-G: git tag with the edit option stays judged" \
    "$(bash_payload $'git tag -a v0 -e -F - <<\'EOF\'\nrm -rf /tmp/hd-geg\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-H: git -C <dir> commit with the edit option stays judged" \
    "$(bash_payload $'git -C /tmp/hd-repo commit -e -F - <<\'EOF\'\nrm -rf /tmp/hd-geh\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-I: a variable after the subcommand, which can expand to the edit option, stays judged" \
    "$(bash_payload $'git commit -F - $GIT_OPTS <<\'EOF\'\nrm -rf /tmp/hd-gei\nEOF')" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-EDIT-J: a command substitution after the subcommand stays judged" \
    "$(bash_payload "$HD_GIT_EDIT_J")" 2 "BLOCK-TRASH-001"
  test_case "HDATA-GIT-NOEDIT: git commit with the option that turns editing off is data" \
    "$(bash_payload $'git commit --no-edit -F - <<\'EOF\'\nrm -rf /tmp/hd-gne\nEOF')" 0
  test_case "HDATA-GIT-SIGNOFF: a short option without the edit letter is data" \
    "$(bash_payload $'git commit -s -F - <<\'EOF\'\nrm -rf /tmp/hd-gso\nEOF')" 0
  # The edit decline shown load-bearing: a copy of the git arms' hook without it allows its sentinels.
  /usr/bin/sed -e 's/^\([[:space:]]*\)if (gitrx \&\& git_edit(cur\[0\])) bail = 1  # M-HD-EDIT$/\1# M-HD-EDIT (removed)/' \
    "$hd_git_hook" > "${hd_dir}/block-rm-prefer-trash-edit.sh"
  ra_pair "HDATA-MUT-EDIT-A:" "${hd_dir}/block-rm-prefer-trash-edit.sh" "$HD_GIT_EDIT_A"
  ra_pair "HDATA-MUT-EDIT-C:" "${hd_dir}/block-rm-prefer-trash-edit.sh" "$HD_GIT_EDIT_C"
  ra_pair "HDATA-MUT-EDIT-D:" "${hd_dir}/block-rm-prefer-trash-edit.sh" "$HD_GIT_EDIT_D"
  ra_pair "HDATA-MUT-EDIT-J:" "${hd_dir}/block-rm-prefer-trash-edit.sh" "$HD_GIT_EDIT_J"
  HOOK="$hd_hook_saved"

  # The mutant pairs. Each copy differs from the hook by exactly its marked line of HEREDOC_DATA_AWK,
  # shown live first; each sentinel, refused through the hook, is allowed through its copy, so the
  # decline it removes is what holds the sentinel's refusal.
  /usr/bin/sed -e 's/^\([[:space:]]*\)if (j > k) return 0  # M-HD-RECV$/\1return 1  # M-HD-RECV/' \
    "$HOOK" > "${hd_dir}/block-rm-prefer-trash-recv.sh"
  /usr/bin/sed -e 's/ || risky \(.*# M-HD-RISKY\)$/ \1/' \
    "$HOOK" > "${hd_dir}/block-rm-prefer-trash-risky.sh"
  /usr/bin/sed -e 's/^\([[:space:]]*\)if (d != 0) { bail = 1; break }  # M-HD-ENCL$/\1# M-HD-ENCL (removed)/' \
    "$HOOK" > "${hd_dir}/block-rm-prefer-trash-encl.sh"
  /usr/bin/sed -e 's/^\([[:space:]]*\)if (!quoted) { bail = 1; break }  # M-HD-QUOTED$/\1# M-HD-QUOTED (removed)/' \
    "$HOOK" > "${hd_dir}/block-rm-prefer-trash-quoted.sh"
  ra_pair "HDATA-MUT-RECV-SHELL:" "${hd_dir}/block-rm-prefer-trash-recv.sh" "$HD_RX_SHELL"
  ra_pair "HDATA-MUT-RECV-PYC:" "${hd_dir}/block-rm-prefer-trash-recv.sh" "$HD_RX_PYC"
  ra_pair "HDATA-MUT-RECV-PATHQ:" "${hd_dir}/block-rm-prefer-trash-recv.sh" "$HD_RX_PATHQ"
  ra_pair "HDATA-MUT-RECV-OSA:" "${hd_dir}/block-rm-prefer-trash-recv.sh" "$HD_RX_OSA"
  ra_pair "HDATA-MUT-RISKY-PIPE:" "${hd_dir}/block-rm-prefer-trash-risky.sh" "$HD_RX_PIPE"
  ra_pair "HDATA-MUT-RISKY-FUNC:" "${hd_dir}/block-rm-prefer-trash-risky.sh" "$HD_RX_FUNC"
  ra_pair "HDATA-MUT-RISKY-FUNC2:" "${hd_dir}/block-rm-prefer-trash-risky.sh" "$HD_RX_FUNC2"
  ra_pair "HDATA-MUT-RISKY-ZFUNCS:" "${hd_dir}/block-rm-prefer-trash-risky.sh" "$HD_RX_ZFUNCS"
  ra_pair "HDATA-MUT-RISKY-ZCOMMANDS:" "${hd_dir}/block-rm-prefer-trash-risky.sh" "$HD_RX_ZCOMMANDS"
  ra_pair "HDATA-MUT-ENCL-A:" "${hd_dir}/block-rm-prefer-trash-encl.sh" "$HD_ENCL_A"
  ra_pair "HDATA-MUT-ENCL-B:" "${hd_dir}/block-rm-prefer-trash-encl.sh" "$HD_ENCL_B"
  ra_pair "HDATA-MUT-ENCL-C:" "${hd_dir}/block-rm-prefer-trash-encl.sh" "$HD_ENCL_C"
  ra_pair "HDATA-MUT-ENCL-EVAL:" "${hd_dir}/block-rm-prefer-trash-encl.sh" "$HD_RX_EVAL"
  ra_pair "HDATA-MUT-QUOTED-A:" "${hd_dir}/block-rm-prefer-trash-quoted.sh" "$HD_AC3_A"
  ra_pair "HDATA-MUT-QUOTED-B:" "${hd_dir}/block-rm-prefer-trash-quoted.sh" "$HD_AC3_B"
  case "${hd_dir##*/}" in rmt-hd.*) /bin/rm -rf "$hd_dir" ;; esac
fi

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
