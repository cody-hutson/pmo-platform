# estimate fixtures — SYNTHETIC

Every record, version, point count, class, path, and figure in this directory is
**fabricated** for `estimate-usage.sh --self-test`. No operator-local store was read
to produce them and none is read to run them (CIAC-3 data hygiene). Session UUIDs use
the reserved `00000000-…` / `aaaaaaaa-…` shapes; work items use non-existent
`milestone:v9.xx` and an `issue-9NNNN` placeholder (deliberately NOT the `#N` form: a `#`-prefixed digit run matches a real issue number even when the suffix does not, which is exactly the confusion these fixtures exist to avoid). The
`/Users/synthetic-operator/…` paths are deliberate: SE-10 asserts that no render
leaks them.

## Files

| File | Exercises |
|---|---|
| `usage.jsonl` | The main rolled-up store: `meta` + `coverage` + 31 `rollup` rows spanning five synthetic release classes, every `attribution_tier`, `token_source` ∈ {exact, heuristic, mixed}, both honesty buckets, a zero-token row, three unkeyable milestones, four issue-grain rows, and three `session` rows carrying an operator-shaped path. |
| `RELEASE_LOG.fixture.md` | The **LOCAL** size/class bridge — the governed `**Velocity:**` grammar, including an `N/A` row and a narrative row that must fail to parse and be **excluded**, never defaulted (SA-8). |
| `usage-thin.jsonl` | Exactly **two** eligible rollup rows, so E2 *and* the E3 pooled tier both fall below `N_min` and the terminal DECLINE is reached (SE-3). |
| `usage-no-coverage.jsonl` | Sessions and rollups but **no `coverage` record**, with `meta.schema_version` deliberately set to `"1.2.0"` — the negative control proving the roll-up gate reads the record, not the version (SE-2). |
| `usage-provider.jsonl` | A synthetic `provider` record carrying a readable cost + token pair, so the `$` branch is gradable even though no producer exists (SE-8). |
| `usage-provider-unreadable.jsonl` | A `provider` record with **no** readable cost/token pair — must render volume plus the named `PROVIDER-PRESENT-BUT-UNREADABLE` notice, never a silent fallback (SE-8). |
| `estimate.expected.json` | The `--json` oracle for `--class novel --points 16` (SE-14). |

## The designed statistics

Each class is built to pin one reachable outcome of the confidence ladder, so
SE-5 can assert the ladder is **total** rather than sampling it.

| `--class` … `--points` | four-leaf totals | n | median | rMAD | outcome |
|---|---|---|---|---|---|
| `routine` 8 | 50/52/54/56/58/60 k | 6 | 55,000 | 0.0545 | **HIGH** (R3) |
| `novel` 16 | 100/110/120/140/**900** k | 5 | 120,000 | 0.1667 | **MEDIUM** (R4) — mean is 274,000, **2.28× the median** |
| `cross-cutting` 10 | 10/30/70/300 k | 4 | 50,000 | 0.60 | **LOW** (R5) |
| `wide-dispersion` 6 | 5/20/100/900 k | 4 | 60,000 | 0.7917 | **LOW, point figure SUPPRESSED** (R2) |
| `thin-population` 4 | 30/40 k | 2 | — | — | falls through to the **E3** pooled rate, capped MEDIUM by C-RATE |
| `usage-thin.jsonl`, any class | 30/40 k | 2 | — | — | **DECLINE** — no tier reaches `N_min` |

`--delta milestone:v9.94` is the leave-one-out case with a known pair: the target's
own key is `(novel, 18 pts)`, its actual is 900,000, and rebuilding its comparable
set **without it** yields a median of 115,000 — a signed delta of −785,000 and a
−87.2 % error. The all-in figure for the same key is 120,000, so the exclusion is
observably load-bearing rather than cosmetic.

## Regenerating

`usage*.jsonl` are machine-generated so the four-leaf totals stay exact. The
`RELEASE_LOG.fixture.md` and this README are hand-authored. If a fixture changes,
`estimate.expected.json` must be regenerated from the new render and the change
reviewed — the oracle is a committed expectation, not a snapshot to refresh blindly.
