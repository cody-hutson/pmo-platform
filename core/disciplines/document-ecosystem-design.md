---
title: Document Management Ecosystem — Design Specification
purpose: The narrative spine of the document-management ecosystem design — the architecture decisions, cross-cutting concerns, and integration of the six deliverable specifications into one coherent layer.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Document Management Ecosystem — Design Specification

**Status:** Canonical design specification for the document management ecosystem layer.

---

## 1. Purpose

This document is the narrative spine of the document management ecosystem design. It records architecture decisions, defines cross-cutting concerns, and integrates the six deliverable specifications into a coherent system. The conceptual model is realized at entity granularity by [`project-entity-model.md`](project-entity-model.md); this document remains the architectural narrative that explains *why* the entity model takes the shape it does.

### Design Deliverable Inventory

| # | Deliverable | File | Purpose |
|---|-------------|------|---------|
| 1 | Frontmatter Schema | `schemas/frontmatter-schema.md` | Field definitions for agent-maintained metadata per domain |
| 2 | SQLite Index Schema | `schemas/sqlite-index-schema.md` | Table DDL, FTS5 indexing, named query patterns |
| 3 | Agent Processing Contracts | `schemas/agent-processing-contracts.md` | Per-skill ecosystem additions (what to read/write/create) |
| 4 | Navigation Layer Schema | `schemas/navigation-layer-schema.md` | Page types, view parameterization, refresh triggers |
| 5 | Domain C Lifecycle Protocol | `domain-c-lifecycle-protocol.md` | State transitions, triggers, governance for synthesized artifacts |
| 6 | Health Check Specification | `health-check-specification.md` | 9 checks with queries, thresholds, remediation, scheduling |

### Grounding References

All design decisions trace to the PMO Reference Model Knowledge Base capability domains:

| KB Domain | Design Application |
|-----------|-------------------|
| C05 (Roles & Accountability) | View parameterization by role (navigation layer) |
| C06 (Portfolio & Program Management) | Portfolio → Program → Project hierarchy (navigation backbone) |
| C07 (Risk & Issue Management) | RAID integration, risk relationship modeling |
| C12 (Artifacts & Documentation) | Three lifecycle patterns, traceability chains, anti-pattern detection |
| C13 (Knowledge Management) | SECI model application, knowledge transfer considerations |
| C17 (Agent Platform & AI Operations) | 12 relationship types, three-phase artifact linking, files-as-source-of-truth, MCP stack |

---

## 2. Architecture Decisions

Five design questions are resolved here with rationale.

### Decision 1: Master document + schema files

**Choice:** One master design document (this file) + 4 schema files in `schemas/` + 2 specification files at reference root.

**Rationale:** A single framing document works well for decisions. Design specifications include field-level tables, SQL DDL, and validation rules — consumed differently by different agents. A skill editor implementing agent processing contracts needs that schema open alongside per-skill-output-contracts.md. The existing `schemas/` directory establishes this pattern with `tracker-schemas.md`, `field-lifecycle-matrix.md`, `per-skill-output-contracts.md`, and `stage-io-contracts.md`.

**Placement logic:**
- Schema files (`schemas/`): consumed independently by agents, follow existing table-based format
- Protocol/specification files (reference root): define new capabilities alongside predecessors
- Master document (this file): carries the architectural narrative; the entity-granularity realization lives in [`project-entity-model.md`](project-entity-model.md)

### Decision 2: Sidecar metadata for non-markdown files

**Choice:** `.meta.yml` sidecar files for any file that cannot embed YAML frontmatter.

**Rationale:** 46% of project files are non-markdown (.txt: 174, .csv: 18, .pdf: 15, .xlsx: 6, .docx: 6, .html: 5). These cannot embed YAML. Without sidecar metadata, nearly half the file population would be second-class citizens in the relationship graph. The sidecar convention (`{filename}.meta.yml`) keeps metadata co-located with the source file and uses identical field definitions. The SQLite index builder ingests both embedded frontmatter and sidecars identically.

