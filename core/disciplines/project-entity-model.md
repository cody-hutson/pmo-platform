---
title: Project Entity Model
purpose: The canonical project-entity model — the logical entities of the project-data layer, their relationships, and the FROZEN definitions downstream schemas derive from.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Project Entity Model

<!-- repo-integrity: allow-memory-ref -->
<!-- schema field names like `project_owner_external` match the memory-slug pattern but are not memory references -->

**Status:** Canonical
**Owner:** `../disciplines/project-entity-model.md`
**Introduced:** project-data-foundation (2026-05-16) — initiative project-data-architecture, roadmap `<OPERATOR_INSTANCE_ROADMAPS_PATH>/project-data-architecture.md` (operator-local)
**Establishing issue:** G1 — 17-entity canonical model (roster re-frozen at 18 via ADR-018, 2026-06-07)
**Architectural basis:** the Two-Axis Entity Lifecycle ADR (**RATIFIED** at Collective Review, 2026-05-16)
**Consumers (downstream G2–G10):** G2 (per-entity field schemas), G3-pilot (RAID-Log machine-schema pilot), G4 (operational-artifact inventory), G5 (template standard), G6 (templatization harness), G3–G10 (later milestones)
**Cross-references:** see [§9](#9-cross-references).

---

## AC Build-Checklist (Stage 6 → AC-1..AC-7 traceability)

This doc satisfies the seven acceptance criteria of the establishing issue. Each section is mapped to the AC it discharges and to the FROZEN Stage-5 artifact it transcribes — **no re-design; transcription + rationale only**.

| AC | Requirement | Satisfied by | Frozen source |
|---|---|---|---|
| **AC-1** | All 17 entities defined with single-paragraph rationale + first-class justification | [§4](#4-entity-definitions-18) — per-entity *Rationale & first-class justification* | Frozen Artifact 1 (roster + tier; +Work Item entity 18 via ADR-018) |
| **AC-2** | Field list per entity (≥3 required fields each) | [§3](#3-entity-core-schema) (6 required core) + [§4](#4-entity-definitions-18) per-entity (≥3 required entity-specific) | Frozen Artifacts 2, 3 |
| **AC-3** | Relationship matrix (entity-pair × MVP type) for ≥10 common chains | [§5](#5-relationship-matrix) — 17 directed chains + adjacency grid | Frozen Artifact 4 (16 chains + the ADR-018 rollup edge) |
| **AC-4** | Lifecycle state machine per entity (DOMAIN A/B/C inheritance from `frontmatter-schema.md`) | [§3](#3-entity-core-schema) two-axis model + [§4](#4-entity-definitions-18) per-entity Axis-1 machines + Axis-2 pattern | the Two-Axis Entity Lifecycle ADR + Frozen Artifacts 1, 3 |
| **AC-5** | Owning-agent matrix — which skills read/write per entity | [§6](#6-owning-agent-matrix) | Frozen Artifact 5 |
| **AC-6** | Cross-references to project-schema, frontmatter-schema, document-ecosystem-design, methodology-parameterization, Deep Research C06/C07/C12/C17 | [§9](#9-cross-references) | §9 targets |
| **AC-7** | 3+ worked examples — Milestone, Person, Plan | [§8](#8-worked-examples) | Worked Examples (verbatim) |

---

## 1. Purpose

This document is the **canonical specification of the 18 logical entities** the PMO platform tracks across the project, cross-project, and portfolio tiers. It defines, per entity: what it represents, why it is first-class, its field schema (type + cardinality + requiredness), its two-axis lifecycle, its storage tier and persistence mode, and its owning-agent triplet (creates / maintains / reads).

It exists because the project-data-architecture initiative's 5-layer architecture (Schema / Storage / Automation / Interface / Governance) hangs off an entity model that does not yet exist in formalized form. Three adjacent schemas each cover a slice but none the whole:

- `schemas/project-schema.md` formalizes today's `PROJECT.md` frontmatter — **one** entity (Project), too narrow.
- `schemas/frontmatter-schema.md` describes file-level metadata — **file-centric**, not entity-centric.
- `document-ecosystem-design.md §6` sketches an entity model but does not formalize fields / relationships / owners — **incomplete**.

This doc fills that gap. It is **DATA-centric**: it defines the records the PMO tracks as data, independent of the files that persist them. `frontmatter-schema.md` is its *persistence dialect*, not its competitor (see [§2](#2-scope--boundary-axiom) D1 mapping). Field-**validation** rules (regex / range / cross-field) are deferred to G2 by design — this doc freezes *what fields exist*; G2 enumerates *how they validate*.

## 2. Scope & Boundary Axiom

**In scope.** The 18-entity roster (frozen); per-entity rationale + first-class justification; the inherited Entity Core schema (6 required + 1 optional field); per-entity entity-specific field lists (type + cardinality + requiredness — frozen); the two-axis lifecycle model; per-entity Axis-1 operational state machines (frozen); per-entity Axis-2 content-lifecycle pattern (referenced from `frontmatter-schema.md`); the directed relationship matrix (17 chains, consuming the 7 canonical MVP types); the owning-agent matrix; the logical storage map (`storage_tier` + `persistence_mode`).

**Out of scope (deferred — boundary axiom).** Field-validation rules → **G2**. Physical file layout, filenames, frontmatter serialization → **G3 (PROJECT.md redesign) / G4 (`_pmo/` layout)**. Registration of the entity Axis-1 state-machine family into `standards/lifecycle-states-canonical.md §3` → **G8 / G10**, later milestones — this doc only *declares* the forward-binding `<Entity>-<state>` convention (see [§4 note](#axis-1-naming-convention-forward-binding)).

### Boundary axiom — project **DATA** ≠ **FILE** ecosystem 

> A logical entity is a *data record the PMO tracks*. The file(s) that persist it are a separate concern with their own lifecycle. Conflating the two is forbidden — it is the architectural error this initiative exists to eliminate.

This axiom forces the two-axis lifecycle model ([§3](#two-axis-lifecycle-model)). It is mandated by the initiative roadmap (`project-data-architecture.md §2 Boundary`) and grounded in closed issue. The Project entity ⊇ `PROJECT.md` (the file is one persistence of the entity); a Milestone has *no single backing file* (it is embedded in parent project state) — proof that "an entity's lifecycle = its file's Domain state" is undefined for operational entities and therefore cannot be the model.

### Relationship to adjacent schemas (D1 — frozen)

| Layer | Doc | Unit | This model's relationship |
|---|---|---|---|
| Conceptual (this doc) | `project-entity-model.md` | logical **entity** (record the PMO tracks) | **defines** the 18 entities, fields, relationships, lifecycle |
| Persistence dialect | `schemas/frontmatter-schema.md` | **file** with YAML metadata | **referenced, not duplicated** — entities persisted as Domain A/B/C files inherit its Category-2 lifecycle + Category-4 relationship-edge schema |
| Narrower instance | `schemas/project-schema.md` | `PROJECT.md` frontmatter | the **Project** entity (#1) ⊇ `PROJECT.md`; project-schema.md's V1–V12 + worked-example-with-trace pattern is the template G2 extends per-entity |
| Sketch (superseded by this) | `document-ecosystem-design.md §6` | Schema / Storage / Presentation layers | this doc **formalizes** §6's entity sketch at entity granularity; preserves the 3-layer governance boundary (we own Schema only) |

**Duplicate-source-discipline compliance:** the 7 MVP relationship types and the Domain A/B/C content-state vocabularies are **cited by pointer, never re-listed with definitions**. This doc *names* the 7 types and the 3 patterns and links their authoritative homes (`frontmatter-schema.md §Category 4` / `§Category 2`; `standards/lifecycle-states-canonical.md §3–§4`).

## 3. Entity Core Schema

### Two-axis lifecycle model

Per the **Two-Axis Entity Lifecycle ADR** (RATIFIED). Every entity declares **two orthogonal lifecycle axes**:

- **Axis 1 — `lifecycle_state`**: an entity-specific **operational** state machine. *Net-new vocabulary* this model originates (e.g., RAID Item `open→in-progress→mitigating→resolved→closed`). Defined per-entity in [§4](#4-entity-definitions-18).
- **Axis 2 — `content_lifecycle_pattern ∈ {Baselined, Living, Hybrid}`**: *referenced* from `frontmatter-schema.md` Category-2 Domain A/B/C (Domain A = Baselined; Domain B = Living; Domain C = Hybrid). Governs the lifecycle of the file(s) that persist the entity. **This is the literal AC-4 "DOMAIN A/B/C inheritance from `frontmatter-schema.md`".**

The two axes are independent: an entity's operational state (Axis 1) says where the *record* is in its workflow; its content pattern (Axis 2) says how the *file* persisting it evolves. The boundary axiom makes any single-axis reading internally contradictory (rejected alternatives are recorded in the Two-Axis Entity Lifecycle ADR).

<a id="axis-1-naming-convention-forward-binding"></a>**Axis-1 naming convention (forward-binding; NOT a governance edit here).** Axis-1 operational states are cross-machine vocabulary that will eventually collide with the independent state-vocabulary spaces in `standards/lifecycle-states-canonical.md §5` (e.g., entity `archived` vs. existing `archived` senses). This model **declares** the object-typed convention `<Entity>-<state>` for cross-machine prose (e.g., `Milestone-completed`, `RAIDItem-closed`), consistent with `lifecycle-states-canonical.md §2`. **Registration of the entity state-machine family into `lifecycle-states-canonical.md §3` is a downstream governed change owned by G8 / G10** — flagged here, NOT executed (respects "No governance file modifications without operator approval").

### Entity Core fields (inherited by ALL 18 — FROZEN Artifact 2)

Every entity carries these core fields **plus** its entity-specific fields ([§4](#4-entity-definitions-18)). Six are required; `relationships` is optional. This floor alone satisfies AC-2's ≥3-required minimum before any entity-specific field is added.

| Field | Type | Req | Card | Notes |
|---|---|---|---|---|
| `id` | string (slug) | ✅ | 1 | stable identifier, unique within `storage_tier` |
| `entity_type` | enum (18 roster names) | ✅ | 1 | discriminator |
| `lifecycle_state` | string | ✅ | 1 | **Axis 1** — value ∈ this entity's operational machine ([§4](#4-entity-definitions-18)) |
| `content_lifecycle_pattern` | enum {Baselined, Living, Hybrid} | ✅ | 1 | **Axis 2** — inherits `frontmatter-schema.md §Cat-2` Domain A/B/C |
| `owning_agent` | string (skill name) | ✅ | 1 | the skill that maintains this record ([§6](#6-owning-agent-matrix)) |
| `created_date` | ISO `YYYY-MM-DD` | ✅ | 1 | not in future |
| `relationships` | array&lt;RelEdge&gt; | ⚪ | 0..* | RelEdge schema = `frontmatter-schema.md §Cat-4` (referenced, not redefined); `type` ∈ the 7 MVP types |

> **Field-validation deferral.** Type / requiredness / cardinality are frozen here. Regex / range / cross-field validation rules are **G2** — it writes V-style rules (per `project-schema.md` V1–V12) against exactly this surface.

## 4. Entity Definitions (×18)

Per-entity record: **Rationale & first-class justification** · **Entity-specific fields** (on top of the 7 Core; `✅`=required `⚪`=optional · type · cardinality) · **Axis-1 operational state machine** · **Axis-2 content pattern** · **storage_tier** · **persistence_mode** · **owning-agent triplet**. Field lists + Axis-1 machines transcribe FROZEN Artifact 3; tier / persistence / Axis-2 transcribe FROZEN Artifact 1; owning-agent transcribes FROZEN Artifact 5. **The roster and field lists are FROZEN — any change requires reopening the establishing issue via a Tier-2 SCOPE CHANGE.**

> **Amended per [SCOPE CHANGE — RESOLVED via ADR-018] (declarative-workitem-type-model, Tier-2):** the roster is extended from 17 to **18** by the addition of the generic `Work Item` entity ([#18](#18-work-item), [§4](#4-entity-definitions-18)) — a thin entity-graph member whose type variability is externalized to the declarative type layer (the C2 type layer of the same release) per D1 hybrid. Precedented by the 2026-05-16 RAID Item Tier-2 amendment (scoped addition + re-freeze). Roster + field lists **RE-FROZEN at 18 entities** as of 2026-06-07. Authorization: this milestone's Stage 9 GO.

### Project-scoped entities (live in `[Project]/`)

#### 1. Project

**Rationale & first-class justification.** The top-level unit of delivery the PMO tracks; every operational artifact is either project-scoped or explicitly cross-project. First-class because it owns the lifecycle (`ACTIVE→CLOSING→CLOSED`) that gates *all* skill processing (CLAUDE.md § Project Lifecycle) and is the anchor every project-scoped entity's `project_id` resolves to. The Project entity ⊇ `PROJECT.md`; `project-schema.md` is the persistence dialect of this entity's frontmatter.

- **Fields:** `project_name`✅ str·1 · `project_owner`⚪ ref·1 → `Person.person_id` · `project_owner_external`⚪ str·1 *(external fallback — exactly-one-of {`project_owner`, `project_owner_external`}; Tier-2 SCOPE CHANGE — ADR-040)* · `status`✅ enum·1 · `delivery_approach`✅ enum8·1 · `portfolio_id`⚪ ref·1 · `program_id`⚪ ref·1
- **Axis-1:** `ACTIVE → CLOSING → CLOSED` (reconciles 1:1 with `project-schema.md status`; Project ⊇ PROJECT.md)
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** file-backed
- **Owning agents:** creates `project-initiator` · maintains `ppm-agent` · readers: all PMO skills

**Amended per [SCOPE CHANGE — RESOLVED via ADR-040] (functional-people-graph, Tier-2):** `project_owner` lifted from `string` to `ref → Person.person_id` + an optional `project_owner_external` free-text fallback for non-roster owners (leadership-owner reconciliation). The required-presence guarantee moves to a record-level invariant — *exactly-one-of* {`project_owner` ref, `project_owner_external`} populated (additive: the ref is the new primary, the external fallback preserves non-roster people). Surface RE-FROZEN with this amendment.

#### 2. Milestone

**Rationale & first-class justification.** A dated delivery checkpoint within a project. First-class because it carries its own operational state machine distinct from the project's, is the target of `BLOCKS` edges from RAID Items, and is independently reported by `weekly-status-rollup`. Not an attribute of Project — many Milestones per Project, each with its own target/actual date and state.

- **Fields:** `milestone_name`✅ str·1 · `project_id`✅ ref·1 · `target_date`✅ date·1 · `actual_date`⚪ date·1
- **Axis-1:** `planned → in-progress → completed | cancelled`
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `release-planner` · maintains `delivery-engine` · readers: `ppm-agent`, `weekly-status-rollup`

#### 3. Workstream

**Rationale & first-class justification.** A parallel stream of work within a project (e.g., "Data Migration", "Cutover"). First-class because it groups milestones/resources under a lead and has its own `active→paused→closed` lifecycle; it is computed/derived from project structure but tracked as a record so status can be segmented per stream.

- **Fields:** `workstream_name`✅ str·1 · `project_id`✅ ref·1 · `lead_person_id`⚪ ref·1
- **Axis-1:** `active → paused → closed`
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** computed
- **Owning agents:** creates `ppm-agent` · maintains `ppm-agent` · readers: `delivery-engine`, `daily-status`

#### 4. Plan

**Rationale & first-class justification.** A baselined planning artifact (cutover plan, test plan, comms plan, etc.). First-class because it is the canonical Domain-A **Baselined** content pattern — versioned, approved, and superseded as a unit; the `SUPERSEDES` self-edge is itself a first-class relationship. `plan_type` is a required **OPEN discriminator** whose **value domain is resolved at v3.34, ADR-059** — registry in `entity-field-schemas.md` §3.4a (the 6 go-live subtypes + an extension slot); correct WHAT/HOW split — the field exists and is required now; its membership is registry-governed.

- **Fields:** `plan_title`✅ str·1 · `plan_type`✅ string-discriminator·1 *(OPEN; registry resolved at v3.34 — `entity-field-schemas.md` §3.4a)* · `project_id`✅ ref·1 · `version`⚪ str·1 · `supersedes_plan_id`⚪ ref·1
- **Axis-1:** `draft → approved → active → superseded → archived` (= Domain-A Baselined machine)
- **Axis-2:** Baselined (A) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** file-backed
- **Owning agents:** creates `artifact-generator` · maintains `ppm-agent` · readers: `implementation-planner`

#### 5. Decision

**Rationale & first-class justification.** A recorded decision with rationale and decider. First-class because it is an immutable Baselined record generated by Meetings and assigned to a Person; decisions must be queryable independently of the meeting that produced them (audit + traceability).

- **Fields:** `decision_statement`✅ str·1 · `decided_date`✅ date·1 · `project_id`✅ ref·1 · `decision_maker_person_id`⚪ ref·1 · `rationale`⚪ str·1
- **Axis-1:** `proposed → accepted → reversed | superseded`
- **Axis-2:** Baselined (A) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `ppm-agent` · maintains `tracker-manager` · readers: `comms-writer`, `weekly-status-rollup`

#### 6. RAID Item

**Rationale & first-class justification.** A Risk, Assumption, Issue, or Dependency tracked on a project. First-class because each carries its own owner, severity, business `impact`, `action_plan`, and operational lifecycle, and `BLOCKS` Milestones — it is the core risk-management record, not a row attribute of a tracker. **Amended per [SCOPE CHANGE — RESOLVED via Option A] (2026-05-16, Tier-2):** `impact` and `action_plan` are now first-class entity fields (`impact` is irreducible primary DATA per the boundary axiom; modeling it as a CSV-only column would trap queryable portfolio data in the anti-pattern this initiative eliminates). RAID Item surface **RE-FROZEN** with this amendment as of 2026-05-16.

- **Fields:** `raid_type`✅ enum{Risk,Assumption,Issue,Dependency}·1 · `summary`✅ str·1 · `project_id`✅ ref·1 · `owner_person_id`✅ ref·1 · `severity`⚪ enum·1 · `target_date`⚪ date·1 · **`impact`✅ str·1** *(Option-A amendment — business impact if realized/unresolved; legacy RAID Log Tracker 5 = Required; irreducible primary DATA)* · **`action_plan`⚪ str·1** *(Option-A amendment — what is being done about it; legacy conditionally-required)*
- **Axis-1:** `open → in-progress → mitigating → resolved → closed`
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `ppm-agent` · maintains `tracker-manager` · readers: `daily-status`, `weekly-status-rollup`

#### 7. Meeting

**Rationale & first-class justification.** A scheduled or held project meeting. First-class because it is the `GENERATES` source for Decisions, RAID Items, and Artifacts (the meeting → decision-package chain at entity granularity); tracked independently with attendees and date so generated records trace back to their origin.

- **Fields:** `meeting_title`✅ str·1 · `meeting_date`✅ date·1 · `project_id`✅ ref·1 · `attendee_person_ids`⚪ ref·0..*
- **Axis-1:** `scheduled → held | cancelled`
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `file-router` · maintains `ppm-agent` · readers: `ppm-agent`

#### 8. Resource

**Rationale & first-class justification.** A Person's *project-scoped allocation* (role + allocation %). First-class because it is the join entity between a global Person and a Project — distinct from Person (global identity, `_pmo/`) and from Cross-Project Resource Conflict (portfolio-level contention). This three-entity decomposition (Stage-5 Finding 3) keeps each entity single-responsibility and matches the roster's tiering; collapsing them into one fuzzy "resource" concept is the modeling error it prevents.

- **Fields:** `person_id`✅ ref·1 · `project_id`✅ ref·1 · `allocation_pct`✅ int·1 · `role_on_project`✅ str·1 · `period_start`⚪ date·1 · `period_end`⚪ date·1
- **Axis-1:** `planned → active → released`
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `delivery-engine` · maintains `delivery-engine` · readers: `weekly-status-rollup`

**Activation — people-roster join.** Resource's `person_id` join — previously defined but wired to nothing — is activated against the operator-instance people-roster: a Resource (project-scoped allocation) resolves its Person through `person_id`, and the roster supplies the functional/coverage view that makes "who is allocated, and who covers them" answerable. No Resource field changes; the roster is the functional read surface the join now resolves against.

#### 9. Artifact

**Rationale & first-class justification.** A project deliverable file (report, tracker, FDD, design doc, etc.). First-class because it is the explicit **reconciliation seam** to `frontmatter-schema.md`: its `domain` + `content_lifecycle_pattern` bind the entity to a backing file's Domain A/B/C lifecycle. Its Axis-1 *delegates to Axis-2* — the Artifact's operational lifecycle **is** the Domain A/B/C content lifecycle of its backing file. G3/G4 must honor this seam when physicalizing.

- **Fields:** `artifact_title`✅ str·1 · `artifact_type`✅ enum·1 *(values = `frontmatter-schema.md` Type Taxonomy — referenced, not redefined)* · `project_id`✅ ref·1 · `domain`⚪ enum{A,B,C}·1 · `version`⚪ str·1
- **Axis-1:delegates to Axis-2** — `lifecycle_state` mirrors `frontmatter-schema.md §Cat-2` for the backing file's domain (the seam)
- **Axis-2:inherits per file** (A/B/C — reconciliation seam) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** file-backed
- **Owning agents:** creates `artifact-generator` · maintains `ppm-agent` (route: `file-router`) · readers: all PMO skills

### Cross-project shared entities (live in `_pmo/`)

#### 10. Person

**Rationale & first-class justification.** A global human identity (cross-project). First-class because it is the single source of identity that Resources, Decisions, RAID Items, and Conflicts reference; lives in `_pmo/` so one person is not duplicated per project (the deduplication anchor for all human references).

- **Fields:** `full_name`✅ str·1 · `person_id`✅ str(global)·1 · `primary_role`✅ str·1 · `email`⚪ str·1
- **Axis-1:** `active → inactive`
- **Axis-2:** Living (B) · **storage_tier:** cross-project-shared → `_pmo/` · **persistence_mode:** file-backed
- **Owning agents:** creates `project-initiator` / `file-router` · maintains `ppm-agent` · readers: all PMO skills

**Operationalization — functional people-roster (ADR-018 declarative config-layer).** Person is operationalized for functional coordination via an operator-instance people-roster: a declarative YAML config-layer keyed on `person_id` (the §3.10 dedup anchor) carrying functional attributes — preferred name + spelling, role(s), team, capability tags, backup/coverage, comms-calibration, escalation-routing — WITHOUT amending the 4 frozen Person fields and without adding an entity (the ADR-018 thin-entity dividend: attribute variability lives in the separate declarative layer). The filled roster is operator-instance and never committed: out-of-tree placement is the primary protection — it lives outside the repository tree, so a repository commit cannot reach it — with the `.gitignore` `**/people-roster.yaml` rule as a stray-copy backstop and the PII pre-commit needle list (fed by `core/deploy/extract-roster-needles.sh`) as a third layer; only a de-identified template ships. Reading contract (honored, not runtime-enforced): the roster is a functional coordination artifact, not an HR/performance system — read only the closed allow-list fields, express capability as tags never ratings, and represent an unknown value as `unknown` rather than inferring it. The capability/coverage graph (who-does-what / who-covers-whom / coverage-by-capability) composes this Person entity with the Resource entity (§4) and this functional roster at read time, keyed on `person_id` — see [`people-coverage-graph.md`](people-coverage-graph.md). That composition reads the three sources and adds no frozen field to either entity.

#### 11. System

**Rationale & first-class justification.** A technical system relevant to projects (ERP, data platform, integration bus, etc.). First-class cross-project record with its own `active→deprecated→retired` lifecycle, read by `pmo-technical-analyst`; shared so system facts are not re-stated per project.

- **Fields:** `system_name`✅ str·1 · `system_id`✅ str·1 · `system_owner_person_id`⚪ ref·1
- **Axis-1:** `active → deprecated → retired`
- **Axis-2:** Living (B) · **storage_tier:** cross-project-shared → `_pmo/` · **persistence_mode:** file-backed
- **Owning agents:** creates `ppm-agent` · maintains `ppm-agent` · readers: `pmo-technical-analyst`

#### 12. Vendor

**Rationale & first-class justification.** An external vendor / supplier. First-class cross-project record (`active→inactive`) read by `change-management`; shared identity like Person so vendor facts and contacts are not duplicated per project.

- **Fields:** `vendor_name`✅ str·1 · `vendor_id`✅ str·1 · `vendor_category`⚪ str·1 · `primary_contact_person_id`⚪ ref·1
- **Axis-1:** `active → inactive`
- **Axis-2:** Living (B) · **storage_tier:** cross-project-shared → `_pmo/` · **persistence_mode:** file-backed
- **Owning agents:** creates `ppm-agent` · maintains `ppm-agent` · readers: `change-management`

### Portfolio-level entities (live in `projects/_config/`)

#### 13. Portfolio

**Rationale & first-class justification.** The top-level grouping of programs/projects. First-class portfolio-level record (`active→archived`) that Projects `BELONG_TO`; the root of the portfolio → program → project hierarchy.

- **Fields:** `portfolio_name`✅ str·1 · `portfolio_id`✅ str·1 · `portfolio_owner`⚪ ref·1 → `Person.person_id` · `portfolio_owner_external`⚪ str·1 *(external fallback — exactly-one-of {`portfolio_owner`, `portfolio_owner_external`}; Tier-2 SCOPE CHANGE — ADR-040)*
- **Axis-1:** `active → archived`
- **Axis-2:** Living (B) · **storage_tier:** portfolio-level → `projects/_config/` · **persistence_mode:** file-backed
- **Owning agents:** creates `weekly-status-rollup` · maintains `weekly-status-rollup` · readers: `ppm-agent`

**Amended per [SCOPE CHANGE — RESOLVED via ADR-040] (functional-people-graph, Tier-2):** `portfolio_owner` lifted from `string` to `ref → Person.person_id` + an optional `portfolio_owner_external` free-text fallback for non-roster owners (leadership-owner reconciliation). The required-presence guarantee moves to a record-level invariant — *exactly-one-of* {`portfolio_owner` ref, `portfolio_owner_external`} populated (additive). Surface RE-FROZEN with this amendment.

#### 14. Program

**Rationale & first-class justification.** A grouping of related projects within a portfolio. First-class because it has its own owner and `active→closing→closed` lifecycle and is the `BELONGS_TO` target for Strategic Initiatives' generated work — the mid-tier of the portfolio hierarchy.

- **Fields:** `program_name`✅ str·1 · `program_id`✅ str·1 · `portfolio_id`✅ ref·1 · `program_owner`⚪ ref·1 → `Person.person_id` · `program_owner_external`⚪ str·1 *(external fallback — exactly-one-of {`program_owner`, `program_owner_external`}; Tier-2 SCOPE CHANGE — ADR-040)*
- **Axis-1:** `active → closing → closed`
- **Axis-2:** Living (B) · **storage_tier:** portfolio-level → `projects/_config/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `weekly-status-rollup` · maintains `weekly-status-rollup` · readers: `ppm-agent`

**Amended per [SCOPE CHANGE — RESOLVED via ADR-040] (functional-people-graph, Tier-2):** `program_owner` lifted from `string` to `ref → Person.person_id` + an optional `program_owner_external` free-text fallback for non-roster owners (leadership-owner reconciliation). The required-presence guarantee moves to a record-level invariant — *exactly-one-of* {`program_owner` ref, `program_owner_external`} populated (additive). Surface RE-FROZEN with this amendment.

#### 15. Cross-Project Dependency

**Rationale & first-class justification.** A directed dependency between entities in different projects. First-class because it is a portfolio-level record (`open→satisfied|broken|waived`) with typed from/to refs — it belongs to neither project individually and must be tracked at the portfolio tier to be visible to cross-project rollups.

- **Fields:** `dependency_id`✅ str·1 · `from_entity_ref`✅ typed-ref·1 · `to_entity_ref`✅ typed-ref·1 · `dependency_kind`⚪ enum·1
- **Axis-1:** `open → satisfied | broken | waived`
- **Axis-2:** Living (B) · **storage_tier:** portfolio-level → `projects/_config/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `ppm-agent` · maintains `ppm-agent` · readers: `weekly-status-rollup`

#### 16. Cross-Project Resource Conflict

**Rationale & first-class justification.** Detected contention where ≥2 projects over-claim one Person. First-class portfolio-level record (`detected→acknowledged→resolved`); the third leg of the Person / Resource / Conflict decomposition (Stage-5 Finding 3) — keeps contention detection single-responsibility and separate from both global identity (Person) and project allocation (Resource).

- **Fields:** `conflict_id`✅ str·1 · `person_id`✅ ref·1 · `competing_project_ids`✅ ref·2..* · `over_allocation_pct`⚪ int·1
- **Axis-1:** `detected → acknowledged → resolved`
- **Axis-2:** Living (B) · **storage_tier:** portfolio-level → `projects/_config/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `delivery-engine` · maintains `delivery-engine` · readers: `weekly-status-rollup`

#### 17. Strategic Initiative

**Rationale & first-class justification.** A portfolio-level strategic thrust spanning programs. First-class because it is the only **Hybrid (C)** content-pattern entity (agent-drafted, human-ratified), `GENERATES` Programs, and tracks `proposed→active→completed|cancelled` at the strategy tier — distinct from the delivery tiers below it.

- **Fields:** `initiative_name`✅ str·1 · `initiative_id`✅ str·1 · `sponsor`⚪ ref·1 → `Person.person_id` · `sponsor_external`⚪ str·1 *(external fallback — exactly-one-of {`sponsor`, `sponsor_external`}; sponsors are the most-likely-external case; Tier-2 SCOPE CHANGE — ADR-040)* · `linked_program_ids`⚪ ref·0..* · `target_outcome`⚪ str·1
- **Axis-1:** `proposed → active → completed | cancelled`
- **Axis-2:** Hybrid (C — agent-drafted, human-ratified) · **storage_tier:** portfolio-level → `projects/_config/` · **persistence_mode:** file-backed
- **Owning agents:** creates `ppm-agent` · maintains `weekly-status-rollup` · readers: `comms-writer`

**Amended per [SCOPE CHANGE — RESOLVED via ADR-040] (functional-people-graph, Tier-2):** `sponsor` lifted from `string` to `ref → Person.person_id` + an optional `sponsor_external` free-text fallback for non-roster sponsors (leadership-owner reconciliation — a sponsor is often a legitimately external party, e.g. a client executive). The required-presence guarantee moves to a record-level invariant — *exactly-one-of* {`sponsor` ref, `sponsor_external`} populated (additive). Surface RE-FROZEN with this amendment.

### Work-item tier entity (added by Tier-2 SCOPE CHANGE — ADR-018)

#### 18. Work Item

**Rationale & first-class justification.** The generic delivery work-item beneath Milestone/Workstream — the finest unit of tracked work (the model previously bottomed out at Milestone). First-class because, by the boundary axiom ([§2](#2-scope--boundary-axiom): "a logical entity is a data record the PMO tracks"), a work-item instance IS a tracked record needing graph membership for referential integrity and container rollup; it is the `BELONGS_TO` source of the rollup edge that lets Milestone/Workstream status aggregate from its children. **Thin and stable by design (D1 hybrid):** the entity carries only a `work_item_type` discriminator + a polymorphic `parent_ref`; ALL kind/field variability (Story/Bug/Test/Task fields, per-kind readiness/done/gate criteria) lives in the separate declarative type-pack layer, so future kinds parameterize this entity and never amend the roster. `work_item_type`'s value domain is an EXTERNAL, OPEN registry (the declarative type layer) — deliberately not a frozen enum (the open-set property is why the type *set* cannot be a frozen-roster member while the generic *entity* can). Added by Tier-2 SCOPE CHANGE (ADR-018); roster RE-FROZEN at 18 with this addition.

- **Fields:** `work_item_type`✅ str·1 *(discriminator; value domain = the declarative type registry — `[ASSUMPTION–CONFIRM @ C2 type layer]`)* · `parent_ref`✅ typed-ref·1 *(polymorphic `BELONGS_TO` → Milestone.id OR Workstream.id)*
- **Axis-1:** `backlog → ready → in-progress → in-review → done | cancelled` (generic base machine; the C2 type-pack layer projects methodology labels + MAY add type-scoped sub-states over this base)
- **Axis-2:** Living (B) · **storage_tier:** project-scoped → `[Project]/` · **persistence_mode:** embedded-in-parent
- **Owning agents:** creates `intake-desk` · maintains `delivery-engine` · readers: `ppm-agent`, `daily-status`, `weekly-status-rollup`

## 5. Relationship Matrix

Directed adjacency. `Source → Target` reads "Source has an edge of `MVP type` to Target". The 7 MVP relationship types — `GENERATES` / `DEPENDS_ON` / `BLOCKS` / `SUPERSEDES` / `BELONGS_TO` / `RELATES_TO` / `ASSIGNED_TO` — and their cardinalities are **canonical in `frontmatter-schema.md §Category 4`** (and `document-ecosystem-design.md §4`); they are **referenced here, not redefined**. The 17 chains below instantiate `document-ecosystem-design.md §4`'s delivery-methodology chains at *entity* granularity (AC-3 requires ≥10); chains 1–16 are FROZEN Artifact 4, chain 17 (the Work Item rollup edge) was added by ADR-018.

### 5.1 Directed chains (FROZEN Artifact 4 — verbatim)

| # | Source → Target | MVP type | Cardinality |
|---|---|---|---|
| 1 | Project → Portfolio | `BELONGS_TO` | many:1 |
| 2 | Milestone → Project | `BELONGS_TO` | many:1 |
| 3 | Workstream → Project | `BELONGS_TO` | many:1 |
| 4 | Plan → Project | `BELONGS_TO` | many:1 |
| 5 | Plan → Plan | `SUPERSEDES` | 1:1 |
| 6 | Meeting → Decision | `GENERATES` | 1:many |
| 7 | Meeting → RAID Item | `GENERATES` | 1:many |
| 8 | Meeting → Artifact | `GENERATES` | 1:many |
| 9 | RAID Item → Milestone | `BLOCKS` | many:many |
| 10 | RAID Item → Person | `ASSIGNED_TO` | many:1 |
| 11 | Decision → Person | `ASSIGNED_TO` | many:1 |
| 12 | Resource → Person | `RELATES_TO` | many:1 |
| 13 | Cross-Project Dependency → Milestone | `DEPENDS_ON` | many:many |
| 14 | Cross-Project Resource Conflict → Person | `RELATES_TO` | many:1 |
| 15 | Program → Portfolio | `BELONGS_TO` | many:1 |
| 16 | Strategic Initiative → Program | `GENERATES` | 1:many |
| 17 | Work Item → Milestone | `BELONGS_TO` | many:1 |

### 5.2 Adjacency grid (expanded N×N view of the 17 directed chains)

Cell = MVP type of the edge `row → column`; blank = no frozen chain. (Entities with no frozen outbound/inbound edge omitted for compactness; the 17 chains above are authoritative — chains 1–16 are FROZEN Artifact 4, chain 17 is the ADR-018 Work Item rollup edge — this grid is a navigational view, not an expansion of scope.)

| Source ↓ \ Target → | Portfolio | Program | Project | Milestone | Plan | Decision | RAID Item | Artifact | Person |
|---|---|---|---|---|---|---|---|---|---|
| **Project** | BELONGS_TO | | | | | | | | |
| **Program** | BELONGS_TO | | | | | | | | |
| **Milestone** | | | BELONGS_TO | | | | | | |
| **Workstream** | | | BELONGS_TO | | | | | | |
| **Plan** | | | BELONGS_TO | | SUPERSEDES | | | | |
| **Meeting** | | | | | | GENERATES | GENERATES | GENERATES | |
| **Decision** | | | | | | | | | ASSIGNED_TO |
| **RAID Item** | | | | BLOCKS | | | | | ASSIGNED_TO |
| **Resource** | | | | | | | | | RELATES_TO |
| **Cross-Project Dependency** | | | | DEPENDS_ON | | | | | |
| **Cross-Project Resource Conflict** | | | | | | | | | RELATES_TO |
| **Strategic Initiative** | | GENERATES | | | | | | | |
| **Work Item** | | | | BELONGS_TO | | | | | |

> **Work Item rollup edge (chain 17, added by ADR-018, 2026-06-07).** `Work Item → Milestone BELONGS_TO many:1` is the directed rollup chain — status/progress aggregates *up* from work-item children to the container. It is the entity-graph realization of the entity's `parent_ref`. `parent_ref` is **polymorphic**: it also admits a Workstream parent. The Milestone rollup is the canonical/required frozen chain (the F3 rollup target); `Work Item → Workstream BELONGS_TO` is the *same edge type against the alternate polymorphic target*, covered by the field-level polymorphism and the cross-entity X-rule in `entity-field-schemas.md §4` (not enumerated as a second frozen chain — the frozen chains are illustrative common chains per AC-3 ≥10, not exhaustive).

## 6. Owning-Agent Matrix

Which skill **creates**, **maintains**, and **reads** each entity (FROZEN Artifact 5 — verbatim; skills verified present 2026-05-15). This is the authority that downstream automation (G8) and the interface layer (G9) consume to route entity reads/writes.

| Entity | Creates | Maintains | Primary Readers |
|---|---|---|---|
| Project | project-initiator | ppm-agent | all PMO skills |
| Milestone | release-planner | delivery-engine | ppm-agent, weekly-status-rollup |
| Workstream | ppm-agent | ppm-agent | delivery-engine, daily-status |
| Plan | artifact-generator | ppm-agent | implementation-planner |
| Decision | ppm-agent | tracker-manager | comms-writer, weekly-status-rollup |
| RAID Item | ppm-agent | tracker-manager | daily-status, weekly-status-rollup |
| Meeting | file-router | ppm-agent | ppm-agent |
| Resource | delivery-engine | delivery-engine | weekly-status-rollup |
| Artifact | artifact-generator | ppm-agent (route: file-router) | all PMO skills |
| Person | project-initiator / file-router | ppm-agent | all PMO skills |
| System | ppm-agent | ppm-agent | pmo-technical-analyst |
| Vendor | ppm-agent | ppm-agent | change-management |
| Portfolio | weekly-status-rollup | weekly-status-rollup | ppm-agent |
| Program | weekly-status-rollup | weekly-status-rollup | ppm-agent |
| Cross-Project Dependency | ppm-agent | ppm-agent | weekly-status-rollup |
| Cross-Project Resource Conflict | delivery-engine | delivery-engine | weekly-status-rollup |
| Strategic Initiative | ppm-agent | weekly-status-rollup | comms-writer |

## 7. Storage-Location Map

**Logical only.** `storage_tier` (3 tiers, frozen from the roster's own tiering) + `persistence_mode` (the conceptual hook G3/G4 physicalize). **No filename, file format, or frontmatter serialization is specified here** — physical layout is **G3 (PROJECT.md redesign) / G4 (`_pmo/` layout)** per the [boundary axiom](#boundary-axiom--project-data--file-ecosystem-548).

- `storage_tier ∈ { project-scoped → [Project]/ , cross-project-shared → _pmo/ , portfolio-level → projects/_config/ }`
- `persistence_mode ∈ { file-backed, embedded-in-parent, computed }` — the seam G3/G4 physicalize. `document-ecosystem-design.md §6` already proved entities split into source-file-backed (Project), embedded rows (RAID Item in a RAID Log), and computed (Workstream). No 18-roster entity is purely computed-only except Workstream's derivation posture; consistent with §6 placing Accountability *outside* the maintained set.

| # | Entity | storage_tier | persistence_mode | Axis-2 pattern |
|---|---|---|---|---|
| 1 | Project | project-scoped → `[Project]/` | file-backed | Living (B) |
| 2 | Milestone | project-scoped → `[Project]/` | embedded-in-parent | Living (B) |
| 3 | Workstream | project-scoped → `[Project]/` | computed | Living (B) |
| 4 | Plan | project-scoped → `[Project]/` | file-backed | Baselined (A) |
| 5 | Decision | project-scoped → `[Project]/` | embedded-in-parent | Baselined (A) |
| 6 | RAID Item | project-scoped → `[Project]/` | embedded-in-parent | Living (B) |
| 7 | Meeting | project-scoped → `[Project]/` | embedded-in-parent | Living (B) |
| 8 | Resource | project-scoped → `[Project]/` | embedded-in-parent | Living (B) |
| 9 | Artifact | project-scoped → `[Project]/` | file-backed | **inherits per file** (A/B/C — reconciliation seam to `frontmatter-schema.md`) |
| 10 | Person | cross-project-shared → `_pmo/` | file-backed | Living (B) |
| 11 | System | cross-project-shared → `_pmo/` | file-backed | Living (B) |
| 12 | Vendor | cross-project-shared → `_pmo/` | file-backed | Living (B) |
| 13 | Portfolio | portfolio-level → `projects/_config/` | file-backed | Living (B) |
| 14 | Program | portfolio-level → `projects/_config/` | embedded-in-parent | Living (B) |
| 15 | Cross-Project Dependency | portfolio-level → `projects/_config/` | embedded-in-parent | Living (B) |
| 16 | Cross-Project Resource Conflict | portfolio-level → `projects/_config/` | embedded-in-parent | Living (B) |
| 17 | Strategic Initiative | portfolio-level → `projects/_config/` | file-backed | Hybrid (C) |
| 18 | Work Item | project-scoped → `[Project]/` | embedded-in-parent | Living (B) |

## 8. Worked Examples

Three worked instances (AC-7) — Milestone, Person, Plan — transcribed verbatim from the FROZEN Stage-5 spec. Each shows the 7 Core fields + entity-specific fields + the two lifecycle axes + a relationship edge using a referenced MVP type.

### 8.1 Milestone

```yaml
id: acme-go-live
entity_type: Milestone
lifecycle_state: in-progress           # Axis 1 (Milestone machine)
content_lifecycle_pattern: Living      # Axis 2 → frontmatter-schema Domain B
owning_agent: delivery-engine
created_date: 2026-05-15
milestone_name: [PROJECT_KEY] Go-Live
project_id: acme-implementation
target_date: 2026-07-01
relationships:
  - type: BELONGS_TO                    # MVP type — frontmatter-schema §Cat-4
    target: acme-implementation
```

### 8.2 Person

```yaml
id: person-example
entity_type: Person
lifecycle_state: active                 # Axis 1 (Person machine)
content_lifecycle_pattern: Living       # Axis 2 → Domain B
owning_agent: ppm-agent
created_date: 2026-05-15
full_name: [OPERATOR_NAME]
person_id: person-example
primary_role: Senior TPM
storage_tier: cross-project-shared      # → _pmo/ (physical layout = G4)
```

### 8.3 Plan

```yaml
id: acme-cutover-plan-v2
entity_type: Plan
lifecycle_state: active                  # Axis 1 = Domain-A Baselined machine
content_lifecycle_pattern: Baselined     # Axis 2 → frontmatter-schema Domain A
owning_agent: artifact-generator
created_date: 2026-05-15
plan_title: [PROJECT_KEY] Cutover Plan
plan_type: cutover                       # OPEN discriminator — registered value (entity-field-schemas.md §3.4a; resolved at v3.34)
project_id: acme-implementation
version: "2.0"
supersedes_plan_id: acme-cutover-plan-v1
relationships:
  - type: SUPERSEDES
    target: acme-cutover-plan-v1
```

## 9. Cross-References

Per AC-6. This model **consumes** these sources by pointer (duplicate-source-discipline — vocabularies are named and linked, never re-defined here).

| Reference | Role relative to this model |
|---|---|
| [`schemas/project-schema.md`](../schemas/project-schema.md) | The **Project** entity (#1) ⊇ `PROJECT.md`. Its V1–V12 + worked-example-with-trace pattern is the per-entity template G2 extends. |
| [`schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) | **Persistence dialect.** §Category-2 = Domain A/B/C ↔ Baselined/Living/Hybrid (Axis-2 source). §Category-4 = the 7 MVP relationship types + `RelEdge` schema (referenced by [§3](#3-entity-core-schema) / [§5](#5-relationship-matrix)). §Type Taxonomy = Artifact `artifact_type` value domain. |
| [`document-ecosystem-design.md`](../disciplines/document-ecosystem-design.md) | §6 entity sketch is **formalized** by this doc at entity granularity. §4 delivery-methodology chains are instantiated at entity granularity by [§5](#5-relationship-matrix). §1 carries the Deep Research PMO grounding (C06/C07/C12/C17). |
| [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) | Project entity's `delivery_approach` enum (8 archetypes) + Custom Extension Protocol — the methodology classification a Project carries. |
| [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) | §2–§5 — the `<Object>-<State>` object-typed convention this model forward-binds to (Axis-1 naming); §3 is the registration target for the entity state-machine family (downstream G8 / G10 — flagged, not executed here). |
| the Two-Axis Entity Lifecycle ADR | The ratified architectural basis for the [two-axis lifecycle model](#two-axis-lifecycle-model). |
| Deep Research PMO **C06 / C07 / C12 / C17** | Entity-model grounding, surfaced via `document-ecosystem-design.md §1` (C12 = Baselined/Living/Hybrid content patterns; C06/C07/C17 = entity + relationship + portfolio modeling). |

---

### Handoff to downstream (G2–G10)

The roster ([§7](#7-storage-location-map) / Frozen Artifact 1), Entity Core ([§3](#3-entity-core-schema) / Frozen Artifact 2), and per-entity field lists ([§4](#4-entity-definitions-18) / Frozen Artifact 3, RAID Item Option-A-amended) are the **frozen derivation surface**. G2 writes V-style validation rules against exactly these fields (per the `project-schema.md` V1–V12 pattern); the G3-pilot derives `raid-log.schema.json` from the RAID Item field list (including `impact`/`action_plan`); G4/G5/G6 derive the inventory, template standard, and enforcement harness downstream. **The freeze is in effect — changes require reopening the establishing issue via a Tier-2 SCOPE CHANGE per the Inter-Stage Feedback Protocol.**
