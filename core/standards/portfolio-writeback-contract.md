---
title: Portfolio Write-Back Contract — G7 Project-to-Portfolio Rollup
purpose: The G7 project-to-portfolio rollup publishing contract — the per-project 7-field schema, per-field cadence, staleness anchor, and PORTFOLIO.md section-schema map that ppm-agent emits, the deterministic composer renders, and the Cowork PORTFOLIO.md writer stages.
type: standard
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
consumers: weekly-status-rollup (Section 6 write-back composition); ppm-agent (per-project rollup-entity emission); the deterministic PORTFOLIO.md composer; the portfolio health-score freshness thresholds; the portfolio risk-profile aggregation
---
<!-- reference-durability: allow-link -->

# Portfolio Write-Back Contract — G7 Project-to-Portfolio Rollup

**Status:** Canonical (Stage 6 Engineering until merged)
**Owner:** `core/standards/portfolio-writeback-contract.md`
**Introduced:** release `pda-rollup-and-portfolio` — the G7 project-to-portfolio rollup-contract work item (project-data-architecture initiative, portfolio write-back layer).
**Architectural basis:** ADR-019 (compose-not-absorb) + the entity-roster freeze in [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md) §4 (re-frozen at **19 entities** via ADR-044). The per-project rollup is a **COMPOSED read-surface over existing entities — NOT a roster entity**: the roster is frozen at 19 and this contract adds none. Each contract field READS its source entity and references that authoritative value; no field owns or duplicates one.

---

## §1 Purpose & Boundary

Project → portfolio rollup was implicit: `PORTFOLIO.md` was hand-synthesized by `weekly-status-rollup` Section 6 with no field contract, so skill-output drift propagated silently and the dashboard could read Green over a failing subsystem. This contract closes that gap. It defines **one** per-project publishing schema — a fixed set of fields, each typed, each with a cadence, each sourced from a frozen entity — so the deterministic composer renders `PORTFOLIO.md` sections **from fields**, not from agent-synthesized prose.

**Staging-only boundary (load-bearing).** This contract **STAGES composed content for the Cowork `PORTFOLIO.md` writer — it NEVER authorizes a Claude-side write into `projects/`.** `PORTFOLIO.md` is a Layer-2, Cowork-owned artifact ([`../rules/operations-bridge.md`](../rules/operations-bridge.md): Claude Code does not write any Layer-2 file). Every section this contract defines is composed content routed through `weekly-status-rollup` Section 6's existing human-in-the-loop checkpoint. No producer of this contract has an output path that resolves into `projects/`.

**Roster-rule exemption (explicit).** The per-project rollup record is a composed read-surface, so it is **exempt from `V-CORE-02`** (`entity_type` ∈ the frozen roster): its `entity_type: "Project Rollup (composed)"` is deliberately non-roster and is the composer's **discovery key** (`../deploy/tools/compose-portfolio.py`), not a roster claim — a roster-legal value would make the composer discover **zero** rollups. It is likewise exempt from **`V-CORE-03`/`V-CORE-03b`** (`lifecycle_state`) and **`V-CORE-06`** (`created_date`): the record carries no lifecycle of its own, and its freshness is carried by `last_published` per §3. No other Core rule is waived. **Honest enforcement status:** these rules are today *declared* L1-blocking in [`../schemas/entity-field-schemas.md`](../schemas/entity-field-schemas.md) §3.0 but are **mechanically unenforced** — the entire `V-CORE` family has **zero** executable references across the corpus's `.py`/`.sh` files, and the only executable reader of `entity_type` is the composer, which uses it as a discovery key rather than a validator. This exemption is therefore **governance-correctness**: it is stated so that a future mechanization does not fail a record the contract deliberately excludes. It closes no live enforcement gap and must not be cited as though it does.

