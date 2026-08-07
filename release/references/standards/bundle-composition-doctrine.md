---
title: Bundle Composition Doctrine
type: standard
version: v11.28
purpose: Codifies the agent-readable methodology for deciding WHAT belongs in a given milestone and WHY those items cohere as a shippable unit — the 7-step vertical capability slice method + tight-merge mechanics + naming convention + size-target heuristics + risk-weighted capacity model + sequence rules + the retention guardrails constraining a recommendation to remove work from the backlog
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
  - release/references/pipeline/stage-02-triage.md (§ 12 read when A6.5 Pattern (1) surfaces a removal candidate)
  - release/skills/roadmap-curator/SKILL.md (§ 12 read at Mode B re-baseline and Mode C drift audit)
last-updated: 2026-08-03
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
- Backlog-retention guardrails (§ 12) — the restraints on a recommendation to REMOVE work from the backlog.
- Cross-reference catalog (§ 13).
- Version history (§ 14).

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

**Single-item / milestone-of-one shape.** A release may legitimately ship a **single work item**. The `< 10 pts` row is positive guidance to prefer merging *drift-prone* small slices — it is **not** a prohibition on a standalone single-item release. A single-item release is a first-class shape (frequently paired with the `version-less` identity mode — see § 5 *Version-less naming form* and [`stage-03-bundle.md § 4 Release-Identity Mode`](../pipeline/stage-03-bundle.md)); the single-item-vs-bundle choice is a **Stage-5 D-class decision**, not committed at intake.

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
| `<MAJOR>` | Integer; a major bump is a deliberate work-mode re-baseline on the single active track, not a chronological generation counter | `1`, then the `2` re-baseline |
| `<NN-padded>` | 2-digit zero-padded minor; lexical sort stability at >9 items per major | `04` (NOT `4`) |
| `<capability-slug>` | Hyphenated lowercase capability name from Step 1 output | `pipeline-fitness-foundation` |
| **Composite** | All three joined by `.` and `-` | `v1.04-pipeline-fitness-foundation` |

**Padding rationale.** 2-digit padding ensures lexical sort matches numeric sort even when minor count crosses 9. `v1.10` sorts lexically AFTER `v1.09` (correct); without padding, `v1.10` sorts BEFORE `v1.2` (incorrect). The slice methodology (operator memory) ratified this convention; observed across the platform's milestones.

### Version-less naming form (release-identity mode)

The title convention above is the **`versioned`** identity-mode form. A **`version-less`** release (per [`stage-03-bundle.md § 4 Release-Identity Mode`](../pipeline/stage-03-bundle.md)) omits the `v<MAJOR>.<NN>` prefix entirely — its milestone title is the **capability slug alone**:

| Identity mode | Title form | Example |
|---|---|---|
| `versioned` | `v<MAJOR>.<NN-padded>-<capability-slug>` | `v1.04-pipeline-fitness-foundation` |
| `version-less` | `<capability-slug>` (no version prefix) | `public-flip-install-blockers` |

Both forms admit either bundle size — **all four combinations** (`versioned`/`version-less` × single-item/bundle) are supported; the single-item shape is § 3 Step 5.

**Reconciliation with the version grammar.** A `version-less` release carries **no version key**, so the [`version-grammar.sh`](../../tools/version-grammar.sh) input gate `version_canonical` (and the freeness/comparison path built on it) is **never invoked** for it — there is no candidate string to present, so `version-grammar.md`'s rejection of the empty form is neither reached nor contradicted. The grammar governs the string a *versioned* release claims; it has no jurisdiction over one that claims none. This is distinct from the § 9.1 rule "never ship version-less to *dodge* a slot collision" — that prohibits version-less as a collision *hedge*; the identity mode is a first-class *on-the-merits* choice.

### 5.1 Slot allocation

