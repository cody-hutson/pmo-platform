#!/bin/bash
# tests/commit-guard-skip.test.sh — BLOCK-DESTRUCTIVE-024 (block-destructive.sh)
#
# The commit-time PII guard (core/hooks/git-pre-commit-pii.sh) runs as git's
# pre-commit hook. git's own flags and its hooks-directory setting skip it in one
# word. BLOCK-DESTRUCTIVE-024 refuses those spellings. Every positive arm below
# names a spelling that was MEASURED to skip a pre-commit hook in a scratch
# repository (git 2.54), and every control arm names a command that must keep
# working — so a rule that refuses everything fails here as surely as one that
# refuses nothing.
#
# Runs standalone (bash .claude/hooks/tests/commit-guard-skip.test.sh inside a
# layout built by setup-ci-layout.sh) or under test-runner.sh.

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

# must_block / must_allow keep each arm to one line.
must_block() { test_case "refuse: $1" "$(bash_payload "$1")" 2 "BLOCK-DESTRUCTIVE-024"; }
must_allow() { test_case "allow: $1" "$(bash_payload "$1")" 0; }

NL='
'

echo "================================"
echo "block-destructive.sh — BLOCK-DESTRUCTIVE-024 (commit-time guard skip)"
echo "================================"

# Liveness: a long-standing rule must fire. If it does not, the hook is inert here (scope
# gate, bypass, layout) and every "allow" below would pass for the wrong reason.
test_case "liveness: BLOCK-DESTRUCTIVE-001 still fires" \
  "$(bash_payload 'git push --force origin main')" 2 "BLOCK-DESTRUCTIVE-001"

# ---------------------------------------------------------------------------
# Positive arms — git commit's hook-skip flag
# ---------------------------------------------------------------------------
must_block 'git commit --no-verify -m wip'
must_block 'git commit -n -m wip'
must_block 'git commit -anm wip'                 # bundled: a, n, then m takes "wip"
must_block 'git commit -am wip -n'
must_block 'git commit --no-veri -m wip'          # git accepts the unambiguous abbreviation
must_block 'git commit --no-verif -m wip'
must_block 'git commit "-n" -m wip'               # quoted flag is still the flag
must_block "git commit -m wip -'n'"               # partially quoted flag
must_block 'git commit -m "x" -n'
must_block 'git commit --amend --no-verify --no-edit'
must_block 'git -C /tmp/repo commit -n -m wip'    # global option before the subcommand
must_block 'git --git-dir /tmp/repo/.git --work-tree /tmp/repo commit -n -m wip'
must_block '/usr/bin/git commit --no-verify -m wip'
must_block 'cd /tmp/repo && git commit -n -m wip'
must_block 'sudo git commit -n -m wip'
must_block '(git commit -n -m wip)'
must_block 'echo "$(git commit -n -m wip)"'      # substitution inside double quotes runs
must_block 'echo `git commit -n -m wip`'          # backtick substitution runs
must_block 'git commit ""-n -m wip'               # an empty quoted prefix leaves the flag
must_block 'GIT commit -n -m wip'                 # macOS resolves the command word in any case
must_block '/Library/Developer/CommandLineTools/usr/libexec/git-core/git-commit -n -m wip'
must_block 'git commit -m wip --no-verify # tidy later'
must_block "git commit -m wip \\${NL}  --no-verify"   # line continuation joins the flag on
must_block 'git commit -n -m "unterminated'      # unbalanced quotes: conservative view
must_block "echo 'a\\\\${NL}git commit -n -m wip"   # conservative view keeps an unjoined copy
must_block 'git commit -m "$(date)" --no-verify'  # a substitution in an argument does not cut the command
must_block 'git commit -am "$(git log -1 --format=%s)" -n'
must_block 'git -C "$(git rev-parse --show-toplevel)" commit -n -m wip'
must_block 'git commit -m wip 2>&1 -n'            # a redirect is not a separator
must_block "git commit -m \"\$(cat <<'EOF'${NL}msg${NL}EOF${NL})\" --no-verify"   # the heredoc message shape
must_block "bash <<'EOF'${NL}git commit -n -m wip${NL}EOF"                       # a heredoc body a shell runs
must_block "cat <<EOF${NL}\$(git commit -n -m wip)${NL}EOF"                       # unquoted heredoc: substitution runs
must_block "cat > /tmp/m.txt <<'EOF'${NL}Don't${NL}EOF${NL}git commit -n -F /tmp/m.txt"

