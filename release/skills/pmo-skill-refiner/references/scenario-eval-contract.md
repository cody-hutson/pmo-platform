<!-- reference-durability: allow-link -->
# Scenario Eval Contract

## Purpose

The contract for the **output-scoring scenario runner** — `scripts/run_scenario_eval.py`.

This document is written so a second scenario author can add a suite **without reading the runner's source**. Everything a suite may declare is enumerated here, with its shape, its meaning, and what a wrong value does. If something you need is not here, it is not in the contract.

**What the runner is not.** It is not `scripts/run_eval.py`. That script is a *trigger* harness — it asks whether a skill's description causes the model to fire for a query, and passes on a trigger rate above a threshold. This runner asks whether a scenario's graded statements hold against a committed fixture, and passes on an output score. The two are independent, neither reads the other, and neither modifies the other.

**What the runner executes.** The eval-harness input schema and the `grading.json` report contract were both declared before any runner existed; the assertion-grading path from the assertion array through a grader to the report was a **grader-honored contract, not runner-executed**. This runner executes the **deterministic** half of that path. The model-judged half — the `judgment` and `acceptance` assertion types — remains grader-honored and is **not** executed by this runner.

---

## 1. The scenario schema (input)

A suite is the shipped eval-harness `evals.json` schema, **unmodified**, plus exactly **two optional fields**: `assertions[].check` and `assertions[].expect`.

```json
{
  "suite_name": "<string>",
  "description": "<string>",
  "fixture": "<path, relative to this suite file>",
  "control": { "empty_fixture": "<path, relative to this suite file>" },
  "evals": [
    {
      "id": 1,
      "name": "<slug>",
      "prompt": "<string>",
      "expected_output": "<string>",
      "files": ["<path>"],
      "assertions": [
        {
          "text": "<the graded statement, copied verbatim into the report>",
          "type": "structural | judgment | resolution | non-triviality | read-only | acceptance",
          "expected_value": "<optional — read by the resolves_to predicate>",
          "expect": "pass | fail",
          "check": { "kind": "<one of five>", "…": "…" }
        }
      ]
    }
  ]
}
```

| Field | Required | Meaning |
|---|---|---|
| `suite_name` | Yes | Copied into the report's provenance block. |
| `description` | Recommended | Free prose. Not read by the runner. |
| `fixture` | Yes, unless `--fixture` is passed | The document this suite scores. Path is relative to the suite file. |
| `control.empty_fixture` | Recommended | The non-triviality control arm — see § 3. |
| `evals[].assertions[].text` | Yes | The graded statement. Copied **verbatim** into the report. |
| `evals[].assertions[].type` | Yes | The existing open assertion-type enum. The runner does **not** branch on it; it branches on `check.kind`. The two agree by construction — see the mapping in § 2. |
| `evals[].assertions[].expected_value` | Conditional | Read by `resolves_to` when the check itself carries no `value`. |
| `evals[].assertions[].check` | **Optional** | The predicate. Its absence has a defined meaning — see § 4. |
| `evals[].assertions[].expect` | **Optional** | Which predicate outcome the suite expects. Closed two-value set, default `"pass"` — see § 1.1. |

**Every suite already in the corpus is valid input, unmodified.** `check` is optional, and an assertion without one is *ungraded* rather than failing. `expect` is optional, and its default is the identity — an assertion without one grades exactly as it did before the field existed. That is what makes both additive extensions rather than migrations.

### 1.1 `expect` — which outcome the suite expects

`expect` names the predicate outcome the suite **expects to observe**. The vocabulary is closed, and the default is the identity:

| `expect` | Graded outcome | Use it for |
|---|---|---|
| *omitted* / `"pass"` | the observed outcome, unchanged | every ordinary assertion |
| `"fail"` | the **negation** of the observed outcome | a **known-open defect** — a statement that is true of the corpus's intent and false of the tree today |

An unrecognized value is a usage error (exit 2), not a silent fallback to the default. Falling back would score a deliberately-expected failure as a real one and depress the rate with no visible cause — the opposite of what the field is for.

