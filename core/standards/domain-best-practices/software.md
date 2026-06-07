---
title: Domain Best-Practice Guide — Software Engineering
purpose: A K1 universal reference that carries an Applicability Profile and indexes the authoritative best-practice sources for the software-engineering domain, for Stage-5 design and Stage-7 review consumption. One of the two seed guides establishing the domain-best-practice guide class.
type: standard
reversibility: CHEAP / Confidence HIGH
domain: software
framework_version_anchor: "domain-aware-stage5-design"
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index — the design spoke consults this guide when the deliverable's domain is software); the domain-best-practice review criterion (a Stage-5/7 reviewer checks the design against this guide's concepts and the contraindications its Applicability Profile names); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==software)"
frameworks_cited: "Gang of Four (1994); ADR — Nygard (2011); Fowler design heuristics (YAGNI) — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->

# Domain Best-Practice Guide — Software Engineering

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the software-engineering guide. It is **not** new machinery: every structural property is borrowed from a shipped protocol — the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, and the K1 placement model. The guide cites authoritative sources (the sourcing input); a Stage-5/7 design or review consults the guide to check a software deliverable against current authoritative practice (the design-consumption content).

## Applicability Profile

The guide's spine is the platform's standard Applicability Profile schema. The Profile makes "does this guide apply to the deliverable in context C?" a decidable predicate, not interpretation.

```
Applicability Profile (for the software guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; software best-practice is not org-specific
  APPLIES-WHEN:          deliverable domain == software   # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  (no structural contraindication for the guide as a whole; per-concept contraindications are stated inline — see the Fowler/YAGNI entry's paired contraindication)
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 2 (lex specialis) — a more-specific software practice beats a more-general one; equal specificity falls to rung 3 (evidence-tier tiebreak)
```

`UNIVERSALITY: universal` because a different organization running the platform would find this guide's content true and useful verbatim — it carries no operator-specific, project-specific, or single-reviewer assumption. The guide MUST NOT embed contextual literals (an operator name, a project name, a team-structure assumption); the domain signal it is indexed by is the abstract `domain:` class, never a hard read of a project-specific field.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == software
- **Contraindicated when:** per-concept (see the YAGNI entry's paired contraindication: do not invoke YAGNI to justify neglecting code health)
- **On conflict:** precedence-ladder rung 2 (lex specialis); equal specificity → rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is one of the two fresh in-doc demonstrations of the applicability rubric the guide class contributes (the governance guide is the other), disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use per the corpus-curation evidence-label discipline) and a design-consumption note (what a Stage-5 spoke checks a software design against).

### Maintainability

**Source:** `[FRAMEWORK: Gang of Four 1994]` (ET2 — peer-reviewed canonical framework) and `[FRAMEWORK: ADR — Nygard 2011]` (ET2). The Gang of Four established that systems are made more modular, flexible, and maintainable by two core design moves: **"program to an interface, not an implementation"** and **"favor object composition over class inheritance"** — composition being black-box reuse that does not expose internal details, whereas inheritance breaks encapsulation by exposing a subclass to its parent's implementation. Nygard's Architecture Decision Records add a maintainability dimension at the *decision* level: an ADR captures a single architectural decision with its context, decision, and consequences, so that people months or years later understand *why* the system is built as it is — a maintainability artifact in its own right.

