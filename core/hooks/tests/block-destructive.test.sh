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

# --- EXT-POS (#5644): the root-filesystem rule is command-POSITION sensitive ---
#
# ANCHOR_PREFIX_BASH saw a command start only at line-start or after `;&|`, so the
# highest-severity rule in this hook did not fire on the same deletion behind an ordinary
# command prefix. Each case below is the IDENTICAL `rm -rf /` and allowed before the
# shared canonicalizer (core/hooks/lib/command-position.awk) landed.
test_case "EXT-POS-D1: sudo rm -rf / blocks (command-prefix word)" \
  "$(bash_payload 'sudo rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D2: time rm -rf / blocks (command-prefix word)" \
  "$(bash_payload 'time rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D3: env rm -rf / blocks (command-prefix word)" \
  "$(bash_payload 'env rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D4: FOO=1 rm -rf / blocks (assignment prefix)" \
  "$(bash_payload 'FOO=1 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D5: escaped verb rm -rf / blocks" \
  "$(bash_payload '\rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# --- EXT-RES (#5644): residual boundary of THIS rule, pinned deliberately ---
#
# ALLOW assertions on purpose, and NOT because the position is still blind — it is not.
# `{ rm -rf /; }` puts the target immediately before `;`, and this rule's own terminator
# class is `([[:space:]]|$|/\*)`, which does not admit `;`. The position is closed; the
# terminator class is a separate defect in this rule, tracked outside this change (the
# root-filesystem guard is filed as its own item). Pinning it means the fix for that
# defect has a fixture that MUST flip rather than a silent behaviour change. The
# containment guard (BLOCK-TRASH-001, block-rm-prefer-trash.sh) does deny these today.
test_case "EXT-RES-D1: { rm -rf /; } allows HERE — terminator class, not position (residual)" \
  "$(bash_payload '{ rm -rf /; }')" \
  0

test_case "EXT-RES-D2: nested-shell program string allows (documented nested-shell residual)" \
  "$(bash_payload 'bash -c '"'"'rm -rf /'"'"'')" \
  0

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
# BLOCK-022 trailing-punctuation normalization + arm parity
# ==========================================================================
#
# THE DEFECT THIS BLOCK PINS. normalize_script_token used to strip exactly one
# quote character from each end. A token that is the TAIL of a command
# substitution carries the substitution's own closing punctuation -- `)`, `)"`,
# or a closing backtick -- so one strip left residual punctuation attached. The
# interpreter arm's operand filter is SUFFIX-anchored (`*.sh`), so the residual
# defeated it and check_script_target was never called: the matcher fired, then
# silently skipped, and the allowlist was never consulted. The source/. arm
# survived the identical input because its filter carries PREFIX alternatives
# (`/*`, `./*`, `../*`) that trailing punctuation does not disturb. That is a
# measured asymmetry between two arms of one rule, and it is what this block
# turns into a standing assertion.
#
# THE FIX IS NORMALIZATION, NOT FILTER UNIFICATION -- and that is a constraint,
# not a preference. The shipped comment above the source arm forbids unifying
# the two filters in either direction: narrowing the source arm to `*.sh`
# silently drops `/*`, `~/*` and `*.bash` coverage, and widening the interpreter
# arm to `/*` opens a false-positive surface with no defect behind it. So the
# arms KEEP different operand domains by design, and a parity claim over their
# UNION would be false. The claim asserted here is parity over their SHARED
# domain -- `.sh`-suffixed operands, which both filters accept -- and it is
# paired below with a domain-boundary control that asserts the arms still
# DIFFER outside that domain. Those two together are what make "symmetric"
# falsifiable: unify the filters and the boundary control turns red; regress the
# normalization and the parity rows turn red.
#
# THE TABLE IS THREE-ARM BY CONSTRUCTION. `exec` is registered as an arm here
# with status `pending`, not omitted, because a third execution arm is a known
# forthcoming change to this same rule. Its rows announce themselves as skipped
# WITH THE REASON on every run rather than being silently absent -- an absent
# arm reads as a covered arm, which is the failure mode this whole milestone
# exists to close.
#
# ACTIVATION COST, CORRECTED. The note this paragraph replaced predicted that
# activating `exec` would be a one-word edit to B022_ARMS with no case
# re-authored. The one-word edit is real -- `pending:...` -> `active`, and the
# empty verb field renders the arm's command line with no re-authoring of
# b022_cmd, because direct execution IS the path at command position. What the
# prediction missed is that the exec arm ships PHASE-GATED at `warn`, so at the
# shipped phase it deliberately returns exit 0 on a must-flag input while the
# other two return 2. Two things follow, and both are additions rather than
# rewrites:
#
#   (1) the must-flag EXPECTED EXIT is now per-arm, read from the hook's own
#       DESTRUCTIVE_022_EXEC_PHASE constant rather than hardcoded; and
#   (2) the parity aggregate compares the ADJUDICATION DECISION (deny/allow),
#       not the raw exit code.
#
# (2) is the more faithful claim, not a weakened one. What parity was always
# about is whether every arm carries its operand to the ALLOWLIST and decides
# the same way; the exit code was only ever a proxy for that decision, and it
# stops being one the moment an arm is allowed to decide `deny` and act `allow`.
# At `warn` the exec arm's decision is evidenced by a drain row, so the drain
# delta is read as the verdict. Set the phase constant to `enforce` and the
# decision and the exit code coincide again with no edit here.

echo ""
echo "BLOCK-022 trailing-punctuation normalization + arm parity"
echo "---"

# Arm registry -- "<key>|<verb>|<status>". status is `active` or `pending:<why>`.
# The exec arm's verb is EMPTY by construction: direct execution has no verb
# token, the path itself sits at command position. b022_cmd's formats render
# that as a leading space, which the hook trims with the same leading-whitespace
# trim every segment gets -- so no format needs a third variant.
B022_ARMS=(
  "interp|bash|active"
  "source|source|active"
  "exec||active"
)

# Operand spellings in the arms' SHARED domain. Each is a real raw-argv shape a
# shell produces; the last three are the command-substitution tails that carry
# residual punctuation onto the operand token.
B022_SHAPES="bare dquote squote half-dquote paren paren-dquote backtick"

# Render one command line. Single-quoted formats keep `$(` and the backtick
# literal -- these strings are payload text, never evaluated here.
b022_cmd() { # $1 shape  $2 verb  $3 path
  case "$1" in
    bare)         /usr/bin/printf '%s %s'                        "$2" "$3" ;;
    dquote)       /usr/bin/printf '%s "%s"'                      "$2" "$3" ;;
    squote)       /usr/bin/printf "%s '%s'"                      "$2" "$3" ;;
    half-dquote)  /usr/bin/printf '%s %s"'                       "$2" "$3" ;;
    paren)        /usr/bin/printf 'echo $(cd /tmp && %s %s)'     "$2" "$3" ;;
    paren-dquote) /usr/bin/printf 'echo "$(cd /tmp && %s %s)"'   "$2" "$3" ;;
    backtick)     /usr/bin/printf 'echo `cd /tmp && %s %s`'      "$2" "$3" ;;
  esac
}

# The exec arm's rollout drain. Read from the hook's own HOOK_DIR so the test
# and the hook cannot disagree about where the drain lives.
B022_DRAIN="${HOOK%/*}/destructive-warn-log.jsonl"

b022_drain_rows() {
  if [ -f "$B022_DRAIN" ]; then
    /usr/bin/wc -l < "$B022_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

# The shipped rollout phase, read OUT OF THE HOOK SOURCE rather than restated
# here. Restating it would let the constant and the expectation drift in
# opposite directions and still go green -- the test would then be asserting its
# own copy of the posture instead of the hook's.
B022_EXEC_PHASE="$(/usr/bin/sed -n '/^readonly DESTRUCTIVE_022_EXEC_PHASE=/{s/^readonly DESTRUCTIVE_022_EXEC_PHASE="\([a-z]*\)".*/\1/p;q;}' "$HOOK")"
if [ -z "$B022_EXEC_PHASE" ]; then
  /usr/bin/printf 'FAIL: BLOCK-022 exec phase constant not readable from %s (the suite cannot state an expectation it cannot resolve)\n' "$HOOK"
  FAIL=$((FAIL + 1))
  B022_EXEC_PHASE="unreadable"
fi
case "$B022_EXEC_PHASE" in
  enforce) B022_EXEC_FLAG_EXIT=2 ;;
  *)       B022_EXEC_FLAG_EXIT=0 ;;
esac
/usr/bin/printf 'PASS: BLOCK-022 exec arm rollout phase resolved from the hook source: %s (must-flag expects exit %s)\n' \
  "$B022_EXEC_PHASE" "$B022_EXEC_FLAG_EXIT"
PASS=$((PASS + 1))

