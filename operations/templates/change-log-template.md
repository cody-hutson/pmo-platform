---
artifact_type: template
template_family: Change Log
domain: project
canonical_path: operations/templates/change-log-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-29
updated: 2026-08-03
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Project Work Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered [Project]_Change_Log.md instance — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Change Log family (template-taxonomy.md §3.5 carries no plugin cross-ref; the family takes no §6 row per §2.1 F4). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# {{PROJECT_NAME}} Change Log

**Purpose:** Track change requests against the project baseline (scope, schedule, cost) with impact and approval (PMBOK Project Work; Waterfall change-control log).
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Change Requests

| CR ID | Date Raised | Requested By | Description | Type | Impact (Scope/Schedule/Cost) | Status | Decision Owner | Decision Date |
|-------|------------|-------------|-------------|------|------------------------------|--------|---------------|--------------|
| CR-001 | {{DATE_RAISED}} | {{REQUESTED_BY}} | {{CHANGE_DESCRIPTION}} | {{CHANGE_TYPE}} | {{CHANGE_IMPACT}} | {{CHANGE_STATUS}} | {{DECISION_OWNER}} | {{ASSUMPTION – CONFIRM}} |
| {{ASSUMPTION – CONFIRM}} | | | | | | | | |

### Type Key
- **Scope** — adds/removes deliverable scope
- **Schedule** — moves a baselined date
- **Cost** — changes budget
- **Quality** — alters acceptance criteria

### Status Key
- **Raised** — logged, not yet assessed
- **Assessing** — impact analysis in progress
- **Approved** — authorized; baseline updated
- **Rejected** — declined, with rationale
- **Deferred** — parked for a later decision

---

## Baseline Change History

| Date | Baseline Item | From | To | Driving CR |
|------|--------------|------|----|-----------|
| {{ASSUMPTION – CONFIRM}} | {{BASELINE_ITEM}} | {{FROM_VALUE}} | {{TO_VALUE}} | CR-### |
