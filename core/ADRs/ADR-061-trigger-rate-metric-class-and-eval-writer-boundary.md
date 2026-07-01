<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: trigger-rate is a new metric class in the shared calibration surface, and skill-compliance-auditor is NEW (not a mode on eval-writer)
status: Accepted
date: 2026-06-30
release: 07-INFRA-hygiene-measurement
deciders: "[operator]"
tags: [skill-compliance-auditor, trigger-rate, metric-class, calibration-data, namespace-reservation, eval-writer-boundary, skill-boundary-test, adr-019, reversibility-moderate]
---

# ADR-061 — `trigger-rate` metric class + the eval-writer NEW-vs-EXTEND boundary

## Status

**Accepted** — flipped from Proposed at the Stage 9 review (GO). Binds atomically at Stage 12.

Number **061** — the next gap-free slot in the global ADR sequence (verified free across both `core/ADRs/` and `release/ADRs/` at Engineering time; the sequence spans both directories under one numbering, enforced by `check-adr-numbers.py`). Authored at Stage 6 per the Stage-5 recommendation (Stage 5 recommends the ADR; Engineering authors it).

## Context

The `skill-compliance-auditor` skill (built this release) measures **skill trigger-compliance** — whether the right skill fires for the requests it should serve. It is the coverage gap upstream of the three existing measurement surfaces: `pmo-qa-auditor` measures output quality, `pmo-skill-editor` Mode D measures structure, and `core/schemas/gate-evaluation-spec.md` measures gate-decision judgment. Nothing measured *firing*.

Two decisions on this skill clear the decision-discipline ADR threshold because they are **cross-cutting** (they bind a contract read by other skills) and **non-obvious** (a future author could reasonably decide either way and must not be left to re-litigate):

