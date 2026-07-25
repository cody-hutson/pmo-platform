---
title: Execution Framework
purpose: The tool-agnostic, methodology-agnostic pattern set governing HOW work executes — work breakdown, assignment, tracking, handoffs, and state persistence — across any delivery methodology.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Execution Framework

## Purpose

The Execution Framework is a **tool-agnostic, domain-agnostic pattern set** that governs HOW work gets executed — work breakdown, assignment, tracking, handoffs, and state persistence — across any delivery [Methodology](../specs/terminology-glossary.md#term-methodology) (Scrum / Kanban / Waterfall / SAFe / PRINCE2 / XP / Hybrid / Custom) and any work [Area](../specs/terminology-glossary.md#term-area) (engineering releases in `pmo-platform/`, operational PMO delivery in `projects/`, future work areas).

It sits between the **[Process](../specs/terminology-glossary.md#term-process) layer** (13-stage pipeline in `pipeline/`) and the **Tool layer** (specific implementations like `hub-spoke-bridge.md` and PMO skills). A single Process ships under many methodologies; many tools implement the framework's patterns; the framework provides the stable vocabulary and dimensional scaffolding that keeps them coherent.

**Distinguishing claim:** This doc is at the [Framework](../specs/terminology-glossary.md#term-framework) layer per the glossary's Process/Methodology/Framework distinction (Category 3). It does NOT define delivery approaches (that's `methodology-parameterization-v1.md`); it does NOT mandate specific tools (`hub-spoke-bridge.md` is one implementation); it does NOT duplicate the Process stage definitions (those live in `pipeline/`). When consumer files implement framework patterns, they cite this doc and name the dimensions they touch — they do NOT redefine dimension semantics.

---

## Relationship to Other Docs (Governance Hierarchy Placement)

**Hierarchy diagram:**

```
┌──────────────────────────────────────────────────────────────────────┐
│ CLAUDE.md                                                            │
│  (Workspace-global universal rules)                                  │
└────────────────────────┬─────────────────────────────────────────────┘
                         │ defines boundaries
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Governance Layer                                                     │
│  OPERATIONS.md · release-process.md + mirror · RELEASE_PROTOCOL.md   │
└────────────────────────┬─────────────────────────────────────────────┘
                         │ governs sequence
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Process Layer                                                        │
│  pipeline/ (13-stage pipeline)                                       │
└─────────┬──────────────┬─────────────────┬───────────────────────────┘
          │              │                 │
          ▼              ▼                 ▼
┌─────────────────┐ ┌─────────────┐ ┌────────────────────────────────┐
│ Methodology     │ │ FRAMEWORK   │ │ Framework ↔ Methodology        │
│ Layer           │ │ Layer       │ │ composition hook               │
│                 │ │             │ │                                │
│ methodology-    │ │ execution-  │ │ methodology-archetype-         │
│ parameter-      │ │ framework   │ │ matrix.md (variation tables)   │
│ ization-v1.md   │ │ .md         │ │                                │
│                 │ │             │ │                                │
│                 │ │ THIS FILE   │ │                                │
└─────────────────┘ └─────────┬───┘ └────────────────────────────────┘
                              │ implemented by
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Tool Layer (Execution Tools)                                         │
│  hub-spoke-bridge.md · implementation-execution-pattern.md ·         │
│  skills (delivery-engine, release-executor, tracker-manager, etc.)   │
└──────────────────────────────────────────────────────────────────────┘
```

**Relationship table:**

| Doc | Layer | Owns | Does NOT Own |
|---|---|---|---|
| `CLAUDE.md` | Workspace-global | Universal rules, routing, quality standards | Stage specs, framework dimensions, tools |
| `release/governance/release-process.md` + mirror | Governance | Concise operating model, lifecycle, stage-gate protocol | Detailed stage content (→ pipeline/), framework patterns (→ this file) |
| `release/references/pipeline/` | Process | 13-stage pipeline, 10-point framework per stage, stage-level I/O | Methodology parameterization, execution-tool mechanics, framework dimensions |
| `release/references/specs/methodology-parameterization-v1.md` | Framework (methodology-domain scope) | `delivery_approach` archetypes + normative definitions | Execution-dimension patterns (→ this file) |
| **`../disciplines/execution-framework.md` (THIS FILE)** | Framework (execution-domain scope) | 5 execution dimensions, dual-domain applicability patterns | Process sequence, methodology definitions, specific tool implementations |
| `release/references/how-to/hub-spoke-bridge.md` | Tool | Specific hub-and-spoke execution pattern (one impl of framework) | Framework dimensions (consumes from this file) |
| `release/references/how-to/implementation-execution-pattern.md` | Tool | 7-step Read+Edit+Bash implementation-plan execution | Framework dimensions; consumes State-Persistence + Handoff dimensions from this file |

**Same-layer coexistence:** `methodology-parameterization-v1.md` and `execution-framework.md` both sit at the Framework layer with different scopes — methodology-domain and execution-domain respectively. Both are consumed by Tool-layer files; neither subsumes the other.

---

## Dimension 1 — Work Breakdown Patterns

**Canonical hierarchy:**

```
Release (Milestone; SCOPE-BOXED)
  └─ Work Item (Issue)
       └─ Task (Sub-task, stage-scoped, TRACKING-artifact)
            └─ Commit(s) (change-scoped)
```

Terminology from [glossary Category 5 + 6](../specs/terminology-glossary.md#category-5--work-breakdown-terms): [Work Item](../specs/terminology-glossary.md#term-work-item), [Task](../specs/terminology-glossary.md#term-task), [Sub-task](../specs/terminology-glossary.md#term-sub-task), [Milestone](../specs/terminology-glossary.md#term-milestone), [Release](../specs/terminology-glossary.md#term-release).

**Methodology Variation Hook:** Methodology determines whether a [Sprint](../specs/terminology-glossary.md#term-sprint) time-box wraps one or more Milestones.

| Methodology | Sprint/Milestone relationship |
|---|---|
| Scrum / XP | Sprint (time-boxed) contains one or more Milestone increments — Sprint Review gates Milestone closure |
| Kanban | No Sprint — Milestones flow continuously; WIP limits replace sprint capacity |
| Waterfall | No Sprint — Milestones align to phase-gates; one Milestone = one phase |
| SAFe | Program Increment (PI, ~10 weeks) contains multiple Sprints each containing Milestone slices |
| PRINCE2 | Management Stages align to Milestones; no Sprint concept |
| Hybrid | Caller-defined per `custom_methodology_definition.lifecycle` in PROJECT.md |
| Custom | Explicit in `custom_methodology_definition.lifecycle` + ceremonies |

Full variation matrix: [methodology-archetype-matrix.md](../../release/references/specs/methodology-archetype-matrix.md).

**Mandatory vs. optional tiers:**
- Release / Work Item / Task: **MANDATORY** across all methodologies and domains.
- Commit: **MANDATORY** for engineering domain; OPTIONAL for operations domain (some operational artifacts are not git-tracked per Layer 2 / Layer 3 classification).
- Sprint: **OPTIONAL** — declared by Methodology.

---

## Dimension 2 — Assignment Model

**Three-concept map** (per [glossary Category 2](../specs/terminology-glossary.md#category-2--function--role--persona)):

| Concept | Name-in-release | Source of Truth |
|---|---|---|
| **[Function](../specs/terminology-glossary.md#term-function)** | Initiating, Planning, Executing, Monitoring & Controlling, Closing | `five-function-spine-and-process-flows.md` |
| **[Role](../specs/terminology-glossary.md#term-role)** | Operator, Hub Agent, Spoke Agent, External Stakeholder | `hub-spoke-bridge.md`, `release-process.md` |
| **[Persona](../specs/terminology-glossary.md#term-persona)** | "Principal Engineer — Architecture Assessment" card content | `release-personas.md` |

**Assignment rule:**

A [Task](../specs/terminology-glossary.md#term-task) (sub-task GitHub Issue) is assigned to a Role (Spoke Agent) that embodies a Persona (from `release-personas.md`) for a [Stage](../specs/terminology-glossary.md#term-stage) which performs one or more Functions. The Role is durable across a session; the Persona is stage-specific; the Function describes the category of work.

**Example (Stage 5 Solutioning):**
- **Task:** Sub-task "Stage 5 Solutioning"
- **Role:** Spoke Agent (spawned Claude Code session)
- **Persona:** Principal Engineer — Architecture Assessment (release-personas.md Stage 5 card)
- **Function(s):** Planning (scope lock), Monitoring (blast radius)

**Methodology variation hook:** Assignment structure is stable across methodologies (Role + Persona are always applicable). Methodology determines ceremony cadence and which Personas fire at which natural events — captured in the Methodology layer's variation matrix, not here.

---

## Dimension 3 — Tracking Conventions

**Canonical tracking surface: GitHub.** Five tracking artifacts (exhaustive for the pipeline):

| Artifact | Role | Authority |
|---|---|---|
| GitHub Issue | Work Item (primary tracking unit) | `ticket-information-architecture.md` |
| GitHub Issue with `sub-task` label | Task (stage-scoped) | `hub-spoke-bridge.md` |
| GitHub Milestone | Release scope box | `github-projects-guide.md` |
| GitHub Projects (PMO Pipeline board) | Stage / Status / Decision-Date field anchors | `github-projects-guide.md` + `schemas/tracker-schemas.md` |
| GitHub Labels | Classification (priority, category, status, etc.) | `label-taxonomy.md` |

**State-anchor conflict resolution:** When labels / fields / milestone assignments drift, `ticket-information-architecture.md` conflict resolution rule applies (Fields are authoritative; labels are reflective). The framework REFERENCES this rule; does not redefine it.

**Operations-domain tracking:** The Operations domain (`projects/` — Layer 2) does NOT use GitHub for primary work-item tracking. Its canonical surface is operational trackers under `projects/<project>/04-PMO-Operations/` per `schemas/tracker-schemas.md`. The framework accommodates this by distinguishing tracking *surface* (GitHub vs. filesystem trackers) from tracking *artifacts* (the 5 canonical artifact types above are Engineering-domain; Operations maps to analogous file-based trackers).

**Methodology variation hook:** Methodology determines tracker field variations — fields vary per `delivery_approach` per `schemas/field-lifecycle-matrix.md` and `schemas/tracker-schemas.md` (both touched by Wave 2b).

---

## Dimension 4 — Handoff Protocols

**Two categories of handoff:**

1. **Inter-stage (upstream ↔ downstream within a release):** governed by [`release/governance/release-process.md` § Inter-Stage Feedback Protocol](../../release/governance/release-process.md) (Tier 1 Minor Adjustment / Tier 2 Scope Change / Tier 3 Plan Rejection). Framework REFERENCES; does not redefine.
2. **Cross-session (hub ↔ spoke ↔ operator):** governed by this framework. Patterns:
   - **Hub → Spoke:** Spoke prompt per `hub-spoke-bridge.md` Procedure 3 (Spoke Template). The hub pre-loads all state the spoke needs; the spoke has no session memory.
   - **Spoke → Hub (via operator):** Spoke closes its sub-task with a structured comment; operator returns to hub session; hub reads the sub-task comment.
   - **Hub → Operator (at gates):** Decision Briefing per `hub-spoke-bridge.md` Operating Principle.

**Contract for cross-session handoff:** The sub-task comment MUST contain the structured output format specified in its spoke template. Specifically: `Summary (30 seconds)` / `Detail` / `Evidence` / `Decisions & Recommendations` / `Output for Stage N+1`. Each section serves a distinct downstream consumer (operator = Summary; next-stage spoke = Output; auditor = Detail + Evidence).

**Methodology variation:** Handoff cadence varies by methodology — in Scrum, cross-session handoff aligns to Sprint boundaries; in Kanban, continuous; in Waterfall, aligned to phase-gate signoff. Cadence variation is a consumer-file concern (`release-process.md` variation table), not a framework-dimension concern.

---

## Dimension 5 — State Persistence Across Sessions

**Principle:** Files are the memory. Sessions are ephemeral. All durable state lives in tracked artifacts.

**State categories and their authoritative files:**

| State Category | Authoritative Location | Scope | Persists Across |
|---|---|---|---|
| Session handoff state | `projects/_config/SESSION_STATE.md` | Operator's current-session context | Sessions |
| Active behavioral corrections | `projects/_config/CORRECTIONS.md` | Short-term operator preference overrides | Sessions until explicit removal |
| User-durable memory | User auto-memory store | Cross-project user preferences + feedback | Conversations |
| Release working state | `release/releases/plans/<slug>_RELEASE_PLAN.md` (slug-primary / pre-claim; renamed to `vX.Y_RELEASE_PLAN.md` at the Stage-12 claim) | Current release's plan + deviation log + verification evidence | Sessions within a release |
| Cross-release audit trail | `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` | Shipped releases' permanent record | Forever |
| Project operating state | `projects/<project>/PROJECT.md` | Active project context | Project lifetime |
| Portfolio state | `projects/_config/PORTFOLIO.md` | Cross-project health | Continuously |

**Cross-reference contracts:**
- Any stage that produces durable state MUST name its authoritative file (per each `pipeline/stage-NN-*.md` § 6 Outputs).
- Any stage that consumes durable state MUST read from the authoritative file (per each `pipeline/stage-NN-*.md` § 4 Inputs).
- No dual-writes — the authoritative file has a single-writer discipline per Layer classification.

**Staleness handling:** When `SESSION_STATE.md` `Last Updated` is older than 2 business days, flag a full-state refresh (per `CLAUDE.md` § Session Management Staleness Rule). Framework references; does not redefine.

**Methodology variation:** The durable-state set is methodology-agnostic. Methodology determines variation in session-state *contents* (e.g., a Scrum project's PROJECT.md names a Sprint; a Kanban project's PROJECT.md names WIP limits). The *list* of state files is stable.

---

## Dual-Domain Worked Examples

### Example A — Engineering release

**Domain:** Engineering (Layer 1, git-tracked, `pmo-platform/`).
**Methodology:** Hybrid — the platform has Scrum-like release-bundling but Waterfall-style phase-gates at Stages 9/12.
**Dimensions in action:**

1. **Work Breakdown:** the release Milestone → 3 Issues → sub-tasks per stage per issue (Stage 4 release planning + per-issue Stages 5 / 6 / 7 / 8 / 9 / 12 / 13) → commits on the release branch.
2. **Assignment:** Operator (human, Role) + Hub Agent (Claude session, Role) + Spoke Agents (one per sub-task, each embodying the stage's Persona from `release-personas.md`).
3. **Tracking:** Each Issue has Stage / Status / Decision-Date GitHub Project fields + `sub-task` label on sub-tasks + the Milestone.
4. **Handoff:** Stage 4 output (release plan on ) → scaffolding → Stage 5 spoke prompts (Procedure 3) → Spoke sub-task comments → Collective Review (for this release, because ≥2 issues with Solutioning activated) → Stage 6 Engineering.
5. **State persistence:** Release plan committed as `release/releases/plans/<slug>_RELEASE_PLAN.md` (slug-primary / pre-claim — renamed to `vX.Y_RELEASE_PLAN.md` at the Stage-12 claim, ADR-092) at Engineering Commit 0; session handoff via `SESSION_STATE.md`; audit trail via `RELEASE_LOG.md` after merge.

### Example B — Operational PMO delivery ([PROJECT_KEY] Implementation hypercare)

**Domain:** Operations (Layer 2, git-ignored, `projects/[PROJECT_KEY] Implementation/`).
**Methodology:** [PROJECT_KEY] project uses **Waterfall phase-gates with Agile execution inside phases** — a Hybrid with `delivery_approach: Hybrid`, `base_archetype: Waterfall`, `derived_from: [Scrum, Waterfall]` per the typed Custom block.
**Dimensions in action:**

1. **Work Breakdown:** Phase (CLOSING state → hypercare) → Work Items (hypercare issue tickets, one per incident / defect) → Tasks (ordinary ops tasks, tracked in carry-forward tracker, NOT sub-task GitHub Issues) → Deliverables (status updates, hotfix decisions, hypercare tracker entries).
2. **Assignment:** Operator (human, Role) + PMO-agent skill (e.g., `ppm-agent`, Role acting via skill invocation) + SMEs for specific domains (Role).
3. **Tracking:** Operational trackers under `projects/[PROJECT_KEY] Implementation/04-PMO-Operations/` (NOT GitHub Issues — GitHub is Engineering-domain only). Tracker schemas per `schemas/tracker-schemas.md`.
4. **Handoff:** Session-to-session via operational trackers (open-items tracker, hypercare tracker) + daily-status Teams messages + AM/PM daily-status framework in Operations domain.
5. **State persistence:** `PROJECT.md` for project context (phase, systems, SME list); carry-forward trackers for open items; `PORTFOLIO.md` rollup; NO git history for most Operations artifacts (Layer 2 is git-ignored).

**Shared framework, different tool set:** Both examples use the 5 framework dimensions, but with different *tools* — Example A uses GitHub Issues + `release-process.md` + `hub-spoke-bridge.md`; Example B uses operational trackers + `daily-status` skill + `ppm-agent` skill. The framework's dimensional semantics are stable; the tool layer adapts to the domain. This is the load-bearing dual-domain claim (AC-250-7).

---

## Methodology Variation Hook

The framework's 5 dimensions are stable across all methodologies. Methodology parameterizes the *content* inside each dimension, not the *structure*:

| Dimension | Methodology-Variable? | Where Variation Lives |
|---|---|---|
| Work Breakdown | Yes (Sprint inclusion) | `methodology-archetype-matrix.md` rows per dimension |
| Assignment | No (Role structure stable) | — |
| Tracking | Yes (fields, board config) | `schemas/tracker-schemas.md` + `github-projects-guide.md` + `schemas/field-lifecycle-matrix.md` variation tables |
| Handoff | Yes (cadence, ceremony) | `release-process.md` variation table |
| State Persistence | No (file set stable; contents vary) | — |

Composition rule: this framework's dimension semantics are the spine; the Methodology layer populates per-approach rows via `methodology-parameterization-v1.md`; the Tool layer consumes both.

---

## Governance Hierarchy Placement

This document is authoritative for the 5 execution dimensions. Beyond that, it is deliberately narrow:

**What this file owns:**
- Dimensional vocabulary (Work Breakdown / Assignment / Tracking / Handoffs / State Persistence) and their semantics
- Composition contracts with Process, Methodology, and Tool layers
- Dual-domain applicability patterns (Engineering vs. Operations)

**What this file does NOT own:**
- **Process layer:** the 13-stage sequence — that's `pipeline/`
- **Methodology layer:** `delivery_approach` enum + archetype definitions — that's `methodology-parameterization-v1.md` + `project-schema.md`
- **Tool layer:** specific hub-and-spoke mechanics — that's `hub-spoke-bridge.md` + `implementation-execution-pattern.md` + skills
- **Terminology contract:** canonical term definitions — that's `terminology-glossary.md`
- **Reversibility / risk discipline:** `reversibility-protocol.md` + `decision-discipline.md` remain the authorities
- **Failure-mode structural standard:** `failure-mode-standard.md` remains the authority for the 5-field template (this file USES it; does not redefine it)

**Position in the 4-layer hierarchy** (per glossary Category 3):

| Layer | This file's relationship |
|---|---|
| Process | Consumes (stage sequence is input; dimensions apply WITHIN stages) |
| Methodology | Composes with (methodology populates dimension variations; framework provides dimensional spine) |
| **Framework** | **IS** (execution-domain scope; `methodology-parameterization-v1.md` is the sibling Framework doc at methodology-domain scope) |
| Tool | Produces for (tools implement framework patterns and cite this doc) |

---

## Consumer Contract

Execution tools and skills that "implement the framework" MUST:

1. **Cite the framework** at the top of their own doc: `> Implements [Execution Framework](../disciplines/execution-framework.md).`
2. **For each of the 5 dimensions the tool implements, state which pattern it uses** — a brief table or per-section note suffices.
3. **Conform to the glossary terminology** (`terminology-glossary.md`) when naming their own concepts.
4. **NOT redefine framework-dimension semantics** — if a tool needs a new dimension variant, author it here first (or via ADR + this file update).

**Compliance posture:** This is a MUST for new tools and a SHOULD for existing tools (retrofit on-demand as they are edited). Existing files are not retroactively rewritten; compliance propagates organically as files are touched per the "No ungoverned changes" protocol.

**Skill ↔ pipeline alignment (Tool-layer ↔ Process-layer contract).** A skill is a Tool-layer implementation that runs *inside* the Process layer's 13-stage pipeline. How any skill aligns to the stages it runs in — whether it is 1:1 stage-mapped, one of several stage-internal steps, or a cross-stage composing service, plus the decision-tests that keep its mode/gate vocabulary from shadowing the canonical pipeline IDs — is governed by the skill-pipeline-alignment standard (`core/standards/skill-pipeline-alignment.md`). That standard is the Tool-layer alignment contract for this dimension; it operationalizes ADR-019 (`core/ADRs/ADR-019-specialists-compose-not-absorb.md`, "Specialists compose, not absorb") at the skill↔pipeline seam. This framework owns the layer *relationship*; the alignment standard owns the skill-side *conformance rules*.

**First citations:** `hub-spoke-bridge.md` gets the retrofit citation in Wave 2a (§ Framework Alignment). `implementation-execution-pattern.md` is a retrofit candidate deferred to the next edit of that file (low priority — no term collisions).

---

## Failure Modes

Per [failure-mode-standard.md](../standards/failure-mode-standard.md), this framework authors 3 domain-specific failure modes using the 5-field template (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response). Tags follow the `failure-mode-standard.md` category taxonomy: TRIG (triggering), INPUT (input handling), PROC (processing), OUT (output), HAND (handoff).

### FM-EF-1 [OUT] — Tool confused with Framework

- **Signature:** Agent treats `hub-spoke-bridge.md` (or another specific tool) as the Framework and ignores methodology variation. Symptom: agent claims "the hub-and-spoke framework requires X" when X is actually a tool-layer implementation choice, not a framework dimension.
- **Conditional:** Do NOT point to a specific execution tool when asked for the Framework, because Framework and Tool are different layers of the 4-layer hierarchy.
- **Root cause:** Layer conflation — the agent reads a tool's documentation as if it defined the pattern it implements. The tool documents its own mechanics; the Framework owns dimensional semantics.
- **Mitigation:** When answering a Framework-layer question, check the [Relationship table](#relationship-to-other-docs-governance-hierarchy-placement) — if the cited doc is in the Tool row, back up to the Framework row.
- **Principal-vs-junior response:** A junior agent cites a tool as authoritative because the tool is concrete and the framework is abstract. A principal agent cites the framework for dimensional semantics and cites the tool only as "one implementation of the pattern."

### FM-EF-2 [OUT] — Methodology and Framework conflated at term level

- **Signature:** Agent uses "framework" to mean "delivery approach" — e.g., writes "the Scrum framework defines sprint events" in governance docs or skill authoring.
- **Conditional:** Do NOT use "framework" to describe a [Methodology](../specs/terminology-glossary.md#term-methodology) when authoring governance content, because the glossary reserves [Framework](../specs/terminology-glossary.md#term-framework) (Category 3) for the tool-agnostic pattern layer.
- **Root cause:** Industry usage of "framework" is ambiguous — "the Scrum framework" is a common phrase that reuses the word at a different abstraction level. The platform glossary disambiguates; agents not grounded in the glossary carry the industry ambiguity into platform content.
- **Mitigation:** When drafting governance or skill-authoring content, run a terminology pass: every occurrence of "framework" should survive the glossary Category 3 test (tool-agnostic, pattern-set, consumed-by-tools). If it fails, replace with "Methodology."
- **Principal-vs-junior response:** A junior agent uses "framework" and "methodology" interchangeably because both sound authoritative. A principal agent distinguishes the layers and enforces glossary discipline even when industry norms blur them.

### FM-EF-3 [HAND] — State-persistence dual-writes

- **Signature:** Two skills or sessions write to the same authoritative state file (e.g., `SESSION_STATE.md`, `RELEASE_LOG.md`, `PORTFOLIO.md`) without a single-writer contract. Symptom: file contents alternate between contradictory states, or last-write-wins corruption.
- **Conditional:** Do NOT write to `SESSION_STATE.md`, `RELEASE_LOG.md`, or any Dimension 5 state file from multiple producers in the same session, because the Layer classification mandates single-writer discipline per file.
- **Root cause:** Ambiguous ownership — two skills both plausibly "own" a state update (e.g., both a close-out skill and a status-report skill plausibly write to SESSION_STATE.md). Without an explicit contract, both write and the later one silently overwrites the earlier.
- **Mitigation:** Check the [Dimension 5 authoritative-file column](#dimension-5--state-persistence-across-sessions) before any state-file write. Route the write through the designated producer (e.g., session-end updates go through the close-out flow, not through the status-report flow).
- **Principal-vs-junior response:** A junior agent writes to SESSION_STATE.md directly when wrapping up a task, overwriting concurrent session metadata. A principal agent routes the update through the established producer (or creates one) and logs the write-path decision for future sessions.

---

## See Also

- [terminology-glossary.md](../specs/terminology-glossary.md) — canonical term definitions (consumed throughout this file)
- [pipeline/](../../release/references/pipeline/) — Process layer (13-stage pipeline)
- [methodology-parameterization-v1.md](../../release/references/specs/methodology-parameterization-v1.md) — sibling Framework-layer doc (methodology-domain scope)
- [methodology-archetype-matrix.md](../../release/references/specs/methodology-archetype-matrix.md) — methodology variation tables (Work Breakdown dimension consumer)
- [hub-spoke-bridge.md](../../release/references/how-to/hub-spoke-bridge.md) — example Tool-layer implementation
- [implementation-execution-pattern.md](../../release/references/how-to/implementation-execution-pattern.md) — another example Tool-layer implementation (retrofit-citation candidate)
- [release-personas.md](../../release/references/specs/release-personas.md) — Persona source (Dimension 2 consumer)
- [`release/governance/release-process.md`](../../release/governance/release-process.md) — Governance layer
- [failure-mode-standard.md](../standards/failure-mode-standard.md) — 5-field template + category tags used in § Failure Modes
