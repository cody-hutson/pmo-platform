---
title: Work-Organization Mapping Framework
purpose: The domain-neutral standardization of work organization — universal hierarchy concept (Layer 1), a best-practice hierarchy-by-methodology map keyed by archetype name (Layer 2), shipped best-practice default work-item schemas (Layer 3), and the user plug-and-play override + "agent understands by nature" model (Layer 4). Projects any methodology's named work levels onto the single canonical Work Item entity via work_item_type, never via new entity-graph nodes.
type: reference
kind: disciplines
status: Canonical
reversibility: CHEAP / Confidence HIGH
version: v1.07
composes_with:
  - project-entity-model.md
  - knowledge-architecture.md
  - ../standards/universal-vs-release-pipeline-split-rule.md
  - ../specs/framework-catalog.md
  - ../specs/terminology-glossary.md
consumers: "intake-desk, delivery-engine, ppm-agent (read the map to place + relate work items) + the declarative work-item type layer (projects its per-kind schemas through Layer 2) + any pmo-platform deployment placing work items"
glossary_anchor: "terminology-glossary.md#term-work-item (Work Item canonical; Story/Epic/Feature/Work-Package are non-canonical projections per Appendix B)"
---
<!-- reference-durability: allow-link -->

# Work-Organization Mapping Framework

This document is the platform's **standardization of work organization**: a domain-neutral, methodology-agnostic model of how work decomposes, what each hierarchy level is *for*, how typical methodologies populate that hierarchy, what default work-item schemas ship out of the box, and how a user brings or overrides their own work-item types so that an agent understands any deployment's work *by nature*. It is shipped **full-spectrum and plug-and-play down to the work-item level**.

It is the doc [`ADR-018`](../ADRs/ADR-018-work-item-type-layer.md) forward-references as "the work-organization mapping framework shipped in `core/`": the methodology→kind projection (a tracked unit displayed as Story / Task / Work-Package) is a property of **this** domain-neutral map, not of any release-pipeline support tool. ADR-018 establishes the thin generic `Work Item` entity; this framework is the map that entity's kinds project through.

The framework composes with — and does **not** restate — four substrates that remain their own single sources of truth:

- [`project-entity-model.md`](project-entity-model.md) — the FROZEN canonical entity roster (the hierarchy nodes, the relationship chains, the `Work Item` entity §18). Layer 1 *cites* it by pointer; it is never re-defined here.
- [`knowledge-architecture.md`](knowledge-architecture.md) — the K1–K5 tiers + the parameterization seam. Layers 1–3 are K1 (shipped); Layer 4 is K4 (operator-local).
- The 8 delivery-approach **archetypes**, defined by name in the methodology corpus and catalogued in [`framework-catalog.md`](../specs/framework-catalog.md). Layer 2 references them **by name only** (Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe, Hybrid, Custom) — a name reference to an external body of practice, exactly the posture the catalog uses for PMBOK/SAFe/Scrum, and exactly the posture ADR-018 and the entity model already use. **No dependency on any release-pipeline file results.**
- [`terminology-glossary.md`](../specs/terminology-glossary.md) — `Work Item` is canonical; Story / Epic / Feature / User-Story / Work-Package are **non-canonical projections / display labels** (Appendix B). This map treats every methodology kind name as a projection, never a canonical kind.

> **Placement note (why `core/`, reference-by-name).** This map is universal-platform-knowledge consumed by skills/agents regardless of release-pipeline operation, so [`universal-vs-release-pipeline-split-rule.md`](../standards/universal-vs-release-pipeline-split-rule.md) §2 routes it to `core/disciplines/`. The archetype catalog stays in its release-class consumer's tree (the split-rule §5 audit already ratified that placement). Referencing a methodology *by name* is not a path/code dependency on the file that happens to also describe it; the kernel discipline (no `core/`→`release/` dependency) holds.

---

## Layer 1 — Concept of Work Organization (K1) {#layer-1-concept}

