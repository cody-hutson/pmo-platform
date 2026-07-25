---
artifact_type: template
template_family: Change Impact Matrix
domain: project
canonical_path: operations/templates/change-impact-matrix-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-24
updated: 2026-07-24
generated_by: release-pipeline v3.89
reviewer: N/A
canon: PMBOK 7 §Stakeholder Performance Domain
canon_compat: none
version: v3.89
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered [Project]_Change_Impact_Matrix.md instance — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Change Impact Matrix / OCM artifact family (template-taxonomy.md §3.1 Stakeholder families carry no plugin cross-ref). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# {{PROJECT_NAME}} Change Impact Matrix

**Purpose:** Structured change-impact analysis for a version upgrade or go-live — one row per change topic, current→future state, level of impact, and the change-management response (PMBOK 7 §Stakeholder Performance Domain).
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Change Impact Analysis

One row per change topic. Capture the current→future state delta, rate the **Level of Impact**, name the impacted stakeholders and any customer impact, and state the change-management response for each topic.

| Topic | Current State | Future State | Change Summary | Level of Impact | Customer Impact | Impacted Stakeholders | Change Mgmt Plan | Notes |
|---|---|---|---|---|---|---|---|---|
| {{TOPIC_1}} | {{CURRENT_STATE_1}} | {{FUTURE_STATE_1}} | {{CHANGE_SUMMARY_1}} | {{IMPACT_LEVEL_1}} | {{CUSTOMER_IMPACT_1}} | {{IMPACTED_STAKEHOLDERS_1}} | {{CHANGE_MGMT_PLAN_1}} | {{NOTES_1}} |
| {{ASSUMPTION – CONFIRM}} | | | | | | | | |

### Legend — Level of Impact
- **High:** role or process fundamentally changes; significant retraining or workflow redesign required.
- **Medium:** noticeable change to a task or tool; guided first-use and a job aid suffice.
- **Low:** minor adjustment; awareness communication is enough.
