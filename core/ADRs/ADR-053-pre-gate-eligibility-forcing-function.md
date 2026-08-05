---
title: Pre-gate eligibility precondition (Gate 0) as the autonomy-conformance forcing function
status: Accepted
tags: [hub-autonomy, gate-eligibility, forcing-function, decision-briefing, autonomy-tiers, governance-theater, warn-to-enforce]
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-053 — Pre-gate eligibility precondition (Gate 0) as the autonomy-conformance forcing function

## Status

Accepted (Stage 9 Plan Review GO, milestone 64-hub-autonomy-conformance / v3.31). Authored at Stage 6 alongside the enforcement surfaces it governs, per the core-ADR convention (a decision captured as a committed ADR document written in the same release as the artifact it governs).

**Deciders:** operator · **Date:** 2026-06-30

## Context

The hub's autonomy *policy* is complete and current: `autonomous-execution-model.md` § Autonomous Execution Disposition forbids re-presenting framework-resolved actions as operator gates ("context-available-but-not-applied" failure); `autonomy-tiers.md` defines the Tier 0–3 model and the `FM-2` tier-inflation / governance-theater failure mode; `hub-spoke-bridge.md` § Procedure 7 codifies the Standing-GO Authorization Model (post-Stage-9-GO Tier-1 mechanical actions execute without a per-step gate). The **descriptive prohibition is present**. What is absent is a **forcing function**: nothing makes the hub consult that policy at the moment it constructs an operator gate. The hub recurringly re-presents Autonomy-Tier-2/3 auto-launch and Standing-GO Tier-1 actions (notably Milestone close) as `AskUserQuestion` gates — the conformance regression #377 names.

The existing pre-`AskUserQuestion` precondition block — the Decision Briefing Information Sufficiency gate check — verifies briefing *completeness* (option space loaded, briefing rendered, stance scanned) but contains **no gate that asks whether the gate should exist at all**. Gate *eligibility* is the missing question.

## Decision

Add a **Gate 0 — gate-eligibility precondition** at the head of the Information Sufficiency gate list (`hub-spoke-bridge.md` § Operating Principle: Decision Briefing), as a **literal "Gate 0"** that runs **before** the existing gates 1–5 — **without renumbering** them (the gates retain their numbers; all existing "gate 3/4/5" citations stay valid). Gate 0 is a MUST-pass classification: before issuing any operator gate, the hub classifies the candidate action against (1) the Stage-to-Autonomy-Tier mapping and (2) the Standing-GO Authorization list. An action whose effective **Autonomy Tier** is Tier 2 (Bounded Auto) or Tier 3 (Autonomous, within an approved-plan / Standing-GO scope), or a Standing-GO Tier-1 mechanical action after Stage 9 GO, is **NON-gate-eligible** — the hub executes it and reports the observable state change, it does not render a gate. Only the reserved genuine-judgment touchpoints (Stage 9 GO/NO-GO, Stage 12 Execute, Stage 4 judgment-Ds, Collective Review scope-lock, Autonomy-Tier 2/3 inter-stage escalations, Tier 0 Premise Rejection, post-deploy `--apply`) — or a genuinely novel/ambiguous situation the framework does not resolve — are gate-eligible and proceed to gates 1–5.

**Token disambiguation (adopted refinement FMF-1):** "Tier" in Gate 0's non-gate-eligible exit means **Autonomy Tier** (`autonomy-tiers.md`), never the Inter-Stage-Feedback routing Tier. The two conventions point opposite directions at this action class — an Inter-Stage-Feedback **Tier 2 scope change** (or **Tier 3 plan rejection**) is **gate-eligible** (it escalates / produces a Decision Briefing), NOT a Bounded-Auto execution. Gate 0's classifier is anchored to the Autonomy Tier table; the durable spec text carries the `Autonomy Tier` qualifier so the disambiguation does not depend on the reader already knowing the prefix-binding rule.

**Reversibility carve-out (inherited).** An IRREVERSIBLE action re-enters the gate-eligible path regardless of tier (`autonomy-tiers.md` Boundary Test 3) — Gate 0 does not weaken the irreducible-human floor.

