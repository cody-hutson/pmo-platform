---
title: "ADR-207 — A verification row's grading route is declared in its method cell; a Predicate class column is a reader annotation the executor does not read"
status: Accepted (rendered by the operator at the Stage-5 D-6180 gate as decision D17; this file records it)
date: 2026-09-25
release: verifier-grades-what-plans-declare
deciders: "Workspace owner (operator), rendering the Stage-5 D-6180 gate as decision D17 against the Stage-5 design and its Phase A6.5 adversarial review, whose counter-design and text fixes the operator adopted with the gate + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + the Stage 6 Engineering spoke that recorded it"
tags: [architecture, release-pipeline, verify-release-plan, declared-route, method-cell, declared-deferred, predicate-class, reader-annotation, remove-not-wire, residual-signal, ADR-168-retained]
supersedes: none
source_observations:
  - "At the Stage-5 pin the per-issue parser indexed 1,058 rows over 215 plans: 1,056 classifiable plus 2 parity-error rows. Feeding each row's Predicate class cell to the existing hint arm, as coded, re-classified 49 of the 1,056: 28 unclassified -> a family, and 21 between families (12 per-issue -> runtime-suite, 3 per-issue -> regression, 2 regression -> runtime-suite, and 1 each sync -> regression, sync -> runtime-suite, per-issue -> integration, integration -> runtime-suite). Measured by the Stage-5 design with a port validated against the live executor and a live wired variant, reproduced by the Phase A6.5 review with a third extractor, and re-measured at Stage 6 by evaluating the executor's own parser and classifier with and without the class cell: the same figures at the pin, and again on the mainline at Stage 6, where 217 plans index 1,080 rows and the class-column population is unchanged."
  - "Hint-first wiring, measured on a live wired variant at the Stage-5 pin: 6 rows routed to the deploy --check oracle, which tests none of their claims; 1 fabricated FAIL, a method saying 'FAIL on the mutant' read by the runtime-suite FAIL-substring arm; and 4 rows that stop running their own probe. Of the 12 per-issue -> runtime-suite moves, 9 graded SKIP at the pin and 3 were FAILs from a bare-verb extraction."
  - "The column: 11 plans author it in an indexed table (133 rows, 17 header blocks), in four incompatible conventions: 93 executor-family tokens, 35 G1-05a AC-predicate classes, 3 whole predicate statements, 1 declared-deferred string, and 1 other."
  - "What removal leaves unconsumed (the card's fourth criterion, REINTERPRET-WITH-RATIONALE: a bare 'no consumer' is not the test, so each cell is classified against what its author declared). Of the 133 class cells: 73 are redundant with an emitted field (63 agree with the family the method already selects; 10 sit on a method already declared-deferred); 16 contradict the probe their method runs or can never route (5 name a family other than the one whose command the method runs, 2 of them runnable probes and 3 bare verbs; 11 carry no token any hint arm recognises); 16 are overridden by the keyword fallback on every branch but class-first (12 routed to per-issue, 2 to sync, 1 to regression, 1 to integration); and 28, on 5 plans, sit on a method cell that resolves no family, so the class cell is the only machine-legible statement of how the author meant the row graded. This decision leaves those 28 unconsumed, accepted: the plans are immutable, and the declared-deferred form in the method cell serves every future row. Split measured at Stage 6 by the executor's own parser and classifier."
  - "The 28 method-silent declared rows, by plan file (under release/releases/plans/, immutable once merged) and line, with each class cell and the family the hint arm would have given it — v3.65_RELEASE_PLAN.md: line 108 (behavioral/domain, runtime-suite)."
  - "v4/v4.02_RELEASE_PLAN.md: lines 160, 162, 163, 164 (runtime-suite, runtime-suite); 166 (behavioral, runtime-suite); 167 (regression, regression); 181 (runtime-suite, runtime-suite); 182 and 189 (regression, regression); 196 and 203 (content, per-issue); 212 (runtime-suite, runtime-suite)."
  - "v4/v4.09_RELEASE_PLAN.md: lines 143, 144, 145 (file-path+state, per-issue); 146 (behavioral/domain, runtime-suite)."
  - "v4/v4.19_RELEASE_PLAN.md: lines 313, 318, 323, 329, 330 (file-path+state, per-issue); 316 and 328 (behavioral/domain, runtime-suite)."
  - "v4/v4.35_RELEASE_PLAN.md: lines 277, 278, 285 (file-state, per-issue); 286 (runtime-suite, runtime-suite). All five plans are byte-identical between the Stage-5 pin and the mainline at Stage 6, so these coordinates hold."
  - "The hint was never live: the only call site passed an empty class from the executor's first commit on. At the pin the declared-deferred form in the method cell reached a named SKIP and carried 34 rows on 8 plans. The runtime-suite subtype tokens carried 0 corpus rows, and they route to FAIL whenever the method carries an uppercase FAIL anywhere: 12 of 1,056 method cells did, 7 of them prose rows (measured by the Phase A6.5 review)."
  - "Removal is behaviour-neutral: at the Stage-5 pin a variant built from the specified text gave byte-identical output and exit codes on 215 of 215 plans and on every suite fixture, and identical suite assertion lines; 17 of 87 Verification-Plan header blocks name a predicate column, all 17 also name a method column, and 0 depend on the predicate word alone. Re-measured at Stage 6 on the shipped removal, in a stub root with the deploy check stubbed: byte-identical JSON output and exit codes, before and after, on 217 of 217 plans and 74 of 74 test-fixture markdown files."
  - "The step-0 residual, measured at the pin by the Phase A6.5 review: a probe whose own search pattern carries 'deferred to #' or 'verification deferred' graded SKIP declared-deferred although its pattern had hits in the target, and the plan exited 0; 6 of the 34 corpus deferred rows write the bracket form inside backticks, and 0 of the 34 carry a runnable probe."
