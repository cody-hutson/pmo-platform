# Deployment Strategies — Shared Role-Skill Reference

> **Shared surface.** Consumed by every PMO role-Specialist skill whose scope touches releases, cutovers, or operational readiness. Authored for longevity — a change here ripples to all consumers. The structure is the contract: **named strategies** (each with when-to-use + rollback mechanism), **rollback types**, and an **RTO/RPO tier table**. Cells are decision-grade. The role-skill factory (`pmo-skill-refiner` → `## Workflow — Consume Feeding Document`) draws on this file as the **deployment-strategies** substrate; a role whose modes reason about go-lives references these strategies and tiers.

This file is **reference content, not a skill** (no `SKILL.md`; not in any `deploy.sh` roster array; `_`-prefixed sibling of the skill directories).

## Strategies

Six named deployment strategies. Each row: when to use, rollback mechanism, and the primary risk it trades against.

| Strategy | When to use | Rollback mechanism | Primary risk traded |
|---|---|---|---|
| **Big-bang** | Small blast radius, low coupling, or a hard cutover the system cannot run split | Restore prior version; replay/migrate-back data | All-at-once exposure — no partial safety net |
| **Phased / staged rollout** | Independent cohorts (regions, business units) that can cut over sequentially | Halt the next phase; roll back the last phase only | Mixed-version window across cohorts |
| **Canary** | Need production signal before full exposure; reversible at the routing layer | Shift traffic back to the stable version (no redeploy) | Canary cohort bears first-failure risk |
| **Blue-green** | Need instant cutover + instant rollback; can run two full environments | Flip the router back to the blue (prior) environment | Double infrastructure cost during the window |
| **Rolling** | Stateless, horizontally-scaled services tolerant of mixed versions mid-roll | Roll the version back instance-by-instance | Transient mixed-version behavior during the roll |
| **Feature-flag / dark launch** | Decouple deploy from release; ship code dormant, enable per-cohort | Toggle the flag off (no deploy) | Flag debt; config drift if flags are not retired |

## Rollback Types

| Rollback type | What it reverses | Reversibility tier | Data consideration |
|---|---|---|---|
| **Routing rollback** | Traffic direction (canary / blue-green / flag) | CHEAP — seconds, no redeploy | None — code never changed on the live path |
| **Version rollback** | The deployed artifact to the prior version | MODERATE — minutes, redeploy | Schema-compatible only; forward-migrated data may not read on the old version |
| **Data rollback / restore** | State to a prior snapshot | EXPENSIVE — hours, data loss window | Loses everything written after the snapshot (bounded by RPO) |
| **Compensating transaction** | The *effect* of an action via a forward correction | MODERATE — depends on the correction path | Preferred when a true restore is infeasible; the undo is a new forward action |
| **No rollback (fix-forward)** | Nothing — the defect is patched in place | IRREVERSIBLE of the original action | The only path when the change cannot be undone; pair with a rollback-infeasibility statement |

## RTO/RPO Tiers

**RTO** = Recovery Time Objective (how fast service must be restored). **RPO** = Recovery Point Objective (how much data loss is tolerable, measured as time). A role reasoning about a go-live's reversibility maps the affected service to a tier, which sets the rollback type and the readiness bar.

| Tier | RTO (restore within) | RPO (data-loss bound) | Typical posture |
|---|---|---|---|
| **Tier 0 — Critical** | < 15 min | ≈ 0 (synchronous replication) | Blue-green or canary with instant routing rollback; no big-bang |
| **Tier 1 — High** | < 1 hour | < 5 min | Canary / phased; version rollback rehearsed; snapshot immediately pre-cutover |
| **Tier 2 — Standard** | < 4 hours | < 1 hour | Phased or rolling; version rollback acceptable; hourly backups |
| **Tier 3 — Low** | < 24 hours | < 24 hours | Big-bang acceptable; daily backup restore is the rollback |

**Decision rule.** The tier with the *stricter* RTO/RPO governs when a cutover spans services of different tiers. A go-live recommendation states the affected tier, the chosen strategy, the rollback type, and the resulting reversibility tier — so the approver calibrates scrutiny to the blast radius.
