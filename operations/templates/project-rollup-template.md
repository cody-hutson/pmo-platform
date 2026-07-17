---
# Project Rollup (composed) — per-project portfolio publishing rollup.
# A COMPOSED read-surface over existing entities, NOT a roster entity: the entity roster is
# FROZEN at 19 (project-entity-model.md §4, ADR-044) and this template adds none (ADR-019
# compose-not-absorb). Each field below READS its source entity (annotated inline) and
# references that authoritative value — no field owns or duplicates one.
# Governed by core/standards/portfolio-writeback-contract.md (the 7-field contract).
# Placement: [Project]/04-PMO-Operations/[Project]_Rollup.md — project-scoped, the same
# dual-taxonomy home as [Project]_Daily_Status_Log.md (legacy 04-PMO-Operations/ in skill
# refs; registered in the Operational Artifacts (3-Operations/) table; both union-valid).
id: {{PROJECT_ID}}-rollup
entity_type: Project Rollup (composed)
owning_agent: ppm-agent
content_lifecycle_pattern: Living          # Axis-2 → frontmatter-schema §Cat-2 Domain B (composed read-surface, refreshed)
project_id: {{PROJECT_ID}}                 # kebab-case project slug (operational tier-taxonomy DD-2 *_id convention)
last_published: {{LAST_PUBLISHED}}         # ISO 8601 datetime — drives [STALE]; age = today − last_published, BUSINESS days
# ── The 7 contract fields, each annotated with the source entity it READS ──
status: {{STATUS}}                         # ← Project (entity 1).status — RAG {green|yellow|red}; worst-component dominance
top_risks: {{TOP_RISKS}}                   # ← RAID Item (entity 6) — ≤5 × {risk, owner, mitigation}
key_dependencies: {{KEY_DEPENDENCIES}}     # ← Cross-Project Dependency / XPD (entity 15) — {from, to, state}
capacity_signal: {{CAPACITY_SIGNAL}}       # ← Resource (entity 8) — {utilization, gap_rag}; synthesis CITED from weekly-status-rollup §7.5 + capacity-model.md, not re-derived
milestone_delta: {{MILESTONE_DELTA}}       # ← Milestone (entity 2) — {next_milestone, target, actual?, state}
cross_project_conflicts: {{CROSS_PROJECT_CONFLICTS}}   # ← Cross-Project Resource Conflict / XRC (entity 16) — {conflict, projects_affected[], owner, mitigation}
---
# Project Rollup — {{PROJECT_NAME}}

> **Composed read-surface — not a roster entity.** Every field above READS its source entity (annotated inline); this rollup references authoritative values, it does not own or duplicate them (ADR-019 compose-not-absorb; roster frozen at 19 per ADR-044). It is emitted/refreshed by `ppm-agent` per the [portfolio write-back contract](../../core/standards/portfolio-writeback-contract.md), and STAGED for the Cowork `PORTFOLIO.md` writer via `weekly-status-rollup` Section 6's human-in-the-loop checkpoint — **never auto-written into `projects/`**.

**Project:** `{{PROJECT_ID}}` · **Status:** {{STATUS}} · **Last published:** {{LAST_PUBLISHED}}
_Freshness: age = `today − last_published` in **business days** — `> 3 bd` renders `[STALE]`, `> 5 bd` auto-degrades (threshold values set by the portfolio health-score layer)._

## Composed fields → source entities

| Field | Composes from | Feeds PORTFOLIO.md section |
|---|---|---|
| `status` | Project (entity 1) `status` | S1 Health · S2 Health Indicators |
| `top_risks[]` | RAID Item (entity 6) `impact` / `owner_person_id` / `action_plan` | S5 Top Risks · S6 Cross-Project RAID |
| `key_dependencies[]` | Cross-Project Dependency / XPD (entity 15) | S6 · S7 Cross-Project Dependencies |
| `capacity_signal` | Resource (entity 8) `allocation_pct` (synthesis cited, not re-derived) | S3 Capacity Dashboard |
| `milestone_delta` | Milestone (entity 2) `target_date` / `actual_date` / `lifecycle_state` | S1 Health Summary |
| `cross_project_conflicts[]` | Cross-Project Resource Conflict / XRC (entity 16) | S6 Cross-Project RAID · S8 Resource Conflicts |
| `last_published` | rollup meta (this file) | meta `Last Updated` + inline `[STALE]` markers |

## Notes

{{NOTES}}
