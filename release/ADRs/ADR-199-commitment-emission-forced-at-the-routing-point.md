---
title: "ADR-199 — An emission obligation is forced at the routing point, not at the moment the agent recognises it"
status: Accepted
date: 2026-09-17
release: hub-emits-state-gates-read
deciders: "Stage 5 Solutioning spokes for the joint card pair and for the late-add card (designs, option matrices, evidence-grounding surveys) + three adversarial design reviews + operator decisions at the Collective Review scope-lock (re-scope, warn-mode cutover freeze, transition-safety basis) + operator decision at Stage 6 authorising this record + the Stage 6 Engineering spokes (build, differential probes, corpus re-derivation)"
tags: [forcing-function, emission-contract, decision-briefing, routing-point, commitment-sweep, recommendation-choice-delta, obligation-class, conditional-vs-must, warn-mode-cutover]
source_observations:
  - "The originating population read: the hub-state action-item ledger was absent on 10 of 77 milestone directories, every one of which had emitted decision-class pipeline events, 1 to 81 rows each. The directory exists iff some surface was written, and the ledger is the only surface that would normally write it."
  - "Two of the three hub-state surfaces the first card's title implicates are CORRECTLY absent, on canon rather than on statistics: the session-index surface is declared OPTIONAL and not load-bearing for resume, and the pending-approvals surface fires only at an approval gate reached with no active main-thread session — a condition a main-thread release never meets. A detector built to the card's title would have fired on 69 and 64 of 77 correct releases."
  - "Decision-vs-commitment measurement that falsifies creation-binding: `d-class` rows numbered 2064 across 113 releases while `action-item-*` rows numbered 774 across 58. The first decision-class event of a release is the plan-approval scope-lock, so binding ledger creation to it pre-creates a ledger on runs that record nothing."
  - "The two empty surfaces share no write path: the ledger is a hub-state markdown file written by the template-copy protocol; the choice-delta row is a pipeline-event-log row written by the append tool. The originating run proves it — it wrote 48 event rows successfully while writing no ledger."
  - "The choice-delta subtype measured 30 rows across 12 of 125 releases at authoring, and carried no row at all in the EMISSION-CONTRACT block, which held 18 data rows when read verbatim."
  - "Divergences already recorded in the wrong column, measured at authoring by two independent parsers: 263 over 76 releases by the design's matcher and 256 over 74 by the hub's narrower one, written as free text inside d-class, qa-acceptance, scope-lock, plan-review-go and empirical-verification-finding payloads, where the look-back read-model cannot query them. 225 of them sit on 66 releases that emitted no delta row at all."
  - "Reflexive-binding measurement: the standard carrying the sweep definition appears in 0 of 55 committed skill packages, with the orchestration playbook at 1 of 55 as the sensitivity arm. The standard therefore loads from the repository tree and binds on merge, including for the release that ships it; the playbook reaches the hub only through the deployed mirror."
  - "Catch-up-limb corroboration from the live ledger: the introducing release's first three commitments all carry source_stage 4, created at Procedure 0 — a routing point no sweep point covers, which is exactly the case a point-scoped rendering would have missed."
---

# ADR-199 — An emission obligation is forced at the routing point, not at the moment the agent recognises it

## Status

**Accepted.** Authored at Stage 6 Engineering for the `hub-emits-state-gates-read` release, alongside the two sweep branches it records, the emission-contract row, and the Procedure 4a step-2 clause.

**Numbering provenance.** Claimed as **198** against an anchor of **197** on `origin/main`, read from the repository's own ADR-numbering tool rather than computed as one past the highest number visible on any branch. Sibling branches carried their own claims on this number at authoring; branch-local claims do not bind. The number binds at the Stage-12 claim, and in-release prose cites this record by slug rather than by number.

**Authoring provenance.** The joint design named this record and the ratified File Change Matrix omitted it, so the first Engineering card correctly declined to author outside its locked write set and routed the question up. The operator ruled at Stage 6 that the record is authored here, as a one-file scope override; the decision is recorded in the release plan's Deviation Log.

**Numbering provenance — `198 → 199`.** Held **ADR-198** branch-local; renumbered to **ADR-199** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 198. In-release citations that read "ADR-198" denote this record.

## Context

Two hub obligations were being discharged unreliably, and the corpus already held the evidence for both.

The first is the durable commitment. The emit procedure obliges an action-item row *"when the hub or a spoke makes a durable commitment"* — a state the agent must recognise **in itself**, where every other step of that procedure fires at an observable routing point. Nothing ever asks the question, so the answer is frequently never given: ledgers are absent on releases that emitted decision-class events throughout.

The second is the recommendation-versus-choice delta. The event-log schema defines a subtype for it whose provenance values name decision moments, and the hub's emission contract carried no row for it at all. The result is not silence: the divergences are recorded, in quantity, as free prose inside other subtypes' payloads — a field the look-back read-model cannot query.

