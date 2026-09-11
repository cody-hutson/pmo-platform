---
title: ADR-195 — Criterion evaluability is a per-check measured property, and it gates admission
status: Accepted
date: 2026-09-11
release: authoring-bar-and-consumers
deciders: Workspace owner (Stage-4 D-Gate; Stage-5 Collective Review scope-lock), Stage-5 Solutioning spoke, Stage-5 Phase A6.5 adversarial reviewer, Stage-6 Engineering spoke
tags: [criteria, work-item-types, methodology-packs, gates, evaluability, readiness]
source_observations:
  - "Measured 2026-09-11 against baseline a30838589583bcddf5f88183cfff1a8ea2475300: the two shipped methodology packs declare 26 criteria checks in total — 19 at level L3, 4 at L1, 3 at L2; 21 at automatable = false and 5 at automatable = true. The cross-tabulation is (L3,false)=19, (L1,true)=4, (L2,false)=2, (L2,true)=1."
  - "The level = L3 set and the automatable = false set are NOT the same set. They diverge on exactly two checks — kanban-dor-pull-policy-explicit and kanban-dod-exit-policy-satisfied — each carrying level = L2 together with automatable = false. Any arithmetic that subtracts the L3 count from the total to obtain the machine-evaluable count is therefore wrong by two."
  - "The same measurement recorded 8 kind_specific field declarations across both packs, all of them in the Scrum pack; the Kanban pack declares none."
  - "The annotation the L3 projection arm emits occurs exactly once in the tracked corpus — in the schema that declares it — and has no materialized instance and no consumer, while its L2 sibling annotation class has a materialized instance in a shipped machine-schema."
  - "The consuming gate reduction is ALL-PASS / ANY-FAIL over a criterion set, its verdict set is closed at three values with partial credit explicitly forbidden, and a criterion with no evidence is treated as not-satisfied. Each criterion is evaluated against available evidence, which makes the evidence state a property of a work item rather than of a check."
supersedes: none
---

# ADR-195 — Criterion evaluability is a per-check measured property, and it gates admission

## Status

Accepted. Ratified at the Stage-5 Collective Review scope-lock for the `authoring-bar-and-consumers` release, with two structural findings from the independent Phase-A6.5 adversarial review routed Tier-1 and applied inside the design shape rather than reopening it.

## Context

The two shipped methodology packs declare criteria checks per kind, each carrying a `level` of `L1`, `L2` or `L3` and an `automatable` boolean. The EAD materialization treats the three levels asymmetrically: `L1` projects to a schema-expressible constraint, `L2` to a referential annotation, and `L3` to a judgment annotation that is recorded so a reviewer or skill can surface it rather than machine-enforced.

That asymmetry left an open question for the per-kind authoring bar: **if a judgment-level criterion cannot be evaluated reproducibly, the bar is guidance that shapes elicitation and never gates; if it can, readiness gates gain a whole class of check they do not have today.** At the baseline measured for this decision, `L3` accounted for the clear majority of the declared surface, so the answer routes most of it.

**The question as filed does not have a single answer, and answering it as though it did is the failure mode.** It is asked of a heterogeneous population. One check reads *"At least one Work Item declares a BELONGS_TO edge to this epic"* — a graph query wearing a judgment label. Another reads *"leaves the implementation approach for the Developers to determine"* — genuinely interpretive. One verdict over both is wrong for both.

**The decision-relevant question is not evaluability; it is admission.** The rule that consumes these checks reduces ALL-PASS / ANY-FAIL and treats a criterion with no evidence as not-satisfied. A check that cannot be evaluated therefore does not go quiet when admitted — it changes what the aggregate can return. So the question worth answering is *which checks may be admitted to a set whose rule rounds absence to failure*, and that reframing is what makes the measurement worth running.

**The corpus forecloses the naive "advisory" landing.** The platform's gate-efficacy standard states that leaving a normative predicate unrun *is* the defect: a fail-closed predicate with no runner cannot fire, so it cannot fail, and in the artifact it is indistinguishable from a clean check. "Advisory-only" therefore cannot mean *leave the judgment-level statements standing as normative and unrun*. It must resolve to a named disposition — a downgrade to non-normative description, or a registered named gap carrying a declared observable.

## Decision

**Part 1 — Evaluability is a per-check measured property, not an attribute of a level.** The `level` domain is declared fixed and closed because the projection is a three-way switch and a fourth value would have no arm; this decision does not re-level any check and does not add a level. It records, per check, whether that check's judgment is reproducible — a property orthogonal to how the check projects. A check can be interpretive in projection and reproducible in judgment, and collapsing the two axes destroys the distinction this decision exists to capture.

**Part 2 — The verdict vocabulary maps onto the shipped gate-efficacy disposition ladder. No new vocabulary is minted.**

| Per-check verdict | Measured definition | Disposition it obliges |
|---|---|---|
| `gate-capable` | the falsification arm flips on **every** run **and** the specificity arm holds on **every** run | Wire it. The check becomes an implemented gate, declared at the implementing check |
| `gate-capable-under-conditions` | both arms unanimous only when a named precondition holds — a required field populated, a named context artifact supplied | Wire it with the precondition as a guard, carrying a stated unresolved-disposition |
| `advisory-only` | **either** the arms are not unanimous across runs, **or** any run returned an unrenderable judgment | Downgrade to non-normative description, **or** register a named gap carrying a declared observable. Never "leave normative and unrun" |

The per-run judgment vocabulary is **`MET` / `NOT MET`** — the platform's existing binary per-criterion enum — plus **`UNRENDERABLE`** for a judgment the run cannot render. The tokens are spelled here as literals rather than named by description, because two in-corpus enums answer to "the existing binary per-criterion enum" and a run that resolves the other one emits a semantically identical verdict set under tokens that will not aggregate. A run emits exactly one of the three per pair-member and mints no fourth.

**`UNRENDERABLE` is not a spelling of the consumer's no-evidence state, and the two must stay lexically distinct.** The readiness-gate consumer already evaluates each criterion against a tri-valued `PASS` / `FAIL` / `NO-EVIDENCE` enum. That is a different enum on a different surface: `NO-EVIDENCE` is a *rendered* consumer-side state that the reduction rounds to not-satisfied, while `UNRENDERABLE` records that no judgment was rendered at all. Collapsing them would let a judge-side indeterminacy be read downstream as a measured absence of evidence — a verdict that reads as data while nothing was measured, which is the failure this record exists to prevent. No fourth gate-verdict value is introduced, so the consuming reduction's closed three-value verdict set is untouched.

**Part 3 — The admission bar is a binary falsification/specificity pair required unanimous, and the run count `r` is a declared parameter with a recorded error profile.** The platform already sets a check's admission bar as a binary pair: a constructed violation must flip the gate red, and a benign input must leave it green. Three independent in-corpus surfaces set a bar that shape, and the consuming reduction is itself ALL-PASS / ANY-FAIL with partial credit explicitly forbidden — an aggregate with no arm for a fractional agreement score. **No agreement threshold is introduced.** The agreement statistic is computed and reported per check as a diagnostic that explains a non-unanimous result; it carries no gate authority.

**Unanimity is not scale-free, and `r` is therefore a real parameter rather than the absence of one.** Under independent arms, the probability that a check of true per-run reliability `p` is classified `gate-capable` is `p^(2r)`:

| `r` | p=0.95 | p=0.90 | p=0.85 | p=0.80 | p=0.50 |
|---|---|---|---|---|---|
| 2 | 0.815 | 0.656 | 0.522 | 0.410 | 0.062 |
| **3** | **0.735** | **0.531** | **0.377** | **0.262** | **0.016** |
| 5 | 0.599 | 0.349 | 0.197 | 0.107 | 0.001 |

