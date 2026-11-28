---
title: "ADR-243 — One resolver per class, behind a per-repository switch read through the config root, with a repository's main checkout designated by name"
status: Proposed — authored at Stage 6 for the one-resolver-and-release-tool-routing release; ratified at its Stage 13 close
date: 2026-11-28
release: one-resolver-and-release-tool-routing
deciders: "Workspace owner (Collective Review rulings) + Stage 5 Solutioning spoke (design) + independent adversarial design review + Stage 6 Engineering spoke (authorship)"
tags: [architecture, placement, resolver, switch, designation, run-class, leak-risk, sandbox-parity, fail-closed]
supersedes: none
source_observations:
  - "Three release tools resolved hub state through three different override cascades: one honored a direct variable, an operator.toml key, the container relocation and a four-step workspace-root ladder; one the same less a rung; one a different direct variable and no container relocation at all."
  - "The event-log resolver's reader and its writer once diverged through a cascade mismatch, and an integrity check read the resulting absence as a benign fresh-install state rather than as a broken control."
  - "The shell idioms local x=\"$(…)\" and \"$(…)/leaf\" swallow a resolver's failure status, and two deploy-time readers of the event-log path used them."
---

# ADR-243 — One resolver per class, behind a per-repository switch read through the config root, with a repository's main checkout designated by name

## Status

Proposed. Authored at Stage 6 of the `one-resolver-and-release-tool-routing` release from its Stage 5 design as the Collective Review ruled it. Ratification is the operator's, at that release's Stage 13 close; it is never inferred from milestone closure.

**Numbering provenance.** This record was authored at the next-free number computed from the mainline anchor. An ADR number is allocated at authorship but claimed at merge; should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop.

This decision is extended or reversed only by a successor ADR, never by an in-place edit of this record.

## Context

- ADR-231 homes every kind of non-tracked data by its risk class and leaves four parameters to the resolver slice: how the per-repository switch is carried, how a repository's main checkout is designated, how a run's class reaches the resolver, and whether the leak-risk home takes a per-target isolation key. Five later slices — consumer routing, home provisioning, the migration dual-read, the leak-risk migration and external targets — bind to the answer, so leaving it in a design comment would have them re-argue it.
- The release tools that read and write hub state, the pipeline event log and the close-out registers each composed their own path, through override cascades that differ. One resolver cannot reproduce all three under overrides, and ADR-231's carried-forward clause 2 keeps every override at its current precedence until its class's cutover.
- The platform's sandboxes isolate an install by pointing `PMO_PLATFORM_CONFIG_ROOT` at a scratch folder and leave `HOME` real; ADR-231 obliges every such entry point to isolate both XDG bases as well.
- The event-log path is read by integrity checks that must never mistake a refused path for an absent log (`source_observations`).

## Decision

