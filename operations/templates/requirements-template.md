---
artifact_type: template
template_family: Requirements (epics/features/stories)
domain: project
canonical_path: operations/templates/requirements-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-05
updated: 2026-08-03
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Planning Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered requirements artifact — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Requirements (epics/features/stories) family (template-taxonomy.md §3.4 carries no plugin cross-ref; the family takes no §6 row per §2.1 F4). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# Requirements Template — PMO Reference

## Purpose

This file provides the structured template and quality criteria for requirements
artifacts across delivery methodologies. The pmo-process-designer skill reads
this file in Mode A (Requirements & Process Design) to guide requirements
authoring, hierarchy construction, and quality validation.

---

## Requirements Hierarchy

All requirements decompose through a canonical hierarchy. The level of formality
and artifact type varies by methodology, but the decomposition principle is universal.

| Level | Artifact | Description | Owner | Traceability Link |
|-------|----------|-------------|-------|-------------------|
| **Strategic** | OKR / Strategic Theme | Business objective driving the initiative | Portfolio / Executive | Enterprise strategy |
| **Epic** | Epic / Initiative | Large body of work decomposable into features; hypothesis-driven (SAFe) or scope-defined (traditional) | Product Manager / Portfolio | Strategic Theme → Epic |
| **Feature** | Feature / Capability | Service or functionality that delivers user value; sized for a PI or release | Product Owner / PM | Epic → Feature |
| **Story** | User Story / Job Story | Smallest unit of user-visible value; sized for a single sprint | Product Owner | Feature → Story |
| **Task** | Task / Sub-task | Technical work to implement a story; not user-visible | Developer / Team | Story → Task |
| **Test** | Test Case / Acceptance Test | Verification that a requirement is satisfied | QA / Developer | Story → Test (bidirectional) |

---

## Requirement Record Template

Each requirement record includes these fields regardless of methodology:

| Field | Description | Required? |
|-------|-------------|-----------|
| **Requirement ID** | Unique identifier following naming convention (e.g., EPIC-001, FEAT-012, US-045) | Yes |
| **Title** | Concise descriptive name (< 80 characters) | Yes |
| **Description** | Full specification of the requirement; format varies by methodology (see below) | Yes |
| **Acceptance Criteria** | Testable conditions that define "done" for this requirement | Yes |
| **Priority** | Business priority using the project's prioritization framework (WSJF, MoSCoW, weighted scoring) | Yes |
| **Source** | Origin of the requirement (stakeholder, regulation, technical need, defect) | Yes |
| **Traceability Link — Up** | Parent requirement or strategic objective this traces to | Yes |
| **Traceability Link — Down** | Child requirements or test cases this decomposes into | Yes (populated as decomposition occurs) |
| **Status** | Current lifecycle state (Draft, Refined, Ready, In Progress, Done, Deferred, Rejected) | Yes |
| **Owner** | Person accountable for requirement clarity and acceptance | Yes |
| **Estimation** | Size estimate (story points, T-shirt, hours — per project convention) | Recommended |
| **Dependencies** | Other requirements or external factors this depends on | Recommended |
| **Risk/Assumptions** | Known risks or assumptions underlying this requirement | Recommended |

---

## Description Formats by Methodology

| Methodology | Format | Template | When to Use |
|-------------|--------|----------|-------------|
| **Scrum / Agile** | User Story | "As a [role], I want [capability] so that [benefit]." | Default for team-level requirements; focuses on user value |
| **Kanban** | Job Story | "When [situation], I want to [motivation] so I can [expected outcome]." | When context/situation matters more than role; useful for workflow-centric requirements |
| **SAFe** | Capability / Feature | "Enable [capability] for [users] by [mechanism] to achieve [business outcome]." | Program-level requirements; features sized for a PI |
| **Waterfall / PRINCE2** | Formal Requirement | Numbered requirement statement: "The system shall [action] [object] [constraint]." | Regulated environments; contractual requirements; auditable traceability required |
| **Hybrid** | Mixed | User stories for team-level; formal requirements for compliance/audit items | When both agile execution and formal governance are needed |

---

## INVEST Quality Criteria for User Stories

Every user story entering a sprint must satisfy INVEST (Bill Wake, 2003):

| Criterion | Definition | Validation Question | Failure Signal |
|-----------|------------|-------------------|----------------|
| **I — Independent** | Can be developed and delivered without requiring another story to be done first | "Can this story be built, tested, and released without waiting for another story?" | Stories with hard sequential dependencies; "Part 1 of 3" patterns |
| **N — Negotiable** | Details are open to conversation; not a rigid specification | "Can the team and PO discuss alternative approaches to deliver this value?" | Prescriptive implementation details in the description; no room for technical judgment |
| **V — Valuable** | Delivers identifiable value to a user or stakeholder | "If we shipped only this story, would someone care?" | Technical tasks disguised as stories; "refactor X" without user value framing |
| **E — Estimable** | Team can estimate the effort within acceptable uncertainty | "Can the team give a confidence-bounded size estimate?" | Story too vague to size; team says "we need to spike this first" |
| **S — Small** | Fits within a single sprint with margin | "Can this be completed within the sprint with time for testing and review?" | Stories that consume >50% of sprint capacity; multi-sprint stories |
| **T — Testable** | Has clear, verifiable acceptance criteria | "Can we write a test that proves this story is done?" | "Make the system better" or "improve performance" without measurable criteria |

