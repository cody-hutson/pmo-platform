---
title: Agent Processing Contracts — Document Ecosystem Integration
purpose: Defines what each skill must do to build and maintain the document ecosystem during normal delivery processing — the ecosystem-specific actions additive to each skill's output contract.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: every skill (the additive document-ecosystem actions); per-skill-output-contracts.md; the document-ecosystem health checks
---
# Agent Processing Contracts — Document Ecosystem Integration

## Purpose

Defines what each skill must do to build and maintain the document ecosystem during normal delivery processing. These contracts are **additive** — they describe ecosystem-specific actions each skill takes in addition to its existing output contract (defined in `per-skill-output-contracts.md`).

A skill that produces correct output per its output contract but fails to maintain ecosystem metadata is non-compliant with its ecosystem contract.

**Grounding:** Existing skill architecture (`per-skill-output-contracts.md`, `routing-rules.md`); design brief §18-19 (human-agent roles); C17 (agent platform operations)
**Cross-references:** `frontmatter-schema.md` (field definitions), `sqlite-index-schema.md` (index queries), `domain-c-lifecycle-protocol.md` (lifecycle transitions)

## Consumers

| Consumer | Purpose |
|----------|---------|
| Skill editors | When modifying skills to add ecosystem behavior |
| QA Auditor | Validating ecosystem contract compliance |
| Skill Creator | Designing new skills with ecosystem awareness |
| Health check engine | Verifying skills fulfilled their ecosystem obligations |

## Relationship to Existing Contracts

| Document | Defines | Scope |
|----------|---------|-------|
| `per-skill-output-contracts.md` | Output structure per skill mode | What the skill produces for the user |
| **This file** | Ecosystem metadata actions per skill | What the skill does for the document ecosystem |

Both contracts must be satisfied simultaneously.

---

## Contract Format

Each skill contract specifies:

| Field | Description |
|-------|-------------|
| **Trigger** | When this ecosystem action fires (maps to an existing skill processing step) |
| **Reads** | What frontmatter/index data the skill consumes |
| **Writes** | What frontmatter fields the skill creates or updates |
| **Relationships Created** | What relationship types this skill can create |
| **Lifecycle Transitions** | What state changes this skill can trigger |
| **Ecosystem Tag** | The `[ECOSYSTEM_UPDATE]` tag format emitted |
| **Validation** | How to verify the skill fulfilled its ecosystem contract |

---

## Skill 1: File Router — Intake Injection Point

**Existing role:** Classifies and routes incoming files using 3-layer classification (content analysis → project identification → filename patterns).

**Ecosystem addition:** After classification, create initial frontmatter (embedded) or sidecar (.meta.yml) for every routed file.

| Field | Value |
|-------|-------|
| **Trigger** | After successful classification and routing (confidence ≥ 70%) |
| **Reads** | Classification result (type, project, confidence), filesystem metadata (dates, format) |
| **Writes** | `type`, `domain`, `project`, `folder`, `file_format`, `managed_by` (set to `file-router`), `lifecycle_state` (initial: `created` for Domain A, `created` for Domain B, `draft` for Domain C), `trust_category` (default by domain: A=`evidence`, B=`controlled-truth`, C=`interpretation`), `created_date`, `created_by`, `source_system`, `tags` (see Tag Application below) |
| **Relationships Created** | `BELONGS_TO` (file → project) |
| **Lifecycle Transitions** | Sets initial state only (no transitions) |
| **Ecosystem Tag** | `[ECOSYSTEM_UPDATE: {path} | FRONTMATTER_CREATED | file-router | confidence: {score}]` |
| **Validation** | Every routed file has frontmatter with all required core fields populated, including tags from taxonomy |

**Tag application (File Router):** On intake, assign tags based on classification result:
- `project/{slug}` — from the project identification layer
- `delivery/{domain}` — from the folder/domain mapping (governance, design, testing, operations, transcripts, comms, synthesis)
- `artifact/{type}` — from the content classification (transcript, design-doc, tracker, report, plan, email, export)
- `status/{state}` — from the initial lifecycle state (active, draft)

**Sidecar creation rule:** If the file is non-markdown (.txt, .csv, .xlsx, .pdf, .docx, .html), create a `.meta.yml` sidecar instead of embedded frontmatter.

**Version detection:** If the filename matches an existing file with a version pattern (e.g., `FDD_v2.md` matches `FDD_v1.md`), create a `SUPERSEDES` relationship and set the predecessor's `lifecycle_state` to `superseded`, `superseded_by` to the new filename, and `trust_category` to `historical-record`.

---

## Skill 2: PPM Agent — Dependency Scan Enhancement

**Existing role:** Strategic brain. Processes transcripts, exports, and other artifacts to produce 7-section output + Section 8 (TRACKER_UPDATE instructions, Impact Matrix, dependency scan).

**Ecosystem addition:** During Section 8.6 dependency scan, create and update relationship entries in frontmatter of processed files.

