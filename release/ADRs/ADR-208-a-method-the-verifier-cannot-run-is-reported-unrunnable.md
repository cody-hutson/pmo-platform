---
title: "ADR-208 — A method the plan verifier cannot run is reported UNRUNNABLE: a fifth verdict that does not fail the run, and the release's one outcome partition"
status: Accepted (rendered by the operator at the Stage-5 D-6848 gates as decisions D21–D24, with the Collective Review's partition and single-record decisions D37 and D47; this file records them)
date: 2026-09-25
release: verifier-grades-what-plans-declare
deciders: "Workspace owner (operator), rendering the Stage-5 D-6848 gates as decisions D21–D24 against the Stage-5 design and its Phase A6.5 adversarial review, whose command-shape counter-design and scope guards the operator adopted with the gates, and the Collective Review scope-lock as decisions D37 (the outcome partition) and D47 (this file as the release's single partition record) + Stage 5 Solutioning spokes (Principal Engineer — Architecture Assessment) + the Stage 6 Engineering spokes that recorded them"
tags: [architecture, release-pipeline, verify-release-plan, verdict-enum, unrunnable, outcome-partition, scope-family, command-shape, shell-operator, schema-version, amends-adr-075]
supersedes: none
source_observations:
  - "At the Stage-5 pin, 206 rows declined as tool invocations graded SKIP beside 36 declared deferrals, and the declined 'verb' was the method's first bare word: it named 105 distinct things across the corpus, mostly labels, file names, hashes and words. A failing UNRUNNABLE would have flipped 8 otherwise-clean plans from exit 0 to exit 3 by relabel alone, and a second measurement on a different mask flipped 25. Measured by the Stage-5 design and reproduced by its Phase A6.5 review."
  - "The review found that at least 29 of the 249 rows the design's first form named named a mention rather than an invoked command, 17 of them created by the residual step. Under the invocation-shape test the operator adopted (D22, D24), UNRUNNABLE rows fell from 249 to 211 and ERROR-to-UNRUNNABLE moves from 119 to 98, with 0 new FAIL, ERROR, PASS or executed rows and 0 plans moving from exit 0 to exit 3; about 17 genuine single-token script invocations lose their name. Measured by the review's replica over 1,438 parsed rows."
  - "Re-measured at Stage 6 on the step that lands this record, by a record-stream differential of the previous step's executor against this step's, in one stub root with the deploy check stubbed, over the release branch's 217 plans and 50 test-fixture files. 468 plan records change and none newly reads PASS: 115 tool declines move from SKIP to UNRUNNABLE, 16 of them under a different name (11 had named an identifier), and 3 whole-method script rows are newly named; 101 refusals that named an identifier (91) or a one-token mention (10) become the no-command SKIP; 98 rows move from an unclassified ERROR to UNRUNNABLE naming the tool their command invokes; 84 partially run rows move from the SKIP slot to UNRUNNABLE, 22 more reach it because a tool span is now a command, and 9 keep FAIL or ERROR and now name it; 12 rows whose designated command carries shell syntax read UNRUNNABLE naming the operator, 11 of them from ERROR and 1 from PASS. The other 24 are the deploy-route rows that the sibling record on how a method cell declares its route governs (its Decision 7). 6 plans stop failing the masked measure (FAIL or ERROR outside the deploy, delivery and provenance families): v3.70, v3.96, v4.01, v4.06, v4.21 and v4.67.1. None starts."
  - "The named-tool census at the same step: of the 2,587 records the 217 plans emit, 263 name a declined tool, with 38 distinct names — 19 catalog words and 19 script basenames — and 0 identifiers. The previous step's executor, over the same records, names 102 identifier mentions (92 distinct: file names, labels, function names and commit hashes), so the census discriminates."
  - "The script-name cost at the same step: 78 plan records carry a one-token script span. 26 of them name a tool; 28 name nothing and read an unclassified ERROR (22) or the no-command SKIP (6). A hand read classes 14 of those 28 as clear invocations (for example 'Run `check-label-parity.py` against a fixture' and 'through `test-runner.sh`'), 11 as mentions and 3 as unclear — the cost the review estimated at about 17."
  - "No historical plan row is a scope assertion: at the Stage-5 pin no corpus `git diff` span carried a comparator, and at the Stage-6 step no plan row moves into the scope family. Its verdicts, and each of its guards, are exercised by the release's own suite fixture."
---

# ADR-208 — A method the plan verifier cannot run is reported UNRUNNABLE: a fifth verdict that does not fail the run, and the release's one outcome partition

## Status

**Accepted.** Rendered by the operator at the Stage-5 D-6848 gates as decisions D21–D24, which adopted the Phase A6.5 review's command-shape counter-design and its scope guards. The Collective Review then reconciled the release's outcome vocabulary into one partition (D37) and made this file the release's single partition record (D47). Recorded at Stage 6 Engineering for the `verifier-grades-what-plans-declare` release, in the slice that implements Decisions 1–7. Decision 8 is the Decision line of the card whose multi-command reading the partition's partially run row rests on (D29), carried from that card's slice.

**Amends ADR-075 decision 5.** This record contests nothing ADR-075 decided. Decision 5 made the emitted evidence, its verdict enum included, a versioned contract, so that a change to it is a detectable schema bump rather than a silent break. This record is such a change: the enum gains UNRUNNABLE under the release's one `SCHEMA_VERSION` bump, and the exit rule counts UNRUNNABLE with PASS and SKIP.

**Numbering provenance.** Claimed as **208** against an anchor of **206** on the mainline, read from the repository's own ADR-numbering tool at authoring, with **207** already held on this release's branch by the record {{ADR:a-rows-grading-route-is-declared-in-its-method-cell}}. The number binds at the Stage-12 claim, and in-release prose cites this record by its slug token.

## Context

The plan verifier runs only a closed set of read-only verbs, and that closure is a security boundary. A method needing any other tool was reported SKIP, the same verdict a plan uses to declare a row another runner's job, so a plan whose most rigorous criterion never ran read like one that deferred a judgement call. The refusal named its "tool" from the method's first bare word, and so named labels, file names and hashes as readily as tools. A `git diff` scope assertion had no family at all.

Several of the release's cards each designed a part of one outcome vocabulary: the can't-run verdict, the partially run row, the method with nothing to run, and the reading Stage 9 gives each. The Collective Review reconciled them into the one partition this record carries. The measurements behind every decision are in `source_observations`.

## Decision Drivers

- Keep `RUNNABLE_VERBS` untouched: it is the security boundary.
- No historical plan may flip from exit 0 to exit 3 by relabel alone. As of the D21 decision, a failing token would have flipped 8 otherwise-clean plans.
- Every reader keys on the verdict value: the exit predicate, QC3.5, G-PR10 and the roll-up.
- A refusal names a real tool, never a label, file name, hash or word the method merely mentions.
- One vocabulary: an outcome means the same thing to the executor, to its roll-up and to every gate that reads it.

## Decision

1. **UNRUNNABLE is a fifth verdict value** (can't-run-here): the row is read, but a command it names cannot be run here. It is neither a named SKIP (not this runner's job, or nothing to run) nor ERROR (could not read).
2. **It does not fail the run.** The exit stays non-zero only on FAIL or ERROR. A roll-up counter and a stderr note make it visible.
3. **The declined tool is named only from an invocation-shaped span** (D22, D24).
   - A span qualifies when it has two or more tokens, is a bare interpreter, or is the whole method; shell keywords and builtins also need an argument.
   - The name comes from a closed catalog plus the script shape. A backticked identifier or a mention is never named as a tool, and an identifier stops the surrounding prose from being run as a bare command.
   - A designated command that carries shell syntax outside quotes — a pipe, a list, a redirect or a substitution — is UNRUNNABLE as well, naming the operator: the executor runs no shell, so the syntax would reach the verb as literal arguments. One shared quote-aware predicate decides it for the router, the handlers and the scope step (D38).
4. **An otherwise-unclassified row carrying an invocation-shaped recognised command is UNRUNNABLE.**
5. **A native scope family** grades `git diff --name-only <release range> -- <pathspec>…` against the release diff: every change the release makes, across all of its cards (D23).
   - It reuses the fcm-delivery family's fixed git call and matches pathspecs in-process, so no plan-authored byte reaches git.
   - It accepts exactly one comparator, read through the shared comparator vocabulary, and refuses a `<placeholder>` pathspec.
   - For `==` and `<=` assertions, every included pathspec must select at least one existing or changed path.
   - An empty or unresolvable diff, an ambiguous comparator, a placeholder, or a pathspec that selects nothing is UNRUNNABLE, never a pass.
6. **The new enum value contributes to the release's single `SCHEMA_VERSION` bump, 4 → 5** (D40). The bump lands with the release's first executor change; this record's slice is a later contributor and adds no second bump.
7. **The release's outcomes form one partition** (D37), stated in the table below. QC3.5 reads UNRUNNABLE, a partially run row included, as NOT MET (unverified). An unexecuted command is reported as "did not run (reason)". There is no separate partial outcome: a row whose other commands did not run is unverified, which is what can't-run-here already says.
8. A method that names more than one command is graded on its designated command — the first allowlisted verb that carries an argument — against the comparator written after that command. Every other command it names is reported as "did not run (reason)", and the row is never PASS: a FAIL or ERROR from the designated command stands, and a designated PASS takes the can't-run outcome (UNRUNNABLE), naming the command that ran and each one that did not. A bare verb (a tool named in prose, with no argument) is never a command, and the further commands are not run.

**The partition (Decision 7).**

| Outcome | Verdict | What the executor found | Fails the run | Typical `observed` text |
|---|---|---|---|---|
| Met | PASS | The designated command ran and met its comparator | No | `count=N (op want)`, `command-succeeded` |
| Not met | FAIL | The designated command ran and did not meet its comparator | Yes | `count=N (op want)`, `command-exit-N` |
| Not this runner's job | SKIP | The method declares another runner | No | `declared-deferred` |
| Nothing to run | SKIP | The method names no command | No | `no-executable-command-in-method`, `documented-decision-method (…)` |
| Can't run here | UNRUNNABLE | The method names a command this executor will not run, or a scope input that is vacuous or mis-bound | No | `tool-invocation-outside-executor-allowlist:<tool>`, `shell-operator:<op>`, `scope-diff-empty`, `scope-pathspec-selects-nothing` |
| Partially run | UNRUNNABLE | The designated command passed, and another command the method names did not run | No | `partial-execution: limbs run 1 of N: …` |
| Could not read | ERROR | The executor could not read or evaluate the row | Yes | `unclassified-method (no family match)`, `count-unreadable:…`, `stdin-reader:<verb>` |

A designated command that fails keeps FAIL or ERROR whatever else the method names: only a designated PASS becomes the partially run outcome.

## Alternatives Considered

- **Keep SKIP and distinguish by reason.** The strongest alternative, because it needs no enum change. Not chosen: every reader keys on the verdict.
- **UNRUNNABLE that fails the run, or an opt-in failing flag.** Rejected: the first turns historical plans red by relabel alone, and the second is off unless asked for.
- **ERROR for a command the executor will not run.** Rejected: ERROR means the input could not be read, and these rows were read.
- **Name the tool lexically, or by a PATH lookup.** Rejected: lexical naming admits English words, and a PATH lookup grades differently per machine.
- **Add `git` to the verb set, or validate the author's git command.** Rejected: either opens an authored-command channel into the tool that grades the release's own plan.
- **A declared scope grammar.** Rejected: a third in-method grammar beside the declared-deferred form and the command.
- **Name a tool from any backticked span whose first token is a catalog word or a script path** (the Stage-5 design's own form, before its review). Rejected, as of the D22/D24 decision: at least 29 of the rows it named named a mention, not a command.
- **A separate PARTIAL outcome for a partially run row.** Dropped at the Collective Review (D37): the row is unverified, which the can't-run outcome already states.
- **Grade a per-issue scope row on its own card's commits** (the review's per-card scope counter-design). Not taken beyond the minimum (D44): the family grades the release diff, and a claim about one card's own changes is not a scope row.

## Consequences

- **Positive:**
  - Can't-run-here is visible at the verdict, in the roll-up and on stderr.
  - A named tool is a command the method runs, and a mention is never named.
  - A command that carries shell syntax is never run with that syntax as literal arguments.
  - Scope assertions execute with no code-execution channel, and cannot pass on a vacuous or mis-bound input.
  - Every gate reads one partition: a partially run row, a tool the executor declines and a vacuous scope input all read the same way, as unverified.
- **Negative:**
  - Plans whose only failing rows were readable tool commands now exit 0, with those rows counted as UNRUNNABLE. No gate reads per-issue verdicts today: Stage 7 keys on the exit status and Stage 8 grades each criterion independently. This residual is stated, not hidden.
  - About 17 genuine single-token script invocations lose their name under the invocation-shape test, as of the D22/D24 decision.
  - A real tool missing from the catalog reads as a method with no command until it is added.

## Reversibility

**MODERATE.** A revert restores the four-value enum, and plans regrade with no data loss. It changes routing and the emitted contract of a tool every release runs, so its effect reaches every plan the tool grades.

## Related ADRs

- ADR-075 — the plan-verification executor's shared contract. Amended: decision 5's verdict enum gains UNRUNNABLE under decision 5's own versioning rule, and the family registry gains the scope and unrunnable families.
- ADR-073 — the cross-issue release-integration check at Stage 9. Its single-runner rule is unchanged; Stage 9 reads the emitted UNRUNNABLE as Decision 7 states.
- ADR-168 — a verification claim is a named schema column. Untouched.
- ADR-181 — ADR citations bind at the claim, not at authorship. In-release prose cites this record by its slug token.
- {{ADR:a-rows-grading-route-is-declared-in-its-method-cell}} — the sibling record in this release, on how a method cell declares its grading route. Its declared deploy row that also names another command takes this partition's partially run outcome.

## References

- #6848 — the card this record carries (Decisions 1–7).
- #7647 — the ADR issue holding this record's decision set.
- #7606 — the Stage-5 design sub-task, carrying the D21–D24 decision record.
- #7643 — the design's Phase A6.5 adversarial review, whose command-shape counter-design and scope guards D22–D24 adopted.
- #7547 — the Stage-4 planning sub-task, carrying the Collective Review record (D37, D38, D40, D44, D47).
- #7531 — the loop-body isolation the scope family's git call runs inside, and the release's single `SCHEMA_VERSION` bump (D40).
- #6837 and #7599 — the card whose Decision line is Decision 8 (D29), and its Stage-6 slice, which rendered that line.
- #7834 — the round-2 design sub-task, whose D50 record assigned the handlers' shell-operator refusal to this record's slice.
- #6236, #6854 and #6685 — the cards whose Decision lines join this record from their own slices (D47).
