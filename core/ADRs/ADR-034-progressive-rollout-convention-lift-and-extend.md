<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-034 — Pipeline-wide progressive-rollout convention — lift-and-extend the executor model, add a terminal phase, do not author parallel
status: Accepted
date: 2026-06-20
release: 71-autonomy-phaseout-foundation (v2.12)
deciders: "Workspace owner (operator-adopted at the 71-autonomy-phaseout-foundation Collective Review scope-lock); design authored at Stage 5 Solutioning (the Principal Engineer — Architecture Assessment spoke, #164); ADR materialized at Stage 6 per the ADR-007 / ADR-028 / ADR-033 Stage-6 ADR-authoring precedent"
tags: [architecture, rollout, governance, shadow-warn-enforce, phase-enum, lift-and-extend, autonomy-phaseout, reversibility, duplicate-source, placement, blast-radius]
source_observations:
  - "#164 Stage-5 finding: a complete three-cycle shadow→warn→enforce model ALREADY EXISTS at release/skills/release-executor/references/progressive-rollout.md (215 lines, LIVE) but is release-executor-scoped (wraps only the executor's T1/T2/T3 quality-gate ladder), is 3-phase, and explicitly puts the security-hook layer out of scope. The security-hook layer separately runs a 2-state-plus-off (warn/enforce/off) machine. The platform therefore had two non-unified, partially-overlapping rollout ladders and no pipeline-wide convention — the gap #164 is chartered to close."
  - "#164 Stage-5 finding: a terminal-rollout vocabulary (removed / retired / sunset) is absent corpus-wide — both existing ladders stop at enforce. The milestone Outcome Statement (shadow → warn → enforce → removed) and the companion #165 phase-out schema's current_phase field both need a terminal value to express 'this human gate is now fully automated.' removed is that value."
---

# ADR-034 — Pipeline-wide progressive-rollout convention: lift-and-extend the executor model, add a terminal phase, do not author parallel

## Status

**Accepted.** Operator-adopted at the Collective Review scope-lock for `71-autonomy-phaseout-foundation` (v2.12). Design authored at Stage 5 Solutioning (the Principal Engineer — Architecture Assessment spoke, parent task `#164`); ADR materialized at Stage 6 post-build per the ADR-007 / ADR-028 / ADR-033 Stage-6 ADR-authoring precedent. Ships in the v2.12 release PR (reviewed at Stage 9, Deep per the `novel` release class). The next gap-free ADR number after 033 is 034 (`check-adr-numbers.py` enforces platform-wide-unique, gap-free numbering).

## Context

Task `#164` asks for a pipeline-wide `shadow → warn → enforce` convention with ≥4 named phases. Verification at Stage 5 found the platform already runs **two non-unified rollout ladders**:

1. A 3-cycle `shadow / warn / enforce` model scoped to the release-executor (`release/skills/release-executor/references/progressive-rollout.md`, LIVE) — it wraps the executor's T1/T2/T3 quality-gate ladder and explicitly puts the security-hook layer out of scope.
2. A 2-state-plus-off `warn / enforce / off` mode machine for the security-hook layer and `deploy.sh --check` (`core/hooks/.mode`, `core/hooks/deploy-check.mode`, plus `block-autonomy-ceiling.sh`'s own `.autonomy-mode`).

Neither is pipeline-wide; neither has a terminal decommission phase; the executor doc explicitly scopes the hook-layer retrofit out. The companion task `#165` needs a canonical phase enum for its `current_phase` schema field. Building the convention surfaced two coupled questions the platform had no precedent for: which phase vocabulary to canonicalize (resolving the 3-state-vs-2-state divergence), and whether to lift the existing executor model to pipeline scope or author a parallel file (a duplicate-source question with blast radius).

## Decision

Adopt a **pipeline-wide progressive-rollout convention** at `core/standards/progressive-rollout-convention.md` as the canonical definition of the phase enum and the per-phase contract, with four coupled parts:

1. **Phase enum = `shadow / warn / enforce / removed`.** Preserve the existing three phases verbatim (zero rename of any LIVE usage), and add a terminal `removed` rung. `removed` is the autonomy-phase-out telos — a human gate fully automated or retired — and the value the companion `#165` `current_phase` field consumes. Rejected `dark/canary/GA` (traffic-percentage semantics misfit governance-rule rollout; zero corpus occurrences; would orphan two LIVE usages).

2. **Per-phase 4-element contract.** Each phase is defined by observable behavior · telemetry contract · advance criteria · retreat trigger, stated inline per phase. The terminal `removed` rung's retreat is deliberately routed back to `shadow` (re-observe before it can block again), never a silent jump to `enforce` — the load-bearing safety property of having a named terminal phase.

3. **RECONCILE, do not duplicate.** The existing `progressive-rollout.md` becomes the executor-scoped *realization* and cites the convention as its canonical phase-vocabulary source; the convention does NOT absorb the executor's gate-ladder machinery (the `rollout-cycle` column, the short-circuit seam, the JSONL outcome-log stay with the executor). The enum lives in exactly one canonical home per the duplicate-source register-or-remove rule.

4. **Placement at `core/standards/`.** The convention is a cross-module authoring standard, co-located with its sibling disciplines (`evidence-grounding-standard.md`, `reference-durability-standard.md`); `core/governance/` is reserved for OPERATIONS.md-class governance.

The convention records the existing usages in an audit table graded per-phase (✅/⚠/❌) with an N-of-4 realized-count and a PARTIAL verdict: the executor ladder is 3-of-4 (missing `removed`); the hook layer and `deploy.sh --check` are 2-of-4 (missing `shadow` + `removed`). The hook-layer `shadow` retrofit stays **out of scope** (it touches governed harness tooling under a separate gate); the convention records the 2-of-4 gap, it does not close it.

## Consequences

- **One canonical enum, no drift.** `#165`'s `current_phase` has a stable domain authored once; the executor realization references the convention rather than re-defining the vocabulary.
- **Existing usages graded honestly.** The audit table marks the modal 2-state-plus-off machinery PARTIAL against the 4-phase contract and states plainly that nothing realizes `removed` — the gap is visible, not papered over.
- **A reusable rollout vocabulary** exists for any future mechanism that graduates observe → warn → block → decommission; it cites this convention rather than re-deciding the phases.
- **A future ticket may** retrofit the hook layer to `shadow` and/or migrate touchpoints to `removed`; both are out of this milestone's scope.

## Alternatives rejected

- **`dark / canary / GA` vocabulary.** Rejected: traffic-percentage rollout semantics misfit governance-rule rollout (a rule observes / warns / blocks; there is no "5% of releases" dimension); zero corpus occurrences; adopting it would orphan two LIVE usages and force a corpus-wide rename.
- **Author a parallel pipeline-wide file alongside the executor model.** Rejected: it would duplicate the phase enum across two homes — a duplicate-source violation. The lift-and-extend keeps exactly one canonical definition.
- **Absorb the executor's gate-ladder machinery into the convention.** Rejected: the convention owns the vocabulary, not the executor's tier-short-circuit machinery; absorbing it would couple a pipeline-wide standard to one skill's internals.
- **Close the hook-layer `shadow` gap in this release.** Rejected: the hook `.mode` machinery is governed harness tooling under a separate gate; retrofitting it is a separate ticket. The convention records the gap as 2-of-4 PARTIAL.
- **Place the convention in `core/governance/`.** Rejected: `core/governance/` is OPERATIONS.md-class operating governance; an authoring convention is a standard and belongs with its standards siblings.

## Reversibility

**CHEAP** at ship — additive (a new standards convention + a content-additive executor-reference re-point + one `(future)`→LIVE taxonomy-line flip). Reverting the v2.12 release PR deletes the convention and reverts the edits with no data loss and no stranded consumer (the only corpus consumer, the `release-class-taxonomy.md` `(future)` block, is reverted in the same PR). Trends **MODERATE** as future mechanisms and the `#165` schema accumulate citations of the enum. **Confidence: HIGH** on the diagnosis (both findings are directly grounded in the Stage-5 survey, re-verified LIVE at baseline `f7eee93`) / **HIGH** on the recommendation (lift-and-extend is the minimal single-source resolution; `removed` is the minimal terminal rung the Outcome Statement and `#165` both require).

## Related ADRs

- [ADR-030](ADR-030-hook-registry-drop-in-with-generated-index.md) — the generated `bypass-mode-readiness.md` index; this convention audit-references the hook layer but must NOT edit that generated index (edit source fragments only), a boundary this ADR inherits.
- [ADR-031](ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md) — `block-autonomy-ceiling.sh` and its own `.autonomy-mode` file; one of the audit-table rows graded 2-of-4 PARTIAL.
- [ADR-028](ADR-028-operations-consume-core-safety-controls-via-public-api.md) — consume-by-reference-from-the-canonical-owner posture; the RECONCILE-do-not-duplicate decision is the same one-owner-of-truth principle applied to the phase enum.
- [ADR-033](ADR-033-methodology-conditional-skill-activation.md) — the immediately preceding Stage-6-materialized ADR; this ADR follows the same scope-lock-adoption + Stage-6-authoring pattern and the gap-free numbering precedent.

## Provenance

- `#164` — parent task (this convention is its AC1/AC2/AC4 deliverable). Milestone `71-autonomy-phaseout-foundation`.
- `#165` — companion task; its schema's `current_phase` field consumes this convention's phase enum (the E1 consistency contract, #164 AC5).
- Canonical artifact: [progressive-rollout-convention.md](../standards/progressive-rollout-convention.md).