# Map one arm's observed behaviour to the ADJUDICATION DECISION. For the two
# always-enforcing arms the exit code IS the decision. For the phase-gated exec
# arm below `enforce` it is not: the arm decides `deny` and then acts `allow` by
# design, and the drain row is the record of the decision. Reading the drain is
# what keeps the parity claim about adjudication rather than about exit status.
b022_decide() { # $1 arm key  $2 rc  $3 drain delta -> prints deny|allow
  if [ "$1" = "exec" ] && [ "$B022_EXEC_PHASE" != "enforce" ]; then
    if [ "$3" -gt 0 ]; then /usr/bin/printf 'deny'; else /usr/bin/printf 'allow'; fi
    return 0
  fi
  if [ "$2" = "2" ]; then /usr/bin/printf 'deny'; else /usr/bin/printf 'allow'; fi
}

# Run the hook and record the exit code in B022_RC, asserting the expectation in
# the same pass so the hook is invoked once per case rather than twice. The
# drain delta is captured around the same single invocation, so the decision
# reading below costs no extra hook run.
B022_RC=""
B022_DRAIN_DELTA=0
b022_case() { # $1 name  $2 payload  $3 expected_exit
  local rc=0 before after
  before="$(b022_drain_rows)"
  /usr/bin/printf '%s' "$2" | /bin/bash "$HOOK" >/dev/null 2>&1 || rc="$?"
  after="$(b022_drain_rows)"
  B022_RC="$rc"
  B022_DRAIN_DELTA=$(( after - before ))
  if [ "$rc" = "$3" ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  expected_exit=%s actual_exit=%s\n' "$1" "$3" "$rc"; FAIL=$((FAIL + 1))
  fi
}

B022_EVIL="/tmp/evil.sh"                 # must-flag   -- never allowlisted
B022_OK="core/deploy/deploy.sh"          # must-not-flag -- allowlisted, bare-relative form
B022_ACTIVE_ARMS=0
B022_PENDING_ARMS=0

for b022_arm in "${B022_ARMS[@]}"; do
  case "${b022_arm##*|}" in
    active) B022_ACTIVE_ARMS=$((B022_ACTIVE_ARMS + 1)) ;;
    *)      B022_PENDING_ARMS=$((B022_PENDING_ARMS + 1)) ;;
  esac
done

for b022_shape in $B022_SHAPES; do
  b022_flag_verdicts=""
  b022_notflag_verdicts=""

  for b022_arm in "${B022_ARMS[@]}"; do
    b022_key="${b022_arm%%|*}"
    b022_rest="${b022_arm#*|}"
    b022_verb="${b022_rest%%|*}"
    b022_status="${b022_rest##*|}"

    if [ "$b022_status" != "active" ]; then
      /usr/bin/printf 'SKIP: BLOCK-022 parity %s/%s -- %s. No verdict asserted; this arm is declared, not covered.\n' \
        "$b022_shape" "$b022_key" "${b022_status#pending:}"
      continue
    fi

    # must-flag: a non-allowlisted script must be ADJUDICATED AND DENIED in
    # every spelling. This is the specificity arm -- the fix must make these
    # tokens REACH the allowlist, never pass it. The expected EXIT is per-arm:
    # the two always-enforcing arms block, and the phase-gated exec arm exits 0
    # below `enforce` while still recording the denial in its drain.
    if [ "$b022_key" = "exec" ]; then
      b022_expect_flag="$B022_EXEC_FLAG_EXIT"
    else
      b022_expect_flag=2
    fi
    b022_case "BLOCK-022 parity $b022_shape/$b022_key: non-allowlisted denied (expect exit $b022_expect_flag)" \
      "$(bash_payload "$(b022_cmd "$b022_shape" "$b022_verb" "$B022_EVIL")")" \
      "$b022_expect_flag"
    b022_flag_verdicts="$b022_flag_verdicts $b022_key=$(b022_decide "$b022_key" "$B022_RC" "$B022_DRAIN_DELTA")"

    # must-not-flag: an allowlisted script must still be permitted in the same
    # spelling. Without this the whole set is satisfiable by a hook that denies
    # everything. Exit 0 on every arm -- an allowlisted path is permitted at
    # every phase, and on the exec arm it must not even be recorded, which the
    # decision reading below asserts as `allow`.
    b022_case "BLOCK-022 parity $b022_shape/$b022_key: allowlisted allows" \
      "$(bash_payload "$(b022_cmd "$b022_shape" "$b022_verb" "$B022_OK")")" \
      0
    b022_notflag_verdicts="$b022_notflag_verdicts $b022_key=$(b022_decide "$b022_key" "$B022_RC" "$B022_DRAIN_DELTA")"
  done

  # The parity assertion itself: every ACTIVE arm reached the same ADJUDICATION
  # DECISION for this spelling, in both directions. Distinct from the per-arm
  # expectations above -- those can all be red while still agreeing, and this
  # row is what names the disagreement when they do not. The verdicts compared
  # are `deny`/`allow`, not exit codes, because one arm is phase-gated and its
  # exit code is deliberately not its decision below `enforce`.
  for b022_dir in flag notflag; do
    case "$b022_dir" in
      flag)    b022_v="$b022_flag_verdicts" ;;
      *)       b022_v="$b022_notflag_verdicts" ;;
    esac
    b022_distinct="$(/usr/bin/printf '%s' "$b022_v" | /usr/bin/tr ' ' '\n' \
      | /usr/bin/sed -n 's/.*=//p' | /usr/bin/sort -u | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
    if [ "$b022_distinct" = "1" ]; then
      /usr/bin/printf 'PASS: BLOCK-022 parity %s/%s: all %s active arms agree (%s)\n' \
        "$b022_shape" "$b022_dir" "$B022_ACTIVE_ARMS" "$b022_v"
      PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: BLOCK-022 parity %s/%s: active arms DISAGREE\n  verdicts:%s\n' \
        "$b022_shape" "$b022_dir" "$b022_v"
      FAIL=$((FAIL + 1))
    fi
  done
done

/usr/bin/printf 'PASS: BLOCK-022 parity arm coverage: %s active, %s pending (declared, not covered)\n' \
  "$B022_ACTIVE_ARMS" "$B022_PENDING_ARMS"
PASS=$((PASS + 1))

# Emitted as RESIDUAL, not as a bare echo, because test-runner.sh forwards only
# `^RESIDUAL` and `^FAIL` lines from a suite's captured output. A per-shape SKIP
# line is visible when this file is run standalone and invisible at the
# authoritative runner -- so on a green CI run the pending arm would leave no
# trace at all, which is precisely the "absent reads as covered" failure this
# block is built to avoid. This line qualifies the green.
if [ "$B022_PENDING_ARMS" -gt 0 ]; then
  /usr/bin/printf 'RESIDUAL: BLOCK-022 arm parity is asserted over %s of %s registered arms. %s arm(s) are DECLARED BUT NOT COVERED; a green run here does not speak for them.\n' \
    "$B022_ACTIVE_ARMS" "$((B022_ACTIVE_ARMS + B022_PENDING_ARMS))" "$B022_PENDING_ARMS"
  for b022_arm in "${B022_ARMS[@]}"; do
    b022_status="${b022_arm##*|}"
    case "$b022_status" in
      active) ;;
      *) /usr/bin/printf 'RESIDUAL: BLOCK-022 arm `%s` not covered -- %s.\n' \
           "${b022_arm%%|*}" "${b022_status#pending:}" ;;
    esac
  done
fi

# --- domain-boundary control (MANDATORY) ----------------------------------
# The arms' operand domains differ BY DESIGN and must keep differing. These
# operands are outside the shared `.sh` domain: the source arm adjudicates them
# through its `*.bash` and `/*` alternatives, the interpreter arm does not.
# Asserting the DIFFERENCE is what stops the parity rows above from being
# satisfiable by unifying the two filters -- the exact edit the shipped comment
# on the source arm forbids. If someone narrows source to `*.sh`, the first pair
# goes red; if someone widens interp to `/*`, the second pair goes red.
test_case "BLOCK-022 domain boundary: .bash operand blocks on source (outside interp's domain)" \
  "$(bash_payload 'echo $(cd /tmp && source /tmp/evil.bash)')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 domain boundary: .bash operand allows on interp (interp keeps its *.sh domain)" \
  "$(bash_payload 'echo $(cd /tmp && bash /tmp/evil.bash)')" \
  0

test_case "BLOCK-022 domain boundary: extensionless absolute blocks on source (/* arm)" \
  "$(bash_payload 'echo $(cd /tmp && source /tmp/evil)')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 domain boundary: extensionless absolute allows on interp (no *.sh match)" \
  "$(bash_payload 'echo $(cd /tmp && bash /tmp/evil)')" \
  0

