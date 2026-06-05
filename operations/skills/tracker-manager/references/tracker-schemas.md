# Tracker Schemas — PMO Operational Trackers

## Purpose
Defines the schema for every operational tracker in 04-PMO-Operations/. Used by the Tracker Manager to validate updates, produce consolidated change summaries, and maintain data integrity.

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
- Status: NEEDS SCHEDULING / SCHEDULED / COMPLETED / CANCELLED
- Outcome: Post-meeting summary (populated after completion)
- Follow-up actions: Actions identified during meeting
- Transcript path: Link to transcript file (if recorded)

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

## Extensibility
To add a new tracker:
1. Define schema in this file (columns, types, valid values)
2. Create empty tracker file in 04-PMO-Operations/
3. Update PMO.md operational artifact index
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
