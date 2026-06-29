<!-- reference-durability: allow-link -->
# Tracker Schemas — PMO Operational Trackers

## Purpose
Defines the schema for every operational tracker in 04-PMO-Operations/. Used by the Tracker Manager to validate updates, produce consolidated change summaries, and maintain data integrity.

> For the cross-artifact entity-derivation inventory (every operational artifact ↔  entity, template/schema status), see [operational-artifact-inventory.md](../specs/operational-artifact-inventory.md).

## Schema Format
Each tracker schema defines: column name, data type, valid values (if constrained), required/optional, description, and update rules.

---

## Tracker 1: Daily Status Log
**File pattern:** `[Project]_Daily_Status_Log.md`
**Update tier:** Tier 2 (auto-update with approval)
**Update sources:** Transcripts, Jira status changes (via MCP), user-provided digests

### Structure
The Daily Status Log is a carry-forward tracker organized by category. It is the single source of truth for what's open on the project.

**Sections (in order):**
1. **Header** — Project name, last updated date/time, current phase, processing cycle reference
2. **Active Blockers** — Items blocking progress. Each entry:
   - ID: BLK-### (auto-incremented)
   - Description: What is blocked
   - Owner: Person responsible for resolution
   - Since: Date identified
   - Impact: What's affected
   - Status: ACTIVE / MONITORING / ESCALATED
   - Last update: Date + evidence source
   - Next action: Specific next step with date

3. **Decisions Pending** — Open decision items. Each entry:
   - ID: DEC-### (auto-incremented)
   - Decision needed: Clear statement of what must be decided
   - Decision maker: Who has authority
   - Options: Listed options with tradeoffs
   - Deadline: When decision is needed
   - Status: PENDING / DEFERRED / MADE
   - Evidence: Source of the decision need
   - Blocking: `true` / `false` (optional; default `false` when absent). Marks a **gating-class**
     decision (go/no-go, launch-sequence, and similar decisions that block project progress).
     Only `blocking: true` entries are subject to the Overdue-Decision Escalation Protocol
     (OPERATIONS.md). An entry with no `blocking` field is treated as non-blocking, and the
     missing classification is surfaced as a coverage gap on first encounter — never silently
     defaulted to blocking.
   - Escalation state: `NOMINAL` / `WARN` / `ESCALATED` (optional; default `NOMINAL`). The
     overdue-escalation band the decision is in, keyed on `today − Deadline` in business days:
     `NOMINAL` ≤ 3 bd past due; `WARN` > 3 bd; `ESCALATED` > 5 bd (per the Overdue-Decision
     Escalation Protocol in OPERATIONS.md, which cites
     `ppm-agent/references/escalation-thresholds.md` §2 as doc-of-record for the routed tiers).
   - Escalated to: Tier the overdue escalation routed to (populated when Escalation state =
     `ESCALATED`; one step up the `escalation-thresholds.md` §2 ladder — Team / Project /
     Program / Program-Critical / Portfolio). Blank otherwise.

4. **Open Actions by Person** — Grouped by person. Each entry:
   - Person name (group header)
   - Action: What they need to do
   - Source: Where the action was identified (transcript, meeting, email)
   - Due: Date
   - Status: OPEN / IN PROGRESS / BLOCKED
   - Notes: Additional context

5. **Deferred Items** — Items intentionally deferred. Each entry:
   - Description
   - Deferred by: Who deferred it
   - Deferred to: When to revisit
   - Reason: Why deferred
   - Status: DEFERRED / REACTIVATED

6. **Retest Queue** — Items requiring retesting. Each entry:
   - Ticket: Jira ticket ID
   - Description: What to retest
   - Fix date: When the fix was applied
   - Assigned to: Who will retest
   - Status: QUEUED / IN PROGRESS / PASSED / FAILED
   - Notes: Test conditions or environment

7. **Recently Closed** — Items closed in the last 3 business days (for audit trail). Each entry:
   - Original ID (BLK/DEC/action)
   - Description
   - Closed date
   - Evidence: How we know it's resolved (transcript ref, Jira status, confirmation)

