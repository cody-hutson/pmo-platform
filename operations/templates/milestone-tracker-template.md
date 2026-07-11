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

# {{PROJECT_NAME}} Milestone Tracker

**Purpose:** Phase-gate milestone tracking with evidence for Waterfall/Hybrid projects.
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Phase-Gate Milestones

| Phase | Milestone | Planned Date | Actual Date | Status | Gate Criteria | Evidence | Owner |
|-------|-----------|-------------|-------------|--------|--------------|----------|-------|
| Initiation | Project charter approved | {{ASSUMPTION – CONFIRM}} | | Not Started | Charter signed by sponsor | | {{SPONSOR_NAME}} |
| Initiation | Stakeholders identified | {{ASSUMPTION – CONFIRM}} | | Not Started | RACI complete | | [OPERATOR_NAME] |
| Planning | Requirements baselined | {{ASSUMPTION – CONFIRM}} | | Not Started | Requirements doc approved | | |
| Planning | Schedule approved | {{ASSUMPTION – CONFIRM}} | | Not Started | Timeline reviewed by SteerCo | | |
| Execution | Design complete | {{ASSUMPTION – CONFIRM}} | | Not Started | All FDDs approved | | |
| Execution | Testing complete | {{ASSUMPTION – CONFIRM}} | | Not Started | Exit gate criteria met | | |
| Go-Live | Cutover readiness | {{GO_LIVE_TARGET}} | | Not Started | Cutover checklist complete | | |
| Go-Live | Go-live | {{GO_LIVE_TARGET}} | | Not Started | Production deployment | | |
| Hypercare | Stabilization | Post go-live | | Not Started | Issue rate below threshold | | |

---

## Status Key
- **Not Started** — Phase not yet begun
- **In Progress** — Active work underway
- **At Gate** — Phase work complete, awaiting gate review
- **Passed** — Gate criteria met, approved to proceed
- **Blocked** — Cannot proceed, see RAID log

---

## Gate Review Log

| Phase Gate | Review Date | Decision | Attendees | Notes |
|-----------|------------|----------|-----------|-------|
| (none) | | | | |
