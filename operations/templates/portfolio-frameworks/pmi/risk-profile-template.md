---
artifact_type: template
template_family: Portfolio Risk Profile
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/risk-profile-template.md
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
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered Portfolio Risk Profile — an instance starts at the second H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Portfolio-tier governance family (template-taxonomy.md §8's convention-anchor list carries no portfolio-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# Portfolio Risk Profile Template (PMI)

The portfolio's **risk appetite, thresholds and aggregate exposure** — how much risk of
each category the portfolio will knowingly carry, and how much it is carrying now.

**This is not a RAID log, and the distinction is load-bearing.** The registry's
`raid-log-template.csv` binds per-item rows: one risk, one owner, one mitigation, one
date. This artifact binds *thresholds and aggregates*: the appetite statement a component
is admitted against, and the roll-up that says whether the portfolio as a whole is inside
it. A portfolio running a RAID log still owes this profile, because a stack of individual
risk rows never answers "are we over our limit?" — summing per-item severities is not the
same measurement as an appetite threshold, and treating one as the other is how a
portfolio discovers its exposure only at the point of breach.

Variables in `{{BRACKETS}}` are replaced at render time.

---

# Portfolio Risk Profile — {{PORTFOLIO_NAME}}

**Portfolio ID:** `{{PORTFOLIO_ID}}`
**As of:** {{AS_OF_DATE}}
**Prepared by:** {{PREPARED_BY}}
**Approved by:** {{APPROVED_BY}} on {{APPROVAL_DATE}}
**Next review:** {{NEXT_REVIEW_DATE}}

## 1. Risk appetite statement

{{APPETITE_STATEMENT}}

One paragraph naming what the portfolio is willing to risk in pursuit of its mandate, and
what it is not. An appetite statement that does not exclude anything has not been written.

## 2. Appetite by category

| Category | Appetite | Threshold | Measured by | Breach disposition |
|----------|----------|-----------|-------------|--------------------|
| Delivery / schedule | {{APPETITE_SCHEDULE}} | {{THRESHOLD_SCHEDULE}} | {{MEASURE_SCHEDULE}} | {{BREACH_SCHEDULE}} |
| Financial | {{APPETITE_FINANCIAL}} | {{THRESHOLD_FINANCIAL}} | {{MEASURE_FINANCIAL}} | {{BREACH_FINANCIAL}} |
| Operational | {{APPETITE_OPERATIONAL}} | {{THRESHOLD_OPERATIONAL}} | {{MEASURE_OPERATIONAL}} | {{BREACH_OPERATIONAL}} |
| Compliance / regulatory | {{APPETITE_COMPLIANCE}} | {{THRESHOLD_COMPLIANCE}} | {{MEASURE_COMPLIANCE}} | {{BREACH_COMPLIANCE}} |
| Technical / architectural | {{APPETITE_TECHNICAL}} | {{THRESHOLD_TECHNICAL}} | {{MEASURE_TECHNICAL}} | {{BREACH_TECHNICAL}} |
| Reputational | {{APPETITE_REPUTATIONAL}} | {{THRESHOLD_REPUTATIONAL}} | {{MEASURE_REPUTATIONAL}} | {{BREACH_REPUTATIONAL}} |

**Appetite** is `Averse` / `Cautious` / `Open` / `Seeking`. A **threshold** is a number or
a named condition — never an adjective, because an adjective cannot be breached
observably. **Breach disposition** names what happens when the threshold is crossed and
who decides it.

## 3. Aggregate exposure — current

| Category | Threshold | Current exposure | Headroom | Trend | Verdict |
|----------|-----------|------------------|----------|-------|---------|
| {{EXPOSURE_CATEGORY_1}} | {{EXPOSURE_THRESHOLD_1}} | {{EXPOSURE_CURRENT_1}} | {{EXPOSURE_HEADROOM_1}} | {{EXPOSURE_TREND_1}} | {{EXPOSURE_VERDICT_1}} |

**Verdict** is `WITHIN` / `AT LIMIT` / `BREACHED`. Every category in §2 takes a row here,
including the ones comfortably within appetite — omitting the quiet categories makes the
profile unreadable as a coverage claim.

**Measurement baseline.** {{EXPOSURE_BASELINE}} — the data instant the exposure figures
were read at. An exposure figure with no baseline is not reproducible, and a category
that was observably empty at read time is recorded as *empty at this baseline*, never as
structurally zero.

## 4. Concentration risk

Where exposure clusters. A portfolio inside every category threshold can still be
fragile if one vendor, one system, or one team carries most of it.

| Concentration | Dimension | Share | Threshold | Verdict | Mitigation |
|---------------|-----------|-------|-----------|---------|------------|
| {{CONCENTRATION_1}} | {{DIMENSION_1}} | {{SHARE_1}} | {{CONC_THRESHOLD_1}} | {{CONC_VERDICT_1}} | {{CONC_MITIGATION_1}} |

## 5. Escalation thresholds

| # | Condition | Escalates to | Within | Standing action |
|---|-----------|--------------|--------|-----------------|
| E1 | {{ESCALATION_CONDITION_1}} | {{ESCALATION_TARGET_1}} | {{ESCALATION_SLA_1}} | {{ESCALATION_ACTION_1}} |

## 6. Component risk contribution

The link back to per-item risk. This table names *which component* drives each category's
exposure; the individual risks themselves stay in that component's RAID log and are
referenced, never copied here.

| Component | Dominant category | Contribution | RAID reference |
|-----------|-------------------|--------------|----------------|
| {{RISK_COMPONENT_1}} | {{RISK_CATEGORY_1}} | {{RISK_CONTRIBUTION_1}} | {{RAID_REF_1}} |

## 7. Changes since last review

| Date | Change | Driver | Decided by |
|------|--------|--------|------------|
| {{RISK_CHANGE_DATE_1}} | {{RISK_CHANGE_1}} | {{RISK_DRIVER_1}} | {{RISK_DECIDER_1}} |

An appetite or threshold change is a governance decision and carries a decision record —
a threshold edited without one is indistinguishable from a threshold that drifted.

## 8. Related artifacts

- Portfolio Charter §9 (the appetite statement this profile operationalizes) — {{CHARTER_REF}}
- Portfolio Roadmap (schedule and capacity exposure) — {{ROADMAP_REF}}
- Component RAID logs (per-item risk) — {{RAID_REFS}}
