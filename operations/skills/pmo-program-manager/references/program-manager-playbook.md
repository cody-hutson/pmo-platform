<!-- reference-durability: allow-link -->
# Program Manager — Composition & Synthesis Playbook

Reference detail for the [`pmo-program-manager`](../SKILL.md) Specialist. SKILL.md is authoritative for the role, mode set, output contract, guardrails, and failure modes; this file carries the expanded composition surface, the delivery-model variation detail, and the reversibility-tier worked examples that the SKILL.md sections summarize-and-link. Nothing here re-implements a composed skill — `ppm-agent` and `delivery-engine` remain the single source for the functions they own (ADR-019). A finding with no composition reference is dropped before output; this playbook never becomes a back-door for inlining composed logic.

## 1. Composed-skill surface (expanded)

The Program Manager invokes these surfaces read-only. Their modes, gates, and output contracts stay owned by the composed skill. The Program Manager adds only the program-level synthesis layered on their outputs.

### `ppm-agent` (strategic synthesis + intake-governance)

- **Strategic-triage output**, run **per workstream / project**:
  - **Section 2 — Program Snapshot** (consumed by Mode 2 for the program-altitude posture read).
  - **Section 5 — Decisions needed**, each with a decision-authority tag (the org-model derivation from `delivery_approach`) + reversibility tier (consumed by Mode 3's go/no-go framing and Mode 5's decision-authority tagging).
  - **Section 6 — Top risks**, including the stale-RAID auto-escalation pass (the flag Mode 5 keys its escalation adjudication on, and the cross-project risk source for Mode 1).
  - **Section 7 — Dependencies and blockers** (the cross-project dependency source for Mode 1's inter-workstream edges).
  - **Section 9 — Proactive next steps** (cadence-gap + deadline detection across projects, consumed by Mode 2).
- **Intake-governance pass** (per `ppm-agent` `references/ppm-intake-governance.md`): business-case tier + demand-source tag + WSJF score + capacity-aware routing + the over-capacity trade-off package (consumed by Mode 4).

### `delivery-engine` (backlog → release-readiness mechanics)

- **Mode A — Backlog Ingestion & Health Scan** (grounds a cross-project risk against live backlog state in Mode 1).
- **Mode D — Sprint Planning**, including the capacity model + demand-supply band (the capacity arithmetic Mode 4's displacement decision rests on; the re-plan surface for Modes 1/2).
- **Mode E — Execution Control Tower** (velocity / burn / at-risk per workstream — the per-workstream posture Mode 2 aggregates).
- **Mode F — DoD / Release-Readiness Gate** (the per-workstream readiness verdict Mode 3 binds).
- **Mode G — RAID / Decision / Milestone Artifact Update** — the validated, approval-gated write. This human-in-the-loop checkpoint is **owned by `delivery-engine`** and is never bypassed by the Program Manager (Mode 3 records the go/no-go decision through it; Mode 5 executes the stewardship write through it).

**Allowlist note.** `delivery-engine` is on the C7 4-skill cascade allowlist for the PPM→`delivery-engine` auto-cascade path; that path is orthogonal to this Specialist's composition. The Program Manager is an operator-invoked role skill (Pattern B autonomy) that invokes each composed mode directly — it registers **no new C7 auto-cascade edge**. Routing depth stays ≤2 by construction (cascade rule C1): the Program Manager invokes a function-skill; that function-skill does not invoke a third on its behalf.

## 2. Cross-boundary influence (CS-15) — the defining synthesis

The Program Manager's reason to exist is the edge where a `ppm-agent` cross-project risk or dependency gates a `delivery-engine` program-delivery decision. This is the same CS-15 surface the two Phase-1 pilot Specialists (`pmo-technical-program-manager`, `pmo-program-coordinator`) calibrated; the Program Manager applies it as the load-bearing behavior of Mode 1 and Mode 3.

For every cross-project finding that touches a program delivery decision, the output states the edge as: **finding → the program gate / decision it gates → the gating relationship (blocks / conditions / non-blocking)**. Running the synthesis pass and the delivery pass as two disconnected analyses — risks in one block, the verdict in another, no edges between them — is the swallowed-influence failure mode; it is not a closed handoff.

Worked edge set (illustrative shape, not a fixed inventory):
1. workstream-A vendor-API slip → program cutover milestone → **BLOCKS**;
2. cross-workstream API dependency → workstream-C sprint plan → **CONDITIONS** (mock contract unblocks);
3. workstream-B logging gap → neither gate → **non-blocking**, RAID-logged.

## 3. Delivery-model variation (detail)

The Program Manager's synthesis varies by delivery model (`delivery_approach: context-aware`, resolved per the program's governance — see [`operations/skills/_shared/five-model-variations.md`](../../_shared/five-model-variations.md)):

- **Waterfall** — the program's delivery decisions are phase-gate (milestone DoD, stage exit); the risk binding is to the shared phase-gate the program is approaching, and the inter-workstream dependency is the predecessor-milestone edge.
- **Agile / Scrum** — the decisions are sprint-scoped across the workstreams (DoR for the next sprint, DoD for the increment); the binding is to the release train and cross-workstream sprint capacity.
- **Kanban** — continuous-flow; the binding is to the policy gates (cross-workstream WIP, the explicit DoD per class of service) rather than a sprint boundary.
- **Hybrid** — the program runs phase-gates over agile execution; the Program Manager binds risk to *both* the agile DoD and the phase-gate across workstreams, surfacing where they disagree.
- **n/a (no formal model)** — the binding is to the committed program milestones directly; the Program Manager names the implicit gate.

## 4. Reversibility tiers — worked examples

Per [`reversibility-protocol.md`](../../../../core/specs/reversibility-protocol.md), every decision-class output carries a tier paired with a confidence level. The decision-class outputs are: the Mode 1 ranked cross-project risk/dependency entries and their recommended actions; the Mode 2 program delivery-posture read and its recommended adjustments; the Mode 3 program release-readiness go/no-go and its conditions; the Mode 4 program intake trade-off ("take X, defer Y" displacement); and the Mode 5 RAID/decision-steward adjudications the operator acts on (the Mode G write itself stays approval-gated by `delivery-engine`).

- **CHEAP** (undo in hours, no stakeholder impact) — an internal pre-commit program-posture draft the operator has not circulated. *State the tier, proceed.*
- **MODERATE** (undo in days, small cohort) — a cross-project risk re-prioritization, or a re-scope / re-sequence recommendation across workstreams before commitment. *State the tier, surface the key assumption in ≤1 sentence, invite a single-reviewer pass.*
- **EXPENSIVE** (undo in weeks, multi-stakeholder) — an intake trade-off that re-baselines a program milestone across workstreams; a program release go/no-go pre-ship. *State the tier, document rationale (≥2 sentences), state the rollback plan, name the affected cohort (dependent workstream leads, sponsor).*
- **IRREVERSIBLE** (cannot undo — a shipped program release, an externally-committed go-live) — *state the tier, document rationale, state rollback is infeasible or name the counter-commitment, name the sign-off authority, pair with an explicit downside description.*

**The program release go/no-go (Mode 3) is frequently the highest-reversibility output the skill produces** — a GO on a program release that has shipped to production is EXPENSIVE-to-IRREVERSIBLE; the Program Manager never renders a GO without the tier, the confidence, and (for EXPENSIVE+) the rollback posture and sign-off authority. Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* — both travel together. A HIGH-confidence IRREVERSIBLE call still requires a sign-off gate. **The skill is NOT report-only** — it produces recommendations, go/no-go calls, and proposed actions; the report-only opt-out must NOT be used.
