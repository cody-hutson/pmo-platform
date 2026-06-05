---
title: Stage-to-Skill-Mode Mapping
purpose: Maps each of the 13 pipeline stages to its primary owning skill, mode, automation tier, and gap notes; functions as the build spec for future skill-mode work.
applies_to: 13-stage pipeline (`pipeline/`); 6 in-scope skills per the Agent Runbook (`pmo-qa-auditor`, `pmo-skill-editor`, `pmo-technical-analyst`, `release-executor`, `release-planner`, `ppm-agent`).
related: pipeline/, release-personas.md, release-process.md, gate-criteria-spec.md
last_updated: 2026-05-04
---
<!-- reference-durability: allow-link -->

# Stage-to-Skill-Mode Mapping

This document maps each of the 13 pipeline stages defined in [`pipeline/`](../pipeline) to its primary owning skill, the mode within that skill that applies, the automation tier (per Stage 4 D-3 decision), and a gap note where existing skill capability does not cover the stage. Scope is narrowed to the 6 primary skills already listed in the Agent Runbook (`pmo-qa-auditor`, `pmo-skill-editor`, `pmo-technical-analyst`, `release-executor`, `release-planner`, `ppm-agent`) per #8 risk mitigation. Other skills (22+ total in `release/skills/`) are not per-row assigned here — most are project-ops scoped (sprint planning, comms drafting, project artifact generation) or platform-meta scoped (skill creation, eval authoring) and do not own a pipeline stage. The mapping becomes the build spec for future skill-mode slices that fill identified gaps.

**Tier vocabulary.** "Automation Tier" follows convention 3 in [`autonomy-tiers.md`](../../../core/specs/autonomy-tiers.md) § Tier Disambiguation Table — the [`pipeline/`](../pipeline) per-stage tier (Tier 1 Auto / Tier 2 Recommend / Tier 3 Human-only) classifying authorization posture per stage transition. Distinct from Skill Tier (`OPERATIONS.md`), Document Tier (CLAUDE.md File Management Protocol), and Autonomy Tier ([`autonomy-tiers.md`](../../../core/specs/autonomy-tiers.md) per-action classification).

## Stage Mapping Table

