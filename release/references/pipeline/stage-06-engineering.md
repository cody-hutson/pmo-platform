<!-- reference-durability: allow-link -->
# Stage 6: Engineering

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Execute the release plan by decomposing issues into sub-tasks, implementing file changes on the release branch, and producing a PR ready for review — so the operator reviews completed work, not work-in-progress.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Develop solution per design and requirements | Implement file changes per release plan and design specs on a release branch |
| Governance Focus | Code standards, progress tracking | Platform conventions (naming, layer boundaries, governance patterns), sub-task progress |
| Artifact Inputs | Requirements, design docs, architecture standards | Release plan (from Planning), design specs + ADRs (from Solutioning, when activated), platform architecture (CLAUDE.md, core/rules/) |
| Artifact Outputs | Source code, unit tests, build artifacts | Committed files on release branch, PR ready for review, deployed skill copies (if applicable), sub-task completion evidence |

Key compression: Multi-developer teams with CI/CD → single agent implementing on a release branch per plan. "Code review" = PR diff review by operator. "CI/CD" = PreToolUse hooks (`.claude/hooks/`) + manual deployment. "Automated tests" = eval assertions (future, per the canonical eval-type taxonomy). Delivery Strategy from Planning (Stage 4, Revision 1) provides git workflow specifics — Engineering consumes, doesn't reinvent.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Decision maker: Human operator | — | — | Tier 3 (Human-only) — PR approval, scope change decisions |
| Implementation (primary): Software Engineer Skill 10 | Development | Mode 1 | Tier 1 (Auto-execute) — file changes, commits, sub-task tracking |
| Quality gate (secondary): Principal Engineer Skill 9 | Implementation & Code Quality | Mode 3 (Tech Lead) | Tier 1 (Auto-flag during implementation) |
| Feasibility bridge: TPM Skill 3, Mode 2 | Technical risk assessment | Cross-cutting | Tier 2 (Recommend — when plan divergence detected) |

Mode activation: Skill 10 Mode 1 always active (core implementation). Skill 9 Mode 3 conditionally active (convention compliance, lightweight self-review). Skill 3 Mode 2 activated on plan divergence (assess severity, escalate per feedback protocol).

## 4. Inputs
From Intake/Triage/Bundle: issue metadata, affected files, dependencies, Milestone assignment.
From Planning (always present): release plan file on release branch, implementation sequence, change specs, file change matrix, delivery strategy, risk register, verification plan, rollback strategy.
From Solutioning (when activated): refined change specs, closed ADR issues, blast radius analysis, implementability assessment, tech debt flags.

**Spec depth indicator:** Planning-level (file-level "what to change" — more Engineering autonomy) vs. Solutioning-level (structure-level "how to change" — follow the design). Affects autonomy; inline decisions documented as deviations.

