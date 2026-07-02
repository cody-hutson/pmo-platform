# Stage-gate eval sets

This directory is the home for **pipeline stage-gate eval sets** — assertion-cluster
eval sets that grade the *output* of a pipeline stage gate. Each stage-gate set lives
in its own sub-directory (`stage-gates/<gate>/evals.json`), mirroring the
discipline-scoped eval-set precedent under `core/disciplines/evals/<set>/`. The home
and layout are recorded in the joint stage-gate-eval-home ADR
([`ADR-067`](../../../../ADRs/ADR-067-stage-gate-eval-set-home.md)).

Stage-gate eval sets are deliberately kept **out of** eval-writer's demonstration
`evals.json` (the `../evals.json` file, which holds the skill's *own* worked-example
evals). eval-writer authors stage-gate content; it does not fold that content into its
own demonstration suite.

All stage-gate eval sets conform to the live eval schema: top-level header +
`evals[]`, each eval `{id, name, prompt, expected_output, files, assertions[]}`, each
assertion `{text, type}` with `type` binary (`structural` = mechanically checkable /
`judgment` = a single binary LLM-judge call). **No 1-5 Likert** — binary judges only,
per the eval-writer consensus.

## Sets in this directory

| Gate | Set | Contents |
|---|---|---|
| Stage 7 — Dev Testing | [`stage-07-dev-testing/evals.json`](stage-07-dev-testing/evals.json) | Branch-freshness assertion (release branch has no base commits unreachable from HEAD before Dev Testing passes). Executable half: the `assert_branch_fresh.py` runner in the pmo-skill-refiner scripts. |

*(Additional stage-gate sets are appended to this table as they are authored.)*

## Escape-rate metric

Each stage-gate set declares an **escape-rate** in its header:

> **escape rate** = (number of *escapes*) / (number of *gate firings evaluated*),
> over a defined window (per-release-close, rolling).

An **escape** is a defect the gate passed (the gate fired GO / the artifact shipped)
that a downstream stage subsequently caught as a defect this set's assertions *should*
have caught. A **gate firing** is one evaluation of the gate. The metric is
**recorded, not gated** at authoring time — with no historical data yet, each set's
header marks its current value `[INSUFFICIENT DATA — populate at release close]`
(fewer than 3 firings is not yet a reliable rate). The per-set header is the machine
source; this index restates the metric for human readers.

## Deferred: calibration-data auto-aggregation

**Status: DEFERRED as of 2026-07-02.**

Automatic aggregation of per-run calibration records into a rolled-up
calibration-data file is **deferred**, not built, at this time. Rationale: there is no
per-run calibration *producer* writing records to a live results directory today, and
the calibration layer stays dormant until a boundary accrues records — so an
aggregator would roll up an empty input set with no consumer. Building it now would be
a roll-up over nothing.

This deferral re-opens when **both** unblock conditions hold:

1. **A live results-dir home exists** for per-run calibration records (a resolved,
   non-dead directory where per-run calibration JSONs are written); and
2. **A per-run calibration record producer is wired into the harness** (something
   actually emits per-run calibration records to that home).

Once at least one gate boundary accrues calibration records under those two
conditions, revisit and build the aggregation.
