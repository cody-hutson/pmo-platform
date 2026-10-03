---
title: "ADR-215 — The skill-editor exemption list resolves at the instance tier, through one resolver"
status: Proposed
date: 2026-09-28
release: install-resolves-identically
deciders: "Workspace owner (operator) — the decision rendered at the release's Stage-5 Collective Review scope-lock, with the independent adversarial review's refinements taken; design by the Stage 5 Solutioning spoke (Principal Engineer persona); authored by the Stage 6 Engineering spoke"
tags: [hooks, gate-2, skill-editor, exemption-list, composition-surface, instance-tier, resolver, completeness-gate, fail-closed]
source_observations:
  - "The code consumers of the exemption list resolved three runtime locations. The installer writes, and the deploy-side checks read, the instance tier the manifest registers. The Gate 2 hook and its writer read a copy beside the hook-tier allowlists. When the instance copy was absent, the deploy-side fallbacks read the checkout's own configuration directory."
  - "The writer-to-hook leg agreed before the change, because both addressed the hook-tier copy. The legs that disagreed were installer-to-hook and writer-to-deploy-checks. The end-to-end arm therefore drives the writer at the manifest-resolved path."
  - "update.sh's completeness gate keyed on the hook tier. An absent instance-tier list, the escape half of Gate 2, was reported as INFO and never stopped an update."
  - "The adversarial review found that a reconcile placed inside the managed-section phase would retire the copy the still-deployed pre-change hook reads, under --surfaces-only or after a declined hook refresh. Its remedy would also have named a writer that refuses the new path. The reconcile moved to its own phase after the hook refresh."
  - "The same review found that every Gate 2 arm ran with the workspace root exported, so no arm exercised the location branch production takes. An arm in the deployed shape, with the environment unset, now exercises it. Cutting one level from the hook's root derivation turns that arm red."
  - "One resolver function is not one resolved path. The deploy-side readers root at the ambient default. A PMO_INSTANCE_PATH exported to the install shell but not to the Claude Code process splits the writer from the hook."
supersedes: none
---

# ADR-215 — The skill-editor exemption list resolves at the instance tier, through one resolver

## Status

**Proposed** — authored at Stage 6 Engineering of `install-resolves-identically`. The operator rendered the decision at the release's Stage-5 Collective Review scope-lock: the instance tier through one resolver, the gate predicate declared beside that resolver, and the legacy reconcile ordered after the hook refresh. The transition to Accepted belongs to the release's close.

**Numbering provenance.** This record was claimed as **208** against an anchor of **206** on `origin/main`, read from the repository's ADR-numbering detector. It advances past one slot, which a sibling record on this same release branch already occupies. Sibling release branches hold numbers in the same range branch-only, which does not bind. This is the second of the release's three records, numbered in serial order at authorship. The number binds at the Stage-12 claim. If the mainline claims it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations use the slug token `ADR-215`, which carries no number shape and resolves at the claim.

**Numbering provenance — `208 → 212`.** Held **ADR-208** branch-local; renumbered to **ADR-212** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 208. In-release citations that read "ADR-208" denote this record.

**Numbering provenance — `212 → 215`.** Held **ADR-212** branch-local; renumbered to **ADR-215** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 212. In-release citations that read "ADR-212" denote this record.

## Context

The skill-editor exemption list is the escape half of the Gate 2 skill-edit hook. A skill it names may be edited directly; every other migrated skill must go through the governed editor.

The consumers did not agree on where the list lives:
- The composition manifest registers the list at the `instance` tier, and the installer writes it there.
- The hook and its writer, `allowlist-add.sh`, read and wrote a copy beside the hook-tier allowlists.
- The deploy-side readers read the instance tier. When it was absent, they fell back to the checkout's own configuration directory, which is a third location.

As a result, the list the installer seeds was not the list the hook read. An exemption added through the writer was invisible to the deploy-side checks, and no single file was the list.

Two further facts shaped the decision:
- **The gate keyed on the tier.** The update's completeness gate stops an update when a hook-tier surface is absent, because each such surface is the escape half of a security control. Keyed on the tier, the gate only reported this list, the one escape surface homed at the instance tier, and never stopped on it.
- **The entries live in two places.** Every install since the instance tier existed carries the instance copy. Every exemption that ever worked at the hook lives in the hook-tier copy. A change of location must carry the operator's entries across without writing policy on their behalf.

## Decision

The list lives at the tier the manifest registers. Every consumer resolves it through one resolver pair in `core/deploy/lib-instance-path.sh`:
- `pmo_skill_editor_exemption_list`, from the ambient root;
- `pmo_skill_editor_exemption_list_for`, from an explicit workspace root.

The library's exemption-surface resolution contract states once who resolves the list, and from which root. This record carries the decision and its rejected alternatives and does not restate that table.

The decision has five parts:

1. **One location, one resolver, no fallback.** No consumer spells the path. The deploy-side readers lose their checkout fallback, because a first-existing-wins ladder is how the divergence stayed hidden.
2. **The hook and the writer root the way a deployed hook is rooted.** They use `CLAUDE_WORKSPACE_ROOT` when it is set. Otherwise they use the workspace the script is deployed into, two levels above its own directory. The writer compares the resolved path physically, the same way it compares its argument.
3. **Resolve in isolation, fail toward enforcement.** The hook and the writer source the resolver inside a command substitution and use only its output. A resolver that is absent, stale or corrupt, including one that exits early, yields an empty path. The hook then grants no exemption and logs that it could not resolve. The writer does not admit the list as a target.
4. **Declare the hook-read set beside the resolver.** `pmo_hook_read_instance_files_for` names the instance-tier files a deployed security hook reads. Today its only member is the exemption list. The completeness gate stops on an absent surface whose tier is `hook` or which is a member of that set. The CI hook layout and the Linux install leg materialize the same set. No consumer names the list itself, so a new member is added in one place.
5. **Retire the legacy copy only after its reader has switched, and only when nothing is lost.** In its own phase after the hook refresh, a full update moves the hook-tier copy to a backup. It does so only when every entry is already an exact line of the instance-tier list. The deployed Gate 2 hook must also be byte-identical to source, and its co-deployed resolver present.
   - A copy that carries more is kept. Each extra entry is named with the writer command that re-adds it.
   - `--surfaces-only` refreshes no hook, so it never runs the reconcile.
   - The phase writes no policy.