1. **Switch: carrier and grammar.** The switch is `operator.toml [adapters] governed_homes`, an opt-in string of comma-separated repository names. Each entry is trimmed, empty entries are dropped, and every entry must match `^[A-Za-z0-9][A-Za-z0-9._-]*$`; any other entry fails every resolution that reads a non-empty switch, so a value can never compose a path outside the workspace root. A TOML array is not read. An absent, empty or blank value is off for every repository, which is the shipped state; each repository's entry is added by that repository's cutover change, after its homes exist and its data is copied. Names, not paths, because no platform file stores a target's path or layout.
2. **Read through the config root, split by arm.** The switch is always read through `${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/operator.toml`. The today arm keeps reading every key through `$HOME`, unchanged, so every switch-off answer is byte-identical. Once the switch reads non-empty, every further key read goes through the config root too: the designation inputs and each member's direct-override keys. A governed per-user resolution refuses when `PMO_PLATFORM_CONFIG_ROOT` is set and the matching XDG base (`XDG_DATA_HOME` for leak-risk and embargoed results, `XDG_STATE_HOME` for install-scoped ones) is unset, empty or not absolute — the resolver's half of ADR-231's sandbox-parity obligation. A governed working-state no-argument resolution refuses when `PMO_PLATFORM_CONFIG_ROOT` is set and the designation's workspace root would come from the `$HOME/Claude` fallback.
3. **The designated-main-checkout rule.** A listed repository's designated checkout is `<workspace-root>/<name>`. The context clone's main worktree M (the first entry of its worktree list, made physical) is designated when its basename is listed and `<workspace-root>/<basename>` is M. Otherwise each listed entry is tried in listed order, and the first confirmed one wins: origins that match after normalization confirm it; for the entry that shares M's basename, differing or missing origins fall back to history — a shallow clone or any git error refuses, intersecting root-commit sets confirm a fork-workflow clone, disjoint sets mean another repository. The designated checkout must be its own clone's main worktree. A listed entry is read only when this rule uses it, so a broken entry for another repository never fails an unrelated context. Every git probe runs with the repository-discovery environment cleared.
4. **Run class.** Release runs take `--run-class working-state|leak-risk`, defaulting to working state; the value space is the placement standard's own class vocabulary. `leak-risk` resolves the embargoed home in either switch state and applies to the run-scoped members alone. How a run's class is recorded is a reserved contract the leak-risk migration implements: `pmo_run_class_for <run-key> --repo <checkout>` answers `leak-risk` exactly when the leak-risk record `$LR/embargoed/.runs/<run-key>` exists and `working-state` exactly when only the run's working-state folder exists, and refuses when neither record exists or both do. The record is keyed on the run key alone and written once by the hub's start-of-run step, and the config-root sandbox refusal of item 2 applies to its leak-risk probe. An absent record is never read as working state.
5. **Leak-risk isolation key.** The leak-risk home takes a per-target segment: an embargoed run resolves `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/embargoed/<repository>/<release-runs|event-log|registers>`, mirroring that repository's own `/local-state/` subfolders, so disclosure moves one folder per subfolder.
6. **Overrides on the governed arm.** Each member has one direct-override set, the union of its forms, read through the config root, so every form of a member returns the same governed path. A family-wide relocation that the member's today arm honors (`PMO_INSTANCE_PATH`; `WORKSPACE_ROOT` for the no-argument event-log form) is refused on the governed arm and on the embargoed arm, naming the variable, rather than silently dropped; each class's cutover may relax this when it states how the relocation maps onto its homes.
7. **Run-scoped members name their repository.** `release-runs`, `event-log` and `registers` called with no `--repo` refuse once the switch is non-empty, and always under `--home governed` or `--run-class leak-risk`. With the switch empty nothing changes and no git process runs.
8. **Reaching an arm the switch does not select.** `--home today|governed` returns the named arm, so provisioning and the migration dual-read reach the governed arm while the switch is off without reopening the interface.
9. **Failure contract.** Exit 2 is usage and exit 3 a refusal; on either, stdout is empty and stderr carries exactly one line beginning `lib-instance-path: `. Every function is pure and creates nothing. A consumer captures the value and checks the status at the assignment its own script makes at top level; a check only inside a function the script calls through command substitution is not enough. `local x="$(…)"` and `"$(…)/leaf"` are banned at every call site. The two deploy-time readers of the event-log path print a distinct `UNRESOLVED` verdict on a refusal, which every caller's fail-closed arm already takes, rather than reusing a verdict whose remedy text points elsewhere.
10. **The work-tree refusal is a filesystem walk.** A per-user result, or an embargoed one, is refused when a component of its path is `.git`, or when walking from its first existing ancestor, made physical, up to `/` finds a `.git` entry of any type (a dangling link included), a directory named `.git`, or a directory with git's own repository layout. No git process runs, so no git environment or configuration can make it answer "outside".
11. **A listed repository with no home fails loud.** When the designated checkout has no `local-state/` folder (or no `analysis/` folder, for that member), the governed working-state arm refuses rather than falling back to today's path. Per-user homes are not checked for absence here, because the installer resolves them in order to create them.
12. **Entry-gating invariant.** No repository's entry is added to the switch before its consumers check the resolver's status at their outermost assignment — the release tools, the two deploy-time event-log readers, the PII guard's unanchored needle read once that accessor becomes switch-aware, and the event-log integrity suite `core/deploy/tests/test_check19_event_log_integrity.sh` — and, for the platform repository's own entry, before the platform-flip card has carried out its target-checkout swap at every run-scoped call site, so an external target's run names that target rather than the platform's own checkout. The out-of-tree container is not retired until the PII guard's anchored floor has a decided leak-risk source (Consequences, the obligation below).

## Alternatives Considered

**Switch carrier.**

| Candidate | Mechanism | Verdict |
|---|---|---|
| A | the repository's shipped `/local-state/` home is the switch (present means on) | rejected: it flips every install at the merge that ships the home, before the install has copied and verified |
| B | a per-clone git config key | rejected: not declarable in the template and schema, and per clone rather than per repository |
| C | a marker file inside the repository's ignored `/local-state/` | rejected: not declarable, and an agent-writable escape hatch over its own subject |
| D | an environment variable | rejected: invents a new variable, is not declarable, and does not survive across tool calls or sessions |
| E | one per-install `operator.toml` key whose value lists repositories | **chosen** |
| F | per-repository named subtables | rejected: the schema declares fixed keys per section, and the section-blind key reader would read another section's key |
| G | a new per-user configuration file | rejected: the configuration contract names the template and its schema |

