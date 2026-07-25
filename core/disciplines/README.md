---
title: core/disciplines/
purpose: Index of the understanding- and rationale-oriented documents — the load-bearing models, frameworks, and methodological disciplines downstream skills, governance, and schemas consume.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# core/disciplines/

**Purpose:** Understanding- and rationale-oriented documents — *why* the platform takes the shape it does. These are the load-bearing models, frameworks, and methodological disciplines that downstream skills, governance, and schemas consume by reference.

**Organization:** Flat. One `.md` per model / framework / discipline. No subfolders.

**Governance:** [../governance/OPERATIONS.md](../governance/OPERATIONS.md) § README-Per-Folder Convention.

**Layer:** 1 (Engineering, git-tracked).

---

## Foundational architecture

| Document | Purpose |
|---|---|
| [architecture-overview.md](architecture-overview.md) | Single-source overview of platform structure: workspace layout, skill architecture, deployment model, governance model, release pipeline. **Start here.** |
| [operating-model.md](operating-model.md) | Composition view: per-skill ownership manifest, per-stage governance composition, execution blueprint across the 13 pipeline stages. |
| [five-function-spine-and-process-flows.md](five-function-spine-and-process-flows.md) | Maps the 13 stages to the 5 PMBUK process groups (Initiating / Planning / Executing / Monitoring & Controlling / Closing) + the 10 cross-cutting flows that thread through them. |
| [execution-framework.md](execution-framework.md) | The 5 tool-agnostic execution dimensions (Work Breakdown / Assignment / Tracking / Handoff / State Persistence). Sits between the Process layer and the Tool layer. |
| [build-philosophy.md](build-philosophy.md) | The platform's first-class engineering values (Scalability, Best-Practice-per-Domain, Maintainability, Simplicity, Stability, Security + the read-before-edit / track-all-edits disciplines) and the philosophy × surface coverage matrix mapping each value to the artifact enforcing it across skills / agents / hub-spokes / hooks / slash-commands. Names and routes; cites, never restates. |
| [actor-model-and-governance-as-contract.md](actor-model-and-governance-as-contract.md) | The **target** operating model: the three-actor model (orchestrator / specialist skill / free AI agent), each actor's governing surface, the permanent determinism-vs-judgment division, and the governance-as-procedure → governance-as-contract enforcement shift. Forward-looking (target-state, not current); consumes the seed docs, does not restate them. |
| [cross-chain-architecture-map.md](cross-chain-architecture-map.md) | Cross-chain index: maps every management chain (escalation / project / program-portfolio / release + 6 operational sub-chains) to its governing data model, flow/escalation path, and holding gate. The operational-chain (World B) analog of the five-function spine (World A); references — does not restate — project-entity-model, five-function-spine, agent-handoff-framework, and the actor-model target. |

## Knowledge & corpus

| Document | Purpose |
|---|---|
| [knowledge-architecture.md](knowledge-architecture.md) | The 5-tier (K1–K5) knowledge classification + the universality axis + the placement model (incl. the parameterization seam). |
| [corpus-curation.md](corpus-curation.md) | 5-tier evidence rubric (ET1–ET5) + orthogonality axiom + the 6-step curation protocol + a 6-domain source taxonomy. |
| [km-protocols.md](km-protocols.md) | KM-artifact lifecycle state machine + two-key staleness-by-criticality model + the K5→K1 lessons-learned pipeline + doc-debt scoring. |
| [applicability-framework.md](applicability-framework.md) | When a codified practice applies, when it is contraindicated, and how to resolve conflicts between competing practices. |
| [project-entity-model.md](project-entity-model.md) | The 19-entity canonical data model — per-entity fields, lifecycle, storage tier, owning-agent triplet. Consumed by every operational skill. |
| [work-organization-mapping-framework.md](work-organization-mapping-framework.md) | The domain-neutral standardization of work organization — universal hierarchy concept + the hierarchy-by-methodology map (keyed by archetype name) + shipped best-practice default work-item schemas + the user plug-and-play override model. Projects any methodology's work levels onto the canonical Work Item entity via `work_item_type`. |
| [architecture-evaluative-lens.md](architecture-evaluative-lens.md) | The two cross-cutting design-time evaluative lenses — the triple-Venn (skill ∩ methodology ∩ altitude) and the plug-and-play K1-universal vs K2–K5-install scope classifier. Names + routes each constituent to its canonical home; cites, never restates. Consulted as an advisory design check at Stage 2 Triage / Stage 4 Planning. |