The universal principles — how work decomposes, how it relates, and the *purpose* of each hierarchy level — **already exist** in [`project-entity-model.md`](project-entity-model.md) §4 (per-entity rationale) and §5 (the relationship matrix + the Work Item→Milestone rollup chain 17). This layer **elevates and cites** that substrate; it does not restate it (duplicate-source-discipline — the entity model is the FROZEN authoritative home).

### 1.1 The universal decomposition principle {#decomposition-principle}

The principle this framework adds on top of the entity model, stated once:

> **A methodology populates the general hierarchy by naming its levels and defining how its work breaks down onto them; the hierarchy itself is methodology-invariant.** Scrum and Waterfall do not have *different hierarchies* — they have different *names* and *break-down rules* for the *same* levels. The finest level — the unit of independently-trackable execution — is the canonical `Work Item` entity ([`project-entity-model.md` §18](project-entity-model.md)); everything a methodology calls "below Milestone" lands on that single entity, distinguished by `work_item_type`, **never** by adding entity-graph nodes.

### 1.2 The per-level purpose abstraction (the net-new universal artifact) {#per-level-purpose}

The one net-new universal artifact Layer 1 contributes is a **methodology-invariant statement of what each hierarchy level is *for*** — the invariant against which Layer 2 maps each methodology's named levels. It composes with the entity model's per-entity rationale: the entity model says what each entity *is*; this table says what each *level* is *for*, methodology-agnostically, so a Scrum "Story" and a Waterfall "WBS leaf" are recognizable as the *same level*.

| General level | Entity (`project-entity-model.md`) | Purpose — what this level is *for* (methodology-invariant) | Cardinality intuition |
|---|---|---|---|
| **Portfolio** | Portfolio (§13) | The top-level grouping of programs/projects — the root of strategic roll-up | 1 per deployment (typ.) |
| **Program** | Program (§14) | A grouping of related projects under one owner — mid-tier coordination | many per Portfolio |
| **Project** | Project (§1) | The top-level unit of delivery whose lifecycle gates all processing — the scope container | many per Program |
| **Milestone / Workstream** | Milestone (§2) / Workstream (§3) | **Milestone** = a *dated convergence checkpoint* (a gate where work converges to a date); **Workstream** = a *parallel stream* grouping work under a lead | many per Project |
| **Work Item** | Work Item (§18) | The *finest independently-trackable unit of execution* — the leaf that carries a `work_item_type`, attaches to a `parent_ref`, and is the `BELONGS_TO` source of the rollup edge | many per Milestone/Workstream |

The table bottoms out at **Work Item** because that is where the entity model bottoms out (§18 is the finest node). Methodology level-names *below* Milestone (Story, Task, WBS-leaf) are all this one level — see Layer 2.

### 1.3 The two universal relations the map relies on {#universal-relations}

The map needs exactly two relations from the built relationship vocabulary. Both are **referenced from** [`frontmatter-schema.md` §Category 4](../schemas/frontmatter-schema.md) (the 7 MVP relationship types, frozen/built) — **never redefined**:

- **Containment** — `BELONGS_TO` (the rollup edge). A Work Item `BELONGS_TO` its Milestone/Workstream parent (entity-model chain 17). This is how a brought work item is *placed*.
- **Sequence / dependency** — `DEPENDS_ON` / `BLOCKS`. Ordering and blocking between work items. This is how work items are *related* in time.

No new relationship vocabulary is introduced. An agent reasoning over this map **relates** work only via the built 7 MVP types; inventing edges is forbidden (see Layer 4 §4.2 step 4).

---

## Layer 2 — Hierarchy-by-Methodology map (K1) {#layer-2-map}

This is the heart of the framework: a best-practice map of how typical methodologies name their levels and break work down onto the general hierarchy. It is the **work-breakdown dimension** that the methodology corpus does not yet carry — the methodology archetype grid carries lifecycle / ceremonies / artifacts / cadence / sample-types per archetype, but **no work-breakdown/hierarchy dimension**. This layer adds exactly that, and only that.

### 2.1 Composition rule — compose by shared key, do not restate, do not relocate {#composition-rule}

