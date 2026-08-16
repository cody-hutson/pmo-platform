#!/bin/bash
# tests/block-destructive.test.sh — synthetic PreToolUse payload tests for block-destructive.sh
#
# Covers: NEW-A acceptance criteria (12 core scenarios) + regression cases + edge cases.
# Runs standalone: bash .claude/hooks/tests/block-destructive.test.sh

# Note: no `set -e` — we expect and assert on hook failures (exit 2)
set -u

HOOK="$(cd "$(dirname "$0")/.." && pwd -P)/block-destructive.sh"
if [ ! -x "$HOOK" ]; then
  echo "FAIL: hook not executable at $HOOK" >&2
  exit 1
fi

PASS=0
FAIL=0

# Helper: run hook with given JSON payload, capture exit + stderr, compare
#   $1 = test name
#   $2 = JSON payload (on stdin)
#   $3 = expected exit code (0 = allow, 2 = block)
#   $4 = (optional) regex pattern that must appear in stderr
test_case() {
  local name="$1"
  local payload="$2"
  local expected_exit="$3"
  local expected_pattern="${4:-}"

  local tmp_stderr
  tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  local actual_stderr
  actual_stderr="$(/bin/cat "$tmp_stderr")"
  /bin/rm -f "$tmp_stderr"

  local ok=1
  if [ "$actual_exit" != "$expected_exit" ]; then
    ok=0
  fi
  if [ -n "$expected_pattern" ] && ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "$expected_pattern"; then
    ok=0
  fi

  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  expected_exit=%s actual_exit=%s\n  stderr: %s\n' "$name" "$expected_exit" "$actual_exit" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

# Helper: build a Bash tool JSON payload
bash_payload() {
  local cmd="$1"
  local cwd="${2:-$HOME/Claude/.claude/worktrees/test}"
  /usr/bin/jq -n --arg cmd "$cmd" --arg cwd "$cwd" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}'
}

echo "================================"
echo "block-destructive.sh tests (NEW-A)"
echo "================================"

# --- AC-001: git push --force origin main → block ---
test_case "AC-001: git push --force origin main blocks" \
  "$(bash_payload 'git push --force origin main')" \
  2 "BLOCK-DESTRUCTIVE-001"

# --- AC-002: git push --force-with-lease origin feature/foo → allow ---
test_case "AC-002: git push --force-with-lease allows" \
  "$(bash_payload 'git push --force-with-lease origin feature/foo')" \
  0

# --- AC-003: --force-with-lease + unrelated rm --force junk → no false unblock ---
test_case "AC-003: force-with-lease + rm --force (no false unblock)" \
  "$(bash_payload 'git push --force-with-lease origin main && rm --force /tmp/junk')" \
  0

# --- AC-003b: --force-with-lease with trailing noise → still allow ---
test_case "AC-003b: force-with-lease with embedded --force-with-lease noise" \
  "$(bash_payload 'echo about --force-with-lease; git push --force-with-lease origin main')" \
  0

# --- Regression: git push --force with additional flags before force ---
test_case "AC-001b: git push --dry-run --force blocks (flags before force)" \
  "$(bash_payload 'git push --dry-run --force origin main')" \
  2 "BLOCK-DESTRUCTIVE-001"

# --- Regression: -f short form ---
test_case "AC-001c: git push -f origin main blocks (-f short form)" \
  "$(bash_payload 'git push -f origin main')" \
  2 "BLOCK-DESTRUCTIVE-001"

# --- Regression: --force-if-includes (newer safe variant) ---
test_case "AC-001d: --force-if-includes allowed (safe variant)" \
  "$(bash_payload 'git push --force-if-includes origin main')" \
  0

# --- git reset --hard → block ---
test_case "reset --hard blocks" \
  "$(bash_payload 'git reset --hard HEAD~1')" \
  2 "BLOCK-DESTRUCTIVE-002"

# --- git reset (soft) → allow ---
test_case "git reset (soft) allows" \
  "$(bash_payload 'git reset HEAD~1')" \
  0

# --- git clean -f → block ---
test_case "git clean -f blocks" \
  "$(bash_payload 'git clean -fd')" \
  2 "BLOCK-DESTRUCTIVE-003"

# --- git clean -n (dry run) → allow ---
test_case "git clean -n allows (dry run)" \
  "$(bash_payload 'git clean -n')" \
  0

# --- AC-004: rm -rf / → block ---
test_case "AC-004: rm -rf / blocks" \
  "$(bash_payload 'rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- AC-005: rm -rf /tmp/build → allow ---
test_case "AC-005: rm -rf /tmp/build allows" \
  "$(bash_payload 'rm -rf /tmp/build')" \
  0

# --- AC-006: rm -rf -- / → block ---
test_case "AC-006: rm -rf -- / blocks" \
  "$(bash_payload 'rm -rf -- /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- AC-006b: rm --recursive --force / → block ---
test_case "AC-006b: rm --recursive --force / blocks" \
  "$(bash_payload 'rm --recursive --force /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- AC-006c: rm --no-preserve-root -rf / → block ---
test_case "AC-006c: rm --no-preserve-root -rf / blocks" \
  "$(bash_payload 'rm --no-preserve-root -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- /Users subdirs — block at /Users bare, allow deeper ---
test_case "rm -rf /Users blocks (catastrophic)" \
  "$(bash_payload 'rm -rf /Users')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "rm -rf /Users/testuser/safe-project allows (specific subpath)" \
  "$(bash_payload 'rm -rf /Users/testuser/safe-project')" \
  0

# --- /etc — block bare, allow deeper ---
test_case "rm -rf /etc blocks" \
  "$(bash_payload 'rm -rf /etc')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "rm -rf /etc/myapp-config allows (specific file)" \
  "$(bash_payload 'rm -rf /etc/myapp-config')" \
  0

# --- AC-007: rm -rf $HOME literal → block ---
test_case "AC-007: rm -rf \$HOME literal blocks" \
  "$(bash_payload 'rm -rf $HOME')" \
  2 "BLOCK-DESTRUCTIVE-005"

# --- rm -rf $HOME/specific → allow (just the subdirectory) ---
test_case "rm -rf \$HOME/specific allows (specific subpath — actually the literal)" \
  "$(bash_payload 'rm -rf $HOME/Downloads/temp')" \
  0

# --- Preserved rules ---
test_case "rm -rf .git blocks" \
  "$(bash_payload 'rm -rf .git')" \
  2 "BLOCK-DESTRUCTIVE-006"

# repo-integrity: allow-projects-casing — the BLOCK-DESTRUCTIVE-007 fixture below
# intentionally uses the legacy-uppercase Projects/ literal; file-exempt from the
# net-new Projects/ casing gate.
test_case "rm -rf Projects/ blocks" \
  "$(bash_payload 'rm -rf Projects/')" \
  2 "BLOCK-DESTRUCTIVE-007"

test_case "rm -rf projects/ blocks (lowercase Layer 2)" \
  "$(bash_payload 'rm -rf projects/')" \
  2 "BLOCK-DESTRUCTIVE-008"

test_case "rm -rf pmo-platform/ blocks" \
  "$(bash_payload 'rm -rf pmo-platform/')" \
  2 "BLOCK-DESTRUCTIVE-009"

# --- Legitimate ops → allow ---
test_case "git status allows" \
  "$(bash_payload 'git status')" \
  0

test_case "git push origin main (no --force) allows" \
  "$(bash_payload 'git push origin main')" \
  0

test_case "git push origin feature/my-branch allows" \
  "$(bash_payload 'git push origin feature/my-branch')" \
  0

test_case "ls -la allows" \
  "$(bash_payload 'ls -la')" \
  0

# --- Non-Bash tool → early exit 0 ---
test_case "Write tool early-exit (non-Bash)" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/foo.txt","content":"hello"},"cwd":"/tmp"}' \
  0

test_case "Read tool early-exit (non-Bash)" \
  '{"tool_name":"Read","tool_input":{"file_path":"/etc/passwd"},"cwd":"/tmp"}' \
  0

