<!-- reference-durability: allow-link -->
# Portfolio Manager — Composition & Synthesis Playbook

Reference detail for the [`pmo-portfolio-manager`](../SKILL.md) Specialist. SKILL.md is authoritative for the role, mode set, output contract, guardrails, and failure modes; this file carries the expanded composition surface, the delivery-model variation detail, and the reversibility-tier worked examples that the SKILL.md sections summarize-and-link. Nothing here re-implements a composed skill — `ppm-agent` and `weekly-status-rollup` remain the single source for the functions they own (ADR-019).

## 1. Composed-skill surface (expanded)

The Portfolio Manager invokes these surfaces read-only. Their modes, gates, and output contracts stay owned by the composed skill.

### `ppm-agent` (strategic triage + intake-governance)

- **Strategic-triage output**, run per project or against a portfolio-spanning artifact:
  - **Section 5 — Decisions needed**, each with a decision-authority tag + reversibility tier.
  - **Section 6 — Top risks**, including the stale-RAID auto-escalation pass (the `[STALE-ESCALATE]` flag the Portfolio Manager keys CS-15 edges on).
  - **Section 9 — Proactive next steps.**
- **Intake-governance pass** (per `ppm-agent` `references/ppm-intake-governance.md`): business-case tier + demand-source tag + WSJF score + capacity-aware routing + the over-capacity trade-off package.

### `weekly-status-rollup` (cross-project roll-up + portfolio write-back)

- **Section 1 — Portfolio Health Dashboard** (per-project RAG with the worst-component-dominance correction).
- **Section 5 — Looking Ahead** (the 2-week look-ahead; part of the full executive roll-up Sections 1–5).
- **Section 6 — Portfolio Write-Back** — the approval-gated PORTFOLIO.md write. This human-in-the-loop checkpoint is **owned by `weekly-status-rollup`** and is never bypassed by the Portfolio Manager.
- **Section 7 — Portfolio Governance** — the 8-signal W1–W8 watermelon scan (canonical home in `pmo-qa-auditor` `references/watermelon-detection.md`, run by reference), the lag/lead audit, the R-G-T allocation, the per-metric decision-rule validation, and the capacity dashboard.

## 2. Delivery-model variation (detail)

The Portfolio Manager's synthesis varies by delivery model (`delivery_approach: context-aware`, resolved per the portfolio's governance — see [`operations/skills/_shared/five-model-variations.md`](../../_shared/five-model-variations.md)):

- **Waterfall / SPM** — portfolio calls are phase-gate-anchored; the cross-project binding is to the milestones and stage gates the projects are approaching, and the SteerCo readiness call is the phase-gate decision at portfolio scope.
- **Agile / Scrum** — portfolio calls are anchored to the release trains and sprint commitments across projects; the binding is to cross-project capacity and the WSJF-ranked backlog.
- **Kanban** — continuous-flow; the binding is to the portfolio policy gates (cross-project WIP, the explicit class-of-service throughput) rather than a sprint boundary.
- **Hybrid** — the portfolio runs phase-gates over agile execution; the Portfolio Manager binds cross-project health to *both* the agile cadence and the phase-gate, surfacing where they disagree at portfolio altitude.
- **n/a (no formal model)** — the binding is to the committed portfolio milestones directly; the Portfolio Manager names the implicit gate.

## 3. Reversibility tiers — worked examples

Per [`reversibility-protocol.md`](../../../../core/specs/reversibility-protocol.md), every decision-class output carries a tier paired with a confidence level. The decision-class outputs are: the Mode 1 portfolio health call and load-bearing-signal adjudications; the Mode 2 portfolio-ranked risk/decision entries and their recommended actions; the Mode 3 intake trade-off ("take X, defer Y" displacement); and the Mode 4 SteerCo / Portfolio Readiness Decision and its conditions.

- **CHEAP** (undo in hours, no stakeholder impact) — an internal pre-confirmation portfolio health read; a draft SteerCo summary the operator has not circulated. *State the tier, proceed.*
- **MODERATE** (undo in days, small cohort) — a portfolio health transition or Top-3 portfolio priority list circulated to a TPM before SteerCo. *State the tier, surface the key assumption in ≤1 sentence, invite a single-reviewer pass.*
- **EXPENSIVE** (undo in weeks, multi-stakeholder) — a portfolio intake trade-off (defer committed item Y to take X) that re-sequences in-flight work across projects; a portfolio health transition shared with leadership. *State the tier, document rationale (≥2 sentences), state the rollback plan, name the affected cohort (dependent project leads, sponsor).*
- **IRREVERSIBLE** (cannot undo — a portfolio readiness call distributed to a SteerCo/exec audience that sets the committed status on the record; a portfolio-of-record health write-back consumed by external reporting) — *state the tier, document rationale, state rollback is infeasible or name the counter-commitment, name the sign-off authority (program sponsor / COO), pair with an explicit downside description.*

**The SteerCo readiness call (Mode 4) is frequently the highest-reversibility output the skill produces** — the skill never renders it without the tier, the confidence, and (for EXPENSIVE+) the rollback posture. Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* — both travel together. A HIGH-confidence IRREVERSIBLE call still requires a sign-off gate.