# --- normalization unit-shape controls -------------------------------------
# Trailing punctuation must be stripped as a RUN, not one character. A single
# strip was the whole defect, so a case with TWO trailing punctuation
# characters is the one that distinguishes a run-strip from an off-by-one fix.
test_case "BLOCK-022 trailing run: two trailing punctuation chars still block" \
  "$(bash_payload 'echo "$(cd /tmp && bash /tmp/evil.sh)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 trailing run control: two trailing punctuation chars on an allowlisted path allow" \
  "$(bash_payload 'echo "$(cd /tmp && bash core/deploy/deploy.sh)"')" \
  0

# Stripping must never manufacture an allow: a variable-bearing path keeps its
# fail-closed verdict once the punctuation is gone, rather than normalizing into
# something the filter skips.
test_case "BLOCK-022 trailing run: variable-bearing path with trailing punctuation still fails closed" \
  "$(bash_payload 'echo "$(cd /tmp && bash $W/evil.sh)"')" \
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
# BLOCK-022 command-position invariance under COMMAND-WRAPPER prefixes
# ==========================================================================
#
# Same invariant as the assignment block above, on the other half of the prefix
# grammar. The walk resolved assignment prefixes ONLY, so a transparent command
# wrapper ahead of the verb resolved AS the command word: no verb matched, and
# the invocation fell through to ALLOW with the allowlist never consulted. The
# operation is identical to the bare form, so the verdict must be too.
#
# The set is a BOUNDED enumeration mirroring core/hooks/lib/command-position.awk.
# Every must-flag case below is paired with the SAME wrapper spelling over an
# ALLOWLISTED target, so an implementation that simply blocked anything carrying
# a leading wrapper word would fail the controls rather than pass the suite.

echo ""
echo "BLOCK-022 command-wrapper-prefix invariance"
echo "---"

test_case "BLOCK-022 wrapper: sudo before bash, non-allowlisted, blocks" \
  "$(bash_payload 'sudo bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: env before bash, non-allowlisted, blocks" \
  "$(bash_payload 'env bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: command before bash, non-allowlisted, blocks" \
  "$(bash_payload 'command bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: exec before bash, non-allowlisted, blocks" \
  "$(bash_payload 'exec bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: nohup before bash, non-allowlisted, blocks" \
  "$(bash_payload 'nohup bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: time before bash, non-allowlisted, blocks" \
  "$(bash_payload 'time bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# absolute wrapper form -- the wrapper is matched on its BASENAME, as the verb is.
test_case "BLOCK-022 wrapper: /usr/bin/env before bash, non-allowlisted, blocks" \
  "$(bash_payload '/usr/bin/env bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# compound-command keywords are command-start positions too, and the segment
# splitter puts them at the head of their segment.
test_case "BLOCK-022 wrapper: 'then' keyword before bash blocks" \
  "$(bash_payload 'if [ -f /tmp/x ]; then bash /tmp/evil.sh; fi')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: 'do' keyword before bash blocks" \
  "$(bash_payload 'for f in a; do bash /tmp/evil.sh; done')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: '!' negation before bash blocks" \
  "$(bash_payload '! bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# the source/. arm resolves command position through the same walk.
test_case "BLOCK-022 wrapper: sudo before source, non-allowlisted, blocks" \
  "$(bash_payload 'sudo source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: builtin before source, non-allowlisted, blocks" \
  "$(bash_payload 'builtin source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: env before '.', non-allowlisted, blocks" \
  "$(bash_payload 'env . /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# the two prefix families interleave in one walk, in either order.
test_case "BLOCK-022 wrapper: wrapper then assignment before bash blocks" \
  "$(bash_payload 'sudo ENVV=1 bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: assignment then wrapper before bash blocks" \
  "$(bash_payload 'ENVV=1 sudo bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# a wrapper does not shield a later command any more than an allowlisted one does.
test_case "BLOCK-022 wrapper chain: wrapper laundering behind an allowlisted first command blocks" \
  "$(bash_payload 'bash core/deploy/deploy.sh; sudo bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper chain: wrapper after '&&' blocks" \
  "$(bash_payload 'echo hi && env bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# xargs, both directions. With an argv path the executed script IS that path and
# is adjudicated normally; with none, the operand list arrives on stdin and the
# target is UNRESOLVABLE -- which denies, matching the variable-bearing posture,
# rather than falling through to allow.
test_case "BLOCK-022 wrapper: xargs with a non-allowlisted argv path blocks" \
  "$(bash_payload 'echo x | xargs bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 wrapper: xargs feeding an interpreter from stdin blocks (unresolvable)" \
  "$(bash_payload 'echo /tmp/evil.sh | xargs bash')" \
  2 "unresolvable script target"

# must-not-flag controls -- the SAME wrapper spellings over ALLOWLISTED targets.
# Without these the wrapper walk could have been implemented as "block anything
# behind a wrapper word" and the suite would still be green.
test_case "BLOCK-022 wrapper control: sudo before bash, allowlisted, allows" \
  "$(bash_payload 'sudo bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: env before bash, allowlisted, allows" \
  "$(bash_payload 'env bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: exec before bash, allowlisted, allows" \
  "$(bash_payload 'exec bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: time before bash, allowlisted, allows" \
  "$(bash_payload 'time bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: sudo before source, allowlisted, allows" \
  "$(bash_payload 'sudo source core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: wrapper + assignment, allowlisted, allows" \
  "$(bash_payload 'sudo ENVV=1 bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: xargs with an allowlisted argv path allows" \
  "$(bash_payload 'echo x | xargs bash core/deploy/deploy.sh')" \
  0

test_case "BLOCK-022 wrapper control: wrapper before a non-interpreter verb allows" \
  "$(bash_payload 'sudo grep -r needle /tmp/evil.sh')" \
  0

# skip-precision controls. The walk must advance past a word in the BOUNDED SET,
# not past "any leading word". Each token below is an unlisted word, so it IS the
# command word -- not an interpreter -- and the verdict is UNCHANGED from before
# the wrapper walk existed. If the skip ever loosens into advance-past-anything,
# these flip to blocking and fail.
test_case "BLOCK-022 wrapper precision: unlisted leading word does not advance" \
  "$(bash_payload 'mytool bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 wrapper precision: near-miss on a listed word does not advance" \
  "$(bash_payload 'sudoedit bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 wrapper precision: wrapper flag terminates the walk" \
  "$(bash_payload 'command -v bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 wrapper precision: wrapper word off the segment head does not advance" \
  "$(bash_payload 'echo sudo bash /tmp/evil.sh')" \
  0

# recorded residuals, asserted so the stated coverage boundary is measured rather
# than assumed. `eval` re-parses a program string this lexical matcher cannot
# resolve; `timeout` carries an operand the walk would additionally have to
# consume. Both are deliberately OUT of the bounded set. If either is ever added,
# these two cases fail and the rule doc must be updated with them.
test_case "BLOCK-022 wrapper residual: eval is not a skipped prefix (allows)" \
  "$(bash_payload 'eval bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 wrapper residual: timeout is not a skipped prefix (allows)" \
  "$(bash_payload 'timeout 5 bash /tmp/evil.sh')" \
  0

# false-positive controls -- the wrapper walk must not disturb the quoted-fragment
# suppression that keeps DESCRIBED executions from being read as performed ones.
test_case "BLOCK-022 wrapper FP: carrier-quoted fragment with a wrapper allows" \
  "$(bash_payload "gh issue comment 1 --body 'note; sudo bash /tmp/evil.sh'")" \
  0

test_case "BLOCK-022 wrapper FP: wrapper invocation quoted as echo text allows" \
  "$(bash_payload "echo 'sudo bash /tmp/evil.sh'")" \
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
# BLOCK-022 exec arm — direct script execution, phase-gated
# ==========================================================================
#
# THE BYPASS THIS BLOCK PINS. `bash /tmp/x.sh` blocked; `/tmp/x.sh` -- the same
# script, the same allowlist state, the ordinary way to run an executable --
# was not adjudicated by any rule in any hook. The allowlist was bypassable by
# making the file executable and dropping the interpreter word, on a rule whose
# own block message reads "Red Team C1 -- script-laundering mitigation".
#
# WHY EVERY ASSERTION HERE READS THE DRAIN AND NOT ONLY THE EXIT CODE. The arm
# ships at `warn`, so it returns 0 on a would-fire input. A case asserting exit
# 0 alone would pass against a hook that never evaluated the arm at all -- it
# would pass right now against the pre-change hook, and it would keep passing if
# the arm were deleted. The drain delta is what makes evaluation a NECESSARY
# condition of a green run rather than an incidental one.
#
# The pair T-EXEC-1 / T-EXEC-9 is the must-flag / must-not-flag pair AC-3 asks
# for, and both were demonstrated against the PRE-change hook before this block
# was written: T-EXEC-1 returned exit 0 with no drain row (nothing adjudicated
# it), and T-EXEC-9 also returned exit 0 -- so a naive widening that adopted the
# source arm's operand filter would newly flag it. A control that passes both
# before and after proves nothing.

echo ""
echo "BLOCK-022 exec arm (direct execution, rollout=${B022_EXEC_PHASE})"
echo "---"

