---
title: "ADR-207 — Design axes and cut patterns key on work nature: the natures the platform recognizes, the design axes each owes, and how a framing states coverage"
status: Proposed (flips to Accepted at the Stage-13 ratification gate)
date: 2026-09-27
release: work-nature-and-axis-model
deciders: "Stage 5 Solutioning spoke (Principal Engineer, Research-Methodology Design variant) + Stage 6 Engineering spoke (validation) + the operator at the Stage-13 ratification gate"
tags: [architecture, decomposition, epic-framing, classification, work-nature, design-axes, methodology-neutral]
source_observations:
  - "Frame census as of 2026-09-27, window 2026-06-21T01:22:40Z..2026-09-27T15:46:56Z: ⟦S6⟧ in-window issues; ⟦S6⟧ carry an improvement-form Domain heading; normalized Governance ⟦S6⟧, Software ⟦S6⟧, Data ⟦S6⟧; ⟦S6⟧ off-enum items (⟦S6⟧ distinct raw values); closed frame items completed ⟦S6⟧, not planned ⟦S6⟧; Website, ERP, Code Review, Other none."
  - "Planning evidence at the release baseline: nature-list and design-framework probes over the release-history-excluded Markdown corpus returned zero while their controls fired."
  - "The measured instance (the epic-framing epic): a consumer repository's first epic framing was re-scoped the same day after the operator named the flow/data/CRUD surface; its second epic converged on the same structural and behaviour-over-time pair."
supersedes: none
---

# ADR-207 — Design axes and cut patterns key on work nature

## Status

Proposed; revised in place until the Stage-13 ratification gate flips it to Accepted. Once Accepted it is immutable: changing the natures, axes or table takes a record that supersedes this one.

## Context

