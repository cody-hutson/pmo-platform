---
title: PROJECT.md Schema
purpose: The canonical schema for PROJECT.md — the fields a project context file carries, consumed by the PROJECT.md-reading skills and the Methodology Awareness Protocol.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the PROJECT.md-reading skills (the §8 consumer table); OPERATIONS.md §Methodology Awareness Protocol; project-initiator; the role-skill wave
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
# PROJECT.md Schema

**Status:** Canonical
**Owner:** `../schemas/project-schema.md`
**Introduced:** methodology-parameterization-core (2026-04-24)
**Consumers:** the PROJECT.md-reading skills enumerated in the [§8 consumer table](#8-consumers) + `OPERATIONS.md § Methodology Awareness Protocol` + the future role-skill wave
**Cross-references:**

- [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) — 8 archetype normative definitions + Custom Extension Protocol + Skill Consumption Pattern
- [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md) — per-archetype variation table (lifecycle / ceremonies / artifacts / cadence / consumers / sample-types / distinguishing-constraint)
- [`terminology-glossary.md`](../specs/terminology-glossary.md) — canonical definitions of Process / Methodology / Framework and adjacent terms (owned by )
- [`OPERATIONS.md § Methodology Awareness Protocol`](../governance/OPERATIONS.md) — skill consumption rule

---

## 1. Purpose

`PROJECT.md` is the per-project source of truth — the operational-state file that every PMO skill consulting a project reads at invocation. This schema is the canonical specification of its frontmatter shape: what fields exist, what values they take, and how consumer skills interpret them. It replaces tribal knowledge and per-skill ad-hoc parsing with a single authoritative reference.

The schema is **methodology-aware**. Prior to this release, a co-management boolean was the only explicit methodology signal, and skills that needed to vary behavior by delivery approach did so via ad-hoc inference. The new `delivery_approach` enum + conditional `custom_methodology_definition` block (introduced by the methodology-parameterization keystone) give skills an authoritative methodology classification to parameterize against — eliminating the implicit "sprint-centric Agile" default that was load-bearing in 12 of 13 project-reading skills.

## 2. Scope

**In scope.** All fields in the `PROJECT.md` frontmatter YAML block. Values, types, presence rules, and the reconciliation rules between legacy and new fields. The additions — `delivery_approach` and `custom_methodology_definition` — with full validation rules (V1-V15) and worked examples.

**Out of scope.** Per-skill consumption rules (those live in each skill's own output-contract and in `methodology-parameterization-v1.md § Skill Consumption Pattern`). The matrix of per-archetype variation columns (lifecycle / ceremonies / artifacts / cadence) lives in `methodology-archetype-matrix.md`. Canonical term definitions for Process / Methodology / Framework live in `terminology-glossary.md`.

## 3. Root Schema

Canonical YAML frontmatter shape. Fields are listed in canonical order — Engineering authoring of new `PROJECT.md` files and the `project-initiator` skill SHOULD follow this order for consistency.

```yaml
---
# Identity
project_name: string                       # REQUIRED — display name
project_owner: ref→Person.person_id        # REQUIRED* — accountable owner, resolves to a roster Person (ADR-040)
project_owner_external: string             # OPTIONAL — owner NOT in the roster; *exactly one of {project_owner, project_owner_external}
status: ACTIVE | CLOSING | CLOSED          # REQUIRED — lifecycle state (per CLAUDE.md Project Lifecycle)

# Dual-framing co-management trigger (decoupled from delivery_approach — orthogonal)
dual_framing_enabled: bool                 # OPTIONAL — true triggers dual Agile/Waterfall co-management framing (OPERATIONS.md § Dual-Framing Bridge). See §7 Migration Notes.

# Methodology classification — NEW
delivery_approach: Scrum | Kanban | XP | Waterfall | PRINCE2 | SAFe | Hybrid | Custom
                                           # REQUIRED — top-level methodology archetype

# Conditionally required — present iff delivery_approach: Custom
custom_methodology_definition:
  name: string                             # REQUIRED — display name (e.g., "Scrumban")
  base_archetype: <one-of-8> | null        # REQUIRED — closest archetype, or null for genuinely novel
  derived_from: [<archetype-name>, ...]    # REQUIRED — fusion list (may be empty [])
  lifecycle: continuous | phased | timeboxed
                                           # REQUIRED — core cadence pattern
  ceremonies: [string, ...]                # REQUIRED — non-empty list of named sync events
  artifacts: [string, ...]                 # REQUIRED — non-empty list of work-products
  cadence: string                          # REQUIRED — free-form cadence description
  notes: string                            # OPTIONAL — rationale + known trade-offs

# Deliverable-domain axis — NEW (keystone) — orthogonal to delivery_approach
deliverable_type: software | governance | web | data | enterprise-platform | hardware | process | <lowercase-kebab>
                                           # OPTIONAL on legacy, REQUIRED forward — the kind of work the
                                           # project delivers (what), orthogonal to delivery_approach (how it is governed).
                                           # OPEN enum: a recognized class OR a non-empty lowercase-kebab string
                                           # (mirrors delivery_approach: Custom openness). Authoritative source the
                                           # Stage-4 `domain:` label reads where present (stage-04-planning.md).

# Organizational structure — NEW
org_structure_type: functional | matrix_weak | matrix_balanced | matrix_strong | projectized | virtual | hybrid | Custom
                                           # OPTIONAL — PMBOK org-structure shape; default `functional` when absent.
                                           # Closed enum + `Custom` escape (mirrors delivery_approach). Drives portfolio org-shape rollups.

# Project team roster — NEW; the project-altitude INDEX into the people-graph (ADR-040 owner-ref pattern)
team_roster:                               # OPTIONAL — list of {person_ref, role_on_project}; REFS ONLY, no inline PII
  - person_ref: ref→Person.person_id       # REQUIRED per entry — resolves to a roster Person (compose, never copy)
    role_on_project: string                # REQUIRED per entry — the person's role ON THIS project
  # ... one entry per team member ...

# Other per-project fields (per existing skill conventions — not introduced by )
# ... e.g., stakeholder roster, go-live date, systems, governance model, Dual-Framing Bridge section trigger ...
---
```

Field presence rules summary:

| Field | Required | Conditional |
|---|---|---|
| `project_name` | ✅ Always | — |
| `project_owner` | ✅ Exactly-one-of† | †one of {`project_owner` ref→Person, `project_owner_external`} per ADR-040 |
| `project_owner_external` | ⚪ Conditional | populated iff the owner is not in the roster; mutually exclusive with `project_owner` |
| `status` | ✅ Always | — |
| `dual_framing_enabled` | ⚪ Optional | — |
| `delivery_approach` | ✅ Always | — (new) |
| `custom_methodology_definition` | Conditional | ✅ iff `delivery_approach: Custom`; ❌ otherwise |
| `deliverable_type` | ⚪ Optional (legacy) / ✅ Required (forward) | open enum: recognized class OR non-empty lowercase-kebab; additive on legacy files |
| `org_structure_type` | ⚪ Optional | default `functional` when absent (new) |
| `team_roster` | ⚪ Optional | when present, every entry is `{person_ref → Person.person_id, role_on_project}`; refs only (new) |

## 4. Field Reference

One subsection per field. Values, semantics, and consumer expectations. Evidence labels: `[SOURCE]` indicates the authoring file or grep result; `[INFERRED]` indicates derivation from observed skill behavior.

### `project_name`

Free-form string. Used in status output headers, artifact titles, and cross-project reports. Convention: title-case; match the project folder name under `projects/` when possible. `[SOURCE]` — `operations/skills/project-initiator/SKILL.md` (governs PROJECT.md scaffolding).

### `project_owner` / `project_owner_external`

Primary accountable owner. **Type-lifted per ADR-040** (functional-people-graph, Tier-2) from a free-text string to a typed reference: `project_owner` is a `ref→Person.person_id` resolving to a roster Person, unifying the leadership-owner axis on the `person_id` anchor. For an owner NOT in the people roster (an external client/vendor contact), use the optional `project_owner_external` free-text field instead — e.g. `project_owner_external: [EXTERNAL_OWNER_NAME]`. **Exactly one** of {`project_owner`, `project_owner_external`} is populated — the L1 mutual-exclusion invariant (both-populated, or neither, is malformed; this preserves the original required-owner guarantee). On-unresolved: a populated `project_owner` ref that does not resolve → BLOCK-WRITE; a populated `project_owner_external` → WARN-HEALTH (X-30). **Migration:** an existing free-text owner name resolves-by-name against the roster — a unique match becomes the ref; zero or ambiguous (≥2) matches route to the operator clarification queue, never silently dropped. The worked examples below that show an owner as a name illustrate this pre-migration free-text resolving to a `person_id` ref. Used in routing, status output, and escalation chains. `[SOURCE]` — observed convention across all projects under `projects/`; type-lifted per ADR-040.

### `status`

Enum: `ACTIVE` | `CLOSING` | `CLOSED`. Lifecycle state per `CLAUDE.md § Project Lifecycle`. `ACTIVE` projects receive full processing; `CLOSING` projects receive reduced cadence (hypercare); `CLOSED` projects are read-only reference. Skills MUST check `status` before processing and short-circuit accordingly. `[SOURCE]` — `CLAUDE.md § Project Lifecycle`.

### `dual_framing_enabled`

Boolean. When `true`, activates the **Dual-Framing Bridge** — dual Agile/Waterfall co-management framing across outputs from `ppm-agent`, `delivery-engine`, `daily-status`, `weekly-status-rollup`. `[SOURCE]` — `OPERATIONS.md § Dual-Framing Bridge (Conditional)`.

This field is the dual-framing co-management trigger, **orthogonal** to `delivery_approach`: it is **NOT implied by, and does not imply, `delivery_approach: Hybrid`** — see §7 Collision Check for reconciliation rules. The trigger is the operational co-management dual-framing capability; `Hybrid` (and the `[A, B]` array form) is a methodology classification — the two combine freely.

**Renamed field.** The dual-framing trigger was renamed to `dual_framing_enabled`; the legacy key it replaced was **retired in v2.19** and is no longer accepted on read. See §7 Migration Notes for the rename and the one-line migration.

### `delivery_approach`

Required. Enum — one of 8 values (title-case, case-sensitive):

| Value | Meaning |
|---|---|
| `Scrum` | Iterative timeboxed; sprint commitment protected |
| `Kanban` | Continuous-flow with WIP limits |
| `XP` | Iteration-based + engineering practices as governance |
| `Waterfall` | Sequential phased with gate-based change control |
| `PRINCE2` | Stage-based project governance framework |
| `SAFe` | Multi-team Agile at PI cadence (Essential 5.0+) |
| `Hybrid` | User-configurable two-archetype combination `[A, B]` reported in both native framings (co-management is orthogonal — see `dual_framing_enabled`, § 7) |
| `Custom` | Escape hatch — requires `custom_methodology_definition` block |

Full normative definitions (3-5 sentences per archetype) live in [`methodology-parameterization-v1.md § Definitions`](../../release/references/specs/methodology-parameterization-v1.md). Variation table (lifecycle / ceremonies / artifacts / cadence / consumers / sample-types / distinguishing-constraint) lives in [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md).

Consumer skills read this field at invocation and parameterize their behavior per [`OPERATIONS.md § Methodology Awareness Protocol`](../governance/OPERATIONS.md) Rules 1-3.

### `custom_methodology_definition`

Block. Present iff `delivery_approach: Custom`; absent or null otherwise (per V4). Typed escape-hatch carrying full methodology specification. Consumer skills use this block as the authoritative methodology description when `delivery_approach: Custom` — no implicit archetype inference.

Sub-fields:

#### `custom_methodology_definition.name`

Required. Non-empty free-form string. The display name of the custom variant (e.g., `"Scrumban"`, `"Shape Up"`, `"Scrum-no-estimation"`). Used in status output and artifact titles.

#### `custom_methodology_definition.base_archetype`

Required. Either one of the 8 enum values OR the YAML `null` literal. Names the archetype the custom variant most closely resembles. `null` is an **explicit signal** the variant is genuinely novel — skills MUST NOT silently default to any archetype when `base_archetype` is `null` (see §5 V6; see `methodology-parameterization-v1.md § Skill Consumption Pattern` 3-branch logic).

#### `custom_methodology_definition.derived_from`

Required. List of archetype enum values. May be empty `[]` (typically paired with `base_archetype: null`). Each member must be one of the 8 enum values. Documents the fusion lineage of the variant — e.g., Scrumban might have `derived_from: [Kanban, Scrum]`.

#### `custom_methodology_definition.lifecycle`

Required. Enum: `continuous` | `phased` | `timeboxed`. The core cadence pattern:

- `continuous` — flow-pull; no time boundaries on work cycles (Kanban-family).
- `phased` — gate-sequential; each phase completes before next begins (Waterfall-family).
- `timeboxed` — iteration-bounded; work happens in fixed-length boxes (Scrum/XP-family).

Skills key their primitives off this field — WIP/throughput for `continuous`, phase-gate progress for `phased`, velocity/sprint-goal for `timeboxed`.

#### `custom_methodology_definition.ceremonies`

Required. Non-empty list of strings. Named recurring synchronization events (e.g., `"daily standup"`, `"sprint retro"`, `"end-stage review"`, `"betting table"`). Skills recognize these as sync points for status aggregation and decision cadence.

#### `custom_methodology_definition.artifacts`

Required. Non-empty list of strings. Named work-product or tracking artifacts (e.g., `"product backlog"`, `"kanban board"`, `"stage plan"`, `"pitch"`). Skills expect these as inputs/outputs and use them to orient documentation generation.

#### `custom_methodology_definition.cadence`

Required. Non-empty free-form string describing the cadence (e.g., `"2-week sprints"`, `"continuous flow with weekly replenishment"`, `"6-week cycle + 2-week cooldown"`). Informs scheduling defaults in consumer skills.

#### `custom_methodology_definition.notes`

Optional. Free-form string. Rationale, known trade-offs, governance-promotion candidacy notes. Consumed as methodology-context hint by verbose-mode skill outputs.

### `deliverable_type`

Optional on legacy files, **required forward**. Names the **deliverable domain** — *what kind of work the project delivers* (a website build, an ERP customization, a code-review engagement, a governance corpus). **Open enum**, shape-validated (not a closed set): a recognized class — `software` | `governance` | `web` | `data` | `enterprise-platform` | `hardware` | `process` — OR a non-empty lowercase-kebab string for a domain not yet recognized, exactly mirroring `delivery_approach: Custom` openness. An unrecognized-but-well-formed value is itself the demand signal for authoring a domain guide (`core/standards/domain-best-practices/<x>.md`), per the Stage-4 expansion rule.

**Orthogonal to `delivery_approach`.** `deliverable_type` is *what is built*; `delivery_approach` is *how it is governed*. A `deliverable_type: software` project may run `delivery_approach: Scrum`, `Waterfall`, or any archetype — the axes combine freely. They are not redundant and neither implies the other.

**Authoritative source for the Stage-4 `domain:` label.** Where present, this field is the authoritative source the Stage-4 Planning `domain:` class field reads (`release/references/pipeline/stage-04-planning.md` § 5.7 — the field that field's forward-reference anticipated). Consumer skills and gate criteria branch on `deliverable_type` → the matching domain guide via the §5A Domain-Axis Consumption Pattern in [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md). `[SOURCE]` — `stage-04-planning.md` `domain:` forward-reference; the shipped intake-side domain representation consumes this enum.

#### Disambiguation — `deliverable_type` vs. the other `domain`-named concepts

The bare word `domain` is overloaded across the platform; `deliverable_type` is the deliberately **non-colliding** name for the deliverable-domain axis. This note fixes the boundaries once (modeled on the §7 `dual_framing_enabled`-vs-`delivery_approach` Collision Check):

| Concept | What it is | Where it lives | Relation to `deliverable_type` |
|---|---|---|---|
| **`deliverable_type`** | *What kind of deliverable a project produces* (project-level) | `project-schema.md` §3 frontmatter | — (this field) |
| `work_item_type` | *Declarative discriminator for a work-item kind* (story/task/bug/spike), the **domain-neutral methodology→hierarchy map** | `work-item-type-schema.md` | **Does NOT extend it.** Orthogonal: a `deliverable_type: software` project still contains `work_item_type: story` items. `deliverable_type` is a PROJECT-level frontmatter field; it is never a type-pack grammar entry (ADR-018 `core/`-independence kernel). |
| artifact-provenance `domain: A\|B\|C` | Three-domain artifact classification | `frontmatter-schema.md` Category 6 | **Distinct.** A per-artifact provenance tag, not a project-level deliverable class. |
| content-area `delivery/{domain}` | Obsidian content-area tag (`governance`/`design`/`testing`/…) | `frontmatter-schema.md` Tag Taxonomy | **Distinct.** A content-filing tag, not a deliverable class. |
| Stage-4 `domain:` class field | Abstract deliverable-domain signal consumed by the impact-analysis selector / guides / guide-index | `stage-04-planning.md` § 5.7 | **Consumes `deliverable_type`.** The Stage-4 field reads `deliverable_type` as its authoritative source where present (the reconciliation seam). |

Renaming the shipped artifact-provenance and content-area `domain` fields is **pre-existing naming-debt, OUT OF SCOPE** for this axis — flagged separately, not addressed here.

### `org_structure_type`

Optional. Enum — one of 7 PMBOK organizational-structure archetypes + a `Custom` escape (lowercase-kebab values, case-sensitive; `Custom` title-case to match `delivery_approach: Custom`):

| Value | PMBOK org-structure meaning |
|---|---|
| `functional` | Functional org; PM has little/no authority, resources report to functional managers |
| `matrix_weak` | Weak matrix; PM role is coordinator/expediter, functional managers hold authority |
| `matrix_balanced` | Balanced matrix; authority shared between PM and functional managers |
| `matrix_strong` | Strong matrix; PM has significant authority, dedicated PM staff |
| `projectized` | Projectized org; PM has high authority, team dedicated to the project |
| `virtual` | Virtual/network org; coordination across distributed/contracted nodes |
| `hybrid` | Mixed structure combining ≥2 of the above across the org |
| `Custom` | Escape hatch — an org shape not captured by the closed enum; free-form value documented in the project's own context |

**Default.** When absent, consumers treat the project as `functional` (the PMBOK baseline — lowest PM authority, the conservative assumption for portfolio rollups). The default is documented, not silent: a consumer rendering an org-shape rollup states `[ASSUMPTION] org_structure_type absent — defaulting to functional`.

**Consumer use.** Portfolio rollups (`weekly-status-rollup`, `pmo-portfolio-manager`) compare org shape across projects; alignment/escalation consumers read PM-authority level from the value. `[SOURCE]` — PMBOK 6th ed. organizational-structure-influence table (functional → projectized authority spectrum); enum shape mirrors `delivery_approach`.

### `team_roster`

Optional. A list of project-team membership entries — the **project-record-level projection** of "who is on this project's team" into the people-graph. Each entry is a 2-field object:

| Sub-field | Required | Type | Semantics |
|---|---|---|---|
| `person_ref` | ✅ | `ref → Person.person_id` | Resolves to a roster Person (the `person_id` deduplication anchor, ADR-040). Refs **only**. |
| `role_on_project` | ✅ | string | The person's role on THIS project (e.g., `Tech Lead`, `BA`, `QA`). |

**Compose-not-duplicate (load-bearing).** `team_roster` is an **index into** the people-graph, not a copy of it. An entry resolves to a `person_id`; capability, coverage, allocation %, and identity (`full_name`, `primary_role`) are **read through** the ref against Person / Resource / the operator-instance roster (`people-coverage-graph.md` three-query view) — **never copied inline**. An entry MUST NOT carry an inline `name`, `full_name`, `allocation_pct`, capability tags, or any Person/Resource attribute. The discriminating test: *entry resolves to a `person_id` (compose ✅) vs. carries its own person attributes (duplicate 🟥)*. Inlining a name forks the never-committed roster — a **PII-commit hazard** (the roster is operator-instance and never committed; an inline name in a tracked schema file leaks it) — and duplicates the frozen Resource entity (`{person_id, project_id, allocation_pct, role_on_project}`, `project-entity-model.md` §4 Resource entity).

**Relationship to Resource.** `role_on_project` intentionally mirrors the Resource field of the same name. `team_roster` is the **lightweight project-record membership list** (who is on the team, by ref); Resource is the **frozen allocation entity** (the same membership PLUS `allocation_pct` / period). They are two projections of the one `person_id` identity — `team_roster` is the PROJECT.md-frontmatter-level index; Resource is the entity-model-level allocation record. `team_roster` does NOT re-model Resource; it references the same people. (Re-modeling team membership as a new entity would touch the frozen 18-entity model → Tier-2 SCOPE CHANGE — explicitly out of scope.)

**Seed path (replaces `## Key People` prose).** `team_roster` replaces the free-text `## Key People` markdown table (`operations/templates/project-md-template.md`, columns `Person | Role | Comm Style / Notes`). Migration seeds each prose row into a `team_roster` entry by **resolving the `Person` cell by name against the people-roster** to a `person_id` (the same resolve-by-name migration ADR-040 defines for `project_owner`): a unique match becomes the `person_ref`; the prose `Role` cell becomes `role_on_project`; zero or ambiguous (≥2) matches route to the operator clarification queue (`people-coverage-graph.md` §3.2), never silently dropped. Comm-style notes are functional-roster attributes (read through the ref), not copied into `team_roster`.

**Reconciliation with the Stakeholder Register.** `team_roster`, the Stakeholder Register, and the frozen Resource entity are **three distinct projections of one `person_id` identity** — they join on the same anchor and MUST NOT be conflated. `team_roster` = **team membership** (who is on the delivery team). Stakeholder Register = **engagement** (interest/influence/desired-engagement + decision authority, for stakeholders who may NOT be team members). Resource = **allocation** (membership + allocation %). A person can be in all three, one, or any combination; each answers a different question. Keep the schemas consistent by keying all three on `person_id`; do not merge them. `[SOURCE]` — Stakeholder Register schema (joins on `person_id`); ADR-040 (`person_id` anchor).

## 5. Validation Rules

Fifteen rules governing schema conformance. Enforcement level `structural (auto)` means the rule is machine-verifiable from the frontmatter alone — no human judgment required. `[AC-R2]` annotations indicate the rule operationalizes the Stage-5-locked AC-R2.

| ID | Rule | Blocks | Level |
|---|---|---|---|
| **V1** | `delivery_approach` field is present in PROJECT.md frontmatter | schema parse | structural (auto) |
| **V2** | `delivery_approach` is EITHER (a) a single value in `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe, Hybrid, Custom}` (case-sensitive, title-case — the original single-enum form), OR (b) a 2-element YAML sequence `[A, B]` where A ≠ B and both A, B ∈ `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe}` (the Hybrid-Two array form; array members **exclude** `Hybrid` and `Custom` — they are meta-archetypes, not composable constituents). Array sub-assertions: **(V2-a) length == 2 · (V2-b) members distinct · (V2-c) each member ∈ the 6-set.** | schema parse + skill branch | structural (auto) |
| **V3** | When `delivery_approach: Custom`, block `custom_methodology_definition` is present | skill branch | structural (auto) — **AC-R2** |
| **V4** | When `delivery_approach ≠ Custom`, block `custom_methodology_definition` is absent or `null` | skill branch | structural (auto) |
| **V5** | `custom_methodology_definition.name` is a non-empty string | — | structural (auto) — **AC-R2** |
| **V6** | `custom_methodology_definition.base_archetype` is one of the 8 enum values OR the YAML `null` literal | skill-fallback logic | structural (auto) — **AC-R2** |
| **V7** | `custom_methodology_definition.derived_from` is a list (may be `[]`); each member (if any) is one of the 8 enum values | — | structural (auto) — **AC-R2** |
| **V8** | `custom_methodology_definition.lifecycle` is one of `{continuous, phased, timeboxed}` | skill branch | structural (auto) — **AC-R2** |
| **V9** | `custom_methodology_definition.ceremonies` is a non-empty list of strings (min 1 entry) | — | structural (auto) — **AC-R2** |
| **V10** | `custom_methodology_definition.artifacts` is a non-empty list of strings (min 1 entry) | — | structural (auto) — **AC-R2** |
| **V11** | `custom_methodology_definition.cadence` is a non-empty string | — | structural (auto) — **AC-R2** |
| **V12** | `custom_methodology_definition.notes` is either absent OR a string (may be empty `""`) | — | structural (auto) |
| **V13** | `deliverable_type` is EITHER **absent** (legacy file — additive, the field is optional on pre-existing PROJECT.md), OR a non-empty string matching **one of** the recognized classes `{software, governance, web, data, enterprise-platform, hardware, process}` (lowercase, case-sensitive) **OR** the open-escape shape `^[a-z]+(-[a-z0-9]+)*$` (a non-empty lowercase-kebab string — mirrors `delivery_approach: Custom` openness; an unrecognized-but-well-formed value is valid and is the guide-authoring demand signal). The field is **required on forward (newly-scaffolded) PROJECT.md files** and **optional on legacy files**; absence on a legacy file is conformance, not a defect. | schema parse + skill branch | structural (auto) |
| **V14** | `org_structure_type`, when present, is one of `{functional, matrix_weak, matrix_balanced, matrix_strong, projectized, virtual, hybrid}` (lowercase-kebab, case-sensitive) OR the literal `Custom`. Absent is valid (consumers default to `functional`). | skill branch | structural (auto) |
| **V15** | `team_roster`, when present, is a list where **every** entry is an object with EXACTLY the keys `{person_ref, role_on_project}` and no others — `person_ref` is a `ref → Person.person_id` and `role_on_project` is a non-empty string. **(V15-a)** no entry carries any key outside `{person_ref, role_on_project}` (no inline `name`/`allocation_pct`/Person-or-Resource attribute — the no-inline-PII invariant). **(V15-b)** each `person_ref` resolves against the people-roster `person_id` anchor: an unresolved ref → **BLOCK-WRITE**; a ref flagged external (not in roster) → **WARN-HEALTH** (per ADR-040 L2 disposition). | schema parse + skill branch | structural (auto) for V15-a (closed key-set, frontmatter-only); ref-resolution (V15-b) is a write-time check |

**V-table coordination note.** The `delivery_approach` array form (the Hybrid-Two `[A, B]` case) is validated by the **amended V2 (v2.18)** — it does NOT introduce a new V-rule. The `deliverable_type` deliverable-domain axis is defined by **V13** (appended to the V12 tail; no existing rule renumbered). The org-structure shape and the project-altitude people-graph index are defined by **V14 + V15** — `org_structure_type` (V14) and `team_roster` (V15) — appended to the post-V13 tail (see References). `delivery_model` is **not** a field — it resolves to the existing required `delivery_approach`, so no rule is added for it. No existing rule is renumbered.

### 5.1 Custom Block Completeness (operationalizes AC-R2)

When `delivery_approach: Custom`, the following fields MUST all be present and well-formed per their individual rules:

> `{name, base_archetype, derived_from, lifecycle, ceremonies, artifacts, cadence}`

That is: V3 (block presence) AND V5 (name non-empty) AND V6 (base_archetype enum-or-null) AND V7 (derived_from list) AND V8 (lifecycle enum) AND V9 (ceremonies non-empty) AND V10 (artifacts non-empty) AND V11 (cadence non-empty).

This block-completeness assertion is the single-test AC-R2 gate. Stage 8 QA runs it against the 3 worked examples in [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md) Custom row (all must PASS) and against 2 negative test cases (both must FAIL):

- Negative case 1 — `delivery_approach: Custom` with `cadence` missing → V11 FAIL → Custom Block Completeness FAIL.
- Negative case 2 — `delivery_approach: Custom` with `lifecycle: weekly` (invalid enum) → V8 FAIL → Custom Block Completeness FAIL.

### 5.2 Validation-failure handling

A PROJECT.md that fails any V1-V15 assertion is **malformed** (V13/V14/V15 join the malformed-file set with the same surface-the-failing-rule-ID + route-to-`project-initiator` Mode C handling; absence of an optional field — `deliverable_type` on a legacy file, `org_structure_type`, or `team_roster` — is conformance per its rule, not a failure). Consumer skills encountering a malformed PROJECT.md MUST:

1. Refuse to produce methodology-parameterized output.
2. Surface the specific failing rule ID to the operator.
3. Route the file for correction via `project-initiator` (Mode C — schema repair) or manual edit.

Skills MUST NOT silently work around validation failures by defaulting to an archetype. Silent default is a named failure mode — see `methodology-parameterization-v1.md § Failure Modes` (PROC-2: Base-archetype blind fallback; PROC-3: Custom-block skip).

### References

- PROJECT.md-schema keystone: added the first-class `deliverable_type` deliverable-domain axis to the schema, defined by V13 (appended off the V12 tail). See ADR-050 for the placement + open-enum decision.
- Org-structure + team-roster expansion — adds the `org_structure_type` and `team_roster` fields to the schema (the org-structure shape + the project-altitude people-graph index), defined by the two V-rules after the keystone (**V14 + V15**). `delivery_model` is NOT added — it resolves to the existing required `delivery_approach`.

## 6. Examples

Five worked examples covering the representative cases. Each is a valid PROJECT.md frontmatter block that passes all V1-V15 assertions applicable to its `delivery_approach` value.

### 6.1 Scrum (minimal — enum-matched, no Custom block)

```yaml
---
project_name: Payments Platform Refactor
project_owner: J. Doe
status: ACTIVE
delivery_approach: Scrum
---
```

**Validation trace:** V1 ✓ (field present), V2 ✓ (`Scrum` in enum), V3 N/A (not Custom), V4 ✓ (no block present as expected), V5-V12 N/A.

### 6.2 Hybrid with `dual_framing_enabled: true` (enum-matched + co-management framing)

```yaml
---
project_name: [PROJECT_KEY] Implementation
project_owner: C. [OPERATOR_NAME]
status: ACTIVE
dual_framing_enabled: true
delivery_approach: Hybrid
---
```

**Validation trace:** V1 ✓, V2 ✓ (`Hybrid`), V3 N/A, V4 ✓, V5-V12 N/A.

**Reconciliation note.** The two fields are **orthogonal**, and this example shows them combined: `delivery_approach: Hybrid` is the methodology classification (a two-archetype combination), while `dual_framing_enabled: true` is the *separate, orthogonal* operational co-management dual-framing trigger. Co-management is NOT implied by `Hybrid` — a Hybrid project with `dual_framing_enabled: false` is equally valid (two native framings, no co-management output), and a single-archetype project may set `dual_framing_enabled: true` independently. This combination is the legacy co-managed shape, but it is a *configuration*, not the definition of Hybrid — see §7 Collision Check.

### 6.3 Custom — Scrumban (base_archetype: Kanban)

```yaml
---
project_name: Vendor Onboarding Modernization
project_owner: A. Smith
status: ACTIVE
delivery_approach: Custom
custom_methodology_definition:
  name: Scrumban
  base_archetype: Kanban
  derived_from: [Kanban, Scrum]
  lifecycle: continuous
  ceremonies:
    - daily standup
    - replenishment review
    - retrospective
  artifacts:
    - kanban board with WIP limits
    - cycle-time metrics
    - sprint goals as optional overlay
  cadence: continuous flow with weekly replenishment
  notes: Scrum ceremonies retained, estimation and sprint commitment replaced with WIP-limited pull
---
```

**Validation trace:** V1 ✓, V2 ✓ (`Custom`), V3 ✓ (block present), V5 ✓ (`Scrumban` non-empty), V6 ✓ (`Kanban` in enum), V7 ✓ (both members in enum), V8 ✓ (`continuous` in enum), V9 ✓ (3 entries), V10 ✓ (3 entries), V11 ✓ (non-empty cadence), V12 ✓ (notes is a string). **Custom Block Completeness: PASS.**

**Hybrid-Two vs. Custom (partition note).** This Scrumban is a **fused variant** — Scrum ceremonies are retained but estimation and sprint commitment are *replaced* with WIP-limited pull — so it is correctly modelled as `Custom` (a named methodology that blends two archetypes into a third thing). A project running an **unmodified Scrum track alongside an unmodified Kanban track** instead uses the Hybrid-Two array `delivery_approach: [Scrum, Kanban]`. The two representations are **not redundant** and partition cleanly: **Custom** = a named modification/fusion (overridden ceremonies/practices, `derived_from` records lineage); **array** = two canonical archetypes coexisting as-is, each native, union of primitives. Test: *"two tracks each running an archetype natively (→ array), or one team running a fused/renamed methodology (→ Custom)?"*

### 6.4 Custom — Shape Up (base_archetype: null — genuinely novel)

```yaml
---
project_name: Platform Discovery Sprint
project_owner: R. Patel
status: ACTIVE
delivery_approach: Custom
custom_methodology_definition:
  name: Shape Up
  base_archetype: null
  derived_from: []
  lifecycle: timeboxed
  ceremonies:
    - betting table
    - kickoff
    - cool-down retrospective
  artifacts:
    - pitches
    - shape-up bets
    - circuit-breaker deadlines
    - hill charts
  cadence: 6-week cycle + 2-week cooldown
  notes: Basecamp-originated; no backlogs, no sprints, no standups — betting replaces planning
---
```

**Validation trace:** V1 ✓, V2 ✓, V3 ✓, V5 ✓ (`Shape Up`), V6 ✓ (`null` literal allowed), V7 ✓ (empty list allowed), V8 ✓ (`timeboxed`), V9 ✓ (3 entries), V10 ✓ (4 entries), V11 ✓, V12 ✓. **Custom Block Completeness: PASS.**

**Skill consumption note.** Because `base_archetype: null`, consumer skills MUST use the block's `lifecycle` / `ceremonies` / `artifacts` / `cadence` directly — NO archetype fallback. If a skill cannot parameterize from these fields alone, it MUST emit a methodology-agnostic output with an explicit caveat (not a silent default to Scrum). See `methodology-parameterization-v1.md § Skill Consumption Pattern` 3-branch logic CASE 3.

### 6.5 Hybrid-Two array — `delivery_approach: [Scrum, Kanban]` (two archetypes as-is)

A project running **two canonical archetypes natively, side-by-side** — each track keeping its own lifecycle/ceremonies/artifacts — declares the pair as a 2-element array. No `custom_methodology_definition` block is present (the array members are unmodified archetypes, not a fused variant).

```yaml
---
project_name: Platform Re-architecture Program
project_owner: M. Okafor
status: ACTIVE
delivery_approach: [Scrum, Kanban]
---
```

**Validation trace:** V1 ✓ (field present), V2 ✓ — **array branch**: 2 elements (V2-a length == 2 ✓), `Scrum ≠ Kanban` (V2-b distinct ✓), both members ∈ the 6-set `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe}` (V2-c ✓; neither is `Hybrid`/`Custom`). V3 N/A (not `Custom`), V4 ✓ (no `custom_methodology_definition` block), V5-V12 N/A.

**Array vs. Custom (which form to use).** This is the **array** family, NOT a second Custom example. Use the array `[A, B]` when two named archetypes run **as-is** (union of both, each native) — contrast §6.3, where Scrumban is a *fused* variant (Scrum ceremonies retained but estimation replaced with WIP-pull) and is therefore `Custom`. The two representations partition cleanly and are not redundant: **array** = two archetypes coexisting unmodified; **Custom** = a named modification/fusion. (The array-consumption logic — how a consumer renders dual-framed output from `[A, B]` — is specified in the [`methodology-parameterization-v1.md § Skill Consumption Pattern` CASE 1-ARRAY sub-branch](../../release/references/specs/methodology-parameterization-v1.md#case-1-array): one native section per constituent, union of primitives per work-org-mapping §2.5, phased-governs-gates / timeboxed-governs-iterations on contested surfaces.)

### 6.6 `org_structure_type` + `team_roster` (the additive org-shape + people-graph-index fields)

A balanced-matrix project declaring its org shape and a 3-member team by `person_id` ref. Both fields are additive — the example also passes all V1-V15 rules applicable to its `delivery_approach`.

```yaml
---
project_name: Vendor Portal Modernization
project_owner: p_okafor_m          # ref→Person.person_id (ADR-040)
status: ACTIVE
delivery_approach: Scrum
deliverable_type: web              # from the keystone deliverable-domain axis
org_structure_type: matrix_balanced
team_roster:
  - person_ref: p_okafor_m
    role_on_project: Program Manager
  - person_ref: p_singh_a
    role_on_project: Tech Lead
  - person_ref: p_torres_l
    role_on_project: Business Analyst
---
```

**Validation trace:** V1 ✓ (`delivery_approach` present), V2 ✓ (`Scrum` in enum), V3 N/A (not Custom), V4 ✓ (no Custom block), V5-V12 N/A, **V13 ✓** (`deliverable_type: web` — recognized class), **V14 ✓** (`org_structure_type: matrix_balanced` in enum), **V15 ✓** — `team_roster` is a list of 3 objects, each with EXACTLY `{person_ref, role_on_project}` (V15-a closed key-set ✓ — no inline names/allocation), each `person_ref` resolves against the roster (V15-b ✓), each `role_on_project` non-empty ✓.

**Compose-not-duplicate note.** The roster carries only refs + project-roles. `p_singh_a`'s full name, capability tags, allocation %, and coverage edges are **read through** the ref against Person / Resource / the people-roster (`people-coverage-graph.md` who-does-what query) — never copied into PROJECT.md. This is the no-inline-PII invariant V15-a enforces: the schema cannot hold a roster name, so an accidental commit cannot leak one.

## 7. Migration Notes — Field Rename

The dual-framing co-management trigger is named **`dual_framing_enabled`**. The legacy key `spm_comanaged` it replaced was **retired in v2.19** — it is no longer accepted on read. Migrate any remaining `PROJECT.md` files by renaming the key to `dual_framing_enabled` (identical boolean semantics); a one-line edit per file. (Through v2.18 the legacy key was accepted via a `project-initiator` deprecation shim; that shim is removed in v2.19, now that live files have migrated.)

### Collision Check — Are `dual_framing_enabled` and `delivery_approach` redundant?

**No.** They are orthogonal fields measuring different properties, and neither implies the other:

| Field | Role | Consumer |
|---|---|---|
| `dual_framing_enabled: bool` | Triggers Dual-Framing Bridge output (Agile + Waterfall) — operational co-management dual-framing binary, independent of methodology. | `OPERATIONS.md § Dual-Framing Bridge`; `delivery-engine` Mode D bridge step |
| `delivery_approach: Hybrid` | Classifies project methodology as a user-configurable two-archetype combination `[A, B]` reported in both native framings — a classification only, saying nothing about co-management | All methodology-aware role-skills |

### Reconciliation Rule

The two fields are **orthogonal and combine freely** — co-management is no longer implied by, and does not imply, the Hybrid classification:

- `delivery_approach: Hybrid` + `dual_framing_enabled: true` — a two-archetype project that *additionally* runs the co-management dual-framing output (the legacy co-managed shape, now expressed as an explicit combination rather than a coupled default).
- `delivery_approach: Hybrid` + `dual_framing_enabled: false` (or absent) — a two-archetype project reported in both native framings, with no co-management output. **Valid.**
- `dual_framing_enabled: true` + `delivery_approach: Scrum` (or any non-Hybrid) — a single-archetype project that runs the co-management dual-framing output independently of methodology. **Valid** under the decoupled model — this is NOT a misconfiguration to "correct" toward Hybrid. (`project-initiator` Mode C no longer flags this combination as a configuration-validation candidate.)
- `dual_framing_enabled: false` (or absent) + non-Hybrid — single-methodology project, no dual-framing.

### Future consolidation — OUT OF SCOPE

The field rename + legacy-key retirement is **not** the deferred trigger↔`Hybrid` consolidation. That consolidation — collapsing the orthogonal `dual_framing_enabled` trigger into the `delivery_approach: Hybrid` classification — remains explicitly OUT OF SCOPE; doing it would collapse the orthogonality this decouple protects. A future milestone may still revisit whether to:

- (a) derive co-management framing from `delivery_approach: Hybrid` and drop the standalone trigger,
- (b) keep `dual_framing_enabled` as the authoritative trigger and `delivery_approach: Hybrid` as the methodological tag (current model),
- (c) introduce a reconciliation validator that enforces alignment between the two fields.

See [`OPERATIONS.md § Methodology Awareness Protocol § Relationship to Dual-Framing Bridge`](../governance/OPERATIONS.md) for the operational posture.

### Current PROJECT.md format note

Existing `projects/<project>/PROJECT.md` files under `projects/` use an ad-hoc markdown `**Key:** value` format rather than YAML frontmatter. `[SOURCE]` — inspection of `projects/[PROJECT_KEY] Implementation/PROJECT.md` and sibling files 2026-04-24.

The schema describes the **canonical forward-looking shape**. As of the composed-index redesign (ADR-057, #363), that shape is a **thin composed wiki-link index** (≤50 lines): Methodology + Status stay **inline** (the §8 consumers parse them in place); People / Systems / Milestones / Plans / Workstreams become `[[wiki-link]]` lists into the `_pmo/` shared-entity pages (#362) and the #159 typed plans, rather than inline tables. `project-initiator` Mode A scaffolds **new** projects in this shape (Step 3, `references/project-md-composed-index-template.md`). Migration of **existing** live PROJECT.md files is the gated, EXPENSIVE step (Migration Protocol below) — **not** auto-applied. Consumer skills read `delivery_approach` + `status` via the same parsing approach they use today (markdown key-value or YAML — whichever is present); because Methodology + Status remain inline, the composed-index shape is back-compatible with every §8 consumer. The schema is authoritative for:

- new PROJECT.md scaffolding (composed-index shape via `project-initiator` Mode A),
- any PROJECT.md migrated to the composed-index shape (per the protocol below),
- the semantic definition of fields regardless of serialization format.

### Composed-Index Migration Protocol (ADR-057 — gated, per-project)

Migrating a live PROJECT.md from the narrative-table monolith to the composed-index shape. **EXPENSIVE / gated per project** — the live ops tree (`projects/`) is git-ignored, so there is **no git rollback**; snapshot before, verify links after. Run the four steps in order, one project at a time:

- **M1 — Extract.** Read the live PROJECT.md end-to-end and extract the inline People / Systems / Milestones / Plans / Workstreams table rows into discrete entities. Snapshot the original to `08-Generated/_migration-snapshot/` (the pre-change copy — the only rollback path on the git-ignored tree).
- **M2 — Author / link `_pmo/` pages (with alias tracking).** For each extracted entity, author (or link to an existing) `_pmo/` page from the matching entity-page template (`operations/templates/{person,system,vendor,workstream,decision,dependency}-entity-template.md`). Dedup against the entity id (`person_id`, …); on any name variant, append to `aliases[]` (`people-coverage-graph.md §2.3`), never edit the id. Unresolved person names route to the clarification queue (never auto-create — `project-initiator` Step 2b).
- **M3 — Replace tables with wiki-link lists.** Swap the inline tables in PROJECT.md for `[[wiki-link]]` lists into the M2 pages + the #159 typed plans. Keep Methodology + Status inline (consumer back-compat). Target the ≤50-line composed-index shape.
- **M4 — Verify links.** Confirm every wiki-link resolves to a real `_pmo/` page (Obsidian graph view shows project↔entity edges) and that every §8 consumer still parses Methodology + Status from the migrated file without error.

The POC project for the first migration is **decided at the Stage-12 gate** (not in Engineering); bulk migration beyond the POC is a gated follow-up.

## 8. Consumers

Skills and governance files that read `PROJECT.md` fields at invocation. Methodology-sensitivity column indicates whether the skill's behavior should vary by `delivery_approach` (per the blast radius analysis §6.1).

| Consumer | Reads | Methodology-sensitivity | status |
|---|---|---|---|
| `delivery-engine` | `dual_framing_enabled` + sprint tracker + velocity history + (future) `delivery_approach` | CRITICAL | Reads unchanged; future refit parameterizes on `delivery_approach` |
| `project-initiator` | `dual_framing_enabled` + governance-specific tracker routing + (future) `delivery_approach` | HIGH | Reads unchanged; future refit adds 8-way archetype branch |
| `ppm-agent` | `status` + project metadata + RAG derivation | MEDIUM | Unchanged |
| `daily-status` | `status` + framework + sprint stand-up format | HIGH | Unchanged; future refit varies format by archetype |
| `weekly-status-rollup` | project metadata + status cadence | MEDIUM | Unchanged |
| `comms-writer` | project-level voice + sprint cadence | MEDIUM | Unchanged |
| `change-management` | governance context | MEDIUM | Unchanged |
| `tracker-manager` | tracker routing | LOW | Unchanged |
| `file-router` | classification | LOW | Unchanged |
| `pmo-qa-auditor` | skill-under-audit context | LOW | Unchanged (methodology-agnostic by design) |
| `pmo-process-designer` | project context | LOW | Unchanged |
| `implementation-planner` | release context | MEDIUM | Unchanged |
| `artifact-generator` | project context | LOW | Unchanged |

**Governance consumers:**

- [`OPERATIONS.md § Methodology Awareness Protocol`](../governance/OPERATIONS.md) — Rules 1-3 mandate that skills read `delivery_approach` + consult the matrix + handle Custom via typed extension.
- [`OPERATIONS.md § Dual-Framing Bridge (Conditional)`](../governance/OPERATIONS.md) — reads the dual-framing trigger `dual_framing_enabled`; not yet refit to read `delivery_approach: Hybrid` (future consolidation scope).

**Downstream (future) consumers:**

- **release-planner-bundle** (HARD handoff) — `release-planner` skill reads `delivery_approach` + consults matrix at Stage 3 Bundle time.
- **Role-skills wave** (HARD handoff) — PO/BA/Principal/Software Engineer role-skills read `delivery_approach` + `custom_methodology_definition` + matrix row at invocation; parameterize role-appropriate outputs.
- **Skill-authoring adapter** (SOFT handoff) — `pmo-skill-refiner` `methodology-adapter` reference consumes the enum + matrix at skill-authoring time.

**Evidence:**

| # | Claim | Source |
|---|---|---|
| 1 | 13 skills consume PROJECT.md | `[SOURCE]` `grep -l 'PROJECT\.md' release/skills/**/SKILL.md` 2026-04-24 (blast radius §6.1) |
| 2 | `delivery-engine` Mode D + Mode E presuppose sprints | `[SOURCE]` `operations/skills/delivery-engine/SKILL.md:170-215` |
| 3 | `project-initiator` binary Agile/Hybrid vs. Waterfall branch | `[SOURCE]` `operations/skills/project-initiator/SKILL.md:190-193` |
| 4 | `OPERATIONS.md § Dual-Framing Bridge` defines the dual-framing trigger behavior | `[SOURCE]` `core/governance/OPERATIONS.md § Dual-Framing Bridge` |
| 5 | Existing PROJECT.md files use markdown key-value format | `[SOURCE]` inspection of `projects/[PROJECT_KEY] Implementation/PROJECT.md` 2026-04-24 |
| 6 | AC-R2 block-completeness operationalization | `[SOURCE]` Stage 5 spec §1 + AC-R2 locked text |

---

**End of PROJECT.md schema.** Next: [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) for normative archetype definitions.
