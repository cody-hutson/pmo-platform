<!-- reference-durability: allow-link -->
# Methodology Parameterization — v1

**Status:** Canonical
**Owner:** `release/references/specs/methodology-parameterization-v1.md`
**Consumers:** role-skill wave (HARD handoff); `methodology-adapter` consumer (SOFT handoff); release-planner bundle (HARD handoff via `OPERATIONS.md § Methodology Awareness Protocol` + variation matrix)
**Cross-references:**

- [`schemas/project-schema.md`](../../../core/schemas/project-schema.md) — `delivery_approach` enum + `custom_methodology_definition` block + V1-V12 validation rules
- [`methodology-archetype-matrix.md`](methodology-archetype-matrix.md) — per-archetype variation table (lifecycle / ceremonies / artifacts / cadence / consumers / sample-types / distinguishing-constraint)
- [`terminology-glossary.md`](../../../core/specs/terminology-glossary.md) — canonical definitions of Process / Methodology / Framework (owned by terminology-glossary.md)
- [`OPERATIONS.md § Methodology Awareness Protocol`](../../../core/governance/OPERATIONS.md) — skill consumption rule
- [`failure-mode-standard.md`](../../../core/specs/failure-mode-standard.md) — 5-field template + 5-category taxonomy
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
read PROJECT.md → parse delivery_approach field:

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

#### CASE 1-ARRAY — the Hybrid-Two array form {#case-1-array}

When `delivery_approach` is a 2-element array `[A, B]` (the Hybrid-Two form — see the array worked example and its validation trace in [`schemas/project-schema.md` § 6.5](../../../core/schemas/project-schema.md)), the consumer reads the matrix row for **each** of A and B and produces **dual-framed output** — one native section per constituent (an A-framing and a B-framing), each parameterized from its own row's lifecycle / ceremonies / artifacts / cadence. The ceremonies and artifacts the consumer emits are the **union** of the two constituents' primitives, exactly the per-track mapping [`work-organization-mapping-framework.md` § 2.5](../../../core/disciplines/work-organization-mapping-framework.md) already defines for the Hybrid row (*"each track maps per its constituent archetype, union of both"*). This branch **references** §2.5; it does not re-found it. The consumer logs `[methodology-branch: CASE 1-ARRAY constituents=A,B]`.

**Semantic-merge / dominance.** The union is the default: where two output surfaces are distinct (a milestone roll-up vs. an iteration burn-down) the consumer renders **both**. When a *single* output position needs one cadence (e.g. a single roll-up date), the surfaces do not collide because they are owned by different constituents — the **phased constituent governs milestone / gate framing** and the **timeboxed or continuous constituent governs iteration / flow framing**. Where both constituents could legitimately claim one surface, the consumer renders both **side-by-side** (the union default); it **never silently picks one**. This is the §2.5 union made operational.

The array form is **methodology classification only** — it does not imply co-management. A consumer reading `[A, B]` MUST still read `dual_framing_enabled` (the orthogonal trigger, project-schema § 7) before deciding whether to *additionally* emit the Dual-Framing Bridge co-management output. The two native constituent framings (this branch) and the Dual-Framing Bridge (the `dual_framing_enabled` trigger) are independent: a `[Scrum, Waterfall]` project with `dual_framing_enabled: false` emits two native framings and no co-management bridge.

### 5.1 Step-by-step for skill authors

1. **Read `delivery_approach` first.** Treat it as the primary methodology signal. Skills MAY cache the value for the duration of the invocation but MUST NOT cache across invocations (the field is project-level mutable).
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

Stage 9 operator verifies pickup-readiness per AC-R3.

## 6. Failure Modes (domain-specific)

Per [`failure-mode-standard.md`](../../../core/specs/failure-mode-standard.md) 5-field template + 5-category taxonomy. Five failure modes the methodology parameterization creates. Future skills (e.g., a `methodology-aware` audit) and `pmo-qa-auditor` consumers cite these when reviewing skill outputs.

### 6.1 Methodology conflation — INPUT

- **Signature.** Skill reads `spm_comanaged: true` as synonymous with `delivery_approach: Hybrid`, OR treats `delivery_approach: Hybrid` as implying `spm_comanaged: true`.
- **Conditional.** Do NOT treat `spm_comanaged` and `delivery_approach` as redundant or coupled when both are present, because they are orthogonal fields measuring different properties (co-management dual-framing trigger vs. methodology classification) and every independent combination is valid and meaningful — co-management is NOT implied by, and does not imply, the Hybrid classification.
- **Root cause.** Legacy schema collapsed both into a single binary, and the legacy `§3` anchor named Hybrid "the SPM-co-managed pattern"; pattern-recognition misreads the new field as a rename of, or a synonym for, the classification. Authoring pressure to "clean up the duplicate" inflates conflation.
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

The `dual_framing_enabled: true` binary (legacy key `spm_comanaged`, accepted via the `project-initiator` Mode C shim) **remains operative** and is NOT deprecated by the introduction of `delivery_approach`. The two fields are **orthogonal** — they measure different properties and combine freely; neither implies the other. Reconciliation:

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

**Deprecation timeline.** Consolidation of `dual_framing_enabled` with `delivery_approach: Hybrid` is a future concern and is OUT OF SCOPE currently (the legacy `spm_comanaged` key folds away with it). See [`schemas/project-schema.md § 7 Migration Notes`](../../../core/schemas/project-schema.md) and [`OPERATIONS.md § Methodology Awareness Protocol § Relationship to Dual-Framing Bridge`](../../../core/governance/OPERATIONS.md).

## 8. Versioning

This document is **v1** — the initial cut. Versioning rules:

- **v1.1 (data-level)** — archetype addition via governance-promotion (a Custom variant elevated to a 9th enum member) per §4.4. A minor-release bump ships the elevation; this file's archetype list expands; matrix gets a new row.
- **v2 (schema-level)** — breaking change to the `custom_methodology_definition` block shape (e.g., adding a required sub-field), or reclassification of a canonical archetype (rename, split, merge). Not expected in the current minor-release line; would trigger major-release consideration.

The filename `methodology-parameterization-v1.md` signals the version. v1.1 data-level changes do NOT rename the file. v2 schema-level changes ship under a new filename (`methodology-parameterization-v2.md`) with a compatibility shim period.

**Downstream handoffs assume v1.** The release-planner bundle and role-skills consumer skills ship coded against v1. Any promotion from Custom to enum requires coordinated update across consumers — tracked per the emergence-rule governance path.

---

**End of methodology parameterization v1.** Next: [`methodology-archetype-matrix.md`](methodology-archetype-matrix.md) for the variation table + Custom row worked examples.