**Alternatives rejected:**
- Filename inference only: loses relationship/trust/lifecycle data — insufficient for the navigation layer
- Centralized metadata registry: violates C17 principle (files-as-source-of-truth) — metadata would diverge from files

### Decision 3: 7 MVP relationship types (of 12 from C17)

**Choice:** GENERATES, DEPENDS_ON, BLOCKS, SUPERSEDES, BELONGS_TO, RELATES_TO, ASSIGNED_TO.

**Rationale:** Five relationship types have partial current representation (belongs_to, depends_on, blocks, resolves, tracks). Delivery-methodology connections (transcript → decision → scope change → training impact) are what make the graph useful. The 7 MVP types cover these core delivery chains:

| Chain | Types Used |
|-------|-----------|
| Production chain | GENERATES (transcript → decision package → communication) |
| Dependency chain | DEPENDS_ON, BLOCKS (test plan → FDD → requirements) |
| Version chain | SUPERSEDES (FDD v2 → FDD v1) |
| Organizational chain | BELONGS_TO, ASSIGNED_TO (file → project, action → owner) |
| General association | RELATES_TO (catch-all for contextual links) |

**Phase 2 expansion path:** FOLLOWS_UP (meeting series), PARTICIPATED_IN (attendance), ESCALATED_TO (governance chain), AUDIENCE_OVERLAP (computed similarity), plus 1 extension slot for domain-specific needs.

### Decision 4: Hybrid navigation refresh model

**Choice:** Event-triggered refresh on file changes + daily full rebuild as safety net.

**Rationale:** The existing skill processing pipeline already provides natural trigger points: File Router intake, PPM Agent processing, Tracker Manager consolidation. When a file changes, the navigation pages that reference it should refresh. But event triggers can miss changes (manual edits, bulk imports, direct file operations). A daily full rebuild catches gaps and doubles as the orphan detection sweep.

**Refresh trigger mapping:** Defined in `schemas/navigation-layer-schema.md` per page type.

### Decision 5: Five Domain C lifecycle states

**Choice:** Draft → Validated → Published → Stale → Archived.

**Rationale:** Replaces the current 10-day auto-archive (which treats all synthesis as ephemeral) with a governed lifecycle. Key distinction: "Validated" means an agent confirmed consistency (sources exist, no contradictions); "Published" means a human confirmed the synthesis is authoritative. This preserves the human governance principle (humans remain governors of meaning) while allowing agents to do consistency checking.

**Full protocol:** `domain-c-lifecycle-protocol.md`

---

## 3. Three-Domain Architecture Applied

The three-domain model maps directly to the existing 01-08 folder structure. The design applies domain-specific semantics without restructuring the folder system.

### Domain Mapping

| Domain | Brief Definition | PMO Folder Mapping | Trust Default | Lifecycle Pattern (C12) |
|--------|------------------|--------------------|---------------|------------------------|
| A — Source Artifacts | Evidence-bearing originals with provenance | 01-Governance, 02-Design, 03-Testing, 05-Transcripts, 06-Emails, 07-Reference | `evidence` | Baselined Document |
| B — Managed Knowledge | Durable structured representations | 04-PMO-Operations (trackers: RAID, Daily Status, Communications, Meetings, Transcript Register) + PROJECT.md | `controlled-truth` | Living Document |
| C — Synthesized Intelligence | Reusable interpreted outputs | 08-Generated (decision packages, roll-ups, runbooks, processing outputs) | `interpretation` | Hybrid (agent + human gates) |

### What the Design Adds to Each Domain

**Domain A (Source Artifacts — 01-07):**
- Frontmatter with provenance (who, when, what system), approval state, version tracking
- Supersession model (v2 SUPERSEDES v1 with explicit link)
- Lifecycle: `created` → `draft` → `active` → `superseded` → `archived`
- Impact: files gain metadata; content and folder structure unchanged

**Domain B (Managed Knowledge — 04-Operations):**
- Frontmatter with staleness tracking, evidence freshness, entry counts
- Lifecycle: `created` → `emerging` → `current` → `needs-review` → `stale` → `superseded` → `archived`
- Staleness detection: automatic `needs-review` transition when no new evidence within threshold
- Impact: trackers gain lifecycle awareness; tracker schemas and update contracts unchanged

