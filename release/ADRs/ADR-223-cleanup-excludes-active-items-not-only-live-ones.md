---
title: "ADR-223 — The orphan cleanup excludes active items, not only live ones"
status: Accepted — operator-approved plan, 2026-10-24; the definition of active is the operator's
date: 2026-10-24
release: "fix-cleanup-active-exclusions (an out-of-band fix, outside any release milestone)"
deciders: "Workspace owner (operator) — set the definition of active and approved the implementing plan; design and authoring by a platform-engineering session"
supersedes: ADR-021 in-part (recency prohibition and absolute-path holder residual and skip-label vocabulary)
tags: [architecture, release-tooling, safety, liveness, worktree-lifecycle, fail-closed]
source_observations:
  - "2026-10-24, a workspace with 183 linked worktrees: all 15 running claude processes had their working directory at the workspace root and none inside a worktree. The cleanup dry-run's liveness oracle mapped 0 live holders across those worktrees while 7 desktop sessions were busy, and classified REMOVE 19 worktrees whose HEAD had moved within 24 hours. One of them, created within the hour, had its session running in it."
  - "Same day, reproduced in an isolated clone: a throwaway worktree whose HEAD a live process moved by path, from a working directory outside the tree, classified REMOVE under the pre-change classifier, and its branch was projected WILL-DRAIN."
  - "Same day, each candidate signal measured on the four worktrees whose HEAD moved in the preceding hour. Process cwd scan: 0 holders. All-open-file scan (the re-triage target ADR-021 named): 17 s over 49,786 rows, 0 holders. Worktree lock line: 1 of the 183 worktrees locked. Desktop app worktree registry: only its own pooled worktrees, none leased, and not the busy one. HEAD reflog movement: within 1 h on 4, 24 h on 26 and 72 h on 33 of the 183."
  - "Same day: 58 of 184 worktrees held git-ignored content, and none of them held only regenerable caches. The content was install copies: allowlists, hook logs and an instance-container seed. A tree whose only work is ignored reads clean, and a plain `git worktree remove` without --force deletes it. A `git status` that fails with exit 128 produced an empty capture, which the classifier read as clean."
  - "Same day, the fixed classifier's real dry-run: 24 of the 116 worktrees it would otherwise remove held git-ignored content, mostly install copies under .claude/ and a few instance-container directories. Counting that content as active leaves 92 removable."
---

# ADR-223 — The orphan cleanup excludes active items, not only live ones

## Status

**Accepted.** The operator set the definition of active this record implements and approved the implementing plan on 2026-10-24. The definition: an item is active when it is recent or held, when it has an open pull request, or when it carries uncommitted work. The coordinating cleanup session then settled, under that approval, that git-ignored content counts as uncommitted work at any age, and that every active row carries one label form.

This record amends ADR-021 in part, as both records' frontmatter states. ADR-021's oracle mechanism, the all-process working-directory scan with its self-canary and fail-closed posture, stands unchanged. What this record replaces is ADR-021's premise that the oracle alone can decide whether a worktree is in use.

**Numbering provenance.** Authored as ADR-223, the next number after a mainline anchor of 222. Two unmerged release branches also hold 223 as claims, so the number is a duplicate at authoring and binds only at merge: whichever claimant merges later is moved by `release/tools/renumber-adr.py`, which appends a provenance note to the record it moves. A number past the anchor plus one would leave a gap, which the ADR-number integrity check refuses. <!-- adr-record -->

## Context

ADR-021 defined liveness as "some live process has its working directory at or under the worktree" and accepted one residual by name: an operator that reaches a tree by absolute path from a working directory elsewhere. It prohibited recency as a signal, on the premise that liveness is knowable from process evidence.

On 2026-10-24 that residual became the common case. Desktop sessions are rooted at the workspace root and reach their worktrees by absolute path or `git -C`. No process has its working directory inside such a tree, so the cwd scan cannot see the session. A cleanup run read the workspace as idle while sessions were working, and would have removed trees those sessions were using.

The premise behind the prohibition fails on this host. Every process-evidence signal was measured, including the all-open-file scan ADR-021 named as its re-triage target, and none sees a session that reaches its tree by path. A session in that position leaves two kinds of trace: HEAD movement, which git records in the reflog, and the files it writes — which read as uncommitted changes, or, under an ignored path, as git-ignored content.

Two further fail-open paths surfaced in the same review, both on uncommitted work. A tree whose only work sits under ignored paths read clean, and git's removal deletes ignored files without `--force`. And a `git status` that failed was read as clean.

## Decision

1. **Active items are excluded, and nothing overrides the exclusion.** A worktree or branch is active when any one of these holds:
   - **(a) Recent or held.** Its HEAD moved within the active window (for a branch, its ref; for a remote branch, the tip and the tracking ref), or a live process or a worktree lock holds it.
   - **(b) Open PR.** Its branch, or the release it belongs to, has an open pull request. Belonging is by the release's branch families. A detached tree carrying commits off the mainline belongs to a pull request whose head contains them.
   - **(c) Uncommitted work.** It has uncommitted changes, or git-ignored files present at any age. Git deletes ignored files without `--force`, and nothing distinguishes an install copy from a session's work product written into an ignored home.

   An active item is never REMOVE and is never projected WILL-DRAIN. No flag, `--force` included, makes it removable.
