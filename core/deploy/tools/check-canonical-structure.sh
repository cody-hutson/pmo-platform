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
# Single-sourcing of the ROSTER *and* module RESOLUTION: the per-module skill
# arrays are extracted from deploy.sh at runtime (the same awk idiom
# build-skill-packages.sh uses to extract TEMPLATE_SYNC_MAP) — never a hardcoded
# name list here. Both the scan set AND resolve_skill_module() consume those same
# extracted arrays (the resolver iterates them rather than a hardcoded case map),
# so neither the iteration set nor the skill→module map can drift from the
# deploy.sh roster authority that Check 5 reconciles against disk.
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

# Single resolver for the operator-instance path (sibling of deploy.sh). Used by
# the exemption-list resolution below instead of the hardcoded instance default
# (#1830). Mirrors deploy.sh Check 6.
# shellcheck source=../lib-instance-path.sh disable=SC1091
source "${SCRIPT_DIR}/../lib-instance-path.sh"

# ─── D-Refs thresholds (BYTE-ALIGNED with deploy.sh Check 6) ──────────────────
# Keep these two literals in lockstep with the deploy.sh Check-6 block. They are
# the pre-existing, canonical thresholds — this script does not invent new ones.
C6_LINE_THRESHOLD=400
C6_BYTE_THRESHOLD=25600
C6_FM_FLOOR=3
# Failure-mode heading pattern (BYTE-ALIGNED with deploy.sh Check 6).
C6_FM_RE='^### .+ — (TRIG|INPUT|PROC|OUT|HAND)[[:space:]]*$'
# Skill version-field format. SINGLE SOURCE: core/standards/version-field-semantics.md
# § Format — this literal MIRRORS that section rather than inventing a grammar;
# keep the two in lockstep and change neither alone. vMAJOR.MINOR with an optional
# single lowercase sentinel suffix (the -canary sentinel per ADR-04, which this
# grammar admits by construction — the canary is exempt from the D-Refs threshold
# only, never from the version-field requirement).
#
# NOT the release-tag grammar. Release tags admit a 3-component patch form
# (release/tools/version-grammar.sh) that a skill version: field forbids outright,
# because skills sync to platform MINOR versions, not to patches. The two grammars
# govern different objects and their divergence is deliberate.
C6_VERSION_RE='^v[0-9]+\.[0-9]+(-[a-z]+)?$'

# Per-module skill arrays — populated at runtime by run_check() from deploy.sh
# (the same extract_roster_array helper that builds the scan roster). Declared
# empty here at file scope so resolve_skill_module() can reference them under
# `set -u` before the first populate (the `${#ARR[@]} -gt 0` guards make an empty
# array safe). Single-sourcing these means module resolution iterates the exact
# deploy.sh roster the scan does — the hardcoded case map this replaces silently
# drifted whenever a release/core skill was added without a matching case arm (it
# fell through to the operations default, the predicate looked for SKILL.md under
# operations/skills/, and the Check 6 mirror failed loud as exit 3).
OPERATIONS_SKILLS=()
RELEASE_SKILLS=()
CORE_SKILLS=()
CANARY_SKILLS=()

