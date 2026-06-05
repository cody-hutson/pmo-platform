<!-- reference-durability: allow-link -->
# Operating Model — Skill Ownership, Governance Composition, Per-Stage Execution Blueprint

**Status:** Canonical
**Owner:** `../disciplines/operating-model.md`
**Introduced:** 2026-05-10
**Consumers:** v12.* skill-build wave; v13.* role-skill wave (composes against this file's per-stage execution blueprint); Stage 6 Engineering and Stage 7 Dev Testing read the per-stage blocks as their execution-context spec; pmo-qa-auditor Mode B (cross-skill coherence) consumes the Skill Ownership manifest.

---

This document is the **composition view** of the PMO platform. It composes three layers — Skill Ownership (which skill executes), Governance Composition (which docs constrain), Per-Stage Execution Blueprint (how the layers compose at each of the 13 stages) — into a single reference for downstream consumers. It is intentionally cite-not-duplicate: where existing files already define the authoritative table (e.g., [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md), [`schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md), [`schemas/stage-io-contracts.md`](../schemas/stage-io-contracts.md)), the per-stage blocks cite those sources by anchor rather than restate them. Honors [`architecture-overview.md` Key Principles § 1 "One source, one truth"](../disciplines/architecture-overview.md). Three foundational design choices — cardinality model, cite-not-duplicate citation discipline, cross-reference pattern with the function-spine companion document — are recorded in [`../ADRs/ADR-003-operating-model-composition.md`](../ADRs/ADR-003-operating-model-composition.md). Future authors revisiting any of these choices should consult ADR-003 before re-designing.

---

## Skill Ownership

### 1.1 Cardinality model

The platform's skill-to-stage binding is **many-to-many with declared primary**. A skill may own (be the primary executor of) multiple stages or modes; a stage may have one primary skill plus secondary skills (cross-cutting flags, friction logs, regression checks). Stages with no current owner are documented as **GAP** with forward-reference to the v12.* / v13.* skill-build milestone that will fill them. Four cardinality types apply:

- **1:1** — single skill, single stage (e.g., `release-planner` Mode A → Stage 3 Bundle).
- **1:many** — single skill, multiple stages (e.g., `release-executor` Modes A/B → Stages 12, 13; with optional Stage 11 activation for non-git-native releases).
- **many:1** — multiple skills, single stage (e.g., Stage 7 Dev Testing = `pmo-qa-auditor` Mode A + Mode D + `pmo-skill-editor` Mode C — split by artifact type).
- **0:1 (GAP)** — no current skill, forward-ref documented (e.g., Stage 1 Intake → future intake skills).

The cardinality model is **load-bearing for v12.* / v13.* consumers**. Strict 1:1 (each stage → exactly one skill) would force artificial bundling of stages or splitting of skills; many-to-many without a declared primary loses the "who owns this stage's gate decision" affordance the release pipeline depends on. Declared-primary-with-secondaries is the operative choice — see [`../ADRs/ADR-003-operating-model-composition.md`](../ADRs/ADR-003-operating-model-composition.md) § Decision 1 for rationale and rejected alternatives.

### 1.2 Reference to canonical binding table

The single source of truth for stage → skill → mode binding is [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md). This document composes that binding with governance inputs, write boundaries, and execution context — it does **not redefine** the binding. When [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) updates a row (e.g., an intake skill lands and Stage 1 transitions from GAP to coverage), the per-stage blocks in § 3 inherit the new binding by reference. Drift in either direction is governed by [`stage-to-skill-mode-mapping.md` § Maintenance Discipline](../../release/references/specs/stage-to-skill-mode-mapping.md).

[`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) scopes its per-row coverage to the 6 primary platform-pipeline skills (`pmo-qa-auditor`, `pmo-skill-editor`, `pmo-technical-analyst`, `release-executor`, `release-planner`, `ppm-agent`). The remaining 16 skills in [`release/skills/`](../../release/skills/) are not per-stage assigned because they are either **project-ops scoped** (sprint planning, comms drafting, project-artifact generation — they run in the PMO operations area, not in the platform pipeline) or **platform-meta scoped** (skill creation, eval authoring, prompt building — they support pipeline work but do not own a stage). The per-skill ownership manifest in § 1.3 covers all 22 skills with this scoping made explicit.

### 1.3 Per-skill ownership manifest

One 4-field entry per skill (22 entries, alphabetical). Each entry states the skill name + version, primary stages owned, secondary stages (review-only / friction-log / compliance-check), and one out-of-scope declaration sourced from the skill's own `## Operating Principles` section in its SKILL.md. The out-of-scope statements are evidence-grounded — they appear in the skill's authoring discipline today, not invented for this manifest.

**`artifact-generator`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Writes only to `08-Generated/` staging area; never modifies governance files, never modifies SKILL.md files, never authors GitHub Issues against the `pmo-platform` repo.

**`build-reviewer`** *(platform-meta scoped)*

- **Stages owned (primary):** none — platform-meta scoped (release-readiness review for governed document packs; not pipeline-stage-bound)
- **Stages co-owned (secondary):** none — invoked by operator on demand, not as part of a release lifecycle stage
- **Out-of-scope:** Read-only review; does not write findings to source files; does not author governance changes.

**`change-management`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Project-ops domain only (training plans, readiness checklists, hypercare plans for project go-lives); never modifies platform governance.

**`comms-writer`** *(project-ops scoped; cascade-allowlisted)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Writes communications to the active project's folder (06-Emails/, 08-Generated/); never modifies governance files, skills, or shared trackers.

**`daily-status`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Generates daily-status updates from carry-forward trackers + recent transcripts; reads only project artifacts; never modifies governance files.

**`delivery-engine`** *(project-ops scoped; cascade-allowlisted)*

- **Stages owned (primary):** none — project-ops scoped (sprint-backlog modes are project-ops; not pipeline-improvement-backlog)
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Backlog scan, DoR/DoD gates, sprint planning operate against project sprint backlogs (not the pmo-platform improvement backlog); never authors GitHub Issues against `pmo-platform` repo.

**`eval-writer`** *(platform-meta scoped)*

- **Stages owned (primary):** none — platform-meta scoped
- **Stages co-owned (secondary):** none — supports skill-build work in v12.* / v13.* by authoring eval suites; not pipeline-stage-bound
- **Out-of-scope:** Authors eval suites only; never modifies skills, governance, or release plans.

**`file-router`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Classifies and routes incoming project files (Layer 2 / projects/); never modifies platform governance or skills.

**`implementation-planner`** *(platform-meta scoped)*

- **Stages owned (primary):** none — platform-meta scoped
- **Stages co-owned (secondary):** none — produces remediation implementation plans for any governed document pack; consumed by `implementer` for execution; not pipeline-stage-bound
- **Out-of-scope:** Plans only; never executes changes; never modifies source files directly.

**`pmo-process-designer`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Authors project requirements and process documentation; never modifies platform governance.

**`pmo-qa-auditor`** *(platform-pipeline scoped; primary at Stages 7-8)*

- **Stages owned (primary):** Stage 7 Dev Testing (Mode A — Single Output Review + Mode D — Document Management Compliance); Stage 8 QA Testing (Mode A + Mode B — Cross-Skill Coherence Review). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stages 7-8.
- **Stages co-owned (secondary):** none formally assigned; Mode B may be invoked at Collective Review post-Stage-5 as informal coherence input
- **Out-of-scope:** Review-only; never modifies the source files under review; never renders gate decisions (operator-only at Stages 8-9); never modifies governance docs (must route through pmo-skill-editor for SKILL.md edits).

**`pmo-skill-editor`** *(platform-pipeline scoped; secondary at Stage 7)*

- **Stages owned (primary):** none formally; Mode C — Regression runs friction-log regression checks for skill-modification PRs at Stage 7
- **Stages co-owned (secondary):** Stage 7 Dev Testing (Mode C secondary review for skill-modification PRs per [`stage-to-skill-mode-mapping.md` row 7](../../release/references/specs/stage-to-skill-mode-mapping.md))
- **Out-of-scope:** Mode A edits a single SKILL.md per invocation (or its `references/*.md` files); never edits non-skill governance; never edits skills outside the migrated allowlist when [`block-skill-direct-edit.sh`](../hooks/block-skill-direct-edit.sh) BLOCK-SKILL-EDIT-001..002 is enforcing.

**`pmo-skill-refiner`** *(platform-meta scoped)*

- **Stages owned (primary):** none — platform-meta scoped
- **Stages co-owned (secondary):** none — used during skill authoring to wrap `anthropic-skills:skill-creator` with PMO refinement layer; not pipeline-stage-bound
- **Out-of-scope:** Mode 2 (Create New) authors NEW skills only; never edits existing skills (those route through pmo-skill-editor per [`canonical-skill-structure.md § 2`](../standards/canonical-skill-structure.md)).

**`pmo-skill-refiner-selftest-canary`** *(platform-meta scoped; canary)*

- **Stages owned (primary):** none — canary skill per ADR-04 of [`canonical-skill-structure.md`](../standards/canonical-skill-structure.md); source-only, never deployed
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Canary surface for self-test drills; never invoked in production; never modifies any file.

**`pmo-technical-analyst`** *(platform-pipeline scoped; primary at Stage 5 as bridging fit)*

- **Stages owned (primary):** Stage 5 Solutioning (Mode C — Architecture / Infrastructure Review, **PARTIAL FIT** bridging until the Principal Engineer skill ships). Per [`stage-to-skill-mode-mapping.md` G3](../../release/references/specs/stage-to-skill-mode-mapping.md).
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Modes A/B/D/E target project-ops domain (vendor FDDs, IDDs, ERP architectures); Mode C bridges to platform-internal Stage 5 work but is explicitly a partial fit per per-row gap note. Never authors source-file changes; review-only at Stage 5.

**`ppm-agent`** *(platform-pipeline scoped; decision-briefing scaffold at Stages 1, 9)*

- **Stages owned (primary):** none formally; Section 10 Handoff Manifest produces follow-ups at Stage 1; Section 5 (Decisions needed) provides operator briefing at Stage 9 per [`stage-to-skill-mode-mapping.md` G5](../../release/references/specs/stage-to-skill-mode-mapping.md)
- **Stages co-owned (secondary):** Stage 1 (Section 10 candidates feed Intake), Stage 9 (Section 5 briefing scaffold)
- **Out-of-scope:** Reads project artifacts; produces analysis frames; never authors GitHub Issues against `pmo-platform` repo (the Stage 1 G1 gap covers improvement-issue authoring — that's a forward-ref).

**`project-initiator`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Scaffolds new project folders and closes completed projects (PMO operations area); never modifies platform governance.

**`prompt-builder`** *(platform-meta scoped)*

- **Stages owned (primary):** none — platform-meta scoped
- **Stages co-owned (secondary):** none — supports skill-authoring work; not pipeline-stage-bound
- **Out-of-scope:** Drafts prompts; never modifies skills directly; pmo-skill-editor owns SKILL.md edits.

**`release-executor`** *(platform-pipeline scoped; primary at Stages 12-13, optional at Stage 11)*

- **Stages owned (primary):** Stage 12 Execute (Mode A — Execute Release); Stage 13 Close (Mode B — Verify Release); Stage 11 Snapshot (Mode A snapshot phase) **only when activated** (compression exception for non-git deploy targets). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stages 11-13.
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Plan-driven; never executes changes without an approved release plan file that includes a Dry-Run Record section. Never modifies source-of-truth governance content (writes `RELEASE_LOG.md` append only + GitHub state via `gh project item-edit` + `gh issue close`). Never authors SKILL.md edits (those route through pmo-skill-editor).

**`release-planner`** *(platform-pipeline scoped; primary at Stages 3-4, optional at Stage 10)*

- **Stages owned (primary):** Stage 3 Bundle (Mode A — Backlog Analysis); Stage 4 Planning (Mode B — Release Planning); Stage 10 Dry Run (Mode C — Dry Run) **only when activated** (compression exception). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stages 3, 4, 10.
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Read-only across governance and source; the only file the skill writes is the release plan file at `release/releases/plans/[version]_RELEASE_PLAN.md`. Never modifies governance files, skills, SKILL.md files, or project artifacts.

**`tracker-manager`** *(project-ops scoped; cascade-allowlisted)*

- **Stages owned (primary):** none — project-ops scoped (updates operational trackers in `04-PMO-Operations/`)
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Schema-validated tracker updates in the project domain; never modifies platform governance.

**`weekly-status-rollup`** *(project-ops scoped)*

- **Stages owned (primary):** none — project-ops scoped
- **Stages co-owned (secondary):** none
- **Out-of-scope:** Generates weekly executive roll-ups from project artifacts; never modifies governance.

**Manifest summary.** 22 skills total. Platform-pipeline scoped with stage ownership: 5 (`pmo-qa-auditor`, `pmo-skill-editor`, `pmo-technical-analyst`, `release-executor`, `release-planner`). Platform-pipeline scoped with decision-briefing role: 1 (`ppm-agent`). Platform-meta scoped: 5 (`build-reviewer`, `eval-writer`, `implementation-planner`, `prompt-builder`, `pmo-skill-refiner`). Canary: 1 (`pmo-skill-refiner-selftest-canary`). Project-ops scoped: 10 (`artifact-generator`, `change-management`, `comms-writer`, `daily-status`, `delivery-engine`, `file-router`, `pmo-process-designer`, `project-initiator`, `tracker-manager`, `weekly-status-rollup`). Cross-check: per-skill SKILL.md "Operating Principles" sections are the authoritative source for each out-of-scope declaration above.

---

## Governance Composition

### 2.1 Governance file inventory

The platform's governance corpus is partitioned by who manages each file and which agent loads it at invocation. Read-access universality varies — some files are universal-read (loaded by every skill), some are specific-read (loaded only by skills whose discipline is governed by the file).

| Category | Files | Owner | Universal read? |
|---|---|---|---|
| Workspace-global | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) | Claude Code (git-tracked) | YES — every skill MUST read |
| Claude Code rules | [`core/rules/*`](../rules/) (7 files: bypass-mode-readiness, git-workflow, governance-files, harness-deployment, operations-bridge, release-process, skill-deployment) | Claude Code (git-tracked) | Platform-engineering area only — operations-scoped skills do not load |
| Program-scoped governance | [`../governance/OPERATIONS.md`](../governance/OPERATIONS.md), [`RELEASE_PROTOCOL.md`](../../release/governance/RELEASE_PROTOCOL.md), [`RELEASE_LOG.md`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>), [`ADRs/`](../ADRs/) (2 core entries: ADR-003 + ADR-004) and [`release/ADRs/`](../../release/ADRs/) (3 release entries: ADR-001 + ADR-002 + ADR-005), [`roadmaps/`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/) (3 entries) | Claude Code (git-tracked) | Operations-scoped skills read OPERATIONS.md; platform-engineering reads all program-scoped files |
| Standards | [`core/standards/*`](../standards/) (6 files: AUDIT_FRAMEWORK, canonical-skill-structure, principal-standard-checklist, regression-checks, triage-design-rereview, version-field-semantics) | Claude Code (git-tracked) | Read by skills whose discipline is governed by the standard |
| Schemas | [`core/schemas/*`](../schemas/) (13 files: agent-processing-contracts, field-lifecycle-matrix, frontmatter-schema, gate-criteria-spec, gate-evaluation-spec, handoff-coordinator-spec, navigation-layer-schema, per-skill-output-contracts, project-schema, routing-rules, sqlite-index-schema, stage-io-contracts, tracker-schemas) | Claude Code (git-tracked) | Read by skills whose I/O conforms to the schema |
| Reference frameworks | [`architecture-overview.md`](../disciplines/architecture-overview.md), [`decision-discipline.md`](../disciplines/decision-discipline.md), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md), [`execution-framework.md`](../disciplines/execution-framework.md), [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md), [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md), `pipeline-stages.md` (post-cascade: [`pipeline/`](../../release/references/pipeline/)), [`terminology-glossary.md`](../specs/terminology-glossary.md), [`autonomy-tiers.md`](../specs/autonomy-tiers.md), [`autonomous-execution-model.md`](../disciplines/autonomous-execution-model.md), [`release-personas.md`](../../release/references/specs/release-personas.md), [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md), [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md), [`github-projects-guide.md`](github-projects-guide.md), the function-spine companion document (cross-referenced once from § 3.2 below) | Claude Code (git-tracked) | Per-skill, per-stage; decision-discipline.md universal for decision-class skills; review-discipline-principles.md universal for review-class skills |
| Operational config | [`projects/_config/PORTFOLIO.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>), [`SESSION_STATE.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>), [`CORRECTIONS.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>), [`SWAP_HANDOFF.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>) | Operations state (git-ignored) | Read-only for platform-engineering via [`CLAUDE.md § Cross-Domain Read Access`](<OPERATOR_INSTANCE_CLAUDE_MD>); read+write for operations sessions |

This inventory is **descriptive of current state** — additions to governance follow [`CLAUDE.md` § Pre-creation governance check](<OPERATOR_INSTANCE_CLAUDE_MD>) and the placement map in CLAUDE.md § Governance File Map. Per-stage governance composition (§ 2.2) draws its READ and WRITE columns from this inventory.

### 2.2 Per-stage governance composition matrix

The 13 stages each carry a different governance load — Stage 1 Intake reads intake templates and decision-discipline.md; Stage 12 Execute reads RELEASE_PROTOCOL.md and writes RELEASE_LOG.md. The matrix below is the per-stage breakdown of which governance files are loaded (READ) and which are produced or appended (WRITE). It is the source of truth for the "Governance Inputs" and "Governance Writes" rows in each per-stage block in § 3.2.

| Stage | Universal-read (always) | Stage-specific governance reads | Stage-specific governance writes |
|---|---|---|---|
| 1 Intake | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md`](../disciplines/decision-discipline.md) (decision-class) | [`intake-style-guide.md`](../../release/references/how-to/intake-style-guide.md) if present, [`improvement.yml`](../../.github/ISSUE_TEMPLATE/improvement.yml) template, [`observation.yml`](../../.github/ISSUE_TEMPLATE/observation.yml) template, [`schemas/gate-criteria-spec.md` Gate 1](../schemas/gate-criteria-spec.md) | NEW GitHub Issue with structured fields |
| 2 Triage | (same) | [`schemas/gate-criteria-spec.md` Gate 2](../schemas/gate-criteria-spec.md) (G2-01..G2-04 inclusive of G2-04 dependency validation), [`schemas/field-lifecycle-matrix.md`](../schemas/field-lifecycle-matrix.md) Gate 1→2 inheritance | Issue Status field (Triage → Approved/Deferred/Rejected), dependency labels, priority + category fields |
| 3 Bundle | (same) | [`schemas/gate-criteria-spec.md` Gate 3](../schemas/gate-criteria-spec.md) (G3-01..G3-06), [`roadmaps/`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/), [`pipeline/stage-03-bundle.md`](../../release/references/pipeline/stage-03-bundle.md) (post-cascade) | Milestone (created), Issue Milestone field, `status: bundled` label, bundle rationale comment |
| 4 Planning | (same), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) | [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md) (post-cascade), [`standards/triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md), [`decision-discipline.md` § 3](../disciplines/decision-discipline.md), [`schemas/stage-io-contracts.md` Boundary Stage 3 → Stage 4](../schemas/stage-io-contracts.md) | `release/releases/plans/[version]_RELEASE_PLAN.md` (on release branch), Stage 4 sub-task comment, file-overlap-audit folder (when A4 cross-PR contention applies) |
| 5 Solutioning | (same) | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) (post-cascade), [`architecture-overview.md`](../disciplines/architecture-overview.md), [`decision-discipline.md` § 3](../disciplines/decision-discipline.md), [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) Procedure 0 D-Gate Template, [`schemas/stage-io-contracts.md` Boundary Stage 5 → Stage 6](../schemas/stage-io-contracts.md) | NEW ADR issue (`adr` label) and/or ADR file in [`core/ADRs/`](../ADRs/) (cross-cutting) or [`release/ADRs/`](../../release/ADRs/) (release-scope), Stage 5 sub-task comment, refined change-specs in release plan |
| 6 Engineering | (same) | [`pipeline/stage-06-engineering.md`](../../release/references/pipeline/stage-06-engineering.md) (post-cascade), [`../rules/git-workflow.md`](../rules/git-workflow.md), [`implementation-execution-pattern.md`](../../release/references/how-to/implementation-execution-pattern.md), file-specific governance per change-spec, [`schemas/stage-io-contracts.md` Boundary Stage 5 → Stage 6](../schemas/stage-io-contracts.md) | Source files per change-spec, PR body + metadata, sub-task comments, RELEASE_PLAN deviation log, deployed-copy sync via `core/deploy/deploy.sh --deploy` (Layer 2 propagation) |
| 7 Dev Testing | (same), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) | [`pipeline/stage-07-dev-testing.md`](../../release/references/pipeline/stage-07-dev-testing.md) (post-cascade), [`schemas/gate-criteria-spec.md` Gate 7](../schemas/gate-criteria-spec.md) (planned per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md)), [`standards/principal-standard-checklist.md`](../standards/principal-standard-checklist.md), [`standards/regression-checks.md`](../standards/regression-checks.md) | DT report comment on PR (or sub-task), structured Handoff Payload per [`pipeline/stage-07-dev-testing.md` DT↔QA Handoff Protocol](../../release/references/pipeline/stage-07-dev-testing.md#dtqa-handoff-protocol-source-200-204) |
| 8 QA Testing | (same), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) | [`pipeline/stage-08-qa-testing.md`](../../release/references/pipeline/stage-08-qa-testing.md) (post-cascade), [`schemas/gate-criteria-spec.md` Gate 8](../schemas/gate-criteria-spec.md) (planned), AC eval set per release plan, DT Handoff Payload from Stage 7 | QA verdict comment, acceptance evidence on Issue, QA Return to Dev Testing payload per [`pipeline/stage-07-dev-testing.md` §Return Path](../../release/references/pipeline/stage-07-dev-testing.md#dtqa-handoff-protocol-source-200-204) (Lane 2 findings) |
| 9 Plan Review | (same) | [`pipeline/stage-09-plan-review.md`](../../release/references/pipeline/stage-09-plan-review.md) (post-cascade), all Stage 4-8 outputs (release plan, DT report, QA verdict), `ppm-agent` Section 5 decision briefing scaffold | Operator decision record (sub-task comment), gate sub-task close (decision-documentation discipline) |
| 10 Dry Run (compressed) | (same) | [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md) — git-native compression rationale | (compressed — PR diff IS the dry run; no separate write) |
| 11 Snapshot (compressed) | (same) | [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md) — git history IS the snapshot | (compressed — git history is the snapshot; no separate write) |
| 12 Execute | (same) | [`pipeline/stage-12-execute.md`](../../release/references/pipeline/stage-12-execute.md) (post-cascade), [`../governance/RELEASE_PROTOCOL.md`](../../release/governance/RELEASE_PROTOCOL.md), [`release/governance/release-process.md § Stage 12`](../../release/governance/release-process.md), Stage 9 operator GO record | RELEASE_LOG.md append, `gh pr merge`, signed-annotated version tag (`git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<n>" vX.Y "$MERGE_SHA" && git push origin vX.Y`), `gh project item-edit` for all release issues (Status → Done, Stage → 12-Execute), `core/deploy/deploy.sh --deploy` for changed skills and harness artifacts |
| 13 Close | (same) | [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) (post-cascade), [`schemas/gate-criteria-spec.md` Gate 13](../schemas/gate-criteria-spec.md) (planned), Stage 12 deployment evidence, [`standards/release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) | RELEASE_LOG.md verification append, Milestone close on GitHub, Issue auto-close verification (PRs with `closes #N` close issues automatically), user-facing `release/releases/notes/[version]_RELEASE_NOTES.md` |

**Notes on compressed stages.** Stages 10 and 11 are compressed for git-native releases per [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md). They retain rows in the matrix (and detailed blocks in § 3.2) to preserve cite-resolvability — if a release ships with compression exceptions (non-git deploy targets, destructive operations, Layer 2 file deployment with new mechanism), Stages 10 and 11 activate as distinct steps and their READ/WRITE composition applies.

**Notes on universal-read.** Every stage loads CLAUDE.md (workspace-global) and decision-discipline.md (when the stage produces decision-class output — Stages 1, 2, 3, 4, 5, 9, 12, 13 are decision-class). Stages 4, 7, 8 additionally load review-discipline-principles.md because they produce review-class output (Stage 4 reviews intake quality; Stages 7-8 review implementation quality).

### 2.3 Compartmentalization rules — READ boundaries

Read boundaries protect skills from loading context they should not act on, and protect operator-owned config from skill modification. The boundaries below are derived from the inventory in § 2.1 and the per-skill operating principles in § 1.3.

**Universal read requirements.** All skills MUST read [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>). Decision-class skills MUST read [`decision-discipline.md`](../disciplines/decision-discipline.md). Review-class skills MUST read [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md).

**Operations-scoped skills (project-ops) MUST NOT read [`core/rules/*`](../rules/).** Platform-engineering governance (git workflow, bypass-mode readiness, harness deployment, skill deployment) does not apply during PMO operations work. Project-ops skills load CLAUDE.md, OPERATIONS.md, and project-specific PROJECT.md; they do not load `core/rules/`.

**Platform-pipeline skills MUST NOT read `projects/_config/*`** except as documented cross-domain reads. The four cross-domain reads explicitly authorized in CLAUDE.md are [`PORTFOLIO.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>), [`SESSION_STATE.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>), [`CORRECTIONS.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>), and [`SWAP_HANDOFF.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>). All other content under `projects/` is the operations area and read-locked to operations-scoped skills.

**All skills MUST NOT read credential files** (`.env` variants, `~/.ssh/*`, `~/.aws/*`, `~/.config/gh/*`, SSH private keys, `*.pem`, `*.key`). Read-blocking is structurally enforced by [`core/hooks/block-credential-reads.sh`](../hooks/block-credential-reads.sh) BLOCK-CREDENTIAL-READ-001..006 per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md). The hook fails closed; skills cannot bypass without the operator's explicit `CLAUDE_HOOK_BYPASS=1` launch flag, which is anti-injection guarded per the same governance file.

**Hub vs spoke READ asymmetry.** Hub agents read the operator's correction state and session context. Spokes read only the chip-specific context provided in their spawn prompt. Spokes do NOT read [`CORRECTIONS.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>) or [`SESSION_STATE.md`](<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>) — the hub mediates by transcoding relevant context into the spawn prompt. This is operator-confirmed (spoke-vs-hub chip-routing discipline).

### 2.4 Compartmentalization rules — WRITE boundaries

Write boundaries protect the integrity of the governance surface — if any skill could write any file, drift would compound until the governance corpus is unreliable. The boundaries below are derived from each skill's own SKILL.md `## Operating Principles` section (evidence-grounded, not invented).

**No skill writes outside its declared write-scope.** Per-skill write-scopes (sourced from SKILL.md Operating Principles per § 1.3):

- **`release-planner`** writes only `release/releases/plans/[version]_RELEASE_PLAN.md`. Never writes governance, skills, or projects/.
- **`release-executor`** writes RELEASE_LOG.md append + executes git operations (`gh pr merge`, `git tag`, `git push origin`) + executes `gh project item-edit` for release issues + executes `gh issue close` for auto-closure verification. Never modifies source-of-truth governance content (RELEASE_LOG append is operational state, not governance authoring).
- **`pmo-skill-editor`** writes `release/skills/<skill>/SKILL.md` (and its `references/*.md` files) — routed through [`block-skill-direct-edit.sh`](../hooks/block-skill-direct-edit.sh) Gate 2. Never writes non-skill governance.
- **`pmo-skill-refiner`** writes NEW skill scaffolds under `release/skills/<new-skill>/`. Never edits existing skills (those route through pmo-skill-editor per [`canonical-skill-structure.md § 2`](../standards/canonical-skill-structure.md)).
- **`pmo-qa-auditor`** writes review comments on PRs / sub-tasks. Never modifies source files under review.
- **`pmo-technical-analyst`** writes review comments and design specs in sub-task comments. Never modifies source files.
- **Project-ops skills** write only to the active project's folders (01-08 directories + 08-Generated/ staging). Never modify platform governance.
- **Platform-meta skills** write per their specific scope (`prompt-builder` produces prompt drafts in 08-Generated/ or chat; `eval-writer` produces eval suites in skill `evals/` subfolders).

**Hard enforcement layer.** Two PreToolUse hooks structurally enforce critical write boundaries when running under `bypassPermissions` mode:

- [`core/hooks/block-destructive.sh`](../hooks/block-destructive.sh) **BLOCK-DESTRUCTIVE-019** prevents Layer 1 primary-path writes (CLAUDE.md, `pmo-platform/`, `<OPERATOR_INSTANCE_CLAUDE_SETTINGS>`, `core/rules/`) from non-worktree contexts. All platform-governance writes MUST happen inside a `<OPERATOR_INSTANCE_WORKTREES_PATH>/<name>/` context — never directly on the primary checkout at `${HOME}/Claude/`.
- [`core/hooks/block-skill-direct-edit.sh`](../hooks/block-skill-direct-edit.sh) **BLOCK-SKILL-EDIT-001..002** routes Write/Edit operations on migrated SKILL.md files through `pmo-skill-editor`. Direct SKILL.md edits are blocked at edit-time for any skill carrying frontmatter `skill_discipline_migrated_v10_2: true`. The exemption surface is [`core/config/allowlists/skill-editor-exemption-list.txt`](../config/allowlists/skill-editor-exemption-list.txt) (canary only initially).

**Cascade approval scope (CLAUDE.md § Cascade approval).** A user approval of a Document Tier 1 artifact authorizes downstream Document Tier 2 writes within the artifact's declared `cascade_scope` only. Governance files never auto-cascade. The 4-skill allowlist (`comms-writer`, `delivery-engine`, `tracker-manager`, `artifact-generator`) is the only path for Tier 2 cascade writes; all other skills require explicit per-action approval for any cascade-eligible write.

**Write attribution discipline.** Every commit is co-authored per the workspace owner's git attribution preference; the specific Co-Authored-By identity is a localized (K3) parameter and is not embedded in the universal corpus (parameterization-seam discipline per [`universal-vs-localized-context.md`](../standards/universal-vs-localized-context.md)). PR bodies use `closes #N` (not `fixes` or `resolves`) for issue auto-closure consistency. PRs must not contain "does not close #N" — GitHub's lexical parser triggers auto-close regardless; use "References #N" for partial-work PRs.

---

## Per-Stage Execution Blueprint

> **Universal Function context.** The Primary Function column in the per-stage blocks below is inlined as plain-text data from the function-mapping table in [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md). For each stage's Secondary Functions (the cross-cutting work that overlaps inside the stage), the Cross-Cutting Process Flow touchpoints, and the rationale behind each stage's Primary classification, refer to the function-mapping section in that file. This is the single cross-reference between this document and the function-spine document; the per-stage blocks themselves carry the Primary Function as data, not as a hyperlink.

**3.1 Compact summary table**

| Stage | Owning Skill | Quality Gate | Handoff Contract |
|---|---|---|---|
| [1 Intake](#stage-01-intake) | GAP — see [`stage-to-skill-mode-mapping.md` G1](../../release/references/specs/stage-to-skill-mode-mapping.md) | Gate 1 Triage Readiness (`schemas/gate-criteria-spec.md` Gate 1) | NEW Issue → Triage |
| [2 Triage](#stage-02-triage) | GAP — see [`stage-to-skill-mode-mapping.md` G2](../../release/references/specs/stage-to-skill-mode-mapping.md) | Gate 2 Workflow Readiness (`schemas/gate-criteria-spec.md` Gate 2) | Triage decision → Bundle |
| [3 Bundle](#stage-03-bundle) | `release-planner` Mode A | Gate 3 Release Readiness (`schemas/gate-criteria-spec.md` Gate 3) | Milestone + bundle → Planning (`schemas/stage-io-contracts.md` Boundary Stage 3 → Stage 4) |
| [4 Planning](#stage-04-planning) | `release-planner` Mode B | Stage 4 acceptance (`pipeline/stage-04-planning.md`) | Release plan → Solutioning (`schemas/stage-io-contracts.md` Boundary Stage 4 → Stage 5) |
| [5 Solutioning](#stage-05-solutioning) | `pmo-technical-analyst` Mode C (PARTIAL FIT, bridging to Principal Engineer skill) | Stage 5 acceptance + QC2 dependency validation (`pipeline/stage-05-solutioning.md`) | Design specs + ADRs → Engineering (`schemas/stage-io-contracts.md` Boundary Stage 5 → Stage 6) |
| [6 Engineering](#stage-06-engineering) | GAP — [`implementation-execution-pattern.md`](../../release/references/how-to/implementation-execution-pattern.md) procedure; see [`stage-to-skill-mode-mapping.md` G4](../../release/references/specs/stage-to-skill-mode-mapping.md) | PR creation + self-verification (`pipeline/stage-06-engineering.md`) | PR with verification → Dev Testing |
| [7 Dev Testing](#stage-07-dev-testing) | `pmo-qa-auditor` Modes A+D + `pmo-skill-editor` Mode C | Gate 7 quality review (`schemas/gate-criteria-spec.md` Gate 7 planned) | DT Handoff Payload → QA Testing |
| [8 QA Testing](#stage-08-qa-testing) | `pmo-qa-auditor` Modes A+B | Gate 8 acceptance (`schemas/gate-criteria-spec.md` Gate 8 planned) | QA verdict → Plan Review |
| [9 Plan Review](#stage-09-plan-review) | GAP BY DESIGN — operator-only; see [`stage-to-skill-mode-mapping.md` G5](../../release/references/specs/stage-to-skill-mode-mapping.md) | Operator GO/NO-GO (`pipeline/stage-09-plan-review.md`) | GO record → Execute |
| [10 Dry Run](#stage-10-dry-run) | `release-planner` Mode C (when activated) | Compressed for git-native (`release/governance/release-process.md § Stage Compression`) | (compressed — PR diff IS the dry run) |
| [11 Snapshot](#stage-11-snapshot) | `release-executor` Mode A snapshot phase (when activated) | Compressed for git-native (`release/governance/release-process.md § Stage Compression`) | (compressed — git history IS the snapshot) |
| [12 Execute](#stage-12-execute) | `release-executor` Mode A | Stage 12 deployment integrity (`pipeline/stage-12-execute.md`) | Deployed release → Close (`schemas/stage-io-contracts.md` Boundary Stage 12 → Stage 13) |
| [13 Close](#stage-13-close) | `release-executor` Mode B | QC4 post-deploy verification (`pipeline/stage-13-close.md`) | RELEASE_LOG appended + Milestone closed |

**3.2 Per-stage detailed blocks**

Each block below is the composition view of one stage — Skill + Governance + Tracking + Quality + Handoff + Compartmentalization. Cite-not-duplicate discipline applies throughout: the **Owning Skill** row cites [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md); the **Governance Inputs** and **Governance Writes** rows reference § 2.2 above (the matrix); the **Quality Gate** row cites [`schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) where the named gate is defined; the **Handoff Contract** row cites [`schemas/stage-io-contracts.md`](../schemas/stage-io-contracts.md) where the per-boundary contract is defined; the **Canonical definition** row cites the modular [`pipeline/stage-NN-<name>.md`](../../release/references/pipeline/) file (post-cascade).

### Stage 01: Intake

**Universal Function:** Initiating

**Canonical definition:** [`pipeline/stage-01-intake.md`](../../release/references/pipeline/stage-01-intake.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | **GAP** — no scoped skill currently owns improvement-issue authoring against the `pmo-platform` repo. Forward-ref: **future intake skills**. See [`stage-to-skill-mode-mapping.md` G1](../../release/references/specs/stage-to-skill-mode-mapping.md) for the gap definition and likely successor skill. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md`](../disciplines/decision-discipline.md), [`schemas/gate-criteria-spec.md` Gate 1](../schemas/gate-criteria-spec.md), [`improvement.yml`](../../.github/ISSUE_TEMPLATE/improvement.yml) and [`observation.yml`](../../.github/ISSUE_TEMPLATE/observation.yml) Issue templates. Operator-confirmed observations or session-end candidate improvements as input source. |
| Governance Writes | NEW GitHub Issue with structured fields per the improvement.yml template (priority, category, description, evidence, proposed change, affected files, dependencies, acceptance criteria). No source-file or governance writes at this stage. |
| Tracking Actions | Issue created with Status = Proposed. Labels applied: `improvement` (or `observation` for Observation-tier per CLAUDE.md tier-selection test), category label, layer label. See [`github-projects-guide.md`](github-projects-guide.md) and [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) for field IDs and lifecycle. |
| Artifacts Produced | Single GitHub Issue, structured fields populated, evidence labels applied per [`CLAUDE.md` § Universal Preferences "Evidence quality labels"](<OPERATOR_INSTANCE_CLAUDE_MD>). |
| Quality Gate | **Gate 1 Triage Readiness** — `auto` (structural) + `recommend` (judgment) per [`schemas/gate-criteria-spec.md` Gate 1](../schemas/gate-criteria-spec.md). All required fields populated, evidence labeled, format valid. |
| Handoff Contract | NEW Issue → Stage 2 Triage. Issue body itself IS the handoff artifact; Triage reads structured fields directly from the Issue. |
| Compartmentalization | Cannot author governance edits (only the Issue body); cannot render Triage decision (operator-only at Stage 2); cannot modify [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) or any other governance file from Intake. |

### Stage 02: Triage

**Universal Function:** Initiating

**Canonical definition:** [`pipeline/stage-02-triage.md`](../../release/references/pipeline/stage-02-triage.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | **GAP** — no scoped skill currently owns Workflow Readiness gate execution. `delivery-engine` triage modes are sprint-backlog scoped (project-ops). Forward-ref: **future intake skills**. See [`stage-to-skill-mode-mapping.md` G2](../../release/references/specs/stage-to-skill-mode-mapping.md). |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md`](../disciplines/decision-discipline.md), [`schemas/gate-criteria-spec.md` Gate 2](../schemas/gate-criteria-spec.md) (G2-01 priority validity, G2-02 duplicate detection, G2-03 category verification, G2-04 dependency state validation), [`schemas/field-lifecycle-matrix.md`](../schemas/field-lifecycle-matrix.md) Gate 1→2 inheritance, [`pipeline/stage-02-triage.md`](../../release/references/pipeline/stage-02-triage.md). |
| Governance Writes | Issue Status field transition (Triage → Approved / Deferred / Rejected), dependency labels, priority and category fields. Decision Date field set. No source-file or governance writes at this stage. |
| Tracking Actions | Status field update per [`github-projects-guide.md`](github-projects-guide.md); label updates per [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) conflict resolution rules; Decision Date set on the Issue. |
| Artifacts Produced | Triage decision recorded on Issue (comment with rationale); state anchor update via `gh project item-edit` and `gh issue edit --add-label`. |
| Quality Gate | **Gate 2 Workflow Readiness** — `auto` (structural — fields present, dependency state valid) + `recommend` (judgment — priority calibration, category verification) per [`schemas/gate-criteria-spec.md` Gate 2](../schemas/gate-criteria-spec.md). G2-04 dependency block on Rejected dependencies. |
| Handoff Contract | Triage decision → Stage 3 Bundle. Issue carries Status = Approved + Decision Date + finalized priority/category; Stage 3 reads these as scope candidates. |
| Compartmentalization | Cannot author bundle composition (Stage 3 owns); cannot author release plan (Stage 4 owns); cannot author governance edits; cannot resolve Rejected dependencies (the Issue's dependencies are inputs, not outputs). |

### Stage 03: Bundle

**Universal Function:** Planning

**Canonical definition:** [`pipeline/stage-03-bundle.md`](../../release/references/pipeline/stage-03-bundle.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `release-planner` **Mode A — Backlog Analysis** (Tier 2 Recommend). Mode A produces dependency graph + suggested bundles + version recommendations; operator reviews and creates Milestone. See [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 3 row. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md`](../disciplines/decision-discipline.md), [`schemas/gate-criteria-spec.md` Gate 3](../schemas/gate-criteria-spec.md) (G3-01..G3-06), [`roadmaps/`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/) (capability-vision context), [`pipeline/stage-03-bundle.md`](../../release/references/pipeline/stage-03-bundle.md), Approved issues on the backlog, dependency graph, file contention map, release history in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). |
| Governance Writes | NEW Milestone (created with version number and bundle rationale), Issue Milestone field updated on each bundled issue, `status: bundled` label applied. No source-file writes at this stage. |
| Tracking Actions | Milestone creation via `gh api`; Issue Milestone field via `gh issue edit --milestone`; label updates per [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md). State anchor: Issue Status = Approved → Bundled. |
| Artifacts Produced | Milestone with assigned issues, dependency graph (in bundle rationale comment), capacity assessment, bundle rationale comment on first issue or Milestone description. |
| Quality Gate | **Gate 3 Release Readiness** — `auto` (G3-01 milestone created, G3-02 ≥1 issue, G3-04 no circular deps) + `recommend` (G3-03 dependencies satisfied, G3-05 version assigned, G3-06 bundle rationale documented) per [`schemas/gate-criteria-spec.md` Gate 3](../schemas/gate-criteria-spec.md). Operator override with documented rationale for any gate failure. |
| Handoff Contract | Milestone + bundle → Stage 4 Planning. Per [`schemas/stage-io-contracts.md` Boundary Stage 3 → Stage 4](../schemas/stage-io-contracts.md). |
| Compartmentalization | Read-only across governance and source; only writes are GitHub state (Milestone + Issue labels/fields); never modifies governance files, skills, or project artifacts. `release-planner` SKILL.md Operating Principles explicit: "Read-only. The only file you write is the release plan file" (Stage 4 deliverable). |

### Stage 04: Planning

**Universal Function:** Planning

**Canonical definition:** [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `release-planner` **Mode B — Release Planning** (Tier 2 Recommend). Mode B writes the release plan file with implementation sequence, file change matrix, risk register, delivery strategy, verification plan, rollback strategy. See [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 4 row. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md`](../disciplines/decision-discipline.md) § 3 (D-Gate template), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md), [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md), [`standards/triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) (Tier 0 PT-1..PT-4 premise problem types), [`schemas/stage-io-contracts.md` Boundary Stage 3 → Stage 4](../schemas/stage-io-contracts.md), Milestone scope from Stage 3. |
| Governance Writes | `release/releases/plans/[version]_RELEASE_PLAN.md` (on release branch), Stage 4 sub-task comment with D-Gate decisions, file-overlap-audit folder at `<OPERATOR_INSTANCE_ANALYSIS_PATH>/file-overlap-audit-YYYY-MM-DD/` (when A4 cross-PR contention applies). |
| Tracking Actions | Stage → 4-Planning on each release issue, Status remains In Progress; Stage 4 sub-task closes on plan commit. |
| Artifacts Produced | Release plan file, dependency-ordered implementation sequence, file change matrix, risk register, verification plan, rollback strategy, A4 cross-PR overlap analysis (when applicable per [`../../release/ADRs/ADR-001-cross-pr-overlap-audit-baseline.md`](../../release/ADRs/ADR-001-cross-pr-overlap-audit-baseline.md)). |
| Quality Gate | Stage 4 acceptance per [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md) — `auto` (release plan file exists on branch, implementation sequence dependency-ordered, no unresolved D-decisions) + `recommend` (judgment on file-overlap-audit completeness, A4 cross-PR contention resolution). |
| Handoff Contract | Release plan → Stage 5 Solutioning (when activated per applicability matrix). Per [`schemas/stage-io-contracts.md` Boundary Stage 4 → Stage 5](../schemas/stage-io-contracts.md). |
| Compartmentalization | Writes only the release plan file; never modifies governance, skills, source files, or projects/. Never executes plan (Engineering owns Stage 6). Per `release-planner` SKILL.md `## Operating Principles` "Read-only" and "Plan-driven" semantics. |

### Stage 05: Solutioning

**Universal Function:** Planning

**Canonical definition:** [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `pmo-technical-analyst` **Mode C — Architecture / Infrastructure Review** (PARTIAL FIT, bridging until **Principal Engineer skill** ships per [`release-personas.md`](../../release/references/specs/release-personas.md) Stage 5). See [`stage-to-skill-mode-mapping.md` G3](../../release/references/specs/stage-to-skill-mode-mapping.md) for the partial-fit gap definition. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md` § 3](../disciplines/decision-discipline.md) (M1 Localization, M2 Opposing View, M3 Pattern Cache Scan), [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md), [`architecture-overview.md`](../disciplines/architecture-overview.md), [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) Procedure 0 D-Gate Template, [`schemas/stage-io-contracts.md` Boundary Stage 4 → Stage 5](../schemas/stage-io-contracts.md). Release plan from Stage 4 as the input contract; platform architecture context for blast-radius analysis. |
| Governance Writes | NEW ADR Issue (`adr` label) and/or ADR file in [`core/ADRs/`](../ADRs/) (cross-cutting) or [`release/ADRs/`](../../release/ADRs/) (release-scope) (per Stage 5 spec § 6 ADR Recommendation), Stage 5 sub-task comment with D-decisions and rationale, refined change-specs in the release plan deviation log. |
| Tracking Actions | Stage → 5-Solutioning, Status remains In Progress; on close: sub-task closed; ADR Issue opened with operator as decider. |
| Artifacts Produced | Refined change specs, blast-radius analysis, ADR draft(s), implementability assessment, skip rationale (when Solutioning is skipped per applicability matrix). |
| Quality Gate | Stage 5 acceptance per [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) + **QC2 Dependency Validation** per [`release/governance/release-process.md § QA Checkpoint Framework`](../../release/governance/release-process.md) (QC2-01..QC2-04: declared deps still compatible, no new circular chains, cross-file impact validated, new implicit deps registered). |
| Handoff Contract | Design specs + ADRs → Stage 6 Engineering. Per [`schemas/stage-io-contracts.md` Boundary Stage 5 → Stage 6](../schemas/stage-io-contracts.md) Path A (Solutioning activated) or Path B (Solutioning skipped). Collective Review post-Stage-5 validates cross-issue design coherence before engineering authorization. |
| Compartmentalization | Cannot write source files (Engineering owns Stage 6); cannot author PR (Engineering owns); cannot render gate decision (operator owns); review-only at Stage 5 per `pmo-technical-analyst` SKILL.md `## Operating Principles`. |

### Stage 06: Engineering

**Universal Function:** Executing

**Canonical definition:** [`pipeline/stage-06-engineering.md`](../../release/references/pipeline/stage-06-engineering.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | **GAP** — no scoped skill. Existing procedure: [`implementation-execution-pattern.md`](../../release/references/how-to/implementation-execution-pattern.md) (supersedes deprecated `implementer` skill). Forward-ref: **engineering-role skill** (engineering-skill candidate). See [`stage-to-skill-mode-mapping.md` G4](../../release/references/specs/stage-to-skill-mode-mapping.md). |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`decision-discipline.md`](../disciplines/decision-discipline.md), [`pipeline/stage-06-engineering.md`](../../release/references/pipeline/stage-06-engineering.md), [`../rules/git-workflow.md`](../rules/git-workflow.md) (worktree discipline, branch naming, PR process), [`implementation-execution-pattern.md`](../../release/references/how-to/implementation-execution-pattern.md), [`autonomous-execution-model.md`](../disciplines/autonomous-execution-model.md) (Retry / Escalate / Rollback patterns), [`schemas/stage-io-contracts.md` Boundary Stage 5 → Stage 6](../schemas/stage-io-contracts.md), file-specific governance per change-spec, release plan from Stage 4 (or Solutioning-refined plan from Stage 5). |
| Governance Writes | Source files per change-spec, PR body + metadata (milestone, labels, assignee, reviewer, project per [`../rules/git-workflow.md`](../rules/git-workflow.md) PR process), sub-task comments, RELEASE_PLAN deviation log entries, deployed-copy sync via `core/deploy/deploy.sh --deploy` for changed skills and harness artifacts. |
| Tracking Actions | Stage → 6-Engineering on each release issue, Status = In Progress; PR opened with `closes #N` for each fully-resolved issue; sub-tasks closed on commit per chip; per the PR-body close-keyword discipline, do NOT use "does not close #N" — use "References #N" for partial-work PRs. |
| Artifacts Produced | Committed changes on release branch, PR with full metadata and self-verification evidence in body, sub-task completion comments, deployed copy sync verified via `core/deploy/deploy.sh --check`. |
| Quality Gate | PR creation + self-verification per [`pipeline/stage-06-engineering.md`](../../release/references/pipeline/stage-06-engineering.md) — `auto` (PR exists, metadata complete, deploy check passes) + `recommend` (judgment on self-verification evidence completeness). Phase A checkpoint: sub-task decomposition presented before Phase B implementation. |
| Handoff Contract | PR with verification evidence → Stage 7 Dev Testing. DT consumes the PR diff + Engineering self-verification evidence as its input. |
| Compartmentalization | Cannot render gate decision (operator owns Stage 9); cannot author SKILL.md edits outside pmo-skill-editor routing (BLOCK-SKILL-EDIT-001..002 hook enforces); cannot perform Layer 1 primary-path writes from non-worktree contexts (BLOCK-DESTRUCTIVE-019 hook enforces). DT iteration response uses `fix(dt):` commit convention with iteration tag per [`release/governance/release-process.md` DT↔Engineering Iteration Loop Protocol](../../release/governance/release-process.md). |

### Stage 07: Dev Testing

**Universal Function:** Monitoring & Controlling

**Canonical definition:** [`pipeline/stage-07-dev-testing.md`](../../release/references/pipeline/stage-07-dev-testing.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `pmo-qa-auditor` **Mode A — Single Output Review** + **Mode D — Document Management Compliance** (split by artifact type: Mode A for skill outputs, Mode D for governance documents); `pmo-skill-editor` **Mode C — Regression** (friction-log regression for skill-modification PRs). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 7 row. Forward-ref: dedicated QA Auditor dev mode. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md), [`pipeline/stage-07-dev-testing.md`](../../release/references/pipeline/stage-07-dev-testing.md), [`schemas/gate-criteria-spec.md` Gate 7](../schemas/gate-criteria-spec.md) (planned per `stage-to-skill-mode-mapping.md` forward-ref), [`standards/principal-standard-checklist.md`](../standards/principal-standard-checklist.md), [`standards/regression-checks.md`](../standards/regression-checks.md), PR diff + Engineering self-verification evidence from Stage 6, verification plan from release plan. On QA return: QA Return to Dev Testing payload triggers Pass N+1 full re-review. |
| Governance Writes | DT report comment on PR (or sub-task), structured Handoff Payload per [`pipeline/stage-07-dev-testing.md` DT↔QA Handoff Protocol](../../release/references/pipeline/stage-07-dev-testing.md#dtqa-handoff-protocol-source-200-204) (`### Output for Stage 8` heading + machine-parseable fields), iteration-log entries for iteration cycles per [`pipeline/stage-07-dev-testing.md` DT↔Engineering Iteration Loop Protocol](../../release/references/pipeline/stage-07-dev-testing.md#dtengineering-iteration-loop-protocol-source-192). |
| Tracking Actions | Stage → 7-DevTesting; iteration counter incremented on each `fix(dt):` cycle; iteration label applied per [`schemas/handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md). Escalation threshold: >3 iterations route to operator. |
| Artifacts Produced | Quality review report with LLM-graded content assessment, eval set results, escape detection, finding classification by routing tier (Tier 1 Auto / Tier 2 [SCOPE CHANGE] / Tier 3 [PLAN REJECTION] per [`release/governance/release-process.md` Inter-Stage Feedback Protocol](../../release/governance/release-process.md)), Handoff Payload to Stage 8. |
| Quality Gate | Gate 7 quality review per [`schemas/gate-criteria-spec.md` Gate 7](../schemas/gate-criteria-spec.md) (planned) + [`pipeline/stage-07-dev-testing.md`](../../release/references/pipeline/stage-07-dev-testing.md) acceptance — `auto` (structural checks per `standards/regression-checks.md`) + `recommend` (judgment on principal standard compliance per `standards/principal-standard-checklist.md`). |
| Handoff Contract | DT Handoff Payload → Stage 8 QA Testing. Iteration loop: DT↔Engineering iterates until PASS/CONDITIONAL PASS; Pass 1 = full review, Pass 2+ = targeted re-review. |
| Compartmentalization | Review-only; cannot modify source files (Engineering owns); cannot render acceptance verdict (Stage 8 owns); cannot route Tier 2/3 findings without operator (Tier 1 Auto is the only auto-route per the release-orchestration-autonomy discipline). |

### Stage 08: QA Testing

**Universal Function:** Monitoring & Controlling

**Canonical definition:** [`pipeline/stage-08-qa-testing.md`](../../release/references/pipeline/stage-08-qa-testing.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `pmo-qa-auditor` **Mode A — Single Output Review** (per-acceptance-criterion gate evaluation) + **Mode B — Cross-Skill Coherence Review** (multi-issue release coherence). Stage 8 acceptance verdict is operator-rendered (Tier 2 Recommend). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 8 row. Forward-ref: dedicated QA Auditor acceptance mode. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md), [`pipeline/stage-08-qa-testing.md`](../../release/references/pipeline/stage-08-qa-testing.md), [`schemas/gate-criteria-spec.md` Gate 8](../schemas/gate-criteria-spec.md) (planned), AC eval set per release plan, DT Handoff Payload from Stage 7. Phase A validates the DT Handoff Payload conformance per [`pipeline/stage-07-dev-testing.md` DT↔QA Handoff Protocol](../../release/references/pipeline/stage-07-dev-testing.md#dtqa-handoff-protocol-source-200-204). |
| Governance Writes | QA verdict comment on PR or Issue (acceptance evidence), QA Return to Dev Testing payload per [`pipeline/stage-07-dev-testing.md` §Return Path](../../release/references/pipeline/stage-07-dev-testing.md#dtqa-handoff-protocol-source-200-204) (Lane 2 findings — preserved as layered review per not routed directly to Engineering). |
| Tracking Actions | Stage → 8-QATesting; Lane 2 return path increments QA↔DT round-trip counter (escalation at ≥3 round-trips protocol). |
| Artifacts Produced | QA results, acceptance sign-off or rejection with specific defects (failing check ID, file, line range, expected vs. actual-01..QC3-04 protocol). |
| Quality Gate | **QC3 Pre-Merge QA** per [`release/governance/release-process.md § QA Checkpoint Framework`](../../release/governance/release-process.md) (QC3-01 regression, QC3-02 schema validation, QC3-03 cross-reference integrity, QC3-04 AC verified against evidence) + Gate 8 acceptance per [`schemas/gate-criteria-spec.md` Gate 8](../schemas/gate-criteria-spec.md) (planned). |
| Handoff Contract | QA verdict → Stage 9 Plan Review. DT↔QA round-trip: Lane 2 findings emit QA Return to Dev Testing payload (composes with Stage 7's iteration loop on Engineering fix; emits Return-to-QA Verified signal). |
| Compartmentalization | Review-only; cannot modify source files; cannot render final go/no-go (operator at Stage 9 owns); per `pmo-qa-auditor` SKILL.md Mode A/B Operating Principles. |

### Stage 09: Plan Review

**Universal Function:** Monitoring & Controlling

**Canonical definition:** [`pipeline/stage-09-plan-review.md`](../../release/references/pipeline/stage-09-plan-review.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | **GAP BY DESIGN** — Tier 3 Human-only per [`pipeline/stage-09-plan-review.md`](../../release/references/pipeline/stage-09-plan-review.md) and [`release-personas.md`](../../release/references/specs/release-personas.md) Stage 9. `ppm-agent` Section 5 (Decisions needed) + gate-decision documentation pattern provide the briefing scaffold; no skill replacement planned. See [`stage-to-skill-mode-mapping.md` G5](../../release/references/specs/stage-to-skill-mode-mapping.md). |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`pipeline/stage-09-plan-review.md`](../../release/references/pipeline/stage-09-plan-review.md), all Stage 4-8 outputs (release plan, DT Handoff Payload, QA verdict, acceptance evidence), `ppm-agent` Section 5 decision-briefing scaffold. |
| Governance Writes | Operator decision record (sub-task comment with GO/NO-GO + rationale + any last-minute adjustments). Gate sub-task closed BEFORE routing next chip per the gate-decision-documentation discipline. |
| Tracking Actions | Stage → 9-PlanReview; on GO: route to Stage 12 Execute (Stages 10-11 compressed for git-native releases); on NO-GO: route to remediation per failure mode (back to Engineering Tier 2/3, or back to Solutioning for re-design, or defer release). |
| Artifacts Produced | Go/No-Go decision recorded as sub-task comment + decision record in release plan. Any last-minute adjustments to the release plan documented in deviation log. |
| Quality Gate | Operator GO/NO-GO per [`pipeline/stage-09-plan-review.md`](../../release/references/pipeline/stage-09-plan-review.md). PR diff IS the dry-run for git-native releases (Stages 10-11 compressed per [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md)). |
| Handoff Contract | GO record → Stage 12 Execute (compressed routing for git-native; or Stage 10 → Stage 12 when compression exceptions apply). NO-GO routes back to upstream stage per failure mode. |
| Compartmentalization | Cannot author skill / governance changes (Stage 6 owns); cannot deploy (Stage 12 owns); operator decision-only. The gate-decision-documentation discipline applies — decision-record comment posted and gate sub-task closed BEFORE routing the next chip. |

### Stage 10: Dry Run

**Universal Function:** Executing

**Canonical definition:** [`pipeline/stage-10-dry-run.md`](../../release/references/pipeline/stage-10-dry-run.md) (post-cascade) — note this stage is **COMPRESSED** for git-native releases per [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md).

| Field | Value |
|---|---|
| Owning Skill(s) | `release-planner` **Mode C — Dry Run** when activated (compression exceptions: non-git deploy targets, destructive operations, Layer 2 file deployment with new mechanism). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 10 row. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md), [`pipeline/stage-10-dry-run.md`](../../release/references/pipeline/stage-10-dry-run.md), [`../governance/RELEASE_PROTOCOL.md`](../../release/governance/RELEASE_PROTOCOL.md) Dry-Run Protocol when activated. |
| Governance Writes | Dry-Run Record section appended to release plan **when activated**; otherwise compressed (no separate write — PR diff IS the dry run for git-native). |
| Tracking Actions | Stage → 10-DryRun (only when activated); otherwise compressed and skipped in the stage anchor sequence. |
| Artifacts Produced | When activated: dry-run record with rollback validation. Otherwise: no separate artifact (PR diff reviewed at Stage 9 IS the dry-run output for git-native). |
| Quality Gate | Compressed for git-native releases per [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md); activates only with compression exceptions (non-git deploy, destructive ops, Layer 2 with new mechanism). |
| Handoff Contract | When activated: dry-run validation → Stage 12 Execute. When compressed: handoff is from Stage 9 GO directly to Stage 12 (no separate Stage 10 boundary). |
| Compartmentalization | When activated: same scope as `release-planner` Mode B (read-only across governance; writes only release plan dry-run section). When compressed: stage does not execute. |

### Stage 11: Snapshot

**Universal Function:** Executing

**Canonical definition:** [`pipeline/stage-11-snapshot.md`](../../release/references/pipeline/stage-11-snapshot.md) (post-cascade) — note this stage is **COMPRESSED** for git-native releases per [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md).

| Field | Value |
|---|---|
| Owning Skill(s) | `release-executor` **Mode A — Execute Release** (snapshot phase) when activated. Activates only for non-git deploy targets per [`../governance/RELEASE_PROTOCOL.md`](../../release/governance/RELEASE_PROTOCOL.md). Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 11 row. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`release/governance/release-process.md § Stage Compression`](../../release/governance/release-process.md), [`pipeline/stage-11-snapshot.md`](../../release/references/pipeline/stage-11-snapshot.md), [`../governance/RELEASE_PROTOCOL.md`](../../release/governance/RELEASE_PROTOCOL.md) Pre-Change Snapshot Protocol when activated. |
| Governance Writes | Pre-change snapshots written to `releases/_snapshots/` **when activated**; otherwise compressed (git history IS the snapshot — `git revert` restores prior state). |
| Tracking Actions | Stage → 11-Snapshot (only when activated); otherwise compressed and skipped in the stage anchor sequence. |
| Artifacts Produced | When activated: pre-change snapshot files in `releases/_snapshots/`. Otherwise: no separate artifact (git history is the snapshot mechanism). |
| Quality Gate | Compressed for git-native releases; activates only for non-git deploy targets (Layer 2 deployment with state mutation, schema migration, etc.). |
| Handoff Contract | When activated: snapshot complete → Stage 12 Execute. When compressed: handoff is from Stage 10 (or directly from Stage 9 GO) to Stage 12. |
| Compartmentalization | When activated: same scope as `release-executor` Mode A (writes snapshots + executes operations; never modifies source-of-truth governance content). When compressed: stage does not execute. |

### Stage 12: Execute

**Universal Function:** Executing

**Canonical definition:** [`pipeline/stage-12-execute.md`](../../release/references/pipeline/stage-12-execute.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `release-executor` **Mode A — Execute Release** (Tier 1 Auto with Tier 3 gate at Stage 9). Mode A executes the merge / tag / deploy sequence after operator authorizes Stage 9 GO. Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 12 row. Forward-ref: Stage 12 may gain concurrency-control logic for parallel-PR scenarios. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`pipeline/stage-12-execute.md`](../../release/references/pipeline/stage-12-execute.md), [`../governance/RELEASE_PROTOCOL.md`](../../release/governance/RELEASE_PROTOCOL.md), [`release/governance/release-process.md § Stage 12`](../../release/governance/release-process.md), [`../rules/git-workflow.md`](../rules/git-workflow.md) PR Process and post-merge worktree discipline, [`../rules/skill-deployment.md`](../rules/skill-deployment.md), [`../rules/harness-deployment.md`](../rules/harness-deployment.md), [`schemas/stage-io-contracts.md` Boundary Stage 12 → Stage 13](../schemas/stage-io-contracts.md), Stage 9 operator GO record. |
| Governance Writes | RELEASE_LOG.md append (deployment evidence: files deployed, mechanism used, timestamp, success/fail per file), signed-annotated version tag created and pushed (`git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<n>" vX.Y "$MERGE_SHA" && git push origin vX.Y`), `gh project item-edit` for all release issues (Status → Done, Stage → 12-Execute), `core/deploy/deploy.sh --deploy` execution for changed skills and harness artifacts. |
| Tracking Actions | Stage → 12-Execute on each release issue; Status → Done. Corresponding `status: done` labels updated per [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md). State anchor field updates per [`github-projects-guide.md`](github-projects-guide.md). |
| Artifacts Produced | Merged PR on main, version tag on GitHub, deployed skill files (when applicable, via S-2 copy mechanism per [`../rules/skill-deployment.md`](../rules/skill-deployment.md)), deployed harness artifacts (when applicable, per [`../rules/harness-deployment.md`](../rules/harness-deployment.md)), deployment execution log appended to RELEASE_LOG.md. |
| Quality Gate | Stage 12 deployment integrity per [`pipeline/stage-12-execute.md`](../../release/references/pipeline/stage-12-execute.md) — pre-merge check (PR has milestone, labels, assignee, reviewer, project; missing metadata blocks merge) + deploy.sh --check on Layer 2 propagation success. Self-repair: Retry on transients (cap=2 — production-impacting); Escalate on retry-exhausted deploy; Rollback (operator-only) on post-merge regression per [`autonomous-execution-model.md`](../disciplines/autonomous-execution-model.md). |
| Handoff Contract | Deployed release → Stage 13 Close. Per [`schemas/stage-io-contracts.md` Boundary Stage 12 → Stage 13](../schemas/stage-io-contracts.md). |
| Compartmentalization | Plan-driven; never executes changes without an approved release plan file with a Dry-Run Record section (per `release-executor` SKILL.md `## Operating Principles`). Snapshot-first when Stage 11 is activated. Never modifies source-of-truth governance content (RELEASE_LOG.md append is operational state). Never authors SKILL.md edits (those route through pmo-skill-editor). |

### Stage 13: Close

**Universal Function:** Closing

**Canonical definition:** [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) (post-cascade)

| Field | Value |
|---|---|
| Owning Skill(s) | `release-executor` **Mode B — Verify Release** (Tier 1 Auto). Mode B verifies deployment artifacts, closes Milestone, appends RELEASE_LOG.md verification evidence, and authors / verifies presence of the user-facing release note. Per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) Stage 13 row. Forward-ref: Stage 13 verification may gain cross-release dependency-check logic. |
| Governance Inputs | [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>), [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md), [`schemas/gate-criteria-spec.md` Gate 13](../schemas/gate-criteria-spec.md) (planned), Stage 12 deployment evidence in RELEASE_LOG.md, [`standards/release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) (user-facing release note format per ), Stage 12 PR merge state. |
| Governance Writes | RELEASE_LOG.md verification append (per-file deploy verification: deployed files match git source via diff-clean; each deployed skill responds without error; updated trackers match schemas; regression passes), Milestone closed on GitHub, Issue auto-close verification (PRs with `closes #N` auto-close issues — Stage 13 confirms final state), user-facing `release/releases/notes/[version]_RELEASE_NOTES.md` matching [`standards/release-notes-standard.md`](../../release/references/standards/release-notes-standard.md). |
| Tracking Actions | Stage → 13-Close on each release issue; verify Status = Done; close Milestone on GitHub. State anchor verification per [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) conflict resolution rules. |
| Artifacts Produced | RELEASE_LOG.md verification entry, closed Milestone, user-facing release note at `release/releases/notes/[version]_RELEASE_NOTES.md`, verification evidence persisted in release plan. |
| Quality Gate | **QC4 Post-Deploy Verification** per [`release/governance/release-process.md § QA Checkpoint Framework`](../../release/governance/release-process.md) (QC4-01 deploy integrity, QC4-02 skill invocation, QC4-03 tracker conformance, QC4-04 regression preserved) + Gate 13 per [`schemas/gate-criteria-spec.md` Gate 13](../schemas/gate-criteria-spec.md) (planned). Any QC4 failure → automatic operator notification (post-deploy = production-impacting). |
| Handoff Contract | RELEASE_LOG.md appended + Milestone closed + user-facing release note published. Per [`schemas/stage-io-contracts.md`](../schemas/stage-io-contracts.md). Release is not complete until verification evidence is persisted in the release plan's Verification Evidence section. |
| Compartmentalization | Verifies and finalizes; does not modify source files; does not author new governance (only operational state appends). Per `release-executor` SKILL.md Mode B Operating Principles. Releases shipping a Review-Surface trigger (deprecation, breaking change, state-mutating default, removal, or new restriction per [`standards/release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) Rule 3) require Stage 9 Plan Review of the user-facing note before merge. |

---

*Operating model authored at Stage 6 Engineering per Stage 5 spec and Collective Review record 2026-05-10. Companion files: the function-spine document (cross-referenced once from § 3.2 above) and the modular pipeline-stages reference (cascade ships in PR-1 ahead of this PR).*