A milestone's `v<MAJOR>.<NN>` number is the **next free minor within the active major**, computed at claim time against the authoritative version landscape — the set of versions already claimed in the mainline's lineage (released tags plus any number held by an in-flight release that will reach the mainline). The lowest minor not in that set is the allocated slot.

The number is **intent-to-bump while the release is in the pipeline, and claimed atomically at the merge** — it is not bound when the milestone is created. Planning records a provisional display number for human readability; the concrete number is fixed only when the release tags, by recomputing next-free at that instant. The allocation rule itself (what "next free" means, against which authoritative refs) and the atomic claim-at-merge mechanism are specified by the founding version-claim-determinism Architecture Decision Record and the version-allocation rule in the Release Protocol; this section states the *allocation semantics* a bundle author relies on and does not re-specify that mechanism.

Two freeness checks bracket the allocation: a planning-time check when the provisional number is first recorded, and a pre-merge check at execution. A collision detected at either point is resolved by re-versioning up (§ 5.3), not by overwriting an existing claim.

### 5.2 Numeric order is not ship order (chronological caveat)

A milestone's version number records the slot it was allocated, **not its position in chronological ship order**. Because minors are allocated next-free at claim time and releases run pipelines of different lengths, a higher-numbered release may merge — and therefore tag and ship — before a lower-numbered one when work proceeds in parallel. Reading a version number as "this shipped after every lower number" is therefore unsound.

The runtime guarantee is the inverse: **ship order equals merge order equals tag order**. A release ships when it merges to the mainline, and it claims its number at that same merge, so the tag sequence reflects the actual order things shipped — but that order is not required to be numerically monotonic. Monotonicity holds *per claim at the tag* (each claim takes a then-free number), not across the order releases entered the pipeline. The parallel-release sequencing rules that make merge order the single ordering authority are defined in the Sequence Rules of this doctrine (§ 9); the chronological deploy timeline is recorded in the release log.

### 5.3 Reservation and renumbering

- **No early reservation.** A number is not held before it is claimed. There is no "reserved but unbuilt" window — the slot is taken at the merge, and only then. This is what keeps a long-running pipeline from blocking a number it has not yet earned.
- **Renumbering is forward-only on collision.** When a claim collides — another release took the intended number first — the release re-versions **up** to the next free number at execution, never down and never over an existing claim. Re-versioning up is a normal, expected event under parallel work, not an incident; the release log shows real instances of a release moving up one or more minors when its intended slot was taken before it merged.
- **No retroactive milestone renaming.** Once a milestone carries its number, that number is not changed after the fact to "fix" chronological order or close a numbering gap. Numbering gaps (from abandoned or re-versioned claims) are permanent and benign. Legacy milestones predating this convention are likewise left as-is (§ 5.4, § 10).

### 5.4 Major-version semantics

Major version signals a **work-mode re-baseline on the single active track**, not chronological order and not a set of concurrent theme-tracks. The platform currently runs **one active track**: minors increment within a major, and a major bump (e.g., the `v1.x` line followed by the `v2.x` re-baseline) is a deliberate re-baseline event, not the opening of a second track that runs alongside the first. Releases may deploy out of numeric sequence due to parallel work within the active track (§ 5.2); the chronological deploy timeline is recorded in the release log.

The naming scheme *permits* a future major track for a genuinely distinct work-mode (the § 6 New-Track Placement Rationale governs when one is opened), but that is a possible future shape, not current allocation — there are zero concurrent theme-tracks today. Treat any prose elsewhere describing "a major-version track per work-mode" as describing this permitted future capability, not an active multi-track convention.

**Legacy milestones grandfathered.** Milestones created before this convention used single-digit unpadded minor — grandfathered per § 10 Cutover. Do not retro-rename.

## 6. A6 New-Track Placement Rationale (new-track special case of the doctrine)

The Stage 3 Bundle Phase A6 New-Track Placement Rationale (per `release-process.md` § Stage 3 Bundle) is the **new-track special case** of this doctrine. A6 enforces enumeration discipline (alternatives × Reject / Considered-but-rejected / Anchor verdict) for the specific question "does this milestone need a new version-major track?" — but the same enumeration discipline applies to the broader question "what coheres in this slice?" answered by Step 1-7 above.

