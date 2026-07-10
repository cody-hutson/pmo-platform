<!-- reference-durability: allow-link -->
---
title: "ADR-077 — Cross-cutting control-field layer: pack-level [[controls]] facet + the Arm-3 control-field body"
status: Accepted
date: 2026-07-09
release: 87-methodology-pack-catalog (v3.67; bound at Stage 12)
deciders: "operator (release-plan approval + Collective Review scope-lock) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment)"
tags: [work-item-type-layer, meta-schema, control-field, controls-facet, gate-conditions, cross-kind, cross-level, EAD-annotation, additive-extension, reserve-then-specify]
source_observations:
  - "The type-pack meta-schema modeled fields and criteria per kind only: a shared readiness/tracking dimension (a design-readiness state, an architecture-review status) required re-declaring the same field N times across kinds — forking one dimension's value domain N ways and breaking any cross-kind filter or gate that needs one id and one value set spanning kinds and hierarchy levels."
  - "A field value had no declared coupling to a gate or a filter: nothing in the grammar said 'this value is readable as a gate input and by grooming/planning automations' — the value→gate/filter seam existed only as intent."
  - "Arm 2 (set-aggregate) shipped a limit_ref key referencing a <control-field-id> with no declaration surface anywhere in the grammar — a dangling forward-reference awaiting a declaration home."
  - "The Arm-3 control-field discriminator value was registered as a fail-loud RESERVED slot (a pack using it failed pack-validation by design: 'reserved, not yet implemented') with its body — field_ref / value_in / scope — explicitly left for the specifying decision. This ADR is that decision."
---

# ADR-077 — Cross-cutting control-field layer

## Status

