---
title: PROJECT.md Schema
purpose: The canonical schema for PROJECT.md — the fields a project context file carries, consumed by the PROJECT.md-reading skills and the Methodology Awareness Protocol.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the PROJECT.md-reading skills (the §8 consumer table); OPERATIONS.md §Methodology Awareness Protocol; project-initiator; the role-skill wave; the §7 Entity-Seeding Protocol and any entity-grain validator resolving the Project record's §3b dialect
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
# PROJECT.md Schema

**Status:** Canonical
**Owner:** `../schemas/project-schema.md`
**Introduced:** methodology-parameterization-core (2026-04-24)
**Consumers:** the PROJECT.md-reading skills enumerated in the §8 consumer table (below) + `OPERATIONS.md § Methodology Awareness Protocol` + the future role-skill wave
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

**In scope.** All fields in the `PROJECT.md` frontmatter YAML block. Values, types, presence rules, and the reconciliation rules between legacy and new fields. The additions — `delivery_approach` and `custom_methodology_definition` — with full validation rules (V1-V24) and worked examples.

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

# External connector configuration — the per-project keys naming this project's
# external systems. Roster indexed at OPERATIONS.md § Connector Configuration;
# defined and validated HERE (V18-V24). All optional.
jira_project_key: string                   # OPTIONAL — Jira project key this project files to
jira_query_scope: string                   # OPTIONAL — JQL filter for backlog queries (opaque; not parsed)
confluence_space: string                   # OPTIONAL — Confluence space key
confluence_page_ids: [string, ...]         # OPTIONAL — governed Confluence page ids (may be [])
gdrive_folder: string                      # OPTIONAL — Google Drive folder id for transcript ingest
co_management_sharepoint_folder: string | null
                                           # CONDITIONAL — non-null iff dual_framing_enabled: true
co_management_smartsheet_id: string | null # CONDITIONAL — non-null iff dual_framing_enabled: true

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

# Per-space methodology split — NEW — optional space-scoped refinements of delivery_approach
operational_methodology: <archetype> | [A, B]
                                           # OPTIONAL — methodology governing the OPERATIONAL space
                                           # (PMO / project-delivery work). Single value from the 6
                                           # composable archetypes OR a 2-element array per the V2
                                           # array grammar (V16). Absent → the operational space
                                           # falls back to delivery_approach. Never Hybrid-literal
                                           # or Custom — see §4.
release_methodology: <archetype> | [A, B]
                                           # OPTIONAL — methodology governing the RELEASE space
                                           # (release-pipeline / SDLC work). Same grammar (V17);
                                           # absent → falls back to delivery_approach.

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

# Work-tracker routing — NEW — names the destination this project files to
work_tracker: string                       # OPTIONAL — the id of an operator.toml [trackers.<id>] destination
                                           # (e.g. work_tracker: work). Names WHERE work items for this project
                                           # are filed. Filing-resolution order: explicit operator selection >
                                           # this project's work_tracker > the `default` tracker. FAIL-CLOSED
                                           # (CD-1): once ANY [trackers.*] is declared, a private-scope project with
                                           # an UNSET work_tracker MUST NOT fall through to a public destination —
                                           # resolution fails closed (blocks / requires explicit selection) rather
                                           # than routing private-origin work to public. Absent + no [trackers.*]
                                           # declared → the back-compat single-GitHub default (zero operator action).

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
| `jira_project_key` | ⚪ Optional | — |
| `jira_query_scope` | ⚪ Optional | — |
| `confluence_space` | ⚪ Optional | — |
| `confluence_page_ids` | ⚪ Optional | — |
| `gdrive_folder` | ⚪ Optional | — |
| `co_management_sharepoint_folder` | ⚪ Conditional | non-null iff `dual_framing_enabled: true`; null-or-absent otherwise |
| `co_management_smartsheet_id` | ⚪ Conditional | non-null iff `dual_framing_enabled: true`; null-or-absent otherwise |
| `delivery_approach` | ✅ Always | — (new) |
| `custom_methodology_definition` | Conditional | ✅ iff `delivery_approach: Custom`; ❌ otherwise |
| `operational_methodology` | ⚪ Optional | when present: one of the 6 composable archetypes OR `[A, B]` per the V2 array sub-assertions (V16); absent → the operational space falls back to `delivery_approach` (new) |
| `release_methodology` | ⚪ Optional | when present: same grammar (V17); absent → the release space falls back to `delivery_approach` (new) |
| `deliverable_type` | ⚪ Optional (legacy) / ✅ Required (forward) | open enum: recognized class OR non-empty lowercase-kebab; additive on legacy files |
| `org_structure_type` | ⚪ Optional | default `functional` when absent (new) |
| `work_tracker` | ⚪ Optional | when present, must name a declared `operator.toml` `[trackers.<id>]` id; absent → routing falls back per the resolution order, fail-closed for a private-scope project when `[trackers.*]` are configured (new) |
| `team_roster` | ⚪ Optional | when present, every entry is `{person_ref → Person.person_id, role_on_project}`; refs only (new) |

### 3b. Entity-record block (the Project entity's persisted fields)

`PROJECT.md` is the backing file of the **Project** entity (`../disciplines/project-entity-model.md` §7 row 1 — `storage_tier: project-scoped → [Project]/`, `persistence_mode: file-backed`). This section is that entity's **persistence dialect**: which entity fields persist in this file's frontmatter, under which key names. It adds no field and redefines none — `entity-field-schemas.md` §3.1 remains the field and validation authority.

**Two records, one file, disjoint key sets.** A live `PROJECT.md` is simultaneously (a) a **node** in the file ecosystem, carrying the `frontmatter-schema.md` Category-1..6 keys that the node stamper writes, and (b) the **Project entity record**. The two are distinguished by key, never by parsing order:

| Concern | Key | Meaning | Written by |
|---|---|---|---|
| file axis | `lifecycle_state` | content maturity (`frontmatter-schema.md` Cat-2, per-domain enum) | the node stamper |
| entity axis | `status` | the Project entity's Axis-1 (`ACTIVE → CLOSING → CLOSED`) | this dialect |
| shared | `created_date` | when the file entered the ecosystem; the entity's `created_date` reads the same value | the node stamper — the entity dialect **never** writes it |
| shared | `id` | on an entity-backing file, `id` is the **entity** id (`entity-field-schemas.md` V-CORE-01), not the Cat-3 artifact id | this dialect |

