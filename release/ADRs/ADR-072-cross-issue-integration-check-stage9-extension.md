---
title: "ADR-072 — Cross-issue release-integration check: Stage-9 extension over new Stage 7.5"
status: Proposed
date: 2026-07-03
release: 70-verification-execution-surface
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Collective Review scope-lock"
tags: [release-ops, pipeline-architecture, stage-09, verification-execution-surface, cross-issue-ac, ciac, release-scoped-gate, single-runner, integration-check]
source_observations:
  - "Nothing tests the PR as an integrated artifact between Stage-6 close and the Stage-9 gate: cross-issue cohesion constraints (e.g., 'issue X's text cites issue Y's anchor verbatim') live only in Stage-5 instructions / Risk Register, never as testable AC. Per-issue Stage 7/8 are structurally blind to them because their unit is the single issue."
  - "The corpus already ships a cross-issue mechanism — INT-N integration ACs (Stage-5 Phase A4.2, graded Stage-8, chain-validated Stage-9 Phase A3.5, shipped v3.52). INT-N fires on a dependency edge and grades one (this-issue × upstream × shared-surface) triple. A cohesion constraint between two issues with NO dependency edge — the motivating gap — cannot be expressed as INT-N. A distinct release-scoped layer is required, and it must not collide with INT-N."
  - "The pattern compounds with release size (1-issue release → 0 cohesion edges; 6-issue release → ~9 cohesion edges). Operator vigilance does not scale; a pipeline-structural gate does. This is the same 'structure over attention' argument that motivated the INT-N chain check."
---
<!-- reference-durability: allow-link -->
# ADR-072 — Cross-issue release-integration check: Stage-9 extension over new Stage 7.5

## Status
Proposed. Drafted at Stage 5 Solutioning for the Cross-Issue AC + release-integration-check card in the 70-verification-execution-surface release. Flips to Accepted at this release's Collective Review scope-lock (the ratification surface the release-ADR README names), consistent with how in-repo release ADRs set their own status. Recorded Proposed because that gate has not yet run. Sibling to ADR-071 (region-scoped AV verification) in the same release. (Originating-issue provenance is carried in the `source_observations` frontmatter.)

## Context
The card has two threads. **Thread 1** codifies a release-scoped **Cross-Issue Acceptance Criteria (CIAC)** section in the Stage-4 release plan — each entry a testable predicate spanning ≥2 issues with a verification method (grep / anchor-resolution / runtime-dispatch). **Thread 2** decides how the release exercises those predicates as an integrated artifact between Stage-6 close and the Stage-9 GO. This ADR records the Thread-2 architecture decision (Option A vs Option B) and the single-runner correction the Collective Review scope-lock imposed on it.

The load-bearing distinction that makes the whole card coherent: **CIAC (release-scoped, Stage-4-authored, any ≥2 issues, no dependency edge) is a distinct namespace from the shipped `INT-N` (issue-pair-scoped, Stage-5-authored, requires a dependency edge).** Both grade under the Stage-8 per-criterion verdict enum verbatim; neither introduces new verdict values. Stage 9 Phase A3.5 counts `INT-N`; the new Phase A3.6 / QC3.5 counts `CIAC-N`. They are complementary layers, not competitors: `INT-N` cannot express a cohesion constraint between two issues that lack a dependency edge (its trigger IS the edge), and that is exactly the motivating gap CIAC fills.

## Decision
1. **Thread 2 = Option A — extend Stage 9 with a release-integration check (new Phase A3.6 + QA Checkpoint QC3.5 + gate criterion G-PR10), NOT a new Stage 7.5.** The predicate "does the *merged, integrated PR* satisfy release-scoped cohesion?" is definitionally a **pre-GO gate** question (Stage 9's charter), not a per-issue test (Stage 7/8's unit is the single issue). Option A composes with the already-shipped `INT-N` chain validation at Stage 9 Phase A3.5 by adding a sibling **release-node** pass next to the existing **chain** pass — one coherent Stage-9 integration surface. Option B (a net-new `stage-07.5-integration-testing.md` shard) would fork a second integration surface at a second stage and force a corpus-wide "13-stage pipeline" → "13.5" renumber.
2. **Single-runner (M-3(a) scope-lock correction — LOCKED).** The CIAC method is executed by **exactly one runner: the release's verification-execution executor**, which runs each CIAC's declared method once at Stage 6/7 and emits the verdict as Verification-Evidence. **Stage-9 Phase A3.6 / QC3.5 / G-PR10 CONSUME the emitted verdicts read-only — they do NOT re-run the method.** This mirrors Phase A3.5's read-only posture (A3.5 reads Stage-8 verdicts; it does not re-grade). The pre-scope-lock Stage-5 draft wrote A3.6 as "the hub runs the declared method against the merged PR"; that is superseded — a second runner at the gate could diverge from the executor's result for the same predicate, so the method is evaluated in exactly one place.
3. **Evidence-freshness guard (mirrors G-PR9 baseline-currency).** A consumed CIAC verdict is valid only if emitted against the **final PR head SHA**. Before the gate reads the verdicts, the hub confirms the SHA each verdict was recorded against equals the current release-branch / PR head. If a later commit touched a CIAC-relevant file, the verdict is **stale** → the hub re-triggers the executor to re-emit against the new head SHA before reading. This is the intra-release analogue of G-PR9's staleness predicate (a GO baseline invalidated by a later mover-set).
4. **Landing sites (Option A, 0 new files):** Thread-1 schema in `stage-04-planning.md` § Cross-Issue Acceptance Criteria + `hub-spoke-bridge.md` Procedure 0 Release Planning Spoke Template (Task item 8 + Output schema) + `release-personas.md` Stage-4 card marker; Thread-2 gate in `stage-09-plan-review.md` Phase A3.6 + `release-process.md` QA Checkpoint 3.5 + `gate-criteria-spec.md` G-PR10. Per-release CIAC *instances* ride the existing release-plan surface (no new artifact), exactly as `INT-N` rides `### Output for Stage 6`.
5. **Cutover (introducing-release-exempt).** QC3.5 / Phase A3.6 / G-PR10 apply to releases entering Stage 9 strictly AFTER this ADR's introducing-release merge SHA (**v3.65**); the introducing release itself is exempt (reflexive-pipeline-loop discipline — it cannot fire its own new gate). v3.65 authors one dog-food CIAC in its own plan (the predicate asserting the verification-execution executor consumes the CIAC schema and the runtime-suite map rather than re-implementing either) as a demonstration but grades it under pre-QC3.5 discipline.

