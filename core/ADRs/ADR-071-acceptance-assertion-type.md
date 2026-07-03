<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-071 — Acceptance assertion type: two-judgment grading (gradability-class + binary satisfaction) projected to the Stage-8 verdict enum"
status: Accepted
date: 2026-07-03
release: 84-executable-acceptance-testing
deciders: "operator (Collective Review scope-lock 2026-07-03) + Stage 5 Solutioning spoke (Principal Engineer — Architecture) + Collective Review scope-lock"
tags: [eval-framework, eval-writer, acceptance-assertion, stage-08, qa-testing, verdict-enum, two-judgment-grading, binary-judge, drift-verdict, acceptance-score, core, knowledge-architecture]
source_observations:
  - "Stage 8's process is fully defined in release/references/pipeline/stage-08-qa-testing.md — the per-criterion verdict enum (MET / NOT MET / PARTIAL / N/A-WITH-RATIONALE / REINTERPRET-WITH-RATIONALE / FLAG-UPSTREAM), three-lane routing, the acceptance matrix — but its own gap log states the machine-applicable assertion type that ingests AC from a GitHub issue, grades each criterion, and aggregates an acceptance score does not exist. The eval home carries structural/judgment assertion types but no acceptance type that ingests issue AC. #218 builds that executor."
  - "Two governing consensuses are in tension. The eval-writer consensus (A-04) is binary judges by default — a multi-point LLM scale inflates verbosity and middle-cluster bias. Stage-8 §5 requires a SIX-value drift-aware enum. A single native six-way judge would satisfy Stage-8 but violate the binary discipline; a bare binary judge would satisfy the discipline but not emit the drift-aware enum. The reconciliation is the non-obvious, cross-cutting decision this ADR records."
  - "The score is net-new, not Stage-8-verbatim. Stage-8 §5 defines the verdict enum, not an acceptance-score formula. The scope-lock (2026-07-03) fixed an ALL-DRIFT-OUT denominator — all three drift verdicts leave both numerator and denominator, uniform with the §5 out-of-gate treatment — as a decision distinct from the enum it consumes."
---

# ADR-071 — Acceptance assertion type

## Status

**Accepted.** Operator-ratified at this release's Collective Review scope-lock (2026-07-03) — the Status-enum gate the core-ADR README names ("Operator-ratified at Collective Review or equivalent gate"). Authored at Stage 6 Engineering per the Stage-6 ADR-authoring precedent, as part of the `84-executable-acceptance-testing` milestone (#204). The deciding gates already ran: the Stage-5 Solutioning design (#3145) that reconciled the two governing consensuses, and the Collective Review scope-lock that locked the two-judgment framing and the all-drift-out score. It flips to Accepted at authoring because the ratification is already on record — consistent with how the sibling eval-framework ADR (ADR-067) set its status at its Collective Review gate.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/` (max ADR-070 at the authoring commit), resolved with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. Referenced downstream **by slug**, never by number. Extended or reversed only by a successor / superseding ADR — never by an in-place edit.

## Subordinate to

[ADR-067 — Stage-gate eval-set home](ADR-067-stage-gate-eval-set-home.md). This ADR homes the acceptance type's worked-example eval set at the ADR-067 location (`core/skills/eval-writer/evals/stage-gates/stage-08-qa-testing/evals.json`) and adds no competing home. It records the *grading contract* of a new `assertions[].type` value; ADR-067 records *where stage-gate eval sets live*.

## Context

Stage 8 QA validates a built release against its acceptance criteria — "does this satisfy the stated requirement?" as opposed to Stage 7's "does this meet specs?". The Stage-8 *process* is fully specified in `release/references/pipeline/stage-08-qa-testing.md`: the six-value per-criterion verdict enum (§5), the three-lane routing (Phase C), the Finding Disposition Framework, the acceptance matrix and acceptance score as §6 Outputs. But that same doc's §9 Gap Summary records that the machine-applicable **assertion type** — the executor that ingests a GitHub issue's AC list, grades each criterion, and rolls up an acceptance score — does not exist. The live eval home carries five assertion types (`structural`, `judgment`, `resolution`, `non-triviality`, `read-only`) but none that ingests issue AC.

The design question is **how a binary-judge grader emits the six-value Stage-8 enum**. Two governing consensuses are in tension:

- **eval-writer, binary-by-default (A-04):** an LLM judge on a multi-point scale inflates verbosity bias (longer-wins) and clusters in the middle; binary judgment rewards concision and gives clean precision/recall against human labels.
- **Stage-8 §5, six-value drift-aware enum:** acceptance grading must distinguish `MET` / `NOT MET` / `PARTIAL` from the three *drift* verdicts (`N/A-WITH-RATIONALE`, `REINTERPRET-WITH-RATIONALE`, `FLAG-UPSTREAM`) that arise when a criterion cannot be graded as-written.

