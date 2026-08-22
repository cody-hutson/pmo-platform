---
title: Migration Enforcement Protocol — entity-first target states for existing projects
purpose: The enforcement layer for migrating existing projects onto the entity-first target states — the deadline semantics that say when a migration is late, the MM-0..MM-3 telemetry that measures how far it has come, and the escalation contract an enforcement instrument emits when one stalls.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the structure-mode enforcement instrument that computes MM-0..MM-3 and emits the escalation contract; the project-initiator migration mode that remediates what the score reports; operators tracking migration progress across the portfolio
composes_with: progressive-rollout-convention.md, health-check-specification.md, project-schema.md
---
<!-- reference-durability: allow-link -->

# Migration Enforcement Protocol

**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Owner:** Platform engineering — project-data-architecture domain.
**Enforcement instrument:** the `structure` audit mode. This protocol governs *when* that instrument fires, *what* it measures, and *what happens* when a migration stalls; the instrument itself is delivered and owned elsewhere.

## 1. Purpose

The entity-first project data architecture has shipped its target states. Existing projects have not moved onto them, and — absent this protocol — nothing establishes when they must, how far along any one of them is, or what happens when one stops progressing.

This protocol supplies the three missing pieces: a **deadline model** (§ 3), a **telemetry vocabulary** with computable definitions (§ 4), and an **escalation contract** (§ 3.4) stating what the instrument emits at each project state. It schedules no migration and performs no write; it is the rule the instrument enforces.

## 2. Scope

### 2.1 In scope — the five target states

A project is *migrated* when all five hold. Each state is owned by an accepted decision record; this protocol restates none of them and cites all of them.

| # | Target state | Owning decision |
|---|---|---|
| 1 | `PROJECT.md` is a thin composed wiki-link index rather than a narrative-table monolith | [ADR-060](../ADRs/ADR-060-project-md-composed-index.md) |
| 2 | Person / System / Vendor records live once as shared entity pages, not as per-project inline tables | [ADR-058](../ADRs/ADR-058-pmo-entity-page-ssot.md) |
| 3 | Plans are typed sub-entities rather than untyped plan documents | [ADR-059](../ADRs/ADR-059-plan-type-open-discriminator.md) |
| 4 | Every file carries the required frontmatter fields | [frontmatter-schema.md](../schemas/frontmatter-schema.md) |
| 5 | Folders conform to the closed 5-bin taxonomy rather than the legacy 8-folder structure | [ADR-080](../ADRs/ADR-080-project-folder-taxonomy-closed-5-bin-set.md) |

### 2.2 Population — `ACTIVE` and `CLOSING`; `CLOSED` exempt

The protocol governs projects in lifecycle state `ACTIVE` or `CLOSING` per the 3-state model in the workspace charter's Project Lifecycle section.

`CLOSED` is **exempt**. A closed project is read-only reference with no operational processing, so migrating it buys nothing and spends a write that — on a tree with no version control — is EXPENSIVE and has only a snapshot as its reversal path. Excluded projects are **accounted for by count and reason** in every report, never silently dropped from a denominator.

### 2.3 Orientation-card back-fill disposition

Per-bin orientation cards are **not an independent back-fill**; they are an output of the folder-taxonomy migration step (target state 5). Two cases, both determinate:

- **Project still on the legacy 8-folder structure** → the cards land **when the folders are reshaped**, as part of the taxonomy migration. There are no 5-bin folders to hold a per-bin card, so a back-fill is incoherent before the reshape. Not separately scheduled.
- **Project already on the 5-bin set but scaffolded before the card-copy step shipped** → the cards **are back-filled**, as a one-time step inside the migration procedure. The target folders already exist; the only thing missing is the copy.

This protocol is the sole home of the existing-project deadline. A scaffolding change that copies cards into **newly created** projects does not pre-empt it and carries no back-fill step of its own.

### 2.4 Non-goals

