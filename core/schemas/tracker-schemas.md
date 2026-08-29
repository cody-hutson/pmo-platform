---
title: Tracker Schemas — PMO Operational Trackers
purpose: Defines the schema for every operational tracker under 04-PMO-Operations/ — used by the Tracker Manager to validate updates, produce consolidated change summaries, and maintain data integrity.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: tracker-manager (validate updates, consolidated change summaries); the operational trackers under 04-PMO-Operations/; the entity-derivation inventory
---
<!-- reference-durability: allow-link -->
# Tracker Schemas — PMO Operational Trackers
<!-- design-artifact: flow-class=data-flow; name=tracker-schemas; depicts=operations/templates/README.md -->

## Purpose
Defines the schema for every operational tracker in 04-PMO-Operations/. Used by the Tracker Manager to validate updates, produce consolidated change summaries, and maintain data integrity.

> For the cross-artifact entity-derivation inventory (every operational artifact ↔  entity, template/schema status), see [operational-artifact-inventory.md](../specs/operational-artifact-inventory.md).

## Division of Labour (registered complementary pair)

This file is the **canonical** half of a registered complementary pair with
`operations/skills/tracker-manager/references/tracker-schemas.md`. The two are
**complementary, not duplicates** — neither is a copy or a subset of the other:

- **This file owns** the full field sets for **Trackers 1–10**, and is the sole
  home of **Trackers 5–10** (RAID Log, Artifact Register, Milestone Tracker,
  Stakeholder Register, RACI, Sprint Tracker).
- **The skill-local copy owns** **§ Tracker Integrity Rules** (the RAID dedup
  threshold, the cascade-trigger signal set, and the lifecycle-state predicate),
  which does **not** appear here.
- **Trackers 1–4 are shared** — both copies define them, and both are expected
  to agree. Where they do not, that divergence is a reported finding, not a
  silent difference.
- **A new tracker is defined HERE**, never in the skill-local copy.