**Design-consumption note:** a Stage-5 software design is checked for (a) dependence on abstractions/interfaces rather than concrete implementations at module boundaries; (b) composition over deep inheritance hierarchies where reuse is needed; (c) an ADR (or the platform's ADR-issue equivalent) for each non-obvious architectural decision, carrying context/decision/consequences — so the rationale survives turnover.

### Evolvability and testability

**Source:** `[FRAMEWORK: ADR — Nygard 2011]` (ET2) and `[FRAMEWORK: Gang of Four 1994]` (ET2). Recording decisions as ADRs keeps a system evolvable: a later change can be made knowingly because the original constraints and consequences are legible, rather than re-derived or violated by accident. GoF patterns localize variation behind stable interfaces, which is what makes a part of the system replaceable (evolvable) and substitutable by a test double (testable).

**Design-consumption note:** a Stage-5 software design is checked for (a) variation points isolated behind stable interfaces so a change is local rather than rippling; (b) seams that admit test doubles (a design that can only be tested end-to-end is a testability smell); (c) a legible decision trail so a future change does not silently violate a prior constraint.

### Simplicity-first (YAGNI)

**Source:** `[EXPERT-OPINION: Fowler — YAGNI ("You Aren't Gonna Need It")]` (ET5 — single-author heuristic; admitted only with the mandatory paired contraindication below). YAGNI, which Fowler articulates from the extreme-programming "do the simplest thing that could possibly work" practice, advises against building a capability now to support a *presumptive* future feature, because presumptive features carry four costs: **cost of build** (effort on features never used), **cost of delay** (value lost by postponing urgent work to build speculative work), **cost of carry** (added complexity that slows every other feature), and **cost of repair** (rework when the speculative feature does not match later understanding).

**Mandatory paired contraindication (per the ET5 evidence-tier rule — an expert-opinion source is never silently authoritative):** YAGNI is **contraindicated as a justification for neglecting code health**. Fowler is explicit on the limit: *"YAGNI only applies to capabilities built into the software to support a presumptive feature; it does not apply to effort to make the software easier to modify,"* and *"YAGNI is not a justification for neglecting the health of your code base. YAGNI requires (and enables) malleable code."* So invoking YAGNI to skip refactoring, self-testing code, or other malleability work is a misapplication: those efforts are exactly what makes YAGNI safe. YAGNI also does not apply when a future-proofing change adds no complexity — there is nothing to defer. **Do NOT cite YAGNI to defer maintainability or testability work when the codebase is not already malleable, because YAGNI presupposes malleable code and collapses without it.**

**Design-consumption note:** a Stage-5 software design is checked for (a) presumptive features built ahead of a real need (a YAGNI smell — flag and ask whether the need is real now); BUT (b) the reviewer must NOT use this concept to wave away refactoring, test seams, or decision records — those are malleability work that YAGNI explicitly exempts. The paired contraindication is what keeps the simplicity-first concept from being weaponized against code health.

### Scalability

**Source:** `[FRAMEWORK: Gang of Four 1994]` (ET2) for structural scalability (patterns that decouple components so they scale independently) and `[EXPERT-OPINION: Fowler — YAGNI]` (ET5, with the contraindication above) for the discipline of not over-engineering scale ahead of evidence. The honest current-practice position: scale for the load you can evidence, behind interfaces that let you re-scale a component without rewriting its consumers (the GoF decoupling move) — and do not pre-build for hypothetical scale (the YAGNI cost-of-carry argument), subject to the malleability contraindication.

**Design-consumption note:** a Stage-5 software design is checked for (a) components decoupled behind stable interfaces so an individual component can be re-scaled without a consumer rewrite; (b) scale decisions grounded in evidenced load rather than speculation — while (c) NOT using simplicity-first to skip the decoupling that makes future re-scaling cheap (the contraindication again).

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — it tells a Stage-5/7 spoke what to check a software design against. It is distinct from the platform's source-taxonomy, which is the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the taxonomy's software-domain (D4) sources; the taxonomy does not carry an Applicability Profile and does not tell a design what to check. Different objects, clean seam: do not collapse the guide into the source taxonomy or vice versa.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, but with `UNIVERSALITY: contextual` and a narrower context predicate, placed in the operator-instance layer rather than the platform corpus. Authoring this guide to the standard Profile schema **is** what lets a later onboarding capability plug in by emitting the same shape — reusing the existing schema, inventing nothing. A future contextual KB that needed a *different* Profile shape would signal this seam was mis-designed; conformance to the standard schema is therefore load-bearing, not cosmetic.

## Cutover

This guide and the domain-best-practice guide class apply to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the guide class shipping in a release cannot retroactively bind its own design/review work, which ran before the guide existed. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline carry.
