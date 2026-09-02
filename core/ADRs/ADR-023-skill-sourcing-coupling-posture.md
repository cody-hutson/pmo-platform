---
title: ADR-023 — Skill sourcing-coupling posture (own-with-harvest default; guarded-wrap exception)
status: Accepted
date: 2026-06-13
release: knowledge-architecture-initiative (epic knowledge-corpus)
deciders: "operator (decision adopted 2026-06-13) + the build-philosophy charter initiative"
tags: [architecture, skill, sourcing, anthropic, coupling, build-vs-buy, reversibility]
source_observations:
  - "The anthropic-base-vs-build registry catalogs 22 PMO skills against the Anthropic catalog in three observed postures (independent ×19, extends ×2, replaces ×1; pass-through reserved) but is observational-only — it explicitly does NOT prescribe migration, consolidation, or build-vs-buy actions. There is no normative rule for WHICH posture a skill should take."
  - "The comms-writer/artifact-generator offload milestone made the posture call ad hoc: one of its issues bakes a RUNTIME dependency on Anthropic product-management/stakeholder-comms into comms-writer's exec-brief / stakeholder-email path — the highest-blast-radius, stakeholder-facing surface — and its own trade-offs concede 'quality depends on Anthropic skill evolution cadence.'"
  - "The platform already owns the machinery to manage this: a drift-canary precedent guards the one explicit runtime wrap (pmo-skill-refiner -> skill-creator), and the upstream-reference catalog is a design-time harvest surface that records upstream-source + pmo-extensions + a drift-check cadence WITHOUT a runtime binding."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-023 — Skill sourcing-coupling posture

## Status

**Accepted.** The operator adopted the decision on 2026-06-13; this ADR is the
committed record of that adopted decision.

## Context

The platform relates to Anthropic skills in three observable postures, catalogued in the
[anthropic-base-vs-build registry](../specs/anthropic-base-vs-build-registry.md): a skill is
`independent` (no Anthropic counterpart — fully owned), `extends` (wraps an Anthropic skill
at runtime), or `replaces` (ships its own implementation under a colliding name); a fourth,
`pass-through`, is reserved. The registry is **observational only** — by its own §Observational
discipline it "does NOT prescribe migration, consolidation, or build-vs-buy actions." It
records *what overlaps*; it deliberately carries no rule for *which posture a skill should
take*.

That normative gap has a cost. The comms-writer/artifact-generator offload made the posture
call issue-by-issue, and one issue puts a **runtime** dependency on Anthropic's
`product-management/stakeholder-comms` directly in comms-writer's exec-brief and
stakeholder-email path — the most stakeholder-facing, highest-blast-radius surface the suite
has — then attempts to post-process generic output back into PMO compliance. A silent upstream
change there changes an executive's briefing with no signal; the issue's own trade-offs admit
"quality depends on Anthropic skill evolution cadence." The decision this ADR records is the
rule that should have governed that call.

## Decision

**Default posture is own-with-harvested-learnings.** A PMO skill is `independent` by default:
it is authored and owned first-party, and it *harvests* structure, patterns, and conventions
from the relevant Anthropic skill at **design time** via the
[upstream-reference catalog](../standards/upstream-reference-catalog.md) — a recorded
divergence with a drift-check cadence, not a runtime call.

**A runtime dependency (`extends` / `pass-through`) is the exception, permitted only when all
three hold:** (1) the upstream contract is **commodity-stable** (a stable I/O contract such as
a document-format engine, not a drifting judgment surface); AND (2) a silent upstream change
has **low blast radius** (build-time / human-reviewed output, not a stakeholder-facing or
governance-binding artifact); AND (3) the coupling is **guarded** by a drift canary in the
manner the `pmo-skill-refiner` → `skill-creator` wrap already is.

**Stakeholder-facing generation and any PMO-judgment or governance-binding skill never take a
runtime Anthropic dependency.** They own their generation and harvest at design time.