**Switch value space.** Repository names (chosen); absolute paths of designated checkouts (rejected: storing a target's path, and a machine move breaks every entry); origin slugs (rejected: a repository with no remote could not be listed); names or paths mixed (rejected: the path case).

**How a tool learns a run's class.** An environment variable exported at run start (rejected: a new variable that does not persist across calls); the hub passing the argument to every invocation for the run's life (rejected as the carrier: one omission silently homes leak-risk state as working state); inferring the class from the repository context (rejected: it replaces the hub's classification); location as record, where the class is `leak-risk` exactly when the run's embargoed folder exists (considered, then rejected at Collective Review: an absent folder reads as working state, so every way of failing to find it — a different XDG base, a deleted folder, another checkout's key — is fail-open); a positive record per class, keyed on the run key alone, refusing when neither or both exist (**chosen**, item 4).

**How the switch-off arm reproduces each consumer's cascade.** Named per-tool cascade profiles inside the resolver (rejected: the shared kernel would become a registry of its consumers); the resolver holds the resolver-level rungs and each consumer keeps its own, with one residual expressed by the caller unsetting a variable for one call (**chosen**); the same with an extra option instead of caller-side scoping (rejected: an option one caller uses that the cutover must remove); converging every tool onto the widest ladder now (rejected: carried-forward clause 2); tools building today's path and calling the resolver only when the switch is on (rejected: one site must spell each home).

**Reading configuration under a sandboxed config root.** (A) the switch key alone through the config root (rejected at Collective Review: the governed arm it turns on would still read its overrides and the workspace root from the real `HOME`, so a config-root sandbox would reach the live homes); (B) every key through the config root now (rejected: a recorded switch-off behavior change); (C) the switch through `HOME` like every other key (rejected: a sandbox that sets only the config root would read the operator's real switch); (D) split by arm, with the sandbox refusals (**chosen**, item 2).

**Family-wide relocations under the governed arm.** Dropping them silently (rejected: a self-test that isolates a real writer with `PMO_INSTANCE_PATH` would write live state after a flip); refusing them until the class's cutover states the mapping (**chosen**, item 6).

**A run-scoped call with no repository.** Defaulting to the platform context (rejected: once the platform's entry is set, an external target's run state would land in the platform's home); requiring the repository once the switch is non-empty (**chosen**, item 7).

**The work-tree test.** Asking git whether the path is inside a work tree (rejected: git's ceiling, ownership and filesystem-boundary settings make it answer "not a repository", which reads as outside — a fail-open); a filesystem walk that asks git nothing (**chosen**, item 10).

**The refused-path verdict.** Reusing the "asserted set absent" verdict (rejected: its remedy text points an operator at restoring an allowlist file, and under warn-mode it maps to a different exit); a distinct `UNRESOLVED` verdict on the existing fail-closed arms (**chosen**, item 9).

## Consequences

**Positive.**

- One site spells each home. A repository's cutover becomes one value added to one key instead of an edit to every tool.
- With the switch off, every consumer resolves exactly today's path, by today's rungs, with no git process run.
- The event log's writer and readers follow the switch together through one function, so they cannot resolve to different places across it.

**Negative, accepted.**

- The switch and the governed arm read the config root while the today arm reads `HOME`, until each class's cutover converges its members' reads.
- The platform's own release tools name their own checkout as the run's repository, which is wrong for an external target's run until the platform-flip card's target-checkout swap lands (item 12).
- Two workspace roots can split designation between callers that pass `WORKSPACE_ROOT` and callers that read `CLAUDE_WORKSPACE_ROOT`, until the platform cutover states that mapping.

**Obligation, owner the leak-risk migration card.** The PII guard's anchored read pins `HOME` to `/var/empty` and clears the class resolvers' inputs, so it stays a function of the guard's install geometry and cannot be moved by a prefix on the commit. The anchored floor therefore stays workspace-keyed when the leak-risk class moves to its per-user home. Before the out-of-tree container is retired (item 12), that card states how the anchored floor reaches the user-keyed home without reading the committer's environment. The option space is narrow: the one environment-independent route is the account database's home for the effective user, gated on the canonical install geometry so a sandboxed copy still anchors in its sandbox — and that route cannot honor a custom `XDG_DATA_HOME`, a residual the card records.

## Reversibility

CHEAP (HIGH confidence) while no repository is listed: the key is opt-in, nothing writes it, and a revert restores every surface. MODERATE once later waves build against the contract, because their consumers would need to be re-pointed.

## Related ADRs

- ADR-231 — composed. This record fixes the parameters ADR-231's D1, D2 and D5 and its Consequences delegate to the resolver slice, and supersedes nothing in it.
- ADR-032 — "invent no new variable", applied: the switch is a key in an existing configuration surface, not a new variable.
- ADR-109 — target-side facts are read, not stored: the switch stores names, and a target's checkout is found at run time.
- ADR-096 — the resolve-time guard, of which the filesystem-walk refusal is a stricter descendant.
- ADR-181 — the slug-token citation form other surfaces use to cite this record before its number binds.

## References

- #8005 — the parent epic and its wave order.
- #8020 — the resolver slice this record decides.
- #8021 — the release-tool routing that consumes this contract.
- #8025 — consumer routing, which converts the remaining per-member functions.
- #8027 — home provisioning, which reaches the governed arm through `--home governed`.
- #8030 — the migration dual-read.
- #8032 — the leak-risk migration and the run-class helper, owner of the anchored-floor obligation.
- #8034 — the platform-flip card, owner of the target-checkout swap.
- #8037 — external targets.
