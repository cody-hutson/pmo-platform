---
artifact_type: template
template_family: PROGRAM.md scaffolding
domain: project
canonical_path: operations/templates/portfolio-frameworks/pmi/program-md-template.md
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
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a scaffolded PROGRAM.md instance — an instance starts at the second H1 below ("# PROGRAM.md — {{PROGRAM_NAME}}"); the first H1 and the guidance under it are authoring notes and are not rendered either. This template is an INLINE provenance carrier on the project-md-template.md pattern: the rendered instance carries bold field lines rather than a YAML block, so the frontmatter slot stays this template file's own and no `.provenance.yml` sidecar is owed (template-protocol.md §4.4 / ADR-107). -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Program-tier governance family (template-taxonomy.md §8's convention-anchor list carries no program-management plugin). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->
<!-- Framework-selected content: this shape ships only to a deployment that sets operator.toml [methodology].portfolio_framework = "pmi". Consumer branch: release/references/specs/methodology-parameterization-v1.md §5B CASE P-1. -->

# PROGRAM.md Template (PMI)

The program's standing record — the file a reader opens to learn what this program is,
which components it coordinates, and where its benefits stand. Variables in
`{{BRACKETS}}` are replaced when the record is scaffolded.

**The Program entity's field set is frozen, and this template cites it rather than
re-declaring it.** `program_id` is the entity's classifier; the authoritative field
schema is [`core/schemas/entity-field-schemas.md` § 3.14 Program (PROG)](../../../../core/schemas/entity-field-schemas.md),
its validation rules are `V-PROG-01`..`V-PROG-07` there, and its referential rules are
`X-22` / `X-32`. Read requiredness, cardinality, types and the exactly-one-of owner
invariant from that schema — **never from this file**. A template that restated the field
table would create a second copy of a frozen schema from inside framework-selected
delta content, which would then drift silently from the schema that actually validates.

**Physical placement is not this template's to govern.** The Program record is embedded
at the portfolio-level home per its frozen `storage_tier` / `persistence_mode`; there is
no dedicated program folder. Where a rendered instance is persisted is a project-data
architecture concern, and the Template Architecture boundary rule is explicit that
template changes never write into the operations tree.

**Scope boundary against the Program Charter.** The charter *authorizes* the program once
and is re-ratified on a cadence; this record is the *living* state that changes between
ratifications. Where the two would say the same thing, this record references the charter.

---

# PROGRAM.md — {{PROGRAM_NAME}}

**Program ID:** `{{PROGRAM_ID}}`
**Portfolio ID:** `{{PORTFOLIO_ID}}`
**Lifecycle state:** {{LIFECYCLE_STATE}}
**Program owner:** {{PROGRAM_OWNER}}
**Created:** {{CREATED_DATE}}
**Last updated:** {{LAST_UPDATED}}

<!--
Field authority: core/schemas/entity-field-schemas.md § 3.14 (PROG). The owner line above
renders EITHER the roster reference OR the external free-text fallback — exactly one, per
that schema's mutual-exclusion invariant. Do not render both, and do not render neither.
Lifecycle state is the Axis-1 machine (active → closing → closed); `archived` belongs to
the Portfolio entity's machine and is not valid here.
-->

## Program Summary

{{PROGRAM_DESCRIPTION}}

**Coordination rationale:** {{COORDINATION_RATIONALE}}

The benefit that exists only because these components are managed together. Carried from
the Program Charter § 2 — if it is not stated there, this record is not the place to
invent it.

## Components

| Component | Type | Delivery approach | Status | Owner | Record |
|-----------|------|-------------------|--------|-------|--------|
| {{COMPONENT_1}} | {{COMPONENT_TYPE_1}} | {{COMPONENT_APPROACH_1}} | {{COMPONENT_STATUS_1}} | {{COMPONENT_OWNER_1}} | {{COMPONENT_REF_1}} |

**Each component keeps its own `delivery_approach`.** The program does not impose one, and
this column is read from each component's own record rather than set here — a program
coordinating Scrum, Kanban and phase-gated components at once is the ordinary case, and
each renders status in its own native framing.

## Benefits — current standing

| ID | Benefit | Target | Current | Verdict | As of |
|----|---------|--------|---------|---------|-------|
| B1 | {{BENEFIT_1}} | {{BENEFIT_TARGET_1}} | {{BENEFIT_CURRENT_1}} | {{BENEFIT_VERDICT_1}} | {{BENEFIT_ASOF_1}} |

Measurement method, baselines, transition owners and sustainment live in the Benefits
Realization Plan. This table is the summary read, and it cites that plan rather than
re-deriving it.

## Governance

**Cadence:** {{GOVERNANCE_CADENCE}}
**Next review:** {{NEXT_REVIEW_DATE}}
**Escalation path to portfolio:** {{PORTFOLIO_ESCALATION}}

| Role | Named | Decides |
|------|-------|---------|
| {{ROLE_1}} | {{NAME_1}} | {{DECIDES_1}} |

## Cross-component dependencies

| ID | Predecessor | Successor | Type | Status | Owner |
|----|-------------|-----------|------|--------|-------|
| D1 | {{PREDECESSOR_1}} | {{SUCCESSOR_1}} | {{DEP_TYPE_1}} | {{DEP_STATUS_1}} | {{DEP_OWNER_1}} |

## Open decisions

| ID | Decision needed | Owner | Needed by | Reversibility |
|----|-----------------|-------|-----------|---------------|
| DEC-1 | {{DECISION_1}} | {{DECISION_OWNER_1}} | {{DECISION_BY_1}} | {{DECISION_REVERSIBILITY_1}} |

Every open decision carries a reversibility tier — `CHEAP` / `MODERATE` / `EXPENSIVE` /
`IRREVERSIBLE` — because the process weight a decision deserves scales with it.

## Risks at program level

| # | Risk | Owner | Mitigation | Severity |
|---|------|-------|------------|----------|
| R1 | {{RISK_1}} | {{RISK_OWNER_1}} | {{RISK_MITIGATION_1}} | {{RISK_SEVERITY_1}} |

Risks owned inside a single component stay in that component's RAID log. A risk earns a
row here only when it spans components or when its mitigation is the program's to make.

## Closure criteria

{{CLOSURE_CRITERIA}}

**Transition owner at closure:** {{TRANSITION_OWNER}}

## Related artifacts

- Program Charter — {{PROGRAM_CHARTER_REF}}
- Benefits Realization Plan — {{BENEFITS_REF}}
- Parent Portfolio Charter — {{PORTFOLIO_CHARTER_REF}}
- Component records — {{COMPONENT_REFS}}
