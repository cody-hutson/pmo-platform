---
title: ADR-217 — The exit-consumer and executor census is keyed on provenance and shape, and asserted on every run
status: Proposed — the design was locked at the controls-fail-loud Collective Review scope lock; the transition to Accepted belongs to the release's Stage 13 ratification beat
date: 2026-09-27
release: controls-fail-loud
deciders: "Workspace owner (operator) — decisions rendered at the release's Stage-5 Collective Review scope lock, with the independent adversarial review's findings folded in; design by the Stage 5 Solutioning spoke; authored by the Stage 6 Engineering spoke"
tags: [gate-efficacy, census, exit-contract, population-record, never-fail, executor-coverage, pv-7, drift-engine]
source_observations:
  - "Four earlier counts of the workflow binary-exit consumers rested on four unrecorded definitions and disagreed: a Stage-8 figure of 6 across 4 files, a candidate list of 13 lines, and a Stage-4 plan's 12 and 21. Measured at the Stage-4 pin 8e0ee084, the Stage-4 set of 21 held 16 real members and 5 multi-state ladders and missed 5 members."
  - "Measured at the Stage-4 pin over the same 26 workflow files: the RC|rc spelling tested -eq 0 counts 12 lines in 8 files; adding -ne counts 17; adding probe_rc counts 21; line-level status provenance counts 35 lines in 12 files; consumer-granularity provenance with shape counts 42 consumers in 15 files, 21 of them binary-zero."
  - "History arms recorded at Stage 5: the workflow resolver reads release-corpus-completeness's gate step as binary-zero at bae6ea6f^, the parent of the release that converted it to an integer case, and as multi-state after; the drift resolver counts 6 sites at 80997456^ and 8 at 80997456, the commit that added the re-emit preflight gate; at 539c4440, the readiness sweep that named five executor candidates, the executor resolver reports exactly one of the five as zero-executor, the root-cause record's conclusion."
  - "Check 47 logged an N/A line for each row the drift engine returned exit 2 or 3 for, then printed that every enumerated row had a published Release body matching its note. Reproduced before the fix on a clone whose origin/main was deleted: all 94 enumerated rows returned exit 2 and the OK line claimed all 94 matched."
  - "The install-regression precision probe deleted a hand-written list of seven members from its copy of the runner; eight members enrolled later stayed in the copy, absent from the probe tree, so the runner failed whatever the fixture did. Reproduced with a passing fixture: exit 1, 2 passed and 8 failed, all eight missing."
  - "At the census commit (9b65c62b) the resolvers counted 8 drift-engine decision sites in 5 of the 6 files naming the engine, 21 binary-zero workflow consumers of 43 exit-status consumers in 15 of 26 workflow files, and 89 suites with one zero-executor. The design had predicted 20 binary-zero consumers; the difference is the repaired precision probe's new control arm, a second consumer in that step."
  - "The independent adversarial review found the first executor-record text self-contradictory (its register recipe promised a FAIL its own measurement reported as zero findings), the shape rule reading the case keyword rather than the compared values, the executor predicate counting a mention as an execution, the drift record blind to workflow steps, and the ADR skip rationale not engaging the authoring guide's triggers."
---

# ADR-217 — The exit-consumer and executor census is keyed on provenance and shape, and asserted on every run

## Status

**Proposed.** The design was locked by the operator at the controls-fail-loud Collective Review scope lock, together with the adversarial review's findings routed there; the transition to Accepted belongs to the release's Stage 13 ratification beat, not to authoring.

**Numbering provenance.** Claimed as **207** against a mainline anchor of **206**, read from the repository's ADR-numbering detector as its next-free number rather than computed as one past the highest number visible on any branch; another release's open branch carries 207 to 210 as a detection-only claim. The number binds at the Stage-12 claim; if the mainline claims it first, the renumbering tool moves this record at merge and appends a provenance note here.

**Numbering provenance — `207 → 211`.** Held **ADR-207** branch-local; renumbered to **ADR-211** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 207. In-release citations that read "ADR-207" denote this record.

**Numbering provenance — `211 → 217`.** Held **ADR-211** branch-local; renumbered to **ADR-217** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 211. In-release citations that read "ADR-211" denote this record.

## Context

The gate-efficacy standard requires a gate to report the population it examined, never only a finding count, because a count cannot tell "nothing found" from "nothing examined". The release this record belongs to exists for controls that report success without measuring, and two populations bear on that directly while no file enumerated either. The first is the consumers of the release-body drift engine, a producer with a four-member exit contract — MATCH, DRIFT, not evaluated, MISSING — whose not-evaluated member a consumer can silently fold into a pass. The second is the workflow steps that reduce a captured exit status to zero-versus-non-zero, the job-surface shape that turns a not-evaluated or skipped outcome into a green one. A third population, the test suites and whatever executes them, had been censused before and had gone stale, because nothing re-derived it.

Every earlier count of the workflow population rested on a definition nobody wrote down, and the counts disagreed with each other. The definitions keyed on a variable's spelling, so they included steps that test several values and missed steps whose status variable had another name. A count that depends on its definition is not reproducible unless the definition travels with it, and a census that nothing re-derives decays into a comment the first time the tree moves.

## Decision

The platform adopts one census, published as a section of the gate-efficacy standard in the standard's own population-record form, with its definitions stated before its records, and re-derived and asserted on every run by the conformance suite in a required context.