### Closure Rules (Evidence Gate)
An item can only leave carry-forward if there is evidence:
- Blocker resolved: Transcript confirms, Jira ticket closed, or person confirmed
- Action completed: Person confirmed (transcript, email, or direct confirmation)
- Decision made: Transcript records decision + decision maker
- Retest passed: Test plan confirms pass
- No evidence = stays in carry-forward

---

## Tracker 2: Communications Tracker
**File pattern:** `[Project]_Communications_Tracker.md`
**Update tier:** Tier 2 (auto-update with approval)
**Update sources:** User-provided comms digests, meeting outcomes

### Structure
**Sections (in order):**
1. **Header** — Project name, last updated, total active messages
2. **Active Communications** (lifecycle = ACTIVE)
3. **Core Communications** (lifecycle = CORE)
4. **Archived Communications** (lifecycle = ARCHIVE, last 10 only)

**Each communication entry:**
- ID: MSG-### (auto-incremented, never reused)
- Date sent: YYYY-MM-DD
- Type: Email / Teams / Meeting / Confluence / Other
- Direction: OUTBOUND / INBOUND / INTERNAL
- From: Sender
- To: Recipient(s)
- Subject: Subject line or topic
- Summary: 1-2 sentences
- Status: SENT / PENDING RESPONSE / RESPONSE RECEIVED / NO RESPONSE NEEDED
- Response due: Date (if applicable)
- Response received: Date + summary (if applicable)
- Parent RAID/Decision: Link to related RAID entry or decision (if applicable)
- Lifecycle: ACTIVE / CORE / ARCHIVE
- Tags: [ESCALATION] [EXEC] [VENDOR] etc.

### Lifecycle Rules
- ACTIVE → CORE: Response received + no further action + parent RAID/decision still open
- ACTIVE → ARCHIVE: Response received + no further action + no open parent + 3 business days elapsed
- CORE → ARCHIVE: Parent RAID/decision closed + 5 business days elapsed
- Never archives: Communications Plan items, escalation chains with exec involvement, messages that changed a decision

---

## Tracker 3: Open Meetings Tracker
**File pattern:** `[Project]_Open_Meetings_Tracker.md`
**Update tier:** Tier 2 (auto-update with approval)
**Update sources:** Transcripts, user-provided digests, calendar references

### Structure
**Sections (in order):**
1. **Header** — Project name, last updated
2. **Upcoming Meetings** (status = SCHEDULED or NEEDS SCHEDULING)
3. **Recently Completed** (last 5 business days)
4. **Recurring Cadences** (standing meeting schedule)

**Each meeting entry:**
- ID: MTG-### (auto-incremented)
- Meeting name: Descriptive title
- Type: Daily Connect / AM Testing / PM Testing / Weekly Status / Touch Base / SteerCo / Topic Session / Ad Hoc
- Date/Time: Scheduled date and time (or TBD)
- Duration: Expected duration
- Attendees: Required + optional
- Objective: What the meeting should accomplish (1-2 sentences)
- Agenda: Numbered items with time allocations
- Pre-reads: Documents attendees should review before
- `lifecycle_state`: The **canonical governed** Meeting Axis-1 state — enum `{scheduled, held, cancelled}` (per `entity-field-schemas.md §3.7` V-MTG-05). This is the state the entity model and lifecycle automation key off.
- Status: NEEDS SCHEDULING / SCHEDULED / COMPLETED / CANCELLED — the human-readable tracker **display** label (retained for the existing tracker UX; `NEEDS SCHEDULING` is a pre-`scheduled` display sub-step). Display↔governed map: `NEEDS SCHEDULING` / `SCHEDULED` → `lifecycle_state: scheduled`; `COMPLETED` → `held`; `CANCELLED` → `cancelled`.
- Outcome: Post-meeting summary (populated after completion)
- Follow-up actions: Actions identified during meeting
- Transcript path: Link to transcript file (if recorded)

### Meeting `lifecycle_state` — frozen 3-state machine

