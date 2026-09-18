---
title: ADR-199 — The pack consumer contract is tiered, and its middle tier is read defensively
status: Accepted
date: 2026-09-18
release: authoring-bar-and-consumers
deciders: Workspace owner (Stage-5 Collective Review scope-lock; the post-Stage-7 authorization to implement the held File Change Matrix rows), Stage-5 Solutioning spoke, Stage-5 Phase A6.5 adversarial reviewer, Stage-6 Engineering spoke
tags: [work-item-types, methodology-packs, consumer-contract, tiering, enforcement, not-evaluated, gate-coverage]
source_observations:
  - "Measured 2026-09-18 over the tracked type-pack corpus with two independent instruments required to agree — the shipped pack reader's parse_pack, and a raw-text scanner over the manifest tables written separately for this pass. Both read 19 tracked pack.toml manifests and 23 declared kinds, with 0 instrument disagreements and 0 degraded parses. Unprojected kinds: 0 of 4 shipped, 0 of 6 fixture kinds in packs declaring a labels facet, 13 of 13 fixture kinds in packs declaring no labels facet at all. Packs projecting some of their kinds while omitting others: zero. Sensitivity arm, a synthetic two-kind pack projecting one kind: the unprojected figure moves and the partial-projection population becomes non-empty. Control arm, the same pack projecting both: neither moves. Specificity arm, an unguessable sentinel kind id and an unguessable sentinel table header: zero."
  - "The same corpus read at the Stage-5 design baseline carried 21 declared kinds where this tip carries 23. The numerator held at 13 and the denominator moved, which is the behaviour that makes the ratio the wrong thing to record."
  - "PACK-L02 iterates the pack's label rows, so a declared kind is never the loop's subject, and it requires each type-prefixed row's projects_kind to resolve into the declaring pack's own kinds array — so no central label source exists for a kit to inherit a carrier from."
  - "Executed against a scratch copy of the rollup-kit fixture: a type-prefixed label row removed while its kind stays declared validates clean at exit 0. Paired control, the same row's projects_kind repointed at an undeclared kind: PACK-L02, exit 1. Both runs self-reported an identical read scope, so the pair differs in verdict and not in population."
  - "The disposition token NOT-EVALUATED was already live in this corpus at two narrower scopes before this decision adopted it generally: the type-pack meta-schema applies it to the status axis when no platform adapter is configured, and the gate-criteria specification's Gate-1 Step 0 applies it to the kind vocabulary when that vocabulary cannot be read, where it is explicitly ranked as a fifth outcome that is not a verdict."
  - "The work-item-type consumer map declares itself descriptive and not a gate, and records that a criterion phrased as conformance to the map is ungradable. The type-packs README declares its own subject to be pack layout, roles, inheritance and composition — the authoring view."
supersedes: none
---

# ADR-199 — The pack consumer contract is tiered, and its middle tier is read defensively

## Status

Accepted. The decisions recorded here were ratified at the Stage-5 Collective Review scope-lock for the `authoring-bar-and-consumers` release, and the consumer-side reading rule they govern shipped in the type-pack meta-schema during that release's Engineering pass.

**Authored after Stage 7, and the record says so rather than reading as contemporaneous.** This record is one of two File Change Matrix rows the Engineering brief under-enumerated. The Engineering spoke implemented the rows it was authorized for and held these two rather than widening its own authorization, which left the design's acceptance criterion for this record ungradable. The operator authorized both rows after Dev Testing raised it. The decisions are unchanged from the scope-lock; only the record is late, and it is owed a targeted re-review rather than a fresh ratification.

**Numbering provenance.** This record was authored at the next free number computed from the mainline anchor plus one, advanced past the slots already occupied by two sibling records on this same release branch. A branch claim is detection-only and never binds for mainline purposes, but a same-branch claim is a file that already exists, and taking its number would be a duplicate rather than a claim. Stepping *above* the sibling claims to leave room would land a gap, which the contiguity gate fails as readily as a duplicate. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Citations use the slug token `{{ADR:consumer-contract-is-tiered-and-unenforced}}`, which carries no number shape and resolves at the claim.

## Context

The type-pack grammar states its boundary from the **producer's** side: what a pack may declare, and what the platform fixes regardless of what a pack declares. Nothing stated the **consumer's** side — what a program reading a *resolved* kit may actually rely on, and what it must do when a reliance fails.

The absence had a specific shape, and it is why a general "document the contract" answer would have missed. A consumer cannot read the producer-side rules and derive its own contract from them, because the producer-side rules do not distinguish the three things a consumer needs kept apart: a property the grammar fixes *and* the resolver enforces; a property some rule states but nothing executes; and a property no rule states at all. Collapsed together, those read as one undifferentiated set of guarantees. A consumer that trusts them uniformly renders confident verdicts over inputs it never actually read — and a clean verdict over an unread population is exactly the gate-that-cannot-fail defect this release's sibling work exists to make countable.

