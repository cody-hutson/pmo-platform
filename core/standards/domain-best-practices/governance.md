---
title: Domain Best-Practice Guide — Governance
purpose: A K1 universal reference that carries an Applicability Profile and indexes the authoritative best-practice sources for the governance domain (project/program governance, knowledge codification, documentation), for Stage-5 design and Stage-7 review consumption. One of the two seed guides establishing the domain-best-practice guide class; it is also the encoding of the platform's own internal-deliverable practice.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: governance
framework_version_anchor: "domain-aware-stage5-design"
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index — the design spoke consults this guide when the deliverable's domain is governance); the domain-best-practice review criterion (a Stage-5/7 reviewer checks a governance deliverable against this guide's concepts and contraindications); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==governance, including the pipeline-internal-exempt case)"
frameworks_cited: "PMI PMBOK 7th (2021); PRINCE2 2017; Nonaka SECI (1995); Diátaxis (current) — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->

# Domain Best-Practice Guide — Governance

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the governance guide — project/program governance, knowledge codification, and documentation practice. Because the platform is itself a governance deliverable, this guide doubles as the encoding of the platform's own internal-deliverable best-practice: a pipeline-internal/governance release is sourcing-exempt but still classifies as `domain: governance`, and this guide is the encoding that classification points at. The guide is **not** new machinery — its structure is borrowed entirely from shipped protocols (the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, the K1 placement model).

## Applicability Profile

```
Applicability Profile (for the governance guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; governance best-practice is not org-specific
  APPLIES-WHEN:          deliverable domain == governance   # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  CI-3 — research-grade / formal-audit-required practices are contraindicated when regulatory_posture is in {none, internal-governance} and the formal evidence is absent (lightweight self-review suffices)
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 3 (evidence-tier tiebreak) — governance practices of equal specificity resolve by the stronger evidence tier
```

`UNIVERSALITY: universal` because a different organization running the platform would find this content true and useful verbatim. The `CONTRAINDICATED-WHEN: CI-3` entry is the governance domain's most relevant contraindication: a single-operator, internally-governed deployment should not be forced into research-grade evidence or formal external audit ceremonies where lightweight self-review is the proportionate control. The guide MUST NOT embed contextual literals (no operator name, no project name, no single-operator-HITL assumption hardcoded as universal) — the contraindication is exactly how context is consumed as a mediated input rather than baked in.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == governance
- **Contraindicated when:** CI-3 (research-grade/formal-audit practices when regulatory_posture in {none, internal-governance} and evidence absent)
- **On conflict:** precedence-ladder rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is the second of the two fresh in-doc demonstrations of the applicability rubric the guide class contributes (the software guide is the other), disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use) and a design-consumption note (what a Stage-5/7 spoke checks a governance deliverable against).

### Compliance (value-driven, tailored governance)

**Source:** `[FRAMEWORK: PMI PMBOK 7th 2021]` (ET2 — peer-reviewed canonical framework) and `[FRAMEWORK: PRINCE2 2017]` (ET2). PMBOK 7 (2021) reframed project management around **12 principles** — stewardship, value delivery, tailoring, stakeholder engagement, and others — explicitly stating that **value, not output, is the measure of success**: a deliverable that ships on time and on budget but generates no real benefit is not a success. PRINCE2's **continued business justification** principle operationalizes the same idea — the business case is revisited at every stage boundary and the work proceeds only while it remains justified. Both frameworks pair this with **tailoring**: PMBOK's tailoring principle and PRINCE2's tailoring principle both hold that governance must be adapted to the project's scale, complexity, and risk rather than applied as uniform ceremony ("discipline without rigidity").

**Design-consumption note:** a governance deliverable is checked for (a) a stated value/outcome it serves, not merely an output it produces; (b) a justification that is revisited rather than assumed-once; (c) governance weight proportionate to the work's scale and risk (tailoring) — heavy ceremony on a low-risk change is a tailoring failure, the inverse of CI-3.

### Auditability