The split is registered — with this ownership machine-checkable — in
`core/deploy/allowlists/complementary-reference-pairs.txt`, and asserted by
`deploy.sh --check` Check 13b. Moving a section across the pair without updating
that registry is a detected ownership breach, not a silent drift.

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
   - `source_inputs`: (Optional; Array) Structured provenance back-link — the raw evidence this
     decision was **extracted from**, as a list of `TR-###` / `MSG-###` / source-file-path tokens
     (same token domain as [`frontmatter-schema.md`](frontmatter-schema.md) Category 3
     `source_inputs`; see § Raw→Tracked Provenance). Written by tracker-manager on ADD, evidence-gated
     (omit when no establishing source is recoverable — never guessed). Distinct from the free-text
     `Evidence` field: `Evidence` narrates *why* the decision is needed; `source_inputs` is the
     machine-resolvable reverse link to the raw artifact that the forward `GENERATES` edge points at.
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
   - ID: ACT-### (auto-incremented per tracker, consistent with BLK-###/DEC-###; **namespaced and
     never reused**). This id is the stable anchor the raw→tracked `GENERATES` edge and the reverse
     back-link resolve against — added so an extracted action is edge-addressable (a re-write never
     reassigns it; see § Raw→Tracked Provenance).
   - Action: What they need to do
   - Source: Where the action was identified (transcript, meeting, email)
   - `source_inputs`: (Optional; Array) Structured provenance back-link — the raw evidence this
     action was **extracted from**, as a list of `TR-###` / `MSG-###` / source-file-path tokens
     (same token domain as [`frontmatter-schema.md`](frontmatter-schema.md) Category 3
     `source_inputs`; see § Raw→Tracked Provenance). Written by tracker-manager on ADD, evidence-gated
     (omit when no establishing source is recoverable). The machine-resolvable reverse-link complement
     to the free-text `Source` field.
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
   - Ticket: the retest item's external work-item identifier — the `source_system` + `external_id` pair per `entity-field-schemas.md` §3.0c (e.g. a Jira key, a GitHub issue number, a Smartsheet row id). Jira is one source system, not the only one.
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
- Agenda: Per the canonical meeting-agenda output-format spec [`meeting-agenda-format.md`](../standards/meeting-agenda-format.md) — numbered items with `@Name` owners and time allocations (this MTG-### field stores the agenda; the spec is the single source for its structure)
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
**Agent-native surface:** the machine-schema [`raid-log.schema.json`](raid-log.schema.json) — EAD-derived from the RAID Item entity — is the agent-native validation surface; the CSV above is its persistence *dialect*. The agent read/write path is native structured-instruction (no `csv` module on the agent path); `csv.DictReader` is the validator harness, not the agent path. The stakeholder-facing view (CSV export / Confluence) is produced on demand by **artifact-generator** via the [`dual-format-document-model.md`](../standards/dual-format-document-model.md) `raid-log--stakeholder-csv` translation map (per ADR-064) — not a bespoke export path. The **15-column** schema below (14 entity/legacy columns + the optional `source_ref` provenance **dialect** column) matches the schema-of-record [`raid-log.schema.json`](raid-log.schema.json); the entity surface is unchanged.

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
| source_ref | String | No | `TR-###` \| `MSG-###` \| artifact `id`-slug \| source-file path | Structured provenance back-link — which transcript / message / artifact **established** this row (the reverse half of the raw→tracked bridge; see § Raw→Tracked Provenance). Same token domain as `source_inputs` in [`frontmatter-schema.md`](frontmatter-schema.md) Category 3. A schema **dialect** column (per [`raid-log.schema.json`](raid-log.schema.json)), NOT an EAD entity-projected column — the frozen RAID Item entity surface is not reopened. Optional: a row whose establishing source is unrecoverable carries **no** `source_ref` rather than a guessed one (never stuffed into `Tags`). |
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
- **Local CSV (source of truth):** Full 15-column schema including RAID_ID, Date_Opened, Date_Closed, source_ref, and Section. This is the operational version used by all skills for processing, querying, and lifecycle management. It is the **system of record for RAID content** per [ADR-162](../ADRs/ADR-162-system-of-record-per-mirrored-element.md) (element **E1**): the Confluence view is a one-way render, and a Confluence-side edit is superseded by the next render rather than merged back.
- **Confluence (stakeholder-facing):** Manually uploaded by the workspace owner. Excludes internal operational fields (RAID_ID, Date_Opened, Date_Closed, source_ref, Section). Matches the stakeholder-visible format used before this schema overhaul.

**Rules:**
- All agent processing reads and writes the local CSV. Never reference RAID_IDs in stakeholder-facing output (chat summaries, status updates, meeting packages). Use descriptive references instead (e.g., "the ERP freeze window dependency" not "R-PPM-003").
- The workspace owner is responsible for syncing the Confluence version after local changes. The agent may remind the owner when significant RAID changes are approved but does not upload to Confluence directly.
- If a future MCP integration enables direct Confluence writes, the agent should strip internal fields before publishing.

**Governing model (proof-of-concept):** this RAID CSV→Confluence dual-format is the proof-of-concept instance of the general [Dual-Format Document Model](../standards/dual-format-document-model.md); the stakeholder rendering is its `raid-log--stakeholder-csv` translation map (the strip-internal-fields rule above, formalized). The model is the reusable seam for future dual-format artifacts — see that standard rather than re-deriving the strip rule per artifact.

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

## Tracker 8: Stakeholder Register
**File pattern:** `[Project]_Stakeholder_Register.csv`
**Update tier:** Tier 1 (stakeholder-facing — requires user approval for changes)
**Update sources:** PPM Agent processing, Change Management (stakeholder analysis), user input

The per-project **stakeholder engagement register** for the PMBOK 7 Stakeholder Performance Domain — one row per stakeholder, capturing identification, interest/influence classification, current vs. desired engagement, communication preferences, and the **typed decision authority** that graduates the SIOR escalation owner-resolution from free-text heuristic to structured lookup. The `Name` column is the project-altitude **engagement projection** of the people-graph: it resolves to the same `person_id` anchor as `team_roster` (membership projection) and the Resource entity (allocation projection) — three projections of one identity, never re-modeled inline.

### Structure
**Format:** CSV — one row per stakeholder.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Name | String | Yes | Free text (resolves to `Person.person_id`) | Stakeholder name. The engagement-projection join key into the people-graph (same anchor as `team_roster` + Resource). Names live in the operator-instance roster; the committed template carries `{{TOKEN}}` placeholders only. |
| Role | String | Yes | Free text | The stakeholder's role / title on the project. |
| Organization | String | Yes | Free text | Their org or department (internal team, vendor, customer). |
| Interest | Integer | Yes | 1–5 | Level of interest in the project outcome (1 = minimal, 5 = high). |
| Influence | Integer | Yes | 1–5 | Power to affect the project (1 = minimal, 5 = high). Interest × Influence drives the engagement-strategy quadrant. |
| Engagement | Enum | Yes | `Unaware` \| `Resistant` \| `Neutral` \| `Supportive` \| `Leading` | Current engagement posture (PMBOK stakeholder engagement-assessment scale). |
| Desired Engagement | Enum | Yes | `Unaware` \| `Resistant` \| `Neutral` \| `Supportive` \| `Leading` | Target posture; a gap between current and desired drives the engagement action. |
| Comm Preference | String | Yes | Free text (e.g., Email, Teams, 1:1, SteerCo) | Preferred communication channel. |
| Frequency | String | Yes | Free text (e.g., Weekly, Per-milestone, Ad hoc) | Communication cadence. |
| Decision Owner | Enum | No | `yes` \| `no` (default `no`) | Marks this stakeholder as the typed decision owner for its `Authority` domain. Read by `sior-escalation-protocol.md` § Decision-Owner Mapping for structured owner-resolution (replaces the free-text `## Key People` heuristic + warn-route). |
| Authority | Enum | No (**required when Decision Owner = `yes`**) | `schedule` \| `scope` \| `resource` \| `technical` \| `vendor` | The decision domain this stakeholder owns. The 5-domain set is identical to `sior-escalation-protocol.md` § Decision-Owner Mapping step 1, so the register is a drop-in structured source for that lookup. A `Decision Owner = yes` row with blank `Authority` is rejected (unresolvable domain). |
| Notes | String | No | Free text | Additional context (constraints, sensitivities, history). |

### Decision-Owner Resolution (SIOR upgrade)
When `sior-escalation-protocol.md` § Decision-Owner Mapping needs a named owner for a decision domain, it looks up the row where `Decision Owner = yes` AND `Authority = <domain>` and names that stakeholder — a **structured** resolution. This supersedes the free-text `## Key People` heuristic + warn-route-to-PgM fallback for projects that maintain a Stakeholder Register; the free-text path remains the graceful degradation when no register exists.

### person_id Consistency (with team_roster + Resource)
`Name` (and any `Decision Owner` row) resolves to the **same `person_id`** that `team_roster` and the Resource entity join on. The three are distinct **projections** of one identity — Stakeholder Register = engagement + decision authority, `team_roster` = team membership, Resource = per-project allocation — and MUST NOT carry inline person attributes that fork the never-committed roster (the ADR-040 compose-not-duplicate invariant; a row that re-models person attributes is a duplicate, a row that resolves to a `person_id` is the compose).

---

## Tracker 9: RACI
**File pattern:** `[Project]_RACI.md`
**Update tier:** Tier 1 (stakeholder-facing — responsibility assignment; requires user approval for changes)
**Update sources:** PPM Agent processing, Process Designer (role definition), user input

The per-project **responsibility-assignment matrix** for the PMBOK 7 Stakeholder Performance Domain — a workstream/deliverable (rows) × role/person (columns) grid whose cells assign Responsible / Accountable / Consulted / Informed. RAEW (Responsible/Accountable/Expert/Work) and RAS variants are referenced alternatives, not the default. Column-header roles resolve to the same `person_id` anchor as Tracker 8 + `team_roster`.

### Structure
**Format:** Markdown table — rows = workstreams/deliverables, columns = roles; the body cells hold the RACI code.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Workstream / Deliverable | String | Yes | Free text | The row axis — a workstream, phase, or named deliverable the assignment covers. |
| Role columns | Enum (per cell) | Yes | `R` \| `A` \| `C` \| `I` \| (blank) | One column per role/person; each cell is the RACI code. `R` = Responsible (does the work), `A` = Accountable (owns the outcome), `C` = Consulted (two-way input), `I` = Informed (one-way notification). |
| (row constraint) | Rule | Yes | exactly one `A` per row | Each workstream row has **exactly one Accountable**. A row with zero or ≥2 `A` cells is malformed (prose-enforced convention — no machine linter). |
| person_id mapping | Ref | Yes | each role column → `Person.person_id` | A companion "Person ↔ Role" block maps each column-header role to a `person_id` (same anchor as Tracker 8 + `team_roster`). Names live in the operator-instance roster; the committed template carries `{{TOKEN}}` placeholders. |

### Accountability Rule (exactly one A)
PMBOK/RACI discipline requires exactly one Accountable per workstream row. This is a documented convention checked at review (the platform has no RACI-specific machine validator — identical posture to the milestone-tracker gate rules, which are prose-enforced). A row violating it is flagged in review, not auto-rejected.

---

## Tracker 10: Sprint Tracker
**File pattern:** `[Project]_Sprint_Tracker.md`
**Update tier:** Tier 2 (operational — auto-write within `cascade_scope`)
**Update sources:** Delivery Engine Mode C — **LG-4 DoR exit PASS** at `T(6→7)` (item **admission**: the `ADD` that creates the pair row); Delivery Engine Mode F — **LG-5 Dev Complete (DoD) exit PASS** at `T(8→9)` (item close: the `MODIFY` that completes it); **end-of-sprint review** (team close)

The per-project **sprint / iteration tracker** for Scrum, XP, and Hybrid-iterative projects (the iteration-cadence tracker named in the § Methodology Variation matrix below), and the **capture surface for the estimate/actual pairs** that feed the estimation-calibration loop. [`estimation-standards.md`](../../operations/skills/delivery-engine/references/estimation-standards.md) **§ 8 owns the method** — the estimation ratio, the calibration-bias / calibration-spread pair, the bias band, the window floor, and every threshold. **This schema is § 8's INPUT contract and mints no threshold, no band, and no derived figure**; it defines only what is written down, by whom, and when. Its template is [`sprint-tracker-template.md`](../../operations/templates/sprint-tracker-template.md).

**Grain note (normative).** This tracker carries **two grains by design** — *iteration-grain* (`## Current Sprint`, `## Sprint History`) and *item-grain* (`## Estimate-Actual Pairs`, `## Capture Exceptions`) — alongside the existing *person-grain* `## Capacity Planning` block. The grains are **never pooled**: an item-grain population and an iteration-grain population are different units, and a single combined population is prohibited (§ 8.1 rule 1).

**Boundary (normative) — the release-pipeline throughput instrument is neither read nor written.** Every figure in this tracker is a **delivery-team** measurement. The release pipeline's own delivered-versus-planned throughput field, owned by [`release-velocity-tracking.md`](../../release/references/standards/release-velocity-tracking.md) § 8, is a **different concept that merely shares a shape** — that standard states the two never share a value, and names `estimation-standards.md` as the owner of the team-altitude figure. What this tracker reuses from that standard is its **conventions, by citation**: explicit-N/A (§ 5), grandfather-no-backfill (§ 10), the N = 3 calibration trigger (§ 6), and the parser-safety invariant (§ 12). **Cite the convention; share no value.** No routine defined here reads or writes that field.

### Structure

Six H2 sections; four carry the calibration path.

| Section | Grain | Rows | Role in the calibration path |
|---|---|---|---|
| `## Current Sprint` | iteration | single | Existing. Outside the calibration path. |
| `## Sprint History` | iteration | one per closed iteration | **F3** — delivered-versus-planned. |
| `## Estimate-Actual Pairs` | item | one per (item × signal family × close ordinal) | **F1 + F2** — re-scored size and elapsed time. |
| `## Capture Exceptions` | item | one per (item × signal family) close that produced no pair | The **positive negative-record** that makes a no-capture countable. |
| `## Capacity Planning` | person | one per team member | Existing. Outside the calibration path. |
| `## Velocity Trend` | iteration | narrative | Existing. Outside the calibration path. |

**Template parity (normative — fails closed, and its runner is named).** For each calibration-path section, the column headers of [`sprint-tracker-template.md`](../../operations/templates/sprint-tracker-template.md) MUST equal this section's field names, **in order**. Parity is what makes a row key *writable*: a template header missing a key component cannot express the key, so two records that the schema separates collide into one cell and the per-family denominator they feed is destroyed — the schema's rule holds while the surface that implements it silently cannot. **Unequal → FAIL; a header set that merely contains the field names in a different order is a FAIL, not a pass**, because a positional writer fills the wrong column.

The predicate is an ordered set-equality, so it is mechanically checkable — extract the first `|`-row under each of `## Estimate-Actual Pairs` and `## Capture Exceptions` in the template, extract the `Field`-column values of the corresponding field table here, and compare the two lists. **Runner (named, because a predicate nobody executes is indistinguishable in the artifact from a clean check):** [`pmo-skill-editor`](../../release/skills/pmo-skill-editor/SKILL.md) **Mode C (Regression)**, whose trigger is an edit to a skill or its consumers, run on any change to **either** file; and re-verified at **Stage 7 Dev Testing** ([`pmo-qa-auditor`](../skills/pmo-qa-auditor/SKILL.md) Mode G) on the PR that carries the change. **No CI job executes this check today** — that is stated rather than implied, so a reader does not mistake a named agent-run predicate for an automated one.

### Sprint History — F3 (delivered-versus-planned, iteration grain)

Existing columns are retained verbatim: `Sprint`, `Dates`, `Goal`, `Committed`, `Completed`, `Velocity`, `Carryover`, `Notes`. Two columns are added:

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Window Key | String | Yes | Free text — the iteration identifier | The window this iteration constitutes. Joins to `## Estimate-Actual Pairs` → `Window Key`, and is the key the § 8 window and its documented outlier exclusion are applied against. |
| Planned Items | Integer | Yes | ≥ 0 | Count of work **items** committed into the iteration — the **coverage denominator**. Pair count is rendered against it so the survivorship gap is visible rather than silent. Items, not points: deriving it from `Committed` would silently change the denominator's unit. |

**F3 mapping (normative — no new column).** `estimate` = `Committed`; `actual` = `Completed`; `Signal Family` = `F3`; grain = iteration. The existing **`Velocity` column is the team's own narrative figure and is NOT the calibration ratio** — do not overload it, and do not compute F3 from it.

### Estimate-Actual Pairs — F1 + F2 (item grain)

**Format:** Markdown table — one row per **(item × signal family × close ordinal)**. That triple is the row key; see § Row Key below for why the family is in it.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Item Ref | String | Yes | Free text — the work item's stable reference (ticket / item id) | Identity, never reassigned. **One of three key components** (see § Row Key) — `Estimate` and `Actual` are joined on the full key at report time, never on `Item Ref` alone. |
| Signal Family | Enum | Yes | `F1` \| `F2` \| `F3` — **only `F1` and `F2` are valid in this section** | The § 8.1 family. The enum domain is § 8.5's verbatim, so the two documents carry one vocabulary; `F3` is iteration-grain and is carried by `## Sprint History`, never by a row here. Families are never pooled (§ 8.1 rule 1). |
| Estimate | Number | Yes | `> 0` | **Frozen at `ADD`** — written by **Delivery Engine Mode C** when the item is admitted to execution at the LG-4 DoR exit PASS (see § Admission below) — and **never rewritten at close**. F1: the committed story-point figure (the § 5 range **midpoint**). F2: the § 2 committed-horizon budget, in **business days**. `Estimate = 0` is invalid: the ratio is undefined, so the row is rejected rather than stored. |
| Estimate Phase | Enum | Yes | `Initial concept` \| `Approved concept` \| `Requirements defined` \| `Design complete` \| `Build underway` | The § 1 cone row the estimate was made at. Required — § 8.4's realized-versus-claimed comparison is not computable without it, so a row missing it is incomplete rather than partially usable. |
| Start Date | Date | Yes | `YYYY-MM-DD` (not in the future) | The item's **LG-4 DoR exit PASS** date, written by **Mode C** at admission. **Written once, at the first admission, and immutable on every path thereafter** — see § Start-Date Immutability below. |
| Actual | Number | Yes | `≥ 0` | F1: the **blind** re-score assigned at close (see Capture Rule 5). F2: equal to `Elapsed`. **Never zero-filled to stand in for a missing value** — a synthesized zero is indistinguishable from a genuinely zero-effort item and would drag the window's bias toward 0. |
| Actual Date | Date | Yes | `YYYY-MM-DD` (not in the future) | The **LG-5 Dev Complete (DoD) exit PASS** date for this close ordinal. Same field semantics as Tracker 7's `Actual Date` (achieved date, populated on completion) — adopted, not re-coined. |
| Elapsed | Integer | Yes for `F2`; No for `F1` | ≥ 0, **business days** | Business days from the **first** `Start Date` to this row's `Actual Date`. **Cumulative across every reopen pass** — see § Cumulative Elapsed below. On an F2 row `Actual` MUST equal `Elapsed`; a disagreement is a validation failure, not a value to reconcile silently. |
| Window Key | String | Yes | Free text — the iteration identifier | The iteration this close lands in. Joins to `## Sprint History` → `Window Key`. |
| Close Ordinal | Integer | Yes | ≥ 1 | `1` at admission and on the first close; **incremented by 1 on each `REACTIVATE` → reclose**, in **lockstep across every family** for that `Item Ref`. With `Item Ref` **and `Signal Family`** it forms the row key (§ Row Key), and it is what makes a reopen a **visible second row** rather than an overwrite. Only the **last non-excluded** ordinal counts toward the window's `N`. |
| Evidence Grade | Enum | Yes | `[SOURCE]` \| `[INFERRED]` \| `[ASSUMPTION – CONFIRM]` | Adopted verbatim from § 8.5. **F1 is capped at `[INFERRED]`** — a re-score is itself an estimate. **F2 is `[SOURCE]`** — it is derived from two recorded gate verdicts rather than asserted. |
| Excluded Reason | String | No | Present **if and only if** the row is excluded: `superseded-by-reclose` \| `superseded-by-re-estimate` \| `start-date-corrected` \| `unit-change-pending-re-anchor` \| a documented outlier reason | Why this row does not count toward the window's `N`. An excluded row is **retained, never deleted** — append-only, the same posture as Tracker 6's `superseded` rule and the Tracker 5 archive rule. Deleting it would destroy the rework signal, which is the most informative thing a reopen carries. |

**No per-person attribution — by construction.** This table carries no person, assignee, or owner column, and none may be added. Per-person estimate-accuracy analysis is therefore **unrepresentable in the schema**, not merely discouraged.

### Admission — the `ADD` that creates the row (normative)

**A row is created at admission, not at close.** `estimation-standards.md` § 8.5's two-write contract binds here: the promise half (`Estimate`, `Estimate Phase`, `Start Date`) is written when the item is admitted to execution, and the close only completes it. **A `MODIFY` has no target until this `ADD` has run** — so an admission that emits nothing does not produce a late pair, it produces a permanently unwritable one.

| | Admission (`ADD`) | Close (`MODIFY`) |
|---|---|---|
| **Gate** | **LG-4 DoR exit PASS or CONDITIONAL PASS** at `T(6→7)` | **LG-5 DoD exit PASS or CONDITIONAL PASS** at `T(8→9)` |
| **Emitter** | Delivery Engine **Mode C** | Delivery Engine **Mode F** |
| **`fields:` map** | `Item Ref`, `Signal Family`, `Estimate`, `Estimate Phase`, `Start Date`, `Window Key`, `Close Ordinal`, `Evidence Grade` | `Actual`, `Actual Date`, and — on `F2` — `Elapsed` as recomputed by this skill |
| **`entry_id`** | blank (creating) | the row key of the row this close completes |
| **Never carries** | `Actual`, `Actual Date`, `Elapsed` | `Estimate`, `Estimate Phase`, `Start Date` |

**One `ADD` per signal family (normative).** An admitted item carries up to **two** promises — an F1 size figure and an F2 horizon budget — and they are **separate rows**, because one row cannot hold two `Estimate` values or two `Actual` values (see § Row Key below). Mode C emits **one `ADD` per family for which the item has an estimate of record at admission**, and **none** for a family that has none.

**Admission fails closed, and its failure is countable at close.** Mode C emits an `ADD` **only** when it can populate the full required field set for that family. It **never** zero-fills `Estimate`, never defaults `Estimate Phase`, and never emits a partial row — an item admitted without a size figure gets no F1 row, and the F1 gap surfaces at close as a `## Capture Exceptions` row with `no-estimate-of-record`. **A missing admission is therefore visible in the exception population rather than silent in the pair population** — which is the only reason a no-capture is countable at all. On an LG-4 **FAIL** or **NO-EVIDENCE**, no row is created and no exception is recorded: the item was not admitted, so nothing is owed.

**End-to-end executability (the property this section exists to hold).** *admit → row exists → close → `MODIFY` resolves → the actual is captured keyed to its frozen estimate.* Each arrow has a named emitter, a named gate, and a fail-closed negative path. **If any arrow has no emitter, the loop has no input and every downstream figure is `not computable` for a reason no consumer can see** — so the emitter is named here rather than assumed.

### Row Key — `Item Ref` × `Signal Family` × `Close Ordinal` (normative)

**The row key is a triple.** All three components are load-bearing, and dropping any one of them collapses two distinct records into one.

| Component | What it separates | What its absence collapses |
|---|---|---|
| `Item Ref` | one work item from another | two items' pairs into one population |
| **`Signal Family`** | **the size promise (F1) from the horizon promise (F2)** | **the two families of the same close into one row that cannot hold both** |
| `Close Ordinal` | one close pass from a later reclose | a reopen into a silent overwrite of the first close |

**Why `Signal Family` is in the key — one close owes two pairs.** § 8 requires an F1 pair **and** an F2 pair from the same item close, and the two are structurally incompatible in one row: **F1**'s `Estimate` is a story-point figure and its `Actual` is a blind re-score carrying **no `Elapsed` at all**; **F2**'s `Estimate` is a business-day budget and its `Actual` **MUST equal `Elapsed`**. One row holds one `Estimate` and one `Actual`, so it can carry one family or the other — never both.

Without the family in the key, the schema forces a choice between two defects, and **both are worse than the fix**:

| Option | What happens | Why it fails |
|---|---|---|
| One row per close | The close writes F1 **or** F2, never both | **F1 and F2 are then computed over disjoint item sets** — no item appears in both — so § 8.7 V2's F1/F2/F3 corroboration and the § 8.6 discordance rule compare populations that **share no items**. The corroboration reads as performed and corroborates nothing. |
| Two rows per close, family outside the key | Two rows collide on one key | The close `MODIFY`'s `entry_id` resolves to **two** rows; the write is ambiguous. Under the pre-fix Capture Rule 3 it also reads as the **two-rows defect** — the specified outcome scored as a violation. |

**Consequences (normative — each fails closed).**

1. **Uniqueness.** At most **one** row per `(Item Ref × Signal Family × Close Ordinal)`. Two rows sharing the full triple is a defect Mode F surfaces — never a silently accepted duplicate.
2. **`entry_id` resolves the full triple.** A close `MODIFY` whose `entry_id` does not identify all three components is **ambiguous and is rejected**, not resolved by guessing the family from the presence of an `Elapsed` field.
3. **Two families at one close is the specification, not a double-write.** An F1 row and an F2 row written from the same LG-5 exit PASS are **one record each in two different cells**. See Capture Rule 3.
4. **`Close Ordinal` advances in lockstep.** A `REACTIVATE` supersedes **every** non-excluded row for that `Item Ref` across **all** families, and the reclose writes a new row per admitted family at ordinal *n+1*. Bumping one family's ordinal without the other would let the two families' windows drift apart on the same item.
5. **`Start Date` is one value per `Item Ref`, spanning families and ordinals.** It is not part of the key and it never varies within an item — see § Start-Date Immutability.
6. **`## Capture Exceptions` keys on `(Item Ref × Signal Family × Close Date)`** for the same reason: a per-family coverage denominator cannot be filled by an exception that does not name its family.

### Cumulative Elapsed — the reopen-then-reclose closure (normative)

**`Elapsed` accumulates across every pass — first `Start Date` → the final DoD — and is NEVER reset on `REACTIVATE`.**

This is the rule the schema exists to enforce. If the clock restarted on reopen, a team could close an item early, reopen it, and reclose it, **manufacturing two short cycle times out of one long item** while every recorded figure stayed internally consistent. **No downstream consumer can detect that** — a consumer reading this tracker sees only numbers, with no way to distinguish one 20-day item from two 10-day items. The lever is therefore closed **here, at the capture surface, or nowhere.**

Three column semantics enforce it, so the rule is structural rather than an implementer's instinct:

1. **`Start Date` is write-once — on every path, not just `REACTIVATE`.** It is set at the first LG-4 DoR exit PASS and is unwritable thereafter by **any** action for **any** reason; an instruction carrying it after admission is **rejected**, not applied. Binding this to `REACTIVATE` alone left a plain corrective `MODIFY` unconstrained — see § Start-Date Immutability, which is where this rule is enforced in full.
2. **`Elapsed` is derived, never asserted.** It is computed as business days from the item's first `Start Date` to the current row's `Actual Date`. Because `Start Date` cannot move, `Elapsed` at ordinal *n+1* is necessarily **greater than or equal to** `Elapsed` at ordinal *n*.
3. **`Close Ordinal` makes the accumulation checkable.** A monotonicity check falls out of the two rules above and **fails closed**: for any `Item Ref`, `Elapsed` must be non-decreasing in `Close Ordinal` **across that item's `F2` rows** (`F1` rows carry no `Elapsed`, so they are outside this check by construction, not by exemption), and **every row for that `Item Ref` — in every family, at every ordinal — must carry the same `Start Date`**. A decrease, or two different `Start Date` values on one `Item Ref`, is a **defect Mode F surfaces** — never a value that is silently accepted, and never a row that is silently dropped. **This check alone is not sufficient**: it compares rows to each other, so a shift applied uniformly to all of them satisfies it. § Start-Date Immutability supplies the external anchor that closes that gap.

### Start-Date Immutability — closing the lever against every mutation path (normative)

**`Start Date` is the only field that moves every elapsed figure at once.** `Elapsed` is derived from it, so shifting it **later** shrinks the elapsed figure on every row of that item without touching a single `Actual`, `Actual Date`, or `Elapsed` value. It is the highest-leverage Goodhart target in this schema, and it is closed **here or nowhere** — no downstream consumer, reading only the numbers, can tell a genuinely fast item from a re-anchored slow one.

**What the § Cumulative Elapsed rules do not reach.** Those three rules are necessary and **not sufficient**, in two distinct ways:

| Gap | Why it was open |
|---|---|
| **Enforcement bound to the ACTION, not the FIELD** | The write-once rule named `REACTIVATE` and reclose. Every other action was unconstrained — and a plain corrective `MODIFY` is a **documented, required** operation (Capture Rule 6 uses one to set `Excluded Reason`). A corrective `MODIFY` that also carried `Start Date` violated no stated rule. |
| **Both checks are ROW-RELATIVE** | "Every ordinal must share one `Start Date`" and "`Elapsed` non-decreasing in `Close Ordinal`" compare an item's rows **to each other**. A shift applied **uniformly across every ordinal** leaves them agreeing with each other perfectly: all rows still share one value, and every `Elapsed` shrinks by the same amount, so the ordering is preserved. **The attack passes both stated checks while shrinking total elapsed on every item in the tracker.** |

Three closures, each failing closed:

**I1 — `Start Date` is writable on exactly one instruction, and the rule binds to the FIELD.** It may appear in a `fields:` map **only** on the admitting `ADD` at `Close Ordinal` 1. **Every** subsequent instruction — `MODIFY`, `CLOSE`, or `REACTIVATE`, in any family, at any ordinal, **for any stated reason including a corrective edit** — that carries `Start Date` is **rejected, not applied**, and the rejection is surfaced naming the `Item Ref`. There is no action, and no reason, that admits a second write.

**I2 — `Elapsed` is derived by the writing skill and never accepted as an asserted value.** It is recomputed at write time from the **stored** `Start Date` and the row's `Actual Date`. An instruction asserting `Elapsed` is rejected. On an `F2` row the emitter's `Actual` is then **checked against** the recomputed figure, and a disagreement is a validation failure — which makes the emitter's arithmetic and the stored anchor mutually checking rather than mutually trusting.

**I3 — the binding anchor is EXTERNAL to this tracker.** Because a uniform shift defeats every row-relative check, the check that closes it must compare against a value **outside the file a tracker edit can reach**: for every row, `Start Date` MUST equal the **LG-4 DoR exit-PASS date of record** for that `Item Ref`, as rendered in the gate verdict. A mismatch is a **defect Mode F surfaces** — **whether it affects one row or every row of the item**. This is the only one of the checks the uniform-shift attack cannot satisfy, because satisfying it would require editing the gate verdict, which is not this tracker's to edit.

**The uniform-shift attack, walked (the case the previous form passed).**

| Step | Old rules | With I1–I3 |
|---|---|---|
| A corrective `MODIFY` sets `Excluded Reason` **and** `Start Date`, applied to **every** ordinal of the item | Permitted — the write-once rule named only `REACTIVATE` | **Rejected at I1** — the field is unwritable after admission regardless of action or reason |
| Check: "every ordinal shares one `Start Date`" | **PASSES** — they all share the new value | Never reached; and **I3 FAILS** it against the gate verdict |
| Check: `Elapsed` non-decreasing in `Close Ordinal` | **PASSES** — every value shrank by the same *k*, ordering preserved | Never reached; `Elapsed` is recomputed from the stored anchor (**I2**) |
| Net effect | Total elapsed shrinks by *k* on every item, with both stated checks green | **No effect, and the attempt is surfaced** |

**The legal correction path — visible, never silent.** A `Start Date` genuinely recorded wrong is corrected by **exclusion and re-admission**, never by editing the field: set `Excluded Reason` to `start-date-corrected` on **every** row of that `Item Ref` in **every** family, then emit a fresh admission `ADD` at the next `Close Ordinal` carrying the corrected date. The correction costs the item its accumulated ordinals and leaves an append-only trail, so an item whose start date moved is **distinguishable from one whose never did** — which a field edit makes permanently impossible. Withholding any correction path at all is not the safer option: it does not stop the edit, it only stops the edit from being recorded.

### Capture Exceptions

The **positive record of a close that produced no pair.** Silence is the failure mode this section exists to foreclose: an item that closes with nothing written is invisible, and an invisible gap cannot be counted, reported, or fixed.

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|-------------|-------------|
| Item Ref | String | Yes | Free text | The item that closed without producing a pair. |
| Signal Family | Enum | Yes | `F1` \| `F2` | **The family this close produced no pair for.** Required, and part of the exception's key (§ Row Key): coverage is rendered **per family**, so an exception that does not name its family cannot be counted against a per-family denominator and the gap silently vanishes from the very population it exists to make visible. One close can produce a pair in one family and an exception in the other. |
| Window Key | String | Yes | Free text — the iteration identifier | The iteration the close landed in. Joins to `## Sprint History` → `Window Key`. |
| Close Date | Date | Yes | `YYYY-MM-DD` (not in the future) | The LG-5 exit-PASS date of the close that produced no pair. |
| Exception Reason | Enum | Yes | `no-estimate-of-record` \| `estimate-not-in-window` \| `item-descoped-at-close` \| `unit-change-pending-re-anchor` | **Closed set.** A closed set is what makes the exception population countable and lets coverage be rendered as a fraction; free text would not. A close fitting none of the four is a **defect Mode F surfaces**, never a silent skip and never a coerced fifth meaning. |

**The named consumer (normative — a section written by the capture path and read by no one is dead infrastructure).** This population is **read** by the calibration **coverage** line — grant **G13** in [`estimation-standards.md`](../../operations/skills/delivery-engine/references/estimation-standards.md) § 8.6 — rendered by **Delivery Engine Mode D** (the sprint-planning advisory) and **Mode E** (the calibration report). Coverage renders, **per family per window**, the pair count, **this section's exception count with its closed-set reason breakdown**, and the unclosed remainder, all against `## Sprint History` → `Planned Items`. The reason breakdown travels with the count because the four reasons imply different remedies — `no-estimate-of-record` is an **admission** gap (Mode C never emitted the `ADD`), `estimate-not-in-window` is a window-boundary effect of Capture Rule 9, `item-descoped-at-close` is genuine attrition, and `unit-change-pending-re-anchor` is a § 8.7 V5 exclusion.

**Why this is stated here rather than left implicit.** A write-only audit surface is **worse than an absent one**: it reads to a future maintainer as evidence that the gap is tracked, while nothing downstream ever counts it — so the silence this section exists to foreclose returns one layer further out, now wearing the appearance of coverage. **A coverage line rendering a pair count and a denominator but no exception count is a FAIL** (§ 8.6.2), and a change that removes the last reader of this section removes the section's reason to exist — **either the reader is re-wired or the section goes**, never a write with no read.

### Capture Rules (normative)

1. **Item trigger.** Capture fires when Delivery Engine Mode F renders an **LG-5 exit verdict** at `T(8→9)`. `PASS` → capture; `CONDITIONAL PASS` → capture (the increment is accepted); **`FAIL` or `NO-EVIDENCE` → no capture and no exception** — the item is still open and the gate will fire again. Capture binds to the **verdict**, never to a "done" claim.
2. **Iteration trigger.** The `## Sprint History` row is written at Mode F's **end-of-sprint review**, and **after** every item capture for that `Window Key` has landed. Writing it first would let `Completed` and the pair count disagree with no way to tell which is stale.
3. **Exactly-one-per-family rule (fails closed).** The unit this rule quantifies over is the **`(close × signal family)` cell**, not the close. For **each** of `F1` and `F2`, every LG-5 exit PASS produces **exactly one of**: one `## Estimate-Actual Pairs` row in that family, **or** one `## Capture Exceptions` row naming that family. A family the item was never admitted under (rule 12) takes the exception branch with `no-estimate-of-record`. **Zero records in a cell is a defect Mode F surfaces; two records in the SAME cell is a defect Mode F surfaces.** **Two records in DIFFERENT families at one close is the specified outcome, not a violation** — the F1 pair and the F2 pair are one record each in two different cells, which is precisely what the row key exists to keep apart (§ Row Key). Reading the specified two-family write as a double-write is the error this rule was previously stated loosely enough to cause. **A silent no-capture is never a valid outcome.**
4. **Never partial, never zero-filled.** A pair row carries the **full** required field set or is **not written at all** (a `Capture Exception` is written instead). `Estimate = 0` is invalid. A missing `Actual` is never filled with `0`.
5. **Blind re-score (F1).** The close instruction's `fields:` map carries **`Actual` and `Actual Date` only — it does not carry `Estimate`**, so the write path has no reason to load the original figure. The re-score elicitation **MUST NOT render the `Estimate` column**. `Estimate` and `Actual` are joined at **read** time on `Item Ref`. The honest limit: this tracker is a flat markdown table, so a determined reader can still look — these rules make anchoring a deliberate act off the specified path, not the default, and the § 8.7 `[INFERRED]` cap plus the F2/F3 corroboration rule are the compensating controls.
6. **`REACTIVATE`.** Retain the prior rows and set the `Excluded Reason` of **every** non-excluded row for that `Item Ref`, **in every family**, to `superseded-by-reclose`; the next LG-5 exit PASS writes a **new row per admitted family** at `Close Ordinal` *n+1*. Superseding one family and not the other would leave the two families' ordinals out of lockstep on the same item (§ Row Key consequence 4). Only the last non-excluded row **in each family** counts toward that family's `N` — counting every close would measure one estimate against two actuals.
7. **Elapsed is cumulative.** Per § Cumulative Elapsed above. This rule is not negotiable at implementation time: it is the one lever no downstream consumer can detect.
8. **Re-estimate on reopen.** A re-estimate **never overwrites** the frozen `Estimate`. Write a new row at ordinal *n+1* carrying the new figure and exclude the prior with `superseded-by-re-estimate`. Overwriting would drive the ratio toward 1.00 by construction.
9. **Window immutability.** A reclose after its window has closed lands in the **new** window; the prior window is **never recomputed**. The prior window records a `Capture Exception` with `estimate-not-in-window`, so the coverage loss is visible rather than silent.
10. **Unit re-anchoring.** A pair spanning a story-point re-anchoring is excluded (`unit-change-pending-re-anchor`) — comparing a pre- and post-anchor figure compares two different units.
11. **Forward-only.** **Never backfill a historical pair.** A reconstructed estimate is not the estimate that was made, and a backfilled population is exactly the survivorship-biased one § 8.7 V2 warns about. Capture is grandfathered forward from the point this surface lands, per `release-velocity-tracking.md` § 10's convention.
12. **Admission trigger — the rule that runs BEFORE rule 1.** Row creation fires when Delivery Engine **Mode C** renders an **LG-4 DoR exit verdict** at `T(6→7)`. `PASS` → `ADD`; `CONDITIONAL PASS` → `ADD` (the item is admitted to execution); **`FAIL` or `NO-EVIDENCE` → no `ADD` and no exception** — the item was not admitted, so no pair is owed. Admission binds to the **verdict**, never to a "refined" claim. **A close (rule 1) with no prior admission cannot write a pair** — it writes the `no-estimate-of-record` exception per rule 3 instead, and the coverage loss is visible rather than silent. See § Admission above for the per-family fan-out and the field split.
13. **`Start Date` never moves after admission.** Per § Start-Date Immutability: writable **only** on the admitting `ADD` (I1), `Elapsed` derived and never asserted (I2), and every row checked against the **external** LG-4 exit-PASS date of record (I3) — because the row-relative checks in § Cumulative Elapsed are all satisfied by a **uniform shift across every ordinal**, which shrinks total elapsed on every item. A genuine correction goes through exclusion (`start-date-corrected`) and re-admission, never a field edit.

### Runners for the capture-time checks (normative — named, because a fail-closed predicate nobody executes is indistinguishable in the artifact from a clean check)

Every check in § Row Key § Consequences, § Cumulative Elapsed rule 3 (the `Elapsed`-monotonicity and single-`Start Date` check), § Start-Date Immutability I1–I3, and § Capture Rules 3 is stated as failing closed and as surfacing a **defect**. This section names *what executes each of them*, so a reader cannot mistake a stated predicate for an enforced one.

**No CI job executes any of them, and none can.** These checks read a **populated tracker instance**, which is operator-local, git-ignored, Layer-2 operations content that never enters this repository (`CLAUDE.md` § Platform vs. Working Content Boundary). There is no artifact in the repo for a workflow to assert against, so automation is not a deferred improvement here — it is structurally unavailable. What follows is therefore the complete enforcement surface, not an interim one.

| Check | Runner | Trigger | Failure surface |
|---|---|---|---|
| I1 (`Start Date` writable only on the admitting `ADD`) · I2 (`Elapsed` derived, never asserted) | [`tracker-manager`](../../operations/skills/tracker-manager/SKILL.md), at the write | Every `MODIFY` / `CLOSE` / `REACTIVATE` instruction against this tracker | The instruction is **rejected** and the rejection surfaced naming the `Item Ref` — the write never lands |
| § Row Key § Consequences 1–6 · § Cumulative Elapsed rule 3 · § Capture Rules 3 (exactly-one-per-family) | [`delivery-engine`](../../operations/skills/delivery-engine/SKILL.md) **Mode F**, at the close gate | Every LG-5 exit verdict at `T(8→9)` — the same trigger that writes the row | Reported as a defect in the Mode F output; a `(close × family)` cell holding neither record, a duplicate on the full triple, or a decreasing `Elapsed` is named, never passed over |
| I3 (every `Start Date` equals the **external** LG-4 exit-PASS date of record) | `delivery-engine` **Mode F**, reading the gate verdict — **not** this tracker | Every LG-5 exit verdict, per row of the item | Reported as a defect whether it affects one row or every row — this is the only check the uniform-shift attack cannot satisfy, so it is the one that must not be skipped when the row-relative checks all read clean |
| The schema-conformance of any change to *these rules* (as distinct from the data) | [`pmo-skill-editor`](../../release/skills/pmo-skill-editor/SKILL.md) **Mode C (Regression)**, re-verified at **Stage 7 Dev Testing** ([`pmo-qa-auditor`](../skills/pmo-qa-auditor/SKILL.md) Mode G) | An edit to this section or to either consuming skill | Reported on the PR carrying the change |

**Two consequences of the operator-local siting, stated rather than left to be discovered.** First, a check that runs only inside an agent turn is only as good as the turn: a Mode F invocation that skips the reconciliation produces no signal at all, so the *absence* of a stated reconciliation in a Mode F output is itself the defect to look for — not evidence that the tracker was clean. Second, I3 is the only closure with an anchor outside this file; if the gate verdict it reads is unavailable, the correct outcome is an explicit `[ASSUMPTION – CONFIRM]` on the affected rows, **never** a silent fall-back to the row-relative checks, which the uniform-shift attack already passes by construction.

---

## Raw→Tracked Provenance

Every **extracted** tracker entry (a decision, action, risk, or meeting derived from raw evidence)
is linked back to the raw artifact it came from, and every raw artifact is linked forward to the
entries it produced. This makes the raw→tracked relationship a **first-class, bidirectional,
queryable bridge** rather than provenance that dies with the session. The bridge is **two
coordinated half-edges** resolving against the entry's stable namespaced id.

### The two half-edges

| Direction | Carrier | Where it lives | Written by |
|---|---|---|---|
| **Forward** (raw → entries) | `relationships: [{type: GENERATES, target: <entry-id>, …}]` | the **raw artifact's** frontmatter / sidecar (the transcript / message) | the upstream extraction / processing agent (ppm-agent; the transcript-intake sweep) — per [`frontmatter-schema.md`](frontmatter-schema.md) § Relationship Edge Population |
| **Reverse** (entry → raw) | `source_inputs[]` (markdown-tracker entries) · `source_ref` (RAID rows) | the **tracked entry** (a Daily Status Log `DEC-###`/`ACT-###` row; a RAID `source_ref` column) | **tracker-manager** on `ADD` |

`GENERATES` is the SHIPPED Source→Product verb ([`frontmatter-schema.md`](frontmatter-schema.md)
Relationship-Type table); its `target` resolves to the entry's stable id. This section **defines
the contract**; the forward-edge emit shape and the corpus-wide edge-population rules are owned by
`frontmatter-schema.md` § Relationship Edge Population and are **referenced, not restated** here.

### Resolvable both directions

- *From a raw artifact* → read its `relationships[] GENERATES` targets → the entry ids it produced.
- *From a tracked entry* → read its `source_inputs` / `source_ref` → the `TR-###` / `MSG-###` /
  source-file it was extracted from.

Both resolve against the entry's **stable namespaced id** (`DEC-###` / `ACT-###` / `MTG-###`;
RAID `R-[SKILL]-###`), which a tracker re-write never reassigns — renumbering would orphan every
inbound edge and back-link.

