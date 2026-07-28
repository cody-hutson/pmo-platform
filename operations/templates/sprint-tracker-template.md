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

# {{PROJECT_NAME}} Sprint Tracker

**Purpose:** Sprint planning, velocity tracking, capacity management, and estimate/actual capture for Agile/Hybrid projects.
**Schema:** `core/schemas/tracker-schemas.md` § Tracker 10: Sprint Tracker
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}
**Jira Project:** {{JIRA_PROJECT_KEY}}

---

## Current Sprint

| Field | Value |
|-------|-------|
| Sprint | Sprint 1 |
| Dates | {{ASSUMPTION – CONFIRM}} |
| Goal | {{ASSUMPTION – CONFIRM}} |
| Committed Points | — |
| Completed Points | — |
| Carryover | — |

---

## Sprint History

| Sprint | Dates | Goal | Committed | Completed | Velocity | Carryover | Notes | Window Key | Planned Items |
|--------|-------|------|-----------|-----------|----------|-----------|-------|------------|---------------|
| (none) | | | | | | | | | |

*One row per closed iteration. `Committed` / `Completed` are the F3 delivered-versus-planned pair; the `Velocity` column is the team's own narrative figure and is not that ratio. `Window Key` joins to the two item-grain tables below. `Planned Items` is a count of items (not points) — the coverage denominator. Written at end-of-sprint review, after every item capture for that `Window Key` has landed.*

---

## Estimate-Actual Pairs

| Item Ref | Signal Family | Estimate | Estimate Phase | Start Date | Actual | Actual Date | Elapsed | Window Key | Close Ordinal | Evidence Grade | Excluded Reason |
|----------|---------------|----------|----------------|------------|--------|-------------|---------|------------|---------------|----------------|-----------------|
| (none) | | | | | | | | | | | |

*One row per (item × close ordinal), written at the LG-5 Dev Complete (DoD) exit PASS. `Estimate` is frozen when the item is admitted to execution and is never rewritten at close. `Start Date` is written once and is never reset on reopen, so `Elapsed` (business days) accumulates across every pass. A reopen supersedes the prior row via `Excluded Reason` and adds a new row at the next `Close Ordinal` — excluded rows are kept, never deleted. Full field definitions and rules: `core/schemas/tracker-schemas.md` § Tracker 10.*

---

## Capture Exceptions

| Item Ref | Window Key | Close Date | Exception Reason |
|----------|------------|------------|------------------|
| (none) | | | |

*Every item close lands exactly one record: a row above, or a row here. `Exception Reason` is a closed set — `no-estimate-of-record` · `estimate-not-in-window` · `item-descoped-at-close` · `unit-change-pending-re-anchor`. A close that produces neither record is a defect to surface, not a gap to leave silent.*

---

## Capacity Planning

| Team Member | Role | Availability (%) | Notes |
|-------------|------|------------------|-------|
| (populate from PROJECT.md Key People) | | 100% | |

---

## Velocity Trend

*Not yet established — requires 2-3 sprints of data.*
