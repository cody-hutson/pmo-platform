<!-- reference-durability: allow-link -->
---
title: ADR-027 — Release-bundle risk-weighting keys on Release Class, not a new per-issue Tier field
status: Accepted
date: 2026-06-17
release: 61-bundling-capacity-and-sizing-gates (v2.02)
deciders: "[OPERATOR_NAME] (decision adopted at the v2.02 Collective Review scope-lock 2026-06-17)"
tags: [architecture, release-ops, capacity, risk-weighting, release-class, bundle-composition, parameterize-over-hardcode, reversibility]
source_observations:
  - "The bundling capacity card asked for risk-weighted capacity — higher-ceremony/Tier-3 items consuming more capacity than routine items — but the platform has NO per-issue Tier-3 field at bundle altitude: the Autonomy Tier (0-3) is per-action not per-issue, and size:* labels are a complexity axis (XS-XL), not a ceremony axis. The literal 'Tier-3 item' framing points at a field that does not exist."
  - "The shipped axis that DOES express 'higher-ceremony = more coordination cost' at release altitude is the Release Class (routine/novel/cross-cutting/hotfix), declared per-milestone at Stage 3 Phase B3, already described as the axis that declares ceremony weight, gate-enforced by G3-10 (structural-required: the milestone carries a '## Release Class' H2 whose value is one of the four CLOSED enum values), and carrying a shipped per-class Engagement-density ordinal (Light/Standard/Tight/Light)."
  - "bundle-composition-doctrine.md § 3 Step 5 already defines the 15-25 pt target band + XS-XL point scale + a 4-row disposition table + [CALIBRATE-AFTER-3]; the band is positive guidance with no per-milestone-sum enforcer. The risk-weight must compose with that existing band and its disposition table with zero new disposition rows."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-027 — Release-bundle risk-weighting keys on Release Class, not a new per-issue Tier field

## Status

Accepted. The operator adopted the decision at the v2.02 (`61-bundling-capacity-and-sizing-gates`) Collective Review scope-lock on 2026-06-17. This ADR is the committed record of that adopted decision, authored at Stage 6 per the ADR-007 / ADR-028 precedent of Stage-6 ADR authoring. The risk-weight *mechanism* (a multiplier keyed on Release Class) is HIGH-confidence; the seed *magnitudes* are MEDIUM-confidence and `[CALIBRATE-AFTER-3]`.

## Context

A bundling-capacity card asked the platform to express **risk-weighted capacity** — a higher-ceremony or higher-risk release should consume more of a release's capacity budget than a routine release of equal raw size, so the size-check is not blind to coordination/review/rollback cost. The card framed the residual as "Tier-3 items consume more capacity than routine items."

The literal framing has no home at bundle altitude:

- The **Autonomy Tier** (0–3) is a *per-action* authorization classification, not a per-issue durable field.
- `size:*` labels (XS–XL) are a **complexity** axis already consumed by the point scale at `bundle-composition-doctrine.md § 3 Step 5`; they are not a *ceremony* axis.
- No per-issue ceremony/Tier field exists in the backlog that a bundle could sum.

The size-check it must modulate already exists: `§ 3 Step 5` defines a 15–25 pt target band, an XS=1/S=2/M=4/L=8/XL=16 scale, a 4-row disposition table, and a `[CALIBRATE-AFTER-3]` marker. The band is **positive guidance** with no per-milestone enforcer.

The platform DOES carry a shipped, per-milestone, gate-enforced axis that means "more ceremony = more coordination cost" at release altitude: the **Release Class** (`routine` / `novel` / `cross-cutting` / `hotfix`), declared at Stage 3 Phase B3, enforced present by gate **G3-10**, and carrying a shipped per-class **Engagement-density** ordinal (Light / Standard / Tight / Light) and Stage-9 review-depth ordinal (Deep > Standard > Light). The decision is therefore which axis the risk-weight keys on, and what mechanism (multiplier vs additive budget vs per-issue sum) it uses.

## Decision

**Release-bundle risk-weighting keys on the already-shipped Release Class, applied as a multiplier on the raw point sum, evaluated against the existing target band.**

```
effective_pts = round_half_up( sum(member_pts) * class_weight )
```

1. **Axis = Release Class, NOT a new per-issue Tier field.** The weight resolves from the milestone's declared `## Release Class` (G3-10-guaranteed present + enum-valid), falling back to the configured `default_release_class` when absent. No new per-issue field is introduced; no backlog schema change.

2. **Mechanism = multiplier (not additive ceremony budget, not per-issue ceremony-tag sum).** A multiplier is **scale-invariant** — ceremony cost scales proportionally with scope, which an additive constant cannot express (a fixed `+6` is huge at 10 raw pts and trivial at 50). The multiplier feeds the **existing** 4-row disposition table unchanged (one scalar in, one scalar out — zero new rows), and composes with a downstream per-milestone size-bound enforcement gate that asserts a single scalar.

