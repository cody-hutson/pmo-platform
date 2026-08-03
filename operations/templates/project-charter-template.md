---
artifact_type: template
template_family: Project Charter
domain: project
canonical_path: operations/templates/project-charter-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-29
updated: 2026-08-03
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Planning Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered [Project]_Project_Charter.md instance — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Project Charter family (template-taxonomy.md §3.4 carries no plugin cross-ref; the family takes no §6 row per §2.1 F4). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# {{PROJECT_NAME}} Project Charter

**Purpose:** Formally authorize the project and establish the sponsor's mandate, objectives, and high-level scope (PMBOK 7 §Planning Performance Domain — PMBOK 6 placed chartering in the Initiating process group).
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Purpose & Justification

{{PROJECT_PURPOSE}}

**Business case / driver:** {{BUSINESS_CASE}}

## Measurable Objectives & Success Criteria

| Objective | Success Metric | Target | Measured By |
|-----------|---------------|--------|-------------|
| {{OBJECTIVE_1}} | {{METRIC_1}} | {{TARGET_1}} | {{MEASURE_OWNER_1}} |
| {{ASSUMPTION – CONFIRM}} | | | |

## High-Level Scope

**In scope:** {{SCOPE_IN}}
**Out of scope:** {{SCOPE_OUT}}

## Milestone Summary

| Milestone | Target Date | Acceptance |
|-----------|------------|------------|
| Project start | {{CREATION_DATE}} | Charter approved |
| {{MILESTONE_1}} | {{ASSUMPTION – CONFIRM}} | {{MILESTONE_1_ACCEPTANCE}} |
| Go-live | {{GO_LIVE_TARGET}} | Cutover checklist complete |

## Budget Summary

| Category | Estimate | Funding Source |
|----------|---------|---------------|
| {{BUDGET_CATEGORY_1}} | {{BUDGET_ESTIMATE_1}} | {{FUNDING_SOURCE_1}} |

## Key Stakeholders

| Stakeholder | Role | Authority |
|-------------|------|-----------|
| {{SPONSOR_NAME}} | Executive Sponsor | Charter approval, funding |
| [OPERATOR_NAME] | Program Manager (TPM) | Delivery accountability |
| {{TECH_LEAD_NAME}} | Technical Lead | Technical decisions |

> Full engagement detail lives in the Stakeholder Register (`[Project]_Stakeholder_Register.csv`); this table is the charter-level summary.

## Assumptions & Constraints

- **Assumption:** {{ASSUMPTION_1}} `[ASSUMPTION – CONFIRM]`
- **Constraint:** {{CONSTRAINT_1}}

## High-Level Risks

| Risk | Potential Impact |
|------|-----------------|
| {{RISK_1}} | {{RISK_1_IMPACT}} |

> Risks are managed in the RAID Log (`[Project]_RAID_Log.csv`) once the project is active.

## Sponsor Authorization

| Approver | Role | Decision | Date |
|----------|------|----------|------|
| {{SPONSOR_NAME}} | Executive Sponsor | {{ASSUMPTION – CONFIRM}} | {{ASSUMPTION – CONFIRM}} |
