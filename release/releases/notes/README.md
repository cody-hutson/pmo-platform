# release/releases/notes/ — user-facing release notes

Per-release user-facing release notes live here, one file per release: `vX.Y_RELEASE_NOTES.md`.

## File naming

`vX.Y_RELEASE_NOTES.md` where `vX.Y` is the release version matching the GitHub Milestone slug suffix.

## Directory layout — flat, with one permitted subfolder

Note files are **flat** in this directory, alongside `README.md`. The one permitted subfolder is `_unversioned/`, the bucket for version-less-by-design notes — a release that ships with Tag `(none)` has no version stem to name. No other subfolder is permitted; the rule is stated once in [`../../references/standards/release-notes-standard.md`](../../references/standards/release-notes-standard.md) § File Location, Naming, Frontmatter and this section restates only its shape.

```
notes/
├── README.md            ← this file
├── vX.Y_RELEASE_NOTES.md    ← every versioned note, flat
└── _unversioned/        ← notes of version-less releases (Tag (none))
```

**Notes are not sharded by major version.** The per-major-version subfolder scheme in [`../plans/README.md` § Directory layout](../plans/README.md#directory-layout--major-version-subfolders) governs `../plans/` **only** — it is ADR-092-backed and enforced by `lint_release_corpus.py --check plan-identity`, and no equivalent placement assertion exists for notes. Both note producers (`../../tools/automated-closeout.sh` `notes_rel_path()` and `../../../core/deploy/tools/generate_release_index.py` `note_link()`) already emit the flat-except-`_unversioned/` form.

The tooling that reads this corpus discovers files **recursively** (`rglob` / `ls-tree -r`), so `_unversioned/` is transparent to it.

## Authoring contract

- **Authored by:** Stage 13 close spoke (per the Release-Notes Authoring Discipline in [`../../references/how-to/hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md) § Procedure 3 §Stage 13 Chip Pattern)
- **Committed by:** Stage 13 chore PR (`chore(vX.Y): Stage 13 — INDEX + DIGEST + RELEASE_NOTES`)
- **Read by:** GitHub Release Surface 1 at Stage 12 Phase B5.5 — emitted as `gh release create --notes "$BODY"` where `BODY="$(strip_frontmatter release/releases/notes/vX.Y_RELEASE_NOTES.md)"`, the shared transform in [`../../tools/lib/frontmatter-strip.sh`](../../tools/lib/frontmatter-strip.sh). The emit passes the frontmatter-stripped body, NEVER `--notes-file <path>`: `--notes-file` would publish the YAML frontmatter as raw text on the public Release page, violating the §5.1 enforced-transform invariant. An **empty** strip is refused rather than published (§5.1 S4) — a note needs both an opening and a closing `---` fence.

## Format

9-section format per [`../../references/standards/release-notes-standard.md`](../../references/standards/release-notes-standard.md). The standard defines the per-surface length + format conventions for the release-notes-canonical artifact vs. the engineering-audit artifact (`RELEASE_LOG.md` row) vs. the Surface 2 CHANGELOG.md entry.

## Three-artifact chain

Per [`../../references/standards/release-notes-standard.md`](../../references/standards/release-notes-standard.md):

1. **Release Outcome Statement** (pre-execution intent) — Milestone description H3 block, authored at Stage 3 Phase B3
2. **Change Description** (post-engineering operator-facing) — PR body, authored at Stage 6
3. **Release Notes** (post-merge user-facing) — `vX.Y_RELEASE_NOTES.md`, authored at Stage 13

This directory holds artifact #3 of the chain.

## Classification

**UNIVERSAL-PUBLIC** per [`../../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md). The canonical file is the upstream source for two downstream public surfaces — GitHub Release (Surface 1 via `--notes "$BODY"`, the §5.1 frontmatter-stripped body) and `CHANGELOG.md` (Surface 2 via the §5.3 transform). Both surfaces run in spoke worktrees that need the file on the branch, so the artifact ships verbatim.
