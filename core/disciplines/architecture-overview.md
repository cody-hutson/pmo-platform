<!-- reference-durability: allow-link -->
# PMO Platform — Architecture Overview

This document is the single source of truth for how the PMO platform works. Read this before making any structural decisions, deployment changes, or assumptions about file ownership.

---

## What This Is

A software platform that operates as a Claude Code-managed PMO (Project Management Office). The git repository (`pmo-platform/`) is the product — it contains skill definitions, governance rules, reference material, and deployment tools that let Claude Code run the PMO. The operational workspace (`projects/`) is where the platform runs — actual project data managed via Claude Code skills.

Think of it like building an application: `pmo-platform/` is the source code, `projects/` is the operational state.

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

## File Architecture

```
workspace root/
├── CLAUDE.md                           ← workspace config (Claude Code auto-loads)
├── deploy.sh                           ← deployment engine
├── .gitignore                          ← ignores projects/
│
├── .claude/                            ← Claude Code runtime config
│   ├── rules/          (5 files)       ← operating procedures (git-tracked)
│   ├── settings.json                   ← settings (git-tracked)
│   └── hooks/                          ← pre-commit hooks (git-tracked)
│
├── pmo-platform/                       ← THE PLATFORM (git-tracked)
│   ├── governance/                     ← operational rules
│   ├── skills/                         ← skill definitions (see deploy.sh SKILL_LIST + SUPPLEMENTARY_SKILLS + canary)
│   ├── packages/                       ← compiled .skill packages (one per SKILL_LIST + SUPPLEMENTARY_SKILLS entry)
│   ├── reference/                      ← schemas, templates, standards, docs
│   ├── releases/                       ← release history
│   └── engineering/                    ← pipeline docs
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
  skills/ppm-agent/             packages/ppm-agent.skill        ppm-agent/
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

Current skill roster: see `deploy.sh` `SKILL_LIST` (deployed skills) + `SUPPLEMENTARY_SKILLS` (full-tree deployments) arrays, plus `pmo-skill-refiner-selftest-canary` (source-only canary per ADR-04). Sum equals the directory listing at `release/skills/`.

Packages: every skill in `SKILL_LIST` + `SUPPLEMENTARY_SKILLS` has a corresponding `.skill` package in `packages/` — no exceptions per package-freshness enforcement. Canary is source-only (no package).

Claude Code first-party skills (not version-controlled in this repo, managed by Anthropic): `docx`, `pdf`, `pptx`, `xlsx`, `schedule`.

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
| `--check [--warn]` | Validate platform health (4 checks) |
| `--report` | Structured report for release evidence |
| `--init` | One-time cutover migration |

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
| **M1 Localization Check** | `reference/decision-discipline.md` | § 2.1 | How does a decision-class consumer reconcile platform-localized context against a generic heuristic? |
| **M2 Opposing View** | `reference/decision-discipline.md` | § 2.2 | What concrete counter-argument would change the recommendation? |
| **M3 Pattern Cache Scan** | `reference/decision-discipline.md` | § 2.3 | Has the operator surfaced this class pattern before, and what should the consumer do about it? |
| **Decision-class triage table** | `reference/decision-discipline.md` | § 3 | Which of M1/M2/M3 apply to a given decision class? |
| **Pattern cache infrastructure** (observation log + emergence rule) | `reference/decision-discipline.md` | § 4 | How do operator corrections promote from one-off observations to confirmed behavioral rules? |
| **Decision Briefing (Operating Principle)** | `reference/hub-spoke-bridge.md` | Operating Principle | How does the hub present spoke outputs + release state to the operator without routing past pending judgment? |
| **D-Gate Template** | `reference/hub-spoke-bridge.md` | Procedure 0 § D-Gate Template | What structural fields does each D-decision in a release plan carry (gate input, options, recommendation, upstream compatibility)? |
| **Hub-spoke Procedures P0–P7** | `reference/hub-spoke-bridge.md` | Procedures 0–7 | What does the hub do at release planning, scaffolding, routing, spoke prompts, spoke completion, gates, early merge, release close? |
| **Stage I/O boundary contract** (7-field schema) | `reference/schemas/stage-io-contracts.md` | § Schema Definition | What artifact, format, requirement, decision tier, cognitive load, delivery surface, and validation rule crosses each stage boundary? |
| **Three-Layer Gate Assessment** (metrics / judgment / calibration) | `reference/schemas/gate-evaluation-spec.md` | § Three-Layer Assessment Protocol | At a stage transition, how does an agent assess gate readiness and produce a PROCEED / PROCEED WITH CAVEATS / HOLD recommendation? |
| **Gate criteria** (G1 / G2 / G3 / G-BR / G9 / G12 / G13) | `reference/schemas/gate-criteria-spec.md` | per-Gate § | WHAT specifically does each pipeline gate check (criterion ID / type / check / automation)? |
| **Five-Phase Handoff Orchestration** | `reference/schemas/handoff-coordinator-spec.md` | § Five-Phase Orchestration Protocol | At a stage boundary, how does the coordinator validate, evaluate, route, iterate, and report? |
| **Inter-Stage Feedback Tier 1/2/3** | `release/governance/release-process.md` (mirror: `engineering/rules/`) | § Inter-Stage Feedback Protocol | When a downstream stage finds upstream output insufficient mid-execution, what tier of return-to-upstream fires? |
| **Tier 0 — Premise Rejection** | `reference/standards/triage-design-rereview.md` | § 9 | When a Stage 4/5 re-review identifies a premise problem at stage **entry** (not execution), what escalation block fires and what operator options exist? |
| **Re-Review Schema** (D1/D2/D3 dimensions, C1/C2/C3 classifications, PT-1..PT-4 premise-problem types) | `reference/standards/triage-design-rereview.md` | § 1–3 | What dimensions does a Stage 4/5 re-review evaluate per requirement, what classifications can result, and what premise-problem taxonomy applies? |
| **Stage 5 Activation Gate** (Phase 0) | `reference/pipeline/stage-05-solutioning.md` | § 5 Phase 0 | When does Solutioning activate (all-or-nothing per release)? |
| **Forecast Discipline** (deploy-resolution) | `reference/pipeline/stage-05-solutioning.md` | § 5.5 | Which `deploy.sh --check` findings does Stage 12 deploy actually resolve vs. require a subsequent commit? |
| **Collective Review** (release-level checkpoint) | `reference/pipeline/stage-05-solutioning.md` | § Release-Level Checkpoint | Post-Solutioning, how does the hub validate cross-issue design coherence before authorizing Engineering, and how does scope lock work? |
| **`delivery_approach` parameter** | `reference/methodology-parameterization-v1.md` | § 3 Definitions | What methodology archetype values are recognized (Scrum/Kanban/XP/Waterfall/PRINCE2/SAFe/Hybrid/Custom), and what does each parameterize? |
| **Custom Extension Protocol** | `reference/methodology-parameterization-v1.md` | § 4 | When `delivery_approach: Custom`, how is the project methodology specified and consumed? |
| **Glossary terms** (Task / Sub-task / Persona / Role / Milestone / Release / Process / Methodology / Framework) | `reference/terminology-glossary.md` | per-category § | When two specs use overlapping terms (e.g., Process vs. Methodology vs. Framework), which usage is canonical? |
| **Five Execution Dimensions** (Work Breakdown · Assignment · Tracking · Handoff · State Persistence) | `reference/execution-framework.md` | Dimensions 1–5 | At a layer below Process (pipeline) and Methodology (delivery approach), what tool-agnostic execution dimensions does every release exercise? |
| **Practice Efficacy Framework** (6-signal catalog + 3-trigger protocol + tier-derived cadence binding) | `reference/standards/practice-efficacy-framework.md` | per-section | What signals measure practice efficacy, how often does efficacy review fire per framework tier, what triggers a re-evaluation, and how does this scope boundary against staleness and drift? |
| **Review Composition Framework + 7-dim taxonomy** (WHEN × WHAT × WHO/POSTURE × DETAIL × FOCUS × OUTPUT × AUTHORITY) | `reference/standards/review-composition-framework.md` | per-section § | Which review fires at which pipeline stage with what posture, detail, focus, output, and authority — and how does the same object reviewed at multiple stages compose? |
| **Initiative-roadmap framework + cohesion-check** | `reference/standards/initiative-roadmap-framework.md` | per-section (§3 / §4 / §5 / §6 / §7.9) | When does an initiative warrant a roadmap, what lifecycle does it follow, how does it differ from an ADR or Initiative Issue, and how is cross-milestone cohesion checked? |
| **KM Governance Framework + 4-class ownership enum + 4-source retirement protocol** | `reference/standards/km-governance-framework.md` | per-section (§2 ownership / §3 approval / §4 retirement / §5 meta-governance / §6 composition boundaries / §9 schema-stability) | Who owns each K1 artifact, what authority approves new K1 entries by evidence tier, what triggers and workflow govern KM artifact retirement, who governs the KM-governance framework itself, and how does this compose with records-management, DRAFT→APPROVED, operating-model, and Anthropic-base-vs-build? |

**How to use this map.** When applying a concept, follow the section anchor. When two specs appear to define the same concept, the owning spec wins; the other spec is a citation. When a new concept emerges, add a row before the duplicate-source-discipline check fails — see [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md).

**Update discipline.** This map is the authoritative concept index. Any peer-spec change that renames a concept, splits a concept across specs, or introduces a new concept MUST update this map in the same PR. `core/deploy/deploy.sh --check` Check 14 (doc-link maintenance) flags anchor drift at deploy-time. Stage 13 Close verifies map currency for any peer-spec touched in the release.

---

## What belongs where

### pmo-platform/ (the product)
Everything that defines how the PMO works as software:
- How Claude Code behaves in operations (governance/, skills/)
- What Claude Code produces in operations (reference/schemas/, reference/templates/)
- Quality standards (reference/standards/)
- Release history (releases/)
- Compiled packages (packages/)

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
- deploy.sh — deployment engine
- README.md — repo overview

---

## Key Principles

1. **One source, one truth** — every file has exactly one authoritative location
2. **Git tracks the platform, not the projects** — pmo-platform/ is versioned; projects/ is gitignored
3. **Skills are the interface** — Claude Code's PMO behavior is entirely defined by deployed skills + governance
4. **deploy.sh is the bridge** — all platform-to-runtime propagation goes through it
5. **Both agents share a filesystem** — schemas, templates, and governance are read in place (no deployment needed for non-skill assets)
6. **Platform changes never bypass git** — modifications to `pmo-platform/` always flow through branch → PR → merge, even within a single Claude Code session
7. **Operations changes stay in `projects/`** — project artifacts, status, and operational state never leak into `pmo-platform/`