### Carrier split (do not unify the names)

The reverse link uses **two carriers scoped by the entry's container**, and they are deliberately
**not** unified into one field name:

- **Markdown-tracker entries → `source_inputs[]`** — Array; value domain `TR-###` | `MSG-###` |
  source-file path (identical to [`frontmatter-schema.md`](frontmatter-schema.md) Category 3
  `source_inputs`). The new entry-schema field defined on Tracker 1 (Daily Status Log) above and
  applicable to any extracted markdown entry.
- **RAID rows → `source_ref`** — the SHIPPED scalar dialect column (Tracker 5 above). A CSV row has
  no frontmatter, so its provenance is the dedicated `source_ref` field, **not** a `relationships[]`
  edge — the [`frontmatter-schema.md`](frontmatter-schema.md) § Relationship Edge Population
  **carrier exception**. Renaming `source_ref` → `source_inputs` would churn the frozen
  [`raid-log.schema.json`](raid-log.schema.json) schema-of-record and the dual-format render path
  for zero semantic gain; the carrier-scoped name is retained (same concept, container-scoped
  carrier).

Both are **evidence-gated**: an entry whose establishing source is not recoverable carries **no**
back-link rather than a guessed one (unrecoverable provenance is logged as an orphan-candidate, per
`frontmatter-schema.md` § Relationship Edge Population — never invented).

