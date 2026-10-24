<!-- reference-durability: allow-link -->
# Decision-Health Summary (committed hand-off surface)

> **Producer:** `pmo-qa-auditor` Mode J (Decision-Health Audit) — overwrites the headline block
> below on each run (single-record-overwrite). **Consumer: none today, and that is a
> measurement rather than an omission.** A probe across the operations skills and the schema
> corpus for a reader of this file returns nothing, run on the same instrument that *does*
> locate the sibling audit surface's declared consumer — so the zero discriminates. This file
> ships in the repo (tracked) for two narrower reasons, both load-bearing:
>
> 1. **It gives a tracked acceptance criterion a tracked oracle.** The full read-once audit
>    lives in the git-ignored dated analysis folder, so a criterion that cites only that folder
>    has no oracle on any instance but the producing one.
> 2. **It lets the window's `from_release` default resolve on a fresh clone.** A run with no
>    supplied lower bound reads the previous run's upper bound from here.
>
> Schema: [`decision-audit-mode-spec.md`](../../core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md)
> §7b. When-to-run: [`decision-audit-cadence.md`](../references/protocols/decision-audit-cadence.md).
> Scored content SSOT: [`decision-audit-dimension-rubric.md`](../../core/skills/pmo-qa-auditor/references/decision-audit-dimension-rubric.md).

## Latest run

| Field | Value |
|---|---|
| Status | **RUN 3 COMPLETE (T1 release close + T2 decision-oracle change), window of one release.** One seam `captured`, five `partial`, one `uninstrumented`. 16 findings (none HIGH or CRITICAL; 5 MEDIUM). 0 in-window systemic patterns, because a one-release window cannot carry a cross-release recurrence; two cross-run recurrences recorded |
| Audit date (UTC) | 2026-10-24 |
| Evidence cut | event log read 2026-10-24T21:14Z (241 rows for the release slug); stage sub-tasks and the hub-state ledgers read 21:03–21:08Z. Stage 13 of `to_release` was still running at the cut, and its later rows are outside this run |
| Resolved window — `from_release` | v4.77 (`dependabot-prs-merge-without-bypass`) — **supplied by the caller**, not defaulted |
| Resolved window — `from` merge anchor | `0324b97f483c523eb0af5fce739f2ffb56ae669b` |
| Resolved window — `to_release` | v4.78 (`authoring-conventions-enforced-or-retired`) — release-log row `DEPLOYED` at the cut |
| Resolved window — `to` merge anchor | `aa1e8ffe629e584e0d65ff73e5ff35387c10331d` |
| Releases spanned | 1 (ordered by merge anchor, with ancestry verified and a reverse control arm) |
| **Untiled span (no decision-health run covers it)** | **13 release-log rows, v4.66 through v4.77, merge anchors `d97584e4…` through `0324b97f…`.** The previous run's window ended at v4.65 (`0c4f0a4d…`). This run's lower bound was narrowed explicitly to the one release its caller scoped, so a run that defaults `from_release` from this surface (to v4.78) does not reach that span |
| Decision-health posture | **The gates held and were recorded; the record between them is incomplete.** Every operator stop the Hub Gate Register names was rendered and recorded on both surfaces, and gate verdicts were captured in full for the first time on this axis (DS2). The shortfalls sit in the connective records: choice deltas at aligned answers and at the Stage-9 GO (the GO gap recurs from the prior run), the commitment sweep's zero-state row (none emitted in the release), and self-repair terminal and companion rows. The release-hub failure mode added by this release's T2 change fired, undetected, on the three hub records posted after its deploy |
| `coverage_index` | **1/7 ≈ 0.143** (counts only `measured` + `captured` seams; a lower bound on decision-observability, not a health score) |
| `instrumentation_ceiling` | **6/7 ≈ 0.857** (every seam with a declared producer; no window term) |
| Coverage distribution — `captured` | 1 (DS2) |
| Coverage distribution — `partial` | 5 (DS1, DS3, DS4, DS5, DS6) |
| Coverage distribution — `unexercised` | 0 — *quiet*; none occurred |
| Coverage distribution — `undecidable` | 0 — *blind for this window only*; none occurred |
| Coverage distribution — `uninstrumented` | 1 (DS7) — *standing blind*; carried by the residual-risk register |
| Classification counts | `unrecorded-decision` 7 · `malformed-record` 3 · `non-terminal-disposition` 3 · `oracle-coverage-gap` 1 · `undetected-named-failure-mode` 1 · `detected-deviation` 1 · `absent-evidence-surface` 0. The labels are run-carried: no corpus surface defines a classification vocabulary, and the last two are new at this run |
| Undeclared-producer detection | neither arm fired. Per-seam arm: the only `¬instrumented` seam, DS7, returned zero rows. Aggregate arm: 0.143 is not above 0.857 |
| Index re-based this run? | **NO** — the seam-identifier set `{DS1…DS7}` is unchanged against the prior pin. The T2 change moved the **detection oracle**, not the seam set: see the roster-delta notice |
| Movement against the prior run | index 0.000 → 0.143 (DS2 partial → captured); ceiling unchanged; DS4 0 → 20 rows. Read it with the window-size caveat: the prior window spanned five releases and this one spans one |
| Oracle pin — roster membership | `build-reviewer`, `implementation-planner`, `pipeline-triage`, `pmo-architect`, `pmo-data-engineer`, `pmo-devops-sre`, `pmo-principal-engineer`, `pmo-qa-lead`, `pmo-release-manager`, `pmo-skill-editor`, `pmo-skill-refiner`, `pmo-software-engineer`, `release-executor`, `release-hub`, `release-planner`, `roadmap-curator` |
| Oracle pin — derivation anchor | `aa1e8ffe` (the oracle after the T2 change); unchanged at the run's `main` head |
| Oracle pin — per-source path · content hash · entry count · entry-title set | entry-title sets recorded in full in the run folder's `SUMMARY.md` § Oracle derivation and pin; per-source hashes and counts in the table below |
| Oracle pin — derivation date | 2026-10-24 |
| Oracle pin — derivation control | bounding control **PASS** on all 16 sources (section-scoped count strictly below the whole-file heading count everywhere; zero degenerate) |
| Roster-delta notice | **No membership delta.** Three sources changed content since the prior pin. `release-hub` gained one entry, *Grounded claim cited in prose and left unlabeled — OUT*: the T2 change, with the hub Output Contract's per-emission evidence-label requirement. `release-executor` and `release-planner` changed content with identical entry counts and title sets, which is the case the hash field exists to show |
| Evidence-bar pass rate | **16 of 16 (100%)**; zero unpinnable observations |
| Systemic patterns | 0 in-window (one-release window). Cross-run recurrences: the Stage-9 GO carries no choice-delta row (the prior run's largest pattern), and the Stage-12 Surface-1 step defers to the Stage-13 backstop by construction (the prior run's third pattern). In-window cluster that is a candidate for the next window: hub-brief premises overturned downstream, seven instances |
| Latest analysis folder | `<OPERATOR_INSTANCE_ANALYSIS_PATH>/decision-audit-2026-10-24/` (operator-instance, git-ignored) |