# Long input. BLOCK-DESTRUCTIVE-022's per-command work ceiling refuses a command longer than
# its length gate (SCRIPT_CEIL_CHARS, 65536 characters) before any rule reads it, so a 70 KB
# command never reaches -024: it is refused with or without the flag. That fail-closed
# outcome is what this pair pins.
#
# The long words are built by the shell's own printf, never /usr/bin/printf: a coreutils printf
# may refuse a field this wide (the Rust coreutils on the Linux runner panics on it), and a
# word built empty sends the hook a short command these arms do not mean to test, so they pass
# or fail on the wrong input. Each word's length is checked before use; one that did not build
# is a FAIL here, and its arms are not run.
built_word() {   # <length> <label> -> WORD holds that many zeros; else records a FAIL, returns 1
  WORD=""
  printf -v WORD '%0*d' "$1" 0
  [ "${#WORD}" -eq "$1" ] && return 0
  /usr/bin/printf 'FAIL: %s\n  the input word built as %s characters, not %s, so its arms were not run\n' "$2" "${#WORD}" "$1"
  FAIL=$((FAIL + 1))
  return 1
}
if built_word 70000 "build the 70 KB word for the length-gate arms"; then
  LONG_WORD="$WORD"
  test_case "refuse: git commit -m <70 KB word> -n (above -022's length gate)" \
    "$(bash_payload "git commit -m ${LONG_WORD} -n")" 2 "BLOCK-DESTRUCTIVE-022"
  test_case "refuse: git commit -m <70 KB word> (above -022's length gate)" \
    "$(bash_payload "git commit -m ${LONG_WORD}")" 2 "BLOCK-DESTRUCTIVE-022"
fi
# Near the gate. An ASCII command short enough for -024 to read also fits within a pipe's
# 64 KiB capacity, so no input -024 can still see tells a pipe-fed matcher from its
# here-string one: this pair pins only that -024 reads a command near the gate in full,
# refusing the flag and allowing the plain form. (A multi-byte command can be under the
# gate and over a pipe's capacity only where ${#} counts characters, which depends on the
# locale, so no such arm is kept. tests/ghsa-xxjm-long-input-matchers.test.sh pins the
# shared matches() for the hooks without a length gate.)
if built_word 60000 "build the 60 KB word for the near-gate arms"; then
  NEAR_WORD="$WORD"
  test_case "refuse: git commit -m <60 KB word> -n" \
    "$(bash_payload "git commit -m ${NEAR_WORD} -n")" 2 "BLOCK-DESTRUCTIVE-024"
  test_case "allow: git commit -m <60 KB word>" \
    "$(bash_payload "git commit -m ${NEAR_WORD}")" 0
fi

# ---------------------------------------------------------------------------
# Positive arms — hooks-directory override for one invocation
# ---------------------------------------------------------------------------
must_block 'git -c core.hooksPath=/dev/null commit -m wip'
must_block 'git -c core.hookspath=/tmp/x commit -m wip'        # config keys are case-insensitive
must_block 'git -c CORE.HOOKSPATH= commit -m wip'              # empty value skips the hook too
must_block "git -c 'core.hooksPath=/tmp/a b' commit -m wip"
must_block 'git -c core."hooksPath"=/tmp/x commit -m wip'
must_block 'git -C /tmp/repo -c core.hooksPath=/tmp/x commit -m wip'
must_block 'git --config-env=core.hooksPath=HP commit -m wip'
must_block 'git --config-env core.hooksPath=HP commit -m wip'
must_block 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m wip'
must_block 'export GIT_CONFIG_KEY_0=core.hooksPath'
must_block "GIT_CONFIG_PARAMETERS=\"'core.hooksPath'='/dev/null'\" git commit -m wip"

