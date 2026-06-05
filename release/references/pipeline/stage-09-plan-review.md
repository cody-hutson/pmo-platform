# Stage 9: Plan Review

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Final review of the release plan, implementation, and test results before deployment authorization. The operator renders a Go/No-Go decision with full evidence — this is the last human gate before production state change. Stage classification note: Plan Review is a gate stage — the hub presents evidence to the operator, no spoke is launched.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation | Compression Note |
|---|---|---|---|
| Purpose | Plan review; deployment authorization | Same — Go/No-Go decision with evidence package | — |
| Governance Focus | Deployment readiness, stakeholder sign-off | Operator reviews PR diff + quality reports | Single operator = single sign-off |
| Artifact Inputs | Test results, deployment plan, risk assessment | Complete PR, release plan, Stage 7-8 reports, risk register | — |
| Artifact Outputs | Go/No-Go decision, deployment authorization | Decision record with verdict, rationale, conditions | No separate deployment authorization document |

Key compression: Ref Model assumes multi-stakeholder sign-off with deployment readiness review board. Single-operator PMO: one person reviews all evidence and renders the decision. PR diff review IS the deployment procedure validation (Stage 10 compressed into Stage 9).

## 3. Persona

| Role | Skills-Map Ref | Autonomy |
|---|---|---|
| Decision maker: Human operator | Portfolio Mgr Skill 1, Mode 3 | Tier 3 (Human-only — renders Go/No-Go) |
| Evidence assembly: Release Mgr Skill 13 | Mode 1 | Tier 1 (Auto — compiles evidence package) |
| Risk assessment: TPM Skill 3 | Mode 2 | Tier 2 (Recommend — flags risks) |

## 4. Inputs
From Dev Testing: quality review report, finding list, escape rate, verdict.
From QA Testing: acceptance report, acceptance matrix, fitness assessment, Stage 7 escape log.
From Engineering: PR with committed changes, deviation log, self-verification evidence.
From Planning: release plan, risk register, verification plan.

Set at Stage 9: Go/No-Go verdict, decision rationale, conditions (if GO WITH CONDITIONS), deployment authorization.

## 5. Process
**Phase A — Evidence Assembly (Tier 1):**
A1 Upstream report synthesis (Stage 7 quality report + Stage 8 acceptance report). A2 PR scope summary (files changed, additions/deletions, issues addressed). A3 Release plan compliance check (all planned items implemented). A4 Risk register status (all risks mitigated or accepted). A5 Deployment readiness checklist (PR mergeable, branch current, metadata complete, rollback available). A6 Release Readiness Scan per [release-readiness-scan-spec.md](../specs/release-readiness-scan-spec.md) — 13-dimension aggregation over A1-A5 outputs; escape detection absorbed as dim-13. Cutover: applies to all Stage 9 reviews going forward. A7 Goal-conformance check (per G-PR7) — see Phase A7 below.

**Phase A7 — Goal-conformance check (per G-PR7):** Hub reads the `### Release Outcome Statement` H3 block from the GitHub Milestone description (`gh api repos/{REPO}/milestones/<N> --jq .description`), reads the PR scope (`gh pr view <PR> --json files,additions,deletions`), reads the release plan §Implementation Sequence + File Change Matrix, AND reads each release-scoped issue AC. Produces a 1-paragraph conformance narrative answering "does the assembled implementation deliver the AFTER state?" Verdict: **ALIGNED** / **DIVERGED-WITH-RATIONALE** / **MISALIGNED**.

- **ALIGNED** → no operator action; GO recommendation supported.
- **DIVERGED-WITH-RATIONALE** → operator documents in Decision Record before GO.
- **MISALIGNED** → NO-GO recommendation (operator may override).

LLM-graded judgment-recommend tier per gate-criterion G-PR7 in [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-9-plan-review). Recommend-tier matches the G3-04/G3-05 judgment precedent — a grep cannot reliably assert "release delivers the AFTER state"; the LLM scan provides the recommendation; the operator renders the binding decision. See [release-outcome-statement-template.md](../specs/release-outcome-statement-template.md) for the canonical Outcome schema and anti-pattern catalog the conformance check applies on read. **Cutover:** Applies to all Stage 9 reviews going forward.

