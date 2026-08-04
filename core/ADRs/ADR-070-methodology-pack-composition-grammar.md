<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-070 — Methodology-pack composition grammar: widen the type-pack meta-schema to carry a pack-composition layer (a shared _common root via a role discriminator + extends delta-inheritance, a [[labels]] contribution facet, a work-status projection, and RELAXED-to-optional kinds), additive and backward-compatible, extending ADR-018 at grammar altitude"
status: Accepted
date: 2026-07-02
release: 86-methodology-pack-foundation
deciders: "operator (scope-lock 2026-07-01) + Stage 5 Solutioning spoke (Principal Engineer — Architecture) + Collective Review scope-lock"
tags: [methodology-pack, composition-grammar, work-item-type-layer, meta-schema, role-discriminator, delta-inheritance, labels-facet, work-status, additive-extension, cross-cutting]
source_observations:
  - "The type-pack meta-schema (work-item-type-schema.md) models a work-item KIND — its fields, criteria, lifecycle_behavior, and base_kind delta-inheritance — but has no pack-COMPOSITION layer: no notion of a shared _common root a methodology pack extends, no pack-level [[labels]] contribution facet, no pack-level work-status projection, and it treats kinds as the mandatory center of a type-pack. A methodology pack (ADR-069) needs all four to carry a methodology's full operational surface as one selectable unit."
  - "Both Stage-5 pack designs (the pack scaffold #3025 and the label cleave #3021) assumed a wider meta-schema than exists: a pack-level [[labels]] facet keyed to grammar groups, a shared work-status base packs project over, and an optional-kinds _common root. The Collective Review found the grammar-widen (originally the closed #1090 scope) was never scoped, and — per operator directive — absorbed it into the pack layer: the grammar is DESIGNED to accommodate the best-practice-baseline + plug-and-play + override convergence, not the packs bent to fit a rigid grammar."
  - "ADR-039 is the on-precedent shape: it extended ADR-018's grammar additively for the gate-condition surface (an OPTIONAL condition object on an existing checks[] entry; absent = byte-identical prior behavior). This ADR extends the same grammar additively for the pack-composition surface. But the two extensions differ on ONE compatibility axis: ADR-039 added an OPTIONAL field (symmetric forward+backward compat), whereas relaxing a currently-REQUIRED kinds surface to optional is not forward-compatible for a pre-existing validator that assumes kinds present — grounded separately here (the relaxation is currently theoretical: no meta-schema validator exists yet)."
---

# ADR-070 — Methodology-pack composition grammar

## Status

