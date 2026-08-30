---
title: Domain Best-Practice Guide — Security Architecture
purpose: A K1 universal reference carrying an Applicability Profile and indexing the authoritative best-practice sources for architecture-level security — trust-boundary decomposition, threat enumeration, control selection — for Stage-5 design and Stage-7 review consumption. Distinct from software.md § Security (implementation-level control hygiene).
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: security
framework_version_anchor: "skill-surface-sync"
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index, consulted when the deliverable's domain is security); the domain-best-practice review criterion (Stage-5/7); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==security); release/skills/pmo-architect (Mode 3 Security-Architecture — design-time threat-modeling anchor)"
frameworks_cited: "Saltzer & Schroeder (1975); STRIDE (Kohnfelder & Garg 1999); NIST SP 800-207 Zero Trust Architecture (2020); OWASP ASVS 4.0.3 (2021) — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->

# Domain Best-Practice Guide — Security Architecture

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the security guide — trust-boundary decomposition, per-boundary threat enumeration, control selection with an explicit fail-mode, and the verification depth a design owes. It is **not** new machinery: every structural property is borrowed from a shipped protocol — the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, and the K1 placement model. The guide cites authoritative sources (the sourcing input); a Stage-5/7 design or review consults the guide to check a security deliverable against current authoritative practice (the design-consumption content).

This guide sits at **architecture altitude** and is deliberately bounded there. The platform already codifies *implementation-level* control hygiene — fail-closed controls, input validation, sink-context output encoding, injection resistance — in the software guide's § Security at `core/standards/domain-best-practices/software.md`. This guide decides **which control the architecture owes and where the boundary falls**; that one governs **how the control is built**. The two are cited across, never restated across, per the compose-by-reference discipline (ADR-019) and the register-or-remove single-source rule.

The security domain cites **external** security-architecture frameworks whose text lives outside the platform — the same posture the software, governance, and support guides take, and distinct from the process guide, whose rule bodies are already codified inside the platform. The guide therefore adds the design-consumption layer over those external sources and does not restate any framework body.

No ADR accompanies this guide. The decision it would record — whether a domain earns a shared guide — already has one, and its own §5.7 sibling rule covers the case: where no guide exists for a deliverable's domain, that absence is itself the demand signal for authoring one. The rationale is recorded inline here, exactly as the sibling guides record theirs.

## Applicability Profile

The guide's spine is the platform's standard Applicability Profile schema. The Profile makes "does this guide apply to the deliverable in context C?" a decidable predicate, not interpretation.

```
Applicability Profile (for the security guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; security-architecture best-practice is not org-specific
  APPLIES-WHEN:          deliverable domain == security   # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  CI-3 — research-grade / formal-audit security practices (a formal threat-model artifact, an external control assessment, a full assurance-evidence package) are contraindicated when regulatory_posture is in {none, internal-governance} and the formal evidence is absent; a proportionate lightweight boundary review is the control
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 2 (lex specialis) — a more-specific security practice beats a more-general one; equal specificity falls to rung 3 (evidence-tier tiebreak)
```

`UNIVERSALITY: universal` because a different organization running the platform would find this guide's content true and useful verbatim — naming trust boundaries, enumerating threats per crossing, selecting controls that fail safe, and stating residual risk carry no operator-specific, project-specific, or single-reviewer assumption. The guide MUST NOT embed contextual literals (an operator name, a project name, a team-structure or single-operator-HITL assumption hardcoded as universal); the `CI-3` contraindication is exactly how context (the deployment's regulatory posture) is consumed as a mediated input rather than baked in. The domain signal it is indexed by is the abstract `domain:` class, never a hard read of a project-specific field.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == security
- **Contraindicated when:** CI-3 (research-grade / formal-audit security practice when regulatory_posture in {none, internal-governance} and the formal evidence is absent)
- **On conflict:** precedence-ladder rung 2 (lex specialis); equal specificity → rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is the security domain's fresh in-doc demonstration of the applicability rubric — a fifth instance alongside the software, governance, process, and support guides', disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use per the corpus-curation evidence-label discipline) and a design-consumption note (what a Stage-5/7 spoke checks a security deliverable against).

### Trust-boundary decomposition

**Source:** `[FRAMEWORK: NIST SP 800-207 Zero Trust Architecture 2020]` (ET2 — canonical standards-body framework) and `[FRAMEWORK: Saltzer & Schroeder 1975]` (ET2 — the foundational protection-mechanism paper). SP 800-207 holds that trust is never granted implicitly by network location: every request crosses from a less-trusted to a more-trusted position and is evaluated at a **policy enforcement point** against a policy decision, per request rather than per session. Saltzer & Schroeder supply the older and stricter statement of the same idea — **complete mediation**: every access to every object is checked for authority, with no cached "already allowed" path that bypasses the check. Together they make boundary decomposition the first act of a security architecture: name where the trust level changes, and put a decision point at each named crossing.

**Design-consumption note:** a security deliverable is checked for (a) every crossing from a less-trusted to a more-trusted principal **named** — an unnamed crossing is an unassessed one, and the map's completeness is the claim being made; (b) a policy-enforcement point at each named crossing, rather than trust inherited from position, network, or call order; (c) no implicit trust zone left undeclared — a component treated as trusted because of where it runs is a declared decision or it is a defect.

### Threat enumeration per crossing