# A would-fire case. Asserts the exit code the SHIPPED phase implies, that the
# drain grew by exactly one row, that the row carries that phase and the
# expected cause class, and -- at `warn` only -- that the operator saw a notice.
exec_warn_case() { # $1 name  $2 command  $3 expected cause
  local rc=0 before after last err tmp_err ok=1 why=""
  before="$(b022_drain_rows)"
  tmp_err="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload "$2")" | /bin/bash "$HOOK" >/dev/null 2>"$tmp_err" || rc="$?"
  after="$(b022_drain_rows)"
  err="$(/bin/cat "$tmp_err")"; /bin/rm -f "$tmp_err"

  [ "$rc" = "$B022_EXEC_FLAG_EXIT" ] || { ok=0; why="$why exit=$rc(want $B022_EXEC_FLAG_EXIT)"; }
  [ "$(( after - before ))" = "1" ] || { ok=0; why="$why drain_delta=$(( after - before ))(want 1)"; }
  last="$(/usr/bin/tail -1 "$B022_DRAIN" 2>/dev/null || /usr/bin/printf '')"
  case "$last" in
    *"\"phase\":\"${B022_EXEC_PHASE}\""*) ;;
    *) ok=0; why="$why phase-field!=${B022_EXEC_PHASE}" ;;
  esac
  case "$last" in
    *"\"cause\":\"$3\""*) ;;
    *) ok=0; why="$why cause!=$3" ;;
  esac
  case "$last" in
    *'"reason":"would-fire"'*) ;;
    *) ok=0; why="$why reason-field-missing" ;;
  esac
  # `shadow` surfaces nothing by design -- the drain IS the observation -- so a
  # notice there would be the defect, not the assertion.
  case "$B022_EXEC_PHASE" in
    warn)
      case "$err" in
        *'BLOCK-DESTRUCTIVE-022] WARN (would-block, rollout=warn'*) ;;
        *) ok=0; why="$why no-stderr-notice" ;;
      esac
      ;;
    shadow)
      case "$err" in
        *'BLOCK-DESTRUCTIVE-022'*) ok=0; why="$why shadow-must-be-silent" ;;
        *) ;;
      esac
      ;;
  esac

  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  %s\n  last_drain_row: %s\n' "$1" "$why" "$last"; FAIL=$((FAIL + 1))
  fi
}

# A must-not-flag case. Exit 0 AND the drain unchanged -- the second half is the
# load-bearing one. An arm that logged every candidate and then allowed it would
# satisfy exit 0 while making the drain unreadable, which is the failure that
# turns a graduation reading into noise.
exec_notflag_case() { # $1 name  $2 command
  local rc=0 before after ok=1 why=""
  before="$(b022_drain_rows)"
  /usr/bin/printf '%s' "$(bash_payload "$2")" | /bin/bash "$HOOK" >/dev/null 2>&1 || rc="$?"
  after="$(b022_drain_rows)"
  [ "$rc" = "0" ] || { ok=0; why="$why exit=$rc(want 0)"; }
  [ "$(( after - before ))" = "0" ] || { ok=0; why="$why drain_delta=$(( after - before ))(want 0)"; }
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  %s\n' "$1" "$why"; FAIL=$((FAIL + 1))
  fi
}

# --- MUST-FLAG ---------------------------------------------------------------
exec_warn_case "T-EXEC-1 must-flag: direct execution of a non-allowlisted script (the reproduction)" \
  '/tmp/pmo-probe-not-allowlisted-xyz.sh' 'not-allowlisted'

exec_warn_case "T-EXEC-2 must-flag: relative direct execution with a flag" \
  './tmp/evil.sh --flag' 'not-allowlisted'

# Every segment is adjudicated, not just the first, so a direct execution cannot
# hide behind an innocuous command ahead of it.
exec_warn_case "T-EXEC-3 must-flag: direct execution chained after another command" \
  'git status; /tmp/evil.sh' 'not-allowlisted'

# The cause classes must stay separate in the drain. `unresolvable` has NO
# allowlist remedy -- sending an operator to edit an allowlist that can never
# match is the exact trap BLOCK-EGRESS-007 was filed about -- so a drain that
# conflated the two would misdirect the graduation decision.
exec_warn_case "T-EXEC-4 must-flag: variable-bearing direct execution records cause=unresolvable" \
  '$TMPDIR/probe.sh' 'unresolvable'

# The operand filter is `*.sh|*.bash`, matching the interpreter arm's domain
# widened only by `.bash`. This case is what distinguishes it from a bare `*.sh`.
exec_warn_case "T-EXEC-2b must-flag: .bash operand on the exec arm" \
  './tmp/evil.bash' 'not-allowlisted'

# --- MUST-NOT-FLAG -----------------------------------------------------------
exec_notflag_case "T-EXEC-5 must-not-flag: allowlisted tool by direct execution (form 3)" \
  './core/deploy/deploy.sh --check'

# The BLOCK-SHELL-INJECTION-002 read-across, and the single most important
# structural constraint on this arm. A markdown table row shreds on `|` into
# fragments whose head token can contain `/` and end `.sh`. The arm is safe only
# because it sits INSIDE the quoted-fragment suppression and is evaluated only
# for segments at true command position. Hoist it above that block and this case
# goes red -- which is the point of having it.
exec_notflag_case "T-EXEC-6 must-not-flag: markdown table row with a backticked .sh path in a carrier argument" \
  'gh issue comment 1 --body "| step | `./tmp/x.sh` | run it |"'

exec_notflag_case "T-EXEC-7 must-not-flag: system-bin interpreter for another language" \
  '/usr/bin/python3 script.py'

exec_notflag_case "T-EXEC-8 must-not-flag: PATH-resolved utility, no slash (arm never reached)" \
  'git status'

exec_notflag_case "T-EXEC-8b must-not-flag: PATH-resolved utility with flags" \
  'ls -la'

# RECORDED RESIDUAL, PINNED. `./x` with no extension escapes this arm -- and
# already escapes the interpreter arm, which does not adjudicate `bash /tmp/evil`
# either. It is one residual shared by three arms, not a new gap. Pinning it here
# means a future widening to the source arm's `/*` domain is a deliberate act
# that turns this case red, rather than a drift nobody notices.
exec_notflag_case "T-EXEC-9 must-not-flag: extensionless direct execution (recorded residual, pinned)" \
  './tmp/evil'

# --- PHASE DISCRIMINATION ----------------------------------------------------
# Everything above is satisfiable by an arm that adjudicates and then always
# allows. This case is what proves the phase gate is a gate: the SAME must-flag
# input against a copy of the hook whose only difference is the phase constant
# must exit 2. The copy lives beside the hook so HOOK_DIR still resolves lib/ and
# the allowlist; it is removed immediately after.
B022_PHASE_PROBE="${HOOK%/*}/.block-destructive-phase-probe.sh"
/usr/bin/sed 's/^readonly DESTRUCTIVE_022_EXEC_PHASE=.*/readonly DESTRUCTIVE_022_EXEC_PHASE="enforce"/' \
  "$HOOK" > "$B022_PHASE_PROBE"
/bin/chmod +x "$B022_PHASE_PROBE"
b022_probe_rc=0
b022_probe_err="$(/usr/bin/printf '%s' "$(bash_payload '/tmp/pmo-probe-not-allowlisted-xyz.sh')" \
  | /bin/bash "$B022_PHASE_PROBE" 2>&1 >/dev/null)" || b022_probe_rc="$?"
/bin/rm -f "$B022_PHASE_PROBE"
case "${b022_probe_rc}:${b022_probe_err}" in
  2:*BLOCK-DESTRUCTIVE-022*)
    /usr/bin/printf 'PASS: T-EXEC-10 phase discrimination: the same input blocks at rollout=enforce\n'
    PASS=$((PASS + 1))
    ;;
  *)
    /usr/bin/printf 'FAIL: T-EXEC-10 phase discrimination: expected exit 2 + BLOCK-DESTRUCTIVE-022 at rollout=enforce\n  rc=%s stderr=%s\n' \
      "$b022_probe_rc" "$b022_probe_err"
    FAIL=$((FAIL + 1))
    ;;
esac

