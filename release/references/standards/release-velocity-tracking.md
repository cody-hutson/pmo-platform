---
title: Release Velocity Tracking
purpose: K1 codified-knowledge standard defining how release velocity (planned-vs-delivered story points, files-changed, and the realized feature/debt/slack allocation mix) is measured, formatted, surfaced in RELEASE_LOG.md, and baselined for the PMO platform
type: standard
parallel_to: deployment-cycle-time.md (the sibling visible-H4 measurement field; cycle-time measures GO-to-deploy latency, velocity measures release-bundle throughput — disjoint signals, co-resident block), decision-outcome-tracking.md (the additive-H4-field placement precedent this follows), bundle-composition-doctrine.md (owns the point scale + the round-half-up mode + the release-class capacity weights this instrument feeds), gate-evaluation-spec.md (the Layer 3 calibration surface providing the N=3 trigger)
reversibility: CHEAP (forward-only additive H4 field; pre-cutover releases lack the field and consumers treat as absent; the whole instrument reverts with one commit — no master-table schema change)
consumers: "release/governance/release-process.md Stage 13 § velocity-tracking convention; release/references/pipeline/stage-13-close.md Phase B (capture surface); release/references/pipeline/stage-12-execute.md Phase B5 (forward-note that velocity lands at Stage 13); release/references/how-to/hub-spoke-bridge.md Stage 13 chip pattern (spoke RELEASE_LOG-edit instruction); bundle-composition-doctrine.md § 3 Step 5 release-class capacity-weight recalibration (the heuristic half); release-planner Mode B (capacity calibration); automated-closeout.sh (RELEASE_LOG row-parser — invariant against this H4 field)"
version: v2.02
---

<!-- reference-durability: allow-version-ref -->
# Release Velocity Tracking

## 1. Purpose

Release velocity = the release pipeline's own throughput per release — how the platform builds itself. Three signals plus a join key:

1. **planned-vs-delivered story points** — the bundle scope committed at Stage 3 (planned) against the membership that actually shipped at Stage 13 (delivered), plus the delivered/planned ratio.
2. **files-changed** — the whole-release count of files the release PR touched.
3. **allocation actuals** — the realized feature / debt / protocol-slack point split of the delivered membership.
4. **Release Class** (the join key) — carried into the field so the recalibration consumer can group delivered-vs-planned BY class without re-deriving it.

Prior to this standard, none of the three velocity signals existed as a machine-readable field. files-changed appeared only as inline narrative (`(+N/−M)`) inside the `**Files deployed:**` prose; planned-vs-delivered and the allocation mix were recorded nowhere — the 60/20/20 allocation *target* at Stage 3 Bundle had no measured *realized* counterpart. This standard codifies the field schema, the units, the RELEASE_LOG surfacing convention, the N=3 baseline trigger, and the label→work-class map so the velocity signals are produced consistently per release and consumed deterministically by the release-class capacity-weight recalibration (the heuristic half of the calibration loop; see § 9).

**Scope:** release-bundle throughput, captured at Stage 13 close per release, derived from mechanical sources — `size:*` labels over the milestone membership, `git diff --shortstat` over the release range, the issue `type:`/`cluster:` labels, and the milestone's declared Release Class. Content-only / governance-only releases that carry no `size:*`-labelled membership record `Velocity: N/A` and are excluded from the calibration ratio.

**Out of scope:** managed-delivery-team capacity (available-hours, focus-factor, effective-capacity, the team-standing 60/20/20 split, the communication-overhead ceiling, onboarding ramp-down) — owned by the delivery-engine capacity model and estimation standards at the project-delivery altitude (see § 8 boundary clause); per-issue velocity (the field is release-level only); deployment cycle time (GO-to-deploy latency — the disjoint sibling field owned by the deployment-cycle-time standard).

## 2. What is measured

The `**Velocity:**` field carries five sub-signals plus a producing-tool marker:

| Sub-signal | Source | Format | Notes |
|---|---|---|---|
| **planned pts** | Sum of `size:*` → points over the **delivered** set PLUS every member dispositioned out of the bundle: those still on the milestone carrying a terminal not-delivered `status:` label, AND those `stage-13-close.md` Phase A2 removed from the milestone on the way out, recovered from their `demilestoned` timeline events | integer `<P> pts` | "Planned" = the bundle scope committed at Stage 3. Uses the EXISTING point scale (§ 3.1), not a new one. **The Phase-A2 recovery is not optional bookkeeping.** Phase A2 applies `status: deferred` *and then removes the milestone*, so a `gh issue list --milestone` read cannot see the deferred member at all — planned would silently shrink to equal delivered and the ratio would read `1.00` on every governed close, feeding a constant into the § 6 recalibration. **Known bound:** a member demilestoned at Phase A2 and later re-bundled elsewhere loses its terminal label and is not recovered, so planned may under-report; it never over-reports. Closing that gap needs the Stage-3 membership snapshot the platform does not yet take. |
| **delivered pts** | Sum of `size:*` → points over the milestone members that do **not** carry a terminal not-delivered `status:` label (`status: deferred`, `status: rejected`) | integer `<D> pts` | "Delivered" = membership that actually shipped. **The predicate reads labels, never issue close state.** Close state is bimodal on something no one controls: when the release PR's close keywords resolve at Stage 12 the members are already closed, and when they do not, the close-out's own remedy runs twenty phases after the measurement — booking `delivered 0 pts` on a release that shipped everything. Seven hot-ledger rows recorded exactly that before it was caught. Labels do not move between a `--no-merge` run, a dry run and an `--apply` run, which is what makes the figure order-independent. **The exclusion set is OPEN**, not closed: `label-taxonomy.md § Status Labels` calls its enumeration illustrative and defines the live set as the packs' union, so a deployment whose pack contributes another terminal status must register it in the producing tool's exclusion constant or those members count as delivered. |
| **ratio** | `delivered / planned`, 2-decimal, **round-half-up** (§ 3.2) | `(<D/P>)` | The signal the release-class capacity-weight recalibration reads per Release Class. |
| **files-changed** | `git diff --shortstat <merge-base>..<merge-SHA>` files-touched count for the release PR merge | integer `<F>` | Promotes the inline `(+N/−M)` narrative to a structured field. Whole-release count (not per-skill). `N/A` when the merge SHA is unknown at capture time. |
| **allocation** | feature / debt / protocol-slack point split over the delivered membership, keyed off issue `type:`/`cluster:` labels per the § 4 map | `<feat>/<debt>/<slack> pts` | The **realized** counterpart to the 60/20/20 *target* at Stage 3 Bundle. "protocol-slack" is the protocol/process-improvement third of the 60/20/20 mix. The three buckets partition delivered points (they always sum to delivered). |
| **class** | the milestone's declared `## Release Class` H2 (the gate that guarantees the field is present) | one of `routine` / `novel` / `cross-cutting` / `hotfix` | Carried INTO the field so the recalibration consumer can group delivered-vs-planned BY class without re-deriving it. This is the join key between the measurement half (this instrument) and the heuristic half (the capacity weights). |
| **mechanism** | literal `compute-release-velocity.sh` | suffix | Discoverability marker mirroring the cycle-time field's `mechanism:` convention; names the producing tool. |

## 3. Unit / Format

### 3.1 Point scale (reused, not redefined)

Story points use the platform's existing scale — `XS=1 / S=2 / M=4 / L=8 / XL=16` — defined at the bundle size-check (`bundle-composition-doctrine.md § 3 Step 5`). This standard does NOT redefine the scale; it reuses it verbatim so the planned side (Stage 3 bundle) and the delivered side are an apples-to-apples ratio. A `size:*` label outside the closed `XS/S/M/L/XL` set is a source-integrity violation (the producing tool exits non-zero; see § 7 FM3).

### 3.2 Rounding mode (round-half-up, taken by reference)

The delivered/planned ratio rounds **round-half-up** at the second decimal: a `.5` result rounds away from zero (e.g. `0.125 → 0.13`), NOT banker's round-half-to-even. This mode is NOT defined here — it is taken **by reference** from the single definitional home at `bundle-composition-doctrine.md § 3 Step 5 Risk-Weighting`, which pins round-half-up for `effective_pts` and directs every consumer — including "any velocity-instrument field that records the value" — to take the mode by reference and never re-derive it, so a producer and an enforcer cannot disagree at a half-integer boundary. The producing tool implements that one canonical mode; this standard cites it.

### 3.3 Field name + RELEASE_LOG surface

- **Field name:** `**Velocity:**` — TitleCase-bold, matching the established visible-H4 sibling-field convention (`**Cycle-Time:**`, `**Result:**`, `**Outcome:**`, `**Timestamp:**`).
- **Placement:** inside the visible-H4 `#### Deployment Log v<X.Y>` block, as a sibling structured field — NOT a main-table column. The master-table schema (`| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |`) is untouched. This follows the additive-H4-field placement precedent the platform has already validated twice (the cycle-time field and the outcome field both landed this way; a main-table column was explicitly rejected as high-cost main-table churn).
- **Field position:** immediately AFTER `**Cycle-Time:**`. Both are machine-computed instrument fields; keeping them adjacent and before the `**Result:**`/`**Outcome:**` prose-and-enum fields matches the "instruments first, narrative and verdict last" reading order. The extended field-ordering convention is `… Timestamp → Cycle-Time → Velocity → Result → Outcome → Outcome rationale`.

