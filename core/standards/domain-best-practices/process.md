---
title: Domain Best-Practice Guide — Process
purpose: A K1 universal reference that carries an Applicability Profile and indexes the authoritative best-practice sources for the process domain — staged execution, discovery/decision/review discipline — for Stage-5 design and Stage-7 review consumption. One of the domain-best-practice guide class; it indexes the platform's own codified process disciplines as the enforcing artifacts rather than restating them.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: process
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index — the design spoke consults this guide when the deliverable's domain is process); the domain-best-practice review criterion (a Stage-5/7 reviewer checks a process deliverable against this guide's concepts and the contraindications its Applicability Profile names); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==process); and the process-domain specialist skills operations/skills/pmo-scrum-master, operations/skills/pmo-release-train-engineer, operations/skills/pmo-business-analyst, and operations/skills/pmo-product-owner (each cites this guide as its design-time best-practice anchor; pmo-product-owner is dual-domain and also cites governance.md)"
frameworks_cited: "PMI PMBOK 7th (2021); PRINCE2 2017; Scrum Guide 2020; Kanban (Anderson 2010) — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->

# Domain Best-Practice Guide — Process

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the process guide — staged execution, phase-gating, and the discovery/decision/review discipline that governs how delivery work is conducted. It is **not** new machinery: every structural property is borrowed from a shipped protocol — the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, and the K1 placement model. The guide cites authoritative sources (the sourcing input); a Stage-5/7 design or review consults the guide to check a process deliverable against current authoritative practice (the design-consumption content).

The process domain is distinctive among the three best-practice domains in *where its rule bodies already live*: the software and governance guides cite **external** frameworks (Gang of Four, PMBOK) whose text lives outside the platform, whereas the process domain's best-practice is already **codified inside the platform** — in the 13-stage pipeline specs and the discovery/decision/review disciplines. This guide therefore cites those existing process surfaces by relative path as the enforcing artifacts and adds only the design-consumption layer, rather than restating any rule body (per the register-or-remove single-source discipline). The two external process frameworks it grounds (PMBOK 7, PRINCE2) supply the canonical staged-execution and tailoring principles those internal surfaces enact.

No ADR accompanies this guide: the decision is obvious — mirror two shipped sibling guides (`software.md`, `governance.md`) to fill a named coverage gap — so an ADR would be ceremony rather than a recorded non-obvious choice. The rationale is recorded inline here, exactly as the siblings record theirs.

## Applicability Profile

The guide's spine is the platform's standard Applicability Profile schema. The Profile makes "does this guide apply to the deliverable in context C?" a decidable predicate, not interpretation.

```
Applicability Profile (for the process guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; process best-practice (staged execution, discovery/decision/review) is not org-specific
  APPLIES-WHEN:          deliverable domain == process    # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  CI-P — heavyweight staged ceremony (full phase-gating, ADR authorship, formal discovery/review passes) is contraindicated for a trivial, well-understood point change where a lightweight path is the proportionate control; the tailoring principle governs, the same lex-specialis posture the pipeline's own "obvious decision → no ADR; omission is the correct non-ceremony signal" guard expresses
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 2 (lex specialis) — a more-specific process practice beats a more-general one; equal specificity falls to rung 3 (evidence-tier tiebreak)
```

`UNIVERSALITY: universal` because a different organization running the platform would find this guide's content true and useful verbatim — staged execution with decidable gates, discovery before build, proportionate decision ceremony, and review at activity-exit carry no operator-specific, project-specific, or single-reviewer assumption. The guide MUST NOT embed contextual literals (an operator name, a project name, a team-structure or single-operator-HITL assumption hardcoded as universal); the `CI-P` contraindication is exactly how context (the work's scale and risk) is consumed as a mediated input rather than baked in. The domain signal it is indexed by is the abstract `domain:` class, never a hard read of a project-specific field.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == process
- **Contraindicated when:** CI-P (heavyweight staged ceremony when the change is a trivial, well-understood point change and a lightweight path is the proportionate control)
- **On conflict:** precedence-ladder rung 2 (lex specialis); equal specificity → rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is the process domain's fresh in-doc demonstration of the applicability rubric — a third instance alongside the software guide's and the governance guide's, disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use per the corpus-curation evidence-label discipline) and a design-consumption note (what a Stage-5/7 spoke checks a process deliverable against). For the platform's own codified process disciplines, the **enforcing artifact** is cited by relative path — the rule body stays registered in that surface and is never reproduced here.

