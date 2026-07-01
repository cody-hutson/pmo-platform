---
# Plan entity (PLN) — entity-field-schemas.md §3.4 / §3.4a (plan_type: comms)
id: {{PLAN_ID}}                          # slug, unique within storage_tier
entity_type: Plan
lifecycle_state: draft                   # Axis-1: draft → approved → active → superseded → archived (V-PLN-05)
content_lifecycle_pattern: Baselined     # Axis-2 → frontmatter-schema §Cat-2 Domain A
owning_agent: comms-writer
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today
plan_title: {{PROJECT_NAME}} Communications Plan
plan_type: comms                         # OPEN discriminator (§3.4a registry)
project_id: {{PROJECT_ID}}               # BELONGS_TO parent → Project.id (V-PLN-03 / X-13)
version: "1.0"
relationships:
  - type: BELONGS_TO                     # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: GENERATES                    # → Artifact (a sent comms artifact) — §3.4b / X-34
  #   target: {{ARTIFACT_ID}}
---
# {{PROJECT_NAME}} Communications Plan

**Purpose:** Define the audience-calibrated communication cadence, channels, and ownership for the project (OCM change-comms program).
**Owner:** [OPERATOR_NAME]
**plan_type:** `comms` · **Producer skill:** `comms-writer`

> Section skeleton — develop against [`operations/skills/change-management/references/adoption-tracking.md`](../../skills/change-management/references/adoption-tracking.md) (change-comms program framing) and the comms-writer voice/audience model.

---

## Audience Map

| Audience | Information Need | Channel | Cadence | Owner |
|----------|------------------|---------|---------|-------|
| {{AUDIENCE_1}} | {{NEED_1}} | {{CHANNEL_1}} | {{CADENCE_1}} | {{OWNER_1}} |
| {{ASSUMPTION – CONFIRM}} | | | | |

## Key Messages

- {{KEY_MESSAGE_1}}

## Communication Schedule

| Date | Message | Audience | Channel | Status |
|------|---------|----------|---------|--------|
| {{DATE_1}} | {{MSG_1}} | {{AUD_1}} | {{CH_1}} | Planned |

## Feedback & Escalation Loop

{{FEEDBACK_MECHANISM}}

## Generated Artifacts (GENERATES edges → §3.4b)

| Artifact | plan→artifact edge | Status |
|----------|--------------------|--------|
| {{COMMS_ARTIFACT_1}} | GENERATES | {{STATUS_1}} |