**Default emit (non-N/A):**

```markdown
**Velocity:** planned <P> pts / delivered <D> pts (<ratio>); files-changed <F>; allocation <feat>/<debt>/<slack> pts (feature/debt/protocol-slack); class <release-class>; mechanism: compute-release-velocity.sh
```

Worked example (a release whose 24 planned points all shipped, 9 files touched, a debt+slack mix, novel class):

```markdown
**Velocity:** planned 24 pts / delivered 24 pts (1.00); files-changed 9; allocation 0/20/4 pts (feature/debt/protocol-slack); class novel; mechanism: compute-release-velocity.sh
```

**N/A emit (content-only release with no sized membership):**

```markdown
**Velocity:** N/A — no size:* labels on milestone membership (cannot derive points); files-changed <F> recorded; class <release-class> (excluded from calibration ratio)
```

Emit mechanism: the Stage 13 spoke invokes `compute-release-velocity.sh <version> --milestone <N> --merge-sha <SHA>` at the Stage 13 chore PR and embeds the returned value into the visible-H4 block. Per the chore-PR convention the field lands on main via the Stage 13 chore PR, never direct-to-main.

### 3.4 Machine-readable contract — what is NORMATIVE and what is INCIDENTAL

The default emit above is the **preferred rendering**. It is not, line for line, the machine contract. The distinction is load-bearing in both directions: a producer that satisfies only the prose renders a field no consumer can read, and a gate that asserts the prose verbatim reds rows that are entirely correct.

**The normative core is the grammar the shipped consumer actually parses.** That consumer is the velocity accessor in `core/skills/finops-usage-extractor/scripts/estimate-usage.sh`, which reads the `#### Deployment Log <version>` heading and the FIRST `**Velocity:**` line beneath it, and requires BOTH an unbolded `planned <N> pts` AND a `class <release-class>` to key the row. A line it cannot parse yields no entry at all — the release is excluded as *unkeyable*, silently, with no diagnostic anywhere. The contract is therefore stated against that grammar rather than re-derived, so a producer and a gate cannot encode the same token shape twice and drift apart.

| # | Element | Status | Why |
|---|---|---|---|
| **N1** | The field line begins `**Velocity:**` at column 0, inside the `#### Deployment Log <version>` block, bounded by the next `#### ` heading or EOF | **NORMATIVE** | The consumer scopes by block and anchors on the line prefix. A field outside its block belongs to whichever release the parser was last inside. |
| **N2** | It is the FIRST `**Velocity:**` line in the block | **NORMATIVE** | The consumer takes the first and ignores the rest. A second line is dead text that reads as authoritative. |
| **N3** | A non-N/A field carries an unbolded `planned <N> pts` **and** a `class <release-class>` (lowercase, hyphens allowed) | **NORMATIVE** | Both are required to key the row. Either alone yields no entry. |
| **N4** | An N/A field begins `**Velocity:** N/A` | **NORMATIVE** | The explicit-N/A discipline of § 5. Distinguishes "no sized membership" from "nobody wrote the field". |
| **N5** | **No emphasis inside the numerals.** `planned 28 pts`, never `planned **28** pts` | **NORMATIVE** | The consumer matches `planned <digits> pts` as an unbroken token. Bolding the numeral splits it, and the row is dropped as unkeyable — while still reading perfectly to a human, which is exactly why this failed silently in the corpus before it was stated. The producing tool never bolds; the risk is a hand-authored or hand-edited field. |
| **N6** | The field's position is immediately after `**Cycle-Time:**` (§ 3.3), or immediately after the block heading when the block carries no `**Cycle-Time:**` field | **NORMATIVE for placement, not for parsing** | The consumer does not check position; the reading-order convention does. Stated so a producer has one rule rather than a choice. |
| **I1** | The `mechanism:` marker, in any form — `; mechanism: compute-release-velocity.sh`, `(mechanism: \`compute-release-velocity.sh <args>\`)`, or absent | **INCIDENTAL** | Discoverability prose. No consumer reads it, and no form dominates the corpus — measured over every `**Velocity:**` line in `RELEASE_LOG.md` plus its `RELEASE_LOG_ARCHIVE-*.md` segments, **neither marker form reaches a third of the population, and the largest single bucket is the rows carrying no marker at all**. A gate asserting any one form verbatim would therefore red the majority of correct rows. |
| **I2** | `files-changed <F>` | **INCIDENTAL** | Legitimately `N/A` whenever the merge SHA is unknown at capture time. |
| **I3** | `allocation <f>/<d>/<s> pts (feature/debt/protocol-slack)` | **INCIDENTAL** | Recorded for the recalibration consumer, which reads the tool's `--json` output rather than the prose field. |
| **I4** | The trailing narrative tail (a parenthetical reason on an N/A field, a note on the ratio) | **INCIDENTAL** | Human context. It must not interrupt an N3 token, which N5 already forbids. |