**Accepted.** Authored at Stage 6 Engineering of the methodology-pack-catalog release. It records Accepted at authoring — and records the flip here rather than deferring it — because the deciding gates already ran before the file was authored: the operator's release-plan approval bound the Stage-5 rider set (specify the reserved Arm-3 slot only; no criterion-grammar re-open; feed the existing architecture/DoR gate; no second gate), and the operator's Collective Review scope-lock ratified the Stage-5 design (the pack-level `[[controls]]` mechanism, the `scope: self` v1 vocabulary, the meta-schema-stays-v1 determination, and this ADR's allocation as the decision record). Recording the ratification at authoring is the same move the sibling grammar-extension record [ADR-070](ADR-070-methodology-pack-composition-grammar.md) made at its gate — and it deliberately avoids the known ratified-but-never-flipped drift the declarative-gate-conditions record ([ADR-039](ADR-039-declarative-gate-conditions.md)) exhibited after its own release shipped.

## Subordinate to

[ADR-018 — Work-Item Type Layer](ADR-018-work-item-type-layer.md). This ADR extends ADR-018's declarative-type-layer grammar for the **cross-cutting control** surface, exactly as [ADR-039](ADR-039-declarative-gate-conditions.md) extended it for the gate-condition surface and [ADR-070](ADR-070-methodology-pack-composition-grammar.md) for the pack-composition surface. It opens **no competing kernel**: ADR-018's kernel disciplines bind it — the grammar projects onto the work-organization mapping framework (never a release-pipeline ticket model), external consumers are named **by name with no path dependency**, and the dependency direction is consumer→grammar only. It **fills the arm ADR-039 reserved**: ADR-039 registered the `control-field` discriminator as a fail-loud reserved slot and recorded that the reserved arm inherits its gate-layer disposition set; this ADR specifies that arm's body and its declaration surface.

## Context

The type-pack meta-schema (`../schemas/work-item-type-schema.md`) modeled fields + criteria **per kind** only. Four forces converged:

1. **Shared dimensions required N-kind repetition.** A readiness/tracking dimension that spans kinds (design readiness, architecture-review state) had to be re-declared as a `fields.kind_specific[]` entry on every kind — N copies of one value domain, drifting independently.
2. **No value→gate/filter coupling.** A field value had no grammar-level contract making it readable as a gate input or a grooming/planning filter; cross-kind filterability requires one id and one value domain spanning kinds and hierarchy levels.
3. **A dangling reference.** Arm 2's `limit_ref: <control-field-id>` (the WIP-cap-as-config composition) referenced an id with **no declaration home** anywhere in the grammar.
4. **A registered reserved slot.** The §1.2.1 condition discriminated union carried `control-field` as a RESERVED third arm — fail-loud at pack-validation, body (`field_ref` / `value_in` / `scope`) unspecified, registered precisely so the field axis could land later **without re-opening the criterion grammar**.

The first proving instance is a **design & architecture control set** (design-readiness + architecture-review-status), declared operator-locally (K4) — the grammar ships the capability; no shipped pack declares controls at introduction.

## Decision

**D1 — Pack-level `[[controls]]` declaration facet (declare once, project per kind).** The meta-schema gains a `[[controls]]` array on a pack (§1.1.2), permitted on both `role` values — a `role = "base"` pack is the natural home for archetype-invariant controls, inherited via `extends`. Each entry declares one cross-cutting control: `control_id` (the id `field_ref` and `limit_ref` resolve against), `display_name`, optional `description`/`default`, a REQUIRED `value_domain` (v1 type set `{enum, integer}`; `integer` is the domain a `limit_ref` target MUST declare; further types RESERVED fail-loud), and a REQUIRED `applies_to` span (`levels[]` from the work-organization mapping framework's Layer-1 taxonomy; `kinds[]` required iff `Work Item` is in scope, `"*"` = every kind). Per-kind FieldDecl-annotation and shared-criteria-reference designs were rejected (see Alternatives): declaring once at pack level is what makes one `control_id` + one value domain span kinds and levels by construction.

**D2 — Arm-3 `control-field` body.** `field_ref` (REQUIRED — must resolve to a visible `[[controls]]` declaration; unresolvable = pack-validation error, the Arm-1 posture) · `value_in[]` (REQUIRED, ≥1 — each member load-validated against the declared `value_domain`, statically checkable because the domain is declared) · `scope` (OPTIONAL, DEFAULT `self` — the transitioning item's own projected control property; `{parent, project, board}` registered-RESERVED fail-loud until container-level value carriage ships, then reusing Arm 2's `set.scope` container vocabulary) · `on_unresolved` (REQUIRED — inherits the ADR-039 gate-layer disposition set `{BLOCK-TRANSITION, WARN-HEALTH}`; a recorded ADR-039 consequence, not a new key).

**D3 — A third EAD annotation class.** A control-field gate check materializes as a NEW `x-pmo-control` annotation (L2 control-value sub-class, modeled on `x-pmo-referential` for level + disposition), and each in-scope control projects into a kind's EAD-materialized schema as one property carrying the `x-pmo-control-source` provenance key. **No new physicalization and no new enforcer** — the read bites at the single existing enforcement point (the tracker-manager pre-write/transition pass); the only evaluation surface is a declaration lookup + scoped value read + membership compare.

**D4 — The value→gate/filter coupling contract (three consumer classes).** (1) Kind **transition gates** read a control via the Arm-3 condition — gate-only, firing stays `lifecycle_behavior`-keyed. (2) Kind **readiness/done checks** consume a control as a plain self-evaluating field check — the rule that a `condition` on readiness/done is a pack-validation error is UNCHANGED; the DoR path needs no grammar change because the projection makes controls into ordinary fields. (3) **Design/architecture review gates + grooming/planning automations** read the projected property or container stamp directly — the platform's Stage-5 design-handoff architecture/best-practice gate (the Structure-Review gate, SR-G1–SR-G4) is the first named external consumer, referenced by name with no path dependency; the dependency direction is consumer→grammar only. The control layer defines the **value**, never the **firing** — a control adds no cadence or gate-firing semantics.

**D5 — Meta-schema stays v1.** By the same two-axis analysis as the pack-composition widen (§6.2a → §6.2b): `[[controls]]` is an optional ADD (a pack declaring none is byte-identical), and specifying the Arm-3 body converts a fail-loud reserved value into a defined one (no existing valid pack changes meaning — a pack using `kind: control-field` before this specification failed pack-validation by design; reserve-then-specify is the slot's registered lifecycle). Validator-forward: the widen ships ahead of any meta-schema validator. A pack that adopts controls takes a `pack_version` minor bump per §6.1.

## Alternatives rejected

1. **Pack-level `shared_criteria[]` reference** (share check definitions, kinds reference them into `criteria`) — shares *checks*, not *values*: declares no filterable value domain, no field a gate can read, and no id `limit_ref` can resolve; a pack-level criteria mirror IS the parallel-criteria path the release plan named as a rejection trigger.
2. **Per-kind FieldDecl annotation** (annotate a `fields.kind_specific[]` entry as a control) — per-kind re-declaration forks the value domain N ways (drift), kills cross-kind filterability, and a kind-scoped id can host neither container-level values (≥2 hierarchy levels) nor `limit_ref` (a board-scoped cap); it formalizes the status quo the change exists to fix.
3. **Entity-layer first-class field** (add control fields to the `Work Item` entity schema) — the entity substrate is FROZEN; operator-declared dimensions would become entity-schema migrations — K4 data trapped in the K1 kernel.
4. **`project-schema.md` placement** (declare controls in project configuration) — project config is the pack-*selection* surface, not a grammar surface; the placement also collided with a sibling slice's exclusive file surface in the same release.

## Consequences

- **+** One declaration spans kinds and hierarchy levels: one `control_id`, one value domain, one filter predicate — the cross-kind filter/gate contract holds by construction.
- **+** Arm 2's `limit_ref` forward-reference gains its declaration home plus a load-time validation rule (the referenced control must declare an `integer` domain).
- **+** Filter, gate, and DoR consumption arrive with **zero consumer code changes** — the registry-read design routes the new read through the existing single enforcement point; DoR checks consume controls as ordinary fields.
- **+** Cycle-safety: a `control-field` check contributes **no** gating-graph edge — a control value is item/container data written by an ordinary field write, not an axis1 state produced by a guarded transition — so the arm adds no cycle class to the gating-cycle detector.
- **−** A reserved-scope widening release is owed when container-level value carriage ships (the `{parent, project, board}` scopes un-reserve then, reusing Arm 2's container vocabulary).
- **−** First control adopters take the §6.1 `pack_version` minor bump; once packs declare controls the shape hardens (the pre-consumption window is the cheap moment to adjust — the same framing ADR-039 recorded for its construct).

## Reversibility

**CHEAP pre-consumption → MODERATE once packs declare controls** (the ADR-039 framing for grammar surfaces that harden on adoption) / Confidence **HIGH**. At introduction zero packs declare `[[controls]]` and the shipped control set is K4 operator-local with no repo surface — a single-PR revert restores the prior grammar byte-for-byte.

## Related ADRs

- [ADR-018 — Work-Item Type Layer](ADR-018-work-item-type-layer.md) — the kernel this extends at grammar altitude; its disciplines (methodology-projection, release-pipeline neutrality, open value domains) bind.
- [ADR-039 — Declarative gate conditions](ADR-039-declarative-gate-conditions.md) — registered the reserved `control-field` arm this ADR fills; its gate-layer disposition set is inherited by D2; its additive-extension + anti-EAV requirements carry.
- [ADR-070 — Methodology-pack composition grammar](ADR-070-methodology-pack-composition-grammar.md) — the sibling lineage move; the `[[controls]]` facet mirrors its `[[labels]]` contribution-facet shape (D2), and §6.2b mirrors its §6.2a stays-v1 analysis.
- [ADR-069 — Methodology-pack composing unit](ADR-069-methodology-pack-composing-unit.md) — the pack manifests that will carry `[[controls]]` declarations conform to the grammar this ADR extends.