At `r = 3` the bar is deliberately asymmetric: a coin-flip check clears both arms about 1.6% of the time, while a genuinely reliable check at `p = 0.90` is nonetheless dispositioned `advisory-only` about 47% of the time. **Raising `r` worsens the second rate, not the first**, so `r` is held at 3 and the asymmetry is recorded here rather than left implicit. The remedy for the false-exclusion rate is Part 4's arm-count record, not a larger `r`.

**Part 4 — A recorded disposition carries its arm counts and, for `advisory-only`, which disjunct fired.** A flat trichotomy makes an exclusion permanent by erasing its basis: `advisory-only` at 2-of-3 and at 0-of-3 are the same token, so a consumer receives a bare must-not-admit with nothing to prioritise a re-measurement against. Every recorded disposition therefore carries the per-arm `n/r` counts, and every `advisory-only` additionally names which of its two disjuncts fired. Both are numbers the measurement already produces; this only changes where they land.

**Part 5 — An `advisory-only` check MUST NOT be admitted to an aggregated criterion set whose rule rounds an unevaluable member to failure. The rule holds for both disjuncts, for two individually sufficient reasons, and the two are not the same reason.**

| Disjunct | What the consuming aggregate does | Why it is still MUST-NOT-ADMIT |
|---|---|---|
| **Unrenderable** — a run declines or errors | The judgment codes to the no-evidence state, which rounds to failure, which blocks the transition | Admission makes the aggregate **structurally incapable of its clean verdict** for any work item whose evidence is absent |
| **Non-unanimous** — every run renders a definite verdict, inconsistently | Evidence is present on every run, so the aggregate never sees the no-evidence state; it blocks on some runs and passes on others | Admission makes the aggregate **nondeterministic**, which is a re-rollable gate: a blocked transition can be re-requested until it passes. That is the gate-washing surface the reduction's guardrails exist to close |

**Stating this as one reason would have recorded the wrong mechanism as the basis of the rule.** The inference *"an unevaluable check blocks every gate permanently"* holds only for the first disjunct. A non-unanimous check produces a flaky gate, not a blocked one — and the flaky failure is the more dangerous of the two, because a permanently-blocked gate is loud and self-announcing while a flaky one is silent and re-rollable. The two registers are different objects: reliability is a property of the check-and-judge pair *across runs*; the evidence state is a property of the check, item and run *triple*. Each criterion is evaluated against available evidence, so the evidence state is per work item by construction and no measurement over a bounded item sample establishes it "for every work item".

## Methodology

Three layers, composed. Each answers a different question, and the three singles were each dominated because each answers only one of the three things a reproducibility verdict requires.

**Layer D — decidability pre-partition** (no runs; classification from the statements). The partition is a **hypothesis, not a verdict**: a check classified decidable on structural grounds still runs Layers E and B. It is applied as an **ordered two-question procedure**, which is disjoint by construction, rather than as three named classes:

1. *Is the check's predicate wholly a property of data the platform declares — an edge, or a field's presence or literal value — such that the predicate is decided by reading that data and comparing it to a stated constant, **with no residue**?* If **no** → `interpretive`.
2. If **yes**: *does deciding it require traversing at least one edge?* **Yes** → `graph-decidable` (traversal dominates). **No** → `field-decidable`.

The "no residue" qualifier and the traversal-precedence rule are the two clauses that make the procedure decidable. Without them the three class names admit no unique classification for a check that mixes an edge, a field and a judgment in one sentence — which the middle of this population routinely does.

**Layer E — falsification-pair construction** (per check, from real work items). The conforming member is a real unmodified item that satisfies the check; the violating member is **the same item with one minimal mutation that breaks exactly this check**. The pair is the sensitivity/specificity arm pair, and minimality is what makes a flip attributable.

**Minimality in the item is not minimality in the criterion space**, and the shipped checks share the fields a minimal mutation touches. Layer E therefore carries a mandatory **confound lookup**: for each pair, record which *other* declared checks the same mutation also breaks. Where that count is non-zero, either re-derive a mutation that isolates the check, or record the pair **confounded**, grade its verdict `[INFERRED]`, and exclude it from the routing count.

**Layer E's output is a materialized artifact, not a procedure each run re-derives.** The concrete pair-member set is recorded in Appendix A: per check in the frame, a named base item, the bounded evidence set the judgment is rendered against, and the literal text of the violating member. Recording mutation *classes* and leaving the item to the executing run makes the item a **free variable**, and a per-run free variable is a strictly larger threat than the per-check item-conditionality the threat table concedes: with each run drawing its own item, cross-run agreement confounds rater reliability with item variation, and no arm can be read as a reliability signal at all. Materializing the set is what converts the declared item-conditionality from an unbounded threat into the bounded one it was declared as — the verdict stays conditional on one item, and that item is now named, frozen and identical across runs.

Three properties make the recorded instrument usable, and each closes a specific way two raters can grade different things while appearing to grade the same:

- **The evidence set is closed.** A pair-member's evidence set is exactly what Appendix A records for it; a fact outside that set is not available to the judgment, and a judgment that reaches outside it is out of protocol. Without this, "the item" silently means whatever each rater chose to read — one rater deciding a criterion from the record and another deciding it from the delivered artifact are answering different questions under one check id.
- **The evidence set is complete over the check's predicate.** Where a check quantifies over something that is not a property of the item — a team's Definition of Done, a Sprint Goal, a service's written policy, or the realisation of a stated outcome — the instrument supplies it, in one of three declared classes: **`[item]`**, a verbatim fragment or declared structural fact of the real base item; **`[pinned]`**, a real fact about the repository or the tracker at the baseline recorded in `source_observations:`, supplied because the check quantifies outside the item; and **`[fixture]`**, a constructed artifact this deployment does not carry. An incomplete evidence set does not make a check hard — it makes it unanswerable, and a protocol that leaves the set undefined measures each rater's choice of boundary rather than the check.
- **The violating member is recorded as text, not as an instruction.** A described mutation is authored differently by two raters, so a shared description is not a shared instrument. Appendix A records the literal replacement — the exact fact or fragment that changes and the exact text that replaces it — and the mutation's prose description is retained as the derivation record that makes the isolation claim auditable, never as the rater's construction step.

**No base item is mutated in the tracker.** A violating member is a derived reading of a real item, recorded here; the item it derives from is real, unmodified, and stays that way. This is what lets the conforming member remain "a real unmodified item" in Layer E's sense while its twin is fully determinate.

**Layer B — context-isolated repeated judgment.** `r = 3` runs per check-and-pair-member, **each from a fresh context carrying no memory of a prior run**. Context isolation is specified as a **property** with two sanctioned realizations — independent sessions mediated by the orchestrating session, or a fresh sub-agent invocation per run. Repeated judgments inside one context are correlated by construction and inflate agreement toward certainty, which would manufacture a false `gate-capable`; the property is what the measurement rests on, and the realization is free.

**If neither realization is available, the measurement degrades to same-context repetition. That degradation is reported explicitly, its results are graded `[INFERRED]`, and they do not enter the routing count.**

**Rendering rule — the boundary between `NOT MET` and `UNRENDERABLE`.** `UNRENDERABLE` is a property of the run, and Part 2 defines it as one. What a definition of that shape does not settle is the case that dominates this population: a well-formed check whose named referent is absent, where a rater has no rule for telling an unrendered judgment from a rendered negative. **That ambiguity is downstream of the instrument rather than independent of it** — it exists only while the evidence set is undefined, because "the referent is absent" is a claim about a boundary nobody drew. With the evidence set closed and complete (Layer E above), the boundary is decidable by an ordered three-question procedure, asked in order and stopping at the first yes:

1. **Did the run decline, error, or emit no resolvable verdict token?** → `UNRENDERABLE`.
2. **Does the check's predicate quantify over an entity the pair-member's evidence set does not define — neither as present nor as absent?** → `UNRENDERABLE`.
3. **Otherwise the predicate has a truth value over that evidence set.** → `MET` where it holds; `NOT MET` where it does not, **including where it does not hold because evidence the check requires is absent from a surface the set defines**.

