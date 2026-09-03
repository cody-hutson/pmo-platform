---
title: "Judge prompt: behavioural output-quality criteria"
purpose: The binary PASS/FAIL judge for the skill-behaviour layer of the behavioural-regression corpus — grades a captured skill output against a named check-bank criterion.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Judge prompt: behavioural output-quality criteria

**Status: committed and inert.** This layer is not executed by the release gate. The gate runs the deterministic layer only, and the statements this judge would grade carry no `check` predicate in `evals.json`, so they are **ungraded** — out of both numerator and denominator — and cannot inflate the deterministic pass rate while they wait for a harness. Stated plainly because a judge prompt sitting beside a live gate reads as part of it.

Executed downstream by a harness (`pmo-skill-refiner`, or a Stage 7 dev-testing pass) against **captured real skill output**, not against a fixture.

---

## Task

You are grading one skill output against **one** named criterion from the platform's regression check bank at `core/standards/regression-checks.md`.

You will be given:

- `CRITERION_ID` — e.g. `EQ-01`, `GR-05`, `XC-03`
- `CRITERION_TEXT` — the intent, validation method and failure mode, **quoted verbatim from the bank**
- `OUTPUT` — the skill output under test

Return exactly one verdict: **PASS** or **FAIL**, followed by one line of evidence.

## Rules

1. **Grade only the named criterion.** Another defect you notice is out of scope for this call; a judge that grades everything grades nothing reproducibly.
2. **The bank's text is the rubric.** Do not substitute your own standard for quality, and do not grade against a stricter reading than the criterion states.
3. **Binary, with no third option.** No "PASS with concerns", no partial credit. If the criterion's failure mode is present in the output, the verdict is FAIL.
4. **Cite, do not summarise.** The evidence line quotes or points at the specific span of `OUTPUT` that decided the verdict. An evidence line that restates the criterion is not evidence — it does not distinguish a real pass from a judge that never read the output.
5. **Absence of the subject is not a pass.** If `OUTPUT` contains nothing the criterion applies to (no dates for a date criterion, no risks for a risk criterion), return `N/A` with that stated. Do not return PASS: a criterion that had nothing to grade did not hold, it simply did not fire, and reporting the two the same way is how a corpus comes to be trusted for coverage it does not have.

## Output format

```
VERDICT: PASS | FAIL | N/A
EVIDENCE: <one line — the span of OUTPUT that decided it, quoted or located>
```

## Calibration

| Judge | Pass criterion | Calibration requirement |
|---|---|---|
| output-quality-criteria | The output satisfies the named criterion as the bank defines it | Krippendorff α ≥ 0.80 on a ≥ 30-item gold set per the sibling suite's `calibration-protocol.md`; 0.67–0.79 is tentative (add a second-family judge); below 0.67 means the rubric is reworked rather than the threshold lowered |

**This judge must be calibrated before its layer is wired to any gate.** Promoting an uncalibrated judge to a gate criterion would put a sampled verdict behind a threshold designed for a reproducible one.
