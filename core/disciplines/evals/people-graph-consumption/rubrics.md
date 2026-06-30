---
title: "Rubrics: people-graph-consumption"
purpose: The binary PASS/FAIL rubric for the people-graph-consumption eval suite — the rationale and criteria for grading consumption as wired-versus-not without a Likert scale.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Rubrics: people-graph-consumption

## Scoring scale

Binary **PASS / FAIL**. Rationale: A-04 (binary over Likert) — the downstream decision is binary (consumption wired vs. not), binary resists verbosity bias (F-02), and binary produces clean precision/recall against human labels. No 1–5 scale appears in this suite.

## Two-layer grading

| Layer | What it grades | Mechanism | Pass condition |
|---|---|---|---|
| Deterministic resolution + read-only | Does the fixture resolve the named expected value via each view query? Is the read read-only? Does an empty roster FAIL (non-triviality)? | `run_consumption_eval.py` — code-checkable, no LLM | All expected_value assertions resolve from the fixture; the read-only assertion holds (the runner performs only reads); the empty-roster control yields zero resolutions (proving non-triviality) |
| Skill-behavior (binary judge) | Does the SKILL's output show the resolution fired from the graph, the status filter applied, and no graph write? | `judge_prompts/people-graph-read-resolution.md` — binary LLM judge, executed by a harness on real skill output | Judge returns PASS for all four skill evals |

Both layers must pass for the suite to pass. The deterministic layer is the gate this Stage-6 self-verification runs now (it needs no live skill invocation); the binary-judge layer is executed downstream by a harness (pmo-skill-refiner / CI / Stage 7 DT) on captured skill output.

## Per-eval pass criteria

| Eval | Skill | View query | Named expected value (resolution) | Read-only | Non-triviality |
|---|---|---|---|---|---|
| 1 | comms-writer | who-does-what | preferred_name `Wren`; spelling `Wren Calloway`; role `Program Manager` (person-id-001) | zero graph write | empty roster → no name → FAIL |
| 2 | tracker-manager | who-does-what | full_name `Dax Moreno`; role `Technical Program Manager` (person-id-002) | zero graph write | empty roster → unresolved owner → FAIL |
| 3 | ppm-agent | who-covers-whom + coverage-by-capability | escalates_to `person-id-004`; coverage `integration-design` = {person-id-002, person-id-005}; EXCLUDE on-leave person-id-003 | zero graph write | empty roster → no target, no coverer → FAIL |
| 4 | delivery-engine | coverage-by-capability + who-does-what (Resource leg) | coverage `data-migration` = active person-id-005; EXCLUDE departed person-id-006; allocation person-id-005 @ proj-atlas = 100% | zero graph write | empty roster → no coverer → FAIL |

## Calibration thresholds (binary-judge layer)

| Judge | Pass criterion | Calibration requirement |
|---|---|---|
| people-graph-read-resolution | Output resolves the named value FROM the graph, applies the status filter where applicable, and writes nothing | Krippendorff α ≥ 0.80 on a ≥30-item gold set (per `calibration-protocol.md`); 0.67–0.79 tentative (add a second-family judge); < 0.67 rework the rubric (A-10) |

## Reversibility

The eval artifacts (fixture, evals.json, judge prompt, rubrics, runner, narrative) are a committed eval suite not yet executed by CI / pmo-skill-refiner — **MODERATE · confidence: HIGH** per `core/specs/reversibility-protocol.md` (committed to the corpus but not yet a release-gate criterion; undo = revert the suite, no downstream consumer invalidated). Promotion of the binary-judge layer to a CI gate that grades real runs would escalate the judge-prompt design to EXPENSIVE (changing it mid-stream invalidates historical comparisons) — out of scope for this suite.
