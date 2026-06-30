---
# Plan entity (PLN) — entity-field-schemas.md §3.4 / §3.4a (plan_type: raid)
# NOTE: plan_type: raid = the RAID **Log** (a Plan-class register). It is NOT the
# RAID-Item entity (§3.6) — a RAID-Item is a *row* in this Log, a separate entity.
id: {{PLAN_ID}}                          # slug, unique within storage_tier
entity_type: Plan
lifecycle_state: draft                   # Axis-1: draft → approved → active → superseded → archived (V-PLN-05)
content_lifecycle_pattern: Baselined     # Axis-2 → frontmatter-schema §Cat-2 Domain A
owning_agent: tracker-manager
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today
plan_title: {{PROJECT_NAME}} RAID Log
plan_type: raid                          # OPEN discriminator (§3.4a registry) — the RAID Log register (≠ RAID-Item §3.6)
project_id: {{PROJECT_ID}}               # BELONGS_TO parent → Project.id (V-PLN-03 / X-13)
version: "1.0"
relationships:
  - type: BELONGS_TO                     # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: GENERATES                    # → RAID-Item rows (the Log holds RAID-Items) — §3.4b / X-34
  #   target: {{RAID_ITEM_ID}}
---
# {{PROJECT_NAME}} RAID Log

**Purpose:** The project's Risk / Assumption / Issue / Dependency register (the RAID **Log** — a Plan-class artifact). Each row is a RAID-Item entity (`entity-field-schemas.md` §3.6); this Log is their container, NOT the items themselves.
**Owner:** [OPERATOR_NAME]
**plan_type:** `raid` · **Producer skill:** `tracker-manager`

> Section skeleton — the RAID-Item rows conform to [`core/schemas/raid-log.schema.json`](../../../core/schemas/raid-log.schema.json) (§3.6 freeze-gate surface). Row authoring guidance: [`operations/skills/delivery-engine/references/raid-templates.md`](../../skills/delivery-engine/references/raid-templates.md).

---

## RAID Register (rows = RAID-Item entities, §3.6)

| ID | raid_type | Summary | Owner (person_id) | Severity | Target Date | lifecycle_state |
|----|-----------|---------|-------------------|----------|-------------|-----------------|
| {{RAID_ID_1}} | {{RAID_TYPE_1}} | {{SUMMARY_1}} | {{OWNER_PERSON_ID_1}} | {{SEVERITY_1}} | {{TARGET_1}} | open |
| {{ASSUMPTION – CONFIRM}} | | | | | | |

> Each row is a distinct **RAID-Item** (§3.6 entity) — `raid_type ∈ {Risk, Assumption, Issue, Dependency}`, `owner_person_id → Person.person_id` (X-01), `lifecycle_state ∈ {open, in-progress, mitigating, resolved, closed}`. Do NOT conflate the RAID-Item `closed` state with the Plan's lifecycle.