**Reframe.** A6 fires **per milestone** when EITHER (a) the milestone's version-major track carries no prior recorded rationale OR (b) the milestone introduces a distinct capability scope relative to its track (the inaugural new-version-prefix case being the strongest sub-case of (b)) — see `release-process.md` § Stage 3 Bundle § A6 for the operational predicate. When A6 fires, the Stage 3 spoke MUST author the A6 rationale section per the existing 4-table format (existing-milestone alternatives / existing-roadmap alternatives / existing-initiative alternatives / conclusion); a genuine identical-track-extension instead records the one-line `A6: identical-track-extension …` acknowledgment. Authoring is **incremental** atop Step 1-7 — Step 1 establishes the capability; A6 establishes why no existing track or milestone absorbs the capability.

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

The rules above order issues **within one bundled release**. The subsection below states how releases sequence **against one another** when several run the pipeline concurrently — the runtime counterpart to the § 5.2 chronological caveat.

### 9.1 Parallel-release semantics

Multiple releases run the pipeline at the same time. This subsection states how a version number behaves across those concurrent in-flight releases and what fixes the order they ship in. It is the **doctrine** layer: the runtime machinery that makes every rule below true already ships, and this subsection **cites** that machinery by name and behavior rather than re-specifying it. It adds **no new gate** — the conflict detection it relies on is the set of checks already in the pipeline.

**The version number is a slot identifier, not a sequence ordinal.** A version `vMAJOR.MINOR` names a *slot* in the release lineage (allocated next-free per § 5.1); it does not encode "shipped Nth," and a lower number does not imply an earlier ship. The slot is *claimed* — never *reserved* — at the merge, so a number carries no ordering meaning until a tag claims it. This is the runtime restatement of the § 5.2 caveat: numeric order is not ship order.

**Ship-order = merge-order = tag-order — the held-but-unclaimed window is eliminated.** Of two concurrent in-flight releases, whichever **merges first claims the lower free slot**; the other recomputes next-free against fresh authoritative host state and claims the next slot. Ship-order is therefore *defined by* merge-order: a release ships when it merges, it claims its number at that same merge, and the tag sequence is the actual ship sequence. The guarantee is physical, not procedural — the claim is an atomic compare-and-swap on the host's version ref: a colliding claim is rejected, the loser recomputes next-free and retries, and no release ever overwrites another's claim. Because the number is claimed (not reserved) at the merge, there is no window in which a release *holds* a number it has not yet claimed; the recompute-and-retry-on-collision loop is exactly what closes that window. The claim is exposed host-agnostically as the repository-host adapter's atomic-claim operation (the capability defines the operation; a repository host satisfies it by any atomic means — for the GitHub/git reference adapter it is a signed-tag push whose ref compare-and-swap rejects a colliding push); the adapter spec and the founding version-claim-determinism Architecture Decision Record own that mechanism, and this subsection does not re-specify it.

**Two concurrent releases cannot both hold a number.** Neither *holds* it — each *claims* it atomically, and the second claim is rejected, recomputed, and retried upward. Reserving a number early was considered and rejected at the founding architecture: it re-introduces a held resource and an orphan-tag cleanup obligation, which is precisely the held-but-unclaimed window this design eliminates.

**The single hard constraint that overrides "any merge order is legal."** Absent a dependency between them, concurrent releases may merge in any order, and the order they merge in is the order they ship. The one exception is a declared **cross-milestone dependency edge**: for a real `#A -> #B` dependency (a dependency-edge schema token, not a live issue number), A's milestone must sequence at or after B's — the cross-milestone dependency-sequence release-readiness criterion (G3-07) is the gate that enforces it. That edge, and only that edge, constrains the merge order; everything else is free.

