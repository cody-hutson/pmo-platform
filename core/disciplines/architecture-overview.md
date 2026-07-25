---
title: PMO Platform — Architecture Overview
purpose: The single source of truth for how the PMO platform works — read before any structural decision, deployment change, or assumption about file ownership.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# PMO Platform — Architecture Overview

This document is the single source of truth for how the PMO platform works. Read this before making any structural decisions, deployment changes, or assumptions about file ownership.

---

## What This Is

A software platform that operates as a Claude Code-managed PMO (Project Management Office). The git repository (`pmo-platform/`) is the product — it contains skill definitions, governance rules, reference material, and deployment tools that let Claude Code run the PMO. The operational workspace (`projects/`) is where the platform runs — actual project data managed via Claude Code skills.

Think of it like building an application: `pmo-platform/` is the source code, `projects/` is the operational state.

---

## Who This Serves — Product & Role Model

The platform serves a specific set of **human** roles and models every **other** PMO role as an AI agent contributor.

- **Served humans (the orchestrators).** The platform is built for **Portfolio leads, Program Managers (PgMs), and Project Managers (PMs)** — the humans who own the portfolio, program, and project altitude. The human directs the work, renders the irreducible decisions (approvals, GO/NO-GO, deploy authorization), and stays accountable for delivery.
- **Agent-as-adjacent-role contributor.** Across the *other* PMO-adjacent roles — Business Analyst, Product Owner, Engineering, Design, Finance, Legal, HR, Sales, Marketing, Data, Customer Support — the platform's skills and agents act as a **principal-level contributor**: they produce the analysis, artifacts, and recommendations those roles would produce, at the quality bar a principal in that discipline would meet, and hand a decision (not a to-do list) back to the orchestrating human.

**Quality bar.** "Principal-level" is not a figure of speech — it is the measurable bar defined by the [`Principal Contributor Standard`](../standards/principal-standard-checklist.md). Every agent output is evaluated against that standard's competencies and PASS/FAIL behaviors; this document does not restate them (the checklist is the single source). When an output would fall short of that bar, the discipline is to surface the gap and its resolution path, not to ship briefing-grade work.

**Target-state evolution.** The forward-looking evolution of this human-orchestrator / agent-contributor split — the three-actor target model (orchestrator / specialist skill / free AI agent) bound by governance-as-contract — is stated, as a target architecture (not current state), in [`actor-model-and-governance-as-contract.md`](actor-model-and-governance-as-contract.md).

---

## One Agent, One Workspace

Claude Code is the single agent that operates the platform. It works across two areas without role separation — the same agent both builds the platform and runs the PMO:

| Area | Location | Mechanism | Governed by |
|---|---|---|---|
| **Platform engineering** | `pmo-platform/`, `.claude/`, workspace root files | Git branches → PRs → merge to main | `core/rules/` (auto-loaded), `CLAUDE.md` |
| **PMO operations** | `projects/` | Direct file read/write | Skills (deployed to `~/.claude/skills/`), governance files (`core/governance/`) |

### What Claude Code does

- Edits skills, governance, reference docs, schemas, templates (platform engineering)
- Runs the 13-stage release pipeline ([`release/governance/release-process.md`](../../release/governance/release-process.md))
- Deploys skills to its own user skills folder via `deploy.sh`
- Manages GitHub Issues, PRs, Milestones
- Processes transcripts, generates status updates, manages trackers (PMO operations)
- Follows governance rules from [`../governance/OPERATIONS.md`](../governance/OPERATIONS.md)
- Reads schemas and templates from `core/`
- Writes project artifacts to `projects/[Project]/01-08` folders

### Domain isolation

The two areas share an agent but never share files. Platform changes always go through git (branch → PR → merge). Project state lives in `projects/` and is git-ignored. A change in one area never accidentally modifies the other because each lives in a distinct part of the file tree with distinct read/write rules in `core/rules/`.

---

## Capability Surfaces & Extraction Posture

