---
title: "ADR-221 — An evicted auto-memory entry is archived nowhere by default, and only operator-locally when elected"
status: Proposed
date: 2026-10-16
release: authoring-conventions-enforced-or-retired
deciders: "Workspace owner (operator) — the decision rendered at the release's Stage-5 Collective Review scope-lock, with the independent adversarial review's counter-designs on the unit of eviction, the absorption gate and the binding actor taken; design by the Stage 5 Solutioning spoke (Principal Engineer persona); authored by the Stage 6 Engineering spoke"
tags: [memory-architecture, encode-and-evict, archive, public-surface, release-plan-manifest, unit-of-eviction, reversibility]
source_observations:
  - "The encode-and-evict lifecycle carried an archive phase that pasted an evicted entry's full body, index line and ledger row into the executing stage's hosted sub-task comment. On a public repository that publishes operator-local content, and a hosted comment's edit history outlives a later edit."
  - "An evicted entry is one whose rule has been encoded into the corpus, and encoding deliberately drops operator-specific context. The verbatim body is the untransformed original, so the archive published exactly the residue the encoding removed."
  - "A close-out executor reached the archive step, judged the destination wrong for the content and stopped. Nothing mechanical would have stopped it."
  - "The phase served two purposes. Recoverability is served by the eviction itself, which is a Trash move the containment hook admits. Enumeration for the close-time absorption reconciliation is served by the release plan's manifest, which identifies entries by tie."
  - "The Trash's retention is finite and local, and no step of the lifecycle observes it. That bound is the one fact the design named as moving the choice from no archive toward an elected operator-local copy, and it is the basis the scope-lock recorded for that choice."
  - "The store's tie relation is many-to-many: one card has carried several entries, and one ledger row may cite several cards. A row that identifies a single entry by its position among a tie's entries cannot be bound without reading entry bodies, so the tie, with a planned count, is the unit of eviction."
supersedes: ADR-045 in-part (Decision item 4) — the archive-first property only; the graduation framing of item 4 and every other item stand
---

# ADR-221 — An evicted auto-memory entry is archived nowhere by default, and only operator-locally when elected

## Status

**Proposed** — authored at Stage 6 Engineering of the `authoring-conventions-enforced-or-retired` release. The operator rendered the decision at that release's Stage-5 Collective Review scope-lock. Ratification is the operator's at the Stage 13 close gate and is recorded in this file's frontmatter `status:` field.

**Numbering provenance — `217 → 221`.** Held **ADR-217** branch-local; renumbered to **ADR-221** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 217. In-release citations that read "ADR-217" denote this record.

## Context

The lifecycle that graduates knowledge from the operator's auto-memory store into the corpus included a phase that copied each evicted entry verbatim into a hosted comment before removing it. The repository is public. The copy existed to make an eviction recoverable and to give the close-time absorption reconciliation a list to diff. Both needs are real; the destination was chosen by convenience, and nothing read a hosted comment for entry content.

Removing the copy raised a second question the original phase had hidden: what a manifest row identifies. A store entry is tied to the codification card that encodes it, and that relation is many-to-many, so a row that names one entry by its place among a tie's entries cannot be bound to an entry without reading entry bodies — the judgment-dependent kind of control the decision exists to remove.

## Decision

1. **No archive by default.** An evicted entry's archive disposition is `none`. No phase copies an entry's body, its index line, or its pointer or ledger row to any other surface — a tracked file, an issue, a pull request, a comment on either, or a second file in the store.
2. **An elected copy is operator-local and operator-made.** Where the operator elects it for a row, the disposition is `operator-local`: the operator copies the entry to a location of their own, outside the store and outside every git working tree, and EVICT waits for the operator's confirmation. The executor never makes the copy, and the lifecycle names no location.
3. **Recoverability is the Trash move.** EVICT moves the entry to the Trash; an eviction made in error is undone by restoring it. That lasts until the Trash is emptied, and the lifecycle says so.
4. **The tie is the unit of eviction.** A manifest row covers one tie: every corpus home and every corpus-presence probe the card writes, and the planned count of ledger rows citing the tie. The row executes all or nothing — every probe passes and the count at execution equals the planned count, or nothing in it is evicted. An entry holding more than its encoding kept is split first; an entry whose ledger row cites more than one issue stops its row. Each probe names the file the encoding was written to, is read against `origin/main`, carries the reading it gives at the release's merge base, and passes only when it reads 0 at the release's merge base and at least 1 on `origin/main`.
5. **The absorption gate is a post-state test.** After EVICT and RE-POINT, no ledger row may still cite a tie the manifest names or the number of a codification issue the release closes; any row that does is stranded and blocks the close.
6. **The hub binds and names.** The hub resolves each tie to its entries at the Tier 1 authorization, shows the operator that set as the enumeration the approval covers, and hands the executor the resolved entries in its operator-local brief. Public records carry ties and counts only.
7. **A row that names a destination is not executed.** The executor declines it at manifest validation and records it; the close gate is not met until the row is corrected or the operator's disposition is recorded as its documented exception, and the hub takes the row to the operator.
8. **The rule is stated once**, in the memory↔corpus boundary's lifecycle. The release-plan template restates the disposition value set because it ships in a package where that file is not reachable; the restatement states nothing the lifecycle does not.

