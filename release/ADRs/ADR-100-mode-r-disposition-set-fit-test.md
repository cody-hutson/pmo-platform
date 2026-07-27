---
title: "ADR-100 — Milestone-readiness disposition set: closed as a vocabulary, not a cardinality"
status: Proposed
date: 2026-07-27
release: release-hub-mode-r-depth (v3.98 provisional; bound at Stage 12)
deciders: "Stage 5 Solutioning spoke surfaced the enum question and recommended the fit test; the operator ratified at the Stage-5 scope gate; Stage 6 Engineering authored this record; the operator ratifies the Accepted flip at the Stage 9 plan-review gate"
tags: [architecture, release-pipeline, release-hub, milestone-readiness, enum, disposition, precedence-ladder]
source_observations:
  - "A readiness-checklist group was added that maps onto no existing disposition: the finding is that a card's work is already owned by another open epic, and the operator action is to MOVE the live card to its owning epic. Testing the finding against each existing value in turn showed none fits — fix-in-place (the card needs no fix), re-validate a moved premise (the premise is fine; the home is wrong), remove already-completed work (the work is live), and re-bundle (milestone-scoped, and it names no destination for the card)."
  - "The disposition set's own governing sentence asserted the set 'stays exactly' its then-current four values, justifying the freeze by the fact that the preceding group had mapped onto an existing value. That sentence hardcodes current membership rather than stating the rule that produced it, so any future group invalidates it — and it directly contradicts the addition above."
  - "The subsumption protocol that the removal disposition implements terminates in CLOSING the subsumed issue (its final step is titled 'Close the Subsumed Issue', with close reason 'not planned'). A rehome closes nothing. Mapping a move-finding onto the removal value would put a close protocol behind a move finding."
  - "Three of the four live restatements of the set constrain MEMBERSHIP and are silent on cardinality; the recommend-only boundary states the labels with an explicit open-ended ellipsis. The single cardinality-asserting site was therefore the outlier, not the convention."
---
<!-- reference-durability: allow-link -->

# ADR-100 — Milestone-readiness disposition set: closed as a vocabulary, not a cardinality

## Status

Proposed — authored at Stage 6 Engineering; ratified at the operator's Stage 9 plan-review gate. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure.

## Context

The milestone-readiness pre-flight emits, per finding, a **disposition** — the named action the operator is expected to take. The dispositions are drawn from a closed set enumerated in one authoritative table and mirrored at a small number of other sites.

"Closed" was being read two incompatible ways in the corpus at once. Most sites constrained **membership** — a finding carries a value *from* the set, never an ad-hoc label — and said nothing about how many values the set contains. One site instead asserted a **cardinality**: that the set "stays exactly" its then-current four values, justifying the freeze on the observation that the most recently added checklist group had mapped onto an existing value rather than adding a new one.

That reading is fragile in two distinct ways. First, it is anti-durable: it hardcodes current membership rather than stating the rule that produced it, so the sentence must be rewritten every time the question is asked. Second, and more seriously, it misreads its own precedent. The preceding group mapped onto an existing value **because that value fit** — its finding genuinely *was* a moved architecture premise, which is exactly what the re-validation disposition names. The precedent records a **fit test**, not a decision to freeze the count. Applied as a cardinality rule, it forces any subsequent group's finding onto the nearest-sounding existing label regardless of whether the label names the right operator action.

The forcing case arrived with a group whose finding is that a card's work is **already owned by another open epic** and whose operator action is to **move the live card to its owning epic**. Tested against each existing value in turn, none fits. The nearest candidate — the removal disposition — is the worst available match rather than the closest one, because the protocol it implements **terminates in closing the subsumed issue**. A rehome closes nothing; it moves live work to a different parent. Collapsing the two would place a *close* protocol behind a *move* finding, and every emission would need prose contradicting its own label.

A second, independent problem surfaces the moment a second overlapping group exists: one card can trip two groups at once (already shipped **and** owned elsewhere is a real state), and the two findings recommend opposite actions. The set needs a rule for resolving that, and the rule needs a home.

## Decision

**The disposition set is closed as a finite named vocabulary, not as a fixed cardinality.**

1. **Membership, not count.** Every finding carries a value from the authoritative disposition table, never an ad-hoc label. The set is closed in the sense that its members are enumerated and named; it is *not* frozen at whatever size it currently happens to be.

2. **The fit test governs additions.** A new readiness-checklist group **maps onto an existing disposition unless it introduces a materially distinct operator action** — a different thing for the operator to *do*, with a different destination. Mapping is the default and the common case. Adding a value is permitted only when the fit test is run against every existing value and none fits; the test and its result are recorded where the set is defined.

