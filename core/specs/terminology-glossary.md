---
title: Terminology Glossary
purpose: The shared terminology contract between governance docs, skills, and execution tools across the pmo-platform — defines how six categories of terms (Area/Domain, Function/Role/Persona, Process/Methodology/Framework, Stage/Phase/Step, Work Breakdown units, Scope/Time boxes) plus first-class actor terms are used canonically, each mapped to an authoritative-file owner.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
source: "Pre-triage terminology-collision audit (2026-03-29); actor-term + tier-anchoring + frontmatter refresh for cold-agent comprehension as Autonomy Tier 2/3 expands."
consumers: "All agents resolving platform vocabulary; execution-framework.md (Role/Function/Persona/Work-Breakdown anchors); hub-spoke-bridge.md (Hub/Spoke/Sub-agent/Task/Role); registry.md (Skill); release-process.md + pipeline/ (Stage/Phase/Step/Deliverable); methodology-parameterization-v1.md (Methodology)."
---
<!-- reference-durability: allow-link -->
# Terminology Glossary

## Purpose

The Terminology Glossary is the shared terminology contract between governance docs, skills, and execution tools across the pmo-platform. It defines how six categories of terms (Area/Domain, Function/Role/Persona, Process/Methodology/Framework, Stage/Phase/Step, Work Breakdown units, and Scope/Time boxes) are used canonically — grounded in real-world PMO practice and mapped to concrete platform artifacts. Authored to resolve terminology collisions identified in pre-triage (2026-03-29).

## How to Use

Reference terms by stable `{#term-<slug>}` anchor. On first use of a canonical term within a document, link `[term](terminology-glossary.md#term-<slug>)`. The **Authoritative file** column is the single source of truth for each concept — other files consume, not redefine. Consumers MUST use the canonical term when referring to the concept; MAY use the real-world PMO equivalent as gloss. Appendix A tracks historical ambiguities resolved by this glossary; Appendix B lists non-canonical synonyms and the platform terms that replace them.

## Categories

