---
artifact_type: template
template_family: Portfolio Charter
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/portfolio-charter-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-09-01
updated: 2026-09-01
generated_by: release-pipeline v4.46
reviewer: N/A
canon: The Standard for Portfolio Management (PMI)
canon_compat: none
version: "v4.46"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered Portfolio Charter — an instance starts at the second H1 below ("# Portfolio Charter — {{PORTFOLIO_NAME}}"); the first H1 and the guidance under it are authoring notes and are not rendered either. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Portfolio-tier governance family (template-taxonomy.md §8's convention-anchor list carries no portfolio-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# Portfolio Charter Template (PMI)

The authorizing document for a portfolio: what the portfolio exists to achieve, who may
decide what about it, and the criteria by which a component enters or leaves it. Distinct
from a **project** charter (`operations/templates/project-charter-template.md`) at both
altitude and field schema — a project charter authorizes one project's scope against one
sponsor's mandate; this authorizes a standing governance body and the rules by which it
admits, ranks and removes components.

Variables in `{{BRACKETS}}` are replaced when the charter is rendered. Sections marked
**[REQUIRED]** carry the criterion the governance body is later held to; sections marked
*[OPTIONAL]* are omitted whole when they do not apply — never left as empty headings.

---

# Portfolio Charter — {{PORTFOLIO_NAME}}

**Portfolio ID:** `{{PORTFOLIO_ID}}`
**Status:** {{LIFECYCLE_STATE}}
**Chartered:** {{CHARTER_DATE}}
**Last reviewed:** {{LAST_REVIEW_DATE}}
**Portfolio owner:** {{PORTFOLIO_OWNER}}

## 1. Purpose and strategic mandate — [REQUIRED]

{{PURPOSE_STATEMENT}}

State what the portfolio is accountable for delivering to the organization, in one
paragraph. This is the sentence every prioritization argument is settled against, so it
must name an outcome rather than a set of activities.

**Strategic objectives this portfolio serves:**

| # | Objective | Source | Owner |
|---|-----------|--------|-------|
| 1 | {{OBJECTIVE_1}} | {{OBJECTIVE_1_SOURCE}} | {{OBJECTIVE_1_OWNER}} |

## 2. Scope boundary — [REQUIRED]

**In scope.** {{IN_SCOPE}}

**Out of scope, and why.** {{OUT_OF_SCOPE}}

An out-of-scope entry states the reason, not just the exclusion. An unexplained exclusion
is re-litigated at every intake.

## 3. Component-inclusion criteria — [REQUIRED]

The test a candidate must pass to become a component of this portfolio. These are
admission criteria, not scoring weights — ranking is §4.

| # | Criterion | Threshold | Evidence required | Disposition when unmet |
|---|-----------|-----------|-------------------|------------------------|
| C1 | {{CRITERION_1}} | {{THRESHOLD_1}} | {{EVIDENCE_1}} | {{DISPOSITION_1}} |

**Component types admitted:** {{COMPONENT_TYPES}} (programs, projects, and standing
operational workstreams are each admitted or excluded explicitly — an unnamed type is
excluded).

## 4. Prioritization and ranking model — [REQUIRED]

{{PRIORITIZATION_MODEL}}

| Factor | Weight | Scale | Measured by |
|--------|--------|-------|-------------|
| {{FACTOR_1}} | {{WEIGHT_1}} | {{SCALE_1}} | {{MEASURE_1}} |

**Tie-breaking rule:** {{TIEBREAK_RULE}}

**Re-ranking cadence:** {{RERANK_CADENCE}}. A rank is valid until the next scheduled
re-ranking or until a component's underlying factor materially changes, whichever is first.

## 5. Governance body and decision rights — [REQUIRED]

| Role | Named | Decides | Escalates to |
|------|-------|---------|--------------|
| {{ROLE_1}} | {{NAME_1}} | {{DECIDES_1}} | {{ESCALATES_1}} |

**Quorum:** {{QUORUM}}
**Decision record:** every decision this body takes is recorded as a Decision entity with
its date, the options weighed, and the reversibility tier — a decision recorded only in
minutes is not citable by a later component.

**Meeting cadence:** {{GOVERNANCE_CADENCE}}

## 6. Capacity and funding envelope — [REQUIRED]

**Approved envelope:** {{FUNDING_ENVELOPE}} for {{ENVELOPE_PERIOD}}
**Capacity basis:** {{CAPACITY_BASIS}}

| Investment class | Target allocation | Current allocation |
|------------------|-------------------|--------------------|
| Run | {{RUN_TARGET}} | {{RUN_ACTUAL}} |
| Grow | {{GROW_TARGET}} | {{GROW_ACTUAL}} |
| Transform | {{TRANSFORM_TARGET}} | {{TRANSFORM_ACTUAL}} |

**Reallocation authority:** {{REALLOCATION_AUTHORITY}}

## 7. Success measures — [REQUIRED]

Portfolio-level measures. A measure that can only be read from one component belongs to
that component, not here.

| # | Measure | Baseline | Target | Read from | Cadence |
|---|---------|----------|--------|-----------|---------|
| M1 | {{MEASURE_1}} | {{BASELINE_1}} | {{TARGET_1}} | {{SOURCE_1}} | {{CADENCE_1}} |

## 8. Component-removal and termination criteria — [REQUIRED]

The conditions under which a component leaves the portfolio, stated in advance. Authoring
these at charter time rather than at the moment of removal is what keeps a termination
decision from reading as a judgment on the team.

| # | Trigger | Assessment | Decision owner |
|---|---------|------------|----------------|
| T1 | {{TRIGGER_1}} | {{ASSESSMENT_1}} | {{OWNER_1}} |

## 9. Risk appetite — [REQUIRED]

{{RISK_APPETITE_STATEMENT}}

Thresholds and aggregate exposure limits live in the Portfolio Risk Profile
(`risk-profile-template.md`), which this section references rather than restates.

## 10. Reporting and review — [REQUIRED]

| Report | Audience | Cadence | Owner |
|--------|----------|---------|-------|
| {{REPORT_1}} | {{AUDIENCE_1}} | {{REPORT_CADENCE_1}} | {{REPORT_OWNER_1}} |

**Charter review cadence:** {{CHARTER_REVIEW_CADENCE}}. The charter is re-ratified, not
merely re-read — a review that changes nothing records that it changed nothing.

## 11. Authorization — [REQUIRED]

| Name | Role | Date |
|------|------|------|
| {{APPROVER_1}} | {{APPROVER_ROLE_1}} | {{APPROVAL_DATE_1}} |

## 12. Related artifacts — *[OPTIONAL]*

- Strategic Alignment Matrix — {{ALIGNMENT_MATRIX_REF}}
- Portfolio Roadmap — {{ROADMAP_REF}}
- Portfolio Risk Profile — {{RISK_PROFILE_REF}}
- Component programs — {{PROGRAM_REFS}}