# --- Edge cases: chaining with ; && || | ---
test_case "echo ok; rm -rf / (after semicolon) blocks" \
  "$(bash_payload 'echo ok; rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "true && rm -rf / blocks" \
  "$(bash_payload 'true && rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "false || rm -rf / blocks" \
  "$(bash_payload 'false || rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "echo foo | rm -rf / blocks" \
  "$(bash_payload 'echo foo | rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- Edge cases: newlines in command (printf preservation) ---
test_case "multiline command with rm -rf / embedded blocks" \
  "$(bash_payload $'echo ok\nrm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- Edge cases: leading whitespace ---
test_case "leading-spaces rm -rf / blocks" \
  "$(bash_payload '   rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "tab-separated rm -rf / blocks" \
  "$(bash_payload $'rm\t-rf\t/')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- Invalid JSON → fail-CLOSED ---
test_case "malformed JSON → exit 2 (fail-closed)" \
  'this is not json' \
  2 "INPUT-INVALID"

# --- Empty command → allow ---
test_case "empty command → allow" \
  '{"tool_name":"Bash","tool_input":{"command":""},"cwd":"/tmp"}' \
  0

# ==========================================================================
# NEW-B: git plumbing coverage
# ==========================================================================

echo ""
echo "NEW-B: git plumbing coverage"
echo "---"

test_case "git update-ref on main blocks" \
  "$(bash_payload 'git update-ref refs/heads/main abc123')" \
  2 "BLOCK-DESTRUCTIVE-010"

test_case "git update-ref on HEAD blocks" \
  "$(bash_payload 'git update-ref HEAD abc123')" \
  2 "BLOCK-DESTRUCTIVE-010"

test_case "git update-ref on feature branch allows" \
  "$(bash_payload 'git update-ref refs/heads/feature-foo abc123')" \
  0

test_case "git symbolic-ref HEAD refs/heads/main blocks" \
  "$(bash_payload 'git symbolic-ref HEAD refs/heads/main')" \
  2 "BLOCK-DESTRUCTIVE-011"

test_case "git symbolic-ref HEAD refs/heads/feature allows" \
  "$(bash_payload 'git symbolic-ref HEAD refs/heads/feature-foo')" \
  0

test_case "git push origin +main blocks (plus-refspec)" \
  "$(bash_payload 'git push origin +main')" \
  2 "BLOCK-DESTRUCTIVE-012"

test_case "git push origin +refs/heads/main:refs/heads/main blocks" \
  "$(bash_payload 'git push origin +refs/heads/main:refs/heads/main')" \
  2 "BLOCK-DESTRUCTIVE-012"

test_case "git push origin main (no plus) allows" \
  "$(bash_payload 'git push origin main')" \
  0

test_case "git push origin +feature-foo allows (not main/master)" \
  "$(bash_payload 'git push origin +feature-foo')" \
  0

test_case "git reflog expire blocks" \
  "$(bash_payload 'git reflog expire --expire=now --all')" \
  2 "BLOCK-DESTRUCTIVE-013"

test_case "git reflog delete blocks" \
  "$(bash_payload 'git reflog delete HEAD@{0}')" \
  2 "BLOCK-DESTRUCTIVE-013"

test_case "git reflog (show) allows" \
  "$(bash_payload 'git reflog show')" \
  0

test_case "git filter-branch blocks" \
  "$(bash_payload 'git filter-branch --env-filter \"echo ok\" HEAD')" \
  2 "BLOCK-DESTRUCTIVE-014"

test_case "git filter-repo blocks" \
  "$(bash_payload 'git filter-repo --path foo --invert-paths')" \
  2 "BLOCK-DESTRUCTIVE-015"

# ==========================================================================
# NEW-B: tamper resistance (PATH / alias / function)
# ==========================================================================

echo ""
echo "NEW-B: tamper resistance"
echo "---"

test_case "PATH=/tmp:\$PATH grep blocks" \
  "$(bash_payload 'PATH=/tmp:$PATH grep foo bar')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "export PATH=/tmp blocks" \
  "$(bash_payload 'export PATH=/tmp')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "unset PATH blocks" \
  "$(bash_payload 'unset PATH')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "alias grep='echo ok' blocks" \
  "$(bash_payload 'alias grep='\''echo ok'\''')" \
  2 "BLOCK-DESTRUCTIVE-021"

test_case "alias jq='cat' blocks" \
  "$(bash_payload 'alias jq='\''cat'\''')" \
  2 "BLOCK-DESTRUCTIVE-021"

test_case "function grep() { echo ok; } blocks" \
  "$(bash_payload 'function grep() { echo ok; }')" \
  2 "BLOCK-DESTRUCTIVE-021"

test_case "alias ll='ls -la' allows (non-critical tool)" \
  "$(bash_payload 'alias ll='\''ls -la'\''')" \
  0

# ==========================================================================
# NEW-B: subprocess script ban
# ==========================================================================

echo ""
echo "NEW-B: subprocess script ban"
echo "---"

test_case "bash /tmp/attacker.sh blocks (not allowlisted)" \
  "$(bash_payload 'bash /tmp/attacker.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "sh /tmp/evil.sh blocks" \
  "$(bash_payload 'sh /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# The deploy script lives at core/deploy/deploy.sh post-modular-monolith (there
# is no top-level $HOME/Claude/deploy.sh shim). The script-execution-allowlist
# carries the token-free relative forms `core/deploy/deploy.sh` and
# `./core/deploy/deploy.sh` verbatim, so these allow-cases match in both the
# source tree (literal-token allowlist) and the CI-resolved sandbox.
test_case "bash core/deploy/deploy.sh allows (allowlisted)" \
  "$(bash_payload 'bash core/deploy/deploy.sh')" \
  0

test_case "./core/deploy/deploy.sh allows (allowlisted)" \
  "$(bash_payload './core/deploy/deploy.sh --check')" \
  0

test_case "bash -c 'echo ok' allows (no script path)" \
  "$(bash_payload 'bash -c "echo ok"')" \
  0

# --------------------------------------------------------------------------
# BLOCK-022: release/tools/tests/ suite registration
#
# The eight shell suites in release/tools/tests/ are registered in the
# script-execution allowlist so the agent asked to dev-test one can actually
# run it. These cases assert the GUARD'S VERDICT against the token-resolved
# deployed allowlist -- they never run a suite and never assert a suite's own
# exit status.
#
# WHY A MUST-FLAG CONTROL IS MANDATORY HERE: the 11 must-not-flag cases below
# are all "allows" assertions, and an allows-only fixture cannot tell a correct
# allowlist apart from one that permits everything. Measured: widen the allowlist
# to `*`, or stub the hook to `exit 0`, and all 11 stay green while this control
# is the ONLY case in this block that turns red (11/11 green + control red, on
# both arms). A guard that has stopped guarding is the vacuity this control exists
# to catch, and it is the direction no "allows" case can report by construction.
#
# The OPPOSITE direction needs no control, so this comment does not claim one: if
# the allowlist fails to load, is_script_allowlisted returns 1 for every path, so
# everything blocks and the must-not-flag cases go red together (measured: 11/11
# red, this control still green). A load failure is already loud.
#
# The control is also the anti-broadening arm: it is a sibling in the SAME
# directory, in the SAME invocation shape, differing ONLY in allowlist
# membership, so a wildcard directory glob would permit it and fail this case.
# Its path must NOT exist on disk -- registration is a path-pattern match, not a
# file-existence check, so a non-existent name can never be accidentally
# satisfied by a future suite.
#
# FORM COVERAGE, and the substrate boundary that bounds it. The allowlist
# registers each suite in four forms; two of them are prefixed with the
# [PMO_PLATFORM_ROOT] token. setup-ci-layout.sh (which materializes the
# deployed posture these cases run against) resolves [CLAUDE_WORKSPACE_ROOT],
# [OPERATOR_HOMEDIR_PATH] and [OPERATOR_GITHUB] only -- it does NOT resolve
# [PMO_PLATFORM_ROOT], which core/deploy/compose.py resolves at real deploy
# time. Unresolved, "[PMO_PLATFORM_ROOT]" is a shell `case` BRACKET EXPRESSION
# matching one character, so no command path can match those two patterns on
# this substrate and neither token-prefixed form is exercisable here. The three
# form-coverage cases therefore pin the two token-free registered forms and the
# detector's interpreter arms, which is the whole of what this substrate can
# assert. The token-form gap is a fidelity limitation of the CI layout helper,
# not of the registration.
# --------------------------------------------------------------------------

echo ""
echo "BLOCK-022: release/tools/tests/ suite registration"
echo "---"

# must-not-flag -- one per suite, bare-relative form (allowlist form 4).
test_case "BLOCK-022 suite: test_action_item_gate_predicate.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_action_item_gate_predicate.sh')" \
  0

test_case "BLOCK-022 suite: test_corpus_home_tolerance.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_corpus_home_tolerance.sh')" \
  0

test_case "BLOCK-022 suite: test_deciders_carveout.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_deciders_carveout.sh')" \
  0

test_case "BLOCK-022 suite: test_domain_blast_radius.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_domain_blast_radius.sh')" \
  0

test_case "BLOCK-022 suite: test_lint_release_corpus_versionless.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_lint_release_corpus_versionless.sh')" \
  0

test_case "BLOCK-022 suite: test_renumber_adr.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_renumber_adr.sh')" \
  0

test_case "BLOCK-022 suite: test_structural_blast_radius.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_structural_blast_radius.sh')" \
  0

test_case "BLOCK-022 suite: test_verify_release_plan.sh allows (registered)" \
  "$(bash_payload 'bash release/tools/tests/test_verify_release_plan.sh')" \
  0

# must-not-flag, form coverage -- one representative suite, three invocation
# shapes: the ./ relative form, the bare form through a second interpreter, and
# the bare form behind an absolute interpreter path (the ANCHOR_PREFIX_BASH arm).
test_case "BLOCK-022 form: ./ relative form allows (allowlist form 3)" \
  "$(bash_payload 'bash ./release/tools/tests/test_verify_release_plan.sh')" \
  0

test_case "BLOCK-022 form: sh <suite> allows (bare form, sh interpreter)" \
  "$(bash_payload 'sh release/tools/tests/test_verify_release_plan.sh')" \
  0

test_case "BLOCK-022 form: /bin/bash ./<suite> allows (absolute-interpreter prefix)" \
  "$(bash_payload '/bin/bash ./release/tools/tests/test_verify_release_plan.sh')" \
  0

# must-flag control (MANDATORY) -- an unregistered sibling in the same
# directory. This is what makes the 11 must-not-flag cases above falsifiable.
# The path must never be created on disk.
test_case "BLOCK-022 control: unregistered sibling in the same directory blocks" \
  "$(bash_payload 'bash release/tools/tests/zz_unregistered_control.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# --------------------------------------------------------------------------
# BLOCK-022 target resolution
#
# The matcher must adjudicate the script the interpreter EXECUTES, and must not
# fall through to allow on quoting or on separator adjacency. Four defects are
# covered here, three of which were fail-OPEN:
#
#   A  a .sh passed as an ARGUMENT was adjudicated instead of the executed
#      script (`tail -1` took the last .sh token) — a false BLOCK that made
#      the Stage-5-mandated blast-radius.sh unusable.
#   B  a .sh immediately followed by `;` matched nothing, because `\b` is not
#      honored inside an alternation by BSD grep — fail-OPEN.
#   C  only the FIRST invocation on a command line was evaluated — fail-OPEN.
#   D  a quoted path did not end in `.sh`, so it matched nothing — fail-OPEN.
#
# Plus the unresolvable-path (variable-bearing) case, which must fail CLOSED.
#
# WHY EACH ARM CARRIES A CONTROL: same reason as the registration block above —
# an allows-only fixture cannot tell a correct matcher from one that permits
# everything, and a blocks-only fixture cannot tell a correct matcher from one
# that permits nothing. Defect A is a false-block and defects B/C/D are
# false-allows, so BOTH directions have to be pinned or a fix in one direction
# can silently regress the other. Measured: reverting the matcher turns the
# A-arm red; widening the allowlist to `*` turns the B/C/D controls red.
# --------------------------------------------------------------------------

echo ""
echo "BLOCK-022 target resolution"
echo "---"

# --- Defect A: a script path passed as an ARGUMENT ---
test_case "BLOCK-022 argform: allowlisted tool with a .sh ARGUMENT allows" \
  "$(bash_payload 'bash release/tools/blast-radius.sh update.sh')" \
  0

test_case "BLOCK-022 argform: allowlisted tool with an allowlisted .sh argument allows" \
  "$(bash_payload 'bash release/tools/blast-radius.sh core/deploy/deploy.sh')" \
  0

# must-flag control -- the EXECUTED script is adjudicated, so a non-allowlisted
# tool blocks even when the argument it is handed IS allowlisted. This is the
# case that fails if the target selection ever inverts again.
test_case "BLOCK-022 argform control: non-allowlisted tool with allowlisted argument blocks" \
  "$(bash_payload 'bash release/tools/zz_unregistered_control.sh core/deploy/deploy.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# --- Defect B: separator adjacency ---
test_case "BLOCK-022 sep: non-allowlisted script followed by ';' blocks" \
  "$(bash_payload 'bash /tmp/evil.sh; echo done')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 sep control: allowlisted script followed by ';' allows" \
  "$(bash_payload 'bash core/deploy/deploy.sh; echo done')" \
  0

# --- Defect C: every invocation is evaluated, not only the first ---
test_case "BLOCK-022 chain: ';' laundering behind an allowlisted first command blocks" \
  "$(bash_payload 'bash core/deploy/deploy.sh; bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 chain: '&&' laundering blocks" \
  "$(bash_payload 'bash core/deploy/deploy.sh && bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 chain: '|' laundering blocks" \
  "$(bash_payload 'bash core/deploy/deploy.sh | bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# must-not-flag control -- chaining itself is not what blocks; two allowlisted
# commands chained still allow.
test_case "BLOCK-022 chain control: two allowlisted commands chained allow" \
  "$(bash_payload 'bash core/deploy/deploy.sh && bash release/tools/blast-radius.sh')" \
  0

# --- Defect D: quoted path ---
test_case "BLOCK-022 quote: double-quoted non-allowlisted path blocks" \
  "$(bash_payload 'bash "/tmp/evil.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 quote: single-quoted non-allowlisted path blocks" \
  "$(bash_payload "bash '/tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 quote: -c with a quoted non-allowlisted path blocks" \
  "$(bash_payload 'bash -c "/tmp/evil.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# must-not-flag control -- quote-stripping must not break the ALLOW path.
test_case "BLOCK-022 quote control: double-quoted allowlisted path allows" \
  "$(bash_payload 'bash "core/deploy/deploy.sh"')" \
  0

# --- Unresolvable (variable-bearing) path must fail CLOSED ---
# The hook sees unexpanded argv and cannot resolve the path to an allowlist
# entry, so it denies rather than guessing -- the same posture as the
# dependency gate.
test_case "BLOCK-022 var: variable-bearing script path blocks (fail-closed)" \
  "$(bash_payload 'bash "$W/not-allowlisted.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# must-not-flag control -- a quoted LITERAL path still allows, so the case
# above is the unresolvable variable and not the quoting.
test_case "BLOCK-022 var control: quoted literal allowlisted path allows" \
  "$(bash_payload 'bash "release/tools/blast-radius.sh"')" \
  0

# --- flag walking must still reach the operand ---
test_case "BLOCK-022 flags: -x before an allowlisted script allows" \
  "$(bash_payload 'bash -x core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 flags control: -x before a non-allowlisted script blocks" \
  "$(bash_payload 'bash -x /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ==========================================================================
# BLOCK-022 source/. arm — folded into the single segment matcher
# ==========================================================================
#
# Before this block existed, the source/. arm had exactly ONE case anywhere in
# the suite (AC-AP-022b, a must-flag) and ZERO must-not-flag controls. Every
# ALLOW claim for the arm was therefore unfalsifiable: a change that converted
# every sourced path into a denial would have kept the suite green.
#
# Every must-flag case below is paired with a must-not-flag control in the SAME
# spelling, so a tightening that breaks the allow path turns the suite red
# exactly as a fail-open does.

echo ""
echo "BLOCK-022 source/. arm"
echo "---"

# --- quoting: the arm used to keep the quotes, match no filter pattern, and
# fall through to ALLOW without the allowlist ever being consulted ---
test_case "BLOCK-022 source quote: double-quoted non-allowlisted path blocks" \
  "$(bash_payload 'source "/tmp/evil.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source quote: single-quoted non-allowlisted path blocks" \
  "$(bash_payload "source '/tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 dot quote: double-quoted non-allowlisted path blocks" \
  "$(bash_payload '. "/tmp/evil.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 dot quote: single-quoted non-allowlisted path blocks" \
  "$(bash_payload ". '/tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# must-not-flag controls. The bare form allowed before this change AND after;
# the quoted forms allowed before for the WRONG reason -- the case fell through
# ahead of the allowlist read -- and must now allow for the right one. Only
# these paired controls distinguish those two states.
test_case "BLOCK-022 source quote control: bare allowlisted path allows" \
  "$(bash_payload 'source core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 source quote control: double-quoted allowlisted path allows" \
  "$(bash_payload 'source "core/deploy/deploy.sh"')" \
  0

test_case "BLOCK-022 source quote control: single-quoted allowlisted path allows" \
  "$(bash_payload "source 'core/deploy/deploy.sh'")" \
  0

test_case "BLOCK-022 dot quote control: double-quoted allowlisted path allows" \
  "$(bash_payload '. "core/deploy/deploy.sh"')" \
  0

# --- chaining: the arm used to apply head -1 to the invocation list, so a
# second sourced file was never evaluated once the first one resolved ---
test_case "BLOCK-022 source chain: ';' laundering behind an allowlisted source blocks" \
  "$(bash_payload 'source core/deploy/deploy.sh; source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source chain: '&&' laundering blocks" \
  "$(bash_payload 'source core/deploy/deploy.sh && source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source chain: '||' laundering blocks" \
  "$(bash_payload 'source core/deploy/deploy.sh || source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source chain: '|' laundering blocks" \
  "$(bash_payload 'source core/deploy/deploy.sh | source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# must-not-flag control -- chaining itself is not what blocks.
test_case "BLOCK-022 source chain control: two allowlisted sources chained allow" \
  "$(bash_payload 'source core/deploy/deploy.sh; source ./core/deploy/deploy.sh')" \
  0

# --- the arm's own operand filter, one case per branch. These were entirely
# ungraded before: nothing exercised /*, and nothing exercised *.bash. ---
test_case "BLOCK-022 source filter: absolute non-allowlisted path blocks (/* arm)" \
  "$(bash_payload 'source /etc/profile.d/evil')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source filter: .bash suffix blocks (*.bash arm)" \
  "$(bash_payload 'source /tmp/evil.bash')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source filter: ./ relative non-allowlisted blocks (./* arm)" \
  "$(bash_payload 'source ./tmp-evil-fixture')" \
  2 "BLOCK-DESTRUCTIVE-022"

# flag walking on the source arm is strictly TIGHTER than not walking: without
# it, `-x` would be presented as the operand and the real target would evade.
test_case "BLOCK-022 source flags: -x before a non-allowlisted path blocks" \
  "$(bash_payload '. -x /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 source flags control: -x before an allowlisted path allows" \
  "$(bash_payload '. -x core/deploy/deploy.sh')" \
  0

# --- adopting check_script_target on this arm brings the variable-bearing
# fail-closed posture the rule doc already claimed for the rule as a whole ---
test_case "BLOCK-022 source var: variable-bearing sourced path blocks (fail-closed)" \
  "$(bash_payload 'source "$W/release/tools/version-grammar.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# DOCUMENTED RESIDUAL, pre-existing and preserved verbatim by the fold.
# bash performs tilde expansion on a `case` PATTERN, so the filter's `~/*` arm
# is compared as $HOME/* and never matches a LITERAL `~/...` token. A literal
# home path therefore reaches the filter only via the *.sh / *.bash arms.
# Pinned here rather than left unknown: if a later change makes these block,
# that is a deliberate widening and this assertion is where it surfaces.
test_case "BLOCK-022 source residual: literal ~/ non-script operand allows (tilde-expanded pattern)" \
  "$(bash_payload 'source ~/evil.conf')" \
  0

test_case "BLOCK-022 source residual control: ~/ operand with .sh suffix still blocks" \
  "$(bash_payload 'source ~/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ==========================================================================
# BLOCK-022 command-position invariance under assignment prefixes
# ==========================================================================
#
# The verdict must not depend on a token that does not change the operation.
# Before the command-position walk, an assignment ahead of the verb moved the
# verb off index 0 and the invocation was skipped -- in BOTH directions, so the
# gap did not fail safe. Each must-flag case is paired with the SAME prefix
# spelling over an allowlisted target.

echo ""
echo "BLOCK-022 assignment-prefix invariance"
echo "---"

test_case "BLOCK-022 prefix: VAR=v before bash, non-allowlisted, blocks" \
  "$(bash_payload 'ENVV=1 bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 prefix: two assignments before bash, non-allowlisted, blocks" \
  "$(bash_payload 'FOO=bar BAZ=qux bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 prefix: VAR=v before /bin/bash, non-allowlisted, blocks" \
  "$(bash_payload 'ENVV=1 /bin/bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 prefix: VAR=v before source, non-allowlisted, blocks" \
  "$(bash_payload 'ENVV=1 source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 prefix: VAR=v before '.', non-allowlisted, blocks" \
  "$(bash_payload 'ENVV=1 . /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# must-not-flag controls -- the SAME prefix spellings over allowlisted targets.
# Without these the prefix walk could have been implemented as "block anything
# with an assignment prefix" and the suite would still be green.
test_case "BLOCK-022 prefix control: VAR=v before bash, allowlisted, allows" \
  "$(bash_payload 'ENVV=1 bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 prefix control: two assignments before bash, allowlisted, allows" \
  "$(bash_payload 'FOO=bar BAZ=qux bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 prefix control: VAR=v before source, allowlisted, allows" \
  "$(bash_payload 'ENVV=1 source core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 prefix control: VAR=v before quoted allowlisted source allows" \
  "$(bash_payload 'ENVV=1 source "core/deploy/deploy.sh"')" \
  0

# skip-precision controls. The walk must advance past ASSIGNMENTS, not past
# "any token containing =". Both tokens below are invalid shell NAMEs, so they
# terminate the prefix run and become the command word -- which is not an
# interpreter, so nothing is adjudicated and the verdict is UNCHANGED from
# before the walk existed. If the skip ever loosens into a general
# advance-past-anything-with-an-equals, these two flip to blocking and fail.
test_case "BLOCK-022 prefix precision: invalid NAME does not advance command position" \
  "$(bash_payload 'a-b=1 bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 prefix precision: flag-shaped =-bearing token does not advance" \
  "$(bash_payload '--body=x bash /tmp/evil.sh')" \
  0

# ==========================================================================
# BLOCK-022 R5 — the pipeline's own invocation shapes must not be blocked
# ==========================================================================
#
# This rule is tightened by the same change that adds these. A tightening that
# blocks the release pipeline's own Stage 12 or Stage 13 tooling is a
# self-inflicted outage, so every shape the pipeline actually invokes is a
# first-class must-not-flag control here rather than an assumption.

echo ""
echo "BLOCK-022 R5 pipeline invocation shapes"
echo "---"

test_case "BLOCK-022 R5: deploy.sh --check allows" \
  "$(bash_payload 'bash core/deploy/deploy.sh --check')" \
  0

test_case "BLOCK-022 R5: append-pipeline-event.sh allows" \
  "$(bash_payload 'bash release/tools/append-pipeline-event.sh --stage 6')" \
  0

test_case "BLOCK-022 R5: automated-closeout.sh allows (Stage 13)" \
  "$(bash_payload 'bash release/tools/automated-closeout.sh --milestone m')" \
  0

test_case "BLOCK-022 R5: claim-version.sh allows (Stage 12)" \
  "$(bash_payload 'bash release/tools/claim-version.sh --version v0.0')" \
  0

test_case "BLOCK-022 R5: hook suite from the source tree allows" \
  "$(bash_payload 'bash core/hooks/tests/block-destructive.test.sh')" \
  0

test_case "BLOCK-022 R5: hook test runner from the source tree allows" \
  "$(bash_payload 'bash core/hooks/tests/test-runner.sh')" \
  0

test_case "BLOCK-022 R5: env-prefixed pipeline tool allows" \
  "$(bash_payload 'VAR=x bash core/deploy/deploy.sh')" \
  0

# must-flag control for the R5 block -- an unregistered sibling in the very
# directory the new allowlist rows cover still blocks, so those rows are a
# named-and-globbed permission rather than a hole in the guard.
test_case "BLOCK-022 R5 control: unregistered sibling in core/hooks/tests/ blocks" \
  "$(bash_payload 'bash core/hooks/tests/zz_unregistered_control.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ==========================================================================
# BLOCK-022 AC-FP — the verdict must not depend on non-executing text
# ==========================================================================
#
# The matcher is lexical, so a separator and an interpreter inside a QUOTED
# ARGUMENT are shredded into fragments that look like commands. The rule then
# fires on text that DESCRIBES an execution rather than performing one. This is
# not hypothetical: the class fired three times during the release that added
# these cases, across two different hooks, including once on a grep pattern.
#
# Suppression is gated on an allowlist of outer command words that cannot
# evaluate their arguments. A word MISSING from that set means a false positive
# persists -- it can never mean an evasion is admitted.
#
# HOW THIS CONTROL SET IS DERIVED, and why it is derived that way. Twice now a
# version of this block enumerated its controls from the DESIGN's own account of
# how the suppression could be wrong. Both times every control passed while a real
# evasion was live, because a design document is a list of the failures somebody
# already thought of. The first miss was a carrier PREFIX ahead of a real
# execution; the second was a command reached through ENCLOSURE (`$( )`) rather
# than through a prefix, plus `$'...'`, whose escape rules desynchronise the
# quote scan.
#
# THE DERIVATION RULE, which is the durable fix and is binding on anything added
# here. Enumerate the BASH CONSTRUCTS THAT CAN CAUSE THE SHELL TO EVALUATE TEXT,
# independently of what verb encloses them, and write a pair for each:
#
#   '...'  "..."  $'...'  $"..."  \ escaping (outside, and inside "...")
#   $( )   ` `    $(( ))  ${ }    <( )  >( )
#   heredoc << and <<-   herestring <<<
#   eval-family verbs: eval xargs env command exec nohup timeout nice stdbuf
#   interpreter -c in every spelling (-c, -xc, -cx, -o opt -c) and enclosure of it
#
# then cross that list with POSITION (outside quotes / interior to each quoting
# construct / after the run closes) and with WHO OPENED THE QUOTE (carrier,
# non-carrier, absolute-path spelling, assignment prefix, no head at all). The
# shapes below are that cross product, not a restatement of the design.
#
# THE INVARIANT UNDER TEST. A suppression may fire only when the enclosing context
# PROVABLY CANNOT cause the shell to evaluate the segment. Two conditions, both
# necessary: the command that OPENED the quote cannot evaluate its argument, AND
# the quoting construct itself performs no expansion. `bash -c '<string>'` executes
# the string, so positions inside it are command positions and no prefix in front
# may reattribute the string to the prefix; and `echo "$( ... )"` executes too,
# because the SHELL expands it before `echo` is ever reached.

echo ""
echo "BLOCK-022 AC-FP quoted-fragment suppression"
echo "---"

# AC-FP-1: the false positive itself, both arms. Nothing executes here -- gh
# cannot run its own argument -- so the verdict must be allow.
test_case "AC-FP-1a: interpreter-shaped text inside a gh --body argument allows" \
  "$(bash_payload "gh issue comment 1 --body 'note; bash /tmp/evil.sh'")" \
  0

test_case "AC-FP-1b: source-shaped text inside a gh --body argument allows" \
  "$(bash_payload "gh issue comment 1 --body 'note; source /tmp/evil.sh'")" \
  0

# (c) a quoted body reached through a DOUBLE quote, not a single one. Both quote
#     characters must open a suppressible run, or the class is only half fixed.
test_case "AC-FP-1c: interpreter-shaped text inside a double-quoted gh body allows" \
  "$(bash_payload 'gh issue comment 1 --body "note; bash /tmp/evil.sh"')" \
  0

# (d) an interior fragment whose OWN quotes balance. It is still inside the gh
#     argument, so it must be allowed; per-segment parity got this one wrong in
#     the other direction, blocking text that never executes.
test_case "AC-FP-1d: even-parity fragment inside a carrier argument allows" \
  "$(bash_payload "gh issue comment 1 --body 'a; bash \"/tmp/evil.sh\" b; c'")" \
  0

# AC-FP-2: the controls that prove no evasion was purchased. Each must STILL
# block, and each closes a different way the suppression could have been wrong.
#
# (a) a real execution after a separator in a carrier-headed command. The
#     executing segment is not inside the carrier's quote, so it is adjudicated.
test_case "AC-FP-2a control: real execution after a separator in a carrier command blocks" \
  "$(bash_payload 'gh issue view 1; bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (b) the -c path is untouched: `bash` opens the quote around its own program
#     string, and `bash` is not a carrier, so nothing inside it is suppressed.
test_case "AC-FP-2b control: bash -c program string still blocks" \
  "$(bash_payload "bash -c 'echo hi; bash /tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (c) suppression is allowlist-GATED, not universal. Identical quoted text under
#     a command word outside the carrier set must still block.
test_case "AC-FP-2c control: same quoted text under a non-carrier verb blocks" \
  "$(bash_payload "zzverb --body 'note; bash /tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (d) a carrier-headed command whose later segment is a REAL invocation outside
#     any quote is not suppressed -- a carrier appearing is not sufficient.
test_case "AC-FP-2d control: carrier-headed pipeline into a real invocation blocks" \
  "$(bash_payload "printf '%s' x | bash /tmp/evil.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (e) THE CASE THE FIRST CONTROL SET MISSED, and the reason this block was
#     rewritten. A carrier PREFIX in front of `bash -c` must not reattribute the
#     program string to the carrier. The quote belongs to whoever opened it, and
#     `bash` opened this one. Without the pair (e)+(b) the suite cannot tell a
#     closed gate from a gate that any one-token prefix re-opens.
test_case "AC-FP-2e control: carrier prefix ahead of bash -c still blocks" \
  "$(bash_payload "echo x; bash -c 'echo hi; bash /tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (f) the other half of the same miss: a carrier prefix ahead of a real execution
#     whose ARGUMENT merely contains an apostrophe. `--msg "it's here"` is
#     ordinary well-formed shell, not evidence that nothing ran.
test_case "AC-FP-2f control: carrier prefix, real execution, apostrophe in an argument blocks" \
  "$(bash_payload "echo hi && bash /tmp/evil.sh --msg \"it's here\"")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (g) the double-quoted spelling of (e). Both quote characters must be handled,
#     or the fix is only half a fix in the evasion direction too.
test_case "AC-FP-2g control: carrier prefix ahead of a double-quoted -c string blocks" \
  "$(bash_payload 'echo x; bash -c "echo hi; bash /tmp/evil.sh"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (h) a BACKSLASH-ESCAPED quote does not open a quote. Reading it as one would
#     mark everything after it as interior to a carrier's argument, which is the
#     fail-open direction.
test_case "AC-FP-2h control: escaped quote after a carrier does not open a quoted run" \
  "$(bash_payload 'echo \'"'"'; bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (i) an apostrophe INSIDE a double-quoted argument is literal and closes
#     nothing, so the quoted run really has ended by the separator.
test_case "AC-FP-2i control: apostrophe inside a double-quoted carrier argument blocks after" \
  "$(bash_payload "echo \"it's\"; bash /tmp/evil.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (j) suppression must STOP at the closing quote. Here it legitimately fires on
#     the carrier's body and the real execution after it must still block -- one
#     command exercising both directions at once.
test_case "AC-FP-2j control: real execution after a carrier's quoted body closes blocks" \
  "$(bash_payload "gh issue comment 1 --body 'note; ok'; bash /tmp/evil.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (k) membership in the carrier set is a claim that the verb cannot evaluate its
#     argument, and it is checkable. `git -c alias.x='!<cmd>' x` evaluates its
#     own quoted argument, so `git` is not a carrier -- this case fails if it is
#     ever added back.
test_case "AC-FP-2k control: git is not a carrier (git -c evaluates its argument)" \
  "$(bash_payload "git -c alias.x='!x; bash /tmp/evil.sh' foo")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (l)(m) the source/. arm reaches the same adjudicator by the same path, so it
#     needs the same pair. Sourcing executes the file in the current shell; a
#     carrier prefix must not suppress it on either spelling.
test_case "AC-FP-2l control: carrier prefix ahead of a real source blocks" \
  "$(bash_payload "echo hi && source /tmp/evil.sh --msg \"it's here\"")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "AC-FP-2m control: carrier prefix ahead of a real dot-source blocks" \
  "$(bash_payload "printf hi; . /tmp/evil.sh --msg \"it's\"")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (n) the separator itself is an axis: a pipe splits segments exactly as `;` and
#     `&` do, so the carrier prefix must not open the -c path through one either.
test_case "AC-FP-2n control: carrier piped into bash -c still blocks" \
  "$(bash_payload "gh issue view 1 | bash -c 'echo hi; bash /tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- Axis: the SHELL evaluates the enclosed text, whatever the carrier is -----
#
# Inside a double-quoted argument the shell performs command substitution before
# the carrier ever runs, so a carrier that genuinely cannot evaluate its argument
# does not have to. Each spelling of "the shell evaluates this" needs its own
# case, because they are separate constructs, not variants of one.

# (o) command substitution inside a double-quoted carrier argument.
test_case "AC-FP-2o control: command substitution inside a carrier argument blocks" \
  "$(bash_payload 'echo "$(cd /x; bash /tmp/evil.sh --f)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (p) the backtick spelling of the same thing. Two spellings, two cases.
test_case "AC-FP-2p control: backtick substitution inside a carrier argument blocks" \
  "$(bash_payload 'echo "`cd /x; bash /tmp/evil.sh --f`"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (q) the corpus-prescribed --body shape, which is the reachable one: an agent
#     that hits -022 and reaches for a command substitution must not get through.
test_case "AC-FP-2q control: command substitution inside a gh --body blocks" \
  "$(bash_payload 'gh issue comment 1 --body "$(cd /x; bash /tmp/evil.sh --f)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (r) ENCLOSURE of `bash -c`, as distinct from a PREFIX in front of it (2e). The
#     invariant covered prefixes; `$( )` wraps the whole invocation instead.
test_case "AC-FP-2r control: bash -c enclosed by a command substitution blocks" \
  "$(bash_payload 'echo "$(bash -c '"'"'cd /x; bash /tmp/evil.sh --f'"'"')"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (s)(t) $'...' is a DIFFERENT quoting construct: `\'` escapes and does not close.
#     Read under the '...' rule the scan ends one quote out of phase and reports
#     *inside* where bash is *outside* -- the fail-open direction. Both verb arms.
test_case "AC-FP-2s control: ANSI-C quoting does not desync the scan (interpreter arm)" \
  "$(bash_payload 'echo $'"'"'it\'"'"'s'"'"'; bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "AC-FP-2t control: ANSI-C quoting does not desync the scan (source arm)" \
  "$(bash_payload 'echo $'"'"'a\'"'"'b'"'"' ; source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (u)(v) arithmetic and parameter expansion can each carry a substitution. They
#     are covered by the same `$` taint, and each gets a case so a later narrowing
#     of that taint to `$(` alone fails here rather than silently.
test_case "AC-FP-2u control: arithmetic expansion carrying a substitution blocks" \
  "$(bash_payload 'echo "$(( $(cd /x; bash /tmp/evil.sh --f) ))"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "AC-FP-2v control: parameter expansion carrying a substitution blocks" \
  "$(bash_payload 'echo "${x:-$(cd /x; bash /tmp/evil.sh --f)}"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (w) process substitution is valid only OUTSIDE quotes, so it lands at segment
#     start state 0 and is adjudicated for a different reason. Pinning it anyway:
#     the reason must stay true if the state model changes.
test_case "AC-FP-2w control: process substitution blocks" \
  "$(bash_payload 'echo <(cd /x; bash /tmp/evil.sh --f)')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (x) a heredoc BODY line is not a command line, but the matcher splits on
#     newlines and cannot tell. A body line that opens a quote poisons the carried
#     state, so a real execution after the terminator reads as interior to it.
#     Heredocs are outside the model and switch suppression off entirely.
test_case "AC-FP-2x control: a heredoc body cannot suppress an execution after the terminator" \
  "$(bash_payload 'cat <<EOF
echo "hi
EOF
bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (y) nesting: an inner double quote inside a substitution must not clear the
#     outer run early.
test_case "AC-FP-2y control: nested command substitution blocks" \
  "$(bash_payload 'echo "$(echo "$(cd /x; bash /tmp/evil.sh --f)")"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (z) $"..." is a translated double-quoted string and performs the same expansions.
test_case "AC-FP-2z control: locale-translation quoting carrying a substitution blocks" \
  "$(bash_payload 'echo $"a $(cd /x; bash /tmp/evil.sh --f) b"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (aa) every carrier in the set gets the substitution treatment, not just `echo`.
test_case "AC-FP-2aa control: printf carrier with a substitution blocks" \
  "$(bash_payload 'printf -v X "%s" "$(cd /x; bash /tmp/evil.sh --f)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (ab) a subshell inside the substitution, so the head of the executing segment
#      is not the first token after the separator.
test_case "AC-FP-2ab control: subshell inside a substitution blocks" \
  "$(bash_payload 'echo "$( ( cd /x; bash /tmp/evil.sh ) )"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# (ac) the source arm reaches the same adjudicator through the same enclosure.
test_case "AC-FP-2ac control: source through a command substitution blocks" \
  "$(bash_payload 'echo "$(cd /x; source /tmp/evil.sh --f)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- The paired must-not-flag side of each axis above -----
#
# Without these the suite cannot tell a correctly narrowed suppression from one
# that has been narrowed until it never fires. Each is a real false positive: the
# construct is present as TEXT and the shell expands nothing.

# (e) $'...' performs no expansion at all, so it is inert and suppressible.
test_case "AC-FP-1e: interpreter-shaped text inside an ANSI-C quoted body allows" \
  "$(bash_payload 'gh issue comment 1 --body $'"'"'note; bash /tmp/evil.sh'"'"'')" \
  0

# (f) $"..." with nothing to expand is likewise inert.
test_case "AC-FP-1f: interpreter-shaped text inside a translated body allows" \
  "$(bash_payload 'echo $"note; bash /tmp/evil.sh"')" \
  0

# (g)(h) an ESCAPED `$` or backtick introduces no expansion, so the run stays
#     inert. These are the pairs that keep the taint from degenerating into "any
#     dollar sign anywhere, escaped or not".
test_case "AC-FP-1g: an escaped dollar does not open a substitution" \
  "$(bash_payload 'echo "\$(cd /x; bash /tmp/evil.sh)"')" \
  0

test_case "AC-FP-1h: an escaped backtick does not open a substitution" \
  "$(bash_payload 'echo "a \`cd /x; bash /tmp/evil.sh\` b"')" \
  0

# (i) inside '...' the shell expands nothing, so substitution-shaped TEXT there is
#     inert however it is spelled.
test_case "AC-FP-1i: substitution-shaped text inside a single-quoted body allows" \
  "$(bash_payload 'echo '"'"'note; $(bash /tmp/evil.sh)'"'"'')" \
  0

# (j) `\"` does not close a double-quoted run, so what follows is still interior.
test_case "AC-FP-1j: an escaped double quote does not close the carrier's run" \
  "$(bash_payload 'echo "a\"; bash /tmp/evil.sh"')" \
  0

# ==========================================================================
# NEW-B: Write/Edit primary-write guard
# ==========================================================================

echo ""
echo "NEW-B: Write/Edit primary-write guard"
echo "---"

# Helper: build Write tool JSON payload
write_payload() {
  local file_path="$1"
  local cwd="${2:-$HOME/Claude/.claude/worktrees/test}"
  /usr/bin/jq -n --arg fp "$file_path" --arg cwd "$cwd" \
    '{tool_name: "Write", tool_input: {file_path: $fp, content: "x"}, cwd: $cwd}'
}

# Helper: build Edit tool JSON payload
edit_payload() {
  local file_path="$1"
  local cwd="${2:-$HOME/Claude/.claude/worktrees/test}"
  /usr/bin/jq -n --arg fp "$file_path" --arg cwd "$cwd" \
    '{tool_name: "Edit", tool_input: {file_path: $fp, old_string: "a", new_string: "b"}, cwd: $cwd}'
}

# .git metadata writes (any cwd)
test_case "Write .git/config (from worktree) blocks" \
  "$(write_payload ''"$HOME"'/Claude/.claude/worktrees/foo/.git/config' ''"$HOME"'/Claude/.claude/worktrees/foo')" \
  2 "BLOCK-DESTRUCTIVE-016"

test_case "Write .git/hooks/pre-commit blocks" \
  "$(write_payload ''"$HOME"'/Claude/.git/hooks/pre-commit' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-016"

test_case "Write .git/info/exclude blocks" \
  "$(write_payload ''"$HOME"'/Claude/.git/info/exclude' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-016"

# Layer 1 writes from primary cwd → block
test_case "Write CLAUDE.md with primary cwd blocks" \
  "$(write_payload ''"$HOME"'/Claude/CLAUDE.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "Write pmo-platform/x.md with primary cwd blocks" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/reference/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "Write .claude/settings.json with primary cwd blocks" \
  "$(write_payload ''"$HOME"'/Claude/.claude/settings.json' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "Write .claude/hooks/block-foo.sh with primary cwd blocks" \
  "$(write_payload ''"$HOME"'/Claude/.claude/hooks/block-foo.sh' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "Write .claude/rules/bar.md with primary cwd blocks" \
  "$(write_payload ''"$HOME"'/Claude/.claude/rules/bar.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "Edit CLAUDE.md with primary cwd blocks" \
  "$(edit_payload ''"$HOME"'/Claude/CLAUDE.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# Layer 1 writes from REPO-ROOTED worktree cwd → allow (per AC: worktree context permits)
# Worktrees live under the repo root (<workspace>/pmo-platform/.claude/worktrees/), NOT
# directly under the workspace root — BLOCK-DESTRUCTIVE-019 exemption base mirrors the
# :425 Layer-1 detection base (#1639).
test_case "Write CLAUDE.md with REPO-ROOTED worktree cwd allows" \
  "$(write_payload ''"$HOME"'/Claude/CLAUDE.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/foo')" \
  0

# --- BLOCK-DESTRUCTIVE-019 worktree-exemption base correction (#1639) ---
# Both-direction gate-teeth for the repo-rooted worktree exemption base. The
# exemption base (:442) must mirror the :425 Layer-1 detection base
# (${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/), NOT the workspace root.
# FWD: a real repo-rooted worktree cwd editing a Layer-1 path → EXEMPT (allow).
# REV-a: the retired workspace-rooted base is no longer a valid exemption → BLOCK
#        (proves the exemption did not over-widen; catches the OLD base). The
#        workspace-rooted <workspace>/.claude/worktrees/ path does not exist on
#        disk and was never a real worktree, so blocking it is strictly correct.
# REV-b: a non-worktree primary cwd → BLOCK (the core invariant stays green).

# FWD — repo-rooted worktree cwd editing a pmo-platform Layer-1 path → allow
test_case "Write pmo-platform/x.md with REPO-ROOTED worktree cwd allows" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/reference/x.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/foo')" \
  0

# REV-a — workspace-rooted 'worktrees' cwd is NO LONGER a valid exemption → block
test_case "Write CLAUDE.md with WORKSPACE-ROOTED worktrees cwd blocks (old base retired)" \
  "$(write_payload ''"$HOME"'/Claude/CLAUDE.md' ''"$HOME"'/Claude/.claude/worktrees/foo')" \
  2 "BLOCK-DESTRUCTIVE-019"

# REV-b — non-worktree primary cwd → block (base-correction leaves this invariant intact)
test_case "Write pmo-platform/x.md with primary cwd blocks (base-correction invariant)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/reference/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# Explicit allow: .claude/skills (deploy target)
test_case "Write .claude/skills/SKILL.md allows (deploy target)" \
  "$(write_payload ''"$HOME"'/Claude/.claude/skills/skill-x/SKILL.md' ''"$HOME"'/Claude')" \
  0

# Explicit allow: .claude/settings.local.json (Layer 2)
test_case "Write .claude/settings.local.json allows (Layer 2)" \
  "$(write_payload ''"$HOME"'/Claude/.claude/settings.local.json' ''"$HOME"'/Claude')" \
  0

# Writes outside primary → allow
test_case "Write /tmp/foo.txt allows" \
  "$(write_payload '/tmp/foo.txt' '/tmp')" \
  0

test_case "Write ~/Documents/notes.md allows" \
  "$(write_payload ''"$HOME"'/Documents/notes.md' ''"$HOME"'')" \
  0

# --- realpath portability — ../-escape edge case ---
# Path normalization (Python os.path.realpath) must resolve ../ segments BEFORE
# the layer-1 prefix-match so that paths constructed via ../ escapes are still
# subject to BLOCK-DESTRUCTIVE-019. Prior baseline: hook referenced
# /usr/bin/realpath which does not exist on macOS, so on this system the path
# was un-normalized (fell through to FILE_PATH directly), and the ../-escape
# evaded the prefix-match. Now: Python os.path.realpath handles this
# portably on BSD/macOS and GNU/Linux alike. Requires CLAUDE.md to exist at
# $HOME/Claude/CLAUDE.md so the [ -e "$FILE_PATH" ] branch fires.

test_case "../-escape from .claude/hooks to CLAUDE.md (primary cwd) blocks" \
  "$(write_payload ''"$HOME"'/Claude/.claude/hooks/../../CLAUDE.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "../-escape from .claude/hooks to CLAUDE.md (REPO-ROOTED worktree cwd) allows" \
  "$(write_payload ''"$HOME"'/Claude/.claude/hooks/../../CLAUDE.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/foo')" \
  0

# ----- BLOCK-AP-001..005: absolute-path invocation coverage -----
#
# Cover the 5 canonical macOS/Linux absolute-path prefixes
# (/bin/, /usr/bin/, /usr/local/bin/, /opt/homebrew/bin/,
# /opt/local/bin/). Prior baseline: each of these invocation forms
# bypassed the verb-detection anchor (which required the verb to start
# at line-start or after a separator/non-alphanumeric boundary with NO
# allowance for absolute-path prefixes). Now: ANCHOR_PREFIX_BASH
# and ANCHOR_PREFIX_GIT constants match the optional prefix in both
# rm-family and git-family rules.

echo ""
echo "absolute-path invocation coverage"
echo "---"

test_case "AC-AP-001: /bin/rm -rf / blocks (BLOCK-DESTRUCTIVE-004)" \
  "$(bash_payload '/bin/rm -rf /')" 2 "BLOCK-DESTRUCTIVE-004"

test_case "AC-AP-002: /usr/bin/rm -rf / blocks (BLOCK-DESTRUCTIVE-004)" \
  "$(bash_payload '/usr/bin/rm -rf /')" 2 "BLOCK-DESTRUCTIVE-004"

test_case "AC-AP-003: /usr/local/bin/git push --force origin main blocks (BLOCK-DESTRUCTIVE-001)" \
  "$(bash_payload '/usr/local/bin/git push --force origin main')" 2 "BLOCK-DESTRUCTIVE-001"

test_case "AC-AP-004: /opt/homebrew/bin/git filter-branch HEAD blocks (BLOCK-DESTRUCTIVE-014)" \
  "$(bash_payload '/opt/homebrew/bin/git filter-branch HEAD')" 2 "BLOCK-DESTRUCTIVE-014"

test_case "AC-AP-005: echo /usr/bin/rm foo allows (false-positive guard — echo is not anchored)" \
  "$(bash_payload 'echo /usr/bin/rm foo')" 0

# AC-AP-005b: additional false-positive coverage addressing FMF-2
# adversarial finding (AC-AP-005 above passes under OLD AND NEW regex
# because `echo` is not anchored — tautological). This case genuinely
# exercises the prefix-group regression risk: `cat` followed by
# `/usr/bin/rm` as a quoted literal grep pattern. Line-start anchor
# fails (cat is not a hook-anchored verb). Pipe-separator anchor
# fires on `|`, but the second segment starts with `grep`, not `rm`.
# Both the prior and current anchor correctly allow this.
test_case "AC-AP-005c: cat | grep with '/usr/bin/rm' literal allows (false-positive guard)" \
  "$(bash_payload 'cat /tmp/log.txt | grep "/usr/bin/rm called"')" 0

# AC-AP-005d: composition test — chained absolute-path invocation
# (separator + prefix + verb together). This is the canonical
# regression risk surface: the new pattern MUST correctly fire when
# all three components present. Prior anchor: allowed (anchor failed).
# Current anchor: blocked (anchor + prefix + verb all present).
test_case "AC-AP-005d: chained && /opt/local/bin/rm -rf /etc blocks (composes with chained-command)" \
  "$(bash_payload 'ls && /opt/local/bin/rm -rf /etc')" 2 "BLOCK-DESTRUCTIVE-004"

# AC-AP-005e: variable-prefix-only invocation does NOT match the
# canonical absolute-path prefix set; ensures the prefix group is
# enumerated (not just any absolute path).
test_case "AC-AP-005e: non-canonical-prefix /home/user/bin/rm /tmp/foo allows (out-of-scope prefix)" \
  "$(bash_payload '/home/user/bin/rm /tmp/foo')" 0

# AC-AP-022a: absolute-path bash/sh/zsh script invocation. Pre-Pass-2:
# BLOCK-DESTRUCTIVE-022 used raw-grep with the OLD (^|[;&|])[[:space:]]*
# anchor instead of ${ANCHOR_PREFIX_BASH} — `/bin/bash /tmp/evil.sh`
# bypassed the script-laundering protection in the same release that
# claimed to systematically close absolute-path bypasses. Pass 2
# applies ${ANCHOR_PREFIX_BASH} to both raw-grep sites at lines 330,342.
# Hand-traced regex evidence recorded in the DT Pass 1 report.
test_case "AC-AP-022a: /bin/bash /tmp/evil.sh blocks (BLOCK-DESTRUCTIVE-022 script form)" \
  "$(bash_payload '/bin/bash /tmp/evil.sh')" 2 "BLOCK-DESTRUCTIVE-022"

# AC-AP-022b: absolute-path source/. invocation. Same anchor convention
# applies to the source/. detection at line 342. Pre-Pass-2:
# `/bin/. /tmp/evil.sh` bypassed; Pass 2: blocks.
test_case "AC-AP-022b: /bin/. /tmp/evil.sh blocks (BLOCK-DESTRUCTIVE-022 source form)" \
  "$(bash_payload '/bin/. /tmp/evil.sh')" 2 "BLOCK-DESTRUCTIVE-022"

# ==========================================================================
# GHSA-9cjm-v22x-4x33: jq fail-CLOSED regression (missing-dependency gate)
# ==========================================================================
#
# jq resolution now lives in lib/dep-resolve.sh. To simulate a host with no jq
# we sandbox BOTH files: a copy of the hook plus a copy of the helper whose
# THREE jq candidate paths (/usr/bin/jq /opt/homebrew/bin/jq /usr/local/bin/jq)
# are sed'd to nonexistent paths. POSTURE = enforce: a SHOULD-BLOCK payload
# under missing jq must fail CLOSED (exit 2), never fail open (exit 0). A second
# case proves the helper being absent ENTIRELY also fails closed (bash 3.2 exits
# 1 on a failed source, which is non-blocking — the readability pre-test + exit 2
# is what keeps it closed).

echo ""
echo "GHSA-9cjm-v22x-4x33: jq fail-closed regression"
echo "---"

DESTRUCTIVE_SANDBOX="$(/usr/bin/mktemp -d)"
DEP_LIB_SRC="$(cd "$(dirname "$0")/.." && pwd -P)/lib/dep-resolve.sh"
/bin/mkdir -p "$DESTRUCTIVE_SANDBOX/lib"
/bin/cp "$HOOK" "$DESTRUCTIVE_SANDBOX/block-destructive.sh"
/usr/bin/sed \
  -e 's#/usr/bin/jq#/nonexistent/jq#g' \
  -e 's#/opt/homebrew/bin/jq#/nonexistent/hb/jq#g' \
  -e 's#/usr/local/bin/jq#/nonexistent/ul/jq#g' \
  "$DEP_LIB_SRC" > "$DESTRUCTIVE_SANDBOX/lib/dep-resolve.sh"

sandbox_case() {
  local name="$1" hook_path="$2" payload="$3" expected_exit="$4" expected_pattern="${5:-}"
  local tmp_stderr actual_exit=0 actual_stderr ok=1
  tmp_stderr="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$payload" | /bin/bash "$hook_path" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  [ "$actual_exit" != "$expected_exit" ] && ok=0
  if [ -n "$expected_pattern" ] && ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "$expected_pattern"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  expected_exit=%s actual_exit=%s\n  stderr: %s\n' "$name" "$expected_exit" "$actual_exit" "$actual_stderr"; FAIL=$((FAIL + 1))
  fi
}

# jq unresolvable (helper present, all candidates missing) + should-block payload → exit 2 (fail-closed)
sandbox_case "jq-missing: rm -rf / fails CLOSED (exit 2, DEPENDENCY-MISSING)" \
  "$DESTRUCTIVE_SANDBOX/block-destructive.sh" \
  "$(bash_payload 'rm -rf /')" \
  2 "DEPENDENCY-MISSING"

# CLAUDE_HOOK_BYPASS=1 short-circuits BEFORE the gate even with jq unresolvable → exit 0
sandbox_bypass_exit=0
CLAUDE_HOOK_BYPASS=1 /usr/bin/printf '%s' "$(bash_payload 'rm -rf /')" \
  | CLAUDE_HOOK_BYPASS=1 /bin/bash "$DESTRUCTIVE_SANDBOX/block-destructive.sh" >/dev/null 2>&1 || sandbox_bypass_exit="$?"
if [ "$sandbox_bypass_exit" = 0 ]; then
  /usr/bin/printf 'PASS: jq-missing + CLAUDE_HOOK_BYPASS=1 short-circuits (exit 0)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq-missing + CLAUDE_HOOK_BYPASS=1\n  expected_exit=0 actual_exit=%s\n' "$sandbox_bypass_exit"; FAIL=$((FAIL + 1))
fi

# Helper absent entirely (no lib/dep-resolve.sh) → fails CLOSED (exit 2, LIB-MISSING)
DESTRUCTIVE_NOLIB="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "$DESTRUCTIVE_NOLIB/block-destructive.sh"
sandbox_case "helper-missing: fails CLOSED (exit 2, LIB-MISSING)" \
  "$DESTRUCTIVE_NOLIB/block-destructive.sh" \
  "$(bash_payload 'rm -rf /')" \
  2 "LIB-MISSING"

/bin/rm -rf "$DESTRUCTIVE_SANDBOX" "$DESTRUCTIVE_NOLIB"

# --- Summary ---
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
