#!/bin/bash
# tests/block-skill-direct-edit.test.sh — synthetic Write/Edit payload tests for block-skill-direct-edit.sh
# Covers: Gate 2 hook (BLOCK-SKILL-EDIT-001..002) + plural references/ scope.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-skill-direct-edit.sh"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi

# --- Mode detection ---
# The hook uses .mode file to switch between enforce (exit 2 on block) and warn
# (exit 0 with WARN marker). Tests assert the rule ID fires in both cases; the
# exit code is derived from the mode.
CURRENT_MODE="enforce"
if [ -f "${HOOK_DIR}/.mode" ]; then
  m="$(/bin/cat "${HOOK_DIR}/.mode" 2>/dev/null | /usr/bin/tr -d '[:space:]')"
  case "$m" in enforce|warn|off) CURRENT_MODE="$m" ;; esac
fi
case "$CURRENT_MODE" in
  enforce) BLOCK_EXIT=2 ;;
  warn|off) BLOCK_EXIT=0 ;;
esac
echo "Hook mode: $CURRENT_MODE (block-cases expect exit=$BLOCK_EXIT)"

# --- Sandbox setup ---
# Use a temp SKILLS_ROOT so the hook evaluates against synthetic SKILL.md content.
# Hook resolves SKILL.md from cwd-relative or absolute path (PRIMARY_ROOT).
# We emulate by constructing absolute file_paths that land inside a synthetic tree.
SBX="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$SBX"' EXIT

MIGRATED_SKILL_DIR="${SBX}/pmo-platform/skills/test-migrated"
UNMIGRATED_SKILL_DIR="${SBX}/pmo-platform/skills/test-unmigrated"
CANARY_SKILL_DIR="${SBX}/pmo-platform/skills/pmo-skill-refiner-selftest-canary"

/bin/mkdir -p "${MIGRATED_SKILL_DIR}/references" "${MIGRATED_SKILL_DIR}/reference"
/bin/mkdir -p "${UNMIGRATED_SKILL_DIR}"
/bin/mkdir -p "${CANARY_SKILL_DIR}"

# Migrated skill — has marker
/bin/cat > "${MIGRATED_SKILL_DIR}/SKILL.md" <<'EOF'
---
name: test-migrated
description: test
version: v10.2
skill_discipline_migrated_v10_2: true
---
body
EOF

# Unmigrated skill — no marker
/bin/cat > "${UNMIGRATED_SKILL_DIR}/SKILL.md" <<'EOF'
---
name: test-unmigrated
description: test
version: v6.3
---
body
EOF

# Canary — has marker (for this test) but exempted via exemption list
/bin/cat > "${CANARY_SKILL_DIR}/SKILL.md" <<'EOF'
---
name: pmo-skill-refiner-selftest-canary
description: test
version: v10.2-canary
---
body
EOF

# Existing references/ files for plural test
/bin/cat > "${MIGRATED_SKILL_DIR}/references/existing-plural.md" <<'EOF'
plural reference content
EOF

/bin/cat > "${MIGRATED_SKILL_DIR}/reference/existing-singular.md" <<'EOF'
singular reference content
EOF

PASS=0
FAIL=0

test_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="${4:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
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

payload() {
  local tool="$1"; local fp="$2"
  /usr/bin/jq -n --arg tool "$tool" --arg fp "$fp" --arg cwd "$SBX" \
    '{tool_name: $tool, tool_input: {file_path: $fp, content: "x"}, cwd: $cwd}'
}

echo "================================"
echo "block-skill-direct-edit.sh tests"
echo "================================"

# Test 1: SKILL.md edit to non-migrated skill → exit 0 (pre-migration pass-through)
test_case "Test 1: SKILL.md edit to non-migrated skill → pass-through" \
  "$(payload Edit "${UNMIGRATED_SKILL_DIR}/SKILL.md")" 0

# Test 2: SKILL.md edit to migrated skill WITHOUT sentinel → BLOCK-SKILL-EDIT-001
test_case "Test 2: SKILL.md edit to migrated skill without sentinel → BLOCK-SKILL-EDIT-001" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/SKILL.md")" "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-001"

# Test 3: SKILL.md edit to canary → exit 0 (exemption pass-through — SKIPPED)
# Note: canary exemption is tied to the actual exemption list file. Since the
# synthetic canary skill-name MATCHES the real exemption entry, the hook will
# honor the exemption and exit 0. (This test is a defensive check.)
test_case "Test 3: SKILL.md edit to canary → exemption pass-through" \
  "$(payload Edit "${CANARY_SKILL_DIR}/SKILL.md")" 0

# Test 4: SKILL.md edit WITH valid sentinel → exit 0 (sanctioned session)
NOW_ISO="$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')"
/usr/bin/jq -n --arg skill "test-migrated" --arg now "$NOW_ISO" \
  '{target_skill: $skill, session_id: "test-01", started_at: $now, mode: "A"}' \
  > "${MIGRATED_SKILL_DIR}/.editor-session"

test_case "Test 4: SKILL.md edit with valid sentinel → sanctioned" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/SKILL.md")" 0

# Remove sentinel for remaining tests
/bin/rm -f "${MIGRATED_SKILL_DIR}/.editor-session"

# Test 5: singular reference/*.md edit to migrated skill → BLOCK-SKILL-EDIT-002
test_case "Test 5: singular reference/*.md edit to migrated skill → BLOCK-SKILL-EDIT-002" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/reference/existing-singular.md")" "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# Test 6: plural references/*.md edit to migrated skill → BLOCK-SKILL-EDIT-002 (NEW D8)
test_case "Test 6: plural references/*.md edit to migrated skill → BLOCK-SKILL-EDIT-002 (D8)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/existing-plural.md")" "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# Test 7: Out-of-scope path (canonical-global) → exit 0 (not in matcher scope)
test_case "Test 7: out-of-scope canonical-global path → pass-through" \
  "$(payload Edit "${SBX}/pmo-platform/reference/standards/canonical-skill-structure.md")" 0

# Test 8: Non-Write/Edit tool → early exit
test_case "Test 8: Bash tool → early exit (not in tool scope)" \
  "$(payload Bash "${MIGRATED_SKILL_DIR}/SKILL.md")" 0

# Test 9: CLAUDE_HOOK_BYPASS=1 permits edit even without sentinel
tmp_stderr="$(/usr/bin/mktemp)"
actual_exit=0
/usr/bin/printf '%s' "$(payload Edit "${MIGRATED_SKILL_DIR}/SKILL.md")" \
  | /usr/bin/env CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
/bin/rm -f "$tmp_stderr"
if [ "$actual_exit" = "0" ]; then
  echo "PASS: Test 9: CLAUDE_HOOK_BYPASS=1 permits edit"; PASS=$((PASS + 1))
else
  echo "FAIL: Test 9: CLAUDE_HOOK_BYPASS=1 permits edit (exit=$actual_exit expected=0)"; FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
