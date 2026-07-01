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

# --- Summary ---
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