**Warn→enforce posture (adopted refinement FMF-2).** Gate 0 ships warn-mode-initial and rides the `shadow→warn→enforce` ladder; its telemetry is the R4 unauthorized-gate metric (target 0/release). In warn mode the hub normally executes the suppressed action and emits the notice after — **except** that for an action Gate 0 classifies non-gate-eligible **and** whose reversibility is **MODERATE or worse**, the hub emits the suppressed-gate notice **before** executing (a one-line "suppressing gate for X under [Standing-GO row]; proceeding unless you object"). This ties the control's weakest mode to the reversibility tier, so the introducing release is not the release where a mis-classified EXPENSIVE action executes silently. CHEAP mechanical state-flips (the bulk of the Standing-GO table) keep the execute-then-notice warn behavior.

Gate 0 is the read-side **enforcement** of the Standing-GO model (a declare/enforce pair); it changes no Standing-GO content and references it by name.

## Alternatives Considered

| # | Option | Trade-off | Verdict |
|---|---|---|---|
| A | **Literal "Gate 0" at the head of the existing Information Sufficiency block, gates 1–5 unchanged** (chosen) | Minimal surface; one pre-gate lifecycle event; eligibility + sufficiency co-located. **Zero ordinal edits** — "Gate 0" is the platform's own idiom for a logically-prior precondition (cf. Procedure 0b, Phase 0 / Phase 0.5), so no "gate 3/4/5" citation moves. | **CHOSEN** — minimal-change, single pre-gate surface, composes the existing gate precondition, and (per CDF-1) strictly dominates the renumber variant on blast radius at zero clarity cost. |
| A′ | Gate 0 at the head **with** a renumber of gates 1–5 → 2–6 | Marginally cleaner sequential reading, but forces 7 same-PR ordinal edits across 2 files (in-file worked-example callouts + `release-personas.md` "gate 3/4/5") and creates a standing cross-file ordinal-coupling drift surface. | Rejected at scope-lock (CDF-1) — the coupling is the design's own "one real hazard"; the literal-label form retires it. |
| B | Standalone "Gate-Eligibility" section elsewhere in `hub-spoke-bridge.md` | Fragments the one pre-gate surface into two; risk a hub running sufficiency-gates on a gate Gate 0 would have suppressed; a second forcing-function location to keep in sync. | Rejected — fragments the construction precondition; higher drift surface. |
| C | Persona-only hardening (R2) with no precondition in the bridge | Cheapest, but a behavioral marker without a MUST-pass precondition is exactly the "policy present, not enforced" state #377 diagnoses; leaves no structural forcing function. | Rejected — re-creates the gap (descriptive-only). R2 composes WITH Gate 0; it does not replace it. |
| D | A PreToolUse hook that blocks `AskUserQuestion` for classified actions | Strongest enforcement, but `AskUserQuestion` eligibility needs the hub's per-action tier classification, which the hook payload lacks (same Phase-2-deferred limit as `block-autonomy-ceiling.sh` per ADR-031); infeasible now. | Rejected for this release — payload cannot carry the classification. Residual tracked under #172 (eval automation); revisit if a tier-signal becomes payload-detectable. |

## Consequences

- **Positive:** the policy becomes enforced at the decision surface; the `FM-2` governance-theater failure gains a structural catch; Milestone close and other Standing-GO actions stop reading as operator gates; the unauthorized-gate metric makes conformance measurable and rides the shipped #164 / #165 substrate.
- **Negative / residual:** Gate 0 is hub-narrative-executed (no CI backstop this release — the same warn-mode-documented-guard posture the Information Sufficiency block already carries; residual logged under #172 per CDF-2). A mis-classified novel action fails safe toward a rendered gate (operator-visible, not silently suppressed), and the FMF-2 reversibility-gate ensures the warn-mode weakest mode is weakest only where a mistake is cheap to undo. Reversibility **CHEAP** (single precondition block; revertable in one PR). Confidence **HIGH** (composes `autonomy-tiers.md`, the Standing-GO model, the Information Sufficiency block, and the shipped #164 / #165 telemetry — no new primitive invented).

## Composition

R2 (persona do-not-ask + hedge marker) is the behavioral-marker layer over Gate 0; R3 (no-re-surface guard, keyed on `(decision_type, option_set_hash)` per FMF-3) prevents a resolved gate from re-firing as a fresh unauthorized gate; R4 (unauthorized-gate metric) is Gate 0's telemetry across the #164 ladder, conforming to the #165 phase-out schema. #381 (CODIFY) is the sibling — Gate 0 references the codified Standing-GO / milestone-close-is-Tier-1 rules #381 moves into the stage specs, and the #381 carve-out prose cites this Gate-0 reserved list rather than copying it (CDF-3); #381 sequences at/before #377 so Gate 0 cites stage-spec rules, not memory.