**Domain C (Synthesized Intelligence — 08-Generated):**
- Full lifecycle protocol replacing 10-day auto-archive
- Trigger-source tracking (what prompted this synthesis)
- Scope tracking (what source files were used)
- Human promotion gate (draft → validated → published)
- Impact: most significant change — transforms 08-Generated from ephemeral staging to governed lifecycle

---

## 4. Relationship Model Design

### 7 MVP Types

Each relationship is directional (source → target) with an optional inverse for traversal. Relationships are stored in frontmatter on the source file and indexed in the `relationships` table.

| Type | Source → Target | Inverse | Cardinality | Typical Agent Creator |
|------|----------------|---------|-------------|----------------------|
| `GENERATES` | Producer → Product | `GENERATED_BY` | 1:many | PPM Agent, Artifact Generator |
| `DEPENDS_ON` | Dependent → Dependency | `DEPENDED_ON_BY` | many:many | PPM Agent (dependency scan) |
| `BLOCKS` | Blocker → Blocked | `BLOCKED_BY` | many:many | PPM Agent (RAID processing) |
| `SUPERSEDES` | New → Old | `SUPERSEDED_BY` | 1:1 | File Router (version detection) |
| `BELONGS_TO` | Part → Whole | `CONTAINS` | many:1 | File Router (intake classification) |
| `RELATES_TO` | Peer → Peer | `RELATES_TO` | many:many | Any skill (general association) |
| `ASSIGNED_TO` | Work → Person | `ASSIGNED_FROM` | many:1 | PPM Agent (action extraction) |

### Relationship Storage

- **Source of truth:** `relationships` array in frontmatter (or sidecar `.meta.yml`)
- **Queryable cache:** `relationships` table in SQLite index
- **Conflict resolution:** frontmatter wins; index is rebuilt from frontmatter
- **Directionality:** relationship stored on the source file only; inverse computed by index queries

### Delivery Methodology Chains (Prototype Finding 2)

Connections follow how project delivery actually flows, not arbitrary taxonomy:

```
Transcript  ──GENERATES──►  Decision Package  ──GENERATES──►  Communication
    │                             │
    └──GENERATES──►  RAID Entry   └──DEPENDS_ON──►  Scope Document
                        │
                        └──BLOCKS──►  Milestone
```

These chains emerge from agent processing during delivery — they are not pre-designed taxonomies. The PPM Agent builds them during transcript processing (Section 8 dependency scan). The Artifact Generator extends them when creating synthesis.

---

## 5. Trust Model Design

### Five Trust Categories

Five trust categories are defined. The design extends the platform's existing evidence quality labels (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`) from skill output to file-level metadata.

| Category | Brief §14 Definition | Frontmatter Field | Default Domain | Agent Can Set? |
|----------|---------------------|-------------------|----------------|----------------|
| `evidence` | Original artifacts or directly captured factual records | `trust_category: evidence` | A | Yes (at intake) |
| `controlled-truth` | Explicitly accepted as current operational/governance view | `trust_category: controlled-truth` | B | No (requires human confirmation) |
| `interpretation` | Summaries, analytical views, inferred reasoning | `trust_category: interpretation` | C | Yes (at generation) |
| `working-context` | In-progress or exploratory material not yet stabilized | `trust_category: working-context` | A/C | Yes (at intake/generation) |
| `historical-record` | No longer current but important for audit trail | `trust_category: historical-record` | Any | Yes (on lifecycle transition) |

### Trust-Lifecycle Consistency

Trust categories and lifecycle states must be consistent. The health check engine validates these rules:

| Rule | Condition | Required Trust Category |
|------|-----------|------------------------|
| Archived files are historical | `lifecycle_state` = `archived` | `historical-record` |
| Superseded files are historical | `lifecycle_state` = `superseded` | `historical-record` |
| Published synthesis can be authoritative | `lifecycle_state` = `published` + human approval | May be `controlled-truth` |
| Draft synthesis is never authoritative | `lifecycle_state` = `draft` (Domain C) | Cannot be `controlled-truth` |
| Active source artifacts are evidence | `lifecycle_state` = `active` (Domain A) | `evidence` |

