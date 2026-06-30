---
title: Entity Lifecycle Protocol — Project-Scoped Entities (G8)
purpose: The G8 entity-lifecycle-automation protocol for project-scoped entities — the lifecycle states, transitions, and write-authority for per-project entities in the project-data-architecture layer.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the G8 entity-lifecycle-automation layer; entity-field-lifecycle-matrix.md; agents writing project-scoped entity records in the project-data layer
---
# Entity Lifecycle Protocol — Project-Scoped Entities (G8)

**Status:** Canonical (Stage 6 Engineering until merged)
**Owner:** `core/standards/entity-lifecycle-protocol.md`
**Introduced:** v2.20 `13-field-lifecycle-and-cmdb-automation` — initiative project-data-architecture (the L3 G8 entity-lifecycle-automation layer)
**Establishing issue:** the project-scoped entity-lifecycle transition protocol work item.
**Architectural basis:** the Two-Axis Entity Lifecycle ADR (RATIFIED). G1 (`core/disciplines/project-entity-model.md`) froze *what* entities + Axis-1 machines exist; G2 (`core/schemas/entity-field-schemas.md`) froze *how* fields validate. **Neither says who triggers which transition, on what evidence, with what side-effect, and what is forbidden — that is this protocol.**
**Co-lock:** the shared+portfolio tier (entities 10–17) is the format-identical companion `core/standards/entity-lifecycle-protocol-shared-portfolio.md` (its own establishing work item). Both docs use the identical 5-column transition-table format defined in §2.

---

## §1 Purpose & Boundary

This protocol states, **per project-scoped entity, who triggers which Axis-1 transition on what evidence with what side-effect, and what is forbidden.** It transcribes (does **NOT** redesign) the FROZEN Axis-1 machines in `core/disciplines/project-entity-model.md §4`. State sets are **verbatim**; any change requires reopening the establishing issue via a Tier-2 SCOPE CHANGE per the Inter-Stage Feedback Protocol.

**Scope — 10 project-scoped entities** (`project-entity-model.md §7` tier-1): Project (entity 1), Milestone (entity 2), Workstream (entity 3), Plan (entity 4), Decision (entity 5), RAID Item (entity 6), Meeting (entity 7), Resource (entity 8), Artifact (entity 9), and Work Item (entity 18). The shared+portfolio tier (entities 10–17) is the sibling doc.

**This is transcription, not design.** Every state set is copied verbatim from `project-entity-model.md §4` Axis-1 lines; every triggering agent from §6 the owning-agent matrix; every cascade from §5.1 the directed chains. No new or aliased states — that would breach the entity-model freeze and the `lifecycle-states-canonical.md §5` collision map.

**Cross-references:** `project-entity-model.md` §4 (Axis-1 machines) / §5.1 (directed chains) / §6 (owning-agent matrix); `entity-field-schemas.md` §5 (create-time field supply); `lifecycle-states-canonical.md` §2 (the `<Object>-<State>` convention) / §3.2 (the Artifact Workflow machine).

## §2 The shared 5-column transition-table FORMAT (canonical)

Each entity gets one Axis-1 transition table. **Each row = one directed transition.** The table holds the entity's **valid** transitions; forbidden pairs are enumerated in the per-entity **"Forbidden transitions"** mini-block carrying the `[INVALID-TRANSITION]` marker. The five columns are:

| Column | Content | Frozen source |
|---|---|---|
| **From → To** | `from-state → to-state` using the Axis-1 enum **verbatim** | `project-entity-model.md §4` Axis-1 line for the entity |
| **Triggering agent** | the skill that fires the transition — the **maintainer** (§6 *Maintains*) fires intermediate transitions; the **creator** (§6 *Creates*) fires only the create-entry transition; readers never fire | `project-entity-model.md §6` owning-agent matrix |
| **Qualifying evidence** | the observable precondition that authorizes the transition (the artifact / field / event that must be present) | grounded in `entity-field-schemas.md §5` create-time-supply + the entity's required fields |
| **Side-effects** | downstream writes the transition causes (relationship-edge creation, sibling-record generation, comms-entry, audit-trail append) — citing **only** frozen `§5.1` chains for cross-entity effects | `project-entity-model.md §5.1` directed chains |
| **Marker** | `valid` for a defined transition; `[INVALID-TRANSITION]` tags any from→to pair NOT in the entity's machine (a fired-but-unqualified transition is the same marker) | net-new convention this protocol originates |

