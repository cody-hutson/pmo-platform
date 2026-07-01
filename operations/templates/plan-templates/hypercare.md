---
# Plan entity (PLN) — entity-field-schemas.md §3.4 / §3.4a (plan_type: hypercare)
id: {{PLAN_ID}}                          # slug, unique within storage_tier
entity_type: Plan
lifecycle_state: draft                   # Axis-1 base: draft → approved → active → superseded → archived (V-PLN-05);
                                         # hypercare operational-terminal `closed` admitted pre-`archived` (§3.4a)
content_lifecycle_pattern: Baselined     # Axis-2 → frontmatter-schema §Cat-2 Domain A
owning_agent: change-management
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today
plan_title: {{PROJECT_NAME}} Hypercare Plan
plan_type: hypercare                     # OPEN discriminator (§3.4a registry)
project_id: {{PROJECT_ID}}               # BELONGS_TO parent → Project.id (V-PLN-03 / X-13)
version: "1.0"
relationships:
  - type: BELONGS_TO                     # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: DEPENDS_ON                   # → go-live Milestone (hypercare follows go-live) — §3.4b / X-35
  #   target: {{GOLIVE_MILESTONE_ID}}
---
# {{PROJECT_NAME}} Hypercare Plan

**Purpose:** Define the post-go-live stabilization window — support model, issue triage SLAs, exit criteria, and the transition to steady-state operations.
**Owner:** [OPERATOR_NAME]
**plan_type:** `hypercare` · **Producer skill:** `change-management` · **Operational-terminal:** `closed`

> Section skeleton — develop against [`operations/skills/change-management/references/hypercare-plan.md`](../../skills/change-management/references/hypercare-plan.md) (support model + exit criteria).

---

## Hypercare Window

**Start:** {{HYPERCARE_START}} · **Planned exit:** {{HYPERCARE_EXIT}} · **Duration:** {{DURATION}}

## Support Model & Triage SLAs

| Severity | Response SLA | Resolution SLA | Escalation Path | Owner |
|----------|--------------|----------------|-----------------|-------|
| {{SEV_1}} | {{RESP_1}} | {{RESOL_1}} | {{ESCAL_1}} | {{OWNER_1}} |
| {{ASSUMPTION – CONFIRM}} | | | | |

## Hypercare Metrics & Exit Criteria

| Metric | Threshold | Current | Exit-ready? |
|--------|-----------|---------|-------------|
| {{METRIC_1}} | {{THRESHOLD_1}} | {{CURRENT_1}} | {{READY_1}} |

## Transition to Steady-State

{{TRANSITION_PLAN}}

## Lifecycle note

When the window exits and steady-state transition is signed off, advance `lifecycle_state` to `closed` (the hypercare operational-terminal, §3.4a) before `archived`.