### Evidence Quality Extension

The existing evidence quality labels apply to skill output (PPM Agent claims, RAID entries). The design extends this to file-level metadata:

| Label | Skill Output Meaning | File-Level Meaning |
|-------|---------------------|-------------------|
| `source` | Direct observation from artifact | File is an original source artifact |
| `corroborated` | Confirmed by multiple sources | File content validated against other sources |
| `inferred` | Derived from evidence | File content is synthesis or interpretation |
| `assumed` | Speculative, needs confirmation | File content contains unverified claims |

---

## 6. Three-Layer Architecture

*Separates what-to-track from how-to-store from how-to-present.*

The document ecosystem operates across three layers. This separation ensures that changes to presentation (switching from Obsidian to Confluence) don't affect the schema or storage, and changes to the schema (new entity type) propagate cleanly to storage and presentation.

| Layer | Concern | Governed By | Location |
|-------|---------|-------------|----------|
| **Schema** | What entities exist, what fields they have, what relationships are valid, what lifecycle states apply | `frontmatter-schema.md` | Entity model + field definitions |
| **Storage** | How the agent persists entity data on source files | `agent-processing-contracts.md` | YAML frontmatter, `.meta.yml` sidecars, SQLite index |
| **Presentation** | How entity data is rendered for human consumption | `navigation-layer-schema.md` + `per-skill-output-contracts.md` | Obsidian vault, Teams messages, status reports, CLI queries |

### Schema Layer — What to Track

The entity model defines WHAT the PMO tracks, independent of storage or presentation. Entities map to the 4-level PMO hierarchy:

**Portfolio entities:** Portfolio health, cross-project dependencies, resource allocation
**Program entities:** Program coordination, shared systems, escalated items
**Project entities:** Phase/milestone, workstream, risk, issue, dependency, decision, scope item
**Team entities:** Accountability (computed from ownership — not a maintained entity)
**Artifact entities:** Source artifact (Domain A), managed knowledge (Domain B), synthesis (Domain C)

The Schema Layer answers: "Does the PMO track this concept?" If yes, it has fields, relationships, and lifecycle states defined in `frontmatter-schema.md`.

### Storage Layer — How to Persist

Each entity maps to a storage mechanism:

| Entity | Storage | Notes |
|--------|---------|-------|
| Project | PROJECT.md with frontmatter | Source file exists |
| Risk | RAID Log row + navigation page | Source data in CSV; nav page generated |
| Workstream | Navigation page only | No source file — agent-maintained construct |
| Phase | Navigation page only | Dates from PROJECT.md; page generated |
| System | Navigation page only | Shared across projects; one page per system |
| Accountability | Query result | Computed from RAID owners + action items — no file |

**Key distinction:** Some entities have source files (risks exist in the RAID Log). Some exist only as navigation pages (workstreams, phases, systems). Some are query results (accountability). The Storage Layer defines which.

### Presentation Layer — How to Render

The same schema data renders differently depending on the medium:

| Medium | Spec | What It Renders |
|--------|------|----------------|
| Obsidian vault | `navigation-layer-schema.md` | Pages with wiki-links, callouts, tags |
| Teams message | `per-skill-output-contracts.md` | Daily/weekly status, action items |
| Status report | `per-skill-output-contracts.md` | Executive summary, health metrics |
| CLI query | `sqlite-index-schema.md` named queries | Table results from index |

**Key principle:** A risk entity produces a risk page in Obsidian, a risk mention in a Teams status, and a query row in the CLI. All source from the same frontmatter. The Presentation Layer is NOT the schema — it's one rendering of the schema.

### Governance Boundary

