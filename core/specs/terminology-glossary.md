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
- **Authoritative file:** `pmo-platform/reference/explanation/five-function-spine-and-process-flows.md`
- **Consumers:** Skill personas (pmo-process-designer, ppm-agent), Stage 5 Solutioning design specs, future methodology-aware skill authoring.

### term: Role {#term-role}

- **Definition:** A named set of responsibilities an agent or human assumes during a specific activity (e.g., "Hub Agent," "Spoke Agent," "Operator").
- **Real-world PMO equivalent:** RACI role (Responsible, Accountable, Consulted, Informed) or organizational role title (e.g., "Sponsor," "Project Manager," "Business Analyst").
- **Platform equivalent:** Operator (the human user), Hub Agent (orchestrating Claude session), Spoke Agent (spawned Claude session). Future: agent roles in multi-agent orchestration.
- **Authoritative file:** `release/references/how-to/hub-spoke-bridge.md` § For the Operator / For the Hub Agent / Spoke Template.
- **Consumers:** All release-process documentation, persona cards in `release-personas.md`.

### term: Persona {#term-persona}

- **Definition:** A set of behavioral markers, anti-patterns, and professional identity instructions embedded in a spoke prompt to shape agent behavior for a specific stage.
- **Real-world PMO equivalent:** Principal-grade job specification — e.g., "Principal Software Engineer: evaluates trade-offs, challenges assumptions, documents ADRs."
- **Platform equivalent:** Cards in `release/references/specs/release-personas.md` embedded into Spoke Template prompts by the hub.
- **Authoritative file:** `release/references/specs/release-personas.md`.
- **Consumers:** `hub-spoke-bridge.md` Procedure 3, all stage-specific spoke prompts.

**Distinguishing the three:** Function is *what a category of work is* (Planning); Role is *who performs it* (Operator + Hub + Spoke); Persona is *how they perform it with stylistic/behavioral detail* (Principal Engineer card).

---

## Category 3 — Process / Methodology / Framework

> **This category is load-bearing.** The three terms are distinct abstraction levels. PROJECT.md's `delivery_approach` enum parameterizes Methodology; `methodology-parameterization-v1.md` reference doc operates at the Framework layer (methodology-domain scope); `execution-framework.md` also operates at the Framework layer (execution-domain scope). Same layer, different scope. See Collective Review for the scope-lock rationale.

### term: Process {#term-process}

- **Definition:** A governed sequence of stages that transforms inputs into outputs end-to-end — stable over time, independent of the delivery methodology used inside any single stage.
- **Real-world PMO equivalent:** PMBOK "Process" = a defined activity with inputs/tools-and-techniques/outputs. At the macro level, a delivery lifecycle (initiation → closure) is a process; at the micro level, each governance step (risk review, change control) is also a process.
- **Platform equivalent:** The 13-stage pipeline (Intake → Triage → Bundle → Planning → … → Close) is the platform's canonical delivery Process. Sub-processes: triage protocol, gate evaluation protocol.
- **Authoritative file:** `pmo-platform/reference/pipeline/` (13-stage pipeline) + `.claude/rules/release-process.md` (concise operating model).
- **Consumers:** All release-operation documentation, all stage sub-task templates, all pipeline-aware skills.

**Distinguishing mark:** Process is **WHAT sequence of stages we run**, regardless of methodology. A release moves through the same 13 stages under Scrum or Waterfall.

### term: Methodology {#term-methodology}

- **Definition:** A named delivery approach that parameterizes how work is decomposed, sequenced, and time-boxed within a given Process — e.g., Scrum, Kanban, Waterfall, SAFe, PRINCE2, XP, Hybrid, Custom.
- **Real-world PMO equivalent:** PMI / PMBOK "Delivery Approach" (Predictive / Agile / Hybrid) or PRINCE2 / SAFe / Scrum framework names. Collectively: the named family of practices + ceremonies + artifacts a project commits to.
- **Platform equivalent:** PROJECT.md `delivery_approach` enum (8 values: Scrum / Kanban / XP / Waterfall / PRINCE2 / SAFe / Hybrid / Custom) + optional `custom_methodology_definition` typed block when Custom. Defined in `methodology-parameterization-v1.md`.
- **Authoritative file:** `release/references/specs/methodology-parameterization-v1.md` (methodology deliverable) + `pmo-platform/reference/schemas/project-schema.md` (schema deliverable, enum validation) + `pmo-platform/reference/specs/methodology-archetype-matrix.md` (variation table).
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
- **Authoritative file:** `pmo-platform/reference/pipeline/`.
- **Consumers:** `hub-spoke-bridge.md`, `release-personas.md`, all sub-task templates, `reference/schemas/stage-io-contracts.md`.