### Aggregation source-of-truth

The maintained **tracked (Domain-B) layer is the canonical input for status / rollup
aggregations** — it is `trust_category: controlled-truth`, carries `entry_count` +
`last_evidence_date`, and each entry carries its `source_inputs` / `source_ref`. Aggregations
(daily status, weekly rollup) therefore **read the tracked layer and cite tracker entries + their
provenance — they do NOT re-scan the raw transcripts**. Re-deriving a rollup from raw evidence
would bypass the controlled-truth layer and re-introduce the un-cited, un-provenance'd aggregation
this bridge exists to eliminate. (The write-side maintenance of this layer is
`tracker-manager` § Domain-B Frontmatter Maintenance; the read-side enforcement is the consuming
rollup skills' responsibility.)

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
| **Scrum** | Sprint-burndown + sprint-velocity trackers are primary health trackers; populated at sprint-cadence (daily burndown updates, velocity at sprint close). Risk register reviewed at sprint retro. Decisions tracker keyed to sprint boundaries. | `sprint-burndown.md`, `sprint-velocity.md`, `sprint-tracker.md`, `risks.md`, `decisions.md` | [SOURCE] Scrum Guide 2020 — sprint-scale health metrics. |
| **Kanban** | Flow-efficiency + cycle-time + throughput trackers are primary; no sprint-burndown. Populated continuously as work moves through board columns. Risk register reviewed at service-delivery-review cadence (typically bi-weekly). | `flow-efficiency.md`, `cycle-time.md`, `throughput.md`, `risks.md` | [SOURCE] Kanban Method — flow metrics over velocity. |
| **XP** | Inherits Scrum sprint trackers PLUS engineering-health trackers: CI-health, test-coverage, pair-rotation, refactor-frequency. Populated continuously (CI-driven) + iteration-cadence (pair-rotation review). | `sprint-burndown.md`, `ci-health.md`, `test-coverage.md`, `pair-rotation.md` | [SOURCE] XP engineering practices — governance-level requirements. |
| **Waterfall** | Milestone + phase-gate trackers are primary; no sprint-scale trackers. Populated at phase-gate cadence (sparse updates between gates). Change-control log is required tracker; replaces iteration-cadence decisions tracker. | `milestone-status.md`, `phase-gate-log.md`, `change-control-log.md`, `risks.md` | [SOURCE] PMBOK predictive-lifecycle reporting. |
| **PRINCE2** | Stage-boundary + highlight-report trackers; populated at end-stage-assessment + highlight-report cadence (weekly/bi-weekly per project tailoring). Issue register + lessons log are REQUIRED PRINCE2 trackers. | `stage-boundary.md`, `highlight-reports.md`, `issue-register.md`, `lessons-log.md` | [SOURCE] PRINCE2 2017 management products. |
| **SAFe** | Program Increment (PI) + ART-level trackers (multiple teams × multiple sprints). PI-objectives + ART-metrics (predictability, program-velocity) populated at PI cadence (8-12 weeks). Feature trackers supplement sprint trackers. | `pi-objectives.md`, `art-metrics.md`, `feature-progress.md`, `dependencies-map.md` | [SOURCE] SAFe 6.0 — PI + ART instrumentation. |
| **Hybrid** | Trackers partition by phase: predictive-phase uses milestone trackers (Waterfall-style); iterative-phase uses sprint or flow trackers. When `dual_framing_enabled: true`, requires Dual-Framing Bridge reporting that consolidates both framings per stakeholder audience (co-management is orthogonal to the Hybrid classification — see `project-schema.md § 7`). | Phase-specific | [INFERRED] PMBOK 7 hybrid + Dual-Framing Bridge convention in `operational-runbook.md`. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive tracker applicability from declared `lifecycle`, `ceremonies`, `artifacts`, `cadence` fields. Lifecycle=continuous → flow trackers; lifecycle=timeboxed → iteration trackers; lifecycle=phased → milestone trackers. Declared `ceremonies` drive tracker update cadence. | All trackers | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md). |

**Consumer guidance.** `tracker-manager` reads `delivery_approach` at invocation, consults this table, and scopes its update routines to the applicable trackers per the archetype. Full-matrix shape chosen because all 8 archetypes have distinct tracker compositions — no archetype inherits a common default pattern for tracker applicability.