*Worked example, the `UNRENDERABLE` side.* A task check reading *"the task contributes to the Sprint Goal the Sprint Backlog commits to"*, judged against an evidence set containing the task alone. The set defines no Sprint and no Sprint Goal — not an empty one, none at all — so the predicate has nothing to quantify over and neither `MET` nor `NOT MET` would be a statement about the task. Question 2 fires. This is the case the materialized instrument removes by construction: its shared context defines a Sprint Goal, so the same check reaches question 3 and renders.

*Worked example, the `NOT MET` side.* A story check reading *"every entry in `acceptance_criteria` is met"*, judged against an evidence set that defines five acceptance-criteria entries and records satisfaction for three of them. The predicate is false over the set, so the verdict is `NOT MET` — and it stays `NOT MET` where the set defines the entries and records satisfaction for none, because **an absence on a surface the set defines is a rendered negative, not an unrendered judgment**. Coding that `UNRENDERABLE` would route a substantive negative through the judge-side indeterminacy code; since the consuming rule rounds absence to not-satisfied anyway, it would reach the same downstream state by a path that destroys the arm the measurement is made of.

**`UNRENDERABLE` is not a confidence code.** A rater who can render a verdict but holds it weakly renders it. Confining the code to questions 1 and 2 is what keeps it countable: an `UNRENDERABLE` is evidence about the check's evaluability, and one issued for low confidence is evidence about the rater's mood.

**Run-report contract.** Three runs whose verdicts cannot be mechanically joined produce no aggregate, and a parser that silently recovers a subset produces a *wrong* one. Each run therefore emits its verdict set in exactly this shape.

A header block, with these keys and no others:

```
run_id:             <label unique within the measurement>
instrument_version: <the Appendix A version token>
pair_members:       <the instrument's declared member count>
rows_emitted:       <data rows in the table below>
distribution:       MET <n> / NOT MET <n> / UNRENDERABLE <n>
presentation_order: <"instrument order" | the permutation actually used>
```

Then one table, with these five columns in this order:

| `pair_member` | `base` | `verdict` | `grade` | `basis` |
|---|---|---|---|---|

- **`pair_member`** — the Appendix A identifier, verbatim and backticked, of the form `` `<check_id>#<arm>` `` with `<arm>` exactly `conforming` or `violating`: one separator, no spaces, no alternative spelling. Three runs producing three table syntaxes for one data set is a reporting defect, not a data difference, and it is repaired by fixing the grammar rather than by widening the parser.
- **`base`** — the Appendix A base-item token this row was judged against. It is redundant against the instrument by construction, and that is its purpose: **it makes the cross-run item-identity check mechanical.** Two runs agree on the instrument iff their `base` columns agree row-for-row, which is a join rather than a forensic reconstruction of what each rater happened to draw.
- **`verdict`** — exactly one of `MET`, `NOT MET`, `UNRENDERABLE`.
- **`grade`** — exactly one of `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`.
- **`basis`** — one line, naming the evidence-set element the verdict turns on.

**The declared count is the parser's control arm.** `rows_emitted` MUST equal both the table's data-row count and `pair_members`. An aggregator that recovers fewer rows than `rows_emitted` has a broken parse, not a short run, and must repair the parse rather than aggregate the remainder — a row count never compared against a declared denominator is an unvalidated extraction, and reporting an aggregate over it states a result the data does not carry.

**Evidence-grading rubric.** `[SOURCE]` — derived from recorded per-run rows over a real item with every run context-isolated; **the minimum load-bearing grade, and the only one that enters the routing count.** `[INFERRED]` — derived from a projected item, a confounded pair, runs that were not context-isolated, **or a verdict that turns on a `[fixture]` element of the evidence set**; reported with its grade, recorded as a coverage gap, excluded. `[ASSUMPTION – CONFIRM]` — no runs completed; surfaced for disposition, never silently omitted from the table.

**Fixture-dependence is a grade, not a disqualification, and the distinction from `[pinned]` is where it bites.** A `[pinned]` element is a real fact supplied because the check quantifies outside the item — the verdict still rests on the world, so the row stays `[SOURCE]`-eligible. A `[fixture]` element is a constructed artifact this deployment does not carry, so a verdict resting on one measures judging-against-a-fixture and is graded accordingly. The grade is what makes supplying the fixture honest rather than an invention: without the element the check is unanswerable and contributes no arm, and with it the row contributes a diagnostic arm that is excluded from the routing count.

**Frame.** The criterion axis is a **census, not a sample** — every declared `level = "L3"` check, plus the two checks carrying `level = "L2"` together with `automatable = false` as a discriminating control. A census eliminates selection bias on this axis by construction rather than by mitigation. The control pair resolves empirically whether the operative axis is `level` or `automatable`: if the two pattern with the judgment set, the axis is `automatable`; if they pattern with the machine-evaluable `L2`, it is `level`.

**The control pair is structurally determined and cannot be substituted.** Those two checks are the only members of the declared set on which `level` and `automatable` diverge, so they are the only pair whose verdicts can resolve which axis is operative. Choosing a different pair because its referent happens to be present in this deployment would answer a different question — it would no longer be a control. What is available is the other side of the same problem: both name a written service-level policy this deployment does not keep, so the instrument supplies that referent as declared `[fixture]` context and both members render rather than declining. Their rows carry the `[INFERRED]` grade fixture-dependence obliges, which is the grade the Layer-D comparison they feed already carries — a control that contributes a diagnostic arm resolves more than one that contributes none.

## Validity Threats

Declared before the results, because a threat table written after a result is a rationalization of it.

