# PMO Platform Context

## Usage

This file is loaded into the refiner's context during Interview mode so the refiner asks informed questions about the PMO platform — dependency conventions, layer boundaries, shared contracts. It is the architectural reference that distinguishes "PMO skill" from "generic skill" and drives the 7 PMO Injection Points.

---

## Platform Overview

The PMO platform is organized into two domains with distinct management rules:

| Domain | Location | Git Status | Organizing Principle | Managing Agent |
|---|---|---|---|---|
| **Engineering (Layer 1)** | `pmo-platform/` | Tracked | Function-oriented (governance, skills, reference, packages, releases, engineering) | Claude Code via git |
| **Operations (Layer 2)** | `projects/` | Ignored | Tier-oriented (portfolio → program → project) | Cowork |

New skills created via the refiner live in `release/skills/<name>/`. Skills may READ Layer 2 files (`projects/_config/PORTFOLIO.md`, `SESSION_STATE.md`, `CORRECTIONS.md`) for context but MUST NOT WRITE to any Layer 2 file.

## 13-Stage Pipeline

The platform runs releases through a 13-stage pipeline (`release/references/pipeline/`). Skills are typically invoked at specific stages:

| Stage range | Skill archetypes |
|---|---|
| Stage 1–2 (Intake/Triage) | `ppm-agent`, `file-router` |
| Stage 3–5 (Bundle/Plan/Solution) | `release-planner`, `implementation-planner`, `pmo-technical-analyst` |
| Stage 6 (Engineering) | Executor skills — `tracker-manager`, `artifact-generator`, `comms-writer` |
| Stage 7–8 (Dev Testing / QA) | `pmo-qa-auditor`, `build-reviewer` |
| Stage 12–13 (Execute/Close) | `release-executor`, `weekly-status-rollup` |
| Meta (cross-stage) | `pmo-skill-editor`, `pmo-skill-refiner`, `skill-creator` (deprecated) |

New skills typically land in one of these slots. The refiner's Interview Q6 asks which upstream/downstream skills the new skill depends on; the answers drive the dependency-graph.md node.

## Governance File Hierarchy

See CLAUDE.md § Governance File Map for the authoritative table. Key constraint for skill-building: skills MUST NOT write to governance files (CLAUDE.md, OPERATIONS.md, PORTFOLIO.md, SESSION_STATE.md, RELEASE_PROTOCOL.md). Governance changes flow through the release process (PR + dry-run + snapshot per § No ungoverned changes).

## Methodology Framework — `delivery_approach`

The `delivery_approach` frontmatter field parameterizes the skill to the active project's methodology. Valid values:

| Value | Semantics |
|---|---|
| `waterfall` | Milestone / phase-gate / fixed scope |
| `agile` | Sprint / velocity / emergent scope |
| `kanban` | Flow / throughput / continuous |
| `hybrid` | Mixed (e.g., SAFe, Scaled Agile) |
| `n/a` | Methodology-agnostic skill (rare; only for pure utilities) |
| `context-aware` (planned) | Skill derives methodology from project context at runtime — planned future capability, not yet shipped |

**When methodology matters:** Skills that produce sprint plans, velocity forecasts, milestone dashboards, or phase-gate outputs assume a specific methodology. Hardcoding the assumption is a TRIG failure mode (see `pmo-antipatterns.md` entry 3). Parameterize via `delivery_approach` so the same skill serves waterfall and agile projects.

**When methodology doesn't matter:** Skills like `file-router` (filename-based routing) or `tracker-manager` (generic tracker updates) are methodology-agnostic — declare `n/a` explicitly rather than omitting the field.

## Skill-Suite Dependency Graph (condensed)

Inline summary of the current graph in `core/knowledge-base/dependency-graph.md`. Used by Interview Q6 to prompt for upstream/downstream edges.

| Skill | Upstream | Downstream |
|---|---|---|
| ppm-agent | None (entry point) | All downstream via follow-up tags; tracker-manager via structured updates |
| delivery-engine | ppm-agent | comms-writer (status data), change-management (via [CHANGE]) |
| comms-writer | ppm-agent, delivery-engine, change-management, pmo-process-designer | User (sending) |
| change-management | ppm-agent, delivery-engine, pmo-technical-analyst | comms-writer (via [COMMS]) |
| pmo-technical-analyst | ppm-agent | change-management (via [CHANGE]), delivery-engine (via [DELIVERY]) |
| pmo-process-designer | ppm-agent | comms-writer (via [COMMS]) |
| pmo-qa-auditor | All skills (audits outputs) | Operator (findings) |
| pmo-skill-editor | All skills (edits) | Operator (reviews), pmo-qa-auditor (post-edit validation) |
| implementation-planner | pmo-qa-auditor (consumes findings), build-reviewer | Engineering execution (via implementation-execution-pattern.md) |
| pmo-skill-refiner | External Anthropic skills, failure-mode-standard.md, reversibility-protocol.md, principal-standard-checklist.md, per-skill-output-contracts.md, dependency-graph.md | All newly-created or refined PMO skills |

Interview Q6 asks: "Which upstream skill feeds input into this new skill? Which downstream skill consumes its output?" The refiner uses this table to offer specific candidates rather than open-ended prompts.

## Cross-Skill Contracts (Shared Interfaces)

