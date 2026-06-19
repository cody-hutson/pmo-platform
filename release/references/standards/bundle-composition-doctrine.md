---
title: Bundle Composition Doctrine
type: standard
version: v11.28
purpose: Codifies the agent-readable methodology for deciding WHAT belongs in a given milestone and WHY those items cohere as a shippable unit — the 7-step vertical capability slice method + tight-merge mechanics + naming convention + size-target heuristics + risk-weighted capacity model + sequence rules
parallel_to:
  - reference/explanation/discovery-discipline.md
  - reference/specs/release-class-taxonomy.md
  - reference/standards/triage-design-rereview.md
  - reference/standards/initiative-roadmap-framework.md
consumers:
  - release/skills/release-planner/SKILL.md (Mode A composition selection; Mode B doctrine-derived-field persistence)
  - release/references/pipeline/stage-03-bundle.md (§5 Phase A6 reframe; §5 Phase B3 milestone-description schema)
  - release/governance/release-process.md + mirror (Stage 3 Bundle section cross-reference)
  - release/governance/RELEASE_PROTOCOL.md (Implementation Plan Format section cross-reference)
last-updated: 2026-05-25
---
<!-- reference-durability: allow-link -->

# Bundle Composition Doctrine

**Origin:** Doctrine-promotion ticket — promotes the vertical capability slice methodology from operator memory (applied at the 2026-04-24 reorg) into agent-readable governance so `release-planner` and Stage 3 Bundle spokes can apply it autonomously.
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../../../core/disciplines/knowledge-architecture.md).
**Class:** standard. Governs the WHAT-to-bundle-and-why-it-coheres dimension of Stage 3 Bundle. Cross-cuts Stage 4 Planning (foundation/infra/skill-core sequence) and Stage 13 Close (composition-coherence verification surfaces).
**Primary consumers:** `release-planner` Mode A invocations producing bundle recommendations; Stage 3 Bundle hub spokes evaluating Phase A6 placement; operators authoring new milestone descriptions.
**Secondary consumers:** Stage 5 Solutioning Collective Review (composition-coherence one dimension of cross-issue cohesion); Stage 13 Close (composition-shape recorded as audit metadata for the release-synthesis triple).

## 1. Frame

The doctrine codifies the **bundle-composition frame** the platform applies when deciding what coheres as a single shippable release.

**Current default per platform config: F1 — SAFe Feature-Slicing + Vertical Slice methodology.** This frame anchors all 7 steps below and matches PMO's existing release practice (18+ milestones already use AFTER/BEFORE outcome framing; the 2026-04-24 reorg was an empirical instance of the methodology). The frame is **config-driven** — the live `[bundling].bundle_doctrine_frame` field in `core/config/platform-config.toml.template` (default `"F1"`; schema at `core/schemas/platform-config-schema.md`) selects the frame, resolved per `core/governance/OPERATIONS.md § Platform-Config Resolution Protocol` (5-rung cascade) on milestone-creation and milestone-update without rewriting this doctrine's structure. Replacing the frame swaps the prose anchor of § 1 + reorients § 2 step-wise terminology; § 3-§ 9 structural rules (sizing, sequencing, naming, tight-merge) remain frame-independent.

**Frame-pluggability discipline (per operator clarification 2026-05-24, recorded in the Collective Review issue comment):**

> *"For now we can default to the agile version. Enhancement would need to set this config on creation and update."* — operator-rendered at Collective Review 2026-05-25.

Read this doctrine as "the platform currently defaults to F1 per platform config" — NOT as "F1 is the only valid bundle-composition frame." Agents and operators consulting this doctrine resolve the active frame from the live `[bundling].bundle_doctrine_frame` field (`core/config/platform-config.toml.template`) per the 5-rung resolver; the doctrine prose stays frame-replaceable.

### 1.1 F1 — SAFe Feature-Slicing + Vertical Slice methodology (current default)

**Source lineage** (industry frame — current default per platform config):