---

# ADR-207 — A verification row's grading route is declared in its method cell; a Predicate class column is a reader annotation the executor does not read

## Status

**Accepted.** Rendered by the operator at the Stage-5 D-6180 gate as decision D17, option A-prime, which adopted the Phase A6.5 review's counter-design and its text fixes. Recorded at Stage 6 Engineering for the `verifier-grades-what-plans-declare` release, in the slice that removes the path.

**Numbering provenance.** Claimed as **207** against an anchor of **206** on the mainline, read from the repository's own ADR-numbering tool at authoring rather than computed as one past the highest number visible on any branch. The number binds at the Stage-12 claim, and in-release prose cites this record by its slug token.

## Context

The plan verifier's classifier accepted a predicate-class hint as its first argument. Its only caller passed an empty string from the executor's first commit on, so the `Predicate class` column that plans author never shaped a verdict. Two earlier assessments declined the card, each correctly within its own scope, and together they left the seam with no owner.

The decision was whether to wire the column into routing, or to remove the path that pretended to read it. The measurements behind it are in `source_observations`.

## Decision Drivers

- **Measured effect of wiring the arm as coded**, as of the D17 decision: it moved 49 of 1,056 classifiable rows, routed 6 rows to an oracle that tested none of their claims, fabricated 1 FAIL, and stopped 4 rows from running their own probe.
- **Removal is behaviour-neutral**, as of the D17 decision: output and exit codes byte-identical on 215 of 215 plans and on every suite fixture.
- **The column had no single vocabulary**, as of the D17 decision: its 133 cells used four incompatible ones, so wiring it would first have required canonicalizing one.
- **The executor's own doctrine:** a declaration never runs ahead of an executable row.
- **The declared route already existed in the method cell**, as of the D17 decision: the declared-deferred form reached a named SKIP and carried 34 rows on 8 plans, while the runtime-suite subtype tokens carried none and could turn prose into a FAIL.

## Decision

1. A verification row's grading route is declared in its Verification method cell alone.
   - A row the verifier is not the runner for is declared in one form: `[DEFERRED — <reason>]`, or "declared, verification deferred to <runner>".
   - `suite-skip` and `suite-fail` are runtime-suite subtype tokens, for rows that are actually about a suite run. They are not a general declaration: an uppercase "FAIL" anywhere in the method routes the subtype to FAIL.
2. The class-hint path is removed.
   - The classifier takes the method as its only argument, and the parser resolves no class value.
   - The in-source note and the help text that described the dormant seam are retired.
3. ADR-168 is retained. A header cell naming a predicate still counts as a schema word, both for header detection and for the unindexable-table latch. The column's data cells are not read.
4. A `Predicate class` column stays permitted, as a reader annotation. The Stage-4 table contract says the executor reads no cell but the method cell to decide how a row is graded, and no longer names the column as the example of a permitted extra column.
5. No `SCHEMA_VERSION` bump is owed: no field, family value or verdict value is added, and no emitted byte changes. A bump would have been owed only if a class were emitted.