The Meeting entity's Axis-1 lifecycle is the **frozen 3-state** machine `scheduled → held | cancelled` (`core/disciplines/project-entity-model.md` §7 Meeting; `core/schemas/entity-field-schemas.md §3.7` V-MTG-05). The tracker MAY display richer sub-steps in the `Status` field (e.g., `NEEDS SCHEDULING`), but `lifecycle_state` is constrained to the three governed values only.

**Stage-transition rules:**

| Transition | Trigger | Triggering agent | Evidence |
|---|---|---|---|
| `scheduled → held` | meeting occurred (transcript captured or outcome populated) | ppm-agent (meeting processing — Cascade B) | transcript path or `Outcome` populated |
| `scheduled → cancelled` | meeting cancelled before it occurred | ppm-agent / operator | cancellation note |

No other transitions exist — there is **no** `held → *` and **no** re-open (terminal on `held` / `cancelled`), consistent with the frozen Axis-1 machine. The `held` and `cancelled` transitions are terminal states and carry the same evidence bar as a tracker CLOSE action.

> **Reconcile note (6-stage → 3-state).** Legacy framing proposed a "6-stage" meeting pipeline (Identified … Held / Closed). The canonical Meeting machine is the **3-state** `{scheduled, held, cancelled}` — there are **no** `Identified` or `Closed` Meeting states. A body-only reader of a legacy proposal must not build a competing 6-state machine: `lifecycle_state` is the V-MTG-05 3-value enum, period. Richer display sub-steps live in the `Status` display field, never in `lifecycle_state`.

---

## Tracker 4: Transcript Register
**File pattern:** `[Project]_Transcript_Register.md` (or `Transcript_Register.md` at project level)
**Update tier:** Auto-write (Tier 2 for the register itself, but entries auto-added)
**Update sources:** File Router output after transcript classification

**Behavioral note — READ THIS:** The Transcript Register is a **passive search/reference index**, NOT an operational tracker. Its sole purpose is to optimize transcript recall and search across sessions. The transcript file itself remains the source of truth — the register is a lookup tool that helps agents find relevant transcripts quickly. Agents should **never** treat register entries as actionable items, raise flags based on register content, or surface register metadata as findings. Empty entries, missing tags, or PENDING status in the register are normal housekeeping states, not risks or issues to escalate.

### Structure
**Format:** Markdown table

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Transcript ID | String | Yes | TR-### (auto-incremented) | Unique identifier |
| Date | Date | Yes | YYYY-MM-DD | Meeting date |
| Meeting Type | Enum | Yes | Daily Connect, AM Testing, PM Testing, Weekly Status, Touch Base, Topic Session, SteerCo, Ad Hoc | From controlled vocabulary |
| Project | String | Yes | Project name or UNASSIGNED | Which project this belongs to |
| Participants (key) | String | Yes | Comma-separated names | Notable attendees |
| Tags | String | Yes | [CATEGORY:value] format | From controlled tag vocabulary |
| Summary | String | Yes | Exactly 3 sentences | (1) primary outcome, (2) key blocker/decision, (3) next action |
| File Path | String | Yes | Relative path | Validated on write; [PATH:BROKEN] if not found on read |
| Status | Enum | Yes | PENDING, REVIEWED, UNASSIGNED | Processing state |

### Tag Vocabulary (Controlled)
| Category | Values | When to Apply |
|----------|--------|--------------|
| Meeting Type | (from enum above) | Every transcript, exactly one |
| TICKET | Jira ticket IDs ([PROJECT_KEY]-NNN, etc.) | Any ticket explicitly referenced |
| INTEGRATION | WMS, integration middleware, iPaaS, data warehouse, CRM, etc. | Integration system discussed |
| TESTING | E2E, UAT, Regression, Performance | Testing activities |
| DECISION | MADE, PENDING, DEFERRED | Decision points |
| RISK | NEW, ESCALATED, MITIGATED, CLOSED | Risk items |
| DEPLOYMENT | (no sub-value) | Deployment activity |
| BLOCKER | (no sub-value) | Blocking issue |
| ACTION | person name | Action items assigned |
| PHASE | UAT, Issue Resolution, Training, Cutover, Hypercare | Phase context |

