<!-- reference-durability: allow-link -->
---
title: "ADR-137 — A project's own governance files are located by a non-bin sentinel, not by a sixth bin"
status: Accepted
date: 2026-08-21
release: operational-folder-enforcement-and-migration
deciders: "operator (D-12 enum extension; D-47 scope-lock) + Stage 5 Solutioning spoke (design) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [taxonomy, frontmatter, folder-enum, ADR-080, closed-set, sentinel, classification, node-backfill]
source_observations:
  - "A project's own governance files — PROJECT.md, README.md, CORRECTIONS.md — sit at the project ROOT and in no bin at all, so no folder token resolves for them and the node classifier records them as orphans. Measured at the release baseline: exactly 6 such files across the live corpus, against a depth histogram of 1:1 / 2:24 / 3:45 / 4:27."
  - "`folder` is a NOT-NULL member of the 11-field core set the SQLite files table requires, and a partial stamp yields no row at all. A file with no defensible `folder` value therefore cannot be indexed, which is why these files are absent from the warehouse rather than merely mislabelled in it."
  - "ADR-080 declares the 5-bin set CLOSED and makes changing it a governance change rather than a runtime decision, so any value added to the `folder` enum must be shown NOT to be a bin before it can be added at all."
  - "The `_` prefix is already the established marker for a non-bin area in this enum: `_inbox` and `_generated` are both transient areas rather than bins, and both carry it."
  - "A token census over the platform corpus returned 0 occurrences of `_project-root`, against 7 occurrences of the candidate `_root` — all of them shell locals in the deploy script, which would make every future sweep on that token noisy."
  - "The scaffold side was born with the same gap: the project-initiator born-entity block carried 6 fields and no `folder`, so a newly-created PROJECT.md was born missing a NOT-NULL core field. Fixing only the classifier would have left new projects being born broken."
  - "The sentinel's guard set was falsified once during design and re-derived: without the `_`-prefix guard the predicate selects 7 files rather than 6, because the shared-entity store's own README sits at the same depth with the same basename and belongs to the non-project-top-segment tier instead."
---

# ADR-137 — A project's own governance files are located by a non-bin sentinel

## Status

**Accepted.** Authored at Engineering for the `operational-folder-enforcement-and-migration` release, against the operator's D-12 decision to extend the `folder` enum; scope-locked at D-47.

**Depends on:** [ADR-080](ADR-080-project-folder-taxonomy-closed-5-bin-set.md), whose closed-set clause is the constraint this record must satisfy rather than amend.

## Context

The `folder` field answers "where in the project structure did this file originate". Its enum is the ADR-080 union: the legacy 8-folder taxonomy plus the closed 5-bin set plus the two transient areas. Every value in it names a **bin** — a routing target an agent places files into — or a transient staging area on the way to one.

A project's own governance files do not live in any of them. `PROJECT.md` is the project's dashboard; `README.md` and `CORRECTIONS.md` sit beside it. They are scaffolded at the project root, never routed, and by construction there is no bin above them. The classifier walks upward from the file looking for a resolvable folder token, finds the project directory, and stops — no confident domain, so the file is recorded as an orphan.

That is the correct verdict from a classifier that only knows bins, and the wrong outcome for the corpus. `folder` is a NOT-NULL member of the 11-field core set, and a partial stamp produces no index row at all, so these files are not mis-described in the warehouse — they are **absent from it**. The project's own front page is the one file most likely to be queried and the one file guaranteed not to be there.

The obvious repair is to give them a `folder` value. The obstacle is that ADR-080 declares the bin set **CLOSED** and makes changing it a governance change. So the question this record answers is not "what value should these files carry" — several would work. It is: **can a value be added to this enum without adding a member to the closed set the enum is supposed to protect?**

## Decision

**D1 — `_project-root` is a SENTINEL, not a bin, and the distinction is what preserves ADR-080.** A bin is a *routing target*: agents place files into it, `file-router` names it in its routing tree, and the scaffolder creates it. `_project-root` is none of these. It is a **location description** for files that were never routed anywhere — it names the absence of a bin rather than the presence of one. The closed-set invariant is therefore untouched: the set of places an agent may route into is exactly the five bins it was before this record. What grew is the enum of locations the schema can *describe*, which is a strictly larger set than the set of locations an agent may *choose*. Collapsing those two into one enum is what made this look like a closed-set breach.

