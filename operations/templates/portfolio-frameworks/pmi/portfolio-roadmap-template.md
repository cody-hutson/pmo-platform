---
artifact_type: template
template_family: Portfolio Roadmap
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/portfolio-roadmap-template.md
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
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered Portfolio Roadmap — an instance starts at the second H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Portfolio-tier governance family (template-taxonomy.md §8's convention-anchor list carries no portfolio-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# Portfolio Roadmap Template (PMI)

The time-phased view of portfolio components: what is running, what is queued, what each
one depends on, and where the capacity conflicts fall. Portfolio-tier — the unit is a
**component**, not a work item, and the horizon is the planning period rather than an
iteration.

**Distinct from an initiative roadmap.** The platform's initiative-roadmap framework
governs a *capability* through Now / Next / Later with sunset criteria. This artifact
governs a *portfolio's components* through a calendar. The two are not substitutes and
neither is derived from the other.

**Distinct from a project plan.** A project plan sequences tasks inside one component.
A roadmap row that decomposes into tasks has dropped an altitude — keep it at the
component's own milestones.

Variables in `{{BRACKETS}}` are replaced at render time.

---

# Portfolio Roadmap — {{PORTFOLIO_NAME}}

**Portfolio ID:** `{{PORTFOLIO_ID}}`
**Planning horizon:** {{HORIZON_START}} → {{HORIZON_END}}
**As of:** {{AS_OF_DATE}}
**Owner:** {{ROADMAP_OWNER}}
**Next re-plan:** {{NEXT_REPLAN_DATE}}

## 1. Horizon summary

| Period | Components starting | Components completing | Committed capacity | Available capacity |
|--------|---------------------|-----------------------|--------------------|--------------------|
| {{PERIOD_1}} | {{STARTING_1}} | {{COMPLETING_1}} | {{COMMITTED_1}} | {{AVAILABLE_1}} |

A period whose committed capacity exceeds available capacity is an over-commitment, and
it is stated here rather than discovered when a component slips. The resolution is
recorded in §5.

## 2. Component schedule

| Component | Type | Objective | Status | Start | End | Investment class | Owner |
|-----------|------|-----------|--------|-------|-----|------------------|-------|
| {{COMPONENT_1}} | {{TYPE_1}} | {{OBJECTIVE_1}} | {{STATUS_1}} | {{START_1}} | {{END_1}} | {{CLASS_1}} | {{OWNER_1}} |

**Status** is `Proposed` / `Approved` / `Active` / `Closing` / `Closed` / `On hold` /
`Terminated`. **Investment class** is `Run` / `Grow` / `Transform`, matching the charter's
§6 allocation table so the two reconcile.

**Every date is a specific date, never a generalized range.** A date that cannot be
verified against the component's own plan is marked `[RECOMMENDED]` inline; it is never
smoothed into "mid-quarter".

## 3. Milestones

Portfolio-visible milestones only — the ones another component or an external stakeholder
depends on. A milestone visible only inside its own component belongs to that component's
plan.

| ID | Milestone | Component | Target date | Confidence | Depends on |
|----|-----------|-----------|-------------|------------|------------|
| M1 | {{MILESTONE_1}} | {{MILESTONE_COMPONENT_1}} | {{MILESTONE_DATE_1}} | {{MILESTONE_CONFIDENCE_1}} | {{MILESTONE_DEPS_1}} |

## 4. Cross-component dependencies

| ID | Predecessor | Successor | Type | Lag | Status | Owner |
|----|-------------|-----------|------|-----|--------|-------|
| D1 | {{PREDECESSOR_1}} | {{SUCCESSOR_1}} | {{DEP_TYPE_1}} | {{LAG_1}} | {{DEP_STATUS_1}} | {{DEP_OWNER_1}} |

**Test every edge before recording it.** A dependency is *build-blocking* (the successor
cannot start) or *ship-gating* (it can proceed but cannot release). Collapsing the two
idles work that could have proceeded, so the `Type` column carries the distinction rather
than a bare "depends on".

## 5. Capacity conflicts and their resolutions

| # | Conflict | Period | Components | Resolution | Decided by | Date |
|---|----------|--------|------------|------------|------------|------|
| K1 | {{CONFLICT_1}} | {{CONFLICT_PERIOD_1}} | {{CONFLICT_COMPONENTS_1}} | {{RESOLUTION_1}} | {{CONFLICT_OWNER_1}} | {{CONFLICT_DATE_1}} |

An unresolved conflict carries `UNRESOLVED` in the Resolution column and a named owner —
never a blank cell. A blank reads as "no conflict".

## 6. Changes since last publication

| Date | Change | Driver | Impact | Decided by |
|------|--------|--------|--------|------------|
| {{ROADMAP_CHANGE_DATE_1}} | {{ROADMAP_CHANGE_1}} | {{ROADMAP_DRIVER_1}} | {{ROADMAP_IMPACT_1}} | {{ROADMAP_DECIDER_1}} |

## 7. Related artifacts

- Portfolio Charter (envelope + prioritization model) — {{CHARTER_REF}}
- Strategic Alignment Matrix (why each component is here) — {{ALIGNMENT_REF}}
- Portfolio Risk Profile (schedule and capacity risk) — {{RISK_PROFILE_REF}}
- Component programs and projects — {{COMPONENT_REFS}}
