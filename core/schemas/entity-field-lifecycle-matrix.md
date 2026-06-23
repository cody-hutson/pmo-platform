<!-- reference-durability: allow-link -->
# Entity Field Lifecycle Matrix

The per-entity × per-field × per-agent **write-permission** matrix for all 18 logical entities of the project-entity model — the entity-tier sibling of the ticket-tier [`field-lifecycle-matrix.md`](field-lifecycle-matrix.md). It answers, for a project-DATA record: *which agent may write which field of which entity at which lifecycle transition*, who wins when two agents claim the same field, and which writes must carry an audit label.

**Scope — post-create only.** This matrix covers the **post-create write-lifecycle, conflict-winner, and audit-trail** dimensions ONLY. The **create-time field-supply** contract (which fields a skill MUST supply at create-time vs. MAY read, per creator/maintainer/reader) is already defined in [`entity-field-schemas.md` §5 Consumer Matrix](entity-field-schemas.md) + [`project-entity-model.md` §6 Owning-Agent Matrix](../disciplines/project-entity-model.md). Those are **referenced, never restated** here (duplicate-source-discipline). Every per-entity block carries a one-line `Create-time supply → §5` pointer instead of re-listing the triplet.

**Consumers:** the G8 lifecycle-automation layer and the G9/G10 interface layer consume this matrix to route entity writes (which agent's write to honor at which transition). It is the entity-tier analogue of the [Agent Write Permissions](../../release/references/specs/ticket-information-architecture.md#agent-write-permissions) table for issues: that table governs ticket fields across the 13 pipeline stages; this matrix governs **entity** fields across each entity's **own** lifecycle machine.

**Relationship to the architecture stack:**
- [`project-entity-model.md` §4](../disciplines/project-entity-model.md) — the 18 entities + their Axis-1 lifecycle machines (the column source; **referenced, not restated**).
- [`project-entity-model.md` §6](../disciplines/project-entity-model.md) + [`entity-field-schemas.md` §5](entity-field-schemas.md) — creator / maintainer / reader per entity (the Owner column + create-time supply; **referenced, not restated**).
- [`field-lifecycle-matrix.md`](field-lifecycle-matrix.md) — the ticket-tier sibling whose **C/R/U/A/L/—** Cell Taxonomy this matrix reuses verbatim (the taxonomy source; **referenced, not redefined**).
- This matrix — entity-field write/append/read-only access per lifecycle transition + conflict-winner rules + audit-trail-per-write-class.

---

## 1. Cell Taxonomy

This matrix **reuses the six-value cell taxonomy of [`field-lifecycle-matrix.md` § Cell Taxonomy](field-lifecycle-matrix.md#cell-taxonomy) verbatim** — same letters, same meanings — so a reader fluent in the ticket matrix reads this one with zero relearning. The values are **not redefined** here; the table below states only their **entity-write binding** (how each maps to the post-create entity world). One additive value, `Ap`, is introduced (§1.1).

| Value | Ticket-matrix meaning (source: `field-lifecycle-matrix.md`) | Entity-matrix binding (post-create) |
|---|---|---|
| **C** | Created — field first populated at this stage | Field first written **at create-commit by the §5 creator**. Appears only in the `create` column; post-create columns never show C (single-create invariant). |
| **R** | Required — must exist for the gate (set earlier) | Maintainer **validates existence** before a transition fires; gate check, no write. |
| **U** | Updated — may be refined at this stage | Maintainer **overwrites** the field at/through this transition (last-writer-wins on a single owner). |
| **A** | Auto — populated by automation | Written by a **G8 automation hook**, not an agent (e.g. `actual_date` stamped on `→completed`). Agent does not write; MAY validate. |
| **L** | Locked — set earlier, not modified | **Read-only** after the locking transition. Modification requires the operator-gated correction protocol. Immutable-record fields (Decision `decision_statement`, Plan `version`) are L in every post-create column. |
| **—** | N/A — field not relevant at this stage | Field is meaningless at this entity's transition (e.g. `resolved_date` before `→resolved`). |

### 1.1 The one additive value — `Ap` (Append)

The ticket matrix has no append value because issue fields are single-author overwrite. The 18-entity model has genuine **multi-writer accreting fields** — `RAID Item.action_plan` (ppm-agent proposes it; tracker-manager appends mitigation-status updates over the `open→in-progress→mitigating` arc), `Decision.rationale`, Meeting-generated note streams. For these, `U` (overwrite) is the **wrong** contract: a second writer overwriting the first silently destroys the first writer's data — the exact failure this matrix exists to prevent.

| Value | Meaning | Agent behavior |
|---|---|---|
| **Ap** | **Append** — multi-writer accreting field; entries accrete, never overwrite | The writer **appends a timestamped + attributed entry**; it never overwrites a prior entry. Concurrent appends are commutative (both land; order by attributed timestamp). Each entry self-carries an evidence label (§4). |

`Ap` is the minimal additive surface — everything else reuses the existing taxonomy unchanged. It is the data-loss-safe contract for the named multi-writer fields; without it, the append-merge conflict (§3 CS-3) has no safe resolution. Design rationale: §5.

---

## 2. Column Convention — the load-bearing adaptation

The ticket matrix's columns are the **13 release-pipeline stages** (1-In … 13-Cl). **Entity records never traverse the release pipeline** — a `Milestone` record is not an issue moving Triage→Engineering; it is project-DATA with its own operational lifecycle. So this matrix's columns are each entity's **Axis-1 operational transitions** (the lifecycle machines frozen in [`project-entity-model.md` §4](../disciplines/project-entity-model.md); the transition-table *format* is formalized by the W0 transition protocols [`entity-lifecycle-protocol.md`](../standards/entity-lifecycle-protocol.md) (project-scoped) and [`entity-lifecycle-protocol-shared-portfolio.md`](../standards/entity-lifecycle-protocol-shared-portfolio.md) (shared + portfolio)).

Per entity, the columns are: **`create`** (the §5 creator's write) **+ one column per Axis-1 transition edge** of that entity's machine. This is a **per-entity table** (18 of them), each sized to its own machine — **not** one mega-grid with 13 fixed columns. Worked shape for Milestone (`planned → in-progress → completed | cancelled`):

| Field | create | →in-progress | →completed | →cancelled | Owner |
|---|---|---|---|---|---|
| `milestone_name` | **C** (release-planner) | L | L | L | creator |
| `target_date` | **C** | U | L | L | maintainer |
| `actual_date` | — | — | **A** (G8 stamp on completion) | — | automation |
| `lifecycle_state` | **C** (=`planned`) | **U** | **U** | **U** | maintainer |

The matrix structure is therefore: per-entity blocks, each = field-rows × (`create` + Axis-1-transition) columns, cells drawn from `{C, R, U, A, L, Ap, —}`. The column headers **are** the W0 transition edges. The `Owner` column names which §5/§6 role legitimately holds the post-create write authority (creator only at `create`; maintainer thereafter — see §3 CW-BASE); `automation` denotes a G8-owned `A` cell.

**Reading rule.** Only the discriminating entity-specific fields + `lifecycle_state` are surfaced per block (the §3.0 Core-field house style of `entity-field-schemas.md`). `lifecycle_state` is the Axis-1 state itself: `C` at create (entry state), `U` by the maintainer at each transition. Fields not listed inherit the default "creator writes at `create`, maintainer may `U` post-create, `L` once a Baselined entity is locked."

---

## 3. Conflict-Winner Rules

### 3.1 CW-BASE — the deterministic base rule

[`entity-field-schemas.md` §5](entity-field-schemas.md) and [`project-entity-model.md` §6](../disciplines/project-entity-model.md) already assign every entity exactly **one creator and one maintainer**. CW-BASE canonicalizes the *temporal* split those matrices imply but do not state:

> **CW-BASE.** For any field of any entity, the **§5 maintainer owns every write after create-commit**. The §5 creator's write authority is **scoped to the create transaction only** and **terminates at create-commit**. After that instant, a creator-role skill attempting to write the field is **demoted to reader**; the maintainer wins. **Automation** (`A` cells) wins over both for its declared fields (G8 owns them). **`L`** (locked / immutable) fields are won by **no agent** post-lock — only the operator-gated correction protocol writes them.

CW-BASE makes most "conflicts" **non-conflicts by construction**: two skills cannot both legitimately hold write authority on the same field at the same lifecycle phase, because §5 names exactly one owner per phase. Every winner below is a **§5/§6-named owner** — CW-BASE adds *temporal precision only*, never new authority.

### 3.2 CW-LADDER — the tie-break ladder (residual disputes only)

> **CW-LADDER** (applied only when CW-BASE leaves ≥2 candidate writers):
> 1. **Owner rung** — the §5 maintainer (post-create) or §5 creator (at create) wins. Resolves all single-owner disputes.
> 2. **Class rung** — if owner is ambiguous (a field with split sub-ownership), the **higher write-class** wins by precedence **Create > State-transition > Field-update > Append** (a create or a state-transition beats a cosmetic field-update racing it).
> 3. **Append rung** — for `Ap` fields where two writers fire concurrently, there is **no winner: both entries land** (append is commutative); ordering is by attributed timestamp. This is the rung that makes multi-writer log fields safe.

### 3.3 Conflict-winner register (per disputed field)

Every field whose §5 creator ≠ maintainer is a conflict candidate. The register records the winner per disputed field; the four worked scenarios (§3.4) are the exemplars covering all four residual shapes.

| CW-ID | Entity.field | Disputed between | Winner (CW rule) | Loser action |
|---|---|---|---|---|
| **CW-1** | `RAID Item.lifecycle_state` | ppm-agent (creator) vs tracker-manager (maintainer) | **tracker-manager** (CW-BASE: post-create state-transition → maintainer) | ppm-agent emits a TRACKER_UPDATE recommendation; does not write |
| **CW-2** | `Milestone.actual_date` | release-planner (creator) vs delivery-engine (maintainer) | **G8 automation** (`A` cell) → **delivery-engine** as agent fallback (CW-BASE) | release-planner is a reader of `actual_date` |
| **CW-3** | `RAID Item.action_plan` | ppm-agent vs tracker-manager (multi-writer log) | **both** (CW-LADDER rung 3: `Ap` append, no winner) | neither overwrites; each appends an attributed entry |
| **CW-4** | `Decision.decision_statement` | tracker-manager (maintainer) vs operator | **nobody** (CW-BASE: `L` immutable post-accept) | tracker-manager refuses the write; surfaces a correction-protocol recommendation |
| **CW-5** | `Decision.rationale` | ppm-agent vs tracker-manager (multi-writer log) | **both** (CW-LADDER rung 3: `Ap` append) | neither overwrites; each appends an attributed entry |
| **CW-6** | `Plan.version` | artifact-generator (creator) vs ppm-agent (maintainer) | **nobody once `approved`** (CW-BASE: `L` on a Baselined record); a new version is a new Plan via `SUPERSEDES` | writer issues a superseding Plan, not an in-place edit |

> **General rule for unlisted disputed fields.** Apply CW-BASE first (maintainer wins post-create); if the field is multi-writer accreting (`Ap`), apply CW-LADDER rung 3 (both land); if the field is `L` on a Baselined entity, no agent wins (correction protocol only). The register grows by adding a row, not by re-deriving the rule.

### 3.4 Worked conflict scenarios

**CS-1 — ppm-agent vs tracker-manager on `RAID Item.lifecycle_state`** *(the named conflict-seam case)*
- *Setup:* `RAID Item` §5 = creator `ppm-agent`, maintainer `tracker-manager`; Axis-1 `open → in-progress → mitigating → resolved → closed`. ppm-agent (which *created* the item at `open`) later tries to flip it to `mitigating` during a transcript sweep; tracker-manager simultaneously processes a TRACKER_UPDATE flipping it to `resolved`.
- *Resolution:* **CW-BASE → tracker-manager wins.** `lifecycle_state` is a post-create state-transition field; the maintainer owns it. ppm-agent's authority on this RAID ended at create-commit (it set `open`); it is now a **reader** of `lifecycle_state` and must route any state-change *recommendation* through tracker-manager (the TRACKER_UPDATE channel, per [OPERATIONS.md § Closed-Loop Processing Protocol](../governance/OPERATIONS.md)), not write directly. **Winner: tracker-manager (maintainer). Loser action: ppm-agent emits a recommendation, does not write.**

**CS-2 — creator vs maintainer on `Milestone.actual_date`** *(the named conflict-seam case)*
- *Setup:* `Milestone` §5 = creator `release-planner`, maintainer `delivery-engine`. `actual_date` is stamped when the milestone reaches `→completed`. release-planner (creator) tries to backfill `actual_date` during a re-plan; delivery-engine (maintainer) is the legitimate updater.
- *Resolution:* **Two rules fire and agree.** First, `actual_date` on `→completed` is an **`A` (automation) cell** — the G8 completion hook stamps it; *neither* agent should hand-write it (`DEFER-G8` disposition, [`entity-field-schemas.md` §2](entity-field-schemas.md)). If automation is not yet wired, **CW-BASE → delivery-engine (maintainer) wins**; release-planner's create-scope ended at create-commit. **Winner: G8 automation (declared) → delivery-engine (maintainer) as the agent fallback. Loser action: release-planner is a reader of `actual_date`.**

**CS-3 — append-merge: ppm-agent and tracker-manager both write `RAID Item.action_plan`** *(residual `Ap` shape)*
- *Setup:* Over the `open → in-progress → mitigating` arc, ppm-agent records the initial action plan and tracker-manager later adds a mitigation-status update. Under a naive `U` contract the second write **silently overwrites** the first — the data-loss failure this matrix exists to prevent.
- *Resolution:* **`action_plan` is an `Ap` (Append) field → CW-LADDER rung 3: no winner, both entries land.** Each writer appends an attributed, timestamped entry; neither overwrites. The maintainer (tracker-manager) still owns the field's *lifecycle* (it can mark the parent transition), but appends are commutative and non-destructive. **Winner: both (append is the resolution). This is the case that motivates the additive `Ap` value.**

**CS-4 — immutable-record write: tracker-manager vs operator on `Decision.decision_statement`** *(residual `L` shape)*
- *Setup:* `Decision` is a Baselined / immutable record ([`project-entity-model.md` §4 entity 5](../disciplines/project-entity-model.md)); §5 = creator `ppm-agent`, maintainer `tracker-manager`. After the decision is `accepted`, tracker-manager processes an edit that would rewrite `decision_statement`.
- *Resolution:* **`decision_statement` is `L` (locked) in every post-accept column → CW-BASE: no agent wins.** An immutable field post-lock is writable only via the **operator-gated correction protocol** (a Decision is `reversed → superseded`, not silently rewritten). tracker-manager's maintainer role covers *operational* fields (`lifecycle_state`), not the immutable statement. **Winner: nobody (operator correction protocol only). Loser action: tracker-manager refuses the write, surfaces a correction-protocol recommendation.**

---

## 4. Audit-Trail Requirement per Write Class

The access-cell values collapse to **4 write classes** for audit purposes. The matrix states which classes MUST carry a [CLAUDE.md evidence-quality label](../CLAUDE.md.template) (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`). This **reuses the existing gate** — [OPERATIONS.md § Skill Chaining Protocol **C3**](../governance/OPERATIONS.md) already requires `evidence_quality ∈ {[SOURCE], [INFERRED]}` on any auto-cascaded tracker write, and `[ASSUMPTION – CONFIRM]` demotes a write to manual. This matrix **extends C3's existing bar** from "auto-cascade only" to "all entity-field writes, by class" — citing, not re-inventing, the label set and gate semantics.

| Write class | Cell(s) | Evidence-quality label REQUIRED? | Rationale |
|---|---|---|---|
| **Create** | `C` | **YES — `[SOURCE]` or `[INFERRED]`** | The create-commit establishes the record; its provenance must be traceable (which transcript / issue / operator input sourced it). Matches C3's existing auto-cascade bar. |
| **State-transition** | `U` on `lifecycle_state`; `A` state stamps | **YES — `[SOURCE]` or `[INFERRED]`** | A lifecycle flip is a load-bearing, often-irreversible event (`→closed`, `→cancelled`); the trail must say what evidence justified it. `[ASSUMPTION – CONFIRM]` **demotes the write to manual** (per C3) — an unverified transition never auto-fires. |
| **Field-update** | `U` on non-state fields | **CONDITIONAL** — required for **portfolio-queried** fields (`RAID Item.impact`, `severity`, `target_date`); `[CONTEXT]` acceptable for cosmetic fields | The portfolio-rollup query keys on `impact` / `severity` ([§5 note](entity-field-schemas.md)); those updates must be graded so a rollup never aggregates unlabelled data. Purely cosmetic fields (a `*_name` typo fix) may carry `[CONTEXT]`. |
| **Append** | `Ap` | **YES — each appended entry self-labels** | Each `Ap` entry is attributed + timestamped + carries its own evidence label (the append *is* the audit trail; entries are never overwritten, so the log *is* the provenance record). |
| **Automation** | `A` (non-state) | **N/A — label is the hook identity** | A G8-hook write is audited by the hook's own commit / log identity, not an agent evidence label (agents do not author `A` cells). |
| **Locked** | `L` | **N/A — no write occurs** | Post-lock writes happen only via the operator correction protocol, which carries its own approval trail. |

**Audit-trail home (declared, not built here — boundary discipline).** This matrix **declares** the label requirement per write class. The **physical** capture surface (where the label is persisted — a frontmatter field, a tracker cell, a commit trailer) is **G8 automation / tracker-schema physicalization** — exactly the WHAT/HOW split the [`entity-field-schemas.md` §2](entity-field-schemas.md) boundary axiom uses. The matrix is the logical contract; it does not over-reach into the persistence mechanism.

---

## 5. Design Rationale

This matrix canonicalizes three conventions that the corpus implied but never stated. Per the slim-to-kernel discipline, an application-of-existing-ADRs record folds into the artifact rather than a standalone ADR — CW-BASE is the *temporal completion* of the already-ratified §5/§6 ownership model (the Two-Axis Entity Lifecycle decision), not a new architectural decision.

- **The `Ap` (Append) value** is additive (not a replacement) per CLAUDE.md "Prefer durable structures over static examples" and the `entity-field-schemas.md` duplicate-source-discipline (reuse the taxonomy, do not fork it). It is the minimal delta the entity model's **multi-writer fields** force, justified by the data-loss failure mode (a second `U` writer silently overwriting the first) that [`entity-field-schemas.md` §7](entity-field-schemas.md) already names. **Reversibility: CHEAP / Confidence: HIGH.**
- **CW-BASE** invents no authority: every winner is the §5/§6-named owner; the rule adds the missing *temporal* clause ("authority transfers at create-commit") to the already-canonical creator/maintainer split. The four worked scenarios each resolve to a §5 owner, demonstrating the rule adds temporal precision only. **Reversibility: CHEAP / Confidence: HIGH.**
- **The audit-trail-per-write-class** requirement extends OPERATIONS.md C3's existing `{[SOURCE], [INFERRED]}` bar from auto-cascade to all entity-field writes by class; it cites (does not re-invent) the CLAUDE.md label set and the C3 gate semantics, and defers the persistence surface to G8 (boundary discipline). **Reversibility: CHEAP / Confidence: HIGH.**

**Out of scope (deliberately not done here):** this matrix **keys on** the entity Axis-1 transitions; it does **not register** the entity state-machine family into [`lifecycle-states-canonical.md` §3](../standards/lifecycle-states-canonical.md) — that is the operator-gated downstream G8/G10 governance touch (flagged in [`project-entity-model.md` §2](../disciplines/project-entity-model.md), FLAGGED-not-executed). It does not restate §5 create-time supply, redefine the C/R/U/A/L/— taxonomy, or re-list the Axis-1 state enums.

---

## 6. Per-Entity Access Blocks (×18)

One table per entity. Columns = `create` + the entity's Axis-1 transition edges ([`project-entity-model.md` §4](../disciplines/project-entity-model.md)). Cells ∈ `{C, R, U, A, L, Ap, —}` (§1). The `Owner` column names the §5/§6 role holding post-create write authority (per CW-BASE). Only discriminating fields + `lifecycle_state` are surfaced (house style); `Create-time supply → §5` is the per-block pointer (do not re-list the triplet).

### Project-scoped entities (live in `[Project]/`)

#### 6.1 Project (PRJ) — `ACTIVE → CLOSING → CLOSED`
*Create-time supply → §5 · creator `project-initiator` · maintainer `ppm-agent`*

| Field | create | →CLOSING | →CLOSED | Owner |
|---|---|---|---|---|
| `project_name` | **C** | L | L | creator |
| `project_owner` | **C** | U | L | maintainer |
| `status` | **C** (=`ACTIVE`) | **U** | **U** | maintainer |
| `delivery_approach` | **C** | L | L | creator |
| `lifecycle_state` | **C** (=`ACTIVE`) | **U** | **U** | maintainer |

#### 6.2 Milestone (MIL) — `planned → in-progress → completed | cancelled`
*Create-time supply → §5 · creator `release-planner` · maintainer `delivery-engine`*

| Field | create | →in-progress | →completed | →cancelled | Owner |
|---|---|---|---|---|---|
| `milestone_name` | **C** | L | L | L | creator |
| `target_date` | **C** | U | L | L | maintainer |
| `actual_date` | — | — | **A** (G8 stamp) | — | automation |
| `lifecycle_state` | **C** (=`planned`) | **U** | **U** | **U** | maintainer |

#### 6.3 Workstream (WS) — `active → paused → closed`
*Create-time supply → §5 · creator `ppm-agent` · maintainer `ppm-agent` (single owner — no creator/maintainer split)*

| Field | create | →paused | →closed | Owner |
|---|---|---|---|---|
| `workstream_name` | **C** | L | L | owner |
| `lead_person_id` | **C** | U | L | owner |
| `lifecycle_state` | **C** (=`active`) | **U** | **U** | owner |

#### 6.4 Plan (PLN) — `draft → approved → active → superseded → archived` *(Baselined)*
*Create-time supply → §5 · creator `artifact-generator` · maintainer `ppm-agent`*

| Field | create | →approved | →active | →superseded | →archived | Owner |
|---|---|---|---|---|---|---|
| `plan_title` | **C** | L | L | L | L | creator |
| `plan_type` | **C** | L | L | L | L | creator |
| `version` | **C** | **L** | L | L | L | creator (locked at approval; a new version = a new Plan via `SUPERSEDES`, CW-6) |
| `supersedes_plan_id` | — | — | — | **U** | L | maintainer |
| `lifecycle_state` | **C** (=`draft`) | **U** | **U** | **U** | **U** | maintainer |

#### 6.5 Decision (DEC) — `proposed → accepted → reversed | superseded` *(Baselined / immutable)*
*Create-time supply → §5 · creator `ppm-agent` · maintainer `tracker-manager`*

| Field | create | →accepted | →reversed | →superseded | Owner |
|---|---|---|---|---|---|
| `decision_statement` | **C** | **L** | L | L | locked post-accept (no agent — correction protocol only, CS-4) |
| `decided_date` | **C** | L | L | L | creator |
| `decision_maker_person_id` | **C** | L | L | L | creator |
| `rationale` | **Ap** | **Ap** | Ap | Ap | append (multi-writer log, CW-5) |
| `lifecycle_state` | **C** (=`proposed`) | **U** | **U** | **U** | maintainer |

#### 6.6 RAID Item (RAID) — `open → in-progress → mitigating → resolved → closed`
*Create-time supply → §5 · creator `ppm-agent` · maintainer `tracker-manager`*

| Field | create | →in-progress | →mitigating | →resolved | →closed | Owner |
|---|---|---|---|---|---|---|
| `raid_type` | **C** | L | L | L | L | creator |
| `summary` | **C** | U | U | L | L | maintainer |
| `owner_person_id` | **C** | U | U | U | L | maintainer |
| `severity` | **C** | U | U | U | L | maintainer (portfolio-queried — labelled write, §4) |
| `impact` | **C** | U | U | U | L | maintainer (portfolio-queried — labelled write, §4) |
| `target_date` | ⚪ C | U | U | L | L | maintainer |
| `action_plan` | **Ap** | **Ap** | **Ap** | Ap | L | append (multi-writer log, CS-3) |
| `lifecycle_state` | **C** (=`open`) | **U** | **U** | **U** | **U** | maintainer (CS-1) |

#### 6.7 Meeting (MTG) — `scheduled → held | cancelled`
*Create-time supply → §5 · creator `file-router` · maintainer `ppm-agent`*

| Field | create | →held | →cancelled | Owner |
|---|---|---|---|---|
| `meeting_title` | **C** | U | L | maintainer |
| `meeting_date` | **C** | U | L | maintainer |
| `attendee_person_ids` | ⚪ C | **U** | L | maintainer |
| `lifecycle_state` | **C** (=`scheduled`) | **U** | **U** | maintainer |

#### 6.8 Resource (RES) — `planned → active → released`
*Create-time supply → §5 · creator `delivery-engine` · maintainer `delivery-engine` (single owner)*

| Field | create | →active | →released | Owner |
|---|---|---|---|---|
| `person_id` | **C** | L | L | owner |
| `project_id` | **C** | L | L | owner |
| `allocation_pct` | **C** | **U** | L | owner |
| `role_on_project` | **C** | U | L | owner |
| `period_start` | ⚪ C | U | L | owner |
| `period_end` | ⚪ C | U | **U** | owner |
| `lifecycle_state` | **C** (=`planned`) | **U** | **U** | owner |

#### 6.9 Artifact (ART) — Axis-1 **delegates to Axis-2** (Domain A/B/C content machine, the reconciliation seam)
*Create-time supply → §5 · creator `artifact-generator` · maintainer `ppm-agent` (route: `file-router`)*

The Artifact's Axis-1 *delegates to Axis-2* — `lifecycle_state` mirrors the backing file's Domain A/B/C content-maturity machine ([`frontmatter-schema.md` §Cat-2](frontmatter-schema.md), referenced). The Domain-C content machine is `draft → validated → published → stale → archived`. The orthogonal **promotion-location** concern is carried by a separate field `promotion_state` (`staged → promoted → archived-in-place`), owned by `artifact-generator`, defined in [`artifact-workflow-protocol.md` §4](../artifact-workflow-protocol.md) (referenced, not restated). The two are independent — a `published` artifact may still be `staged`.

| Field | create | →validated | →published | →stale | →archived | Owner |
|---|---|---|---|---|---|---|
| `artifact_title` | **C** | L | L | L | L | creator |
| `artifact_type` | **C** | L | L | L | L | creator |
| `domain` | ⚪ C | L | L | L | L | creator (reconciliation seam) |
| `version` | ⚪ C | U | U | L | L | maintainer |
| `lifecycle_state` (Axis-1 = content-maturity) | **C** (=`draft`) | **U** | **U** | **U** | **U** | maintainer (content transitions are governed) |
| `promotion_state` (location — orthogonal) | **C** (=`staged`) | — | — | — | A (`archived-in-place` on Auto-Archive sweep) | `artifact-generator` (never self-advances past `staged`; `staged→promoted` is operator-gated — [`artifact-workflow-protocol.md` §4.1](../artifact-workflow-protocol.md)) |

### Cross-project shared entities (live in `_pmo/`)

#### 6.10 Person (PER) — `active → inactive`
*Create-time supply → §5 · creator `project-initiator` / `file-router` · maintainer `ppm-agent`*

| Field | create | →inactive | Owner |
|---|---|---|---|
| `full_name` | **C** | L | creator |
| `person_id` | **C** | L | creator (global identity anchor) |
| `primary_role` | **C** | U | maintainer |
| `email` | ⚪ C | U | maintainer |
| `lifecycle_state` | **C** (=`active`) | **U** | maintainer |

#### 6.11 System (SYS) — `active → deprecated → retired`
*Create-time supply → §5 · creator `ppm-agent` · maintainer `ppm-agent` (single owner)*

| Field | create | →deprecated | →retired | Owner |
|---|---|---|---|---|
| `system_name` | **C** | U | L | owner |
| `system_id` | **C** | L | L | owner |
| `system_owner_person_id` | ⚪ C | U | L | owner |
| `lifecycle_state` | **C** (=`active`) | **U** | **U** | owner |

#### 6.12 Vendor (VEN) — `active → inactive`
*Create-time supply → §5 · creator `ppm-agent` · maintainer `ppm-agent` (single owner)*

| Field | create | →inactive | Owner |
|---|---|---|---|
| `vendor_name` | **C** | U | owner |
| `vendor_id` | **C** | L | owner |
| `vendor_category` | ⚪ C | U | owner |
| `primary_contact_person_id` | ⚪ C | U | owner |
| `lifecycle_state` | **C** (=`active`) | **U** | owner |

### Portfolio-level entities (live in `projects/_config/`)

#### 6.13 Portfolio (PORT) — `active → archived`
*Create-time supply → §5 · creator `weekly-status-rollup` · maintainer `weekly-status-rollup` (single owner)*

| Field | create | →archived | Owner |
|---|---|---|---|
| `portfolio_name` | **C** | L | owner |
| `portfolio_id` | **C** | L | owner |
| `portfolio_owner` | **C** | U | owner |
| `lifecycle_state` | **C** (=`active`) | **U** | owner |

#### 6.14 Program (PROG) — `active → closing → closed`
*Create-time supply → §5 · creator `weekly-status-rollup` · maintainer `weekly-status-rollup` (single owner)*

| Field | create | →closing | →closed | Owner |
|---|---|---|---|---|
| `program_name` | **C** | L | L | owner |
| `program_id` | **C** | L | L | owner |
| `portfolio_id` | **C** | L | L | owner |
| `program_owner` | **C** | U | L | owner |
| `lifecycle_state` | **C** (=`active`) | **U** | **U** | owner |

#### 6.15 Cross-Project Dependency (XPD) — `open → satisfied | broken | waived`
*Create-time supply → §5 · creator `ppm-agent` · maintainer `ppm-agent` (single owner)*

| Field | create | →satisfied | →broken | →waived | Owner |
|---|---|---|---|---|---|
| `dependency_id` | **C** | L | L | L | owner |
| `from_entity_ref` | **C** | L | L | L | owner |
| `to_entity_ref` | **C** | L | L | L | owner |
| `dependency_kind` | ⚪ C | L | L | L | owner |
| `lifecycle_state` | **C** (=`open`) | **U** | **U** | **U** | owner |

#### 6.16 Cross-Project Resource Conflict (XRC) — `detected → acknowledged → resolved`
*Create-time supply → §5 · creator `delivery-engine` · maintainer `delivery-engine` (single owner)*

| Field | create | →acknowledged | →resolved | Owner |
|---|---|---|---|---|
| `conflict_id` | **C** | L | L | owner |
| `person_id` | **C** | L | L | owner |
| `competing_project_ids` | **C** | U | L | owner |
| `over_allocation_pct` | ⚪ C | U | L | owner |
| `lifecycle_state` | **C** (=`detected`) | **U** | **U** | owner |

#### 6.17 Strategic Initiative (INIT) — `proposed → active → completed | cancelled` *(Hybrid — agent-drafted, human-ratified)*
*Create-time supply → §5 · creator `ppm-agent` · maintainer `weekly-status-rollup`*

| Field | create | →active | →completed | →cancelled | Owner |
|---|---|---|---|---|---|
| `initiative_name` | **C** | L | L | L | creator |
| `initiative_id` | **C** | L | L | L | creator |
| `sponsor` | **C** | U | L | L | maintainer (human-ratified) |
| `linked_program_ids` | ⚪ C | **U** | U | L | maintainer |
| `target_outcome` | ⚪ C | U | L | L | maintainer |
| `lifecycle_state` | **C** (=`proposed`) | **U** | **U** | **U** | maintainer |

### Work-item tier entity (live in `[Project]/`)

#### 6.18 Work Item (WI) — `backlog → ready → in-progress → in-review → done | cancelled`
*Create-time supply → Work Item's §5 Consumer-Matrix row · creator `intake-desk` · maintainer `delivery-engine` (per [`project-entity-model.md` §4 entity 18](../disciplines/project-entity-model.md) + [§6](../disciplines/project-entity-model.md)).*

| Field | create | →ready | →in-progress | →in-review | →done | →cancelled | Owner |
|---|---|---|---|---|---|---|---|
| `work_item_type` | **C** | L | L | L | L | L | creator |
| `parent_ref` | **C** | U | L | L | L | L | maintainer |
| `lifecycle_state` | **C** (=`backlog`) | **U** | **U** | **U** | **U** | **U** | maintainer |

> The C2 type-pack layer projects methodology labels onto this base machine and MAY add type-scoped sub-states over it ([`project-entity-model.md` §4 entity 18](../disciplines/project-entity-model.md)). Those projected/extended transitions inherit the same access cells: maintainer owns post-create writes; create-time supply is the creator's.

---

## 7. Cross-References

- [`field-lifecycle-matrix.md`](field-lifecycle-matrix.md) — the ticket-tier sibling; **source of the C/R/U/A/L/— Cell Taxonomy** reused here (§1).
- [`entity-field-schemas.md` §5 Consumer Matrix](entity-field-schemas.md) — **create-time field-supply** contract (referenced, not restated; the per-block `→ §5` pointer).
- [`entity-field-schemas.md` §2](entity-field-schemas.md) — the `DEFER-G8` disposition + WHAT/HOW boundary axiom the audit-trail home (§4) cites.
- [`project-entity-model.md` §4](../disciplines/project-entity-model.md) — the 18 entities + **Axis-1 lifecycle machines** (the column source, §2).
- [`project-entity-model.md` §6 Owning-Agent Matrix](../disciplines/project-entity-model.md) — creator / maintainer / reader per entity (the `Owner` column + CW-BASE source, §3).
- [`entity-lifecycle-protocol.md`](../standards/entity-lifecycle-protocol.md) + [`entity-lifecycle-protocol-shared-portfolio.md`](../standards/entity-lifecycle-protocol-shared-portfolio.md) — the W0 Axis-1 transition protocols whose transition-table format the column headers bind to (§2).
- [`artifact-workflow-protocol.md` §4](../artifact-workflow-protocol.md) — the Artifact `promotion_state` field (§6.9, referenced not restated).
- [OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md) (C3) + [§ Closed-Loop Processing Protocol](../governance/OPERATIONS.md) — the consumers (the audit-label gate the matrix extends, §4; the TRACKER_UPDATE channel CS-1 routes through).
- [CLAUDE.md](../CLAUDE.md.template) — the 5 evidence-quality labels the audit-trail requirement cites (§4).
