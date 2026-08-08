#!/usr/bin/env bash
# test_agent_tools_conformance.sh — regression test for deploy.sh Check 46
# (agent-tools-list-conformance), #189 / v2.23.
#
# WHAT IT GUARDS
#   deploy.sh Check 46 scans release/.claude/agents/pmo-*.md (PMO_AGENTS_DIR_OVERRIDE
#   for fixtures) and emits two findings: (a) a file missing the `tools:` field; (b)
#   a file whose `tools:` line lists a recursion-surface tool (Agent / spawn_task /
#   mcp__ccd_session__spawn_task). This test drives that scan against the fixtures
#   under fixtures/agent-tools-conformance/ and asserts:
#     - ≥2 findings on a "bad" dir (pmo-bad-missing.md + pmo-bad-recursion.md)
#     - 0  findings on a "good" dir (pmo-good.md)
#
# LAYERING NOTE (mirrors test_version_stamping.sh)
#   Check 46 lives inside deploy.sh's cmd_check() — a ~5000-line function that
#   runs ~45 other checks and shells live `gh api`. deploy.sh also runs
#   `main "$@"` unconditionally under `set -euo pipefail`, so it cannot be sourced
#   to isolate one check. Per the sibling deploy-test convention, the Check-46
#   SCAN LOOP is re-implemented here as the unit under test, byte-for-byte the
#   same grep logic + recursion-surface ERE deploy.sh Check 46 uses, driven with
#   controlled fixture inputs. The end-to-end deploy.sh --check behavior (the
#   override pointed at the fixtures during a live --check) is shown in the PR's
#   Verification Evidence; this offline test guards the decision logic so CI can
#   run it credential-free.
#
#   >>> SYNC CONTRACT: the c46_recursion_re pattern + the (a)/(b) finding logic
#   >>> below MUST stay in sync with deploy.sh Check 46. If you change the check's
#   >>> scan logic, change it here too (and vice-versa).
#
# Hermetic + offline: a private sandbox composed from the committed fixtures; no
# network, no operator state touched. Portable: pure bash + BSD/GNU grep; runs on
# macOS CI and Linux alike.
#
# Run from repo root:
#   bash core/deploy/tests/test_agent_tools_conformance.sh
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
FIXTURE_DIR="${SCRIPT_DIR}/fixtures/agent-tools-conformance"

PASS=0
FAIL=0
SBX=""

cleanup() { [ -n "${SBX}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"; FAIL=$((FAIL + 1))
  fi
}

for _req in "${FIXTURE_DIR}/pmo-bad-missing.md" "${FIXTURE_DIR}/pmo-bad-recursion.md" "${FIXTURE_DIR}/pmo-good.md"; do
  if [ ! -r "${_req}" ]; then
    printf 'FATAL: fixture missing at %s\n' "${_req}" >&2
    printf 'test_agent_tools_conformance.sh: 0 passed, 1 failed (fixture missing)\n'
    exit 2
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Unit under test — the Check 46 scan loop (KEEP IN SYNC with deploy.sh Check 46).
# Echoes the finding count for the agents dir passed as $1.
# ─────────────────────────────────────────────────────────────────────────────
c46_recursion_re='(^|[[:space:],])(Agent|spawn_task|mcp__ccd_session__spawn_task)([[:space:],]|$)'

count_findings() {
  local agents_dir="$1"
  local findings=0
  local _agent_file _tools_line
  for _agent_file in "$agents_dir"/pmo-*.md; do
    [ -f "$_agent_file" ] || continue
    _tools_line=$(grep -m1 -E '^tools:' "$_agent_file" 2>/dev/null ) || _tools_line=""
    if [ -z "$_tools_line" ]; then
      findings=$((findings + 1))                                  # finding (a)
    elif grep -qE "$c46_recursion_re" <<<"$_tools_line"; then
      findings=$((findings + 1))                                  # finding (b)
    fi
  done
  printf '%s' "$findings"
}

SBX="$(mktemp -d -t agent-tools-conformance.XXXXXX)"
printf '\nagent-tools-list-conformance (Check 46) regression (#189) (bash %s)\n' "${BASH_VERSION:-unknown}"

# Compose a BAD dir (both bad fixtures) and a GOOD dir (only the good fixture),
# exercising deploy.sh's PMO_AGENTS_DIR_OVERRIDE fixture seam by pointing the scan
# at each.
BAD_DIR="${SBX}/bad"; GOOD_DIR="${SBX}/good"
mkdir -p "$BAD_DIR" "$GOOD_DIR"
cp "${FIXTURE_DIR}/pmo-bad-missing.md" "${FIXTURE_DIR}/pmo-bad-recursion.md" "$BAD_DIR/"
cp "${FIXTURE_DIR}/pmo-good.md" "$GOOD_DIR/"

# ── Part 1 — BAD dir yields ≥2 findings (missing tools: + recursion surface) ──
BAD_N="$(count_findings "$BAD_DIR")"
if [ "$BAD_N" -ge 2 ]; then
  report "bad fixture dir yields ≥2 findings (got ${BAD_N})" 1
else
  report "bad fixture dir yields ≥2 findings" 0 "expected ≥2, got ${BAD_N}"
fi

# Per-fixture precision: confirm each bad fixture is individually a finding.
ONLY_MISS="${SBX}/only-miss"; mkdir -p "$ONLY_MISS"; cp "${FIXTURE_DIR}/pmo-bad-missing.md" "$ONLY_MISS/"
if [ "$(count_findings "$ONLY_MISS")" -eq 1 ]; then
  report "finding (a): missing-tools fixture flags (1 finding)" 1
else
  report "finding (a): missing-tools fixture flags" 0 "expected 1, got $(count_findings "$ONLY_MISS")"
fi
ONLY_REC="${SBX}/only-rec"; mkdir -p "$ONLY_REC"; cp "${FIXTURE_DIR}/pmo-bad-recursion.md" "$ONLY_REC/"
if [ "$(count_findings "$ONLY_REC")" -eq 1 ]; then
  report "finding (b): recursion-surface fixture flags (1 finding)" 1
else
  report "finding (b): recursion-surface fixture flags" 0 "expected 1, got $(count_findings "$ONLY_REC")"
fi

# ── Part 2 — GOOD dir yields 0 findings ──
GOOD_N="$(count_findings "$GOOD_DIR")"
if [ "$GOOD_N" -eq 0 ]; then
  report "good fixture dir yields 0 findings" 1
else
  report "good fixture dir yields 0 findings" 0 "expected 0, got ${GOOD_N}"
fi

# ── Part 3 — the deployed deploy.sh Check 46 actually carries this token (AC2) ──
if grep -qE 'agent-tools-list-conformance' "${REPO_ROOT}/core/deploy/deploy.sh"; then
  report "deploy.sh Check 46 token present (AC2 grep)" 1
else
  report "deploy.sh Check 46 token present (AC2 grep)" 0 "agent-tools-list-conformance not found in deploy.sh"
fi

# ── Part 4 — POSIX-ERE discipline: the recursion pattern carries no `\b` ──
if grep -nE 'Agent\|spawn_task\|mcp__ccd_session__spawn_task' "${REPO_ROOT}/core/deploy/deploy.sh" | grep -q '\\b'; then
  report "Check 46 recursion ERE is POSIX (no \\b)" 0 "found a \\b in the Check 46 recursion pattern"
else
  report "Check 46 recursion ERE is POSIX (no \\b)" 1
fi

printf '\ntest_agent_tools_conformance.sh: %d passed, %d failed\n' "${PASS}" "${FAIL}"
[ "${FAIL}" -eq 0 ] || exit 1
exit 0