Decomposition must classify a piece of work's nature before offering cut patterns, and epic framing must know which design surfaces an epic owes an answer on; deciding these separately would give one method two keys. The measured instance showed the cost: an epic's first framing pass produced only its structural record, and the operator named the missing flow and data surface the same day. The existing classifications answer other questions — the intake type map (a filing's form, by altitude), the process designer's requirement types, the deliverable-class sense of `domain`, methodology-pack kinds and `type:` labels — so this record reconciles with them in a crosswalk rather than extending one.

## Decision

The platform keys its design axes and its cut patterns on one classification, the work nature. The work-nature key (one key by default, or nature × deliverable class where a demonstration held) is defined below, with the design axes each nature owes, how a framing states its coverage of an owed axis, how that framing carries into slices and through later stages, and when the model is re-decided.

### Terms

- **Work nature** — how a piece of work relates to the solution's existing behaviour and structure; always two words. Not the work-organization mapping framework's "by nature" placement (meaning: without per-user governance).
- **Design axis** — a surface of the solution a framing must answer on: an ISO/IEC/IEEE 42010 viewpoint framing one concern, the framing's answer being the view. Not the architect role's altitude axis (ADR-127), design exploration's distinctness axes, a decision's own dimension (ADR-063), or the workspace-layout guide's design principle.
- **Users** — the operators and the agent sessions the platform governs. A change to what a check asserts, or to what a hook blocks or emits, changes what users get.
- **Altitude** — the level of the work-organization hierarchy at which a framing states its question (the per-level purpose ladder of the work-organization mapping framework).
- **Overlap considerations** — duplication or subsumption between an epic's slices and with other open work, and the shared surfaces the work touches: topics at framing, and files once the cut assigns them.

### Work natures

The single key, orthogonal to kind, altitude, deliverable class and filing form: any story, task, epic or work item can carry any nature.

| Identifier | Definition | Boundary example | Source in practice |
|---|---|---|---|
| `defect` | Behaviour departs from what an authoritative statement recorded before the work was raised — a spec, rule, contract, schema, decision record, or the stated purpose of the capability — already requires; the work restores it. | A guard applying an allowlist's host patterns to GitHub write paths, when the allowlist's own header documents those patterns as matching the host portion of a URL, is a `defect`; an undeclared allowlist row still matching either kind of destination, where no rule requires rows to declare a kind, is not. | IEEE 1044; ISO/IEC/IEEE 14764 corrective maintenance |
| `new-capability` | Adds behaviour or an artifact that no existing capability delivers in any form; its absence violates no requirement. | A settings manager where operators hand-edit raw configuration; an allowlist helper gaining an option to declare an entry's kind extends an existing helper and is not one. | SAFe features; ISO/IEC/IEEE 14764 perfective maintenance (enhancements for users) |
| `data-structure-change` | Changes an authoritative shape — the canonical declaration of entities, fields, keys or value sets — that existing records and readers depend on, so they must migrate. | Adding a versioned field set to refusal records, which their readers must branch on while records written before it carry none; rewording a file's header so it describes an unchanged row format is not a shape change. | Ambler & Sadalage, *Refactoring Databases* (2006); BABOK v3 Data Modelling |
| `integration-change` | Changes exchange across a boundary not owned on both sides: contract, adapter, exchange sequence or identity mapping. | Changing the key a sync snapshot matches external records on; renaming a field only the solution reads is a `data-structure-change`. | Hohpe & Woolf, *Enterprise Integration Patterns* (2003); BABOK v3 Interface Analysis |
| `investigation` | Produces knowledge, not change: a question answered, a decision recorded, a feasibility established in a time box. | A spike recording a model decision, though its output is a file; the card building what it specifies is not. | Beck, *Extreme Programming Explained* (1999), spikes; SAFe exploration enablers |
| `infrastructure-change` | Changes the build, verify, deploy or run environment — pipeline and CI runners, deploy mechanics, hosting, hook installation and wiring, runtime configuration — without changing what users get. | Bounding CI suite run time, or wiring an existing hook into a further session type; changing what a check asserts, or what a hook blocks or emits, changes what users get and is not an infrastructure change. | SAFe infrastructure enablers; ITIL 4 change enablement |

### Classification procedure

Classify each acceptance criterion; the item's nature is the one most of its criteria carry, ties going to the earlier step, and the others are recorded as secondary. An item with no acceptance criteria is classified on its proposed change as one unit. A criterion that verifies no change — a recorded baseline, a regression guard on existing behaviour — is not classified. For each criterion, the first yes wins:

1. Its output is knowledge and it changes nothing users rely on → `investigation`.
2. It changes only the build, verify, deploy or run environment and nothing users get → `infrastructure-change`. What a check asserts, and what a hook blocks or emits, are not environment.
3. It changes a contract with a party not owned on both sides → `integration-change`.
4. It changes an authoritative shape that existing records or readers depend on → `data-structure-change`.
5. An authoritative statement recorded before the work was raised — a spec, rule, contract, schema, decision record, or the stated purpose of the capability — already requires the missing or wrong behaviour, and it can be quoted → `defect`.
6. No existing capability delivers it in any form → `new-capability`.

Otherwise the criterion fits no nature; the coder records which candidate below it matches.

**Authoritative sources.** A governed file in the repository, an ADR, or a ratified release plan counts as an authoritative statement. An operator comment, directive or scanner alert counts only once a governed file adopts it. Each `defect` code records its source and the basis for its authority.

**Owed set.** An item owes the union of the owed axes of its primary nature and the owed axes of every surface nature (steps 3 and 4) that at least one of its classified criteria carries. The primary nature still indexes the item's row for grading.

**Why this order.** Steps 1 and 2 classify by what the output is, and after the exclusion in step 2 they cannot overlap the later steps. Steps 3 and 4 classify by the surface touched, and each carries parts that are owed whatever the motive — coordination with a party the work does not own, and migration of existing records and readers — so a surface nature outranks a motive nature, and its owed axes join the item's owed set even when a motive nature is primary: a defect fix that changes a canonical shape still owes the migration. Step 3 precedes step 4 because an exchange-contract change usually changes an exchanged shape too, and the other party's readers cannot be migrated by this work. Steps 5 and 6 classify by motive and apply only to what remains; step 5 precedes step 6 because behaviour that is required and missing is a defect, whose expected parts (root cause, regression) differ from a new capability's.

**Candidate natures** — admitted only if at least three validation items fit one and no other nature:

| Identifier | Definition | Boundary example | Source in practice |
|---|---|---|---|
| `restructure` | Changes where parts live or how they compose, preserving behaviour. | Collapsing hand-copied constants into one library with unchanged results; the same move made to change a result is not. | Fowler, *Refactoring* (1999; 2nd ed. 2018); ISO/IEC/IEEE 14764 perfective maintenance (recoding to improve maintainability) |
| `behaviour-change` | Deliberately changes an existing capability's behaviour with no prior requirement violated: the intent changes. | Silencing a hook's allow path where chatter was the design; silencing it because a rule required silence is a `defect`. | ISO/IEC/IEEE 14764 adaptive and perfective maintenance; Swanson (1976) |

ISO/IEC/IEEE 14764's perfective category covers both enhancements for users and recoding for maintainability, so it does not separate `restructure` from `new-capability`; Fowler's behaviour-preserving transformation is the citation that does.

⟦S6: move each admitted candidate's row into the work-natures table; under each one not admitted, state its matching count of items that fit no nature.⟧

### Crosswalk from existing classifications

These surfaces carry hints, not the key. Where a hint and the procedure disagree, the procedure wins and the divergence is recorded against the item.

| Existing classification | Value | Nature hint |
|---|---|---|
| Intake type map (filing form × altitude) | Broken behavior (solution requirement) → `bug` | `defect` |
| same | Migration / rollout (transition requirement) | `data-structure-change` when existing records or readers migrate; `infrastructure-change` when only the environment moves |
| same | Initiative, feature/story, task rows; the not-yet-authorable row | none — these rows state altitude or readiness, not nature |
| Tracker `type:` labels | `type:bug` · `type:spike` | `defect` · `investigation` |
| same | `type:epic`, `type:story`, `type:task`, `type:card` | none — methodology kinds; any kind carries any nature |
| Process designer's requirement types | Integration · Data · Operational | `integration-change` · `data-structure-change` when an authoritative shape changes · `infrastructure-change` |
| same | Functional · Non-Functional | by the procedure (`defect`, `new-capability`, or a candidate) · none — a quality attribute is a cross-cutting perspective, not a nature |

⟦S6: the divergence rate — items whose hint and procedure disagree, of items carrying a hint.⟧

### Nature is one key

⟦S6: keep one of the next two paragraphs, per the three-valued demonstration outcome.⟧

**One key, by default.** Nature is one axis; deliverable class is a parameter. Answering an owed axis consults the best-practice guide for the deliverable's class (registry concept 1, Deliverable-class), but the class never changes which axes are owed. This is a default, not a finding: it is borrowed by analogy from the architect role's rule that a split needs a demonstration (ADR-127), whose own scope is the architect axis only. A demonstration needs, for deliverable classes A and B, an axis at E2 or above in at least two delivered items of a nature in class A, while at least two delivered items of that nature in class B show E0 on it and none of them carries E3-F on it. The second-axis question was ⟦S6: "tested for NATURE on the governance × software pair (n = G governance and S software delivered items of that nature) and not demonstrated" or "not testable for any nature"⟧; for ⟦S6: the remaining natures⟧ it was not testable, because the validation set's delivered items span two deliverable classes. The calibration framings may reopen it: each framing line records the framed epic's deliverable class.

**Nature × deliverable class.** ⟦S6: the nature, the axis and the class pair demonstrated, with n on each side⟧; the second axis binds to registry concept 1 (Deliverable-class).

The improvement form's Domain field is a distinct, unregistered sense of `domain`: an optional value the filer or triage sets, used as a topic label. It served only as the validation set's sampling stratum. Its values name concept-1 classes (Software → `software`, Website → `web`, ERP → `enterprise-platform`, Data → `data`, Governance → `governance`; Code Review has none; Other → a free name), but they do not track them: ⟦S6: the observed crosswalk — for each Domain value, the concept-1 classes of its delivered items, and the name-agreement count⟧.

### Design axes

| Identifier | Answered when the framing states | Source in practice |
|---|---|---|
| `data` | what information the work creates, reads, changes or deletes; its shape (entities, keys, value sets); its owner | Zachman, *What* (1987); Rozanski & Woods, Information viewpoint (2011); UML 2.5 class diagrams; BABOK v3 Data Modelling |
| `process-flow` | the steps — who or what acts, in what order, with which hand-offs, decision points and error paths | Zachman, *How* (1987); Kruchten, 4+1 scenarios (1995); arc42 runtime view; UML 2.5 activity and sequence diagrams; BABOK v3 Process Modelling |
| `structure-placement` | the parts, where each lives, what each composes with or depends on | Zachman, *Where* (1987); Kruchten, 4+1 logical, development and physical views (1995); arc42 building-block and deployment views; UML 2.5 component, package and deployment diagrams |
| `behaviour-over-time` | the states the solution passes through, what moves it between them, what must persist across a session, phase or version boundary | Zachman, *When* (Sowa & Zachman 1992); UML 2.5 state machine and timing diagrams; BABOK v3 State Modelling |

Not axes: Zachman's *Who* and *Why* (the framing's actor and outcome fields carry them); quality attributes such as security or performance (cross-cutting perspectives, per Rozanski & Woods, applied through the domain best-practice guides); milestone sequencing (it sequences delivery, not the solution — see the continuity rule).

