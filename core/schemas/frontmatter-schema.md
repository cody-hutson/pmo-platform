---
title: Frontmatter Schema — Document Ecosystem Metadata
purpose: Defines the Schema Layer of the document ecosystem — the entity model governing what the PMO tracks for operational K4 artifacts, their fields, valid relationships, and lifecycle states.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the document-ecosystem Storage Layer (frontmatter on operational K4 files); the SQLite index; file-router and health-check; platform-doc-frontmatter-standard.md (disjoint-population sibling)
---
<!-- reference-durability: allow-link -->
# Frontmatter Schema — Document Ecosystem Metadata

## Purpose

Defines the **Schema Layer** of the document ecosystem — the entity model that governs what the PMO tracks, what fields each entity has, what relationships are valid, and what lifecycle states apply. This is the source of truth for entity definitions. The Storage Layer (frontmatter on files, SQLite index) persists this schema. The Presentation Layer (Obsidian vault, Teams messages) renders it.

Frontmatter is the storage mechanism: YAML metadata that agents maintain on every file. The SQLite index is a disposable cache rebuilt from these fields.

**Predecessor:** Prototype evaluation (Phase 3) — proven fields: `type`, `managed_by`, `parent`, `health`, `phase`
**Grounding:** Design brief §9 (three domains), §14 (trust model), §15 (lifecycle model); C17 (12 relationship types, files-as-source-of-truth); C12 (three lifecycle patterns, artifact catalogs per gate); C02 (15-stage universal lifecycle)
**Three-Layer context:** See `document-ecosystem-design.md` §6 — this spec is the Schema Layer

## Consumers

| Consumer | Access | Purpose |
|----------|--------|---------|
| Agent skills (PPM Agent, File Router, Artifact Generator, etc.) | Read/Write | Maintain metadata during processing |
| SQLite index builder | Read | Rebuild index tables from frontmatter |
| Navigation layer generator | Read (via index) | Generate navigation pages from file metadata |
| Health check engine | Read (via index) | Validate completeness, consistency, freshness |
| QA Auditor | Read | Validate frontmatter contract compliance |

## Scope

- **Applies to:** all files in `projects/[Project]/01-08/` folders
- **Markdown files (.md):** embedded YAML frontmatter block (standard `---` delimiters)
- **Non-markdown files (.txt, .csv, .xlsx, .pdf, .docx, .html):** sidecar `.meta.yml` file (see Sidecar Specification below)
- **Exclusions:** navigation layer pages (`_pmo/`) have their own simplified frontmatter; governance files at `projects/_config/` are exempt (governed by CLAUDE.md tier system)
- **Generated-vs-source separation:** the `domain` (A/B/C, Category 6) and `folder` (`08-generated` vs `01-07`, Category 6) fields, together with the Domain-A-vs-Domain-C field split, are the schema's canonical generated-vs-source boundary — a generated artifact is `domain: C` + `folder: 08-generated`; a source artifact is `domain: A` + an `01-07` folder.

---

## Field Categories

Six categories. Every file has core fields (required across all domains). Domain-specific fields apply based on the file's `domain` classification.

### Category 1: Identity

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `type` | String | Yes | See Type Taxonomy below | File classification — what kind of artifact this is |
| `managed_by` | String | Yes | Skill name (e.g., `ppm-agent`, `file-router`, `artifact-generator`) | Which skill maintains this file's frontmatter |
| `parent` | String | Yes | Project name or workstream identifier | Hierarchical parent in the portfolio→program→project→workstream chain |

**Type Taxonomy:**

| Domain | Valid Types |
|--------|------------|
| A (Source) | `transcript`, `fdd`, `test-plan`, `email`, `export`, `presentation`, `spreadsheet`, `plan`, `process-map`, `architecture-diagram`, `training-material`, `reference` |
| B (Knowledge) | `tracker`, `project-page`, `decision-record`, `risk-register`, `dependency-register`, `status-log`, `communications-log`, `meetings-log`, `transcript-register` |
| C (Synthesis) | `executive-summary`, `decision-package`, `readiness-assessment`, `weekly-rollup`, `daily-status-output`, `processing-run`, `draft-communication`, `sop`, `runbook`, `analysis` |

