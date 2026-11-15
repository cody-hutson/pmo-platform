---
title: ADR-240 — Superseded pull-request runs are cancelled by one canonical workflow-level concurrency block, and a pull-request-time gate keeps it on every pull-request-triggered workflow
status: Proposed
date: 2026-11-15
release: superseded-pr-runs-cancelled
deciders: "Workspace owner (Stage-4 plan gate; Collective Review scope lock; Stage-13 ratification); the key and the gate's predicate chosen at Stage 5 Solutioning and amended at the scope lock by the adversarial reviews' fixes"
tags: [architecture, ci, workflows, concurrency, superseded-runs, gate, reversibility-cheap]
source_observations:
  - "Before this release no workflow under .github/workflows/ declared a concurrency group, so the runs for a superseded pull-request head kept their hosted macOS runners until they finished while the runs for current heads waited behind them, and release hubs cancelled superseded runs by hand."
  - "A group key built from github.ref is refs/heads/main on every push to main, so on a workflow that also runs on a push to main it puts every such push in one group, and a later merge cancels an earlier merge's run. A check for the mere presence of a group passes that key."
  - "A called workflow evaluates its caller's github context, so the canonical key in a called workflow resolves to the caller's group; and under an exemption for called workflows, one inert workflow_call line beside a pull_request trigger would take a pull-request workflow out of the gate."
  - "A review event's payload carries the pull request, so on a workflow that also runs on pull_request the canonical key resolves to the pull request's group for the review run as well."
---

# ADR-240 — Superseded pull-request runs are cancelled by one canonical workflow-level concurrency block, and a pull-request-time gate keeps it on every pull-request-triggered workflow

## Status

**Proposed** — authored at Stage 6 Engineering for the `superseded-pr-runs-cancelled` release, as the pointer record the Collective Review scope lock asked for. Ratification is recorded in this file's frontmatter `status:` field at Stage 13, which is where it must be verified, and is never inferred from milestone closure.

**Numbering provenance.** Claimed as **240** against an anchor of **239** on `origin/main`, read from `release/tools/renumber-adr.py --detect` at this record's authoring commit. A branch claim is detection-only and never binds. At authoring, a sibling release in flight held a branch claim on the same slot; whichever of the two merges second is moved by the renumbering tool at merge time, which appends one provenance note per hop. Citations from other branch-authored artifacts use the slug token keyed on this record's slug, which carries no number shape and resolves at the claim.

## Context

The repository runs its pull-request checks on hosted runners, and its macOS runners are scarce. When a newer commit reached a pull request, the runs for the commit it replaced kept their runners until they finished, so current heads queued behind heads nobody would merge. GitHub Actions offers a concurrency group at workflow or job level: a run joins the group its key names, a newer run replaces a pending one, and with `cancel-in-progress` the newer run also ends the running one. The key decides what can cancel what, and one key in common use is unsafe on a workflow that also runs on a push to `main`.

Configuring today's workflows once would not stay true. The next workflow added without the group, or with an unsafe one, would bring the queue back, and a check for the mere presence of a group would pass the unsafe key.

## Decision

**(1) One canonical block, at workflow level.** Every workflow a pull request triggers carries one concurrency block at workflow level, keyed on the workflow's identity and the pull request's number with the run id as the fallback, with `cancel-in-progress` on. On a pull request a newer run of the workflow cancels the older one. On a push, a tag, a schedule or a dispatch the number is empty, the key falls back to the run id, and the run has a group of its own, so it is never cancelled and never waits. No job carries a concurrency key of its own. The block's exact text is held, as the authority, by the gate's checker, `core/deploy/tools/check-workflow-concurrency.py`, in its `CANONICAL_GROUP` constant.