**Source:** `[FRAMEWORK: STRIDE — Kohnfelder & Garg 1999]` (ET2 — the canonical threat-classification framework). STRIDE enumerates six threat categories against each element of a design — **S**poofing (impersonating a principal), **T**ampering (unauthorized modification), **R**epudiation (denying an action without a record that contradicts it), **I**nformation disclosure (exposure to an unauthorized principal), **D**enial of service (removing availability), and **E**levation of privilege (gaining authority not granted). Its discipline is that the enumeration is applied **per element or per crossing**, not once over the whole system: a system-level pass produces a list of generic worries, while a per-crossing pass produces a specific claim about a specific boundary that a reviewer can check.

**Design-consumption note:** a security deliverable is checked for (a) enumeration performed **per boundary**, not once for the system as a whole; (b) each named threat stating what an adversary actually *achieves* if that boundary fails open — a threat without a consequence is not yet a finding; (c) categories consciously dismissed with a reason rather than silently skipped, so the gap between "not applicable here" and "not considered" is visible to the reviewer.

### Control selection and fail-mode

**Source:** `[FRAMEWORK: Saltzer & Schroeder 1975]` (ET2). The design principles that govern which control an architecture owes: **fail-safe defaults** (the default is denial; the design names what is permitted, not what is forbidden, so an omission closes rather than opens), **least privilege** (each principal holds the minimum authority its function needs, for the minimum time), **economy of mechanism** (the protection mechanism is small enough to be reviewed and reasoned about — complexity is where undetected flaws live), and **separation of privilege** (an operation of consequence requires more than one condition, so one compromised key or condition is not sufficient).

**Design-consumption note:** a security deliverable is checked for (a) each control stating its fail-mode explicitly, and resolving to *denied* when it cannot do its job — a control whose failure path is unstated has an unstated failure path, not an absent one; (b) privilege minimal and separated, with the authority each principal holds named rather than assumed; (c) mechanism small enough to review, with complexity that cannot be removed called out as accepted risk.

**Cite-not-restate clause (mandatory).** The *implementation-level* instantiation of these controls — fail-closed hooks that deny when a dependency is unresolvable, input validation that denies on a malformed parse, sink-context output encoding, and injection resistance by construction — lives at `core/standards/domain-best-practices/software.md` § Security. That section is the anchor for **how the control is built**; this concept is the anchor for **which control the architecture owes and where it sits**. Pointer only — no content absorption (ADR-019). A security design that begins restating the software guide's encoder rules has drifted out of this guide's altitude and belongs in that one.

### Verification depth and residual risk

**Source:** `[CONSENSUS: OWASP ASVS 4.0.3 (2021)]` (ET3 — broadly-adopted practitioner-consensus standard; admitted with the mandatory paired applicability note below). ASVS organizes verification requirements into a **depth ladder** — successive levels representing increasing assurance, from a baseline appropriate to low-assurance software, through a level for applications handling significant data, to a level for the highest-assurance case. The ladder's contribution here is the idea that verification depth is a **chosen and stated** property proportionate to what is at risk, not a uniform constant applied by reflex.

**Mandatory paired applicability note (per the ET3 consensus rule — consensus is not universal fit):** ASVS is a **web-application** verification standard. Its *level ladder* generalizes — depth proportionate to assurance need is a domain-independent idea — but its **control catalogue does not**: the specific requirement set assumes a web request/response application with sessions, browsers, and HTTP semantics, and is **over-structure for a non-web architecture** (a batch pipeline, a local hook estate, an offline toolchain). Use the ladder to decide and state a depth; do **not** impose the web-specific catalogue on a design whose shape it does not fit. Where the catalogue does not apply, the depth statement still does.

**Design-consumption note:** a security deliverable is checked for (a) verification depth proportionate to asset criticality and stated as a choice, not uniform across every boundary by default; (b) an explicit **residual-risk** position naming what the selected controls do **not** close, so the accepted exposure is a recorded decision rather than an omission; (c) NOT a web-application control catalogue imposed on a non-web design — the ladder travels, the catalogue does not.

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — it tells a Stage-5/7 spoke what to check a security deliverable against. It is distinct from the platform's source taxonomy, which is the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the security-architecture sources; the taxonomy does not carry an Applicability Profile and does not tell a design what to check. Different objects, clean seam: do not collapse the guide into the source taxonomy or vice versa.

One boundary condition is worth stating because it is easy to misread as an omission. The corpus-curation source taxonomy's own domain rows do **not** include a security row; that taxonomy is self-declared non-exhaustive, and this guide's sources therefore enter the platform the way the catalog's own convention directs — registered as rows in `core/specs/framework-catalog.md`, which is the governed registry for a newly referenced framework. The absence of a taxonomy row is not a missing registration.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, but with `UNIVERSALITY: contextual` and a narrower context predicate (an organization's own control catalogue, its classification scheme, its regulatory obligations), placed in the operator-instance layer rather than the platform corpus. Authoring this guide to the standard Profile schema **is** what lets a later onboarding capability plug in by emitting the same shape — reusing the existing schema, inventing nothing. A future contextual KB that needed a *different* Profile shape would signal this seam was mis-designed; conformance to the standard schema is therefore load-bearing, not cosmetic.

## Cutover

This guide applies to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — a guide shipping in a release cannot retroactively bind its own design/review work, which ran before the guide existed. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline carry.