### Oracle pin — per source

| Oracle source | content sha256 | entry count |
|---|---|---|
| `release/skills/build-reviewer/SKILL.md` | `9409b358bb3b36c2` | 7 |
| `release/skills/implementation-planner/SKILL.md` | `1f2d2550c5dcd098` | 6 |
| `release/skills/pipeline-triage/SKILL.md` | `0cdffa8e4971a039` | 4 |
| `release/skills/pmo-architect/SKILL.md` | `3470b4187afff597` | 4 |
| `release/skills/pmo-data-engineer/SKILL.md` | `4e54f014213dde53` | 4 |
| `release/skills/pmo-devops-sre/SKILL.md` | `0900659e4ab101fd` | 3 |
| `release/skills/pmo-principal-engineer/SKILL.md` | `46b5aa7b1e3ae21f` | 4 |
| `release/skills/pmo-qa-lead/SKILL.md` | `8bd5ec00975113db` | 4 |
| `release/skills/pmo-release-manager/SKILL.md` | `0ac2078b2178e380` | 4 |
| `release/skills/pmo-skill-editor/SKILL.md` | `d7992351414dc01d` | 6 |
| `release/skills/pmo-skill-refiner/SKILL.md` | `99e4966a83dfdc7b` | 6 |
| `release/skills/pmo-software-engineer/SKILL.md` | `ff360c227b864ea8` | 4 |
| `release/skills/release-executor/SKILL.md` | `13ecc8addbc08873` | 13 |
| `release/skills/release-hub/SKILL.md` | `99344ca2a747828b` | 10 |
| `release/skills/release-planner/SKILL.md` | `5255d3699abb377c` | 17 |
| `release/skills/roadmap-curator/SKILL.md` | `4b9383855ff24b8b` | 5 |

