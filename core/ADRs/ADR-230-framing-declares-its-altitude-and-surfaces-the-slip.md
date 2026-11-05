---
title: "ADR-230 — A framing declares its altitude, its question and the order of its open questions, and a decision taken ahead of an open predecessor is surfaced as a framing slip"
status: Proposed (flips to Accepted at the framing-altitude-and-slip-model Stage-13 ratification gate)
date: 2026-11-05
release: framing-altitude-and-slip-model
deciders: "Stage 5 Solutioning spoke (Principal Engineer) + Stage 6 Engineering spoke + Stage 8 QA spoke (blind re-code) + the operator at the Stage-13 ratification gate"
tags: [architecture, epic-framing, altitude, question-order, decomposition, review-time-judgment, methodology-neutral]
source_observations:
  - "Altitude census as of 2026-11-05, at the release base: case-insensitive line scan for 'altitude' over the tracked Markdown corpus (git grep -c -i -F altitude -- '*.md'; occurrences by git grep -o), lines coded by the word adjacent to 'altitude'; 200 files / 810 lines / 1090 occurrences over 1502 tracked Markdown files (Stage 5 baseline: 1502 files → 200 / 810 / 1090, unchanged at the release base); eleven senses plus one recursive usage; residue in files with coded lines attributed, not individually read."
  - "The measured instance as the epic-framing epic quotes it: an item 'specifying a verifier before knowing the channel', and a critic that 'commits the identical error one level up, at the roster altitude'."
  - "Recorded cases: ADR-184 § Rejected (a WHAT/HOW cut one level too low); ADR-173 § Alternatives (kind tokens reproduce the defect one level up); a backfill card fissioned into six cards after a readiness pre-flight; a release plan's provisional six-card hold."
  - "The ladder is coarse below Milestone: the framework's § 1.2 bottoms out at Work Item, and the type schema records an epic as a grouping kind at general_level Work Item."
supersedes: none
---

# ADR-230 — A framing declares its altitude, its question and the order of its open questions, and a decision taken ahead of an open predecessor is surfaced as a framing slip

## Status

Proposed; revised in place until the framing-altitude-and-slip-model Stage-13 ratification gate flips it to Accepted. Once Accepted it is immutable: changing the declaration, the measure or the test takes a record that supersedes this one.

**Numbering provenance.** This record was authored at the next-free number computed from the mainline anchor at Engineering Commit 0. An ADR number is allocated at authorship but claimed at merge; should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations of this record elsewhere use its slug token, which carries no number shape and resolves at the claim.

## Context

The epic-framing epic's sixth requirement asks that the framing method state the altitude it operates at, and that a design decided one level below the question it answers be surfaced rather than inherited. No rule names that pattern today; each recorded instance was caught case by case.

The measured instance, as the epic-framing epic quotes it, records an item criticised for "specifying a verifier before knowing the channel", and a critic that "commits the identical error one level up, at the roster altitude". The epic quotes the milestone's structural record as covering "what a channel is, the roster, what each may carry". The pattern was noticed through recursion — the same error recurring one level up — rather than by any check.

"Altitude" names several scales in the corpus: the abstraction band of a remedy, the hierarchy ladder, triage's scope altitude, the architect role's rungs and more (§ Distinctions). ADR-211 fixed the term this record uses: the level of the work-organization hierarchy — the work-organization mapping framework's § 1.2 per-level purpose ladder — at which a framing states its question. ADR-211 lists altitude among the elements a framing carries but gives it no form, and its ladder is coarse below Milestone: it bottoms out at Work Item. This record decides the declaration's form, the measure behind "one level below its question", and where a slip is detected. Its current state, future state and gap map follow `## Related ADRs`.

## Decision

A framing declares its altitude in ADR-211's term, the question it answers, and its open questions with the order among them. Each decision recorded under the framing names the question it answers and is tested against that order: a decision taken ahead of an open declared predecessor, or one that materially presupposes a cited open question, is surfaced as a framing slip unless the move is declared. The test surfaces; it never blocks.