**Format-identity contract:** this header row is **byte-pattern-identical** to the header in `core/standards/entity-lifecycle-protocol-shared-portfolio.md`. Both docs share this exact 5-column schema (the project-scoped ∥ shared+portfolio co-lock); the downstream skill-integration work item consumes the two table sets uniformly.

**Authoring rule:** the From-state column may only contain states that appear in the §4 Axis-1 line for that entity; the To-state column likewise. Any cell pairing two states with no arrow between them in §4 is authored as a single `[INVALID-TRANSITION]` row in the per-entity "Forbidden transitions" mini-block — never invented as a new edge. Terminal-state forbidden-exit rows (e.g. `CLOSED → *`, `closed → *`, `cancelled → *`) are `[INVALID-TRANSITION]` by construction.

**Object-typing:** cross-machine prose uses the object-typed `<Entity>-<state>` form per `lifecycle-states-canonical.md §2.1` (e.g. `Milestone-completed`, `RAIDItem-closed`, `Plan-superseded`); bare state names are used only inside this doc's own table cells / YAML per §2.2.

---

## §3 The 10 project-scoped Axis-1 transition tables

States are **VERBATIM** from `project-entity-model.md §4` (the `**Axis-1:**` line of each entity). Triggering agent = the §6 *Maintains* column (intermediate transitions) / *Creates* column (the create-entry row). Side-effects cite only frozen §5.1 chains.

### §3.1 Project (entity 1)

Axis-1 (verbatim §4): `ACTIVE → CLOSING → CLOSED` · creates `project-initiator` · maintains `ppm-agent`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `ACTIVE` | project-initiator (create) | Project record created; `project_name` / `project_owner` / `status` / `delivery_approach` supplied (§4 entity 1 required fields) | audit-trail append; the Project is the anchor every project-scoped `project_id` resolves to | valid |
| `ACTIVE` → `CLOSING` | ppm-agent | Evidence the project is entering hypercare/transition (go-live reached; closure initiated) | reduced-cadence processing per CLAUDE.md §Project Lifecycle; readers `daily-status` / `weekly-status-rollup` re-read | valid |
| `CLOSING` → `CLOSED` | ppm-agent | Evidence transition is complete (hypercare exited; knowledge transfer done) | terminal — read-only reference; no operational processing | valid |

**Forbidden transitions (entity 1):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `ACTIVE` → `CLOSED` | — | — | — | `[INVALID-TRANSITION]` (must pass through `CLOSING` — no skip) |
| `CLOSED` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.2 Milestone (entity 2)

Axis-1 (verbatim §4): `planned → in-progress → completed | cancelled` · creates `release-planner` · maintains `delivery-engine`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `planned` | release-planner (create) | Milestone record created; `milestone_name` / `project_id` / `target_date` supplied (§4 entity 2) | audit-trail append | valid |
| `planned` → `in-progress` | delivery-engine | Evidence work on the milestone has begun (target_date approaching; first deliverable started) | `weekly-status-rollup` reader re-reads | valid |
| `in-progress` → `completed` | delivery-engine | `actual_date` set (≤ today); any `RAID Item —BLOCKS→` this Milestone (§5.1 chain 9) is `resolved`/`closed` first | `weekly-status-rollup` reader re-reads; the BLOCKS precondition is the qualifying-evidence gate, not a fired cascade | valid |
| `in-progress` → `cancelled` | delivery-engine | Operator/owner decision to cancel the milestone | terminal; readers re-read | valid |

**Forbidden transitions (entity 2):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `planned` → `completed` | — | — | — | `[INVALID-TRANSITION]` (must pass through `in-progress`) |
| `completed` → `in-progress` | — | — | — | `[INVALID-TRANSITION]` (terminal-ish reopen) |
| `cancelled` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.3 Workstream (entity 3)

