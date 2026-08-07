<!-- reference-durability: allow-link -->
---
title: ADR-122 — CLAUDE.md is re-categorized from Customizable to Composition-surface
status: Accepted — ratified by the operator at the Stage 5 Collective Review scope-lock gate for the `96-update-install-config-safety` release, 2026-08-06. The flip is verified against this file's `status:` field, never inferred from milestone closure or a review comment.
date: 2026-08-07
release: 96-update-install-config-safety
deciders: "Workspace owner (ratified the scope and mechanism at the Stage 5 Collective Review scope-lock gate); mechanism designed at Stage 5 Solutioning, authored at Stage 6"
tags: [composition-surface, update-mechanism, category-contract, customizable, claude-md, durability, reversibility-expensive]
source_observations:
  - "core/CLAUDE.md.template shipped a markdown MANAGED SECTION fence from the initial public
     release until the v3.86 honest-doc fix removed it, on the stated ground that CLAUDE.md is
     absent from COMPOSITION_SURFACE_FILES — the only list update.sh's regen loop iterates — so
     the marker's SHA placeholders were never resolved and a template change never propagated."
  - "An installed workspace surveyed at authoring still carried that removed fence, with an
     unresolved managed_sha placeholder and no installed_sha marker; its managed body was an
     exact byte match to the token-substituted template five revisions behind the mainline."
  - "One of the tokens core/CLAUDE.md.template consumes is resolvable by the install-time
     substituter but not by the composition writer, and it has no persisted home in
     operator.toml — it is prompt-only at install and is never written there at all."
  - "The install-time token resolver derives its active token set by grepping the shipped
     templates, so the template's authoring header — which declares the reserved vocabulary —
     is load-bearing for the resolver rather than inert documentation."
---

# ADR-122 — CLAUDE.md is re-categorized from Customizable to Composition-surface

## Status

**Accepted** — ratified by the operator at the Stage 5 Collective Review scope-lock gate for the `96-update-install-config-safety` release, 2026-08-06. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. Acceptance is the Stage-5 → Stage-6 boundary condition on the Customizable-refresh work item and blocks no other card in the release. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering.** This record's number was derived at Engineering Commit 0 against the mainline anchor per ADR-115 §Decision (1) — next-free is `anchor(origin/main) + 1`, never `max(claimed_set) + 1`. The mainline held 119 at that moment, so the derivation yielded 120. It **bound** at **122**, two hops later; the derivation rule is unchanged and the moves are recorded in the two provenance notes below, which is where the number is verified.

**Numbering provenance — `119 → 120`.** Drafted at Stage 5 as **ADR-119**. A concurrent release claimed 119 on the mainline before this record was written to disk, so the rule-determined next-free advanced to 120. No file was ever created at 119 on this branch — the draft lived in the Stage-5 handoff comment — so nothing had to be moved or renamed. The move did **not** come free of a citation sweep, however, and the original claim that it did was wrong: the release plan had already been authored at Engineering Commit 0 against the drafted numbers, so it carried 24 `ADR-119` and 10 `ADR-120` references — every one of them denoting an in-release record — plus two ADR filenames in its machine-readable File Change Matrix that never existed on disk. All were re-classified and repointed at the pre-PR reconciliation pass; none had referred to the unrelated mainline ADR-119. No file outside that plan cited a drafted number, because the corpus edits were authored after the shift. The sweep's real scope is therefore the set of artifacts already written against the old number — which, when a plan is authored at Commit 0, is never empty. In-release Stage-4/Stage-5 citations reading "ADR-119" denote this record. The substance the operator ratified — scope and mechanism — is unchanged by the renumber.

**Numbering provenance — `120 → 122`.** Held **ADR-120** branch-local; renumbered to **ADR-122** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 120. In-release citations that read "ADR-120" denote this record **only where the surrounding context is the CLAUDE.md re-categorization**. That qualifier is load-bearing on this hop in a way it was not on the first: the mainline record that took 120 is a live record in this tree, cited here on its own terms, so a bare number no longer disambiguates. This is the record's second move, so its lineage is `119 → 120 → 122` and the hop-1 note above stands unamended — its `ADR-119` and `ADR-120` references are historical and are deliberately not swept. Sibling **ADR-121** did **not** move: the mainline does not claim 121 and it already sat inside the free range, so ADR-115 §Decision (3a) holds it fixed rather than shifting both records for symmetry.

