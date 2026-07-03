<!-- reference-durability: allow-link -->
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
A1 Upstream report synthesis (Stage 7 quality report + Stage 8 acceptance report). A2 PR scope summary (files changed, additions/deletions, issues addressed). A3 Release plan compliance check (all planned items implemented). A4 Risk register status (all risks mitigated or accepted). A5 Deployment readiness checklist (PR mergeable, branch current, metadata complete, rollback available, **install/onboarding regression gate green** — the `install-tests.yml` `install-regression` job, which runs the standing install/onboarding/update regression suite, is passing on the release-branch head; **Automation Tier 2 (Bounded Auto)** — CI fires the suite automatically within its declared sandbox boundary and the operator consumes the verdict here, it is not a per-run human approval and does not itself authorize the deploy). A6 Release Readiness Scan per [release-readiness-scan-spec.md](../specs/release-readiness-scan-spec.md) — 13-dimension aggregation over A1-A5 outputs (the install/onboarding regression-gate CI status is one A5 input the scan reads); escape detection absorbed as dim-13. Cutover: applies to all Stage 9 reviews going forward. A7 Goal-conformance check (per G-PR7) — see Phase A7 below.

**Phase A3.5 — Chain-by-chain integration validation (Tier 1; conditional).** Where prior Stage 9 evidence assembly read each issue's acceptance flat (per-PR / per-issue), this sub-step adds a **chain-oriented** pass: the hub groups the release's issues into **dependency chains** (transitive closure over native `blocked-by` + the release plan's § Dependency Graph directional edges), then for each chain confirms that **every integration AC authored at Stage 5 (Phase A4.2) was graded `MET` at Stage 8**. Output — a per-chain integration verdict:

- **CHAIN-CONSISTENT** — all of the chain's `INT-N` integration ACs graded MET at Stage 8;
- **CHAIN-INCONSISTENT** — ≥1 integration AC graded NOT MET, or PARTIAL without an Operator Override Record;
- **N/A — no multi-issue chain** — the chain is a single node (no cross-issue dependency).

Each per-chain verdict folds into the Phase A6 Release Readiness Scan and surfaces in the Procedure 5 Decision Briefing. A **CHAIN-INCONSISTENT** verdict is a **NO-GO recommendation input** (the operator may override with recorded rationale, consistent with the existing G-PR7 DIVERGED-WITH-RATIONALE precedent). This sub-step consumes the Stage-5 Phase-A4.2 output and the Stage-8 per-criterion verdicts using the **Stage-8 verdict enum verbatim** — it authors no new verdict values.

**Single-node degeneracy (regression guarantee):** a release whose issues have no cross-issue dependencies produces only single-node "chains"; Phase A3.5 then reduces to the existing per-issue read and emits **N/A — no multi-issue chain** for each. It adds evidence *structure* for chained releases; it removes nothing for unchained ones — existing per-issue Stage 9 behavior is byte-for-byte unchanged when no integration ACs exist. *Cutover (introducing-release-exempt): applies to releases entering Stage 9 strictly AFTER this sub-step's introducing-release merge SHA; the introducing release is itself exempt.*

**Phase A3.6 — Release-node cross-issue integration validation (Tier 1; conditional).** Where Phase A3.5 validates cross-issue *chains* (dependency-linked issues via `INT-N`), this sub-step validates the release's **Cross-Issue Acceptance Criteria (CIAC)** — release-scoped predicates spanning ≥2 issues with **no dependency edge required**, authored at Stage 4 (per [stage-04-planning.md](stage-04-planning.md) § Cross-Issue Acceptance Criteria). Mirroring Phase A3.5's **read-only posture** (A3.5 reads the Stage-8 per-criterion verdicts; it does not re-grade), **the hub reads the CIAC verdicts the release's verification-execution executor emitted at Stage 6/7 (Verification-Evidence), confirming each CIAC-N is graded PASS** — it does NOT itself run the CIAC's declared grep / anchor / runtime-dispatch method. The single-runner discipline is deliberate: the verification-execution executor is the sole runner of each CIAC's declared method and the sole emitter of the verdict; Stage 9 consumes those verdicts so a predicate is evaluated in exactly one place, never re-run by a second runner that could diverge. For each CIAC-N the hub renders a per-CIAC verdict using the Stage-8 per-criterion verdict enum verbatim (no new verdict values). Output:
- **RELEASE-CONSISTENT** — all CIAC-N verdicts read PASS (MET);
- **RELEASE-INCONSISTENT** — ≥1 CIAC-N NOT MET, or PARTIAL without an Operator Override Record;
- **N/A — no cross-issue criteria** — the plan declares zero CIACs.

**Evidence-freshness guard (mirrors the G-PR9 baseline-currency discipline).** A consumed CIAC verdict is only trustworthy if it was emitted against the **final PR head SHA**. Before reading the verdicts, the hub confirms the SHA the executor recorded each CIAC verdict against equals the current release-branch / PR head SHA. If a commit landed after the verdict was emitted AND that commit touched any file the CIAC's shared surface / verification method reads, the verdict is **stale** → the hub re-triggers the executor to re-emit the CIAC verdicts against the new head SHA before the gate reads them. A stale-but-unrefreshed verdict is not a valid PASS input — this is the CIAC analogue of G-PR9's staleness predicate (a GO baseline invalidated by a later mover-set), applied to the intra-release commit that post-dates the emitted evidence.

Each verdict folds into the Phase A6 Release Readiness Scan and surfaces in the Procedure 5 Decision Briefing. A **RELEASE-INCONSISTENT** verdict is a **NO-GO recommendation input** (the operator may override with recorded rationale, consistent with the existing G-PR7 DIVERGED-WITH-RATIONALE precedent). This sub-step consumes the Stage-4 CIAC list and the executor's emitted verdicts; it composes with — and does not duplicate — Phase A3.5 (`INT-N` chain validation): A3.5 covers dependency-linked issue pairs, A3.6 covers release-scoped predicates over any ≥2 issues. **Empty-CIAC degeneracy (regression guarantee):** a plan with zero CIACs emits **N/A** and existing Stage-9 behavior is byte-unchanged. *Cutover (introducing-release-exempt): applies to releases entering Stage 9 strictly AFTER this sub-step's introducing-release merge SHA; the introducing release is itself exempt.*

**Phase A6.5 — Mid-Pipeline Divergence Re-Check (Tier 2; HALT-eligible on the file dimension, advisory on the version dimension):** Between Phase A6 (Release Readiness Scan) and Phase A7 (Goal-conformance check), the hub runs the mid-pipeline divergence re-check on two orthogonal dimensions against freshly-fetched `origin/main`. **File dimension (G-PR8 — HALT-eligible):** per [`release/governance/release-process.md`](../../governance/release-process.md) § Mid-Pipeline Divergence Re-Check (G-PR8 — Phase A6.5) — three verdicts: **CLEAN** (zero commits) → record `G-PR8 = CLEAN`, advance to Phase A7; **DIVERGED-RELEASE-FILES-UNTOUCHED** (commits exist on `main` post-baseline but none touch release-plan files) → record `G-PR8 = DIVERGED-RELEASE-FILES-UNTOUCHED` + informational note, advance to Phase A7; **DIVERGED-RELEASE-FILES-TOUCHED** (commits touch release-plan files) → HALT pre-GO via Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol. **Version dimension (advisory):** resolve this release's version via the version-claim adapter and check whether the provisional-display version the branch carries is still the free slot — do NOT re-derive the anchor or re-encode the claimed-set union (the host mechanism lives only inside the adapter per [`core/standards/repo-host-adapter-versioning.md`](../../../core/standards/repo-host-adapter-versioning.md) § 4 adapter discipline). Run `CLAIM_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)" release/tools/claim-version.sh --bump <bump-class> [--patch-base v<X.Y>] --sha "$(git rev-parse origin/main)" --dry-run`, which computes the next-free version against the adapter's `anchor()` (highest claimed version in the mainline lineage, orphans excluded) and `claimed_set()` (published Release tags ∪ origin signed tags ∪ in-flight RELEASE_LOG `DEPLOYED`-not-`VERIFIED` rows, orphan-filtered, integer-tuple compared) WITHOUT pushing. Two outcomes: **version-freeness = FREE** (the dry-run's next-free equals the carried provisional-display) → record `version-freeness = FREE`; advance to Phase A7. **version-freeness = TAKEN** (the dry-run's next-free has advanced past the carried version) → record `version-freeness = TAKEN` + the recomputed next-free version in the Plan Review comment, surface it in the Procedure 5 Decision Briefing as a re-version signal, and advance to Phase A7. The version dimension is **advisory, not a hard HALT**: the version is not claimed until Stage 12 (defer-to-claim per [`core/standards/repo-host-adapter-versioning.md`](../../../core/standards/repo-host-adapter-versioning.md)), so a slot taken at Stage 9 is recoverable by recomputing the floor, which the operator folds into the GO (consistent with the G-PR7 DIVERGED-WITH-RATIONALE precedent below — a recorded Decision-Record disposition, not a block). The HALT-eligible authoritative version stop is Stage 12 Phase A.5.6 (the last pre-merge detection instant). **Composition (no duplicate gate):** this version dimension is the *absolute* freeness predicate ("is the carried slot claimed at all, right now, per `claimed_set()`?"). It composes with — and does not duplicate — G-PR9 (Phase A7.5), whose `Δversion/<claim-key>` virtual-path token is the *relative* predicate ("did a sibling claim this slot *since the recorded GO baseline*?"): G-PR9 catches a sibling claim within the baseline→GO window via the staleness predicate; this advisory catches a slot already claimed independent of any baseline. Both read the same single claim the adapter's `atomic_claim()` arbitrates at the Stage 12 merge. **Cutover discipline:** Applies to releases entering Stage 9 strictly AFTER this dimension's introducing-release merge. The introducing release itself is exempt (the check shipping in this release cannot run on its own Stage 9).

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
Metrics (canonical IDs per [`schemas/gate-criteria-spec.md` Gate 9](../../../core/schemas/gate-criteria-spec.md#gate-9-plan-review)): evidence package complete (G-PR1), all upstream reports present (G-PR2), PR scope matches release plan (G-PR3), risk register reviewed (G-PR4), deployment readiness checklist all PASS (G-PR5), decision record posted (G-PR6), goal-conformance against Outcome Statement (G-PR7 — judgment-recommend); incoming deferred items accounted (every item whose Target stage = this stage, per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md), is picked up or re-deferred with rationale — zero unaccounted incoming deferrals).
Judgment (1-5): evidence completeness, risk assessment quality, decision clarity, handoff readiness.
Judgment dimensions anchored to G-PR* structural criteria per [`gate-evaluation-spec.md § Per-Boundary Judgment-Dimension Anchors`](../../../core/schemas/gate-evaluation-spec.md) — each dimension is the qualitative read of the structural criterion(s) it maps to.
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
