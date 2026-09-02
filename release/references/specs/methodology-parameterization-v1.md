<!-- reference-durability: allow-link -->
# Methodology Parameterization — v1

**Status:** Canonical
**Owner:** `release/references/specs/methodology-parameterization-v1.md`
**Consumers:** role-skill wave (HARD handoff); `methodology-adapter` consumer (SOFT handoff); release-planner bundle (HARD handoff via `OPERATIONS.md § Methodology Awareness Protocol` + variation matrix)
**Cross-references:**

- [`schemas/project-schema.md`](../../../core/schemas/project-schema.md) — `delivery_approach` enum + `custom_methodology_definition` block + per-space `operational_methodology` / `release_methodology` fields + V1-V12 / V16-V17 validation rules
- [`methodology-archetype-matrix.md`](methodology-archetype-matrix.md) — per-archetype variation table (lifecycle / ceremonies / artifacts / cadence / consumers / sample-types / distinguishing-constraint)
- [`terminology-glossary.md`](../../../core/specs/terminology-glossary.md) — canonical definitions of Process / Methodology / Framework (owned by terminology-glossary.md)
- [`OPERATIONS.md § Methodology Awareness Protocol`](../../../core/governance/OPERATIONS.md) — skill consumption rule
- [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) — 5-field template + 5-category taxonomy
- [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) — § 4.2 emergence rule (governance-promotion of recurring Custom variants)

---

## 1. Purpose

This document is the **normative vocabulary source** for methodology-aware skill authoring on the PMO platform. It names the 8 archetypes the platform recognizes, defines each in 3-5 sentences with a distinguishing constraint, and documents the Custom Extension Protocol and Skill Consumption Pattern that together operationalize the `delivery_approach` enum.

**Relationship to `terminology-glossary.md`.** Canonical definitions of the three abstraction-level terms — **Process**, **Methodology**, **Framework** — live in [`terminology-glossary.md`](../../../core/specs/terminology-glossary.md), owned by terminology-glossary.md (sibling). This document USES those terms per the glossary; it does NOT redefine them. When glossary and this document disagree on vocabulary, glossary is authoritative. The file name `methodology-parameterization-v1.md` was retained after Collective Review (2026-04-24) — per Collective Review the glossary accommodates this filename at the Framework layer (framework scope = methodology-domain) without conflict.

## 2. Scope

**In scope.**

- Normative 3-5 sentence definitions of the 8 archetypes: Scrum / Kanban / XP / Waterfall / PRINCE2 / SAFe / Hybrid / Custom.
- Distinguishing constraint for each archetype — the one-line test that distinguishes it from its siblings.
- Semantic anchors for SAFe and Hybrid (disambiguation resolves the R8 semantic drift risk per the Stage-5 risk register).
- Custom Extension Protocol — when to use `Custom`, how to populate `custom_methodology_definition`, governance-promotion rule.
- Skill Consumption Pattern — the authoritative 3-branch logic methodology-aware role skills use to parameterize on `delivery_approach` + `custom_methodology_definition`.
- Space-Scoped Resolution (Step 0) — the per-space `operational_methodology` / `release_methodology` resolution that precedes the 3-branch logic, and the per-space consumer audit.
- Portfolio-Framework Axis Consumption Pattern (§5B) — the `portfolio_framework` altitude, its 3-branch consumer logic, and its orthogonality to the project-tier `delivery_approach` axis.
- Failure modes the parameterization creates (per `failure-mode-standard.md`).
- Relationship to the orthogonal dual-framing co-management capability (the `dual_framing_enabled` trigger and its bridge artifact), which is independent of the `delivery_approach` methodology classification.

**Out of scope.**

