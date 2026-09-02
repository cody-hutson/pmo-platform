---
artifact_type: template
template_family: Program Charter
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/program-charter-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-09-01
updated: 2026-09-01
generated_by: release-pipeline v4.46
reviewer: N/A
canon: The Standard for Program Management (PMI)
canon_compat: none
version: "v4.46"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered Program Charter — an instance starts at the second H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Program-tier governance family (template-taxonomy.md §8's convention-anchor list carries no program-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# Program Charter Template (PMI)

The authorizing document for a program: the coordinated set of projects and operational
work managed together to obtain benefits **not available from managing them separately**.
That last clause is the whole test — a program whose components would deliver the same
benefits run independently is a reporting grouping, not a program, and this charter should
not be written for it.

**Altitude, stated because the three charters are easy to conflate.** A *portfolio*
charter authorizes a standing governance body and its component-admission rules. A
*program* charter authorizes one coordinated benefits-delivery effort with an end. A
*project* charter authorizes one project's scope against one sponsor's mandate. The
distinguishing field is the middle one's: **benefits that only coordination produces.**

Variables in `{{BRACKETS}}` are replaced at render time.

---

# Program Charter — {{PROGRAM_NAME}}

**Program ID:** `{{PROGRAM_ID}}`
**Parent portfolio:** `{{PORTFOLIO_ID}}`
**Status:** {{LIFECYCLE_STATE}}
**Chartered:** {{CHARTER_DATE}}
**Program owner:** {{PROGRAM_OWNER}}
**Sponsor:** {{SPONSOR}}

## 1. Program purpose — [REQUIRED]

{{PURPOSE_STATEMENT}}

## 2. The coordination rationale — [REQUIRED]

{{COORDINATION_RATIONALE}}

State the benefit that exists **only** because these components are managed together —
shared capability, sequenced dependency, common change audience, pooled scarce resource.
If this section can be written without naming an inter-component effect, the grouping is
not a program and the charter should stop here.

## 3. Component projects and workstreams — [REQUIRED]

| Component | Type | Contribution to program benefit | Owner | Status |
|-----------|------|--------------------------------|-------|--------|
| {{COMPONENT_1}} | {{COMPONENT_TYPE_1}} | {{COMPONENT_CONTRIBUTION_1}} | {{COMPONENT_OWNER_1}} | {{COMPONENT_STATUS_1}} |

**Each component keeps its own delivery approach.** A program does not impose one — a
PMI-governed program routinely coordinates Scrum, Kanban and phase-gated components at
once, and each renders status in its own native framing. The program coordinates
*benefits and dependencies*, not ceremonies.

## 4. Target benefits — [REQUIRED]

| ID | Benefit | Measure | Baseline | Target | Realized when | Owner |
|----|---------|---------|----------|--------|---------------|-------|
| B1 | {{BENEFIT_1}} | {{BENEFIT_MEASURE_1}} | {{BENEFIT_BASELINE_1}} | {{BENEFIT_TARGET_1}} | {{BENEFIT_REALIZED_WHEN_1}} | {{BENEFIT_OWNER_1}} |

The realization schedule, transition arrangements and sustainment owner for each benefit
live in the Benefits Realization Plan (`benefits-realization-template.md`), which this
section references rather than duplicates.

## 5. Scope boundary — [REQUIRED]

**In scope.** {{IN_SCOPE}}

**Out of scope, and why.** {{OUT_OF_SCOPE}}

**Boundary with the parent portfolio.** {{PORTFOLIO_BOUNDARY}} — what the portfolio
decides versus what this program decides, so an escalation has one correct destination.

## 6. Governance and decision rights — [REQUIRED]

| Role | Named | Decides | Escalates to |
|------|-------|---------|--------------|
| {{ROLE_1}} | {{NAME_1}} | {{DECIDES_1}} | {{ESCALATES_1}} |

**Cadence:** {{GOVERNANCE_CADENCE}}
**Quorum:** {{QUORUM}}
**Escalation path to portfolio:** {{PORTFOLIO_ESCALATION}}

## 7. Cross-component dependencies — [REQUIRED]

The dependencies that motivate the program's existence. A program with no rows here has
not discharged §2.

| ID | Predecessor | Successor | Type | Managed by | Status |
|----|-------------|-----------|------|------------|--------|
| D1 | {{PREDECESSOR_1}} | {{SUCCESSOR_1}} | {{DEP_TYPE_1}} | {{DEP_MANAGER_1}} | {{DEP_STATUS_1}} |

## 8. Resources and funding — [REQUIRED]

**Funding envelope:** {{FUNDING_ENVELOPE}} for {{ENVELOPE_PERIOD}}
**Shared resources:** {{SHARED_RESOURCES}}
**Contention resolution:** {{CONTENTION_RESOLUTION}} — who arbitrates when two components
need the same scarce resource, decided now rather than at the moment of contention.

## 9. Stakeholders — [REQUIRED]

| Stakeholder | Interest | Influence | Engagement approach | Owner |
|-------------|----------|-----------|---------------------|-------|
| {{STAKEHOLDER_1}} | {{INTEREST_1}} | {{INFLUENCE_1}} | {{ENGAGEMENT_1}} | {{STAKEHOLDER_OWNER_1}} |

## 10. Risks and assumptions — [REQUIRED]

| # | Risk or assumption | Type | Owner | Mitigation or validation | Reversibility |
|---|--------------------|------|-------|--------------------------|---------------|
| R1 | {{RISK_1}} | {{RISK_TYPE_1}} | {{RISK_OWNER_1}} | {{RISK_MITIGATION_1}} | {{RISK_REVERSIBILITY_1}} |

Name the risk, its owner, and its mitigation. A risk written in passive voice with no
owner is an observation, not a managed risk.

## 11. Program closure criteria — [REQUIRED]

{{CLOSURE_CRITERIA}}

A program ends when its benefits are realized and sustained, not when its last project
closes. State the observable condition, and name who confirms it.

**Transition owner at closure:** {{TRANSITION_OWNER}}

## 12. Authorization — [REQUIRED]

| Name | Role | Date |
|------|------|------|
| {{APPROVER_1}} | {{APPROVER_ROLE_1}} | {{APPROVAL_DATE_1}} |

## 13. Related artifacts — *[OPTIONAL]*

- Parent Portfolio Charter — {{PORTFOLIO_CHARTER_REF}}
- Benefits Realization Plan — {{BENEFITS_REF}}
- Program record (`PROGRAM.md`) — {{PROGRAM_MD_REF}}
- Component project charters — {{PROJECT_CHARTER_REFS}}
