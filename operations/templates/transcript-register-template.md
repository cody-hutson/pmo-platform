---
type: tracker
managed_by: tracker-manager
domain: managed
file_format: md
project: {{PROJECT_NAME}}
folder: 3-Operations
lifecycle_state: created
trust_category: controlled-truth
created_date: {{CREATION_DATE}}
entry_count: 0
---

# {{PROJECT_NAME}} Transcript Register

**Purpose:** Log of all transcripts processed for this project. Each entry records the source, classification, key outcomes, and which trackers were updated.
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Register

| # | Date | Source File | Meeting Type | Participants | Summary (2-3 sentences) | Tags | Trackers Updated |
|---|------|------------|-------------|-------------|------------------------|------|-----------------|
| (none) | | | | | | | |

---

## Notes

- Entries are added by the PPM Agent after processing each transcript through the File Router pipeline.
- Tags use the standard follow-up tag format: `[DECISION]`, `[RISK]`, `[COMMS]`, `[DELIVERY]`, `[TECHNICAL]`, `[PROCESS]`, `[CHANGE]`.
- "Trackers Updated" lists which operational artifacts were modified (DSL = Daily Status Log, CT = Communications Tracker, MT = Meetings Tracker, RAID = RAID Log).