## Discipline meta-protocols

These are parallel — each governs a distinct activity-class at a distinct temporal anchor.

| Document | Activity-class | Primary question | When it fires |
|---|---|---|---|
| [discovery-discipline.md](discovery-discipline.md) | Discovery | "What should this be? What don't we know?" | Before the artifact exists |
| [decision-discipline.md](decision-discipline.md) | Decision | "What should we choose?" | At the recommendation point |
| [review-discipline-principles.md](review-discipline-principles.md) | Review | "Is this correct?" | After the artifact exists |

Decision sub-mechanism (not a peer activity-class — an edit-time twin of `decision-discipline.md` §2.1.1):
- [reconcile-dont-annotate.md](reconcile-dont-annotate.md) — when editing an artifact that carries stale/contradictory state, reconcile it to current state rather than annotating-and-deferring. The edit-time twin of verify-before-recommend (§2.1.1).
- [ticket-architecture-reconciliation.md](ticket-architecture-reconciliation.md) — the pre-build ticket-vs-live-architecture specialization of Discovery's stage-entry premise-currency check and Decision §2.1.1. Fires at Stage 4/5 entry when a ticket touches ≥1 architecture surface; uses ticket-age-vs-architecture-date as the staleness signal. "Is the ticket's premise still valid vs live architecture?"

Authoring sub-mechanism (not a peer activity-class — the default posture when ADDING durable-corpus content):
- [minimal-addition-discipline.md](minimal-addition-discipline.md) — when adding content to governance/reference corpus, add the minimum that carries the meaning (in service of *simplicity*). The umbrella authoring discipline of which duplication is one facet; complements the reference-durability floor via the floor/ceiling boundary.
| [root-cause-analysis.md](root-cause-analysis.md) | RCA | "Why did this fail?" | After a defect/failure surfaces (activity-exit) |
| [autonomous-execution-model.md](autonomous-execution-model.md) | Self-repair | "What can be retried, escalated, rolled back?" | During pipeline execution between gates |
| [three-gulfs-methodology.md](three-gulfs-methodology.md) | Diagnosis | "Intent / Execution / Evaluation — where is the gap?" | At skill creation, improvement, eval design |
| [diataxis-framework.md](diataxis-framework.md) | Documentation classification | "What kind of doc am I writing?" | When authoring or filing a documentation artifact |

## Lifecycle, concurrency, & safety

| Document | Purpose |
|---|---|
| [context-lifecycle-model.md](context-lifecycle-model.md) | 5-state lifecycle for inbound content (Captured → Structured → Reviewed → Decided → Closed) + per-state stall detection. |
| [concurrency-safeguards.md](concurrency-safeguards.md) | Detection, prevention, and recovery conventions for concurrent writes across Layer 1 / 2 / 3 file surfaces. |
| [lifecycle-tailoring.md](lifecycle-tailoring.md) | The platform's PMBOK-7 lifecycle tailoring: why the 3 agent states (ACTIVE/CLOSING/CLOSED) for cadence + granular PROJECT.md phase timelines for reporting are a deliberate, documented tailoring of the canonical 5-process-group model — citing five-function-spine for the group definitions, not redefining them. Includes a research-PMO alternative. |

## Document ecosystem

| Document | Purpose |
|---|---|
| [document-ecosystem-design.md](document-ecosystem-design.md) | Architectural narrative for the document-management layer. Three-domain model (Source / Managed Knowledge / Synthesized) + relationship model + trust model + three-layer schema/storage/presentation governance. Realized at entity-granularity by [project-entity-model.md](project-entity-model.md). |

## GitHub integration

| Document | Purpose |
|---|---|
| [github-feature-strategy.md](github-feature-strategy.md) | Feature decision matrix: which GitHub features the platform uses, defers, and enforces. ADR record. |
| [github-projects-guide.md](github-projects-guide.md) | Operational reference for the PMO Pipeline GitHub Project — fields, views, automations, agent integration patterns. |
