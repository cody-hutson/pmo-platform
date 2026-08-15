# Version-field cross-tabulation — the reproducible probe

**Purpose.** Answer *"did this release's material `SKILL.md` edits bump their `version:` fields?"* without re-deriving the method each time. Recorded because that question once cost a full investigation to answer, and the answer was not reusable.

**This is a method, not a stored result.** A stored 2×2 goes stale on the next `SKILL.md` commit — which is precisely the drift class this probe exists to detect. The figures below are baseline-pinned specimens showing the probe discriminating; re-run it rather than citing them.

---

## The probe

For a release's integration merge `<merge>`, cross-tabulate two independent predicates over the `SKILL.md` files that merge changed:

- **DESC-CHANGED** — the frontmatter `description:` block differs between `<merge>^1` and `<merge>`
- **BUMPED** — the frontmatter `version:` field differs across the same pair

```
git diff --name-only <merge>^1 <merge> -- '*/SKILL.md'
```

For each path, extract both fields at both revisions and place the file in one of four cells.

**Read the `version:` field with a first-match `^version:` extraction**, and the `description:` block as the span from `^description:` to the next top-level frontmatter key — a `description:` is frequently multi-line and a naive single-line read silently truncates it.

**Resolve blobs with `git show "${rev}:path"`, braced.** Unbraced `$rev:core/...` is mangled by zsh's `:c` history modifier — the command errors, the extraction is empty, and the cell reads zero. That produced a false clean reading during the investigation that motivated this document.

## The four cells, and what each means

| Cell | Meaning |
|---|---|
| **DESC-CHANGED + BUMPED** | Correct, if the description edit changed addressability |
| **DESC-CHANGED + no-bump** | **The defect class.** Candidates for correction — but see the qualifier below |
| **desc-same + BUMPED** | Correct — a body-only material edit |
| **desc-same + no-bump** | Correct — cosmetic or no material change |

**Report all four cells.** A lone "0 in the defect cell" is indistinguishable from a probe that examined nothing; the other three cells are what prove the extraction ran.

## The qualifier that matters most

**A populated `DESC-CHANGED + no-bump` cell is a candidate list, not a defect list.** Per § Bump Rules, a `description:` edit is material only when it changes **addressability** — which requests reach this skill. A length trim or a reword that alters no routing is correctly not bumped and will sit in that cell looking like a defect.

Classify each member before acting. The distinguishing test: *would a request that previously reached this skill now reach a different one, or vice versa?*

## The failure mode this probe is guarded against

**Do not substitute "carries an old `version:`" for "was materially edited in this release without a bump."** Those are different predicates over different populations, and only the second is a defect.

An analysis once proposed expanding a 12-member correction set to 17 on exactly that substitution. The five additions carried older `version:` values because the release **never touched them** — a skill last materially edited in v3.41 correctly reads v3.41. Two of the five were the very skills cited elsewhere in the same analysis as *correctly not bumped*. Adding them would have stamped a release label onto work that release did not do — the same error that had already removed one skill from the set at an earlier gate.

**The membership test is the changed-file set of the release's own merge, nothing else.**

## Specimen — illustrative only

Run at integration merge **`e323b0e8`** and its first parent. Denominator: **20** changed `SKILL.md` files.

The SHA is recorded because "baseline-pinned" without one is not pinned — a reader reproducing this has to source the merge externally, which is the same class of under-specification the probe itself guards against. Reproduce with `git diff --name-only e323b0e8^1 e323b0e8 -- '*/SKILL.md'`.

| Cell | Count |
|---|---|
| DESC-CHANGED + BUMPED | 1 |
| DESC-CHANGED + no-bump | 13 |
| desc-same + BUMPED | 4 |
| desc-same + no-bump | 2 |

All four non-degenerate, so neither predicate is a dead probe. The 13 became **12** by the time of correction: one member had since been materially edited by later work and bumped correctly, so re-stamping it would have introduced a false claim. **Re-measure against live state before acting on any historical figure** — the population moves between measurement and remediation.

## Corpus-wide variant

The same predicates run over all commits touching `SKILL.md`, rather than one merge, give a corpus-level view. Useful for spotting a systemic pattern; **not** a substitute for the per-release run, since a corpus 2×2 is stale the moment anything lands. If recorded anywhere, it must carry the commit it was pinned at.