```
framing ─┬─ Altitude: <general_level> — <question Q>      (ADR-211 term; value by the assignment rule)
         ├─ Open questions Q1..Qn · owner · waits on · state   (+ each silent owed axis)
         ├─ owed axes (answered | declared n/a | silent)    (ADR-211 coverage)
         └─ decisions d1..dk, each "on Qi" with a [FRAMING-SLIP: …] record
               ├─ declared predecessor of Qi open? ─ undeclared → FRAMING SLIP (order) → owner
               │                                  └ declared (a|b|c) → declared move
               └─ else names/assumes/constrains an open Qj (cited)?
                     ├─ undeclared → FRAMING SLIP (presupposition) → add the edge, route
                     ├─ declared (a|b|c) → declared move
                     └─ nothing citable → clear (unstated → coverage signal)
Qj answered ──→ re-test every decision provisional on Qj (the exit from (a))
slice framing ── parent's Altitude line + unhanded Qs with their order (Framing carry); (b) clears handed Qs
```

### Terms

- **Altitude** — ADR-211's term, unchanged: the level of the work-organization hierarchy at which a framing states its question (the framework's § 1.2 per-level purpose ladder). This record decides only how a framing declares it and where the declaration sits.
- **Framing slip** — an undeclared decision on a question whose declared predecessor in the framing's question order is still open; and, by the secondary limb, an undeclared decision that materially presupposes an enumerated open question, cited. A framing slip is neither a schedule slip nor a sense of altitude.
- **Question order** — the relation a framing declares over its open questions: each entry names the open questions it waits on. It is framing content. It is not `DEPENDS_ON`, which relates work items (the framework's § 1.3), and it is not a new edge type, which the framework's § 4.2 step 4 forbids.
- **Enumerated open questions** — the comparison set the test reads (§ The slip test).
- **Material presupposition** — a decision names, assumes or constrains a value that another enumerated open question is to decide.
- **Declared move** — one of three written records — provisional, hand-down or stated change (§ Declared moves and the continuity rule). Nothing else counts as declared.

### The declaration

A framing declares its altitude in one line, followed by its open-questions list:

`**Altitude:** <value> — <the question this framing answers, one sentence>`

- **Value set.** One member of the work-item type schema's `general_level` enum, the machine form of the framework's § 1.2 ladder. The record binds to the enum, never to a copied list. A kind name, a roadmap altitude or an intake altitude is never a value.
- **Assignment rule.** The value is the § 1.2 level of **the smallest entity whose outcome the question's answer governs**: one work item → `Work Item`; one milestone's or workstream's deliverables → `Milestone/Workstream`; several milestones of one project → `Project`. The value describes the question, not the item's kind: the type schema's `general_level` describes a kind, and the two readings differ. An epic and its slices often declare the same value.
- **Consumers of the value.** ADR-211's continuity rule ("moves the altitude"); the cut-basis card's altitude entry; the slice's Framing carry; a future presence check. **The slip test does not read the value.**
- **The `Open questions` list**, one line per entry: `Q<n> — <question> · owner <who> · waits on <Q-ids | none> · <open | answered (decision ref) | provisional on Q<m>>`.
- **Place.** The line and the list sit in the altitude slot of ADR-211's framing elements, after the work nature and owed axes and before the overlap considerations. The line is the declaration; the list is the question's decomposition at that altitude, not an altitude itself. A slice carries its parent's line verbatim and the parent's unhanded entries in order; writing that carry belongs to the framing-to-cut card.
- **Shared term.** The cut-basis card's altitude entry uses **the same term**. ADR-211 assigns that card the altitude and overlap vocabulary, so aligning its value set with the assignment rule is that card's decision.

### The framing slip and its measure

R6's "one level below its question" reads as **one step in the framing's declared question order**: a decision on a question whose declared predecessor is still open. A longer chain is a slip at its first open step. A secondary review-time limb catches an undeclared dependency: a decision that materially presupposes an enumerated open question, which must be cited.

The order is framing content, not a ladder level and not a work-item edge, so the measure adds no sense of "altitude". A ladder-level measure is not used: by the assignment rule, the measured instance's questions govern one structural record, so they share a level and a ladder measure finds nothing on the lead case. A ladder step is real when a slice decides a question its epic states at `Milestone/Workstream`, and that move is the continuity rule's ground, not this test's.

The record measures the slip in steps of the framing's declared question order, never in altitude; "altitude" appears in the definition only as the level at which the framing states its question.

### The slip test

**Enumerated open questions** are the only comparison set:

1. the framing's `Open questions` entries not yet answered;
2. each owed axis in ADR-211 coverage state `silent`, worded as that axis's question;
3. for a slice, those entries carried from its parent and not handed to it.

The framing's own whole question is **not** an entry. A question answered only provisionally counts as open.

The test runs on each decision recorded under a framing:

1. **Named question.** The decision names the question it answers: an entry ID, or the framing's question.
2. **Primary limb (order).** Is a declared predecessor of that question open? If yes: declared (§ Declared moves and the continuity rule) → `declared (a|b|c)`; undeclared → `slip (order)`. If no, go to step 3.
3. **Secondary limb (material presupposition; review-time).** Does the decision name, assume or constrain a value that another enumerated open question is to decide? The record must cite that entry, with its location and text, and quote the term — for example "the channel", for a verifier.
   - Cited and undeclared → `slip (presupposition)`, which also names the missing predecessor edge for the owner to add.
   - Cited and declared → `declared (a|b|c)`.
   - Nothing citable → `clear`. If the reviewer believes an unstated question was presupposed, record `not surfaced — upstream question unstated` as a coverage signal against ADR-211's owed axes.
4. **Record and route.** Record the verdict on the framing (§ Where detection lives), and route each slip to the open question's owner, who answers it, declares the move, or has the decision revised. **The test surfaces; it never blocks.**

**Stated limit.** The test reads only stated questions. ADR-211's owed axes — the epic-framing epic's first requirement — turn the common upstream questions into stated ones (entry 2), so the two requirements compose.

**Recursion is a heuristic, not the measure.** "The same error, one level up" is how the pattern was noticed, and it also matches defects that recur across levels with no open question involved. After a slip is corrected, test the next open question up.

**Recording a verdict for a case.** A case is **surfaced** when the test returns `slip (order)` or `slip (presupposition)`, and **not surfaced** when it returns `clear`, `declared (a|b|c)` or `not surfaced — upstream question unstated`. A case whose verdict turns on a fact it does not state is **conditional**, with that condition stated. A case that supplies neither the decision nor the question it depends on is **INDETERMINATE**, with the missing element stated, because steps 1 to 3 cannot run.

### Declared moves and the continuity rule

"Declared" has one meaning, used in the test, in the register row's Act and in the case table. It is one of three written records; nothing else counts.

- **(a) Provisional.** The decision is recorded as provisional on an open question, naming its ID and what settles it; `[ASSUMPTION – CONFIRM]` with owner and close-by is the standard form. **Exit:** when that question is answered, each decision provisional on it is re-tested against the answer (kept, revised or withdrawn) and its record updated. A decision still provisional on another open predecessor stays (a).
- **(b) Hand-down.** The parent hands the question to this framing by name at the cut (ADR-211's "handed to a named slice").
- **(c) Stated change.** The stage that moves the question's altitude, or its place in the order, updates the framing (the `Altitude:` line or the list) and the acceptance criteria, with a comment that explains why. This is ADR-211's carrier rule. A statement only elsewhere, such as in a decision record's own text, is not (c).

How this relates to the continuity rule:

- The two catch disjoint things. An undeclared change to the line or the order breaches the continuity rule (ADR-211's continuity row in the gate-coverage register). An undeclared decision ahead of an open predecessor is a framing slip (this record's row). A declared move of either kind is neither.
- A *cross-level* slip is a slice or stage deciding a question whose parent-declared predecessor is open and was not handed down. It is the undeclared form of the move the continuity rule requires to be stated, and ADR-211's carry comparison sees it only at axis granularity, after the cut.
- An *intra-framing* slip has no continuity-rule counterpart; (a) is its only declared form.
- When parent and slice declare the same value, "moves the altitude" does not fire. The rule's hand-down carry and its "does not inherit a different framing silently" clause do.

### Distinctions

The census (its probe and denominator are under `source_observations:`) coded each line by the word adjacent to "altitude". The framing slip differs from every sense it found.

| # | Sense | Scale | Owner | How the framing slip differs |
|---|---|---|---|---|
| 1 | Abstraction band | point-fix · extend-seam · new-abstraction | design exploration (used by the cross-stage re-review's § 11.2, design-review checklist item 4.7, and the Premise-Altitude-Finding) | It grades a remedy against seams; a slip can occur at any band |
| 2 | Hierarchy ladder | the § 1.2 levels (`general_level`) | the framework's § 1.2; ADR-211; the architecture lens's altitude circle | It places work or a question; the slip is measured in the order |
| 3 | SA-G1 scope altitude | promised outcome vs declared scope | the intake style guide § 4c; `stage-02-triage.md` § 5 A4.7 | It checks one item's promise against its own scope |
| 4 | Architect rungs | enterprise ↔ system | ADR-127; the `pmo-architect` skill | It routes who owns a design call |
| 5 | Intake / requirement altitude | container ↔ story ↔ task | the intake-desk model; the authoring standard's per-kind depth | It picks the kind to file. Over-definition is a slip only when the detail presupposes an open question |
| 6 | Roadmap altitude | Portfolio · Program · PI-Sprint | the initiative-roadmap framework § 3.4 | It classifies a roadmap artifact |
| 7 | Organizational altitude | work unit → organization | knowledge architecture § 5; the knowledge-management protocols | It is a lesson's scope |
| 8 | Specification altitude | WHAT ↔ HOW | intake gate G1-04; the intake style guide § 5 | Closest: G1-04 is the intake-time instance of a slip on a design-stage question |
| 9 | Structural-nesting altitude | meta-schema ↔ schema ↔ block ↔ entry | descriptive (ADR-069, ADR-070, ADR-196) | Where a rule applies in a declaration |
| 10 | Role / audience altitude | the owning role level; a text's register | descriptive; "altitude switching" | It routes or pitches |
| 11 | Operating-layer altitude | pipeline ↔ project delivery; stage; session | "altitude boundary"; descriptive | Which layer a mechanism acts in |
| R | *Recursive usage, not a sense* | "the same error at two altitudes", "one altitude up" | none | A defect recurring a level up: the measured instance's phrasing, and the recursion heuristic's look-alike |

### Where detection lives

Detection is split by the moment a decision is made.

| Moment | Arm and the seam it extends | Status |
|---|---|---|
| Design time (Stage-4 refinement, Stage-5 design) | A "framing slip" item in `release/references/templates/design-review-checklist.md` § 4, beside item 4.7 (whose "seam altitude" is the band sense), and a matching line in the Stage-4 Phase A0 re-review (`stage-04-planning.md` § 5 Phase A0; artifact per `triage-design-rereview.md` § 1). Both are review steps that already run | Authored by R6's build card; not yet present |
| Framing time (an epic framing is authored or changed) | A step of the framing method, on the epic-framing surface the epic-framing toolkit introduces | Registered named gap |
| Cut time (a slice framing is written) | The same step, in the framing-to-cut mechanism | Registered named gap |

**Not the home:**

- **The architecture lens's altitude circle.** The lens is a naming-and-routing instrument whose Boundaries section has it cite the ladder rather than own it and author no gate criterion. The circle is "the level at which [work] is placed and tracked", and the lens fires only when a proposal introduces or reshapes a component (its § 3). A placement check cannot host a question-order check: placement and slip are disjoint (case C5).
- **ADR-211's continuity row** is composed with, not used: it works at axis granularity, after the cut.
- **Intake gate G1-04 and the over-definition test** are earlier, intake-time instances.
- **The design-review checklist alone** is one arm, not the home.

**Per-decision observable.** Each decision recorded under a framing carries one test record:

`[FRAMING-SLIP: <decision ref> on <Q-id | framing question>; predecessors <Q-id open|answered, … | none>; presupposes <cited entry | none> → <clear | declared (a|b|c) | slip (order) | slip (presupposition) | not surfaced — upstream question unstated>]`

- **Form:** the `core/rules/decision-time-adherence.md` § 3 token form (`[<id>: <read> → <observed>]`).
- **Its § 6 declaration fields:** trigger — about to record a design decision under a framing; ground-truth read — the framing's order and the decision's named question; token — this record; locus — planning.
- **Registration:** R6's build card adds an index row in `core/rules/decision-time-adherence.md`, and this record then discharges that row as the rename-cascade record discharges DTA-7. Nothing emits the record until then, so no second trailer family is introduced.

### Mechanical or review-time

- **Primary limb: mechanizable by construction, not yet built.** "Is a declared predecessor open" is a read of two recorded fields, but no framing surface carries them yet. **Revisit trigger:** mechanize it when the framing method records them.
- **Secondary limb: review-time.** Material presupposition is semantic. The citation rule makes each verdict inspectable, and the Stage-8 blind re-code tests whether coders agree.
- **Mechanizable now:** the line's presence and value, the list's presence, and test records counted against decisions.
- **Runner: none today.** One class-3-O named-gap row (disposition 2) in the gate-efficacy standard's gate-coverage register, a sibling of ADR-211's continuity row. It is net-new because extending that row in place is infeasible: the continuity row triggers on the cut or a later stage acting on a slice and compares parent and slice framings, so it cannot see an intra-framing slip, and rewriting it would alter an obligation another record owns.
- **Row-split rule.** One row names both seams. When R6's build card authors the design-time items, it splits the row: the design-time arm becomes its own row with a `runner-def:` pointer at the checklist item, and the framing-time and cut-time arms stay this named gap.

### Applying the definition

The measured instance is cited only as the epic-framing epic quotes it. The *Case input* column stands alone; it is what the Stage-8 blind packet carries.

| # | Case input | Role | Verdict, with its condition |
|---|---|---|---|
| C1 | A predecessor item was criticised for "specifying a verifier before knowing the channel" (the epic-framing epic). The epic quotes the milestone's structural record as covering "what a channel is, the roster, what each may carry" | in-sample positive | **Surfaced if** the framing under which the verifier was specified enumerated the channel question: by the primary limb if the verifier question declared it a predecessor, otherwise by the secondary limb citing that entry and quoting "the channel". **Not surfaced otherwise** (a coverage signal). The epic quotes the later critic, not that framing, so which branch held is unknown |
| C2 | The critic "commits the identical error one level up, at the roster altitude" (the epic-framing epic) | in-sample positive | **INDETERMINATE.** Neither the decision nor the presupposed question is supplied, so steps 1–3 cannot run |
| C3 | ADR-184 § Rejected, "put the firing backend in the routine spec": "Cut WHAT and HOW apart one level too low …". Its axis table says storing the backend "is the host-binding leak this record exists to close". The release's criterion was amended only afterwards, to assert the registry names no backend | card-cited positive | **Conditional.** At registry granularity the question was unstated (a coverage signal); at record level the alternative contradicts a settled answer (C4's rule). **Surfaced only if** the framing had carried an open question the placement constrains — such as `structure-placement` silent — and that entry was cited |
| C4 | ADR-173 § Alternatives, "Enumerate the kind tokens in the map": "Reproduces the defect being repaired one level up …"; it "cannot satisfy the criterion that a newly-declared kind resolves without editing the tool" | card-cited, specificity | **Not surfaced.** The presupposed question (is the kind set closed?) was answered by that criterion. Contradicting a settled answer is the recursive defect class plus a low-altitude point-fix |
| C5 | The architecture lens's example: a weekly-rollup artifact written at Portfolio when its content is one Project | out-of-sample, specificity | **Not surfaced.** A placement error; no open question is involved |
| C6 | A check fixture's comment "THIS IS THE FOUNDING BLIND SPOT REPRODUCED ONE LEVEL DOWN", and a release-log watch-for of the same shape | out-of-sample, specificity | **Not surfaced.** A defect class recurring across attribute classes |
| C7 | A milestone's first description listed a "regenerated `core/ADRs/README.md`" row; the README calls itself curated | out-of-sample, specificity | **Not surfaced.** The question was settled: a stale premise |
| C8 | ADR-180 § Decision: "The binding weld is one level down, on the kind", stated with its reason | specificity | **Not surfaced.** "Level" here is pack-to-kind nesting (sense 9); no open question is involved. Neither a ladder move nor form (c) |
| C9 | The epic-framing epic's container is "typed `epic` — one level below what it is — as a stated compromise", and the grouping-tier work that would correct it is named | must-not-surface, declared (a) | **Not surfaced.** The secondary limb reaches it: the typing names a value the open grouping-tier question decides, citable to the epic's typing-compromise risk. It is provisional with its settler named → `declared (a)`, re-tested when the grouping tier settles. "Level" is the kind sense (sense 5), so this is not the ladder arm |
| C10 | A work item filed at one-card scope was found at a milestone readiness pre-flight to be "a full slice, not a [milestone] member" (about 18 points). That stage recorded a Tier-2 scope change and a fission comment with the rationale, rewrote the criteria per child, and split it into six cards | must-not-surface: a genuine ladder move, retrofitted | **Not surfaced.** By the assignment rule, the question's answer was first read as governing one work item (`Work Item`), then found to govern a milestone slice's deliverables (`Milestone/Workstream`). The moving stage said so and why and updated the criteria → `declared (c)`. The question's level moved, not the item's kind |
| C11 | Constructed: an epic framing declares `**Altitude:** Milestone/Workstream — <question>`. Stage-4 refinement finds the answer governs two milestones' deliverables, changes the line to `Project`, updates the criteria and comments why | must-not-surface: a genuine ladder move, constructed | **Not surfaced:** `declared (c)`. The same change made silently breaches the continuity rule (ADR-211's row); it is not a framing slip |
| C12 | A decision fixing a declaration's form (an open-questions list under the altitude line) was recorded while the framing's own stated question was open. The framing's list declares that this question waits on the choice of measure, and the measure was decided first | near-miss in domain (real: this record's own design) | **Not surfaced.** The whole question is not an entry, and the declared predecessor is answered → `clear` |
| C13 | Constructed: a framing with the `data` axis silent records "the hand-off from intake to triage is a queued message" | near-miss in domain (constructed) | **Not surfaced.** No declared predecessor, and no entity, key or value set is named → `clear` |
| C14 | Constructed: the same framing records "the queued message carries the record's primary key" | in-domain positive (constructed) | **Surfaced:** it names a key the silent `data` axis decides → `slip (presupposition)`, citing that entry |
| C15 | A release plan held six build cards "PROVISIONAL", their shapes "a prediction, **not** a measurement", behind an operator gate on an open confirm-or-collapse question, and stated they are re-derived after the gate (`release/releases/plans/v3.87_RELEASE_PLAN.md`, staged waves) | must-not-surface, declared (a) with a re-test (real) | **Not surfaced:** `declared (a)`. The planned re-derivation is the provisional form's exit, already in practice |