**How to use this split.** A producer emits the preferred rendering and self-asserts N1–N5 on the composed line *before* writing — an emit-time rejection is a loud failure, whereas an unparseable field is a permanent silent one. A gate asserts N1–N5 and nothing below the line; asserting I1–I4 measures fashion, not correctness. When the preferred rendering and the normative core disagree for a given row, the normative core governs and the row is correct.

**Basis discipline for any consumer or gate.** Deployment-Log narrative older than the release log's hot window is relocated into sibling `RELEASE_LOG_ARCHIVE-*.md` segments that keep the same heading and the same field lines. Anything reading the velocity field across releases MUST read the ledger **plus** those segments — the shipped consumer does — or its population shrinks silently every time the archival chore runs. Correspondingly, a field written for a release whose block body has been relocated belongs in the **segment that holds that block's `**Result:**` line**, not in the hot stub: a field in one file and the rest of its record in another satisfies N1–N5 and is still a broken record.

## 4. Allocation work-class map (the one new classification)

The allocation actuals require mapping each delivered issue's `type:`/`cluster:` labels onto the three work-classes the 60/20/20 mix names. This map is the single genuinely-new classification this standard introduces; it is grounded in the category-label and cluster-label sets defined at the platform label taxonomy (`core/specs/label-taxonomy.md`).

| Work-class | Resolves from (any of these labels) | 60/20/20 role |
|---|---|---|
| **feature** | `enhancement`, `type:feature`, `feature` | the ~60% feature third |
| **protocol-slack** | `protocol`, `cluster: process-protocol`, `routing-rules`, `tracker-schema` | the ~20% protocol/process third |
| **debt** | `bug`, `structure`, `skill-update`, `documentation`, `cluster: architecture`, `cluster: tech-debt` | the ~20% debt third |

**Resolution precedence (a multi-labelled issue resolves to exactly one class):** an explicit **feature** signal wins; then a **protocol-slack** signal; then a **debt** signal. **Default = debt** — an un-feature, un-protocol delivered issue is treated as debt-paydown, never silently dropped, so the three buckets always partition the delivered points (they sum to delivered exactly). This default-to-debt rule is conservative (it never inflates the feature third) and keeps the allocation reproducible rather than ad-hoc.

## 5. N/A semantics

A release whose milestone membership carries **zero** `size:*` labels records `**Velocity:** N/A` — points cannot be derived. The release is excluded from the calibration ratio population (§ 6). A `files-changed` count is still recorded in the N/A field when the merge SHA is available, and the Release Class is still carried — only the points-derived signals collapse to N/A.

**Explicit-N/A discipline:** `Velocity: N/A` is not blank-fill. The field is present on every post-cutover visible-H4 Deployment Log block; the value is `N/A` (with parenthetical reason) when no sized membership exists. A row either carries the full field (post-cutover, sized) or carries `N/A` (post-cutover, unsized) or carries no field at all (pre-cutover, grandfathered) — never a partial field.

**Why N/A and not zero:** a content-only release genuinely has no story-point throughput to measure; recording it as `0 pts` would crush the calibration ratio and bias the very weights it feeds (the same synthesized-data-biases-baseline trap the deployment-cycle-time standard names for synthesized timestamps). The N=3 calibration count (§ 6) counts only non-N/A fields, so N/A and grandfathered rows are simply absent from the population, never zero-valued.

## 6. Baseline / calibration trigger

Per the platform calibration discipline (`gate-evaluation-spec.md § Layer 3 Calibration`), velocity data recalibrates the release-class capacity weights only after a minimum population accrues:

| Phase | Trigger | Action |
|---|---|---|
| **Pre-calibration** | Count of non-N/A `**Velocity:**` fields across closed post-cutover releases < 3 | Each release records its velocity field; no recalibration. The shared `[calibration].releases_since_calibration` counter advances per closed release. |
| **Calibration** | Count reaches 3 (N=3) | The per-class delivered-vs-planned ratio + the allocation actuals recalibrate the release-class capacity weights (the heuristic half — see § 9). A Track-A governed change re-sets the seeded defaults from the measured actuals. |
| **Post-calibration** | Count ≥ 3 | Subsequent releases continue recording the field; the weights are re-reviewed against accumulated actuals per the same `[CALIBRATE-AFTER-3]` cadence. |

**N=3 rationale:** aligns with the platform-wide calibration threshold (`gate-evaluation-spec.md § Layer 3`) and the `[CALIBRATE-AFTER-3]` precedent recorded at the bundle-composition doctrine. Selecting N=3 keeps the velocity instrument within the established calibration discipline rather than inventing a private threshold.

**Shared counter:** the velocity instrument and the release-class capacity weights advance the **same** `[calibration].releases_since_calibration` counter in `platform-config.toml.template`. Neither half defines a private counter — they are the measurement half and the heuristic half of one calibration loop (§ 9).

## 7. Computation tool

Reference implementation: `release/tools/compute-release-velocity.sh`.

**Form factor:** a thin wrapper mirroring the `compute-cycle-time.sh` form factor and exit-code contract. It is stdlib-only (PATH pinned to system tools per the bypass-mode-readiness portability tier), takes `<version> --milestone <N>`, and emits the field value sourcing (a) `size:*`-derived points from the milestone membership via `gh` issue labels, (b) files-changed via `git diff --shortstat <merge-base>..<merge-SHA>`, (c) the declared Release Class from the milestone description, (d) the allocation split from `type:`/`cluster:` labels via the § 4 map. It ships a `--self-test` (point scale, round-half-up, work-class precedence, allocation-partitions-delivered invariant, and the delivery predicate — both directions, spaced-label match fidelity, exclusion-constant shape, close-state independence carrying the pre-fix close-state rule as a firing sensitivity arm, non-degeneracy, and the allocation partition across an exclusion) and a `--json` detail mode.

**Cost note.** Recovering the Phase-A2 set costs one issue-events read per candidate, where candidates are the repo's terminal-status issues that carry a `size:*` label and are not already on the milestone — tens of issues, not a repo scan. The bound is the terminal-status population, so it does not grow with repository size.

**CLI:**

```bash
./compute-release-velocity.sh <version> --milestone <N> --merge-sha <SHA>   # the **Velocity:** field value
./compute-release-velocity.sh <version> --milestone <N> --json             # JSON of all signals
./compute-release-velocity.sh --self-test                                  # validate logic, no network
```

**Exit codes:**
- `0` — success (a release may legitimately produce N/A — content-only release with no sized membership, or files-changed unknown at call time)
- `1` — invalid args / required input missing / `gh` unavailable when needed
- `2` — malformed source (a `size:` label outside the closed `XS..XL` set, or a milestone that does not resolve — source-integrity violation; escalate), **or an implausible measurement**: a non-zero `planned` against `delivered 0` over a non-empty sized membership. The tool refuses to emit that reading rather than writing it into a permanent ledger row. The guard runs *after* the unsized-membership N/A return, so a legitimate content-only release still records `N/A` at exit 0 and never trips it.

**Consumer obligation on exit 2.** A caller must NOT fold exit 2 into its "tool unavailable" degrade. Exit 1 means *we could not measure* and correctly degrades to the explicit `N/A` field; exit 2 means *we measured and the result is not fit to record*, and must surface as a failure. Recording a refusal as an `N/A` converts a loud stop into a clean-parsing permanent row — the same class of trade this instrument's own defect history is made of. `automated-closeout.sh` phase 6.6 implements the split, non-blocking under `--dry-run` and fatal at `--apply`.

**Manual-fill fallback:** if the tool cannot run at capture time (e.g. `gh` unavailable in the close worktree), the Stage 13 spoke MAY compute the three numbers by hand from the membership and embed them in the field — exactly as the cycle-time field degraded gracefully to manual `N/A` during its own instrumentation gap. The field and the convention bind either way.

## 8. Boundary statement (release-pipeline velocity ≠ delivery-team capacity)

RELEASE_LOG velocity (this instrument) measures the **release pipeline's own throughput** — how the platform builds itself: story points planned-vs-delivered per release, files changed, and the realized feature/debt/slack mix of a release bundle. It is **NOT** a managed-delivery-team capacity model.