2. **One label form, and no liveness claim.** Every active row reads `SKIP — active — <reason>`, the live and locked classes included, so no active row can read as a pending removal. The reasons are recent HEAD activity, live process, lock held, open PR, uncommitted changes, git-ignored files present, and status unreadable. Recency is its own reason, beside the live-process reason rather than inside it, so the oracle's meaning is unchanged: the report says what trace it read, and does not say a process holds the tree. The branch skip that the resolve pass may still drain reads `SKIP — worktree attached`, deliberately not of the active form.
3. **The window can be widened, never narrowed.** The default is 24 hours, the operator's definition. `--active-window-hours` accepts only larger values.
4. **Every reader fails closed.** A trace that cannot be read makes the item active, as `SKIP — active — status unreadable (<trace>)`. That covers an unreadable reflog, a failed status, a failed ignored-file listing, an unavailable open-pull-request list, a remote that moved since the last fetch, an unavailable liveness oracle, and reflogs switched off.
5. **The exclusions are re-read at apply time**, immediately before each removal, as ADR-021's apply-time liveness re-check already is. That includes the uncommitted-work check: git refuses to remove a dirty tree without `--force`, but not with it.
6. **A tree containing another registered worktree is not removable.** Removing the outer tree would delete the inner tree's directory, whatever the inner tree's own classification.

## Alternatives Considered

- **Keep liveness as the only signal, and re-triage to the all-open-file scan.** This is ADR-021's own re-triage target. Measured, it saw no holder on any of the trees in use, at many times the cost of the cwd scan. Rejected: it does not reach the case.
- **The desktop app's worktree registry.** Rejected. It covers only the app's own pooled worktrees, it held no leases, and it omitted the busy tree. It also exists once per app account, and its format is internal to a third-party application. ADR-021's requirement of working with zero cooperation from the harness still holds.
- **The worktree lock line.** It is already a protective class. Locks were measured on a single tree, so the lock line cannot cover this case.
- **The index file's modification time.** Rejected. Any `git status` refreshes it, including the cleanup tool's own dirty check, so every tree would read recent.
- **Working-tree file mtimes.** Rejected. A modified or untracked file already reads dirty, a checkout's fresh mtimes coincide with the HEAD movement the reflog already records, and git-ignored content is excluded by its presence.
- **Count git-ignored content only while it was written inside the window.** Rejected under the zero-deletion bar. An ignored file written before the window can still be a session's only copy of its work, and git's removal deletes it without `--force`. The cost is measured: some trees whose ignored content is install copies are no longer removed by the tool.
- **Fail closed on the all-states pull-request map.** Rejected in favour of a dedicated open-pull-request query. The all-states map degrades on truncation to per-branch lookups, and those cannot say which releases have an open pull request. The open set is small enough to read completely in one query.
- **Operator workarounds — lock active trees, or protect-list them, so a removal can run around them.** Rejected and not offered as mitigation. They move the safety burden onto the operator, and they leave the tool's REMOVE set wrong.

## Consequences

- **+** A session that reaches its tree by path is protected while it keeps moving HEAD within the window, and for as long as its tree holds uncommitted or git-ignored content. The cleanup no longer needs the harness to set each session's working directory to its tree.
- **+** The two fail-open paths on uncommitted work are closed, and the apply-time re-check covers `--force`.
- **+** Every exclusion carries its reason in the row, so an operator can see why an item stayed.
- **−** A session that neither moves HEAD within the window nor leaves uncommitted or git-ignored content is not seen by any signal on this host. Its tree is protected only by a lock or a holder whose working directory is inside it.
- **−** A tree whose git-ignored content is only install copies is not removed by the tool. Removing it needs that content gone first, by an operator decision outside this tool.
- **−** Cleanup drains more slowly. A finished tree stays for up to a window after its last activity.
- **−** Removal now depends on reading the open pull requests. A host with no usable `gh` removes no worktree or branch until the list is readable, the same posture ADR-021 takes when the cwd scan is unavailable.

## Reversibility

**CHEAP** — the change is confined to classification and to the apply-time re-check. A revert restores the prior behaviour; nothing it does is irreversible, because an excluded item is left in place. Confidence HIGH on the mechanism, measured on the host and reproduced in an isolated clone. Confidence MEDIUM on the window length, which is the operator's definition and can be widened.

## Related ADRs

- **ADR-021** — the liveness oracle. Amended in part: its prohibition on recency and its accepted residual for absolute-path holders are replaced by this record's active exclusions, and its skip labels by this record's single active form. Its mechanism, self-canary, fail-closed posture and apply-time re-check stand.
- **ADR-142** — the self-test runs behind the workspace boundary check rather than being exempted from it. This record's fixtures run under that same boundary.
