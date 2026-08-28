<!-- reference-durability: allow-link -->
---
title: ADR-144 — G1-03 admits a second evidence shape: label-position probe markers, two co-present, Evidence-section-scoped
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-24
release: pipeline-spec-self-consistency
deciders: "Workspace owner. Design decision rendered at Stage 5 Solutioning for the G1-03 evidence-shape card and accepted by the hub at Procedure 4; the card deferred the marker set, the co-presence rule, and the layer split, and was silent on predicate scope, which is why this record exists."
supersedes: none
tags: [governance, intake, gate-criteria, g1-03, evidence, predicate-design, measurement-led, probe-discipline, reversibility-cheap]
source_observations:
  - "The gate did not recognise the platform's own codified evidence form. A body carrying a full probe record — invocation, denominator, both control arms, verdict — and no bracket token scored G1-03 FAIL, because the predicate matched only the five bracket labels."
  - "The convention it failed to recognise is not folklore. It is `review-discipline-principles.md` § 8.2, the copy-paste probe record, whose `PV-0`..`PV-7` element IDs are declared stable and citable individually."
  - "Measured, not argued. Eight candidate rules were run over 239 applicable open cards (203 declaring an Evidence section) plus six fixtures. Only one rule landed all six arms correctly."
  - "The most attractive option was rejected on evidence. A structured `invocation + grounding` rule mirrors the G1-05a pattern-(d) co-presence precedent exactly and is semantically the best fit — and it admits **2 of 239**, because the dominant corpus shape states the measurement in prose and labels only the control arm."
  - "The strict bold render was rejected for the same class of reason: only **5 of 203** Evidence sections use it, so canonicalizing it would invent a value the corpus does not use."
  - "Label-shape, not word-count, does the specificity work. A synthetic body carrying all six marker words as running prose scores **0** under the selected rule and FAILs."
  - "The spec and the tool disagreed about where evidence must live. The criterion row scoped G1-03 to the Evidence section; the implementation grepped the whole body. **9 of 239** bodies passed today only via a bracket token sitting outside their Evidence section."
  - "That divergence made the card's own acceptance fixture vacuous: the fixture named as a must-PASS carries 7 bracket tokens in the body and **0** inside its Evidence section, so it already passed the whole-body predicate before any widening."
  - "The widening is not a loosening into a never-FAIL check. Under the selected rule **109 of 239** bodies still FAIL, 36 of them for declaring no Evidence section at all."
  - "The card's headline figure does not reproduce. Re-derived at the design anchor, the probe-only cohort is 49% under a loose word-match and **4.4%** under the specificity-preserving rule; the defect is confirmed live, the 30% figure is a stale loose-probe artifact."
---

# ADR-144 — G1-03 admits a second evidence shape: label-position probe markers, two co-present, Evidence-section-scoped

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `144` was derived at Engineering time, immediately before this file was authored, via `release/tools/renumber-adr.py`. The oracle reported `ANCHOR 141 origin/main` and `NEXT-FREE 142`; `--detect` reported `CLAIMED-SET-BRANCH-ONLY 142,143 (detection only — never binds)` with both claims `BINDS`. `142` and `143` are therefore already bound on this same release branch by the records authored in the two earlier builds, and `144` is this branch's contiguous next, with the mainline reaching `ADR-141` and no hole beneath any claim. The number was deliberately **not** reserved at design time — the oracle is a *read*, not a reservation, which is exactly why three Stage-5 spokes in this release independently specified `142`. Sibling unmerged release branches claim overlapping numbers; those claims are **detection-only and do not bind**, and stepping past them to be safe would land a gap. The asymmetry is the whole rule: a duplicate is mechanically renumberable by this same tool at merge time, whereas a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole.

## Context

G1-03 is one of six structural Gate-1 criteria — auto-checked, FAIL-capable, and the only structural enforcement point the platform has for the no-invention discipline. It read:

> Evidence contains >=1 evidence-labeled claim

and the implementation matched exactly one thing: a bracket-form token from the five-label evidence vocabulary.

The platform, meanwhile, codifies a **second** evidence form. `review-discipline-principles.md` § 8.2 specifies a copy-paste probe record whose field labels are `Probe:` / `Denominator:` / `Control — sensitivity:` / `Control — specificity:` / `Extraction:` / `Result:` / `Measurement state:` / `Verdict:`, with `PV-0`..`PV-7` element IDs declared stable and citable individually. Authors follow it. A body that reports what it ran, over what denominator, with both control arms named and a verdict stated, is carrying *more* evidence than a bracket token conveys — and G1-03 returned it to the author as unevidenced.

