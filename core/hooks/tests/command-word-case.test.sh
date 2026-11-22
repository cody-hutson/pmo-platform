#!/bin/bash
# tests/command-word-case.test.sh — block-destructive.sh, BLOCK-DESTRUCTIVE-001..015:
# the command word in any case.
#
# macOS's default filesystem is case-insensitive, so a command word spelled in upper or
# mixed case runs the same program: `GIT` is git and `RM` is rm (measured — /usr/bin/GIT
# and /bin/RM are the same files as their lower-case names). The git rules
# (-001..-003, -010..-015) read the word through GIT_WORD_ANYCASE and the rm rules
# (-004..-009) through RM_WORD_ANYCASE. Each positive arm below is a case spelling of a
# command its rule already refuses in lower case, and must be refused BY THAT RULE; each
# lower-case control must still be refused; each allow arm must keep working, so a rule
# that refuses everything fails here as surely as one that refuses nothing.
#
# The builtin subcommands these rules name, and every flag, stay matched as written: git
# does not resolve a builtin in another case (`git PUSH` fails), so it is allowed.
# filter-branch and filter-repo are not builtins — git runs them as the files
# git-filter-branch and git-filter-repo, which the filesystem resolves in any case — so
# -014 and -015 refuse those subcommands in any case too.
#
# Runs standalone (bash .claude/hooks/tests/command-word-case.test.sh inside a layout
# built by setup-ci-layout.sh) or under test-runner.sh.

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
  if [ -n "$expected_pattern" ] && ! /usr/bin/grep -qE "$expected_pattern" <<< "$actual_stderr"; then
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

# The layout root this suite runs in (<root>/.claude/hooks/tests/). Payloads carry it as
# their cwd so the hook's layer-3 scope gate, whose root resolves from the hook's own
# location, keeps them in scope when this file runs standalone as well as under
# test-runner.sh (which widens the scope root itself). A cwd outside that root makes the
# hook inert, and every arm below would then read "allowed" whatever the rule says.
LAYOUT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd -P)"

# Helper: build a Bash tool JSON payload
bash_payload() {
  local cmd="$1"
  local cwd="${2:-$LAYOUT_ROOT}"
  /usr/bin/jq -n --arg cmd "$cmd" --arg cwd "$cwd" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}'
}

# $1 = rule number (e.g. 001), $2 = command — refused by exactly that rule.
must_block() { test_case "refuse ($1): $2" "$(bash_payload "$2")" 2 "BLOCK-DESTRUCTIVE-$1"; }
must_allow() { test_case "allow: $1" "$(bash_payload "$1")" 0; }

echo "================================"
echo "block-destructive.sh — BLOCK-DESTRUCTIVE-001..015 (command word in any case)"
echo "================================"

# Liveness: a rule this change does not touch must fire. If it does not, the hook is inert
# here (scope gate, bypass, layout) and every "allow" below would pass for the wrong reason.
test_case "liveness: BLOCK-DESTRUCTIVE-023 still fires" \
  "$(bash_payload 'export CLAUDE_HOOK_BYPASS=1')" 2 "BLOCK-DESTRUCTIVE-023"

# ---------------------------------------------------------------------------
# git rules: the lower-case control, then six case spellings of the word —
# bare, behind a canonical path, and behind a path that is itself in upper case.
# ---------------------------------------------------------------------------
GIT_SPELLINGS=(git GIT Git gIT /usr/bin/GIT /opt/homebrew/bin/Git /USR/BIN/GIT)
git_rule() {  # $1 = rule number, $2 = everything after the command word
  local w
  for w in "${GIT_SPELLINGS[@]}"; do
    must_block "$1" "$w $2"
  done
}
git_rule 001 'push --force origin main'
git_rule 001 'push -f origin main'
git_rule 002 'reset --hard HEAD~1'
git_rule 003 'clean -fd'
git_rule 010 'update-ref -d refs/heads/main'
git_rule 011 'symbolic-ref HEAD refs/heads/main'
git_rule 012 'push origin +main'
git_rule 013 'reflog expire --expire=now --all'
git_rule 014 'filter-branch --tree-filter true HEAD'
git_rule 015 'filter-repo --path docs'

# -014 / -015: the subcommand itself in another case (external, so it still runs).
must_block 014 'git FILTER-BRANCH --tree-filter true HEAD'
must_block 014 'GIT Filter-Branch --tree-filter true HEAD'
must_block 015 'git FILTER-REPO --path docs'
must_block 015 'Git filter-REPO --path docs'

# ---------------------------------------------------------------------------
# rm rules: the lower-case control, then five case spellings of the word.
# ---------------------------------------------------------------------------
RM_SPELLINGS=(rm RM Rm rM /bin/RM /bin/Rm)
rm_rule() {  # $1 = rule number, $2 = everything after the command word
  local w
  for w in "${RM_SPELLINGS[@]}"; do
    must_block "$1" "$w $2"
  done
}
rm_rule 004 '-rf /'
rm_rule 004 '-rf /Users'
rm_rule 005 '-rf $HOME'
rm_rule 006 '-rf .git'
rm_rule 007 '-rf Projects/'
rm_rule 008 '-rf projects/'
rm_rule 009 '-rf pmo-platform/'

# ---------------------------------------------------------------------------
# The word at other command positions the canonicalizer already resolves.
# ---------------------------------------------------------------------------
must_block 001 'cd repo && GIT push --force origin main'
must_block 002 'echo ok; Git reset --hard HEAD'
must_block 003 '( gIT clean -fdx )'
must_block 004 'sudo RM -rf /'
must_block 008 'true || Rm -rf projects/'

# ---------------------------------------------------------------------------
# Allow arms: commands that must keep working.
# ---------------------------------------------------------------------------
must_allow 'GIT status'
must_allow 'Git log --oneline -5'
must_allow 'GIT push origin feature/x'
must_allow 'GIT push --force-with-lease origin feature/x'
must_allow 'Git reset --soft HEAD~1'
must_allow 'GIT clean -n'
must_allow 'git PUSH --force origin main'      # git rejects an upper-case subcommand
must_allow 'LEGIT push --force origin main'    # a longer word that ends in the letters
must_allow 'my_GIT push --force origin main'   # an identifier, not the command word
must_allow 'RM notes.txt'
must_allow 'RMDIR emptydir'                    # a different command that starts with the letters
must_allow 'FORM -rf /'                        # a different command that ends with them
must_allow 'echo RM -rf / is refused'          # the words as an argument, not a command

echo ""
echo "================================"
echo "Total: $((PASS + FAIL))  PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ "$FAIL" = 0 ]