| Threat | Mitigation, or the residual where none is available |
|---|---|
| **Selection bias on the criterion axis** | Eliminated by construction — the criterion axis is a census. No selection is made, so none can be biased. |
| **Selection bias on the work-item axis** | **Not eliminated, and not eliminable at this sample size.** Layer E draws **one** item pair per check by unconstrained hand-selection, while the per-check verdict is consumed as a property of the *check*, quantifying over all items of that kind. A judge that reads a criterion reliably on an obvious item and unreliably on a borderline one returns a lucky-draw verdict that nothing here would detect. **Every per-check verdict is therefore item-conditional**, and the results table names the item it is conditional on. The platform's own gate-efficacy standard states the residual in terms: a probe can carry a real sensitivity arm and a real specificity arm and still be wrong about the population it never sampled. Raising the draw to two items for the interpretive partition is the cheapest real remedy and is recorded as follow-on work, not claimed here. |
| **Correlated runs** | Runs must be context-isolated. Where neither realization is available, the degradation is reported, those results are graded `[INFERRED]`, and they do not enter the routing count. Same-context repetition inflates agreement toward certainty and would manufacture a false `gate-capable`. |
| **Mutations are easier than natural violations** | The violating twin is a **minimal single mutation** of a real item, not a synthetic worst case, which bounds the threat without eliminating it. A `gate-capable` verdict evidences decidability against a *clean* violation; it does not evidence robustness against a *subtle* one. |
| **Cross-check confounding of a minimal mutation** | The declared checks share fields, so one field-level mutation can break several checks at once and a flip is then attributable to the wrong one. Layer E's confound lookup records the other checks each mutation breaks; a non-zero count forces either an isolating re-derivation or an `[INFERRED]` grade and exclusion. |
| **Coverage gap — a kind with no natural population** | A deployment running one methodology has no natural population for the other's kind. Those checks are exercised by projecting items through the foreign kind; every such verdict is graded `[INFERRED]` and excluded from the routing count. |
| **Single un-replicated rater on Layers D and E** | **Not eliminated.** Layers D and E are hand-classified; only Layer B is run-derived. Applying the reproducibility standard to Layer B while exempting the two layers that produce Layer B's inputs would be the reviewer-posture failure of treating the author's confidence in a classification as evidence for it. Where a second independent classification pass is available it is run and its agreement reported; **where it is not, the whole partition column is graded `[INFERRED]` and the Layer-D-versus-measured comparison is diagnostic, not evidential.** |
| **Per-run item variation** | **Eliminated by construction, and only once the instrument is materialized.** While Layer E recorded mutation classes and left the item to the executing run, the item was a free variable: three runs drew three different item sets, so an agreement statistic over their verdicts could not discriminate *"this judgment is reproducible"* from *"these checks are easy regardless of which item you draw"*, and a disagreement could be an instrument difference rather than a rater difference. Appendix A removes the variable; the run-report contract's `base` column makes conformance to it a join rather than a reconstruction. The residual is the per-check item-conditionality in the row above, which this does not touch. |
| **Instrument authorship** | **Not eliminated.** Appendix A is authored by a single un-replicated rater who had sight of three completed runs' verdicts, which is a stronger selection risk than the row above: a selector who knows which rows diverged could, without intending to, choose evidence sets that make those rows easy. Two things bound it and neither removes it. The base items are **not novel** — each was drawn by one of the three prior runs, and Appendix A records which — so the pool was not authored to taste. And the selection rule is stated in item properties a reader can check without consulting any verdict: a readiness check binds to a pre-terminal item and a done check to a terminal one, and among the candidates the base is the one that makes the check's conforming arm **substantive rather than vacuous**. A conforming arm whose satisfaction the author reads as partial is declared `contested` in Appendix A rather than re-drawn until it passes, because re-drawing to make an arm unanimous is selecting on the outcome. |
| **Fixture-supplied context** | **Not eliminated; graded instead.** Several checks quantify over an artifact this deployment does not keep, and the instrument supplies it so the check renders. A verdict resting on such an element measures judging-against-a-fixture, so it is graded `[INFERRED]` and excluded from the routing count. The alternative — leaving the referent absent — is worse rather than more conservative: it yields `UNRENDERABLE` on both members, which under Part 2 is an `advisory-only` disjunct, so the check would be dispositioned unevaluable on the evidence that this deployment lacks an artifact rather than on anything about the check. |
| **A threat declared after a result** | This table is declared before the results it governs, and the three rows above were added before the runs they govern were executed. They govern the re-run of Layer B over the materialized instrument, not the Layer-D and Layer-E results already recorded below, and no row here was written to account for a result already in hand. Stated because the discipline is worth more than the convenience of leaving it implicit. |

## Results

**Layer D — decidability partition.** Every check in the frame as measured at the baseline recorded in `source_observations:` was classified, and every classification was determinate.

| Partition class | Count | Members |
|---|---|---|
| `graph-decidable` | **3** | the epic-decomposition check, and the two children-terminal checks (epic and story) |
| `field-decidable` | **0** | — |
| `interpretive` | **18** | every remaining judgment-level check in the frame, plus both control checks |

**Grade: `[INFERRED]` — single un-replicated rater, no second classification pass available to the session that ran it.** The comparison this column feeds is diagnostic, not evidential.

Three findings are worth the column even at that grade.

1. **The ordered procedure is decidable where the three-class criterion was not.** Applied as three named classes with no precedence rule and no completeness qualifier, the criterion left 7 of these 21 with no determinate class — 5 that satisfy two classes on their face, and 2 that turn on whether "field-decidable" means reading a field or judging what the field describes. The ordered form resolves all 21: asking the no-residue question *first* sends both presence-versus-satisfaction checks to `interpretive`, and traversal-precedence resolves all five multi-class cases.
2. **`field-decidable` is empty, and that is the informative half.** Both checks a literal reading would have landed there — *"every entry in `acceptance_criteria` is met"* and *"the epic states which product outcome it advances"* — name a genuinely declared field whose *presence* a machine-evaluable check already tests. What the judgment-level check adds is precisely the residue: whether the criteria are **met**, whether the stated outcome **is** a product outcome. The declared field is the subject of the judgment, never its resolution.
3. **Both control checks land `interpretive`, patterning with the judgment set rather than with the machine-evaluable `L2` check.** Read with their shared `automatable = false`, this is the evidence that **the operative axis is `automatable`, not `level`** — which is the divergence the census surfaced and which the per-kind authoring bar must settle.

**Layer E — falsification-pair confound lookup.** Every check in the frame was evaluated against the full declared check set as measured at the baseline recorded in `source_observations:` — in-frame and out-of-frame members alike.

| Mutation class | Check it targets | Other declared checks the same mutation breaks | Disposition |
|---|---|---|---|
| Clear the benefit field | the epic outcome-named check | the machine-evaluable epic-valuable check (and its story twin) | **CONFOUNDED** — an isolating mutation must corrupt the field's *content* rather than clear it |
| Clear the acceptance-criteria field | the story acceptance-criteria-met check | the machine-evaluable story-testable check | **CONFOUNDED** — isolation requires leaving the entries present and unmet |
| Delete the sole parent edge of a task | the task belongs-to check (machine-evaluable, out of frame) | — | not in frame |
| Delete the sole child edge of an epic | the epic-decomposition check | **none directly — but see the vacuous-pass interaction below** | ISOLATABLE |
| Clear the size field | the machine-evaluable story-estimable check | the story-small check is **not** broken — an absent estimate makes a story unestimated, not large | ISOLATABLE, by mutating scope prose rather than the field |
| Remove the implementation-approach clause | the story-negotiable check | none, provided the mutation *adds* prescriptive implementation prose rather than removing a declared field | ISOLATABLE |
| Every remaining in-frame check | — | no shared declared field or edge | ISOLATABLE |

**Two confounded pairs, both cross-level**, and both confound a judgment-level check with the machine-evaluable check over the same field. This is a structural property of the declared set rather than an artifact of one mutation choice: where a machine-evaluable check tests a field's *presence* and a judgment-level check tests its *adequacy*, clearing the field breaks both and a flip is not attributable.

**One vacuous-pass interaction, found while constructing the pairs and recorded because it is the defect class this release exists to eliminate.** Deleting the sole child edge of an epic falsifies the epic-decomposition check as intended — and **simultaneously makes the epic children-terminal check pass vacuously**, because "every child has reached a terminal state" is trivially true over an empty child set. A falsification pair for the first check is therefore a *specificity* trap for the second: a judge evaluating both against the same mutated item should return one flip and one pass, and a judge that returns two flips is reading a constraint that is not there. The children-terminal checks need an explicit empty-set clause before either is admitted to a gate, independent of how they measure.

**The vacuous pass is no longer a predicted interaction; it is a confirmed observation.** Three context-isolated runs, each drawing its own story item and none having seen another's output, independently returned `MET` on the story children-terminal check's conforming member over an item with **zero** child items, each naming the vacuity in its own basis line. The finding is **item-independent** — it holds for any item with an empty child set, which is the modal shape for a story in this corpus — so it survives the instrument confound that makes those runs' other verdicts unreadable, and it is the only Layer-B-derived finding that does. Two properties make it load-bearing rather than a curiosity. It is reached **without** the mutation that produced the predicted interaction, so the defect is in the check's own quantifier and not in a falsification pair's side effect. And the check's own unmodified conforming arm is where it surfaced, so a gate admitting this check would return its clean verdict on precisely the items that carry no plan at all. The admission precondition the paragraph above states is therefore owed on evidence, not on foresight; **where that clause lands is the consuming gate's placement decision**, which this record does not make.

The instrument records the same class as a construction rule rather than re-measuring it: Appendix A binds each children-terminal check to a base with a **non-empty** child set, so its rows measure the judgment instead of re-confirming a defect already confirmed. The vacuous case is recorded here; it is not re-run.

**Layer B — context-isolated repeated judgment. `NOT-EVALUATED`. This is not a clean result.**

