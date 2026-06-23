# Entity Lifecycle Protocol — Shared + Portfolio Entities (G8)

**Status:** Canonical (Stage 6 Engineering until merged)
**Owner:** `core/standards/entity-lifecycle-protocol-shared-portfolio.md`
**Introduced:** v2.20 `13-field-lifecycle-and-cmdb-automation` — initiative project-data-architecture (the L3 G8 entity-lifecycle-automation layer)
**Establishing issue:** the shared+portfolio entity-lifecycle transition protocol work item.
**Architectural basis:** the Two-Axis Entity Lifecycle ADR (RATIFIED). This protocol transcribes (does **NOT** redesign) the FROZEN Axis-1 machines in `core/disciplines/project-entity-model.md §4` (entities 10–17). State sets are **verbatim**; any change requires reopening the establishing issue via a Tier-2 SCOPE CHANGE.
**Co-lock:** the project-scoped tier (entities 1–9 + 18) is the format-identical companion `core/standards/entity-lifecycle-protocol.md` (its own establishing work item). Both docs use the identical 5-column transition-table format defined in §2 — this doc is **co-located in `core/standards/`** with the project-scoped protocol per the operator directive.

---

## §1 Purpose & Boundary

This protocol is the tier-(b) companion to the project-scoped protocol: it states, **per shared + portfolio entity, who triggers which Axis-1 transition on what evidence with what side-effect, and what is forbidden.** It wires the **8 already-FROZEN Axis-1 machines** (`project-entity-model.md §4`, roster entities 10–17) into a per-entity transition protocol.

**Scope — 8 shared + portfolio entities**, partitioned by `storage_tier` so no entity straddles the project-scoped (10 entities) / shared+portfolio (8 entities) boundary:

- **Cross-project-shared** (`storage_tier: cross-project-shared → _pmo/`): Person (entity 10), System (entity 11), Vendor (entity 12).
- **Portfolio-level** (`storage_tier: portfolio-level → projects/_config/`): Portfolio (entity 13), Program (entity 14), Cross-Project Dependency (entity 15), Cross-Project Resource Conflict (entity 16), Strategic Initiative (entity 17).

**This is transcription, not design.** Every state set is copied verbatim from `project-entity-model.md §4` Axis-1 lines (entities 10–17); every triggering agent from §6 the owning-agent matrix (the *Maintains* column fires lifecycle transitions; the *Creates* agent fires only the create-entry transition); every side-effect cites only frozen §5.1 chains.

**Cross-references:** `project-entity-model.md` §4 (Axis-1 machines entities 10–17) / §5.1 (directed chains) / §6 (owning-agent matrix); `lifecycle-states-canonical.md` §2 (the `<Object>-<State>` convention) / §3 (the registration target).

## §2 The shared 5-column transition-table FORMAT (canonical)

Each entity gets one Axis-1 transition table. **Each row = one directed transition.** The table holds the entity's **valid** transitions; forbidden pairs are enumerated in the per-entity **"Forbidden transitions"** mini-block carrying the `[INVALID-TRANSITION]` marker. The five columns are:

| Column | Content | Frozen source |
|---|---|---|
| **From → To** | `from-state → to-state` using the Axis-1 enum **verbatim** | `project-entity-model.md §4` Axis-1 line for the entity |
| **Triggering agent** | the skill that fires the transition — the **maintainer** (§6 *Maintains*) fires intermediate transitions; the **creator** (§6 *Creates*) fires only the create-entry transition; readers never fire | `project-entity-model.md §6` owning-agent matrix |
| **Qualifying evidence** | the observable precondition that authorizes the transition (the artifact / field / event that must be present) | grounded in `entity-field-schemas.md §5` create-time-supply + the entity's required fields |
| **Side-effects** | downstream writes the transition causes (relationship-edge creation, sibling-record generation, comms-entry, audit-trail append) — citing **only** frozen `§5.1` chains for cross-entity effects | `project-entity-model.md §5.1` directed chains |
| **Marker** | `valid` for a defined transition; `[INVALID-TRANSITION]` tags any from→to pair NOT in the entity's machine (a fired-but-unqualified transition is the same marker) | net-new convention this protocol originates |