Every PMO skill honors these shared contracts. Interview Q7 asks which contracts the new skill produces or consumes.

### Evidence quality labels

Every factual claim in skill outputs carries one of five labels per CLAUDE.md § Universal Preferences:
- `[SOURCE: <source>]` — direct citation from an authoritative input (RAID log, transcript, ticket system, domain doc)
- `[INFERRED]` — derived from inputs via named reasoning; not a direct quote
- `[ASSUMPTION – CONFIRM: <proposed-answer>]` — Claude's proposed answer when input is missing; requires user confirmation
- `[CONTEXT]` — background framing; not a claim
- `[RECOMMENDED]` — proposed date or action without operator confirmation

Applies to internal analysis, not only user-facing outputs. See `## Evidence Quality Protocol` injection field.

### Follow-up tag routing

Skills emit follow-up tags to route work to specialist skills. Max depth 2 (PPM → specialist → optional single handoff). Permitted tags:

| Tag | Target Skill |
|---|---|
| `[DELIVERY]` | delivery-engine |
| `[COMMS]` | comms-writer |
| `[DECISION]` | ppm-agent (self) |
| `[RISK]` | ppm-agent (self) |
| `[TECHNICAL]` | pmo-technical-analyst |
| `[PROCESS]` | pmo-process-designer |
| `[CHANGE]` | change-management |

New skills declare their emitted and consumed tags in Interview Q7; the refiner registers these in the dependency-graph.md node.

### RAID prefixes

Skills that produce RAID entries carry a skill-specific prefix: `R-PPM-###` (ppm-agent), `R-DE-###` (delivery-engine), `R-CM-###` (change-management), `R-TA-###` (pmo-technical-analyst), `R-PD-###` (pmo-process-designer), `R-PSR-###` (pmo-skill-refiner). Interview Q7 asks which prefix the new skill uses; the refiner verifies no collision with existing prefixes before accepting.

### Reversibility tiers

Decision-class outputs carry CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE labels paired with HIGH / MEDIUM / LOW confidence per `core/specs/reversibility-protocol.md`. Interview Q3 establishes whether the skill produces decision-class or report-only; this drives the `## Reversibility Discipline` injection branch.

## Layer Boundary Rules

1. **New skills go in `release/skills/<name>/`.** Single-skill directories; no plugin wrapping. If the scaffolder produced a plugin-style layout, the refiner repositions to this single-skill convention.
2. **Skills read Layer 2 for context only.** Paths allowed: `projects/_config/PORTFOLIO.md`, `SESSION_STATE.md`, `CORRECTIONS.md`. Never write.
3. **Governance changes flow through the release process.** If a new skill would need to modify CLAUDE.md, OPERATIONS.md, or other governance files, raise a GitHub Issue per CLAUDE.md § No ungoverned changes — do not encode a direct-write path into the skill.
4. **Deployment lives in `deploy.sh`.** New skills are added to `SKILL_LIST` (and `SUPPLEMENTARY_SKILLS` if they have scripts/agents/references beyond SKILL.md). The refiner flags this as a cascade edit in its handoff message.

## Cascade Scopes for Tier 1 Artifact-Producing Skills

If the new skill produces Tier 1 artifacts (RAID Log, Project Plan, governance docs), declare a `cascade_scope` frontmatter field per CLAUDE.md § Cascade Approval. Scope string enumerates what downstream Tier 2 files the skill may auto-write after user approval of the Tier 1 artifact.

Example: `cascade_scope: "projects/[current-project]/04-PMO-Operations/carry-forward-tracker.md, projects/[current-project]/04-PMO-Operations/open-meetings-tracker.md"`.

The 4-skill allowlist (comms-writer, delivery-engine, tracker-manager, artifact-generator) have this field today. New Tier 1–producing skills extend the list.

## Pre-Deploy Canonical-Session Check

Refiner handoffs MUST instruct the user to run `core/deploy/deploy.sh --check --warn` before `core/deploy/deploy.sh --deploy` to validate that session detection resolves to the canonical (not orphaned) session. The current session paths are declared in `core/rules/skill-deployment.md`. Detection inversion risk is tracked in the platform's deploy-detection investigation.

This check is a runbook instruction in handoff output, not in-skill logic — session canonicity lives in deploy.sh and the deploy-detection investigation.

## Reference doc map

Core reference docs the refiner cites during Interview and injection:

| Doc | Purpose |
|---|---|
| `core/specs/failure-mode-standard.md` | 5-field template + 5-category taxonomy for Domain-Specific Failure Modes |
| `core/specs/reversibility-protocol.md` | Tier vocabulary (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) |
| `core/standards/principal-standard-checklist.md` | Principal Standard checklist and Scoring Guide; skills target CONDITIONAL PASS or better |
| `core/schemas/per-skill-output-contracts.md` | Output schema registration (Skill N entry) |
| `core/knowledge-base/dependency-graph.md` | Upstream/downstream edge registration |
| `core/disciplines/three-gulfs-methodology.md` | Intention / Execution / Evaluation framing for skill design |
| `core/disciplines/review-discipline-principles.md` | Review-class skill methodology (only for review/audit/QA skills; refiner is not one) |
| `CLAUDE.md` | Universal Preferences, Quality Standards, File Management Protocol |
