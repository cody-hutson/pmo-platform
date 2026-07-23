<!-- reference-durability: allow-link -->
---
title: ADR-039 — Declarative gate-condition construct (3-kind discriminated union) + two EAD annotation classes + cycle-safety doctrine
status: Accepted
date: 2026-06-23
deciders: "operator + Collective Review scope-lock"
tags: [entity-model, work-item, type-system, gate-conditions, declarative-gating, ead-materialization, cycle-safety, methodology-projection]
source_observations:
  - "The work-item type-pack meta-schema lets a kind declare gates and lets the project lifecycle select which fire, but a gate's condition can evaluate only the item's own fields — there is no first-class way to gate on a RELATED item's workflow status or on an AGGREGATE over a set of items."
  - "Two methodology-canonical gate shapes resist the self-field model: a finish-to-start / parent-design-gates-child status gate, and a Kanban WIP / pull-limit gate (the defining gate of a first-class archetype). A cross-methodology gate survey established that one declarative model with a typed check-target discriminator is sufficient as the spine, and that the set-aggregate target genuinely resists folding into the status+field pair."
  - "The set-aggregate gate must not invent set evaluation — the entity model already specifies a kind-agnostic BELONGS_TO rollup traversal (chain 17); the gate applies a comparator to that existing traversal rather than adding new physicalization."
---

# ADR-039 — Declarative gate-condition construct

## Status

**Proposed.** Drafted at Solutioning for the relationship-conditioned-status / set-aggregate gating work item and materialized alongside the meta-schema grammar it governs. Flips to **Accepted** at the declarative-gating-model Collective Review scope-lock — that gate is the ratification surface, consistent with how the establishing Work-Item Type Layer decision set its own status. Recorded as Proposed (not Accepted) at authoring time because that ratification gate has not yet run.

## Subordinate to

[ADR-018 — Work-Item Type Layer (WITL)](ADR-018-work-item-type-layer.md). This ADR implements ADR-018's declarative-type-layer kernel for the *gate-condition* surface; it opens **no competing kernel**. ADR-018's kernel disciplines bind it: the construct projects onto the work-organization mapping framework, never a release-pipeline ticket model, and `core/` governance carries no coupling to release-pipeline dev tooling.

## Context

The type-pack meta-schema (`../schemas/work-item-type-schema.md`) lets a kind declare gates (`criteria.gate`) and lets the project `lifecycle` select which fire, but a gate's condition can evaluate only the item's own fields and criteria. Three methodology-canonical gate shapes cannot be expressed:

1. A gate on a **related item's workflow status** — a child cannot advance to its next workflow status until its parent reaches a given status (parent-design-gates-child, BELONGS_TO); a dependent cannot leave `ready` while a blocking item is not yet `done` (finish-to-start, DEPENDS_ON / BLOCKS).
2. A gate on an **aggregate over a set** of items — the Kanban WIP / pull-limit gate ("a pull is permitted only while fewer than N items of a class are in a given status within a scope"), the defining gate of a first-class flow archetype.
3. The cross-cutting **control-field** gate (the field-axis sibling of the status axis) — reserved here, specified elsewhere.

A cross-methodology gate survey established that one declarative model with a typed check-target discriminator is sufficient as the spine, and that the set-aggregate target genuinely resists folding into the status-plus-field pair (it differs on resolution path and on materialization shape).

## Decision

1. **One discriminated-union gate-condition construct.** An OPTIONAL `condition` object on the existing `criteria.checks[]` entry, with a REQUIRED `condition.kind` discriminator. Absent `condition` = today's self-evaluating check (backward-compatible). Three discriminator values: `related-item-status` and `set-aggregate` (built now), `control-field` (slot reserved for the field-axis sibling, fail-loud if used before it is implemented). A `condition` is permitted **only inside a `criteria.gate` check**, so it inherits project-`lifecycle`-keyed firing — the construct carries no cadence/sprint semantics (the hardcoded-sprint-presumption defense holds by construction). The bodies are disjoint (no shared payload beyond the envelope) — the anti-EAV requirement, applied one level down to criteria.

2. **Two new EAD annotation classes** in the materialization contract. `related-item-status` materializes to `x-pmo-referential` resolving the target's *state* (not its existence), with a gate-layer `BLOCK-TRANSITION` disposition — extending the existing single-target referential precedent (which resolves existence with `BLOCK-WRITE`). `set-aggregate` materializes to a **new `x-pmo-aggregate`** class — a reduced value over a scope-bounded population, modeled on the single-target referential annotation (level + disposition) plus the existing chain-17 `BELONGS_TO` rollup traversal. It applies a comparator to the enumeration the entity model already specifies; it invents no new physicalization.

3. **A gate-transition disposition (`BLOCK-TRANSITION`) defined at the gate layer**, distinct from the entity layer's write-time referential `on-unresolved` enum. The entity disposition governs a *write* of a malformed referential field (a dangling FK at row-write); the gate disposition governs a *transition* of a well-formed row whose gate condition can't be resolved or isn't satisfied (a state move). Same refuse-and-route posture; different governed event, different layer. The frozen entity-layer enum is cross-walked, not extended — `BLOCK-TRANSITION` is a peer-by-posture of `BLOCK-WRITE`, owned by the gate layer (which is the layer that owns gate semantics: `criteria.gate`, `axis1_state_machine`, and `lifecycle_behavior` all live there).