### Owed axes by nature

| Nature | data | process-flow | structure-placement | behaviour-over-time | Row |
|---|---|---|---|---|---|
| `defect` | — | owed | owed | — | ⟦S6: proven / hypothesis⟧ |
| `new-capability` | owed | owed | owed | owed | ⟦S6⟧ |
| `data-structure-change` | owed | — | owed | owed | ⟦S6⟧ |
| `integration-change` | owed | owed | owed | owed | ⟦S6⟧ |
| `investigation` | — | — | — | — | ⟦S6⟧ |
| `infrastructure-change` | — | — | owed | owed | ⟦S6⟧ |

⟦S6: admitted candidates add hypothesis rows — `restructure`: structure-placement; `behaviour-change`: process-flow, structure-placement, behaviour-over-time. Apply the owed-axis rule before grading; never turn "owed" into "—".⟧

**Grades.** E0 nothing answers the axis · E1 the item's own framing names or partly answers it · E2 a delivered design or change answers it in an item-specific passage outside a template-forced section · E2-T the only delivered passage sits in a section or field that the governing template requires for every item regardless of nature, scored as E1 — the list is derived from the templates rather than closed, and includes the issue form's Affected Files and Documentation Impact fields, the release plan's File Change Matrix and Contention Map, the Stage-5 output's Blast Radius and Output for Stage 6 blocks, and the release PR template's Documentation Impact table · E3-P a planned Stage 2–5 refinement added it, scored as E2 on delivered items and never counted for owed-ness · E3-F the item's first framing was silent on it and an operator correction, or a re-scope made because the framing missed it, supplied it. Only delivered items (closed as completed) count as delivered evidence; items closed as not planned are coded and reported but enter no count.