Delivery-team capacity — available-hours → effective capacity, the communication-overhead ceiling, onboarding ramp-down, the **team-standing** 60/20/20 allocation, focus-factor — is owned by `operations/skills/delivery-engine/references/capacity-model.md` and `operations/skills/delivery-engine/references/estimation-standards.md` at the project-delivery altitude. The two never share a value; this instrument does NOT read focus-factor, effective-capacity, or sprint-velocity history.

The two `60/20/20` allocations are disjoint concepts that share digits, already disambiguated in-corpus: the capacity-model standard's own disambiguation note distinguishes the **team-standing** 60/20/20 (its concern) from the **release-bundle** 60/20/20 used at Stage 3 Bundle ("Different concept, same digits"). This instrument's `allocation` signal measures the **release-bundle** mix — the same side of that boundary the release-class capacity weights operate on — not the team-standing split. Zero duplication: this instrument introduces structured *records* of release-pipeline throughput; the capacity model models *human-team* capacity.

## 9. Recalibration linkage (the heuristic half)

This standard is the **measurement half** of one calibration loop; the **heuristic half** is the release-class capacity-weight recalibration documented at `bundle-composition-doctrine.md § 3 Step 5 Recalibration`. That sub-block already names this instrument as its measurement source: after ≥3 releases tracked in the RELEASE_LOG velocity instrument (planned-vs-delivered, files-changed, allocation actuals), the per-class delivered-vs-planned ratio recalibrates the `release_class_capacity_weights` — a class whose releases systematically over- or under-run its band signals a weight adjustment — advancing the shared `[calibration].releases_since_calibration` counter.

What this instrument's schema guarantees for the consumer (and does):
1. **`class` is in the field** — the consumer groups delivered-vs-planned BY Release Class without re-deriving it (this is why `class` is a first-class sub-signal).
2. **`ratio` is machine-readable** — the consumer reads the per-class over/under-run directly.
3. **`allocation actuals` are recorded** — feeding whether the 60/20/20 *target* at Stage 3 Bundle held in practice, making the aspirational target measurable for the first time.
4. **Shared counter** — both halves advance the SAME `[calibration].releases_since_calibration`; neither defines a private counter.

The recalibration consumer (the release-class capacity weights) is cited **by role**, not by its threshold values — this standard does not restate the weight numbers (parameterize-over-hardcode; the config field is the single numeric home). The recalibration also informs the Stage 3 capacity heuristics (the A4 capacity-heuristic surface) and the `[CALIBRATE-AFTER-3]` review of the point-band thresholds. The two halves are a soft dependency, not a hard block: this instrument begins accumulating velocity data immediately and independently; the heuristic half consumes it after N=3. Neither blocks the other.

## 10. Cutover / grandfather

**GRANDFATHER. No backfill.** Pre-cutover Deployment Log blocks carry **no** `**Velocity:**` field. The field is present **going-forward only**, on releases entering Stage 13 strictly AFTER this field's introducing-release merge SHA. **The introducing release itself is exempt** (reflexive-pipeline-loop discipline — a release shipping the velocity convention does not retroactively self-instrument).