Three context-isolated runs have been executed, each in a fresh context with no memory of a sibling and none having read another's output, and each rendering a verdict for **all 42** pair-members. The context-isolation property was satisfied. **What defeated the measurement is the instrument, not the isolation.**

All three runs independently reported the same root cause: this record stated that the instrument was prepared, but no concrete item-level pair-member set existed on any surface a run could read. Layer E recorded mutation *classes*, so **the item was a free variable and each run drew its own.** On the two checks where every run's base item is mechanically recoverable, the three drew three different items and none shared one. Their verdicts are therefore not comparable: an agreement statistic over verdicts rendered against different instruments cannot discriminate *"this judgment is reproducible"* from *"these checks are easy whichever item you draw"*, and a disagreement may be an instrument difference rather than a rater one. Three isolated raters converging on that structural finding is the strongest evidence those runs produced, and it is meaningful precisely because — unlike their verdicts — it is not item-dependent.

The runs also named three further underspecifications, each of which would have prevented a clean aggregate even over a shared instrument: the `NOT MET` / `UNRENDERABLE` boundary was undefined and accounted for most of the observed cross-run divergence, the verdict vocabulary was named by description rather than spelled, and no output shape was specified, so three runs emitted three table grammars for one data set. All four are repaired in § Methodology above and in Appendix A; the runs' verdict sets are not carried into this record, because a verdict set graded against an unrecorded instrument is not a measurement of anything this record can consume.

**The measurement state is recorded as absence, not as zero.** The per-check arm counts, agreement statistics and verdicts are **absent** from this record, not populated with nulls; a consumer must branch on this state before reading any count, because reading a count alone consumes *"nothing was examined"* as *"nothing was found"*.

**`G` — the count of judgment-level checks landing `gate-capable` or `gate-capable-under-conditions` at `[SOURCE]` grade — is `NOT-EVALUATED`.** It is emphatically **not 0**. A zero would be a measurement; this is the absence of one, and the distinction is the whole difference between *"these checks were tested and none passed"* and *"these checks were never tested."* Reporting the second as the first would reproduce, in the record that decides the question, exactly the vacuous-verdict failure this release exists to eliminate. That the runs executed cleanly does not move the state: **a clean run against an unrecorded instrument is still not a measurement**, and treating three completed runs as one would be the same substitution wearing better evidence.

**What is required to complete the measurement, stated so it is actionable rather than open-ended:** three context-isolated judgment runs over the 42 pair-members **recorded in Appendix A**, each run seeing every pair-member exactly once, rendering per the ordered procedure in § Methodology, and emitting the run-report contract's header and table. Isolation is required *between runs of the same pair-member*, which three fresh contexts satisfy — it does not require a fresh context per judgment. The frame is enumerated, the instrument is recorded, and the reporting shape is fixed; only the runs are outstanding.

## Routing Rule

The two consumers cite **this record** as the single verdict identifier. Neither restates the verdict.

**While `G` is `NOT-EVALUATED`, both consumers take the conservative branch, and they take it for different reasons.**

- **The per-kind authoring bar** ships its rubric with the enforceability dimension **declared and unresolved** rather than silently absent. Each rubric dimension states whether a per-kind rule instantiating it may gate; while the measurement is outstanding, every dimension reads *unresolved pending measurement*, and every per-kind rule still takes a gate-efficacy disposition. An unresolved enforceability dimension is not a licence to leave normative predicates standing and unrun.
- **The readiness and done gates** admit **no** judgment-level check. Non-admission under `NOT-EVALUATED` is the same act as non-admission under `G = 0`, but it is owed for a different reason and the record must say which: not *these checks were measured unevaluable*, but *these checks are unmeasured, and admitting an unmeasured check to a set whose rule rounds absence to failure is the failure mode this record exists to prevent.* The gates continue to evaluate the machine-evaluable checks and **report** the remainder explicitly — criteria present, not admitted, here they are — rather than passing over them silently.

**Once the measurement completes**, the routing keys on `G`:

| | **G ≥ 1** | **G = 0 (measured)** |
|---|---|---|
| **Authoring bar** | The rubric's enforceability dimension resolves per dimension. The bar is **mixed**: the passing subset gates; the remainder takes a named-gap disposition with a declared observable | The rubric ships as guidance and names no enforceable dimension. Every per-kind rule still takes a disposition — downgrade, or named gap with a declared observable |
| **Gates** | The passing subset is admitted, each admitted check carrying its recorded arm **counts**. The remainder is **explicitly excluded**, and that exclusion is the load-bearing engineering act | No judgment-level check is admitted. The remainder is reported, never admitted |

**The downstream obligation is stated over the aggregate, never as a named file edit in a consumer's write set.** This record constrains *which checks may be members of an any-fail criterion set*; where a consumer lands that membership rule is the consumer's own placement decision. A record that names another card's edit file makes a load-bearing claim it has no authority to verify.

**An admitted check's recorded reliability is a lower bound at the run count it was measured at.** A check admitted on unanimity at a small `r` may still gate nondeterministically, so an admitted check observed to flip on re-request is grounds to re-open its disposition against its recorded arm counts — not evidence that the admission rule was wrong.

## Alternatives Considered

- **Repeat-run self-consistency alone** — one judge, repeated runs over identical input, measuring the proportion of unanimous items. **Rejected on governance conformance:** an agreement claim with no sensitivity arm is a broken probe. Runs agreeing on the same *wrong* answer score perfectly and prove nothing, so this cannot distinguish a reproducible judge from a reproducibly-wrong one. Retained as a component (Layer B), never as the whole mechanism.
- **Independent-judge agreement alone** — two or more context-isolated judges over the same items. **Rejected as insufficient alone:** it answers whether the decision is *stable* and is silent on whether the check is *decidable at all*, so a check both judges reproducibly misread scores as capable. Retained as the strongest surviving single alternative and the opposing view to the chosen composition.
- **Gold-standard accuracy** — operator hand-labels a sample; measure agent-versus-gold accuracy. **Rejected on blast-radius ceiling and domain contraindication:** it requires an irreducible-human labelling pass and a gold-label artifact class the platform does not have, and the governance domain guide contraindicates research-grade practice where regulatory posture is internal and lightweight self-review is proportionate. Heavy ceremony on a proportionate-risk change is a tailoring failure.
- **Decidability pre-partition alone** — partition by decidability shape and measure only the interpretive residue. **Rejected as insufficient alone:** it answers whether a check is decidable *in principle* and produces no reproducibility evidence at all. Retained as Layer D.
- **Falsification-pair testing alone** — per check, a conforming and a minimally-mutated violating item; decidable iff the judge flips across the pair. **Rejected as insufficient alone:** a single run measures decidability and no reproducibility. Retained as Layer E.
- **A numeric agreement or kappa cut-point** as the admission bar. **Rejected as ungrounded and unrepresentable:** no such threshold exists anywhere in this corpus, three competing conventional values are in common use, and the consuming aggregate is ALL-PASS / ANY-FAIL with partial credit explicitly forbidden — it has no arm for a fractional score. A spike inventing a psychometric cut-point would be exactly the invented-canonical-value failure the authoring discipline forbids.
- **Introducing a fourth projection level, or re-levelling checks by measured evaluability.** **Rejected:** the level domain is declared closed because the projection is a three-way switch with no arm for a fourth value, and re-levelling would conflate two orthogonal axes — how a check projects into a schema, and whether its judgment is reproducible.

## Consequences

**Positive.**

- The admission question is answerable per check, which is the granularity at which it is actually decided. A single release-level verdict would have been wrong for both ends of a heterogeneous population.
- The verdict maps onto an existing disposition ladder, so there is one ladder for this behaviour rather than two.
- The ordered decidability procedure is reproducible where the three-class form was not, and it yields a determinate class for every check in frame.
- The empty `field-decidable` class is a durable finding for the authoring bar: where a machine-evaluable check tests a declared field's presence, the judgment-level check over the same field tests its adequacy, and the declared field is the subject of that judgment rather than its resolution.
- The confound lookup makes a structural property of the declared set visible: presence-versus-adequacy check pairs over one field cannot be falsified independently by clearing that field.

