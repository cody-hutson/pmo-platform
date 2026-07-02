<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-068 — Methodology pack as the plug-and-play composing unit: a per-archetype manifest at core/packs/<archetype>/ bundling a methodology's full operational surface (kinds + work-status + fields + labels + body-schema + gates) as best-practice defaults, selected per delivery_approach and overridable per project"
status: Accepted
date: 2026-07-02
release: 86-methodology-pack-foundation
deciders: "operator (scope-lock 2026-07-01) + Stage 5 Solutioning spoke (Principal Engineer — Architecture) + Collective Review scope-lock"
tags: [methodology-pack, plug-and-play, work-item-type-layer, delivery-approach, best-practice-defaults, byo-override, knowledge-architecture, composition, cross-cutting]
source_observations:
  - "The platform models work-item KINDS as a declarative type-pack (ADR-018 / work-item-type-schema.md), but a methodology's FULL operational surface — kinds + work-statuses + sortable fields + labels + body-schema + gates — is spread across separate docs (label-taxonomy.md, ticket-information-architecture.md, field-lifecycle-matrix.md) and is partly instance-coded to this repo. There is no single plug-and-play unit a deployment selects per delivery_approach, and no clean best-practice -> platform -> project (K1 -> Layer-3 -> K4) seam for the non-kind surfaces."
  - "Operator intent (methodology-packs epic #1962): run a Hybrid-Two [Scrum, Kanban] delivery model and add further archetypes as thin deltas without a repo restructure. Statuses are generally the same for delivery work -> a shared work-status base with per-pack deltas only. The public corpus stays methodology-NEUTRAL; a methodology's concrete selection stays operator-local config, never baked into the package (the ADR-018 kernel: work TYPES are user config)."
  - "ADR-018 already established the seam this ADR completes: the operations Work Item entity projects onto the domain-neutral work-organization mapping framework, ships best-practice default schemas (K1) at layers 1-3, and supports user plug-and-play/override (K4). ADR-018 named the KIND surface; the methodology's non-kind surfaces (work-status projection, labels, gates, body-schema) had no equivalent composing unit until this ADR."
---

# ADR-068 — Methodology pack as the plug-and-play composing unit

## Status

**Accepted.** This is the founding ADR of the methodology-pack-foundation milestone (`86-methodology-pack-foundation`, epic #1962) and is authored at Stage 6 Engineering as the Wave-0 first slice of the methodology-packs track — the ADR *is* the Stage-5 design act for its issue (#1967), per the ADR-sliced-into-hub-spoke pattern the platform uses for a founding ADR that inaugurates a track. It flips to **Accepted** at authoring because the deciding gates already ran: the operator scope-lock (2026-07-01, recorded in the milestone Amendment Log), the Stage-5 Solutioning designs (#3025 for the pack scaffold, #3021 for the label cleave), and the Collective Review scope-lock that absorbed the type-pack meta-schema widen into the pack layer. This is consistent with how the establishing ADR-018 decision set its own status at its ratification gate.

## Subordinate to

[ADR-018 — Work-Item Type Layer (WITL)](ADR-018-work-item-type-layer.md). This ADR completes ADR-018's governance spectrum (the K1 best-practice-defaults + K4 plug-and-play/override model) for a methodology's FULL operational surface, not just the KIND surface ADR-018 named. It opens **no competing kernel**: ADR-018's kernel disciplines bind it — a pack projects onto the domain-neutral work-organization mapping framework (never a release-pipeline ticket model), `work_item_type` stays an OPEN/external value domain, and `core/` governance carries no coupling to release-pipeline dev tooling. The *composition grammar* that widens the meta-schema to carry the pack model (the pack-level `[[labels]]` facet, work-status projection, optional `kinds`, and the `role`/composition altitude) is the sibling decision recorded in [ADR-069](ADR-069-methodology-pack-composition-grammar.md); this ADR records the *composing-unit + placement + selection* decision that ADR-069's grammar realizes.

## Context

The platform ships a **standardization of work organization**, plug-and-play down to the ticket level (ADR-018 § Governance spectrum): universal principles (K1), a domain-neutral methodology→hierarchy map (K1), and best-practice default work-item schemas (K1), with user plug-and-play/override (K4). ADR-018 externalized ALL *type* variability (per-kind fields, readiness/done/gate criteria) into a declarative type-pack layer so a new kind never amends the frozen entity roster.

But a **methodology** is more than its kinds. Its full operational surface is six facets:

1. **kinds** — the work-item types it declares (Scrum: epic/story/task; Kanban: card) — already modeled by ADR-018's type-pack.
2. **work-status** — the Axis-1 lifecycle projection (Scrum's sprint-timeboxed states; Kanban's continuous flow) over the entity's generic base machine.
3. **sortable fields** — the ordering/estimation fields (Scrum story points; Kanban class-of-service).
4. **labels** — the concrete label rows the methodology contributes (a `type:*` family projecting its kinds, plus status/cluster/disposition rows).
5. **body-schema** — the per-kind body/field materialization.
6. **gates** — the methodology-canonical gates (Scrum's design-before-sprint; Kanban's WIP/pull-limit — the ADR-039 declarative gate-condition surface).

Today these facets are **spread across separate documents** — `label-taxonomy.md` (labels), `ticket-information-architecture.md` (body-schema), `field-lifecycle-matrix.md` (fields) — and are **partly instance-coded to this repo's own board** (e.g., `label-taxonomy.md` fuses the universal label *grammar* with this board's concrete label *rows*). There is:

- **no single plug-and-play unit** a deployment selects per `delivery_approach`;
- **no clean K1 → Layer-3 → K4 seam** for the non-kind facets (kinds have it via ADR-018; work-status/fields/labels/gates do not);
- **duplication risk**: the ~80% of a methodology's surface that is archetype-invariant (the generic work-status base, the universal label groups, the priority scale) is at risk of being re-authored per archetype (a `duplicate-source-discipline` violation).

The operator intent is concrete: run **Hybrid-Two `[Scrum, Kanban]`** and add further archetypes (SAFe, Waterfall, XP, …) as **thin deltas** without a repo restructure. Statuses are generally the same for delivery work, so the shared surface should be authored once and the packs carry only their deltas.

## Decision

**Adopt Option 1 — a *methodology pack* is the composing unit.** A methodology pack is a per-archetype manifest under **`core/packs/<archetype>/`** that bundles a methodology's full operational surface (kinds + work-status + sortable fields + labels + body-schema + gates) into one selectable unit, shipped as **best-practice defaults (K1 / Layer-3)**, selected per deployment via `operator.toml` (`delivery_approach`), and **overridable per project (K4)**. Four sub-decisions:

### D1 — The composing unit + its placement

A methodology pack is a directory `core/packs/<archetype>/` carrying a manifest. The manifest is the single home for that archetype's six-facet surface. The shipped set for this milestone is `core/packs/{_common, scrum, kanban}/`. The pack is where the platform's three convergent properties meet on one surface:

- **best-practice baseline** — the pack ships as the platform's shipped-default methodology kit (K1), sourced from best-practice references (Scrum Guide, INVEST, the Kanban Method), NOT reverse-engineered from this repo's board (the ADR-018 §7.3 anti-pattern);
- **plug-and-play** — a deployment SELECTS a pack (or a set, for a hybrid) by naming its methodology; no hand-editing of skills per methodology (the methodology-as-config discipline);
- **BYO / override** — a project MAY bring or override pack content at K4 (operator-local), exactly as ADR-018 supports the user bringing/overriding work-item schemas.

### D2 — Shared grammar + `_common` carries the archetype-invariant ~80%; packs carry only deltas