**What this contract owns vs. what parameterizes it.** This contract owns the field set (§2), the `last_published` freshness field and the `[STALE]` render marker and the staleness **anchor definition** (§3), and the `PORTFOLIO.md` section-schema map (§4). The portfolio health-score work item supplies the threshold **values** that parameterize the one staleness mechanism in §3 — it introduces no second freshness field. The deterministic composer is the execution engine that renders §4 from §2; this contract is its input schema.

## §2 Per-project publishing schema (7 fields)

The per-project rollup entity (`[Project]_Rollup.md`, templated at [`../../operations/templates/project-rollup-template.md`](../../operations/templates/project-rollup-template.md)) carries exactly these seven fields. `Req` = required/optional. `Cadence` = the per-field refresh rhythm, drawn from the existing operational-artifact cadence vocabulary {daily, weekly, on-event}. `Source entity` names the frozen entity the field READS (entity numbers per [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md) §4).

| Field | Type | Req | Cadence | Source entity (READS) | Notes |
|---|---|---|---|---|---|
| `status` | enum {`green`, `yellow`, `red`} (RAG) | Required | weekly (published) · daily (refreshed) | Project (entity 1) — `health_rag`; ppm-agent derives + maintains | worst-component dominance — the existing Section-1 health rule + the §7.1 watermelon gate; a subsystem `red` cannot roll up to portfolio `green`. Source is the **derived projection**, not a self-reported value: the bands and the transparent worst-component roll-up rule are owned by `comms-writer/references/channel-formats.md` § RAG Threshold Standards (ADR-065, retained owner), the metric→band **index** is `weekly-status-rollup/references/metric-registry.md` § Project Metrics, and composition is executed in `weekly-status-rollup` Section 1. `health_derived_date` is `health_rag`'s required companion stamp (V-PRJ-11) |
| `top_risks[]` | array&lt;{`risk`, `owner`, `mitigation`}&gt;, ≤ 5 | Required | weekly | RAID Item (entity 6) — `impact` / `owner_person_id` / `action_plan`; tracker-manager maintains | passive-voice-free triples (platform guardrail); `impact` is the field the portfolio-rollup query keys on |
| `key_dependencies[]` | array&lt;{`from`, `to`, `state`}&gt; | Required | weekly · on-event (break) | Cross-Project Dependency / XPD (entity 15) — `from_entity_ref` / `to_entity_ref` / `lifecycle_state` (`open → satisfied \| broken \| waived`); ppm-agent maintains | — |
| `capacity_signal` | {`utilization`: float, `gap_rag`: enum} | Required | weekly | Resource (entity 8) — `allocation_pct`; delivery-engine maintains | the effective-capacity + Demand-Supply-Gap synthesis is owned by `weekly-status-rollup` §7.5 + `capacity-model.md` §1/§9 — **cite that synthesis by reference; do not re-derive it** |
| `milestone_delta` | {`next_milestone`, `target`, `actual`?, `state`} | Required | weekly · on-event (state change) | Milestone (entity 2) — `milestone_name` / `target_date` / `actual_date` / `lifecycle_state` (`planned → in-progress → completed \| cancelled`); delivery-engine maintains | — |
| `cross_project_conflicts[]` | array&lt;{`conflict`, `projects_affected[]`, `owner`, `mitigation`}&gt; | Required | weekly · on-event (detect) | Cross-Project Resource Conflict / XRC (entity 16) — `conflict_id` / `competing_project_ids` / `person_id` (`detected → acknowledged → resolved`); delivery-engine maintains | makes §4 S6 (Cross-Project RAID) and S8 (Resource Conflicts) **fully contract-driven** — the composer renders them from this field, not from agent-synthesized prose |
| `last_published` | ISO 8601 datetime | Required | on every publish | rollup meta | the **single** freshness field — drives the `[STALE]` marker per §3; no parallel freshness field exists |