**Negative, and carried rather than closed.**

- **The measurement is outstanding.** `G` is unmeasured, the consumers take the conservative branch, and the authoring bar's enforceability dimension ships declared-and-unresolved. This is a named gap with a declared observable — the observable is the absent Layer-B columns in the results table above, which no reader can mistake for a clean result.
- **The bar's false-exclusion rate is real and recorded.** At the declared run count a genuinely reliable check is dispositioned advisory about half the time. The mitigation is the arm-count record, which keeps an exclusion re-openable against a number, not a larger run count.
- **Every per-check verdict will be item-conditional** at the specified draw of one item pair per check. Raising the draw for the interpretive partition is the cheapest real remedy and is follow-on work.
- **Layers D and E carry a single un-replicated rater**, and their outputs are graded accordingly rather than presented as measured.
- **Nothing validates the shape of a declared check.** The schema records this as a gap with no runner: a check could declare an out-of-domain level or a non-boolean automatable value and validate clean today. A disposition recorded into that structure is only as trustworthy as the absent runner, and this record does not close that gap.
- **A record with no consumer is a contract with no worked example.** The annotation this decision extends has no materialized instance anywhere in the corpus; the first instance is owed by whichever consumer admits or reports the first check.

## Reversibility

**MODERATE.** A recorded verdict is revisable by re-running the protocol, and the two edits this record lands are additive and independently revertible. It crosses to **EXPENSIVE** once the consumers read it: at that point the pack surface is a live read contract rather than a declarative manifest, and the grammar the disposition rides on becomes expensive to change — the same crossing the methodology-pack composing-unit record names for the surface this one extends.

## Related ADRs

- **ADR-018 — Work-Item Type Layer.** Establishes the thin generic work-item entity plus the declarative type layer whose criteria checks this record dispositions. This record adds no entity and no level; it annotates members of the type layer's check records.
- **ADR-069 — Methodology pack as the composing unit.** Keeps the public corpus methodology-neutral and homes concrete rows in the selected packs. This record's per-check disposition rides the check record inside the pack, which is where that decision puts concrete content. Its reversibility note names the same declarative-to-consumed-contract crossing recorded above.
- **ADR-033 — Methodology-conditional activation and canonical-row sourcing.** Homes archetype-specific parameterization at the per-archetype surface rather than as a column on a shared high-blast-radius document; the disposition follows that placement.
- **ADR-181 — ADR citations bind at the claim, not at authorship.** Why the schema's prose cites this record by slug token rather than by literal number: the number allocated at authorship is claimed at merge, and a long-lived branch is exposed to every sibling that merges ahead of it.

## References

- Issue #6364 — *Determine whether L3-judgment checks are agent-evaluable.* The spike this record answers. It asks whether a judgment-level criterion can be evaluated reproducibly by an agent, requires that inter-run agreement be measured and reported rather than asserted, and requires a verdict recorded as advisory-only, gate-capable, or gate-capable under stated conditions.
- Issue #6367 — the per-kind authoring bar, one of the two consumers of this record's verdict. Its rubric's enforceability dimension resolves from the routing rule above.
- Issue #6369 — the readiness and done gates, the other consumer. Its admission decision is governed by Part 5 above.

## Provenance

The base items of the Appendix A instrument, named here because an instrument whose items cannot be traced is not auditable, and named *only* here because the instrument itself identifies them by token so that a renumber or a migration cannot invalidate it. Each was drawn by one of the three executed Layer-B runs; none was authored for this record.

- Issue #6442 — instrument base `E1`. A pointer-umbrella epic, pre-terminal, declaring five child items, a capability-outcome statement and an in-scope enumeration of its split.
- Issue #1962 — instrument base `E2`. A terminal epic with four child items, three closed as completed and one closed as not planned, carrying a capability-outcome statement and an out-of-scope clause routing the undelivered scope to a named successor band.
- Issue #6426 — instrument base `S1`. A pre-terminal story carrying a size, a value statement, five acceptance-criteria entries and no declared dependency edge.
- Issue #6363 — instrument base `S2`, and the projected base `C2`. A terminal story carrying five acceptance-criteria entries and no child items, delivering the provenance-key convention the Appendix A pinned facts verify.
- Issue #4455 — instrument base `S3`. A terminal story with four child items, all terminal — the non-empty child set the story children-terminal binding requires.
- Issue #6438 — instrument base `T1`, and the projected base `C1`. A pre-terminal task naming the file, the section and the exact edit it proposes.
- Issue #1772 — instrument base `T2`. A terminal task declaring a parent edge, whose record states its determination and its full resolution.

## Appendix A — The Layer-E instrument

**Instrument version token:** `ADR-195-INSTRUMENT-v1`. **Members:** the frame's checks × {`conforming`, `violating`} — as of the baseline, 42.

**Every fact in this appendix is frozen at the baseline recorded in `source_observations:`.** It is an instrument record, not a live reading: a later edit to a source item does not change what this appendix says, and is not meant to. That is the point of recording it here rather than pointing at the tracker — a pointer to a mutable record is a free variable wearing a citation.

### A.1 — How a member is judged

A pair-member is `` `<check_id>#<arm>` ``. Its **evidence set** is exactly what this appendix records for it: the shared context of A.2, plus its base item's block in A.3, plus its own binding in A.4. **A fact outside that set is not available to the judgment.** A run that consults the live tracker, the repository, or its own recollection in order to decide a member has left the protocol, and its verdict is not comparable with a run that did not.

Every element carries one of three classes. **`[item]`** — a verbatim fragment or a declared structural fact of a real, unmodified base item. **`[pinned]`** — a real fact about the repository or the tracker at the baseline, supplied because the check quantifies outside the item. **`[fixture]`** — a constructed artifact this deployment does not carry. A verdict turning on a `[fixture]` element is graded `[INFERRED]` and excluded from the routing count; `[item]` and `[pinned]` elements keep a row `[SOURCE]`-eligible.

Quoted `[item]` fragments are verbatim with one uniform normalization: **an outbound work-item reference is rendered `<item-ref>`**, because under the closed-world rule a pointer to something outside the evidence set is not judgeable content and would invite the rater out of the set. The normalization touches no wording any bound check turns on.

A binding's **conforming arm** is annotated `substantive` or `contested`. `contested` records that the instrument author reads the conforming member as satisfying the check on partial evidence. It is a declaration, not a hedge: the alternative is re-drawing until the arm passes, which is selecting on the outcome and would manufacture the false `gate-capable` this design exists to prevent. **The annotations are aggregator-side.** A run is given A.1 through A.3 and the check statements; it is not given A.4's arm labels, because a rater told which member is the conforming one returns the specificity arm by construction and measures nothing. Where that separation cannot be realized, the run says so and its specificity-arm results are reported as unblinded.

### A.2 — Shared context

Supplied because the frame's checks quantify over artifacts that are not properties of any item. Without it the instrument would manufacture the `UNRENDERABLE` verdicts it exists to measure.

**`CTX-DOD`** `[fixture]` — the done standard in force for the team, in three elements: (a) the convention the change introduces is documented where an author of that content will find it; (b) no defect raised against the change is left open at closure; (c) the change carries a recorded reviewer acceptance.

**`CTX-SPRINT`** `[fixture]` — a Sprint is in progress. Its Sprint Goal: *the provenance a reader follows from a seeded record resolves to the protocol's home in one hop.*

**`CTX-SERVICE`** `[fixture]` — a Kanban service with two written policies. **Pull policy for the receiving state:** an item may be pulled only if (i) it has passed the commitment point and (ii) it carries a size and a named owner. **Exit policy for the final state:** an item may leave only if (i) the requesting customer's acceptance is recorded and (ii) every defect raised during its flow is closed or re-filed.