**Format-identity contract:** this header row is **byte-pattern-identical** to the header in `core/standards/entity-lifecycle-protocol.md`. Both docs share this exact 5-column schema (the project-scoped ∥ shared+portfolio co-lock); the downstream skill-integration work item consumes the two table sets uniformly.

**Authoring rule:** the From-state column may only contain states that appear in the §4 Axis-1 line for that entity; the To-state column likewise. Any cell pairing two states with no arrow between them in §4 is authored as a single `[INVALID-TRANSITION]` row in the per-entity "Forbidden transitions" mini-block — never invented as a new edge. Identity entities (Person / System / Vendor) carry a referential-integrity FLAG on inbound dependents as their side-effect, never an auto-cascade.

**Object-typing:** cross-machine prose uses the object-typed `<Entity>-<state>` form per `lifecycle-states-canonical.md §2.1` (e.g. `Program-closed`, `Portfolio-archived`, `StrategicInitiative-active`); bare state names are used only inside this doc's own table cells / YAML per §2.2.

---

## §3 The 8 shared + portfolio Axis-1 transition tables

States are **VERBATIM** from `project-entity-model.md §4` (entities 10–17). Triggering agent = the §6 *Maintains* column (intermediate transitions) / *Creates* column (the create-entry row). Side-effects cite only frozen §5.1 chains.

### §3.1 Person (entity 10)

Axis-1 (verbatim §4): `active → inactive` · creates `project-initiator` / `file-router` · maintains `ppm-agent` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `active` | project-initiator / file-router (create) | Person record created in `_pmo/` (new global identity); `full_name` / `person_id` / `primary_role` supplied (§4 entity 10) | — (identity entity; no outbound frozen §5.1 chain) | valid |
| `active` → `inactive` | ppm-agent | Evidence the person is no longer an active participant across all projects (departure / role-end) | **Referential-integrity FLAG, not cascade:** inbound `ASSIGNED_TO` (§5.1 chain 10 RAID Item→Person, chain 11 Decision→Person) and `RELATES_TO` (chain 12 Resource→Person, chain 14 Cross-Project Resource Conflict→Person) dependents are flagged for each dependent's maintainer; deactivation does NOT auto-mutate dependents | valid |
| `inactive` → `active` | ppm-agent | Evidence of re-activation (person returns to an active role) | inbound dependents re-validate against the re-activated identity | valid |

**Forbidden transitions (entity 10):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `active` → `active` (self / skip) and any other unlisted pair | — | — | — | `[INVALID-TRANSITION]` (only `active↔inactive` are defined) |

### §3.2 System (entity 11)

Axis-1 (verbatim §4): `active → deprecated → retired` · creates `ppm-agent` · maintains `ppm-agent` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `active` | ppm-agent (create) | System record created in `_pmo/` (ERP / data platform / integration bus etc.); `system_name` / `system_id` supplied (§4 entity 11) | — (no outbound frozen §5.1 chain; read by `pmo-technical-analyst`) | valid |
| `active` → `deprecated` | ppm-agent | Evidence the system is being phased out (successor named / sunset announced) | `pmo-technical-analyst` readers see deprecated status; no frozen graph cascade | valid |
| `deprecated` → `retired` | ppm-agent | Evidence the system is fully decommissioned (no longer in use) | terminal | valid |

**Forbidden transitions (entity 11):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `active` → `retired` | — | — | — | `[INVALID-TRANSITION]` (must pass through `deprecated`) |
| `retired` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

