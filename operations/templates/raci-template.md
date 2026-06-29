# {{PROJECT_NAME}} RACI Matrix

**Purpose:** Assign Responsible / Accountable / Consulted / Informed for each workstream or deliverable (PMBOK Stakeholder domain; RAEW/RAS variants are references).
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Responsibility Assignment

Each cell ∈ {R, A, C, I, blank}. Exactly **one A** (Accountable) per row.

| Workstream / Deliverable | {{ROLE_1}} | {{ROLE_2}} | {{ROLE_3}} | {{ROLE_4}} |
|--------------------------|-----------|-----------|-----------|-----------|
| {{WORKSTREAM_1}} | A | R | C | I |
| {{WORKSTREAM_2}} | {{ASSUMPTION – CONFIRM}} | | | |
| {{ASSUMPTION – CONFIRM}} | | | | |

### Legend
- **R — Responsible:** does the work
- **A — Accountable:** owns the outcome (exactly one per row)
- **C — Consulted:** two-way input before the work
- **I — Informed:** one-way notification after the work

### Person ↔ Role Mapping

> Each column header above is a role; the person filling it resolves to a `person_id` (see `tracker-schemas.md` § Tracker 9). Names live in the operator-instance roster, not in this committed template.

| Role | Person | person_id |
|------|--------|-----------|
| {{ROLE_1}} | {{PERSON_1}} | {{PERSON_ID_1}} |
