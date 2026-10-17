---
title: "ADR-219 — Release identity is stamped at Stage 12, and a stamped deploy states its target set"
status: Proposed
date: 2026-10-16
release: ci-wiring-and-required-checks
deciders: "Workspace owner (operator) — the shape and the target-set contract rendered at the release's Stage 5 Collective Review scope-lock, with the adversarial review's roster-membership filter and empty-key fold-in taken; design by the Stage 5 Solutioning spoke (Principal Engineer persona); authored by the Stage 6 Engineering spoke"
tags: [deploy, deployment-status, release-identity, stage-12, post-merge-hook, telemetry, append-only, target-set, roster-membership]
source_observations:
  - "The Stage 12 deploy step carried no command. Measured at the design pin: no tracked line outside the deploy tool and the release records paired the deploy flag with the release flag (0 lines; control 4 in the tool). The release log recorded the step executed five different ways across five cited releases."
  - "A stamped deploy given names writes one row per name whether or not the files were already current — read from the deploy loop, recorded in production where a stamped named re-run after the post-merge hook wrote five rows, and proved at authorship by a sandboxed arm that stamps a target an unstamped deploy had already made current."
  - "The no-names stamped form selects from a tag window that is not the release. Measured over 74 consecutive releases at the design pin: the window named a skill the release's own merge did not change in 12, and 9 of the 34 releases whose merge changed no skill would have been stamped with a skill row. The adversarial review reproduced both figures."
  - "No uniform signal identifies a release merge from inside the hook. Measured over the last 400 first-parent commits at the design pin: 99 release merges carried the head ref in the subject and 9 did not; the tag is pushed after the merge and is absent for a version-less release."
  - "Selecting targets by directory presence is not the deploy's own test. Replayed over the 75 tagged release merges at the design pin, 1 derivation named a shared directory under a skill root that no module array lists; the deploy resolves names through those arrays and stops on a non-member after its rules-mirror carrier has written a row. Re-run at authorship over 76 tagged release merges, the replay named the same directory at the same release and no other, and the roster-membership filter set it aside."
  - "An empty release key failed open at every touchpoint of the drafted step: the deploy ran unstamped and exited 0, and the read-back and the row read both treat an empty release filter as no filter, counting every row in the log on a fixture of three releases."
  - "The post-merge hook, the update script and the install orchestrator carried no release flag (0 occurrences each), by the deploy tool's own stated contract that a fresh install or an ad-hoc redeploy carries no release identity."
supersedes: none
---

# ADR-219 — Release identity is stamped at Stage 12, and a stamped deploy states its target set

## Status

**Proposed.** Authored at Stage 6 Engineering for the `ci-wiring-and-required-checks` release. The operator rendered the decision at the release's Stage 5 Collective Review scope-lock: Stage 12 owns the stamped deploy, a stamped deploy states its target set, the target set is filtered by deploy-roster membership, and an empty release key is refused. The `Proposed → Accepted` transition belongs to that release's Stage 13 Close ratification beat (Phase A13); the frontmatter `status:` field is where it is recorded, and where it is read.

**Numbering provenance.** This record was claimed as **217** against an anchor of **216** on `origin/main`, read from the repository's ADR-numbering detector at authorship. A sibling release branch holds the same number branch-only, which does not bind. The number binds at the Stage 12 claim; if the mainline claims it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Branch prose cites this record by its slug token, which resolves at the claim.

**Numbering provenance — `217 → 219`.** Held **ADR-217** branch-local; renumbered to **ADR-219** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 217. In-release citations that read "ADR-217" denote this record.

## Context

A deploy has two jobs. It makes the installed copies match the mainline, and — for a release — it records that the release was deployed and to which targets. The first job was automated by a post-merge hook; the second was never given an owner. The pipeline stage that holds the release's join key carried its deploy step as a clause with no command, so the record was written, or not, by whoever remembered the flag.

The tempting repair is to teach the hook to pass the key. Two things were not visible from that proposal. The rows are permanent, and the hook fires on every checkout that observes a merge. And the deploy tool's own advice for a stamped deploy — the release flag with no names — selects from a window that is not the release, in both directions.

## Decision