- Per-skill consumption rules (those live in each skill's output-contract).
- Variation table — lifecycle / ceremonies / artifacts / cadence per archetype (that is the `methodology-archetype-matrix.md` doc, which this file complements in prose).
- Canonical term definitions for Process / Methodology / Framework — see `terminology-glossary.md`.

## 3. Definitions

One H3 per archetype. 3-5 sentences each. Each section ends with a **Distinguishing constraint** line (the one-line test that distinguishes this archetype from its siblings) + a cross-reference to the corresponding row in [`methodology-archetype-matrix.md`](methodology-archetype-matrix.md). SAFe includes an explicit **Semantic anchor** line, and Hybrid an explicit **Decoupled from co-management** line, that resolve R8 semantic drift risk.

### Scrum

Iterative, timeboxed development using fixed-length sprints (typically 2 weeks). Work breakdown is user stories with story-point estimation; the team commits to a sprint scope during planning and protects that scope for the sprint duration. Ceremonies: daily standup, sprint planning, sprint review, sprint retrospective. Artifacts: product backlog, sprint backlog, increment.

**Distinguishing constraint.** Sprint commitment is protected — scope is not pushed in mid-sprint; scope changes require either a sprint abort or waiting for the next sprint.

**Matrix row:** [`methodology-archetype-matrix.md` § Scrum](methodology-archetype-matrix.md).

### Kanban

Continuous-flow delivery governed by work-in-progress (WIP) limits. Work breakdown is flow items pulled through board columns as capacity opens; no sprint commitments, no timeboxes, no velocity. Ceremonies: cadence-based replenishment events and service-delivery reviews (no sprint-family ceremonies). Artifacts: kanban board with WIP limits, cycle-time metrics, throughput metrics.

**Distinguishing constraint.** WIP-limited pull system — capacity (flow efficiency), not velocity (scope-per-timebox), is the primary health metric.

**Matrix row:** [`methodology-archetype-matrix.md` § Kanban](methodology-archetype-matrix.md).

### XP

Iteration-based development (typically 1-2 week iterations) coupled with engineering practices elevated to governance-level requirements: pair programming, test-driven development, continuous integration, collective code ownership, simple design. Work breakdown is user stories with story-point estimation. Ceremonies: iteration planning, daily standup, iteration retrospective PLUS technical ceremonies — pair-rotation, CI-health review. Artifacts: user stories, acceptance tests as specs, CI health metrics.

**Distinguishing constraint.** Engineering practices (pair programming, TDD, CI) are governance-level requirements — not recommendations — and are verified at delivery gates.

**Matrix row:** [`methodology-archetype-matrix.md` § XP](methodology-archetype-matrix.md).

### Waterfall

Sequential phased lifecycle: requirements → design → build → test → deploy. Each phase completes fully and passes a phase-gate review before the next begins; re-entry to prior phases requires formal change control. Work breakdown is WBS tasks per phase; estimation is time-based (days/weeks) with phase-gate milestones. Ceremonies: phase-gate reviews, change control board reviews (no iterative ceremonies). Artifacts: SOW, requirements spec, design doc, test plan, deployment plan.

**Distinguishing constraint.** Linear phase progression with formal gate-based change control — in-phase iteration is allowed, but cross-phase backflow requires change-control authorization.

**Matrix row:** [`methodology-archetype-matrix.md` § Waterfall](methodology-archetype-matrix.md).

### PRINCE2

Stage-based project governance framework (PRojects IN Controlled Environments, 2nd edition). Work is segmented into management stages; each ends with an end-stage report and a stage-boundary decision by the Project Board — continue / cease / re-plan. Work breakdown: stage plans contain work packages which produce products (deliverables). Ceremonies: end-stage assessments, exception-plan reviews, highlight-report cadence. Artifacts: Project Initiation Documentation (PID), business case, stage plans, highlight reports, exception reports.

**Distinguishing constraint.** PRINCE2 is a project governance framework, not a development methodology — it explicitly tailors to project scale/risk and routinely coexists with Scrum or Waterfall execution inside its stage boundaries. A PRINCE2 project's stage may be internally Scrum-run; the PRINCE2 classification describes the governance wrapper, not the delivery engine.

**Matrix row:** [`methodology-archetype-matrix.md` § PRINCE2](methodology-archetype-matrix.md).

### SAFe

Multi-team Agile at enterprise scale, organized in Agile Release Trains (ARTs) that plan on a Program Increment (PI) cadence (typically 8-12 weeks, comprising 4-6 team sprints). Work breakdown: Portfolio Epics → Program Features → Team Stories; estimation combines story points at team level and feature sizing at program level. Ceremonies: PI Planning (2-day event), System Demo, Inspect & Adapt, scrum-of-scrums. Artifacts: ART backlog, PI objectives, program board, solution intent.

**Semantic anchor (resolves R8).** "SAFe" means the **SAFe Essential 5.0+ configuration** — PI cadence + ART + PI Planning — not full-stack SAFe Portfolio or LPM. Projects using the ART layer without portfolio integration classify as SAFe; projects using only team sprints without an ART coordination layer do NOT classify as SAFe (they classify as Scrum).

**Distinguishing constraint.** The PI is the coordination primitive above the sprint; a single-team timeboxed project without PI cadence is Scrum, not SAFe.

**Matrix row:** [`methodology-archetype-matrix.md` § SAFe](methodology-archetype-matrix.md).

### Hybrid

A project that runs a **user-configurable combination of two of the 8 archetypes** under a single project governance, declared `delivery_approach: [A, B]` (two distinct archetypes; e.g. `[Scrum, Kanban]`, `[Waterfall, XP]`). Each constituent track runs in its native methodology; the project reports status in **both** constituent framings simultaneously. Ceremonies and artifacts are the **union** of the two constituents. The per-track hierarchy mapping is defined in [`work-organization-mapping-framework.md` § 2.5](../../../core/disciplines/work-organization-mapping-framework.md).

**Decoupled from co-management (resolves R8).** Hybrid is a **methodology classification only**. The dual-framing *output* — Agile + Waterfall framings rendered for a co-managing sponsor — is an **orthogonal operational capability** gated by the separate `dual_framing_enabled` flag (project-schema § 7), NOT implied by `delivery_approach: Hybrid`. A Hybrid project may run with `dual_framing_enabled: false` (two native framings, no co-management bridge) or `true` (additionally emits the Dual-Framing Bridge). A non-Hybrid single-archetype project may set `dual_framing_enabled: true` independently. The literal value `Hybrid` is retained as a single-enum value for backward-compatibility; the array form is the forward-looking explicit declaration.

**Distinguishing constraint.** Two distinct archetypes named in one project; native-framing status output in TWO lifecycles, not one. Single-track "mostly-Scrum-with-light-gate-review" is Scrum, not Hybrid. A *named variant that fuses* two archetypes into a third methodology is `Custom`, not Hybrid — see the Hybrid-Two-vs-Custom partition rule in [`schemas/project-schema.md` § 6.3](../../../core/schemas/project-schema.md).

**Matrix row:** [`methodology-archetype-matrix.md` § Hybrid](methodology-archetype-matrix.md).

### Custom

First-class escape hatch for projects whose methodology does not match any of the 7 archetypes above, or is a genuinely novel variant. Requires a populated `custom_methodology_definition` block in PROJECT.md specifying name, `base_archetype` (or `null` for genuinely novel), `derived_from` list, lifecycle, ceremonies, artifacts, cadence, and optional notes. Skills consuming PROJECT.md use the block as the authoritative methodology description — no implicit archetype inference. Governance-promotion to a 9th enum value is possible in a future minor release per the emergence rule (see §4.5 below).

**Distinguishing constraint.** The `custom_methodology_definition` block IS the methodology definition; there is no implicit fallback to a default archetype unless `base_archetype` is explicitly set (and even then, only as a hint for skill behavior, not a silent override).

**Matrix row:** [`methodology-archetype-matrix.md` § Custom](methodology-archetype-matrix.md).

## 4. Custom Extension Protocol

The Custom archetype is first-class — skills MUST handle it explicitly. This section documents the authoring + governance protocol for Custom.

### 4.1 When to use `Custom`

Use `delivery_approach: Custom` when:

1. The project's methodology does **not match** any of the 7 canonical archetypes' distinguishing constraints.
2. The project is a **fusion** of two or more archetypes with enough deviation from the primary that treating it as the primary would misrepresent it (e.g., Scrum without story-point estimation, Scrumban).
3. The project uses a **genuinely novel methodology** not reducible to archetype fusion (e.g., Shape Up, operator-invented patterns).

Do NOT use Custom for:

- Minor variation of a canonical archetype (e.g., 3-week Scrum sprints instead of 2-week — still Scrum).
- "Customization" of ceremony names without changing semantics (e.g., calling sprint review a "show & tell" — still Scrum).
- Uncertain authoring — if the author cannot confidently populate `base_archetype` + 4 constraint fields (lifecycle / ceremonies / artifacts / cadence), that is a signal the project's methodology is not yet well-defined; resolve methodology classification with the project owner before scaffolding.

### 4.2 How to populate `custom_methodology_definition`

When `delivery_approach: Custom`, populate ALL required block fields per [`schemas/project-schema.md` § 4 Field Reference](../../../core/schemas/project-schema.md):

- `name` — display name (free-form string, e.g., `"Scrumban"`).
- `base_archetype` — one of the 8 archetype enum values OR the YAML `null` literal. `null` is an **explicit signal** the variant is genuinely novel.
- `derived_from` — list of archetype enum values (may be empty `[]`, typically paired with `base_archetype: null`).
- `lifecycle` — one of `{continuous, phased, timeboxed}`.
- `ceremonies` — non-empty list of named sync events.
- `artifacts` — non-empty list of named work-products.
- `cadence` — free-form cadence description.
- `notes` — optional rationale / trade-offs.

Three worked examples (Scrumban, Shape Up, Scrum-no-estimation) are maintained in [`methodology-archetype-matrix.md § Custom Row`](methodology-archetype-matrix.md). Each worked example passes all V1-V12 validation rules per AC-R1 + AC-R3.

### 4.3 Populated-block rigor

The `custom_methodology_definition` block must be **load-bearing**, not a stub. Populated rigorously means:

- `ceremonies` enumerates the recurring sync events the project actually runs — not a copy of Scrum's ceremonies list.
- `artifacts` enumerates the work-products the project actually produces — not a token entry like `"board"`.
- `cadence` is concrete enough that a consumer skill can schedule output around it.
- `notes` captures the rationale (why this variant exists) and known trade-offs (what it sacrifices vs. its closest archetype).

Skill authors downstream depend on the block for methodology-parameterized output. A stubbed block forces consumer skills into the `base_archetype: null` fallback path even when `base_archetype` is populated — defeating the block's purpose.

### 4.4 Governance-promotion rule (N=2 within 180 days)

A Custom variant whose `name` recurs **identical across ≥2 projects within a 180-day window** is an **emergence candidate** per [`decision-discipline.md § 4.2`](../../../core/disciplines/decision-discipline.md). When observed:

1. Log the occurrence toward the emergence rule (pattern cache N=1 → N=2 → operator elevation).
2. The operator MAY elevate the variant to a 9th enum value in a future minor release via a governed change per `CLAUDE.md` "No ungoverned changes" protocol.
3. Skills MUST NOT promote archetypes unilaterally — elevation is operator authority only.

When a variant is elevated, the canonical file list updates: the variant becomes a named archetype (e.g., `Scrumban`) with its own matrix row and normative definition in this file; existing projects using `delivery_approach: Custom` with `name: Scrumban` can migrate to `delivery_approach: Scrumban` in a follow-up release.

### 4.5 Failure modes to avoid (when populating or consuming Custom)

See §5 Failure Modes below for the full 5-entry table. The Custom-specific subset:

- **PROC-2 Custom-block skip** — reading `delivery_approach: Custom` without reading the block. Produces wrong output.
- **PROC-3 Base-archetype blind fallback** — silently defaulting to Scrum when `base_archetype: null`. Defeats the escape-hatch's purpose.

## 5. Skill Consumption Pattern

This section documents the **authoritative 3-branch logic** every methodology-aware role skill MUST implement (operationalizes AC-R3).

Pseudocode:

```
read PROJECT.md →

  STEP 0 (space-scoped consumers — see the Step 0 sub-branch below):
    consumer serves the operational space AND operational_methodology present → resolve its value
    consumer serves the release space AND release_methodology present → resolve its value
    otherwise → resolve delivery_approach (unchanged)
    (a per-space value is a single archetype from the 6-set or a 2-element [A, B] array —
     never Hybrid-literal, never Custom — so STEP 0 output enters CASE 1 or CASE 1-ARRAY
     only; CASE 2/3 arise only via the delivery_approach fallback)

  parse the resolved value:

  CASE 1: delivery_approach IN {Scrum, Kanban, XP, Waterfall, PRINCE2, SAFe, Hybrid}:
    → read matrix row for this archetype
    → parameterize behavior from: lifecycle + ceremonies + artifacts + cadence
    → produce methodology-native output

  CASE 1-ARRAY: delivery_approach is a 2-element array [A, B]   (the Hybrid-Two form):
    → read the matrix row for EACH of A and B
    → produce dual-framed output: one native section per constituent (A-framing + B-framing),
      parameterized from each row's lifecycle + ceremonies + artifacts + cadence
    → take the UNION of track-specific primitives per work-organization-mapping-framework § 2.5
      (Hybrid = "each track maps per its constituent archetype, union of both")
    → log [methodology-branch: CASE 1-ARRAY constituents=A,B]
    → dominance on a contested output surface: the phased constituent governs milestone/gate
      framing; the timeboxed/continuous constituent governs iteration/flow framing — render
      BOTH side-by-side (the union default); never silently pick one

  CASE 2: delivery_approach == Custom AND base_archetype != null:
    → read custom_methodology_definition block
    → start from matrix row for base_archetype as DEFAULT
    → OVERRIDE with custom block's lifecycle / ceremonies / artifacts / cadence where they differ
    → produce Custom-tuned output with base-archetype framing

  CASE 3: delivery_approach == Custom AND base_archetype == null:
    → read custom_methodology_definition block
    → use lifecycle / ceremonies / artifacts / cadence directly — NO archetype fallback
    → if skill cannot parameterize from these fields alone:
      → emit methodology-agnostic output WITH an explicit caveat
      → DO NOT silently default to Scrum or any other archetype
```

#### Step 0 — Space-scoped resolution (the per-space methodology split) {#space-scoped-resolution}

When a project declares the optional per-space fields — `operational_methodology` / `release_methodology`, grammar + precedence contract in [`schemas/project-schema.md` §4](../../../core/schemas/project-schema.md) (V16/V17) — a consumer serving a single **space** resolves the space-effective methodology BEFORE taking a branch:

1. A consumer serving the **operational space** (PMO / project-delivery work) resolves `operational_methodology` when present, else `delivery_approach`.
2. A consumer serving the **release space** (release-pipeline / SDLC work) resolves `release_methodology` when present, else `delivery_approach`.
3. A **project-wide** consumer (portfolio rollup, cross-space audit) resolves `delivery_approach` unchanged and MAY surface the per-space split as an annotation.

**Space assignment follows the module boundary by default:** operations-module skills serve the operational space; release-module skills and pipeline gates serve the release space; core-module consumers are project-wide unless they declare a space. A consumer MUST NOT merge the two per-space values into a synthetic array, and MUST NOT read the other space's field in place of its own — both are the space-conflation counterpart of the §6 conflation failure modes.

**The resolved value feeds the UNCHANGED branch set.** A per-space value is a single archetype from the 6 composable archetypes or a 2-element `[A, B]` array — never `Hybrid`-literal, never `Custom` — so Step 0 output enters **CASE 1 or CASE 1-ARRAY only**. CASE 2 / CASE 3 arise only via the `delivery_approach` fallback; a project running a Custom methodology in one space declares `delivery_approach: Custom` + the block and overrides the other space's field. Consumers log the resolution: `[methodology-branch: STEP-0 space=<operational|release|project-wide> source=<field resolved> → CASE …]`.

**Dominance-rule interaction.** For a space-scoped consumer, an explicit per-space assignment REPLACES the CASE 1-ARRAY contested-surface dominance heuristic — the operator has assigned which constituent governs which space. Project-wide consumers reading a `delivery_approach` array keep the §2.5 union + dominance rendering unchanged.

#### Per-space consumer audit {#per-space-consumer-audit}

The durable rule is the module-boundary space assignment above; this table records the disposition of each live §5-consuming surface at the split's introduction:

| Consumer (reads §5) | Space | Per-space read? |
|---|---|---|
| intake-desk methodology-resolution step (elicitation) | operational | **YES** — resolves `operational_methodology` first per the project-schema §4 precedence contract (the intake seam) |
| `OPERATIONS.md § Methodology Awareness Protocol` Rules 1–4 (+ its operations mirror) | space-agnostic mandate | No edit — composes by reference; Rule 3's §5 citation carries Step 0 transitively |
| `project-schema.md` §8 consumer-table skills | operational | No edit now — "future refit" rows; the refit reads §5 (now carrying Step 0) and lands on `operational_methodology` |
| `pmo-release-train-engineer` (CASE 1-ARRAY implementer) | operational | No edit — fallback semantics identical while the fields are absent; Step 0 governs when present |
| Gate criterion G3-18 (`gate-criteria-spec.md`, Bundle→Planning design conditioning) | release | Future refit — its resolution chain gains `release_methodology` ahead of the project's `delivery_approach`; behavior unchanged while the fields are absent |
| Methodology-pack selection (pack lens per resolved archetype) | per space | Composes — the pack lens a space renders follows the Step-0 space-effective value |

#### CASE 1-ARRAY — the Hybrid-Two array form {#case-1-array}

When `delivery_approach` is a 2-element array `[A, B]` (the Hybrid-Two form — see the array worked example and its validation trace in [`schemas/project-schema.md` § 6.5](../../../core/schemas/project-schema.md)), the consumer reads the matrix row for **each** of A and B and produces **dual-framed output** — one native section per constituent (an A-framing and a B-framing), each parameterized from its own row's lifecycle / ceremonies / artifacts / cadence. The ceremonies and artifacts the consumer emits are the **union** of the two constituents' primitives, exactly the per-track mapping [`work-organization-mapping-framework.md` § 2.5](../../../core/disciplines/work-organization-mapping-framework.md) already defines for the Hybrid row (*"each track maps per its constituent archetype, union of both"*). This branch **references** §2.5; it does not re-found it. The consumer logs `[methodology-branch: CASE 1-ARRAY constituents=A,B]`.

**Semantic-merge / dominance.** The union is the default: where two output surfaces are distinct (a milestone roll-up vs. an iteration burn-down) the consumer renders **both**. When a *single* output position needs one cadence (e.g. a single roll-up date), the surfaces do not collide because they are owned by different constituents — the **phased constituent governs milestone / gate framing** and the **timeboxed or continuous constituent governs iteration / flow framing**. Where both constituents could legitimately claim one surface, the consumer renders both **side-by-side** (the union default); it **never silently picks one**. This is the §2.5 union made operational.

The array form is **methodology classification only** — it does not imply co-management. A consumer reading `[A, B]` MUST still read `dual_framing_enabled` (the orthogonal trigger, project-schema § 7) before deciding whether to *additionally* emit the Dual-Framing Bridge co-management output. The two native constituent framings (this branch) and the Dual-Framing Bridge (the `dual_framing_enabled` trigger) are independent: a `[Scrum, Waterfall]` project with `dual_framing_enabled: false` emits two native framings and no co-management bridge.

### 5.1 Step-by-step for skill authors

1. **Read `delivery_approach` first.** Treat it as the primary methodology signal. Skills MAY cache the value for the duration of the invocation but MUST NOT cache across invocations (the field is project-level mutable). When the project declares a per-space field for the space your skill serves, resolve the space-effective value per [Step 0](#space-scoped-resolution) first — the value you branch on is the RESOLVED value; `delivery_approach` remains the fallback and the project-level classification.
2. **Read the block when `Custom`.** Do NOT skip the block read — the enum value `Custom` is not self-describing. Skipping the block produces CASE 2 or CASE 3 treated as Scrum — the PROC-2 failure mode.
3. **Consult the matrix for archetype-matched cases (CASE 1).** `methodology-archetype-matrix.md` is the canonical data contract. Use the row's lifecycle / ceremonies / artifacts / cadence to parameterize.
4. **Inherit from base in CASE 2.** When `base_archetype` is populated in a Custom block, start from that archetype's matrix row as default; override only the fields the custom block specifies differently. This gives Custom-with-base variants coherent archetype framing with targeted deviation.
5. **Use the block directly in CASE 3.** When `base_archetype: null`, there is no archetype to fall back to. Use the block's lifecycle / ceremonies / artifacts / cadence directly. If they are insufficient for the skill's parameterization, emit methodology-agnostic output WITH CAVEAT — do NOT silently default.
6. **Log the branch taken.** Skills SHOULD log the consumption branch taken in debug output (e.g., `[methodology-branch: CASE 2 base=Kanban]`). This aids debugging and operator review of skill behavior on edge-case projects.
7. **Branch CASE 1-ARRAY when `delivery_approach` is a `[A, B]` array.** Read the matrix row for **each** constituent, emit one native section per constituent (union of primitives per [`work-organization-mapping-framework.md` § 2.5](../../../core/disciplines/work-organization-mapping-framework.md)), apply the phased-governs-gates / timeboxed-governs-iterations dominance rule on contested surfaces, render both side-by-side rather than silently picking, and log `[methodology-branch: CASE 1-ARRAY constituents=A,B]`. The array is a methodology classification only — read `dual_framing_enabled` separately to decide whether to additionally emit the Dual-Framing Bridge. See the [CASE 1-ARRAY](#case-1-array) sub-branch above.

### 5.2 Pickup-readiness test (AC-R3 gate)

A methodology-aware role-skill author reading ONLY this document + [`schemas/project-schema.md`](../../../core/schemas/project-schema.md) + [`methodology-archetype-matrix.md`](methodology-archetype-matrix.md) SHOULD be able to implement correct methodology-aware branching WITHOUT clarifying questions. Test vectors:

- Given a project with `delivery_approach: Scrum`, skill produces sprint-native output using the matrix Scrum row.
- Given a project with `delivery_approach: Custom / name: Scrumban / base_archetype: Kanban`, skill produces Custom-tuned output starting from Kanban matrix row + overriding cadence per block.
- Given a project with `delivery_approach: Custom / name: "Shape Up" / base_archetype: null`, skill produces output using the block's lifecycle/ceremonies/artifacts/cadence directly; if skill lacks Shape-Up-specific templates, skill emits methodology-agnostic output with caveat `"Custom methodology 'Shape Up' has no archetype fallback; output is methodology-agnostic"`.
- Given a project with `delivery_approach: [Scrum, Kanban]` (the Hybrid-Two array — validates via the project-schema § 6.5 array branch: 2 distinct members, both in the 6-set), skill takes **CASE 1-ARRAY**: it reads the Scrum and Kanban matrix rows, emits a Scrum-native section (sprint cadence, sprint ceremonies) **and** a Kanban-native section (continuous flow, WIP-limited pull) as the union of both, applies the dominance rule on any contested surface (here neither constituent is phased, so milestone/gate framing is absent and both contribute iteration/flow framing rendered side-by-side), logs `[methodology-branch: CASE 1-ARRAY constituents=Scrum,Kanban]`, and reads `dual_framing_enabled` separately before deciding whether to additionally emit the Dual-Framing Bridge.
- Given a project with `delivery_approach: [Kanban, Waterfall]` + `operational_methodology: Kanban` + `release_methodology: Waterfall` (the per-space split — validates per project-schema V16/V17), an operational-space consumer resolves `Kanban` at Step 0 and produces flow-native output (CASE 1); a release-space consumer resolves `Waterfall` and produces phase-gate output (CASE 1); a project-wide consumer reads the array unchanged (CASE 1-ARRAY union). Logs `[methodology-branch: STEP-0 space=operational source=operational_methodology → CASE 1 Kanban]` (and the release-space analog). With only `release_methodology: Waterfall` declared on a `delivery_approach: Scrum` project, the operational space falls back to `Scrum`.

Stage 9 operator verifies pickup-readiness per AC-R3.

## 5A. Domain-Axis Consumption Pattern

This section is the **domain-axis sibling of §5** (the methodology consumption pattern). Where §5 branches consumer behavior on `delivery_approach` (*how the work is governed*), §5A branches it on `deliverable_type` (*what kind of work is delivered*, `project-schema.md` §4). The two axes are orthogonal and compose: a consumer reads **both** fields independently.

**The branch.**

```
read PROJECT.md → parse deliverable_type field:

  CASE D-1: deliverable_type is a recognized class with a shipped guide
            (a guide exists at core/standards/domain-best-practices/<deliverable_type>.md):
    → resolve that guide; confirm its Applicability Profile APPLIES-WHEN matches the deliverable
      and CONTRAINDICATED-WHEN does not exclude it (per stage-05-solutioning.md §5.7 guide index)
    → parameterize domain-aware output / review against the guide's concepts + contraindications

  CASE D-2: deliverable_type is a recognized-or-well-formed class with NO shipped guide yet
            (open-escape value, or a recognized class whose guide is not yet authored):
    → the absence IS the guide-authoring demand signal (the SHIP-WITH-FLAG expansion path)
    → emit domain-agnostic output WITH an explicit caveat naming the unguided deliverable_type
    → DO NOT silently default to the software/governance guide or any other domain

  CASE D-3: deliverable_type absent (legacy methodology-only PROJECT.md):
    → no domain branch; proceed methodology-only (the field is optional on legacy files per V13)
    → where a Stage-4 `domain:` class was independently classified from the File-Change-Matrix,
      that abstract signal still governs the design-aware mechanisms (the field is an ADDITIONAL
      authoritative source, not the only one — stage-04-planning.md §5.7)
```

**No silent default (the §5 CASE-3 analog).** CASE D-2 is the exact structural analog of §5 CASE 3 (`base_archetype: null`): when the platform cannot parameterize the deliverable's domain from a shipped guide, it emits a **methodology/domain-agnostic output with an explicit caveat** — never a silent fallback to a default domain. Silent domain-default is the domain-axis counterpart of the PROC base-archetype-blind-fallback failure mode (§6.3).

**Reconciliation with the Stage-4 `domain:` label.** Where PROJECT.md carries `deliverable_type`, it is the **authoritative source** the Stage-4 Planning `domain:` class field reads (`release/references/pipeline/stage-04-planning.md` §5.7). The consumer chain — the A3.1 impact-analysis selector, the domain-best-practice review criterion, and the §5.7 guide index — is **unchanged**: `deliverable_type` feeds the abstract `domain:` class without reworking any consumer, exactly the forward-reference contract that field declared. This branch **references** the §5.7 guide index; it does not re-found guide resolution.

**Composition with §5.** A consumer reads `delivery_approach` (§5) AND `deliverable_type` (§5A) independently and combines them: e.g., a `delivery_approach: Scrum` + `deliverable_type: web` project gets Scrum-native methodology framing (§5 CASE 1) AND web-domain-aware design/review parameterization (§5A CASE D-1). Neither axis implies the other; both are read when present.

## 5B. Portfolio-Framework Axis Consumption Pattern

This section is the **portfolio-framework-axis sibling of §5** (the methodology consumption pattern) and of §5A (the domain axis). Where §5 branches consumer behavior on `delivery_approach` (*how a project's work is governed*), §5B branches it on `[methodology].portfolio_framework` (*which portfolio-tier governance framework the deployment's portfolio and program tiers run under*). The two axes are orthogonal and compose: a consumer reads **both** fields independently, and neither implies the other. A portfolio framework governs the portfolio a project runs **under**, so "Scrum projects inside a PMI-governed portfolio" is an ordinary configuration rather than a contradiction.

**The branch.**

```
read the resolved portfolio_framework value (see Resolution below):

  CASE P-1: portfolio_framework names a framework with a shipped shape directory
            (operations/templates/portfolio-frameworks/<framework_id>/ exists):
    → resolve that directory; use its artifact shapes for portfolio-tier and
      program-tier output
    → anything the directory does not carry falls through to the registry root
      (the thin-delta rule: framework-invariant content stays at the root)

  CASE P-2: portfolio_framework is set to a well-formed value with NO shipped
            shape directory (the OPEN value domain's escape case):
    → the absence IS the shape-authoring demand signal
    → emit portfolio-framework-agnostic output WITH an explicit caveat naming
      the unshipped framework_id
    → DO NOT silently fall back to another framework's shapes

  CASE P-3: portfolio_framework absent or empty (the default, and today's state
            for every deployment):
    → no portfolio-framework branch; resolve exactly as today
    → the project-tier delivery_approach axis (§5) is unaffected in every case
```

**No silent default (the §5 CASE-3 analog).** CASE P-2 is the exact structural analog of §5 CASE 3 (`base_archetype: null`) and of §5A CASE D-2: when the platform cannot parameterize the portfolio tier from a shipped shape directory, it emits **portfolio-framework-agnostic output with an explicit caveat** naming the unshipped `framework_id` — never a silent fallback to another framework's shapes. A silent framework-default is the portfolio-framework-axis counterpart of the base-archetype-blind-fallback failure mode (§6.3), and it is worse at this altitude: a portfolio charter rendered in the wrong framework's shape reads as authoritative governance rather than as a missing capability.

**Resolution.** `portfolio_framework` is an `operator.toml` field. Its rungs, precedence and default-fallback are those of every other platform-config field and are defined once in [`OPERATIONS.md § Platform-Config Resolution Protocol`](../../../core/governance/OPERATIONS.md), with the field's schema row and its rung narrowing recorded at [`platform-config-schema.md` §3.1 / §4](../../../core/schemas/platform-config-schema.md). This section **references** that resolver; it does not restate it. The field is **deployment-global at v1** — it resolves on the global and individual rungs only, and the narrowing plus its reason live at the schema row, not here.

**Composition with §5 and §5A.** A consumer reads `delivery_approach` (§5), `deliverable_type` (§5A) and `portfolio_framework` (§5B) independently and combines them. A project declaring `delivery_approach: Scrum` inside a deployment declaring `portfolio_framework: pmi` gets Scrum-native project framing (§5 CASE 1) **and** PMI portfolio- and program-tier artifact shapes (§5B CASE P-1) — the project's sprints are unaffected by the portfolio framework, and the portfolio's charter is unaffected by the delivery approach. Neither axis implies the other; each is read when present. Where the three axes are all present they parameterize three different questions — how the work is governed, what kind of work it is, and which framework governs the portfolio above it.

**Value domain.** `portfolio_framework` is **OPEN**, not a closed enum: a well-formed value is a lowercase-kebab `framework_id` per [`artifact-naming-standard.md`](../../../core/standards/artifact-naming-standard.md). Shipped at v1: `pmi`. An unrecognized-but-well-formed value takes CASE P-2 rather than failing — the same open-escape posture `delivery_approach: Custom` (§5 CASE 3) and `deliverable_type` (§5A CASE D-2) already take, so the axis's expansion path is authoring a shape directory rather than amending an enum. Per-framework definitions live in the [`methodology-archetype-matrix.md` §3A Portfolio-Framework Matrix](methodology-archetype-matrix.md); this section does not enumerate them.

## 6. Failure Modes (domain-specific)

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) 5-field template + 5-category taxonomy. Five failure modes the methodology parameterization creates. Future skills (e.g., a `methodology-aware` audit) and `pmo-qa-auditor` consumers cite these when reviewing skill outputs.

### 6.1 Methodology conflation — INPUT

- **Signature.** Skill reads `dual_framing_enabled: true` as synonymous with `delivery_approach: Hybrid`, OR treats `delivery_approach: Hybrid` as implying `dual_framing_enabled: true`.
- **Conditional.** Do NOT treat `dual_framing_enabled` and `delivery_approach` as redundant or coupled when both are present, because they are orthogonal fields measuring different properties (co-management dual-framing trigger vs. methodology classification) and every independent combination is valid and meaningful — co-management is NOT implied by, and does not imply, the Hybrid classification.
- **Root cause.** Legacy schema collapsed both into a single binary, and the legacy `§3` anchor named Hybrid "the co-managed pattern"; pattern-recognition misreads the new field as a rename of, or a synonym for, the classification. Authoring pressure to "clean up the duplicate" inflates conflation.
- **Mitigation.** Always read both fields when either is present, and treat them independently. Reconcile per `schemas/project-schema.md § 7 Collision Check`.
- **Principal vs. junior.** Principal reads both fields and treats them as orthogonal — a single-archetype project that sets the co-management dual-framing trigger is a *valid* configuration, not an error to "correct" toward Hybrid. Junior silently rewrites one field to match the other (re-introducing the conflation the decouple removed).

### 6.2 Custom-block skip — PROC

- **Signature.** Skill output for a project with `delivery_approach: Custom` looks identical to a Scrum or Kanban project — the Custom block was not read.
- **Conditional.** Do NOT produce methodology-parameterized output when `delivery_approach: Custom` without reading the `custom_methodology_definition` block, because the enum value `Custom` is not self-describing and silent fallback to a default archetype produces wrong outputs.
- **Root cause.** Switch-statement authoring defaults; the `Custom` case is stubbed to "same as Scrum" under time pressure.
- **Mitigation.** Implement the 3-branch pattern (§5) explicitly. Log the branch taken in skill debug output.
- **Principal vs. junior.** Principal treats Custom as a first-class branch with explicit handling; logs `base_archetype` value consulted. Junior treats Custom as "TODO — use Scrum for now."

### 6.3 Base-archetype blind fallback — PROC

- **Signature.** Skill silently defaults to Scrum when `delivery_approach: Custom` and `base_archetype: null`.
- **Conditional.** Do NOT default to Scrum (or any archetype) when `custom_methodology_definition.base_archetype` is `null`, because `null` is an explicit signal that the project is genuinely novel and any archetype framing would misrepresent it.
- **Root cause.** Null-handling convenience; "null means no base; use the platform default" is the naive null-handler.
- **Mitigation.** When `base_archetype: null`, parameterize directly from the block's lifecycle/ceremonies/artifacts/cadence. If skill cannot do so, emit methodology-agnostic output with a caveat — never silent Scrum fallback.
- **Principal vs. junior.** Principal respects `null` as intentional, surfaces the parameterization limit as a caveat in output. Junior silently swaps `null` for `Scrum` and moves on.

### 6.4 Hardcoded sprint presumption — PROC

- **Signature.** Skill invokes DoR/DoD gates, velocity calculations, or sprint-framed cadence for a project with `lifecycle: continuous` or `lifecycle: phased`.
- **Conditional.** Do NOT apply sprint ceremonies (DoR, DoD, velocity, sprint goal) when `lifecycle: continuous` or `lifecycle: phased`, because sprint ceremonies are lifecycle-timeboxed primitives and applying them to flow or phased lifecycles generates non-diagnostic output.
- **Root cause.** Sprint vocabulary is the default PMO vernacular; authoring defaults to the familiar language.
- **Mitigation.** Read `lifecycle` field first. For `continuous`: use WIP/throughput primitives. For `phased`: use phase-gate primitives. For `timeboxed`: sprint primitives are appropriate.
- **Principal vs. junior.** Principal keys primitives off `lifecycle` enum. Junior hardcodes sprint primitives and renames them for output (`"velocity"` → `"flow rate"` without changing the calculation).

### 6.5 Enum-drift — HAND

- **Signature.** A skill invents a 9th archetype (e.g., accepts `delivery_approach: LeSS`) or extends matrix rows beyond the 8+Custom canonical set.
- **Conditional.** Do NOT extend the `delivery_approach` enum unilaterally in a skill when the 8-archetype enum does not match a real project's methodology, because unilateral extension cascades to consumer skills and breaks the governance-promotion protocol.
- **Root cause.** Real-world project introduces a methodology not in the enum; authoring pressure to "just accept it" routes around governance.
- **Mitigation.** Route novel methodologies through `delivery_approach: Custom` with a populated block. If the variant recurs, elevate per §4.4 governance-promotion rule — operator authority required.
- **Principal vs. junior.** Principal flags novel variants as Custom-block candidates; logs occurrence toward emergence rule. Junior silently extends the enum to accommodate the first novel case.

## 7. Relationship to Dual-Framing Bridge (Conditional)

The `dual_framing_enabled: true` binary **remains operative** and is NOT deprecated by the introduction of `delivery_approach`. The two fields are **orthogonal** — they measure different properties and combine freely; neither implies the other. Reconciliation:

- `delivery_approach` is the **methodology classification** — a single archetype, or (for Hybrid) a user-configurable two-archetype combination `[A, B]` reported in both native framings. It says nothing about co-management.
- `dual_framing_enabled: true` is the **operational dual-framing trigger** — an orthogonal capability that activates the Dual-Framing Bridge co-management output in downstream skills (`ppm-agent`, `delivery-engine`, `daily-status`, `weekly-status-rollup`). It is gated by the flag, not by `delivery_approach: Hybrid`.

Because they are orthogonal, every combination is meaningful:

| `delivery_approach` | `dual_framing_enabled` | Interpretation |
|---|---|---|
| `Hybrid` (or a two-archetype array) | `true` | A two-archetype project that *additionally* runs the co-management dual-framing output |
| `Hybrid` (or a two-archetype array) | `false` (or absent) | A two-archetype project reported in both native framings, with no co-management bridge |
| Non-Hybrid (e.g., `Scrum`) | `true` | A single-archetype project that runs the co-management dual-framing output independently of methodology |
| Non-Hybrid | `false` (or absent) | Single-methodology project — no dual-framing |

The "Hybrid + `dual_framing_enabled: true`" row is the **legacy co-managed shape**, but it is a *configuration*, not the definition of Hybrid: co-management is no longer implied by the classification. Skills reading `delivery_approach: Hybrid` for methodology parameterization MUST ALSO read `dual_framing_enabled` before producing output — the two fields independently determine the methodology framing and whether co-management dual-framing is active.

**Deprecation timeline.** Consolidation of `dual_framing_enabled` with `delivery_approach: Hybrid` is a future concern and is OUT OF SCOPE currently. See [`schemas/project-schema.md § 7 Migration Notes`](../../../core/schemas/project-schema.md) and [`OPERATIONS.md § Methodology Awareness Protocol § Relationship to Dual-Framing Bridge`](../../../core/governance/OPERATIONS.md).

## 8. Versioning

This document is **v1** — the initial cut. Versioning rules:

- **v1.1 (data-level)** — archetype addition via governance-promotion (a Custom variant elevated to a 9th enum member) per §4.4. A minor-release bump ships the elevation; this file's archetype list expands; matrix gets a new row.
- **v2 (schema-level)** — breaking change to the `custom_methodology_definition` block shape (e.g., adding a required sub-field), or reclassification of a canonical archetype (rename, split, merge). Not expected in the current minor-release line; would trigger major-release consideration.

The filename `methodology-parameterization-v1.md` signals the version. v1.1 data-level changes do NOT rename the file. v2 schema-level changes ship under a new filename (`methodology-parameterization-v2.md`) with a compatibility shim period.

**Downstream handoffs assume v1.** The release-planner bundle and role-skills consumer skills ship coded against v1. Any promotion from Custom to enum requires coordinated update across consumers — tracked per the emergence-rule governance path.

---

**End of methodology parameterization v1.** Next: [`methodology-archetype-matrix.md`](methodology-archetype-matrix.md) for the variation table + Custom row worked examples.
