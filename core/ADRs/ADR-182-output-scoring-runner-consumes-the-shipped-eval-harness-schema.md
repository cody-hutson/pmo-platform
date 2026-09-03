<!-- reference-durability: allow-link -->
---
title: "ADR-182 — The output-scoring runner consumes the shipped eval-harness schema, not a new one"
status: Accepted
date: 2026-09-02
release: regression-corpus-gates-releases
deciders: "Stage 5 Solutioning spoke (four-candidate design exploration on the consumed schema) + Stage 6 Engineering spoke (build and self-verification) + operator GO at the Stage 4 plan gate"
tags: [eval-harness, output-scoring, scenario-runner, report-contract, duplicate-source, extend-before-create, zero-denominator, never-fail, ADR-071]
source_observations:
  - "The work item that commissioned the runner names, as 'the schema it consumes', a reference document that is trigger-rate shaped: its slots are explicit, neutral and competing; its row fields are explicit-rate, neutral-rate and competing-rate; and its classifier emits fired, sibling-captured and not-fired. It carries no output-score or rubric field. A runner built against it would score nothing while satisfying the literal wording of the criterion that asked for scoring."
  - "The eval-authoring skill's own output-format section declares the eval-harness input schema and then states, in the same paragraph, that the assertion-grading path from the assertion array through the grader to the grading report is a grader-honored contract and not runner-executed today. The gap the work item describes is named by the platform itself, in the file that owns the schema."
  - "The decision record that introduced the acceptance assertion type says in its scope section that no code enforces the type enum, and explicitly defers runner wiring to the framework-consumer work. This release is that consumer."
  - "Five of the five typed suites in the live corpus carry the graded statements under the key `assertions`; zero carry them under `expectations`. The framework's own schema document prescribes `expectations` for that same input. The corpus and the document disagree, and the corpus is what any runner must actually read."
  - "The report contract's pass-rate field is pinned by executable consumer code: the benchmark aggregator reads it through a nested get on the summary object with a zero default, and later performs arithmetic over the collected list. A null in that position raises a type error; an omitted key is silently read as total failure."
  - "The corpus carries three unrelated senses of the bare token `pass_rate` — a gate-criteria structural rate, an iteration-history rate, and the eval-grading rate. A consumer that matches the bare token cannot tell them apart."
  - "The one shipped runner with a non-triviality control arm implements it as four hard-coded, domain-specific Python functions re-run against an empty roster. The pattern is exactly right; the code cannot execute a second suite without new Python per suite."
---

# ADR-182 — The output-scoring runner consumes the shipped eval-harness schema, not a new one

## Status

**Accepted.** Authored at Engineering for the `regression-corpus-gates-releases` release.

**Numbering provenance — `177 → 180`.** Held **ADR-177** branch-local; renumbered to **ADR-180** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 177. In-release citations that read "ADR-177" denote this record.

**Numbering provenance — `180 → 182`.** Held **ADR-180** branch-local; renumbered to **ADR-182** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 180. In-release citations that read "ADR-180" denote this record.

## Context

The platform declared a single scenario engine — one declarative scenario schema, one output-scoring runner, one report contract — and shipped the schema and the contract without the executor. The only runner that exists is a trigger-detection harness: it returns a per-query boolean for whether a skill fires and passes on a trigger rate above a threshold. It computes no output score and invokes no judge. Nothing in the tree catches a change to one skill silently regressing another, which is the capability the engine was commissioned to deliver.

The work item that re-opened the gap names a consumed schema, and **that citation is wrong**. The document it names is trigger-rate shaped end to end and defines no output-score or rubric field. Building the runner against it would produce something that satisfies the literal wording of "scores at least one scenario and emits a report" while measuring nothing — the failure mode where the letter of a criterion is met and the capability is not.

Two facts, both already in the tree and neither cited by the work item, reframe the question:

- **The eval-authoring skill declares this exact gap in the file that owns the schema.** Its output-format section states the harness input schema and, in the same breath, that the assertion-grading path from the assertion array through the grader to the grading report is a *grader-honored contract, not runner-executed today*.
- **The decision record that introduced the acceptance assertion type says the same thing in stronger terms** — that no code enforces the type enum, and that runner wiring is deferred to the framework-consumer work.

So the runner is not a new capability needing a new schema. It is the missing executor for a contract the platform has already frozen, documented, and left inert. That reframing is what makes the third option below available at all: the question is not *which schema do we invent or extend*, but *do we execute the one we already declared*.