| Question | Layer | Document |
|----------|-------|----------|
| What entities does the PMO track? | Schema | `frontmatter-schema.md` |
| What fields does a risk entity have? | Schema | `frontmatter-schema.md` |
| How does the agent write risk data? | Storage | `agent-processing-contracts.md` |
| How does Obsidian show a risk? | Presentation | `navigation-layer-schema.md` |
| How does a Teams message show a risk? | Presentation | `per-skill-output-contracts.md` |
| When does a risk transition states? | Schema | `frontmatter-schema.md` lifecycle rules |

---

## 7. Cross-Deliverable Integration Map

The six deliverables form a pipeline: frontmatter feeds the index, the index feeds navigation, agent processing maintains all three, and health checks validate the full chain.

### Data Flow

```
Source Files (01-08)
    │
    ▼
Agent Processing (Skills with ecosystem contracts)
    │
    ├──► Frontmatter (embedded YAML or sidecar .meta.yml)
    │        │
    │        ▼
    │    SQLite Index (rebuilt from frontmatter — disposable cache)
    │        │
    │        ├──► Navigation Layer (pages generated from index queries)
    │        │
    │        └──► Health Checks (validate integrity via index queries)
    │
    └──► Domain C Lifecycle (governs 08-Generated/ state transitions)
             │
             └──► Health Check 6 (lifecycle compliance)
```

### Cross-Reference Matrix

How each deliverable references the others:

| Deliverable | References | Referenced By |
|-------------|-----------|---------------|
| **Frontmatter Schema** | — (foundation) | Index, Processing, Navigation, Lifecycle, Health |
| **SQLite Index Schema** | Frontmatter (column definitions from fields) | Navigation (view queries), Health (check queries), Processing (blast radius) |
| **Agent Processing Contracts** | Frontmatter (fields to write), Index (queries to run), Lifecycle (transitions to trigger) | Health (contract compliance validation) |
| **Navigation Layer Schema** | Index (view queries), Frontmatter (metadata displayed) | Health Check 7 (coverage) |
| **Domain C Lifecycle Protocol** | Frontmatter (lifecycle fields), Index (staleness query) | Processing Skill 4 (initial state), Health Check 6 (compliance) |
| **Health Check Specification** | Index (all check queries), Frontmatter (validation rules), Navigation (coverage), Lifecycle (compliance) | Navigation (health dashboard) |

### Field Consistency

Frontmatter field names must match SQLite column names which must match agent contract field references. Key field chain:

| Frontmatter Field | SQLite Column | Agent Contract Reference | Navigation Display | Health Check |
|-------------------|---------------|--------------------------|--------------------|----|
| `lifecycle_state` | `files.lifecycle_state` | Tracker Manager writes, Artifact Generator sets initial | Shown in file inventory tables | Checks 2, 6, 8, 9 |
| `trust_category` | `files.trust_category` | File Router sets default by domain | Shown in structural pages | Check 9 |
| `relationships[]` | `relationships` table rows | PPM Agent creates, File Router creates `BELONGS_TO` | Powers cross-cutting views | Checks 1, 4, 8 |
| `trigger_source` | `files.trigger_source` | Artifact Generator sets | Shown in Domain C views | Check 5 |
| `synthesis_scope[]` | `synthesis_scope` table rows | Artifact Generator sets | Shown in Domain C views | Check 3 (contradiction source) |

---

## 8. Non-Markdown File Strategy

46% of project files are non-markdown. The sidecar `.meta.yml` convention (defined in `frontmatter-schema.md`) makes them first-class ecosystem citizens.

### File Type Coverage

| Format | Count ([PROJECT_KEY]) | Sidecar Required | Navigation Behavior | Index Behavior |
|--------|-------------|------------------|--------------------|----|
| `.md` | 263 | No (embedded frontmatter) | Full wiki-link, full graph | Full FTS5 search |
| `.txt` | 174 | Yes | Wiki-link (attachment in Obsidian) | FTS5 search on content |
| `.csv` | 18 | Yes | Wiki-link (attachment) | No FTS5 (structured data) |
| `.pdf` | 15 | Yes | Wiki-link (attachment) | No FTS5 (binary) |
| `.xlsx` | 6 | Yes | Wiki-link (attachment) | No FTS5 (binary) |
| `.docx` | 6 | Yes | Wiki-link (attachment) | No FTS5 (binary) |
| `.html` | 5 | Yes | Wiki-link (attachment) | No FTS5 (binary) |