# ==========================================================================
# BLOCK-022 F1 — normalization must not MANUFACTURE an allow (deny-don't-sanitize)
# ==========================================================================
#
# THE BYPASS THIS BLOCK PINS, and it is the inverse of the one the parity block
# above pins. There, normalization was too WEAK: residual punctuation defeated a
# suffix-anchored filter and a real target was never adjudicated. Here it was too
# STRONG: the trailing-strip loop ran through a SELF-QUOTED token's own closing
# quote and kept eating characters that were literal filename content.
#
#     source './core/deploy/deploy.sh)'
#
# runs a file named `deploy.sh)` — not allowlisted, must BLOCK. The hook
# normalized it to `deploy.sh` — allowlisted — and permitted. All TEN characters
# the function declares it strips flip BLOCK to ALLOW in that spelling, so this
# block carries one arm per character rather than one arm for the class: the
# class claim is what the shipped comment made, and it was the per-character
# measurement that falsified it.
#
# WHY THE SHIPPED COMMENT DID NOT CATCH IT. It asserted a DIRECTION OF ERROR —
# that stripping "only ever makes a token MORE likely to reach the allowlist,
# never more likely to bypass it" — and had no arm behind that assertion. The
# reasoning was sound for the CARVE-OUT set (`{ } [ ] , . -`, which it explicitly
# audited) and was never carried to the stripped set. So the carve-out arms below
# are not decoration: they are the half of the claim that was always true, kept
# beside the half that was not, and the pair is what makes the corrected comment
# falsifiable in both directions.
#
# THE TWO INPUTS THIS BLOCK MUST HOLD APART. They are one character different and
# a naive rule collapses them:
#
#   'core/deploy/deploy.sh)'   real file `…/deploy.sh)`  -> BLOCK (F1-DISCRIM-block)
#   core/deploy/deploy.sh)"    real file `…/deploy.sh`   -> ALLOW (F1-DISCRIM-allow)
#
# The second is the command-substitution tail the parity block above exists to
# fix. Collapsing them in the safe direction would discard that fix entirely, so
# F1-DISCRIM-allow is a MUST-NOT-REGRESS arm and is asserted at the same rank as
# the must-block arms. The discriminator is whether the token OPENED its own
# quote: if it did, everything to the matching close is filename; if it did not,
# the trailing run is foreign syntax and strips as before.

echo ""
echo "BLOCK-022 F1 deny-don't-sanitize (self-quoted token normalization)"
echo "---"

F1_OK='./core/deploy/deploy.sh'         # allowlisted in every form used below
F1_EVIL='./core/deploy/notallowed.sh'   # never allowlisted

# The ten characters normalize_script_token declares it strips, and the four it
# declares it does NOT. Kept as data so a future edit to the stripped set that
# forgets to extend this table is visible as a count mismatch rather than as
# silent under-coverage.
F1_STRIPPED=( '"' "'" '`' '(' ')' ';' '&' '|' '<' '>' )
F1_STRIPPED_NAMES=( dquote squote backtick lparen rparen semi amp pipe lt gt )
F1_CARVE=( '.' '-' ']' ',' )
F1_CARVE_NAMES=( dot dash rbracket comma )

if [ "${#F1_STRIPPED[@]}" != "10" ] || [ "${#F1_CARVE[@]}" != "4" ]; then
  /usr/bin/printf 'FAIL: F1 table arity: stripped=%s(want 10) carve=%s(want 4)\n' \
    "${#F1_STRIPPED[@]}" "${#F1_CARVE[@]}"
  FAIL=$((FAIL + 1))
fi

# `<verb> '<path><char>'` — the self-quoted spelling. printf keeps the quotes
# literal; nothing here is evaluated by this shell.
f1_quoted_cmd() { /usr/bin/printf "%s '%s%s'" "$1" "$2" "$3"; }

# --- MUST-BLOCK: one arm per declared-stripped character.
#
# THESE RUN ON THE SOURCE ARM, AND THE CHOICE IS FORCED, NOT CONVENIENT. The
# source arm's operand filter carries PREFIX alternatives (`/*`, `./*`, `../*`,
# `~/*`), so every one of these ten spellings lands inside its declared operand
# domain and the arm is obliged to adjudicate all ten. The interpreter arm's
# filter is SUFFIX-anchored (`*.sh`), so a correctly-resolved `…/deploy.sh)` is
# outside ITS declared domain — see the residual pair below, which pins that
# boundary rather than hiding it. Running the table on the arm whose domain
# contains every case is what keeps a red arm meaning "the fix regressed" instead
# of "this arm never covered it".
f1_i=0
while [ "$f1_i" -lt "${#F1_STRIPPED[@]}" ]; do
  f1_c="${F1_STRIPPED[$f1_i]}"
  f1_n="${F1_STRIPPED_NAMES[$f1_i]}"
  test_case "F1-QUOTED-${f1_n}/source: quoted allowlisted path + '${f1_n}' is a DIFFERENT file, blocks" \
    "$(bash_payload "$(f1_quoted_cmd source "$F1_OK" "$f1_c")")" \
    2 "BLOCK-DESTRUCTIVE-022"
  f1_i=$((f1_i + 1))
done

# --- THE INTERPRETER ARM, AND THE BOUNDARY OF ITS DECLARED DOMAIN.
#
# Four of the ten characters reach the interpreter arm even though its filter is
# suffix-anchored, and they do so for two nameable reasons rather than by luck:
#   `;` `&` `|` are SEPARATORS, so the segment splitter truncates the token
#       before normalization sees it and the operand arrives as `'…/deploy.sh` —
#       an unclosed quote whose filter probe is the bare `.sh` path;
#   `'`     RE-OPENS a quote after the first one closes, so the token resolves to
#       nothing single and its filter probe is again the bare `.sh` path.
# In all four the probe is inside `*.sh` and the arm denies. Each was
# demonstrated failing against the pre-fix hook.
for f1_pair in "squote:'" "semi:;" "amp:&" "pipe:|"; do
  test_case "F1-QUOTED-${f1_pair%%:*}/interp: unresolvable token with an in-domain probe blocks" \
    "$(bash_payload "$(f1_quoted_cmd bash "$F1_OK" "${f1_pair#*:}")")" \
    2 "BLOCK-DESTRUCTIVE-022"
done

# The other six resolve CLEANLY to a filename ending in the character — and that
# filename is not `.sh`-suffixed, so it falls outside the interpreter arm's
# declared operand domain and the arm does not adjudicate it. This arm expects
# ALLOW and it passed before the fix as well, so it is NOT evidence the fix
# works; it is a PIN on a pre-existing residual, in the same spirit as T-EXEC-9.
#
# THE RESIDUAL IT PINS is the one already recorded for this rule: both the
# interpreter and exec arms are suffix-anchored, so an operand outside `*.sh`
# escapes them (`bash /tmp/evil` escapes for the identical reason). The fix
# CHANGED THE MECHANISM without changing this verdict: before, the hook actively
# matched a DIFFERENT file against the allowlist and permitted on that match;
# now it declines to adjudicate a target outside its filter. The first is a
# bypass, the second is a declared boundary — but the executed file is still not
# blocked HERE, and the source arm is what covers it.
#
# Closing it means widening the interpreter arm's filter, which the shipped
# comment on the source arm forbids and which is outside this change. Widen it
# and this arm turns red, which is the point of having it.
test_case "F1-INTERP-RESIDUAL (pin, not fix-evidence): a resolved non-.sh filename is outside the interpreter arm's domain" \
  "$(bash_payload "bash './core/deploy/deploy.sh)'")" \
  0

# The same input on the SOURCE arm, stated immediately beside it so the pair
# reads as one fact: the residual is a property of the interpreter arm's filter,
# not of the normalization. Same token, same resolution, opposite verdict,
# because one arm's declared domain contains the target and the other's does not.
test_case "F1-INTERP-RESIDUAL pair: the identical token on the source arm DOES block" \
  "$(bash_payload "source './core/deploy/deploy.sh)'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# --- CARVE-OUT: the four characters the function declares it does NOT strip.
# These blocked before the fix and must keep blocking after it. They are the
# control that proves the probe DISCRIMINATES — a probe that reported BLOCK for
# every trailing character would report the fix as working while proving nothing.
f1_i=0
while [ "$f1_i" -lt "${#F1_CARVE[@]}" ]; do
  test_case "F1-CARVE-${F1_CARVE_NAMES[$f1_i]}: unstripped character keeps blocking (control)" \
    "$(bash_payload "$(f1_quoted_cmd source "$F1_OK" "${F1_CARVE[$f1_i]}")")" \
    2 "BLOCK-DESTRUCTIVE-022"
  f1_i=$((f1_i + 1))
done

# --- THE DISCRIMINATION PAIR, stated as two named arms so a reader can find it.
test_case "F1-DISCRIM-block: self-quoted token whose real filename ends ')' blocks" \
  "$(bash_payload "source './core/deploy/deploy.sh)'")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-DISCRIM-allow: command-substitution tail on an allowlisted path still ALLOWS" \
  "$(bash_payload 'bash ./core/deploy/deploy.sh)"')" \
  0

# --- MUST-NOT-REGRESS: every legitimate spelling the normalization was built for.
test_case "F1-ALLOW-tail: enclosed substitution tail, allowlisted, allows" \
  "$(bash_payload 'echo "$(cd /tmp && bash ./core/deploy/deploy.sh)"')" \
  0

test_case "F1-ALLOW-halfdquote: half-quoted tail, allowlisted, allows" \
  "$(bash_payload 'bash ./core/deploy/deploy.sh"')" \
  0

