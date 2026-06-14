# Operational-Artifact Template Standard — PMO Platform

**Last Refreshed:** 2026-05-16 (project-data-foundation — )

**Authority:** The PDA-side contract overlay binding operational-artifact templates to the entity-field schema and entity-model spec. Composes by reference with the 5-Layer Template Architecture — adds entity-derivation + machine-schema-companion + FINDING-3-exception; redefines none of L1/L3/L4.

**Reversibility:** MODERATE — Confidence HIGH.

---

## AC Build Checklist (this document)

| AC | Requirement | Satisfied by | Verification |
|---|---|---|---|
| **AC-1** | Standard file exists | this file at `pmo-platform/reference/standards/operational-artifact-template-standard.md` | `test -f` |
| **AC-2** | Required template anatomy — ≥4 named required structural elements | §3 Elements A–F (6 ≥ 4 floor) | `grep -cE '^### Element [A-F] '` → 6 |
| **AC-3** | Entity-derivation rule referencing the entity-field schema | §4 rule T1–T8; **T2 explicitly cites `entity-field-schemas.md`** | `grep -n 'entity-field-schemas.md' §4` resolves |
| **AC-4** | Machine-schema companion convention (what a template must declare to be machine-validatable) | §5 four-EAD-input declaration contract | §5 declares `source_entity`/`entity_crosswalk`/`serialization_dialect`/`schema_mode` |
| **AC-5** | ≥1 worked example applying the standard to a real N1-inventory artifact | §7 RAID Log (positive, `entity-derived`) + §7.1 Communications Tracker (exception, `out-of-standard-until-reconciled`) | §7 table + §7.1 contrast present |
| **AC-6** | `templates/README.md` points to the standard | additive pointer line in `pmo-platform/reference/templates/README.md` using cross-directory relative path `../standards/operational-artifact-template-standard.md` | `grep operational-artifact-template-standard pmo-platform/reference/templates/README.md` resolves |

---

## §1 Purpose

This standard defines what makes an operational-artifact template **"highly machine-readable and manageable"** per the reframed capability (project-data-foundation initiative). An *operational artifact* is a tracker, structural file, generated artifact, or typed plan enumerated in the N1 inventory (`pmo-platform/reference/specs/operational-artifact-inventory.md`).

**First-pass discipline (consolidate, do not invent).** This standard is satisfied by **reference, not re-authoring**. It consolidates four existing convention sources by **citation** and adds **exactly three net-new contract clauses**:

**Four consolidation sources (cited, never duplicated):**

1. L4 `template-protocol.md` §4.1 — the 14-field provenance header schema (the template *file* carries it verbatim).
2. `frontmatter-schema.md`  — instance-frontmatter Category 1–7 + 7 MVP relationship types + Domain A/B/C.
3. L1 `template-taxonomy.md` §2 — the three-domain model (operational artifacts are the `project`-domain subset).
4. `project-schema.md` §5–§6 — the V-style validation-rule structural pattern this standard mirrors.

**Three net-new contract clauses (this standard DEFINES):**

- §4 — the **Entity-Derivation Rule** (every template field maps to an entity-field schema entry OR is marked `template-local` with rationale).
- §5 — the **Machine-Schema-Companion convention** (a template declares the four EAD inputs so its validatable schema is mechanically derivable).
- §6 — the **FINDING-3 known-exception path** (the conformance tri-state for artifacts with no entity home in the frozen 18-roster).

Citing the future/authoritative home rather than restating it is the consolidation discipline `duplicate-source-discipline.md` mandates — a standard that re-stated L4 provenance / L1 taxonomy / L3 PDA-boundary would create a second drift-prone source for already-frozen template-architecture governance.

---

## §2 Scope & Relationship to the 5-Layer Template Architecture

The 5-Layer Template Architecture (SHIPPED — `template-taxonomy.md` / `template-storage.md` / `template-protocol.md`) **already governs** template lifecycle, 14-field provenance, taxonomy, storage, and the PDA boundary. This standard is **not a 6th layer and not a competitor** — it is the **PDA-side contract overlay** that adds the exact three clauses the 5-Layer Architecture deliberately scoped OUT.