**Detecting a sibling that claims the slot first — by reference, no new gate.** A long-running release can lose its intended number to a faster concurrent release that merges first. The pipeline already detects this through its shipped defense-in-depth checks, and this doctrine relies on them rather than adding a third:

- the **mid-pipeline divergence re-check at Stage 9** — did a sibling touch this release's declared files (or claim its provisional version slot) in the plan-pin-to-GO window? This is the Phase A6.5 check (verdicts CLEAN / DIVERGED-RELEASE-FILES-UNTOUCHED / DIVERGED-RELEASE-FILES-TOUCHED). It is named in the Release Protocol Stage-9 prose as the `G-PR8` verdict, but note it is **not yet a registered row in the gate-criteria spec's Gate-9 table** — its enforcement lives in that Stage-9 procedure prose, and its registration as a criterion row is a separate, still-open task; a reader grepping the gate table for `G-PR8` will find no row, which is expected and not a defect in this doctrine;
- the **GO baseline-currency check at Stage 9** — the GO records the baseline SHA it was rendered against, and a sibling merging after that baseline (or claiming this release's provisional version slot, which rides the same predicate via the version-slot virtual-path token) invalidates the GO until it is revalidated (verdicts CURRENT / STALE-REVALIDATE / STALE-VOID). This **is** a registered gate-criteria row (`G-PR9`), and it is what makes the GO falsifiable when a sibling claims the slot first;
- the **semantic GO-invalidation check at Stage 12 (Phase A.5)** — the same predicate runs once more immediately before the merge, halting even when `git merge` reports no textual conflict, as the last check before the tag is claimed.

The structural-contention substrate underneath these is the Stage-3 serialization predicate (two in-flight releases whose edit-set and surface intersect are a serialization point — one merges, the other re-baselines); the version slot is folded into that same predicate as a virtual-path token, so version contention is detected by the existing machinery with no new gate logic. This doctrine states the rule; those checks are the enforcement surface.

**Re-versioning up is the expected runtime behavior, not an error.** When a concurrent release claims the lower number first, the in-flight release **re-versions up at Stage 12**: it re-verifies the next number is free, then claims it (forward-only, never down, never over an existing claim, per § 5.3). This is routine, not exceptional — the release log records it happening across many releases, where a release moved up one or more minors because its intended slot was taken before it merged. A release never ships version-less to dodge a collision; it claims the next free slot. The operator-facing procedure for the residual post-tag case — an orphaned tag or ledger entry left by a collision — is the **post-tag re-version recovery doctrine** (a sibling slice in this same capability), which this subsection states the rule for inline and defers the recovery steps to.

**Worked example — two milestones shipping in parallel.** Two releases ran the pipeline concurrently with provisional numbers in the same band. The first to merge claimed its tag at its merge time; the second, finding its intended number now claimed, re-verified the next free number and claimed that one at its later merge time. Different merge times produced different tag times and different final numbers — the later-merging release shipped the higher number precisely because it merged later, not because it was planned that way. The release log carries real instances of exactly this shape (a release re-versioning up one or more minors when a sibling claimed its intended slot first). This is ship-order = merge-order in practice: the slot follows the tag, and the tag follows the merge.

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
| Provides input to Scan dimensions (composition-shape, slice-coherence) | Defines the scan's dimensions; composition-coherence may be one |

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

### 11.10 Numbering convention ⊥ skill version field — [`version-field-semantics.md`](../../../core/standards/version-field-semantics.md)

| This doctrine § 5 | version-field-semantics.md |
|---|---|
| Allocates the milestone's `v<MAJOR>.<MINOR>` slot (next-free-at-claim) and states why numeric order is not ship order | Defines the `version:` frontmatter field in every PMO SKILL.md — the release tag a skill was validated against |
| Owns milestone *slot allocation* (§ 5.1) and the chronological caveat (§ 5.2) | Owns the skill-version *marker*; carries a thin caveat pointing back here |

**Boundary:** two distinct conventions over the same `vX.Y` string — this doctrine owns how a milestone's number is *allocated*; version-field-semantics owns what a skill's `version:` field *means*. A skill's `version:` records the platform release tag it was validated against, not a chronological ordinal; the allocation and ship-order semantics behind that tag live here. The runtime parallel-release sequencing that makes merge order the ordering authority is owned by the Sequence Rules (§ 9, extended by the forthcoming parallel-release semantics subsection), not by either of these two surfaces.

## 12. Backlog-Retention Guardrails

§ 3 decides what **enters** a milestone. This section constrains the opposite move — a recommendation to **remove** work from the backlog: to prune an issue, retire a queued milestone, or declare a body of planned work dead. The doctrine already emits recommendations of that kind (§ 3 Step 4 outputs *retirement candidates*; § 3 Step 5 outputs a size disposition that can read "too big, split or cut") and previously carried no restraint on them. These four are that restraint.

They are stated as prohibitions because the failure they prevent is an over-eager one: an agent asked to "clean up the backlog" reaches for the nearest sizing heuristic, finds a queue of not-yet-started milestones, and recommends killing planned work as bloat.

> **Two same-vocabulary neighbours — read before grepping.** Both words in this section's title are already in use elsewhere in the corpus for different concepts. The compound name is therefore load-bearing, and **neither neighbour is a precedent for it**.
>
> - **"Backlog hygiene"** — [`stage-02-triage.md`](../pipeline/stage-02-triage.md) Phase A6.5 **Pattern (1)** is a *per-issue detector* (stale issues, orphaned dependencies, conflicting scope) that surfaces candidates for the operator. This section is a *judgment restraint* on what may be concluded about them at the population level. The detector finds candidates; these guardrails govern what may be recommended.
> - **"Retention"** — [`RECORDS_POLICY.md`](../../../core/governance/RECORDS_POLICY.md) § Retention Schedule uses the bare word for a records **preservation floor**: the minimum period a record is kept before it becomes *eligible* for disposition, keyed by record type, where the disposition is never destruction. That is a period, not a restraint on a recommendation. **Backlog-retention** here means keeping *planned work* on the backlog against an unevidenced case for removing it — a different subject with a different test.

### BRG-1 — Do not size-judge the product backlog against a delivery-team backlog model

The platform's own improvement backlog is a **multi-role product backlog**: it carries work for every role the platform models, across enabling and capability tracks, on a sequence-not-time horizon. The **delivery-team** backlog-health model — its item-count alarm threshold, its months-of-throughput sizing target, and its age-based re-triage and kill thresholds ([`backlog-health.md`](../../../operations/skills/delivery-engine/references/backlog-health.md) § 1.1 and § 3) — is calibrated for one team's committed delivery queue and is **not** a yardstick for this backlog.

Do not import an item-count target from any delivery-team backlog model, in-corpus or external, and do not present one as evidence that this backlog is oversized. A backlog is too large when its *sequence* no longer resolves — when nothing can be shown to depend on an item and no horizon places it — not when its cardinality exceeds a number borrowed from a different altitude.

This is the retention-side sibling of two boundaries the platform already draws: the capacity-altitude boundary at § 3 Step 5 (release-bundle capacity ≠ delivery-team capacity), and the intake-priority altitude boundary in [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) § Gate 2 (pipeline-intake priority ≠ delivery-engine sequencing).

### BRG-2 — Do not label a queued milestone "aspirational" or "zombie"

A milestone that is bundled and sequenced but not yet started is **planned work awaiting its turn**. Its position in the queue is a scheduling fact, not evidence of abandonment.

Do not apply "aspirational", "zombie", "dead", "wishlist", or an equivalent judgment token to a milestone on the basis of queue position, age, or track. A foundation-first sequence deliberately places enabling work ahead of the capability work that depends on it, so an early-track milestone that has not yet shipped is **on plan, not stalled** — and reading the sequence as neglect inverts its meaning.

**"Zombie" is not a free label — the corpus already spends it twice, and neither use licenses this one.** It names an *unreferenced generated artifact* past its staleness window ([`lifecycle-states.md`](../../../operations/skills/artifact-generator/references/lifecycle-states.md)), and it names a *backlog work item* held past an aging threshold ([`backlog-health.md`](../../../operations/skills/delivery-engine/references/backlog-health.md) § 7, the "Backlog as graveyard" anti-pattern, whose remedy prescribes recurring zombie hunts against explicit age thresholds). The second sense is the nearer one and the one an agent is likeliest to reach for — and it is still not applicable here, because it is scoped to a delivery-team queue and keyed on *age*: the yardstick BRG-1 rules out and the evidence BRG-3 rules out.

### BRG-3 — Recommend closure only on concrete evidence, never on age

A recommendation to close, retire, or de-scope a milestone or an issue must cite evidence that the work is **no longer needed** or **already delivered**: the shipped surface, the superseding item, the retired dependency, the changed decision, the removed consumer.

Elapsed time since creation, time since last update, and position in the queue are **not** that evidence. They are signals to go and look — never findings on their own. State the evidence, name the surface it was read from, and carry an evidence-quality label. A closure recommendation whose only support is age is not a finding, and is rejected as one.

### BRG-4 — Do not delete or rewrite retired-milestone history

A milestone that has been retired, superseded, renumbered, emptied, or absorbed **keeps its record**. Do not delete its description, rewrite its scope to match what actually shipped, or renumber it to close a gap in the sequence. The retired record is how a later reader reconstructs what was planned, what changed, and why — and § 5.3 already forbids retroactive milestone renaming for the same reason.

Amend by **appending**: an amendment-log entry naming what changed and when. Never by overwriting. This is the milestone-surface application of the append-not-overwrite discipline the platform applies to ADRs (superseded, never edited) and to roadmap findings (permanent, status-transitioned).

### Who reads these

Any agent producing a **removal recommendation** over the platform's own backlog: Stage-2 Triage (when Phase A6.5 Pattern (1) surfaces a candidate), Stage-3 Bundle (§ 3 Step 4 retirement candidates), roadmap re-baseline and drift-audit passes, milestone-readiness assessment, and any platform-health audit that reports on backlog state. The guardrails are **positive guidance**, not gate enforcement — consistent with § 2, which assigns enforcement to the sibling gate specs.

## 13. Cross-Reference

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

## 14. Version History

| Version | Date | Change | Authority |
|---|---|---|---|
| Initial | 2026-05-25 | Initial. Promotes 7-step vertical capability slice methodology from operator memory to K1 codified-knowledge corpus. Frame: F1 SAFe Feature-Slicing + Vertical Slice (current default per platform config per operator clarification 2026-05-24; frame-pluggability discipline). Cutover REFLEXIVE-EXEMPT-ALL — the introducing release itself is exempt. | Stage 5 D-decisions; operator-CONFIRMED at Collective Review 2026-05-25 |
| v11.28 | 2026-06-17 | Adds the § 3 Step 5 Risk-Weighting (Release-Class capacity multiplier) sub-block — `effective_pts = round_half_up(sum(member_pts) * class_weight)`, weights cited by role from `[bundling].release_class_capacity_weights` (single numeric home), round-half-up pinned at this definitional home, delivery-team-capacity boundary clause, `[CALIBRATE-AFTER-3]` recalibration linkage to the RELEASE_LOG velocity instrument, and an enforcement-layer reference to the decomposition-review gate family. Consolidates the sizing guidance: names the point-band as the governing capacity ceiling and the Stage-3 "5-8 issues" item-count as a secondary readability heuristic. Additive only; no existing rule restated. | Stage 5 Solutioning design + scope-lock; Stage 6 Engineering (release v2.02, milestone 61-bundling-capacity-and-sizing-gates) |
| — | 2026-06-21 | Hardens § 5 milestone numbering semantics: promotes the previously-parenthetical chronological rule to named sub-sections — § 5.1 Slot allocation (next-free-within-active-major, intent-to-bump in pipeline, claimed atomically at merge, cross-referencing the founding version-claim-determinism ADR + the Release Protocol allocation rule for the mechanism), § 5.2 Numeric order is not ship order (a version number is not a chronological ordinal; ship order = merge order = tag order; runtime sequencing owned by § 9), § 5.3 Reservation and renumbering (no early reservation; forward-only re-version-up on collision; no retroactive renaming). Reconciles the stale multi-track gloss in the `<MAJOR>` row + § 5.4 Major-version semantics to a single active track (major = work-mode re-baseline; multi-track is permitted-future, not active). Adds § 11.10 boundary row (numbering convention ⊥ skill `version:` field). Cross-references the forthcoming parallel-release semantics subsection (§ 9) by name. Additive + one normative→informative gloss reconciliation; no existing rule restated. | Stage 5 Solutioning + Collective Review scope-lock (numbering doctrine home prevails); Stage 6 Engineering (milestone release-version-claim-determinism) |
| — | 2026-06-21 | Adds § 9.1 Parallel-release semantics — the runtime counterpart to the § 5.2 chronological caveat: the version number is a slot identifier not a sequence ordinal; ship order = merge order = tag order with the held-but-unclaimed window eliminated by claim-at-merge; two concurrent releases cannot both hold a number (atomic compare-and-swap on the host version ref, recompute-and-retry-up on collision, never overwrite); a declared cross-milestone dependency edge (G3-07) is the single hard constraint overriding free merge order; sibling-claims-first detection is by reference to the shipped Stage-9 + Stage-12 checks with no new gate (carrying inline the caveat that the Stage-9 Phase A6.5 / `G-PR8` divergence verdict is named in Release-Protocol prose but is not yet a registered gate-criteria row, whereas the Stage-9 `G-PR9` baseline-currency check is a registered row); re-versioning up at Stage 12 is the expected runtime behavior, with the post-tag recovery procedure deferred to the post-tag re-version recovery doctrine; plus a worked parallel-ship example. References the host-agnostic repository-host adapter atomic-claim operation + the founding version-claim-determinism ADR for the mechanism. Additive; no existing rule restated; no new gate added. | Stage 5 Solutioning + adversarial review + Collective Review scope-lock (§ 9 home prevails; cite live gates, add none); Stage 6 Engineering (milestone release-version-claim-determinism) |
| — | 2026-08-03 | Adds § 12 Backlog-Retention Guardrails (BRG-1..BRG-4) — the restraints on a recommendation to REMOVE work from the backlog, complementing § 3's what-enters method: no delivery-team backlog model as a sizing yardstick for the multi-role product backlog (with the altitude boundary stated against the delivery-engine backlog-health reference § 1.1 + § 3); no "aspirational"/"zombie" label on a queued milestone, with both live in-corpus senses of *zombie* named and each shown not to license the label; concrete evidence (never age) required for a closure recommendation; retired-milestone history amended by appending, never deleted or rewritten. Carries a two-neighbour disambiguation clause covering both same-vocabulary collisions — the Stage-2 Triage A6.5 Pattern (1) "Backlog hygiene" per-issue detector, and the `RECORDS_POLICY.md` § Retention Schedule preservation-floor sense of *retention*. Renumbers Cross-Reference § 12 → § 13 and Version History § 13 → § 14 (§ 10 and § 11 unchanged — `§ 11.8` is externally cited); widens the frontmatter `purpose` by one clause, adds two consumers, and reconciles a `last-updated` field three prior amendments left stale. Additive; no existing rule restated; no gate added. | Stage 5 Solutioning design + Collective Review scope-lock (Tier-1 [ADJUST] amendments from the adversarial design review); Stage 6 Engineering (milestone governance-hardening) |
