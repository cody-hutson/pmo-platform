<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-092 — Plan-file identity binds at claim-time stamping (post-CAS), extending ADR-088
status: Accepted — ratified by the workspace owner at the `release-identity-and-plan-lifecycle` Collective Review scope-lock (the Stage 5→6 boundary), 2026-08-24. The flip was promised at the `release-identity-and-plan-naming` review, which shipped v3.93 on 2026-07-25 without the ratification on its agenda; it is re-anchored here rather than backdated to a ratification the record does not evidence.
date: 2026-07-25
release: release-identity-and-plan-naming (version binds at the Stage-12 claim)
deciders: "Workspace owner (ratified at the release-identity-and-plan-lifecycle Collective Review scope-lock, 2026-08-24); design resolved at the plan-file-naming Stage-5 Solutioning + its adversarial review"
tags: [architecture, release-pipeline, versioning, claim-time-binding, slug-primary, reversibility, adr-036, adr-088]
source_observations:
  - "#2548 Stage-5 Solutioning (#3994): ADR-036 killed the early-binding collision for the git TAG (defer-to-claim + atomic CAS), but the versioned plan-file name and branch name still bind a concrete vX.Y at plan time — re-creating, for those identifiers, the exact HALT+re-version churn ADR-036 eliminated for the tag."
  - "#3994 central design fork: the issue says insert the {{RELEASE_VERSION}} substitution 'before the existing CAS claim.' Taken literally that fights collision-safety — resolving the candidate before the push and then losing the CAS makes the resolved value stale, forcing a revert+recompute+re-substitute (the churn moved, not removed)."
  - "#3994 AC5 carve: Check# and ADR# are a DIFFERENT identifier class (cheap collision, existing slug/gap indirection, already claim-deferred by the renumber-at-Engineering discipline); tokenizing them fights the gap-free ADR CI + the Check-57 roster contract. Struck from #2548 and carved to #3713."
---

# ADR-092 — Plan-file identity binds at claim-time stamping (post-CAS)

## Status

**Accepted.** Ratified by the workspace owner at the `release-identity-and-plan-lifecycle`
Collective Review scope-lock, 2026-08-24. Authored at #2548 Stage 6 per the Stage-6
ADR-authoring precedent (ADR-031 / ADR-007 / ADR-028). The flip was originally promised
at the #279 `release-identity-and-plan-naming` Collective Review scope-lock; that review
ran and shipped v3.93 on 2026-07-25 with the ratification never placed on its agenda, and
because the close-gate criterion that owns promised flips is scoped to the ratifying
release, no later release inherited the escaped promise. The promise is therefore
re-anchored to this release's review rather than backdated to a ratification the record
does not evidence. The superseded promise wording placed Collective Review at Stage 9;
it is the Stage 5→6 checkpoint, and that is corrected here. It references issues
and ADRs as bare `#N` / `ADR-NNN` with the file-level `allow-issue-ref` /
`allow-link` markers above.

> **Dogfooding note.** This ADR takes its number the way the AC5 carve recommends
> for Check#/ADR#: next-free at Engineering, referenced downstream by slug
> (`plan-file-claim-time-stamping`). That the number binding is unremarkable here is
> itself evidence that the renumber-at-Engineering discipline — not tokenization —
> is the right defer-to-claim mechanism for that identifier class.

## Context

Release identity is monotonic across three surfaces: the **git tag**, the **plan-file
name**, and the **branch name**. ADR-036 (version-claim determinism) established the
correct discipline for the tag — a bump-class *intent* declared at plan time, and the
concrete number computed and claimed only at the merge moment via an atomic
compare-and-swap (`atomic_claim`), whose free recompute-and-retry loop makes
ship-order = merge-order = tag-order an architectural guarantee. ADR-088 fixed the
*release-state binding points* for the tag (Gate 3 asserts identity-mode intent, not
claim-time freeness).

The plan-file name and branch name, however, still bound a concrete `vX.Y` **early**
— at plan authoring, before the claim. That re-creates, for those two identifiers, the
exact collision ADR-036 killed for the tag: two in-flight releases both authoring
`release/v3.54-…` + `v3.54_RELEASE_PLAN.md` must HALT and re-version when one wins the
slot, and every downstream reference to the early number rots.

Extending the `{{RELEASE_VERSION}}` token-substitution to the claim raises a
binding-point question the intake under-specifies: does the concrete number resolve
**before** or **after** the CAS win? The naive "substitute before the push" reading
fights collision-safety — a resolved-then-lost candidate is stale, forcing a
revert + recompute + re-substitute, which is the churn the fix is meant to remove,
merely relocated from Commit-0 into the claim loop. The merge SHA is also an *input*
to the tag, so a substitution commit cannot precede the tag without breaking the
merge-SHA invariant.

## Decision

The plan-file rename and `{{RELEASE_VERSION}}` resolution bind on the **CAS-win path
(post-CAS)** — not before the push:

1. **Pre-CAS pre-flight (read-only).** Before the compare-and-swap, validate the stamp
   manifest — the pre-claim plan resolves, carries ≥1 `{{RELEASE_VERSION}}` token, and
   the target directory is writable — and **HALT before claiming** if it is broken. This
   is the "before the CAS" checkable half; it **mutates nothing**, so the recompute-retry
   loop stays free.
