---
title: "ADR-103 — Decision-audit hosts as pmo-qa-auditor Mode J (sibling to Mode I), not a standalone skill: ADR-019 conjunct-3 forecloses the net-new Specialist"
status: Proposed — to be ratified at the operator's Stage 9 plan-review gate for the decision-audit-and-learning release. The flip to Accepted is verified against this file's `status:` field, never assumed from milestone closure.
date: 2026-07-27
release: decision-audit-and-learning (version bound at Stage 12)
deciders: "operator (plan approval / Stage 9 ratification gate) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + Phase A6.5 adversarial design reviewer"
tags: [skill-architecture, decision-audit, pmo-qa-auditor, extend-before-create, compose-not-absorb, audit-family, oracle-derivation, mode-hosting]
source_observations:
  - "The per-mode increment and the host file's absolute length are different quantities, and only the first is decision-relevant. Measured at authoring: Mode I's dispatcher footprint inside SKILL.md is 73 lines, while its machinery occupies 260 lines of mode-spec plus 141 lines of dimension rubric under references/ and 203 lines of cadence protocol under the release module. A tenth mode built on that template adds roughly 75 lines to SKILL.md — about 4.6% of a body measured at 1627 lines at authoring. Both the 1627-line file measurement and the 75-line increment measurement are accurate; they answer different questions, and the growth question the host decision turns on is the increment."
  - "canonical-skill-structure.md §5 states the 400-line and 25600-byte values are 'triggers, not size caps', and that a skill crossing a trigger 'and carries a non-empty references/ subtree is compliant, however far it exceeds the trigger.' pmo-qa-auditor carries a populated references/ subtree, so it is compliant. The same section's multi-mode re-baseline clause adds that exceeding the soft authoring guideline is 'soft authoring-guideline debt, not a structural gate failure,' and 'does not by itself warrant a size-reduction pass.' The size objection is therefore refuted on governance, not merely outweighed on balance."
  - "ADR-019's skill-boundary test requires all three conjuncts to hold together for a net-new Specialist, and states that if any conjunct fails 'the capability belongs in the existing Specialist (or the existing function-skill), not in a new one.' Conjunct 3 (distinct primary role) fails: the decision audit and Mode I occupy the same primary role — retrospective cross-release audit against corpus-defined oracles, emitting the review-discipline six-deliverable set into a dated analysis folder. The standalone skill is non-conformant by rule, not merely costlier."
  - "The capability's own intake carried a cached oracle cardinality that did not reconcile against live state: a section-scoped structured count over the oracle sources at authoring returned a materially larger named-failure-mode set than the figure the intake recorded, and the discrepancy's cause is not determinable from this repository because the originating analysis artifact is operator-local. Whether the original count was wrong or the oracle set grew afterwards, the finding is the same and it is self-exemplifying — a frozen cardinality is silently invalidated by a single new entry, which is precisely the class of decay this capability exists to detect."
---
<!-- reference-durability: allow-link -->

# ADR-103 — Decision-audit hosts as pmo-qa-auditor Mode J (sibling to Mode I), not a standalone skill: ADR-019 conjunct-3 forecloses the net-new Specialist

## Status

Proposed — to be ratified at the operator's Stage 9 plan-review gate for the decision-audit-and-learning release. The flip to Accepted is verified against this file's `status:` field, never assumed from milestone closure.

**Numbering provenance — lineage `098 → 101 → 103`.** This record has renumbered twice; both moves have the same cause and neither reflects any change to the decision itself.

*First move, `098 → 101`.* Authored as a branch-local ADR-098 and renumbered while this branch was parked awaiting its dependency milestone. Four records were authored concurrently against the same next-free slot; per `core/ADRs/README.md` § Renumber log, first-to-merge takes the number and the other claimants renumber. `ADR-098-portability-seventh-first-class-value.md` merged first and kept **098**, then two further siblings claimed **099** and **100**, so `main` topped out at ADR-100 contiguous and **101** was the true next-free slot at that recomputation.

*Second move, `101 → 103`.* While this branch remained unmerged, the `agent-finops-intelligence` release merged and its own records took **101** (`core/ADRs/ADR-101-finops-store-frozen-kind-versioning-exemption.md`) and **102** (`release/ADRs/ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md`). Under merge-first-keeps-the-number the merged record keeps **101**, so this one moves again. Recomputed globally across **both** ADR homes and every remote ref, the sequence is contiguous at `001..102` with no gaps, making **103** the true next-free slot.