**`P-PACKS`** `[pinned]` — at the baseline, the repository carries three pack manifests (`_common`, `scrum`, `kanban`), and every declared check row and kind-specific field row in the two archetype manifests carries a non-empty `source` key naming a body of practice — as of that baseline, 34 of 34 rows, with both control arms observed.

**`P-MAINLINE`** `[pinned]` — at the baseline, all three pack manifests are present on the mainline branch, with both control arms observed.

### A.3 — Base items

**`E1` — epic, pre-terminal.** Structural `[item]`: child items declaring `BELONGS_TO` = **5** (four terminal, one pre-terminal); `as_a` / `i_want` / `so_that` = **not declared on this item**; no delivery milestone assigned. Body `[item]`, verbatim:

```
## Capability Outcome

The platform's operating rules reach every session they are written for; the
directory they arrive in has a published admission test and a measured budget;
and the links inside a mirrored rule resolve from the location it is read in.

BEFORE: The rules surface has a contract and a drift check but no carrier, so a
rule can be authored, reviewed, merged and verified while being read by nobody.

## Scope

In:
- The carrier that populates the mirror, and the second-half routing gap that
  leaves operations-scoped sessions loading nothing — <item-ref>
- Corpus admission criteria, classification of the pair set, and the
  session-start load budget — <item-ref>
- Cross-tree link resolution from the mirror location, and the stale spec clause
  that mandates the wrong link form — <item-ref>
- Parity between the enforced mirror-pair array and the blast-radius topology
  detector — <item-ref>
- The instruction-file relocation that depends on a bounded, admission-tested
  destination — <item-ref>
```

*Excluded, and why:* the source item's candidate-child-items table restates the in-scope enumeration above item-for-item, and its sequencing section states edge kinds rather than the split. Neither adds a fact a bound check turns on.

**`E2` — epic, terminal.** Structural `[item]`: child items = **4**; three closed as completed, one closed as **not planned**, that one closed before the epic itself. Body `[item]`, verbatim:

```
### Capability / Outcome
Establish the methodology-pack as the plug-and-play unit that bundles, per
delivery_approach archetype, a methodology's kinds + statuses + fields + labels
+ body-schema + gates — shipped as best-practice defaults in-repo, selected via
operator config, overridable per project.

### Scope
- In: the founding ADR; the core/packs/{_common,scrum,kanban} scaffold; widening
  the type-pack grammar to the methodology-pack; the cross-cutting control-field
  layer.
- Out: the remaining 6 archetype packs + deploy-time sync (Band 2 · Pack Catalog).
```

**`S1` — story, pre-terminal.** Structural `[item]`: declared `DEPENDS_ON` / `BLOCKS` edges = **none** (the body carries one untyped cross-item mention, which is a see-also and not a typed edge); size = M; story points = 3; acceptance-criteria entries = 5; child items = 0. Body `[item]`, verbatim in part:

```
### Value
Native links are the only relationship record that boards, filters and tooling
can consume — but today they drift from the relationships stated in issue
bodies, so prose becomes the de-facto record and every downstream consumer
re-scrapes it. Keeping the two mirrored means sequencing tools read typed,
directed edges instead of guessing, vertical rollups stay navigable without
opening bodies, and backlog audits stop re-finding the same unlinked pairs.

### Acceptance Criteria (first entry, quoted; four further entries declared)
- A research note enumerates the current-tooling surfaces evaluated and records
  the chosen mechanism with rationale
```

**`S2` — story, terminal.** Structural `[item]`: acceptance-criteria entries = **5**; child items = **0**; a declared parent edge. Body `[item]`, verbatim:

```
### Value
Every field and criterion in a shipped kit names the body of practice it came
from, so a reviewer can tell whether a criterion derives from a named
methodology or from one team's local habit.

### Acceptance Criteria
- A source key is declarable on kit fields and criteria
- The key projects into the materialized schema as an annotation, following the
  existing provenance-key pattern rather than a new mechanism
- All shipped kit content carries a source naming a specific body of practice,
  not a generic label
- The completeness lint can read the annotation and report content with no source
- The convention is documented where a kit author will find it
```

Satisfaction `[pinned]`: `P-PACKS` establishes the first and third entries. **The second, fourth and fifth are not recorded as satisfied on any surface this evidence set can carry**, and that is a property of the corpus rather than of this draw — see the binding in A.4.

**`S3` — story, terminal.** Structural `[item]`: child items = **4**, all terminal. Body `[item]`: the item states that four named ledgers record one fact, that three should be generated from the fourth, and names the files each change touches.

**`T1` — task, pre-terminal.** Structural `[item]`: a declared parent edge; size = XS; acceptance-criteria entries = 2. Body `[item]`, verbatim:

```
### Proposed Change
Change the provenance citation seeded records inherit (project-schema.md §7
emit text) to point at project-schema.md §7 'Entity-Seeding Protocol' with
ADR-138 named as the authorizing decision; leave operator-side backfill at
operator discretion.

### Affected Files
core/schemas/project-schema.md §7 (the emit text records inherit);
core/ADRs/ADR-138-project-entity-axis-1-carrier.md
```

**`T2` — task, terminal.** Structural `[item]`: a declared parent edge; size = XS; `Dependencies` = none known; nothing on the record is named deferred. Body `[item]`, verbatim in part:

```
### Proposed Change
Under the Bridge Files (Layer 3) heading, add a single scope sentence before the
table stating that it lists only cross-domain bridges — files one agent writes
and the other reads — and pointing to § Session Management for the session and
account bridges, which are managed within a single domain.

No table rows are added.
```

**`C1`, `C2` — card, projected.** `C1` is `T1` and `C2` is `S2`, each read through the foreign `card` kind against `CTX-SERVICE`. This deployment has no natural card population, so **every card row is `[INFERRED]` and excluded from the routing count** under the declared coverage-gap threat, independently of its fixture-dependence.

### A.4 — The bindings

Each binding names the base, the grade its evidence classes oblige, the conforming arm's annotation, the literal violating delta, and the isolation basis.

**`dor-epic-decomposed`** · `E1` · `[SOURCE]` · substantive
Delta: structural fact `child items declaring BELONGS_TO = 5` → `= 0`.
Isolation: no declared field changes. The two children-terminal checks bind to `E2` and `S3`, so the vacuous-pass interaction recorded in § Results cannot arise inside this instrument — the mutation and the check it would trap are never applied to one item.

**`dor-epic-splittable`** · `E1` · `[SOURCE]` · **contested**
Delta: the `## Scope` In block replaced in full by `In: The rules surface, end to end.`
Isolation: outcome text and edge count untouched.
Contested because `E1` names five discrete slices and their order but does not address the predicate's second conjunct — that each is doable within one Sprint — and no item in this corpus addresses it. The author's reading is that naming the split satisfies the check; the reading is declared rather than resolved by re-drawing.

**`dor-epic-outcome-named`** · `E1` · `[SOURCE]` · substantive
Delta: the `## Capability Outcome` paragraph replaced in full by `The team will keep the rules directory tidy and review it each release.` — present and non-empty, naming a working practice rather than a product outcome.
Isolation: this is the corrupt-the-content mutation Layer E prescribes over clearing the field. Here the confound it guards against is moot as well: the machine-evaluable epic-valuable check reads three fields `E1` does not declare.

**`dod-epic-children-terminal`** · `E2` · `[SOURCE]` · substantive
Delta: structural fact `child items = 4, all terminal` → `= 4, of which three terminal and one pre-terminal`.
Isolation: the edge count is unchanged, so the vacuous-pass trap is not engaged; a pre-terminal child is not an undelivered item closed alongside the epic, so the remainder check is unaffected.