# ---------------------------------------------------------------------------
# Positive arms — hooks-directory setting written, unset or removed
# ---------------------------------------------------------------------------
must_block 'git config core.hooksPath /tmp/nohooks'
must_block 'git config --local core.hooksPath /tmp/nohooks'
must_block 'git config --worktree core.hooksPath /tmp/nohooks'
must_block 'git config --global core.hooksPath /tmp/nohooks'
must_block 'git config --file .git/config core.hooksPath /tmp/nohooks'
must_block 'git config --add core.hooksPath /tmp/nohooks'
must_block 'git config --replace-all core.hooksPath /tmp/nohooks'
must_block 'git config set core.hooksPath /tmp/nohooks'
must_block 'git config set --global core.hooksPath /tmp/nohooks'
must_block 'git config core.hooksPath 0'                        # a bare digit is a value too
must_block 'git config core.hooksPath "$(mktemp -d)"'           # a substitution is a value
must_block 'git config core.hooksPath ""'                       # an empty value skips the hook too
must_block "git config core.hooksPath ''"
must_block "cat > /tmp/m.txt <<'EOF'${NL}x${NL}EOF${NL}git config core.hooksPath \"\""   # empty value, conservative view
must_block 'git config --unset core.hooksPath 2>/dev/null'
must_block 'git -C /tmp/repo config core.hooksPath /tmp/nohooks'
must_block 'git config --get core.hooksPath; git config core.hooksPath /tmp/x'
must_block 'git config --unset core.hooksPath'
must_block 'git config --local --unset-all core.hooksPath'
must_block 'git config unset core.hooksPath'
must_block 'git config unset --global core.hooksPath'
must_block 'git config --remove-section core'
must_block 'git config --rename-section core old'

# ---------------------------------------------------------------------------
# Control arms — must keep working
# ---------------------------------------------------------------------------
must_allow 'git commit -m wip'
must_allow 'git commit -am wip'
must_allow 'git commit -mn'                        # -m takes "n" as the message; the hook runs
must_allow 'git commit -m "fix -n flag"'
must_allow "git commit -m 'never use --no-verify'"
must_allow "git commit -m \"Don't skip the hook\""
must_allow 'git commit -m "$(printf "a -n b")"'
must_allow 'git commit --amend --no-edit'
must_allow "git commit -m '' --allow-empty-message"
must_allow 'git commit -S -m wip'
must_allow 'git commit -um wip'                   # -u takes "m" as its mode; no -n
must_allow 'git commit --verify -m wip'
must_allow "git commit -F - <<'EOF'${NL}fix -n handling and the --no-verify docs${NL}EOF"
must_allow "git commit -m \"\$(cat <<'EOF'${NL}Don't pass -n here${NL}EOF${NL})\""
must_allow "cat > /tmp/notes.md <<'EOF'${NL}Never pass -n to git commit${NL}EOF"
must_allow 'git commit -m "$(git log -n 1 --format=%s)"'
must_allow 'git commit -m wip 2>&1 | tail -3'
must_allow "git log -n1 && git commit -m 'note -n'"
must_allow 'git log -n 5'
must_allow 'git log --grep commit -n 3'
must_allow 'git rev-list -n 1 HEAD'
must_allow 'git push -n origin feature/x'
must_allow 'git clean -n'
must_allow 'git -c commit.gpgsign=false commit -m wip'
must_allow 'git -C /tmp/repo commit -m wip'
must_allow 'git config core.hooksPath'
must_allow 'git config --get core.hooksPath 2>/dev/null || echo unset'
must_allow 'git config --show-origin --get core.hooksPath'
must_allow 'git config get core.hooksPath'
must_allow 'git config --list | grep -i hookspath'
must_allow 'git config user.name probe'
must_allow 'git config --unset user.signingkey'
must_allow "grep -rn -- '--no-verify' core/rules"

echo ""
echo "================================"
echo "Total: $((PASS + FAIL))  PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ "$FAIL" = 0 ]
