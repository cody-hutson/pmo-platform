---
title: "ADR-074 — Stage 8 consumes Stage-7 runtime evidence for behavioral-AC acceptance (does not re-execute)"
status: Accepted
date: 2026-07-03
release: 70-verification-execution-surface
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Collective Review scope-lock"
tags: [release-ops, stage-08, qa-acceptance, verification-execution-surface, runtime-suite, behavioral-ac, consume-vs-define, acceptance-altitude]
source_observations:
  - "Stage 8 acceptance was LLM-graded review of PR content only — 'No formal test execution environment' (stage-08-qa-testing.md §2), with no deliverable-exercising execution path. The runtime-execution surface (the Phase A8 runtime-suite gate + the runtime-suite selection map) had already shipped at Stage 7 in a prior release, exercising runtime-mapped deliverables and recording a test-run PASS/FAIL/SKIP outcome — but Stage 8 did not grade acceptance on it."
  - "The A8 outcome already flows to Stage 8: the Test-results field of the DT→QA Handoff Payload carries Suite · Selected-by (map row #) · Result (PASS/FAIL/SKIP) · counts · Env · Evidence · event ts. Stage 8's Phase A Entry Validation already validates the envelope this field rides in. So the carrier existed; what was missing was a Phase B rule that READS the Result and lets it drive a behavioral AC's verdict."
  - "The behavioral-AC worked example the card requires ('component renders and dismiss persists for the session') maps to the selection map's row-6 no-match today — no web/component runtime suite row exists. This is a real registry gap in the map, not a defect in the AC; it is surfaced honestly as the map's own extension path, and the worked example shows both the honest suite-skip fallback (unmapped web/component) and a mapped-domain case (hooks) where real runtime evidence is consumed."
---
<!-- reference-durability: allow-link -->
# ADR-074 — Stage 8 consumes Stage-7 runtime evidence for behavioral-AC acceptance (does not re-execute)

## Status
Proposed. Drafted at Stage 5 Solutioning for the Stage-8 verification-execution-surface card — the surface card of the 70-verification-execution-surface release (foundation → schema → surface → executor). Flips to Accepted at this release's Collective Review scope-lock (the ratification surface the release-ADR README names), consistent with how in-repo release ADRs set their own status. Recorded Proposed because that gate has not yet run. (Originating-issue provenance is carried in the `source_observations` frontmatter.)

## Context
Stage 8 QA (`release/references/pipeline/stage-08-qa-testing.md`) validates the built result against acceptance criteria — the "does this meet needs?" gate, distinct from Stage 7's "does this meet specs?". Its acceptance review was **LLM-graded evaluation of PR content only** (§2 "No formal test execution environment"; Phase B "evaluate each criterion against PR content"). There was no deliverable-exercising execution path at acceptance altitude: a behavioral acceptance criterion ("the component renders and the dismiss persists for the session") was graded by reading the source and opining, never by exercising the deliverable.

The runtime-execution surface already exists — but at Stage 7, not Stage 8. The Phase A8 runtime-suite gate exercises a runtime-mapped deliverable and records a `test-run` PASS/FAIL/SKIP outcome, keyed by the runtime-suite selection map (`release/references/standards/runtime-suite-selection-map.md`). That outcome already flows to Stage 8 in the DT→QA Handoff Payload **Test-results** field, and Stage 8's Phase A Entry Validation already validates the envelope carrying it. What was absent was a Stage-8 **Phase B rule** that reads the Result and lets it drive a behavioral AC's verdict.

The design question this ADR settles: does Stage 8 **CONSUME** the Stage-7 A8 result as acceptance evidence, or **DEFINE** its own Stage-8 execution step that re-runs a suite at acceptance altitude?

## Decision
1. **CONSUME, not define.** Stage 8 grades a behavioral/runtime AC on the Stage-7 A8 `test-run` Result carried in the Handoff Payload Test-results field. It does **not** re-run any suite. The "execution surface" at Stage 8 is *evidence consumption* of the upstream run, keeping Stage 8 at acceptance altitude and leaving execution a Stage-7 concern.
2. **Phase A validates the envelope; Phase B adds the Test-results read.** Entry Validation confirms a conformant `### Output for Stage 8` block is present and its fields (including Test-results) are extractable — a structural gate, not an acceptance judgment. The new Phase B Runtime-Evidence Acceptance rule reads the Test-results Result for the AC's mapped suite: `PASS` → the AC may be graded MET; `FAIL` → NOT MET (Blocker) → Lane 2 → QA Return to Dev Testing; `SKIP`/unmapped-domain → graded by the existing LLM-acceptance path with `runtime-evidence: none` recorded so the absence is explicit.
3. **One dispatch source of truth.** The domain→suite keying is owned by `runtime-suite-selection-map.md`, cited (not re-implemented) by Stage 8 — the same map the verification-execution executor reads. Stage 8 forks no second dispatch surface.
4. **No new Gate-8 criterion.** The FAIL→NOT-MET→Blocker effect is carried by Gate 8→9's existing "all AC checked / no unresolved Blocker" metric; a new gate-criteria-spec criterion would duplicate the contract, so none is authored (the Stage-4 matrix's "possible Gate-8 edit" resolves to a no-op).
5. **Honest no-op + introducing-release-exempt cutover.** A doc/governance/pipeline-internal release touches no runtime-mapped path (A8 emits `suite-skip`) and carries no runtime/behavioral AC, so the rule has nothing to key on and grades byte-for-byte as today. Cutover: applies to releases entering Stage 8 strictly AFTER this rule's introducing-release merge SHA (**v3.65**); the introducing release itself is exempt (reflexive-pipeline-loop discipline — it does not run its own new acceptance rule on itself; its own Stage-8 run grades against pre-change semantics).

