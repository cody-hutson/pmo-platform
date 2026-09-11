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

The per-run judgment vocabulary is the platform's existing binary per-criterion enum plus an `UNRENDERABLE` code for a run that declines or errors. No fourth gate-verdict value is introduced, so the consuming reduction's closed three-value verdict set is untouched.

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

**Layer B — context-isolated repeated judgment.** `r = 3` runs per check-and-pair-member, **each from a fresh context carrying no memory of a prior run**. Context isolation is specified as a **property** with two sanctioned realizations — independent sessions mediated by the orchestrating session, or a fresh sub-agent invocation per run. Repeated judgments inside one context are correlated by construction and inflate agreement toward certainty, which would manufacture a false `gate-capable`; the property is what the measurement rests on, and the realization is free.

**If neither realization is available, the measurement degrades to same-context repetition. That degradation is reported explicitly, its results are graded `[INFERRED]`, and they do not enter the routing count.**

**Evidence-grading rubric.** `[SOURCE]` — derived from recorded per-run rows over a real item with every run context-isolated; **the minimum load-bearing grade, and the only one that enters the routing count.** `[INFERRED]` — derived from a projected item, a confounded pair, or runs that were not context-isolated; reported with its grade, recorded as a coverage gap, excluded. `[ASSUMPTION – CONFIRM]` — no runs completed; surfaced for disposition, never silently omitted from the table.

**Frame.** The criterion axis is a **census, not a sample** — every declared `level = "L3"` check, plus the two checks carrying `level = "L2"` together with `automatable = false` as a discriminating control. A census eliminates selection bias on this axis by construction rather than by mitigation. The control pair resolves empirically whether the operative axis is `level` or `automatable`: if the two pattern with the judgment set, the axis is `automatable`; if they pattern with the machine-evaluable `L2`, it is `level`.

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

**Layer B — context-isolated repeated judgment. `NOT-EVALUATED`. This is not a clean result.**

Neither sanctioned realization of the context-isolation property was available to the session that executed this decision: it is not the orchestrating session, so it cannot mediate independent sessions, and it operated under an explicit standing instruction not to spawn. The remaining path is same-context repetition, whose agreement is inflated toward certainty by construction — so running it would have produced 126 rows that look like data and carry no reliability information, every one of them `[INFERRED]` and excluded from the routing count in any case.

**The measurement was therefore held rather than degraded, and the state is recorded as absence, not as zero.** The per-check arm counts, agreement statistics and verdicts are **absent** from this record, not populated with nulls; a consumer must branch on this state before reading any count, because reading a count alone consumes *"nothing was examined"* as *"nothing was found"*.

**`G` — the count of judgment-level checks landing `gate-capable` or `gate-capable-under-conditions` at `[SOURCE]` grade — is `NOT-EVALUATED`.** It is emphatically **not 0**. A zero would be a measurement; this is the absence of one, and the distinction is the whole difference between *"these checks were tested and none passed"* and *"these checks were never tested."* Reporting the second as the first would reproduce, in the record that decides the question, exactly the vacuous-verdict failure this release exists to eliminate.

**What is required to complete the measurement, stated so it is actionable rather than open-ended:** three context-isolated judgment runs over the 42 prepared pair-members, each run seeing every pair-member exactly once in an independently randomized order. Isolation is required *between runs of the same pair-member*, which three fresh contexts satisfy — it does not require a fresh context per judgment. The instrument is prepared and the frame is enumerated; only the runs are outstanding.

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
