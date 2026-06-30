---
# Person entity (PER) — entity-field-schemas.md §3.10 / §6.2 worked example. Lives in projects/_pmo/people/.
# This _pmo/ page is the SSOT on person_id (ADR-054); the people-roster + ADR-040 leadership-owner
# refs are read-time consumers that resolve AGAINST this page — never a second Person home.
id: {{PERSON_ID}}                        # = person_id (slug); globally unique across _pmo/ (V-PER-02)
entity_type: Person
lifecycle_state: active                  # Axis-1: active → inactive (V-PER-05)
content_lifecycle_pattern: Living        # Axis-2 → frontmatter-schema §Cat-2 Domain B
owning_agent: ppm-agent
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today (V-PER-06)
full_name: {{FULL_NAME}}
person_id: {{PERSON_ID}}                 # the cross-entity dedup anchor (resolution target for X-01/X-04/X-12/X-15/X-18/X-20/X-21/X-23/X-27/X-30..X-33)
primary_role: {{PRIMARY_ROLE}}
email: {{EMAIL}}                         # optional — RFC-ish format (V-PER-04); omit if unknown
aliases: []                              # optional rename-safety convention (people-coverage-graph.md §2.3) — append prior names on rename; NEVER edit person_id, NEVER delete
---
# {{FULL_NAME}}

**person_id:** `{{PERSON_ID}}` · **Primary role:** {{PRIMARY_ROLE}} · **Status:** active

> Cross-project Person record (SSOT). Functional attributes (capability tags, coverage edges, escalation) live in the operator-instance `people-roster.yaml`, joined on `person_id` (people-coverage-graph.md §2). This page is the identity record; the roster is the coverage view.

## Identity & Aliases

- **Canonical name:** {{FULL_NAME}}
- **Aliases (prior names / spellings):** _(none — append on rename, never edit `person_id`)_

## Projects & Allocation

_(Resource allocations resolve from the Resource entity on `person_id` — `{project_id, role_on_project, allocation_pct}`.)_

| Project | Role on project | Allocation % |
|---------|-----------------|--------------|
| {{PROJECT_1}} | {{ROLE_1}} | {{ALLOC_1}} |

## Notes

{{NOTES}}