**And this hop's citation sweep was the largest of the release's three number moves, not the smallest — the cost of a renumber rises with how much corpus has been written against the old number.** Hop 1 was cheap only because the release plan alone had been authored at the time; by this hop the whole Engineering corpus existed, so the tooled sweep repointed **98 occurrences across 14 files** — this record, ADR-121, the release plan, the composition-surface spec, the manifest, the composition library and its three test suites, both install/update docs, `setup-workspace.sh`, `update.sh` and `CLAUDE.md.template`. Two corrections were **not** mechanical, and both are the same residual seen from different angles — an artifact carrying the *other* record's claim on the old number. `core/deploy/deploy.sh` was **excluded whole-file**: it is in the branch diff for unrelated reasons, and all three of its `ADR-120` citations are mainline prose about G1 enforcement authority, byte-identical to `origin/main` at the same line numbers, so sweeping them would have manufactured a dangling reference to a record that never moved. Two lines inside ADR-121's own hard-wrapped provenance paragraph were swept and then reverted by hand: the tool's historical-line exemption is line-wise and keys on the `**Numbering provenance — …**` head, so the continuation lines of a wrapped note sit outside it. The first case the tool documents as a known residual; the second is a narrower instance of it and is reported to the release hub rather than fixed here, since changing the tool mid-renumber is the one thing this record's own release discipline forbids.

## Context

The composition-surface spec defines four file categories on the universality × editability matrix, each with an install-time and an update-time contract. The **Composition-surface** category is fully implemented: files declared in the package manifest are written at install with a managed-section fence plus an empty operator-additions fence, and regenerated at update from the current template and the current operator config while operator additions are preserved verbatim. The **Customizable** category is implemented only at install — whole-file token substitution, no markers — and the spec's own text records that its update-time auto-refresh is *specified but not yet implemented*.

Two files are classified Customizable: the workspace-root `CLAUDE.md` and the managed `settings.json`. The consequence of the unimplemented half is that neither is refreshed when the package is updated. A workspace installed once holds whatever template revision was current at install, indefinitely, and the only remedy is a full re-run of the install script, which recomposes the whole file and overwrites anything the operator added.

The spec's reversibility clause fixes the marker convention and the category contract at the first public-flip release and permits amendment **only via formal ADR**; the repository is past that flip, and re-categorizing a file is additionally named a breaking change gated at Stage 5 Solutioning. This record is that gate. The spec also forecloses one design direction outright: JSON has no in-file comment syntax and therefore no marker carve-out, so JSON-format runtime files are treated as wholly Customizable rather than as a composition surface, with composition expressed structurally through the runtime's own user-scoped overlay and through fields added to the operator config. Any decision that gave `settings.json` a fence would contradict the spec it amends.

## Decision

**The workspace-root `CLAUDE.md` is re-categorized from Customizable to Composition-surface. `settings.json` remains wholly Customizable and is unaffected by this record.**

Concretely, and stated so that Engineering cannot misread it:

1. **Scope is `CLAUDE.md` only.** This record defines **no** JSON composition model, structural or otherwise. The spec's JSON clause stands unamended, verbatim; no fence, no merge, and no overlay semantics are defined for `settings.json`, whose update-time contract — *not refreshed by the update script* — is unchanged by this record.

2. **The existing manifest is extended; no parallel manifest is created.** The source template is registered as one appended row in the **existing** composition-surface manifest array. A separate `CUSTOMIZABLE_FILES` array is **not** introduced: once a file carries a preserved operator-additions fence and is regenerated at update time it satisfies every axis of the Composition-surface row and none of the Customizable row, so a second array would be a second name for one mechanism.

3. **The manifest entry format gains a fourth, optional field: the marker dialect**, with values `plain` (comment-prefixed) and `markdown` (HTML-comment). It **defaults to `plain` when absent**, so every pre-existing row is unchanged and un-rewritten. `CLAUDE.md` is the first and only `markdown` entry.

4. **The manifest tier vocabulary gains `workspace-root`**, resolving to the workspace root itself and **stripping a trailing `.template`** from the source basename to form the target name. A new tier value, not a new precedence chain — the update script's existing workspace-root resolution order (flag, then environment variable, then home-relative default) is reused unchanged.

5. **The composition writer becomes the sole writer of `CLAUDE.md` at install and at update.** The install script's whole-file substitution arm for `CLAUDE.md` is removed; its `settings.json` arm is retained. One writer owning both moments is the invariant this record exists to restore — the defect it supersedes was a marker emitted by one mechanism and honored by no other.

