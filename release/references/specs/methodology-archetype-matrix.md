# Methodology Archetype Matrix

**Status:** Canonical
**Owner:** `release/references/specs/methodology-archetype-matrix.md`
**Introduced:** methodology-parameterization-core (2026-04-24)
**Consumers:** release-planner-bundle (HARD handoff — data contract); role-skills-wave-2 (HARD handoff — data contract); role-skills-phase-0 (SOFT handoff)
**Cross-references:**

- [`schemas/project-schema.md`](../../../core/schemas/project-schema.md) — `delivery_approach` enum + `custom_methodology_definition` block + V1-V12 validation rules
- [`methodology-parameterization-v1.md`](methodology-parameterization-v1.md) — 8 archetype normative definitions + Custom Extension Protocol + Skill Consumption Pattern
- [`OPERATIONS.md § Methodology Awareness Protocol`](../../../core/governance/OPERATIONS.md) — skill consumption rule

---

## 1. Purpose

This document is the **variation data contract** for methodology-aware skill authoring. Where [`methodology-parameterization-v1.md`](methodology-parameterization-v1.md) provides prose definitions, this file provides the table-driven per-archetype variation grid that skill authors consult at implementation time to parameterize behavior (lifecycle → primitive selection; ceremonies → sync-point recognition; artifacts → input/output expectations; cadence → scheduling defaults).

The matrix is a **load-bearing data contract** for the HARD downstream handoffs (release-planner-bundle, role-skills-wave-2). Consumer skills read the row matching `PROJECT.md`'s `delivery_approach` field at invocation. Rows are stable; new rows are added only via the governance-promotion rule when a recurring Custom variant is elevated per [`methodology-parameterization-v1.md § 4.4`](methodology-parameterization-v1.md).

## 2. How to Read

### Column glossary

| Column | Type | Semantics |
|---|---|---|
| **Archetype** | enum / "Custom" | One of the 8 `delivery_approach` enum values — 7 named archetypes plus `Custom`, one row each |
| **Lifecycle** | enum (3 values) | `continuous` (flow-pull) / `phased` (gate-sequential) / `timeboxed` (iteration-bounded). Governs the core cadence pattern |
| **Ceremonies** | comma-separated list | Named recurring synchronization events the skill recognizes as sync points |
| **Artifacts** | comma-separated list | Named work-products the skill expects as inputs/outputs |
| **Cadence** | string | Canonical cadence description (for Custom: "see worked examples" pointer) |
| **Primary consumers** | list | Which PMO skills prioritize this archetype (methodology-sensitivity HIGH/CRITICAL per OPERATIONS.md §6.1) |
| **Sample project types** | list | Representative project types typically using this archetype (heuristic only — not authoritative) |
| **Distinguishing constraint** | one-line | Test that distinguishes this archetype from siblings (verbatim from `methodology-parameterization-v1.md § 3`) |

### Row conventions

- **Title-case archetype names** — match `delivery_approach` enum values byte-for-byte (case-sensitive per V2).
- **`Custom` row is special** — it does not specify fixed lifecycle/ceremonies/artifacts/cadence values; instead it enumerates the `custom_methodology_definition` sub-field schema and provides 3 worked examples.
- **Comma-separated lists use semantic enumeration** — each list entry names a distinct item.
- **Cross-reference to `methodology-parameterization-v1.md`** — full prose definition of each archetype lives there; the matrix is a data-driven complement.

### How to handle the Custom row

Consumer skills reading `delivery_approach: Custom` do NOT read the Custom **matrix row** for lifecycle/ceremonies/etc. — those fields live in `PROJECT.md`'s `custom_methodology_definition` block. The Custom matrix row documents the block **schema** and provides **worked examples** for authoring + skill-verification. Consumer skills use the block directly (per [`methodology-parameterization-v1.md § 5 Skill Consumption Pattern`](methodology-parameterization-v1.md) CASE 2 and CASE 3).

## 3. Archetype Matrix

8 rows (7 archetypes + Custom, matching the 8-value `delivery_approach` enum) × 8 columns. For readability in GitHub markdown, the matrix below renders compact text; the fuller prose — the per-archetype normative definitions — lives in the methodology-parameterization v1 spec named in Cross-references above.