**(2) A pull-request-time gate keeps it true.** The `Workflow concurrency gate` job in `.github/workflows/repo-integrity.yml` runs that checker over the whole of `.github/workflows/` on every pull request. Equality with the canonical form is textual — the raw source line, located by a structural parse — so the gate and a fixed-string search for the canonical line cannot disagree on a file the gate passes. The gate also refuses a pull-request trigger beside `workflow_call` and a review event beside a pull-request trigger, forbids a workflow-level key in a called workflow, and keeps the workflow identities the key embeds distinct after case-folding. It is advisory and enforcing: a finding turns the check red, and the context is not registered as a required check. Its invariant, falsification tests, posture and stated limits are recorded once, in the gate-coverage register of `core/standards/gate-efficacy-standard.md`; this record does not restate them.

**(3) Exempt workflows are not graded.** A workflow triggered only by a push, a tag, a schedule or a dispatch needs no block, and the gate does not grade any key it carries.

## Alternatives Considered

- **A key built from `github.ref`.** Rejected: on a push to `main` it is the same value for every push, so on a workflow that also runs on a push to `main` a later merge cancels an earlier merge's run. Its near-miss is a committed fixture of the gate.
- **A key built from `github.head_ref` or `github.sha`.** Rejected: a branch name is shared by two forks' same-named branches, and a dispatch at a pushed commit would share the push run's group.
- **Job-level groups on the macOS jobs only.** Rejected: they leave the Linux jobs uncancelled, a job-level group can hold two jobs of two push runs, and the gate would have no uniform form to check.
- **A presence-only gate, or parsed rather than textual equality.** Rejected: presence passes the `github.ref` key; a parsed comparison accepts spellings the canonical line does not have, and passes a quoted value that a fixed-string search of the canonical line fails.
- **Accepting any key provably per pull request**, such as a `github.ref` key on a workflow with no push trigger. Rejected: deciding it needs an expression evaluator over GitHub's contexts, and one form is decidable without one.
- **Exempting a workflow that declares `workflow_call`.** Rejected at the scope lock: one inert trigger line would take a pull-request workflow out of the gate. The remedy the gate teaches is a split into a caller that carries the block and a called workflow with neither a pull-request trigger nor a key.
- **A new workflow as the gate's host, or an arm in the gate-efficacy conformance ratchet.** Rejected: a new workflow is a larger change for one job, and the ratchet's only host publishes a required context, so an arm there would block from its first day.
- **Scanning only the workflows a pull request changes.** Rejected: a workflow that arrives by a merge from `main` is unchanged relative to the pull request's base, and the identity clause needs the whole population in any case.
- **A required posture, registered just before the merge.** Rejected: the declaration follows the registration, and a pull request cannot register a context.
- **No decision record, with the rejected forms kept only in the checker's docstring.** Rejected at the scope lock: the decision binds every future workflow author, and its rejected options must survive as rationale.

## Consequences

- **Positive.** A newer commit on a pull request ends the superseded commit's runs, so the macOS runners serve current heads, while runs on `main` and every required check on the current head still run to completion. A workflow added without the block, or with an unsafe key, fails a check on the pull request that adds it.
- **Negative.** A job cancelled because a newer commit arrived has no result for its commit, so a superseded commit's CI evidence is a job that finished before the next push, or a local record of its suite. A same-head re-run cancels an in-progress older run of the same head. For uniformity the gate rejects a `github.ref` key even where that key would be safe.
- **Stated limits.** The gate does not read activity types, does not grade an exempt workflow's key, and reads only the files directly under `.github/workflows/`.
- **Cross-release.** Because the scan is whole-tree, a non-conforming workflow that reaches `main` turns the gate red on every pull request until it is repaired there.

## Reversibility

**CHEAP · Confidence HIGH.** Revert the gate's commits first, then the configuration's, because the gate fails on `main` without the blocks. Every workflow token is read-only, so a cancelled run leaves no partial state, and any subset of files carrying the block is safe for `main`. A later registration of the context as required is an operator action, removed the same way.

## Related ADRs

- **ADR-181** — an ADR citation binds at the Stage-12 claim; this record is cited by slug token until then.

## References

- `#8440` — the card that adds the canonical block to every pull-request-triggered workflow.
- `#9007` — the card that adds the gate and asked for this record.
