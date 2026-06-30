---
# Workstream entity (WS) — entity-field-schemas.md §3.3. Lives in projects/_pmo/workstreams/.
# Stored in the _pmo/ shared-entity tree (ADR-054) so a workstream spanning projects is one record;
# project_id is its BELONGS_TO anchor, lead_person_id resolves AGAINST _pmo/people/.
id: {{WORKSTREAM_ID}}                     # slug, unique within storage_tier
entity_type: Workstream
lifecycle_state: active                   # Axis-1: active → paused → closed (V-WS-05)
content_lifecycle_pattern: Living         # Axis-2 → frontmatter-schema §Cat-2 Domain B
owning_agent: ppm-agent
created_date: {{CREATION_DATE}}           # ISO YYYY-MM-DD, ≤ today (V-WS-06)
workstream_name: {{WORKSTREAM_NAME}}
project_id: {{PROJECT_ID}}                # BELONGS_TO parent → Project.id (V-WS-03 / X-11, BLOCK-WRITE)
lead_person_id: {{LEAD_PERSON_ID}}        # optional → Person.person_id (V-WS-04 / X-12, BLOCK-WRITE); omit if none
relationships:
  - type: BELONGS_TO                      # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
---
# {{WORKSTREAM_NAME}}

**Workstream:** `{{WORKSTREAM_ID}}` · **Project:** `{{PROJECT_ID}}` · **Lead:** `{{LEAD_PERSON_ID}}` (→ _pmo/people/) · **Status:** active

> Workstream record in the `_pmo/` shared-entity tree (SSOT). `BELONGS_TO` exactly one Project; the lead resolves to a Person by `person_id`.

## Scope & Deliverables

- **Scope:** {{SCOPE}}
- **Key deliverables:** {{DELIVERABLES}}

## Lifecycle

**Current state:** `active` · _(active → paused → closed)_

## Notes

{{NOTES}}
