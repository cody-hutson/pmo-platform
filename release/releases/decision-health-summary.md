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
| Status | **RUN 4 COMPLETE (operator-approved backfill of the T1 triggers that went unrun since 2026-09-18), window of 14 releases.** All seven seams `measured` and graded `partial`. 13 findings (7 MEDIUM, 6 LOW, none HIGH or CRITICAL); every one recurs in two or more releases, giving 11 systemic patterns. v4.78's 16 findings from run 3 carry forward |
| Audit date (UTC) | 2026-10-24 |
| Evidence cut | event log read 2026-10-24T22:23Z (3,381 rows across the window's 14 releases; per-release counts reproduced by the query tool's release join). Milestone issues: 626, plus 43 pull requests; each milestone's counter is reconciled. All 14 hub-state ledgers read |
| Resolved window — `from_release` | v4.65 (`deploy-tools-and-tests-batch`) — the previous tiled `to_release` |
| Resolved window — `from` merge anchor | `0c4f0a4d6210bff9413c2ff1ab2f8bd1d438a2da` |
| Resolved window — `to_release` | v4.78 (`authoring-conventions-enforced-or-retired`), `VERIFIED` |
| Resolved window — `to` merge anchor | `aa1e8ffe629e584e0d65ff73e5ff35387c10331d` |
| Releases spanned | 14 (v4.66 through v4.78, including v4.67.1), ordered by merge anchor, with each consecutive pair verified by ancestry and a reverse control arm |
| Untiled span | **None.** The 13 releases the previous run left untiled are covered, and the record tiles from the 2026-09-18 run's upper bound to v4.78 |
| Decision-health posture | **The operator's gates were rendered and the GO was recorded in all 14 releases. The record around the gates is unreliable and uneven between releases.** The Stage-12 operator-authorization row (a `MUST` row) is absent in three `VERIFIED` releases, while the existence-only check passes. About 60 Stage 7/8 verdicts never reached the log in five releases. The action-item ledger disagrees with the log in six releases. Self-repair is recorded as an election in only five of the fourteen. Recording density varies by release more than by rule |
| `coverage_index` | **0/7 = 0.000** (counts only `measured` + `captured` seams; a lower bound on decision-observability, not a health score) |
| `instrumentation_ceiling` | **6/7 ≈ 0.857** (every seam with a declared producer; no window term) |
| Coverage distribution — `captured` | 0 |
| Coverage distribution — `partial` | 7 (DS1–DS7) |
| Coverage distribution — `unexercised` | 0 — *quiet*; none occurred |
| Coverage distribution — `undecidable` | 0 — *blind for this window only*; none occurred |
| Coverage distribution — `uninstrumented` | 0. DS7 reads `measured` because rows arrived from an undeclared producer; its `instrumented` predicate is still false, which is why the ceiling stays 6/7 |
| Classification counts | `unrecorded-decision` 6 · `malformed-record` 3 · `undeclared-producer` 1 · `oracle-coverage-gap` 1 · `detected-deviation` 1 · `non-terminal-disposition` 1 (run-carried labels; `undeclared-producer` is the rubric's own term) |
| Undeclared-producer detection | **Per-seam arm FIRED on DS7**: one release (v4.75) wrote 45 `spoke-launch`/`quota-reservation` rows that no corpus rule declares a writer for. This is the arm's first firing. Aggregate arm not fired (0.000 ≯ 0.857) |
| Index re-based this run? | **NO** — the seam-identifier set `{DS1…DS7}` is unchanged |
| Movement against prior runs | 0/7 (v4.61–v4.65) → 1/7 (v4.78 alone) → 0/7 (v4.66–v4.78). **The last step is not a regression:** DS2 was captured for v4.78 alone, and the wider window includes five releases whose Stage 7/8 verdicts never reached the log. All three patterns from 2026-09-18 persist through this window |
| Candidate patterns tested | all six recur — the GO with no choice delta (6 of the 12 releases that owed one), recovery recorded at the symptom locus (12 of 14), the Surface-1 deferral (12 of 14), the sweep zero-state absent (5 of 12), hub-brief premises overturned (3, a lower bound), incomplete self-repair sequences (5) |
| `recommendation-choice` MUST-promotion condition | **NOT MET** — two releases after the cutover (v4.67.1, v4.77) carry no `recommendation-choice-delta` row |
| Oracle pin — roster membership | `build-reviewer`, `implementation-planner`, `pipeline-triage`, `pmo-architect`, `pmo-data-engineer`, `pmo-devops-sre`, `pmo-principal-engineer`, `pmo-qa-lead`, `pmo-release-manager`, `pmo-skill-editor`, `pmo-skill-refiner`, `pmo-software-engineer`, `release-executor`, `release-hub`, `release-planner`, `roadmap-curator` |
| Oracle pin — derivation anchor | `aa1e8ffe`, identical to run 3's pin, and re-verified unchanged at the run's `main` head |
| Oracle pin — per-source path · content hash · entry count · entry-title set | entry-title sets recorded in full in the run folder's `SUMMARY.md`; per-source hashes and counts in the table below |
| Oracle pin — derivation date | 2026-10-24 |
| Oracle pin — derivation control | bounding control **PASS** on all 16 sources |
| Roster-delta notice | **no delta** against run 3: membership, hashes and counts are identical |
| Evidence-bar pass rate | **13 of 13 (100%)**; zero unpinnable observations |
| Latest analysis folder | `<OPERATOR_INSTANCE_ANALYSIS_PATH>/decision-audit-2026-10-24-backfill/` (operator-instance, git-ignored; the suffix separates it from the same date's v4.78 run) |

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

| Seam | `rows(s,W)` | coverage state | grade | what keeps it from `captured` |
|---|---|---|---|---|
| **DS1** | 793 | `measured` | partial | `MUST` Stage-12 authorization rows absent in three releases |
| **DS2** | 187 | `measured` | partial | about 60 Stage 7/8 verdicts unrecorded in five releases (the GO row is present in all 14) |
| **DS3** | 1,372 events + 14 ledgers | `measured` | partial | sweep zero-state absent in five releases; ledger and log diverge in six |
| **DS4** | 382 | `measured` | partial | GO delta absent in six of the twelve releases that owed one |
| **DS5** | 18 | `measured` | partial | recovery recorded at the symptom locus in 12 of 14 releases |
| **DS6** | 34 | `measured` | partial | re-spawns with no delegation row; rows with no merit condition |
| **DS7** | 45 (one release) | `measured` | partial | rows from an undeclared producer, in one release of fourteen |

**DS7 is `measured` without being instrumented.** Rows arrived, so § 2.1's first predicate places
the seam in `measured`. No corpus rule names their writer, so § 2.2 keeps `instrumented(DS7)` false,
and the ceiling does not rise. That pairing is exactly what the per-seam undeclared-producer arm
exists to surface.

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