**Why the field exists.** A regression corpus gated at a `1.00` floor has, without it, exactly two ways to carry a known-open defect: an allowlist beside the corpus, or a loosened floor. Both hide the exception inside a number. An expected-FAIL assertion keeps the pass rate at the floor **and** keeps the exception legible — one named row in the report, and a named line on stdout.

**An `expect: "fail"` assertion that starts passing grades FAIL.** This is deliberate and it is the field's safety property. When the defect is fixed the predicate begins to hold, the graded outcome flips to FAIL, and the run says so in as many words: *the exception is stale, retire it in the same change that fixed it.* Without that rule an expectation is an allowlist entry that nobody ever removes.

**`expect` requires a `check`.** Declaring one on an assertion with no predicate is a usage error (exit 2), because an ungraded assertion computes no outcome for the expectation to hold against — an author who writes it believes the assertion is graded when it is not.

**`expect` is an input-only field.** It changes which boolean `expectations[].passed` carries; it adds **no key** to the report — see § 5.

---

## 2. `check.kind` — a closed five-value vocabulary

The set is **closed**. An unrecognized `kind` is a usage error (exit 2), not a failing assertion — a suite that names a predicate the runner does not implement is malformed, and reporting it as a low score would hide the defect inside a number.

The five members are derived by construction from the four **deterministic** values already in the assertion-`type` enum. They add no new semantics; they make executable the semantics the enum already declares.

| `check.kind` | Shape | Serves `type` | Passes when |
|---|---|---|---|
| `path_exists` | `{kind, target?}` | `structural` | the target file exists |
| `contains` | `{kind, target?, value}` | `structural` | `value` occurs in the target's text as a **literal substring** |
| `matches` | `{kind, target?, pattern, engine}` | `structural` | `pattern` finds a match in the target's text |
| `resolves_to` | `{kind, target?, path, value?}` | `resolution` | the structured `path` resolves in the target **and** its value compares equal |
| `unchanged` | `{kind, target?}` | `read-only` | the target is byte-identical before and after the run |

Two constraints are part of the contract, not implementation detail:

- **`contains` is literal only.** It never interprets its `value` as a regular expression. A suite that wants pattern semantics says so by using `matches`, so a regular expression can never end up silently evaluated as a substring or vice versa.
- **`matches` must name its engine in-band**, as `"engine": "python-re"`. Any other value is a usage error. An unnamed dialect is an ungradeable claim: the same pattern means different things to different engines, so a reader cannot tell what was asserted. Patterns are searched with multiline semantics, so `^` and `$` anchor to line boundaries.

### `target` — where a check reads

`target` is **optional**, and its default is the property that makes a suite reusable across fixtures.

| `target` value | Resolves to |
|---|---|
| *omitted* | **the fixture this run is scoring** |
| `"@fixture"` | the same thing, spelled out |
| a relative path | resolved **against the suite file's directory** (`../../references/foo.md` is legal) |
| an absolute path | used as given |

Because an omitted `target` follows the active fixture, one suite can be scored against a baseline fixture, a regressed fixture, and an empty control fixture with **no edit to the suite** — which is exactly what the discrimination check and the non-triviality arm need.

### `resolves_to` — path syntax and the comparison rule

`path` is a **dotted path** walked over the parsed fixture. A segment that parses as an integer indexes a sequence; every other segment is a mapping key. A miss at any depth is a clean miss — the check fails and says where. It never guesses and never partially resolves.

The resolved value is compared **as text** against `check.value`, or against the assertion's `expected_value` when the check carries none:

| Resolved value | Compared as |
|---|---|
| a string or number | `str(value)` |
| a boolean | `true` / `false`, lowercased |
| `null` | the empty string |
| a sequence | its members joined with `, ` — so `[0, 1, 2, 3]` compares against `"0, 1, 2, 3"` |
| a **mapping** | **not comparable** — the check fails and says so |

A `resolves_to` that carries neither `check.value` nor `expected_value` is a usage error.

