---
title: ADR-242 — The commit-time in-repo home guard runs whether or not CLAUDE_HOOK_BYPASS is set; its push-time read honours the bypass
status: Proposed
date: 2026-11-28
release: in-repo-home-is-guarded
deciders: "Workspace owner (Collective Review scope lock, option C of the bypass decision); the guard's host and predicate chosen at Stage 5 Solutioning, and the option named by the adversarial design review"
tags: [architecture, git-hooks, bypass, in-repo-homes, commit-guard, reversibility-cheap]
source_observations:
  - "The card that ships the /local-state/ README and the commit guard over the three registered in-repo homes asks, in its second criterion, for the guard to fail a forced add whether or not CLAUDE_HOOK_BYPASS is set."
  - "Before this record every platform hook and git hook exited on CLAUDE_HOOK_BYPASS before anything else, so a session launched with the bypass could force-add a file under a home, commit it and push it, and no local layer would read either step."
  - "A home's README passes the guard by construction, and nothing else in a home is ever committed, so the commit-time home check has no legitimate override use."
  - "Every CI layer reads a branch that is already on the remote: the push-time scan runs after the push, and a pull-request job needs the head branch published."
---

# ADR-242 — The commit-time in-repo home guard runs whether or not CLAUDE_HOOK_BYPASS is set; its push-time read honours the bypass

## Status

**Proposed** — authored at Stage 6 Engineering for the `in-repo-home-is-guarded` release, carrying the option the workspace owner chose at that release's Collective Review scope lock. Ratification is recorded in this file's frontmatter `status:` field at the release's Stage 13 Close, which is where it must be verified, and is never inferred from milestone closure.

**Numbering provenance.** Claimed as **242** against an anchor of **241** on `origin/main`, read from `release/tools/renumber-adr.py --detect` at this record's authoring commit, which reported 242 as the next free number and also as a branch-only claim of sibling releases in flight. A branch claim is detection-only and never binds, and the ADR-number integrity gate refuses a gap, so the record takes the binding oracle's number; whichever claimant merges later is moved by the renumbering tool at merge time, which appends one provenance note per hop and rewrites this release's in-branch citations.

## Context

