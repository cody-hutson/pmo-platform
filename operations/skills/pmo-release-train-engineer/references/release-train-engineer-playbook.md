<!-- reference-durability: allow-link -->
# Release Train Engineer — Composition, Activation & Synthesis Playbook

Reference detail for the [`pmo-release-train-engineer`](../SKILL.md) Specialist. SKILL.md is authoritative for the role, the SAFe-conditional activation gate predicate, the mode set, the output contract, the guardrails, and the failure modes; this file carries the **expanded composition surface**, the **per-mode process detail**, the **SAFe-conditional branch worked detail**, the **role-boundary rationale**, and the **reversibility-tier worked examples** that the SKILL.md sections summarize-and-link. Nothing here re-implements a composed skill — `delivery-engine` and `ppm-agent` remain the single source for the functions they own (ADR-019). A claim with no composition reference is dropped before output; this playbook never becomes a back-door for inlining composed logic.

## 1. Composition surface (expanded)

The RTE composes two function-skills by invoking them through the `core/`-registry skill-chain (runtime chaining) and re-implements neither, per [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md). The composed skills are read-only; their modes, gates, and output contracts are owned by them. The RTE adds only the ART/PI-level facilitation synthesis layered on their outputs.

| RTE Mode | Composes `delivery-engine` (modes owned there) | Composes `ppm-agent` (sections owned there) |
|---|---|---|
| **Mode 1 — PI-Planning Facilitation** | **Mode D (Sprint Planning)** per ART team for focus-adjusted capacity + sprint scope (RTE aggregates across teams into a PI view); **Mode C (DoR Gate)** so PI-scope items meet DoR before the PI commit. | **Section 5 (Decisions needed)** for PI-objective trade-offs; **Section 9** proactive PI-readiness. |
| **Mode 2 — ART Dependency & PI-Risk Management** | **Mode E (Execution Control Tower)** for per-team execution status feeding the ART roll-up; **Mode G (RAID)** for program-increment RAID entries. | **Section 6 (Top risks)** + **Section 7 (Dependencies & blockers)** for the cross-team dependency/risk synthesis pushed to resolution. |
| **Mode 3 — Program-Flow & Impediment Escalation** | **Mode E (Execution Control Tower)** for the flow / velocity-as-range read; **Mode G (RAID)** to record each impediment as a RAID Action with owner + due date. | **Section 6** stale-RAID auto-escalation pass; **Section 10** `[COMMS]`-routed escalation handoff. |
| **Mode 4 — ART Release-Readiness Synthesis** | **Mode F (DoD / Release-Readiness Gate)** for the per-team + ART release-readiness verdict. | **Section 5** GO / GO-WITH-CONDITIONS / NO-GO decision framing. |

**Compose-not-absorb boundary (ADR-019).** The RTE does not re-derive any sprint-planning, DoR/DoD-gate, execution-control, RAID, or strategic-triage logic. When a mode composes `delivery-engine` Mode D, it *chains to* `delivery-engine` and consumes its sprint plan — it does not re-implement the capacity model. The single source for each function stays the function-skill; the RTE forks none of it.

**Registry-broker invocation.** The composed skills are invoked through the `core/` logical skill-registry broker, which resolves the runtime chain at invocation; there is no code import. The composed skills' `chained=true` argument semantics (suppress the opening AskUserQuestion, read-from-manifest, decrement cascade depth) are the existing `delivery-engine` Chained Invocation Contract — the RTE invokes through that contract and adds no new chaining machinery.

## 2. SAFe-conditional activation — branch detail

The activation gate runs as **step 0, before mode selection** (a DORMANT invocation never reaches mode selection). It renders the SAFe view "by nature" via a single read of the canonical methodology signal, per the [Methodology Awareness Protocol](../../../../core/governance/OPERATIONS.md). The SKILL.md `## SAFe-Conditional Activation` section is authoritative for the predicate; the detail below expands each branch.