- **It does not restate the per-project migration procedure.** The composed-index steps and the entity-seeding steps are defined once in [project-schema.md](../schemas/project-schema.md); § 5 cites them.
- **It does not set the enforcement instrument's rollout phase.** Whether the instrument observes, warns, or blocks is governed by [progressive-rollout-convention.md](progressive-rollout-convention.md). See § 3.5.
- **It does not execute the document-ecosystem engine's checks.** It consumes one check's *definition* as a shared source of truth and projects it; it runs no index query. See § 4.3.
- **It performs no migration write.** It measures, it declares a deadline, and it specifies an emission. Every mutation belongs to the gated procedures in § 5.

## 3. Deadline semantics

A three-part model. It binds **per-project** (D1, D2) and **workspace-wide** (D3), so both limbs are specified rather than one.

### 3.1 D1 — window population + anchor (per-project)

- **Population:** per § 2.2.
- **Anchor:** a per-project value `migration_window_opened`, resolved as the later of (a) this protocol's effective date and (b) the date the project entered `ACTIVE`. A project onboarded after this protocol ships is not born overdue.
- **Absence rule.** A project with **zero** recorded `structure`-mode runs is `UNMEASURED` — reported with what was searched and why it could not be measured, and **never** reported `OK`. A metric nobody has measured is not a metric that passed. Absence is a third value alongside pass and fail; collapsing it into either is the error this rule exists to prevent.

### 3.2 D2 — soft deadline: the stall predicate (per-project)

```
STALLED  ⇔  MM-0 < 100
             AND MM-0 has not increased across N = 2 consecutive structure-mode runs
```

- **`N = 2`.** The threshold generalizes the run-count escalation form already carried by the orphan-detection check in [health-check-specification.md](../specs/health-check-specification.md) — same document, same escalation class (a persistent non-zero defect count), adjacent check. It is not a new threshold.
- **Why a stall, not an elapsed clock.** Three reasons, in order of weight: (i) the corpus has **no day-count precedent** for a migration deadline — every migration deadline it carries is event-anchored, so a day count would be invented rather than grounded; (ii) a stall predicate is robust to irregular audit cadence, where an elapsed clock marks a project *overdue* that nobody has audited — a false finding about the operator rather than the corpus; (iii) it matches the vocabulary the downstream escalation already uses (*stalled*, not *overdue*).
- **Monotonicity, not activity.** *Has not increased*, not *has not changed*. A project improving by any margin per run is progressing and does not stall; an oscillating project does, because the test is against the maximum over the prior window rather than the immediately preceding value.
- **Evaluation domain.** The predicate is defined over `N` consecutive runs and is therefore **evaluable only once `N` runs are recorded**. Fewer than `N` recorded runs yields *no verdict* — which is not the verdict `not stalled`. Report it under the absence rule in § 3.1.

### 3.3 D3 — hard deadline: the convergence event (workspace-wide)

A project must reach `MM-0 = 100` **before the folder-taxonomy additive-union migration window closes.**

At convergence the legacy vocabulary stops being accepted and an unmigrated project's artifacts fail `folder` enum validation — [frontmatter-schema.md](../schemas/frontmatter-schema.md) states the union `{legacy 8} ∪ {5-bin + transient}` is explicitly a *window*, and that on convergence exactly **one live taxonomy** carries the concept.

**This protocol does not schedule convergence.** [ADR-080](../ADRs/ADR-080-project-folder-taxonomy-closed-5-bin-set.md)'s convergence tail owns that. This protocol declares convergence the hard backstop and defines the pre-convergence readiness gate. No version number appears in this rule — the rule names the *event*; the release that binds it is recorded in the release log, not here.

### 3.4 D4 — escalation contract

What the enforcement instrument must emit at each project state. Stated as an abstract emission contract — a report section plus required content — so that it binds any instrument that implements it.

| Project state | Emission | Report section |
|---|---|---|
| `UNMEASURED` | a coverage note stating what was searched and why it could not be measured | `## Unknowns` |
| in-window, `MM-0` Green | telemetry line only | `## Confirmed` |
| in-window, `MM-0` Yellow or Red, not stalled | telemetry plus a progress note | `## Decisions` |
| `STALLED` | a **FAIL naming the specific project** plus a remediation link to § 5 — never a bare count | `## Decisions` |
| post-convergence, `MM-0 < 100` | the FAIL above, plus the `folder` enum-validation consequence stated | `## Decisions` |

