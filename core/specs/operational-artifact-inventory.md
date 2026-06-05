<!-- repo-integrity: allow-issue-ref -->
# Operational-Artifact Inventory (first-pass)

**Status:** Canonical (first-pass — incremental-fill posture)
**Owner:** `pmo-platform/reference/specs/operational-artifact-inventory.md`
**Introduced:** project-data-foundation initiative (2026-05-16) — project-data-architecture initiative, roadmap `<OPERATOR_INSTANCE_ROADMAPS_PATH>/project-data-architecture.md` (operator-local)
**Establishing scope:** N1 — first-pass operational-artifact inventory, W1 work-stream
**Architectural basis:** the Two-Axis Entity Lifecycle ADR (**RATIFIED** at Collective Review, 2026-05-16)
**Source-entity authority:** [`project-entity-model.md`](../disciplines/project-entity-model.md) (17-entity roster + owning-agent matrix, FROZEN)
**Consumers (downstream):** N2 (template standard — consumes this inventory to scope entity-derived templatization) · N3 (templatization harness — consumes the `⚠ FINDING-3` set as its known-exception register)
**Cross-references:** see [§7](#7-cross-references).

---

## AC Build-Checklist (AC-1..AC-5 + Finding-3 catch traceability)

This doc satisfies the five acceptance criteria plus the task-mandated Finding-3 structural catch. Transcribed from the FROZEN Stage-5 spec — **no re-design; transcription + instantiation only**.

| AC | Discharged by | Verification |
|---|---|---|
| AC-1 (≥40 artifacts × 5 classes) | [§5](#5-the-inventory) via the D7 recipe (~48 rows) | `grep -c` §5 data rows ≥ 40; all 5 `class` values present |
| AC-2 (every row →  source-entity or `[ASSUMPTION – CONFIRM]`) | [§2](#2-column-schema) col 3 + [§4](#4-source-entity-derivation-rule); mandatory | no blank `source_entity`; values ∈ {#1..17, `[ASSUMPTION – CONFIRM]`, `⚠ NO-ENTITY-HOME (FINDING-3)`} |
| AC-3 (template-status + schema-status + owning-skill populated or explicit) | [§2](#2-column-schema) cols 5,6,7; mandatory | no blank in cols 5/6/7; `absent`/`unknown` explicit |
| AC-4 (`tracker-schemas.md` pointer) | additive line in `tracker-schemas.md` §Purpose | pointer link resolves; distinct from prior line |
| AC-5 (first-pass header string) | [§1](#1-purpose) verbatim disclaimer | exact-string grep |
| **Finding-3 catch (task mandate)** | [§2](#2-column-schema) col 8 + [§6](#6-derived-signals)(b); mandatory-coverage | every §5 row has non-blank `reconciliation_flag`; `grep "⚠ FINDING-3"` returns the class population |

---

## 1. Purpose

This document is a **first-pass authoritative inventory** of every operational artifact produced or maintained in the operational space (Layer 2 `projects/`), mapping each artifact to its source entity (per [`project-entity-model.md`](../disciplines/project-entity-model.md), ), its current template status, its current machine-schema status, its owning skill/tool, and its file format. It is the **W1 work-stream** of the reframed project-data-foundation capability — the spine from which the template standard (N2, ) and the enforcement harness (N3, ) derive. It is a Layer 1 reference doc *about* Layer 2 artifacts; it does not instantiate or write any Layer 2 file (identical posture to how `tracker-schemas.md` defines the schema for Layer 2 trackers — no boundary violation).

> This inventory is a first-pass consolidation — not exhaustive; gaps are marked [ASSUMPTION – CONFIRM] and tracked for incremental fill (templatization harness keeps it live going forward).

## 2. Column Schema

The inventory uses an **8-column FROZEN schema** (transcribed verbatim from  D2). The -body seed (7 columns) is extended by one load-bearing column — `reconciliation_flag` — the **structural catch for the Finding-3 gap class**: every row carries it, so `grep "⚠ FINDING-3"` returns the full gap-class population by construction (not ad-hoc discovery).

| # | Column | Type | Controlled values | Derivation rule (deterministic — Stage 6 does not interpret) |
|---|---|---|---|---|
| 1 | `artifact` | string | canonical filename pattern or artifact name | Verbatim from the seed source (file-pattern for trackers; artifact name for generated/typed) |
| 2 | `class` | enum(5) | `core-tracker` · `methodology-variant-tracker` · `structural-file` · `generated-artifact` · `typed-plan` | §3 ordered discriminator decision tree (top-down, first match wins) |
| 3 | `source_entity` | ref \| flag | `#N <EntityName>` (1..17 per project-entity-model §4 roster) · `[ASSUMPTION – CONFIRM]` · `⚠ NO-ENTITY-HOME (FINDING-3)` | §4 primary-entity rule |
| 4 | `format` | enum | `.csv` · `.md` · `.json` · `.csv (+Confluence dual)` | From file pattern in seed source; RAID Log = dual per `tracker-schemas.md` §Confluence Dual-Format |
| 5 | `template_status` | path \| enum | `reference/templates/<file>` · `absent` · `[ASSUMPTION – CONFIRM]` | Match artifact against the `templates/README.md` Registered-Templates table + `deploy.sh TEMPLATE_SYNC_MAP`; populate path if registered, else `absent` |
| 6 | `schema_status` | enum(EAD-aligned) | `entity-derived` · `prose-only` · `absent` · `[ASSUMPTION – CONFIRM]` | `entity-derived` iff an `EAD(E,C,D,mode)` machine-schema file exists; else `prose-only` iff a prose schema exists in `tracker-schemas.md`/a `schemas/` doc; else `absent` |
| 7 | `owning_skill` | string \| enum | skill name · `unknown` | The **Maintains** agent of `source_entity` from  §6 (owning-agent matrix), cross-checked against `per-skill-output-contracts.md`; `unknown` if `source_entity` is a FINDING-3 flag |
| 8 | `reconciliation_flag` | enum | `clean` · `context-implicit` · `composite-multi-entity` · `⚠ FINDING-3 (artifact-element-no-entity-home)` · `[ASSUMPTION – CONFIRM]` | §4 / §6 — EAD-crosswalk completeness, **both directions**. **Mandatory on every row.** |

**Why 8 and not more (anti-gold-plating, first-pass discipline):** an `ead_readiness` 9th column was considered and **rejected** — EAD-derivability is a *pure function* of columns 3+6+8 (`source_entity` resolves ∧ `schema_status`≠absent-blocked ∧ `reconciliation_flag`∈{clean,context-implicit}). It is specified as a derived **rule** in [§6](#6-derived-signals), not a stored column, to keep the first pass lean and avoid a denormalized column that drifts. The free-text `Notes` annotation in §5 is not a 9th controlled column — it carries the D4a secondary-entity enumeration and the D4b OOS-3 content-lifecycle seam, exactly as the frozen anchor table format prescribes.

## 3. Class Taxonomy + Decision Tree

The 5 class definitions are **mutually exclusive by construction** — classification runs the decision tree top-down, first-match-wins (the discriminator-rule discipline; Stage 6 never guesses a class).

| Class | Definition | Discriminator (the deterministic test) |
|---|---|---|
| `core-tracker` | One of the 5 canonical operational trackers populated for **every** project regardless of `delivery_approach`; carry-forward operational memory | Artifact appears as a numbered **Tracker 1–5** in `tracker-schemas.md` |
| `methodology-variant-tracker` | A tracker populated **conditionally** per `delivery_approach`; named in the §Methodology Variation matrix | Artifact appears in the `tracker-schemas.md` §Methodology Variation "Applies to" column **and is not** a Tracker 1–5 |
| `typed-plan` | A `Plan`-entity instance (`content_lifecycle_pattern = Baselined (A)`) discriminated by `plan_type` | `source_entity` resolves to **#4 Plan** |
| `generated-artifact` | A skill-produced **on-demand** output (produced fresh per invocation, not continuously maintained) | Artifact appears as a Skill-N **Output Contract** deliverable in `per-skill-output-contracts.md` |
| `structural-file` | A non-tracker file that persists an entity's **own state record** as primary content; one-per-scope (not an append-event-log) | Default — none of the four tests above matched; the file persists a single entity's record (e.g., PROJECT.md ⊇ Project #1) |

**Decision tree (applied in this exact order):** ① numbered Tracker 1–5? → `core-tracker`. ② else in §Methodology Variation? → `methodology-variant-tracker`. ③ else `source_entity == #4 Plan`? → `typed-plan`. ④ else a `per-skill-output-contracts.md` Output-Contract deliverable? → `generated-artifact`. ⑤ else → `structural-file`.

## 4. Source-Entity Derivation Rule

**Primary rule:** `source_entity` = the entity (per [`project-entity-model.md`](../disciplines/project-entity-model.md) §4, 17-roster) whose **record the artifact primarily persists or aggregates**, cross-validated by the owning-agent matrix (the artifact's owning skill should be that entity's Create/Maintain agent — per project-entity-model §6).

**Three sub-rules (all FROZEN):**

- **(a) Aggregator/composite artifacts** (e.g., Daily Status Log carries Blockers≈RAID Item + Decisions≈Decision + Actions + Meetings): `source_entity` = the dominant record-type entity; `reconciliation_flag = composite-multi-entity`; the row Notes enumerate the secondary entities. Do **not** force a single clean entity onto a genuinely multi-entity aggregator.
- **(b) OOS-3 Artifact-seam** (per §4 entity #9): generated artifacts that are *themselves* "Artifacts" (reports, packages, transcripts-as-files) → `source_entity = #9 Artifact`; the row Notes record `content_lifecycle = inherits-per-file (A/B/C)` — the reconciliation seam to `frontmatter-schema.md`. G3/G4 physicalizes; **noted, not resolved here**.
- **(c) No-entity-home** (the Finding-3 macro case): if no roster entity primarily persists the artifact's records (the artifact tracks a concept absent from the frozen 17-roster), `source_entity = ⚠ NO-ENTITY-HOME (FINDING-3)`. Do **NOT** add an entity (redefining the frozen surface is forbidden — Tier-2 SCOPE CHANGE territory, not a spoke action). Flag the row; downstream triage (N2/N3 or a future roster reopen) decides disposition.

**Ratified Communications-Tracker policy (Collective Review 2026-05-16, decision item 4):** the Communications Tracker has no entity home in the frozen 17-roster — recorded as `source_entity: ⚠ NO-ENTITY-HOME (FINDING-3)`, `reconciliation_flag: ⚠ FINDING-3`, **flag + carry as `out-of-standard-until-reconciled` known-exception**. Entity-roster expansion (adding a Communication entity) is a SEPARATE downstream decision (future roster reopen / later milestone) — **NOT in scope**. The flagged row *is* the deliverable; it routes the gap to downstream triage.

## 5. The Inventory

8-column FROZEN schema (§2); rows instantiated from the D7 deterministic enumeration recipe (5 core-tracker + 21 methodology-variant + 6 structural-file + 10 generated-artifact + 6 typed-plan = **48 ≥ AC-1's 40 floor by construction**). Class assigned via the §3 decision tree; every column derived per §2; every row carries a non-blank `reconciliation_flag` (the mandatory-coverage invariant — the Finding-3 catch enforcement point).

### 5.1 core-tracker (5) — from `tracker-schemas.md` Trackers 1–5

| artifact | class | source_entity | format | template_status | schema_status | owning_skill | reconciliation_flag | Notes |
|---|---|---|---|---|---|---|---|---|
| `[Project]_Daily_Status_Log.md` | core-tracker | entity 6 RAID Item | .md | `reference/templates/daily-status-log-template.md` | prose-only | tracker-manager | composite-multi-entity | Aggregator (D4a): dominant=entity 6 RAID Item; secondaries entity 5 Decision, entity 7 Meeting, entity 10 Person. Operational producer cross-check: `daily-status` |
| `[Project]_Communications_Tracker.md` | core-tracker | ⚠ NO-ENTITY-HOME (FINDING-3) | .md | `reference/templates/communications-tracker-template.md` | prose-only | unknown | ⚠ FINDING-3 (artifact-element-no-entity-home) | **RATIFIED decision item 4** — no Communication entity in frozen 17-roster; out-of-standard-until-reconciled known-exception; flag + carry; entity-roster expansion NOT in scope; do **NOT** add an entity |
| `[Project]_Open_Meetings_Tracker.md` | core-tracker | entity 7 Meeting | .md | `reference/templates/open-meetings-tracker-template.md` | prose-only | ppm-agent | clean | Owning-agent cross-check: file-router creates, ppm-agent maintains ( §6) |
| `[Project]_Transcript_Register.md` | core-tracker | #9 Artifact `[ASSUMPTION – CONFIRM]` | .md | `reference/templates/transcript-register-template.md` | prose-only | ppm-agent (route: file-router) | context-implicit | Passive search/reference index of transcript-Artifacts; `project_id` filename-implicit; "index not tracker" behavioral nuance (tracker-schemas.md Tracker 4 note) flagged, not forced |
| `[Project]_RAID_Log.csv` | core-tracker | entity 6 RAID Item | .csv (+Confluence dual) | `reference/templates/raid-log-template.csv` | entity-derived | tracker-manager | clean | **EAD pilot proven** ([`raid-log.schema.json`](../schemas/raid-log.schema.json)) — the **only** first-pass `entity-derived` artifact; `impact`/`action_plan` re-frozen first-class per the Stage 5 Option-A spec |

### 5.2 methodology-variant-tracker (21) — from `tracker-schemas.md` §Methodology Variation "Applies to" (dedup union across 7 archetypes)

| artifact | class | source_entity | format | template_status | schema_status | owning_skill | reconciliation_flag | Notes |
|---|---|---|---|---|---|---|---|---|
| `sprint-burndown.md` | methodology-variant-tracker | #2 Milestone `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Scrum/XP; sprint≈milestone-scale, entity fit first-pass-uncertain. Relates to `sprint-tracker-template.md` (not individually registered) |
| `sprint-velocity.md` | methodology-variant-tracker | #2 Milestone `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | FROZEN  D4 illustrative anchor (verbatim): Scrum-only; entity fit first-pass-uncertain |
| `risks.md` | methodology-variant-tracker | entity 6 RAID Item | .md | absent | absent | tracker-manager | context-implicit | Methodology-scoped projection of the Risk subset of RAID Items |
| `decisions.md` | methodology-variant-tracker | entity 5 Decision | .md | absent | absent | tracker-manager | context-implicit | Methodology-scoped Decision view (sprint/iteration-keyed) |
| `flow-efficiency.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Kanban flow metric; no frozen entity persists "flow efficiency" — first-pass deferred |
| `cycle-time.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Kanban flow metric; first-pass deferred to downstream triage |
| `throughput.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Kanban flow metric; first-pass deferred |
| `ci-health.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | XP engineering-health; no frozen entity home — first-pass deferred |
| `test-coverage.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | XP engineering-health; first-pass deferred |
| `pair-rotation.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | XP; relates to entity 8 Resource / entity 10 Person allocation — entity fit first-pass-uncertain |
| `milestone-status.md` | methodology-variant-tracker | #2 Milestone | .md | absent | absent | delivery-engine | context-implicit | Waterfall; directly persists Milestone records (Maintains=#2 Milestone → delivery-engine). Relates to `milestone-tracker-template.md` (not individually registered) |
| `phase-gate-log.md` | methodology-variant-tracker | #2 Milestone `[ASSUMPTION – CONFIRM]` | .md | absent | absent | delivery-engine `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Waterfall; phase-gate≈milestone-checkpoint — entity fit first-pass-uncertain |
| `change-control-log.md` | methodology-variant-tracker | entity 5 Decision `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Waterfall; change requests≈Decision records — entity fit first-pass-uncertain |
| `stage-boundary.md` | methodology-variant-tracker | #2 Milestone `[ASSUMPTION – CONFIRM]` | .md | absent | absent | delivery-engine `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | PRINCE2 end-stage-assessment; stage≈milestone-scale — first-pass-uncertain |
| `highlight-reports.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | PRINCE2 highlight-report; tracker-classed per §3② (in §Methodology Variation) before generated-artifact test — entity fit first-pass-uncertain |
| `issue-register.md` | methodology-variant-tracker | entity 6 RAID Item | .md | absent | absent | tracker-manager | context-implicit | PRINCE2 REQUIRED; methodology-scoped projection of the Issue subset of RAID Items |
| `lessons-log.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | PRINCE2 REQUIRED; no "Lesson" entity in frozen roster — **candidate no-entity-home**, first-pass deferred (NOT anchored as FINDING-3 by the Stage 5 spec; downstream triage decides) |
| `pi-objectives.md` | methodology-variant-tracker | #2 Milestone `[ASSUMPTION – CONFIRM]` | .md | absent | absent | delivery-engine `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | SAFe PI-cadence; PI≈milestone-scale — first-pass-uncertain |
| `art-metrics.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | SAFe ART predictability/program-velocity metric; no frozen entity home — first-pass deferred |
| `feature-progress.md` | methodology-variant-tracker | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | tracker-manager `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | SAFe; relates to #2 Milestone / #3 Workstream — entity fit first-pass-uncertain |
| `dependencies-map.md` | methodology-variant-tracker | entity 15 Cross-Project Dependency | .md | absent | absent | ppm-agent | context-implicit | SAFe; methodology-scoped projection of Cross-Project Dependency records |

### 5.3 structural-file (6) — CLAUDE.md Governance File Map + `projects/_config/`

| artifact | class | source_entity | format | template_status | schema_status | owning_skill | reconciliation_flag | Notes |
|---|---|---|---|---|---|---|---|---|
| `PROJECT.md` | structural-file | #1 Project | .md | `reference/templates/project-md-template.md` | prose-only | ppm-agent | clean | Project entity ⊇ PROJECT.md ( §2 D1); `project-schema.md` is the persistence dialect (prose schema, not EAD machine-schema) |
| `PORTFOLIO.md` | structural-file | entity 13 Portfolio | .md | absent | absent | weekly-status-rollup | clean | Portfolio-level → `projects/_config/`; Layer-2 bridge file (Claude Code read-only per operations-bridge.md) |
| `SESSION_STATE.md` | structural-file | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Session-continuity bridge file; no frozen-entity home — first-pass deferred (candidate no-entity-home, NOT anchored by the Stage 5 spec) |
| `CORRECTIONS.md` | structural-file | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Cowork-owned behavioral-corrections config; no frozen-entity home — first-pass deferred |
| `SWAP_HANDOFF.md` | structural-file | `[ASSUMPTION – CONFIRM]` | .md | absent | absent | `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | account-switcher harness-written; no frozen-entity home — first-pass deferred |
| `key-terms-glossary` | structural-file | `[ASSUMPTION – CONFIRM]` | .csv | `reference/templates/key-terms-glossary-template.csv` | absent | `[ASSUMPTION – CONFIRM]` | `[ASSUMPTION – CONFIRM]` | Stakeholder glossary index; registered template but no frozen-entity home — first-pass deferred |

### 5.4 generated-artifact (10) — from `per-skill-output-contracts.md` Skill-N Output Contracts

All map to `source_entity = #9 Artifact` (OOS-3 Artifact-seam); `reconciliation_flag = context-implicit` (the #9-Artifact mapping resolves via the OOS-3 seam; `content_lifecycle = inherits-per-file (A/B/C)` recorded in Notes — the seam to `frontmatter-schema.md`, physicalized at G3/G4). `owning_skill` = Maintains(#9 Artifact) = `ppm-agent (route: file-router)` per §2 col 7; the producing skill is the per-skill-output-contracts.md cross-check (Notes).

| artifact | class | source_entity | format | template_status | schema_status | owning_skill | reconciliation_flag | Notes |
|---|---|---|---|---|---|---|---|---|
| executive status report | generated-artifact | #9 Artifact | .md | `reference/templates/executive-status-report-prompt-template.md` | absent | ppm-agent (route: file-router) | context-implicit | Producer: ppm-agent / comms-writer. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| weekly status roll-up | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: weekly-status-rollup. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| decision briefing | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: ppm-agent. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| change-impact assessment | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: change-management. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| technical-analysis report | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: pmo-technical-analyst. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| requirements / FRD | generated-artifact | #9 Artifact | .md | `reference/templates/requirements-template.md` | absent | ppm-agent (route: file-router) | context-implicit | Producer: pmo-process-designer. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| traceability matrix | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: pmo-process-designer. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| build-reviewer findings register | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: build-reviewer. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| daily-status Teams update | generated-artifact | #9 Artifact | .md | `reference/templates/daily-status-update-framework-template.md` | absent | ppm-agent (route: file-router) | context-implicit | Producer: daily-status. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |
| comms drafts | generated-artifact | #9 Artifact | .md | absent | absent | ppm-agent (route: file-router) | context-implicit | Producer: comms-writer. `content_lifecycle = inherits-per-file (A/B/C)` — OOS-3 seam |

### 5.5 typed-plan (6) — `source_entity == #4 Plan`

All `source_entity = #4 Plan`; `owning_skill` = Maintains(#4 Plan) = `ppm-agent` ( §6); `reconciliation_flag = clean` (Plan entity directly persists these). `plan_type` discriminator value domain is **deferred to G5** ( §4 entity #4 — the field is required now; its enum is G5's).

| artifact | class | source_entity | format | template_status | schema_status | owning_skill | reconciliation_flag | Notes |
|---|---|---|---|---|---|---|---|---|
| `v[X.Y]_RELEASE_PLAN.md` | typed-plan | #4 Plan | .md | absent | absent | ppm-agent | clean | FROZEN D4 illustrative anchor: `plan_type=release` (enum value deferred to G5 per the Stage 5 spec §4 / Finding 2) |
| implementation plan | typed-plan | #4 Plan | .md | absent | absent | ppm-agent | clean | `plan_type=implementation` `[ASSUMPTION – CONFIRM @ G5]` |
| project plan | typed-plan | #4 Plan | .md | absent | absent | ppm-agent | clean | `plan_type=project` `[ASSUMPTION – CONFIRM @ G5]` |
| test plan | typed-plan | #4 Plan | .md | absent | absent | ppm-agent | clean | `plan_type=test` `[ASSUMPTION – CONFIRM @ G5]` |
| comms plan | typed-plan | #4 Plan | .md | absent | absent | ppm-agent | clean | `plan_type=comms` `[ASSUMPTION – CONFIRM @ G5]` |
| training plan | typed-plan | #4 Plan | .md | absent | absent | ppm-agent | clean | `plan_type=training` `[ASSUMPTION – CONFIRM @ G5]` |

**Row count:** 5 + 21 + 6 + 10 + 6 = **48** (≥ AC-1's 40 floor by construction). All 5 `class` values present. Every row carries a non-blank `source_entity`, `format`, `template_status`, `schema_status`, `owning_skill`, and `reconciliation_flag` (mandatory-coverage invariant satisfied).

## 6. Derived Signals

**(a) EAD-readiness rule (derived — not a stored column).** An artifact is **EAD-derivable** iff:

> `source_entity` resolves to #1..17 **∧** `schema_status` ≠ absent-without-entity **∧** `reconciliation_flag` ∈ {`clean`, `context-implicit`}

At first pass exactly **one** artifact satisfies this with a live machine-schema: `[Project]_RAID_Log.csv` (`entity 6 RAID Item` ∧ `entity-derived` ∧ `clean`). This is the precise signal N2 ( template standard) and N3 ( harness) consume to know which artifacts are ready for entity-derived templatization versus which are reconciliation-blocked.

**(b) Gap-class query (the Finding-3 structural catch).** The complete downstream-triage population is a single queryable set:

```bash
grep "⚠ FINDING-3" pmo-platform/reference/specs/operational-artifact-inventory.md
```

This returns every artifact whose `source_entity`/`reconciliation_flag` is `⚠ FINDING-3 (artifact-element-no-entity-home)` — the legacy-artifact-element-with-no-entity-home gap class, surfaced **by construction** (mandatory `reconciliation_flag` on all 48 rows), not by ad-hoc discovery. At first pass this returns the **Communications Tracker** (RATIFIED decision item 4 — `out-of-standard-until-reconciled` known-exception; entity-roster expansion is NOT in scope). N2 consumes this to scope entity-derived templatization; N3 consumes it as its harness known-exception register. Per-instance disposition is downstream's job — the inventory surfaces the class, it does not adjudicate each instance.

> **First-pass note on `[ASSUMPTION – CONFIRM]` rows:** rows flagged `[ASSUMPTION – CONFIRM]` on `source_entity`/`reconciliation_flag` are first-pass-unresolved crosswalks (not asserted gaps). They are deliberately distinguished from `⚠ FINDING-3` (an asserted reverse-gap). Several methodology-variant trackers (`lessons-log.md`, flow/metric trackers) and `projects/_config/` structural files (`SESSION_STATE.md`, `CORRECTIONS.md`, `SWAP_HANDOFF.md`) are **candidate** no-entity-home cases that the prior pass did not anchor as FINDING-3 — they are flagged for downstream triage, neither silently forced onto an entity nor silently asserted as gaps. The templatization harness drains these incrementally as their entities' field schemas land.

## 7. Cross-References

| Reference | Role relative to this inventory |
|---|---|
| [`project-entity-model.md`](../disciplines/project-entity-model.md) | **Source-entity + owning-skill authority.** §4 17-entity roster → `source_entity` col 3; §6 owning-agent matrix (Maintains) → `owning_skill` col 7. FROZEN derivation surface. |
| [`schemas/entity-field-schemas.md`](../schemas/entity-field-schemas.md) | Per-entity field/validation schemas — the `schema_status` tri-state alignment authority (entity-derived vs prose-only). |
| [`schemas/raid-log.schema.json`](../schemas/raid-log.schema.json) | The one first-pass `entity-derived` exemplar — EAD machine-schema for the RAID Log, derived from the RAID Item entity. |
| [`schemas/tracker-schemas.md`](../schemas/tracker-schemas.md) | Seed for the 5 `core-tracker` rows (Trackers 1–5) + the 21 `methodology-variant-tracker` rows (§Methodology Variation matrix). Carries the additive §Purpose pointer back to this inventory (AC-4). |
| [`schemas/per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md) | Seed for the 10 `generated-artifact` rows (Skill-N Output Contract deliverables) + the `owning_skill` cross-check. |
| [`templates/README.md`](../../operations/templates/README.md) | Registered-Templates table — the `template_status` col 5 derivation source. |
| the Two-Axis Entity Lifecycle ADR | Ratified Two-Axis Entity Lifecycle — the architectural basis the entity model (and thus this inventory's `source_entity` axis) hangs off. |
| the Collective Review decision record | RATIFIED Communications-Tracker disposition policy (item 4) applied in §4 / §5.1. |

---

*First-pass inventory complete. Incremental-fill posture: the templatization harness keeps this live going forward; `[ASSUMPTION – CONFIRM]` rows drain as entity field schemas land. The roster, decision tree, and column schema are FROZEN transcriptions of Stage-5 spec — changes require the Inter-Stage Feedback Protocol.*