| Archetype | Lifecycle | Ceremonies | Artifacts | Cadence | Primary consumers | Sample project types | Distinguishing constraint |
|---|---|---|---|---|---|---|---|
| **Scrum** | timeboxed | daily standup, sprint planning, sprint review, sprint retrospective | product backlog, sprint backlog, increment | 2-week sprints (typical) | delivery-engine, daily-status, project-initiator | software dev, digital product | Sprint commitment is protected; scope changes require sprint abort or next-sprint deferral |
| **Kanban** | continuous | replenishment review, service-delivery review | kanban board with WIP limits, cycle-time metrics, throughput metrics | continuous flow with cadence-based replenishment | delivery-engine, daily-status | support/ops, content production, continuous ops | WIP-limited pull system; capacity (flow efficiency), not velocity, is primary metric |
| **XP** | timeboxed | iteration planning, daily standup, iteration retrospective, pair-rotation, CI-health review | user stories, acceptance tests as specs, CI health metrics | 1-2 week iterations | delivery-engine | high-engineering-discipline software | Engineering practices (pair programming, TDD, CI) are governance-level requirements, not recommendations |
| **Waterfall** | phased | phase-gate review, change control board review | SOW, requirements spec, design doc, test plan, deployment plan | phase-duration variable (days-months per phase) | project-initiator, change-management, implementation-planner | regulated industries, infra, compliance-driven | Linear phase progression with formal gate-based change control |
| **PRINCE2** | phased | end-stage assessment, exception-plan review, highlight-report cadence | PID, business case, stage plans, highlight reports, exception reports | stage-duration variable; highlights on defined cadence | project-initiator, change-management | UK public sector, large-program governance, controlled-environment projects | Governance framework (not development methodology) — tailors to project scale/risk; coexists with Scrum/Waterfall inside stage boundaries |
| **SAFe** | timeboxed | PI Planning, System Demo, Inspect & Adapt, scrum-of-scrums | ART backlog, PI objectives, program board, solution intent | 8-12 week Program Increment (4-6 team sprints) | delivery-engine, weekly-status-rollup | enterprise multi-team Agile, ART-organized development | PI is the coordination primitive above the sprint — single-team timeboxed is Scrum, not SAFe |
| **Hybrid** | per the two constituents (e.g. timeboxed + phased) | union of the two constituent archetypes | union of the two constituent archetypes | each constituent's native cadence, run side-by-side | delivery-engine, weekly-status-rollup, ppm-agent | enterprise transformation, dual-track programs, any user-configured two-archetype combination | Two distinct archetypes in one project; native-framing status output in TWO lifecycles simultaneously |
| **Custom** | per block | per block | per block | per block | all methodology-aware role skills | non-canonical variants (Scrumban, Shape Up, operator-invented) | `custom_methodology_definition` block IS the methodology definition — no implicit archetype fallback |

### 3.1 Rationale for column semantics

**Lifecycle** is the single most important skill-parameterization signal. Skills key their primitives off `lifecycle`:

- `timeboxed` → velocity, sprint-goal, iteration burndown primitives.
- `continuous` → WIP limits, cycle-time, throughput primitives.
- `phased` → phase-gate progress, milestone completion, change-control-board metrics.

**Ceremonies** determines which project events the skill treats as sync points for status aggregation and decision cadence. A skill rendering weekly status output for a Scrum project should align to the sprint review rhythm; the same skill for a Kanban project should align to the replenishment review rhythm.

**Artifacts** determines what the skill expects as documentation inputs and what it generates as outputs. A skill producing a daily status for a Waterfall project references the current phase's work-products (design doc revisions, test plan execution); the same skill for a Kanban project references flow items pulled and cycle times.

**Cadence** informs scheduling defaults. Weekly-status-rollup runs weekly regardless of archetype, but the status-section content varies: sprint-end summary for Scrum on sprint-end weeks; throughput delta for Kanban; PI-midpoint check for SAFe at weeks 4-6 of a 12-week PI.

## 4. Custom Row — Schema + Worked Examples