### D1 — Architectural placement: contract overlay, NOT a competing layer

| Concern | Authoritative home (SHIPPED) | This standard's relationship |
|---|---|---|
| Template lifecycle (DRAFT→…→ARCHIVED) | L4 `template-protocol.md` §3 | **REFERENCES** — operational-artifact templates obey the L4 lifecycle unchanged |
| 14-field provenance header | L4 `template-protocol.md` §4.1 | **REFERENCES** — the template *file* carries the L4 header verbatim; this standard adds NO field to it |
| Artifact-family taxonomy + 3-domain model | L1 `template-taxonomy.md` §2–§6 | **REFERENCES** — operational artifacts are the `project` domain subset |
| Registry layout, deploy-sync, **PDA boundary** | L3 `template-storage.md` §2–§5 | **REFERENCES** — esp. §5: *"Templates declare structure; PDA instances populate structure"* |
| Instance frontmatter (Category 1–7, 7 MVP rels, Domain A/B/C) | `frontmatter-schema.md` | **REFERENCES** — the instance contract a template points at; the frontmatter-schema owns it |
| Instance provenance for `08-Generated/` | Forthcoming generated-artifact provenance spec (OPEN/approved; downstream consumer of L4 §8) | **FORWARD-REFERENCES** — instance-level, not template-contract-level |
| File naming syntax | Forthcoming `artifact-naming-standard.md` (OPEN/approved; **file ABSENT**) | **FORWARD-REFERENCES** — authority-when-shipped; candidate pattern is interim working basis |
| V-style validation-rule pattern | `project-schema.md` §5–§6 | **MIRRORS** the structural pattern (numbered rules + completeness + traces) |
| **Entity-derivation rule** (field → entity-field schema) | — *(net-new)* | **DEFINES** |
| **Machine-schema-companion convention** (EAD-derivable declaration) | — *(net-new; aligns to the `EAD` derivation)* | **DEFINES** |
| **FINDING-3 known-exception path** | — *(net-new; the PDA D4(c) decision defers to N2)* | **DEFINES** |

`template-storage.md` §5 is the load-bearing evidence: it explicitly declares Template-Architecture and Project-Data-Architecture as **sibling initiatives at different layers**, and states the boundary as *"Template Architecture does not govern WHAT fields a risk has; PDA does."* (`template-storage.md` §5 "Concrete example" + Surface boundary rule 3, frontmatter ownership). This standard is precisely **PDA defining HOW an operational-artifact template encodes that field ownership** — the PDA-side complement to the L3 §5 boundary, not a re-statement of L4/L1/L3. This placement is **forced** by `template-storage.md` §5, not elective; first-pass "consolidate not invent" is satisfied by *citation* of the four consolidation sources + exactly three net-new clauses. This is the **frontmatter-ownership boundary reconciliation**: the standard governs the **template contract**, not file storage / instance physicalization.

### Compose-not-modify rule (FROZEN)

