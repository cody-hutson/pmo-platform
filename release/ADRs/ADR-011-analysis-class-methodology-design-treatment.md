---
title: "ADR-011 — Analysis-class methodology-design treatment: Stage 5 persona variant (not a new stage)"
status: Accepted
date: 2026-06-02
release: v1.04-planning
deciders: "Stage 5 Solutioning (Principal Engineer — Architecture Assessment) + Adversarial Design Review"
tags: [architecture, governance, pipeline, persona, methodology-design, analysis-class]
source_observations:
  - "A prior release-process fitness audit surfaced a persona-stretch: analysis-class releases (primary deliverable = research artifact) route through Stage 5, whose Architecture-Assessment persona fits research-methodology-design work awkwardly."
  - "A new pipeline stage (Option A) would ripple across every file carrying the pipeline stage-count — a large blast radius with EXPENSIVE reversibility."
  - "Current-state survey: the Release Class enum is closed (no analysis-class member); Stage 5 activation is all-or-nothing per release; the per-stage-shard standard routes a new gate criterion to MODIFY-existing rather than a new shard."
---

# ADR-011 — Analysis-class methodology-design treatment: Stage 5 persona variant (not a new stage)

## Status
**Accepted.** An independent Adversarial Design Review interrogated this ADR's Option-A-rejection premise before scope-lock; its findings were advisory to the operator.

## Context
Analysis-class releases — releases whose primary deliverable is a research artifact (audit, gap analysis, methodology design) rather than code or governance edits — route through Stage 5 Solutioning. Stage 5's persona is Principal Engineer — Architecture Assessment, whose behavioral markers are architecture-decision framed (evaluates structural decisions; validates feasibility against current architecture; identifies blast radius). When the deliverable is a research methodology (sampling frame, evidence-grading rubric, coding scheme, analysis plan), those markers fit awkwardly. A prior release-process fitness audit recorded this as a persona-stretch.

The question is the FORM of the fix, decided here by ADR:
- **Option A** — a full new "Methodology Design" stage between Planning and Engineering, with its own persona card, gate criteria, and handoff schema; activation deterministic on release class. EXPENSIVE reversibility (a pipeline stage-count change).
- **Option B** — extend the existing Stage 5 persona card with an analysis-class research-methodology-design variant. MODERATE reversibility (one governance file).

A current-state survey established three decisive facts:
1. The Release Class enum is closed — {routine, novel, cross-cutting, hotfix} — with no `analysis-class` member; extending it is a governed change (release-class-taxonomy.md, § Class Enum). Option A's stated activation trigger ("deterministic on release class") therefore has no enum value to bind to.
2. Stage activation is all-or-nothing per release; every retained stage applies to every retained issue. Release class tunes only the activate/skip bias inside Stage 5 — never whether a stage exists. Per-issue mixed routing is disabled (planning-solutioning-handoff.md, § 2). A conditionally-activated stage has no precedent and no control machinery.
3. The per-stage-shard standard (§ 4.1) classifies "new Phase / new gate criterion / new cross-stage protocol on an existing stage" as a MODIFY-existing edit, and reserves authoring a brand-new stage shard for genuinely new stages. The methodology-design need is a variant of design work Stage 5 already owns.

Option A's blast radius spans every file that carries the pipeline stage-count (the public README, the release-process governance file, and every per-stage shard header) — a large edit on a contestable premise.

## Decision
**Adopt Option B.** Extend the Stage 5 (Principal Engineer — Architecture Assessment) persona card in release-personas.md with an **analysis-class research-methodology-design variant** — a scoped subsection that activates when the release deliverable is a research artifact. It adds research-methodology behavioral markers (defines sampling frame / evidence-grading rubric / coding scheme / analysis plan; grounds methodology in cited prior art; states validity threats and mitigations) while the base Architecture-Assessment markers remain the default for code and governance design.

**Activation** keys off the existing issue-level Stage 5 triggers — an analysis-class deliverable fires the structural-design and multiple-approaches triggers (planning-solutioning-handoff.md, § 3) — plus a descriptive "analysis-class deliverable" hint in the variant text. No new release-class enum value is introduced; no stage-count change; no renumber.

**Gate-teeth.** The variant is given methodology-design **gate criteria** and a **Stage 5→6 handoff schema** at the Stage 5 surface — not just behavioral-marker vocabulary. The gate criteria add a methodology-design row set to the Stage 5 Stage-Transition Gate (stage-05-solutioning.md, § 7); the handoff schema is appended as an extended-protocol section (§ 12) per the per-stage-shard standard's "new cross-stage protocol owned by an existing stage → append as extended-protocol section" rule. Both are MODIFY-existing edits of the Stage 5 surface; neither adds a stage. This closes the insufficiency the audit pre-registered for a vocabulary-only variant (a structural distinction may warrant its own gate criteria and hand-off schema) — the actual persona-stretch instance produced handoff schemas and an evidence-quality bar, so the variant gives methodology-design those teeth in-stage rather than leaving them to a separate stage.