6. **The source template carries no fences**, per the existing convention for every composition-surface source file; the writer emits both. Removing the template's hand-written operator-additions fence also resolves a spelling divergence between the form the writer emits, the form the spec documents, the form the template carries, and the form already in the field.

7. **The first regeneration of a `workspace-root`-tier target takes an unconditional pre-write backup**, independent of the tamper anchor. That anchor was introduced *after* the `CLAUDE.md` fence was removed, so no installed `CLAUDE.md` carries one, and the anchor's absent-means-*unknown-not-tampered* rule would otherwise leave the tamper-backup path unreachable on the first rewrite. This is what makes an EXPENSIVE-reversibility write recoverable.

8. **The template's authoring header is relocated to the manifest, and the manifest becomes an input to the install-time active-token derivation.** The header must leave the shipped template, because under clause 6 the whole template body becomes the managed body and any optional token left empty in the operator config would survive unsubstituted into the composed file and fail the installer's own unresolved-token verification gate. But the header is not inert prose: the installer derives its active token set by grepping the shipped templates, so the header's reserved-vocabulary declaration is load-bearing for the resolver. Relocating that declaration into the manifest and adding the manifest to the resolver's grep inputs keeps the derived token set byte-identical while removing the header from the composed body. The pairing is explicit rather than incidental, which is what the prior arrangement lacked.

## Alternatives Considered

**(A) Re-categorize `CLAUDE.md`; extend the existing manifest — SELECTED.** Reuses the shipped writer, the additions-preservation primitive, the SHA-triggered regeneration path, the tamper-detection contract, the atomic replace, and the existing test suite; the reader half is already dialect-aware and covered by a test, so the change is additive rather than novel. Restores the one-writer invariant whose absence caused the superseded defect.

**(B) Build a parallel `CUSTOMIZABLE_FILES` manifest array with its own regeneration loop — REJECTED.** The shape the originating work item proposed: a second array, loop, spec row, and mental model for a population of one file that behaves identically to a composition surface once fenced — a duplicate source for one contract, and the net-new-beside-covering-infrastructure pattern the extend-before-create gate exists to catch. Rejecting it narrows the work item's stated acceptance criterion, recorded as an adjustment rather than a silent omission.

**(C) Include `settings.json` by defining a JSON-structural composition model — REJECTED.** The spec forecloses a comment fence for JSON and treats JSON runtime files as wholly Customizable, so a structural model here would contradict a clause in the document this record amends. It would also collapse into the deep-merge option already on the sibling item's menu, so the two would ship competing merge mechanisms on one file or serialize for no architectural gain. The refresh need is real and is routed to the card that owns the file; it is not a composition-surface expansion.