For the structured boundary contract, see [schemas/stage-io-contracts.md](../../../core/schemas/stage-io-contracts.md#boundary-stage-5--stage-6).

Set at Engineering: sub-task decomposition (GitHub sub-issues or PR-body checklist per the A2 container threshold), branch/PR references, commit history, implementation notes, verification evidence.

## 5. Process
**Phase A — Entry Validation + Decomposition (Tier 1):**
A1 Entry contract validation (check release plan file, sequence, specs, matrix, strategy, risks, verification — adapted for spec depth). Gate: PROCEED / CAVEATS / HOLD.
A2 Sub-task decomposition: one sub-task per file-level change or logical unit. **Container selection** — the decomposition lands in one of two containers, chosen by a reproducible threshold predicate evaluated against the release plan's change matrix:

- **Threshold predicate.** Count the planned sub-tasks (file-level changes + logical units, special sub-tasks excluded from the count). If sub-task count ≤ **5** `[CALIBRATE-AFTER-3]` **AND** the work is doc-only or a single logical unit (no calibration-sensitive change, no eval/judge/threshold value being tuned, no cross-file structural change) → **PR-body checklist container**. Otherwise — sub-task count above the threshold, OR any multi-file / calibration-sensitive / structure-changing work — → **GitHub sub-issue container**. The predicate is evaluable from the change matrix alone before any container is created, so the choice is reproducible and reviewable.
- **PR-body checklist container (lightweight path).** The sub-task decomposition renders as a markdown task-list (`- [ ]` rows) in the release PR body — one row per file-level change or logical unit. When to use: small, simple, low-risk decompositions that clear the threshold predicate (typically additive doc/governance edits to a single shard). No GitHub sub-issues are created; the checklist rows ARE the decomposition record, checked off as each lands and visible in the PR diff at Stage 9.
- **GitHub sub-issue container (default / structured path).** One sub-issue per file-level change or logical unit, linked to the parent issue. When to use: decompositions above the threshold, or any multi-file, calibration-sensitive, or structure-changing work where per-unit tracking, native dependency edges, or independent closure state earn their overhead. This is the default whenever the predicate does not select the checklist path.

Special sub-tasks (sync, plan update, verification) are **always generated regardless of container**: in the sub-issue container they remain sub-issues; in the checklist container they render as dedicated checklist rows (one row each for sync / plan-update / verification) — they are never dropped, only re-expressed in the selected container's form. When the parent's body Dependencies field cites `FS+0d #N` deps that ALSO apply to a sub-task (sub-task-to-sub-task body deps with native-meaningful semantics), populate the sub-task's native `blocked-by` via the Stage 2 A3.5 mirror algorithm — per [`ticket-information-architecture.md § Native Dependencies — Mirror Trigger Points`](../specs/ticket-information-architecture.md#native-dependencies); native `blocked-by` edges are a sub-issue-container affordance — a decomposition carrying such deps does not qualify for the checklist path. The `[CALIBRATE-AFTER-3]` threshold value is MEDIUM-confidence and tunable after 3 releases accumulate sub-task-decomposition data per the RELEASE_LOG calibration trigger (re-review the count threshold once 3 subsequent releases close). Cutover discipline: the container threshold applies to all releases entering Stage 6 going forward; a release already past its own Stage 6 decomposition is not retroactively re-containerized.
A3 Pre-implementation file state snapshot: read all files in change matrix, flag if state diverged since Planning.

**CHECKPOINT: Present A1-A2 to operator for review before proceeding to B1.**

**Phase B — Implementation (Tier 1):**
B1 Execute per Delivery Strategy: implement in sequence order, commit per strategy, reference issue numbers in messages.

**Concurrency posture (default: serial).** Stage-6 chip routing follows the release plan's `D-Concurrency Posture` decision (per [`parallelism-posture-taxonomy.md`](../standards/parallelism-posture-taxonomy.md)). **When the posture is undeclared, the default is P0 fully-serial** — the hub routes one Engineering chip at a time per the Implementation Sequence, and the next chip waits until the prior commit lands on the release branch. Non-serial postures (P1 serialized-commit-lane / P2 per-sub-task-branch merge-queue / P3 parallel-push rebase-retry) are opt-IN and are selected only when the Stage-4 D-Gate declares them; each prohibits force-push (incl. `--force-with-lease`) on the shared release branch under multi-chip activity per the taxonomy's named-and-excluded force-push class. The default-serial floor means a release that declares no posture executes exactly as today's serial behavior. **Cutover:** the introducing release is exempt and ships under serial execution; the posture protocol applies to releases entering Stage 4 strictly after its introducing-release merge SHA.
B2 Platform convention compliance (Mode 3, concurrent): layer boundaries, naming, governance rules, evidence labels, guardrail checks. Self-correct minor issues, flag significant ones. When authoring or editing durable-corpus files — governance rules, standards, specs, disciplines, schemas, skill SKILL.md files, and committed release-plan files — apply the reference-durability standard: state rules unconditionally and inline, summarize referenced content rather than linking to it, and confine any unavoidable bare issue reference to a designated reference block with an inline summary. The reference-durability hook flags violations at Write and Edit time.
B3 Deviation handling (inter-stage feedback protocol): Minor adjustment → commit with rationale. Scope change → flag to operator. Plan rejection → stop, return upstream with blockers.

**Phase C — PR Assembly (Tier 1):**
C1 Author `## Change Description` section in the release plan FILE per [`release/governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Change Description Protocol. Section is ~60 lines, operator-facing voice, 6 sub-sections (Outcome / Issues resolved / Key decisions [conditional] / Reversibility / Downstream impact / Cross-references). Committed on the release branch BEFORE the PR is marked ready-for-review so the section is visible at Stage 9 Plan Review in the PR diff. Distinct artifact from the user-facing release note authored at Stage 13 (see [`release/references/standards/release-notes-standard.md`](../standards/release-notes-standard.md)).
C1.5 Populate the `### Documentation Impact` H3 subsection on the release PR body per [`.github/PULL_REQUEST_TEMPLATE.md`](../../../.github/PULL_REQUEST_TEMPLATE.md) (per the doc-impact resolution gate). One row per in-PR issue: declared docs (from issue body Documentation Impact field), status (LINKED / CREATED / UPDATED / NONE), commit SHAs of the docs landing on this branch, optional notes. NONE status applies when the issue declared `None — no documentation impact (rationale: ...)` at Intake. Declared docs land in the same PR as the code that motivated them — engineering does not defer doc updates to a follow-up PR. The resolution gate fires at Stage 13 (G-CL8 via deploy.sh Check 28). Scope: K1 codified corpus only. Cutover discipline: applies to all releases going forward.
C2 Create PR with full metadata (title, body, milestone, labels, assignee, reviewer, project). Body: implementation summary, per-issue status, documentation impact resolution, deviation log, verification evidence, plan link.
C3 Sync deployed copies (core/rules/, skill files per S-2 mechanism).
C4 Self-verification (Layer 1): per-issue checks, integration checks, regression checks, sync checks, **doc-link integrity** (via `core/deploy/deploy.sh --check` Check 14 — confirms every internal markdown link in modified `.md` files resolves; the link-resolver primitive has a workspace-root fallback per [`core/standards/doc-link-maintenance-protocol.md`](../../../core/standards/doc-link-maintenance-protocol.md)). Evidence in PR body. **Mirror-pair files** (`core/rules/<file>.md` ↔ `core/rules/<file>.md` pairs) MUST use **workspace-rooted form** for cross-tree references (e.g., `core/...` — no leading `../../`, no leading `/`); workspace-rooted form resolves correctly from both source and mirror locations via the primitive's workspace-root fallback. See [`core/rules/doc-link-maintenance.md`](../../../core/rules/doc-link-maintenance.md) § Path Resolution. **Runtime-suite self-verification:** when the change touches a code path mapped to a runtime suite per [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md) (rows 1–4), run the selected suite under the `/tmp` `HOME`-override sandbox (`HOME=$(mktemp -d)`) and emit a `test-run` event (`stage=6`, `actor=spoke:#N`) recording the pass/fail counts as self-verification evidence in the PR body before handoff to Dev Testing. A change matching the map's no-match row (doc/governance/spec-only) emits `test-run/suite-skip` — the honest no-op. This pre-stages the runtime gate that Stage 7 Phase A8 then re-runs as the authoritative gate input.

**Phase D — Human Review (Tier 3):**
Operator reviews PR diff. Approve + Merge / Request Changes / Reject.

**Phase E — DT Iteration Response (Tier 1, conditional):**
Activated when Stage 7 returns Tier 1 findings per the [DT↔Engineering Iteration Loop Protocol](stage-07-dev-testing.md#dtengineering-iteration-loop-protocol). Engineering receives the classified finding list, implements fixes on the release branch using the `fix(dt):` commit convention with [ADJUST] signal tag, and signals DT for targeted re-review. Tier 2/3 findings route to the operator per the general inter-stage feedback protocol — Engineering does not act on these. See the iteration loop protocol for classification criteria, escalation threshold, and tracking requirements.

**Ticket lifecycle:** Claim: set Stage→6-Engineering + Status→In Progress + `status: in-progress` label (Bundled→In Progress transition). Execute: sub-task decomposition + implementation + PR assembly. Resolve: post implementation summary, close completed sub-tasks (sub-issues closed, or checklist rows checked off, per the A2 container). Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md) Ticket Lifecycle Protocol.

**Framework dimensions touched:** Work Breakdown (commits per RI); Assignment (Software Engineer persona); Tracking (PR metadata); State Persistence (release branch). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Sub-task decomposition (GitHub sub-issues closed on completion, or PR-body checklist rows checked off, per the A2 container threshold), committed changes on release branch, PR with verification evidence, deployed copy sync, deviation log, updated release plan with implementation notes, `## Change Description` section embedded in release plan FILE per [`release/governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Change Description Protocol. When DT iteration is active (Phase E): `fix(dt):` commits on release branch, fix summary for DT re-review trigger; Change Description refreshed if Tier 1 [ADJUST] commits change which issues land or which D-decisions stand.

Engineering does NOT produce: design decisions (Stage 5), test plans beyond inherited verification (Stage 7/8), deployment execution (Stage 12), RELEASE_LOG row + visible-H4 Deployment Log (Stage 12 chore PR per [`stage-12-execute.md § Phase B5 commit mechanism`](stage-12-execute.md)), RELEASE_INDEX + RELEASE_DIGEST + RELEASE_NOTES + RELEASE_LOG VERIFIED transition (Stage 13 chore PR per [`stage-13-close.md § Phase B commit mechanism`](stage-13-close.md)). Per the chore-PR convention codified at those surfaces, the release PR ships content only; release-corpus governance artifacts land via Stage 12 + Stage 13 chore PRs per [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § PR Process (direct-to-main commits prohibited; chicken-and-egg merge-SHA constraint requires post-merge authoring). Engineering does NOT act on Tier 2/3 DT findings — those route to the operator.

**Cutover discipline:** Applies to all releases going forward.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all issues have commits, all sub-tasks resolved (sub-issues closed, or checklist rows checked off, per the A2 container), PR created with metadata and evidence, deployed copies synced, verification complete (all PASS or explained), plan updated, zero undocumented deviations, layer boundary compliance; incoming deferred items accounted (every item whose Target stage = this stage, per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md), is picked up or re-deferred with rationale — zero unaccounted incoming deferrals).
Judgment (1-5): implementation fidelity, convention compliance, verification thoroughness, deviation handling, PR reviewability.
Calibration: sub-task accuracy, deviation count by severity, verification coverage, escape rate, cycle time, self-review effectiveness.

## 8. Automation Level
Overall Tier 1 (AI-Delegated with Threshold Enforcement). Most autonomous stage — agent executes plan without intervention until PR ready. Threshold: inter-stage feedback protocol escalates to human when deviations exceed minor.
Today: agent implements in conversation. Target: Software Engineer skill Mode 1 end-to-end.

## 9. Gap Summary
14 gaps: 7 definition + 7 execution. Key: sub-task methodology reference (P2), gate manager expansion (P2), layered review model (P2).
Additional cross-cutting: Projects integration, backlog triage (P1), ticket lifecycle, environment strategy, PR metadata, tracking system config, operating model (P1).

## 10. Retro
Key lessons: Dual input paths simpler than expected — one workflow with spec depth indicator, not two workflows. Sub-task decomposition closes the issue-to-action gap. Inter-stage feedback protocol is critical but lightweight — three tiers generalize across all boundaries. Engineering is where documentation platform compression is most visible — governance rigor matters regardless of artifact type. Every release passes through all stages — no skip path (user decision). Mandatory checkpoint after A1-A2 before B1 — corrected after first execution violated the 5-step cycle.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `self-repair` | `retry` / `escalate` / `rollback` | Per autonomous-execution-model retry / escalate / rollback fires during engineering execution per [autonomous-execution-model.md § Per-Stage Application](../../../core/disciplines/autonomous-execution-model.md) | `spoke:#N` (Engineering spoke) |
| `scope-change` | `tier-1-adjust` | [ADJUST] commit landed on release branch per § Inter-Stage Feedback Protocol Tier 1 | `spoke:#N` |
| `test-run` | `suite-pass` / `suite-fail` / `suite-skip` | C4 author self-verification runs the selected runtime suite per [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md) under the `/tmp` HOME-override sandbox before handoff | `spoke:#N` (Engineering spoke) |
| `scope-change` | `tier-2-scope-change` / `tier-3-plan-rejection` | Tier 2 / Tier 3 finding surfaced to operator per § Inter-Stage Feedback Protocol | `spoke:#N` |
| `iteration` | `dt-eng-pass-N` | DT↔Eng iteration counter post-increment when Engineering re-enters from Stage 7 with Tier 1 findings; ALSO captured in `iteration-log.md` — payload carries `projects_to: iteration-log.md:<row-anchor>` | `hub` |

Cutover discipline: applies to all releases going forward.
