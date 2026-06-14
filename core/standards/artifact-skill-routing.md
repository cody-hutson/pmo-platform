---
title: Artifact-Skill Routing Standard
purpose: The user-facing "which artifact skill to call" decision tree — routes an artifact need to the correct skill (artifact-generator and its specialist routes, delivery-engine, comms-writer) or out to a purpose-built Anthropic skill (then wrap). Composes with (does NOT restate) ADR-021 skill-sourcing-coupling-posture and the artifact-generator catalog.
type: reference
composes_with: [ADR-021-skill-sourcing-coupling-posture.md, upstream-reference-catalog.md, duplicate-source-discipline.md]
source: initial release
reversibility: CHEAP / Confidence HIGH
---

<!-- reference-durability: allow-link -->

# Artifact-Skill Routing Standard

## Purpose

This standard answers one question for a workspace user: **"I need an artifact — which skill do I call?"** It is a cross-skill routing convention, so it lives in the normative `core/standards/` corpus rather than inside any one skill's reference set.

It exists because the platform splits artifact production across several skills, and one class (technical documentation and product-requirement specs) is deliberately **routed out** to purpose-built Anthropic skills and then re-ingested under PMO metadata staging. Without a single routing surface, a user (or an agent) reaches for the closest-looking skill and produces a near-miss. This tree makes the correct route explicit.

It is **user-facing guidance**, not a runtime-coupling spec. Routing a need to an Anthropic skill and then wrapping the result is a **design-time** path with **no runtime Anthropic dependency** — see [ADR-021](../ADRs/ADR-021-skill-sourcing-coupling-posture.md).

## Decision tree

```
Need an artifact?
├─ PMO project governance (charter, decision deck, exec readout, RAID)? → artifact-generator (Generate Mode, primary)
├─ Change management (impact, training, hypercare, readiness)?           → artifact-generator → routes to change-management specialist
├─ Cutover / go-live (cutover plan, go/no-go, readiness assessment)?     → artifact-generator → routes to delivery-engine specialist
├─ Delivery tracking (sprint/velocity/DoR/DoD)?                          → delivery-engine directly, OR artifact-generator by audience
├─ Stakeholder communication (email, Teams, exec brief, agenda)?         → comms-writer
├─ Technical documentation (API docs, README, runbook, arch doc)?        → Anthropic engineering/documentation, THEN artifact-generator Wrapper Mode to stage
└─ Feature spec / PRD (PRD, new-feature stories, acceptance criteria)?   → Anthropic product-management/feature-spec, THEN artifact-generator Wrapper Mode to stage
```

## Branch detail

| If the need is… | Call… | Why |
|---|---|---|
| **PMO project governance** — Project Overview, Decision Deck, Executive Readout, RAID Log, Project Charter | **artifact-generator** (Generate Mode, primary). RAID Log routes on to delivery-engine; the rest are self-produced or specialist-routed per the catalog. | These are PMO-unique artifacts artifact-generator owns. See [`artifact-catalog.md`](../../operations/skills/artifact-generator/references/artifact-catalog.md) §Project Governance. |
| **Change management** — Communication Plan, Change Impact Assessment, Training Plan, Hypercare Plan, Role Impact Matrix, Readiness Checklist, Change Matrix | **artifact-generator** → **change-management** specialist (Communication Plan → comms-writer). | artifact-generator routes to the change-management specialist for domain depth. Catalog §Change Management. |
| **Cutover / deployment** — Cutover Plan, Go/No-Go Checklist, Readiness Assessment | **artifact-generator** → **delivery-engine** specialist (Readiness Assessment → change-management). | Cutover artifacts carry gate-criteria rigor the delivery-engine owns. Catalog §Cutover / Deployment. |
| **Operations / status** — Daily Status, Weekly Roll-Up, Sprint Review, Retrospective Notes, Phase Gate Review Package | **artifact-generator** → specialist (Daily Status / Weekly Roll-Up / delivery-engine), OR the dedicated skill directly. | Status artifacts delegate to their dedicated skills; artifact-generator routes when invoked as the entry point. Catalog §Operations / Status. |
| **Waterfall governance** — Milestone Status Report, Deliverable Tracker, Gantt Update Narrative | **artifact-generator** → **delivery-engine** (Gantt narrative self-produced). | Catalog §Waterfall Governance. |
| **Delivery tracking** — sprint/velocity/DoR/DoD gates, backlog health | **delivery-engine** directly (or artifact-generator by audience when a packaged deliverable is wanted). | delivery-engine is the operational backbone for backlog→release readiness. |
| **Stakeholder communication** — email, Teams post, Confluence, exec brief, meeting agenda, recap, escalation | **comms-writer**. | comms-writer is the voice of the PMO; the comms-adjacent catalog entries route through it. Catalog §Comms-adjacent. |
| **Technical documentation** — API docs, README, architecture doc, runbook, onboarding guide, technical reference | **Anthropic `engineering/documentation`**, THEN **artifact-generator Wrapper Mode** to stage the result. | Out of PMO-catalog scope — routed out and wrapped. Detail: [`tech-doc-routing.md`](../../operations/skills/artifact-generator/references/tech-doc-routing.md). |
| **Feature spec / PRD** — PRD, new-feature user stories, acceptance-criteria docs, success-metric definitions | **Anthropic `product-management/feature-spec`**, THEN **artifact-generator Wrapper Mode** to stage the result. | Out of PMO-catalog scope — routed out and wrapped. Detail: [`prd-routing.md`](../../operations/skills/artifact-generator/references/prd-routing.md). |

## The two route-out branches (design-time, no runtime coupling)

The last two branches are the offload targets made user-visible. artifact-generator no longer **produces** technical documentation or PRDs/feature specs; instead, the user invokes the purpose-built Anthropic skill, then brings the result into the project via artifact-generator **Wrapper Mode** (metadata-prepend + stage, no content mutation; the staged header carries `source: external` + `source_origin`).

This keeps artifact-generator's sourcing posture `independent` / own-with-harvest per [ADR-021](../ADRs/ADR-021-skill-sourcing-coupling-posture.md): routing a user to an Anthropic skill and wrapping its inert output is **not** a runtime dependency. Structure and conventions are harvested at design time via the [upstream-reference catalog](upstream-reference-catalog.md). No `extends` / `pass-through` binding exists.

## Related

- artifact-generator skill (Generate Mode + Wrapper Mode): [`operations/skills/artifact-generator/SKILL.md`](../../operations/skills/artifact-generator/SKILL.md)
- Technical-documentation branch detail: [`tech-doc-routing.md`](../../operations/skills/artifact-generator/references/tech-doc-routing.md)
- PRD / feature-spec branch detail: [`prd-routing.md`](../../operations/skills/artifact-generator/references/prd-routing.md)
- PMO-unique artifact catalog: [`artifact-catalog.md`](../../operations/skills/artifact-generator/references/artifact-catalog.md)
- Sourcing posture (own-with-harvest; no runtime coupling): [ADR-021](../ADRs/ADR-021-skill-sourcing-coupling-posture.md)
- Design-time harvest surface: [upstream-reference catalog](upstream-reference-catalog.md)