The Custom row is special: it does not have fixed lifecycle/ceremonies/artifacts/cadence values. Instead, each Custom-using project populates the `custom_methodology_definition` block in its PROJECT.md, and consumer skills read the block directly. This section documents the block schema and provides **3 worked examples** (operationalizes **AC-R1**).

### 4.1 Custom block schema

Per [`schemas/project-schema.md § 3 Root Schema`](../../../core/schemas/project-schema.md):

```yaml
delivery_approach: Custom
custom_methodology_definition:
  name: string                             # REQUIRED — display name
  base_archetype: <one-of-8> | null        # REQUIRED — closest archetype or null
  derived_from: [<archetype-name>, ...]    # REQUIRED — may be empty []
  lifecycle: continuous | phased | timeboxed
                                           # REQUIRED — core cadence pattern
  ceremonies: [string, ...]                # REQUIRED — min 1 entry
  artifacts: [string, ...]                 # REQUIRED — min 1 entry
  cadence: string                          # REQUIRED — non-empty
  notes: string                            # OPTIONAL
```

Validation per V3 + V5-V11 (all structural auto-check per [`schemas/project-schema.md § 5`](../../../core/schemas/project-schema.md)).

### 4.2 Worked Example 1 — Scrumban (base_archetype: Kanban)

```yaml
delivery_approach: Custom
custom_methodology_definition:
  name: Scrumban
  base_archetype: Kanban
  derived_from: [Kanban, Scrum]
  lifecycle: continuous
  ceremonies:
    - daily standup
    - replenishment review
    - retrospective
  artifacts:
    - kanban board with WIP limits
    - cycle-time metrics
    - sprint goals as optional overlay
  cadence: continuous flow with weekly replenishment
  notes: Scrum ceremonies retained, estimation and sprint commitment replaced with WIP-limited pull
```

**Validation trace (V1-V12):**

| Rule | Check | Pass? |
|---|---|---|
| V1 | `delivery_approach` present | ✓ |
| V2 | `Custom` in enum | ✓ |
| V3 | block present when Custom | ✓ |
| V5 | `name: "Scrumban"` non-empty | ✓ |
| V6 | `base_archetype: Kanban` in enum | ✓ |
| V7 | `derived_from: [Kanban, Scrum]` both in enum | ✓ |
| V8 | `lifecycle: continuous` in `{continuous, phased, timeboxed}` | ✓ |
| V9 | `ceremonies` has 3 entries (min 1) | ✓ |
| V10 | `artifacts` has 3 entries (min 1) | ✓ |
| V11 | `cadence` non-empty | ✓ |
| V12 | `notes` is a string | ✓ |

**Custom Block Completeness:** PASS (all V3 + V5-V11 satisfied).

**Skill-consumption branch per [`methodology-parameterization-v1.md § 5`](methodology-parameterization-v1.md):** **CASE 2** — `base_archetype: Kanban` populated, so skills start from Kanban matrix row (lifecycle=continuous, ceremonies=replenishment-review+service-delivery-review) as default and override with block's ceremonies (adds daily standup + retrospective) and block's cadence (continuous flow with weekly replenishment).

### 4.3 Worked Example 2 — Shape Up (base_archetype: null — genuinely novel)

```yaml
delivery_approach: Custom
custom_methodology_definition:
  name: Shape Up
  base_archetype: null
  derived_from: []
  lifecycle: timeboxed
  ceremonies:
    - betting table
    - kickoff
    - cool-down retrospective
  artifacts:
    - pitches
    - shape-up bets
    - circuit-breaker deadlines
    - hill charts
  cadence: 6-week cycle + 2-week cooldown
  notes: Basecamp-originated; no backlogs, no sprints, no standups — betting replaces planning
```

**Validation trace (V1-V12):**

| Rule | Check | Pass? |
|---|---|---|
| V1 | `delivery_approach` present | ✓ |
| V2 | `Custom` in enum | ✓ |
| V3 | block present | ✓ |
| V5 | `name: "Shape Up"` non-empty | ✓ |
| V6 | `base_archetype: null` (explicit null literal allowed per V6) | ✓ |
| V7 | `derived_from: []` empty list allowed | ✓ |
| V8 | `lifecycle: timeboxed` in enum | ✓ |
| V9 | `ceremonies` has 3 entries | ✓ |
| V10 | `artifacts` has 4 entries | ✓ |
| V11 | `cadence` non-empty | ✓ |
| V12 | `notes` is a string | ✓ |

