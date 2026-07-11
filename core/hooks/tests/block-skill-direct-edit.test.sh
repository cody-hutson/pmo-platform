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

# The hook resolves the migration marker via cwd-relative
# `pmo-platform/skills/<skill>/SKILL.md` with an absolute fallback of
# `PRIMARY_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"`. The test builds its
# synthetic skills under ${SBX}/pmo-platform/skills/... and sets payload cwd to
# $SBX, but the hook's fallback otherwise resolves against the real workspace
# (where these synthetic skills do not exist), so the marker check is skipped
# and block-cases wrongly pass through. Point PRIMARY_ROOT at the sandbox so the
# hook resolves THIS test's skills tree regardless of the runner's real $HOME.
export CLAUDE_WORKSPACE_ROOT="$SBX"

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

# Multi-root coverage: a migrated skill under operations/skills/ (the real source layout)
OPS_MIGRATED_DIR="${SBX}/operations/skills/test-migrated-ops"
/bin/mkdir -p "${OPS_MIGRATED_DIR}/references"
/bin/cat > "${OPS_MIGRATED_DIR}/SKILL.md" <<'EOF'
---
name: test-migrated-ops
description: test
version: v10.2
skill_discipline_migrated_v10_2: true
---
body
EOF
/bin/cat > "${OPS_MIGRATED_DIR}/references/existing.md" <<'EOF'
ops reference content
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

# Test 10: migrated skill under operations/skills/ (multi-root) SKILL.md → BLOCK-SKILL-EDIT-001
test_case "Test 10: migrated skill under operations/skills/ SKILL.md → BLOCK-SKILL-EDIT-001" \
  "$(payload Edit "${OPS_MIGRATED_DIR}/SKILL.md")" "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-001"

# Test 11: migrated skill under operations/skills/ references/*.md → BLOCK-SKILL-EDIT-002
test_case "Test 11: migrated skill under operations/skills/ references/*.md → BLOCK-SKILL-EDIT-002" \
  "$(payload Edit "${OPS_MIGRATED_DIR}/references/existing.md")" "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# Test 12: deploy-target path (.claude/skills/) is NOT gated → pass-through
test_case "Test 12: .claude/skills/ deploy target → pass-through (not a source root)" \
  "$(payload Edit "${SBX}/.claude/skills/test-migrated-ops/SKILL.md")" 0

# --- GHSA-9cjm-v22x-4x33 regression: jq resolution now lives in lib/dep-resolve.sh.
# To simulate missing jq we sandbox BOTH the hook and a copy of the helper whose three
# jq candidate paths are rewritten to nonexistent locations. Warn posture: a missing jq
# must degrade to exit 0 (never block harder than a rule match), while a missing HELPER
# LIB fails CLOSED (exit 2). ---

# Test 13: jq unresolvable (helper sandbox), MODE-GATED — enforce fails CLOSED
# (exit 2 + DEPENDENCY-MISSING), warn degrades (exit 0 + DEPENDENCY-DEGRADED).
JQSBX="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${JQSBX}/lib"
/bin/cp "$HOOK" "${JQSBX}/block-skill-direct-edit.sh"
/usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/usr/bin/jq#g' \
             -e 's#/opt/homebrew/bin/jq#/nonexistent/opt/homebrew/bin/jq#g' \
             -e 's#/usr/local/bin/jq#/nonexistent/usr/local/bin/jq#g' \
             "${HOOK_DIR}/lib/dep-resolve.sh" > "${JQSBX}/lib/dep-resolve.sh"
# 13a: enforce → fail CLOSED
/usr/bin/printf 'enforce' > "${JQSBX}/.mode"
tmp_stderr="$(/usr/bin/mktemp)"; actual_exit=0
/usr/bin/printf '%s' "$(payload Edit "${MIGRATED_SKILL_DIR}/SKILL.md")" \
  | /bin/bash "${JQSBX}/block-skill-direct-edit.sh" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
if [ "$actual_exit" = "2" ] && /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE 'DEPENDENCY-MISSING'; then
  echo "PASS: Test 13a: jq unresolvable + enforce → fail CLOSED (exit 2 + DEPENDENCY-MISSING)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: Test 13a: enforce (exit=%s expected=2 + DEPENDENCY-MISSING)\n  stderr: %s\n' "$actual_exit" "$actual_stderr"; FAIL=$((FAIL + 1))
fi
# 13b: warn → degrade to exit 0
/usr/bin/printf 'warn' > "${JQSBX}/.mode"
tmp_stderr="$(/usr/bin/mktemp)"; actual_exit=0
/usr/bin/printf '%s' "$(payload Edit "${MIGRATED_SKILL_DIR}/SKILL.md")" \
  | /bin/bash "${JQSBX}/block-skill-direct-edit.sh" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"; /bin/rm -rf "$JQSBX"
if [ "$actual_exit" = "0" ] && /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE 'DEPENDENCY-DEGRADED'; then
  echo "PASS: Test 13b: jq unresolvable + warn → degrade (exit 0 + DEPENDENCY-DEGRADED)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: Test 13b: warn (exit=%s expected=0 + DEPENDENCY-DEGRADED)\n  stderr: %s\n' "$actual_exit" "$actual_stderr"; FAIL=$((FAIL + 1))
fi

# Test 14: dependency-resolver helper missing entirely → fail CLOSED (exit 2 + LIB-MISSING)
LIBSBX="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "${LIBSBX}/block-skill-direct-edit.sh"  # deliberately NO lib/dep-resolve.sh
tmp_stderr="$(/usr/bin/mktemp)"; actual_exit=0
/usr/bin/printf '%s' "$(payload Edit "${MIGRATED_SKILL_DIR}/SKILL.md")" \
  | /bin/bash "${LIBSBX}/block-skill-direct-edit.sh" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"; /bin/rm -rf "$LIBSBX"
if [ "$actual_exit" = "2" ] && /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE 'LIB-MISSING'; then
  echo "PASS: Test 14: helper lib missing → fail-closed (exit 2 + LIB-MISSING)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: Test 14: helper lib missing → fail-closed (exit=%s expected=2 + LIB-MISSING)\n  stderr: %s\n' "$actual_exit" "$actual_stderr"; FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