1. **The results surface.** The skill reports a compliance rate that must trend over time. The platform already has a shared calibration-data surface (`gate-evaluation-spec.md`'s "Data source," resolved via the `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` operator token to `calibration-data.md`). Does the skill fork its own results store, or extend the shared one — and if it extends it, under what metric-class namespace, given the shared surface is read by other consumers and a collision would silently corrupt two metrics?

2. **The eval-writer boundary.** The skill's trigger-measurement purpose sits close to `eval-writer`'s trigger-optimization eval surface. Is `skill-compliance-auditor` a genuinely NEW skill, or should it be a mode on `eval-writer`? The boundary is close enough that a future author could merge the two by accident; the answer must be recorded.

A build-time path caveat also had to settle: the Stage-5 spec named the results surface as `core/evals/results/calibration-data.md`, but the evals dir moved in the corpus restructure — the file is operator-instance, referenced via the `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` token, not a tracked in-repo path.

## Decision

**`trigger-rate` is a new metric class in the shared calibration-data surface (namespace reserved here); `skill-compliance-auditor` is a NEW skill, not a mode on `eval-writer`, established by the 3-conjunct skill-boundary test.**

1. **Extend the shared surface — do not fork; reserve the `trigger-rate` namespace here.** The skill appends its compliance rows to the existing shared calibration-data surface at `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md` (the operator-token path the `gate-evaluation-spec.md` framework already references — not the stale `core/evals/results/` path), under a **new metric class named `trigger-rate`**. Forking a parallel results store is rejected (duplicate-source-discipline: two calibration files, one concept). The class name `trigger-rate` is **reserved in this ADR** so it is checked against the `gate-evaluation-spec.md` metric classes (which measure gate-decision judgment — a free namespace) and against any future `eval-writer` enhancement; a run writes only under the reserved class, additively, never rewriting another consumer's rows. The row schema lives in the skill's `references/scenario-and-calibration-schema.md §3`.

2. **`skill-compliance-auditor` is NEW — the 3-conjunct skill-boundary test (ADR-019) holds on all three conjuncts.** A skill is NEW (not a mode on an adjacent skill) when it has a **distinct trigger surface AND a distinct write-scope AND a distinct primary role**. Against `eval-writer`:

   | Conjunct | `eval-writer` | `skill-compliance-auditor` | Distinct? |
   |---|---|---|---|
   | Trigger surface | "write evals", "audit evals", "calibrate a judge", "build a rubric" | "measure skill trigger-rate", "does the right skill fire", "is this description drifting" | **Yes** |
   | Write-scope | eval suites (characterizations, judge prompts, rubrics, taxonomies) | calibration results (the `trigger-rate` rows) | **Yes** |
   | Primary role | **author** an eval suite | **measure** firing behavior and report compliance | **Yes** |

   Distinct on all three → **NEW**. A single-conjunct overlap (both touch trigger-optimization) does not collapse the boundary; the test requires distinctness on all three, and all three hold. `pmo-skill-refiner` composes the new skill as a post-creation calibration pass (it invokes the skill; it does not absorb it) — an ADR-019-clean invocation relationship.

## Alternatives considered

- **Fork a parallel results store for trigger-rate** — rejected: duplicates the shared calibration contract (two files, one concept), violating duplicate-source-discipline, and fragments the calibration surface that `gate-evaluation-spec.md` and future measurement skills read as one. Extending under a reserved class keeps one surface.
- **Make it a mode on `eval-writer` (EXTEND, not NEW)** — rejected: it fails the skill-boundary test on all three conjuncts (distinct trigger surface, write-scope, and primary role). Bolting a *measurement/reporting* mode onto an *authoring* skill would blur `eval-writer`'s role (author vs. measure) and its write-scope (eval files vs. calibration results); the two would be one edit away from silently merging. The proximity is exactly why the boundary must be *recorded*, not why it should be *erased*.
- **Leave the metric-class name unreserved (pick it inline at write time)** — rejected: the shared surface is read by other consumers; an unreserved, inline-chosen class name is the namespace-collision failure mode the skill documents (HAND) — a colliding class silently corrupts two metrics far from the write site. Reserving the name in an ADR is the forcing function that makes the namespace a checked boundary.
- **Register against the stale `core/evals/results/` path named in the spec** — rejected: that path is stale (the evals dir moved in the restructure); the file is operator-instance and is correctly referenced via the `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` token, the same one the canonical `gate-evaluation-spec.md` schema uses. Registering against the tracked path would break on any operator instance.

## Consequences

- `skill-compliance-auditor` ships as a NEW `core/` measurement function-skill, registered on the three roster surfaces (deploy.sh `CORE_SKILLS`, OPERATIONS.md mode-selection tier, registry.md CI row) — sibling to `context-budget-auditor` / `eval-writer` / `pmo-qa-auditor`.
- The `trigger-rate` metric class is reserved in the shared calibration-data surface; other consumers (`gate-evaluation-spec.md`, a future `eval-writer` enhancement) must treat that name as taken. A namespace re-draw after adoption is a multi-consumer change (see Reversibility).
- The eval-writer boundary is recorded, so a future author extending either skill has the NEW-vs-EXTEND rationale on record and does not re-litigate or accidentally merge the two surfaces.
- The routing-beyond-Jaccard slice (shipped SPEC-ONLY this release) shares the LLM-judge seam with this skill's competing-scenario judge — a documented reuse seam if that routing check is later implemented alongside eval-infra.

## Reversibility

**MODERATE / Confidence HIGH.** The skill scaffold and its registration are CHEAP to revert (a directory delete + three registration-row reverts, all git-tracked, all in the single release PR). The **metric-class addition is MODERATE**: once other consumers of `calibration-data.md` read the `trigger-rate` class, a namespace change re-casts the shared contract and requires a coordinated update across consumers — which is precisely why the name is fixed in this ADR rather than left implicit. No live-data migration occurs at authoring time (the calibration surface gains a new class; existing classes are untouched). Confidence HIGH that both decisions are correct — extend-not-fork is forced by duplicate-source-discipline, and NEW-not-EXTEND is forced by the 3-conjunct skill-boundary test (all three conjuncts distinct), not by preference. Tightening the OPEN namespace later (adding recognized classes) is additive; the load-bearing choice was reserving the name up front.

## Related ADRs

- **ADR-019** (compose-not-absorb; the skill-boundary test) — supplies the 3-conjunct NEW-vs-EXTEND test this ADR applies to the `eval-writer` boundary; the invocation-not-absorption rule that keeps `pmo-skill-refiner`'s composition clean.
- **ADR-038** (registry as CMDB) — the CI-row registration surface the new skill is catalogued in; one catalog, typed routing view.
- **ADR-04** (canary fixture-scope) — the source-only-canary exclusion the roster-note reconcile preserves when the CI count moves.

## References

- Stage-5 solution spec recommending this ADR: sub-task #2686 (the #17 solution section).
- Engineering slice authoring this ADR: sub-task #2687 (Stage 6 Wave C).