Two further forces bound the answer. **The enforcement surface is in motion**: runners ship, flip posture, and close named gaps release over release, so any partition keyed on *what is enforced today* would re-partition every time a check lands. And **the corpus measured for this decision moves too** — the declared-kind population grew inside this very release, which is what turned an early framing of the central finding as a ratio into a liability.

## Decision

**Part 1 — The contract is tiered into three, and the partition is by specification-presence, never by observed enforcement.** A property sits in the guaranteed tier or the specified-but-unenforced tier because *a rule states it* — this grammar's, or the contract of the resolver that reads it — whether or not any runner executes that rule; and in the absent tier only where **no rule states it at all**. Partitioning by "does something read it?" instead would classify schema-fixed keys as absent and instruct a consumer to skip a key the grammar requires. Enforcement is reported **per property**, in its own column, and is never the basis of the split. A runner shipping or flipping therefore re-derives that column and moves no property between tiers.

**Part 2 — What separates the first tier from the second is what the specification is *about*, not how firmly it is enforced.** The first tier is specified of the **kind set a resolution delivers** — which kinds there are and what each is called. The second is specified of the **declaration behind each resolved kind**, the join surface a consumer reads by name. The resolver keys its union on the kind identifier and consults no second-tier key, so the first tier reaches a consumer *already resolved* while every second-tier key reaches it *unconsulted*. That asymmetry — and not a guarantee — is why the disposition rule reads the two tiers differently.

**Part 3 — On a second-tier violation the consumer emits `NOT-EVALUATED`, naming the kind, the key, and the denominator, and renders no verdict for that kind.** Never a silent default, never a substituted kind, never an unreadable input reading as a clean one. **The denominator is required, not advisory**, because the rule can otherwise hide its own failure: a consumer emitting the caveat for every kind it meets is indistinguishable from one working correctly unless the emission carries *kinds read* against *kinds evaluated*. Without it, a rule written to prevent a vacuous clean verdict produces a vacuous caveat instead — the same defect in the opposite sign. The three-element form is the contract; the two-element form is not a shorthand for it.

**Part 4 — The absent tier is not read at all.** A consumer neither relies on an absent-tier property nor emits a caveat for its absence, because there is no specification for it to have violated. A caveat there would be noise indistinguishable from a real finding.

**Part 5 — The rule extends the producer-side section rather than opening a consumer-side file.** One boundary maintained in two files that must agree is the duplicate-source pattern the grammar's own gap-recording section declines by name for the coverage register. The producer half is already in that section; the consumer half joins it.

**Part 6 — The asymmetric limb is registered as a second limb of an existing register row, and is recorded as a zero-instance invariant rather than as a statistic.** Nothing requires a declared kind to carry a type-prefixed label row: the enforcing rule walks the label rows, so a kind is never its subject, and the rule additionally binds each row's projection into the declaring pack's own kind set, so no central label source exists to inherit a carrier from. The consequence is **conditional rather than realized** — a kit declaring kinds and no type rows resolves cleanly, validates cleanly, and produces work items that cannot be typed on the label surface every create, update and delete path joins through — and, as of authoring, no such pack exists in the corpus. The gap is in the rule, not in the fixtures that exercise it.

**Part 7 — The interim contract claims no coverage it does not have.** The consumer-side rule mints no rule identifier, declares no resolution pointer, and adds no register row. The restraint is **editorial**, on the ground that the register and not the grammar is the authority on coverage — and explicitly *not* mechanical, because the resolution-pointer check never reads the grammar file at all. Stating that distinction precisely is the point: a restraint defended on a mechanical ground that turns out to be false is a claim waiting to be retracted.

## Alternatives Considered

**Where the consumer contract lives — four candidates, one selected.**

| Candidate | Verdict | Why |
|---|---|---|
| A net-new consumer-contract standard | **Rejected** | Splits one boundary across two files that must agree — the move the grammar's own gap-recording section declines by name for the register. It also fails the reuse bar: an existing surface plainly covers it. |
| Extend the type-pack meta-schema's boundary section | **SELECTED** | The producer half is already there; the section's own rationale *is* the question being answered; its placement test is the instrument a consumer rule composes with; and it already routes coverage questions to the register. |
| Extend the consumer map | **Rejected** | That file declares itself descriptive and not a gate, and records that a criterion phrased as conformance to it is ungradable. A normative rule there contradicts the file's stated nature. |
| Extend the type-packs README | **Rejected** | That file owns layout, roles, inheritance and composition — the *authoring* view. A consumer rule there is invisible to a consumer, who reads the schema. |