Layer 2 adds the work-breakdown dimension as a table **keyed by the same 8 archetype names** the methodology corpus uses (byte-identical, case-sensitive: `Scrum` `Kanban` `XP` `Waterfall` `PRINCE2` `SAFe` `Hybrid` `Custom`). It does **not** re-list the archetypes' lifecycle/ceremonies/artifacts columns. The two are joined by the shared archetype-name key: a consumer reads the methodology corpus for cadence/ceremonies and reads **this** framework for the level-mapping/work-breakdown. This is the same compose-by-shared-key pattern the methodology prose-definitions and the archetype data-grid already use (prose defs + data grid, joined by archetype name).

The work-breakdown dimension, per archetype, has three facets: **(i) level names** (what the methodology calls each hierarchy level), **(ii) mapping onto the general hierarchy** (which general level each named level occupies), and **(iii) decomposition rule** (what is a parent-of-what).

### 2.2 Scrum — end-to-end {#scrum-map}

*Archetype: `Scrum` (Scrum Guide 2020 — catalogued in [`framework-catalog.md`](../specs/framework-catalog.md), referenced by name).*

| General level | Scrum level name | Decomposition rule |
|---|---|---|
| Portfolio | *(none — Scrum is team-scoped)* | — |
| Program | *(none at team scale)* | — |
| Project | Product | the product backlog's owning container |
| Milestone / Workstream | **Sprint** (time-boxed) / Product Backlog (flow) | Sprint = a dated convergence box (Milestone-level); the backlog is the flow container |
| Work Item | **Story / Bug / Task / Spike** | a Story decomposes into Tasks; the Story is the unit of sprint commitment |

**Work-breakdown:** `Epic` (grouping label) ⊐ `Story` (commit unit, **Work Item level**) ⊐ `Task` (execution sub-unit, **Work Item level**).

- `Story` and `Task` are **both Work-Item-level kinds**. Per the entity model, the `Work Item` entity is the single hierarchy node beneath Milestone; Story-vs-Task is a *kind* distinction *within* that level (handled by Layer 3 / the declarative type layer), **not** a new hierarchy level. This is the load-bearing modeling call: **methodology "levels" below Milestone collapse onto the single Work Item entity-level and are distinguished by `work_item_type`, not by adding entity-graph nodes.** It matches ADR-018's rejected alternative (B) ("don't add an entity per kind").
- `Epic` is a **backlog-grouping label, NOT a hierarchy level** — Appendix B of the glossary bans `Epic` as a canonical term (it maps to "Milestone + Issue"). An Epic groups large Stories; it does not occupy its own level.

### 2.3 Waterfall — end-to-end {#waterfall-map}

*Archetype: `Waterfall` (PMBOK predictive lifecycle — catalogued in [`framework-catalog.md`](../specs/framework-catalog.md), referenced by name).*

| General level | Waterfall level name | Decomposition rule |
|---|---|---|
| Portfolio | Portfolio | program/project grouping |
| Program | Program | related-project grouping |
| Project | Project | the SOW-scoped container |
| Milestone / Workstream | **Phase** (gate-bounded) / Deliverable | a Phase (requirements→design→build→test→deploy) is a gate-bounded stage = a dated convergence checkpoint = Milestone-level |
| Work Item | **WBS task / Deliverable-leaf** | a Phase decomposes into WBS tasks; the WBS leaf is the Work-Item-level unit assigned to a performer |

**Work-breakdown:** `Phase` (**Milestone level**) ⊐ `WBS summary task` (decomposition grouping) ⊐ `WBS leaf task` (**Work Item level**).

- The `WBS leaf` is PMBOK's "Work Package" — which the glossary Appendix B maps to "Work Item (issue level) + Task (stage-scoped)." It is the **Work Item level**.
- `Phase` maps to **Milestone level** (a gate-bounded dated checkpoint), confirming the entity model's Milestone rationale reads as universal.
- `WBS summary task` is a **decomposition grouping, NOT a hierarchy level** — the Waterfall analogue of Scrum's `Epic`.

### 2.4 The cross-archetype invariant {#cross-archetype-invariant}

The two worked maps surface the invariant that makes Layer 4's "by nature" placement possible:

> **Every methodology's finest execution unit lands on the single `Work Item` entity level.** What differs across methodologies is only: **(a)** the *name* (Story / WBS-leaf / Work-Package); **(b)** the *kind set* (Story+Bug+Task vs. WBS-task+Deliverable); and **(c)** the *intermediate grouping labels* (Epic, WBS-summary), which are **not** hierarchy levels but backlog/decomposition groupings.

Because the level structure is invariant and only names/kinds/groupings vary, an agent that knows the general hierarchy (Layer 1) and the per-archetype name mapping (Layer 2) can place *any* declared kind onto the right level — see Layer 4.

### 2.5 Additional archetypes — name + mapping granularity {#additional-archetypes}

The remaining catalogued archetypes are mapped at **level-name + general-level granularity**; their full decomposition rules are tagged `[deferred — extend when a consumer needs it]`, honoring promote-on-demand (a stub now, full rules when a downstream consumer requires them).

| Archetype | Project-level name | Milestone-level name | Work-Item-level name(s) | Decomposition rule |
|---|---|---|---|---|
| **SAFe** | Solution | Program Increment (PI) / ART iteration | Capability → Feature → Story / Enabler | `[deferred]` — Epic ⊐ Capability ⊐ Feature ⊐ Story; Feature/Story are Work-Item-level, the rest are grouping/coordination tiers |
| **PRINCE2** | Project | Stage (management stage) | Work Package | `[deferred]` — Stage (Milestone-level) ⊐ Work Package (Work-Item-level); PRINCE2 is a governance wrapper that tailors over an execution engine |
| **Kanban** | *(service/board)* | *(flow — no time-box)* | Card / work item | `[deferred]` — continuous-flow: no fixed Milestone-level time-box; cards are Work-Item-level pulled through WIP-limited columns |
| **XP** | *(product)* | Iteration | User story / Task | `[deferred]` — Iteration (Milestone-level) ⊐ Story ⊐ Task (both Work-Item-level); engineering-practice-heavy |
| **Hybrid** | Project | per-track (one per constituent archetype) | per-track kind set | `[deferred]` — a user-configurable two-archetype combination `delivery_approach: [A, B]`: each track maps per its constituent archetype (e.g. Scrum-track + Waterfall-track), union of both |
| **Custom** | per `custom_methodology_definition` | per block | per block | `[deferred]` — resolves via the block's `base_archetype` (use that archetype's row) or, when `base_archetype: null`, places brought kinds at Work-Item level by default (Layer 4 §4.2 step 5) |

> **Note on SAFe/PRINCE2 names.** `Capability`, `Feature`, `Work Package` are projection/display labels (glossary Appendix B), not canonical kinds — listed here to map the methodology, not to bless the term. The canonical kind remains `Work Item` distinguished by `work_item_type`.

---

## Layer 3 — Work-Item Best-Practice default schemas (K1) {#layer-3-schemas}