**Absent-source behaviour for `status` (no silent default).** `health_rag` is an **optional** Project field while the rollup's `status` is **required**. When a project carries no `health_rag`, `ppm-agent` **emits no rollup for that project** — an honest coverage gap, mirroring the composer's existing `Unclassified` honesty pattern for an unset `investment_class` (§4 S4). It **must never default to `green`**: a defaulted health value is indistinguishable from a derived one at the render surface, which is precisely the watermelon failure the §7.1 gate exists to prevent.

**`completeness_score` is deliberately OMITTED.** No live producer emits it (0 producers / 0 consumers at authoring). A required field nothing populates is a spec-vs-reality defect; an optional stub invites divergence. The field is added atomically with its producer when a producer ships — not carried as an empty contract slot now.

**Drift detection.** A rollup field whose value type deviates from the type declared above is flagged for repair. The rollup is a composed surface: a field is valid only when it reads its named source entity's authoritative value.

## §3 The `[STALE]` staleness mechanism — pinned anchor

**Anchor (pinned by this contract).** A rollup's staleness age is measured as:

> **age = `today − last_published`, in BUSINESS days.**

The anchor is `today` (the current date at composition), **not** `max(last_published)` across projects. The fixed-`--as-of` form is scoped **only** to the composer's `--self-test` fixture (which pins a deterministic date so the fixture output is reproducible); in production the composer is invoked with **`--as-of=today`**. `weekly-status-rollup` Section 6 passes `--as-of=today`.

**Unit is business days** (the calendar-vs-business-day ambiguity is resolved here to business days, uniformly):

| Threshold | Effect |
|---|---|
| age `> 3 business days` | render `[STALE]` inline next to the aged field in the composed `PORTFOLIO.md` section |
| age `> 5 business days` | auto-degrade the field (the health-score layer treats an auto-degraded field as not-Green) |

This contract owns the `last_published` field, the `[STALE]` render marker, and the anchor definition above. The portfolio health-score work item supplies the two threshold **values** (`3` and `5` business days) that parameterize this one mechanism — it does **not** invent a second freshness field.

**Idempotency.** Because age anchors on `today − last_published`, re-running the composer with the same `--as-of` over an unchanged rollup produces byte-identical output — the freshness computation is a pure function of `(as_of, last_published)`.

## §4 PORTFOLIO.md section-schema map (Part A — the shared composition anchor)

The deterministic composer renders these `PORTFOLIO.md` sections from the §2 fields. `[EXISTING]` = a section `weekly-status-rollup` already writes (extend in place); `[NEW]` = net-new. This is the ONE section schema the four portfolio write-back work items in this release compose — the composer engine, the health score, and the risk profile each render or populate a slice of it.

| Sec | `PORTFOLIO.md` section | State | §2 contract field(s) | Backing entity |
|---|---|---|---|---|
| **S1** | `## Portfolio Health Summary` (per-project row: Phase · Health RAG · Critical-Path · Go-Live · **Last-Validated**) | EXISTING → extend | `status`, `milestone_delta`, `last_published` | Project (1), Milestone (2) |
| **S2** | per-project `### Health Indicators` (Schedule / Scope / Quality / Stakeholders / Integration; each `[STALE]` if aged) | EXISTING | — (the five dimensions are derivation **inputs** to `health_rag`, not a §2 contract field; indexed by `weekly-status-rollup/references/metric-registry.md` § Project Metrics under a **non-1:1** mapping — Quality composes Risk + Integration Risk, and Stakeholders is an optional `UNSOURCED-DOMAIN` row that may not exist). **Render posture (interim, stated honestly):** the composer today renders the single composed `health_rag` scalar against all five dimension labels; per-dimension sourcing is **not yet delivered** and no §2 field carries it | Project (1) |
| **S3** | `## Capacity Dashboard` (per-project utilization + portfolio demand-supply gap RAG) | NEW | `capacity_signal` | Resource (8) |
| **S4** | `## Portfolio R-G-T Allocation` (Run / Grow / Transform shares; `Unclassified` coverage gap) | NEW | — (reads `PROJECT.md` `investment_class`) | Project (1) |
| **S5** | per-project `### Top Risks` (≤ 5 rows: risk · owner · mitigation) | EXISTING → extend | `top_risks[]` | RAID Item (6) |
| **S6** | `## Cross-Project RAID` (aggregated 6-column shell: `Type · Item · Owner · Mitigation · Source-Tier · Projects-Affected`; `Type` = source leg {Risk, Dependency, Conflict}, `Source-Tier` = `Project` for the RAID leg · `Portfolio` for XPD/XRC; a risk-bearing row missing an owner/mitigation renders an inline `[DRIFT: incomplete risk record]` repair flag) | NEW | `top_risks[]` + `key_dependencies[]` + `cross_project_conflicts[]` | RAID Item (6) + XPD (15) + XRC (16) |
| **S7** | `## Cross-Project Dependencies` | EXISTING | `key_dependencies[]` | XPD (15) |
| **S8** | per-project `### Resource Conflicts` | EXISTING | `cross_project_conflicts[]` | XRC (16) |
| **meta** | `Last Updated` (portfolio-level) + inline `[STALE]` markers | mechanism | `last_published` + per-field cadence | — |