This standard composes by **citation**, exactly as sibling specs compose with L4 §8 without redefining it. Authoring/maintaining this standard authors **exactly one** net-new file (`operational-artifact-template-standard.md`) **plus one** additive one-line pointer in `templates/README.md` (AC-6). It MUST NOT edit `template-protocol.md`, `template-taxonomy.md`, or `template-storage.md` (shipped governance — editing them is an ungoverned change outside this standard's scope).

---

## §3 Required Template Anatomy

Every conformant operational-artifact template carries these six structural elements. Elements A–C/F are **consolidated by reference**; D–E are **net-new contract clauses**. Six named required elements ≥ the AC-2 ≥4 floor.

| # | Element | Required | Source / Definition | Consolidated or Net-New |
|---|---|---|---|---|
| **A** | Provenance header | YES | The L4 14-field YAML block per `template-protocol.md` §4.1 (markdown) or sibling `.provenance.yml` per §4.4 (CSV). Verbatim; no field added/removed. | Consolidated (L4) |
| **B** | Instance-frontmatter contract | YES | A declaration of which `frontmatter-schema.md` Category 1–7 fields the *instances* produced from this template MUST carry (the template specifies the contract; the frontmatter-schema owns the schema). | Consolidated (frontmatter-schema) |
| **C** | Body typed-format spec | YES | The existing typed-format content: column headers (CSV) or section structure + placeholder semantics (MD). Unchanged from current template practice. | Consolidated (existing practice) |
| **D** | Entity-Derivation Table | YES | NEW. One row per template field: `field · entity_binding (#N Entity.field \| template-local) · ead_class (7-class) · level (L1/L2/L3) · rationale-if-local`. Per §4 rule. | **Net-new** |
| **E** | Machine-Schema Companion declaration | YES | NEW. A four-line block declaring the EAD inputs (`source_entity`, `entity_crosswalk`, `serialization_dialect`, `schema_mode`) so `S=EAD(E,C,D,mode)` is derivable. Per §5. | **Net-new** |
| **F** | Naming-convention conformance line | YES | A one-line assertion that instances follow the `artifact-naming-standard.md` pattern. Until that standard ships: candidate `[ProjectCode]_[Type]_[Date]_[Desc].ext` as `[ASSUMPTION – CONFIRM]` interim. | Consolidated (forward-ref to `artifact-naming-standard.md`) |

The per-element subsections below restate each element so the AC-2 conformance grep (`grep -cE '^### Element [A-F] '`) returns 6.

### Element A — Provenance header (consolidated, L4)

The template file carries the L4 14-field provenance block **verbatim** per `template-protocol.md` §4.1 (markdown frontmatter) or the sibling `.provenance.yml` per §4.4 (CSV companion). This standard adds **no** field to the L4 schema — provenance is L4's, not PDA's (compose-not-modify, §2).

### Element B — Instance-frontmatter contract (consolidated, frontmatter-schema)

The template declares **which** `frontmatter-schema.md` Category 1–7 fields the instances it produces MUST carry (the contract). The frontmatter-schema owns the schema definition; the template points at it. This is the §2 frontmatter-ownership boundary (PDA owns the schema; the template carries the placeholder/contract reference).

### Element C — Body typed-format spec (consolidated, existing practice)

The existing typed-format content — CSV column headers or markdown section structure + placeholder semantics. Unchanged from current canonical-template practice; this element names the existing surface, it does not redefine it.

### Element D — Entity-Derivation Table (net-new)

One row per template body field: `field · entity_binding (#N Entity.field | template-local) · ead_class (one of the  7-class taxonomy) · level (L1/L2/L3) · rationale-if-local`. Governed by the §4 Entity-Derivation Rule (T1–T8). This is the per-field crosswalk `C` that EAD consumes (Element E).

### Element E — Machine-Schema Companion declaration (net-new)

A four-line block declaring the EAD inputs — `source_entity` (E) · `entity_crosswalk` (C) · `serialization_dialect` (D) · `schema_mode` (mode) — so the validatable schema `S = EAD(E, C, D, mode)` is mechanically derivable without re-interpretation. Governed by the §5 convention.

### Element F — Naming-convention conformance line (consolidated, forward-ref to `artifact-naming-standard.md`)

A one-line assertion that instances follow the `artifact-naming-standard.md` pattern. Until that standard ships and `artifact-naming-standard.md` exists, the interim working basis is the candidate pattern `[ProjectCode]_[Type]_[Date]_[Desc].ext` carried as `[ASSUMPTION – CONFIRM]`. The authority-when-shipped is `artifact-naming-standard.md`; this standard forward-references it, it does not define naming syntax.

---

## §4 The Entity-Derivation Rule

The rule is stated as numbered **T-rules** (T = Template-conformance; parallel to `project-schema.md` §5's V-rules), each `{ID · Rule · Blocks · Level}`.

| ID | Rule | Blocks | Level |
|---|---|---|---|
| **T1** | Every field in the template body has exactly one row in the Entity-Derivation Table (Element D) | schema parse | structural (auto) |
| **T2** | Each Entity-Derivation row is **either** bound (`entity_binding = #N <Entity>.<field>` resolving to an `entity-field-schemas.md` field) **or** marked `template-local` | schema parse | structural (auto) |
| **T3** | Every `template-local` row carries a non-empty `rationale` string (why no entity field is the source of truth) | schema parse | structural (auto) |
| **T4** | Each bound row declares an `ead_class` ∈ the EAD 7-class taxonomy `{exact-map · rename-map · type-lift · dialect-projection · computed · transition-metadata · context-implicit}` | schema parse | structural (auto) |
| **T5** | Each bound row declares an enforcement `level` ∈ `{L1 · L2 · L3}` (structural / referential / judgment) | schema parse | structural (auto) |
| **T6** | A field that is neither bound nor `template-local`-with-rationale is a **standard violation** (the template is non-conformant) | conformance gate | structural (auto) |
| **T7** | The template declares a `source_entity` (Element E) resolving to a PDA 18-roster entity **OR** the `⚠ NO-ENTITY-HOME (FINDING-3)` sentinel from the PDA inventory col 3 | conformance gate | structural (auto) |
| **T8** | `template-local` MUST NOT be used to bypass a field that DOES have an entity home (escape hatch is for genuine dialect/computed/no-home fields only) | conformance (judgment) | judgment (recommend) |

**Entity-derivation reference is to (`entity-field-schemas.md`)** — explicitly cited in T2 above. A bound row's `entity_binding` resolves to a field defined in `pmo-platform/reference/schemas/entity-field-schemas.md` (the PDA frozen surface). This satisfies AC-3's "referencing the entity-field schema" requirement.

### §4.1 Conformance Completeness assertion (operationalizes AC-3; mirrors `project-schema.md` §5.1)

A template is **entity-derivation-conformant** iff:

> T1 ∧ T2 ∧ T3 ∧ T4 ∧ T5 ∧ T6 ∧ T7 all PASS.

T8 is the judgment guard (agent-recommend → operator-confirm) preventing escape-hatch abuse; it does not block the structural completeness assertion but is surfaced for operator confirmation.

### §4.2 Conformance tri-state (the §6 hand-off)

The assertion result is recorded as `standard_conformance ∈ {entity-derived · template-local-annotated · out-of-standard-until-reconciled}`. See §6 for the tri-state contract.

### §4.3 Validation-failure handling (mirrors `project-schema.md` §5.2)

A template failing any T1–T7 is **non-conformant**. The template-validation harness encountering a non-conformant NEW template MUST:

1. Refuse the create.
2. Surface the failing T-rule ID.
3. Route for correction.

It MUST NOT silently templatize. Silent-pass is the named failure mode this standard exists to prevent (parallel to `project-schema.md` §5.2: "Skills MUST NOT silently work around validation failures").

---

## §5 Machine-Schema Companion Convention

This section **is AC-4**: it specifies what a template must declare to be machine-validatable. A template is **machine-validatable** iff it declares the four EAD inputs so `S = EAD(E, C, D, mode)` (per the EAD D1 derivation) is mechanically derivable **without re-interpretation**:

| Declaration (Element E) | EAD param | Allowed values | Authority |
|---|---|---|---|
| `source_entity:` | **E** | `#N <EntityName>` (1..17 per PDA entity-roster) · `⚠ NO-ENTITY-HOME (FINDING-3)` | PDA Frozen Artifact 1 / inventory col 3 |
| `entity_crosswalk:` | **C** | the Entity-Derivation Table (Element D) — the per-field 7-class classification | EAD D1 `C` param / 7-class taxonomy |
| `serialization_dialect:` | **D** | `csv` · `md-table` · `md-sections` · `json` (+ structural framing note) | EAD D1 `D` param |
| `schema_mode:` | **mode** | `dialect-enforce` (legacy/as-serialized) · `canonical-enforce` (new/entity-canonical) | DD-686-2 / D4 selection contract |

**Dialect-agnostic at the WHAT level.** This standard specifies *that* a conformant template declares these four so a schema is derivable; it does **NOT** specify the JSON Schema dialect, the resolver, or the validator wiring. The concrete HOW is owned downstream and **cited, not redefined**:

- JSON-Schema-draft-07 + stdlib validator pattern → DD-686-1 / DD-686-3.
- The EAD 8-step derivation + `x-pmo-*` provenance → EAD D1.
- The physical referential resolver → G3/G4 per the boundary axiom.
- Harness invocation + `mode` selection → harness contract.

The standard's job is the **declaration contract**; the EAD derivation proves it; the harness enforces it.

---

## §6 FINDING-3 Known-Exception Path

**Problem.** PDA froze `source_entity = ⚠ NO-ENTITY-HOME (FINDING-3)` for artifacts whose records no PDA entity persists (canonical macro case: **Communications Tracker** — no "Communication" entity in the frozen 18-roster; Transcript Register `[ASSUMPTION – CONFIRM]`). These **cannot** satisfy the entity-derivation rule (T7 has no entity to resolve to). PDA D4(c) explicitly states the disposition decision *"(N2/N3 or a future PDA reopen) decides disposition"* — **N2 (this standard) is the named owner of that disposition.** A silent failure here (templatizing as if entity-derived, force-fitting a wrong entity, or omitting the artifact) is the precise anti-pattern the capability forbids.

### Resolution — the conformance tri-state (FROZEN)

| `standard_conformance` | Trigger | Meaning | N3 harness contract |
|---|---|---|---|
| `entity-derived` | T1–T7 all PASS; every field bound; `source_entity` resolves to an 18-roster entity | Full conformance; EAD machine-schema derivable | `canonical-enforce` eligible — born compliant |
| `template-local-annotated` | T1–T7 PASS but ≥1 field is `template-local` (genuine dialect/computed/no-home **field**, e.g. `RAID_ID` projection) with rationale; `source_entity` still resolves to an entity | Conformant — every field is *accounted for* (bound OR explicitly local-with-rationale); the artifact HAS an entity home | `canonical-enforce` eligible; `template-local` fields excluded from entity-canonical enforcement |
| `out-of-standard-until-reconciled` | `source_entity = ⚠ NO-ENTITY-HOME (FINDING-3)` — the **artifact-level** macro case; T7 cannot resolve | The artifact has **NO** entity home in the frozen 18-roster; entity-derivation is *structurally impossible*, not merely incomplete | **Declared, tracked known-exception** — EXEMPT from `canonical-enforce` until reconciled; harness MUST NOT block, MUST NOT silent-pass; records `reconciliation_blocker:` pointer to the PDA inventory row + opens/links the reopen path |

### Field-level vs artifact-level distinction (FROZEN — do not conflate)

- `template-local-annotated` = **field-level** exceptions *inside* an entity-homed artifact (artifact has a home; some fields are dialect/computed). Still conformant.
- `out-of-standard-until-reconciled` = **artifact-level** exception (artifact has *no* home at all — the Finding-3 macro case). Explicitly out-of-standard, **with a named reopen path**, not silently degraded.

### Reopen path (FROZEN)

An `out-of-standard-until-reconciled` template carries:

```
reconciliation_blocker:
  inventory_row: <operational-artifact-inventory.md row ref>
  gap: "<entity absent from frozen 18-roster>"
  reopen_owner: "future PDA entity-roster expansion OR operator decision"
```

This makes the exception **enumerable** (`grep "out-of-standard-until-reconciled"` returns the full blocked-class population for triage) and **tracked** (each carries its reconciliation pointer) — the same structural-catch discipline PDA D5 established at the inventory layer, propagated to the template-contract layer.

### N3 consumption contract

N3 consumes the tri-state as its compliance predicate:

- `entity-derived` / `template-local-annotated` → **enforce** (`canonical-enforce` eligible).
- `out-of-standard-until-reconciled` → **declared-exempt** + surface in the harness's known-exception register. **NOT a failure. NOT a silent pass.**

---

## §7 Worked Example — RAID Log

**Artifact:** RAID Log (`raid-log-template.csv` family / `[Project]_RAID_Log.csv` instances) — a `core-tracker` from the N1 inventory; the EAD pilot already proven by the RAID-log pilot.

> **Transcription note (frozen-authority binding).** Per the Stage-5 frozen spec's repeated instruction ("bindings authoritative from `raid-log.schema.json` `x-pmo-entity-field` provenance + frozen RAID Item surface — Stage 6 transcribes from those frozen sources, does NOT re-derive"; "S = EAD(...) → derives `raid-log.schema.json` exactly as the RAID-log pilot already proved"), the Entity-Derivation Table below is transcribed verbatim from the on-branch frozen authority — `pmo-platform/reference/schemas/raid-log.schema.json` `x-pmo-class` / `x-pmo-entity-field` / `x-pmo-derived-from` / `x-pmo-referential` provenance, cross-checked against `entity-field-schemas.md` §3.6 RAID Item Table F crosswalk (frozen Option-A). The Stage-5 draft's `[ASSUMPTION – CONFIRM]` row resolved against that frozen text: the frozen RAID Item surface has **no `probability` field** and the frozen 14-column crosswalk (Table F) maps 1:1 to the schema property set — the canonical RAID Log column set is the 14-column set used below.

**Machine-Schema Companion declaration (Element E):**

```
source_entity:        #6 RAID Item
entity_crosswalk:     <the Entity-Derivation Table below>
serialization_dialect: csv
schema_mode:          dialect-enforce      # pilot validates the live legacy CSV; x-pmo-canonical-enum carries the entity-canonical contract for canonical-enforce
```

**Entity-Derivation Table (Element D) — transcribed from `raid-log.schema.json` + `entity-field-schemas.md` §3.6 Table F:**

| Template column | entity_binding | ead_class | level | rationale / note |
|---|---|---|---|---|
| `RAID_ID` | `#6 RAID Item.id` (Core-7) | dialect-projection | L1 | `[TYPE]-[SKILL]-[COUNTER]` view of core `id` ( `x-pmo-derived-from: id`) |
| `RAID Category` | `#6 RAID Item.raid_type` | exact-map | L1 | enum {Risk,Assumption,Issue,Dependency}; legacy value-exact (V-RAID-01) |
| `Description` | `#6 RAID Item.summary` | rename-map | L1 | = legacy *Description* (V-RAID-02) |
| `Impact` | `#6 RAID Item.impact` | exact-map | L1 | first-class frozen entity field post-Option-A; required non-empty (V-RAID-12) |
| `Owner` | `#6 RAID Item.owner_person_id` → `references: Person.person_id` | type-lift | L2 | free-text name → Person ref; on-unresolved BLOCK-WRITE (V-RAID-08; R-RAID-01) |
| `Priority` | `#6 RAID Item.severity` | rename-map | L1 | value sets identical; entity-optional, V-RAID-06 conditional-required when `lifecycle_state ≠ open` |
| `Status` | `#6 RAID Item.lifecycle_state` (Axis-1) | dialect-projection | L1 | `x-pmo-canonical-enum {open,in-progress,mitigating,resolved,closed}`; `dialect-enforce`=legacy enum, legacy-crosswalk carries entity-canonical contract for `canonical-enforce`; Axis-1 per the lifecycle ADR |
| `Action Plan` | `#6 RAID Item.action_plan` | exact-map | L1 | first-class frozen entity field post-Option-A; legacy conditionally-required (schema `allOf`) |
| `Due Date` | `#6 RAID Item.target_date` | exact-map | L1 | ISO date (V-RAID-05) |
| `Date Opened` | `#6 RAID Item.created_date` (Core-7) | exact-map | L1 | `x-pmo-derived-from: created_date`; not-future (V-RAID-04) |
| `Date Closed` | `#6 RAID Item` (→closed transition) | transition-metadata | L1 | conditional-required when `lifecycle_state=closed` (V-RAID-11; DEFER-G8) |
| `Closure Comments` | `#6 RAID Item` (→closed transition rationale) | transition-metadata | L1 | conditional-required when `lifecycle_state=closed` (V-RAID-11; DEFER-G8) |
| `Tags` | `template-local` | dialect | — | rationale: dialect-only free tag field (`x-pmo-dialect-only: true`); entity provenance is `relationships[]` / free `tags` per frontmatter-schema Cat-4 — **illustrates `template-local-annotated`: the escape hatch with rationale (T3/T8)** |
| `Section` | `template-local` (computed projection) | computed | — | rationale: `ARCHIVE iff Status==Closed else ACTIVE` — a *computed* projection of `lifecycle_state`, not an independent entity field of record (`x-pmo-computed`) — **illustrates the `computed` 7-class member as a rationale-carrying local** |

**Context-implicit callout (not a row column):** `#6 RAID Item.project_id` (`references: Project.id`, L2, on-unresolved BLOCK-WRITE) is serialized **out-of-band** as the `[Project]` filename token in `[Project]_RAID_Log.csv` (`x-pmo-context-implicit`, "F-1 — entity-required field serialized out-of-band, not a row column; file-level harness assertion"). This illustrates the `context-implicit` member of the EAD 7-class taxonomy: an entity-bound field that is genuinely entity-derived but physicalized as a file-level token, asserted by the harness, not a template body column.

**Conformance verdict: `entity-derived`.** 12 entity-bound fields + 2 `template-local`-with-rationale (`Tags` dialect, `Section` computed) + 1 `context-implicit` (`project_id`, file-level). Every field is accounted for; `source_entity = #6 RAID Item` resolves to the frozen 18-roster (per `entity-field-schemas.md` §3.6). T1–T7 PASS; T8 judgment: the two locals are genuine dialect / computed projections, not entity-home bypass.

**Machine-schema companion:** `S = EAD(#6 RAID Item, <this table>, csv, dialect-enforce)` derives `pmo-platform/reference/schemas/raid-log.schema.json` exactly as the RAID-log pilot already proved. This worked example **points at** the frozen schema as the EAD output proof — it does not re-author it.

### §7.1 Contrast — Communications Tracker (`out-of-standard-until-reconciled`)

The *negative* case proving the §6 non-silent-failure path end-to-end. The Communications Tracker (`[Project]_Communications_Tracker.md`, a `core-tracker` in the N1 inventory) tracks a concept — communications — that has **no entity** in the frozen 18-roster.

```
source_entity:        ⚠ NO-ENTITY-HOME (FINDING-3)
entity_crosswalk:     <none possible — no source entity to derive from>
serialization_dialect: md-table
schema_mode:          n/a (entity-derivation structurally impossible)
standard_conformance: out-of-standard-until-reconciled
reconciliation_blocker:
  inventory_row: operational-artifact-inventory.md → [Project]_Communications_Tracker.md row
  gap: "no Communication entity in frozen 18-roster"
  reopen_owner: "future PDA entity-roster expansion OR operator decision"
```

**Ratified policy (Collective Review 2026-05-16, decision item 4 — verbatim):** the Communications Tracker has no entity home in the frozen 17-roster [18-roster since ADR-018, 2026-06-07 — no Communication entity added] — recorded as `source_entity: ⚠ NO-ENTITY-HOME (FINDING-3)`, `reconciliation_flag: ⚠ FINDING-3`, **flag + carry as `out-of-standard-until-reconciled` known-exception**. Entity-roster expansion (adding a Communication entity) is a SEPARATE downstream decision (future PDA reopen / later milestone) — **NOT in scope**. The flagged row *is* the deliverable; it routes the gap to downstream triage.

No Entity-Derivation Table is possible (T7 cannot resolve). The N3 harness treats this as a **declared, tracked, enumerable known-exception** — exempt from `canonical-enforce` until reconciled, **NOT** a compliance failure and **NOT** a silent pass. This is the load-bearing contribution of this standard: a no-entity-home artifact is neither force-fit to a wrong entity nor silently omitted — it is explicitly out-of-standard with a named reopen path.

---

## §8 Conformance Verification

AC-checkable assertions (mirrors `project-schema.md` §5 / `template-protocol.md` §7.3 style):

| AC | Assertion | Command |
|---|---|---|
| **AC-1** | This standard file exists | `test -f pmo-platform/reference/standards/operational-artifact-template-standard.md` |
| **AC-2** | ≥4 named required structural elements (returns 6) | `grep -cE '^### Element [A-F] ' pmo-platform/reference/standards/operational-artifact-template-standard.md` |
| **AC-3** | Entity-derivation rule references the entity-field schema (T2) | `grep -nE 'entity-field-schemas.md' pmo-platform/reference/standards/operational-artifact-template-standard.md` resolves in §4 |
| **AC-4** | §5 declares the four EAD inputs | `grep -nE 'source_entity:.*entity_crosswalk:.*serialization_dialect:.*schema_mode:' pmo-platform/reference/standards/operational-artifact-template-standard.md` — all four present in §5 |
| **AC-5** | §7 RAID Log table present + §7.1 Communications contrast present | `grep -nE '## §7 Worked Example — RAID Log' && grep -nE '### §7.1 Contrast — Communications Tracker'` |
| **AC-6** | `templates/README.md` points to the standard | `grep operational-artifact-template-standard pmo-platform/reference/templates/README.md` resolves (link uses cross-directory relative path `../standards/operational-artifact-template-standard.md`) |

---

## §9 References

| Reference | Role |
|---|---|
| L4 `pmo-platform/reference/standards/template-protocol.md` §3/§4.1/§4.4/§8 | Template lifecycle + 14-field provenance + composition boundary (REFERENCED, not modified) |
| L1 `pmo-platform/reference/standards/template-taxonomy.md` §2 | Three-domain model; operational artifacts = `project`-domain subset (REFERENCED) |
| L3 `pmo-platform/reference/standards/template-storage.md` §5 | PDA boundary — the load-bearing placement evidence (REFERENCED, not modified) |
| `pmo-platform/reference/schemas/frontmatter-schema.md` | Instance-frontmatter Category 1–7 + 7 MVP rels + Domain A/B/C (REFERENCED) |
| `pmo-platform/reference/schemas/project-schema.md` §5–§6 | V-style validation-rule structural pattern (MIRRORED) |
| `core/disciplines/project-entity-model.md` | The 18-entity canonical roster (`source_entity` resolution target) |
| `pmo-platform/reference/schemas/entity-field-schemas.md` | Per-entity field schemas — **the entity-derivation target cited by T2** |
| `pmo-platform/reference/schemas/raid-log.schema.json` | EAD pilot + §7 worked-example frozen authority (`S=EAD` output proof) |
| `pmo-platform/reference/specs/operational-artifact-inventory.md` | N1 inventory — the `reconciliation_blocker` inventory-row target; FINDING-3 register |
| ADR for the two-axis lifecycle (RATIFIED) | Two-axis entity lifecycle (Axis-1 `lifecycle_state` ⊥ Axis-2 `content_lifecycle_pattern`) — the `Status` binding basis |
| Forthcoming `artifact-naming-standard.md` (OPEN; file ABSENT) | Naming-convention authority-when-shipped (FORWARD-REFERENCED, Element F) |
| Forthcoming generated-artifact provenance spec (OPEN/approved) | Instance provenance for `08-Generated/` (FORWARD-REFERENCED, instance-level) |
| `pmo-platform/reference/standards/duplicate-source-discipline.md` | The register-or-remove / cite-don't-duplicate discipline this standard observes |
