---
title: ADR-008 — deploy.sh per-module array design (architectural rationale)
status: Accepted (architectural intent at the module restructure; implementation followed)
date: 2026-05-27
deciders: "operator + Stage 5 Solutioning spoke + adversarial review"
tags: [architecture, deploy-script, module-boundary, error-handling, bash-set-u]
source_observations:
  - Stage 5 spec (deploy.sh adapt) — 11-function adaptation surface
  - Adversarial review — 1 Blocker finding (FM-1 empty-array crash under set -u) + 4 Major findings
  - Empirical: deploy.sh at HEAD d849255 has 126 hardcoded `pmo-platform/` references (not 98 per spec PR-1 correction); 11 functions adapted; 8 distinct `${SKILL_LIST[@]}` iteration sites
---

# ADR-008 — deploy.sh per-module array design

## Status

Accepted as architectural intent (this ticket commits deploy.sh byte-identical to source; ADR-008 codifies the adaptation strategy). Implementation owned by a follow-on spoke (parallel to operations/release migrations). Spec authored at Stage 5 sub-task; ADR substance ratified at adversarial review + Collective Review APPROVE WITH OVERRIDES 2026-05-27.

## Context

This release transforms `pmo-platform/` flat structure to `pmo-platform-v2/{operations,release,core,docs,packages}/` modular monolith. `deploy.sh` has 9-11 functions referencing `pmo-platform/` paths (126 grep occurrences as of authoring, at HEAD `d849255`) and 8 distinct `${SKILL_LIST[@]}` iteration sites. The current `SKILL_LIST` is a single 21-entry array; the new structure requires partition into per-module arrays:

```bash
declare -a OPERATIONS_SKILLS=( ... 12 skills ... )
declare -a RELEASE_SKILLS=( ... 6 skills ... )
declare -a CORE_SKILLS=( ... 3 skills ... )
declare -a CANARY_SKILLS=( pmo-skill-refiner-selftest-canary )
declare -a HARNESS_LIST=( account-switcher )  # may be empty in operator instances
```

**Critical defect surfaced by adversarial review FM-1 (Blocker):** deploy.sh declares `set -euo pipefail`. Empty arrays under `set -u` raise `unbound variable` on `${ARR[@]}` expansion — the script CRASHES rather than iterating zero times:

```bash
$ echo 'set -euo pipefail; a=(); for x in "${a[@]}"; do echo $x; done' | bash
bash: line 1: a[@]: unbound variable
exit: 1
```

Without explicit `${#ARR[@]} -gt 0` gating at every iteration site, `./deploy.sh --check` will exit 1 on first `for harness_name in "${HARNESS_LIST[@]}"` if HARNESS_LIST is empty.

## Decision

**The deploy.sh adaptation follows three structural rules:**

### Rule 1: Per-module arrays replace SKILL_LIST

Replace the single `declare -a SKILL_LIST=` with four per-module arrays:

```bash
declare -a OPERATIONS_SKILLS=(
  artifact-generator change-management comms-writer daily-status
  delivery-engine file-router pmo-process-designer pmo-technical-analyst
  ppm-agent project-initiator tracker-manager weekly-status-rollup
)
declare -a RELEASE_SKILLS=(
  build-reviewer implementation-planner pmo-skill-editor pmo-skill-refiner
  release-executor release-planner
)
declare -a CORE_SKILLS=(
  eval-writer pmo-qa-auditor prompt-builder
)
declare -a CANARY_SKILLS=( pmo-skill-refiner-selftest-canary )
```

**Iteration pattern** (replaces `for skill in "${SKILL_LIST[@]}"`):

```bash
for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}" "${CANARY_SKILLS[@]}"; do
  module=$(resolve_skill_module "$skill")
  source_dir="pmo-platform-v2/${module}/skills/${skill}"
  # ...
done
```

### Rule 2: Empty-array guard at EVERY iteration site