### Category 2: Lifecycle

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `lifecycle_state` | String | Yes | Per-domain state sets (see below) | Current lifecycle state |
| `lifecycle_changed` | ISO Date | Yes | `YYYY-MM-DD` | Date of last state change |
| `lifecycle_trigger` | String | No | Free text | What caused the last state change (e.g., `human-approval`, `staleness-detection`, `source-modification`) |

**Lifecycle States by Domain:**

| Domain A (Source Artifacts) | Domain B (Managed Knowledge) | Domain C (Synthesized Intelligence) |
|-----------------------------|------------------------------|--------------------------------------|
| `created` | `created` | `draft` |
| `draft` | `emerging` | `validated` |
| `active` | `current` | `published` |
| `superseded` | `needs-review` | `stale` |
| `archived` | `stale` | `archived` |
| | `superseded` | |
| | `archived` | |

**Lifecycle pattern mapping (C12):**
- Domain A files follow the **Baselined Document** pattern (formal state changes, explicit approval)
- Domain B files follow the **Living Document** pattern (continuous updates, no formal baseline)
- Domain C files follow a **hybrid** pattern (agent-initiated states + human-gated promotion) — full protocol in `domain-c-lifecycle-protocol.md`

**Content-maturity vs. promotion-location (the two-concern separation).** `lifecycle_state` is the canonical **content-maturity** field — *how authoritative the content is* (this is the Artifact's Axis-1 delegation per `project-entity-model.md §4 entity 9`; `artifact_state` is **deprecated** as a content-maturity carrier, see `lifecycle-states-canonical.md §3.2`). A generated artifact's **promotion-location** — *where the file physically sits* (`08-Generated/` vs. its promoted `01-07` folder) — is a separate, orthogonal concern carried by the `promotion_state` Domain-C field (see § Domain C below), **not** by `lifecycle_state`. The two vary independently: a `published` artifact may still be `staged`. Full protocol: [`artifact-workflow-protocol.md`](../artifact-workflow-protocol.md).

### Category 3: Provenance

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `id` | String | No | Stable slug: `<type-slug>-<project-slug>-<YYYY-MM-DD>-<nn>` (e.g., `decision-package-acme-2026-04-09-01`) | A **stable, filename-independent** artifact identifier, assigned at generation and never changed on rename/move. Decouples addressability from `original_filename` so a back-link survives a rename and a **missing back-link is a detectable dangling edge** (a referrer cites an `id` that resolves to no artifact). Distinct from the SQLite `file_id` (a disposable cache key, rebuilt per index) and from the tracker-row entity `id` in [`entity-field-schemas.md`](entity-field-schemas.md) (which identifies a RAID/decision *row*, not a generated *file*). The structured `source_ref` tracker field + `relationships[]` edge population that consume this id are **out of scope here** (header field only). |
| `created_date` | ISO Date | Yes | `YYYY-MM-DD` | When the file entered the ecosystem |
| `created_by` | String | Yes | Person name or skill name | Who created or ingested this file |
| `source_system` | String | No | `teams`, `jira`, `email`, `confluence`, `manual`, `agent-generated` | Originating system |
| `original_filename` | String | No | Original filename | Preserved if file was renamed during routing |
| `generated_by` | String | No | `<skill-name> v<semver>` (e.g., `ppm-agent v6.3`) | The generating skill **plus its version** that synthesized this artifact **instance**. Distinct from `created_by`: `created_by` is *who* (person-or-skill name, no version) ingested/created the file; `generated_by` is the *versioned generator* of an AI-synthesized artifact, so a regression can be traced to the exact skill version that produced it. Recommended for any AI-derived artifact (Domain C in particular). Carries **dual semantics** across the template/instance boundary — see the dual-semantics note below. |
| `source_inputs` | Array | No | List of `TR-###` \| `MSG-###` \| source-file path strings | The list of **upstream human evidence** this artifact derives from — transcript-register IDs (`TR-###`), communication IDs (`MSG-###`), or source-file paths/filenames. The **cross-domain** provenance carrier (Domain A and Domain C); generalizes the Domain-C-only `synthesis_scope` (now its deprecated alias — see Domain C). Provenance scope (outward, to human evidence), distinct from the `parent_artifact` lineage edge (horizontal, to a generated artifact) — see Lineage Fields vs. Provenance Fields. |

### Category 4: Connections

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `relationships` | Array | No | Array of relationship objects (see below) | Explicit connections to other files |

**Relationship Object Schema:**

```yaml
relationships:
  - type: DEPENDS_ON           # One of the 7 MVP relationship types
    target: "target-filename"  # Filename (wiki-link compatible, no path)
    evidence: "SteerCo transcript 2026-03-15"  # What established this connection
    created_date: 2026-03-15   # When the relationship was identified
```

**MVP Relationship Types (7 of 12 from C17):**

| Type | Direction | Description | Example |
|------|-----------|-------------|---------|
| `GENERATES` | Source → Product | This file produced the target file | Transcript GENERATES decision-package |
| `DEPENDS_ON` | Dependent → Dependency | This file depends on the target for its validity | Test plan DEPENDS_ON FDD |
| `BLOCKS` | Blocker → Blocked | This file's state blocks progress on the target | Risk BLOCKS milestone |
| `SUPERSEDES` | New → Old | This file replaces the target file | FDD v2 SUPERSEDES FDD v1 |
| `BELONGS_TO` | Part → Whole | This file is part of the target entity | File BELONGS_TO project |
| `RELATES_TO` | Peer → Peer | General association without directionality | Risk RELATES_TO workstream |
| `ASSIGNED_TO` | Work → Person | This file is assigned to the target person/role | Action ASSIGNED_TO owner |

**Phase 2 expansion (not MVP):** `FOLLOWS_UP`, `PARTICIPATED_IN`, `ESCALATED_TO`, `AUDIENCE_OVERLAP`, plus 1 extension slot.

### Lineage Fields vs. Provenance Fields

The horizontal-lineage scalar fields (`parent_artifact`, `sibling_topic`, `supersedes`/`superseded_by`) record edges *between generated artifacts* so parent→child and supersede relationships survive the session that created them. They are distinct from provenance, which records the *upstream human evidence* an artifact derives from. The table below fixes the boundary so the two are never conflated.

| Field | Points to | Direction | Class |
|-------|-----------|-----------|-------|
| `source_inputs` | Upstream human evidence (transcripts, messages, source files) | Outward from the AI/agent system | Provenance |
| `parent_artifact` | Upstream generated artifact in the lineage graph | Horizontal within AI/agent outputs | Lineage |
| `sibling_topic` | Scope descriptor for strict-sibling dedup match | Lateral — disambiguates siblings | Lineage |
| `supersedes` / `superseded_by` | Sibling artifact in a dedup/version chain | Horizontal, temporal | Lineage |

**Field vs. verb (composition).** These lineage entries are **scalar frontmatter keys**, NOT `relationships[]` MVP-type verbs. They **compose against** the 7 MVP relationship types above rather than extending them: a `supersedes:` scalar denotes the same edge a `type: SUPERSEDES` relationship entry expresses, but is the lightweight per-artifact carrier. No new enum value is added and the 7-MVP-type constraint is unchanged.

**`source_inputs` scope note.** `source_inputs` is a separate **provenance** scope (upstream human evidence, outward) and is **not** part of this lineage field set; it is **defined as a Category 3 Provenance field** (see Category 3 above) and is referenced here only to fix the lineage-vs-provenance boundary.

**`generated_by` dual-semantics note.** `generated_by` is a **dual-semantics field name** shared with the L4 template schema in [`template-protocol.md`](../standards/template-protocol.md) §4.2/§8. **Here (the artifact-instance schema) it is the versioned generating skill of a Domain-C instance** (e.g., `ppm-agent v6.3`); **there (`operations/templates/`) it is the template-authoring skill OR operator name.** Same field NAME, scope-localized value — NOT a naming conflict. This note satisfies the both-locations flag mandated by `template-protocol.md` §8.2 **drift-prevention rule 5** ("Dual-semantics field names MUST be flagged in BOTH locations"), and closes the §4.2/§4.3/§8.1 forward-reference that names this instance-side field as its comparison anchor. File scope distinguishes the two populations: templates at `operations/templates/`; instances at `projects/*/08-Generated/`.

### Category 5: Trust

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `trust_category` | String | Yes | `evidence`, `controlled-truth`, `interpretation`, `working-context`, `historical-record` | Trust classification per design brief §14 |
| `evidence_quality` | String | No | `source`, `corroborated`, `inferred`, `assumed` | Evidence strength — extends existing evidence quality labels to file level |

**Trust Category Definitions (Brief §14):**

| Category | Meaning | Typical Domain | Example |
|----------|---------|---------------|---------|
| `evidence` | Original artifact or directly captured factual record | A | Transcript, signed-off design, export |
| `controlled-truth` | Explicitly accepted as current operational/governance view | B | Active RAID register, approved baseline, current scope |
| `interpretation` | Summary, comparison, analytical view, or inferred reasoning | C | Executive summary, impact assessment, contradiction analysis |
| `working-context` | In-progress or exploratory material not yet stabilized | A/C | Draft notes, scratch analyses, open questions |
| `historical-record` | No longer current but retained for audit trail or learning | A/B/C | Superseded designs, old summaries, closed project docs |

**Trust-lifecycle consistency rules:**
- `archived` lifecycle state requires `historical-record` trust category
- `draft` lifecycle state (Domain C) cannot be `controlled-truth`
- `published` lifecycle state (Domain C) can be `controlled-truth` if human-confirmed
- `superseded` lifecycle state shifts trust to `historical-record`

### Category 6: Classification

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `domain` | String | Yes | `A`, `B`, `C` | Three-domain classification (Brief §9) |
| `file_format` | String | Yes | `md`, `txt`, `csv`, `xlsx`, `pdf`, `docx`, `html` | File format for index queries |
| `project` | String | Yes | Project name | Project this file belongs to |
| `folder` | String | Yes | `01-governance`, `02-design`, `03-testing`, `04-operations`, `05-transcripts`, `06-emails`, `07-reference`, `08-generated` | Originating folder in the project structure |

### Category 7: Tags

Tags serve dual purpose: graph cluster anchors in Obsidian (green nodes that visually group related files) and search/filter targets. Applied by agents during processing, not manually by humans.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `tags` | Array of Strings | Yes | Hierarchical tag strings (see taxonomy below) | Obsidian-compatible tags for clustering and filtering |

**Tag Taxonomy:**

| Tag Pattern | Applied To | Purpose |
|-------------|-----------|---------|
| `project/{slug}` | All content files in a project | Primary cluster — separates projects visually |
| `delivery/{domain}` | Content files by area | Values: `governance`, `design`, `testing`, `operations`, `transcripts`, `comms`, `synthesis` |
| `artifact/{type}` | Content files by kind | Values: `transcript`, `design-doc`, `tracker`, `report`, `plan`, `email`, `export` |
| `status/{state}` | Content files by lifecycle | Values: `active`, `draft`, `stale`, `archived`, `validated` |
| `workstream/{slug}` | Files related to a workstream | By keyword matching during agent processing |
| `level/{pmo-level}` | Navigation pages only | Values: `portfolio`, `program`, `project`, `project-risks`, `project-phases`, `team` |

**Hierarchical behavior:** Obsidian's tag pane groups by prefix. `project/acme-implementation` creates a `project` parent and `project/acme-implementation` child. The parent connects all projects; the child connects one project's files.

**Agent application:** File Router assigns `project/`, `delivery/`, `artifact/` tags on intake. PPM Agent adds `workstream/` tags during processing. Navigation generator adds `level/` tags to nav pages.

---

## Domain-Specific Fields

### Domain A — Source Artifacts (01-07 folders)

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `approval_state` | String | No | `draft`, `under-review`, `approved`, `rejected` | Approval status for formal artifacts (plans, FDDs, test plans) |
| `version` | String | No | Semantic version `X.Y` | Version for baselined documents |
| `superseded_by` | String | No | Filename of replacing document | Points to the superseding file (if `lifecycle_state` = `superseded`) |
| `supersedes` | String | No | Filename of the document this one replaces | Backward inverse of `superseded_by` — points to the prior artifact this one supersedes in a dedup/version chain. Documented inverse pair with `superseded_by` (see Lineage Fields vs. Provenance Fields). Distinct from the `SUPERSEDES` relationship verb — this is a lightweight per-artifact scalar carrier, not a `relationships[]` entry. |
| `parent_artifact` | String | No | Path/filename of the upstream generated artifact | The upstream generated artifact in the lineage graph that this artifact derives from. Horizontal lineage within AI/agent outputs (distinct from `source_inputs` upstream human evidence — see Lineage Fields vs. Provenance Fields). |
| `sibling_topic` | String | No | Scope descriptor string | Topic/scope descriptor that groups strict siblings for dedup matching. Lateral disambiguator within a sibling set. Verbatim-aligned with `lifecycle-states-canonical.md §3.2`. |

### Domain B — Managed Knowledge (04-Operations trackers)

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `last_evidence_date` | ISO Date | No | `YYYY-MM-DD` | Date of the most recent evidence incorporated |
| `staleness_threshold_days` | Integer | No | Default: `14` | Days without new evidence before `needs-review` transition |
| `entry_count` | Integer | No | Positive integer | Number of active entries (for trackers) |

### Domain C — Synthesized Intelligence (08-Generated)

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| `trigger_source` | String | Yes (Domain C) | Filename or event description | What triggered this synthesis (e.g., transcript, SteerCo meeting, user request) |
| `synthesis_scope` | Array | No | List of filenames | **DEPRECATED → alias of `source_inputs` (Category 3).** The Domain-C-only narrower instance of the cross-domain `source_inputs` provenance carrier. During the migration window, readers MAY find either field; writers SHOULD emit `source_inputs`. Migration tail (emit sites + the `sqlite-index-schema.md` junction table) is sequenced in the build; on completion, exactly **one live field** (`source_inputs`) carries the concept (duplicate-source-discipline §1). `trigger_source` is a **distinct** concern and is NOT deprecated — see note below. |
| `validation_state` | String | No | `pending`, `passed`, `failed` | Agent consistency check result |
| `promotion_state` | String | No | `staged`, `promoted`, `archived-in-place` | **Promotion-location** of the generated artifact's file — *where it physically sits*, orthogonal to `lifecycle_state` (which carries content-maturity). `staged` = in `08-Generated/`; `promoted` = physically moved to its `01-07` target folder; `archived-in-place` = moved to `08-Generated/_archived/` by the Auto-Archive sweep (a location terminal, distinct from the content terminal `lifecycle_state: archived`). Owner: `artifact-generator`. Full protocol: [`artifact-workflow-protocol.md`](../artifact-workflow-protocol.md) §4. Absent ⇒ not-yet-staged / not-applicable. |
| `promoted_from` | String | No | Filename | If promoted from another synthesis, links to predecessor |
| `parent_artifact` | String | No | Path/filename of the upstream generated artifact | The upstream generated artifact this synthesis derives from (horizontal lineage). A lineage edge MAY point at a Domain-A baselined parent — both Domain A and Domain C carry the field so an A↔C chain resolves. See Lineage Fields vs. Provenance Fields. |
| `sibling_topic` | String | No | Scope descriptor string | Topic/scope descriptor that groups strict siblings for dedup matching. Verbatim-aligned with `lifecycle-states-canonical.md §3.2`. |
| `supersedes` | String | No | Filename of the artifact this one replaces | Backward inverse of `superseded_by` — points to the prior artifact this one supersedes in a dedup/version chain. Distinct from the `SUPERSEDES` relationship verb (a per-artifact scalar carrier, not a `relationships[]` entry). |

**Promotion-location consistency rules:**
- `promotion_state: promoted` requires `folder ≠ 08-generated` (a promoted file has physically left the staging area; this is the rule artifact-lint Check 4 enforces, now schema-declared on the dedicated `promotion_state` field rather than inferred from the deprecated `artifact_state: PROMOTED`).
- `promotion_state` (location) and `lifecycle_state` (content-maturity) are **orthogonal** — neither value constrains the other. Full transition rules: [`artifact-workflow-protocol.md`](../artifact-workflow-protocol.md) §4.

**`trigger_source` vs `source_inputs` (distinct concerns — both live).** `trigger_source` records **what triggered** the synthesis (the event/file that prompted generation — e.g., a SteerCo meeting, a user request); `source_inputs` (Category 3) records **what evidence** the synthesis drew from. A synthesis may be *triggered by* one transcript while *drawing on* several. These are orthogonal and both remain live fields; only `synthesis_scope` (the "what evidence" duplicate) is deprecated.

---

## Sidecar File Specification

For non-markdown files that cannot embed YAML frontmatter.

### Naming Convention

```
{original-filename}.meta.yml
```

Examples:
- `SteerCo_2026-03-15.txt` → `SteerCo_2026-03-15.txt.meta.yml`
- `RAID_Export_Q1.xlsx` → `RAID_Export_Q1.xlsx.meta.yml`
- `Cutover_Plan_v2.pdf` → `Cutover_Plan_v2.pdf.meta.yml`

### Sidecar Structure

Identical YAML field set to embedded frontmatter. No `---` delimiters (plain YAML file). This includes the horizontal-lineage fields (`parent_artifact`, `sibling_topic`, `supersedes`): sidecar `.meta.yml` files carry them identically to embedded frontmatter, so lineage edges on non-markdown artifacts are equally grep-discoverable.

```yaml
# Sidecar metadata for: SteerCo_2026-03-15.txt
type: transcript
managed_by: file-router
parent: [PROJECT_KEY] Implementation
domain: A
file_format: txt
project: [PROJECT_KEY] Implementation
folder: 05-transcripts
lifecycle_state: active
lifecycle_changed: 2026-03-15
trust_category: evidence
evidence_quality: source
created_date: 2026-03-15
created_by: file-router
source_system: teams
relationships:
  - type: GENERATES
    target: "[PROJECT_KEY]_SteerCo_Decision_Package_2026-03-15"
    evidence: "PPM Agent processing run 2026-03-15"
    created_date: 2026-03-15
```

### Agent Creation Rules

| Condition | Agent Behavior |
|-----------|---------------|
| Markdown file, no frontmatter | Add embedded YAML frontmatter block |
| Non-markdown file, no sidecar | Create `.meta.yml` sidecar |
| Sidecar already exists | Update existing sidecar (merge, don't overwrite) |
| File type unknown | Create sidecar with `type: reference`, `trust_category: working-context` |

### Index Builder Behavior

The SQLite index builder treats embedded frontmatter and sidecar metadata identically:
1. Scan for `.md` files → parse YAML frontmatter
2. Scan for `.meta.yml` files → parse as sidecar metadata, associate with parent file
3. Files with neither embedded nor sidecar metadata → flag as orphan candidates

---

## Complete Frontmatter Example

### Domain A — Markdown source artifact

```yaml
---
type: fdd
managed_by: ppm-agent
parent: [PROJECT_KEY] Implementation
domain: A
file_format: md
project: [PROJECT_KEY] Implementation
folder: 02-design
lifecycle_state: active
lifecycle_changed: 2026-03-20
lifecycle_trigger: human-approval
trust_category: controlled-truth
evidence_quality: source
created_date: 2026-02-15
created_by: [OPERATOR_NAME]
source_system: manual
approval_state: approved
version: "2.0"
superseded_by: null
relationships:
  - type: SUPERSEDES
    target: "[PROJECT_KEY]_FDD_Inventory_v1"
    evidence: "Design review 2026-03-18"
    created_date: 2026-03-20
  - type: DEPENDS_ON
    target: "[PROJECT_KEY]_Requirements_Matrix"
    evidence: "Traceability mapping"
    created_date: 2026-02-15
---
```

### Domain B — Tracker

```yaml
---
type: tracker
managed_by: tracker-manager
parent: [PROJECT_KEY] Implementation
domain: B
file_format: md
project: [PROJECT_KEY] Implementation
folder: 04-operations
lifecycle_state: current
lifecycle_changed: 2026-04-09
trust_category: controlled-truth
created_date: 2026-01-15
created_by: ppm-agent
last_evidence_date: 2026-04-09
staleness_threshold_days: 14
entry_count: 42
relationships:
  - type: BELONGS_TO
    target: "[PROJECT_KEY] Implementation"
    evidence: "Project structure"
    created_date: 2026-01-15
---
```

### Domain C — Generated synthesis

```yaml
---
id: decision-package-acme-2026-04-09-01
type: decision-package
managed_by: artifact-generator
parent: [PROJECT_KEY] Implementation
domain: C
file_format: md
project: [PROJECT_KEY] Implementation
folder: 08-generated
lifecycle_state: draft
lifecycle_changed: 2026-04-09
lifecycle_trigger: ppm-agent-processing
trust_category: interpretation
created_date: 2026-04-09
created_by: artifact-generator
generated_by: artifact-generator v3.1
trigger_source: "SteerCo_2026-04-08.txt"
source_inputs:
  - "TR-034"
  - "MSG-047"
  - "[PROJECT_KEY]_RAID_Log"
  - "05-transcripts/SteerCo_2026-04-08.txt"
validation_state: pending
relationships:
  - type: GENERATES
    target: null
    evidence: "SteerCo transcript processing"
    created_date: 2026-04-09
---
```

---

## Validation Checklist

- [ ] Every frontmatter block has at minimum: `type`, `managed_by`, `lifecycle_state`, `trust_category`, `domain`, `file_format`, `project`, `folder`
- [ ] `type` value is valid for the file's `domain` (see Type Taxonomy)
- [ ] `lifecycle_state` value is valid for the file's `domain` (see Lifecycle States by Domain)
- [ ] Trust-lifecycle consistency rules are satisfied
- [ ] Relationship `target` values resolve to existing files in the ecosystem
- [ ] (WARN) Lineage-field path values (`parent_artifact`, `supersedes`, `superseded_by`) resolve to existing artifacts — WARN, not BLOCK (consistent with relationship-target resolution; a dangling lineage pointer is a flag, not a hard failure)
- [ ] Relationship `type` values are one of the 7 MVP types
- [ ] Domain C files have `trigger_source` populated
- [ ] (Domain C) if `promotion_state: promoted`, then `folder ≠ 08-generated` (promotion-location consistency)
- [ ] Sidecar files follow the `{filename}.meta.yml` naming convention
- [ ] `created_date` is not in the future
- [ ] `lifecycle_changed` is not earlier than `created_date`