So the gate was returning conforming authors to rewrite evidence that was already better than the form it demanded. That is the defect, and it is confirmed live: a real card carrying six probe-record markers and zero bracket tokens is a genuine true positive of the old predicate.

A second, deeper problem surfaced during design and forced a decision the originating card had not anticipated. **The criterion and its implementation disagreed about where evidence must live.** The criterion row said "Evidence contains"; the tool grepped the whole issue body. Nine of 239 open applicable cards passed only because a bracket token sat somewhere else entirely — in `Proposed Change`, or in an `Affected Files` list. This is the same spec-versus-tool divergence class this release exists to remove, sitting inside the very criterion being edited.

It also made the card's own acceptance criteria ungradable. One of the two fixtures named as a must-PASS carries seven bracket tokens in its body and none inside its Evidence section. Against the whole-body predicate it **already passed** before any widening. Recording a PASS for it after the change would have recorded a PASS the change did not cause.

## Decision

**G1-03 admits evidence in either of two shapes, and reads both from the `### Evidence` section only.**

- **(a) Evidence-label form** — at least one bracket-form token: `[SOURCE]` / `[INFERRED]` / `[CONTEXT]` / `[ASSUMPTION – CONFIRM]` / `[RECOMMENDED]`. Unchanged.
- **(b) Probe-record form** — at least **two distinct** markers from the closed set `probe` · `denominator` · `control` · `sensitivity` · `specificity` · `verdict`, **each in label position** (the marker word terminated by `:` or a dash, optionally emphasised).

The criterion's identity is untouched: same ID, same `field` type, same `Check = structural`, same `auto` automation, same `req | req | n/a` applies-to triple. Shape (b) is a **second admissible shape within one criterion**, not a new criterion — following the precedent set when G1-05a gained a fourth admissible pattern and explicitly held its type, check and automation columns unchanged so the Gate 1→2 `structural_pass_rate` denominator stayed fixed. It stays fixed here too, at six structural G1 rows.

### The two principles

**A gate that enforces an evidence discipline must recognise the evidence forms the platform itself codifies.** The marker set is not a Stage-5 invention: it is § 8.2's own field vocabulary, filtered by observed corpus use. Two § 8.2 fields were excluded on measurement rather than preference — `measurement state` occurs **0** times across 203 Evidence sections (a valid zero: `probe` returned 58 in the same invocation, so the probe fires), and `extraction` occurs 12 times but never in label position in a probe-only body, so it contributes no discrimination.

**A widened predicate owes a falsification arm.** Loosening an evidence check without one converts a real control into a check that cannot fail. Under the selected rule **109 of 239** bodies still FAIL, 36 of them for declaring no Evidence section at all — and the shipped self-test asserts the negative directly: an evidence-free body and a prose-about-probes near-miss must both still FAIL. A recorded PASS without its paired FAIL would not have been evidence that the widening was safe.

### Why label position, and why two

The **label-shape** constraint does the specificity work — not the count. A synthetic body carrying all six marker words as running prose scores **0** and FAILs, because it carries no marker in label position. That is the difference between a body *reporting* a probe and one *discussing* probes, and it is the entire reason a loose word-match was unusable.

The **two-marker** count then closes the residual that a label-shaped floor of one leaves open: `Verdict: this is broken.` is a label with nothing behind it. Requiring two distinct markers means a record must name both *what was measured* and *how it was grounded*. This is the same co-presence discipline the platform already applied to G1-05a pattern (d), admitted "only when both tokens are co-present."

**Accepted residual, stated rather than hidden.** The predicate is lexical. A body writing `Probe:` and `Denominator:` above worthless values passes. That is correct scoping — G1-03 is a **structural** criterion; evidence *quality* is judgment territory and is deliberately not being moved here.

### Why the Evidence section, for both shapes

Scoping only the new arm would have produced an unexplainable predicate — bracket tokens admissible anywhere, probe markers only in one place. Scoping neither would have left the acceptance criteria vacuous and perpetuated a live spec-versus-tool divergence inside the criterion being edited. So both arms move together, and the criterion row — which already said "Evidence contains" — becomes the true statement of what the tool does.

The risk was measured rather than asserted. The nine affected bodies sit across eight buckets — seven other milestones and one un-milestoned card; **zero** are in the deploying milestone. The gate evaluates only the deploying milestone, so this release's own gate run is unaffected, and the check ships in **warn** mode, where the emitter structurally does not increment the issue counter. First surfacing on those milestones is a WARN line, never a block.

## Alternatives Considered

Eight co-presence rules were generated and measured over 239 applicable cards, 203 Evidence sections, and six fixtures — three live, three synthetic. Six arms had to land correctly: two live must-PASS fixtures, one live must-FAIL, a prose near-miss that must FAIL, a single-marker body that must FAIL, and a bracket-only regression that must PASS.