**Routing rule — never `## Auto-Actionable`.** A migration finding routes to `## Decisions` regardless of the confidence the instrument assigns it. This is a rule this protocol *imposes*, not a property it infers from the instrument's own confidence gate: a migration remediation is an EXPENSIVE, operator-gated write on a tree with no version control, and it must never reach a section whose contents an operator approves at a glance.

### 3.5 Boundary — deadline vs rollout phase

The deadline predicate is an **input to** the enforcement instrument. It is never a **promoter of** it.

Whether the instrument observes, warns, or blocks advances through the named phases in [progressive-rollout-convention.md](progressive-rollout-convention.md), and advancement there is an operator decision — that convention makes auto-promotion by a numeric threshold a deliberate non-goal. Stating this boundary is load-bearing: without it the platform acquires two dials that both look like *when does this start blocking*, with no precedence rule between them.

## 4. Telemetry metrics

Four metrics. `MM-1`, `MM-2` and `MM-3` are the three progress metrics; `MM-0` is the composite the deadline predicate reads.

**Definition-uniqueness.** This protocol is the **definitional home** of `MM-0`, `MM-1`, `MM-2` and `MM-3`. A downstream instrument **cites** these identifiers and computes them; it does not redefine them, and it mints no competing metric family for the same measurements. The identifiers are the load-bearing tokens — they are stable, greppable, and are not to be rendered only as prose labels.

**Grain declaration (binding).** Every metric declares its grain explicitly. All four are **reported per project**; they differ in the unit their numerator and denominator count. `MM-0` is a composite of three per-project factor values on a common 0–100 scale, so it multiplies commensurable numbers rather than mixed grains.

| ID | Name | Counting unit | Reporting grain | Corpus-grain rollup |
|---|---|---|---|---|
| `MM-0` | Migration Completeness | composite of the three factor values | per project | mean of the per-project values, denominator stated |
| `MM-1` | Entity Extraction Completeness | **entity record** | per project | sum of numerators / sum of denominators |
| `MM-2` | Frontmatter Completeness | **entity record** | per project | sum of numerators / sum of denominators |
| `MM-3` | Composed-Index Conformance | **project** | per project (a state) | projects in state `composed` / in-scope projects |

### 4.1 `MM-0` — Migration Completeness

**Definition.** `MM-0 = MM-1 × MM-2 × MM-3`, each factor taken as a fraction of 1 and the product rendered 0–100.

**Grain.** Per project. Each factor contributes its per-project value; no factor contributes a corpus-grain rollup.

**Consumers.** `MM-0` is the sole input to the stall predicate in § 3.2 and the value the escalation contract in § 3.4 bands.

**Stated property.** The product form means any single factor at 0 forces `MM-0 = 0`. A project with complete frontmatter and no entity extraction reads 0, not 33. This is intended — a migration is not partially done in a way that composes additively across the five target states — but it is stated here rather than discovered downstream.

### 4.2 `MM-1` — Entity Extraction Completeness

**Definition.** Entities referenced by the project that **resolve to a materialized entity record at their declared storage-tier home**, divided by entities referenced by the project.

**Grain.** Entity record, evaluated per project.

**Computation rule.**

- *Referenced* is read from `PROJECT.md`: a wiki-link target in a composed index, or a table row in an unmigrated monolith. **Both are references** — an unmigrated project has referenced entities, it just has not extracted them.
- *Materialized* means a record present at the entity's `storage_tier` home per the Storage-Location Map in [project-entity-model.md](../disciplines/project-entity-model.md) — the shared-entity home for Person / System / Vendor, the project-scoped home for typed Plans.
- **Only `persistence_mode: file-backed` entities are countable.** An `embedded-in-parent` or `computed` entity has no independent artifact to detect, so counting it would make the denominator unmeasurable. See § 4.6.

### 4.3 `MM-2` — Frontmatter Completeness

**Definition — consumed, not re-authored.** The metric definition, its severity, its cadence and its status bands are those of the **Frontmatter Completeness** check in [health-check-specification.md](../specs/health-check-specification.md): *completeness rate = records with all required fields / total records*. This protocol cites that definition and restates none of it.

