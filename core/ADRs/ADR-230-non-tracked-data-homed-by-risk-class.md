---
title: ADR-230 — Non-tracked platform data is homed by its risk class
status: Proposed — authored at Stage 6 Engineering for the `placement-rules-and-adr` release; flips to Accepted at that release's Stage 13 close gate (Phase A13), where the operator ratifies it, recorded in this field.
date: 2026-11-05
release: placement-rules-and-adr
deciders: "Workspace owner (placement design agreed on the parent epic; the layering inputs at an operator review; the whole supersession of ADR-141 and the per-user and install-level homes at the Stage 4 plan gate; the exact home paths, the enumerated main-checkout carve-out, the release-corpus classification and the added supersession edges at the Collective Review scope-lock; ratification at Stage 13) + Stage 5 Solutioning spoke (design) + independent adversarial design review + Stage 6 Engineering spoke (authorship)"
supersedes: ADR-141 whole, ADR-017 in-part (Decision 4's workspace placement of leak-risk content and its routing of event logs to XDG state), ADR-032 in-part (Decision 1's classification and home for the release corpus and Decisions 2 and 3 and the Deferred-migration plan and the operator-instance home in Decision 5 and the Bootstrap), ADR-046 in-part (Decision 4's criterion that keeps runtime state in the operator-instance path family), ADR-096 in-part (the store's home as install-scoped working state and Decision 3's admission of a git-ignored in-repo path)
tags: [architecture, placement, risk-class, working-state, leak-risk, local-state, xdg, operator-instance, supersession, migration, resolver, worktree, carve-out]
source_observations:
  - "The parent epic's inventory (2026-09-27): one out-of-tree container at the workspace root held 24 top-level entries mixing leak-risk content, working state for two repositories and empty install stubs, and 110 tracked files resolved paths into it; a re-count on 2026-10-27 found 27 entries."
  - "Release hubs wrote their working state into that container because the hub-state standard and the hub-spoke bridge named it as the runtime home; at the epic's inventory at least 25 of 106 run folders and 839 of 8,909 event-log rows belonged to a second repository."
  - "The out-of-tree reason that is correct for the PII scan lists was applied to every member of one folder, and the folder grew by default because nothing required a new kind of data to be classified or registered."
  - "A worktree session could not write the analysis workspace, an in-repo git-ignored home, because the main checkout is read-only to sessions and a worktree's own copy of the folder is empty; the rule and the hook enforcing it had diverged."
  - "An operator review (2026-10-27) of how the platform fits a setup running several separate areas of work produced four layering inputs; two bind this record: no platform folder is left at the workspace root, and the leak-risk home is keyed on the user rather than the workspace."
  - "The usage store records every session on the install: at that review 1,764 of its 3,225 rows carried a working folder, and 32 of those were outside this repository's checkout."
  - "A session branch on the public remote carried 22 committed files of release working state (hub briefs, a resume file, staged ledger rows) so that a fresh session could resume a run (found 2026-10-08)."
  - "Measured at this record's Stage 5 (2026-11-05): no tracked file read an XDG data or XDG state base directory; the platform's only per-user root in use was its XDG config root."
  - "Measured at this record's Stage 5 (2026-11-05): six ADRs read Proposed on the mainline, the oldest ratification promise 138 days old and one that promised a Stage 13 flip 61 days old; the corpus's one earlier whole supersession had left its target frozen behind a Proposed superseder for 26 days."
  - "Measured at this record's adversarial design review (2026-11-05): the shipped write-guard hook already exempted the git-ignored analysis subfolders and roadmap instances from the main-checkout write block, through a static predicate in the hook source; and the sandbox test asserted isolation of the per-user config root only, never of an XDG data or state base."
---

# ADR-230 — Non-tracked platform data is homed by its risk class

## Status

**Proposed.** Authored at Stage 6 Engineering for the `placement-rules-and-adr` release from the design rendered at its Stage 5 Solutioning, as amended by that design's adversarial review and by the release's Collective Review scope-lock. It flips to Accepted at the release's Stage 13 close gate (Phase A13) when the operator ratifies it, recorded in this file's `status:` field.

**Supersedes ADR-141 whole, and ADR-017, ADR-032, ADR-046 and ADR-096 in part.** The partial edges carry their reciprocal pointers from the moment this record merges. ADR-141's `status:` transition to `Superseded` is applied in the same commit that ratifies this record and never earlier: a superseded record is frozen, so retiring it ahead of ratification would leave it retired by a record not yet in force, with no edit able to undo that. Until then the whole supersession is pending, as this record's `Proposed` status says.

**Numbering.** Allocated at Engineering Commit 0 from `release/tools/renumber-adr.py --next-free` against the mainline anchor; it binds at the Stage 12 claim. In-release prose cites this record by its slug token.

## Context

The platform keeps several kinds of data out of git: release-hub run state, the pipeline event log, close-out registers, deploy warn logs, usage telemetry, allowlist instances, the PII scan lists and the people roster. ADR-141 gave all of them one canonical default — a container at the workspace root, `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` — on the principle that where a path family lands is decided by who writes it, not by how private it is.

That principle put two unlike things in one folder. Leak-risk content has to stay out of every repository, because one wrong commit to a public remote exposes it. Working state has no such reason: it is release and run state that belongs to the repository whose release produced it. Housing both in one out-of-tree folder applied the leak-risk reason to everything, and four failures followed.

- **A release depended on a folder outside its repository.** The hub-state standard and the hub-spoke bridge named the container as the runtime home, so every run wrote its state outside the repository it served, and a second repository's runs and event rows landed in the platform's container.
- **The container grew by default.** Each new kind of data went there because it was the default home; nothing required it to be classified or registered first.
- **Worktree sessions could not reach in-repo homes.** The main checkout is read-only to sessions, a worktree's copy of an ignored folder is empty, and the rule and the hook that enforce the boundary had drifted apart.
- **Working state was resumed through git.** With no in-repo home, a session committed release working state to a tracked branch on the public remote so that a fresh session could resume.

The parent epic agreed the design recorded below as D1 to D8 before slicing. An operator review later added layering inputs, and two bind this record: after the cleanup wave no platform folder may remain at the workspace root, and the leak-risk home must be keyed on the user rather than the workspace, so a workspace move cannot strand the PII scan lists — the failure ADR-141's own migration section named. The release's Collective Review then settled the exact per-user paths, enumerated the main-checkout carve-out, classified the release corpus as tracked repository content, and added the supersession edges the design's adversarial review found.

## Decision

**Where a kind of non-tracked platform data lives is decided by its risk class — what would follow if it reached a repository. Each class has one home per repository or per install; working state's in-repo homes are the registered set D1 enumerates, with release and run state in `/local-state/`.**

| Class | Contents | Home | Protection |
|---|---|---|---|
| **Working state** | Release-hub runs, the pipeline event log, close-out registers, deploy warn logs, allowlist instances (each checked for operator identifiers); analysis artifacts and roadmap instances | Release and run state: `/local-state/` at the root of the main checkout of the repository the state belongs to. The folder and its README are tracked; the contents are git-ignored. Subfolders: `release-runs/`, `event-log/`, `registers/`, `logs/`, `telemetry/`, `allowlists/`. Analysis artifacts and roadmap instances keep the in-repo git-ignored homes they already have, `/analysis/` and `/roadmaps/` | The ignore rule; for `/local-state/`, also a commit guard (pre-commit and CI) that fails anything staged under the folder, a forced add included |
| **Working state, install-scoped** | Usage telemetry, which records every session on the install | `${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry/` | Outside every repository and every workspace |
| **Leak-risk** | The PII scan lists, the people roster, its clarification queue, their backups, and an embargoed security-fix run until disclosure | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` | Outside every repository and every workspace; permission mode 0700 on each folder and 0600 on each file; the resolver refuses a resolved home that sits inside a git work tree, ignored or not |
| **Operator PMO content** | Projects, portfolio, meetings, the intake inbox | `projects/`, unchanged | Outside every repository |
| **Tool-owned** | The memory store, the deployed hooks, skills and rules mirror, operator config | Unchanged | Their own |

A repository's `/local-state/` admits only that repository's own release, run and operating state — what a platform run produces, and the configuration it reads, while releasing or operating that repository — and content about the operator's other areas of work never enters a repository's tree, ignored or not. The placement standard states that admission test in full and registers every surface against one row of this table.

### D1 — Working state lives in the main checkout, and worktree sessions may write its enumerated homes

`/local-state/` sits in the repository's main checkout, visible beside `roadmaps/` and `analysis/`, and every worktree reaches it by absolute path. Where an operator holds more than one clone of a repository, every clone resolves to one designated main checkout, so one operator still has one working-state home per repository; how that checkout is designated belongs to the resolver.

The read-only rule for the main checkout gains a carve-out, and its admitted set is enumerated rather than defined by reference: a worktree or spoke session may write into the main checkout only inside `/local-state/`, inside a subfolder of the analysis workspace (`/analysis/<sub>/`), or at a roadmap instance (`/roadmaps/<name>`), and nowhere else. This amends the parent epic's agreed D1, which admitted `/local-state/` only. The two further homes are the ones the shipped write-guard hook already exempts, so the enumerated set records what is enforced rather than widening it.

The hook's predicate stays a static pattern in the hook source, because an exemption read from an agent-writable surface would make the guard's escape hatch writable by its own subject. The placement standard's register of in-repo git-ignored homes and the hook's static set are therefore two surfaces held equal by a parity check that fails when they disagree, owned by the worktree-sessions slice and the placement-checklist check (§ References). Registering a further home admits no write until the hook's static set changes in the same change, and the rule's prose and the hook's path scoping change together, so the two cannot diverge again.

**Channel scope.** The carve-out binds the file-write channel the hook guards. The shell channel carries no write guard on the tracked tree today, a residual the hook's own rule already records as accepted; this record does not claim the carve-out seals it.

This trades the stronger protection of a folder inside `.git/` for visibility. Its costs are accepted and become build obligations: every check that walks the tree excludes the folder; a forced `git clean -x` deletes it, which agents are already denied; and the carve-out is enforced by the hook on the channel it guards, not only stated.

### D2 — Borderline classes are decided per instance

An embargoed security-fix run is leak-risk until disclosure, so a hub classifies each run when it starts and the resolver takes a run-class argument. Allowlist instances are classified one by one, each passing an identifier check before it is treated as working state.

### D3 — One event log per repository

Each repository keeps its own pipeline event log in its `/local-state/event-log/`. Cross-repository telemetry reads each log; no log interleaves two repositories' histories.

### D4 — An external target holds its own state

A target repository ships its own `/local-state/`, ignore rule and commit guard. A hub reads the target at run time and stores nothing about it, as ADR-109 decides for every target-side fact.

### D5 — One resolver per class, behind a switch that keeps today's homes

Each class resolves through one resolver. A switch defaults to today's homes and is flipped per repository at its cutover, so nothing changes at runtime before then: until a repository's cutover every class keeps resolving to today's path — hub state, for one, through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`. The overrides honored today keep resolving as § Carried forward from ADR-141 states, and a host without XDG base directories derives each per-user home through the same override seam.

### D6 — Migration is copy, verify, read from both, flip, retire

Each cutover copies, verifies checksums, reads from both homes for a window, flips the switch, and retires the old home after a retention window. A run in flight finishes on the old home or hands off at a checkpoint. Each cutover is rehearsed first, with a run in flight and a resume from a different account and worktree. Verification is by positive assertion, never by absence of complaint: the PII guard reads its scan lists through the leak-risk resolver, and after an uncopied flip that guard goes quiet rather than loud.

### D7 — Names

The working-state home is `/local-state/` in each repository. The leak-risk container is named for its class: it is the `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` folder, and this record spells it only in that rooted form.

### D8 — This record supersedes ADR-141 and reconciles the records that placed these surfaces

It supersedes ADR-141 whole; supersedes ADR-017, ADR-032, ADR-046 and ADR-096 in part; and composes with ADR-167, ADR-178, ADR-109 and ADR-045 without superseding them, as Related ADRs states for each.

### Carried forward from ADR-141

ADR-141 is superseded whole, so the clauses of it that still bind are restated here in substance as this record's own decision. After ratification they bind through this record, not through the frozen one.

1. **The operator's own areas of work are theirs.** The platform creates nothing inside the operator's own areas of work, the personal area included, reads nothing from them, and writes no runtime state there.
2. **Every override honored today keeps resolving as before until its class's cutover.** An environment override or an `operator.toml [paths]` field that redirects a home today keeps redirecting it, at the same precedence, until the cutover of the class that home belongs to; an operator who set an explicit home is unaffected before then. A single override that redirects the whole family today spans several classes under this record, so each cutover states how a family-wide override maps onto the class homes it touches.
3. **One resolver per class is the only site that spells a home.** Consumers call it rather than inlining a default.
4. **Provisioning is create-once.** It is skip-if-exists, dry-run-aware and rollback-recorded.
5. **The leak-risk class stays out of every tree.** Its home sits outside every repository and every workspace, so no repository commit can reach it.

### Layering input 1 — No platform folder remains at the workspace root

When the cleanup wave retires today's container at `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/`, the folder is removed rather than left behind empty. Afterwards the workspace root holds the operator's own areas of work, the repository checkouts and `projects/`, and nothing the platform owns.

### Layering input 2 — The leak-risk home is keyed on the user

The leak-risk container lives in the user's XDG data home, beside the platform's per-user config root, not at the workspace root. The XDG data home is chosen over the config root because `~/.config` is the directory dotfile managers most often version or sync wholesale. An operator who syncs or versions the XDG data home excludes the container.

### Install-scoped working state — the usage telemetry home

Usage telemetry covers every session on the install, so it is install-scoped working state, homed in the user's XDG state home, where ADR-017 Decision 4 already routes telemetry. It never enters a repository's `/local-state/`, because its rows describe work outside that repository, and its store never resolves into a repository's tree, ignored or not — stricter than the resolve-time guard ADR-096 decided, which admitted an ignored in-repo path. Derived, repository-scoped telemetry — a cost row for one repository's releases, for example — passes the admission test and may live in that repository's `/local-state/telemetry/`.

### Release-corpus location

Recorded by the corpus-home slice of this release.

## Alternatives Considered

| Decision | Alternative | Why it was not taken |
|---|---|---|
| D1 | A folder inside `.git/` | The strongest protection — git never stages it and `git clean` does not reach it — but invisible to the operator, who browses working state the way they browse `roadmaps/` and `analysis/`. Visibility was chosen, and its costs are carried as build obligations. |
| D1 | A folder in each worktree | Worktree cleanup deletes it with the worktree, and a run resumed in another worktree or account cannot find it — the reachability defect the analysis workspace already hit. |
| D1 carve-out | Admit any in-repo git-ignored home the placement standard registers | A hook that read the standard's register would make the guard's escape hatch writable by its own subject, and a static hook beside a rule defined by reference drifts at the first new registration — the divergence this record exists to close. |
| D7 | Keep today's container name | A name that says "instance" invites every instance-shaped surface, which is how the container grew by default; and Layering input 1 requires that no platform folder remain at the workspace root. |
| D3 | One shared event log | It interleaves two repositories' release histories and leaves an external target's rows in the platform's home. |
| Layering input 2 | Rename the container at the workspace root | It leaves a platform folder at the workspace root, against input 1, and keys the leak-risk resolver on the workspace, so a workspace move strands the PII scan lists. |
| Layering input 2 | A folder under the per-user config root | The simplest option — tests already isolate that root — but `~/.config` is the directory most often versioned or synced wholesale, which is the exposure this class exists to avoid. |
| Layering input 2 | The XDG state home, or a native folder per operating system | State is for data not important enough for the data home, and the scan lists and roster are irreplaceable; a native folder per operating system forks the XDG convention the platform's per-user config already follows. |
| Telemetry | This repository's `/local-state/telemetry/`, after the identifier check strips working-folder names | It contradicts the admission test: stripping a folder name removes the path, not the fact that the row describes work outside the repository. |
| Telemetry | The same data home as the leak-risk container | One root instead of two, but it contradicts ADR-017 Decision 4, which routes telemetry to the XDG state home, and places a projection that can be rebuilt into the data home. |
| ADR-141 | Supersede it in part | Its headline (one home for the whole family) and its kernel (placement decided by who writes it) are both overturned; a partial edge would keep a contradicted record in the population the durability lint polices. |

## Consequences

**Positive.**

- A release depends on no folder outside its repository once its cutover runs, and an external target carries its own state.
- Leak-risk content is protected by being outside every tree and working state by an ignore rule plus a guard — each class gets the protection its risk warrants instead of one shared default.
- A new kind of non-tracked data has a classification to pass before it has a home, so the out-of-tree container can no longer grow by default.
- The leak-risk resolver keys on the user, so moving the workspace on one machine cannot strand the PII scan lists.

**Negative, accepted.**

- An ignore rule is weaker than being out of tree, so the commit guard and the tree-walk exclusions are load-bearing. A forced `git clean -x` would delete the folder; agents are denied it.
- The resolver family gains the XDG data and state base directories, which no tracked file read before this record. Each is parameterized by its standard variable and by the platform's override seam. This record makes no claim that a sandboxed install already isolates the per-user homes: today's sandboxes isolate through the config-root override and the workspace root, which set neither base. The two build obligations that follow carry that isolation, and their owners are the resolver slice and the epic's fourth wave, which provisions every home (§ References).
- **Build obligation — sandbox parity.** Every entry point that sandboxes through the config-root override or the workspace root also isolates both XDG bases — either the harness sets them, or the per-user homes derive from the config-root override when it is set — and the sandbox test asserts that no planned write reaches the real per-user homes.
- **Build obligation — a loud failure on an empty home.** On an install with a configured operator configuration, a leak-risk home that is absent, or that holds no scan entry, fails loudly at session start or at the deploy check, not only at a cutover.
- A move to another machine, or a restore of the workspace from backup, now requires copying the per-user homes beside the per-user config root: the workspace alone no longer carries the leak-risk content, and the loud-failure obligation is what keeps an empty home from passing silently.
- Layering input 2 moves three surfaces that later waves already change: the path-leak needle gains the leak-risk container's leaf, the installer provisions the per-user folders at their modes, and the migration of leak-risk content targets the XDG data home.
- Placement statements across the governance surfaces read as target wording until each repository's cutover, and each keeps today's resolving path beside it.

**Neutral.**

- Nothing moves in the release that ships this record, and no runtime write path changes; the switch keeps today's homes.
- The isolation-key question ADR-141 deferred is retired for working state and stays deferred for the leak-risk class. Per-repository homes separate one target's working state from another's by construction, but the leak-risk home is per-user, so two targets' embargoed runs would share it with no target segment; whether that home takes one is the resolver slice's question.

## Reversibility

**EXPENSIVE · confidence MEDIUM.** The release that ships this record moves no data, so before ratification it reverts cleanly. Once ratified it changes only by a superseding record, and every later wave builds against it; each cutover that executes it is reversible during its dual-read window and is gated by its own rehearsal.

## Related ADRs

- ADR-141 — superseded whole. Its `status:` transition lands with this record's ratification; the clauses of it that still bind are restated under § Decision → Carried forward from ADR-141.
- ADR-017 — superseded in part: Decision 4's workspace placement no longer holds for leak-risk content, which moves to the user's XDG data home, and its routing of event logs to XDG state no longer holds for the pipeline event log and the deploy warn logs, which are working state in each repository's `/local-state/`. Its routing of telemetry to the XDG state home is realized here, and its Decisions 1 to 3 bind unchanged, including one shared state per operator.
- ADR-032 — superseded in part: Decision 1's classification and home for the release corpus, Decisions 2 and 3, the Deferred-migration plan, and the operator-instance home in Decision 5 and the Bootstrap. The corpus's classification and location are this record's Release-corpus location item. Its classification of the release mechanism as public package, its HEAD-only removal rule, its template-public register rule and its canonical workspace-root resolver bind.
- ADR-046 — superseded in part: Decision 4's criterion that keeps runtime state in the operator-instance path family. Release and run state now has an in-repo git-ignored home, and placement is decided by risk class rather than by who writes the data. Its Decisions 1 to 3 bind unchanged: its shipped `/roadmaps/` folder is one of the enumerated in-repo homes, and working state adopts its tracked-folder, git-ignored-contents idiom.
- ADR-096 — superseded in part: the usage store's home is install-scoped working state in the user's XDG state home, and the store no longer admits a git-ignored path inside a repository. Its schema authority binds, and its resolve-time guard binds as the floor this record tightens; the leak-risk resolver's git-work-tree refusal is modelled on that guard but refuses an ignored path too.
- ADR-167 — composed: the shared warn-log sink keeps its single, check-discriminated form and is re-homed through the resolver at cutover. An in-repo ignored home is still not repo-derivable, so its terminable-shakedown rule binds unchanged.
- ADR-178 — qualified: its "platform state container" reads as the working-state home the resolver returns. Its zero-writes-under-the-operations-tree containment holds.
- ADR-109 — applied by D4.
- ADR-045 — composed: the people roster remains the People surface's home and moves with the leak-risk class; the contract's per-type assignment is unchanged.

## References

- #8005 — the parent epic: the epic-level design D1 to D8, the container inventory, and the layering inputs from the operator review.
- #8016 — this record's work item.
- #7503 — the analysis-workspace reachability defect that D1's carve-out answers.
- #8019 — the worktree-sessions slice: changes the main-checkout rule and its hook together, and co-owns the parity check between the placement standard's register and the hook's static set.
- #8029 — the placement-checklist check in the epic's fourth wave, which provisions every home; co-owns that parity check.
- #8020 — the resolver slice: one resolver per class, the switch, the designated main checkout and the leak-risk isolation-key question; with the epic's fourth wave, owner of the sandbox-parity and loud-failure build obligations in § Consequences.
- #8032 — the migration slice for leak-risk content, whose target path Layering input 2 moves.
- #6627 — the corpus-home slice that records the Release-corpus location item.
