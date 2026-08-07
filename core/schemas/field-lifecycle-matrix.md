---
title: Field Lifecycle Matrix
purpose: Defines the lifecycle of every issue field across all 13 pipeline stages — which fields are created, required, updated, or locked at each stage, who populates them, and what gates block advancement.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: agents executing the CER Claim phase across the 13 stages; the gate specs (which fields gate stage advancement); the stage-io contracts
---
<!-- reference-durability: allow-link -->
# Field Lifecycle Matrix

Defines the lifecycle of every issue field across all 13 pipeline stages — which fields are created, required, updated, locked, or irrelevant at each stage, who populates them, and what gates prevent stage advancement with missing data.

**Consumers:** Agents executing the CER Claim phase (step 3: "Validate entry gate") use this matrix to determine field requirements. The [Agent Write Permissions](../../release/references/specs/ticket-information-architecture.md#agent-write-permissions) table defines WHAT each stage CAN write; this matrix defines WHAT each stage SHOULD write and MUST validate.

**Relationship to the architecture stack:**
- [ticket-information-architecture.md](../../release/references/specs/ticket-information-architecture.md) — defines the three-layer model and write permissions
- [Ticket Lifecycle Protocol](../../release/references/specs/ticket-information-architecture.md#ticket-lifecycle-protocol) — defines CER pattern and transition timing
- [stage-io-contracts.md](stage-io-contracts.md) — defines artifact deliverables per stage boundary
- This matrix — defines field state per stage and gate requirements

---

## Cell Taxonomy

Six values define the lifecycle state of each field at each pipeline stage.

| Value | Meaning | Agent Behavior |
|---|---|---|
| **C** | **Created** — field first populated at this stage | Agent writes this field. Required at stage exit. |
| **R** | **Required** — must exist for stage exit gate (set at a prior stage) | Agent validates existence. Gate check — do not proceed if missing. |
| **U** | **Updated** — may be refined at this stage | Agent may modify per body update protocol. Not required to change. |
| **A** | **Auto** — populated by GitHub automation | Agent does not write. May validate result. |
| **L** | **Locked** — set at an earlier stage, not modified | Agent reads only. Modification requires correction protocol. |
| **—** | **N/A** — field not relevant at this stage | Agent ignores. |

### C vs. R Distinction

**C** (Created) means the field originates at this stage — the populating agent's responsibility to write it. **R** (Required) means the field must already exist — the validating agent's gate check. An agent seeing R in its column checks for the field's presence; an agent seeing C in its column is responsible for creating it.

### Special Notations

| Notation | Meaning |
|---|---|
| **O** | Optional — field may be populated but is not gating. No gate check. |
| **C\*/U** | Create if absent, Update if present. Used for dual-origin fields where intake provides an optional initial value and a later stage creates/validates the definitive value. |
| **R/U** | Required AND may be updated. Field must exist (gate check) and may be refined. |
| **C\*/R** | Create if absent, Required (gate check) if present. Used for fields where intake provides an optional value and a later stage either creates the definitive value or validates the existing value as a gate requirement. |
| **U\*** | Updated only under specific conditions (footnoted). |

---

## Body Fields Lifecycle

| Field | Created At | Populated By | 1-In | 2-Tri | 3-Bun | 4-Plan | 5-Sol | 6-Eng | 7-DT | 8-QA | 9-PR | 12-Ex | 13-Cl |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Title | 1-Intake | Author | **C** | R | L | L | L | L | L | L | L | L | L |
| Description | 1-Intake | Author | **C** | R | L | L | L | L | L | L | L | L | L |
| Evidence | 1-Intake | Author | **C** | R | L | L | L | L | L | L | L | L | L |
| Proposed Change | 1-Intake | Author | **C** | R/U | L | U | U | L | L | L | L | L | L |
| AC | 1-Intake | Author | **C** | R/U | L | L | U | L | L | L | L | L | L |
| Priority (body) | 1 (opt) / 2 (req) | Author (opt) -> Triage Agent (req) | O | **C\**/U | R | L | L | L | U* | U* | L | L | L |
| Category (body) | 1 (opt) / 2 (req) | Author (opt) -> Triage Agent (req) | O | **C\**/U | R | L | L | L | L | L | L | L | L |
| Affected Files | 1 (opt) / 4 (req) | Author (opt) -> Planning Agent (req) | O | U | — | **C\**/U | U | L | L | L | L | L | L |
| Dependencies | 1 (opt) / 3 (req) | Author (opt) -> Triage/Bundle Agent | O | U | **C\**/R | U | L | L | L | L | L | L | L |
| Documentation Impact | 1-Intake | Author | **C** | R | L | L | U | L | L | L | L | L | R |
| Risks | 1 (opt) | Author | O | O | O | O | O | L | L | L | L | L | L |
| Notes | Any | Any | O | O | O | O | O | O | O | O | O | O | O |

**Dual-origin fields:** Priority, Category, Affected Files, and Dependencies have dual "Created At" values. The field may be optionally populated at intake (O in Stage 1) but is not gating until a later stage where the responsible agent either creates it (if absent) or validates/updates it (if present). The **C\*/U** notation means: Create if absent, Update if present.

**Priority U\* at DT/QA:** Updated only if testing reveals severity warrants escalation. Rare but permitted per body update protocol.

---

## State Anchor Fields Lifecycle

| Field | Created At | Populated By | 1-In | 2-Tri | 3-Bun | 4-Plan | 5-Sol | 6-Eng | 7-DT | 8-QA | 9-PR | 12-Ex | 13-Cl |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Status (Projects) | 1-Intake | Auto (bookends) + Agent (mid) | **A** | U | U | — | — | U | — | — | — | **A** | — |
| Stage (Projects) | 1-Intake | Agent (always, at CER Claim) | **C** | U | U | U | U | U | U | U | U | U | U |
| Priority (Projects) | 2-Triage | Triage Agent | — | **C** | L | L | L | L | U* | U* | L | L | L |
| Label — type | 1-Intake | Auto (template) | **A** | R/U | L | L | L | L | L | L | L | L | L |
| Label — cluster | 2-Triage | Triage Agent | — | **C** | R | L | L | L | L | L | L | L | L |
| Label — status | 1-Intake | Agent (atomic sync) | **C** | U | U | — | — | U | — | — | — | U | — |
| Label — lifecycle | 2-Triage (cond.) | Triage Agent | — | O | — | — | — | — | — | — | — | — | — |
| Label — work-status | — (delivery axis) | Agent or operator | — | — | — | — | — | — | — | — | — | — | — |
| Milestone | 3-Bundle | Bundle Agent | — | — | **C** | R | R | R | R | R | R | R | R |
| Assignee | 6-Engineering (typical) | Operator / Engineering Agent | — | — | — | O | — | **C\**/U | — | — | — | — | — |
| Decision Date (Projects) | 2-Triage | Triage Agent (CER Resolve) | — | **C** | R | L | L | L | L | L | L | L | L |

**Automation-handled fields:** Status (Projects) at bookends (Proposed on add, Done on close/merge) and Label — type at intake (template auto-label) are marked **A**. Per the [Automation vs. Agent Responsibility](../../release/references/specs/ticket-information-architecture.md#automation-vs-agent-responsibility) table: agents own intermediate transitions; automations own bookends. Stage (Projects) is ALWAYS agent-driven — no automation touches it.

**State anchor sync:** At transitions T1-T5, agents update Label — status and Status (Projects) atomically per the `sync_state_anchors` pattern in ticket-information-architecture.md. Both show U in the same columns because they track parallel state per ADR-1 ( dual-tracking).

**Label — work-status reads `—` across every stage BY DESIGN, not by omission.** It is the only row in this matrix that does so, so the reason is stated rather than left to be inferred as an oversight. This field tracks the **Axis-1 delivery lifecycle**, which is orthogonal to the release pipeline: it is advanced by delivery-lifecycle transitions (refinement, pull, review, acceptance), not by pipeline stage entry or exit. No pipeline stage creates it, requires it, updates it, or locks it — so no stage column can carry anything but `—`, and its absence on an issue is never a gate failure. Its "Created At" is likewise not a stage: a work item acquires the field when it enters a delivery board, which may be before, during, or entirely outside a release pipeline run. The value domain and the label projection are defined at [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) § Delivery Work-Status (Axis-1) and [`label-taxonomy.md`](../specs/label-taxonomy.md) § Work-Status Labels; the obligation to advance it — which actor, on which observable trigger — belongs to the status-maintenance contract and is cited here rather than restated.

---

## Stage Transition Gates

Each gate combines field requirements (from the matrices above) with artifact requirements (from [stage-io-contracts.md](stage-io-contracts.md)). The gate is the "Definition of Ready" for the next stage — the CER Claim phase (step 3: "Validate entry gate") reads these requirements.

For named gate definitions (Triage Readiness, Workflow Readiness, Release Readiness) with structured criteria IDs, type classifications, and self-repair actions, see [gate-criteria-spec.md](gate-criteria-spec.md). Named gates extend the structural gates below with metrics and judgment layers — they do not replace them.

**Gates are cumulative:** Each gate inherits all prior gate requirements. An issue at Stage 6 must satisfy Gates 1->2, 2->3, 3->4, and 4->5/6 requirements. The CER Claim phase validates the immediate predecessor gate, not the full chain — prior stages already validated their gates.

### Gate 1->2 (Intake -> Triage)

| Requirement | Type | Source |
|---|---|---|
| Title non-empty | Field (R) | Matrix |
| Description non-empty | Field (R) | Matrix |
| Evidence non-empty | Field (R) | Matrix |
| Proposed Change non-empty | Field (R) | Matrix |
| AC non-empty | Field (R) | Matrix |
| Status = Proposed | Anchor |  T1 |
| Stage = 1-Intake | Anchor |  T1 |
| Label `improvement` present | Anchor | Template auto-label |

### Gate 2->3 (Triage -> Bundle)

| Requirement | Type | Source |
|---|---|---|
| All Gate 1 fields present | Field (R) | Inherited |
| Priority validated (P1-P4) | Field (C at 2) | Matrix |
| Category validated | Field (C at 2) | Matrix |
| Label — cluster assigned | Anchor (C at 2) | Matrix |
| Triage decision rendered (Approve) | Artifact | I/O contracts |
| Status = Approved | Anchor |  T2 |
| No unresolved duplicates | Validation | Triage process |
| Decision Date set | Field (C at 2) | Matrix |

### Gate 3->4 (Bundle -> Planning)

| Requirement | Type | Source |
|---|---|---|
| All Gate 2 fields present | Field (R) | Inherited |
| Milestone assigned | Anchor (C at 3) | Matrix |
| Dependencies populated and validated within milestone | Field (C/R at 3) | Matrix |
| Bundle rationale posted | Artifact | I/O contracts |
| Status = Bundled | Anchor |  T3 |

### Gate 4->5 (Planning -> Solutioning)

Conditional per Stage Applicability Matrix.

| Requirement | Type | Source |
|---|---|---|
| All Gate 3 fields present | Field (R) | Inherited |
| Affected Files populated | Field (C at 4) | Matrix |
| Release plan committed on branch | Artifact | I/O contracts |
| Issue has entry in implementation sequence | Artifact | Release plan |
| Stage Applicability Matrix indicates Solutioning=YES | Routing | Release plan |

### Gate 5->6 (Solutioning -> Engineering)

| Requirement | Type | Source |
|---|---|---|
| All Gate 4 fields present | Field (R) | Inherited |
| AC refined if design changed scope | Field (U at 5) | Matrix |
| Design specs posted ("Output for Stage 6") | Artifact | I/O contracts |
| All ADR issues closed | Artifact | I/O contracts |
| Blast radius analysis complete | Artifact | I/O contracts |
| No unresolved questions in output | Validation | I/O contracts |

### Gate 4->6 (Planning -> Engineering, Solutioning Skipped)

| Requirement | Type | Source |
|---|---|---|
| All Gate 4 fields present | Field (R) | Inherited |
| Skip rationale in Stage Applicability Matrix | Artifact | I/O contracts |
| Planning-level change specs in release plan | Artifact | I/O contracts |

### Gate 6->7 (Engineering -> DevTest)

| Requirement | Type | Source |
|---|---|---|
| PR created | Artifact | pipeline/stage-06-engineering.md |
| All Engineering sub-tasks closed | Artifact | Sub-issue lifecycle  |
| Assignee set | Anchor (C at 6) | Matrix |
| Status = In Progress | Anchor |  T4 |

### Gate 7->8 (DevTest -> QA)

| Requirement | Type | Source |
|---|---|---|
| Last Dev Test pass non-blocking | Artifact | pipeline/stage-07-dev-testing.md |
| Quality review pass sub-issue closed | Artifact | Sub-issue lifecycle  |

### Gate 8->9 (QA -> Plan Review)

| Requirement | Type | Source |
|---|---|---|
| QA acceptance pass rendered | Artifact | pipeline/stage-08-qa-testing.md |
| Last QA sub-issue closed with acceptance | Artifact | Sub-issue lifecycle  |

### Gate 9->12 (Plan Review -> Execute)

| Requirement | Type | Source |
|---|---|---|
| Go/No-Go decision = Go | Decision | Operator (Tier 3) |
| Decision record comment posted | Artifact | pipeline/stage-09-plan-review.md |

### Gate 12->13 (Execute -> Close)

| Requirement | Type | Source |
|---|---|---|
| PR merged | Artifact | pipeline/stage-12-execute.md |
| Deployment log comment posted | Artifact | pipeline/stage-12-execute.md |
| Verification evidence appended | Artifact | pipeline/stage-12-execute.md |
| Status = Done | Anchor |  T5 (automation on merge) |

### Gate 13 Exit (Release Close)

| Requirement | Type | Source |
|---|---|---|
| RELEASE_LOG.md updated | Artifact | pipeline/stage-13-close.md |
| Milestone closed | Anchor | pipeline/stage-13-close.md |
| All sub-issues closed | Validation | Sub-issue lifecycle  |
| Verification evidence comment posted | Artifact | pipeline/stage-13-close.md |

---

## Relationship to I/O Contracts

The field lifecycle matrix and [stage I/O contracts](stage-io-contracts.md) are complementary, not overlapping.

| Dimension | Field Lifecycle Matrix | Stage I/O Contracts |
|---|---|---|
| **What it defines** | Issue field state per stage | Deliverable artifacts per stage boundary |
| **Granularity** | Individual fields on the issue | Artifacts (comments, files, sub-issues) |
| **Consumer** | Agent validating gates (CER Claim step 3) | Agent checking handoff completeness |
| **Update cadence** | When fields are added/removed from template | When stage boundaries are defined |

**Integration pattern:** Stage transition gates (above) reference BOTH sources — field requirements from this matrix AND artifact requirements from I/O contracts. This is the unified "Definition of Ready" per boundary. Neither source alone is sufficient.

---

## Template Alignment

The `improvement.yml` GitHub Issue template reflects intake-stage field requirements from the matrix. Fields marked **C** (Created) at Stage 1 are template-required; fields marked **O** (Optional) at Stage 1 are template-optional.

| Template Field | Matrix Value at Stage 1 | Template Required | Rationale |
|---|---|---|---|
| Description | C | Yes | Triage needs this to evaluate the issue |
| Evidence | C | Yes | Triage needs this to evaluate the issue |
| Proposed Change | C | Yes | Triage needs this to evaluate the issue |
| AC | C | Yes | Triage needs this to evaluate the issue |
| Priority | O | No | Intake authors estimate; triage validates against full backlog context |
| Category | O | No | Intake authors may not know the category taxonomy; triage applies after content analysis |
| Affected Files | O | No | Requires codebase knowledge intake authors may not have; Planning defines precise affected files |
| Dependencies | O | No | Authors may know some deps; triage/bundle discovers full dependency graph |
| Documentation Impact | C | Yes | Author declares pointer-list of impacted K1 docs (link/create/update) OR explicit `None — no documentation impact (rationale: <phrase>)`. Per ; resolution gate at Stage 13 G-CL8. Applies to all issues entering Stage 1 going forward. |
| Risks | O | No | Author-declared risks and cross-cutting concerns; "None identified" is the explicit-check signal |
| Notes | O | No | Additional context, always optional |

---

## Methodology Variation — Field Semantics

The field-lifecycle matrix above is methodology-agnostic at the structural level — every field has a defined Create/Optional/Read-Only lifecycle regardless of `delivery_approach`. What varies by [Methodology](../specs/terminology-glossary.md#term-methodology) is the *semantic interpretation* of specific fields. The table below covers fields whose semantics diverge per archetype; all other fields inherit the default semantic definition in §Field Reference above.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Kanban** | `Priority` field is interpreted as **class-of-service** (Expedite / Standard / Fixed-Date / Intangible), not ordinal P1-P4 urgency. `Dependencies` field expresses pull-readiness (is this card unblocked for pull?), not gate-chain sequencing. `Decision Date` is rolling; no batch-gate decisions. | `Priority`, `Dependencies`, `Decision Date` | [SOURCE] Kanban Method — class-of-service categorization. |
| **Waterfall** | `Priority` field maps to **schedule criticality** (critical-path vs. float-path), not business-value. `Dependencies` field expresses **phase-gate chains** (Requirements → Design → Build → Test → Deploy) with formal change-control on backflow. `Decision Date` is gate-bound (next phase-gate review). | `Priority`, `Dependencies`, `Decision Date` | [SOURCE] PMBOK predictive scheduling — critical path method. |
| **Scrum / XP** | `Priority` field is **ordinal sprint-priority** (P1 = top of backlog at sprint planning). `Dependencies` field expresses sprint-ordering constraints within or across sprints. `Decision Date` is sprint-bound (next sprint planning session). | `Priority`, `Dependencies`, `Decision Date` | [SOURCE] Scrum Guide 2020 — product backlog ordering. |
| **PRINCE2** | `Priority` field maps to **MoSCoW** (Must-have / Should-have / Could-have / Won't-have) per PRINCE2 prioritisation principles. `Dependencies` field expresses stage-boundary chains; decisions gate-bound to end-stage-assessment. | `Priority`, `Dependencies`, `Decision Date` | [SOURCE] PRINCE2 2017 — MoSCoW prioritisation. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive field semantics from declared `lifecycle`, `ceremonies`, `artifacts`, `cadence` fields. `lifecycle: continuous` → Kanban-style interpretation; `lifecycle: phased` → Waterfall-style; `lifecycle: timeboxed` → Scrum-style. | `Priority`, `Dependencies`, `Decision Date` | [SOURCE] [`methodology-parameterization-v1.md § Skill Consumption Pattern`](../../release/references/specs/methodology-parameterization-v1.md). |
| **All other fields + archetypes (inherit default semantics)** | Fields not named above (Title, Description, Evidence, AC, Affected Files, Risks, Notes, Category, Proposed Change) have archetype-agnostic semantics. Archetypes not named above (SAFe, Hybrid) inherit the closest named archetype's semantics per their composition (SAFe inherits Scrum at sprint-level + Waterfall at PI-planning level; Hybrid inherits per-phase). | All other fields | [INFERRED] — structural invariants preserved across archetypes. |

**Consumer guidance.** Agents reading/writing these fields MUST consult this table when `delivery_approach ≠ Scrum` (platform-default baseline), and default to Scrum-style interpretation otherwise. `tracker-manager` and `delivery-engine` are the primary consumers of the Priority + Dependencies + Decision Date semantic divergence.
