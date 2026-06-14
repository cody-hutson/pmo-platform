# Five-Function Spine and Cross-Cutting Process Flows

**Status:** Canonical
**Owner:** `../disciplines/five-function-spine-and-process-flows.md`
**Introduced:** platform-architecture-operating-model (2026-05-10)
**Consumers:** the future role-skill wave (HARD handoff — function-mapping data contract); the operating-model per-stage execution blueprint inlines the Primary Function value from this file's mapping table as a data column.
**Cross-references:** see § Related References at the foot of this file.

---

## Purpose

This document maps each of the 13 stages of the PMO platform's improvement-to-deployment pipeline to one or more of the 5 universal PMBOK Process Groups (Initiating, Planning, Executing, Monitoring & Controlling, Closing), enumerates the 10 cross-cutting process flows that thread through the pipeline, and documents methodology-primitive → stage variants for 3 named archetypes (Scrum, Waterfall, Kanban). The function spine is the universal framework PMBOK names as recurring across all delivery approaches; this file is the platform's authoritative anchor for that spine and the cross-cutting flows that interact with it. Canonical term definitions for [Function](../specs/terminology-glossary.md#term-function), [Process](../specs/terminology-glossary.md#term-process), and [Methodology](../specs/terminology-glossary.md#term-methodology) live in [`terminology-glossary.md`](../specs/terminology-glossary.md) — this document consumes those definitions, it does not redefine them.

---

## Function Mapping

Each stage maps to exactly **one Primary Function** + zero-or-more **Secondary Functions**. The Primary Function names what the stage primarily accomplishes in PMBOK terms; the Secondary Functions name the cross-cutting work that overlaps inside the stage (most often Monitoring & Controlling, which PMBOK treats as cross-cutting throughout the lifecycle).

### Initiating

PMBOK Process Group definition: those activities that authorize a new project, phase, or piece of work, and that establish the scope, objectives, and stakeholders before substantive design or execution begins. On the PMO platform, Initiating corresponds to demand capture and gating decisions — accepting an improvement proposal into the system and rendering the Approve/Defer/Reject decision.

- **Primary stages:** Stage 1 Intake, Stage 2 Triage.
- **Secondary footprint:** Stage 3 Bundle carries an Initiating residual (Milestone chartering).

### Planning

PMBOK Process Group definition: those activities that establish the scope, refine objectives, and define the course of action required to deliver the work. On the PMO platform, Planning corresponds to release-scope construction, dependency-ordered implementation planning, and design-decision resolution.

- **Primary stages:** Stage 3 Bundle, Stage 4 Planning, Stage 5 Solutioning.
- **Secondary footprint:** Stage 2 Triage carries Planning work (priority and dependency assessment); Stage 7 Dev Testing carries Planning work on return-to-Engineering (re-plans the change).

### Executing

PMBOK Process Group definition: those activities that complete the work defined in the plan to satisfy project requirements. On the PMO platform, Executing corresponds to file changes, deployment procedure validation, state capture, and the merge-and-deploy operation.

- **Primary stages:** Stage 6 Engineering, Stage 10 Dry Run, Stage 11 Snapshot, Stage 12 Execute.
- **Secondary footprint:** Stage 12 Execute also carries Closing residual (tag, merge, RELEASE_LOG entry).

### Monitoring & Controlling

PMBOK Process Group definition: those activities that track, review, and regulate the progress and performance of the work; identify any areas in which changes to the plan are required; and initiate the corresponding changes. On the PMO platform, Monitoring & Controlling corresponds to quality review, acceptance assessment, deployment authorization, and post-deploy verification.

- **Primary stages:** Stage 7 Dev Testing, Stage 8 QA Testing, Stage 9 Plan Review.
- **Secondary footprint:** Monitoring & Controlling appears as a Secondary function on 9 of the 13 stages — consistent with the PMBOK characterization of M&C as cross-cutting throughout the lifecycle rather than confined to a single phase.

### Closing

PMBOK Process Group definition: those activities that formally complete or close the project, phase, or contract — final acceptance, archival, lessons learned. On the PMO platform, Closing corresponds to release finalization: RELEASE_LOG entries, Issue closure, Milestone close, user-facing release-note authoring.

- **Primary stages:** Stage 13 Close.
- **Secondary footprint:** Stage 8 QA Testing carries Closing residual (acceptance sign-off approaches release closure); Stage 9 Plan Review and Stage 12 Execute both touch Closing.

### Stage → Function Mapping Table

| Stage | Primary Function | Secondary Functions | Mapping Rationale |
|---|---|---|---|
| 1 Intake | Initiating | Monitoring & Controlling | Captures demand entering the system (PMBOK Initiating); session-start drift detection is M&C |
| 2 Triage | Initiating | Planning | Approve/Defer/Reject is initiation gating; priority and dependency assessment touches Planning |
| 3 Bundle | Planning | Initiating | Building release scope is Planning Process Group work; Milestone chartering is an Initiating residual |
| 4 Planning | Planning | Monitoring & Controlling | Release-plan authoring is Planning; A4 cross-PR overlap audit is M&C |
| 5 Solutioning | Planning | Monitoring & Controlling | Design, ADR, and feasibility decisions are Planning; blast-radius and Collective Review are M&C |
| 6 Engineering | Executing | Monitoring & Controlling | Build is Executing; Tier 1/2/3 feedback to upstream and DT↔Engineering iteration are M&C |
| 7 Dev Testing | Monitoring & Controlling | Planning | Quality review against plan is M&C; return-to-Engineering re-plans the change |
| 8 QA Testing | Monitoring & Controlling | Closing | Acceptance assessment is M&C; sign-off approaches release closure |
| 9 Plan Review | Monitoring & Controlling | Closing | GO/NO-GO is an M&C gate decision; gates closure of the pre-deploy phase |
| 10 Dry Run | Executing | Monitoring & Controlling | Procedure validation is an Executing primitive; compressed in git-native releases |
| 11 Snapshot | Executing | Monitoring & Controlling | State capture is an Executing primitive; compressed in git-native releases |
| 12 Execute | Executing | Monitoring & Controlling, Closing | Deploy is Executing; verification and RELEASE_LOG entry are M&C; tag-and-merge approaches closure |
| 13 Close | Closing | Monitoring & Controlling | Finalize is Closing; QC4 post-deploy verification is M&C |

**Function distribution.** Initiating ×2 (Stages 1-2), Planning ×3 (Stages 3-5), Executing ×4 (Stages 6, 10, 11, 12), Monitoring & Controlling ×3 (Stages 7-9), Closing ×1 (Stage 13). Total = 13. Secondary footprint: Monitoring & Controlling appears as a Secondary function on 9 of 13 stages — consistent with the PMBOK characterization of M&C as cross-cutting throughout the lifecycle.

---

## Cross-Cutting Process Flows

A cross-cutting process flow is a thread of activity that recurs at multiple stages of the pipeline rather than living inside a single stage. The 10 flows below are PMBOK-aligned where the Knowledge Area has a clean analog (Risk, Change Control, Quality, Stakeholder, Communication, Configuration, Dependency) and platform-native where no clean PMBOK analog exists (Decision, Audit Trail, Continuous Improvement). Each flow traces to a canonical platform mechanism — none are invented for this document.

### 1. Risk Management Flow

The flow that captures, tracks, mitigates, and retires risks across the release lifecycle.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 3 Bundle | Release-level risk register created in the Milestone plan | Primary |
| Stage 4 Planning | Per-issue risks refined and added to the release-plan Risk Register | Primary |
| Stage 5 Solutioning | Blast-radius analysis adds design-level risks | Primary |
| Stages 6-12 | Risks monitored at each stage transition; new risks logged as discovered | Secondary |
| Stage 13 Close | Risks retired or carried forward; lessons captured | Primary |

**Canonical source.** [`release/governance/release-process.md`](../../release/governance/release-process.md) per-stage Risk Register references; per-release Risk Register section in `release/releases/plans/vX.Y_RELEASE_PLAN.md`.

### 2. Change Control Flow

The flow that governs corrective and adaptive change to scope, sequence, or design after a release plan is in execution.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 2 Triage | Re-triage when issue assumptions change | Secondary |
| Stage 4 Planning | Planning revision in response to Tier 2 [SCOPE CHANGE] | Primary |
| Stage 5 Solutioning | Re-solutioning in response to Tier 3 [PLAN REJECTION] | Primary |
| Stage 9 Plan Review | NO-GO authorizes scope or sequence change | Primary |
| Stage 12 Execute | Rollback (operator-authorized) is the change-control terminal action | Primary |

**Canonical source.** [`release/governance/release-process.md § Inter-Stage Feedback Protocol`](../../release/governance/release-process.md) (Tier 0/1/2/3); Collective Review scope-lock override per [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md).

### 3. Quality Assurance Flow

The flow that drafts acceptance criteria, validates implementation against them, and confirms post-deploy quality.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 3 Bundle | Acceptance criteria drafted per issue | Primary |
| Stage 5 Solutioning | Gate criteria refined; QC2 dependency validation | Primary |
| Stage 7 Dev Testing | QC3 pre-merge structural and content checks | Primary |
| Stage 8 QA Testing | Acceptance review against AC | Primary |
| Stage 13 Close | QC4 post-deploy verification | Primary |

**Canonical source.** [`schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md); QC1-QC4 checkpoints in [`release/governance/release-process.md § QA Checkpoint Framework`](../../release/governance/release-process.md).

### 4. Stakeholder Engagement Flow

The flow that involves the operator at decision gates and confirms shared understanding of release state.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 1 Intake | Operator-triggered intake of an improvement proposal | Primary |
| Stage 2 Triage | Operator renders Approve/Defer/Reject decision | Primary |
| Stage 9 Plan Review | Operator GO/NO-GO authorization | Primary |
| Stage 12 Execute | Operator-only deploy authorization (Autonomy Tier 3) | Primary |
| Stage 13 Close | Operator confirms release close and user-facing release note | Primary |

**Canonical source.** [`autonomy-tiers.md`](../specs/autonomy-tiers.md) Tier 3 (Manual) gate definitions; [`release-personas.md`](../../release/references/specs/release-personas.md) operator-as-Role designation.

### 5. Communication & Handoff Flow

The flow that carries structured information between hub and spoke and between adjacent stages.

| Stage | Activity at this stage | Role |
|---|---|---|
| All stages | Hub↔Spoke spawn-and-report cycle per [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) | Primary |
| Stage 5 → Stage 6 | Collective Review post-Solutioning scope lock | Primary |
| Stage 7 → Stage 8 | DT↔QA Handoff Payload | Primary |
| Stage 8 → Stage 12 | QA sign-off authorizing deployment | Primary |

**Canonical source.** [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md); [`schemas/handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md); [`schemas/stage-io-contracts.md`](../schemas/stage-io-contracts.md).

### 6. Configuration Management Flow

The flow that manages branches, commits, tags, and deployed artifacts across the release lifecycle.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 6 Engineering | Release branch creation; commit history | Primary |
| Stage 12 Execute | Merge to main; version tag; deploy via `deploy.sh` | Primary |
| Stage 13 Close | Branch cleanup; worktree detach | Primary |

**Canonical source.** [`../rules/git-workflow.md`](../rules/git-workflow.md); [`../rules/harness-deployment.md`](../rules/harness-deployment.md); `core/deploy/deploy.sh`.

### 7. Decision Management Flow

The flow that captures, evaluates, and records design and process decisions for traceability.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 4 Planning | D-Gates (decision-gating points) raised in the release plan | Primary |
| Stage 5 Solutioning | D-decisions rendered; ADR Issues opened where load-bearing | Primary |
| Stage 9 Plan Review | Operator renders final GO/NO-GO decision | Primary |

**Canonical source.** [`decision-discipline.md`](../disciplines/decision-discipline.md) (Localization Check, Opposing-View, Pattern Cache Scan); D-Gate Template per [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) Procedure 0.

### 8. Audit Trail / Knowledge Capture Flow

The flow that records the evidence and rationale behind each stage transition, accumulating a queryable history for future audit and learning.

| Stage | Activity at this stage | Role |
|---|---|---|
| All automated stages | Gate-evaluation records appended to [`evals/results/calibration-data.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) | Primary |
| All automated stages | Iteration events recorded in [`evals/results/iteration-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md) | Primary |
| Stage 12 Execute | Deployment evidence appended to RELEASE_LOG.md | Primary |

**Canonical source.** [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md); [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md).

**Future unification.** Tracked for future evaluation. The five-function mapping above may inform whether the per-stage audit-trail capture schema can normalize at the function level (5 schemas — one per function) rather than the stage level (13 schemas — one per stage). Solutioning will independently evaluate; this file only provides the mapping that enables the option.

### 9. Continuous Improvement Flow

The flow that surfaces gaps, drift, and improvement opportunities at every stage and feeds them back into the Intake stage as new GitHub Issues.

| Stage | Activity at this stage | Role |
|---|---|---|
| All stages | Auto-logging of gaps, drift, and improvement candidates as GitHub Issues per CLAUDE.md § Continuous Improvement | Primary |
| Stage 1 Intake | Improvements re-enter the pipeline as new Triage candidates | Primary |

**Canonical source.** [`../../CLAUDE.md § Continuous Improvement`](<OPERATOR_INSTANCE_CLAUDE_MD>); [`../governance/OPERATIONS.md § Continuous Improvement Protocol`](../governance/OPERATIONS.md).

### 10. Dependency Management Flow

The flow that constructs the dependency graph, validates dependency state at gates, and re-validates after design discoveries.

| Stage | Activity at this stage | Role |
|---|---|---|
| Stage 2 Triage | G2-04 dependency state validation per gate criteria | Primary |
| Stage 3 Bundle | Dependency graph constructed across approved issues | Primary |
| Stage 4 Planning | Dependency ordering refined in implementation sequence | Primary |
| Stage 5 Solutioning | QC2 re-validation after blast-radius analysis | Primary |

**Canonical source.** [`schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) G2-04 (Stage 2 dependency state) + G3-06 (Stage 3 dependency graph); QC2 checkpoint in [`release/governance/release-process.md`](../../release/governance/release-process.md).

### Count Rationale

The 10 flows above were arrived at by enumeration against PMBOK Knowledge Areas and the platform's canonical reference mechanisms, then validated against the alternative of fewer or more flows.

- **Fewer would conflate distinct mechanisms.** Risk Management and Change Control are distinct PMBOK Knowledge Areas with separate platform sources (Risk Register vs. Inter-Stage Feedback Protocol); collapsing them loses per-flow citation discipline. Quality Assurance and Audit Trail are likewise distinct surfaces (gate criteria vs. captured evidence).
- **More would over-fragment.** Considered and rejected as separate flows: (a) Rollback / Reversibility Management — too narrow; rolled into Change Control. (b) Cost / Resource Management — not applicable to a single-operator PMO. (c) Procurement Management — not applicable. (d) Schedule Management — overlaps with Configuration (release cadence) and the Methodology Variants section below; rolled into those. (e) Issue Management — overlaps with Change Control and Audit Trail; rolled in.
- **Why these 10 specifically.** Each maps 1:1 to either a PMBOK Knowledge Area (Risk, Change, Quality, Stakeholder, Communication, Configuration, Scope via Change Control implicitly, Dependency under Schedule/Integration) or a platform-native mechanism with no clean PMBOK analog (Decision Discipline, Audit Trail, Continuous Improvement). No invented flows.

---

## Methodology Variants

**Coverage scope.** This section maps methodology primitives (ceremonies, phases, flow items) from 3 named archetypes (Scrum, Waterfall, Kanban) to the 13 pipeline stages. For archetype properties (lifecycle, ceremonies, artifacts, cadence enum) across all 8 archetypes, see [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md). For per-archetype release-cadence variation specifically, see [`release/governance/release-process.md § Methodology Variation — Release Cadence`](../../release/governance/release-process.md). These three sources occupy distinct, non-overlapping slots in the methodology-variation problem space: archetype-properties (matrix), release-cadence (release-process.md), and methodology-primitive → stage mapping (this section). Consumers reading this section for archetype-properties or release-cadence variation should follow the cross-reference rather than treat this section as authoritative for those slots.

### Scrum

The 13 stages execute within sprint cadence. Stage 3 Bundle aligns to sprint-planning commitment (the sprint is the release boundary); Stages 5-8 happen within the sprint; Stage 12 Execute aligns to sprint-end ship; Stage 13 Close aligns to sprint retrospective. Sprint commitment is protected through Stages 6-9 — no mid-sprint scope push. Cross-references: [`release/governance/release-process.md § Methodology Variation — Release Cadence § Scrum`](../../release/governance/release-process.md), [`methodology-archetype-matrix.md § Scrum`](../../release/references/specs/methodology-archetype-matrix.md).

### Waterfall

Stages map approximately 1:1 to traditional Waterfall phases — Stages 1-2 ≈ Requirements, Stages 3-5 ≈ Design, Stages 6-7 ≈ Build, Stage 8 ≈ Test, Stage 9 ≈ Deployment Authorization, Stages 12-13 ≈ Deployment + Close. Stage 9 Plan Review is the Change Control Board signoff; cross-phase backflow (e.g., Stage 6 returning to Stage 5) requires formal change-control authorization, not just inter-stage feedback Tier 2. Cross-references: [`release/governance/release-process.md § Methodology Variation — Release Cadence § Waterfall`](../../release/governance/release-process.md), [`methodology-archetype-matrix.md § Waterfall`](../../release/references/specs/methodology-archetype-matrix.md).

### Kanban

Stages run continuously per work item — there is no batch boundary. Stage 12 Execute fires per-item at flow; Stage 3 Bundle compresses to a per-cadence replenishment event rather than a sprint commitment. WIP limits gate movement between stages. Stage 13 Close maps to a cadence-based service-delivery review, not a per-release retrospective. Cross-references: [`release/governance/release-process.md § Methodology Variation — Release Cadence § Kanban`](../../release/governance/release-process.md), [`methodology-archetype-matrix.md § Kanban`](../../release/references/specs/methodology-archetype-matrix.md).

### Methodology-Primitive → Stage Mapping Table

| Stage | Scrum (ceremonies) | Waterfall (phases) | Kanban (continuous flow) |
|---|---|---|---|
| 1 Intake | Captured during sprint planning or refinement; PBI creation | Requirements Capture phase | Continuous pull from intake board |
| 2 Triage | Backlog refinement (grooming); story-point estimation | Requirements analysis and sign-off | Triage replenishment cadence |
| 3 Bundle | Sprint backlog commitment (per-sprint scope) | Project plan or WBS approval | Release-cadence batch (per-window scope) |
| 4 Planning | Sprint planning (capacity vs. velocity) | Detailed design phase planning | Continuous flow plan; WIP-limit reset |
| 5 Solutioning | Spike or design spike during sprint | Design phase (HLD / LLD) | Just-in-time design at pull |
| 6 Engineering | Sprint execution (in-sprint dev) | Build phase | Pull-based execution (next-in-flow) |
| 7 Dev Testing | In-sprint dev testing (pair, TDD if XP-adjacent) | Build-phase dev testing | Per-item dev testing at flow |
| 8 QA Testing | Sprint demo or acceptance review | Test phase (UAT) | Per-item QA at flow |
| 9 Plan Review | Sprint review (stakeholder demo + accept) | Deployment Authorization (Change Control Board) | Pre-merge service-delivery review |
| 10 Dry Run | (Compressed; in-sprint validation) | Deployment dress rehearsal | (Compressed; CI validation gate) |
| 11 Snapshot | (Compressed; git tag at sprint-end) | Pre-deployment baseline capture | (Compressed; git tag at item-merge) |
| 12 Execute | Sprint-end release | Deployment phase | Continuous deployment |
| 13 Close | Sprint retrospective | Project closeout or phase-gate close | Service-delivery retrospective (cadence) |

**Note on the 5 archetypes not covered here.** XP, PRINCE2, SAFe, Hybrid, and Custom are out of scope for this 3-archetype table per the issue scope. For their archetype properties see [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md); for their release-cadence variation see [`release/governance/release-process.md § Methodology Variation — Release Cadence`](../../release/governance/release-process.md). When a non-canonical variant is encountered (Scrumban, Shape Up, etc.), consumer skills use the `custom_methodology_definition` block in PROJECT.md per [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md) and derive the stage mapping from the declared lifecycle, ceremonies, artifacts, and cadence fields.

---

## Related References

- **Operating-model perspective on these stages:** see [`operating-model.md`](../disciplines/operating-model.md) for the per-stage Skill Ownership, Governance Composition, and Execution Blueprint. Each stage row in that file inlines this document's Primary Function as a data column; refer back here for Secondary Functions and Cross-Cutting Flow touchpoints.
- **Archetype properties (8 archetypes):** [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md).
- **Archetype normative definitions (8 archetypes):** [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md).
- **Release-cadence variation (8 archetypes):** [`release/governance/release-process.md § Methodology Variation — Release Cadence`](../../release/governance/release-process.md).
- **13-stage pipeline reference directory:** [`pipeline/README.md`](../../release/references/pipeline/README.md).
- **Canonical term definitions:** [`terminology-glossary.md`](../specs/terminology-glossary.md) (Function, Process, Methodology, Framework).
- **Design rationale for this file:** [`../ADRs/ADR-004-five-function-spine.md`](../ADRs/ADR-004-five-function-spine.md) records the rationale for the Primary+Secondary function-mapping scheme, the 10-flow cross-cutting taxonomy, and the 13×3 archetype × stage variants matrix. Future authors revisiting any of these decisions should consult ADR-004 before re-designing.
- **Process-flow diagram standards:** [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md) — canonical authority for Mermaid syntax, swimlane notation, and the color/shape grammar of any process-flow diagram. Forward-only scope; retroactive retrofit tracked separately.