A **shared root pack `_common`** carries the methodology-agnostic ~80% every archetype inherits: the generic Axis-1 work-status base (owned by the entity layer per ADR-018 D1 — packs *project labels over* it, they do not re-found it), the universal priority scale, and the universal label *groups*. An archetype pack (`scrum`, `kanban`) declares `extends = "_common"` and carries **only its deltas** (its kinds, its sortable fields, its lifecycle projection, its class-of-service / WIP set). This mirrors, one altitude up, the FROZEN-precedent delta-inheritance contract already in the corpus — `base_kind` (work-item-type-schema.md §2.1: "non-null ⇒ inherit fields + criteria + lifecycle_behavior from the named base; declare deltas only") and `base_archetype` (project-schema.md §6.3, Scrumban `base_archetype: Kanban`). One delta-inheritance mental model across the platform.

### D3 — Selection is `delivery_approach`; the public corpus stays methodology-neutral

Which pack(s) a deployment runs is chosen by `delivery_approach` in `operator.toml` (the operator-ENVIRONMENT/IDENTITY surface per ADR-022). A Hybrid-Two `[Scrum, Kanban]` deployment runs `_common ∪ scrum ∪ kanban`. The shipped packs are best-practice *defaults*; the concrete selection is operator-local K4. This keeps the **public corpus methodology-neutral** — no single methodology is privileged in the K1 corpus, and the label/kind/gate *grammar* stays archetype-invariant while the concrete rows live in the selected packs. The instance-coding of `label-taxonomy.md` (grammar fused with this board's rows) is resolved by moving the rows into the packs (the #1970 label-cleave slice consumes this decision).

### D4 — Physical form is TOML; the meta-schema widen is the sibling decision

The pack manifest is `pack.toml` — TOML is the platform's already-canonicalized operator-selectable config-manifest format (`operator.toml`, `platform-config.toml`; ADR-022), so packs (operator-selectable config *instances*) belong on the config surface, not the `.md` grammar/spec surface. The *grammar* those manifests conform to — the widened type-pack meta-schema carrying the pack-level `[[labels]]` facet, work-status projection, optional `kinds`, and the `role`/composition altitude — is decided in [ADR-069](ADR-069-methodology-pack-composition-grammar.md) and lives in `work-item-type-schema.md`. This ADR fixes the composing-unit + placement + selection; ADR-069 fixes the grammar; the #1968 slice widens the meta-schema and scaffolds the manifests; the #1970 slice restructures `label-taxonomy.md` into grammar-only + populates the packs' label facets.

## Consequences

### Positive

- **One plug-and-play selection seam** for a methodology's full surface — a deployment names its methodology and gets kinds + work-status + fields + labels + body-schema + gates, without hand-editing skills.
- **Adding an archetype is a thin delta** — a new pack declares `extends = "_common"` and carries only its deltas; the archetype-invariant ~80% is inherited, never re-authored (the thin-pack dividend, the methodology-scope analog of ADR-018's thin-entity dividend).
- **The public corpus stays methodology-neutral** — the grammar is archetype-invariant; concrete rows live in selected packs; no methodology is privileged in K1.
- **Resolves the instance-coding of `label-taxonomy.md`** — the fused grammar+rows split cleanly into grammar (stays) + rows (move to packs), closing a `duplicate-source-discipline` / parameterization-seam breach (the K1↔K4 seam per knowledge-architecture.md §3).
- **Reuses existing grammar + entity model** — no major repo restructure; ADR-018's type-pack grammar and delta-inheritance precedent are extended, not replaced.

### Negative / cost

- **A one-time type-pack meta-schema widen** — the grammar gains a pack-composition layer (the `[[labels]]` facet, work-status projection, optional `kinds`, the `role` altitude). Additive and backward-compatible, but it is a change to an accepted grammar (ADR-069 records it; the #1968 slice implements it).
- **A one-time `label-taxonomy.md` restructure** — the fused grammar+instance doc splits into grammar-only + per-pack label facets (the #1970 slice). Governance-doc edit, `git revert`-able.
- **A new architectural surface `core/packs/`** — the first `core/`-tree TOML instances outside `core/config/`; a new directory class that downstream consumers (tracker-manager, delivery-engine, ppm-agent, weekly-status-rollup) will read once the consumer read-refit lands (that wiring is the separate #2021 issue, NOT this milestone — the scaffold is inert until consumed).
- **A deploy-time pack-sync obligation** (Band 2) once packs are consumed — enumerated when the consumer read-refit lands.

### Cross-D upstream-compat

The pack surface inherits ADR-018's OPEN-value-domain discipline: no downstream consumer may treat the set of archetypes, or a pack's declared `kinds`, as a closed enum. A pack is a selectable, extensible unit; treating the shipped `{_common, scrum, kanban}` set as exhaustive would re-trap the open methodology set in the frozen-roster anti-pattern this track exists to eliminate.

## Reversibility

**MODERATE / Confidence HIGH pre-consumption** — before any consumer skill reads `core/packs/`, the composing-unit decision is a free choice: the packs are net-new files under a new directory, the meta-schema widen is additive (absent facets are byte-identical to prior behavior), and the `label-taxonomy.md` restructure is a `git revert`-able governance edit. Crosses to **EXPENSIVE** once the consumer read-refit (#2021) wires tracker-manager / delivery-engine / ppm-agent / weekly-status-rollup to resolve against the pack surface — at that point the pack manifest is a contract and undo means unwinding every consumer. Deciding the composing unit + placement + selection at this founding moment is the cheap moment; retrofitting a pack abstraction after the non-kind surfaces have accreted more instance-coding would be expensive. The founding-ADR + the operator scope-lock + the Collective Review are the sign-off gate.

## Related ADRs

- [ADR-018 — Work-Item Type Layer (WITL)](ADR-018-work-item-type-layer.md) — the parent kernel this ADR is subordinate to (thin generic Work Item entity + declarative type layer; methodology-projected; release-pipeline-neutral; K1 best-practice-defaults + K4 plug-and-play/override). This ADR completes ADR-018's governance spectrum for a methodology's full operational surface.
- [ADR-069 — Methodology-pack composition grammar](ADR-069-methodology-pack-composition-grammar.md) — the sibling decision that widens the type-pack meta-schema to carry the pack-composition model (the `[[labels]]` facet, work-status projection, optional `kinds`, and the `role`/composition altitude). This ADR fixes the composing unit; ADR-069 fixes the grammar it conforms to.
- [ADR-022 — platform-config.toml vs operator.toml split](ADR-022-platform-config-vs-operator-toml-split.md) — establishes TOML as the operator-selectable config-manifest surface and `operator.toml` as the environment/identity/methodology-selection home; D3/D4 consume it (packs are config instances on the TOML surface; `delivery_approach` in `operator.toml` selects them).
- [ADR-033 — Methodology-conditional skill activation](ADR-033-methodology-conditional-skill-activation.md) — the precedent that a methodology-conditional surface gates on `delivery_approach` (active-on-match, dormant-with-notice off-match, never a silent default); pack selection (D3) is the data-surface analog of that activation model.
- [ADR-039 — Declarative gate-condition construct](ADR-039-declarative-gate-conditions.md) — the gate facet of a pack (Kanban WIP / pull-limit; parent-design-gates-child) is expressed via ADR-039's declarative gate-condition grammar; a pack contributes gate `criteria`, it invents no new gating primitive.

### Provenance

This decision was sliced from the methodology-pack-foundation epic (#1962) as its founding ADR (issue #1967), the Wave-0 first slice of the methodology-packs track. It adopts Option 1 of the three options weighed in #1967 (widen the type-pack into a methodology pack; vs. keep surfaces separate and bind per-methodology in each consumer; vs. monolithic per-methodology config files). The Stage-5 Solutioning designs that ground the physical form and the label-surface cleave are #3025 (pack scaffold — `pack.toml` / `extends` inheritance) and #3021 (label-taxonomy grammar-vs-instance cleave). The Collective Review scope-lock (recorded in the milestone Amendment Log) absorbed the type-pack meta-schema widen (originally the closed #1090 grammar-widen scope) into the pack layer per operator directive — the pack layer is where best-practice-baseline + plug-and-play + user-override converge, so the grammar is designed to accommodate that convergence. The consumer read-refit that wires skills to the pack surface is the separate downstream issue #2021; this ADR scaffolds the contract, it does not wire the reads.