### Summary Format
3-sentence structure:
1. What was the primary outcome or topic?
2. What is the key blocker, decision, or risk?
3. What is the next action and who owns it?
If any sentence has no content, use "None identified."

---

## Tracker 5: RAID Log
**File pattern:** `[Project]_RAID_Log.csv`
**Update tier:** Tier 1 (stakeholder-facing — requires user approval for changes)
**Update sources:** PPM Agent processing, specialist skills (DE, CM, TA, PD), user input

### Structure
**Format:** CSV with two logical sections — Active Register and Archive.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| RAID_ID | String | Yes | `[TYPE]-[SKILL]-[COUNTER]` (e.g., R-PPM-001, I-DE-003) | Unique identifier per OPERATIONS.md RAID ID Namespacing. TYPE = R/A/I/D. SKILL = PPM/DE/CM/TA/PD. COUNTER = auto-incremented per skill. |
| RAID Category | Enum | Yes | Risk, Assumption, Issue, Dependency | Category of the entry |
| Description | String | Yes | Free text | What the risk/assumption/issue/dependency is |
| Impact | String | Yes | Free text | Business impact if realized/unresolved |
| Owner | String | Yes | Person name | Person responsible for management/resolution |
| Priority | Enum | Yes | Critical, High, Medium, Low | Severity ranking |
| Status | Enum | Yes | Open, Monitoring, Mitigating, Escalated, Closed | Current state |
| Action Plan | String | Yes (Open/Monitoring/Mitigating/Escalated) | Free text | What is being done about it |
| Due Date | Date | No | YYYY-MM-DD | Target resolution date |
| Date Opened | Date | Yes | YYYY-MM-DD | When the entry was created |
| Date Closed | Date | No (required when Status = Closed) | YYYY-MM-DD | When the entry was resolved |
| Closure Comments | String | No (required when Status = Closed) | Free text | How it was resolved, lessons learned |
| Tags | String | No | Free text | Additional classification tags |
| Section | Enum | Yes | ACTIVE, ARCHIVE | Logical partition. ACTIVE = open items. ARCHIVE = closed items. |

### Active/Archive Rules
- **ACTIVE section:** Contains all items where Status ≠ Closed. This is the working view.
- **ARCHIVE section:** Contains all items where Status = Closed. Append-only — never purge, never delete. Preserves full audit trail.
- **Closure transition:** When Status changes to Closed: (1) Date_Closed populated with closure date. (2) Closure_Comments populated with resolution and lessons. (3) Section changes from ACTIVE to ARCHIVE. (4) Entry moves to the ARCHIVE section of the CSV.
- **Reactivation:** A closed item can be reactivated by changing Status back to Open, clearing Date_Closed, and moving Section back to ACTIVE. The Closure_Comments are preserved as historical context.

### ID Assignment Rules
- Each RAID-producing skill uses its own prefix per OPERATIONS.md RAID ID Namespacing.
- Counter is auto-incremented per skill (not global). R-PPM-001, R-PPM-002, etc.
- IDs are permanent — never reused, even if an entry is deleted (which should never happen).
- When backfilling existing entries without IDs: assign sequentially based on creation order. Use R-PPM-### as the default prefix for entries that predate the namespacing system.

### Confluence Dual-Format Model
The RAID Log maintains two representations:
- **Local CSV (source of truth):** Full 14-column schema including RAID_ID, Date_Opened, Date_Closed, and Section. This is the operational version used by all skills for processing, querying, and lifecycle management.
- **Confluence (stakeholder-facing):** Manually uploaded by the workspace owner. Excludes internal operational fields (RAID_ID, Date_Opened, Date_Closed, Section). Matches the stakeholder-visible format used before this schema overhaul.

**Rules:**
- All agent processing reads and writes the local CSV. Never reference RAID_IDs in stakeholder-facing output (chat summaries, status updates, meeting packages). Use descriptive references instead (e.g., "the ERP freeze window dependency" not "R-PPM-003").
- The workspace owner is responsible for syncing the Confluence version after local changes. The agent may remind the owner when significant RAID changes are approved but does not upload to Confluence directly.
- If a future MCP integration enables direct Confluence writes, the agent should strip internal fields before publishing.