**The pipeline stays 13 stages.** A stage-count renumber sweep is not needed under this decision.

## Consequences
**Positive:**
- MODERATE reversibility — the variant is one subsection in one governance file; the gate-teeth are two scoped additions (a § 7 gate row set and a § 12 handoff-schema section) to one pipeline shard.
- Zero stage-count blast radius; the corpus carrying the "13-stage" count is untouched; the public README's pipeline-count commitment holds.
- Conforms to the per-stage-shard standard's MODIFY-existing default and matches the existing sibling-variant precedent (the Stage 5 Phase A6.5 Adversarial Design Review variant).
- No Methodology-layer term collision; the existing stage-count and its compression rationale are intact.
- The persona-stretch is resolved: research-methodology work has explicit markers, an explicit quality gate, and an explicit handoff schema — not just vocabulary.

**Negative:**
- Stage 5's persona card accretes a second variant (after Adversarial Design Review) — card-bloat risk. Mitigated by scoping the variant as a subsection with an explicit activation predicate rather than a base-card rewrite.
- The gate-teeth add methodology-design criteria to the Stage 5 gate that fire only for analysis-class deliverables — gate-conditionality inside a shared gate. Mitigated: the criteria are explicitly predicated on variant activation (the same structural-design / multiple-approaches judgment), and the base gate criteria remain unconditional; a code or governance release simply does not exercise the methodology-design rows.
- "Is this release analysis-class?" remains a judgment at activation time (there is no enum value). Mitigated: the objective triggers carry activation; the analysis-class label is a descriptive hint, not the gating mechanism.

## Alternatives Considered
- **(A) Full new Methodology Design stage — REJECTED.** EXPENSIVE reversibility; a corpus-wide renumber on a contestable premise (methodology design is design, which Stage 5 already owns). Its activation trigger ("deterministic on release class") is specification-broken against the closed release-class enum. A conditionally-activated stage has no precedent (all-or-nothing activation; mixed routing disabled). "Methodology Design" collides with the reserved Methodology layer term. The gate criteria and handoff schema Option A would carry in a dedicated stage are instead supplied in-stage by Option B's gate-teeth, removing Option A's one genuine advantage at MODERATE rather than EXPENSIVE cost. Not foreclosed forever: if analysis-class cadence grows and a separate methodology-peer-review gate (one the Stage 5 transition gate cannot express) becomes necessary, a future ADR supersedes this one and adds the stage (the per-stage-shard standard documents that path).
- **(B) Stage 5 persona variant with in-stage gate-teeth — SELECTED.** See Decision.
- **(C) New release-class value `analysis-class` plus the Option-B variant — REJECTED for this release.** Adding a fifth release-class value is a governed enum change orthogonal to the persona-stretch fix and out of scope; the existing structural-design / multiple-approaches triggers already activate Stage 5 for analysis-class work without it. A future release may add the value if release-class dispatch (engagement density, review depth) genuinely needs to differentiate analysis-class releases — but that is a release-dispatch question, not a methodology-design-persona question.
- **(D) Do nothing — REJECTED.** Leaves the persona-stretch unresolved; the next analysis-class release repeats it (the longitudinal acceptance check would fail).
- **(B-narrow) Option B vocabulary-only, no gate-teeth — REJECTED at Collective Review.** Behavioral markers alone would leave the pre-registered insufficiency risk unaddressed. The adversarial review found the vocabulary-only variant under-powered against the actual persona-stretch instance, which produced handoff schemas and an evidence-quality bar. The operator folded the gate-teeth in; this ADR records that as part of the selected option.

## Reversibility
MODERATE. Revert = remove the variant subsection from release-personas.md (and its activation cross-pointer) and remove the two gate-teeth additions from stage-05-solutioning.md (the § 7 methodology-design gate row set and the § 12 handoff-schema section) by reverting one commit. No enumeration, no shard, and no README count change to undo. Supersession path: a future ADR may supersede this one to adopt Option A (a full stage) if a distinct methodology-design quality gate becomes necessary — the trigger condition is "an analysis-class release requires a methodology-peer-review gate that Stage 5's transition gate cannot express."

## References
- release-class-taxonomy.md, § Class Enum — the closed 4-value enum.
- planning-solutioning-handoff.md, § 2 (all-or-nothing activation) and § 3 (the issue-level Stage 5 triggers).
- per-stage-shard-standard.md, § 4.1 — MODIFY-existing vs author-new-shard; a new gate criterion or new cross-stage protocol routes to MODIFY-existing.
- release-personas.md, § Stage 5 — the base card and the new variant.
- stage-05-solutioning.md, § 7 (the gate-teeth gate criteria) and § 12 (the gate-teeth handoff schema).
- ADR-002 (modular pipeline split — documents the hypothetical new-stage extension path).
- ADR-005 (the house ADR format template followed here).
