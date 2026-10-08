---
title: "ADR-216 — Evicting an auto-memory entry is not an outside-workspace deletion"
status: Accepted — operator-ratified at the install-resolves-identically Stage 13 Close ratification beat, 2026-10-04
date: 2026-10-02
release: install-resolves-identically
deciders: "Workspace owner (operator) — the decision rendered at the release's Stage-5 Collective Review scope-lock, with the independent adversarial review's admission log and scope refusal taken; design by the Stage 5 Solutioning spoke (Principal Engineer persona); authored by the Stage 6 Engineering spoke"
tags: [hooks, block-rm-prefer-trash, autonomy-tiers, irreducible-human-tasks, tier-0, memory-architecture, encode-and-evict, security-control-scope, admission-log, fail-closed]
source_observations:
  - "The corpus disagreed with itself about who may remove an auto-memory entry. The cross-surface memory contract classed eviction as Tier 1, while the Irreducible Human Tasks list made any Trash target outside the workspace root a Tier-0 act, enforced by the deletion-containment hook."
  - "The Tier-0 item's stated rationale cited only its own enforcement, so it never said why the act is irreducible. Against the Tier-0 observable indicators, a Trash move of one memory entry is reversible, affects only the operator, is not governance state, and is not a Prohibited Action."
  - "Because the procedure mandated an act the control forbade, executors improvised: entries were rewritten to empty 'safe to delete manually' stubs that stayed on disk, orphaned from the index."
  - "The runtime reads the store's location from any settings scope, repository-supplied ones included. The control therefore reads the operator's user-scope settings only, the file its own hook wiring lives in."
  - "The adversarial review found that a widened outside-root admission would leave no trace, and that an operator whose store is declared outside user scope would meet the same generic refusal as before, with no sign of why. The scope-lock took both remedies: an admission row, and a memory-specific refusal."
  - "Stage 6 narrowed the drafted predicate in the fail-closed direction, so that the path the hook classifies is the path the command removes, while the operand's directories are unchanged between judgment and execution. The operand must be written only in characters the shell passes through unchanged; only its parent is resolved; and its leaf must be a regular file, not a symbolic link."
supersedes: none
---

# ADR-216 — Evicting an auto-memory entry is not an outside-workspace deletion

## Status

**Accepted** — operator-ratified at the `install-resolves-identically` Stage 13 Close ratification beat (Phase A13), 2026-10-04, as one record of a decision rendered per record. Authored at Stage 6 Engineering of that release as `Proposed`. The operator rendered the decision at the release's Stage-5 Collective Review scope-lock: a Trash-only arm with a Tier-0 re-scope, together with an admission row and a memory-specific refusal. The ratification is recorded in this file's frontmatter `status:` field. The decision this record documents shipped in **v4.73**.

**Numbering provenance.** This record was claimed as **209** against an anchor of **206** on `origin/main`, read from the repository's ADR-numbering detector. It advances past two slots, which the release's two earlier records on this same branch already occupy. Sibling release branches hold numbers in the same range branch-only, which does not bind. This is the third of the release's three records, numbered in serial order at authorship. The number binds at the Stage-12 claim. If the mainline claims it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations use the slug token `ADR-216`, which carries no number shape and resolves at the claim.

**Numbering provenance — `209 → 213`.** Held **ADR-209** branch-local; renumbered to **ADR-213** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 209. In-release citations that read "ADR-209" denote this record.

**Numbering provenance — `213 → 216`.** Held **ADR-213** branch-local; renumbered to **ADR-216** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 213. In-release citations that read "ADR-213" denote this record.

## Context

The encode-and-evict lifecycle requires that a memory entry be moved to Trash once its content is encoded in the corpus. The deletion-containment hook refused every Trash target outside the workspace root, and the auto-memory store lives there. Tier-0 item 8 of the Irreducible Human Tasks recorded that refusal as permanent. The cross-surface memory contract, meanwhile, classed eviction as Tier 1. Both statements were in force, so the mandated act could not be performed without a hook bypass, and executors left inert stubs in its place.

Three further facts shaped the decision:
- **The store's location belongs to the runtime.** It is the `autoMemoryDirectory` setting, which the runtime reads from every settings scope, the repository-supplied project and local scopes included. A deletion control that honoured those scopes could be aimed by a cloned repository.
- **An admission outside the root is a new hole in a containment boundary.** The hook's other allow paths record nothing, but an allow inside the workspace and an allow across its boundary do not carry the same stakes.
- **An operand is judged as written, and removed as the shell reads it.** A predicate that resolves the whole operand, or that accepts characters the shell transforms, can judge one path while the command removes another.

## Decision

1. **Item 8 is re-scoped.** A Trash move of one auto-memory entry leaves item 8's set as item 8a, at Tier 1. Every other outside-root target, and every permanent-deletion verb, stays at Tier 0 permanently.
2. **The hook admits exactly that act and nothing wider.** It admits a Trash-verb move of one direct `*.md` entry of the declared store, and never the `MEMORY.md` index or a directory. The operand must be written in characters the shell passes through unchanged, as an absolute path, bare or wholly quoted, with no `..` component. Its leaf must be an existing regular file and not a symbolic link, and its resolved parent must be the resolved store. The predicate judges the operand before it opens any settings file, and admits only on an explicit success token, so every failure refuses. The act it admits is the act the command performs while the operand's directories are unchanged between judgment and execution.
3. **The store's location is read from the operator's user-scope settings only**, with no environment override. Project and local settings never admit. They are read only to word a refusal: an entry whose store is declared there is refused with a message that says so, rather than with the generic cancel text.
4. **Every admission leaves one row.** Once every operand of a command has been judged, each admission appends one compact row to the hook's block log, carrying the command's digest and never its text or the entry's path. A command refused as a whole leaves no row, and an admission whose row cannot be written is refused.
5. **The mechanism is stated once**, in the memory↔corpus boundary's EVICT phase. This record, item 8a and the hook's registry entry cite it and do not restate it.