3. **Values are config-resident with a single numeric home.** The per-class weights live in `core/config/platform-config.toml.template [bundling].release_class_capacity_weights` (a TOML inline table), resolved per the 5-rung cascade. `bundle-composition-doctrine.md § 3 Step 5` cites the field **by role and does not restate the numbers** (parameterize-over-hardcode). Default seed set: `routine 1.0` (identity baseline), `novel 1.15`, `cross-cutting 1.3` (progressively heavier ceremony), `hotfix 0.9` (narrow but real corrective risk, weighted lighter than baseline). The ordinal direction replicates the shipped Engagement-density / review-depth ordering; it does not invent a new ranking.

4. **Rounding mode pinned at the definitional home.** `§ 3 Step 5` pins **round-half-up** as the one rounding rule for `effective_pts`; the producer (the size-check), the per-milestone enforcement gate, and any velocity-instrument field that records the value all take the mode by reference, so a producer and an enforcer cannot disagree at a half-integer band edge.

5. **Seeds are `[CALIBRATE-AFTER-3]`.** The magnitudes are MEDIUM-confidence and recalibrate from per-class delivered-vs-planned actuals after ≥3 releases of RELEASE_LOG velocity data, advancing `[calibration].releases_since_calibration`. The mechanism is independent of the exact magnitudes.

## Consequences

### Positive

- **Lowest blast radius:** reuses a shipped, gate-enforced field; one new config key + one doctrine sub-block; no backlog schema change and no new per-issue field to populate.
- **Composes cleanly:** one scalar (`effective_pts`) flows into the existing disposition table and into a downstream enforcement gate without new disposition rows or parallel machinery.
- **Honest seeds:** values are config-resident and `[CALIBRATE-AFTER-3]`, so the recommendation does not pretend to empirical precision it lacks; the velocity instrument supplies the recalibration input.
- **Read-only-additive at the consumer:** `release-planner` emits `effective_pts` alongside raw `sum(pts)`; the critical-path math is untouched (provably no regression).

### Negative / cost

- **Coarser than per-issue ceremony:** keying on the bundle's single Release Class cannot express a routine bundle that happens to contain one high-ceremony issue. Accepted: per-issue ceremony has no shipped field, and the bundle-altitude solution is sufficient for the capacity-sizing purpose.
- **Seed magnitudes carry calibration debt:** the weights are MEDIUM-confidence until the 3-release recalibration; a class whose releases systematically over/under-run its band may need a weight adjustment that nobody performs. Mitigated by the `[CALIBRATE-AFTER-3]` marker + the RELEASE_LOG calibration trigger.
- **Gate fires after composition, not during it:** the downstream enforcement gate backstops at the Stage 3→4 boundary (after the Release Class is declared at B3) rather than shaping the bundle at Phase A5. Accepted: the warn-then-enforce posture softens the rework cost; surfacing `effective_pts` at A5 as an advisory is a future enhancement, not this decision.

### Reversibility

**CHEAP → MODERATE.** CHEAP at ship — additive only: revert the release PR (one config inline-table, additive doctrine sub-blocks, one deploy-check allowlist entry). Every addition ships a default and no existing field/row/enum is mutated, so existing readers keep working. Trends MODERATE once a downstream size-bound enforcement gate and `release-planner` wire into `effective_pts` and the weights are recalibrated under the rule.

## Options considered

| Option | Verdict | Why |
|---|---|---|
| (A) Release-Class multiplier on `sum(member_pts)` | **CHOSEN** | Scale-invariant; reuses the shipped gate-enforced Release Class; composes with the existing band + disposition table + downstream gate with zero new rows; config-parameterizable + `[CALIBRATE-AFTER-3]`. |
| (B) Additive ceremony budget (fixed pts per class) | Rejected | Not scale-invariant — a fixed constant distorts the XS–XL scale's meaning at small bundles and is trivial at large ones; ceremony cost should scale with scope. |
| (C) Per-issue ceremony/Tier-tag sum | Rejected (hard-constraint elimination, before scoring) | Requires a NEW per-issue ceremony field the backlog does not carry — a structural-tier change where a bundle-altitude solution exists. Highest blast radius. |

## Related ADRs

- [ADR-022 — platform-config.toml vs operator.toml split](ADR-022-platform-config-vs-operator-toml-split.md): establishes the `[bundling]` table on the platform-BEHAVIOR config surface where `release_class_capacity_weights` lands.
- [ADR-007 — Core module boundary lock-in](ADR-007-core-module-boundary.md): the Stage-6 ADR-authoring precedent and the markdown-doc-link cross-module reference posture this ADR follows (a doctrine in `release/` citing a config field in `core/`).

## References

<!-- repo-integrity: allow-issue-ref -->

- **Canonical definition:** `release/references/standards/bundle-composition-doctrine.md § 3 Step 5` (the Risk-Weighting sub-block — formula, rounding mode, boundary clause, recalibration linkage).
- **Value home:** `core/config/platform-config.toml.template [bundling].release_class_capacity_weights`.
- **Enum source (cited, not re-defined):** `release/references/specs/release-class-taxonomy.md` (the CLOSED 4-value Release Class enum) + `core/schemas/gate-criteria-spec.md` Gate 3 (G3-10 presence enforcement).
- **Release:** v2.02, milestone `61-bundling-capacity-and-sizing-gates` (#153); parent card #290; Stage-6 sub-task #1244.