### term: Phase {#term-phase}

- **Definition:** A sub-division of a single Stage's execution — typically used in multi-phase stage processes (e.g., Stage 2 Phase A Agent / Phase B Human, Stage 7 Phase A/B/C DT-QA lanes).
- **Real-world PMO equivalent:** PMBOK "Phase" sometimes overloaded with Stage; at the sub-stage level, corresponds to Activity Groups within a Work Package.
- **Platform equivalent:** Phase A / Phase B labels inside Stage 2, 3, 4, 5, 7 Process sections of `pipeline/`.
- **Authoritative file:** `pmo-platform/reference/pipeline/` per-stage `## 5. Process` subsection.
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
- **Authoritative file:** `pmo-platform/reference/pipeline/` per-stage Outputs section.
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
- **Authoritative file:** `.claude/rules/release-process.md` + `pmo-platform/reference/how-to/github-projects-guide.md`.
- **Consumers:** Release-process stages 3/4/9/12/13, release-planner skill, RELEASE_LOG.md.

### term: Release {#term-release}

- **Definition:** A deployment-boxed event that ships a set of Work Items to production — the act of merging the release branch to `main`, tagging, and deploying.
- **Real-world PMO equivalent:** PMBOK "Deployment" event / SAFe "Release" (release of value, often PI-ending).
- **Platform equivalent:** Git tag `vX.Y`, the merged PR, the `pmo-platform/releases/plans/vX.Y_RELEASE_PLAN.md` file, the RELEASE_LOG.md entry. 1 Milestone = 1 Release per current convention.
- **Authoritative file:** `.claude/rules/release-process.md` § Lifecycle.
- **Consumers:** Stage 12 Execute, Stage 13 Close, `deploy.sh`, RELEASE_LOG.md.

**Distinguishing the three:** Sprint is **TIME-BOXED** (methodology-specific); Milestone is **SCOPE-BOXED** (platform-universal); Release is **DEPLOYMENT-BOXED** (the ship event). In the platform's current convention, 1 Milestone = 1 Release; sprints apply only when Methodology declares them.

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
| Initiative | Portfolio-level concept not modeled at platform layer | Milestone (ships together) or cross-Milestone roadmap theme |

---

## Cross-cutting glossary properties

- **Anchor convention:** Every term uses `{#term-<slug>}` where `<slug>` is the lowercase-kebab-case of the Name. E.g., `{#term-work-item}`, `{#term-sub-task}`. Stable across re-orderings (anchor not tied to document position).
- **Consumer discipline:** When any consumer file references a glossary term, it SHOULD link `[term](terminology-glossary.md#term-<slug>)` on first use per document. This is a SHOULD (not MUST) — enforcement is via Collective Review + author discipline, not gate-enforced.
- **Authoritative-file delegation:** Glossary entries name the authoritative file but do NOT duplicate its schema. If the authoritative file changes a definition, the glossary is updated in the same commit (cross-reference integrity check QC3-03).
- **Adding new terms:** New terms added to this glossary require a Collective Review pass or an ADR Issue — this is a governance file and falls under "No ungoverned changes."

**Total terms:** 6 categories × 3-4 terms = **19 terms** (19 `{#term-<slug>}` anchors).

## See Also

- [execution-framework.md](../disciplines/execution-framework.md) — consumes glossary; names Framework as its layer
- `pmo-platform/reference/pipeline/` — consumes Stage / Phase / Step / Deliverable
- [hub-spoke-bridge.md](../../release/references/how-to/hub-spoke-bridge.md) — consumes Task / Sub-task / Role / Persona
- [methodology-parameterization-v1.md](../../release/references/specs/methodology-parameterization-v1.md) — consumes Methodology; owns `delivery_approach` enum
- [release-personas.md](../../release/references/specs/release-personas.md) — owns Persona content
- [ticket-information-architecture.md](../../release/references/specs/ticket-information-architecture.md) — owns Work Item semantics
- [label-taxonomy.md](label-taxonomy.md) — consumes Sub-task label name
