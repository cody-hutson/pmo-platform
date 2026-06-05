<!-- reference-durability: allow-link -->
# Stage 8: QA Testing

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Validate release quality from an independent acceptance perspective — the gate that asks "does this meet needs?" (vs. Stage 7's "does this meet specs?"). Produces an acceptance verdict with per-criterion evidence for human review.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | QA testing and acceptance review | Acceptance review against AC, not formal test execution |
| Governance Focus | Test execution, defect management | Acceptance matrix, fitness assessment, escape detection |
| Artifact Inputs | Test plans, test cases, build artifacts | Dev-tested PR, quality report from Stage 7, AC per issue |
| Artifact Outputs | Test results, acceptance sign-off | Acceptance report with per-criterion verdict, fitness assessment |

Key compression: Part 6 Stages 8-9 compressed. No formal test execution environment — acceptance review against AC using LLM-graded evaluation. Relationship to Stage 7: Stage 7 uses QA Auditor in review mode; Stage 8 uses acceptance mode.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Decision maker: Human operator | — | — | Tier 3 (renders acceptance verdict) |
| Acceptance reviewer (primary): QA Auditor Skill 11 | Acceptance review | Mode 2 | Tier 2 (Recommend) |
| Delivery gate (secondary): Delivery Engine | DoD gate | — | Tier 1 (deterministic checks) |

Stage 8 uses acceptance mode (vs. Stage 7 review mode). Principal Engineer lens replaced by Delivery Engine DoD gate lens. Author-reviewer separation maintained (fresh context).

## 4. Inputs
From Dev Testing: quality review report terminating in the structured Handoff Payload per [DT↔QA Handoff Protocol §Forward Handoff](stage-07-dev-testing.md#dtqa-handoff-protocol), iteration history, verdict. On a post-return iteration, DT emits the Verified Signal per the same protocol.
From Engineering: PR with committed changes, sub-task completion, deviation log.
From Planning: verification plan, AC per issue, file change matrix.
From GitHub Issues: AC per issue — primary QA source.

Set at Stage 8: per-criterion verdict, acceptance score, Stage 7 escape count, overall verdict (ACCEPT/CONDITIONAL ACCEPT/REJECT/HOLD).

## 5. Process
**Phase A — Entry Validation (Tier 1):** 4 steps — verify Stage 7 verdict (PASS or CONDITIONAL PASS required), PR still mergeable, quality report present with conformant Handoff Payload (per [DT↔QA Handoff Protocol §Forward Handoff](stage-07-dev-testing.md#dtqa-handoff-protocol)), all AC extractable from issues. Missing or malformed Handoff Payload → post [ADJUST] signal per the inter-stage feedback protocol Tier 1; DT amends in-place (no full re-review required for format-only corrections).

**Phase B — Acceptance Review (Tier 2 Recommend):** 4 steps — extract AC per issue, evaluate each criterion against PR content (LLM-graded), classify findings, render per-issue verdict. Decision card format for each finding:

```
Finding: [ID]
Criterion: [AC item]
Evidence: [what was found]
Verdict: MET / NOT MET / PARTIAL
Severity: [if NOT MET: Blocker / Warning]
```

**Per-criterion verdict enum** (extended for AC drift): `MET / NOT MET / PARTIAL / N/A-WITH-RATIONALE / REINTERPRET-WITH-RATIONALE / FLAG-UPSTREAM` per [`release/governance/release-process.md § Inter-Stage Feedback Protocol § AC-Drift Handling Protocol`](../../governance/release-process.md). Drift verdicts (`N/A-WITH-RATIONALE`, `REINTERPRET-WITH-RATIONALE`, `FLAG-UPSTREAM`) carry a required `Drift-rationale:` field per the protocol; `FLAG-UPSTREAM` routes Tier 1 [ADJUST] or Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol (NOT Lane 2 QA→DT Return per Phase C). **Cutover discipline:** Applies to all releases entering Stage 8 going forward.

**Phase C — Three-Lane Routing:**

| Lane | Trigger | Action | Return Target |
|---|---|---|---|
| Lane 1: Cosmetic | Minor formatting, non-AC | Note — log, no action required | — |
| Lane 2: AC Gap | AC not met, fixable | Emit QA Return to Dev Testing payload per [DT↔QA Handoff Protocol §Return Path](stage-07-dev-testing.md#dtqa-handoff-protocol) (NOT directly to Engineering) | Stage 7 |
| Lane 3: Acceptance Judgment | Subjective AC, fitness question | Decision card → human review | Stage 9 |

Critical routing difference: Lane 2 returns to Dev Testing, not directly to Engineering. This preserves the quality gate chain and composes with the DT↔Engineering iteration loop as its QA-initiated variant — full specification in the protocol reference.

**Phase D — Iteration Loop:**
QA Pass 1 → Route findings per lanes → Lane actions executed (Lane 2 triggers QA→DT Return per [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol); DT runs full re-review per the DT-Eng iteration loop, iterates with Engineering, emits Verified Signal on PASS) → QA Pass 2 (full re-review per Stage 8 §5 Phase D) triggered by Verified Signal → If new findings, route again → Escalation at iteration count > 2 (flag to operator). Iteration cap rationale: more than 2 passes indicates a systemic issue, not incremental fixes.

**Phase E — Human Review (Tier 3):** 3 verdicts — ACCEPT (all AC met, fitness confirmed), CONDITIONAL ACCEPT (minor gaps with documented rationale), REJECT (AC gaps requiring Engineering rework) / HOLD (scope question requiring Planning review).

**Ticket lifecycle:** Claim: set Stage→8-QATesting. Execute: A-E. Resolve: post acceptance report, route per verdict. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** Handoff (QA return to DT protocol); Tracking (acceptance sign-off). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Acceptance Report: acceptance matrix (per-criterion verdict), acceptance score, fitness assessment, Stage 7 escape log, lane distribution, overall verdict. Downstream: to Stage 9 (acceptance report + PR + DT report) or to Stage 7 (Lane 2 findings emitted as QA Return to Dev Testing payload per [DT↔QA Handoff Protocol §Return Path](stage-07-dev-testing.md#dtqa-handoff-protocol)).

Stage 8 does NOT produce: quality scores (Stage 7), design decisions (Stage 5), deployment actions (Stage 12).

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all AC checked, acceptance matrix complete, no unresolved Blocker findings, escape detection performed, iteration count logged, report posted.
Judgment (1-5): AC coverage thoroughness, evidence quality, fitness assessment, escape detection, report clarity.
Calibration: ambiguous AC rate, QA escapes to Stage 9, iteration count. Threshold adjustment after 3+ releases.

## 8. Automation Level
Overall Tier 2 (Recommend). More human-dependent than Stage 7 — acceptance is inherently human judgment. Agent evaluates and recommends; operator decides. Tier 1 only for deterministic entry checks and report assembly.

## 9. Gap Summary
8 gaps. Key: no QA Auditor acceptance review mode (P2), no acceptance assertion framework (P2). The Stage 7→8 handoff format and QA→DT return path resolved via [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol).

## 10. Retro
To be populated after execution. Incorporates patterns from the three-lane routing, iteration loop, decision-weighting, user engagement, and full re-review scope decisions.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `qa-acceptance` / `qa-rejection` | QA verdict rendered at Phase B; ALSO captured in `calibration-data.md` — payload carries `projects_to: calibration-data.md:<row-anchor>` | `spoke:#N` (QA spoke) |
| `iteration` | `qa-dt-pass-N` | QA↔DT Lane 2 return per [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol); ALSO captured in `iteration-log.md` — payload carries `projects_to: iteration-log.md:<row-anchor>` | `hub` |

Cutover discipline: applies to all releases going forward.