## Alternatives Considered

- **No archive at all, with no election.** The design's own recommendation and the strongest losing option. It is what the rule's logic implies — a second copy of codified knowledge is the shadow the eviction removes — and the operator rendered it once before. Not taken as the whole rule because recoverability under it is bounded by a finite local Trash retention that nothing observes; the election keeps that path open for an entry whose wording the operator wants kept, at the price of one confirmation inside an approval that already happens. The default is this option.
- **An operator-local archive of every entry.** Rejected: it makes a second copy mandatory for content whose point is that it now has one home, and restores a standing per-eviction operator step.
- **A subdirectory of the store.** Rejected: a copy left in the store is the shadow copy the eviction removes, and the standing drift audit would flag it at every run.
- **The hosted comment, redacted.** Rejected: a public surface, a judgment-dependent control, and an error that cannot be retracted.
- **A pointer stub in place of removal.** Rejected on the reasoning ADR-216 already records.
- **One manifest row per entry, told apart by its corpus home and its position among the tie's entries.** Rejected: the position has no order, and telling entries apart by corpus home means reading entry content at the irreversible step.

## Consequences

- **+** No step of the lifecycle publishes operator-local content, and the instruction that asked for it is gone rather than guarded.
- **+** The executor has a stated stop rule where it previously had only its own judgment, and nothing it does binds a row to an entry by content.
- **+** The absorption gate sees an eviction a manifest carries for another release's card, and a listed entry whose eviction did not run.
- **+** The lifecycle's count of phases no longer appears in prose, so the next change to the list does not cascade.
- **−** An eviction made under the default is unrecoverable once the Trash is emptied. A corpus-presence false pass that coincides with an emptied Trash loses the entry's content; the probe's ref-anchored form with its merge-base reading is the mitigation, not a guarantee.
- **−** An entry's content is read by no gate on any surface. On a tracked file the operator-memory-reference gate matches an entry's name shape and the store's path, not its content; on a hosted comment nothing reads entry content at all. The prohibition is reviewer-detected for content everywhere.
- **−** The template's restatement of the value set is held to the lifecycle by authoring discipline, not by a mechanized parity check — named debt.
- **−** The CORRECTIONS graduation protocol still describes its own archive step by analogy to this lifecycle.

## Reversibility

CHEAP — revert the change and the phase returns. Evictions made while this record is in force stay recoverable from the Trash until it is emptied and are not restored by a revert. Once this record is numbered and merged it is never deleted; it is superseded or deprecated instead.

## Related ADRs

- ADR-045 — the cross-surface memory contract. This record supersedes the archive-first property named in its Decision item 4; the rest of that record binds.
- ADR-029 — the superseded boundary record that first specified the phase and its destination. Frozen, and unchanged.
- ADR-216 — the record that made the eviction's Trash move agent-executable, which is what lets the Trash carry recoverability.
- ADR-109 — the external-target scope, which left this lifecycle untouched.

## References

- #5185 — the card this record resolves: memory-eviction manifest entries had no safe archive destination, and the implied one was a public surface.
- #8195 — the Stage 5 design this record is drawn from.
- #8275 — the adversarial review. Its counter-designs made the tie the unit of eviction, the absorption gate a post-state test and the hub the binding actor.
- #8161 — the release's planning sub-task, which carries the Collective Review's Decision Recorded.
