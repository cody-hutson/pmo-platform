---
artifact_type: template
template_family: RACI / RAEW / RAS
domain: project
canonical_path: operations/templates/raci-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-29
updated: 2026-08-03
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Stakeholder Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered [Project]_RACI_Matrix.md instance — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the RACI / RAEW / RAS family (template-taxonomy.md §3.1; §6 row 8 records "no direct plugin"). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

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