*Why this keeps happening — the mechanism, stated plainly.* The ADR sequence is a **single globally monotonic namespace spanning `core/ADRs/` and `release/ADRs/`**, but a number is *allocated at authorship* while the claim only *binds at merge*. A record authored on a long-lived branch is therefore exposed to every sibling release that merges ahead of it, and each such merge consumes the slot the branch is holding. This is a property of concurrent releases sharing one sequence, not a defect in any individual record — and it recurs for as long as the branch stays unmerged. Pre-reserving a higher number is not a remedy: `check-adr-numbers.py` fails a **gap** as readily as a duplicate, so the number is always chosen to keep `main` contiguous rather than to preserve this branch's earlier allocation.

## Context

The platform needs a repeatable decision health-check: a capability that audits how the release hub and its spokes make, improve, and validate decisions across a release window, and reports findings — so autonomous decisions can be held to durable confidence and corrected over time. A prior operator-local analysis demonstrated the method end-to-end and narrowed the host question to two viable options, rejecting a third. The capability build is blocked on that host question, so the host must be settled before the build starts.

**The forces:**

- **Reuse-first.** [ADR-019](ADR-019-specialists-compose-not-absorb.md) establishes that Specialists compose shared function-skills rather than absorbing or duplicating them, and gates a net-new Specialist behind a three-conjunct skill-boundary test.
- **The audit family already has a shape.** `pmo-qa-auditor` Modes E, F, and I share a report header, an observational-discipline self-check, an evidence-validation routine, and an OBSERVE-only mutation posture. Mode I in particular already reads the release record cross-release, scores it against a corpus-defined baseline, emits a six-deliverable set into a dated analysis folder, and carries a cadence protocol with a staleness sentinel.
- **The apparent cost of growing a large multi-mode skill.** The host skill is the largest SKILL.md in the corpus, and the analysis that framed the host question recorded that growth as the standing trade-off against extending it.
- **A gate obligation that postdates the framing.** [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md)'s extend-before-create criterion is gate-blocking: when a named existing infrastructure surface plausibly covers a capability class and the design nonetheless selects a net-new surface beside it, the design must record either an extend determination or a stated infeasibility reason. A net-new surface with no recorded determination is not design-complete. The two-option framing this decision inherits carries no such determination.

**On the growth trade-off — the argument stated on its own terms.** The host file's absolute length and the per-mode increment are different quantities, and only the second bears on whether to add a mode. The three-layer split the audit family already practices — a dispatcher entry in `SKILL.md`, machinery in a mode-spec under `references/`, and the scored content in a dimension rubric — means each added mode costs a small, roughly constant dispatcher footprint regardless of how deep its machinery runs, because the machinery lands in the growth surface `canonical-skill-structure.md` §5 explicitly sanctions. Measured against the sibling mode at authoring, a tenth mode adds on the order of seventy-five dispatcher lines.

**And the size objection is refuted on governance, not merely outweighed.** `canonical-skill-structure.md` §5 states the size values are *triggers, not size caps*, and that a skill crossing a trigger while carrying a non-empty `references/` subtree is compliant however far it exceeds the trigger. The host skill carries a populated `references/` subtree. The same section's multi-mode re-baseline records that a body exceeding the soft authoring guideline is soft authoring-guideline debt rather than a structural gate failure, and does not by itself warrant a size-reduction pass. Under the platform's own standard there is no size gate for extending this skill to fail.

## Decision

1. **The decision-audit capability hosts as `Mode J — Decision-Health Audit` in `core/skills/pmo-qa-auditor`, sibling to Mode I.** It is not a standalone `core/skills/decision-audit/` skill, and it is not an expansion of the project-scoped health-check skill — that skill is a downstream *consumer* of this audit family's committed summary surface, so hosting the audit there would invert an existing dependency edge.

2. **The capability splits across three layers, replicating the shape Mode I established.** The dispatcher lives in `core/skills/pmo-qa-auditor/SKILL.md` and owns the trigger set, scope statement, input set, mutation posture, the process by citation, and the does-not-auto-file clause. The machinery lives in `core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md` and owns window resolution, oracle derivation and pinning, evidence collection, the six-deliverable emission schema, and the committed-summary handoff schema. The scored content — the coverage-seam set, the per-seam grade vocabulary, and the run-over-run coverage-index formula — lives in a dimension rubric under the same `references/` directory and is its **single definition site**, so cross-artifact consistency between the capability and its scorecard is gradable by construction rather than by prose judgment.

3. **The when-to-run authority lives in `release/references/protocols/decision-audit-cadence.md`**, beside the three existing audit cadences. The cadence protocol owns the event triggers and the staleness sentinel; the mode owns how to run. The cadence file does not live inside the skill directory, matching the unanimous convention across the sibling axes and the in-skill when-to-run versus how-to-run split the audit family already states.