**What a consumer does on a middle-tier violation — four candidates, one selected.**

| Candidate | Verdict | Why |
|---|---|---|
| Fail loud / exit non-zero | **Rejected** | Correct for the guaranteed tier, where it is already implemented. Wrong for the middle tier, which is unenforced *by decision*, so any pack can trip it — a hard failure turns a documented gap into an outage. |
| `NOT-EVALUATED` + named caveat + denominator | **SELECTED** | Distinguishes *not measured* from *measured clean*, which is the whole difference. Two narrower corpus precedents already carry the token, so adopting it verbatim composes with a live vocabulary instead of forking it with a synonym. |
| Silent skip | **Rejected** | A clean verdict over an unread population — precisely the defect class this boundary exists to make countable. |
| Best-effort partial evaluation | **Rejected** | On a shredded parse, "best effort" evaluates fragments: a wrong answer with a confident shape, which is worse than no answer. |

**How to record the asymmetric limb — two candidates.** A **new** register row for the unprojected direction was rejected: the grammar states one invariant over the aggregation contract whose two directions are enforced unequally, so a second row would assert a second invariant that the grammar does not declare, and it would move the resolution-pointer check's denominator for a gap that has no runner to point at. **Extending the existing row** was selected, and the register-side rule that every named gap carries a row with its declared observable is what obliges the extension rather than leaving the limb stated only in the grammar.

**How to state the asymmetric finding — ratio versus invariant.** Stating it as a raw ratio of unprojected kinds was rejected on the independent adversarial review's evidence: the denominator is the population the *probe* could reach, not the population the *claim* is about, and the split by pack class shows a perfect one-directional correlation — every pack declaring a labels facet projects every one of its kinds. The ratio therefore measures minimal fixtures being minimal rather than drift, and a reader who sees the decomposition can dismiss the finding. The invariant statement, with the failure shape named and its instance count recorded as zero, is both more durable and harder to dismiss. The subsequent corpus growth confirmed the reasoning empirically: the denominator moved within the release and the numerator did not.

## Consequences

**Easier.** A consumer has one place to read what it may rely on, and a rule for what to do when a reliance fails that does not require it to know which runners currently exist. A runner shipping or flipping posture updates one column and moves nothing between tiers, so the contract is stable against exactly the change that happens most often. The `NOT-EVALUATED` emission with its denominator makes an unread population **countable** at the consuming surface, which is what a reviewer needs to distinguish a working consumer from a uniformly-caveating one.

**Harder.** Consumers must now branch before reading, which is more code than trusting the declaration — that cost is the decision, not a side effect. The tier table and the enforcement column live in one section, so a reader skimming for guarantees can mistake the column for the tier; the section states the direction explicitly to counter that, and it remains the likeliest misreading.

**Accepted residuals, named rather than smoothed.** The contract is **interim**: it states what a consumer may assume today and defers the machinery for revisiting that. The asymmetric limb is registered as a named gap with no runner and no resolution pointer, so it stays *stated and unexecuted* until a lint reads the unread direction — this record makes that condition visible, it does not close it. And the measured figures grounding the limb are point-in-time: they are pinned in this record's grounding-observation block with their date and their instruments, and a reader relying on a number re-derives it rather than quoting it.

## Reversibility

**CHEAP / Confidence HIGH.** Every artifact is prose in durable corpus — a boundary section, one register row extended in place, and this record. Nothing mints an identifier, declares a resolution pointer, adds a register row, changes a validator, or edits a pack or fixture, so no runner's behaviour and no gate's denominator depends on any of it. Reverting is a documentation revert with no migration. The tiering itself is a *reading* of declarations the grammar already carries, so a future re-partition costs a re-derivation of one column rather than a change to the grammar.

## Related ADRs

- [ADR-069](ADR-069-methodology-pack-composing-unit.md) — establishes the pack as the composing unit and keeps the grammar archetype-invariant while concrete rows live in the selected packs; this record states the consumer-side reading of that grammar.
- [ADR-070](ADR-070-methodology-pack-composition-grammar.md) — the pack-composition layer, including the label contribution facet whose one-directional binding is the asymmetric limb registered here.
- [ADR-198](ADR-198-per-kind-authoring-bar-is-a-reading-not-a-carrier.md) — the sibling determination from the same design pass that a per-kind bar is a *reading* of declared grammar rather than a new carrier; this record applies the same extend-over-create move to the consumer side.
- [ADR-181](../../release/ADRs/ADR-181-adr-citations-bind-at-the-claim-not-at-authorship.md) — why this record's branch-authored citations use a slug token rather than a literal number.

## References

- #6379 — the work item asking whether any project can be consumed by any consumer, which framed the interim-contract question this record answers.
