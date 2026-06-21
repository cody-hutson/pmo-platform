<!-- reference-durability: allow-link -->
# PROJECT.md Schema

**Status:** Canonical
**Owner:** `../schemas/project-schema.md`
**Introduced:** methodology-parameterization-core (2026-04-24)
**Consumers:** 13 PROJECT.md-reading skills + `OPERATIONS.md § Methodology Awareness Protocol` + the future role-skill wave
**Cross-references:**

- [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) — 8 archetype normative definitions + Custom Extension Protocol + Skill Consumption Pattern
- [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md) — per-archetype variation table (lifecycle / ceremonies / artifacts / cadence / consumers / sample-types / distinguishing-constraint)
- [`terminology-glossary.md`](../specs/terminology-glossary.md) — canonical definitions of Process / Methodology / Framework and adjacent terms (owned by )
- [`OPERATIONS.md § Methodology Awareness Protocol`](../governance/OPERATIONS.md) — skill consumption rule

---

## 1. Purpose

`PROJECT.md` is the per-project source of truth — the operational-state file that every PMO skill consulting a project reads at invocation. This schema is the canonical specification of its frontmatter shape: what fields exist, what values they take, and how consumer skills interpret them. It replaces tribal knowledge and per-skill ad-hoc parsing with a single authoritative reference.

The schema is **methodology-aware**. Prior to this release, `spm_comanaged: bool` was the only explicit methodology signal, and skills that needed to vary behavior by delivery approach did so via ad-hoc inference. The new `delivery_approach` enum + conditional `custom_methodology_definition` block (introduced by the methodology-parameterization keystone) give skills an authoritative methodology classification to parameterize against — eliminating the implicit "sprint-centric Agile" default that was load-bearing in 12 of 13 project-reading skills.

## 2. Scope

**In scope.** All fields in the `PROJECT.md` frontmatter YAML block. Values, types, presence rules, and the reconciliation rules between legacy and new fields. The additions — `delivery_approach` and `custom_methodology_definition` — with full validation rules (V1-V12) and worked examples.