**Owed-axis rule.** An axis a nature does not owe becomes owed only when at least two items of that nature carry framing-level corrective evidence (E3-F) on it, each from its own correction record; an axis already in an item's owed set through a surface nature is explained by that nature and does not count toward this rule. No mark is ever removed here. For each row with at least two delivered items, the owed axes that stayed at E1 or below on every delivered item, with no E3-F anywhere, are reported as over-owed candidates: ⟦S6: per row, the over-owed candidates, "none", or "untested (fewer than two delivered items)"⟧.

**Row grading.** A row is **proven** when at least three delivered items of the nature come from at least two Domain strata, every owed axis shows E2, E3-P or E3-F in at least two of them, and no item of the nature shows E3-F on an axis outside its owed set; otherwise it is a **hypothesis**. Each proven row reports its deliverable-class span beside its strata. An investigation owes no axis: its framing states question, method and time box, and its row is proven when at least three delivered investigation items from at least two strata do so with no E3-F on any axis. Before ratification, this release's acceptance testing blind re-codes the first nine items from the codebook alone and records the agreement in its acceptance report, as k of nine and as k′ of the seven items left once the two drawn items the codebook was refined on are set aside; a nature agreement k below seven of nine leaves every row a hypothesis.

### Coverage states

Per owed axis, a framing records exactly one:

- **answered** — answers the axis question for this epic and names at least one concrete element (an entity; a step; a part and where it lives; a state and what moves it). Restating the question, a placeholder or a pointer to later work is not an answer.
- **declared not applicable** — says the axis does not bind this epic, with an epic-specific reason; without a reason it reads as silent.
- **silent** — neither: a legal, visible state; what it triggers is the rendering surface's decision.

Axes the nature does not owe carry no state: omitted, not marked not applicable.

### How the catalog and the toolkit share the key

The cut-pattern catalog indexes patterns by the work-nature key (one key by default, or nature × deliverable class where a demonstration held); the design-axis toolkit indexes rows by the same key and cites this table or reproduces it as a declared projection matching row for row. Neither defines its own nature list, synonyms or kind-based key. No identifier equals a methodology kind name, work-item type label or category label, so the key never names a methodology archetype's kind. A nature is added only by revising this record while Proposed or by a superseding record.

### Continuity rule

The framing an epic carries — its work nature, its owed axes with their coverage states, its altitude and its overlap considerations — holds in two directions.

- **Into its slices.** A slice set accounts for every axis its parent owed: each is answered by a slice, declared not applicable with a reason, or handed to a named slice. A slice's nature is expected to be among its parent's natures, primary or secondary; a slice whose nature is outside them says why. How the cut reads the framing and records its basis belongs to the decomposition method's framing-to-cut and cut-basis cards, not to this record.
- **Through the later stages.** Triage, refinement, design, solutioning, engineering and testing hold the work to that same framing. A stage that changes the nature, drops an owed axis, moves the altitude or changes the overlap considerations says so and why; it does not inherit a different framing silently.

**One carrier.** At the cut, the framing-to-cut mechanism writes one structured "Framing carry" section into each slice's issue body: the parent reference, the work nature, the owed axes with their coverage states, the altitude and the overlap considerations. Every stage reads the issue body first, so this section is how the framing reaches each later stage, and a stage that changes it follows the platform's existing rule for a stage finding that changes requirements: the acceptance criteria are updated and a comment explains why.

Where each carry is enforced today, or which card owns it: ⟦S6: transcribe the carry table — one row per carry, enforced-by (file and section), an owning card, or "unowned — recommended home"; the stage-to-stage rows include engineering⟧. Until those mechanisms ship, the rule is a named gap in the gate-efficacy standard's gate-coverage register, observed through a dated carry line that compares each slice's framing with its parent's; that line cannot be emitted until the slice-body Framing carry section exists.

Milestone sequencing — which milestone composes which — is a cut and milestone-chain concern, not a design axis: it orders delivery, not the solution. The counter-reading that delivery continuity is behaviour-over-time content was put to the operator, who reframed continuity as this rule.

### Calibration trigger

Each epic framing measured against this record is compared with the owed-axis table. Counting the measured instance as the first framing, the comparison is due when the third framing is recorded, and each later framing re-runs it. It fires on any one of three limbs:

- **under-owed** — a framing needed an axis its nature does not owe: a later correction supplied it, or the framing states why it was needed;
- **unnamed axis** — a framing needed an axis this record does not name;
- **over-owed** — two framings of one nature each declare the same owed axis not applicable, with reasons.

A not-applicable declaration with a reason is never, on its own, a disagreement. When a limb fires, the model is re-decided in a record that supersedes this one; before the Stage-13 ratification gate the record is revised in place. The trigger is a named gap in the gate-efficacy standard's gate-coverage register — no surface yet records which axes a framing needed — observed through the dated framing line the workspace owner appends there at the Stage-13 close of each milestone whose epic was framed against this record, carrying the framing's nature, the framed epic's deliverable class, the axes it needed and the axes it declared not applicable with their reasons.

### Validation set and candidate pool

⟦S6: the pool in prose — issues filed on the improvement form from 2026-06-21T01:22:40Z (Domain field go-live) to 2026-09-27T15:46:56Z whose Domain value normalizes to one of the seven values, excluding the subject spike and its five held cards; strata by Domain value; quota 12, up to 8 closed; seeded; round-robin.⟧ As of the authoring census (2026-09-27): ⟦S6: pool and stratum sizes, closed items completed and not planned, delta against the Stage-5 census⟧. Website, ERP, Code Review and Other had no items, and the Data stratum is one initiative's slicing batch. "Across domains" in this record means across the form's recorded values within one platform. The codebook was refined on three drawn items before coding; its boundary examples were then replaced with items from outside the set.

Deliverable classes (registry concept 1) with delivered items in the pool: ⟦S6: each class, with its resolved and inferred counts, and the unresolved count⟧. Testable for the one-key-or-two question: ⟦S6: the classes and pairs testable, and why the others were not⟧.