2. **Post-CAS stamp (the mutation).** On the CAS **win**, with the **won** tag, resolve
   `{{RELEASE_VERSION}} → vX.Y` in the plan's **content** and `git mv` the slug-named plan
   to `plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`, then commit + push the follow-on stamp.

**Filesystem identity (filename, branch) is slug-keyed; only file content carries the
`{{RELEASE_VERSION}}` placeholder.** The double-brace form is filesystem/git-ref-hazardous,
so it never appears in a filename or a ref — the slug is the pre-claim filesystem identity,
and the concrete number binds the filename only at the `git mv`.

This is additive to `release/tools/claim-version.sh`: the pre-flight and stamp passes
hang off the existing four-step CAS loop (STEP 2.7 pre-flight before the push; the stamp
on the STEP-4 OK branch). The CAS arithmetic, the discriminated-failure classifier, and
the retry loop are **untouched** — the stamp is gated on a `--stamp-slug` argument and is
entirely absent for every existing caller.

## Alternatives Considered

The binding-point question is the fork this record resolves, and § Context states it directly: does the concrete number resolve **before** or **after** the compare-and-swap win?

- **Substitute before the push (pre-CAS binding)** — the reading the intake suggests — **not taken.** § Context: it fights collision-safety, because a resolved-then-lost candidate is stale and forces a revert, recompute and re-substitute — the churn the fix is meant to remove, merely relocated into the claim loop. A second, independent reason is recorded alongside it: the merge SHA is an *input* to the tag, so a substitution commit cannot precede the tag without breaking the merge-SHA invariant.
- **Keep the early `vX.Y` binding for the plan-file and branch names** (the status quo) — **not taken.** It re-creates, for those two identifiers, the exact collision the version-claim ADR already killed for the tag.
- **Carry the placeholder in the filename or the branch ref** — **not taken.** § Decision records that the double-brace token form is filesystem- and git-ref-hazardous, so filesystem identity stays slug-keyed and only file *content* carries the placeholder.
- **Extend the same treatment to Check and ADR numbers** — **explicitly out of scope**, and § Consequences gives the reason: their collision is cheap, they already have slug or reserved-gap indirection, they are already claim-deferred by the renumber-at-Engineering discipline, and tokenizing them would fight the gap-free ADR CI and the check-roster contract.

The pre-flight / stamp split follows from the same constraint: the pre-CAS pass is read-only so the recompute-retry loop stays free, and every mutation hangs off the CAS-win path.

## Consequences

- **The recompute-retry loop stays free.** Nothing is stamped until the number is won, so
  a lost candidate is never written to any filename or file body — the churn the change
  eliminates. (The `U-13` self-test fixture is the collision-safety proof: on
  collision-then-win the stamp fires exactly once, binding the won `v2.17`, never the lost
  `v2.16`.)
- **The merge-SHA invariant holds.** The stamp is a **follow-on commit** — the same
  post-merge-commit pattern Stage 13 already uses for `RELEASE_LOG` / `RELEASE_INDEX` rows —
  never a commit that precedes the tag.
- **A stamp failure HALTs without un-claiming the tag.** The tag is authoritative once won;
  a stamp failure surfaces "tag claimed, stamp manually" and returns non-zero, but never
  reverts the claim.
- **Mode-composed.** For a `versioned` release the rename fires at the claim; for a
  `version-less` release the plan/branch stay slug-primary permanently (no number to bind).
  This composes with the `{versioned, version-less}` identity-mode enum (#3016); it does
  not collapse it.
- **Scope limit (records the AC5 carve).** This binding-point applies to the
  **plan-file and branch** — identifiers with an *expensive* collision and *no* existing
  indirection. `Check#` and `ADR#` are a **different class**: their collision is *cheap*
  (slug indirection for ADRs; reserved-gap tolerance for Checks) and they are **already**
  claim-deferred by the renumber-at-Engineering discipline. Tokenizing them (`{{ADR_NUM}}` /
  `{{CHECK_NUM}}`) would fight the gap-free ADR CI (`check-adr-numbers.py`) and the Check-57
  roster contract, so they are **explicitly out of scope** here and carved to #3713.

## Reversibility

**MODERATE — confidence HIGH.** `git revert` the change; the additive nature means the
pre-existing CAS guards (Commit-0 re-verify, pre-merge freeness, atomic CAS) remain the
correctness backstop throughout. Filesystem renames performed by a stamp are themselves
git-tracked and revertible.

## Composition

- **Extends ADR-088** (release-state binding points) from the tag to the plan-file/branch.
- **Slug-anchored to ADR-036** (version-claim determinism) — the same defer-to-claim +
  atomic-CAS rule, projected onto the plan-file and branch identifiers.
- **Composes #3016** (the `{versioned, version-less}` identity-mode enum) — mode governs
  whether the rename ever fires; this ADR governs *when* it fires for a `versioned` release.

## References

- #279 — the release milestone `release-identity-and-plan-naming`, at whose Collective Review scope-lock this record is ratified.
