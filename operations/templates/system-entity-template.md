---
# System entity (SYS) — entity-field-schemas.md §3.11. Lives in projects/_pmo/systems/.
# Cross-project shared entity (SSOT, ADR-058); the system_owner_person_id resolves AGAINST _pmo/people/.
id: {{SYSTEM_ID}}                        # = system_id (slug); unique within _pmo/ (V-SYS-02)
entity_type: System
lifecycle_state: active                  # Axis-1: active → deprecated → retired (V-SYS-04)
content_lifecycle_pattern: Living        # Axis-2 → frontmatter-schema §Cat-2 Domain B
owning_agent: ppm-agent
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today (V-SYS-05)
system_name: {{SYSTEM_NAME}}
system_id: {{SYSTEM_ID}}                 # unique within the cross-project-shared tier
system_owner_person_id: {{OWNER_PERSON_ID}}   # optional → Person.person_id (V-SYS-03 / X-20, WARN-HEALTH); omit if none
---
# {{SYSTEM_NAME}}

**system_id:** `{{SYSTEM_ID}}` · **Owner:** `{{OWNER_PERSON_ID}}` (→ _pmo/people/) · **Status:** active

> Cross-project System record (SSOT). Referenced by projects via link, not duplicated per project.

## System Profile

- **Category / type:** {{SYSTEM_CATEGORY}}
- **Environment(s):** {{ENVIRONMENTS}}
- **Integration touchpoints:** {{INTEGRATIONS}}

## Lifecycle

**Current state:** `active` · _(active → deprecated → retired)_

## Notes

{{NOTES}}