| # | Candidate | Admits | Why rejected |
|---|---|---|---|
| **R1 / R2 / R3** | Loose word-match at ≥1 / ≥2 / ≥3 marker **words**, any position | 100 / 58 / 28 | All three admit the **prose near-miss** — a body merely *discussing* probes. A rule that counts words rather than labels cannot tell reporting from commentary, at any threshold. |
| **R4** | Strict bold § 8.2 render (`**Probe:**` etc.) | 2 | Breaks a must-PASS fixture. And only **5 of 203** Evidence sections use the bold render, so canonicalizing it would invent a value the corpus does not use. |
| **R5** | Structured **invocation + grounding** — require an invocation marker plus a grounding marker | 2 | **The runner-up, and the interesting rejection.** Every arm lands correctly, and it mirrors the G1-05a pattern-(d) `outcome + method` co-presence precedent exactly — semantically the best fit on the table. Rejected on **evidence, not taste**: it admits **2 of 239**, because it requires a literal `Probe:`-class invocation label while **8 of the 10** single-marker bodies carry `Control arm:` with the measurement stated in prose. Canonicalizing it would ship a spec that the corpus does not satisfy — an invented canonical value diverging from observed state, which is the same defect class this release exists to remove, one surface over. |
| **R6** | Label-position, ≥1 marker | 33 | `Verdict: this is broken.` passes with no probe behind it. The label floor without a count admits a bare assertion. |
| **R7** | **Label-position, ≥2 distinct markers** | **9** | **SELECTED.** The only rule where all six arms land correctly. |
| **R8** | Label-position, ≥3 distinct markers | 3 | Breaks a must-PASS fixture — the live probe-only card that sits at exactly two markers. |

Three predicate-scope options were considered separately. Keeping whole-body scope for both arms was rejected because it leaves the acceptance criteria ungradable and perpetuates the divergence. Evidence-scoping only the new arm was rejected as an unexplainable, asymmetric predicate. Evidence-scoping **both** arms was selected.

## Consequences

**What this buys.** A body that reports a real measurement is recognised as evidenced, without weakening what "evidenced" means. The criterion row and the tool now say the same thing about where evidence lives. And the platform's two evidence disciplines — confidence labelling and probe recording — are both first-class at the gate, rather than one being enforced and the other quietly punished.

**One normative statement, plus an enumerated set of deliberate author-facing reproductions.** The admissible set and the co-presence rule are **normative** in exactly one place — the G1-03 criterion row — and every surface that *decides* a card derives from it rather than paraphrasing it: the check calls the single extracted predicate, and the F2-applicability row, the bundled-transition re-check set, the G1 Enforcement-Layer Split row, the triage stage spec, `stage-01-intake.md` § 7 and `stage-io-contracts.md`'s Stage 1 → 2 Validation cell all **cite** it and reproduce nothing.

**Six surfaces do reproduce the set, and they do so by design.** The self-repair row, the check's header comment, the check's FAIL message, the authoring guide's § 8 structural floor, and both intake templates' description text each name the shapes in full. Every one is read by a human at the moment they must *write* evidence, and a remediation string or form hint that said "go and read the criterion row" would be worse guidance than the bracket-only text this card removed — the same defect one surface over. #4923's own Documentation Impact requires the authoring guide to state both forms, so reproduction there is the deliverable, not a lapse.

**The consequence, stated rather than claimed away: the vocabulary has seven edit sites, not one.** One normative site and these six. That list *is* the register — a future change to the marker set, the bracket vocabulary, or the co-presence count must sweep all seven. Check 22 and `--self-test` group EV share one function, so the two **enforcing** readings cannot diverge; nothing mechanical holds the six human-facing reproductions in step, and keeping them there is a documented obligation. An earlier draft of this record asserted that all seven merely cite and that zero restatements survive. Measured against the merged tree, that was false for six of them, and the honest repair is to name the cost rather than to strip guidance the card exists to add.

**The predicate became testable.** It was extracted into a single function called by both the gate and the offline self-test. This closes a reachability gap that predates the change: the check's live query reaches only open issues in the deploying milestone, so it structurally could not exercise its own fixture set — all three fixtures the originating card named are unreachable by it, two being closed and one out-of-milestone. The self-test drives the same function the gate calls, so a parallel reimplementation cannot drift, and it carries eight arms including the two mutant-killers — a single-marker body that must FAIL, and a bracket token placed outside the Evidence section that must FAIL while the identical token inside it PASSes.

