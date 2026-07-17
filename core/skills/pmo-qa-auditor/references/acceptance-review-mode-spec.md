---
title: Acceptance-Review Mode Spec — pmo-qa-auditor Mode H
purpose: The detail spec for pmo-qa-auditor Mode H (Acceptance Review) — the per-criterion AC-verdict machinery, consumed from its canonical homes.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Acceptance-Review Mode Spec — pmo-qa-auditor Mode H

> Consumed by `SKILL.md` § Mode H. This doc carries the mode's detail; every
> machinery element below is CONSUMED from its canonical home — this file
> defines none of them.

## 1. Consumption map (anti-duplication contract)

| Machinery | Canonical home (SSOT) | Mode H's use |
|---|---|---|
| Per-criterion verdict enum (6 values) | `release/references/pipeline/stage-08-qa-testing.md` §5 Phase B | emitted verbatim; zero new values |
| AC parse rules P1–P6 · two-judgment grading · projection table · all-drift-out score | `core/skills/eval-writer/references/acceptance-assertion-type.md` §§1–4 | applied per criterion; score computed by applying §4, never re-defined |
| Acceptance-matrix columns (`AC-ID` / `Criterion` / `Verdict` / `Evidence` / `Severity` / `Drift-rationale` / `Disposition`) + machine block | `acceptance-assertion-type.md` §5 + `operations/templates/qa-acceptance-report-template.md` | rendered exactly; no added column |
| 3-lane routing · Finding Disposition Step-0 · Operator Override Record (5 fields) · PARTIAL keying | `stage-08-qa-testing.md` §5 Phase C + § Finding Disposition Decision Framework | applied; override record SURFACED, operator-authored |
| Drift-verdict selection criteria + `Drift-rationale:` | `release/governance/release-process.md` § AC-Drift Handling Protocol | applied for ungradable-as-written criteria |
| Runtime-Evidence Acceptance (behavioral AC) | `stage-08-qa-testing.md` § Runtime-Evidence Acceptance (+ `runtime-suite-selection-map.md` keying) | A8 Test-results consumed; `runtime-evidence:` recorded inside the Evidence cell |
| PR review-comment / iteration-context arrival (Phase D) | `stage-08-qa-testing.md` §5 Phase D + `release-process.md` § Inter-Stage Feedback Protocol (author-association trust boundary) | comment-shaped findings enter ONLY through that gated path; the mode defines no comment-ingest of its own |

## 2. Fitness-beyond-literal-AC rubric (net-new; renders the report's fitness section)

Three lenses, each producing 0..n findings:

1. **Intent-vs-letter** — does the delivered change satisfy what the issue was
   FOR (body "Why still open" / problem statement), not only the AC text? A
   met-the-letter-missed-the-point finding is a Lane-3 decision card (subjective
   AC / fitness question → operator).
2. **Operational value** — would the operator act on the delivered result
   without rework (the G5 standard applied at acceptance altitude)?
3. **Escape detection** — should Stage 7 have caught any NOT-MET found here?
   Each such finding is logged to the report's Stage-7 escape log.

Fitness findings NEVER alter per-criterion verdicts — they inform the
operator's Phase E overall verdict.

## 3. Ad-hoc (Cowork) invocation contract

Required inputs: issue number(s) + the artifact/PR to review. Without a Stage-7
Handoff Payload: entry validation degrades to {AC extractable + content
reviewable}; the report header carries `invocation: ad-hoc (no Stage-7
payload — escape log and runtime-evidence reads N/A)`. Missing inputs → ask
(≤ 5-question cap). Tier 2 (Recommend) in both contexts; the overall verdict
remains the operator's.

## 4. Evidence discipline

Per-criterion evidence comes from PR/artifact CONTENT (file:line cite or
quote). Never evidence: issue checkbox state, PR-description self-claims,
Stage-7 PASS, the AC text itself. Runtime evidence: the A8 Test-results row for
the mapped suite, cited inside the Evidence cell as
`runtime-evidence: <suite> <RESULT> (map row N, <run-ref>)`, or
`runtime-evidence: none (suite-skip | unmapped-domain)` when absent.

## 5. Mode A vs Mode H routing boundary

"Review this output / QA this" (quality-vs-contract, gate table) → Mode A.
"Acceptance review / grade the AC / per-criterion verdicts" (PR-vs-issue-AC,
acceptance matrix) → Mode H. "Acceptance sign-off" (program synthesis) →
`pmo-qa-lead` Mode 2, which composes this mode.
