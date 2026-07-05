---
artifact_type: template
template_family: PRD / Feature spec
domain: software
canonical_path: operations/templates/prd-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: Anthropic product-management:write-spec plugin convention
canon_compat: plugin-aligned
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered PRD instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5(a)): `plugin-aligned` records the ANTICIPATED alignment path at DRAFT — authoritative only at an APPROVED transition. Registry basis: plugin `product-management:write-spec` is the registered cross-ref for the PRD family per template-taxonomy.md §6 row 5 + §7 localization audit trail (inventory dated 2026-05-10); this template carries the industry-standard PRD section set (secondary field-shape reference Aha! / Lenny Rachitsky). Live-plugin check 2026-07-03/04: the engineering:*/operations:*/product-management:* plugin suites are NOT installed in this workspace and NOT present in the marketplace roster — alignment is registry-anticipated, not live-verified. P5 re-evaluates against the live plugin at any future APPROVED transition. -->
# {{PRODUCT_OR_FEATURE}} — Product Requirements Document

**Purpose:** Define WHAT to build and WHY — the problem, the users, the success measures, and the requirements — so engineering and design can decide HOW.
**Canon:** Anthropic `product-management:write-spec` plugin convention (secondary field-shape reference: Aha! / Lenny Rachitsky PRD template) — binding per `core/standards/template-taxonomy.md` §6 row 5. Plugin availability is re-verified at promotion (L4 gate P5).
**Author:** {{AUTHOR}} · **Status:** {{DRAFT | IN REVIEW | APPROVED}} · **Created:** {{CREATION_DATE}} · **Tracking:** {{TRACKING_REF}}

---

## Problem Statement

{{PROBLEM}} <!-- The user/business problem with evidence (data, quotes, tickets). Not the solution. -->

## Goals & Success Metrics

| Goal | Metric | Target | Measured By |
|---|---|---|---|
| {{GOAL_1}} | {{METRIC_1}} | {{TARGET_1}} | {{MEASURE_OWNER_1}} |
| {{ASSUMPTION – CONFIRM}} | | | |

## Non-Goals

- {{NON_GOAL_1}} <!-- Explicitly out of scope, and why. -->

## Users & Use Cases

| Persona / User | Scenario | Today's workaround |
|---|---|---|
| {{PERSONA_1}} | {{SCENARIO_1}} | {{WORKAROUND_1}} |

## Requirements

| ID | Requirement | Priority (MoSCoW) | Acceptance Criteria |
|---|---|---|---|
| REQ-001 | {{REQUIREMENT_1}} | {{MUST/SHOULD/COULD/WONT}} | {{ACCEPTANCE_1}} |
| {{ASSUMPTION – CONFIRM}} | | | |

## User Experience & Flow Notes

{{UX_NOTES}} <!-- Key flows, states, empty/error cases; link design artifacts rather than embedding. -->

## Dependencies, Risks & Assumptions

| Type | Item | Owner | Mitigation / Validation |
|---|---|---|---|
| {{DEPENDENCY/RISK/ASSUMPTION}} | {{ITEM_1}} | {{OWNER_1}} | {{MITIGATION_1}} |

## Launch / Rollout Plan

{{ROLLOUT}} <!-- Phasing, flags, migration, comms, success checkpoint after launch. -->

## Open Questions

- {{OPEN_QUESTION_1}}