The package ships **default work-item schemas per the map** — the best-practice defaults a deployment gets out of the box. Load-bearing constraint: these are authored from **methodology best practice** (the Scrum Guide's definition of a Story; PMBOK's definition of a WBS work package; IEEE-1044 defect classification), **NOT** reverse-engineered from the platform's own issue templates or from any release-pipeline ticket model. The platform's own dev-tooling tickets are an *instance under the model*, not its definition (ADR-018's "operations entity vs. dev-tooling ticket" discipline).

### 3.1 Default-schema shape {#schema-shape}

Each default schema is expressed in a methodology-neutral **field-list form** (the same shape [`entity-field-schemas.md`](../schemas/entity-field-schemas.md) uses, so the declarative type layer's meta-schema can consume these as worked examples). Each default schema =

> the canonical `Work Item` base (Entity Core 7 + `work_item_type` + `parent_ref`, per [`project-entity-model.md` §18](project-entity-model.md)) **+** a kind-specific best-practice field set **+** readiness/done criteria drawn from the methodology.

Notation: `✅` required · `⚪` optional · type · `(note)`. The Entity Core 7 + `work_item_type` + `parent_ref` are inherited from §18 and not re-listed per schema.

### 3.2 Story — best-practice default {#schema-story}

*Source of best practice: Scrum Guide 2020 + INVEST (Cohn, "User Stories Applied") — referenced by name. Covers the Scrum/XP/SAFe Work-Item kind set.*

| Field | Req | Type | Note |
|---|---|---|---|
| `as_a` | ✅ | str | role — the "who" of the story |
| `i_want` | ✅ | str | goal — the capability sought |
| `so_that` | ✅ | str | benefit — the value rationale |
| `acceptance_criteria` | ✅ | list&lt;str&gt; | the conditions of satisfaction (the done test) |
| `story_points` | ⚪ | int | relative-size estimate (optional) |
| `sprint_ref` | ⚪ | ref | the Sprint (Milestone-level) this is committed to |

- **Readiness (maps to delivery-engine DoR):** INVEST-conformant **and** `acceptance_criteria` present.
- **Done:** every `acceptance_criteria` entry met.
- **Deliberate divergence:** this is the *methodology* best-practice Story (role-goal-benefit + INVEST), **not** the platform's own intake field set. The methodology defines the default; the platform's dev tooling is a separate instance.

### 3.3 Bug — best-practice default {#schema-bug}

*Source of best practice: general defect-management best practice (IEEE 1044 defect classification) — referenced by name. The base Bug default; per-domain field variability (a JSON-failure bug's `payload` vs. a UI bug's `repro_steps`) is the declarative type layer's per-domain overlay, not shipped here.*

| Field | Req | Type | Note |
|---|---|---|---|
| `reproduction_steps` | ✅ | list&lt;str&gt; | ordered steps to reproduce |
| `expected_vs_actual` | ✅ | str | expected behavior vs. observed behavior |
| `environment` | ✅ | str | where it reproduces (build/OS/config) |
| `severity` | ⚪ | enum | defect severity classification |
| `affected_component` | ⚪ | ref | the component/system exhibiting the defect |

- **Readiness:** reproducible **and** `environment` captured.
- **Done:** fix verified against the `reproduction_steps`.

### 3.4 WBS task — best-practice default (sketch) {#schema-wbs-task}

*Source of best practice: PMBOK Work Package — referenced by name. The Waterfall Work-Item default, shipped as a 3-field sketch (the AC requires a sample kind to have a shipped default; the exhaustive per-kind library is the declarative type layer's scope, not this framework's).*

| Field | Req | Type | Note |
|---|---|---|---|
| `wbs_code` | ✅ | str | the WBS outline code locating this leaf |
| `deliverable_ref` | ✅ | ref | the Phase deliverable this task produces toward |
| `completion_criteria` | ✅ | str | the verifiable condition that marks the package complete |

- **Readiness:** `wbs_code` assigned **and** `deliverable_ref` resolved.
- **Done:** `completion_criteria` verified.

### 3.5 Why illustrative, not exhaustive {#illustrative-not-exhaustive}

Layer 3 ships **2 kinds fully (Story, Bug) + 1 sketch (WBS task)** across the two worked archetypes — exemplars, not a library. The *complete* per-kind schema authoring is the declarative work-item type layer's job (the type-pack meta-schema + materialization). Layer 3's contract is to ship *enough* best-practice defaults that (a) a sample kind has a shipped default schema, (b) the type layer has a concrete projection target to consume, and (c) a deployment has working defaults day-one. Authoring every kind × every archetype here would duplicate the type layer and over-scope this framework.

---

## Layer 4 — User Plug-and-Play (K4) {#layer-4-plug-and-play}

The package ships Layers 1–3 (K1, universal); **Layer 4 is the user's local config** (K4, operator-local — never in the platform corpus, per [`knowledge-architecture.md` §K4](knowledge-architecture.md)). This layer specifies two mechanisms: how a brought schema overrides a default, and how an agent places & relates a user's work items *by nature* — without any per-user governance file.

### 4.1 Override model — precedence {#override-precedence}

Precedence is a clean K1→K4 override, mirroring the proven `delivery_approach` + `custom_methodology_definition` pattern (the methodology corpus' CASE 1/2/3 skill-consumption pattern) and the entity→schema materialization. For a given `work_item_type`, resolution order is:

1. **User type-pack wins (full override).** If the user declares a type-pack for that kind in their K4 config → the brought block **is** the definition for that kind (the `base_archetype: null` / CASE-3 analog).
2. **Else the best-practice default applies.** If a Layer-3 default exists for that kind → it applies (the CASE-1 analog).
3. **Else the thin generic base applies.** The `Work Item` base (Entity Core 7 + `work_item_type` + `parent_ref`) applies with **no** kind-specific overlay; the agent emits a methodology-agnostic placement **with a caveat** — it never silently invents fields (the CASE-3 null-base analog).

This is a **field-level merge, default-as-base** (the CASE-2 "start from base, override the deltas" pattern): a user who overrides only `acceptance_criteria` for Story inherits the rest of the Layer-3 Story default.

> **Worked example — override.** A user brings a `Story` type-pack that adds a `risk_tier` field and replaces `story_points` with `t_shirt_size`. The agent resolves: `Story = (Layer-3 Story default ∖ {story_points}) ∪ {risk_tier, t_shirt_size}`, keeping `as_a / i_want / so_that` + `acceptance_criteria` from the default. The user wrote only the deltas; the default supplied the rest.

### 4.2 The "agent understands by nature" procedure {#by-nature-procedure}

Given Layers 1–3 + a user's brought types, an agent **places and relates** the user's work items *without per-user governance*. The mechanism is this deterministic procedure:

1. **Read `delivery_approach`** (from the project's `PROJECT.md`) → select the Layer-2 work-breakdown row for that archetype (CASE 1), or the `custom_methodology_definition.base_archetype`'s row (CASE 2), or `null` (CASE 3).
2. **Resolve each brought `work_item_type` to a hierarchy level** via Layer 2's mapping facet: look up the user's kind name (or its `base_archetype`-projected equivalent) → general level. A brought kind the map does not name resolves to the **Work Item level** by default (the finest level), unless its declared `parent_ref` target dictates otherwise.
3. **Place** = attach the work item to its `parent_ref` (Milestone or Workstream) per the §18 polymorphic `BELONGS_TO` edge — entity-model rollup chain 17 gives "place" its concrete realization.
4. **Relate** = draw edges **only** from the built 7 MVP types ([`frontmatter-schema.md` §Category 4](../schemas/frontmatter-schema.md)); the agent never invents relationship vocabulary. Containment = `BELONGS_TO`; ordering = `DEPENDS_ON` / `BLOCKS`.
5. **Caveat-on-gap (the anti-PROC-3 discipline).** When a brought kind cannot be mapped *and* has no `parent_ref` hint, the agent places it at **Work Item level under the active Milestone** and **flags the placement as inferred** — it does **not** silently default to a wrong level or fabricate a parent.

> **Worked example — place & relate.** A `Custom` project declares `delivery_approach: Custom`, `base_archetype: Scrum`, and brings a kind `Spike` with `parent_ref → <sprint-milestone>`. Step 1 selects the Scrum row (CASE 2). Step 2: `Spike` is not in the Scrum kind set's mapping, so it resolves to **Work Item level** (the default for an unmapped kind). Step 3: it is placed `BELONGS_TO` its declared `parent_ref` Sprint-milestone. Step 4: a `DEPENDS_ON` edge the user declared to a blocking Story is drawn using the built MVP type — no new vocabulary. No governance file was authored; the composition (universal map ∘ user types) was total.

### 4.3 Why "by nature" emerges {#why-by-nature}

The "by nature" property emerges because the agent reasons over the **universal** Layers 1–2 (methodology-complete for the catalogued archetypes) plus the **user's declared types** (which carry their own `parent_ref` + `work_item_type`). No per-user governance file is needed — the composition `(universal map ∘ user types)` is total: every brought kind either maps via Layer 2 or falls to the Work Item level by the default rule, and every placement either resolves a `parent_ref` or is flagged inferred. This is exactly the **K1↔K4 parameterization seam** from [`knowledge-architecture.md` §3](knowledge-architecture.md#parameterization-seam): the map is the universal parameter-consumer; the user's brought types are the K4 values.

---

## Composition with the declarative work-item type layer {#composition-type-layer}

This framework is **upstream** of the declarative work-item type layer (the type-pack meta-schema). The seam the type layer consumes from this framework has three named contract surfaces:

1. **The hierarchy-level taxonomy (Layer 1 §1.2 per-level-purpose table).** The type layer's `work_item_type` declarations resolve to a hierarchy level via this taxonomy; it does not re-derive what a "level" is.
2. **The methodology→work-breakdown map (Layer 2).** The type layer's per-archetype kind projections are the *kind-level* detail; Layer 2 is the *hierarchy-placement* detail they project through. The type layer reads the Layer-2 mapping facet to know which level a declared kind occupies. **This is the projection target the type layer consumes — projecting onto this map, not onto any release-pipeline ticket model.**
3. **The best-practice default schemas (Layer 3).** The type layer's meta-schema is the *grammar*; Layer 3's defaults are the *first instances* in that grammar. The type layer consumes Layer 3 as both (a) its validation corpus (the defaults must parse against the meta-schema) and (b) the base layer its user-override mechanism (Layer 4) overrides.

Contract direction: **Layer 3 ⊂ the set of documents the type layer's meta-schema must accept.** Sequence: this framework (the map + level taxonomy + best-practice defaults) lands before the type-pack grammar projects onto it.

---

## Cross-References {#cross-references}

This framework **consumes** these sources by pointer (duplicate-source-discipline — substrates are named and linked, never re-defined here). All links are intra-`core/`; the framework declares **no dependency on any release-pipeline file** — methodologies are referenced by name (catalogued external bodies of practice), not by path.

| Reference | Role relative to this framework |
|---|---|
| [`ADRs/ADR-018-work-item-type-layer.md`](../ADRs/ADR-018-work-item-type-layer.md) | Establishes the thin generic `Work Item` entity + the type layer; forward-references **this** framework by name as "shipped in `core/`". This doc satisfies those references. |
| [`project-entity-model.md`](project-entity-model.md) | The FROZEN hierarchy substrate — §4 per-level purpose, §5 + chain 17 the rollup edge, §18 the `Work Item` entity. Layer 1 cites it; never restated. |
| [`knowledge-architecture.md`](knowledge-architecture.md) | K1 (Layers 1–3 shipped) vs K4 (Layer 4 user-local) split + §3 parameterization seam Layer 4 instantiates. |
| [`../standards/universal-vs-release-pipeline-split-rule.md`](../standards/universal-vs-release-pipeline-split-rule.md) | §2 routes this map to `core/`; §5 ratifies the archetype catalog's `release/` placement (why reference-by-name, no relocation). |
| [`../specs/framework-catalog.md`](../specs/framework-catalog.md) | The registry of named frameworks (PMBOK / SAFe / Scrum / Kanban / XP / Waterfall / PRINCE2) — the proof that reference-by-name is the platform's standing posture, and the registry this framework's own INTERNAL row joins. |
| [`../specs/terminology-glossary.md`](../specs/terminology-glossary.md) | `Work Item` canonical (`#term-work-item`); Story / Epic / Feature / Work-Package are non-canonical projections (Appendix B). The map treats methodology names as projections/display labels. |
| [`../schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) | §Category 4 — the built 7 MVP relationship types Layer 1 §1.3 + Layer 4 step 4 consume (no new vocabulary). |
| [`../schemas/entity-field-schemas.md`](../schemas/entity-field-schemas.md) | The field-list shape Layer 3's default schemas adopt, so the type layer's meta-schema can consume them as worked examples. |
| The 8 `delivery_approach` archetypes (Scrum / Kanban / XP / Waterfall / PRINCE2 / SAFe / Hybrid / Custom) | Referenced **by name** as external bodies of practice (catalogued above). Layer 2's work-breakdown dimension joins them by the shared archetype-name key. **No path dependency.** |
