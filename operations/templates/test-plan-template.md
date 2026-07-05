---
artifact_type: template
template_family: Test plan / Test case
domain: software
canonical_path: operations/templates/test-plan-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: PMBOK 7 §Quality + Anthropic engineering:testing-strategy plugin convention
canon_compat: plugin-aligned
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered test-plan instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5(a)): `plugin-aligned` records the ANTICIPATED alignment path at DRAFT — authoritative only at an APPROVED transition. Registry basis: dual-anchor family — PMBOK 7 §Quality (quality-management framing) + plugin `engineering:testing-strategy` (engineer-facing structure), the registered cross-ref for the Test plan / Test case family per template-taxonomy.md §6 row 9 + §7 localization audit trail (inventory dated 2026-05-10). Live-plugin check 2026-07-03/04: the engineering:*/operations:*/product-management:* plugin suites are NOT installed in this workspace and NOT present in the marketplace roster — alignment is registry-anticipated, not live-verified. P5 re-evaluates against the live plugin at any future APPROVED transition. -->
# {{SCOPE_NAME}} Test Plan

**Purpose:** Plan and record the verification that {{SCOPE_NAME}} meets its requirements — quality objectives, test approach, cases, and the evidence trail from requirement to verdict.
**Canon:** PMBOK 7 §Quality (planning/control framing, requirement traceability) + Anthropic `engineering:testing-strategy` plugin convention (engineer-facing structure) — binding per `core/standards/template-taxonomy.md` §6 row 9. Plugin availability is re-verified at promotion (L4 gate P5).
**Author:** {{AUTHOR}} · **Status:** {{DRAFT | IN REVIEW | APPROVED | EXECUTING | COMPLETE}} · **Created:** {{CREATION_DATE}} · **Tracking:** {{TRACKING_REF}}

---

## Scope

**In scope:** {{SCOPE_IN}}
**Out of scope:** {{SCOPE_OUT}}

## Quality Objectives & Acceptance Criteria

| Objective | Acceptance criterion | Traces to requirement |
|---|---|---|
| {{OBJECTIVE_1}} | {{CRITERION_1}} | {{REQ_REF_1}} |
| {{ASSUMPTION – CONFIRM}} | | |

## Test Approach

| Level | In scope? | Types applied | Automation posture |
|---|---|---|---|
| Unit | {{YES/NO}} | {{FUNCTIONAL/REGRESSION/PERFORMANCE/SECURITY}} | {{AUTOMATED/MANUAL/MIXED}} |
| Integration | {{YES/NO}} | {{TYPES}} | {{POSTURE}} |
| System / End-to-end | {{YES/NO}} | {{TYPES}} | {{POSTURE}} |
| Acceptance (UAT) | {{YES/NO}} | {{TYPES}} | {{POSTURE}} |

## Test Environment & Data

{{ENVIRONMENT}} <!-- Environments, fixtures/data sets, access needs, reset procedure. -->

## Entry / Exit Criteria

**Entry:** {{ENTRY_CRITERIA}}
**Exit:** {{EXIT_CRITERIA}} <!-- e.g., 100% MUST-requirement cases executed; zero open Sev-1/Sev-2 defects; sign-off recorded. -->

## Test Cases

| ID | Traces to | Precondition | Steps | Expected result | Actual result | Status |
|---|---|---|---|---|---|---|
| TC-001 | {{REQ_REF}} | {{PRECONDITION}} | {{STEPS}} | {{EXPECTED}} | {{ACTUAL}} | {{NOT-RUN/PASS/FAIL/BLOCKED}} |
| {{ASSUMPTION – CONFIRM}} | | | | | | |

## Defect Management

{{DEFECT_MANAGEMENT}} <!-- Severity classes, triage flow, tracking system, re-test rule. -->

## Roles & Responsibilities

| Role | Person | Responsibility |
|---|---|---|
| {{ROLE_1}} | {{PERSON_1}} | {{RESPONSIBILITY_1}} |

## Schedule & Milestones

| Milestone | Target date | Depends on |
|---|---|---|
| {{MILESTONE_1}} | {{DATE_1}} | {{DEPENDENCY_1}} |

## Risks & Contingencies

| Risk | Likelihood / Impact | Contingency | Owner |
|---|---|---|---|
| {{RISK_1}} | {{L/I}} | {{CONTINGENCY_1}} | {{OWNER_1}} |

## Sign-off

| Approver | Role | Date | Verdict |
|---|---|---|---|
| {{APPROVER}} | {{ROLE}} | {{DATE}} | {{APPROVED/APPROVED-WITH-CONDITIONS/REJECTED}} |
