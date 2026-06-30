---
# Plan entity (PLN) — entity-field-schemas.md §3.4 / §3.4a (plan_type: change-management)
id: {{PLAN_ID}}                          # slug, unique within storage_tier
entity_type: Plan
lifecycle_state: draft                   # Axis-1: draft → approved → active → superseded → archived (V-PLN-05)
content_lifecycle_pattern: Baselined     # Axis-2 → frontmatter-schema §Cat-2 Domain A
owning_agent: change-management
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today
plan_title: {{PROJECT_NAME}} Change-Management Plan
plan_type: change-management             # OPEN discriminator (§3.4a registry) — change-management binds here
project_id: {{PROJECT_ID}}               # BELONGS_TO parent → Project.id (V-PLN-03 / X-13)
version: "1.0"
relationships:
  - type: BELONGS_TO                     # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: GENERATES                    # → training / comms / hypercare Plan (the OCM program children) — §3.4b / X-34
  #   target: {{CHILD_PLAN_ID}}
---
# {{PROJECT_NAME}} Change-Management Plan

**Purpose:** The umbrella OCM plan — the change strategy, stakeholder/impact assessment, and the sequenced program of training, comms, readiness, and hypercare sub-plans for the go-live.
**Owner:** [OPERATOR_NAME]
**plan_type:** `change-management` · **Producer skill:** `change-management`

> Section skeleton — develop against [`operations/skills/change-management/references/methodology-selection.md`](../../skills/change-management/references/methodology-selection.md) (choose ADKAR / Kotter / Lewin / Bridges) and [`impact-assessment.md`](../../skills/change-management/references/impact-assessment.md).

---

## Change Strategy & Methodology

**Selected methodology:** {{METHODOLOGY}} (per methodology-selection.md) · **Rationale:** {{RATIONALE}}

## Stakeholder & Impact Assessment

| Stakeholder Group | Impact (H/M/L) | Change Required | Resistance Risk | Owner |
|-------------------|----------------|-----------------|-----------------|-------|
| {{GROUP_1}} | {{IMPACT_1}} | {{CHANGE_1}} | {{RISK_1}} | {{OWNER_1}} |
| {{ASSUMPTION – CONFIRM}} | | | | |

## Sub-Plan Program (GENERATES edges → §3.4b)

| Sub-plan | plan_type | Status | Owner |
|----------|-----------|--------|-------|
| Communications Plan | `comms` | {{STATUS_1}} | {{OWNER_1}} |
| Training Plan | `training` | {{STATUS_2}} | {{OWNER_2}} |
| Readiness Checklist | (readiness artifact) | {{STATUS_3}} | {{OWNER_3}} |
| Hypercare Plan | `hypercare` | {{STATUS_4}} | {{OWNER_4}} |

## Adoption & Reinforcement

{{ADOPTION_APPROACH}}
