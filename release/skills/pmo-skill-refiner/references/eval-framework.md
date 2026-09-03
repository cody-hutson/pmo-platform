# Eval Framework

## Usage

Documents how the preserved skill-creator eval harness is invoked from `pmo-skill-refiner`. Consumers: Claude-when-running-the-refiner, and future maintainers extending the harness.

The harness is **preserved verbatim** from skill-creator via `git mv` in the refactor — no logic changes were made during the refactor. Any script-level refactor is deferred to follow-up issues.

---

## Overview — 3-Layer Eval Model

| Layer | Purpose | Entry point |
|---|---|---|
| **1. Qualitative review** | Human judges output quality via HTML viewer showing per-eval outputs + benchmark comparison | `eval-viewer/generate_review.py` |
| **2. Quantitative assertion grading** | Each eval's assertions graded PASS/FAIL against a committed fixture and reduced to a pass rate; emits `grading.json` | `scripts/run_scenario_eval.py` |
| **3. Description-trigger optimization** | 60/40 train/test split on 20 trigger eval queries; iterates up to 5× on the `description:` field; selects `best_description` by test score | `scripts/run_loop.py` |

**Layer 2's entry point is the output-scoring runner, not the trigger harness.** `run_eval.py` grades *triggers* — whether a skill's description causes the model to fire for a query — and it grades nothing else. It computes no output score, reads no `assertions[]`, and writes no `grading.json`. This table previously named it as Layer 2's entry point and credited it with variance analysis and gaming detection; that claim was false against the checked-in file. Layer 2 now names the runner that actually implements it, and the aggregate statistics that claim referred to are produced by `aggregate_benchmark.py` over multiple runs, not by any single-run script. Full contract for the Layer-2 runner: [`scenario-eval-contract.md`](scenario-eval-contract.md).

Supplementary: **Cross-skill false-positive detection** via `scripts/run_eval_audit.py` — surfaces trigger-set overlaps between the new skill and existing skills. Unique to the PMO harness; not present in Anthropic's out-of-box scaffolder.

---

## Script Inventory (preserved from skill-creator)

All scripts live at `scripts/` within this skill directory. Preserved via `git mv`; no content changes in the refactor scope.

| Script | Role | Invocation pattern |
|---|---|---|
| `run_eval.py` | **Trigger detection only** — runs each query and reports whether the skill fired; passes on a trigger rate above a threshold. Computes no output score, reads no `assertions[]`, invokes no judge | `python -m scripts.run_eval --skill-path <path> --eval-set <eval-set.json>` |
| `run_scenario_eval.py` | **Output scoring** — grades a suite's `assertions[]` against a committed fixture through a closed declarative predicate vocabulary, emits `grading.json`, and carries a suite-level non-triviality control. Not preserved from skill-creator; added to execute the assertion-grading path the schema had declared and left inert. Contract: [`scenario-eval-contract.md`](scenario-eval-contract.md) | `python -m scripts.run_scenario_eval --suite <evals.json> [--fixture <path>] [--fail-under <float>]` |
| `run_loop.py` | Description-trigger optimization loop (60/40 train/test, up to 5 iterations) | `python -m scripts.run_loop --eval-set <eval-set.json> --skill-path <path> --model <model-id> --max-iterations 5` |
| `run_eval_audit.py` | Cross-skill trigger audit (false-positive detection across the suite) | `python -m scripts.run_eval_audit --skills-dir release/skills/` |
| `aggregate_benchmark.py` | Aggregates per-iteration benchmark.json; produces benchmark.md | `python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>` |
| `improve_description.py` | Proposes description rewrites based on failed trigger queries | Used internally by `run_loop.py` |
| `package_skill.py` | Produces `.skill` package (for skills that are packaged; refiner itself is not) | `python -m scripts.package_skill <path/to/skill>` |
| `quick_validate.py` | Pre-package sanity check (frontmatter parses, required files present) | `python -m scripts.quick_validate <path/to/skill>` |
| `generate_report.py` | HTML benchmark report (human-readable aggregation) | Used internally by `aggregate_benchmark.py` |
| `utils.py` / `__init__.py` | Shared helpers | Imported by above |

