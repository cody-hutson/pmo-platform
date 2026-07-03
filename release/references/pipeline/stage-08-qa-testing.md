<!-- reference-durability: allow-link -->
# Stage 8: QA Testing

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
This is the **validate** stage of the pipeline — where the built result is validated against acceptance criteria, after Engineering has built it. Validate release quality from an independent acceptance perspective — the gate that asks "does this meet needs?" (vs. Stage 7's "does this meet specs?"). Produces an acceptance verdict with per-criterion evidence for human review.

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

**Per-criterion verdict enum** (extended for AC drift): `MET / NOT MET / PARTIAL / N/A-WITH-RATIONALE / REINTERPRET-WITH-RATIONALE / FLAG-UPSTREAM` per [`release/governance/release-process.md § Inter-Stage Feedback Protocol § AC-Drift Handling Protocol`](../../governance/release-process.md). Drift verdicts (`N/A-WITH-RATIONALE`, `REINTERPRET-WITH-RATIONALE`, `FLAG-UPSTREAM`) carry a required `Drift-rationale:` field per the protocol; `FLAG-UPSTREAM` routes Tier 1 [ADJUST] or Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol (NOT Lane 2 QA→DT Return per Phase C). **Cutover discipline:** Applies to all releases entering Stage 8 going forward. Each non-MET verdict additionally keys the disposition axis per the **Finding Disposition Decision Framework** below (fix-now / defer / accept), with a strengthened Step 0 gate for `NOT MET` acceptance criteria.

**Design-Principle Conformance QA dimension** (applies when the release touches the D-Gate-rendering surface or the design-principle register): for each option-level `### Design-Principle Conformance` verdict produced in the release's Decision Briefings / D-Gate renderings, verify the conformance verdict CITES (a) the register entry id (`DP-N`) and (b) the entry's `governing_doc` path:line — a bare `ALIGNED` / `**CONFLICT.**` with no register-entry + `governing_doc` citation is a NOT MET finding (it fails the load-bearing evidence test per `decision-discipline.md` § 5 G1/G3, the same evidence-citation discipline the Upstream-compatibility verdict carries). Cross-check: every `**CONFLICT.**` verdict enumerates ≥1 named mitigation and, when the entry's `conflict_reversibility_default` is EXPENSIVE/IRREVERSIBLE, shows an operator HALT / sign-off (not a silent annotate). This dimension is the acceptance-side twin of `deploy.sh --check` Check 45's deploy-time structural assertion: Check 45 asserts the conformance mechanism EXISTS and the register resolves; this dimension asserts each rendered conformance verdict is EVIDENCE-GROUNDED.

**Phase C — Three-Lane Routing:**

| Lane | Trigger | Action | Return Target |
|---|---|---|---|
| Lane 1: Cosmetic | Minor formatting, non-AC | Note — log, no action required | — |
| Lane 2: AC Gap | AC not met, fixable | Emit QA Return to Dev Testing payload per [DT↔QA Handoff Protocol §Return Path](stage-07-dev-testing.md#dtqa-handoff-protocol) (NOT directly to Engineering) | Stage 7 |
| Lane 3: Acceptance Judgment | Subjective AC, fitness question | Decision card → human review | Stage 9 |

Critical routing difference: Lane 2 returns to Dev Testing, not directly to Engineering. This preserves the quality gate chain and composes with the DT↔Engineering iteration loop as its QA-initiated variant — full specification in the protocol reference.

### Finding Disposition Decision Framework

Phase B renders a **verdict** per criterion (`MET / NOT MET / PARTIAL`) and Phase C routes it to a **lane** (WHERE). This subsection adds the **disposition axis** (WHEN): for each finding, *fix-now* (this release) / *defer* (a future release) / *accept* (as-is). Disposition is rendered by the operator at Phase E (Tier 3); the framework is advisory input, not auto-correction.

**Inherited from the shared framework by reference (NOT re-specified here).** Stage 8 reuses, unchanged, the stage-agnostic disposition machinery defined in [`release/references/standards/finding-disposition-framework.md`](../standards/finding-disposition-framework.md):

- the **5-factor disposition matrix** (§ 3) — Effort (High) · Best-Practice Alignment (High) · Downstream Impact (Medium) · Reversibility/Risk (Medium) · Scope-Window (Low, gate-modifier), each with its Fix-Now / Defer / Accept signals;
- the **Step 1 weighted disposition** logic and the **Step 2 tie-break** order (§ 4) — weight spine High = 3 / Medium = 2 / Low = 1; ties resolve Reversibility-Accept → cheap-and-open-Fix-Now → Defer (the conservative default);
- the **stage-agnostic scoring skeleton** (§ 5) — `disposition(finding) → {fix-now, defer, accept, escalate}`, advisory until calibration justifies promotion.

Stage 8 **defines only its own Step 0 precedence gate** (below) — the stage-specific gate the shared framework's § 6 contract requires each consumer to inject — and **adds** the PARTIAL keying and the three-lane composition. The shared matrix and Steps 1–2 are authoritative in the framework doc; they are **not** duplicated here.

#### Step 0 — QA hard precedence (the strengthened gate)

Stage 8's Step 0 is **strictly stronger** than Stage 7's and is keyed on the per-criterion **verdict** (lines 47/51), not DT severity:

- **NOT MET** → a **contractual gap**. Its **only no-override disposition is fix-now**, routed **Lane 2 → QA Return to Dev Testing** (the existing Phase C path). A NOT-MET AC is **never** Defer or Accept by the weighted layer. **Deferring _or accepting_ a NOT-MET AC requires an explicit operator override with a recorded Operator Override Record** (below). Absent that record, a NOT-MET AC cannot leave the release as anything but fix-now — silent defer/accept is foreclosed. *(This is the override gate; it rides Lane 2.)*
- **PARTIAL** → keyed by its **unmet remainder** (see "PARTIAL deferral criteria" below).
- **MET** → no gate; not a finding requiring disposition.
- **Drift verdicts** (`N/A-WITH-RATIONALE` / `REINTERPRET-WITH-RATIONALE` / `FLAG-UPSTREAM`, line 51) are **out of this gate** — they retain their own `Drift-rationale:` requirement and `FLAG-UPSTREAM` Tier-1/Tier-2 routing per the AC-Drift Handling Protocol. This framework keys only on `MET / NOT MET / PARTIAL`.

**Why stronger than Stage 7:** Stage 7's Step 0 permits an in-scope **Blocker** to be auto-dispositioned **fix-now** by the weighted layer and is silent on override records. Stage 8 (a) keys on the **contractual `NOT MET`** verdict, (b) forbids *any non-fix* disposition of it absent operator sign-off, and (c) requires that sign-off to be **recorded** — because an acceptance criterion is a commitment from issue creation, and deferring/accepting it is a conscious scope change, not routine prioritization.

**Operator Override Record** (required for any deferred-or-accepted NOT-MET, or AC-blocking PARTIAL, criterion):

| Field | Content |
|---|---|
| **Criterion** | the AC item verbatim (the contractual text being dispositioned away from fix-now) |
| **Verdict + evidence** | `NOT MET` / `PARTIAL` + the Phase B evidence line (what was found) |
| **Disposition** | `Defer` or `Accept` (the non-fix disposition being authorized) |
| **Operator rationale** | why the conscious scope change is acceptable (1–3 sentences; "routine prioritization" is **not** a valid rationale) |
| **Reversibility + landing** | reversibility tier + where the gap lands: **Defer** → a next-release issue number (the gap gets a tracked home); **Accept** → recorded in the Acceptance Report fitness assessment |

The agent **surfaces** the NOT-MET/PARTIAL gap and the *requirement* for an Override Record; it does **not** self-author the override (Tier 3 — acceptance is human judgment per § 8). A **CONDITIONAL ACCEPT** at Phase E that covers a NOT-MET/PARTIAL AC **must** carry an Override Record per criterion — this is the existing "documented rationale" of that verdict made specific. CONDITIONAL ACCEPT is the **named vehicle** for an accepted NOT-MET/PARTIAL AC; no parallel verdict is invented.

#### PARTIAL deferral criteria

A `PARTIAL` keys the gate by its **unmet remainder**:

- **Unmet remainder is non-AC-blocking** (cosmetic, outside the AC's contractual scope, or aspirational with no documented commitment) → routes the **Step 1 weighted layer**; **may be deferred or accepted without an operator override** (a deferral opens a next-release issue; an acceptance carries the one-line weighted-layer rationale). This is the "substantially met, minor remainder" case CONDITIONAL ACCEPT contemplates.
- **Unmet remainder is itself an acceptance commitment** (a contractual sub-criterion is undelivered) → **escalates to the Step-0 NOT-MET gate**: fix-now (Lane 2 → DT return) is the only no-override disposition; defer/accept requires the Operator Override Record.
- **Test:** *"Is the unmet portion something we agreed to deliver?"* — **yes → NOT-MET gate**; **no → weighted layer.**

#### Disposition × three-lane composition

The lane says WHERE a finding routes; the disposition says WHEN it is addressed; Step 0 constrains WHICH dispositions are legal for a NOT-MET/PARTIAL AC.

| Lane (Phase C) | Disposition composition |
|---|---|
| **Lane 1 — Cosmetic** (non-AC) | **Accept (informational)** by default — the existing "Note — log, no action required" *is* the accept disposition; the weighted layer is not exercised and Step 0 does not fire (no AC at stake). |
| **Lane 2 — AC Gap** (`NOT MET`, fixable) | **Step 0 fires.** Default = **fix-now** → the existing QA Return to Dev Testing path. **Defer or Accept is legal only with the Operator Override Record.** The override gate lives here. |
| **Lane 3 — Acceptance Judgment** (subjective AC, fitness) | **Tier-3 disposition by the operator at Phase E.** A subjective/fitness AC judged acceptable-as-is is an **Accept** carrying the Override Record when the underlying verdict is NOT-MET/PARTIAL. The weighted layer is advisory input to the judgment. |

#### Stage 7 ↔ Stage 8 differentiation (what is shared vs. what QA overrides)

This is the inverse view of the differentiation note in [`stage-07-dev-testing.md`](stage-07-dev-testing.md) § Finding Disposition Decision Framework: Stage 7 states "what QA will override"; this states "what QA inherits + its stronger gate."

| Element | Stage 7 (Dev Testing) | Stage 8 (QA — this stage) |
|---|---|---|
| 5-factor matrix (§ 3) | references the shared framework | **inherited unchanged** (references the same shared framework) |
| Step 1 weighted disposition + Step 2 tie-break (§ 4) | references the shared framework | **inherited unchanged** (references the same shared framework) |
| Step 0 hard precedence | open **Blocker** → fix-now-or-escalate; never silent defer/accept; **Note** → Accept | **STRENGTHENED:** **NOT-MET AC** → fix-now is the only no-override disposition; defer/accept needs a **recorded operator override**. Strictly stronger — Stage 7 permits in-scope Blocker auto-fix-now and records no override; Stage 8 forbids any non-fix disposition of a NOT-MET AC absent recorded sign-off. |
| Finding vocabulary | DT severity (Blocker / Warning / Note) | QA per-criterion verdict (`MET / NOT MET / PARTIAL`); NOT-MET keys the gate, PARTIAL keys by unmet remainder; drift verdicts are out-of-gate |
| Routing on Defer | new next-release issue | **same**, plus a deferred NOT-MET/PARTIAL-AC-blocking criterion additionally requires the Operator Override Record |

**Phase D — Iteration Loop:**
QA Pass 1 → Route findings per lanes → Lane actions executed (Lane 2 triggers QA→DT Return per [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol); DT runs full re-review per the DT-Eng iteration loop, iterates with Engineering, emits Verified Signal on PASS) → QA Pass 2 (full re-review per Stage 8 §5 Phase D) triggered by Verified Signal → If new findings, route again → Escalation at iteration count > 2 (flag to operator). Iteration cap rationale: more than 2 passes indicates a systemic issue, not incremental fixes.

**PR review-comment → edit → resolving-reply path (Phase D; autonomy-tier-bound).** When a QA-surface finding arrives as a **GitHub PR review comment / review thread** on the release PR (as opposed to an internal QA finding card), it is handled by the same machinery — the channel is an alternate arrival surface, tiered by change-nature per [`release/governance/release-process.md` § Inter-Stage Feedback Protocol → PR review comments as a feedback surface](../../governance/release-process.md):
- **Tier 1 [ADJUST]** (minor QA correction, no AC/scope/sequence touched): the fix routes via the existing `fix(qa):` commit convention on the release branch (the QA-surface analogue of the `fix(dt):`/Lane-2 machinery); the spoke posts a **resolving reply** on the originating PR review thread when the fix lands, closing the loop on that comment.
- **Tier 2 [SCOPE CHANGE] / Tier 3 [PLAN REJECTION]** (the comment requires scope/sequence/AC change, or rejects the plan): routed to the operator per § Inter-Stage Feedback Protocol — the QA spoke does not silently absorb a scope-affecting comment as a Tier 1 edit.
- An **AC-gap** comment (AC not met, fixable) rides the existing **Lane 2 → QA Return to Dev Testing** path per Phase C (not directly to Engineering — preserving the layered review chain); the resolving reply is posted when the returned fix re-passes QA.

The tier binding is by the *nature* of the requested change, never by the fact that it arrived as a comment. **Single-operator no-op:** under the single-operator reviewer convention the PR ships with no external reviewer, so no review comments arrive and this path is **dormant** — a no-op in single-operator steady state. **Cutover discipline:** Applies to all releases entering Stage 8 going forward.

**Phase E — Human Review (Tier 3):** 3 verdicts — ACCEPT (all AC met, fitness confirmed), CONDITIONAL ACCEPT (minor gaps with documented rationale), REJECT (AC gaps requiring Engineering rework) / HOLD (scope question requiring Planning review). For each finding, apply the **Finding Disposition Decision Framework** to render disposition (fix-now / defer / accept); a CONDITIONAL ACCEPT covering a `NOT MET` or AC-blocking `PARTIAL` criterion MUST carry an Operator Override Record per that framework's Step 0.

##### Phase E3 — REJECT/HOLD upstream re-scope routing (requirements-clarity vs implementation)

A Phase E REJECT/HOLD splits on whether the gap is an **implementation defect** or a **requirements-clarity / premise problem** — the two route to different upstream stages:

- **Implementation REJECT** (the AC is sound; the build does not meet it) → **Engineering rework** via the existing Lane 2 → QA Return to Dev Testing path (§ Phase C). Release-state: HOLD until the rework lands and re-review passes.
- **Requirements-clarity REJECT / HOLD** (the AC itself is stale, ambiguous, subsumed, or premise-invalid — the scope question Phase E names as HOLD) → the **Tier 0 — Premise Rejection** protocol, NOT Engineering. Per [`release/governance/release-process.md` § Inter-Stage Feedback Protocol → Tier 0 — Premise Rejection](../../governance/release-process.md), the operator chooses among **(A) Return to Triage**, **(B) Override + proceed with deviation log**, or **(C) Defer to next release**; the underlying finding is the **C3 (should-be-challenged)** classification per [`triage-design-rereview.md`](../standards/triage-design-rereview.md) § 3. **Artifact on REJECT:** the spoke posts the **Tier 0 escalation block** ([`triage-design-rereview.md`](../standards/triage-design-rereview.md) § 9 template) on the **parent issue** (not the sub-task) and HOLDS the sub-task open; **re-entry** is Triage re-running with the re-review evidence as input (it may re-bundle into the same Milestone or be excluded), which re-enters this pipeline at Stage 4. This is the WHEN/WHO routing for a premise-level REJECT, distinct from the Finding Disposition Decision Framework above (which keys the fix-now/defer/accept disposition of an in-scope NOT-MET AC).

**Release-state on either REJECT = HOLD until resolved.** This subsection **cites** the Tier-0 protocol and the disposition framework; it does not restate them (duplicate-source-discipline) — the authoritative routing options, escalation-block template, and re-entry mechanics live in `release-process.md` § Inter-Stage Feedback Protocol and `triage-design-rereview.md` §§ 3/9.

**Ticket lifecycle:** Claim: set Stage→8-QATesting. Execute: A-E. Resolve: post acceptance report, route per verdict. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** Handoff (QA return to DT protocol); Tracking (acceptance sign-off). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Acceptance Report: acceptance matrix (per-criterion verdict), acceptance score, fitness assessment, Stage 7 escape log, lane distribution, overall verdict. Downstream: to Stage 9 (acceptance report + PR + DT report) or to Stage 7 (Lane 2 findings emitted as QA Return to Dev Testing payload per [DT↔QA Handoff Protocol §Return Path](stage-07-dev-testing.md#dtqa-handoff-protocol)).

The Acceptance Report is rendered from the canonical template at [`operations/templates/qa-acceptance-report-template.md`](../../../operations/templates/qa-acceptance-report-template.md) — three reader tiers (verdict / detail / evidence) carrying these six sections, with a machine-parseable acceptance-matrix block whose columns and all-drift-out score are the co-design contract with the `acceptance` assertion type ([`core/skills/eval-writer/references/acceptance-assertion-type.md`](../../../core/skills/eval-writer/references/acceptance-assertion-type.md)).

Stage 8 does NOT produce: quality scores (Stage 7), design decisions (Stage 5), deployment actions (Stage 12).

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all AC checked, acceptance matrix complete, no unresolved Blocker findings, escape detection performed, iteration count logged, report posted; incoming deferred items accounted (every item whose Target stage = this stage, per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md), is picked up or re-deferred with rationale — zero unaccounted incoming deferrals).
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