Reading both emitters settles what the relationship between them is. The ledger is a hub-state markdown file written by the template-copy protocol; the delta is an event-log row written by the append tool. **They share no write path** — the originating run proves it, having written its event rows successfully while writing no ledger. So they are not one defect with one repair. What they share is the **class**: an emission obligation whose trigger is a state the agent must recognise in itself, with no forcing function at any observable moment. Two defects, one class.

A third piece of context shaped the scope. The first card was titled as though the hub never creates its hub-state surfaces. Read against canon rather than against statistics, two of the three surfaces that title implicates are **correctly** absent — one is declared optional and not load-bearing for resume, and the other's trigger is a condition a main-thread release never meets. Building the card as titled would have shipped a detector firing on the large majority of correct releases. The card therefore re-scopes to the one limb the population supports, plus its own distinct detection limb; the issue body is left as historical record rather than amended, per the substrate-versus-canonical precedent.

## Decision

**Relocate the test from the moment the agent must recognise a state to a routing point that already happens, and make its result a rendering whose omission is a structural defect.**

Concretely: the Decision Briefing gains a **sweep** at each of the routing points at which a record can be created. The sweep asks whether a record is owed. Its answer is rendered in the operator's field of view, and an admissible rendering is required in every case — including the zero case, so that *"the sweep ran and found nothing"* and *"the sweep never ran"* stop being the same silence.

Four sub-decisions carry as much weight as the main one.

**1 — Creation-binding is rejected on the acceptance criterion, not on taste.** Binding ledger creation to the first decision-class event would pre-create a ledger on runs that record nothing, because the first decision-class event of a release is the plan-approval scope-lock and **a decision is not a commitment**. The measurement is in `source_observations:`: decision-class rows outnumbered action-item rows by better than two to one, across nearly twice as many releases. The introducing release's own ledger falsifies the alternative on its face — it opened at the first *commitment*, not at the *decision* one step earlier.

**2 — One mechanism, two branches — because one predicate cannot serve both.** The commitment test and the choice-delta test are not two members of one predicate's domain; they are two **tenses**. A commitment is a future-tense obligation with a lifecycle; a choice delta is a past-tense fact about a completed moment, append-only and terminal at write. The commitment limbs turn on deferral and on the deferred thing being unowned in-release — neither of which a rendered choice has. A conjunct appended to a conjunction already false at its first limb changes no verdict and emits nothing, ever. The repair is therefore a **second two-limb branch**, disjunctive with the first: a record is owed when **either** branch's limbs both hold. One subsection, one set of firing points, one omission-is-a-structural-defect clause, one residue token — and the record's substrate is downstream of the answer rather than a second mechanism.

**3 — The choice-delta obligation ships `CONDITIONAL` on transition safety, with its promotion condition recorded beside it.** Not because the moments it covers are skippable — plan approval and the Stage-9 GO are not, and a derivation resting on their skippability is contradicted by the design's own volume floor, which names both as structurally recommendation-bearing. The sound basis is different and narrower: `MUST` rows are asserted per completed release by the deploy-time close-out check, so promoting this class now would retroactively obligate every historical release, none of which carries a delta row. The **promotion condition** is recorded with the row: the class becomes eligible for `MUST` once every release from this cutover forward carries at least one delta row. Recording it is what keeps the class promotable at all — an obligation whose own premise is *no forcing function* would otherwise be structurally unable ever to acquire mechanical enforcement.

**4 — The obligation's scope stops at the hub-side provenance values.** The retrospective provenance value is owned by the per-session retro skill's own emission contract, which conditions its hindsight path on the live path having emitted none. The hub's row covers the hub-side values and stops; reaching the sixth would be a duplicate-source defect. For the same reason the event-log schema's payload convention is **not** edited: the emission contract block is the corpus's single delimited registry of hub emission obligations, and its own extension seam says so. That outcome stands on the duplicate-source argument alone — an earlier, categorical claim that a payload convention has never owned obligation is **false** and is not part of this record's reasoning.

## Decision kernel (version-agnostic)

*An emission obligation whose trigger is an agent-recognised state has no forcing function. Relocate the test to an already-observable routing point and make its result a rendering whose omission is a defect. Where the same routing point owes records of more than one kind, add a branch to the one sweep rather than a second sweep — and let the substrate follow the answer instead of deciding it.*

## Alternatives Considered

