---
type: project-page
managed_by: project-initiator
domain: managed
folder: _project-root
lifecycle_state: emerging
trust_category: controlled-truth
created_date: {{CREATION_DATE}}
---

# PROJECT.md — {{PROJECT_NAME}}

<!--
Born entity frontmatter (above): the 7-field block per frontmatter-schema.md § Classification/Trust
+ agent-processing-contracts.md Skill-6 contract. `domain: managed` is the live value (A/B/C
deprecated per frontmatter-schema.md § Category 6). `folder: _project-root` is the NON-BIN
SENTINEL (ADR-137) — PROJECT.md sits at the project ROOT, in no bin, and `folder` is a NOT-NULL
core field, so without this value a newly-scaffolded PROJECT.md is born missing one.
Entity `lifecycle_state: emerging` is the
ENTITY maturity axis — distinct from the project-lifecycle `Status` below (two-lifecycle model).
Composed-index PROJECT.md (ADR-060): a thin dashboard, NOT the container. Methodology + Status
are INLINE (consumer back-compat per project-schema.md §4); People / Systems / Milestones /
Plans / Workstreams are [[wiki-link]] lists into the _pmo/ shared-entity pages and the
typed plans — edit once on the entity page, not in a table cell here. Target: ≤50 lines.
Variables in {{BRACKETS}} are filled at scaffold; {{IF ...}}...{{ENDIF}} blocks are conditional.
-->

**Status:** `ACTIVE` · **Last updated:** {{CREATION_DATE}}
**Governance model:** {{GOVERNANCE_MODEL}} · **delivery_approach:** {{DELIVERY_APPROACH}} · **dual_framing_enabled:** {{DUAL_FRAMING_ENABLED}}
**Go-live target:** {{GO_LIVE_TARGET}} · **Current phase:** {{CURRENT_PHASE}}

> {{PROJECT_DESCRIPTION}}

## Methodology (inline — read by the §8 consumers)

- **delivery_approach:** {{DELIVERY_APPROACH}}  {{IF DELIVERY_APPROACH == Custom}}(custom: see `custom_methodology_definition`){{ENDIF}}
- **dual_framing_enabled:** {{DUAL_FRAMING_ENABLED}}  {{IF DUAL_FRAMING_ENABLED == Yes}}→ [[{{PROJECT_PREFIX}}_Dual_Framing_Bridge]]{{ENDIF}}
{{IF GOVERNANCE_MODEL == Agile OR Hybrid}}- **Cadence:** Scrum/Agile · current sprint + velocity tracked in [[{{PROJECT_PREFIX}}_Sprint_Tracker]]{{ENDIF}}
{{IF GOVERNANCE_MODEL == Waterfall OR Hybrid}}- **Cadence:** phase-gate · milestones tracked in [[{{PROJECT_PREFIX}}_Milestone_Tracker]]{{ENDIF}}

## People  → _pmo/people/

- [[person-{{OPERATOR_SLUG}}]] — Senior TPM (decision authority)
- {{ADDITIONAL_PEOPLE_WIKILINKS}}  <!-- [[person-<id>]] per teammate; resolve to _pmo/people/ (one record, no per-project duplication) -->

## Systems  → _pmo/systems/

- {{SYSTEMS_WIKILINKS}}  <!-- [[system-<id>]] into _pmo/systems/ -->

## Milestones

- {{MILESTONE_WIKILINKS}}  <!-- [[<milestone-id>]]; phase-gate or sprint milestones -->

## Plans  → typed plans

- {{PLAN_WIKILINKS}}  <!-- [[<plan-id>]] typed by plan_type: comms / training / hypercare / cutover / change-management / raid -->

## Workstreams  → _pmo/workstreams/

- {{WORKSTREAM_WIKILINKS}}  <!-- [[<workstream-id>]] into _pmo/workstreams/ -->

## Governance Links

- **Confluence:** {{CONFLUENCE_SPACE}}{{IF GOVERNANCE_MODEL == Agile OR Hybrid}} · **Jira:** {{JIRA_PROJECT_KEY}}{{ENDIF}}
- **Operational trackers:** `3-Operations/` (Tier-2 working copies)
