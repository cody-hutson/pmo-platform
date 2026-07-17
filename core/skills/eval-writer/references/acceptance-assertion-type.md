---
title: The `acceptance` Assertion Type
purpose: Reference for the eval-schema acceptance assertion type — the sixth value of the evals[].assertions[].type open enum and how it is authored.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# The `acceptance` assertion type

The **`acceptance`** assertion type is the sixth value of the eval-schema `evals[].assertions[].type` open enum:

```
structural | judgment | resolution | non-triviality | read-only | acceptance
```

It grades **"does this satisfy the stated requirement?"** — not "does this meet quality standards?" (that is `judgment`) and not "is this mechanically present?" (that is `structural`). It ingests a GitHub Issue body's acceptance-criteria list, grades each criterion against the PR content, and rolls the per-criterion verdicts up to a release-level **acceptance score**. It is the machine-applicable executor of the Stage-8 acceptance machinery whose *process* is defined in [`release/references/pipeline/stage-08-qa-testing.md`](../../../../release/references/pipeline/stage-08-qa-testing.md) (the Stage-8 doc defines the verdict enum and the acceptance-review process; this type is its assertion-level executor).

Like the five incumbent types, `acceptance` is a **grader-honored contract** — no code enforces the type enum today (there is no validator on `assertions[].type`); the grading semantics live in prose that the grader agent honors, exactly as `structural` and `judgment` do. This doc is the schema-authority home for the type's contract.

---

## 1. Grading model — two judgments per criterion

The `acceptance` type grades each criterion with **two separate judgments** (this is the durable kernel recorded in [ADR-071](../../../ADRs/ADR-071-acceptance-assertion-type.md)):

1. **Gradability-class judgment** — *can this criterion be graded as-written against this PR?* One of four classes:
   - **gradable** — the criterion is sound, applicable, and the PR is in scope to satisfy it.
   - **not-applicable** — the criterion's scope moved out of this PR (a valid non-commitment).
   - **needs-reinterpretation** — the criterion text is stale or ambiguous; grading requires re-reading intent.
   - **blocked-upstream** — the criterion depends on an upstream issue's undelivered output.
2. **Binary-satisfaction judgment** — *for a **gradable** criterion only,* does the PR content satisfy it? A single **binary PASS/FAIL** call (with a `PARTIAL` refinement when part is satisfied and an unmet remainder exists).

The binary-satisfaction judgment is **only** made when the gradability-class is `gradable`. When the class is one of the three non-gradable classes, no binary call is made — the criterion carries a drift verdict and a mandatory `Drift-rationale:` instead.

**Why two judgments, not one native six-way call.** A single six-way LLM judge is a six-point scale — it reintroduces the middle-cluster and verbosity bias that binary grading exists to remove (the eval-writer consensus rejects mid-scale scoring; see `## Design rationale` below). Separating "is it gradable?" from "is it satisfied?" keeps the *satisfaction* decision binary (clean precision/recall against human labels) while still emitting the drift-aware six-value enum the Stage-8 process requires. The two judgments **project** to the Stage-8 enum via the deterministic table in §3 — the enum is a projection of the two judgments, not a native scale.

## 2. AC-ingestion parse contract (issue body → per-criterion list)

Parsing is **grader-side** — the grader reads the issue body via `gh issue view <N>`, consistent with how the grader already reads transcripts and outputs. No parser script ships with this type (see §6). Named parse rules:

| Rule | Parse behavior |
|---|---|
| **P1 — Source block** | Ingest ONLY the list items under the issue body's `## Acceptance Criteria` **or** `## Completion condition (verifiable)` H2 (both are observed live). The first matching H2 wins; if both are present, union in document order. |
| **P2 — Item shape** | Each GitHub task-list line (`- [ ] <text>` or `- [x] <text>`) is one criterion. Plain `-` / `*` bullets under the block are also criteria (the checkbox is optional). Nested sub-bullets attach to their parent as detail, not as separate criteria. |
| **P3 — Method extraction** | An inline `(method: …)` / `(verified: …)` / trailing `— method:` clause is captured as the criterion's `grading_method` hint. Absent → the grader infers the method from PR content. |
| **P4 — Identifier** | Assign `AC-N` in document order (1-based). Stable across re-grades (order-derived, not content-derived). Integration ACs, when present, use `INT-N` (a disjoint namespace). |
| **P5 — Drift tolerance** | A criterion whose text references a renumbered issue or a moved path is graded on **existence / intent**, not literal digit-match; a hard reference to an absent target becomes a candidate `FLAG-UPSTREAM` or `N/A-WITH-RATIONALE`, never a silent `NOT MET`. |
| **P6 — Empty / none** | Zero criteria under the block → the eval emits a single `structural` assertion "issue body exposes a parseable AC block" and the acceptance score is `N/A` (no criteria to grade), surfaced explicitly (not `0.0`). |