> **DOWNSTREAM CROSS-LINK (Stage 6):** entity **System (entity 11)** (`active → deprecated → retired`) is the lifecycle machine the per-project-CMDB / skills-as-CIs work (restored to full Artifact-Register + skill-CMDB scope, single-registry) reuses to model skill Configuration Items. That work item's Stage 5 / ADR-038 (reconciling ADR-035 / ADR-019 / ADR-007 under the single-skill-registry constraint) binds to THIS frozen machine rather than minting a parallel CI-state set. Flagged, not designed here (out of this protocol's scope).

### §3.3 Vendor (entity 12)

Axis-1 (verbatim §4): `active → inactive` · creates `ppm-agent` · maintains `ppm-agent` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `active` | ppm-agent (create) | Vendor record created in `_pmo/` (external supplier identity); `vendor_name` / `vendor_id` supplied (§4 entity 12) | — (no outbound frozen §5.1 chain; read by `change-management`) | valid |
| `active` → `inactive` | ppm-agent | Evidence the vendor relationship has ended / supplier no longer engaged | `change-management` readers see inactive status; no frozen graph cascade | valid |
| `inactive` → `active` | ppm-agent | Evidence of re-engagement | — | valid |

**Forbidden transitions (entity 12):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| any other unlisted pair | — | — | — | `[INVALID-TRANSITION]` (only `active↔inactive` are defined) |

### §3.4 Portfolio (entity 13)

Axis-1 (verbatim §4): `active → archived` · creates `weekly-status-rollup` · maintains `weekly-status-rollup` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `active` | weekly-status-rollup (create) | Portfolio record created in `projects/_config/` (top-level grouping); `portfolio_name` / `portfolio_id` / `portfolio_owner` supplied (§4 entity 13) | — (Portfolio is the root; it is the TARGET of §5.1 chain 1 Project→Portfolio `BELONGS_TO` and chain 15 Program→Portfolio `BELONGS_TO`, never a source) | valid |
| `active` → `archived` | weekly-status-rollup | Evidence the portfolio is wound down (all member programs / projects closed/archived) | **Pre-condition FLAG, not cascade:** inbound `BELONGS_TO` members (chain 1 Projects, chain 15 Programs) should be terminal first; archiving raises an integrity flag if any active member `BELONGS_TO` this portfolio | valid |

**Forbidden transitions (entity 13):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `archived` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.5 Program (entity 14)

Axis-1 (verbatim §4): `active → closing → closed` · creates `weekly-status-rollup` · maintains `weekly-status-rollup` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `active` | weekly-status-rollup (create) | Program record created in `projects/_config/`; `program_name` / `program_id` / `portfolio_id` / `program_owner` supplied (§4 entity 14); OR generated by a Strategic Initiative (§5.1 chain 16) | inbound `GENERATES` from Strategic Initiative (chain 16 SI→Program `1:many`) — a `Program-active` MAY be the generated target of `StrategicInitiative-active` | valid |
| `active` → `closing` | weekly-status-rollup | Evidence the program is entering wind-down (member projects transitioning to CLOSING) | the program's own outbound `BELONGS_TO Portfolio` edge (chain 15) persists through closing | valid |
| `closing` → `closed` | weekly-status-rollup | Evidence all member work is complete / transitioned | terminal; the chain-15 `BELONGS_TO Portfolio` edge remains for historical record | valid |

**Forbidden transitions (entity 14):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `active` → `closed` | — | — | — | `[INVALID-TRANSITION]` (must pass through `closing`) |
| `closed` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.6 Cross-Project Dependency (entity 15)

Axis-1 (verbatim §4): `open → satisfied | broken | waived` · creates `ppm-agent` · maintains `ppm-agent` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `open` | ppm-agent (create) | A directed cross-project dependency detected; `dependency_id` / `from_entity_ref` / `to_entity_ref` typed refs set (§4 entity 15) | outbound `DEPENDS_ON` (§5.1 chain 13 Cross-Project Dependency→Milestone `many:many`) — the dependency points at the Milestone(s) it gates | valid |
| `open` → `satisfied` | ppm-agent | Evidence the depended-on deliverable landed (the `to_entity_ref` reached its satisfying state) | the chain-13 `DEPENDS_ON Milestone` edge is cleared as a blocker; `weekly-status-rollup` reader updates the cross-project view | valid |
| `open` → `broken` | ppm-agent | Evidence the dependency can no longer be met (the source/target moved or was cancelled) | chain-13 `DEPENDS_ON Milestone` flagged at-risk to `weekly-status-rollup` | valid |
| `open` → `waived` | ppm-agent | Operator/owner decision that the dependency is no longer required (descoped) | chain-13 edge retired by decision | valid |

