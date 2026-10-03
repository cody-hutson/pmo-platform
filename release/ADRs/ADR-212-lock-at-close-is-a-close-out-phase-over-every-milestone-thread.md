<!-- reference-durability: allow-link -->
---
title: "ADR-212 — Lock-at-close is a close-out phase over every milestone thread"
status: Proposed
date: 2026-09-25
release: closeout-verification-rows-consistent
deciders: "operator (Stage-4 D-PhaseC5 gate: option E2, forward-only; Collective Review scope-lock: this record authored as Proposed and ratified at the release's Stage 13) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + independent adversarial design review + Stage 6 Engineering spoke (build and hermetic arms)"
tags: [release-ops, security, trust-boundary, lock-at-close, close-out, stage-13, no-merge, count-check]
supersedes: ADR-076 in-part (Decision 3)
source_observations:
  - "Measured before this decision (2026-09-19 through 2026-09-24): Phase C5 had locked threads on 2 of the 18 most recent closes, and no tool invoked a thread lock anywhere in the release tooling, the deploy tooling, the hooks or the workflows — the step existed only as manual checklist text."
  - "Measured on the release milestone closed immediately before this decision: the issues-only listing returned 19 items against a closed-item counter of 22, while the PR-inclusive issues listing returned 22 (19 issues + 3 pull requests), so the gap the Phase C5 count check reported was exactly the milestone's own pull requests."
  - "The integrative adversarial review found that the phase as first designed deferred under --no-merge through its own hand-written guard, recorded every row under a variable subject the dispatch-to-record cross-check cannot read, and built its diagnostics through a pipe into head that the repository's SIGPIPE-idiom gate rejects on added lines; the record's decisions were unaffected, and the phase conforms to the release's harness contracts instead."
---

# ADR-212 — Lock-at-close is a close-out phase over every milestone thread

## Status

**Proposed.** Authored at Stage 6 Engineering for the `closeout-verification-rows-consistent` release. The Collective Review decided that this record is authored as `Proposed` and ratified by the operator at the release's Stage 13 close gate (Phase A13); the ratification is recorded in this file's frontmatter `status:` field and is never inferred from a review comment or from milestone closure.

**Numbering provenance.** Claimed as **208** against an anchor of **206** on `origin/main`, read from the repository's own ADR-numbering tool at Engineering Commit 0: this release's two new records took the next two numbers in slice order, and this one is the second. A sibling release branch carries its own branch-local claims on this number, and branch-local claims do not bind. The number binds at the Stage-12 claim, and in-release prose cites this record by slug rather than by number.

**Numbering provenance — `208 → 212`.** Held **ADR-208** branch-local; renumbered to **ADR-212** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 208. In-release citations that read "ADR-208" denote this record.

## Context

ADR-076 Decision 3 reads: "**Lock-at-close** ships as a manual Stage 13 checklist step (Phase C5) on the repo-host adapter seam — abstract thread-lock/unlock; `gh issue lock --reason resolved` as the GitHub-adapter binding. The sweep locks finished sub-task threads and the delivery card. Non-blocking for Milestone close initially."

A manual, non-blocking step with no runner has no negative observable: a close that skips it records nothing, so a sweep that never ran is indistinguishable from a sweep that found nothing to lock. The step was inert on almost every close after its cutover (see `source_observations`). Its count check compared an issues-only listing with the milestone's closed-item counter, which counts pull requests too, so it could never pass on a release that milestones its own pull requests — and every release does. Its binding was the GraphQL-backed CLI verb, which the close-out cannot rely on, because the GraphQL budget is the one exhausted while a close runs. ADR-076 recorded an upgrade path — fold the step into the automated close-out tooling once the manual step proved reliable across two or more releases — and the step proved inert instead.

The release that authors this record also made the close-out tool's post-merge phases declare their `--no-merge` behaviour once, in a table the deferral, the reports and the tests derive from (ADR-213). A lock phase is a post-merge phase, so it joins that table rather than carrying its own guard.

## Decision

**Phase C5 is a numbered phase of the automated close-out that locks every thread on the release milestone and always records its outcome.**