| Field | Value |
|-------|-------|
| **Trigger** | During Section 8.6 (Dependency Scan & Tracker Impact Matrix) processing |
| **Reads** | Source file frontmatter (existing relationships), SQLite index (blast radius CTE for impact analysis), tracker frontmatter (entry counts, staleness) |
| **Writes** | `relationships` array (append new relationships), `last_evidence_date` (on Domain B files when evidence is incorporated), `tags` (append `workstream/{slug}` when workstream association detected) |
| **Relationships Created** | `GENERATES` (transcript/input → output artifacts), `DEPENDS_ON` (decisions → scope documents, test plans → FDDs), `BLOCKS` (risks → milestones, blockers → deliverables), `RELATES_TO` (general contextual links discovered during analysis) |
| **Lifecycle Transitions** | Can flag Domain B files as `needs-review` when upstream changes detected. Can trigger Domain C staleness check when source files are modified. |
| **Ecosystem Tag** | `[ECOSYSTEM_UPDATE: {path} | RELATIONSHIP_ADDED | {type}: {source} → {target} | {evidence}]` |
| **Validation** | Every TRACKER_UPDATE instruction that references a file also creates or confirms a relationship. Impact Matrix entries have corresponding relationship entries. |

**Blast radius integration:** When the PPM Agent produces a Tracker Impact Matrix (Section 8.6), it should query the SQLite index blast radius CTE (Query 1) to identify secondary and tertiary effects beyond what the flat matrix captures.

---

## Skill 3: Tracker Manager — Update Propagation

**Existing role:** Receives structured `TRACKER_UPDATE` instructions from PPM Agent and other skills, validates against tracker schemas, consolidates changes, presents to user for approval, executes updates.

**Ecosystem addition:** When updating tracker entries, update lifecycle and evidence fields on tracker files. Emit relationship entries linking tracker updates to their source files.

| Field | Value |
|-------|-------|
| **Trigger** | After each approved TRACKER_UPDATE execution |
| **Reads** | Tracker file frontmatter (lifecycle_state, last_evidence_date, entry_count), source file that triggered the update |
| **Writes** | `lifecycle_state` (refresh to `current` if was `needs-review`), `lifecycle_changed`, `last_evidence_date` (set to today), `entry_count` (recalculated after update) |
| **Relationships Created** | `RELATES_TO` (tracker → source file that produced the update evidence) |
| **Lifecycle Transitions** | `needs-review` → `current` (when new evidence incorporated). `stale` → `current` (when substantive update applied). |
| **Ecosystem Tag** | `[ECOSYSTEM_UPDATE: {tracker_path} | LIFECYCLE_CHANGED | {old_state} → current | tracker-update: {update_count} entries]` |
| **Validation** | Every TRACKER_UPDATE execution updates the tracker's `last_evidence_date`. Tracker `entry_count` matches actual entries after update. |

---

## Skill 4: Artifact Generator — Staging with Domain C Metadata

**Existing role:** Produces artifacts on request, from `[ARTIFACT_GAP]` tags, or from phase gate requirements. Stages output in 08-Generated/ with metadata headers.

**Ecosystem addition:** Every generated artifact receives full Domain C frontmatter. The lifecycle protocol (`domain-c-lifecycle-protocol.md`) governs all subsequent state transitions.

| Field | Value |
|-------|-------|
| **Trigger** | On every artifact generation (before writing to 08-Generated/) |
| **Reads** | Request context (what triggered this generation), source files used during generation |
| **Writes** | Full frontmatter block: `type` (from artifact catalog), `managed_by: artifact-generator`, `domain: C`, `folder: 08-generated`, `lifecycle_state: draft`, `trust_category: interpretation`, `trigger_source` (what prompted generation), `synthesis_scope` (list of source files used), `validation_state: pending`, `created_date`, `created_by: artifact-generator` |
| **Relationships Created** | `GENERATES` (trigger source → this artifact), `DEPENDS_ON` (this artifact → each file in synthesis_scope) |
| **Lifecycle Transitions** | Sets initial state `draft` only |
| **Ecosystem Tag** | `[ECOSYSTEM_UPDATE: {path} | FRONTMATTER_CREATED | artifact-generator | trigger: {trigger_source} | scope: {scope_count} files]` |
| **Validation** | Every file in 08-Generated/ created by this skill has Domain C frontmatter with `trigger_source` populated. `synthesis_scope` array is non-empty. |

**Metadata header migration:** The existing metadata header format in 08-Generated/ files is replaced by YAML frontmatter. The frontmatter contains a superset of the information currently in metadata headers.

---

## Skill 5: Weekly Status Roll-Up — Navigation Trigger

**Existing role:** Generates weekly executive status across all active projects. Covers project health, risks, decisions, milestones.

**Ecosystem addition:** After roll-up generation, trigger navigation page refresh for affected projects. Update project-level health indicators in frontmatter.

