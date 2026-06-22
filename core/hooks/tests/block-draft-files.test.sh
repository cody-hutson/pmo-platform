#!/bin/bash
# tests/block-draft-files.test.sh — synthetic PreToolUse payload tests for
# block-draft-files.sh (#411b). Covers: draft-shape + outside-governed flagging,
# the git-ignored sanctioned-scratch allow (incl. the adversarial PR-1 cases:
# steering-committee/ + */governance/roadmaps/), normal-governed allow, and the
# warn / enforce / off mode infrastructure.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-draft-files.sh"
MODE_FILE="${HOOK_DIR}/.mode"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK" >&2; exit 1; }

# Hermetic git fixture. The hook classifies via `git check-ignore` against the repo
# that contains the payload's cwd, so the test must OWN a real git repo carrying the
# sanctioned-scratch .gitignore patterns — depending on the ambient checkout makes the
# test pass locally but fail in CI's materialized-layout sandbox (a bare mktemp dir
# with no git context → the hook fail-opens and every BLOCK case regresses; this was
# the #1847 CI miss). The .gitignore mirrors the real repo: personal/,
# steering-committee/, and <root>/governance/roadmaps/ per governed root.
REPO="$(mktemp -d 2>/dev/null)"
(
  cd "$REPO" && /usr/bin/git init -q && /usr/bin/printf '%s\n' \
    'personal/' 'steering-committee/' \
    'core/governance/roadmaps/' 'release/governance/roadmaps/' 'operations/governance/roadmaps/' \
    > .gitignore
)
REPO="$(cd "$REPO" && pwd -P)"   # canonicalize (macOS mktemp returns a /private symlink) to match `git rev-parse --show-toplevel`

ORIGINAL_MODE=""; [ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(cat "$MODE_FILE")"
cleanup() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
  [ -n "${REPO:-}" ] && /bin/rm -rf "$REPO"
}
trap cleanup EXIT

set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

PASS=0; FAIL=0
# test_case <name> <repo-relative-path> <expected_exit> [expected_stderr_pattern]
test_case() {
  local name="$1" rel="$2" expected_exit="$3" pattern="${4:-}"
  local payload; payload="$(/usr/bin/printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s/%s"}}' "$REPO" "$REPO" "$rel")"
  local tmp; tmp="$(/usr/bin/mktemp)"; local rc=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp" >/dev/null || rc="$?"
  local err; err="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  local ok=1
  [ "$rc" != "$expected_exit" ] && ok=0
  [ -n "$pattern" ] && ! /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE "$pattern" && ok=0
  if [ "$ok" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s)\n  stderr: %s\n' "$name" "$expected_exit" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}

# --- ENFORCE mode: flags BLOCK (exit 2), allows pass (exit 0) ---
set_mode enforce
test_case "enforce: docs/proposals/ draft (the incident) BLOCKED" "docs/proposals/enhancement.md" 2 "BLOCK-DRAFT-001"
test_case "enforce: draft segment under governed root BLOCKED"     "core/scratch/wip.md"           2 "BLOCK-DRAFT-001"
test_case "enforce: stray top-level file BLOCKED"                  "random-idea.md"                2 "outside the governed"
test_case "enforce: normal governed write ALLOWED"                "core/standards/new.md"          0
test_case "enforce: release/ governed write ALLOWED"              "release/references/how-to/g.md" 0
test_case "enforce: tracked top-level (README) ALLOWED"          "README.md"                       0
test_case "enforce: git-ignored personal/ ALLOWED"              "personal/notes.md"               0
test_case "enforce: git-ignored governance/roadmaps (PR-1) ALLOWED" "core/governance/roadmaps/r.md" 0
test_case "enforce: git-ignored steering-committee (PR-1) ALLOWED"  "steering-committee/notes.md"   0

# --- WARN mode: flags WARN (exit 0 + message), allows silent ---
set_mode warn
test_case "warn: draft WARNs not blocks" "docs/proposals/x.md" 0 "WARN \\(would-block"
test_case "warn: governed write silent"  "core/standards/y.md" 0

# --- OFF mode: no action ---
set_mode off
test_case "off: draft not flagged" "docs/proposals/z.md" 0

/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
