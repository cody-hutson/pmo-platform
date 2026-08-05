---
title: Stage-to-Skill-Mode Mapping
purpose: Maps each of the 13 pipeline stages to its primary owning skill, mode, automation tier, and gap notes; functions as the build spec for future skill-mode work.
applies_to: 13-stage pipeline (`pipeline/`); 6 in-scope skills per the Agent Runbook (`pmo-qa-auditor`, `pmo-skill-editor`, `pmo-technical-analyst`, `release-executor`, `release-planner`, `ppm-agent`).
related: pipeline/, release-personas.md, release-process.md, gate-criteria-spec.md
last_updated: 2026-07-09
---
<!-- reference-durability: allow-link -->

# Stage-to-Skill-Mode Mapping

This document maps each of the 13 pipeline stages defined in [`pipeline/`](../pipeline) to its primary owning skill, the mode within that skill that applies, the automation tier (per Stage 4 D-3 decision), and a gap note where existing skill capability does not cover the stage. Scope is narrowed to the 6 primary skills already listed in the Agent Runbook (`pmo-qa-auditor`, `pmo-skill-editor`, `pmo-technical-analyst`, `release-executor`, `release-planner`, `ppm-agent`) per #8 risk mitigation. Other skills (22+ total in `release/skills/`) are not per-row assigned here — most are project-ops scoped (sprint planning, comms drafting, project artifact generation) or platform-meta scoped (skill creation, eval authoring) and do not own a pipeline stage. The mapping becomes the build spec for future skill-mode slices that fill identified gaps.

**Tier vocabulary.** "Automation Tier" follows convention 3 in [`autonomy-tiers.md`](../../../core/specs/autonomy-tiers.md) § Tier Disambiguation Table — the [`pipeline/`](../pipeline) per-stage tier (Tier 1 Auto / Tier 2 Recommend / Tier 3 Human-only) classifying authorization posture per stage transition. Distinct from Skill Tier (`OPERATIONS.md`), Document Tier (CLAUDE.md File Management Protocol), and Autonomy Tier ([`autonomy-tiers.md`](../../../core/specs/autonomy-tiers.md) per-action classification).

## Stage Mapping Table

