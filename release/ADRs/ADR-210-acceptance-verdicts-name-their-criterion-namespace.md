---
title: "ADR-210 — An acceptance verdict names the criterion list its ordinal counts in; the issue body is the list of record"
status: Accepted (rendered by the operator at the Stage-5 D-7494a gate as decision D35, with the D-7494b gate as D36 and the Collective Review's reading of the binder's outcomes as D37; this file records them)
date: 2026-09-26
release: verifier-grades-what-plans-declare
deciders: "Workspace owner (operator), rendering the Stage-5 D-7494a and D-7494b gates as decisions D35 and D36 against the Stage-5 design and its Phase A6.5 adversarial review, whose fixes the operator adopted with the gates, and the Collective Review scope-lock as decision D37 (the binder's outcome reading and its reason split) + the Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + the Stage 6 Engineering spoke that recorded them"
tags: [architecture, release-pipeline, acceptance-criteria, criterion-namespace, ac-binding, reference-form, heading-vocabulary, stage-7, stage-8, reversibility-cheap]
supersedes: none
source_observations:
  - "The collision is witnessed, not hypothesised. On one card a targeted review discharged the design list's AC-6 and the discharge was reported upward as the card's AC-6, which in the issue body is a different criterion; the next stage's brief had already inherited it before it was caught. Within this release, the Stage-5 designs define INT-1 as a different criterion in 7 of 8 designs, and 5 designs label fixture rows with AC- ordinals past their card's criterion count (the Stage-5 design's P11, reproduced by its review's Q13)."
  - "At the Stage-5 pin, of 6,842 issue bodies, 1,451 carried a heading starting Acceptance Criteria (390 open), 148 a Completion condition (verifiable) heading (10 open, all H2), 0 both, and 74 a Cross-Issue Acceptance Criteria heading. The binder read the first form only. Reading both forms at any level changed the reading of 0 bodies and made 148 more readable; the checkbox-dominant item rule then changed 0 more and made 103 more readable (29 open). A literal reading of the contract's H2 rule would have missed 1,028 of the 1,599 criteria-bearing bodies. Measured by the Stage-5 design (its P1, P2 and P9) and reproduced by its review over 6,846 bodies (Q1, Q2)."
  - "A P2-literal item rule (task-list lines plus plain bullets) changed the reading of 6 live bodies and turned one plan's BOUND into a false BASELINE-DRIFT, 5 criteria read as 7, because declined and superseded annotations are written as plain bullets beside the task-list lines (the design's P2, the review's Q3)."
  - "The review measured three shapes on which the amended contract text and the unanchored reader disagreed — a nested task-list line, a second vocabulary heading directly after the block, and ordered criteria with a nested task-list sub-item — each on 0 of 6,846 bodies (its Q6), so anchoring the reader to the contract changes no live reading."
  - "The first MAP design put the declared mapping and the issue list in one hand-built snapshot, so the declaration Stage 8 consumes (the Stage-7 AC map's Maps-to cell) was never an input and the issue list could not come through the binder's own reader (the review's FM-1). The rendered form separates them: --design-file carries the declaration, and --fetch or --criteria-file the issue list."
  - "Measured at Stage 6 against the parent binder: every line of every plan's --ordinals-only run differs only by its appended ns: field (218 of 218 plans, equal exit codes), and so does every line of this release's own --fetch run (65 of 65 lines). The binder's self-test reads 73 cases, and 16 single-site mutants of the new rules are each killed by the arm written for it."
---

# ADR-210 — An acceptance verdict names the criterion list its ordinal counts in; the issue body is the list of record

## Status

**Accepted.** Rendered by the operator at the Stage-5 D-7494a gate as decision D35 (option A, with the Phase A6.5 review's fixes PR-1, FM-1, FM-2 and FM-4) and at the D-7494b gate as decision D36 (option B1, with the in-release amendment of the acceptance-assertion contract and the checkbox-dominant item rule, and the review's FM-3). The Collective Review then adopted the binder's outcome reading and its split of a withheld verdict by cause, with exit codes unchanged (D37). Recorded at Stage 6 Engineering for the `verifier-grades-what-plans-declare` release, in the slice that lands the change.

**Numbering provenance.** Claimed as **210** against an anchor of **206** on the mainline, read from the repository's own ADR-numbering tool at authoring, with **207**, **208** and **209** already held on this release's branch by {{ADR:a-rows-grading-route-is-declared-in-its-method-cell}}, {{ADR:a-method-the-verifier-cannot-run-is-reported-unrunnable}} and {{ADR:runtime-suite-selection-one-glob-grammar}}. The number binds at the Stage-12 claim, and in-release prose cites this record by its slug token.

## Context

