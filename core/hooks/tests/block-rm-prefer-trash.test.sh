#!/bin/bash
# tests/block-rm-prefer-trash.test.sh — synthetic Bash-tool payload tests
# for block-rm-prefer-trash.sh. Covers BLOCK-TRASH-001..003 ACs, the
# auto-memory Trash arm (MEM-*), CLAUDE_HOOK_BYPASS bypass + edge/regression cases.
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
# one is allowed. The hook spells its default workspace root from HOME as written and
# canonicalizes the target, so the premise holds only while HOME is itself a canonical
# path. A caller that points HOME at a `mktemp -d` directory, as the install regression's
# HOME-override step does, hands the hook a HOME under the per-user temp area, which
# macOS reaches through the /var -> /private/var symlink: the target resolves to the
# /private form, the root keeps the form HOME spelled, and every inside target reads as
# outside. The arm then fails on a property of the caller, not of the rule it tests. The
# hook's comparison is its own behaviour and is not changed here.
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

# ----- MEMORY-STORE ARM: auto-memory entry eviction (MEM-*) -----
#
# Every MEM case runs the hook with HOME pointed at a throwaway sandbox (the
# block-autonomy-ceiling.test.sh idiom) and CLAUDE_PROJECT_DIR cleared, unless a case sets
# it, so neither the operator's real settings and store nor a caller's project is read.
# Fixture names avoid the operator-memory-reference gate's patterns. MEM_ROOT is
# canonicalized at creation: the hook compares a canonicalized target with a root spelled
# from HOME as written (see HOME-FIXTURE-01), so a sandbox reached through a symlink would
# misread in-workspace targets, and MEM-23 would test that instead of the arm.
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

  case "${MEM_ROOT##*/}" in
    rmt-mem.*) /bin/rm -rf "$MEM_ROOT" ;;
  esac
fi

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
