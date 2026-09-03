---
title: "Eval suite: behavioral-regression"
purpose: The platform's standing behavioural-regression corpus — the scenarios, fixtures and expected verdicts that the release gate scores against a recorded pass-rate floor.
type: discipline
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
---
# Eval suite: behavioral-regression

The standing corpus behind the **Behavioral-regression pass-rate gate**. It answers one question a release needs answered and nothing in this tree could previously answer: *did a change to one skill silently regress the behaviour of another?*

## What is here

| Path | What it is |
|---|---|
| `evals.json` | the scenario manifest — each assertion names the `regression-checks.md` criterion it grades **by ID** and carries its expected verdict |
| `rubrics.md` | the two-layer grading contract, and why a known-open defect is carried as an expected-FAIL rather than an allowlist |
| `fixtures/baseline.json` | the unregressed reference state |
| `fixtures/regressed.json` | the same document with **specific** values degraded — the other half of the control pair |
| `fixtures/empty.json` | the structurally-empty non-triviality control |
| `fixtures/tag-boundary-cases.json` | the committed expected-match set for the gate's major-release tag filter |
| `judge_prompts/` | the binary judge for the skill-behaviour layer — **committed and inert**, not wired to the gate |
| `gate_inputs.py` | the two inputs the gate consumes, read and asserted: the pass-rate floor, and the tag filter |

## What this suite does not own

The **check definitions** — `EQ-01`, `GR-05`, `XC-03` and the rest. Those live in `core/standards/regression-checks.md`, which stays their single source; this suite cites them by ID and restates none of their text. The bank is an assertion bank with zero fixtures, and its own procedure says *prepare a test artifact*. This suite is that missing layer: scenario, fixture, expected verdict. The two are layers of one capability, not competitors for one fact.

## Running it

From the runner's skill root, `release/skills/pmo-skill-refiner/`:

```bash
# baseline — expect the pass rate at the floor, exit 0, control PASS
python3 -m scripts.run_scenario_eval \
  --suite ../../../core/disciplines/evals/behavioral-regression/evals.json \
  --fail-under "$(python3 ../../../core/disciplines/evals/behavioral-regression/gate_inputs.py read-floor)" \
  --out /tmp/grading.json

# the control arm — expect a STRICTLY LOWER pass rate and exit 1
python3 -m scripts.run_scenario_eval \
  --suite ../../../core/disciplines/evals/behavioral-regression/evals.json \
  --fixture ../../../core/disciplines/evals/behavioral-regression/fixtures/regressed.json \
  --fail-under "$(python3 ../../../core/disciplines/evals/behavioral-regression/gate_inputs.py read-floor)" \
  --out /tmp/control.json
```

Pass `--out` to a path outside the tree, as above, or the runner writes `grading.json` beside the suite and you commit a report by accident. Add `--verbose` for per-assertion evidence.

**Read all three signals, not just the exit code:** the pass rate, the `control:` line (it must read `PASS`), and the `expected-FAIL:` line if one prints. A run where the second scores the same as the first is **not discriminating**, and its baseline passes are unfalsifiable.

From the repository root, the gate's own inputs:

```bash
python3 core/disciplines/evals/behavioral-regression/gate_inputs.py read-floor
python3 core/disciplines/evals/behavioral-regression/gate_inputs.py assert-tag-filter
```

Both are the same entry points the CI job invokes, so a local run and the gate measure the same thing.

## The threshold lives in exactly one place

`[behavioral_regression].pass_rate_floor` in `core/config/platform-config.toml.template`. This suite does not restate the number, and neither does the workflow or the standard — they name it by role. A recalibration edits that one line.

The seam, stated once: **the workflow reads the floor and passes it to the runner as `--fail-under`; the runner performs the comparison and sets its exit code; the gate consumes only that exit code and never parses the report.** That is what keeps exactly one definition of the report contract in the tree.

## Adding a scenario

Additive by construction — no change to the runner, the threshold, or the workflow:

1. Add an entry to `evals.json` naming the criterion IDs it grades. Do not copy the criterion text.
2. Add the matching values to **all three** fixtures.
3. In `regressed.json`, degrade *some* values and leave the rest as the baseline has them. The unchanged values are what make a failure attributable.
4. Run all three ways above and read all three signals.
5. If the statement genuinely needs a human or a model to grade, leave `check` off — it reports as ungraded rather than silently failing.
6. If it is a **known-open defect**, mark it `expect: "fail"` (see `rubrics.md`). Do not loosen the floor and do not delete the assertion.

Full input contract, written so you need not read the runner's source: `release/skills/pmo-skill-refiner/references/scenario-eval-contract.md`.

## Current size, honestly

**3 scenarios · 13 gradable assertions · 1 ungraded · 1 expected-FAIL.** That is thin, and the gate ships in warn mode because of it. The shakedown exit criterion — `N >= 10` scenarios plus both control-arm directions grading across `>= 3` released versions — is recorded in `.github/behavioral-regression.enforce`, evaluable from committed state rather than from a log nobody can read back.
