<!-- reference-durability: allow-link -->
# Work-Item Type-Pack Meta-Schema

**Status:** Canonical
**Meta-schema version:** v1
**Owner:** `../schemas/work-item-type-schema.md`
**Layer:** 1 (Engineering, git-tracked)
**Type:** schema-spec doc (the K1 *grammar*; type-pack *instances* are K4 user config)
**Derivation source (FROZEN):** [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md) §18 (the thin generic `Work Item` entity) + [`entity-field-schemas.md`](entity-field-schemas.md) §3.18 (its field schema + V-rules) + §3.0 (the inherited Core 7 + the `FieldDecl` row shape).
**Projection target:** [`../disciplines/work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md) — Layer 2 (the hierarchy-by-methodology map a declared kind projects through) and Layer 3 (the best-practice default schemas this grammar *consumes/accepts*, never re-authors).
**Architectural basis:** [`../ADRs/ADR-018-work-item-type-layer.md`](../ADRs/ADR-018-work-item-type-layer.md) (D1 hybrid — thin generic entity + declarative type layer; D2 methodology-projected; D4 Tier-2 scope change).
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

A **type-pack** is a document with two levels: a **pack header** and one or more **per-kind declarations**.

### 1.1 Pack header

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `pack_id` | string (slug) | ✅ | Lowercase-kebab, unique within a deployment. |
| `pack_version` | string (semver) | ✅ | The pack's version. §6 governs the bump rule (additive kind = minor; meta-schema-shape change = a new meta-schema version + shim). |
| `applies_to` | string | ✅ | A `delivery_approach` archetype name (the byte-identical, case-sensitive set `Scrum` `Kanban` `XP` `Waterfall` `PRINCE2` `SAFe` `Hybrid` `Custom`) **OR** `*` for a methodology-neutral pack. This is the join key into the work-organization mapping framework's Layer-2 row. |
| `kinds` | array&lt;Kind&gt; | ✅ | One `Kind` object per declared work-item kind (the per-kind meta-schema in §1.2). |

### 1.2 Per-kind meta-schema (exact fields, types, requiredness)

Each entry in `kinds[]` is a `Kind` object with exactly these fields:

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `kind_id` | string (slug) | ✅ | Lowercase-kebab, unique within the pack. The value that lands in the entity's `work_item_type` discriminator (`entity-field-schemas.md` §3.18). Matches the Core `id` slug rule (V-CORE-01). **Not** a display name. |
| `display_name` | string | ✅ | Human label (e.g., `"User Story"`). Free-form. **This is the only home for methodology vernacular** — Story / Epic / Feature / Work-Package are non-canonical projections per the glossary Appendix B, so they live here, never in `kind_id`. |
| `base` | const `Work Item` | ✅ | Every kind IS the canonical `Work Item` entity (§18). No other base permitted — this is what keeps a kind a *projection*, not a new entity (D2; the ADR-018 rejected alternative (B) "don't add an entity per kind"). |
| `methodology_projection` | object | ✅ | The projection record. **Projects onto the general hierarchy via the work-organization mapping framework's Layer-2 map** (see §1.3). Fields: `archetype`, `general_level`, `projects_as`, `level_name_ref`. |
| `fields` | object | ✅ | The field overlay. Two sub-keys: `core` (a const reference to the inherited Core 7 — never re-listed, per the `entity-field-schemas.md` §3.0 house style) and `kind_specific[]` (the array below). |
| `fields.kind_specific[]` | array&lt;FieldDecl&gt; | ⚪ | Each `FieldDecl` reuses the §3.N row shape **verbatim**: `{ name, type, required (✅/⚪), cardinality, enum? (enum type), ref? (target entity for typed-ref), description }`. Empty array = a kind with no fields beyond Core 7 (valid — the thin-generic floor). |
| `criteria` | object | ✅ | Three keyed sub-objects: `readiness` (DoR), `done` (DoD), `gate` (phase/stage gate). Each = `{ criteria_version (semver), checks[] }`, where each check = `{ id, statement, level (L1 structural / L2 referential / L3 judgment), automatable (bool) }`. **The criteria carry their own version**, independent of `pack_version` — the grandfather hook (§6.3). |
| `relationships` | object | ✅ | `allowed_types[]` — a subset of the **7 MVP relationship types by reference** (`frontmatter-schema.md` §Category 4: `GENERATES` / `DEPENDS_ON` / `BLOCKS` / `SUPERSEDES` / `BELONGS_TO` / `RELATES_TO` / `ASSIGNED_TO`). Plus `required_edges[]` (e.g., a kind MAY require a `BELONGS_TO` parent). **No type is defined here** — only referenced + constrained. A pack naming a relationship type outside the 7 is invalid (§5 enforcement). |
| `lifecycle_behavior` | object | ✅ | The behavior map keyed off the **project's** `lifecycle` value (`{timeboxed, continuous, phased}` — read from `delivery_approach` / `custom_methodology_definition`, **NOT** from the kind). Value = the behavior selection (which `criteria.gate` set applies, which cadence primitive). **The explicit defense against the hardcoded-sprint-presumption failure mode:** a kind declares *what gates exist*; the project's lifecycle selects *which fire*. The kind never carries `sprint`/`phase` semantics directly. |
| `axis1_state_machine` | ref OR inline | ✅ | The kind's operational lifecycle (Axis-1). **Default = inherit the generic `Work Item` Axis-1 base machine** `backlog → ready → in-progress → in-review → done | cancelled`, owned by the entity layer (ADR-018 D1; `entity-field-schemas.md` §3.18 V-WI-04). A kind declares this field as `inherit` unless it genuinely **narrows or extends** the generic states, in which case it declares the refinement inline (a type-scoped sub-state per D1 — type-packs project labels over the base, they never re-found it). |
| `materialization` | object | ⚪ | EAD directives (§3): `{ schema_id (the output machine-schema $id), enforcement_mode (canonical-enforce / dialect-enforce), crosswalk_overrides[]? }`. When omitted, EAD derives a `canonical-enforce` schema mechanically from `fields` (the default path — §3). |

### 1.3 `methodology_projection` — projects onto the Layer-2 map

The `methodology_projection` object is the seam to the **work-organization mapping framework**. It projects a kind onto the **general hierarchy** through that framework's Layer-2 hierarchy-by-methodology map — the domain-neutral methodology→hierarchy map — **never** onto any release-pipeline ticket model (the ADR-018 kernel discipline: `core/` must not depend on release-pipeline dev tooling).

| Field | Type | Req | Constraint / Semantics |
|---|---|---|---|
| `archetype` | string | ✅ | One of the 8 `delivery_approach` archetype names, **OR** `Custom`. The byte-identical join key into the work-organization mapping framework's Layer-2 row for that archetype (and the same key the methodology corpus uses). |
| `general_level` | enum | ✅ | The general hierarchy level the kind occupies, from the framework's Layer-1 per-level-purpose taxonomy: `{Portfolio, Program, Project, Milestone/Workstream, Work Item}`. For a work-item *kind* this is almost always `Work Item` (the finest level) — the framework's Layer-2 invariant is that every methodology's finest execution unit lands on the single `Work Item` level. A kind that resolves elsewhere is a modeling smell to flag. |
| `projects_as` | string | ✅ | The methodology-native level name this kind surfaces as (e.g., Scrum → `Story`, Waterfall → `WBS leaf`). A display projection — equals `display_name` for the common case; distinct only when the pack wants the map-name and the UI-name to differ. |
| `level_name_ref` | string (anchor) | ⚪ | An anchor into the work-organization mapping framework's Layer-2 mapping facet for `archetype` (e.g., the Scrum or Waterfall map section), naming the row whose level mapping this kind inherits. `derive` for `archetype: Custom` (resolve via the custom block's `base_archetype` per §2 / the framework's Layer-4 by-nature procedure). |

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
4. **Each `fields.kind_specific[]` FieldDecl → one property**, classified by the **7-class `x-pmo-class` column crosswalk** observed in `raid-log.schema.json`: `exact-map` · `rename-map` · `type-lift` · `dialect-projection` (with `x-pmo-canonical-enum` + `x-pmo-legacy-crosswalk` when a value set projects to a legacy/display set) · plus the `x-pmo-referential`, `x-pmo-temporal`, and `allOf` conditional-required annotations for L2/L3.
5. **Each `criteria.checks[]` projects by level:** `automatable: true` ∧ `level: L1` → a schema-expressible constraint (enum / pattern / required); `level: L2` → an `x-pmo-referential` entry; `level: L3` → an `x-pmo-criteria-judgment` annotation (recorded so a reviewer/skill can surface it, not machine-enforced).
6. **Negative tests generated 1:1 from the rules** (the `entity-field-schemas.md` §3.0b pattern + the `x-pmo-negative-tests` array `raid-log.schema.json` carries): each L1 enum → one out-of-enum NT; each L2 ref → one unresolvable-id NT. **A materialized kind ships ≥2 negative tests.**

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

---

## 8. Cross-References

This document **consumes** these sources by pointer (duplicate-source-discipline — substrates are named and linked, never re-defined here). All links are intra-`core/`; this document declares **no dependency on any release-pipeline file** — pattern precedents (the `custom_methodology_definition` protocol, the EAD mechanism) are referenced **by name**.

| Reference | Role relative to this document |
|---|---|
| [`../disciplines/work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md) | **The projection target.** Layer 1 = the per-level-purpose taxonomy a kind's `general_level` resolves to; Layer 2 = the hierarchy-by-methodology map a kind projects onto (`methodology_projection`); Layer 3 = the best-practice default schemas this grammar consumes/accepts; Layer 4 = the K4 plug-and-play override model. **Upstream of this document.** |
| [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md) | The FROZEN entity substrate — §18 the thin generic `Work Item` entity (the const `base`), the Core 7, the `work_item_type` discriminator, the polymorphic `parent_ref`, the rollup chain 17. Cited; never restated. |
| [`entity-field-schemas.md`](entity-field-schemas.md) | §3.18 the `Work Item` field schema + V-WI-01..06 + the Axis-1 base machine; §3.0 the inherited Core 7 + the `FieldDecl` row shape this grammar reuses; §7 the validation-failure disposition `tracker-manager` applies. |
| [`../ADRs/ADR-018-work-item-type-layer.md`](../ADRs/ADR-018-work-item-type-layer.md) | The establishing decision — D1 hybrid (thin entity + this declarative layer), D2 methodology-projected (project onto the general hierarchy via the work-organization mapping framework, not a release-pipeline tool), D4 Tier-2. This grammar is the D1/D2 implementation; it opens no competing ADR. |
| [`frontmatter-schema.md`](frontmatter-schema.md) | §Category 4 — the built 7 MVP relationship types `relationships.allowed_types[]` references (no new vocabulary). |
| [`raid-log.schema.json`](raid-log.schema.json) | The EAD precedent — the entity→artifact machine-schema DERIVED (not hand-authored) via the 7-class `x-pmo-class` crosswalk + `x-pmo-*` annotations + `x-pmo-negative-tests`; the exact mechanism §3 generalizes. |
| [`tracker-schemas.md`](tracker-schemas.md) | The EAD note (the generalized Entity→Artifact-Schema Derivation contract) + `tracker-manager`'s schema-validation enforcement role (§5.2). |
| [`../specs/terminology-glossary.md`](../specs/terminology-glossary.md) | `Work Item` canonical; Story / Epic / Feature / Work-Package are non-canonical projections (Appendix B) — why vernacular lives in `display_name` / `projects_as`, never `kind_id`. |
| [`../disciplines/knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | The K1 (this grammar + the framework's Layers 1–3) vs K4 (declared kinds, the framework's Layer 4) split + the parameterization seam the override model instantiates. |
| The `custom_methodology_definition` Custom Extension Protocol + Skill Consumption Pattern | Referenced **by name** — the CASE 1/2/3 consumption, the N=2-within-180-days governance-promotion, and the data-level/schema-level versioning model this document mirrors by pattern for kinds. |
