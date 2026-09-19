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
| Status | **RUN 2 COMPLETE (independent re-run of the same window)** — six seams `measured` and graded `partial`, one `uninstrumented`; 8 findings, 3 systemic patterns |
| Audit date (UTC) | 2026-09-18 |
| Resolved window — `from_release` | v4.60 (`deploy-checks-hardening-batch`) |
| Resolved window — `from` merge anchor | `aea98ac15f84813a847ffcc666d3926fa7f23c00` |
| Resolved window — `to_release` | v4.65 (`deploy-tools-and-tests-batch`) |
| Resolved window — `to` merge anchor | `0c4f0a4d6210bff9413c2ff1ab2f8bd1d438a2da` |
| Releases spanned | 5 (v4.61, v4.62, v4.63, v4.64, v4.65 — ordered by merge anchor, verified by ancestry with a reverse control arm) |
| Decision-health posture | **Observable, incompletely recorded, and the gap concentrates at one gate.** Every seam the platform can see was measurable over this window and none reached full capture. The Stage-9 GO gate is the locus of the window's highest-severity finding and of its largest systemic pattern: v4.65 carries no gate-verdict row at all, and no release in the window carries a recommendation-choice delta at any GO firing. One seam is a standing blind spot. |
| `coverage_index` | **0/7 = 0.000** (counts only `measured` + `captured` seams; a lower bound on decision-observability, not a health score) |
| `instrumentation_ceiling` | **6/7 ≈ 0.857** (every seam with a declared producer; no window term) |
| Coverage distribution — `captured` | 0 |
| Coverage distribution — `partial` | 6 |
| Coverage distribution — `unexercised` | 0 — *quiet*; none occurred |
| Coverage distribution — `undecidable` | 0 — *blind for this window only*; none occurred |
| Coverage distribution — `uninstrumented` | 1 (DS7) — *standing blind*; carried by the residual-risk register |
| Classification counts | `unrecorded-decision` 3 · `malformed-record` 2 · `non-terminal-disposition` 1 · `absent-evidence-surface` 1 · `oracle-coverage-gap` 1 |
| Undeclared-producer detection | neither arm fired — per-seam arm not fired (the only `¬instrumented` seam returned zero rows); aggregate arm not fired (0.000 ≯ 0.857) |
| Index re-based this run? | **NO** — the seam-identifier set `{DS1…DS7}` is unchanged against the prior pin, so § 3.3's guard does not fire. (The prior run rendered `re-based` under § 3.4's one-time first-run clause, which does not reach this run.) |
| Oracle pin — roster membership | `build-reviewer`, `implementation-planner`, `pipeline-triage`, `pmo-architect`, `pmo-data-engineer`, `pmo-devops-sre`, `pmo-principal-engineer`, `pmo-qa-lead`, `pmo-release-manager`, `pmo-skill-editor`, `pmo-skill-refiner`, `pmo-software-engineer`, `release-executor`, `release-hub`, `release-planner`, `roadmap-curator` |
| Oracle pin — per-source path · content hash · entry count · entry-title set | entry-title sets recorded in full in the run folder's `SUMMARY.md` § Oracle derivation and pin; per-source hashes and counts in the table below |
| Oracle pin — derivation date | 2026-09-18 |
| Oracle pin — derivation control | bounding control **PASS** on all 16 sources (section-scoped count strictly < whole-file heading count everywhere; zero degenerate) |
| Roster-delta notice | **no delta** — membership identical to the prior pin, none added, none removed; per-source content hashes also identical, so the oracle has not drifted in content |
| Evidence-bar pass rate | **8 of 8 (100%)**; zero unpinnable observations |
| Systemic patterns | 3 — the Stage-9 gate recording nothing; recovery recorded at the symptom locus not the election locus; the Stage-13 Surface-1 deferral taken on every release |
| Latest analysis folder | `analysis/decision-audit-2026-09-18/` (operator-instance, git-ignored) |

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
| `release/skills/release-executor/SKILL.md` | `3be07cbd8d85f281` | 13 |
| `release/skills/release-hub/SKILL.md` | `379af3079936c3f0` | 9 |
| `release/skills/release-planner/SKILL.md` | `1e403b00bbdfdf40` | 17 |
| `release/skills/roadmap-curator/SKILL.md` | `4b9383855ff24b8b` | 5 |

### Per-seam result

| Seam | `rows(s,W)` | `occasions(s,W)` | coverage state | grade |
|---|---|---|---|---|
| **DS1** | 218 | ≥ 10 | `measured` | partial |
| **DS2** | 22 | ≥ 5 | `measured` | partial |
| **DS3** | 80 events + 15 ledger | ≥ 15 | `measured` | partial |
| **DS4** | 0 | 4 | `measured` | partial |
| **DS5** | 2 | 4 | `measured` | partial |
| **DS6** | 3 | 3 | `measured` | partial |
| **DS7** | 0 | — | `uninstrumented` | — (no grade — a non-graded state is never a passing grade) |

**DS4 is the instrumented-owed-and-silent case**, routed to `measured`/`partial` by § 2.1's first
predicate rather than to `unexercised` or `uninstrumented`, so a live emission gap reads as a shortfall
rather than as an absence.

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