### Fixture formats

`.json`, `.yaml`, and `.yml`. YAML support imports its parser lazily and, when that parser is unavailable, reports a **usage error (exit 2)** with an install hint — never a failing assertion, because a missing dependency is not a regression. A suite that wants zero optional dependencies uses `.json` fixtures; `resolves_to` is format-agnostic.

---

## 3. `control.empty_fixture` — the non-triviality arm

A suite may declare a **structurally empty** control fixture:

```json
"control": { "empty_fixture": "fixtures/empty.yaml" }
```

When present, the runner re-runs **every `resolves_to` check** against that fixture and requires **all of them to fail**. A resolution that still succeeds against an empty fixture is not reading the fixture at all — which would make every one of the suite's baseline passes unfalsifiable.

- **All fail** → the control PASSES; the run's verdict is decided by the graded assertions.
- **Any passes** → the control FAILS. The runner names each spurious assertion and the run **exits 1**, regardless of the pass rate. A suite that cannot discriminate does not get to report a green.
- **The active fixture *is* the control fixture** → the arm is skipped and says so. Comparing empty to empty measures nothing.

Write the control fixture with its **top-level keys present and their bodies empty**. Deleting the keys makes every path miss at depth 1, which tests less: with the keys present a path must miss at the leaf, so the arm exercises the resolver's full walk rather than its first step.

**This arm reads the raw predicate outcome, and `expect` is deliberately not applied to it.** The question the arm asks is *does this predicate actually read the fixture?* — a property of the predicate alone. Folding the suite's expectation in would let a suite declare `expect: "fail"` and thereby satisfy the control arm without its predicate ever touching the fixture, turning the one arm that proves a suite is falsifiable into the one place a suite could opt out of being falsifiable.

---

## 4. Ungraded assertions, and the denominator

**An assertion with no `check` is `ungraded`.** It leaves **both** the numerator and the denominator.

That is the platform's locked **all-drift-out** denominator, reused rather than invented — the same convention the acceptance assertion type applies to its non-gradable verdicts, so one arithmetic convention covers both graded types.

```
pass_rate = passed / (total − ungraded)
```

Two consequences worth stating plainly:

- **Adding un-predicated assertions to a suite cannot depress its pass rate.** This is what keeps every existing suite valid input, and it is what lets a suite carry a model-judged statement alongside deterministic ones without the deterministic score absorbing it.
- **A suite whose assertions are *all* ungraded produces no measurement.** See § 6.

**Ungraded is not the same thing as expected-FAIL, and the difference is the denominator.** An *ungraded* assertion leaves both sides of the quotient — nothing was measured. An *expected-FAIL* assertion stays in **both** sides: it is measured, it is graded, and while the defect it names is still open it counts toward the numerator. One says "no measurement exists here"; the other says "a measurement exists, and this is the value we expect it to have." A known-open defect encoded as ungraded would silently shrink the corpus; encoded as expected-FAIL it stays counted, stays named, and stays retirable.

Ungraded assertions do **not** appear in the report's `expectations[]` array, because every member of that array carries a boolean and an ungraded assertion has no boolean to carry. Their count is in the summary, and `--verbose` names them on stdout.

---

## 5. The report (output)

**The report is `grading.json` as defined in [`schemas.md`](schemas.md) § grading.json. This runner adds no second definition of it** — read that section for the field semantics. What is stated here is only *which subset this runner emits*.

| Emitted | Notes |
|---|---|
| `expectations[]` — `{text, passed, evidence}` | One row per **graded** assertion, in declaration order. `text` is the assertion's text verbatim. `passed` is the **graded** outcome — the observed outcome folded through `expect` (§ 1.1). `evidence` describes what the check **observed**; on an expected-FAIL row the observation is carried verbatim inside a sentence naming the expectation, so a reader sees both what happened and why it graded the way it did. |
| `summary` — `{passed, failed, ungraded, total, pass_rate}` | `ungraded` is this runner's addition to the summary object, alongside the existing counts. |
| `suite` — `{suite_name, fixture, sha, run_at}` | Provenance. `sha` is the **fixture's** content hash, short form — what makes a run reproducible against a fixture rather than against a path. `run_at` is UTC, ISO-8601. |