---

## Agent Inventory (preserved from skill-creator)

`agents/` subdirectory contains subagent definitions invoked during eval grading.

| Agent | Role |
|---|---|
| `grader.md` | Assertion grading subagent — evaluates each assertion against run outputs, writes `grading.json` |
| `comparator.md` | Blind A/B comparison — independent grader with no knowledge of which version is "new" vs. "old"; used when user requests rigorous between-version comparison |
| `analyzer.md` | Analyst pass — reads benchmark.json and surfaces patterns aggregate stats hide (non-discriminating assertions, high-variance evals, time/token trade-offs) |

---

## Viewer

`eval-viewer/generate_review.py` + `eval-viewer/viewer.html` — unchanged from skill-creator. Renders:
- **Outputs tab:** one eval at a time; prompt, produced output files, previous-iteration output (N ≥ 2), formal grades (if graded), feedback textbox
- **Benchmark tab:** pass-rate per assertion, mean ± stddev, delta between with-skill vs. baseline runs, analyst observations

Launch pattern:
```bash
nohup python <skill-path>/eval-viewer/generate_review.py \
  <workspace>/iteration-N \
  --skill-name "<skill-name>" \
  --benchmark <workspace>/iteration-N/benchmark.json \
  > /dev/null 2>&1 &
VIEWER_PID=$!
```

For iteration ≥ 2, add `--previous-workspace <workspace>/iteration-<N-1>`.

Cowork / headless environments: use `--static <output_path>` to write a standalone HTML file; feedback downloads as `feedback.json` on "Submit All Reviews" click.

---

## Assets

`assets/eval_review.html` — description-optimization HTML review template. Used during description-trigger optimization to let the user review the 20 candidate trigger queries before running `run_loop.py`.

Placeholders:
- `__EVAL_DATA_PLACEHOLDER__` → JSON array of eval items, substituted into the inert `<script type="application/json" id="eval-data">` block and read via `JSON.parse(el.textContent)` (data context, not executable script). The filler MUST neutralize `<` in the emitted JSON so a `</script>` sequence cannot terminate the block early, per `core/standards/domain-best-practices/software.md` §Security → Output encoding.
- `__SKILL_NAME_PLACEHOLDER__` → skill's name
- `__SKILL_DESCRIPTION_PLACEHOLDER__` → current description

Write to `/tmp/eval_review_<skill-name>.html`; open via `open`. User edits, toggles should-trigger, exports to `~/Downloads/eval_set.json`.

---

## Schemas reference

`references/schemas.md` — preserved from skill-creator — documents:
- `evals.json` — eval set schema (id, name, prompt, expected_output, files, assertions). Graded statements are read from `assertions[]`; the optional `assertions[].check` predicate is what the output-scoring runner executes
- `grading.json` — per-run grading results (expectations array with `text` / `passed` / `evidence` fields — exact field names required by viewer). **Two producers:** the grader subagent writes the full object, the output-scoring runner writes the deterministic subset
- `references/scenario-eval-contract.md` — the output-scoring runner's own contract: the scenario schema, the closed predicate vocabulary, the non-triviality control, the command-line signature and the closed exit-code set. Written so a scenario author can add a suite without reading the runner's source
- `benchmark.json` — aggregated per-assertion pass rates with mean ± stddev
- `timing.json` — per-run timing (`total_tokens`, `duration_ms`, `total_duration_seconds`)
- `feedback.json` — user feedback from viewer "Submit All Reviews"

Viewer rendering depends on exact field names. Changes to schema require corresponding viewer updates.

---

## Variance Analysis and Gaming Detection

