---
title: Finding Disposition Framework
type: standard
purpose: K1 codified-knowledge canonical cross-stage finding-disposition decision-weighting framework — the stage-agnostic WHEN-axis (fix-now / defer / accept) that layers on top of each review stage's WHERE-axis (classification/routing). Defines the corrected 5-factor disposition matrix, the Step 1 weighted-disposition logic, the Step 2 tie-break order, and the stage-agnostic scoring skeleton. Consumed by Stage 7 Dev Testing and Stage 8 QA Testing, each of which injects its own stage-specific Step 0 precedence gate.
parallel_to:
  - release/references/pipeline/stage-07-dev-testing.md (Stage 7 consumer — injects the open-Blocker Step 0 gate; owns the DT worked example + Phase D/E pointers + Automation Trajectory row)
  - release/references/pipeline/stage-08-qa-testing.md (Stage 8 consumer — injects the NOT-MET-AC Step 0 gate with operator-override record)
  - release/references/standards/solutioning-output-template.md (sister K1 standard — house style for Stage-5/6 reference scaffolds)
consumers:
  - release/references/pipeline/stage-07-dev-testing.md (§ Finding Disposition Decision Framework — references this doc for matrix + Steps 1-2 + scoring; defines Stage-7 Step 0)
  - release/references/pipeline/stage-08-qa-testing.md (§ Finding Disposition Decision Framework — references this doc for matrix + Steps 1-2 + scoring; defines Stage-8 Step 0)
reversibility: CHEAP (forward-only reference doc; existing stage outputs not retroactively conformed; revisable in subsequent releases without breaking consumers)
last-updated: 2026-06-06
---
<!-- reference-durability: allow-link -->

# Finding Disposition Framework — Cross-Stage WHEN-Axis Decision Weighting

## § 1. Purpose + Scope

Review stages produce findings. Each review stage already has a **WHERE-axis** — it classifies a finding by severity and routes it (e.g., to Engineering vs the operator, at a routing tier). The WHERE-axis answers *where does this finding go*. It does **not** answer *when should it be addressed*.

This standard defines the **WHEN-axis**: for each finding, **fix-now** (this release) vs **defer** (a future release) vs **accept** (as-is). It is a stage-agnostic decision-weighting framework — a 5-factor matrix plus a two-step decision logic — that the review stages consume so the fix-now / defer / accept call is deterministic and consistent across stages, rather than ad-hoc per finding.

The two axes **compose**: a consuming stage classifies WHERE first, then disposes WHEN. Disposition is **advisory input to the human** at the stage's human-review step — it is a weighting aid, not auto-correction.

**In scope (this standard):** the stage-agnostic mechanics — the 5-factor disposition matrix (§ 3), the Step 1 weighted-disposition logic and Step 2 tie-break (§ 4), and the stage-agnostic scoring skeleton (§ 5).

**Out of scope (this standard — stage-injected by each consumer):** the **Step 0 precedence gate**. Step 0 is a severity/verdict gate applied *before* the weighted layer, and it differs per stage (an open Blocker means something different at Dev Testing than a NOT-MET acceptance criterion does at QA). Each consuming stage defines its own Step 0 in its own shard. See § 6.