test_case "F1-ALLOW-dquote: plainly double-quoted allowlisted path allows" \
  "$(bash_payload 'bash "./core/deploy/deploy.sh"')" \
  0

test_case "F1-ALLOW-squote: plainly single-quoted allowlisted path allows" \
  "$(bash_payload "bash './core/deploy/deploy.sh'")" \
  0

test_case "F1-ALLOW-source-squote: plainly single-quoted allowlisted path allows on the source arm" \
  "$(bash_payload "source './core/deploy/deploy.sh'")" \
  0

# --- SENSITIVITY CONTROLS for the must-allow arms. Without these the whole
# must-allow set is satisfiable by a hook that allows everything in those shapes.
test_case "F1-CTL-tail: the same tail shape with a NON-allowlisted path blocks" \
  "$(bash_payload 'bash ./core/deploy/notallowed.sh)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-CTL-enclosed: the same enclosed shape with a NON-allowlisted path blocks" \
  "$(bash_payload 'echo "$(cd /tmp && bash ./core/deploy/notallowed.sh)"')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-CTL-squote: the same single-quoted shape with a NON-allowlisted path blocks" \
  "$(bash_payload "bash './core/deploy/notallowed.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# --- FALSE-POSITIVE CONTROL for the deny channel, and the reason the unresolvable
# verdict is gated behind each arm's operand filter rather than raised the moment a
# quote fails to close. Segment splitting hands the `-c` arm the fragment `'echo`,
# which opens a quote it never closes. Denying on that alone would block every
# `bash -c '… ; …'` in the workspace. Raise the deny above the filter and this
# arm goes red, which is the point of having it.
test_case "F1-FP-cmode: bash -c with a separator inside the program string still allows" \
  "$(bash_payload "bash -c 'echo a; echo b'")" \
  0

test_case "F1-FP-spacepath: an unclosed quote outside the operand domain is not a verdict" \
  "$(bash_payload "git commit -m 'two words'")" \
  0

# ==========================================================================
# BLOCK-022 F1 CONCAT — quote-adjacent concatenation: the filter's SUBJECT
# ==========================================================================
#
# THE DEFECT THESE ARMS PIN. `bash '/tmp/'evil.sh` is ordinary shell
# concatenation — the shell runs the real, non-allowlisted /tmp/evil.sh. The
# token opens a quote, closes it, then CONTINUES, so normalize_script_token
# correctly declines to resolve it (script_norm_ok=0) and returns `/tmp/` as a
# FILTER PROBE. That probe is a strict PREFIX. The interpreter arm's operand
# filter is SUFFIX-anchored (`*.sh`). `/tmp/` ends in no suffix, so the arm read
# the token as outside its own domain and skipped — and the deny that the ok=0
# verdict had ALREADY reached was never raised. `main` and the first remediation
# both DENIED this input; the second remediation regressed it to a silent ALLOW,
# and 1079 green assertions coexisted with the regression because no arm in this
# file covered the shape.
#
# WHY A FAMILY AND NOT ONE ARM. The quote can sit at five different places in the
# token and each truncates the probe differently — to `/tmp/`, to `/tmp/evil`, to
# `/`, and to the empty string. One arm pins one truncation and leaves the rest
# free to regress independently.
#
# THE SIXTH ROW IS A CONTROL AND IS NOT FIX-EVIDENCE. `/tmp/'evil'.sh` does not
# OPEN its own quote, so it resolves cleanly, its subject ends `.sh`, and it
# blocked before this fix as well. It is here because a probe that reported BLOCK
# for every quote-bearing spelling would report the fix as working while proving
# nothing about the truncation.
#
# THE OPPOSITE DIRECTION IS PINNED TOO, and it is why the domain gate reads BOTH
# the probe and the raw argv token rather than swapping one for the other:
#   probe-only  is the defect above;
#   raw-only    would lose F1-QUOTED-squote/interp above, whose RAW token ends
#               `''` and whose PROBE is the half that lands inside the domain.
# Those arms and these must stay green together, or the subject rule has been
# replaced rather than corrected.

echo ""
echo "BLOCK-022 F1 CONCAT (quote-adjacent concatenation reaches the deny)"
echo "---"