**D2 — The `_` prefix carries that distinction and is load-bearing, not cosmetic.** The enum already marks its non-bin members this way: `_inbox` and `_generated` are transient areas rather than bins, and both are prefixed. A reader encountering `_project-root` reads it against an established convention rather than as a novel exception. The rejected candidate `0-Root` fails precisely here — it reads as a **sixth numbered bin** and would breach the invariant this record exists to preserve, in appearance if not in mechanism. Appearance is not a secondary concern for a value whose whole job is to signal a category.

**D3 — The classifying predicate carries three guards, and each is independently necessary.** The sentinel resolves only when: the file sits at depth 2 (directly under a project directory); its basename is in a **closed** set of known governance names; and its top segment is not `_`-prefixed. The second guard is what keeps the branch from becoming a catch-all — an arbitrary stray at a project root **stays an orphan**, which is the honest verdict for a file nobody can classify. The third is the one that was falsified and re-derived during design: without it the predicate selects 7 files rather than 6, because the shared-entity store's own `README.md` sits at the same depth with the same basename and belongs to the non-project-top-segment tier instead. A sentinel that quietly annexes a neighbouring tier's files is worse than one that misses some of its own.

**D4 — The sentinel is a FALLBACK in the resolution order, never a shadow of the bins.** It is consulted only after the folder-token walk has failed to resolve a domain. A governance-named file that *does* sit inside a bin resolves to that bin, exactly as before. This makes "the sentinel never shadows a bin file" a structural property of the ordering rather than a property the depth guard has to defend on its own — and the depth guard is retained as defence-in-depth rather than claimed as the mechanism.

**D5 — The retroactive fix and the scaffold fix ship together, or neither is worth shipping.** Adding the value to the classifier repairs the projects that already exist; it does nothing about the next one. The scaffold side carried the identical gap — the born-entity block was a 6-field block with no `folder` — so a newly-created PROJECT.md was born missing a NOT-NULL core field, which is *why* these files show up as backfill orphans in the first place. Editing the emit contract to say the scaffolder writes `folder` while the scaffolder does not write it would have declared a contract the implementation does not honour. The classifier, the emit contract, the skill instruction and the template move as one change.

**D6 — Every surface that restates the union is updated in the same commit, and the ones that must NOT be are recorded with their reason.** The union is restated verbatim in the schema's own enum row, the index column comment, and the operations governance note; each gains the member. The routing-authority skill is deliberately **not** updated: it enumerates the *routing* target set, and `_project-root` is not a routing target — PROJECT.md is scaffolded, never routed. Adding it there would be a category error, and recording the omission is what stops a later sweep from "fixing" it.

## Decision kernel (version-agnostic)

**When a closed set of choices and an open set of descriptions share one enum, a new value is admissible if and only if it describes a location outside the choice set rather than adding a member to it.** Mark such a value with the vocabulary the enum already uses for its non-choice members, resolve it as a fallback after the choice set has failed rather than alongside it, and constrain it with a closed predicate so it cannot become a sink for anything the choice set merely failed to classify. The closed-set invariant is preserved by the value's *category*, not by its absence.

## Alternatives Considered

1. **Leave the files as accepted-residual orphans.** The honest zero-cost option, and it was the standing position before D-12. Rejected because the residual is not noise: it is every project's front page, permanently absent from the index the warehouse exists to populate. An accepted residual is a legitimate disposition for a class nobody can own; it is the wrong disposition for a class with a clear owner and a one-line fix.

2. **Add `0-Root` as a sixth bin.** Rejected on D2. It resolves the same files with the same mechanism, and it reads as a numbered bin — which would make the closed-set clause false in appearance while it remained true in mechanism. A taxonomy whose invariant requires a footnote to defend has lost the property it was protecting.

3. **Reuse `1-Governance` for project-root files.** Tempting, because these files are governance content and the bin exists. Rejected as a **false statement about location**: `folder` records where the file originated, and these files did not originate in that bin. It would also make the value unusable for its real purpose — a query for "what is in this project's governance bin" would return files that are not in it, and the migration that eventually moves projects onto the 5-bin set could not tell the two populations apart.