**Audience:** Stage 7 Dev Testing spokes and Stage 8 QA Testing spokes (primary consumers); the operator (renders disposition per finding at each stage's human-review step); `pmo-qa-auditor` (audit-trail consumer).

## § 2. When This Applies

Applies whenever a consuming review stage has a finding that has already been classified on its WHERE-axis and now needs a fix-now / defer / accept disposition. One disposition per finding. The consuming stage's human-review step renders the disposition; this framework is the weighting aid it applies.

**Does NOT apply to** the WHERE-axis classification itself (severity bucketing, routing-tier assignment) — that remains owned by each stage's own classification rule. This framework layers *on top of* that classification; it does not replace it.

## § 3. Disposition Matrix (5 factors)

Each finding is read against five factors. Each factor emits one of three signals — **Fix-Now**, **Defer**, or **Accept** — and carries a weight (High / Medium / Low) used by the Step 1 weighting in § 4.

| # | Factor | Weight | Fix-Now signal | Defer signal | Accept signal |
|---|---|---|---|---|---|
| 1 | **Effort** | High | Trivial — single file, < ~30 min, no design decision | Non-trivial — multi-file, or needs an unmade design decision | Effort never *alone* justifies Accept (a cheap fix is never accepted *because* it is cheap) |
| 2 | **Best-Practice Alignment** | High | Moves the artifact toward a **documented** standard (cite it) | Standard is **aspirational** / not-yet-current (no documented anchor) | **Intentional, documented** deviation from the standard |
| 3 | **Downstream Impact** | Medium | Blocks or degrades a downstream stage / consumer | No downstream dependency; bounded to this release | Isolated to this file/context; no consumer reads it |
| 4 | **Reversibility / Risk** | Medium | Additive / low-regression-risk (CHEAP reversibility) | MODERATE+ regression risk; safer in its own change cycle | The *fix* introduces more risk than the *finding* (net-negative to act) |
| 5 | **Scope-Window** *(gate-modifier)* | Low | PR/branch still **open** — additive change rides the existing review | Would require a **new branch/release cycle** | **Out of platform scope** entirely |

**Note on the Effort "Accept" cell.** Effort is a *fix-now-vs-defer* discriminator only; it can never *by itself* push to Accept. Accept is owned by factors 2 / 3 / 4. The cell reads "Effort never alone justifies Accept" rather than `N/A` — closing the structural hole a naive 5-column matrix leaves.

**Note on Scope-Window as a gate-modifier.** Scope-Window is weighted Low and behaves as a modifier on the gate (is the PR/branch still open?) rather than as a free factor that double-counts the disposition gate. It expresses *the cost of acting now vs in a new cycle*, not a fourth independent reason to fix/defer/accept.

## § 4. Decision Logic (Step 1 weighted + Step 2 tie-break)

The decision logic is three-step. **Step 0** (the hard precedence / severity gate) is **stage-specific and injected by each consuming stage** — see § 6. The two stage-agnostic steps below run for every finding the stage's Step 0 gate did not already force.

> **Step 1 — Weighted disposition** (for findings the Step 0 gate did not force): score each factor's signal weighted **High = 3 / Medium = 2 / Low = 1**.
> - **Fix-now** when `Effort = Fix-Now AND (Best-Practice = Fix-Now OR Downstream = Fix-Now) AND Reversibility ≠ Accept AND Scope-Window = open`. (This is the operator's standing rule made precise: a trivial, best-practice-aligned, low-risk fix on an open branch is fix-now.)
> - **Defer** when `Effort = Defer OR Scope-Window = Defer OR an unmade design decision` — AND no factor signals Accept.
> - **Accept** when any of `Best-Practice = Accept` (documented intentional deviation) OR `Downstream = Accept` (isolated, no consumer) OR `Reversibility = Accept` (the fix is net-negative). Accept always carries a one-line documented rationale.
>
> **Step 2 — Tie-break** (when Step 1 factors disagree, applied in this order):
> 1. `Reversibility = Accept` → **Accept** (never make it worse).
> 2. else `Effort = Fix-Now AND Scope-Window = open` → **Fix-Now** (cheap-and-open default).
> 3. else → **Defer** (conservative default — a deferred item is re-dispositioned next release; a wrongly-accepted item is lost).

The tie-break's conservative default (Defer) mirrors the asymmetry the review stages already encode for routing ("when uncertain, over-escalate"): the cost of deferring a finding that could have been fixed now is one extra cycle; the cost of accepting a finding that should have been fixed is silent loss.

## § 5. Stage-Agnostic Scoring Skeleton

The matrix + decision logic compose into a scoring function `disposition(finding) → {fix-now, defer, accept, escalate}`. The skeleton below is the **stage-agnostic core (Steps 1–2 only)**. **Step 0 is stage-injected** — each consuming stage prepends its own precedence gate (the `# Step 0 — stage-injected` block) ahead of this skeleton, per § 6. The function is **advisory** (it recommends; the human confirms) until calibration data justifies promotion.

```
disposition(f):
  # Step 0 — STAGE-INJECTED precedence gate (see § 6; each consumer prepends its own).
  #   e.g. Stage 7 DT: open Blocker → fix-now-or-escalate; Note → accept.
  #   e.g. Stage 8 QA: NOT-MET AC → no defer/accept without a recorded operator override.

  # Step 1 — weighted signals (stage-agnostic)
  score = Σ weight(factor) · signal(factor)   # weight: H=3, M=2, L=1; signal ∈ {fix-now, defer, accept}
  if any(signal == accept for x in [BestPractice, Downstream, Reversibility]): return accept   # + rationale
  if Effort==fix-now and (BestPractice==fix-now or Downstream==fix-now) \
     and Reversibility!=accept and ScopeWindow==open:      return fix-now
  if Effort==defer or ScopeWindow==defer or f.unmade_design_decision: return defer

  # Step 2 — tie-break (stage-agnostic)
  if Reversibility==accept: return accept            # tie-break 1
  if Effort==fix-now and ScopeWindow==open: return fix-now   # tie-break 2
  return defer                                       # conservative default
```

## § 6. Step 0 Is Stage-Specific (the precedence-gate contract)

Step 0 is the **hard precedence (severity / verdict) gate** applied *before* the weighted layer. It is intentionally **NOT** defined in this shared standard, because the severity/verdict vocabulary it keys on — and the strength of the no-silent-disposition rule it enforces — differ by stage. This standard owns the stage-agnostic mechanics (§§ 3–5); each consuming stage **MUST** define its own Step 0 precedence gate in its own shard.

The contract every consumer's Step 0 satisfies:

1. **Runs first.** Step 0 is evaluated before the Step 1 weighted layer; a finding the gate forces never reaches weighting.
2. **Forecloses silent non-fix dispositions for the stage's hardest finding class.** The gate names the stage's blocking finding class (an open Blocker; a NOT-MET acceptance criterion) and forbids the weighted layer from silently deferring or accepting it.
3. **Names its override path.** Any non-fix disposition of a gated finding requires an explicit, documented operator override — never an ad-hoc judgment call.

**The two consuming stages and their Step 0 gates:**

| Consumer stage | Step 0 precedence gate (defined in the consumer's shard) |
|---|---|
| **Stage 7 — Dev Testing** | An open **Blocker** is **fix-now** when "fixable within scope," else **escalate** — never silent Defer/Accept. A **Note** is **Accept (informational)**. Defined in [`release/references/pipeline/stage-07-dev-testing.md`](../pipeline/stage-07-dev-testing.md) § Finding Disposition Decision Framework. |
| **Stage 8 — QA Testing** | A **NOT-MET acceptance criterion** cannot be Deferred or Accepted without a **recorded operator override** — strictly stronger than the Stage 7 Blocker gate (Stage 7 permits in-scope Blocker auto-fix-now; Stage 8 forbids *any* non-fix disposition of a NOT-MET AC absent operator sign-off). Defined in [`release/references/pipeline/stage-08-qa-testing.md`](../pipeline/stage-08-qa-testing.md) § Finding Disposition Decision Framework. |

The Stage 8 gate is the Stage 7 gate **strengthened** — the only difference between the two stages' disposition logic. Everything below Step 0 (the matrix in § 3, the Steps 1–2 logic in § 4, the scoring skeleton in § 5) is **shared verbatim** and reused unchanged by both stages.

## § 7. Consumers

This framework is referenced (not duplicated) by each consuming stage shard. Each consumer references §§ 3–5 for the shared mechanics and defines only its own Step 0 gate plus its stage-specific integration:

| Consumer | Reading surface | What the consumer owns locally (not in this doc) |
|---|---|---|
| [`release/references/pipeline/stage-07-dev-testing.md`](../pipeline/stage-07-dev-testing.md) | § Finding Disposition Decision Framework | Stage-7 Step 0 (open-Blocker gate); DT worked example; the Disposition → routing-consequence table (Tier 1 `fix(dt):` / Tier 2 / Defer → next-release issue / Accept → logged); Phase D/E forward-pointers; the Automation Trajectory row |
| [`release/references/pipeline/stage-08-qa-testing.md`](../pipeline/stage-08-qa-testing.md) | § Finding Disposition Decision Framework | Stage-8 Step 0 (NOT-MET-AC gate + 5-field operator-override record; CONDITIONAL ACCEPT as the override vehicle); PARTIAL-verdict handling; three-lane integration; the Stage 7 ↔ Stage 8 differentiation note |

**Content-split rule:** the stage-agnostic mechanics (matrix + Steps 1–2 + tie-break + scoring skeleton) live **once**, here. No consumer re-inlines them; each consumer references this doc for the shared core and adds only its Step 0 gate and stage-specific integration.