### Agent Behavior by File Type

| Scenario | Agent Action |
|----------|-------------|
| New `.md` file routed | Add embedded YAML frontmatter block |
| New non-`.md` file routed | Create `{filename}.meta.yml` sidecar |
| Existing `.md` file, no frontmatter | Add frontmatter during processing (backfill) |
| Existing non-`.md` file, no sidecar | Create sidecar during processing (backfill) |
| Sidecar exists, needs update | Merge updates into existing sidecar (don't overwrite) |

### Obsidian Limitations (Prototype Finding 5)

Obsidian renders non-markdown files as "attachments" with limited graph connectivity. The SQLite index provides the full relationship graph regardless of file type. For users browsing in Obsidian:

- `.txt` files: viewable in Obsidian, linked via wiki-links, appear in graph with "show attachments" enabled
- Binary files (`.xlsx`, `.pdf`, `.docx`): linked but not viewable in Obsidian; clicking opens in default application
- The Folder Index navigation pages list all files with their metadata — this is the primary discovery mechanism for non-markdown files

---

## 9. Migration and Backfill Strategy

### Starting State

- 139 files in [PROJECT_KEY] Implementation (01-08), 0 with frontmatter
- 81 files in 08-Generated/ — highest concentration, highest value for lifecycle management
- 4 projects in portfolio — [PROJECT_KEY] Implementation is deepest, others are lighter
- 46% non-markdown — require sidecar creation

### Backfill Approach: Incremental During Processing

Frontmatter is added incrementally as files are processed, not in a bulk migration. This approach:

1. Avoids a disruptive bulk edit across 488+ files
2. Lets each skill add frontmatter according to its ecosystem contract
3. Naturally prioritizes actively-used files (processed more frequently)
4. Creates relationships during the processing that discovers them

### Priority Order

| Priority | Target | Rationale | Estimated Files |
|----------|--------|-----------|----------------|
| 1 | 08-Generated/ (Domain C) | Highest value — lifecycle management transforms ephemeral output into governed synthesis | 81 |
| 2 | 04-Operations/ (Domain B) | Trackers gain staleness detection and evidence freshness tracking | 11 |
| 3 | 05-Transcripts/ (Domain A) | Most common PPM Agent input — high relationship value | 6 |
| 4 | Remaining 01-03, 06-07 (Domain A) | Complete coverage | 22 |
| 5 | Other projects | Extend to 10.0.47 Upgrade, Credit Holds, Credit Card Processing | ~349 |

### Backfill Triggers

| Trigger | Action |
|---------|--------|
| File processed by PPM Agent | PPM Agent adds/updates frontmatter per its ecosystem contract |
| File routed by File Router | File Router creates initial frontmatter per its ecosystem contract |
| Artifact Generator creates file | Full Domain C frontmatter from creation |
| Health check detects file without frontmatter | Queue for File Router processing |
| Daily rebuild detects files without index entry | Flag as backfill candidates |

### Transition Period

During backfill, the ecosystem operates in mixed mode:
- Files with frontmatter: fully integrated (relationships, lifecycle, navigation)
- Files without frontmatter: appear in Folder Index navigation pages with placeholder values, flagged as backfill candidates
- Health metrics report completeness rate (% with frontmatter) — expected to increase over time
- Zero-orphan KPI relaxes during backfill: target is "all frontmatter-enabled files connected" rather than "all files connected"

---

## 10. Validation and Acceptance Criteria

### Per-Deliverable Acceptance

| Deliverable | Acceptance Criteria |
|-------------|-------------------|
| Frontmatter Schema | Covers all 7 file types in [PROJECT_KEY]. Required fields defined for all 3 domains. Sidecar convention specified. Validation checklist has 10+ items. |
| SQLite Index Schema | 5+ tables defined with DDL. 7+ named query patterns. Supports all 7 MVP relationship types. Rebuild protocol documented. |
| Agent Processing Contracts | 6 skill contracts documented. Each has trigger/reads/writes/relationships/lifecycle/tag/validation. `[ECOSYSTEM_UPDATE]` tag format defined. |
| Navigation Layer Schema | 11 page types defined. Wiki-link conventions from prototype lessons. Refresh model specified. View parameterization by role/level. |
| Domain C Lifecycle Protocol | 5 states with transition diagram. Staleness triggers specified. Governance rules (human vs. agent transitions). Migration from 10-day auto-archive. |
| Health Check Specification | 9 checks with detection logic. Execution schedule (per-cycle/daily/weekly). Remediation priority. Reporting format for navigation. |
| Master Design Document (this file) | 5 architecture decisions documented. Cross-deliverable integration map. Migration strategy. All deliverables traceable to brief sections and KB domains. |

### Cross-Deliverable Consistency

| Check | Method |
|-------|--------|
| Frontmatter field names match SQLite column names | Manual inspection of field consistency table (section 6) |
| Relationship types consistent across all specs | Grep for relationship type names — all must use the 7 MVP types |
| Lifecycle states consistent between frontmatter schema, lifecycle protocol, and health checks | Compare state lists across documents |
| Navigation page types consistent between navigation schema and health check 7 | Compare page type enumerations |
| Agent contract field references match frontmatter field names | Validate each skill contract's "Writes" column against frontmatter field definitions |

### Concept Traceability

| Concept | Design Deliverable |
|---------|--------------------|
| Three domains | Frontmatter Schema (domain classification), Master Doc §3 (domain mapping) |
| Relationships | Frontmatter Schema (connection fields), Master Doc §4 (relationship model) |
| Trust model | Frontmatter Schema (trust fields), Master Doc §5 (trust model) |
| Lifecycle | Frontmatter Schema (lifecycle fields), Domain C Lifecycle Protocol |
| Navigation | Navigation Layer Schema |
| Human-agent roles | Agent Processing Contracts, Domain C Lifecycle Protocol (governance rules) |
| Health checks | Health Check Specification |
| Promotion criteria | Domain C Lifecycle Protocol (promotion criteria section) |

---

## 11. Implementation Roadmap

### Test

Test the design specifications against real data before implementation.

**Scope:**
- Validate frontmatter schema against sample project files (does every file type fit?)
- Execute SQLite named queries against a mock index (do they return expected results?)
- Walk through agent processing contracts with a sample transcript processing run (does the flow produce correct metadata?)
- Generate sample navigation pages from the schema (do they match quality bar?)
- Run Domain C lifecycle transitions on sample 08-Generated files (do state machines work?)
- Execute all 9 health checks against a mock ecosystem (do they detect planted violations?)

### Implement

Build the design into the platform.

**Implementation order (respects dependencies):**
1. Frontmatter schema → Update File Router to create initial frontmatter
2. SQLite index → Build index builder tool (rebuild from frontmatter)
3. Domain C lifecycle → Update Artifact Generator to apply lifecycle
4. Agent processing contracts → Update PPM Agent, Tracker Manager with ecosystem behavior
5. Navigation layer → Build navigation generator (from index queries)
6. Health checks → Build health check engine (from index queries + validation rules)

**Key implementation decisions:**
- MCP server for SQLite index access
- Navigation generator as a new skill vs. extension of existing infrastructure
- Health check engine as a new skill vs. extension of QA Auditor
- Sidecar creation as part of File Router vs. dedicated utility

### Evaluation

Measure the implemented ecosystem against design objectives.

**Evaluation criteria:**
- Orphan count reaches 0 for the active project
- Coverage rate reaches 100% for frontmatter-enabled files
- Staleness detection catches planted stale files within 24 hours
- Navigation pages refresh within 24 hours of triggering events
- Domain C lifecycle correctly transitions files through all 5 states
- Health checks detect all 9 violation types when planted
- Backfill rate: % of total files with frontmatter over time