| V | Domain | State | Concept-1 class | Nature (secondary) | data | process-flow | structure-placement | behaviour-over-time | Uncovered surface |
|---|---|---|---|---|---|---|---|---|---|
| V-01 | Data | completed | governance | `integration-change` (`data-structure-change`, `new-capability`, `defect`) | E2 | E2 | E2 · E3-P | E2 | none |
| V-02 | Software | completed | governance | `new-capability` | E2 | E2 | E2 | E2 | none |
| V-03 | Governance | completed | governance | fits no nature → matches `behaviour-change` | E2 | E2 | E2 | E2 | none |
| V-04 | Data | completed | governance | `defect` (`data-structure-change`) | E2 | E2 | E2 · E3-P | E2 | none |
| V-05 | Software | completed | software | fits no nature → matches `restructure` | E1 | E2 | E2 | E2 | none |
| V-06 | Governance | not planned | — (marked) | `investigation` (`defect`, `data-structure-change`) | E1 | E1 | E1 | E1 | none |
| V-07 | Data | open | — | `data-structure-change` | E1 | E0 | E1 | E1 | none |
| V-08 | Software | not planned | — (marked) | `infrastructure-change` | E1 | E1 | E1 | E1 | none |
| V-09 | Governance | completed | governance | `defect` | E2 | E2 | E2 | E2 | none |
| V-10 | Data | open | — | `defect` | E1 | E1 | E1 | E1 | none |
| V-11 | Software | open | — | fits no nature → matches `behaviour-change` | E1 | E1 | E1 | E1 | none |
| V-12 | Governance | completed | governance (inferred) | `defect` | E2 | E2 | E2 | E2 | none |
| V-13 | Data | open | — | `data-structure-change` (`defect`) | E1 | E1 | E1 | E1 | none |
| V-14 | Software | open | — | fits no nature → matches `behaviour-change` | E1 | E1 | E1 | E1 | none |
| V-15 | Governance | completed | governance (inferred) | `defect` | E2 | E1 | E2 · E3-P | E1 | none |
| V-16 | Data | open | — | `defect` (`data-structure-change`) | E1 | E1 | E1 | E1 | none |
| V-17 | Software | open | — | fits no nature → matches `restructure` | E1 | E1 | E1 | E1 | none |
| V-18 | Governance | completed | governance | `defect` | E2 | E2 | E2 · E3-P | E2 · E3-P | none |
| V-19 | Data | open | — | `defect` (`data-structure-change`) | E1 | E1 | E1 | E1 | none |
| V-20 | Software | open | — | fits no nature → matches `behaviour-change` | E1 | E1 | E1 | E1 | none |
| V-21 | Governance | completed | governance | `defect` | E2 | E2 | E2 | E2 | none |
| V-22 | Software | open | — | fits no nature → matches `behaviour-change` (`infrastructure-change`) | E1 | E1 | E1 | E1 | none |
| V-23 | Governance | completed | software | fits no nature → matches `behaviour-change` (`defect`) | E2 | E2 | E2 | E2 | none |
| V-24 | Software | open | — | fits no nature → matches `behaviour-change` | E1 | E1 | E1 | E0 | none |
| V-25 | Governance | open | — | `defect` | E1 | E1 | E1 | E1 | none |
| V-26 | Software | open | — | `defect` | E1 | E1 | E1 | E1 | none |
| V-27 | Governance | open | — | fits no nature → matches `restructure` | E1 | E1 | E1 | E1 | none |
| V-28 | Software | open | — | `defect` | E1 | E1 | E1 | E0 | none |
| V-29 | Governance | open | — | `defect` (`infrastructure-change`) | E1 | E1 | E1 | E1 | none |
| V-30 | Software | open | — | fits no nature → matches `behaviour-change` | E1 | E1 | E1 | E0 | none |
| V-31 | Governance | open | — | `investigation` | E1 | E1 | E1 | E1 | none |
⟦S6: State is completed, not planned or open; Concept-1 class marks inferred values; then a summary line — items coded, delivered items per class, per-nature counts, items fitting no nature, multi-nature items and the owed-set widening they cause, candidates admitted, axis co-occurrence⟧

### Applying the model to the measured instance

This is an in-sample consistency check on the source instance, not validation: the four starting axes were taken from this instance, and the out-of-sample test is the calibration framings.

Both epics are `new-capability` (a session record; a channel roster — neither existed), so both owe all four axes.

**Would the owed axes have surfaced the omitted record?** Yes, by construction. The first pass answered `structure-placement` only; `data`, `process-flow` and `behaviour-over-time` would each have read silent — three silent owed axes where the operator named one combined surface ("the flow/data/CRUD surface"). The consumer's behaviour-over-time record answers three at once (write model → `data`; resumption and modality → `process-flow`; session lifecycle and resumption → `behaviour-over-time`): one record may answer several axes.

**Evidence limit:** the consumer's records were not read. The omitted surface is E3-F, from the epic-framing epic's verbatim amendment-log quote; the structural records are E2 (reported, unverified), from its summary.

## Alternatives Considered

⟦S6: one bullet per losing candidate of the Stage-5 design exploration, each with its reason: nature × deliverable class (the default until demonstrated; the falsification test, testable here for at most one nature); a framework wholesale (Who/Why carried elsewhere; six axes add ceremony; the axes cite these frameworks instead); a universal axis set (nothing keyed or omissible); a machine-readable registry (outside a decision spike); a nature attribute on kinds or a type-map column (keys nature on a kind or form; a shared key in a skill-private reference); an intake prompt with no model (one instance, no key).⟧

## Consequences

