<!-- reference-durability: allow-link -->
# Tier-2 Support — Composition & Reversibility Reference

This reference holds the granular composition contract for `pmo-tier-2-support` and its skill-specialized reversibility tier vocabulary. The SKILL.md `## Composition` and `## Reversibility Discipline` sections are the operating contract; this file is the detailed surface they derive from. Everything except the RCA *method* is consumed via invocation, never re-implemented ([ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)); the RCA method is invoked by citation, not import.

## 1. Composition contract

Tier-2 **owns the RCA method but composes everything else** by **invoking the function-skills through the `core/`-registry skill-chain** (runtime chaining), and **re-implements none of them** — per [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md). The composed skills are read-only here; their modes, staging, classification, and persistence contracts are owned by them. Tier-2 adds only the **RCA + runbook content** on top — never the production *mechanism*.

| Composed function-skill | Tier-2 invokes it for | Tier-2 does NOT |
|---|---|---|
| [`artifact-generator`](../../artifact-generator/SKILL.md) | Produce the **runbook artifact** and the **RCA record** — staged per its Generate Mode (`08-Generated/`, `lifecycle_state: draft` + `promotion_state: staged`) | re-implement artifact production / staging / formatting |
| [`file-router`](../../file-router/SKILL.md) | **Classify and route** the runbook to its governed knowledge-base location | re-implement three-layer classification or routing-target selection |
| [`pmo-knowledge-manager`](../../pmo-knowledge-manager/SKILL.md) | **Persist and steward** the runbook into the knowledge base as the durable first-line-resolvable record (the Knowledge Manager itself composes `artifact-generator` + `file-router` for the capture-route-steward pass) | own the knowledge-base persistence / stewardship mechanics |
| [`intake-desk`](../../intake-desk/SKILL.md) | File a **tracked work item** when the RCA reveals a defect/improvement that needs one | author the work item itself, run the 5-test, or auto-decompose |

**Compose-not-absorb statement (ADR-019):** Tier-2 **owns the RCA method but composes everything else.** It owns the *method* (`root-cause-analysis.md` — which it **invokes, not redefines**) and the *causal judgment*; it does **not** re-implement artifact generation (invokes `artifact-generator`), classification/routing (`file-router`), knowledge-base persistence (`pmo-knowledge-manager`), or work-item intake (`intake-desk`). **Re-implementing `artifact-generator` inside tier-2** — the explicit anti-pattern named in this skill's acceptance criteria — would fork the single source of artifact production and drift the runbook format from every other artifact. The RCA method itself stays single-sourced in `core/disciplines/`; tier-2 is its primary support-domain caller, not a second copy of it.

## 2. Reversibility tier vocabulary

These are the skill-specialized instances of the canonical tiers in [`reversibility-protocol.md`](../../../../core/specs/reversibility-protocol.md). Every decision-class output — the RCA root-cause conclusion, the CAPA, and the published runbook — carries a tier + confidence.

**Tier vocabulary:**
- **CHEAP** (undo in hours) — an in-progress RCA record nobody has acted on; a draft runbook staged in `08-Generated/` before persistence. State the tier, proceed.
- **MODERATE** (undo in days, propagates until corrected) — **the default for a runbook published to the knowledge base.** It shapes future first-line answers; a wrong runbook is undone in days but propagates a wrong fix until corrected — distinct from tier-1's CHEAP ephemeral close. State the tier, surface the key assumption in ≤1 sentence, invite a reviewer pass; the published runbook descends to operator-confirm.
- **EXPENSIVE** (undo in weeks, multi-stakeholder) — a root-cause conclusion that **drives a structural CAPA** (multi-component remediation, a governance change, a platform-wide fix). Document rationale (≥2 sentences), state the rollback plan, name the affected cohort; the conclusion descends to operator-confirm.
- **IRREVERSIBLE** (cannot undo) — a CAPA that triggers an externally-committed or audit-of-record change. Rollback infeasible → name the counter-commitment + sign-off authority, pair with an explicit downside.

A **published runbook is frequently the highest-reversibility output a routine escalation produces** (MODERATE by default); a structural CAPA escalates to EXPENSIVE+. Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* — both travel together. A HIGH-confidence EXPENSIVE conclusion still requires the rationale + rollback and the operator-confirm descent.