### Staged execution & phase-gating

**Source:** `[FRAMEWORK: PRINCE2 2017]` (ET2 — peer-reviewed canonical framework) and `[FRAMEWORK: PMI PMBOK 7th 2021]` (ET2). PRINCE2's **manage-by-stages** principle holds that a project advances through discrete management stages, each terminating in a decision point where an updated business case drives an explicit go/no-go — so work proceeds in controlled increments rather than as an undifferentiated flow. PMBOK 7's **tailoring** principle pairs with it: the weight of the staged process is adapted to the work's scale, complexity, and risk rather than applied as uniform ceremony ("discipline without rigidity").

**Enforcing artifact (cited, not restated):** the 13-stage pipeline specs [`stage-*.md`](../../../release/references/pipeline/) and the process-self-governance surface [`release-process.md`](../../../release/governance/release-process.md). These carry the phase-by-phase procedure, the per-stage gate criteria, and the stage-transition mechanics; this guide points at them and does not duplicate any stage's procedure.

**Design-consumption note:** a Stage-5 process design is checked for (a) explicit stage/phase boundaries each carrying a decidable go/no-go, rather than an undifferentiated flow; (b) gate criteria stated as decidable predicates, not as "make it rigorous"; (c) ceremony **tailored** to scale — heavy phase-gating imposed on a trivial change is the tailoring failure, the inverse of the `CI-P` contraindication.

### Discovery-before-build (activity-entry posture)

**Source:** `[INTERNAL-DISCIPLINE: discovery framework]` — the platform's own codified discovery discipline, itself grounded in the staged-execution canon above (a stage entry is exactly where discovery fires). Discovery is the first-class activity of interrogating what is not yet known — open premises, missing evidence, where scope cleaves — fired at activity-**entry**, before any artifact is produced. It is the temporal inverse of review.

**Enforcing artifact (cited, not restated):** [`discovery-discipline.md`](../../disciplines/discovery-discipline.md). It carries the activation triggers, the open-question/gap/scope-cleavage register structure, and the routing to decision and review; this guide points at it and does not reproduce the activation-trigger list.

**Design-consumption note:** a Stage-5 process design is checked for (a) a discovery step at activity-entry — premise interrogation, gap surfacing, scope-cleavage identification — **before** artifacts are committed, rather than discovery deferred until a defect surfaces; (b) evidence-quality labels on every grounded claim the design rests on; (c) a clean split between "we don't know yet" (a spike/discovery obligation) and "we can't know" (a standing constraint) — without the design restating the discovery framework's activation triggers.

### Decision adjudication (localization / opposing-view / ceremony-guard)

**Source:** `[INTERNAL-DISCIPLINE: decision framework]` — the platform's own codified decision discipline. It governs how a non-obvious call is made: the change is localized to where it actually bites rather than applied globally, an opposing view is weighed before the call, and the decision ceremony is held proportionate — the guard that an *omitted* ADR for an obvious decision is the correct non-ceremony signal, not a gap.

**Enforcing artifact (cited, not restated):** [`decision-discipline.md`](../../disciplines/decision-discipline.md). It carries the localization, opposing-view, and ceremony-guard mechanisms in full; this guide points at it and does not reproduce the mechanism bodies.

**Design-consumption note:** a Stage-5 process design is checked for (a) decisions localized — a change scoped to the surface it actually affects, not a global edit where a targeted one suffices; (b) an opposing view explicitly considered before a non-obvious call is recorded; (c) decision ceremony proportionate to reversibility and blast radius — the ceremony-guard that omitting an ADR for an obvious decision is correct, not a defect — without the design reproducing the three-mechanism bodies.