Wrap iteration of any array that may be empty (HARNESS_LIST, CANARY_SKILLS, SUPPLEMENTARY_SKILLS) in explicit count-check:

```bash
if [[ ${#HARNESS_LIST[@]} -gt 0 ]]; then
  for harness_name in "${HARNESS_LIST[@]}"; do
    # ...
  done
fi
```

**Rationale:** Under `set -euo pipefail` (deploy.sh:2), `${ARR[@]}` on an empty array raises unbound-variable and crashes the script. The Stage 5 spec verification was run WITHOUT `set -u` and incorrectly claimed empty-array iteration "skips cleanly" — adversarial FM-1 verified the crash mode. The `${#ARR[@]} -gt 0` gate is the safest, most-portable pattern (compatible with macOS bash 3.2 default).

**Sites requiring the gate** (per adversarial FM-2 cascade-sweep):
- deploy.sh:781 (Check 1)
- deploy.sh:925 (cmd_init)
- deploy.sh:999 (Check 6)
- deploy.sh:1073 (Check 7)
- deploy.sh:1195 (Check 10)
- deploy.sh:1322 (Check 12 c12_roster)
- deploy.sh:2865 (cmd_report)
- Every HARNESS_LIST iteration site (lines 646, 715, 1280, 2920)

### Rule 3: `resolve_skill_module()` helper with `die`-on-miss

Per adversarial FM-3, a helper function called via command substitution under `set -e` aborts the script with no diagnostic if it returns non-zero. The helper MUST die explicitly:

```bash
resolve_skill_module() {
  local skill="$1"
  local arr
  for arr in OPERATIONS_SKILLS RELEASE_SKILLS CORE_SKILLS CANARY_SKILLS; do
    local -n arr_ref="$arr"
    for s in "${arr_ref[@]}"; do
      if [[ "$s" == "$skill" ]]; then
        case "$arr" in
          OPERATIONS_SKILLS) echo "operations"; return 0 ;;
          RELEASE_SKILLS|CANARY_SKILLS) echo "release"; return 0 ;;
          CORE_SKILLS) echo "core"; return 0 ;;
        esac
      fi
    done
  done
  die "resolve_skill_module: skill '${skill}' not in any per-module array"
}
```

The `die` function provides operator-actionable diagnostic; `return 1` would silently abort under `set -e`.

## Alternatives Considered

The headline decision was **forced rather than weighed**: § Context records that the new structure *requires* partition into per-module arrays, so the split itself had no competing shape. The alternatives this record does evidence sit at the mechanism level, one per Decision rule.

- **Rule 2 — empty-array guard.** `${ARR[@]:+...}` parameter substitution was available and **not taken**: § Consequences item 4 records that it is bash 4.2+ while macOS ships bash 3.2 by default, so the explicit `${#ARR[@]} -gt 0` gate was chosen for portability.
- **Rule 3 — miss handling in `resolve_skill_module()`.** A bare `return 1` was **not taken**: a helper called via command substitution under `set -e` aborts the script with no diagnostic on non-zero return, so the helper dies explicitly with an operator-actionable message instead.
- **Check 9 — mirror-pair semantics.** Retaining the bi-directional *two-sources-must-agree* assertion was **not taken**; per the adversarial review the adapted check is uni-directional source-to-workspace, so drift has one unambiguous reading and one remedy.

A prior verification was also rejected rather than trusted: the Stage 5 spec claimed empty-array iteration "skips cleanly", but that check had been run without `set -u`; the adversarial review reproduced the crash, and the empirical result superseded the claim.

## Consequences

1. **Implementation contract:** The implementation spoke implements per-module arrays + empty-array gates + `resolve_skill_module()` helper + Check 9 mirror-pair adaptation (semantic change: bi-directional source-of-truth → uni-directional source-to-workspace mirror, per adversarial PR-4).

