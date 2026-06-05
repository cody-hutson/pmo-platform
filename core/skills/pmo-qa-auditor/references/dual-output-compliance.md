# Dual Output Compliance — PMO Reference

## Purpose

This file defines the dual output rule and provides compliance checklists for
validating that every PMO skill operation produces both its primary artifact
AND its corresponding metadata/tracking entry. The pmo-qa-auditor skill reads
this file to validate dual output compliance across all skill outputs.

---

## The Dual Output Rule

**Rule:** Every artifact update produces two outputs:
1. **The artifact content** — the primary deliverable (document, entry, draft, analysis)
2. **The metadata/tracking entry** — the operational record (tracker update, log entry, status change, change summary)

The artifact without metadata is untracked work. Metadata without the artifact is
status theater. Both must exist for the operation to be complete.

**Rationale:** Single source of truth requires that every artifact change is recorded
in its governance layer. Without dual output, artifact state diverges from tracked
state — the most dangerous anti-pattern in document management (stale artifacts
create false confidence).

---

## Compliance Checklists by Output Type

### RAID Entry

| Output | Content | Compliance Check |
|--------|---------|-----------------|
| **Primary artifact** | Risk/Action/Issue/Decision entry with all required fields (ID, description, owner, status, severity/priority, response strategy, due date) | Entry exists with all fields populated; no [TBD] placeholders |
| **Metadata entry** | Next-action metadata: who does what by when; follow-up tag if applicable; RAID log update timestamp | Action item has specific owner (person, not team), specific date (day-of-week validated), and sufficient context for the owner to act |

### Communication Draft

| Output | Content | Compliance Check |
|--------|---------|-----------------|
| **Primary artifact** | Paste-ready communication (email body, Teams message, status update) in the correct voice and format for the audience | Draft is complete, audience-calibrated, and paste-ready — not a template with blanks |
| **Metadata entry** | Readiness assessment: audience identified, channel confirmed, timing appropriate, approvals needed (if any), dependencies on other communications | Readiness assessment explicitly states whether the draft is ready to send or what blocks it |

### Tracker Update

| Output | Content | Compliance Check |
|--------|---------|-----------------|
| **Primary artifact** | Data change in the tracker (status change, date update, owner reassignment, new entry) | Tracker file is actually written (write-first-speak-second); change is verifiable in the file |
| **Metadata entry** | Change summary: what changed, why, source of the change (transcript, meeting, user direction), timestamp | Change summary exists and references the source that triggered the update |

### Status Report

| Output | Content | Compliance Check |
|--------|---------|-----------------|
| **Primary artifact** | Status report content (RAG assessment, milestone progress, risk highlights, decisions needed) | Report contains actionable content — not just activity recaps; RAG backed by formula or threshold |
| **Metadata entry** | Status log entry: date, reporting period, key metrics snapshot, decisions/actions from the report | Log entry exists in the operational tracker; metrics are computed, not estimated |

### Meeting Recap

| Output | Content | Compliance Check |
|--------|---------|-----------------|
| **Primary artifact** | Recap document (attendees, discussion summary, decisions made, action items) | Recap captures decisions and actions, not just discussion topics |
| **Metadata entry** | Transcript register entry (if from transcript), action items extracted to relevant trackers, follow-up tags applied | Action items from recap are filed in the appropriate tracker, not just listed in the recap |

### Artifact Creation

| Output | Content | Compliance Check |
|--------|---------|-----------------|
| **Primary artifact** | New document or artifact (plan, analysis, template, design doc) | Document is complete per its template/schema; no placeholder sections |
| **Metadata entry** | File routing confirmation (correct folder per project structure), version entry, any upstream/downstream notifications required | File is written to the correct location per project folder structure; routing is confirmed |

---

## Exceptions: Single-Output Types

Some output types are inherently single-output. These are exempt from the dual
output rule because the primary artifact IS the tracking mechanism.

| Output Type | Why Single-Output | Governance Mechanism |
|-------------|------------------|---------------------|
| **Email (sent)** | The sent email is its own record; email system tracks delivery | Communications tracker captures send date, audience, purpose — but this is pre-send tracking, not post-send metadata |
| **Teams message (sent)** | The Teams message is its own record; platform tracks delivery and read receipts | No separate tracking required for informal messages; formal coordination messages may warrant tracker entry |
| **Git commit** | The commit message and diff are self-documenting; git history is the metadata | No separate tracking beyond the commit; PR body serves as the summary layer |
| **Verbal confirmation** | Spoken decisions are inherently ephemeral | NOT actually an exception — verbal decisions must be documented in writing to exist in the governance system; flag as a gap if verbal-only |

**The "verbal confirmation" trap:** If a decision or action exists only as a verbal
statement, it does not exist in the PMO governance system. The dual output rule
for verbal decisions is: (1) document the decision in writing, (2) update the
tracking artifact. Treating verbal confirmation as single-output is an anti-pattern.

---

## Validation Rules

Programmatic validation for dual output compliance:

| Rule | Check | Pass Criteria | Failure Type |
|------|-------|---------------|-------------|
| **Artifact exists** | File write operation completed successfully | File exists at expected path with non-zero content | Hard fail — artifact not created |
| **Metadata exists** | Tracking entry exists for the artifact operation | Tracker/log contains an entry dated within the same session as the artifact write | Soft fail — artifact exists but is untracked |
| **Timestamps align** | Artifact write timestamp and metadata entry timestamp are from the same session | Timestamps within the same session boundary | Warning — possible stale metadata |
| **Content consistency** | Metadata summary accurately reflects artifact content | Key facts in metadata match artifact content (dates, statuses, owners) | Hard fail — metadata describes a different state than the artifact |
| **No orphan metadata** | Metadata entries reference artifacts that exist | Every tracker entry pointing to a file resolves to an existing file | Warning — possible deleted or moved artifact |
| **No phantom artifacts** | Artifacts have corresponding metadata entries | Every artifact in auto-write folders has a tracker entry | Soft fail — untracked artifact |

---

## Anti-Patterns

| Anti-Pattern | Signal | Impact | Remediation |
|-------------|--------|--------|-------------|
| **Write without track** | Artifact created but no tracker/log entry | Invisible work; status reports miss the update; downstream processes unaware | Enforce metadata write as part of every artifact operation |
| **Track without write** | Status reported as "done" but artifact not written | Write-first-speak-second violation; false confidence | Verify artifact existence before confirming completion |
| **Metadata drift** | Tracker says "In Progress" but artifact shows "Complete" | Conflicting sources of truth; governance decisions made on stale data | Reconciliation audit at session boundaries; flag discrepancies as drift |
| **Verbal-only decisions** | Decision made in conversation but never documented | Decision does not exist in governance system; subject to revisionism | Every verbal decision triggers a documentation obligation |
| **Batch metadata** | Multiple artifact updates but single metadata entry covering all | Individual changes lose traceability; cannot audit specific changes | One metadata entry per artifact change; batch summaries supplement but do not replace individual entries |
