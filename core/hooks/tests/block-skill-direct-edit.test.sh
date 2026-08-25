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

# ============================================================================
# #4977 — nested reference subtrees are in scope (regression arm)
#
# The scope regex matched `references?/[^/]+\.md$` — exactly ONE path segment below
# the reference dir. Every nested reference subtree was therefore outside the gate
# entirely: 12 behavior-defining files across three MIGRATED skills — build-reviewer
# (references/dimension-packs/), implementation-planner (references/domain-packs/), and
# pmo-wms-specialist (references/corpus/) — could be written directly, with no editor
# session and no audit trailer. A dimension pack IS the skill's review behavior; a
# domain pack IS its classification behavior. The single-level form read as correct for
# exactly as long as no skill nested its references, so it needs a pin, not a re-count:
# pack-per-subdirectory is how these skills grow.
#
# Both directions are pinned. Tests 15-18 (must-block) all FAIL against the single-level
# matcher — they are the regression pin proper. Tests 19-23 (must-NOT-block) bound the
# false-positive surface, which is the risk a WIDENING actually carries. Because those
# five pass against the old matcher too, they would hold vacuously on their own; tests
# 24-25 are their control, asserting that a deliberately over-wide matcher DOES fire on
# the same paths. If a control stops firing, the specificity arm it guards has gone
# uninformative and the suite says so rather than staying green.
# ============================================================================

# Nested fixtures under the migrated skill (plural + singular reference dirs).
/bin/mkdir -p "${MIGRATED_SKILL_DIR}/references/dimension-packs"
/bin/mkdir -p "${MIGRATED_SKILL_DIR}/references/corpus/deep"
/bin/mkdir -p "${MIGRATED_SKILL_DIR}/reference/nested"
/bin/mkdir -p "${MIGRATED_SKILL_DIR}/templates/nested"
/usr/bin/printf 'pack\n'  > "${MIGRATED_SKILL_DIR}/references/dimension-packs/pmo-platform-dimensions.md"
/usr/bin/printf 'readme\n'> "${MIGRATED_SKILL_DIR}/references/dimension-packs/README.md"
/usr/bin/printf '{}\n'    > "${MIGRATED_SKILL_DIR}/references/dimension-packs/pack-config.json"
/usr/bin/printf 'deep\n'  > "${MIGRATED_SKILL_DIR}/references/corpus/deep/runbook.md"
/usr/bin/printf 'sing\n'  > "${MIGRATED_SKILL_DIR}/reference/nested/nested-singular.md"
/usr/bin/printf 'tmpl\n'  > "${MIGRATED_SKILL_DIR}/templates/nested/tmpl.md"

# Nested fixture under the UNMIGRATED skill — the pre-migration pass-through must
# still win over the widened scope.
/bin/mkdir -p "${UNMIGRATED_SKILL_DIR}/references/domain-packs"
/usr/bin/printf 'pack\n' > "${UNMIGRATED_SKILL_DIR}/references/domain-packs/x.md"

# Nested fixtures OUTSIDE the four source roots — deploy target, and a non-root tree
# that merely contains a `skills/` directory.
/bin/mkdir -p "${SBX}/.claude/skills/test-migrated-ops/references/dimension-packs"
/usr/bin/printf 'pack\n' > "${SBX}/.claude/skills/test-migrated-ops/references/dimension-packs/x.md"
/bin/mkdir -p "${SBX}/docs/skills/test-migrated/references/dimension-packs"
/usr/bin/printf 'pack\n' > "${SBX}/docs/skills/test-migrated/references/dimension-packs/x.md"

# Absence-asserting variant of test_case: pins exit code AND that the rule marker is
# NOT emitted. The existing helper only asserts a pattern's PRESENCE, so a must-NOT-block
# arm written with it would assert nothing in warn mode, where a real block also exits 0.
test_case_absent() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local forbidden_pattern="$4"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != "$expected_exit" ] && ok=0
  if /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "$forbidden_pattern"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s, forbidden=%s)\n  stderr: %s\n' \
      "$name" "$actual_exit" "$expected_exit" "$forbidden_pattern" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

# --- MUST BLOCK (15-18): these four fail against the single-level matcher ---

# Test 15: nested pack file, depth 2 below references/ → BLOCK-SKILL-EDIT-002
test_case "Test 15: nested references/dimension-packs/*.md → BLOCK-SKILL-EDIT-002 (#4977)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/dimension-packs/pmo-platform-dimensions.md")" \
  "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# Test 16: nested README.md — accepted-and-documented per #4977 AC-4. The two nested