1. **A mechanism, not a checklist step.** The close-out driver runs the lock as phase 15.2, `lock_milestone_threads`, dispatched immediately after the driver's last comment-posting phase (phase 15's gate-passage proof) and before the phases after it, so it is never the last phase to record a row.
2. **Every milestone thread.** The target set is every thread on the release milestone — issues and pull requests, the release PR and the Stage 13 chore PR included — enumerated from the host's issues listing, which returns both because the host models a pull request as an issue.
3. **Like with like.** The count check compares the enumerated total with the milestone's open-plus-closed counters. Both sides count pull requests, so the check has no offset to subtract and a mismatch is a genuine under-enumeration or a milestone that changed mid-close. A mismatch is reported, and the enumerated threads are still locked.
4. **REST, through named bindings.** The GitHub binding is the REST lock endpoint with lock reason `resolved`, and the phase makes no GraphQL call. The listing, the counters and the lock are three named repo-host bindings in the driver, so the phase body carries no host syntax.
5. **One row, never blocking.** The phase always records exactly one row: PASS with the locked list, SKIPPED with an explicit zero, or FAIL with the per-thread errors, a thread the read-back still shows unlocked, or a count mismatch. It reads the post-state back before recording PASS. It returns success on every path, so its outcome never changes the close-out's exit status and never reaches Milestone close, which runs earlier.
6. **A declared post-merge phase.** Under `--no-merge` it defers through the post-merge declaration table and appears in the report's deferred set; under `--dry-run` it predicts statically and reads nothing from the host.
7. **Forward-only.** Closes that ran before this decision's introducing release are not retrofitted.

ADR-076 Decisions 1, 2, 4 and 5 stand unchanged.

## Decision kernel (version-agnostic)

> A security control that a release close owes is a phase of the close-out tooling that always records an outcome, never a manual checklist step: a step with no runner cannot be told apart from a step that ran and found nothing. Its target set is the population the control protects, enumerated from a surface whose membership rule matches the counter it is checked against, so a count check compares like with like and has no offset to explain.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| A numbered close-out phase over named REST bindings, every milestone thread, a like-with-like count check, one row always recorded, non-blocking | **Selected** | Composes with the close-out's record-derived report, its mode-branch rule and its post-merge declaration table |
| Keep the step manual and add a mandatory report row | Rejected | Keeps the manual step whose non-execution is the defect |
| Retire the step | Rejected | Removes a security control on a public repository and leans on host interaction limits, which ADR-076 Decision 5 describes as a decaying control |
| Enforce on issues only | Rejected | The count check then needs a second enumeration surface and a documented offset, and the release's own pull-request threads keep accepting non-collaborator comments |
| Lock through the GraphQL-backed CLI verbs | Rejected | The close-out runs when the GraphQL budget is exhausted |
| A standalone lock tool invoked by the driver | Rejected | Adds a file, its allowlist rows and a second harness; its one unique benefit, a runnable retrofit, is moot under forward-only |
| Dispatch the phase last | Rejected | The report's halted marker reads the last row, so a non-blocking FAIL recorded last would print a false halt line on a completed run |
| Retrofit the closes left unlocked since the original cutover | Rejected | Several hundred public-thread mutations for exposure that is already historical |

## Consequences

**What improves.** Every close records a Phase C5 row; a close that never reached the phase shows the row absent from the record-derived phase table. The release and chore pull-request threads stop accepting non-collaborator comments at close, alongside the sub-task and delivery threads. The count check can pass on a release that milestones its own pull requests, so a FAIL means something again.

**What it costs.** Locks are host state: reverting the release does not unlock the threads a close already locked. A lock failure is reported, never gated, so the operator reads the row. The phase adds one listing, one counter read, one lock call per unlocked thread and one read-back to each close, all on the REST budget.

**What it does not do.** It does not change what a lock allows — the operator and collaborators can still comment, and existing content stays readable. It does not reach Milestone close or any phase before it, and it retrofits nothing.

## Reversibility

**CHEAP · confidence HIGH.** The code and text revert with the release PR. Locks already applied are reverted per thread through the REST unlock (`DELETE /repos/{owner}/{repo}/issues/{n}/lock`); a PR revert does not unlock them.

## Related ADRs

- [`ADR-076`](ADR-076-comment-author-association-trust-boundary.md) — superseded in part (Decision 3); its other decisions stand.
- [`ADR-158`](ADR-158-dry-run-predicts-apply-asserts-mode-branch-placement.md) — dry-run predicts, apply asserts: the phase predicts statically at `--dry-run` and locks at `--apply`.
- ADR-213 — post-merge phases declare their `--no-merge` behaviour once: the phase defers through that table's `defer` row, as its first statement. Cited by slug, because both records bind their numbers at this release's claim.

## References

- #5284 — the Phase C5 inertness report: thread-locking had not fired on the closes sampled
- #4768 — the Phase C5 count-check report: an issues-only count set against a PR-inclusive counter