**Layer-A validation is deliberately unchanged.** The intake forms' `required: true` on the Evidence field stays exactly as it was. Layer-A is presence-only by construction and structurally cannot inspect content, so it cannot carry a convention distinction. What *did* change on both intake templates is the author-facing **description text**, which asserted the bracket form as the whole admissible set. Leaving it would have shipped the card's own defect one surface over — guidance telling a conforming probe-convention author they are wrong.

**Blast radius is small and was traced.** The criterion's file has 173 first-order consumers, but only **15** references to the criterion itself across **3** files, and only two files needed edits; the third already cites rather than restates. No other gate criterion changes, no aggregation rule changes, and the Gate 1→2 `structural_pass_rate` denominator is untouched at six structural rows — the widening narrows the set of bodies that reach a FAIL state; it does not weaken the rule.

**Eight bodies flip PASS to FAIL, none in this release.** Re-derived at **2026-08-28** against the live open backlog — 455 open issues, **235** of them G1-03-applicable — by driving the shipped `_g1_03_evaluate` (spliced verbatim out of `deploy.sh`, never reimplemented) and the pre-change whole-body predicate over every applicable body, and taking the set the old rule passed and the new rule fails. The figure is **date-anchored because the population is live**: it moves as cards open and close, and an unanchored count would read as a standing property of the corpus rather than as a measurement.

**Eight, not nine, and the difference is load-bearing.** **Nine** bodies carry their only bracket token outside their Evidence section — that figure re-derives unchanged, and it is the one § Context and § Alternatives state. One of the nine *also* carries a probe record inside its Evidence section, so shape (b) admits it and it never reaches a FAIL. The out-of-section cohort and the flip set are therefore **not the same set**, and conflating them overstates the blast radius by exactly the cards the widening rescues — which is the change working as designed.

The eight sit across seven buckets — six other milestones and one un-milestoned card — and **zero** are in the deploying milestone. The gate is milestone-scoped and ships in warn mode, so the first surfacing is a warning line and a log row, never a block. Those bodies are not wrong to fix — each carries its evidence label outside the section that claims to hold its evidence.

**A stale figure is recorded as stale rather than carried.** The originating card headlined that 30% of a triage batch would be returned. Re-derived, the probe-only cohort is 49% under a loose word-match and 4.4% under the specificity-preserving rule; the card's number reproduces under neither. The **defect is confirmed live**; the figure is a loose-probe artifact and is deliberately not transcribed into any acceptance criterion as a measured quantity.

**A related defect is routed out rather than folded in.** Three surfaces disagree on which criteria constitute the Gate 1→2 structural set — the criterion table lists six, the version-history entries list five, and the check enforces a different five. That is squarely this release's defect class, but fixing it would change the `structural_pass_rate` denominator, which this decision explicitly holds constant. It is routed as separate work.

## Reversibility

**CHEAP · confidence HIGH.** One criterion cell, one self-repair row, one predicate function, one self-test group, one header comment, one authoring section, and two template description blocks — plus this record. No schema migration, no data movement, no path move, no package rebuild, and no change to any aggregation rule or gate threshold. Full rollback is a revert of the five source files; the criterion reverts to its bracket-only predicate with no residue, because shape (a) was never modified and the criterion's identity columns never moved.

The one asymmetry worth naming: reverting after authors have begun writing probe-record evidence would re-fail those bodies. That is a *content* migration cost, not a structural one, and it is bounded — the nine bodies whose scope changed are named, and the check ships in warn mode, so nothing blocks either way.

## Related ADRs

| ADR | Relationship |
|---|---|
| [ADR-120](../../core/ADRs/ADR-120-g1-enforcement-authority-is-class-scoped-and-release-scoped.md) | **Composes.** Establishes the Layer-B(d) / Layer-B(g) authority split this decision lands inside. The widening touches the Layer-B(g) predicate only, and it is ADR-120's release-scoping that makes the nine affected bodies a warning on other milestones rather than a block here. |
| [ADR-094](ADR-094-extend-before-create.md) | **Composes.** The predicate extends the existing check branch and reuses the existing Evidence-section extraction idiom rather than adding a check; the extracted function is an extraction of that branch, not a parallel mechanism. |
| [ADR-062](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md) | **Composes.** Governs the reconciliation direction when the canonical criterion text and the implementing tool disagree: the criterion row was already correct about Evidence-section scope, so the tool moved to it. |
| [ADR-115](ADR-115-adr-number-claim-binds-at-merge.md) | **Composes.** The numbering rule this record's `## Status` block applies — allocate at authorship, bind at merge, take the contiguous next, never reserve past an unmerged sibling claim. |
| [ADR-117](ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) | **Composes.** The derived-surface contract under which this record's index row is projected rather than hand-written. |
