---
title: ADR-018 — Work-Item Type Layer (WITL) — thin generic Work Item entity + declarative type layer
status: Accepted
date: 2026-06-07
release: declarative-workitem-type-model
deciders: "operator (D1/D2/D4 ratified 2026-06-07) + Stage 5 Solutioning + Collective Review scope-lock"
tags: [entity-model, work-item, type-system, methodology-projection, tier-2-scope-change, hybrid-architecture]
source_observations:
  - "The frozen 17-entity model bottoms out at Milestone — no delivery work-item entity exists beneath Milestone/Workstream, so container rollup has no child to aggregate from. (Work-Item Type Layer initiative discovery.)"
  - "A work-item instance IS a tracked record (boundary axiom) so it needs entity-graph membership; but the work-item TYPE set is open/declarative and cannot be a frozen-roster member. The tension resolves as a hybrid: one thin generic entity + a separate declarative type layer."
  - "The governance is a standardization of work organization: it ships universal principles, a domain-neutral methodology->hierarchy map (the work-organization mapping framework), and best-practice default work-item schemas, and supports the user bringing/overriding their own work-item types. Work TYPES are user config, not baked into the package; the operator's own project work and the platform's own dev tooling are instances under the model, not its definition."
  - "Relationship vocabulary (7 MVP types) already exists and is frozen/built — WITL references it, it does not redefine it. (per the directional-not-authoritative intake principle — reconcile, don't perpetuate.)"
---

# ADR-018 — Work-Item Type Layer (WITL)

## Status