| # | Alternative | Why not |
|---|---|---|
| A | **Detect at close** — report whether the run *should have* written a record | A backstop, not a repair; it cannot make a record exist. Retained in narrowed form as a detection limb rather than as the mechanism. |
| B | **Bind record creation to the first decision-class event** | Rejected on the acceptance criterion — a decision is not a commitment, so this pre-creates a record on runs that record nothing. See Decision sub-decision 1. |
| C | **Assert the pairing as a standalone check** (decision count × record existence) | Cannot live standalone, and overlaps an existing integrity arm unless narrowed. Folded in, narrowed. |
| D | **Fire the absent-record state earlier than close** | The same enrichment as A at a different time; folded into the same surface rather than kept separate. |
| E | **Declare the ledger the only sanctioned home** | A prohibition with no detector is the shape of defect already under repair, and it over-reaches: a release plan legitimately *summarises* the ledger. Kept as a one-line rule — the plan may **cite** the ledger, never **substitute** for it. |
| F | **Admit the second subject under the first branch's limbs unchanged**, or **append a third conjunct to them** | Both inert, and falsified rather than doubted: the first limb fails for the second subject by inspection of the schema's own enum, so either shape ships a forcing function that forces nothing. |
| G | **Generalise the incumbent limbs into one record-class-parameterised test** | The shape that most literally satisfies *one mechanism* — and correctly rejected on cost: it re-opens text a sibling card authors in the same release, creating a genuine contention where the disjunctive second branch creates none. Its useful half was taken instead, by writing the sweep's invocation clause branch-agnostically so it reaches every branch by construction. |
| H | **Ship the second obligation as `MUST`** | Every historical release would acquire a retroactive obligation under the close-out check. See Decision sub-decision 3; the promotion condition is what keeps `MUST` reachable later. |
| I | **Author a second record for the second branch** | One decision would be fragmented across two records — the duplicate-source shape this release exists to remove. The slug names the founding case; this record covers the class. |

## Consequences

**What improves.** An obligation that nobody was asked to discharge becomes a question the routing point always asks, with an answer a reader can see. The second branch converts divergences currently held as unqueryable free text into the column the detector reads. The explicit zero-state means an absent record is distinguishable from an unasked question — the property without which every count over this population is unfalsifiable.

**What it costs, stated rather than discovered.** The second branch adds event-log volume, bracketed at authoring between a floor and a ceiling roughly five times apart; the bound is the rule that a rule-determined value is a recorded determination and not a recommendation, which is stated as a limb rather than left to judgment. The sweep renders its own count at each routing point, so realised volume is visible in-run at the first release rather than later in an append-only log.

**What it does not do.** It **does not relocate facts the log already holds.** No back-fill is proposed and the write medium forbids mutation, so every historical divergence stays exactly where it is and stays invisible to the look-back reader. What the measured population establishes is that the phenomenon is frequent and currently unreadable; this decision makes **future** instances readable and recovers none of the historical ones. Forward, the same fact can land in two rows, which is why the standard now names which one answers a gate's question: **the delta row is canonical for the detector; a prose payload describing the same divergence is narrative.**

**Reflexive binding, decided rather than inherited.** The standard carrying the sweep definition is **not deployed** — it loads from the repository tree, so the obligation is in force from the merge, **including for the release that ships it**. The playbook carrying the invocation ships inside a skill package and binds only at the next deploy. Between those two moments the obligation is live with no forcing function behind it, which is this defect class reproduced by its own rollout. The sweep therefore ships **warn-mode** under a named cutover clause: for the shipping release's remaining routing points an unrendered sweep is reported, not blocked, and the clause is **named rather than numbered** into the standard's protocol series, so no count cascades and no sentence falsely asserts the sweep shipped in that standard's introducing release.

**Residue that is named, not classified.** Where one utterance splits by object — a finding carried elsewhere and an edit owed in-release — the rule names the case `UNDECIDED` and the operator dispositions it. The claim this test makes is not that it resolves everything; it is that it either resolves or names the residue. `UNDECIDED` is a briefing rendering and never a gate state, deliberately distinct from the gate-side residue that fails closed at close: different register, different authority, different remedy.

**Coverage bound.** Each sweep covers its own routing point and every preceding routing point of the release at which no sweep was rendered. Close is total over completed releases and is a sweep point, so no record escapes the sweep in a completed release. This is a window, not a new routing point: no firing point is added and no cadence count changes.

## Reversibility

**CHEAP · confidence HIGH.** Every surface this decision touches is prose — one subsection in a standard, one row inside existing delimiters, one clause inside an existing procedure step. Reverting is a revert of those hunks plus a package rebuild; no tool, interface, enum value, or schema field is added, and the new emission row is inert in every obligation-keyed aggregate by the extractor's own filter. The one durable residue of a revert is any event row already written under the obligation, and an extra correctly-shaped row in an append-only log is readable rather than harmful.

## Related ADRs

- [`ADR-181`](ADR-181-adr-citations-bind-at-the-claim-not-at-authorship.md) — ADR citations bind at the claim, not at authorship. Governs this record's slug-token citation form and its numbering provenance.
- [`ADR-195`](../../core/ADRs/ADR-195-pack-content-lint-sibling-vs-extend.md) — the sibling-versus-extend reasoning, whose *reuse would conflate* clause is applied in both directions here: it refuses reusing the gate-side residue token for the briefing residue, and it refuses minting a second residue token inside one subsection.
- [`ADR-197`](ADR-197-action-item-status-classified-by-membership.md) — the close-time gate that reads the ledger this decision causes to be written; its residue-is-a-state-never-a-verdict determination is the gate-side counterpart to the briefing-side residue here.
- [`ADR-062`](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md) — the substrate-versus-canonical precedent under which the re-scoped card's issue body is left as historical record rather than amended.