### Machine-Schema (entity-derived)
**Companion schema:** [`raid-log.schema.json`](raid-log.schema.json) — machine-readable JSON Schema (draft-07) validating one RAID Log CSV row.
**Entity-derivation note:** This artifact is NOT hand-schema'd — `raid-log.schema.json` is *derived* from the **RAID Item entity field schema** ([`entity-field-schemas.md`](entity-field-schemas.md)) via the **EAD** mechanism (Entity→Artifact-Schema Derivation: 7-class column crosswalk + L1-native/L2-L3-annotation projection). The entity model is authoritative (per ADR); the CSV above is its persistence *dialect*. The generalized `EAD` contract is the pattern the new-artifact templatization harness applies to all artifacts; Daily Status / Transcript Register machine-schemas are produced incrementally by that harness as their entities' field schemas land — **not** here.

---

## Tracker 6: Artifact Register
**File pattern:** `[Project]_Artifact_Register.md`
**Update tier:** Tier 2 (operational — auto-write within `cascade_scope`)
**Update sources:** Tracker Manager (row writes on artifact-generate + phase-gate baselining)

The per-project **configuration-management catalog** for the **Artifact** entity ([`project-entity-model.md`](../disciplines/project-entity-model.md) §4 entity 9): one row per project artifact (plans, RAID files, FDDs, charters, design docs, …), capturing its version, baseline status, owner, and retention so the operator can see at a glance which configuration items (CIs) exist for a project and which are baselined vs. in-flight. This closes the gap where `projects/` is gitignored and artifacts are updated in place with no version, no baseline, and no catalog — the Register is the durable CI history that the gitignore otherwise loses.