Axis-1 (verbatim §4): `active → paused → closed` · creates `ppm-agent` · maintains `ppm-agent`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `active` | ppm-agent (create) | Workstream record created; `workstream_name` / `project_id` supplied (§4 entity 3) | audit-trail append | valid |
| `active` → `paused` | ppm-agent | Evidence the stream is on hold (lead reassigned; dependency stall) | readers `delivery-engine` / `daily-status` re-read | valid |
| `paused` → `active` | ppm-agent | Evidence the stream resumes | readers re-read | valid |
| `active` → `closed` | ppm-agent | Evidence the stream's work is complete | terminal | valid |

**Forbidden transitions (entity 3):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `active` → `closed` (skipping a defined intermediate) is itself defined above; `paused` → `closed` | — | — | — | `[INVALID-TRANSITION]` (`closed` is reachable only from `active`; a paused stream re-activates before closing) |
| `closed` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.4 Plan (entity 4)

Axis-1 (verbatim §4): `draft → approved → active → superseded → archived` (= Domain-A Baselined machine) · creates `artifact-generator` · maintains `ppm-agent`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `draft` | artifact-generator (create) | Plan record created; `plan_title` / `plan_type` / `project_id` supplied (§4 entity 4) | audit-trail append | valid |
| `draft` → `approved` | ppm-agent | Operator approval recorded (Baselined Domain-A gate) | readers `implementation-planner` re-read | valid |
| `approved` → `active` | ppm-agent | `version` set + the plan is made the live baseline | a prior `active` Plan carrying a `SUPERSEDES` edge (§5.1 chain 5) transitions `active → superseded` — see Cascade C2 / §4 | valid |
| `active` → `superseded` | ppm-agent | A successor Plan with a `SUPERSEDES` edge to this one is activated (§5.1 chain 5) | comms-entry emitted (the superseded plan must be communicated) | valid |
| `superseded` → `archived` | ppm-agent | Retention policy reached; the plan is no longer current | terminal; `Trust-historical-record` per `frontmatter-schema.md §Category 5` | valid |

**Forbidden transitions (entity 4):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `draft` → `active` | — | — | — | `[INVALID-TRANSITION]` (skips `approved`) |
| `archived` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.5 Decision (entity 5)

Axis-1 (verbatim §4): `proposed → accepted → reversed | superseded` · creates `ppm-agent` · maintains `tracker-manager`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `proposed` | ppm-agent (create) | Decision record created; `decision_statement` / `decided_date` / `project_id` supplied (§4 entity 5); MAY be `GENERATES`-emitted by a held Meeting (§5.1 chain 6) | if generated by a Meeting, a `GENERATES` edge Meeting→Decision is written — see Cascade C1 | valid |
| `proposed` → `accepted` | tracker-manager | Decision ratified (decider recorded; rationale captured) | if this Decision carries a `SUPERSEDES` edge to a prior `accepted` Decision (§5.1 chain 5 self-edge), that prior Decision transitions `accepted → superseded` — see Cascade C2 | valid |
| `accepted` → `reversed` | tracker-manager | Evidence the decision is undone (reversal recorded) | comms-entry emitted; readers `comms-writer` / `weekly-status-rollup` consume | valid |
| `accepted` → `superseded` | tracker-manager | A successor Decision with a `SUPERSEDES` edge to this one is accepted (§5.1 chain 5) | comms-entry emitted (the superseded decision must be communicated) | valid |

**Forbidden transitions (entity 5):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `proposed` → `reversed` / `proposed` → `superseded` | — | — | — | `[INVALID-TRANSITION]` (a proposed-then-dropped decision is a create-time concern; reversal/supersession act on `accepted` only) |
| `reversed` → any / `superseded` → any | — | — | — | `[INVALID-TRANSITION]` (both terminal resolutions) |

### §3.6 RAID Item (entity 6)