1. **Read `delivery_approach` at invocation** (Methodology Awareness Protocol Rule 1 — read PROJECT.md's `delivery_approach`; MAY cache within the invocation, MUST NOT cache across invocations). No `org_model` / `governance_model` field is read or assumed (there is none).

2. **`delivery_approach == SAFe` → ACTIVE.** Resolve the SAFe parameterization from the release-side [`methodology-archetype-matrix.md`](../../../../release/references/specs/methodology-archetype-matrix.md) **SAFe row** (Methodology Awareness Protocol Rule 2): lifecycle `timeboxed`; ceremonies `PI Planning, System Demo, Inspect & Adapt, scrum-of-scrums`; artifacts `ART backlog, PI objectives, program board, solution intent`; cadence `8–12 week Program Increment (4–6 team sprints)`. The skill reads the canonical SAFe row rather than carrying a hand-maintained SAFe branch.

3. **`delivery_approach ∈ {Scrum, Kanban, XP, Waterfall, PRINCE2, Hybrid}` → DORMANT.** The skill emits a one-line non-fire notice — *"`pmo-release-train-engineer` is SAFe-conditional and does not fire under `delivery_approach: <X>` — the Release Train Engineer role is meaningful only on a SAFe Agile Release Train. Route ART-shaped intent to the methodology-appropriate role (`pmo-scrum-master` for Scrum team-process; `pmo-program-manager` for non-SAFe program coordination)."* — and then stops. It does not produce an ART artifact, does not chain to the composed skills, and does not error. Dormant-under-non-SAFe is correct behavior; the platform default is Scrum, so dormant is the common case.

4. **`delivery_approach == Custom` →** branch on the `custom_methodology_definition` block: if `base_archetype == SAFe`, treat as **ACTIVE** consuming the block's overrides (CASE 2 per [`methodology-parameterization-v1.md § 5`](../../../../release/references/specs/methodology-parameterization-v1.md)); else **DORMANT** (CASE 3 / non-SAFe base). Never silently default-to-SAFe and never default-to-Scrum.

5. **`delivery_approach` absent / unparseable → DORMANT with an owned caveat** (negative-path discipline, mirrors `ppm-agent`'s org-model detection): emit `[ASSUMPTION – CONFIRM] delivery_approach absent — pmo-release-train-engineer not fired; the RTE role requires an explicit SAFe delivery_approach — to activate: set delivery_approach: SAFe in PROJECT.md`. Never assume SAFe from ambient context; absence is dormant, not active.

6. **Debug-log the branch** per [`methodology-archetype-matrix.md § 5.3`](../../../../release/references/specs/methodology-archetype-matrix.md): `[methodology-branch: CASE 1 archetype=SAFe → RTE ACTIVE]` / `[methodology-branch: non-SAFe (<X>) → RTE DORMANT]` / `[methodology-branch: CASE 2 base=SAFe → RTE ACTIVE]` / `[methodology-branch: CASE 3 null-or-non-SAFe-base → RTE DORMANT]`.

A DORMANT outcome is a successful, correct invocation that declines to produce an ART artifact and routes the intent elsewhere — it is first-class behavior, not an error path.

## 3. Per-mode process detail

Each mode confirms the SAFe activation gate passes (step 0) before any of the steps below; a DORMANT instance never reaches a mode.

### Mode 1 — PI-Planning Facilitation
1. Chain to `delivery-engine` Mode D per ART team to surface each team's focus-adjusted capacity; aggregate across teams into the ART's PI capacity envelope.
2. Chain to `delivery-engine` Mode C to confirm PI-scope items meet DoR before the commit.
3. Chain to `ppm-agent` Section 5 to frame the PI-objective trade-offs (what fits the PI, what defers) as decisions.
4. Render the PI plan: draft PI objectives, the aggregated capacity view, and the program board's cross-team commitments, each decision-class item carrying a reversibility tier + confidence.

**Output:** a PI-Planning facilitation pack — draft PI objectives, the cross-team capacity aggregation (sourced to the composed `delivery-engine` Mode D per team), the program board's commitment/dependency edges, and the PI-objective trade-off decisions.

### Mode 2 — ART Dependency & PI-Risk Management
1. Chain to `delivery-engine` Mode E for each ART team's execution status; roll up into the ART-level flow/health view.
2. Identify the cross-team dependency edges (a deliverable from team A that team B's PI objective depends on) and the program-increment risks that threaten the PI commitment.
3. Chain to `ppm-agent` Sections 6 + 7 to synthesize and push each cross-team dependency/risk to a resolution owner.
4. Chain to `delivery-engine` Mode G to record program-increment RAID entries.
5. Render the ART dependency & PI-risk read: the ranked cross-team dependency edges and PI-level risks, each with owner, status, and a reversibility tier + confidence.

**Output:** an ART Dependency & PI-Risk read — the ranked cross-team dependency edges (sourced to the composed `delivery-engine` Mode E roll-up) and program-increment risks (sourced to the composed `ppm-agent` Sections 6/7), each with its resolution owner and a reversibility tier + confidence.

### Mode 3 — Program-Flow & Impediment Escalation
1. Chain to `delivery-engine` Mode E for the cross-team flow / velocity-as-range read; identify where ART flow is stalling.
2. For each impediment, determine whether it is removable at the program-increment layer (an RTE facilitation action) or requires escalation above the ART.
3. Chain to `delivery-engine` Mode G to record each impediment as a RAID Action with owner + due date.
4. Chain to `ppm-agent` Section 6 for the stale-RAID auto-escalation pass and Section 10 to frame the `[COMMS]`-routed escalation for the impediments the RTE cannot remove.
5. Render the impediment & flow read: the ART flow-health status, the removable impediments (with the facilitation action), and the escalation-required impediments (with the routed escalation), each carrying a reversibility tier + confidence.

**Output:** an ART Flow & Impediment read — flow-health status (sourced to the composed `delivery-engine` Mode E), the removable-vs-escalation impediment split, and the routed escalations (framed via the composed `ppm-agent` Section 10).

### Mode 4 — ART Release-Readiness Synthesis
1. Chain to `delivery-engine` Mode F per ART team for the per-team DoD / release-readiness verdict; roll up to the ART-level DoD posture.
2. Establish program-increment objective achievement (which PI objectives are met / partial / missed).
3. **Bind the two passes** (the defining RTE synthesis): for each ART team's DoD verdict and each PI objective, state whether it blocks, conditions, or is non-blocking on the PI-release call — never let the DoD pass and the objective pass run as two disconnected analyses.
4. Chain to `ppm-agent` Section 5 to frame the GO / GO-WITH-CONDITIONS / NO-GO with explicit conditions, the rollback posture, and a reversibility tier + confidence.

**Output:** a PI-Release-Readiness Decision — GO / GO-WITH-CONDITIONS / NO-GO, the binding rationale (which per-team DoD failures and which missed PI objectives gate the verdict and how), the rollback posture, and a reversibility tier + confidence on the call. A PI-release GO is frequently EXPENSIVE-to-IRREVERSIBLE (see §5).

## 4. Role-boundary rationale (vs `pmo-scrum-master` and `pmo-program-manager`)

Deconfliction is **by primary-role + trigger surface, NOT by composed target** — all three roles compose `delivery-engine`, and that overlap is expected and is not a cross-fire. The boundary holds all three ADR-019 skill-boundary conjuncts (distinct trigger surface, distinct write-scope, distinct primary role). SKILL.md `## Dependency Graph Node` carries the boundary table; the rationale below expands the non-cross-fire guarantee.

Under an active SAFe config: the RTE answers PI/ART-shaped triggers; `pmo-scrum-master` answers single-team-sprint triggers (a sprint inside the ART is still a scrum-master concern — the RTE does not absorb it, it coordinates *across* teams); `pmo-program-manager` answers outcome-accountability triggers and is **not** SAFe-gated (it serves any methodology).

- **RTE × scrum-master split** — distinct trigger surface (PI/ART vs single-team), distinct write-scope (ART backlog / PI objectives / program board vs sprint backlog / team artifacts), distinct primary role (ART facilitation vs team-process facilitation). The coordination primitives differ: Program Increment vs Sprint.
- **RTE × program-manager split** — PI/ART-SAFe-facilitation vs methodology-general program-delivery-accountability. The RTE is SAFe-only and facilitation-oriented; the program-manager is methodology-neutral and accountability-oriented. Coordination primitives differ: Program Increment vs Program (workstream set).

## 5. Reversibility — tier vocabulary & worked examples

This skill produces decision-class outputs (the PI plan, the ART dependency/PI-risk read, the impediment escalations, the PI-release-readiness GO/NO-GO). It runs at **Pattern B autonomy** (recommend-then-act with operator confirmation on the program-level call). Every decision-class item carries a reversibility tier paired with a confidence level per [`reversibility-protocol.md`](../../../../core/specs/reversibility-protocol.md). SKILL.md `## Reversibility Discipline` is authoritative; the tier vocabulary and worked examples below expand it.

**Tier vocabulary:**
- **CHEAP** (undo in hours, no stakeholder impact) — state the tier, proceed.
- **MODERATE** (undo in days, small cohort) — state the tier, surface the key assumption in ≤1 sentence, invite a single-reviewer pass.
- **EXPENSIVE** (undo in weeks, multi-stakeholder) — state the tier, document rationale (≥2 sentences), state the rollback plan, name the affected cohort.
- **IRREVERSIBLE** (cannot undo — a shipped PI release, an externally-committed PI commitment) — state the tier, document rationale, state rollback is infeasible or name the counter-commitment, name the sign-off authority, pair with an explicit downside description.

A **PI-release GO is frequently the highest-reversibility output this skill produces** — a GO on a PI release that has shipped to production, or an externally-committed PI commitment, is EXPENSIVE-to-IRREVERSIBLE; the RTE never renders a GO without the tier, the confidence, and (for EXPENSIVE+) the rollback posture. Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* — both travel together. A HIGH-confidence IRREVERSIBLE call still requires a sign-off gate.

**Worked examples:**
- *Mode 1 PI-objective deferral* — "defer the partner-API objective to PI+1 (MODERATE · confidence HIGH): undo is re-scoping next PI; affected cohort is team-3 only [SOURCE: `delivery-engine` Mode D capacity]."
- *Mode 4 PI-release call* — "PI objectives met [SOURCE: `ppm-agent` §5], BUT team-2 DoD FAIL on the migration rollback [SOURCE: `delivery-engine` Mode F] → GO-WITH-CONDITIONS (EXPENSIVE · confidence MEDIUM): rollback runbook required before go-live; affected cohort is the full ART release."