## 3. Verdict-projection table (the two judgments → the Stage-8 §5 enum)

The Stage-8 verdict enum is the SSOT — this type is a strict **consumer** of it and authors **zero** new verdict values. The enum (six values, per `stage-08-qa-testing.md` §5):

```
MET | NOT MET | PARTIAL | N/A-WITH-RATIONALE | REINTERPRET-WITH-RATIONALE | FLAG-UPSTREAM
```

The two judgments (§1) project to it deterministically:

| Gradability-class | Binary-satisfaction | Stage-8 §5 verdict emitted | Required field |
|---|---|---|---|
| gradable | PASS (fully satisfied) | `MET` | evidence |
| gradable | FAIL (not satisfied; criterion sound) | `NOT MET` | evidence + `Severity: Blocker \| Warning` |
| gradable | PARTIAL (part satisfied; unmet remainder) | `PARTIAL` | evidence + unmet-remainder note (keys the Stage-8 Step-0 gate by the remainder) |
| not-applicable | — (no binary call) | `N/A-WITH-RATIONALE` | `Drift-rationale:` |
| needs-reinterpretation | — (no binary call) | `REINTERPRET-WITH-RATIONALE` | `Drift-rationale:` |
| blocked-upstream | — (no binary call) | `FLAG-UPSTREAM` | `Drift-rationale:` + routes Tier-1 [ADJUST] / Tier-2 [SCOPE CHANGE] |

The first three (`MET / NOT MET / PARTIAL`) are the binary-gate outputs of a **gradable** criterion. The last three (drift verdicts) are emitted **only** when the criterion cannot be graded as-written; they carry the mandatory `Drift-rationale:` field and are **out of the Stage-8 Step-0 fix-now gate** (per `stage-08-qa-testing.md` §5). `FLAG-UPSTREAM` routes Tier-1/Tier-2 per the Inter-Stage Feedback Protocol, NOT the Lane-2 QA→DT return.

## 4. Acceptance-score roll-up — ALL-DRIFT-OUT

The score is **all-drift-out**: all three drift verdicts leave the denominator (uniform with `stage-08-qa-testing.md` §5, where every drift verdict is out-of-gate). This is a net-new formula the type introduces — the Stage-8 process defines the verdict enum, not the score.

```
acceptance_score(issue)   = count(MET) / ( total_criteria − count(N/A-WITH-RATIONALE)
                                                          − count(REINTERPRET-WITH-RATIONALE)
                                                          − count(FLAG-UPSTREAM) )

acceptance_score(release) = Σ count(MET) over all issues
                            / ( Σ total_criteria − Σ count(drift-class) ) over all issues
```

- **`PARTIAL` counts as 0 in the numerator** (not 0.5) — preserves binary discipline. A `PARTIAL`'s unmet remainder is separately keyed to the Stage-8 Step-0 gate, so half-credit would double-count.
- **`NOT MET` counts as 0** in the numerator (a gradable, unsatisfied commitment stays in the denominator).
- **All three drift verdicts** (`N/A-WITH-RATIONALE` / `REINTERPRET-WITH-RATIONALE` / `FLAG-UPSTREAM`) are removed from **both** numerator and denominator — none is a gradable commitment.
- **Score is RECORDED, not GATED** at authoring time (mirrors the stage-gate `escape_rate` "recorded, not gated" convention). The **verdict** gates (Stage-8 Step-0 fixes NOT MET now); the **score** is a fitness signal the Acceptance Report renders.
- Emitted into `grading.json` `summary` as a sibling of `pass_rate`: `acceptance_score` plus `acceptance_verdicts: {MET, NOT_MET, PARTIAL, NA, REINTERPRET, FLAG_UPSTREAM}` counts.

> **Denominator note.** This all-drift-out denominator is the LOCKED formula (scope-lock, 2026-07-03). It differs from a "remove only N/A" variant: `REINTERPRET-WITH-RATIONALE` and `FLAG-UPSTREAM` also leave the denominator, matching the Stage-8 §5 treatment where all drift verdicts sit out of the gate uniformly.

## 5. Acceptance-matrix columns (the acceptance-report co-design contract)

The acceptance matrix that the acceptance-report template renders is the per-criterion output of this type. These are the **stable, machine-parseable** columns (verdict/score fields anchored verbatim to the Stage-8 §5 enum) — the report template renders exactly these so the report and the framework agree:

| Column | Values / shape | Source |
|---|---|---|
| `AC-ID` | `AC-N` (or `INT-N` for integration ACs) | P4 (order-derived, stable) |
| `Criterion` | the AC item verbatim (the contractual text) | issue body (P1/P2) |
| `Verdict` | one of the six Stage-8 §5 values | §3 projection |
| `Evidence` | what the grader found in PR content (cite/quote) | grader output |
| `Severity` | `Blocker \| Warning` — **present only when `NOT MET`** | §3 |
| `Drift-rationale` | required-when-present — populated **only** for the three drift verdicts | §3 |
| `Disposition` | `fix-now \| defer \| accept` — the Stage-8 Finding-Disposition axis (operator-rendered; advisory in the matrix) | Stage-8 §5 Finding Disposition Framework |

**Footer roll-up fields** (from §4): `acceptance_score` (all-drift-out) + `acceptance_verdicts` per-verdict counts. Parseable-row contract (reusing the machine-readable result schema from the closed result-tracking work): the stable headers above + one row per criterion + a machine block mirroring `grading.json` `summary.acceptance_*`.

## 6. Runner integration — DOC-ONLY

**This type ships as a documentation + schema + grader-honored contract. No runner code is wired in this change.**

- **Why doc-only.** The checked-in `release/skills/pmo-skill-refiner/scripts/run_eval.py` is a **trigger-evaluation** harness — it consumes `{query, should_trigger}` and tests whether a skill's description causes Claude to trigger. It does **not** read `assertions[]` or `expected_output`. The assertion-grading path (`assertions[]` → the grader agent → `grading.json`) that the framework docs attribute to `run_eval.py` is documented but not present in that runner. Wiring a new type into a runner that does not grade `assertions[]` at all would be building on absent substrate.
- **What this change ships:** (1) the `acceptance` value in the type enum (documented here + referenced from `SKILL.md` + `rubric-templates.md`); (2) this contract (parse rules, two-judgment grading, projection table, all-drift-out roll-up); (3) a worked-example `acceptance`-type assertion set in the Stage-8 stage-gate eval set (`evals/stage-gates/stage-08-qa-testing/evals.json`) with a fixture issue (`evals/fixtures/acceptance-sample-issue.md`) as the discoverable specimen.
- **What this change does NOT ship:** any change to `run_eval.py` execution code; any parser script; any `grading.json` writer. Those belong to the framework-**consumer** work (the assertion-grading runner wiring is its own concern, out of this milestone's scope, and blocked on resolving the trigger-vs-assertion runner drift). This is the natural substrate the consumer milestone must resolve before any runtime execution of the type.

## Design rationale

The load-bearing decision is **how a binary-judge grader emits the six-value Stage-8 enum**. Three candidates were weighed:

| Criterion | Native six-way judge | **Two judgments → projection (SELECTED)** | Ordinal 1–4 |
|---|---|---|---|
| Binary-by-default (resists verbosity / middle-cluster bias) | violates — a six-way judge is a six-point scale | preserves — the *satisfaction* call is binary | permitted only when ordinal is genuinely needed; acceptance is binary-natural |
| Stage-8 §5 verbatim alignment | emits enum directly | projects to enum verbatim | 1–4 is not the Stage-8 enum; needs a lossy second map |
| Drift-verdict handling | mixed into the six-way call (conflates "ungradable" with "not met") | isolated behind the gradability judgment → clean `Drift-rationale:` | no natural drift band |
| Calibration tractability (α/κ vs humans) | six-way inflates disagreement | binary gives clean precision/recall per class | four-way middling |

**Survivor: two judgments → projection.** It is the only option that satisfies both governing consensuses simultaneously — binary-judge discipline (the satisfaction call is PASS/FAIL) **and** verbatim Stage-8 enum alignment (the projection emits the six values without inventing any). The drift verdicts are cleanly isolated behind the gradability-class judgment rather than smeared into a single multi-way judgment.

## Where the type lives

- **This doc** — the type's full contract (schema authority for `acceptance`).
- `SKILL.md` § Output format / assertion-type discussion — names `acceptance` as the AC-ingesting type + points here.
- `rubric-templates.md` — the acceptance-grading rubric clause (binary satisfaction + gradability pre-check + all-drift-out score).
- `evals/stage-gates/stage-08-qa-testing/evals.json` — the worked-example `acceptance`-type assertion set (ADR-067 home).
- `evals/fixtures/acceptance-sample-issue.md` — the fixture issue the worked example grades.
- [ADR-071](../../../ADRs/ADR-071-acceptance-assertion-type.md) — the durable decision kernel (two-judgment grading projected to the Stage-8 enum).