### Structure
**Format:** Markdown table — one row per artifact CI.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Artifact Name | String | Yes | Free text (= the Artifact entity's `artifact_title`) | The deliverable's name (e.g., "Cutover Plan v2"). |
| Artifact Type | Enum | Yes | Charter, Plan, RAID, FDD, Design Doc, Requirements, Report, Tracker, … (= the Type Taxonomy in [`frontmatter-schema.md`](frontmatter-schema.md) — **referenced, not redefined**) | The Artifact entity's `artifact_type`. |
| Current Version | String | No | Free text (e.g., `v2.0`) | The artifact's `version`. Blank for unversioned living docs. |
| Baseline Status | Enum | Yes | `operational` \| `baselined-at-phase-gate` \| `superseded` | CI baseline state. Default `operational`; flips per the Baseline Rules below. |
| Last Updated | Date | Yes | `YYYY-MM-DD` (not in the future) | When the artifact last changed. |
| Owner | String | Yes | Person name / role | Accountable owner of the artifact. |
| Retention | String | No | Free text / policy ref (e.g., `project+2yr`, `until-closeout`) | Retention policy. The records-management/retention *policy engine* is out of scope here — this column is the hook, not the engine. |

### Baseline Rules (phase-gate baselining trigger)
- **Default:** every new Artifact Register row enters `Baseline Status = operational`.
- **Flip to `baselined-at-phase-gate`:** at a **phase-gate moment** — PRINCE2 configuration-management baselining. The platform already models phase-gate cadence (the Methodology Variation table below: Waterfall row → `phase-gate-log.md`; PRINCE2 row → `stage-boundary.md`). When a phase gate is reached, the artifacts in scope at that gate are baselined — Tracker Manager flips their Baseline Status to `baselined-at-phase-gate` and pins `Last Updated` to the gate date. This is a **Tier-2 row MODIFY** (auto-write within `cascade_scope`), **not** a Tier-1 approval gate: the artifact's *content* is not changing, only the CI baseline marker.
- **Flip to `superseded`:** when a new version of the artifact supersedes it (the Artifact entity's `SUPERSEDES` self-edge). The prior row's Baseline Status → `superseded`, **append-only** — never delete the superseded row (it is the CI history the `projects/` gitignore otherwise loses).

### Update Instruction Format
Reuses the shared `TRACKER_UPDATE` block (see § Update Instruction Format below) with `target: [Project]_Artifact_Register.md`, `action: ADD | MODIFY`, and the artifact name as `entry_id`. ADD on artifact-generate; MODIFY to update `Last Updated` / `Current Version` / `Baseline Status` as the artifact or its baseline state changes.

### Ownership seam (no owning-agent contradiction)
The **Artifact ENTITY** (the record's fields, V-rules, Axis-1↔Axis-2 seam) stays maintained by **`ppm-agent`** (creates: `artifact-generator`; route: `file-router`) per [`project-entity-model.md`](../disciplines/project-entity-model.md) §6 + [`entity-field-schemas.md`](entity-field-schemas.md) §5 — **unchanged**. The Artifact Register is a Document-Tier-2 operational tracker, so its **ROW** writes are owned by **`tracker-manager`** like every other tracker in `04-PMO-Operations/`. This is the **identical entity-maintainer ≠ tracker-row-writer split already in production** for RAID Item and Decision (both entity-maintained yet `maintains: tracker-manager` in the owning-agent matrix). No new ownership model.

---

## Tracker 7: Milestone Tracker
**File pattern:** `[Project]_Milestone_Tracker.md` (Waterfall / Hybrid; `milestone-status.md` per the Methodology Variation matrix below)
**Update tier:** Tier 1 (stakeholder-facing — phase-gate status; requires user approval for changes)
**Update sources:** Delivery Engine Mode F (DoD / phase-gate evaluation), Mode G (milestone artifact update), user input

The per-project **phase-gate / milestone status tracker** for Waterfall and Hybrid projects (the predictive-phase tracker named in the Methodology Variation matrix). `project-initiator` Mode A Step 4 scaffolds it empty-but-properly-formatted for Waterfall/Hybrid projects; Delivery Engine reads it at the DoD / phase-gate gate. This section gives the milestone entry a defined field-set so the **evidence-backed gate-completion** rule has a field to read.

### Structure
**Format:** Markdown table — one row per milestone / phase gate.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Phase | String | Yes | Free text | The project phase the milestone belongs to. |
| Milestone | String | Yes | Free text | The milestone / phase-gate name. |
| Planned Date | Date | Yes | `YYYY-MM-DD` | Baselined target date (day-of-week validated). |
| Actual Date | Date | No | `YYYY-MM-DD` | Achieved date (populated on completion). |
| Status | Enum | Yes | `Not Started` / `In Progress` / `Complete` / `Slipped` | Current gate status. |
| Evidence Artifact | String | No (**required when Status = `Complete`**) | Named closure/evidence artifact (free text — e.g., "UAT sign-off 2026-06-18", "Gate checklist GC-04") | The named, inspectable closure/evidence artifact that substantiates a `Complete` mark. An **inferred signal alone is insufficient**: a `Complete` row with a blank or absent Evidence Artifact is rejected by the Delivery Engine DoD gate (Mode F) under the NO-EVIDENCE→FAIL rule ("Complete asserted without a named closure/evidence artifact"). Carries a `[SOURCE]` evidence-quality label; an `[INFERRED]`-only mark does not satisfy the gate. |

### Gate-Completion Rule (evidence-backed Complete)
Marking a milestone `Complete` REQUIRES a named **Evidence Artifact** cited on the row. Delivery Engine Mode F treats a `Complete` mark with an empty/absent Evidence Artifact as **FAIL** (identical to its NO-EVIDENCE→PASS prohibition), names the milestone, states "Complete asserted without a named closure/evidence artifact", and gives the remediation (cite the artifact, or revert to `In Progress`). Reversibility **CHEAP** — the gate BLOCK prevents the unverifiable state from being recorded; reverting `Complete → In Progress` is a tracker edit.

---

## Extensibility
To add a new tracker:
1. Define schema in this file (columns, types, valid values)
2. Create empty tracker file in 04-PMO-Operations/
3. Update OPERATIONS.md operational artifact index
4. Tracker Manager automatically includes in consolidated updates

## Update Instruction Format
When PPM Agent (or any skill) produces tracker update instructions for the Tracker Manager, use this format:

```
TRACKER_UPDATE:
  target: [tracker filename]
  action: ADD | MODIFY | CLOSE | REACTIVATE
  entry_id: [ID if modifying/closing, blank if adding]
  fields:
    [field_name]: [new value]
    ...
  evidence: [source citation]
  reason: [why this update is needed]
```

---

## Methodology Variation — Tracker Applicability

The tracker schemas above are the superset — which trackers are populated, and at what cadence, varies by [Methodology](../specs/terminology-glossary.md#term-methodology) per PROJECT.md `delivery_approach`. Every tracker in 04-PMO-Operations/ exists across all archetypes (no archetype-conditional tracker creation), but applicability, cadence, and field usage differ per the matrix below.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Scrum** | Sprint-burndown + sprint-velocity trackers are primary health trackers; populated at sprint-cadence (daily burndown updates, velocity at sprint close). Risk register reviewed at sprint retro. Decisions tracker keyed to sprint boundaries. | `sprint-burndown.md`, `sprint-velocity.md`, `risks.md`, `decisions.md` | [SOURCE] Scrum Guide 2020 — sprint-scale health metrics. |
| **Kanban** | Flow-efficiency + cycle-time + throughput trackers are primary; no sprint-burndown. Populated continuously as work moves through board columns. Risk register reviewed at service-delivery-review cadence (typically bi-weekly). | `flow-efficiency.md`, `cycle-time.md`, `throughput.md`, `risks.md` | [SOURCE] Kanban Method — flow metrics over velocity. |
| **XP** | Inherits Scrum sprint trackers PLUS engineering-health trackers: CI-health, test-coverage, pair-rotation, refactor-frequency. Populated continuously (CI-driven) + iteration-cadence (pair-rotation review). | `sprint-burndown.md`, `ci-health.md`, `test-coverage.md`, `pair-rotation.md` | [SOURCE] XP engineering practices — governance-level requirements. |
| **Waterfall** | Milestone + phase-gate trackers are primary; no sprint-scale trackers. Populated at phase-gate cadence (sparse updates between gates). Change-control log is required tracker; replaces iteration-cadence decisions tracker. | `milestone-status.md`, `phase-gate-log.md`, `change-control-log.md`, `risks.md` | [SOURCE] PMBOK predictive-lifecycle reporting. |
| **PRINCE2** | Stage-boundary + highlight-report trackers; populated at end-stage-assessment + highlight-report cadence (weekly/bi-weekly per project tailoring). Issue register + lessons log are REQUIRED PRINCE2 trackers. | `stage-boundary.md`, `highlight-reports.md`, `issue-register.md`, `lessons-log.md` | [SOURCE] PRINCE2 2017 management products. |
| **SAFe** | Program Increment (PI) + ART-level trackers (multiple teams × multiple sprints). PI-objectives + ART-metrics (predictability, program-velocity) populated at PI cadence (8-12 weeks). Feature trackers supplement sprint trackers. | `pi-objectives.md`, `art-metrics.md`, `feature-progress.md`, `dependencies-map.md` | [SOURCE] SAFe 6.0 — PI + ART instrumentation. |
| **Hybrid** | Trackers partition by phase: predictive-phase uses milestone trackers (Waterfall-style); iterative-phase uses sprint or flow trackers. When `dual_framing_enabled: true`, requires Dual-Framing Bridge reporting that consolidates both framings per stakeholder audience (co-management is orthogonal to the Hybrid classification — see `project-schema.md § 7`). | Phase-specific | [INFERRED] PMBOK 7 hybrid + Dual-Framing Bridge convention in `operational-runbook.md`. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive tracker applicability from declared `lifecycle`, `ceremonies`, `artifacts`, `cadence` fields. Lifecycle=continuous → flow trackers; lifecycle=timeboxed → iteration trackers; lifecycle=phased → milestone trackers. Declared `ceremonies` drive tracker update cadence. | All trackers | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md). |

**Consumer guidance.** `tracker-manager` reads `delivery_approach` at invocation, consults this table, and scopes its update routines to the applicable trackers per the archetype. Full-matrix shape chosen because all 8 archetypes have distinct tracker compositions — no archetype inherits a common default pattern for tracker applicability.