**Grain — entity record, evaluated per project.** The consumed check is defined at the **file** grain. This protocol **projects** it onto the entity-record grain, because a logical entity is a data record the PMO tracks and the file that persists it is a separate concern with its own lifecycle — conflating the two is forbidden by the boundary axiom in [project-entity-model.md](../disciplines/project-entity-model.md). The reuse obligation stands; the file-grain population does not. `MM-0` must never multiply an entity-grain ratio by a file-grain one.

**Required-field set — resolved by reference, never enumerated here.** For an entity record, the required set is the fields whose intra-record (`L1`) presence rules are declared in [entity-field-schemas.md](../schemas/entity-field-schemas.md) — the inherited core rule set plus the entity's own per-entity rules. For a persisted file, the required set is the `Required: Yes` column of [frontmatter-schema.md](../schemas/frontmatter-schema.md). **Do not enumerate either set in this file.** An inline enumeration becomes a hardcoded duplicate of a schema column and drifts from it; one such drift already exists in the corpus, and this protocol routes around it rather than adding a third copy.

**Semantics boundary.** `MM-2` measures **presence**, not taxonomy convergence. While the additive-union window is open, a record carrying a legacy `folder` value is *complete* — the enum accepts the union. Folder-taxonomy migration is carried by D3's convergence backstop in § 3.3, and is deliberately not smuggled into a completeness percentage.

**Computation path — projected, not executed.** `MM-2` is computed by reading frontmatter from the corpus. It does **not** run the document-ecosystem engine's index query: the enforcement instrument does not own or run that engine, and no index artifact is committed for it to query. Consuming a definition and projecting it is the reuse pattern the instrument already applies to the shared staleness band scale; this protocol adopts it rather than inventing a second one.

### 4.4 `MM-3` — Composed-Index Conformance

**Definition — a three-state per-project value.**

```
composed ⇔  PROJECT.md length ≤ 50 lines
        AND zero markdown table rows inside the entity sections
            (People / Systems / Milestones / Plans / Workstreams)
        AND every wiki-link target resolves to an existing entity record
monolith ⇔  zero wiki-link targets in the entity sections
partial  ⇔  otherwise
```

The `≤ 50` line criterion and the composed-index shape are [ADR-060](../ADRs/ADR-060-project-md-composed-index.md)'s, consumed rather than invented.

**Grain.** Project. The reported value is the state; the corpus-grain rollup counts *projects in state `composed`*, never links.

**The zero-denominator trap, handled explicitly.** An unmigrated monolith has **zero** wiki-links. A naive link-integrity ratio would compute `0/0` and render 100% — reporting the least-migrated project as perfectly migrated. The three-state form makes `monolith` a distinct value that can never be mistaken for `composed`. This is the most likely silent-wrong-answer in the metric set, and it is why `MM-3` is not defined as a link ratio.

**Factor projection — the 0–100 value `MM-0` consumes.** The reported value stays the state. The factor value is:

| State | Factor value |
|---|---|
| `composed` | 100 |
| `partial` | the satisfied-conjunct rate of the `composed` predicate, rendered 0–100 |
| `monolith` | 0 |

`monolith → 0` is pinned rather than computed, so a short monolith can never earn a non-zero factor from the line-count conjunct alone.

### 4.5 Status bands

All four metrics band as **Green 100% · Yellow 90–99% · Red < 90%**, per the Health Status Thresholds table in [health-check-specification.md](../specs/health-check-specification.md). That table already applies this identical triple to two different completeness rates, so it is the corpus's generic completeness-rate band rather than a check-specific one. **No new band is canonicalized here.**

`MM-3`'s band applies to its factor value; its reported three-state value is a state, not a percentage, and is reported as such.

### 4.6 Declared coverage bounds

Stated as bounds rather than left implicit, so that a reader knows what the numbers do **not** cover.