### Per-seam result

| Seam | `rows(s,W)` | `occasions(s,W)` | coverage state | grade |
|---|---|---|---|---|
| **DS1** | 50 | 17 contract occasions (15 rows present) + the stage-spec decisions | `measured` | partial |
| **DS2** | 21 | 21 | `measured` | **captured** |
| **DS3** | 100 events + 27 ledger | ≥ 27 items' transitions + the tiered findings | `measured` | partial |
| **DS4** | 20 | ≥ 24 | `measured` | partial |
| **DS5** | 4 | ≥ 5 | `measured` | partial |
| **DS6** | 4 | ≥ 5 | `measured` | partial |
| **DS7** | 0 | — | `uninstrumented` | — (no grade — a non-graded state is never a passing grade) |

**DS2 is the first `captured` seam on this axis.** Every stage gate the release traversed carries
the verdict row its spec assigns, and the Stage-9 GO row is present. Four of those rows were written
after the routing point that consumed them, and each carries a disclosure token. That disclosure is
what keeps them well-formed.

## How to read this surface

**The non-graded coverage classes are reported separately, and they are blind in different
ways.** This is the distinction the whole surface exists to preserve, so it is stated here
rather than left to the reader. Each answers a different question about a silent seam:

- **`uninstrumented`** — no corpus rule names a writer for any of the seam's loci. The platform
  cannot see this decision class at all. This is the **standing blind** class, and it is what the
  residual-risk register carries.
- **`undecidable`** — a writer **is** declared and no rows arrived, but the surface that would
  say what the window owed could not be read at audit time, so there is no denominator to
  compare the silence against. This is **blind for this window only**: it also carries
  residual-risk register membership, and a later run over a readable window resolves the seam
  normally.
- **`unexercised`** — a writer is declared and the window determinately owed the seam no
  occasions. Nothing was missed. This is **quiet, not blind**, and it is not a residual risk.

Collapsing any of them into one number would report a live blind spot, an unreadable denominator
and an uneventful window as the same state. None takes a grade at all: a grade belongs only to a
`measured` seam.

**The headline index is a lower bound on decision-observability, by design.** `coverage_index`
counts only fully-captured seams, so a seam that is instrumented but recorded incompletely
contributes nothing to it. That is the honest direction — an index that credited partial
capture would read as health while measuring silence. The distribution above renders alongside
the index precisely so movement from partial toward full capture stays visible even though the
headline does not move until capture is complete.

**`instrumentation_ceiling` is the reachable bound, and reading it beside the index is the
point.** The ceiling counts every seam for which a producer is declared anywhere in the corpus,
so it rises only as instrumentation lands and carries no window term. A persistently
sub-maximal index below a sub-maximal ceiling is **not** evidence of ill decision-health — it
is the instrumentation gap being reported honestly. A reader comparing observability across
windows reads the ceiling and the distribution; a reader asking how much of what happened got
recorded reads the index.

**Evidence from an undeclared producer is a finding, not an arithmetic error, and it is detected
on two arms.** Per seam, rows arriving for a seam no corpus rule declares a writer for is the
direct reading and fires on that seam alone. In aggregate, `coverage_index` exceeding
`instrumentation_ceiling` is a detector rather than an invariant — the relation does not hold by
construction, and a run observing it violated has found the same thing across the distribution.
The per-seam arm is the sensitive one: the aggregate arm can only fire when the captured count
exceeds the instrumented count, so it goes quiet as instrumentation lands, which is the opposite
of what a reader watching for undeclared emission needs. Surface either.

**A re-based index does not trend.** When the rubric's seam-id set changes between runs, the
run renders the index as re-based and states the seam delta rather than trending across the
discontinuity. A change to the rubric's coverage vocabulary is an oracle change of the same
family, noted in the run's `SUMMARY.md` per the cadence protocol's continuity rule.