## Alternatives Considered

- **Wire the column as a residual signal.** The class would speak only where the method cell resolves nothing, through a closed vocabulary, so the method-silent rows in `source_observations` would move from ERROR to a named SKIP and an author who fills the column would get a forward route. It follows ADR-173's residual-signal kernel and was the strongest alternative. Not chosen: it keeps two declaration channels for one fact, its vocabulary would first have to be canonicalized from cells written in four incompatible conventions, and what it buys over removal is a re-grade of history plus a route for an authoring habit the method cell already serves.
- **Wire class-first, with probe precedence.** Rejected, as of the D17 decision: it would have moved 43 rows, and it overrides the executor's own can't-run finding with an author's class on 11 rows.
- **Wire the arm as coded.** Rejected: it routes rows to an oracle that tests none of their claims, fabricates a FAIL, and lets a class displace a probe, against the executor's "never ahead of an executable row" doctrine.
- **Keep the declared test-run outcome as a second general declaration form.** This was the Stage-5 design's own framing, before the Phase A6.5 review. Rejected: the runtime-suite subtype arm routes to FAIL on an uppercase FAIL anywhere in the method, so a row declared as not this runner's job could fabricate a failure from its prose, and no corpus row used the route.
- **Remove the header word as well, superseding ADR-168.** Rejected: it re-opens a silent drop for no measured gain.
- **A new in-method class grammar.** Rejected: a second declaration grammar beside the declared-deferred form that already works.
- **Status quo.** Rejected by the card's own measurable outcome.

## Consequences

- **Positive:**
  - One place declares a row's route, and no verdict changes.
  - A dormant plan-authored downgrade channel is gone.
  - The help text and the table contract stop promising behaviour that does not exist.
- **Negative:**
  - The method-silent declared rows on merged plans, listed in `source_observations`, carry author-declared grading intent that this decision leaves permanently unconsumed. That is accepted: the plans are immutable, and the declared-deferred form in the method cell serves every future row. Under D26 they grade by their method cell — a named SKIP when the cell carries no command — rather than ERROR, and the list gives a later residual wire its target set.
  - Authors who fill the column get no effect, and the table contract now tells them so.
  - The three bug RCAs named wiring as their fix locus. This decision honours their principle — read the declared route, never infer it — through the method cell instead.
- **Residual — the deferred-phrase matcher.** Step 0 reads the whole method cell, so a deferred phrase inside a backticked probe is read as a declaration and displaces the probe: the row grades a declared-deferred SKIP and its command never runs. The operator placed the fix in this release's keyword-precedence slice (D30), which records it in this file as Decision 6; the Collective Review made the shell-operator test that fix relies on one shared quote-aware command predicate (D38), landing in the same slice.

## Reversibility

**CHEAP.** Reverting restores a dormant arm and moves no row. Wiring the column later as a residual signal remains open, and its target rows are listed in `source_observations`.

## Related ADRs

- ADR-075 — the plan-verification executor's shared contract. Its family registry and output contract are unchanged, and its fifth decision's verdict enum and `SCHEMA_VERSION` are not bumped here.
- ADR-168 — a verification claim is a named schema column. Retained: the predicate header word keeps its role in header detection and in the unindexable-table latch.
- ADR-173 — a declared kind is a residual feature signal. The kernel the residual-wire alternative followed.
- ADR-062 — the substrate-versus-canonical precedent. The card's issue-body figures stay historical record.
- ADR-181 — ADR citations bind at the claim, not at authorship. In-release prose cites this record by its slug token.

## References

- #6180 — the card whose wire-or-remove decision this record carries.
- #7641 — the ADR issue holding this record's decision set.
- #7590 — the Stage-5 design sub-task, carrying the D17 decision record.
- #7640 — the design's Phase A6.5 adversarial review, whose counter-design and text fixes D17 adopted.
- #7610 — the per-issue residual design sub-task, carrying the D26 decision record.
- #7547 — the Stage-4 planning sub-task: the plan that registered the decision and measured both branches, and the Collective Review record.
- #6893, #6837, #6854 and #6685 — the four cards that inherit the rendered branch.