4. **Widen the predicate to `depth <= 2` so the corpus-root file resolves too.** Rejected as the wrong mechanism for a genuinely different class. A file at the corpus root has **no project segment at all**, so a *project*-root sentinel is not its natural home; it is program-scoped operational config whose correct long-run home is the non-project-top-segment tier. Adopting it here to drive a count to zero is the count-driven carve-out this release's acceptance criterion has repeatedly refused. It remains a declared accepted-residual with a next-release owner.

5. **Make the basename guard a catch-all — classify anything at a project root.** Rejected on D3. It would convert an orphan verdict into a confident-looking wrong answer for every stray file a project accumulates, and the orphan list is the surface that exists to make those visible.

6. **Add a CHECK constraint on the index column to enforce the enum.** Out of scope and independently undesirable: the column carries no CHECK today by deliberate design, with cardinality left unconstrained at the DB layer and the enum validated upstream at write. This record does not change that posture.

## Consequences

**Positive.** Six files per the release-baseline measurement — every active project's governance root — become indexable rather than absent. The scaffold stops producing new instances of the defect, so the class closes rather than being drained. The classifier's orphan list becomes a shorter and more meaningful surface: at the merged state it holds exactly one file, and that file is a declared accepted-residual with a named next-release owner rather than an unexamined remainder.

**Negative, named.**

- **The `folder` enum now mixes two categories** — bins and a non-bin location — and only the `_` prefix and this record distinguish them. A consumer that treats every enum member as a routing target will be wrong about this one. The routing-authority skill is deliberately not updated (D6) precisely so that consumer has a correct source, but the enum itself no longer answers "is this a bin" without reference to the prefix convention.
- **A backfilled project root reads `lifecycle_state: current` where a born one reads `emerging`.** The classifier derives lifecycle from domain; the scaffolder writes the entity's initial maturity. For an established project `current` is arguably the more accurate value, and the stamp writes only ABSENT keys so a born file keeps its own — but the two paths do disagree, and that is a decision recorded here rather than an accident to be discovered later.
- **The blast radius is Structural.** The enum's home surface carries 81 first-order and 429 second-order referrers. The change is **additive-union** — the pattern this schema already established twice — so a consumer that merely cites the taxonomy is unaffected and only an enum-validating consumer needs the member. The union is restated verbatim in three places, all updated here; a fourth restatement appearing later would go stale silently.
- **The predicate's depth limb is not independently observable.** Because the predicate indexes the second path segment, relaxing the depth limb changes behaviour only for a directory literally *named* `PROJECT.md`. The limb is retained as defence-in-depth and is deliberately not claimed as pinned by a test — stated so a later reader does not mistake an unpinned guard for a graded one.

**Blast radius.** Six tracked surfaces plus the classifier: the schema enum row, the index column comment, the emit contract, the operations governance note, the scaffolding skill's born-block instruction, and the template that implements it. Additive on every one.

## Reversibility

**MODERATE · confidence HIGH.** The repository side reverts cleanly — the enum member, the classifier branch and the four documentation surfaces are a single additive commit with no vocabulary migration behind it.

The **corpus** side does not revert with it. Once the backfill has stamped `folder: _project-root` onto live files, a repository revert leaves those files carrying a value the schema no longer admits, and the stamp writes only absent keys so it will not correct itself on a re-run. The corpus-side reversal path is the pre-write snapshot, restored by path — it is not `git revert`, and the two paths are independent. A revert decided after the Stage-12 write must therefore restore the snapshot as well, or it leaves the corpus describing itself in a vocabulary the tree no longer defines.

## Related ADRs

- [ADR-080](ADR-080-project-folder-taxonomy-closed-5-bin-set.md) — the closed 5-bin taxonomy. Its closed-set clause is the constraint this record satisfies; D1 is the argument that a non-bin sentinel does not breach it. ADR-080 also names the structure lint as the enforcement instrument for the closed set and records it as a still-unbuilt sibling work item; that remains true, and this record adds no enforcement of its own.
- [ADR-058](ADR-058-pmo-entity-page-ssot.md) — the shared-entity store. D3's third guard exists so that store's own root-level page is claimed by the non-project-top-segment tier rather than annexed by this sentinel.
