<!-- reference-durability: allow-link -->
# Tracker Schemas — PMO Operational Trackers

## Purpose
Defines the schema for every operational tracker in 04-PMO-Operations/. Used by the Tracker Manager to validate updates, produce consolidated change summaries, and maintain data integrity.

## Division of Labour (registered complementary pair)

This file is the **skill-local** half of a registered complementary pair with
`core/schemas/tracker-schemas.md`. The two are **complementary, not duplicates**:

- **This file owns** **§ Tracker Integrity Rules** — the RAID dedup threshold,
  the cascade-trigger signal set, and the lifecycle-state predicate. That section
  appears **only** here.
- **The canonical copy owns** the full **Tracker 1–10** field sets, and is the
  sole home of **Trackers 5–10**.
- **Trackers 1–4 are shared** — both copies define them, and both are expected
  to agree. Where they do not, that divergence is a reported finding, not a
  silent difference.
- **Do not define a new tracker here.** New trackers are defined in
  `core/schemas/tracker-schemas.md`.

The split is registered — with this ownership machine-checkable — in
`core/deploy/allowlists/complementary-reference-pairs.txt`, and asserted by
`deploy.sh --check` Check 13b.

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
- Agenda: Per the canonical meeting-agenda output-format spec [`meeting-agenda-format.md`](../../../../core/standards/meeting-agenda-format.md) — numbered items with `@Name` owners and time allocations (this MTG-### field stores the agenda; the spec is the single source for its structure)
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

## Tracker Integrity Rules

Write-side integrity guards the Tracker Manager applies during the Processing Cycle. These are
**advisory by design** — they flag for operator confirmation rather than silently suppressing a
legitimate entry — but they must run. The Processing Cycle insertion points are Step 1.5 (dedup),
Step 2.5 (cascade), and the top of Step 5 (lifecycle). This section is the single queryable home
for the three parameters; the SKILL.md steps reference it by role.

### RAID Deduplication

| Parameter | Value |
|---|---|
| **Fires on** | `action: ADD` targeting a RAID Log artifact ONLY. MODIFY / CLOSE / REACTIVATE exempt (they reference an existing `entry_id` — no new entry is created). Non-RAID trackers exempt. |
| **Comparison field** | The RAID `Description` (free-text risk / issue / assumption / dependency statement). |
| **Comparison scope** | **ACTIVE-section rows only** (`Section = ACTIVE`). ARCHIVE rows excluded — a closed historical risk is not a live duplicate. Same-`RAID Category` rows are the **primary** set; cross-category matches surface at a **lower-confidence note** only (a Risk and an Issue describing the same condition is an escalation lineage, not a duplicate). |
| **Method** | Normalized **token-set (Jaccard) similarity** on `Description`: lowercase → strip punctuation → drop a small stopword set → compare token sets via `|A∩B| / |A∪B|`. Computed by the LLM agent reasoning over the two strings (no library import). Jaccard chosen over cosine / embedding similarity: no embedding substrate ships in-repo, and token-set Jaccard is transparent and hand-reproducible for short RAID descriptions (the "no over-engineering" choice). |
| **Threshold** | **≥ 0.70 (70%) → flag** as a probable duplicate. Adopted as the documented design value from the parent story's stated `>70%`; there is no in-repo RAID-description distribution to empirically tune against (operator RAID logs are Layer-2, git-ignored). Operator decision item: adopt 70% as-stated (recommended) vs. tune at build. |
| **Action** | **Flag, never auto-block.** A ≥ 0.70 match surfaces as a decision-class line in the Step-2 consolidated summary — matched ID, similarity score, reversibility tier — e.g. `RAID ADD (R-PPM-014) — probable duplicate of R-PPM-012 (0.82 similarity); confirm new entry or merge. [CHEAP · confidence: HIGH]`. Below 0.70 on every ACTIVE row → no flag. A wrongly-suppressed RAID entry is a silent loss, worse than a flagged near-duplicate — hence advisory. |

### Cascade-Trigger Rules

tracker-manager does **NOT** discover cascades. Cascade discovery is owned by **ppm-agent
Section 8.6** (the deterministic dependency scan that emits the `TRACKER_IMPACT_MATRIX` with
DIRECT / SECONDARY rows, which this skill already consumes and validates). This guard is a
**presence check** on the handoff contract — it asserts the upstream scan ran, then renders what
the matrix found. It does not re-derive the cascade.

| Parameter | Value |
|---|---|
| **Scope-change signal (trigger — fires WHEN any holds)** | (i) a RAID `ADD` / `MODIFY` whose `RAID Category = Dependency` or `Scope` (the Scope risk sub-category per `delivery-engine/references/raid-templates.md` § 1.2); OR (ii) a `MODIFY` changing a milestone / date / deliverable field on a Tier-1 tracker; OR (iii) an update whose `reason` names a scope change (re-scoping, descope, added / removed deliverable). Routine updates (blocker closes, meeting completions) carry no signal → guard does not fire. |
| **Assertion** | An accompanying `TRACKER_IMPACT_MATRIX` is present for the run AND contains a row (DIRECT or SECONDARY) keyed to this update, OR an explicit `No secondary effects identified` record for it. |
| **Discovery owner** | ppm-agent § 8.6 (reference-by-role). tracker-manager renders the matrix's SECONDARY rows as the "downstream impacts of this scope change"; it does not find them. |
| **Action** | Matrix present → list the SECONDARY rows in the consolidated summary. Matrix absent / silent on a scope-change update → **flag**: `Cascade-unverified: scope-change update (R-PPM-014) arrived without a Tracker Impact Matrix entry — route through ppm-agent §8.6 dependency scan before applying. [MODERATE · confidence: HIGH]`. MODERATE because un-scanned secondary effects, if written, leave trackers internally inconsistent (days-to-reconcile). |

This is the write-side mirror of ppm-agent's `TRACKER_UPDATES emitted without the Section 8.6
dependency scan` failure mode — read-side enforces emitting the matrix; this guard enforces
receiving it before writing a scope change.

### Lifecycle-State Predicate

Before any write, validate that the target artifact is still a live document. The predicate reads
the target **FILE's** `lifecycle_state` frontmatter (`core/schemas/frontmatter-schema.md`
§ Category 2 — a real, REQUIRED field; operational trackers / RAID registers are **Domain B**).
This is distinct from the RAID **row's** own status (Open / Monitoring / Mitigating / Escalated /
Closed) — the predicate asks "is the artifact I'm about to write to still live?", not "what is the
state of this RAID row?". Domain-B value set is referenced from the schema and
`core/standards/lifecycle-states-canonical.md` § 4.2 by role — only the block / flag set is
restated here.

| Target artifact `lifecycle_state` | Disposition |
|---|---|
| `current` / `emerging` / `needs-review` (live Domain-B states; `active` tolerated as a Domain-A alias) | **PROCEED** — write allowed |
| `archived` / `superseded` | **BLOCK + flag** — refuse the write: `Write refused: target [Project]_RAID_Log.csv is lifecycle_state=archived — updating a closed/archived artifact. Confirm reactivation or redirect to the current artifact. [MODERATE · confidence: HIGH]` |
| `stale` (Domain B) | **FLAG, proceed-on-confirm** — stale ≠ closed; warn the artifact is past its staleness window and the update may land on out-of-date content |
| **absent / unparseable / unknown enum** | **`unknown → flag`** — low-noise advisory, never silent-pass and never hard-block: `Lifecycle-state unknown for [target] (frontmatter field absent or unreadable) — confirm the target is a live artifact before write. [MODERATE · confidence: HIGH]` |

**Low-noise discipline (top regression risk).** Many operator trackers do not yet carry the
field. Scope the **BLOCK** strictly to `archived` / `superseded`. `unknown` on an established
operational tracker — a routine Daily-Status / Comms / Meetings / Transcript auto-write on a
field-less `.md` — must produce an **advisory note, NOT an approval gate**. The `unknown → flag`
default honors the parent card's dependency clause ("if not uniformly present, default to 'state
unknown → flag for confirmation' rather than silently passing").

**CSV-artifact lifecycle source.** A `.csv` RAID artifact carries no YAML frontmatter line. Read
its lifecycle state from the co-located project context (PROJECT.md artifact registry) where
available; absent → `unknown → flag`. Do not crash on "no YAML in a `.csv`."

> Scope note: this is the **skill-local operational** reference. The entity-derived canonical
> schema at `core/schemas/tracker-schemas.md` is the EAD-derived authority and is left untouched
> by these integrity rules.

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