**Forbidden transitions (entity 15):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| any transition OUT of `satisfied` / `broken` / `waived` | — | — | — | `[INVALID-TRANSITION]` (the three are terminal resolutions of `open` — parallel branches; no inter-terminal transition) |

### §3.7 Cross-Project Resource Conflict (entity 16)

Axis-1 (verbatim §4): `detected → acknowledged → resolved` · creates `delivery-engine` · maintains `delivery-engine` · Axis-2: Living (B)

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `detected` | delivery-engine (create) | ≥2 projects over-claim one Person; `conflict_id` / `person_id` / `competing_project_ids` (≥2) set; `over_allocation_pct` computed (§4 entity 16) | outbound `RELATES_TO` (§5.1 chain 14 Cross-Project Resource Conflict→Person `many:1`) — the conflict points at the contended Person | valid |
| `detected` → `acknowledged` | delivery-engine | Evidence the contention is recognized by the owning party (raised to portfolio view) | chain-14 `RELATES_TO Person` surfaced to `weekly-status-rollup` | valid |
| `acknowledged` → `resolved` | delivery-engine | Evidence the over-allocation is corrected (allocations re-balanced) | terminal; chain-14 `RELATES_TO Person` edge cleared | valid |

**Forbidden transitions (entity 16):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `detected` → `resolved` | — | — | — | `[INVALID-TRANSITION]` (must pass through `acknowledged`) |
| `resolved` → any | — | — | — | `[INVALID-TRANSITION]` (terminal) |

### §3.8 Strategic Initiative (entity 17)

Axis-1 (verbatim §4): `proposed → active → completed | cancelled` · creates `ppm-agent` · maintains `weekly-status-rollup` · Axis-2: **Hybrid (C — agent-drafted, human-ratified)**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| (none) → `proposed` | ppm-agent (create) | A portfolio-level strategic thrust drafted; `initiative_name` / `initiative_id` / `sponsor` set (§4 entity 17) | — (proposed initiatives have not yet generated programs) | valid |
| `proposed` → `active` | weekly-status-rollup | **Human ratification** (Axis-2 Hybrid C — agent-drafted, human-ratified): operator approves the initiative to proceed | outbound `GENERATES` (§5.1 chain 16 Strategic Initiative→Program `1:many`) — an active initiative MAY generate `Program-active` records (the create-entry of entity 14) | valid |
| `active` → `completed` | weekly-status-rollup | Evidence the strategic outcome is achieved | terminal; generated Programs (chain 16) follow their own entity-14 machine independently | valid |
| `active` → `cancelled` | weekly-status-rollup | Operator decision to cancel the initiative | terminal; generated Programs (chain 16) are NOT auto-cancelled — each follows its own entity-14 lifecycle | valid |

**Forbidden transitions (entity 17):**

| From → To | Triggering agent | Qualifying evidence | Side-effects | Marker |
|---|---|---|---|---|
| `proposed` → `completed` / `proposed` → `cancelled` | — | — | — | `[INVALID-TRANSITION]` (`proposed` may only advance to `active` — a proposed-then-dropped initiative is a create-time concern) |
| any transition OUT of `completed` / `cancelled` | — | — | — | `[INVALID-TRANSITION]` (both terminal) |

---

## §4 Cross-entity cascade chains — frozen §5.1 edges only