**Phase B — Tiered Presentation (Tier 1):**
Present evidence package to operator in three tiers: Tier 1 (30-second summary — verdict recommendation, key metrics, blockers), Tier 2 (5-minute detail — per-issue status, risk assessment, escape analysis), Tier 3 (full evidence — complete reports, PR diff, release plan).

**Phase C — Human Decision (Tier 3):**

| Verdict | Criteria | Next Step |
|---|---|---|
| **GO** | All quality gates passed, no unresolved blockers, risk accepted | → Stage 12 Execute |
| **GO WITH CONDITIONS** | Minor items accepted with documented rationale; conditions must not require code changes | → Stage 12 Execute (conditions tracked) |
| **NO-GO** | Unresolved blockers, unacceptable risk, quality below threshold | → Return to Stage 6/7/8 per finding |

GO WITH CONDITIONS boundary rule: if a condition requires code changes, it is a NO-GO. Conditions are documentation, tracking, or process items only.

**Ticket lifecycle:** Claim: set Stage→9-PlanReview. Execute: A-C. Resolve: post decision record, route per verdict. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** Handoff (Go/No-Go gate); Assignment (Portfolio Manager persona — operator). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Go/No-Go decision record (verdict, rationale, conditions, authorization), evidence package (assembled reports, PR scope, risk status, deployment readiness). No separate deployment authorization document — the decision record IS the authorization.

**Release Readiness Scan output:** Phase A6 emits a 13-dimension scan output per [release-readiness-scan-spec.md § 6](../specs/release-readiness-scan-spec.md). The output is dual-surfaced: (a) markdown table posted as a comment on the Stage 9 Plan Review sub-task; (b) one `gate-outcome` row with subtype `plan-review-readiness-scan` appended to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the unified [pipeline-event-log-schema.md](../standards/pipeline-event-log-schema.md). Aggregate verdict (ALL-PASS / ANY-FAIL / ANY-PARTIAL) surfaces in the Procedure 5 Decision Briefing per [hub-spoke-bridge.md § Procedure 5](../how-to/hub-spoke-bridge.md). **Cutover:** Applies to all Stage 9 reviews going forward.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics (canonical IDs per [`schemas/gate-criteria-spec.md` Gate 9](../../../core/schemas/gate-criteria-spec.md#gate-9-plan-review)): evidence package complete (G-PR1), all upstream reports present (G-PR2), PR scope matches release plan (G-PR3), risk register reviewed (G-PR4), deployment readiness checklist all PASS (G-PR5), decision record posted (G-PR6), goal-conformance against Outcome Statement (G-PR7 — judgment-recommend).
Judgment (1-5): evidence completeness, risk assessment quality, decision clarity, handoff readiness.
Gate output: GO → Stage 12 / GO WITH CONDITIONS → Stage 12 / NO-GO → return upstream.

## 8. Automation Level
Overall Tier 3 (Human-only). The decision is inherently human — no agent recommendation on Go/No-Go. Agent role: assemble evidence, present in tiered format, document the decision. Agent does NOT produce a recommendation for the verdict.

## 9. Gap Summary
8 gaps. Key: no Release Manager evidence assembly mode (P2), evidence package refinement (P3), Stage 9/10 compression not formalized (P2).

## 10. Retro
To be populated after execution.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `plan-review-go` / `plan-review-no-go` | Operator renders GO / NO-GO decision after reviewing PR diff (the dry-run governance gate per Stage 9 compression rules); ALSO captured in `calibration-data.md` — payload carries `projects_to: calibration-data.md:<row-anchor>` and confidence label | `operator` |
| `gate-outcome` | `goal-conformance` | Phase A7 verdict (ALIGNED / DIVERGED-WITH-RATIONALE / MISALIGNED) rendered against the Outcome Statement per G-PR7; paired with `plan-review-go` / `plan-review-no-go` capture; payload carries `verdict` (enum) + `outcome_excerpt` (Outcome AFTER paragraph quote) | `hub` |
| `gate-outcome` | `plan-review-readiness-scan` | Hub completes Phase A6 Release Readiness Scan and posts output per [release-readiness-scan-spec.md § 6](../specs/release-readiness-scan-spec.md); payload carries `aggregate_verdict` (ALL-PASS / ANY-FAIL / ANY-PARTIAL) + per-status counts + `sub_task_comment:<URL>` pointer; cutover: applies to all Stage 9 reviews going forward | `hub` |

Cutover: applies to all releases entering this stage going forward, including the `goal-conformance` sub-type.