## The permanence claim this narrows, and how it is reconciled

Tier-0 permanence attaches to a correctly-scoped item. Item 8 covered every deletion outside the workspace root, but its purpose never reached a recoverable move of a governed store's own entry. That purpose is to protect files the platform does not govern and whose loss it cannot assess. Re-scoping an item drafted more broadly than its rationale supports is the path the Autonomy Tier specification itself names, with item 7 as its worked example: a visible, reviewed, evidence-bearing act, recorded here. Lowering a correctly-scoped item stays unavailable.

## Alternatives Considered

- **Keep item 8 absolute, and evict through the operator handoff with no hook change.** This is the strongest losing option, and the opposing view this record carries. It adds no surface to a security-containment hook: no settings file becomes load-bearing for a deletion control, no admission needs auditing, and no scope can go silently inert. Rejected because it leaves the guard keyed on invocation context rather than on the governed subject, which is the defect this release exists to remove, and because it costs the operator a terminal step on every eviction.
- **A dedicated eviction script.** Rejected under extend-before-create: deciding a Trash-verb deletion is this hook's own job. A separate script would also be an allowlisted channel for an act the hook refuses, and it would still need the re-scope.
- **A platform-config key for the store.** Rejected: a second copy of the store's location, beside the runtime's own setting.
- **Relocate the store inside the workspace.** Rejected for its blast radius: a live migration of the operator's store, and a store the corpus names in several surfaces.
- **Formalize the stub.** Rejected: it has the handoff's governance posture, and it leaves an inert file the index no longer describes.
- **Move the entry into the workspace, then Trash it there.** Rejected: it routes around the control through a verb the control does not gate.
- **Ship the arm and leave item 8 as written.** Rejected: the canonical tier specification would then claim a block the hook no longer performs, recreating at the governance layer the unreconciled pair of predicates this release removes.

## Consequences

- **+** Eviction completes without a bypass, and the cause of the stubs is removed. The Trash-recoverability the lifecycle promises holds end to end.
- **+** Each admission is reviewable after the fact from the hook's block log. An admission that cannot be recorded does not happen.
- **+** An operator whose store is declared outside user scope is told why the arm does not apply, instead of meeting the generic refusal.
- **−** The integrity of the user-scope settings file becomes load-bearing for a deletion control. An agent that could write that file mid-session could re-aim the arm. The damage is bounded by the predicate: Trash only, one directory level, `.md` files only, and only a store that holds an index. It is also dominated by what such a writer can already do, which is to unwire every guard.
- **−** An operator whose setting lives in project or local scope gets no arm, and evicts through the handoff. The runtime's default per-project store is not admitted either.
- **−** The arm admits no operand that carries a character outside the admitted set, so it cannot evict an entry whose name carries one, nor any entry of a store whose own path carries one. Such an operand meets a generic `BLOCK-TRASH-003` refusal, not the memory-specific one, and the eviction goes through the handoff.
- **−** The verdict is reached once, when the hook judges the operand, and the command resolves the operand again when it runs. The path judged is the path moved only while the operand's directories are unchanged between the two: the judgment-time class every path-resolving rule in the hook registry carries, and not a property of the operand's spelling.
- **−** The drift audit keeps a second, hardcoded resolver of the store until it adopts the same resolution.
- **−** The lifecycle still has no read-back of its own after an eviction. That residual is named and out of scope.

## Reversibility

MODERATE — revert the change, then republish the hook bundle, since the deployed hook is what fires. Item 8a reverts with it. Evictions already made stay recoverable from the Trash until it is emptied. Once this record is numbered and merged it is never deleted; it is superseded or deprecated instead, because the ADR-number sequence is gap-free.

## Related ADRs

- ADR-029 — the memory↔corpus SSOT boundary, which places the encode-and-evict lifecycle in the knowledge-architecture discipline.
- ADR-045 — the cross-surface memory contract, which classes eviction as Tier 1; item 8a makes the tier specification agree with it.
- ADR-030 — one registry fragment per hook, with a generated index; the predicate's full statement lives in this hook's fragment.
- ADR-149 — the re-scope precedent: a Tier-0 item drafted more broadly than its rationale is corrected by re-scoping it, with the reasoning recorded.
- ADR-205 — a hook record carries the command's digest and structure, never the command; the admission row follows the same floor.
- ADR-181 — citation binding: this record is cited by its slug token until the claim binds its number.

## References

- #6440 — the card this record resolves: memory eviction was structurally unexecutable, because the deletion-containment hook refused every target outside the workspace root.
- #7764 — the Stage 5 design this record is drawn from.
- #7866 — the adversarial review. Its findings added the admission row and the memory-specific refusal.
- #7684 — the release's planning sub-task, which carries the Collective Review's Decision Recorded.
- #5185 — the ARCHIVE destination for evicted entries, a disjoint phase of the same lifecycle, coordinated and independent.
