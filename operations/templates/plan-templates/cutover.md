---
# Plan entity (PLN) — entity-field-schemas.md §3.4 / §3.4a (plan_type: cutover)
id: {{PLAN_ID}}                          # slug, unique within storage_tier
entity_type: Plan
lifecycle_state: draft                   # Axis-1 base: draft → approved → active → superseded → archived (V-PLN-05);
                                         # cutover operational-terminal `executed` admitted pre-`archived` (§3.4a)
content_lifecycle_pattern: Baselined     # Axis-2 → frontmatter-schema §Cat-2 Domain A
owning_agent: delivery-engine
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today
plan_title: {{PROJECT_NAME}} Cutover Plan
plan_type: cutover                       # OPEN discriminator (§3.4a registry)
project_id: {{PROJECT_ID}}               # BELONGS_TO parent → Project.id (V-PLN-03 / X-13)
version: "1.0"
relationships:
  - type: BELONGS_TO                     # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: BLOCKS                       # → go-live Milestone (cutover gates go-live) — §3.4b
  #   target: {{GOLIVE_MILESTONE_ID}}
---
# {{PROJECT_NAME}} Cutover Plan

**Purpose:** Define the go-live cutover runbook — the sequenced, timed, rollback-aware task list that moves the system from pre-prod to production.
**Owner:** [OPERATOR_NAME]
**plan_type:** `cutover` · **Producer skill:** `delivery-engine` · **Operational-terminal:** `executed`

> Section skeleton — develop against the `delivery-engine` execution-control model ([`operations/skills/delivery-engine/references/gate-checklists.md`](../../skills/delivery-engine/references/gate-checklists.md) for the go/no-go gate; [`lifecycle-stages.md`](../../skills/delivery-engine/references/lifecycle-stages.md) for stage sequencing).

---

## Cutover Runbook (sequenced + timed)

| # | Task | Owner | Start (T-/T+) | Duration | Rollback Step | Status |
|---|------|-------|---------------|----------|---------------|--------|
| 1 | {{TASK_1}} | {{OWNER_1}} | {{TIME_1}} | {{DUR_1}} | {{ROLLBACK_1}} | Not Started |
| {{ASSUMPTION – CONFIRM}} | | | | | | |

## Go / No-Go Gate

| Criterion | Owner | Status | Decision |
|-----------|-------|--------|----------|
| {{CRITERION_1}} | {{OWNER_1}} | {{STATUS_1}} | {{GO_NOGO_1}} |

## Rollback Plan

**Rollback trigger:** {{ROLLBACK_TRIGGER}} · **Decision owner:** {{ROLLBACK_OWNER}} · **Point of no return:** {{PONR}}

## Lifecycle note

When the cutover runbook completes in production, advance `lifecycle_state` to `executed` (the cutover operational-terminal, §3.4a) before `archived`.
