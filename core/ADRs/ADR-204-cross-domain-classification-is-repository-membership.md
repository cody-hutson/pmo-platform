---
title: "ADR-204 — Cross-domain classification is repository membership, resolved through one shared helper"
status: Accepted (operator-ratified at the autonomy-ceiling-domains-resolve-canonically Stage-13 close, 2026-09-25)
date: 2026-09-24
release: autonomy-ceiling-domains-resolve-canonically
deciders: "operator (Collective Review scope-lock) + Stage 5 Solutioning spoke (option space, trade-off matrix, design) + Stage 6 Engineering spoke (build, measurement)"
supersedes: ADR-149 in-part (how a write's working directory and target are classified for BLOCK-AUTONOMY-002 and BLOCK-AUTONOMY-004)
tags: [block-autonomy-ceiling, block-draft-files, repository-membership, tier-0, cross-domain, hook-lib, fail-direction, anchor-resolution]
source_observations:
  - "Three implementations answered one question. BLOCK-AUTONOMY-001's second stage walked to the enclosing working tree and asked whether it belonged to this repository; BLOCK-AUTONOMY-002 and -004 classified by the path prefix <workspace>/pmo-platform; block-draft-files asked git for the working directory's common directory. Each was internally correct, and the mismatch was visible only when the three were compared."
  - "The prefix classification was the one granting a demotion. The pmo-platform → projects direction was re-tiered on the premise that it cannot reach the tracked repository, and a path prefix cannot establish that premise, because a working tree of the platform can be created anywhere, including under projects/."
  - "The disclosure direction was unarmed. No fixture paired a projects working directory with a platform worktree stored outside the checkout, and the prefix classification let exactly that write pass the Tier-0 floor."
  - "The shipped walk compared against an unresolved anchor. A symlinked checkout segment, a --separate-git-dir checkout, a checkout that is itself a linked worktree, and a symlinked .git each read as not-a-member for true members. Under a membership-only classification the separate-git-dir shape would have failed BLOCK-AUTONOMY-002 open for the primary checkout itself; this was found at design time, before anything was built."
  - "The workspace root the hooks read is not self-locating. The installer writes the root into each hook's command path and exports no CLAUDE_WORKSPACE_ROOT, so a hook that falls back to $HOME/Claude reads the wrong root on an install made with --workspace-root unless the operator's environment exports the variable. The scope library's root order locates itself; the hook's own root does not."
---

# ADR-204 — Cross-domain classification is repository membership, resolved through one shared helper

## Status

**Accepted** — operator-ratified at the `autonomy-ceiling-domains-resolve-canonically` Stage-13 close, 2026-09-25. Authored at Stage 5 Solutioning for that release, and written to disk in its Engineering stage under the number claimed there against the mainline anchor. The decision this record documents shipped in **v4.68**.

**Supersedes in part:** ADR-149. Only its classification mechanism is superseded: how a write's working directory and target are assigned to the `pmo-platform` or `projects` domain. The following stand unchanged:
- ADR-149's direction split;
- its re-tiering of the converse direction to a mode-gated signal;
- its permanence reconciliation.

ADR-149 keeps `status: Accepted` and gains a `superseded_by:` pointer.

## Context

`block-autonomy-ceiling.sh` enforces two cross-domain rules, split by direction:
- `BLOCK-AUTONOMY-002` covers a `projects/` session writing into the tracked, public platform repository. It is an irreducible Tier-0 floor.
- `BLOCK-AUTONOMY-004` covers a platform session writing into `projects/`. It is a mode-gated layer-discipline signal.

The demotion of the second rule rests on a property of its target: `projects/` is not a git repository, so nothing written there can be committed to the platform.

The hook established that property with path prefixes. A path was `pmo-platform` when it began with `<workspace>/pmo-platform`, and `projects` when it began with `<workspace>/projects`. But a prefix names a location, while the property the demotion relies on is about repositories. A working tree of the platform repository can be created anywhere: a spawned session receives one under its own scratchpad, and the commit made from it pushes to the same public repository. Two consequences followed:
- A `projects/` session writing into a platform worktree stored outside the checkout classified its target as no domain at all, and so passed the Tier-0 floor.
- A platform session inside such a worktree classified its own working directory as no domain, so `-004` never fired.

The same file already held the correct mechanism. `BLOCK-AUTONOMY-001`'s second stage walks upward to the nearest `.git` and asks whether that tree belongs to this repository; it had already learned that the governance floor must follow the repository, not the path. `block-draft-files.sh` answered the same question a third way, through git's common directory. That made three implementations and three anchors for one question.

## Decision

**1. One membership mechanism.** Repository membership is answered by one sourced helper, `core/hooks/lib/platform-membership.sh`, and by nothing else. Three callers use it:
- `BLOCK-AUTONOMY-001`'s second stage;
- the domain classification behind `BLOCK-AUTONOMY-002` and `-004`;
- `block-draft-files.sh`'s repository-identity gate.

Neither hook keeps a membership implementation of its own. The mechanism is the walk `-001` already used, moved rather than rewritten: a bounded upward loop of 64 levels in which the nearest tree wins, with a relative-pointer join for worktrees created with `--relative-paths`, using shell builtins only.

**2. Membership decides the target's domain, and it is evaluated before the location prefix.**
- A target is `pmo-platform` when it sits in any working tree of this repository, wherever that tree lives.
- It is `projects` when it is under `<workspace>/projects/` and in no such tree.
- The `pmo-platform` location prefix is retired as a classifier.

The working directory is read the same way for `BLOCK-AUTONOMY-004`: it is on the platform side when it sits in a working tree of this repository. For `BLOCK-AUTONOMY-002` it is read by location instead, twice, and only to block: it is on the operations side when its payload spelling is under `<workspace>/projects/`, or when its resolved path is under the operations root resolved the same way. Membership masks neither reading.

This is what establishes the premise the direction split reasons from, scoped to what membership can see: a write that `-004` sees as going "into `projects/`" is, by construction, a write into no working tree of this checkout's repository.

**3. The helper answers in three states and owns no failure branch.** It returns *member*, *not a member*, or *undeterminable*. Undeterminable covers an input that is not an absolute path, a walk that exhausts its bound, and a pointer file with no pointer line. The helper never exits, blocks or logs, and each caller maps its answers to its own failure direction:

| Answer | `-001` stage 2 | target of `-002`/`-004` | working directory, for `-004` | block-draft-files identity gate |
|---|---|---|---|---|
| member | block | `pmo-platform` | `pmo-platform` | apply the rule |
| not a member | no block | `projects` under `<workspace>/projects/`, else none | `projects` under the operations root, else none | inert |
| undeterminable | no block | `projects` under `<workspace>/projects/`, else `pmo-platform` | `projects` under the operations root, else none | inert |
| no platform repository at the anchor | no block | as not a member | as not a member | abstain (apply the rule) |
| helper unavailable | block (fails closed) | as undeterminable | as undeterminable | abstain (apply the rule) |

The working directory's side for `BLOCK-AUTONOMY-002` is not a membership answer and has no row here: it is the location reading in Decision 2, which no helper answer can change. A working directory that resolves to no absolute path is a separate, third state — `unresolvable`, from the upstream resolution — on which `BLOCK-AUTONOMY-002` alone fails closed and `BLOCK-AUTONOMY-004` does not fire. An undeterminable membership answer is never `unresolvable`.

Undeterminable stays not-a-member for `-001`, so every input the shipped walk cleared stays cleared. For `-002` it fails closed outside `projects/`, where a write the classifier cannot place might be reaching the repository. Inside `projects/` the location prefix decides, so a corrupt pointer or a missing helper cannot lock operations work out of its own tree. Because the working directory's `-002` side never consults the helper, a missing helper cannot block a platform-engineering session's ordinary writes; it refuses only a session rooted under `projects/`, and only for targets outside `projects/`.

**4. One anchor, self-locating and resolved.** The platform checkout is `<workspace>/pmo-platform`. The workspace root is taken, in order, from:
1. `$CLAUDE_WORKSPACE_ROOT`, when it is set;
2. otherwise, the parent of the `.claude` directory the calling hook was deployed into;
3. otherwise, `$HOME/Claude`.

That is the scope library's root order without its sandbox override. The checkout's own `.git` is then resolved to a physical git directory. It is taken as-is when it is a directory, followed when it is a pointer file, and followed further through `commondir` when it points into a linked worktree's administrative directory.

**5. A missing helper fails the floor's questions closed, and only those.** In `block-autonomy-ceiling.sh` the helper is loaded lazily, inside the Write/Edit branch. It sits behind the same four-part guard the dependency resolver uses (readable, parses, sources, exports), and the guard does not depend on mode. Bash and mcp calls never load it. `block-draft-files.sh` loads it softly and abstains without it. The `-002` block that results names the missing helper and the reinstall remedy, rather than reporting a confirmed platform-repository write.

## Alternatives Considered

**Anchor: the hook's own root order (`CLAUDE_WORKSPACE_ROOT`, then `$HOME/Claude`).** This is the strongest alternative, and the opposing view this record carries. It would keep the membership anchor in step with the hook's location arms and its `projects/` prefix. It lost because that agreement is with a value that is wrong exactly where the two orders diverge: an install made with `--workspace-root` whose environment does not export the variable. It would also regress `block-draft-files.sh` on those same installs, because that hook's current root order locates itself.

**Anchor: the scope library's root function.** Rejected. Its first step is `PMO_SCOPE_GUARD_ROOT`, a sandbox override that exists to neutralize scope for the rule suites. Consuming it would let a scope knob decide which repository the Tier-0 floor protects. It would also make the scope library floor-critical, against its own clause that a missing scope library never gates.

**Anchor: a per-caller argument.** Rejected: it gives one question two anchors.

**Anchor: an identity file stamped by the installer.** Rejected. It adds a new operator-instance artifact that goes silently stale when the checkout moves, and it would be a scope change for this release.

**Anchor: a new public root function in the scope library.** Rejected. It edits a contract every workspace-scoped hook shares in order to answer a question two of them ask, and it reintroduces the floor dependency above.

**Semantics: the union of prefix and membership.** Rejected. It keeps two classifiers for one question, and because it can only ever add platform paths, the classification never becomes the membership answer.

**Contract: a binary answer.** Rejected. Folding undeterminable into not-a-member leaves `-002` no state to fail closed on.

## Consequences

- **The disclosure direction is armed wherever a platform worktree lives.** A `projects/` session writing into any working tree of the platform repository, including one outside the checkout, now blocks at the Tier-0 floor. `-004` now sees platform sessions in relocated worktrees.
- **Writes into a `<workspace>/pmo-platform` that is not a repository no longer block at `-002`.** There is no repository there to commit to, so the prefix was over-blocking. This is recorded and armed rather than left to be discovered.
- **A session whose working directory is spelled under `projects/` cannot write into a platform working tree, even when that directory resolves into one** — a symlink or traversal from `projects/` into the checkout, or a platform worktree placed under `projects/`. The two location readings are used only to block. The sanctioned exit is to relaunch from a working directory outside `projects/`.
- **Symlinked, `--separate-git-dir` and worktree-shaped checkouts are recognized.** For `-001` this flips true members that the unresolved anchor misread, from not-a-member to member. In the standard layout, a regular clone whose `.git` is a directory, no verdict moves.
- **`-004` on a relocated worktree stays session-scoped.** It sits below the workspace-scope gate, so a worktree outside the governed workspace root is still beyond `-004`'s reach. The floor rules above that gate are not limited this way.
- **`block-draft-files.sh` is inert outside the governed workspace root, by design.** Its scope gate exits before its identity gate, so a platform worktree outside the root is not recognized there. This is recorded as the documented verdict, not tested as recognition.
- **Accepted residuals:**
  - A platform worktree nested inside `projects/` that also hits an undeterminable condition is classified by the prefix.
  - A pointer file the hook cannot read is treated as absent, and the walk continues upward, as the shipped walk did.
  - A submodule of the platform repository would read as a member, since its administrative directory lives under the platform's own. The repository carries none.
  - A hardlink placed inside a platform worktree to a file under `projects/` is outside what any path classification can see.
  - A separate clone of the platform remote is a different repository to git and is not classified as a member. A write into it from a `projects/` session draws no `-002`, and a platform session writing into a clone placed under `projects/` draws the demoted `-004`. Either clone can push to the same remote: membership establishes the premise for working trees of this checkout's repository, not for every copy of its remote.
  - The target's `projects/` classification compares against the operations root as spelled beneath the resolved workspace root. Only the working directory's `-002` reading resolves a symlinked operations root.
- **The hook's own workspace root still does not locate itself.** The helper's anchor now does, but the location arms and the `projects/` prefix still read the hook's own root. On an install where the two diverge, `-001`'s second stage is live and `-002`/`-004` are not. That defect predates this record and is routed separately.

## Reversibility

MODERATE. A revert restores the prefix classification, the inline walk and the git-based identity gate. The runtime copy of the hooks is refreshed again and verified by hash, and the orphaned deployed helper is removed. No data is lost.

## Verification

The arms were written assertion-first. The relocated-worktree arms fail against the prefix classification and pass against membership. They cover:
- the disclosure direction;
- the demoted direction, from a working directory that is exactly a worktree root;
- the foreign-worktree twins of both;
- the separate-git-dir and symlinked-checkout anchors;
- the trailing-slash, trailing-dot, symlinked and relative spellings of `CLAUDE_WORKSPACE_ROOT`;
- the working directory spelled under `projects/` but resolving into the platform; and `projects/` itself symlinked out of the root, with the working directory spelled logically and physically.

A prefix-restoring mutant replaces only the helper's answer with the retired prefix test. It allows both relocated arms while still blocking an in-checkout write, which proves the mutant is live and attributes the difference to membership alone. A sandbox without the helper blocks a governance write the healthy hook allows. The helper's contract is exercised directly by sourcing it inside the test suite.

## Related ADRs

- ADR-149: superseded in part (the classification mechanism only).
- ADR-031: the payload-triggered hook design this rule set lives in; unchanged.

## References

- #6200: the card that decided this. Two sibling rules tested repository membership on different axes, and the weaker one carried the security demotion.
- #6199: the upstream card whose resolved working directory the classification consumes. The working directory is resolved by the same resolver as the target.