**Accepted.** Sibling to the founding [ADR-069](ADR-069-methodology-pack-composing-unit.md), authored at Stage 6 Engineering as part of the methodology-pack-foundation milestone (`86-methodology-pack-foundation`, epic #1962). It flips to **Accepted** at authoring because the deciding gates already ran: the operator scope-lock that absorbed the meta-schema widen into the pack layer (2026-07-01, recorded in the milestone Amendment Log), and the Stage-5 Solutioning designs (#3025, #3021) whose adversarial passes established the widened surface. The Collective Review recommended a dedicated ADR for this decision (the meta-schema `role`/composition decision is a grammar-altitude decision distinct from ADR-069's composing-unit/placement decision — PA-1), which this ADR is. Consistent with how ADR-039 (the sibling grammar-extension ADR) set its own status at its ratification gate.

## Subordinate to

[ADR-018 — Work-Item Type Layer (WITL)](ADR-018-work-item-type-layer.md). This ADR extends ADR-018's declarative-type-layer grammar for the **pack-composition** surface, exactly as [ADR-039](ADR-039-declarative-gate-conditions.md) extended it for the **gate-condition** surface. It opens **no competing kernel**: ADR-018's kernel disciplines bind it — the grammar projects onto the work-organization mapping framework (never a release-pipeline ticket model), `work_item_type` stays an OPEN/external value domain, and `core/` governance carries no coupling to release-pipeline dev tooling. It is the grammar-altitude sibling of [ADR-069](ADR-069-methodology-pack-composing-unit.md): ADR-069 fixes the composing unit + its placement + its selection; this ADR fixes the meta-schema grammar those pack manifests conform to.

## Context

The type-pack meta-schema (`../schemas/work-item-type-schema.md`) models a work-item **kind**: its `fields`, `criteria` (including `criteria.gate`, extended by ADR-039), `lifecycle_behavior`, `axis1_state_machine`, and the `base_kind` delta-inheritance key (non-null ⇒ inherit + declare deltas; null ⇒ no-fallback root). ADR-018 D1 owns the generic Axis-1 base machine at the entity layer; type-packs *project* methodology labels over it.

A **methodology pack** (ADR-069) is a wider unit than a single kind — it bundles a methodology's full six-facet surface (kinds + work-status + fields + labels + body-schema + gates) as one selectable manifest. Four things the current grammar cannot express are required:

1. **A shared-root composition layer.** A pack needs to declare "I am the shared root that others extend" vs. "I am an archetype pack that extends the root and carries only deltas." The `base_kind` inheritance is a *kind*-level key; there is no *pack*-level equivalent, and no way to say a pack is the root vs. a delta.
2. **A pack-level `[[labels]]` contribution facet.** ADR-069's decision names labels as one of the six facets a pack carries. Today the concrete label rows are instance-coded into `label-taxonomy.md`; a pack needs a first-class facet to contribute the rows it owns, keyed back to the universal label *groups* the grammar defines.
3. **A pack-level work-status projection.** A pack needs to project methodology-specific labels/sub-states over the entity's generic Axis-1 base (Scrum's sprint-timeboxed projection; Kanban's continuous-flow projection) — over, not re-founding, the base machine ADR-018 D1 owns.
4. **Optional `kinds`.** The shared `_common` root pack carries the archetype-invariant surface (work-status, priority, universal labels) but declares **no kinds of its own** — kinds are a per-archetype delta. The current grammar centers a type-pack on its kinds; `_common` needs `kinds` to be legitimately absent.

The Collective Review found this widen (originally the closed #1090 grammar-widen scope) was never scoped, and — per operator directive — absorbed it into the pack layer: the grammar is *designed to accommodate* the best-practice-baseline + plug-and-play + override convergence, rather than the packs being bent to fit a rigid grammar.

## Decision

**Widen the type-pack meta-schema with a pack-composition layer — additive and backward-compatible where each addition permits, grounded separately where it does not.** Four grammar additions, expressed on the `pack.toml` manifest form ADR-069 D4 fixes:

### D1 — A pack `role` discriminator + `extends` delta-inheritance (the composition root)

A pack manifest declares a `role` in its `[meta]` block: `role = "base"` (the shared root — e.g., `_common`) or `role = "archetype"` (a methodology pack — e.g., `scrum`, `kanban`). An archetype pack declares `extends = "<parent-pack>"` (e.g., `extends = "_common"`) meaning "start from the named parent as the DEFAULT; this file declares deltas only." A `base` pack declares `extends = ""` (empty ⇒ root, no parent). This is the FROZEN `base_kind` / `base_archetype` contract lifted one altitude (pack vs kind) — one delta-inheritance mental model across the platform. The `role` discriminator is what lets the grammar treat a `base` pack's absent `kinds` as legitimate (D4) and lets a validator apply the correct completeness rule per role.

### D2 — A pack-level `[[labels]]` contribution facet

The meta-schema gains a `[[labels]]` array on a pack: each entry is a concrete label row (`name`, `color`, `description`, `applied_at`/`removed_at`) plus a REQUIRED `group` key binding the row to a universal label *group* the grammar defines (`category` | `status` | `cluster` | `initiative` | `triage-flag` | `disposition`). A `type:*` label row additionally carries `projects_kind = "<kind_id>"`, the join key into the pack's `kinds[]`, so the `type:*` family stays in lockstep with the pack's declared kinds (no independent drift). The contract direction is fixed: the grammar defines label *groups* (in `label-taxonomy.md`); packs *populate* them. This is the facet the #1970 label-cleave slice moves the instance rows into.

### D3 — A pack-level work-status projection over the entity base

The meta-schema gains a pack-level work-status projection: a pack MAY project methodology-specific labels/sub-states over the generic Axis-1 base machine owned by the entity layer (ADR-018 D1). The projection is *over* the base, never a re-founding of it (a pack cannot redefine the generic `backlog → ready → in-progress → in-review → done | cancelled` machine; it labels/sub-states within it). `_common` carries the shared base projection; archetype packs carry only their sub-state deltas.

### D4 — `kinds` RELAXED to optional (role-conditioned)

The meta-schema relaxes `kinds` from the currently-mandatory center of a type-pack to **optional, conditioned on `role`**: a `role = "base"` pack MAY declare zero kinds (the archetype-invariant root carries work-status/priority/labels but no kinds of its own); a `role = "archetype"` pack declares the kinds it contributes. This is the one addition that is **not symmetric on both compatibility axes** — see § Consequences: relaxing a currently-required surface to optional is backward-compatible for existing packs (which all declare kinds) but is not forward-compatible for a hypothetical pre-existing validator that assumes kinds present. It is grounded separately from the optional-ADD precedent (ADR-039) for exactly this reason.

**Backward-compatibility envelope.** D1–D3 are optional-ADDs (a manifest without `role`/`extends`/`[[labels]]`/work-status projection is byte-identical to a pre-widen type-pack — the same shape ADR-039 preserved for the absent `condition`). D4 is the relaxation, role-gated so the completeness rule a validator applies is selected by `role`. The meta-schema version bumps per the additive-change discipline (`work-item-type-schema.md` §6.1 minor bump = additive); the widen is additive at the grammar level (no existing key changes meaning; no existing pack becomes invalid).

## Alternatives Considered

The four grammar additions were largely *required* rather than selected — § Context enumerates four things the current grammar cannot express that the pack model needs — so this record weighs shape and grounding rather than a set of competing designs.

- **Bend the packs to fit the existing rigid grammar** — **not taken.** § Context records the operator directive the other way round: the grammar is *designed to accommodate* the best-practice-baseline + plug-and-play + override convergence, rather than the packs being bent to fit a rigid grammar.
- **Fold this decision into the founding sibling ADR** — **not taken.** § Provenance records the Collective Review's recommendation (PA-1) that the meta-schema `role` / composition decision is a grammar-altitude decision distinct from the composing-unit and placement decision, and therefore warrants its own record.
- **Ground the `kinds` relaxation on the existing optional-ADD precedent** — **not taken.** § Consequences grounds it separately and states why: the precedent is an optional-ADD symmetric on both compatibility axes, whereas relaxing a required surface to optional is not forward-compatible for a pre-existing validator. The asymmetry is recorded honestly rather than claimed as clean-additive.

The residual is named rather than resolved: the relaxation lands before any meta-schema validator exists to be broken by it, so the obligation transfers — when a validator is built it must be role-aware from the start rather than retrofitted onto a kinds-mandatory assumption.

## Consequences

### Positive

- A methodology pack (ADR-069) can carry its full six-facet surface in one manifest conforming to one grammar — kinds + work-status + fields + labels + body-schema + gates.
- The shared `_common` root + `extends` delta-inheritance means the archetype-invariant ~80% is authored once and inherited, never re-authored per archetype (the thin-pack dividend).
- The `[[labels]]` facet gives the #1970 label-cleave a first-class home to move instance rows into, resolving the `label-taxonomy.md` grammar-vs-instance fusion without inventing a bespoke label store.
- The `role` discriminator makes the grammar self-describing about pack completeness (a `base` pack legitimately has no kinds; an `archetype` pack does), so a future meta-schema validator applies the correct rule per role rather than a single rigid rule.
- Additive and backward-compatible for D1–D3 (absent facets are byte-identical to prior behavior); the meta-schema stays at a minor-bumped version, no grammar re-open for a later fifth facet.

### Negative / cost

- **D4 is asymmetric on the forward-compat axis.** Relaxing a required surface to optional is not forward-compatible for a pre-existing validator that assumes `kinds` present — distinct from ADR-039's optional-ADD (which is symmetric: an old reader ignores an absent optional field, and a new reader tolerates it). This is currently **theoretical**: no meta-schema validator exists yet (the #1968 AC's "validator once available" is a declared-but-deferred method), so the relaxation lands before any validator can be broken by it. Recorded honestly rather than claimed as clean-additive: when a validator is built, it must be built role-aware from the start (apply the completeness rule per `role`), not retrofitted onto a kinds-mandatory assumption.
- A new pack-composition layer in the meta-schema — the first grammar construct that composes *packs* (not just kinds); a precedent any future pack-level facet inherits.
- The `[[labels]]` facet is a new contribution surface the grammar must keep consistent with the label groups defined in `label-taxonomy.md` (the contract direction — grammar defines groups, packs populate — is the guardrail against drift).

### Cross-D upstream-compat

The widened grammar inherits ADR-018's OPEN-value-domain discipline: no consumer may treat the set of pack `role` values, or a pack's declared `kinds`, or the shipped archetype set, as a closed enum. The `role` discriminator is a small controlled enum (`base` / `archetype`) at the composition layer, but the *kinds* a pack declares and the *archetypes* that exist remain open — treating them as closed would re-trap the open type/methodology set in the frozen-roster anti-pattern.

## Reversibility

**MODERATE / Confidence HIGH pre-consumption** — before a deployment authors packs against the widened grammar and before any consumer resolves against it, the grammar addition is a free choice: D1–D3 are additive (absent facets byte-identical to prior behavior) and D4's relaxation lands before any validator exists to be broken by it. Crosses to **EXPENSIVE** once packs declare `role`/`extends`/`[[labels]]`/work-status projections AND the consumer read-refit (#2021) resolves against them — at that point the widened grammar is a contract and undo means a criteria-version migration plus unwinding every consumer. Deciding the four grammar additions at this founding moment is the cheap moment (the ADR-039 lesson: retrofitting a grammar facet after live consumers exist is expensive); the specific cheap-now/expensive-later item is D4's role-conditioned optionality — building the eventual validator role-aware from the start costs nothing now and is expensive to retrofit under a kinds-mandatory assumption.

## Related ADRs

- [ADR-018 — Work-Item Type Layer (WITL)](ADR-018-work-item-type-layer.md) — the parent kernel this ADR extends at grammar altitude (thin generic Work Item entity + declarative type layer; the generic Axis-1 base machine D3 projects over; the OPEN-value-domain discipline). This ADR widens ADR-018's grammar for the pack-composition surface and opens no competing kernel.
- [ADR-069 — Methodology pack as the plug-and-play composing unit](ADR-069-methodology-pack-composing-unit.md) — the founding sibling; ADR-069 fixes the composing unit + placement + selection, this ADR fixes the meta-schema grammar those manifests conform to.
- [ADR-039 — Declarative gate-condition construct](ADR-039-declarative-gate-conditions.md) — the on-precedent shape for an additive ADR-018 grammar extension (an OPTIONAL construct on an existing entry; absent = byte-identical prior behavior). D1–D3 follow this optional-ADD pattern; D4 deliberately departs from it on the forward-compat axis (a relaxation, not an add) and is grounded separately for that reason.
- [ADR-022 — platform-config.toml vs operator.toml split](ADR-022-platform-config-vs-operator-toml-split.md) — establishes TOML as the config-manifest surface the `pack.toml` form (and this grammar) is expressed on, and the `[meta] schema_version` additive-bump discipline the meta-schema version follows.

### Provenance

This decision was recommended by the Collective Review as a dedicated ADR (PA-1: the meta-schema `role`/composition decision is a grammar-altitude decision warranting its own ADR, distinct from ADR-069's composing-unit/placement decision), authored as part of the methodology-pack-foundation milestone (#1962). The widen was originally the closed #1090 grammar-widen scope; the Collective Review scope-lock (recorded in the milestone Amendment Log) absorbed it into the pack layer per operator directive and expanded the #1968 slice to own it. The four grammar additions are grounded in the two Stage-5 pack designs whose adversarial passes established the widened surface: #3025 (the pack scaffold — the `role`/`extends` composition + the `pack.toml` form) and #3021 (the label cleave — the `[[labels]]` contribution facet keyed to grammar groups + `projects_kind`). The separate grounding of D4 (the `kinds` requiredness-relaxation) from ADR-039's optional-ADD precedent follows the Collective Review's carried Stage-6 fix (PR-A / FM-A / PA): ADR-039's precedent is an optional-ADD symmetric on both compat axes, whereas a relaxation is not forward-compatible for a pre-existing validator — currently theoretical, as no meta-schema validator yet exists. The grammar edits this ADR governs are implemented by the #1968 slice in `work-item-type-schema.md`; this ADR records the decision kernel those edits implement.