1. **`MM-1` counts file-backed entities only.** Entities whose `persistence_mode` is `embedded-in-parent` or `computed` are structurally undetectable as independent artifacts and are outside the metric. This is a declared bound, not an omission.
2. **An empty denominator is `UNMEASURED`, never a percentage.** If a metric's denominator is zero for a project — no referenced entities, no in-scope records — the metric yields `UNMEASURED` and routes to `## Unknowns` per § 3.1. It never renders as 100%. A ratio over an empty population reports an untouched project as a finished one, which is the same absence-vs-zero error the absence rule exists to prevent, one level down.
3. **Every reported value carries its numerator and its denominator.** A metric never renders as a bare number, and the excluded set is enumerated alongside it.
4. **The entity-record population is seeded by a gated procedure, not by this protocol.** `MM-1` and `MM-2` are defined over entity records; until the entity-seeding procedure cited in § 5 has run for a tier, that tier's population is empty and bound 2 applies. This is the expected state on the day this protocol ships, not a defect in it.
5. **`MM-0`'s stall predicate requires cross-run state.** Evaluating § 3.2 requires the prior `N` runs' `MM-0` values to be readable. Where no prior-run source exists, D2 is specified but not yet evaluable, and every affected project reports under the absence rule rather than as `not stalled`.

## 5. Procedure pointer

The remediation procedures are defined once, in [project-schema.md](../schemas/project-schema.md), and are cited here rather than restated:

- **Composed-Index Migration Protocol** — the gated, per-project, snapshot-before / verify-after procedure that moves a live `PROJECT.md` from the narrative-table monolith to the composed-index shape. It covers target states 1, 2 and 3. It is the remediation link the `STALLED` emission in § 3.4 points to.
- **Entity-Seeding Protocol** — the gated, per-tier procedure that populates the operational corpus with conformant entity records, so that an entity-grain audit measures a real population rather than an empty one. It is the precondition named in coverage bound 4.

Two target states are not covered by either procedure and have no separate procedure of their own:

- **Target state 4 (frontmatter backfill)** is remediated file-by-file against the required-field set in § 4.3; the tooling shipped, the execution is per project.
- **Target state 5 (folder taxonomy)** is remediated by reshaping the project's folders onto the closed 5-bin set per [ADR-080](../ADRs/ADR-080-project-folder-taxonomy-closed-5-bin-set.md), and carries the orientation-card copy per § 2.3.

Both procedures are **EXPENSIVE / operator-gated**: the operational tree carries no version history, so a pre-change snapshot is the only reversal path. Nothing in this protocol authorizes an unattended migration write.

## 6. References

- **[project-entity-model.md](../disciplines/project-entity-model.md)** — the 19-entity model, the data-vs-file boundary axiom, and the Storage-Location Map that `MM-1` reads.
- **[entity-field-schemas.md](../schemas/entity-field-schemas.md)** — the per-entity validation rules whose intra-record presence level supplies `MM-2`'s required-field set at the entity grain.
- **[frontmatter-schema.md](../schemas/frontmatter-schema.md)** — the file-level metadata contract: the required-field column, and the additive-union `folder` migration window D3 backstops.
- **[health-check-specification.md](../specs/health-check-specification.md)** — the document-ecosystem check inventory: the Frontmatter Completeness definition `MM-2` consumes, the run-count escalation form `N = 2` generalizes, and the status-band triple § 4.5 reuses.
- **[project-schema.md](../schemas/project-schema.md)** — the `PROJECT.md` field contract, and the home of both remediation procedures cited in § 5.
- **[progressive-rollout-convention.md](progressive-rollout-convention.md)** — the rollout-phase ladder that owns the enforcement instrument's authority to block, distinct from this protocol's deadline.
- **[ADR-058](../ADRs/ADR-058-pmo-entity-page-ssot.md)** — shared entity pages as the single source of truth for Person / System / Vendor.
- **[ADR-059](../ADRs/ADR-059-plan-type-open-discriminator.md)** — typed plan sub-entities.
- **[ADR-060](../ADRs/ADR-060-project-md-composed-index.md)** — the composed wiki-link index shape and its ≤50-line criterion.
- **[ADR-080](../ADRs/ADR-080-project-folder-taxonomy-closed-5-bin-set.md)** — the closed 5-bin folder taxonomy and its additive-union migration window.
