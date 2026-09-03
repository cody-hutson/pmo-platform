---
title: Work-Item Type-Pack Meta-Schema
purpose: The K1 meta-schema for work-item type-packs — the grammar that user-config type-pack instances conform to, derived from the FROZEN project-entity model.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: user-config work-item type-pack instances; intake-desk / delivery-engine / ppm-agent (the declarative work-item type layer); project-entity-model.md (the FROZEN derivation source)
---
<!-- reference-durability: allow-link -->
# Work-Item Type-Pack Meta-Schema

**Status:** Canonical
**Meta-schema version:** v1
**Owner:** `../schemas/work-item-type-schema.md`
**Layer:** 1 (Engineering, git-tracked)
**Type:** schema-spec doc (the K1 *grammar*; type-pack *instances* are K4 user config)
**Derivation source (FROZEN):** [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md) §18 (the thin generic `Work Item` entity) + [`entity-field-schemas.md`](entity-field-schemas.md) §3.18 (its field schema + V-rules) + §3.0 (the inherited Core 7 + the `FieldDecl` row shape).
**Projection target:** [`../disciplines/work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md) — Layer 2 (the hierarchy-by-methodology map a declared kind projects through) and Layer 3 (the best-practice default schemas this grammar *consumes/accepts*, never re-authors).
**Architectural basis:** [`../ADRs/ADR-018-work-item-type-layer.md`](../ADRs/ADR-018-work-item-type-layer.md) (D1 hybrid — thin generic entity + declarative type layer; D2 methodology-projected; D4 Tier-2 scope change). The pack-composition layer (§1.1 `role`/`extends`, §1.1.1 `[[labels]]` facet, work-status projection) is [`../ADRs/ADR-070-methodology-pack-composition-grammar.md`](../ADRs/ADR-070-methodology-pack-composition-grammar.md) — a grammar-altitude sibling extension of ADR-018 (the same lineage as ADR-039's gate-condition extension), authored for the methodology-pack composing unit [`../ADRs/ADR-069-methodology-pack-composing-unit.md`](../ADRs/ADR-069-methodology-pack-composing-unit.md). The cross-cutting control layer (§1.1.2 + §1.2.1 Arm 3) is [`../ADRs/ADR-077-cross-cutting-control-field-layer.md`](../ADRs/ADR-077-cross-cutting-control-field-layer.md), filling the arm ADR-039 reserved.
**Pattern precedents (mirrored by pattern, referenced by name — no path dependency):** the `custom_methodology_definition` escape hatch (CASE 1/2/3 skill-consumption + N=2 governance-promotion) and the EAD mechanism that derives `raid-log.schema.json` from the RAID Item entity field schema.
**Consumers (downstream):** `tracker-manager` (the single schema-validation enforcement point), `intake-desk` (repoints its `references/type-map.md` registry portion here), `delivery-engine` / `ppm-agent` / `weekly-status-rollup` (read the registry for kind fields + the cross-kind rollup — the one-time read refit is a deferred propagation slice, not this doc).
**Cross-references:** see the Cross-References section (§8) below.

---

## 0. What this document is (and is NOT)

This is the **meta-schema** for a `work-item-type-pack`: the format a user — or a shipped best-practice-default pack — uses to declare a **work-item kind** as **data**. A kind is never code, never a skill-extensible enum, never a new entity-graph node. Every declared kind IS the single canonical `Work Item` entity (`project-entity-model.md` §18), distinguished only by its `work_item_type` discriminator.

| This document IS | This document is NOT |
|---|---|
| The **grammar** every type-pack conforms to (the meta-schema). | A library of kinds. The package ships best-practice DEFAULT schemas in the work-organization mapping framework's Layer 3; this doc defines the grammar those defaults are the *first instances* of. |
| K1 codified-knowledge (the shape is universal). | K4 user config. A project's *declared kinds* are operator-local plug-and-play (the framework's Layer 4) — they are never authored into this git-tracked corpus. |
| The contract that a declared kind **EAD-materializes** into a concrete per-kind machine-schema (the `raid-log.schema.json` mechanism). | A hand-authored per-kind JSON Schema. The machine-schema is *derived* from the declaration; the declaration is authoritative. |
| A projection **onto the general hierarchy** via the work-organization mapping framework's Layer-2 hierarchy-by-methodology map. | A projection onto any release-pipeline ticket model. `core/` governance must not couple to release-pipeline dev tooling (the ADR-018 kernel discipline). |

**Types are user config.** The grammar here lets a deployment do two things: (a) **consume the shipped best-practice defaults** (the framework's Layer-3 Story / Bug / WBS-task schemas parse against this grammar out of the box) and (b) **bring or override its own kinds** (plug-and-play, the framework's Layer-4 K4 override model). No "canonical seed pack" is governance — the defaults are best-practice exemplars per the map, not a baked-in roster.

---

## 1. The type-pack grammar

A **type-pack** is a document with two levels: a **pack header** and — for a **kind-bearing** pack — one or more **per-kind declarations**. Kind-bearing follows from the pack's `role`, never from whether it names an archetype: `role ∈ {archetype, kit}` bears kinds and `role = "base"` MUST NOT. That sentence resolves a contradiction this section previously carried against the §1.1 field table, which read `kinds` as optional-or-absent for a base pack and so left a second, undesigned way to express a cross-methodology kind set (ADR-177 D7). A `role = "base"` pack (the shared root, §1.1) therefore carries a header plus archetype-invariant contributions (label groups projected over the entity base) and **no per-kind declarations**; a `role = "kit"` pack carries a header plus per-kind declarations that name **no** archetype at all (§1.3).

### 1.1 Pack header

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `pack_id` | string (slug) | ✅ | Lowercase-kebab, unique within a deployment. |
| `pack_version` | string (semver) | ✅ | The pack's version. §6 governs the bump rule (additive kind = minor; meta-schema-shape change = a new meta-schema version + shim). |
| `applies_to` | string | ✅ | A `delivery_approach` archetype name (the byte-identical, case-sensitive set `Scrum` `Kanban` `XP` `Waterfall` `PRINCE2` `SAFe` `Hybrid` `Custom`) **OR** `*` for a methodology-neutral pack. This is the join key into the work-organization mapping framework's Layer-2 row. **The rule is stated for all three roles and it is total** (ADR-177 D1). The requiredness cell previously deferred to a role-conditional note that this section stated for `base` only, which left the archetype case unwritten and permissive: • a `role = "base"` pack MUST set `*` — it carries no kinds and performs no Layer-2 join, so `*` is its only meaningful value; • a `role = "kit"` pack MUST set `*` — a kit is archetype-neutral by definition; • a `role = "archetype"` pack MUST name an archetype and **MUST NOT** set `*` — a neutral archetype pack would be a second, incoherent way to express what a kit expresses, and its kinds would each still name an archetype, so the neutrality would be a claim the pack does not honour. Any other role/value combination is a pack-validation error. **The third clause is a RESTRICTION, not an add** — it is the one shape in this extension that can invalidate a previously-valid pack, and it is accounted for as such in §6.2c. |
| `role` | enum `{archetype, base, kit}` | ⚪ | **Pack-composition discriminator (ADR-070 D1, widened to three members by ADR-177 D1).** `archetype` (the DEFAULT when omitted) = a normal pack that projects kinds for one archetype. `base` = a non-kind-bearing shared pack that carries only archetype-invariant contributions (the label-group projections kind-bearing packs inherit). `kit` = a **kind-bearing, archetype-neutral** pack: it declares kinds a deployment selects *independently of the methodology it runs*, sets `applies_to = "*"`, is discriminated by `kit_class` (below), MAY declare `extends`, and MUST NOT itself be an `extends` target. Absence ⇒ `archetype` ⇒ byte-identical to a pre-widen pack (the backward-compat guarantee — every existing pack is implicitly `role = "archetype"`). The discriminator is what lets the grammar treat a base pack's absent `kinds` as legitimate, lets a kit bear kinds without naming an archetype, and lets a validator select the correct completeness rule per role. **The role set is OPEN** — it has just been widened from two members to three, which is itself the proof; a consumer branching exhaustively on role values will be wrong at the next widening (ADR-070 §Cross-D; ADR-177 §Cross-D). |
| `extends` | string (pack_id) | ⚪ | **Pack delta-inheritance (ADR-070 D1), permitted on `role ∈ {archetype, kit}`** (widened by ADR-177 D1). Names a `role = "base"` pack to inherit contributions from; a delta pack then declares only what differs from its base — the FROZEN `base_kind` / `base_archetype` delta-inheritance contract (§2.1, project-schema §6.3) lifted one altitude, pack vs kind. Absent ⇒ no inheritance (byte-identical to a pre-widen pack). Two prohibitions, each a pack-validation error: a `role = "base"` pack MUST NOT set `extends` (a base is a root — the `base_kind: null` no-fallback-root analog), and a `role = "kit"` pack MUST NOT be an `extends` **target** (only a base pack is an inheritance root, so a kit may inherit but may never be inherited from). |
| `kit_class` | string (slug) | **role-conditional** | **The kit's facet discriminator (ADR-177 D3), REQUIRED when `role = "kit"` and absent otherwise.** It names *which facet the kit must carry*, and it is what the `kinds` requiredness rule below branches on. Its v1 registered value is `work-item` — a work-item kit, whose facet is the `kinds` array. **The value domain is OPEN**: `field`, `workflow` and `form` kits are plausible successors, and each registers a class plus the requiredness rule for its own facet — no `role` change, no second unit, no re-opening of the `kinds` rule. An **unregistered** class is a **CAVEAT, never an error**: a validator reports the value it did not recognize and asserts no facet requirement for it. The cost of the open domain is stated rather than elided — a mistyped class falls through to the unregistered arm and silently relieves a work-item kit of its `kinds` obligation, which is exactly why the caveat MUST name the unrecognized value and MUST NOT be silent. **The `kit_class` set is OPEN**; a consumer that branches on the literal `work-item` re-creates the frozen-roster anti-pattern one altitude up (the ADR-018 kernel discipline). |
| `kinds` | array&lt;Kind&gt; | **role-conditional, then class-conditional** | **The requiredness rule is TWO-LEVEL** (ADR-070 D4, restated in full by ADR-177 D3 — a rule stated at one altitude only was this decision's first defect): • **`role = "base"` ⇒ FORBIDDEN.** A base pack carries archetype-invariant contributions only and declares no kinds of its own; a base pack that declares any is a pack-validation error (ADR-177 D7 — the prohibitive reading, resolving the §1/§1.1 contradiction that previously read this cell as optional-or-absent). • **`role = "archetype"` ⇒ REQUIRED (✅, ≥1)**, unchanged from the pre-widen unconditional requirement. • **`role = "kit"` ⇒ requiredness is SELECTED BY `kit_class`** — `kit_class = "work-item"` requires at least one kind (that class's facet *is* the kind set); an **unregistered** class asserts **no facet requirement at all**, and the unrecognized value surfaces as the `kit_class` caveat above rather than as an error here. **Conditioning the kit arm on `kit_class` rather than on `role` is what makes the class domain genuinely open**: a future `field` or `workflow` kit registers a class and its facet without re-opening this rule. Were the kit arm conditioned on `role` alone, every kit would owe work-item kinds, a second class would be hard-rejected on this row, and the open domain above would be unreachable — the same pack would fail here first. |

> **Requiredness-condition mechanism (honest framing).** Conditioning `kinds`'s requiredness on the `role` discriminator is *analogous in spirit* to — not a byte-identical reuse of — the grammar's existing conditional constructs (`custom_kind_definition` appears iff `archetype: Custom` (§2.1); `custom_methodology_definition` appears iff `delivery_approach: Custom` (project-schema §6.3)). Those gate whether an optional *block* is present (and every field inside it is then unconditionally required); `role` instead flexes the requiredness of the always-present `kinds` field in this fixed header table. The pattern (a discriminator selects the applicable requiredness rule) is shared; the mechanism differs. The pack-composition altitude this introduces is the decision recorded in ADR-070 (a grammar-altitude decision, not an inline scaffold note). **ADR-177 D3 adds a second level to the same mechanism** — for `role = "kit"` the applicable rule is selected a second time, by `kit_class`. Two discriminators in series, not two competing rules: `role` decides *whether a facet requirement applies at all*, and `kit_class` decides *which facet*. A rule set that collapsed the second level into the first would admit exactly one kit class forever, which is the failure the two-level form exists to prevent.

> **A `role = "base"` pack declares no work-status machine.** The generic Axis-1 base machine `backlog → ready → in-progress → in-review → done | cancelled` is owned by the **entity layer** (ADR-018 D1; §1.2 `axis1_state_machine`, `entity-field-schemas.md` §3.18 V-WI-04). A pack MUST NOT declare a pack-level work-status/state machine — it *projects over* the base (a pack MAY project methodology-specific sub-states/labels via a kind's `axis1_state_machine` refinement, per ADR-070 D3), never re-founds it. A `role = "base"` pack therefore carries neither a `kinds` array nor a state machine; each kind of a **kind-bearing** pack — `role ∈ {archetype, kit}` — inherits the base via `axis1_state_machine = "inherit"` (§1.2) and refines it inline only when it genuinely narrows/extends the states. A `role = "kit"` pack likewise carries no pack-level state machine.

### 1.1.1 The `[[labels]]` contribution facet (pack-level; ADR-070 D2)

A pack MAY carry a `[[labels]]` array (permitted on all three `role` values — `base`, `archetype` and `kit`). Each entry is one concrete label row a pack **contributes** into a universal label **group** the label grammar owns. The contract direction is fixed: **the label groups + rules are defined by [`../specs/label-taxonomy.md`](../specs/label-taxonomy.md) (the grammar); a pack only *populates* them** — a pack never defines a new group or rule (ADR-018 D1: type-packs "project methodology labels over the base; they do not re-found it"). A `group` value not defined by the label grammar is a pack-validation error.

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `group` | enum | ✅ | The label-grammar-owned group this row lands in. **The value domain is the group set [`../specs/label-taxonomy.md`](../specs/label-taxonomy.md) declares, read from that document rather than restated here.** The label grammar owns the set and a pack only fills it, so a second enumeration in this table is a duplicate source that drifts silently as the grammar gains groups — and it had: this row previously listed seven groups while the label grammar declared eight, and the shipped base pack populates the eighth. A `group` value the label grammar does not declare is a pack-validation error. |
| `name` | string | ✅ | The concrete label instance (e.g., a methodology-specific workflow label). Methodology vernacular for labels lives HERE, exactly as `display_name` is the vernacular home for kinds (§1.2). |
| `color` | string (hex) | ⚪ | The label's 6-hex color (GitHub label color), matching the `label-taxonomy.md` convention. |
| `description` | string | ⚪ | The label's one-line purpose. |
| `applied_at` | string | ⚪ | The pipeline stage / event that applies the label (the `label-taxonomy.md` "Applied At" column shape). |
| `removed_at` | string | ⚪ | The stage / event that removes it, when the label is transient. |
| `projects_kind` | string (kind_id) | conditional | **REQUIRED for a `type:*` label row** (a category-group label naming a work-item kind) — the join key into this pack's `kinds[]`, keeping the `type:*` label family in lockstep with the pack's declared kinds (no independent drift). Omitted for non-`type:*` rows. |

The instance rows for the shipped packs are populated by the label-cleave slice (which relocates the per-pack label content out of `label-taxonomy.md` into these `[[labels]]` facets); the meta-schema here defines only the **shape** of that landing zone.

### 1.1.2 The `[[controls]]` declaration facet (pack-level) — cross-cutting controls

A pack MAY carry a `[[controls]]` array (permitted on all three `role` values — a `role = "base"` pack is the natural home for archetype-invariant controls, which `archetype` and `kit` packs inherit via `extends`). Each entry declares one **cross-cutting control**: a named readiness/tracking dimension — declared ONCE at pack level — that **applies across kinds and across hierarchy levels**, carries a **filterable value domain**, and whose per-item value is **readable as a gate input** (§1.2.1 Arm 3) and by grooming/planning filters. A control declares a *dimension + value domain*, never a check and never firing: checks that consume a control live in `criteria.{readiness,done,gate}` unchanged, and firing stays `lifecycle_behavior`-keyed off the project `lifecycle` (§1.2, §7.4).

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `control_id` | string (slug) | ✅ | Lowercase-kebab, unique within a deployment (the `pack_id` uniqueness scope). The id that `condition.field_ref` (§1.2.1 Arm 3) and `limit_ref` (§1.2.1 Arm 2) resolve against. **Not** a display name. |
| `display_name` | string | ✅ | Human label (e.g., `"Architecture Review Status"`). Practice vernacular lives here, mirroring `display_name` on a kind (§1.2). |
| `description` | string | ⚪ | One-line purpose. |
| `value_domain` | object | ✅ | The filterable value set. v1 type set = `{enum, integer}`: `{ type: enum, values: [...] (≥2) }` OR `{ type: integer, min?, max? }`. `integer` is the domain a `limit_ref` target MUST declare (§1.2.1 Arm 2 — the WIP cap as config; a `limit_ref` naming a non-integer control is a pack-validation error). Further types are RESERVED (the §1.2.1 reserve pattern — fail-loud, never silent). |
| `default` | value ∈ `value_domain` | ⚪ | The value an unset control reads as. When absent AND an item carries no value, a consuming gate's `on_unresolved` fires (§1.2.1 Arm 3) and a filter treats the control as unset. |
| `applies_to` | object | ✅ | The cross-cutting span. `levels[]` (✅, ≥1) — general-hierarchy levels from the work-organization mapping framework's Layer-1 taxonomy `{Portfolio, Program, Project, Milestone/Workstream, Work Item}` at which an instance of this control's value attaches. `kinds[]` (REQUIRED iff `Work Item` ∈ `levels[]`) — the kinds that project the control; `"*"` = every kind in the pack (and, on a `role = "base"` pack, every kind of every inheriting archetype pack). |

**Value carriage (where a control's value lives).** At the `Work Item` level, each in-scope kind's EAD-materialized schema gains **one property per in-scope control** (name = `control_id`; enum = `value_domain.values` for enum-typed) carrying the `x-pmo-control-source` provenance annotation — §3.1 step 4. Because the property name and value domain are pack-declared ONCE, they are **identical across every in-scope kind by construction** — one filter predicate spans kinds (the cross-kind filter contract; the same composition move as the §4 rollup's shared `work_item_type` discriminator). At container levels (`Project` / `Milestone/Workstream` / …), the value attaches to the container entity; carrying it as a small stamp on the container instance is the natural home, and whether that stamp is a first-class entity field is an entity-layer consideration — flagged, not required by this grammar (the §6.3 criteria_version-stamp posture). Physical tracker carriage of control values is the tracker-schema layer's concern and ships on its own track; nothing in this facet blocks on it.

**The value→gate/filter coupling contract.** A declared control's value is a first-class **input surface** with three consumer classes; the control layer defines the value, **never the firing** (§7.4 holds by construction — a control adds no cadence or gate-firing semantics):

| Consumer class | Reads the control via | Contract |
|---|---|---|
| Kind transition gates | §1.2.1 **Arm 3 `control-field`** condition (`field_ref` → this facet) | Gate-layer read; permitted only inside `criteria.gate.checks[]`; firing stays `lifecycle_behavior`-keyed. |
| Kind readiness/done checks (DoR/DoD) | A plain **self-evaluating check** over the item's projected control property — no `condition` (the §1.2.1 rule that a `condition` on readiness/done is a pack-validation error is UNCHANGED) | The DoR consumption path: because a control materializes as a field, a readiness check asserts control-value membership as an ordinary check. |
| Design/architecture review gates + grooming/planning automations | Direct read / filter on the projected property or container stamp | The platform's own design-handoff **architecture / best-practice gate — the Stage-5 Structure-Review gate (SR-G1–SR-G4)** — is the first named external consumer (referenced **by name, no path dependency**, per this document's release-pipeline-neutrality posture): where a deployment declares a design & architecture control set, that gate and grooming/planning automations read the control values as review-state evidence and filter inputs. The dependency direction is consumer→grammar only; this grammar depends on no release-pipeline surface (the ADR-018 kernel discipline). |

**Design rationale (shared-vs-per-kind).** A cross-cutting control is declared once at pack level and projected into every in-scope kind — NOT repeated per kind — because a per-kind re-declaration would fork one dimension's value domain N ways (a drift surface) and break the cross-kind filter/gate contract, which requires one `control_id` and one value domain spanning kinds and levels; per-kind `criteria` remain the home for kind-specific checks, so no parallel criteria path is created.

**Worked instance (illustrative — a control-set instance is K4 user config per §1.4, never authored into this corpus).** The first proving instance is a **design & architecture control set**, declared operator-locally:

```toml
# K4 operator-local pack (or an override pack extending the shared base) — NOT committed to this corpus.
[[controls]]
control_id   = "design-readiness"
display_name = "Design Readiness"
description  = "Whether the item's design is ready for build."
[controls.value_domain]
type   = "enum"
values = ["not-required", "pending", "in-review", "approved"]
[controls.applies_to]
levels = ["Work Item", "Milestone/Workstream"]
kinds  = ["*"]

[[controls]]
control_id   = "architecture-review-status"
display_name = "Architecture Review Status"
description  = "Review state read by design/architecture gates and grooming filters."
default      = "pending"
[controls.value_domain]
type   = "enum"
values = ["not-required", "pending", "in-review", "approved", "waived"]
[controls.applies_to]
levels = ["Work Item", "Milestone/Workstream"]
kinds  = ["*"]
```

### 1.2 Per-kind meta-schema (exact fields, types, requiredness)

Each entry in `kinds[]` is a `Kind` object with exactly these fields:

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `kind_id` | string (slug) | ✅ | Lowercase-kebab, unique within the pack. The value that lands in the entity's `work_item_type` discriminator (`entity-field-schemas.md` §3.18). Matches the Core `id` slug rule (V-CORE-01). **Not** a display name. |
| `display_name` | string | ✅ | Human label (e.g., `"User Story"`). Free-form. **This is the only home for methodology vernacular** — Story / Epic / Feature / Work-Package are non-canonical projections per the glossary Appendix B, so they live here, never in `kind_id`. |
| `base` | const `Work Item` | ✅ | Every kind IS the canonical `Work Item` entity (§18). No other base permitted — this is what keeps a kind a *projection*, not a new entity (D2; the ADR-018 rejected alternative (B) "don't add an entity per kind"). |
| `methodology_projection` | object | ✅ | The projection record. **Projects onto the general hierarchy via the work-organization mapping framework's Layer-2 map** (see §1.3). Fields: `archetype`, `general_level`, `projects_as`, `level_name_ref`, `level_role`. |
| `fields` | object | ✅ | The field overlay. Two sub-keys: `core` (a const reference to the inherited Core 7 — never re-listed, per the `entity-field-schemas.md` §3.0 house style) and `kind_specific[]` (the array below). |
| `fields.kind_specific[]` | array&lt;FieldDecl&gt; | ⚪ | Each `FieldDecl` reuses the §3.N row shape **verbatim**: `{ name, type, required (✅/⚪), cardinality, enum? (enum type), ref? (target entity for typed-ref), description }`. Empty array = a kind with no fields beyond Core 7 (valid — the thin-generic floor). |
| `criteria` | object | ✅ | Three keyed sub-objects: `readiness` (DoR), `done` (DoD), `gate` (phase/stage gate). Each = `{ criteria_version (semver), checks[] }`, where each check = `{ id, statement, level (L1 structural / L2 referential / L3 judgment), automatable (bool) }` plus the **two OPTIONAL keys** `guards_transition` + `condition` (the relationship-conditioned / set-aggregate gate construct — §1.2.1). **The criteria carry their own version**, independent of `pack_version` — the grandfather hook (§6.3). |
| `relationships` | object | ✅ | `allowed_types[]` — a subset of the **7 MVP relationship types by reference** (`frontmatter-schema.md` §Category 4: `GENERATES` / `DEPENDS_ON` / `BLOCKS` / `SUPERSEDES` / `BELONGS_TO` / `RELATES_TO` / `ASSIGNED_TO`). Plus `required_edges[]` (e.g., a kind MAY require a `BELONGS_TO` parent). **No type is defined here** — only referenced + constrained. A pack naming a relationship type outside the 7 is invalid (§5 enforcement). |
| `lifecycle_behavior` | object | ✅ | The behavior map keyed off the **project's** `lifecycle` value (`{timeboxed, continuous, phased}` — read from `delivery_approach` / `custom_methodology_definition`, **NOT** from the kind). Value = the behavior selection (which `criteria.gate` set applies, which cadence primitive). **The explicit defense against the hardcoded-sprint-presumption failure mode:** a kind declares *what gates exist*; the project's lifecycle selects *which fire*. The kind never carries `sprint`/`phase` semantics directly. |
| `axis1_state_machine` | ref OR inline | ✅ | The kind's operational lifecycle (Axis-1). **Default = inherit the generic `Work Item` Axis-1 base machine** `backlog → ready → in-progress → in-review → done | cancelled`, owned by the entity layer (ADR-018 D1; `entity-field-schemas.md` §3.18 V-WI-04). A kind declares this field as `inherit` unless it genuinely **narrows or extends** the generic states, in which case it declares the refinement inline (a type-scoped sub-state per D1 — type-packs project labels over the base, they never re-found it). |
| `materialization` | object | ⚪ | EAD directives (§3): `{ schema_id (the output machine-schema $id), enforcement_mode (canonical-enforce / dialect-enforce), crosswalk_overrides[]? }`. When omitted, EAD derives a `canonical-enforce` schema mechanically from `fields` (the default path — §3). |

### 1.2.1 Relationship-conditioned + set-aggregate gate construct (the `condition` discriminated union)

A `criteria.checks[]` entry MAY carry **two OPTIONAL keys** beyond the four base fields (`id`, `statement`, `level`, `automatable`): `guards_transition` and `condition`. When `condition` is **absent**, the check is a plain self-evaluating criterion — **byte-identical to today's behavior** (the backward-compatibility guarantee that keeps the change additive; §6.1). When `condition` is **present**, `condition.kind` is a **required discriminator** selecting exactly one of three disjoint condition bodies — the §4 discriminated-union / table-per-type / anti-EAV pattern, applied one level down to criteria (the bodies are DISJOINT; no shared payload field beyond the envelope — the anti-EAV requirement).

This construct lets a kind declare a gate whose pass/fail condition reads (a) the **workflow status of a *related* Work Item** across a declared `relationships` edge, or (b) an **aggregate over a scope-bounded *set*** of Work Items (the Kanban WIP / pull-limit gate). Both express gates in **methodology workflow statuses** (the kind's `axis1_state_machine`, keyed off the project `lifecycle`), never platform release-pipeline stages (the ADR-018 §7.2 kernel discipline; see §7.2 + §7.6).

**The expanded check shape.** The 4 existing fields are UNCHANGED; `guards_transition` + `condition` are NEW + OPTIONAL.

```yaml
# A check entry in criteria.{readiness,done,gate}.checks[].
# condition is permitted ONLY inside criteria.gate.checks[] (see the Firing rule below); a
# condition on readiness/done is a pack-validation error.
- id: <slug>                       # EXISTING — unique within the kind's check set
  statement: <string>             # EXISTING — human-readable gate statement
  level: <L1 | L2 | L3>           # EXISTING — projection level (a condition'd check is L2; see EAD §3)
  automatable: <bool>             # EXISTING
  guards_transition: "<from> -> <to>"   # NEW, OPTIONAL — the axis1_state_machine transition this gate
                                  #   guards (from/to ∈ the kind's axis1_state_machine states).
                                  #   REQUIRED when `condition` is present; omitted otherwise (D-A).
  condition:                      # NEW, OPTIONAL — absent ⇒ today's self-evaluating check.
    kind: <related-item-status | set-aggregate | control-field>   # REQUIRED discriminator.
    # ... exactly ONE condition body below, selected by `kind`.
```

**Arm 1 — `related-item-status`.** Resolves a *single related Work Item's* axis-1 workflow status across a declared edge.

```yaml
  condition:
    kind: related-item-status
    edge: <BELONGS_TO | DEPENDS_ON | BLOCKS>   # REQUIRED — MUST ∈ this kind's relationships.allowed_types[]
    edge_direction: <outbound | inbound>        # REQUIRED — which end of the directed edge THIS item occupies
                                                #   (frontmatter-schema §Cat-4 directionality: BELONGS_TO = Part→Whole,
                                                #    DEPENDS_ON = Dependent→Dependency, BLOCKS = Blocker→Blocked).
                                                #   outbound = this item is the edge SOURCE; inbound = the TARGET.
    target_status_in: [<state>, ...]            # REQUIRED — the related item's axis1_state_machine state(s)
                                                #   that SATISFY the gate (≥1). Not validated against the target
                                                #   kind's machine at pack-load (the target may be any kind);
                                                #   an unresolvable/empty match fires on_unresolved.
    on_unresolved: BLOCK-TRANSITION             # REQUIRED — gate-disposition when the edge/target can't be resolved.
```

**Arm 2 — `set-aggregate`.** Reduces an aggregate over a *scope-bounded set* of Work Items and compares it to a limit. The Kanban WIP / pull-limit gate.

```yaml
  condition:
    kind: set-aggregate
    set:                                        # REQUIRED — the POPULATION the aggregate runs over.
      scope: <project | parent | board>         # REQUIRED — the in-graph container class the set is drawn from.
                                                #   project = the Project entity; parent = this item's BELONGS_TO
                                                #   container (chain 17); board = a named Workstream-class container.
                                                #   Resolved from the ENTITY GRAPH — never an implicit "current view"
                                                #   and never a release-pipeline construct (§7.2).
      scope_ref: <entity-id>                    # REQUIRED when scope ∈ {board}; OPTIONAL when scope ∈ {project, parent}
                                                #   (those resolve from the item's own context). The in-graph container id.
      kind_filter: [<work_item_type>, ...]      # OPTIONAL — restrict the count to these kinds (class-of-service).
                                                #   Omitted ⇒ all kinds in scope.
      status_filter: [<state>, ...]             # REQUIRED — the axis1_state_machine state(s) that define set membership.
      edge: BELONGS_TO                          # OPTIONAL — the membership edge when scope is container-relative;
                                                #   MUST ∈ relationships.allowed_types[]; defaults to BELONGS_TO (chain 17).
    aggregate: <count>                          # REQUIRED — the reduction. v1 value set = {count}; sum-of-<field> RESERVED.
    comparator: <"<" | "<=" | ">" | ">=" | "==">   # REQUIRED — the relation the reduced value must satisfy to PASS.
    limit: <integer>                            # REQUIRED unless limit_ref is set — the literal threshold.
    limit_ref: <control-field-id>               # ALTERNATIVE to limit — a control-field holding the cap (composes with
                                                #   the control-field arm; the WIP cap becomes config, not a literal).
                                                #   Exactly ONE of {limit, limit_ref} is present (else pack-validation error).
    on_unresolved: BLOCK-TRANSITION             # REQUIRED — gate-disposition when the set/scope can't be resolved.
```

**Arm 3 — `control-field`.** Resolves a **cross-cutting control's value** (a `[[controls]]` declaration — §1.1.2) at a declared scope; the gate PASSES when the value is in the satisfying set. The field-axis sibling of Arm 1's status axis: Arm 1 reads a related item's *workflow state*; Arm 3 reads a declared *control value* (data, not an axis1 state).

```yaml
  condition:
    kind: control-field
    field_ref: <control_id>            # REQUIRED — MUST resolve to a [[controls]] declaration visible to this
                                       #   pack (own, or inherited via extends); an unresolvable field_ref is a
                                       #   pack-validation error (the Arm-1 "MUST ∈ allowed_types" posture).
    value_in: [<value>, ...]           # REQUIRED (≥1) — the control values that SATISFY the gate. Each MUST ∈
                                       #   the control's value_domain — validated at pack-load (the domain is
                                       #   declared, so this IS statically checkable — unlike Arm 1's
                                       #   target_status_in, whose target kind is unknown at pack-load).
                                       #   v1 semantics = literal membership; comparator forms on integer
                                       #   controls are RESERVED (the Arm-2 sum-of-<field> reserve pattern).
    scope: self                        # OPTIONAL — where the value is read; DEFAULT self (the transitioning
                                       #   item's own projected control property, §3.1 step 4). The values
                                       #   {parent, project, board} are RESERVED — registered here, fail-loud
                                       #   at pack-validation ("reserved, not yet implemented") — until
                                       #   container-level value carriage ships; on widening they reuse Arm 2's
                                       #   set.scope container vocabulary (+ scope_ref when board).
    on_unresolved: BLOCK-TRANSITION    # REQUIRED — gate-disposition when the value cannot be resolved (control
                                       #   unset with no declared default). The same gate-layer set
                                       #   {BLOCK-TRANSITION, WARN-HEALTH} as Arms 1–2 (D-B) — the disposition
                                       #   this arm was always specified to inherit.
```

**Discriminator table (the one-screen contract):**

| `condition.kind` | Body fields | EAD level → annotation | Resolution | Edge? | Cycle class |
|---|---|---|---|---|---|
| (absent) | — (self-check) | L1/L2/L3 per existing §3.1 step 5 | local | no | none |
| `related-item-status` | `edge` · `edge_direction` · `target_status_in[]` · `on_unresolved` | **L2** → `x-pmo-referential` (resolves STATE) | single edge → target state | yes | A↔B (refusable) |
| `set-aggregate` | `set{scope, scope_ref?, kind_filter?, status_filter[], edge?}` · `aggregate` · `comparator` · `limit \| limit_ref` · `on_unresolved` | **L2** → `x-pmo-aggregate` (NEW; resolves a reduced value over a population) | set-enumerate (chain 17) + reduce + compare | optional (membership edge) | convergent self-edge (exempt) + mutual two-set (refusable) |
| `control-field` | `field_ref` · `value_in[]` · `scope?` · `on_unresolved` | **L2** → `x-pmo-control` (NEW; resolves a declared control's VALUE at a scope) | control-declaration lookup (§1.1.2) + scoped value read + membership compare | no | none (a control value is data, not a transition-produced state — it contributes no gating-graph edge; §7.6) |

**Firing rule (the §7.4 hardcoded-sprint-presumption defense, by construction).** A `condition` is permitted **only inside a `criteria.gate` check**. Gate checks inherit `lifecycle_behavior`-keyed firing: the **kind declares the gate exists; the project's `lifecycle` (`{timeboxed, continuous, phased}`) selects whether it fires** (§1.2 + §7.4). The construct names only `axis1_state_machine` states + edges + generic container scopes — it adds **no** sprint/phase/cadence semantics to the kind, so §7.4 holds by construction. Set-aggregate is the **`continuous` lifecycle's signature gate** (Kanban WIP); a `timeboxed` (Scrum) project MAY declare the same check but its `lifecycle_behavior` need not fire it (Scrum bounds WIP by sprint commitment instead).

**`guards_transition` requiredness (D-A).** `guards_transition` is REQUIRED whenever `condition` is present, omitted otherwise. Every condition kind gates a *transition* (the point of a relationship/aggregate gate is to block a state move); binding the construct to a transition by construction is what makes the `on_unresolved: BLOCK-TRANSITION` disposition meaningful (it blocks *that* transition). A self-evaluating check (no `condition`) keeps `guards_transition` optional — unchanged from today.

**Gate-disposition definition (`on_unresolved`) — distinct from the entity-layer write-time enum (D-B).** A gate check's `on_unresolved` draws from the **gate-layer disposition set `{BLOCK-TRANSITION, WARN-HEALTH}`**, defined here in the meta-schema. This is **distinct from** the entity layer's frozen write-time `on-unresolved` enum `{BLOCK-WRITE, WARN-HEALTH, DEFER-G8}` (`entity-field-schemas.md` §on-unresolved): the two govern **different events on different layers**. The entity-layer enum governs a **write** of a malformed *referential field* (a dangling FK at row-write — `BLOCK-WRITE`); the gate `on_unresolved` governs a **transition** of a *well-formed* row whose *gate condition* can't be resolved or isn't satisfied (a state move — `BLOCK-TRANSITION`). `BLOCK-TRANSITION` is a **peer-by-posture** of the entity layer's `BLOCK-WRITE` — same refuse-and-route posture (refuse the move, surface the failing rule + expected-vs-actual, route to repair per `entity-field-schemas.md` §7), different governed event; `WARN-HEALTH` is reused by name from the entity-layer posture (a soft WIP gate may WARN; a hard gate BLOCKs). The frozen entity-layer enum is **cross-walked, not extended** — this construct adds no member to it.

**Worked instances** (illustrative grammar — not shipped kinds; kinds are K4 user config per §1.4).

*(a) Child cannot advance `refinement → ready` until parent Epic is design-approved (BELONGS_TO).* Gates at the *enter-ready* point of the lean cycle — a child Story cannot leave refinement for `ready` (committable for development) until its parent Epic's design is approved.

```yaml
# inside a kind (e.g. a Story-class kind), criteria.gate.checks[]:
- id: gate-parent-epic-design-approved
  statement: "Cannot advance to ready until the parent Epic is design-approved."
  level: L2
  automatable: true
  guards_transition: "refinement -> ready"
  condition:
    kind: related-item-status
    edge: BELONGS_TO
    edge_direction: outbound          # this child is the Part (source) of BELONGS_TO → Whole (the Epic)
    target_status_in: [design-approved]
    on_unresolved: BLOCK-TRANSITION
```

*(b) A Story cannot leave `ready` until a blocking Spike is `done` (DEPENDS_ON / BLOCKS).* Gates at a *different* cycle point (leaving ready), proving multi-point support.

```yaml
- id: gate-blocking-spike-done
  statement: "Cannot leave ready until the blocking Spike is done."
  level: L2
  automatable: true
  guards_transition: "ready -> in-progress"
  condition:
    kind: related-item-status
    edge: DEPENDS_ON
    edge_direction: outbound          # this Story is the Dependent (source) of DEPENDS_ON → Dependency (the Spike)
    target_status_in: [done]
    on_unresolved: BLOCK-TRANSITION
# Equivalent modeling via BLOCKS from the Spike's side: a Spike kind declares a guards_transition
# gate on the items it BLOCKS with edge: BLOCKS, edge_direction: outbound (Spike = Blocker → Blocked).
# Either direction is expressible; edge_direction disambiguates which end the gate-owning kind occupies.
```

*(c) Set-aggregate Kanban WIP — "< N items of kind=Story in status=in-progress within board scope" gates the pull.* The `continuous` lifecycle's signature gate.

```yaml
- id: gate-wip-pull-limit
  statement: "Cannot pull a Story into in-progress while >= N Stories are already in-progress on this board."
  level: L2
  automatable: true
  guards_transition: "ready -> in-progress"
  condition:
    kind: set-aggregate
    set:
      scope: board
      scope_ref: board-eng-flow        # a Workstream-class container entity id
      kind_filter: [story]             # class-of-service: count only Stories (an expedite lane = its own check + limit)
      status_filter: [in-progress]     # the WIP column
      edge: BELONGS_TO                 # membership = the board's BELONGS_TO children (chain 17)
    aggregate: count
    comparator: "<"                    # pull permitted only while count(set) < limit
    limit: 3
    on_unresolved: BLOCK-TRANSITION
# limit_ref variant (composes with the control-field arm): replace `limit: 3` with
#   limit_ref: wip-limit-eng-flow   → the cap is a control-field, config not hardcode.
# Pull-capacity (free slots) is the same gate read as (limit - count).
```

*(d) GitHub use case — the first plug-and-play adapter.* The three rules above are **methodology-pack base function** (abstract, archetype-neutral, in the K1 grammar). The **GitHub adapter is the K4 operator-local expression** that binds them to GitHub Issues/Projects state — it is **not** committed to this corpus (adapter config is K4 per §1.4 / knowledge-architecture). The adapter maps: the related item's `axis1_state_machine` state → a GitHub Projects **Status** field value (e.g., Epic Status = "Design Approved"); the `BELONGS_TO` / `DEPENDS_ON` edges → GitHub native **parent/sub-issue** links and **tracked-by / blocked-by** relations; the set-aggregate `scope: board` → a GitHub **Project (board)**, `status_filter: [in-progress]` → the board's **In Progress** column, `count < limit` → the column's WIP cap. **GitHub is the first adapter**; the operator-local type-pack example (K4) expresses the Epic→child and Spike→dependent rules; further adapters (Jira / Linear) ride the existing adapter epics, out of scope here.

*(e) Control-field gate — the design & architecture control set (§1.1.2 worked instance) gating the leave-refinement transition.* Consumes a K4-declared control; the adapter expression maps the control value to a host field exactly as (d) maps states and edges (e.g., a single-select field on the host's project board — K4, per (d)).

```yaml
- id: gate-architecture-review-approved
  statement: "Cannot advance to ready until this item's architecture review is approved, waived, or not required."
  level: L2
  automatable: true
  guards_transition: "refinement -> ready"
  condition:
    kind: control-field
    field_ref: architecture-review-status   # resolves to the §1.1.2 [[controls]] declaration
    value_in: [approved, waived, not-required]
    scope: self
    on_unresolved: BLOCK-TRANSITION
```

### 1.2.2 Status resolution when no platform adapter is configured

Worked instance (d) above binds a kind's `axis1_state_machine` state to a host system through a **K4 operator-local adapter**. That adapter is **optional**: a deployment may run with none, and a deployment running with none is not a deployment without status. This subsection states what a consumer does on each path. It is the status-axis sibling of the §2.2 CASE-3 kind fallback and carries the same **caveat-on-gap** discipline — a gap is surfaced, **never silently defaulted**.

| Path | Predicate | Consumer behavior |
|---|---|---|
| **Configured** | a K4 adapter declares a binding for the resolved pack's `kinds[]` | Resolve the item's Axis-1 state **through the adapter**, per the (d) mapping. The adapter's host field is the read surface; this grammar states no host vocabulary and names no host field. |
| **Unconfigured** | no adapter binding resolves for this deployment | Maintain and read the entity's own Axis-1 `lifecycle_state` **directly on the `Work Item` entity**, under the obligated actor and qualifying evidence [`../standards/entity-lifecycle-protocol.md`](../standards/entity-lifecycle-protocol.md) §3.10 already names for every transition of the base machine (cited, not restated), and **emit an explicit caveat naming the unresolved binding**. Never infer a state, never substitute a host vocabulary, and never read *no adapter configured* as *no status*. |

**The fallback contract is K1; the adapter binding stays K4.** Worked instance (d) places the *adapter expression* in K4 and is **unchanged** by this subsection — an adapter and a constraint on adapters are different objects. The rule must live in K1 because the unconfigured path is precisely the path on which the K4 artifact **does not exist**: a rule homed in an absent file cannot state the rule for its own absence. The corpus already splits exactly this way twice — a K1 standard reads the operator-local adapter config and defines the unconfigured outcome *itself* (an unconfigured or unreachable adapter is a recorded `skipped` run-record outcome, never a hard failure), and a K1 constraint record states the properties a future corpus-home adapter MUST honour while defining no adapter and no selector. Both are referenced by name per this document's precedent convention.

**This rule names no kind, no archetype, and no state literal.** Kind resolution is unchanged: a consumer reads the resolved pack's `kinds[]` and each kind's `axis1_state_machine` (§1.2), so the rule holds byte-unchanged across every archetype pack — those shipped today and those not yet built. Branching on a methodology-specific kind name here is the §2.3 hardcoded-kind anti-pattern, which §5 forbids.

**Reading status back is §4, on either path.** The cross-kind rollup is already specified there as one kind-agnostic `BELONGS_TO` traversal (the entity-model rollup chain 17) plus a group-by-`work_item_type` projection; it is stated once there and is **not** restated here. The traversal is identical on both paths — only the per-item read *source* differs (the host field when configured, `lifecycle_state` when not) — so an unconfigured deployment loses no read surface, only the host's rendering of it.

### 1.3 `methodology_projection` — projects onto the Layer-2 map

The `methodology_projection` object is the seam to the **work-organization mapping framework**. It projects a kind onto the **general hierarchy** through that framework's Layer-2 hierarchy-by-methodology map — the domain-neutral methodology→hierarchy map — **never** onto any release-pipeline ticket model (the ADR-018 kernel discipline: `core/` must not depend on release-pipeline dev tooling).

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `archetype` | string | ✅ | **The `delivery_approach` archetype name set §1.1 defines** — stated by reference rather than re-counted, because the previous wording read "one of the 8 … **OR** `Custom`" and double-counted `Custom`, which is harmless as prose and unimplementable as a rule — **OR the neutral sentinel `"*"`, permitted ONLY on a kind declared inside a `role = "kit"` pack** (ADR-177 D2). For a concrete archetype the value is the byte-identical join key into the work-organization mapping framework's Layer-2 row for that archetype (and the same key the methodology corpus uses). **`"*"` declares the ABSENCE of a Layer-2 row rather than naming one**: a kit's kinds perform no Layer-2 join, so `general_level` is asserted directly on the kind, `projects_as` degenerates to the `display_name` common case, and `level_name_ref` is omitted — there is no anchor to name. **This row is the weld the kit unit exists to cut, and it is the one that carries the capability**: a change relaxing only the pack-level `applies_to` would validate a kit whose every kind still named an archetype — the pack would pass every gate and the capability would be absent. An archetype pack's kinds still MUST name their archetype; `"*"` on a kind outside a `role = "kit"` pack is a pack-validation error. |
| `general_level` | enum | ✅ | The general hierarchy level the kind occupies, from the framework's Layer-1 per-level-purpose taxonomy: `{Portfolio, Program, Project, Milestone/Workstream, Work Item}`. For a work-item *kind* this is almost always `Work Item` (the finest level) — the framework's Layer-2 invariant is that every methodology's finest execution unit lands on the single `Work Item` level. A kind that resolves elsewhere is a modeling smell to flag. **On a `role = "kit"` pack that advisory hardens into a rule: every kind's `general_level` MUST be `Work Item`, and any other value is a pack-validation error (`PACK-K06a`), not a smell.** The narrowing is deliberate and is scoped to kits alone. A kind's `base` is the const `Work Item` and the container tiers are separate frozen entities, so a kind declared at `Portfolio`, `Program` or `Project` would be a **new entity node** rather than a projection — the shape ADR-177 D6 forbids on its own terms. A kit is the unit most likely to be authored by a deployment reaching for "coverage of every organizational level", and coverage is achieved by **projection, not by declaration**: a rollup resolves an entity type at each container tier from the frozen entity model and a kit-declared kind at the Work-Item level. An archetype pack's advisory is left unchanged, so no shipped pack is migrated. |
| `projects_as` | string | ✅ | The methodology-native level name this kind surfaces as (e.g., Scrum → `Story`, Waterfall → `WBS leaf`). A display projection — equals `display_name` for the common case; distinct only when the pack wants the map-name and the UI-name to differ. |
| `level_name_ref` | string (anchor) | ⚪ | An anchor into the work-organization mapping framework's Layer-2 mapping facet for `archetype` (e.g., the Scrum or Waterfall map section), naming the row whose level mapping this kind inherits. `derive` for `archetype: Custom` (resolve via the custom block's `base_archetype` per §2 / the framework's Layer-4 by-nature procedure). **A kind whose `archetype` is `"*"` OMITS this field** (ADR-177 D2). The anchor points into a Layer-2 row; a neutral kind has no such row, and `derive` is not a substitute because `derive` resolves through a custom block's `base_archetype` and a neutral kind has neither. The field is optional, so omission is legal and is the defined state for a kit's kinds. |
| `level_role` | enum | ⚪ | The kind's role **within** the Work-Item level: `execution` (a unit of work that is done) or `grouping` (a unit that contains other Work-Item-level kinds as a backlog grouping). **Absent means `execution`**, which is why the field is additive and no shipped pack moves. This is the declarative carrier for a distinction the corpus previously stated only as prose and enforced only as the hardcoded label literal `type:epic`: it does **not** change `general_level`, which stays `Work Item` for both values — a grouping kind is a Work-Item-level grouping label, **never a new level**. The domain is **CLOSED**: an unknown value is an error (`PACK-K08`), deliberately unlike `kit_class`'s OPEN domain, because the distinction is binary and internal to how a rollup traverses rather than an extensible successor set (ADR-177 D6). Within one `role = "kit"` pack **at most one** kind may declare `grouping` (`PACK-K09`) — two grouping altitudes inside a kit is a shadow tier ladder built inside the Work Item entity, parallel to the entity layer's real one and free to drift from it. An archetype pack is unbound by that rule: a methodology's own altitudes (SAFe's portfolio-epic over program-epic) are the methodology pack's to model. |

> **The projection direction.** The work-organization mapping framework is **upstream**: it is the map; a kind projects *onto* it. A kind never re-derives what a hierarchy level *is* (that is the framework's Layer 1) and never re-states a methodology's level mapping (that is the framework's Layer 2). It cites the map by `archetype` key + `level_name_ref` anchor and inherits the placement. This is the framework's own stated contract surface: "the type layer reads the Layer-2 mapping facet to know which level a declared kind occupies … projecting onto this map, not onto any release-pipeline ticket model."

### 1.4 The shipped best-practice defaults are *consumed*, not re-authored here

The work-organization mapping framework's **Layer 3** ships the best-practice default work-item schemas (Story from the Scrum Guide + INVEST; Bug from IEEE-1044 defect classification; a WBS-task sketch from PMBOK). Those defaults are authored from **methodology best practice**, not reverse-engineered from any issue template or release-pipeline ticket model.

This meta-schema's contract toward them is **acceptance**, not authorship:

- Every Layer-3 default schema **MUST parse against this grammar** — they are the grammar's worked examples and its validation corpus. (The framework states this directly: Layer 3's defaults are "the *first instances* in that grammar.")
- A deployment **consumes** a Layer-3 default by declaring a `Kind` whose `fields.kind_specific[]` adopts the default's field list and whose `methodology_projection.archetype` keys the matching Layer-2 row.
- A deployment **overrides** a default via the plug-and-play model (§2 + the framework's Layer-4): bring a kind that starts from the Layer-3 default and overrides only the deltas (field-level merge, default-as-base).

This doc therefore **does not** define Story / Bug / WBS-task field lists — that would duplicate Layer 3 and re-trap user-config kinds in the git-tracked corpus. The grammar is the format; Layer 3 is the best-practice content; a deployment's chosen kinds are K4 data.

---

## 2. Custom-kind escape hatch + N=2 governance-promotion

The custom-kind mechanism mirrors `custom_methodology_definition` **exactly** (the methodology-parameterization Custom Extension Protocol + Skill Consumption Pattern), so the platform carries **one** custom-extension mental model. The kind set is **open declaratively** (any project MAY declare a custom kind) but **closed at the enum/code level** (no skill ever adds a `kind_id` to a hardcoded list; the registry is data; promotion is governed) — the standing defense against the enum-drift failure mode.

### 2.1 Custom-kind declaration

A kind with `methodology_projection.archetype: Custom` MUST carry a `custom_kind_definition` block (analogous to `custom_methodology_definition`):

| Field | Type | Req | Semantics |
|---|---|---|---|
| `name` | string | ✅ | The custom kind's display name. |
| `base_kind` | a kind in scope **OR** `null` | ✅ | `null` = a genuinely novel kind (no projection fallback). Non-null = inherit `fields` + `criteria` + `lifecycle_behavior` from the named base kind; declare deltas only. The exact analog of `custom_methodology_definition.base_archetype`. |
| `derived_from` | array&lt;kind_id&gt; | ✅ (may be `[]`) | The kinds this fuses. Typically paired with `base_kind: null`. |
| `fields.kind_specific[]` | array | ✅ | Load-bearing, not a stub (the populated-block rigor rule — a stubbed block forces consumers into the null-base fallback even when `base_kind` is set, defeating the block). |
| `criteria` | object | ✅ | Full `readiness` / `done` / `gate`, versioned. |
| `notes` | string | ⚪ | Rationale + trade-offs. |

### 2.2 Consumption (CASE 1/2/3 — verbatim mirror of the Skill Consumption Pattern)

A skill resolving a kind follows the same three branches the methodology pattern defines, with `delivery_approach` → kind `archetype` and `base_archetype` → `base_kind`:

- **CASE 1** — `archetype ∈ {the 8 archetype names}`: read the best-practice default for that archetype's kind (the framework's Layer 3) and parameterize directly. No custom block.
- **CASE 2** — `archetype: Custom` **AND** `base_kind != null`: read the custom block; start from `base_kind`'s declaration as the DEFAULT; override `fields` / `criteria` / `lifecycle_behavior` only where the block differs.
- **CASE 3** — `archetype: Custom` **AND** `base_kind == null`: read the custom block; use its `fields` / `criteria` directly — **NO kind fallback**. If a consumer cannot parameterize from these alone, it emits a generic-`Work Item` treatment **WITH an explicit caveat** — it never silently treats the kind as Story/Task (the base-archetype-blind-fallback failure mode; the framework's Layer-4 §4.2 "caveat-on-gap" discipline).

A skill **MUST** read the registry at invocation (§5.1) and **MUST log the branch taken** (e.g., `[kind-branch: CASE 2 base=story]`), mirroring the methodology pattern's debug-logging rule.

### 2.3 N=2 governance-promotion (within a 180-day window)

A custom kind whose `name` recurs **identical across ≥2 projects within a 180-day window** is an emergence candidate (the same emergence rule the decision-discipline defines and the methodology Custom Extension Protocol applies). Procedure:

1. Log the occurrence toward the emergence cache (N=1 → N=2).
2. The **operator MAY** elevate it to a first-class best-practice default kind via a governed change (the "No ungoverned changes" protocol). On elevation, the work-organization mapping framework's Layer 3 gains the default schema and Layer 2 gains the kind's mapping row; existing `Custom`-declared instances may migrate.
3. **Skills MUST NOT** promote kinds unilaterally — elevation is operator authority.

A skill that hardcodes `if kind == "story"` branching is the anti-pattern (§5 forbids it): the kind set stays open as data, closed as code.

---

## 3. EAD materialization (declared kind → concrete per-kind machine-schema)

Each declared kind is **EAD-materialized** into a concrete per-kind machine-schema using the **exact** mechanism that derives `raid-log.schema.json` from the RAID Item entity field schema — no new physicalization is invented. The declaration is authoritative; the JSON-Schema is its persistence dialect (the same relationship `raid-log.schema.json` has to the RAID Item entity).

### 3.1 The derivation (the EAD contract, generalized)

For each declared kind, EAD emits a JSON-Schema (draft-07) `work-item-<kind_id>.schema.json` by mechanical projection (the `$id` mirroring the `raid-log.schema.json` naming):

1. **Core 7 → 7 base properties** (inherited; identical to the V-CORE-01..07 floor): `id`; `entity_type` const = `Work Item`; `lifecycle_state` enum = the kind's `axis1_state_machine` states (default the generic six); `content_lifecycle_pattern`; `owning_agent`; `created_date` with the not-future temporal check; `relationships[]` constrained to `relationships.allowed_types`.
2. **`work_item_type` → a `const` property** = `kind_id` (the discriminator that lets a cross-kind query filter / group by kind — load-bearing for the cross-kind rollup in §4).
3. **`parent_ref` → a typed-ref property** with `x-pmo-referential: { target: "Milestone.id | Workstream.id", level: "L2", on-unresolved: "BLOCK-WRITE" }` (the rollup edge; the entity's V-WI-03 / X-28 contract — the polymorphic `BELONGS_TO` parent).
4. **Each `fields.kind_specific[]` FieldDecl → one property**, classified by the **7-class `x-pmo-class` column crosswalk** observed in `raid-log.schema.json`: `exact-map` · `rename-map` · `type-lift` · `dialect-projection` (with `x-pmo-canonical-enum` + `x-pmo-legacy-crosswalk` when a value set projects to a legacy/display set) · plus the `x-pmo-referential`, `x-pmo-temporal`, and `allOf` conditional-required annotations for L2/L3. Additionally, **each pack-level control in scope for the kind (§1.1.2 `applies_to`) → one property** (name = `control_id`; enum = `value_domain.values` for enum-typed; bounds for integer-typed), annotated `x-pmo-control-source: "<pack_id>#<control_id>"` — a control-projected property is pack-declared, not a `FieldDecl`, so it carries the provenance key instead of an `x-pmo-class` crosswalk class (the 7-class crosswalk is untouched).
5. **Each `criteria.checks[]` projects by level:** `automatable: true` ∧ `level: L1` → a schema-expressible constraint (enum / pattern / required); `level: L2` → an `x-pmo-referential` entry; `level: L3` → an `x-pmo-criteria-judgment` annotation (recorded so a reviewer/skill can surface it, not machine-enforced). **When the L2 check carries a `condition` (§1.2.1), the annotation is selected by `condition.kind`:** `related-item-status` → an `x-pmo-referential` entry that resolves the target's *state* (not its existence), with the gate-layer `on-unresolved: BLOCK-TRANSITION`; `set-aggregate` → an `x-pmo-aggregate` annotation (the NEW class, §3.1a). A check with no `condition` keeps the existing behavior unchanged.
6. **Negative tests generated 1:1 from the rules** (the `entity-field-schemas.md` §3.0b pattern + the `x-pmo-negative-tests` array `raid-log.schema.json` carries): each L1 enum → one out-of-enum NT; each L2 ref → one unresolvable-id NT. **A materialized kind ships ≥2 negative tests.** A `condition`'d gate check (§1.2.1) generates its negative tests 1:1 from the construct:
   - **NT-status-1** — a `related-item-status` gate: a transition write while the related item (across `edge`) is NOT in `target_status_in` → referential gate FAIL (transition blocked).
   - **NT-status-2** — a `related-item-status` gate: an unresolvable edge/target (related item missing) → `on-unresolved: BLOCK-TRANSITION` fires.
   - **NT-agg-1** — a `set-aggregate` gate: the `guards_transition` write while `count(set) >= limit` (for `comparator: "<"`) → aggregate gate FAIL (pull blocked).
   - **NT-agg-2** — a `set-aggregate` gate: an unresolvable `scope_ref` (board entity missing) → `on-unresolved: BLOCK-TRANSITION` fires.
   - **NT-ctl-1** — a `control-field` gate: the `guards_transition` write while the scoped control value ∉ `value_in` → control gate FAIL (transition blocked).
   - **NT-ctl-2** — a `control-field` gate: the control value unresolvable (unset, no `default` declared) → `on-unresolved: BLOCK-TRANSITION` fires.

### 3.1a Condition'd-gate projection (the three annotation classes)

A `condition`'d gate check (§1.2.1) is **L2** (it resolves beyond the row's own self-check — another entity's state, a population, or a declared control), so step 5 routes it to a referential-class annotation — projecting via the **existing §3.1 step-5 by-level rule**, with **no new physicalization** (the §3 discipline). Three annotation shapes apply, selected by `condition.kind`.

**`related-item-status` → `x-pmo-referential` resolving STATE (extends the existing precedent).** The existing step-3 `parent_ref` precedent materializes `x-pmo-referential: { target, level: L2, on-unresolved: BLOCK-WRITE }` (resolves another entity's *existence*). The status arm **extends — does not replace** — that shape: the resolved object is the target's *state* (not its existence), and the disposition is the gate-layer `BLOCK-TRANSITION` (guard a state move) rather than `BLOCK-WRITE` (guard a row write).

```jsonc
// On the derived work-item-<kind>.schema.json, for a related-item-status gate check:
"x-pmo-referential": {
  "target": "WorkItem.lifecycle_state via <edge>",   // resolves the target's STATE, not its existence
  "level": "L2",
  "on-unresolved": "BLOCK-TRANSITION",               // gate-layer disposition (§1.2.1)
  "x-pmo-edge": "<BELONGS_TO|DEPENDS_ON|BLOCKS>",
  "x-pmo-edge-direction": "<outbound|inbound>",
  "x-pmo-satisfying-states": ["<state>", "..."],
  "x-pmo-guards-transition": "<from> -> <to>"
}
```

**`set-aggregate` → a NEW `x-pmo-aggregate` annotation class (L2-aggregate sub-class).** A set-aggregate resolves a *reduced value over a population*, which the single-target `x-pmo-referential` shape cannot express. It is a **NEW sibling annotation**, modeled on `x-pmo-referential` (for level + disposition) **+ the chain-17 `BELONGS_TO` rollup traversal** (`project-entity-model.md` §18 / chain 17 — the kind-agnostic set enumeration the platform already specifies). **The set-aggregate gate does not invent set evaluation; it applies a comparator to the rollup traversal the entity model already specifies.**

```jsonc
// On the derived work-item-<kind>.schema.json, for a set-aggregate gate check — a NEW x-pmo-aggregate:
"x-pmo-aggregate": {
  "set": {
    "scope": "<project|parent|board>",
    "scope_ref": "<entity-id>",          // present when scope = board
    "kind_filter": ["<work_item_type>", "..."],   // optional
    "status_filter": ["<state>", "..."],
    "edge": "BELONGS_TO"
  },
  "aggregate": "count",
  "comparator": "<comparator>",
  "limit": 0,                            // integer literal, OR "limit_ref": "<control-field-id>"
  "level": "L2",                         // resolves other entities → L2 (the aggregate sub-class)
  "on-unresolved": "BLOCK-TRANSITION",
  "x-pmo-derives-via": "chain-17 BELONGS_TO set traversal + reduce"   // cites the EXISTING traversal; no new physicalization
}
```

Both annotations bite where `parent_ref` (V-WI-03 / X-28) and the `BELONGS_TO` rollup (V-WI-06 / X-29) already bite — `tracker-manager`'s pre-write/transition validation pass (§5.2). **No new enforcer.** The cross-kind rollup (§4) is untouched — the construct adds a *check*, not a kind-specific *field*; the count groups by the same `work_item_type` discriminator the rollup already uses. The **only new evaluation surface** is the set-aggregate's **set-enumerate-and-reduce** contract (resolve `set.scope` → enumerate `BELONGS_TO` children via the chain-17 traversal → apply `status_filter` + optional `kind_filter` → `aggregate` → compare to `limit` / `limit_ref`), sited in the existing enforcer; the *physical* resolver (index scan / graph walk) is G3/G4 physicalization per the entity-model boundary axiom (`entity-field-schemas.md` §boundary-axiom), exactly as the single-referential resolver is.

**`control-field` → a NEW `x-pmo-control` annotation class (L2 control-value sub-class).** A control-field gate resolves a *declared control's value at a scope* — not a target's existence/state (`x-pmo-referential`) and not a reduced population value (`x-pmo-aggregate`) — so it is the third sibling annotation, modeled on `x-pmo-referential` for level + disposition. It is stamped L2 per the §1.2.1 condition'd-check rule (uniform union-wide, even at `scope: self` where the resolution is a declaration lookup plus the item's own projected property rather than another entity). **No new physicalization** and **no new enforcer** — the read bites at `tracker-manager`'s existing pre-write/transition pass (§5.2); the only evaluation surface is the scoped value read + membership compare.

```jsonc
// On the derived work-item-<kind>.schema.json, for a control-field gate check — a NEW x-pmo-control:
"x-pmo-control": {
  "control_ref": "<control_id>",          // resolves against the pack's [[controls]] declarations (§1.1.2)
  "satisfying_values": ["<value>", "..."],
  "scope": "self",                         // v1; {parent, project, board} reserved (§1.2.1 Arm 3)
  "level": "L2",
  "on-unresolved": "BLOCK-TRANSITION",
  "x-pmo-guards-transition": "<from> -> <to>"
}
```

### 3.2 Enforcement mode

Follows the `raid-log.schema.json` precedent: **`canonical-enforce`** (the entity-canonical contract) by default for a new kind; **`dialect-enforce`** available when a kind must validate a pre-existing legacy artifact shape. The mode is recorded in `materialization.enforcement_mode` and on the derived schema's `x-pmo-derivation.mode`, so the same rule can yield a mode-dependent verdict (the `raid-log.schema.json` `NT-RAID-3` pattern).

> **Worked materialization (illustrative, grammar-level — not a shipped kind).** A kind whose `fields.kind_specific[]` declares `severity` (enum, ✅) materializes a property `{"type":"string","enum":[…],"x-pmo-class":"exact-map","x-pmo-entity-field":"severity"}` plus a negative test `{ input: {severity: "<out-of-enum>"}, expect_fail: "severity enum (L1)" }`. The Core 7 + `work_item_type` const + `parent_ref` typed-ref are emitted identically for every kind. The kind's field list is supplied by the deployment (a Layer-3 default or a brought override) — this grammar specifies only *how* the declaration becomes a schema.

---

## 4. The cross-kind rollup composes (anti-EAV — the load-bearing bet)

The thin generic entity + per-kind EAD-materialized schemas **compose** into a clean cross-kind rollup *without* degrading into EAV-style sparseness. The rollup is a **two-step** operation, each step landing on a *typed* surface:

1. **Generic step (kind-agnostic).** Every work item, whatever its kind, is the same `Work Item` entity with Core 7 + `parent_ref` + `work_item_type`. "All work items under Milestone M" is a single `BELONGS_TO` edge traversal on the **generic** entity (the entity-model rollup chain 17) — no kind knowledge, no sparse columns.
2. **Kind-projection step (kind-aware).** Group the result set by `work_item_type` (the const discriminator each EAD schema declares), then for each group read **that kind's own EAD schema** to resolve a kind-specific field. A `bug` row reads `bug`'s schema (which has `severity`); a `story` row reads `story`'s schema (which has `story_points`). No row is ever asked for a column its kind does not declare — **no nulls-by-sparseness**.

This is a **discriminated-union / table-per-type** shape, not EAV. EAV would force one wide table with every kind's fields nullable on every row; the type-pack design keeps a thin shared base (Core 7 + rollup keys) and per-kind concrete schemas — the same shape that lets `raid-log.schema.json` be a tight typed schema rather than a generic property bag. `weekly-status-rollup` consumes exactly this: group-by-kind, one kind-specific headline per group, plus the kind-agnostic Core 7 status. The model holds — the thin-generic + table-per-type split is precisely what makes the cross-kind rollup both possible (shared base for the edge) and sparse-free (concrete per-kind schemas for the fields).

---

## 5. Propagation seam — the platform type registry

The prototyped `intake-desk` `references/type-map.md` seam (today a flat table bound to the current intake types, read at use time, with a documented forward-coupling to the work-item type system) **generalizes** into a **platform type registry**: the type-pack(s), read at invocation.

### 5.1 The per-invocation read rule

A skill consuming kinds **MAY cache for the duration of one invocation, MUST NOT cache across invocations** — inherited verbatim from the methodology Skill Consumption Pattern (kinds are project-level mutable; a promotion or a new custom kind must be seen on the next call). This is the "per-invocation, no cross-call cache" requirement, made identical to the proven methodology pattern.

### 5.2 `tracker-manager` is the single enforcement point

`tracker-manager` validates any work-item write against the kind's EAD-materialized machine-schema **before writing** — the same way it validates RAID rows against `raid-log.schema.json`. This is where a kind's `criteria` / `fields` actually bite at runtime. A validation failure follows the `entity-field-schemas.md` §7 disposition: refuse output, surface the failing rule ID + field + expected-vs-actual, route to repair — never silently default a field, drop a reference, or substitute a kind.

### 5.3 How a kind change reaches consumers with NO grammar edit

| Consumer | Couples to kinds via | What a kind change does | Grammar/SKILL edit? |
|---|---|---|---|
| `tracker-manager` | reads the registry → validates writes against the kind's EAD schema (the enforcement point) | new/changed kind ⇒ new/changed EAD schema ⇒ validation auto-applies on the next invocation | **NONE** |
| `intake-desk` | reads the registry (its `type-map.md` repointed here) for the type set + when-to-choose + landing criteria | new kind appears in the type set on the next read; the field-derivation contract derives from the kind's `fields.kind_specific[]` | **NONE** (after the one-time repoint) |
| `delivery-engine` | reads the registry for kind fields + `lifecycle_behavior`; DoR/DoD gate uses the kind's `criteria` + the project `lifecycle` | kind change ⇒ the read picks up new fields/criteria | **NONE** (after the one-time read refit) |
| `ppm-agent` | reads the registry to interpret a work-item kind when triaging/parsing | kind change ⇒ the read picks up the kind's projection + fields | **NONE** (after the one-time read refit) |
| `weekly-status-rollup` | reads the registry for the cross-kind rollup (§4) — groups/labels by `work_item_type` | a new kind appears in rollups automatically (just another `work_item_type` value under the Milestone) | **NONE** |

**Scope of the seam this document ships.** A *kind change* needing no SKILL edit is satisfied by the registry-read design above. The **one-time generalization** — teaching each reader skill to read the registry instead of its hardcoded vocabulary — is a separate propagation-refit slice of the same initiative; it is **not** in this document. This document ships the **meta-schema + the seam contract that makes that refit a no-logic-rewrite read**, plus the `intake-desk` `type-map.md` repoint (the prototyped consumer, whose own forward-coupling block already names this repoint as its target). `intake-desk`'s architectural-boundary and downstream-handoff contract (the intake-front-door boundary ADR) are unaffected — the *registry* is repointed (an implementation detail), the front-door boundary is not.

---

## 6. Versioning / grandfather

Mirrors the methodology-parameterization versioning model (data-level vs schema-level + shim), applied at two grains, plus per-kind criteria versioning.

### 6.1 Data-level — additive kind (no force-migrate)

Adding a kind to a pack, or promoting a custom kind to a best-practice default (§2.3 N=2), is a **`pack_version` minor bump**. Additive and backward-compatible: existing items of other kinds are untouched; no migration. (The data-level analog of the methodology versioning's archetype addition.)

### 6.2 Schema-level — meta-schema change (new version + shim)

A breaking change to the *meta-schema shape itself* (e.g., adding a required per-kind field, changing the `criteria` structure) ships under a **new meta-schema version with a compatibility-shim period**, exactly like the methodology-parameterization `v1 → v2` rule. This file carries the meta-schema version; a v2 ships as a new doc with a shim.

### 6.2a The pack-composition extension is additive — meta-schema version stays v1 (ADR-070)

The pack-composition layer (§1.1 `role` / `extends`, §1.1.1 `[[labels]]`, and the work-status-projection discipline — ADR-070 D1–D4) extends the meta-schema **without** a version bump. The §6.2 bump trigger is a *breaking* shape change — a **new required** field, or a `criteria`-structure change. The extension is neither: it adds optional fields (`role`, `extends`, `[[labels]]`) and *relaxes* one existing requirement (`kinds`, now role-conditional). By the two backward-compat axes:

- **`role` / `extends` / `[[labels]]` are optional ADDs** — a pack that declares none of them is byte-identical to a pre-widen pack. This is the exact shape [ADR-039](../ADRs/ADR-039-declarative-gate-conditions.md) preserved for its optional `condition` construct (absent ⇒ prior behavior), symmetric on both the data-backward and tooling-forward axes.
- **The `kinds` requiredness relaxation is grounded separately — NOT under the ADR-039 optional-ADD precedent.** A relaxation is *not* symmetric the way an optional add is: an old validator meeting an unknown optional key simply ignores it, but an old validator that assumes `kinds` present would *reject* a now-valid `role = "base"` pack. That forward-incompat is **currently theoretical**: no meta-schema validator exists yet, so the relaxation lands before any validator can be broken by it, and the first validator (built against this widened grammar) is role-aware from the start (it applies the completeness rule per `role`). The relaxation is safe because the widen ships the only validator — not because it matches ADR-039's optional-ADD symmetry.

Because both additions are backward-compatible for every existing pack (all of which declare `kinds` and no `role`), **the meta-schema version stays v1**; no shim. A pack that *adopts* the new fields takes a `pack_version` minor bump per §6.1 (the data-level additive rule), independent of the meta-schema version. The architectural decision this records is [ADR-070](../ADRs/ADR-070-methodology-pack-composition-grammar.md) (sibling to [ADR-069](../ADRs/ADR-069-methodology-pack-composing-unit.md), extending [ADR-018](../ADRs/ADR-018-work-item-type-layer.md) at grammar altitude — the same lineage move ADR-039 made).

### 6.2b The controls facet + Arm-3 body are additive — meta-schema version stays v1 (ADR-077)

The cross-cutting control layer (§1.1.2 `[[controls]]`, the §1.2.1 Arm-3 `control-field` body, the `x-pmo-control` annotation class) extends the meta-schema **without** a version bump, by the same two-axis analysis as §6.2a:

- **`[[controls]]` is an optional ADD** — a pack that declares none is byte-identical to a pre-widen pack (the ADR-039 optional-`condition` shape, symmetric on the data-backward and tooling-forward axes).
- **Specifying the Arm-3 body converts a fail-loud reserved value into a defined one** — no existing valid pack changes meaning, because a pack using `kind: control-field` before this specification FAILED pack-validation by design ("reserved, not yet implemented"); reserve-then-specify is exactly the lifecycle the slot was registered for. Validator-forward: the widen ships ahead of any meta-schema validator (the §6.2a posture holds — the first validator is controls-aware from the start).

Because both are backward-compatible for every existing pack (none declares `[[controls]]` or `kind: control-field`), **the meta-schema version stays v1**; no shim. A pack that *adopts* controls takes a `pack_version` minor bump per §6.1. The architectural decision this records is [ADR-077](../ADRs/ADR-077-cross-cutting-control-field-layer.md) — filling the slot ADR-039 reserved; extending ADR-018 at grammar altitude (the same lineage move as ADR-070).

### 6.2c The work-item-kit extension is additive in effect — meta-schema version stays v1 (ADR-177)

The work-item-kit layer (§1 kind-bearing-by-role, §1.1 `role = "kit"` / `kit_class` / the widened `extends` / the two-level `kinds` rule, §1.3 the neutral `archetype` sentinel and the `level_role` traversal carrier) extends the meta-schema **without** a version bump — the third such extension, after §6.2a and §6.2b. The architectural decision this records is [ADR-177](../ADRs/ADR-177-work-item-kit-first-class-unit.md), a grammar-altitude sibling extension of [ADR-018](../ADRs/ADR-018-work-item-type-layer.md) in the same lineage as ADR-039, ADR-070 and ADR-077.

**Three axes land, not two, and the third is the one that matters.** §6.2a and §6.2b each carried an *optional-add* axis and a *relaxation* axis. This extension carries a **restriction** as well — the one shape that can invalidate a previously-valid pack — so the analysis is stated on all three rather than folded into the two-axis form its predecessors used.

**Axis 1 — the optional ADDs. The SET is enumerated below rather than totalled**, and the reason is recorded because a count on this row was wrong once already: the population closed one wave after the count was first written, so a literal total went stale on the day it was authored while an enumeration could not. Every member is optional; a pack declaring none of them is byte-identical to a pre-change pack — the [ADR-039](../ADRs/ADR-039-declarative-gate-conditions.md) optional-`condition` shape, symmetric on the data-backward and tooling-forward axes.

| # | Add | Where |
|---|---|---|
| 1 | the `kit` member of the `role` enum | §1.1 `role` |
| 2 | the `kit_class` field, required iff `role = "kit"`, OPEN value domain | §1.1 `kit_class` |
| 3 | the `"*"` neutral sentinel in the `methodology_projection.archetype` value domain | §1.3 `archetype` |
| 4 | the `methodology_projection.level_role` field, CLOSED value domain `{execution, grouping}`, absent meaning `execution` | §1.3 `level_role` |

**Ownership within the release, stated so the enumeration is readable at any commit on the branch.** Adds 1-3 and both the relaxation and the restriction land with the grammar change; add 4 (`level_role`) lands with the level-coverage change later in the same release and on the same branch. The set is enumerated here rather than counted precisely so that this section is complete before its last member arrives — a total authored at the earlier point would have read three and stayed wrong.

The OPEN/CLOSED asymmetry between adds 2 and 4 is deliberate and is grounded in ADR-177 D6: `kit_class` names a successor set the platform expects to grow, so an unrecognized member is a gap to report and work around; `level_role` names a binary distinction internal to a rollup traversal, where silently admitting a third value would make the traversal unanalyzable rather than merely under-specified. Asserting openness where the set is closed is not generosity — it is an unenforced invariant.

**Axis 2 — the relaxation, grounded separately and NOT under the ADR-039 optional-ADD precedent.** `extends` widens from *permitted only on `role = "archetype"`* to *permitted on `role ∈ {archetype, kit}`*. A relaxation is not symmetric the way an optional add is: an old validator meeting an unknown optional key ignores it, but an old validator asserting `extends ⇒ role == "archetype"` would **reject** a now-valid kit pack. That forward-incompatibility was theoretical at the moment the relaxation was taken, and the claim is measured rather than asserted: **before this change, no tracked executable validated against this meta-schema at all** — the release's own consumer map records that enumeration in full at [`../references/reference/work-item-type-consumer-map.md`](../references/reference/work-item-type-consumer-map.md). The relaxation therefore landed before any validator could be broken by it, and the **first** such validator ships in this same change, kit-aware from the start rather than retrofitted. This is the same posture §6.2a took for the `kinds` relaxation, discharged the same way — and it is why the window in which the relaxation was free is now closed: a future relaxation of this grammar meets a live reader and must be analysed against it.

**Axis 3 — the RESTRICTION, and it is the one shape that can invalidate a previously-valid pack.** `applies_to = "*"` becomes **illegal** on `role = "archetype"` (§1.1). It is legal under the pre-change grammar: the role-conditional constraint was one-directional — a `base` pack MUST set `*` — and nothing bound archetype packs, so a neutral archetype pack validated. The restriction is taken deliberately, because leaving it out preserves a second, incoherent way to express near-neutrality: a pack claiming methodology-neutrality whose every kind still names an archetype. That is precisely the *appears-to-land-and-does-not* shape the kind-level sentinel exists to prevent, and admitting both spellings would make a validator's verdict on the capability ambiguous.

Its blast radius is bounded by measurement rather than by assertion: **0 of the 3 shipped packs** combine `role = "archetype"` with `applies_to = "*"` — the base pack is `role = "base"` (which must be `*`, and is unaffected), and the two archetype packs name `Scrum` and `Kanban`. A control arm on the same instrument locates the one legitimate `role = "base"` + `*` combination, so the zero is a measured absence rather than a dead pattern. Every shipped pack is byte-identical after this change and still validates.

**The residual is named rather than dismissed.** Type-pack *instances* are K4 user config by design (§0), so the tracked corpus is **not** the whole population: a deployment could hold an operator-local archetype pack that sets `*`. The restriction ships **with** its rule implemented rather than promised — the conformance mode that lands in this same change evaluates it, and every shipped pack passes — but the corpus it runs over here is not the population it could break. **No operator-local instance is rejected until that deployment runs the check on its own tree**, which is a choice it makes rather than one this change makes for it, and this section states the restriction axis explicitly so an adopting deployment reads it before it bites. "0 affected" means 0 affected *in the population that can be measured*, and the population that cannot be measured is named here.

**Verdict: additive in effect on shipped packs, not purely additive in grammar.** Because every shipped pack is unaffected on all three axes, **the meta-schema version stays v1**; no shim. A pack that *adopts* the new fields takes a `pack_version` minor bump per §6.1 (the data-level additive rule), independent of the meta-schema version.

### 6.3 Per-kind criteria versioning (the grandfather core)

Each kind's `criteria.{readiness,done,gate}.criteria_version` is **independent of `pack_version`**. An in-flight item records the `criteria_version` it was judged against when it passes a DoR/DoD/gate check. When a kind's criteria are revised, **already-judged items keep their judged version** (grandfathered); only items entering the gate *after* the revision use the new version. (Carrying the judged version as a small stamp on the `Work Item` instance is the natural home; whether that stamp is a first-class entity field is an entity-layer consideration, flagged not required by this grammar.) This is the version-controlled-criteria remediation for criteria drift, made concrete.

---

## 7. Failure modes (domain-specific)

Each anti-pattern below is conditional ("do NOT do X when Y, because Z"), distinct from platform-wide guardrails, tagged by category (TRIG / INPUT / PROC / OUT / HAND).

### 7.1 Kind-as-enum (HAND)

- **Signature.** A skill hardcodes a closed list of `work_item_type` values or branches `if kind == "story"`.
- **Conditional.** Do NOT treat `work_item_type` as a closed enum in any consumer, because the discriminator's value domain is an EXTERNAL, OPEN registry (ADR-018 cross-D upstream-compat); a closed enum re-traps the open set in the frozen-roster anti-pattern this layer exists to eliminate.
- **Root cause.** Convenience branching on a known kind set instead of reading the registry.
- **Mitigation.** Read the registry per invocation (§5.1); resolve fields/criteria from the kind's declaration. Route a novel kind through the custom-kind block (§2); recurrence elevates via N=2 (§2.3), operator authority only.
- **Principal vs. junior.** Principal reads the registry and treats every kind uniformly via its declaration; junior writes `if kind in {"story","bug","task"}` and ships an instant drift target.

### 7.2 Coupling the projection to a release-pipeline ticket model (PROC)

- **Signature.** `methodology_projection` (or any consumer) references a release-pipeline ticket model / issue-template as the projection target instead of the work-organization mapping framework's Layer-2 map.
- **Conditional.** Do NOT project a kind onto any release-pipeline ticket model, because that is a kernel→release-pipeline dependency inversion (ADR-018): it would let the platform's own dev tooling define the best-practice work-organization structure shipped for *any* user, and couple `core/` governance to release-pipeline dev tooling.
- **Root cause.** Mistaking the platform's own dev-tooling instance for the governed operations concept.
- **Mitigation.** Project only onto the work-organization mapping framework's Layer-2 map via `archetype` key + `level_name_ref` anchor (§1.3). Consume the framework's Layer-3 defaults; never re-author them from an issue template.
- **Principal vs. junior.** Principal keeps the operations type system self-standing and map-projected; junior wires the type-pack to whatever ticket shape the dev pipeline happens to use.

### 7.3 Re-authoring the best-practice defaults as governance (OUT)

- **Signature.** This grammar (or a "seed pack" committed to `core/`) enumerates Story/Bug/WBS-task field lists as a baked-in roster.
- **Conditional.** Do NOT bake concrete kinds into the git-tracked corpus, because **types are user config (K4)**: the package ships best-practice DEFAULTS (the framework's Layer 3, authored from methodology best practice) and supports BYO/override (the framework's Layer 4) — a "canonical seed pack" as governance both duplicates Layer 3 and re-traps user config in the kernel.
- **Root cause.** Treating the worked examples as a deliverable roster rather than as the framework's consumable defaults.
- **Mitigation.** Define the grammar here; consume Layer-3 defaults by reference (§1.4); keep declared kinds as operator-local data.
- **Principal vs. junior.** Principal ships a grammar + accepts the defaults; junior commits a 7-kind roster and creates a perpetual drift/maintenance surface.

### 7.4 Hardcoded-sprint-presumption in `lifecycle_behavior` (PROC)

- **Signature.** A kind's `lifecycle_behavior` (or a consumer reading it) assumes `sprint`/`phase` semantics from the kind rather than the project's `lifecycle`.
- **Conditional.** Do NOT encode cadence/gate behavior on the kind, because behavior must key off the *project's* `lifecycle` (`{timeboxed, continuous, phased}` from `delivery_approach` / `custom_methodology_definition`); a kind that carries sprint semantics breaks on a continuous-flow or phased project.
- **Root cause.** Conflating *what gates a kind has* with *which gates the project fires*.
- **Mitigation.** A kind declares the gate set in `criteria.gate`; `lifecycle_behavior` selects which fire by the project `lifecycle` key (§1.2). Default to the project lifecycle, never the kind.
- **Principal vs. junior.** Principal keys behavior off the project lifecycle; junior assumes sprints and silently misfires on Waterfall/Kanban.

### 7.5 Test-kind vs. test-artifact (do not collapse the layers)

A `test` **kind** is a Work Item — a tracked unit of work (the const `base` Work Item entity, distinguished by `work_item_type: test`). A test **deliverable** — a test plan, a test case, a test suite — is the **Artifact** entity, a different layer and a different record. The two relate via the `GENERATES` MVP edge (the work item generates the artifact), not by being the same row. Do NOT model a test plan or test case as a `work_item_type`, and do NOT fold a `test` work item into the Artifact entity: collapsing the two erases the work-vs-deliverable distinction the entity model draws and breaks the cross-kind rollup (§4), which keys on `work_item_type` over Work Item records only.

### 7.6 Gating cycle in relationship-conditioned / set-aggregate gates (PROC)

- **Signature.** Two `condition`'d gate checks (§1.2.1) form a mutual wait: a `related-item-status` standoff (A's gate reads B's status while B's gate reads A's status), or a `set-aggregate` mutual two-set / `limit_ref` cycle (set A's pull is gated on set B while B's is gated on A).
- **Conditional.** Do NOT let a pack ship a gating cycle, because each gate then waits on the other forever — a deadlock that either freezes both transitions or, if silently broken, lets one item advance on a gate meant to hold (defeating the gate).
- **Root cause.** Authoring two transition gates that each condition on the other's outcome, with no terminating state.
- **Mitigation — detect-and-refuse, enforced at the existing single enforcement point (`tracker-manager`; no new enforcer):**
  1. **Static gating-graph cycle detection (pack-validation — the primary defense).** At registry-load (§5.1/§5.2) build a directed gating graph: nodes = `(kind, transition)` pairs; a `related-item-status` check contributes an edge from its `guards_transition` to the `(target-kind, transition)` that moves the target into a `target_status_in` state; a `set-aggregate` check contributes an edge from its `guards_transition` to the transitions that move items INTO its `status_filter` set. Run DFS back-edge / topological-sort-failure detection. **A detected cycle is REFUSED** — the pack fails validation with the offending cycle path named (mirrors §5's "a pack naming a relationship type outside the 7 is invalid" posture) (a `control-field` check contributes **no** edge — a control value is item/container data written by an ordinary field write, not an axis1 state produced by a guarded transition, so there is no transition node for the graph to point at).
  2. **Two special cases.** The **set-aggregate convergent self-edge is EXEMPT** — a WIP gate that guards the same transition that fills its own set is *self-limiting* (it converges to ≤ limit and stops admitting), not a deadlock; the detector special-cases a node whose only "cycle" is its own fill-transition as converging, not refusable. **Mutual cycles are REFUSED** — two *different* transitions in a mutual wait (the A↔B status standoff or the two-set / `limit_ref` aggregate cycle) are named-and-refused.
  3. **Runtime cut (write/transition time — the backstop).** `tracker-manager` evaluates the condition at transition time; `on_unresolved: BLOCK-TRANSITION` fires when the target/set/scope can't be resolved (deleted related item, missing board entity, a manual-edit standoff the static graph couldn't see at instance level). Two bounds prevent unbounded runtime evaluation: a **traversal-depth cap** on edge-following (status arm) and a **set-cardinality bound** (aggregate arm — refuse to evaluate a pathologically large/unbounded scope rather than enumerate unboundedly).
  4. **Refuse, not auto-break.** A genuine mutual cycle is an operator-resolvable modeling error (remove one gate) — refuse-and-name routes the decision to the operator (Tier 1), consistent with `entity-field-schemas.md` §7 ("never silently default a field, drop a reference, or substitute a kind").
- **Principal vs. junior.** Principal builds the gating graph at pack-load, exempts the convergent WIP self-edge, refuses-and-names a true mutual cycle, and bounds runtime traversal; junior ships two mutually-conditioned gates and discovers the deadlock when both items freeze in production.

---

## 8. Cross-References

This document **consumes** these sources by pointer (duplicate-source-discipline — substrates are named and linked, never re-defined here). All links are intra-`core/`; this document declares **no dependency on any release-pipeline file** — pattern precedents (the `custom_methodology_definition` protocol, the EAD mechanism) are referenced **by name**.

| Reference | Role relative to this document |
|---|---|
| [`../disciplines/work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md) | **The projection target.** Layer 1 = the per-level-purpose taxonomy a kind's `general_level` resolves to; Layer 2 = the hierarchy-by-methodology map a kind projects onto (`methodology_projection`); Layer 3 = the best-practice default schemas this grammar consumes/accepts; Layer 4 = the K4 plug-and-play override model. **Upstream of this document.** |
| [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md) | The FROZEN entity substrate — §18 the thin generic `Work Item` entity (the const `base`), the Core 7, the `work_item_type` discriminator, the polymorphic `parent_ref`, the rollup chain 17. Chain 17's `BELONGS_TO` rollup traversal is **also the set-aggregate enumeration substrate** (§1.2.1 / §3.1a — the set-aggregate gate applies a comparator to this existing traversal, inventing no new physicalization). Cited; never restated. |
| [`entity-field-schemas.md`](entity-field-schemas.md) | §3.18 the `Work Item` field schema + V-WI-01..06 + the Axis-1 base machine; §3.0 the inherited Core 7 + the `FieldDecl` row shape this grammar reuses; §7 the validation-failure disposition `tracker-manager` applies. |
| [`../standards/entity-lifecycle-protocol.md`](../standards/entity-lifecycle-protocol.md) | §3.10 the transcribed `Work Item` Axis-1 base machine — one row per transition carrying the **triggering agent** and the **qualifying evidence**, plus the forbidden-transition set. The §1.2.2 unconfigured path **delegates** its maintenance obligation there rather than restating it; this document authors no actor and no trigger of its own. A frozen transcription — changing it is a Tier-2 scope change against its establishing issue, not an edit this grammar may make. |
| [`../ADRs/ADR-018-work-item-type-layer.md`](../ADRs/ADR-018-work-item-type-layer.md) | The establishing decision — D1 hybrid (thin entity + this declarative layer), D2 methodology-projected (project onto the general hierarchy via the work-organization mapping framework, not a release-pipeline tool), D4 Tier-2. This grammar is the D1/D2 implementation; it opens no competing ADR. |
| [`../ADRs/ADR-069-methodology-pack-composing-unit.md`](../ADRs/ADR-069-methodology-pack-composing-unit.md) | The founding decision that the methodology pack is the plug-and-play composing unit (placement `core/packs/<archetype>/`, `pack.toml` manifest, selection). The `role`/`extends` composition (§1.1) is the grammar those manifests conform to. |
| [`../ADRs/ADR-070-methodology-pack-composition-grammar.md`](../ADRs/ADR-070-methodology-pack-composition-grammar.md) | The grammar-altitude sibling of ADR-069 that this widen implements — D1 pack `role`/`extends` (§1.1), D2 the `[[labels]]` contribution facet (§1.1.1), D3 the work-status projection over the entity base, D4 the role-conditional `kinds` relaxation. Additive extension of ADR-018 (the ADR-039 lineage); grounds why the meta-schema version stays v1 (§6.2a). |
| [`../ADRs/ADR-077-cross-cutting-control-field-layer.md`](../ADRs/ADR-077-cross-cutting-control-field-layer.md) | The grammar-altitude decision for the cross-cutting control layer — the §1.1.2 `[[controls]]` facet (shared pack-level declaration over per-kind repetition), the §1.2.1 Arm-3 body (`scope: self` v1 + reserved container scopes), the `x-pmo-control` class, and the value→gate/filter coupling contract. Fills the slot ADR-039 reserved; extends ADR-018 in the ADR-039/ADR-070 lineage; grounds §6.2b. |
| [`../specs/label-taxonomy.md`](../specs/label-taxonomy.md) | The label-group grammar the `[[labels]]` facet (§1.1.1) contributes *into* — it owns the group set (`category` / `status` / `work-status` / `cluster` / `initiative` / `triage-flag` / `disposition`) + the rules; a pack only populates the rows. The contract direction (grammar defines groups; packs populate) is the guardrail against label drift. |
| [`frontmatter-schema.md`](frontmatter-schema.md) | §Category 4 — the built 7 MVP relationship types `relationships.allowed_types[]` references (no new vocabulary). |
| [`raid-log.schema.json`](raid-log.schema.json) | The EAD precedent — the entity→artifact machine-schema DERIVED (not hand-authored) via the 7-class `x-pmo-class` crosswalk + `x-pmo-*` annotations + `x-pmo-negative-tests`; the exact mechanism §3 generalizes. |
| [`tracker-schemas.md`](tracker-schemas.md) | The EAD note (the generalized Entity→Artifact-Schema Derivation contract) + `tracker-manager`'s schema-validation enforcement role (§5.2). |
| [`../specs/terminology-glossary.md`](../specs/terminology-glossary.md) | `Work Item` canonical; Story / Epic / Feature / Work-Package are non-canonical projections (Appendix B) — why vernacular lives in `display_name` / `projects_as`, never `kind_id`. |
| [`../disciplines/knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | The K1 (this grammar + the framework's Layers 1–3) vs K4 (declared kinds, the framework's Layer 4) split + the parameterization seam the override model instantiates. |
| The `custom_methodology_definition` Custom Extension Protocol + Skill Consumption Pattern | Referenced **by name** — the CASE 1/2/3 consumption, the N=2-within-180-days governance-promotion, and the data-level/schema-level versioning model this document mirrors by pattern for kinds. |