2. **Mirror-pair semantics change (adversarial PR-4):** Current Check 9 asserts `.claude/rules/<file>.md` ↔ `pmo-platform/engineering/rules/<file>.md` byte-equality (two-sources-must-agree). The adapted Check 9 asserts `core/rules/<file>.md` ↔ `~/.claude/rules/<file>.md` (source-mirrors-to-workspace; uni-directional). Drift means "workspace mirror diverged from source; re-run `./deploy.sh --deploy` to restore."

3. **Empty operator-instance compatibility:** Operators forking pmo-platform-v2 with empty HARNESS_LIST (no operator-instance harness artifacts) MUST not crash deploy.sh. The empty-array gate (Rule 2) ensures `./deploy.sh --check` runs cleanly on a fresh-clone empty operator instance.

4. **Bash 3.2 macOS compatibility:** macOS ships bash 3.2 as default. The `${ARR[@]:+...}` parameter substitution alternative is bash 4.2+; the `${#ARR[@]} -gt 0` explicit gate works on bash 3.2+. Rule 2 chose the latter for portability.

5. **Test-fixture requirement (G0 smoke test):** The implementation spoke MUST run `bash -c 'set -euo pipefail; <script-fragment>'` against every empty-array site BEFORE merging. This is the executable contract that prevents FM-1 from recurring.

## Reversibility

**CHEAP** — array partitioning is mechanical; can collapse back to single SKILL_LIST at any future release. Empty-array gates are additive (don't break correct-arity code). The deploy.sh adaptation is module-boundary-aware but module-internal mechanics unchanged.

**Confidence:** HIGH — empirical bash-3.2/`set -u` behavior verified twice during adversarial review; the gate pattern is universally portable.

## Composition with other ADRs

- ADR-006 (skill map) — supplies the per-module skill names
- ADR-007 (core boundary) — supplies file-placement boundary; deploy.sh `--check 14/15` glob expansion depends on ADR-007's module layout
- ADR-009 (rewrite-map CLI) — sibling adaptation ADR; both implemented together.

## Implementation timing

- **Initial migration (this ticket):** deploy.sh migrated byte-identical to source (no array changes; no empty-array guards yet). ADR-008 codifies the close intent.
- **Adaptation:** Implements Rule 1 (per-module arrays) + Rule 2 (empty-array gates) + Rule 3 (resolve helper) + Check 9 mirror-pair adaptation.
- **Validation:** Extraction-readiness validation re-runs `./deploy.sh --check` against per-module empty-state to verify no crash mode.

## Audit Tooling Exemption

Per the cross-module reference cleanup (operator-ratified at the Pattern-P4 per-edit plan), the cross-module audit classifier exempts deploy infrastructure files from cross-module reference scanning:

| File | Rationale |
|---|---|
| `core/deploy/deploy.sh` | Deploys across all 3 modules by design (per this ADR's per-module array partitioning); MUST reference `operations/`, `release/`, `core/` paths to orchestrate deployment |
| `core/deploy/tools/cross_module_audit_helper.py` | Audit classifier itself — `MODULES = ("operations", "release", "core")` constant + `DIRECTIONALITY` dict naturally trigger self-reference findings |
| `core/deploy/tools/cross-module-audit.sh` | Wrapper around audit helper — same self-reference pattern |
| `core/deploy/tools/check-doc-links.py` | Link-resolution primitive — references workspace-rooted paths across modules |

The exemption is a **classifier policy decision**, not a strategy. Source files in `DEPLOY_INFRASTRUCTURE_PATHS` (constant in `cross_module_audit_helper.py`) are skipped during scan time (per `scan_module_for_cross_module_refs()`); they emit no audit findings. Adding new deploy/audit infrastructure files to this exemption requires the same operator-approved per-edit-plan governance as any other classifier change.

**This ADR section's authority:** This section composes with the broader cleanup framework (operator-ratified at ADR-007 Carry-Forward Extension section). The audit tool refinement is reversible CHEAP via single function revert.
