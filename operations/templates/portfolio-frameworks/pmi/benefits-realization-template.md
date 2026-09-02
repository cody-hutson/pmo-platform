---
artifact_type: template
template_family: Benefits Realization Plan
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/benefits-realization-template.md
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
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered Benefits Realization Plan — an instance starts at the second H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Program-tier governance family (template-taxonomy.md §8's convention-anchor list carries no program-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# Benefits Realization Plan Template (PMI)

How each program benefit gets measured, transitioned to an operational owner, and
sustained after the program closes. Its reason for existing is that **delivery is not
realization**: a program can ship every component on time and realize nothing, and the
gap is invisible unless someone wrote down in advance what "realized" would look like and
who would still be watching for it a year later.

Two properties this artifact carries that a status report does not: a **measurement**
baseline taken *before* the change, and a **sustainment owner** who holds the benefit
after the program's governance body dissolves.

Variables in `{{BRACKETS}}` are replaced at render time.

---

# Benefits Realization Plan — {{PROGRAM_NAME}}

**Program ID:** `{{PROGRAM_ID}}`
**Parent portfolio:** `{{PORTFOLIO_ID}}`
**As of:** {{AS_OF_DATE}}
**Plan owner:** {{PLAN_OWNER}}
**Next review:** {{NEXT_REVIEW_DATE}}

## 1. Benefit register

| ID | Benefit | Type | Measure | Baseline | Baseline date | Target | Target date | Benefit owner |
|----|---------|------|---------|----------|---------------|--------|-------------|---------------|
| B1 | {{BENEFIT_1}} | {{BENEFIT_TYPE_1}} | {{MEASURE_1}} | {{BASELINE_1}} | {{BASELINE_DATE_1}} | {{TARGET_1}} | {{TARGET_DATE_1}} | {{BENEFIT_OWNER_1}} |

**Type** is `Financial` / `Operational` / `Capability` / `Compliance` / `Strategic`.

**A benefit with no baseline is not measurable and must not be registered.** If the
baseline cannot be taken before the change lands, record that explicitly as an
`[ASSUMPTION – CONFIRM]` with the proxy being used and its known weakness — never
back-fill a baseline after the fact and present it as measured.

## 2. Realization schedule

Benefits rarely land when the component that enables them closes. This table separates
**delivered** from **realized** so the lag is visible rather than assumed away.

| Benefit | Enabling component | Delivered by | First measurable | Full realization | Measurement cadence |
|---------|--------------------|--------------|------------------|------------------|---------------------|
| {{BENEFIT_REF_1}} | {{ENABLER_1}} | {{DELIVERED_BY_1}} | {{FIRST_MEASURABLE_1}} | {{FULL_REALIZATION_1}} | {{MEASUREMENT_CADENCE_1}} |

## 3. Measurement method

| Benefit | Data source | Collected by | Method | Known limitation |
|---------|-------------|--------------|--------|------------------|
| {{BENEFIT_REF_1}} | {{DATA_SOURCE_1}} | {{COLLECTOR_1}} | {{METHOD_1}} | {{LIMITATION_1}} |

**Known limitation is a required cell, not an optional caveat.** Every measurement has
one — attribution ambiguity, seasonality, a proxy standing in for the real quantity. A
blank there means the limitation was not looked for, which is the condition under which a
benefit gets reported as realized because the number moved for an unrelated reason.

## 4. Transition to operations

| Benefit | Transition trigger | Receiving owner | Handover artifacts | Transition date | Status |
|---------|--------------------|-----------------|--------------------|-----------------|--------|
| {{BENEFIT_REF_1}} | {{TRANSITION_TRIGGER_1}} | {{RECEIVING_OWNER_1}} | {{HANDOVER_ARTIFACTS_1}} | {{TRANSITION_DATE_1}} | {{TRANSITION_STATUS_1}} |

**Receiving owner is a named person or a named standing role — never a team name alone.**
A benefit handed to "Operations" has been handed to nobody.

## 5. Sustainment

What keeps the benefit in place after the program's governance dissolves.

| Benefit | Sustainment owner | Sustainment activity | Review cadence | Decay risk |
|---------|-------------------|----------------------|----------------|------------|
| {{BENEFIT_REF_1}} | {{SUSTAINMENT_OWNER_1}} | {{SUSTAINMENT_ACTIVITY_1}} | {{SUSTAINMENT_CADENCE_1}} | {{DECAY_RISK_1}} |

## 6. Realization status — current

| Benefit | Baseline | Target | Current | % to target | Verdict | As of |
|---------|----------|--------|---------|-------------|---------|-------|
| {{BENEFIT_REF_1}} | {{STATUS_BASELINE_1}} | {{STATUS_TARGET_1}} | {{STATUS_CURRENT_1}} | {{STATUS_PCT_1}} | {{STATUS_VERDICT_1}} | {{STATUS_ASOF_1}} |

**Verdict** is `NOT YET MEASURABLE` / `ON TRACK` / `AT RISK` / `REALIZED` / `NOT REALIZED`.
`NOT YET MEASURABLE` is a first-class verdict, not a placeholder — a benefit whose first
measurable date has not arrived is correctly unmeasured, and saying so is different from
having no reading.

## 7. Dis-benefits and trade-offs

Costs the program knowingly accepts. Recording them is what stops a downstream reader
from treating an anticipated cost as an unmanaged defect.

| # | Dis-benefit | Affected group | Accepted by | Date | Mitigation |
|---|-------------|----------------|-------------|------|------------|
| X1 | {{DISBENEFIT_1}} | {{AFFECTED_1}} | {{ACCEPTED_BY_1}} | {{ACCEPTED_DATE_1}} | {{DISBENEFIT_MITIGATION_1}} |

## 8. Changes since last review

| Date | Change | Driver | Decided by |
|------|--------|--------|------------|
| {{BR_CHANGE_DATE_1}} | {{BR_CHANGE_1}} | {{BR_DRIVER_1}} | {{BR_DECIDER_1}} |

A target or baseline revision is a governance decision and carries a decision record.
Revising a target downward without one is how a program reports success against a bar it
moved.

## 9. Related artifacts

- Program Charter §4 (the benefits this plan operationalizes) — {{PROGRAM_CHARTER_REF}}
- Program record (`PROGRAM.md`) — {{PROGRAM_MD_REF}}
- Portfolio Strategic Alignment Matrix (the objectives these benefits serve) — {{ALIGNMENT_REF}}