A second force cuts the same way. Authoring a new schema where a documented one exists creates a second home for one fact — precisely the duplicate-source condition the platform's own discipline exists to prevent — and it would strand two shipped consumers that already parse the existing report by name.

## Decision

**The output-scoring runner consumes the eval-harness schema the platform already ships, and emits the report contract the framework already defines. It adds no new schema and no second definition of the report.**

Three determinations follow from that one, and are recorded here because they are consequences of it rather than independent choices.

**1 — The schema delta is exactly one optional field.** Graded statements today carry a text, a type, and an optional expected value. The runner adds one optional sibling: a declarative predicate object. An assertion carrying no predicate is **ungraded**, so **every suite already in the corpus remains valid input, unmodified**. That backward compatibility is what makes the delta additive rather than a migration, and it is the property that lets the decision be taken without touching any existing suite.

The predicate's kind is a **closed five-value set**, derived by construction from the four deterministic values already in the assertion-type enum: an existence check, a literal-substring check, a regular-expression check that names its engine at the point of use, a structured-path resolution that reuses the existing expected-value field, and an unchanged check that proves a read was read-only. The set adds no new semantics; it makes executable the semantics the enum already declares. It is **closed** rather than open because an open predicate set re-admits per-suite code, which is the property that makes the one existing deterministic runner unable to run a second suite.

Two details are part of the decision, not of the implementation. The substring check is **literal only**, so a scenario author cannot silently author a regular expression into a substring matcher. The pattern check **names its engine in-band**, because an unnamed regular-expression dialect is an ungradeable claim.

**2 — Non-triviality is a suite-level control, not a per-assertion predicate.** The suite declares a control fixture that is structurally empty; the runner re-runs every resolution predicate against it and requires **all** of them to fail. This is the same layer the one shipped deterministic runner implements, re-expressed declaratively — which is the only form that generalizes, since that runner implements it as hard-coded per-skill functions.

**3 — The runner extends the skill that owns the eval framework** rather than being sited elsewhere. The four artifacts it must interoperate with — the contract document, the aggregator that reads the pass rate, the viewer that reads the report by name, and the agent that is currently the report's only producer — all live in that skill, and two of them pin the contract in executable code. A runner sited outside would emit a contract defined in another module and consumed by two scripts in that module, fragmenting one framework across a module boundary for no gain.

**4 — When nothing was gradable, the runner writes no report and exits with a status reserved for that state.** It does not emit a null pass rate and it does not omit the key. This is forced by a real property of the shipped consumer rather than by preference: the aggregator reads the pass rate through a nested get whose default is zero, so an omitted key is silently read as **total failure**; and it later performs arithmetic over the collected values, so a null raises a type error and crashes a shipped consumer. Writing no file is the only faithful encoding the frozen contract admits — the aggregator's missing-file branch warns and skips the run, so a non-measuring run contributes nothing to the aggregate rather than entering it as a zero.

**Two field names are inherited asymmetrically and the asymmetry is preserved deliberately.** The runner **reads** the graded statements under the key the corpus actually uses and **writes** them under the key the aggregator pins in code. The two differ. Renaming either side breaks a shipped consumer, so the runner implements the mapping and documents it; it does not "fix" the asymmetry. Separately, the pass-rate field is referenced **fully qualified** — as the named field of the summary object — never as the bare token, because three unrelated metrics in the corpus share that token and a bare match cannot tell them apart.

## Decision kernel (version-agnostic)