**INVEST is a readiness check, not a quality standard.** A story can satisfy INVEST and still be poorly conceived. INVEST validates that a story is ready for sprint execution — it does not validate that the story is the right thing to build.

---

## Acceptance Criteria Writing Guide

### Given/When/Then Format (Gherkin)

The standard format for testable acceptance criteria:

```
Given [precondition / initial context]
When [action / event / trigger]
Then [expected outcome / observable result]
```

**Rules:**
- Each acceptance criterion is one Given/When/Then scenario
- A story typically has 3-7 acceptance criteria (fewer = under-specified; more = story too large)
- "Then" must be observable and verifiable — no subjective terms ("fast," "user-friendly," "intuitive")
- Negative scenarios (error cases, edge cases) are separate criteria, not embedded in happy-path scenarios

**Examples:**

| Quality | Example | Problem |
|---------|---------|---------|
| Good | Given a logged-in user with admin role, When they click "Delete User," Then the system displays a confirmation dialog with the user's name and a "Confirm Delete" button. | Clear precondition, specific action, observable outcome |
| Good | Given an order with status "Shipped," When the carrier reports delivery, Then the order status updates to "Delivered" and the customer receives a notification email within 5 minutes. | Includes timing constraint; testable |
| Poor | Given a user, When they do something, Then it works correctly. | Vague precondition, unspecified action, subjective outcome |
| Poor | The system should be fast and user-friendly. | Not in Given/When/Then; not testable; subjective |

### Alternative: Checklist Format

For non-behavioral requirements (configuration, data, infrastructure):

```
- [ ] [Specific verifiable condition]
- [ ] [Specific verifiable condition]
```

Use when Given/When/Then adds ceremony without clarity — typically for operational or infrastructure stories.

---

## Methodology Variation Table

| Aspect | Waterfall / PRINCE2 | Scrum | Kanban | SAFe | Hybrid |
|--------|-------------------|-------|--------|------|--------|
| **Primary artifact** | BRD → SRS → FRD (sequential) | Product Backlog (single ordered list) | Work items on board | Solution Intent + Program/Team Backlogs | BRD (upstream) + Product Backlog (execution) |
| **Hierarchy depth** | Full formal hierarchy with RTM | Epic → Feature → Story → Task | Flat or shallow (item types by class of service) | Portfolio Epic → Capability → Feature → Story (4 levels) | Full hierarchy upstream; backlog in execution |
| **Requirements format** | "The system shall..." formal statements | User stories with acceptance criteria | Job stories or minimal descriptions | Features with benefit hypothesis; stories with acceptance criteria | Formal for compliance items; stories for team work |
| **Readiness gate** | Requirements sign-off (baselined document) | Definition of Ready (team-owned, lightweight) | Commitment Point (explicit policies) | PI Planning readiness (analyzed state) | Requirements gate (formal) + DoR (sprint) |
| **Change mechanism** | Formal Change Request → CCB | PO reprioritizes backlog (no CR needed within sprint) | Continuous replenishment | PO reprioritizes; scope negotiation at PI boundaries | CR for baselined items; PO authority for backlog items |
| **Traceability** | Formal RTM (bidirectional, auditable) | Implicit in backlog hierarchy (Epic → Story links) | Minimal (board state is the record) | Explicit 4-level hierarchy; Solution Intent for regulated | RTM for compliance; backlog links for execution |
| **Quality check** | Formal review and sign-off per document | INVEST criteria at refinement | Explicit policies at commitment point | Analyzed state criteria; PI Planning readiness | Formal review upstream; INVEST in sprints |

---

## Anti-Patterns

| Anti-Pattern | Signal | Remediation |
|-------------|--------|-------------|
| **Requirement as solution** | "Build a dropdown with options A, B, C" instead of stating the need | Rewrite as user value: "As a [role], I want to select [option] so that [benefit]." Let the team determine implementation. |
| **Missing acceptance criteria** | Stories enter sprint with "TBD" or no acceptance criteria | Enforce INVEST-T at DoR gate; no story enters sprint without at least 3 testable acceptance criteria |
| **Orphan requirements** | Requirements with no upward trace to strategy or no downward trace to tests | Run traceability audit; every requirement must link up (to feature/epic) and down (to test case) |
| **Giant stories** | Stories that span multiple sprints or consume >50% of sprint capacity | Apply INVEST-S; decompose until each story fits within a sprint with margin |
| **Requirements as wish lists** | Unprioritized lists of features with no sizing, sequencing, or value assessment | Apply prioritization framework (WSJF, MoSCoW); every item gets priority, size, and value assessment |
| **Copy-paste requirements** | Same requirement copied across multiple documents; versions diverge | Single source of truth per requirement; link, do not copy |