This rule maps onto the registry's existing four-value enum (it does not coin a new
vocabulary): `independent` = own; `extends`/`pass-through` = the guarded exception; `replaces`
= a deliberate first-party implementation under a colliding name. The registry remains the
**ledger** (it records each skill's posture) and the upstream-reference catalog remains the
**harvest surface**. This ADR is the **single source** of the rule: the registry's update
trigger and the Stage-4 D-Gate **cite** it, they do not restate it.

## Consequences

### Positive

- A skill's sourcing posture becomes a **declared, auditable property**, chosen against a test
  (blast-radius × commodity-stability) rather than defaulted ad hoc.
- Stakeholder-facing output stays **deterministic and first-party** — it cannot silently change
  because an upstream skill shipped a new version.
- New or changed skills declare posture at two existing surfaces (the registry update trigger;
  the Stage-4 D-Gate Upstream-compatibility subsection), so the rule propagates without a new
  gate.
- The justified existing couplings stand: the `skill-creator` wrap (build-time, human-reviewed,
  drift-guarded) and commodity format engines remain legitimately `extends`/`pass-through`.

### Negative / cost

- Own-with-harvest converts runtime-coupling risk into **staleness risk** — a harvested pattern
  stops receiving upstream improvements. Mitigated by the registry's (b)/(c) update triggers
  (re-walk when Anthropic ships or deprecates a skill) and the upstream-reference catalog's
  drift-check cadence.
- One added required line at the Stage-4 D-Gate when a D-decision touches a skill's Anthropic
  coupling.

## Reversibility

**MODERATE / Confidence HIGH.** Reversal is a new superseding ADR plus re-pointing the two
citations (registry trigger, D-Gate line); it introduces no data migration and no schema
change. Pre-application the change is CHEAP; it crosses to MODERATE once skills are
re-classified or re-pointed under the rule.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| **(A) Own-with-harvested-learnings default; guarded-wrap exception keyed on blast-radius × commodity-stability (this ADR)** | **Chosen** | Stakeholder/judgment surfaces stay deterministic and owned; learnings still flow via the upstream-reference catalog; runtime coupling is allowed only where it is safe and is guarded. |
| **(B) Offload / wrap-by-default** | Rejected | Couples stakeholder-facing surfaces to silent upstream drift; the offload milestone already exhibits the failure mode (runtime stakeholder-comms dependency with admitted cadence risk). |
| **(C) Always-own (never wrap)** | Rejected | Wasteful not-invented-here for commodity engines (docx/pptx/pdf/xlsx) whose contracts are stable; converts a managed coupling into pure maintenance/staleness cost with no offsetting control. |

## Related ADRs

- [ADR-019 — Specialists compose, not absorb](ADR-019-specialists-compose-not-absorb.md) — the
  **orthogonal sibling**: ADR-019 governs the skill↔skill relationship (composition axis); this
  ADR governs the skill↔Anthropic relationship (sourcing axis). A skill is classified on both
  axes independently.
- [ADR-003 — Operating Model Composition](ADR-003-operating-model-composition.md) — its
  cite-not-duplicate discipline is the mechanism by which the registry trigger and D-Gate cite
  this ADR rather than restating it.

## References

The issue and initiative numbers below are provenance; the prose above leads with
self-describing roles so the meaning survives renumbering. This block is the designated
reference home.

- The skill-sourcing-coupling posture decision record (this ADR): #762.
- The platform build-philosophy charter that indexes this rule as the sourcing × skills cell, under epic #365 (`initiative:knowledge-architecture`): #761.
- The operationalization (registry trigger + Stage-4 D-Gate wiring + re-point of the conflicting offload issue): #763, applied to #173 / #175.
- The drift-canary precedent that guards the one existing runtime wrap: #193.
- The sibling discipline-codification (read-before-edit) coordinated with this batch: #527.