4. **Emission is two-surface.** Each run writes the git-ignored dated audit folder under the operator-instance analysis workspace **and** overwrites a committed summary handoff under the release module. This adopts Mode I's own precedent and exists for a specific reason: a tracked acceptance criterion whose only oracle sits at a git-ignored path is ungradable by construction. The committed surface gives the tracked criterion a tracked oracle, and gives a deployed consumer a flag it can read off any instance rather than only the producing one.

5. **The oracle set is derived and pinned at run time, never hardcoded.** The mode derives its oracle set from the corpus at each run, resolving the oracle-source roster from the corpus rather than enumerating it inline, and records the derived per-source counts together with a content-hash and date anchor in both emitted surfaces — mirroring the freshness anchor Mode I already carries. No Mode-J artifact carries a hardcoded oracle cardinality. This is deterministically gradable: a search for a fixed named-failure-mode count across the mode's artifacts must return nothing.

**The extend-before-create determination, recorded verbatim as the gate requires:** *extend `core/skills/pmo-qa-auditor/SKILL.md` (as Mode J, sibling to Mode I) because Mode I is a structurally isomorphic capability — same input class (the release record), same emission target class (a git-ignored dated audit folder plus a committed summary handoff), same mutation posture (OBSERVE-only, auto-files nothing), same cadence-protocol pattern — differing only in which corpus oracle it scores against; and because ADR-019's skill-boundary test fails conjunct 3 (distinct primary role) for the net-new alternative, which routes the capability into the existing Specialist by rule.*

## Consequences

**Positive.**

- One audit family, one output-report contract, one observational-discipline self-check, one evidence-validation routine. The standalone alternative would have forked all four.
- The dispatcher increment is small and roughly constant, because the machinery lands in the `references/` growth surface the structure standard sanctions rather than in the body.
- The coverage scorecard gets a deterministic single definition site, so the consistency constraint between the capability and its scorecard is checkable mechanically instead of by reading two specs against each other.
- The ungradable-criterion risk closes: the two-surface emission gives a tracked criterion a tracked oracle.
- The extend-before-create gate is satisfied with a recorded determination rather than an undocumented net-new surface.

**Negative — stated plainly.**

- The host skill reaches ten modes. This is compliant under the structure standard because the `references/` subtree is non-empty, but it is real soft authoring-guideline debt and should be named as such rather than waved through.
- Mode-selection ambiguity rises with mode count. The mode-selection row for the new mode must disambiguate it against the platform-health, process-fitness, and architecture-conformance modes on the **evidence axis** — which corpus oracle the run scores against — exactly as the architecture-conformance mode's own trigger block does. Without that, four observational audit modes present four near-identical trigger surfaces.
- The mode letter and the coverage-seam identifiers occupy adjacent namespaces, so a seam-identifier prefix that collides with the mode letter would make the two mutually confusable in both prose and search. The seam identifiers are canonicalized inside the capability build's design, not here; the collision is cheap to resolve while the identifiers remain untracked and dearer once the rubric ships.
- The standalone option — which would have had a cleaner single-responsibility story and an independent trigger surface — is foreclosed. Any future need for an independent decision-audit invocation surface requires revisiting this decision rather than adding one alongside.
- The mode is registered before its scoring rubric exists, because the host decision and the capability build are separate work items. The dispatcher entry therefore declares its own provisioning state and reports it rather than fabricating a scorecard; that declaration is retired when the rubric lands.

## Reversibility

**CHEAP** (confidence: **HIGH**). A mode addition is additive and revertable in a single commit: no existing mode's contract changes, no data migration occurs, and no consumer breaks. The asymmetry is worth recording explicitly — extracting the mode into a standalone skill later would be **MODERATE**, requiring a skill-directory creation, a deploy-roster entry, and package machinery, so the cheap direction is the one this decision takes and the dear direction is the one it forecloses.

## Related ADRs

- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — the skill-boundary test. The governing constraint: conjunct 3 (distinct primary role) is what forecloses the net-new alternative.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — the extend-before-create criterion. The gate this decision's recorded determination satisfies.
- [ADR-090](ADR-090-structural-path-move-mode-extend-vs-sibling.md) — the extend-versus-sibling structural precedent this criterion generalizes.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — substrate versus canonical. Why the capability build's issue body is edited only under the spike's explicit mandate and is otherwise historical record.
- [ADR-044](ADR-044-skill-output-ownership-model.md) — skill-output ownership, which the two-surface emission operates under.
- [ADR-006](ADR-006-skill-to-module-map.md) — the skill-to-module map, which places the host in the core module and therefore places this decision record in the core-module ADR directory.