A single native six-way LLM judge satisfies Stage-8 but violates the binary discipline (a six-way call is a six-point scale). A bare binary judge satisfies the discipline but cannot emit the drift-aware enum. The reconciliation is non-obvious and cross-cutting (it touches the eval-schema contract consumed by the grader, eval-writer, the acceptance-report template of #217, and the QA acceptance-review mode of #219) — meeting the ADR threshold.

## Decision

**The `acceptance` assertion type grades each criterion with TWO judgments, and the six-value Stage-8 verdict enum is a deterministic PROJECTION of the two judgments — not a native six-way score.**

1. **Judgment 1 — gradability-class.** *Can this criterion be graded as-written against this PR?* One of four classes: `gradable`, `not-applicable`, `needs-reinterpretation`, `blocked-upstream`.
2. **Judgment 2 — binary satisfaction** (made **only** when the class is `gradable`). *Does the PR content satisfy the criterion?* A binary PASS / FAIL call, with a `PARTIAL` refinement when part is satisfied and an unmet remainder exists.

The two judgments project to the Stage-8 §5 enum deterministically: `gradable`+PASS → `MET`; `gradable`+FAIL → `NOT MET` (+ Severity); `gradable`+PARTIAL → `PARTIAL`; `not-applicable` → `N/A-WITH-RATIONALE`; `needs-reinterpretation` → `REINTERPRET-WITH-RATIONALE`; `blocked-upstream` → `FLAG-UPSTREAM`. The three drift verdicts carry a mandatory `Drift-rationale:` and are out of the Stage-8 Step-0 fix-now gate. The type authors **zero** new verdict values — it is a strict consumer of the Stage-8 §5 enum (which stays the SSOT).

**Framing note (the durable kernel).** This is explicitly **two judgments (gradability-class + binary satisfaction)**, NOT "one binary call projected to six values". The gradability pre-check is a first-class judgment that isolates the drift verdicts cleanly; only after a criterion is judged `gradable` is the binary satisfaction call made. Recording the pair — not a single binary — is what keeps the drift verdicts from being smeared into the satisfaction decision.

**Acceptance score — ALL-DRIFT-OUT.** `acceptance_score = count(MET) / (total − count(N/A-WITH-RATIONALE) − count(REINTERPRET-WITH-RATIONALE) − count(FLAG-UPSTREAM))`. `PARTIAL` and `NOT MET` count 0 in the numerator; all three drift verdicts leave both numerator and denominator (uniform with the §5 out-of-gate treatment). The score is **recorded, not gated** at authoring time — the *verdict* gates (Stage-8 Step-0), the *score* is a fitness signal. This formula is net-new (the Stage-8 process defines the enum, not the score).

**Scope — DOC-ONLY runner.** The type ships as a documentation + schema + grader-honored contract (identical in kind to how `structural`/`judgment` operate — no code enforces the type enum today). No runner code is wired: the checked-in `run_eval.py` grades *triggers*, not `assertions[]`, so wiring a new type into it would build on absent substrate. Runner wiring is deferred to the framework-consumer work.

## Consequences

- **Positive.** The satisfaction decision stays binary (resists the biases A-04 names) while the emitted enum matches Stage-8 §5 verbatim. Drift verdicts are cleanly isolated behind the gradability judgment, each carrying its `Drift-rationale:`. The type reuses the live `{text, type}` assertion schema, the grader's grading loop, and the ADR-067 stage-gate eval home — no new runner, schema file, or abstraction. Reversibility CHEAP (delete the type's doc rows + grader clause; no data migration).
- **Negative / residual.** The type is defined but not runner-executed (DOC-ONLY) — a consumer expecting runtime grading before the assertion-grading runner exists would find the type inert. Mitigated: the type is a grader-honored contract like its five siblings; the consumer milestone (#219-adjacent runner wiring) resolves the trigger-vs-assertion runner drift before any runtime execution. Calibration of the projection against human verdicts (α/κ) is the consumer milestone's concern (recorded-not-gated at authoring).
- **Boundary (R-1, ratified).** #218 owns the framework — the type, the parse contract, the two-judgment rubric, the all-drift-out score, the grader clause, and the worked-example eval set. #219 (milestone #161) CONSUMES the framework as a QA acceptance-review mode and redefines nothing (no new verdict values, no new parse rules, no new score formula). The cleave line: a change to *what the acceptance verdict / parse / score IS* → #218; a change to *the QA-auditor mode that runs it* → #219.

## Alternatives considered

- **Native six-way LLM judge** (grader directly outputs one of the six values). Rejected: a six-way call is a six-point scale — it reintroduces the verbosity / middle-cluster bias binary grading removes, inflates α/κ disagreement, and conflates "ungradable" with "not met".
- **Ordinal 1–4 judge mapped to verdicts.** Rejected: 1–4 is not the Stage-8 enum (needs a lossy second map), has no natural drift band, and acceptance is binary-natural (not ordinal-required).
- **Remove-only-N/A score denominator.** Rejected at scope-lock in favor of ALL-DRIFT-OUT: `REINTERPRET-WITH-RATIONALE` and `FLAG-UPSTREAM` also leave the denominator, matching the §5 treatment where all drift verdicts sit out of the gate uniformly.

## References

- Type contract: [`core/skills/eval-writer/references/acceptance-assertion-type.md`](../skills/eval-writer/references/acceptance-assertion-type.md)
- Grading rubric: `core/skills/eval-writer/references/rubric-templates.md` § Acceptance-grading rubric
- Verdict-enum SSOT: [`release/references/pipeline/stage-08-qa-testing.md`](../../release/references/pipeline/stage-08-qa-testing.md) §5
- Worked example: [`core/skills/eval-writer/evals/stage-gates/stage-08-qa-testing/evals.json`](../skills/eval-writer/evals/stage-gates/stage-08-qa-testing/evals.json) + fixture `evals/fixtures/acceptance-sample-issue.md`
- Stage-gate eval home: [ADR-067](ADR-067-stage-gate-eval-set-home.md)

### Issue References

References #218 (parent — build acceptance assertion framework), #217 (the acceptance-report template renders this type's output), #219 (the QA acceptance-review mode consumes this framework), #430 (machine-readable result schema, reused for the parseable matrix row).