1. [Area / Domain](#category-1--area--domain)
2. [Function / Role / Persona](#category-2--function--role--persona)
3. [Process / Methodology / Framework](#category-3--process--methodology--framework)
4. [Stage / Phase / Step](#category-4--stage--phase--step)
5. [Work Breakdown Terms](#category-5--work-breakdown-terms)
6. [Scope / Time Boxes](#category-6--scope--time-boxes)

---

## Category 1 — Area / Domain

### term: Area {#term-area}

- **Definition:** A top-level organizational unit of the workspace that has its own context file and operates under its own rules.
- **Real-world PMO equivalent:** Business Unit / Department (e.g., Engineering, Operations, HR) — corresponds loosely to an Organizational Breakdown Structure node in PMBOK.
- **Platform equivalent:** Top-level folder under `Claude/` with a `CLAUDE.md` (workspace root) or `CONTEXT.md` (non-PMO work area). Today: `pmo-platform/`, `projects/`.
- **Authoritative file:** `CLAUDE.md` § Workspace Structure.
- **Consumers:** All agents reading workspace structure; routing logic; `deploy.sh`.

### term: Domain {#term-domain}

- **Definition:** A functional territory within a platform Area, organized by purpose rather than tier (e.g., Engineering vs. Operations domains within pmo-platform).
- **Real-world PMO equivalent:** Functional organization dimension of a matrix structure — PMBOK "Functional Manager" owns a domain (software engineering, testing, operations) while "Project Manager" cuts across domains.
- **Platform equivalent:** Two domains today: **Engineering** (owns `pmo-platform/`, function-oriented) and **Operations** (owns `projects/`, tier-oriented). Governed by Layer classification (Layer 1 / Layer 2 / Bridge).
- **Authoritative file:** `CLAUDE.md` § Platform vs. Working Content Boundary.
- **Consumers:** `.claude/rules/operations-bridge.md`, `.claude/rules/skill-deployment.md`, `deploy.sh`.

### term: Work Area {#term-work-area}

- **Definition:** Synonym for Area. Used when the distinction from physical directory matters (e.g., "PMO work area," "non-PMO work area").
- **Real-world PMO equivalent:** Program domain — a collection of projects/initiatives under a shared governance model.
- **Platform equivalent:** Scope inheritance boundary for workspace-global files (CLAUDE.md applies to all; PORTFOLIO.md applies only to PMO work area).
- **Authoritative file:** `CLAUDE.md` § Governance File Map.
- **Consumers:** Scaling model documentation; future non-PMO areas adopting the workspace.

---

## Category 2 — Function / Role / Persona

### term: Function {#term-function}

- **Definition:** A category of work or responsibility in the delivery lifecycle, independent of methodology (e.g., Planning, Executing, Monitoring & Controlling).
- **Real-world PMO equivalent:** PMBOK Process Group — the 5 universal PM functions (Initiating, Planning, Executing, Monitoring & Controlling, Closing) apply regardless of delivery approach (Agile, Waterfall, PRINCE2).
- **Platform equivalent:** Cross-stage activity categories that recur across multiple pipeline stages, enumerated in the authoritative file below.
- **Authoritative file:** `core/disciplines/five-function-spine-and-process-flows.md`
- **Consumers:** Skill personas (pmo-process-designer, ppm-agent), Stage 5 Solutioning design specs, future methodology-aware skill authoring.

### term: Role {#term-role}

- **Definition:** A named set of responsibilities an agent or human assumes during a specific activity (e.g., "Hub Agent," "Spoke Agent," "Operator").
- **Real-world PMO equivalent:** RACI role (Responsible, Accountable, Consulted, Informed) or organizational role title (e.g., "Sponsor," "Project Manager," "Business Analyst").
- **Platform equivalent:** Operator (the human user, **Autonomy Tier 0**), Hub Agent (orchestrating Claude session) and Spoke Agent (spawned Claude session) — both **Autonomy Tier 1–3** per the action. Future: agent roles in multi-agent orchestration. The concrete actors are first-class terms below: [Hub](#term-hub), [Spoke](#term-spoke), [Skill](#term-skill), [Sub-agent](#term-sub-agent).
- **Authoritative file:** `release/references/how-to/hub-spoke-bridge.md` § For the Operator / For the Hub Agent / Spoke Template.
- **Tier-anchoring convention:** State each role's characteristic **Autonomy Tier** when naming it, citing `core/specs/autonomy-tiers.md` as the tier authority — Operator acts at **Autonomy Tier 0** (irreducible-human gates: Stage 9 GO, Stage 12 Execute), the **Hub Agent** and **Spoke Agent** act across **Autonomy Tier 1–3** depending on the action (Tier 1 drafts awaiting approval → Tier 3 standing-authorization execution per an approved plan). This answers "who acts at this tier?" from any role reference without backtracking; the canonical tier definitions live in `core/specs/autonomy-tiers.md` (this glossary states the convention, it does not redefine the tiers).
- **Consumers:** All release-process documentation, persona cards in `release-personas.md`.

### term: Persona {#term-persona}

- **Definition:** A set of behavioral markers, anti-patterns, and professional identity instructions embedded in a spoke prompt to shape agent behavior for a specific stage.
- **Real-world PMO equivalent:** Principal-grade job specification — e.g., "Principal Software Engineer: evaluates trade-offs, challenges assumptions, documents ADRs."
- **Platform equivalent:** Cards in `release/references/specs/release-personas.md` embedded into Spoke Template prompts by the hub.
- **Authoritative file:** `release/references/specs/release-personas.md`.
- **Consumers:** `hub-spoke-bridge.md` Procedure 3, all stage-specific spoke prompts.

**Distinguishing the three:** Function is *what a category of work is* (Planning); Role is *who performs it* (Operator + Hub + Spoke); Persona is *how they perform it with stylistic/behavioral detail* (Principal Engineer card).

### term: Hub {#term-hub}

- **Definition:** The single orchestrating Claude session that holds the full release context, dependency graph, and operator-authorization scope, and drives a release through the pipeline by spawning Spokes. The Hub is the only agent that launches other agents; it never performs a stage's isolated work itself.
- **Real-world PMO equivalent:** Program Manager / orchestration lead — owns the plan and the cross-workstream picture, delegates execution, and reconciles results into decisions.
- **Platform equivalent:** The hub session in the hub-and-spoke release bridge. Acts across **Autonomy Tier 1–3** (drafts Decision Briefings at Tier 1; executes routing/scaffolding under standing plan authorization at Tier 3) per `core/specs/autonomy-tiers.md`.
- **Authoritative file:** `release/references/how-to/hub-spoke-bridge.md` § For the Hub Agent.
- **Consumers:** All release-orchestration documentation; `release-personas.md`; every Spoke (which reports back to the Hub).

### term: Spoke {#term-spoke}

- **Definition:** A spawned, worktree-isolated Claude session that performs one pipeline stage's work for one issue and reports its result back to the Hub. A Spoke does isolated work only; it never launches a downstream Spoke (no Agent-tool or spawn_task invocation for the next stage).
- **Real-world PMO equivalent:** A specialist contributor assigned a single work package — does the work, hands back the deliverable, does not re-assign downstream work.
- **Platform equivalent:** A stage spoke launched by the Hub via the `Agent({subagent_type,…})` Task tool (see [Sub-agent](#term-sub-agent) for the component it is instantiated as). Embodies a stage [Persona](#term-persona). Acts across **Autonomy Tier 1–3** per the stage's authorization (per `core/specs/autonomy-tiers.md`).
- **Authoritative file:** `release/references/how-to/hub-spoke-bridge.md` § Spoke Template / § Spoke Launch Mechanisms.
- **Consumers:** All stage sub-task templates; `release-personas.md`; the Hub's Procedure 2 routing.

### term: Skill {#term-skill}

- **Definition:** A packaged, deployable unit of Claude Code behavior — a `SKILL.md` definition plus its `references/` support files, distributed as a `.skill` package — that the platform invokes to perform a capability. Each deployed Skill is one Configuration Item (CI) row in the skill catalog.
- **Real-world PMO equivalent:** A documented capability / standard operating procedure the organization can deploy repeatably across engagements.
- **Platform equivalent:** A skill under `{operations,release,core}/skills/<name>/`, deployed by `deploy.sh`, catalogued in the skill registry. Structural model (the three components — SKILL.md / references / package) is described in `core/disciplines/architecture-overview.md` § Skill Architecture.
- **Authoritative file:** `core/skills/registry.md` (the single skill catalog / CMDB, per ADR-038).
- **Consumers:** `pmo-skill-router` (routing view of the registry); `deploy.sh`; all skill-authoring + skill-editing documentation.

### term: Sub-agent {#term-sub-agent}

- **Definition:** The Claude Code component a Spoke is instantiated as — an agent definition file under `.claude/agents/<name>.md`, invoked through the `Agent({subagent_type,…})` Task tool. "Sub-agent" is the build-surface / mechanism term; "[Spoke](#term-spoke)" is the orchestration-role the sub-agent fills during a release. They are not synonyms: a Spoke is a role played by a sub-agent invocation; a sub-agent is the component definition that makes the invocation possible.
- **Real-world PMO equivalent:** A staffing template / role definition — the reusable job spec that an assigned contributor (the Spoke) is hired against for a specific engagement.
- **Platform equivalent:** An agent definition at `.claude/agents/<subagent_type>.md` (e.g., `pmo-adversarial`), resolved by the Hub's `Agent({…})` launch with an explicit `model:` per the definition's frontmatter.
- **Authoritative file:** `release/references/how-to/hub-spoke-bridge.md` § Spoke Launch Mechanisms (the `.claude/agents/<subagent_type>.md` definition surface).
- **Consumers:** The Hub (launch mechanism); `release-personas.md` (persona ↔ subagent_type mapping); Stage 5 adversarial-review pairing.

**Distinguishing the actor terms:** [Hub](#term-hub) and [Spoke](#term-spoke) are orchestration **roles** (who acts in a release — the Hub orchestrates, the Spoke executes one stage); [Sub-agent](#term-sub-agent) is the **component** a Spoke is instantiated as (the `.claude/agents/` definition + Task-tool invocation); [Skill](#term-skill) is a **deployable capability unit** (a packaged SKILL.md the platform invokes). A Spoke is launched as a Sub-agent and may invoke Skills.

---

## Category 3 — Process / Methodology / Framework

> **This category is load-bearing.** The three terms are distinct abstraction levels. PROJECT.md's `delivery_approach` enum parameterizes Methodology; `methodology-parameterization-v1.md` reference doc operates at the Framework layer (methodology-domain scope); `execution-framework.md` also operates at the Framework layer (execution-domain scope). Same layer, different scope. See Collective Review for the scope-lock rationale.

### term: Process {#term-process}

- **Definition:** A governed sequence of stages that transforms inputs into outputs end-to-end — stable over time, independent of the delivery methodology used inside any single stage.
- **Real-world PMO equivalent:** PMBOK "Process" = a defined activity with inputs/tools-and-techniques/outputs. At the macro level, a delivery lifecycle (initiation → closure) is a process; at the micro level, each governance step (risk review, change control) is also a process.
- **Platform equivalent:** The 13-stage pipeline (Intake → Triage → Bundle → Planning → … → Close) is the platform's canonical delivery Process. Sub-processes: triage protocol, gate evaluation protocol.
- **Authoritative file:** `release/references/pipeline/` (13-stage pipeline) + `.claude/rules/release-process.md` (concise operating model).
- **Consumers:** All release-operation documentation, all stage sub-task templates, all pipeline-aware skills.

**Distinguishing mark:** Process is **WHAT sequence of stages we run**, regardless of methodology. A release moves through the same 13 stages under Scrum or Waterfall.

### term: Methodology {#term-methodology}

- **Definition:** A named delivery approach that parameterizes how work is decomposed, sequenced, and time-boxed within a given Process — e.g., Scrum, Kanban, Waterfall, SAFe, PRINCE2, XP, Hybrid, Custom.
- **Real-world PMO equivalent:** PMI / PMBOK "Delivery Approach" (Predictive / Agile / Hybrid) or PRINCE2 / SAFe / Scrum framework names. Collectively: the named family of practices + ceremonies + artifacts a project commits to.
- **Platform equivalent:** PROJECT.md `delivery_approach` enum (8 values: Scrum / Kanban / XP / Waterfall / PRINCE2 / SAFe / Hybrid / Custom) + optional `custom_methodology_definition` typed block when Custom. Defined in `methodology-parameterization-v1.md`.
- **Authoritative file:** `release/references/specs/methodology-parameterization-v1.md` (methodology deliverable) + `core/schemas/project-schema.md` (schema deliverable, enum validation) + `release/references/specs/methodology-archetype-matrix.md` (variation table).
- **Consumers:** All methodology-aware skills (delivery-engine sprint modes, project-initiator, ppm-agent), OPERATIONS.md § Methodology Awareness Protocol, downstream methodology variation tables in 10 files.

**Distinguishing mark:** Methodology is **WHICH named delivery approach a project chooses**. Different projects using the same Process can choose different Methodologies.

### term: Framework {#term-framework}

- **Definition:** A tool-agnostic, domain-agnostic pattern set that governs HOW execution happens across multiple methodologies — structural scaffolding consumed by execution tools.
- **Real-world PMO equivalent:** PMBOK Chapter-level construct — the universal PM knowledge areas (Scope, Schedule, Cost, Quality, Risk, etc.) and process groups ARE a framework that applies regardless of methodology. A framework provides the reusable skeleton; methodologies instantiate it.
- **Platform equivalent:** `core/disciplines/execution-framework.md` ( deliverable — work breakdown / assignment / tracking / handoff / state-persistence dimensions); also: `hub-spoke-bridge.md` is an execution tool that *implements* framework patterns. Frameworks are consumed by tools; tools are specific instantiations.
- **Authoritative file:** `core/disciplines/execution-framework.md`.
- **Consumers:** `hub-spoke-bridge.md` (tool implementing framework patterns), all skills performing work management (delivery-engine, release-executor, tracker-manager), future multi-agent orchestration skills.

**Distinguishing mark:** Framework is **HOW patterns unify execution** across methodologies and tools. A framework is consumed by tools; it does NOT dictate a specific Methodology. This is the level of abstraction that `execution-framework.md` lives at.

### Summary of the three-way distinction

| Term | Abstraction Q | Example | Layer |
|---|---|---|---|
| **Process** | WHAT sequence of stages? | "Our release process has 13 stages: Intake → Triage → … → Close" | Governance |
| **Methodology** | WHICH delivery approach? | "This project uses Scrum with 2-week sprints" | Parameterization |
| **Framework** | HOW do patterns unify across tools/methodologies? | "The execution framework defines work-breakdown patterns any tool can implement" | Structural |

---

## Category 4 — Stage / Phase / Step

### term: Stage {#term-stage}

- **Definition:** A numbered top-level division of the 13-stage pipeline Process (e.g., Stage 5 Solutioning).
- **Real-world PMO equivalent:** PMBOK Process Group / PRINCE2 Stage — a named phase of the lifecycle with entry + exit gates and defined deliverables.
- **Platform equivalent:** Stages 1-13 in `pipeline/`; each has a GitHub Project `Stage` field value, a sub-task per issue, a persona card, and a transition gate.
- **Authoritative file:** `release/references/pipeline/`.
- **Consumers:** `hub-spoke-bridge.md`, `release-personas.md`, all sub-task templates, `core/schemas/stage-io-contracts.md`.

### term: Phase {#term-phase}

- **Definition:** A sub-division of a single Stage's execution — typically used in multi-phase stage processes (e.g., Stage 2 Phase A Agent / Phase B Human, Stage 7 Phase A/B/C DT-QA lanes).
- **Real-world PMO equivalent:** PMBOK "Phase" sometimes overloaded with Stage; at the sub-stage level, corresponds to Activity Groups within a Work Package.
- **Platform equivalent:** Phase A / Phase B labels inside Stage 2, 3, 4, 5, 7 Process sections of `pipeline/`.
- **Authoritative file:** `release/references/pipeline/` per-stage `## 5. Process` subsection.
- **Consumers:** Stage-internal processing documentation, skill-mode definitions that align to stage phases.

### term: Step {#term-step}

- **Definition:** A single numbered operational action inside a Phase (e.g., A1, B3) OR a numbered instruction inside a Procedure or workflow.
- **Real-world PMO equivalent:** Task-level activity (lowest meaningful unit of agent/operator work).
- **Platform equivalent:** A1/A2/A3… B1/B2/B3 numbering inside stage Process sections; numbered Steps 1-7 inside `implementation-execution-pattern.md`; numbered Steps in `hub-spoke-bridge.md` Procedures.
- **Authoritative file:** Per-document — the doc enumerating the steps is the authority.
- **Consumers:** All procedural documentation, all skill operational sections.

**Distinguishing the three:** Stage is the top-level pipeline division (13 of them); Phase is a sub-division WITHIN one stage; Step is the operational unit WITHIN a phase or procedure. They nest: Stage > Phase > Step.

---

## Category 5 — Work Breakdown Terms

### term: Work Item {#term-work-item}

- **Definition:** The generic, methodology-agnostic name for any unit of work tracked by the platform.
- **Real-world PMO equivalent:** PMBOK "Deliverable" or SAFe "Work Item" (capability/feature/story/enabler generic wrapper).
- **Platform equivalent:** GitHub Issue — the universal Work Item type. May or may not be an Improvement (labeled `improvement`), an ADR (labeled `adr`), or a sub-task (labeled `sub-task`).
- **Authoritative file:** `release/references/specs/ticket-information-architecture.md`.
- **Consumers:** All backlog-management documentation, triage skills, release planner.

### term: Task {#term-task}

- **Definition:** A Work Item whose scope is entirely subsumed by a single Stage of pipeline execution for a single parent Issue (e.g., "Stage 5 Solutioning for ").
- **Real-world PMO equivalent:** PMBOK "Work Package" at the leaf of WBS — the unit assigned to a single performer.
- **Platform equivalent:** A sub-task GitHub Issue labeled `sub-task` with a parent Issue reference. Typically one per stage per parent issue (scaffolded by `hub-spoke-bridge.md` Procedure 1).
- **Authoritative file:** `release/references/how-to/hub-spoke-bridge.md` § Sub-Task Template.
- **Consumers:** Hub scaffolding, all spoke prompts, tracking config.

### term: Sub-task {#term-sub-task}

- **Definition:** Synonym for Task when viewed from the parent Issue's perspective; the hyphenated "sub-task" is the **canonical label name** on GitHub Issues performing this role.
- **Real-world PMO equivalent:** Same as Task — "sub-task" in MS Project WBS is one level below a summary task.
- **Platform equivalent:** GitHub label `sub-task` applied to per-stage-per-issue tracking artifacts.
- **Authoritative file:** `core/specs/label-taxonomy.md` (consumer) + `hub-spoke-bridge.md` (producer).
- **Consumers:** All scaffolding skills, all stage closure criteria.

### term: Deliverable {#term-deliverable}

- **Definition:** A specific output artifact produced by a Stage that can be named, located, and verified (e.g., "release plan file," "ADR issue," "PR").
- **Real-world PMO equivalent:** PMBOK "Deliverable" (verifiable output of a project, phase, or process).
- **Platform equivalent:** Named in each Stage's `## 6. Outputs` section of `pipeline/`. Examples: release plan file, ADR issue with `adr` label, PR with full metadata.
- **Authoritative file:** `release/references/pipeline/` per-stage Outputs section.
- **Consumers:** Gate criteria (checks for deliverable presence), QA checkpoints (verify deliverable content), downstream stages (consume deliverable as input).

**Distinguishing the four:** Work Item is the generic wrapper; Task/Sub-task are tracking-artifact names for a stage-scoped Work Item; Deliverable is the verifiable output produced BY executing a Task.

---

## Category 6 — Scope / Time Boxes

### term: Sprint {#term-sprint}

- **Definition:** A time-boxed iteration of work (typically 1-4 weeks) used by Agile methodologies (Scrum, SAFe) to deliver a potentially shippable increment.
- **Real-world PMO equivalent:** Scrum Sprint / SAFe Iteration / XP Iteration — a fixed-length time box ending with a Sprint Review.
- **Platform equivalent:** Methodology-specific. Not a universal platform concept — **only applies when `delivery_approach` is Scrum, XP, SAFe, or Custom-with-sprints**. Platform pipeline is methodology-agnostic; sprints are a Methodology artifact. Consumed by delivery-engine skill sprint modes.
- **Authoritative file:** `release/references/specs/methodology-parameterization-v1.md` Scrum + XP + SAFe sections ( deliverable).
- **Consumers:** delivery-engine, project-initiator, ppm-agent (when methodology is sprint-using).

### term: Milestone {#term-milestone}

- **Definition:** A scope-boxed grouping of Work Items that ship together as a single release; identified by a version number (e.g., `v1.2`) and tracked as a GitHub Milestone.
- **Real-world PMO equivalent:** PMBOK "Milestone" (significant point or event) generalized to "scope boundary" — a checkpoint that gathers multiple deliverables and marks a release boundary.
- **Platform equivalent:** GitHub Milestones labeled `vX.Y-description`; every release Issue is assigned a Milestone at Stage 3 Bundle.
- **Authoritative file:** `.claude/rules/release-process.md` + `core/disciplines/github-projects-guide.md`.
- **Consumers:** Release-process stages 3/4/9/12/13, release-planner skill, RELEASE_LOG.md.

### term: Release {#term-release}

- **Definition:** A deployment-boxed event that ships a set of Work Items to production — the act of merging the release branch to `main`, tagging, and deploying.
- **Real-world PMO equivalent:** PMBOK "Deployment" event / SAFe "Release" (release of value, often PI-ending).
- **Platform equivalent:** Git tag `vX.Y`, the merged PR, the `release/releases/plans/vX.Y_RELEASE_PLAN.md` file, the RELEASE_LOG.md entry. 1 Milestone = 1 Release per current convention.
- **Authoritative file:** `.claude/rules/release-process.md` § Lifecycle.
- **Consumers:** Stage 12 Execute, Stage 13 Close, `deploy.sh`, RELEASE_LOG.md.

**Distinguishing the three:** Sprint is **TIME-BOXED** (methodology-specific); Milestone is **SCOPE-BOXED** (platform-universal); Release is **DEPLOYMENT-BOXED** (the ship event). In the platform's current convention, 1 Milestone = 1 Release; sprints apply only when Methodology declares them.

### term: Initiative {#term-initiative}

- **Definition:** A multi-milestone grouping theme; not a hierarchy level — a cross-milestone grouping label (`epic:*` / `project:*`), never a container tier or `parent_ref` target. It ties related Work Items, their umbrella Issue, and an optional roadmap together.
- **Real-world PMO equivalent:** Program-level initiative / strategic theme — a body of related projects pursued toward one capability outcome (loosely a PMI "program" theme), but expressed in this platform as a grouping label, not an org tier.
- **Platform equivalent:** A grouping label in the `epic:*` or `project:*` namespace (`label-taxonomy.md` § Initiative Labels) binding an umbrella Issue + child Issues + an optional operator-local roadmap. The work-item hierarchy itself is methodology-invariant (Portfolio → Program → Project → Milestone/Workstream → Work Item) and Initiative is NOT one of its levels.
- **Authoritative file:** `core/disciplines/work-organization-mapping-framework.md` (hierarchy SSOT) + `core/specs/label-taxonomy.md` § Initiative Labels (grouping-label mechanism). Decision record: ADR-049.
- **Consumers:** `core/standards/initiative-roadmap-framework.md`, `core/specs/label-taxonomy.md`, `release-planner` / Stage 3 Bundle (grouping-label scoping).

### term: Roadmap {#term-roadmap}

- **Definition:** An architected path across milestones; may span one or more initiatives — one-per-initiative is the default, not a definitional limit. Program-altitude, Living.
- **Real-world PMO equivalent:** Program roadmap / strategic roadmap — the sequence-anchored "what we are delivering across these milestones" view, distinct from a Gantt schedule (which is implementation-anchored).
- **Platform equivalent:** A Living artifact at the operator-local roadmaps path (default `/roadmaps/`, per ADR-046; instances git-ignored). Its § 3 Now/Next/Later sequences the contributing Issues (scoped by the initiative's grouping label) into the architected path-to-done.
- **Authoritative file:** `core/standards/initiative-roadmap-framework.md` (roadmap convention). Decision record: ADR-049.
- **Consumers:** `initiative-roadmap-framework.md`, `release-planner`, Stage 3 Bundle / Stage 5 Collective Review cohesion-check (convention only — in-repo enforcement retired per ADR-012).

---

## Appendix A — Conflicting-Usage Register

Terms the platform historically used for two distinct concepts — this glossary resolves each by assigning one canonical meaning and directing the other usage to a different term.

| Ambiguous usage | Historical collision | Canonical split |
|---|---|---|
| "Planning" | Meant both release-level (Stage 4 Planning) and issue-level (breaking one issue into work chunks) | Release-level = **Stage 4 Planning** (produces the release plan file). Issue-level = **Work Breakdown Decomposition** (happens during Stage 6 Engineering, produces Deliverables and Steps, NOT named "Planning"). |
| "Sub-task" | Meant both the tracking artifact (GitHub sub-task Issue) AND the unit produced by engineer work-breakdown decomposition | **Sub-task = tracking artifact only** (one GitHub Issue per stage per parent, labeled `sub-task`). Work-breakdown decomposition chunks are **Deliverables** or **Steps**, not Sub-tasks. |
| "Framework" | Used loosely to mean both "delivery approach" (e.g., "the Scrum framework") and "tool-agnostic pattern set" | **Framework = tool-agnostic pattern set** (this glossary Category 3). Delivery approaches (Scrum / Kanban / Waterfall / etc.) are **Methodologies**, not Frameworks. |
| "Process" | Used both for the 13-stage pipeline AND for any governed sequence (e.g., "triage process," "review process") | **Process** refers to the 13-stage pipeline as the canonical delivery Process. Smaller governed sequences are **sub-processes** (lowercase), named by their function (triage protocol, gate evaluation protocol). |
| "Stage" vs. "Phase" | Occasionally conflated in PMBOK-style references | **Stage = top-level pipeline division** (13 of them, numbered 1-13). **Phase = sub-division within a single Stage**. Nest as Stage > Phase > Step. |
| "agent" | Used for (i) a [Role](#term-role) in orchestration ("the Hub agent"), (ii) any generic autonomous actor ("an agent reading the corpus"), and (iii) a future-workforce identity ("agents cover BA/PO/Eng roles") | **(i) Role sense → name the specific role:** [Hub](#term-hub) / [Spoke](#term-spoke) / Operator, not bare "agent". **(ii) Generic-actor sense → "autonomous agent" / "reader"** is acceptable as gloss when no specific role is meant (e.g., "an autonomous agent reading the corpus cold"). **(iii) Future workforce-identity sense → out of scope of this glossary** — when the agent-workforce model is canonicalized it gets its own term; until then do NOT overload "agent" to mean a persistent workforce identity. The deployable-capability unit is a [Skill](#term-skill); the component an actor is instantiated as is a [Sub-agent](#term-sub-agent). |

## Appendix B — Non-Canonical Synonyms

Terms NOT used in the platform (with reason) and the canonical term that replaces each.

| Non-canonical term | Reason not used | Canonical replacement |
|---|---|---|
| Epic | SAFe/Jira terminology; adds taxonomy level without platform use | Milestone + Issue (large Issues may span multiple sub-tasks) |
| Story | Agile/Scrum convention; not methodology-agnostic | Work Item (`improvement` label when applicable) |
| Feature | Overloaded with product-management usage | Work Item labeled `improvement` with Category `Feature` |
| User Story | Agile convention; not methodology-agnostic | Work Item with Acceptance Criteria in body |
| Ticket | Support/IT context; pmo-platform uses GitHub Issues | Work Item / Issue |
| Work Package | PMBOK convention; Work Item + Task cover the same scope | Work Item (issue level) + Task (stage-scoped sub-task) |
| Iteration | Methodology-specific (Agile); not universal | Sprint (when methodology uses time-boxes) |
| Delivery | Overloaded — sometimes means Release, sometimes means artifact | Release (deployment event) or Deliverable (artifact) — per context |
| Initiative | Previously treated as a non-canonical / unmodeled concept; now a canonical term (cross-milestone grouping theme, not a hierarchy level) per ADR-049. | Canonical — see [term: Initiative](#term-initiative). |

---

## Cross-cutting glossary properties

- **Anchor convention:** Every term uses `{#term-<slug>}` where `<slug>` is the lowercase-kebab-case of the Name. E.g., `{#term-work-item}`, `{#term-sub-task}`. Stable across re-orderings (anchor not tied to document position).
- **Consumer discipline:** When any consumer file references a glossary term, it SHOULD link `[term](terminology-glossary.md#term-<slug>)` on first use per document. This is a SHOULD (not MUST) — enforcement is via Collective Review + author discipline, not gate-enforced.
- **Authoritative-file delegation:** Glossary entries name the authoritative file but do NOT duplicate its schema. If the authoritative file changes a definition, the glossary is updated in the same commit (cross-reference integrity check QC3-03).
- **Adding new terms:** New terms added to this glossary require a Collective Review pass or an ADR Issue — this is a governance file and falls under "No ungoverned changes."

**Total terms:** **25 terms** across the six categories (Area/Domain, Function/Role/Persona, Process/Methodology/Framework, Stage/Phase/Step, Work Breakdown, Scope/Time boxes) — the per-category counts vary (some categories carry more than four terms: Category 2 also holds the four first-class actor terms Hub/Spoke/Skill/Sub-agent, and Category 6 also holds the grouping terms Initiative/Roadmap). Authoritative count = `grep -cE '^### term:.*\{#term-' core/specs/terminology-glossary.md` (heading-scoped — prose mentions of `{#term-…}` in this file are not term entries and are correctly excluded).

## See Also

- [execution-framework.md](../disciplines/execution-framework.md) — consumes glossary; names Framework as its layer
- `release/references/pipeline/` — consumes Stage / Phase / Step / Deliverable
- [hub-spoke-bridge.md](../../release/references/how-to/hub-spoke-bridge.md) — consumes Task / Sub-task / Role / Persona
- [methodology-parameterization-v1.md](../../release/references/specs/methodology-parameterization-v1.md) — consumes Methodology; owns `delivery_approach` enum
- [release-personas.md](../../release/references/specs/release-personas.md) — owns Persona content
- [ticket-information-architecture.md](../../release/references/specs/ticket-information-architecture.md) — owns Work Item semantics
- [label-taxonomy.md](label-taxonomy.md) — consumes Sub-task label name
