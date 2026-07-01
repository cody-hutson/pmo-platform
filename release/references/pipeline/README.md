# release/references/pipeline/ — Pipeline Stage Definitions

**Purpose:** Per-stage pipeline reference — one self-contained `stage-NN-<name>.md` per stage of the 13-stage improvement-to-deployment pipeline, plus the cross-layer Framework-Alignment and Methodology-Variation tables.
**Organization:** One file per stage following the 10-point framework; this README carries the Stage Index, Cross-Cutting Reference Map, and the alignment tables.
**Governance:** [core/governance/OPERATIONS.md](../../../core/governance/OPERATIONS.md) § README-Per-Folder Convention; the concise operating procedure is [release/governance/release-process.md](../../governance/release-process.md).
**Layer:** 1 (Engineering, git-tracked)

## Overview

The PMO platform uses a 13-stage improvement-to-deployment pipeline, compressed from the PMO Reference Model Part 6 (15-stage universal delivery lifecycle) for a single-operator PMO. The pipeline transforms improvement proposals into deployed platform changes through three parallel workstreams:

The 13-stage pipeline is the [Process](../../../core/specs/terminology-glossary.md#term-process) layer of the platform's governance hierarchy. [Methodology](../../../core/specs/terminology-glossary.md#term-methodology) parameterization (which delivery approach — Scrum, Kanban, Waterfall, etc.) lives in [methodology-parameterization-v1.md](../specs/methodology-parameterization-v1.md); the tool-agnostic execution patterns shared across methodologies live in [execution-framework.md](../../../core/disciplines/execution-framework.md). See [§ Framework Alignment](#framework-alignment) below.

1. **Future-State Process** — define what each stage should look like per Reference Model + Skills Matrix + automation targets
2. **First Deployment** — execute real releases using the future-state process (the pipeline proves itself by deploying itself)
3. **Gap Analysis** — identify gaps between current state and future-state standard; log as GitHub Issues

The pipeline design standard is defined in `core/standards/per-stage-shard-standard.md`. Each stage follows the 10-point framework documented there.

**Cross-stage purpose contract.** Each phase of the pipeline owns a distinct kind of work, and the phases do not overlap: **early (Intake / Triage / Bundle / Planning) = map current state / surface gaps · Solutioning = design · Engineering = build/tweak · QA = validate.** The early stages establish and enrich what is true now and where the gaps are (they do not design or build); Solutioning decides the design; Engineering builds or tweaks against that design; QA validates the built result against acceptance criteria. Each stage's §1 Purpose states its stage-specific detail; this contract fixes the phase-level intent those purposes express so no stage silently drifts into another phase's job (e.g., Planning does not design; Engineering does not re-open design).

## How to Read This Directory

- This directory contains one file per stage of the 13-stage pipeline
- Each `stage-NN-<name>.md` is self-contained and follows the 10-point framework (Purpose / Reference Model Alignment / Persona / Inputs / Process / Outputs / Stage-Transition Gate / Automation Level / Gap Summary / Retro)
- Anchor convention: `pipeline/stage-NN-<name>.md#N-section-name` (e.g., `stage-05-solutioning.md#5-process`, `stage-07-dev-testing.md#7-stage-transition-gate`)
- This directory is the **compiled design reference** — the versioned record of stage definitions
- For the **concise operating procedure** (~5 lines per stage), see [`release/governance/release-process.md`](../../governance/release-process.md)
- Stage definitions originate as GitHub Issues; this directory compiles them into a single navigable reference
- This directory replaces the legacy monolithic `pipeline-stages.md` (split per ADR-002)

## Stage Index

| # | Stage | File | One-line summary |
|---|---|---|---|
| 1 | Intake | [stage-01-intake.md](stage-01-intake.md) | Capture improvement proposals via structured GitHub Issue templates |
| 2 | Triage | [stage-02-triage.md](stage-02-triage.md) | Render Approve/Reject/Defer decision with priority and dependency validation |
| 3 | Bundle | [stage-03-bundle.md](stage-03-bundle.md) | Group Approved issues into a versioned Milestone with capacity heuristics |
| 4 | Planning | [stage-04-planning.md](stage-04-planning.md) | Produce dependency-ordered release plan with file-level change specifications |
| 5 | Solutioning | [stage-05-solutioning.md](stage-05-solutioning.md) | Resolve technical design decisions; produce ADRs and implementation-ready specs |
| 6 | Engineering | [stage-06-engineering.md](stage-06-engineering.md) | Decompose into sub-tasks; implement on release branch; produce reviewable PR |
| 7 | Dev Testing | [stage-07-dev-testing.md](stage-07-dev-testing.md) | Independent quality review of PR — Layer 2 automated review |
| 8 | QA Testing | [stage-08-qa-testing.md](stage-08-qa-testing.md) | Acceptance review against AC — the gate before deployment |
| 9 | Plan Review | [stage-09-plan-review.md](stage-09-plan-review.md) | Operator GO/NO-GO decision authorizing deployment |
| 10 | Dry Run | [stage-10-dry-run.md](stage-10-dry-run.md) | Deployment procedure validation (compressed for git-native releases) |
| 11 | Snapshot | [stage-11-snapshot.md](stage-11-snapshot.md) | Pre-change state capture (compressed — git history is the snapshot) |
| 12 | Execute | [stage-12-execute.md](stage-12-execute.md) | Merge PR, tag release, deploy changed files |
| 13 | Close | [stage-13-close.md](stage-13-close.md) | Update RELEASE_LOG, close issues, finalize Milestone |

## Cross-Cutting Reference Map

| Reference | Where Defined | Used By |
|---|---|---|
| [Framework Alignment](#framework-alignment) | Below in this README | Every stage (cross-layer model) |
| [Methodology Variation](#methodology-variation-across-stages) | Below in this README | Every stage (per-archetype variation) |
| [Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol) | release-process.md | All stage transitions (Tier 0/1/2/3) |
| [Release-Level Checkpoint: Collective Review](stage-05-solutioning.md#release-level-checkpoint-collective-review) | stage-05-solutioning.md | Post-Stage-5, pre-Stage-6 |
| [DT↔Engineering Iteration Loop Protocol](stage-07-dev-testing.md#dtengineering-iteration-loop-protocol) | stage-07-dev-testing.md | Stage 6↔7 boundary |
| [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol) | stage-07-dev-testing.md | Stage 7↔8 boundary |
| [Gate Evaluation Spec](../../../core/schemas/gate-evaluation-spec.md) | schemas/ | All stage transitions |
| [Handoff Coordinator Spec](../../../core/schemas/handoff-coordinator-spec.md) | schemas/ | All stage transitions |
| [Stage I/O Contracts](../../../core/schemas/stage-io-contracts.md) | schemas/ | Stage 3→4, Stage 4→5, Stage 5→6, Stage 12→13 boundaries |
| [Per-Stage Shard Standard](../../../core/standards/per-stage-shard-standard.md) | standards/ | Authoring or materially modifying any shard in this directory (canonical 10-H2 structure + variants) |

> **Cutover discipline:** Applies to all releases going forward.

## Framework Alignment

This directory is the Process-layer authority for the 13-stage pipeline. The stages define WHAT sequence runs; they do not define HOW execution happens within a stage (that is the [Framework](../../../core/specs/terminology-glossary.md#term-framework) layer) nor WHICH delivery approach parameterizes the work (that is the [Methodology](../../../core/specs/terminology-glossary.md#term-methodology) layer).

| Layer | Authority | Role |
|---|---|---|
| **Process** | This directory | Sequence of stages, per-stage 10-point structure |
| **Methodology** | [methodology-parameterization-v1.md](../specs/methodology-parameterization-v1.md) | Delivery approaches (Scrum/Kanban/Waterfall/…) that parameterize per-stage variation |
| **Framework** | [execution-framework.md](../../../core/disciplines/execution-framework.md) | Tool-agnostic execution patterns (work breakdown, assignment, tracking, handoff, state persistence) |
| **Tool** | [hub-spoke-bridge.md](../how-to/hub-spoke-bridge.md), [implementation-execution-pattern.md](../how-to/implementation-execution-pattern.md), skills | Specific implementations of framework patterns |

Per-stage `## 5. Process` sections include a `**Framework dimensions touched:**` line identifying which of the 5 execution-framework dimensions (Work Breakdown / Assignment / Tracking / Handoffs / State Persistence) the stage primarily exercises. Cross-reference for agents implementing stage logic per framework contract.

---

## Methodology Variation Across Stages

**Purpose.** The 13-stage pipeline is the platform's canonical delivery [Process](../../../core/specs/terminology-glossary.md#term-process) and is invariant across methodologies — every release moves through Intake → Triage → … → Close regardless of `delivery_approach`. What VARIES per archetype is *how* individual stages manifest: cadence, ceremony mapping, gate framing, and artifact emphasis. This section is the authoritative per-archetype lookup table.

**How to read.** Each row names an archetype (per the canonical [`delivery_approach` enum](../../../core/schemas/project-schema.md)). The **Variation** column describes how the 13-stage Process is expressed under that archetype. The **Applies to** column back-references the specific stage numbers where the variation is most visible. The **Notes** column carries evidence and cross-references. Methodology Variation sections across the platform use the canonical H2 phrase `Methodology Variation` so agents can grep-enumerate all variation sites.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Scrum** | Stages compress to fit sprint cadence (typically 2-week). Stage 4 Planning maps to Sprint Planning; Stage 6 Engineering runs as sprint execution; Stage 7-8 testing happens inside the sprint; Stage 13 Retro maps to Sprint Retrospective. Scope commitment at Stage 3 Bundle is protected through Stages 6-9 (no mid-sprint scope push). | §[Stage 3](stage-03-bundle.md), §[Stage 4](stage-04-planning.md), §[Stage 6](stage-06-engineering.md), §[Stage 13](stage-13-close.md) | [SOURCE] Scrum Guide 2020 (sprint commitment protection). Matches [`methodology-archetype-matrix.md` § Scrum](../specs/methodology-archetype-matrix.md). |
| **Kanban** | Stages run as continuous flow, not batch-sprint cycles. Stage 3 Bundle is soft — issues can enter/exit a release pull at any point subject to WIP limits. Stage 6 Engineering and Stage 7 Dev Testing pull new work as capacity opens; no sprint-boundary synchronization. Stage 13 Retro maps to cadence-based service-delivery review, not per-release retro. | §[Stage 3](stage-03-bundle.md), §[Stage 6](stage-06-engineering.md), §[Stage 12](stage-12-execute.md) | [SOURCE] Kanban Method (Anderson, 2010) — WIP-limited pull system. |
| **XP** | Like Scrum timebox structure but with engineering practices elevated to gate criteria: Stage 6 Engineering MUST show pair-programming evidence + TDD test-first evidence; Stage 7 Dev Testing verifies CI health + refactor-frequency signals; Stage 8 QA accepts acceptance-tests-as-specs. | §[Stage 6](stage-06-engineering.md), §[Stage 7](stage-07-dev-testing.md), §[Stage 8](stage-08-qa-testing.md) | [SOURCE] Extreme Programming Explained (Beck, 2004). Shares Scrum timebox; diverges on engineering-governance requirements. |
| **Waterfall** | Stages run sequentially with formal phase-gates — Stage 9 Plan Review is a phase-gate review (no phase exit without explicit gate sign-off), not a continuous authorization. Stage 4-5 are front-loaded; change control governs cross-stage backflow (Stage 6 returning to Stage 5 requires CCB approval, not just inter-stage feedback Tier 2). | §[Stage 4](stage-04-planning.md), §[Stage 5](stage-05-solutioning.md), §[Stage 9](stage-09-plan-review.md), §[Stage 12](stage-12-execute.md) | [SOURCE] PMBOK predictive lifecycle + Royce "Managing the Development of Large Software Systems" (1970). |
| **PRINCE2** | Stages grouped into management stages bounded by end-stage assessments. Stage 9 Plan Review maps to end-stage assessment by Project Board (continue / cease / re-plan decision); Stage 13 Close maps to end-project assessment. Highlight-report cadence runs across all stages — Stage 6 Engineering produces highlight reports regardless of iteration pattern. | §[Stage 3](stage-03-bundle.md), §[Stage 9](stage-09-plan-review.md), §[Stage 13](stage-13-close.md) | [SOURCE] PRINCE2 2017 — management stages, Project Board authority. |
| **SAFe** | Stages aggregate into Program Increments (PIs, typically 8-12 weeks). Stage 3 Bundle maps to PI Planning; Stages 6-8 run as multiple sprints inside the PI with Scrum-of-Scrums synchronization; Stage 9 Plan Review maps to System Demo + Inspect & Adapt workshop. Release-train-level dependencies cross-reference PI objectives. | §[Stage 3](stage-03-bundle.md), §[Stage 4](stage-04-planning.md), §[Stage 9](stage-09-plan-review.md), §[Stage 13](stage-13-close.md) | [SOURCE] SAFe 6.0 — PI cadence + ART-level synchronization. Semantic anchor: SAFe ≠ "scaled Scrum" — see [`methodology-parameterization-v1.md § SAFe`](../specs/methodology-parameterization-v1.md). |
| **Hybrid** | Stages partition by phase: upstream stages (Stages 4-5 Planning/Solutioning) run predictive (Waterfall-style front-loaded); downstream stages (Stages 6-8 Engineering/DT/QA) run iterative (Scrum or Kanban). Stage 9 Plan Review is the bridge gate — authorizes iterative downstream work against the predictive upstream plan. | §[Stage 4](stage-04-planning.md), §[Stage 5](stage-05-solutioning.md), §[Stage 6](stage-06-engineering.md), §[Stage 9](stage-09-plan-review.md) | [INFERRED] From PMBOK 7 hybrid guidance; platform operationalization via [`methodology-parameterization-v1.md § Hybrid`](../specs/methodology-parameterization-v1.md) semantic anchor. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive stage cadence and gate framing from declared `lifecycle`, `ceremonies`, `artifacts`, `cadence` fields. Skills MUST NOT default to any archetype when `base_archetype` is `null`; the block IS the authoritative stage-variation source. | All stages | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](../specs/methodology-parameterization-v1.md). Three worked examples (Scrumban, Shape Up, Scrum-no-estimation) in [`methodology-archetype-matrix.md § Custom Row`](../specs/methodology-archetype-matrix.md). |

**Consumer guidance.** Stage agents reading a specific stage (e.g., Stage 6 Engineering) SHOULD cross-reference the row(s) above whose `Applies to` column names that stage, and parameterize their behavior accordingly. When a row does not name the stage, default behavior per the stage's Definition, Process, and Transition Gate subsections applies — the variation table enriches, not overrides, the invariant Process.

---

**Migration note:** This directory replaces the legacy `core/pipeline-stages.md` (1,317 lines, 13 stages, 3 nested protocols). Cascade-completed: 115 substantive references rewritten across 33 files per [ADR-002](../../ADRs/ADR-002-modular-pipeline-stages-split.md). Historical references preserved as-is in archive classes (release plans, RELEASE_LOG, analysis artifacts).