# Every arm below executes the SAME real file, /tmp/pmo-concat-probe-na.sh, which
# is not allowlisted in any spelling. Only the quote position moves.
test_case "F1-CONCAT-squote-prefix: bash '<dir>/'name.sh blocks (probe truncates to the dir)" \
  "$(bash_payload "bash '/tmp/'pmo-concat-probe-na.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-CONCAT-dquote-prefix: bash \"<dir>/\"name.sh blocks (same, double-quoted)" \
  "$(bash_payload 'bash "/tmp/"pmo-concat-probe-na.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-CONCAT-squote-stem: bash '<dir>/<stem>'.sh blocks (probe keeps the stem, loses the suffix)" \
  "$(bash_payload "bash '/tmp/pmo-concat-probe-na'.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-CONCAT-empty-squote: bash ''<path> blocks (probe truncates to the EMPTY string)" \
  "$(bash_payload "bash ''/tmp/pmo-concat-probe-na.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-CONCAT-squote-root: bash '/'<rest> blocks (probe truncates to the root slash)" \
  "$(bash_payload "bash '/'tmp/pmo-concat-probe-na.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

# CONTROL — this one never flipped. It resolves cleanly because the token does not
# open its own quote, so it is a discrimination control, NOT evidence for the fix.
test_case "F1-CONCAT-ctl-inner (control, not fix-evidence): an inner-quoted token resolves and blocks" \
  "$(bash_payload "bash /tmp/'pmo-concat-probe-na'.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

# The SOURCE arm never had this defect, and stating that as an arm is what keeps
# the asymmetry visible: its domain carries PREFIX alternatives (`/*`), so the
# truncated probe `/tmp/` lands inside it and the arm always denied. If this ever
# goes red the source arm's domain has been narrowed toward the interpreter arm's,
# which the shipped comment on that arm forbids.
test_case "F1-CONCAT-source (asymmetry pin): the same spelling on the source arm blocks" \
  "$(bash_payload "source '/tmp/'pmo-concat-probe-na.sh")" \
  2 "BLOCK-DESTRUCTIVE-022"

# The EXEC-arm twins. Same defect, same rule, different arm — and because the arm
# ships at `warn` both an adjudicated and a skipped input exit 0, so only the drain
# separates "evaluated" from "never evaluated". `unresolvable` is the correct cause
# class here: there is no allowlist row that could ever match an unclosed token.
exec_warn_case "F1-CONCAT-exec must-flag: quote-adjacent concatenation at command position is adjudicated" \
  "'/tmp/'pmo-concat-probe-na.sh" 'unresolvable'

# The empty-probe spelling reaches the exec arm one layer EARLIER than the operand
# filter — at the POSIX 2.9.1.1 slash test that decides whether the command word is
# a pathname at all. Its probe is the empty string, which holds no slash, so the
# candidate was dropped before any filter saw it.
exec_warn_case "F1-CONCAT-exec-empty must-flag: an empty probe does not hide a pathname execution" \
  "''/tmp/pmo-concat-probe-na.sh" 'unresolvable'

# FALSE-POSITIVE CONTROL for the widened subject. The raw token is now consulted
# whenever a token fails to resolve, so a `.sh` appearing in NON-executing text
# inside a suppressed quoted argument must still not produce a verdict. Without
# this arm the widening is satisfiable by a hook that denies on any `.sh` anywhere.
test_case "F1-CONCAT-fp-quoted-arg: a .sh named inside a suppressed quoted argument is not a verdict" \
  "$(bash_payload "gh issue comment 1 --body 'see /tmp/pmo-concat-probe-na.sh; done'")" \
  0

# ==========================================================================
# BLOCK-022 F1 — the exec arm's exemption set is not ANCHOR_PREFIX_BASH's
# ==========================================================================
#
# THE GAP THIS BLOCK PINS. The exec arm exempted five "system bin" prefixes,
# adopted verbatim from ANCHOR_PREFIX_BASH "so this file keeps ONE definition of
# system bin". One of the five, `/opt/homebrew/bin`, is mode 0775 owned by the
# operator's admin group on the reference host — writable by the agent WITHOUT
# elevation. So `/opt/homebrew/bin/x.sh` executed directly was exempt from
# adjudication entirely, while `bash /opt/homebrew/bin/x.sh` blocked: the
# allowlist was bypassable by dropping the interpreter word and writing into a
# directory the agent already owns, which is the exact script-laundering route
# the rule's own block message names.
#
# THE ROOT CAUSE IS THE REUSE, NOT THE ENTRY. ANCHOR_PREFIX_BASH's prefixes
# identify the INTERPRETER BINARY — a trusted-SOURCE question where adding a
# directory only widens what counts as a command start. The exec arm used them to
# exempt the EXECUTION TARGET — an untrusted-TARGET question where adding a
# directory REMOVES coverage. One list cannot answer both inverted questions, so
# the exec arm now owns its own set and the anchor is deliberately unchanged.
#
# WHY THESE ARMS READ THE DRAIN. Same reason as the exec block above: the arm
# ships at `warn`, so both an adjudicated and an exempt input exit 0. Only the
# drain delta separates "evaluated and denied" from "never evaluated", which is
# exactly the distinction this gap is about.

echo ""
echo "BLOCK-022 F1 exec-arm exemption set (agent-writable prefix is not a system bin)"
echo "---"

exec_warn_case "F1-EXEC-homebrew must-flag: direct execution under the agent-writable /opt/homebrew/bin is adjudicated" \
  '/opt/homebrew/bin/pmo-probe-not-allowlisted-xyz.sh' 'not-allowlisted'

exec_warn_case "F1-EXEC-homebrew-flag must-flag: same prefix with a flag" \
  '/opt/homebrew/bin/pmo-probe-not-allowlisted-xyz.sh --check' 'not-allowlisted'

# The asymmetry that made the gap visible: the SAME file via an interpreter was
# always blocked. If this arm ever goes green-by-allow the exemption has leaked
# back into the interpreter arm too.
test_case "F1-EXEC-homebrew-interp control: the same file via an interpreter blocks" \
  "$(bash_payload 'bash /opt/homebrew/bin/pmo-probe-not-allowlisted-xyz.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# The four root-owned prefixes KEEP their exemption. This is what makes the
# change a narrowing rather than a rewrite: drop one of these by accident and the
# corresponding arm turns red.
exec_notflag_case "F1-EXEC-ctl-usr-bin must-not-flag: /usr/bin stays exempt (root:wheel, 0755)" \
  '/usr/bin/pmo-probe-not-allowlisted-xyz.sh'

exec_notflag_case "F1-EXEC-ctl-bin must-not-flag: /bin stays exempt (root:wheel, 0755)" \
  '/bin/pmo-probe-not-allowlisted-xyz.sh'

exec_notflag_case "F1-EXEC-ctl-usr-local-bin must-not-flag: /usr/local/bin stays exempt (root:wheel, 0755)" \
  '/usr/local/bin/pmo-probe-not-allowlisted-xyz.sh'

exec_notflag_case "F1-EXEC-ctl-opt-local-bin must-not-flag: /opt/local/bin stays exempt (root:wheel, 0755)" \
  '/opt/local/bin/pmo-probe-not-allowlisted-xyz.sh'

# --- THE EXEMPTION MUST DECIDE ON A RESOLVED PATH, NOT ON THE TOKEN.
#
# THE GAP THESE ARMS PIN. The exemption above was a GLOB against the raw token, and
# a token is not a location. `/usr/bin/../../tmp/evil.sh` matches `/usr/bin/*` and
# executes `/tmp/evil.sh`: the exec arm exempted it and never adjudicated it, while
# `bash /usr/bin/../../tmp/evil.sh` — the same file, through the interpreter arm of
# the SAME rule — blocked. Same file, same hook, opposite verdicts. An exemption
# must read the thing whose behaviour it claims to govern, and what this one
# governs is a file LOCATION.
#
# ONE ARM PER EXEMPTED PREFIX, because the prefixes are four independent rows in
# one `case` and a fix that resolves only the first would leave three live.
#
# WHY THESE READ THE DRAIN. Same reason as the block above: the arm ships at
# `warn`, so an exempted input and an adjudicated one both exit 0. Only the drain
# delta separates "evaluated and denied" from "never evaluated" — which is exactly
# the distinction this gap is about.
exec_warn_case "F1-EXEC-esc-usr-bin must-flag: a traversal out of /usr/bin is not exempt" \
  '/usr/bin/../../tmp/pmo-probe-not-allowlisted-xyz.sh' 'not-allowlisted'

exec_warn_case "F1-EXEC-esc-bin must-flag: a traversal out of /bin is not exempt" \
  '/bin/../tmp/pmo-probe-not-allowlisted-xyz.sh' 'not-allowlisted'

exec_warn_case "F1-EXEC-esc-usr-local-bin must-flag: a traversal out of /usr/local/bin is not exempt" \
  '/usr/local/bin/../../../tmp/pmo-probe-not-allowlisted-xyz.sh' 'not-allowlisted'

exec_warn_case "F1-EXEC-esc-opt-local-bin must-flag: a traversal out of /opt/local/bin is not exempt" \
  '/opt/local/bin/../../../tmp/pmo-probe-not-allowlisted-xyz.sh' 'not-allowlisted'

# The asymmetry that made the gap visible, stated as an arm: the SAME file through
# the interpreter arm always blocked. If this ever goes green-by-allow the
# exemption has leaked across into the interpreter arm too.
test_case "F1-EXEC-esc-interp control: the identical traversal via an interpreter blocks" \
  "$(bash_payload 'bash /usr/bin/../../tmp/pmo-probe-not-allowlisted-xyz.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# An UNRESOLVABLE token can never be exempt: if the filename cannot be determined
# from argv it cannot be shown to live in a trusted directory. Without that rule
# the probe `/usr/bin/` left by this token satisfies the entry glob on its own,
# and the exemption is reachable by quoting rather than by location.
exec_warn_case "F1-EXEC-esc-unresolvable must-flag: an unresolvable token is never exempt" \
  "'/usr/bin/'../../tmp/pmo-probe-not-allowlisted-xyz.sh" 'unresolvable'

# MUST-NOT-FLAG SENSITIVITY CONTROL, and it is the one that proves the check
# RESOLVES rather than merely rejecting every `..`. This traversal leaves and
# re-enters the exempted directory, so the file it executes really is under
# /usr/bin and the exemption must still hold. An implementation that blanket-denied
# `..` would satisfy every must-flag arm above and fail here.
exec_notflag_case "F1-EXEC-ctl-inner-dotdot must-not-flag: a traversal that RESOLVES back under /usr/bin stays exempt" \
  '/usr/bin/../bin/pmo-probe-not-allowlisted-xyz.sh'

# ==========================================================================
# BLOCK-022 F1 QTOK — the FLAG WALK's and the VERB RESOLVER's subject
# ==========================================================================
#
# THE DEFECT THESE ARMS PIN, AND IT IS THE SAME SHAPE AS EVERY F1 BLOCK ABOVE:
# a matcher deciding on a token that is not the thing whose behaviour it claims
# to govern. Normalization was introduced one layer at a time — first at the
# operand, then at the exec arm's exemption — and TWO readers upstream of both
# were left reading raw argv:
#
#   THE FLAG WALK reads the raw token to decide "is this a flag I skip past".
#   `'-x'` does not START with `-`, so the walk stopped there and adjudicated
#   `-x` as though it were the operand. `-x` is in no arm's operand domain, so
#   nothing was adjudicated and the REAL script — the next token — was never
#   looked at. `bash '-x' <script>` allowed; `bash -x <script>` blocked. One
#   quote apart, opposite verdicts.
#
#   THE VERB RESOLVER reads the raw basename to decide which arm owns the
#   segment. `"bash"` is not `bash`, so the interpreter arm was never entered;
#   the token fell through to the exec `*)` branch, which normalized it, found a
#   command word with no `.sh`/`.bash` suffix, and correctly declined. Both arms
#   declined and the invocation was never adjudicated by either.
#
# THESE ARE TWO ROOT CAUSES, NOT ONE, and they are pinned as two families so a
# fix to one cannot be read as covering the other.
#
# WHY THE SKIP IS THE DANGEROUS HALF, AND WHAT CONSTRAINS THE FIX. Skipping a
# token REMOVES it from adjudication, so the flag walk is an exemption in the
# same sense `script_exempt_system_bin` is — and an exemption may only ever
# NARROW. A naive "normalize, then test `-*`" widens it instead, and flips a
# shipped BLOCK to an ALLOW: `bash '-x.sh'` normalizes to `-x.sh`, which is
# flag-shaped, so a naive fix skips it — and `-x.sh` is exactly the token the
# interpreter arm's operand domain already claimed and already blocked. Arm
# F1-QFLAG-ctl-domain is that over-correction control and it was GREEN before
# this change: a fix that turns it red has swapped the subject rather than added
# a view, which is the failure mode three prior remediations of this rule share.
#
# THE RESIDUAL THIS BLOCK DOES NOT CLOSE is pinned at the bottom
# (F1-QTOK-RESIDUAL-space) rather than left to be discovered.

echo ""
echo "BLOCK-022 F1 QTOK (quoted flag / quoted verb reach their arms)"
echo "---"

# Never allowlisted in any spelling. Only the quoting of the FLAG moves.
QTOK_NA='/tmp/pmo-qtok-probe-na.sh'

# --- FAMILY 1: the quoted FLAG (the flag walk's subject) ---------------------
test_case "F1-QFLAG-x: bash '-x' <script> blocks (quoted flag is still a flag)" \
  "$(bash_payload "bash '-x' ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-QFLAG-v: bash '-v' <script> blocks" \
  "$(bash_payload "bash '-v' ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-QFLAG-ddash: bash '--' <script> blocks (quoted end-of-options)" \
  "$(bash_payload "bash '--' ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

# The double-quoted spelling is a SEPARATE arm for the same reason the F1-QUOTED
# block carries one arm per stripped character: the class claim is what the code
# asserted, and only a per-spelling measurement falsifies it.
test_case "F1-QFLAG-dq: bash \"-x\" <script> blocks (double-quoted flag)" \
  "$(bash_payload "bash \"-x\" ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

# The flag walk is SHARED by the source arm, so the defect was too.
test_case "F1-QFLAG-source: source '-x' <file> blocks (shared flag walk)" \
  "$(bash_payload "source '-x' ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

# --- FAMILY 2: the quoted VERB (the verb resolver's subject) -----------------
test_case "F1-QVERB-dq-bash: \"bash\" <script> blocks (quoted interpreter verb)" \
  "$(bash_payload "\"bash\" ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-QVERB-sq-sh: 'sh' <script> blocks" \
  "$(bash_payload "'sh' ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

# The ABSOLUTE quoted spelling failed through a SECOND mechanism and is therefore
# its own arm: `"/bin/bash"` missed the verb set on its raw basename, fell to the
# exec `*)` branch, and was then EXEMPTED there as a system-bin path — so the
# interpreter binary itself carried the operand past both arms.
test_case "F1-QVERB-abs: \"/bin/bash\" <script> blocks (quoted absolute interpreter)" \
  "$(bash_payload "\"/bin/bash\" ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "F1-QVERB-source: 'source' <file> blocks (quoted source verb)" \
  "$(bash_payload "'source' ${QTOK_NA}")" \
  2 "BLOCK-DESTRUCTIVE-022"

# --- OVER-CORRECTION CONTROLS -----------------------------------------------
# THE one that matters. GREEN BEFORE THIS CHANGE. `'-x.sh'` normalizes to a
# flag-shaped token that is ALSO inside the interpreter arm's operand domain.
# The domain claim wins: it is an operand, not a flag, and it must keep blocking.
# A fix that normalizes and then tests `-*` skips it and turns this red.
test_case "F1-QFLAG-ctl-domain (over-correction control): a normalized flag-shaped token INSIDE the operand domain is still an operand" \
  "$(bash_payload "bash '-x.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# The RAW view must keep deciding first and alone. `-x.sh` is raw-flag-shaped and
# has always been skipped; the domain guard above must not retroactively reach it,
# or the change stops being additive and starts re-adjudicating shipped shapes.
test_case "F1-QFLAG-ctl-rawflag (over-correction control): a RAW flag-shaped token is skipped exactly as before" \
  "$(bash_payload 'bash -x.sh')" \
  0

# Availability control: the fix must reach the ALLOWLIST, not deny the class.
test_case "F1-QFLAG-ctl-allow: an allowlisted script behind a quoted flag still ALLOWS" \
  "$(bash_payload "bash '-x' core/deploy/deploy.sh")" \
  0

# A quoted `-c` now enters cmode, where the tokens are WORDS OF A PROGRAM STRING.
# The operand-domain gate must keep them inert — the same property F1-FP-cmode
# pins for the unquoted spelling, restated for the route this change opens.
test_case "F1-QFLAG-ctl-cmode: quoted -c enters cmode without over-blocking its program string" \
  "$(bash_payload "bash '-c' 'echo a; echo b'")" \
  0

# The verb widening must ADD a view, never STEAL tokens from the exec arm. A
# quoted non-verb command word must still reach exec and still flag. GREEN BEFORE
# THIS CHANGE — a fix that reroutes quoted command words wholesale turns it red.
exec_warn_case "F1-QVERB-ctl-exec (over-correction control): a quoted NON-verb command word still reaches the exec arm" \
  "\"/tmp/pmo-qtok-probe-na.sh\"" 'not-allowlisted'

# False-positive control for the verb widening: an interpreter named in
# NON-executing text inside a suppressed quoted argument is still not a verdict.
test_case "F1-QVERB-ctl-fp: a quoted verb named inside a suppressed quoted argument is not a verdict" \
  "$(bash_payload "gh issue comment 1 --body 'run \"bash\" ${QTOK_NA} now'")" \
  0

# --- DECLARED RESIDUAL (pin, NOT fix-evidence) ------------------------------
# A SPACE-BEARING quoted path is a different root cause from either family above
# and is NOT closed by this change. Tokenization splits raw argv on whitespace
# BEFORE any normalization runs, so the operand token is `'/tmp/pmo` — the real
# filename's first fragment. Neither the probe nor the raw token ends `.sh`, so
# no arm's operand domain is implicated and nothing is adjudicated. Closing it
# requires QUOTE-AWARE TOKENIZATION, which is a change to the primitive every arm
# traverses; it is declared in
# core/rules/bypass-mode-readiness/block-destructive.md rather than half-closed
# here. This arm asserts the CURRENT verdict so that widening it later is a
# deliberate act rather than a drift — the same convention as F1-INTERP-RESIDUAL.
test_case "F1-QTOK-RESIDUAL-space (pin, not fix-evidence): a space-bearing quoted operand is split before normalization and is NOT adjudicated" \
  "$(bash_payload "bash '/tmp/pmo qtok probe na.sh'")" \
  0

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

# --- BLOCK-DESTRUCTIVE-019 analysis-workspace carve-out (#6427) ---
#
# The second -019 exemption: the git-ignored analysis workspace. Three must-ALLOW
# arms and five discrimination partners. The discrimination partners are not
# decoration — each is a SPECIFIC WIDENING the naive `analysis/`* predicate would
# have introduced, and two of them (A5, A6) were confirmed live against that
# predicate before this design was settled.
#
# Environment-independence: `hookfix-2026-01-01` and `zz-nonexistent` are chosen
# NOT to exist on any runner, so the hook's [ -e "$FILE_PATH" ] test takes the
# raw/parent-fallback branch deterministically. These arms add no dependency on an
# on-disk file, unlike the pre-existing ../-escape arms below which require
# $HOME/Claude/CLAUDE.md to exist.

# A1 — the defect itself. Non-worktree cwd, dated analysis subfolder → allow.
test_case "Write analysis/<subfolder>/SUMMARY.md with primary cwd allows (carve-out)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/hookfix-2026-01-01/SUMMARY.md' ''"$HOME"'/Claude')" \
  0

# A2 — Edit parity. The card says "a Write (or Edit)"; both tool names reach -019.
test_case "Edit analysis/<subfolder>/SUMMARY.md with primary cwd allows (carve-out)" \
  "$(edit_payload ''"$HOME"'/Claude/pmo-platform/analysis/hookfix-2026-01-01/SUMMARY.md' ''"$HOME"'/Claude')" \
  0

# A3 — depth 3. The standard's §2 support folders (evidence/, _scores/, issue-drafts/).
test_case "Write analysis/<subfolder>/evidence/probe.md with primary cwd allows (carve-out depth 3)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/hookfix-2026-01-01/evidence/probe.md' ''"$HOME"'/Claude')" \
  0

# A4 — THE PIN (card AC2). A TRACKED Layer-1 path from the same session still blocks.
# This is what proves the carve-out did not widen past its own subtree.
test_case "Write pmo-platform/core/x.md with primary cwd still blocks (carve-out did not widen)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/core/zz-carveout-probe.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# A5 — the one TRACKED file INSIDE the carve-out folder. .gitignore is
# `/analysis/*` + `!/analysis/README.md`, so README.md is tracked Layer 1 and a
# bare `analysis/`* predicate would have admitted it. The subfolder segment is
# what excludes it, and this arm is that guard's teeth.
test_case "Write analysis/README.md with primary cwd still blocks (tracked file, no subfolder segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/README.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# A6 — the ../ escape through the raw-path fallback. Neither the target nor its
# parent exists, so abs_target is the RAW un-normalized FILE_PATH with `..`
# intact; a `case` glob matches across `/`, so without the traversal arm this
# would match the carve-out pattern while naming a tracked Layer-1 file.
test_case "Write analysis/../core/x.md with primary cwd still blocks (traversal guard)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/../core/zz-nonexistent/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# A7 — sibling PREFIX does not widen. `analysis-notes` is not `analysis/`.
test_case "Write pmo-platform/analysis-notes/x.md with primary cwd still blocks (prefix is not a segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis-notes/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# A8 — the pattern is REPO-ROOT-ANCHORED. A differently-located directory named
# `analysis` is not exempt; this admits exactly one subtree, not every such dir.
test_case "Write pmo-platform/release/analysis/x.md with primary cwd still blocks (repo-root-anchored)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/release/analysis/x.md' ''"$HOME"'/Claude')" \
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