Accepted (2026-06-07). This decision was ratified at the declarative-workitem-type-model
Stage 9 GO — that operator GO rendered the **Tier-2 SCOPE CHANGE** authorization
required by the FROZEN-roster clause of
[`project-entity-model.md` §4](../disciplines/project-entity-model.md#4-entity-definitions-19)
("any change requires reopening the establishing issue via a Tier-2 SCOPE CHANGE").
Per the core-ADR convention, this decision is captured as a committed ADR document
authored alongside the entity-model and field-schema edits in the same release.

Provenance: this decision establishes the Work-Item Type Layer; the layer's
authorization and the subsequent declarative type-pack meta-schema are tracked
under the Work-Item Type Layer initiative (D1/D2/D4 ratified 2026-06-07).

## Context

The 17-entity container model
([`project-entity-model.md`](../disciplines/project-entity-model.md), frozen
2026-05-16) has **no entity beneath Milestone/Workstream**; the finest tracked unit
is Milestone. Container rollup (the F3 gap — "all work items belonging to Milestone
X") and work-item-level referential integrity (a `BLOCKS`/`DEPENDS_ON` edge to or
from a work item) are therefore unmodellable: there is no node to attach the edge to.

Two in-package assets are relevant:

- The **7 MVP relationship types** (`GENERATES` / `DEPENDS_ON` / `BLOCKS` /
  `SUPERSEDES` / `BELONGS_TO` / `RELATES_TO` / `ASSIGNED_TO`), built and frozen in
  `frontmatter-schema.md` §Category 4. WITL **references** them; it never redefines
  the vocabulary.
- The **canonical term** `Work Item`, fixed by the glossary
  [`terminology-glossary.md` §term-work-item](../specs/terminology-glossary.md#term-work-item),
  whose Appendix B bans Story / Epic / Feature / User-Story / Ticket / Work-Package
  as canonical synonyms. The methodology→kind projection (Issue → Story / Task /
  Work-Package and the like) is not owned by any release-pipeline support tool — it
  is a property of the domain-neutral **work-organization mapping framework**
  shipped in `core/` (see the Governance spectrum below).

The operator ratified D1/D2/D4 for the Work-Item Type Layer initiative on
2026-06-07.

### Governance spectrum — standardization of work organization

This entity model is a **standardization / templatization of work organization**,
shipped **full-spectrum and plug-and-play down to the ticket level**. It is not a
codification of the operator's own project work or of the platform's own
GitHub/pipeline development — those are *instances* under the model and must not
define its best-practice structure, nor may operational/dev-tooling data be baked
into the governance template. The package ships:

1. **Concept of Work Organization** (K1) — the universal principles and the purpose
   of each hierarchy level.
2. **Hierarchy-by-methodology map** (K1) — a domain-neutral, best-practice map of
   how typical methodologies populate the hierarchy (the **work-organization mapping
   framework**).
3. **Work-item best-practice schemas** (K1) — the shipped default work-item schemas.

…and supports:

4. **User plug-and-play** (K4) — the user brings or overrides their own work-item
   schemas (operator-local). **Work TYPES are user config, not baked into the
   package.**

The agent reasons over the shipped layers 1–3 to understand any user's brought work
(4) "by nature." This ADR governs the structure (the entity + the map + the
best-practice defaults + the type-pack meta-schema grammar); the concrete work-item
types are user config.

## Decision

### D1 — Data model = HYBRID

Add **one thin generic `Work Item` entity** to the roster (entity 18): the
inherited Entity Core 7 + a `work_item_type` **discriminator** + a **polymorphic
`parent_ref`** (a `BELONGS_TO` parent that is a Milestone *or* a Workstream) +
`relationships[]` (the built 7 MVP types, by reference). The entity joins the graph
(referential integrity + the rollup edge); **all type variability** — Story / Bug /
Test / Task fields, per-kind readiness/done/gate criteria — lives in the separate
**declarative type-pack layer** (a subsequent slice of this initiative). The
pattern mirrors the platform's own
`delivery_approach` + `custom_methodology_definition` and the RAID-Item →
`raid-log.schema.json` EAD materialization.

The entity's **Axis-1 base machine** —
`backlog → ready → in-progress → in-review → done | cancelled` — is owned **here**
(it is required at C1 for the entity to satisfy V-CORE-03; an entity with no Axis-1
machine would be the only roster member missing one). The declarative type layer's
type-packs **project** methodology-specific labels over this base and MAY add
type-scoped sub-states; they do not re-found the base machine.

### D2 — Vocabulary = methodology-projected

The canonical kind is `Work Item`. Story / Bug / Test / Task are **per-methodology
projections** declared in the declarative type layer's type-pack, projected onto the
**general hierarchy** through the domain-neutral **work-organization mapping
framework** (the best-practice methodology→hierarchy map shipped in `core/`) — *not*
onto any release-pipeline support tool. **No glossary amendment** — the glossary
already bans the non-canonical synonyms and remains the single canonical home of the
term `Work Item` (see § Operations entity vs. dev-tooling ticket below for why the
operations template stands alone and does not couple to the release pipeline).

### D3 — Now-milestone scope

This ADR (establishing) + the declarative type-pack meta-schema + the layer
authorization. The deferred slices — methodology breakdown, propagation refit,
rollup/translation-fidelity, storage/projection, glossary, migration — are tracked
under the Work-Item Type Layer initiative and are out of this milestone.

### D4 — Tier-2 SCOPE CHANGE

Adding the entity reopens the establishing issue per the FROZEN-roster clause of
`project-entity-model.md §4`. This is precedented by the 2026-05-16 RAID Item
amendment (which added `impact` / `action_plan` to an existing entity; this adds an
entity — the larger-but-still-precedented move, same change *class*). The roster is
**RE-FROZEN at 18 entities** with this addition.

## Operations entity vs. dev-tooling ticket (kernel discipline — analogous, not the same concept)

Two surfaces carry work-item-shaped data, and they are **analogous but NOT the same
governed concept**:

- The **operations `Work Item`** — entity 18 in
  [`project-entity-model.md`](../disciplines/project-entity-model.md): the
  operations-domain hierarchy node. A tracked data record with a field schema, a
  two-axis lifecycle, and entity-graph membership. Its canonical name is fixed by
  [`terminology-glossary.md` §term-work-item](../specs/terminology-glossary.md#term-work-item);
  its methodology→kind projection runs through the domain-neutral
  **work-organization mapping framework** shipped in `core/`.
- The **platform's own dev-tooling ticket** — the GitHub-Issue-backed unit the
  release pipeline uses to develop the platform itself. It is the platform's
  *instance* of work tracking, not the governed operations concept.

These are **analogous, not unified.** The operations `Work Item` entity does **not**
depend on, fork, or unify with the release-pipeline ticket model, and the operations
governance template must **not** bake the platform's own dev-tooling structure into
itself. This is a **kernel discipline**: `core/` governance must not couple to
`release/`. A dependency from the operations entity model onto a release-pipeline
support tool would be a kernel→`release/` dependency inversion — it would let the
platform's own dev tooling define the best-practice work-organization structure that
the template ships for *any* user. The projection therefore lands on the general
hierarchy via the in-`core/` work-organization mapping framework (a domain-neutral
methodology→hierarchy map), keeping the operations template self-standing. The
glossary remains the single canonical home of the term `Work Item`.

## Consequences

### Positive

- The container↔work-item **rollup edge exists** — the F3 gap closes; Milestone /
  Workstream status can aggregate from work-item children.
- **Future work-item kinds never amend the roster** — the thin-entity dividend: a new
  methodology or kind parameterizes the declarative type layer, with zero
  governance change per kind.
- **The operations template stands alone** — the operations `Work Item` entity
  projects onto the general hierarchy through the in-`core/` work-organization
  mapping framework; it neither depends on nor unifies with the release-pipeline
  ticket model, so `core/` carries no coupling to `release/`.

### Negative / cost

- One scoped Tier-2 plus a roster `17 → 18` count cascade across two corpus files
  (`project-entity-model.md`, `entity-field-schemas.md`) — mechanical, enumerated in
  the Stage 5 cascade-sweep.
- the declarative type layer becomes a **hard consumer**: once it resolves
  `work_item_type` against the type registry, the entity is a contract.

### Cross-D upstream-compat

The discriminator's value domain is **OPEN / external** — no downstream consumer may
treat `work_item_type` as a closed enum. Doing so would re-trap the open type set in
the frozen-roster anti-pattern this initiative exists to eliminate.

## Reversibility

**EXPENSIVE / Confidence HIGH.** Once the type layer + downstream consume the entity
it is a contract; undo means unwinding the type layer + every consumer. The Tier-2 +
this ADR + the Stage 9 GO are the sign-off gate. Pre-consumption — before the type
layer's implementation lands — the change is MODERATE (a new file + an additive §4
block); it crosses to EXPENSIVE at the first consumer.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| **(A) Floating type layer (no entity)** | Rejected | A declarative type system with no entity-graph member violates the boundary axiom (a work-item instance IS a tracked record); leaves rollup/integrity edges with no node to attach to (F3 stays open); breaks referential integrity for `BLOCKS`/`DEPENDS_ON` to/from work items. |
| **(B) 18th "fat" entity (type baked in)** | Rejected | One entity per kind, or one entity with a frozen kind-enum + all per-kind fields inline, re-freezes an OPEN set (every new methodology/kind becomes a roster Tier-2 — exactly the governance debt the hybrid avoids); explodes the field list; collides with the work-organization mapping framework instead of projecting through it. |
| **(C) Reuse Milestone / Artifact** | Rejected | Milestone is a dated checkpoint (wrong semantics + cardinality); Artifact is a deliverable file whose Axis-1 *delegates to Axis-2* (a backing-file Domain lifecycle) — a work item is operational, not a file. Neither carries a `work_item_type` discriminator or the work-item Axis-1 machine. |
| **(D) Hybrid — thin generic entity + declarative type layer (this ADR)** | **Chosen** | Satisfies the boundary axiom (the instance is a graph member), gives rollup/integrity a node, and keeps the open type set declarative so future kinds never amend the roster. |

## Related ADRs

- [ADR-016](ADR-016-intake-front-door-architectural-boundary.md) — establishes
  `intake-desk` as the work-item-lifecycle front door and records that "the
  work-item type system, when it lands, extends the type set the front door binds
  to." THIS is that system; `intake-desk` is the creator owning-agent of the
  Work Item entity, and its `references/type-map.md` seam repoints to the type layer
  when it lands. The component boundary and handoff contract ADR-016 recorded are
  unaffected.
- The Two-Axis Entity Lifecycle ADR (ratified at Collective Review, 2026-05-16) — the
  Axis-1 / Axis-2 lifecycle basis the Work Item entity instantiates (Axis-1 operational
  machine owned here; Axis-2 = Living (B)).
