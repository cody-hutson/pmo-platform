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

*Row key: **(`Item Ref` × `Signal Family` × `Close Ordinal`)** — one row per admitted family per close, because one row holds one `Estimate` and one `Actual` and F1's blind re-score and F2's elapsed figure cannot share them. The row is **created at admission** (Delivery Engine Mode C, LG-4 DoR exit PASS — the `ADD`) and **completed at close** (Mode F, LG-5 Dev Complete (DoD) exit PASS — the `MODIFY`); a close with no prior admission has no row to modify and writes a `no-estimate-of-record` exception below instead. `Estimate`, `Estimate Phase`, and `Start Date` are frozen at admission and are never rewritten on any later path. `Start Date` is never reset on reopen, so `Elapsed` (business days) accumulates across every pass. A reopen supersedes the prior row via `Excluded Reason` — in **every** family, in lockstep — and adds a new row at the next `Close Ordinal`; excluded rows are kept, never deleted. Full field definitions and rules: `core/schemas/tracker-schemas.md` § Tracker 10.*

---

## Capture Exceptions

| Item Ref | Signal Family | Window Key | Close Date | Exception Reason |
|----------|---------------|------------|------------|------------------|
| (none) | | | | |

*Row key: **(`Item Ref` × `Signal Family` × `Close Date`)** — the triple the schema's § Row Key consequence 6 names. The unit is the **`(close × signal family)` cell**, not the close: for **each** of `F1` and `F2`, every LG-5 exit PASS lands exactly one record — a row in `## Estimate-Actual Pairs` in that family, **or** a row here **naming that family**. One close can produce a pair in one family and an exception in the other, so an exception that does not name its family cannot be counted against the **per-family** coverage denominator and the gap vanishes from the population this section exists to make visible. `Window Key` is a **required attribute, not a key component** — it is the join to `## Sprint History` → `Window Key`, whose `Planned Items` is the denominator this row is counted against; it is not derivable from `Close Date` (a date does not resolve an iteration boundary), and Capture Rule 9 makes the landing window a **recorded** fact rather than a derived one, since a reclose after its window has closed lands in the **new** window while the prior window keeps the `estimate-not-in-window` exception. `Exception Reason` is a closed set — `no-estimate-of-record` · `estimate-not-in-window` · `item-descoped-at-close` · `unit-change-pending-re-anchor`. This population is **read** — the calibration coverage line renders pairs against `Planned Items` **and** the exception count per family (`estimation-standards.md` §8.6 grant **G13**); a close that produces neither record is a defect to surface, not a gap to leave silent.*

---

## Capacity Planning

| Team Member | Role | Availability (%) | Notes |
|-------------|------|------------------|-------|
| (populate from PROJECT.md Key People) | | 100% | |

---

## Velocity Trend

*Not yet established — requires 2-3 sprints of data.*