# resolve_skill_module — mirrors deploy.sh resolve_skill_module(): iterate the
# per-module arrays (populated from deploy.sh by run_check via extract_roster_array)
# and echo the module the skill belongs to. CANARY_SKILLS classifies to release/
# (the canary is the canary for the release-side pmo-skill-refiner). Bash 3.2
# portable — explicit per-array iteration with `${#ARR[@]} -gt 0` empty-guards
# (ADR-008 Rule 2); no `local -n` nameref (bash 4.3+). Echoes the module dir;
# returns non-zero on miss. Differs from deploy.sh ONLY in the miss path: deploy.sh
# die()s under `set -e`; this script has no `die` and runs under `set -uo pipefail`
# (no `set -e`), so a miss is a plain non-zero return — the caller (check_one_skill)
# surfaces the empty module as a scan-surface error (SKILL.md missing -> exit 3),
# never a silent misresolve to the wrong module dir.
resolve_skill_module() {
  local skill="$1" s
  if [[ ${#OPERATIONS_SKILLS[@]} -gt 0 ]]; then for s in "${OPERATIONS_SKILLS[@]}"; do [[ "$s" == "$skill" ]] && { echo "operations"; return 0; }; done; fi
  if [[ ${#RELEASE_SKILLS[@]}    -gt 0 ]]; then for s in "${RELEASE_SKILLS[@]}";    do [[ "$s" == "$skill" ]] && { echo "release";    return 0; }; done; fi
  if [[ ${#CORE_SKILLS[@]}       -gt 0 ]]; then for s in "${CORE_SKILLS[@]}";       do [[ "$s" == "$skill" ]] && { echo "core";       return 0; }; done; fi
  if [[ ${#CANARY_SKILLS[@]}     -gt 0 ]]; then for s in "${CANARY_SKILLS[@]}";     do [[ "$s" == "$skill" ]] && { echo "release";    return 0; }; done; fi
  return 1
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

  # (a.2) Frontmatter version FORMAT. Runs immediately after the presence loop and
  # BEFORE the exemption pass-through, for the same reason (a) does: the exemption
  # is D-Refs-only, and version-field-semantics.md § Scope of Enforcement states
  # explicitly that the canary is NOT exempt from the version-field requirement.
  # Guarded on presence so a missing field yields exactly ONE FAIL, not two.
  # Extraction: first ^version: line, key stripped, CR stripped (a CRLF checkout
  # would otherwise produce an invisible, unactionable FAIL), leading and trailing
  # whitespace trimmed. An empty value survives as the empty string and correctly
  # fails — `grep -qE "^version:"` alone matches a bare `version:` with nothing
  # after the colon, which is one of the malformations this branch exists to catch.
  if grep -qE "^version:" "$src"; then
    local version_value
    version_value="$(grep -m1 -E "^version:" "$src" | tr -d '\r' \
                     | sed -e 's/^version:[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if ! grep -qE "$C6_VERSION_RE" <<<"$version_value"; then
      echo "FAIL:  $skill — version: '$version_value' does not match the required format vMAJOR.MINOR[-suffix] (regex $C6_VERSION_RE per core/standards/version-field-semantics.md § Format)"
      skill_ok=false
      had_fail=1
    fi
  fi

  # Exemption pass-through (canary-by-design): exempt from the D-Refs threshold
  # only. The frontmatter checks above already ran.
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

  # Populate the per-module global arrays from deploy.sh. Reset first so a
  # re-entrant call (e.g. the self-test invoking run_check across fixtures) never
  # sees a prior fixture's roster. resolve_skill_module() iterates these globals,
  # so its module map IS the deploy.sh roster by construction and cannot drift.
  OPERATIONS_SKILLS=(); RELEASE_SKILLS=(); CORE_SKILLS=(); CANARY_SKILLS=()
  local line s
  while IFS= read -r line; do [[ -n "$line" ]] && OPERATIONS_SKILLS+=("$line"); done < <(extract_roster_array OPERATIONS_SKILLS "$deploy_sh")
  while IFS= read -r line; do [[ -n "$line" ]] && RELEASE_SKILLS+=("$line");    done < <(extract_roster_array RELEASE_SKILLS    "$deploy_sh")
  while IFS= read -r line; do [[ -n "$line" ]] && CORE_SKILLS+=("$line");       done < <(extract_roster_array CORE_SKILLS       "$deploy_sh")
  while IFS= read -r line; do [[ -n "$line" ]] && CANARY_SKILLS+=("$line");     done < <(extract_roster_array CANARY_SKILLS     "$deploy_sh")

  # The SCAN roster is the deployed three (CANARY is source-only per ADR-04 —
  # resolvable to release/ above, but not itself scanned). Built from the
  # now-populated globals so the roster and the resolver share one source.
  local -a roster=()
  if [[ ${#OPERATIONS_SKILLS[@]} -gt 0 ]]; then for s in "${OPERATIONS_SKILLS[@]}"; do roster+=("$s"); done; fi
  if [[ ${#RELEASE_SKILLS[@]}    -gt 0 ]]; then for s in "${RELEASE_SKILLS[@]}";    do roster+=("$s"); done; fi
  if [[ ${#CORE_SKILLS[@]}       -gt 0 ]]; then for s in "${CORE_SKILLS[@]}";       do roster+=("$s"); done; fi

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
  # skill tree we mutate per assertion. fixtureskill is listed in the stub's
  # OPERATIONS_SKILLS, so run_check resolves it to operations/skills/.
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

  # Assertion 7: module resolution is single-sourced from deploy.sh and no longer
  # drifts. Fixture skill names are deliberately ABSENT from the former hardcoded
  # case map, so the old default-to-operations resolver would have misrouted the
  # release/ and core/ skills to operations/skills/ and FAILed (SKILL.md missing)
  # — the exact roadmap-curator incident this change fixes. A run_check that
  # resolves every arm to its correct module dir -> exit 0.
  mkdir -p "$tmp/operations/skills/fixtureops" \
           "$tmp/release/skills/fixturerel" \
           "$tmp/core/skills/fixturecore"
  cat > "$tmp/deploy-multi.sh" <<'STUB'
OPERATIONS_SKILLS=(
  fixtureops
)
RELEASE_SKILLS=(
  fixturerel
)
CORE_SKILLS=(
  fixturecore
)
CANARY_SKILLS=(
  fixturecanary
)
STUB
  # Compliant SKILL.md (under thresholds, 3 failure modes, all frontmatter) at $2.
  _write_compliant_at() {
    {
      echo "---"; echo "name: $1"; echo "description: fixture"; echo "version: v1.00"; echo "---"
      echo "# Fixture"
      echo "## Domain-Specific Failure Modes"
      echo "### One — TRIG";   echo "body"
      echo "### Two — INPUT";  echo "body"
      echo "### Three — PROC"; echo "body"
    } > "$2"
  }
  _write_compliant_at fixtureops  "$tmp/operations/skills/fixtureops/SKILL.md"
  _write_compliant_at fixturerel  "$tmp/release/skills/fixturerel/SKILL.md"
  _write_compliant_at fixturecore "$tmp/core/skills/fixturecore/SKILL.md"
  if run_check "$tmp" "$tmp/deploy-multi.sh" "" >/dev/null 2>&1; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: multi-module fixture did not pass — a release/ or core/ skill misresolved to the wrong module dir (expected exit 0)" >&2
    return 1
  fi

  # Assertion 8: a CANARY_SKILLS member resolves to release/ (the mapping the task
  # calls out). The per-module globals are still populated from the run_check above.
  if [[ "$(resolve_skill_module fixturecanary)" == "release" ]]; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: CANARY_SKILLS member did not resolve to release/ (expected 'release')" >&2
    return 1
  fi

  # Assertion 9 — version-format SENSITIVITY arm. A malformed value turns the
  # check red AND the FAIL text names the observed value (deploy.sh Check 6
  # specifies that it surfaces the current value). This is the arm that proves the
  # format branch is live: the live population conforms 56/56, so a green scan is
  # NOT evidence the predicate exists — which is precisely how the documented gate
  # went missing for as long as it did. '3.99' is one of the exact malformations
  # the defect report names (missing v-prefix).
  _write_compliant
  sed 's/^version: v1\.00$/version: 3.99/' "$fx" > "$fx.tmp" && mv "$fx.tmp" "$fx"
  local a9_out a9_rc
  a9_out="$(run_check "$tmp" "$tmp/deploy.sh" "" 2>&1)"; a9_rc=$?
  if [[ $a9_rc -eq 1 ]] \
     && grep -q 'does not match the required format' <<< "$a9_out" \
     && grep -q "3\.99" <<< "$a9_out"; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: malformed 'version: 3.99' did not produce a format FAIL naming the observed value (expected exit 1, got $a9_rc)" >&2
    return 1
  fi

  # Assertion 10 — version-format SPECIFICITY arm. The sanctioned '-canary'
  # sentinel is ACCEPTED. Assertion 9 on its own is a sensitivity-only probe; this
  # arm is what makes the pair discriminating, and it pins the sentinel against a
  # future over-tightening of C6_VERSION_RE. The canary must clear this gate by
  # GRAMMAR — never by an exemption entry, which would disarm assertion 9's own
  # control by routing the fixture around the predicate it exists to exercise.
  _write_compliant
  sed 's/^version: v1\.00$/version: v1.11-canary/' "$fx" > "$fx.tmp" && mv "$fx.tmp" "$fx"
  if run_check "$tmp" "$tmp/deploy.sh" "" >/dev/null 2>&1; then
    pass=$((pass + 1))
  else
    echo "self-test FAIL: sanctioned '-canary' sentinel version was rejected (expected exit 0) — C6_VERSION_RE has drifted from version-field-semantics.md § Format" >&2
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
      # operator-instance path via the resolver, fallback to the legacy .claude path.
      local exemption_list="$(pmo_instance_path)/skill-editor-exemption-list.txt"
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