**`status` is the Axis-1 carrier, and that is a structural fact rather than a local convention.** `../disciplines/project-entity-model.md` §4.1 states Axis-1 *"reconciles 1:1 with `project-schema.md status`"*, and `entity-field-schemas.md` V-PRJ-03 keys the rule on `status` and annotates it `= V-CORE-03 instance`. Project is the **only** entity in the 19-roster whose dialect renames the carrier, because it is the only entity whose backing file is also a stamped ecosystem node — the only one where a single `lifecycle_state` key would otherwise have to carry two enums at once. Portfolio (V-PORT-04) and Person (V-PER-05) key `lifecycle_state` directly, and their tiers carry no node frontmatter at all.

**`lifecycle_state` is still required on this file, and is not this dialect's to write.** V-CORE-03b (the D-42 presence guard) restates the frozen Core-7 requiredness independently of V-CORE-03, so renaming the carrier does not silently retire the field. On a `PROJECT.md` the key is supplied by the node stamper, which is why the entity seed is ordered **after** the node-frontmatter backfill rather than beside it: seeding a project whose file has not yet been stamped leaves V-CORE-03b unsatisfied through no fault of the seed.

**Persisted key set.** Required keys, each with its authority:

| Key | Rule | Source of truth |
|---|---|---|
| `id` | V-CORE-01 | the project folder slug, normalized per `../standards/artifact-naming-standard.md` |
| `entity_type` | V-CORE-02 | the literal `Project` |
| `status` | V-PRJ-03 (= V-CORE-03) | the file's existing inline `**Status:**` line, parsed per the rule below |
| `content_lifecycle_pattern` | V-CORE-04 | the literal `Living` (Project Axis-2 is `Living (B)` — a frozen per-entity constant, not a per-file judgement) |
| `owning_agent` | V-CORE-05 | the literal `ppm-agent` (the maintain side of the frozen owning-agent triplet) |
| `created_date` | V-CORE-06 | **not written** — discharged against the node-axis `created_date` already on the file |
| `lifecycle_state` | V-CORE-03b | **not written** — discharged against the node-axis value the stamper supplies |
| `project_name` | V-PRJ-01 | the project folder display name |
| `delivery_approach` | V-PRJ-04 | the file's own `delivery_approach:` when present; otherwise the `operator.toml` `[methodology].default_delivery_approach`, which that file states the file-level key overrides |
| exactly one of `project_owner` / `project_owner_external` | V-PRJ-02, V-PRJ-08 | see the owner rule below |
| `portfolio_id` | V-PRJ-05 (optional) | the seeded portfolio-tier record's `portfolio_id` |

**`relationships[]` is deliberately not persisted here.** V-CORE-07 is L2 / WARN-HEALTH, so omitting it leaves the record valid. Writing it would be actively harmful: `frontmatter-schema.md` Cat-4 defines `relationships[].target` as a reference to a **file**, resolved against the index's filename column, while V-CORE-07 requires `target` to resolve to an **entity**. Entity-id targets on a stamped node would therefore log a dangling-edge warning per edge on every index rebuild. The two FK obligations this dialect actually carries — V-PRJ-05 and V-PRJ-08 — are both scalar ref keys and are satisfied above. Reconciling the two target domains is a downstream automation concern, named here rather than silently inherited.

**Status parse rule.** `status` is derived from the file's existing inline `**Status:**` line, which the composed-index shape keeps inline for exactly this reason. Resolve it in three steps, in order:

1. **Take** the first whitespace-delimited token after the `**Status:**` label.
2. **Normalize** it: strip surrounding markdown emphasis and code markers (`` ` ``, `*`, `_`) and trailing punctuation, then upper-case. **This step is load-bearing, not tidying** — measured against the live corpus, every in-scope `PROJECT.md` writes the value inside backticks, so a first-token rule *without* normalization resolves **0 of 4** and the protocol would write no Project record at all. With normalization it resolves **4 of 4**.
3. **Require** membership in `{ACTIVE, CLOSING, CLOSED}`.

A compound value (a state token followed by a parenthetical or dash-qualifier) contributes its **leading token only**, and the qualifier is preserved untouched in the body line. A first token outside the enum is **not** coerced: the record is not written for that project, and the file is reported in the evidence record as an unresolved-status exclusion. No default is applied — V-PRJ-03 is L1, and guessing a lifecycle state is the No-invention breach this rule exists to prevent.

**Owner rule.** V-PRJ-02 requires exactly one of `project_owner` / `project_owner_external`, and V-PRJ-08 makes an unresolved `project_owner` **BLOCK-WRITE**. The dialect resolves this to `project_owner` = the operator's `person_id`, on the ground that the operator is the PMO owner of record for every project in their own operational corpus. `project_owner_external` is **never** written by a seeding run: its value is a named human, and writing engagement-derived personal data into the corpus is the exact hazard the one-Person cap exists to prevent. A project whose owner is genuinely someone else is an operator-supplied value, not a derived one.

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

### External connector keys — `jira_project_key` · `jira_query_scope` · `confluence_space` · `confluence_page_ids` · `gdrive_folder` · `co_management_sharepoint_folder` · `co_management_smartsheet_id`

These seven keys, together with `dual_framing_enabled` above, are the **per-project connector configuration**: the fields that name *which* external systems this project is mirrored against and *under what key there*. [`OPERATIONS.md § Connector Configuration`](../governance/OPERATIONS.md) carries the **name index** and a worked example; this section and V18–V24 are the **definitional home** — types, requiredness, conditional rules and validation are stated here and restated nowhere else.

**Every value in this group is opaque to the platform.** A connector key is passed through to the connector that reads it; it is never parsed into an identifier, split on a separator, or interpreted for meaning. A skill that needs a component of one asks the connector, never the string.

#### `jira_project_key`

Optional. The Jira project key this project files work items to (e.g. `PROJ`). Consumed by the Jira MCP connector when resolving this project's backlog. Opaque — never parsed into a prefix or a numbering scheme. Validated by **V18**.

#### `jira_query_scope`

Optional. A JQL fragment scoping backlog queries for this project (e.g. `Sprint >= 5`). **Opaque — the platform does not parse or validate it as JQL**; an invalid fragment surfaces as a connector-side query error, not a schema failure. Consumed by the Jira MCP connector. Validated by **V19**.

#### `confluence_space`

Optional. The Confluence space key holding this project's governed pages. Consumed by the Confluence MCP connector. Opaque. Validated by **V20**.

#### `confluence_page_ids`

Optional. A list of governed Confluence page ids — the pages this project publishes to or reads from (RAID view, FDD index, process flows). May be the empty list `[]`, which declares "Confluence is configured but no page is governed yet" and is distinct from absence. Each member is opaque. Consumed by the Confluence MCP connector and by the dual-format render path. Validated by **V21**.

#### `gdrive_folder`

Optional. The Google Drive folder id this project's transcripts are ingested from. Consumed by the Google Drive MCP connector and the transcript-ingest path. Opaque. Validated by **V22**.

#### `co_management_sharepoint_folder`

**Conditional on `dual_framing_enabled`.** The SharePoint folder holding the co-management artifacts when dual-framing is active. Non-null when `dual_framing_enabled: true`; `null` or absent otherwise — a non-null value with `dual_framing_enabled` false-or-absent is a defect, not a harmless leftover, because it declares a co-management surface the project is not co-managed on. Consumed by the Dual-Framing Bridge (`OPERATIONS.md § Dual-Framing Bridge`). Opaque. Validated by **V23**.

#### `co_management_smartsheet_id`

**Conditional on `dual_framing_enabled`**, with the identical shape as `co_management_sharepoint_folder`. The Smartsheet grid id carrying the co-managed milestone view. Consumed by the Dual-Framing Bridge and cited as this project's Smartsheet identity by [`c3-external-sync-path-b.md`](../standards/c3-external-sync-path-b.md). Opaque. Validated by **V24**.

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

### `operational_methodology` / `release_methodology`

Optional. The **per-space methodology split** — two space-scoped refinements of `delivery_approach` that let a project run different methodologies in different **spaces**: `operational_methodology` governs the **operational space** (PMO / project-delivery work — the operations-module consumer surface); `release_methodology` governs the **release space** (release-pipeline / SDLC work — the release-module consumer surface). Each is a one-line declaration (e.g., Kanban-flow ops + stage-gated releases) with no drop to `Custom`. Carried from the Hybrid-Two design (v2.18), whose per-space half was deferred to this field pair (operator decision 2026-06-21).

**Value grammar (V16 / V17).** Each field, when present, is EITHER a single archetype from the 6 composable archetypes `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe}` OR a 2-element array `[A, B]` satisfying the V2 array sub-assertions (length == 2 · members distinct · each member ∈ the 6-set). The meta-archetypes are NOT valid per-space values: the bare `Hybrid` literal is a back-compat single-enum retained on `delivery_approach` only — a new field has no legacy files, so the explicit array is the only two-archetype declaration; `Custom` is excluded because `custom_methodology_definition` is a singular block keyed to `delivery_approach: Custom` (V3/V4) — a per-space Custom would require per-space definition blocks, a schema-level (v2) change per `methodology-parameterization-v1.md §8`. **A custom methodology still reaches a single space by composition:** declare `delivery_approach: Custom` + the block, and override the OTHER space's field (e.g., `release_methodology: Waterfall`) — the un-overridden space falls back to the Custom definition.

**Precedence — the space-scoped resolution contract.** For a consumer serving space S ∈ {operational, release}:

1. `<S>_methodology` present → the space-effective methodology is its value (a single archetype or `[A, B]`), consumed via `methodology-parameterization-v1.md §5` CASE 1 or CASE 1-ARRAY. A per-space value never resolves to CASE 2/3.
2. Absent → fall back to the project's `delivery_approach` (the full §5 branch set, including Custom via CASE 2/3).
3. `delivery_approach` itself resolves per the Config-Hierarchy Resolution Protocol (`default_delivery_approach`) where no project value applies — existing behavior, unchanged.

A consumer's space follows the module boundary by default: operations-module skills read `operational_methodology`; release-module skills and pipeline gates read `release_methodology`; project-wide consumers (portfolio rollups, cross-space audits) stay on `delivery_approach` and MAY surface the split as an annotation. A consumer never merges the two per-space values into a synthetic array and never silently substitutes a space it does not serve — the authoritative resolution step is [`methodology-parameterization-v1.md §5 Step 0`](../../release/references/specs/methodology-parameterization-v1.md#space-scoped-resolution). The intake methodology-resolution step (intake-desk) is an operational-space consumer under this contract.

**Composition with Hybrid-Two.** The fields compose with the array form: `delivery_approach: [Kanban, Waterfall]` classifies the project as running both archetypes; `operational_methodology: Kanban` + `release_methodology: Waterfall` assign which constituent governs which space — for space-scoped consumers this explicit assignment replaces the CASE 1-ARRAY contested-surface dominance heuristic (project-wide consumers keep the union rendering per `work-organization-mapping-framework.md §2.5`). The fields are deliberately NOT validated against `delivery_approach`'s constituents — a single-archetype project may override one space (e.g., `delivery_approach: Scrum` + `release_methodology: Waterfall`) without reclassifying as Hybrid; when both spaces diverge durably, the RECOMMENDED declaration is the explicit array plus both per-space fields (§6.7).

**Orthogonal to `dual_framing_enabled`** — same posture as `delivery_approach` (§7 Collision Check): the split is methodology classification only; co-management dual-framing remains the separate trigger.

### `deliverable_type`

Optional on legacy files, **required forward**. Names the **deliverable domain** — *what kind of work the project delivers* (a website build, an ERP customization, a code-review engagement, a governance corpus). **Open enum**, shape-validated (not a closed set): a recognized class — `software` | `governance` | `web` | `data` | `enterprise-platform` | `hardware` | `process` — OR a non-empty lowercase-kebab string for a domain not yet recognized, exactly mirroring `delivery_approach: Custom` openness. An unrecognized-but-well-formed value is itself the demand signal for authoring a domain guide (`core/standards/domain-best-practices/<x>.md`), per the Stage-4 expansion rule.

**Orthogonal to `delivery_approach`.** `deliverable_type` is *what is built*; `delivery_approach` is *how it is governed*. A `deliverable_type: software` project may run `delivery_approach: Scrum`, `Waterfall`, or any archetype — the axes combine freely. They are not redundant and neither implies the other.

**Authoritative source for the Stage-4 `domain:` label.** Where present, this field is the authoritative source the Stage-4 Planning `domain:` class field reads (`release/references/pipeline/stage-04-planning.md` § 5.7 — the field that field's forward-reference anticipated). Consumer skills and gate criteria branch on `deliverable_type` → the matching domain guide via the §5A Domain-Axis Consumption Pattern in [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md). `[SOURCE]` — `stage-04-planning.md` `domain:` forward-reference; the shipped intake-side domain representation consumes this enum.

#### Disambiguation — `deliverable_type` vs. the other `domain`-named concepts

The bare word `domain` is overloaded across the platform; `deliverable_type` is the deliberately **non-colliding** name for the deliverable-domain axis. This note fixes the boundaries once (modeled on the §7 `dual_framing_enabled`-vs-`delivery_approach` Collision Check):

**Scope of this note vs. the corpus index.** This note answers one question at its point of use — *why isn't this field called `domain`?* — and its final column is always the relation to `deliverable_type`. The corpus-wide index of **every** concept the bare token names, with each concept's owning file, value space and declaration pattern, is `core/specs/domain-token-registry.md`. Read this note to place `deliverable_type`; read the registry to resolve a `domain` found anywhere else.

| Concept | What it is | Where it lives | Relation to `deliverable_type` |
|---|---|---|---|
| **`deliverable_type`** | *What kind of deliverable a project produces* (project-level) | `project-schema.md` §3 frontmatter | — (this field) |
| `work_item_type` | *Declarative discriminator for a work-item kind* (story/task/bug/spike), the **domain-neutral methodology→hierarchy map** | `work-item-type-schema.md` | **Does NOT extend it.** Orthogonal: a `deliverable_type: software` project still contains `work_item_type: story` items. `deliverable_type` is a PROJECT-level frontmatter field; it is never a type-pack grammar entry (ADR-018 `core/`-independence kernel). |
| artifact-provenance `domain: source\|managed\|generated` | Three-domain artifact classification | `frontmatter-schema.md` Category 6 | **Distinct.** A per-artifact provenance tag, not a project-level deliverable class. |
| content-area `delivery/{domain}` | Obsidian content-area tag (`governance`/`design`/`testing`/…) | `frontmatter-schema.md` Tag Taxonomy | **Distinct.** A content-filing tag, not a deliverable class. |
| Stage-4 `domain:` class field | Abstract deliverable-domain signal consumed by the impact-analysis selector / guides / guide-index | `stage-04-planning.md` § 5.7 | **Consumes `deliverable_type`.** The Stage-4 field reads `deliverable_type` as its authoritative source where present (the reconciliation seam). |
| behavioral/domain predicate | An *adjective* naming a class of acceptance-criterion outcome — not a field at all | `gate-criteria-spec.md` G1-05a | **Distinct.** Never appears as a `domain:` key; a field-shaped probe never finds it. |
| template-provenance `domain: project\|software\|platform-internal` | Three-domain classification of a *template structure* by canon family and rendered-output audience | `template-protocol.md` § 4.2; rule at `template-taxonomy.md` § 2 | **Distinct.** Classifies a template, not a project or its deliverable. Value space is disjoint from every other row's. |
| K1 platform-doc `domain` | The subject domain an authored `core/**` reference doc belongs to | `platform-doc-frontmatter-standard.md` § 6 | **Distinct.** Says what a *document is about*; `deliverable_type` says what a *project builds*. Shares most of its live values, which is why the two are confusable. |

Renaming the shipped artifact-provenance and content-area `domain` fields is **pre-existing naming-debt, OUT OF SCOPE** for this axis — flagged separately per ADR-050, and indexed rather than migrated by the registry named above.

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

### `work_tracker`

Optional (introduced by the multi-destination work-tracker capability). Names the **work-tracker destination** this project files work items to — a string that must match the id of a declared `operator.toml` `[trackers.<id>]` subtable (e.g. `work_tracker: work` → `[trackers.work]`). It is the project-altitude routing pointer for the multi-destination tracker model; the tracker's `platform` / `identifier` / `scope` are read from `operator.toml`, never restated here (compose, never copy).

**Filing-resolution order (the routing read path).** A skill that files a work item resolves the destination by: **(1)** an explicit operator selection for this filing, else **(2)** the active project's `work_tracker`, else **(3)** the `default` tracker (`[trackers].default_id`, or the single back-compat destination derived from `[adapters].ticketing`).

**Fail-closed default (CD-1).** Once ANY `[trackers.*]` is declared, resolution is fail-closed for a private-scope project: a project whose scope is private (or unknown) with an UNSET `work_tracker` MUST NOT fall through to a `scope: public` destination — resolution blocks or requires an explicit selection rather than routing private-origin work to public. When NO `[trackers.*]` are declared at all, resolution uses the back-compat single-destination default (today's single-GitHub behavior, zero operator action).

**Consumer use.** `operations/skills/intake-desk/SKILL.md` (the concrete filing driver) reads this field on its create path; `core/hooks/block-scope-segregation.sh` is the filing-time enforcing backstop (refuses private/PII-marked content to a `scope: public` destination). Downstream filing consumers adopt the same resolution rule when their create path is next touched. `[SOURCE]` — the multi-destination-tracker Stage-5 Solutioning DD-6 + A6.5 CD-1.

### `team_roster`

Optional. A list of project-team membership entries — the **project-record-level projection** of "who is on this project's team" into the people-graph. Each entry is a 2-field object:

| Sub-field | Required | Type | Semantics |
|---|---|---|---|
| `person_ref` | ✅ | `ref → Person.person_id` | Resolves to a roster Person (the `person_id` deduplication anchor, ADR-040). Refs **only**. |
| `role_on_project` | ✅ | string | The person's role on THIS project (e.g., `Tech Lead`, `BA`, `QA`). |

**Compose-not-duplicate (load-bearing).** `team_roster` is an **index into** the people-graph, not a copy of it. An entry resolves to a `person_id`; capability, coverage, allocation %, and identity (`full_name`, `primary_role`) are **read through** the ref against Person / Resource / the operator-instance roster (`people-coverage-graph.md` three-query view) — **never copied inline**. An entry MUST NOT carry an inline `name`, `full_name`, `allocation_pct`, capability tags, or any Person/Resource attribute. The discriminating test: *entry resolves to a `person_id` (compose ✅) vs. carries its own person attributes (duplicate 🟥)*. Inlining a name forks the never-committed roster — a **PII-commit hazard** (the roster is operator-instance and never committed; an inline name in a tracked schema file leaks it) — and duplicates the frozen Resource entity (`{person_id, project_id, allocation_pct, role_on_project}`, `project-entity-model.md` §4 Resource entity).

**Relationship to Resource.** `role_on_project` intentionally mirrors the Resource field of the same name. `team_roster` is the **lightweight project-record membership list** (who is on the team, by ref); Resource is the **frozen allocation entity** (the same membership PLUS `allocation_pct` / period). They are two projections of the one `person_id` identity — `team_roster` is the PROJECT.md-frontmatter-level index; Resource is the entity-model-level allocation record. `team_roster` does NOT re-model Resource; it references the same people. (Re-modeling team membership as a new entity would touch the frozen 18-entity model → Tier-2 SCOPE CHANGE — explicitly out of scope.)

**Seed path (`team_roster` is the target end-state; the `## Key People` prose path is a retained fallback).** `team_roster` is the **target end-state** for the free-text `## Key People` markdown table (`operations/templates/project-md-template.md`, columns `Person | Role | Comm Style / Notes`) — it is the **primary** path, not a completed replacement, and the prose path is **not migration debt**. The free-text path is **deliberately retained as the fallback** per `core/standards/sior-escalation-protocol.md` § Decision-Owner Mapping and **ADR-025 §5 (`status: Accepted`)**: decision-owner resolution reads the Stakeholder Register when a project maintains one and falls back to the `## Key People` prose — plus the warn-and-route-to-PgM terminal case — when it does not. That fallback is the ratified graceful degradation for a project with no register, so a consumer reading `## Key People` is **implementing a two-path resolution, not depending on a stale surface awaiting repair**. Migration seeds each prose row into a `team_roster` entry by **resolving the `Person` cell by name against the people-roster** to a `person_id` (the same resolve-by-name migration ADR-040 defines for `project_owner`): a unique match becomes the `person_ref`; the prose `Role` cell becomes `role_on_project`; zero or ambiguous (≥2) matches route to the operator clarification queue (`people-coverage-graph.md` §3.2), never silently dropped. Comm-style notes are functional-roster attributes (read through the ref), not copied into `team_roster`.

**Reconciliation with the Stakeholder Register.** `team_roster`, the Stakeholder Register, and the frozen Resource entity are **three distinct projections of one `person_id` identity** — they join on the same anchor and MUST NOT be conflated. `team_roster` = **team membership** (who is on the delivery team). Stakeholder Register = **engagement** (interest/influence/desired-engagement + decision authority, for stakeholders who may NOT be team members). Resource = **allocation** (membership + allocation %). A person can be in all three, one, or any combination; each answers a different question. Keep the schemas consistent by keying all three on `person_id`; do not merge them. `[SOURCE]` — Stakeholder Register schema (joins on `person_id`); ADR-040 (`person_id` anchor).

## 5. Validation Rules

Twenty-four rules governing schema conformance. Enforcement level `structural (auto)` means the rule is machine-verifiable from the frontmatter alone — no human judgment required. `[AC-R2]` annotations indicate the rule operationalizes the Stage-5-locked AC-R2.

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
| **V16** | `operational_methodology`, when present, is EITHER (a) a single value in `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe}` (case-sensitive, title-case — the 6 composable archetypes; the meta-archetypes `Hybrid` and `Custom` are NOT valid per-space values), OR (b) a 2-element YAML sequence `[A, B]` satisfying the V2 array sub-assertions (V2-a length == 2 · V2-b members distinct · V2-c each member ∈ the 6-set). Absent is valid — the operational space falls back to `delivery_approach` (§4). | skill branch | structural (auto) |
| **V17** | `release_methodology`, when present, follows the identical grammar as V16 (single value ∈ the 6-set OR a 2-element `[A, B]` per the V2 array sub-assertions; meta-archetypes excluded). Absent is valid — the release space falls back to `delivery_approach` (§4). | skill branch | structural (auto) |
| **V18** | `jira_project_key`, when present, is a non-empty string. Absent is valid. | skill branch | structural (auto) |
| **V19** | `jira_query_scope`, when present, is a non-empty string (an opaque JQL fragment — **not** parsed or validated as JQL). Absent is valid. | skill branch | structural (auto) |
| **V20** | `confluence_space`, when present, is a non-empty string. Absent is valid. | skill branch | structural (auto) |
| **V21** | `confluence_page_ids`, when present, is a list of non-empty strings (may be `[]`). Absent is valid. | skill branch | structural (auto) |
| **V22** | `gdrive_folder`, when present, is a non-empty string. Absent is valid. | skill branch | structural (auto) |
| **V23** | `co_management_sharepoint_folder` is a non-empty string when `dual_framing_enabled: true`; `null` or absent otherwise. A non-null value with `dual_framing_enabled` false-or-absent is a defect (mirrors the V3/V4 conditional pair). | skill branch | structural (auto) |
| **V24** | `co_management_smartsheet_id` follows the identical conditional shape as V23. | skill branch | structural (auto) |

**V-table coordination note.** The `delivery_approach` array form (the Hybrid-Two `[A, B]` case) is validated by the **amended V2 (v2.18)** — it does NOT introduce a new V-rule. The `deliverable_type` deliverable-domain axis is defined by **V13** (appended to the V12 tail; no existing rule renumbered). The org-structure shape and the project-altitude people-graph index are defined by **V14 + V15** — `org_structure_type` (V14) and `team_roster` (V15) — appended to the post-V13 tail (see References). `delivery_model` is **not** a field — it resolves to the existing required `delivery_approach`, so no rule is added for it. The per-space methodology split is defined by **V16 + V17** — `operational_methodology` (V16) and `release_methodology` (V17) — appended to the post-V15 tail; their grammar reuses the V2 array sub-assertions by reference, and the meta-archetype exclusion keeps V3/V4 (Custom-block presence) keyed off `delivery_approach` only. The **external connector keys** are defined by **V18–V24** — `jira_project_key` (V18), `jira_query_scope` (V19), `confluence_space` (V20), `confluence_page_ids` (V21), `gdrive_folder` (V22), `co_management_sharepoint_folder` (V23), `co_management_smartsheet_id` (V24) — appended to the post-V17 tail; V23/V24 reuse the V3/V4 conditional-pair shape keyed off `dual_framing_enabled`, which keeps its own row and gains no new rule. No existing rule is renumbered.

### 5.1 Custom Block Completeness (operationalizes AC-R2)

When `delivery_approach: Custom`, the following fields MUST all be present and well-formed per their individual rules:

> `{name, base_archetype, derived_from, lifecycle, ceremonies, artifacts, cadence}`

That is: V3 (block presence) AND V5 (name non-empty) AND V6 (base_archetype enum-or-null) AND V7 (derived_from list) AND V8 (lifecycle enum) AND V9 (ceremonies non-empty) AND V10 (artifacts non-empty) AND V11 (cadence non-empty).

This block-completeness assertion is the single-test AC-R2 gate. Stage 8 QA runs it against the 3 worked examples in [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md) Custom row (all must PASS) and against 2 negative test cases (both must FAIL):

- Negative case 1 — `delivery_approach: Custom` with `cadence` missing → V11 FAIL → Custom Block Completeness FAIL.
- Negative case 2 — `delivery_approach: Custom` with `lifecycle: weekly` (invalid enum) → V8 FAIL → Custom Block Completeness FAIL.

### 5.2 Validation-failure handling

A PROJECT.md that fails any V1-V24 assertion is **malformed** (V13/V14/V15/V16/V17 join the malformed-file set with the same surface-the-failing-rule-ID + route-to-`project-initiator` Mode C handling; absence of an optional field — `deliverable_type` on a legacy file, `org_structure_type`, `team_roster`, `operational_methodology`, or `release_methodology` — is conformance per its rule, not a failure). Consumer skills encountering a malformed PROJECT.md MUST:

1. Refuse to produce methodology-parameterized output.
2. Surface the specific failing rule ID to the operator.
3. Route the file for correction via `project-initiator` (Mode C — schema repair) or manual edit.

Skills MUST NOT silently work around validation failures by defaulting to an archetype. Silent default is a named failure mode — see `methodology-parameterization-v1.md § Failure Modes` (PROC-2: Base-archetype blind fallback; PROC-3: Custom-block skip).

### References

- PROJECT.md-schema keystone: added the first-class `deliverable_type` deliverable-domain axis to the schema, defined by V13 (appended off the V12 tail). See ADR-050 for the placement + open-enum decision.
- Org-structure + team-roster expansion — adds the `org_structure_type` and `team_roster` fields to the schema (the org-structure shape + the project-altitude people-graph index), defined by the two V-rules after the keystone (**V14 + V15**). `delivery_model` is NOT added — it resolves to the existing required `delivery_approach`.
- Per-space methodology split — adds the optional `operational_methodology` + `release_methodology` space-scoped fields (the per-space half of the Hybrid-Two design, deferred from v2.18), defined by **V16 + V17** appended to the post-V15 tail. Value grammar reuses the V2 array sub-assertions by reference; the space-scoped resolution contract lives in §4 and `methodology-parameterization-v1.md §5 Step 0`. No existing rule is renumbered.

## 6. Examples

Six worked examples covering the representative cases. Each is a valid PROJECT.md frontmatter block that passes all V1-V24 assertions applicable to its `delivery_approach` value.

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

A balanced-matrix project declaring its org shape and a 3-member team by `person_id` ref. Both fields are additive — the example also passes all V1-V24 rules applicable to its `delivery_approach`.

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

### 6.7 Per-space split — Kanban-flow ops + stage-gated releases

A program running **two archetypes assigned to different spaces**: continuous Kanban flow in the operational space, gate-based Waterfall in the release space. The project-level classification is the Hybrid-Two array (both archetypes, per §6.5); the per-space fields assign which constituent governs which space.

```yaml
---
project_name: Managed Services Modernization
project_owner: p_patel_r
status: ACTIVE
delivery_approach: [Kanban, Waterfall]
operational_methodology: Kanban
release_methodology: Waterfall
---
```

**Validation trace:** V1 ✓ (field present), V2 ✓ — array branch: 2 elements (V2-a ✓), `Kanban ≠ Waterfall` (V2-b ✓), both members ∈ the 6-set (V2-c ✓). V3 N/A (not Custom), V4 ✓ (no block), V5-V12 N/A, **V16 ✓** (`Kanban` — single value in the 6-set), **V17 ✓** (`Waterfall` — single value in the 6-set).

**Space-resolution note.** An operational-space consumer resolves `Kanban` (WIP/flow primitives); a release-space consumer resolves `Waterfall` (phase-gate primitives); a project-wide consumer reads `[Kanban, Waterfall]` and renders the §6.5 union. The explicit per-space assignment replaces the CASE 1-ARRAY dominance heuristic for space-scoped consumers — the operator has declared which constituent governs which space. A fallback variant is equally valid: `delivery_approach: Scrum` + `release_methodology: Waterfall` alone leaves the operational space on `Scrum` (V16 N/A — absent) while the release space runs `Waterfall`.

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

The schema describes the **canonical forward-looking shape**. As of the composed-index redesign (ADR-060), that shape is a **thin composed wiki-link index** (≤50 lines): Methodology + Status stay **inline** (the §8 consumers parse them in place); People / Systems / Milestones / Plans / Workstreams become `[[wiki-link]]` lists into the `_pmo/` shared-entity pages and the typed plans, rather than inline tables. `project-initiator` Mode A scaffolds **new** projects in this shape (Step 3, `operations/templates/project-md-composed-index-template.md`). Migration of **existing** live PROJECT.md files is the gated, EXPENSIVE step (Migration Protocol below) — **not** auto-applied. Consumer skills read `delivery_approach` + `status` via the same parsing approach they use today (markdown key-value or YAML — whichever is present); because Methodology + Status remain inline, the composed-index shape is back-compatible with every §8 consumer. The schema is authoritative for:

- new PROJECT.md scaffolding (composed-index shape via `project-initiator` Mode A),
- any PROJECT.md migrated to the composed-index shape (per the protocol below),
- the semantic definition of fields regardless of serialization format.

### Composed-Index Migration Protocol (ADR-060 — gated, per-project)

Migrating a live PROJECT.md from the narrative-table monolith to the composed-index shape. **EXPENSIVE / gated per project** — the live ops tree (`projects/`) is git-ignored, so there is **no git rollback**; snapshot before, verify links after. Run the four steps in order, one project at a time:

- **M1 — Extract.** Read the live PROJECT.md end-to-end and extract the inline People / Systems / Milestones / Plans / Workstreams table rows into discrete entities. Snapshot the original to `08-Generated/_migration-snapshot/` (the pre-change copy — the only rollback path on the git-ignored tree).
- **M2 — Author / link `_pmo/` pages (with alias tracking).** For each extracted entity, author (or link to an existing) `_pmo/` page from the matching entity-page template (`operations/templates/{person,system,vendor,workstream,decision,dependency}-entity-template.md`). Dedup against the entity id (`person_id`, …); on any name variant, append to `aliases[]` (`people-coverage-graph.md §2.3`), never edit the id. Unresolved person names route to the clarification queue (never auto-create — `project-initiator` Step 2b).
- **M3 — Replace tables with wiki-link lists.** Swap the inline tables in PROJECT.md for `[[wiki-link]]` lists into the M2 pages + the typed plans. Keep Methodology + Status inline (consumer back-compat). Target the ≤50-line composed-index shape.
- **M4 — Verify links.** Confirm every wiki-link resolves to a real `_pmo/` page (Obsidian graph view shows project↔entity edges) and that every §8 consumer still parses Methodology + Status from the migrated file without error.

The POC project for the first migration is **decided at the Stage-12 gate** (not in Engineering); bulk migration beyond the POC is a gated follow-up.

### Entity-Seeding Protocol (ADR-138 — gated, per-tier)

Populating the operational corpus with conformant entity records so that entity-grain audits measure a real population rather than an empty one. **EXPENSIVE / gated** — the live ops tree is git-ignored, so there is **no git rollback**; the S1 snapshot is the only reversal path. A sibling of the Composed-Index Migration Protocol above: same tree, same gating posture, same snapshot-first discipline. Run S1–S6 in order.

- **S1 — Snapshot, verify, or halt.** Copy every file the run will touch to `[CLAUDE_WORKSPACE_ROOT]/.backup-pre-entity-seed-<YYYYMMDDTHHMMSSZ>/`, corpus-relative paths preserved, plus a JSON manifest recording each file's pre-existing frontmatter key set and a `RESTORE-ORDER` field (below). The timestamp is `date -u +%Y%m%dT%H%M%SZ`, matching the shipped `.backup-pre-*` convention — **a date-only suffix is forbidden**, because more than one snapshot per day is routine and a same-day collision destroys the only pre-write copy. **S1 refuses to run when the resolved directory already exists**; it never overwrites, because a second same-instant run would otherwise capture post-write state over the pre-write copy. Verify every copy at its path; any unverified write halts the run **before** any mutation.
- **S2 — Portfolio tier.** Author the Portfolio record at its program-scoped config home as a discrete file-backed record. Fields per `entity-field-schemas.md` §3.13. **Write the full per-tier key set enumerated below** — this tier is a non-project top segment for the node stamper, so **no node stamper ever writes here** and the seed is the only writer: `lifecycle_state` and `created_date` **MUST be written by the seed**, and its `lifecycle_state` is unambiguously the entity's Axis-1. **Target file: OPEN — an explicit operator decision, resolved at Stage 12** (see the per-tier enumeration).
- **S3 — Shared-entity tier.** Author the operator's Person record at the shared-entity home per §3.10, sourced from `operator.toml` (`operator_name` → `full_name`, `operator_role_title` → `primary_role`, `operator_email` → `email`). **Write the full per-tier key set enumerated below**, including `lifecycle_state` and `created_date`: §3.10's field table lists neither (both are inherited Core, surfaced nowhere in that section's own rows), so **an executor reading S3 alone gets no signal that they must be written** — and V-PER-05 / V-PER-06 / V-CORE-03 / V-CORE-03b are all **L1** on them. **Never auto-create a second Person** — ADR-058 §Decision 5 routes any unresolved person name to the operator clarification queue. This is both the governance rule and the only shape that keeps engagement-derived personal data out of the corpus. **Target file: OPEN — an explicit operator decision, resolved at Stage 12** (see the per-tier enumeration).
- **S4 — Project tier.** For each in-scope project, add the §3b key set to `PROJECT.md` frontmatter. **Add-absent-keys-only**: never overwrite an operator-supplied value, which is what makes a re-run a no-op. Write `lifecycle_state` **never** and `created_date` **never** — those two belong to the node stamper, and that exclusion is what keeps the two writers non-interfering. **This never-write exclusion is scoped to S4 ALONE**, precisely because a `PROJECT.md` is a stamped ecosystem node and the node stamper supplies both keys there. Nothing supplies them at S2 or S3.

**Per-tier key sets — enumerated, because a write set computed against the one tier that has a collision must never be generalised to the tiers that do not.** The Project tier's 9-key set is fully sourced in §3b. The other two tiers are enumerated here with each key's value source **or an explicit `UNSOURCED` marker**; an `UNSOURCED` key is an operator input at Stage 12, never a value the executor invents.

| Tier | Key | Value source | Class |
|---|---|---|---|
| **S2 Portfolio** | `id` | the portfolio slug, kebab-case per `artifact-naming-standard.md`; unique within `storage_tier` (V-CORE-01) | derived |
| | `entity_type` | literal `Portfolio` | constant |
| | `portfolio_name` | — | **UNSOURCED — operator input** `[ASSUMPTION – CONFIRM]` |
| | `portfolio_id` | — unique within the portfolio-level tier (V-PORT-02). **Not assumed equal to `id`**: the two uniqueness scopes are declared separately and no shipped surface equates them | **UNSOURCED — operator input** `[ASSUMPTION – CONFIRM]` |
| | `portfolio_owner` | the operator's `person_id`, seeded at S3 | FK, resolved in-run |
| | `portfolio_owner_external` | **not written** — V-PORT-03 is exactly-one-of, and `portfolio_owner` is populated | n/a by exclusion |
| | `content_lifecycle_pattern` | — | **UNSOURCED — operator input** `[ASSUMPTION – CONFIRM]` |
| | `owning_agent` | — no shipped surface names a maintaining agent for this record; ADR-138 declined to give the Portfolio record a declared producer | **UNSOURCED — operator input** `[ASSUMPTION – CONFIRM]` |
| | `lifecycle_state` | **seed-written** — Axis-1 `∈ {active, archived}` (V-PORT-04, L1). No node stamper reaches this tier | seed-supplied |
| | `created_date` | **seed-written** — the run date, ISO, ≤ today (V-PORT-05 = V-CORE-06 instance, L1) | seed-supplied |
| | `relationships[]` | not written — V-CORE-07 is L2 / WARN-HEALTH; the scalar refs carry the graph | deliberately absent |
| **S3 Person** | `full_name` | `operator.toml` `operator_name` | config |
| | `primary_role` | `operator.toml` `operator_role_title` | config |
| | `email` | `operator.toml` `operator_email` | config |
| | `person_id` | the operator's `person_id`; globally unique across the shared-entity tier (V-PER-02) | derived / operator-confirmed |
| | `id` | = `person_id` where the tier's uniqueness scopes coincide; **confirm rather than assume** | derived `[ASSUMPTION – CONFIRM]` |
| | `entity_type` | literal `Person` | constant |
| | `content_lifecycle_pattern` | — | **UNSOURCED — operator input** `[ASSUMPTION – CONFIRM]` |
| | `owning_agent` | — | **UNSOURCED — operator input** `[ASSUMPTION – CONFIRM]` |
| | `lifecycle_state` | **seed-written** — Axis-1 `∈ {active, inactive}` (V-PER-05, L1). §3.10's own field table does not list it; it is inherited Core | seed-supplied |
| | `created_date` | **seed-written** — the run date, ISO, ≤ today (V-PER-06 = V-CORE-06 instance, L1) | seed-supplied |
| | `relationships[]` | not written, as at S2 | deliberately absent |

**Scoped honestly rather than half-delivered.** The enumeration above is complete and is the FM3-1 mitigation. **Completing the *sourcing* is not a text fix** — six keys across the two tiers have no value source anywhere on this branch, and inventing one would violate no-invention. They are marked `UNSOURCED` and are **operator inputs collected at Stage 12 before S2/S3 run**, exactly as `project_owner` already is at S4. **S5 must assert each of them present and non-empty, or halt** — an `UNSOURCED` key silently defaulted is the failure this enumeration exists to prevent.

**Target files for S2 and S3 are an explicit operator decision, not an executor's invention.** `project-entity-model.md` §7 is *"logical only — no filename, file format, or frontmatter serialization is specified"*, and ADR-138's rejected-alternative 7 declines to give the Portfolio record a declared producer. Neither S2 nor S3 can therefore name its target file from any shipped surface. **Recorded as an explicit operator decision, resolved at Stage 12 before either step runs** — a Stage-12 executor must be handed the two filenames, never left to invent them. The homes are fixed (`projects/_config/` for S2, the shared-entity `_pmo/` home for S3 per §3.10); only the filenames are open.
- **S5 — Verify.** Assert per tier: record present, `entity_type` correct, every L1 rule for that entity satisfied (V-CORE-03 **and** V-CORE-03b), and each FK resolving to a record seeded in an earlier step. Report counts with denominators and a sensitivity arm proving the probe is live.
- **S6 — Record.** Emit the realized per-record added-key manifest, the resolved snapshot path, and a demonstrated restore-then-re-apply on at least one record. A snapshot whose restore has never been exercised is not a reversal mechanism.

**Scope.** `ACTIVE` and `CLOSING` projects only; `CLOSED` is read-only reference per `CLAUDE.md § Project Lifecycle`. Excluded projects are **accounted for** in the evidence record — by count and reason, never silently dropped.

**Tier order S2 → S3 → S4 is forced, not stylistic.** It follows FK direction: V-PRJ-08 is BLOCK-WRITE on an unresolved `project_owner`, so the Person record must exist before any Project record references it, and **V-PORT-06** makes an unresolved `portfolio_owner` **BLOCK-WRITE**, so the Portfolio record's own owner is the same target (**V-PORT-03** additionally requires exactly one of the two owner fields). Reordering produces records that are invalid at the instant they are written.

**Snapshot destination — why the workspace root.** The destination must survive every mover that could run between the snapshot and a restore. The `08-Generated/_migration-snapshot/` destination M1 names is excluded because the folder-taxonomy reshape renames that bin, and a reversal path the operation itself relocates mid-flight is not a reversal path. A project-root destination is excluded because this run's write set spans three tiers, two of which are not project roots. The workspace root is a shipped convention, and a dot-leading directory there is **structurally** invisible to the corpus iterator — which skips any dot-leading path segment — rather than merely policy-excluded.

**Restore ordering (load-bearing whenever two snapshots exist).** A release that runs both a node-frontmatter backfill and an entity seed leaves two pre-write snapshots over an overlapping file set, taken at different instants. They do not compose in either direction, so the order is fixed rather than inferred:

> The backfill's snapshot is **pre-seed**: restoring it after the seed has landed silently discards the seed on every shared file. The seed's snapshot is **post-backfill**: restoring it after a backfill restore re-applies the backfill. **LIFO only** — restore the seed's snapshot before the backfill's, and re-run S1–S6 after any backfill restore.

This rule is carried in the S1 manifest's `RESTORE-ORDER` field as well as here, because whoever performs a rollback on a git-ignored tree is reading the snapshot directory, not a tracked schema.

**Retention.** Snapshots are retained through the release's outcome window; deletion is **operator-only**. Nothing in the platform expires them — a deferred-cleanup residual rather than a guarantee, stated so that a future retention policy knows this directory exists.

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
| `file-router` | classification + the `## Routing Signals` section (Layer-2 project identification) | LOW | **Writer-side changed.** The scaffold now emits `## Routing Signals` — one line per Layer-2 category (Participants · Project keys · Systems · Terminology), carrying literal match terms. The Layer-2 **reader** still keys on the legacy section names, so reader repair is **owed as a named follow-on**: the mirror pair `operations/skills/file-router/SKILL.md` and `core/schemas/routing-rules.md`, both halves in one commit, plus the `file-router` package rebuild. This row is the registered seam for that contract — a change to the `PROJECT.md` shape that Layer 2 reads is recorded here so the writer↔reader cascade is discoverable rather than lost. |
| `pmo-qa-auditor` | skill-under-audit context | LOW | Unchanged (methodology-agnostic by design) |
| `pmo-process-designer` | project context | LOW | Unchanged |
| `implementation-planner` | release context | MEDIUM | Unchanged |
| `artifact-generator` | project context | LOW | Unchanged |
| the §7 Entity-Seeding Protocol | the inline `**Status:**` line (via the §3b parse rule) + `delivery_approach` + the §3b persisted key set | LOW | New — writes the §3b entity-record block; methodology-agnostic (it *carries* `delivery_approach`, it does not branch on it) |

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
