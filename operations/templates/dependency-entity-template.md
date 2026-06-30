---
# Cross-Project Dependency entity (XPD) — entity-field-schemas.md §3.15 / §6.3 worked example.
# Lives in projects/_pmo/dependencies/. Q1: this _pmo/ view carries storage_tier: portfolio-level —
# a view over the §3.15 portfolio-level home (projects/_config/), NOT a relocation of it (ADR-054).
id: {{DEPENDENCY_ID}}                      # = dependency_id (slug); unique within portfolio-level tier (V-XPD-01)
entity_type: Cross-Project Dependency
lifecycle_state: open                      # Axis-1: open → satisfied | broken | waived (V-XPD-06)
content_lifecycle_pattern: Living          # Axis-2 → frontmatter-schema §Cat-2 Domain B
owning_agent: ppm-agent
created_date: {{CREATION_DATE}}            # ISO YYYY-MM-DD, ≤ today (V-XPD-07)
storage_tier: portfolio-level              # Q1 — view-over-tier; the §3.15 _config/ home is preserved, this is the _pmo/ view
dependency_id: {{DEPENDENCY_ID}}
from_entity_ref: {{FROM_ENTITY_REF}}      # → <any roster entity>.id (V-XPD-02 / X-05, WARN-HEALTH) — directed source
to_entity_ref: {{TO_ENTITY_REF}}          # → <any roster entity>.id (V-XPD-03 / X-05, WARN-HEALTH) — directed target; must ≠ from (V-XPD-04)
dependency_kind: {{DEPENDENCY_KIND}}      # optional; membership [ASSUMPTION–CONFIRM @ G3/G4] (V-XPD-05)
relationships:
  - type: DEPENDS_ON                       # MVP type — frontmatter-schema §Cat-4
    target: {{TO_ENTITY_REF}}
---
# Cross-Project Dependency — {{DEPENDENCY_ID}}

**Dependency:** `{{DEPENDENCY_ID}}` · **From:** `{{FROM_ENTITY_REF}}` → **To:** `{{TO_ENTITY_REF}}` · **Kind:** {{DEPENDENCY_KIND}} · **Status:** open

> Cross-project dependency record. The authoritative portfolio-level home is `projects/_config/` (§3.15); this `_pmo/dependencies/` page is the portfolio-level **view** (`storage_tier: portfolio-level`, Q1), composed not relocated. `from ≠ to` (no self-dependency, V-XPD-04).

## Dependency

**Source (`from`):** {{FROM_ENTITY_REF}}
**Target (`to`):** {{TO_ENTITY_REF}}
**Kind:** {{DEPENDENCY_KIND}}

## Lifecycle

**Current state:** `open` · _(open → satisfied | broken | waived)_

## Notes

{{NOTES}}
