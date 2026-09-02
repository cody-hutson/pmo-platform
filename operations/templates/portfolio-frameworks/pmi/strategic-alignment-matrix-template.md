---
artifact_type: template
template_family: Strategic Alignment Matrix
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/strategic-alignment-matrix-template.md
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
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered Strategic Alignment Matrix — an instance starts at the second H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Portfolio-tier governance family (template-taxonomy.md §8's convention-anchor list carries no portfolio-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# Strategic Alignment Matrix Template (PMI)

The traceability surface between organizational strategy and portfolio components. Its
job is to make **two** absences visible: a component that serves no stated objective, and
an objective no component serves. A matrix that only shows the populated cells is a
coverage claim without a denominator, so both orphan classes are rendered explicitly
below rather than inferred by the reader.

This is a portfolio-tier artifact. It does not track delivery status — that is the
Portfolio Roadmap — and it does not rank components — that is the charter's §4 model.
It answers one question: *what does this component exist to move, and by how much?*

Variables in `{{BRACKETS}}` are replaced at render time. One row per
component × objective pair with a non-`None` contribution.

---

# Strategic Alignment Matrix — {{PORTFOLIO_NAME}}

**Portfolio ID:** `{{PORTFOLIO_ID}}`
**As of:** {{AS_OF_DATE}}
**Prepared by:** {{PREPARED_BY}}
**Next review:** {{NEXT_REVIEW_DATE}}

## 1. Strategic objectives

The objectives this matrix maps against, restated from their source so a reader need not
resolve a second document to read a row. The **source** column is what makes each one
citable rather than asserted.

| ID | Objective | Source | Horizon | Owner |
|----|-----------|--------|---------|-------|
| O1 | {{OBJECTIVE_1}} | {{SOURCE_1}} | {{HORIZON_1}} | {{OWNER_1}} |

## 2. Alignment matrix

**Contribution scale.** `Primary` — the component's principal reason for existing.
`Secondary` — a material contribution that is not the component's main purpose.
`Enabling` — the component does not move the objective itself but is a precondition for
something that does. A pair with no contribution takes **no row**; it is read from §4.

| Component | Type | Objective | Contribution | Measure moved | Baseline → Target | Confidence |
|-----------|------|-----------|--------------|---------------|-------------------|------------|
| {{COMPONENT_1}} | {{COMPONENT_TYPE_1}} | {{OBJ_REF_1}} | {{CONTRIBUTION_1}} | {{MEASURE_1}} | {{BASELINE_1}} → {{TARGET_1}} | {{CONFIDENCE_1}} |

**Confidence** is `HIGH` / `MEDIUM` / `LOW` and refers to the *causal claim* — how sure the
portfolio is that this component moves this measure — not to delivery confidence.

## 3. Objective coverage

One row per objective. This is the read that answers "is anything actually working on
this?" — and it is computed from §2, never authored independently.

| Objective | Primary components | Secondary / enabling | Coverage verdict |
|-----------|--------------------|----------------------|------------------|
| {{OBJ_REF_1}} | {{PRIMARY_COMPONENTS_1}} | {{SUPPORTING_COMPONENTS_1}} | {{COVERAGE_VERDICT_1}} |

**Coverage verdict** is `COVERED` (≥1 primary), `THIN` (secondary/enabling only), or
`UNCOVERED` (no component). A `THIN` or `UNCOVERED` objective is a portfolio finding, not
a formatting artifact — route it to the governance body's next agenda.

## 4. Orphans — both directions

**Components serving no objective.** A component here is not automatically wrong: it may
be mandatory, regulatory, or keep-the-lights-on work. What it must not be is *unexamined*.

| Component | Type | Stated rationale | Disposition |
|-----------|------|------------------|-------------|
| {{ORPHAN_COMPONENT_1}} | {{ORPHAN_TYPE_1}} | {{ORPHAN_RATIONALE_1}} | {{ORPHAN_DISPOSITION_1}} |

**Objectives no component serves.** Carried from §3's `UNCOVERED` rows.

| Objective | Owner | Gap statement | Proposed disposition |
|-----------|-------|---------------|----------------------|
| {{UNCOVERED_OBJ_1}} | {{UNCOVERED_OWNER_1}} | {{GAP_STATEMENT_1}} | {{GAP_DISPOSITION_1}} |

If both orphan tables are empty, say so explicitly — an empty table with no statement
reads as an unfilled section rather than a clean result.

## 5. Changes since last review

| Date | Change | Driver | Decided by |
|------|--------|--------|------------|
| {{CHANGE_DATE_1}} | {{CHANGE_1}} | {{CHANGE_DRIVER_1}} | {{CHANGE_OWNER_1}} |

## 6. Related artifacts

- Portfolio Charter (objectives + inclusion criteria) — {{CHARTER_REF}}
- Portfolio Roadmap (sequencing of the components above) — {{ROADMAP_REF}}
- Benefits Realization Plan (whether the targeted measures actually moved) — {{BENEFITS_REF}}