**`dod-epic-outcome-realized`** · `E2` · `[SOURCE]` · substantive
Conforming rests on `P-PACKS`, which evidences realisation independently of child closure — the clause the check's *"not merely that its items closed"* requires.
Delta: the outcome clause restated as `... and all eight archetype packs, with deploy-time sync` — children and closure states unchanged, so `P-PACKS` makes the named outcome demonstrably unrealised.
Isolation: no child edge, closure state or out-of-scope clause changes.

**`dod-epic-remainder-returned`** · `E2` · `[SOURCE]` · **contested**
Conforming is substantive rather than vacuous: `E2` has a genuine antecedent — one child closed **not planned** before the epic closed — and the out-of-scope clause routes the corresponding scope to a named successor band.
Delta: structural fact added — the not-planned child's scope is carried by no successor item and is named nowhere after closure.
Contested because whether routing scope to a named successor band is *returning the item* is exactly the judgment the check makes. That the arm is live rather than empty is what makes the row worth running.

**`dor-story-independent`** · `S1` · `[SOURCE]` · substantive
Delta: structural fact `declared DEPENDS_ON / BLOCKS edges = none` → `declared DEPENDS_ON edge = one, to a pre-terminal item`.
Isolation: no body content changes. The conforming member carries a deliberate near-miss — an untyped cross-item mention the check must not read as an edge.

**`dor-story-negotiable`** · `S1` · `[SOURCE]` · substantive
Delta: append to `### Value` — `Implement this as a scheduled workflow calling the existing census probe through the REST dependencies endpoint; do not use GraphQL, and do not add a new detector module.`
Isolation: the mutation **adds** prescriptive prose rather than removing a declared field, per Layer E's stated direction, so the testable and estimable machine checks are unaffected. It names no new deliverable, so the small check is unaffected.

**`dor-story-small`** · `S1` · `[SOURCE]` · substantive
Delta: append to `### Value` — `Scope also covers backfilling every unmirrored body-stated pair across the open backlog and migrating every downstream consumer off body-scraping.`
Isolation: scope prose widens and the size field is untouched, per Layer E's stated direction, so the estimable machine check is unaffected.

**`dod-story-definition-of-done-met`** · `S2` + `CTX-DOD` · `[INFERRED]` (fixture) · substantive
Conforming: `CTX-DOD`'s three elements hold against `S2`'s record and `P-PACKS`.
Delta: structural fact added — one defect raised against the delivered change is open at closure, falsifying `CTX-DOD` element (b).
Isolation: element (b) is named by no acceptance-criteria entry of `S2` and by no clause of `CTX-SERVICE`, so neither the acceptance-criteria check nor either card policy check is touched.

**`dod-story-acceptance-criteria-met`** · `S2` · `[SOURCE]` · **contested**
Delta: entries left present, one annotated as not satisfied — the isolating form Layer E prescribes, which leaves the testable machine check unaffected.
Contested, and the reason is structural rather than a property of this draw: **this corpus records no per-criterion satisfaction for a terminal item**, so the conforming arm's evidence is the delivered artifact (`P-PACKS`, covering two of five entries) rather than the record. Two of the three executed runs reached a negative on this arm for exactly that reason. The instrument declares the condition instead of curating around it — supplying satisfaction facts the corpus does not keep would make the arm pass by authorship, which is the failure this design exists to prevent. If the arm fails unanimously, the reading is not that the judge is unreliable: it is that admitting this check to an any-fail set over a corpus that never records per-criterion satisfaction would block every story, which is Part 5's first disjunct and a real result.

**`dod-story-children-terminal`** · `S3` · `[SOURCE]` · substantive
Delta: structural fact `child items = 4, all terminal` → `= 4, of which three terminal and one pre-terminal`.
Isolation: `S3` is bound here rather than `S2` precisely because its child set is **non-empty** — the vacuous pass over an empty set is already a confirmed observation in § Results and is recorded there, not re-measured here.

**`dor-task-actionable`** · `T1` · `[SOURCE]` · substantive
Delta: `### Proposed Change` replaced in full by `Fix the provenance citation story across the platform.`, and `### Affected Files` by `Various.`
Isolation: the declared parent edge is untouched, so the belongs-to machine check is unaffected.

**`dor-task-serves-sprint-goal`** · `T1` + `CTX-SPRINT` · `[INFERRED]` (fixture) · substantive
Delta: `### Proposed Change` replaced in full by `In the CI workflow definition, bump the runner image to the current LTS and re-pin the lint toolchain version.`
Isolation: the replacement still names a file, a section and a startable edit, so the actionable check is unaffected — the mutation moves what the work *serves*, not whether it can be started.

**`dod-task-parent-done-standard`** · `T2` + `CTX-DOD` · `[INFERRED]` (fixture) · substantive
Conforming: `T2`'s delivered output meets `CTX-DOD`, and the check's second conjunct — that a task is not separately releasable — is decidable from `T2`'s record.
Delta: structural fact added — the delivered output makes the edit the task names but omits the companion pointer `CTX-DOD` element (a) requires, **and that omission is raised as its own item**.
Isolation: raising the omission is what keeps the no-implicit-remainder check unaffected; without that clause the same delta would break both, which is the confound this derivation exists to avoid.

**`dod-task-no-implicit-remainder`** · `T2` · `[SOURCE]` · substantive
Delta: append to `### Notes` — `The companion amendment named under Risks was not made; it is noted here and is not tracked as its own item.`
Isolation: the appended remainder is scope **outside** the task's own named output, so the task's output stays complete to `CTX-DOD` and the parent-done-standard check is unaffected.

**`kanban-dor-pull-policy-explicit`** · `C1` + `CTX-SERVICE` · `[INFERRED]` (fixture, projected) · substantive · **CONTROL**
Conforming: `CTX-SERVICE`'s pull policy is written down, and `C1` satisfies both clauses.
Delta: structural fact — the card enters the receiving state carrying no size and no named owner, falsifying clause (ii).
Isolation: clause (i) — the commitment point — is untouched, so the commitment-point check is unaffected.

**`kanban-dor-commitment-point-reached`** · `C1` · `[INFERRED]` (projected) · substantive
Delta: the card's committed status reverted to the pre-triage candidate value and its delivery milestone removed, returning it to a discardable option.
Isolation: size and owner are untouched, so the pull-policy control's clause (ii) is unaffected — the two card readiness checks are falsified through different clauses by design, since a shared mutation would make the control uninterpretable.

**`kanban-dod-exit-policy-satisfied`** · `C2` + `CTX-SERVICE` · `[INFERRED]` (fixture, projected) · substantive · **CONTROL**
Conforming: `CTX-SERVICE`'s exit policy is written down, and `C2` satisfies both clauses.
Delta: structural fact — the requesting customer's acceptance is not recorded, falsifying clause (i).
Isolation: the exit policy's clauses name neither mainline presence nor the flow record, so the delivery-point and flow-record checks are unaffected.

**`kanban-dod-delivery-point-reached`** · `C2` · `[INFERRED]` (projected) · substantive
Conforming rests on `P-MAINLINE` — delivered rather than merely finished by the people working it, which is the clause the check's own gloss requires.
Delta: `P-MAINLINE` replaced for this member by — the work is complete on an unmerged branch and is present on no mainline.
Isolation: the two flow instants and the exit-policy clauses are untouched.

**`kanban-dod-flow-record-complete`** · `C2` · `[INFERRED]` (projected) · substantive
Conforming: the tracker's event record carries both instants — the dated application of the committed status and the dated closure.
Delta: structural fact — the card is recorded as created already-committed, with no dated commitment event, so only the delivery instant is statable.
Isolation: mainline presence is untouched, so the delivery-point check is unaffected.

### A.5 — Presentation

A run sees every pair-member exactly once. The declared presentation order interleaves arms so that adjacency does not reveal pairing; a run that instead draws its own permutation records it in the run report's `presentation_order` key, so a within-kind anchoring effect is a readable property of a run rather than an unrecorded one.