This matches how the two sibling visible-H4 fields grandfathered (the cycle-time field is "Pre-cutover releases: exempt. No backfill"; the outcome field surveyed the pre-cutover blocks and added forward-only). **Why grandfather, not backfill:** the planned-vs-delivered ratio requires the Stage-3-commit membership snapshot AND the Stage-13-closed membership — for closed historical releases the planned-vs-delivered distinction is not reliably reconstructable (issues were re-milestoned and re-versioned across the repository's version lineage), so a backfilled ratio would be synthesized, not measured, biasing the very calibration baseline it feeds. Grandfathering is also the platform's established convention for pre-convention artifacts. The N=3 calibration count (§ 6) counts only non-N/A post-cutover fields, so grandfathered rows are simply absent from the population, never zero-valued.

## 11. Consumers

| Consumer | Role |
|---|---|
| `release/references/pipeline/stage-13-close.md` Phase B | Capture surface — the Stage 13 chore PR embeds the `**Velocity:**` field (via the tool, or manual-fill) in the same commit that transitions the row `DEPLOYED → VERIFIED` and adds `**Outcome:**` |
| `release/references/pipeline/stage-12-execute.md` Phase B5 | Forward-note only — the Stage-12 emit template stays cycle-time-only; the velocity field is appended at Stage 13 (mirrors how the outcome field is a Stage-13 addition to the same block) |
| `release/governance/release-process.md` Stage 13 | Documents the velocity-tracking convention (what is captured, when, how it feeds recalibration) — cites this standard by role; does NOT restate the field anatomy |
| `release/references/how-to/hub-spoke-bridge.md` Stage 13 chip pattern | The Stage-13 spoke's RELEASE_LOG-edit instruction carries the `**Velocity:**` field so spawned spokes emit it |
| `bundle-composition-doctrine.md § 3 Step 5` release-class capacity weights | The heuristic half — consumes the per-class delivered-vs-planned ratio + allocation actuals after N=3 (§ 9) |
| `release-planner` Mode B (durable release plan authoring) | Reads velocity data for capacity calibration once the population establishes |
| `automated-closeout.sh` (RELEASE_LOG row-parser) | Invariant against this field — its row-parsers anchor on master-table rows (`^| v<X.Y>`); the `**Velocity:**` H4 field line is structurally invisible to them (no master-table change; see § 12) |

## 12. Parser-safety invariant

The `**Velocity:**` field lives in the `#### Deployment Log v<X.Y>` visible-H4 block, NOT in the master table. Every RELEASE_LOG row-parser anchors exclusively on master-table rows that begin with a pipe (`^| v<X.Y>`): the close-out tool's row locator and milestone-slug/state extractors operate only on the matched table row, and the corpus-completeness deploy-check enumerates only pipe-leading version rows (reading fields by position). A line beginning `**Velocity:**` does not start with `|`, so it matches none of those anchors and shifts no positional field index. No row-parser change and no deploy-check change is required; the master-table schema is untouched. The sibling `**Cycle-Time:**` and `**Outcome:**` fields have co-resided in the same block across the full release history with all row-parsers green — `**Velocity:**` is the third sibling in a proven-safe container.

## 13. Failure modes

Per `core/standards/failure-mode-standard.md`, every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **INPUT** | Backfilling a synthesized planned-vs-delivered ratio onto a historical release | When a pre-cutover release lacks the `**Velocity:**` field, do NOT reconstruct a planned-vs-delivered ratio from the current closed membership — emit nothing (grandfather) rather than a synthesized value | Convenience pressure: "the release closed cleanly, surely we can compute its velocity from the issues it shipped." But historical issues were re-milestoned and re-versioned across the repository lineage, so the Stage-3-commit planned snapshot is not reliably reconstructable — a synthesized ratio biases the calibration baseline it feeds | § 10 directs forward-only grandfathering; § 5/§ 6 count only non-N/A post-cutover fields; the planned snapshot is taken at the Stage-3 bundle commit, not reconstructed | Principal: leaves the pre-cutover block field-less; the calibration population simply starts at the first post-cutover release. Junior: scrapes the closed membership and back-computes a ratio → injects a synthesized value that drags the per-class baseline and corrupts the weight recalibration |
| FM2 | **PROC** | Counting N/A (content-only) releases as zero in the calibration ratio | When computing the per-class delivered-vs-planned population for recalibration, do NOT count `Velocity: N/A` releases as `0 pts` or `0.00` ratio — they are excluded by § 5 design | "Just average the last N releases' ratios" shortcut: a content-only release has no story-point throughput; treating its N/A as zero crushes the median and biases the weights toward over-estimation | § 5 records N/A explicitly (not blank, not zero); § 6 counts only non-N/A fields; the producing tool emits the N/A field with a parenthetical reason and exit 0 | Principal: filters to non-N/A fields before computing the per-class ratio; documents the exclusion. Junior: takes the last-N rows blindly, includes N/A as zero → the calibration ratio drifts on every content-only release |
| FM3 | **PROC** | Deriving the allocation split from an out-of-set or unmapped label | When a delivered issue carries a `size:` label outside the closed `XS/S/M/L/XL` set, do NOT coerce it to a nearest bucket; and when an issue's labels match no § 4 work-class signal, do NOT drop its points — default it to debt | A size value the scale does not define is a source-integrity problem (a typo or a non-canonical label), not a rounding case; silently coercing it produces a wrong points total. Dropping an unmapped issue's points breaks the partition invariant (the three buckets no longer sum to delivered) | § 3.1 treats an out-of-set size as a tool-level exit-2 source-integrity violation; § 4 makes debt the explicit default so every delivered issue lands in exactly one bucket and the buckets always sum to delivered | Principal: on an out-of-set size, halts and surfaces the label for correction (exit 2); on an unmapped issue, lands it in debt per the default rule. Junior: coerces the odd size to "closest" → wrong total; or skips the unmapped issue → allocation under-counts and the partition invariant silently breaks |
| FM4 | **OUT** | Committing the velocity field direct-to-main, or at Stage 12 | When adding the `**Velocity:**` field, do NOT commit the visible-H4 edit directly to main, and do NOT emit it at Stage 12 — it lands via the Stage 13 chore PR | Direct-to-main is prohibited regardless of edit size (the git-workflow "What NOT To Do" rule does not exempt metadata edits). The field is a Stage-13 field because that is where the *disposition* is final: Phase A2 applies the terminal `status:` labels the delivery predicate reads, so a Stage-12 emit would measure a bundle nobody had dispositioned yet | § 3.3 + § 11 land the field at the Stage 13 chore PR (same commit as the `DEPLOYED → VERIFIED` transition and the outcome field); the Stage-12 emit template stays cycle-time-only with a forward-note | Principal: appends the field in the Stage 13 chore PR, after Phase A2 has dispositioned the membership. Junior: emits velocity at Stage 12, before any deferred member has been marked → records a ratio against an undispositioned bundle that the recalibration then reads as real |
| FM5 | **PROC** | Waiting for member closure before measuring `delivered` | Do NOT try to make `delivered` authoritative by moving the measurement after member close, and do NOT gate it on close state — the field lands in the Stage-13 chore PR, which the sequencing invariant requires to merge BEFORE milestone close, so "after the members close" is a point this field can never be written from | The reading is intuitive and wrong: "delivered means shipped, shipped means closed, so wait for the closes." Three constraints make it unsatisfiable together — the field lands in the chore PR (§ 3.3 / § 11), the chore PR lands before milestone close (`stage-13-close.md` § Phase C sequencing), and member close is at or after that. The historical fix attempts went the other way and produced the seven zero-delivered rows | § 2 defines `delivered` on a LABEL predicate that is invariant across the close, so the measurement is valid at any point after Phase A2 and identical under `--no-merge`, `--dry-run` and `--apply` | Principal: picks evidence that does not move across the close, then measures whenever it is convenient. Junior: chases the ordering — moves the dispatch point, or adds a retry — and ships a field whose value depends on whether GitHub's auto-close happened to fire |

## 14. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Sibling visible-H4 field | `deployment-cycle-time.md` | The disjoint sibling instrument (GO-to-deploy latency); this standard mirrors its section structure, N/A discipline, grandfather policy, and failure-mode shape |
| Field-placement precedent | `decision-outcome-tracking.md` | The additive-H4-field-not-main-table-column precedent + the field-ordering convention this field extends |
| Point scale + rounding mode + recalibration consumer | `bundle-composition-doctrine.md § 3 Step 5` | Owns the `XS=1..XL=16` scale (reused), the round-half-up definitional home (taken by reference), and the release-class capacity weights (the heuristic half) |
| Capacity weights config home | `core/config/platform-config.toml.template` `[bundling].release_class_capacity_weights` + `[calibration].releases_since_calibration` | The single numeric home for the weights + the shared calibration counter |
| Calibration threshold | `gate-evaluation-spec.md § Layer 3 Calibration` | The N=3 rule (inherited, not redefined) |
| Stage 3 allocation target | `release/references/pipeline/stage-03-bundle.md` A4 | The 60/20/20 *target* this instrument's allocation signal measures the *realized* counterpart of |
| Label taxonomy | `core/specs/label-taxonomy.md` | The category-label + cluster-label sets the § 4 work-class map is grounded in |
| Capture surface | `release/references/pipeline/stage-13-close.md` Phase B | Where the field is embedded (Stage 13 chore PR) |
| Stage-12 forward-note | `release/references/pipeline/stage-12-execute.md` Phase B5 | Records that velocity is a Stage-13 field |
| Convention documentation | `release/governance/release-process.md` Stage 13 | Documents what/when/how the field feeds recalibration |
| Chip pattern | `release/references/how-to/hub-spoke-bridge.md` Stage 13 chip | Carries the field into the spawned Stage-13 spoke's instruction |
| Delivery-team boundary | `operations/skills/delivery-engine/references/capacity-model.md` + `estimation-standards.md` | The project-delivery-altitude capacity model this instrument is explicitly NOT (§ 8) |
| Chore-PR convention | `release/governance/release-process.md` Stage 13 § chore-PR mechanism | All RELEASE_LOG velocity edits land via chore PR, never direct-to-main |
| Failure-mode schema | `core/standards/failure-mode-standard.md` | 5-field schema + 5 category tags |
| K1 placement | `core/disciplines/knowledge-architecture.md § 3` | K1 standards live at the standards set |

## Version History

Tracked in git history.