**Tally (single coder, at authoring).**

| Group | Cases | Primary limb | Secondary limb | Result |
|---|---|---|---|---|
| Corpus positives | C1–C3 | 0 of 3: no corpus framing declared an order, so each is retrofitted | C1 and C3 conditional | 0 unconditional · 2 conditional · 1 INDETERMINATE |
| Constructed in-domain positive | C14 | — | fires | 1 of 1 |
| Specificity | C4–C8 | silent | silent | 5 of 5 not surfaced |
| Declared moves | C9, C10, C11, C15 | — | C9 reached, then cleared as declared | 4 of 4 not surfaced. The ladder-altitude moves are C10 (real) and C11 (constructed) |
| In-domain near-misses | C12, C13 | silent | silent | 2 of 2 not surfaced |

**Limits.** No corpus positive is unconditional. Phrase searches found no out-of-sample positive. The primary limb has no corpus instance, because no framing yet declares an order. Out-of-sample sensitivity therefore rests on the register row's dated lines, as it did for ADR-211's calibration framings.

**Blind re-code, before ratification.** A re-code by this record's own author would not be blind, so the agreement is measured at Stage 8 by the QA spoke, on ADR-211's precedent (its release bound its coding to a blind re-code at acceptance testing, with a threshold).

- **Who:** the Stage-8 QA spoke, before ratification. It codes before opening this record, the release plan, the Stage-5 design comments, the adversarial design review, the release pull request or any other issue of this release's milestone; its own sub-task body is excepted.
- **Blind packet:** the codebook — § The slip test and § Declared moves and the continuity rule — and the *Case input* column of C1–C15. Nothing else.
- **Metric:** verdict agreement, k of 15, on the verdict value (surfaced / not surfaced / conditional / INDETERMINATE), with each disagreement and its reason, and the read order.
- **Threshold:** k at least 12 (⌈15 × 7/9⌉, ADR-211's 7-of-9 proportion). Below it, the case-application criterion is not met and returns to Engineering, which records the figures in this section and states in § Consequences that the review-time limb is unvalidated.

## Alternatives Considered

- **A ladder-level measure** (the decision's question sits at a lower `general_level` than the question it depends on). Eliminated on sensitivity: the measured instance's questions govern one structural record, share a level, and return nothing on the lead case. Its real steps are the continuity rule's ground.
- **Containment depth** (counting `BELONGS_TO` steps). Intermediate groupings are not hierarchy levels, so it would add a sense of altitude.
- **Judged presupposition as the primary measure** ("some admissible answer would make the decision wrong or moot", tested against the whole question and silent axes). It flagged every decision that helps answer the framing's question; it is narrowed into the cited secondary limb.
- **A recursion signature** ("the same error, one level up"). Eliminated on specificity: it surfaces recursion sightings with no open question, such as ADR-173's. Kept as a heuristic.
- **A frontmatter field for altitude.** Framings are issue bodies, and an `altitude` frontmatter field has no corpus use.
- **A label.** A label cannot carry the question.
- **A bare level with no question.** Uncheckable.
- **Predecessors recorded on each decision.** The edges would repeat and drift.
- **A separate dependency artifact.** A second carrier, against ADR-211's one-carrier rule.
- **The architecture lens's altitude circle as the home.** A placement instrument that fires on components; placement and slip are disjoint.
- **ADR-211's continuity row as the home.** It works at axis granularity after the cut, cannot see an intra-framing slip, and rewriting it would alter an obligation another record owns.
- **The intake checks (G1-04, the over-definition test) as the home.** They are earlier, intake-time instances.
- **The design-review checklist alone.** One arm, not the home.
- **A table row per decision instead of the inline record.** A second format.
- **Registering the decision-time-adherence index row now.** Outside this release's file set; R6's build card owns it.
- **Two named-gap rows now.** Identical status and no runner; they add no information and widen the change.

## Consequences

- **Positive:** one term with one meaning — altitude stays ADR-211's ladder, and the slip is measured in the declared order; a slip is visible when the decision is recorded, not in delivery; the primary limb is mechanizable once the fields are recorded; intake gate G1-04's WHAT-before-HOW concern is generalized to every stage; a provisional decision exits through a re-test when its question is answered.
- **Negative:** a small evidence base — no unconditional corpus positive and no primary-limb instance as of authoring; a named gap until the framing method exists; only stated questions are seen; the ladder's coarseness below Milestone is inherited; reproducibility of the review-time limb rests on the Stage-8 agreement.

## Reversibility

MODERATE — revised in place while Proposed; superseded after ratification, at a cost that grows as the framing method, the design-review items and the decision-time-adherence row build on it.

## Related ADRs

- ADR-211 — the altitude term this record declares, and the continuity rule a framing slip is distinguished from.
- ADR-127 — the architect role's altitude axis, a distinct sense.
- ADR-184 — a recorded case: a WHAT/HOW cut one level too low (C3).
- ADR-173 — a recorded case: kind tokens reproducing a defect one level up (C4).
- ADR-180 — another sense of "level": pack-to-kind nesting (C8).
- ADR-181 — citations of an in-flight record bind at the claim.

## Current State

As of authoring:

- **How framings declare altitude:** they do not. ADR-211 names altitude among the framing elements and the Framing carry fields, with no form. No issue body carries an altitude line, and neither the epic-framing surface nor the Framing carry has shipped.
- **Senses in use:** the census found eleven senses and one recursive usage (§ Distinctions); ADR-211's term is the ladder.
- **What catches a slip:** human reading, case by case — the measured instance's later critic; ADR-184's author at design time. At intake only, G1-04 and the over-definition test cover questions a later stage owns.
- **What does not:** no surface records which question a decision answers or what an open question waits on; a provisional decision is re-tested only ad hoc; design-review item 4.7 grades a remedy's band; the architecture lens places components; ADR-211's continuity row works at axis granularity after the cut and is itself a named gap; and no decision-time-adherence checkpoint covers deciding ahead of an open question.

## Future State

Once adopted:

- **An epic framing** carries the `Altitude:` line; the `Open questions` list, with silent owed axes counted as entries; its owed-axis coverage; and, for each decision, the question it answers and a `[FRAMING-SLIP: …]` record. A provisional decision names its question and settler, and answering a question re-tests every decision provisional on it.
- **A slice framing** carries the parent's line verbatim and its own, the parent's unhanded open questions in order, and the questions handed to it by name. Its decisions are tested against its own entries and the carried ones.
- **A design review,** at Stage-4 Phase A0 and Stage-5 Phase B, carries a "framing slip" item. It reads each design decision's question against the order, runs the secondary limb under the citation rule, and emits the record. A slip is routed to the owner and recorded, never blocking.
- **At each qualifying Stage-13 close,** the workspace owner appends the register row's dated line.

## Gap Map

| # | Gap | Current | Future | Where it is closed |
|---|---|---|---|---|
| G1 | Declaration form | none | the `Altitude:` line, value by rule | this record; adopted by R6's build card, drafted by the drafting card |
| G2 | Question order | none | the `Open questions` list | this record; built by R6's build card |
| G3 | Decision → question | none | named question plus a test record | this record (form); R6's build card (method) |
| G4 | Framing-time and cut-time detection | human reading | the test at authoring and at the cut | the registered named gap → R6's build card |
| G5 | Design-time detection | no slip item | a design-review checklist § 4 item and a Phase A0 line; the row splits, gaining a `runner-def:` | R6's build card |
| G6 | Provisional exit | ad hoc | a re-test on settlement | this record (rule); R6's build card (step) |
| G7 | Carry into slices | not shipped; names altitude only | the parent's line plus its unhanded questions, in order | the framing-to-cut card |
| G8 | Cut-side value set | unaligned | same term; aligned, or a reason stated | the cut-basis card |
| G9 | Population owner | — | an open item names the population key | the drafting card writes it into R6's build card |
| G10 | Coder agreement | one coder | agreement recorded | this record (the Stage-8 blind re-code) |
| G11 | Mechanization | none | presence checks; the primary limb read by machine | R6's build card (revisit trigger) |
| G12 | Lens pointer | none | a pointer from the architecture lens to the test | R6's build card |

## References

- #7540 — the epic-framing epic: R6 and the measured instance
- #7965 — the spike that produced this record
- #7960 — the cut-basis card, sharing the altitude term
- #7963 — the framing-to-cut card, which writes the Framing carry
- #8100 — the drafting card: the card drafting R6's build card
- #6902 — context gathering across the hierarchy
- #7539 — the grouping tier above epic
- #398 — the backfill card fissioned into six (C10)
