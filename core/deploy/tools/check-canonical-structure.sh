#!/bin/bash
# Check 6 (canonical-structure compliance) predicate — SINGLE SOURCE.
#
# This is the extracted, single-sourced implementation of deploy.sh Check 6.
# Both consumers invoke THIS script so the predicate cannot drift between the
# deploy-time check and its PR-time CI mirror:
#
#   1. core/deploy/deploy.sh  Check 6  (deploy-time, operator-machine safety net)
#   2. .github/workflows/skill-canonical-structure-check.yml  (PR-time gate)
#
# Per core/standards/gate-efficacy-standard.md Requirement (b′): a `required`
# gate must be CI-enforced, not deploy-time-only. Check 6 was always-enforce
# *per run* but had no automatic run surface (the run-context gap #673 names) —
# its predicates and iteration set were already correct (proven byte-identical
# since v1.09), so the fix is purely to give the existing predicate an automatic
# trigger via this shared invokable + a CI mirror, NOT to change the predicate.
#
# Invariant asserted (BYTE-ALIGNED with the historical deploy.sh Check-6 block):
#   For every rostered skill (OPERATIONS_SKILLS + RELEASE_SKILLS + CORE_SKILLS):
#     (a) required frontmatter fields present: name, description, version
#     (b) D-Refs threshold (per the D-Refs Option B decision): when SKILL.md
#         > 400 lines OR > 25600 bytes, a non-empty references/ subdir is REQUIRED
#     (c) failure-mode floor: ≥ 3 entries matching the 5-category heading pattern
#         (per core/standards/failure-mode-standard.md + pmo-qa-auditor G7)
#   An EXEMPTION_LIST member is exempt from the D-Refs threshold (canary-by-design)
#   but the required-frontmatter check still applies (mirrors the deploy.sh order:
#   the version-presence loop runs BEFORE the exemption pass-through, so the
#   exemption cannot suppress a missing-field FAIL).
#
# Single-sourcing of the ROSTER: the per-module skill arrays are extracted from
# deploy.sh at runtime (the same awk idiom build-skill-packages.sh uses to extract
# TEMPLATE_SYNC_MAP) — never a hardcoded name list here, so this predicate cannot
# drift from the deploy.sh roster authority that Check 5 reconciles against disk.
#
# Usage:
#   bash core/deploy/tools/check-canonical-structure.sh            # scan full roster
#   bash core/deploy/tools/check-canonical-structure.sh --self-test
#
# Output: one OK/FAIL line per skill on stdout; a trailing summary line.
# Exit codes:
#   0 — every rostered skill is canonical-structure compliant
#   1 — one or more FAILs (the count is in the summary line)
#   2 — usage error
#   3 — scan-surface error (could not extract the roster from deploy.sh, or a
#       roster skill's SKILL.md is missing) — a fail-loud condition the CI mirror
#       treats as hard-fail regardless of warn-mode, so a relocated source tree
#       can never read green.

set -uo pipefail

# Run from repo root regardless of cwd (matches build-skill-packages.sh).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ─── D-Refs thresholds (BYTE-ALIGNED with deploy.sh Check 6) ──────────────────
# Keep these two literals in lockstep with the deploy.sh Check-6 block. They are
# the pre-existing, canonical thresholds — this script does not invent new ones.
C6_LINE_THRESHOLD=400
C6_BYTE_THRESHOLD=25600
C6_FM_FLOOR=3
# Failure-mode heading pattern (BYTE-ALIGNED with deploy.sh Check 6).
C6_FM_RE='^### .+ — (TRIG|INPUT|PROC|OUT|HAND)[[:space:]]*$'

# resolve_skill_module — mirrors deploy.sh resolve_skill_module() (and the copy in
# build-skill-packages.sh). Bash 3.2 portable (default macOS bash). Echoes the
# module dir; returns non-zero on miss (callers treat a miss as a scan error).
resolve_skill_module() {
  local skill="$1"
  case "$skill" in
    eval-writer|pmo-qa-auditor|prompt-builder) echo "core"; return 0 ;;
    pmo-architect|pmo-devops-sre|pmo-principal-engineer|pmo-qa-lead|pmo-software-engineer|pmo-skill-refiner|pmo-skill-refiner-selftest-canary|pmo-skill-editor|build-reviewer|release-executor|release-planner|implementation-planner) echo "release"; return 0 ;;
    *) echo "operations"; return 0 ;;
  esac
}