**These are properties of the ACROSS-RUN aggregate, not of any single run.** `aggregate_benchmark.py` collects each run's `grading.json` and computes the statistics below; `analyzer.md` reads the result and surfaces the patterns. Neither `run_eval.py` nor `run_scenario_eval.py` computes a standard deviation — a single run has nothing to vary against. This section previously attributed the whole set to `run_eval.py`, which grades triggers and produces none of it.

Per-assertion statistics across multiple runs:

- **Mean pass rate** — `pass_count / total_runs`
- **Standard deviation** — flags high-variance assertions as "possibly flaky"
- **Non-discriminating assertions** — assertions that always pass regardless of skill presence; flagged as "skill-independent" (useless for measuring skill value)
- **Gaming detection** — if an assertion passes at 100% on the with-skill runs but also 100% on the baseline, the skill is not doing the work — flag for re-draft

Interpretation rule: an assertion with high mean + low stddev is a signal. High mean + high stddev is a warning (may be random). Low mean regardless of stddev is a fail.

---

## Blind A/B Protocol

Invoked when the user asks "is the new version actually better?" or when Refine-Existing workflow detects a regression risk.

1. Snapshot the current SKILL.md (`cp -r <skill-path> <workspace>/skill-snapshot/`) before editing.
2. Apply refiner changes to the live skill.
3. Spawn `agents/comparator.md` as an independent grader given both outputs without labels.
4. Comparator produces a winner determination + rationale.
5. Analyst pass via `agents/analyzer.md` explains why the winner won.

Decision rule: if blind A/B shows the new version wins on ≥ 60% of evals with confidence ≥ MEDIUM, keep the new version. Else keep current and report regression to user.

---

## Description-Trigger Optimization Loop

End-to-end invocation pattern:

1. **Generate 20 eval queries** — 8–10 should-trigger, 8–10 should-not-trigger. Each query is realistic (concrete context, specific detail) rather than abstract.
2. **Review with user** via `assets/eval_review.html` — user edits queries, toggles should-trigger, adds / removes entries.
3. **Save eval set** to `<workspace>/trigger-eval.json`.
4. **Run the loop:**
   ```bash
   python -m scripts.run_loop \
     --eval-set <workspace>/trigger-eval.json \
     --skill-path <path-to-skill> \
     --model <model-id-powering-this-session> \
     --max-iterations 5 \
     --verbose
   ```
5. **Apply `best_description`** from the returned JSON output to the skill's frontmatter (only if improvement delta exceeds the configured threshold).
6. **Show user before/after** and report iteration scores.

The loop splits 60/40 train/test; each query runs 3× for reliable trigger-rate measurement; best_description is selected by test score (not train) to avoid overfitting.

---

## Historical Regression Tracking

Workspace convention:

```
release/skills/<skill-name>-workspace/
├── iteration-1/
│   ├── benchmark.json
│   ├── grading.json
│   ├── feedback.json
│   ├── timing.json
│   ├── eval_metadata.json (one per eval)
│   ├── run_loop_output.json
│   └── eval-<ID>/
│       ├── with_skill/outputs/
│       └── without_skill/outputs/ (or old_skill/outputs/)
├── iteration-2/...
```

Multi-iteration persistence enables regression detection: iteration N's `benchmark.json` `pass_rate` must not drop below iteration N−1's without rationale. The refiner compares automatically when Refine-Existing workflow runs.

This is the PMO-specific answer to "history.json" — per-iteration isolation rather than a single running log. Makes it easy to diff two specific iterations without parsing a monolithic file.

---

## Follow-ups (filed as issues, not in current scope)

- Parameterize `run_loop.py`'s 60/40 train/test split (currently hardcoded). Filed as a follow-up candidate.
- Author unit tests for `run_eval.py`, `run_loop.py`, `run_eval_audit.py`. Filed as a follow-up candidate.
- Anthropic scaffolder version-compat strategy — if Anthropic changes scaffolder output format, refiner's injection could silently misfire. Filed as a follow-up candidate.
- Extract `run_eval_audit.py`'s cross-skill logic into a reusable module if a second skill needs it. Filed as a follow-up candidate.