1. **A decision site is keyed by its file or workflow, its consuming unit and its status variable** — never by a line number, which moves under any edit above it. Membership is read by **exit-status provenance**: a variable assigned from `$?` or `${PIPESTATUS[n]}`, the first value a Python call returns, or a step output written from such a variable. A variable's spelling never decides membership.
2. **A workflow consumer's shape is the set of values it compares the status against.** A `case` contributes its arm labels and a `*)` arm contributes none, so a single-value `case` reads binary-zero rather than multi-state. Only binary-zero consumers are members of the workflow record, each with a direction (`gate` or `probe`) and a classification (`consumes-a-fused-exit-space` or `legitimately-binary`) and a reason.
3. **A drift-engine decision site is classified by what the not-evaluated member reaches on the consumer's own surface** — `distinguishes`, `fail-closed` or `collapses`. Sites in workflow `run:` steps are members, because the not-evaluated member reaches the job surface there, which is where the defect class is defined.
4. **An executor executes its suite** — at command position, directly or as an interpreter's operand; through a named runner's member declaration; or through a loop that executes a tracked glob. A path that is only named — an operand of a transformation, a redirection target, a copy under a scratch directory — is not an execution.
5. **The drift-engine and workflow records are graded as sets.** A live member with no row, a row naming a member that is gone, or an `examined:` count that disagrees with the rows fails the required context. **The executor record lists the zero-executor suites**: a listed suite that gains an executor fails, while a new zero-executor suite is reported on every run and does not fail it — the executor merge gate stays with the self-test coverage checker, which ADR-119 governs.
6. **A change that adds a binary-zero workflow consumer or a drift-engine run adds its census row in the same change.** The required context enforces it.

## Alternatives Considered

**The definition the counts depend on.**

- (A) A status variable recognized by its spelling, tested `-eq 0`. REJECTED: it counts multi-state ladders that test another value first, and misses consumers whose variable has another name.
- (B) The same spelling with `-ne` admitted. REJECTED: the same two defects, with more ladder halves.
- (C) The spelling rule plus one further named probe variable. REJECTED: it matched the prior plan's count in size but not in membership.
- (D) Exit-status provenance read line by line. REJECTED: it counts each half of a ladder as a separate consumer.
- (E) Exit-status provenance at consumer granularity, with shape read from the compared values. SELECTED: it is the only definition that asks the question the class is about — whether a step can ask anything but "was it zero?" — and the only one whose history arms reproduce a known conversion.

**Where the census lives.**

- A new section of the gate-efficacy standard. SELECTED: one structure with the population-record form it renders, beside the register that names its runner.
- A subsection inside Requirement (c). REJECTED: it mixes point-in-time members into normative text.
- A separate census file. REJECTED: a second structure beside the record form.
- Member rows held in the conformance suite, the standard keeping only definitions and records. REJECTED at the scope lock: the rows are what the census publishes, and moving them out would leave the standard publishing a definition without its population.

**How deep the executor record asserts.**

- Every suite a row, with a ratcheted count. REJECTED: an edit to a heavily contended standard for every new test.
- A new zero-executor suite fails the merge. REJECTED: it pre-empts the executor-coverage decision ADR-119 leaves to its own checker, creating two gates that can disagree.
- Stale rows fail, and new zero-executor suites are reported. SELECTED.
- A pinned record checked for form only. REJECTED: that is the stale census this one replaces.

**Posture.**

- Required from day one, in a context branch protection already requires. SELECTED: a census that cannot fail is the defect class it audits.
- Warn-mode first. REJECTED: it needs a written sink and a repository-derivable exit, and delays the only teeth the census has.

**The collapse the census's own audit found in Check 47.**

- Convert Check 47 in the same release. SELECTED: its verdict line counted rows the engine never compared as matching.
- Record the site as `collapses` and route the conversion elsewhere. REJECTED at the scope lock.

## Consequences

**Positive.** The consumers of a multi-state producer and the steps that can reduce one to a single green are now a published, re-derived population rather than a count each audit reinvents. A new binary-zero workflow consumer or drift-engine run cannot land unrecorded, so the next consumer that folds "not evaluated" into "passed" is named in the change that introduces it. The census reports its own reach on every run, so its denominator is the check's output rather than a number in prose.

**Negative.** Every new binary-zero workflow consumer or drift-engine run costs a census row in the same change — intended friction on a heavily edited standard. The classifications are recorded judgment: the suite asserts that every member carries a token from its closed set and a reason, not that the token is right. The conformance suite now carries an executor resolver that the self-test coverage checker could later subsume; it retires when that checker's scope covers every test tree. A new zero-executor suite is visible on every run but does not block a merge.

## Reversibility

**CHEAP** before other changes add rows: a `git revert` of the census commit removes the section, its register row, the conformance suite's census code and the workflow comments together. **MODERATE** afterwards, because rows added by later changes become inert prose once the assertion is gone.

## Related ADRs

- ADR-134 — the degraded-state emit contract that the census's classifications are read against: a not-evaluated member never shares the clean state's emit.
- ADR-119 — self-test coverage discovered against a declared scope; this record leaves the executor merge gate with it.
- ADR-193 — an emitter asserts only properties of its own emit; Check 47's conversion routes its not-evaluated rows through the structurally non-escalating emitter. One not-evaluated class also escalates, by design: an exit outside the drift engine's contract fails Check 47 closed through its mode-driven emitter, as an instrument failure and never a drift finding — the operator's decision, whose record the References block names.

## References

- #4917 — the never-FAIL class card whose census this record decides.
- #7466 — the candidate list whose first criterion became the workflow record's population.
- #6114 — the executor-coverage owner to which the zero-executor suite's disposition is routed.
- #7810 — the work item recording the operator's decision that an exit outside the drift engine's contract fails Check 47 closed as an instrument failure, never as drift.
