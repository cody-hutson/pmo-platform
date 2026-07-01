---
# Decision entity (DEC) — entity-field-schemas.md §3.5. Lives in projects/_pmo/decisions/.
# Stored in the _pmo/ shared-entity tree (ADR-058) so a cross-project decision is one record;
# project_id is its BELONGS_TO anchor, decision_maker_person_id resolves AGAINST _pmo/people/.
id: {{DECISION_ID}}                        # slug, unique within storage_tier
entity_type: Decision
lifecycle_state: proposed                  # Axis-1: proposed → accepted → reversed | superseded (V-DEC-05)
content_lifecycle_pattern: Living          # Axis-2 → frontmatter-schema §Cat-2 Domain B
owning_agent: ppm-agent
created_date: {{CREATION_DATE}}            # ISO YYYY-MM-DD, ≤ today (V-DEC-06)
decision_statement: {{DECISION_STATEMENT}}
decided_date: {{DECIDED_DATE}}            # ISO YYYY-MM-DD, ≤ today (V-DEC-02)
project_id: {{PROJECT_ID}}                 # BELONGS_TO parent → Project.id (V-DEC-03 / X-14, BLOCK-WRITE)
decision_maker_person_id: {{MAKER_PERSON_ID}}   # optional → Person.person_id (V-DEC-04 / X-15, BLOCK-WRITE); omit if none
rationale: {{RATIONALE}}                   # optional
relationships:
  - type: BELONGS_TO                       # MVP type — frontmatter-schema §Cat-4
    target: {{PROJECT_ID}}
  # - type: ASSIGNED_TO                    # → Person (the decision maker as an edge)
  #   target: {{MAKER_PERSON_ID}}
---
# Decision — {{DECISION_STATEMENT}}

**Decision:** `{{DECISION_ID}}` · **Decided:** {{DECIDED_DATE}} · **Maker:** `{{MAKER_PERSON_ID}}` (→ _pmo/people/) · **Project:** `{{PROJECT_ID}}` · **Status:** proposed

> Decision record in the `_pmo/` shared-entity tree (SSOT). `BELONGS_TO` exactly one Project; the maker resolves to a Person by `person_id`.

## Decision

{{DECISION_STATEMENT}}

## Rationale

{{RATIONALE}}

## Lifecycle

**Current state:** `proposed` · _(proposed → accepted → reversed | superseded)_

## Notes

{{NOTES}}