Three lists number a card's acceptance criteria with the same `AC-N` form, each in its own order: the issue body, a Stage-5 design comment that restates or refines them, and the release plan's per-issue verification rows. No payload that carried a verdict across a stage boundary said which list its ordinal counted in, so an `AC-6` graded against one list was read as another list's `AC-6` — and each verdict read correct inside its own frame. The plan-to-issue binder checked plan rows against the issue's criteria, but nothing checked a design-to-issue mapping, and nothing let a reader tell two identically-labelled verdicts apart without re-deriving them.

The binder's criteria reader had a second, smaller defect. It recognised one of the two headings the acceptance-assertion contract names, so a card headed `Completion condition (verifiable)` read "no criteria oracle" rather than a binding, and it read only task-list items, so a card whose criteria are an ordered list withheld too. The contract itself said its headings were H2, against a corpus whose issue forms render H3. The measurements behind each point are in `source_observations`.

## Decision Drivers

- **One source is already named.** Stage 8's primary QA source, the acceptance-assertion contract's source-block and identifier rules, the plan's row-label contract, the binder's oracle and the AC-drift protocol all name the issue body.
- **The Stage-8 matrix's column set is closed.** It is rendered exactly, and a column costs two skill edits and a new machine-block version.
- **Declare, then verify.** The binder's plan limb keeps the declaration (the committed plan) apart from the evidence (the issue body). A derived mapping is silent when it is wrong.
- **One contract downstream.** The CIAC authoring constraint needs one reference form for issue, design and plan criteria.
- **Monotonic reach**, as of the D36 decision: widening the reader to the contract's vocabulary and item rule changed the reading of no body read before.

## Decision

1. **A criterion is identified by (namespace, issue, label).** The issue body is the namespace of record for `AC-` ordinals; `INT-` labels count a design's integration list; a plan's `AC-` row counts the plan and claims the issue ordinal it binds to. The namespaces, the reference forms and the `ns:` grammar are defined once, in the Stage-8 QA spec's criterion-namespace section, which the other surfaces cite.
2. **Name the list where it varies; declare it where it is fixed.** Each row of the Stage-7 AC map carries `Namespace` and `Maps-to`. The two payloads Stage 8 produces — the acceptance matrix with its machine block, and the QA-return Failed-AC table — are fixed by identifier class, so each declares the mapping once, keyed by class, as `ns:AC=issue,INT=design`. No per-row column is added, and the matrix stays at its `v1` grammar.
3. **The reference form.** `#N AC-k` is an issue criterion: the unqualified form is the issue qualification. `design #N AC-k` and `design #N INT-k` are design criteria. `plan #N AC-k` is a plan row, or an executor verdict on one, and it may be written unqualified only where the binder reads that issue BOUND at the cited head. This is the contract offered to the CIAC authoring constraint.
4. **The binder resolves, and says what it resolved.** `check-ac-binding.py` ends every emitted line in an `ns:` field — `ns:plan`, `ns:plan>issue` or `ns:design>issue` — and its VERDICT line lists the resolutions that ran. A design mapping is checked by a design limb that runs only on a supplied snapshot: `--design-file` carries each design entry under its own label with the issue ordinal it declares, and the issue list it is checked against comes through the binder's own reader (`--fetch` or `--criteria-file`), never from the design file. A mis-declared target reads UNBOUND; an undeclared or out-of-range one is an ordinal gap; a snapshot key the plan does not grade is named, not dropped. `ns:` has one grammar on every surface that writes it: a term is a namespace, a resolution (`plan>issue`), or a class declaration (`AC=issue`).
5. **The reader and the contract are one reader.** The binder reads the acceptance-assertion contract's vocabulary, and the contract states what the reader does. Its parse rule P1 names both headings at any level, matched from the start of the heading text, with the next heading of any level closing the block; its P2 names the checkbox-dominant item rule — task-list lines when any are present, otherwise top-level ordered items, otherwise plain bullets — with a nested item as detail of its parent. P1 and P2 are amended in the same release as the binder.
6. **A withheld verdict names its cause** (D37). `NOT-EVALUATED (oracle-unavailable)` — nothing was read for the issue — reads as can't run here; `NOT-EVALUATED (no-criteria-section)` — the body was read and holds no criteria — reads as could not read. Both keep the phrase "no criteria oracle". Every binder outcome reads in the release's outcome partition ({{ADR:a-method-the-verifier-cannot-run-is-reported-unrunnable}}): BOUND and WEAK-ORACLE pass; UNBOUND, ORDINAL-GAP and BASELINE-DRIFT fail; OUT-OF-SCOPE is a named SKIP; UNPARSEABLE could not read. The exit codes are unchanged.
7. **No verdict value is added**, and the change contributes nothing to the plan executor's schema version.