## Alternatives Considered

- **Re-tier the row to the hook tier.** This is the strongest losing option, and the opposing view this record carries. The hook and the writer already read that location, and none of the tier-keyed consumers (the gate, the CI layout, the Linux leg) would have needed a change.
  - Rejected for the upgrade break. No install carries the hook-tier file the manifest would then name. The gate would stop the next update of every existing install until the installer was re-run. The alternative was for `update.sh` to start creating absent targets, which reverses its documented contract.
  - A tier move also has the install-wide reach the composition-surface spec treats as breaking.
- **A new hook-side resolver library.** Rejected under extend-before-create. `lib-instance-path.sh` is already the single operator-instance resolution site and is already co-deployed beside the hooks. A second library would either re-spell the instance location or source the first one anyway.
- **A read ladder in every consumer, canonical first with a fallback.** Rejected. The requirement is one path, and a first-existing-wins ladder is how two live copies went unnoticed.
- **A manifest field that declares each surface's readers.** Not adopted here. It is the right long-term class control, but a manifest-format change belongs to the work item that owns the write-target/read-path invariant for every row. The declared set is its point form and retires into it.
- **Gate every instance-tier row.** Rejected. The gate would then stop updates on instance-tier surfaces whose absence no hook reads. That reverses the gate's deliberate scope for no hook-safety reason.
- **The ambient root for the hook.** Rejected. Its fallback reads the wrong root on an install made with an explicit workspace root, because such an install exports no root. The scope guard's root was rejected as well: the hook harness sets it to the filesystem root.
- **Source the resolver in-process.** Rejected. A library that exits early would end the hook with status 0 at the exemption site, which is an allow.
- **Auto-merge a legacy copy's extra entries into the instance-tier list.** Rejected, because it writes policy on the operator's behalf. Re-adding an entry goes through the governed writer, whose additions are logged.
- **Reconcile inside the managed-section phase.** Rejected at the scope-lock. That phase also runs under `--surfaces-only`, and it runs before the hook refresh. It could therefore retire the copy the still-deployed pre-change hook reads. Its remedy would also name a writer that refuses the new path.

## Consequences

- **+** On the default root, or a root exported as `CLAUDE_WORKSPACE_ROOT`, the installer, the update, the writer, the hook and the deploy-side checks read and write one file.
- **+** An absent exemption list now stops an update before the hook refresh, as the absence of any other escape surface of a security hook already did.
- **+** A missing or broken resolver cannot open the gate. The hook grants no exemption, and it says why.
- **+** The CI hook layout carries the list at the path its own hook resolves. An arm in the deployed shape, with the environment unset, proves the location branch production takes.
- **−** One resolver is not yet one resolved path everywhere. Two residuals remain, and both fail toward enforcement:
  - The deploy-side readers root at the ambient default. On an install whose workspace root is neither the default nor exported, they read a different copy than the hook does.
  - A `PMO_INSTANCE_PATH` exported to the shell that runs install and update, but not to the Claude Code process, splits the writer from the hook in the same way.
  - Both are routed to the hook-root follow-up, not solved here.
- **−** The hook's other reads, the skill file and the editor sentinel, still root at `CLAUDE_WORKSPACE_ROOT`, else the home-directory default. That root does not locate itself. The defect predates this record and is routed separately under ADR-204.
- **−** A legacy copy with extra entries stays until the operator re-adds them through the writer. Until then, every update names them.
- **−** The reconcile phase and its tests are transitional. They retire once no install carries a hook-tier copy.

## Reversibility

CHEAP — revert the change. No operator data is rewritten: the instance-tier list is untouched. A retired legacy copy sits byte-for-byte in the pre-update backup directory, and it can be restored from there to its place beside the hook-tier allowlists.

## Related ADRs

- ADR-017 — the distribution architecture that places operator-instance state under the workspace root, which the resolver's default base follows.
- ADR-032 — the canonicalization on `CLAUDE_WORKSPACE_ROOT` rather than `PMO_INSTANCE_PATH`, and the rule to invent no new variable.
- ADR-094 — extend-before-create: the existing resolver library is extended rather than a new one created.
- ADR-181 — citation binding: this record is cited by its slug token until the claim binds its number.
- ADR-204 — the workspace-root order the hook and the writer bind, and the separate route for the hook's own non-self-locating root.
- ADR-214 — this release's first record. It shares `update.sh`'s Phase-3 loop with this record's gate predicate, and neither edit reverts the other.

## References

- #5274 — the defect (the exemption list resolves to different files for the installer, the hook, the writer and the deploy-side checks) and its acceptance criteria: one path, a writer-to-hook end-to-end arm, a gate that covers the list, and a lossless migration.
- #7760 — the Stage 5 design this record is drawn from.
- #7864 — the adversarial review. Its findings moved the reconcile after the hook refresh, added the deployed-shape arm and recorded the two residuals.
- #7684 — the release's planning sub-task, which carries the Collective Review's Decision Recorded.
- #5633 — the class control that owns the write-target/read-path invariant for every manifest row; the declared set retires into it.
- #6896 — the hook-suite layout helper. The CI layout's copy of the list is written through its recorded footprint.