- **Positive:** catalog and toolkit share one key; an omitted owed axis shows as silent at framing time, not in delivery; small changes omit what they do not owe; a multi-nature item owes what each surface nature requires; the framing carries into slices and later stages through one section of the slice body; recalibration runs through supersession, and a skipped comparison shows as a stale date.
- **Negative:** a small evidence base as of the authoring census — one epic-altitude instance applied in-sample, two deliverable classes among delivered items, a single-cluster Data stratum — so ⟦S6: the hypothesis rows⟧ rest on definitions and practice, and one key is a default rather than a finding; downstream surfaces inherit any error until the trigger fires; the calibration comparison and the continuity rule stay named gaps until the framing surface records coverage and the slice-body Framing carry section ships; the stage-to-stage carries named unowned above have no mechanism yet.

## Reversibility

MODERATE — revised in place or reverted before ratification; after it, superseded rather than edited, at a cost that grows as the toolkit, catalog and framing surface build on it.

## Related ADRs

- ADR-011 — the research-methodology variant that validated this record.
- ADR-018 — the work-item type layer; its "by nature" is not a work nature.
- ADR-019 — specialists compose: consumers cite this key.
- ADR-050 — deliverable domain is orthogonal to work-item type.
- ADR-127 — domain is a parameter of the architect role until a split is demonstrated; its scope is the architect axis, and this record borrows its default by analogy.

## References

- #6420 — the decomposition-method epic whose classification requirement this realizes
- #7540 — the epic-framing epic: measured instance, calibration trigger, continuity ask
- #7959 — the spike that produced this record
- #7960 — the cut-basis card: the considerations a cut records, including altitude and the surfaces it touches
- #7963 — the framing-to-cut card: each owed axis mapped to a slice or a stated reason, and the slice-body Framing carry section written at the cut
- #5592 — the source of the `defect` and `new-capability` boundary examples: an allowlist's host patterns applied to write paths
- #6201 — the source of the `data-structure-change` boundary example: versioned fields added to refusal records
- V-01 — #5844 — one system of record per mirrored data element
- V-02 — #4197 — a check for undeclared CSS custom-property consumers
- V-03 — #4923 — G1-03's evidence predicate and the probe convention
- V-04 — #5846 — mastered project health and the rollup contract's source mapping
- V-05 — #3722 — DOM construction for the eval-review rows
- V-06 — #5589 — the operator-instance home and the XDG read-path
- V-07 — #5843 — one declared key scheme for the entity model
- V-08 — #2344 — skill-to-module lookup in the deploy tools
- V-09 — #6255 — the await-merge phase's terminal state for an already-merged pull request
- V-10 — #5847 — the frozen entity model reconciled with what shipped
- V-11 — #4228 — section-citation coverage and the near-miss store variable
- V-12 — #5055 — the action-items template's restated enums
- V-13 — #5850 — referential action per foreign-key class
- V-14 — #7848 — rate-limit refusal handling converged on one classifier
- V-15 — #2156 — a canonical ADR frontmatter schema
- V-16 — #5845 — the document-index contract at three seams
- V-17 — #7856 — a per-phase projectability declaration for the cleanup dry-run
- V-18 — #5063 — the release-plan version token at Stage 12
- V-19 — #5849 — tracker templates that carry the schema
- V-20 — #7893 — the generated Stage-13 chore-PR body
- V-21 — #4198 — detector constants hand-copied across three sites
- V-22 — #7418 — the install-tests timeout guard
- V-23 — #5057 — declared-versus-live label attribute divergence
- V-24 — #4207 — the FinOps estimator's confidence label on a bimodal set
- V-25 — #5764 — an ungradeable cross-issue criterion retired for a runnable arm
- V-26 — #7548 — heredoc bodies misread as unparseable by the egress rule
- V-27 — #7403 — the posture of standing self-test arms with no blocking CI home
- V-28 — #7552 — a hard-coded jq path the dependency-hardening check misses
- V-29 — #6238 — a committed gate for the retired frontmatter-strip literal
- V-30 — #7855 — the absolute checkout path in close-out report details
- V-31 — #7424 — literal-list cross-issue criteria
⟦S6: one line per follow-up card the continuity table names⟧