## Alternatives Considered

- **The binder derives the design-to-issue mapping by term overlap** (the design's option B). Not chosen: a wrong derived mapping is silent, which is the failure the card exists to remove, and no parseable corpus of design lists existed to calibrate it.
- **A qualified label grammar everywhere** (`issue:#N/AC-4`). Rejected: it breaks the plan's row-label contract across every plan, and forces a second executor-contract change beside the release's single one.
- **Canonicalize at the producer** (every `AC-` that crosses a boundary is an issue ordinal). Rejected: it cannot carry the mapping a divergent design needs.
- **Content-hash identity.** Rejected: criteria are amended in place at Stage 4, so every amendment would re-key the criterion and orphan its verdicts.
- **A Stage-5 rule that designs never renumber.** Not chosen on its own: it cannot reach existing designs. With a fixed-grammar criterion map in Stage-5 output, the review's full counter-design, it is a follow-up.
- **A per-row `Namespace` column on the Stage-8 matrix** (sub-choice a-i as a column). Not chosen: two skill edits and a machine-block `v2` to carry a value fixed by identifier class.
- **Delegate the heading read to the bundle parser's section extractor.** Not chosen: it lost criteria on bodies the chosen reader reads, and shares only the heading half.
- **A shared criteria-section module for every reader.** Not chosen in this release: it reaches readers outside the change; one reader for the four criteria grammars is a follow-up.
- **An open heading vocabulary** (any heading containing "criteria"). Rejected: it fails the named control, `Cross-Issue Acceptance Criteria`.
- **Derive the vocabulary from the issue-form templates.** Rejected: no template emits `Completion condition (verifiable)`, which the contract and the task and spike bodies carry.
- **Route the contract's amendment to a follow-up** (sub-choice b-ii). Not chosen: the binder and the contract would read one vocabulary two ways.
- **The contract's literal item rule** (task-list lines plus plain bullets). Rejected: a measured regression — a false BASELINE-DRIFT on a plan that was bound.
- **Home the definition in the stage I/O contracts schema** (the review's CD-2). Not taken: D35 places it in Stage 8, the stage whose primary QA source is the issue body.

## Consequences

- **Positive:**
  - Every acceptance verdict can be traced to the criterion it grades, in the list it came from.
  - A mis-declared design-to-issue mapping reads UNBOUND instead of passing silently, and the Stage-7 AC map's design rows quote the check that verified them.
  - The CIAC authoring constraint gets one reference form for all three lists.
  - The binder and the acceptance-assertion contract read one vocabulary, and a card headed `Completion condition (verifiable)`, or listing its criteria as an ordered list, binds.
  - A withheld verdict says whether nothing was read or nothing was found.
- **Negative:**
  - A design's restated criteria are still transcribed by hand into the design snapshot; a fixed-grammar criterion map in Stage-5 output is a follow-up.
  - The design limb checks only what a spoke declares and supplies.
  - The binder stays advisory: its self-test is CI-run, and no CI job grades a release plan with it.
  - Historical designs and reports keep their unqualified labels, as historical record.

## Reversibility

**CHEAP.** The binder's `ns:` field is appended last, so every earlier field keeps its index; the payload changes are documentation columns and one header key; and a revert restores the prior reader, whose widening changed the reading of no body it read before. No data or event schema changes.

## Related ADRs

- ADR-071 — the `acceptance` assertion type. Its parse contract is the vocabulary the binder now reads; this record's release amends its heading and item rules in place.
- ADR-075 — the plan-verification executor's shared contract. Unchanged; the verdicts it emits on a plan's `AC-` rows count the plan namespace.
- ADR-111 — one detector for one issue-body field, scoped there to priority. This record applies the same one-reader principle to the criteria block.
- ADR-062 — the substrate-versus-canonical precedent. Historical labels stay as they were written.
- ADR-181 — ADR citations bind at the claim, not at authorship. In-release prose cites this record by its slug token.
- {{ADR:a-method-the-verifier-cannot-run-is-reported-unrunnable}} — the release's outcome partition, in whose vocabulary Decision 6 reads the binder's outcomes.

## References

- #7494 — the card whose namespace collision and heading gap this record decides.
- #7676 — the ADR issue holding this record's decision set.
- #7618 — the Stage-5 design sub-task, carrying the D35 and D36 decision record.
- #7671 — the design's Phase A6.5 adversarial review, whose PR-1 and FM-1 to FM-4 fixes the gates adopted.
- #7547 — the Stage-4 planning sub-task, carrying the Collective Review record (D37).
- #6236 — the CIAC authoring constraint, which consumes the reference form.
- #7619 — the Stage-6 slice that recorded this file.