**(D) Whole-file re-render guarded by a sidecar hash — REJECTED for `CLAUDE.md`.** Preservation becomes binary: an operator who edits anywhere forfeits either every future refresh or the edit, with no structured extension surface — the very property the additions fence exists to provide. (A reasonable candidate for `settings.json`, where no fence is possible; the sibling card's call.)

**(E) Three-way merge of the install-time base, the new template, and the live file — REJECTED.** Best in theory, worst in practice: a conflict writes conflict markers into the governance file the agent reads at session start, corrupting a Tier-1 surface. The spec's own precedent table already cites the package manager whose answer to this class is to *not* auto-merge.

**(F) Sidecar overlay — the platform owns the file outright, operator content moves elsewhere — REJECTED.** Superficially symmetric with the spec's JSON answer, but the symmetry fails: that overlay is a documented runtime feature, whereas a markdown overlay would rest on an assumption about external tool behavior the platform neither controls nor can test in its own repository.

**(G) Opt-in refresh behind a new command-line flag — REJECTED.** Zero risk, zero benefit: silent staleness persists for anyone who does not know the flag exists — the present state with extra vocabulary. Satisfies neither the regeneration criterion nor the outcome statement.

| Option | Preserves operator content | Reuse | Contradicts the spec? | Worst-case failure | Verdict |
|---|---|---|---|---|---|
| A | Structured, verbatim | High | No | Out-of-fence content discarded, with backup | **Selected** |
| B | Structured, verbatim | Med | No | Duplicate contract drifts | Rejected |
| C | Structural (JSON) | Low | **Yes** | Two merge mechanisms on one file | Rejected |
| D | Binary | Med | No | Operator silently stops receiving updates | Rejected here |
| E | Best in theory | Low | No | Conflict markers in a Tier-1 governance file | Rejected |
| F | Total (separate file) | Low | No | Rests on unverified external runtime behavior | Rejected |
| G | N/A | High | No | Staleness persists | Rejected |

## Consequences

**Positive.** A template change now reaches an installed workspace through the ordinary update path. Operator additions to `CLAUDE.md` gain a durable, structured home that survives an update byte-for-byte — replacing a template comment that today has to warn the operator that re-running install will overwrite their additions. The four-category taxonomy becomes *true*: every category that claims an update-time mechanism now has one, and the *specified but not yet implemented* hedge is deleted rather than restated. One writer owns the file at both moments, so the marker-versus-manifest divergence class that produced the superseded defect cannot recur — and the regression test that guarded that divergence is generalized rather than deleted, so the invariant survives with new expected values. A re-run of the install script now preserves an existing `CLAUDE.md` instead of overwriting it, because the composition loop's install-if-missing semantics replace the whole-file substitution arm.

**Negative.** The composition surface acquires a marker dialect, so the writer, the reader, and the update script's marker parsing must each be dialect-aware; a dialect-blind parse of a markdown-fenced target silently never matches its stored source hash and would regenerate the file on every run. Content outside either fence is discarded on update — proportionate for an allowlist, less so for a governance file, which is why the unconditional backup and a named-path notice are part of the decision rather than left to the general rule. The source template must shed both its hand-written fence and its authoring header, and one illustrative token in its body must be de-tokenized, because the composition writer resolves a smaller token set than the install-time substituter and one of the template's tokens has no persisted home in the operator config. Shedding the header moves a load-bearing declaration — the reserved token vocabulary the installer greps to derive its active token set — so the manifest that receives it becomes an input to that derivation; a future editor who removes the vocabulary comment from the manifest silently shrinks the set of tokens the installer resolves, which is why that comment carries an explicit warning and a test pins the derived set.

**For the sibling operator-key-guard work item on `settings.json`: this record fully decouples it.** Because scope is `CLAUDE.md` only and no JSON composition model is defined, that item's mechanism menu is untouched and its deep-merge option is neither required nor foreclosed; it has no dependency on this record nor on the card this record gates, so the two may be designed and built in parallel. Had this record instead defined a JSON-structural model, the two would have collapsed into one mechanism and would have had to serialize. **The corollary is a gap, stated rather than hidden:** `settings.json` staleness is not closed here, and its observed consequence is that platform-shipped security hooks can remain inert in a live install. Closing it belongs to the card that owns the file — whose guard is the precondition for any safe refresh — and would carry its own ADR, since amending the Customizable category's update-time contract is itself a category-contract change under the same clause that requires this record.

## Reversibility

**EXPENSIVE / Confidence HIGH.** Two independent reasons, and only the first is what the spec's clause names: past the public flip, changing the category contract is a coordinated user-side migration with stakeholder impact, and the spec is fixed at that release and amendable only by formal ADR.

The second is more concrete — rollback is **asymmetric**. Reverting the release restores the package but does not un-write a fence already rendered into an operator's live `CLAUDE.md`; the reverted platform would then read a file carrying markers its code no longer honors, which is the exact false-contract state the superseded defect describes, reintroduced from the other direction. The unconditional pre-write backup makes the operator-side state recoverable; it does not make the decision cheap to reverse.

## Related ADRs

Builds on **ADR-014**, whose two-hash separation (source-template hash as the regeneration trigger, post-substitution installed-body hash as the tamper anchor) is reused unchanged, and whose absent-anchor *unknown-not-tampered* rule is the specific reason the unconditional first-run backup is required here. Composes with **ADR-022**, which governs the split between the operator-identity config and the platform-behavior config, and which is the reason the one unresolvable token is not simply added to the operator config as part of this change. Numbered under **ADR-115**, whose mainline-anchor allocation rule determined this record's number after two concurrent releases claimed, in turn, the drafted number and then its successor — and whose §Decision (3a) is why the sibling **ADR-121** was held fixed rather than shifted alongside it.

## References

- The work item carrying the unimplemented Customizable-refresh mechanism, whose acceptance criteria this record gates — tracked as issue #3831.
- The earlier release that took the honest-documentation path, removed the false regeneration marker, and deferred building the mechanism this record authorizes — tracked as issue #2232.
- The sibling operator-key-guard work item on the managed `settings.json`, which this record's scope decision decouples — tracked as issue #1355.
- The sibling non-interactive-install work item whose token-pairing fix this record's clause 8 preserves — tracked as issue #1531.