## Alternatives Considered
| Option | Decision | Rationale |
|---|---|---|
| (a) CONSUME — read the Stage-7 A8 result and grade the AC on it | **Accepted** | Does not duplicate the Stage-7 execution; preserves the Stage-7 "meets specs" / Stage-8 "meets needs" altitude split; buildable on the narrowed scope because the carrier field and the Phase-A envelope validation already exist; composes cleanly with the executor's shared-map dispatch. |
| (b) DEFINE — a Stage-8 execution step that re-selects a suite via the map and re-runs it at acceptance altitude | Rejected | Re-implements the A8 execution harness at the wrong altitude — it duplicates the Stage-7 run and blurs the deliberate DT/QA altitude boundary. Wide blast radius (new sandbox contract at Stage 8, a Gate-8 execution criterion, event-schema touch) for no acceptance-value the consume path lacks. |
| (c) HYBRID — CONSUME by default, DEFINE a narrow fallback runner for the no-match-but-behavioral edge (e.g. web/component) | Rejected | The fallback runner buys nothing: the web/component behavioral case no-matches the selection map under *any* design (there is no web row), so a Stage-8 runner has nothing to run and lands on the same honest-fallback path — at the cost of a second load-bearing execution locus. The map gap is real and a Stage-8 runner cannot close it. |

The survivor — consume the upstream run + an honest LLM-acceptance fallback for unmapped/`suite-skip` domains — is strictly simpler and strictly sufficient: it exercises the deliverable wherever a runtime suite covers it (via the A8 run) and degrades honestly (declared method + recorded `runtime-evidence: none`) where none does, without a second execution harness.

## Consequences
### Positive
- Stage 8 gains a deliverable-exercising acceptance path for every runtime-mapped behavioral AC — for free, by consuming the A8 run — without any Stage-8 re-execution.
- Stage 8 stays at acceptance altitude; the Stage-7 "meets specs" / Stage-8 "meets needs" split is preserved rather than blurred by a second execution stage.
- One dispatch source of truth (the runtime-suite selection map), shared with the verification-execution executor — no forked second surface to reconcile.
- Doc/governance releases are unaffected: their A8 already emits `suite-skip` and they carry no runtime AC, so the rule is vacuously satisfied and the verdict is byte-unchanged.
- The web/component map gap becomes an explicit, cited honest-signal (the worked example records `runtime-evidence: none (unmapped-domain)`), not a silent hole — the "honest no-op over fabricated pass" discipline.

### Negative / cost
- A behavioral AC whose domain has no selection-map row (web/component today) has no runtime evidence and is graded honestly by the LLM-acceptance path — the deliverable-exercising path is only as broad as the map's rows. Closing the web/component gap is the map's own extension path, out of this card's scope.
- The rule adds a Phase-B branch keyed on the Test-results field; a malformed or missing Test-results field degrades to the no-evidence path (recorded), relying on Phase A's envelope validation to have caught a truly absent handoff.

## Reversibility
**MODERATE / Confidence MEDIUM.** The change is an additive Phase-B grading rule + one cross-reference + a worked example; revert = delete the Runtime-Evidence Acceptance subsection, the Inputs xref, and the worked example — no tool, no schema, no gate criterion to unwind. Whole-release rollback = revert the single squash-merge (restores the pre-change Stage-8 spec) — CHEAP at the release grain. (The card body's original EXPENSIVE tier reflected the from-scratch "give Stages 7 AND 8 an execution surface" scope; the narrowed consume-only Stage-8 scope trends MODERATE — the from-scratch execution surface shipped earlier at Stage 7 and is not re-touched here.)

## Related ADRs
- ADR-073 (cross-issue release-integration check — the same release's schema card) — sibling in the 70-verification-execution-surface bundle; its executor is the shared runner that reads the same runtime-suite selection map this ADR keys Stage-8 acceptance to (one dispatch surface, cited by both).
- ADR-072 (region-scoped AV invariant verification — the same release's foundation card) — sibling; makes the verification substrate every gate's verdict relies on structurally sound, the foundation this surface card builds on (foundation → schema → surface).
- ADR-062 (substrate-vs-canonical precedent) — cited for the canonical-edit-wins discipline: the acceptance rule is authored at its canonical governed home (`release/references/pipeline/stage-08-qa-testing.md`), and the domain→suite keying is consumed from the selection map rather than duplicated.