> When a platform has already declared a schema and a report contract and left them unexecuted, the executor consumes the declared contract rather than introducing a competing one — even when the commissioning work item cites a different schema, because a wrong citation is a defect in the citation and not evidence that the declared contract is unfit. The delta a new executor may add to a frozen input schema is bounded by backward compatibility: one optional field whose absence is a defined, non-penalizing state, so that no existing input requires migration. And where the executor's output feeds a consumer that coerces absence to a value, the executor emits **nothing** rather than a value the consumer would misread — a measurement that did not happen must not be representable as a measurement that scored zero.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Extend the trigger-rate schema** the work item cites with an output-scoring slot — the literal reading of the commissioning item | Rejected | That schema's consumer is a compliance auditor's calibration run, which appends trigger-rate rows. Bolting an output-score slot onto it puts two unrelated metric classes in one contract and drags a second skill into this release's blast radius for no capability gain. The citation is a defect to correct, not a constraint to honour. |
| **Adopt the shape of the one shipped deterministic eval suite** as the schema | Rejected | Its shape is suite-local and ad hoc, carried by exactly one suite, and it defines no report contract at all. Adopting it would create a second report definition alongside the one two consumers already parse. |
| **Author a new bespoke output-scoring scenario schema** | Rejected | Creates a second home for a fact the platform already documents, which is the duplicate-source condition the register-or-remove discipline exists to prevent. It also leaves the declared-but-inert contract permanently inert while adding a competitor to it. |
| **Adopt the shipped eval-harness schema** | **Selected** | Its consumed fields exist today in five live suites; its report contract is already defined and already parsed by two shipped consumers; and adopting it means the release adds no second definition of anything, so the cross-issue constraint requiring exactly one contract definition holds without any deduplication work. Blast radius is confined to one skill plus a single-passage correction in the schema's owning skill. |
| **Emit a null pass rate** when nothing was gradable | Rejected — falsified against the consumer | The aggregator performs arithmetic over the collected values; a null raises a type error there. The rejection is measured against the consumer's code, not argued from taste. |
| **Omit the pass-rate key** when nothing was gradable | Rejected | The aggregator's nested get defaults to zero, so absence is read as total failure — the absence-read-as-zero anti-pattern the platform's own probe discipline forbids. |
| **Ship the judge layer in this release** alongside the deterministic layer | Rejected — deferred | The deterministic scoring layer cleaves cleanly from the model-judged layer, and the cleave is the assertion-type enum itself. Shipping both would couple a reproducible, offline-verifiable capability to one that requires live model calls to verify. |

## Consequences

**The deferred runner-wiring commitment is partially, not fully, discharged.** Only the deterministic assertion types execute after this release; the judgment and acceptance types stay runner-inert. Any downstream reading that treats the commitment as closed is wrong, and this record says so rather than leaving the overclaim available.

**The pass-rate field now has a deterministic producer as well as a model-judged one.** The same field could previously only be written by the grader agent; a code path now computes it, so it can carry a reproducible value across runs. The aggregate the benchmark computes therefore mixes reproducible and sampled members, and a reader of that aggregate must know which producer wrote each run.

**A suite can now be a no-op in a way the runner detects but a reader might not.** An assertion with no predicate is ungraded and leaves both numerator and denominator, so adding un-predicated assertions to a suite cannot depress its pass rate — which is what keeps existing suites valid. The cost is that a suite consisting entirely of un-predicated assertions produces no measurement at all. The zero-denominator rule makes that state loud rather than silent, but the state remains reachable by authoring.

**The runner's home is settled for this release and argued, not permanent.** Siting it in the skill that owns the framework was chosen because relocating the framework is a strictly larger change than adding its missing executor. If a consumer outside that module emerges, promoting the runner to the shared kernel is a clean follow-up, and this record is the place a future decision would supersede.

**Two field-name asymmetries are now load-bearing.** The read key and the write key differ, and the pass-rate token is ambiguous across three metrics. Both are documented and both are now depended upon. A future normalization must move every consumer at once; a partial rename is worse than the asymmetry.

**One pre-existing defect is named and deliberately not fixed.** The aggregator reads a missing pass rate as zero. Changing it is a behaviour change to a shipped consumer and is outside this release's criteria. The zero-denominator rule routes around it rather than repairing it, which means the defect survives this release with a consumer that no longer triggers it.

## Reversibility

**CHEAP / Confidence HIGH.** Every deliverable this record governs is additive: a new runner module, a new reference document, a new suite with its fixtures, and four bounded documentation edits. Reverting the commits removes the runner and restores the current state, in which the schema is declared and unexecuted. The trigger-detection runner is not modified, so no revert can disturb trigger detection. No migration, no data, no state.

**The one asymmetry worth naming:** the schema delta is an *optional* field, so a suite authored against it remains valid input to any future executor that ignores the field. Reverting the runner does not invalidate suites written for it.

## Related ADRs

- **ADR-071** — introduced the acceptance assertion type, stated that no code enforces the type enum, and deferred runner wiring to the framework-consumer work. This record is that consumer's decision: it discharges the deferral for the deterministic types and states explicitly that the model-judged types remain deferred. It also reuses that record's locked all-drift-out denominator convention verbatim rather than defining a second arithmetic for the same aggregate.