**Custom Block Completeness:** PASS.

**Skill-consumption branch:** **CASE 3** — `base_archetype: null`, so skills MUST use the block's lifecycle/ceremonies/artifacts/cadence directly — NO archetype fallback. If a skill cannot parameterize from these fields (e.g., a sprint-native daily-status skill encountering "betting table" as a ceremony it does not recognize), the skill MUST emit methodology-agnostic output with a caveat — it MUST NOT silently default to Scrum. This is the canonical **PROC-3 Base-archetype blind fallback** failure-mode case that the `null`-as-intentional semantic prevents.

### 4.4 Worked Example 3 — Scrum-no-estimation (base_archetype: Scrum)

```yaml
delivery_approach: Custom
custom_methodology_definition:
  name: Scrum-no-estimation
  base_archetype: Scrum
  derived_from: [Scrum, Kanban]
  lifecycle: timeboxed
  ceremonies:
    - sprint planning (throughput-based)
    - daily standup
    - sprint review
    - retrospective
  artifacts:
    - sprint backlog (no story points)
    - throughput chart
    - sprint goal
  cadence: 2-week sprints with throughput-based capacity
  notes: Full Scrum minus story-point estimation; capacity measured by historical throughput
```

**Validation trace (V1-V12):**

| Rule | Check | Pass? |
|---|---|---|
| V1 | `delivery_approach` present | ✓ |
| V2 | `Custom` in enum | ✓ |
| V3 | block present | ✓ |
| V5 | `name: "Scrum-no-estimation"` non-empty | ✓ |
| V6 | `base_archetype: Scrum` in enum | ✓ |
| V7 | `derived_from: [Scrum, Kanban]` both in enum | ✓ |
| V8 | `lifecycle: timeboxed` in enum | ✓ |
| V9 | `ceremonies` has 4 entries | ✓ |
| V10 | `artifacts` has 3 entries | ✓ |
| V11 | `cadence` non-empty | ✓ |
| V12 | `notes` is a string | ✓ |

**Custom Block Completeness:** PASS.

**Skill-consumption branch:** **CASE 2** — `base_archetype: Scrum`, skills start from Scrum matrix row as default and override with block's artifacts (drops story points, adds throughput chart) and block's cadence (specifies throughput-based capacity). A velocity-calculation primitive invoked on a Scrum project would here substitute throughput-based capacity per the block's `cadence` field.

### 4.5 Summary — AC-R1 compliance

| Required named example | Present? | Validation | Skill-consumption branch |
|---|---|---|---|
| **Scrumban** | ✓ §4.2 | PASS V1-V12 | CASE 2 (base=Kanban) |
| **Shape Up** | ✓ §4.3 | PASS V1-V12 | CASE 3 (null base) |
| **Scrum-no-estimation** | ✓ §4.4 | PASS V1-V12 | CASE 2 (base=Scrum) |

**AC-R1 status:** PASS — 3 required named examples present, each a fully-populated block with all 8 fields, each parsing against V3 + V5-V11 block-completeness (AC-R2).

**Negative test cases (for Stage 8 QA):**

- Custom with `cadence` missing → V11 FAIL → Custom Block Completeness FAIL.
- Custom with `lifecycle: weekly` → V8 FAIL → Custom Block Completeness FAIL.

## 5. Skill Authoring Quick-Reference

Given a project's `delivery_approach`, a methodology-aware skill's parameterization decisions fall into a small set of predictable patterns. This section provides the quick-reference.

### 5.1 "Given `delivery_approach = X`, your skill should..."