Side-effects reference **ONLY** frozen `project-entity-model.md §5.1` chains. Of the 8 entities, only entities 13–16 are sources or intra-tier targets of frozen chains; Person / System / Vendor (entities 10–12) have **no outbound §5.1 chain** (identity / reference entities — targets of inbound chains 10/11/12/14 only).

- **Chain 13 — Cross-Project Dependency `DEPENDS_ON` Milestone** (`many:many`): the §3.6 transitions clear / flag this edge as the dependency resolves.
- **Chain 14 — Cross-Project Resource Conflict `RELATES_TO` Person** (`many:1`): the §3.7 transitions surface / clear this edge.
- **Chain 15 — Program `BELONGS_TO` Portfolio** (`many:1`): the program's own outbound edge; persists through `closing`/`closed` for historical record (§3.5).
- **Chain 16 — Strategic Initiative `GENERATES` Program** (`1:many`): an `active` initiative MAY generate `Program-active` records (§3.8 → §3.5 create-entry).

**Non-cascade discipline (to pre-empt phantom cascades in the downstream skill-integration work):**

- **Identity entities (entities 10/11/12)** emit a **referential-integrity FLAG** on inbound dependents (chains 10/11/12/14), never an auto-cascade. Deactivating a Person does not auto-mutate its ASSIGNED_TO / RELATES_TO dependents.
- **`StrategicInitiative-cancelled` does NOT auto-cancel generated Programs** — each generated Program (chain 16) follows its own entity-14 machine independently.
- **`Portfolio-archived` does NOT auto-archive members** — it raises a pre-condition integrity flag if any active member `BELONGS_TO` it.

No cross-entity edge outside §5.1 is asserted.

---

## §5 Downstream handoff — §3 registration is FLAGGED, NOT executed

The registration of the entity Axis-1 state-machine family into `core/standards/lifecycle-states-canonical.md §3` is the downstream **operator-gated G8 / G10 governance touch** (Autonomy Tier 0). It is **declared here, NOT executed.**

- `lifecycle-states-canonical.md §3` today registers exactly 3 machines (§3.1 Context, §3.2 Artifact, §3.3 Domain-C); the entity Axis-1 family (this doc's 8 + the project-scoped doc's 10) is **unregistered**.
- `project-entity-model.md §2` (Out of scope) already names this exact deferral ("Registration of the entity Axis-1 state-machine family into `standards/lifecycle-states-canonical.md §3` → G8 / G10").
- The 8 tables above ARE the registration-ready input §3 will eventually consume (one `<Entity>-<state>` machine block per entity, mirroring the §3.1/§3.2/§3.3 sub-section shape).
- **Forward-binding now (prose only):** this protocol uses the object-typed `<Entity>-<state>` convention (`lifecycle-states-canonical.md §2.1`) for cross-machine prose — e.g. `Program-closed`, `Portfolio-archived`, `StrategicInitiative-active` — without writing the §3 registration row.

**This protocol writes ZERO changes to `core/standards/lifecycle-states-canonical.md`.**

---

## §6 Acceptance (grep-AC)

- `test -f core/standards/entity-lifecycle-protocol-shared-portfolio.md` — exists.
- For each of the 8 entities (entities 10–17): its verbatim §4 Axis-1 state set appears, and a transition table with ≥2 valid rows (incl. the create-entry) is present.
- State-set fidelity: every state token used appears in the corresponding `project-entity-model.md §4` Axis-1 line — zero new/aliased tokens.
- `grep -c "\[INVALID-TRANSITION\]" core/standards/entity-lifecycle-protocol-shared-portfolio.md` ≥ 8 (≥1 forbidden row per entity).
- Side-effects cite only §5.1 chains 13/14/15/16; identity entities (entities 10/11/12) carry referential-integrity flags, not outbound cascades.
- `git diff` shows **zero** changes to `core/standards/lifecycle-states-canonical.md` (the §3 registration is FLAGGED, not executed).
- **Format-identity check:** the §2 5-column table header in this doc === the header in `core/standards/entity-lifecycle-protocol.md` (byte-identical column set).