The platform serves **two audiences** — PMO practitioners (day-to-day program work) and platform builders (shipping releases). That split is realized as **two capability modules — `operations/` and `release/` — inside a three-module modular monolith** (`core/` shared kernel + the two consumer modules), **not** as two separate software packages.

- **The modular monolith is the durable packaging form** (decision D-02, 2026-06-10). One repository, three capability modules, each with a documented public API in its module README; modules talk only through declared public surfaces.
- **Extraction-readiness is preserved, but extraction is trigger-gated.** A module that proves genuinely independent *can* be lifted into its own repository without rewriting consumer references — but a package split **executes only if a named extraction trigger fires**: independent consumer demand, divergent release cadence, or an independent-versioning need. Absent a trigger, the monolith stands.
- **What is NOT codified:** any intended end-state where the platform "splits into two separate packages." That framing was **superseded as a packaging end-state on 2026-06-10 (D-02)**; the two-package idea survives only as the extraction *triggers* above, never as a committed destination.

The module partition, per-module public APIs, and the extraction-readiness clause are maintained in the canonical structural map — [`core/diagrams/architecture-platform-structure.md`](../diagrams/architecture-platform-structure.md) (§"What this depicts"). This section states the audience-decomposition + extraction posture in prose; that artifact is the maintained module tree. Summarize here; do not duplicate the module descriptions.

---

## File Architecture

```
workspace root/
├── CLAUDE.md                           ← workspace config (Claude Code auto-loads)
├── .gitignore                          ← ignores projects/
│
├── .claude/                            ← Claude Code runtime config
│   ├── rules/                          ← operating rules (deployed from core/rules/)
│   ├── settings.json                   ← settings (git-tracked)
│   └── hooks/                          ← security/governance hooks (deployed from core/hooks/)
│
├── pmo-platform/                       ← THE PLATFORM (git-tracked, modular monolith)
│   ├── core/                           ← cross-cutting core
│   │   ├── governance/                 ← OPERATIONS.md
│   │   ├── deploy/                     ← deploy.sh (deploy + --check + --report)
│   │   ├── rules/                      ← Claude Code operating rules (mirror source)
│   │   ├── disciplines/                ← architecture, operating-model, discovery/review/RCA
│   │   ├── standards/                  ← authoring standards & frameworks
│   │   ├── specs/                      ← autonomy-tiers, failure-mode, reversibility, …
│   │   ├── schemas/                    ← output-contract & data schemas
│   │   ├── skills/                     ← core skills (eval-writer, pmo-qa-auditor, prompt-builder)
│   │   ├── hooks/                      ← security/governance hooks (mirror source)
│   │   └── ADRs/                       ← architecture decision records
│   ├── operations/                     ← operations module
│   │   ├── skills/                     ← PMO ops skills (ppm-agent, comms-writer, …)
│   │   └── templates/                  ← artifact templates
│   ├── release/                        ← release module
│   │   ├── governance/                 ← RELEASE_PROTOCOL.md + release-process.md
│   │   ├── references/                 ← pipeline specs, how-to, standards
│   │   ├── releases/                   ← RELEASE_LOG.md, plans/, notes/, archive/
│   │   ├── skills/                     ← release skills (release-planner, pmo-skill-editor, …)
│   │   └── tools/                      ← release-support scripts
│   ├── docs/                           ← install/setup docs + scripts
│   └── packages/                       ← compiled .skill packages
│
└── projects/                           ← OPERATIONAL WORKSPACE (git-ignored)
    ├── _config/        (3 files)       ← operational state
    │   ├── PORTFOLIO.md                    cross-project health
    │   ├── SESSION_STATE.md                session handoff
    │   └── CORRECTIONS.md                  behavioral redirects
    └── [project folders]               ← actual project data
        ├── PROJECT.md
        └── 01-Governance/ ... 08-Generated/
```

---

## Skill Architecture

Skills are the core product — they define how Claude Code behaves in PMO operations. Each skill has three components:

```
Source (git-tracked)           Package (compiled)              Deployed (runtime)
────────────────────          ──────────────────              ────────────────────
pmo-platform/                 pmo-platform/                   ~/.claude/skills/
  operations/skills/ppm-agent/  packages/ppm-agent.skill        ppm-agent/
    SKILL.md                      (ZIP containing:)               SKILL.md ← from git
                                    SKILL.md                      references/
                                    references/                     push-to-resolve.md
                                      push-to-resolve.md           competency-model.md
                                      competency-model.md          ... ← from package
                                      ...
```

- **SKILL.md** (git source) is the authoritative skill definition — always deployed from git
- **references/** (inside .skill package) are bundled support files the skill reads at runtime
- **deploy.sh --deploy** copies SKILL.md from git + extracts references/ from the package to `~/.claude/skills/`

### Skill Roster

Current skill roster: see `core/deploy/deploy.sh` per-module arrays `OPERATIONS_SKILLS` + `RELEASE_SKILLS` + `CORE_SKILLS` (deployed roster) + `SUPPLEMENTARY_SKILLS` (full-tree deployments), plus `pmo-skill-refiner-selftest-canary` (source-only canary per ADR-04). Sum equals the directory listing across `{operations,release,core}/skills/`.

Packages: every skill in the deployed roster (`OPERATIONS_SKILLS` + `RELEASE_SKILLS` + `CORE_SKILLS`) + `SUPPLEMENTARY_SKILLS` has a corresponding `.skill` package in `packages/` — no exceptions per package-freshness enforcement. Canary is source-only (no package).

Claude Code first-party skills (not version-controlled in this repo, managed by Anthropic): `docx`, `pdf`, `pptx`, `xlsx`, `schedule`.

---

## Build Surfaces (Claude Code Component Types)

When extending the platform, the first design question is *which Claude Code component type* to build. Claude Code exposes **five** component types; each has a distinct invocation trigger, on-disk shape, and best-fit use.

| Component type | Invocation trigger | File shape | Best for |
|---|---|---|---|
| **Slash command** | Explicit operator invocation (`/name`) — deterministic, human-started | A prompt file under `.claude/commands/` (or a plugin's `commands/`) | A repeatable, operator-initiated workflow the human starts on demand |
| **Skill** | Model-decided — auto-invoked when the task matches the skill's description | A `SKILL.md` + bundled `references/` | A reusable domain capability the agent should reach for automatically when the work matches |
| **Agent (subagent)** | Delegated dispatch — spawned for a scoped sub-task, runs in its own context | An agent definition (`.claude/agents/*.md` frontmatter or SDK `agents`) | An isolated multi-step sub-task handled in a separate context and summarized back |
| **Hook** | Lifecycle event — fires on `PreToolUse` / `PostToolUse` / etc., every time, regardless of model judgment | A command/script wired into `settings.json` `hooks` | Enforcing an invariant or automation that must run deterministically on an event |
| **Plugin** | Distribution unit — bundles commands / skills / agents / hooks / MCP servers as one installable package | A plugin package installed from a marketplace | Sharing or consuming a bundle of components as a single installable unit |

### Selection decision tree

1. **Must it run deterministically on an event, every time, regardless of the model's judgment?** → **Hook**.
2. **Does the operator start it explicitly, on demand, as a repeatable workflow?** → **Slash command**.
3. **Should the agent reach for it automatically when the task matches?** → **Skill** — unless the work is an isolated multi-step sub-task that needs its own context, in which case → **Agent (subagent)**.
4. **Are you packaging several of the above to distribute or consume as one unit?** → **Plugin**.

**What this platform builds vs consumes.** This platform **builds** skills, agents, hooks, and slash-commands — the four surfaces it authors and version-controls. It **consumes** plugins (installed from marketplaces) rather than authoring them; plugins are a distribution wrapper, not a native build target here.

**Reconciliation with `build-philosophy.md`.** [`build-philosophy.md`](build-philosophy.md) presents a different five-surface cut — **Skills / Agents / Hub-Spokes / Hooks / Slash-commands** — which is the platform's *governance-enforcement* view, not the raw component taxonomy. The two are complementary cuts of the same space: **"Hub-Spokes" is a platform *composition* of the agent + skill primitives** (a multi-session execution pattern), **not a sixth raw component type**; and **"plugin" is a raw Claude Code surface this platform consumes but does not build**, which is why it appears here (build-*selection*) but not there (build-*enforcement*). Use this section to choose a surface; use `build-philosophy.md` to see which discipline enforces each surface.

---

## Deployment Model

Changes flow from git to Claude Code's user skills folder via `deploy.sh`:

```
Edit in Claude Code
        │
        ▼
Branch → PR → Merge to main
        │
        ▼
core/deploy/deploy.sh --deploy
        │
        ├─→ SKILL.md copied to ~/.claude/skills/<skill>/
        ├─→ references/ extracted from .skill package to ~/.claude/skills/<skill>/
        └─→ .skill package copied to ~/.claude/skills/packages/
        │
        ▼
Claude Code loads updated skills + references at next session start
```

### deploy.sh modes
| Mode | Purpose |
|---|---|
| `--deploy [skill...]` | Deploy changed skills (auto-detect or manual) |
| `--check [--warn]` | Validate platform health (numbered Check suite) |
| `--all` | Deploy the full skill roster + all packages (bootstrap / redeploy-everything) |
| `--report` | Structured report for release evidence |

### What gets deployed vs read in place
| Asset | Deployed? | Mechanism |
|---|---|---|
| Skills (SKILL.md) | Yes | `deploy.sh` → `~/.claude/skills/<skill>/` |
| Skill references/ | Yes | `deploy.sh` extracts from .skill package |
| .skill packages | Yes | `deploy.sh` → `~/.claude/skills/packages/` |
| Governance (OPERATIONS.md, etc.) | No | Claude Code reads directly from `core/governance/` |
| Schemas | No | Skills read directly from `core/schemas/` |
| Templates | No | Skills read directly from `operations/templates/` |
| Standards | No | Skills read directly from `core/standards/` |
| core/rules/ | No | Claude Code auto-loads at session start |

### Acquisition — canonical install

The deploy flow above propagates changes *within* a checkout; acquiring the platform in the first place follows the **canonical install** model: the public clones the canonical upstream repository directly and runs it as-is, rather than forking and self-hosting a divergent copy. Preserve the distinction — *where you install from* is canonical (the upstream repo, hardcoded in the install docs, which are identity-exempt); *which repo you drive releases against* is per-operator (the `REPO=` target stays tokenized). The sourcing decision (canonical-clone vs fork-and-self-host) is recorded in [`ADR-083 — Canonical install model`](../ADRs/ADR-083-canonical-install-model.md), which composes with [`ADR-017`](../ADRs/ADR-017-distribution-architecture.md) on the distribution surfaces + version-pinning posture.

---

## Governance Model

### File tiers (from CLAUDE.md)

| Tier | Type | Write rules | Examples |
|---|---|---|---|
| 1 | Stakeholder-facing | Propose → approve → write | RAID Log, Project Plan, governance docs |
| 2 | Operational trackers | Auto-write → confirm | Daily Status Log, Communications Tracker |
| 3 | New files | Auto-route with approval | Transcript uploads, new artifacts |
| 4 | Context files | Drift detection | PROJECT.md, OPERATIONS.md, CLAUDE.md |

### Governance files

| File | Location | Tracked in | Purpose |
|---|---|---|---|
| OPERATIONS.md | core/governance/ | Git | Behavioral rules for operational skills |
| RELEASE_PROTOCOL.md | core/governance/ | Git | Release lifecycle and change management |
| RELEASE_LOG.md | core/governance/ | Git | Version history |
| PORTFOLIO.md | projects/_config/ | Local (git-ignored) | Cross-project health snapshot |
| SESSION_STATE.md | projects/_config/ | Local (git-ignored) | Session handoff state |
| CORRECTIONS.md | projects/_config/ | Local (git-ignored) | Active behavioral redirects |

---

## Release Pipeline (13 Stages)

All platform changes go through a structured pipeline:

```
1. Intake → 2. Triage → 3. Bundle → 4. Planning → 5. Solutioning →
6. Engineering → 7. Dev Testing → 8. QA Testing → 9. Plan Review →
10. Dry Run* → 11. Snapshot* → 12. Execute → 13. Close

* Stages 10-11 compressed for git-native releases (PR diff = dry run, git history = snapshot)
```

- GitHub Issues track improvements
- GitHub Milestones bundle issues into releases
- GitHub Projects (PMO Pipeline) tracks pipeline stage
- All changes via branch → PR → review → merge

Pipeline operations are defined in:
- `release/governance/release-process.md` — pipeline operating rules
- `release/references/pipeline/` — detailed stage definitions
- `release/references/how-to/hub-spoke-bridge.md` — multi-session execution mechanism

---

## Peer-Spec Concept Ownership

The 13-stage pipeline (above) and the hub-spoke execution model load ≥9 peer specs at Stage 5 Solutioning and adjacent stages. Each concept defined in those specs has exactly one canonical owner. Use this map as a navigation index when a downstream reader (Stage 5 Solutioning spoke, Stage 6 Engineering, Stage 7 Dev Testing, QA, or any successor skill) needs to apply a specific concept and would otherwise pay the peer-spec-load cost of re-deriving ownership from cross-references.

| Concept | Owning spec | Section anchor | What it answers |
|---|---|---|---|
| **M1 Localization Check** | `core/disciplines/decision-discipline.md` | § 2.1 | How does a decision-class consumer reconcile platform-localized context against a generic heuristic? |
| **M2 Opposing View** | `core/disciplines/decision-discipline.md` | § 2.2 | What concrete counter-argument would change the recommendation? |
| **M3 Pattern Cache Scan** | `core/disciplines/decision-discipline.md` | § 2.3 | Has the operator surfaced this class pattern before, and what should the consumer do about it? |
| **Decision-class triage table** | `core/disciplines/decision-discipline.md` | § 3 | Which of M1/M2/M3 apply to a given decision class? |
| **Pattern cache infrastructure** (observation log + emergence rule) | `core/disciplines/decision-discipline.md` | § 4 | How do operator corrections promote from one-off observations to confirmed behavioral rules? |
| **Decision Briefing (Operating Principle)** | `release/references/how-to/hub-spoke-bridge.md` | Operating Principle | How does the hub present spoke outputs + release state to the operator without routing past pending judgment? |
| **D-Gate Template** | `release/references/how-to/hub-spoke-bridge.md` | Procedure 0 § D-Gate Template | What structural fields does each D-decision in a release plan carry (gate input, options, recommendation, upstream compatibility)? |
| **Hub-spoke Procedures P0–P7** | `release/references/how-to/hub-spoke-bridge.md` | Procedures 0–7 | What does the hub do at release planning, scaffolding, routing, spoke prompts, spoke completion, gates, early merge, release close? |
| **Stage I/O boundary contract** (7-field schema) | `core/schemas/stage-io-contracts.md` | § Schema Definition | What artifact, format, requirement, decision tier, cognitive load, delivery surface, and validation rule crosses each stage boundary? |
| **Three-Layer Gate Assessment** (metrics / judgment / calibration) | `core/schemas/gate-evaluation-spec.md` | § Three-Layer Assessment Protocol | At a stage transition, how does an agent assess gate readiness and produce a PROCEED / PROCEED WITH CAVEATS / HOLD recommendation? |
| **Gate criteria** (G1 / G2 / G3 / G-BR / G9 / G12 / G13) | `core/schemas/gate-criteria-spec.md` | per-Gate § | WHAT specifically does each pipeline gate check (criterion ID / type / check / automation)? |
| **Five-Phase Handoff Orchestration** | `core/schemas/handoff-coordinator-spec.md` | § Five-Phase Orchestration Protocol | At a stage boundary, how does the coordinator validate, evaluate, route, iterate, and report? |
| **Inter-Stage Feedback Tier 1/2/3** | `release/governance/release-process.md` (mirror: `engineering/rules/`) | § Inter-Stage Feedback Protocol | When a downstream stage finds upstream output insufficient mid-execution, what tier of return-to-upstream fires? |
| **Tier 0 — Premise Rejection** | `release/references/standards/triage-design-rereview.md` | § 9 | When a Stage 4/5 re-review identifies a premise problem at stage **entry** (not execution), what escalation block fires and what operator options exist? |
| **Re-Review Schema** (D1/D2/D3 dimensions, C1/C2/C3 classifications, PT-1..PT-4 premise-problem types) | `release/references/standards/triage-design-rereview.md` | § 1–3 | What dimensions does a Stage 4/5 re-review evaluate per requirement, what classifications can result, and what premise-problem taxonomy applies? |
| **Stage 5 Activation Gate** (Phase 0) | `release/references/pipeline/stage-05-solutioning.md` | § 5 Phase 0 | When does Solutioning activate (all-or-nothing per release)? |
| **Forecast Discipline** (deploy-resolution) | `release/references/pipeline/stage-05-solutioning.md` | § 5.5 | Which `deploy.sh --check` findings does Stage 12 deploy actually resolve vs. require a subsequent commit? |
| **Collective Review** (release-level checkpoint) | `release/references/pipeline/stage-05-solutioning.md` | § Release-Level Checkpoint | Post-Solutioning, how does the hub validate cross-issue design coherence before authorizing Engineering, and how does scope lock work? |
| **`delivery_approach` parameter** | `release/references/specs/methodology-parameterization-v1.md` | § 3 Definitions | What methodology archetype values are recognized (Scrum/Kanban/XP/Waterfall/PRINCE2/SAFe/Hybrid/Custom), and what does each parameterize? |
| **Custom Extension Protocol** | `release/references/specs/methodology-parameterization-v1.md` | § 4 | When `delivery_approach: Custom`, how is the project methodology specified and consumed? |
| **Glossary terms** (Task / Sub-task / Persona / Role / Milestone / Release / Process / Methodology / Framework) | `core/specs/terminology-glossary.md` | per-category § | When two specs use overlapping terms (e.g., Process vs. Methodology vs. Framework), which usage is canonical? |
| **Five Execution Dimensions** (Work Breakdown · Assignment · Tracking · Handoff · State Persistence) | `core/disciplines/execution-framework.md` | Dimensions 1–5 | At a layer below Process (pipeline) and Methodology (delivery approach), what tool-agnostic execution dimensions does every release exercise? |
| **Practice Efficacy Framework** (6-signal catalog + 3-trigger protocol + tier-derived cadence binding) | `core/standards/practice-efficacy-framework.md` | per-section | What signals measure practice efficacy, how often does efficacy review fire per framework tier, what triggers a re-evaluation, and how does this scope boundary against staleness and drift? |
| **Review Composition Framework + 7-dim taxonomy** (WHEN × WHAT × WHO/POSTURE × DETAIL × FOCUS × OUTPUT × AUTHORITY) | `core/standards/review-composition-framework.md` | per-section § | Which review fires at which pipeline stage with what posture, detail, focus, output, and authority — and how does the same object reviewed at multiple stages compose? |
| **Initiative-roadmap framework + cohesion-check** | `core/standards/initiative-roadmap-framework.md` | per-section (§3 / §4 / §5 / §6 / §7.9) | When does an initiative warrant a roadmap, what lifecycle does it follow, how does it differ from an ADR or Initiative Issue, and how is cross-milestone cohesion checked? |
| **KM Governance Framework + 4-class ownership enum + 4-source retirement protocol** | `core/standards/km-governance-framework.md` | per-section (§2 ownership / §3 approval / §4 retirement / §5 meta-governance / §6 composition boundaries / §9 schema-stability) | Who owns each K1 artifact, what authority approves new K1 entries by evidence tier, what triggers and workflow govern KM artifact retirement, who governs the KM-governance framework itself, and how does this compose with records-management, DRAFT→APPROVED, operating-model, and Anthropic-base-vs-build? |

**How to use this map.** When applying a concept, follow the section anchor. When two specs appear to define the same concept, the owning spec wins; the other spec is a citation. When a new concept emerges, add a row before the duplicate-source-discipline check fails — see [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md).

**Update discipline.** This map is the authoritative concept index. Any peer-spec change that renames a concept, splits a concept across specs, or introduces a new concept MUST update this map in the same PR. `core/deploy/deploy.sh --check` Check 14 (doc-link maintenance) flags anchor drift at deploy-time. Stage 13 Close verifies map currency for any peer-spec touched in the release.

---

## What belongs where

### pmo-platform/ (the product)
Everything that defines how the PMO works as software:
- How Claude Code behaves in operations (`core/governance/`, `{operations,release,core}/skills/`)
- What Claude Code produces in operations (`core/schemas/`, `operations/templates/`)
- Quality standards (`core/standards/`)
- Release history (`release/releases/`)
- Compiled packages (`packages/`)

### core/rules/ (Claude Code's operating manual)
How Claude Code operates when working on the platform:
- git-workflow.md — branching, commits, PR process
- release-process.md — 13-stage pipeline rules
- skill-deployment.md — deployment paths and procedures
- operations-bridge.md — cross-domain interaction rules
- governance-files.md — contextual loading for governance edits

### projects/ (runtime data)
The actual work being managed by the platform:
- _config/ — 3 operational state files (PORTFOLIO, SESSION_STATE, CORRECTIONS)
- Project folders with 01-08 structure
- Archive/ for closed projects

### Workspace root
- CLAUDE.md — workspace config read by both agents
- README.md — repo overview

(The deployment engine `deploy.sh` is not at workspace root — it lives under `core/deploy/deploy.sh`.)

---

## Key Principles

1. **One source, one truth** — every file has exactly one authoritative location
2. **Git tracks the platform, not the projects** — pmo-platform/ is versioned; projects/ is gitignored
3. **Skills are the interface** — Claude Code's PMO behavior is entirely defined by deployed skills + governance
4. **deploy.sh is the bridge** — all platform-to-runtime propagation goes through it
5. **Both agents share a filesystem** — schemas, templates, and governance are read in place (no deployment needed for non-skill assets)
6. **Platform changes never bypass git** — modifications to `pmo-platform/` always flow through branch → PR → merge, even within a single Claude Code session
7. **Operations changes stay in `projects/`** — project artifacts, status, and operational state never leak into `pmo-platform/`

---

## Related References

- [`core/diagrams/architecture-platform-structure.md`](../diagrams/architecture-platform-structure.md) — the centralized, current-state ASCII structural map of the modular-monolith top-level layout. This overview narrates how the platform works; that artifact is the maintained tree of where everything lives. The artifact reciprocates with a link back to this overview as a parent it depicts.
- [`actor-model-and-governance-as-contract.md`](actor-model-and-governance-as-contract.md) — the forward-looking **target-architecture** statement: the three-actor target operating model (orchestrator / specialist skill / free AI agent) bound by governance-as-contract, the permanent determinism-vs-judgment division, and the migration path from today's hub-spoke model. Target-state, not current-state.
- [`cross-chain-architecture-map.md`](cross-chain-architecture-map.md) — the cross-chain architecture index: for every management chain (escalation · project · program/portfolio · release + 6 operational sub-chains) it names the governing data model/entity, the flow/escalation path, and the holding gate/check. The operational-chain (World B) analog of the release-flow five-function spine (World A); references the per-domain architectures, does not restate them.
