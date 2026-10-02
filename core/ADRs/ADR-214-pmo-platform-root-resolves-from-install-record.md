---
title: "ADR-214 — [PMO_PLATFORM_ROOT] resolves from the install record, never from the invoking checkout"
status: Proposed
date: 2026-09-28
release: install-resolves-identically
deciders: "Workspace owner (operator) — the decision rendered at the release's Stage-5 Collective Review scope-lock, with the independent adversarial review's refinements taken; design by the Stage 5 Solutioning spoke (Principal Engineer persona); authored by the Stage 6 Engineering spoke"
tags: [deploy, composition-surface, allowlist, worktree, install-record, resolution-ladder, fail-closed]
source_observations:
  - "A refresh run from a linked worktree baked that worktree's path into the deployed script allowlist, because the resolver's last tier was compose.py's own location; the deployed copy was later found pointing at a scratchpad worktree that no longer existed. The allowlist kept working only because its bare-relative rows still matched."
  - "The installer had written source_repo_path into the workspace's install state since the initial public release — raw, on full-install flows only — and nothing read it."
  - "At the design pin, 9 of 52 registered linked worktrees lived outside the repository (temporary scratchpads), all prunable: a check keyed on the .claude/worktrees path segment could not see the incident shape, so the linked-worktree test is git's own, not a path pattern."
  - "The design's suggested acceptance probe, a count of lines carrying the worktree segment, read 86 on a correct build and 86 on the scratchpad shape; a root-equality probe over the template's token rows read 0 missing on a correct build and every row missing on both worktree shapes."
  - "The adversarial review found that the legacy record, promoted above git, would let the one-time heal rewrite a working allowlist to the root of a different, still-existing clone; the decision records the resolver tier alongside the root and treats a record without it as advisory."
  - "The same review found that classifying a tree by work-tree membership refuses a platform tree unpacked inside an unrelated repository and silently re-roots one nested inside a platform checkout; classification is by identity with the work tree's top level."
supersedes: none
---

# ADR-214 — [PMO_PLATFORM_ROOT] resolves from the install record, never from the invoking checkout

## Status

**Proposed** — authored at Stage 6 Engineering of `install-resolves-identically`, after the operator rendered the decision at the release's Stage-5 Collective Review scope-lock (record-first resolution with a record-provenance key, and remedy texts that name the forced regeneration). The transition to Accepted belongs to the release's close.

**Numbering provenance.** Claimed as **207** against an anchor of **206** on `origin/main`, read from the repository's ADR-numbering detector rather than computed from the numbers visible on any branch; sibling release branches hold 207 through 210 branch-only, which does not bind. This is the first of the release's three records, numbered in serial order at authorship. The number binds at the Stage-12 claim; should the mainline claim it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. In-release prose cites this record by its slug token.

**Numbering provenance — `207 → 211`.** Held **ADR-207** branch-local; renumbered to **ADR-211** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 207. In-release citations that read "ADR-207" denote this record.

**Numbering provenance — `211 → 214`.** Held **ADR-211** branch-local; renumbered to **ADR-214** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 211. In-release citations that read "ADR-211" denote this record.

## Context

`[PMO_PLATFORM_ROOT]` anchors the absolute rows of the script-execution allowlist, a security control: its first two invocation forms admit a tool invoked by absolute path from the platform checkout or from any worktree under it. The value is substituted into bash `case` glob patterns. Its resolver ended at compose.py's own location, so any refresh run from a linked worktree persisted that worktree's path, and the persisted path outlived the worktree. A root baked to a worktree also stops the worktree-glob form from admitting invocations from the primary checkout and from every other worktree.

Three facts shaped the decision. The installer already persisted which checkout it was run from, in the workspace's install state, and nothing consumed it. A deploy legitimately runs from a worktree to ship that worktree's templates, so the checkout a run starts in cannot simply be refused — only its location must stop leaking into the value. And the value decides where trusted scripts live, so it must fail closed rather than fall back to whatever answer is nearest.

## Decision

The token resolves through five tiers, first valid tier wins: `cli` (the explicit flag), `env` (the environment override), `install-record` (the canonical root the installer recorded), `declared-source` (at install time, the checkout the installer runs with) and `main-worktree` (the main working tree of the repository the running compose.py belongs to); when no tier yields a valid root, resolution fails and so does the composing write. The normative ladder — the validation each tier applies, the refusal set, and the rule for records without provenance — is stated once, in `core/standards/depersonalization-spec.md` § 2; this record carries the decision and its rejected alternatives and does not restate that text.

The decision has five parts:

1. **Record-first.** The installer records the canonical root it composes with — the main working tree of the repository it was run from, never a linked worktree — together with `source_repo_path_source`, the tier that supplied it. A later update honors that record. A record without the provenance key is advisory: it is used only when the main-worktree tier cannot resolve or agrees with it; otherwise a warning names both roots and the main-worktree tier wins.
2. **The invoking checkout supplies templates only.** `update.sh` keeps its own location as the source of the templates, the manifest and the library, and resolves the token's value once per run, in pre-flight, passing it explicitly to every composition write.
3. **Canonicalize by identity, through git.** A tree is a checkout when it is its work tree's top level; a linked worktree maps to the first entry of git's worktree registry, a bare repository's worktree does not resolve, and a tree nested inside another work tree is its own tree. A tree outside any repository resolves only through the install record or as a declared source — never through self-location.
4. **Refuse what the glob patterns would misread.** Every tier refuses a linked worktree, a `.claude/worktrees` path segment, a glob metacharacter, a control character and, on POSIX, a backslash.
5. **Fail closed, and never leave the token behind.** Resolution runs only for a template that carries the token; an unresolvable root is an error (exit 3 from compose.py, 65 from `update.sh`, 66 from the installer, before any install step), and a writer that would emit the literal token refuses the write. Remedies name `./update.sh --force-regen`, because a surface is re-rendered only when its template changes.

## Alternatives Considered

- **A git-derived root only, with no record.** Rejected: the card requires an install record, and a tree that is not a git checkout could not resolve at all.
- **A delivered `operator.toml` `[paths]` key.** Rejected, and the strongest losing option: under the declared-schema coverage rule a delivered key is a one-way door, it reverses the depersonalization spec's "not operator.toml" for this token, and it puts the value that decides where trusted scripts live under manual edit.
- **The `<workspace-root>/pmo-platform` location convention.** Rejected: the repository may live anywhere, so a directory-name assumption resolves the wrong tree or none.
- **A shared bash and python root library that the hook layer also migrates to.** Rejected: a structural change to the Tier-0 membership helper for one deploy-time token, where a behavioural change suffices.
- **Git-first precedence.** Rejected: the value would follow whichever clone ran last, which is the caller-dependence this decision removes.
- **Honoring every recorded root, whoever wrote it.** Rejected at the scope-lock: a raw record written before this change could name another existing clone, and the release's own heal would then move a working allowlist onto it. The provenance key keeps record-first for every record written under this contract.
- **A standing root-drift regeneration trigger.** Not adopted at the scope-lock; the remedy texts name the forced regeneration instead. A general input-drift trigger would change the regeneration contract of every token-bearing surface, the workspace charter included.
- **Failing only the token-bearing surfaces instead of the whole update.** Not adopted: refreshing the hooks while their allowlist stays on a stale root was weighed against stopping, and the run stops.

## Consequences

- **+** The composed surfaces are identical apart from their `managed_at` markers whichever checkout or worktree a refresh runs from, and running an update from an arbitrary copy no longer bakes the copy's path.
- **+** One resolver, called once per run, whose value and tier are named in its output, passed explicitly to every write.
- **+** A pre-release install whose allowlist carries a worktree root heals on its first post-release update: this release changes the allowlist template, which re-renders it under the new resolver, with the pre-write backup.
- **−** A tree outside any repository with no install record now fails loud instead of resolving to itself.
- **−** Tiers 3 through 5 read the checkout through git, so a git-clone install whose checkout git cannot interrogate does not resolve, whatever its record says. git is a declared install prerequisite.
- **−** `update.sh` resolves in pre-flight and refuses the whole run when no tier yields a root, so token-free surfaces, skills, hooks and settings wait on that answer too.
- **−** A later move of the clone, or a re-recorded root, is not re-rendered by itself: the surfaces keep the old root until a template change or `./update.sh --force-regen`, which every remedy text names.

## Reversibility

CHEAP — revert the code and regenerate the surfaces from the primary checkout. A recorded canonical `source_repo_path` and its `source_repo_path_source` key are inert to the prior resolver, which reads neither.

## Related ADRs

- ADR-014 — the regeneration trigger (the template hash) that the heal rides and that explains why a changed root needs a forced regeneration.
- ADR-094 — extend-before-create: the existing install-state field is extended rather than a new record created.
- ADR-140 — the declared-schema coverage rule that makes an `operator.toml` key a one-way door.
- ADR-165 — the primary-versus-linked discriminator this resolver reuses.
- ADR-181 — citation binding: this record is cited by its slug token until the claim binds its number.
- ADR-192 — the allowlist's four-form convention, whose first two forms anchor on this root.

## References

- #5265 — the defect (a worktree-invoked update bakes the worktree's path into deployed surfaces) and its four acceptance criteria, the install record among them.
- #6168 — the co-discharged card: the composed allowlist is identical whichever checkout runs the refresh, and the refresh reports the root it bound.
- #7756 — the Stage 5 design this record is drawn from.
- #7862 — the adversarial review whose findings shaped the provenance key, identity classification and the refusal of a backslash.
- #7684 — the release's planning sub-task, which carries the Collective Review's Decision Recorded.