**`expect` adds no report key.** The field changes which boolean `passed` carries and appears nowhere in the emitted object. That is a constraint, not an omission: `expectations[]` rows are pinned in code by the benchmark aggregator and the eval viewer, so the runner keeps the emitted shape frozen and puts the expectation in the row's `evidence` prose plus a named stdout line. **A count of expected-FAIL assertions, with each one's text, prints to stdout when the count is non-zero** — that is where a CI reader sees the exception, without the report contract acquiring a second definition to carry it.

**Not emitted:** `execution_metrics`, `timing`, `claims`, `user_notes_summary`, `eval_feedback`. Those are grader-agent-specific. The benchmark aggregator reads each through a defaulted accessor, so their absence is tolerated — **do not stub them**.

**The read/write key asymmetry is inherited and deliberate.** The runner **reads** graded statements under `assertions[]` — what every typed suite in the corpus actually contains — and **writes** them under `expectations[]`, which the benchmark aggregator and the eval viewer pin in code. Renaming either side breaks a shipped consumer. The runner implements the mapping; it does not reconcile the two names.

**Reference the pass rate by its fully-qualified path** — the `pass_rate` field of the `summary` object. Three unrelated metrics in this corpus share the bare token `pass_rate`: a gate-criteria structural rate, an iteration-history rate, and this eval-grading rate. A consumer that matches the bare token cannot tell them apart.

`pass_rate` is rendered to four decimal places. A `--fail-under` comparison is made on the **exact quotient**, not on the rendered value — and a gate consumes this runner's **exit status**, never this field, so the rendering is a reader's convenience and is never a gate input.

---

## 6. Invocation

Run as a module from the skill root, matching every sibling in the Script Inventory:

```
python3 -m scripts.run_scenario_eval \
  --suite <path/to/evals.json>          # required
  [--out <path/to/grading.json>]        # default: alongside the suite file
  [--fixture <path>]                    # override the suite's declared fixture
  [--fail-under <float>]                # exit 1 when the pass rate is below this
  [--verbose]                           # per-assertion PASS/FAIL with evidence
```

### Exit codes — a closed four-value set

| Code | Meaning |
|---|---|
| `0` | Every gradable assertion passed, and — if `--fail-under` was given — the pass rate is at or above it. |
| `1` | At least one gradable assertion failed, **or** the pass rate is below `--fail-under`, **or** the non-triviality control did not hold. |
| `2` | Usage or environment error — unreadable or malformed suite, unknown `check.kind`, an unknown `expect` value, an `expect` declared on an assertion with no `check`, missing fixture, unnamed regular-expression engine, or a missing optional dependency for the fixture format in use. |
| `3` | **Nothing was gradable.** No report is written — see below. |

The set is closed and the codes are **distinguishable by design**: a below-floor result must never share a code with a runner error, because a gate that cannot tell "the corpus regressed" from "the runner crashed" reports the same red for both and teaches its reader to ignore it.

### `--fail-under` takes the threshold as data

The runner performs the comparison and sets the exit status. It does **not** know where the threshold is recorded, and a caller does not need the runner to know. A gate reads the floor from wherever it is recorded, passes it here, and consumes **only the exit status** — it never parses the report. That is what keeps exactly one definition of the report contract in the tree: a consumer that never reads a field cannot restate it.

### The zero-denominator rule

**When `total − ungraded == 0`, the runner writes no report file, prints a diagnostic naming the measurement state, and exits 3.**

This is forced by a property of the shipped consumer, not by preference. The benchmark aggregator reads the pass rate through a defaulted accessor whose default is `0.0`, and later performs arithmetic over the collected values. So:

- emitting `"pass_rate": null` raises a type error in the aggregator's statistics pass — it crashes a shipped consumer;
- **omitting** the key is read as `0.0` — absence silently reported as total failure, the exact anti-pattern the platform's probe discipline forbids;
- **writing no file** takes the aggregator's missing-file branch, which warns and skips the run — so a non-measuring run contributes nothing to the mean rather than entering it as a zero.

The last is the only faithful encoding the frozen contract admits, and it is why a corpus whose assertions are all ungraded **cannot** produce a green pass rate. It produces no pass rate at all, and a gate gets nothing to compare. The failure mode "ship a gate that always passes because it measures nothing" is made structurally unreachable rather than merely discouraged.

---

## 7. Adding a suite — the whole procedure

1. **Create the suite directory** under the owning skill's `evals/`, and write `evals.json` in the § 1 shape.
2. **Commit a baseline fixture** — the unregressed reference state — and point `fixture` at it.
3. **Commit a deliberately-regressed fixture** — the same document with specific values degraded. Regress *some* values, not all: a fixture in which everything fails proves nothing about which assertion caught what, and the unchanged values are what make the failures attributable.
4. **Commit a structurally-empty control fixture** and declare it under `control.empty_fixture`.
5. **Give each assertion a `check`**, choosing the `kind` from § 2. Leave `check` off any statement that genuinely needs a human or a model to grade — it will be reported as ungraded rather than silently failing.
5a. **Mark a known-open defect with `expect: "fail"`** (§ 1.1) rather than deleting the assertion or loosening the floor. Write the assertion's `text` as the statement you want to become true, and expect it to fail until it is. Retire the `expect` in the same change that fixes the defect — the run turns red the moment it starts passing, which is the reminder.
6. **Run it three ways and read all three:**
   - against the baseline — expect the pass rate at ceiling and exit 0;
   - against the regressed fixture (`--fixture`) — expect a **strictly lower** pass rate and exit 1;
   - confirm the control line reads `PASS`, meaning every resolution check failed against the empty fixture.
   A suite where the second run scores the same as the first is **not discriminating**, and its baseline passes are unfalsifiable.

---

## 8. Data flow

Producers and consumers of the report contract, so a change to any one of them can be traced to the others.

| Direction | Party | Reads / writes |
|---|---|---|
| Producer | `scripts/run_scenario_eval.py` (this runner) | **writes** `grading.json` — the § 5 subset, deterministically |
| Producer | `agents/grader.md` (the grading subagent) | **writes** `grading.json` — the full object, model-judged |
| Consumer | `scripts/aggregate_benchmark.py` | **reads** `summary.pass_rate`, `summary.passed`, `summary.failed`, `summary.total`; treats a missing file as a skipped run |
| Consumer | `eval-viewer/generate_review.py` | **reads** `expectations[]` for the per-assertion grade display |
| Consumer | a CI gate | **reads the exit status only** — never the report |

The last row is the one that matters most. A gate that consumes only the exit status cannot restate the report contract, so "exactly one definition of the contract exists in the tree" holds by construction rather than by discipline.

---

## References

- [`schemas.md`](schemas.md) — the authoritative definition of `evals.json`, `grading.json`, and the framework's other JSON contracts. The report fields are **cited** from there, never restated here.
- [`eval-framework.md`](eval-framework.md) — how the eval harness is invoked, the layer model, and the Script Inventory this runner joins.
- [`../../../../core/skills/eval-writer/SKILL.md`](../../../../core/skills/eval-writer/SKILL.md) — authors `evals.json` suites; owns the assertion-`type` enum this vocabulary maps onto.
- [`../../../../core/skills/eval-writer/references/acceptance-assertion-type.md`](../../../../core/skills/eval-writer/references/acceptance-assertion-type.md) — the locked all-drift-out denominator convention § 4 reuses.
- [`../../../../core/disciplines/evals/people-graph-consumption/run_consumption_eval.py`](../../../../core/disciplines/evals/people-graph-consumption/run_consumption_eval.py) — the prior deterministic runner whose three-layer structure (resolution / read-only / non-triviality) this contract generalizes. It implements that structure as hard-coded per-skill functions; § 3 is the declarative form.
