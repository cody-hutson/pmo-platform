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
assertion `{text, type}` with `type` binary at the judge (`structural` = mechanically
checkable / `judgment` = a single binary LLM-judge call / `acceptance` = a PR graded
against its issue's acceptance criteria — two judgments per criterion, gradability-class
then binary satisfaction, projected to the Stage-8 §5 verdict enum per
[`../../references/acceptance-assertion-type.md`](../../references/acceptance-assertion-type.md)).
**No 1-5 Likert** — binary judges only, per the eval-writer consensus (the `acceptance`
six-value enum is a projection of two binary-flavored judgments, not a native scale).

## Sets in this directory

| Gate | Set | Contents |
|---|---|---|
| Stage 3 — Bundle | [`stage-03-bundle/evals.json`](stage-03-bundle/evals.json) | Stage-3 Bundle gate eval set — 11 typed evals (4 structural S1-S4, 4 principal-behavior P1-P4, 2 contract C1-C2, 1 proactivity PR1). Grades a bundle rationale + created milestone description for Gate-3 conformance, principal bundling judgment, the two hard bundle contracts, and A5.1 cluster proactivity. Declares its own escape-rate metric in the set header. |
| Stage 7 — Dev Testing | [`stage-07-dev-testing/evals.json`](stage-07-dev-testing/evals.json) | Branch-freshness assertion (release branch has no base commits unreachable from HEAD before Dev Testing passes). Executable half: the `assert_branch_fresh.py` runner in the pmo-skill-refiner scripts. |
| Stage 8 — QA Testing | [`stage-08-qa-testing/evals.json`](stage-08-qa-testing/evals.json) | The `acceptance`-type worked example: an acceptance assertion ingests a GitHub-issue AC list (parse rules P1-P6), grades each criterion with two judgments (gradability-class + binary satisfaction), and projects to the Stage-8 §5 verdict enum with an all-drift-out acceptance score. Subject-under-test is the fixture at [`../fixtures/acceptance-sample-issue.md`](../fixtures/acceptance-sample-issue.md); type contract in [`../../references/acceptance-assertion-type.md`](../../references/acceptance-assertion-type.md). |

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