# extract_roster_array — pull a named bash array literal out of deploy.sh at
# runtime and print one element per line. Single source of truth for the roster:
# Check 5 (deploy.sh) asserts these same arrays match the on-disk skill dirs, so
# extracting them here keeps this predicate's iteration set identical to the
# deploy-time check's. Same awk-window + sed-clean idiom build-skill-packages.sh
# uses for TEMPLATE_SYNC_MAP, generalized to take the array name.
#   $1 — array name (e.g. OPERATIONS_SKILLS)
#   $2 — path to deploy.sh
extract_roster_array() {
  local array_name="$1" deploy_sh="$2"
  awk -v name="$array_name" '
    $0 ~ ("^" name "=\\(") { capture=1; next }
    capture && /^\)/        { capture=0 }
    capture {
      line=$0
      sub(/#.*/, "", line)                       # strip trailing comments
      gsub(/[[:space:]]/, "", line)              # strip whitespace
      if (line != "") print line
    }
  ' "$deploy_sh"
}

# check_one_skill — apply the Check-6 predicate to a single skill. Echoes one
# "OK:    <skill>" or "FAIL:  <skill> — <reason>" line per finding. Returns the
# number of FAILs for this skill (0 = compliant) via the global FAIL_DELTA, and
# the function's own return code (0 compliant / 1 has-fail / 3 missing-file).
check_one_skill() {
  local skill="$1" exemption_list="$2"
  local module src
  module="$(resolve_skill_module "$skill")"
  src="$REPO_ROOT/$module/skills/$skill/SKILL.md"

  if [[ ! -f "$src" ]]; then
    echo "FAIL:  $skill — SKILL.md missing"
    return 3
  fi

  local skill_ok=true had_fail=0

  # (a) Required frontmatter fields (presence). Runs FIRST — BEFORE the exemption
  # pass-through — so an exemption can never suppress a missing-field FAIL (the
  # exact ordering deploy.sh Check 6 uses).
  local field
  for field in name description version; do
    if ! grep -qE "^${field}:" "$src"; then
      echo "FAIL:  $skill — missing required frontmatter field '$field'"
      skill_ok=false
      had_fail=1
    fi
  done

  # Exemption pass-through (canary-by-design): exempt from the D-Refs threshold
  # only. The frontmatter check above already ran.
  if [[ -n "$exemption_list" && -f "$exemption_list" ]] && grep -Fxq "$skill" "$exemption_list" 2>/dev/null; then
    [[ "$skill_ok" == "true" ]] && echo "OK:    $skill (exempted from threshold)"
    [[ "$had_fail" -eq 1 ]] && return 1
    return 0
  fi

  # (b) D-Refs threshold evaluation.
  local lines bytes fm_count
  lines=$(wc -l < "$src" | tr -d ' ')
  bytes=$(wc -c < "$src" | tr -d ' ')
  fm_count=$(grep -cE "$C6_FM_RE" "$src" || true)

  local refs_required=false
  [[ $lines -gt $C6_LINE_THRESHOLD ]] && refs_required=true
  [[ $bytes -gt $C6_BYTE_THRESHOLD ]] && refs_required=true

  if [[ "$refs_required" == "true" ]]; then
    local ref_dir="$REPO_ROOT/$module/skills/$skill/references"
    if [[ ! -d "$ref_dir" ]] || [[ -z "$(find "$ref_dir" -name '*.md' -type f 2>/dev/null | head -1)" ]]; then
      echo "FAIL:  $skill — D-Refs threshold crossed (lines=$lines bytes=$bytes fm=$fm_count); references/ subdir missing or empty"
      skill_ok=false
      had_fail=1
    fi
  fi

  # (c) Failure-mode floor (≥ 3).
  if [[ $fm_count -lt $C6_FM_FLOOR ]]; then
    echo "FAIL:  $skill — ## Domain-Specific Failure Modes has $fm_count entries (< $C6_FM_FLOOR floor per failure-mode-standard.md)"
    skill_ok=false
    had_fail=1
  fi

  [[ "$skill_ok" == "true" ]] && echo "OK:    $skill"
  [[ "$had_fail" -eq 1 ]] && return 1
  return 0
}