Axis-1 (verbatim §4): `open → in-progress → mitigating → resolved → closed` · creates `ppm-agent` · maintains `tracker-manager`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `open` | ppm-agent (create) | RAID record created; `raid_type` / `summary` / `project_id` / `owner_person_id` / `impact` supplied (§4 entity 6 + §5 create-supply); MAY be `GENERATES`-emitted by a held Meeting (§5.1 chain 7) | if generated by a Meeting, a `GENERATES` edge Meeting→RAID Item is written — see Cascade C1 | valid |
| `open` → `in-progress` | tracker-manager | `owner_person_id` resolves to a live Person **and** `action_plan` present (the in-progress qualifier) | audit-trail append; no cross-entity edge | valid |
| `in-progress` → `mitigating` | tracker-manager | Evidence mitigation is underway (mitigation actions executing) | audit-trail append | valid |
| `mitigating` → `resolved` | tracker-manager | Evidence the risk/issue is mitigated (impact closed out) | any `RAID Item —BLOCKS→ Milestone` (§5.1 chain 9) is cleared as a precondition for that Milestone's completion | valid |
| `resolved` → `closed` | tracker-manager | Closure recorded (no residual action) | terminal | valid |

**Forbidden transitions (entity 6):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `open` → `resolved` | — | — | — | `[INVALID-TRANSITION]` (skips `in-progress` / `mitigating`) |
| `closed` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.7 Meeting (entity 7)

Axis-1 (verbatim §4): `scheduled → held | cancelled` · creates `file-router` · maintains `ppm-agent`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `scheduled` | file-router (create) | Meeting record created; `meeting_title` / `meeting_date` / `project_id` supplied (§4 entity 7) | audit-trail append | valid |
| `scheduled` → `held` | ppm-agent | Transcript / minutes routed by `file-router` (the held-meeting evidence) | the held Meeting MAY `GENERATES`-emit child Decision (`proposed`) / RAID Item (`open`) / Artifact records (§5.1 chains 6/7/8), each with a `GENERATES` edge Meeting→child — see Cascade C1 | valid |
| `scheduled` → `cancelled` | ppm-agent | Evidence the meeting did not occur (cancelled / no-show) | terminal | valid |

**Forbidden transitions (entity 7):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `held` → any / `cancelled` → any | — | — | — | `[INVALID-TRANSITION]` (both terminal — `held` and `cancelled` are the two parallel terminal resolutions of `scheduled`) |

### §3.8 Resource (entity 8)

Axis-1 (verbatim §4): `planned → active → released` · creates `delivery-engine` · maintains `delivery-engine`

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `planned` | delivery-engine (create) | Resource (allocation) record created; `person_id` / `project_id` / `allocation_pct` / `role_on_project` supplied (§4 entity 8); `RELATES_TO` Person edge (§5.1 chain 12) set | a `RELATES_TO` edge Resource→Person is written | valid |
| `planned` → `active` | delivery-engine | `period_start` reached; the allocation is live | `weekly-status-rollup` reader re-reads; over-claim of the same Person across ≥2 projects may surface a Cross-Project Resource Conflict (entity 16, shared+portfolio tier) | valid |
| `active` → `released` | delivery-engine | `period_end` reached or the allocation ends | terminal; the `RELATES_TO Person` edge remains for historical record | valid |

**Forbidden transitions (entity 8):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `planned` → `released` | — | — | — | `[INVALID-TRANSITION]` (must pass through `active`) |
| `released` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.9 Artifact (entity 9) — delegation rule (NOT a standalone table)

Artifact's Axis-1 **delegates to Axis-2** (§4 entity 9 + §9 the reconciliation seam): the Artifact's operational `lifecycle_state` **is** the Domain A/B/C content lifecycle of its backing file. This protocol does **NOT** invent a standalone Artifact transition table — it documents the delegation rule and points at the canonical Artifact-Workflow machine.

