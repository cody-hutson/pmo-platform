<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-034 — Pipeline-wide progressive-rollout convention — lift-and-extend the executor model, add a terminal phase, do not author parallel
status: Accepted
date: 2026-06-20
release: 71-autonomy-phaseout-foundation
deciders: "Workspace owner — adopted at the 71-autonomy-phaseout-foundation Collective Review scope-lock"
tags: [architecture, rollout, phase-enum, single-source, autonomy-phaseout]
---

# ADR-034 — Pipeline-wide progressive-rollout convention: lift-and-extend the executor model, add a terminal phase, do not author parallel

## Status

**Accepted.** Adopted at the Collective Review scope-lock for the `71-autonomy-phaseout-foundation` milestone.

## Context

The platform needed a pipeline-wide `shadow → warn → enforce` rollout convention with a named terminal phase, and a companion touchpoint phase-out schema needed a canonical phase enum for its `current_phase` field. But the platform already ran **two non-unified rollout ladders**, neither pipeline-wide and neither with a terminal decommission phase:

1. A 3-cycle `shadow / warn / enforce` model scoped to the release-executor (`release/skills/release-executor/references/progressive-rollout.md`, LIVE) — it wraps the executor's T1/T2/T3 quality-gate ladder and explicitly puts the security-hook layer out of scope.
2. A 2-state-plus-off `warn / enforce / off` mode machine for the security-hook layer and `deploy.sh --check` (`core/hooks/.mode`, `core/hooks/deploy-check.mode`, plus `block-autonomy-ceiling.sh`'s own `.autonomy-mode`).

The executor doc explicitly scopes the hook-layer retrofit out. Building the convention surfaced two coupled questions the platform had no precedent for: which phase vocabulary to canonicalize (resolving the 3-state-vs-2-state divergence), and whether to lift the existing executor model to pipeline scope or author a parallel file (a duplicate-source question with blast radius). A terminal-rollout vocabulary (`removed` / `retired` / `sunset`) was absent corpus-wide — both ladders stop at `enforce` — yet the milestone outcome and the companion schema both need a terminal value to express "this human gate is now fully automated."

## Decision

Adopt a **pipeline-wide progressive-rollout convention** at `core/standards/progressive-rollout-convention.md` as the canonical definition of the phase enum and the per-phase contract, with four coupled parts:

1. **Phase enum = `shadow / warn / enforce / removed`.** Preserve the existing three phases verbatim (zero rename of any LIVE usage), and add a terminal `removed` rung. `removed` is the autonomy-phase-out telos — a human gate fully automated or retired — and the value the companion touchpoint phase-out schema's `current_phase` field consumes. Rejected `dark/canary/GA` (traffic-percentage semantics misfit governance-rule rollout; zero corpus occurrences; would orphan two LIVE usages).

2. **Per-phase 4-element contract.** Each phase is defined by observable behavior · telemetry contract · advance criteria · retreat trigger, stated inline per phase. The terminal `removed` rung's retreat is deliberately routed back to `shadow` (re-observe before it can block again), never a silent jump to `enforce` — the load-bearing safety property of having a named terminal phase.

3. **RECONCILE, do not duplicate.** The existing `progressive-rollout.md` becomes the executor-scoped *realization* and cites the convention as its canonical phase-vocabulary source; the convention does NOT absorb the executor's gate-ladder machinery (the `rollout-cycle` column, the short-circuit seam, the JSONL outcome-log stay with the executor). The enum lives in exactly one canonical home per the duplicate-source register-or-remove rule.

4. **Placement at `core/standards/`.** The convention is a cross-module authoring standard, co-located with its sibling disciplines (`evidence-grounding-standard.md`, `reference-durability-standard.md`); `core/governance/` is reserved for OPERATIONS.md-class governance.

The convention records the existing usages in an audit table graded per-phase (✅/⚠/❌) with an N-of-4 realized-count and a PARTIAL verdict: the executor ladder is 3-of-4 (missing `removed`); the hook layer and `deploy.sh --check` are 2-of-4 (missing `shadow` + `removed`). The hook-layer `shadow` retrofit stays **out of scope** (it touches governed harness tooling under a separate gate); the convention records the 2-of-4 gap, it does not close it.

## Consequences

- **One canonical enum, no drift.** The companion schema's `current_phase` has a stable domain authored once; the executor realization references the convention rather than re-defining the vocabulary.
- **Existing usages graded honestly.** The audit table marks the modal 2-state-plus-off machinery PARTIAL against the 4-phase contract and states plainly that nothing realizes `removed` — the gap is visible, not papered over.
- **A reusable rollout vocabulary** exists for any future mechanism that graduates observe → warn → block → decommission; it cites this convention rather than re-deciding the phases.
- **A future ticket may** retrofit the hook layer to `shadow` and/or migrate touchpoints to `removed`; both are out of this milestone's scope.

## Alternatives Considered

- **`dark / canary / GA` vocabulary.** Rejected: traffic-percentage rollout semantics misfit governance-rule rollout (a rule observes / warns / blocks; there is no "5% of releases" dimension); zero corpus occurrences; adopting it would orphan two LIVE usages and force a corpus-wide rename.
- **Author a parallel pipeline-wide file alongside the executor model.** Rejected: it would duplicate the phase enum across two homes — a duplicate-source violation. The lift-and-extend keeps exactly one canonical definition.
- **Absorb the executor's gate-ladder machinery into the convention.** Rejected: the convention owns the vocabulary, not the executor's tier-short-circuit machinery; absorbing it would couple a pipeline-wide standard to one skill's internals.
- **Close the hook-layer `shadow` gap in this release.** Rejected: the hook `.mode` machinery is governed harness tooling under a separate gate; retrofitting it is a separate ticket. The convention records the gap as 2-of-4 PARTIAL.
- **Place the convention in `core/governance/`.** Rejected: `core/governance/` is OPERATIONS.md-class operating governance; an authoring convention is a standard and belongs with its standards siblings.

## Reversibility

**CHEAP → MODERATE** (HIGH confidence). At adoption the change is additive — a new standards convention plus a content-additive re-point of the executor realization to cite the convention — and reverts with no data loss and no stranded consumer. It trends **MODERATE** as future mechanisms and the companion schema accumulate citations of the enum: a rename or removal of a phase value then ripples to every consumer that references it by name. The diagnosis is grounded in a direct survey of the two LIVE ladders; the recommendation is the minimal single-source resolution, and `removed` is the minimal terminal rung the milestone outcome and the companion schema both require.

## Related ADRs

- **ADR-028** (`ADR-028-operations-consume-core-safety-controls-via-public-api.md`) — consume-by-reference-from-the-canonical-owner posture; the RECONCILE-do-not-duplicate decision is the same one-owner-of-truth principle applied to the phase enum.
- **ADR-030** (`ADR-030-hook-registry-drop-in-with-generated-index.md`) — the generated `bypass-mode-readiness.md` index; this convention audit-references the hook layer but must NOT edit that generated index (edit source fragments only), a boundary this ADR inherits.
- **ADR-031** (`ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md`) — `block-autonomy-ceiling.sh` and its own `.autonomy-mode` file is one of the audit-table rows graded 2-of-4 PARTIAL.

## Provenance

- `#164` — parent task (this convention is its deliverable). Milestone `71-autonomy-phaseout-foundation`.
- `#165` — companion task; its schema's `current_phase` field consumes this convention's phase enum.
- Canonical artifact: `core/standards/progressive-rollout-convention.md`.