| Stage | Stage Name | Primary Skill | Skill Mode | Automation Tier | Gap Notes |
|---|---|---|---|---|---|
| 1 | Intake | — | — | Tier 2 (Recommend) | **GAP** — no scoped skill owns platform-internal improvement-issue authoring against `pmo-platform` repo. `ppm-agent` Section 10 Handoff Manifest produces follow-ups but does not author GitHub Issues. Forward-ref: **intake skills**. |
| 2 | Triage | `pipeline-triage` | (single-purpose skill — runs A1–A6.5) | Tier 2 (Recommend) | Coverage. [`pipeline-triage`](../../skills/pipeline-triage/SKILL.md) owns Workflow Readiness gate execution (G1/G2 per [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md)) over the `status: proposed` **improvement** backlog — auto-executes A1–A6.5 and produces the consolidated triage summary; verdict (B1–B3) stays operator-only (Tier 3). Distinct from `delivery-engine`'s sprint-backlog (project-ops) triage modes. |
| 3 | Bundle | `release-planner` | Mode A — Backlog Analysis | Tier 2 (Recommend) | Coverage. Mode A produces dependency graph + suggested bundles + version recommendations. Stage 3 Release Readiness gate (Gate 3 criteria) executes upstream of Mode A output. Forward-ref: **release-planner Bundle mode** enrichment. |
| 4 | Planning | `release-planner` | Mode B — Release Planning | Tier 2 (Recommend) | Coverage. Mode B writes `release/releases/plans/[version]_RELEASE_PLAN.md` with implementation sequence, dependency ordering, risk register. |
| 5 | Solutioning | `pmo-principal-engineer` | Mode A — Architecture & NFR Governance; Mode B — Build-vs-Buy & Design Review | Tier 2 (Recommend) | Coverage. Forward-ref **resolved**: `pmo-principal-engineer` shipped and owns Stage 5, matching the [`release-personas.md`](release-personas.md) Stage 5 persona (Principal Engineer — Architecture Assessment) directly. The prior `pmo-technical-analyst` Mode C bridging fit is **discharged** — that skill is project-ops scoped (vendor FDDs, IDDs, ERP architectures) and no longer owns this stage; it remains available as a composed technical-review input. |
| 6 | Engineering | — | — | Tier 1 (Auto) with Tier 3 checkpoint | **GAP** — no scoped skill. Existing reference workflow [`implementation-execution-pattern.md`](../how-to/implementation-execution-pattern.md) (supersedes deprecated implementer skill per implementation-execution-pattern.md) is the procedure. `release-executor` handles approved-plan execution (Stage 12) not engineering implementation; `pmo-skill-editor` Mode A handles skill-only edits (subset). Forward-ref: **role skills** (engineering-skill candidate). |
| 7 | Dev Testing | `pmo-qa-auditor` (primary) + `pmo-skill-editor` (skill modifications) | `pmo-qa-auditor` Mode G — Dev Testing (PR + release plan → eval-assertion ladder → PR-comment quality report); `pmo-skill-editor` Mode C — Regression | Tier 1 / Tier 2 (mixed: structural auto, judgment recommend) | Coverage. Mode G executes Stage 7 Phases A–D per [`stage-07-dev-testing.md`](../pipeline/stage-07-dev-testing.md) §5 (Phase E stays operator/hub-owned); `pmo-skill-editor` Mode C runs friction-log regression checks for skill-modification PRs. Forward-ref resolved: the dedicated mode planned per [`release-personas.md`](release-personas.md) Stage 7 shipped as **Mode G — Dev Testing**. |
| 8 | QA Testing | `pmo-qa-auditor` | Mode H — Acceptance Review (GitHub Issue AC → per-criterion verdicts under the Stage-8 six-value enum → Acceptance Report); Mode B — Cross-Skill Coherence Review for cross-issue coherence in multi-issue releases | Tier 2 (Recommend) | Coverage. Mode H executes Stage 8 Phases A–C + report assembly per [`stage-08-qa-testing.md`](../pipeline/stage-08-qa-testing.md) §5, consuming the acceptance-assertion contract (enum verbatim; all-drift-out score); the acceptance verdict stays operator-rendered (Phase E). Forward-ref resolved: the dedicated mode planned per [`release-personas.md`](release-personas.md) Stage 8 shipped as **Mode H — Acceptance Review**. |
| 9 | Plan Review | — | — | Tier 3 (Human-only) | **Decision gate: GAP BY DESIGN** — the go/no-go DECISION is Tier-3 operator-only; no skill renders it, and none is planned per [`release-personas.md`](release-personas.md) Stage 9 ("hub presents decision to operator, no spoke launched"). `ppm-agent` Section 5 (Decisions needed) + gate-decision documentation pattern provide the briefing scaffold. **Evidence-assembly sub-step: COVERED** (out-of-table cross-reference) by `pmo-release-manager` Mode 1 (Go/No-Go Evidence) — Tier-1 auto-compiles the evidence package per [`stage-09-plan-review.md`](../pipeline/stage-09-plan-review.md) §5 Phase A; it feeds the gate, it does not render the decision. |
| 10 | Dry Run | `release-planner` | Mode C — Dry Run (when activated) | Tier 1 (Auto) — compressed for git-native | Compressed per [`release-process.md`](../../governance/release-process.md) § Stage Compression. PR diff IS the dry-run for git-native releases. Mode C activates explicitly only when compression exceptions apply (non-git deploy targets, destructive operations, Layer 2 file deployment with new mechanism). |
| 11 | Snapshot | `release-executor` | Mode A — Execute Release (snapshot phase, when activated) | Tier 1 (Auto) — compressed for git-native | Compressed per [`release-process.md`](../../governance/release-process.md) § Stage Compression. Git history IS the snapshot mechanism for git-native releases. Snapshot phase of `release-executor` Mode A activates only for non-git deploy targets per [`RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md). |
| 12 | Execute | `release-executor` | Mode A — Execute Release | Tier 1 (Auto) with Tier 3 gate | Coverage. Operator authorizes Stage 9 GO; Mode A executes merge/tag/deploy sequence + RELEASE_LOG.md update + GitHub Projects field updates per [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md). Forward-ref: **concurrency** — Stage 12 may gain concurrency-control logic for parallel-PR scenarios. |
| 13 | Close | `release-executor` | Mode B — Verify Release | Tier 1 (Auto) | Coverage. Mode B verifies deployment artifacts + closes Milestone + appends RELEASE_LOG.md verification evidence per [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md). Forward-ref: **concurrency** — Stage 13 verification may gain cross-release dependency-check logic. |

## Gaps

Five gaps surfaced by the table: two open skill-build candidates (G1, G4), two **resolved** (G2 — the `pipeline-triage` skill now owns Stage 2; G3 — `pmo-principal-engineer` shipped and replaced the `pmo-technical-analyst` Mode C bridging assignment at Stage 5), and one structural gap by design (G5).

### G1: Stage 1 (Intake) — no improvement-issue authoring skill

- **Stage role:** Capture improvement proposals as GitHub Issues with structured fields per `improvement.yml` / `observation.yml` templates.
- **Why no current skill fits:** `ppm-agent` processes project artifacts → project-tracker outputs (not GitHub Issues against `pmo-platform`). `pmo-skill-editor` edits skills. `pmo-technical-analyst` reviews vendor artifacts.
- **Forward-reference:** intake skill expansion. Likely successor: `platform-improvement-intake` skill consuming operator observations + session-end candidate improvements + authoring `improvement.yml`-conformant issues.

### G2: Stage 2 (Triage) — RESOLVED by the `pipeline-triage` skill

- **Stage role:** Evaluate each issue for priority, feasibility, fit; produce Approved/Deferred/Rejected decision; run dependency-state validation (G2-04).
- **Resolution:** the [`pipeline-triage`](../../skills/pipeline-triage/SKILL.md) skill (release module) owns this stage — it auto-executes A1–A6.5 over the `status: proposed` improvement backlog and produces the consolidated triage summary; the verdict stays operator-only (Tier 3). Standalone-skill decision per ADR-063 (delivery-engine / release-planner / ppm-agent all ruled out: `delivery-engine` triage modes are sprint-backlog project-ops; `ppm-agent` produces decision frames but doesn't run the Workflow Readiness gate; `release-planner` Mode A consumes Approved issues, downstream of triage).

### G3: Stage 5 (Solutioning) — CLOSED, `pmo-principal-engineer` owns the stage

- **Stage role:** Resolve technical design decisions, validate feasibility, produce implementation-ready specifications. Per [`release-personas.md`](release-personas.md) Stage 5: Principal Engineer — Architecture Assessment.
- **Resolution:** `pmo-principal-engineer` shipped and is the stage owner. Its Modes A (Architecture & NFR Governance) and B (Build-vs-Buy & Design Review) are platform-internal-design scoped, which is what the stage needs and what the prior bridge lacked.
- **Why the bridge existed and why it is gone:** `pmo-technical-analyst` Modes A-E target vendor/project artifacts; Mode C was the closest available fit while no platform-internal design skill existed. Stage 5 targets platform-internal design — a different domain — so the fit was always partial and the persona card named the Principal Engineer skill as the replacement. That replacement has landed, so the bridging arrangement is **discharged**, not merely deprecated.

### G4: Stage 6 (Engineering) — reference workflow only, no skill

- **Stage role:** Execute release plan; decompose issues into sub-tasks; implement file changes; produce PR.
- **Why no skill fits:** Deprecated `implementer` skill superseded by [`implementation-execution-pattern.md`](../how-to/implementation-execution-pattern.md) — procedure document, not skill. `release-executor` executes approved plans (Stage 12), not engineering implementation. `pmo-skill-editor` Mode A handles skill-only edits (subset).
- **Forward-reference:** role skills (engineering-skill candidate).

### G5: Stage 9 (Plan Review) — decision gate by design; evidence-assembly covered by Mode 1

Stage 9 splits into two sub-steps with distinct coverage: the **Tier-3 decision gate** is a structural gap by design (no skill, none planned), while the **Tier-1 evidence-assembly** sub-step is covered by `pmo-release-manager` Mode 1.

- **Decision gate (structural gap, retained):** Final go/no-go DECISION before deployment authorization. **Why no skill fits (intentional):** Tier 3 Human-only per [`pipeline/`](../pipeline) and [`release-personas.md`](release-personas.md) — the decision is inherently human; no agent recommends the verdict. Decision-briefing scaffold provided by `ppm-agent` Section 5 + gate-decision documentation pattern. **Forward-reference:** None. Structural gap, not a skill-build candidate.
- **Evidence-assembly sub-step (covered):** Auto-compile the Stage-9 evidence package from the plan evidence + Stage-7 quality report + Stage-8 acceptance report. **Covered by `pmo-release-manager` Mode 1 (Go/No-Go Evidence)** — Tier-1 auto, structured per [`stage-09-plan-review.md`](../pipeline/stage-09-plan-review.md) §5 Phase A. This is an **out-of-table cross-reference**: `pmo-release-manager` is not one of the 6 per-row-assigned in-scope skills (frontmatter `applies_to`) — it is named here because it owns the Tier-1 assembly that feeds the gate, not because it is added to the mapping's per-row assignment scope. The mode assembles the evidence; it does not render the go/no-go.

## Forward-Reference Legend

Markers annotated on affected rows above signal expected enrichment at known future milestones.

| Enrichment marker | Affected stages | Enrichment expected |
|---|---|---|
| **concurrency** | Stages 12, 13 | Concurrency-control logic for parallel-PR scenarios; cross-release dependency-check at Stage 13 |
| **intake skills** | Stages 1, 2 | New intake + triage skills filling G1 + G2 gaps |
| **release-planner Bundle** | Stage 3 | `release-planner` Mode A enrichment for Bundle gate (Gate 3 criteria automation) |
| **role skills** | Stage 6 | Stage 5 leg **resolved** — `pmo-principal-engineer` shipped and replaced the `pmo-technical-analyst` Mode C bridging. Remaining: an engineering skill to fill G4 |

## Maintenance Discipline

This file is the single source of truth for stage-to-skill-mode mapping going forward. Per-row updates that follow Forward-Reference Legend events qualify for the lightweight update path under "No ungoverned changes" — namely:

1. Open a GitHub Issue with the `improvement` label citing the milestone trigger (e.g., "intake skill landed; update Stage 1 + Stage 2 rows from gap to coverage").
2. Author an implementation plan (single PR, change-spec covering only the affected rows + matching Forward-Reference Legend entries).
3. Execute via the standard release pipeline (most updates qualify for the compressed git-native flow per [`release-process.md`](../../governance/release-process.md) § Stage Compression).

Cross-reference contract:

- [`pipeline/`](../pipeline) — canonical stage definitions and per-stage automation-tier classifications.
- [`release-personas.md`](release-personas.md) — per-stage personas and replacement-skill identifiers (the source of role-skill / QA-mode / engineering-workflow references).
- [`release-process.md`](../../governance/release-process.md) — release lifecycle, stage compression, gate transitions.
- [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) — per-stage gate criteria; the Workflow Readiness, Release Readiness, and Plan Review gates referenced in Gap Notes.

Drift triggers: when [`pipeline/`](../pipeline) renames a stage, splits a stage, or compresses a previously-distinct stage; when a SKILL.md adds, removes, or renames a Mode cited in this document; when a row's forward-reference milestone closes (and the gap should now be coverage); or when the operator flags a skill scope change that invalidates a per-stage assignment. Any drift constitutes a governance-file modification and follows the "No ungoverned changes" protocol.