- **Delegation rule:** Artifact `lifecycle_state` = the `frontmatter-schema.md §Cat-2` Domain A/B/C machine for the backing file's `domain`. For the agent-generated artifact workflow this is the canonical `lifecycle-states-canonical.md §3.2` machine: `Artifact-DRAFT → Artifact-REVIEWED → Artifact-APPROVED → Artifact-PROMOTED → Artifact-ARCHIVED` (object-typed form per §2.1). Creator `artifact-generator` (sets entry state on create); maintainer `ppm-agent` (route `file-router`); readers all PMO skills.
- **Why no standalone table:** authoring an independent Artifact Axis-1 machine would duplicate (and risk diverging from) the §3.2 vocabulary, breaching duplicate-source-discipline and the boundary axiom. The Artifact entity's lifecycle is its file's Domain lifecycle by construction.
- **Reconciliation seam (Axis-1 ↔ Axis-2):** the precise reconciliation of the three adjacent artifact-state expressions — this entity Axis-1 delegation · the `§3.2` Artifact-Workflow machine · the frontmatter-schema Category-2 Domain A/B/C pattern — into a single `artifact_state` mapping is the **Wave 0b** reconciliation deliverable (the artifact-state reconciliation work items) and is owned by the Artifact Axis-1↔Axis-2 delegation seam tracked under its dedicated work item. This protocol documents the delegation; it does not author the mapping.

### §3.10 Work Item (entity 18) — base machine only

Axis-1 (verbatim §4): `backlog → ready → in-progress → in-review → done | cancelled` (generic base machine) · creates `intake-desk` · maintains `delivery-engine`

This protocol transcribes the **base** machine only. Per-type sub-states (Story / Bug / Test / Task) live in the declarative **C2 type-pack layer** — an EXTERNAL, OPEN registry. The protocol notes the extension point but does **not** enumerate type sub-states (that would breach the §4 entity 18 open-set boundary).

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `backlog` | intake-desk (create) | Work Item created; `work_item_type` discriminator + polymorphic `parent_ref` (`BELONGS_TO` → Milestone.id OR Workstream.id) supplied (§4 entity 18) | a `BELONGS_TO` rollup edge Work Item→Milestone (§5.1 chain 17) is written; status rolls up to the container | valid |
| `backlog` → `ready` | delivery-engine | DoR (Definition-of-Ready) gate passes | audit-trail append | valid |
| `ready` → `in-progress` | delivery-engine | Work started (sprint commitment / assignment) | readers `ppm-agent` / `daily-status` / `weekly-status-rollup` re-read | valid |
| `in-progress` → `in-review` | delivery-engine | Work submitted for review | audit-trail append | valid |
| `in-review` → `done` | delivery-engine | DoD (Definition-of-Done) gate passes | terminal; rollup to the parent container updates | valid |
| `in-progress` → `cancelled` / `ready` → `cancelled` / `backlog` → `cancelled` | delivery-engine | Work descoped before completion | terminal | valid |

**Extension point (C2 type-pack — OPEN, out-of-scope here):** the type-pack layer projects methodology labels onto this base machine and MAY add type-scoped sub-states over it; those sub-states are NOT enumerated here.

**Forbidden transitions (entity 18):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `backlog` → `in-progress` / `ready` → `in-review` / `in-progress` → `done` | — | — | — | `[INVALID-TRANSITION]` (no skip over a base intermediate) |
| `done` → any / `cancelled` → any | — | — | — | `[INVALID-TRANSITION]` (both terminal) |

---

## §4 Cross-entity cascade chains