1. **Release identity is stamped by Stage 12, once per release, as a commanded and unconditional step** — Phase B4 of the Stage 12 specification. The post-merge hook, the update script and the install path stay unstamped carriers of currency.
2. **The stamped deploy is given its targets by name, derived from the release's own merge commit against its first parent and kept only when they are members of the deploy roster** — the three module arrays the deploy resolves names through, read as text. A name that is not a member is recorded, not deployed. The rows are therefore a function of the release's merge, not of install state or tag position, and the deploy yields the same rows whether or not an unstamped deploy has already made the install current.
3. **A release-stamped deploy states its target set.** The deploy tool accepts the release flag only with named targets or with an explicit declaration that the release has none, and refuses the flag alone, the two contradictory forms and an empty release key before its rules-mirror carrier runs — so a refused invocation writes no row. The step that stamps asserts the key non-empty before it reaches the deploy or a read, and the verification read keys on the recorded slug.
4. **The hook is not changed.** A test pins that neither of its invocation sites forwards a release key on a release-shaped merge.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| **The hook recognises a release merge and stamps it** | Irreversible exposure and no reliable signal. The hook runs on machines where that release's Stage 12 never ran; a missed classification is silent; a stamped row cannot be deleted. |
| **The hook stands down on release merges** | Reverses the purpose of the hook's own decision record for every checkout that is not running that release's Stage 12, and needs the same classifier with a worse failure. |
| **The deploy tool infers the release itself** | Every deploy path would stamp, including a fresh install on a clone that sits on a release tag. |
| **Stage 12 suppresses the hook on its own sync so its deploy is first** | Survived the hard constraints and lost the comparison: it cannot guarantee "first" where any session may sync, it edits a shared rule to buy a property no criterion tests, and it removes defence in depth. |
| **Keep the no-names stamped form for releases with no target** | The window stamps a neighbouring merge's skill onto a release that deployed nothing. |
| **The deploy tool derives the target set from the merge commit itself** | Raised by the adversarial review as the stronger form and not taken at the Collective Review scope-lock, which chose the stage-level derivation filtered by roster membership. As weighed there: a published flag, more logic in the most contended file and a design not prototyped, against a few lines in one stage block. Its advantages are stated rather than dismissed: it would hold the deployability predicate in one place, give the merge-to-rows path a suite arm that fails before the change, and retire the hand-declared zero. |
| **Select targets by the presence of a directory** | Not the deploy's own test. A shared directory under a skill root passes it, and the deploy then stops on that name after its carrier has already written a row. |

## Consequences

**Positive.** Every release whose Stage 12 runs the step carries one row or more under its key, so an empty row set means the stamped deploy did not run, and the Stage 12 verification read detects it. The row set is a function of the release's merge, not of install state or tag position. A zero-target release carries its rules-mirror row alone, which the cycle-time reader names as excluded rather than as a failed deploy.

**Negative, and stated.** An invocation the tool previously accepted now exits non-zero. The Stage 12 step's target derivation is a further textual holder of the three skill roots, and it is prose that no suite executes, so the release's first live exercise of it is its own Stage 12. The obligation to run the step is verified by a read in the stage's own verification phase, not by a gate.

**Bounding consequence.** This record does not make the hook install itself, and does not make a release's rows appear on a machine where Stage 12 was not run.

## Reversibility

**MODERATE** (confidence **HIGH**). Reverting the tool's refusal is one line; rows written under either contract are permanent by the log's design.

## Related ADRs

- **ADR-165** — the post-merge hook as a local git hook. This record extends it: the hook's four sub-decisions stand, and its statement that the deploy tool is not modified is about that decision.
- **ADR-186** — the rules mirror has two carriers, and the deploy's carrier runs before the no-changes exit, never gated on the change sets. The target-set refusal sits above that carrier as argument validation, as the workspace check already does; it gates the carrier on a well-formed invocation, not on what changed.
- **ADR-194** — deploy selection asks the installed corpus, and a named deploy's residual assertion is scoped to the names it was given. A stamped deploy is a named deploy, so that scope carries over unchanged, and a declared zero-target deploy selects nothing and takes the no-changes exit.
- **ADR-092** — plan-file identity binds at the claim-time stamp, so a release stays slug-primary until its Stage 12 claim. That is why the stamped deploy's key is the slug and never a version; the join key itself is defined by the pipeline event-log schema, § 2a.