3. **One authoritative enumeration.** The disposition table in the milestone-readiness checklist is the single authoritative statement of the set. Every other statement of it — in the readiness mode's process roll-up, in its output contract, anywhere else — is a **mirror** and must agree with the table. A mirror that disagrees with the table is a defect in the mirror.

4. **A precedence ladder resolves multi-group hits to exactly one disposition per card.** When a card trips more than one group, the higher-precedence disposition wins. Terminal and mechanical dispositions outrank relocation, which outranks in-place fixes; a milestone-scoped disposition is evaluated once per bundle rather than per card and does not participate in the per-card ladder. The concrete ordering is stated with the table, not here — this ADR binds the *existence and shape* of the ladder, so that adding a value obliges the author to place it in the order rather than leaving the ambiguity to the reader.

5. **The rule is stated as an invariant, not as an inventory.** The governing sentence at the definition site states the fit test and points at the table; it does not enumerate current membership. Any future group is governed without editing that sentence.

## Alternatives Considered

- **(b) Map the ownership finding onto the existing removal disposition and leave the set at four values.** This option was genuine, not a strawman, and it carried real strengths: it follows the most recent shipped precedent as commonly read, it needs no ADR, it requires the smallest edit, and at least two already-shipped cards were designed against a four-value set. It was **rejected on two grounds**. First, the **four-way fit test**: each existing value was tested against the ownership finding and none names the operator action, so the mapping would be a forced fit rather than a fit. Second, the **opposite terminal actions**: the removal disposition implements a protocol whose final step closes the subsumed issue, whereas a rehome closes nothing — so the mapping would put a close protocol behind a move finding and require a prose override at every emission. A label that must be contradicted in prose is not a working enum value. Note also that (b) is not the zero-edit option it appears to be: the cardinality-asserting sentence must be rewritten under either option, because under (b) it must be extended to justify the new group's mapping and remains anti-durable regardless.

- **(c) Keep the cardinality freeze and forbid new groups from producing findings that do not map.** Rejected as a constraint on the wrong object: it would let the shape of an existing vocabulary decide which readiness checks may exist, inverting the dependency. The checks answer to the backlog's real failure modes; the vocabulary answers to the checks.

- **(d) Fold the ownership finding into an existing adjacent group so no new group — and therefore no new disposition — is needed.** Rejected because it modifies an existing group rather than appending a new one, which breaks the append-only numbering that downstream consumers and every in-corpus group citation depend on. It also does not actually solve the problem: the finding still needs a disposition naming the move.

The chosen option's real costs are recorded honestly: it requires the precedence ladder (genuinely new machinery), it requires rewriting the definition-site sentence, and it requires this ADR. The ladder is a cost of the decision, not a hidden one — but (b) does not avoid the ambiguity, it relocates it from an explicit written rule into the operator's head at read time, which is strictly worse.

## Consequences

**Positive.**
- A new checklist group can be added without renegotiating what "closed" means; the fit test answers the question mechanically and the answer is auditable.
- The default remains *map onto an existing value* — the set does not drift upward, because addition requires demonstrating that all existing values fail.
- Multi-group collisions have a defined resolution, so a card cannot carry two contradictory recommended actions.
- The definition sentence becomes durable: it states a rule that stays accurate without manual updates rather than an inventory that any addition invalidates.

**Negative / accepted.**
- The set is enumerated at a small number of mirror sites rather than single-sourced. This duplication is **accepted deliberately**: those enumerations are the grep-anchors that mechanical consistency checks depend on, and converting them to pointers would trade a *detectable* drift for a *silent* one. The population is small and every mirror is named as a mirror.
- Each addition now obliges the author to place the new value in the precedence ladder — a real authoring cost, and the intended one.
- Any consumer that hardcoded the set's size (rather than its membership) would need updating. No such consumer existed at authoring time; the readiness mode is read-only and persists no disposition value, so the set lives only in transient briefings.

## Reversibility

**CHEAP** · confidence **HIGH**. The decision governs a read-only advisory mode that mutates and persists no state — a disposition value exists only inside a briefing the operator reads. Reverting means removing a value from the table and its mirrors and restoring the prior sentence; no migration, no orphaned records, no downstream data carries the value. The one residual is that a consumer which had begun persisting findings would hold an orphan value after a revert; that residual is bounded by the read-only contract and is re-assessed if a persisting consumer ever ships.

## Related ADRs

- **ADR-019** (specialists compose, don't absorb) — the readiness mode owns no check logic; the groups whose findings this vocabulary labels are each owned by a composed skill or spec. This ADR governs the shared *disposition vocabulary* those composed verdicts roll up into, which is the orchestration layer's own contract rather than any composed skill's.
- **ADR-033** (methodology-conditional activation) — cited by the checklist group whose finding mapped onto an existing disposition, and therefore the shipped worked example of the fit test returning "map" rather than "add".
