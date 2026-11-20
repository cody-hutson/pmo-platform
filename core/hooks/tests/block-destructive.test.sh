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

# --- EXT-POS (#8314): the canonicalizer walks a wrapper's own grammar ---
#
# The canonicalizer stopped at a wrapper's first flag, matched a prefix word as an exact
# token, and omitted three wrappers and the condition keywords, so the identical deletion
# reached this rule in plain form and did not behind any of those spellings. Each case is
# the plain-form refusal above (AC-004), reached through one face: a wrapper option that
# takes a separate argument (D6, D8, D10), a wrapper flag that takes none (D7, D16), an
# absolute-path wrapper (D9), a wrapper missing from the set (D10-D12), a condition
# position (D13-D15), and a quoted or escaped wrapper word (D17, D18).
test_case "EXT-POS-D6: sudo -u root rm -rf / blocks (wrapper option with a separate argument)" \
  "$(bash_payload 'sudo -u root rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D7: sudo -n rm -rf / blocks (wrapper flag that takes no argument)" \
  "$(bash_payload 'sudo -n rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D8: env -u X rm -rf / blocks (wrapper option with a separate argument)" \
  "$(bash_payload 'env -u X rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D9: /usr/bin/env rm -rf / blocks (absolute-path wrapper)" \
  "$(bash_payload '/usr/bin/env rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D10: nice -n 10 rm -rf / blocks (wrapper missing from the set, with its option)" \
  "$(bash_payload 'nice -n 10 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D11: stdbuf -o0 rm -rf / blocks (wrapper missing from the set)" \
  "$(bash_payload 'stdbuf -o0 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D12: timeout 5 rm -rf / blocks (wrapper missing from the set, with its duration)" \
  "$(bash_payload 'timeout 5 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D13: if-condition rm -rf / blocks (condition position)" \
  "$(bash_payload 'if rm -rf / ; then :; fi')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D14: while-condition rm -rf / blocks (condition position)" \
  "$(bash_payload 'while rm -rf / ; do :; done')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D15: until-condition rm -rf / blocks (condition position)" \
  "$(bash_payload 'until rm -rf / ; do :; done')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D16: time -p rm -rf / blocks (wrapper flag that takes no argument)" \
  "$(bash_payload 'time -p rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D17: escaped wrapper word rm -rf / blocks (one leading backslash on sudo)" \
  "$(bash_payload '\sudo rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-POS-D18: quoted wrapper word rm -rf / blocks (full-token quotes on sudo)" \
  "$(bash_payload '"sudo" rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

# The prefix cap, from both sides. The walk counts prefix-run tokens (keywords, wrappers,
# assignments, redirections) and stops after ten, so a verb behind ten is reached and a
# verb behind eleven is not: a deliberate bound, declared in the readiness text. A
# wrapper's own options and operands do not count toward it.
test_case "EXT-POS-D19: ten assignments then rm -rf / blocks (inside the prefix cap)" \
  "$(bash_payload 'A=1 B=1 C=1 D=1 E=1 F=1 G=1 H=1 I=1 J=1 rm -rf /')" \
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

test_case "EXT-RES-D3: eleven assignments then rm -rf / allows HERE — the prefix cap, a declared residual" \
  "$(bash_payload 'A=1 B=1 C=1 D=1 E=1 F=1 G=1 H=1 I=1 J=1 K=1 rm -rf /')" \
  0

# --- EXT-RES-D-GIT (#8314): the declared precision class of the git rules ---
#
# The git rules anchor on a WORD BOUNDARY, not on a command position, so they read `git`
# wherever it appears. Once the canonicalizer walks a wrapper's own grammar, a `git` that
# the wrapper consumes as an option value or a positional is followed by the inserted
# separator, and the rule no longer reads a git subcommand there. Each pin below is a
# command that never runs git (it runs `push` as the user git, or with the variable git
# unset, or is rejected by nice for its adjustment), so the move from refused to allowed is
# a declared precision improvement. The control is the same command running git: refused.
test_case "EXT-RES-D-GIT-1: sudo -u git push --force allows (git is sudo's user, not the command)" \
  "$(bash_payload 'sudo -u git push --force')" \
  0

test_case "EXT-RES-D-GIT-2: env -u git push --force allows (git is the variable env unsets)" \
  "$(bash_payload 'env -u git push --force')" \
  0

test_case "EXT-RES-D-GIT-3: nice -n git push --force allows (git is nice's adjustment)" \
  "$(bash_payload 'nice -n git push --force')" \
  0

test_case "EXT-RES-D-GIT-CTL: sudo -u root git push --force blocks (the same wrapper running git)" \
  "$(bash_payload 'sudo -u root git push --force')" \
  2 "BLOCK-DESTRUCTIVE-001"

# --- EXT-APPEND (#8314, follow-up pass): the append form of a prefix assignment ---
#
# A prefix assignment has two spellings, NAME=value and its append form NAME+=value, and
# bash and zsh read both as an assignment word and run the command behind it. The
# canonicalizer's prefix walk recognized only the first, so it read an append-form word as
# the command word, and nothing behind that word sat at a command start: the deletion
# behind it reached no anchored rule. Each arm below is the plain-form refusal of
# EXT-POS-D4 (a NAME=value prefix, the CTL arm) reached through the append form: alone, not
# at the start of the line, with an empty value, ahead of a wrapper, and twice. PREC is the
# declared precision class of EXT-RES-D-GIT reached behind the append form: the command runs
# `push` as the user git and never runs git, so it is allowed exactly as its NAME=value
# spelling already is; PREC-CTL is the same wrapper running git, refused.
test_case "EXT-APPEND-D-CTL: a NAME=value assignment then rm -rf / blocks (plain-form control)" \
  "$(bash_payload 'FOO=1 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-APPEND-D1: an append-form assignment then rm -rf / blocks" \
  "$(bash_payload 'FOO+=1 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-APPEND-D2: an append-form assignment opening a later segment, then rm -rf / blocks" \
  "$(bash_payload 'true; FOO+=1 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-APPEND-D3: an append-form assignment with an empty value, then rm -rf / blocks" \
  "$(bash_payload 'FOO+= rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-APPEND-D4: an append-form assignment, then a wrapper, then rm -rf / blocks" \
  "$(bash_payload 'FOO+=1 sudo rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-APPEND-D5: two append-form assignments then rm -rf / blocks" \
  "$(bash_payload 'FOO+=1 BAR+=2 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-APPEND-PREC: an append-form assignment ahead of sudo -u git push --force allows (the declared precision class)" \
  "$(bash_payload 'FOO+=1 sudo -u git push --force')" \
  0

test_case "EXT-APPEND-PREC-CTL: an append-form assignment ahead of sudo -u root git push --force blocks" \
  "$(bash_payload 'FOO+=1 sudo -u root git push --force')" \
  2 "BLOCK-DESTRUCTIVE-001"

# --- EXT-ORDER (#8314, DT pass 2): an assignment or a redirection is read as what it is ---
#
# The default walk looked a token up as a prefix word (one leading backslash and full-token
# quotes dropped, then the basename) BEFORE it tested the token as an assignment or a
# redirection. A prefix-run assignment whose value is a path, or a redirection whose
# attached target is one, was therefore read as the wrapper its last path segment names;
# the walk stepped that wrapper's grammar, and a wrapper that takes a positional consumed
# the real command word as its operand, so the deletion behind it reached no anchored rule.
# The shell reads such a token as an assignment or a redirection, never as a command, and
# the walk now tests those two shapes first, the order the -022 walk already uses. Each arm
# below is the plain-form refusal (CTL0) reached through one spelling of the class. CTL1 to
# CTL4 hold the same shapes with a value or target that names no positional-taking wrapper,
# refused before and after; CTL5 is a real wrapper written by absolute path, which must keep
# its walk. The exit view's walk is unchanged.
test_case "EXT-ORDER-D-CTL0: rm -rf / blocks (plain-form control)" \
  "$(bash_payload 'rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D-CTL1: an assignment with a plain value, then rm -rf / blocks" \
  "$(bash_payload 'X=1 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D-CTL2: an assignment whose value is a path to env, then rm -rf / blocks" \
  "$(bash_payload 'X=/usr/bin/env rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D-CTL3: an assignment whose value is a path to nice, then rm -rf / blocks" \
  "$(bash_payload 'X=/usr/bin/nice rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D-CTL4: a redirection to a file that names no wrapper, then rm -rf / blocks" \
  "$(bash_payload '>/tmp/out rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D-CTL5: a real timeout wrapper written by absolute path, with its duration, then rm -rf / blocks" \
  "$(bash_payload '/usr/bin/timeout 5 rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D1: an assignment whose value's last path segment is timeout, then rm -rf / blocks" \
  "$(bash_payload 'X=/usr/bin/timeout rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D2: an output redirection to a file named timeout, then rm -rf / blocks" \
  "$(bash_payload '>/tmp/timeout rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D3: a numbered redirection whose target's last segment is timeout, then rm -rf / blocks" \
  "$(bash_payload '2>/tmp/x/timeout rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D4: an append-form assignment whose value names timeout, then rm -rf / blocks" \
  "$(bash_payload 'X+=/usr/bin/timeout rm -rf /')" \
  2 "BLOCK-DESTRUCTIVE-004"

test_case "EXT-ORDER-D5: a plain assignment, then one whose value names timeout, then rm -rf / blocks" \
  "$(bash_payload 'Y=1 X=/opt/tools/timeout rm -rf /')" \
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

# --- AC-D020 (#8444): the PATH-manipulation rule judges every spelling alike ---
#
# BLOCK-DESTRUCTIVE-020 anchors a PATH assignment at a command start, and the shared
# canonicalizer marked only the command word, so an assignment its prefix walk stepped over
# never sat where the anchor reads. The prefix form above was refused while the same
# assignment handed to a wrapper, placed behind another assignment or a redirection, after a
# keyword or `!`, at a condition position or inside a group was admitted, and so were the
# declaration builtins and the append operator. The canonicalizer's transformation (e) now
# marks every assignment the walk skips, and the rule's own line reads a declaration
# builtin's argument list and `PATH+=`. Each arm is the refused plain form (CTL) reached
# through one spelling. The NEAR arms hold the same shapes with another name, or the name as
# content, and must stay allowed, so each refusal is attributable to the PATH assignment
# itself. CAP pins the prefix cap's boundary: an assignment behind ten prefix-run tokens is
# judged, one behind eleven is the declared residual. OVER pins the declared over-block of
# an assignment written as a heredoc body line, which the canonicalizer reads as a command
# start because heredoc bodies are outside its model.
test_case "AC-D020-CTL-PFX: a prefix PATH assignment blocks (plain-form control)" \
  "$(bash_payload 'PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-CTL-EXPORT: export PATH before the command blocks (plain-form control)" \
  "$(bash_payload 'export PATH=x; true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-WRAP: a PATH assignment handed to env blocks" \
  "$(bash_payload 'env PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-WRAP-SUDO: a PATH assignment handed to sudo blocks" \
  "$(bash_payload 'sudo PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-WRAP-TIME: a PATH assignment behind time blocks" \
  "$(bash_payload 'time PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-WRAPOPT-1: a PATH assignment behind env's own flag blocks" \
  "$(bash_payload 'env -i PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-WRAPOPT-2: a PATH assignment behind env's own option and its argument blocks" \
  "$(bash_payload 'env -u FOO PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-WRAPABS: a PATH assignment handed to env by absolute path blocks" \
  "$(bash_payload '/usr/bin/env PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-COND-IF: a PATH assignment at an if condition blocks" \
  "$(bash_payload 'if PATH=x true; then true; fi')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-COND-WHILE: a PATH assignment at a while condition blocks" \
  "$(bash_payload 'while PATH=x false; do true; done')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-COND-UNTIL: a PATH assignment at an until condition blocks" \
  "$(bash_payload 'until PATH=x true; do true; done')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-COND-EXPORT: export PATH at an if condition blocks" \
  "$(bash_payload 'if export PATH=x; then true; fi')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-ASSIGN-1: a PATH assignment behind another assignment blocks" \
  "$(bash_payload 'FOO=1 PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-ASSIGN-2: a PATH assignment behind a redirection blocks" \
  "$(bash_payload '>/dev/null PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-GROUP-1: a PATH assignment opening a subshell blocks" \
  "$(bash_payload '(PATH=x; true)')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-GROUP-2: a PATH assignment opening a brace group blocks" \
  "$(bash_payload '{ PATH=x; true; }')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-GROUP-3: a PATH assignment opening a function body blocks" \
  "$(bash_payload 'f() { PATH=x true; }')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-KW-1: a PATH assignment after then blocks" \
  "$(bash_payload 'if true; then PATH=x true; fi')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-KW-2: a PATH assignment after do blocks" \
  "$(bash_payload 'for i in 1; do PATH=x true; done')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-KW-3: a PATH assignment after ! blocks" \
  "$(bash_payload '! PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-EXPORT-ARGS-1: export with a PATH assignment later in its argument list blocks" \
  "$(bash_payload 'export FOO=1 PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-EXPORT-ARGS-2: export with an end-of-options marker before PATH blocks" \
  "$(bash_payload 'export -- PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-DECL-1: declare carrying a PATH assignment blocks" \
  "$(bash_payload 'declare -x PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-DECL-2: typeset carrying a PATH assignment blocks" \
  "$(bash_payload 'typeset -x PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-DECL-3: readonly carrying a PATH assignment blocks" \
  "$(bash_payload 'readonly PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-DECL-4: local carrying a PATH assignment blocks" \
  "$(bash_payload 'local PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-APPEND: an appending PATH assignment blocks" \
  "$(bash_payload 'PATH+=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-CAP-TEN: a PATH assignment behind ten prefix-run tokens blocks (the cap's boundary)" \
  "$(bash_payload 'A=1 B=1 C=1 D=1 E=1 F=1 G=1 H=1 I=1 J=1 PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-CAP-RESID: a PATH assignment behind eleven prefix-run tokens allows (the declared cap residual)" \
  "$(bash_payload 'A=1 B=1 C=1 D=1 E=1 F=1 G=1 H=1 I=1 J=1 K=1 PATH=x true')" \
  0

test_case "AC-D020-OVER-HEREDOC: a PATH assignment written as a heredoc body line blocks (declared over-block)" \
  "$(bash_payload "$(/usr/bin/printf '%s\n%s\n%s' "cat > notes.txt <<'EOF'" 'local PATH=x' 'EOF')")" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "AC-D020-NEAR-1: another variable handed to env allows" \
  "$(bash_payload 'env FOO=x true')" \
  0

test_case "AC-D020-NEAR-2: another variable opening a subshell allows" \
  "$(bash_payload '(FOO=x; true)')" \
  0

test_case "AC-D020-NEAR-3: another variable at an if condition allows" \
  "$(bash_payload 'if FOO=x true; then true; fi')" \
  0

test_case "AC-D020-NEAR-4: a variable whose name ends in PATH allows" \
  "$(bash_payload 'MYPATH=x true')" \
  0

test_case "AC-D020-NEAR-5: a variable whose name begins with PATH allows" \
  "$(bash_payload 'PATHX=x true')" \
  0

test_case "AC-D020-NEAR-6: a PATH assignment as an argument of echo allows" \
  "$(bash_payload 'echo PATH=x')" \
  0

test_case "AC-D020-NEAR-7: a PATH assignment as a search pattern allows" \
  "$(bash_payload 'grep -c PATH= f')" \
  0

test_case "AC-D020-NEAR-8: a wrapped PATH assignment inside a quoted string allows" \
  "$(bash_payload 'echo "env PATH=x true"')" \
  0

test_case "AC-D020-NEAR-9: export of a variable whose name ends in PATH allows" \
  "$(bash_payload 'export MYPATH=x')" \
  0

test_case "AC-D020-NEAR-10: declare of another variable allows" \
  "$(bash_payload 'declare -x FOO=x')" \
  0

# AC-D020-CANON — transformation (e)'s text contract, exact. The default output marks every
# assignment the walk skips and never the one at offset 1; the exit view, which the deletion
# hook's allow-on-match exits read, marks no assignment.
d020_canon() { # $1 = arm label  $2 = input  $3 = expected output  $4 = view (default | exit)
  local got
  if [ "$4" = exit ]; then
    got="$(/usr/bin/awk -v CMDPOS_VIEW=exit -f "${HOOK%/*}/lib/command-position.awk" <<<"$2" 2>/dev/null)"
  else
    got="$(/usr/bin/awk -f "${HOOK%/*}/lib/command-position.awk" <<<"$2" 2>/dev/null)"
  fi
  if [ "$got" = "$3" ]; then
    /usr/bin/printf 'PASS: %s the %s view of [%s] is [%s]\n' "$1" "$4" "$2" "$3"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s the %s view of [%s]: wanted [%s] got [%s]\n' "$1" "$4" "$2" "$3" "$got"
    FAIL=$((FAIL + 1))
  fi
}
d020_canon "AC-D020-CANON-1" 'env PATH=x true' 'env ; PATH=x ; true' default
d020_canon "AC-D020-CANON-2" 'FOO=1 PATH=x true' 'FOO=1 ; PATH=x ; true' default
d020_canon "AC-D020-CANON-3" '(PATH=x; true)' '(; PATH=x; ; true)' default
d020_canon "AC-D020-CANON-4" 'PATH=x true' 'PATH=x ; true' default
d020_canon "AC-D020-CANON-EXIT" 'env PATH=x true' 'env PATH=x ; true' exit

# --- AC-D023 (#8444): the anti-injection rule reads the positions -020 reads ---
#
# BLOCK-DESTRUCTIVE-023 shares -020's anchored-assignment shape, so transformation (e) moves
# its wrapped, behind-assignment, grouped and condition-position spellings from admitted to
# refused, a declared tightening; its two export-capable lines also read a declaration
# builtin's argument list and the append operator, as -020's line does. No arm pinned this
# rule's patterns before, so CTL is the plain-form control, and NEAR holds a name that only
# resembles the variable, or the variable as content.
test_case "AC-D023-CTL: a prefix hook-bypass assignment blocks (plain-form control)" \
  "$(bash_payload 'CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-CTL-SCOPE: a prefix scope-root assignment blocks (plain-form control)" \
  "$(bash_payload 'PMO_SCOPE_GUARD_ROOT=x true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-WRAP: a hook-bypass assignment handed to env blocks (declared tightening)" \
  "$(bash_payload 'env CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-WRAP-OPT: a hook-bypass assignment behind env's own flag blocks (declared tightening)" \
  "$(bash_payload 'env -i CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-WRAP-SCOPE: a scope-root assignment handed to env blocks (declared tightening)" \
  "$(bash_payload 'env PMO_SCOPE_GUARD_ROOT=x true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-ASSIGN: a hook-bypass assignment behind another assignment blocks (declared tightening)" \
  "$(bash_payload 'FOO=1 CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-GROUP: a hook-bypass assignment opening a subshell blocks (declared tightening)" \
  "$(bash_payload '(CLAUDE_HOOK_BYPASS=1 true)')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-COND: a hook-bypass assignment at an if condition blocks (declared tightening)" \
  "$(bash_payload 'if CLAUDE_HOOK_BYPASS=1 true; then true; fi')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-DECL: declare carrying a hook-bypass assignment blocks" \
  "$(bash_payload 'declare -x CLAUDE_HOOK_BYPASS=1')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-DECL-SCOPE: export with a scope-root assignment later in its argument list blocks" \
  "$(bash_payload 'export FOO=1 PMO_SCOPE_GUARD_ROOT=x')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-APPEND: an appending hook-bypass assignment blocks" \
  "$(bash_payload 'CLAUDE_HOOK_BYPASS+=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-APPEND-SCOPE: an appending scope-root assignment blocks" \
  "$(bash_payload 'PMO_SCOPE_GUARD_ROOT+=x true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "AC-D023-NEAR-1: a variable whose name only resembles the bypass variable allows" \
  "$(bash_payload 'env FOO_HOOK_BYPASS=1 true')" \
  0

test_case "AC-D023-NEAR-2: the bypass assignment as an argument of echo allows" \
  "$(bash_payload 'echo CLAUDE_HOOK_BYPASS=1')" \
  0

# --- EXT-APPEND-D020 / -D023 (#8314, follow-up pass): an assignment behind the append form ---
#
# -020 and -023 read the append operator on their own variable at a command start, but an
# append-form word was the canonicalizer's command word, so a guarded assignment BEHIND one
# was never reached and never marked by transformation (e). Each arm is a guarded assignment
# placed behind an append-form assignment; each CTL is the same assignment behind a
# NAME=value word, refused before and after. The NEAR arms hold words that only look like
# the append form — quoted, an argument of the real command, an invalid name, a doubled
# operator — or the append form ahead of another name, and must keep today's allow.
test_case "EXT-APPEND-D020-CTL: a PATH assignment behind a NAME=value assignment blocks (plain-form control)" \
  "$(bash_payload 'FOO=1 PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-APPEND-D020-1: a PATH assignment behind an append-form assignment blocks" \
  "$(bash_payload 'FOO+=1 PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-APPEND-D020-2: an appending PATH assignment behind an append-form assignment blocks" \
  "$(bash_payload 'FOO+=1 PATH+=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-APPEND-D020-3: a PATH assignment handed to env behind an append-form assignment blocks" \
  "$(bash_payload 'FOO+=1 env PATH=x true')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-APPEND-D020-4: export PATH behind an append-form assignment blocks" \
  "$(bash_payload 'FOO+=1 export PATH=x')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-APPEND-D023-CTL: a hook-bypass assignment behind a NAME=value assignment blocks (plain-form control)" \
  "$(bash_payload 'FOO=1 CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "EXT-APPEND-D023-1: a hook-bypass assignment behind an append-form assignment blocks" \
  "$(bash_payload 'FOO+=1 CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "EXT-APPEND-D023-2: a scope-root assignment behind an append-form assignment blocks" \
  "$(bash_payload 'FOO+=1 PMO_SCOPE_GUARD_ROOT=x true')" \
  2 "BLOCK-DESTRUCTIVE-023"

test_case "EXT-APPEND-NEAR-1: a quoted append-form word is the command word, so the PATH word behind it allows" \
  "$(bash_payload '"FOO+=1" PATH=x true')" \
  0

test_case "EXT-APPEND-NEAR-2: an append-form word as an argument of echo allows" \
  "$(bash_payload 'echo FOO+=1 PATH=x')" \
  0

test_case "EXT-APPEND-NEAR-3: an invalid name before the append operator is the command word and allows" \
  "$(bash_payload '1FOO+=1 PATH=x true')" \
  0

test_case "EXT-APPEND-NEAR-4: a doubled plus is not the append operator and allows" \
  "$(bash_payload 'FOO++=1 PATH=x true')" \
  0

test_case "EXT-APPEND-NEAR-5: an append-form assignment ahead of a variable whose name ends in PATH allows" \
  "$(bash_payload 'FOO+=1 MYPATH=x true')" \
  0

test_case "EXT-APPEND-NEAR-6: an append-form line written as quoted content allows" \
  "$(bash_payload 'echo "FOO+=1 PATH=x true"')" \
  0

# --- EXT-ORDER-D020 / -D023 (#8314, DT pass 2): the ordering class at the assignment-anchored rules ---
#
# The misread of EXT-ORDER above also kept transformation (e) from marking an assignment. An
# assignment whose value's last path segment names a positional-taking wrapper consumed the
# PATH assignment behind it as that wrapper's operand (D020-1), and a PATH assignment whose own
# value ends in a wrapper's name was itself read as that wrapper and never marked (D020-2).
# Each CTL is the same PATH assignment behind a plain prefix assignment, refused before and
# after. D023-1 is D020-1's shape on the anti-injection rule, a position D-Scope-023 declares.
# The CANON pins hold the default view's exact text for both shapes and the exit view's.
test_case "EXT-ORDER-D020-CTL1: a PATH assignment behind a plain assignment blocks (control)" \
  "$(bash_payload 'X=1 PATH=/tmp/evil ls')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-ORDER-D020-1: a PATH assignment behind an assignment whose value names timeout blocks" \
  "$(bash_payload 'X=/usr/bin/timeout PATH=/tmp/evil ls')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-ORDER-D020-CTL2: a PATH assignment to a directory path, behind a plain assignment, blocks (control)" \
  "$(bash_payload 'X=1 PATH=/tmp/evil/bin ls')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-ORDER-D020-2: a PATH assignment whose value's last segment is sudo, behind a plain assignment, blocks" \
  "$(bash_payload 'X=1 PATH=/tmp/evil/sudo ls')" \
  2 "BLOCK-DESTRUCTIVE-020"

test_case "EXT-ORDER-D023-1: a hook-bypass assignment behind an assignment whose value names timeout blocks (declared tightening)" \
  "$(bash_payload 'X=/usr/bin/timeout CLAUDE_HOOK_BYPASS=1 true')" \
  2 "BLOCK-DESTRUCTIVE-023"

d020_canon "EXT-ORDER-CANON-1" 'X=/usr/bin/timeout PATH=x true' 'X=/usr/bin/timeout ; PATH=x ; true' default
d020_canon "EXT-ORDER-CANON-2" 'X=1 PATH=/tmp/evil/sudo ls' 'X=1 ; PATH=/tmp/evil/sudo ; ls' default
d020_canon "EXT-ORDER-CANON-3" '>/tmp/timeout rm x' '>/tmp/timeout ; rm x' default
d020_canon "EXT-ORDER-CANON-EXIT" 'X=/usr/bin/timeout rm x' 'X=/usr/bin/timeout ; rm x' exit

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
# The set is a BOUNDED enumeration, one of four lists of this vocabulary; they are not
# one set, and the WRAPVOCAB-PARITY arms further down assert exactly how they differ. A
# wrapper's own options are walked from its row; the WRAPOPT-* arms grade that.
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

test_case "BLOCK-022 wrapper precision: a describe-only wrapper option (command -v) executes nothing, so the segment is skipped" \
  "$(bash_payload 'command -v bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 wrapper precision: wrapper word off the segment head does not advance" \
  "$(bash_payload 'echo sudo bash /tmp/evil.sh')" \
  0

# recorded residual, asserted so the stated coverage boundary is measured rather
# than assumed. `eval` re-parses a program string this lexical matcher cannot
# resolve, so it is deliberately OUT of the bounded set. If it is ever added, this
# case fails and the rule doc must be updated with it. `timeout` used to be pinned
# here beside it, for the duration operand the walk had no way to consume; its row
# consumes that operand now, so the same payload is adjudicated and blocks
# (WRAPOPT-row-timeout-* carry its other spellings).
test_case "BLOCK-022 wrapper residual: eval is not a skipped prefix (allows)" \
  "$(bash_payload 'eval bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 wrapper: timeout before bash, its duration consumed by its row, non-allowlisted, blocks" \
  "$(bash_payload 'timeout 5 bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

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
# goes red -- which is the point of having it (AC-ENCL-TEXEC6-pair shows it: with
# the suppression switched off, this payload is recorded).
#
# RE-POINTED WHEN ENCLOSURE POSITIONS BECAME ADJUDICATED. The payload used to put
# the code span's raw backticks inside the DOUBLE-quoted argument, where the shell
# runs them as a command substitution: both real shells execute `./tmp/x.sh` for
# that spelling, so "must not flag" asserted an allow on a real execution, and the
# enclosure view now records it (T-EXEC-6b below). The table row is now
# single-quoted, where the backticks are text and nothing runs, and the arm still
# guards the suppression, as the paragraph above says.
exec_notflag_case "T-EXEC-6 must-not-flag: markdown table row with a backticked .sh path in a carrier argument (single-quoted, so nothing runs)" \
  "gh issue comment 1 --body '| step | \`./tmp/x.sh\` | run it |'"

exec_warn_case "T-EXEC-6b must-flag: the same row double-quoted, where the shell runs the code span, is recorded from the position its backtick opens" \
  'gh issue comment 1 --body "| step | `./tmp/x.sh` | run it |"' 'not-allowlisted'

# RETARGETED BY #6167, AND THE RETARGET IS THE POINT RATHER THAN A REPAIR. This arm
# read `/usr/bin/python3 script.py` and asserted the EXEC arm does not flag it. That
# was true because `python3` was not a verb, so the exec arm claimed the command word
# `/usr/bin/python3` and exempted it as system-bin. Admitting the non-shell
# interpreters moves the same input to the INTERPRETER arm, where the adjudicated
# subject is `script.py` — the file that actually executes — and it is now flagged.
# That is the card's whole subject, so the old expectation cannot stand.
#
# The arm's CLAIM is unchanged and still worth asserting: a system-bin interpreter
# for a language OUTSIDE the admitted set is not flagged by the exec arm. The fixture
# moves to `osascript`, which is a declared residual rather than an admitted verb.
# T-NSI-07d below asserts the new verdict for the python spelling, so the pair reads
# as one fact: the boundary moved, and both sides of it are pinned.
exec_notflag_case "T-EXEC-7 must-not-flag: system-bin interpreter for a language OUTSIDE the admitted set" \
  '/usr/bin/osascript script.scpt'

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
# BLOCK-022 — a documented command the guard must keep admitting
# ==========================================================================
#
# The hub-spoke bridge's release-close checklist (item 8 of its closing procedure)
# runs a bash -c program that sources the version-grammar library. The guard reads
# that program, so the documented form has to be one it admits: a hub running the
# checklist must not be refused by the platform's own guard. These arms read the
# program out of the document, so they grade what the document says rather than a
# copy that could drift from it.
#
# The pair is its own control. The second arm swaps only the sourced line for the
# earlier spelling, a library path built from a command substitution, which the guard
# refuses once it reads each word after quote removal. A guard that allowed everything
# fails the second arm; one that refused everything fails the first.
P7_REL="release/references/how-to/hub-spoke-bridge.md"
P7_DOC=""
p7_root=""
if [ -r "$(dirname "$0")/.source-repo-root" ]; then
  IFS= read -r p7_root < "$(dirname "$0")/.source-repo-root" || true
fi
for p7_c in "${p7_root:+${p7_root}/${P7_REL}}" \
  "$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd -P)/${P7_REL}"; do
  if [ -z "$P7_DOC" ] && [ -n "$p7_c" ] && [ -f "$p7_c" ]; then P7_DOC="$p7_c"; fi
done
P7_PROG=""
if [ -n "$P7_DOC" ]; then
  P7_PROG="$(/usr/bin/awk -v q="'" '
    /^   # 8\. \.version stamped/ { f = 1 }
    f && /^   bash -c / { p = 1 }
    p { print }
    p && !/^   bash -c / && substr($0, length($0)) == q { exit }' "$P7_DOC")"
fi
P7_NEWLINE='. release/tools/version-grammar.sh ""'
P7_OLDLINE='. "$(git rev-parse --show-toplevel)/release/tools/version-grammar.sh" ""'
P7_OLD="${P7_PROG/"$P7_NEWLINE"/$P7_OLDLINE}"
p7_ok=1; p7_why=""
[ -n "$P7_DOC" ] || { p7_ok=0; p7_why="$p7_why document-not-found"; }
case "$P7_PROG" in *"$P7_NEWLINE"*) ;; *) p7_ok=0; p7_why="$p7_why program-not-found-or-source-line-changed" ;; esac
case "$P7_OLD" in *'rev-parse --show-toplevel'*) ;; *) p7_ok=0; p7_why="$p7_why control-not-built" ;; esac
if [ "$p7_ok" = 1 ]; then
  /usr/bin/printf 'PASS: BLOCK-022 doc-form: the release-close .version program is read from the document and sources the library by its repository-relative path\n'
  PASS=$((PASS + 1))
  exec_notflag_case "BLOCK-022 doc-form: the release-close .version program, as documented, allows and writes no row" \
    "$P7_PROG"
  test_case "BLOCK-022 doc-form control: the same program with the library path built from a command substitution blocks" \
    "$(bash_payload "$P7_OLD")" \
    2 "BLOCK-DESTRUCTIVE-022"
else
  /usr/bin/printf 'FAIL: BLOCK-022 doc-form: the documented program could not be graded (%s); re-read the checklist line and re-verify it against the guard\n' "$p7_why"
  FAIL=$((FAIL + 1))
fi

# ==========================================================================
# BLOCK-022 — the append form of a prefix assignment (#8314, the walk-fix pass)
# ==========================================================================
#
# A prefix assignment has two spellings, NAME=value and its append form NAME+=value, and
# bash and zsh read both as an assignment word and run the command behind it. This rule's
# command-position walk recognized only the first, so it took an append-form word for the
# command word: an interpreter or `source` invocation behind it matched no verb and was never
# adjudicated, while an append-form word whose own value named an interpreter or a script was
# adjudicated as though it were the command. The walk now steps over the append form exactly
# as it steps over NAME=value. Each must-flag arm below is a must-flag arm of the
# assignment-prefix block above (its NAME=value control) reached through the append form, and
# each was allowed, with nothing adjudicated, before this pass.
#
# THE DECLARED PRECISION CLASS. An append-form word is an assignment, so its value is not the
# command and the word after it is: `VAR+=/bin/bash <script>` runs <script> directly, which the
# direct-execution arm records at its rollout phase where the old reading refused it as an
# interpreter invocation, and `VAR+=<script> <command>` executes nothing, which the old reading
# recorded as a direct execution. Each takes the verdict its NAME=value spelling already has,
# and the twin arm beside it pins that.
#
# THE DECLARED LIMIT. The head resolver the quoted-fragment suppression reads keeps its
# NAME=value-only test on purpose: it fails closed, so a carrier behind the append form keeps a
# false positive its NAME=value spelling does not have, and widening it would turn refusals
# into allows. Pinned, not closed.

echo ""
echo "BLOCK-022 the append form of a prefix assignment (walk-fix pass)"
echo "---"

test_case "BLOCK-022 append: VAR+=v before bash, non-allowlisted, blocks" \
  "$(bash_payload 'ENVV+=1 bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 append: two append-form assignments before bash, non-allowlisted, blocks" \
  "$(bash_payload 'FOO+=bar BAZ+=qux bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 append: VAR+= with an empty value before bash, non-allowlisted, blocks" \
  "$(bash_payload 'ENVV+= bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 append: VAR+=v before source, non-allowlisted, blocks" \
  "$(bash_payload 'ENVV+=1 source /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 append: VAR+=v, then a wrapper and its option, then bash, blocks" \
  "$(bash_payload 'ENVV+=1 sudo -u bot bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 append: VAR+=v opening a later segment, then bash, blocks" \
  "$(bash_payload 'true; ENVV+=1 bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

exec_warn_case "BLOCK-022 append: VAR+=v before a direct execution records it at the exec arm's phase" \
  'ENVV+=1 /tmp/evil.sh' 'not-allowlisted'

# must-not-flag control -- the same prefix over an allowlisted target.
test_case "BLOCK-022 append control: VAR+=v before bash, allowlisted, allows" \
  "$(bash_payload 'ENVV+=1 bash core/deploy/deploy.sh')" \
  0

# skip-precision controls. Each word below only looks like the append form, or stands where the
# walk does not step, so it stays the command word -- not an interpreter -- and the verdict is
# UNCHANGED from before this pass. If the skip ever loosens into a general advance past any
# token carrying `+=`, or into the array or indirect forms another card owns, these flip to
# blocking and fail.
test_case "BLOCK-022 append precision: a quoted append-form word is the command word" \
  "$(bash_payload '"ENVV+=1" bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 append precision: an append-form word after the command word is an argument" \
  "$(bash_payload 'echo ENVV+=1 bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 append precision: invalid NAME before the append operator does not advance" \
  "$(bash_payload 'a-b+=1 bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 append precision: a doubled plus is not the append operator" \
  "$(bash_payload 'ENVV++=1 bash /tmp/evil.sh')" \
  0

test_case "BLOCK-022 append precision: an array append ends the run (an indirect form another card owns)" \
  "$(bash_payload 'ENVV+=(x) bash /tmp/evil.sh')" \
  0

# The declared precision class, each beside its NAME=value twin.
exec_warn_case "BLOCK-022 append precision class: VAR+=/bin/bash <script> is the direct execution of <script>, recorded" \
  'ENVV+=/bin/bash /tmp/evil.sh' 'not-allowlisted'

exec_warn_case "BLOCK-022 append precision class twin: VAR=/bin/bash <script> is recorded the same way" \
  'ENVV=/bin/bash /tmp/evil.sh' 'not-allowlisted'

exec_notflag_case "BLOCK-022 append precision class: VAR+=<script> before another command executes nothing" \
  'ENVV+=/tmp/evil.sh true'

exec_notflag_case "BLOCK-022 append precision class twin: VAR=<script> before another command executes nothing" \
  'ENVV=/tmp/evil.sh true'

# The declared limit of the head resolver, beside its NAME=value spelling.
test_case "BLOCK-022 append limit: a carrier behind the append form keeps the quoted-fragment false positive (pinned)" \
  "$(bash_payload "ENVV+=1 gh issue comment 1 --body 'x; bash /tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "BLOCK-022 append limit control: the NAME=value spelling of that carrier suppresses the fragment" \
  "$(bash_payload "ENVV=1 gh issue comment 1 --body 'x; bash /tmp/evil.sh'")" \
  0

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
# THE SPACE-BEARING PATH THIS BLOCK DID NOT CLOSE is pinned at the bottom
# (F1-QTOK-RESIDUAL-space). It was a pin of the allow; #8318's fragment join
# closes it at the operand, and the arm is now must-refuse.

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

# --- THE SPACE-BEARING QUOTED PATH (re-pointed: pin -> must-refuse) ---------
# A SPACE-BEARING quoted path is a different root cause from either family above
# and is not closed by THIS block. Tokenization splits raw argv on whitespace
# BEFORE any normalization runs, so the operand token is `'/tmp/pmo` — the real
# filename's first fragment — and neither the probe nor the raw token ends `.sh`.
# This arm used to pin that allow. #8318 closes it without a new tokenizer: at
# the operand after the flag walk, a fragment is joined to the word the shell
# passes (script_word_join), and that word is adjudicated. The join's boundary —
# the positions it does not reach — is declared in
# core/rules/bypass-mode-readiness/block-destructive.md, limit 3. The arm's old
# second role, the control of the rule that a fragment is never advanced past,
# moved to FWALK-QWORD-ctl-fragment-noexec: with the join, a walk that stepped
# off the fragment would refuse here too.
test_case "F1-QTOK-RESIDUAL-space (re-pointed, now must-refuse): a space-bearing quoted operand is joined at the operand and refused" \
  "$(bash_payload "bash '/tmp/pmo qtok probe na.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# ==========================================================================
# BLOCK-022 F2 FWALK — the operand walk must stop where the arm ADJUDICATES
# ==========================================================================
#
# A SIBLING ROOT CAUSE IN THE SAME WALK, WHICH IS WHY IT IS A SIBLING FAMILY.
# F1 above is about the walk's SUBJECT — a quoted token was read raw and the
# wrong string was tested. F2 is about the walk's TERMINATION PREDICATE — the
# right string was tested against the wrong question. The walk answered "where
# is the operand?" with "the first token that is not flag-shaped", and that is
# wrong in two independent ways that both land in the same place: a token that
# is NOT the operand becomes the adjudicated operand, falls outside the arm's
# declared operand domain, and the arm concludes the invocation is not its
# business — reaching ALLOW WITHOUT THE ALLOWLIST EVER BEING CONSULTED.
#
#   DEFECT 1 — the skip arm was DASH-ANCHORED. A plus-form option is not matched
#   by `-*`, so it fell to `*)` and the OPTION ITSELF became the operand:
#       bash +x <script>
#
#   DEFECT 2 — the skip did not CONSUME A FLAG'S ARGUMENT. `-*` advanced past the
#   option, the value is not dash-prefixed, `*)` broke, and THE VALUE became the
#   operand:
#       bash -o errexit <script>
#
# THE CONTROLS ARE WHAT MAKE THIS A DEFECT RATHER THAN A DECLARED BOUNDARY. An
# option taking no separate argument leaves the real operand in place, so
# `bash -x <script>` blocked while `bash -o errexit <script>` allowed — two
# spellings of one execution, one checked and one not.
#
# WHY THE ALLOW-ARMS BELOW ARE NOT FIX-EVIDENCE, AND MUST NOT BE READ AS SUCH.
# Every `F2-FWALK-ctl-*` arm was ALSO green before this change — for the OPPOSITE
# reason. Pre-fix they allowed because the allowlist was never consulted at all;
# post-fix they allow because the target IS allowlisted. An allow-arm cannot tell
# those two apart. Its only value is as the paired SPECIFICITY control for its
# must-flag twin: the twins differ in allowlist membership and in nothing else,
# so a fix that simply denied the whole class would turn the control red.
#
# HERMETIC BY CONSTRUCTION, AND THAT IS AC5 RATHER THAN TIDINESS. Running
# block-destructive.test.sh standalone reports ~179 PASS / 219 FAIL, because
# test-runner.sh exports PMO_SCOPE_GUARD_ROOT=/ and without it scope_guard_root()
# falls to <HOOK_DIR>/../.., the default fixture cwd lands outside it, and THE
# HOOK EXITS BEFORE ANY RULE RUNS. The 179 that "pass" are allow-arms passing
# VACUOUSLY. A block of all-allow arms would therefore read 100% green against a
# completely inert hook. So this block owns its whole runtime: its own sandbox
# root, its own hook copies, its own one-line allowlist, its own .mode, payload
# cwd pointed INSIDE the sandbox, and PMO_SCOPE_GUARD_ROOT / CLAUDE_WORKSPACE_ROOT
# unset for every run — it reads nothing from the runner and nothing from the
# ambient install, and returns the same verdict standalone and under the runner,
# because a suite whose verdict depends on how it is invoked is not a gate.
# F2-FWALK-SCOPE asserts that liveness BEFORE any verdict below is read.

echo ""
echo "BLOCK-022 F2 FWALK (operand walk terminates on the arm's operand domain)"
echo "---"

F2_ROOT="$(/usr/bin/mktemp -d)"
F2_CLAUDE="${F2_ROOT}/.claude"
F2_HOOKS="${F2_CLAUDE}/hooks"
/bin/mkdir -p "${F2_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${F2_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${F2_HOOKS}/lib/" 2>/dev/null || true

# ONE allowlist entry, owned by this block. Every ctl-arm allow and every must-flag
# deny below turns on membership in THIS file and on nothing else — not on the
# ambient core/script-execution-allowlist.txt, which is absent in a source checkout
# and token-resolved in a deployed one.
/usr/bin/printf '/tmp/pmo-f2-fwalk-allowed.sh\n' > "${F2_CLAUDE}/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${F2_HOOKS}/.mode"

/bin/cp "$HOOK" "${F2_HOOKS}/block-destructive.sh"
# The mutant: revert the operand walk to the dash-anchored form. Two expressions,
# because a pure deletion would leave the `case` with no default arm at all — a
# non-flag token would then match nothing, script_idx would never advance, and the
# while-loop would spin forever. Expression 1 deletes the arm BODY (anchored on
# M-FWALK-BODY, which the marker line does not carry); expression 2 rewrites the
# marker line back to `*) break ;;`. The arm now carries the ARITY OVERLAY as well as
# the domain test, so the sed reverts BOTH — which is why M3/M4's payload is a `+`
# form rather than `-o errexit`. Net: 18 lines -> 1, pinned by AC-D022-M1.
/usr/bin/sed \
  -e '/# M-FWALK-BODY/,/^[[:space:]]*;;$/d' \
  -e 's|^\([[:space:]]*\)\*) # M-FWALK-ADVANCE.*|\1*) break ;;|' \
  "$HOOK" > "${F2_HOOKS}/block-destructive-mut.sh"
/bin/chmod +x "${F2_HOOKS}/block-destructive.sh" "${F2_HOOKS}/block-destructive-mut.sh"

F2_NA='/tmp/pmo-f2-fwalk-na.sh'
F2_OK='/tmp/pmo-f2-fwalk-allowed.sh'

F2_EXIT=0
F2_ERR=""
# Run one payload through one of the two sandbox copies. Both live in the SAME
# directory, so they resolve the same allowlist, the same .mode and the same scope
# root: the sed is the only difference between them, which is what makes the pair a
# differential rather than two unrelated runs. The unsets are what make scope
# resolve from THIS fixture's own layout (<HOOK_DIR>/../.. == F2_ROOT == the payload
# cwd) instead of from whatever the caller exported.
f2_run() {
  local which="$1" cmd="$2" tmp
  tmp="$(/usr/bin/mktemp)"
  F2_EXIT=0
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$cmd" "$F2_ROOT")" \
      | /bin/bash "${F2_HOOKS}/${which}" 2>"$tmp" >/dev/null ) || F2_EXIT="$?"
  F2_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
}

# $1 = arm name  $2 = command  $3 = expected exit  $4 = (optional) stderr pattern
f2_case() {
  local name="$1" cmd="$2" want="$3" pat="${4:-}"
  f2_run block-destructive.sh "$cmd"
  local ok=1
  [ "$F2_EXIT" = "$want" ] || ok=0
  if [ -n "$pat" ] && ! /usr/bin/grep -qE "$pat" <<<"$F2_ERR"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  expected_exit=%s actual_exit=%s\n  stderr: %s\n' \
      "$name" "$want" "$F2_EXIT" "$F2_ERR"; FAIL=$((FAIL + 1))
  fi
}

# --- AC5: assert the harness BEFORE asserting any verdict --------------------
# A canary the hook must block for a reason UNRELATED to this fix. If it allows,
# the fixture is out of scope / inert and every verdict below is vacuous — an
# all-allow block would read 100% green against a hook that never ran a rule. A
# broken probe must report itself unusable, never report the population empty.
f2_run block-destructive.sh 'git push --force origin main'
if [ "$F2_EXIT" = 2 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-001' <<<"$F2_ERR"; then
  /usr/bin/printf 'PASS: F2-FWALK-SCOPE: fixture is in scope and enforcing (unrelated rule -001 fires), so the verdicts below are live\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: F2-FWALK-SCOPE: SCOPE ASSERTION FAILED - verdicts below are unusable (exit=%s, expected 2 naming BLOCK-DESTRUCTIVE-001)\n  stderr: %s\n' \
    "$F2_EXIT" "$F2_ERR"; FAIL=$((FAIL + 1))
fi

# --- AC1: plus-form options are not the operand ------------------------------
f2_case "F2-FWALK-plus-x: bash +x <non-allowlisted> blocks (plus-form option is not the operand)" \
  "bash +x ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-plus-v: bash +v <non-allowlisted> blocks" \
  "bash +v ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-plus-O: bash +O extglob <non-allowlisted> blocks (plus-form WITH a separate argument)" \
  "bash +O extglob ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-plus-sh: sh +x <non-allowlisted> blocks (the walk is shared by every interpreter)" \
  "sh +x ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# --- AC2: an option's ARGUMENT is never adjudicated as the operand -----------
f2_case "F2-FWALK-o-errexit: bash -o errexit <non-allowlisted> blocks (flag argument consumed)" \
  "bash -o errexit ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-o-noexec: bash -o noexec <non-allowlisted> blocks" \
  "bash -o noexec ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-O-extglob: bash -O extglob <non-allowlisted> blocks" \
  "bash -O extglob ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# A long option with a separate value. `--rcfile` is NOT `--`: the end-of-options
# arm is a literal match, so this reaches the generic flag arm as intended.
f2_case "F2-FWALK-rcfile: bash --rcfile <path> <non-allowlisted> blocks (long option, separate value)" \
  "bash --rcfile /tmp/pmo-f2-fwalk-rc ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-init-file: bash --init-file <path> <non-allowlisted> blocks" \
  "bash --init-file /tmp/pmo-f2-fwalk-rc ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-zsh-o: zsh -o errexit <non-allowlisted> blocks" \
  "zsh -o errexit ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# The walk is SHARED by the source arm, so the defect was too. The flag VALUE here
# is deliberately non-path-shaped: the source arm's operand domain carries PREFIX
# alternatives (`/*`), so a path-shaped value would land inside its domain and be
# adjudicated (as the wrong file) even before this fix.
f2_case "F2-FWALK-source-o: source -o errexit <non-allowlisted> blocks (shared walk, source arm)" \
  "source -o errexit ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# --- Paired specificity controls: same shapes, ALLOWLISTED target ------------
# Green before this change too, and for the wrong reason — see the block header.
# These are the specificity halves of the pairs above, not independent evidence.
f2_case "F2-FWALK-ctl-plus-x (paired control): bash +x <allowlisted> still allows" \
  "bash +x ${F2_OK}" 0

f2_case "F2-FWALK-ctl-o-errexit (paired control): bash -o errexit <allowlisted> still allows" \
  "bash -o errexit ${F2_OK}" 0

f2_case "F2-FWALK-ctl-rcfile (paired control): bash --rcfile <path> <allowlisted> still allows" \
  "bash --rcfile /tmp/pmo-f2-fwalk-rc ${F2_OK}" 0

f2_case "F2-FWALK-ctl-source-o (paired control): source -o errexit <allowlisted> still allows" \
  "source -o errexit ${F2_OK}" 0

# --- The fail-closed deny the defect DISARMED --------------------------------
# A variable-bearing path cannot be resolved from argv, so check_script_target
# denies it. Before this fix, prefixing ANY value-taking flag hid that operand and
# the documented fail-closed posture silently did not apply: `bash "$DIR/x.sh"`
# denied while `bash -o errexit "$DIR/x.sh"` allowed.
f2_case "F2-FWALK-varbearing: a value-taking flag no longer disarms the variable-bearing fail-closed deny" \
  'bash -o errexit "$DIR/x.sh"' 2 "BLOCK-DESTRUCTIVE-022"

# --- The bypass must not survive by position on the line ---------------------
f2_case "F2-FWALK-chain: the SECOND command on a line is walked with the same predicate" \
  "bash ${F2_OK}; bash +x ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# `-c` was UNREACHABLE behind a value-taking flag: the walk stopped on the flag's
# argument before it ever saw `-c`, so the whole cmode scanning loop was skipped.
# Reaching it is the correct widening, not a new mechanism.
f2_case "F2-FWALK-cmode-reach: -c is reachable behind a value-taking flag and its program string is scanned" \
  "bash -o errexit -c 'bash ${F2_NA}'" 2 "BLOCK-DESTRUCTIVE-022"

# --- The bypass must not survive by how the interpreter is spelled -----------
f2_case "F2-FWALK-wrapper: env bash -o errexit <non-allowlisted> blocks (verb behind a prefix word)" \
  "env bash -o errexit ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-varprefix: FOO=1 bash +x <non-allowlisted> blocks (verb behind an assignment prefix)" \
  "FOO=1 bash +x ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-quotedverb: \"bash\" -o errexit <non-allowlisted> blocks (F1 verb widening + F2 walk)" \
  "\"bash\" -o errexit ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

f2_case "F2-FWALK-absinterp: /bin/bash -o errexit <non-allowlisted> blocks (absolute interpreter)" \
  "/bin/bash -o errexit ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# --- DECLARED RESIDUAL R1 — NOW CLOSED, AND THE PIN IS THE RECORD OF IT ---------
# The pin read: "R1: a value-taking flag whose ARGUMENT is itself an allowlisted
# script path. The scan legitimately terminates on that argument and the real operand
# is never reached … closing it is an arity overlay's job, and layered on top of this
# walk that overlay's failure direction is safe. This arm asserts the CURRENT verdict
# so a later closure is a deliberate act rather than a drift."
#
# THE ARITY OVERLAY IS THE OTHER HALF OF THIS MERGE, SO THE CLOSURE IS THAT ACT. The
# walk now asks the interpreter whether a flag takes a separate argument, consumes it,
# and ADJUDICATES it in place — so `--rcfile <allowlisted>` no longer terminates the
# scan: the allowlisted path is checked where it sits, and the walk continues to the
# script bash actually runs. R1 is closed for every flag the arity table names, and
# the overlay's failure direction is the safe one the pin predicted: a flag the table
# omits falls through to the domain test, which is an over-block, not an exemption.
# The arm keeps its subject and asserts the NEW verdict, so a regression that
# re-opens R1 turns it red in the other direction.
f2_case "F2-FWALK-RESIDUAL-flagarg [CLOSED by the arity overlay]: a flag argument that is an allowlisted script no longer hides the operand" \
  "bash --rcfile ${F2_OK} ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# --- DECLARED VERDICT CHANGE (pin) -------------------------------------------
# P6: an EXTENSIONLESS executed target with a script argument moves ALLOW -> BLOCK.
# The walk advances past the un-adjudicable wrapper (the extensionless residual
# three arms already share) and adjudicates the argument. The direction is
# over-block, which this rule's doc calls recoverable, and no prior arm pinned it.
# `bash -- <wrapper> <script>` is UNCHANGED — `--` remains a hard stop, so POSIX
# operand semantics are preserved exactly.
f2_case "F2-FWALK-CONSEQ-extless (pin): an extensionless target with a .sh argument now blocks on the argument" \
  "bash /tmp/pmo-f2-fwalk-wrapper ${F2_NA}" 2 "BLOCK-DESTRUCTIVE-022"

# =====================================================================
# AC-D022-M* — mutation differential on the operand walk (#6724 AC4)
# =====================================================================
# Every F2 arm above is an OUTCOME assertion against the shipped hook, and no
# outcome arm can separate "the walk's termination predicate changed" from "some
# other property of this hook happens to reach the same verdict". AC4 asks for the
# discriminating form: the new arms demonstrated FAILING on a fixture whose walk is
# reverted to the dash-anchored form, and PASSING on the conformant control. The
# requirement is a BEHAVIOURAL DIFFERENCE, not a green light.
#
# THE POLARITY IS INVERTED relative to the one shipped precedent for this shape
# (AC-E007-M* in block-egress.test.sh, whose conformant control is an ALLOW and
# whose differential is a DENY). Here the fix ADDS blocks, so the conformant
# control is the DENY and the differential is the ALLOW — which is exactly why M5
# below is not optional.
echo ""
echo "BLOCK-022 operand-walk mutation differential (AC-D022-M*)"
echo "---"

# M1 — guard the mutation itself. If the sed matched nothing, the "mutant" IS the
# shipped hook and every arm below is an inert tautology. Pinning the exact delta
# also means a future edit that moves or reshapes the arm turns this red rather
# than silently neutering the fixture: re-point the sed, do not delete the arm.
#
# THE SECOND CLAUSE IS COUNTED, NOT MERELY PRESENT, AND THAT IS THE WHOLE POINT.
# `*) break ;;` occurs at TWO other places in this hook at the same indentation, so
# "the mutant contains a dash-anchored default arm" is true of the SHIPPED file too
# and asserts nothing. The discriminating form is that the mutant carries exactly
# ONE MORE such arm than the shipped copy, and carries NO M-FWALK marker at all.
F2_M_REMOVED=$(( $(/usr/bin/wc -l < "${F2_HOOKS}/block-destructive.sh") - $(/usr/bin/wc -l < "${F2_HOOKS}/block-destructive-mut.sh") ))
F2_M_ARMS_SHIP="$(/usr/bin/grep -cE '^[[:space:]]*\*\) break ;;[[:space:]]*$' "${F2_HOOKS}/block-destructive.sh" || true)"
F2_M_ARMS_MUT="$(/usr/bin/grep -cE '^[[:space:]]*\*\) break ;;[[:space:]]*$' "${F2_HOOKS}/block-destructive-mut.sh" || true)"
F2_M_MARKERS_MUT="$(/usr/bin/grep -c 'M-FWALK' "${F2_HOOKS}/block-destructive-mut.sh" || true)"
# THE EXPECTED DELTA IS 21. IT WAS 5, THEN 17, THEN 20 — the tripwire above has now
# done exactly its job at three successive reconciles, which is the argument for
# keeping it a hard number. 5 -> 17 when the advance-past arm took on the arity
# question (see FWALK-PLUS-* below). 17 -> 20 when it took on the NOEXEC REVOCATION
# (see NOEXEC-* below): the arm now also clears the parse-only flag for any token it
# steps over, three more lines inside the same `# M-FWALK-BODY` .. `;;` range. 20 -> 21
# when it took on the word read of a token it steps over (#8318, OPND-*): one call
# below both breaks. 21 -> 22 when it took on the positional mark of the xargs
# stdin deny (#8492, XARGS-*): one line recording that the token it steps over is not
# option-shaped. All five concerns — the domain test, the arity overlay, the
# revocation, the word read and the positional mark — are what the mutant must revert,
# so the count is UPDATED rather than the assertion loosened.
# Loosening it to a range or a `-gt` would retire the only thing that catches a
# reshaped arm.
if [ "$F2_M_REMOVED" = 22 ] \
  && [ "$F2_M_ARMS_MUT" = "$(( F2_M_ARMS_SHIP + 1 ))" ] \
  && [ "$F2_M_MARKERS_MUT" = 0 ]; then
  /usr/bin/printf 'PASS: AC-D022-M1: fixture sed removed exactly the 22 body lines, dropped both M-FWALK markers, and restored one additional dash-anchored `*) break ;;` arm (%s -> %s)\n' \
    "$F2_M_ARMS_SHIP" "$F2_M_ARMS_MUT"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D022-M1: fixture sed removed %s lines (expected 22), break-arms %s -> %s (expected +1), residual M-FWALK markers in mutant = %s (expected 0) — it no longer targets the operand walk; re-point the sed\n' \
    "$F2_M_REMOVED" "$F2_M_ARMS_SHIP" "$F2_M_ARMS_MUT" "$F2_M_MARKERS_MUT"; FAIL=$((FAIL + 1))
fi

# M2 — the mutated copy must still PARSE. A fixture that fails because it no longer
# runs proves nothing about the predicate it reverted; this arm is what makes M4's
# ALLOW attributable to changed BEHAVIOUR rather than to a broken file.
F2_M_SYNTAX=0
/bin/bash -n "${F2_HOOKS}/block-destructive-mut.sh" 2>/dev/null || F2_M_SYNTAX="$?"
if [ "$F2_M_SYNTAX" = 0 ]; then
  /usr/bin/printf 'PASS: AC-D022-M2: mutated copy is still valid bash (its verdict below is behavioural, not a parse error)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D022-M2: mutated copy does not parse (bash -n exit=%s) — the differential would be meaningless\n' \
    "$F2_M_SYNTAX"; FAIL=$((FAIL + 1))
fi

# M3/M4 — THE DIFFERENTIAL PAYLOAD IS RE-POINTED FROM `-o errexit` TO `+x`, AND THE
# REASON IS THAT THE TWO FIXES IN THIS MERGE OVERLAP. `bash -o errexit <script>` is
# closed TWICE over: by this walk's domain termination (the value is not the operand,
# so the walk keeps looking) and, independently, by the arity overlay merged alongside
# it (the `-*` skip arm consumes `errexit` as `-o`'s argument). Reverting only the walk
# therefore no longer reopens that payload — M4 measured a genuine overlap and said so
# by going red, which is the arm working. The `+`-FORM is the shape only the walk
# closes: `+x` is arity 0 on bash, so the overlay has nothing to consume, and a
# dash-anchored `*)` takes `+x` ITSELF as the operand — a token no domain claims — and
# reaches ALLOW. Same fixture, same rule, one predicate reverted.
#
# M3 — the CONFORMANT control. The shipped walk advances past the plus-form option,
# reaches the real operand, and denies it.
f2_run block-destructive.sh "bash +x ${F2_NA}"
if [ "$F2_EXIT" = 2 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$F2_ERR"; then
  /usr/bin/printf 'PASS: AC-D022-M3: conformant control — shipped hook DENIES the non-allowlisted script behind a value-taking flag\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D022-M3: conformant control did not deny (exit=%s, expected 2 naming BLOCK-DESTRUCTIVE-022)\n  stderr: %s\n' \
    "$F2_EXIT" "$F2_ERR"; FAIL=$((FAIL + 1))
fi

# M4 — the DIFFERENTIAL. Same payload, same sandbox, walk reverted to dash-anchored.
# The bypass reopens and the identical invocation reaches ALLOW.
f2_run block-destructive-mut.sh "bash +x ${F2_NA}"
if [ "$F2_EXIT" = 0 ]; then
  /usr/bin/printf 'PASS: AC-D022-M4: differential — with the walk reverted to the dash-anchored form the SAME invocation reaches ALLOW\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D022-M4: differential inconclusive (exit=%s, expected 0) — the mutant did not reopen the bypass\n  stderr: %s\n' \
    "$F2_EXIT" "$F2_ERR"; FAIL=$((FAIL + 1))
fi

# M5 — LIVENESS OF THE MUTANT, and the arm that makes AC4 a guarantee rather than a
# green light. M4 asserts an EXIT 0, and an inert hook — out of scope, master-off,
# missing lib, unparsed — produces exit 0 for free. Unlike the egress precedent, M4
# here has NO stderr to assert on, so nothing inside M4 can distinguish "the mutation
# reopened the bypass" from "the sandbox is dead". This arm supplies that
# discrimination: the mutant must still enforce the UNTOUCHED half of the very same
# rule — the bare invocation, and the no-argument flag that always blocked.
F2_M5_OK=1
f2_run block-destructive-mut.sh "bash ${F2_NA}"
{ [ "$F2_EXIT" = 2 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$F2_ERR"; } || F2_M5_OK=0
F2_M5_BARE="$F2_EXIT"
f2_run block-destructive-mut.sh "bash -x ${F2_NA}"
{ [ "$F2_EXIT" = 2 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$F2_ERR"; } || F2_M5_OK=0
if [ "$F2_M5_OK" = 1 ]; then
  /usr/bin/printf 'PASS: AC-D022-M5: mutated copy still enforces the untouched half of -022 (bare and no-argument-flag forms), so M4 is a live ALLOW and not a dead sandbox\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D022-M5: mutated copy did not enforce -022 on the untouched forms (bare exit=%s, -x exit=%s) — M4 may be an artefact of an inert hook\n  stderr: %s\n' \
    "$F2_M5_BARE" "$F2_EXIT" "$F2_ERR"; FAIL=$((FAIL + 1))
fi

# M6 — SPECIFICITY OF THE SANDBOX, which is what the ctl-arms' exit 0 rests on. M3
# proves this fixture can DENY; on its own that leaves "does it deny everything?"
# open, and a fix that simply denied the whole class would satisfy every must-flag
# arm above. Same hook, same sandbox, same value-taking-flag shape — only allowlist
# membership differs — and this MUST allow. The pair M3/M6 is therefore the one
# place the block shows its verdicts are allowlist DECISIONS rather than a posture.
f2_run block-destructive.sh "bash -o errexit ${F2_OK}"
if [ "$F2_EXIT" = 0 ]; then
  /usr/bin/printf 'PASS: AC-D022-M6: same sandbox ALLOWS the allowlisted twin of M3 behind the same flag, so the F2 verdicts are allowlist decisions and not a blanket deny\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-D022-M6: sandbox denied an allowlisted target behind a value-taking flag (exit=%s) — the fix is over-blocking, not adjudicating\n  stderr: %s\n' \
    "$F2_EXIT" "$F2_ERR"; FAIL=$((FAIL + 1))
fi

/bin/rm -rf "$F2_ROOT"

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

# (w) process substitution. The `;` inside it starts a segment at state 0, and that
#     is why this arm blocked before the enclosure view existed: the substitution
#     itself opened no command position then. Pinning it anyway: the reason must
#     stay true if the state model changes.
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

# A PRIMARY Layer-1 target written from a REPO-ROOTED worktree cwd → BLOCK. -019 is keyed
# on the write target, never on the session's working directory, so a worktree-rooted
# session no longer reaches the primary checkout through the Write/Edit path. This arm
# allowed before the re-key; it is one of three deliberate inversions, and the tightening
# is the point: the target is primary whatever the session's cwd.
test_case "Write CLAUDE.md with REPO-ROOTED worktree cwd blocks (target-keyed; inverted from allow)" \
  "$(write_payload ''"$HOME"'/Claude/CLAUDE.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/foo')" \
  2 "BLOCK-DESTRUCTIVE-019"

# --- BLOCK-DESTRUCTIVE-019 worktree-exemption base correction (#1639) ---
# The base correction pinned the exemption base at the REPO root
# (${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/), NOT the workspace root. That intent
# now lives on the TARGET axis: T7497-B1..B3 below pin the base there (a prefix is not a
# segment, the base is anchored at the repo root, and a <name>/ segment is required).
# FWD (inverted): a primary Layer-1 target from a repo-rooted worktree cwd → BLOCK, because
#        the target is primary; the worktree cwd no longer exempts it.
# REV-a: a primary target from the retired workspace-rooted 'worktrees' cwd → BLOCK, as
#        before — its target is primary too.
# REV-b: a non-worktree primary cwd → BLOCK (the core invariant stays green).

# FWD (inverted) — a pmo-platform Layer-1 target from a repo-rooted worktree cwd → block
test_case "Write pmo-platform/x.md with REPO-ROOTED worktree cwd blocks (target-keyed; inverted from allow)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/reference/x.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/foo')" \
  2 "BLOCK-DESTRUCTIVE-019"

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
# on-disk file, and neither do the ../-escape arms below: they block whether or
# not $HOME/Claude/CLAUDE.md exists.

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

# A9-A12 — the SINGLE-DOT segment. A6 pins `..`; these pin `.`, which the
# traversal arm did not originally reject.
#
# WHY A SINGLE DOT IS A CARVE-OUT DEFECT AND NOT A TRAVERSAL ONE. A `.` segment
# cannot leave the subtree, so it is not an escape. It is a defect because it
# SATISFIES ARM 2's `*/*` SUBFOLDER REQUIREMENT while adding no subfolder — the
# very predicate A5 relies on to keep the tracked `analysis/README.md` outside the
# carve-out. On the raw-path branch `analysis/./README.md` therefore reached the
# carve-out and was ALLOWED.
#
# WHY THESE SUBJECTS AND NOT THE BARE `analysis/./README.md`. The raw-path branch
# is taken only when the target AND its parent are both absent. `analysis/` and its
# tracked README EXIST in a real checkout, so `analysis/./README.md` is resolved by
# the normalizer (which collapses `.`) and blocks for the NORMALIZER's reason on
# such a runner — it would pass against the un-fixed hook too, and would pin
# nothing. A9/A10 use the block's `zz-nonexistent` convention so the raw branch is
# taken DETERMINISTICALLY on every runner, which is what makes them discriminating:
# each was confirmed to ALLOW (exit 0) against the pre-fix arm and to BLOCK against
# the fixed one.

# A9 — mid-path `/./`, the `*"/./"*` limb. Discriminating.
test_case "Write analysis/./zz-nonexistent/x.md with primary cwd still blocks (single-dot segment, mid-path)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/./zz-nonexistent/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# A10 — trailing `/.`, the `*/.` limb. Arm 1 carries a mid-path AND a trailing form
# for each dot segment; pinning only the mid-path one would leave half the
# predicate invisible to regression. Discriminating.
test_case "Write analysis/zz-nonexistent/. with primary cwd still blocks (single-dot segment, trailing)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/zz-nonexistent/.' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# A11 — PAIRED CONTROL. The false positive the new limbs could have introduced: a
# DOTFILE inside a legitimate analysis subfolder carries `/.` but is neither `/./`
# nor a trailing `/.`, so the carve-out must still admit it. Without this arm the
# fix could have been over-broadened to `*/.*` and stayed green.
test_case "Write analysis/<subfolder>/.hidden.md with primary cwd allows (dotfile is not a dot segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/hookfix-2026-01-01/.hidden.md' ''"$HOME"'/Claude')" \
  0

# A12 — OUTCOME pin for AC2's named subject. The tracked `analysis/README.md`
# stays blocked under a dot spelling. Environment-independent in OUTCOME but not
# in mechanism (normalizer where `analysis/` exists, arm 1 where it does not), so
# A9/A10 above are the discriminating pins and this one asserts the criterion.
test_case "Write analysis/./README.md with primary cwd still blocks (tracked file, dot spelling)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/analysis/./README.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# --- BLOCK-DESTRUCTIVE-019 keyed on the WRITE TARGET ---
#
# The exemptions read the target, never the session's working directory: a primary-rooted
# session may write its own worktree, and a worktree-rooted session may not write the
# primary. Every subject below is a `zz-7497-*` path that exists on no runner, so the
# hook's normalizer takes the same branch everywhere (the carve-out block's convention).

# S1c..S1f — a primary Layer-1 target OUTSIDE every exemption, from a REPO-ROOTED worktree
# cwd → BLOCK. One arm per remaining class of the classification (CLAUDE.md is the first
# inverted arm above). S1d also pins the block message: it names the refused TARGET.
test_case "T7497-S1c: Edit pmo-platform/core/x.md with REPO-ROOTED worktree cwd blocks (target-keyed)" \
  "$(edit_payload ''"$HOME"'/Claude/pmo-platform/core/zz-7497-probe/x.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-S1d: Write .claude/settings.json with REPO-ROOTED worktree cwd blocks, the message naming the target" \
  "$(write_payload ''"$HOME"'/Claude/.claude/settings.json' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt')" \
  2 'BLOCK-DESTRUCTIVE-019.*target=[^ ]*/\.claude/settings\.json'

test_case "T7497-S1e: Write .claude/hooks/x.sh with REPO-ROOTED worktree cwd blocks (target-keyed)" \
  "$(write_payload ''"$HOME"'/Claude/.claude/hooks/zz-7497-probe.sh' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-S1f: Write .claude/rules/x.md with REPO-ROOTED worktree cwd blocks (target-keyed)" \
  "$(write_payload ''"$HOME"'/Claude/.claude/rules/zz-7497-probe.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt')" \
  2 "BLOCK-DESTRUCTIVE-019"

# P1a..P1c — a target INSIDE a repo-rooted worktree from a PRIMARY-rooted session → ALLOW.
# This is the misfire the re-key removes: a session launched in the primary could not
# write into its own worktree.
test_case "T7497-P1a: Write worktree/core/x.md with primary cwd allows (the target is in a worktree)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/core/x.md' ''"$HOME"'/Claude')" \
  0

test_case "T7497-P1b: Edit worktree/core/x.md with primary cwd allows (Edit parity)" \
  "$(edit_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/core/x.md' ''"$HOME"'/Claude')" \
  0

test_case "T7497-P1c: Write worktree/core/x.md with a pmo-platform cwd allows (repo-rooted primary session)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/core/x.md' ''"$HOME"'/Claude/pmo-platform')" \
  0

# B1..B3 — the worktree home's base, on the target axis.
test_case "T7497-B1: Write .claude/worktrees-old/zz/x.md with primary cwd blocks (a prefix is not a segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees-old/zz/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-B2: Write release/.claude/worktrees/zz/x.md with primary cwd blocks (anchored at the repo root)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/release/.claude/worktrees/zz/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-B3: Write worktrees/zz-7497-file.md with primary cwd blocks (a <name>/ segment is required)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-file.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# D1..D6 — the as-written dot-segment guard, ahead of the worktree arm. `..` escapes
# textually; a single `.` fakes the <name>/ segment. D1 is the escape from a worktree-rooted
# session, which allowed before the re-key. D2, D3 and D5 already block; they pin the guard
# and the resolved view against a naive re-key that reads the as-written path alone. D6 is
# the paired control: a dotfile carries `/.` but is not a dot segment.
test_case "T7497-D1: Write worktree/../../../core/x.md with REPO-ROOTED worktree cwd blocks (dot-segment guard)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/../../../core/zz-nonexistent/x.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-D2: Write worktree/../../../core/x.md with primary cwd blocks (dot-segment guard)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/../../../core/zz-nonexistent/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-D3: Write worktree/zz/.. with primary cwd blocks (trailing .. segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/zz/..' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-D5: Write worktree/. with primary cwd blocks (a single dot fakes the <name>/ segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/.' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-D6: Write worktree/.hidden.md with primary cwd allows (a dotfile is not a dot segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/.hidden.md' ''"$HOME"'/Claude')" \
  0

# R1..R8 — the roadmap-instance carve-out. Instances are git-ignored and flat under
# pmo-platform/roadmaps/, writable from a primary-rooted and a worktree-rooted session; the
# one tracked file there, README.md, stays blocked in any case spelling (the volume may fold
# case, and realpath keeps the spelled case).
test_case "T7497-R1: Write roadmaps/<name>.md with primary cwd allows (a roadmap instance)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/zz-7497-initiative.md' ''"$HOME"'/Claude')" \
  0

test_case "T7497-R2: Write roadmaps/<name>.md with REPO-ROOTED worktree cwd allows (non-regression)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/zz-7497-initiative.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt')" \
  0

test_case "T7497-R3: Edit roadmaps/<name>.md with primary cwd allows (Edit parity)" \
  "$(edit_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/zz-7497-initiative.md' ''"$HOME"'/Claude')" \
  0

test_case "T7497-R4: Write roadmaps/README.md with primary cwd blocks (the tracked file)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/README.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-R5: Write roadmaps/readme.md with primary cwd blocks (a case spelling of the tracked file)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/readme.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-R6: Write roadmaps/../core/x.md with primary cwd blocks (dot-segment guard)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/../core/zz-nonexistent/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-R7: Write roadmaps-notes/x.md with primary cwd blocks (a prefix is not a segment)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps-notes/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

test_case "T7497-R8: Write release/roadmaps/x.md with primary cwd blocks (anchored at the repo root)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/release/roadmaps/x.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# FM4 — a dot-leading leaf of the flat roadmaps home is never exempt. git reads an ignore
# file placed at the top of that home, and one could re-include the git-ignored instances.
# The analysis home's subfolder segment rules that out (git never descends into an ignored
# subfolder); a flat home has no such segment, so the carve-out refuses every dot-leaf.
test_case "T7497-FM4: Write roadmaps/.gitignore with primary cwd blocks (a dot-leading leaf is never exempt)" \
  "$(write_payload ''"$HOME"'/Claude/pmo-platform/roadmaps/.gitignore' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# CD2 — a worktree's `.git` leaf is never exempt, in any case spelling. In a linked worktree
# `.git` is a pointer FILE, which the -016 `.git/config|hooks|info` arms do not reach, and
# no Write/Edit workflow writes it. ONE arm, TWO payloads: it passes only when the exact
# name AND a case variant both block, so the case claim is asserted rather than stated.
t7497_cd2_ok=1
t7497_cd2_detail=""
for t7497_cd2_leaf in .git .GIT; do
  t7497_cd2_err="$(/usr/bin/mktemp)"
  t7497_cd2_rc=0
  /usr/bin/printf '%s' "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/zz-7497-wt/'"$t7497_cd2_leaf" ''"$HOME"'/Claude')" \
    | /bin/bash "$HOOK" 2>"$t7497_cd2_err" >/dev/null || t7497_cd2_rc="$?"
  if [ "$t7497_cd2_rc" != 2 ] || ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-019' "$t7497_cd2_err"; then
    t7497_cd2_ok=0
    t7497_cd2_detail="${t7497_cd2_detail} ${t7497_cd2_leaf}:exit=${t7497_cd2_rc}"
  fi
  /bin/rm -f "$t7497_cd2_err"
done
if [ "$t7497_cd2_ok" = 1 ]; then
  /usr/bin/printf 'PASS: %s\n' "T7497-CD2: Write worktree/.git and worktree/.GIT with primary cwd blocks (a .git leaf is never exempt)"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  expected_exit=2 BLOCK-DESTRUCTIVE-019 for both spellings; got%s\n' "T7497-CD2: Write worktree/.git and worktree/.GIT with primary cwd blocks (a .git leaf is never exempt)" "$t7497_cd2_detail"
  FAIL=$((FAIL + 1))
fi

# MSG1 — a target the AS-WRITTEN view refuses is told why. Two causes, one payload each: a
# dot segment (a dot-segment spelling of a path inside a worktree) and an excluded leaf (a
# worktree's .git). Neither target is outside a worktree, so the block message must name its
# as-written cause and must not tell the caller the target "is not inside a worktree". ONE
# arm, TWO payloads: it passes only when both messages hold, and it asserts the message
# alone — the verdict, the exit code and the rule ID are the other arms'.
t7497_msg_ok=1
t7497_msg_detail=""
for t7497_msg_case in "zz-7497-wt/zz/./x.md|dot segment" "zz-7497-wt/.git|excluded leaf"; do
  t7497_msg_rel="${t7497_msg_case%%|*}"
  t7497_msg_cause="${t7497_msg_case#*|}"
  t7497_msg_err="$(/usr/bin/mktemp)"
  t7497_msg_rc=0
  /usr/bin/printf '%s' "$(write_payload ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/'"$t7497_msg_rel" ''"$HOME"'/Claude')" \
    | /bin/bash "$HOOK" 2>"$t7497_msg_err" >/dev/null || t7497_msg_rc="$?"
  if [ "$t7497_msg_rc" != 2 ] \
     || ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-019' "$t7497_msg_err" \
     || ! /usr/bin/grep -qF 'is refused as written: ' "$t7497_msg_err" \
     || ! /usr/bin/grep -qF "$t7497_msg_cause" "$t7497_msg_err" \
     || /usr/bin/grep -qF 'is not inside a worktree' "$t7497_msg_err"; then
    t7497_msg_ok=0
    t7497_msg_detail="${t7497_msg_detail} [${t7497_msg_rel}: exit=${t7497_msg_rc}; $(/bin/cat "$t7497_msg_err")]"
  fi
  /bin/rm -f "$t7497_msg_err"
done
if [ "$t7497_msg_ok" = 1 ]; then
  /usr/bin/printf 'PASS: %s\n' "T7497-MSG1: a target refused as written is told its cause (a dot segment; an excluded leaf), not that it is outside a worktree"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  expected exit 2, BLOCK-DESTRUCTIVE-019, the as-written cause named and no "is not inside a worktree"; got%s\n' "T7497-MSG1: a target refused as written is told its cause (a dot segment; an excluded leaf), not that it is outside a worktree" "$t7497_msg_detail"
  FAIL=$((FAIL + 1))
fi

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
# portably on BSD/macOS and GNU/Linux alike. What the two arms below pin: a
# ..-bearing spelling under a classified prefix is refused, from a primary cwd and
# from a repo-rooted worktree cwd, whether or not $HOME/Claude/CLAUDE.md exists.
# Each target as written already sits under a classified prefix, so neither arm
# turns on the normalization itself.

test_case "../-escape from .claude/hooks to CLAUDE.md (primary cwd) blocks" \
  "$(write_payload ''"$HOME"'/Claude/.claude/hooks/../../CLAUDE.md' ''"$HOME"'/Claude')" \
  2 "BLOCK-DESTRUCTIVE-019"

# The same escape from a REPO-ROOTED worktree cwd → BLOCK. It allowed before the re-key,
# because the cwd exempted it; keyed on the target it blocks like the primary-cwd arm above.
# The third deliberate inversion.
test_case "../-escape from .claude/hooks to CLAUDE.md (REPO-ROOTED worktree cwd) blocks (target-keyed; inverted from allow)" \
  "$(write_payload ''"$HOME"'/Claude/.claude/hooks/../../CLAUDE.md' ''"$HOME"'/Claude/pmo-platform/.claude/worktrees/foo')" \
  2 "BLOCK-DESTRUCTIVE-019"

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

# ==========================================================================
# BLOCK-DESTRUCTIVE-019 — the RESOLVED view (real symlinks) and subject parity
# ==========================================================================
#
# -019 grants an exemption only when the target AS WRITTEN and its RESOLVED location sit in
# the same home, and it resolves the target and the workspace root through the SAME
# fail-closed resolver (python realpath, via script_realpath). These arms need real
# symlinks, so they run in a sandbox workspace exported as CLAUDE_WORKSPACE_ROOT. The
# sandbox root is made PHYSICAL first: macOS spells a mktemp path through /var ->
# /private/var, and a symlink-spelled root is the shape the FM1 arms exercise on purpose,
# not one the other arms should inherit by accident. They sit here, after sandbox_case().

echo ""
echo "BLOCK-DESTRUCTIVE-019 resolved view (sandbox) + subject parity"
echo "---"

T7497_SB="$(cd -P -- "$(/usr/bin/mktemp -d)" && pwd -P)"
T7497_WT="${T7497_SB}/pmo-platform/.claude/worktrees/wt1"
/bin/mkdir -p "${T7497_WT}/real" "${T7497_SB}/pmo-platform/core"
/bin/ln -s "${T7497_SB}/pmo-platform/core" "${T7497_WT}/lnk"
/bin/ln -s "${T7497_SB}/pmo-platform/core/zz-dang.md" "${T7497_WT}/dang.md"
/bin/ln -s "${T7497_WT}/real" "${T7497_WT}/inlnk"
/usr/bin/printf 'x\n' > "${T7497_WT}/real/zz-7497-existing.md"
/usr/bin/printf 'x\n' > "${T7497_SB}/pmo-platform/core/zz-7497-target.md"
/bin/ln -s "${T7497_SB}/pmo-platform/core/zz-7497-target.md" "${T7497_WT}/zz-7497-leaf.md"
t7497_prev_cwr="${CLAUDE_WORKSPACE_ROOT-__t7497_unset__}"
export CLAUDE_WORKSPACE_ROOT="$T7497_SB"

# L2..L6 — a worktree-prefixed spelling whose resolved location leaves the worktree gets no
# exemption: L2 through a symlinked ancestor over a missing tail, L3 through a dangling
# leaf. The exemption is live in the same sandbox (L4, L5), and resolution does not
# over-block an in-worktree symlink (L6).
sandbox_case "T7497-L2: symlinked ancestor + missing tail resolving into the primary blocks" "$HOOK" \
  "$(write_payload "${T7497_WT}/lnk/zz-new/x.md" "$T7497_SB")" 2 "BLOCK-DESTRUCTIVE-019"
sandbox_case "T7497-L3: dangling leaf symlink into the primary blocks" "$HOOK" \
  "$(write_payload "${T7497_WT}/dang.md" "$T7497_SB")" 2 "BLOCK-DESTRUCTIVE-019"
sandbox_case "T7497-L4: real directory inside the worktree allows (the sandbox exemption is live)" "$HOOK" \
  "$(write_payload "${T7497_WT}/real/x.md" "$T7497_SB")" 0
sandbox_case "T7497-L5: new directory inside the worktree allows" "$HOOK" \
  "$(write_payload "${T7497_WT}/zz-new/x.md" "$T7497_SB")" 0
sandbox_case "T7497-L6: in-worktree symlink allows (resolution does not over-block)" "$HOOK" \
  "$(write_payload "${T7497_WT}/inlnk/x.md" "$T7497_SB")" 0

# FM2a..FM2c — the branches the arms above cannot reach. Every subject above is absent, so
# each lands on the unresolved branch. An EXISTING target takes the resolved branch: every
# real Edit inside a worktree takes it (FM2a), and it is the only branch an existing symlink
# leaf into the primary can reach (FM2b). FM2c: with python unavailable neither the target
# nor the root resolves, so no exemption is granted. Its hook is a copy with the python
# path rewritten, placed beside the shipped hook so its libs resolve; a copy the rewrite
# left byte-identical FAILs the arm rather than testing the shipped hook by accident.
sandbox_case "T7497-FM2a: Edit an existing file inside the worktree allows (the resolved branch)" "$HOOK" \
  "$(edit_payload "${T7497_WT}/real/zz-7497-existing.md" "$T7497_SB")" 0
sandbox_case "T7497-FM2b: Write an existing symlink leaf into the primary blocks (the resolved branch)" "$HOOK" \
  "$(write_payload "${T7497_WT}/zz-7497-leaf.md" "$T7497_SB")" 2 "BLOCK-DESTRUCTIVE-019"
T7497_NOPY="$(dirname "$HOOK")/block-destructive.T7497-nopy-mutant.sh"
/usr/bin/sed 's#^readonly PYTHON3="/usr/bin/python3"$#readonly PYTHON3="/nonexistent/t7497/python3"#' "$HOOK" > "$T7497_NOPY"
if /usr/bin/cmp -s "$HOOK" "$T7497_NOPY"; then
  /usr/bin/printf 'FAIL: T7497-FM2c: the python-unavailable rewrite is INERT (the copy is byte-identical to the shipped hook)\n'
  FAIL=$((FAIL + 1))
else
  sandbox_case "T7497-FM2c: python unavailable, a worktree target gets no exemption (fails closed)" "$T7497_NOPY" \
    "$(write_payload "${T7497_WT}/real/x.md" "$T7497_SB")" 2 "BLOCK-DESTRUCTIVE-019"
fi
/bin/rm -f "$T7497_NOPY"

# FM1a, FM1b — the workspace root resolves through the SAME resolver as the target, and
# fails closed. Here the root is spelled through a symlink to a directory that does not
# exist yet: the shape a HOME=$(mktemp -d) regression run gives on macOS, where the new HOME
# is spelled through /var -> /private/var and holds no workspace. A root resolved any other
# way (a `cd -P` that falls back to the raw spelling when the directory is absent) never
# agrees with the resolved target, and every exemption silently becomes a block. A fixture
# precondition is folded into both arms, so a mis-built sandbox FAILs rather than reading
# as a vacuous allow.
T7497_SYM="$(cd -P -- "$(/usr/bin/mktemp -d)" && pwd -P)"
/bin/ln -s "${T7497_SYM}/ws-not-yet" "${T7497_SYM}/ws"
export CLAUDE_WORKSPACE_ROOT="${T7497_SYM}/ws"
if [ -L "${T7497_SYM}/ws" ] && [ ! -e "${T7497_SYM}/ws" ]; then
  sandbox_case "T7497-FM1a: symlink-spelled absent root, a worktree target allows (the root resolved like the target)" "$HOOK" \
    "$(write_payload "${T7497_SYM}/ws/pmo-platform/.claude/worktrees/wt1/x.md" "${T7497_SYM}/ws")" 0
  sandbox_case "T7497-FM1b: symlink-spelled absent root, an analysis target allows (the root resolved like the target)" "$HOOK" \
    "$(write_payload "${T7497_SYM}/ws/pmo-platform/analysis/zz-7497-sub/x.md" "${T7497_SYM}/ws")" 0
else
  /usr/bin/printf 'FAIL: T7497-FM1a: fixture not built (the root link is not a dangling symlink)\n'
  FAIL=$((FAIL + 1))
  /usr/bin/printf 'FAIL: T7497-FM1b: fixture not built (the root link is not a dangling symlink)\n'
  FAIL=$((FAIL + 1))
fi

if [ "$t7497_prev_cwr" = "__t7497_unset__" ]; then unset CLAUDE_WORKSPACE_ROOT; else export CLAUDE_WORKSPACE_ROOT="$t7497_prev_cwr"; fi
/bin/rm -rf "$T7497_SB" "$T7497_SYM"

# PAR-01..03 — subject parity, asserted rather than described. -019's exemptions must read
# the TARGET: no non-comment line between the rule's header and its block call may read the
# session's working directory, and the dot guard must precede the worktree arm, which must
# precede the resolved view. ONE awk pass over the file, index() rather than regexes, no
# pipeline, and its only `exit` statements inside END. It FAILS CLOSED: a marker that stops
# matching reports MARKER-MISSING rather than reading as parity.
t7497_par_check() {   # $1 = hook -> TARGET-KEYED | CWD-KEYED | GUARD-AFTER-ARM | MARKER-MISSING
  /usr/bin/awk '
    index($0, "# BLOCK-DESTRUCTIVE-019 ")        { if (hdr == 0) hdr = NR }
    index($0, "block \"BLOCK-DESTRUCTIVE-019\"") { blk = NR }
    index($0, "# M-019-DOTGUARD")                { if (grd == 0) grd = NR }
    index($0, "# M-019-WORKTREE")                { if (wtr == 0) wtr = NR }
    index($0, "# M-019-RESOLVE")                 { if (rsv == 0) rsv = NR }
    { c = $0; sub(/^[ \t]+/, "", c)
      if (substr(c, 1, 1) != "#" && (index(c, "$CWD") || index(c, "${CWD}"))) { n++; cl[n] = NR } }
    END {
      if (hdr == 0 || blk == 0 || blk < hdr) { printf "MARKER-MISSING"; exit }
      for (i = 1; i <= n; i++) if (cl[i] > hdr && cl[i] <= blk + 2) { printf "CWD-KEYED"; exit }
      if (grd == 0 || wtr == 0 || rsv == 0) { printf "MARKER-MISSING"; exit }
      if (!(grd > hdr && wtr > grd && rsv > wtr && blk > rsv)) { printf "GUARD-AFTER-ARM"; exit }
      printf "TARGET-KEYED"
    }' "$1"
}

t7497_par_shipped="$(t7497_par_check "$HOOK")"
if [ "$t7497_par_shipped" = "TARGET-KEYED" ]; then
  /usr/bin/printf 'PASS: T7497-PAR-01 the shipped -019 exemptions read the target, the dot guard first\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T7497-PAR-01 -019 subject parity\n  expected=TARGET-KEYED actual=%s\n' "$t7497_par_shipped"
  FAIL=$((FAIL + 1))
fi

# PAR-02, PAR-03 — the checker's red-before controls. A checker that cannot fail proves
# nothing, so it also reads two fixtures: one whose exemption reads the working directory
# (it must report CWD-KEYED) and one whose worktree arm precedes the dot guard (it must
# report GUARD-AFTER-ARM).
T7497_PAR_CWD="$(/usr/bin/mktemp)"
T7497_PAR_ORD="$(/usr/bin/mktemp)"
# Each fixture line is literal hook source; nothing in it may expand.
# shellcheck disable=SC2016
/usr/bin/printf '%s\n' \
  '    # BLOCK-DESTRUCTIVE-019 — fixture: the exemption reads the working directory' \
  '      case "$FILE_PATH" in' \
  '        *"/../"*) ;;   # M-019-DOTGUARD' \
  '        "${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/"*/*) exempt_home="worktree" ;;   # M-019-WORKTREE' \
  '      esac' \
  '      exempt_resolved="$abs_target"   # M-019-RESOLVE' \
  '      case "$CWD" in' \
  '        "${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/"*) exit 0 ;;' \
  '      esac' \
  '      block "BLOCK-DESTRUCTIVE-019" "fixture" "fixture"' > "$T7497_PAR_CWD"
# shellcheck disable=SC2016
/usr/bin/printf '%s\n' \
  '    # BLOCK-DESTRUCTIVE-019 — fixture: the worktree arm precedes the dot guard' \
  '      case "$FILE_PATH" in' \
  '        "${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/"*/*) exempt_home="worktree" ;;   # M-019-WORKTREE' \
  '        *"/../"*) ;;   # M-019-DOTGUARD' \
  '      esac' \
  '      exempt_resolved="$abs_target"   # M-019-RESOLVE' \
  '      block "BLOCK-DESTRUCTIVE-019" "fixture" "fixture"' > "$T7497_PAR_ORD"

t7497_par_cwd="$(t7497_par_check "$T7497_PAR_CWD")"
if [ "$t7497_par_cwd" = "CWD-KEYED" ]; then
  /usr/bin/printf 'PASS: T7497-PAR-02 the checker REPORTS an exemption keyed on the working directory\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T7497-PAR-02 the checker did not report a cwd-keyed exemption\n  expected=CWD-KEYED actual=%s\n' "$t7497_par_cwd"
  FAIL=$((FAIL + 1))
fi

t7497_par_ord="$(t7497_par_check "$T7497_PAR_ORD")"
if [ "$t7497_par_ord" = "GUARD-AFTER-ARM" ]; then
  /usr/bin/printf 'PASS: T7497-PAR-03 the checker REPORTS a worktree arm ahead of the dot guard\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T7497-PAR-03 the checker did not report the misordered guard\n  expected=GUARD-AFTER-ARM actual=%s\n' "$t7497_par_ord"
  FAIL=$((FAIL + 1))
fi
/bin/rm -f "$T7497_PAR_CWD" "$T7497_PAR_ORD"

# ==========================================================================
# PARSE-* — parse-only (noexec) exemption + the two admitted allowlist paths
# ==========================================================================
#
# Subject: BLOCK-DESTRUCTIVE-022 refused `bash -n <script>` — an invocation that
# PARSES AND EXITS, executing nothing — while permitting several forms that do
# execute. It also refused two named platform scripts the corpus tells agents to
# run. Both are refusals outside any arm's declared scope.
#
# EVERY "ALLOW" ARM BELOW IS PAIRED WITH A CONTROL THAT MUST BLOCK. An exemption
# suite in which nothing blocks cannot distinguish a working exemption from a
# dead allowlist or an inert hook, and would read green either way.

echo ""
echo "PARSE-*: parse-only exemption + allowlist admission (#6172)"
echo "---"

# The non-allowlisted fixture path. Deliberately reused across the AC-3/4/5 arms
# so each ALLOW and its BLOCK control differ ONLY by the flag under test.
PARSE_UNLISTED="core/deploy/tools/no-such-tool-xyz.sh"

# --- AC-1: the two named paths execute, in both repository-relative spellings ---
test_case "PARSE-01: bash core/deploy/tools/check-convention.sh allowed (bare-relative)" \
  "$(bash_payload 'bash core/deploy/tools/check-convention.sh')" 0
test_case "PARSE-02: bash ./core/deploy/tools/check-convention.sh allowed (dot-relative)" \
  "$(bash_payload 'bash ./core/deploy/tools/check-convention.sh')" 0
test_case "PARSE-03: bash core/deploy/tests/test_check49_mode_identifier_unification.sh allowed (bare-relative)" \
  "$(bash_payload 'bash core/deploy/tests/test_check49_mode_identifier_unification.sh')" 0
test_case "PARSE-04: bash ./core/deploy/tests/test_check49_mode_identifier_unification.sh allowed (dot-relative)" \
  "$(bash_payload 'bash ./core/deploy/tests/test_check49_mode_identifier_unification.sh')" 0

# AC-1 control arm THAT MUST FIRE: a sibling-shaped path that was never admitted
# still blocks. Without it, PARSE-01..04 would read green against an allowlist
# that had stopped being consulted at all.
test_case "PARSE-05 [ctl]: bash <unlisted>.sh still blocks (AC-1 is not a dead allowlist)" \
  "$(bash_payload "bash $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- AC-2 / CIAC-1: the widening is FORM-SCOPED, not path-scoped ---
# The rows added for these two scripts are repository-relative ONLY. The absolute
# spelling of the SAME script must still be refused — that is what makes the -022
# hint's "retry the allowlisted relative form" truthful rather than decorative,
# and it is why the added allowlist block carries a do-not-complete-to-four-forms
# guard. If someone adds the absolute form, this arm goes red and says why.
test_case "PARSE-06 [ctl]: ABSOLUTE spelling of check-convention.sh still blocks (CIAC-1 form-scoping)" \
  "$(bash_payload 'bash /srv/pmo-platform/core/deploy/tools/check-convention.sh')" 2 "BLOCK-DESTRUCTIVE-022"

# --- AC-3: parse-only is not execution ---
test_case "PARSE-07: bash -n <unlisted>.sh allowed (parses and exits; executes nothing)" \
  "$(bash_payload "bash -n $PARSE_UNLISTED")" 0

# --- AC-4 / CIAC-2: the exemption is keyed on the INTERPRETER, not on the token ---
test_case "PARSE-08: sh -n <unlisted>.sh allowed" \
  "$(bash_payload "sh -n $PARSE_UNLISTED")" 0
test_case "PARSE-09: zsh -n <unlisted>.sh allowed" \
  "$(bash_payload "zsh -n $PARSE_UNLISTED")" 0
# Control arms that MUST fire: `source`/`.` are builtins taking no options, so a
# `-n` there is an OPERAND, not a parse-only flag. They reach the table's explicit
# null and keep blocking. A flag-keyed exemption would wrongly allow both.
test_case "PARSE-10 [ctl]: source -n <unlisted>.sh still blocks (per-interpreter null)" \
  "$(bash_payload "source -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "PARSE-11 [ctl]: . -n <unlisted>.sh still blocks (per-interpreter null)" \
  "$(bash_payload ". -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- AC-5: executing forms stay refused (per-flag fixture table) ---
# The `-c` pair is the load-bearing entry. `bash -c '<prog>' -n <p>` GENUINELY
# EXECUTES: the walk breaks at `-c`, so the trailing `-n` is never seen as a flag.
# `bash -n -c '<prog>'` is declined by the explicit no-`-c` conjunct instead.
test_case "PARSE-12a [ctl]: bash <unlisted>.sh blocks (no flag)" \
  "$(bash_payload "bash $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "PARSE-12b [ctl]: bash -x <unlisted>.sh blocks (executing flag)" \
  "$(bash_payload "bash -x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "PARSE-12c [ctl]: bash -s <unlisted>.sh blocks (executing flag)" \
  "$(bash_payload "bash -s $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "PARSE-12d [ctl]: bash -- <unlisted>.sh blocks (end-of-options)" \
  "$(bash_payload "bash -- $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "PARSE-12e [ctl]: bash -c '<prog>' -n <unlisted>.sh blocks (TRAILING -n; this form executes)" \
  "$(bash_payload "bash -c 'echo hi' -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "PARSE-12f [ctl]: bash -n -c '<prog>' blocks (cmode conjunct declines the exemption)" \
  "$(bash_payload "bash -n -c 'echo hi' $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# A cluster is a DECLARED RESIDUAL, not an admitted spelling: unchanged behaviour.
test_case "PARSE-12g [ctl]: bash -nx <unlisted>.sh still blocks (cluster is a declared residual)" \
  "$(bash_payload "bash -nx $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- AC-7: an already-permitted path must not change verdict ---
test_case "PARSE-13: bash -n core/deploy/deploy.sh still allowed (was ALLOW at baseline)" \
  "$(bash_payload 'bash -n core/deploy/deploy.sh')" 0

# --- AC-6: PAIRED MUTATION ARM — proves PARSE-07's detector is LIVE ---
#
# Three arms in this milestone's prior release read green while their mutation was
# INERT, so this harness asserts the mutation actually changed the file before it
# believes anything the mutant reports. The mutant is written as a SIBLING of the
# real hook so HOOK_DIR — and therefore every lib and the allowlist — resolves
# identically; the mutant differs from the shipped hook in exactly one predicate.
PARSE_MUTANT="$(dirname "$HOOK")/block-destructive.PARSE-mutant.sh"
/usr/bin/sed 's#\[ "\$script_noexec" -eq 1 \]#[ "$script_noexec" -eq 99 ]#' \
  "$HOOK" > "$PARSE_MUTANT"

# (a) NON-INERTNESS GATE. If the substitution matched nothing the mutant is a byte
#     copy, the "mutant blocks" arm below would be measuring the shipped hook, and
#     a green result would mean nothing. Fail loudly instead.
if /usr/bin/cmp -s "$HOOK" "$PARSE_MUTANT"; then
  /usr/bin/printf 'FAIL: PARSE-14a mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: PARSE-14a mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

# (b) The mutant — exemption reverted — must BLOCK the very payload the shipped
#     hook allows at PARSE-07. This is what proves PARSE-07 measures the exemption
#     rather than a permissive hook.
sandbox_case "PARSE-14b: mutant (exemption reverted) BLOCKS bash -n <unlisted>.sh" \
  "$PARSE_MUTANT" \
  "$(bash_payload "bash -n $PARSE_UNLISTED")" \
  2 "BLOCK-DESTRUCTIVE-022"

# (c) The shipped hook allows the identical payload in the same run — the pair is
#     the evidence, not either arm alone.
test_case "PARSE-14c: shipped hook ALLOWS the identical payload (mutation pair closes)" \
  "$(bash_payload "bash -n $PARSE_UNLISTED")" 0

/bin/rm -f "$PARSE_MUTANT"

echo ""
echo "BLOCK-022 flag-walk OPTION ARITY (#6172 F-01)"
echo "---"
#
# WHAT THESE ARMS ARE FOR. The flag walk stepped over `-*` one token at a time and
# called the first non-option the operand. It had no notion of option ARITY, so an
# option that takes a SEPARATE argument left that argument sitting in the operand
# slot — and the walk was wrong in two directions at once:
#
#   (1) It adjudicated the ARGUMENT instead of the script. `bash --rcfile <allowed>
#       <unlisted>` checked the rcfile, found it allowlisted, allowed the segment,
#       and never saw the script bash actually runs. Measured on origin/main as
#       well as on this branch: INHERITED, not introduced here.
#
#   (2) It offered the ARGUMENT to the parse-only table as though it were a FLAG.
#       In `bash --rcfile -n <unlisted>` bash has taken `-n` as the rcfile
#       FILENAME, so the invocation EXECUTES <unlisted> — but the walk read `-n`,
#       set script_noexec, and the parse-only exemption allowed the whole segment.
#       origin/main BLOCKS this payload and this branch ALLOWED it: INTRODUCED by
#       the #6172 exemption, and the reason F-01 is a live block-to-allow rather
#       than an inherited gap.
#
# Both are one cause, so they get one fix and one block of arms. The arity table is
# MEASURED against the interpreters, not inferred: `<interp> <opt> -n -c 'echo X'`
# prints X exactly when <opt> consumed the `-n`.
#
# THE PROPERTY THESE ARMS PIN, and the one an edit is most likely to break: a
# consumed argument is STILL ADJUDICATED. Consuming it and stepping over it would
# close (1) and (2) while moving a claimed token out of adjudication — the one
# direction the walk's NET DIRECTION rule forbids, and the direction that would
# flip ARITY-11 from BLOCK to ALLOW. ARITY-11 is that control and it is the arm to
# read first if this block ever goes red.
ARITY_ALLOWED="core/deploy/deploy.sh"

# --- (1) an argument-taking option preceding a NON-ALLOWLISTED operand ---
test_case "ARITY-01: bash --rcfile <allowed> <unlisted>.sh blocks (operand is the SCRIPT, not the rcfile)" \
  "$(bash_payload "bash --rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "ARITY-02: bash --init-file <allowed> <unlisted>.sh blocks" \
  "$(bash_payload "bash --init-file $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "ARITY-03: sh --rcfile <allowed> <unlisted>.sh blocks (/bin/sh is bash on the reference host)" \
  "$(bash_payload "sh --rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# The short argument-taking forms reach the same walk. `-O shopt_option` and
# `-o option` take a shell-option NAME, which claims no operand domain — so before
# the fix the walk stopped on a name it could not adjudicate and the script behind
# it escaped entirely. This is the shape the noexec table's own comment recorded as
# making `-o noexec` unreachable.
test_case "ARITY-04: bash -O expand_aliases <unlisted>.sh blocks (-O takes a shopt name)" \
  "$(bash_payload "bash -O expand_aliases $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "ARITY-05: zsh -o noexec <unlisted>.sh blocks (-o takes an option name)" \
  "$(bash_payload "zsh -o noexec $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- (2) the same, with an inert-mode flag ALSO present as the option's argument ---
# These are the block-to-allow arms. On origin/main all three BLOCK.
test_case "ARITY-06: bash --rcfile -n <unlisted>.sh blocks (-n is the rcfile NAME; this executes)" \
  "$(bash_payload "bash --rcfile -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "ARITY-07: bash --init-file -n <unlisted>.sh blocks (-n is the init-file NAME)" \
  "$(bash_payload "bash --init-file -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# zsh implements neither long option and exits "no such option", so nothing runs
# either way. It is listed in the arity table regardless: the alternative leaves the
# verdict resting on another program's option parser, which this control does not
# reason about. See the ZSH ROWS note on script_interp_optarg_flag.
test_case "ARITY-08: zsh --rcfile -n <unlisted>.sh blocks (verdict does not rest on zsh's parser)" \
  "$(bash_payload "zsh --rcfile -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- (3) a GENUINE parse-only invocation is still admitted — #6172's whole point ---
# The fix must close the arity hole without taking back the exemption. ARITY-10 is
# the discriminating arm: the rcfile argument is consumed, and the `-n` that
# FOLLOWS it is a real parse-only flag, so the segment is genuinely inert.
test_case "ARITY-09: bash -n <unlisted>.sh still allowed (parse-only survives the arity fix)" \
  "$(bash_payload "bash -n $PARSE_UNLISTED")" 0
test_case "ARITY-10: bash --rcfile <allowed> -n <unlisted>.sh allowed (a REAL -n after a consumed argument)" \
  "$(bash_payload "bash --rcfile $ARITY_ALLOWED -n $PARSE_UNLISTED")" 0

# --- Control arms THAT MUST FIRE ---
# ARITY-11 is the load-bearing one: the consumed argument is still adjudicated. A
# consume-and-skip implementation passes every arm above and ALLOWS this one.
test_case "ARITY-11 [ctl]: bash --rcfile <unlisted>.sh <allowed> blocks (a consumed argument is STILL adjudicated)" \
  "$(bash_payload "bash --rcfile $PARSE_UNLISTED $ARITY_ALLOWED")" 2 "BLOCK-DESTRUCTIVE-022"
# `--rcfile=FILE` is not a bash spelling at all (bash rejects it), so no token is
# consumed and the operand is unchanged. Pins the arity table to the exact separate-
# argument forms rather than a `--rcfile*` prefix.
test_case "ARITY-12 [ctl]: bash --rcfile=<allowed> <unlisted>.sh blocks (attached form consumes nothing)" \
  "$(bash_payload "bash --rcfile=$ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# `-c` breaks the walk before the arity step can run, so cmode still wins.
test_case "ARITY-13 [ctl]: bash -c '<prog>' -n <unlisted>.sh still blocks (the -c break precedes arity)" \
  "$(bash_payload "bash -c 'echo hi' -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# The source arm consumes nothing: `source`/`.` are builtins that take no options,
# so the first non-option is still the operand there.
test_case "ARITY-14 [ctl]: source --rcfile <unlisted>.sh <allowed> blocks (source arm consumes no argument)" \
  "$(bash_payload "source --rcfile $PARSE_UNLISTED $ARITY_ALLOWED")" 2 "BLOCK-DESTRUCTIVE-022"
# A trailing option whose argument ends argv leaves no operand; the index bound
# keeps the walk from reading past the end, and the argument is adjudicated anyway.
test_case "ARITY-15 [ctl]: bash --rcfile <allowed> allowed (argument ends argv; no operand follows)" \
  "$(bash_payload "bash --rcfile $ARITY_ALLOWED")" 0
# The cluster residual is untouched by arity — still refused, exactly as before.
test_case "ARITY-16 [ctl]: bash -nx <unlisted>.sh still blocks (cluster residual unchanged)" \
  "$(bash_payload "bash -nx $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- (4) `zsh --emulate` — the row a letter-by-letter sweep misses ---
# zsh's own `--help` lists its "special options" as --help, --version, -b, -c and
# `-o OPTION`, and does NOT name --emulate. It exists all the same, it takes a
# SEPARATE argument, and that makes it the same defect shape as ARITY-06/07:
#
#   zsh --emulate -n -s  <<< 'echo RUNOK'  ->  RUNOK    (-n eaten as the mode NAME)
#   zsh -n -s            <<< 'echo RUNOK'  ->  (empty)  (control: -n really is inert)
#
# so `zsh --emulate -n <unlisted>` EXECUTES, and before this row the walk read the
# `-n` as a flag and the parse-only exemption allowed the segment. origin/main
# BLOCKS the payload; this branch ALLOWED it until the row was added — the same
# block-to-allow F-01 names, on the interp domain, not phase-gated.
#
# The row is measured, not inferred. The sweep enumerated zsh's whole option
# surface — every -X/+X single letter, and --<name>, --no<name>, --no-<name>,
# +-<name>, +-no-<name> for all 197 setopt names plus the 12 documented aliases
# (1135 spellings) — with a script-execution marker as the discriminator and
# controls firing both ways. Exactly two spellings execute despite a following
# `-n`: `--emulate` and `+-emulate`. BOTH are now in the table; an earlier form of
# this note said `+-emulate` was structurally excluded because the walk's option arm
# matches `-*` and a `+`-leading token fell to `*) break`. That `*) break` is gone —
# see FWALK-PLUS-* below, which is the arm set that records the new boundary.
test_case "ARITY-18a: zsh --emulate -n <unlisted>.sh blocks (-n is the emulation MODE NAME; this executes)" \
  "$(bash_payload "zsh --emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "ARITY-18b: zsh --emulate -n -x <unlisted>.sh blocks (trailing flags do not restore inertness)" \
  "$(bash_payload "zsh --emulate -n -x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# The discriminating arm: a REAL -n after a consumed mode name is genuinely inert,
# so #6172's exemption must still fire. This is ARITY-10's analogue for zsh.
test_case "ARITY-18c: zsh --emulate zsh -n <unlisted>.sh allowed (a REAL -n after the consumed mode name)" \
  "$(bash_payload "zsh --emulate zsh -n $PARSE_UNLISTED")" 0
# ARITY-11's analogue: the consumed mode-name slot is still adjudicated, so a
# non-allowlisted script sitting in it is caught rather than stepped over.
test_case "ARITY-18d [ctl]: zsh --emulate <unlisted>.sh <allowed> blocks (the consumed argument is STILL adjudicated)" \
  "$(bash_payload "zsh --emulate $PARSE_UNLISTED $ARITY_ALLOWED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- FWALK-PLUS-* : the `+`-leading arity surface, live since the walk stopped -----
# being dash-anchored. THIS IS THE ARM SET FOR A HOLE NEITHER SIDE OF THE MERGE HAS.
# `origin/main` advances past a `+`-leading option (its walk terminates on the operand
# DOMAIN, not on flag shape) and then adjudicates the real script — it has no
# parse-only exemption to fool, so `zsh +-emulate -n <unlisted>.sh` BLOCKS there. This
# branch never advanced past `+-emulate` at all, because `*) break` took it as the
# operand. Compose main's advance with this branch's parse-only exemption and the walk
# steps over `+-emulate`, offers the FOLLOWING `-n` to the noexec table as a flag, and
# exempts a segment the real shell EXECUTES. Measured inline, controls firing both
# ways: `zsh +-emulate -n -c 'echo X'` prints X; `zsh -n -c 'echo X'` is silent.
#
# The fix is the arity question asked in the advance-past arm — the same question the
# `-*` skip arm already asks — so it closes the CLASS rather than this spelling, and
# the `+O`/`+o` rows kept "for a later widening" become live with it. The `+` surface
# was re-swept before the row was added: 656 zsh and 89 bash/sh `+` spellings under the
# three-outcome read (B-named = consumed; A-named-and-REJECTED = consumed against a
# validated namespace; A-named-and-not-found = A was the script), controls firing on
# both readings. `+-emulate` is the ONLY arity-1 `+` spelling zsh has beyond `+o`, and
# the only one leaving the shell LIVE after eating a `-n` (`+o`/`+O` abort).
test_case "FWALK-PLUS-emulate: zsh +-emulate -n <unlisted>.sh blocks (the + spelling eats the -n too)" \
  "$(bash_payload "zsh +-emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-PLUS-emulate-x: zsh +-emulate -n -x <unlisted>.sh blocks (trailing flags do not restore inertness)" \
  "$(bash_payload "zsh +-emulate -n -x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# The QUOTED spelling is why the arity table is asked about the NORMALIZED token here
# and not the raw one: a `+`-leading token never reaches the flag-normalization step
# above, so a raw-token lookup would miss `'+-emulate'` and fall to the fail-OPEN side.
test_case "FWALK-PLUS-emulate-quoted: zsh '+-emulate' -n <unlisted>.sh blocks (normalized view feeds the table)" \
  "$(bash_payload "zsh '+-emulate' -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# ARITY-18d's analogue for the + spelling: consuming is not stepping over. The token
# in the consumed mode-name slot is still adjudicated, so it is caught there instead.
test_case "FWALK-PLUS-adjudicated [ctl]: zsh +-emulate <unlisted>.sh <allowed> blocks (consumed argument STILL adjudicated)" \
  "$(bash_payload "zsh +-emulate $PARSE_UNLISTED $ARITY_ALLOWED")" 2 "BLOCK-DESTRUCTIVE-022"
# ARITY-18c's analogue, and the arm that keeps this from being a blanket `+` over-block:
# a REAL -n after the consumed mode name is genuinely inert, so #6172's exemption must
# still fire. Without it, "block everything with a +" would pass every arm above.
test_case "FWALK-PLUS-ctl-inert: zsh +-emulate zsh -n <unlisted>.sh allowed (a REAL -n after the consumed mode name)" \
  "$(bash_payload "zsh +-emulate zsh -n $PARSE_UNLISTED")" 0
# The paired control for the OTHER direction: a `+` option that takes NO argument must
# not consume anything, so the -n after it is a real flag and the segment stays exempt.
# `+x` is arity 0 on every one of the three shells (swept, controls firing).
test_case "FWALK-PLUS-ctl-arity0: zsh +x -n <unlisted>.sh allowed (+x takes no argument; the -n is real)" \
  "$(bash_payload "zsh +x -n $PARSE_UNLISTED")" 0
# R1, the residual the walk-termination commit declared, is CLOSED for the + forms by
# the same overlay: a value-taking flag whose argument is an allowlisted script no
# longer hides the real operand, because the argument is consumed and adjudicated in
# place and the walk continues to the token the shell actually runs.
test_case "FWALK-PLUS-r1: zsh +-emulate <allowed> <unlisted>.sh blocks (flag argument no longer hides the operand)" \
  "$(bash_payload "zsh +-emulate $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

echo ""
echo "BLOCK-022 parse-only LAST-ONE-WINS (#6172 noexec latch)"
echo "---"
# SUBJECT: the parse-only flag was a ONE-WAY LATCH. It was set to 1 the first time an
# inert-mode spelling appeared and never cleared, but every shell in the table treats
# these options as LAST-ONE-WINS state. A later token that turns noexec back OFF left
# the hook reporting parse-only on an invocation the interpreter EXECUTES.
#
# MEASURED ON THE REFERENCE HOST, with the marker ASSEMBLED AT RUNTIME so that `-v`
# or `-x` echoing the source text cannot forge it (`p=OPER; q=AND_RAN; echo "${p}${q}"`
# piped to <interp> <opts> /dev/stdin):
#     bash -n +n            -> marker prints   (EXECUTES)
#     bash -n +o noexec     -> marker prints   (EXECUTES)
#     zsh  -n +-noexec      -> marker prints   (EXECUTES)
#     bash -n               -> silent          CONTROL: the exemption is real
#     bash +n -n            -> silent          CONTROL: order matters, last wins
#     bash -n +n -n         -> silent          CONTROL: interleaving resolves to ON
# The controls are what make this a defect rather than a boundary: the same tokens in
# the other order are genuinely inert, so a blanket "any `+` cancels it" would be as
# wrong as the latch, in the opposite direction.
#
# THE PREDICATE IS NOT A CLEARING TABLE, and that is the whole point of the fix. A
# table of clear-spellings symmetric to the set-table fails OPEN on omission — one
# unlisted way of writing "noexec off" and the parse-only claim stands while the
# script runs. Instead: parse-only is GRANTED only by positive recognition and
# REVOKED by every other token the walk steps over. A spelling never seen costs an
# over-block, never an exemption.
#
# BOTH ORDERS ARE ARMED ON PURPOSE. Three prior sweeps enumerated `<candidate> -n`
# and this class lives at `-n <candidate>`, which is how it survived them.

# (1) THE CLASS — a clearing form AFTER the set form. These ALLOW on the pre-fix hook.
test_case "NOEXEC-01: bash -n +n <unlisted>.sh blocks (+n turns noexec OFF; this EXECUTES)" \
  "$(bash_payload "bash -n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-02: sh -n +n <unlisted>.sh blocks (the walk is shared by every interpreter)" \
  "$(bash_payload "sh -n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-03: zsh -n +n <unlisted>.sh blocks" \
  "$(bash_payload "zsh -n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# `+o` is in the ARITY table, so `noexec` is consumed as its argument and never
# offered to the noexec table — the revocation must come from `+o` itself.
test_case "NOEXEC-04: bash -n +o noexec <unlisted>.sh blocks (clearing form with a separate argument)" \
  "$(bash_payload "bash -n +o noexec $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-05: zsh -n +-noexec <unlisted>.sh blocks (long `+` spelling of the same clear)" \
  "$(bash_payload "zsh -n +-noexec $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# INTERLEAVING that resolves to OFF — an even number of flips ending on a clear.
test_case "NOEXEC-06: bash -n +n -n +n <unlisted>.sh blocks (interleaved; final state is OFF)" \
  "$(bash_payload "bash -n +n -n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (2) THE OTHER ORDER, AND INTERLEAVINGS THAT RESOLVE TO ON. These are the arms that
# keep the fix HONEST: if the predicate were "any `+` token cancels parse-only" they
# would over-block, and the exemption would be worth much less than the card claims.
test_case "NOEXEC-07: bash +n -n <unlisted>.sh allowed (clear THEN set; final state is ON, shell is inert)" \
  "$(bash_payload "bash +n -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-08: bash -n +n -n <unlisted>.sh allowed (interleaved; final state is ON)" \
  "$(bash_payload "bash -n +n -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-09: zsh +-noexec -n <unlisted>.sh allowed (long clear THEN set)" \
  "$(bash_payload "zsh +-noexec -n $PARSE_UNLISTED")" 0

# (3) THE CARD'S VALUE — unchanged. If any of these turn red the fix has eaten the
# feature it was protecting.
test_case "NOEXEC-CTL-01: bash -n <unlisted>.sh STILL allowed (the operand ends the walk, it does not revoke)" \
  "$(bash_payload "bash -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-CTL-02: bash -n <allowed> still allowed" \
  "$(bash_payload "bash -n $ARITY_ALLOWED")" 0
test_case "NOEXEC-CTL-03: bash -n +n <allowed> allowed (revoked, but the allowlist still governs)" \
  "$(bash_payload "bash -n +n $ARITY_ALLOWED")" 0

# (4) DECLARED RESIDUAL — a genuinely inert invocation that this predicate over-blocks.
# `bash -n -x <script>` IS inert (measured: silent), but `-x` is not a recognised
# parse-only spelling, so it revokes and the segment is adjudicated. This is the
# fail-SAFE direction and it is pinned so a future maintainer reads it as intended
# rather than as a bug: the cost of the revoke being unconditional for every token the
# walk STEPS OVER. That scope is the whole guarantee, and stating it unscoped — "nothing
# to omit on the revoke side" — is false: a token that ENDS the walk does not revoke, so
# an earlier grant survives it. NOEXEC-QSPLIT-* below now asserts the block for the
# quote-closes-early family, which the walk reads as a whole word; the surviving-grant
# case is a fragment, pinned as FWALK-QWORD-ctl-fragment-noexec, and NOEXEC-ORD-* pins
# the line order the scope depends on.
test_case "NOEXEC-R1: bash -n -x <unlisted>.sh blocks (declared over-block; unrecognised token revokes)" \
  "$(bash_payload "bash -n -x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (5) QUOTED SPELLINGS. A `+`-leading token never reaches the flag normalization at
# the top of the walk, so the quoted form arrives at the advance-past arm still
# wearing its quotes — the same asymmetry that made `'+-emulate'` a hole worth an arm
# in FWALK-PLUS. These pin that a quoted clear still revokes and a quoted set still
# grants, so the fix cannot be walked around by adding quotes.
test_case "NOEXEC-Q1: bash -n '+n' <unlisted>.sh blocks (quoted clearing form still revokes)" \
  "$(bash_payload "bash -n '+n' $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-Q2: bash '-n' '+n' <unlisted>.sh blocks (both tokens quoted)" \
  "$(bash_payload "bash '-n' '+n' $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-Q3: bash '-n' <unlisted>.sh allowed (quoted set form still grants; paired control)" \
  "$(bash_payload "bash '-n' $PARSE_UNLISTED")" 0

# --- (6) ORDERING PIN — the revoke must stay BELOW both breaks ---
# The predicate's guarantee is scoped to tokens the walk STEPS OVER, and that scope is
# produced by one thing only: the revoke sitting below both `break`s. Hoist it and
# `bash -n <script>.sh` revokes on the script itself and the card's whole value is lost.
# NOEXEC-CTL-01 catches that behaviourally for the shapes it covers; this arm reads the
# ORDER out of the hook, so a hoist is caught as the structural edit it is.
#
# The predicate is "no `script_noexec=0` appears between the walk-body marker and the
# second break, and the advance-past revoke appears after it". It FAILS CLOSED: a marker
# that stops matching reports MARKER-MISSING rather than reading as "ordering fine".
# ONE awk PASS OVER THE FILE, AND NO PIPELINE ANYWHERE IN IT. The obvious spelling of
# this helper — `grep -n … | head -1 | cut` — is a writer piped into a short-circuiting
# reader, which the SIGPIPE-idiom gate matches by name. awk reads the file directly, uses
# index() rather than regexes so no marker needs escaping, and takes its only `exit`
# inside END, which that gate documents as safe because END runs after the input is drained.
noexec_ord_check() {
  /usr/bin/awk '
    index($0, "# M-FWALK-BODY")                                                  { if (body == 0) body = NR }
    index($0, "script_norm_ok\" -eq 0 ]; then break")                            { if (b1 == 0)   b1   = NR }
    index($0, "script_operand_implicated \"$script_interp_domain\"; then break") { if (b2 == 0)   b2   = NR }
    index($0, "M-NOEXEC-REVOKE")                                                 { rev = NR }
    index($0, "script_noexec=0")                                                 { n++; nl[n] = NR }
    END {
      if (body == 0 || b1 == 0 || b2 == 0 || rev == 0) { printf "MARKER-MISSING"; exit }
      for (i = 1; i <= n; i++) {
        if (nl[i] >= body && nl[i] <= b2) { printf "HOISTED"; exit }
      }
      if (b1 > body && b2 > b1 && rev > b2) { printf "BELOW" } else { printf "OUT-OF-ORDER" }
    }
  ' "$1"
}

noexec_ord_shipped="$(noexec_ord_check "$HOOK")"
if [ "$noexec_ord_shipped" = "BELOW" ]; then
  /usr/bin/printf 'PASS: NOEXEC-ORD-01 revoke sits BELOW both walk-ending breaks (scope of the fail-safe guarantee)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-ORD-01 revoke ordering\n  expected=BELOW actual=%s\n' "$noexec_ord_shipped"
  FAIL=$((FAIL + 1))
fi

# RED-BEFORE CONTROL for NOEXEC-ORD-01. A checker that cannot fail proves nothing, so the
# same predicate is run against a mutant with the revoke hoisted onto the walk-body line —
# above both breaks. It must report HOISTED. The hoist is a single-line substitution on
# the marker comment, which keeps it portable across BSD and GNU sed. The marker is
# RE-EMITTED at the end of the line: the checker locates the region by it, so a mutant
# that dropped it would report MARKER-MISSING and the control would pass for the wrong
# reason — it would prove only that the checker notices a missing marker.
ORD_MUTANT="$(dirname "$HOOK")/block-destructive.ORD-mutant.sh"
/usr/bin/sed 's|# M-FWALK-BODY|; if [ "$script_verb" = "interp" ]; then script_noexec=0; fi   # M-FWALK-BODY|' \
  "$HOOK" > "$ORD_MUTANT"

if /usr/bin/cmp -s "$HOOK" "$ORD_MUTANT"; then
  /usr/bin/printf 'FAIL: NOEXEC-ORD-02a hoist mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: NOEXEC-ORD-02a hoist mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

noexec_ord_mutant="$(noexec_ord_check "$ORD_MUTANT")"
if [ "$noexec_ord_mutant" = "HOISTED" ]; then
  /usr/bin/printf 'PASS: NOEXEC-ORD-02b checker REPORTS the hoist (red-before control fires)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-ORD-02b checker did not report the hoist\n  expected=HOISTED actual=%s\n' "$noexec_ord_mutant"
  FAIL=$((FAIL + 1))
fi

# And the CONSEQUENCE, measured rather than asserted: with the revoke hoisted the operand
# itself revokes, so the card's own payload stops being admitted. This is the pair that
# says WHY the order matters — the shipped hook allows it in the same run (NOEXEC-CTL-01).
sandbox_case "NOEXEC-ORD-03: hoisted mutant BLOCKS bash -n <unlisted>.sh (the card's value is what the order protects)" \
  "$ORD_MUTANT" "$(bash_payload "bash -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

/bin/rm -f "$ORD_MUTANT"

# --- (6b) DOC <-> BEHAVIOUR TIE — the documented exemption claim must match the verdict ---
# WHY THIS PAIR EXISTS, AND WHY A FRESHNESS GATE COULD NOT CATCH WHAT IT CATCHES. The
# BLOCK-DESTRUCTIVE-022 registry row described this exemption as UNCONDITIONAL — "a bare -n
# under bash/sh/zsh with no -c in the flag span executes nothing and is not adjudicated" — and
# went on saying it after the predicate stopped being unconditional. build-hook-registry.py
# --check was rc=0 throughout, and correctly so: it proves the GENERATED index is byte-identical
# to its SOURCE fragment, and both carried the same false sentence. Comparing two copies of one
# claim can never falsify the claim. The missing check is a tie between the SENTENCE and the
# VERDICT, which is what these arms are — the claim is read out of the readiness corpus and held
# against what the shipped hook actually decides for `bash -n +n <unlisted>.sh` in this same run.
#
# FAILS CLOSED. An unresolvable document reports DOC-MISSING and reddens; it never reads as
# "nothing to check", which is the failure mode a documentation arm most easily acquires.
#
# ONE RESOLUTION EXPRESSION, TWO RUNGS. ${HOOK_DIR}/../rules/... is <sandbox>/.claude/rules/...
# under an explicit setup-ci-layout.sh --sandbox, which copies the readiness corpus there for
# these arms (deploy's rules mirror does not carry it), and <repo>/core/rules/... in a
# source-tree run. At the helper's default site the sandbox IS the checkout, so the corpus is
# not copied and the second rung, the repo-root form, reads core/rules/... in place. An
# unfamiliar layout therefore degrades to a resolved read.
#
# NO PIPELINES ANYWHERE IN THIS BLOCK. The classifier is one awk pass using index() — literal
# matching, so no marker needs escaping — and the behavioural probe feeds the hook from a FILE
# rather than from a writer on the other side of a pipe. Both are deliberate: a writer piped
# into a short-circuiting reader is the idiom the SIGPIPE gate matches by name.
NOEXEC_DOC_FRAG="$(cd "$(dirname "$0")/../.." && pwd -P)/rules/bypass-mode-readiness/block-destructive.md"
[ -f "$NOEXEC_DOC_FRAG" ] || NOEXEC_DOC_FRAG="$(cd "$(dirname "$0")/../../.." && pwd -P)/core/rules/bypass-mode-readiness/block-destructive.md"
NOEXEC_DOC_INDEX="$(cd "$(dirname "$0")/../.." && pwd -P)/rules/bypass-mode-readiness.md"
[ -f "$NOEXEC_DOC_INDEX" ] || NOEXEC_DOC_INDEX="$(cd "$(dirname "$0")/../../.." && pwd -P)/core/rules/bypass-mode-readiness.md"

# CONDITIONAL requires BOTH halves of the corrected claim AND the absence of the stale absolute.
# Either half alone is not enough: prose that says "conditional" while still carrying "executes
# nothing and is not adjudicated" is exactly the both-ways-at-once state a partial reconcile
# leaves behind, and it is the state this rule's own history produced.
noexec_doc_claim() {   # $1 = readiness file -> CONDITIONAL | STALE-ABSOLUTE | NO-QUALIFIER | NO-REVOKE-RULE | DOC-MISSING
  if [ ! -f "$1" ]; then /usr/bin/printf 'DOC-MISSING'; return 0; fi
  /usr/bin/awk '
    index($0, "executes nothing and is not adjudicated")             { stale = 1 }
    index($0, "conditional on the FINAL EFFECTIVE")                  { qual  = 1 }
    index($0, "by every later token the walk steps over")            { revok = 1 }
    END {
      if (stale == 1) { printf "STALE-ABSOLUTE"; exit }
      if (qual  != 1) { printf "NO-QUALIFIER";   exit }
      if (revok != 1) { printf "NO-REVOKE-RULE"; exit }
      printf "CONDITIONAL"
    }
  ' "$1"
}

# The behavioural half, taken from the SHIPPED hook in this same run. `bash -n +n <unlisted>.sh`
# is the discriminating payload: a bare -n, no -c in the flag span — precisely what the stale
# sentence declared exempt — on an invocation the shell RUNS and the hook BLOCKS.
noexec_doc_verdict() {   # -> BLOCK | ALLOW
  local noexec_doc_pf noexec_doc_rc=0
  noexec_doc_pf="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload "bash -n +n $PARSE_UNLISTED")" > "$noexec_doc_pf"
  /bin/bash "$HOOK" < "$noexec_doc_pf" >/dev/null 2>&1 || noexec_doc_rc="$?"
  /bin/rm -f "$noexec_doc_pf"
  if [ "$noexec_doc_rc" = 2 ]; then /usr/bin/printf 'BLOCK'; else /usr/bin/printf 'ALLOW'; fi
}

noexec_doc_frag_claim="$(noexec_doc_claim "$NOEXEC_DOC_FRAG")"
noexec_doc_index_claim="$(noexec_doc_claim "$NOEXEC_DOC_INDEX")"
noexec_doc_behaviour="$(noexec_doc_verdict)"

if [ "$noexec_doc_behaviour" = "BLOCK" ] && [ "$noexec_doc_frag_claim" = "CONDITIONAL" ]; then
  /usr/bin/printf 'PASS: NOEXEC-DOC-01 readiness SOURCE and hook agree (doc=%s, bash -n +n <unlisted>.sh=%s)\n' \
    "$noexec_doc_frag_claim" "$noexec_doc_behaviour"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-DOC-01 readiness SOURCE and hook DISAGREE\n  doc=%s (expected CONDITIONAL)  behaviour=%s (expected BLOCK)\n  file=%s\n' \
    "$noexec_doc_frag_claim" "$noexec_doc_behaviour" "$NOEXEC_DOC_FRAG"
  FAIL=$((FAIL + 1))
fi

# The GENERATED index is pinned separately rather than assumed. build-hook-registry.py --check
# already proves it matches its source, but that gate is about freshness; this one is about the
# claim, and a reader who lands on the index must not find the retired absolute there.
if [ "$noexec_doc_index_claim" = "CONDITIONAL" ]; then
  /usr/bin/printf 'PASS: NOEXEC-DOC-02 generated registry index carries the same conditional claim\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-DOC-02 generated index claim=%s (expected CONDITIONAL) — regenerate with build-hook-registry.py\n  file=%s\n' \
    "$noexec_doc_index_claim" "$NOEXEC_DOC_INDEX"
  FAIL=$((FAIL + 1))
fi

# RED-BEFORE CONTROLS — ONE PER WAY THE CLAIM CAN GO WRONG. A classifier that cannot report
# anything but CONDITIONAL proves nothing, so the same predicate is run against three mutants of
# the shipped document. Each arm asserts the mutation is LIVE (the mutant differs from the
# shipped file) AND that the classifier reports the specific code that mutation should produce —
# a merged conjunct, because a sed that matched nothing would otherwise let the control pass for
# the wrong reason, which is the trap NOEXEC-ORD-02a exists to name.
noexec_doc_control() {   # $1 = arm id  $2 = expected code  $3 = sed script
  local noexec_doc_mut noexec_doc_got
  noexec_doc_mut="$(/usr/bin/mktemp)"
  /usr/bin/sed "$3" "$NOEXEC_DOC_FRAG" > "$noexec_doc_mut"
  if /usr/bin/cmp -s "$NOEXEC_DOC_FRAG" "$noexec_doc_mut"; then
    /usr/bin/printf 'FAIL: %s mutation is INERT — mutant is byte-identical to the shipped document; re-point the sed\n' "$1"
    FAIL=$((FAIL + 1)); /bin/rm -f "$noexec_doc_mut"; return 0
  fi
  noexec_doc_got="$(noexec_doc_claim "$noexec_doc_mut")"
  /bin/rm -f "$noexec_doc_mut"
  if [ "$noexec_doc_got" = "$2" ]; then
    /usr/bin/printf 'PASS: %s mutation is live AND the classifier reports %s (red-before control fires)\n' "$1" "$noexec_doc_got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s classifier did not report the drift\n  expected=%s actual=%s\n' "$1" "$2" "$noexec_doc_got"
    FAIL=$((FAIL + 1))
  fi
}

# (a) the historical regression itself — the retired absolute back in the text.
noexec_doc_control "NOEXEC-DOC-03a" "STALE-ABSOLUTE" \
  's|A token that ENDS the walk does not revoke|it executes nothing and is not adjudicated. A token that ENDS the walk does not revoke|'
# (b) the conditionality qualifier silently dropped.
noexec_doc_control "NOEXEC-DOC-03b" "NO-QUALIFIER" \
  's|conditional on the FINAL EFFECTIVE|contingent upon the FINAL EFFECTIVE|'
# (c) the revocation rule silently dropped — the half that makes the claim decidable per token.
noexec_doc_control "NOEXEC-DOC-03c" "NO-REVOKE-RULE" \
  's|by every later token the walk steps over|by every later token the walk hops over|'

# --- (7) THE CLOSED FAMILY OF THAT SCOPE, AND THE FRAGMENT THAT REMAINS ---
# A token whose leading quote closes early is declined by normalize_script_token. While
# the walk read tokens only through that function it broke above the revoke, an earlier
# `-n` grant survived, and the script behind the token was adjudicated by nothing; these
# three arms pinned that ALLOW. The walk now reads such a token through script_walk_view,
# which reads a token that opens with a quote and closes every quote it opens as its
# unquoted spelling, so the three arms below assert the verdict of that spelling. What
# still ends the walk above the revoke is a FRAGMENT — a token that leaves a quote open —
# and that case is pinned in block (7b) as FWALK-QWORD-ctl-fragment-noexec.
test_case "NOEXEC-QSPLIT-01: bash -n \"\"+n <unlisted>.sh BLOCKS (the quoted clear is read as +n and revokes the grant)" \
  "$(bash_payload "bash -n \"\"+n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-QSPLIT-02: bash -n ''+n <unlisted>.sh BLOCKS (same word, single quotes)" \
  "$(bash_payload "bash -n ''+n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-QSPLIT-03: bash \"\"-x <unlisted>.sh BLOCKS (no -n anywhere — the quoted flag is stepped over and the operand adjudicated)" \
  "$(bash_payload "bash \"\"-x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# CONTROLS THAT MUST FIRE. Without these the three arms above would read green against a
# harness that had stopped blocking anything at all. Each is the unquoted twin of the
# arm above it, and each BLOCKS.
test_case "NOEXEC-QSPLIT-ctl-unquoted: bash -n +n <unlisted>.sh BLOCKS (the twin of QSPLIT-01 the revoke does reach)" \
  "$(bash_payload "bash -n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-QSPLIT-ctl-flag: bash -x <unlisted>.sh BLOCKS (the twin of QSPLIT-03)" \
  "$(bash_payload "bash -x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# --- (7b) THE WALK READS A WHOLE QUOTE-LED WORD AS ITS UNQUOTED SPELLING — FWALK-QWORD-* ---
# The three QSPLIT arms above pinned an ALLOW until the flag walk began reading each
# token the filename normalizer declines through script_walk_view. A token that opens
# with a quote and closes every quote it opens is a WHOLE WORD, and the walk gives it the
# verdict of its unquoted spelling. A token that leaves a quote open is a FRAGMENT and
# still ends the walk. The arms below pin both directions. Every refusal in (a) and (b)
# is an ALLOW on the pre-fix hook, which the revert mutant reproduces (FWALK-QWORD-M1*).
# Every arm in (c) is refused by the deny mutant (FWALK-QWORD-M2*), which is what shows
# that a must-allow arm can fail. A flag that begins with a sign or a backslash and
# carries a quote is NOT this reading's subject and has no arm here: the option-parse
# change on this walk closes that class, and its arms are the NOEXEC-TERM, FWALK-CLUSTER
# and FWALK-OPAQUE blocks after the corpus reader.
QWORD_WRAP="/tmp/pmo-qword-wrap"
QWORD_LONG="$(/usr/bin/printf '%*s' 1100 '' | /usr/bin/tr ' ' 'x')"

test_case "NOEXEC-QSPLIT-04: bash -n '+'n <unlisted>.sh BLOCKS (the quote closes inside the word; it is still +n)" \
  "$(bash_payload "bash -n '+'n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-QSPLIT-05: bash \"-\"n +n <unlisted>.sh BLOCKS (a quoted grant is revoked by the clear behind it)" \
  "$(bash_payload "bash \"-\"n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (a) MUST REFUSE — one arm per way a quoted word can sit in front of the operand.
test_case "FWALK-QWORD-plus: bash \"\"+x <unlisted>.sh blocks (plus-form, quoted)" \
  "$(bash_payload "bash \"\"+x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-sh: sh \"\"-x <unlisted>.sh blocks (second shell)" \
  "$(bash_payload "sh \"\"-x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-zsh: zsh ''-x <unlisted>.sh blocks (third shell, single quotes)" \
  "$(bash_payload "zsh ''-x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-ddash: bash \"\"-- <unlisted>.sh blocks (a quoted -- still hands over the operand)" \
  "$(bash_payload "bash \"\"-- $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-cmode: bash \"\"-c 'bash <unlisted>.sh' blocks (a quoted -c still opens the program string)" \
  "$(bash_payload "bash \"\"-c 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-arity: bash \"\"--rcfile <allowed> <unlisted>.sh blocks (a quoted option keeps its arity)" \
  "$(bash_payload "bash \"\"--rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-emulate: zsh \"\"--emulate -n <unlisted>.sh blocks (the -n is the option's argument, not a grant)" \
  "$(bash_payload "zsh \"\"--emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-source: source \"\"-- <unlisted>.sh blocks (the source arm walks the same loop)" \
  "$(bash_payload "source \"\"-- $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-chain: bash <allowed>; bash \"\"-x <unlisted>.sh blocks (second segment)" \
  "$(bash_payload "bash $ARITY_ALLOWED; bash \"\"-x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-extless: bash '<dir>/wr'ap <unlisted>.sh blocks on the argument, as its twin F2-FWALK-CONSEQ-extless does (declared over-block)" \
  "$(bash_payload "bash '/tmp/pmo-qword-wr'ap $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (b) A WHOLE WORD WHOSE VALUE ARGV DOES NOT DETERMINE — it carries an expansion, or
# it is over the read limit. It is neither a flag this hook can read nor an operand it
# can name. Under an interpreter the walk ends on the route -c takes: no parse-only
# exemption, and every claimed token after it adjudicated. Under source, which has no
# such route, it is stepped over and the walk keeps looking. PMO_QWORD_UNSET is never
# set and never expanded.
test_case "FWALK-QWORD-expansion: bash \"\$VAR\"-x <unlisted>.sh blocks" \
  "$(bash_payload "bash \"\$PMO_QWORD_UNSET\"-x $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-expansion-n: bash -n \"\$VAR\"+n <unlisted>.sh blocks (an earlier grant does not survive it)" \
  "$(bash_payload "bash -n \"\$PMO_QWORD_UNSET\"+n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-nogrant: bash \"\$VAR\"-n <unlisted>.sh blocks (declared over-block; an unknown value is never read as a grant)" \
  "$(bash_payload "bash \"\$PMO_QWORD_UNSET\"-n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-unknown-arity: zsh \"\$VAR\"--emulate -n <unlisted>.sh blocks (not read for arity, so the -n behind it cannot grant)" \
  "$(bash_payload "zsh \"\$PMO_QWORD_UNSET\"--emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-unknown-optarg: bash \"\$VAR\"--rcfile <allowed> <unlisted>.sh blocks (an allowlisted argument does not hide the operand)" \
  "$(bash_payload "bash \"\$PMO_QWORD_UNSET\"--rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-limit: bash \"\"-<1,100 x> <unlisted>.sh blocks (over the read limit degrades toward adjudication)" \
  "$(bash_payload "bash \"\"-${QWORD_LONG} $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-source-unknown: source \"\$VAR\"-- <unlisted>.sh blocks (stepped over; the operand is adjudicated)" \
  "$(bash_payload "source \"\$PMO_QWORD_UNSET\"-- $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-QWORD-source-unknown-walk: source \"\$VAR\"-p <unclaimed> <unlisted>.sh blocks (under source the walk keeps looking; the -c label would stop one token on)" \
  "$(bash_payload "source \"\$PMO_QWORD_UNSET\"-p pmo-qword-a:pmo-qword-b $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (c) MUST STAY ALLOWED. The first is the card's near miss. If any of these turns red
# the fix has started refusing what it was required to admit.
test_case "FWALK-QWORD-ctl-allow: bash \"\"-x <allowed>.sh allowed (THE NEAR MISS — the allowlist still governs)" \
  "$(bash_payload "bash \"\"-x $ARITY_ALLOWED")" 0
test_case "FWALK-QWORD-ctl-allow-n: bash -n \"\"+n <allowed>.sh allowed (revoked, and the allowlist still governs)" \
  "$(bash_payload "bash -n \"\"+n $ARITY_ALLOWED")" 0
test_case "FWALK-QWORD-grant: bash \"-\"n <unlisted>.sh allowed (the parse-only spelling, quoted — twin of NOEXEC-Q3)" \
  "$(bash_payload "bash \"-\"n $PARSE_UNLISTED")" 0
test_case "FWALK-QWORD-cmode-fp: bash \"\"-c 'echo a; echo b' allowed (twin of F1-FP-cmode)" \
  "$(bash_payload "bash \"\"-c 'echo a; echo b'")" 0
test_case "FWALK-QWORD-ddash-stop: bash \"\"-- <extensionless> <unlisted>.sh allowed (a quoted -- is the hard stop its twin is)" \
  "$(bash_payload "bash \"\"-- $QWORD_WRAP $PARSE_UNLISTED")" 0
test_case "FWALK-QWORD-expansion-allow: bash \"\$VAR\"-x <allowed>.sh allowed (the conservative route adjudicates; it does not deny)" \
  "$(bash_payload "bash \"\$PMO_QWORD_UNSET\"-x $ARITY_ALLOWED")" 0
test_case "FWALK-QWORD-limit-allow: bash \"\"-<1,100 x> <allowed>.sh allowed (same route, allowlisted operand)" \
  "$(bash_payload "bash \"\"-${QWORD_LONG} $ARITY_ALLOWED")" 0
test_case "FWALK-QWORD-ctl-cluster-fp: bash -ec 'echo a b' allowed (an ordinary program string behind a cluster: the cluster takes the -c route and nothing in the string is claimed)" \
  "$(bash_payload "bash -ec 'echo a b'")" 0
test_case "FWALK-QWORD-ctl-program-fp: perl -e 'print 1' allowed (a fragment behind a flag is not refused: a program string the walk still reads, since the cluster table leaves non-shell interpreters on its null)" \
  "$(bash_payload "perl -e 'print 1'")" 0
test_case "FWALK-QWORD-ctl-fragment-noexec (pin, not fix-evidence): bash -n '<path with spaces>.sh' allowed (a fragment still ends the walk and the grant survives)" \
  "$(bash_payload "bash -n '/tmp/pmo qtok probe na.sh'")" 0

# (d) A TOKEN A VIEW ALREADY PLACES IN THE OPERAND DOMAIN IS NOT RE-READ AS A WORD.
# '<path>.sh'y is the word <path>.shy, which no suffix set claims — but the probe view
# claims the token, and the pre-fix hook denies it as unresolvable. Reading it as a
# word would step over it and move a BLOCK to ALLOW, the one direction this change may
# not take. FWALK-QWORD-M3b is the mutant that does exactly that.
test_case "FWALK-QWORD-ctl-claimed (pin, not fix-evidence): bash '<unlisted>.sh'y still blocks (a domain claim outranks the word reading)" \
  "$(bash_payload "bash '${PARSE_UNLISTED}'y")" 2 "BLOCK-DESTRUCTIVE-022"

# RED-BEFORE, AS AN ARM. This mutant reverts the two call sites and nothing else, so
# it IS the pre-fix walk with the new functions left in the file unused. M1a proves the
# substitution matched exactly those two lines; M1b to M1e show the pre-fix ALLOW on
# one payload per mechanism.
QWORD_MUTANT="$(dirname "$HOOK")/block-destructive.QWORD-mutant.sh"
/usr/bin/sed 's/script_walk_view "/normalize_script_token "/' "$HOOK" > "$QWORD_MUTANT"

if [ "$(/usr/bin/diff "$HOOK" "$QWORD_MUTANT" | /usr/bin/grep -c '^<')" = "2" ]; then
  /usr/bin/printf 'PASS: FWALK-QWORD-M1a revert mutation is live (exactly the two walk call sites differ)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-QWORD-M1a revert mutation did not change exactly two lines — the M1 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-QWORD-M1b: the revert mutant ALLOWS bash \"\"-x <unlisted>.sh (the pre-fix verdict)" \
  "$QWORD_MUTANT" "$(bash_payload "bash \"\"-x $PARSE_UNLISTED")" 0
sandbox_case "FWALK-QWORD-M1c: the revert mutant ALLOWS bash -n \"\"+n <unlisted>.sh" \
  "$QWORD_MUTANT" "$(bash_payload "bash -n \"\"+n $PARSE_UNLISTED")" 0
sandbox_case "FWALK-QWORD-M1d: the revert mutant ALLOWS bash \"\"-c 'bash <unlisted>.sh'" \
  "$QWORD_MUTANT" "$(bash_payload "bash \"\"-c 'bash $PARSE_UNLISTED'")" 0
sandbox_case "FWALK-QWORD-M1e: the revert mutant ALLOWS bash \"\$VAR\"-x <unlisted>.sh" \
  "$QWORD_MUTANT" "$(bash_payload "bash \"\$PMO_QWORD_UNSET\"-x $PARSE_UNLISTED")" 0

/bin/rm -f "$QWORD_MUTANT"

# WHY THE WALK DOES NOT SIMPLY DENY, pinned so the proposal is not re-made. The
# obvious remedy for this family is to refuse any token the normalizer declines and no
# view claims. This mutant IS that remedy. It closes the family — and it refuses every
# arm in (c) the walk reads, the card's own near miss first. M2b to M2j are those
# refusals, each one matched on the mutant's own reason text so no other rule can
# satisfy it. FWALK-QWORD-ctl-cluster-fp has no pair here: its cluster takes the `-c`
# route before the walk reads the program string, so no deny at the walk reaches it, and
# FWALK-CLUSTER-M2b is the deny mutant that refuses it. M2i reads the program string the
# walk still reaches, behind a non-shell interpreter's `-e`.
QWORD_DENY="$(dirname "$HOOK")/block-destructive.QWORD-deny.sh"
/usr/bin/sed 's|^  script_word_scan "\$1"$|  if ! script_operand_implicated "$script_interp_domain"; then block "BLOCK-DESTRUCTIVE-022" "QWORD deny mutant" "test only"; fi; script_word_scan "$1"|' \
  "$HOOK" > "$QWORD_DENY"

if [ "$(/usr/bin/diff "$HOOK" "$QWORD_DENY" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-QWORD-M2a deny mutation is live (exactly one line of the view differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-QWORD-M2a deny mutation did not change exactly one line — the M2 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-QWORD-M2b: the deny mutant REFUSES the near miss bash \"\"-x <allowed>.sh" \
  "$QWORD_DENY" "$(bash_payload "bash \"\"-x $ARITY_ALLOWED")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2c: the deny mutant REFUSES bash -n \"\"+n <allowed>.sh" \
  "$QWORD_DENY" "$(bash_payload "bash -n \"\"+n $ARITY_ALLOWED")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2d: the deny mutant REFUSES the parse-only spelling bash \"-\"n <unlisted>.sh" \
  "$QWORD_DENY" "$(bash_payload "bash \"-\"n $PARSE_UNLISTED")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2e: the deny mutant REFUSES bash \"\"-c 'echo a; echo b'" \
  "$QWORD_DENY" "$(bash_payload "bash \"\"-c 'echo a; echo b'")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2f: the deny mutant REFUSES bash \"\"-- <extensionless> <unlisted>.sh" \
  "$QWORD_DENY" "$(bash_payload "bash \"\"-- $QWORD_WRAP $PARSE_UNLISTED")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2g: the deny mutant REFUSES bash \"\$VAR\"-x <allowed>.sh" \
  "$QWORD_DENY" "$(bash_payload "bash \"\$PMO_QWORD_UNSET\"-x $ARITY_ALLOWED")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2h: the deny mutant REFUSES bash \"\"-<1,100 x> <allowed>.sh" \
  "$QWORD_DENY" "$(bash_payload "bash \"\"-${QWORD_LONG} $ARITY_ALLOWED")" 2 "QWORD deny mutant"
# Exit 2 under perl comes from the mutant calling `block` directly; a real perl refusal goes through the phase router (warn: exit 0).
sandbox_case "FWALK-QWORD-M2i: the deny mutant REFUSES perl -e 'print 1' (a deny at the walk reaches ordinary program strings)" \
  "$QWORD_DENY" "$(bash_payload "perl -e 'print 1'")" 2 "QWORD deny mutant"
sandbox_case "FWALK-QWORD-M2j: the deny mutant REFUSES bash -n '<path with spaces>.sh'" \
  "$QWORD_DENY" "$(bash_payload "bash -n '/tmp/pmo qtok probe na.sh'")" 2 "QWORD deny mutant"

/bin/rm -f "$QWORD_DENY"

# THE LINE THAT KEEPS THE CHANGE MONOTONE, proved load-bearing. Deleting the view's
# claim test lets a claimed token be read as a word; the payload of
# FWALK-QWORD-ctl-claimed then steps over its own operand and is allowed.
QWORD_BLIND="$(dirname "$HOOK")/block-destructive.QWORD-blind.sh"
/usr/bin/sed '/^  if script_operand_implicated "\$script_interp_domain"; then return 0; fi$/d' "$HOOK" > "$QWORD_BLIND"

if [ "$(/usr/bin/diff "$HOOK" "$QWORD_BLIND" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-QWORD-M3a claim-blind mutation is live (exactly one line of the view is gone)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-QWORD-M3a claim-blind mutation did not remove exactly one line — M3b is unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-QWORD-M3b: the claim-blind mutant ALLOWS bash '<unlisted>.sh'y (the BLOCK the shipped view keeps)" \
  "$QWORD_BLIND" "$(bash_payload "bash '${PARSE_UNLISTED}'y")" 0

/bin/rm -f "$QWORD_BLIND"

# THE SCANNER AGAINST THE SHELL. script_word_scan is a second reader of shell quoting,
# and a reader that drifts from the shell reads some token wrongly. SCAN-01 lifts the
# function's text out of the hook and compares it with /bin/bash over a fixed table: a
# token it calls a whole exact word must be ONE word with exactly that value, and a
# token it calls a fragment must NOT be one word. A token it reports as of unknown
# value is counted and not compared — "unknown" claims nothing a shell can contradict.
# The three counts are asserted exactly, so a scanner that called everything unknown
# could not pass. The last three tokens carry an unquoted brace, glob or tilde
# character, which the shell rewrites after quote removal: a scanner that reports them
# exact is caught here, because the brace word is two words to /bin/bash. SCAN-02 is the
# control: the same comparison over a scanner with one quoting rule broken must name a
# disagreement, or SCAN-01's agreement proves nothing.
QWORD_TOKFILE="$(/usr/bin/mktemp)"
/bin/cat > "$QWORD_TOKFILE" <<'QWORD_TOKENS_EOF'
""-x
''-x
"-"x
'-'x
"-x"""
'-x'''
""''-x
''"-x"
"-""x"
""+n
'+'n
"+"n
""--
"-"-
""-c
"-"c
""-o
""--rcfile
''+-emulate
"-"\n
"-\n"
''\-x
'\-x'
"\-x"
"-\"x"
"-\\x"
'-'\''x'
"it's"x
'say"hi"'x
""-n
"-"n
"-n"''
'-''n'
""
''
''''
"a"'b'"c"
-x
+n
plain
a\ b
'abc
"abc
'a'"b
"a"'b
'a'\
"a\"
'/tmp/pmo
"it's
'it"s
""-x\
"$NOPE7019"-x
"${NOPE7019}"-x
""$NOPE7019
"-x"$NOPE7019
"`true`"-x
""$'-x'
""$'a\'b'
""$"-x"
""$(true)
""$(echo
"$(echo
'$NOPE7019'-x
"\$NOPE7019"-x
''\$x
""--{norc,rcfile}
""~
""-x*
QWORD_TOKENS_EOF

qword_scan_compare() { # $1 = scanner source text; prints one verdict line
  (
    script_ws_complete=0; script_ws_exact=0; script_ws_out=""
    eval "$1"
    if ! type script_word_scan >/dev/null 2>&1; then /usr/bin/printf 'NO-SCANNER'; exit 0; fi
    nx=0; nf=0; nu=0; sf="$(/usr/bin/mktemp)"
    while IFS= read -r tok || [ -n "$tok" ]; do
      [ -n "$tok" ] || continue
      script_word_scan "$tok"
      /usr/bin/printf "printf '%%s\\\\n' %s tail\n" "$tok" > "$sf"
      got="$(/usr/bin/env -i PATH=/usr/bin:/bin /bin/bash "$sf" 2>/dev/null | /usr/bin/tr '\n' '|')"
      if [ "$script_ws_complete" -eq 0 ]; then
        nf=$((nf + 1))
        case "$got" in
          *"|tail|")
            case "${got%|tail|}" in
              *"|"*) ;;
              *) /bin/rm -f "$sf"; /usr/bin/printf 'DISAGREE fragment-is-one-word %s' "$tok"; exit 0 ;;
            esac
            ;;
        esac
      elif [ "$script_ws_exact" -eq 1 ]; then
        nx=$((nx + 1))
        if [ "$got" != "${script_ws_out}|tail|" ]; then
          /bin/rm -f "$sf"; /usr/bin/printf 'DISAGREE value %s' "$tok"; exit 0
        fi
      else
        nu=$((nu + 1))
      fi
    done < "$QWORD_TOKFILE"
    /bin/rm -f "$sf"
    /usr/bin/printf 'agree exact=%s fragment=%s unknown=%s' "$nx" "$nf" "$nu"
  )
}

QWORD_SCAN_SRC="$(/usr/bin/sed -n '/^script_word_scan() {/,/^}/p' "$HOOK")"
qword_scan_verdict="$(qword_scan_compare "$QWORD_SCAN_SRC")"
if [ "$qword_scan_verdict" = "agree exact=44 fragment=11 unknown=13" ]; then
  /usr/bin/printf 'PASS: FWALK-QWORD-SCAN-01 the scanner agrees with /bin/bash over the token table (%s)\n' "$qword_scan_verdict"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-QWORD-SCAN-01 the scanner and /bin/bash differ, or the table was classified differently — got: %s; want: agree exact=44 fragment=11 unknown=13\n' "$qword_scan_verdict"
  FAIL=$((FAIL + 1))
fi

QWORD_SCAN_BROKEN="$(/usr/bin/printf '%s\n' "$QWORD_SCAN_SRC" | /usr/bin/sed 's|\*) out="${out}${bs}${t:1:1}" ;;|*) out="${out}${t:1:1}" ;;|')"
qword_scan_verdict="$(qword_scan_compare "$QWORD_SCAN_BROKEN")"
case "$qword_scan_verdict" in
  "DISAGREE value "*)
    /usr/bin/printf 'PASS: FWALK-QWORD-SCAN-02 [ctl] a scanner with the double-quote backslash rule broken is caught (%s)\n' "$qword_scan_verdict"
    PASS=$((PASS + 1))
    ;;
  *)
    /usr/bin/printf 'FAIL: FWALK-QWORD-SCAN-02 [ctl] a broken scanner was NOT caught — SCAN-01 cannot discriminate — got: %s\n' "$qword_scan_verdict"
    FAIL=$((FAIL + 1))
    ;;
esac
/bin/rm -f "$QWORD_TOKFILE"

# WHY NO SYMMETRIC CLEAR IS SHIPPED, pinned so the proposal is not re-made. Dev testing
# built the obvious remedy — revoke on the unresolvable break too — and measured it INERT:
# a FRAGMENT behind a grant was still allowed under it, because the operand path read
# nothing of a fragment. Since #8318 the operand path joins a fragment to the word it is a
# piece of, so the clear is no longer inert — and what it adds is an over-block: under it
# `bash -n '<space-bearing path>.sh'`, which parses and runs nothing, is refused. This
# mutant IS that remedy, and QSPLIT-M1b now pins that refusal; the shipped grant is pinned
# by FWALK-QWORD-ctl-fragment-noexec. Shipping it would add a fourth enumeration and
# refuse a command that runs nothing. (The quote-closes-early family itself
# no longer reaches that break: the walk reads a whole quote-led word through
# script_walk_view, so M1b and M2b carry a fragment, the token that still does.)
QSPLIT_MUTANT="$(dirname "$HOOK")/block-destructive.QSPLIT-mutant.sh"
/usr/bin/sed 's|if \[ "$script_norm_ok" -eq 0 \]; then break; fi|if [ "$script_norm_ok" -eq 0 ]; then if [ "$script_verb" = "interp" ]; then script_noexec=0; fi; break; fi|' \
  "$HOOK" > "$QSPLIT_MUTANT"

if /usr/bin/cmp -s "$HOOK" "$QSPLIT_MUTANT"; then
  /usr/bin/printf 'FAIL: NOEXEC-QSPLIT-M1a symmetric-clear mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: NOEXEC-QSPLIT-M1a symmetric-clear mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

sandbox_case "NOEXEC-QSPLIT-M1b: the symmetric-clear mutant REFUSES a fragment behind a grant (since #8318 the clear is not inert: it would refuse a parse-only invocation that runs nothing)" \
  "$QSPLIT_MUTANT" "$(bash_payload "bash -n '/tmp/pmo qtok probe na.sh'")" 2 "BLOCK-DESTRUCTIVE-022"

/bin/rm -f "$QSPLIT_MUTANT"

# M1b would read green for the WRONG reason if that break were simply never reached on
# this payload — an unexecuted mutation allows everything it never touches. So the break
# is proved reachable directly, with a second mutant that makes it announce itself on
# stderr and changes no verdict. M2b is the positive read and M2c is its negative control:
# the same marker must stay SILENT on a resolvable operand, which takes the other break.
QSPLIT_REACH="$(dirname "$HOOK")/block-destructive.QSPLIT-reach.sh"
/usr/bin/sed 's|if \[ "$script_norm_ok" -eq 0 \]; then break; fi|if [ "$script_norm_ok" -eq 0 ]; then /usr/bin/printf "QSPLIT-REACH" >\&2; break; fi|' \
  "$HOOK" > "$QSPLIT_REACH"

if /usr/bin/cmp -s "$HOOK" "$QSPLIT_REACH"; then
  /usr/bin/printf 'FAIL: NOEXEC-QSPLIT-M2a reach mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: NOEXEC-QSPLIT-M2a reach mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

sandbox_case "NOEXEC-QSPLIT-M2b: the first break IS on the path of that fragment (M1b is not vacuous)" \
  "$QSPLIT_REACH" "$(bash_payload "bash -n '/tmp/pmo qtok probe na.sh'")" 0 "QSPLIT-REACH"

qsplit_reach_err="$(/usr/bin/mktemp)"
/usr/bin/printf '%s' "$(bash_payload "bash -n $PARSE_UNLISTED")" \
  | /bin/bash "$QSPLIT_REACH" 2>"$qsplit_reach_err" >/dev/null || true
if /usr/bin/grep -qF 'QSPLIT-REACH' "$qsplit_reach_err"; then
  /usr/bin/printf 'FAIL: NOEXEC-QSPLIT-M2c marker fired on a RESOLVABLE operand — the marker does not discriminate\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: NOEXEC-QSPLIT-M2c marker stays silent on bash -n <unlisted>.sh (negative control; that path takes the other break)\n'
  PASS=$((PASS + 1))
fi
/bin/rm -f "$qsplit_reach_err" "$QSPLIT_REACH"

# --- PAIRED MUTATION ARMS — prove the REVOCATION is what arms 01-06 measure ---
# Same discipline as PARSE-14 / ARITY-17: a sibling mutant beside the real hook so
# HOOK_DIR, every lib and the allowlist resolve identically, differing in exactly one
# predicate. Here the two revocation sites are reverted to the pre-fix LATCH by
# turning each `script_noexec=0` marked M-NOEXEC-REVOKE into a self-assignment. The
# per-segment initialiser carries no marker and is deliberately untouched — reverting
# THAT would break segment isolation and measure a different thing.
NOEXEC_MUTANT="$(dirname "$HOOK")/block-destructive.NOEXEC-mutant.sh"
/usr/bin/sed '/M-NOEXEC-REVOKE/s/script_noexec=0/script_noexec=$script_noexec/' \
  "$HOOK" > "$NOEXEC_MUTANT"

# (a) NON-INERTNESS GATE — a byte-identical mutant would make every arm below measure
#     the shipped hook, and a green result would mean nothing.
if /usr/bin/cmp -s "$HOOK" "$NOEXEC_MUTANT"; then
  /usr/bin/printf 'FAIL: NOEXEC-M1a mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: NOEXEC-M1a mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

# (b)/(c) The mutant reproduces the pre-fix ALLOW on each shape; the shipped hook
#         blocks the identical payload in the same run. The PAIR is the evidence.
sandbox_case "NOEXEC-M1b: mutant (latch restored) ALLOWS bash -n +n <unlisted>.sh" \
  "$NOEXEC_MUTANT" "$(bash_payload "bash -n +n $PARSE_UNLISTED")" 0
test_case "NOEXEC-M1c: shipped hook BLOCKS the identical payload (`+n` pair closes)" \
  "$(bash_payload "bash -n +n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

sandbox_case "NOEXEC-M1d: mutant (latch restored) ALLOWS bash -n +o noexec <unlisted>.sh" \
  "$NOEXEC_MUTANT" "$(bash_payload "bash -n +o noexec $PARSE_UNLISTED")" 0
test_case "NOEXEC-M1e: shipped hook BLOCKS the identical payload (`+o noexec` pair closes)" \
  "$(bash_payload "bash -n +o noexec $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

sandbox_case "NOEXEC-M1f: mutant (latch restored) ALLOWS zsh -n +-noexec <unlisted>.sh" \
  "$NOEXEC_MUTANT" "$(bash_payload "zsh -n +-noexec $PARSE_UNLISTED")" 0
test_case "NOEXEC-M1g: shipped hook BLOCKS the identical payload (`+-noexec` pair closes)" \
  "$(bash_payload "zsh -n +-noexec $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (h) THE MUTANT MUST STILL ALLOW THE CARD'S OWN PAYLOAD. This is what proves the
#     mutation reverted the REVOCATION and not the exemption itself — otherwise
#     NOEXEC-M1b..g would be green for the wrong reason (a mutant that blocks
#     everything blocks these too).
sandbox_case "NOEXEC-M1h: mutant STILL allows bash -n <unlisted>.sh (the mutation is the revoke, not the exemption)" \
  "$NOEXEC_MUTANT" "$(bash_payload "bash -n $PARSE_UNLISTED")" 0

/bin/rm -f "$NOEXEC_MUTANT"

# --- PAIRED MUTATION ARMS — prove the arity predicate is what these arms measure ---
# Same harness discipline as PARSE-14: a sibling mutant so HOOK_DIR and therefore
# every lib and the allowlist resolve identically, differing in exactly one
# predicate — here the arity table, neutered to its pre-fix answer. The polarity is
# the inverse of PARSE-14's: the MUTANT allows and the SHIPPED hook blocks.
ARITY_MUTANT="$(dirname "$HOOK")/block-destructive.ARITY-mutant.sh"
/usr/bin/sed 's#^script_interp_optarg_flag() {#script_interp_optarg_flag() { return 1;#' \
  "$HOOK" > "$ARITY_MUTANT"

# (a) NON-INERTNESS GATE — a byte-identical mutant would make every arm below
#     measure the shipped hook, and a green result would mean nothing.
if /usr/bin/cmp -s "$HOOK" "$ARITY_MUTANT"; then
  /usr/bin/printf 'FAIL: ARITY-17a mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: ARITY-17a mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

# (b)/(c) shape (1): mutant reproduces the pre-fix ALLOW; shipped hook blocks.
sandbox_case "ARITY-17b: mutant (arity reverted) ALLOWS bash --rcfile <allowed> <unlisted>.sh" \
  "$ARITY_MUTANT" \
  "$(bash_payload "bash --rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" \
  0
test_case "ARITY-17c: shipped hook BLOCKS the identical payload (shape-1 pair closes)" \
  "$(bash_payload "bash --rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (d)/(e) shape (2): the block-to-allow the #6172 exemption introduced.
sandbox_case "ARITY-17d: mutant (arity reverted) ALLOWS bash --rcfile -n <unlisted>.sh" \
  "$ARITY_MUTANT" \
  "$(bash_payload "bash --rcfile -n $PARSE_UNLISTED")" \
  0
test_case "ARITY-17e: shipped hook BLOCKS the identical payload (shape-2 pair closes)" \
  "$(bash_payload "bash --rcfile -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (f)/(g) shape (2) again, on the zsh `--emulate` row. Same mutant, same polarity:
# the pair proves ARITY-18a measures the ARITY TABLE and not some other predicate
# that would keep the payload blocked anyway.
sandbox_case "ARITY-17f: mutant (arity reverted) ALLOWS zsh --emulate -n <unlisted>.sh" \
  "$ARITY_MUTANT" \
  "$(bash_payload "zsh --emulate -n $PARSE_UNLISTED")" \
  0
test_case "ARITY-17g: shipped hook BLOCKS the identical payload (--emulate pair closes)" \
  "$(bash_payload "zsh --emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

/bin/rm -f "$ARITY_MUTANT"

# --- ARITY-19: `--` AND `-c` ARE CONSUMED LIKE ANY OTHER ARGUMENT ---
# These arms exist because the obvious "tidy" edit here is WRONG and would pass
# every other arm in this block. The arity step consumes the next token before the
# walk's own `--)` and `-c)` labels can see it, so when an option's argument is
# literally `-c` the cmode flag stays 0 and the post-walk route changes. That is a
# real, measurable change in verdicts (4775-payload differential against the
# pre-arity hook: 64 ALLOW->BLOCK, 15 BLOCK->ALLOW), which is why the "purely
# additive" claim this file used to carry has been corrected rather than restored.
#
# THE TEMPTING FIX — decline to consume `--` and `-c` so the labels keep their
# tokens — RE-OPENS AN EXECUTION HOLE, and ARITY-19a is that hole. Measured against
# real bash with an executable marker: `bash --rcfile -- -c <script>` prints the
# marker and exits 0, because `--` is the rcfile FILENAME (not an end-of-options
# marker) and `-c` is a real command-mode flag. Under a decline the `--)` label
# breaks the walk and takes `-c` as the operand — a token no domain claims — and
# the segment is ALLOWED. Consuming keeps it BLOCKED. If someone implements the
# decline, ARITY-19a is the arm that goes red, and it is the one to read first.
test_case "ARITY-19a [ctl]: bash --rcfile -- -c <unlisted>.sh blocks (-- is the rcfile NAME; this EXECUTES)" \
  "$(bash_payload "bash --rcfile -- -c $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "ARITY-19b [ctl]: bash -O -- -c <unlisted>.sh blocks (same shape through a short arity option)" \
  "$(bash_payload "bash -O -- -c $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# The other half of the same decision: consuming `-c` REMOVES over-blocks, and the
# removals are correct against the real shell rather than merely harmless.
# `bash --rcfile -c -n <script>` is genuinely inert (measured: rc=0, no output) —
# the rcfile is named `-c`, the `-n` is a real parse-only flag. Declining `-c`
# would turn this correct ALLOW back into a block.
test_case "ARITY-19c: bash --rcfile -c -n <unlisted>.sh allowed (genuinely inert; rcfile is named -c)" \
  "$(bash_payload "bash --rcfile -c -n $PARSE_UNLISTED")" 0
# And `bash --rcfile -c <a> <b>` runs <a> — exactly the token the operand branch
# adjudicates — so an allowlisted <a> is a correct ALLOW and an unlisted one blocks.
test_case "ARITY-19d: bash --rcfile -c <allowed> <unlisted>.sh allowed (the shell runs <allowed>)" \
  "$(bash_payload "bash --rcfile -c $ARITY_ALLOWED $PARSE_UNLISTED")" 0
test_case "ARITY-19e [ctl]: bash --rcfile -c <unlisted>.sh <allowed> blocks (the shell runs <unlisted>)" \
  "$(bash_payload "bash --rcfile -c $PARSE_UNLISTED $ARITY_ALLOWED")" 2 "BLOCK-DESTRUCTIVE-022"

echo ""
echo "BLOCK-022 HD here-document modelling (#6229)"
echo "---"
#
# WHAT THESE ARMS ARE FOR. A here-document BODY is the INPUT DATA a redirection
# supplies to a command (POSIX Shell Command Language 2.7.4); the shell never
# parses it as a command list. Before this change the rule latched suppression
# OFF for any command containing `<<`, so text it had already adjudicated
# correctly was re-adjudicated as if it were command text — and the identical
# report bytes were refused on stdin and accepted from a file.
#
# EVERY ALLOW-ASSERTING ARM BELOW IS PAIRED WITH A REFUSE-ASSERTING ARM IN THE
# SAME RUN. That pairing is the whole evidentiary value: a blanket allow shows up
# as a SILENT CONTROL, a disabled rule shows up as a DROPPED TOTAL, and an
# exemption that is real but inert shows up as a GREEN MUTANT (HD-09). An arm
# whose control arm is also green is measuring a permissive hook, not a fix.
#
# The pre-change verdict of every shape below was recorded before the excision
# landed, so a reader can tell a tightening from a narrowing rather than
# inferring it.

# ----- AC-1: the card's measurement, both transports -----
#
# Identical report bytes quoting an interpreter invocation as evidence, delivered
# two ways. Before: (a) refused, (b) allowed — the transport decided the verdict
# for bytes that reach the same destination either way. The asymmetry is CLOSED,
# not documented: both allow now.
test_case "HD-01a: a report quoting an invocation, delivered by here-document, allows" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'RPT'"'"'
## Finding

The CI log line the finding is about:

    bash /tmp/evil.sh --self-test

That invocation is the subject of the report, not a proposal to run it.
RPT')" \
  0

test_case "HD-01b: the same report bytes delivered by file path allow (transport parity)" \
  "$(bash_payload 'gh issue comment 1 --body-file /tmp/report.md')" \
  0

# The sensitivity arm. A green HD-01a whose control is silent is a disabled rule,
# not a repair — this is the arm that makes the pair readable.
test_case "HD-01c control: a genuine invocation of the same script still blocks" \
  "$(bash_payload 'bash /tmp/evil.sh --self-test')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- AC-2: the stdin-executing arm is refused -----
#
# THE SINGLE MOST IMPORTANT ARM SET. `bash` reads its PROGRAM from stdin, so the
# body genuinely executes. This is the fail-open the carrier condition is shaped
# to avoid, and it is why the exemption cannot key on the construct alone.
test_case "HD-02a control: bash reading its program from a here-document blocks" \
  "$(bash_payload 'bash <<'"'"'EOF'"'"'
bash /tmp/evil.sh
EOF')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "HD-02b control: sh reading its program from a here-document blocks" \
  "$(bash_payload 'sh <<'"'"'EOF'"'"'
bash /tmp/evil.sh
EOF')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "HD-02c control: zsh reading its program from a here-document blocks" \
  "$(bash_payload 'zsh <<'"'"'EOF'"'"'
bash /tmp/evil.sh
EOF')" \
  2 "BLOCK-DESTRUCTIVE-022"

# The byte-identical BODY under a carrier allows in the same run, so the verdict
# above is attributable to the RECEIVING COMMAND and not to the body text.
test_case "HD-02d: the byte-identical body under a carrier allows (verdict is the receiver's)" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'EOF'"'"'
bash /tmp/evil.sh
EOF')" \
  0

# ----- AC-3: the delimiter-quoting axis discriminates -----
#
# A QUOTED delimiter suppresses every expansion in the body; a BARE one performs
# parameter expansion, command substitution and arithmetic expansion. That is the
# same two-tier split the file already applies to '...' versus "...", so the test
# is the CONSTRUCT's expansion capability, not the delimiter's quote characters.
test_case "HD-03a: single-quoted delimiter into a carrier allows" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'RPT'"'"'
bash /tmp/evil.sh
RPT')" \
  0

test_case "HD-03b: double-quoted delimiter into a carrier allows" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<"RPT"
bash /tmp/evil.sh
RPT')" \
  0

test_case "HD-03c: backslash-quoted delimiter into a carrier allows" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<\RPT
bash /tmp/evil.sh
RPT')" \
  0

# (d)(e) are the discriminating pair, and they differ by ONE character. A bare
#     delimiter whose body carries a `$` can expand, so the body is left in the
#     adjudicated text and still blocks; remove the `$` and the same body is
#     inert and is excised. If (e) were red the rule would be reading the
#     delimiter's quote characters instead of the construct's capability.
test_case "HD-03d control: bare delimiter with an expandable body still blocks" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<RPT
bash /tmp/evil.sh $HOME
RPT')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "HD-03e: bare delimiter with an inert body allows (the one-character pair)" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<RPT
bash /tmp/evil.sh
RPT')" \
  0

# ----- AC-5: post-terminator text keeps its verdict -----
#
# A real execution AFTER the terminator must stay adjudicated. If the excision
# corrupted the line structure this is the arm that fails — and the inherited
# arm AC-FP-2x above, which is deliberately left unmodified, is its twin.
test_case "HD-05 control: a real execution after the terminator still blocks" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'RPT'"'"'
report text
RPT
bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- AC-6: the exemption is STRUCTURAL, not a content heuristic -----
#
# The card's constraint: an exemption keyed on "it looked like a report" is
# trivially forgeable by anything that can print a markdown fence. Assert the
# implementation keys on none of that. The control arm proves the instrument is
# live rather than mis-spelled.
#
# THE INSTRUMENT MEASURES CODE, NOT PROSE. Comment lines are stripped first,
# because the criterion is that no BRANCH keys on a content marker — an English
# sentence explaining the quote scanner is not a branch. Left un-stripped this
# probe failed on the word "report" inside a comment carried over from
# script_qadvance, which would have made it a prose linter rather than a
# structure test and would have pressured the prose to satisfy the instrument.
HD_PRESCAN="$(/usr/bin/sed -n '/^script_heredoc_prescan() {/,/^}$/p' "$HOOK" \
  | /usr/bin/grep -v '^[[:space:]]*#')"
if [ -n "$HD_PRESCAN" ] \
   && ! /usr/bin/grep -qiE 'report|evidence|markdown|fence|body-file|--body|```' <<<"$HD_PRESCAN"; then
  /usr/bin/printf 'PASS: HD-06a the pre-pass keys on no content marker (no report/fence/flag token)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: HD-06a the pre-pass keys on a content marker, or the instrument found no function\n'
  FAIL=$((FAIL + 1))
fi

if /usr/bin/grep -qE 'script_qnext|gh\|printf\|echo\|jq' <<<"$HD_PRESCAN"; then
  /usr/bin/printf 'PASS: HD-06b control: the same instrument finds the quote scanner and the carrier set\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: HD-06b control is SILENT — HD-06a zero is unreadable, not clean\n'
  FAIL=$((FAIL + 1))
fi

# ----- AC-7: un-modelled shapes bail closed, keeping the pre-change verdict -----
#
# ALL-OR-NOTHING. One declined body means nothing is excised and the whole
# command keeps the text it had before, so a shape the model does not cover can
# only ever degrade to adjudicate-everything — never to allow.
test_case "HD-07a control: an unterminated here-document blocks (model cannot resolve)" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'RPT'"'"'
bash /tmp/evil.sh')" \
  2 "BLOCK-DESTRUCTIVE-022"

# Re-pointed by #8326: its receiver was cat, which the receiver list now admits under the
# whole-command no-consumer test (HD-RECV-ADMIT-cat-redirect-after is that shape's arm). A receiver
# on no list keeps R-4's role; HD-RECV-CTL-nonmember is its twin.
test_case "HD-07b control: a receiver on no list keeps the false positive (residual R-4)" \
  "$(bash_payload 'tee /tmp/out.md <<'"'"'RPT'"'"'
bash /tmp/evil.sh
RPT')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "HD-07c control: a delimiter bearing expansion characters blocks" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<RP$T
bash /tmp/evil.sh
RP$T')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "HD-07d control: more than two here-documents queued on one line blocks" \
  "$(bash_payload 'gh a --f - <<'"'"'A'"'"' --g - <<'"'"'B'"'"' --h - <<'"'"'C'"'"'
bash /tmp/evil.sh
A
x
B
y
C')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- AC-8: the latch narrowing did not disarm quoted-argument suppression -----
#
# This is the pair the whole card turns on. (a) was ALREADY allowed before the
# change; (b) is the identical command plus an UNRELATED trailing here-document,
# and it was refused — the latch disarmed a suppression that had already decided
# correctly. Both allow now.
test_case "HD-08a: the shipped quoted-argument suppression still allows" \
  "$(bash_payload "gh issue comment 1 --body 'note; bash /tmp/evil.sh'")" \
  0

test_case "HD-08b: the same command plus an unrelated here-document now also allows" \
  "$(bash_payload "gh issue comment 1 --body 'note; bash /tmp/evil.sh' <<'X'
unrelated body
X")" \
  0

# The wrapper asymmetry documented at script_resolve_head is preserved: a prefix
# in front of a carrier must NOT resolve to the carrier. If this went green the
# carrier walk was silently widened while the surface grew.
test_case "HD-08c control: a wrapper in front of a carrier is still not a carrier" \
  "$(bash_payload "sudo gh issue comment 1 --body 'note; bash /tmp/evil.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- Construct coverage the model must get right -----

# `<<-` strips leading TABS from body and delimiter lines before the match.
HD_TAB="$(/usr/bin/printf '\t')"
test_case "HD-10: <<- tab-stripping form with a quoted delimiter allows" \
  "$(bash_payload "gh issue comment 1 --body-file - <<-'RPT'
${HD_TAB}bash /tmp/evil.sh
${HD_TAB}RPT")" \
  0

# THE RECEIVER IS RESOLVED FROM THE LAST SEPARATOR, NOT FROM THE LINE HEAD. If it
# were read from the head, a carrier ahead of a separator would lend its
# exemption to a real interpreter that receives the redirection after it. This is
# the arm that would catch that fail-open.
test_case "HD-11 control: a carrier before a separator does not vouch for the real receiver" \
  "$(bash_payload 'gh issue view 1 ; bash <<'"'"'E'"'"'
bash /tmp/evil.sh
E')" \
  2 "BLOCK-DESTRUCTIVE-022"

# POSIX runs a command that follows the operator on the OPERATOR's own line
# BEFORE the body begins. After separator substitution it is indistinguishable
# from the first body line, which is why the pre-pass runs on the original text.
test_case "HD-12 control: a command after the operator on the operator line still blocks" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'E'"'"' ; bash /tmp/evil.sh
body line
E')" \
  2 "BLOCK-DESTRUCTIVE-022"

# A here-STRING is one word, already covered by the quote model. It must be
# recognised BEFORE `<<`, or the scan reads a delimiter of `<` and corrupts.
test_case "HD-13: a here-string is not read as a here-document" \
  "$(bash_payload "gh issue comment 1 --body-file - <<< 'note bash /tmp/evil.sh'")" \
  0

# `<<` INSIDE a quoted argument is text, not an operator. The latch this replaces
# globbed the raw command and could not tell the difference.
test_case "HD-14: << inside a quoted argument is text and does not disarm suppression" \
  "$(bash_payload "gh issue comment 1 --body 'note << not an operator; bash /tmp/evil.sh'")" \
  0

# Every carrier in the set receives the same treatment, not just gh.
test_case "HD-15a: printf as the receiving carrier allows" \
  "$(bash_payload 'printf '"'"'%s'"'"' - <<'"'"'RPT'"'"'
bash /tmp/evil.sh
RPT')" \
  0

test_case "HD-15b: jq as the receiving carrier allows" \
  "$(bash_payload 'jq -R . <<'"'"'RPT'"'"'
bash /tmp/evil.sh
RPT')" \
  0

# ALL-OR-NOTHING, asserted directly: a command mixing an excisable here-document
# with a declined one excises NEITHER and keeps its pre-change verdict. The declined
# body's receiver was cat until #8326 admitted it; a line counter, on no list, keeps
# the arm's role.
test_case "HD-16 control: one declined body means the whole command is left adjudicated" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'A'"'"'
bash /tmp/evil.sh
A
wc -l <<'"'"'B'"'"'
plain
B')" \
  2 "BLOCK-DESTRUCTIVE-022"

# ----- AC-9: paired mutation arm -----
#
# An exemption that is real but INERT reads green on every arm above. Three arms
# in this milestone's prior release did exactly that. Revert the excision in a
# sibling copy — so HOOK_DIR, every lib and the allowlist resolve identically —
# and require the mutant to REFUSE the payload the shipped hook allows.
HD_MUTANT="$(dirname "$HOOK")/block-destructive.HD-mutant.sh"
/usr/bin/sed 's#\[ "\$_ex" -eq 1 \]#[ "$_ex" -eq 99 ]#' "$HOOK" > "$HD_MUTANT"

if /usr/bin/cmp -s "$HOOK" "$HD_MUTANT"; then
  /usr/bin/printf 'FAIL: HD-09a mutation is INERT — mutant is byte-identical to the shipped hook\n'
  FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: HD-09a mutation is live (mutant differs from the shipped hook)\n'
  PASS=$((PASS + 1))
fi

sandbox_case "HD-09b: mutant (excision reverted) BLOCKS the report HD-01a allows" \
  "$HD_MUTANT" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'RPT'"'"'
bash /tmp/evil.sh --self-test
RPT')" \
  2 "BLOCK-DESTRUCTIVE-022"

test_case "HD-09c: shipped hook ALLOWS the identical payload (mutation pair closes)" \
  "$(bash_payload 'gh issue comment 1 --body-file - <<'"'"'RPT'"'"'
bash /tmp/evil.sh --self-test
RPT')" \
  0

/bin/rm -f "$HD_MUTANT"

# ==========================================================================
# HINT-* — the -022 remediation hint names the sanctioned retry FIRST (#6166)
# ==========================================================================
#
# Subject: when -022 refuses, its Override line offered allowlist-widening and
# the bypass variable, and named the retry that usually works nowhere. The
# allowlist is matched with `case "$path" in $pattern)` — a bash glob against the
# path AS WRITTEN on argv, with no realpath and no canonicalization — and it is
# spelled overwhelmingly in repository-relative form. The same script is
# therefore refused by an absolute path and permitted by its repository-relative
# one, and the hint never said so.
#
# WHY THIS IS TESTED AT ALL. At the baseline NOT ONE arm in this file asserted
# any hint text: the four -022 Override strings were emitted, agent-facing, and
# wholly uncovered, so a reorder or a deletion of the retry would have read green.
# Measured before these arms landed: four hint substrings, zero occurrences each,
# against 345 `test_case` invocations.
#
# THE ORDERING IS ASSERTED POSITIONALLY, NOT BY PRESENCE. The pattern pins
# `Override: ` immediately followed by the retry, then requires the widening and
# the bypass to appear AFTER it. Presence alone would pass on the old string too,
# because the old string also mentioned the allowlist. Anchoring on what directly
# follows `Override: ` is what makes "first" mean first — and it is why no
# separate must-not-match arm is needed: only one clause can follow `Override: `.
#
# THE BYPASS CLAUSE IS PART OF THE ASSERTION, DELIBERATELY. It is a real escape
# hatch and must stay documented; the arms require it present and LAST, so a
# future edit that deletes it to "clean up the hint" goes red rather than quietly
# stranding an operator who has no other route.
#
# Each hint gets a PAIR: an `a` arm pinning WHICH cause class fired (the reason
# line) and a `b` arm pinning the ordering (the Override line). They are separate
# `test_case` calls because grep is line-oriented and the reason and the Override
# are different lines — one pattern cannot span them. Without the `a` arm a
# payload that silently drifted to a different cause class would still satisfy
# `b`, and the pair would prove nothing about the string it claims to cover.

echo ""
echo "HINT-*: -022 remediation hint ordering (#6166)"
echo "---"

# Ordered across all three strings: retry → repository root → AS WRITTEN →
# allowlist widening → bypass. One pattern, five positional claims.
HINT_ORDER='Override: first retry the form the allowlist already permits.*repository root.*AS WRITTEN.*script-execution-allowlist\.txt.*CLAUDE_HOOK_BYPASS=1'

HINT_UNLISTED="core/deploy/tools/no-such-tool-xyz.sh"

# --- the not-allowlisted arm: the card's stated subject, and the common case ---
test_case "HINT-01a: bash <unlisted>.sh reports the not-allowlisted cause" \
  "$(bash_payload "bash $HINT_UNLISTED")" \
  2 "subprocess script execution not in allowlist"
test_case "HINT-01b: ... and its Override names the retry BEFORE widening and the bypass" \
  "$(bash_payload "bash $HINT_UNLISTED")" \
  2 "$HINT_ORDER"

# --- the variable-bearing unresolvable arm ---
test_case "HINT-02a: bash \"\$W/x.sh\" reports the variable-bearing cause" \
  "$(bash_payload 'bash "$W/not-allowlisted.sh"')" \
  2 "unresolvable script path \(variable-bearing\)"
test_case "HINT-02b: ... and its Override names the retry BEFORE widening and the bypass" \
  "$(bash_payload 'bash "$W/not-allowlisted.sh"')" \
  2 "$HINT_ORDER"

# --- the quoting unresolvable arm. The `;` splits the segment before
# normalization sees it, so the operand arrives as an UNCLOSED `'…/deploy.sh`
# with an in-domain `.sh` probe — the shape § F1 QUOTED already pins.
test_case "HINT-03a: an unclosed-quote operand reports the quoting cause" \
  "$(bash_payload "bash './core/deploy/deploy.sh;'")" \
  2 "unresolvable script path \(quoting\)"
test_case "HINT-03b: ... and its Override names the retry BEFORE widening and the bypass" \
  "$(bash_payload "bash './core/deploy/deploy.sh;'")" \
  2 "$HINT_ORDER"

# --- AC3: the hint's own worked example must be TRUE, and the asymmetry it
# asserts must be real. HINT-04 runs the exact spelling the -022 quoting hint
# prints; HINT-05 runs the SAME script by an absolute path and must still be
# refused. Together they are the non-broadening guard for this card: if anyone
# "fixes" a future block by adding absolute forms to the allowlist, HINT-05 goes
# red and the hint's central claim becomes false in the same instant.
# Distinct from PARSE-06, which pins the same asymmetry for #6172's two admitted
# paths; this pair pins it for the script THIS hint names.
test_case "HINT-04: the hint's worked example (quoted bare-relative) is permitted" \
  "$(bash_payload "bash 'core/deploy/deploy.sh'")" \
  0
test_case "HINT-05 [ctl]: the ABSOLUTE spelling of that same script is still refused" \
  "$(bash_payload "bash '/srv/pmo-platform/core/deploy/deploy.sh'")" \
  2 "BLOCK-DESTRUCTIVE-022"

# ==========================================================================
# T-NSI-* — the non-shell interpreter arm (#6167)
# ==========================================================================
#
# THE HOLE THESE ARMS PIN. The verb classifier admitted `bash|sh|zsh` and nothing
# else, so `python3 <path>.py` was not merely un-adjudicated — it was never
# classified as an execution at all, and no arm ever asked the allowlist about it.
# The allowlist was bypassable by writing the laundered script in a language the
# classifier could not name. Same root cause as the shebang hole the exec arm
# closed: an execution model expressed as a fixed vocabulary of shell tokens and
# shell suffixes.
#
# WHY EVERY MUST-FLAG ARM READS THE DRAIN AND NOT ONLY THE EXIT CODE. This arm
# ships at `warn`, so it returns 0 on a would-fire input. An arm asserting exit 0
# alone would pass against a hook that never evaluated the widening — it would pass
# against the PRE-change hook, and it would keep passing if the widening were
# reverted. The drain delta is what makes evaluation a necessary condition of green.
#
# WHY THE `arm` FIELD IS ASSERTED ON EVERY ROW. Three phase-gated families now write
# to one drain. Without the field their graduations are unapportionable — which is the
# defect this card's own body reported against the 1,067 rows already collected.

echo ""
echo "T-NSI-*: non-shell interpreter arm (#6167)"
echo "---"

# The shipped interpreter-arm phase, read OUT OF THE HOOK SOURCE for the same
# reason the exec phase is: a restated copy lets the constant and the expectation
# drift in opposite directions and still go green.
B022_INTERP_PHASE="$(/usr/bin/sed -n '/^readonly DESTRUCTIVE_022_INTERP_PHASE=/{s/^readonly DESTRUCTIVE_022_INTERP_PHASE="\([a-z]*\)".*/\1/p;q;}' "$HOOK")"
B022_INTERP_ARMED="$(/usr/bin/sed -n '/^readonly DESTRUCTIVE_022_INTERP_ARMED=/{s/^readonly DESTRUCTIVE_022_INTERP_ARMED="\([0-9-]*\)".*/\1/p;q;}' "$HOOK")"
if [ -z "$B022_INTERP_PHASE" ]; then
  /usr/bin/printf 'FAIL: T-NSI-00 interpreter-arm phase constant not readable from %s\n' "$HOOK"
  FAIL=$((FAIL + 1))
  B022_INTERP_PHASE="unreadable"
fi
case "$B022_INTERP_PHASE" in
  enforce) B022_INTERP_FLAG_EXIT=2 ;;
  *)       B022_INTERP_FLAG_EXIT=0 ;;
esac
/usr/bin/printf 'PASS: T-NSI-00 interpreter-arm rollout phase resolved from the hook source: %s (must-flag expects exit %s)\n' \
  "$B022_INTERP_PHASE" "$B022_INTERP_FLAG_EXIT"
PASS=$((PASS + 1))

# A would-fire case on the INTERPRETER arm. Same shape as exec_warn_case, with the
# `arm` field asserted so a row written by the other router cannot satisfy it.
nsi_warn_case() { # $1 name  $2 command  $3 expected cause
  local rc=0 before after last err tmp_err ok=1 why=""
  before="$(b022_drain_rows)"
  tmp_err="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload "$2")" | /bin/bash "$HOOK" >/dev/null 2>"$tmp_err" || rc="$?"
  after="$(b022_drain_rows)"
  err="$(/bin/cat "$tmp_err")"; /bin/rm -f "$tmp_err"

  [ "$rc" = "$B022_INTERP_FLAG_EXIT" ] || { ok=0; why="$why exit=$rc(want $B022_INTERP_FLAG_EXIT)"; }
  [ "$(( after - before ))" = "1" ] || { ok=0; why="$why drain_delta=$(( after - before ))(want 1)"; }
  last="$(/usr/bin/tail -1 "$B022_DRAIN" 2>/dev/null || /usr/bin/printf '')"
  case "$last" in
    *'"arm":"interp-nonshell"'*) ;;
    *) ok=0; why="$why arm!=interp-nonshell" ;;
  esac
  case "$last" in
    *"\"phase\":\"${B022_INTERP_PHASE}\""*) ;;
    *) ok=0; why="$why phase-field!=${B022_INTERP_PHASE}" ;;
  esac
  case "$last" in
    *"\"cause\":\"$3\""*) ;;
    *) ok=0; why="$why cause!=$3" ;;
  esac
  case "$B022_INTERP_PHASE" in
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

# A hard-refusal case that ALSO asserts the drain did not move. This is the shell
# trio's shape: always-enforce, and NOT routed through the phase-gated router. Exit
# 2 alone would not distinguish the two — a router at `enforce` also exits 2 — so
# the zero drain delta is the half that proves the routing.
nsi_block_norow_case() { # $1 name  $2 command
  local rc=0 before after err tmp_err ok=1 why=""
  before="$(b022_drain_rows)"
  tmp_err="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload "$2")" | /bin/bash "$HOOK" >/dev/null 2>"$tmp_err" || rc="$?"
  after="$(b022_drain_rows)"
  err="$(/bin/cat "$tmp_err")"; /bin/rm -f "$tmp_err"
  [ "$rc" = "2" ] || { ok=0; why="$why exit=$rc(want 2)"; }
  [ "$(( after - before ))" = "0" ] || { ok=0; why="$why drain_delta=$(( after - before ))(want 0 — the trio must not have acquired the warn posture)"; }
  case "$err" in
    *'BLOCK-DESTRUCTIVE-022'*) ;;
    *) ok=0; why="$why no-022-in-stderr" ;;
  esac
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  %s\n' "$1" "$why"; FAIL=$((FAIL + 1))
  fi
}

# Non-allowlisted fixture paths, one per admitted interpreter's suffix domain.
NSI_PY="core/deploy/tools/no-such-tool-xyz.py"
NSI_PL="core/deploy/tools/no-such-tool-xyz.pl"
NSI_RB="core/deploy/tools/no-such-tool-xyz.rb"
NSI_JS="core/deploy/tools/no-such-tool-xyz.js"
NSI_SH="core/deploy/tools/no-such-tool-xyz.sh"

# --- AC-1: a non-shell interpreter invocation is adjudicated AT ALL ------------
nsi_warn_case "T-NSI-01a must-flag: python3 <unlisted>.py is adjudicated" \
  "python3 $NSI_PY" 'not-allowlisted'
nsi_warn_case "T-NSI-01b must-flag: python <unlisted>.py is adjudicated" \
  "python $NSI_PY" 'not-allowlisted'
nsi_warn_case "T-NSI-01c must-flag: perl <unlisted>.pl is adjudicated" \
  "perl $NSI_PL" 'not-allowlisted'
nsi_warn_case "T-NSI-01d must-flag: ruby <unlisted>.rb is adjudicated" \
  "ruby $NSI_RB" 'not-allowlisted'
nsi_warn_case "T-NSI-01e must-flag: node <unlisted>.js is adjudicated" \
  "node $NSI_JS" 'not-allowlisted'
# The absolute spelling reaches the interpreter arm too — the basename is what the
# classifier matches. This is the input T-EXEC-7 used to carry.
nsi_warn_case "T-NSI-07d must-flag: /usr/bin/python3 <unlisted>.py (the input T-EXEC-7 retargeted away from)" \
  "/usr/bin/python3 $NSI_PY" 'not-allowlisted'
# A variable-bearing operand keeps its own cause class, exactly as on the exec arm:
# `unresolvable` has no allowlist remedy and must not be reported as though it had.
nsi_warn_case "T-NSI-01f must-flag: variable-bearing python3 operand records cause=unresolvable" \
  'python3 $TMPDIR/probe.py' 'unresolvable'

# --- FWALK-DOM-* : the operand walk's domain argument, re-pointed at the reconcile -
# The walk terminates on "is this token in the arm's declared operand domain?". The
# commit that introduced that predicate asked it about `$script_verb` and said, in
# the same note, that a successor splitting interpreter DOMAIN from verb CLASS "must
# re-point this ONE argument to that domain variable, or a non-shell interpreter's
# real script is tested against the SHELL suffix set, found unclaimed, walked past,
# and silently under-adjudicated -- a fail-open re-introduced by an otherwise clean
# merge." The per-interpreter domain table IS that split and exists only on this
# side, so these arms are the control for taking the walk verbatim: under
# `$script_verb` the domain is `interp` (the `*.sh` set), `<unlisted>.py` is not
# claimed, the walk advances OFF THE END, and NOTHING is adjudicated -- no drain row
# at all, which is what nsi_warn_case's drain_delta=1 assertion catches.
nsi_warn_case "FWALK-DOM-py must-flag: python3 +x <unlisted>.py is adjudicated (walk asks the PY domain, not the shell one)" \
  "python3 +x $NSI_PY" 'not-allowlisted'
nsi_warn_case "FWALK-DOM-js must-flag: node +x <unlisted>.js is adjudicated (same re-point, second domain)" \
  "node +x $NSI_JS" 'not-allowlisted'

# FWALK-QWORD on a phase-gated interpreter: the quoted flag is stepped over and the
# operand reaches the interpreter arm's router. It sits here, not in block (7b),
# because nsi_warn_case is defined above this point and not above that one.
nsi_warn_case "FWALK-QWORD-py must-flag: python3 \"\"-u <unlisted>.py is adjudicated (the walk reads the quoted flag as -u)" \
  "python3 \"\"-u $NSI_PY" 'not-allowlisted'

# --- AC-1 CONTROL THAT MUST FIRE: an ALLOWLISTED operand writes NO row ---------
# Without this, every arm above would pass against a router that logged
# unconditionally and then allowed. The sandbox allowlist is appended to, the pair
# is observed, and the file is restored — with the restore asserted as its own arm,
# so a failed restore is loud rather than silently corrupting later suites.
NSI_ALLOWLIST="${HOOK%/*}/../script-execution-allowlist.txt"
NSI_ALLOWLIST_BAK="$(/usr/bin/mktemp)"
/bin/cp "$NSI_ALLOWLIST" "$NSI_ALLOWLIST_BAK"
/usr/bin/printf '%s\n' "$NSI_PY" >> "$NSI_ALLOWLIST"
exec_notflag_case "T-NSI-02a [ctl] must-not-flag: the SAME python3 operand, once allowlisted, writes no row" \
  "python3 $NSI_PY"
/bin/cp "$NSI_ALLOWLIST_BAK" "$NSI_ALLOWLIST"
if /usr/bin/cmp -s "$NSI_ALLOWLIST" "$NSI_ALLOWLIST_BAK"; then
  /usr/bin/printf 'PASS: T-NSI-02b allowlist restored after the control arm (later suites see the shipped file)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-02b allowlist NOT restored — later arms and suites are running against a mutated allowlist\n'
  FAIL=$((FAIL + 1))
fi
/bin/rm -f "$NSI_ALLOWLIST_BAK"
# And the pair closes: with the row removed again, the identical payload flags.
nsi_warn_case "T-NSI-02c must-flag: with the allowlist row removed, the identical payload flags again (pair closes)" \
  "python3 $NSI_PY" 'not-allowlisted'

# --- AC-2: the widening is DOMAIN-CORRECT, not blanket ------------------------
# Each domain follows its INTERPRETER. A shared suffix set would adjudicate
# `python3 x.rb` — a file no Python invocation can execute — and would make the
# per-interpreter arms decorative.
exec_notflag_case "T-NSI-03a [ctl]: python3 with an out-of-domain .rb operand is NOT adjudicated" \
  "python3 $NSI_RB"
exec_notflag_case "T-NSI-03b [ctl]: ruby with an out-of-domain .py operand is NOT adjudicated" \
  "ruby $NSI_PY"
exec_notflag_case "T-NSI-03c [ctl]: python3 with a suffixless-domain .txt operand is NOT adjudicated" \
  'python3 core/deploy/tools/no-such-tool-xyz.txt'
# THE BYTE-PRESERVATION SHOWING THROUGH: bash's domain is still `*.sh` alone, so a
# `.py` operand under bash is outside it and unadjudicated — exactly as before this
# change. Its pair on the next line is the discriminator.
exec_notflag_case "T-NSI-03d [ctl]: bash with a .py operand is NOT adjudicated (interp domain unchanged)" \
  "bash $NSI_PY"
nsi_block_norow_case "T-NSI-03e: bash with a .sh operand still hard-refuses (the discriminating pair)" \
  "bash $NSI_SH"

# --- AC-3: the shell trio is byte-preserved AND still always-enforce -----------
# Exit 2 with a ZERO drain delta is the assertion. A trio silently re-routed
# through the phase-gated router would exit 0 and write a row at `warn`; one routed
# through it at `enforce` would exit 2 AND write a row. Both are caught here.
nsi_block_norow_case "T-NSI-04a: bash <unlisted>.sh hard-refuses and writes NO interpreter-arm row" \
  "bash $NSI_SH"
nsi_block_norow_case "T-NSI-04b: sh <unlisted>.sh hard-refuses and writes NO interpreter-arm row" \
  "sh $NSI_SH"
nsi_block_norow_case "T-NSI-04c: zsh <unlisted>.sh hard-refuses and writes NO interpreter-arm row" \
  "zsh $NSI_SH"
nsi_block_norow_case "T-NSI-04d: source <unlisted>.sh hard-refuses and writes NO interpreter-arm row" \
  "source $NSI_SH"
# CONTROL THAT MUST FIRE, in the same run: the newly-admitted interpreter returns
# success AND writes a row, so the difference above is attributable to the ROUTING
# and not to the fixture or to an inert hook.
nsi_warn_case "T-NSI-04e [ctl]: the same fixture stem under python3 returns success and writes a row" \
  "python3 $NSI_PY" 'not-allowlisted'

# --- AC-6: #6172's per-interpreter null holds across the widened key set -------
# `-n` is a parse-only flag FOR A POSIX SHELL. `perl -n` and `ruby -n` are implicit
# input loops that EXECUTE; python has no `-n`; node's parse-only spelling is
# `--check`. Every one of the five new keys therefore hits #6172's documented
# explicit null and must NOT be exempted.
nsi_warn_case "T-NSI-05a: python3 -n <unlisted>.py is NOT exempted (#6172 per-interpreter null)" \
  "python3 -n $NSI_PY" 'not-allowlisted'
nsi_warn_case "T-NSI-05b: perl -n <unlisted>.pl is NOT exempted (implicit input loop EXECUTES)" \
  "perl -n $NSI_PL" 'not-allowlisted'
nsi_warn_case "T-NSI-05c: ruby -n <unlisted>.rb is NOT exempted (implicit input loop EXECUTES)" \
  "ruby -n $NSI_RB" 'not-allowlisted'
nsi_warn_case "T-NSI-05d: node -n <unlisted>.js is NOT exempted" \
  "node -n $NSI_JS" 'not-allowlisted'
# CONTROL THAT MUST FIRE: `bash -n` IS exempted in the same run, so the table is
# observed DISCRIMINATING rather than uniformly refusing.
exec_notflag_case "T-NSI-05e [ctl]: bash -n <unlisted>.sh IS still exempted (the table discriminates)" \
  "bash -n $NSI_SH"

# --- AC-7: the exec arm covers the new suffixes symmetrically ------------------
# `python3 tools/x.py` and `./tools/x.py` are one execution by two spellings.
# These rows carry arm=exec and inherit the exec arm's existing phase.
exec_warn_case "T-NSI-06a must-flag: direct execution of a .py by shebang (exec-arm parity)" \
  './tmp/evil.py' 'not-allowlisted'
exec_warn_case "T-NSI-06b must-flag: direct execution of a .rb by shebang" \
  './tmp/evil.rb' 'not-allowlisted'
exec_warn_case "T-NSI-06c must-flag: direct execution of a .js by shebang" \
  './tmp/evil.js' 'not-allowlisted'
exec_warn_case "T-NSI-06d must-flag: direct execution of a .pl by shebang" \
  './tmp/evil.pl' 'not-allowlisted'
# CONTROL THAT MUST FIRE: the extensionless residual stays PINNED. If this goes red
# the exec domain has been widened past its declared scope.
exec_notflag_case "T-NSI-06e [ctl]: extensionless direct execution still reaches ALLOW (residual stays pinned)" \
  './tmp/evil'

# --- AC-5: the drain is APPORTIONABLE across the two routers -------------------
# A run exercising both routers must produce rows of BOTH `arm` values. A
# single-valued result means one router is not writing and the field is untested.
NSI_ARM_BEFORE="$(b022_drain_rows)"
/usr/bin/printf '%s' "$(bash_payload "python3 $NSI_PY")" | /bin/bash "$HOOK" >/dev/null 2>&1 || true
/usr/bin/printf '%s' "$(bash_payload './tmp/evil.sh')" | /bin/bash "$HOOK" >/dev/null 2>&1 || true
nsi_tail="$(/usr/bin/tail -n 2 "$B022_DRAIN" 2>/dev/null || /usr/bin/printf '')"
nsi_n_interp="$(/usr/bin/printf '%s\n' "$nsi_tail" | /usr/bin/grep -c '"arm":"interp-nonshell"' || true)"
nsi_n_exec="$(/usr/bin/printf '%s\n' "$nsi_tail" | /usr/bin/grep -c '"arm":"exec"' || true)"
if [ "$nsi_n_interp" -ge 1 ] && [ "$nsi_n_exec" -ge 1 ]; then
  /usr/bin/printf 'PASS: T-NSI-08 drain is apportionable — one run produced arm=interp-nonshell (%s) AND arm=exec (%s)\n' \
    "$nsi_n_interp" "$nsi_n_exec"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-08 drain not apportionable — interp-nonshell=%s exec=%s (a single-valued result means one router is silent)\n' \
    "$nsi_n_interp" "$nsi_n_exec"
  FAIL=$((FAIL + 1))
fi
# Every row this suite wrote carries the field at all. An absent field would read as
# `exec` downstream, which would silently mis-attribute an interpreter-arm row.
if [ "$(( $(b022_drain_rows) - NSI_ARM_BEFORE ))" -ge 2 ]; then
  /usr/bin/printf 'PASS: T-NSI-08b both routers wrote in the same run (drain grew by >= 2)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-08b the two-router run did not grow the drain by 2\n'; FAIL=$((FAIL + 1))
fi

# --- AC-12: the #6724 PIN, NOW FLIPPED -----------------------------------------
# THE PIN DID ITS JOB AND IS CONVERTED RATHER THAN DELETED. It read: "DECLARED
# RESIDUAL, NOT DESIRED BEHAVIOUR. The operand-locating walk does not consume a
# flag's ARGUMENT, so `-X faulthandler` leaves `faulthandler` as the adjudicated
# operand — a token no domain claims — and the real script is never reached. #6724
# owns that walk. Pinning it here means their fix flips a PINNED arm and is a
# deliberate act rather than a drift nobody notices."
#
# #6724 SHIPPED, THIS BRANCH MERGED IT, AND THE FLIP IS THAT DELIBERATE ACT. The walk
# now advances past a token the arm's operand domain does not claim, so `faulthandler`
# and `lib` are stepped over and the real script is reached and adjudicated. The arms
# are re-pointed at the NEW verdict and keep the same subject, so the residual cannot
# quietly return: if the walk ever stops short again these go red in the other
# direction.
#
# THE FLIP DEPENDS ON THE DOMAIN RE-POINT AND IS THE EVIDENCE FOR IT. #6724's walk
# asks `script_operand_implicated` about the operand domain, and its own note requires
# a successor that splits interpreter DOMAIN from verb CLASS to re-point that argument.
# Taken verbatim it would ask `$script_verb` — `interp`, the `*.sh` set — so
# `<unlisted>.py` would be unclaimed, advanced past, and the walk would run OFF THE
# END with nothing adjudicated: these two arms would still read ALLOW. They are green
# only because the argument reads `$script_interp_domain`. See FWALK-DOM-*.
nsi_warn_case "T-NSI-09a [flipped, was #6724-owned residual]: python3 -X faulthandler <unlisted>.py IS adjudicated" \
  "python3 -X faulthandler $NSI_PY" 'not-allowlisted'
nsi_warn_case "T-NSI-09b [flipped, was #6724-owned residual]: perl -I lib <unlisted>.pl IS adjudicated" \
  "perl -I lib $NSI_PL" 'not-allowlisted'
# CONTROL THAT MUST FIRE: the same invocation WITHOUT the option-taking flag is
# adjudicated in the same run, so the pin measures the flag walk and not a dead arm.
nsi_warn_case "T-NSI-09c [ctl]: the identical invocation without the flag IS adjudicated" \
  "python3 $NSI_PY" 'not-allowlisted'

# --- NSI-ROW / NSI-F2 (#7026; the adversarial review's F-2, sub-task #8236): what the
# first non-shell allowlist rows open ------------------------------------------------
# The allowlist's non-shell section took its first rows on 2026-10-16, at the
# graduation gate that kept this arm at `warn`: the tracked `.py` tools the drain
# recorded. These arms read the REAL allowlist through the layout, so they bind the
# rows, not a fixture.
#
# A ROW IS LIVE (NSI-ROW-01): the rowed tool alone is admitted silently — exit 0 and
# no drain row, at every phase. It is also the sensitivity control for the two pins
# below: were the row not matched, their lines would draw a row and fail.
#
# WHAT THE ROWS OPEN, PINNED AT ITS MEASURED VERDICT, NOT CLOSED. The walk stops at the
# first token its operand domain claims, and the non-shell interpreters carry no arity
# table, so an option's VALUE that is itself an allowlisted `.py` is taken as the
# operand and admitted — and the script after it, the one the interpreter runs, is never
# read (CPython accepts an unknown `-X` value and runs on). Before any `.py` row existed
# the same line drew a would-fire row, for the option's value; now it allows with no
# row. The verdict does not depend on the phase, so a graduation does not move these
# pins; an arity table for these interpreters flips them deliberately instead of
# drifting. A graduation of the interpreter arm owes this shape, and the readiness
# fragment's decision sentence names it. Pinned for the two admitted interpreters whose
# suffix domain holds rows; `perl`, `ruby` and `node` hold none yet, so the shape is
# not open for them.
NSI_ROWED_PY="core/deploy/tools/check-doc-links.py"
exec_notflag_case "NSI-ROW-01 [ctl]: python3 <rowed>.py is admitted with no drain row — the first non-shell rows are live" \
  "python3 $NSI_ROWED_PY"
exec_notflag_case "NSI-F2-RESID-python3 [pin, declared residual]: python3 -X <rowed>.py <unlisted>.py allows with NO row — the script that runs is never read" \
  "python3 -X $NSI_ROWED_PY $NSI_PY"
exec_notflag_case "NSI-F2-RESID-python [pin, declared residual]: python -X <rowed>.py <unlisted>.py allows with NO row — the script that runs is never read" \
  "python -X $NSI_ROWED_PY $NSI_PY"
# CONTROL THAT MUST FIRE: the identical line with an UNROWED option value is still
# recorded, so the pins measure the row and not a walk that stopped reading.
nsi_warn_case "NSI-F2-ctl-unrowed [ctl]: python3 -X <unlisted>.py <unlisted>.py is still recorded" \
  "python3 -X core/deploy/tools/no-such-tool-abc.py $NSI_PY" 'not-allowlisted'

# --- AC-4 (RETARGETED): the phase gate is LOAD-BEARING, not decorative ---------
# The original AC4 asserted a mode declaration this hook has never had — it is
# MODE-INDEPENDENT and always-enforce. The mechanism it DOES have is the per-rule
# phase constant, and reading the literal is not enough: the constant must be shown
# to change behaviour across all three enum values, plus the fail-closed direction
# for a value outside the enum.
case "$B022_INTERP_PHASE" in
  warn)
    /usr/bin/printf 'PASS: T-NSI-10a the committed interpreter-arm phase is the entry rung `warn`\n'; PASS=$((PASS + 1)) ;;
  *)
    /usr/bin/printf 'FAIL: T-NSI-10a expected committed phase `warn`, read `%s`\n' "$B022_INTERP_PHASE"; FAIL=$((FAIL + 1)) ;;
esac
# The arming stamp must be a RESOLVABLE ISO date, not a placeholder. The platform
# has a worked failure behind that rule: a check shipped expecting a stamp nobody
# wrote and gated nothing for 62 releases.
if /usr/bin/grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' <<<"$B022_INTERP_ARMED" \
   && python3 -c 'import datetime,sys; datetime.date.fromisoformat(sys.argv[1])' "$B022_INTERP_ARMED" 2>/dev/null; then
  /usr/bin/printf 'PASS: T-NSI-10b the interpreter-arm arming stamp is a resolvable ISO date (%s), not a placeholder\n' "$B022_INTERP_ARMED"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-10b arming stamp `%s` is not a resolvable ISO date — the deadline arm cannot be evaluated\n' "$B022_INTERP_ARMED"
  FAIL=$((FAIL + 1))
fi

# The three-value behavioural demonstration. Each probe is a SIBLING of the real
# hook so HOOK_DIR — and therefore every lib and the allowlist — resolves
# identically; each differs from the shipped hook in exactly one word.
nsi_phase_probe() { # $1 phase-value  -> prints "<rc>:<stderr>"
  local probe="${HOOK%/*}/.block-destructive-nsi-phase-probe.sh" rc=0 out=""
  /usr/bin/sed "s/^readonly DESTRUCTIVE_022_INTERP_PHASE=.*/readonly DESTRUCTIVE_022_INTERP_PHASE=\"$1\"/" \
    "$HOOK" > "$probe"
  /bin/chmod +x "$probe"
  out="$(/usr/bin/printf '%s' "$(bash_payload "python3 $NSI_PY")" | /bin/bash "$probe" 2>&1 >/dev/null)" || rc="$?"
  /bin/rm -f "$probe"
  /usr/bin/printf '%s:%s' "$rc" "$out"
}

nsi_enforce="$(nsi_phase_probe enforce)"
case "$nsi_enforce" in
  2:*BLOCK-DESTRUCTIVE-022*)
    /usr/bin/printf 'PASS: T-NSI-10c phase=enforce HARD-REFUSES the identical input\n'; PASS=$((PASS + 1)) ;;
  *)
    /usr/bin/printf 'FAIL: T-NSI-10c phase=enforce: expected exit 2 + BLOCK-DESTRUCTIVE-022, got %s\n' "$nsi_enforce"; FAIL=$((FAIL + 1)) ;;
esac

# `shadow` keeps measuring and stops emitting — the rung that exists so a noisy
# warn phase does not force a choice between notice-spam and going blind. So:
# success, NO notice, and the row still written.
nsi_shadow_before="$(b022_drain_rows)"
nsi_shadow="$(nsi_phase_probe shadow)"
nsi_shadow_delta="$(( $(b022_drain_rows) - nsi_shadow_before ))"
case "${nsi_shadow}|${nsi_shadow_delta}" in
  0:\|1)
    /usr/bin/printf 'PASS: T-NSI-10d phase=shadow allows SILENTLY and still writes its row\n'; PASS=$((PASS + 1)) ;;
  *)
    /usr/bin/printf 'FAIL: T-NSI-10d phase=shadow: expected exit 0, empty stderr, drain +1; got rc:stderr=%s drain_delta=%s\n' \
      "$nsi_shadow" "$nsi_shadow_delta"; FAIL=$((FAIL + 1)) ;;
esac

# CONTROL THAT MUST FIRE: an unrecognised value falls through to REFUSAL. A router
# that failed OPEN on a typo would silently un-arm the rule, which is the direction
# a security control must never take.
nsi_typo="$(nsi_phase_probe wrn)"
case "$nsi_typo" in
  2:*BLOCK-DESTRUCTIVE-022*)
    /usr/bin/printf 'PASS: T-NSI-10e [ctl] an out-of-enum phase value FAILS CLOSED (refuses)\n'; PASS=$((PASS + 1)) ;;
  *)
    /usr/bin/printf 'FAIL: T-NSI-10e [ctl] an out-of-enum phase value did not fail closed, got %s\n' "$nsi_typo"; FAIL=$((FAIL + 1)) ;;
esac

# --- ROLLOUT-DOC-* (#7026, D-1): the readiness SOURCE and the generated index state
# each phased arm's rollout constant in the form `DESTRUCTIVE_022_<FAM>_<NAME>` = value,
# and every value they state is the hook's own ---------------------------------------
# WHY THIS EXISTS. `DESTRUCTIVE_022_EXEC_ARMED` stood stale at 2026-08-24 for five weeks
# while the hook carried 2026-09-03, because nothing compared the sentence to the
# constant: the registry freshness check (build-hook-registry.py --check) compares two
# copies of ONE claim and can never falsify it. These arms tie the sentence to the
# constant it describes, read from the hook in the same run.
#
# BY AGREEMENT, NOT PRESENCE (the adversarial review's F-3, sub-task #8236). The scanner
# reads EVERY `DESTRUCTIVE_022_<NAME>` = value occurrence and requires each to equal the
# hook's value, so a STALE statement standing BESIDE a fresh one — the next shape this
# defect takes — is caught (ROLLOUT-DOC-M2), where a presence check would pass. The scan
# is family-agnostic, so DESTRUCTIVE_022_ENCL_ARMED is tied for free.
#
# FAILS CLOSED: a missing document reports MISSING and reddens; it never reads as
# "nothing to check". NO PIPELINES ANYWHERE: one awk pass over the hook table and the
# document, command-substitution capturing the whole result — never a writer piped into
# a short-circuiting reader (the idiom the repo-integrity SIGPIPE gate matches by name).
# The documents resolve by the same two-rung path the NOEXEC-DOC arms use
# ($NOEXEC_DOC_FRAG / $NOEXEC_DOC_INDEX).
rollout_doc_scan() {   # $1 = document -> "<scanned> <mismatch>", or MISSING
  [ -f "$1" ] || { /usr/bin/printf 'MISSING'; return 0; }
  /usr/bin/awk '
    FNR==NR {
      if ($0 ~ /^readonly DESTRUCTIVE_022_[A-Z_]+=/) {
        rd_line = $0; sub(/^readonly /, "", rd_line)
        rd_eq = index(rd_line, "=")
        rd_nm = substr(rd_line, 1, rd_eq - 1)
        rd_vv = substr(rd_line, rd_eq + 1)
        gsub(/"/, "", rd_vv); sub(/[ \t].*$/, "", rd_vv)
        rd_hook[rd_nm] = rd_vv
      }
      next
    }
    {
      rd_s = $0
      while (match(rd_s, /`DESTRUCTIVE_022_[A-Z_]+` = [A-Za-z0-9._-]+/)) {
        rd_tok = substr(rd_s, RSTART, RLENGTH)
        rd_s   = substr(rd_s, RSTART + RLENGTH)
        rd_n   = split(rd_tok, rd_a, "`")
        rd_name = rd_a[2]
        rd_val  = rd_a[3]; sub(/^ = /, "", rd_val)
        rd_scan++
        if (!(rd_name in rd_hook))      { rd_mis++; next }
        if (rd_hook[rd_name] != rd_val) { rd_mis++ }
      }
    }
    END { printf "%d %d", rd_scan + 0, rd_mis + 0 }
  ' "$HOOK" "$1"
}

rollout_doc_phased_present() {   # $1 = document -> count (0..4) of EXEC/INTERP PHASE+ARMED stated as ` = value`
  [ -f "$1" ] || { /usr/bin/printf '0'; return 0; }
  /usr/bin/awk '
    index($0, "`DESTRUCTIVE_022_EXEC_PHASE` = ")   { rp_ep = 1 }
    index($0, "`DESTRUCTIVE_022_EXEC_ARMED` = ")   { rp_ea = 1 }
    index($0, "`DESTRUCTIVE_022_INTERP_PHASE` = ") { rp_ip = 1 }
    index($0, "`DESTRUCTIVE_022_INTERP_ARMED` = ") { rp_ia = 1 }
    END { printf "%d", rp_ep + rp_ea + rp_ip + rp_ia }
  ' "$1"
}

rollout_doc_agree_arm() {   # $1 = arm id  $2 = label  $3 = document
  local rd_r rd_scanned rd_mis
  rd_r="$(rollout_doc_scan "$3")"
  if [ "$rd_r" = "MISSING" ]; then
    /usr/bin/printf 'FAIL: %s %s is MISSING — the tie cannot be read, and a documentation arm must never read as "nothing to check"\n  file=%s\n' "$1" "$2" "$3"
    FAIL=$((FAIL + 1)); return 0
  fi
  rd_scanned="${rd_r% *}"; rd_mis="${rd_r#* }"
  if [ "$rd_scanned" -gt 0 ] && [ "$rd_mis" -eq 0 ]; then
    /usr/bin/printf 'PASS: %s %s — %s rollout-constant statement(s) read, all equal to the hook\n' "$1" "$2" "$rd_scanned"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s %s — %s statement(s) read, %s disagree with the hook (want scanned>0, mismatch=0)\n  file=%s\n' "$1" "$2" "$rd_scanned" "$rd_mis" "$3"
    FAIL=$((FAIL + 1))
  fi
}

rollout_doc_present_arm() {   # $1 = arm id  $2 = label  $3 = document
  local rd_c; rd_c="$(rollout_doc_phased_present "$3")"
  if [ "$rd_c" -eq 4 ]; then
    /usr/bin/printf 'PASS: %s %s states all four phase-gated constants (EXEC/INTERP PHASE and ARMED) in the tied form\n' "$1" "$2"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s %s states %s of 4 phase-gated constants in the ` = value` form — a dropped statement is an untied constant\n  file=%s\n' "$1" "$2" "$rd_c" "$3"
    FAIL=$((FAIL + 1))
  fi
}

rollout_doc_agree_arm   "ROLLOUT-DOC-01" "readiness SOURCE" "$NOEXEC_DOC_FRAG"
rollout_doc_agree_arm   "ROLLOUT-DOC-02" "generated index"  "$NOEXEC_DOC_INDEX"
rollout_doc_present_arm "ROLLOUT-DOC-03" "readiness SOURCE" "$NOEXEC_DOC_FRAG"
rollout_doc_present_arm "ROLLOUT-DOC-04" "generated index"  "$NOEXEC_DOC_INDEX"

# RED-BEFORE CONTROLS — the scanner must be shown able to report a mismatch, or a clean
# read proves nothing. Each mutates the SHIPPED source and asserts the mutant is LIVE
# (differs) AND that the scan then reports a mismatch.
rollout_doc_control() {   # $1 = arm id  $2 = description  $3 = sed script OR "append:<text>"
  local rd_mut rd_r rd_mis
  rd_mut="$(/usr/bin/mktemp)"
  case "$3" in
    append:*) /bin/cp "$NOEXEC_DOC_FRAG" "$rd_mut"; /usr/bin/printf '\n%s\n' "${3#append:}" >> "$rd_mut" ;;
    *)        /usr/bin/sed "$3" "$NOEXEC_DOC_FRAG" > "$rd_mut" ;;
  esac
  if /usr/bin/cmp -s "$NOEXEC_DOC_FRAG" "$rd_mut"; then
    /usr/bin/printf 'FAIL: %s mutation is INERT — mutant is byte-identical to the shipped source; re-point it\n' "$1"
    FAIL=$((FAIL + 1)); /bin/rm -f "$rd_mut"; return 0
  fi
  rd_r="$(rollout_doc_scan "$rd_mut")"; /bin/rm -f "$rd_mut"
  rd_mis="${rd_r#* }"
  if [ "$rd_r" != "MISSING" ] && [ "$rd_mis" -gt 0 ]; then
    /usr/bin/printf 'PASS: %s mutation is live AND the scan reports %s mismatch(es) (red-before control fires)\n' "$1" "$rd_mis"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s scanner did not report the planted drift (result=%s)\n' "$1" "$rd_r"
    FAIL=$((FAIL + 1))
  fi
}

# (M1) a stated value changed to a wrong one — the drift the registry check cannot see.
# Targets DESTRUCTIVE_022_EXEC_REVIEW_DAYS = 60, which the fragment carries in every state.
rollout_doc_control "ROLLOUT-DOC-M1" "value changed" \
  's|`DESTRUCTIVE_022_EXEC_REVIEW_DAYS` = 60|`DESTRUCTIVE_022_EXEC_REVIEW_DAYS` = 61|'
# (M2) a STALE statement appended beside the fresh ones — F-3's shape, invisible to a
# presence check. The retired 2026-08-24 arming date is the regression this arm exists for.
rollout_doc_control "ROLLOUT-DOC-M2" "stale statement appended" \
  'append:> A stray restatement left by a partial edit: `DESTRUCTIVE_022_EXEC_ARMED` = 2026-08-24 somewhere below the real one.'

# --- AC-9: PAIRED MUTATION ARMS (REQUIRED) ------------------------------------
# Three arms in this milestone's prior release read green while their mutation was
# INERT, so each mutant is asserted to DIFFER from the shipped hook before anything
# it reports is believed.
#
# MUTANT 1 reverts the interpreter set to the shell-only trio at BOTH classifier
# views — exactly the two lines the widening commit changed.
NSI_MUT1="${HOOK%/*}/.block-destructive-nsi-mut1.sh"
/usr/bin/sed 's/^\( *\)bash|sh|zsh|python|python3|perl|ruby|node)/\1bash|sh|zsh)/' \
  "$HOOK" > "$NSI_MUT1"
if /usr/bin/cmp -s "$HOOK" "$NSI_MUT1"; then
  /usr/bin/printf 'FAIL: T-NSI-11a mutation 1 is INERT — mutant is byte-identical to the shipped hook\n'; FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: T-NSI-11a mutation 1 is live (classifier reverted to the shell trio)\n'; PASS=$((PASS + 1))
fi
# The mutant must NOT adjudicate T-NSI-01a's subject: exit 0 AND no drain row. That
# is the pre-change behaviour, and it is what proves T-NSI-01a measures the
# widening rather than a hook that flags everything.
nsi_m1_before="$(b022_drain_rows)"
nsi_m1_rc=0
/usr/bin/printf '%s' "$(bash_payload "python3 $NSI_PY")" | /bin/bash "$NSI_MUT1" >/dev/null 2>&1 || nsi_m1_rc="$?"
nsi_m1_delta="$(( $(b022_drain_rows) - nsi_m1_before ))"
if [ "$nsi_m1_rc" = "0" ] && [ "$nsi_m1_delta" = "0" ]; then
  /usr/bin/printf 'PASS: T-NSI-11b mutant 1 (shell-trio classifier) does NOT adjudicate python3 <unlisted>.py\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-11b mutant 1 should be inert on the new subject; rc=%s drain_delta=%s\n' "$nsi_m1_rc" "$nsi_m1_delta"; FAIL=$((FAIL + 1))
fi
/bin/rm -f "$NSI_MUT1"

# MUTANT 2 reverts ONLY the four operand-domain arms, leaving the classifier
# widened. It must ALSO turn the new subject inert — which is the proof that the
# verb widening ALONE is inert, and therefore that both halves of the fix are
# load-bearing. A design that shipped the classifier without the domains would look
# correct and adjudicate nothing.
NSI_MUT2="${HOOK%/*}/.block-destructive-nsi-mut2.sh"
/usr/bin/sed -e '/^    interp-py) case /d' -e '/^    interp-pl) case /d' \
             -e '/^    interp-rb) case /d' -e '/^    interp-js) case /d' \
  "$HOOK" > "$NSI_MUT2"
if /usr/bin/cmp -s "$HOOK" "$NSI_MUT2"; then
  /usr/bin/printf 'FAIL: T-NSI-11c mutation 2 is INERT — mutant is byte-identical to the shipped hook\n'; FAIL=$((FAIL + 1))
else
  /usr/bin/printf 'PASS: T-NSI-11c mutation 2 is live (per-interpreter operand domains removed)\n'; PASS=$((PASS + 1))
fi
nsi_m2_before="$(b022_drain_rows)"
nsi_m2_rc=0
/usr/bin/printf '%s' "$(bash_payload "python3 $NSI_PY")" | /bin/bash "$NSI_MUT2" >/dev/null 2>&1 || nsi_m2_rc="$?"
nsi_m2_delta="$(( $(b022_drain_rows) - nsi_m2_before ))"
if [ "$nsi_m2_rc" = "0" ] && [ "$nsi_m2_delta" = "0" ]; then
  /usr/bin/printf 'PASS: T-NSI-11d mutant 2 (classifier widened, domains removed) is INERT — the verb widening alone adjudicates nothing\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-11d mutant 2 should be inert; rc=%s drain_delta=%s\n' "$nsi_m2_rc" "$nsi_m2_delta"; FAIL=$((FAIL + 1))
fi
# The mutant must still refuse the SHELL operand — otherwise mutation 2 broke the
# whole rule and T-NSI-11d's zero would be measuring a dead hook rather than an
# inert widening.
nsi_m2_sh_rc=0
/usr/bin/printf '%s' "$(bash_payload "bash $NSI_SH")" | /bin/bash "$NSI_MUT2" >/dev/null 2>&1 || nsi_m2_sh_rc="$?"
if [ "$nsi_m2_sh_rc" = "2" ]; then
  /usr/bin/printf 'PASS: T-NSI-11e [ctl] mutant 2 still refuses bash <unlisted>.sh — its inertness above is scoped, not a dead hook\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: T-NSI-11e [ctl] mutant 2 stopped refusing the shell operand (rc=%s) — T-NSI-11d proves nothing\n' "$nsi_m2_sh_rc"; FAIL=$((FAIL + 1))
fi
/bin/rm -f "$NSI_MUT2"

# ==========================================================================
# WALKCORPUS-* — the tracked payload differential for the operand walk
# ==========================================================================
#
# WHAT THIS IS. core/hooks/tests/fixtures/walk-payload-corpus.txt is the one committed
# corpus that every change to this rule's token walk shares as its exit bar: no payload's
# verdict may move from refused to allowed except as a declared precision improvement,
# with the detector shown able to fire first. Each row records the verdict the hook
# returns. This block runs every `block-destructive` row against the shipped hook and
# fails a group whose rows return anything else, so the corpus diff of a change IS that
# change's differential, and this block is what keeps the recorded column true. The row
# format and the procedure for adding rows: core/hooks/tests/fixtures/README.md.
#
# HERMETIC, ON THE F2 BLOCK'S PATTERN AND FOR ITS REASON. The rows' allows turn on
# allowlist membership, so this block owns its runtime: its own root, its own copy of
# the hook and of the operand-walk mutant (the AC-D022 reversion, the same two sed
# expressions), an allowlist naming exactly @D@/ok.sh and @D@/ok.py, its own .mode,
# payload cwd inside the root, and PMO_SCOPE_GUARD_ROOT / CLAUDE_WORKSPACE_ROOT unset for
# every run. WALKCORPUS-SCOPE asserts the copy is live before any verdict is read.
#
# THE CORPUS IS RESOLVED, NEVER ASSUMED, and an unresolved corpus is a FAIL rather than
# an empty pass: (1) beside this file, the source-tree run; (2) the .source-repo-root
# pointer setup-ci-layout.sh writes beside the materialized tests, the CI sandbox rung;
# (3) the repository root above a default-site layout.
#
# A VERDICT IS READ FROM THE EXIT CODE AND THE DRAIN. Exit 2 is B. Exit 0 with a new row
# in the hermetic drain is W, a would-fire at a rollout phase, whatever that phase prints.
# Exit 0 with no new row is a. Anything else is reported as E<rc> and never matches.
echo ""
echo "BLOCK-022 walk-payload corpus (WALKCORPUS-*)"
echo "---"

WC_REL="core/hooks/tests/fixtures/walk-payload-corpus.txt"
WC_FILE=""
WC_RUNG=""
wc_try() { # $1 = candidate file  $2 = rung label
  if [ -z "$WC_FILE" ] && [ -n "$1" ] && [ -f "$1" ]; then WC_FILE="$1"; WC_RUNG="$2"; fi
}
wc_try "$(dirname "$0")/fixtures/walk-payload-corpus.txt" "beside the suite"
wc_src_root=""
if [ -r "$(dirname "$0")/.source-repo-root" ]; then
  IFS= read -r wc_src_root < "$(dirname "$0")/.source-repo-root" || true
fi
if [ -n "$wc_src_root" ]; then wc_try "${wc_src_root}/${WC_REL}" ".source-repo-root pointer"; fi
wc_up="$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd -P)"
if [ -n "$wc_up" ]; then wc_try "${wc_up}/${WC_REL}" "repository root above the layout"; fi

# The rows this suite owns, loaded once into parallel arrays (bash 3.2: no associative
# arrays). A row whose hook field names another guard is counted and left to that
# guard's suite.
WC_ID=(); WC_GROUP=(); WC_TWIN=(); WC_GT=(); WC_REC=(); WC_CMD=(); WC_OBS=()
wc_total=0
wc_other=0
if [ -n "$WC_FILE" ]; then
  while IFS='|' read -r f_id f_hook f_group f_twin f_gt f_rec f_cmd || [ -n "$f_id" ]; do
    case "$f_id" in ''|'#'*) continue ;; esac
    wc_total=$((wc_total + 1))
    if [ "$f_hook" != "block-destructive" ]; then wc_other=$((wc_other + 1)); continue; fi
    WC_ID+=("$f_id"); WC_GROUP+=("$f_group"); WC_TWIN+=("$f_twin")
    WC_GT+=("$f_gt"); WC_REC+=("$f_rec"); WC_CMD+=("$f_cmd")
  done < "$WC_FILE"
fi
wc_n=${#WC_ID[@]}

# WALKCORPUS-00 — resolution and identity. The digest is the SHA-256 of the committed
# file, printed here so every run's output carries the identity of the corpus it graded,
# recomputable from the file itself (README.md beside the corpus).
if [ -z "$WC_FILE" ]; then
  /usr/bin/printf 'FAIL: WALKCORPUS-00 corpus UNRESOLVED — every rung missed (beside=%s pointer=%s root=%s); no row was graded\n' \
    "$(dirname "$0")/fixtures" "${wc_src_root:-<none>}" "${wc_up:-<none>}"
  FAIL=$((FAIL + 1))
elif [ "$wc_n" -eq 0 ]; then
  /usr/bin/printf 'FAIL: WALKCORPUS-00 corpus resolved via %s but carries no block-destructive row (%s rows in all)\n' "$WC_RUNG" "$wc_total"
  FAIL=$((FAIL + 1))
else
  wc_digest="$(/usr/bin/shasum -a 256 "$WC_FILE")"
  wc_digest="${wc_digest%% *}"
  /usr/bin/printf 'PASS: WALKCORPUS-00 corpus resolved via %s: %s block-destructive rows of %s (%s for other guards), sha256 %s\n' \
    "$WC_RUNG" "$wc_n" "$wc_total" "$wc_other" "$wc_digest"
  PASS=$((PASS + 1))
fi

# WALKCORPUS-ROWS — every row is well formed: a unique id, a verdict and a ground-truth
# class from their closed sets, a group, a command, and a twin that names a row of this
# guard. A malformed row would otherwise grade as a mismatch, or not at all.
wc_badrows=""
wc_all_ids="|"
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  wc_all_ids="${wc_all_ids}${WC_ID[$wc_i]}|"
  wc_i=$((wc_i + 1))
done
wc_seen_ids="|"
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  wc_why=""
  case "${WC_REC[$wc_i]}" in a|B|W) ;; *) wc_why="${wc_why} verdict" ;; esac
  case "${WC_GT[$wc_i]}" in X|o|w|e|s|-|'?') ;; *) wc_why="${wc_why} gt" ;; esac
  [ -n "${WC_GROUP[$wc_i]}" ] || wc_why="${wc_why} group"
  [ -n "${WC_CMD[$wc_i]}" ] || wc_why="${wc_why} command"
  case "${WC_ID[$wc_i]}" in
    *'|'*|'') wc_why="${wc_why} id" ;;
  esac
  case "$wc_seen_ids" in
    *"|${WC_ID[$wc_i]}|"*) wc_why="${wc_why} duplicate-id" ;;
  esac
  wc_seen_ids="${wc_seen_ids}${WC_ID[$wc_i]}|"
  if [ "${WC_TWIN[$wc_i]}" != "-" ]; then
    case "$wc_all_ids" in
      *"|${WC_TWIN[$wc_i]}|"*) ;;
      *) wc_why="${wc_why} twin" ;;
    esac
  fi
  if [ -n "$wc_why" ]; then wc_badrows="${wc_badrows} ${WC_ID[$wc_i]}(${wc_why# })"; fi
  wc_i=$((wc_i + 1))
done
if [ "$wc_n" -gt 0 ] && [ -z "$wc_badrows" ]; then
  /usr/bin/printf 'PASS: WALKCORPUS-ROWS all %s rows are well formed (unique ids, closed verdict and ground-truth sets, twins resolve)\n' "$wc_n"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WALKCORPUS-ROWS malformed rows:%s\n' "${wc_badrows:- <no rows read>}"
  FAIL=$((FAIL + 1))
fi

# The hermetic runtime.
WC_ROOT="$(/usr/bin/mktemp -d)"
WC_HOOKS="${WC_ROOT}/.claude/hooks"
/bin/mkdir -p "${WC_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${WC_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${WC_HOOKS}/lib/" 2>/dev/null || true
WC_D="/tmp/pmo-walk-corpus"
/usr/bin/printf '%s\n' "${WC_D}/ok.sh" "${WC_D}/ok.py" "${WC_D}/li sted/ok.sh" > "${WC_ROOT}/.claude/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${WC_HOOKS}/.mode"
/bin/cp "$HOOK" "${WC_HOOKS}/block-destructive.sh"
/usr/bin/sed \
  -e '/# M-FWALK-BODY/,/^[[:space:]]*;;$/d' \
  -e 's|^\([[:space:]]*\)\*) # M-FWALK-ADVANCE.*|\1*) break ;;|' \
  "$HOOK" > "${WC_HOOKS}/block-destructive-mut.sh"
/bin/chmod +x "${WC_HOOKS}/block-destructive.sh" "${WC_HOOKS}/block-destructive-mut.sh"
WC_DRAIN="${WC_HOOKS}/destructive-warn-log.jsonl"
WC_LONGX="$(/usr/bin/printf '%*s' 4100 '' | /usr/bin/tr ' ' 'x')"
WC_LONGN="$(/usr/bin/printf '%*s' 4100 '' | /usr/bin/tr ' ' 'n')"
WC_SHORTX="$(/usr/bin/printf '%*s' 4000 '' | /usr/bin/tr ' ' 'x')"
WC_MIDX="$(/usr/bin/printf '%*s' 1000 '' | /usr/bin/tr ' ' 'x')"
WC_MIDN="$(/usr/bin/printf '%*s' 1000 '' | /usr/bin/tr ' ' 'n')"
WC_QPAD="$(/usr/bin/printf '%*s' 2050 '' | /usr/bin/sed 's/ /""/g')"
WC_QMID="$(/usr/bin/printf '%*s' 400 '' | /usr/bin/sed 's/ /""/g')"

wc_drain_rows() {
  if [ -f "$WC_DRAIN" ]; then
    /usr/bin/wc -l < "$WC_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

WC_CMDX=""
wc_expand() { # $1 = command template -> WC_CMDX
  local c="$1"
  c="${c//@D@/$WC_D}"
  c="${c//@LONGX@/$WC_LONGX}"
  c="${c//@LONGN@/$WC_LONGN}"
  c="${c//@SHORTX@/$WC_SHORTX}"
  c="${c//@MIDX@/$WC_MIDX}"
  c="${c//@MIDN@/$WC_MIDN}"
  c="${c//@QPAD@/$WC_QPAD}"
  c="${c//@QMID@/$WC_QMID}"
  c="${c//@NL@/$'\n'}"
  WC_CMDX="$c"
}

WC_V=""
wc_run() { # $1 = hook file in the hermetic hooks dir  $2 = command -> WC_V
  local rc=0 before after
  before="$(wc_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$WC_ROOT")" \
      | /bin/bash "${WC_HOOKS}/$1" >/dev/null 2>&1 ) || rc="$?"
  after="$(wc_drain_rows)"
  case "$rc" in
    2) WC_V="B" ;;
    0) if [ "$after" -gt "$before" ]; then WC_V="W"; else WC_V="a"; fi ;;
    *) WC_V="E${rc}" ;;
  esac
}

# WALKCORPUS-SCOPE — the hermetic copy is in scope and enforcing, shown by a rule this
# change never touches. An inert copy would allow every row and grade every recorded
# allow as a pass.
wc_scope_rc=0
wc_scope_err="$(/usr/bin/mktemp)"
( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
  /usr/bin/printf '%s' "$(bash_payload 'git push --force origin main' "$WC_ROOT")" \
    | /bin/bash "${WC_HOOKS}/block-destructive.sh" >/dev/null 2>"$wc_scope_err" ) || wc_scope_rc="$?"
if [ "$wc_scope_rc" = 2 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-001' "$wc_scope_err"; then
  /usr/bin/printf 'PASS: WALKCORPUS-SCOPE hermetic copy is in scope and enforcing (unrelated rule -001 fires), so the verdicts below are live\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WALKCORPUS-SCOPE hermetic copy is not live (exit=%s, expected 2 naming BLOCK-DESTRUCTIVE-001); the verdicts below are unusable\n' "$wc_scope_rc"
  FAIL=$((FAIL + 1))
fi
/bin/rm -f "$wc_scope_err"

# Every row through the shipped hook, once.
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  wc_expand "${WC_CMD[$wc_i]}"
  wc_run block-destructive.sh "$WC_CMDX"
  WC_OBS[$wc_i]="$WC_V"
  wc_i=$((wc_i + 1))
done

# WALKCORPUS-REC-<group> — one arm per group: each row returns its recorded verdict. A
# failure names every row that moved, as id(recorded->observed), on the FAIL line itself,
# because the runner forwards only that line.
WC_GROUPS=()
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  wc_seen=0
  for wc_g in ${WC_GROUPS[@]+"${WC_GROUPS[@]}"}; do
    if [ "$wc_g" = "${WC_GROUP[$wc_i]}" ]; then wc_seen=1; fi
  done
  if [ "$wc_seen" -eq 0 ]; then WC_GROUPS+=("${WC_GROUP[$wc_i]}"); fi
  wc_i=$((wc_i + 1))
done
for wc_g in ${WC_GROUPS[@]+"${WC_GROUPS[@]}"}; do
  wc_rows=0
  wc_moved=""
  wc_i=0
  while [ "$wc_i" -lt "$wc_n" ]; do
    if [ "${WC_GROUP[$wc_i]}" = "$wc_g" ]; then
      wc_rows=$((wc_rows + 1))
      if [ "${WC_OBS[$wc_i]}" != "${WC_REC[$wc_i]}" ]; then
        wc_moved="${wc_moved} ${WC_ID[$wc_i]}(${WC_REC[$wc_i]}->${WC_OBS[$wc_i]})"
      fi
    fi
    wc_i=$((wc_i + 1))
  done
  if [ -z "$wc_moved" ]; then
    /usr/bin/printf 'PASS: WALKCORPUS-REC-%s %s rows return their recorded verdicts\n' "$wc_g" "$wc_rows"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: WALKCORPUS-REC-%s rows moved from their recorded verdicts:%s\n' "$wc_g" "$wc_moved"
    FAIL=$((FAIL + 1))
  fi
done

# WALKCORPUS-OPEN — a row in an `open-` group records an execution the guard allows
# today. It must stay a recorded allow of an executing payload: the change that closes it
# moves its verdict AND drops the prefix, so a refused row still marked open is a
# half-applied closure and fails here.
wc_open=0
wc_open_bad=""
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  case "${WC_GROUP[$wc_i]}" in
    open-*)
      wc_open=$((wc_open + 1))
      if [ "${WC_REC[$wc_i]}" != "a" ] || [ "${WC_GT[$wc_i]}" != "X" ]; then
        wc_open_bad="${wc_open_bad} ${WC_ID[$wc_i]}(${WC_REC[$wc_i]},gt=${WC_GT[$wc_i]})"
      fi
      ;;
  esac
  wc_i=$((wc_i + 1))
done
if [ -z "$wc_open_bad" ]; then
  /usr/bin/printf 'PASS: WALKCORPUS-OPEN %s rows declared open, each a recorded allow of an executing payload\n' "$wc_open"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WALKCORPUS-OPEN rows marked open that are not a recorded allow of an executing payload:%s\n' "$wc_open_bad"
  FAIL=$((FAIL + 1))
fi

# WALKCORPUS-TWIN — a quoted row is never WEAKER than its unquoted twin. One-directional
# on purpose: a quoted spelling may be stricter than its twin (a word whose value argv
# does not determine takes the conservative route where its unquoted spelling is stepped
# over), but it may never be allowed where the twin is refused or warned on, nor warned
# where the twin is refused. Read on the OBSERVED verdicts, so it grades the hook in this
# run and not the recorded column. Rows in an `open-` group are declared allows, left to
# WALKCORPUS-OPEN.
wc_twin_n=0
wc_twin_bad=""
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  case "${WC_GROUP[$wc_i]}" in
    open-*) ;;
    *)
      if [ "${WC_TWIN[$wc_i]}" != "-" ]; then
        wc_twin_n=$((wc_twin_n + 1))
        wc_tv=""
        wc_j=0
        while [ "$wc_j" -lt "$wc_n" ]; do
          if [ "${WC_ID[$wc_j]}" = "${WC_TWIN[$wc_i]}" ]; then wc_tv="${WC_OBS[$wc_j]}"; break; fi
          wc_j=$((wc_j + 1))
        done
        case "${WC_OBS[$wc_i]}" in a) wc_r1=0 ;; W) wc_r1=1 ;; B) wc_r1=2 ;; *) wc_r1=-1 ;; esac
        case "$wc_tv" in a) wc_r2=0 ;; W) wc_r2=1 ;; B) wc_r2=2 ;; *) wc_r2=-1 ;; esac
        if [ "$wc_r1" -lt 0 ] || [ "$wc_r2" -lt 0 ] || [ "$wc_r1" -lt "$wc_r2" ]; then
          wc_twin_bad="${wc_twin_bad} ${WC_ID[$wc_i]}(${WC_OBS[$wc_i]}<${WC_TWIN[$wc_i]}:${wc_tv:-?})"
        fi
      fi
      ;;
  esac
  wc_i=$((wc_i + 1))
done
if [ "$wc_twin_n" -gt 0 ] && [ -z "$wc_twin_bad" ]; then
  /usr/bin/printf 'PASS: WALKCORPUS-TWIN all %s rows with an unquoted twin are at least as strict as it\n' "$wc_twin_n"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WALKCORPUS-TWIN rows weaker than their unquoted twin (row(observed<twin:observed)):%s\n' "${wc_twin_bad:- <no twin rows read>}"
  FAIL=$((FAIL + 1))
fi

# WALKCORPUS-DET-* — the detector, shown able to fire and shown alive. The same rows
# through the operand-walk mutant (the walk reverted to its dash-anchored form): every row
# recorded B or W is run, and the mutant must ALLOW at least one of them (the detector
# fires) while still refusing or warning on at least one (it is a live hook, not a dead
# copy that allows everything). A zero in the corpus's own comparison above is read only
# after this pair is green.
wc_det_fires=0
wc_det_alive=0
wc_i=0
while [ "$wc_i" -lt "$wc_n" ]; do
  case "${WC_REC[$wc_i]}" in
    B|W)
      wc_expand "${WC_CMD[$wc_i]}"
      wc_run block-destructive-mut.sh "$WC_CMDX"
      case "$WC_V" in
        a) wc_det_fires=$((wc_det_fires + 1)) ;;
        B|W) wc_det_alive=$((wc_det_alive + 1)) ;;
      esac
      ;;
  esac
  wc_i=$((wc_i + 1))
done
if [ "$wc_det_fires" -gt 0 ]; then
  /usr/bin/printf 'PASS: WALKCORPUS-DET-fires the operand-walk mutant moves %s recorded refusals or warnings to an allow (the detector fires)\n' "$wc_det_fires"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WALKCORPUS-DET-fires the operand-walk mutant moved no recorded refusal to an allow; the comparison above cannot be read as clean\n'
  FAIL=$((FAIL + 1))
fi
if [ "$wc_det_alive" -gt 0 ]; then
  /usr/bin/printf 'PASS: WALKCORPUS-DET-alive the same mutant still refuses or warns on %s recorded rows (a live hook, not a dead copy)\n' "$wc_det_alive"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WALKCORPUS-DET-alive the mutant refused nothing; its allows above prove nothing\n'
  FAIL=$((FAIL + 1))
fi

# The runner forwards RESIDUAL lines from a green run and discards the PASS lines, so
# the corpus identity and what a green corpus does not speak for are stated here, where
# every run's output carries them.
/usr/bin/printf 'RESIDUAL: WALKCORPUS graded %s block-destructive rows of the corpus at sha256 %s (resolved via %s); %s of them are declared open — allowed executions a later change owns — and a green corpus speaks only for the rows it carries. The operand-walk mutant moved %s recorded refusals or warnings to an allow.\n' \
  "$wc_n" "${wc_digest:-unresolved}" "${WC_RUNG:-no rung}" "$wc_open" "$wc_det_fires"

/bin/rm -rf "$WC_ROOT"

echo ""
echo "BLOCK-022 parse-only: where the option run ends (NOEXEC-TERM-* / STDIN-*)"
echo "---"
# SUBJECT. The parse-only exemption is granted by a bare `-n`, and the walk that grants
# it keeps looking past every token the operand domain does not claim. So it granted on
# a `-n` the interpreter never read as a flag: one that sits AFTER the first non-option
# argument, where it is a positional parameter; or one that is the ARGUMENT of an option
# whose text is not its value (`--rcfile""`, `--rcfile$X`), which the arity table is
# asked about by its text and does not find. The first kind runs stdin, or a script the
# operand domain does not claim, with the guard reading "parse-only". The second
# EXECUTES the script behind the `-n`.
#
# Every arm in (1) is a BLOCK at the commit that predates the parse-only exemption and
# an ALLOW on the hook as it stood before this change. The revert mutant
# NOEXEC-TERM-M1* reproduces that ALLOW in this same run.
TERM_WRAP="/tmp/pmo-term-wrapper"

# (1a) A `-n` AFTER THE OPTION RUN HAS ENDED. Measured against the real shells: zsh's
# `-O` and `+O` take no argument, so `extglob` is the first non-option argument and the
# `-n` behind it is a positional parameter. Under `-s` the shell then runs its stdin;
# without `-s` it runs the word as a script. bash and sh take `extglob` as the argument
# of `-O`, so their arms put the word directly after `-s`.
test_case "NOEXEC-TERM-01: zsh -s -O extglob -n <unlisted>.sh blocks (the card's shape: -n is a positional, stdin executes)" \
  "$(bash_payload "zsh -s -O extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-02: zsh -s +O extglob -n <unlisted>.sh blocks (the card's second shape)" \
  "$(bash_payload "zsh -s +O extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-03: bash -s extglob -n <unlisted>.sh blocks (the same class under bash)" \
  "$(bash_payload "bash -s extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-04: sh -s extglob -n <unlisted>.sh blocks (the same class under sh)" \
  "$(bash_payload "sh -s extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-05: zsh -O extglob -n <unlisted>.sh blocks (no stdin mode: the word is the script zsh runs)" \
  "$(bash_payload "zsh -O extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-06: bash <wrapper> -n <unlisted>.sh blocks (twin of F2-FWALK-CONSEQ-extless: a -n behind the wrapper is the wrapper's argument)" \
  "$(bash_payload "bash $TERM_WRAP -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-13: bash - -n <unlisted>.sh blocks (a lone dash ends option reading; the -n behind it is not a flag)" \
  "$(bash_payload "bash - -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-14: zsh - -n <unlisted>.sh blocks (the same under zsh)" \
  "$(bash_payload "zsh - -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (1b) A `-n` BEHIND A TOKEN THE WALK CANNOT READ. THESE EXECUTE THE SCRIPT. In 07 to 17
# each spelling is `--rcfile` or `--emulate` to the shell, which takes the `-n` as the
# option's argument; the arity table is asked about the text and has no row for it. In
# 18 the `-n` belongs to the command inside the substitution and the interpreter never
# sees it. PMO_TERM_UNSET is never set and never expanded here.
test_case "NOEXEC-TERM-07: bash --rcfile\"\" -n <unlisted>.sh blocks (an empty quoted string inside the option; -n is the rcfile NAME)" \
  "$(bash_payload "bash --rcfile\"\" -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-08: bash --rc\\file -n <unlisted>.sh blocks (a backslash inside the option)" \
  "$(bash_payload "bash --rc\\file -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-09: bash --rcfile\$VAR -n <unlisted>.sh blocks (an expansion behind the option)" \
  "$(bash_payload "bash --rcfile\$PMO_TERM_UNSET -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-10: zsh \$VAR--emulate -n <unlisted>.sh blocks (an expansion ahead of the option)" \
  "$(bash_payload "zsh \$PMO_TERM_UNSET--emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-11: zsh -\$VAR-emulate -n <unlisted>.sh blocks (an expansion between the dashes)" \
  "$(bash_payload "zsh -\$PMO_TERM_UNSET-emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-12: bash \"--rcfile\$VAR\" -n <unlisted>.sh blocks (fully quoted, an expansion inside)" \
  "$(bash_payload "bash \"--rcfile\$PMO_TERM_UNSET\" -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-15: zsh \\--emulate -n <unlisted>.sh blocks (a backslash AHEAD of the option)" \
  "$(bash_payload "zsh \\--emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-16: zsh +-emu\"\"late -n <unlisted>.sh blocks (a plus-form option with a quote inside)" \
  "$(bash_payload "zsh +-emu\"\"late -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
# The brace word reaches the payload through a variable, never as literal text inside
# "$( … "…" )": bash 3.2 brace-expands there, and one arm silently becomes two payloads.
TERM_BRACE='--{norc,rcfile}'
test_case "NOEXEC-TERM-17: bash --{norc,rcfile} -n <unlisted>.sh blocks (a brace word is two options to the shell)" \
  "$(bash_payload "bash $TERM_BRACE -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-18: bash \$(echo -n <unlisted>.sh) blocks (a -n inside a command substitution is not this interpreter's flag)" \
  "$(bash_payload "bash \$(echo -n $PARSE_UNLISTED)")" 2 "BLOCK-DESTRUCTIVE-022"

# (1c) A `-n` BEHIND AN OPTION ARGUMENT THAT MAY BE NO WORD AT ALL. THESE EXECUTE THE
# SCRIPT TOO. The walk consumes the token after an argument-taking option as that
# option's argument. An unquoted expansion of nothing is not a word, and neither is a
# quoted list expansion of an empty list, so the shell gives the option the `-n` instead.
test_case "NOEXEC-TERM-19: bash --rcfile \$VAR -n <unlisted>.sh blocks (an unset variable is no word: -n becomes the rcfile NAME)" \
  "$(bash_payload "bash --rcfile \$PMO_TERM_UNSET -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-20: zsh --emulate \$VAR -n <unlisted>.sh blocks (the same under zsh)" \
  "$(bash_payload "zsh --emulate \$PMO_TERM_UNSET -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-21: bash --rcfile \"\$@\" -n <unlisted>.sh blocks (a quoted list expansion can also be no word)" \
  "$(bash_payload "bash --rcfile \"\$@\" -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (2) MUST STAY ALLOWED. Every one is genuinely inert under the real shell and is allowed
# before and after. If one turns red the latch has started ending the option run on a
# token that does not end it. The over-latch mutant NOEXEC-TERM-M2* refuses each of
# them, which is what shows these arms can fail.
test_case "NOEXEC-TERM-ctl-stdin: zsh -s -n <unlisted>.sh allowed (the card's control: -n directly after -s is a real flag)" \
  "$(bash_payload "zsh -s -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-arity: bash -s -O extglob -n <unlisted>.sh allowed (bash's -O TAKES extglob, so the -n is a real flag)" \
  "$(bash_payload "bash -s -O extglob -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-optarg: zsh -o extendedglob -n <unlisted>.sh allowed (a consumed argument does not end the run)" \
  "$(bash_payload "zsh -o extendedglob -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-plus: bash +x -n <unlisted>.sh allowed (a plus-form option is an option word)" \
  "$(bash_payload "bash +x -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-qplus: bash '+x' -n <unlisted>.sh allowed (a quoted option is read as its value)" \
  "$(bash_payload "bash '+x' -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-qflag: bash \"-x\" -n <unlisted>.sh allowed (the same, dash form)" \
  "$(bash_payload "bash \"-x\" -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-long: bash --norc --noprofile -n <unlisted>.sh allowed (long options are option words)" \
  "$(bash_payload "bash --norc --noprofile -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-qarg: bash -o 'pipefail' -n <unlisted>.sh allowed (a quoted argument with plain text is one word the walk holds)" \
  "$(bash_payload "bash -o 'pipefail' -n $PARSE_UNLISTED")" 0
test_case "NOEXEC-TERM-ctl-emptyarg: bash --rcfile \"\" -n <unlisted>.sh allowed (a quoted empty argument is one word)" \
  "$(bash_payload "bash --rcfile \"\" -n $PARSE_UNLISTED")" 0

# (3) THE LATCH ADJUDICATES; IT DOES NOT DENY. The card's own shape in front of an
# allowlisted path is allowed, and a positional parameter outside the operand domain is
# never refused. The deny mutant refuses both: NOEXEC-TERM-M3b the first, -M3d the second.
test_case "NOEXEC-TERM-ctl-allowlisted: zsh -s -O extglob -n <allowed> allowed (adjudicated, and the allowlist still governs)" \
  "$(bash_payload "zsh -s -O extglob -n $ARITY_ALLOWED")" 0
test_case "NOEXEC-TERM-ctl-word: zsh -s -O extglob -n allowed (the card's first measured line: no token lands in the operand domain)" \
  "$(bash_payload "echo 'echo ok' | zsh -s -O extglob -n")" 0

# (4) DECLARED OVER-BLOCK, pinned so it reads as intended. `bash -eo pipefail -n <script>`
# is inert under bash: the cluster's `o` takes `pipefail`, and the `-n` is a real flag.
# Only a bare `-o` is in the arity table, so the walk reads `pipefail` as a word and the
# option run ends there. The direction is the safe one, and it is the same trade the
# parse-only table already declares for a cluster. Each pin can fail: the revert mutant
# allows the first (NOEXEC-TERM-M1d), the consumed-argument revert mutant the second (-M4d).
test_case "NOEXEC-TERM-R1 (declared over-block): bash -eo pipefail -n <unlisted>.sh blocks (a cluster ending in an argument-taking letter)" \
  "$(bash_payload "bash -eo pipefail -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "NOEXEC-TERM-R2 (declared over-block): bash -o \"\$VAR\" -n <unlisted>.sh blocks (a quoted expansion is one word here, but the walk does not hold its text)" \
  "$(bash_payload "bash -o \"\$PMO_TERM_UNSET\" -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (4b) DECLARED LIMIT, pinned so it is a decision. zsh's `-b` ends option processing, as
# `--` does, and it has the shape of an option word, so the walk keeps reading and grants
# on the `-n` behind it. `+b` does the same, and corpus row ZG03 records it beside this
# arm's row ZT11. What zsh then runs is a file named `-n` — an operand the shell
# domain does not claim, the same limit `bash -- -n <script>.sh` has always had — and
# the script-suffixed path is that file's argument. Modelling `-b` would be a list of
# end-of-options spellings whose omissions fail open. The over-latch mutant refuses it
# (NOEXEC-TERM-M2i), which shows the pin can fail.
test_case "NOEXEC-TERM-P1 (pin, declared limit): zsh -b -n <unlisted>.sh allowed (an end-of-options letter the walk does not model)" \
  "$(bash_payload "zsh -b -n $PARSE_UNLISTED")" 0

# (5) STDIN MODE — the must-not-flag half the criterion names, and three pins of what
# the rule does with a program that arrives on stdin. The pins are not fix-evidence:
# they record today's verdicts so that a change to any of them is a decision. The
# stdin-deny mutant refuses each must-not-flag arm (STDIN-M1*), and the three mutants
# after it fail one pin each (STDIN-M2*, -M3*, -M4*).
test_case "STDIN-ctl-01: echo '<program>' | zsh -s allowed (legitimate stdin usage: nothing on argv to adjudicate)" \
  "$(bash_payload "echo 'echo ok' | zsh -s")" 0
test_case "STDIN-ctl-02: echo '<program>' | bash -s allowed" \
  "$(bash_payload "echo 'echo ok' | bash -s")" 0
test_case "STDIN-ctl-03: echo '<program>' | sh -s allowed" \
  "$(bash_payload "echo 'echo ok' | sh -s")" 0
test_case "STDIN-ctl-04: echo '<program>' | bash -s arg.txt allowed (a positional parameter outside the operand domain)" \
  "$(bash_payload "echo 'echo ok' | bash -s arg.txt")" 0
test_case "STDIN-PIN-01 (pin, not fix-evidence): echo '<program>' | bash -s <unlisted>.sh blocks (a script-suffixed positional is adjudicated: the stdin program can run it, and this hook cannot read stdin)" \
  "$(bash_payload "echo 'bash \"\$1\"' | bash -s $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "STDIN-PIN-02 (pin, not fix-evidence): bash -s < <unlisted>.sh blocks (a redirected file IS the program, and its path is on argv)" \
  "$(bash_payload "bash -s < $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "STDIN-PIN-03 (pin, declared limit): cat <unlisted>.sh | bash allowed (a program that arrives through a pipe has no argv path in the interpreter's segment)" \
  "$(bash_payload "cat $PARSE_UNLISTED | bash")" 0

# RED-BEFORE, AS AN ARM. This mutant removes the latch's one conjunct from the grant and
# nothing else, so it IS the pre-fix grant with the new functions left in the file. M1a
# proves the substitution matched exactly that line; M1b and M1c show the pre-fix ALLOW.
# M1d is not red-before evidence: it reads the declared over-block NOEXEC-TERM-R1, which
# the conjunct alone refuses, so it shows that pin can fail.
TERM_REVERT="$(dirname "$HOOK")/block-destructive.TERM-revert.sh"
/usr/bin/sed 's/\[ "\$script_optrun" -eq 1 \] && script_interp_noexec_flag/script_interp_noexec_flag/' "$HOOK" > "$TERM_REVERT"

if [ "$(/usr/bin/diff "$HOOK" "$TERM_REVERT" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: NOEXEC-TERM-M1a revert mutation is live (exactly the grant line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-TERM-M1a revert mutation did not change exactly one line — the M1 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "NOEXEC-TERM-M1b: the revert mutant ALLOWS zsh -s -O extglob -n <unlisted>.sh (the pre-fix verdict)" \
  "$TERM_REVERT" "$(bash_payload "zsh -s -O extglob -n $PARSE_UNLISTED")" 0
sandbox_case "NOEXEC-TERM-M1c: the revert mutant ALLOWS bash <wrapper> -n <unlisted>.sh" \
  "$TERM_REVERT" "$(bash_payload "bash $TERM_WRAP -n $PARSE_UNLISTED")" 0
sandbox_case "NOEXEC-TERM-M1d: the revert mutant ALLOWS bash -eo pipefail -n <unlisted>.sh (NOEXEC-TERM-R1's payload)" \
  "$TERM_REVERT" "$(bash_payload "bash -eo pipefail -n $PARSE_UNLISTED")" 0

/bin/rm -f "$TERM_REVERT"

# THE CONTROLS IN (2) CAN FAIL. This mutant ends the option run on EVERY token, which is
# what a latch with the wrong test would do. Nothing is granted, and each arm in (2) is
# refused. So is the declared limit in (4b): M2i reads NOEXEC-TERM-P1's payload.
TERM_OVER="$(dirname "$HOOK")/block-destructive.TERM-over.sh"
/usr/bin/sed 's/if ! script_option_word "\$script_fsub"; then script_optrun=0; fi   # M-OPTRUN/script_optrun=0   # M-OPTRUN/' "$HOOK" > "$TERM_OVER"

if [ "$(/usr/bin/diff "$HOOK" "$TERM_OVER" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: NOEXEC-TERM-M2a over-latch mutation is live (exactly the latch line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-TERM-M2a over-latch mutation did not change exactly one line — the M2 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "NOEXEC-TERM-M2b: the over-latch mutant REFUSES zsh -s -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "zsh -s -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2c: the over-latch mutant REFUSES bash -s -O extglob -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "bash -s -O extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2d: the over-latch mutant REFUSES zsh -o extendedglob -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "zsh -o extendedglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2e: the over-latch mutant REFUSES bash +x -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "bash +x -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2f: the over-latch mutant REFUSES bash '+x' -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "bash '+x' -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2g: the over-latch mutant REFUSES bash \"-x\" -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "bash \"-x\" -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2h: the over-latch mutant REFUSES bash --norc --noprofile -n <unlisted>.sh" \
  "$TERM_OVER" "$(bash_payload "bash --norc --noprofile -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M2i: the over-latch mutant REFUSES zsh -b -n <unlisted>.sh (NOEXEC-TERM-P1's payload)" \
  "$TERM_OVER" "$(bash_payload "zsh -b -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

/bin/rm -f "$TERM_OVER"

# THE CONSUMED-ARGUMENT TEST, BOTH WAYS. M4 deletes it: the pre-fix grant returns for
# the shape in (1c) and for nothing in (1a) or (1b). It returns for the declared
# over-block NOEXEC-TERM-R2 in (4) as well, which M4d reads, so that pin can fail. M5
# makes it end the run on EVERY consumed argument: the three controls whose `-n` follows
# a consumed argument are refused, which is what shows they can fail.
#
# M4 DELETES EVERY LINE THAT TESTS THE CONSUMED ARGUMENT, HOWEVER MANY THE HOOK CARRIES.
# script_adjudicate_optarg holds the latch's line always, and the conservative route's
# line beside it when that route is built. Either one alone keeps the shape in (1c)
# refused, so a mutant that removes only the first proves nothing on a hook that has
# both. The count of marker lines is read from the hook, and the liveness arm requires
# that exactly that many are gone and that there is at least one.
TERM_ARGREV="$(dirname "$HOOK")/block-destructive.TERM-argrev.sh"
TERM_ARG_MARKS="$(/usr/bin/grep -c -e '# M-OPTARG' -e '# M-OPAQUE-ARG' "$HOOK")"
/usr/bin/sed -e '/# M-OPTARG/d' -e '/# M-OPAQUE-ARG/d' "$HOOK" > "$TERM_ARGREV"

if [ "$TERM_ARG_MARKS" -ge 1 ] && [ "$(/usr/bin/diff "$HOOK" "$TERM_ARGREV" | /usr/bin/grep -c '^<')" = "$TERM_ARG_MARKS" ]; then
  /usr/bin/printf 'PASS: NOEXEC-TERM-M4a consumed-argument revert mutation is live (every line that tests the consumed argument is gone: %s)\n' "$TERM_ARG_MARKS"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-TERM-M4a consumed-argument revert mutation did not remove exactly the marked lines — the M4 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "NOEXEC-TERM-M4b: the consumed-argument revert mutant ALLOWS bash --rcfile \$VAR -n <unlisted>.sh (the pre-fix verdict)" \
  "$TERM_ARGREV" "$(bash_payload "bash --rcfile \$PMO_TERM_UNSET -n $PARSE_UNLISTED")" 0
sandbox_case "NOEXEC-TERM-M4c: the consumed-argument revert mutant STILL REFUSES zsh -s -O extglob -n <unlisted>.sh (the two lines hold different shapes)" \
  "$TERM_ARGREV" "$(bash_payload "zsh -s -O extglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M4d: the consumed-argument revert mutant ALLOWS bash -o \"\$VAR\" -n <unlisted>.sh (NOEXEC-TERM-R2's payload)" \
  "$TERM_ARGREV" "$(bash_payload "bash -o \"\$PMO_TERM_UNSET\" -n $PARSE_UNLISTED")" 0

/bin/rm -f "$TERM_ARGREV"

TERM_ARGOVER="$(dirname "$HOOK")/block-destructive.TERM-argover.sh"
/usr/bin/sed 's/if ! script_arg_exact; then script_optrun=0; fi   # M-OPTARG/script_optrun=0   # M-OPTARG/' "$HOOK" > "$TERM_ARGOVER"

if [ "$(/usr/bin/diff "$HOOK" "$TERM_ARGOVER" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: NOEXEC-TERM-M5a consumed-argument over-latch mutation is live (exactly one line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-TERM-M5a consumed-argument over-latch mutation did not change exactly one line — the M5 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "NOEXEC-TERM-M5b: the consumed-argument over-latch mutant REFUSES zsh -o extendedglob -n <unlisted>.sh" \
  "$TERM_ARGOVER" "$(bash_payload "zsh -o extendedglob -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M5c: the consumed-argument over-latch mutant REFUSES bash -o 'pipefail' -n <unlisted>.sh" \
  "$TERM_ARGOVER" "$(bash_payload "bash -o 'pipefail' -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
sandbox_case "NOEXEC-TERM-M5d: the consumed-argument over-latch mutant REFUSES bash --rcfile \"\" -n <unlisted>.sh" \
  "$TERM_ARGOVER" "$(bash_payload "bash --rcfile \"\" -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

/bin/rm -f "$TERM_ARGOVER"

# WHY THE WALK DOES NOT DENY WHERE THE OPTION RUN ENDS, pinned so the proposal is not
# re-made. Refusing at the first token that is not an option word closes every arm in
# (1) — and refuses an allowlisted script and an ordinary positional parameter. M3b to
# M3d are those refusals, each matched on the mutant's own reason text: M3b and M3d read
# the two controls in (3), and M3c reads STDIN-ctl-04.
TERM_DENY="$(dirname "$HOOK")/block-destructive.TERM-deny.sh"
/usr/bin/sed 's/if ! script_option_word "\$script_fsub"; then script_optrun=0; fi   # M-OPTRUN/if ! script_option_word "$script_fsub"; then block "BLOCK-DESTRUCTIVE-022" "TERM deny mutant" "test only"; fi   # M-OPTRUN/' "$HOOK" > "$TERM_DENY"

if [ "$(/usr/bin/diff "$HOOK" "$TERM_DENY" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: NOEXEC-TERM-M3a deny mutation is live (exactly the latch line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: NOEXEC-TERM-M3a deny mutation did not change exactly one line — the M3 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "NOEXEC-TERM-M3b: the deny mutant REFUSES zsh -s -O extglob -n <allowed>" \
  "$TERM_DENY" "$(bash_payload "zsh -s -O extglob -n $ARITY_ALLOWED")" 2 "TERM deny mutant"
sandbox_case "NOEXEC-TERM-M3c: the deny mutant REFUSES echo '<program>' | bash -s arg.txt" \
  "$TERM_DENY" "$(bash_payload "echo 'echo ok' | bash -s arg.txt")" 2 "TERM deny mutant"
sandbox_case "NOEXEC-TERM-M3d: the deny mutant REFUSES echo '<program>' | zsh -s -O extglob -n (NOEXEC-TERM-ctl-word's payload)" \
  "$TERM_DENY" "$(bash_payload "echo 'echo ok' | zsh -s -O extglob -n")" 2 "TERM deny mutant"

/bin/rm -f "$TERM_DENY"

# AND WHY A STDIN-FED SHELL IS NOT REFUSED OUTRIGHT, pinned for the same reason. This
# mutant refuses an interpreter segment whose walk finds no operand — the xargs rule
# applied to every shell that reads its program from stdin. It refuses the criterion's
# own must-not-flag case.
STDIN_DENY="$(dirname "$HOOK")/block-destructive.STDIN-deny.sh"
/usr/bin/sed 's/^\( *\)\[ "\$script_idx" -lt "\${#script_tokens\[@\]}" \] || continue$/\1[ "$script_idx" -lt "${#script_tokens[@]}" ] || block "BLOCK-DESTRUCTIVE-022" "STDIN deny mutant" "test only"/' "$HOOK" > "$STDIN_DENY"

if [ "$(/usr/bin/diff "$HOOK" "$STDIN_DENY" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: STDIN-M1a stdin-deny mutation is live (exactly one line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: STDIN-M1a stdin-deny mutation did not change exactly one line — the M1 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "STDIN-M1b: the stdin-deny mutant REFUSES echo '<program>' | zsh -s" \
  "$STDIN_DENY" "$(bash_payload "echo 'echo ok' | zsh -s")" 2 "STDIN deny mutant"
sandbox_case "STDIN-M1c: the stdin-deny mutant REFUSES echo '<program>' | bash -s" \
  "$STDIN_DENY" "$(bash_payload "echo 'echo ok' | bash -s")" 2 "STDIN deny mutant"
sandbox_case "STDIN-M1d: the stdin-deny mutant REFUSES echo '<program>' | sh -s" \
  "$STDIN_DENY" "$(bash_payload "echo 'echo ok' | sh -s")" 2 "STDIN deny mutant"
sandbox_case "STDIN-M1e: the stdin-deny mutant REFUSES echo '<program>' | bash -s arg.txt" \
  "$STDIN_DENY" "$(bash_payload "echo 'echo ok' | bash -s arg.txt")" 2 "STDIN deny mutant"

/bin/rm -f "$STDIN_DENY"

# THE THREE STDIN PINS CAN FAIL. Each mutant below removes what holds one pin's verdict,
# and its arm reads that pin's payload.
#
# STDIN-PIN-03's allow is held by the no-operand branch: an interpreter segment with
# nothing on argv after the verb leaves before the walk begins, with no operand to
# adjudicate. The stdin-deny mutant above cannot fail this pin, because it edits the
# check after the walk, which a bare `| bash` never reaches. This mutant refuses at that
# branch instead. Its sed range runs from the xargs deny's test inside the branch to the
# next `continue`, which is the branch's own, so no other `continue` in the hook matches.
STDIN_NOOP="$(dirname "$HOOK")/block-destructive.STDIN-noop.sh"
/usr/bin/sed '/if \[ "\$script_xargs" -eq 1 \]; then/,/^ *continue$/s/^\( *\)continue$/\1block "BLOCK-DESTRUCTIVE-022" "STDIN no-operand deny mutant" "test only"/' "$HOOK" > "$STDIN_NOOP"

if [ "$(/usr/bin/diff "$HOOK" "$STDIN_NOOP" | /usr/bin/grep -c '^<')" = "1" ] && /bin/bash -n "$STDIN_NOOP" 2>/dev/null; then
  /usr/bin/printf 'PASS: STDIN-M2a no-operand deny mutation is live (exactly one line differs, and the copy parses)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: STDIN-M2a no-operand deny mutation did not change exactly one line, or the copy does not parse — M2b is unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "STDIN-M2b: the no-operand deny mutant REFUSES cat <unlisted>.sh | bash (STDIN-PIN-03's payload)" \
  "$STDIN_NOOP" "$(bash_payload "cat $PARSE_UNLISTED | bash")" 2 "STDIN no-operand deny mutant"

/bin/rm -f "$STDIN_NOOP"

# STDIN-PIN-01's refusal is held by the walk adjudicating a script-suffixed word behind
# `-s` as it would anywhere. The mutant is the design's positional model, scope option P,
# which the Collective Review did not take: three edits that note a readable `-s` inside
# the option run and then skip the adjudication of a plain operand behind it, reading the
# word as a positional parameter. The stdin program runs that positional, and the mutant
# allows it.
STDIN_POS="$(dirname "$HOOK")/block-destructive.STDIN-positional.sh"
/usr/bin/sed \
  -e 's/^      script_optrun=1$/      script_optrun=1; script_stdin=0/' \
  -e 's/^\( *\)if ! script_option_word "\$script_fsub"; then script_optrun=0; fi   # M-OPTRUN/\1if ! script_option_word "$script_fsub"; then script_optrun=0; fi; case "$script_interp_base" in bash|sh|zsh) if [ "$script_optrun" -eq 1 ] \&\& [ "$script_fsub" = "-s" ]; then script_stdin=1; fi ;; esac   # M-OPTRUN/' \
  -e 's/^\( *\)if \[ "\$script_noexec" -eq 1 \] && \[ "\$script_cmode" -eq 0 \]; then$/\1if [ "$script_stdin" -eq 1 ] \&\& [ "$script_cmode" -eq 0 ] \&\& script_plain_word "${script_tokens[$script_idx]}"; then continue; fi; if [ "$script_noexec" -eq 1 ] \&\& [ "$script_cmode" -eq 0 ]; then/' \
  "$HOOK" > "$STDIN_POS"

if [ "$(/usr/bin/diff "$HOOK" "$STDIN_POS" | /usr/bin/grep -c '^<')" = "3" ] && /bin/bash -n "$STDIN_POS" 2>/dev/null; then
  /usr/bin/printf 'PASS: STDIN-M3a positional-model mutation is live (exactly the three edited lines differ, and the copy parses)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: STDIN-M3a positional-model mutation did not change exactly three lines, or the copy does not parse — M3b is unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "STDIN-M3b: the positional-model mutant ALLOWS echo '<program>' | bash -s <unlisted>.sh (STDIN-PIN-01's payload)" \
  "$STDIN_POS" "$(bash_payload "echo 'bash \"\$1\"' | bash -s $PARSE_UNLISTED")" 0

/bin/rm -f "$STDIN_POS"

# STDIN-PIN-02's refusal is held twice. The redirection operator is a token whose reading
# is not plain, so the conservative route takes it; and without the route the walk would
# advance past it to the file it names. So the mutant reverts both: the operand walk to
# its dash-anchored form (the AC-D022 reversion, the same two sed expressions) and the
# route's top-of-loop line. The walk then ends on `<` and adjudicates nothing.
STDIN_WALK="$(dirname "$HOOK")/block-destructive.STDIN-walk.sh"
/usr/bin/sed \
  -e '/# M-FWALK-BODY/,/^[[:space:]]*;;$/d' \
  -e 's|^\([[:space:]]*\)\*) # M-FWALK-ADVANCE.*|\1*) break ;;|' \
  -e '/# M-OPAQUE (mutation/d' \
  "$HOOK" > "$STDIN_WALK"
STDIN_WALK_GONE=$(( $(/usr/bin/wc -l < "$HOOK") - $(/usr/bin/wc -l < "$STDIN_WALK") ))
STDIN_WALK_MARKS="$(/usr/bin/grep -c -e 'M-FWALK' -e '# M-OPAQUE (mutation' "$STDIN_WALK")"

if [ "$STDIN_WALK_GONE" = 23 ] && [ "$STDIN_WALK_MARKS" = 0 ] && /bin/bash -n "$STDIN_WALK" 2>/dev/null; then
  /usr/bin/printf 'PASS: STDIN-M4a walk-and-route revert mutation is live (the 22 body lines and the route line are gone, no marker of either remains, and the copy parses)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: STDIN-M4a walk-and-route revert mutation removed %s lines (expected 23) with %s markers left (expected 0), or the copy does not parse — M4b is unusable\n' "$STDIN_WALK_GONE" "$STDIN_WALK_MARKS"
  FAIL=$((FAIL + 1))
fi

sandbox_case "STDIN-M4b: the walk-and-route revert mutant ALLOWS bash -s < <unlisted>.sh (STDIN-PIN-02's payload)" \
  "$STDIN_WALK" "$(bash_payload "bash -s < $PARSE_UNLISTED")" 0

/bin/rm -f "$STDIN_WALK"

echo ""
echo "BLOCK-022 flag walk: the command-string letter inside a cluster (FWALK-CLUSTER-*)"
echo "---"
# SUBJECT. The walk's `-c)` label is an exact match, and the shells read one-letter
# options as a cluster. `bash -ec '<program>'` is `bash -e -c '<program>'`: the next
# argument is a program string and it executes. The label never saw the cluster, so it
# was stepped over as a flag, the first piece of the program string became the operand,
# and no word of the string was adjudicated — while the same program behind a bare `-c`
# was. Every arm in (1) is an ALLOW on the hook as it stood before this change AND at
# the commit that predates the parse-only exemption: this class is inherited, not
# introduced. The revert mutant FWALK-CLUSTER-M1* reproduces the ALLOW in this run.

# (1) MUST REFUSE.
test_case "FWALK-CLUSTER-01: bash -ec 'bash <unlisted>.sh' blocks (a cluster carrying c opens a program string)" \
  "$(bash_payload "bash -ec 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-02: bash -xc 'bash <unlisted>.sh' blocks" \
  "$(bash_payload "bash -xc 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-03: sh -ec \"sh <unlisted>.sh\" blocks (second shell, double quotes)" \
  "$(bash_payload "sh -ec \"sh $PARSE_UNLISTED\"")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-04: zsh -fc 'zsh <unlisted>.sh' blocks (third shell)" \
  "$(bash_payload "zsh -fc 'zsh $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-05: bash -ce 'bash <unlisted>.sh' blocks (the letter leads the cluster)" \
  "$(bash_payload "bash -ce 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-06: bash +ec 'bash <unlisted>.sh' blocks (bash takes the letter in a plus-form cluster too)" \
  "$(bash_payload "bash +ec 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-07: bash \"-ec\" 'bash <unlisted>.sh' blocks (a quoted cluster is still that cluster)" \
  "$(bash_payload "bash \"-ec\" 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-08: bash -o pipefail -ec 'bash <unlisted>.sh' blocks (behind an option and its consumed argument)" \
  "$(bash_payload "bash -o pipefail -ec 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-09: bash -c\"\" 'bash <unlisted>.sh' blocks (an empty quoted string behind the letter: the token is not the label's exact text)" \
  "$(bash_payload "bash -c\"\" 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-10: bash -\"c\" 'bash <unlisted>.sh' blocks (the letter inside quotes)" \
  "$(bash_payload "bash -\"c\" 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"

# (2) MUST STAY ALLOWED. The cluster takes the route a bare `-c` takes: it adjudicates
# what lands in the operand domain and refuses nothing else. The deny mutant
# FWALK-CLUSTER-M2* refuses the first two; the widened-pattern mutant FWALK-CLUSTER-M3*
# refuses the third.
test_case "FWALK-CLUSTER-ctl-fp: bash -ec 'echo a b' allowed (an ordinary program string)" \
  "$(bash_payload "bash -ec 'echo a b'")" 0
test_case "FWALK-CLUSTER-ctl-allow: bash -ec 'bash <allowed>' allowed (the allowlist still governs)" \
  "$(bash_payload "bash -ec 'bash $ARITY_ALLOWED'")" 0
test_case "FWALK-CLUSTER-ctl-long: bash --rcfile /dev/null -n <unlisted>.sh allowed (a long option containing c is not a cluster)" \
  "$(bash_payload "bash --rcfile /dev/null -n $PARSE_UNLISTED")" 0

# (3) PINS. A token a view already places in the operand domain is not re-read as a
# cluster: `'+c.sh'` is the word +c.sh, which the shell domain claims, and it blocks
# before and after. And the route's known cost: a script-suffixed word that the program
# string only READS is refused, exactly as it is behind a bare `-c`. Each pin can fail:
# the guardless-route mutant allows the first (FWALK-OPAQUE-M5c, built with the route's
# other mutants below), and the revert mutant the second (FWALK-CLUSTER-M1d).
test_case "FWALK-CLUSTER-ctl-claimed (pin, not fix-evidence): bash '+c.sh' still blocks (a domain claim outranks the cluster reading)" \
  "$(bash_payload "bash '+c.sh'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-CLUSTER-R1 (declared over-block): bash -ec 'cat <unlisted>.sh' blocks (twin of the bare -c reading of the same string)" \
  "$(bash_payload "bash -ec 'cat $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"

# RED-BEFORE, AS AN ARM. Deleting the one line that hands a cluster to the label
# restores the pre-fix walk for this class. M1d is not red-before evidence: it reads the
# declared over-block FWALK-CLUSTER-R1, which the same line refuses, so that pin can fail.
# The operand join is deleted with it: once the cluster is stepped over as a flag, the
# program string's first piece ends the walk as the operand, and since #8318 the operand
# path joins that piece to the rest of the string and refuses the joined word when it
# ends in the domain's suffix — a second hold, which would hide the line under test.
CLUSTER_REVERT="$(dirname "$HOOK")/block-destructive.CLUSTER-revert.sh"
/usr/bin/sed -e '/# M-CLUSTER/d' -e '/# M-OPND-JOIN (mutation/d' "$HOOK" > "$CLUSTER_REVERT"

if [ "$(/usr/bin/diff "$HOOK" "$CLUSTER_REVERT" | /usr/bin/grep -c '^<')" = "2" ]; then
  /usr/bin/printf 'PASS: FWALK-CLUSTER-M1a revert mutation is live (exactly two lines are gone: the cluster line and the operand join)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-CLUSTER-M1a revert mutation did not remove exactly the cluster line and the operand join — the M1 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-CLUSTER-M1b: the revert mutant ALLOWS bash -ec 'bash <unlisted>.sh' (the pre-fix verdict)" \
  "$CLUSTER_REVERT" "$(bash_payload "bash -ec 'bash $PARSE_UNLISTED'")" 0
sandbox_case "FWALK-CLUSTER-M1c: the revert mutant ALLOWS zsh -fc 'zsh <unlisted>.sh'" \
  "$CLUSTER_REVERT" "$(bash_payload "zsh -fc 'zsh $PARSE_UNLISTED'")" 0
sandbox_case "FWALK-CLUSTER-M1d: the revert mutant ALLOWS bash -ec 'cat <unlisted>.sh' (FWALK-CLUSTER-R1's payload)" \
  "$CLUSTER_REVERT" "$(bash_payload "bash -ec 'cat $PARSE_UNLISTED'")" 0

/bin/rm -f "$CLUSTER_REVERT"

# THE CONTROLS CAN FAIL. A deny in place of the route refuses an ordinary program
# string and an allowlisted one.
CLUSTER_DENY="$(dirname "$HOOK")/block-destructive.CLUSTER-deny.sh"
/usr/bin/sed 's/then script_take_cmode_route; fi   # M-CLUSTER/then block "BLOCK-DESTRUCTIVE-022" "CLUSTER deny mutant" "test only"; fi   # M-CLUSTER/' "$HOOK" > "$CLUSTER_DENY"

if [ "$(/usr/bin/diff "$HOOK" "$CLUSTER_DENY" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-CLUSTER-M2a deny mutation is live (exactly one line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-CLUSTER-M2a deny mutation did not change exactly one line — the M2 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-CLUSTER-M2b: the deny mutant REFUSES bash -ec 'echo a b'" \
  "$CLUSTER_DENY" "$(bash_payload "bash -ec 'echo a b'")" 2 "CLUSTER deny mutant"
sandbox_case "FWALK-CLUSTER-M2c: the deny mutant REFUSES bash -ec 'bash <allowed>'" \
  "$CLUSTER_DENY" "$(bash_payload "bash -ec 'bash $ARITY_ALLOWED'")" 2 "CLUSTER deny mutant"

/bin/rm -f "$CLUSTER_DENY"

# AND THE SECOND-CHARACTER EXCLUSION IS LOAD-BEARING. A table that claims any token
# containing the letter claims `--rcfile` as well, takes the route, and loses the
# parse-only exemption a real `-n` behind it had earned.
CLUSTER_WIDE="$(dirname "$HOOK")/block-destructive.CLUSTER-wide.sh"
/usr/bin/sed 's/case "\$2" in -c\*|-\[!-\]\*c\*|+c\*|+\[!-\]\*c\*) return 0 ;; esac/case "$2" in -*c*|+*c*) return 0 ;; esac/' "$HOOK" > "$CLUSTER_WIDE"

if [ "$(/usr/bin/diff "$HOOK" "$CLUSTER_WIDE" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-CLUSTER-M3a widened-pattern mutation is live (exactly one line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-CLUSTER-M3a widened-pattern mutation did not change exactly one line — M3b is unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-CLUSTER-M3b: the widened-pattern mutant REFUSES bash --rcfile /dev/null -n <unlisted>.sh" \
  "$CLUSTER_WIDE" "$(bash_payload "bash --rcfile /dev/null -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

/bin/rm -f "$CLUSTER_WIDE"

echo ""
echo "BLOCK-022 flag walk: an option the walk cannot read takes the conservative route (FWALK-OPAQUE-*)"
echo "---"
# SUBJECT. A token carrying a character outside the plain set has a value this hook
# does not hold. Stepping over it is a guess that it consumes nothing. When the guess is
# wrong, an allowlisted script sitting in its argument slot is adjudicated as the operand
# and the script the shell actually runs is never read. The same top-of-loop line also
# routes a QUOTED word of unknown value, which the quoted-word view reports by its raw
# spelling (the FWALK-QWORD arms pin that); these arms pin the spellings that view is
# never asked about — unquoted, and beginning with `-` on raw argv. Every arm in (1) is
# an ALLOW on the hook as it stood before this change AND at the commit that predates
# the parse-only exemption: inherited, not introduced.
# PMO_OPAQUE_UNSET is never set and never expanded here.

# (1) MUST REFUSE.
test_case "FWALK-OPAQUE-01: bash \$VAR--rcfile <allowed> <unlisted>.sh blocks (an unquoted expansion ahead of the option)" \
  "$(bash_payload "bash \$PMO_OPAQUE_UNSET--rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-02: bash --rcfile\"\" <allowed> <unlisted>.sh blocks (an empty quoted string inside the option)" \
  "$(bash_payload "bash --rcfile\"\" $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-03: bash --rcfile\$VAR <allowed> <unlisted>.sh blocks (an expansion behind the option)" \
  "$(bash_payload "bash --rcfile\$PMO_OPAQUE_UNSET $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-04: bash \"--rcfile\$VAR\" <allowed> <unlisted>.sh blocks (fully quoted, an expansion inside)" \
  "$(bash_payload "bash \"--rcfile\$PMO_OPAQUE_UNSET\" $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-05: bash -e\$VAR 'bash <unlisted>.sh' blocks (a cluster whose letters are not on argv)" \
  "$(bash_payload "bash -e\$PMO_OPAQUE_UNSET 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-06: bash <<< 'bash <unlisted>.sh' blocks (a here-string program is read as a program string)" \
  "$(bash_payload "bash <<< 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-07: bash \\--rcfile <allowed> <unlisted>.sh blocks (a backslash AHEAD of the option: the token begins with neither sign nor quote)" \
  "$(bash_payload "bash \\--rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-08: bash \\-c 'bash <unlisted>.sh' blocks (the command-string letter behind a backslash)" \
  "$(bash_payload "bash \\-c 'bash $PARSE_UNLISTED'")" 2 "BLOCK-DESTRUCTIVE-022"
# The brace word reaches the payload through a variable, never as literal text inside
# "$( … "…" )": bash 3.2 brace-expands there, and one arm silently becomes two payloads.
OPAQUE_BRACE='--{norc,rcfile}'
test_case "FWALK-OPAQUE-09: bash --{norc,rcfile} <allowed> <unlisted>.sh blocks (a brace word is two options to the shell)" \
  "$(bash_payload "bash $OPAQUE_BRACE $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-OPAQUE-10: bash --rcfile \$VAR <allowed> <unlisted>.sh blocks (the option's argument may be no word at all, and the allowlisted script takes its place)" \
  "$(bash_payload "bash --rcfile \$PMO_OPAQUE_UNSET $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# (2) MUST STAY ALLOWED. The route adjudicates; it does not deny. The deny mutant
# FWALK-OPAQUE-M2* refuses each of these.
test_case "FWALK-OPAQUE-ctl-allow: bash \$VAR-x <allowed> allowed (the allowlist still governs)" \
  "$(bash_payload "bash \$PMO_OPAQUE_UNSET-x $ARITY_ALLOWED")" 0
test_case "FWALK-OPAQUE-ctl-allow-q: bash --rcfile\"\" <allowed> allowed" \
  "$(bash_payload "bash --rcfile\"\" $ARITY_ALLOWED")" 0
test_case "FWALK-OPAQUE-ctl-redirect: bash < <allowed> allowed (a redirection is not an option word; the file it names is adjudicated and is allowlisted)" \
  "$(bash_payload "bash < $ARITY_ALLOWED")" 0
test_case "FWALK-OPAQUE-ctl-extless: bash \"\$VAR\" allowed (an unreadable word with nothing behind it: nothing lands in the operand domain)" \
  "$(bash_payload "bash \"\$PMO_OPAQUE_UNSET\"")" 0
test_case "FWALK-OPAQUE-ctl-bslash: bash \\-x <allowed> allowed (a backslash-led option in front of an allowlisted script)" \
  "$(bash_payload "bash \\-x $ARITY_ALLOWED")" 0
test_case "FWALK-OPAQUE-ctl-arg: bash --rcfile \$VAR <allowed> allowed (an unreadable option argument in front of an allowlisted script)" \
  "$(bash_payload "bash --rcfile \$PMO_OPAQUE_UNSET $ARITY_ALLOWED")" 0

# (3) PINS. A token a view places in the operand domain is the operand and is not
# routed; and the route's known cost, the same over-block the quoted spelling of the
# same word already carries. Each pin can fail: the guardless-route mutant allows the
# first (FWALK-OPAQUE-M5b), and the revert mutant the second (FWALK-OPAQUE-M1d).
test_case "FWALK-OPAQUE-ctl-claimed (pin, not fix-evidence): bash \$VAR/x.sh still blocks as variable-bearing (a domain claim outranks the route)" \
  "$(bash_payload "bash \$PMO_OPAQUE_UNSET/x.sh")" 2 "variable-bearing"
test_case "FWALK-OPAQUE-R1 (declared over-block): bash \$VAR-x <allowed> <unlisted>.sh blocks (the shell runs only the allowlisted script; the unread option might have taken it as its argument)" \
  "$(bash_payload "bash \$PMO_OPAQUE_UNSET-x $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# RED-BEFORE, AS AN ARM. M1d and M1e are not red-before evidence: they read the declared
# over-block FWALK-OPAQUE-R1 and the integration pin FWALK-INT-02, which the route's line
# refuses, so each pin can fail.
OPAQUE_REVERT="$(dirname "$HOOK")/block-destructive.OPAQUE-revert.sh"
/usr/bin/sed '/# M-OPAQUE (mutation/d' "$HOOK" > "$OPAQUE_REVERT"

if [ "$(/usr/bin/diff "$HOOK" "$OPAQUE_REVERT" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-OPAQUE-M1a revert mutation is live (exactly one line is gone)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-OPAQUE-M1a revert mutation did not remove exactly one line — the M1 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-OPAQUE-M1b: the revert mutant ALLOWS bash \$VAR--rcfile <allowed> <unlisted>.sh (the pre-fix verdict)" \
  "$OPAQUE_REVERT" "$(bash_payload "bash \$PMO_OPAQUE_UNSET--rcfile $ARITY_ALLOWED $PARSE_UNLISTED")" 0
sandbox_case "FWALK-OPAQUE-M1c: the revert mutant ALLOWS bash --rcfile\"\" <allowed> <unlisted>.sh" \
  "$OPAQUE_REVERT" "$(bash_payload "bash --rcfile\"\" $ARITY_ALLOWED $PARSE_UNLISTED")" 0
sandbox_case "FWALK-OPAQUE-M1d: the revert mutant ALLOWS bash \$VAR-x <allowed> <unlisted>.sh (FWALK-OPAQUE-R1's payload)" \
  "$OPAQUE_REVERT" "$(bash_payload "bash \$PMO_OPAQUE_UNSET-x $ARITY_ALLOWED $PARSE_UNLISTED")" 0
sandbox_case "FWALK-OPAQUE-M1e: the revert mutant ALLOWS bash \"\"--{norc,rcfile} <allowed> <unlisted>.sh (FWALK-INT-02's payload)" \
  "$OPAQUE_REVERT" "$(bash_payload "bash \"\"$OPAQUE_BRACE $ARITY_ALLOWED $PARSE_UNLISTED")" 0

/bin/rm -f "$OPAQUE_REVERT"

# THE CONTROLS CAN FAIL. A deny in place of the route refuses every arm in (2), and M2g
# refuses the integration control FWALK-INT-ctl-01, whose word the route also takes.
OPAQUE_DENY="$(dirname "$HOOK")/block-destructive.OPAQUE-deny.sh"
/usr/bin/sed 's/then script_take_cmode_route; fi   # M-OPAQUE/then block "BLOCK-DESTRUCTIVE-022" "OPAQUE deny mutant" "test only"; fi   # M-OPAQUE/' "$HOOK" > "$OPAQUE_DENY"

if [ "$(/usr/bin/diff "$HOOK" "$OPAQUE_DENY" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-OPAQUE-M2a deny mutation is live (exactly one line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-OPAQUE-M2a deny mutation did not change exactly one line — the M2 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-OPAQUE-M2b: the deny mutant REFUSES bash \$VAR-x <allowed>" \
  "$OPAQUE_DENY" "$(bash_payload "bash \$PMO_OPAQUE_UNSET-x $ARITY_ALLOWED")" 2 "OPAQUE deny mutant"
sandbox_case "FWALK-OPAQUE-M2c: the deny mutant REFUSES bash --rcfile\"\" <allowed>" \
  "$OPAQUE_DENY" "$(bash_payload "bash --rcfile\"\" $ARITY_ALLOWED")" 2 "OPAQUE deny mutant"
sandbox_case "FWALK-OPAQUE-M2d: the deny mutant REFUSES bash < <allowed>" \
  "$OPAQUE_DENY" "$(bash_payload "bash < $ARITY_ALLOWED")" 2 "OPAQUE deny mutant"
sandbox_case "FWALK-OPAQUE-M2e: the deny mutant REFUSES bash \"\$VAR\"" \
  "$OPAQUE_DENY" "$(bash_payload "bash \"\$PMO_OPAQUE_UNSET\"")" 2 "OPAQUE deny mutant"
sandbox_case "FWALK-OPAQUE-M2f: the deny mutant REFUSES bash \\-x <allowed>" \
  "$OPAQUE_DENY" "$(bash_payload "bash \\-x $ARITY_ALLOWED")" 2 "OPAQUE deny mutant"
sandbox_case "FWALK-OPAQUE-M2g: the deny mutant REFUSES bash \"\"--{norc,rcfile} <allowed> (FWALK-INT-ctl-01's payload)" \
  "$OPAQUE_DENY" "$(bash_payload "bash \"\"$OPAQUE_BRACE $ARITY_ALLOWED")" 2 "OPAQUE deny mutant"

/bin/rm -f "$OPAQUE_DENY"

# THE CONSUMED-ARGUMENT LINE, BOTH WAYS. M3 deletes it and the pre-fix ALLOW returns
# for arm 10 alone. M4 turns it into a refusal, and the control in (2) whose option
# argument is unreadable is refused.
OPAQUE_ARGREV="$(dirname "$HOOK")/block-destructive.OPAQUE-argrev.sh"
/usr/bin/sed '/# M-OPAQUE-ARG/d' "$HOOK" > "$OPAQUE_ARGREV"

if [ "$(/usr/bin/diff "$HOOK" "$OPAQUE_ARGREV" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-OPAQUE-M3a consumed-argument revert mutation is live (exactly one line is gone)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-OPAQUE-M3a consumed-argument revert mutation did not remove exactly one line — the M3 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-OPAQUE-M3b: the consumed-argument revert mutant ALLOWS bash --rcfile \$VAR <allowed> <unlisted>.sh (the pre-fix verdict)" \
  "$OPAQUE_ARGREV" "$(bash_payload "bash --rcfile \$PMO_OPAQUE_UNSET $ARITY_ALLOWED $PARSE_UNLISTED")" 0

/bin/rm -f "$OPAQUE_ARGREV"

OPAQUE_ARGDENY="$(dirname "$HOOK")/block-destructive.OPAQUE-argdeny.sh"
/usr/bin/sed 's/if ! script_arg_exact; then script_cmode=1; fi   # M-OPAQUE-ARG/if ! script_arg_exact; then block "BLOCK-DESTRUCTIVE-022" "OPAQUE-ARG deny mutant" "test only"; fi   # M-OPAQUE-ARG/' "$HOOK" > "$OPAQUE_ARGDENY"

if [ "$(/usr/bin/diff "$HOOK" "$OPAQUE_ARGDENY" | /usr/bin/grep -c '^<')" = "1" ]; then
  /usr/bin/printf 'PASS: FWALK-OPAQUE-M4a consumed-argument deny mutation is live (exactly one line differs)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-OPAQUE-M4a consumed-argument deny mutation did not change exactly one line — M4b is unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-OPAQUE-M4b: the consumed-argument deny mutant REFUSES bash --rcfile \$VAR <allowed>" \
  "$OPAQUE_ARGDENY" "$(bash_payload "bash --rcfile \$PMO_OPAQUE_UNSET $ARITY_ALLOWED")" 2 "OPAQUE-ARG deny mutant"

/bin/rm -f "$OPAQUE_ARGDENY"

# THE DOMAIN-CLAIM GUARD IS WHAT HOLDS BOTH ctl-claimed PINS. script_take_cmode_route
# leaves a token alone when a view places it in the operand domain; this mutant routes
# every token it is handed. Two lines hand it a claimed token: this block's top-of-loop
# line hands it `$VAR/x.sh`, and the cluster table hands it `'+c.sh'`. Routed, each is
# read as the `-c` label, the walk ends on it, and nothing is adjudicated. M5b reads
# FWALK-OPAQUE-ctl-claimed's payload and M5c reads FWALK-CLUSTER-ctl-claimed's, so both
# pins are shown able to fail.
ROUTE_NOGUARD="$(dirname "$HOOK")/block-destructive.ROUTE-noguard.sh"
/usr/bin/sed 's/^\( *\)\*) if ! script_operand_implicated "\$script_interp_domain"; then script_ftok="-c"; fi ;;$/\1*) script_ftok="-c" ;;/' "$HOOK" > "$ROUTE_NOGUARD"

if [ "$(/usr/bin/diff "$HOOK" "$ROUTE_NOGUARD" | /usr/bin/grep -c '^<')" = "1" ] && /bin/bash -n "$ROUTE_NOGUARD" 2>/dev/null; then
  /usr/bin/printf 'PASS: FWALK-OPAQUE-M5a guardless-route mutation is live (exactly the guarded line of the route differs, and the copy parses)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-OPAQUE-M5a guardless-route mutation did not change exactly one line, or the copy does not parse — the M5 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-OPAQUE-M5b: the guardless-route mutant ALLOWS bash \$VAR/x.sh (FWALK-OPAQUE-ctl-claimed's payload)" \
  "$ROUTE_NOGUARD" "$(bash_payload "bash \$PMO_OPAQUE_UNSET/x.sh")" 0
sandbox_case "FWALK-OPAQUE-M5c: the guardless-route mutant ALLOWS bash '+c.sh' (FWALK-CLUSTER-ctl-claimed's payload)" \
  "$ROUTE_NOGUARD" "$(bash_payload "bash '+c.sh'")" 0

/bin/rm -f "$ROUTE_NOGUARD"

echo ""
echo "BLOCK-022 flag walk: this change read through the quoted-word view (FWALK-INT-*)"
echo "---"
# SUBJECT. These arms hold only on a hook that already reads a whole quoted word as its
# value. Each token below opens with a quote that closes early, so the walk that predates
# that reading ends on it and none of this change is reached. They are the integration
# evidence between the two changes: the quoted-word view produces a reading, and the
# latch and the conservative route are asked about that reading — not about how the
# token is spelled. PMO_INT_UNSET is never set and never expanded here.
#
# THEY ARE PINS ON THIS BRANCH, NOT RED-BEFORE EVIDENCE. The quoted-word view landed
# with a scanner arm that reports an unquoted brace, glob or tilde character as a word
# of unknown value, so on the hook as it stood before this change each must-refuse word
# below was already routed and already refused (corpus rows RB01, RB05, RB07). What
# these arms measure is that the refusal survives the route moving out of the view and
# into the top of the walk's loop, and that the latch reads the view's reading.
#
# EACH IS SHOWN ABLE TO FAIL. FWALK-INT-02 by the route's revert mutant
# (FWALK-OPAQUE-M1e) and FWALK-INT-ctl-01 by its deny mutant (FWALK-OPAQUE-M2g), both
# built in the block above; FWALK-INT-ctl-02 carries NOEXEC-TERM-ctl-qflag's payload,
# which the over-latch mutant refuses (NOEXEC-TERM-M2g); FWALK-INT-01 and -03 by the
# mutant at the end of this block.
#
# The brace word reaches the payload through a variable, never as literal text inside
# "$( … "…" )": bash 3.2 brace-expands there, and one arm silently becomes two payloads.
INT_BRACE='""--{norc,rcfile}'

# (1) Needs the quoted-word view and the option-run latch.
test_case "FWALK-INT-01: bash \"\"--{norc,rcfile} -n <unlisted>.sh blocks (the view reads the word; its value is not plain, so the -n behind it is no grant)" \
  "$(bash_payload "bash $INT_BRACE -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-INT-03: zsh \"\$VAR\"--emulate -n <unlisted>.sh blocks (a quoted expansion glued to the option: whichever way the view reads a word of unknown value, the -n is no grant)" \
  "$(bash_payload "zsh \"\$PMO_INT_UNSET\"--emulate -n $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"
test_case "FWALK-INT-ctl-02: bash \"-x\" -n <unlisted>.sh allowed (a quoted option with a plain value is still an option word)" \
  "$(bash_payload "bash \"-x\" -n $PARSE_UNLISTED")" 0
test_case "FWALK-INT-ctl-01: bash \"\"--{norc,rcfile} <allowed> allowed (nothing unlisted is on the line, with or without the conservative route)" \
  "$(bash_payload "bash $INT_BRACE $ARITY_ALLOWED")" 0

# (2) Needs the quoted-word view and the conservative route. This arm is added only
# when that route is built; it follows the arms above and reads their INT_BRACE.
test_case "FWALK-INT-02: bash \"\"--{norc,rcfile} <allowed> <unlisted>.sh blocks (the same word in front of an allowlisted script takes the conservative route)" \
  "$(bash_payload "bash $INT_BRACE $ARITY_ALLOWED $PARSE_UNLISTED")" 2 "BLOCK-DESTRUCTIVE-022"

# THE TWO MECHANISMS THAT HOLD FWALK-INT-01 AND -03 ARE INDEPENDENT. Each word reads,
# through the view, as a value that is not plain, so the route takes it and the latch
# ends the option run on it; either alone refuses the script behind the `-n`. The mutant
# removes both — the route's top-of-loop line and the latch's conjunct on the grant — and
# the grant then fires on the `-n`.
INT_REVERT="$(dirname "$HOOK")/block-destructive.INT-revert.sh"
/usr/bin/sed \
  -e '/# M-OPAQUE (mutation/d' \
  -e 's/\[ "\$script_optrun" -eq 1 \] && script_interp_noexec_flag/script_interp_noexec_flag/' \
  "$HOOK" > "$INT_REVERT"

if [ "$(/usr/bin/diff "$HOOK" "$INT_REVERT" | /usr/bin/grep -c '^<')" = "2" ] && /bin/bash -n "$INT_REVERT" 2>/dev/null; then
  /usr/bin/printf 'PASS: FWALK-INT-M1a route-and-latch revert mutation is live (exactly the route line and the grant line differ, and the copy parses)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-INT-M1a route-and-latch revert mutation did not change exactly two lines, or the copy does not parse — the M1 arms below are unusable\n'
  FAIL=$((FAIL + 1))
fi

sandbox_case "FWALK-INT-M1b: the route-and-latch revert mutant ALLOWS bash \"\"--{norc,rcfile} -n <unlisted>.sh (FWALK-INT-01's payload)" \
  "$INT_REVERT" "$(bash_payload "bash $INT_BRACE -n $PARSE_UNLISTED")" 0
sandbox_case "FWALK-INT-M1c: the route-and-latch revert mutant ALLOWS zsh \"\$VAR\"--emulate -n <unlisted>.sh (FWALK-INT-03's payload)" \
  "$INT_REVERT" "$(bash_payload "zsh \"\$PMO_INT_UNSET\"--emulate -n $PARSE_UNLISTED")" 0

/bin/rm -f "$INT_REVERT"

echo ""
echo "BLOCK-022 wrapper walk: each wrapper's own options, and the lists of the vocabulary (WRAP*)"
echo "---"
# SUBJECT. A transparent wrapper execs the rest of its argv after its OWN options, and the
# walk used to stop on the first of them: `nice -n 10 bash <unlisted>.sh` read `-n` as the
# command word and adjudicated nothing. The walk now reads each wrapper's option grammar from
# a row (script_wrapper_row), `nice`, `stdbuf` and `timeout` are walked with the other words,
# and `if`, `while` and `until` join the keyword arm. These arms grade that, the build
# conditions the scope was locked under, and the other lists of the same vocabulary.
#
# HERMETIC, ON THE F2 BLOCK'S PATTERN AND FOR ITS REASON: this block's own root, a one-entry
# allowlist, its own .mode, the scope variables unset for every run, and a reverse mutant
# beside the hook copy, so every verdict below turns on this fixture and nothing ambient. A
# verdict is read as the corpus reader reads one: exit 2 is B, exit 0 with a new would-fire
# row in this fixture's drain is W, exit 0 with none is a.
#
# THE REVERSE MUTANT is the hook with its marked lines reverted by sed and nothing else: the
# three new words leave the M-WRAP-WORDS line, the three new keywords leave the
# M-WRAP-KEYWORDS line, and the M-WRAP-OPTIONS call is deleted. The walk then behaves as it
# did before this change, which is what lets a pair arm's mutant limb stand as red-before
# evidence. WRAPOPT-M0 pins the mutant's exact difference, so a drifted marker turns red
# instead of leaving every pair green for the wrong reason.
#
# ARM CLASSES, so the red-before obligation can be read off the label. A WRAPOPT- or WRAPKW-
# arm whose hook limb and mutant limb differ is red before this change. A WRAPDIV- arm is a
# pin — a declared divergence, residual or over-block — and is green before by design unless
# its own label says the change introduced it. A -ctl- arm is a must-not-flag control,
# allowed on both limbs. A WRAPPAIR- arm follows each control and pin and shows it able to
# fail: it runs that arm's own command through a mutant built for the purpose and expects a
# verdict the arm forbids (the pairing mutants, further down).
#
# NO PIPE INTO A SHORT-CIRCUITING READER ANYWHERE IN THIS BLOCK (the SIGPIPE-idiom gate):
# extraction is one awk pass per file using index(), and stderr is matched from a
# here-string, as f2_case does.
WRAP_ROOT="$(/usr/bin/mktemp -d)"
WRAP_CLAUDE="${WRAP_ROOT}/.claude"
WRAP_HOOKS="${WRAP_CLAUDE}/hooks"
/bin/mkdir -p "${WRAP_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${WRAP_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${WRAP_HOOKS}/lib/" 2>/dev/null || true
/usr/bin/printf '/tmp/pmo-wrap-allowed.sh\n' > "${WRAP_CLAUDE}/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${WRAP_HOOKS}/.mode"
/bin/cp "$HOOK" "${WRAP_HOOKS}/block-destructive.sh"
/usr/bin/sed \
  -e '/# M-WRAP-WORDS/s/|nice|stdbuf|timeout)/)/' \
  -e '/# M-WRAP-KEYWORDS/s/|if|while|until|/|/' \
  -e '/# M-WRAP-OPTIONS/d' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-mut.sh"
# THE ITERATION'S REVERSE MUTANT, for Stage 7's finding F-01 on this card: the hook with its
# two M-WRAP-ABBREV lines reverted and nothing else. The line that resolves a long option is
# deleted, so a long token is matched as written, and time's row takes back the spelling its
# manual prints. That is the walk as it stood before a long option was read the way its
# program's parser reads it; WRAPOPT-AB-M0 pins the difference.
/usr/bin/sed \
  -e '/# M-WRAP-ABBREV$/d' \
  -e '/# M-WRAP-ABBREV-ROW/s/ --format --output-file / --format --output /' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-ab.sh"
/bin/chmod +x "${WRAP_HOOKS}/block-destructive.sh" "${WRAP_HOOKS}/block-destructive-mut.sh" \
  "${WRAP_HOOKS}/block-destructive-ab.sh"
WRAP_DRAIN="${WRAP_HOOKS}/destructive-warn-log.jsonl"
WRAP_NA='/tmp/pmo-wrap-na.sh'
WRAP_OK='/tmp/pmo-wrap-allowed.sh'

wrap_drain_rows() {
  if [ -f "$WRAP_DRAIN" ]; then
    /usr/bin/wc -l < "$WRAP_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

WRAP_EXIT=0
WRAP_ERR=""
WRAP_V=""
WRAP_LAST=""
# The copy a pair arm's second limb runs: the reverse mutant above, unless a block below says
# otherwise. The block that grades Stage 7's finding F-01 on this card sets the iteration's
# own reverse mutant and puts this one back after its last arm.
WRAP_MUTANT="block-destructive-mut.sh"
# The command and the hook verdict of the last arm wrap_arm graded, which a pairing arm reads
# so that it runs that arm's command byte for byte rather than a retyped copy of it.
WRAP_ARMCMD=""
WRAP_ARMWANT=""
# Run one payload through one of the sandbox copies -> WRAP_V (a|B|W|E<rc>), WRAP_ERR, and
# WRAP_LAST, the would-fire row the call added (empty when it added none).
wrap_run() { # $1 = hook file in the hermetic hooks dir  $2 = command
  local tmp before after
  tmp="$(/usr/bin/mktemp)"
  WRAP_EXIT=0
  WRAP_LAST=""
  before="$(wrap_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$WRAP_ROOT")" \
      | /bin/bash "${WRAP_HOOKS}/$1" 2>"$tmp" >/dev/null ) || WRAP_EXIT="$?"
  after="$(wrap_drain_rows)"
  WRAP_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
  case "$WRAP_EXIT" in
    2) WRAP_V="B" ;;
    0)
      if [ "$after" -gt "$before" ]; then
        WRAP_V="W"
        WRAP_LAST="$(/usr/bin/tail -n 1 "$WRAP_DRAIN")"
      else
        WRAP_V="a"
      fi
      ;;
    *) WRAP_V="E${WRAP_EXIT}" ;;
  esac
}

# $1 label  $2 command  $3 verdict wanted from the hook (a|B|W)  $4 verdict wanted from the
# copy WRAP_MUTANT names (a|B|W), or - to skip that limb  $5 (optional) for a wanted B, a
# pattern the hook's refusal must carry; for a wanted W, the arm its would-fire row must name.
wrap_arm() {
  local name="$1" cmd="$2" want="$3" wantm="$4" detail="${5:-}" got gotm="-" ok=1 why=""
  WRAP_ARMCMD="$cmd"
  WRAP_ARMWANT="$want"
  wrap_run block-destructive.sh "$cmd"
  got="$WRAP_V"
  if [ "$got" != "$want" ]; then ok=0; why="hook=${got}"; fi
  if [ "$ok" = 1 ] && [ -n "$detail" ]; then
    case "$want" in
      B) if ! /usr/bin/grep -qE "$detail" <<<"$WRAP_ERR"; then ok=0; why="refusal lacks /${detail}/"; fi ;;
      W) case "$WRAP_LAST" in *"\"arm\":\"${detail}\""*) ;; *) ok=0; why="row arm is not ${detail}" ;; esac ;;
    esac
  fi
  if [ "$wantm" != "-" ]; then
    wrap_run "$WRAP_MUTANT" "$cmd"
    gotm="$WRAP_V"
    if [ "$gotm" != "$wantm" ]; then ok=0; why="${why} mutant=${gotm}"; fi
  fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (hook %s, mutant %s)\n' "$name" "$got" "$gotm"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted hook=%s mutant=%s; observed %s\n  stderr: %s\n' "$name" "$want" "$wantm" "${why# }" "$WRAP_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# --- the fixture is live before any verdict is read -------------------------------------
wrap_run block-destructive.sh 'git push --force origin main'
wrap_scope_hook="$WRAP_V"
wrap_scope_err="$WRAP_ERR"
wrap_run block-destructive-mut.sh 'git push --force origin main'
wrap_scope_mut="$WRAP_V"
if [ "$wrap_scope_hook" = "B" ] && [ "$wrap_scope_mut" = "B" ] \
   && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-001' <<<"$wrap_scope_err"; then
  /usr/bin/printf 'PASS: WRAP-SCOPE the hook copy and its reverse mutant are in scope and enforcing (unrelated rule -001 fires on both), so the verdicts below are live\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAP-SCOPE fixture not live (hook=%s mutant=%s); the verdicts below are unusable\n' "$wrap_scope_hook" "$wrap_scope_mut"
  FAIL=$((FAIL + 1))
fi

# WRAPOPT-M0 — the reverse mutant differs from the hook by exactly its three marked lines:
# two changed (the word and keyword patterns) and one deleted (the option-walk call).
wrap_m0_tmp="$(/usr/bin/mktemp)"
/usr/bin/diff "${WRAP_HOOKS}/block-destructive.sh" "${WRAP_HOOKS}/block-destructive-mut.sh" > "$wrap_m0_tmp" 2>/dev/null
wrap_m0_counts="$(/usr/bin/awk '/^</ { l++ } /^>/ { g++ } END { printf "%d %d", l, g }' "$wrap_m0_tmp")"
/bin/rm -f "$wrap_m0_tmp"
if [ "$wrap_m0_counts" = "3 2" ] && /bin/bash -n "${WRAP_HOOKS}/block-destructive-mut.sh" 2>/dev/null; then
  /usr/bin/printf 'PASS: WRAPOPT-M0 the reverse mutant differs from the hook by exactly its marked lines (3 out, 2 in) and parses\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPOPT-M0 the reverse mutant does not differ by exactly the marked lines (removed/added = %s, wanted 3 2) or does not parse — every pair arm below is unusable\n' "$wrap_m0_counts"
  FAIL=$((FAIL + 1))
fi

# WRAPOPT-AB-M0 — the iteration's reverse mutant differs from the hook by exactly its two marked
# lines: one deleted (the resolution) and one changed (time's row).
wrap_ab_tmp="$(/usr/bin/mktemp)"
/usr/bin/diff "${WRAP_HOOKS}/block-destructive.sh" "${WRAP_HOOKS}/block-destructive-ab.sh" > "$wrap_ab_tmp" 2>/dev/null
wrap_ab_counts="$(/usr/bin/awk '/^</ { l++ } /^>/ { g++ } END { printf "%d %d", l, g }' "$wrap_ab_tmp")"
/bin/rm -f "$wrap_ab_tmp"
if [ "$wrap_ab_counts" = "2 1" ] && /bin/bash -n "${WRAP_HOOKS}/block-destructive-ab.sh" 2>/dev/null; then
  /usr/bin/printf 'PASS: WRAPOPT-AB-M0 the reverse mutant of the long-option iteration differs from the hook by exactly its marked lines (2 out, 1 in) and parses\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPOPT-AB-M0 the reverse mutant of the long-option iteration does not differ by exactly its marked lines (removed/added = %s, wanted 2 1) or does not parse — the WRAPOPT-ab arms below are unusable\n' "$wrap_ab_counts"
  FAIL=$((FAIL + 1))
fi

# --- WRAPVOCAB-PARITY — every list of the vocabulary, in both directions -----------------
# Four lists hold the words: this walk (the M-WRAP-WORDS and M-WRAP-KEYWORDS lines), the
# egress rule's prefix-command walk (the first two pattern lines after its one
# `case "${egress_raw##*/}" in`), the shared canonicalizer (every PREFIX["…"] key), and the
# SIGPIPE-idiom lint of the repository-integrity workflow (its P_WRAP alternation). A word
# is a keyword if it is one of WRAP_KW and a wrapper otherwise. They are compared word by
# word against this walk, and the table below declares every difference with its reason. The
# arms fail on a difference no row declares AND on a row whose difference no longer exists,
# so a declaration cannot outlive the divergence it excuses. They compare WORDS: the walks
# also differ in grammar (match form, a leading redirection, an escaped verb, dash-led
# tokens), and the readiness text states that per list.
WRAP_KW=" then do else elif in ! if while until { } {} nocorrect case coproc "
WRAP_DECL='egress|keyword|in|missing|no shell construct puts a command word directly after in; this walk and the canonicalizer over-reach harmlessly, and dropping it would narrow an enforced set
egress|keyword|}|extra|a closing brace opens no command position; the egress walk lists it and this walk needs no entry for it
egress|keyword|{}|extra|the egress walk resolves an xargs replacement token with it; this rule declares the replacement operand open
lint|wrapper|doas|extra|a launcher outside this rule set, declared in the readiness item; the lint asks which words may stand between a pipe and a reader
lint|wrapper|setsid|extra|a launcher outside this rule set, declared in the readiness item; the lint asks which words may stand between a pipe and a reader
lint|wrapper|ionice|extra|a launcher outside this rule set, declared in the readiness item; the lint asks which words may stand between a pipe and a reader
lint|wrapper|chrt|extra|a launcher outside this rule set, declared in the readiness item; the lint asks which words may stand between a pipe and a reader
egress|keyword|nocorrect|missing|a position this walk reaches; the other list owns its own reach (ledger row)
canon|keyword|nocorrect|missing|a position this walk reaches; the other list owns its own reach (ledger row)
egress|wrapper|noglob|missing|a position this walk reaches; the other list owns its own reach (ledger row)
canon|wrapper|noglob|missing|a position this walk reaches; the other list owns its own reach (ledger row)
lint|wrapper|noglob|missing|a position this walk reaches; the other list owns its own reach (ledger row)
egress|wrapper|-|missing|a position this walk reaches; the other list owns its own reach (ledger row)
canon|wrapper|-|missing|a position this walk reaches; the other list owns its own reach (ledger row)
lint|wrapper|-|missing|a position this walk reaches; the other list owns its own reach (ledger row)
canon|keyword|{|missing|a position this walk reaches; the other list owns its own reach (ledger row)
egress|keyword|case|missing|a position this walk reaches; the other list owns its own reach (ledger row)
canon|keyword|case|missing|a position this walk reaches; the other list owns its own reach (ledger row)
egress|keyword|coproc|missing|a position this walk reaches; the other list owns its own reach (ledger row)
canon|keyword|coproc|missing|a position this walk reaches; the other list owns its own reach (ledger row)
lint|wrapper|xargs|missing|the lint excludes xargs for its own documented reason: the child stdin is not the pipe'

wrap_words_hook() { # $1 = a copy of this hook -> one word per line, or EXTRACTION-FAILED
  /usr/bin/awk -v q="'" '
    index($0, "# M-WRAP-WORDS") || index($0, "# M-WRAP-KEYWORDS") {
      if (index($0, "# M-WRAP-WORDS")) nw++; else nk++
      line = $0
      sub(/^[ \t]*/, "", line)
      p = index(line, ")")
      if (p == 0) { bad = 1; next }
      pat = substr(line, 1, p - 1)
      gsub(q, "", pat)
      n = split(pat, w, "|")
      for (i = 1; i <= n; i++) if (w[i] != "") print w[i]
    }
    END { if (nw != 1 || nk != 1 || bad) print "EXTRACTION-FAILED" }
  ' "$1"
}
wrap_words_egress() { # $1 = a copy of the egress hook
  /usr/bin/awk -v q="'" '
    index($0, "case \"${egress_raw##*/}\" in") { anchors++; armed = 1; next }
    armed && got < 2 && $0 ~ /^[ \t]*[^# \t][^ \t]*\)[ \t]*$/ {
      line = $0
      sub(/^[ \t]*/, "", line)
      sub(/\)[ \t]*$/, "", line)
      gsub(q, "", line)
      n = split(line, w, "|")
      for (i = 1; i <= n; i++) if (w[i] != "") print w[i]
      got++
    }
    END { if (anchors != 1 || got != 2) print "EXTRACTION-FAILED" }
  ' "$1"
}
wrap_words_canon() { # $1 = a copy of the canonicalizer
  /usr/bin/awk '
    {
      line = $0
      while ((p = index(line, "PREFIX[\"")) > 0) {
        rest = substr(line, p + 8)
        e = index(rest, "\"")
        if (e == 0) break
        print substr(rest, 1, e - 1)
        found++
        line = substr(rest, e + 1)
      }
    }
    END { if (found == 0) print "EXTRACTION-FAILED" }
  ' "$1"
}
wrap_words_lint() { # $1 = a copy of the repository-integrity workflow
  /usr/bin/awk -v q="'" '
    index($0, "P_WRAP=" q "(") {
      p = index($0, "P_WRAP=" q "(")
      rest = substr($0, p + 9)
      e = index(rest, ")")
      if (e == 0) { bad = 1; next }
      n = split(substr(rest, 1, e - 1), w, "|")
      for (i = 1; i <= n; i++) if (w[i] != "") print w[i]
      hits++
    }
    END { if (hits != 1 || bad) print "EXTRACTION-FAILED" }
  ' "$1"
}

WRAP_SET=""
wrap_classify() { # $1 = words, whitespace-separated  $2 = wrapper|keyword -> WRAP_SET
  local w
  WRAP_SET=" "
  for w in $1; do
    case "$WRAP_KW" in
      *" $w "*) if [ "$2" = "keyword" ]; then WRAP_SET="${WRAP_SET}${w} "; fi ;;
      *) if [ "$2" = "wrapper" ]; then WRAP_SET="${WRAP_SET}${w} "; fi ;;
    esac
  done
}
wrap_declared() { # $1 copy  $2 class  $3 word  $4 extra|missing -> 0 if a row declares it
  local c k w d r
  while IFS='|' read -r c k w d r; do
    if [ "$c" = "$1" ] && [ "$k" = "$2" ] && [ "$w" = "$3" ] && [ "$d" = "$4" ]; then return 0; fi
  done <<<"$WRAP_DECL"
  return 1
}
WRAP_PROBLEMS=""
# Compare one list with this walk on one class; append UNDECLARED and STALE findings.
wrap_parity_one() { # $1 copy  $2 class  $3 that copy's words  $4 this walk's words
  local s h w c k dw d r
  wrap_classify "$3" "$2"; s="$WRAP_SET"
  wrap_classify "$4" "$2"; h="$WRAP_SET"
  for w in $s; do
    case "$h" in *" $w "*) continue ;; esac
    wrap_declared "$1" "$2" "$w" extra || WRAP_PROBLEMS="${WRAP_PROBLEMS} UNDECLARED:${1}+${w}"
  done
  for w in $h; do
    case "$s" in *" $w "*) continue ;; esac
    wrap_declared "$1" "$2" "$w" missing || WRAP_PROBLEMS="${WRAP_PROBLEMS} UNDECLARED:${1}-${w}"
  done
  while IFS='|' read -r c k dw d r; do
    if [ "$c" != "$1" ] || [ "$k" != "$2" ]; then continue; fi
    case "$d" in
      extra)
        case "$s" in *" $dw "*) case "$h" in *" $dw "*) WRAP_PROBLEMS="${WRAP_PROBLEMS} STALE:${1}+${dw}" ;; esac ;;
                    *) WRAP_PROBLEMS="${WRAP_PROBLEMS} STALE:${1}+${dw}" ;; esac
        ;;
      missing)
        case "$h" in *" $dw "*) case "$s" in *" $dw "*) WRAP_PROBLEMS="${WRAP_PROBLEMS} STALE:${1}-${dw}" ;; esac ;;
                    *) WRAP_PROBLEMS="${WRAP_PROBLEMS} STALE:${1}-${dw}" ;; esac
        ;;
    esac
  done <<<"$WRAP_DECL"
}

# The fourth list lives outside the hook layout: resolved the way the corpus is, and never
# assumed — an unresolved workflow file is a FAIL, not a skipped comparison.
WRAP_LINT=""
wrap_try_lint() { if [ -z "$WRAP_LINT" ] && [ -n "$1" ] && [ -f "$1" ]; then WRAP_LINT="$1"; fi; }
wrap_try_lint "$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd -P)/.github/workflows/repo-integrity.yml"
wrap_src_root=""
if [ -r "$(dirname "$0")/.source-repo-root" ]; then
  IFS= read -r wrap_src_root < "$(dirname "$0")/.source-repo-root" || true
fi
if [ -n "$wrap_src_root" ]; then wrap_try_lint "${wrap_src_root}/.github/workflows/repo-integrity.yml"; fi
WRAP_EGRESS="${HOOK%/*}/block-egress.sh"
WRAP_CANON="${HOOK%/*}/lib/command-position.awk"

wrap_w_hook="$(wrap_words_hook "$HOOK")"
wrap_w_egress="$(wrap_words_egress "$WRAP_EGRESS")"
wrap_w_canon="$(wrap_words_canon "$WRAP_CANON")"
wrap_w_lint="EXTRACTION-FAILED"
if [ -n "$WRAP_LINT" ]; then wrap_w_lint="$(wrap_words_lint "$WRAP_LINT")"; fi

# $1 = arm label  $2 = class  $3 = this walk's words (normally the shipped hook's) $4 = the
# canonicalizer's words (normally the shipped copy's) -> PASS/FAIL line
wrap_parity_arm() {
  local name="$1" class="$2" hw="$3" cw="$4" kwlint
  WRAP_PROBLEMS=""
  case "${hw} ${wrap_w_egress} ${cw} ${wrap_w_lint}" in
    *EXTRACTION-FAILED*) WRAP_PROBLEMS=" EXTRACTION-FAILED" ;;
  esac
  if [ -z "$WRAP_PROBLEMS" ]; then
    wrap_parity_one egress "$class" "$wrap_w_egress" "$hw"
    wrap_parity_one canon "$class" "$cw" "$hw"
    if [ "$class" = "wrapper" ]; then
      wrap_parity_one lint wrapper "$wrap_w_lint" "$hw"
    else
      # The lint's list holds no keyword: it names what may stand between a pipe and a reader.
      wrap_classify "$wrap_w_lint" keyword
      for kwlint in $WRAP_SET; do WRAP_PROBLEMS="${WRAP_PROBLEMS} UNDECLARED:lint+${kwlint}"; done
    fi
  fi
  WRAP_PARITY_RESULT="${WRAP_PROBLEMS# }"
}

wrap_parity_arm "WRAPVOCAB-PARITY-wrappers" wrapper "$wrap_w_hook" "$wrap_w_canon"
if [ -z "$WRAP_PARITY_RESULT" ]; then
  /usr/bin/printf 'PASS: WRAPVOCAB-PARITY-wrappers the wrapper words of this walk, the egress walk, the canonicalizer and the SIGPIPE lint differ exactly where the declared table says, in both directions (lint list via %s)\n' "$WRAP_LINT"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPVOCAB-PARITY-wrappers %s\n' "$WRAP_PARITY_RESULT"
  FAIL=$((FAIL + 1))
fi
wrap_parity_arm "WRAPVOCAB-PARITY-keywords" keyword "$wrap_w_hook" "$wrap_w_canon"
if [ -z "$WRAP_PARITY_RESULT" ]; then
  /usr/bin/printf 'PASS: WRAPVOCAB-PARITY-keywords the keyword words of the three walks differ exactly where the declared table says, and the lint list holds none\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPVOCAB-PARITY-keywords %s\n' "$WRAP_PARITY_RESULT"
  FAIL=$((FAIL + 1))
fi

# The parity check is shown able to fail, three ways. Each mutation is asserted live first
# (the mutated copy differs from its source), so a sed that matched nothing cannot pass.
wrap_pm_hook1="${WRAP_ROOT}/parity-m1.sh"
/usr/bin/sed -e '/# M-WRAP-WORDS/s/|timeout)/|timeout|zzwrapword)/' "$HOOK" > "$wrap_pm_hook1"
wrap_parity_arm "M1" wrapper "$(wrap_words_hook "$wrap_pm_hook1")" "$wrap_w_canon"
if ! /usr/bin/cmp -s "$HOOK" "$wrap_pm_hook1" && [[ "$WRAP_PARITY_RESULT" == *"UNDECLARED:egress-zzwrapword"* ]]; then
  /usr/bin/printf 'PASS: WRAPVOCAB-PARITY-M1 a hook copy with one extra wrapper word is reported as an undeclared difference\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPVOCAB-PARITY-M1 an extra wrapper word was not reported (result: %s)\n' "${WRAP_PARITY_RESULT:-none}"
  FAIL=$((FAIL + 1))
fi
# M2 removes one word from a canonicalizer copy: the canonicalizer now holds every word of
# this walk, so a copy that loses one must be reported as an undeclared difference. The
# removal is asserted live twice — the copy differs, and the word is gone from what the
# extractor reads — so a sed that matched nothing cannot pass.
wrap_pm_canon2="${WRAP_ROOT}/parity-m2.awk"
/usr/bin/sed -e 's/PREFIX\["nice"\]=[0-9];[ ]*//' "$WRAP_CANON" > "$wrap_pm_canon2"
wrap_pm2_words="$(wrap_words_canon "$wrap_pm_canon2")"
wrap_pm2_gone=1
case " $(/usr/bin/printf '%s' "$wrap_pm2_words" | /usr/bin/tr '\n' ' ') " in *" nice "*) wrap_pm2_gone=0 ;; esac
wrap_parity_arm "M2" wrapper "$wrap_w_hook" "$wrap_pm2_words"
if ! /usr/bin/cmp -s "$WRAP_CANON" "$wrap_pm_canon2" && [ "$wrap_pm2_gone" = 1 ] && [[ "$WRAP_PARITY_RESULT" == *"UNDECLARED:canon-nice"* ]]; then
  /usr/bin/printf 'PASS: WRAPVOCAB-PARITY-M2 a canonicalizer copy that loses a word of this walk is reported as an undeclared difference\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPVOCAB-PARITY-M2 a lost word was not reported (word removed=%s, result: %s)\n' "$wrap_pm2_gone" "${WRAP_PARITY_RESULT:-none}"
  FAIL=$((FAIL + 1))
fi
wrap_pm_hook3="${WRAP_ROOT}/parity-m3.sh"
/usr/bin/sed -e 's/# M-WRAP-WORDS//' "$HOOK" > "$wrap_pm_hook3"
wrap_parity_arm "M3" wrapper "$(wrap_words_hook "$wrap_pm_hook3")" "$wrap_w_canon"
if ! /usr/bin/cmp -s "$HOOK" "$wrap_pm_hook3" && [ "$WRAP_PARITY_RESULT" = "EXTRACTION-FAILED" ]; then
  /usr/bin/printf 'PASS: WRAPVOCAB-PARITY-M3 a hook copy without its word marker reports an extraction failure, never parity\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPVOCAB-PARITY-M3 a missing marker did not report an extraction failure (result: %s)\n' "${WRAP_PARITY_RESULT:-none}"
  FAIL=$((FAIL + 1))
fi

# WRAPVOCAB-PARITY-DOC — the readiness item that declares the walked set names, as a
# backticked word, every wrapper word any of the four lists holds: what the walk covers and
# what another list holds that it does not. Read in the fragment and in the generated
# registry, found by the same two-rung resolution the NOEXEC-DOC arms use.
wrap_classify "$wrap_w_hook $wrap_w_egress $wrap_w_canon $wrap_w_lint" wrapper
WRAP_DOC_WORDS="$WRAP_SET"
wrap_doc_missing() { # $1 = readiness file -> the words item 2 does not name, ITEM2-MISSING(n) or DOC-MISSING
  if [ ! -f "$1" ]; then /usr/bin/printf 'DOC-MISSING'; return 0; fi
  /usr/bin/awk -v words="$WRAP_DOC_WORDS" -v bq='`' '
    index($0, "2. **Wrapper-prefix residuals.**") { line = $0; hits++ }
    END {
      if (hits != 1) { printf "ITEM2-MISSING(%d)", hits; exit }
      n = split(words, w, " ")
      for (i = 1; i <= n; i++) if (w[i] != "" && w[i] != "EXTRACTION-FAILED" && index(line, bq w[i] bq) == 0) printf "%s ", w[i]
    }
  ' "$1"
}
wrap_doc_frag="$(wrap_doc_missing "$NOEXEC_DOC_FRAG")"
wrap_doc_index="$(wrap_doc_missing "$NOEXEC_DOC_INDEX")"
case "$WRAP_DOC_WORDS" in *EXTRACTION-FAILED*) wrap_doc_frag="EXTRACTION-FAILED" ;; esac
if [ -z "$wrap_doc_frag" ] && [ -z "$wrap_doc_index" ]; then
  /usr/bin/printf 'PASS: WRAPVOCAB-PARITY-DOC readiness item 2 names every wrapper word of the four lists, in the fragment and in the generated registry\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPVOCAB-PARITY-DOC readiness item 2 does not name: fragment [%s] registry [%s]\n' "$wrap_doc_frag" "$wrap_doc_index"
  FAIL=$((FAIL + 1))
fi

# --- WRAPROWS-PARITY — the canonicalizer's copy of this walk's wrapper rows (#8314) -----------
# The shared canonicalizer walks each wrapper's own option grammar from a COPY of this
# walk's rows (script_wrapper_row): the option facts are data about a program, so both walks
# read the same facts, and the copy is asserted here instead of shared at run time (a shared
# runtime file would put one more dependency on four always-on hooks). The arms compare
# every field of every wrapper after defaults, and the key sets three ways (the rows here,
# the rows there, and the canonicalizer's wrapper words), and the mutants below show the
# comparison able to fail. Both extractors read code lines only: a comment that spells a
# row is not a row. The walkers' LOGIC is a second copy this arm does not see; the corpus
# rows of each card that changes either walker are where a logic difference shows.
wraprows_hook() { # $1 = a copy of this hook -> "<wrapper|*default*><TAB><field><TAB><value>" and "LABEL<TAB><wrapper>" lines, or EXTRACTION-FAILED
  /usr/bin/awk '
    /^script_wrapper_row\(\) \{/ { inrow = 1; fn++; next }
    inrow && /^\}/ { inrow = 0; next }
    !inrow { next }
    /^[ \t]*#/ { next }
    {
      line = $0
      if (match(line, /^[ \t]*[a-z*]+\)/)) {
        cur = substr(line, RSTART, RLENGTH); gsub(/[ \t)]/, "", cur)
        if (cur != "*") { print "LABEL\t" cur; nl++ }
      }
      while (match(line, /script_w(opt|larg|nox|split|lsplit|long|pos)="[^"]*"/)) {
        a = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        f = a; sub(/^script_w/, "", f); sub(/=.*$/, "", f)
        v = a; sub(/^[^"]*"/, "", v); sub(/"$/, "", v)
        print ((cur == "") ? "*default*" : cur) "\t" f "\t" v; nv++
      }
    }
    END { if (fn != 1 || nl == 0 || nv == 0) print "EXTRACTION-FAILED" }
  ' "$1"
}
wraprows_canon() { # $1 = a copy of the canonicalizer -> "<wrapper|*default*><TAB><field><TAB><value>" and "ROW<TAB><wrapper>" lines, or EXTRACTION-FAILED
  /usr/bin/awk '
    /^[ \t]*#/ { next }
    {
      line = $0
      while (match(line, /W(ROW|DEF|OPT|LARG|NOX|SPLIT|LSPLIT|LONG|POS)\["[^"]*"\]=("[^"]*"|[0-9]+)/)) {
        a = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        t = a; sub(/\[.*$/, "", t); sub(/^W/, "", t)
        k = a; sub(/^[^"]*"/, "", k); sub(/".*$/, "", k)
        v = a; sub(/^[^=]*=/, "", v); sub(/^"/, "", v); sub(/"$/, "", v)
        if (t == "ROW") { print "ROW\t" k; nr++ }
        else if (t == "DEF") { print "*default*\t" k "\t" v; nd++ }
        else { print k "\t" tolower(t) "\t" v; nv++ }
      }
    }
    END { if (nr == 0 || nd == 0 || nv == 0) print "EXTRACTION-FAILED" }
  ' "$1"
}
# $1 = the hook rows  $2 = the canonicalizer rows  $3 = the canonicalizer words -> WRAPROWS_RESULT
# (empty = parity; otherwise space-separated FIELD:/KEY:/NODEFAULT:/EXTRACTION-FAILED tokens)
wraprows_compare() {
  local cwords
  wrap_classify "$3" wrapper; cwords="$WRAP_SET"
  case "$1 $2" in
    *EXTRACTION-FAILED*) WRAPROWS_RESULT="EXTRACTION-FAILED"; return 0 ;;
  esac
  WRAPROWS_RESULT="$( { /usr/bin/printf '%s\n' "$1" | /usr/bin/sed 's/^/H	/'
      /usr/bin/printf '%s\n' "$2" | /usr/bin/sed 's/^/C	/'; } | /usr/bin/awk -F'\t' -v cwords="$cwords" '
    BEGIN { nf = split("opt larg nox split lsplit long pos", F, " "); nw = split(cwords, W, " ") }
    $1 == "H" && $2 == "LABEL" { hk[$3] = 1; next }
    $1 == "C" && $2 == "ROW" { ck[$3] = 1; next }
    $1 == "H" { hv[$2, $3] = $4; hs[$2, $3] = 1; next }
    $1 == "C" { cv[$2, $3] = $4; cs[$2, $3] = 1; next }
    END {
      for (i = 1; i <= nf; i++) {
        f = F[i]
        if (!(("*default*", f) in hs)) printf "NODEFAULT:hook.%s ", f
        if (!(("*default*", f) in cs)) printf "NODEFAULT:canon.%s ", f
      }
      for (w in hk) if (!(w in ck)) printf "KEY:canon-%s ", w
      for (w in ck) if (!(w in hk)) printf "KEY:hook-%s ", w
      for (i = 1; i <= nw; i++) if (W[i] != "" && !(W[i] in ck)) printf "KEY:row-%s ", W[i]
      for (w in ck) { seen = 0; for (i = 1; i <= nw; i++) if (W[i] == w) seen = 1; if (!seen) printf "KEY:word-%s ", w }
      for (w in hk) {
        if (!(w in ck)) continue
        for (i = 1; i <= nf; i++) {
          f = F[i]
          h = ((w, f) in hs) ? hv[w, f] : hv["*default*", f]
          c = ((w, f) in cs) ? cv[w, f] : cv["*default*", f]
          if (h != c) printf "FIELD:%s.%s ", w, f
        }
      }
    }' )"
  WRAPROWS_RESULT="${WRAPROWS_RESULT% }"
}

wrap_r_hook="$(wraprows_hook "$HOOK")"
wrap_r_canon="$(wraprows_canon "$WRAP_CANON")"
wraprows_compare "$wrap_r_hook" "$wrap_r_canon" "$wrap_w_canon"
wrap_r_fields="$(/usr/bin/printf '%s' "$WRAPROWS_RESULT" | /usr/bin/tr ' ' '\n' | /usr/bin/grep -v -e '^KEY:' -e '^$' | /usr/bin/tr '\n' ' ')"
wrap_r_keys="$(/usr/bin/printf '%s' "$WRAPROWS_RESULT" | /usr/bin/tr ' ' '\n' | /usr/bin/grep -e '^KEY:' -e '^EXTRACTION-FAILED$' | /usr/bin/tr '\n' ' ')"
wrap_r_nlab="$(/usr/bin/printf '%s\n' "$wrap_r_hook" | /usr/bin/grep -c '^LABEL	' || true)"
if [ -z "$wrap_r_fields" ] && [ "$wrap_r_nlab" -ge 11 ]; then
  /usr/bin/printf 'PASS: WRAPROWS-PARITY-01 every field of every wrapper row (%s wrappers x 7 fields, after defaults) is equal in this walk and in the canonicalizer\n' "$wrap_r_nlab"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPROWS-PARITY-01 the canonicalizer copy of the wrapper rows differs from this walk (wrappers read=%s): %s\n' "$wrap_r_nlab" "${wrap_r_fields:-none}"
  FAIL=$((FAIL + 1))
fi
if [ -z "$wrap_r_keys" ] && [ "$wrap_r_nlab" -ge 11 ]; then
  /usr/bin/printf 'PASS: WRAPROWS-PARITY-02 the wrapper key sets are one set: the rows here, the rows in the canonicalizer, and its wrapper words\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPROWS-PARITY-02 the wrapper key sets differ: %s\n' "${wrap_r_keys:-none}"
  FAIL=$((FAIL + 1))
fi

# The row comparison is shown able to fail, three ways, each mutation asserted live.
wrap_rm1="${WRAP_ROOT}/rows-m1.awk"
/usr/bin/sed -e 's/WOPT\["nice"\]="n:"/WOPT["nice"]="m:"/' "$WRAP_CANON" > "$wrap_rm1"
wraprows_compare "$wrap_r_hook" "$(wraprows_canon "$wrap_rm1")" "$wrap_w_canon"
if ! /usr/bin/cmp -s "$WRAP_CANON" "$wrap_rm1" && [[ " $WRAPROWS_RESULT " == *" FIELD:nice.opt "* ]]; then
  /usr/bin/printf 'PASS: WRAPROWS-PARITY-M1 a canonicalizer copy with one option letter changed is reported\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPROWS-PARITY-M1 a changed option letter was not reported (result: %s)\n' "${WRAPROWS_RESULT:-none}"
  FAIL=$((FAIL + 1))
fi
wrap_rm2="${WRAP_ROOT}/rows-m2.sh"
/usr/bin/sed -e '/^    nice)/s/script_wlarg=" --adjustment "/script_wlarg=" "/' "$HOOK" > "$wrap_rm2"
wraprows_compare "$(wraprows_hook "$wrap_rm2")" "$wrap_r_canon" "$wrap_w_canon"
if ! /usr/bin/cmp -s "$HOOK" "$wrap_rm2" && [[ " $WRAPROWS_RESULT " == *" FIELD:nice.larg "* ]]; then
  /usr/bin/printf 'PASS: WRAPROWS-PARITY-M2 a hook copy whose nice row loses a long option is reported\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPROWS-PARITY-M2 a lost long option was not reported (result: %s)\n' "${WRAPROWS_RESULT:-none}"
  FAIL=$((FAIL + 1))
fi
wrap_rm3="${WRAP_ROOT}/rows-m3.sh"
/usr/bin/sed -e 's/^script_wrapper_row() {/script_wrapper_rowx() {/' "$HOOK" > "$wrap_rm3"
wrap_rm3_rows="$(wraprows_hook "$wrap_rm3")"
wraprows_compare "$wrap_rm3_rows" "$wrap_r_canon" "$wrap_w_canon"
if ! /usr/bin/cmp -s "$HOOK" "$wrap_rm3" && [ "$wrap_rm3_rows" = "EXTRACTION-FAILED" ] && [ "$WRAPROWS_RESULT" = "EXTRACTION-FAILED" ]; then
  /usr/bin/printf 'PASS: WRAPROWS-PARITY-M3 a hook copy without the row function reports an extraction failure, never parity\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: WRAPROWS-PARITY-M3 a missing row function did not report an extraction failure (result: %s)\n' "${WRAPROWS_RESULT:-none}"
  FAIL=$((FAIL + 1))
fi

# --- CMDPOS-SKEW — the canonicalizer's version-skew canary (#8314) ---------------------------
# The hook trusts the shared canonicalizer only after two probes: a one-line function body,
# and a wrapper carrying a separate-argument option before a benign word, whose canonical
# form exposes the word only on the walk that reads wrapper grammar. A copy of the
# canonicalizer that predates that grammar, or whose row table is damaged, passes the first
# probe and fails the second, so the hook must fail CLOSED rather than read every wrapped
# command the old way while believing the primitive healthy. Modelled by a copy whose nice
# row is removed; the control is the same sandbox with the shipped copy.
cps_root="$(/usr/bin/mktemp -d)"
cps_hooks="${cps_root}/.claude/hooks"
/bin/mkdir -p "${cps_hooks}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh "${cps_hooks}/lib/" 2>/dev/null || true
/bin/cp "$HOOK" "${cps_hooks}/block-destructive.sh"
/usr/bin/printf 'enforce' > "${cps_hooks}/.mode"
cps_run() { # $1 = command -> CPS_RC and CPS_ERR
  CPS_RC=0
  CPS_ERR="$( ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
      /usr/bin/printf '%s' "$(bash_payload "$1" "$cps_root")" | /bin/bash "${cps_hooks}/block-destructive.sh" 2>&1 >/dev/null ) )" || CPS_RC="$?"
}
/usr/bin/sed -e 's/WROW\["nice"\]=1//' "${HOOK%/*}/lib/command-position.awk" > "${cps_hooks}/lib/command-position.awk"
cps_live=0
if ! /usr/bin/cmp -s "${HOOK%/*}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk" \
   && ! /usr/bin/grep -q -F 'WROW["nice"]' "${cps_hooks}/lib/command-position.awk"; then cps_live=1; fi
cps_run 'echo hello'
if [ "$cps_live" = 1 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'PRIMITIVE-MISSING' <<<"$CPS_ERR"; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-01 a canonicalizer copy without the wrapper grammar fails the hook closed (exit 2, PRIMITIVE-MISSING)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-01 a canonicalizer copy without the wrapper grammar did not fail the hook closed (mutant live=%s, exit=%s): %s\n' "$cps_live" "$CPS_RC" "$CPS_ERR"
  FAIL=$((FAIL + 1))
fi
# CMDPOS-SKEW-APPEND (#8314, follow-up pass): the second probe puts an append-form prefix
# assignment ahead of its wrapper, so a copy whose walk reads that word as the command word —
# the walk before this pass — never exposes the benign word, and the hook fails CLOSED rather
# than read every append-prefixed command the old way. Modelled by a copy whose marked
# assignment test is reverted to the NAME=value form alone, shown live first: it differs from
# the shipped copy by exactly that one line, and it parses.
/usr/bin/sed -e '/CMDPOS-APPEND/s/[[]+[]]?=/=/' "${HOOK%/*}/lib/command-position.awk" > "${cps_hooks}/lib/command-position.awk"
cps_n="$(/usr/bin/diff "${HOOK%/*}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk" 2>/dev/null | /usr/bin/grep -c '^[<>]' || true)"
cps_live=0
if [ "$cps_n" = 2 ] && /usr/bin/awk -f "${cps_hooks}/lib/command-position.awk" </dev/null >/dev/null 2>&1; then cps_live=1; fi
cps_run 'echo hello'
if [ "$cps_live" = 1 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'PRIMITIVE-MISSING' <<<"$CPS_ERR"; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-APPEND a canonicalizer copy without the append form of a prefix assignment fails the hook closed (exit 2, PRIMITIVE-MISSING)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-APPEND a canonicalizer copy without the append form did not fail the hook closed (mutant live=%s, differing lines=%s, exit=%s): %s\n' "$cps_live" "${cps_n:-none}" "$CPS_RC" "$CPS_ERR"
  FAIL=$((FAIL + 1))
fi
/bin/cp "${HOOK%/*}/lib/command-position.awk" "${cps_hooks}/lib/command-position.awk"
cps_run 'echo hello'
cps_ctl_benign="$CPS_RC"
cps_run 'rm -rf /'
if [ "$cps_ctl_benign" = 0 ] && [ "$CPS_RC" = 2 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-004' <<<"$CPS_ERR"; then
  /usr/bin/printf 'PASS: CMDPOS-SKEW-CTL the same sandbox with the shipped canonicalizer allows a benign command and refuses the plain form\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: CMDPOS-SKEW-CTL the sandbox with the shipped canonicalizer is not live (benign exit=%s, plain-form exit=%s)\n' "$cps_ctl_benign" "$CPS_RC"
  FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$cps_root"

# --- pairing mutants: every control and pin below is shown able to fail (Stage 7 F-02) -------
# A control or a pin keeps its verdict across the change by design, so its two limbs cannot
# show that it is able to fail. Each one in this block is followed by a pairing arm
# (WRAPPAIR-*): the arm's own command, taken from wrap_arm and never retyped, run through a
# mutant of the hook, expecting the verdict that mutant gives, which must differ from the one
# the arm asserts. Each mutant is a design the walk could have had or a step it could have
# missed, and each is shown live before it is used: it differs from the hook by exactly the
# lines named, and it parses. Three reuse a mutation the suite already builds elsewhere: the
# parse-only exemption reverted (PARSE-14), the stdin deny on an interpreter whose walk finds
# no operand (STDIN-M1), and the operand walk reverted together with the conservative route for
# a word the walk cannot read (STDIN-M4). The rest are built here:
#   pscan     the verb-locator scan the decision record rejects: a word the prefix walk does
#             not know is stepped over until an interpreter or `source` verb, or a word that
#             holds `.sh`, so the walk reads on past where it must stop
#   pallow    the allowlist never matches, so every near miss would be refused
#   pnox      the describe-only letters no longer make the segment no execution
#   ptrunc    a wrapper option whose value is missing is refused, not read as a run that ended
#   pextless  the direct-execution arm adjudicates every target, the extensionless one too
#   pxoff     the xargs stdin deny is switched off
#   pxall     the xargs stdin deny refuses every interpreter xargs feeds, a token after it or
#             not
#   pnosplit  the split-string stop is removed from both of its lines
#   pambig    a prefix of two or more long options is taken for one of them
/usr/bin/sed '/# M-WRAP-OPTIONS/,/^        esac$/s@^          \*) break ;;$@          *) case "${script_ptok##*/}" in bash|sh|zsh|python|python3|perl|ruby|node|source|.) break ;; esac; case "$script_ptok" in *.sh*) break ;; esac; script_hidx=$(( script_hidx + 1 )) ;;@' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pscan.sh"
/usr/bin/sed 's@^  \[ -f "\$SCRIPT_ALLOWLIST" \] || return 1$@  return 1@' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pallow.sh"
/usr/bin/sed '/script_winert=1; return 0 ;;/d' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pnox.sh"
/usr/bin/sed 's@if \[ -z "\$_rest" \] && \[ "\$script_hidx" -lt "\$_n" \]; then script_hidx=\$(( script_hidx + 1 )); fi@if [ -z "$_rest" ]; then if [ "$script_hidx" -lt "$_n" ]; then script_hidx=$(( script_hidx + 1 )); else block "BLOCK-DESTRUCTIVE-022" "WRAP missing-value deny mutant" "test only"; fi; fi@' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-ptrunc.sh"
/usr/bin/sed 's@if script_operand_implicated exec; then@if true; then@' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pextless.sh"
/usr/bin/sed 's#\[ "\$script_noexec" -eq 1 \]#[ "$script_noexec" -eq 99 ]#' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pparse.sh"
/usr/bin/sed 's/^\( *\)\[ "\$script_idx" -lt "\${#script_tokens\[@\]}" \] || continue$/\1[ "$script_idx" -lt "${#script_tokens[@]}" ] || block "BLOCK-DESTRUCTIVE-022" "STDIN deny mutant" "test only"/' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pstdin.sh"
/usr/bin/sed 's@if \[ "\$script_xargs" -eq 1 \]; then@if [ "$script_xargs" -eq 9 ]; then@' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pxoff.sh"
/usr/bin/sed 's%if \[ \$(( script_hidx + 1 )) -ge "\${#script_tokens\[@\]}" \]; then%if [ "$script_xargs" -eq 1 ] || [ $(( script_hidx + 1 )) -ge "${#script_tokens[@]}" ]; then%' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pxall.sh"
/usr/bin/sed \
  -e '/if \[ "\$script_wsplit_cmd" -eq 1 \]; then return 0; fi/d' \
  -e '/if \[ "\$script_wsplit_cmd" -eq 1 \]; then script_hidx=\$(( script_hidx - 1 )); return 0; fi/d' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pnosplit.sh"
# splitcmd  script_split_scan always reports a command word, so every attached split value stops
#           the walk — the behaviour before that helper, when an attached split string carrying no
#           command word was stepped onto and the command that followed was never adjudicated
/usr/bin/sed 's@^  script_wsplit_cmd=0   # M-WRAP-SPLITCMD$@  script_wsplit_cmd=1; return 0   # M-WRAP-SPLITCMD@' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-splitcmd.sh"
/usr/bin/sed \
  -e '/# M-FWALK-BODY/,/^[[:space:]]*;;$/d' \
  -e 's|^\([[:space:]]*\)\*) # M-FWALK-ADVANCE.*|\1*) break ;;|' \
  -e '/# M-OPAQUE (mutation/d' \
  -e '/# M-OPND-JOIN (mutation/d' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pwalkroute.sh"
/usr/bin/sed '/# M-WRAP-ABBREV$/s/"\$_lk" -eq 1/"$_lk" -ge 1/' \
  "$HOOK" > "${WRAP_HOOKS}/block-destructive-pambig.sh"
for wrap_pm in pscan pallow pnox ptrunc pextless pparse pstdin pxoff pxall pnosplit pwalkroute pambig splitcmd; do
  /bin/chmod +x "${WRAP_HOOKS}/block-destructive-${wrap_pm}.sh"
done

wrap_mut_live() { # $1 label  $2 mutant file  $3 lines it removes  $4 lines it adds
  local tmp counts
  tmp="$(/usr/bin/mktemp)"
  /usr/bin/diff "${WRAP_HOOKS}/block-destructive.sh" "${WRAP_HOOKS}/$2" > "$tmp" 2>/dev/null
  counts="$(/usr/bin/awk '/^</ { l++ } /^>/ { g++ } END { printf "%d %d", l, g }' "$tmp")"
  /bin/rm -f "$tmp"
  if [ "$counts" = "$3 $4" ] && /bin/bash -n "${WRAP_HOOKS}/$2" 2>/dev/null; then
    /usr/bin/printf 'PASS: %s differs from the hook by exactly the lines it names (%s out, %s in) and parses\n' "$1" "$3" "$4"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s does not differ by exactly the lines it names (removed/added = %s, wanted %s %s) or does not parse — its pairing arms are unusable\n' "$1" "$counts" "$3" "$4"
    FAIL=$((FAIL + 1))
  fi
}
wrap_mut_live "WRAPPAIR-M-scan: the verb-locator scan mutant" block-destructive-pscan.sh 1 1
wrap_mut_live "WRAPPAIR-M-allow: the allowlist-blind mutant" block-destructive-pallow.sh 1 1
wrap_mut_live "WRAPPAIR-M-nox: the describe-only-off mutant" block-destructive-pnox.sh 1 0
wrap_mut_live "WRAPPAIR-M-trunc: the missing-value deny mutant" block-destructive-ptrunc.sh 1 1
wrap_mut_live "WRAPPAIR-M-extless: the every-target mutant" block-destructive-pextless.sh 1 1
wrap_mut_live "WRAPPAIR-M-parse: the parse-only revert (PARSE-14's mutation)" block-destructive-pparse.sh 1 1
wrap_mut_live "WRAPPAIR-M-stdin: the stdin deny (STDIN-M1's mutation)" block-destructive-pstdin.sh 1 1
wrap_mut_live "WRAPPAIR-M-xoff: the xargs-deny-off mutant" block-destructive-pxoff.sh 1 1
wrap_mut_live "WRAPPAIR-M-xall: the every-xargs-interpreter deny mutant" block-destructive-pxall.sh 1 1
wrap_mut_live "WRAPPAIR-M-nosplit: the no-split-stop mutant" block-destructive-pnosplit.sh 2 0
wrap_mut_live "WRAPPAIR-M-walkroute: the operand-walk and conservative-route revert (STDIN-M4's mutation), with the operand join removed" block-destructive-pwalkroute.sh 25 1
wrap_mut_live "WRAPPAIR-M-ambig: the ambiguity-blind mutant" block-destructive-pambig.sh 1 1
wrap_mut_live "WRAPPAIR-M-splitcmd: the always-a-command split-scan mutant (Stage 7 F-08 reverse)" block-destructive-splitcmd.sh 1 1

# $1 label  $2 mutant file  $3 the verdict that mutant gives the arm's command (a|B|W). A
# pairing that expects the verdict the arm itself asserts fails on its own: it could not show
# the arm failing.
wrap_pair() {
  local name="$1" mut="$2" want="$3"
  if [ "$want" = "$WRAP_ARMWANT" ]; then
    /usr/bin/printf 'FAIL: %s expects the verdict the arm itself asserts (%s), so it cannot show the arm failing\n' "$name" "$want"
    FAIL=$((FAIL + 1))
    return 0
  fi
  wrap_run "$mut" "$WRAP_ARMCMD"
  if [ "$WRAP_V" = "$want" ]; then
    /usr/bin/printf 'PASS: %s (the arm asserts %s on the hook; %s gives %s)\n' "$name" "$WRAP_ARMWANT" "$mut" "$WRAP_V"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s — wanted %s from %s, observed %s\n  stderr: %s\n' "$name" "$want" "$mut" "$WRAP_V" "$WRAP_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# --- positions this walk does not reach: pins, routed to their own card -------------------

# --- nice and stdbuf, with their options (AC-2) --------------------------------------------
wrap_arm "WRAPOPT-AC2-nice: nice -n 10 bash <unlisted>.sh blocks" "nice -n 10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-AC2-stdbuf: stdbuf -o0 bash <unlisted>.sh blocks" "stdbuf -o0 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-AC2-near: nice -n 10 bash <allowlisted>.sh allowed (the allowlist was consulted)" "nice -n 10 bash ${WRAP_OK}" a a
wrap_pair "WRAPPAIR-AC2-near: the allowlist-blind mutant refuses the allowlisted script, so WRAPOPT-AC2-near can fail" block-destructive-pallow.sh B
wrap_arm "WRAPOPT-nice-bare: nice bash <unlisted>.sh blocks" "nice bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-stdbuf-bare: stdbuf bash <unlisted>.sh blocks" "stdbuf bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nice-n-att: nice -n10 bash <unlisted>.sh blocks" "nice -n10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nice-num: nice -10 bash <unlisted>.sh blocks (a digit is a flag)" "nice -10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nice-neg: nice -n -5 bash <unlisted>.sh blocks (the separate value is consumed, sign and all)" "nice -n -5 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nice-adj-eq: nice --adjustment=10 bash <unlisted>.sh blocks" "nice --adjustment=10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nice-adj-sep: nice --adjustment 10 bash <unlisted>.sh blocks" "nice --adjustment 10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nice-dd: nice -n 10 -- bash <unlisted>.sh blocks" "nice -n 10 -- bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-stdbuf-o-sep: stdbuf -o 0 bash <unlisted>.sh blocks (AC-2's separate-argument spelling)" "stdbuf -o 0 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-stdbuf-ioe: stdbuf -i0 -o0 -e0 bash <unlisted>.sh blocks" "stdbuf -i0 -o0 -e0 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-stdbuf-e-sep: stdbuf -e 0 bash <unlisted>.sh blocks" "stdbuf -e 0 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-stdbuf-out-eq: stdbuf --output=L bash <unlisted>.sh blocks" "stdbuf --output=L bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-stdbuf-out-sep: stdbuf --output L bash <unlisted>.sh blocks" "stdbuf --output L bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-abs: /usr/bin/nice -n 10 bash <unlisted>.sh blocks (basename match)" "/usr/bin/nice -n 10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-source: nice -n 10 source <unlisted>.sh blocks" "nice -n 10 source ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-nested: sudo nice -n 10 bash <unlisted>.sh blocks" "sudo nice -n 10 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-then: if true; then nice -n 5 bash <unlisted>.sh; fi blocks" "if true; then nice -n 5 bash ${WRAP_NA}; fi" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-exec: nice -n 10 <unlisted>.sh writes one exec row at its rollout phase" "nice -n 10 ${WRAP_NA}" W a exec
wrap_arm "WRAPOPT-nonshell: stdbuf -oL node <unlisted>.js writes one interp-nonshell row at its rollout phase" "stdbuf -oL node /tmp/pmo-wrap-na.js" W a interp-nonshell
wrap_arm "WRAPOPT-ctl-stdbuf-ok: stdbuf -o 0 bash <allowlisted>.sh allowed" "stdbuf -o 0 bash ${WRAP_OK}" a a
wrap_pair "WRAPPAIR-ctl-stdbuf-ok: the allowlist-blind mutant refuses it, so WRAPOPT-ctl-stdbuf-ok can fail" block-destructive-pallow.sh B
wrap_arm "WRAPOPT-ctl-grep: nice -n 10 grep -c bash <unlisted>.sh allowed (grep is the command)" "nice -n 10 grep -c bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-ctl-grep: the scan mutant reads past grep to bash and refuses, so WRAPOPT-ctl-grep can fail" block-destructive-pscan.sh B
wrap_arm "WRAPOPT-ctl-echo: echo nice -n 10 bash <unlisted>.sh allowed (off the segment head)" "echo nice -n 10 bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-ctl-echo: the scan mutant reads past echo and refuses, so WRAPOPT-ctl-echo can fail" block-destructive-pscan.sh B
wrap_arm "WRAPOPT-ctl-nearword: nicely -n 10 bash <unlisted>.sh allowed (a near-miss word is not a wrapper)" "nicely -n 10 bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-ctl-nearword: the scan mutant reads past the near-miss word and refuses, so WRAPOPT-ctl-nearword can fail" block-destructive-pscan.sh B
wrap_arm "WRAPOPT-ctl-end: nice -n allowed with no error (a consumed value past the end)" "nice -n" a a
wrap_pair "WRAPPAIR-ctl-end: the missing-value deny mutant refuses it, so WRAPOPT-ctl-end can fail" block-destructive-ptrunc.sh B
wrap_arm "WRAPOPT-ctl-extless: nice -n 10 ./pmo-wrap-tool allowed (an extensionless target, the shared residual)" "nice -n 10 ./pmo-wrap-tool" a a
wrap_pair "WRAPPAIR-ctl-extless: the every-target mutant records the extensionless target, so WRAPOPT-ctl-extless can fail" block-destructive-pextless.sh W
wrap_arm "WRAPOPT-ctl-parse-only: nice -n 10 bash -n <unlisted>.sh allowed (parse-only, behind the wrapper as without it)" "nice -n 10 bash -n ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-ctl-parse-only: the parse-only revert refuses it, so WRAPOPT-ctl-parse-only can fail" block-destructive-pparse.sh B

# --- every wrapper's row, one arm per spelling (whole set) ---------------------------------
# Each prefix is followed by `bash <unlisted>.sh`. The hook refuses; the reverse mutant, the
# walk as it stood, allows every one. sudo rows 14 to 16 are the two argument-taking options
# the sudo manual names that the design's row, built from the reference host's synopsis, did
# not list.
WRAP_ROWS_TABLE='sudo|sudo -n
sudo|sudo -u bot
sudo|sudo -ubot
sudo|sudo -nu bot
sudo|sudo -u bot -g staff
sudo|sudo -E -u bot
sudo|sudo --user bot
sudo|sudo --user=bot
sudo|sudo -D /tmp
sudo|sudo -u bot --
sudo|sudo -k
sudo|sudo -i
sudo|sudo -h box1
sudo|sudo -a bsdauth
sudo|sudo -c staff
sudo|sudo --login-class staff
env|env -i
env|env -u NAME
env|env -uNAME
env|env -u A -u B
env|env --unset NAME
env|env --unset=NAME
env|env -C /tmp
env|env -P /usr/bin
env|env -u NAME FOO=1
env|env a-b=1
env|env -a zero
command|command -p
command|command --
exec|exec -a myname
exec|exec -c
exec|exec -cl
exec|exec -l -a myname
nohup|nohup --
time|time -p
time|time -l
time|time -o /tmp/out.txt
time|time -f %e
xargs|xargs -n1
xargs|xargs -n 1
xargs|xargs -0
xargs|xargs -0 -n 1
xargs|xargs -P 4
xargs|xargs -n 1 -P 4
xargs|xargs -L 1
xargs|xargs -t
xargs|xargs -r
xargs|xargs -a /tmp/list.txt
timeout|timeout 5s
timeout|timeout -s KILL 5
timeout|timeout -sKILL 5
timeout|timeout -k 1 5
timeout|timeout --signal=KILL 5
timeout|timeout --signal KILL 5
timeout|timeout --foreground -s 9 10
nested|sudo -u bot env -u X nice -n 5
nested|time -p nice -n 10 stdbuf -o0
nested|ENVV=1 sudo -u bot'
wrap_rprev=""
wrap_rn=0
while IFS='|' read -r wrap_rw wrap_rpfx; do
  [ -n "$wrap_rw" ] || continue
  if [ "$wrap_rw" != "$wrap_rprev" ]; then wrap_rn=0; wrap_rprev="$wrap_rw"; fi
  wrap_rn=$((wrap_rn + 1))
  wrap_arm "WRAPOPT-row-${wrap_rw}-${wrap_rn}: ${wrap_rpfx} bash <unlisted>.sh blocks" \
    "${wrap_rpfx} bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
done <<<"$WRAP_ROWS_TABLE"

# --- describe-only options execute nothing, and the long spellings do not inherit that ---
wrap_arm "WRAPOPT-inert-command-V: command -V bash <unlisted>.sh allowed (describes, runs nothing)" "command -V bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-inert-command-V: the describe-only-off mutant refuses it, so WRAPOPT-inert-command-V can fail" block-destructive-pnox.sh B
wrap_arm "WRAPOPT-inert-command-pv: command -pv bash <unlisted>.sh allowed" "command -pv bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-inert-command-pv: the describe-only-off mutant refuses it, so WRAPOPT-inert-command-pv can fail" block-destructive-pnox.sh B
wrap_arm "WRAPOPT-inert-sudo-l: sudo -l bash <unlisted>.sh allowed (lists the policy, runs nothing)" "sudo -l bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-inert-sudo-l: the describe-only-off mutant refuses it, so WRAPOPT-inert-sudo-l can fail" block-destructive-pnox.sh B
wrap_arm "WRAPOPT-inert-sudo-v: sudo -v bash <unlisted>.sh allowed" "sudo -v bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-inert-sudo-v: the describe-only-off mutant refuses it, so WRAPOPT-inert-sudo-v can fail" block-destructive-pnox.sh B
wrap_arm "WRAPOPT-inert-sudo-e: sudo -e <unlisted>.sh allowed (edits, runs nothing)" "sudo -e ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-inert-sudo-e: the describe-only-off mutant records the edited file as executed, so WRAPOPT-inert-sudo-e can fail" block-destructive-pnox.sh W
wrap_arm "WRAPOPT-inert-sudo-lU: sudo -lU bot bash <unlisted>.sh allowed" "sudo -lU bot bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-inert-sudo-lU: the describe-only-off mutant refuses it, so WRAPOPT-inert-sudo-lU can fail" block-destructive-pnox.sh B
wrap_arm "WRAPDIV-sudo-long (declared over-block, introduced here): sudo --list bash <unlisted>.sh blocks — a long describe-only spelling is read as a flag" \
  "sudo --list bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"

# --- an option no row lists: the declared failure direction --------------------------------
wrap_arm "WRAPOPT-unlisted-flag: sudo --zz-unlisted bash <unlisted>.sh blocks (an unlisted option is stepped over as a flag)" \
  "sudo --zz-unlisted bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPDIV-unlisted-valued: sudo --zz-unlisted VALUE bash <unlisted>.sh allowed (its value is read as the command word)" \
  "sudo --zz-unlisted VALUE bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-unlisted-valued: the scan mutant reads past the value and refuses, so WRAPDIV-unlisted-valued can fail" block-destructive-pscan.sh B

# --- timeout -------------------------------------------------------------------------------
wrap_arm "WRAPOPT-timeout-near: timeout 5 bash <allowlisted>.sh allowed" "timeout 5 bash ${WRAP_OK}" a a
wrap_pair "WRAPPAIR-timeout-near: the allowlist-blind mutant refuses it, so WRAPOPT-timeout-near can fail" block-destructive-pallow.sh B
wrap_arm "WRAPDIV-timeout-malformed (declared over-read): timeout bash <unlisted>.sh writes one exec row — with no duration the command is read one token late" \
  "timeout bash ${WRAP_NA}" W a exec

# --- the first build condition: a token that carries the command line stays the command word
# env's split-string option takes the command line as its argument. Its ATTACHED spellings
# keep exactly the verdict they had (the mutant limb is that verdict): the walk stops on the
# token instead of stepping over an execution. The separate spelling is a flag, so the word
# after it is the command word.
wrap_arm "WRAPOPT-env-S: env -S bash <unlisted>.sh blocks" "env -S bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPDIV-env-S-quoted: env -S \"bash <unlisted>.sh\" allowed (a command line in one quoted string is not re-tokenized)" \
  "env -S \"bash ${WRAP_NA}\"" a a
wrap_pair "WRAPPAIR-env-S-quoted: the scan mutant reads on to the quoted script and records it, so WRAPDIV-env-S-quoted can fail" block-destructive-pscan.sh W
wrap_arm "WRAPOPT-env-S-attached: env -S<unlisted>.sh keeps its exec row (the walk stops on the token)" "env -S${WRAP_NA}" W W exec
wrap_pair "WRAPPAIR-env-S-attached: the no-split-stop mutant steps over the token and allows it, so WRAPOPT-env-S-attached can fail" block-destructive-pnosplit.sh a
wrap_arm "WRAPOPT-env-S-attached-cluster: env -iS<unlisted>.sh keeps its exec row" "env -iS${WRAP_NA}" W W exec
wrap_pair "WRAPPAIR-env-S-attached-cluster: the no-split-stop mutant allows it, so WRAPOPT-env-S-attached-cluster can fail" block-destructive-pnosplit.sh a
wrap_arm "WRAPOPT-env-S-attached-long: env --split-string=<unlisted>.sh keeps its exec row" "env --split-string=${WRAP_NA}" W W exec
wrap_pair "WRAPPAIR-env-S-attached-long: the no-split-stop mutant allows it, so WRAPOPT-env-S-attached-long can fail" block-destructive-pnosplit.sh a
wrap_arm "WRAPDIV-env-S-attached-cmd: env -Sbash <unlisted>.sh allowed (an attached command line is not re-tokenized, as before)" \
  "env -Sbash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-env-S-attached-cmd: the scan mutant reads on to the script and records it, so WRAPDIV-env-S-attached-cmd can fail" block-destructive-pscan.sh W
# The two declared precision improvements: an option argument shaped like a script path, and
# an env operand whose name is not a shell name. Neither path is executed by the program; the
# walk used to read the whole token as a direct execution (the mutant limb records it).
wrap_arm "WRAPOPT-optpath: env --chdir=/tmp/x.sh ls allowed with no row (precision: an option's argument)" "env --chdir=/tmp/x.sh ls" a W
wrap_arm "WRAPOPT-optpath-short: sudo -D/tmp/x.sh ls allowed with no row (precision)" "sudo -D/tmp/x.sh ls" a W
wrap_arm "WRAPOPT-envop-name: env a-b=/tmp/x.sh ls allowed with no row (precision: env sets a-b and runs ls)" "env a-b=/tmp/x.sh ls" a W

# --- a long option, read the way its program's parser reads it (Stage 7 finding F-01) -----
# Every row that lists a long option belongs to a getopt_long program, and getopt_long takes an
# exact name, or any prefix that names exactly one of its long options, for that option. `env
# --split=<path>` is env's split string and GNU env executes the path; matched as written it
# was an option no row lists, so the walk stepped over it and a recorded execution became an
# allow. A long token is now resolved against the program's own option table first, and the
# row is asked about the option it resolves to. These arms run the iteration's reverse mutant
# as their second limb — the walk before that change — so a pair arm whose limbs differ is red
# before it.
WRAP_MUTANT="block-destructive-ab.sh"
WRAP_NA_PY='/tmp/pmo-wrap-na.py'
wrap_arm "WRAPOPT-ab-split-01: env --split=<unlisted>.sh keeps its exec row (a prefix of --split-string)" "env --split=${WRAP_NA}" W a exec
wrap_arm "WRAPOPT-ab-split-02: env --s=<unlisted>.sh keeps its exec row (the shortest prefix of --split-string)" "env --s=${WRAP_NA}" W a exec
wrap_arm "WRAPOPT-ab-split-03: env --sp=<unlisted>.sh keeps its exec row" "env --sp=${WRAP_NA}" W a exec
wrap_arm "WRAPOPT-ab-split-04: env --split-strin=<unlisted>.sh keeps its exec row (one character short of the name)" "env --split-strin=${WRAP_NA}" W a exec
wrap_arm "WRAPOPT-ab-split-05: env --split=<unlisted>.py keeps its exec row" "env --split=${WRAP_NA_PY}" W a exec
wrap_arm "WRAPOPT-ab-split-cluster: env -i --split=<unlisted>.sh keeps its exec row (behind a flag)" "env -i --split=${WRAP_NA}" W a exec
wrap_arm "WRAPOPT-ab-split-ok: env --split=<allowlisted>.sh keeps the exec row the full spelling keeps" "env --split=${WRAP_OK}" W a exec

# The shortest prefix of every long option a row lists as taking an argument, computed on the
# program's own option table: each one IS that option, so the value after it is consumed and
# the interpreter behind it is adjudicated. The walk before this change stepped over the prefix
# as an option no row lists and read the value as the command word. The split string's own
# shortest prefix, --s, is WRAPOPT-ab-split-02 above.
WRAP_AB_TABLE='nice|--adjustment|nice --a 10
stdbuf|--input|stdbuf --i 0
stdbuf|--output|stdbuf --o 0
stdbuf|--error|stdbuf --e 0
sudo|--auth-type|sudo --au bsdauth
sudo|--close-from|sudo --cl 3
sudo|--login-class|sudo --login- staff
sudo|--chdir|sudo --chd x
sudo|--group|sudo --g staff
sudo|--host|sudo --ho box1
sudo|--prompt|sudo --pro p
sudo|--chroot|sudo --chr x
sudo|--role|sudo --ro r
sudo|--command-timeout|sudo --co 5
sudo|--type|sudo --t t
sudo|--other-user|sudo --o bot
sudo|--user|sudo --u bot
env|--argv0|env --a zero
env|--chdir|env --c x
env|--unset|env --u X
xargs|--arg-file|xargs --a list
xargs|--delimiter|xargs --d x
xargs|--max-args|xargs --max-a 1
xargs|--max-chars|xargs --max-c 100
xargs|--max-procs|xargs --max-p 4
xargs|--process-slot-var|xargs --p VAR
time|--format|time --f %e
time|--output-file|time --o x
timeout|--kill-after|timeout --k 1 5
timeout|--signal|timeout --s KILL 5'
while IFS='|' read -r wrap_abw wrap_abopt wrap_abpfx; do
  [ -n "$wrap_abw" ] || continue
  wrap_arm "WRAPOPT-ab-${wrap_abw}${wrap_abopt}: ${wrap_abpfx} bash <unlisted>.sh blocks (the shortest prefix of ${wrap_abopt})" \
    "${wrap_abpfx} bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
done <<<"$WRAP_AB_TABLE"
wrap_arm "WRAPOPT-ab-time-output-file: time --output-file x bash <unlisted>.sh blocks (the name GNU time's own option table gives -o)" \
  "time --output-file x bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-ab-ctl-near: nice --a 10 bash <allowlisted>.sh allowed (the allowlist was consulted)" "nice --a 10 bash ${WRAP_OK}" a a
wrap_pair "WRAPPAIR-ab-ctl-near: the allowlist-blind mutant refuses it, so WRAPOPT-ab-ctl-near can fail" block-destructive-pallow.sh B
wrap_arm "WRAPDIV-ab-ambiguous: sudo --c x bash <unlisted>.sh allowed (--c prefixes four sudo options: the program rejects it and runs nothing, and the walk keeps it as written)" \
  "sudo --c x bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-ab-ambiguous: the ambiguity-blind mutant takes --c for one option, consumes x and refuses, so WRAPDIV-ab-ambiguous can fail" block-destructive-pambig.sh B
wrap_arm "WRAPDIV-ab-split-cmd (declared, introduced here): env --s=bash <unlisted>.sh allowed — an attached command line written with a prefix takes the full spelling's verdict (WRAPDIV-env-S-attached-cmd)" \
  "env --s=bash ${WRAP_NA}" a W
WRAP_MUTANT="block-destructive-mut.sh"

# --- the second and third build conditions: the xargs deny, behind xargs's own options ----
wrap_arm "WRAPOPT-xargs-stdin-n: printf x | xargs -n 1 bash blocks as unresolvable" "printf x | xargs -n 1 bash" B a "unresolvable script target"
wrap_arm "WRAPOPT-xargs-stdin-0: printf x | xargs -0 sh blocks as unresolvable" "printf x | xargs -0 sh" B a "unresolvable script target"
wrap_arm "WRAPOPT-xargs-stdin-py (declared: no record-only stage): printf x | xargs -n 1 python3 blocks as unresolvable" \
  "printf x | xargs -n 1 python3" B a "unresolvable script target"
wrap_arm "WRAPDIV-xargs-stdin-py-bare: printf x | xargs python3 blocks, as it did before this change" "printf x | xargs python3" B B "unresolvable script target"
wrap_pair "WRAPPAIR-xargs-stdin-py-bare: the xargs-deny-off mutant allows it, so WRAPDIV-xargs-stdin-py-bare can fail" block-destructive-pxoff.sh a
wrap_arm "WRAPDIV-xargs-interp-flag (closed: the post-walk half of the stdin deny refuses it; its red-before limb is XARGS-IFLAG-WR52): printf x | xargs -n 1 bash -x refused" \
  "printf x | xargs -n 1 bash -x" B -
wrap_arm "WRAPDIV-xargs-interp-flag-bare (closed; its red-before limb is XARGS-IFLAG-WR43): printf x | xargs bash -x refused" "printf x | xargs bash -x" B -
wrap_arm "WRAPOPT-xargs-ctl-c: ls | xargs -n1 bash -c 'echo hi' allowed" "ls | xargs -n1 bash -c 'echo hi'" a a
wrap_pair "WRAPPAIR-xargs-ctl-c: the every-xargs-interpreter deny refuses it, so WRAPOPT-xargs-ctl-c can fail" block-destructive-pxall.sh B
wrap_arm "WRAPOPT-xargs-ctl-grep: git ls-files | xargs -n1 grep -l bash allowed" "git ls-files | xargs -n1 grep -l bash" a a
wrap_pair "WRAPPAIR-xargs-ctl-grep: the scan mutant reads past grep to an xargs-fed bash and refuses, so WRAPOPT-xargs-ctl-grep can fail" block-destructive-pscan.sh B
wrap_arm "WRAPOPT-xargs-ctl-pycompile: git ls-files | xargs -n1 python3 -m py_compile allowed" "git ls-files | xargs -n1 python3 -m py_compile" a a
wrap_pair "WRAPPAIR-xargs-ctl-pycompile: the stdin deny refuses it, so WRAPOPT-xargs-ctl-pycompile can fail" block-destructive-pstdin.sh B

# --- if, while and until join the keyword arm ------------------------------------------------
wrap_arm "WRAPKW-if: if bash <unlisted>.sh; then :; fi blocks" "if bash ${WRAP_NA}; then :; fi" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPKW-while: while bash <unlisted>.sh; do :; done blocks" "while bash ${WRAP_NA}; do :; done" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPKW-until: until bash <unlisted>.sh; do :; done blocks" "until bash ${WRAP_NA}; do :; done" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPKW-if-bang: if ! bash <unlisted>.sh; then :; fi blocks" "if ! bash ${WRAP_NA}; then :; fi" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPKW-ctl-test: if [ -f <unlisted>.sh ]; then :; fi allowed" "if [ -f ${WRAP_NA} ]; then :; fi" a a
wrap_pair "WRAPPAIR-kw-ctl-test: the scan mutant reads the tested path as the command and records it, so WRAPKW-ctl-test can fail" block-destructive-pscan.sh W
wrap_arm "WRAPKW-ctl-read: while read -r l; do :; done < <unlisted>.sh allowed" "while read -r l; do :; done < ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-kw-ctl-read: the scan mutant reads the redirected path as the command and records it, so WRAPKW-ctl-read can fail" block-destructive-pscan.sh W
wrap_arm "WRAPKW-ctl-ok: if bash <allowlisted>.sh; then :; fi allowed" "if bash ${WRAP_OK}; then :; fi" a a
wrap_pair "WRAPPAIR-kw-ctl-ok: the allowlist-blind mutant refuses it, so WRAPKW-ctl-ok can fail" block-destructive-pallow.sh B
# The reviewer's pin: quoted prose after a separator, in an argument of a command that is no
# carrier, is split and read as a condition. A declared over-block, introduced by this line
# for three common words and already true of then and do.
wrap_arm "WRAPDIV-kw-prose (declared over-block, introduced here): git commit -m \"note; if bash <unlisted>.sh then\" blocks" \
  "git commit -m \"note; if bash ${WRAP_NA} then\"" B a "BLOCK-DESTRUCTIVE-022"

# --- the quoted assignment value --------------------------------------------------------------
# A value whose quoting or escaping spans a blank is read to the end of its word since #8319; its
# arms are the ASGN-QVAL block at the end of this suite, which reads its rows from the corpus. Still
# pinned here at the verdict the walk gives today: a separator inside the quoted value, which splits
# the segment before the walk sees it — a different root cause, carried as a release follow-up.
wrap_arm "WRAPDIV-qval-sep: FOO='a;b' bash <unlisted>.sh allowed (a separator inside the quoted value splits the segment)" \
  "FOO='a;b' bash ${WRAP_NA}" a a
wrap_pair "WRAPPAIR-qval-sep: the scan mutant reads past the split piece and refuses, so WRAPDIV-qval-sep can fail" block-destructive-pscan.sh B

# --- Stage 7 F-08: an attached split string carrying no command word, then the command -------
# env's split string is its own argv prepended to what follows, so when the attached value is
# empty, a flag, or an assignment, env's command is the token that FOLLOWS and the walk now goes
# on to adjudicate it, where before it stepped onto the split token and read nothing further.
# The table runs every prefix the parser takes for --split-string, against each of the three
# values. These run the splitcmd reverse mutant (stop on any attached split value, the
# pre-helper walk) as the second limb, so each is red before the fix.
WRAP_MUTANT="block-destructive-splitcmd.sh"
WRAP_SN_TABLE='s|--s=|shortest prefix of --split-string
sp|--sp=|a prefix of --split-string
spl|--spl=|a prefix of --split-string
spli|--spli=|a prefix of --split-string
split|--split=|a prefix of --split-string
split-|--split-=|a prefix of --split-string
split-s|--split-s=|a prefix of --split-string
split-st|--split-st=|a prefix of --split-string
split-str|--split-str=|a prefix of --split-string
split-stri|--split-stri=|a prefix of --split-string
split-strin|--split-strin=|the longest proper prefix of --split-string
full|--split-string=|the full long spelling'
while IFS='|' read -r wrap_sntag wrap_snp wrap_snd; do
  [ -n "$wrap_sntag" ] || continue
  wrap_arm "WRAPOPT-sn-empty-${wrap_sntag}: env ${wrap_snp} bash <unlisted>.sh blocks (${wrap_snd}, empty value)" \
    "env ${wrap_snp} bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
  wrap_arm "WRAPOPT-sn-opt-${wrap_sntag}: env ${wrap_snp}-i bash <unlisted>.sh blocks (value is a flag)" \
    "env ${wrap_snp}-i bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
  wrap_arm "WRAPOPT-sn-assign-${wrap_sntag}: env ${wrap_snp}FOO=1 bash <unlisted>.sh blocks (value is an assignment)" \
    "env ${wrap_snp}FOO=1 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
done <<<"$WRAP_SN_TABLE"
wrap_arm "WRAPOPT-sn-short-opt: env -S-i bash <unlisted>.sh blocks (the short form, a flag value)" \
  "env -S-i bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
wrap_arm "WRAPOPT-sn-short-assign: env -SFOO=1 bash <unlisted>.sh blocks (the short form, an assignment value)" \
  "env -SFOO=1 bash ${WRAP_NA}" B a "BLOCK-DESTRUCTIVE-022"
# an arg-taking option in the split value consumes the token that follows, so the real command,
# not the consumed token, is adjudicated: env --s=-u <allowlisted>.sh <unlisted>.sh records the
# unlisted script (env runs it; the allowlisted path was -u's argument, never the command word)
wrap_arm "WRAPOPT-sn-optarg: env --s=-u <allowlisted>.sh <unlisted>.sh records the unlisted script (the -u in the split value consumes the allowlisted path)" \
  "env --s=-u ${WRAP_OK} ${WRAP_NA}" W a exec
# near miss: the command that follows the empty split value is on the allowlist
wrap_arm "WRAPOPT-sn-near: env --s= bash <allowlisted>.sh allowed (the following command is allowlisted)" \
  "env --s= bash ${WRAP_OK}" a a
wrap_pair "WRAPPAIR-sn-near: the allowlist-blind mutant refuses the allowlisted script the walk goes on to, so WRAPOPT-sn-near can fail" block-destructive-pallow.sh B
WRAP_MUTANT="block-destructive-mut.sh"

/bin/rm -rf "$WRAP_ROOT"

echo ""
echo "BLOCK-022 flag walk: a quote-led word that spells a dash flag, its quote closing inside the operand suffix (FWALK-QDASH-*)"
echo "---"
# SUBJECT. The flag walk reads a token that opens with a quote and closes every quote it opens
# as the word the shell makes of it (block (7b), FWALK-QWORD-*). One subclass of that family
# still ended the walk with nothing adjudicated: a word whose exact value begins with `-` and
# ends in the arm's operand suffix, with the quote closing INSIDE the suffix. `'-x.s'h` is the
# word `-x.sh`. Its probe (`-x.s`) and its raw token (ending `'h`) land in no domain, so only
# the word's own value claimed it; the walk ended on it as the operand, and the operand path,
# which reads the probe and the raw token and never the word, adjudicated nothing. Its unquoted
# twin begins with `-`, so the raw view steps over it and the script behind it is adjudicated.
# A word whose exact value begins with `-` is now stepped over the same way, even when that
# value lands in the operand domain. The normalizer, the probe and the raw token still claim
# first. These arms grade that, the controls and pins it must leave alone, and the two
# residuals it leaves declared rather than closed.
#
# HERMETIC, ON THE WRAP BLOCK'S PATTERN AND FOR ITS REASON: this block's own root, an allowlist
# naming one shell and one Python fixture, its own .mode, the scope variables unset for every
# run, and mutant copies beside the hook copy, so every verdict below turns on this fixture and
# nothing ambient. A verdict is read as the corpus reader reads one: exit 2 is B, exit 0 with a
# new would-fire row in this fixture's drain is W, exit 0 with none is a.
#
# THE REVERSE MUTANT deletes the one marked line (M-QDASH) and nothing else, which is the walk
# as it was before this change; FWALK-QDASH-M0 pins that difference. Every pair arm runs the
# hook AND the reverse mutant. Until #8318 the mutant limb of a must-refuse arm was its
# red-before evidence in the same run: the word ended the walk and the operand path read
# nothing. Since #8318 the operand path reads the word after quote removal, so under the
# reverse mutant the word itself is adjudicated as the operand — the wrong subject — and is
# refused (shell arms) or recorded (non-shell arms). The limb now reads that verdict, and the
# line's own difference shows on the near misses: the reverse mutant refuses or records the
# allowlisted script's invocation that the hook allows.
#
# ARM CLASSES, so the red-before obligation can be read off the label. FWALK-QDASH-01 to -14
# are the fourteen spellings the finding measured, must-refuse on the shell arms and must-flag
# on the phase-gated non-shell arm: red before this change. A -ctl- arm must stay allowed and a
# -pin- arm is a verdict this change does not move; both are green before by design, and each
# is shown able to fail by a sibling mutant: the deny mutant (-M1*) refuses each control and the
# declared residual, the claim-blind mutant (-M2*) allows each pin the probe or raw token holds,
# and the top-rule mutant (-M3*) allows each pin the normalizer holds. -SCOPE, the -M*a shape
# arms and the mutant payload arms read mutation sites or behaviour this change adds, and are
# not red-before evidence.
#
# NO PIPE INTO A SHORT-CIRCUITING READER ANYWHERE IN THIS BLOCK (the SIGPIPE-idiom gate):
# the diff shape is counted by one awk pass that reads to the end, and stderr is matched from a
# here-string.
QDASH_ROOT="$(/usr/bin/mktemp -d)"
QDASH_CLAUDE="${QDASH_ROOT}/.claude"
QDASH_HOOKS="${QDASH_CLAUDE}/hooks"
/bin/mkdir -p "${QDASH_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${QDASH_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${QDASH_HOOKS}/lib/" 2>/dev/null || true
QDASH_OK='/tmp/pmo-qdash-ok.sh'
QDASH_OKPY='/tmp/pmo-qdash-ok.py'
QDASH_NA='/tmp/pmo-qdash-na'
/usr/bin/printf '%s\n' "$QDASH_OK" "$QDASH_OKPY" > "${QDASH_CLAUDE}/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${QDASH_HOOKS}/.mode"
/bin/cp "$HOOK" "${QDASH_HOOKS}/block-destructive.sh"
# The reverse mutant: the marked line deleted, so a word that spells a dash flag is claimed by
# its value again and the walk ends on it.
/usr/bin/sed '/# M-QDASH (mutation/d' "$HOOK" > "${QDASH_HOOKS}/block-destructive-rev.sh"
# The deny mutant: the view refuses a token the normalizer declines and the probe and raw token
# leave unclaimed (the FWALK-QWORD-M2 shape, with this block's own reason text).
/usr/bin/sed 's|^  script_word_scan "\$1"$|  if ! script_operand_implicated "$script_interp_domain"; then block "BLOCK-DESTRUCTIVE-022" "QDASH deny mutant" "test only"; fi; script_word_scan "$1"|' \
  "$HOOK" > "${QDASH_HOOKS}/block-destructive-deny.sh"
# The claim-blind mutant: the view's probe-and-raw claim deleted (the FWALK-QWORD-M3 shape).
/usr/bin/sed '/^  if script_operand_implicated "\$script_interp_domain"; then return 0; fi$/d' \
  "$HOOK" > "${QDASH_HOOKS}/block-destructive-blind.sh"
# The top-rule mutant: the walk's top-of-loop line rewrites every flag-shaped reading, with no
# domain question asked of a token the normalizer resolved.
/usr/bin/sed '/# M-QDASH-TOP (mutation/s/if .*; then/if true; then/' \
  "$HOOK" > "${QDASH_HOOKS}/block-destructive-wide.sh"
/bin/chmod +x "${QDASH_HOOKS}/block-destructive.sh" "${QDASH_HOOKS}/block-destructive-rev.sh" \
  "${QDASH_HOOKS}/block-destructive-deny.sh" "${QDASH_HOOKS}/block-destructive-blind.sh" \
  "${QDASH_HOOKS}/block-destructive-wide.sh"
QDASH_DRAIN="${QDASH_HOOKS}/destructive-warn-log.jsonl"

qdash_drain_rows() {
  if [ -f "$QDASH_DRAIN" ]; then
    /usr/bin/wc -l < "$QDASH_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

# The difference between the hook copy and one mutant, as "<lines removed>/<lines added>".
qdash_diff_shape() { # $1 = mutant file in the hermetic hooks dir
  /usr/bin/diff "${QDASH_HOOKS}/block-destructive.sh" "${QDASH_HOOKS}/$1" \
    | /usr/bin/awk 'index($0, "<") == 1 { r++ } index($0, ">") == 1 { a++ } END { printf "%d/%d", r, a }'
}

QDASH_EXIT=0
QDASH_ERR=""
QDASH_V=""
QDASH_LAST=""
# Run one payload through one of the sandbox copies -> QDASH_V (a|B|W|E<rc>), QDASH_ERR, and
# QDASH_LAST, the would-fire row the call added (empty when it added none).
qdash_run() { # $1 = hook file in the hermetic hooks dir  $2 = command
  local tmp before after
  tmp="$(/usr/bin/mktemp)"
  QDASH_EXIT=0
  QDASH_LAST=""
  before="$(qdash_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$QDASH_ROOT")" \
      | /bin/bash "${QDASH_HOOKS}/$1" 2>"$tmp" >/dev/null ) || QDASH_EXIT="$?"
  after="$(qdash_drain_rows)"
  QDASH_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
  case "$QDASH_EXIT" in
    2) QDASH_V="B" ;;
    0)
      if [ "$after" -gt "$before" ]; then
        QDASH_V="W"
        QDASH_LAST="$(/usr/bin/tail -n 1 "$QDASH_DRAIN")"
      else
        QDASH_V="a"
      fi
      ;;
    *) QDASH_V="E${QDASH_EXIT}" ;;
  esac
}

# A pair arm. $1 label  $2 command  $3 verdict wanted from the hook (a|B|W)  $4 verdict wanted
# from the reverse mutant (a|B|W)  $5 (optional) for a wanted B, a pattern the hook's refusal
# must carry; for a wanted W, the arm its would-fire row must name.
qdash_arm() {
  local name="$1" cmd="$2" want="$3" wantm="$4" detail="${5:-}" got gotm ok=1 why=""
  qdash_run block-destructive.sh "$cmd"
  got="$QDASH_V"
  if [ "$got" != "$want" ]; then ok=0; why="hook=${got}"; fi
  if [ "$ok" = 1 ] && [ -n "$detail" ]; then
    case "$want" in
      B) if ! /usr/bin/grep -qE "$detail" <<<"$QDASH_ERR"; then ok=0; why="refusal lacks /${detail}/"; fi ;;
      W) case "$QDASH_LAST" in *"\"arm\":\"${detail}\""*) ;; *) ok=0; why="row arm is not ${detail}" ;; esac ;;
    esac
  fi
  qdash_run block-destructive-rev.sh "$cmd"
  gotm="$QDASH_V"
  if [ "$gotm" != "$wantm" ]; then ok=0; why="${why} reverse=${gotm}"; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (hook %s, reverse %s)\n' "$name" "$got" "$gotm"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted hook=%s reverse=%s; observed %s\n  stderr: %s\n' "$name" "$want" "$wantm" "${why# }" "$QDASH_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# A mutant arm. $1 label  $2 mutant file  $3 command  $4 verdict wanted from the mutant
# $5 (optional) for a wanted B, a pattern the mutant's refusal must carry.
qdash_mut_arm() {
  local name="$1" mut="$2" cmd="$3" want="$4" detail="${5:-}" ok=1 why=""
  qdash_run "$mut" "$cmd"
  if [ "$QDASH_V" != "$want" ]; then ok=0; why="mutant=${QDASH_V}"; fi
  if [ "$ok" = 1 ] && [ "$want" = "B" ] && [ -n "$detail" ] \
     && ! /usr/bin/grep -qE "$detail" <<<"$QDASH_ERR"; then
    ok=0; why="refusal lacks /${detail}/"
  fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (mutant %s)\n' "$name" "$QDASH_V"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted mutant=%s; observed %s\n  stderr: %s\n' "$name" "$want" "$why" "$QDASH_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# A mutant's shape arm. $1 label  $2 mutant file  $3 the shape it must have
qdash_shape_arm() {
  local got
  got="$(qdash_diff_shape "$2")"
  if [ "$got" = "$3" ]; then
    /usr/bin/printf 'PASS: %s (removed/added %s)\n' "$1" "$got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  removed/added %s, wanted %s — the arms that read this mutant are unusable\n' "$1" "$got" "$3"
    FAIL=$((FAIL + 1))
  fi
}

# --- the fixture is live before any verdict is read -------------------------------------
qdash_run block-destructive.sh 'git push --force origin main'
qdash_scope_hook="$QDASH_V"
qdash_scope_err="$QDASH_ERR"
qdash_run block-destructive-rev.sh 'git push --force origin main'
qdash_scope_rev="$QDASH_V"
if [ "$qdash_scope_hook" = "B" ] && [ "$qdash_scope_rev" = "B" ] \
   && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-001' <<<"$qdash_scope_err"; then
  /usr/bin/printf 'PASS: FWALK-QDASH-SCOPE the hook copy and its reverse mutant are in scope and enforcing (unrelated rule -001 fires on both), so the verdicts below are live\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: FWALK-QDASH-SCOPE fixture not live (hook=%s reverse=%s); the verdicts below are unusable\n' "$qdash_scope_hook" "$qdash_scope_rev"
  FAIL=$((FAIL + 1))
fi
qdash_shape_arm "FWALK-QDASH-M0: the reverse mutant differs from the hook by the one marked line, removed" \
  block-destructive-rev.sh "1/0"

# --- MUST REFUSE: the always-enforce shell arms ---------------------------------------------
qdash_arm "FWALK-QDASH-01: bash '-x.s'h <unlisted>.sh blocks (the word is -x.sh, a flag; the script behind it is adjudicated)" \
  "bash '-x.s'h ${QDASH_NA}.sh" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-02: bash -n '-x.s'h <unlisted>.sh blocks (stepping over the word revokes the grant)" \
  "bash -n '-x.s'h ${QDASH_NA}.sh" B a "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-03: bash '--rcfile=x.s'h <unlisted>.sh blocks" \
  "bash '--rcfile=x.s'h ${QDASH_NA}.sh" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-04: zsh '-oxtrace.s'h <unlisted>.sh blocks (the word is a cluster carrying c, as unquoted)" \
  "zsh '-oxtrace.s'h ${QDASH_NA}.sh" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-05: zsh '--emulate=sh.s'h <unlisted>.sh blocks" \
  "zsh '--emulate=sh.s'h ${QDASH_NA}.sh" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-06: source '-x.s'h <unlisted>.sh blocks (the source arm walks the same loop)" \
  "source '-x.s'h ${QDASH_NA}.sh" B B "BLOCK-DESTRUCTIVE-022"

# --- MUST FLAG: the phase-gated non-shell arm, at its rollout phase --------------------------
qdash_arm "FWALK-QDASH-07: python3 '-Wx.p'y <unlisted>.py is adjudicated (the word is -Wx.py)" \
  "python3 '-Wx.p'y ${QDASH_NA}.py" W W interp-nonshell
qdash_arm "FWALK-QDASH-08: python3 '-Xfoo.p'y <unlisted>.py is adjudicated" \
  "python3 '-Xfoo.p'y ${QDASH_NA}.py" W W interp-nonshell
qdash_arm "FWALK-QDASH-09: python3 '-Wignore::x.p'y <unlisted>.py is adjudicated" \
  "python3 '-Wignore::x.p'y ${QDASH_NA}.py" W W interp-nonshell
qdash_arm "FWALK-QDASH-10: perl '-Ifoo.p'm <unlisted>.pl is adjudicated" \
  "perl '-Ifoo.p'm ${QDASH_NA}.pl" W W interp-nonshell
qdash_arm "FWALK-QDASH-11: perl '-Ifoo.p'l <unlisted>.pl is adjudicated" \
  "perl '-Ifoo.p'l ${QDASH_NA}.pl" W W interp-nonshell
qdash_arm "FWALK-QDASH-12: ruby '-Ifoo.r'b <unlisted>.rb is adjudicated" \
  "ruby '-Ifoo.r'b ${QDASH_NA}.rb" W W interp-nonshell
qdash_arm "FWALK-QDASH-13: node '--title=x.j's <unlisted>.js is adjudicated" \
  "node '--title=x.j's ${QDASH_NA}.js" W W interp-nonshell
qdash_arm "FWALK-QDASH-14: perl '-Mstrict.p'm <unlisted>.pl is adjudicated" \
  "perl '-Mstrict.p'm ${QDASH_NA}.pl" W W interp-nonshell

# --- MUST STAY ALLOWED: the allowlist still governs the script behind the word --------------
qdash_arm "FWALK-QDASH-ctl-near: bash '-x.s'h <allowlisted>.sh allowed (the near miss)" \
  "bash '-x.s'h ${QDASH_OK}" a B
qdash_arm "FWALK-QDASH-ctl-near-py: python3 '-Wx.p'y <allowlisted>.py allowed (the near miss the finding named)" \
  "python3 '-Wx.p'y ${QDASH_OKPY}" a W
qdash_arm "FWALK-QDASH-ctl-near-n: bash -n '-x.s'h <allowlisted>.sh allowed (revoked, and the allowlist still governs)" \
  "bash -n '-x.s'h ${QDASH_OK}" a a

# --- PINS: a claim made before the word is read still ends the walk -------------------------
# A token the normalizer resolves, or one the probe or the raw token places in the operand
# domain, is the operand and is adjudicated as before: stricter than its unquoted twin, with the
# two exceptions the readiness fragment names — behind a parse-only grant, which a token that ends
# the walk keeps while its unquoted twin is stepped over and revokes it, and where the allowlist
# admits the token's own value. In both the shell rejects the option and runs nothing. A word that
# does not begin with `-` keeps the claim-order verdict.
qdash_arm "FWALK-QDASH-pin-resolved (pin, not fix-evidence): bash '-x.sh' <allowlisted>.sh still blocks (the normalizer resolves the token; a domain claim beats a flag shape)" \
  "bash '-x.sh' ${QDASH_OK}" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-pin-raw (pin, not fix-evidence): bash \"-\"x.sh <allowlisted>.sh still blocks (the raw token claims it)" \
  "bash \"-\"x.sh ${QDASH_OK}" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-pin-empty (pin, not fix-evidence): bash ''-x.sh <allowlisted>.sh still blocks (the raw token claims it)" \
  "bash ''-x.sh ${QDASH_OK}" B B "BLOCK-DESTRUCTIVE-022"
qdash_arm "FWALK-QDASH-pin-resolved-py (pin, not fix-evidence): python3 '-Wx.py' still warns" \
  "python3 '-Wx.py'" W W interp-nonshell
qdash_arm "FWALK-QDASH-pin-raw-py (pin, not fix-evidence): python3 \"-W\"x.py still warns" \
  "python3 \"-W\"x.py" W W interp-nonshell
qdash_arm "FWALK-QDASH-pin-empty-py (pin, not fix-evidence): python3 ''-Wx.py still warns" \
  "python3 ''-Wx.py" W W interp-nonshell
qdash_arm "FWALK-QDASH-pin-raw-js (pin, not fix-evidence): node \"\"--title=x.js still warns" \
  "node \"\"--title=x.js" W W interp-nonshell
qdash_arm "FWALK-QDASH-pin-claimed (pin, not fix-evidence): bash '<unlisted>.sh'y still blocks (the claim-order example; the word does not begin with -)" \
  "bash '${QDASH_NA}.sh'y" B B "BLOCK-DESTRUCTIVE-022"
# Re-pointed by #8318 from the declared residual's allow. A word whose own value lands in the
# domain without beginning with `-` is the operand, as its unquoted spelling is, and the operand
# path now reads the word after quote removal where the probe and the raw token claim nothing, so
# it takes that spelling's refusal (corpus row DS71, arm OPND-SPLIT-04).
qdash_arm "FWALK-QDASH-pin-plus (re-pointed: the split suffix is read at the operand): bash '+x.s'h <unlisted>.sh refused (the word +x.sh is the operand, adjudicated as its unquoted twin is)" \
  "bash '+x.s'h ${QDASH_NA}.sh" B B "BLOCK-DESTRUCTIVE-022"

# --- EACH CONTROL AND PIN, SHOWN ABLE TO FAIL -------------------------------------------------
qdash_shape_arm "FWALK-QDASH-M1a: the deny mutant differs from the hook by one line, rewritten" \
  block-destructive-deny.sh "1/1"
qdash_mut_arm "FWALK-QDASH-M1b: the deny mutant REFUSES the near miss bash '-x.s'h <allowlisted>.sh" \
  block-destructive-deny.sh "bash '-x.s'h ${QDASH_OK}" B "QDASH deny mutant"
qdash_mut_arm "FWALK-QDASH-M1c: the deny mutant REFUSES python3 '-Wx.p'y <allowlisted>.py" \
  block-destructive-deny.sh "python3 '-Wx.p'y ${QDASH_OKPY}" B "QDASH deny mutant"
qdash_mut_arm "FWALK-QDASH-M1d: the deny mutant REFUSES bash -n '-x.s'h <allowlisted>.sh" \
  block-destructive-deny.sh "bash -n '-x.s'h ${QDASH_OK}" B "QDASH deny mutant"
qdash_mut_arm "FWALK-QDASH-M1e: the deny mutant REFUSES bash '+x.s'h <unlisted>.sh (the shipped hook refuses it too since #8318)" \
  block-destructive-deny.sh "bash '+x.s'h ${QDASH_NA}.sh" B "QDASH deny mutant"
qdash_shape_arm "FWALK-QDASH-M2a: the claim-blind mutant differs from the hook by one line, removed" \
  block-destructive-blind.sh "1/0"
qdash_mut_arm "FWALK-QDASH-M2b: the claim-blind mutant ALLOWS bash \"-\"x.sh <allowlisted>.sh (the raw token's claim is what holds a dash word as the operand)" \
  block-destructive-blind.sh "bash \"-\"x.sh ${QDASH_OK}" a
qdash_mut_arm "FWALK-QDASH-M2c: the claim-blind mutant ALLOWS bash ''-x.sh <allowlisted>.sh" \
  block-destructive-blind.sh "bash ''-x.sh ${QDASH_OK}" a
qdash_mut_arm "FWALK-QDASH-M2d: the claim-blind mutant ALLOWS python3 \"-W\"x.py (no row)" \
  block-destructive-blind.sh "python3 \"-W\"x.py" a
qdash_mut_arm "FWALK-QDASH-M2e: the claim-blind mutant ALLOWS python3 ''-Wx.py (no row)" \
  block-destructive-blind.sh "python3 ''-Wx.py" a
qdash_mut_arm "FWALK-QDASH-M2f: the claim-blind mutant ALLOWS node \"\"--title=x.js (no row)" \
  block-destructive-blind.sh "node \"\"--title=x.js" a
qdash_mut_arm "FWALK-QDASH-M2g: the claim-blind mutant ALLOWS bash '<unlisted>.sh'y" \
  block-destructive-blind.sh "bash '${QDASH_NA}.sh'y" a
qdash_shape_arm "FWALK-QDASH-M3a: the top-rule mutant differs from the hook by one line, rewritten" \
  block-destructive-wide.sh "1/1"
qdash_mut_arm "FWALK-QDASH-M3b: the top-rule mutant ALLOWS bash '-x.sh' <allowlisted>.sh (the domain question is what holds a resolved token)" \
  block-destructive-wide.sh "bash '-x.sh' ${QDASH_OK}" a
qdash_mut_arm "FWALK-QDASH-M3c: the top-rule mutant ALLOWS python3 '-Wx.py' (no row)" \
  block-destructive-wide.sh "python3 '-Wx.py'" a

/bin/rm -rf "$QDASH_ROOT"

echo ""
echo "BLOCK-022 enclosure positions: a second view of the segments (AC-ENCL-*)"
echo "---"
# SUBJECT. The rule splits a command on `;`, `&`, `|` and newline and walks each segment's
# command position. An enclosure — `$( )`, backticks, `<( )`, `>( )`, `( )` — is not a
# separator, so the verb inside one never starts a segment and was never adjudicated: a shell
# interpreter or `source` inside one ran with nothing refused or recorded. The hook now runs a
# second view of the same segments that opens one command position after every `(` and every
# backtick (ENCLOSURE-VIEW in the hook). A shell or `source` finding there follows a third
# rollout family, DESTRUCTIVE_022_ENCL_PHASE, which ships at `warn`: recorded, not refused.
# These arms grade the shapes it closes, the two adjacent fail-opens closed with it, the near
# misses it must leave alone, and the limits it declares.
#
# HERMETIC, ON THE QDASH BLOCK'S PATTERN AND FOR ITS REASON: this block's own root, an
# allowlist naming one shell fixture, its own .mode, the scope variables unset for every run,
# and every copy beside the hook copy. A verdict is read as the corpus reader reads one: exit
# 2 is B, exit 0 with a new would-fire row in this fixture's drain is W, exit 0 with none is a.
#
# THREE COPIES GRADE EVERY SHAPE. The shipped copy, at the shipped phase (`warn`), must
# RECORD a shape (W, and a row carrying the arm and `"pos":"enclosure"`). The FORCED copy —
# the same hook with only DESTRUCTIVE_022_ENCL_PHASE set to `enforce` — must REFUSE it: that
# is the refusal the rollout's graduation would turn on, and AC-2 asks for it. The REVERSE
# mutant — the view's marked block, the pre-pass's ENCL-HDHEAD block and the three openers on
# the pre-pass's M-ENCL-SCAN line removed — is the hook before this change, so its limb of a
# shape arm is that arm's red-before evidence in the same run, and its limb of a pin is the
# mutant that fails the pin.
#
# ARM CLASSES, so the red-before obligation can be read off the label. AC-ENCL-01 to -16 and
# -TEXEC6b are the shapes: red before this change. An -N arm is a near miss that must stay
# allowed and a -RESIDUAL arm pins a declared limit; both are green before by design, and each
# is followed by a pairing arm (-pair) that runs its own command through a mutant of the hook
# and shows the verdict it asserts is able to fail. -SCOPE, the -M*a shape arms, the -P* phase
# arms and the mutant payload arms read mutation sites or behaviour this change adds, and are
# not red-before evidence.
#
# NO PIPE INTO A SHORT-CIRCUITING READER ANYWHERE IN THIS BLOCK (the SIGPIPE-idiom gate): the
# diff shape is counted by one awk pass that reads to the end, and stderr is matched from a
# here-string. No payload here carries an unclosed run of openers: those are slow by design
# (the readiness text states the cost), and the budget pins run on copies with the budget
# lowered instead.
ENCL_ROOT="$(/usr/bin/mktemp -d)"
ENCL_CLAUDE="${ENCL_ROOT}/.claude"
ENCL_HOOKS="${ENCL_CLAUDE}/hooks"
/bin/mkdir -p "${ENCL_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${ENCL_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${ENCL_HOOKS}/lib/" 2>/dev/null || true
ENCL_OK='/tmp/pmo-encl-ok.sh'
ENCL_NA='/tmp/pmo-encl-na.sh'
ENCL_NAPY='/tmp/pmo-encl-na.py'
/usr/bin/printf '%s\n' "$ENCL_OK" > "${ENCL_CLAUDE}/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${ENCL_HOOKS}/.mode"
/bin/cp "$HOOK" "${ENCL_HOOKS}/block-destructive.sh"
# The phase copies: only the enclosure family's phase constant differs.
/usr/bin/sed 's/^readonly DESTRUCTIVE_022_ENCL_PHASE=.*/readonly DESTRUCTIVE_022_ENCL_PHASE="enforce"   # shadow | warn | enforce/' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-forced.sh"
/usr/bin/sed 's/^readonly DESTRUCTIVE_022_ENCL_PHASE=.*/readonly DESTRUCTIVE_022_ENCL_PHASE="shadow"   # shadow | warn | enforce/' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-shadow.sh"
/usr/bin/sed 's/^readonly DESTRUCTIVE_022_ENCL_PHASE=.*/readonly DESTRUCTIVE_022_ENCL_PHASE="bogus"   # shadow | warn | enforce/' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-bogus.sh"
# The reverse mutant: the hook before this change.
/usr/bin/sed \
  -e '/# >>> ENCLOSURE-VIEW-BEGIN/,/# >>> ENCLOSURE-VIEW-END/d' \
  -e '/# >>> ENCL-HDHEAD-BEGIN/,/# >>> ENCL-HDHEAD-END/d' \
  -e '/# M-ENCL-SCAN/s/ "\$_lp" "\$_rp" "\$script_qbt"//' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-rev.sh"
# The design's five component mutants, one marked line or block each.
/usr/bin/sed '/# M-ENCL-RESUPP/s/) : ;;/) continue ;;/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-m1.sh"
/usr/bin/sed '/# >>> ENCL-HDHEAD-BEGIN/,/# >>> ENCL-HDHEAD-END/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-m2.sh"
/usr/bin/sed '/# M-ENCL-TAIL/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-m3.sh"
/usr/bin/sed '/# M-ENCL-CUT/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-m4.sh"
/usr/bin/sed '/# M-ENCL-ESC/s/-eq 1 \]/-eq 9 ]/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-m5.sh"
# Pairing mutants, each a design the view could have had or a step it could have missed:
#   deny     every position the view opens and adjudicates is refused outright
#   openall  the escape rule off as well, so an escaped opener opens a position, and refused
#   supp     a segment interior to a carrier's quote is not suppressed in the second view
#   route    the shell-arm router sends a first-view finding to the enclosure phase too
#   split    the first view reads `)` as a separator
#   noex     the here-document pre-pass excises nothing for the four carriers (the cat
#            receiver, #8326, is its own pattern line, which this copy does not rewrite)
#   suppall  the first view's carrier suppression is switched off
#   smallp   the position ceiling lowered to 4
#   smallb   the remainder budget lowered to 64 bytes
/usr/bin/sed 's@script_rowpos="enclosure"   # M-ENCL-GATE@block "BLOCK-DESTRUCTIVE-022" "ENCL gate deny mutant" "test only"@' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-deny.sh"
/usr/bin/sed \
  -e 's@script_rowpos="enclosure"   # M-ENCL-GATE@block "BLOCK-DESTRUCTIVE-022" "ENCL gate deny mutant" "test only"@' \
  -e '/# M-ENCL-ESC/s/-eq 1 \]/-eq 9 ]/' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-openall.sh"
/usr/bin/sed '/# M-ENCL-SUPP/s/if \[ "\$script_supp" -eq 1 \]; then/if [ "$script_supp" -eq 1 ] \&\& [ "$script_pass" -eq 1 ]; then/' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-supp.sh"
/usr/bin/sed '/# M-ENCL-ROUTE/s/-ne 2 \]/-eq 9 ]/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-route.sh"
/usr/bin/sed 's@script_segments//|/@script_segments//[|)]/@' "$HOOK" > "${ENCL_HOOKS}/block-destructive-split.sh"
/usr/bin/sed 's/^        gh|printf|echo|jq)$/        gh-never)/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-noex.sh"
/usr/bin/sed 's/^      elif \[ "\$script_carrier" -eq 1 \]; then$/      elif false; then/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-suppall.sh"
/usr/bin/sed 's/^readonly SCRIPT_ENCL_POS_MAX=512$/readonly SCRIPT_ENCL_POS_MAX=4/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-smallp.sh"
/usr/bin/sed 's/^readonly SCRIPT_ENCL_TAIL_BYTES=262144$/readonly SCRIPT_ENCL_TAIL_BYTES=64/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-smallb.sh"
for encl_c in forced shadow bogus rev m1 m2 m3 m4 m5 deny openall supp route split noex suppall smallp smallb; do
  /bin/chmod +x "${ENCL_HOOKS}/block-destructive-${encl_c}.sh"
done
/bin/chmod +x "${ENCL_HOOKS}/block-destructive.sh"
ENCL_DRAIN="${ENCL_HOOKS}/destructive-warn-log.jsonl"

encl_drain_rows() {
  if [ -f "$ENCL_DRAIN" ]; then
    /usr/bin/wc -l < "$ENCL_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

# The difference between the hook copy and one copy, as "<lines removed>/<lines added>".
encl_diff_shape() { # $1 = copy file in the hermetic hooks dir
  /usr/bin/diff "${ENCL_HOOKS}/block-destructive.sh" "${ENCL_HOOKS}/$1" \
    | /usr/bin/awk 'index($0, "<") == 1 { r++ } index($0, ">") == 1 { a++ } END { printf "%d/%d", r, a }'
}

ENCL_EXIT=0
ENCL_ERR=""
ENCL_V=""
ENCL_ROWS=""
ENCL_NROWS=0
# Run one payload through one copy -> ENCL_V (a|B|W|E<rc>), ENCL_ERR, and ENCL_ROWS, the
# would-fire rows the call added, one per line (empty when it added none).
encl_run() { # $1 = copy file in the hermetic hooks dir  $2 = command
  local tmp before after
  tmp="$(/usr/bin/mktemp)"
  ENCL_EXIT=0
  ENCL_ROWS=""
  before="$(encl_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$ENCL_ROOT")" \
      | /bin/bash "${ENCL_HOOKS}/$1" 2>"$tmp" >/dev/null ) || ENCL_EXIT="$?"
  after="$(encl_drain_rows)"
  ENCL_NROWS=$(( after - before ))
  ENCL_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
  if [ "$ENCL_NROWS" -gt 0 ]; then
    ENCL_ROWS="$(/usr/bin/tail -n "$ENCL_NROWS" "$ENCL_DRAIN")"
  fi
  case "$ENCL_EXIT" in
    2) ENCL_V="B" ;;
    0) if [ "$ENCL_NROWS" -gt 0 ]; then ENCL_V="W"; else ENCL_V="a"; fi ;;
    *) ENCL_V="E${ENCL_EXIT}" ;;
  esac
}

# Does one of the rows the last call added carry this arm AND the enclosure position key?
encl_row_has() { # $1 = arm value
  local line
  while IFS= read -r line; do
    case "$line" in
      *"\"arm\":\"$1\""*'"pos":"enclosure"'*) return 0 ;;
    esac
  done <<<"$ENCL_ROWS"
  return 1
}

# A shape arm. $1 label  $2 command  $3 shipped verdict (a|B|W)  $4 forced verdict (a|B|W, or
# - to skip)  $5 reverse verdict (a|B|W, or - to skip)  $6 (optional) for a wanted W, the arm
# a row written from an enclosure position must name, on the shipped copy and on the forced
# one. A wanted B must carry BLOCK-DESTRUCTIVE-022. The reverse copy never writes the position
# key, so a reverse W (a first-view row) is not mistaken for the view's.
encl_arm() {
  local name="$1" cmd="$2" want="$3" wantf="$4" wantr="$5" arm="${6:-}" got gotf gotr ok=1 why=""
  encl_run block-destructive.sh "$cmd"
  got="$ENCL_V"
  if [ "$got" != "$want" ]; then ok=0; why="shipped=${got}"; fi
  if [ "$ok" = 1 ] && [ "$want" = "W" ] && [ -n "$arm" ] && ! encl_row_has "$arm"; then ok=0; why="shipped row lacks arm ${arm} at pos enclosure"; fi
  if [ "$ok" = 1 ] && [ "$want" = "B" ] && ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$ENCL_ERR"; then ok=0; why="shipped refusal is not -022"; fi
  gotf="-"
  if [ "$wantf" != "-" ]; then
    encl_run block-destructive-forced.sh "$cmd"
    gotf="$ENCL_V"
    if [ "$gotf" != "$wantf" ]; then ok=0; why="${why} forced=${gotf}"; fi
    if [ "$wantf" = "B" ] && ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$ENCL_ERR"; then ok=0; why="${why} forced refusal is not -022"; fi
    if [ "$wantf" = "W" ] && [ -n "$arm" ] && ! encl_row_has "$arm"; then ok=0; why="${why} forced row lacks arm ${arm} at pos enclosure"; fi
  fi
  gotr="-"
  if [ "$wantr" != "-" ]; then
    encl_run block-destructive-rev.sh "$cmd"
    gotr="$ENCL_V"
    if [ "$gotr" != "$wantr" ]; then ok=0; why="${why} reverse=${gotr}"; fi
  fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (shipped %s, forced %s, reverse %s)\n' "$name" "$got" "$gotf" "$gotr"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted shipped=%s forced=%s reverse=%s; observed %s\n  stderr: %s\n' "$name" "$want" "$wantf" "$wantr" "${why# }" "$ENCL_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# A mutant arm. $1 label  $2 copy file  $3 command  $4 verdict wanted from that copy
# $5 (optional) for a wanted B, a pattern the refusal must carry.
encl_mut_arm() {
  local name="$1" mut="$2" cmd="$3" want="$4" detail="${5:-}" ok=1 why=""
  encl_run "$mut" "$cmd"
  if [ "$ENCL_V" != "$want" ]; then ok=0; why="copy=${ENCL_V}"; fi
  if [ "$ok" = 1 ] && [ "$want" = "B" ] && [ -n "$detail" ] \
     && ! /usr/bin/grep -qE "$detail" <<<"$ENCL_ERR"; then
    ok=0; why="refusal lacks /${detail}/"
  fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (copy %s)\n' "$name" "$ENCL_V"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted copy=%s; observed %s\n  stderr: %s\n' "$name" "$want" "$why" "$ENCL_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# A copy's shape arm: it differs from the hook by the lines named, and it parses. A copy whose
# sed matched nothing is a byte copy of the hook, and the arms that read it would be inert.
encl_shape_arm() { # $1 label  $2 copy file  $3 the shape it must have
  local got parse=0
  got="$(encl_diff_shape "$2")"
  /bin/bash -n "${ENCL_HOOKS}/$2" 2>/dev/null || parse=1
  if [ "$got" = "$3" ] && [ "$parse" = 0 ]; then
    /usr/bin/printf 'PASS: %s (removed/added %s, parses)\n' "$1" "$got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  removed/added %s (wanted %s), bash -n exit %s — the arms that read this copy are unusable\n' "$1" "$got" "$3" "$parse"
    FAIL=$((FAIL + 1))
  fi
}

# --- the fixture is live before any verdict is read ------------------------------------------
encl_scope_ok=1
for encl_c in block-destructive.sh block-destructive-forced.sh block-destructive-rev.sh; do
  encl_run "$encl_c" 'git push --force origin main'
  if [ "$ENCL_V" != "B" ] || ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-001' <<<"$ENCL_ERR"; then encl_scope_ok=0; fi
done
if [ "$encl_scope_ok" = 1 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-SCOPE the shipped copy, the forced copy and the reverse mutant are in scope and enforcing (unrelated rule -001 fires on each), so the verdicts below are live\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-SCOPE a copy is not live (an unrelated rule did not fire on it); the verdicts below are unusable\n'
  FAIL=$((FAIL + 1))
fi

# The reverse mutant removes exactly the two marked blocks and rewrites the one scan line. The
# expected removal is counted from the shipped hook's own markers, and a hook that carries none
# fails here rather than passing with a removal of zero.
encl_view_lines="$(/usr/bin/awk 'index($0, "# >>> ENCLOSURE-VIEW-BEGIN") { f = 1 } f { n++ } index($0, "# >>> ENCLOSURE-VIEW-END") { f = 0 } END { printf "%d", n }' "$HOOK")"
encl_hd_lines="$(/usr/bin/awk 'index($0, "# >>> ENCL-HDHEAD-BEGIN") { f = 1 } f { n++ } index($0, "# >>> ENCL-HDHEAD-END") { f = 0 } END { printf "%d", n }' "$HOOK")"
encl_rev_left="$(/usr/bin/awk 'index($0, "ENCLOSURE-VIEW-") || index($0, "ENCL-HDHEAD-") { n++ } index($0, "# M-ENCL-SCAN") && index($0, "script_qbt") { n++ } END { printf "%d", n }' "${ENCL_HOOKS}/block-destructive-rev.sh")"
encl_rev_want="$(( encl_view_lines + encl_hd_lines + 1 ))/1"
encl_rev_got="$(encl_diff_shape block-destructive-rev.sh)"
if [ "$encl_view_lines" -gt 0 ] && [ "$encl_hd_lines" -gt 0 ] && [ "$encl_rev_got" = "$encl_rev_want" ] && [ "$encl_rev_left" = 0 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-M0a the reverse mutant removes the view block (%s lines) and the receiver block (%s lines) and rewrites the scan line (removed/added %s), leaving no marker behind\n' "$encl_view_lines" "$encl_hd_lines" "$encl_rev_got"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-M0a reverse mutant shape %s (wanted %s, view %s lines, receiver %s lines, %s marker lines left) — the reverse limbs below are unusable\n' "$encl_rev_got" "$encl_rev_want" "$encl_view_lines" "$encl_hd_lines" "$encl_rev_left"
  FAIL=$((FAIL + 1))
fi
encl_shape_arm "AC-ENCL-M0b the reverse mutant parses (shape restated)" block-destructive-rev.sh "$encl_rev_want"
encl_mut_arm "AC-ENCL-M0c the reverse mutant still refuses bash <unlisted>.sh (it enforces the first view)" \
  block-destructive-rev.sh "bash ${ENCL_NA}" B "BLOCK-DESTRUCTIVE-022"
encl_shape_arm "AC-ENCL-P0a the forced copy differs from the hook by the phase constant alone" block-destructive-forced.sh "1/1"
encl_shape_arm "AC-ENCL-P0b the shadow copy differs from the hook by the phase constant alone" block-destructive-shadow.sh "1/1"
encl_shape_arm "AC-ENCL-P0c the out-of-enum copy differs from the hook by the phase constant alone" block-destructive-bogus.sh "1/1"
encl_shape_arm "AC-ENCL-M1a the re-open mutant differs by one line, rewritten" block-destructive-m1.sh "1/1"
encl_shape_arm "AC-ENCL-M2a the single-receiver mutant removes the receiver block" block-destructive-m2.sh "${encl_hd_lines}/0"
encl_shape_arm "AC-ENCL-M3a the no-remainder mutant differs by one line, removed" block-destructive-m3.sh "1/0"
encl_shape_arm "AC-ENCL-M4a the no-cut mutant differs by one line, removed" block-destructive-m4.sh "1/0"
encl_shape_arm "AC-ENCL-M5a the escape-blind mutant differs by one line, rewritten" block-destructive-m5.sh "1/1"
encl_shape_arm "AC-ENCL-DENY-a the gate-deny mutant differs by one line, rewritten" block-destructive-deny.sh "1/1"
encl_shape_arm "AC-ENCL-OPENALL-a the escape-blind gate-deny mutant differs by two lines, rewritten" block-destructive-openall.sh "2/2"
encl_shape_arm "AC-ENCL-SUPP-a the no-suppression mutant differs by one line, rewritten" block-destructive-supp.sh "1/1"
encl_shape_arm "AC-ENCL-ROUTE-a the route mutant differs by one line, rewritten" block-destructive-route.sh "1/1"
encl_shape_arm "AC-ENCL-SPLIT-a the paren-separator mutant differs by one line, rewritten" block-destructive-split.sh "1/1"
encl_shape_arm "AC-ENCL-NOEX-a the excise-nothing mutant differs by one line, rewritten" block-destructive-noex.sh "1/1"
encl_shape_arm "AC-ENCL-SUPPALL-a the first-view no-suppression mutant differs by one line, rewritten" block-destructive-suppall.sh "1/1"
encl_shape_arm "AC-ENCL-SMALLP-a the low-ceiling copy differs by one line, rewritten" block-destructive-smallp.sh "1/1"
encl_shape_arm "AC-ENCL-SMALLB-a the low-remainder-budget copy differs by one line, rewritten" block-destructive-smallb.sh "1/1"

# --- SHAPES: a shell interpreter or `source` inside an enclosure ------------------------------
encl_arm "AC-ENCL-01: echo \$(bash <unlisted>.sh) is recorded at warn and refused at enforce" \
  "echo \$(bash ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-02: echo \"\$(bash <unlisted>.sh)\" is recorded at warn and refused at enforce" \
  "echo \"\$(bash ${ENCL_NA})\"" W B a shell-enclosure
encl_arm "AC-ENCL-03: X=\$(bash <unlisted>.sh) is adjudicated by the arm that owns bash (the reverse copy records it only through the direct-execution arm)" \
  "X=\$(bash ${ENCL_NA})" W B W shell-enclosure
encl_arm "AC-ENCL-03b: OUT=\"\$(bash <unlisted>.sh --flag)\" with no slash in the path is adjudicated (the reverse copy records nothing)" \
  'OUT="$(bash pmo-encl-na.sh --flag)"' W B a shell-enclosure
encl_arm "AC-ENCL-04: the card's for-loop assignment is adjudicated by the arm that owns bash" \
  'for i in 1 2; do X="$(bash "$D/evil.sh" arg)"; done' W B W shell-enclosure
encl_arm "AC-ENCL-05: echo \`bash <unlisted>.sh\` is recorded at warn and refused at enforce" \
  "echo \`bash ${ENCL_NA}\`" W B a shell-enclosure
encl_arm "AC-ENCL-06: cat <(bash <unlisted>.sh) is recorded at warn and refused at enforce" \
  "cat <(bash ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-07: (bash <unlisted>.sh) is recorded at warn and refused at enforce" \
  "(bash ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-07b: time (bash \"\$D/evil.sh\" arg) is recorded at warn and refused at enforce" \
  'time (bash "$D/evil.sh" arg)' W B a shell-enclosure
encl_arm "AC-ENCL-08: (xargs bash \"\$D/evil.sh\" < /dev/null) is recorded at warn and refused at enforce" \
  '(xargs bash "$D/evil.sh" < /dev/null)' W B a shell-enclosure
encl_arm "AC-ENCL-08b: echo x | (xargs bash) — the stdin deny at an enclosure position — is recorded at warn and refused at enforce" \
  'echo x | (xargs bash)' W B a shell-enclosure
encl_arm "AC-ENCL-09: echo \$(source <unlisted>.sh) is recorded at warn and refused at enforce" \
  "echo \$(source ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-09b: (source <unlisted>.sh) is recorded at warn and refused at enforce" \
  "(source ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-10: X=\"\$(bash <unlisted>.sh)-suffix\" — a closer glued to the operand — is adjudicated" \
  "X=\"\$(bash ${ENCL_NA})-suffix\"" W B a shell-enclosure
encl_arm "AC-ENCL-10b: echo \"\${X:-\$(source <unlisted>.sh)}\" is adjudicated" \
  "echo \"\${X:-\$(source ${ENCL_NA})}\"" W B a shell-enclosure
encl_arm "AC-ENCL-11: echo \$(bash \$(echo -n) <unlisted>.sh) — an operand beyond a nested opener — is adjudicated" \
  "echo \$(bash \$(echo -n) ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-11b: echo \$(bash \"\$(pwd)/evil.sh\") is adjudicated" \
  'echo $(bash "$(pwd)/evil.sh")' W B a shell-enclosure
encl_arm "AC-ENCL-12: (X=\$(date) bash <unlisted>.sh) is adjudicated" \
  "(X=\$(date) bash ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-12b: echo \$(env X=\\) bash <unlisted>.sh) — a prefix word the walk lists, inside an enclosure — is adjudicated" \
  "echo \$(env X=\\) bash ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-13: echo \$(bash -c 'cd /tmp; bash <unlisted>.sh') — a carrier's exemption crossing an enclosure — is adjudicated" \
  "echo \$(bash -c 'cd /tmp; bash ${ENCL_NA}')" W B a shell-enclosure
encl_arm "AC-ENCL-14: a here-document received by bash inside an enclosure under a carrier at the line head is recorded at warn and refused at enforce" \
  "echo \$(bash <<'EOF'
bash ${ENCL_NA}
EOF
)" W B a shell-enclosure
encl_arm "AC-ENCL-15: an unquoted here-document body carrying \$(bash <unlisted>.sh) is adjudicated" \
  "cat <<EOF
# note \$(bash ${ENCL_NA})
EOF" W B a shell-enclosure
# The direct-execution and non-shell arms keep their own phases at an enclosure position, so
# their forced limb records, as the shipped one does; only the position key is new.
encl_arm "AC-ENCL-16a: echo \$(<unlisted>.sh) is recorded by the direct-execution arm at its own phase, from the enclosure position" \
  "echo \$(${ENCL_NA})" W W a exec
encl_arm "AC-ENCL-16b: echo \$(python3 <unlisted>.py) is recorded by the non-shell arm at its own phase, from the enclosure position" \
  "echo \$(python3 ${ENCL_NAPY})" W W a interp-nonshell
encl_arm "AC-ENCL-TEXEC6b: T-EXEC-6's original payload — raw backticks inside a carrier's double-quoted argument, which the shell runs — is recorded from the enclosure position" \
  'gh issue comment 1 --body "| step | `./tmp/x.sh` | run it |"' W W a exec

# --- MUST NOT FLAG: near misses, each followed by the mutant that fails it --------------------
encl_arm "AC-ENCL-N01: echo \"\$(date)\" stays allowed (the card's near miss)" 'echo "$(date)"' a - a
encl_mut_arm "AC-ENCL-N01-pair: the gate-deny mutant REFUSES echo \"\$(date)\"" block-destructive-deny.sh 'echo "$(date)"' B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N02: echo \$(bash <allowlisted>.sh --check) stays allowed" "echo \$(bash ${ENCL_OK} --check)" a - a
encl_mut_arm "AC-ENCL-N02-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh "echo \$(bash ${ENCL_OK} --check)" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N03: X=\$(bash --version) stays allowed (no script operand)" 'X=$(bash --version)' a - a
encl_mut_arm "AC-ENCL-N03-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh 'X=$(bash --version)' B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N04: echo \$(bash -n <unlisted>.sh) stays allowed (parse-only)" "echo \$(bash -n ${ENCL_NA})" a - a
encl_mut_arm "AC-ENCL-N04-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh "echo \$(bash -n ${ENCL_NA})" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N05: X=\$(wc -l < <unlisted>.sh) stays allowed (a read that names a script)" "X=\$(wc -l < ${ENCL_NA})" a - a
encl_mut_arm "AC-ENCL-N05-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh "X=\$(wc -l < ${ENCL_NA})" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N06: diff <(sort <unlisted>.sh) <(sort <allowlisted>.sh) stays allowed" "diff <(sort ${ENCL_NA}) <(sort ${ENCL_OK})" a - a
encl_mut_arm "AC-ENCL-N06-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh "diff <(sort ${ENCL_NA}) <(sort ${ENCL_OK})" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N07: echo \$(bash --version) <unlisted>.sh stays allowed (text after a closed enclosure)" "echo \$(bash --version) ${ENCL_NA}" a - a
encl_arm "AC-ENCL-N08: echo \"\\\$(bash <unlisted>.sh)\" stays allowed (the substitution escaped, under a carrier)" "echo \"\\\$(bash ${ENCL_NA})\"" a - a
encl_mut_arm "AC-ENCL-N08-pair: the no-suppression mutant RECORDS it" block-destructive-supp.sh "echo \"\\\$(bash ${ENCL_NA})\"" W
encl_arm "AC-ENCL-N09: gh … --body 'see (bash <unlisted>.sh) for details; ok' stays allowed (a carrier's single-quoted argument)" "gh issue comment 1 --body 'see (bash ${ENCL_NA}) for details; ok'" a - a
encl_mut_arm "AC-ENCL-N09-pair: the no-suppression mutant RECORDS it" block-destructive-supp.sh "gh issue comment 1 --body 'see (bash ${ENCL_NA}) for details; ok'" W
encl_arm "AC-ENCL-N10: echo \"note (bash <unlisted>.sh) end\" stays allowed (a carrier's untainted double-quoted argument)" "echo \"note (bash ${ENCL_NA}) end\"" a - a
encl_mut_arm "AC-ENCL-N10-pair: the no-suppression mutant RECORDS it" block-destructive-supp.sh "echo \"note (bash ${ENCL_NA}) end\"" W
encl_arm "AC-ENCL-N11: git commit -m \"docs: run \\\`bash <unlisted>.sh --flag\\\` (see notes)\" stays allowed (escaped backticks open nothing)" \
  "git commit -m \"docs: run \\\`bash ${ENCL_NA} --flag\\\` (see notes)\"" a - a
encl_arm "AC-ENCL-N12: echo \\(bash <unlisted>.sh\\) stays allowed (escaped parentheses open nothing)" "echo \\(bash ${ENCL_NA}\\)" a - a
encl_mut_arm "AC-ENCL-N12-pair: the escape-blind gate-deny mutant REFUSES it" block-destructive-openall.sh "echo \\(bash ${ENCL_NA}\\)" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N13: find . \\( -name '*.sh' -o -name x \\) -newer <unlisted>.sh stays allowed" "find . \\( -name '*.sh' -o -name x \\) -newer ${ENCL_NA}" a - a
encl_mut_arm "AC-ENCL-N13-pair: the escape-blind gate-deny mutant REFUSES it" block-destructive-openall.sh "find . \\( -name '*.sh' -o -name x \\) -newer ${ENCL_NA}" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N14: a carrier receiving a here-document after a closed substitution stays allowed (the enclosure closed before the operator)" \
  "gh issue comment \$(cat list.txt) --body-file - <<'EOF'
note; bash ${ENCL_NA}
EOF" a - a
encl_mut_arm "AC-ENCL-N14-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh \
  "gh issue comment \$(cat list.txt) --body-file - <<'EOF'
note; bash ${ENCL_NA}
EOF" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-N15: echo \"\$(date)\" 'x; bash <unlisted>.sh' stays allowed (the enclosure inside quotes does not move the carrier)" "echo \"\$(date)\" 'x; bash ${ENCL_NA}'" a - a
encl_mut_arm "AC-ENCL-N15-pair: the no-suppression mutant RECORDS it" block-destructive-supp.sh "echo \"\$(date)\" 'x; bash ${ENCL_NA}'" W

# --- DECLARED OVER-MATCH, pinned: adjudicated although nothing runs ---------------------------
# Each records at warn and is refused at enforce; its reverse limb, allowed, is the mutant that
# fails the pin. The one exception is the array literal: before this change the direct-execution
# arm already recorded it, reading `cmd=(bash` as an assignment and the path after it as the
# command word, so its reverse limb records too, and its pairing arm reads the rows instead.
encl_arm "AC-ENCL-RESIDUAL-noncarrier-text (pin, not fix-evidence): git commit -m 'fix (bash <unlisted>.sh was failing)'" \
  "git commit -m 'fix (bash ${ENCL_NA} was failing)'" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-body-idiom (pin, not fix-evidence): the commit idiom with a code span naming a script in its body" \
  "git commit -m \"\$(cat <<'EOF'
Run \`bash ${ENCL_NA}\` to verify
EOF
)\"" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-backtick-close (pin, not fix-evidence): text after a closing backtick" \
  "echo \`date\` bash ${ENCL_NA}" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-carrier-moved (pin, not fix-evidence): a quoted argument after an unquoted enclosure, under a carrier" \
  "echo \$(date) 'x; bash ${ENCL_NA}'" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-comment (pin, not fix-evidence): a comment naming a script in parentheses" \
  "# setup (bash ${ENCL_NA})" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-array (pin, not fix-evidence): an array literal (the reverse copy records it through the direct-execution arm)" \
  "cmd=(bash ${ENCL_NA} arg)" W B W shell-enclosure
encl_run block-destructive-rev.sh "cmd=(bash ${ENCL_NA} arg)"
if [ "$ENCL_V" = "W" ] && ! encl_row_has shell-enclosure; then
  /usr/bin/printf 'PASS: AC-ENCL-RESIDUAL-array-pair: the reverse mutant records the array literal with no row from an enclosure position, so the pin fails on it\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-RESIDUAL-array-pair: reverse verdict %s, rows [%s] (wanted W with no shell-enclosure row at pos enclosure)\n' "$ENCL_V" "$ENCL_ROWS"
  FAIL=$((FAIL + 1))
fi
encl_arm "AC-ENCL-RESIDUAL-escaped-dollar (pin, not fix-evidence): an escaped dollar under a non-carrier" \
  "git commit -m \"explain \\\$(bash ${ENCL_NA}) literally\"" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-full-stop (pin, not fix-evidence): a sentence's full stop after a code span reads as the dot command" \
  "git commit -m 'see \`x\`. Then /tmp/pmo-encl-y'" W B a shell-enclosure
encl_arm "AC-ENCL-RESIDUAL-hd-cat (pin, not fix-evidence): a carrier's unquoted substitution reading a here-document through cat, where nothing runs, is newly flagged" \
  "echo \$(cat <<'EOF'
bash ${ENCL_NA}
EOF
)" W B a shell-enclosure

# --- DECLARED UNDER-MATCH, pinned: what the view does not reach ------------------------------
encl_arm "AC-ENCL-RESIDUAL-nested-escaped (pin, not fix-evidence): backticks nested through escaped backticks" \
  "echo \`echo \\\`bash ${ENCL_NA}\\\` \`" a - a
encl_mut_arm "AC-ENCL-RESIDUAL-nested-escaped-pair: the escape-blind gate-deny mutant REFUSES it" block-destructive-openall.sh "echo \`echo \\\`bash ${ENCL_NA}\\\` \`" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-RESIDUAL-ansic (pin, not fix-evidence): ANSI-C quoting ahead of the verb ends the position's text early" \
  "echo \$(X=\$'\\')' bash ${ENCL_NA})" a - a
encl_mut_arm "AC-ENCL-RESIDUAL-ansic-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh "echo \$(X=\$'\\')' bash ${ENCL_NA})" B "ENCL gate deny mutant"
encl_arm "AC-ENCL-RESIDUAL-paramexp (pin, not fix-evidence): a ) inside a parameter expansion ends the position's text early" \
  "echo \$(X=\${Y:-)} bash ${ENCL_NA})" a - a
encl_mut_arm "AC-ENCL-RESIDUAL-paramexp-pair: the gate-deny mutant REFUSES it" block-destructive-deny.sh "echo \$(X=\${Y:-)} bash ${ENCL_NA})" B "ENCL gate deny mutant"
# The nested-apostrophe pin that stood here is retired: the trust boundary of the carried quote
# state latches on that nesting, and QSCAN-NESTQ-02 (row EN86) records the class at warn and
# refuses it at enforce. Its pairing arm below still reads the no-suppression copy.
encl_mut_arm "AC-ENCL-RESIDUAL-nested-apostrophe-pair: the no-suppression mutant RECORDS it" block-destructive-supp.sh "echo \"\$(printf \"it's\" \$(bash ${ENCL_NA}))\"" W
encl_arm "AC-ENCL-RESIDUAL-carrier-head (pin, not fix-evidence): a carrier at the head of an unquoted substitution lends its exemption to a later program string" \
  "bash -c \$(echo -n) 'true; (bash ${ENCL_NA})'" a - a
encl_mut_arm "AC-ENCL-RESIDUAL-carrier-head-pair: the no-suppression mutant RECORDS it" block-destructive-supp.sh "bash -c \$(echo -n) 'true; (bash ${ENCL_NA})'" W
encl_arm "AC-ENCL-RESIDUAL-hd-continuation (pin, not fix-evidence): a here-document receiver behind a line continuation is read from its physical line" \
  "echo \$(bash -s \\
echo <<'EOF'
bash ${ENCL_NA}
EOF
)" a - a
encl_mut_arm "AC-ENCL-RESIDUAL-hd-continuation-pair: the excise-nothing mutant REFUSES it" block-destructive-noex.sh \
  "echo \$(bash -s \\
echo <<'EOF'
bash ${ENCL_NA}
EOF
)" B "BLOCK-DESTRUCTIVE-022"
# The two work budgets. The shipped values are asserted, and each budget's behaviour is pinned
# on a copy with only that budget lowered, where a short payload crosses it. The shipped hook on
# the same payload is the copy that fails the pin: within its budget the position is seen.
encl_budget_pos="$(/usr/bin/grep -c '^readonly SCRIPT_ENCL_POS_MAX=512$' "$HOOK" || true)"
encl_budget_bytes="$(/usr/bin/grep -c '^readonly SCRIPT_ENCL_TAIL_BYTES=262144$' "$HOOK" || true)"
if [ "$encl_budget_pos" = 1 ] && [ "$encl_budget_bytes" = 1 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-BUDGETS the hook declares a 512-position ceiling and a 262,144-byte remainder budget\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-BUDGETS the declared budgets moved (position lines %s, remainder lines %s, each wanted 1); restate the readiness text and these pins together\n' "$encl_budget_pos" "$encl_budget_bytes"
  FAIL=$((FAIL + 1))
fi
encl_pos_cmd="echo \$(true) \$(true) \$(true) \$(true) \$(bash ${ENCL_NA})"
encl_mut_arm "AC-ENCL-RESIDUAL-budget-positions (pin, not fix-evidence): past the position ceiling no further position is opened" \
  block-destructive-smallp.sh "$encl_pos_cmd" a
encl_mut_arm "AC-ENCL-RESIDUAL-budget-positions-pair: within the shipped ceiling the same payload is recorded" \
  block-destructive.sh "$encl_pos_cmd" W
encl_pad="$(/usr/bin/printf 'pad %.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30)"
encl_bytes_cmd="echo \$(true) \$(bash \$(echo -n) ${ENCL_NA}) ${encl_pad}"
encl_mut_arm "AC-ENCL-RESIDUAL-budget-bytes (pin, not fix-evidence): past the remainder budget an operand beyond a nested opener is not seen" \
  block-destructive-smallb.sh "$encl_bytes_cmd" a
encl_mut_arm "AC-ENCL-RESIDUAL-budget-bytes-pair: within the shipped budget the same payload is recorded" \
  block-destructive.sh "$encl_bytes_cmd" W

# --- EQUIVALENCES with the prefix walk -------------------------------------------------------
# The view runs the walk the prefix vocabulary leaves: a keyword or a wrapper the walk lists is
# honoured inside an enclosure as at top level. Compared on the FORCED copy, whose refusal is the
# top-level verdict's; the shipped copy records; the reverse mutant allows, which fails the
# equivalence.
encl_eq_arm() { # $1 label  $2 enclosure form  $3 top-level form
  local name="$1" encl="$2" top="$3" vf vt vs vr ok=1
  encl_run block-destructive-forced.sh "$encl"; vf="$ENCL_V"
  encl_run block-destructive.sh "$top"; vt="$ENCL_V"
  encl_run block-destructive.sh "$encl"; vs="$ENCL_V"
  encl_run block-destructive-rev.sh "$encl"; vr="$ENCL_V"
  if [ "$vf" != "$vt" ] || [ "$vt" != "B" ] || [ "$vs" != "W" ] || [ "$vr" = "$vt" ]; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (forced %s = top-level %s; shipped %s; reverse %s)\n' "$name" "$vf" "$vt" "$vs" "$vr"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  forced=%s top-level=%s (want both B), shipped=%s (want W), reverse=%s (want not B)\n' "$name" "$vf" "$vt" "$vs" "$vr"
    FAIL=$((FAIL + 1))
  fi
}
encl_eq_arm "AC-ENCL-KW-eq: echo \$(if bash <unlisted>.sh; then :; fi) takes the verdict of the same condition at top level" \
  "echo \$(if bash ${ENCL_NA}; then :; fi)" "if bash ${ENCL_NA}; then :; fi"
encl_eq_arm "AC-ENCL-08c: (xargs -I{} bash \"\$D/evil.sh\" {} < /dev/null) takes the verdict of the same command without the group" \
  '(xargs -I{} bash "$D/evil.sh" {} < /dev/null)' 'xargs -I{} bash "$D/evil.sh" {} < /dev/null'

# --- THE PHASES ------------------------------------------------------------------------------
encl_run block-destructive.sh "echo \$(bash ${ENCL_NA})"
encl_p1_ok=1
[ "$ENCL_V" = "W" ] || encl_p1_ok=0
[ "$ENCL_NROWS" = 1 ] || encl_p1_ok=0
case "$ENCL_ROWS" in *'"phase":"warn"'*'"reason":"would-fire"'*'"arm":"shell-enclosure"'*'"pos":"enclosure"'*) ;; *) encl_p1_ok=0 ;; esac
/usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022] WARN (would-block, rollout=warn' <<<"$ENCL_ERR" || encl_p1_ok=0
if [ "$encl_p1_ok" = 1 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-P1 at warn: exit 0, one row (phase warn, arm shell-enclosure, pos enclosure) and a notice on stderr\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-P1 at warn: verdict %s, %s new rows, row [%s], stderr [%s]\n' "$ENCL_V" "$ENCL_NROWS" "$ENCL_ROWS" "$ENCL_ERR"; FAIL=$((FAIL + 1))
fi
encl_run block-destructive-shadow.sh "echo \$(bash ${ENCL_NA})"
encl_p2_ok=1
[ "$ENCL_V" = "W" ] || encl_p2_ok=0
[ "$ENCL_NROWS" = 1 ] || encl_p2_ok=0
case "$ENCL_ROWS" in *'"phase":"shadow"'*'"arm":"shell-enclosure"'*) ;; *) encl_p2_ok=0 ;; esac
if /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$ENCL_ERR"; then encl_p2_ok=0; fi
if [ "$encl_p2_ok" = 1 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-P2 at shadow: exit 0, one row (phase shadow), nothing on stderr\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-P2 at shadow: verdict %s, %s new rows, row [%s], stderr [%s]\n' "$ENCL_V" "$ENCL_NROWS" "$ENCL_ROWS" "$ENCL_ERR"; FAIL=$((FAIL + 1))
fi
encl_run block-destructive-forced.sh "echo \$(bash ${ENCL_NA})"
encl_p3_ok=1
[ "$ENCL_V" = "B" ] || encl_p3_ok=0
case "$ENCL_ROWS" in *'"phase":"enforce"'*'"arm":"shell-enclosure"'*) ;; *) encl_p3_ok=0 ;; esac
/usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$ENCL_ERR" || encl_p3_ok=0
if [ "$encl_p3_ok" = 1 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-P3 at enforce: refused by BLOCK-DESTRUCTIVE-022, the row written with phase enforce\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-P3 at enforce: verdict %s, row [%s], stderr [%s]\n' "$ENCL_V" "$ENCL_ROWS" "$ENCL_ERR"; FAIL=$((FAIL + 1))
fi
encl_mut_arm "AC-ENCL-P4 an unrecognised phase value falls through to enforce and refuses" \
  block-destructive-bogus.sh "echo \$(bash ${ENCL_NA})" B "BLOCK-DESTRUCTIVE-022"
encl_run block-destructive.sh "bash ${ENCL_NA}"
if [ "$ENCL_V" = "B" ] && [ "$ENCL_NROWS" = 0 ] && /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$ENCL_ERR"; then
  /usr/bin/printf 'PASS: AC-ENCL-P5 pass-through: bash <unlisted>.sh at a first-view position is refused with no drain row (the router leaves the always-enforce arm as it was)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-P5 pass-through: verdict %s, %s new rows (want B and 0)\n  stderr: %s\n' "$ENCL_V" "$ENCL_NROWS" "$ENCL_ERR"; FAIL=$((FAIL + 1))
fi
encl_mut_arm "AC-ENCL-P5-pair: the route mutant RECORDS bash <unlisted>.sh at a first-view position instead of refusing it" \
  block-destructive-route.sh "bash ${ENCL_NA}" W
encl_run block-destructive.sh "echo \$(bash <<'EOF'
bash ${ENCL_NA}
EOF
)"
encl_p6_ok=1
[ "$ENCL_V" = "W" ] || encl_p6_ok=0
[ "$ENCL_NROWS" = 1 ] || encl_p6_ok=0
case "$ENCL_ROWS" in *'"arm":"shell-enclosure"'*'"cause":"heredoc-receiver"'*'"path":"bash"'*'"pos":"enclosure"'*) ;; *) encl_p6_ok=0 ;; esac
/usr/bin/grep -q 'WARN (would-block, rollout=warn, cause=heredoc-receiver)' <<<"$ENCL_ERR" || encl_p6_ok=0
if [ "$encl_p6_ok" = 1 ]; then
  /usr/bin/printf 'PASS: AC-ENCL-P6 the here-document receiver read from the enclosure is recorded at warn, naming that receiver, with a notice\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-ENCL-P6 receiver at warn: verdict %s, %s new rows, row [%s], stderr [%s]\n' "$ENCL_V" "$ENCL_NROWS" "$ENCL_ROWS" "$ENCL_ERR"; FAIL=$((FAIL + 1))
fi
encl_run block-destructive.sh 'echo x | (xargs bash)'
if [ "$ENCL_V" = "W" ] && [ "$ENCL_NROWS" = 1 ]; then
  case "$ENCL_ROWS" in
    *'"arm":"shell-enclosure"'*'"cause":"unresolvable"'*) /usr/bin/printf 'PASS: AC-ENCL-P7 the xargs stdin deny at an enclosure position is recorded at warn\n'; PASS=$((PASS + 1)) ;;
    *) /usr/bin/printf 'FAIL: AC-ENCL-P7 xargs at warn: row [%s]\n' "$ENCL_ROWS"; FAIL=$((FAIL + 1)) ;;
  esac
else
  /usr/bin/printf 'FAIL: AC-ENCL-P7 xargs at warn: verdict %s, %s new rows\n' "$ENCL_V" "$ENCL_NROWS"; FAIL=$((FAIL + 1))
fi

# --- EACH COMPONENT IS LOAD-BEARING: the design's one-line mutants ----------------------------
encl_mut_arm "AC-ENCL-M1b: without the re-open, the carrier's exemption crossing an enclosure is allowed again" \
  block-destructive-m1.sh "echo \$(bash -c 'cd /tmp; bash ${ENCL_NA}')" a
encl_mut_arm "AC-ENCL-M2b: with one receiver reading, the here-document inside an enclosure is allowed again" \
  block-destructive-m2.sh "echo \$(bash <<'EOF'
bash ${ENCL_NA}
EOF
)" a
encl_mut_arm "AC-ENCL-M3b: without the appended remainder, an operand beyond a nested opener is not seen" \
  block-destructive-m3.sh "echo \$(bash \$(echo -n) ${ENCL_NA})" a
encl_mut_arm "AC-ENCL-M4b: without the cut, a closer glued to the operand hides it" \
  block-destructive-m4.sh "X=\"\$(bash ${ENCL_NA})-suffix\"" a
encl_mut_arm "AC-ENCL-M4c: without the cut, text after a closed enclosure is read as an operand (the near miss N07 fails)" \
  block-destructive-m4.sh "echo \$(bash --version) ${ENCL_NA}" W
encl_mut_arm "AC-ENCL-M5b: without the escape rule, an escaped backtick opens a position (the near miss N11 fails)" \
  block-destructive-m5.sh "git commit -m \"docs: run \\\`bash ${ENCL_NA} --flag\\\` (see notes)\"" W
encl_mut_arm "AC-ENCL-TEXEC6-pair: with the first view's carrier suppression off, T-EXEC-6's re-pointed payload is recorded (the arm guards that suppression)" \
  block-destructive-suppall.sh "gh issue comment 1 --body '| step | \`./tmp/x.sh\` | run it |'" W

# ---- QSCAN-* (#8317): the carried quote state is trusted only where the hook's model follows it ----
#
# The rule's quote scanners model four quote states and nothing else. A construct they do not
# follow — a comment, a quote nested inside a substitution or an expansion, a backquote opened
# outside quotes, a run of dollars ahead of a quote — turns the carried state over, and every later
# segment is then read as quoted text and suppressed behind a carrier, or removed as a
# here-document body. Every arm here reads its command from the walk-payload corpus by row id
# (seed 15.1, rows QC01 to QC24, and EN86), so no payload is spelled in this suite. The verdicts are
# the shipped hook's after the change: each fail-open class is refused at a first-view position, or
# recorded at an enclosure one; each control stays refused; each near miss stays allowed; and each
# declared precision cost — nothing runs, and the hook refuses once it stops vouching for the
# command — is refused.
wc_row_cmd() { # $1 = row id -> WC_CMDX, the row's command with its placeholders expanded; 1 when absent
  local i=0
  WC_CMDX=""
  while [ "$i" -lt "$wc_n" ]; do
    if [ "${WC_ID[$i]}" = "$1" ]; then wc_expand "${WC_CMD[$i]}"; return 0; fi
    i=$((i + 1))
  done
  return 1
}
# qscan_arm <label> <row id> <shipped> <forced> <reverse> [<arm>] — encl_arm on that row's command.
qscan_arm() {
  if ! wc_row_cmd "$2"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$1" "$2"
    FAIL=$((FAIL + 1))
    return 0
  fi
  encl_arm "$1 [row $2]" "$WC_CMDX" "$3" "$4" "$5" "${6:-}"
}

# --- the fail-open classes (fix-evidence) ---
qscan_arm "QSCAN-CMT-01: a quote character in a comment on a carrier line does not suppress an unlisted script on the next line" QC01 B - -
qscan_arm "QSCAN-CMT-03: as CMT-01, the next line running the script through source" QC03 B - -
qscan_arm "QSCAN-CMT-04: as CMT-01, the next line running the script inside a substitution, recorded at warn and refused at enforce" QC04 W B a shell-enclosure
qscan_arm "QSCAN-NESTQ-01: an apostrophe in a string nested inside a double-quoted substitution does not suppress the next line" QC05 B - -
qscan_arm "QSCAN-NESTQ-02: the same nesting with the script inside the inner substitution, recorded at warn and refused at enforce" EN86 W B a shell-enclosure
qscan_arm "QSCAN-NESTQ-03: as NESTQ-01, nested inside a double-quoted parameter expansion" QC06 B - -
qscan_arm "QSCAN-NESTQ-04: as NESTQ-01, nested inside a double-quoted arithmetic opener" QC09 B - -
qscan_arm "QSCAN-BQ-01: an unbalanced quote inside a backquoted substitution opened outside quotes does not suppress the next line" QC08 B - -
qscan_arm "QSCAN-HD-01: a here-document operator inside a comment does not remove the next lines from adjudication" QC07 B - -
qscan_arm "QSCAN-DOLLAR-01: an even run of dollars ahead of a quote opens a plain quote, not ANSI-C quoting, so the next segment is adjudicated" QC10 B - -

# --- the controls: each class without its stray quote or operator, refused before and after ---
qscan_arm "QSCAN-CMT-ctl: a comment with no quote character on a carrier line, the script on the next line" QC11 B - -
qscan_arm "QSCAN-CMT-ctl-sep: the comment's quote character after a separator inside the comment" QC02 B - -
qscan_arm "QSCAN-CMT-ctl-phase: a comment's quote character with a later carrier fragment that the inverted phase already exposes" QC21 B - -
qscan_arm "QSCAN-NESTQ-ctl: the nested string with no apostrophe" QC12 B - -
qscan_arm "QSCAN-HD-ctl: a comment holding the delimiter word but no operator" QC13 B - -
qscan_arm "QSCAN-DOLLAR-ctl: the dollar run and the quote separated by a blank" QC14 B - -

# --- the near misses: allowed before and after ---
qscan_arm "QSCAN-CMT-near (#8317 AC2): a command whose only apostrophe sits in a comment, with nothing else naming a script" QC15 a - -
qscan_arm "QSCAN-CMT-near-quoted: a hash inside a carrier's quoted argument that also holds a separator and script prose" QC16 a - -
qscan_arm "QSCAN-CMT-near-midword: a hash that does not begin a word, beside a carrier's quoted fragment" QC17 a - -
qscan_arm "QSCAN-NESTQ-near-brace: a plain parameter expansion in double quotes, beside a carrier's quoted fragment" QC18 a - -
qscan_arm "QSCAN-HD-near: a carrier here-document with a quoted delimiter, no comment and no nesting on its operator line" QC19 a - -
qscan_arm "QSCAN-NOQ-near: a carrier's quoted fragment in a command with no comment, nesting or backquote" QC20 a - -

# --- the declared precision costs: nothing runs, and the hook refuses ---
qscan_arm "QSCAN-NESTQ-R1 (declared cost): a nested expansion whose text is not plain, beside a carrier's quoted fragment naming an unlisted script" QC22 B - -
qscan_arm "QSCAN-HD-R1 (declared cost): a carrier here-document whose operator line ends in a comment holding a quote, its body naming an unlisted script" QC23 B - -
# QC24 (re-authored after #8317's GREEN commit so it exercises PC-4): a comment naming a second
# here-document operator on a carrier here-document's operator line, with a body that names an
# unlisted script. The comment clause latches, the body is not excised, and the body line is refused
# although the shell runs nothing there — the declared precision cost PC-4.
qscan_arm "QSCAN-HD-R2 (control: refused before the card too, so not PC-4's move): a comment naming a here-document operator on a carrier here-document's operator line, its body naming an unlisted script" QC24 B - -

# QSCAN-WS: the flag walk's word reader reads a dollar run as the shell does. The reader is lifted
# out of the hook and run on every word of QC10 and of its control QC14: each must be read as a
# complete word — the plain quote that follows an even run of dollars closes inside the word.
qs_lib="$(/usr/bin/mktemp)"
qs_why=""
/usr/bin/awk '/^script_word_scan\(\) \{/ { f = 1; k++ } f { print; if ($0 == "}") f = 0 } END { exit k == 1 ? 0 : 1 }' "$HOOK" > "$qs_lib" \
  || qs_why="the word reader is not a single function in the hook;"
qs_words() { # $1 = row id -> qs_bad, the words of the row read as incomplete (empty when none)
  local w r n=0
  qs_bad=""
  if ! wc_row_cmd "$1"; then qs_bad="<row $1 absent>"; return 0; fi
  set -f
  # shellcheck disable=SC2206
  qs_w=( $WC_CMDX )
  set +f
  for w in "${qs_w[@]}"; do
    n=$((n + 1))
    r="$(/bin/bash -c '. "$1"; script_word_scan "$2"; printf "%s" "$script_ws_complete"' _ "$qs_lib" "$w")" || r="error"
    if [ "$r" != 1 ]; then qs_bad="${qs_bad} word ${n} complete=${r};"; fi
  done
  if [ "$n" -eq 0 ]; then qs_bad="<row $1 has no words>"; fi
}
for qs_c in "QSCAN-WS-01:QC10:the word that opens with an even run of dollars and a quote" "QSCAN-WS-ctl:QC14:the control's words"; do
  qs_label="${qs_c%%:*}"; qs_rest="${qs_c#*:}"; qs_row="${qs_rest%%:*}"; qs_what="${qs_rest#*:}"
  qs_words "$qs_row"
  if [ -z "$qs_why" ] && [ -z "$qs_bad" ]; then
    /usr/bin/printf 'PASS: %s: the word reader reads every word of row %s complete (%s)\n' "$qs_label" "$qs_row" "$qs_what"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s: the word reader reads a word of row %s as incomplete (%s)\n  %s%s\n' "$qs_label" "$qs_row" "$qs_what" "$qs_why" "$qs_bad"
    FAIL=$((FAIL + 1))
  fi
done
/bin/rm -f "$qs_lib"

# --- each clause is load-bearing: one-line copies of the hook ---
#   qmcmt    the comment clause off          qmnest   the nested-expansion clause off
#   qmhd     the full-mode comment bytes off  qdollar  the dollar run read as before (any run opens ANSI-C)
#   qmfb     the program's awk missing       qmall    the program never vouches (every checked command latches)
/usr/bin/sed '/# M-QMODEL-CMT/s/lat = 1/lat = lat/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-qmcmt.sh"
/usr/bin/sed '/# M-QMODEL-NEST/s/lat = 1/lat = lat/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-qmnest.sh"
/usr/bin/sed '/# M-QMODEL-HD/s/lat = 1/lat = lat/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-qmhd.sh"
/usr/bin/sed '/# M-QDOLLAR/s/\$(( _nd % 2 )) -eq 1/"$_nd" -ge 1/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-qdollar.sh"
/usr/bin/sed '/# qmodel: awk$/s#/usr/bin/awk#/nonexistent/awk#' "$HOOK" > "${ENCL_HOOKS}/block-destructive-qmfb.sh"
/usr/bin/sed '/# M-QMODEL-OK/s/\[ "\$_r" = 0 \]/false/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-qmall.sh"
for qs_c in qmcmt qmnest qmhd qdollar qmfb qmall; do
  /bin/chmod +x "${ENCL_HOOKS}/block-destructive-${qs_c}.sh"
  encl_shape_arm "QSCAN-COPY-${qs_c}: the copy differs from the hook by one line, rewritten" "block-destructive-${qs_c}.sh" "1/1"
done
# qscan_mut <label> <copy> <row id> <verdict>
qscan_mut() {
  if ! wc_row_cmd "$3"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$1" "$3"
    FAIL=$((FAIL + 1))
    return 0
  fi
  encl_mut_arm "$1 [row $3]" "$2" "$WC_CMDX" "$4"
}
qscan_mut "QSCAN-MUT-cmt: without the comment clause, CMT-01's class is allowed again" block-destructive-qmcmt.sh QC01 a
qscan_mut "QSCAN-MUT-nest: without the nested-expansion clause, NESTQ-01's class is allowed again" block-destructive-qmnest.sh QC05 a
qscan_mut "QSCAN-MUT-nest-bq: without the nested-expansion clause, BQ-01's class is allowed again" block-destructive-qmnest.sh QC08 a
qscan_mut "QSCAN-MUT-hd: without the full-mode comment bytes, HD-01's class is allowed again" block-destructive-qmhd.sh QC07 a
qscan_mut "QSCAN-MUT-dollar: with any dollar run opening ANSI-C quoting, DOLLAR-01's class is allowed again" block-destructive-qdollar.sh QC10 a
# The fallback: with the program's awk missing nothing is vouched for — a checked command latches
# (CMT-01's class is still refused, and EN63, which the program vouches for, is refused: the
# declared fail-closed cost), while a command the prefilter declines keeps today's verdict — and
# the hook raises no error.
for qs_c in "QC01:B" "EN63:B" "QC20:a"; do
  qs_row="${qs_c%%:*}"; qs_want="${qs_c#*:}"
  qscan_mut "QSCAN-FB-${qs_row}: with the program's awk missing, the row reads ${qs_want}" block-destructive-qmfb.sh "$qs_row" "$qs_want"
  case "$ENCL_ERR" in
    *HOOK-ERROR*) /usr/bin/printf 'FAIL: QSCAN-FB-%s-noerror: the copy without the awk raised a hook error\n  %s\n' "$qs_row" "$ENCL_ERR"; FAIL=$((FAIL + 1)) ;;
    *) /usr/bin/printf 'PASS: QSCAN-FB-%s-noerror: the copy without the awk raised no hook error\n' "$qs_row"; PASS=$((PASS + 1)) ;;
  esac
done
# The prefilter: on a copy whose program never vouches, a command the prefilter declines keeps
# today's path and verdict (QSCAN-PRE), while two near misses the program vouches for are refused —
# so what holds them allowed in the shipped hook is the program's reading, not the arm's luck.
qscan_mut "QSCAN-PRE: a command with no comment, nesting or backquote never reaches the program" block-destructive-qmall.sh QC20 a
qscan_mut "QSCAN-PRE-hd: a carrier here-document whose operator line has no comment and no nesting never reaches the program" block-destructive-qmall.sh QC19 a
qscan_mut "QSCAN-CMT-near-midword-pair: latched, the mid-word hash's command is refused" block-destructive-qmall.sh QC17 B
qscan_mut "QSCAN-NESTQ-near-brace-pair: latched, the plain expansion's command is refused" block-destructive-qmall.sh QC18 B
# The Stage 7 fix batch for #8317 (F-07, F-09, F-10): QSCAN-CMT-R1 is the design's PC-1 row, a carrier's quoted
# fragment naming an unlisted script before a comment that holds a quote, with the comment clause's mutant reading it
# as allowed; QSCAN-HDBQ is a backquote in a comment on a carrier here-document's operator line; QSCAN-DOLLAR-P29 pins
# QC29, the card's one refuse-to-allow row (B before the card). No marker isolates the dollar-run rule, so that arm
# carries no mutant limb.
qscan_arm "QSCAN-CMT-R1: a carrier's quoted fragment naming an unlisted script, then a comment holding a quote (PC-1)" QC30 B - -
qscan_mut "QSCAN-CMT-R1-mut: the comment-clause mutant reads it as allowed" block-destructive-qmcmt.sh QC30 a
qscan_arm "QSCAN-HDBQ: a backquote in a comment on a carrier here-document's operator line, its body naming an unlisted script" QC34 B - -
qscan_arm "QSCAN-DOLLAR-P29: an even dollar run before a quote is a plain quote (QC29, the declared precision row)" QC29 a - -

# --- #8490: a command word that begins with a backtick is a command substitution, not a path
# (release script-guard-refuses-only-what-executes; design on sub-task #9059, review on #9084).
# The exec arm declines such a word and leaves it to the position its backtick opens, only where
# the second view is known to read that position (markers M-EXEC-TICK*). Rows are read from the
# hermetic enclosure root above. XT_TICK counts the call's rows whose path begins with a backtick.
/usr/bin/sed 's/^readonly DESTRUCTIVE_022_EXEC_PHASE=.*/readonly DESTRUCTIVE_022_EXEC_PHASE="enforce"   # shadow | warn | enforce/' \
  "$HOOK" > "${ENCL_HOOKS}/block-destructive-xforced.sh"
/usr/bin/sed '/# >>> M-EXEC-TICK$/,/# <<< M-EXEC-TICK$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xrev.sh"
/usr/bin/sed '/# M-EXEC-TICK-GUARD/s/\[ "\$script_encl_all" -eq 1 \] && //' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xnoguard.sh"
/usr/bin/sed '/# M-EXEC-TICK-GUARD/s/ && \[ "\$script_hidx" -eq 0 \]//' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xnohidx.sh"
/usr/bin/sed '/# M-EXEC-TICK-STATE/s/^\([[:space:]]*\)[^)]*)/\1*)/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xnostate.sh"
/usr/bin/sed '/# M-EXEC-TICK-TAIL/s/) : ;;/) script_tick_decline=1 ;;/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xnotail.sh"
/usr/bin/sed -e '/# M-EXEC-TICK-NEST/d' -e 's/^readonly SCRIPT_ENCL_TAIL_BYTES=262144$/readonly SCRIPT_ENCL_TAIL_BYTES=64/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xnonestb.sh"
/usr/bin/sed -e 's/^readonly SCRIPT_ENCL_POS_MAX=512$/readonly SCRIPT_ENCL_POS_MAX=4/' \
  -e '/# M-EXEC-TICK-GUARD/s/\[ "\$script_encl_all" -eq 1 \] && //' "$HOOK" > "${ENCL_HOOKS}/block-destructive-xsmallpng.sh"
for xt_c in xforced xrev xnoguard xnohidx xnostate xnotail xnonestb xsmallpng; do
  /bin/chmod +x "${ENCL_HOOKS}/block-destructive-${xt_c}.sh"
done
xt_marks="$(/usr/bin/awk '/# >>> M-EXEC-TICK$/ { f = 1 } f { n++ } /# <<< M-EXEC-TICK$/ { f = 0 } END { printf "%d", n }' "$HOOK")"
xt_nest="$(/usr/bin/grep -c 'M-EXEC-TICK-NEST' "$HOOK" || true)"
xt_mk_ok=1
for xt_m in "# >>> M-EXEC-TICK" "M-EXEC-TICK-ALL" "M-EXEC-TICK-GUARD" "M-EXEC-TICK-STATE" "M-EXEC-TICK-NEST" "M-EXEC-TICK-TAIL" "# <<< M-EXEC-TICK"; do
  /usr/bin/grep -qF -- "$xt_m" "$HOOK" || xt_mk_ok=0
done
if [ "$xt_mk_ok" = 1 ] && [ "$xt_marks" -gt 0 ] && [ "$xt_nest" -gt 0 ]; then
  /usr/bin/printf 'PASS: EXEC-TEXT-MARKS the hook carries the M-EXEC-TICK block (%s lines) and its markers, so the copies below are live\n' "$xt_marks"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: EXEC-TEXT-MARKS the hook lacks the M-EXEC-TICK block or a marker; every copy below is inert\n'
  FAIL=$((FAIL + 1)); xt_marks="missing"; xt_nest=999
fi
encl_shape_arm "EXEC-TEXT-COPY-xforced: only the exec arm's phase constant differs" block-destructive-xforced.sh "1/1"
encl_shape_arm "EXEC-TEXT-COPY-xrev: the M-EXEC-TICK block removed (${xt_marks} lines)" block-destructive-xrev.sh "${xt_marks}/0"
encl_shape_arm "EXEC-TEXT-COPY-xnoguard: the position-coverage guard removed" block-destructive-xnoguard.sh "1/1"
encl_shape_arm "EXEC-TEXT-COPY-xnohidx: the first-word guard removed" block-destructive-xnohidx.sh "1/1"
encl_shape_arm "EXEC-TEXT-COPY-xnostate: the quote-state condition widened to every state" block-destructive-xnostate.sh "1/1"
encl_shape_arm "EXEC-TEXT-COPY-xnotail: the tail condition removed" block-destructive-xnotail.sh "1/1"
encl_shape_arm "EXEC-TEXT-COPY-xnonestb: the nested-opener stop removed, remainder budget at 64" block-destructive-xnonestb.sh "$(( xt_nest + 1 ))/1"
encl_shape_arm "EXEC-TEXT-COPY-xsmallpng: position ceiling at 4 and the guard removed" block-destructive-xsmallpng.sh "2/2"

XT_TICK=0
xt_count() { # counts ENCL_ROWS rows whose path begins with a backtick -> XT_TICK
  local line
  XT_TICK=0
  while IFS= read -r line; do
    case "$line" in
      *'"path":"`'*) XT_TICK=$((XT_TICK + 1)) ;;
    esac
  done <<<"$ENCL_ROWS"
}
# xt_arm <label> <copy> <command> <verdict> <tick: 0 | 1+ | -> [<B pattern>] [<rows>:<arm>]
# The last, where an arm's label claims it: the call added exactly <rows> rows, one of which carries
# <arm> at the enclosure position.
xt_arm() {
  local name="$1" copy="$2" cmd="$3" want="$4" tick="$5" pat="${6:-}" rows="${7:-}" ok=1 why=""
  encl_run "$copy" "$cmd"
  xt_count
  if [ "$ENCL_V" != "$want" ]; then ok=0; why="verdict=${ENCL_V}"; fi
  case "$tick" in
    0) if [ "$XT_TICK" -ne 0 ]; then ok=0; why="${why} backtick-led rows=${XT_TICK}"; fi ;;
    1+) if [ "$XT_TICK" -lt 1 ]; then ok=0; why="${why} backtick-led rows=0 (wanted at least 1)"; fi ;;
  esac
  if [ -n "$rows" ]; then
    if [ "$ENCL_NROWS" != "${rows%%:*}" ]; then ok=0; why="${why} rows=${ENCL_NROWS} (wanted ${rows%%:*})"; fi
    if ! encl_row_has "${rows#*:}"; then ok=0; why="${why} no row carries arm ${rows#*:} at the enclosure position"; fi
  fi
  if [ "$ok" = 1 ] && [ "$want" = "B" ] && ! /usr/bin/grep -q "${pat:-BLOCK-DESTRUCTIVE-022}" <<<"$ENCL_ERR"; then ok=0; why="refusal lacks ${pat:-BLOCK-DESTRUCTIVE-022}"; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s (%s, backtick-led rows %s)\n' "$name" "$ENCL_V" "$XT_TICK"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted %s with backtick-led rows %s; observed%s\n  stderr: %s\n' "$name" "$want" "$tick" " ${why# }" "$ENCL_ERR"
    FAIL=$((FAIL + 1))
  fi
}
xt_nl=$'\n'
xt_lt01="true <<'EOF'${xt_nl}notes${xt_nl}\`${ENCL_OK}\` is the entry point${xt_nl}EOF"
xt_lt01na="true <<'EOF'${xt_nl}notes${xt_nl}\`${ENCL_NA}\` is the entry point${xt_nl}EOF"
xt_lt02="git commit -m \"\$(cat <<'EOF'${xt_nl}Fix the walk${xt_nl}\`${ENCL_OK}\` now reads it${xt_nl}EOF${xt_nl})\""
xt_lt03="git commit -m 'Fix it (\`${ENCL_OK}\` reads the file)'"
# Must-not-flag: text that executes nothing writes no exec-arm row (RED: each reads W).
xt_arm "EXEC-TEXT-NF-01: an inert here-document line opening with a code span naming a listed script" block-destructive.sh "$xt_lt01" a 0
xt_arm "EXEC-TEXT-NF-01-forced: the same with the exec arm at enforce" block-destructive-xforced.sh "$xt_lt01" a 0
xt_arm "EXEC-TEXT-NF-02: the commit idiom, a code span at quote state 2" block-destructive.sh "$xt_lt02" a 0
xt_arm "EXEC-TEXT-NF-03: a code span opening a parenthesized span inside a single-quoted argument" block-destructive.sh "$xt_lt03" a 0
xt_arm "EXEC-TEXT-NF-04: the same text naming an unlisted script keeps one row, from the enclosure position only" block-destructive.sh "$xt_lt01na" W 0 "" 1:exec
xt_arm "EXEC-TEXT-NF-04-forced: at enforce that enclosure row refuses" block-destructive-xforced.sh "$xt_lt01na" B 0
# The boundary with #8548 (CIAC-1): a substitution outside an assignment's value is this card's.
xt_arm "SUBST-BOUNDARY-TEXT-LISTED: a backtick substitution as the first word, running a listed script" block-destructive.sh "\`${ENCL_OK}\`" a 0
xt_arm "SUBST-BOUNDARY-TEXT-LISTED-forced: the same at enforce" block-destructive-xforced.sh "\`${ENCL_OK}\`" a 0
xt_arm "SUBST-BOUNDARY-TEXT-UNLISTED: running an unlisted script is still recorded, from the enclosure position" block-destructive.sh "\`${ENCL_NA}\`" W 0 "" 1:exec
xt_arm "SUBST-BOUNDARY-TEXT-UNLISTED-forced: and refused at enforce" block-destructive-xforced.sh "\`${ENCL_NA}\`" B 0
xt_arm "SUBST-BOUNDARY-TEXT-UNLISTED-pair: without the view the declined word goes unread (the guard's reason)" block-destructive-xsmallpng.sh "true \$(a) \$(b) \$(c) \$(d); \`${ENCL_NA}\`" a -
xt_arm "EXEC-TEXT-MF-dollar: a backtick substitution running a variable-bearing path is still recorded, from the enclosure position" block-destructive.sh '`$NOPE8490/x.sh`' W 0 "" 1:exec
# Declared residuals: today's first-view reading kept (green before and after), each with the mutant that would lose it.
xt_mfcar="bash -c \$(echo -n) 'true${xt_nl}\`${ENCL_NA}\`'"
xt_arm "EXEC-TEXT-MF-carrier: a carrier-head program string whose later line opens a backtick substitution keeps the first view's record" block-destructive.sh "$xt_mfcar" W 1+
xt_arm "EXEC-TEXT-MF-carrier-pair: without the quote-state condition that record is lost" block-destructive-xnostate.sh "$xt_mfcar" a -
xt_pinsq="git commit -m 'Fix${xt_nl}\`${ENCL_OK}\` reads it'"
xt_arm "EXEC-TEXT-PIN-sq: a single-quoted run spanning lines keeps today's reading (declared residual)" block-destructive.sh "$xt_pinsq" W 1+
xt_arm "EXEC-TEXT-PIN-sq-pair: without the quote-state condition it is declined" block-destructive-xnostate.sh "$xt_pinsq" a -
xt_arm "EXEC-TEXT-PIN-ceiling: past the position ceiling today's reading stands" block-destructive-smallp.sh "true \$(a) \$(b) \$(c) \$(d); \`${ENCL_NA}\`" W 1+
xt_arm "EXEC-TEXT-PIN-tail: a closer followed by a variable-bearing script tail keeps today's reading" block-destructive.sh '`/tmp/pmo-encl-ok.sh`${X8490}.sh' W 1+
xt_arm "EXEC-TEXT-PIN-tail-pair: without the tail condition it is declined" block-destructive-xnotail.sh '`/tmp/pmo-encl-ok.sh`${X8490}.sh' a -
xt_arm "EXEC-TEXT-PIN-prefix: behind a wrapper word the word is not the first, and today's reading stands" block-destructive.sh "command \`${ENCL_OK}\`" W 1+
xt_arm "EXEC-TEXT-PIN-prefix-pair: without the first-word guard it is declined" block-destructive-xnohidx.sh "command \`${ENCL_OK}\`" a -
xt_arm "EXEC-TEXT-PIN-sep: a substitution holding a pipe has no closer on its segment, and today's reading stands" block-destructive.sh "\`${ENCL_OK} | cat\`" W 1+
xt_arm "EXEC-TEXT-PIN-escape: a substitution holding an escaped character keeps today's reading" block-destructive.sh "\`${ENCL_OK} a\\ b\`" W 1+
xt_arm "EXEC-TEXT-PIN-dollar-paren: a command word opened by \$( keeps today's reading (D-2)" block-destructive.sh "\$(${ENCL_OK})" W -
# CD-1 (review FM-1): past the remainder budget a position holds only the text up to a nested opener,
# so the decline stops on a nested opener before the closer and today's first-view record stands.
xt_rem="echo \$(true) \$(true) xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; \`/tmp/pmo\$(true)-encl-na.sh\`"
xt_arm "EXEC-TEXT-PIN-remainder: a nested opener before the closer keeps the first view's record past the remainder budget" block-destructive-smallb.sh "$xt_rem" W 1+
xt_arm "EXEC-TEXT-PIN-remainder-pair: without the nested-opener stop the execution goes unrecorded" block-destructive-xnonestb.sh "$xt_rem" a -
# Stage 7: the quote-led residual in its blank-carrying spelling, the `$(` spelling at enforce, and the
# empty-output hand-off, each with its corpus row (TK07, TK08). A double-quoted substitution as the
# command word, whose closer falls in a later token, opens with a quote, so the decline never reads it;
# it normalizes as unresolvable and is recorded with a backtick-led path, its script listed. A
# substitution at command position whose output yields no field hands command position to the next
# word, which only the position at the closer reads.
xt_pinq="\"\`${ENCL_OK} a\`\""
xt_arm "EXEC-TEXT-PIN-quote: a double-quoted backtick command word whose closer falls in a later token keeps today's reading" block-destructive.sh "$xt_pinq" W 1+
xt_arm "EXEC-TEXT-PIN-quote-forced: and is refused at enforce, its script listed" block-destructive-xforced.sh "$xt_pinq" B -
xt_arm "EXEC-TEXT-PIN-dollar-paren-forced: a command word opened by \$( is refused at enforce, its script listed (D-2)" block-destructive-xforced.sh "\$(${ENCL_OK})" B -
xt_handoff="\`true\` ${ENCL_NA}"
xt_arm "EXEC-TEXT-PIN-handoff: a substitution at command position followed by an unlisted script word keeps that word's one record, from the closer's position" block-destructive.sh "$xt_handoff" W 0 "" 1:exec
xt_arm "EXEC-TEXT-PIN-handoff-forced: and refuses it at enforce" block-destructive-xforced.sh "$xt_handoff" B -

# --- #8326: the here-document receiver read (release script-guard-refuses-only-what-executes; design
# on sub-task #9061). An inert body behind a grammar opener, or received by cat under the whole-command
# no-consumer test, is excised; a receiver that executes its input, a consumer of cat's output, and a
# receiver text holding a compound-command closer keep the body. Rows HL01-HL12 and HM01-HM11 are read
# by id; a shape no row carries is spelled here. Each arm reads the shipped copy and the enclosure
# family's forced copy.
#   hdnocons  the whole-command no-consumer test removed (its one line, M-HD-RECV-NOCONS)
#   hdcloser  the closer rule removed (its one line, M-HD-RECV-CLOSER)
#   hdreach   the new reach's enclosure test removed (its one line, M-HD-RECV-NEWREACH)
#   hdwide    the closer read widened back to any `)` from the head on (its one line, M-HD-RECV-CLOSES)
#   hdnodq    the closer read blind to double quotes (its one line, M-HD-RECV-DQ-OPEN)
#   hdnosq    the closer read blind to single quotes (its one line, M-HD-RECV-SQ)
/usr/bin/sed '/# M-HD-RECV-NOCONS$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdnocons.sh"
/usr/bin/sed '/# M-HD-RECV-CLOSER$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdcloser.sh"
/usr/bin/sed '/# M-HD-RECV-NEWREACH$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdreach.sh"
/usr/bin/sed '/# M-HD-RECV-CLOSES$/s/script_hd_recv_closes "\$_t" && //' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdwide.sh"
/usr/bin/sed '/# M-HD-RECV-DQ-OPEN$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdnodq.sh"
/usr/bin/sed '/# M-HD-RECV-SQ$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdnosq.sh"
/bin/chmod +x "${ENCL_HOOKS}/block-destructive-hdwide.sh" "${ENCL_HOOKS}/block-destructive-hdnodq.sh" "${ENCL_HOOKS}/block-destructive-hdnosq.sh"
/bin/chmod +x "${ENCL_HOOKS}/block-destructive-hdnocons.sh" "${ENCL_HOOKS}/block-destructive-hdcloser.sh" "${ENCL_HOOKS}/block-destructive-hdreach.sh"
encl_shape_arm "HD-RECV-COPY-nocons: the no-consumer mutant removes its one line" block-destructive-hdnocons.sh "1/0"
encl_shape_arm "HD-RECV-COPY-closer: the closer-rule mutant removes its one line" block-destructive-hdcloser.sh "1/0"
encl_shape_arm "HD-RECV-COPY-reach: the new-reach mutant removes its one line" block-destructive-hdreach.sh "1/0"
encl_shape_arm "HD-RECV-COPY-wide: the widened closer read rewrites its one line" block-destructive-hdwide.sh "1/1"
encl_shape_arm "HD-RECV-COPY-nodq: the double-quote-blind closer read removes its one line" block-destructive-hdnodq.sh "1/0"
encl_shape_arm "HD-RECV-COPY-nosq: the single-quote-blind closer read removes its one line" block-destructive-hdnosq.sh "1/0"

# --- admitted: an inert body handed to a receiver that does not execute it (RED: each reads B) ---
qscan_arm "HD-RECV-ADMIT-paren: a subshell opener before a carrier receiver" HL01 a a -
qscan_arm "HD-RECV-ADMIT-paren-attached: the subshell opener attached to the carrier word" HL02 a a -
qscan_arm "HD-RECV-ADMIT-brace: a brace-group opener before a carrier receiver" HL03 a a -
qscan_arm "HD-RECV-ADMIT-brace-printf: the same before another carrier" HL04 a a -
qscan_arm "HD-RECV-ADMIT-kw: a reserved-word opener before a carrier receiver" HL05 a a -
qscan_arm "HD-RECV-ADMIT-kw-gh: the same before another carrier" HL06 a a -
qscan_arm "HD-RECV-ADMIT-bang: the negation word before a carrier receiver" HL07 a a -
qscan_arm "HD-RECV-ADMIT-bang-echo: the same before another carrier" HL08 a a -
qscan_arm "HD-RECV-ADMIT-cat-print: a cat receiver, quoted delimiter, no tail" HL09 a a -
qscan_arm "HD-RECV-ADMIT-cat-print-rpt: the same under another delimiter" HL10 a a -
qscan_arm "HD-RECV-ADMIT-cat-redirect: a cat receiver writing a file, the redirection ahead of the operator" HL11 a a -
qscan_arm "HD-RECV-ADMIT-cat-redirect-after: the same, the redirection after the operator" HL12 a a -
# Re-labelled from AC-ENCL-RESIDUAL-heredoc-kept, a pin of a body left in place (recorded at warn and
# refused at enforce before): its receiver is cat, so its shape is this card's fix and the arm is
# fix-evidence.
encl_arm "HD-RECV-ADMIT-cat-redirect-span: a cat receiver writing a file, its body holding a code span naming a script" \
  "cat > notes.md <<'EOF'
Run \`bash ${ENCL_NA}\` to reproduce
EOF" a a a

# --- must flag: today's refusal stands (each green before and after) ---
qscan_arm "HD-RECV-MF-paren-shell: a subshell opener before a shell-interpreter receiver" HM01 B B -
qscan_arm "HD-RECV-MF-cat-pipe: a cat receiver whose output pipes into an interpreter" HM02 B B -
qscan_arm "HD-RECV-MF-cat-fd-pipe: a cat receiver with a descriptor duplication, then a pipe" HM03 B B -
qscan_arm "HD-RECV-MF-cat-procsub: a cat receiver whose output goes to a process substitution" HM04 B B -
qscan_arm "HD-RECV-MF-cat-subst-head: a cat receiver inside a substitution at command position" HM05 B B -
qscan_arm "HD-RECV-MF-cat-earlier-subst: a cat receiver inside a substitution opened on an earlier line" HM06 B B -
qscan_arm "HD-RECV-MF-cat-later-pipe: a cat receiver inside a group closed and piped after the body" HM07 B B -
qscan_arm "HD-RECV-MF-cat-bare-dollar: a cat receiver, bare delimiter, a dollar in the body" HM08 B B -
qscan_arm "HD-RECV-MF-loop-close: a loop closer receiving the here-document" HM10 B B -
qscan_arm "HD-RECV-CTL-nonmember: a receiver on no list (R-4 stands)" HM11 B B -
hd_nl=$'\n'
hd_arith="(( echo <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF${hd_nl}))"
hd_closer="( echo ) <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_closer_cat="( cat ) <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_coproc="coproc bash; cat <<'EOF' >&\${COPROC[1]}${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_tail="( bash; echo ) <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-MF-arith: an arithmetic opener is not stepped" "$hd_arith" B B -
encl_arm "HD-RECV-MF-closer: a stepped opener whose receiver text holds a closer keeps the body" "$hd_closer" B B -
encl_arm "HD-RECV-MF-closer-cat: a cat head whose receiver text holds a closer keeps the body" "$hd_closer_cat" B B -
encl_arm "HD-RECV-MF-cat-coproc: a cat receiver writing into a coprocess keeps the body" "$hd_coproc" B B -
encl_arm "HD-RECV-MF-group-tail: a here-document after a subshell closer keeps its body" "$hd_tail" B B -
encl_mut_arm "HD-RECV-MF-group-tail-pair: without the closer rule that body is excised" block-destructive-hdcloser.sh "$hd_tail" a
# Added at GREEN, from the self-review: the new reach meeting an enclosure reading off the list. Each keeps
# today's verdict (B, and an allow with no record); the pair shows the line that keeps the first.
hd_reach_sh="( echo \$(bash <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF${hd_nl}) )"
hd_reach_cat="( cat <<'EOF'${hd_nl}plain text${hd_nl}EOF${hd_nl})"
encl_arm "HD-RECV-MF-reach-encl-shell: a stepped opener before a carrier whose substitution opens a shell that receives the here-document keeps the body at every phase" "$hd_reach_sh" B B -
encl_mut_arm "HD-RECV-MF-reach-encl-shell-pair: without the new-reach line the shipped copy only records it" block-destructive-hdreach.sh "$hd_reach_sh" W
encl_arm "HD-RECV-CTL-reach-encl-cat: cat behind a subshell opener with a plain body stays allowed, with no record" "$hd_reach_cat" a a -
if wc_row_cmd HM02; then
  encl_mut_arm "HD-RECV-MF-cat-pipe-pair: without the no-consumer test the piped body is excised [row HM02]" block-destructive-hdnocons.sh "$WC_CMDX" a
else
  /usr/bin/printf 'FAIL: HD-RECV-MF-cat-pipe-pair\n  row HM02 is not a block-destructive row of the corpus\n'
  FAIL=$((FAIL + 1))
fi

# --- the closer read: a `)` keeps the body only when it closes an opener before the receiver's head ---
# A parenthesis inside a carrier's quoted argument closes nothing the receiver sits inside, so the body
# is excised as it was before this card; the copy whose read counts any `)` keeps it. A real closer after
# a quoted span holding an unclosed `(` still keeps the body, and each quote-blind copy loses it.
hd_cost_q="gh pr create --title \"fix(x): y\" --body-file - <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-NARROW-quoted: a carrier whose quoted argument holds a parenthesis, then an inert here-document, is excised as before" "$hd_cost_q" a a -
encl_mut_arm "HD-RECV-NARROW-quoted-pair: the copy whose closer read counts any parenthesis keeps that body" block-destructive-hdwide.sh "$hd_cost_q" B
hd_close_dq="( bash; echo \"a (\" ) <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_close_sq="( bash; echo 'a (' ) <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-MF-closer-dq: a subshell closer after a double-quoted argument holding an unclosed parenthesis keeps the body" "$hd_close_dq" B B -
encl_mut_arm "HD-RECV-MF-closer-dq-pair: the double-quote-blind closer read excises it" block-destructive-hdnodq.sh "$hd_close_dq" a
encl_arm "HD-RECV-MF-closer-sq: a subshell closer after a single-quoted argument holding an unclosed parenthesis keeps the body" "$hd_close_sq" B B -
encl_mut_arm "HD-RECV-MF-closer-sq-pair: the single-quote-blind closer read excises it" block-destructive-hdnosq.sh "$hd_close_sq" a
# The closer read keeps the body on what it does not model (Stage 7 DS-1 to DS-3). Lifted out of the
# hook and run alone on plain receiver texts: an ANSI-C quote, a brace or bracket expansion, an unquoted
# brace or bracket, and a `}` word read as a closer; the controls keep their earlier answers. The pair
# runs the same text on a copy whose unmodelled-text lines are removed.
hd_read_lib="${ENCL_ROOT}/hd-read.lib"
/usr/bin/sed '/# M-HD-RECV-UNMODELED$/d' "$HOOK" > "${ENCL_ROOT}/hd-model-off.sh"
hd_read_lift() { # $1 = hook file, $2 = lib out
  /usr/bin/awk '/^script_hd_recv_closes\(\) / || /^script_hd_recv_text\(\) / { f = 1; k++ } f { print; if ($0 == "}") f = 0 } END { exit k == 2 ? 0 : 1 }' "$1" > "$2" || return 1
  /usr/bin/printf '%s\n' 'script_ceil_check() { return 0; }' >> "$2"
}
hd_read_lift "$HOOK" "$hd_read_lib"; hd_read_lift "${ENCL_ROOT}/hd-model-off.sh" "${ENCL_ROOT}/hd-read-off.lib"
hd_read() { # $1 = lib, $2 = receiver text -> prints script_hdrecv_closer
  /bin/bash -c '. "$1"; script_hd_recv_text "$2"; printf "%s" "$script_hdrecv_closer"' _ "$1" "$2" 2>/dev/null
}
hd_read_arm() { # <label> <lib> <text> <want>
  local got; got="$(hd_read "$2" "$3")"
  if [ "$got" = "$4" ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else /usr/bin/printf 'FAIL: %s\n  closer=%s (wanted %s)\n' "$1" "${got:-none}" "$4"; FAIL=$((FAIL + 1)); fi
}
hd_t_ansic="echo \$'\\'\"' ) \""
hd_t_pexp='echo ${x:-(} ) '
hd_t_glob='echo [(] ) '
hd_t_brace='echo { x } '
hd_read_arm "HD-RECV-READ-ansic: a receiver text holding an ANSI-C quote keeps the body" "$hd_read_lib" "$hd_t_ansic" 1
hd_read_arm "HD-RECV-READ-pexp: a receiver text holding a parameter expansion's parenthesis keeps the body" "$hd_read_lib" "$hd_t_pexp" 1
hd_read_arm "HD-RECV-READ-glob: a receiver text holding a bracket expression's parenthesis keeps the body" "$hd_read_lib" "$hd_t_glob" 1
hd_read_arm "HD-RECV-READ-brace: a receiver text holding a brace word keeps the body, beside an opening one too" "$hd_read_lib" "$hd_t_brace" 1
hd_read_arm "HD-RECV-READ-ctl-title: a parenthesised quoted title still closes nothing" "$hd_read_lib" 'gh pr create --title "fix(x): y" --body-file - ' 0
hd_read_arm "HD-RECV-READ-ctl-subst: a closed substitution in a carrier's arguments still closes nothing" "$hd_read_lib" 'gh issue comment $(cat list.txt) --body-file - ' 0
hd_read_arm "HD-RECV-READ-ctl-closer: a bare closer still keeps the body" "$hd_read_lib" ' echo ) ' 1
hd_read_arm "HD-RECV-READ-ansic-pair: the copy that models nothing extra loses that body" "${ENCL_ROOT}/hd-read-off.lib" "$hd_t_ansic" 0
# A receiver that only carries cat's name (Stage 7 F-2): cat is admitted only as itself or a system
# path, and not in a command that rebinds a command name. Each pair runs a copy without the line.
/usr/bin/sed '/# M-HD-RECV-CATPATH$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdcatpath.sh"
/usr/bin/sed '/# M-HD-RECV-REBIND$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdrebind.sh"
/bin/chmod +x "${ENCL_HOOKS}/block-destructive-hdcatpath.sh" "${ENCL_HOOKS}/block-destructive-hdrebind.sh"
encl_shape_arm "HD-RECV-COPY-catpath: the cat-path mutant removes its one line" block-destructive-hdcatpath.sh "1/0"
encl_shape_arm "HD-RECV-COPY-rebind: the rebinding mutant removes its one line" block-destructive-hdrebind.sh "1/0"
hd_cat_path="./tool/cat <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_cat_rebind="alias cat=bash${hd_nl}cat <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-MF-cat-path: a receiver whose path only ends in cat keeps the body" "$hd_cat_path" B B -
encl_mut_arm "HD-RECV-MF-cat-path-pair: without the cat-path line that body is excised" block-destructive-hdcatpath.sh "$hd_cat_path" a
encl_arm "HD-RECV-MF-cat-rebind: a cat receiver in a command that rebinds a command name keeps the body" "$hd_cat_rebind" B B -
encl_mut_arm "HD-RECV-MF-cat-rebind-pair: without the rebinding line that body is excised" block-destructive-hdrebind.sh "$hd_cat_rebind" a
# Stage 7 pass 2. A `}` that begins a word and is followed directly by a redirection or a control
# character closes a group (P2-1); the logical-line reading takes cat only as itself or a system path
# (P2-2); a rebinding is read however its builtin is quoted or spaced, and through the shells' alias and
# command tables (P2-3); the rebinding test and the unmodelled-text read each carry a declared cost
# (P2-5); and the unmodelled-text classes are shown at the hook, not only in the lifted read (P2-6).
# Rows HM12-HM19. A stepped opener holds no receiver that reads its input, so the hook-level classes run
# on a group's last command, before a carrier and before cat.
#   hdbraceop   the brace-and-operator line removed (its one line, M-HD-RECV-BRACE-OP)
#   hdcatlm     the logical-line cat value taken from the basename alone (its one line, M-HD-RECV-CATPATH-LM)
#   hdmodeloff  the unmodelled-text lines removed (its two lines, M-HD-RECV-UNMODELED)
#   hdmodelbr   only the brace-and-bracket line of those two removed
/usr/bin/sed '/# M-HD-RECV-BRACE-OP$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdbraceop.sh"
/usr/bin/sed '/# M-HD-RECV-CATPATH-LM$/s/case "\$script_head" in cat|\/bin\/cat|\/usr\/bin\/cat) _lm=2 ;; esac/_lm=2/' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdcatlm.sh"
/usr/bin/sed '/# M-HD-RECV-UNMODELED$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdmodeloff.sh"
/usr/bin/sed '/if (c == "{" || c == "\[") { print "1"; exit }   # M-HD-RECV-UNMODELED$/d' "$HOOK" > "${ENCL_HOOKS}/block-destructive-hdmodelbr.sh"
/bin/chmod +x "${ENCL_HOOKS}/block-destructive-hdbraceop.sh" "${ENCL_HOOKS}/block-destructive-hdcatlm.sh" "${ENCL_HOOKS}/block-destructive-hdmodeloff.sh" "${ENCL_HOOKS}/block-destructive-hdmodelbr.sh"
encl_shape_arm "HD-RECV-COPY-braceop: the brace-and-operator mutant removes its one line" block-destructive-hdbraceop.sh "1/0"
encl_shape_arm "HD-RECV-COPY-catlm: the logical-line cat-path mutant rewrites its one line" block-destructive-hdcatlm.sh "1/1"
encl_shape_arm "HD-RECV-COPY-modeloff: the unmodelled-text mutant removes its two lines" block-destructive-hdmodeloff.sh "2/0"
encl_shape_arm "HD-RECV-COPY-modelbr: the brace-and-bracket mutant removes its one line" block-destructive-hdmodelbr.sh "1/0"
hd_read_lift "${ENCL_HOOKS}/block-destructive-hdmodelbr.sh" "${ENCL_ROOT}/hd-read-br.lib"
hd_read_arm "HD-RECV-READ-brace-op: a receiver text holding a brace word followed directly by a redirection keeps the body" "$hd_read_lib" 'cat }>/dev/null ' 1
hd_read_arm "HD-RECV-READ-glob-pair: the copy without the brace-and-bracket line loses the bracket expression's body" "${ENCL_ROOT}/hd-read-br.lib" "$hd_t_glob" 0
qscan_arm "HD-RECV-MF-brace-op: a cat head whose brace word is followed directly by a redirection closes the group and keeps the body" HM12 B B -
qscan_mut "HD-RECV-MF-brace-op-pair: without the brace-and-operator line that body is excised" block-destructive-hdbraceop.sh HM12 a
qscan_arm "HD-RECV-MF-cat-cont: a continuation joining a path that only ends in cat to a carrier's line keeps the body" HM13 B B -
qscan_mut "HD-RECV-MF-cat-cont-pair: with the logical-line cat value read from the basename alone that body is excised" block-destructive-hdcatlm.sh HM13 a
hd_rb_quoted="'alias' cat=bash${hd_nl}cat <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_rb_tab="function"$'\t'"cat { bash; }${hd_nl}cat <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_rb_btable="BASH_ALIASES[cat]=bash${hd_nl}cat <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
hd_rb_ztable="commands[cat]=/bin/bash${hd_nl}cat <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-MF-cat-rebind-quoted: a quoted rebinding builtin keeps a cat-received body" "$hd_rb_quoted" B B -
encl_arm "HD-RECV-MF-cat-rebind-tab: a function definition whose keyword is followed by a tab keeps a cat-received body" "$hd_rb_tab" B B -
encl_arm "HD-RECV-MF-cat-rebind-table: an assignment to bash's alias table keeps a cat-received body" "$hd_rb_btable" B B -
encl_arm "HD-RECV-MF-cat-rebind-ztable: an assignment to zsh's command table keeps a cat-received body" "$hd_rb_ztable" B B -
hd_rb_prose="cat <<'EOF'${hd_nl}the helper function is described below${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-COST-rebind-prose: a cat-received body whose prose names a rebinding word is kept and adjudicated, because the rebinding test reads the whole command (declared cost)" "$hd_rb_prose" B B -
hd_cost_ub="gh api repos/{owner}/x --title \"a (b)\" --input - <<'EOF'${hd_nl}bash ${ENCL_NA}${hd_nl}EOF"
encl_arm "HD-RECV-COST-unmodeled-carrier: a carrier whose arguments hold an unquoted brace beside a quoted parenthesis keeps its inert body (declared cost)" "$hd_cost_ub" B B -
encl_mut_arm "HD-RECV-COST-unmodeled-carrier-pair: the copy that models nothing extra excises that body, as before this rule" block-destructive-hdmodeloff.sh "$hd_cost_ub" a
qscan_arm "HD-RECV-MF-hook-ansic: an ANSI-C quote in a group's last command before a carrier keeps the body at the hook" HM14 B B -
qscan_mut "HD-RECV-MF-hook-ansic-pair: the copy that models nothing extra excises that body" block-destructive-hdmodeloff.sh HM14 a
qscan_arm "HD-RECV-MF-hook-pexp: a parameter expansion holding a parenthesis in a group's last command before a carrier keeps the body at the hook" HM15 B B -
qscan_arm "HD-RECV-MF-hook-glob: a bracket expression holding a parenthesis in a group's last command before a carrier keeps the body at the hook" HM16 B B -
qscan_arm "HD-RECV-MF-hook-ansic-cat: the same ANSI-C quote before a cat head keeps the body at the hook" HM17 B B -
qscan_arm "HD-RECV-MF-hook-pexp-cat: the same parameter expansion before a cat head keeps the body at the hook" HM18 B B -
qscan_arm "HD-RECV-MF-hook-glob-cat: the same bracket expression before a cat head keeps the body at the hook" HM19 B B -
# Stage 7 pass 3 (P3-3). A function definition spelled with a parenthesis names none of the rebinding
# test's words, so what keeps a cat-received body behind it is the no-consumer test's parenthesis. Row
# HM20; its pair runs the copy without the no-consumer line, where the definition's own body is one the
# walk passes and no text of the command holds a rebinding word, so the excised body leaves it allowed.
qscan_arm "HD-RECV-MF-cat-rebind-paren: a function definition of cat spelled with a parenthesis ahead of a cat head keeps the body" HM20 B B -
qscan_mut "HD-RECV-MF-cat-rebind-paren-pair: without the no-consumer test that body is excised" block-destructive-hdnocons.sh HM20 a

/bin/rm -rf "$ENCL_ROOT"

# ---- AC-022-X* (#8314, DT pass 3): the -022 separator split is a linear pass ----
#
# The script-execution rule split every command that reaches it into segments with three global
# pattern substitutions over the whole command, and on bash 3.2 each costs more than linear time
# in the text it scans once that text carries the separator it replaces — so a large command could
# hold this hook past the runtime's command-hook timeout, after which a PreToolUse hook does not
# block. A command of at least SCRIPT_LINEAR_MIN characters is now split first by one tr pass in
# the C locale, on the line marked `# linear: segments`. X-EQ lifts that block out of the hook and
# runs it with the bound at 0 (the pass runs) and at 10^9 (the substitutions alone, the code before
# this change): equal byte for byte on a dense input — every byte from 1 to 255, multibyte letters,
# invalid UTF-8 and each operator — and on its edge endings, in en_US.UTF-8 and in C, alone and with
# them, beside a near miss that must differ. X1 to X24 run the hook under a watchdog on four benign
# shapes at 10, 20 and 40 KB in both locales — the dollar filler, separator-dense, one big quoted
# span and redirection-dense — each inside the budget and allowed. X-CTL is the instrument's
# sensitivity: a copy whose bound never lets the pass run is stopped at the budget on a long
# separator-dense command in UTF-8. X-FB holds the fallback: a copy whose tr does not exist reads
# the shipped hook's verdicts on a long command and raises no hook error.
LIN_LIMIT="${LIN_LIMIT_DS:-200}"   # tenths of a second
# lin_ratio <tenths> <limit> — a run's cost as a share of its budget, or "stopped" when the watchdog ended it:
# what a timed arm prints in place of a time, so no output line pairs a command's size with a time.
lin_ratio() { if [ "$1" = -1 ]; then /usr/bin/printf stopped; else /usr/bin/awk -v d="$1" -v l="$2" 'BEGIN { printf "%.2f", (l > 0 ? d / l : 0) }'; fi; }
LIN_ROOT="$(/usr/bin/mktemp -d)"
LIN_HOOKS="${LIN_ROOT}/.claude/hooks"
/bin/mkdir -p "${LIN_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${LIN_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${LIN_HOOKS}/lib/" 2>/dev/null || true
/usr/bin/printf '%s\n' '/tmp/pmo-lin-ok.sh' > "${LIN_ROOT}/.claude/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${LIN_HOOKS}/.mode"
/bin/cp "$HOOK" "${LIN_HOOKS}/block-destructive.sh"
/usr/bin/sed 's/^readonly SCRIPT_LINEAR_MIN=256$/readonly SCRIPT_LINEAR_MIN=1000000000/' "$HOOK" > "${LIN_HOOKS}/block-destructive-nopass.sh"
/usr/bin/sed '/# linear: segments$/s#/usr/bin/tr#/nonexistent/tr#' "$HOOK" > "${LIN_HOOKS}/block-destructive-notool.sh"

# The dense input, three times over, and its edge endings.
LC_ALL=C /usr/bin/awk 'BEGIN { for (r = 0; r < 3; r++) { for (i = 1; i < 256; i++) printf "%c", i
  printf "%s", "naïve 日本 ü \377\303 x\342\202 y\200 ;&|()#`<>\"'"'"'\001\002\003\004\005\006\177>&<&&>>|.$\\ \t\n" } }' \
  > "${LIN_ROOT}/in-0"
{ /bin/cat "${LIN_ROOT}/in-0"; /usr/bin/printf '\n'; } > "${LIN_ROOT}/in-1"
{ /bin/cat "${LIN_ROOT}/in-0"; /usr/bin/printf '\n\n\n'; } > "${LIN_ROOT}/in-2"
{ /bin/cat "${LIN_ROOT}/in-0"; /usr/bin/printf ';'; } > "${LIN_ROOT}/in-3"
{ /bin/cat "${LIN_ROOT}/in-0"; /usr/bin/printf '.'; } > "${LIN_ROOT}/in-4"
: > "${LIN_ROOT}/in-5"
# lin_eval <locale> <bound> <block> <input> <out> — the block in a fresh /bin/bash on the input.
lin_eval() {
  LC_ALL="$1" /bin/bash -c 'set -euo pipefail; SCRIPT_LINEAR_MIN="$1"; script_lp=""
    script_segments="$(/bin/cat "$3"; printf x)"; script_segments="${script_segments%x}"
    . "$2"
    printf %s "$script_segments" > "$4"' _ "$2" "$3" "$4" "$5"
}
lin_why=""
M='# linear: segments' /usr/bin/awk 'BEGIN { m = ENVIRON["M"] }
  length($0) >= length(m) && substr($0, length($0) - length(m) + 1) == m { c++; n = 4 }
  n > 0 { print; n-- }
  END { exit c == 1 ? 0 : 1 }' "$HOOK" > "${LIN_ROOT}/block" || lin_why="${lin_why} no single line marked \`# linear: segments\`;"
/usr/bin/head -1 "${LIN_ROOT}/block" > "${LIN_ROOT}/one"
F="'\\012\\012\\012'" T="'\\012\\012\\001'" /usr/bin/awk 'BEGIN { f = ENVIRON["F"]; t = ENVIRON["T"] }
  !d && (i = index($0, f)) { $0 = substr($0, 1, i - 1) t substr($0, i + length(f)); d = 1 }
  { print }
  END { exit d ? 0 : 1 }' "${LIN_ROOT}/block" > "${LIN_ROOT}/near" || lin_why="${lin_why} the near-miss edit did not apply;"
if [ -z "$lin_why" ]; then
  for lin_loc in en_US.UTF-8 C; do
    for lin_k in 0 1 2 3 4 5; do
      lin_eval "$lin_loc" 1000000000 "${LIN_ROOT}/block" "${LIN_ROOT}/in-${lin_k}" "${LIN_ROOT}/ship.out" \
        || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the substitutions did not run;"
      lin_eval "$lin_loc" 0 "${LIN_ROOT}/block" "${LIN_ROOT}/in-${lin_k}" "${LIN_ROOT}/pass.out" \
        || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the pass did not run;"
      lin_eval "$lin_loc" 0 "${LIN_ROOT}/one" "${LIN_ROOT}/in-${lin_k}" "${LIN_ROOT}/one.out" \
        || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the pass line alone did not run;"
      /usr/bin/cmp -s "${LIN_ROOT}/ship.out" "${LIN_ROOT}/pass.out" || lin_why="${lin_why} [${lin_loc} in-${lin_k}] pass != substitutions;"
      /usr/bin/cmp -s "${LIN_ROOT}/ship.out" "${LIN_ROOT}/one.out" || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the pass alone != substitutions;"
    done
    lin_eval "$lin_loc" 1000000000 "${LIN_ROOT}/block" "${LIN_ROOT}/in-0" "${LIN_ROOT}/ship.out" || lin_why="${lin_why} [${lin_loc}] the reference did not run;"
    lin_eval "$lin_loc" 0 "${LIN_ROOT}/near" "${LIN_ROOT}/in-0" "${LIN_ROOT}/near.out" || lin_why="${lin_why} [${lin_loc}] the near miss did not run;"
    [ -s "${LIN_ROOT}/ship.out" ] || lin_why="${lin_why} [${lin_loc}] empty reference output;"
    /usr/bin/cmp -s "${LIN_ROOT}/ship.out" "${LIN_ROOT}/near.out" \
      && lin_why="${lin_why} [${lin_loc}] the near miss equals the substitutions (the comparison cannot see a difference);"
  done
fi
if [ -z "$lin_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-X-EQ: the \`# linear: segments\` pass equals the three substitutions byte for byte on a dense input and its edge endings in UTF-8 and C, alone and with them, and a near miss differs"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-X-EQ: the \`# linear: segments\` pass equals the three substitutions byte for byte" "$lin_why"; FAIL=$((FAIL + 1))
fi

# lin_fill <bytes> <head> <unit> <tail> — the head, as many units as fit, then the tail.
lin_fill() {
  H="$2" U="$3" T="$4" /usr/bin/awk -v n="$1" 'BEGIN { h = ENVIRON["H"]; u = ENVIRON["U"]; t = ENVIRON["T"]; s = h
    while (length(s) + length(u) + length(t) <= n) s = s u
    printf "%s", s t }'
}
# lin_cmd <shape> <bytes> <file> — one of the four benign shapes.
lin_cmd() {
  case "$1" in
    dollar)      lin_fill "$2" '' 'echo the quick brown fox jumps over $one lazy dog'$'\n' 'gh api repos/o/r' > "$3" ;;
    separator)   lin_fill "$2" 'echo gh;' 'echo a;echo b|cat&echo c;' 'gh api repos/o/r' > "$3" ;;
    quoted)      lin_fill "$2" "echo '" 'a b'$'\t''c;d&e|f(g)h#i`j<k>l"m'$'\n' "'"$'\n''gh api repos/o/r' > "$3" ;;
    redirection) lin_fill "$2" 'echo gh' ' >&2 2>&1 <&0 &>/dev/null >|/dev/null' ' ; gh api repos/o/r' > "$3" ;;
  esac
}
# lin_reap <pid> — stop a process and every process under it, children first, with KILL: bash
# defers a TERM until a running parameter expansion returns, which is the cost being timed, and a
# command-substitution subshell outlives a parent that dies.
lin_reap() {
  local c
  for c in $(/usr/bin/pgrep -P "$1" 2>/dev/null); do lin_reap "$c"; done
  kill -9 "$1" 2>/dev/null
}
# lin_timed <hook-file> <locale> <command-file> <limit> — the hook on the Bash payload of the
# command under a watchdog; sets LIN_DS (tenths elapsed, -1 when stopped) and LIN_EXIT.
LIN_DS=0
LIN_EXIT=0
lin_timed() {
  local pay="${LIN_ROOT}/payload.json" pid n=0
  bash_payload "$(/bin/cat "$3")" "$LIN_ROOT" > "$pay"
  LC_ALL="$2" /bin/bash "$1" < "$pay" > /dev/null 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$n" -ge "$4" ]; then
      lin_reap "$pid"; wait "$pid" 2>/dev/null
      LIN_DS=-1; LIN_EXIT=-1; return 0
    fi
    /bin/sleep 0.1; n=$(( n + 1 ))
  done
  LIN_EXIT=0; wait "$pid" || LIN_EXIT=$?
  LIN_DS="$n"
}
for lin_shape in dollar separator quoted redirection; do
  for lin_kb in 10 20 40; do lin_cmd "$lin_shape" $(( lin_kb * 1024 )) "${LIN_ROOT}/${lin_shape}-${lin_kb}.cmd"; done
done
lin_n=0
for lin_shape in dollar separator quoted redirection; do
  for lin_loc in en_US.UTF-8 C; do
    for lin_kb in 10 20 40; do
      lin_n=$(( lin_n + 1 ))
      lin_timed "${LIN_HOOKS}/block-destructive.sh" "$lin_loc" "${LIN_ROOT}/${lin_shape}-${lin_kb}.cmd" "$LIN_LIMIT"
      if [ "$LIN_DS" != -1 ] && [ "$LIN_EXIT" = 0 ]; then
        /usr/bin/printf 'PASS: %s\n' "AC-022-X${lin_n}: the ${lin_shape} shape at ${lin_kb} KB in ${lin_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
      else
        /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-X${lin_n}: the long ${lin_shape} shape in ${lin_loc} clears the hook inside the budget and is allowed — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
          "\"stopped\" is the watchdog ending the run at the budget; exit=${LIN_EXIT} (want 0)"; FAIL=$((FAIL + 1))
      fi
    done
  done
done
lin_timed "${LIN_HOOKS}/block-destructive-nopass.sh" en_US.UTF-8 "${LIN_ROOT}/separator-40.cmd" "$LIN_LIMIT"
if [ "$LIN_DS" = -1 ] && /usr/bin/grep -q -F -x 'readonly SCRIPT_LINEAR_MIN=1000000000' "${LIN_HOOKS}/block-destructive-nopass.sh"; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-X-CTL: a copy whose bound never lets the pass run is stopped at the budget on a long separator-dense command in UTF-8 — the instrument sees the cost"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-X-CTL: a copy whose bound never lets the pass run is stopped at the budget — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
    "exit=${LIN_EXIT}; a copy that finishes, or that carries no raised bound, cannot show X1-X24 measure anything (BROKEN PROBE)"; FAIL=$((FAIL + 1))
fi
# X-FB: the pass's tr repointed to a path that does not exist, so the pass fails and leaves the
# split to the substitutions. A long separator-dense command ending in an unlisted script run by an
# interpreter (refused), and the same ending in an echo (allowed).
lin_why=""
lin_tools="$(/usr/bin/grep -c -F '/nonexistent/tr' "${LIN_HOOKS}/block-destructive-notool.sh")" || true
[ "$lin_tools" = 1 ] || lin_why="${lin_why} the copy repoints ${lin_tools} pass lines, want 1;"
lin_pad="$(lin_fill 400 '' 'echo a;echo b|cat&echo c;' '')"
for lin_c in "b:2:${lin_pad}bash /tmp/pmo-lin-na.sh" "a:0:${lin_pad}echo done"; do
  lin_tag="${lin_c%%:*}"; lin_rest="${lin_c#*:}"
  lin_want="${lin_rest%%:*}"; lin_cmd_s="${lin_rest#*:}"
  lin_s=0; lin_t=0
  ( /usr/bin/printf '%s' "$(bash_payload "$lin_cmd_s" "$LIN_ROOT")" | /bin/bash "${LIN_HOOKS}/block-destructive.sh" > /dev/null 2>&1 ) || lin_s="$?"
  lin_err="$( { /usr/bin/printf '%s' "$(bash_payload "$lin_cmd_s" "$LIN_ROOT")" | /bin/bash "${LIN_HOOKS}/block-destructive-notool.sh" > /dev/null; } 2>&1 )" || lin_t="$?"
  [ "$lin_s" = "$lin_want" ] || lin_why="${lin_why} [${lin_tag}] shipped exits ${lin_s}, want ${lin_want};"
  [ "$lin_t" = "$lin_s" ] || lin_why="${lin_why} [${lin_tag}] the copy without its tr exits ${lin_t}, the shipped hook ${lin_s};"
  case "$lin_err" in *HOOK-ERROR*) lin_why="${lin_why} [${lin_tag}] the copy without its tr raised a hook error;" ;; esac
done
if [ -z "$lin_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-X-FB: with the pass's tr missing, the split falls back to its substitutions — a refused interpreter run and an allowed echo read as the shipped hook reads them, with no hook error"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-X-FB: with the pass's tr missing, the verdicts equal the shipped hook's" "$lin_why"; FAIL=$((FAIL + 1))
fi

# ---- AC-022-Z* (#8320, Stage 7 iteration): the joined logical lines take the linear pass too ----
#
# The continuation walk (M-CONT-WALK) adds each joined logical line to the first view and splits it
# on the separators with the same three global substitutions the X family replaced. A command whose
# lines end in a backslash-newline joins into one logical line as long as the command, so a large
# separator-dense one could hold the hook past the runtime's command-hook timeout again, after which
# a PreToolUse hook does not block. X1 to X24 never carry a continuation, so they never reached it.
# The joined lines are now split first by the same tr pass, on the line marked `# linear: cont`.
# Z1 to Z6 run the hook under the X watchdog on a benign separator-dense shape whose every unit ends
# in a continuation, at 10, 20 and 40 KB in both locales. Z-CTL is the instrument's sensitivity on
# that shape: the X copy whose bound never lets either pass run is stopped at the budget. Z-EQ lifts
# the marked block and holds it equal to the substitutions byte for byte on the X dense input and its
# edge endings, beside the X near miss. Z-FB repoints the block's tr and reads the shipped verdicts
# on a long continued command that ends in an interpreter and its operand on two physical lines
# (refused) and on its echo twin (allowed).
/usr/bin/sed '/# linear: cont$/s#/usr/bin/tr#/nonexistent/tr#' "$HOOK" > "${LIN_HOOKS}/block-destructive-notool-cont.sh"
lin_z_unit='echo a;echo b|cat&echo c \'$'\n'
for lin_kb in 10 20 40; do lin_fill $(( lin_kb * 1024 )) 'echo gh;' "$lin_z_unit" 'gh api repos/o/r' > "${LIN_ROOT}/continued-${lin_kb}.cmd"; done
lin_n=0
for lin_loc in en_US.UTF-8 C; do
  for lin_kb in 10 20 40; do
    lin_n=$(( lin_n + 1 ))
    lin_timed "${LIN_HOOKS}/block-destructive.sh" "$lin_loc" "${LIN_ROOT}/continued-${lin_kb}.cmd" "$LIN_LIMIT"
    if [ "$LIN_DS" != -1 ] && [ "$LIN_EXIT" = 0 ]; then
      /usr/bin/printf 'PASS: %s\n' "AC-022-Z${lin_n}: the continued separator shape at ${lin_kb} KB in ${lin_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Z${lin_n}: the long continued separator shape in ${lin_loc} clears the hook inside the budget and is allowed — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
        "\"stopped\" is the watchdog ending the run at the budget; exit=${LIN_EXIT} (want 0)"; FAIL=$((FAIL + 1))
    fi
  done
done
lin_timed "${LIN_HOOKS}/block-destructive-nopass.sh" en_US.UTF-8 "${LIN_ROOT}/continued-40.cmd" "$LIN_LIMIT"
if [ "$LIN_DS" = -1 ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-Z-CTL: the copy whose bound never lets a pass run is stopped at the budget on the long continued separator shape in UTF-8 — the instrument sees the cost"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Z-CTL: the copy whose bound never lets a pass run is stopped at the budget — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
    "exit=${LIN_EXIT}; a copy that finishes cannot show Z1-Z6 measure anything (BROKEN PROBE)"; FAIL=$((FAIL + 1))
fi
# lin_zeval <locale> <bound> <block> <input> <out> — the marked block in a fresh /bin/bash, on _j.
lin_zeval() {
  LC_ALL="$1" /bin/bash -c 'set -euo pipefail; SCRIPT_LINEAR_MIN="$1"; _jl=""
    _j="$(/bin/cat "$3"; printf x)"; _j="${_j%x}"
    . "$2"
    printf %s "$_j" > "$4"' _ "$2" "$3" "$4" "$5"
}
lin_why=""
M='# linear: cont' /usr/bin/awk 'BEGIN { m = ENVIRON["M"] }
  length($0) >= length(m) && substr($0, length($0) - length(m) + 1) == m { c++; n = 4 }
  n > 0 { print; n-- }
  END { exit c == 1 ? 0 : 1 }' "$HOOK" > "${LIN_ROOT}/zblock" || lin_why="${lin_why} no single line marked \`# linear: cont\`;"
/usr/bin/head -1 "${LIN_ROOT}/zblock" > "${LIN_ROOT}/zone"
F="'\\012\\012\\012'" T="'\\012\\012\\001'" /usr/bin/awk 'BEGIN { f = ENVIRON["F"]; t = ENVIRON["T"] }
  !d && (i = index($0, f)) { $0 = substr($0, 1, i - 1) t substr($0, i + length(f)); d = 1 }
  { print }
  END { exit d ? 0 : 1 }' "${LIN_ROOT}/zblock" > "${LIN_ROOT}/znear" || lin_why="${lin_why} the near-miss edit did not apply;"
if [ -z "$lin_why" ]; then
  for lin_loc in en_US.UTF-8 C; do
    for lin_k in 0 1 2 3 4 5; do
      lin_zeval "$lin_loc" 1000000000 "${LIN_ROOT}/zblock" "${LIN_ROOT}/in-${lin_k}" "${LIN_ROOT}/zship.out" \
        || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the substitutions did not run;"
      lin_zeval "$lin_loc" 0 "${LIN_ROOT}/zblock" "${LIN_ROOT}/in-${lin_k}" "${LIN_ROOT}/zpass.out" \
        || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the pass did not run;"
      lin_zeval "$lin_loc" 0 "${LIN_ROOT}/zone" "${LIN_ROOT}/in-${lin_k}" "${LIN_ROOT}/zone.out" \
        || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the pass line alone did not run;"
      /usr/bin/cmp -s "${LIN_ROOT}/zship.out" "${LIN_ROOT}/zpass.out" || lin_why="${lin_why} [${lin_loc} in-${lin_k}] pass != substitutions;"
      /usr/bin/cmp -s "${LIN_ROOT}/zship.out" "${LIN_ROOT}/zone.out" || lin_why="${lin_why} [${lin_loc} in-${lin_k}] the pass alone != substitutions;"
    done
    lin_zeval "$lin_loc" 1000000000 "${LIN_ROOT}/zblock" "${LIN_ROOT}/in-0" "${LIN_ROOT}/zship.out" || lin_why="${lin_why} [${lin_loc}] the reference did not run;"
    lin_zeval "$lin_loc" 0 "${LIN_ROOT}/znear" "${LIN_ROOT}/in-0" "${LIN_ROOT}/znear.out" || lin_why="${lin_why} [${lin_loc}] the near miss did not run;"
    [ -s "${LIN_ROOT}/zship.out" ] || lin_why="${lin_why} [${lin_loc}] empty reference output;"
    /usr/bin/cmp -s "${LIN_ROOT}/zship.out" "${LIN_ROOT}/znear.out" \
      && lin_why="${lin_why} [${lin_loc}] the near miss equals the substitutions (the comparison cannot see a difference);"
  done
fi
if [ -z "$lin_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-Z-EQ: the \`# linear: cont\` pass equals the three substitutions byte for byte on the dense input and its edge endings in UTF-8 and C, alone and with them, and a near miss differs"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Z-EQ: the \`# linear: cont\` pass equals the three substitutions byte for byte" "$lin_why"; FAIL=$((FAIL + 1))
fi
lin_why=""
lin_tools="$(/usr/bin/grep -c -F '/nonexistent/tr' "${LIN_HOOKS}/block-destructive-notool-cont.sh")" || true
[ "$lin_tools" = 1 ] || lin_why="${lin_why} the copy repoints ${lin_tools} pass lines, want 1;"
lin_pad="$(lin_fill 400 '' "$lin_z_unit" '')"
for lin_c in "b:2:${lin_pad};bash \\"$'\n'"/tmp/pmo-lin-na.sh" "a:0:${lin_pad};echo \\"$'\n'"done"; do
  lin_tag="${lin_c%%:*}"; lin_rest="${lin_c#*:}"
  lin_want="${lin_rest%%:*}"; lin_cmd_s="${lin_rest#*:}"
  lin_s=0; lin_t=0
  ( /usr/bin/printf '%s' "$(bash_payload "$lin_cmd_s" "$LIN_ROOT")" | /bin/bash "${LIN_HOOKS}/block-destructive.sh" > /dev/null 2>&1 ) || lin_s="$?"
  lin_err="$( { /usr/bin/printf '%s' "$(bash_payload "$lin_cmd_s" "$LIN_ROOT")" | /bin/bash "${LIN_HOOKS}/block-destructive-notool-cont.sh" > /dev/null; } 2>&1 )" || lin_t="$?"
  [ "$lin_s" = "$lin_want" ] || lin_why="${lin_why} [${lin_tag}] shipped exits ${lin_s}, want ${lin_want};"
  [ "$lin_t" = "$lin_s" ] || lin_why="${lin_why} [${lin_tag}] the copy without its tr exits ${lin_t}, the shipped hook ${lin_s};"
  case "$lin_err" in *HOOK-ERROR*) lin_why="${lin_why} [${lin_tag}] the copy without its tr raised a hook error;" ;; esac
done
if [ -z "$lin_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-Z-FB: with the cont pass's tr missing, the joined lines fall back to their substitutions — the two-line interpreter run is refused and its echo twin allowed, as the shipped hook reads them, with no hook error"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Z-FB: with the cont pass's tr missing, the verdicts equal the shipped hook's" "$lin_why"; FAIL=$((FAIL + 1))
fi

# ---- AC-022-Y* (#8314, DT pass 4): the -022 quote scan is linear ----
#
# The script-execution rule carries its quote state across a command's segments with a scan
# (script_qadvance) whose steps the work cap bounds but whose cost per step it does not: on bash
# 3.2 each step re-read the text left to scan — a removal that re-measures it at every position it
# tries, once per searched character, an absent one the costliest — so a long line dense with quote
# characters cost more than linear time and could hold the hook past the runtime's command-hook
# timeout, after which a PreToolUse hook does not block. A segment of at least SCRIPT_LINEAR_MIN
# characters is now scanned by one awk pass with the same steps (script_qadvance_linear, the line
# marked `# linear: qadvance`). Y-EQ lifts the scan and runs it with the bound at 0 (the pass) and at
# 10^9 (the loop, the code before this pass) over segment sequences carried from a starting state,
# work counts near the cap among them, on dense segments — quotes of both kinds, $'...' and its
# escaped quote, backslashes before multibyte and undecodable bytes, `$` and backticks — in
# en_US.UTF-8 and in C: the carried state, taint, work count and bail after every segment must be
# equal, and a near miss that never opens $'...' must differ. Y1 to Y6 run the hook under the
# watchdog on a long comment line dense with quote characters at 10, 20 and 40 KB in both locales,
# each inside the budget and allowed. Y-CTL is the instrument's sensitivity: the raised-bound copy
# of X-CTL is stopped at the budget on a long comment line in UTF-8. Y-FB holds the fallback: a copy
# whose pass has no awk reads the shipped hook's verdicts on a long quoted argument — suppressed
# behind a carrier, refused behind another command — and raises no hook error.
/usr/bin/sed '/# linear: qadvance$/s#/usr/bin/awk#/nonexistent/awk#' "$HOOK" > "${LIN_HOOKS}/block-destructive-noawk.sh"
LIN_Y="${LIN_ROOT}/y"
/bin/mkdir -p "${LIN_Y}/in"
# The cases: a starting state and up to three segments each, from fixed units cycled by a fixed
# generator; segments never carry a newline, as the rule's segments do not.
LC_ALL=C /usr/bin/awk -v d="${LIN_Y}/in" 'BEGIN {
  n = split("", u)
  u[++n] = "\047"; u[++n] = "\""; u[++n] = "\\"; u[++n] = "$"; u[++n] = "`"; u[++n] = "$\047"; u[++n] = "\\\047"
  u[++n] = "\\\""; u[++n] = "\\\\"; u[++n] = " "; u[++n] = "a"; u[++n] = "bc"; u[++n] = "# c"; u[++n] = "it\047s"
  u[++n] = "\"x\""; u[++n] = "\047y\047"; u[++n] = "$(z)"; u[++n] = "\303\251"; u[++n] = "\346\227\245"
  u[++n] = "\\\303\251"; u[++n] = "\\\343\200\200"; u[++n] = "\377"; u[++n] = "\303"; u[++n] = "\\\377"
  split("0 0 0|1 1 0|2 1 0|3 0 0|0 0 990|2 1 998|1 0 999|0 0 1000", st, "|")
  split("300 900 2600", size, " ")
  x = 11; c = 0
  for (a = 1; a <= 8; a++) for (b = 1; b <= 3; b++) {
    cd = d "/case-" sprintf("%02d", ++c); system("/bin/mkdir -p " cd)
    printf "%s\n", st[a] > (cd "/start"); close(cd "/start")
    for (g = 1; g <= b; g++) {
      s = ""; while (length(s) < size[(a + b + g) % 3 + 1]) { x = (x * 1103515245 + 12345) % 2147483648; s = s u[int(x / 65536) % n + 1] }
      printf "%s", s > (cd "/seg-" g); close(cd "/seg-" g)
    }
  }
}'
# lin_y_lift <src> <out> — the scan, its search helper, its linear pass and the pass's program.
# ceil_stub — a hook function lifted out and run alone carries the rule's work-ceiling check
# (#8327) as the first statement of each loop; a lift defines it as a no-op, because the ceiling
# is not the subject of any arm that lifts a function, and an undefined check would print one
# error per loop pass.
ceil_stub() { /usr/bin/printf '%s\n' 'script_ceil_check() { return 0; }'; }
lin_y_lift() {
  /usr/bin/awk '
    /^readonly SCRIPT_QADVANCE_AWK=/ { inp = 1 }
    inp { print; if ($0 == "    }\047") inp = 0; next }
    /^script_qnext\(\) \{/ || /^script_qadvance\(\) \{/ || /^script_qadvance_linear\(\) \{/ { inf = 1; k++ }
    inf { print; if ($0 == "}") inf = 0 }
    END { exit k == 3 ? 0 : 1 }' "$1" > "$2" || return 1
  ceil_stub >> "$2"
}
# lin_y_eval <locale> <bound> <lib> <out> — each case: its segments scanned in turn from its state,
# the state after each written to <out>/<case>.
lin_y_eval() {
  /bin/mkdir -p "$4"
  LC_ALL="$1" /bin/bash -c 'set -euo pipefail; SCRIPT_LINEAR_MIN="$1"; . "$2"
    script_q1="'"'"'"; script_q2="\""; script_bs="\\"; script_qd="\$"; script_qbt="\`"
    for c in "$3"/case-*; do
      read -r script_qstate script_qtaint script_qwork < "$c/start"; script_qbail=0; o=""
      for g in "$c"/seg-*; do
        s="$(/bin/cat "$g"; printf x)"; s="${s%x}"
        script_qadvance "$s"
        o="${o}${script_qstate} ${script_qtaint} ${script_qwork} ${script_qbail};"
      done
      printf "%s\n" "$o" > "$4/${c##*/}"
    done' _ "$2" "$3" "${LIN_Y}/in" "$4"
}
lin_why=""
lin_y_lift "$HOOK" "${LIN_Y}/lib" || lin_why="${lin_why} the scan, its pass or the pass's program is missing from the hook;"
F='if (nd % 2 == 1) st = 3' T='if (0) st = 3' /usr/bin/awk 'BEGIN { f = ENVIRON["F"]; t = ENVIRON["T"] }
  !d && (i = index($0, f)) { $0 = substr($0, 1, i - 1) t substr($0, i + length(f)); d = 1 }
  { print }
  END { exit d ? 0 : 1 }' "${LIN_Y}/lib" > "${LIN_Y}/near" || lin_why="${lin_why} the near-miss edit did not apply;"
lin_y_n="$(/bin/ls -d "${LIN_Y}/in"/case-* | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
[ "$lin_y_n" -ge 24 ] || lin_why="${lin_why} only ${lin_y_n} cases were written;"
if [ -z "$lin_why" ]; then
  for lin_loc in en_US.UTF-8 C; do
    lin_y_eval "$lin_loc" 1000000000 "${LIN_Y}/lib" "${LIN_Y}/${lin_loc}/ref" || lin_why="${lin_why} [${lin_loc}] the loop did not run;"
    lin_y_eval "$lin_loc" 0 "${LIN_Y}/lib" "${LIN_Y}/${lin_loc}/lin" || lin_why="${lin_why} [${lin_loc}] the pass did not run;"
    lin_y_eval "$lin_loc" 0 "${LIN_Y}/near" "${LIN_Y}/${lin_loc}/near" || lin_why="${lin_why} [${lin_loc}] the near miss did not run;"
    lin_y_d=0
    for lin_c in "${LIN_Y}/in"/case-*; do
      lin_k="${lin_c##*/}"
      /usr/bin/cmp -s "${LIN_Y}/${lin_loc}/ref/${lin_k}" "${LIN_Y}/${lin_loc}/lin/${lin_k}" || lin_why="${lin_why} [${lin_loc} ${lin_k}] the pass differs;"
      /usr/bin/cmp -s "${LIN_Y}/${lin_loc}/ref/${lin_k}" "${LIN_Y}/${lin_loc}/near/${lin_k}" || lin_y_d=$(( lin_y_d + 1 ))
    done
    [ "$lin_y_d" -gt 0 ] || lin_why="${lin_why} [${lin_loc}] the near miss reads like the loop (the comparison cannot see a difference);"
  done
fi
if [ -z "$lin_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-Y-EQ: the \`# linear: qadvance\` pass carries the loop's state, taint, work count and bail across ${lin_y_n} segment sequences in UTF-8 and C, and a near miss differs"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Y-EQ: the \`# linear: qadvance\` pass carries the loop's state, taint, work count and bail" "$lin_why"; FAIL=$((FAIL + 1))
fi
for lin_kb in 10 20 40; do
  lin_fill $(( lin_kb * 1024 )) "echo gh # it's \"x\" " "don't \"stop\" " $'\n' > "${LIN_ROOT}/comment-${lin_kb}.cmd"
done
lin_n=0
for lin_loc in en_US.UTF-8 C; do
  for lin_kb in 10 20 40; do
    lin_n=$(( lin_n + 1 ))
    lin_timed "${LIN_HOOKS}/block-destructive.sh" "$lin_loc" "${LIN_ROOT}/comment-${lin_kb}.cmd" "$LIN_LIMIT"
    if [ "$LIN_DS" != -1 ] && [ "$LIN_EXIT" = 0 ]; then
      /usr/bin/printf 'PASS: %s\n' "AC-022-Y${lin_n}: a long comment line dense with quote characters at ${lin_kb} KB in ${lin_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Y${lin_n}: a long comment line dense with quote characters in ${lin_loc} clears the hook inside the budget and is allowed — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
        "\"stopped\" is the watchdog ending the run at the budget; exit=${LIN_EXIT} (want 0)"; FAIL=$((FAIL + 1))
    fi
  done
done
lin_timed "${LIN_HOOKS}/block-destructive-nopass.sh" en_US.UTF-8 "${LIN_ROOT}/comment-20.cmd" "$LIN_LIMIT"
if [ "$LIN_DS" = -1 ] && /usr/bin/grep -q -F -x 'readonly SCRIPT_LINEAR_MIN=1000000000' "${LIN_HOOKS}/block-destructive-nopass.sh"; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-Y-CTL: a copy whose bound never lets the pass run is stopped at the budget on a long comment line in UTF-8 — the instrument sees the cost"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Y-CTL: a copy whose bound never lets the pass run is stopped at the budget — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
    "exit=${LIN_EXIT}; a copy that finishes, or that carries no raised bound, cannot show Y1-Y6 measure anything (BROKEN PROBE)"; FAIL=$((FAIL + 1))
fi
# Y-FB: the pass's awk repointed to a path that does not exist, so the pass fails and the loop scans.
# A long single-quoted argument holding an interpreter run: behind gh, a carrier, the run is a quoted
# fragment and is suppressed (allowed); behind cat it is adjudicated and refused.
lin_why=""
lin_tools="$(/usr/bin/grep -c -F '/nonexistent/awk' "${LIN_HOOKS}/block-destructive-noawk.sh")" || true
[ "$lin_tools" = 1 ] || lin_why="${lin_why} the copy repoints ${lin_tools} pass lines, want 1;"
lin_pad="$(lin_fill 400 '' 'note ' '')"
for lin_c in "g:0:gh issue comment 1 --body '${lin_pad}; bash /tmp/pmo-lin-na.sh'" "c:2:cat --body '${lin_pad}; bash /tmp/pmo-lin-na.sh'"; do
  lin_tag="${lin_c%%:*}"; lin_rest="${lin_c#*:}"
  lin_want="${lin_rest%%:*}"; lin_cmd_s="${lin_rest#*:}"
  lin_s=0; lin_t=0
  ( /usr/bin/printf '%s' "$(bash_payload "$lin_cmd_s" "$LIN_ROOT")" | /bin/bash "${LIN_HOOKS}/block-destructive.sh" > /dev/null 2>&1 ) || lin_s="$?"
  lin_err="$( { /usr/bin/printf '%s' "$(bash_payload "$lin_cmd_s" "$LIN_ROOT")" | /bin/bash "${LIN_HOOKS}/block-destructive-noawk.sh" > /dev/null; } 2>&1 )" || lin_t="$?"
  [ "$lin_s" = "$lin_want" ] || lin_why="${lin_why} [${lin_tag}] shipped exits ${lin_s}, want ${lin_want};"
  [ "$lin_t" = "$lin_s" ] || lin_why="${lin_why} [${lin_tag}] the copy without its awk exits ${lin_t}, the shipped hook ${lin_s};"
  case "$lin_err" in *HOOK-ERROR*) lin_why="${lin_why} [${lin_tag}] the copy without its awk raised a hook error;" ;; esac
done
if [ -z "$lin_why" ]; then
  /usr/bin/printf 'PASS: %s\n' "AC-022-Y-FB: with the pass's awk missing, the scan falls back to its loop — a suppressed quoted fragment and a refused interpreter run read as the shipped hook reads them, with no hook error"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-022-Y-FB: with the pass's awk missing, the verdicts equal the shipped hook's" "$lin_why"; FAIL=$((FAIL + 1))
fi

# ---- QSCAN-LIN-* (#8317): the trust boundary of the carried quote state is one linear pass ----
# The program reads every byte of a command the prefilter admits and that it vouches for, so its
# longest walk is a long command dense with plain nested expansions in double quotes. That command is
# built from row EN50 of the walk-payload corpus (a plain substitution in double quotes, no
# interpreter), repeated one per line to 10, 20 and 40 KB, and run in both locales: each must clear
# the hook inside the budget and be allowed. A latched command's cost is the one a declined
# here-document body already pays — every line through the segment loop — which X1 to X24 time.
lin_why=""
if wc_row_cmd EN50; then
  lin_q_unit="${WC_CMDX}"$'\n'
  for lin_kb in 10 20 40; do lin_fill $(( lin_kb * 1024 )) '' "$lin_q_unit" '' > "${LIN_ROOT}/qscan-${lin_kb}.cmd"; done
else
  lin_why="row EN50 is not a block-destructive row of the corpus;"
fi
lin_n=0
for lin_loc in en_US.UTF-8 C; do
  for lin_kb in 10 20 40; do
    lin_n=$(( lin_n + 1 ))
    if [ -n "$lin_why" ]; then
      /usr/bin/printf 'FAIL: %s\n  %s\n' "QSCAN-LIN-${lin_n}: the long plain-expansion command" "$lin_why"; FAIL=$((FAIL + 1))
      continue
    fi
    lin_timed "${LIN_HOOKS}/block-destructive.sh" "$lin_loc" "${LIN_ROOT}/qscan-${lin_kb}.cmd" "$LIN_LIMIT"
    if [ "$LIN_DS" != -1 ] && [ "$LIN_EXIT" = 0 ]; then
      /usr/bin/printf 'PASS: %s\n' "QSCAN-LIN-${lin_n}: a command dense with plain nested expansions in double quotes (row EN50 repeated) at ${lin_kb} KB in ${lin_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
    else
      /usr/bin/printf 'FAIL: %s\n  %s\n' "QSCAN-LIN-${lin_n}: the long plain-expansion command (row EN50 repeated) in ${lin_loc} clears the hook inside the budget and is allowed — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
        "\"stopped\" is the watchdog ending the run at the budget; exit=${LIN_EXIT} (want 0)"; FAIL=$((FAIL + 1))
    fi
  done
done

# ---- AC-CPH-D* (#8314, DT pass 7): the hook clears the canonicalizer's long shapes inside the budget ----
#
# The shared canonicalizer's three changed sites — the basename step of a prefix word, the option-cluster
# walk and the split-string scan — each read their token once, so this hook, which canonicalizes every Bash
# command, clears one long command word, a long option cluster and a long split string in its short and
# long spelling inside the budget, in en_US.UTF-8 and C, and allows each. The cells are the ones on which
# `main`'s own hook keeps a wide margin under the budget. On the larger cells the cost is `main`'s own code
# — the -022 rule's reading of a long word and of a long option cluster, which grows faster than the
# command. The rule's work ceiling now bounds that cost and refuses past it (CEIL-*); the cells stay cut,
# because the ceiling bounds the growth and does not change it. The false-positive
# control's AC-CP-L arms time the canonicalizer alone on every size of every shape, beside their
# sensitivity copy.
lin_cph_cmd() { # <shape> <bytes> <file> — the head, as many units as fit, then the tail, built by doubling
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
lin_n=0
for lin_cell in word:10:en_US.UTF-8 word:20:en_US.UTF-8 word:40:en_US.UTF-8 word:10:C word:20:C word:40:C \
                cluster:10:en_US.UTF-8 cluster:10:C cluster:20:C split:10:en_US.UTF-8 split:10:C split:20:C \
                lsplit:10:en_US.UTF-8 lsplit:10:C lsplit:20:C; do
  lin_shape="${lin_cell%%:*}"; lin_rest="${lin_cell#*:}"; lin_kb="${lin_rest%%:*}"; lin_loc="${lin_rest#*:}"
  lin_n=$(( lin_n + 1 ))
  lin_cph_cmd "$lin_shape" $(( lin_kb * 1024 )) "${LIN_ROOT}/cph-${lin_shape}-${lin_kb}.cmd"
  lin_timed "${LIN_HOOKS}/block-destructive.sh" "$lin_loc" "${LIN_ROOT}/cph-${lin_shape}-${lin_kb}.cmd" "$LIN_LIMIT"
  if [ "$LIN_DS" != -1 ] && [ "$LIN_EXIT" = 0 ]; then
    /usr/bin/printf 'PASS: %s\n' "AC-CPH-D${lin_n}: the long ${lin_shape} shape at ${lin_kb} KB in ${lin_loc} clears the hook within the budget and is allowed"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  %s\n' "AC-CPH-D${lin_n}: the long ${lin_shape} shape in ${lin_loc} clears the hook inside the budget and is allowed — measured ratio $(lin_ratio "${LIN_DS}" "${LIN_LIMIT}") of the budget, bound 1.00" \
      "\"stopped\" is the watchdog ending the run at the budget; exit=${LIN_EXIT} (want 0)"; FAIL=$((FAIL + 1))
  fi
done
/bin/rm -rf "$LIN_ROOT"

# ---- OPND-* (#8318): an operand is read as the word the shell passes, in every operand slot ----
#
# SUBJECT. The operand sites asked two views of a token, the filename normalizer's reading and the
# raw argv token, and never the word after quote removal. A quote or a backslash INSIDE the path
# rather than around it, or a quote that closes inside the suffix, left the token in no arm's
# operand domain, so nothing was adjudicated: at the operand after the flag walk, behind an
# end-of-options `--`, in an option's argument slot, and where the walk stepped over the token.
# Whitespace inside a quoted path split it before any operand token existed, so its first piece
# claimed nothing either. Every arm here reads its command from the walk-payload corpus by row id
# (seed 15.2, rows OP01 to OP11; group `concat`; DS71 and DS73; O15), so no payload is spelled in
# this suite. They run in a hermetic root of their own whose allowlist names exactly the corpus's
# two listed scripts, which the enclosure block's root does not.
#
# WHAT THE ARMS HOLD. Each fail-open class is refused. Each listed script spelled the same way is
# still allowed. A token the first two views already place in the domain keeps their verdict: the
# rows whose quoted spelling of a listed script is refused before the change stay refused, because
# the word is read only where the first two views claim nothing (no refused row moves to allow).
# The `-c` loop keeps every per-token verdict. The direct-execution arm is not this change's: its
# two quoted-suffix rows are pinned at their allow.
OPND_ROOT="$(/usr/bin/mktemp -d)"
OPND_HOOKS="${OPND_ROOT}/.claude/hooks"
/bin/mkdir -p "${OPND_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${OPND_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${OPND_HOOKS}/lib/" 2>/dev/null || true
/usr/bin/printf '%s\n' "${WC_D}/ok.sh" "${WC_D}/ok.py" > "${OPND_ROOT}/.claude/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${OPND_HOOKS}/.mode"
/bin/cp "$HOOK" "${OPND_HOOKS}/block-destructive.sh"
/bin/chmod +x "${OPND_HOOKS}/block-destructive.sh"
OPND_DRAIN="${OPND_HOOKS}/destructive-warn-log.jsonl"

opnd_drain_rows() {
  if [ -f "$OPND_DRAIN" ]; then
    /usr/bin/wc -l < "$OPND_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

OPND_V=""
OPND_ERR=""
# Run one command through one copy in the hermetic root -> OPND_V (a|B|W|E<rc>) and OPND_ERR.
opnd_run() { # $1 = copy in the hermetic hooks dir  $2 = command
  local rc=0 before after tmp
  tmp="$(/usr/bin/mktemp)"
  before="$(opnd_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$OPND_ROOT")" \
      | /bin/bash "${OPND_HOOKS}/$1" 2>"$tmp" >/dev/null ) || rc="$?"
  after="$(opnd_drain_rows)"
  OPND_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
  case "$rc" in
    2) OPND_V="B" ;;
    0) if [ "$after" -gt "$before" ]; then OPND_V="W"; else OPND_V="a"; fi ;;
    *) OPND_V="E${rc}" ;;
  esac
}

# opnd_arm <label> <row id> <verdict wanted> — the shipped copy on that row's command. A wanted B
# must name BLOCK-DESTRUCTIVE-022.
opnd_arm() {
  if ! wc_row_cmd "$2"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$1" "$2"
    FAIL=$((FAIL + 1))
    return 0
  fi
  opnd_run block-destructive.sh "$WC_CMDX"
  if [ "$OPND_V" = "$3" ] && { [ "$3" != "B" ] || /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$OPND_ERR"; }; then
    /usr/bin/printf 'PASS: %s [row %s] (hook %s)\n' "$1" "$2" "$OPND_V"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s [row %s]\n  wanted hook=%s; observed %s\n  stderr: %s\n' "$1" "$2" "$3" "$OPND_V" "$OPND_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# --- the fail-open classes (fix-evidence): each is refused ---
opnd_arm "OPND-QSFX-01: a quote that closes inside the operand's suffix, the token opening with it" X06 B
opnd_arm "OPND-QSFX-02: as QSFX-01, the quote closing one character later" X07 B
opnd_arm "OPND-QSFX-03: as QSFX-02, in double quotes" X08 B
opnd_arm "OPND-QSFX-04: a quote inside the operand's suffix, the token not opening with a quote" X12 B
opnd_arm "OPND-QSFX-05: as QSFX-04, the quote running to the end of the token" X13 B
opnd_arm "OPND-QSFX-06: a backslash inside the operand's suffix" X15 B
opnd_arm "OPND-QSFX-07: as QSFX-05, in double quotes" X17 B
opnd_arm "OPND-SPLIT-01: a split suffix in the operand slot behind an end-of-options marker" OP01 B
opnd_arm "OPND-SPLIT-02: a split suffix in an option's argument slot" OP03 B
opnd_arm "OPND-SPLIT-03: a split suffix behind the end-of-options marker, the token opening with the quote" OP04 B
opnd_arm "OPND-SPLIT-04 (re-grade, twin DS72): a quote-split word of plus-form flag shape in the operand position" DS71 B
opnd_arm "OPND-SPLIT-05 (re-grade, twin DS74): a quote-split word in an option's argument slot" DS73 B
opnd_arm "OPND-WS-01: a whitespace-bearing quoted operand path" OP05 B
opnd_arm "OPND-WS-02 (re-grade): a whitespace-bearing quoted operand path to an unlisted copy of the listed name" O15 B

# --- the controls: refused before and after ---
opnd_arm "OPND-SPLIT-ctl-source: the split suffix behind the end-of-options marker under source" OP02 B
opnd_arm "OPND-WS-ctl-source: the whitespace-bearing quoted path under source" OP06 B
opnd_arm "OPND-ORDER-01: a listed script spelled with a quote the first two views already refuse stays refused" X04 B
opnd_arm "OPND-ORDER-02: as ORDER-01, an empty quoted prefix" X05 B
opnd_arm "OPND-ORDER-03: a quoted suffix the normalizer already places in the domain" X14 B
opnd_arm "OPND-ORDER-04: an empty quoted pair inside the path" X18 B
opnd_arm "OPND-ORDER-05: a whole word the probe claims, its word past the suffix" CT05 B
opnd_arm "OPND-cmode-01 (Amendment 1): an in-domain token inside a program string keeps its refusal" OP09 B

# --- the near misses: allowed before and after ---
opnd_arm "OPND-ok-01: the listed script with a quote inside its suffix" OP07 a
opnd_arm "OPND-ok-02: as ok-01, behind the end-of-options marker" OP08 a
opnd_arm "OPND-ok-03: the listed script with a quote closing inside its suffix, the token opening with it" X11 a
opnd_arm "OPND-ok-04: the listed script with a quote running to the end of the token" X16 a
opnd_arm "OPND-near-01: a split-suffix path handed to a command that runs nothing" OP11 a
opnd_arm "OPND-cmode-02 (Amendment 1): a separator inside a program string stays allowed" OP10 a

# --- not this change's: the direct-execution arm's quoted-suffix rows keep their allow ---
opnd_arm "OPND-EXEC-pin-01 (pin, not fix-evidence): a quoted suffix at the command word (the exec arm reads two views; not edited here)" X21 a
opnd_arm "OPND-EXEC-pin-02 (pin, not fix-evidence): as EXEC-pin-01, with an argument after it" X23 a

# --- EACH SITE IS LOAD-BEARING: one-line mutants of the change ---------------------------------
# Each mutant removes one line the change adds, and the row it holds moves back to allow. The
# shape arm shows the mutant differs from the hook by exactly that line, so an anchor that stops
# matching is caught rather than read as a pass.
/usr/bin/sed '/# M-OPND-WORD (mutation/d' "$HOOK" > "${OPND_HOOKS}/block-destructive-noword.sh"
/usr/bin/sed '/# M-OPND-JOIN (mutation/d' "$HOOK" > "${OPND_HOOKS}/block-destructive-nojoin.sh"
/usr/bin/sed '/# M-OPND-FIRST (mutation/d' "$HOOK" > "${OPND_HOOKS}/block-destructive-nofirst.sh"
/usr/bin/sed '/# M-OPND-ROUTE (mutation/d' "$HOOK" > "${OPND_HOOKS}/block-destructive-noroute.sh"
# The clause that a fragment is never advanced past, the line after the walk-body marker. Its
# control used to be F1-QTOK-RESIDUAL-space; with the join that arm refuses whichever piece the walk
# reads, so the clause is now shown by the parse-only grant a fragment keeps (row O17).
/usr/bin/sed '/# M-FWALK-BODY/{n;/script_norm_ok" -eq 0 \]; then break; fi$/d;}' "$HOOK" > "${OPND_HOOKS}/block-destructive-noclause.sh"
/bin/chmod +x "${OPND_HOOKS}/block-destructive-noword.sh" "${OPND_HOOKS}/block-destructive-nojoin.sh" \
  "${OPND_HOOKS}/block-destructive-nofirst.sh" "${OPND_HOOKS}/block-destructive-noroute.sh" \
  "${OPND_HOOKS}/block-destructive-noclause.sh"

# The difference between the shipped copy and one mutant, as "<lines removed>/<lines added>".
opnd_shape() { # $1 = mutant file in the hermetic hooks dir
  /usr/bin/diff "${OPND_HOOKS}/block-destructive.sh" "${OPND_HOOKS}/$1" \
    | /usr/bin/awk 'index($0, "<") == 1 { r++ } index($0, ">") == 1 { a++ } END { printf "%d/%d", r, a }'
}
opnd_shape_arm() { # $1 label  $2 mutant file  $3 the shape it must have
  local got
  got="$(opnd_shape "$2")"
  if [ "$got" = "$3" ] && /bin/bash -n "${OPND_HOOKS}/$2" 2>/dev/null; then
    /usr/bin/printf 'PASS: %s (shape %s, parses)\n' "$1" "$got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted shape %s and a copy that parses; observed shape %s\n' "$1" "$3" "$got"
    FAIL=$((FAIL + 1))
  fi
}
opnd_mut_arm() { # $1 label  $2 mutant file  $3 row id  $4 verdict wanted from the mutant
  if ! wc_row_cmd "$3"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$1" "$3"
    FAIL=$((FAIL + 1))
    return 0
  fi
  opnd_run "$2" "$WC_CMDX"
  if [ "$OPND_V" = "$4" ]; then
    /usr/bin/printf 'PASS: %s [row %s] (mutant %s)\n' "$1" "$3" "$OPND_V"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s [row %s]\n  wanted mutant=%s; observed %s\n  stderr: %s\n' "$1" "$3" "$4" "$OPND_V" "$OPND_ERR"
    FAIL=$((FAIL + 1))
  fi
}
opnd_shape_arm "OPND-M1a: the word-view mutant differs from the hook by one line, removed" block-destructive-noword.sh "1/0"
opnd_mut_arm "OPND-M1b: without the word view, the split suffix behind the end-of-options marker is allowed again" block-destructive-noword.sh OP01 a
opnd_mut_arm "OPND-M1c: without the word view, the split suffix in an option's argument slot is allowed again" block-destructive-noword.sh OP03 a
opnd_shape_arm "OPND-M2a: the join mutant differs from the hook by one line, removed" block-destructive-nojoin.sh "1/0"
opnd_mut_arm "OPND-M2b: without the join, the whitespace-bearing quoted operand is allowed again" block-destructive-nojoin.sh OP05 a
opnd_shape_arm "OPND-M3a: the first-views mutant differs from the hook by one line, removed" block-destructive-nofirst.sh "1/0"
opnd_mut_arm "OPND-M3b: with the word asked first, the listed script that the first two views refuse is allowed (the order is what keeps it refused)" block-destructive-nofirst.sh X04 a
opnd_shape_arm "OPND-M4a: the route mutant differs from the hook by one line, removed" block-destructive-noroute.sh "1/0"
opnd_mut_arm "OPND-M4b: without the word read on the conservative route, a quote inside the operand's suffix is allowed again" block-destructive-noroute.sh X12 a
opnd_arm "OPND-M5-ctl: a parse-only grant ahead of a whitespace-bearing quoted path stands at its first piece" O17 a
opnd_shape_arm "OPND-M5a: the no-clause mutant differs from the hook by one line, removed" block-destructive-noclause.sh "1/0"
opnd_mut_arm "OPND-M5b: without the clause that a fragment is never advanced past, the walk steps off that piece, revokes the grant, and refuses" block-destructive-noclause.sh O17 B

# --- THE JOIN READS EVERY FRAGMENT AS THE WORD READER READS ITS JOIN --------------------------
# OPND-JOIN-PARITY lifts the word reader and the join out of the hook. Over every block-destructive
# row of the corpus, with its placeholders expanded and split on whitespace as the hook splits a
# segment (globbing off), each token the reader calls a fragment is joined, and the join's verdict
# and value must equal the reader's on the same pieces joined by one space: a whole word with the
# same exactness and value, or, where the join runs out of pieces, no whole word. The number of
# fragments compared is reported, and must be non-zero. OPND-JOIN-PARITY-ctl is the control: the
# same comparison over a join whose single-quote close is broken must name a disagreement, or the
# agreement proves nothing.
opnd_join_lib="$(/usr/bin/mktemp)"
opnd_join_why=""
/usr/bin/awk '/^script_word_scan\(\) \{/ || /^script_word_join\(\) \{/ { f = 1; k++ } f { print; if ($0 == "}") f = 0 } END { exit k == 2 ? 0 : 1 }' "$HOOK" > "$opnd_join_lib" \
  || opnd_join_why="the reader and the join are not two single functions in the hook;"
ceil_stub >> "$opnd_join_lib"
opnd_join_compare() { # $1 = library file; prints one verdict line
  (
    . "$1"
    n_frag=0
    i=0
    while [ "$i" -lt "$wc_n" ]; do
      wc_expand "${WC_CMD[$i]}"
      set -f
      # shellcheck disable=SC2206
      script_tokens=( $WC_CMDX )
      set +f
      j=0
      while [ "$j" -lt "${#script_tokens[@]}" ]; do
        script_word_scan "${script_tokens[$j]}"
        if [ "$script_ws_complete" -eq 0 ]; then
          n_frag=$((n_frag + 1))
          script_word_join "$j"
          k="$j"; ref=""
          while [ "$k" -lt "${#script_tokens[@]}" ]; do
            if [ -n "$ref" ]; then ref="${ref} "; fi
            ref="${ref}${script_tokens[$k]}"
            if [ "${#ref}" -gt 1024 ]; then break; fi
            script_word_scan "$ref"
            if [ "$script_ws_complete" -eq 1 ]; then break; fi
            k=$((k + 1))
          done
          if [ "${#ref}" -gt 1024 ]; then
            if [ "$script_wj_complete" -ne 0 ]; then /usr/bin/printf 'DISAGREE limit %s' "${WC_ID[$i]}"; exit 0; fi
          elif [ "$script_ws_complete" -eq 1 ]; then
            if [ "$script_wj_complete" -ne 1 ] || [ "$script_wj_exact" != "$script_ws_exact" ] || [ "$script_wj_out" != "$script_ws_out" ] || [ "$script_wj_raw" != "$ref" ]; then
              /usr/bin/printf 'DISAGREE word %s' "${WC_ID[$i]}"; exit 0
            fi
          elif [ "$script_wj_complete" -ne 0 ]; then
            /usr/bin/printf 'DISAGREE fragment %s' "${WC_ID[$i]}"; exit 0
          fi
        fi
        j=$((j + 1))
      done
      i=$((i + 1))
    done
    /usr/bin/printf 'agree fragments=%s' "$n_frag"
  )
}
if [ -n "$opnd_join_why" ]; then
  /usr/bin/printf 'FAIL: OPND-JOIN-PARITY %s\n' "$opnd_join_why"; FAIL=$((FAIL + 1))
else
  opnd_join_v="$(opnd_join_compare "$opnd_join_lib")"
  case "$opnd_join_v" in
    "agree fragments=0"|"") /usr/bin/printf 'FAIL: OPND-JOIN-PARITY compared no fragment — got: %s\n' "$opnd_join_v"; FAIL=$((FAIL + 1)) ;;
    "agree fragments="*) /usr/bin/printf 'PASS: OPND-JOIN-PARITY the join agrees with the word reader on every fragment of the corpus (%s)\n' "$opnd_join_v"; PASS=$((PASS + 1)) ;;
    *) /usr/bin/printf 'FAIL: OPND-JOIN-PARITY the join and the word reader differ — got: %s\n' "$opnd_join_v"; FAIL=$((FAIL + 1)) ;;
  esac
  opnd_join_broken="$(/usr/bin/mktemp)"
  /usr/bin/awk 'BEGIN { inj = 0 } /^script_word_join\(\) \{/ { inj = 1 } inj && index($0, "\"$sq\") st=0 ;;") && !done { sub(/st=0/, "st=1"); done = 1 } { print } inj && $0 == "}" { inj = 0 }' "$opnd_join_lib" > "$opnd_join_broken"
  opnd_join_v="$(opnd_join_compare "$opnd_join_broken")"
  case "$opnd_join_v" in
    "DISAGREE "*) /usr/bin/printf 'PASS: OPND-JOIN-PARITY-ctl a join with its single-quote close broken is caught (%s)\n' "$opnd_join_v"; PASS=$((PASS + 1)) ;;
    *) /usr/bin/printf 'FAIL: OPND-JOIN-PARITY-ctl a broken join was NOT caught — the parity arm cannot discriminate — got: %s\n' "$opnd_join_v"; FAIL=$((FAIL + 1)) ;;
  esac
  /bin/rm -f "$opnd_join_broken"
fi
/bin/rm -f "$opnd_join_lib"

# OPND-JOIN-BOUND: the join stops at the read limit. A fragment followed by more one-letter pieces
# than fit in 1,024 characters reports no whole word, and what it read ends at the limit.
if [ -z "$opnd_join_why" ]; then
  opnd_bound_lib="$(/usr/bin/mktemp)"
  /usr/bin/awk '/^script_word_join\(\) \{/ { f = 1 } f { print; if ($0 == "}") f = 0 }' "$HOOK" > "$opnd_bound_lib"
  ceil_stub >> "$opnd_bound_lib"
  opnd_bound_v="$(
    . "$opnd_bound_lib"
    script_tokens=("'a")
    while [ "${#script_tokens[@]}" -lt 600 ]; do script_tokens+=("b"); done
    script_word_join 0
    /usr/bin/printf '%s %s' "$script_wj_complete" "${#script_wj_raw}"
  )"
  case "$opnd_bound_v" in
    "0 1025"|"0 1026")
      /usr/bin/printf 'PASS: OPND-JOIN-BOUND the join stops past the 1,024-character read limit with no whole word (complete, read length: %s)\n' "$opnd_bound_v"; PASS=$((PASS + 1)) ;;
    *)
      /usr/bin/printf 'FAIL: OPND-JOIN-BOUND the join did not stop at the read limit — got (complete, read length): %s\n' "$opnd_bound_v"; FAIL=$((FAIL + 1)) ;;
  esac
  /bin/rm -f "$opnd_bound_lib"
fi

/bin/rm -rf "$OPND_ROOT"

# ---- ASGN-QVAL-* (#8319): the prefix walk steps over a space-bearing quoted assignment value ----
#
# SUBJECT. The prefix walk splits a segment on whitespace before it reads a token, so an
# assignment whose quoted or escaped value holds a blank reached it as several tokens: the first
# passed the assignment test and a later piece of the value was read as the command word. The
# command behind the value was never adjudicated, and a value whose pieces read as an invocation
# was refused for text the shell never runs. The walk, and env's operand loop with it, now read
# the rest of the assignment word with the hook's own quote scanner and go on at the shell's next
# word — where the segment is vouched to start outside any quote, the tokens before the
# assignment scan back to outside quotes, the word ends at a token boundary, and every character
# of the value is readable. Any other value keeps today's reading. A carrier answer of the head
# resolver the quoted-fragment suppression reads is checked against the same step, which may only
# withdraw it: when the shell's head word behind such a value is not a carrier, the quoted segment
# the value's carrier-word piece seemed to open is adjudicated. Every arm here reads its command
# from the walk-payload corpus by row id (seed 15.3, rows AV01 to AV39, and its addendum, AV40 to
# AV47; the seed-6 rows of the quoted value; O18, O19, O28; EN06), so no payload is spelled in this
# suite. They run in a hermetic root of their own whose allowlist names exactly the corpus's two
# listed scripts.
#
# EACH ARM READS TWO COPIES: the shipped hook and the reverse mutant pqval, which is the walk
# before this change (its two call lines removed). A fix arm differs across them, and that is its
# red-before evidence. A control, a pin or a declared residual reads the same on both, so where
# one condition of the step is what holds it, a third limb runs the copy with that condition
# removed and must read a verdict the arm forbids. The carrier-head check sits outside the walk, so
# pqval keeps it; its own copy, pqvalhead, is its red-before evidence. The precision arms — refused
# or recorded before, allowed after — are each red against the hook before the change; the corpus
# does not take real-interpreter ground truth for those rows.
AQ_ROOT="$(/usr/bin/mktemp -d)"
AQ_HOOKS="${AQ_ROOT}/.claude/hooks"
/bin/mkdir -p "${AQ_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${AQ_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${AQ_HOOKS}/lib/" 2>/dev/null || true
/usr/bin/printf '%s\n' "${WC_D}/ok.sh" "${WC_D}/ok.py" "${WC_D}/li sted/ok.sh" > "${AQ_ROOT}/.claude/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${AQ_HOOKS}/.mode"
/bin/cp "$HOOK" "${AQ_HOOKS}/block-destructive.sh"
# The copies, each the hook with one condition of the step removed by sed on its marked lines:
#   pqval        the two call lines removed: the walk before this change (the reverse mutant)
#   pqvalgate    the gate vouches for every segment
#   pqvalpfx     the prefix scan never runs
#   pqvalgap     the escaped-blank rule does not read the blank run after the backslash
#   pqvalgap2    a later piece of the value that ends on an escaped blank followed by more blanks
#                declines instead of ending the word after the escaped blank
#   pqvalsubst   the guard on a construct the scanner does not model never fires
#   pqvalread    the readable-set test is not asked (its two lines removed)
#   pqvalguards  pqvalsubst and pqvalread together: nothing in the value's text declines
#   pqvalhead    the carrier-head check never withdraws a carrier answer (its one line removed)
#   pqvalheadcap a carrier answer stands when the check's own re-scan spends the work budget; it also
#                removes the open-value withdrawal (M-WRAP-QVAL-HEADOPEN), because AV50's padded value
#                is open and the step declines it at the cap, so that line is a second hold on AV50
#                that would hide the line under test (as FWALK-CLUSTER-M1 removes the join)
#   pqvalhdhead  a here-document's receiver keeps a carrier word read from inside a value
#   pallow      the allowlist never matches (the wrapper block's allowlist-blind mutant)
/usr/bin/sed '/# M-WRAP-QVAL$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqval.sh"
/usr/bin/sed 's/^\( *\)if .*# M-WRAP-QVAL-GATE$/\1script_qval_trust=1   # M-WRAP-QVAL-GATE/' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalgate.sh"
/usr/bin/sed '/# M-WRAP-QVAL-PFX$/s/while \[ "\$_i" -lt "\$_k" \]; do/while false; do/' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalpfx.sh"
/usr/bin/sed '/# M-WRAP-QVAL-GAP$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalgap.sh"
/usr/bin/sed '/# M-WRAP-QVAL-SUBST$/s/return 0 ;;/: ;;/' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalsubst.sh"
/usr/bin/sed '/# M-WRAP-QVAL-READ$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalread.sh"
/usr/bin/sed -e '/# M-WRAP-QVAL-SUBST$/s/return 0 ;;/: ;;/' -e '/# M-WRAP-QVAL-READ$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalguards.sh"
/usr/bin/sed '/# M-WRAP-QVAL-GAP2$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalgap2.sh"
/usr/bin/sed '/# M-WRAP-QVAL-HEAD$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalhead.sh"
/usr/bin/sed -e '/# M-WRAP-QVAL-HEADCAP$/d' -e '/# M-WRAP-QVAL-HEADOPEN$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalheadcap.sh"
/usr/bin/sed '/# M-WRAP-QVAL-HDHEAD$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pqvalhdhead.sh"
/usr/bin/sed 's@^  \[ -f "\$SCRIPT_ALLOWLIST" \] || return 1$@  return 1@' "$HOOK" > "${AQ_HOOKS}/block-destructive-pallow.sh"
for aq_c in pqval pqvalgate pqvalpfx pqvalgap pqvalgap2 pqvalsubst pqvalread pqvalguards pqvalhead pqvalheadcap pqvalhdhead pallow; do
  /bin/chmod +x "${AQ_HOOKS}/block-destructive-${aq_c}.sh"
done
/bin/chmod +x "${AQ_HOOKS}/block-destructive.sh"
AQ_DRAIN="${AQ_HOOKS}/destructive-warn-log.jsonl"

aq_drain_rows() {
  if [ -f "$AQ_DRAIN" ]; then
    /usr/bin/wc -l < "$AQ_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

AQ_V=""
AQ_ERR=""
# Run one command through one copy in the hermetic root -> AQ_V, the verdict as one word: a, B, or
# W:<arm>[+<arm>…], naming the arm field of every would-fire row the call added, in the order
# written, so a verdict that records twice is told from one that records once. AQ_ERR is stderr.
aq_run() { # $1 = copy in the hermetic hooks dir  $2 = command
  local rc=0 before after tmp n
  tmp="$(/usr/bin/mktemp)"
  before="$(aq_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$AQ_ROOT")" \
      | /bin/bash "${AQ_HOOKS}/$1" 2>"$tmp" >/dev/null ) || rc="$?"
  after="$(aq_drain_rows)"
  AQ_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
  n=$(( after - before ))
  case "$rc" in
    2) AQ_V="B" ;;
    0)
      if [ "$n" -gt 0 ]; then
        AQ_V="W:$(/usr/bin/awk -v from="$(( before + 1 ))" 'NR >= from { if (match($0, /"arm":"[^"]*"/)) { a = substr($0, RSTART + 7, RLENGTH - 8) } else { a = "?" } printf "%s%s", (k++ ? "+" : ""), a }' "$AQ_DRAIN")"
      else
        AQ_V="a"
      fi
      ;;
    *) AQ_V="E${rc}" ;;
  esac
}

# aq_arm <label> <row id> <hook verdict> <pqval verdict> [<copy> <its verdict>] — the shipped copy
# and the reverse mutant on that row's command, then the third limb when a copy is named. A wanted
# B must name BLOCK-DESTRUCTIVE-022. A third limb that expects the arm's own verdict fails: it
# could not show the arm failing.
aq_arm() {
  local name="$1" row="$2" want="$3" wantm="$4" pmut="${5:-}" pwant="${6:-}" got gotm gotp="" herr ok=1 why=""
  if ! wc_row_cmd "$row"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$name" "$row"
    FAIL=$((FAIL + 1))
    return 0
  fi
  aq_run block-destructive.sh "$WC_CMDX"
  got="$AQ_V"
  herr="$AQ_ERR"
  if [ "$got" != "$want" ]; then ok=0; why="hook=${got}"; fi
  if [ "$ok" = 1 ] && [ "$want" = "B" ] && ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$herr"; then
    ok=0; why="the refusal does not name BLOCK-DESTRUCTIVE-022"
  fi
  aq_run block-destructive-pqval.sh "$WC_CMDX"
  gotm="$AQ_V"
  if [ "$gotm" != "$wantm" ]; then ok=0; why="${why} pqval=${gotm}"; fi
  if [ -n "$pmut" ]; then
    if [ "$pwant" = "$want" ]; then ok=0; why="${why} the ${pmut} limb expects the arm's own verdict"; fi
    aq_run "block-destructive-${pmut}.sh" "$WC_CMDX"
    gotp="$AQ_V"
    if [ "$gotp" != "$pwant" ]; then ok=0; why="${why} ${pmut}=${gotp}"; fi
  fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s [row %s] (hook %s, pqval %s%s)\n' "$name" "$row" "$got" "$gotm" "${pmut:+, ${pmut} ${gotp}}"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s [row %s]\n  wanted hook=%s pqval=%s%s; observed %s\n  stderr: %s\n' "$name" "$row" "$want" "$wantm" "${pmut:+ ${pmut}=${pwant}}" "${why# }" "$herr"
    FAIL=$((FAIL + 1))
  fi
}

# aq_mut_arm <label> <copy> <row id> <verdict> — one copy alone on that row's command.
aq_mut_arm() {
  if ! wc_row_cmd "$3"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$1" "$3"
    FAIL=$((FAIL + 1))
    return 0
  fi
  aq_run "block-destructive-${2}.sh" "$WC_CMDX"
  if [ "$AQ_V" = "$4" ]; then
    /usr/bin/printf 'PASS: %s [row %s] (%s %s)\n' "$1" "$3" "$2" "$AQ_V"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s [row %s]\n  wanted %s=%s; observed %s\n  stderr: %s\n' "$1" "$3" "$2" "$4" "$AQ_V" "$AQ_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# The difference between the shipped copy and one mutant, as "<lines removed>/<lines added>".
aq_shape() { # $1 = mutant file in the hermetic hooks dir
  /usr/bin/diff "${AQ_HOOKS}/block-destructive.sh" "${AQ_HOOKS}/$1" \
    | /usr/bin/awk 'index($0, "<") == 1 { r++ } index($0, ">") == 1 { a++ } END { printf "%d/%d", r, a }'
}
aq_shape_arm() { # $1 label  $2 mutant file  $3 the shape it must have
  local got
  got="$(aq_shape "$2")"
  if [ "$got" = "$3" ] && /bin/bash -n "${AQ_HOOKS}/$2" 2>/dev/null; then
    /usr/bin/printf 'PASS: %s (shape %s, parses)\n' "$1" "$got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  wanted shape %s and a copy that parses; observed shape %s\n' "$1" "$3" "$got"
    FAIL=$((FAIL + 1))
  fi
}

# --- each copy differs from the hook by exactly its marked lines, and parses ---
aq_shape_arm "ASGN-QVAL-M0: the reverse mutant removes the two call lines" block-destructive-pqval.sh "2/0"
aq_shape_arm "ASGN-QVAL-M1: the gate mutant rewrites the gate line" block-destructive-pqvalgate.sh "1/1"
aq_shape_arm "ASGN-QVAL-M2: the prefix-scan mutant rewrites its loop line" block-destructive-pqvalpfx.sh "1/1"
aq_shape_arm "ASGN-QVAL-M3: the escaped-blank mutant removes the blank-run line" block-destructive-pqvalgap.sh "1/0"
aq_shape_arm "ASGN-QVAL-M4: the construct-guard mutant rewrites its pattern line" block-destructive-pqvalsubst.sh "1/1"
aq_shape_arm "ASGN-QVAL-M5: the readable-set mutant removes its two lines" block-destructive-pqvalread.sh "2/0"
aq_shape_arm "ASGN-QVAL-M6: the both-guards mutant is M4 and M5 together" block-destructive-pqvalguards.sh "3/1"
aq_shape_arm "ASGN-QVAL-M7: the allowlist-blind mutant rewrites one line" block-destructive-pallow.sh "1/1"
aq_shape_arm "ASGN-QVAL-M8: the carrier-head mutant removes the withdrawal line" block-destructive-pqvalhead.sh "1/0"
aq_shape_arm "ASGN-QVAL-M9: the second escaped-blank mutant removes its clause line" block-destructive-pqvalgap2.sh "1/0"
aq_shape_arm "ASGN-QVAL-M10: the carrier-head budget mutant removes its withdrawal line and the open-value withdrawal" block-destructive-pqvalheadcap.sh "2/0"
aq_shape_arm "ASGN-QVAL-M11: the here-document receiver mutant removes its withdrawal line" block-destructive-pqvalhdhead.sh "1/0"

# --- the closures (fix-evidence): refused, or recorded at the arm's own phase; the walk before allows ---
aq_arm "ASGN-QVAL-sq: a single-quoted value holding a blank, before an interpreter and an unlisted script" WR126 B a
aq_arm "ASGN-QVAL-sq-seed1: as sq, the seed-1 row of the same shape" O18 B a
aq_arm "ASGN-QVAL-dq: as sq, in double quotes" WR127 B a
aq_arm "ASGN-QVAL-sh: as sq, before a different interpreter" AV01 B a
aq_arm "ASGN-QVAL-esc: one escaped blank outside quotes" WR131 B a
aq_arm "ASGN-QVAL-esc-two: a later piece ending on an escaped blank followed by a second blank ends the word after the escaped blank" AV42 B a pqvalgap2 a
aq_arm "ASGN-QVAL-wide: a value of four pieces" AV07 B a
aq_arm "ASGN-QVAL-two: two quoted values, each holding a blank" AV08 B a
aq_arm "ASGN-QVAL-mixed: a quoted value, then a plain one" WR129 B a
aq_arm "ASGN-QVAL-mixed-seed1: as mixed, the seed-1 row" O28 B a
aq_arm "ASGN-QVAL-later: the value opening a later segment" WR130 B a
aq_arm "ASGN-QVAL-later-carrier: the value opening the segment after a carrier's" AV09 B a
aq_arm "ASGN-QVAL-append: the append form" AV04 B a
aq_arm "ASGN-QVAL-source: before source" AV02 B a
aq_arm "ASGN-QVAL-dot: before the dot" AV03 B a
aq_arm "ASGN-QVAL-sudo: behind sudo" AV05 B a
aq_arm "ASGN-QVAL-env: as an env operand" WR128 B a
aq_arm "ASGN-QVAL-env-seed1: as env, the seed-1 row" O19 B a
aq_arm "ASGN-QVAL-env-opt: as an env operand behind an option" AV06 B a
aq_arm "ASGN-QVAL-bail1: in the first segment of a command whose bail latches" AV10 B a
# AV10's here-document is received by cat, which #8326 admits, so its bail no longer latches and the arm
# above no longer reads its premise. The same shape on a receiver on no list keeps it exercised.
aq_bail1="FOO='a b' bash ${WC_D}/na.sh"$'\n'"wc -l <<'EOF'"$'\n'"x"$'\n'"EOF"
aq_run block-destructive.sh "$aq_bail1"; aq_bail1_v="$AQ_V"
aq_run block-destructive-pqval.sh "$aq_bail1"; aq_bail1_m="$AQ_V"
if [ "$aq_bail1_v" = B ] && [ "$aq_bail1_m" = a ]; then
  /usr/bin/printf 'PASS: ASGN-QVAL-bail1-nonmember: in the first segment of a command whose bail latches on a receiver on no list (hook %s, pqval %s)\n' "$aq_bail1_v" "$aq_bail1_m"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: ASGN-QVAL-bail1-nonmember: in the first segment of a command whose bail latches on a receiver on no list\n  wanted hook=B pqval=a; observed hook=%s pqval=%s\n' "$aq_bail1_v" "$aq_bail1_m"
  FAIL=$((FAIL + 1))
fi
aq_arm "ASGN-QVAL-exec: before a direct execution, recorded at that arm's phase" AV11 W:exec a
aq_arm "ASGN-QVAL-nonshell: before a non-shell interpreter, recorded at that arm's phase" AV12 W:interp-nonshell a
aq_arm "ASGN-QVAL-encl: at an unquoted enclosure position, recorded at that view's phase" AV13 W:shell-enclosure a

# --- the controls: the listed script, and values with no blank ---
aq_arm "ASGN-QVAL-ctl-ok: the listed script behind a value holding a blank" AV14 a a pallow B
aq_arm "ASGN-QVAL-ctl-nows (the AC1 control): a quoted value with no blank, an unlisted script" WR125 B B
aq_arm "ASGN-QVAL-ctl-nows-plain: as ctl-nows, unquoted" AV15 B B
aq_arm "ASGN-QVAL-ctl-nows-source: as ctl-nows, before source" AV16 B B
aq_arm "ASGN-QVAL-ctl-nows-exec: an unquoted value before a direct execution" AV17 W:exec W:exec
aq_arm "ASGN-QVAL-ctl-nows-nonshell: an unquoted value before a non-shell interpreter" AV18 W:interp-nonshell W:interp-nonshell

# --- the declared precision rows: refused or recorded before, allowed after ---
aq_arm "ASGN-QVAL-near-sq (AC2, declared precision): a value whose pieces read as an interpreter invocation, before a command that runs nothing" WR134 a B
aq_arm "ASGN-QVAL-near-dq (AC2, declared precision): as near-sq, in double quotes" WR135 a B
aq_arm "ASGN-QVAL-near-sh (declared precision): a value whose pieces read as an interpreter and a script path" AV19 a B
aq_arm "ASGN-QVAL-near-source (declared precision): a value whose pieces read as source and a script path" AV20 a B
aq_arm "ASGN-QVAL-near-exec (declared precision): a value whose first piece read as the command word is a slash-bearing path" AV21 a W:exec
aq_arm "ASGN-QVAL-near-run (declared precision): a value running past a separator, its first segment holding an invocation" AV22 a B
aq_arm "ASGN-QVAL-prec-interp (declared precision): a value ending on an interpreter word, before a slash-bearing script, takes its plain form's verdict" AV23 W:exec B
aq_arm "ASGN-QVAL-prec-path (declared precision): as prec-interp, before a PATH-resolved word, which the rule does not adjudicate in plain form" AV24 a B

# --- the shapes the step declines: their verdicts before and after ---
aq_arm "ASGN-QVAL-keep-sep-sq: a segment that starts inside a single-quoted value" WR100 B B pqvalgate a
aq_arm "ASGN-QVAL-keep-sep-dq: a segment that starts inside a double-quoted value" WR101 B B pqvalgate a
aq_arm "ASGN-QVAL-keep-sep-exec: as keep-sep-dq, before a direct execution" WR115 W:exec W:exec pqvalgate a
aq_arm "ASGN-QVAL-keep-pfx: a wrapper option's argument leaves a quote open ahead of the assignment" AV27 B B pqvalpfx a
aq_arm "ASGN-QVAL-keep-gap: an escaped blank followed by a second blank ends the word" AV28 B B pqvalgap W:exec
aq_arm "ASGN-QVAL-keep-note: a value whose pieces read as an invocation, before a real one" AV26 B B
aq_arm "ASGN-QVAL-keep-subst: a value holding a command substitution keeps today's reading" WR133 a a pqvalguards B
aq_mut_arm "ASGN-QVAL-keep-subst-guard: with the readable-set test off, the construct guard alone still declines it" pqvalread WR133 a
aq_arm "ASGN-QVAL-keep-subst-row: a value holding a substitution that runs a slash-bearing script keeps both records" EN06 W:exec+shell-enclosure W:exec+shell-enclosure pqvalguards W:shell-enclosure
aq_mut_arm "ASGN-QVAL-keep-subst-row-guard: with the readable-set test off, the construct guard alone keeps both records" pqvalread EN06 W:exec+shell-enclosure
aq_arm "ASGN-QVAL-keep-subst-unquoted (pin): an unquoted substitution value, which never enters the step" AV29 W:exec+shell-enclosure W:exec+shell-enclosure

# --- the work budget, the carrier head, and the declared over-block ---
aq_arm "ASGN-QVAL-cap: the step's scan crosses the shared work cap, which latches the bail, so a later carrier fragment is no longer suppressed" AV32 B a
aq_arm "ASGN-QVAL-limit-carrier (declared limit): a carrier behind a value holding a blank keeps its quoted-fragment false positive" AV30 B B
aq_arm "ASGN-QVAL-limit-ctl: the same carrier behind a value with no blank is suppressed" AV31 a a
aq_arm "ASGN-QVAL-head (PR-2): a carrier word inside a value holding a blank is not the command the shell runs, so the quoted segment it seemed to open is adjudicated" AV40 B B pqvalhead a
aq_arm "ASGN-QVAL-head-ctl: the same command with no carrier word in the value" AV41 B B
aq_arm "ASGN-QVAL-headcap: a value dense enough that the carrier-head check spends the shared work budget does not leave the carrier answer standing" AV50 B B pqvalheadcap a
aq_arm "ASGN-QVAL-hdhead: a carrier word inside a value holding a blank is not the receiver of the here-document, so its body is adjudicated" AV48 B B pqvalhdhead a
aq_arm "ASGN-QVAL-hdhead-ctl: the same here-document with no carrier word in the value" AV49 B B
aq_arm "ASGN-QVAL-over-wrap (declared over-block): an assignment behind a wrapper that takes none" AV25 B a

# --- the declared residuals: allowed before and after ---
# AV33's here-document is received by cat, which #8326 admits, so its bail no longer latches and the
# later line is adjudicated: refused through the step, allowed by the walk before it. The residual it
# pinned is re-pinned just below on a receiver on no list.
aq_arm "ASGN-QVAL-resid-bail: a later line after a cat-received here-document, adjudicated now the body is admitted" AV33 B a
# The same residual on a receiver on no list, so the pin does not depend on which receivers the
# here-document pre-pass admits (#8326 admits AV33's cat). Allowed on the hook; the copy whose gate
# vouches for every segment refuses it.
aq_hdresid="wc -l <<'EOF'"$'\n'"x"$'\n'"EOF"$'\n'"FOO='a b' bash ${WC_D}/na.sh"
aq_run block-destructive.sh "$aq_hdresid"; aq_hdresid_v="$AQ_V"
aq_run block-destructive-pqvalgate.sh "$aq_hdresid"; aq_hdresid_g="$AQ_V"
if [ "$aq_hdresid_v" = a ] && [ "$aq_hdresid_g" = B ]; then
  /usr/bin/printf 'PASS: ASGN-QVAL-resid-bail-nonmember: a later line of a command whose bail latched on a receiver on no list (hook %s, pqvalgate %s)\n' "$aq_hdresid_v" "$aq_hdresid_g"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: ASGN-QVAL-resid-bail-nonmember: a later line of a command whose bail latched on a receiver on no list\n  wanted hook=a pqvalgate=B; observed hook=%s pqvalgate=%s\n' "$aq_hdresid_v" "$aq_hdresid_g"
  FAIL=$((FAIL + 1))
fi
aq_arm "ASGN-QVAL-resid-braced: a value holding a braced expansion" AV34 a a pqvalguards B
aq_arm "ASGN-QVAL-resid-dqencl: a value at an enclosure position opened inside double quotes" AV35 a a pqvalgate W:shell-enclosure
aq_arm "ASGN-QVAL-resid-redir: a redirection operator glued to the value's end" AV36 a a
aq_arm "ASGN-QVAL-resid-sep: a separator inside the value" AV37 a a
aq_arm "ASGN-QVAL-resid-ansi: a value in ANSI-C quoting" AV38 a a pqvalread B
aq_arm "ASGN-QVAL-resid-param: a value holding a parameter expansion" AV39 a a pqvalread B
aq_arm "ASGN-QVAL-resid-twoq: a value whose single and double quotes both delimit" AV43 a a pqvalread B
aq_arm "ASGN-QVAL-resid-envpiece (FM-3): an env operand whose = sits in a later piece" AV44 a a
aq_arm "ASGN-QVAL-resid-hash: a # inside a quoted value" AV45 a a pqvalread B
aq_arm "ASGN-QVAL-resid-pfxsubst: a construct the scanner does not model in a prefix token ahead of the quoted assignment" AV46 a a pqvalsubst B
aq_arm "ASGN-QVAL-resid-cap: a later line of a command whose earlier quote-dense part spent the shared work budget" AV47 a a

# ---- SUBST-BOUNDARY-ASGN-* / ASGN-SUBST-* (#8548): an allowlisted script run inside an assignment's command substitution ----
#
# SUBJECT. The characters of a command substitution are part of the word they sit in, but the walk
# splits a segment on whitespace first, so an assignment whose value opens a substitution reached it
# as the assignment's first piece and the substitution's later words, and the walk took the last of
# them — the path with the closer attached — for the command word. A listed script written in quotes
# there was recorded by the exec arm as unresolvable, and a command word written after the
# assignment was never read. The walk, and env's operand loop with it, now read such a word through
# the substitution's closer and go on at the shell's next word, only when the word that closes the
# substitution is one literal word the allowlist admits; every other value keeps today's reading.
# Every corpus arm here reads its command from the walk-payload corpus by row id (rows AS01 to AS23,
# and EN06, AV29, WR132, WR133, AV46, EN52, EN54); the few commands spelled below are the
# discriminating fixtures for a decline no corpus row isolates.
#
# A VERDICT HERE NAMES THE CAUSE as well as the arm of each would-fire row the call added
# (W:<arm>:<cause>[+…]), because the corpus differential cannot see a record that moves from the
# substitution's path to the real command word, or a two-record reading that becomes one.
#
# THE COPIES, each the hook with one decline of the step removed by sed on its marked line:
#   pasubst          the two call lines removed: the walk before this change (the reverse mutant)
#   pasubstmoved     the test that no step moved the walk since the assignment token
#   pasubsttrust     the value step's trust gate
#   pasubstshape     the value's form: an optional double quote, a plain run, one opener, a plain word
#   pasubstslash     the slash test on the word against the opener
#   pasubstpfx       the prefix scan (its loop rewritten to `while false`)
#   pasubstwork      the work-budget test
#   pasubstcut       the test that the closer sits inside the next token
#   pasubstend       the test that nothing but the value's own closing quote follows the closer
#   pasubstnorm      the test that the closing text normalizes to exactly one literal word
#   pasubstplain     the test that the word is non-empty and plain
#   pasubstopt       the test that the word is not option-shaped
#   pasubstallow     the allowlist test
#   pasubstname      the test that an operand's text before its first `=` is plain (env's operand loop)
#   forced           the exec arm's phase at enforce; forced-pasubst is forced and pasubst together
#   enclforced       the enclosure family's phase at enforce
#   gd, gd-pasubst,  the value step's two text guards off (the ASGN-QVAL block's pqvalguards), alone,
#   gd-moved         with the step removed, and with the moved-walk test removed: the one copy on which
#                    the value step can cross a substitution-bearing value, so the moved-walk test can
#                    be shown live there; on the shipped hook the value step never moves before it
# A third limb, or a relational arm, must read a verdict the arm forbids: a limb that expects the
# arm's own verdict fails, since it could not show the condition holding the arm.
#
# TWO HERMETIC ROOTS. AS_ROOT allowlists exactly the fixture's listed paths, as the ASGN-QVAL root
# does. AS_GROOT allowlists the same two scripts through leading-glob entries, the shape some rows
# of the tracked allowlist have; the decline arms run there again, beside the rows of the classes
# such an entry could otherwise admit.
AS_ROOT="$(/usr/bin/mktemp -d)"
AS_GROOT="$(/usr/bin/mktemp -d)"
as_build() { # $1 = root  $2… = its allowlist entries -> the hook and its copies in the root's hooks dir
  local root="$1" h="$1/.claude/hooks" c n m
  local ph='s/^readonly DESTRUCTIVE_022_EXEC_PHASE=.*/readonly DESTRUCTIVE_022_EXEC_PHASE="enforce"   # shadow | warn | enforce/'
  local pe='s/^readonly DESTRUCTIVE_022_ENCL_PHASE=.*/readonly DESTRUCTIVE_022_ENCL_PHASE="enforce"   # shadow | warn | enforce/'
  shift
  /bin/mkdir -p "${h}/lib"
  /bin/cp "${HOOK%/*}/lib/"*.sh  "${h}/lib/" 2>/dev/null || true
  /bin/cp "${HOOK%/*}/lib/"*.awk "${h}/lib/" 2>/dev/null || true
  /usr/bin/printf '%s\n' "$@" > "${root}/.claude/script-execution-allowlist.txt"
  /usr/bin/printf 'enforce' > "${h}/.mode"
  /bin/cp "$HOOK" "${h}/block-destructive.sh"
  /usr/bin/sed '/# M-ASGN-SUBST$/d' "$HOOK" > "${h}/block-destructive-pasubst.sh"
  for c in moved:MOVED trust:TRUST shape:SHAPE slash:SLASH work:WORK cut:CUT end:END norm:NORM plain:PLAIN opt:OPT allow:ALLOW name:NAME; do
    n="${c%%:*}"; m="${c#*:}"
    /usr/bin/sed "/# M-ASGN-SUBST-${m}\$/d" "$HOOK" > "${h}/block-destructive-pasubst${n}.sh"
  done
  /usr/bin/sed '/# M-ASGN-SUBST-PFX$/s/while \[ "\$_i" -lt "\$_k" \]; do/while false; do/' "$HOOK" > "${h}/block-destructive-pasubstpfx.sh"
  /usr/bin/sed "$ph" "$HOOK" > "${h}/block-destructive-forced.sh"
  /usr/bin/sed -e "$ph" -e '/# M-ASGN-SUBST$/d' "$HOOK" > "${h}/block-destructive-forced-pasubst.sh"
  /usr/bin/sed "$pe" "$HOOK" > "${h}/block-destructive-enclforced.sh"
  /usr/bin/sed -e '/# M-WRAP-QVAL-SUBST$/s/return 0 ;;/: ;;/' -e '/# M-WRAP-QVAL-READ$/d' "$HOOK" > "${h}/block-destructive-gd.sh"
  /usr/bin/sed -e '/# M-WRAP-QVAL-SUBST$/s/return 0 ;;/: ;;/' -e '/# M-WRAP-QVAL-READ$/d' -e '/# M-ASGN-SUBST$/d' "$HOOK" > "${h}/block-destructive-gd-pasubst.sh"
  /usr/bin/sed -e '/# M-WRAP-QVAL-SUBST$/s/return 0 ;;/: ;;/' -e '/# M-WRAP-QVAL-READ$/d' -e '/# M-ASGN-SUBST-MOVED$/d' "$HOOK" > "${h}/block-destructive-gd-moved.sh"
  /bin/chmod +x "${h}/"block-destructive*.sh
}
as_build "$AS_ROOT" "${WC_D}/ok.sh" "${WC_D}/ok.py" "${WC_D}/li sted/ok.sh" "${WC_D}/bin/bash"
as_build "$AS_GROOT" '*/ok.sh' '*/ok.py'

AS_R=""; AS_H=""; AS_DRAIN=""
as_root() { # $1 = root: the root the arms below run in
  AS_R="$1"; AS_H="$1/.claude/hooks"; AS_DRAIN="${AS_H}/destructive-warn-log.jsonl"
}
as_drain_rows() {
  if [ -f "$AS_DRAIN" ]; then
    /usr/bin/wc -l < "$AS_DRAIN" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf '0'
  fi
}

AS_V=""
AS_ERR=""
# Run one command through one copy in the current root -> AS_V: a, B, E<exit>, or
# W:<arm>:<cause>[+<arm>:<cause>…] naming every would-fire row the call added, in the order written.
as_run() { # $1 = copy (hook, or the suffix of block-destructive-<suffix>.sh)  $2 = command
  local rc=0 before after tmp n f="block-destructive.sh"
  [ "$1" = hook ] || f="block-destructive-$1.sh"
  tmp="$(/usr/bin/mktemp)"
  before="$(as_drain_rows)"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$AS_R")" \
      | /bin/bash "${AS_H}/${f}" 2>"$tmp" >/dev/null ) || rc="$?"
  after="$(as_drain_rows)"
  AS_ERR="$(/bin/cat "$tmp")"
  /bin/rm -f "$tmp"
  n=$(( after - before ))
  case "$rc" in
    2) AS_V="B" ;;
    0)
      if [ "$n" -gt 0 ]; then
        AS_V="W:$(/usr/bin/awk -v from="$(( before + 1 ))" 'NR >= from { a = "?"; c = "?"
          if (match($0, /"arm":"[^"]*"/)) { a = substr($0, RSTART + 7, RLENGTH - 8) }
          if (match($0, /"cause":"[^"]*"/)) { c = substr($0, RSTART + 9, RLENGTH - 10) }
          printf "%s%s:%s", (k++ ? "+" : ""), a, c }' "$AS_DRAIN")"
      else
        AS_V="a"
      fi
      ;;
    *) AS_V="E${rc}" ;;
  esac
}

as_pass() { /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
# A failure's observations ride on its FAIL line, newlines folded, because the runner forwards only that line.
as_fail() { local o="$2"; o="${o//$'\n'/ | }"; /usr/bin/printf 'FAIL: %s — observed:%s\n' "$1" "$o"; FAIL=$((FAIL + 1)); }

# as_arm <label> <row id> <hook verdict> <pasubst verdict> [<copy> <its verdict>] — the shipped copy
# and the reverse mutant on that row's command, then the third limb when a copy is named. A wanted
# B must name BLOCK-DESTRUCTIVE-022.
as_arm() {
  local name="$1" row="$2" want="$3" wantm="$4" pmut="${5:-}" pwant="${6:-}" got gotm gotp="" herr why=""
  if ! wc_row_cmd "$row"; then as_fail "$name" " row ${row} is not a block-destructive row of the corpus"; return 0; fi
  as_run hook "$WC_CMDX"; got="$AS_V"; herr="$AS_ERR"
  [ "$got" = "$want" ] || why="${why} hook=${got}(wanted ${want})"
  if [ "$want" = B ] && [ "$got" = B ] && ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$herr"; then why="${why} the-refusal-does-not-name-BLOCK-DESTRUCTIVE-022"; fi
  as_run pasubst "$WC_CMDX"; gotm="$AS_V"
  [ "$gotm" = "$wantm" ] || why="${why} pasubst=${gotm}(wanted ${wantm})"
  if [ -n "$pmut" ]; then
    [ "$pwant" != "$want" ] || why="${why} the-${pmut}-limb-expects-the-arm's-own-verdict"
    as_run "$pmut" "$WC_CMDX"; gotp="$AS_V"
    [ "$gotp" = "$pwant" ] || why="${why} ${pmut}=${gotp}(wanted ${pwant})"
  fi
  if [ -z "$why" ]; then
    as_pass "${name} [row ${row}] (hook ${got}, pasubst ${gotm}${pmut:+, ${pmut} ${gotp}})"
  else
    as_fail "${name} [row ${row}]" "${why} stderr: ${herr}"
  fi
}

# as_rows_arm <label> "<copy>:<verdict> …" <row id>… — each named copy on each row's command.
as_rows_arm() {
  local name="$1" spec="$2" r s cp want why=""
  shift 2
  for r in "$@"; do
    if ! wc_row_cmd "$r"; then why="${why} ${r}:absent"; continue; fi
    for s in $spec; do
      cp="${s%%:*}"; want="${s#*:}"
      as_run "$cp" "$WC_CMDX"
      [ "$AS_V" = "$want" ] || why="${why} ${r}:${cp}=${AS_V}(wanted ${want})"
      if [ "$want" = B ] && [ "$AS_V" = B ] && ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$AS_ERR"; then why="${why} ${r}:${cp}-refusal-not-022"; fi
    done
  done
  if [ -z "$why" ]; then as_pass "${name} [rows $*] (${spec})"; else as_fail "$name" "$why"; fi
}

# as_rel_arm <label> <command> <base copy> <stepless copy> <mutant copy> — a decline shown on a
# command no corpus row isolates: on the base copy the step declines (the base reads as the copy
# without the step), the copy with that decline removed reads otherwise, and no copy errors.
as_rel_arm() {
  local name="$1" cmd="$2" base="$3" off="$4" mut="$5" vb vo vm why=""
  as_run "$base" "$cmd"; vb="$AS_V"
  as_run "$off" "$cmd"; vo="$AS_V"
  as_run "$mut" "$cmd"; vm="$AS_V"
  case "${vb}|${vo}|${vm}" in E[0-9]*|*'|E'[0-9]*) why="${why} a-copy-errored" ;; esac
  [ "$vb" = "$vo" ] || why="${why} the-step-moved-on-${base}"
  [ "$vm" != "$vb" ] || why="${why} ${mut}-reads-the-same"
  if [ -z "$why" ]; then
    as_pass "${name} (${base} ${vb}, ${off} ${vo}, ${mut} ${vm})"
  else
    as_fail "$name" "${why} (${base} ${vb}, ${off} ${vo}, ${mut} ${vm})"
  fi
}

# The difference between two copies, as "<lines removed>/<lines added>".
as_shape() { # $1 = copy file  $2 = base file
  /usr/bin/diff "${AS_H}/$2" "${AS_H}/$1" \
    | /usr/bin/awk 'index($0, "<") == 1 { r++ } index($0, ">") == 1 { a++ } END { printf "%d/%d", r, a }'
}
as_shape_arm() { # $1 label  $2 copy suffix  $3 the shape it must have  [$4 base suffix; default the hook]
  local got base="block-destructive.sh"
  [ -z "${4:-}" ] || base="block-destructive-$4.sh"
  got="$(as_shape "block-destructive-$2.sh" "$base")"
  if [ "$got" = "$3" ] && /bin/bash -n "${AS_H}/block-destructive-$2.sh" 2>/dev/null; then
    as_pass "$1 (shape ${got}, parses)"
  else
    as_fail "$1" " wanted shape $3 and a copy that parses; observed shape ${got}"
  fi
}

# The discriminating fixtures, spelled here because no corpus row isolates their decline. Each but
# the moved-walk one ends on an unlisted script written after the assignment, so a step that crosses
# reads it as the command word and adds a record the declined reading never writes.
as_q="'"
as_bt='`'
as_cut="OUT=\$(bash ${WC_D}/ok.sh ${WC_D}/na.sh)"
as_norm="OUT=\$(bash ${as_q}${WC_D}/ok.sh${as_q}x) ${WC_D}/na.sh"
as_moved="X=\"\$(true a)\" ${as_q}${WC_D}/ok.sh${as_q})\" ${WC_D}/na.sh"
as_optd="OUT=\$(bash ${as_q}-x${WC_D}/ok.sh${as_q}) ${WC_D}/na.sh"
as_optp="OUT=\$(bash ${as_q}+x${WC_D}/ok.sh${as_q}) ${WC_D}/na.sh"
as_int="OUT=\$(bash ${as_q}${WC_D}/ok.sh${as_q}) ${as_bt}${WC_D}/na.sh${as_bt}"
# D-2: a listed closing word whose basename is an interpreter's name (this root lists one such path).
as_verb="OUT=\$(bash ${as_q}${WC_D}/bin/bash${as_q}) ${WC_D}/na.sh"

as_root "$AS_ROOT"

# --- each copy differs from the hook by exactly its marked lines, and parses ---
as_shape_arm "ASGN-SUBST-M0: the reverse mutant removes the two call lines" pasubst "2/0"
as_shape_arm "ASGN-SUBST-M1: the trust mutant removes the gate line" pasubsttrust "1/0"
as_shape_arm "ASGN-SUBST-M2: the prefix-scan mutant rewrites its loop line" pasubstpfx "1/1"
as_shape_arm "ASGN-SUBST-M3: the slash mutant removes its line" pasubstslash "1/0"
as_shape_arm "ASGN-SUBST-M4: the work-budget mutant removes its line" pasubstwork "1/0"
as_shape_arm "ASGN-SUBST-M5: the closing-quote mutant removes its line" pasubstend "1/0"
as_shape_arm "ASGN-SUBST-M6: the allowlist mutant removes its line" pasubstallow "1/0"
as_shape_arm "ASGN-SUBST-M7: the forced copy rewrites the exec arm's phase line" forced "1/1"
as_shape_arm "ASGN-SUBST-M8: the enclosure-forced copy rewrites the enclosure family's phase line" enclforced "1/1"
as_shape_arm "ASGN-SUBST-M9: the value-form mutant removes its line" pasubstshape "1/0"
as_shape_arm "ASGN-SUBST-M10: the closer-inside-the-token mutant removes its line" pasubstcut "1/0"
as_shape_arm "ASGN-SUBST-M11: the one-literal-word mutant removes its line" pasubstnorm "1/0"
as_shape_arm "ASGN-SUBST-M12: the plain-word mutant removes its line" pasubstplain "1/0"
as_shape_arm "ASGN-SUBST-M13: the option-shape mutant removes its line" pasubstopt "1/0"
as_shape_arm "ASGN-SUBST-M14: the moved-walk mutant removes its line from the guards-off copy" gd-moved "1/0" gd
as_shape_arm "ASGN-SUBST-M15: the forced reverse copy is the phase line and the two call lines" forced-pasubst "3/1"
as_shape_arm "ASGN-SUBST-M16: the guards-off copy without the step removes the two call lines" gd-pasubst "2/0" gd
as_shape_arm "ASGN-SUBST-M17: the operand-name mutant removes its line" pasubstname "1/0"

# --- the listed script inside the substitution: recorded as unresolvable before, admitted after ---
as_arm "SUBST-BOUNDARY-ASGN-LISTED: an admitted shell interpreter against the opener, the listed script quoted as the substitution's last word" AS01 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-dq: as LISTED, the value double-quoted" AS02 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-tick: as LISTED, opened by a backtick" AS03 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-nonshell: a non-shell interpreter and its listed script" AS04 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-source: the dot or source against the opener" AS05 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-env: as an env operand ahead of a plain command" AS06 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-later: a later segment of a command whose bail does not latch" AS07 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-encl: inside a subshell group, at its enclosure position" AS08 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-arg (declared precision): a reader command against the opener, the listed path its argument" AS09 a W:exec:unresolvable
as_arm "SUBST-BOUNDARY-ASGN-LISTED-direct: a blank after the opener, the listed path itself the inner command word" AS10 a W:exec:unresolvable
as_rows_arm "SUBST-BOUNDARY-ASGN-LISTED-enforce: with the exec arm at enforce the listed rows are admitted; the walk before refuses them" "forced:a forced-pasubst:B" AS01 AS02 AS03 AS04 AS05 AS06 AS07 AS08 AS09 AS10
as_arm "SUBST-BOUNDARY-ASGN-LISTED-ctl: the listed path unquoted, which the trailing-run strip already resolves" AS11 a a

# --- the unlisted or unresolvable script keeps both of today's records ---
as_arm "SUBST-BOUNDARY-ASGN-UNLISTED: an unlisted script keeps the exec arm's record beside the enclosure family's" AS12 W:exec:unresolvable+shell-enclosure:not-allowlisted W:exec:unresolvable+shell-enclosure:not-allowlisted pasubstallow W:shell-enclosure:not-allowlisted
as_arm "SUBST-BOUNDARY-ASGN-UNLISTED-row: the seed row of a double-quoted value running an unlisted script" EN06 W:exec:not-allowlisted+shell-enclosure:not-allowlisted W:exec:not-allowlisted+shell-enclosure:not-allowlisted
as_arm "SUBST-BOUNDARY-ASGN-UNLISTED-plain: the unquoted spelling" AV29 W:exec:not-allowlisted+shell-enclosure:not-allowlisted W:exec:not-allowlisted+shell-enclosure:not-allowlisted
as_arm "SUBST-BOUNDARY-ASGN-UNLISTED-var: a variable-bearing path" AS13 W:exec:unresolvable+shell-enclosure:unresolvable W:exec:unresolvable+shell-enclosure:unresolvable
as_rows_arm "SUBST-BOUNDARY-ASGN-UNLISTED-enforce: refused under either family's graduation, before and after" "forced:B enclforced:B forced-pasubst:B" AS12 EN06 AV29

# --- the declared tightening: a command word written after the assignment is now adjudicated ---
as_arm "ASGN-SUBST-OUTER-exec (declared tightening): the record names the unlisted command word, not the substitution's path" AS14 W:exec:not-allowlisted W:exec:unresolvable
as_arm "ASGN-SUBST-OUTER-interp (declared tightening): an interpreter after the assignment is refused, as a first-view finding" AS15 B W:exec:unresolvable

# --- the declines: today's reading, each held by its condition ---
as_arm "ASGN-SUBST-KEEP-trust: a later segment of a command whose bail latched" AS16 W:exec:unresolvable W:exec:unresolvable pasubsttrust a
as_arm "ASGN-SUBST-KEEP-pfx: a double-quoted value left open across the assignment" AS17 W:exec:unresolvable W:exec:unresolvable pasubstpfx a
as_arm "ASGN-SUBST-KEEP-end: a value that continues past the closer, before an unlisted script" AS18 W:exec:unresolvable W:exec:unresolvable pasubstend a
as_arm "ASGN-SUBST-KEEP-work: the shared work budget already spent (fail-closed)" AS19 W:exec:unresolvable W:exec:unresolvable pasubstwork a
as_arm "ASGN-SUBST-KEEP-blank (declared over-block): a blank between the opener and the interpreter" AS20 B B
as_arm "ASGN-SUBST-KEEP-wrap (declared over-block): a wrapper against the opener, then the interpreter" AS21 B B
as_arm "ASGN-SUBST-KEEP-tickdq: a backtick opener inside a double-quoted value" AS22 W:exec:unresolvable W:exec:unresolvable pasubstshape a
as_arm "ASGN-SUBST-KEEP-slash: a path written against the opener keeps the first view's record of the listed argument" AS23 W:exec:unresolvable+exec:not-allowlisted W:exec:unresolvable+exec:not-allowlisted pasubstslash W:exec:not-allowlisted
as_rel_arm "ASGN-SUBST-KEEP-cut: a listed word with no closer in its token, the substitution going on to an unlisted word" "$as_cut" hook pasubst pasubstcut
as_rel_arm "ASGN-SUBST-KEEP-norm: a closing word that closes its quote and continues normalizes to no single word" "$as_norm" hook pasubst pasubstnorm
as_rel_arm "ASGN-SUBST-KEEP-moved: where the value step crossed the value (guards off), the step does not read past it" "$as_moved" gd gd-pasubst gd-moved
# Stage 7: env's operand loop takes any assignment-shaped operand, so an operand whose text before its
# first `=` opens a quote carries the shell's word past the closer (F-01); a quoted listed path holding a
# space, which the closer test, the one-word test and the allowlist each decline, so no one-line mutant
# moves it (F-04); and a quoted listed closing word named as an interpreter, where the step records
# the unlisted script after it and the walk before records nothing, so no decline is taken there (D-2).
as_arm "ASGN-SUBST-KEEP-name: an env operand whose name part opens a quote keeps today's record" AS24 W:exec:unresolvable W:exec:unresolvable pasubstname a
as_arm "ASGN-SUBST-KEEP-space (declared residual): a quoted listed path holding a space keeps today's reading, an allow" AS25 a a
as_run hook "$as_verb"; as_verb_h="$AS_V"
as_run pasubst "$as_verb"; as_verb_m="$AS_V"
if [ "$as_verb_h" = "W:exec:not-allowlisted" ] && [ "$as_verb_m" = a ]; then
  as_pass "ASGN-SUBST-PIN-verb: a quoted listed closing word named as an interpreter, then an unlisted script: the step records the script, the walk before records nothing (hook ${as_verb_h}, pasubst ${as_verb_m})"
else
  as_fail "ASGN-SUBST-PIN-verb: a quoted listed closing word named as an interpreter, then an unlisted script: the step records the script, the walk before records nothing" " hook=${as_verb_h}(wanted W:exec:not-allowlisted) pasubst=${as_verb_m}(wanted a)"
fi

# --- the seam with the backtick command word: the step crosses, and the word after it keeps its reading ---
as_run hook "$as_int"; as_int_v="$AS_V"
as_run pasubst "$as_int"; as_int_m="$AS_V"
case "$as_int_v" in
  a|B|E[0-9]*) as_fail "ASGN-SUBST-INT-tick: a backtick-led command word after a listed assignment substitution is still recorded" " hook=${as_int_v} pasubst=${as_int_m}" ;;
  *)
    if [ "$as_int_v" != "$as_int_m" ]; then
      as_pass "ASGN-SUBST-INT-tick: a backtick-led command word after a listed assignment substitution is still recorded (hook ${as_int_v}, pasubst ${as_int_m})"
    else
      as_fail "ASGN-SUBST-INT-tick: a backtick-led command word after a listed assignment substitution is still recorded" " the-step-did-not-cross: hook=${as_int_v} pasubst=${as_int_m}"
    fi
    ;;
esac

# --- the adjacent rows that must not move ---
as_arm "ASGN-SUBST-PIN-adjacent: a substitution value whose closing word is an option" WR132 a a
as_arm "ASGN-SUBST-PIN-adjacent-dq: a double-quoted substitution value with no closer in the next token" WR133 a a
as_arm "ASGN-SUBST-PIN-av46: a substitution whose closer is in the assignment token itself" AV46 a a
as_arm "ASGN-SUBST-PIN-near: an interpreter run for its version" EN52 a a
as_arm "ASGN-SUBST-PIN-near-redir: a counting command reading the script on standard input" EN54 a a

# --- the same block under leading-glob allowlist entries: the classes such an entry could admit decline ---
as_why=""
for as_c in pasubst pasubstmoved pasubsttrust pasubstshape pasubstslash pasubstpfx pasubstwork pasubstcut pasubstend pasubstnorm pasubstplain pasubstopt pasubstallow pasubstname forced forced-pasubst enclforced gd gd-pasubst gd-moved; do
  /usr/bin/cmp -s "${AS_ROOT}/.claude/hooks/block-destructive-${as_c}.sh" "${AS_GROOT}/.claude/hooks/block-destructive-${as_c}.sh" || as_why="${as_why} ${as_c}"
done
if [ -z "$as_why" ]; then
  as_pass "ASGN-SUBST-GLOB-copies: the leading-glob root's copies are the ones whose shapes are shown above"
else
  as_fail "ASGN-SUBST-GLOB-copies: the leading-glob root's copies are the ones whose shapes are shown above" "$as_why"
fi
as_root "$AS_GROOT"
as_arm "ASGN-SUBST-GLOB-LISTED: the listed script, admitted through a leading-glob entry" AS01 a W:exec:unresolvable
as_rel_arm "ASGN-SUBST-GLOB-opt-dash: a closing word that begins with a dash, which a leading-glob entry matches, is not crossed" "$as_optd" hook pasubst pasubstopt
as_rel_arm "ASGN-SUBST-GLOB-opt-plus: a closing word that begins with a plus, which a leading-glob entry matches, is not crossed" "$as_optp" hook pasubst pasubstopt
as_arm "ASGN-SUBST-GLOB-var: a variable-bearing closing word, which a leading-glob entry matches, is not crossed" AS13 W:exec:unresolvable+shell-enclosure:unresolvable W:exec:unresolvable+shell-enclosure:unresolvable pasubstplain W:shell-enclosure:unresolvable
as_rel_arm "ASGN-SUBST-GLOB-norm: a closing word that normalizes to no single word is not crossed" "$as_norm" hook pasubst pasubstnorm
as_arm "ASGN-SUBST-GLOB-UNLISTED: an unlisted script keeps both records" AS12 W:exec:unresolvable+shell-enclosure:not-allowlisted W:exec:unresolvable+shell-enclosure:not-allowlisted pasubstallow W:shell-enclosure:not-allowlisted
as_arm "ASGN-SUBST-GLOB-trust: a later segment of a command whose bail latched" AS16 W:exec:unresolvable W:exec:unresolvable pasubsttrust a
as_arm "ASGN-SUBST-GLOB-pfx: a double-quoted value left open across the assignment" AS17 W:exec:unresolvable W:exec:unresolvable pasubstpfx a
as_arm "ASGN-SUBST-GLOB-end: a value that continues past the closer" AS18 W:exec:unresolvable W:exec:unresolvable pasubstend a
as_arm "ASGN-SUBST-GLOB-work: the shared work budget already spent" AS19 W:exec:unresolvable W:exec:unresolvable pasubstwork a
as_arm "ASGN-SUBST-GLOB-tickdq: a backtick opener inside a double-quoted value" AS22 W:exec:unresolvable W:exec:unresolvable pasubstshape a
as_arm "ASGN-SUBST-GLOB-slash: a path written against the opener" AS23 W:exec:unresolvable+exec:not-allowlisted W:exec:unresolvable+exec:not-allowlisted pasubstslash W:exec:not-allowlisted
as_rel_arm "ASGN-SUBST-GLOB-cut: a listed word with no closer in its token" "$as_cut" hook pasubst pasubstcut
/bin/rm -rf "$AS_ROOT" "$AS_GROOT"

# ==========================================================================
# BLOCK-022 — env's split-string value read as env reads it (SPLITV-*)
# ==========================================================================
#
# env's split-string value (`-S<value>`, `--split-string=<value>` and its prefixes) is env's
# own argv. script_split_read reads it after the shell removes its quotes, word by word, in
# env's own order, under Rule M: the stop set may only shrink, and where the reading finds a
# command word of the value's own, or cannot read the value, today's classifier decides. The
# one exception, toward adjudication: a value it cannot read whose split token carries no slash
# walks on (PC-SV1, the declared cost). Under J0 a value whose quote spans whitespace is read
# from its first piece only, and later pieces walk as ordinary tokens. Every arm reads its
# command from seed 15.4 by row id, in this block's hermetic root.
#
# Copies, each shown to differ by its marked lines:
#   svread  the reading is never asked (the M-WRAP-SPLITREAD line removed): the walk before
#   svstop  Rule M's cell inverted: a value the reading cannot read, or reads as carrying its
#           own command, stops the walk on the split token even where today's walk walks on
/usr/bin/sed '/# M-WRAP-SPLITREAD$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-svread.sh"
/usr/bin/sed '/# M-WRAP-SPLITMONO$/s/script_sv=old; return 0/script_wsplit_cmd=1; script_sv=cmd; return 0/' "$HOOK" > "${AQ_HOOKS}/block-destructive-svstop.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-svread.sh" "${AQ_HOOKS}/block-destructive-svstop.sh"

# sv_arm <label> <row id> <hook verdict> [<copy> <its verdict>] — the shipped copy on that
# row's command, then the copy's limb when one is named. A wanted B must name
# BLOCK-DESTRUCTIVE-022, and a limb that expects the arm's own verdict fails, since it could
# not show the arm failing.
sv_arm() {
  local name="$1" row="$2" want="$3" pmut="${4:-}" pwant="${5:-}" got gotp="" ok=1 why=""
  if ! wc_row_cmd "$row"; then
    /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$name" "$row"
    FAIL=$((FAIL + 1))
    return 0
  fi
  aq_run block-destructive.sh "$WC_CMDX"
  got="$AQ_V"
  if [ "$got" != "$want" ]; then ok=0; why="hook=${got}"; fi
  if [ "$ok" = 1 ] && [ "$want" = "B" ] && ! /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-022' <<<"$AQ_ERR"; then
    ok=0; why="the refusal does not name BLOCK-DESTRUCTIVE-022"
  fi
  if [ -n "$pmut" ]; then
    if [ "$pwant" = "$want" ]; then ok=0; why="${why} the ${pmut} limb expects the arm's own verdict"; fi
    aq_run "block-destructive-${pmut}.sh" "$WC_CMDX"
    gotp="$AQ_V"
    if [ "$gotp" != "$pwant" ]; then ok=0; why="${why} ${pmut}=${gotp}"; fi
  fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s [row %s] (hook %s%s)\n' "$name" "$row" "$got" "${pmut:+, ${pmut} ${gotp}}"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s [row %s]\n  wanted hook=%s%s; observed %s\n  stderr: %s\n' "$name" "$row" "$want" "${pmut:+ ${pmut}=${pwant}}" "${why# }" "$AQ_ERR"
    FAIL=$((FAIL + 1))
  fi
}

aq_shape_arm "SPLITV-M1: the reading mutant removes its one call line" block-destructive-svread.sh "1/0"
aq_shape_arm "SPLITV-M2: the Rule M mutant rewrites its one line" block-destructive-svstop.sh "1/1"

# SPLITV-STRUCT-01: inside script_split_read nothing assigns script_wsplit_cmd=1 (the reading
# can only let the walk go on, never stop it), and its call line sits directly after the
# M-WRAP-SPLITCMD line, so it runs before the unchanged body and after its reset.
sv_struct="$(/usr/bin/awk '
  /^script_split_read\(\) *\{/ { inf = 1; seen = 1 }
  inf && /script_wsplit_cmd=1/ { bad++ }
  inf && /^}/ { inf = 0 }
  /# M-WRAP-SPLITCMD$/ { cmd = NR }
  /# M-WRAP-SPLITREAD$/ { rd = NR }
  END { printf "%d %d %d", seen, bad + 0, (rd == cmd + 1 && cmd > 0) }' "$HOOK")"
if [ "$sv_struct" = "1 0 1" ]; then
  /usr/bin/printf 'PASS: SPLITV-STRUCT-01 the reading never stops the walk, and runs right after the reset\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: SPLITV-STRUCT-01 wanted "1 0 1" (function present, no stop assignment, call line after the reset); observed "%s"\n' "$sv_struct"
  FAIL=$((FAIL + 1))
fi

# --- the closures: refused; the walk before allows ---
sv_arm "SPLITV-QUOTED-01: a quote-led value of options only, short spelling" SV01 B svread a
sv_arm "SPLITV-QUOTED-02: the same value under the long spelling" SV02 B svread a
sv_arm "SPLITV-QUOTED-02b: the same value under a unique prefix of the long spelling" SV03 B svread a
sv_arm "SPLITV-QUOTED-03: a quote-led empty value" SV04 B svread a
sv_arm "SPLITV-QUOTED-04: a quote-led value holding one assignment" SV05 B svread a
sv_arm "SPLITV-QUOTED-05: a dash-led value whose inner quote leaves an option needing the following token" SV06 B svread a
sv_arm "SPLITV-QUOTED-06: a quote-led value whose quoted span holds a blank, options and assignments only, reached under J0" SV24 B svread a
sv_arm "SPLITV-SLASH-01: an option in the value whose attached argument holds a path" SV07 B svread a
sv_arm "SPLITV-SLASH-02: the same, long spelling" SV08 B svread a
sv_arm "SPLITV-SLASH-03: an assignment in the value whose value holds a path" SV09 B svread a
sv_arm "SPLITV-DISC-01: a long option in the value needing the following token" SV10 B svread a
sv_arm "SPLITV-DISC-02: an assignment in the value whose name is not a shell name" SV11 B svread a
sv_arm "SPLITV-DISC-03: a value the reading cannot read, whose split token carries no slash" SV12 B svread a
sv_arm "SPLITV-COST-01 (PC-SV1, declared): an unreadable value carrying its own command, ahead of an unlisted script argument nothing runs" SV17 B svread a

# --- the controls: refused before and after ---
sv_arm "SPLITV-ctl-01: the unquoted, slash-free twin of QUOTED-01" SV13 B
sv_arm "SPLITV-ctl-02: the unquoted twin of QUOTED-04" SV14 B
sv_arm "SPLITV-ctl-03: the slash-free twin of SLASH-01's option class" SV15 B
sv_arm "SPLITV-MONO-01: Rule M's control, a dash-led value the reading cannot read, which the walk walks on from today" SV26 B svstop a
sv_arm "SPLITV-MONO-02: a dash-led value whose quoted span carries a command of its own still reaches it" SV16 B

# --- the near-misses and the declared residuals: allowed before and after ---
sv_arm "SPLITV-near-01: QUOTED-01's class ahead of the listed script" SV18 a pallow B
sv_arm "SPLITV-near-02: SLASH-01's class ahead of the listed script" SV19 a pallow B
sv_arm "SPLITV-near-03: QUOTED-01's class ahead of a command that runs no script" SV20 a
sv_arm "SPLITV-RESID-01 (S2): a quoted value carrying its own command word and an unlisted script" SV21 a
sv_arm "SPLITV-RESID-02 (S4): a separator inside a quoted options-only value" SV22 a
sv_arm "SPLITV-RESID-03 (S4): env's own quoting inside the decoded value, hiding an option's need for the following token" SV23 a
# The precision cells P-1 and P-2 (D-8491-PrecAccept, Stage 8 QF-01): each takes its plain form's verdict, recorded at
# the direct-execution arm's phase for a slash-bearing script and allowed for a PATH-resolved word. The reverse mutant
# svread reads each as the pre-fix hook did (refused), which is the red-before evidence; the plain forms do not move.
sv_arm "SPLITV-PREC-01: P-1, a path inside an option's argument, before a slash-bearing script, takes its plain form's verdict" SV27 W:exec svread B
sv_arm "SPLITV-PREC-02: P-1, the same before a PATH-resolved word, is allowed as its plain form is" SV28 a svread B
sv_arm "SPLITV-PREC-03: P-2, a token an option inside the value takes, before a slash-bearing script, takes its plain form's verdict" SV29 W:exec svread B
sv_arm "SPLITV-PREC-04: P-2, the same before a PATH-resolved word, is allowed as its plain form is" SV30 a svread B
sv_arm "SPLITV-PREC-ctl-01: P-1's plain form, slash-bearing" SV31 W:exec
sv_arm "SPLITV-PREC-ctl-02: P-1's plain form, PATH-resolved" SV32 a
sv_arm "SPLITV-PREC-ctl-03: P-2's plain form, slash-bearing" SV33 W:exec
sv_arm "SPLITV-PREC-ctl-04: P-2's plain form, PATH-resolved" SV34 a
sv_arm "SPLITV-RESID-04 (J0): a later piece whose stray quote hides an option's need for the following token" SV25 a

# --- SPLITV-TWIN: the canonicalizer's twin (core/hooks/lib/command-position.awk, T1 with T1b) ---
# The default view marks each command start with an inserted `;`. For every row below the twin
# must put that mark on the token env runs, in en_US.UTF-8 and in C: the first token after a
# split value that carries no command of its own (after any argument its last option takes from
# the following tokens), or the split token itself when the value carries a command word. The
# twin's tokens hold a quoted span whole, so it reads such a value entire where -022's J0 reads
# its first piece (SV25 closes in the twin). Excluded as declared divergences: D-1, a separator
# inside the value (SV22), since the two segmentation layers differ; D-2, a value neither can
# read (SV12, SV17), which -022 walks on from and the twin keeps stopped (T1b); D-3, a dash-led
# quoted span that carries a command of its own (SV16), which -022 walks piece by piece and the
# twin holds whole.
SV_CANON="${HOOK%/*}/lib/command-position.awk"
SV_CANON_M1="$(/usr/bin/mktemp)"
/usr/bin/sed '/# M-CP-SPLITREAD$/d' "$SV_CANON" > "$SV_CANON_M1"
sv_tw_rows=(SV01 SV02 SV03 SV04 SV05 SV06 SV07 SV08 SV09 SV10 SV11 SV13 SV14 SV15 SV18 SV19 SV20 SV24 SV25 SV26 \
  SV21 WR68 WR69 GL80 SN01 SN02 SN03 SN04 SN05 SN06 SN07 SN08 SN09 SN10)
sv_tw_want=(bash bash bash bash bash bash bash bash bash bash bash bash bash bash bash bash cat bash bash bash \
  "-S'bash" "-Sbash" "-S\"bash" "--s=bash" bash bash bash bash bash bash bash bash "@D@/na.sh" bash)
sv_twin_rows() {   # $1 = canonicalizer file  $2 = locale -> sv_twin_bad, the rows whose mark is elsewhere
  local k=0 want out
  sv_twin_bad=""
  while [ "$k" -lt "${#sv_tw_rows[@]}" ]; do
    want="${sv_tw_want[$k]//@D@/$WC_D}"
    if ! wc_row_cmd "${sv_tw_rows[$k]}"; then
      sv_twin_bad="${sv_twin_bad} ${sv_tw_rows[$k]}(missing)"
    else
      out="$(LC_ALL="$2" /usr/bin/awk -f "$1" <<<"$WC_CMDX" 2>/dev/null)"
      case "$out" in
        *"; ${want}"*) ;;
        *) sv_twin_bad="${sv_twin_bad} ${sv_tw_rows[$k]}" ;;
      esac
    fi
    k=$(( k + 1 ))
  done
}
for sv_loc in C en_US.UTF-8; do
  sv_twin_rows "$SV_CANON" "$sv_loc"
  if [ -z "$sv_twin_bad" ]; then
    /usr/bin/printf 'PASS: SPLITV-TWIN-01 [%s] the twin marks the command env runs on all %d rows\n' "$sv_loc" "${#sv_tw_rows[@]}"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: SPLITV-TWIN-01 [%s] the twin marks a different token on:%s\n' "$sv_loc" "$sv_twin_bad"
    FAIL=$((FAIL + 1))
  fi
done
sv_tw_removed="$(/usr/bin/diff "$SV_CANON" "$SV_CANON_M1" | /usr/bin/awk 'index($0, "<") == 1 { r++ } END { print r + 0 }')"
sv_twin_rows "$SV_CANON_M1" C
if [ "$sv_tw_removed" -ge 1 ] && [ -n "$sv_twin_bad" ]; then
  /usr/bin/printf 'PASS: SPLITV-TWIN-M1 the twin without its %d M-CP-SPLITREAD lines marks a different token on:%s\n' "$sv_tw_removed" "$sv_twin_bad"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: SPLITV-TWIN-M1 wanted a copy that loses at least one marked line and is reported on at least one row; lines removed %s, rows reported:%s\n' "$sv_tw_removed" "${sv_twin_bad:- none}"
  FAIL=$((FAIL + 1))
fi
/bin/rm -f "$SV_CANON_M1"

# ==========================================================================
# BLOCK-022 — an interpreter and its operand read across a line continuation (CONT-*)
# ==========================================================================
#
# The shell removes a backslash-newline outside quotes and inside "…", so an interpreter and its
# operand split across one are one command. Every physical reading stays as it was; the joined
# logical line is ADDED for one more first-view walk (M-CONT-WALK), and a here-document's
# receiver is read from the physical and from the logical line, the body excised only when both
# name a carrier (M-CONT-RECV). Rows from seed 15.5, by id.
#   contwalk  the joined line is never walked (its one line removed)
#   contrecv  the receiver is read from the physical line only (its one line removed)
/usr/bin/sed '/# M-CONT-WALK$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-contwalk.sh"
/usr/bin/sed '/# M-CONT-RECV$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-contrecv.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-contwalk.sh" "${AQ_HOOKS}/block-destructive-contrecv.sh"
aq_shape_arm "CONT-M1: the joined-walk mutant removes its one line" block-destructive-contwalk.sh "1/0"
aq_shape_arm "CONT-M2: the receiver-conjunction mutant removes its one line" block-destructive-contrecv.sh "1/0"

# --- the closures ---
sv_arm "CONT-INTERP-01: an interpreter and an unlisted script split by a continuation" LC01 B contwalk W:exec
sv_arm "CONT-INTERP-02: the same under source" LC02 B contwalk W:exec
sv_arm "CONT-INTERP-03: the same with an option before the continuation" LC03 B contwalk W:exec
sv_arm "CONT-INTERP-04: the same with the operand line indented" LC04 B contwalk W:exec
sv_arm "CONT-DQ-01: a continuation inside double quotes, which the shell also removes, splitting the operand" LC05 B contwalk a
sv_arm "CONT-HD-01: a physical receiver line naming a carrier, whose logical command is a shell reading its input" LC06 B contrecv a

# --- what must not move ---
sv_arm "CONT-HD-02: a receiver read before a continuation keeps today's verdict" LC07 B
sv_arm "CONT-HD-DUP-01: a later line equal to the delimiter excises nothing between" LC08 B
sv_arm "CONT-ENCL-01: a continuation inside an enclosure keeps the first-view refusal" LC09 B
sv_arm "CONT-CMT-01: a backslash ending a comment is not joined" LC10 B
sv_arm "CONT-CMT-PHASE-01: a comment holding a quote does not hide the next line" LC11 B
sv_arm "CONT-SQ-01: a backslash-newline inside single quotes is kept" LC12 a
sv_arm "CONT-ANSI-01: a backslash-newline inside ANSI-C quotes is kept" LC13 a
sv_arm "CONT-near-01: the listed script across a continuation" LC14 a
sv_arm "CONT-ARG-01: a continued argument line of a command that runs no script stays its own segment" LC15 W:exec

# ==========================================================================
# BLOCK-022 — the command positions the walk did not reach (REACH-*), slice A: the words
# ==========================================================================
#
# R0, today's reading first and unchanged: the walk newly steps past a token only where today's
# walk ends on that token and adjudicates nothing. Slice A reads a command word, a wrapper word
# and a wrapper's option after quote removal (script_ws_lit marks a complete reading the shell
# would take literally, a backslash-free `$'…'` included), and walks the zsh precommand words.
# Rows from seed 15.6 and the seed-6 / seed-1 rows the design names, by id.
#   rmverb    the escaped or quoted verb is never resolved (the M-REACH-VERB block removed)
#   rmlookup  the prefix walk dispatches on the raw token (the M-REACH-LOOKUP line removed)
#   rmkw      the zsh precommand words leave the keyword and wrapper lines
/usr/bin/sed '/# >>> M-REACH-VERB$/,/# <<< M-REACH-VERB$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmverb.sh"
/usr/bin/sed '/# M-REACH-LOOKUP$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmlookup.sh"
/usr/bin/sed -e '/# M-WRAP-KEYWORDS/s/|nocorrect)/)/' -e '/# M-WRAP-WORDS/s/|noglob|-|/|/' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmkw.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-rmverb.sh" "${AQ_HOOKS}/block-destructive-rmlookup.sh" "${AQ_HOOKS}/block-destructive-rmkw.sh"
aq_shape_arm "REACH-M1: the verb mutant removes its marked block" block-destructive-rmverb.sh "17/0"
aq_shape_arm "REACH-M2: the lookup mutant removes its one line" block-destructive-rmlookup.sh "1/0"
aq_shape_arm "REACH-M3: the zsh-word mutant rewrites the keyword and wrapper lines" block-destructive-rmkw.sh "2/2"

# REACH-VERB-LISTS: every hook line that begins with the interpreter alternation carries the
# identical set, and there are four of them (the raw view, the normalized view, the word view and
# script_reach_verbish), so a new view cannot carry a narrower set.
reach_vl="$(/usr/bin/awk '
  /^[ \t]*bash\|sh\|zsh\|python\|python3\|perl\|ruby\|node\)/ {
    l = $0; sub(/^[ \t]*/, "", l); sub(/\).*/, "", l); n++; if (s == "") s = l; else if (l != s) bad++
  }
  END { printf "%d %d", n, bad + 0 }' "$HOOK")"
if [ "$reach_vl" = "4 0" ]; then
  /usr/bin/printf 'PASS: REACH-VERB-LISTS four interpreter-alternation lines, one identical set\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: REACH-VERB-LISTS wanted "4 0" (four lines, no differing set); observed "%s"\n' "$reach_vl"
  FAIL=$((FAIL + 1))
fi

# --- the escaped or quoted verb ---
sv_arm "REACH-ESC-01: a backslash-escaped verb" WR141 B rmverb a
sv_arm "REACH-ESC-02: a backslash inside the verb" CP23 B rmverb a
sv_arm "REACH-ESC-03: a partly quoted verb" V01 B rmverb a
sv_arm "REACH-ESC-04: an empty-quote prefix on the verb" V02 B rmverb a
sv_arm "REACH-ESC-05: a backslash-free ANSI-C quoted verb" CP24 B rmverb a
sv_arm "REACH-ESC-06: an escaped source" CP25 B rmverb a
sv_arm "REACH-ESC-ctl: an escaped verb with the listed script" V03 a
sv_arm "REACH-ESC-near-1: a quoted strict prefix of a verb" CP27 a
sv_arm "REACH-ESC-near-2: an ANSI-C run holding a backslash escape (R-6, declared)" CP28 a
sv_arm "REACH-ESC-near-3: an escaped absolute interpreter, already resolved by the normalized view" CP26 B

# --- the quoted wrapper word and option ---
sv_arm "REACH-QWRAP-01: a double-quoted wrapper" WR142 B rmlookup a
sv_arm "REACH-QWRAP-02: a single-quoted wrapper" CP29 B rmlookup a
sv_arm "REACH-QWRAP-02b: an escaped wrapper" CP30 B rmlookup a
sv_arm "REACH-QWRAP-02c: a partly quoted wrapper" CP31 B rmlookup a
sv_arm "REACH-QWRAP-03: a quoted option taking a separate value" CP32 B
sv_arm "REACH-QWRAP-04: a quoted xargs with no operand (the stdin deny)" CP33 B rmlookup a
sv_arm "REACH-QWRAP-05: a quoted option whose attached value holds a path (the review's FM-2)" CP34 B
sv_arm "REACH-QWRAP-near-1: a quoted reserved word stays unreserved" CP35 a
sv_arm "REACH-QWRAP-near-2: a quoted describe-only option" CP36 a
sv_arm "REACH-QWRAP-near-3: quoting before the last slash of a wrapper token keeps today's dispatch" CP37 B
sv_arm "REACH-QWRAP-near-4: a quoted option-shaped token under timeout's positional (declared)" CP38 a

# --- the zsh precommand words ---
sv_arm "REACH-ZPRE-01: noglob" CP59 B rmkw a
sv_arm "REACH-ZPRE-02: nocorrect" CP60 B rmkw a
sv_arm "REACH-ZPRE-03: a lone dash" CP61 B rmkw a
sv_arm "REACH-ZPRE-04: nocorrect then noglob" CP62 B rmkw a
sv_arm "REACH-ZPRE-near: the three words as arguments" CP63 a

# --- each class with the listed script ---
sv_arm "REACH-ctl-esc: an escaped verb with the listed script" CP65 a
sv_arm "REACH-ctl-qwrap: a quoted wrapper with the listed script" CP66 a
sv_arm "REACH-ctl-zpre: a zsh precommand word with the listed script" CP70 a

# --- slice B: the leading redirection ---
# A redirection is stepped where today's walk ends on it (R0), at the prefix walk's end and
# inside a wrapper's own grammar (the review's CD-2); an operator the separator split cut is
# carried for one segment; an input word ahead of an interpreter is that interpreter's program
# (the review's CD-1), adjudicated as the -c loop adjudicates a program string.
#   rmloop   the reach step never steps (`script_reach_step || break` -> `break`)
#   rmcarry  the one-segment carry is never set (its one line removed)
#   rmstdin  the stdin program is never adjudicated (its marked block removed)
/usr/bin/sed 's/script_reach_step || break   # M-REACH$/break   # M-REACH/' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmloop.sh"
/usr/bin/sed '/# M-REACH-CARRY$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmcarry.sh"
/usr/bin/sed '/# >>> M-REACH-STDIN$/,/# <<< M-REACH-STDIN$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmstdin.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-rmloop.sh" "${AQ_HOOKS}/block-destructive-rmcarry.sh" "${AQ_HOOKS}/block-destructive-rmstdin.sh"
aq_shape_arm "REACH-M4: the reach-loop mutant rewrites its one line" block-destructive-rmloop.sh "1/1"
aq_shape_arm "REACH-M5: the carry mutant removes its one line" block-destructive-rmcarry.sh "1/0"
sv_rm_n="$(/usr/bin/awk '/# >>> M-REACH-STDIN$/{s=NR} /# <<< M-REACH-STDIN$/{if (s) print NR - s + 1}' "$HOOK")"
aq_shape_arm "REACH-M6: the stdin mutant removes its marked block" block-destructive-rmstdin.sh "${sv_rm_n:-MISSING}/0"
sv_arm "REACH-REDIR-01: an attached output redirection ahead of an interpreter" WR140 B rmloop a
sv_arm "REACH-REDIR-02: the operator alone, its word the next token" CP02 B rmloop a
sv_arm "REACH-REDIR-03: a descriptor form" CP01 B rmloop a
sv_arm "REACH-REDIR-03b: a {name} form" CP03 B rmloop a
sv_arm "REACH-REDIR-04: between assignments" CP04 B rmloop a
sv_arm "REACH-REDIR-04b: after a reserved word" CP05 B rmloop a
sv_arm "REACH-REDIR-04c: between a wrapper and its command" CP06 B
sv_arm "REACH-REDIR-04d: between a wrapper and its first option (the review's CD-2)" CP07 B
sv_arm "REACH-REDIR-04e: ahead of timeout's duration (the review's CD-2)" CP08 B
sv_arm "REACH-REDIR-05: a duplication cut by the separator split" CP10 B rmcarry a
sv_arm "REACH-REDIR-05b: a clobber cut by the separator split" CP12 B rmcarry a
sv_arm "REACH-REDIR-06: an unlisted script fed on a shell's standard input" CP13 B rmstdin a
sv_arm "REACH-REDIR-06b: the same through descriptor 0" CP14 B rmstdin a
sv_arm "REACH-REDIR-06c: a here-string program ahead of a shell (the review's CD-1)" CP16 B rmstdin a
sv_arm "REACH-REDIR-07: an unlisted .py fed to python3, at the non-shell arm's phase" CP15 W:interp-nonshell rmstdin a
sv_arm "REACH-REDIR-08: a leading redirection inside an enclosure, at the enclosure's phase" CP09 W:shell-enclosure
sv_arm "REACH-REDIR-P1 (PM-1, declared): an output redirection word is not an execution" CP17 a
sv_arm "REACH-REDIR-near-1: a process substitution is not a redirection" CP18 a
sv_arm "REACH-REDIR-near-2: a redirection word with an interpreter basename keeps today's reading (R-2)" CP19 B
sv_arm "REACH-REDIR-R1 (PC-2, declared): a stdin word beside a listed script argument" CP20 B
sv_arm "REACH-REDIR-R2 (PC-2, declared): a stdin word under parse-only" CP21 B
sv_arm "REACH-REDIR-resid (FM-1, declared): a redirection between a wrapper's option and its value" CP22 a
sv_arm "REACH-ctl-redir: a leading redirection with the listed script" CP64 a

# --- slice C: the compound positions ---
# A brace group, `coproc` (with a `coproc NAME {` name), and a `case` arm: the first arm through
# a lead-in that steps the subject, `in`, an optional `(` and the first pattern's closer; a later
# arm through a segment-start closer step, gated on the command having opened a `case` and on the
# closer being inert (the review's FM-2). Inside an enclosure the cut reads past a case pattern's
# closer (M-REACH-CUT).
#   rmcase  the lead-in and the coproc name are never stepped (the M-REACH-CASE line removed)
#   rmkw2   `{`, `case` and `coproc` leave the keyword line
#   rmcut   the enclosure cut stops at a case pattern's closer (the M-REACH-CUT line removed)
/usr/bin/sed '/# M-REACH-CASE$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmcase.sh"
/usr/bin/sed "/# M-WRAP-KEYWORDS/s/|'{'|case|coproc|/|/" "$HOOK" > "${AQ_HOOKS}/block-destructive-rmkw2.sh"
/usr/bin/sed '/# M-REACH-CUT$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-rmcut.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-rmcase.sh" "${AQ_HOOKS}/block-destructive-rmkw2.sh" "${AQ_HOOKS}/block-destructive-rmcut.sh"
aq_shape_arm "REACH-M7: the case mutant removes its one line" block-destructive-rmcase.sh "1/0"
aq_shape_arm "REACH-M8: the compound-keyword mutant rewrites the keyword line" block-destructive-rmkw2.sh "1/1"
aq_shape_arm "REACH-M9: the cut mutant removes its one line" block-destructive-rmcut.sh "1/0"
sv_arm "REACH-CASE-01: the first arm" EN80 B rmcase a
sv_arm "REACH-CASE-02: a later arm" CP39 B
sv_arm "REACH-CASE-03: an alternation the separator split cuts" CP40 B
sv_arm "REACH-CASE-04: a leading ( joined to the pattern" CP41 B rmcase a
sv_arm "REACH-CASE-04b: a leading ( spaced" CP42 B rmcase a
sv_arm "REACH-CASE-05: a spaced closer behind a quoted pattern holding whitespace" CP43 B rmcase a
sv_arm "REACH-CASE-06: the first arm inside an enclosure, at the enclosure's phase" EN81 W:shell-enclosure rmcut a
sv_arm "REACH-CASE-07: a later arm inside an enclosure, a first-view segment" CP44 B
sv_arm "REACH-CASE-08: a later arm whose pattern holds a slash but no exec-domain suffix (the review's FM-2)" CP45 B
sv_arm "REACH-CASE-near-2: a pattern named after an interpreter keeps today's reading (R-2)" CP47 a
sv_arm "REACH-CASE-near-3: a script-named subject, the arm running nothing" CP48 a
sv_arm "REACH-CASE-near-4: a list marker opening a line of a non-carrier's quoted text, no case named" CP49 a
sv_arm "REACH-CASE-R1 (PC-1, declared): the same list marker where the prose names case and then in" CP50 B
sv_arm "REACH-COPROC-01: coproc" EN84 B rmkw2 a
sv_arm "REACH-COPROC-02: coproc NAME and a brace group" CP51 B rmcase a
sv_arm "REACH-COPROC-near: a simple command whose first word is a name" CP52 a
sv_arm "REACH-BRACE-01: a brace group" EN83 B rmkw2 a
sv_arm "REACH-BRACE-02: a brace group after &&" CP53 B rmkw2 a
sv_arm "REACH-BRACE-02b: a brace group after then" CP54 B rmkw2 a
sv_arm "REACH-BRACE-03: a brace group inside an enclosure, at the enclosure's phase" CP55 W:shell-enclosure
sv_arm "REACH-BRACE-near-1: brace expansion at command position (R-9)" CP56 a
sv_arm "REACH-BRACE-near-2: a quoted brace" CP57 a
sv_arm "REACH-BRACE-near-paren: the parenthesized group keeps its enclosure record" CP58 W:shell-enclosure
sv_arm "REACH-ctl-case: a case arm with the listed script" CP67 a
sv_arm "REACH-ctl-coproc: coproc with the listed script" CP68 a
sv_arm "REACH-ctl-brace: a brace group with the listed script" CP69 a

# ==========================================================================
# BLOCK-022 — an xargs-fed shell whose flag walk ends with no operand (XARGS-*)
# ==========================================================================
# The pre-walk half of the xargs stdin deny sees only "no token follows the interpreter". The
# post-walk half (M-XF-WALK) refuses an xargs-fed shell whose own flags leave no operand, no
# inline program and no parse-only grant, where every stepped token was option-shaped or an
# option's argument (Amendment 1); at an enclosure position the enclosure's closer and later
# words are not the shell's. A non-shell interpreter stays out (D-8492-NonShell N1, declared).
#   pxwalk  the post-walk half removed (its marked block)
/usr/bin/sed '/# >>> M-XF-WALK$/,/# <<< M-XF-WALK$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pxwalk.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-pxwalk.sh"
xf_n="$(/usr/bin/awk '/# >>> M-XF-WALK$/{s=NR} /# <<< M-XF-WALK$/{if (s) print NR - s + 1}' "$HOOK")"
aq_shape_arm "XARGS-M1: the post-walk mutant removes its marked block" block-destructive-pxwalk.sh "${xf_n:-MISSING}/0"
for xf_r in WR43 WR44 WR45 WR46 WR47 WR48 WR49 WR50 WR51 WR52 WR53 XF01 XF02; do
  sv_arm "XARGS-IFLAG-${xf_r}: an xargs-fed shell with flags of its own and no operand" "$xf_r" B pxwalk a
done
sv_arm "XARGS-CMODE-01: -c with no program string on argv" XF03 B pxwalk a
sv_arm "XARGS-ENCL-01: a spaced enclosure closer is not the shell's operand" XF04 W:shell-enclosure pxwalk a
sv_arm "XARGS-ENCL-02: an attached closer, and the enclosing command's later word, are not the shell's operand" XF05 W:shell-enclosure pxwalk a
sv_arm "XARGS-ENCL-03: the second view reads a shell that opens the enclosure" XF12 W:shell-enclosure pxwalk a
sv_arm "XARGS-near-01: a parse-only check" XF06 a
sv_arm "XARGS-near-02: an inline program string" XF07 a
sv_arm "XARGS-near-03: a non-shell module that only compiles" XF08 a
sv_arm "XARGS-POS-01: an extensionless script named on argv keeps today's verdict (Amendment 1)" XF09 a
sv_arm "XARGS-res-01: a non-shell interpreter with only its flags (N1, declared)" XF10 a
sv_arm "XARGS-ctl-01: the listed script on argv" XF11 a

# ==========================================================================
# The Stage 7 fix batch (#8319 D-8319-S7Fix, #8318 D-8318-S7Fix): HDOPEN-*, OPND-LIMIT-*, OPND-GAP-*, OPND-ADMIT-*
# ==========================================================================
# HDOPEN: the head walk marks a value open when its quote or escape is still open at the token's end, read with the
# rule's own scanner (an escaped quote is not a delimiter; an odd backslash run carries the value on), beside the quote
# count, which stays a disjunct so nothing it marked open is closed. The carrier answer at the fragment site is
# withdrawn when the walk read the head from inside an open value. OPND-LIMIT: a join that stopped at its read limit is
# unresolvable. OPND-GAP: a joined word whose pieces did not sit one space apart in the command is read inexact, so the
# allowlist never admits it under its one-space name. The corpus roots list one spaced path for OPND-ADMIT.
#   pheadscan  the escape-aware open read removed (its call line)
#   pheadopen  the fragment-site withdrawal on an open head removed
#   plimit     the read-limit refusal removed
#   pgap       the spacing check removed
/usr/bin/sed '/# M-HEAD-OPEN-SCAN$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pheadscan.sh"
/usr/bin/sed '/# M-WRAP-QVAL-HEADOPEN$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pheadopen.sh"
/usr/bin/sed '/# M-OPND-JOIN-LIMIT$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-plimit.sh"
/usr/bin/sed '/# M-OPND-JOIN-GAP$/d' "$HOOK" > "${AQ_HOOKS}/block-destructive-pgap.sh"
/bin/chmod +x "${AQ_HOOKS}/block-destructive-pheadscan.sh" "${AQ_HOOKS}/block-destructive-pheadopen.sh" "${AQ_HOOKS}/block-destructive-plimit.sh" "${AQ_HOOKS}/block-destructive-pgap.sh"
aq_shape_arm "HDOPEN-M1: the open-read mutant removes its call line" block-destructive-pheadscan.sh "1/0"
aq_shape_arm "HDOPEN-M2: the open-head withdrawal mutant removes its line" block-destructive-pheadopen.sh "1/0"
aq_shape_arm "OPND-LIMIT-M1: the read-limit mutant removes its refusal line" block-destructive-plimit.sh "1/0"
aq_shape_arm "OPND-GAP-M1: the spacing mutant removes its check line" block-destructive-pgap.sh "1/0"
sv_arm "HDOPEN-01: an escaped blank with no quote leaves the value open, so its carrier word is not the receiver (F-03)" AV51 B pheadscan a
sv_arm "HDOPEN-02: an escaped quote before the real opener leaves the value open (F-02)" AV52 B pheadscan a
sv_arm "HDOPEN-03: a declined value whose quote is still open withdraws the carrier answer at the fragment site (F-04)" AV53 B pheadopen a
sv_arm "HDOPEN-04: an escaped quote before the opener, at the fragment site, needs the open read (F-02)" AV54 B pheadscan a
sv_arm "HDOPEN-04b: the same row needs the fragment-site withdrawal (F-04)" AV54 B pheadopen a
sv_arm "HDOPEN-near-01: an even backslash run before a real carrier keeps the carrier's excision" AV55 a
sv_arm "HDOPEN-near-02: a lone escaped quote still reads open by the count, a kept over-block" AV56 B
sv_arm "OPND-LIMIT-01: a spaced quoted path past the join's read limit is unresolvable (F-12)" OP28 B plimit a
sv_arm "OPND-LIMIT-02: the same at four times the limit (F-12)" OP29 B plimit a
sv_arm "OPND-LIMIT-ctl: the unspaced long path is refused as before" OP30 B
sv_arm "OPND-ADMIT-01: a listed spaced path is admitted (the OPND-WS admit half)" OP31 a
sv_arm "OPND-ADMIT-02: the same behind --" OP32 a
sv_arm "OPND-GAP-01: the two-space spelling of a listed spaced path is not admitted as that name (F-15)" OP33 B pgap a
sv_arm "OPND-ADMIT-ctl: an unlisted spaced path is refused" OP35 B

/bin/rm -rf "$AQ_ROOT"

# --- #8493: the option-run latch's two error directions (release script-guard-refuses-only-what-executes;
# design on sub-task #9062, review on #9087). Part 1, the plain-character set swept on each shell; part 2,
# the conservative route's refusal names its cause, and its block-log row carries a cause tag.

# Part 1. The set is DERIVED from the hook's own `script_plain_word` pattern on every run, so a member
# added later is swept automatically. Each word is handed to a fresh child shell as an unquoted word in
# the child's PROGRAM TEXT (as argv nothing would be expanded), under a clean environment.
ls_pw="$(/usr/bin/awk '/^script_plain_word\(\)/ { f = 1 } f && index($0, "*[!") { s = $0; sub(/^[^[]*\[!/, "", s); sub(/\]\*\).*$/, "", s); print s; exit }' "$HOOK")"
ls_set="${ls_pw#A-Za-z0-9}"
if [ -n "$ls_pw" ] && [ "$ls_set" != "$ls_pw" ] && [ "$ls_set" = "_=+,.:/@%-" ]; then
  /usr/bin/printf 'PASS: LATCH-SWEEP-SET the plain set read from the hook is the recorded 10 members (%s)\n' "$ls_set"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: LATCH-SWEEP-SET the plain set read from the hook is [%s], not the recorded _=+,.:/@%%- — re-record the set, then re-sweep\n' "$ls_pw"
  FAIL=$((FAIL + 1))
fi
ls_pl="$(/usr/bin/awk 'index($0, "PL = \"ABCDEFGHIJ") { s = $0; sub(/^[^"]*"/, "", s); sub(/".*$/, "", s); print s; exit }' "$HOOK")"
ls_rd="$(/usr/bin/awk '/^script_qval_readable\(\)/ { f = 1 } f && index($0, "*[!") { s = $0; sub(/^[^[]*\[!/, "", s); sub(/\]\*\).*$/, "", s); print s; exit }' "$HOOK")"
ls_rd_plain="${ls_rd//\\\'/}"; ls_rd_plain="${ls_rd_plain//\\\"/}"
if [ "$ls_pl" = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789${ls_set} \\t" ] && [ "$ls_rd_plain" = "$ls_pw" ] && [ "$ls_rd" != "$ls_rd_plain" ]; then
  /usr/bin/printf 'PASS: LATCH-SWEEP-PARITY the trust boundary'"'"'s PL string and script_qval_readable'"'"'s set each equal the swept set plus exactly their declared extras\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: LATCH-SWEEP-PARITY a second spelling of the plain set differs from the swept one (PL=[%s] readable=[%s])\n' "$ls_pl" "$ls_rd"
  FAIL=$((FAIL + 1))
fi
LS_DIR="$(/usr/bin/mktemp -d)"
LS_HOME="${LS_DIR}/home"
/bin/mkdir -p "${LS_DIR}/cwd" "$LS_HOME"
/usr/bin/touch "${LS_DIR}/cwd/-xb" "${LS_DIR}/cwd/-xc"
ls_words() { # $1 = member set -> one word per line, the eight positions per member, deduplicated
  local set="$1" i c
  i=0
  while [ "$i" -lt "${#set}" ]; do
    c="${set:$i:1}"
    /usr/bin/printf '%s\n' "-a${c}" "-${c}a" "--rc${c}file" "+${c}n" "${c}abc" "a${c}${c}b" "-${c}" "${c}"
    i=$((i + 1))
  done | /usr/bin/awk '!seen[$0]++'
}
LS_CLASS=""
ls_child() { # $1 = shell  $2 = extra flag or ''  $3 = word -> LS_CLASS unchanged|split|rewritten|aborted
  local out rc=0 n
  out="$(cd "${LS_DIR}/cwd" && /usr/bin/env -i PATH=/usr/bin:/bin HOME="$LS_HOME" LC_ALL=C "$1" ${2:+"$2"} -c "printf '[%s]\\n' $3" 2>/dev/null)" || rc="$?"
  n="$(/usr/bin/printf '%s' "$out" | /usr/bin/awk 'END { print NR }')"
  if [ "$rc" -ne 0 ] || [ -z "$out" ]; then LS_CLASS="aborted"
  elif [ "$n" -gt 1 ]; then LS_CLASS="split"
  elif [ "$out" = "[$3]" ]; then LS_CLASS="unchanged"
  else LS_CLASS="rewritten"; fi
}
ls_limb() { # $1 label  $2 shell  $3 extra flag or ''  $4 1 when the zsh rule applies
  local label="$1" sh="$2" fl="$3" zr="$4" w un=0 rw=0 sp=0 ab=0 bad="" total=0 ctl_ok=1 ctlwhy="" isbash isz m1=0
  while IFS= read -r w; do
    total=$((total + 1))
    ls_child "$sh" "$fl" "$w"
    case "$LS_CLASS" in unchanged) un=$((un + 1)) ;; split) sp=$((sp + 1)) ;; rewritten) rw=$((rw + 1)) ;; aborted) ab=$((ab + 1)) ;; esac
    if [ "$LS_CLASS" != "unchanged" ]; then
      if [ "$zr" = 1 ] && [ "${w:0:1}" = "=" ] && [ "$LS_CLASS" != "split" ]; then :; else bad="${bad} ${w}(${LS_CLASS})"; fi
    fi
  done < <({ ls_words "$ls_set"; ls_words "a"; } | /usr/bin/awk '!seen[$0]++')
  /usr/bin/printf 'RESIDUAL: %s population: %s · members %s (%s) · positions 8 · words %s · unchanged %s · rewritten %s · split %s · aborted %s\n' "$label" "$sh" "${#ls_set}" "$ls_set" "$total" "$un" "$rw" "$sp" "$ab"
  if [ -z "$bad" ]; then
    /usr/bin/printf 'PASS: %s every plain-set word comes back as one unchanged word (%s words)\n' "$label" "$total"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s words not unchanged:%s — a member that fails is re-filed at P1 and the slice stops (plan R13)\n' "$label" "$bad"; FAIL=$((FAIL + 1))
  fi
  ls_child "$sh" "$fl" '-x?'; [ "$LS_CLASS" = "split" ] || { ctl_ok=0; ctlwhy="${ctlwhy} glob=${LS_CLASS}"; }
  ls_child "$sh" "$fl" '~'; [ "$LS_CLASS" = "rewritten" ] || { ctl_ok=0; ctlwhy="${ctlwhy} tilde=${LS_CLASS}"; }
  isbash="$(/usr/bin/env -i PATH=/usr/bin:/bin "$sh" ${fl:+"$fl"} -c 'printf %s "${BASH_VERSION:-}${ZSH_VERSION:-}"' 2>/dev/null)"
  if [ -n "$isbash" ]; then ls_child "$sh" "$fl" '-x{b,c}'; [ "$LS_CLASS" = "split" ] || { ctl_ok=0; ctlwhy="${ctlwhy} brace=${LS_CLASS}"; }; fi
  /usr/bin/printf 'RESIDUAL: %s controls: glob splits, tilde rewritten, brace %s, 7 control words in the sweep above\n' "$label" "$([ -n "$isbash" ] && echo splits || echo not-applicable)"
  if [ "$ctl_ok" = 1 ]; then /usr/bin/printf 'PASS: LATCH-SWEEP-CTL-%s the splitting and rewriting controls fire\n' "${label#LATCH-SWEEP-}"; PASS=$((PASS + 1))
  else /usr/bin/printf 'FAIL: LATCH-SWEEP-CTL-%s a control did not fire:%s — the sweep cannot see a member that misbehaves\n' "${label#LATCH-SWEEP-}" "$ctlwhy"; FAIL=$((FAIL + 1)); fi
  while IFS= read -r w; do ls_child "$sh" "$fl" "$w"; [ "$LS_CLASS" = "unchanged" ] || m1=$((m1 + 1)); done < <(ls_words '~')
  if [ "$m1" -ge 1 ]; then /usr/bin/printf 'PASS: LATCH-SWEEP-M1-%s a wrongly included member (~) is caught (%s words not unchanged)\n' "${label#LATCH-SWEEP-}" "$m1"; PASS=$((PASS + 1))
  else /usr/bin/printf 'FAIL: LATCH-SWEEP-M1-%s the sweep did not catch a wrongly included member\n' "${label#LATCH-SWEEP-}"; FAIL=$((FAIL + 1)); fi
}
ls_limb LATCH-SWEEP-bash /bin/bash "" 0
ls_limb LATCH-SWEEP-sh /bin/sh "" 0
ls_dash=""
for ls_c in /bin/dash /usr/bin/dash; do [ -x "$ls_c" ] && { ls_dash="$ls_c"; break; }; done
if [ -n "$ls_dash" ]; then ls_limb LATCH-SWEEP-dash "$ls_dash" "" 0
else /usr/bin/printf 'RESIDUAL: LATCH-SWEEP-dash absent on this host: sh was measured only as the binary /bin/sh resolves to\n'; fi
if [ -x /bin/zsh ]; then ls_limb LATCH-SWEEP-zsh /bin/zsh -f 1
else /usr/bin/printf 'RESIDUAL: LATCH-SWEEP-zsh absent on this host\n'; fi
/bin/rm -rf "$LS_DIR"

# --- #8493 Part 2: the conservative route's refusal names its cause (LATCH-CAUSE-*) ---
# Three gates hand a segment to the route a bare -c takes: an unreadable word ahead of the
# operand (opaque), a command-string cluster other than a bare -c (cluster), and an option
# argument whose text the walk does not hold (opaque-arg). A refusal the route's own loop
# issues appends "Read on the conservative route (<gate>): ..." to its reason; the Override
# line is unchanged. That refusal's block-log row gains one key, features {schema_version: 1,
# route, subject} (ADR-205's forward-compatible shape); every other row keeps exactly the six
# base keys in their order. Payloads are corpus rows read by id, under a hermetic root of
# their own; the block log is cleared before each call, so the record read is that call's.
LC_ROOT="$(/usr/bin/mktemp -d)"
LC_HOOKS="${LC_ROOT}/.claude/hooks"
/bin/mkdir -p "${LC_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${LC_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${LC_HOOKS}/lib/" 2>/dev/null || true
/usr/bin/printf '%s\n' "${WC_D}/ok.sh" "${WC_D}/ok.py" "${WC_D}/li sted/ok.sh" > "${LC_ROOT}/.claude/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${LC_HOOKS}/.mode"
/bin/cp "$HOOK" "${LC_HOOKS}/block-destructive.sh"
/usr/bin/sed 's/^readonly DESTRUCTIVE_022_INTERP_PHASE=.*/readonly DESTRUCTIVE_022_INTERP_PHASE="enforce"   # shadow | warn | enforce/' \
  "$HOOK" > "${LC_HOOKS}/block-destructive-ienf.sh"
/usr/bin/sed -e '/# M-OPAQUE (mutation/d' -e '/# M-CLUSTER/d' -e '/# M-OPAQUE-ARG/d' \
  "$HOOK" > "${LC_HOOKS}/block-destructive-gateoff.sh"
/usr/bin/grep -vF -- '# M-ROUTE-TAG (mutation' "$HOOK" > "${LC_HOOKS}/block-destructive-m1a.sh"
/usr/bin/grep -vF -- '# M-ROUTE-TAG-ARG (mutation' "$HOOK" > "${LC_HOOKS}/block-destructive-m1b.sh"
/usr/bin/grep -vF -- '# M-ROUTE-NOTE (mutation' "$HOOK" > "${LC_HOOKS}/block-destructive-m2a.sh"
/usr/bin/grep -vF -- '# M-ROUTE-LIVE (mutation' "$HOOK" > "${LC_HOOKS}/block-destructive-m3a.sh"
# Stage 7: the bare -c clear (m1c), the refusal marker (m5), a block-log writer that fails (logfail),
# and the live test removed from both readers of the route (m6).
/usr/bin/grep -vF -- '# M-ROUTE-CLEAR-ARG (mutation' "$HOOK" > "${LC_HOOKS}/block-destructive-m1c.sh"
/usr/bin/grep -vF -- '# M-ROUTE-MARK' "$HOOK" > "${LC_HOOKS}/block-destructive-m5.sh"
/usr/bin/awk '/^log_block\(\) \{$/ { print; print "  return 1"; next } { print }' "$HOOK" > "${LC_HOOKS}/block-destructive-logfail.sh"
/usr/bin/sed -e 's/if \$live == "1" and /if /' -e 's/if \[ "\${script_route_live:-0}" != 1 \] || \[ -z "\${script_route:-}" \]; then return 0; fi/if [ -z "${script_route:-}" ]; then return 0; fi/' \
  "$HOOK" > "${LC_HOOKS}/block-destructive-m6.sh"
/bin/chmod +x "${LC_HOOKS}/"block-destructive*.sh
LC_LOG="${LC_HOOKS}/block-log.jsonl"
LC_DRAIN="${LC_HOOKS}/destructive-warn-log.jsonl"
lc_gone() { # $1 = copy -> how many lines the copy lacks against the shipped hook
  local a b
  a="$(/usr/bin/wc -l < "$HOOK" | /usr/bin/tr -d '[:space:]')"
  b="$(/usr/bin/wc -l < "${LC_HOOKS}/$1" | /usr/bin/tr -d '[:space:]')"
  /usr/bin/printf '%s' "$((a - b))"
}
LC_EXIT=0; LC_ERR=""; LC_REC=""
lc_run() { # $1 = copy  $2 = command -> LC_EXIT, LC_ERR, LC_REC (this call's block-log record, or empty)
  local tmp
  tmp="$(/usr/bin/mktemp)"
  /bin/rm -f "$LC_LOG"
  LC_EXIT=0
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT
    /usr/bin/printf '%s' "$(bash_payload "$2" "$LC_ROOT")" | /bin/bash "${LC_HOOKS}/$1" >/dev/null 2>"$tmp" ) || LC_EXIT="$?"
  LC_ERR="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  LC_REC=""
  if [ -s "$LC_LOG" ]; then LC_REC="$(/usr/bin/jq -s -c '.[-1]' "$LC_LOG" 2>/dev/null)"; fi
}
lc_route() { # -> the features.route of LC_REC, or empty
  if [ -n "$LC_REC" ]; then /usr/bin/jq -r '.features.route // ""' <<<"$LC_REC" 2>/dev/null; fi
}
lc_report() { # $1 = label  $2 = observed reasons (empty = pass)
  if [ -z "$2" ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s\n  observed:%s\n  stderr: %s\n' "$1" "$2" "$LC_ERR"; FAIL=$((FAIL + 1))
  fi
}
# lc_arm <label> <row id | -> <copy> <exit> <note gate | -> <token named | -> <features.route | -> <subject | any | -> [<command when row is ->]
lc_arm() {
  local name="$1" row="$2" copy="$3" want="$4" gate="$5" tok="$6" route="$7" subj="$8" cmd="${9:-}" why="" got gv gs keys last
  if [ "$row" != "-" ]; then
    if ! wc_row_cmd "$row"; then
      /usr/bin/printf 'FAIL: %s\n  row %s is not a block-destructive row of the corpus\n' "$name" "$row"; FAIL=$((FAIL + 1)); return 0
    fi
    cmd="$WC_CMDX"; name="${name} [row ${row}]"
  fi
  lc_run "$copy" "$cmd"
  [ "$LC_EXIT" = "$want" ] || why="${why} exit=${LC_EXIT}"
  if [ "$gate" = "-" ]; then
    case "$LC_ERR" in *"Read on the conservative route"*) why="${why} unexpected-note" ;; esac
  else
    case "$LC_ERR" in *"Read on the conservative route (${gate}): "*) ;; *) why="${why} no-(${gate})-note" ;; esac
    if [ "$tok" != "-" ]; then
      case "$LC_ERR" in *"(${gate}): "*"'${tok}'"*) ;; *) why="${why} note-does-not-name-${tok}" ;; esac
    fi
  fi
  if [ "$want" = 2 ]; then
    if [ -z "$LC_REC" ]; then
      why="${why} no-block-log-record"
    else
      keys="$(/usr/bin/jq -r '[keys_unsorted[] | select(. != "features")] | join(",")' <<<"$LC_REC" 2>/dev/null)"
      [ "$keys" = "ts,hook,rule,tool,input_digest,cwd" ] || why="${why} base-keys=${keys}"
      got="$(/usr/bin/jq -r 'if has("features") then (.features.route // "<no-route>") else "" end' <<<"$LC_REC" 2>/dev/null)"
      if [ "$route" = "-" ]; then
        [ -z "$got" ] || why="${why} features.route=${got}(wanted-none)"
      else
        [ "$got" = "$route" ] || why="${why} features.route=${got:-absent}(wanted-${route})"
        if [ -n "$got" ]; then
          gv="$(/usr/bin/jq -r '.features.schema_version // ""' <<<"$LC_REC" 2>/dev/null)"
          [ "$gv" = "1" ] || why="${why} schema_version=${gv:-absent}"
          gs="$(/usr/bin/jq -r '.features.subject // ""' <<<"$LC_REC" 2>/dev/null)"
          case "$subj" in
            any) case "$gs" in first|later) ;; *) why="${why} subject=${gs:-absent}" ;; esac ;;
            *) [ "$gs" = "$subj" ] || why="${why} subject=${gs:-absent}(wanted-${subj})" ;;
          esac
          last="$(/usr/bin/jq -r '[keys_unsorted[]] | last' <<<"$LC_REC" 2>/dev/null)"
          [ "$last" = "features" ] || why="${why} features-not-last"
          [ "$(/usr/bin/jq -r '.rule' <<<"$LC_REC" 2>/dev/null)" = "BLOCK-DESTRUCTIVE-022" ] || why="${why} tagged-row-not-022"
        fi
      fi
    fi
  else
    [ -z "$LC_REC" ] || why="${why} unexpected-block-log-record"
  fi
  lc_report "$name" "$why"
}

# The three gates, each named with the token that sent the segment to the route.
lc_arm "LATCH-CAUSE-opaque: an unreadable option word ahead of the script is named as the route's cause" ZU34 block-destructive.sh 2 opaque '-x$X' opaque later
lc_arm "LATCH-CAUSE-opaque-word: an unreadable word that is not an option (a redirection) is named, not an option" ZH05 block-destructive.sh 2 opaque '2>/dev/null' opaque later
lc_arm "LATCH-CAUSE-cluster: a command-string option cluster is named as the route's cause" ZC33 block-destructive.sh 2 cluster '-ec' cluster any
lc_arm "LATCH-CAUSE-optarg: an option argument whose text the walk does not hold is named as the route's cause" ZH19 block-destructive.sh 2 opaque-arg 'pipe"fail"' opaque-arg later

# The controls: every refusal outside the route keeps the plain row and the plain reason.
lc_arm "LATCH-CAUSE-ctl-plain: the same unlisted script refused off the route keeps the six keys and no note" - block-destructive.sh 2 - - - - "bash $HINT_UNLISTED"
lc_arm "LATCH-CAUSE-ctl-dashc: a bare -c program running an unlisted script is a real command string, untagged" T18 block-destructive.sh 2 - - - -
lc_arm "LATCH-CAUSE-ctl-allow: the route taken over only an allowlisted script writes no record" ZU05 block-destructive.sh 0 - - - -
lc_arm "LATCH-CAUSE-ctl-stepover: the route token's own word refused is untagged" X12 block-destructive.sh 2 - - - -
lc_arm "LATCH-CAUSE-ctl-rule: another rule's refusal keeps exactly the six base keys" - block-destructive.sh 2 - - - - 'git push --force origin main'
if wc_row_cmd ZU34; then
  lc_run block-destructive.sh "$WC_CMDX"
  lc_why=""
  [ "$LC_EXIT" = 2 ] || lc_why="${lc_why} exit=${LC_EXIT}"
  /usr/bin/grep -qE "$HINT_ORDER" <<<"$LC_ERR" || lc_why="${lc_why} override-order-changed"
  lc_report "LATCH-CAUSE-ctl-hint: the route refusal's Override line keeps its order [row ZU34]" "$lc_why"
else
  lc_report "LATCH-CAUSE-ctl-hint: the route refusal's Override line keeps its order" " row ZU34 absent"
fi
# A non-shell interpreter on the route: at the shipped warn phase it is recorded, never refused,
# and the drain row it writes is unchanged; at enforce the router delegates and the tag follows.
if wc_row_cmd ZH16; then
  lc_d0=0; [ -f "$LC_DRAIN" ] && lc_d0="$(/usr/bin/wc -l < "$LC_DRAIN" | /usr/bin/tr -d '[:space:]')"
  lc_run block-destructive.sh "$WC_CMDX"
  lc_why=""
  [ "$LC_EXIT" = 0 ] || lc_why="${lc_why} exit=${LC_EXIT}"
  [ -z "$LC_REC" ] || lc_why="${lc_why} unexpected-block-log-record"
  lc_d1=0; [ -f "$LC_DRAIN" ] && lc_d1="$(/usr/bin/wc -l < "$LC_DRAIN" | /usr/bin/tr -d '[:space:]')"
  if [ "$lc_d1" -gt "$lc_d0" ]; then
    /usr/bin/tail -n 1 "$LC_DRAIN" | /usr/bin/jq -e 'has("features") | not' >/dev/null 2>&1 || lc_why="${lc_why} drain-row-gained-features"
  else
    lc_why="${lc_why} no-drain-row"
  fi
  lc_report "LATCH-CAUSE-ctl-warn: a non-shell interpreter on the route at the shipped warn phase writes a plain drain row and no block-log record [row ZH16]" "$lc_why"
else
  lc_report "LATCH-CAUSE-ctl-warn: a non-shell interpreter on the route at the shipped warn phase" " row ZH16 absent"
fi
if /usr/bin/grep -qF 'readonly DESTRUCTIVE_022_INTERP_PHASE="enforce"' "${LC_HOOKS}/block-destructive-ienf.sh"; then
  lc_arm "LATCH-CAUSE-enf: the same at enforce is refused with its cause and tag (router delegation)" ZH16 block-destructive-ienf.sh 2 opaque '-u""' opaque first
else
  lc_report "LATCH-CAUSE-enf: the same at enforce is refused with its cause and tag" " the interpreter-phase copy is not at enforce"
fi

# The latch's own corpus rows: every refusal in its groups, through the shipped hook and through a
# copy with the three gate lines deleted (the suite's own seds). Ground truth for these rows was
# taken with marker scripts (seed 5); o and - are refusals that ran nothing unlisted.
lc_cn=0; lc_ct=0; lc_co=0; lc_cc=0; lc_ca=0; lc_cok=0; lc_cbad=""; lc_m0t=0; lc_rg=""
lc_i=0
while [ "$lc_i" -lt "$wc_n" ]; do
  case "${WC_GROUP[$lc_i]}" in
    term-unread|term-run|term-run2|cluster|cluster-edge|optarg|unread-word)
      if [ "${WC_REC[$lc_i]}" = "B" ]; then
        wc_expand "${WC_CMD[$lc_i]}"
        lc_cn=$((lc_cn + 1))
        lc_run block-destructive.sh "$WC_CMDX"
        lc_r="$(lc_route)"
        case "$lc_r" in
          "") ;;
          opaque) lc_co=$((lc_co + 1)) ;;
          cluster) lc_cc=$((lc_cc + 1)) ;;
          opaque-arg) lc_ca=$((lc_ca + 1)) ;;
          *) lc_cbad="${lc_cbad} ${WC_ID[$lc_i]}=${lc_r}" ;;
        esac
        if [ -n "$lc_r" ]; then
          lc_ct=$((lc_ct + 1))
          lc_rg="${lc_rg}${lc_r}/${WC_GT[$lc_i]}"$'\n'
          case "${WC_GT[$lc_i]}" in o|-) lc_cok=$((lc_cok + 1)) ;; esac
        fi
        lc_run block-destructive-gateoff.sh "$WC_CMDX"
        if [ -n "$(lc_route)" ]; then lc_m0t=$((lc_m0t + 1)); fi
      fi ;;
  esac
  lc_i=$((lc_i + 1))
done
lc_rgs="$(/usr/bin/printf '%s' "$lc_rg" | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/awk '{printf "%s%s=%s", (NR > 1 ? " " : ""), $2, $1}')"
/usr/bin/printf 'RESIDUAL: LATCH-CAUSE-CORPUS latch-group refusals=%s route-tagged=%s (opaque=%s cluster=%s opaque-arg=%s); by route/ground-truth: %s; tagged that ran nothing unlisted (ground truth o or -)=%s of %s\n' \
  "$lc_cn" "$lc_ct" "$lc_co" "$lc_cc" "$lc_ca" "${lc_rgs:-none}" "$lc_cok" "$lc_ct"
lc_why=""
[ "$lc_cn" -gt 0 ] || lc_why="${lc_why} no-latch-group-refusals-read"
[ -z "$lc_cbad" ] || lc_why="${lc_why} unknown-route-values:${lc_cbad}"
[ "$lc_co" -ge 1 ] || lc_why="${lc_why} opaque=0"
[ "$lc_cc" -ge 1 ] || lc_why="${lc_why} cluster=0"
[ "$lc_ca" -ge 1 ] || lc_why="${lc_why} opaque-arg=0"
LC_ERR=""
lc_report "LATCH-CAUSE-CORPUS: the latch's refusals carry only the three route values, each at least once (${lc_ct} of ${lc_cn} tagged)" "$lc_why"
lc_why=""
lc_g="$(lc_gone block-destructive-gateoff.sh)"
[ "$lc_g" = 3 ] || lc_why="${lc_why} gate-off-copy-lacks-${lc_g}-lines(wanted-3)"
[ "$lc_m0t" = 0 ] || lc_why="${lc_why} tagged=${lc_m0t}"
lc_report "LATCH-CAUSE-M0: with the three gate lines deleted, none of the ${lc_cn} latch-group refusals is tagged" "$lc_why"

# The mutants: each marker line deleted alone (exactly one line gone), the matching core arm reads
# untagged or note-less. A marker that does not exist yet leaves no mutant to show live.
lc_mut_arm() { # <label> <copy> <row> <untagged | note-less | both>
  local name="$1" copy="$2" row="$3" want="$4" g why="" got
  g="$(lc_gone "$copy")"
  if [ "$g" != 1 ]; then
    LC_ERR=""; lc_report "$name" " the mutant is not live (${g} lines gone, wanted exactly 1: its marker is absent)"; return 0
  fi
  if ! wc_row_cmd "$row"; then LC_ERR=""; lc_report "$name" " row ${row} absent"; return 0; fi
  lc_run "$copy" "$WC_CMDX"
  [ "$LC_EXIT" = 2 ] || why="${why} exit=${LC_EXIT}"
  got="$(lc_route)"
  case "$want" in untagged|both) [ -z "$got" ] || why="${why} still-tagged=${got}" ;; esac
  case "$want" in note-less|both)
    case "$LC_ERR" in *"Read on the conservative route"*) why="${why} note-still-present" ;; esac ;;
  esac
  lc_report "${name} [row ${row}]" "$why"
}
lc_mut_arm "LATCH-CAUSE-M1a: without M-ROUTE-TAG the gate's refusal is untagged" block-destructive-m1a.sh ZU34 untagged
lc_mut_arm "LATCH-CAUSE-M1b: without M-ROUTE-TAG-ARG the option argument's refusal is untagged" block-destructive-m1b.sh ZH19 untagged
lc_mut_arm "LATCH-CAUSE-M2a: without M-ROUTE-NOTE the route's refusal carries no note" block-destructive-m2a.sh ZU34 note-less
lc_mut_arm "LATCH-CAUSE-M3a: without M-ROUTE-LIVE the route's refusal is neither tagged nor noted" block-destructive-m3a.sh ZU34 both

# --- Stage 7 (#9072): the review's carried adjustments FM-3, FM-4, FM-6 and CD-2, and the reader guard (F-06) ---
# lc_copy_arm <label> <copy> <shape removed/added> <row id | -> <untagged | tagged:<route>> [<command when row is ->]
# The copy must differ from the hook by exactly that shape; then the call must refuse, and the row must carry
# no route tag, or carry that route with its note.
lc_copy_arm() {
  local name="$1" copy="$2" shape="$3" row="$4" want="$5" cmd="${6:-}" why="" got
  got="$(/usr/bin/diff "$HOOK" "${LC_HOOKS}/$copy" | /usr/bin/awk 'index($0, "<") == 1 { r++ } index($0, ">") == 1 { a++ } END { printf "%d/%d", r, a }')"
  if [ "$got" != "$shape" ]; then LC_ERR=""; lc_report "$name" " the copy is not live (shape ${got}, wanted ${shape})"; return 0; fi
  if [ "$row" != "-" ]; then
    if ! wc_row_cmd "$row"; then LC_ERR=""; lc_report "$name" " row ${row} absent"; return 0; fi
    cmd="$WC_CMDX"; name="${name} [row ${row}]"
  fi
  lc_run "$copy" "$cmd"
  [ "$LC_EXIT" = 2 ] || why="${why} exit=${LC_EXIT}"
  case "$want" in
    untagged) [ -z "$(lc_route)" ] || why="${why} still-tagged=$(lc_route)" ;;
    tagged:*)
      [ "$(lc_route)" = "${want#tagged:}" ] || why="${why} features.route=$(lc_route)(wanted-${want#tagged:})"
      case "$LC_ERR" in *"Read on the conservative route (${want#tagged:}): "*) ;; *) why="${why} no-${want#tagged:}-note" ;; esac ;;
  esac
  lc_report "$name" "$why"
}
# FM-3: the opaque note's remedy fits its token. A redirection or here-string word has no plain spelling, so
# its note gives the move that works; an option word keeps the plain-spelling remedy.
lc_why=""
if wc_row_cmd ZH05; then
  lc_run block-destructive.sh "$WC_CMDX"
  case "$LC_ERR" in *"(opaque): "*"has no plain spelling"*"after the script and its arguments"*) ;; *) lc_why="${lc_why} ZH05-lacks-the-redirection-remedy" ;; esac
  case "$LC_ERR" in *"in plain characters"*) lc_why="${lc_why} ZH05-offers-the-plain-spelling" ;; esac
else
  lc_why="${lc_why} row-ZH05-absent"
fi
if wc_row_cmd ZU34; then
  lc_run block-destructive.sh "$WC_CMDX"
  case "$LC_ERR" in *"(opaque): "*"in plain characters"*) ;; *) lc_why="${lc_why} ZU34-lacks-the-plain-spelling-remedy" ;; esac
  case "$LC_ERR" in *"has no plain spelling"*) lc_why="${lc_why} ZU34-offers-the-redirection-remedy" ;; esac
else
  lc_why="${lc_why} row-ZU34-absent"
fi
lc_report "LATCH-CAUSE-opaque-remedy: the opaque note gives a redirection word the move that works and an option word its plain spelling [rows ZH05, ZU34]" "$lc_why"
# FM-4: a bare -c after an option argument the walk cannot read is a real command string. Its refusals are
# untagged; without the clear they carry the option argument's tag. The verdict is the same either way.
lc_dashc="bash -o pipe\"fail\" -c 'bash ${WC_D}/na.sh'"
lc_arm "LATCH-CAUSE-ctl-optarg-dashc: a bare -c program after an unreadable option argument is a real command string, untagged" - block-destructive.sh 2 - - - - "$lc_dashc"
lc_copy_arm "LATCH-CAUSE-M1c: without M-ROUTE-CLEAR-ARG that refusal keeps the option argument's tag" block-destructive-m1c.sh 1/0 - tagged:opaque-arg "$lc_dashc"
# FM-6: the deny path cannot lose a refusal. A copy whose block-log writer returns non-zero still refuses,
# on another rule's refusal and on this rule's; block() guards the writer and the note helper ends return 0.
lc_why=""
lc_g="$(/usr/bin/diff "$HOOK" "${LC_HOOKS}/block-destructive-logfail.sh" | /usr/bin/grep -c '^>')"
[ "$lc_g" = 1 ] || lc_why="${lc_why} the-failing-writer-copy-adds-${lc_g}-lines(wanted-1)"
for lc_c in "git push --force origin main" "bash $HINT_UNLISTED"; do
  lc_run block-destructive-logfail.sh "$lc_c"
  [ "$LC_EXIT" = 2 ] || lc_why="${lc_why} [${lc_c%% *}]exit=${LC_EXIT}"
done
lc_report "LATCH-CAUSE-M4-logfail: with a block-log writer that returns non-zero, a refusal still exits 2" "$lc_why"
lc_why=""
/usr/bin/grep -qF 'log_block "$rule_id" || true' "$HOOK" || lc_why="${lc_why} block-does-not-guard-the-writer"
lc_last="$(/usr/bin/awk '/^script_route_note\(\) / { f = 1 } f && /^\}/ { print p; exit } f && NF { p = $0 }' "$HOOK" | /usr/bin/sed 's/^[[:space:]]*//')"
[ "$lc_last" = "return 0" ] || lc_why="${lc_why} the-note-helper-ends-with:${lc_last}"
lc_report "LATCH-CAUSE-STRUCT-deny: block() guards the block-log writer and the note helper ends with return 0" "$lc_why"
# CD-2: the tag is keyed on a marker check_script_target sets before each of its three refusals, as well as
# on the loop's flag. Without the marker the route's refusal is untagged.
lc_copy_arm "LATCH-CAUSE-M5: without the refusal marker the route's refusal is untagged" block-destructive-m5.sh 3/0 ZU34 untagged
# F-06: a refusal outside the route's loop while the route is already recorded. An option argument the walk
# cannot read, carrying a script suffix, is refused on its own value before the loop runs: plain row, no note.
# With the live test removed from both readers, the same refusal is tagged and noted.
lc_own="bash --rcfile \$X.sh ${WC_D}/ok.sh"
lc_arm "LATCH-CAUSE-ctl-optarg-own: an unreadable option argument carrying a script suffix, refused on its own value before the loop, keeps the six keys and no note" - block-destructive.sh 2 - - - - "$lc_own"
lc_copy_arm "LATCH-CAUSE-M6: with the live test removed from both readers that refusal is tagged and noted" block-destructive-m6.sh 2/2 - tagged:opaque-arg "$lc_own"
/bin/rm -rf "$LC_ROOT"

# --- #8327: the rule's work ceiling (CEIL-*) ---
# A command hook that outlasts the runtime's timeout does not block, so the rule bounds its own
# time. At the head of every bash loop on its surface it compares bash's SECONDS with a deadline
# fixed at hook start (SCRIPT_CEIL_SECONDS), and at -022 entry it compares the command's length
# with SCRIPT_CEIL_CHARS, because one expansion between two checks cannot be interrupted. Past
# either the command is refused, whatever the arms' phases; the refusal's block-log row carries
# features {schema_version: 1, ceiling: <cause>}. Copies are built from the hook under test:
#   t0 / t2   the deadline at 0 / 2 seconds          off    the ceiling and the gate off
#   trace     each check also appends its tag        site   only the route loop's check refuses
#   strip     every # M-CEIL- line deleted (no ceiling at all, for the cost control)
#   sens      the check sleeps 50 ms per call (the cost control's sensitivity)
#   v-*       an enclosure-reaching phase at enforce with the view's small-budget edits
# No arm prints a size beside a time: each prints a ratio to its budget, as the lin_* arms do.
CEIL_LIMIT="${CEIL_LIMIT_DS:-200}"   # tenths: the watchdog a refusal must beat
CEIL_CTL="${CEIL_CTL_DS:-100}"       # tenths: the watchdog the ceiling-off limb must outlast
CE_ROOT="$(/usr/bin/mktemp -d)"
CE_HOOKS="${CE_ROOT}/.claude/hooks"
/bin/mkdir -p "${CE_HOOKS}/lib"
/bin/cp "${HOOK%/*}/lib/"*.sh  "${CE_HOOKS}/lib/" 2>/dev/null || true
/bin/cp "${HOOK%/*}/lib/"*.awk "${CE_HOOKS}/lib/" 2>/dev/null || true
/usr/bin/printf '%s\n' "${WC_D}/ok.sh" "${WC_D}/ok.py" > "${CE_ROOT}/.claude/script-execution-allowlist.txt"
/usr/bin/printf 'enforce' > "${CE_HOOKS}/.mode"
CE_TRACE="${CE_ROOT}/trace"
CE_LOG="${CE_HOOKS}/block-log.jsonl"
CE_DRAIN="${CE_HOOKS}/destructive-warn-log.jsonl"
/bin/cp "$HOOK" "${CE_HOOKS}/block-destructive.sh"
/usr/bin/sed 's/^readonly SCRIPT_CEIL_SECONDS=[0-9]*$/readonly SCRIPT_CEIL_SECONDS=0/' "$HOOK" > "${CE_HOOKS}/block-destructive-t0.sh"
/usr/bin/sed 's/^readonly SCRIPT_CEIL_SECONDS=[0-9]*$/readonly SCRIPT_CEIL_SECONDS=2/' "$HOOK" > "${CE_HOOKS}/block-destructive-t2.sh"
/usr/bin/sed -e 's/^readonly SCRIPT_CEIL_SECONDS=[0-9]*$/readonly SCRIPT_CEIL_SECONDS=1000000/' \
  -e 's/^readonly SCRIPT_CEIL_CHARS=[0-9]*$/readonly SCRIPT_CEIL_CHARS=1000000000/' "$HOOK" > "${CE_HOOKS}/block-destructive-off.sh"
F="$CE_TRACE" /usr/bin/awk 'BEGIN { f = ENVIRON["F"] } / # M-CEIL-TEST$/ { print "  /usr/bin/printf \"%s\\n\" \"$1\" >> \"" f "\"" } { print }' \
  "$HOOK" > "${CE_HOOKS}/block-destructive-trace.sh"
/usr/bin/awk '/ # M-CEIL-TEST$/ { print "  if [ \"$1\" = route ]; then script_ceil_refuse time \"$1\"; fi" } { print }' \
  "$HOOK" > "${CE_HOOKS}/block-destructive-site.sh"
/usr/bin/grep -v -- '# M-CEIL-' "$HOOK" > "${CE_HOOKS}/block-destructive-strip.sh"
/usr/bin/awk '/ # M-CEIL-TEST$/ { print "  /bin/sleep 0.05" } { print }' "$HOOK" > "${CE_HOOKS}/block-destructive-sens.sh"
/usr/bin/sed -e 's/^readonly DESTRUCTIVE_022_ENCL_PHASE=.*/readonly DESTRUCTIVE_022_ENCL_PHASE="enforce"   # shadow | warn | enforce/' \
  -e 's/^readonly SCRIPT_ENCL_POS_MAX=512$/readonly SCRIPT_ENCL_POS_MAX=4/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-pos.sh"
/usr/bin/sed -e 's/^readonly DESTRUCTIVE_022_ENCL_PHASE=.*/readonly DESTRUCTIVE_022_ENCL_PHASE="enforce"   # shadow | warn | enforce/' \
  -e 's/^readonly SCRIPT_ENCL_TAIL_BYTES=262144$/readonly SCRIPT_ENCL_TAIL_BYTES=64/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-rem.sh"
/usr/bin/sed -e 's/^readonly DESTRUCTIVE_022_EXEC_PHASE=.*/readonly DESTRUCTIVE_022_EXEC_PHASE="enforce"   # shadow | warn | enforce/' \
  -e 's/^readonly SCRIPT_ENCL_POS_MAX=512$/readonly SCRIPT_ENCL_POS_MAX=4/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-exec.sh"
/usr/bin/sed 's/^readonly SCRIPT_ENCL_POS_MAX=512$/readonly SCRIPT_ENCL_POS_MAX=4/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-warn.sh"
/usr/bin/sed -e 's/^readonly DESTRUCTIVE_022_EXEC_PHASE=.*/readonly DESTRUCTIVE_022_EXEC_PHASE="enforce"   # shadow | warn | enforce/' \
  -e 's/^readonly SCRIPT_ENCL_TAIL_BYTES=262144$/readonly SCRIPT_ENCL_TAIL_BYTES=64/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-exec-rem.sh"
/usr/bin/sed -e 's/^readonly DESTRUCTIVE_022_INTERP_PHASE=.*/readonly DESTRUCTIVE_022_INTERP_PHASE="enforce"   # shadow | warn | enforce/' \
  -e 's/^readonly SCRIPT_ENCL_POS_MAX=512$/readonly SCRIPT_ENCL_POS_MAX=4/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-int.sh"
/usr/bin/sed -e 's/^readonly DESTRUCTIVE_022_INTERP_PHASE=.*/readonly DESTRUCTIVE_022_INTERP_PHASE="enforce"   # shadow | warn | enforce/' \
  -e 's/^readonly SCRIPT_ENCL_TAIL_BYTES=262144$/readonly SCRIPT_ENCL_TAIL_BYTES=64/' "$HOOK" > "${CE_HOOKS}/block-destructive-v-int-rem.sh"
/bin/chmod +x "${CE_HOOKS}/"block-destructive*.sh
# ce_live <copy> <lines that must differ> — 0 when the copy differs from the hook by exactly that many lines.
ce_live() {
  local d
  d="$(/usr/bin/diff "$HOOK" "${CE_HOOKS}/$1" | /usr/bin/grep -c '^[<>]')"
  [ "$d" = "$2" ]
}
# ce_timed <copy> <locale> <command-file> <limit> — the copy on the command's payload under a watchdog;
# sets CE_DS (tenths elapsed, -1 when stopped), CE_EXIT, CE_ERR and CE_REC (the call's block-log record).
CE_DS=0; CE_EXIT=0; CE_ERR=""; CE_REC=""
ce_timed() {
  local pay="${CE_ROOT}/payload.json" err="${CE_ROOT}/stderr" pid n=0
  /bin/rm -f "$CE_LOG"
  bash_payload "$(/bin/cat "$3")" "$CE_ROOT" > "$pay"
  ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT; LC_ALL="$2" exec /bin/bash "${CE_HOOKS}/$1" < "$pay" > /dev/null 2> "$err" ) &
  pid=$!
  CE_REC=""; CE_ERR=""
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$n" -ge "$4" ]; then
      lin_reap "$pid"; wait "$pid" 2>/dev/null
      CE_DS=-1; CE_EXIT=-1; return 0
    fi
    /bin/sleep 0.1; n=$(( n + 1 ))
  done
  CE_EXIT=0; wait "$pid" || CE_EXIT=$?
  CE_DS="$n"
  CE_ERR="$(/bin/cat "$err" 2>/dev/null)"
  if [ -s "$CE_LOG" ]; then CE_REC="$(/usr/bin/jq -s -c '.[-1]' "$CE_LOG" 2>/dev/null)"; fi
}
ce_ceiling() { # -> the features.ceiling of CE_REC, or empty
  if [ -n "$CE_REC" ]; then /usr/bin/jq -r '.features.ceiling // ""' <<<"$CE_REC" 2>/dev/null; fi
}
ce_report() { # <label> <observed reasons; empty = pass>
  if [ -z "$2" ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else /usr/bin/printf 'FAIL: %s\n  observed:%s\n' "$1" "$2"; FAIL=$((FAIL + 1)); fi
}
# ce_fill <chars> <head> <unit> <tail> — the head, whole units, blanks to the exact length, then the tail.
ce_fill() {
  H="$2" U="$3" T="$4" LC_ALL=C /usr/bin/awk -v n="$1" 'BEGIN { h = ENVIRON["H"]; u = ENVIRON["U"]; t = ENVIRON["T"]
    m = n - length(h) - length(t); k = int(m / length(u)); r = ""; b = u
    while (k > 0) { if (k % 2) r = r b; b = b b; k = int(k / 2) }
    p = m - length(r); s = ""; while (length(s) < p) s = s " "
    printf "%s%s%s%s", h, r, s, t }'
}
CE_NA="${WC_D}/na.sh"
CE_Q="'"
CE_BODY_HEAD="gh pr create --title t --body \"\$(cat <<${CE_Q}EOF${CE_Q}"$'\n'
CE_BODY_TAIL=$'EOF\n)"'
# ce_shape <class> <chars> <file> — one of the ten classes, each inert unless the class says so.
ce_shape() {
  case "$1" in
    segment)    ce_fill "$2" 'echo' ' ab' '' ;;
    segments)   ce_fill "$2" 'true' ';true' '' ;;
    quotes)     ce_fill "$2" 'bash -n ' '""' '' ;;
    openers)    ce_fill "$2" 'echo' ' $(true)' '' ;;
    blanks)     ce_fill "$2" '' ' ' 'echo a' ;;
    view)       ce_fill "$2" 'echo' " \$(true) $(/usr/bin/printf '%*s' 600 '' | /usr/bin/tr ' ' 'x')" '' ;;
    cluster)    ce_fill "$2" 'sudo -' 'b' ' q' ;;
    body)       ce_fill "$2" "$CE_BODY_HEAD" $'| a | b | `c` |\nSome prose with a `code span` and more plain words in it.\n' "$CE_BODY_TAIL" ;;
    rows)       ce_fill "$2" "$CE_BODY_HEAD" "see \`${CE_NA}\` for the detail"$'\n' "$CE_BODY_TAIL" ;;
    assignment) ce_fill "$2" 'X=' 'a' ' true' ;;
  esac > "$3"
}

# CEIL-VALUE — the three constants, each one exact readonly line, and their margins.
ce_why=""
ce_sec="$(/usr/bin/sed -n 's/^readonly SCRIPT_CEIL_SECONDS=\([0-9][0-9]*\)$/\1/p' "$HOOK")"
ce_chr="$(/usr/bin/sed -n 's/^readonly SCRIPT_CEIL_CHARS=\([0-9][0-9]*\)$/\1/p' "$HOOK")"
[ "$(/usr/bin/grep -c '^readonly SCRIPT_CEIL_SECONDS=[0-9][0-9]*$' "$HOOK")" = 1 ] || ce_why="${ce_why} no-single-deadline-line"
[ "$(/usr/bin/grep -c '^readonly SCRIPT_CEIL_CHARS=[0-9][0-9]*$' "$HOOK")" = 1 ] || ce_why="${ce_why} no-single-gate-line"
[ "$(/usr/bin/grep -cF 'readonly SCRIPT_CEIL_AT=$(( SECONDS + SCRIPT_CEIL_SECONDS ))' "$HOOK")" = 1 ] || ce_why="${ce_why} no-single-anchor-line"
if [ -n "$ce_sec" ] && [ -n "$ce_chr" ]; then
  [ $(( ce_sec * 4 )) -le 600 ] || ce_why="${ce_why} deadline-not-four-times-under-600"
  [ "$ce_chr" -ge 40960 ] || ce_why="${ce_why} gate-under-the-largest-timed-cell"
fi
ce_report "CEIL-VALUE: the deadline, the gate and the anchor are single readonly lines; the deadline is at least four times under 600 s and the gate at least the largest timed cell" "$ce_why"

# CEIL-COVER — every bash loop on the -022 surface (the helpers from the allowlist reader to the
# dispatch banner, and the -022 block) is charged by a check as its body's first statement, or
# declared bounded by a `# ceil-bounded:` line directly above its head; no check sits inside the two
# helpers that run in a command substitution. awk programs' loops (`for (`, `while (`) are not bash.
ce_cover() { # <file> -> "loops charged bounded bad sub unseen"
  /usr/bin/awk '
    /^is_script_allowlisted\(\) \{/ { on = 1 }
    /^# BRANCH BY TOOL NAME/ { on = 0 }
    /# BLOCK-DESTRUCTIVE-022 — an interpreter/ { on = 1 }
    /# ---- Write\/Edit branch/ { on = 0 }
    /^(script_realpath|script_cont_joined)\(\) / { insub = 1 }
    insub && /script_ceil_(check|refuse)/ { sub_n++ }
    insub && /^\}/ { insub = 0 }
    { line[NR] = $0 }
    on && $0 !~ /^[[:space:]]*#/ && ($0 ~ /^[[:space:]]*(while|until)[[:space:]]+[^(]/ || $0 ~ /^[[:space:]]*for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in([[:space:]]|$)/) { head[++nh] = NR }
    # The forms the head pattern does not read: an arithmetic for, a select, and a loop keyword after a
    # separator or a pipe on the same line. None may appear on the surface (an awk loop opens with a paren).
    on && $0 !~ /^[[:space:]]*#/ && ($0 ~ /(^|[;&|[:space:]])for[[:space:]]*\(\(/ || $0 ~ /(^|[;&|[:space:]])select[[:space:]]+[A-Za-z_]/ || $0 ~ /[;&|][[:space:]]*(while|until)[[:space:]]+[^(]/ || $0 ~ /[;&|][[:space:]]*for[[:space:]]+[A-Za-z_]/) { un = un (un == "" ? "" : ",") NR }
    END {
      for (i = 1; i <= nh; i++) {
        h = head[i]
        if (line[h - 1] ~ /^[[:space:]]*# ceil-bounded: [^[:space:]]/) { nb++; continue }
        d = h; while (d <= NR && line[d] !~ /(^|[;[:space:]])do([[:space:]]+#.*)?$/) d++
        b = d + 1; while (b <= NR && line[b] ~ /^[[:space:]]*$/) b++
        if (line[b] ~ /^[[:space:]]*script_ceil_check [a-z0-9-]+[[:space:]]+# M-CEIL-[A-Z0-9-]+$/) nc++
        else bad = bad (bad == "" ? "" : ",") h
      }
      printf "%d %d %d %s %d %s", nh, nc, nb, (bad == "" ? "-" : bad), sub_n, (un == "" ? "-" : un)
    }' "$1"
}
read -r ce_nl ce_nc ce_nb ce_bad ce_sub ce_un <<<"$(ce_cover "$HOOK")"
ce_why=""
[ "$ce_nl" -ge 46 ] || ce_why="${ce_why} loops-found=${ce_nl}(wanted-at-least-46)"
[ $(( ce_nc + ce_nb )) = "$ce_nl" ] || ce_why="${ce_why} charged=${ce_nc}+bounded=${ce_nb}-of-${ce_nl}; unannotated-at-lines:${ce_bad}"
[ "$ce_sub" = 0 ] || ce_why="${ce_why} a-check-inside-a-subshell-helper=${ce_sub}"
[ "$ce_un" = "-" ] || ce_why="${ce_why} a-loop-form-the-arm-does-not-read-at-lines:${ce_un}"
ce_report "CEIL-COVER: every bash loop on the -022 surface is charged or declared bounded (${ce_nl} loops: ${ce_nc} charged, ${ce_nb} bounded), none is charged inside a subshell helper, and no loop form the arm does not read appears" "$ce_why"
/usr/bin/grep -v -- '# M-CEIL-ROUTE$' "$HOOK" > "${CE_ROOT}/cover-m1"
/usr/bin/awk '/^# BRANCH BY TOOL NAME/ && !d { print "ceil_cover_probe() {"; print "  while false; do"; print "    :"; print "  done"; print "}"; d = 1 } { print }' \
  "$HOOK" > "${CE_ROOT}/cover-m2"
/usr/bin/awk '/^# BRANCH BY TOOL NAME/ && !d { print "ceil_cover_probe2() {"; print "  for (( i = 0; i < 1; i++ )); do :; done"; print "  select w in a; do break; done"; print "  true; while false; do :; done"; print "}"; d = 1 } { print }' \
  "$HOOK" > "${CE_ROOT}/cover-m3"
ce_why=""
[ "$ce_bad" = "-" ] || ce_why="${ce_why} the-shipped-hook-is-not-covered"
ce_live_n="$(/usr/bin/diff "$HOOK" "${CE_ROOT}/cover-m1" | /usr/bin/grep -c '^[<>]')"
if [ "$ce_live_n" != 1 ]; then
  ce_why="${ce_why} no-route-charge-line-to-delete"
else
  read -r ce_nl ce_nc ce_nb ce_mbad ce_sub ce_un <<<"$(ce_cover "${CE_ROOT}/cover-m1")"
  case "$ce_mbad" in -|*,*) ce_why="${ce_why} the-deleted-route-charge-reads-${ce_mbad}(wanted-one-loop)" ;; esac
fi
read -r ce_nl ce_nc ce_nb ce_mbad ce_sub ce_un <<<"$(ce_cover "${CE_ROOT}/cover-m2")"
case "$ce_mbad" in -|*,*) ce_why="${ce_why} the-added-loop-reads-${ce_mbad}(wanted-one-loop)" ;; esac
read -r ce_nl ce_nc ce_nb ce_mbad ce_sub ce_un <<<"$(ce_cover "${CE_ROOT}/cover-m3")"
case "$ce_un" in *,*,*) ;; *) ce_why="${ce_why} the-three-unread-forms-read-${ce_un}(wanted-three-lines)" ;; esac
ce_report "CEIL-COVER-mut: a copy with the route loop's charge deleted, and one with an unannotated loop added, each read exactly one uncovered loop; a copy with an arithmetic for, a select and a loop after a separator added reads all three as forms the arm does not read" "$ce_why"
# CEIL-COVER-charged (Stage 7 F-03) — the here-document pre-pass's character scan and the enclosure cut's
# loop, whose steps read text as long as a line or a position's remainder, carry the check, not only a
# step cap: each marker is present once, and on the trace copy each tag is traced on a command that runs it.
ce_why=""
[ "$(/usr/bin/grep -c '# M-CEIL-HD-SCAN$' "$HOOK")" = 1 ] || ce_why="${ce_why} no-single-scan-charge"
[ "$(/usr/bin/grep -c '# M-CEIL-ENCL-CUT$' "$HOOK")" = 1 ] || ce_why="${ce_why} no-single-cut-charge"
ce_live block-destructive-trace.sh 1 || ce_why="${ce_why} the-trace-copy-edit-did-not-apply"
if wc_row_cmd HL01; then /usr/bin/printf '%s' "$WC_CMDX" > "${CE_ROOT}/charge-hd.cmd"; fi
/bin/rm -f "$CE_TRACE"
ce_timed block-destructive-trace.sh en_US.UTF-8 "${CE_ROOT}/charge-hd.cmd" "$CEIL_LIMIT"
ce_t="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'hd-scan' "$CE_TRACE"; } || /usr/bin/printf 0)"
[ "${ce_t:-0}" -ge 1 ] || ce_why="${ce_why} scan-tag-traced=${ce_t:-0}"
/usr/bin/printf '%s' 'echo $(true) $(true)' > "${CE_ROOT}/charge-cut.cmd"
/bin/rm -f "$CE_TRACE"
ce_timed block-destructive-trace.sh en_US.UTF-8 "${CE_ROOT}/charge-cut.cmd" "$CEIL_LIMIT"
ce_t="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'encl-cut' "$CE_TRACE"; } || /usr/bin/printf 0)"
[ "${ce_t:-0}" -ge 1 ] || ce_why="${ce_why} cut-tag-traced=${ce_t:-0}"
ce_report "CEIL-COVER-charged: the here-document pre-pass's character scan [row HL01] and the enclosure cut's loop are charged, each tag traced" "$ce_why"

# CEIL-AT-CAP — at the deadline and at the gate the rule refuses, never allows.
/usr/bin/printf '%s' 'ls -la' > "${CE_ROOT}/inert.cmd"
ce_why=""
ce_live block-destructive-t0.sh 2 || ce_why="${ce_why} the-t0-copy-edit-did-not-apply"
ce_timed block-destructive-t0.sh en_US.UTF-8 "${CE_ROOT}/inert.cmd" "$CEIL_LIMIT"
[ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
[ "$(ce_ceiling)" = time ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)"
ce_report "CEIL-AT-CAP-time-inert: past the deadline an ordinary allowed command is refused, cause time" "$ce_why"
if wc_row_cmd X24; then /usr/bin/printf '%s' "$WC_CMDX" > "${CE_ROOT}/warn.cmd"; fi
ce_why=""
ce_live block-destructive-t0.sh 2 || ce_why="${ce_why} the-t0-copy-edit-did-not-apply"
ce_d0=0; [ -f "$CE_DRAIN" ] && ce_d0="$(/usr/bin/wc -l < "$CE_DRAIN" | /usr/bin/tr -d '[:space:]')"
ce_timed block-destructive-t0.sh en_US.UTF-8 "${CE_ROOT}/warn.cmd" "$CEIL_LIMIT"
ce_d1=0; [ -f "$CE_DRAIN" ] && ce_d1="$(/usr/bin/wc -l < "$CE_DRAIN" | /usr/bin/tr -d '[:space:]')"
[ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
[ "$ce_d1" = "$ce_d0" ] || ce_why="${ce_why} drain-rows-written=$(( ce_d1 - ce_d0 ))"
ce_report "CEIL-AT-CAP-time-warn: past the deadline a command whose only finding is a warn-phase record is refused and writes no drain row [row X24]" "$ce_why"
/usr/bin/printf '%s' "bash ${CE_NA}" > "${CE_ROOT}/refuse.cmd"
ce_timed block-destructive-t0.sh en_US.UTF-8 "${CE_ROOT}/refuse.cmd" "$CEIL_LIMIT"
ce_why=""; [ "$CE_EXIT" = 2 ] || ce_why=" exit=${CE_EXIT}"
ce_report "CEIL-AT-CAP-time-refuse: past the deadline an unlisted execution is still refused" "$ce_why"
ce_fill 65537 '' 'echo the quick brown fox jumps over $one lazy dog'$'\n' 'gh api repos/o/r' > "${CE_ROOT}/over.cmd"
ce_fill 65536 '' 'echo the quick brown fox jumps over $one lazy dog'$'\n' 'gh api repos/o/r' > "${CE_ROOT}/edge.cmd"
ce_fill 65537 '' 'echo the quick brown fox jumps over $one lazy dog'$'\n' "bash ${CE_NA}" > "${CE_ROOT}/late.cmd"
for ce_loc in en_US.UTF-8 C; do
  ce_timed block-destructive.sh "$ce_loc" "${CE_ROOT}/over.cmd" "$CEIL_LIMIT"
  ce_why=""
  [ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
  [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
  [ "$(ce_ceiling)" = chars ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)"
  ce_report "CEIL-AT-CAP-chars [${ce_loc}]: one character over the gate an inert allowed command is refused, cause chars, at ratio $(lin_ratio "$CE_DS" "$CEIL_LIMIT") of the budget" "$ce_why"
  ce_timed block-destructive.sh "$ce_loc" "${CE_ROOT}/edge.cmd" "$CEIL_LIMIT"
  ce_why=""
  [ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
  [ "$CE_EXIT" = 0 ] || ce_why="${ce_why} exit=${CE_EXIT}"
  ce_report "CEIL-AT-CAP-chars-edge [${ce_loc}]: a linear inert command of exactly the gate is allowed inside the budget, at ratio $(lin_ratio "$CE_DS" "$CEIL_LIMIT")" "$ce_why"
  ce_timed block-destructive.sh "$ce_loc" "${CE_ROOT}/late.cmd" "$CEIL_LIMIT"
  ce_why=""
  [ "$CE_EXIT" != 0 ] || ce_why="${ce_why} allowed"
  [ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
  [ "$CE_EXIT" = 2 ] || [ "$CE_DS" = -1 ] || ce_why="${ce_why} exit=${CE_EXIT}"
  ce_report "CEIL-AT-CAP-chars-late [${ce_loc}]: just over the gate, its only refusal an unlisted execution at the end, the command is refused" "$ce_why"
done
# The gate stands ahead of the first pass that reads the whole command (Stage 7 F-02, operator option
# A): the command-position pass runs only on a command the gate admits. Structural, and timed at four
# times the gate in both locales, where the refusal must come inside the watchdog with cause chars.
ce_why=""
ce_ge="$(/usr/bin/grep -n '# M-CEIL-GATE-EARLY$' "$HOOK" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
ce_cp="$(/usr/bin/grep -n '^    COMMAND_CMDPOS="\$(' "$HOOK" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
[ -n "$ce_ge" ] || ce_why="${ce_why} no-early-gate-line"
[ -n "$ce_cp" ] || ce_why="${ce_why} no-command-position-pass-line"
if [ -n "$ce_ge" ] && [ -n "$ce_cp" ] && [ "$ce_ge" -ge "$ce_cp" ]; then ce_why="${ce_why} the-gate-follows-the-pass"; fi
ce_report "CEIL-GATE-ORDER: the length gate stands ahead of the command-position pass" "$ce_why"
ce_fill 262144 '' 'echo the quick brown fox jumps over $one lazy dog'$'\n' 'gh api repos/o/r' > "${CE_ROOT}/far.cmd"
for ce_loc in en_US.UTF-8 C; do
  ce_timed block-destructive.sh "$ce_loc" "${CE_ROOT}/far.cmd" "$CEIL_LIMIT"
  ce_why=""
  [ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
  [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
  [ "$(ce_ceiling)" = chars ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)"
  ce_report "CEIL-AT-CAP-chars-far [${ce_loc}]: at four times the gate an inert command is refused inside the watchdog, cause chars, at ratio $(lin_ratio "$CE_DS" "$CEIL_LIMIT")" "$ce_why"
done
# CEIL-GATE-EARLY-rule (Stage 7 F-13) — the early gate pinned by what it does, not only by where its line
# stands. One character over the gate, a command whose one finding is another rule's (its last line, with
# nothing after it) is refused under BLOCK-DESTRUCTIVE-022 with cause chars, because the gate refuses before
# that rule reads it. On a copy that keeps the gate's marker line and neutralises its test, the same command
# is refused by the other rule instead, so a gate that stops refusing fails this arm.
/usr/bin/sed '/# M-CEIL-GATE-EARLY$/s/-gt "\$SCRIPT_CEIL_CHARS"/-lt 0/' "$HOOK" > "${CE_HOOKS}/block-destructive-gatenull.sh"
/bin/chmod +x "${CE_HOOKS}/block-destructive-gatenull.sh"
ce_fill 65537 '' 'echo the quick brown fox jumps over $one lazy dog'$'\n' 'git push --force origin main' > "${CE_ROOT}/early.cmd"
ce_why=""
ce_timed block-destructive.sh en_US.UTF-8 "${CE_ROOT}/early.cmd" "$CEIL_LIMIT"
[ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
[ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
ce_rule=""; if [ -n "$CE_REC" ]; then ce_rule="$(/usr/bin/jq -r '.rule // ""' <<<"$CE_REC" 2>/dev/null)"; fi
[ "$ce_rule" = BLOCK-DESTRUCTIVE-022 ] || ce_why="${ce_why} rule=${ce_rule:-none}"
[ "$(ce_ceiling)" = chars ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)"
ce_report "CEIL-GATE-EARLY-rule: one character over the gate, a command another rule would refuse is refused under BLOCK-DESTRUCTIVE-022, cause chars" "$ce_why"
ce_why=""
ce_live block-destructive-gatenull.sh 2 || ce_why="${ce_why} the-gatenull-copy-edit-did-not-apply"
[ "$(/usr/bin/grep -c '# M-CEIL-GATE-EARLY$' "${CE_HOOKS}/block-destructive-gatenull.sh")" = 1 ] || ce_why="${ce_why} the-copy-lost-the-marker-line"
ce_timed block-destructive-gatenull.sh en_US.UTF-8 "${CE_ROOT}/early.cmd" "$CEIL_LIMIT"
[ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
[ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
ce_rule=""; if [ -n "$CE_REC" ]; then ce_rule="$(/usr/bin/jq -r '.rule // ""' <<<"$CE_REC" 2>/dev/null)"; fi
[ "$ce_rule" = BLOCK-DESTRUCTIVE-001 ] || ce_why="${ce_why} rule=${ce_rule:-none}(wanted-BLOCK-DESTRUCTIVE-001)"
[ -z "$(ce_ceiling)" ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)(wanted-none)"
ce_report "CEIL-GATE-EARLY-rule-pair: on a copy that keeps the gate's marker line and neutralises its test, the same command is refused by the other rule, so the arm above fails there" "$ce_why"

# CEIL-SHAPE — ten pathological classes, each built just under the gate. With the ceiling off a
# heavy class outlasts CEIL_CTL (its -ctl limb); with the deadline at 2 s the same class is refused
# with cause time inside CEIL_LIMIT, never stopped and never allowed by running out the clock.
for ce_s in segment segments quotes openers blanks view cluster body rows assignment; do
  ce_shape "$ce_s" 65000 "${CE_ROOT}/shape-${ce_s}.cmd"
  ce_loc=en_US.UTF-8
  ce_timed block-destructive-off.sh "$ce_loc" "${CE_ROOT}/shape-${ce_s}.cmd" "$CEIL_CTL"
  ce_heavy=0; ce_ctl_exit="$CE_EXIT"
  if [ "$CE_DS" = -1 ]; then
    ce_heavy=1
    ce_report "CEIL-SHAPE-${ce_s}-ctl: with the ceiling off the ${ce_s} class outlasts the control watchdog" ""
  else
    /usr/bin/printf 'RESIDUAL: CEIL-SHAPE-%s-ctl bounded without the ceiling, ratio %s of the control watchdog (exit %s)\n' "$ce_s" "$(lin_ratio "$CE_DS" "$CEIL_CTL")" "$CE_EXIT"
    ce_report "CEIL-SHAPE-${ce_s}-ctl: with the ceiling off the ${ce_s} class finishes inside the control watchdog (recorded as a residual)" ""
  fi
  ce_why=""
  ce_live block-destructive-t2.sh 2 || ce_why="${ce_why} the-t2-copy-edit-did-not-apply"
  ce_timed block-destructive-t2.sh "$ce_loc" "${CE_ROOT}/shape-${ce_s}.cmd" "$CEIL_LIMIT"
  [ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
  if [ "$ce_heavy" = 1 ]; then
    [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}(wanted-2)"
    [ "$(ce_ceiling)" = time ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)(wanted-time)"
  else
    if [ "$CE_EXIT" != "$ce_ctl_exit" ] && { [ "$CE_EXIT" != 2 ] || [ "$(ce_ceiling)" != time ]; }; then
      ce_why="${ce_why} exit=${CE_EXIT}(wanted-${ce_ctl_exit}-or-a-time-refusal)"
    fi
  fi
  ce_report "CEIL-SHAPE-${ce_s}: with the deadline at 2 s the ${ce_s} class is decided inside the watchdog, at ratio $(lin_ratio "$CE_DS" "$CEIL_LIMIT")" "$ce_why"
done

# CEIL-LIN — the head resolver's and the head-value check's whole-word quote counts take one linear
# pass (`# linear: quote parity`) for a word of at least SCRIPT_LINEAR_MIN characters.
ce_why=""
/usr/bin/awk '/^script_quote_parity\(\) / { f = 1 } f { print } f && /^\}/ { exit }' "$HOOK" > "${CE_ROOT}/qp.fn"
[ "$(/usr/bin/grep -c '# linear: quote parity$' "${CE_ROOT}/qp.fn")" = 1 ] || ce_why="${ce_why} no-single-marked-quote-parity-line"
# ce_qp <locale> <bound> <function file> <input file> -> "sq dq"
ce_qp() {
  LC_ALL="$1" /bin/bash -c 'set -eu; SCRIPT_LINEAR_MIN="$1"; script_qp_sq=9; script_qp_dq=9
    . "$2"; w="$(/bin/cat "$3"; printf x)"; w="${w%x}"; script_quote_parity "$w"; printf "%s %s" "$script_qp_sq" "$script_qp_dq"' _ "$2" "$3" "$4"
}
if [ -z "$ce_why" ]; then
  LC_ALL=C /usr/bin/awk 'BEGIN { for (r = 0; r < 3; r++) { for (i = 1; i < 256; i++) printf "%c", i
    printf "%s", "naïve 日本 ü \377\303 x\342\202 y\200 \047\047\047 \"\"\" a\047b\"c" } }' > "${CE_ROOT}/qd-0"
  { /bin/cat "${CE_ROOT}/qd-0"; /usr/bin/printf "'"; } > "${CE_ROOT}/qd-1"
  { /bin/cat "${CE_ROOT}/qd-0"; /usr/bin/printf '"'; } > "${CE_ROOT}/qd-2"
  { /bin/cat "${CE_ROOT}/qd-0"; /usr/bin/printf "'\""; } > "${CE_ROOT}/qd-3"
  /usr/bin/sed 's/printf "%d %d", s % 2, t % 2/printf "%d %d", (s + 1) % 2, t % 2/' "${CE_ROOT}/qp.fn" > "${CE_ROOT}/qp-near.fn"
  for ce_loc in en_US.UTF-8 C; do
    for ce_k in 0 1 2 3; do
      ce_a="$(ce_qp "$ce_loc" 1000000000 "${CE_ROOT}/qp.fn" "${CE_ROOT}/qd-${ce_k}")" || ce_why="${ce_why} [${ce_loc} qd-${ce_k}] the substitutions did not run;"
      ce_b="$(ce_qp "$ce_loc" 0 "${CE_ROOT}/qp.fn" "${CE_ROOT}/qd-${ce_k}")" || ce_why="${ce_why} [${ce_loc} qd-${ce_k}] the pass did not run;"
      [ "$ce_a" = "$ce_b" ] || ce_why="${ce_why} [${ce_loc} qd-${ce_k}] pass ${ce_b} != substitutions ${ce_a};"
    done
    ce_a="$(ce_qp "$ce_loc" 1000000000 "${CE_ROOT}/qp.fn" "${CE_ROOT}/qd-1")"
    ce_n="$(ce_qp "$ce_loc" 0 "${CE_ROOT}/qp-near.fn" "${CE_ROOT}/qd-1" 2>/dev/null)" || ce_n="error"
    [ "$ce_a" != "$ce_n" ] || ce_why="${ce_why} [${ce_loc}] the near miss equals the substitutions;"
  done
fi
ce_report "CEIL-LIN-EQ: the quote-parity pass equals the two substitutions on a dense input in UTF-8 and C, and a near miss differs" "$ce_why"
/usr/bin/sed 's/^readonly SCRIPT_LINEAR_MIN=256$/readonly SCRIPT_LINEAR_MIN=1000000000/' "$HOOK" > "${CE_HOOKS}/block-destructive-nopass.sh"
/usr/bin/sed '/# linear: quote parity$/s#/usr/bin/awk#/nonexistent/awk#' "$HOOK" > "${CE_HOOKS}/block-destructive-noawk.sh"
/bin/chmod +x "${CE_HOOKS}/block-destructive-nopass.sh" "${CE_HOOKS}/block-destructive-noawk.sh"
ce_n=0
for ce_cell in 10:en_US.UTF-8 20:en_US.UTF-8 40:en_US.UTF-8 10:C 20:C 40:C; do
  ce_kb="${ce_cell%%:*}"; ce_loc="${ce_cell#*:}"; ce_n=$(( ce_n + 1 ))
  ce_fill $(( ce_kb * 1024 )) 'X=' 'a' "'b' true" > "${CE_ROOT}/lin-${ce_kb}.cmd"
  ce_timed block-destructive.sh "$ce_loc" "${CE_ROOT}/lin-${ce_kb}.cmd" "$LIN_LIMIT"
  ce_why=""
  /usr/bin/grep -q '# linear: quote parity$' "$HOOK" || ce_why="${ce_why} no-marked-line"
  [ "$CE_DS" != -1 ] || ce_why="${ce_why} stopped"
  [ "$CE_EXIT" = 0 ] || ce_why="${ce_why} exit=${CE_EXIT}"
  ce_report "CEIL-LIN-${ce_n}: one assignment word at a segment head with a quoted piece, in ${ce_loc}, is allowed inside the budget at ratio $(lin_ratio "$CE_DS" "$LIN_LIMIT")" "$ce_why"
done
ce_why=""
/usr/bin/grep -q '# linear: quote parity$' "$HOOK" || ce_why="${ce_why} no-marked-line"
ce_timed block-destructive-nopass.sh en_US.UTF-8 "${CE_ROOT}/lin-40.cmd" "$LIN_LIMIT"
[ "$CE_DS" = -1 ] || ce_why="${ce_why} not-stopped(ratio-$(lin_ratio "$CE_DS" "$LIN_LIMIT"))"
ce_report "CEIL-LIN-CTL: a copy whose bound never lets the pass run is stopped at the budget on the largest UTF-8 cell" "$ce_why"
ce_why=""
/usr/bin/grep -q '# linear: quote parity$' "$HOOK" || ce_why="${ce_why} no-marked-line"
ce_live block-destructive-noawk.sh 2 || ce_why="${ce_why} the-no-awk-copy-edit-did-not-apply"
ce_fill 400 'X=' 'a' "'b' bash ${CE_NA}" > "${CE_ROOT}/fb-b.cmd"
ce_fill 400 'X=' 'a' "'b' echo ${CE_NA}" > "${CE_ROOT}/fb-a.cmd"
ce_fill 400 'X=' 'a' "'b' true" > "${CE_ROOT}/fb-long.cmd"
for ce_f in fb-b:2 fb-a:0 fb-long:0; do
  ce_timed block-destructive-noawk.sh en_US.UTF-8 "${CE_ROOT}/${ce_f%%:*}.cmd" "$LIN_LIMIT"
  [ "$CE_EXIT" = "${ce_f#*:}" ] || ce_why="${ce_why} ${ce_f%%:*}-exit=${CE_EXIT}"
  case "$CE_ERR" in *"line "[0-9]*": "*|*"No such file"*) ce_why="${ce_why} ${ce_f%%:*}-hook-error" ;; esac
done
ce_report "CEIL-LIN-FB: with the pass's awk missing the quote counts fall back to the substitutions and the verdicts are the shipped hook's" "$ce_why"

# CEIL-CTL — ordinary commands pay nothing measurable, and no verdict moves.
/usr/bin/printf '%s' 'git commit -m "fix: a short subject"' > "${CE_ROOT}/cost-1.cmd"
/usr/bin/printf '%s' "${CE_BODY_HEAD}A short body with one line."$'\n'"${CE_BODY_TAIL}" > "${CE_ROOT}/cost-2.cmd"
/usr/bin/printf '%s' 'git status && ls -la | head -5; echo done' > "${CE_ROOT}/cost-3.cmd"
# ce_med <copy> <command file> <runs> -> the median of the runs' wall times, in milliseconds
ce_ms() { /usr/bin/perl -MTime::HiRes=time -e 'printf "%d", time() * 1000'; }
ce_cost() { # <copy A> <copy B> <command file> <runs> -> "medianA medianB", runs interleaved
  local i=0 t0 t1 a="" b="" pay="${CE_ROOT}/cost.json"
  bash_payload "$(/bin/cat "$3")" "$CE_ROOT" > "$pay"
  while [ "$i" -lt "$4" ]; do
    t0="$(ce_ms)"; ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT; /bin/bash "${CE_HOOKS}/$1" < "$pay" > /dev/null 2>&1 ) || true; t1="$(ce_ms)"; a="${a}$(( t1 - t0 ))"$'\n'
    t0="$(ce_ms)"; ( unset PMO_SCOPE_GUARD_ROOT CLAUDE_WORKSPACE_ROOT; /bin/bash "${CE_HOOKS}/$2" < "$pay" > /dev/null 2>&1 ) || true; t1="$(ce_ms)"; b="${b}$(( t1 - t0 ))"$'\n'
    i=$(( i + 1 ))
  done
  /usr/bin/printf '%s %s' "$(/usr/bin/printf '%s' "$a" | /usr/bin/sort -n | /usr/bin/awk '{ v[NR] = $1 } END { print v[int((NR + 1) / 2)] }')" \
    "$(/usr/bin/printf '%s' "$b" | /usr/bin/sort -n | /usr/bin/awk '{ v[NR] = $1 } END { print v[int((NR + 1) / 2)] }')"
}
for ce_k in 1 2 3; do
  read -r ce_ma ce_mb <<<"$(ce_cost block-destructive.sh block-destructive-strip.sh "${CE_ROOT}/cost-${ce_k}.cmd" 40)"
  ce_r="$(/usr/bin/awk -v a="$ce_ma" -v b="$ce_mb" 'BEGIN { printf "%.3f", (b > 0 ? a / b : 0) }')"
  ce_why=""
  /usr/bin/awk -v r="$ce_r" 'BEGIN { exit !(r < 1.10) }' || ce_why=" ratio-of-medians=${ce_r}"
  ce_report "CEIL-CTL-cost-${ce_k}: an ordinary command costs the shipped hook under 1.10 times the copy with no ceiling (ratio of medians ${ce_r}, 40 interleaved runs)" "$ce_why"
done
ce_why=""
ce_live block-destructive-sens.sh 1 || ce_why="${ce_why} the-sensitivity-copy-edit-did-not-apply"
read -r ce_ma ce_mb <<<"$(ce_cost block-destructive-sens.sh block-destructive-strip.sh "${CE_ROOT}/cost-3.cmd" 5)"
ce_r="$(/usr/bin/awk -v a="$ce_ma" -v b="$ce_mb" 'BEGIN { printf "%.3f", (b > 0 ? a / b : 0) }')"
/usr/bin/awk -v r="$ce_r" 'BEGIN { exit !(r >= 1.10) }' || ce_why="${ce_why} ratio-of-medians=${ce_r}(wanted-over-1.10)"
ce_report "CEIL-CTL-cost-sens: the same measure reads over its bound on a copy whose check sleeps 50 ms (ratio ${ce_r})" "$ce_why"
ce_mv=0; ce_i=0
while [ "$ce_i" -lt "$wc_n" ]; do
  [ "${WC_OBS[$ce_i]:-}" = "${WC_REC[$ce_i]}" ] || ce_mv=$(( ce_mv + 1 ))
  ce_i=$(( ce_i + 1 ))
done
ce_why=""; [ "$wc_n" -gt 0 ] || ce_why=" no-corpus-rows"; [ "$ce_mv" = 0 ] || ce_why="${ce_why} rows-moved=${ce_mv}"
ce_report "CEIL-CTL-verdict: over the walk payload corpus no verdict moves (${wc_n} rows)" "$ce_why"

# CEIL-CAUSE — the refusal names the ceiling and the remedy; its row says which ceiling.
ce_why=""
for ce_c in "t0:inert:takes longer to read than this rule allows" "ship:over:is longer than this rule reads"; do
  ce_cp="block-destructive-${ce_c%%:*}.sh"; [ "${ce_c%%:*}" = ship ] && ce_cp=block-destructive.sh
  ce_rest="${ce_c#*:}"
  ce_timed "$ce_cp" en_US.UTF-8 "${CE_ROOT}/${ce_rest%%:*}.cmd" "$CEIL_LIMIT"
  case "$CE_ERR" in *"BLOCKED: "*"${ce_rest#*:}"*"per-command work ceiling"*) ;; *) ce_why="${ce_why} [${ce_rest%%:*}] reason-does-not-name-the-ceiling-and-its-cause" ;; esac
  ce_ov="$(/usr/bin/printf '%s\n' "$CE_ERR" | /usr/bin/sed -n 's/^Override: //p')"
  case "$ce_ov" in "pass long text by file reference"*"not an agent's next step.") ;; *) ce_why="${ce_why} [${ce_rest%%:*}] override-order" ;; esac
done
ce_report "CEIL-CAUSE-text: each refusal names the work ceiling and its cause, the deadline and the length gate, and its Override leads with passing text by file and ends with the bypass" "$ce_why"
ce_why=""
for ce_c in t0:inert:time ship:over:chars; do
  ce_cp="block-destructive-${ce_c%%:*}.sh"; [ "${ce_c%%:*}" = ship ] && ce_cp=block-destructive.sh
  ce_rest="${ce_c#*:}"
  ce_d0=0; [ -f "$CE_DRAIN" ] && ce_d0="$(/usr/bin/wc -l < "$CE_DRAIN" | /usr/bin/tr -d '[:space:]')"
  ce_timed "$ce_cp" en_US.UTF-8 "${CE_ROOT}/${ce_rest%%:*}.cmd" "$CEIL_LIMIT"
  ce_d1=0; [ -f "$CE_DRAIN" ] && ce_d1="$(/usr/bin/wc -l < "$CE_DRAIN" | /usr/bin/tr -d '[:space:]')"
  if [ -z "$CE_REC" ]; then ce_why="${ce_why} [${ce_rest#*:}] no-record"; continue; fi
  [ "$(/usr/bin/jq -r '[keys_unsorted[]] | join(",")' <<<"$CE_REC")" = "ts,hook,rule,tool,input_digest,cwd,features" ] || ce_why="${ce_why} [${ce_rest#*:}] keys"
  [ "$(/usr/bin/jq -c '.features' <<<"$CE_REC")" = "{\"schema_version\":1,\"ceiling\":\"${ce_rest#*:}\"}" ] || ce_why="${ce_why} [${ce_rest#*:}] features=$(/usr/bin/jq -c '.features' <<<"$CE_REC")"
  [ "$ce_d1" = "$ce_d0" ] || ce_why="${ce_why} [${ce_rest#*:}] drain-row-written"
done
ce_report "CEIL-CAUSE-row: a ceiling refusal's row holds the six base keys and features {schema_version, ceiling} exactly, and writes no drain row" "$ce_why"
ce_why=""
ce_live block-destructive-site.sh 1 || ce_why="${ce_why} the-site-copy-edit-did-not-apply"
if wc_row_cmd ZU34; then /usr/bin/printf '%s' "$WC_CMDX" > "${CE_ROOT}/route.cmd"; fi
ce_timed block-destructive-site.sh en_US.UTF-8 "${CE_ROOT}/route.cmd" "$CEIL_LIMIT"
[ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
[ "$(ce_ceiling)" = time ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)"
[ -z "$CE_REC" ] || [ "$(/usr/bin/jq -r '.features.route // ""' <<<"$CE_REC")" = "" ] || ce_why="${ce_why} carries-features.route"
case "$CE_ERR" in *"Read on the conservative route"*) ce_why="${ce_why} carries-the-route-note" ;; esac
ce_report "CEIL-CAUSE-route: a ceiling refusal inside the latch route's loop carries features.ceiling and no route tag [row ZU34]" "$ce_why"

# CEIL-NEWSCAN-TEXT — the backtick command word's lookahead (#8490) is charged: its tag is traced
# once per pass, and its hand-off shape at the gate is decided inside the budget.
ce_why=""
ce_live block-destructive-trace.sh 1 || ce_why="${ce_why} the-trace-copy-edit-did-not-apply"
if wc_row_cmd LT01; then /usr/bin/printf '%s' "$WC_CMDX" > "${CE_ROOT}/tick.cmd"; fi
/bin/rm -f "$CE_TRACE"
ce_timed block-destructive-trace.sh en_US.UTF-8 "${CE_ROOT}/tick.cmd" "$CEIL_LIMIT"
ce_t="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'tick' "$CE_TRACE"; } || /usr/bin/printf 0)"
[ "${ce_t:-0}" -ge 1 ] || ce_why="${ce_why} lookahead-tag-traced=${ce_t:-0}"
ce_fill 65000 '`' "x $(/usr/bin/printf '%*s' 60 '' | /usr/bin/tr ' ' 'y')" '` q' > "${CE_ROOT}/tick-big.cmd"
ce_timed block-destructive.sh en_US.UTF-8 "${CE_ROOT}/tick-big.cmd" "$CEIL_LIMIT"
if [ "$CE_DS" = -1 ]; then
  ce_timed block-destructive-t2.sh en_US.UTF-8 "${CE_ROOT}/tick-big.cmd" "$CEIL_LIMIT"
  [ "$CE_DS" != -1 ] && [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} the-gate-sized-hand-off-is-not-decided-inside-the-budget"
fi
ce_report "CEIL-NEWSCAN-TEXT: the backtick command word's lookahead is charged once per pass [row LT01], and its gate-sized hand-off is decided inside the budget" "$ce_why"

# CEIL-NEWSCAN-HD — the here-document receiver read (#8326) is charged: its tag is traced on an
# admitted receiver behind a group opener, and its gate-sized hand-off is decided inside the budget.
ce_why=""
ce_live block-destructive-trace.sh 1 || ce_why="${ce_why} the-trace-copy-edit-did-not-apply"
if wc_row_cmd HL01; then /usr/bin/printf '%s' "$WC_CMDX" > "${CE_ROOT}/hdrecv.cmd"; fi
/bin/rm -f "$CE_TRACE"
ce_timed block-destructive-trace.sh en_US.UTF-8 "${CE_ROOT}/hdrecv.cmd" "$CEIL_LIMIT"
ce_t="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'hd-recv' "$CE_TRACE"; } || /usr/bin/printf 0)"
[ "${ce_t:-0}" -ge 1 ] || ce_why="${ce_why} receiver-read-tag-traced=${ce_t:-0}"
ce_fill 65000 '' '{ ' " gh api x --input - <<'EOF'"$'\n'"bash ${CE_NA}"$'\n'"EOF" > "${CE_ROOT}/hdrecv-big.cmd"
ce_timed block-destructive.sh en_US.UTF-8 "${CE_ROOT}/hdrecv-big.cmd" "$CEIL_LIMIT"
if [ "$CE_DS" = -1 ]; then
  ce_timed block-destructive-t2.sh en_US.UTF-8 "${CE_ROOT}/hdrecv-big.cmd" "$CEIL_LIMIT"
  [ "$CE_DS" != -1 ] && [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} the-gate-sized-hand-off-is-not-decided-inside-the-budget"
fi
ce_report "CEIL-NEWSCAN-HD: the here-document receiver read is charged on an admitted receiver behind a group opener [row HL01], and its gate-sized hand-off is decided inside the budget" "$ce_why"

# CEIL-NEWSCAN-ASGN — the assignment-substitution step (#8548) is charged: its tag is traced on an
# admitted assignment substitution; on one segment of 1,100 admitted assignment words, each closing on
# the listed script so every attempt reaches the allowlist read, the step is attempted until the shared
# work budget declines it (a copy traces only the step's tag and that decline, with bash's own printf);
# and its gate-sized hand-off, the same words with a long closing token last, is decided inside the
# budget. The arm names the limb that decided, with no timing figure.
ce_why=""
ce_live block-destructive-trace.sh 1 || ce_why="${ce_why} the-trace-copy-edit-did-not-apply"
if wc_row_cmd AS01; then /usr/bin/printf '%s' "$WC_CMDX" > "${CE_ROOT}/asgn.cmd"; fi
/bin/rm -f "$CE_TRACE"
ce_timed block-destructive-trace.sh en_US.UTF-8 "${CE_ROOT}/asgn.cmd" "$CEIL_LIMIT"
ce_t="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'asgn-subst' "$CE_TRACE"; } || /usr/bin/printf 0)"
[ "${ce_t:-0}" -ge 1 ] || ce_why="${ce_why} step-tag-traced=${ce_t:-0}"
F="$CE_TRACE" /usr/bin/awk 'BEGIN { f = ENVIRON["F"] }
  / # M-CEIL-TEST$/ { print "  if [ \"$1\" = asgn-subst ]; then builtin printf \"%s\\n\" \"$1\" >> \"" f "\"; fi" }
  / # M-ASGN-SUBST-WORK$/ { print "  if [ \"$script_qwork\" -ge 1000 ]; then builtin printf \"%s\\n\" asgn-work >> \"" f "\"; fi" }
  { print }' "$HOOK" > "${CE_HOOKS}/block-destructive-trace-asgn.sh"
/bin/chmod +x "${CE_HOOKS}/block-destructive-trace-asgn.sh"
ce_live block-destructive-trace-asgn.sh 2 || ce_why="${ce_why} the-step-trace-copy-edits-did-not-apply"
ce_unit="OUT=\$(bash ${WC_D}/ok.sh) "
ce_fill $(( 1100 * ${#ce_unit} + 4 )) '' "$ce_unit" 'true' > "${CE_ROOT}/asgn-budget.cmd"
/bin/rm -f "$CE_TRACE"
ce_timed block-destructive-trace-asgn.sh en_US.UTF-8 "${CE_ROOT}/asgn-budget.cmd" "$CEIL_LIMIT"
ce_ta="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'asgn-subst' "$CE_TRACE"; } || /usr/bin/printf 0)"
ce_tw="$( { [ -f "$CE_TRACE" ] && /usr/bin/grep -cx 'asgn-work' "$CE_TRACE"; } || /usr/bin/printf 0)"
[ "${ce_tw:-0}" -ge 1 ] || ce_why="${ce_why} the-step-never-reached-the-shared-budget(attempts=${ce_ta:-0})"
[ "${ce_ta:-0}" -ge 990 ] || ce_why="${ce_why} attempts=${ce_ta:-0}(wanted-at-least-990-of-the-1000-unit-budget)"
ce_fill 65000 '' "$ce_unit" "OUT=\$(bash ${WC_D}/$(/usr/bin/printf '%*s' 600 '' | /usr/bin/tr ' ' 'x')/ok.sh) true" > "${CE_ROOT}/asgn-big.cmd"
ce_lim="shipped copy"
ce_timed block-destructive.sh en_US.UTF-8 "${CE_ROOT}/asgn-big.cmd" "$CEIL_LIMIT"
if [ "$CE_DS" = -1 ]; then
  ce_lim="2-second deadline copy, the shipped copy having been stopped"
  ce_timed block-destructive-t2.sh en_US.UTF-8 "${CE_ROOT}/asgn-big.cmd" "$CEIL_LIMIT"
  [ "$CE_DS" != -1 ] && [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} the-gate-sized-hand-off-is-not-decided-inside-the-budget"
fi
/usr/bin/printf 'RESIDUAL: CEIL-NEWSCAN-ASGN the gate-sized hand-off was decided by the %s (exit %s); on the budget shape the step was attempted %s times and reached the shared budget %s time(s)\n' "$ce_lim" "$CE_EXIT" "${ce_ta:-0}" "${ce_tw:-0}"
ce_report "CEIL-NEWSCAN-ASGN: the assignment-substitution step is charged on an admitted assignment substitution [row AS01], is attempted until the shared work budget declines it, and its gate-sized hand-off is decided inside the budget (by the ${ce_lim})" "$ce_why"

# CEIL-VIEW — past either of the view's budgets, once an arm that reads enclosure positions enforces,
# the command is refused instead of losing a position; at the shipped warn phases nothing moves.
/usr/bin/printf '%s' 'echo $(true) $(true) $(true) $(true) $(true) $(true)' > "${CE_ROOT}/vpos.cmd"
/usr/bin/printf '%s' "echo \$(true) $(/usr/bin/printf '%*s' 100 '' | /usr/bin/tr ' ' 'x') \$(true) y" > "${CE_ROOT}/vrem.cmd"
for ce_v in v-pos:vpos:positions v-rem:vrem:remainder v-exec:vpos:positions v-exec-rem:vrem:remainder v-int:vpos:positions v-int-rem:vrem:remainder; do
  ce_cp="block-destructive-${ce_v%%:*}.sh"; ce_rest="${ce_v#*:}"
  ce_timed "$ce_cp" en_US.UTF-8 "${CE_ROOT}/${ce_rest%%:*}.cmd" "$CEIL_LIMIT"
  ce_why=""
  ce_live "$ce_cp" 4 || ce_why="${ce_why} the-copy-edits-did-not-apply"
  [ "$CE_EXIT" = 2 ] || ce_why="${ce_why} exit=${CE_EXIT}"
  [ "$(ce_ceiling)" = "${ce_rest#*:}" ] || ce_why="${ce_why} features.ceiling=$(ce_ceiling)"
  ce_report "CEIL-VIEW-${ce_v%%:*}: with an enclosure-reaching arm at enforce, past the ${ce_rest#*:} budget the command is refused, cause ${ce_rest#*:}" "$ce_why"
done
ce_timed block-destructive-v-warn.sh en_US.UTF-8 "${CE_ROOT}/vpos.cmd" "$CEIL_LIMIT"
ce_why=""; [ "$CE_EXIT" = 0 ] || ce_why=" exit=${CE_EXIT}"
ce_report "CEIL-VIEW-warn: at the shipped warn phases, past the position budget, an inert command is allowed as today" "$ce_why"
/bin/rm -rf "$CE_ROOT"

# --- Summary ---
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