**Coherence rules (bind every producer of this schema):**
- **One staleness mechanism.** §3 is the sole freshness apparatus: one `last_published` field, one `[STALE]` marker, one anchor. Threshold values parameterize it; they do not fork it.
- **One cross-project risk surface.** S6 is a single aggregated section. S5 (per-project) and S6 (cross-project) are distinct scopes of one risk model — composed, never duplicated. `cross_project_conflicts[]` makes S6/S8 render deterministically from fields.
- **Staging-only.** Every section is composed content staged via `weekly-status-rollup` Section 6's human-in-the-loop checkpoint (§1 boundary). No producer writes `projects/`.

## §5 Emit / consume wiring

**Emit (ppm-agent).** `ppm-agent` maintains the Project entity, runs the daily processing cycle, and is the emitter for entity-lifecycle transitions. On its scheduled cadence it emits / refreshes the per-project rollup entity per this contract — **READING** each source entity (§2) and staging its value into the rollup field, never re-deriving an authoritative value the source entity owns. The emission rides the existing `TRACKER_UPDATE` carrier (`../../operations/skills/ppm-agent/SKILL.md` § 8.7 / § 8.8) — no new mechanism. The evidence gate binds unchanged: a source value that is `[ASSUMPTION – CONFIRM]` is surfaced as a "Decisions needed" line, not emitted.

**Consume (weekly-status-rollup).** `weekly-status-rollup` Section 6 CONSUMES the per-project rollup entity and composes the `PORTFOLIO.md` sections (§4) from the contract fields rather than re-deriving each field. In production the deterministic composer is invoked with `--as-of=today` (§3), honors the `[STALE]` marker, and stages the result for the Cowork writer at the Section-6 human checkpoint.

## §6 Cutover & provenance

**Cutover discipline.** Applies to all portfolio write-back composition going forward. The contract is additive — it formalizes the schema the prior hand-synthesis already read; no data migration is required (the `PORTFOLIO.md` restructure replaces handwritten content in place).

**Reversibility:** MODERATE / Confidence HIGH — the contract, the template, and the skill wiring are git-revertable up to the release gate; the `PORTFOLIO.md` restructure is cosmetic (replaces handwritten content, no stored data lost).

## Provenance

The G7 project-to-portfolio rollup-contract work item in the `pda-rollup-and-portfolio` release (project-data-architecture initiative, portfolio write-back layer). Composes: the deterministic `PORTFOLIO.md` composer work item (renders §4 from §2), the portfolio health-score work item (supplies the §3 threshold values + the freshness hard-gate), the portfolio risk-profile work item (populates S6 aggregation), and the operational tier-taxonomy work item (the `project_id` kebab-case `*_id` convention the rollup entity conforms to).
