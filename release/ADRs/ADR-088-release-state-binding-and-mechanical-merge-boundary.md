<!-- reference-durability: allow-link -->
---
title: "ADR-088 — Release-state binding points: Gate 3 asserts identity-mode intent, not claim-time freeness; mechanical merge is safe only for pure-additive ledgers"
status: Accepted
date: 2026-07-22
release: version-identity-and-corpus-ledgers
deciders: "Stage-5 Solutioning spokes (#3590 for the Gate-3 boundary; #3594 for the merge boundary, incl. the empirical union-corruption test) + hub R1 adversarial verification + operator decision 2026-07-22 (one combined ADR over two thin ones)"
tags: [release-identity, version-claim, gate-criteria, corpus-ledgers, merge-strategy, git-attributes, two-phase-allocation, composes-adr-036]
source_observations:
  - "Gate 3's version criterion existed only as PROSE at stage-03-bundle.md:264, which explicitly deferred 'the Gate-3 spec enforcement of this conditional' to 'a separate fissioned card'. A live grep of core/schemas/gate-criteria-spec.md for 'version assigned'/'no collision' returned 0 hits — so the enforcement criterion was never created, and an AC phrased as 'make the criterion conditional' had no subject to modify."
  - "A blanket merge=union across all release corpus ledgers CORRUPTS RELEASE_LOG.md. A scratch-git experiment on the §220 v1.22/v1.23 worked example produced 4 rows — every row duplicated, carrying contradictory DEPLOYED/VERIFIED status — because RELEASE_LOG carries a state-bearing status column that a line-level union cannot reconcile. The same test confirmed union is correct and conflict-free for the pure-additive ledgers."
  - "AC2 of the originating issue named 'resolve by regeneration' as the RELEASE_INDEX mechanism. Issue #667 Finding 6 (fix commit 6dd9fd6) had DELIBERATELY REMOVED a regenerate path because it was itself the churn root — 'sibling-row reorder + notes-link drop'. Restoring regeneration would revive a known, already-fixed defect."
  - "Both decisions are facets of one question — which release state binds at which pipeline moment, and which surfaces are therefore safe to resolve mechanically — so they are recorded as one ADR rather than two thin ones (operator decision 2026-07-22)."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-088 — Release-state binding points and the mechanical-merge boundary

## Status

**Accepted** (`version-identity-and-corpus-ledgers`). Two decisions recorded together because they answer one underlying question: **which release state is bound at which pipeline moment, and which surfaces may therefore be resolved mechanically rather than by judgment.**

This ADR **composes** [ADR-036](ADR-036-version-claim-determinism.md) (defer-to-merge / provisional-vs-bound). ADR-036 establishes *when* the version binds; this ADR records *what follows* for gate enforcement and for corpus merge strategy. Nothing in ADR-036 is superseded.

## Context

Two independent Stage-5 designs in one release converged on the same structural insight from opposite ends.