### Review at activity-exit (root-caused, deliverable-structured)

**Source:** `[INTERNAL-DISCIPLINE: review framework]` — the platform's own codified review discipline, grounded in the review canon already encoded there. Review is the activity-**exit** posture (the temporal inverse of discovery): a finished artifact is examined against an anti-laziness standard, every finding carries a root cause and a resolution rather than a bare pass/fail verdict, and the output is deliverable-structured (findings, systemic patterns, residual-risk register, remediation priority).

**Enforcing artifact (cited, not restated):** [`review-discipline-principles.md`](../../disciplines/review-discipline-principles.md). It carries the anti-laziness rule set, the root-cause requirement, and the multi-deliverable output structure in full; this guide points at it and does not reproduce the rule list or the deliverable structure.

**Design-consumption note:** a process deliverable is checked for (a) a review/QA step at activity-exit — the temporal inverse of the discovery step above — rather than review folded into authoring; (b) findings that carry a root cause and a resolution, not pass/fail verdicts alone; (c) a review scope declared-then-held, so the review itself does not creep in scope — without the design restating the anti-laziness rules or the deliverable-structure list.

### Ticket-vs-architecture reconciliation (pre-build premise-currency)

**Source:** `[INTERNAL-DISCIPLINE: ticket-architecture reconciliation]` — the platform's own codified pre-build reconciliation discipline, the ticket-vs-live-architecture specialization of the discovery-before-build posture above (a stage entry is exactly where a ticket's premise is checked against the architecture it will build on). It fires at activity-**entry** (Stage 4/5) when a tracked ticket touches an architecture surface, using ticket-age-relative-to-that-architecture as the staleness signal — so a ticket authored against an architecture that has since moved is reconciled before design, not built stale.

**Enforcing artifact (cited, not restated):** [`ticket-architecture-reconciliation.md`](../../disciplines/ticket-architecture-reconciliation.md). It carries the when-fires predicate, the 4-step reconcile procedure, the reconciliation-record schema, the composition map, and the failure modes in full; this guide points at it and does not reproduce the procedure.

**Design-consumption note:** a Stage-4/5 process design is checked for (a) a reconciliation step at build-entry — for each ticket that touches ≥1 architecture surface, the ticket's premise reconciled against the dated live architecture before design; (b) the consistency surfaces (ledger/registry/charter) updated, not just behavior; (c) each reconciliation surfaced as an explicit C1/C2/C3-classified decision — without the design restating the discipline's 4-step procedure or its failure-mode list.

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — it tells a Stage-5/7 spoke what to check a process deliverable against. It is distinct from the platform's source-taxonomy, which is the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the taxonomy's project/program-management (D1) sources (PMBOK, PRINCE2) for the external staged-execution canon, and indexes the platform's own discovery/decision/review disciplines and the pipeline as the **enforcing artifacts** that enact that canon — the same posture `governance.md` takes when it treats the platform's promotion path as the enacted instance of SECI. The taxonomy does not carry an Applicability Profile and does not tell a design what to check. Different objects, clean seam: do not collapse the guide into the source taxonomy or vice versa, and do not collapse the design-consumption note into the enforcing artifact it points at.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, but with `UNIVERSALITY: contextual` and a narrower context predicate (e.g., an organization's own stage-gate model or ceremony cadence), placed in the operator-instance layer rather than the platform corpus. Authoring this guide to the standard Profile schema **is** what lets a later onboarding capability plug in by emitting the same shape — reusing the existing schema, inventing nothing. A future contextual KB that needed a *different* Profile shape would signal this seam was mis-designed; conformance to the standard schema is therefore load-bearing, not cosmetic.

## Cutover

This guide and the domain-best-practice guide class apply to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the guide class shipping in a release cannot retroactively bind its own design/review work, which ran before the guide existed. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline carry.
