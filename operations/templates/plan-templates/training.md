---
# Plan entity (PLN) — entity-field-schemas.md §3.4 / §3.4a (plan_type: training)
id: {{PLAN_ID}}                          # slug, unique within storage_tier
entity_type: Plan
lifecycle_state: draft                   # Axis-1 base: draft → approved → active → superseded → archived (V-PLN-05);
                                         # training operational-terminal `delivered` admitted pre-`archived` (§3.4a)
content_lifecycle_pattern: Baselined     # Axis-2 → frontmatter-schema §Cat-2 Domain A
owning_agent: change-management
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today
plan_title: {{PROJECT_NAME}} Training Plan
plan_type: training                      # OPEN discriminator (§3.4a registry)
project_id: {{PROJECT_ID}}               # BELONGS_TO parent → Project.id (V-PLN-03 / X-13)
version: "1.0"
relationships:
  - type: BELONGS_TO                     # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: DEPENDS_ON                   # → comms Plan (training depends on comms) — §3.4b / X-35
  #   target: {{COMMS_PLAN_ID}}
---
# {{PROJECT_NAME}} Training Plan

**Purpose:** Define the role-based training curriculum, delivery schedule, and competency sign-off for the go-live audience (ADKAR Knowledge + Ability).
**Owner:** [OPERATOR_NAME]
**plan_type:** `training` · **Producer skill:** `change-management` · **Operational-terminal:** `delivered`

> Section skeleton — develop against [`operations/skills/change-management/references/training-plan.md`](../../skills/change-management/references/training-plan.md) (curriculum + delivery model) and ADKAR Knowledge/Ability stages.

---

## Role × Curriculum Matrix

| Role | Training Module | Delivery Mode | Duration | Competency Check | Owner |
|------|-----------------|---------------|----------|------------------|-------|
| {{ROLE_1}} | {{MODULE_1}} | {{MODE_1}} | {{DURATION_1}} | {{CHECK_1}} | {{OWNER_1}} |
| {{ASSUMPTION – CONFIRM}} | | | | | |

## Delivery Schedule

| Date | Session | Audience | Facilitator | Status |
|------|---------|----------|-------------|--------|
| {{DATE_1}} | {{SESSION_1}} | {{AUD_1}} | {{FACILITATOR_1}} | Planned |

## Competency Sign-off

{{SIGNOFF_CRITERIA}}

## Lifecycle note

When delivery completes, advance `lifecycle_state` to `delivered` (the training operational-terminal, §3.4a) before `archived`.