**From the gate side (#3016).** Gate 3 (Bundle → Planning) was documented as requiring "version assigned (no collision)". Under ADR-036 two-phase allocation this is impossible to satisfy honestly: no concrete version *is* assigned at the Stage 3→4 boundary — the number is provisional display until the atomic claim at Stage 12. The criterion had never actually been written into the gate spec; it survived only as prose in the Stage-3 shard, which explicitly deferred its enforcement to a later card.

**From the corpus side (#3108).** The release corpus append-ledgers conflict on every long-running-branch reconcile, and that slow reconcile is what loses the version slot to a faster concurrent release. The obvious fix — make the ledgers merge automatically — appeared to apply uniformly to all of them. Empirical testing refuted that: some ledgers are pure-additive and some carry state.

The common thread: **a surface can be resolved mechanically only where it holds no state that requires judgment.** A gate criterion that asserts a *claim* needs a claim to exist; a merge driver that takes both sides needs both sides to be independently true.

## Decision

### D1 — Gate 3 asserts release-identity-mode validity, not claim-time version freeness

Gate 3 gains a criterion (**G3-19**, `gate-criteria-spec.md` schema 2.1 → 2.2) that asserts the release's **identity mode is valid** — `versioned` or `version-less` per the identity-mode enum — and, in `versioned` mode, that a provisional version is *declared*. It does **not** assert that a concrete `vX.Y` is free.

Concrete version freeness is checked at its real binding point: the Stage-12 atomic claim, with the Commit-0 re-verify as the early detection rung.

**Rationale.** A gate must assert something true at the moment it fires. Asserting freeness at Stage 3 would either be a lie (nothing is bound yet) or a de-facto reservation — which is precisely the early-binding failure ADR-036 exists to eliminate. Gate 3's honest question is *"is this release's identity coherent?"*, not *"is its number free?"*

**Consequence.** A `version-less` release satisfies Gate 3 by asserting identity-mode validity in place of a version claim, rather than being forced to fabricate a version string. `version-grammar.md` remains the version-string SSOT and is never fed an empty string — `version-less` is an identity-axis value, not a malformed version.

### D2 — Mechanical merge (`merge=union`) applies to pure-additive ledgers only

A committed root `.gitattributes` binds `merge=union` to exactly the **pure-additive** release ledgers:

| Ledger | Merge strategy | Why |
|---|---|---|
| `RELEASE_INDEX.md` | `union` | pure-additive; rows independent |
| `RELEASE_DIGEST.md` | `union` | pure-additive; rows independent |
| `CHANGELOG.md` | `union` | pure-additive; rows independent |
| `RELEASE_LOG.md` | **default merge** (excluded) | carries a state-bearing status column (DEPLOYED → VERIFIED); union duplicates rows with contradictory state |
| `RELEASE_REVERSIONS.md` | **default merge** (excluded) | reaper-mutable disposition cells; same state-bearing hazard |

**Rationale.** A union driver takes both sides unconditionally. That is correct exactly when both sides are independently true and order-insensitive — the definition of a pure append. It is *incorrect* for a row whose later state supersedes its earlier state: taking both yields a record asserting DEPLOYED and VERIFIED simultaneously. This was demonstrated empirically, not reasoned about (see `source_observations`).

**Regeneration is explicitly rejected** as the resolution mechanism. A regenerate-on-merge path previously existed and was deliberately removed by #667 Finding 6 (fix `6dd9fd6`) because regeneration itself caused sibling-row reorder and notes-link drop — the churn this decision is meant to end.

**Consequence.** `RELEASE_LOG`'s conflict is not eliminated; it is *scoped*. It occurs at the Stage-13 chore PR — **after** the version claim — so it cannot cause the version-slot loss this work targets. It remains governed by the shipped conflict-resolution doctrine and the close-out concurrency guard.

## The general rule

> **Bind state at the moment it becomes true, and resolve mechanically only what carries no state.**

Both decisions follow from it. Gate 3 stops asserting a binding that has not happened. The merge driver stops mechanically resolving surfaces whose rows supersede one another. A future surface joins the union set only if it is genuinely append-only; a future gate criterion asserts only what is bound at the moment it fires.

## Alternatives Considered

**For D1 — make the existing criterion conditional.** Rejected on grounds of fact: there was no existing criterion in the gate spec to make conditional. The AC's verb was authored against prose in a different file.

**For D1 — assert freeness at Gate 3 with a re-check later.** Rejected: this is the de-facto reservation ADR-036 removes, and it reintroduces the HALT-and-re-version loop mid-pipeline.

**For D2 — a custom merge driver handling the state column.** Considered and deferred as disproportionate to the defect: it would require modelling row-state semantics in a merge driver to solve a conflict that occurs post-claim and therefore costs no version slot. Recorded as the escalation path should `RELEASE_LOG` conflicts later prove costly.

**For D2 — regenerate on merge.** Rejected — revives #667 Finding 6.

## Reversibility

**MODERATE** · confidence **HIGH**.

- **D1** — additive criterion, no ID renumber (`G3-16` remains reserved for the cross-milestone gate; `G3-13` is a retired tombstone). Revert via `git revert`; consumers route by Check column and the structural-pass denominator is unchanged.
- **D2** — `.gitattributes` is a single new file; deleting it restores default merge behaviour with no data migration. No historical ledger row is rewritten by either decision.

Higher-than-CHEAP because both touch load-bearing release-identity and corpus surfaces that downstream tooling reads.

## Reflexive cutover

Applies to all releases entering the pipeline after this ADR's introducing-release merge. Existing version-keyed artifacts are grandfathered; no retroactive rewrite.
