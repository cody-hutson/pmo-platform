# Fixture corpus — `check-issue-body-anchors.sh` (Check 71)

Hermetic input for `--self-test`. A corpus of live issue bodies cannot be
fixtured against `gh api` without depending on a real repository's issue state,
which is why the tool carries a `fixture` resolver seam at all.

## Layout

| Path | Role |
|---|---|
| `bodies/NNNN.txt` | One synthetic issue body per file; the basename is the issue number the tool reports. |
| `targets/*` | The files those bodies cite. Tracked, so they resolve exactly as a real target does. |

## Sentinel expansion

Body files carry `@@SEC@@` where the section glyph belongs; the tool expands it
at read time. This keeps the tracked body corpus from tripping a corpus-wide
scanner looking for the glyph — the fixtures are *about* section citations, so
they would otherwise read as a population of real ones.

Target files use the glyph directly. They are ordinary markdown and the heading
extractor reads them unmodified, which is the point: a target fixture that
needed preprocessing would not be exercising the real extractor path.

## What the matrix covers

Every Register A member the predicate can reach, plus both control arms:

| Body | Class exercised |
|---|---|
| `1001` | glyph citation resolving; glyph citation UNRESOLVED (the sensitivity arm) |
| `1002` | word-prefix (`Phase`) resolving; word-prefix (`Section`) UNRESOLVED |
| `1003` | lower-case word prefix (case-insensitivity is load-bearing); bare-basename unique-match resolution |
| `1004` | non-markdown target → `not-run: out-of-model` |
| `1005` | prefix outside the modelled five → `not-run: prefix out of model` |
| `1006` | target not tracked → `degraded` |
| `1007` | anchor bound to no path → `not-run` |

The resolving citations are the **specificity** arm: they are near-misses in the
sense that matters here — same file, same grammar, a number that *does* exist —
so a predicate that flagged them would be over-firing. A self-test run whose
sensitivity arm returns zero **exits 3** rather than reporting a clean zero.
