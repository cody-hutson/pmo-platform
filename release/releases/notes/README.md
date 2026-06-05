# release/releases/notes/ — user-facing release notes

Per-release user-facing release notes live here, one file per release: `vX.Y_RELEASE_NOTES.md`.

## File naming

`vX.Y_RELEASE_NOTES.md` where `vX.Y` is the release version matching the GitHub Milestone slug suffix.

## Authoring contract

- **Authored by:** Stage 13 close spoke (per the Release-Notes Authoring Discipline in [`../../references/how-to/hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md) § Procedure 3 §Stage 13 Chip Pattern)
- **Committed by:** Stage 13 chore PR (`chore(vX.Y): Stage 13 — INDEX + DIGEST + RELEASE_NOTES`)
- **Read by:** GitHub Release Surface 1 (`gh release create --notes-file release/releases/notes/vX.Y_RELEASE_NOTES.md`) at Stage 12 Phase B5.5

## Format

9-section format per [`../../references/standards/release-notes-standard.md`](../../references/standards/release-notes-standard.md). The standard defines the per-surface length + format conventions for the release-notes-canonical artifact vs. the engineering-audit artifact (`RELEASE_LOG.md` row) vs. the Surface 2 CHANGELOG.md entry.

## Three-artifact chain

Per [`../../references/standards/release-notes-standard.md`](../../references/standards/release-notes-standard.md):

1. **Release Outcome Statement** (pre-execution intent) — Milestone description H3 block, authored at Stage 3 Phase B3
2. **Change Description** (post-engineering operator-facing) — PR body, authored at Stage 6
3. **Release Notes** (post-merge user-facing) — `vX.Y_RELEASE_NOTES.md`, authored at Stage 13

This directory holds artifact #3 of the chain.

## Classification

**UNIVERSAL-PUBLIC** per [`../../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md). The canonical file is the upstream source for two downstream public surfaces — GitHub Release (Surface 1 via `--notes-file`) and `CHANGELOG.md` (Surface 2 via the §5.3 transform). Both surfaces run in spoke worktrees that need the file on the branch, so the artifact ships verbatim.