| If `delivery_approach` is... | Your skill should... | Key primitives |
|---|---|---|
| `Scrum` | Align output to sprint rhythm; use velocity / sprint-goal / sprint-burndown primitives; expect sprint-end summary on sprint-close weeks | velocity, sprint commitment, sprint goal, DoR/DoD |
| `Kanban` | Align output to continuous flow; use WIP / cycle-time / throughput primitives; weekly-status reports throughput delta | WIP limit, cycle time, throughput, replenishment |
| `XP` | Align output to iteration rhythm + elevate engineering-practice health metrics (CI green%, TDD coverage, pair-rotation) as first-class | iteration velocity, CI health, pair rotation, TDD coverage |
| `Waterfall` | Align output to phase progression; use phase-gate / WBS-completion / change-control primitives; weekly-status reports phase-progress percentage | phase-gate state, WBS %, change request count, CCB throughput |
| `PRINCE2` | Align output to stage boundaries; use end-stage-report / exception-plan / highlight-report primitives; weekly-status respects highlight-report cadence | stage boundary, end-stage decision, exception count, highlight cadence |
| `SAFe` | Align output to PI cadence AND per-team sprint rhythm; use PI objectives / program-board dependencies / ART health primitives | PI objective achievement %, program-board dependency health, ART sync |
| `Hybrid` / `[A, B]` | Produce one native section per constituent archetype; use the union of constituent primitives per the work-organization-mapping-framework § 2.5 per-track mapping; check the orthogonal `dual_framing_enabled` flag to *additionally* activate the Dual-Framing Bridge | per-constituent primitives side-by-side; union per § 2.5; co-management bridge gated separately by `dual_framing_enabled` |
| `Custom` | Read `custom_methodology_definition` block; parameterize per 3-branch logic (CASE 2 / CASE 3); log the branch taken | per-block lifecycle/ceremonies/artifacts/cadence |

### 5.2 Common skill-authoring anti-patterns

Per [`methodology-parameterization-v1.md § 6 Failure Modes`](methodology-parameterization-v1.md). Skill authors MUST avoid:

- **PROC-2 Custom-block skip** — reading `delivery_approach: Custom` without reading the block.
- **PROC-3 Base-archetype blind fallback** — silently defaulting to Scrum when `base_archetype: null`.
- **PROC-4 Hardcoded sprint presumption** — applying sprint primitives to `lifecycle: continuous` or `lifecycle: phased`.
- **HAND-5 Enum-drift** — inventing a 9th archetype in one skill without governance-promotion.
- **INPUT-1 Methodology conflation** — treating `dual_framing_enabled: true` as synonymous with `delivery_approach: Hybrid`.

### 5.3 Debug-log convention

Skills SHOULD log the methodology-consumption branch taken in debug output. Format:

```
[methodology-branch: CASE 1 archetype=Scrum]
[methodology-branch: CASE 2 base=Kanban variant=Scrumban]
[methodology-branch: CASE 3 null-base variant=Shape Up caveat=agnostic-output]
```

This aids skill-author debugging and operator review when output for an edge-case project does not match expectations.

### 5.4 Matrix update procedure (governance-controlled)

Rows are added to the Archetype Matrix ONLY via governance-promotion per [`methodology-parameterization-v1.md § 4.4`](methodology-parameterization-v1.md). Skills MUST NOT unilaterally add rows or extend existing rows. The governance-promotion process:

1. Observe a Custom variant with recurring `name` across ≥2 projects within a 180-day window (per [`decision-discipline.md § 4.2`](../../../core/disciplines/decision-discipline.md) emergence rule).
2. Log the occurrence; pattern-cache N=1 → N=2.
3. Operator elevates the variant in a future minor release — requires GitHub Issue with `improvement` label + implementation plan + PR per `CLAUDE.md` "No ungoverned changes" protocol.
4. Elevated variant gets:
   - A new row in this matrix.
   - A new H3 section (normative definition) in [`methodology-parameterization-v1.md § 3`](methodology-parameterization-v1.md).
   - An entry in `delivery_approach` enum in [`schemas/project-schema.md § 3`](../../../core/schemas/project-schema.md).
   - Coordinated update across consumer skills.
5. Existing projects using `delivery_approach: Custom` with the elevated `name` can migrate to the named enum in a follow-up release; migration is non-forced.

---

**End of methodology archetype matrix.** Back: [`methodology-parameterization-v1.md`](methodology-parameterization-v1.md). Schema: [`schemas/project-schema.md`](../../../core/schemas/project-schema.md). Governance: [`OPERATIONS.md § Methodology Awareness Protocol`](../../../core/governance/OPERATIONS.md).