**Out of scope.** Per-skill consumption rules (those live in each skill's own output-contract and in `methodology-parameterization-v1.md § Skill Consumption Pattern`). The matrix of per-archetype variation columns (lifecycle / ceremonies / artifacts / cadence) lives in `methodology-archetype-matrix.md`. Canonical term definitions for Process / Methodology / Framework live in `terminology-glossary.md`.

## 3. Root Schema

Canonical YAML frontmatter shape. Fields are listed in canonical order — Engineering authoring of new `PROJECT.md` files and the `project-initiator` skill SHOULD follow this order for consistency.

```yaml
---
# Identity
project_name: string                       # REQUIRED — display name
project_owner: string                      # REQUIRED — primary accountable owner
status: ACTIVE | CLOSING | CLOSED          # REQUIRED — lifecycle state (per CLAUDE.md Project Lifecycle)

# Dual-framing co-management trigger (decoupled from delivery_approach — orthogonal)
dual_framing_enabled: bool                 # OPTIONAL — true triggers dual Agile/Waterfall co-management framing (CLAUDE.md § Dual-Framing Bridge). Legacy key `spm_comanaged` is accepted via the project-initiator Mode C deprecation shim — see §7.

# Methodology classification — NEW
delivery_approach: Scrum | Kanban | XP | Waterfall | PRINCE2 | SAFe | Hybrid | Custom
                                           # REQUIRED — top-level methodology archetype

# Conditionally required — present iff delivery_approach: Custom
custom_methodology_definition:
  name: string                             # REQUIRED — display name (e.g., "Scrumban")
  base_archetype: <one-of-8> | null        # REQUIRED — closest archetype, or null for genuinely novel
  derived_from: [<archetype-name>, ...]    # REQUIRED — fusion list (may be empty [])
  lifecycle: continuous | phased | timeboxed
                                           # REQUIRED — core cadence pattern
  ceremonies: [string, ...]                # REQUIRED — non-empty list of named sync events
  artifacts: [string, ...]                 # REQUIRED — non-empty list of work-products
  cadence: string                          # REQUIRED — free-form cadence description
  notes: string                            # OPTIONAL — rationale + known trade-offs

# Other per-project fields (per existing skill conventions — not introduced by )
# ... e.g., stakeholder roster, go-live date, systems, governance model, Dual-Framing Bridge section trigger ...
---
```

Field presence rules summary:

| Field | Required | Conditional |
|---|---|---|
| `project_name` | ✅ Always | — |
| `project_owner` | ✅ Always | — |
| `status` | ✅ Always | — |
| `dual_framing_enabled` | ⚪ Optional | — (legacy key `spm_comanaged` accepted via Mode C shim — §7) |
| `delivery_approach` | ✅ Always | — (new) |
| `custom_methodology_definition` | Conditional | ✅ iff `delivery_approach: Custom`; ❌ otherwise |

## 4. Field Reference

One subsection per field. Values, semantics, and consumer expectations. Evidence labels: `[SOURCE]` indicates the authoring file or grep result; `[INFERRED]` indicates derivation from observed skill behavior.

### `project_name`

Free-form string. Used in status output headers, artifact titles, and cross-project reports. Convention: title-case; match the project folder name under `projects/` when possible. `[SOURCE]` — `operations/skills/project-initiator/SKILL.md` (governs PROJECT.md scaffolding).

### `project_owner`

Primary accountable owner (single person). Free-form string. Used in routing status output and escalation chains. `[SOURCE]` — observed convention across all projects under `projects/`.

### `status`

Enum: `ACTIVE` | `CLOSING` | `CLOSED`. Lifecycle state per `CLAUDE.md § Project Lifecycle`. `ACTIVE` projects receive full processing; `CLOSING` projects receive reduced cadence (hypercare); `CLOSED` projects are read-only reference. Skills MUST check `status` before processing and short-circuit accordingly. `[SOURCE]` — `CLAUDE.md § Project Lifecycle`.

### `dual_framing_enabled`

Boolean. When `true`, activates the **Dual-Framing Bridge** — dual Agile/Waterfall co-management framing across outputs from `ppm-agent`, `delivery-engine`, `daily-status`, `weekly-status-rollup`. `[SOURCE]` — `CLAUDE.md § Dual-Framing Bridge (Conditional)` lines 155-157.

This field is the dual-framing co-management trigger, **orthogonal** to `delivery_approach`: it is **NOT implied by, and does not imply, `delivery_approach: Hybrid`** — see §7 Collision Check for reconciliation rules. The trigger is the operational co-management dual-framing capability; `Hybrid` (and the `[A, B]` array form) is a methodology classification — the two combine freely.

**Legacy key.** The field was previously named `spm_comanaged`. A live `PROJECT.md` carrying the legacy `spm_comanaged` key is still accepted: the `project-initiator` Mode C deprecation shim reads it, emits a one-line deprecation warning, and treats it as `dual_framing_enabled`. Shim-removal is deferred to a future milestone — see §7 Migration Notes.

### `delivery_approach`

Required. Enum — one of 8 values (title-case, case-sensitive):

| Value | Meaning |
|---|---|
| `Scrum` | Iterative timeboxed; sprint commitment protected |
| `Kanban` | Continuous-flow with WIP limits |
| `XP` | Iteration-based + engineering practices as governance |
| `Waterfall` | Sequential phased with gate-based change control |
| `PRINCE2` | Stage-based project governance framework |
| `SAFe` | Multi-team Agile at PI cadence (Essential 5.0+) |
| `Hybrid` | User-configurable two-archetype combination `[A, B]` reported in both native framings (co-management is orthogonal — see `dual_framing_enabled`, § 7) |
| `Custom` | Escape hatch — requires `custom_methodology_definition` block |

Full normative definitions (3-5 sentences per archetype) live in [`methodology-parameterization-v1.md § Definitions`](../../release/references/specs/methodology-parameterization-v1.md). Variation table (lifecycle / ceremonies / artifacts / cadence / consumers / sample-types / distinguishing-constraint) lives in [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md).

Consumer skills read this field at invocation and parameterize their behavior per [`OPERATIONS.md § Methodology Awareness Protocol`](../governance/OPERATIONS.md) Rules 1-3.

### `custom_methodology_definition`

Block. Present iff `delivery_approach: Custom`; absent or null otherwise (per V4). Typed escape-hatch carrying full methodology specification. Consumer skills use this block as the authoritative methodology description when `delivery_approach: Custom` — no implicit archetype inference.

Sub-fields:

#### `custom_methodology_definition.name`

Required. Non-empty free-form string. The display name of the custom variant (e.g., `"Scrumban"`, `"Shape Up"`, `"Scrum-no-estimation"`). Used in status output and artifact titles.

#### `custom_methodology_definition.base_archetype`

Required. Either one of the 8 enum values OR the YAML `null` literal. Names the archetype the custom variant most closely resembles. `null` is an **explicit signal** the variant is genuinely novel — skills MUST NOT silently default to any archetype when `base_archetype` is `null` (see §5 V6; see `methodology-parameterization-v1.md § Skill Consumption Pattern` 3-branch logic).

#### `custom_methodology_definition.derived_from`

Required. List of archetype enum values. May be empty `[]` (typically paired with `base_archetype: null`). Each member must be one of the 8 enum values. Documents the fusion lineage of the variant — e.g., Scrumban might have `derived_from: [Kanban, Scrum]`.

#### `custom_methodology_definition.lifecycle`

Required. Enum: `continuous` | `phased` | `timeboxed`. The core cadence pattern:

- `continuous` — flow-pull; no time boundaries on work cycles (Kanban-family).
- `phased` — gate-sequential; each phase completes before next begins (Waterfall-family).
- `timeboxed` — iteration-bounded; work happens in fixed-length boxes (Scrum/XP-family).

Skills key their primitives off this field — WIP/throughput for `continuous`, phase-gate progress for `phased`, velocity/sprint-goal for `timeboxed`.

#### `custom_methodology_definition.ceremonies`

Required. Non-empty list of strings. Named recurring synchronization events (e.g., `"daily standup"`, `"sprint retro"`, `"end-stage review"`, `"betting table"`). Skills recognize these as sync points for status aggregation and decision cadence.

#### `custom_methodology_definition.artifacts`

Required. Non-empty list of strings. Named work-product or tracking artifacts (e.g., `"product backlog"`, `"kanban board"`, `"stage plan"`, `"pitch"`). Skills expect these as inputs/outputs and use them to orient documentation generation.

#### `custom_methodology_definition.cadence`

Required. Non-empty free-form string describing the cadence (e.g., `"2-week sprints"`, `"continuous flow with weekly replenishment"`, `"6-week cycle + 2-week cooldown"`). Informs scheduling defaults in consumer skills.

#### `custom_methodology_definition.notes`

Optional. Free-form string. Rationale, known trade-offs, governance-promotion candidacy notes. Consumed as methodology-context hint by verbose-mode skill outputs.

## 5. Validation Rules

Twelve rules governing schema conformance. Enforcement level `structural (auto)` means the rule is machine-verifiable from the frontmatter alone — no human judgment required. `[AC-R2]` annotations indicate the rule operationalizes the Stage-5-locked AC-R2.

| ID | Rule | Blocks | Level |
|---|---|---|---|
| **V1** | `delivery_approach` field is present in PROJECT.md frontmatter | schema parse | structural (auto) |
| **V2** | `delivery_approach` is EITHER (a) a single value in `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe, Hybrid, Custom}` (case-sensitive, title-case — the original single-enum form), OR (b) a 2-element YAML sequence `[A, B]` where A ≠ B and both A, B ∈ `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe}` (the Hybrid-Two array form; array members **exclude** `Hybrid` and `Custom` — they are meta-archetypes, not composable constituents). Array sub-assertions: **(V2-a) length == 2 · (V2-b) members distinct · (V2-c) each member ∈ the 6-set.** | schema parse + skill branch | structural (auto) |
| **V3** | When `delivery_approach: Custom`, block `custom_methodology_definition` is present | skill branch | structural (auto) — **AC-R2** |
| **V4** | When `delivery_approach ≠ Custom`, block `custom_methodology_definition` is absent or `null` | skill branch | structural (auto) |
| **V5** | `custom_methodology_definition.name` is a non-empty string | — | structural (auto) — **AC-R2** |
| **V6** | `custom_methodology_definition.base_archetype` is one of the 8 enum values OR the YAML `null` literal | skill-fallback logic | structural (auto) — **AC-R2** |
| **V7** | `custom_methodology_definition.derived_from` is a list (may be `[]`); each member (if any) is one of the 8 enum values | — | structural (auto) — **AC-R2** |
| **V8** | `custom_methodology_definition.lifecycle` is one of `{continuous, phased, timeboxed}` | skill branch | structural (auto) — **AC-R2** |
| **V9** | `custom_methodology_definition.ceremonies` is a non-empty list of strings (min 1 entry) | — | structural (auto) — **AC-R2** |
| **V10** | `custom_methodology_definition.artifacts` is a non-empty list of strings (min 1 entry) | — | structural (auto) — **AC-R2** |
| **V11** | `custom_methodology_definition.cadence` is a non-empty string | — | structural (auto) — **AC-R2** |
| **V12** | `custom_methodology_definition.notes` is either absent OR a string (may be empty `""`) | — | structural (auto) |

**V-table coordination note.** The `delivery_approach` array form (the Hybrid-Two `[A, B]` case) is validated by the **amended V2 (v2.16)** — it does NOT introduce a new V-rule, so the V-series tail remains **V12**. The next V-numbers, **V13 and V14, are reserved** for the PROJECT.md-schema keystone (the first-class domain / deliverable-type axis) and the org-structure / delivery-model / team-roster card respectively, which append to the V12 tail when that later schema-expansion milestone is built (see References). No existing rule is renumbered.

### 5.1 Custom Block Completeness (operationalizes AC-R2)

When `delivery_approach: Custom`, the following fields MUST all be present and well-formed per their individual rules:

> `{name, base_archetype, derived_from, lifecycle, ceremonies, artifacts, cadence}`

That is: V3 (block presence) AND V5 (name non-empty) AND V6 (base_archetype enum-or-null) AND V7 (derived_from list) AND V8 (lifecycle enum) AND V9 (ceremonies non-empty) AND V10 (artifacts non-empty) AND V11 (cadence non-empty).

This block-completeness assertion is the single-test AC-R2 gate. Stage 8 QA runs it against the 3 worked examples in [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md) Custom row (all must PASS) and against 2 negative test cases (both must FAIL):

- Negative case 1 — `delivery_approach: Custom` with `cadence` missing → V11 FAIL → Custom Block Completeness FAIL.
- Negative case 2 — `delivery_approach: Custom` with `lifecycle: weekly` (invalid enum) → V8 FAIL → Custom Block Completeness FAIL.

### 5.2 Validation-failure handling

A PROJECT.md that fails any V1-V12 assertion is **malformed**. Consumer skills encountering a malformed PROJECT.md MUST:

1. Refuse to produce methodology-parameterized output.
2. Surface the specific failing rule ID to the operator.
3. Route the file for correction via `project-initiator` (Mode C — schema repair) or manual edit.

Skills MUST NOT silently work around validation failures by defaulting to an archetype. Silent default is a named failure mode — see `methodology-parameterization-v1.md § Failure Modes` (PROC-2: Base-archetype blind fallback; PROC-3: Custom-block skip).

### References

- #351 — PROJECT.md-schema keystone: adds a first-class domain / deliverable-type axis to the schema; reserves the next V-rule (V13) off the V12 tail when its milestone is built.
- #262 — adds org-structure, delivery-model, and team-roster fields to the schema; reserves the V-rule after the keystone (V14).

## 6. Examples

Four worked examples covering the representative cases. Each is a valid PROJECT.md frontmatter block that passes all V1-V12 assertions applicable to its `delivery_approach` value.

### 6.1 Scrum (minimal — enum-matched, no Custom block)

```yaml
---
project_name: Payments Platform Refactor
project_owner: J. Doe
status: ACTIVE
delivery_approach: Scrum
---
```

**Validation trace:** V1 ✓ (field present), V2 ✓ (`Scrum` in enum), V3 N/A (not Custom), V4 ✓ (no block present as expected), V5-V12 N/A.

### 6.2 Hybrid with `dual_framing_enabled: true` (enum-matched + co-management framing)

```yaml
---
project_name: [PROJECT_KEY] Implementation
project_owner: C. [OPERATOR_NAME]
status: ACTIVE
dual_framing_enabled: true
delivery_approach: Hybrid
---
```

**Validation trace:** V1 ✓, V2 ✓ (`Hybrid`), V3 N/A, V4 ✓, V5-V12 N/A.

**Reconciliation note.** The two fields are **orthogonal**, and this example shows them combined: `delivery_approach: Hybrid` is the methodology classification (a two-archetype combination), while `dual_framing_enabled: true` is the *separate, orthogonal* operational co-management dual-framing trigger. Co-management is NOT implied by `Hybrid` — a Hybrid project with `dual_framing_enabled: false` is equally valid (two native framings, no co-management output), and a single-archetype project may set `dual_framing_enabled: true` independently. This combination is the legacy co-managed shape, but it is a *configuration*, not the definition of Hybrid — see §7 Collision Check. (A legacy `PROJECT.md` carrying `spm_comanaged: true` is accepted via the Mode C shim and reads identically — §7.)

### 6.3 Custom — Scrumban (base_archetype: Kanban)

```yaml
---
project_name: Vendor Onboarding Modernization
project_owner: A. Smith
status: ACTIVE
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
---
```

**Validation trace:** V1 ✓, V2 ✓ (`Custom`), V3 ✓ (block present), V5 ✓ (`Scrumban` non-empty), V6 ✓ (`Kanban` in enum), V7 ✓ (both members in enum), V8 ✓ (`continuous` in enum), V9 ✓ (3 entries), V10 ✓ (3 entries), V11 ✓ (non-empty cadence), V12 ✓ (notes is a string). **Custom Block Completeness: PASS.**

**Hybrid-Two vs. Custom (partition note).** This Scrumban is a **fused variant** — Scrum ceremonies are retained but estimation and sprint commitment are *replaced* with WIP-limited pull — so it is correctly modelled as `Custom` (a named methodology that blends two archetypes into a third thing). A project running an **unmodified Scrum track alongside an unmodified Kanban track** instead uses the Hybrid-Two array `delivery_approach: [Scrum, Kanban]`. The two representations are **not redundant** and partition cleanly: **Custom** = a named modification/fusion (overridden ceremonies/practices, `derived_from` records lineage); **array** = two canonical archetypes coexisting as-is, each native, union of primitives. Test: *"two tracks each running an archetype natively (→ array), or one team running a fused/renamed methodology (→ Custom)?"*

### 6.4 Custom — Shape Up (base_archetype: null — genuinely novel)

```yaml
---
project_name: Platform Discovery Sprint
project_owner: R. Patel
status: ACTIVE
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
---
```

**Validation trace:** V1 ✓, V2 ✓, V3 ✓, V5 ✓ (`Shape Up`), V6 ✓ (`null` literal allowed), V7 ✓ (empty list allowed), V8 ✓ (`timeboxed`), V9 ✓ (3 entries), V10 ✓ (4 entries), V11 ✓, V12 ✓. **Custom Block Completeness: PASS.**

**Skill consumption note.** Because `base_archetype: null`, consumer skills MUST use the block's `lifecycle` / `ceremonies` / `artifacts` / `cadence` directly — NO archetype fallback. If a skill cannot parameterize from these fields alone, it MUST emit a methodology-agnostic output with an explicit caveat (not a silent default to Scrum). See `methodology-parameterization-v1.md § Skill Consumption Pattern` 3-branch logic CASE 3.

### 6.5 Hybrid-Two array — `delivery_approach: [Scrum, Kanban]` (two archetypes as-is)

A project running **two canonical archetypes natively, side-by-side** — each track keeping its own lifecycle/ceremonies/artifacts — declares the pair as a 2-element array. No `custom_methodology_definition` block is present (the array members are unmodified archetypes, not a fused variant).

```yaml
---
project_name: Platform Re-architecture Program
project_owner: M. Okafor
status: ACTIVE
delivery_approach: [Scrum, Kanban]
---
```

**Validation trace:** V1 ✓ (field present), V2 ✓ — **array branch**: 2 elements (V2-a length == 2 ✓), `Scrum ≠ Kanban` (V2-b distinct ✓), both members ∈ the 6-set `{Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe}` (V2-c ✓; neither is `Hybrid`/`Custom`). V3 N/A (not `Custom`), V4 ✓ (no `custom_methodology_definition` block), V5-V12 N/A.

**Array vs. Custom (which form to use).** This is the **array** family, NOT a second Custom example. Use the array `[A, B]` when two named archetypes run **as-is** (union of both, each native) — contrast §6.3, where Scrumban is a *fused* variant (Scrum ceremonies retained but estimation replaced with WIP-pull) and is therefore `Custom`. The two representations partition cleanly and are not redundant: **array** = two archetypes coexisting unmodified; **Custom** = a named modification/fusion. (The array-consumption logic — how a consumer renders dual-framed output from `[A, B]` — is specified in `methodology-parameterization-v1.md § Skill Consumption Pattern`.)

## 7. Migration Notes — Field Rename + Legacy `spm_comanaged` Shim

The dual-framing co-management trigger is named **`dual_framing_enabled`**. It was previously named `spm_comanaged`; that legacy key is **accepted on read** via a deprecation shim (below) so live `PROJECT.md` files do not silently orphan.

### Collision Check — Are `dual_framing_enabled` and `delivery_approach` redundant?

**No.** They are orthogonal fields measuring different properties, and neither implies the other:

| Field | Role | Consumer |
|---|---|---|
| `dual_framing_enabled: bool` | Triggers Dual-Framing Bridge output (Agile + Waterfall) — operational co-management dual-framing binary, independent of methodology. (Legacy alias: `spm_comanaged` — accepted via the Mode C shim.) | `CLAUDE.md § Dual-Framing Bridge`; `delivery-engine` Mode D bridge step |
| `delivery_approach: Hybrid` | Classifies project methodology as a user-configurable two-archetype combination `[A, B]` reported in both native framings — a classification only, saying nothing about co-management | All methodology-aware role-skills |

### Reconciliation Rule

The two fields are **orthogonal and combine freely** — co-management is no longer implied by, and does not imply, the Hybrid classification:

- `delivery_approach: Hybrid` + `dual_framing_enabled: true` — a two-archetype project that *additionally* runs the co-management dual-framing output (the legacy co-managed shape, now expressed as an explicit combination rather than a coupled default).
- `delivery_approach: Hybrid` + `dual_framing_enabled: false` (or absent) — a two-archetype project reported in both native framings, with no co-management output. **Valid.**
- `dual_framing_enabled: true` + `delivery_approach: Scrum` (or any non-Hybrid) — a single-archetype project that runs the co-management dual-framing output independently of methodology. **Valid** under the decoupled model — this is NOT a misconfiguration to "correct" toward Hybrid. (`project-initiator` Mode C no longer flags this combination as a configuration-validation candidate.)
- `dual_framing_enabled: false` (or absent) + non-Hybrid — single-methodology project, no dual-framing.

### Deprecation Shim — legacy `spm_comanaged`

The field is **renamed to `dual_framing_enabled` in this release**. The legacy `spm_comanaged` key is **accepted via a `project-initiator` Mode C deprecation shim**: when a `PROJECT.md` carries `spm_comanaged`, Mode C reads it, emits a one-line deprecation warning, and treats it as `dual_framing_enabled` (same boolean semantics). The shim is additive read-logic — an extension of an existing Mode C branch, not a new mechanism. **Shim-removal is deferred to a future milestone** (once live operator `PROJECT.md` files have migrated to the new key); removing it later is a one-line deletion. (The Mode C shim *implementation* lands in a downstream consumer slice; this section documents the contract.)

This is a rename + back-compat shim, **not** the deferred `spm_comanaged`↔`Hybrid` consolidation. That consolidation — collapsing the orthogonal trigger into the methodology classification — remains explicitly OUT OF SCOPE; doing it would collapse the orthogonality this decouple protects. A future milestone may still revisit whether to:

- (a) derive co-management framing from `delivery_approach: Hybrid` and drop the standalone trigger,
- (b) keep `dual_framing_enabled` as the authoritative trigger and `delivery_approach: Hybrid` as the methodological tag (current model),
- (c) introduce a reconciliation validator that enforces alignment between the two fields.

See [`OPERATIONS.md § Methodology Awareness Protocol § Relationship to Dual-Framing Bridge`](../governance/OPERATIONS.md) for the operational posture.

### Current PROJECT.md format note

Existing `projects/<project>/PROJECT.md` files under `projects/` use an ad-hoc markdown `**Key:** value` format rather than YAML frontmatter. `[SOURCE]` — inspection of `projects/[PROJECT_KEY] Implementation/PROJECT.md` and sibling files 2026-04-24.

The schema describes the **canonical forward-looking shape** — YAML frontmatter. Migration of existing PROJECT.md files to YAML frontmatter is a future concern and is **not required** by this release. Consumer skills read `delivery_approach` via the same parsing approach they use today (markdown key-value or YAML — whichever is present). The schema is authoritative for:

- new PROJECT.md scaffolding (via `project-initiator` Mode A once it is refit in a future release),
- any PROJECT.md migrated to YAML frontmatter format,
- the semantic definition of fields regardless of serialization format.

## 8. Consumers

Skills and governance files that read `PROJECT.md` fields at invocation. Methodology-sensitivity column indicates whether the skill's behavior should vary by `delivery_approach` (per the blast radius analysis §6.1).

| Consumer | Reads | Methodology-sensitivity | status |
|---|---|---|---|
| `delivery-engine` | `dual_framing_enabled` + sprint tracker + velocity history + (future) `delivery_approach` | CRITICAL | Reads unchanged; future refit parameterizes on `delivery_approach` |
| `project-initiator` | `dual_framing_enabled` + governance-specific tracker routing + (future) `delivery_approach`; Mode C hosts the legacy-`spm_comanaged` shim | HIGH | Reads unchanged; future refit adds 8-way archetype branch |
| `ppm-agent` | `status` + project metadata + RAG derivation | MEDIUM | Unchanged |
| `daily-status` | `status` + framework + sprint stand-up format | HIGH | Unchanged; future refit varies format by archetype |
| `weekly-status-rollup` | project metadata + status cadence | MEDIUM | Unchanged |
| `comms-writer` | project-level voice + sprint cadence | MEDIUM | Unchanged |
| `change-management` | governance context | MEDIUM | Unchanged |
| `tracker-manager` | tracker routing | LOW | Unchanged |
| `file-router` | classification | LOW | Unchanged |
| `pmo-qa-auditor` | skill-under-audit context | LOW | Unchanged (methodology-agnostic by design) |
| `pmo-process-designer` | project context | LOW | Unchanged |
| `implementation-planner` | release context | MEDIUM | Unchanged |
| `artifact-generator` | project context | LOW | Unchanged |

**Governance consumers:**

- [`OPERATIONS.md § Methodology Awareness Protocol`](../governance/OPERATIONS.md) — Rules 1-3 mandate that skills read `delivery_approach` + consult the matrix + handle Custom via typed extension.
- [`CLAUDE.md § Dual-Framing Bridge (Conditional)`](<OPERATOR_INSTANCE_CLAUDE_MD>) — reads the dual-framing trigger `dual_framing_enabled` (legacy `spm_comanaged` accepted via the Mode C shim); not yet refit to read `delivery_approach: Hybrid` (future consolidation scope).

**Downstream (future) consumers:**

- **release-planner-bundle** (HARD handoff) — `release-planner` skill reads `delivery_approach` + consults matrix at Stage 3 Bundle time.
- **Role-skills wave** (HARD handoff) — PO/BA/Principal/Software Engineer role-skills read `delivery_approach` + `custom_methodology_definition` + matrix row at invocation; parameterize role-appropriate outputs.
- **Skill-authoring adapter** (SOFT handoff) — `pmo-skill-refiner` `methodology-adapter` reference consumes the enum + matrix at skill-authoring time.

**Evidence:**

| # | Claim | Source |
|---|---|---|
| 1 | 13 skills consume PROJECT.md | `[SOURCE]` `grep -l 'PROJECT\.md' release/skills/**/SKILL.md` 2026-04-24 (blast radius §6.1) |
| 2 | `delivery-engine` Mode D + Mode E presuppose sprints | `[SOURCE]` `operations/skills/delivery-engine/SKILL.md:170-215` |
| 3 | `project-initiator` binary Agile/Hybrid vs. Waterfall branch | `[SOURCE]` `operations/skills/project-initiator/SKILL.md:190-193` |
| 4 | `CLAUDE.md § Dual-Framing Bridge` uses legacy `spm_comanaged` binary | `[SOURCE]` `CLAUDE.md:155-157` |
| 5 | Existing PROJECT.md files use markdown key-value format | `[SOURCE]` inspection of `projects/[PROJECT_KEY] Implementation/PROJECT.md` 2026-04-24 |
| 6 | AC-R2 block-completeness operationalization | `[SOURCE]` Stage 5 spec §1 + AC-R2 locked text |

---

**End of PROJECT.md schema.** Next: [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) for normative archetype definitions.