| Stage | Stage Name | Primary Skill | Skill Mode | Automation Tier | Gap Notes |
|---|---|---|---|---|---|
| 1 | Intake | — | — | Tier 2 (Recommend) | **GAP** — no scoped skill owns platform-internal improvement-issue authoring against `pmo-platform` repo. `ppm-agent` Section 10 Handoff Manifest produces follow-ups but does not author GitHub Issues. Forward-ref: **intake skills**. |
| 2 | Triage | — | — | Tier 2 (Recommend) | **GAP** — no scoped skill owns Workflow Readiness gate execution (G2-01..G2-04 per [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md)). `delivery-engine` triage modes are sprint-backlog scoped (project-ops), not improvement-backlog. Forward-ref: **intake skills**. |
| 3 | Bundle | `release-planner` | Mode A — Backlog Analysis | Tier 2 (Recommend) | Coverage. Mode A produces dependency graph + suggested bundles + version recommendations. Stage 3 Release Readiness gate (G3-01..G3-06) executes upstream of Mode A output. Forward-ref: **release-planner Bundle mode** enrichment. |
| 4 | Planning | `release-planner` | Mode B — Release Planning | Tier 2 (Recommend) | Coverage. Mode B writes `release/releases/plans/[version]_RELEASE_PLAN.md` with implementation sequence, dependency ordering, risk register. |
| 5 | Solutioning | `pmo-technical-analyst` | Mode C — Architecture / Infrastructure Review (closest-domain bridging fit) | Tier 2 (Recommend) | **PARTIAL FIT** — `pmo-technical-analyst` is project-ops scoped (vendor FDDs, IDDs, ERP architectures); Stage 5 targets platform-internal design (skill structure, governance edits, schema changes). Per [`release-personas.md`](release-personas.md) Stage 5, planned replacement is the **Principal Engineer skill**. Use Mode C as bridging fit only until the Principal Engineer skill ships. Forward-ref: **role skills**. |
| 6 | Engineering | — | — | Tier 1 (Auto) with Tier 3 checkpoint | **GAP** — no scoped skill. Existing reference workflow [`implementation-execution-pattern.md`](../how-to/implementation-execution-pattern.md) (supersedes deprecated implementer skill per implementation-execution-pattern.md) is the procedure. `release-executor` handles approved-plan execution (Stage 12) not engineering implementation; `pmo-skill-editor` Mode A handles skill-only edits (subset). Forward-ref: **role skills** (engineering-skill candidate). |
| 7 | Dev Testing | `pmo-qa-auditor` (skill / governance outputs) + `pmo-skill-editor` (skill modifications) | `pmo-qa-auditor` Mode A — Single Output Review + Mode D — Document Management Compliance; `pmo-skill-editor` Mode C — Regression | Tier 1 / Tier 2 (mixed: structural auto, judgment recommend) | Coverage with multi-skill split by artifact type. `pmo-qa-auditor` Mode A for skill outputs; Mode D for governance documents; `pmo-skill-editor` Mode C runs friction-log regression checks for skill-modification PRs. Forward-ref: per [`release-personas.md`](release-personas.md) Stage 7, planned dedicated mode is **QA Auditor dev mode**. |
| 8 | QA Testing | `pmo-qa-auditor` | Mode A — Single Output Review + Mode B — Cross-Skill Coherence Review | Tier 2 (Recommend) | Coverage. Mode A for per-acceptance-criterion gate evaluation (G1-G7); Mode B for cross-issue / cross-skill coherence in multi-issue releases. Stage 8 acceptance verdict is operator-rendered. Forward-ref: per [`release-personas.md`](release-personas.md) Stage 8, planned dedicated mode is **QA Auditor acceptance mode**. |
| 9 | Plan Review | — | — | Tier 3 (Human-only) | **GAP BY DESIGN** — gate stage; operator renders go/no-go decision. `ppm-agent` Section 5 (Decisions needed) + gate-decision documentation pattern provide the briefing scaffold. No skill replacement planned per [`release-personas.md`](release-personas.md) Stage 9 ("hub presents decision to operator, no spoke launched"). |
| 10 | Dry Run | `release-planner` | Mode C — Dry Run (when activated) | Tier 1 (Auto) — compressed for git-native | Compressed per [`release-process.md`](../../governance/release-process.md) § Stage Compression. PR diff IS the dry-run for git-native releases. Mode C activates explicitly only when compression exceptions apply (non-git deploy targets, destructive operations, Layer 2 file deployment with new mechanism). |
| 11 | Snapshot | `release-executor` | Mode A — Execute Release (snapshot phase, when activated) | Tier 1 (Auto) — compressed for git-native | Compressed per [`release-process.md`](../../governance/release-process.md) § Stage Compression. Git history IS the snapshot mechanism for git-native releases. Snapshot phase of `release-executor` Mode A activates only for non-git deploy targets per [`RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md). |
| 12 | Execute | `release-executor` | Mode A — Execute Release | Tier 1 (Auto) with Tier 3 gate | Coverage. Operator authorizes Stage 9 GO; Mode A executes merge/tag/deploy sequence + RELEASE_LOG.md update + GitHub Projects field updates per [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md). Forward-ref: **concurrency** — Stage 12 may gain concurrency-control logic for parallel-PR scenarios. |
| 13 | Close | `release-executor` | Mode B — Verify Release | Tier 1 (Auto) | Coverage. Mode B verifies deployment artifacts + closes Milestone + appends RELEASE_LOG.md verification evidence per [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md). Forward-ref: **concurrency** — Stage 13 verification may gain cross-release dependency-check logic. |

## Gaps

Five gaps surfaced by the table: three skill-build candidates (G1, G2, G4), one partial-fit bridging assignment with replacement scheduled at a future role-skills release (G3), and one structural gap by design (G5).

### G1: Stage 1 (Intake) — no improvement-issue authoring skill

- **Stage role:** Capture improvement proposals as GitHub Issues with structured fields per `improvement.yml` / `observation.yml` templates.
- **Why no current skill fits:** `ppm-agent` processes project artifacts → project-tracker outputs (not GitHub Issues against `pmo-platform`). `pmo-skill-editor` edits skills. `pmo-technical-analyst` reviews vendor artifacts.
- **Forward-reference:** intake skill expansion. Likely successor: `platform-improvement-intake` skill consuming operator observations + session-end candidate improvements + authoring `improvement.yml`-conformant issues.

### G2: Stage 2 (Triage) — no improvement-backlog triage skill

- **Stage role:** Evaluate each issue for priority, feasibility, fit; produce Approved/Deferred/Rejected decision; run dependency-state validation (G2-04).
- **Why no current skill fits:** `delivery-engine` triage modes are sprint-backlog (project-ops). `ppm-agent` produces decision frames but doesn't run Workflow Readiness gate. `release-planner` Mode A consumes Approved issues but doesn't produce triage decisions.
- **Forward-reference:** intake skill expansion.

### G3: Stage 5 (Solutioning) — partial-fit only via pmo-technical-analyst

- **Stage role:** Resolve technical design decisions, validate feasibility, produce implementation-ready specifications. Per [`release-personas.md`](release-personas.md) Stage 5: Principal Engineer — Architecture Assessment.
- **Why `pmo-technical-analyst` is partial fit:** `pmo-technical-analyst` Modes A-E target vendor/project artifacts. Mode C closest. Stage 5 targets platform-internal design — different domain. Persona card explicitly identifies the Principal Engineer skill as planned replacement.
- **Forward-reference:** role skills — Principal Engineer skill.

### G4: Stage 6 (Engineering) — reference workflow only, no skill

- **Stage role:** Execute release plan; decompose issues into sub-tasks; implement file changes; produce PR.
- **Why no skill fits:** Deprecated `implementer` skill superseded by [`implementation-execution-pattern.md`](../how-to/implementation-execution-pattern.md) — procedure document, not skill. `release-executor` executes approved plans (Stage 12), not engineering implementation. `pmo-skill-editor` Mode A handles skill-only edits (subset).
- **Forward-reference:** role skills (engineering-skill candidate).

### G5: Stage 9 (Plan Review) — gap by design

- **Stage role:** Final go/no-go decision before deployment authorization.
- **Why no skill fits (intentional):** Tier 3 Human-only per [`pipeline/`](../pipeline) and [`release-personas.md`](release-personas.md). Decision-briefing scaffold provided by `ppm-agent` Section 5 + gate-decision documentation pattern.
- **Forward-reference:** None. Structural gap, not a skill-build candidate.

## Forward-Reference Legend

Markers annotated on affected rows above signal expected enrichment at known future milestones.

| Enrichment marker | Affected stages | Enrichment expected |
|---|---|---|
| **concurrency** | Stages 12, 13 | Concurrency-control logic for parallel-PR scenarios; cross-release dependency-check at Stage 13 |
| **intake skills** | Stages 1, 2 | New intake + triage skills filling G1 + G2 gaps |
| **release-planner Bundle** | Stage 3 | `release-planner` Mode A enrichment for Bundle gate (G3-01..G3-06 automation) |
| **role skills** | Stages 5, 6 | Principal Engineer skill replaces `pmo-technical-analyst` Mode C bridging at Stage 5; engineering skill fills G4 |

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
