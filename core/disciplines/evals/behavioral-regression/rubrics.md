---
title: "Rubrics: behavioral-regression"
purpose: The two-layer grading contract for the behavioural-regression corpus — what the deterministic layer scores, what the binary judge scores, and how a known-open defect is carried without loosening the floor.
type: discipline
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
---
# Rubrics: behavioral-regression

## What this suite grades, and what it does not

The check definitions this corpus grades against are **not** restated here. They live in `core/standards/regression-checks.md` — the platform's assertion bank — and every assertion in `evals.json` names the criterion it grades **by ID** (`EQ-01`, `GR-05`, `XC-03`, …). That split is the whole point of the corpus's existence:

| Surface | Owns |
|---|---|
| `core/standards/regression-checks.md` | the check **definitions** — intent, validation method, failure mode. Single source. |
| this suite | the **scenario, the fixture, and the expected verdict** — the layer the bank has never carried and, being a `type: standard` prose document with zero fixtures, cannot carry |

Neither restates the other, so no fact acquires a second home.

## Scoring scale

Binary **PASS / FAIL** per assertion. A regression corpus's members are must-hold assertions: a criterion either holds against the fixture or it does not, and a graded middle would only invite a threshold to be tuned until the corpus stopped complaining.

## Two-layer grading

| Layer | What it grades | Mechanism | Pass condition |
|---|---|---|---|
| **Deterministic** (this release) | Does each named criterion hold against the committed fixture? Is the read read-only? Does an empty fixture make every resolution FAIL? | `release/skills/pmo-skill-refiner/scripts/run_scenario_eval.py` — code-checkable, offline, no model call, so a run is reproducible rather than sampled | Every gradable assertion meets its expectation; the pass rate is at or above `[behavioral_regression].pass_rate_floor`; the non-triviality control holds |
| **Skill-behaviour** (binary judge) | Does a real skill output actually show the graded property — not the fixture's record of it? | `judge_prompts/output-quality-criteria.md` — binary judge, executed by a harness on captured skill output | Judge returns PASS for every judged assertion |

**Only the deterministic layer is wired to the release gate today.** The judged layer is committed and inert, exactly as its sibling suite ships it. That is stated rather than implied, because a rubric that describes two layers while one of them runs is how a corpus comes to be trusted for something it does not do. The judged statements in `evals.json` carry no `check` and are therefore **ungraded** — out of both numerator and denominator — so they cannot inflate the deterministic rate while they wait for a harness.

## Per-scenario pass criteria

| Scenario | Criteria graded (by ID) | Discriminates on the regressed fixture? |
|---|---|---|
| 1 — evidence quality and push-to-resolve | `EQ-01`, `EQ-02`, `EQ-06`, `PTR-01`, `PTR-06` | Yes — `EQ-01` and `EQ-02` fail; the other three are deliberately left holding |
| 2 — guardrails and cross-skill contracts | `GR-03`, `GR-05`, `GR-06`, `XC-03` (×2), plus a structural reachability check and a read-only check | Yes — `GR-03`, `GR-05` and both `XC-03` assertions fail; `GR-06` is deliberately left holding |
| 3 — known-open defects | the corpus's own tracked exceptions | No, by construction — see below |

**The unchanged values are load-bearing.** A regressed fixture in which everything fails proves nothing about which assertion caught what. Four criteria are left holding on purpose, so a failure is attributable to the value that moved. Preserve that property when adding a scenario.

## Known-open defects, and why they are not an allowlist

Scenario 3 carries assertions marked `expect: "fail"` — the mechanism the scenario-eval contract defines for a statement that is true of the corpus's *intent* and false of the tree *today*.

The alternative designs were both worse, and the reason is arithmetic. The floor is `1.00` because any failing scenario in a regression corpus **is** a regression; a sub-1.0 floor institutionalises a standing regression budget. That leaves two other ways to carry a known-open defect, and each hides it:

- **an allowlist beside the corpus** — the exception lives in a second file nobody reads during a run;
- **encoding it as `ungraded`** — an ungraded assertion leaves *both* numerator and denominator, so the corpus silently shrinks and the defect stops being measured at all.

An expected-FAIL assertion stays in **both** sides of the quotient, is named on stdout every run, and **turns the run red the day it starts passing** — which is the reminder to retire it in the change that fixed it. Retire the `expect`, and the assertion becomes an ordinary one.

## Non-triviality

Every `resolves_to` check is re-run against `fixtures/empty.json` and **all** must fail. A resolution that still succeeds against a structurally-empty fixture is not reading the fixture, which would make every one of this suite's baseline passes unfalsifiable. The runner exits 1 on that condition regardless of the pass rate — a suite that cannot discriminate does not get to report a green.

## Growth, and the exit criterion this suite ships under

The suite starts at **3 scenarios / 13 gradable assertions**, which is thin, and saying so is the point. The shakedown exit criterion recorded in `.github/behavioral-regression.enforce` is `N >= 10` scenarios plus both control-arm directions grading on every pull request across `>= 3` released versions. Until then the gate reports and does not block.

Adding a scenario is additive: a new entry in `evals.json` naming its criterion IDs, matching values in all three fixtures, and no change to the runner, the threshold or the workflow.

## Reversibility

**MODERATE · confidence HIGH.** The suite is additive and revert removes it. The cost of reversal grows with each release that begins trusting the gate — which is the honest caveat on a gate whose whole purpose is to be relied upon.