Cascades reference **ONLY** frozen `project-entity-model.md §5.1` chains. The protocol does NOT invent a cross-entity edge that is not in §5.1. The `BLOCKS` relationship (§5.1 chain 9) is a **precondition that gates** a transition (surfaced as qualifying-evidence on the blocked entity's transition — see the Milestone `in-progress → completed` and RAID Item `mitigating → resolved` rows), **not** a cascade that fires one — keeping the §5.1 edge direction intact.

### Cascade C1 — Meeting `GENERATES` Decision / RAID Item / Artifact (§5.1 chains 6 / 7 / 8)

When Meeting `scheduled → held` fires (trigger `ppm-agent`; evidence = transcript / minutes routed by `file-router`), the held Meeting MAY `GENERATES`-emit child records:

- Decision records (created `proposed`; creator `ppm-agent`) — §5.1 chain 6.
- RAID Item records (created `open`; creator `ppm-agent`) — §5.1 chain 7.
- Artifact records (created at their entry state; creator `artifact-generator`) — §5.1 chain 8.

**Side-effect:** for each generated child, a `GENERATES` relationship edge Meeting→child is written, and the child enters its own Axis-1 at the entry state. This is the meeting → decision-package chain at entity granularity (§4 entity 7 rationale).

### Cascade C2 — Decision / Plan `SUPERSEDES` predecessor → comms-entry (§5.1 chain 5)

When a successor record is activated/accepted and it carries a `SUPERSEDES` edge to a prior live record, the predecessor transitions to `superseded`:

- **Decision:** when a Decision `proposed → accepted` fires carrying a `SUPERSEDES` edge to a prior `accepted` Decision, the prior Decision transitions `accepted → superseded` (trigger `tracker-manager`). **Side-effect:** a comms-entry is emitted (the superseded decision must be communicated); readers `comms-writer` + `weekly-status-rollup` (§6) consume it.
- **Plan:** the same `SUPERSEDES`-cascade shape governs Plan→Plan (§5.1 chain 5): activating a successor Plan transitions the prior `active` Plan to `superseded` with the same comms-entry side-effect (see §3.4).

**Cascade authoring discipline:** both cascades are drawn verbatim from §5.1 (project-scoped chains 5/6/7/8). No cross-entity edge outside §5.1 is asserted — in particular, RAID-resolution does **not** auto-close a Milestone (chain 9 `BLOCKS` *gates* the Milestone transition as a precondition; it does not fire it).

---

## §5 Downstream handoff — §3 registration is FLAGGED, NOT executed

The registration of the entity Axis-1 state-machine family into `core/standards/lifecycle-states-canonical.md §3` is the downstream **operator-gated G8 / G10 governance touch** (Autonomy Tier 0). It is **declared here, NOT executed.**

- `project-entity-model.md §2` (Out of scope) + `§3` Axis-1 naming note already forward-defer this: *"Registration of the entity state-machine family into `lifecycle-states-canonical.md §3` is a downstream governed change owned by G8 / G10 — flagged here, NOT executed."*
- `lifecycle-states-canonical.md §8` Change Protocol: modifications to its §2/§3/§4/§5 require an Issue + plan + approval per CLAUDE.md "No ungoverned changes" — an operator-gated Autonomy-Tier-0 touch.
- **Forward-binding now (prose only):** this protocol uses the object-typed `<Entity>-<state>` convention (`lifecycle-states-canonical.md §2.1`) for all cross-machine prose — e.g. `Milestone-completed`, `RAIDItem-closed`, `Plan-superseded` — which protects against the `archived` 4-way collision and the `closed` / `active` cross-machine clashes (§5 collision map) **without** writing the §3 registration row. The §3 registration row + §5 collision-map update are left to the future G8/G10 governed change.

**This protocol writes ZERO changes to `core/standards/lifecycle-states-canonical.md`.**

---

## §6 Acceptance (grep-AC)

- `test -f core/standards/entity-lifecycle-protocol.md` — exists.
- For each of the 10 entities (1–9 + 18): its verbatim §4 Axis-1 state set appears, and a transition table with ≥3 valid rows is present (Artifact, entity 9, is the delegation rule, not a standalone table).
- State-set fidelity: every state token used appears in the corresponding `project-entity-model.md §4` Axis-1 line — zero new/aliased tokens.
- `grep -c "\[INVALID-TRANSITION\]" core/standards/entity-lifecycle-protocol.md` ≥ 10 (≥1 forbidden row per entity with a state machine).
- `grep "GENERATES\|SUPERSEDES" core/standards/entity-lifecycle-protocol.md` resolves to Cascade C1 / C2 (≥2 cascades).
- `git diff` shows **zero** changes to `core/standards/lifecycle-states-canonical.md` (the §3 registration is FLAGGED, not executed).
- **Format-identity check:** the §2 5-column table header in this doc === the header in `core/standards/entity-lifecycle-protocol-shared-portfolio.md` (byte-identical column set).