# READMEs in the real corpus (dimension-packs/, domain-packs/) document how to author the
# packs beside them, so gating them is the intended reading, not a tolerated false
# positive. Pinned so the decision is visible rather than incidental.
test_case "Test 16: nested references/dimension-packs/README.md → BLOCK-SKILL-EDIT-002 (#4977 AC-4)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/dimension-packs/README.md")" \
  "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# Test 17: depth 3 — the matcher is depth-agnostic, not depth-2-special-cased.
test_case "Test 17: references/corpus/deep/*.md (depth 3) → BLOCK-SKILL-EDIT-002 (#4977)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/corpus/deep/runbook.md")" \
  "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# Test 18: the singular reference/ dir nests too — the references? alternation must
# survive the widening rather than being silently narrowed to plural-only.
test_case "Test 18: nested singular reference/nested/*.md → BLOCK-SKILL-EDIT-002 (#4977)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/reference/nested/nested-singular.md")" \
  "$BLOCK_EXIT" "BLOCK-SKILL-EDIT-002"

# --- MUST NOT BLOCK (19-23): the false-positive surface of the widening ---

# Test 19: non-markdown nested asset — the \.md$ anchor still bounds the branch.
test_case_absent "Test 19: nested pack-config.json → pass-through (.md anchor holds)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/dimension-packs/pack-config.json")" \
  0 "BLOCK-SKILL-EDIT-00[12]"

# Test 20: nested .md in a SIBLING subtree of the skill — the reference[s]/ segment is
# still required, so the widening did not leak into templates/, assets/, or tests/.
test_case_absent "Test 20: skills/<skill>/templates/nested/*.md → pass-through (not a reference dir)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/templates/nested/tmpl.md")" \
  0 "BLOCK-SKILL-EDIT-00[12]"

# Test 21: nested reference file under an UNMIGRATED skill — pre-migration pass-through
# still precedes the gate. Widening scope must not activate the gate on unmigrated skills.
test_case_absent "Test 21: unmigrated skill, nested references/domain-packs/*.md → pass-through" \
  "$(payload Edit "${UNMIGRATED_SKILL_DIR}/references/domain-packs/x.md")" \
  0 "BLOCK-SKILL-EDIT-00[12]"

# Test 22: deploy target — .claude/skills/ is not a source root at any nesting depth.
test_case_absent "Test 22: .claude/skills/**/references/**/*.md → pass-through (deploy target)" \
  "$(payload Edit "${SBX}/.claude/skills/test-migrated-ops/references/dimension-packs/x.md")" \
  0 "BLOCK-SKILL-EDIT-00[12]"

# Test 23: a `skills/` tree under a non-source root — the root alternation still anchors.
test_case_absent "Test 23: docs/skills/**/references/**/*.md → pass-through (not a source root)" \
  "$(payload Edit "${SBX}/docs/skills/test-migrated/references/dimension-packs/x.md")" \
  0 "BLOCK-SKILL-EDIT-00[12]"

# --- CONTROL (24-25): prove tests 19-23 are not vacuous ---
# Run the hook with SKILL_SCOPE_RE mutated and everything else byte-identical. An
# over-wide matcher MUST fire on the very paths the shipped matcher passes through; if
# it does not, the specificity arms above are asserting nothing and this suite fails.