4. **Cycle-safety = detect-and-refuse**, enforced at the existing single enforcement point (`tracker-manager`; no new enforcer). A static gating-graph cycle-detect at pack-validation refuses and names the offending cycle path. A runtime `BLOCK-TRANSITION` backstop carries a traversal-depth cap (status arm) and a set-cardinality bound (aggregate arm). A single self-limiting WIP gate (a convergent self-edge — a gate that guards the same transition that fills its own set) is **EXEMPT** (it converges to the limit and stops admitting). Mutual cycles (an A↔B status standoff, or a two-set / `limit_ref` aggregate cycle) are **REFUSED**. Refuse, not auto-break — a genuine mutual cycle is an operator-resolvable modeling error (remove one gate), routed to the operator rather than silently broken (which would let one item advance on a gate meant to hold).

## Consequences

### Positive

- Every methodology-canonical gate the survey found — status, set-aggregate, plus the already-shipped cadence and judgment targets — is expressible in one grammar.
- Kanban WIP / pull-limit becomes declarable as data, with class-of-service (kind-filtered) lanes and a `limit_ref` that lets the cap be config rather than a hardcoded literal.
- The discriminated union makes a later fourth arm (e.g., an external-signal target) a purely additive extension, no grammar re-open.
- No new enforcer — both annotations bite where the single-target referential annotation and the rollup already bite (`tracker-manager`'s pre-write/transition pass).
- Additive and backward-compatible (the meta-schema stays at its current version; absent `condition` is byte-identical to prior behavior).

### Negative / cost

- A new logical evaluation primitive — set-enumerate-and-reduce — in `tracker-manager` (the only genuinely new evaluation surface; it composes the existing chain-17 traversal).
- A new gate-disposition term (`BLOCK-TRANSITION`) that other gates and the reserved control-field arm inherit.
- The gating-graph cycle-detector is a new pack-validation pass.
- The `x-pmo-aggregate` class is the first declarative gate that reduces over a population — a precedent any future aggregate gate inherits.

## Alternatives rejected

| Option | Decision | Rationale |
|---|---|---|
| **A single flat condition construct (one shape carrying all kinds' payloads)** | Rejected | Forces each row to populate one payload and null the others — the sparse / EAV shape the type layer explicitly rejects, reproduced at the criterion level. |
| **N unrelated top-level constructs (one per kind)** | Rejected | The kinds share a real envelope (the check shape, project-`lifecycle` firing, criteria-version grandfathering, the by-level EAD projection); N constructs duplicate that envelope and split the EAD logic. |
| **Folding `set-aggregate` into `related-item-status`** | Rejected | Set-aggregate differs on resolution path (set-enumerate-and-reduce vs single-edge) and on materialization class (a new aggregate annotation vs the single-target referential); folding re-introduces the EAV null-half shape inside one discriminator. |
| **Reusing `BLOCK-WRITE` for the gate disposition, or extending the frozen entity-layer enum** | Rejected | `BLOCK-WRITE` mis-states the semantics (the row is well-formed; only the transition is blocked); extending the frozen entity-layer enum over-reaches a frozen surface for a concept the gate grammar legitimately owns. |
| **Coupling the construct to the release-pipeline gate specs** | Rejected | Those are the release-pipeline triage gates with zero type-pack-gate semantics; routing the construct there is the ADR-018 release-pipeline-neutrality kernel violation. |

## Reversibility

**MODERATE / Confidence HIGH pre-consumption** — before a deployment authors a `condition`'d pack, the grammar is a free choice. Crosses to **EXPENSIVE** once packs declare conditions and in-flight items are judged against them (a criteria-version migration). Deciding the three-arm enum + the two annotation classes at design time is the cheap moment: retrofitting set-aggregate after Kanban deployments already exist would be expensive, because the aggregate annotation and its evaluation primitive would have to be back-fitted under live WIP gates.

## Related ADRs

- [ADR-018 — Work-Item Type Layer](ADR-018-work-item-type-layer.md) — the parent kernel this ADR is subordinate to (thin generic Work Item entity + declarative type layer; methodology-projected; release-pipeline-neutral). This construct extends ADR-018's grammar for the gate-condition surface and opens no competing kernel.

### Provenance

This decision was sliced from a unifying "declarative gating model" frame (status-criteria + a field-criteria sibling + a methodology plug-and-play consumer). It consumes two accepted de-risking research findings: a cross-methodology gate-landscape survey (which returned the one-model / typed check-target verdict and graded set-aggregate as a canonical gate of a shipped archetype) and a type-pack meta-schema modeling-feasibility finding (which returned the discriminated-union construct shape, the cycle-safety model, and the ADR-warranted verdict). The set-aggregate target was first-classed into this slice by operator decision. The construct grammar, the two annotation classes, and the cycle-safety doctrine are specified in `../schemas/work-item-type-schema.md` §1.2.1 / §3.1a / §7.6; this ADR records the decision kernel those edits implement.