- **Scaled Agile Framework (SAFe) 6.0** — Agile Release Train (ART) + Program Increment (PI) planning event ([Scaled Agile Inc., 2023](https://framework.scaledagile.com/agile-release-train)). Defines feature as a service that fulfills a stakeholder need, small enough to ship within a PI.
- **Vertical Slice methodology** — popularized by Jimmy Bogard (2014+); the principle that a release "slice" must cut through all architectural layers (UI / business / data) to deliver end-user observable change. [SOURCE: [Wikipedia — Vertical slice](https://en.wikipedia.org/wiki/Vertical_slice)]
- **INVEST criteria** — Mike Cohn, *User Stories Applied* (Addison-Wesley, 2004) — Independent, Negotiable, Valuable, Estimable, Small, Testable.
- **The New New Product Development Game** — Hirotaka Takeuchi + Ikujiro Nonaka (*Harvard Business Review*, January 1986) — founding scrum / cross-functional team paper.

**Applicability (current default frame — see § 1):** anchors all 7 steps of § 3.

**Adaptation to PMO platform** (Localization Check per [`decision-discipline.md` § 2.1 Mechanism 1](../../../core/disciplines/decision-discipline.md)):

| SAFe / Vertical Slice convention | PMO adaptation |
|---|---|
| ART team size (50-125 people) | DROPPED — PMO single-operator (N=1 team) |
| Strict 8-12-week PI cadence | DROPPED — PMO release cadence varies hotfix-days to foundation-weeks |
| AFTER/BEFORE outcome contract | KEPT — already used in 18+ existing milestones |
| Story-point sizing | ADAPTED — PMO uses XS=1 / S=2 / M=4 / L=8 / XL=16; target slice 15-25 pts |
| External-dep target ≤2 | KEPT — composes with G3-07 cross-milestone dep gate |
| Cross-team dep visualization | ADAPTED — PMO uses Stage 4 critical-path (CPM) per Stage 4 A8 critical-path |

### 1.2 Alternative frames surveyed (not currently selected)

For doctrine readers evaluating whether F1 remains the right default for their context, two alternative frames were surveyed at Stage 5 Solutioning and are recorded here for completeness:

- **F2 — Continuous Delivery deployment-pipeline batching** — *Continuous Delivery* (Jez Humble + David Farley, Addison-Wesley Signature Series, Pearson, 2010; ISBN 978-0-321-60191-9; 2011 Jolt Excellence Award). Anchors steps 5-7 (sizing, sequence, external-dep targets). Strongest fit when release cadence is high-frequency continuous deploy rather than milestone-batch. Foundational CD/CI text.
- **F3 — Lean Startup MVP + Build-Measure-Learn** — *The Lean Startup* (Eric Ries, Crown Business, 2011; ISBN 978-0-307-88789-4). Anchors step 1 only (capability framing). Weakest direct fit (product-development context vs. release-engineering context); surfaced for completeness.

The frame-pluggability discipline allows the platform to switch to F2, F3, a hybrid (e.g., F1 + F2 sub-step 6 citation), or a custom-defined frame via the live `[bundling].bundle_doctrine_frame` config field without rewriting this doctrine.

## 2. Purpose and Scope

**Purpose.** Replace operator-memory-bound application of bundle composition with agent-readable governance. Before this doctrine, `release-planner` Mode A applied mechanical heuristics (dep order + category cluster + severity + file overlap + 60/20/20 allocation) but could not autonomously apply the vertical capability slice methodology because the methodology lived only in operator memory and the 2026-04-24 reorg's coordinator ticket. This doctrine promotes the methodology to K1 codified-knowledge corpus per [`knowledge-architecture.md`](../../../core/disciplines/knowledge-architecture.md), enabling autonomous bundle-shape selection at Stage 3 Bundle and bundle-rationale composition at Stage 4 Planning.

**In scope.**

- The 7-step vertical capability slice method (§ 3).
- Tight-merge mechanics for oversized parents (§ 4).
- Naming convention for milestone titles (§ 5).
- A6 New-Track Placement Rationale reframed as the new-track special case of the doctrine (§ 6).
- Milestone description required-fields schema consolidating sibling-defined fields (§ 7).
- Worked examples per documented composition shape (§ 8).
- Sequence rules within a release bundle (§ 9).
- Cutover semantics (§ 10) — REFLEXIVE-EXEMPT-ALL with substrate anchor.
- Composition with sibling Stage 5 outputs (§ 11) — boundary articulation per the source ticket's AC #5.
- Cross-reference catalog (§ 12).
- Version history (§ 13).

**Out of scope (deliberate non-overlap).**

- Gate enforcement of bundle composition — G2-11 / G3-10 enforces sizing; A6 enforces new-track rationale; Outcome / Class / Adversarial have their own gates per sibling specs. This doctrine is **positive guidance**; sibling specs supply **gate enforcement**.
- Frontmatter authoring tooling — operators and agents author frontmatter manually per the schema in this doctrine; no auto-scaffolder ships.
- Cross-milestone dependency policy — owned by G3-07; this doctrine cites G3-07 at § 3 Step 7 and § 7 Required Fields.

## 3. The 7-Step Method

The method applies per **proposed milestone**. Steps 1-7 in fixed order. Output is a milestone description ready for Stage 3 Phase B3 creation.

### Step 1 — Name the user capability (AFTER/BEFORE contrast)

> *"After this slice ships, what can a user do that they couldn't before?"*

One sentence with AFTER/BEFORE contrast. If unanswerable, the slice is **not a capability** — it is infrastructure that belongs **inside** a capability slice (not a slice on its own).

- **(current default frame — see § 1):** SAFe feature definition contract (service that fulfills a stakeholder need; small enough to ship within a PI) + INVEST criteria (specifically the **V**aluable and **N**egotiable criteria).
- **Composes with:** Release Outcome Statement per [`release-outcome-statement-template.md`](../specs/release-outcome-statement-template.md). Step 1's AFTER/BEFORE output IS the Outcome Statement's REQUIRED AFTER + BEFORE fields. No duplication — one authoring act populates both.
- **Output:** AFTER sentence + BEFORE sentence, persisted in the milestone description's `### Release Outcome Statement` H3 block.

### Step 2 — List the skill-implementation tickets

Enumerate the tickets that realize the capability named at Step 1. Usually 2-6 tickets. Each ticket should reference the capability — direct invocation in body, related skill in `labels`, or theme-matching `cluster:` / `initiative:` label per [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md).

- **(current default frame — see § 1):** SAFe ART's feature decomposition into team-sized stories. PMO single-operator team-size = 1, so "team-sized stories" = "issue-sized work items."
- **Composes with:** [`release-class-taxonomy.md`](../specs/release-class-taxonomy.md) Release Class declaration. Class is **orthogonal** to slice shape (§ 11.3) — class declares ceremony weight, slice declares capability scope.
- **Output:** ticket list (`#N`-format) with one-line per-ticket purpose.

### Step 3 — Walk the dep graph backward

From each skill ticket, walk dependencies backward to find prerequisites:

- Explicit `## Dependencies` field references → pull in.
- Implicit body refs with dep-signaling phrases (blocks, depends on, requires, prerequisite, unblocks) → pull in.
- `layer:foundation` tickets referenced → pull in.
- `layer:infrastructure` tickets referenced → pull in.
- Unmilestoned orphans with matching theme/cluster → evaluate for inclusion.

- **(current default frame — see § 1):** Vertical Slice principle — a release "slice" must cut through all architectural layers (UI/business/data); operationalized in PMO as foundation → infrastructure → skill-core dep walk.
- **Composes with:** [`references/dependency-analysis.md` § Dependency Graph Construction Algorithm](../../skills/release-planner/references/dependency-analysis.md) (Kahn's BFS topological sort over `Map<issue_number, Set[issue_number]>` adjacency list). Cycle detection via residual-subgraph DFS extraction; on cycle, HALT bundle recommendation per `release-planner` Failure Mode "Circular dependency silently bundled — PROC."
- **Output:** dep-walked ticket list with foundation/infra/skill-core layer annotations.

### Step 4 — Check older milestones for prerequisites

Pipeline-definition + protocol + template + reference tickets the slice depends on may live in **already-open** older milestones. Pull them into the proposed slice; retire absorbed tickets' old milestones when emptied.

- **(current default frame — see § 1):** SAFe ART cross-train dependency visualization — PMO equivalent is cross-milestone scan.
- **Composes with:** G3-07 cross-milestone dependency sequence per [`gate-criteria-spec.md § Gate 3`](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness). For every dep edge `#A → #B`, assert `milestone-position(A) ≥ milestone-position(B)`; register exceptions in candidate milestone's `## Dependency Exceptions` block when sequence is intentional.
- **Output:** pulled-in prerequisite list with originating-milestone citations + retirement candidates.

### Step 5 — Size-check at 15-25 pts target

Total story points (XS=1 / S=2 / M=4 / L=8 / XL=16). Target **15-25 pts per slice**.

| Total pts | Disposition |
|---|---|
| > 25 pts | **Split by sub-capability** — apply Step 1-4 to each sub-capability; sub-slices land as separate milestones OR tight-merge per § 4 |
| 15-25 pts | **Target band** — slice is shippable as-is |
| 10-15 pts | **Acceptable band** — slice ships if capability boundary is clear; consider merging if drift-prone |
| < 10 pts | **Merge or keep as gating-only** — too small for standalone capability; merge with adjacent slice OR keep as gating/cleanup-only slice |

Thresholds are MEDIUM confidence — **`[CALIBRATE-AFTER-3]`** per the RELEASE_LOG calibration trigger. Review thresholds after 3 subsequent releases close.

**This point-band is the primary capacity ceiling; it governs.** The Stage 3 Bundle capacity heuristic of "5-8 issues per release" (`stage-03-bundle.md` § 5 Phase A4) is a **secondary readability/coordination heuristic, not an independent hard cap.** The two are complementary, not contradictory: a bundle within the point-band may exceed 5-8 small issues, and a bundle of 5-8 large issues may exceed the point-band — in which case the (risk-weighted) point-band governs. This is the single sizing source; Phase A4 cross-references here rather than asserting a parallel ceiling.

- **(current default frame — see § 1):** SAFe team capacity heuristic — story points fit per iteration; small-batch principle (smaller batches = faster feedback = lower risk) inherited from F2 Continuous Delivery (§ 1.2 alternative frame surveyed).
- **Composes with:** decomposition-review enforcement — G2-11 (Triage) + G3-12 (Bundle) COMPOSITE-OR predicate fires on `size:XL` OR declared decomposition hooks OR AC count ≥ 7 OR Affected Files count ≥ 5. This doctrine is **positive guidance** (target band); gate enforcement (positive guidance vs predicate firing) is the decomposition-review gate.
- **Per-milestone enforcement:** the risk-weighted membership sum (`effective_pts`, defined in the Step 5 Risk-Weighting sub-block below) is gated by **G3-15** (`gate-criteria-spec.md § Gate 3`) at the Bundle→Planning boundary — the per-milestone-sum complement to the per-issue G2-11 / G3-12 decomposition predicate. On breach G3-15 routes to the § 4 tight-merge or the § 3 Step 5 split/merge/reframe disposition above (not a dead-end fail), reading the SAME `release_size_target_pts` band and `release_class_capacity_weights` config so the modeled target and the enforced bound are a single source.
- **Output:** total pts + disposition + (if split) sub-slice list.

#### Step 5 — Risk-Weighting (Release-Class capacity multiplier)

The raw point sum measures *complexity*. A release also carries *ceremony* — coordination, review depth, and rollback risk — that scales with the milestone's Release Class (the orthogonal axis declared at Phase B3; see § 7 and the release-class taxonomy). Risk-weighting modulates the size-check so a higher-ceremony release's raw points count for more against the same band:

```
effective_pts = round_half_up( sum(member_pts) * class_weight )
```

- **`sum(member_pts)`** uses the same point scale as the size-check above (no separate scale).
- **`class_weight`** resolves from the milestone's declared `## Release Class` (gate G3-10 guarantees the field is present and is one of the four CLOSED enum values), falling back to the configured default release class when absent. The per-class weights — `routine` the identity baseline, `novel` and `cross-cutting` weighted progressively heavier (more ceremony), `hotfix` weighted lighter than baseline (narrow but still real corrective risk) — live as the single numeric home in the `[bundling].release_class_capacity_weights` field of `core/config/platform-config.toml.template`, resolved per the 5-rung cascade. This sub-block cites those weights **by role and does not restate the numbers** (parameterize-over-hardcode); the config field carries the canonical values + the validity rule.
- **Rounding mode is round-half-up** — definitively, at this definitional home: a `.5` result rounds away from zero (e.g., `22.5 → 23`), NOT banker's round-half-to-even. Every consumer of `effective_pts` (the size-check here, any per-milestone size-bound enforcement gate, and any velocity-instrument field that records the value) MUST take the rounding mode by reference from this sub-block and never re-derive it, so a producer and an enforcer cannot disagree at a half-integer boundary where the band edge (e.g., the 25-pt ceiling) flips disposition.
- **`effective_pts` is evaluated against the same `[bundling].release_size_target_pts` band using the disposition table above** — no new disposition rows. The asymmetry IS the risk-weighting: a `cross-cutting` bundle whose raw points sit at the top of the target band resolves to an `effective_pts` above the ceiling and fires the ">25 split" disposition where raw points would have read "target band."

**Multi-trigger class resolution** is already governed by the release-class taxonomy (a single declared class per milestone); the weight reads that one declared class, so risk-weighting adds no new resolution logic.

**Capacity-altitude boundary (release-bundle ≠ delivery-team).** Release-bundle capacity (this model) sizes a release's scope-commit in story points modulated by Release Class ceremony. It is NOT delivery-team capacity: available-hours, focus-factor, and effective-capacity are owned by the delivery-engine capacity model and estimation standards at the project-delivery altitude. The two never share a value, and the `class_weight` multiplier does NOT consume or reference focus-factor. This model introduces exactly one new construct (`class_weight`) and reuses the size-check's existing point scale.

**Recalibration (`[CALIBRATE-AFTER-3]`).** The `release_class_capacity_weights` defaults are MEDIUM-confidence seeds. After ≥3 releases tracked in the RELEASE_LOG velocity instrument (planned-vs-delivered, files-changed, allocation actuals), recalibrate the weights from the per-class delivered-vs-planned ratio — a class whose releases systematically over- or under-run its band signals a weight adjustment — and advance the `[calibration].releases_since_calibration` counter. The velocity instrument is the measurement half and these weights are the heuristic half of one calibration loop sharing that counter.

**Enforcement layer.** This sub-block is positive guidance (it produces `effective_pts`); a per-milestone size-bound enforcement gate in the decomposition-review gate family (see § 11.8) asserts `effective_pts` against the band ceiling at the Stage 3→4 boundary and routes a breach to § 4 tight-merge or the disposition table above (not a dead-end fail). The gate reads the SAME `class_weight` config this sub-block defines, so the modeled target and the enforced bound are a single source.

- **Output:** raw `sum(member_pts)` + `effective_pts` + the band disposition the effective points resolve to.

### Step 6 — Declare internal sequence

Order tickets within the slice: foundation-dep first, then infrastructure-dep, then skill-core, then eval-verification.

- **(current default frame — see § 1):** SAFe ART per-iteration sequence within a PI (foundation tasks first); composes with F2 Continuous Delivery dep-aware pipeline stage ordering (§ 1.2 alternative frame surveyed) — each stage's output is next stage's input.
- **Composes with:** Stage 4 A8 critical-path (CPM longest-chain) per the Stage 4 A8 critical-path spec — DP-DAG longest-path relaxation over Kahn's-emitted topo-sorted sequence. The internal sequence declared at Step 6 informs the schedule-determining chain at Stage 4.
- **Output:** ordered ticket list (foundation → infra → skill-core → eval).

### Step 7 — Declare external deps to other slices

Target **≤2 external deps** per slice. If more, reconsider slice boundary — high external-dep coupling signals slice scope is too narrow OR slice boundary is misplaced.

- **(current default frame — see § 1):** SAFe program-board cross-team dependency visualization (target: minimize cross-ART dep chains).
- **Composes with:** G3-07 cross-milestone dependency sequence per [`gate-criteria-spec.md § Gate 3`](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness). External deps are cross-milestone deps from the perspective of the slice; G3-07 validates the sequence; this doctrine targets the count.
- **Output:** external-dep list (`#N → milestone-position`) with count; if >2, rationale or boundary-reconsider note.

## 4. Tight-Merge Mechanics

For oversized parents (>15 tickets after Step 1-4): split the parent into sub-slices via Step 1 re-application per sub-capability. **Only merge sub-slices back into a single milestone when they have internal dep edges** (verified via graph). Loose sub-slices (no internal deps) become separate milestones.

**Worked example: Foundation.**

- **Pre-split state:** the Foundation milestone had 13 sub-slices (oversized parent).
- **Tight-merge result:** 4 sub-slices merged into the stage-discipline milestone (3 internal dep edges verified via graph traversal).
- **Loose-split result:** the other 9 sub-slices became individual milestones (zero internal dep edges among them).
- **Verification:** dep graph traversal confirmed which 4 had internal edges; merge decision was algorithmic, not narrative.

**Algorithm:**

1. After Step 1-4, if total tickets > 15: re-apply Step 1 per sub-capability → emit candidate sub-slices.
2. For each pair of candidate sub-slices `(Sa, Sb)`: count dep edges where source ∈ Sa AND target ∈ Sb (or vice versa).
3. Build sub-slice merge-graph: nodes = sub-slices; edges = sub-slice pairs with ≥1 internal dep edge.
4. Connected components in the merge-graph = tight-merge groups; each component lands as ONE milestone. Singleton sub-slices land as separate milestones.

**Composes with:** [`fission-convention.md`](../protocols/fission-convention.md). Fission is the **work-item-decomposition** counterpart (oversize ticket → child tickets); tight-merge is the **milestone-composition** counterpart (oversize milestone → sub-slices with internal-dep-aware re-merge). Both share the "split when scope exceeds capacity; rejoin only when dep edges justify" principle.

## 5. Naming Convention

Milestone titles follow: **`v<MAJOR>.<NN-padded>-<capability-slug>`**.

| Component | Format | Example |
|---|---|---|
| `<MAJOR>` | Integer; signals work-mode | `1` (a foundation track), `2` (a later work-mode track) |
| `<NN-padded>` | 2-digit zero-padded minor; lexical sort stability at >9 items per major | `04` (NOT `4`) |
| `<capability-slug>` | Hyphenated lowercase capability name from Step 1 output | `pipeline-fitness-foundation` |
| **Composite** | All three joined by `.` and `-` | `v1.04-pipeline-fitness-foundation` |

**Padding rationale.** 2-digit padding ensures lexical sort matches numeric sort even when minor count crosses 9. `v1.10` sorts lexically AFTER `v1.09` (correct); without padding, `v1.10` sorts BEFORE `v1.2` (incorrect). The slice methodology (operator memory) ratified this convention; observed across the platform's milestones.

**Major-version semantics.** Major version signals **work-mode transitions**, not chronological order — each major-version track maps to a distinct work-mode (e.g., a foundation track, then later tracks for successive work-modes). Releases may deploy out of numeric sequence due to parallel work (see [`RELEASE_LOG.md`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>) § Deploy Order for chronological timeline). New theme-axes get new major-version tracks per § 6.

**Legacy milestones grandfathered.** Milestones created before this convention used single-digit unpadded minor — grandfathered per § 10 Cutover. Do not retro-rename.

## 6. A6 New-Track Placement Rationale (new-track special case of the doctrine)

The Stage 3 Bundle Phase A6 New-Track Placement Rationale (per `release-process.md` § Stage 3 Bundle) is the **new-track special case** of this doctrine. A6 enforces enumeration discipline (alternatives × Reject / Considered-but-rejected / Anchor verdict) for the specific question "does this milestone need a new version-major track?" — but the same enumeration discipline applies to the broader question "what coheres in this slice?" answered by Step 1-7 above.

**Reframe.** A6 fires when the proposed milestone's version prefix does not appear on any open or closed milestone. When A6 fires, the Stage 3 spoke MUST author the A6 rationale section per the existing 4-table format (existing-milestone alternatives / existing-roadmap alternatives / existing-initiative alternatives / conclusion). Authoring is **incremental** atop Step 1-7 — Step 1 establishes the capability; A6 establishes why no existing track absorbs the capability.

**Relationship to Step 4.** Step 4 (check older milestones for prerequisites) operates **within** an established track. A6 operates **across** tracks when a new track is proposed. If Step 4 surfaces sufficient absorbable prerequisites in an existing milestone, the slice MAY belong to that milestone's track — and A6 does not fire. A6 fires only when no track exists for the proposed work-mode axis.

**No edit to A6 mechanics.** A6's existing detection / authoring / Phase B sequencing semantics are preserved. The reframe is **conceptual** (A6 IS the new-track special case) — operational A6 mechanics live at `release-process.md` § Stage 3 Bundle § A6 (unchanged).

## 7. Required Fields (Milestone Description Schema)

Stage 3 Phase B3 milestone-description authoring populates these fields, consolidating sibling-defined required fields:

| Field | Source spec | Required? | Format |
|---|---|---|---|
| **Outcome (AFTER + BEFORE)** | [`release-outcome-statement-template.md`](../specs/release-outcome-statement-template.md) | REQUIRED | `### Release Outcome Statement` H3 with `**AFTER**` + `**BEFORE**` (1-3 sentences each); OPTIONAL `**Actor(s):**` + `**Success Indicator:**` |
| **Release Class** | [`release-class-taxonomy.md`](../specs/release-class-taxonomy.md) | REQUIRED | `## Release Class` H2 with `Class:` field (enum: routine / novel / cross-cutting / hotfix) + non-empty `Rationale` sub-field |
| **Scope (tickets + sub-slices)** | This doctrine § 3 Step 2 + § 4 | REQUIRED | Ticket list (`#N`) + pts + sub-slice list (when tight-merge applied) |
| **Internal sequence** | This doctrine § 3 Step 6 | REQUIRED | Ordered ticket list with layer annotations (foundation → infra → skill-core → eval) |
| **Dep Exceptions** | G3-07 | CONDITIONAL — only when ≥1 cross-milestone dep exception registered | `## Dependency Exceptions` block with per-exception rationale + authorizer + date |
| **A6 New-Track Placement Rationale** | This doctrine § 6 + `release-process.md § Stage 3 A6` | CONDITIONAL — only when A6 fires (new version-prefix track) | `## New-Track Placement Rationale (recorded YYYY-MM-DD)` section with 4-table format |
| **Amendment Log** | A7 Bundle Mutability Protocol per `release-process.md` | CONDITIONAL — only when amendments occur post-creation | `[BUNDLE AMENDMENT]` / `[BUNDLE REFRESH: ...]` comment trail on milestone |
| **Bundle Composition Frame** | This doctrine § 1 | OPTIONAL — defaults to current platform-config frame (F1) | One-line declaration in milestone description preamble when frame differs from current default |

**Operator approval at Phase B1.** All REQUIRED fields populated by the Stage 3 spoke draft; operator approves at Phase B1 Decision Briefing before Phase B3 milestone creation.

**Schema query.** All fields are queryable via `gh api repos/{REPO}/milestones/<N> --jq .description`.

## 8. Worked Examples (6 composition shapes)

Each shape demonstrates how Step 1-7 apply to a real-world bundle scenario. Shapes are **descriptive enumerations** — additional shapes can be discovered as the platform evolves; this list is not exhaustive.

### Shape 1 — Capability-slice (vertical user-facing capability)

**Example: the pipeline-fitness-foundation capability slice** (10 issues, 54 pts; oversized — required Tight-Merge per § 4 analysis at Stage 4 close).

- **Step 1 — Capability:** AFTER: agents can apply pipeline-fitness protocols (handoff discipline / release-class / outcome / readiness-scan / adversarial review / doc-impact / discovery-discipline / decomposition-review / bundle-composition) autonomously per K1 reference corpus. BEFORE: protocols live in operator memory + ad-hoc operator judgment.
- **Step 2 — Tickets:** 10 tickets establishing 9 pipeline-fitness disciplines (discovery / outcome / class / readiness-scan / adversarial / fission / doc-impact / bundle-composition / decomposition-review) + 1 hub spoke return-value schema.
- **Step 3 — Dep walk:** all skill-implementation tickets; dep edges enforce SINGLE-branch topology serialization (D-C SINGLE).
- **Step 4 — Older milestones:** none — all 10 tickets bundled directly.
- **Step 5 — Size:** 54 pts (oversized). Operator-judgment override applied: ship as one milestone with REFLEXIVE-EXEMPT-ALL cutover discipline rather than split (rationale: synthesis-layer coherence outweighs size-target).
- **Step 6 — Sequence:** spoke-return-schema → fission → discovery → release-class → outcome-statement → readiness-scan → doc-impact → decomposition-review → adversarial-review → bundle-composition synthesis, per Stage 4 critical-path analysis (synthesis-layer lands last per § 9).
- **Step 7 — External deps:** ≤2 (composes with the substrate per cutover anchor; no other open external deps).

### Shape 2 — Hotfix (single-issue critical defect)

**Example: the deploy-cleanup-hotfix** (1 issue, ~4 pts).

- **Step 1 — Capability:** AFTER: deploy.sh failure mode does not cascade-break Stage 12 Execute. BEFORE: deploy.sh failure cascades.
- **Step 2 — Tickets:** 1 ticket (the hotfix).
- **Step 3 — Dep walk:** N/A (zero prerequisites for hotfix).
- **Step 4 — Older milestones:** N/A.
- **Step 5 — Size:** ~4 pts (well below 10-pt floor — acceptable for hotfix shape; hotfix Release Class waives size-target band).
- **Step 6 — Sequence:** single-ticket → no internal sequence required.
- **Step 7 — External deps:** zero (hotfix shape is dep-free by definition).
- **Class:** `hotfix` per [`release-class-taxonomy.md`](../specs/release-class-taxonomy.md) — bypass-mode-readiness ceremony.

### Shape 3 — Audit-driven (cleanup from audit findings)

**Example: hypothetical v1.XX-audit-cleanup-batch** (5-8 issues, 10-15 pts).

- **Step 1 — Capability:** AFTER: audit findings from `<audit-name>-YYYY-MM-DD/` SUMMARY.md remediated; corpus drift cleared. BEFORE: known drift items unresolved.
- **Step 2 — Tickets:** all issues filed from the audit's `issue-drafts/` folder per CLAUDE.md analysis folder convention.
- **Step 3 — Dep walk:** typically zero (audit findings are independent cleanups).
- **Step 4 — Older milestones:** N/A (audit findings are net-new).
- **Step 5 — Size:** 10-15 pts (acceptable band — audit-cleanup is typically small per-issue).
- **Step 6 — Sequence:** by file-contention order if any contention exists; otherwise priority-desc.
- **Step 7 — External deps:** typically zero (cleanup is dep-free).
- **Class:** `routine` per [`release-class-taxonomy.md`](../specs/release-class-taxonomy.md).

### Shape 4 — Cleanup-debt (technical debt drainage)

**Example: hypothetical v2.XX-broken-ref-drainage** (1-3 issues, 5-15 pts).

- **Step 1 — Capability:** AFTER: broken-ref backlog (per the F-4 broken-ref backlog) drained to <10 entries; doc-link corpus consistent. BEFORE: ≥30 broken-ref backlog entries causing warn-log noise.
- **Step 2 — Tickets:** drainage issue + companion-fix issues for any drift surfaced during drainage.
- **Step 3 — Dep walk:** drainage may surface need for upstream fixes; pull those into the slice.
- **Step 4 — Older milestones:** N/A (drainage is on-going maintenance).
- **Step 5 — Size:** 5-15 pts (acceptable; sub-10-pt for pure drainage with no surfaced fixes).
- **Step 6 — Sequence:** drainage execution → surfaced-fix application → re-drainage verification.
- **Step 7 — External deps:** zero.
- **Class:** `routine` per [`release-class-taxonomy.md`](../specs/release-class-taxonomy.md).

### Shape 5 — New-track-inaugural (first release in a new version-major track)

**Example: hypothetical v3.XX-cluster-portfolio-discipline** (inaugural worked example for A6 § 6 — first release in a hypothetical `v3.*` portfolio-discipline track).

- **Step 1 — Capability:** AFTER: portfolio discipline cluster axis recognized as distinct work-mode. BEFORE: portfolio work scattered across non-portfolio tracks.
- **Step 2 — Tickets:** 4-7 tickets establishing the portfolio cluster.
- **Step 3 — Dep walk:** establishes portfolio cluster foundation; no prior portfolio milestones to walk.
- **Step 4 — Older milestones:** N/A (new track).
- **Step 5 — Size:** target 15-25 pts (inaugural slice).
- **Step 6 — Sequence:** foundation → infra → skill-core per standard.
- **Step 7 — External deps:** ≤2.
- **A6 REQUIRED:** Phase A6 fires; rationale section authored per § 6 (existing-milestone / existing-roadmap / existing-initiative alternatives evaluated; conclusion names new theme axis).

### Shape 6 — Subsumption-fission (oversized parent split into child slices)

**Example: the Foundation milestone original split → the stage-discipline milestone + 9 individual milestones** (per § 4 worked example).

- **Pre-split parent:** 13 sub-slices, ~50 pts (oversized).
- **Step 1 — Capability (per sub-slice):** each sub-slice gets its own AFTER/BEFORE.
- **Step 2-4:** per sub-slice.
- **Step 5 — Size:** sub-slices fall within 5-15 pt range each.
- **§ 4 Tight-merge:** 4 sub-slices with internal dep edges → the stage-discipline milestone; 9 loose sub-slices → individual milestones.
- **Composes with:** [`fission-convention.md`](../protocols/fission-convention.md) — same split-when-oversize principle applied at milestone-composition altitude rather than work-item altitude.

## 9. Sequence Rules

Within a bundled release, the **execution sequence** of issues follows:

1. **Foundation layer first** — `layer:foundation` tickets land before downstream layers consume them.
2. **Infrastructure layer next** — `layer:infrastructure` tickets land after foundation, before skill-core consumes them.
3. **Skill-core next** — skill/protocol/spec implementations.
4. **Eval / verification last** — eval set additions, verification protocols, regression-test additions.

**Within-layer tie-break** — priority-desc (P1 > P2 > P3 > P4) → issue-number-asc per Kahn's BFS tie-break (the `dependency-analysis.md` Tie-Breaker Rule, ADR-1).

**Critical-path emission** — after layer-ordered sequence, Stage 4 A8 computes the schedule-determining chain via DP-DAG longest-path per the Stage 4 A8 spec. The critical path informs which sub-slice (within a tight-merge) must complete first.

**Synthesis-layer placement** — when one ticket in the bundle synthesizes work across multiple sibling tickets (e.g., the bundle-composition synthesis — composes-with all 9 siblings), the synthesis ticket lands LAST in the sequence after all composed-with siblings complete.

## 10. Cutover

**Cutover.** Applies to all milestones created going forward — reflexive-pipeline-loop discipline. Pre-existing milestones are grandfathered.

**Grandfathered milestones** continue under operator-judgment composition. The doctrine applies prospectively to milestone creation; the doctrine does NOT retroactively amend grandfathered milestone descriptions.

**Frame-pluggability cutover.** The bundle-composition frame is config-driven via the live `[bundling].bundle_doctrine_frame` field (`core/config/platform-config.toml.template`, default `"F1"`). Existing milestones (under the F1 default) continue under F1; new milestones may select an alternative frame per the config surface, resolved by the 5-rung resolver (`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`). The doctrine prose at § 1 remains; only the resolved frame value changes.

## 11. Composition with Sibling Standards

The doctrine composes with the nine sibling Stage 5 outputs by **referencing their canonical surfaces** rather than redefining them. Each boundary statement clarifies the WHERE-doctrine-ends and WHERE-sibling-begins. The §11.1-§11.9 sub-sections below enumerate each sibling discipline by canonical file-path.

### 11.1 Composition ≠ Discovery — [`discovery-discipline.md`](../../../core/disciplines/discovery-discipline.md)

| This doctrine | discovery-discipline.md |
|---|---|
| Governs WHAT goes in a release once items are intake-validated | Governs WHEN to file new tickets (versus expand an existing one) |
| Stage 3 Bundle scope | Stage 1 Intake scope |
| Output: milestone composition | Output: ticket-creation decision |

**Boundary:** composition operates on already-intaked tickets; discovery operates on observation-tier signals BEFORE intake. No overlap.

### 11.2 Outcome Statement — [`release-outcome-statement-template.md`](../specs/release-outcome-statement-template.md)

| This doctrine | release-outcome-statement-template.md |
|---|---|
| Step 1 of § 3 IS the AFTER/BEFORE authoring act | Defines the AFTER/BEFORE schema + Class-driven shape variations |
| Persists outcome in milestone description per § 7 Required Fields | Defines the `### Release Outcome Statement` H3 block format |

**Boundary:** doctrine § 3 Step 1 invokes the outcome-template schema; outcome-template owns the schema definition. One authoring act, two consumed surfaces.

### 11.3 Composition ⊥ Class — [`release-class-taxonomy.md`](../specs/release-class-taxonomy.md)

| This doctrine | release-class-taxonomy.md |
|---|---|
| WHAT coheres in the slice (capability scope) | HOW heavy the ceremony (routine / novel / cross-cutting / hotfix) |
| Orthogonal axis: composition-shape | Orthogonal axis: ceremony-class |
| § 7 enumerates Class as REQUIRED field | Defines Class enum + Rationale field |

**Boundary:** orthogonal axes — a slice's composition shape (Shape 1 capability-slice) is independent of its ceremony class (e.g., novel + cross-cutting). Both are required fields in the milestone description per § 7.

### 11.4 Composition feeds Readiness Scan — [`release-readiness-scan-spec.md`](../specs/release-readiness-scan-spec.md)

| This doctrine | release-readiness-scan-spec.md |
|---|---|
| Bundle authoring at Stage 3 | Pre-deploy assessment at Stage 9 |
| Provides input to Scan dimensions (composition-shape, slice-coherence) | Defines 13 dimensions; composition-coherence may be one |

**Boundary:** doctrine provides composition-shape signal to Scan; Scan independently assesses dimensions including composition-coherence as one input.

### 11.5 Composition reviewed BY Adversarial — adversarial review per the `pmo-adversarial` agent (`.claude/agents/pmo-adversarial.md`)

| This doctrine | Adversarial reviewer |
|---|---|
| Governs how the composition is selected | Reviews the selected composition for unstated risks |
| Stage 3 / Stage 4 authoring | Stage 5 Phase A6.5 review |
| Doctrine spec is itself an adversarial-review input | Adversarial review consumes doctrine § 3-9 + sibling specs |

**Boundary:** doctrine prescribes; adversarial reviews. Adversarial review per Stage 5 Phase A6.5 consumes the composition output for stress-test-the-design before Engineering.

### 11.6 Composition consumed by release-planner — `release-planner` SKILL

| This doctrine | release-planner SKILL.md |
|---|---|
| Defines the methodology | Mode A invokes the methodology; Mode B persists doctrine-derived fields |
| K1 reference doc | Skill consumer |

**Boundary:** release-planner is the primary consumer; doctrine is the governance. Mode A consults this doctrine; Mode B writes outputs per the doctrine schema. release-planner Stage 6 return-value schema reports composition shape selected as one return field.

### 11.7 Tight-merge composes with Fission — [`fission-convention.md`](../protocols/fission-convention.md)

| This doctrine § 4 Tight-merge | fission-convention.md |
|---|---|
| Milestone-altitude composition (oversize milestone → sub-slices, re-merge with dep-edge gate) | Work-item-altitude decomposition (oversize ticket → child tickets) |
| Operates on tickets-in-bundle | Operates on tickets-as-unit |

**Boundary:** same split-when-oversize principle applied at two altitudes. Doctrine § 8 Shape 6 cross-references fission for the work-item altitude.

### 11.8 Composition guides Decomposition-Review — decomposition-review gate

| This doctrine § 3 Step 5 size-check | Decomposition-review gate G2-11 / G3-12 |
|---|---|
| Positive guidance (target band 15-25 pts; thresholds) | Gate enforcement (COMPOSITE-OR predicate fires routing) |
| `[CALIBRATE-AFTER-3]` thresholds | Auto-execute structural check |

**Boundary:** doctrine prescribes the target band; decomposition-review enforces routing when predicates fire. Issues that route at G2-11 satisfy G3-12 trivially unless body materially changes.

### 11.9 Doc-impact declarations inform dep walk — doc-impact gate

| This doctrine § 3 Step 3-4 dep walk | doc-impact declaration |
|---|---|
| Reads doc-impact declarations as one dep signal | Defines doc-impact declaration field in ticket bodies |

**Boundary:** doc-impact declarations remain a doc-impact-owned field; doctrine reads them as input during Step 3-4 dep walk. No bidirectional cite required.

## 12. Cross-Reference

**Sibling K1 standards (parallel-to):**

- [`release/references/explanation/discovery-discipline.md`](../../../core/disciplines/discovery-discipline.md) — discovery vs composition boundary (§ 11.1)
- [`release/references/specs/release-class-taxonomy.md`](../specs/release-class-taxonomy.md) — orthogonal axis (§ 11.3)
- [`release/references/standards/triage-design-rereview.md`](triage-design-rereview.md) — re-review composition-coherence findings route to Tier 0/1/2/3 per § Inter-Stage Feedback Protocol
- [`release/references/standards/initiative-roadmap-framework.md`](../../../core/standards/initiative-roadmap-framework.md) — structurally-closest sibling (same heading layout, frontmatter shape); roadmap binding when initiative spans multiple slices

**Sibling specs (composed-with):**

- [`release/references/specs/release-outcome-statement-template.md`](../specs/release-outcome-statement-template.md) — Step 1 invokes this template (§ 11.2)
- [`release/references/specs/release-readiness-scan-spec.md`](../specs/release-readiness-scan-spec.md) — composition feeds Scan (§ 11.4)
- [`release/references/protocols/fission-convention.md`](../protocols/fission-convention.md) — work-item-altitude counterpart (§ 11.7)
- [`release/references/schemas/gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) — G3-07 (Step 4 + Step 7), G3-10 (Class field at § 7), G2-11/G3-12 (size-check at § 3 Step 5 + § 11.8)

**Tooling consumers:**

- [`release/skills/release-planner/SKILL.md`](../../skills/release-planner/SKILL.md) — Mode A invokes; Mode B persists (§ 11.6)
- [`release/references/pipeline/stage-03-bundle.md`](../pipeline/stage-03-bundle.md) — §5 Phase A6 reframe (§ 6); §5 Phase B3 milestone-description schema citation (§ 7)
- [`release/references/pipeline/stage-04-planning.md`](../pipeline/stage-04-planning.md) — Implementation Sequence (§ 9)
- [`release/governance/release-process.md`](../../governance/release-process.md) + mirror [`release/governance/release-process.md`](../../governance/release-process.md) — Stage 3 Bundle section cross-reference
- [`release/governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) — Implementation Plan Format section cross-reference

**Operator memory (originating substrate):**

- The slice methodology — 7-step method + tight-merge + naming convention (operator memory; promoted to this K1 reference)
- The release-sequence narrative across the platform's work-mode tracks (operator memory)

**Historical record:**

- 2026-04-24 reorg coordinator (CLOSED) — first application of the methodology (234 tickets → 210 in 43 milestones + 30 closures)
- Stage 4 A8 critical-path (CLOSED) — composes with § 3 Step 6 internal-sequence
- File contention analysis (CLOSED) — composes with § 3 Step 2 ticket-listing
- G3-07 cross-milestone sequence (future release) — composes with § 3 Step 4 + Step 7
- Release-planner GitHub Issues migration (future release) — composes with § 11.6

**Future-state config mechanism:**

- Unified pmo-platform config mechanism (adapter-config-foundation) — SHIPPED; the live `[bundling].bundle_doctrine_frame` field (`core/config/platform-config.toml.template`) makes the § 1 frame swappable on milestone-creation and milestone-update without doctrine prose rewrite, resolved per `core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`

## 13. Version History

| Version | Date | Change | Authority |
|---|---|---|---|
| Initial | 2026-05-25 | Initial. Promotes 7-step vertical capability slice methodology from operator memory to K1 codified-knowledge corpus. Frame: F1 SAFe Feature-Slicing + Vertical Slice (current default per platform config per operator clarification 2026-05-24; frame-pluggability discipline). Cutover REFLEXIVE-EXEMPT-ALL — the introducing release itself is exempt. | Stage 5 D-decisions; operator-CONFIRMED at Collective Review 2026-05-25 |
| v11.28 | 2026-06-17 | Adds the § 3 Step 5 Risk-Weighting (Release-Class capacity multiplier) sub-block — `effective_pts = round_half_up(sum(member_pts) * class_weight)`, weights cited by role from `[bundling].release_class_capacity_weights` (single numeric home), round-half-up pinned at this definitional home, delivery-team-capacity boundary clause, `[CALIBRATE-AFTER-3]` recalibration linkage to the RELEASE_LOG velocity instrument, and an enforcement-layer reference to the decomposition-review gate family. Consolidates the sizing guidance: names the point-band as the governing capacity ceiling and the Stage-3 "5-8 issues" item-count as a secondary readability heuristic. Additive only; no existing rule restated. | Stage 5 Solutioning design + scope-lock; Stage 6 Engineering (release v2.02, milestone 61-bundling-capacity-and-sizing-gates) |