## Alternatives Considered
| Option | Decision | Rationale |
|---|---|---|
| **A — Stage-9 extension (Phase A3.6 + QC3.5 + G-PR10)** | **Chosen** | The predicate is a pre-GO gate question; composes with the shipped Phase A3.5 `INT-N` chain pass (one integration surface); low blast radius (5 in-place edits, 0 new files); the operator-vigilance-doesn't-scale goal is best served by a gate the operator already stops at. |
| B — New Stage 7.5 "Integration Testing" | Rejected | Stages 7/8 are per-issue; a release-scoped integrated-artifact test is a poor fit for a stage whose unit is the issue. Forks a second integration surface (INT-N at A3.5, CIAC at 7.5). Corpus-wide blast radius — every "13-stage pipeline" count becomes "13.5" or forces a renumber; new applicability-matrix row, gate block, event-log events, hub-spoke sequencing. EXPENSIVE to un-ship. |
| C — Extend Stage 8 per-issue QA to grade CIACs | Rejected early | Stage 8 is per-issue; a release-scoped predicate has no single issue to attach to — CIACs would be graded N times or arbitrarily assigned to one issue. Category error. |
| D — New standalone gate stage between 8 and 9 | Rejected early | Identical cost to B with none of B's "dedicated test phase" framing benefit — strictly dominated by B. |
| Hub runs the CIAC method at the gate (pre-scope-lock A3.6 draft) | Superseded by M-3(a) | A second runner at Stage 9 re-running the same predicate the executor already ran risks divergence for the same CIAC. Single-runner discipline: the executor runs once and emits; the gate reads read-only. |

The survivor — a Stage-9 sibling phase that reads the executor's emitted CIAC verdicts, guarded by an evidence-freshness check — is the minimum mechanism that gates release-scoped cross-issue cohesion without forking a second integration surface or a second runner.

## Consequences
### Positive
- Cross-issue cohesion (any ≥2 issues, no dependency edge required) becomes a **gated pre-GO input** rather than an operator-vigilance task that does not scale with release size.
- One coherent Stage-9 integration surface: Phase A3.5 (INT-N chains) + Phase A3.6 (CIAC release-nodes), same verdict enum, same fold-in to the Release Readiness Scan + Decision Briefing.
- Single-runner + freshness guard keep the predicate evaluated in exactly one place against exactly the shipped bits — no gate-vs-executor divergence, no stale-evidence false PASS.
- Backward-compatible: a release with zero CIACs emits N/A and Stage-9 behavior is byte-unchanged (empty-CIAC degeneracy, mirroring A3.5's single-node degeneracy).
- 0 new pipeline stages / files; whole-release `git revert` of the squash-merge restores every edited file.

### Negative / cost
- CIAC verdict trustworthiness depends on the verification-execution executor emitting against the final head SHA; the freshness guard adds a SHA-comparison + conditional re-trigger step at the gate.
- Authors must declare CIAC entries at Stage 4 (a cheap, deliberate discipline that surfaces cross-issue intent the release would otherwise carry implicitly).
- Until the executor ships, CIAC's runtime-method path is dormant; the static grep/anchor path is complete on its own (a human/LLM reader can grade a declared CIAC at Stage 9 even pre-executor).

## Reversibility
**MODERATE / Confidence HIGH.** Option A is 5 in-place governance/pipeline edits + one gate row + one ADR — a whole-release revert of the squash-merge restores all of them. This is materially cheaper to un-ship than Option B (a shipped pipeline stage is EXPENSIVE to reverse — corpus references, operator muscle memory, event-log history). The empty-CIAC degeneracy guarantee is the regression anchor: a zero-CIAC release runs QC3.5 as a no-op with Stage-9 behavior byte-unchanged, so the additive gate cannot regress existing releases.

## Related ADRs
- ADR-071 (region-scoped AV invariant verification) — sibling in the same release (70-verification-execution-surface). Both harden the verification-execution surface: ADR-071 makes the QC4-05 post-deploy verdict sound; ADR-072 makes cross-issue cohesion a gated pre-GO input. ADR-072's G-PR10 is a `recommend`-tier judgment gate; ADR-071's QC4-05 mechanism is `structural`.
- ADR-024 (cross-release impact model — GO baseline-currency) — precedent for the evidence-freshness guard: G-PR9's baseline-currency staleness predicate (a GO baseline invalidated by a later mover-set) is the model this ADR's intra-release freshness guard mirrors, applied to the commit that post-dates an emitted CIAC verdict.
- ADR-062 (substrate-vs-canonical precedent) — cited for the canonical-edit-wins discipline: the QA Checkpoint Framework gains QC3.5 at its canonical governed home (`release/governance/release-process.md`), and the checkpoint-count cascade sweep updates every downstream count reference rather than leaving stale mentions.