The instance-data placement standard registers three in-repo git-ignored homes — `/local-state/`, `/analysis/` and `/roadmaps/` — each of which tracks its own `README.md` and nothing else. An ignore rule does not stop `git add -f`, so the release adds a commit guard, `core/hooks/git-pre-commit-homes.sh`, which the PII guard (`core/hooks/git-pre-commit-pii.sh`, the hook git's one pre-commit slot runs) calls at its two input points: the staged index at pre-commit, and, with `--commits`, every commit a push would publish when the pre-push hook (`core/hooks/git-pre-push-pii.sh`) runs it. A required pull-request job, the In-repo home content gate, reads the merge tree.

Every platform hook and git hook honours `CLAUDE_HOOK_BYPASS`: it is read first and the hook exits. The bypass is an operator-only escape hatch set at launch; an agent cannot set it mid-session through the ordinary command forms. A session launched with it, though, drops every local layer, and the layers that remain run after publication. The pre-push scan in CI runs after the push, and a pull-request job reads a branch that is already on the remote, so for this guard the local layers are the only layer before publication.

The commit-time home check has no legitimate override use: a home's README passes it by construction, and anything else in a home is never committed. Honouring the bypass at commit time therefore buys an operator nothing, and costs the one property the guard exists for.

## Decision

**(1) The commit-time read runs under the bypass.** The PII guard runs the home guard's staged read on git's own no-argument invocation, ahead of its `CLAUDE_HOOK_BYPASS` exit and before it sources any resolver, so no instance home, needle file or mode dial reaches the verdict. A forced add followed by `git commit` is refused whether or not the bypass is set. When the home guard is not found beside the PII guard, that commit is refused too, the bypass included, because a check that cannot run is not a pass.

**(2) The push-time read honours the bypass.** The `--commits` read sits after the PII guard's bypass exit, and the pre-push hook exits on the bypass before it runs the PII guard at all, so `git-pre-push-pii.sh` is not restructured. A commit made under the bypass without pre-commit — `commit-tree`, a merge, a cherry-pick or a rebase — is therefore published by a push under the bypass. That residual is recorded, and the pull-request job keeps it off `main`.

**(3) The escape hatch is the hook-skip flag.** An operator who must commit such a file anyway uses `git commit --no-verify`, which skips every pre-commit layer. `BLOCK-DESTRUCTIVE-024` refuses that flag to agents for commit.

This is an exception to the uniform bypass convention, and the only check in either PII git hook that the bypass does not skip; every other read of these two hooks still exits on the bypass. It is not the first verdict the bypass leaves standing — a PreToolUse hook's missing-helper block is evaluated before its bypass check too — but that block guards a hook's own integrity, while this one is a rule's verdict. The guard's posture, its layers and its stated limits are recorded once, in the gate-coverage register of `core/standards/gate-efficacy-standard.md`; this record does not restate them.

## Alternatives Considered

- **Honour the bypass at both reads** (option B, the Stage-5 designer's recommendation). Rejected: a session launched with the bypass would stage and commit a forced add silently, and push it, and the only layer left — the pull-request job — runs after the branch is published. The designer's mitigation said the required job catches what the bypass lets through; the adversarial review showed it catches it only at merge, not before publication.
- **Ignore the bypass at both reads** (option A). Rejected: the push arm would have to compute the push range under the bypass, so the pre-push hook would call the home guard itself before its own bypass exit, and a range error under the bypass would start refusing pushes. Most of option A's cost is that pre-push restructure; option C takes A's commit-time half, which covers the card's own vector (a forced add followed by a commit), without it.
- **A homes-only bypass variable**, distinct from `CLAUDE_HOOK_BYPASS`. Rejected: a second escape hatch for a check that has no legitimate override use, and a variable an operator would have to learn for one hook.
- **Read the bypass inside the home guard.** Rejected: the guard would carry the bypass semantics of both callers, and its CI caller has no bypass at all. The callers decide where it runs; the guard reads no dial and no bypass.

## Consequences

- **Positive.** A forced add under a home cannot be committed through git's pre-commit slot, whatever the PII guard's dial reads and whether or not the session was launched with the bypass. The verdict depends on no operator-instance file.
- **Negative.** One hook departs from the convention that the bypass exits every hook, so a reader who knows the convention mispredicts this one; the PII guard's header, the home guard's header and the gate-coverage row each name the exception. A missing home guard now refuses a commit even under the bypass.
- **Stated limits.** The push-time read honours the bypass, so a commit made under the bypass without pre-commit is published by a push under the bypass; `git push --no-verify` and commits written through the hosting API reach no local layer either. The pull-request job keeps home content off `main` in all of these cases, but none of them is stopped before publication.

## Reversibility

**CHEAP · Confidence MEDIUM.** Moving the staged call back below the bypass exit restores the uniform convention in one edit to `core/hooks/git-pre-commit-pii.sh`, with the suite's bypass arms re-pointed in the same change. No data, configuration or wiring changes.

## Related ADRs

- **ADR-165** — one git-hook home and one install path; the home guard rides the existing pre-commit slot and the existing commit-range chain rather than a new link.
- **ADR-231** — non-tracked data homed by risk class; it obliges a commit guard, at pre-commit and in CI, over the in-repo home, a forced add included.

## References

- `#8022` — the card that ships the `/local-state/` README and the commit guard over the registered in-repo homes, and whose second criterion this record decides.
- `#9205` — the Stage-5 design sub-task that drafted the bypass decision and carries the Collective Review's decision record.
- `#9235` — the adversarial design review that named option C and corrected the bypass briefing.
