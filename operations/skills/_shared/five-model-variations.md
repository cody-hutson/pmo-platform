# Five-Model Variations — Shared Role-Skill Reference

> **Shared surface.** Consumed by every PMO role-Specialist skill. Authored for longevity — a change here ripples to all consumers. The structure is the contract: **one variation table per varying dimension**, each table has **5 columns = the 5 delivery models**, and each **row = one varying behavior** with **decision-grade cells** (specific enough to drive an implementation decision, not "varies"). The role-skill factory (`pmo-skill-refiner` → `## Workflow — Consume Feeding Document`) draws on this file as the **five-model-variations** substrate; a feeding document's §9 Delivery Model Variation declares which dimensions the role varies on and resolves the `delivery_approach` frontmatter against these tables.

This file is **reference content, not a skill** (no `SKILL.md`; not in any `deploy.sh` roster array; `_`-prefixed sibling of the skill directories).

**The 5 delivery models.** Waterfall · Agile/Scrum · Kanban · Hybrid · n/a (methodology-agnostic). Cells are decision-grade — a reader can act on the cell, not just read a label. "n/a" means the model imposes no specific variation on that dimension (methodology-agnostic), not "unknown."

## Planning Cadence

| Behavior | Waterfall | Agile/Scrum | Kanban | Hybrid | n/a |
|---|---|---|---|---|---|
| Planning horizon | Full-scope upfront, phase-gated | Sprint (1–4 wk) + release | Continuous, just-in-time | Milestone-fixed scope, sprint-executed | No imposed horizon |
| Re-plan trigger | Change request through CCB | Sprint boundary / backlog refinement | WIP-limit breach / pull signal | Sprint boundary within fixed milestone | Event-driven |
| Commitment unit | Phase deliverable | Sprint backlog | Next pulled item | Milestone + sprint goals | Task |

## Estimation & Sizing

| Behavior | Waterfall | Agile/Scrum | Kanban | Hybrid | n/a |
|---|---|---|---|---|---|
| Sizing unit | Effort-hours / duration | Story points (relative) | Cycle-time / throughput | Points within milestone effort budget | Effort-hours |
| Forecasting basis | Critical-path schedule | Velocity (rolling avg) | Throughput + cycle-time distribution | Velocity bounded by milestone dates | Single-point estimate |
| Buffer placement | Schedule contingency (end of phase) | Sprint capacity reserve | WIP slack | Both: milestone contingency + sprint reserve | Per-task pad |

## Status & Reporting

| Behavior | Waterfall | Agile/Scrum | Kanban | Hybrid | n/a |
|---|---|---|---|---|---|
| Primary status artifact | Phase-gate report / % complete | Burndown + sprint review | Cumulative-flow + cycle-time | Milestone status + sprint burndown | Ad-hoc status |
| Cadence | Phase milestones | Daily standup + sprint demo | Continuous (pull events) | Daily + sprint + milestone gate | As requested |
| Health signal | Schedule variance (SV/CV) | Velocity trend + sprint goal hit | Flow efficiency + aging WIP | SV against milestone + velocity | Subjective |

## Risk & Change Handling

| Behavior | Waterfall | Agile/Scrum | Kanban | Hybrid | n/a |
|---|---|---|---|---|---|
| Change intake | Formal CR → CCB approval | Backlog item, re-prioritized | Pulled when capacity frees | CR for milestone scope; backlog for sprint detail | Direct |
| Risk review cadence | Phase-gate risk review | Per-sprint risk in retro | Continuous (blocked-item policy) | Milestone gate + sprint retro | Event-driven |
| Scope-change reversibility | EXPENSIVE (re-baseline) | CHEAP (re-prioritize backlog) | CHEAP (re-order queue) | MODERATE (milestone fixed, sprint fluid) | Varies |

## Gate & Acceptance

| Behavior | Waterfall | Agile/Scrum | Kanban | Hybrid | n/a |
|---|---|---|---|---|---|
| Acceptance unit | Phase deliverable sign-off | Definition of Done per story | Done-column policy | DoD per story + milestone sign-off | Deliverable sign-off |
| Quality gate timing | End-of-phase | Per-story + sprint review | Per-item pull-to-done | Per-sprint + milestone gate | End-of-task |
| Go/no-go authority | Phase-gate board | Product Owner (increment) | Service-delivery review | PO (sprint) + steering (milestone) | Approver |

## Role Engagement Posture

| Behavior | Waterfall | Agile/Scrum | Kanban | Hybrid | n/a |
|---|---|---|---|---|---|
| Cadence the role syncs to | Phase boundaries | Sprint ceremonies | Flow events / WIP signals | Both phase + sprint | On demand |
| Primary lever the role pulls | Schedule + scope baseline | Backlog priority + capacity | WIP limits + flow policy | Milestone scope + sprint priority | Direct task assignment |
| Escalation trigger | Schedule/cost variance threshold | Sprint goal at risk | Aging WIP / policy breach | Milestone slip or sprint-goal miss | Blocker |