# run_check — scan the full roster extracted from deploy.sh. Echoes per-skill
# lines + a summary; sets the process exit code.
#   $1 — repo root (so the self-test can point at a fixture tree)
#   $2 — path to deploy.sh (roster source)
#   $3 — exemption list path (may be empty / nonexistent)
run_check() {
  local repo_root="$1" deploy_sh="$2" exemption_list="$3"
  REPO_ROOT="$repo_root"

  if [[ ! -f "$deploy_sh" ]]; then
    echo "FAIL:  scan-surface error — roster source not found: $deploy_sh" >&2
    return 3
  fi

  local -a roster=()
  local arr line
  for arr in OPERATIONS_SKILLS RELEASE_SKILLS CORE_SKILLS; do
    while IFS= read -r line; do
      [[ -n "$line" ]] && roster+=("$line")
    done < <(extract_roster_array "$arr" "$deploy_sh")
  done

  if [[ ${#roster[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — extracted an EMPTY roster from $deploy_sh (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS). A relocated or restructured deploy.sh must not read green." >&2
    return 3
  fi

  local fails=0 missing=0 skill rc
  for skill in "${roster[@]}"; do
    check_one_skill "$skill" "$exemption_list"
    rc=$?
    if [[ $rc -eq 3 ]]; then
      missing=$((missing + 1))
      fails=$((fails + 1))
    elif [[ $rc -eq 1 ]]; then
      fails=$((fails + 1))
    fi
  done

  if [[ $missing -gt 0 ]]; then
    echo "SUMMARY: ${#roster[@]} skills scanned; $fails FAIL ($missing with a missing SKILL.md — scan-surface error)"
    return 3
  fi
  if [[ $fails -gt 0 ]]; then
    echo "SUMMARY: ${#roster[@]} skills scanned; $fails FAIL"
    return 1
  fi
  echo "SUMMARY: ${#roster[@]} skills scanned; 0 FAIL (all canonical-structure compliant)"
  return 0
}

# ─── Self-test ────────────────────────────────────────────────────────────────
# Per the precision-probe contract the other two CI mirrors carry
# (check-skill-count-imp.py --self-test, check-doc-links.py --self-test): a
# warn-mode scan is blind to a detector regression, so the CI step hard-fails on
# a self-test miss independent of warn-mode. Builds a throwaway fixture tree with
# a stub deploy.sh roster and asserts each predicate branch flips as designed.
self_test() {
  local tmp pass=0
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # Minimal fixture: a stub deploy.sh exposing a one-skill roster, and a fixture
  # skill tree we mutate per assertion. resolve_skill_module maps any unknown
  # name to operations/, so a fixture skill name lands under operations/skills/.
  mkdir -p "$tmp/operations/skills/fixtureskill"
  cat > "$tmp/deploy.sh" <<'STUB'
OPERATIONS_SKILLS=(
  fixtureskill
)
RELEASE_SKILLS=(
)
CORE_SKILLS=(
)
STUB

  local fx="$tmp/operations/skills/fixtureskill/SKILL.md"

  # Helper: write a compliant small SKILL.md (under thresholds, 3 failure modes,
  # all frontmatter). Failure-mode headings match C6_FM_RE.
  _write_compliant() {
    {
      echo "---"
      echo "name: fixtureskill"
      echo "description: fixture"
      echo "version: v1.00"
      echo "---"
      echo "# Fixture"
      echo "## Domain-Specific Failure Modes"
      echo "### A thing goes wrong — TRIG"
      echo "body"
      echo "### Another thing — INPUT"
      echo "body"
      echo "### A third thing — PROC"
      echo "body"
    } > "$fx"
  }

  # Assertion 1: compliant fixture → exit 0.
  _write_compliant
  if run_check "$tmp" "$tmp/deploy.sh" "" >/dev/null 2>&1; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: compliant fixture did not pass (expected exit 0)" >&2
    return 1
  fi

  # Assertion 2: remove the version: field → exit 1 (missing-field FAIL).
  _write_compliant
  grep -v '^version:' "$fx" > "$fx.tmp" && mv "$fx.tmp" "$fx"
  run_check "$tmp" "$tmp/deploy.sh" "" >/dev/null 2>&1
  if [[ $? -eq 1 ]]; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: missing 'version:' field did not turn the check red (expected exit 1)" >&2
    return 1
  fi

  # Assertion 3: over the line threshold with NO references/ → exit 1.
  _write_compliant
  local i
  for ((i=0; i<C6_LINE_THRESHOLD + 5; i++)); do echo "padding line $i" >> "$fx"; done
  run_check "$tmp" "$tmp/deploy.sh" "" >/dev/null 2>&1
  if [[ $? -eq 1 ]]; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: over-threshold SKILL.md without references/ did not turn the check red (expected exit 1)" >&2
    return 1
  fi

  # Assertion 4: same over-threshold SKILL.md but WITH a non-empty references/
  # → exit 0 (the references/ adjacency satisfies the D-Refs requirement).
  mkdir -p "$tmp/operations/skills/fixtureskill/references"
  echo "# extracted" > "$tmp/operations/skills/fixtureskill/references/extracted.md"
  if run_check "$tmp" "$tmp/deploy.sh" "" >/dev/null 2>&1; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: over-threshold SKILL.md WITH references/ did not pass (expected exit 0)" >&2
    return 1
  fi
  rm -rf "$tmp/operations/skills/fixtureskill/references"

  # Assertion 5: drop below the failure-mode floor (only 2 entries) → exit 1.
  {
    echo "---"
    echo "name: fixtureskill"
    echo "description: fixture"
    echo "version: v1.00"
    echo "---"
    echo "# Fixture"
    echo "## Domain-Specific Failure Modes"
    echo "### Only one — TRIG"
    echo "body"
    echo "### Only two — INPUT"
    echo "body"
  } > "$fx"
  run_check "$tmp" "$tmp/deploy.sh" "" >/dev/null 2>&1
  if [[ $? -eq 1 ]]; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: below-floor failure-mode count did not turn the check red (expected exit 1)" >&2
    return 1
  fi

  # Assertion 6: empty roster extraction → exit 3 (scan-surface error, fail-loud).
  cat > "$tmp/deploy-empty.sh" <<'STUB'
OPERATIONS_SKILLS=(
)
RELEASE_SKILLS=(
)
CORE_SKILLS=(
)
STUB
  run_check "$tmp" "$tmp/deploy-empty.sh" "" >/dev/null 2>&1
  if [[ $? -eq 3 ]]; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: empty roster did not produce a scan-surface error (expected exit 3)" >&2
    return 1
  fi

  echo "self-test OK ($pass assertions passed)"
  return 0
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
main() {
  case "${1:-}" in
    --self-test)
      self_test
      exit $?
      ;;
    "")
      # Default: scan the live roster. EXEMPTION_LIST mirrors deploy.sh Check 6:
      # operator-instance path via env var, fallback to the legacy .claude path.
      local exemption_list="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/skill-editor-exemption-list.txt"
      [[ -f "$exemption_list" ]] || exemption_list="$REPO_ROOT/.claude/skill-editor-exemption-list.txt"
      [[ -f "$exemption_list" ]] || exemption_list=""
      run_check "$REPO_ROOT" "$REPO_ROOT/core/deploy/deploy.sh" "$exemption_list"
      exit $?
      ;;
    *)
      echo "Usage: bash core/deploy/tools/check-canonical-structure.sh [--self-test]" >&2
      exit 2
      ;;
  esac
}

main "$@"