| Field | Value |
|-------|-------|
| **Trigger** | After weekly roll-up generation completes |
| **Reads** | Portfolio health data from SQLite index (Query 4: portfolio roll-up), project-level frontmatter |
| **Writes** | `health` field on project-level navigation pages (if health changed) |
| **Relationships Created** | None (roll-up is a read-aggregate-generate pattern) |
| **Lifecycle Transitions** | None directly; the generated roll-up follows Domain C lifecycle (via Artifact Generator contract) |
| **Ecosystem Tag** | `[ECOSYSTEM_UPDATE: _pmo/portfolio.md | NAVIGATION_REFRESH | weekly-rollup | projects: {project_list}]` |
| **Validation** | Navigation pages for all active projects have `last_generated` dates within 7 days of the roll-up |

---

## Skill 6: Project Initiator — Scaffold with Ecosystem

**Existing role:** Creates folder structure for new projects, populates PROJECT.md, updates PORTFOLIO.md.

**Ecosystem addition:** Create initial frontmatter on PROJECT.md, create navigation scaffold pages for the new project.

| Field | Value |
|-------|-------|
| **Trigger** | During project initiation (after folder structure creation) |
| **Reads** | Portfolio structure (existing projects, programs) |
| **Writes** | Full frontmatter on PROJECT.md: `type: project-page`, `managed_by: project-initiator`, `domain: B`, `lifecycle_state: emerging`, `trust_category: controlled-truth`. Navigation page headers for folder indexes. |
| **Relationships Created** | `BELONGS_TO` (project → program → portfolio), `BELONGS_TO` (PROJECT.md → project) |
| **Lifecycle Transitions** | Sets initial states only |
| **Ecosystem Tag** | `[ECOSYSTEM_UPDATE: {project}/PROJECT.md | FRONTMATTER_CREATED | project-initiator | scaffold: {folder_count} folders]` |
| **Validation** | New project has PROJECT.md with frontmatter. Navigation scaffold includes at minimum: project hub page + one folder index per 01-08 folder. |

---

## Inter-Skill Ecosystem Communication

### New Tag: `[ECOSYSTEM_UPDATE]`

A new follow-up tag type for ecosystem metadata changes. Follows the existing follow-up tag pattern (per-skill-output-contracts.md) but carries ecosystem-specific information.

**Format:**

```
[ECOSYSTEM_UPDATE: {file_path} | {action} | {details}]
```

**Actions:**

| Action | Description | Triggered By |
|--------|-------------|-------------|
| `FRONTMATTER_CREATED` | Initial frontmatter added to a file | File Router, Artifact Generator, Project Initiator |
| `RELATIONSHIP_ADDED` | New relationship entry created | PPM Agent, File Router |
| `LIFECYCLE_CHANGED` | Lifecycle state transition occurred | Tracker Manager, Health Check Engine |
| `SIDECAR_CREATED` | New .meta.yml sidecar file created | File Router |
| `NAVIGATION_REFRESH` | Navigation page needs regeneration | Weekly Status Roll-Up, Health Check Engine |

**Routing:** `[ECOSYSTEM_UPDATE]` tags are consumed by:
- The index builder (for incremental updates)
- The navigation layer generator (for targeted page refresh)
- The health check engine (for validation scheduling)

Tags are not routed to other skills for processing (unlike `[DELIVERY]` or `[TECHNICAL]` tags). They are infrastructure signals, not work items.

---

## Skills Without Ecosystem Contracts

The following skills do not have ecosystem contracts in this design phase. They may be added in future phases as the ecosystem matures:

| Skill | Reason for Exclusion |
|-------|---------------------|
| Daily Status | Generates output (covered by Artifact Generator contract) but doesn't maintain relationships |
| Comms Writer | Produces communications (covered by Artifact Generator contract) |
| Delivery Engine | Operates on project methodology, not file metadata; may gain ecosystem contract when DoR/DoD gates integrate with lifecycle |
| Change Management | Training/readiness artifacts follow Artifact Generator contract |
| PMO Technical Analyst | Review output follows Artifact Generator contract |
| PMO Process Designer | Requirements output follows Artifact Generator contract |
| Release Planner / Release Executor | Platform engineering skills; ecosystem covers project delivery artifacts |
| PMO QA Auditor | Gains a new validation dimension (ecosystem contract compliance) but doesn't write ecosystem metadata |
| PMO Skill Editor | Operates on skills, not project files |

---

## Validation Checklist

- [ ] Every skill with an ecosystem contract has the contract fields documented (trigger, reads, writes, relationships, lifecycle, tag, validation)
- [ ] File Router creates frontmatter or sidecar on every classified file
- [ ] PPM Agent creates relationship entries during dependency scan (Section 8.6)
- [ ] Tracker Manager updates `last_evidence_date` on every tracker update
- [ ] Artifact Generator creates full Domain C frontmatter on every generated artifact
- [ ] Project Initiator creates navigation scaffold for new projects
- [ ] `[ECOSYSTEM_UPDATE]` tags use the documented format and valid action types
- [ ] No skill writes lifecycle states outside its permitted transitions (per contract)
- [ ] Ecosystem contracts are additive — existing output contracts in `per-skill-output-contracts.md` are unchanged
- [ ] Skills without ecosystem contracts are listed with rationale for exclusion
