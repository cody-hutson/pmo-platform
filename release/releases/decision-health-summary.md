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
| Status | **AWAITING FIRST RUN** — no decision-health audit has run on this instance yet |
| Audit date (UTC) | _(none)_ |
| Resolved window — `from_release` | _(none)_ |
| Resolved window — `from` merge anchor | _(none)_ |
| Resolved window — `to_release` | _(none)_ |
| Resolved window — `to` merge anchor | _(none)_ |
| Releases spanned | _(none)_ |
| Decision-health posture | _(none — awaiting first run)_ |
| `coverage_index` | _(none)_ |
| `instrumentation_ceiling` | _(none)_ |
| Coverage distribution — `captured` | _(none)_ |
| Coverage distribution — `partial` | _(none)_ |
| Coverage distribution — `unexercised` | _(none)_ |
| Coverage distribution — `uninstrumented` | _(none)_ |
| Index re-based this run? | _(none)_ — set when the rubric's seam-id set changed since the prior run |
| Oracle pin — roster membership | _(none)_ |
| Oracle pin — per-source path · content hash · entry count · entry-title set | _(none)_ |
| Oracle pin — derivation date | _(none)_ |
| Roster-delta notice | _(none)_ — names any oracle source added or removed since the prior pin |
| Evidence-bar pass rate | _(none)_ |
| Systemic patterns | _(none)_ |
| Latest analysis folder | _(none — the dated decision-audit folder is produced at first run)_ |

## How to read this surface

**The non-graded coverage classes are reported separately, and only `uninstrumented` is blind.**
This is the distinction the whole surface exists to preserve, so it is stated here rather than
left to the reader:

- **`uninstrumented`** — no corpus rule names a writer for any of the seam's loci. The platform
  cannot see this decision class at all. This is the **blind** class, and it is what the
  residual-risk register carries.
- **`unexercised`** — a writer is declared and the window simply owed the seam no occasions.
  Nothing was missed. This is **quiet, not blind**, and it is not a residual risk.

Collapsing the two into one number would report a live blind spot and an uneventful window as
the same state. Neither takes a grade at all: a grade belongs only to a `measured` seam.

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

**`coverage_index` exceeding `instrumentation_ceiling` is a finding, not an arithmetic error.**
The relation is a detector rather than an invariant: a run observing it violated has found
evidence arriving from a producer no corpus rule declares. Surface it.

**A re-based index does not trend.** When the rubric's seam-id set changes between runs, the
run renders the index as re-based and states the seam delta rather than trending across the
discontinuity. A change to the rubric's coverage vocabulary is an oracle change of the same
family, noted in the run's `SUMMARY.md` per the cadence protocol's continuity rule.