**Source:** `[FRAMEWORK: PMI PMBOK 7th 2021]` (ET2) and `[FRAMEWORK: Nonaka SECI 1995]` (ET2). Auditability is the property that a decision or change can be reconstructed after the fact. Nonaka's SECI model grounds the mechanism: **externalization** — articulating tacit knowledge into explicit form — is precisely what turns an in-someone's-head decision into an inspectable record. An audit trail is externalized knowledge: the act of writing the decision down is what makes it auditable.

**Design-consumption note:** a governance deliverable is checked for (a) decisions externalized into explicit, inspectable records (not left tacit); (b) a reconstructable trail from a change back to its rationale and authorization; (c) records placed where an auditor would actually find them. CI-3 applies here: the *depth* of audit ceremony is scaled to regulatory posture — a single-operator internal-governance deployment needs a reconstructable trail, not a research-grade evidentiary apparatus.

### Traceability

**Source:** `[FRAMEWORK: PRINCE2 2017]` (ET2) and `[CONSENSUS: Diátaxis (current)]` (ET3 — practitioner consensus; admitted with the mandatory paired applicability note below). PRINCE2's **manage-by-stages** and **defined-roles** principles produce traceability structurally: stage boundaries are decision points with an updated business case and a documented go/no-go, so the project's history is a chain of traceable stage decisions. Diátaxis contributes the documentation-structure half: it identifies four distinct documentation needs — **tutorials** (learning-oriented), **how-to guides** (task-oriented), **reference** (information-oriented), and **explanation** (understanding-oriented) — and holds that documentation should be organized around those needs so a reader can trace from a need to the right document.

**Mandatory paired applicability note (per the ET3 practitioner-consensus rule — consensus is not universal fit):** Diátaxis is a broadly-adopted *consensus* standard, not an empirically-proven universal law. It fits documentation corpora that serve multiple reader needs (learning vs doing vs looking-up vs understanding); it is **over-structure for a small single-purpose document set** where the four-mode separation adds navigation overhead without a corresponding reader benefit. Apply Diátaxis where the corpus is large and multi-need; do not impose the four-mode split on a handful of single-purpose docs. (This is the consensus-≠-universal-fit handoff seam the evidence-tier rule names for ET3 sources.)

**Design-consumption note:** a governance deliverable is checked for (a) a traceable chain from a change to its authorizing decision (the PRINCE2 stage-decision discipline); (b) documentation organized so a reader can trace from their need to the right doc — where the corpus is large enough to warrant it (the Diátaxis applicability note); (c) NOT four-mode documentation ceremony imposed on a single-purpose doc set.

### Knowledge-codification

**Source:** `[FRAMEWORK: Nonaka SECI 1995]` (ET2). SECI is the canonical model of organizational knowledge creation: knowledge moves through **socialization** (tacit→tacit), **externalization** (tacit→explicit), **combination** (explicit→explicit), and **internalization** (explicit→tacit). Codifying knowledge is the externalization-then-combination path: articulate the tacit practice into an explicit artifact, then combine it with the existing explicit corpus. This is exactly the platform's own promotion path from a learned lesson to a codified governance artifact.

**Design-consumption note:** a governance deliverable is checked for (a) tacit practice externalized into an explicit, transferable artifact rather than left as individual know-how; (b) the new artifact combined with — not duplicating — the existing corpus (the single-source discipline is the combination step done correctly); (c) a promotion path that does not hardcode the lesson prematurely (premature codification of a not-yet-stable pattern is the failure mode).

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — what a Stage-5/7 spoke checks a governance deliverable against. It is distinct from the platform's source-taxonomy, the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the taxonomy's project/program-management (D1) and knowledge-management (D3) sources; the taxonomy does not carry an Applicability Profile. Do not collapse the two.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, `UNIVERSALITY: contextual`, a narrower context predicate, operator-instance placement. Authoring this guide to the standard Profile schema is what lets a later onboarding capability plug in by emitting the same shape, inventing nothing. A contextual KB that needed a different Profile shape would signal the seam was mis-designed; schema conformance is load-bearing.

## Cutover

This guide and the domain-best-practice guide class apply to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the guide class shipping in a release cannot retroactively bind its own design/review work. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline carried by the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline.
