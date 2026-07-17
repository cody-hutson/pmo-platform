---
title: Domain Best-Practice Guide — Support
purpose: A K1 universal reference that carries an Applicability Profile and indexes the authoritative best-practice sources for the support domain — service management, incident & on-call practice, and service reliability — for Stage-5 design and Stage-7 review consumption. One of the domain-best-practice guide class, mirroring its software/governance/process siblings.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
framework_version_anchor: domain-aware-stage5-design
domain: support
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index — the design spoke consults this guide when the deliverable's domain is support); the domain-best-practice review criterion (a Stage-5/7 reviewer checks a support deliverable against this guide's concepts and the contraindications its Applicability Profile names); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==support); and the support-domain specialist skills operations/skills/pmo-tier-1-support and operations/skills/pmo-tier-2-support (each cites this guide as its design-time best-practice anchor)"
frameworks_cited: "ITIL 4 (2019); service-management practice; SRE (Google SRE, Beyer et al. 2016) / on-call practice — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->

# Domain Best-Practice Guide — Support

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the support guide — service management, incident handling and on-call practice, and the reliability discipline that governs how a running service is supported. It is **not** new machinery: every structural property is borrowed from a shipped protocol — the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, and the K1 placement model. The guide cites authoritative sources (the sourcing input); a Stage-5/7 design or review consults the guide to check a support deliverable against current authoritative practice (the design-consumption content).

The support domain cites **external** service-management and reliability frameworks (ITIL 4, the SRE canon) whose text lives outside the platform — the same posture the software and governance guides take, and distinct from the process guide, whose rule bodies are already codified inside the platform. The guide therefore adds the design-consumption layer over those external sources and does not restate any framework body (per the register-or-remove single-source discipline).

No ADR accompanies this guide: the decision is obvious — mirror three shipped sibling guides (`software.md`, `governance.md`, `process.md`) to fill a named coverage gap (the support domain) — so an ADR would be ceremony rather than a recorded non-obvious choice. The rationale is recorded inline here, exactly as the siblings record theirs.

## Applicability Profile

The guide's spine is the platform's standard Applicability Profile schema. The Profile makes "does this guide apply to the deliverable in context C?" a decidable predicate, not interpretation.

```
Applicability Profile (for the support guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; service-management and reliability best-practice is not org-specific
  APPLIES-WHEN:          deliverable domain == support    # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  CI-S — heavyweight service-management ceremony (formal CAB change-approval, full multi-tier incident-command structure, an SLA/error-budget apparatus) is contraindicated for a low-volume, low-criticality support surface where a lightweight path is the proportionate control; the ITIL "guiding principles" (progress iteratively, keep it simple and practical) govern, the same tailoring posture the governance guide's CI-3 and the process guide's CI-P express
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 2 (lex specialis) — a more-specific support practice beats a more-general one; equal specificity falls to rung 3 (evidence-tier tiebreak)
```

`UNIVERSALITY: universal` because a different organization running the platform would find this guide's content true and useful verbatim — incident triage, escalation tiers, a reconstructable incident record, and reliability targets bounded by an error budget carry no operator-specific, project-specific, or single-reviewer assumption. The guide MUST NOT embed contextual literals (an operator name, a project name, a team-structure or single-operator-HITL assumption hardcoded as universal); the `CI-S` contraindication is exactly how context (the support surface's volume and criticality) is consumed as a mediated input rather than baked in. The domain signal it is indexed by is the abstract `domain:` class, never a hard read of a project-specific field.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == support
- **Contraindicated when:** CI-S (heavyweight service-management / incident-command / error-budget ceremony when the support surface is low-volume and low-criticality and a lightweight path is the proportionate control)
- **On conflict:** precedence-ladder rung 2 (lex specialis); equal specificity → rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is the support domain's fresh in-doc demonstration of the applicability rubric — a fourth instance alongside the software guide's, the governance guide's, and the process guide's, disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use per the corpus-curation evidence-label discipline) and a design-consumption note (what a Stage-5/7 spoke checks a support deliverable against).

### Service management (value-stream, tailored governance)

**Source:** `[FRAMEWORK: ITIL 4 2019]` (ET2 — peer-reviewed canonical framework). ITIL 4 reframes IT service management around a **Service Value System** and **four dimensions** (organizations & people, information & technology, partners & suppliers, value streams & processes), and replaces ITIL v3's rigid process catalogue with 34 **practices** governed by seven **guiding principles** — among them *focus on value*, *start where you are*, *progress iteratively with feedback*, and *keep it simple and practical*. The shift is from process-as-ceremony to value-stream-as-outcome: the measure of a support function is the value it co-creates with the consumer, not the volume of tickets it processes.