mutant_stderr() {
  local mutant_re="$1"; local fp="$2"
  local msbx; msbx="$(/usr/bin/mktemp -d)"
  /bin/mkdir -p "${msbx}/lib"
  /bin/cp "${HOOK_DIR}"/lib/*.sh "${msbx}/lib/" 2>/dev/null || true
  [ -f "${HOOK_DIR}/.mode" ] && /bin/cp "${HOOK_DIR}/.mode" "${msbx}/.mode"
  /usr/bin/sed "s#^SKILL_SCOPE_RE=.*#SKILL_SCOPE_RE='${mutant_re}'#" "$HOOK" \
    > "${msbx}/block-skill-direct-edit.sh"
  local out
  out="$(/usr/bin/printf '%s' "$(payload Edit "$fp")" \
    | /bin/bash "${msbx}/block-skill-direct-edit.sh" 2>&1 >/dev/null || true)"
  /bin/rm -rf "$msbx"
  /usr/bin/printf '%s' "$out"
}

# Test 24 control for Test 20: drop the reference[s]/ requirement → sibling subtree fires.
MUT_NO_REFDIR='(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|.+\.md)$'
mut_out="$(mutant_stderr "$MUT_NO_REFDIR" "${MIGRATED_SKILL_DIR}/templates/nested/tmpl.md")"
if /usr/bin/printf '%s' "$mut_out" | /usr/bin/grep -qE 'BLOCK-SKILL-EDIT-002'; then
  echo "PASS: Test 24 (control): reference-dir-blind matcher DOES block templates/ — Test 20 is informative"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: Test 24 (control): over-wide matcher did NOT fire on templates/nested/tmpl.md — Test 20 is vacuous\n  stderr: %s\n' "$mut_out"
  FAIL=$((FAIL + 1))
fi

# Test 25 control for Test 19: drop the \.md$ anchor → the JSON asset fires.
MUT_NO_MD='(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+)$'
mut_out="$(mutant_stderr "$MUT_NO_MD" "${MIGRATED_SKILL_DIR}/references/dimension-packs/pack-config.json")"
if /usr/bin/printf '%s' "$mut_out" | /usr/bin/grep -qE 'BLOCK-SKILL-EDIT-002'; then
  echo "PASS: Test 25 (control): extension-blind matcher DOES block pack-config.json — Test 19 is informative"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: Test 25 (control): over-wide matcher did NOT fire on pack-config.json — Test 19 is vacuous\n  stderr: %s\n' "$mut_out"
  FAIL=$((FAIL + 1))
fi

# Test 26: the sanctioned editor session must reach nested files too. A widened gate with
# no satisfiable path would convert under-enforcement into a work stoppage — the exact
# composition failure #5515 recorded one slice earlier.
/usr/bin/jq -n --arg skill "test-migrated" --arg now "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  '{target_skill: $skill, session_id: "test-4977", started_at: $now, mode: "A"}' \
  > "${MIGRATED_SKILL_DIR}/.editor-session"
test_case_absent "Test 26: nested pack edit WITH valid sentinel → sanctioned (#4977)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/dimension-packs/pmo-platform-dimensions.md")" \
  0 "BLOCK-SKILL-EDIT-00[12]"
/bin/rm -f "${MIGRATED_SKILL_DIR}/.editor-session"

# --- EXTRACTION (27-28): WHICH skill directory the in-scope path resolves to ---
# Tests 15-26 pin WHETHER a nested path is in scope. Nothing pinned WHICH skill the hook
# then resolved it to, and the two came apart once `.+` admitted `/`: an in-scope path may
# carry a further <root>/skills/<segment> inside its reference subtree, and the greedy
# extraction anchored on the LAST one. skill_dir and skill then address a directory that
# does not exist, so the sentinel, target-skill and exemption lookups all address the wrong
# skill — which is the work stoppage Test 26 exists to prevent, arriving by a different
# route: a valid test-migrated session cannot satisfy this gate, because the gate is not
# looking at test-migrated. Reachability in the corpus is currently 0; these arms are the
# reason it stays a non-event if a pack ever nests such a subtree.
#
# Both arms read the extracted skill_dir out of the block message, which interpolates it,
# so they assert the resolved VALUE and not merely that something fired. Fixed-string
# matching (grep -F): the sandbox path is interpolated and must not be read as a regex.
test_case_extraction() {
  local name="$1"; local payload="$2"; local expected_exit="$3"
  local required="$4"; local forbidden="$5"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != "$expected_exit" ] && ok=0
  if ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qF "$required"; then ok=0; fi
  if [ -n "$forbidden" ] && /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qF "$forbidden"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  required: %s\n  forbidden: %s\n  stderr: %s\n' \
      "$name" "$actual_exit" "$expected_exit" "$required" "${forbidden:-<none>}" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

# Test 27 (MUST PASS — fails against the greedy extraction): a reference subtree that
# itself contains <root>/skills/<segment>. The edit belongs to test-migrated; the trailing
# `core/skills/other` is reference CONTENT, not a skill directory. Measured against the
# greedy form, the hook still exits 2 with BLOCK-SKILL-EDIT-002 — so exit code and rule
# marker BOTH look correct — while naming
#   .../test-migrated/references/core/skills/other/.editor-session
# as the session it wanted. That is why this arm asserts the resolved directory and not
# the verdict: the verdict was never the part that broke.
test_case_extraction "Test 27: nested references/core/skills/**/*.md → resolves to test-migrated, not the inner segment" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/core/skills/other/x.md")" \
  "$BLOCK_EXIT" \
  "${MIGRATED_SKILL_DIR}/.editor-session" \
  "${MIGRATED_SKILL_DIR}/references/core/skills/other/.editor-session"

# Test 28 (NON-REGRESSION — passes both before and after): the ordinary single-`skills/`
# path must keep resolving exactly as it did. Test 27 changes how skill_dir is computed for
# every in-scope path, not only nested ones, so the unnested case needs its resolved value
# pinned too rather than inferred from Test 15 still being green.
test_case_extraction "Test 28: ordinary references/dimension-packs/*.md → resolves to test-migrated (non-regression)" \
  "$(payload Edit "${MIGRATED_SKILL_DIR}/references/dimension-packs/pmo-platform-dimensions.md")" \
  "$BLOCK_EXIT" \
  "${MIGRATED_SKILL_DIR}/.editor-session" \
  ""

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