**Design-consumption note:** a support deliverable is checked for (a) a stated value/outcome it serves the service consumer, not merely a throughput it produces; (b) governance weight proportionate to the service's scale and criticality (the *keep it simple and practical* principle) — heavy change-approval or multi-tier ceremony on a low-criticality surface is the tailoring failure, the inverse of `CI-S`; (c) the four dimensions considered, so a design does not optimize the process while ignoring the people, tooling, or supplier dimension that actually gates the outcome.

### Incident management & escalation (triage, tiered routing, reconstructable record)

**Source:** `[FRAMEWORK: ITIL 4 2019]` (ET2) and `[PRACTITIONER-CONSENSUS: service-management / incident & on-call practice]` (ET3 — broadly-adopted practitioner consensus; admitted with the mandatory paired applicability note below). ITIL 4's **incident management** practice holds that an incident is an unplanned interruption or quality reduction to a service, and that the objective is to **restore normal service operation as quickly as possible** — restoration first, root cause second (the latter is the problem-management practice). Mature incident practice adds **tiered escalation**: a front-line tier triages and resolves common, well-understood incidents against a known-error base, and escalates to a specialist tier (functional escalation) the incidents that exceed its scope — with a clear escalation trigger rather than an ad-hoc hand-off. On-call practice contributes the time dimension: a defined rotation, a paging path, and a severity scale that decides what wakes a human.

**Mandatory paired applicability note (per the ET3 practitioner-consensus rule — consensus is not universal fit):** the multi-tier incident-command / formal on-call apparatus is a broadly-adopted *consensus* practice, not an empirically-proven universal law. It fits a service with **enough incident volume and criticality** to warrant a standing rotation and a tier structure; it is **over-structure for a low-volume, low-criticality support surface**, where a single resolver path and a lightweight log are the proportionate control (`CI-S`). Apply the tiered structure where the volume and criticality warrant it; do not impose a formal incident-command structure on a handful of low-severity tickets. (This is the consensus-≠-universal-fit handoff seam the evidence-tier rule names for ET3 sources.)

**Design-consumption note:** a support deliverable is checked for (a) a triage step that classifies an incident by impact/urgency and routes it, restoration-first, rather than starting with root-cause analysis; (b) an explicit escalation trigger and a tiered routing path (front-line resolve vs functional escalation) — where the volume/criticality warrant it (the applicability note); (c) a reconstructable incident record (what happened, what was done, when it was restored) so the incident is auditable and feeds problem-management later — NOT a formal multi-tier incident-command structure imposed on a low-criticality surface.

### Service reliability (SLI/SLO, error budgets, toil reduction)

**Source:** `[FRAMEWORK: SRE — Google SRE 2016]` (ET2 — peer-reviewed canonical framework). Site Reliability Engineering grounds reliability in **measured objectives rather than aspiration**: a **Service Level Indicator (SLI)** is a quantitative measure of service behavior (latency, availability, error rate); a **Service Level Objective (SLO)** is a target value for an SLI; and the gap between the SLO and 100% is the **error budget** — the amount of unreliability the service is permitted to spend. The error budget reframes the support-vs-velocity tension as a budget decision: while the budget holds, ship; when it is exhausted, reliability work takes priority. SRE also names **toil** — manual, repetitive, automatable operational work with no enduring value — and holds that toil should be measured and capped so the support function is not consumed by it.

**Design-consumption note:** a support deliverable is checked for (a) reliability stated as a *measured* objective (an SLI with an SLO target) rather than an aspiration ("highly reliable"); (b) an error-budget posture that makes the reliability-vs-change trade-off a decidable call rather than a standing argument — where the service criticality warrants the apparatus (`CI-S` bounds this: a low-criticality surface does not need a formal error budget); (c) a toil-reduction lens — repetitive manual support work named and a path to automate or cap it, so the support function scales rather than absorbing linear headcount.

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — it tells a Stage-5/7 spoke what to check a support deliverable against. It is distinct from the platform's source-taxonomy, which is the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the taxonomy's service-management and reliability sources; the taxonomy does not carry an Applicability Profile and does not tell a design what to check. Different objects, clean seam: do not collapse the guide into the source taxonomy or vice versa.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, but with `UNIVERSALITY: contextual` and a narrower context predicate (e.g., an organization's own severity scale, on-call rotation, or service catalogue), placed in the operator-instance layer rather than the platform corpus. Authoring this guide to the standard Profile schema **is** what lets a later onboarding capability plug in by emitting the same shape — reusing the existing schema, inventing nothing. A future contextual KB that needed a *different* Profile shape would signal this seam was mis-designed; conformance to the standard schema is therefore load-bearing, not cosmetic.

## Cutover

This guide and the domain-best-practice guide class apply to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the guide class shipping in a release cannot retroactively bind its own design/review work, which ran before the guide existed. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline carry.
