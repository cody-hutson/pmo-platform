---
title: Handoff Coordinator Specification
purpose: "Defines the orchestration layer above the gate evaluator — how stage transitions are orchestrated at each pipeline boundary: contract pre-check, gate invocation, state-transition mechanics, and trend reporting."
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the hub orchestrating stage transitions; gate-evaluation-spec.md and gate-criteria-spec.md; stage-io-contracts.md; the iteration-tracking and trend-reporting consumers
---
# Handoff Coordinator Specification

Defines the orchestration layer above the gate evaluator. Specifies HOW stage transitions are orchestrated at each pipeline boundary: contract pre-check, gate invocation, state transition mechanics, iteration tracking, and trend reporting. Consumes contract validation ([stage-io-contracts.md](stage-io-contracts.md)), gate evaluation ([gate-evaluation-spec.md](gate-evaluation-spec.md)), and inter-stage feedback tiers. Does NOT define what gates check (criteria — [gate-criteria-spec.md](gate-criteria-spec.md)) or how gates assess (three-layer protocol — [gate-evaluation-spec.md](gate-evaluation-spec.md)) — those remain evaluator responsibilities.

**Relationship to architecture stack:**
- [gate-criteria-spec.md](gate-criteria-spec.md) — defines gate criteria (WHAT)
- [gate-evaluation-spec.md](gate-evaluation-spec.md) — defines three-layer assessment (HOW to assess)
- [stage-io-contracts.md](stage-io-contracts.md) — defines artifact deliverables per boundary
- Inter-stage feedback protocol — defines return-to-upstream tiers (consumed in Phase 4)
- [calibration-data.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) — assessment records (per gate-evaluation-spec.md schema)
- [iteration-log.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md) — re-entry event history (this file's schema)
- **handoff-coordinator-spec.md (this file)** — orchestrates all of the above

**Consumers:**
- Agents executing stage transitions — read this protocol at each boundary

**Schema version:** 1.0

---

## Separation of Concerns (Coordinator vs. Evaluator)

The evaluator (per gate-evaluation-spec.md) is pure and read-only: given a boundary context, it computes metrics, scores judgment, and returns a recommendation. It has no side effects. The coordinator wraps the evaluator and adds the orchestration concerns a transition actually requires:

| Coordinator Adds | Beyond the Evaluator |
|---|---|
| **Contract pre-check** | Validates required artifacts per [stage-io-contracts.md](stage-io-contracts.md) BEFORE invoking the evaluator. Missing artifact = HOLD without running the evaluator at all. |
| **State transition mechanics** | Side effects that advance the pipeline: GitHub Projects Stage/Status field updates, `status:` label changes, sub-task close/open, stage review comment posting. |
| **Iteration counter** | Tracks re-entries across invocations at the same boundary. Increments on Tier 2 scope-change return; escalates when boundary-specific cap is exceeded. |
| **Feedback routing** | On downstream return per the inter-stage feedback protocol — Tier 1 logs only, Tier 2 re-invokes upstream stage, Tier 3 escalates and suspends. |
| **Cross-boundary trend synthesis** | At Stage 13, aggregates per-boundary patterns across the release (chronic caveats, cycle time, iteration frequency, confidence correlation) into a Milestone rollup. |

**Anti-pattern guardrail:** The coordinator MUST NOT reimplement gate assessment logic. Metrics computation, judgment scoring, calibration comparison, and the decision matrix all live in [gate-evaluation-spec.md](gate-evaluation-spec.md) and must be consumed — not duplicated. If coordinator logic starts computing pass rates or scoring dimensions, the boundary between the two specs has been violated.

---

## Five-Phase Orchestration Protocol

At each stage boundary, the executing agent runs all five phases in order. A phase that produces HOLD terminates the protocol — subsequent phases do not execute.

### Phase 1: Pre-Transition Validation

**Purpose:** Confirm the handoff payload exists and is complete before spending assessment cycles on it.

**Input:** The upstream stage's "Output for Stage N+1" comment or artifact set, plus the [stage-io-contracts.md](stage-io-contracts.md) boundary contract.

**Procedure:** Match each required artifact in the contract against the actual handoff. For each CONDITIONAL artifact, evaluate the condition and apply its required/not-required state. Run each contract Validation rule.

**Output:**
- **PASS** → proceed to Phase 2.
- **HOLD** → terminate protocol. Post a `[HOLD — CONTRACT INCOMPLETE]` comment identifying missing/malformed artifacts and the specific contract validation rule violated. Do not invoke the evaluator.

**Note:** When no boundary contract exists yet (per stage-io-contracts.md Future Boundaries), Phase 1 degrades to a checklist of the upstream stage's §6 Outputs. Log the degraded check.

### Phase 2: Gate Evaluation

**Purpose:** Invoke the three-layer assessment.

**Input:** Boundary context: boundary name (e.g., "Stage 4 → Stage 5"), version (Milestone), artifact set from Phase 1, calibration history (if ≥3 records exist).

**Consumption contract:**
- Coordinator passes boundary context to the evaluator.
- Evaluator returns: metrics table (PASS/FAIL per metric), judgment table (score + evidence per dimension), calibration comparison (when available), recommendation (PROCEED / PROCEED WITH CAVEATS / HOLD), confidence (HIGH/MED/LOW), and caveats list.

**Output:** Structured evaluator response forwarded to Phase 3 as the routing input. Evaluator also appends its assessment row to [calibration-data.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) — the coordinator does not write that file.

### Phase 3: Transition Routing

**Purpose:** Apply the evaluator recommendation as concrete state changes.

**Routing by recommendation:**

| Recommendation | Coordinator Action |
|---|---|
| **PROCEED** | Advance stage anchor (`gh project item-edit` → Stage = N+1). Update `status:` label. Close the upstream sub-task. Post stage review comment with evaluator output. Open the downstream sub-task if not already present. |
| **PROCEED WITH CAVEATS** | Same state transitions as PROCEED, plus: post caveats in the stage review comment under a `## Caveats` heading, and record the caveat set in the release plan's Deviation Log. Downstream stage receives the caveats as input. |
| **HOLD** | Do NOT advance stage anchor. Post `[HOLD]` comment with evaluator output. Escalate to operator per the Tier 3 signal from the inter-stage feedback protocol. Upstream stage remains In Progress. |

**CLI primitives used:**
- `gh project item-edit --id <item> --field-id <Stage> --single-select-option-id <N+1>`
- `gh issue edit <N> --add-label "status: <target>" --remove-label "status: <prior>"`
- `gh issue close <sub-task>` / `gh issue reopen <sub-task>`
- `gh issue comment <N> --body-file <comment>`

**Note:** All state changes are Tier 1 (auto-execute) under Phase 1 (Manual Protocol) — see Architecture Path. The operator gate is embedded in evaluator recommendation, not in a separate confirm-before-advance step.

### Phase 4: Iteration State Management

**Purpose:** When the downstream stage returns upstream (per the inter-stage feedback protocol), decide whether to absorb the adjustment, re-invoke, or escalate — and persist the event for trend reporting.

**Trigger:** A downstream stage posts a feedback signal (`[ADJUST]`, `[SCOPE CHANGE]`, or `[PLAN REJECTION]`) targeting this boundary.

**Tier routing (consumes the inter-stage feedback protocol):**

| Tier | Signal | Coordinator Action |
|---|---|---|
| **Tier 1** | `[ADJUST]` commit on release branch | Append a row to [iteration-log.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md) with trigger = `Tier 1`. Do not increment iteration counter. Do not re-invoke upstream stage. Upstream artifact has already been corrected by the downstream fix. |
| **Tier 2** | `[SCOPE CHANGE]` comment on sub-task/Milestone | Increment iteration counter for this boundary. Apply `iteration: N` label to the affected issue(s). Append a row to iteration-log.md with trigger = `Tier 2`. Re-invoke the upstream stage for the affected issue(s) with the downstream finding as input. Re-run the five-phase protocol at the next downstream transition. |
| **Tier 3** | `[PLAN REJECTION]` comment on sub-task | Escalate to operator with the specific blockers. Suspend the affected issue(s) — no further automated transitions until operator resolves. Append a row to iteration-log.md with trigger = `Tier 3`. Do not advance or re-invoke automatically. |

**Iteration cap enforcement:**
- Default cap: **2 iterations per boundary per release**.
- On iteration count exceeding the cap: escalate to operator regardless of tier. Append a row with trigger = `Cap Exceeded`. Suspend the affected issue(s).
- Boundary-specific overrides (see Boundary-Specific Iteration Caps below) supersede the default.

**Iteration counter scope:** Per boundary, per release, per affected issue. A Tier 2 return at Stage 7 → Engineering for issue #X increments #X's counter at that boundary; it does not affect issue #Y's counter at the same boundary or #X's counter at a different boundary.

### Phase 5: Trend Reporting (Stage 13 Only)

**Purpose:** At release close, synthesize the release's boundary-level patterns into a rollup that feeds calibration and process improvement.

**Trigger:** Invoked only at Stage 13 Phase D (release close). Earlier stages do not execute Phase 5.

**Computations:**

| Metric | Formula | Source | Interpretation |
|---|---|---|---|
| Chronic-caveat boundaries | Count of boundaries this release that emitted PROCEED WITH CAVEATS on the same dimension as the prior ≥2 releases | calibration-data.md (joined on boundary + dimension) | Signals threshold drift or systemic upstream gap at that boundary. |
| Cycle time per boundary | Median hours from upstream sub-task open → downstream sub-task open, per boundary, this release | GitHub sub-task timestamps | Identifies slowest boundaries for queue/triage investigation. |
| Confidence correlation | Correlation between evaluator Confidence (HIGH/MED/LOW numeric-mapped) and release outcome (closed-clean / caveat-resolved / escape) | calibration-data.md across ≥5 releases | Confirms or questions the confidence heuristic. Requires ≥5 releases to compute meaningfully. |
| Iteration frequency | Iterations-per-boundary, this release vs. trailing 3-release average | iteration-log.md | Highlights boundaries where this release diverged from baseline quality. |

**Milestone rollup template:**

```markdown
## Release vX.Y — Handoff Trend Rollup

**Boundaries assessed:** N | **PROCEED:** N | **CAVEATS:** N | **HOLDs resolved:** N

### Chronic-Caveat Boundaries
| Boundary | Dimension | Consecutive Releases |
|---|---|---|
| ... | ... | ... |

### Cycle Time (this release)
| Boundary | Median Hours | Δ vs. 3-release avg |
|---|---|---|
| ... | ... | ... |

### Iteration Summary
| Boundary | Iterations | Tier 1 / Tier 2 / Tier 3 |
|---|---|---|
| ... | ... | ... |

### Recommendations
- [Threshold adjustment candidates, if any]
- [Upstream quality interventions, if any]
- [Calibration warnings, if any]
```

**Minimum data requirements:**

| Computation | Minimum Releases | Behavior Below Minimum |
|---|---|---|
| Chronic-caveat detection | 3 (current + 2 prior) | Report "Insufficient history — chronic detection unavailable." |
| Cycle time Δ | 4 (current + 3 prior for baseline) | Report absolute cycle times only; omit Δ column. |
| Confidence correlation | 5 | Omit section with note "Requires ≥5 calibrated releases." |
| Iteration frequency | 4 (current + 3 prior for baseline) | Report absolute counts only; omit Δ. |

---

## Iteration Log Schema

Append-only event log. Exactly one row per re-entry event across all boundaries and releases. Initial transitions (first-time forward progression at a boundary) are NOT logged — only re-entries. Managed by Phase 4.

| Column | Type | Purpose |
|---|---|---|
| **Version** | String | Release in which the iteration occurred (e.g., `v2.06`). |
| **Boundary** | String | Stage boundary (e.g., `Stage 7 → Stage 6`). Uses the direction of the return, not the forward direction. |
| **Issue** | String | GitHub issue number of the affected artifact. |
| **Pass** | Integer | Iteration count post-increment at this boundary for this issue in this release (Tier 1 events use pass 0 since they do not increment). |
| **Date** | ISO-8601 | When the re-entry was recorded (UTC date). |
| **Trigger** | Enum | `Tier 1` / `Tier 2` / `Tier 3` / `Cap Exceeded`. |
| **Return Target** | String | Upstream stage the return is aimed at (e.g., `Stage 6 Engineering`, `Stage 4 Planning`). |
| **Finding Summary** | String | One-line description of what the downstream stage found. |
| **Resolution** | String | Outcome, filled when the iteration is resolved: `fixed` / `scope-adjusted` / `replan` / `suspended` / `deferred`. Written at resolution time, not at entry time. |

**Conventions:**
- Append-only — existing rows are never edited except to fill the Resolution column when the iteration closes.
- One row per re-entry — if the same issue re-enters the same boundary twice, there are two rows.
- Initial transitions are not logged. The log captures iteration, not forward progression.

---

## Boundary-Specific Iteration Caps

| Boundary | Cap | Rationale |
|---|---|---|
| **(default)** | 2 | Two re-entries signal a systemic upstream issue; escalating forces a plan revisit. |
| **Stage 7 → Stage 6 (DT↔Engineering)** | 3 | DT iteration loop established a >3-iteration escalation threshold for `fix(dt):` commits. Aligns coordinator cap to protocol-defined threshold. |

Boundaries not listed use the default cap. New boundary-specific caps are added by updating this table.

---

## Runtime Output Template

The coordinator posts this artifact at each stage exit under `### Handoff Coordinator Runtime` in the stage review comment. Five sections mirror the five phases; skipped phases record their skip reason.

```markdown
### Handoff Coordinator Runtime — [Boundary Name] — vX.Y

**Phase 1 (Contract):** PASS | HOLD
- Contract source: [stage-io-contracts.md boundary link or "degraded — §6 checklist"]
- Artifacts validated: N/N required present. [list missing if any]
- Validation rules: N/N passed. [list failed if any]

**Phase 2 (Evaluator):** invoked | skipped ([reason])
- Recommendation: PROCEED | PROCEED WITH CAVEATS | HOLD
- Confidence: HIGH | MED | LOW
- Full assessment: [link to stage review comment evaluator section]

**Phase 3 (Routing):** executed | blocked ([reason])
- Stage anchor: Stage N → Stage N+1 ✓ | unchanged
- Label transition: `status: <prior>` → `status: <target>` ✓ | unchanged
- Sub-tasks: closed upstream ✓ | opened downstream ✓ | unchanged
- Caveats recorded: N caveats in Deviation Log [link] | none

**Phase 4 (Iteration):** N/A (forward transition) | Tier 1 logged | Tier 2 re-invoked | Tier 3 escalated | Cap Exceeded escalated
- Iteration count (this boundary, this issue): N/M (cap)
- Log entry: [iteration-log.md link]

**Phase 5 (Trend):** N/A (not Stage 13) | posted
- Rollup: [link to Milestone rollup comment] (Stage 13 only)
```

---

## Architecture Path

| Phase | When | Mechanism | Advancement Criteria |
|---|---|---|---|
| **Phase 1: Manual Protocol** | Current | Agent reads handoff-coordinator-spec.md at each boundary. Manually runs five phases: checks contract, invokes evaluator per gate-evaluation-spec.md, executes CLI state changes, handles feedback signals, produces rollup at Stage 13. | ≥3 releases orchestrated + manual coordination >10 min/boundary observed + iteration-log.md populated with ≥10 events + trend rollup produced at ≥1 Stage 13 |
| **Phase 2: Standalone Skill** | Future release | Skill auto-executes all five phases: reads contract, calls evaluator skill (Phase 2), executes GitHub CLI primitives, parses feedback tier signals, generates rollup. Structured input/output matching per-skill-output-contracts.md. | Phase 1 criteria met + gate evaluator operational as a skill + iteration patterns stable enough to automate (no spec churn in last 2 releases) + operator not overriding Phase 3 routing outcomes |
| **Phase 3: Orchestration Layer** | Future release | Skill auto-invoked at every stage sub-task close event. No manual trigger. Coordinator runs protocol and posts Runtime artifact automatically. Operator sees the result, not the steps. | Pipeline operates with minimal human intervention at non-Tier 3 gates + confidence correlation (from Phase 5) validates Phase 2 reliability |

**Phase 2 trigger:** File a GitHub Issue for coordinator skill creation (a future follow-on) when Phase 1 advancement criteria are met. Skill extraction deferred per release plan.

---

## Phased Implementation Status

Tracks  phased work breakdown progress across releases. Updated at each release that advances coordinator phases.

### Phase 1: Foundation

| Deliverable | Status | Release |
|---|---|---|
| Coordinator protocol specification (this file) | Delivered | — |
| Gate 4→5/6 metric set (gate-evaluation-spec.md) | Delivered | — |
| Gate 6→7 metric set (gate-evaluation-spec.md) | Delivered | — |
| Iteration log schema (iteration-log.md) | Delivered | — |
| Release-process.md "Handoff Coordinator Protocol" H3 | Delivered | — |
| pipeline/stage-NN-*.md §7 cross-references (11 sections) | Delivered | — |
| Entry validation (Phase 1 of orchestration protocol) | Delivered | — |
| Future skill structure planning (below) | Delivered | — |

### Phase 2: Skill Extraction

**Status:** Deferred. **Advancement criteria:** see Architecture Path §Phase 2. **Deliverables:** standalone `skills/handoff-coordinator/SKILL.md`, per-boundary YAML config, auto-invocation at stage transitions, `gh`-driven label management.

### Phase 3: Orchestration

**Status:** Deferred. **Advancement criteria:** see Architecture Path §Phase 3. **Deliverables:** pipeline orchestrator auto-invokes coordinator; feedback routing auto-suspends/re-invokes upstream; trend rollup auto-posted to Milestone.

---

## Future Skill Structure (Planning)

**Not a skill definition.** This section documents the intended structure of the future `handoff-coordinator` skill for use by a Phase 2 implementer. Source:  AC-2 planning artifact.

**Planned skill location:** `release/skills/handoff-coordinator/SKILL.md`

**Planned modes (1:1 with orchestration protocol phases):**

| Mode | Trigger | Inputs | Outputs | Autonomy |
|---|---|---|---|---|
| `contract-validation` | Stage N exit handoff | boundary_id, stage_N_output_ref | Phase 1 validation result | Tier 1 (auto) |
| `gate-evaluation` | After contract-validation PASS | boundary_id, stage_N_output_ref | metrics, judgment, recommendation | Tier 2 (recommend) |
| `transition-routing` | After gate-evaluation | recommendation, boundary_id | state-anchor mutations OR escalation | Tier 2 + Tier 3 gate on CAVEATS/HOLD |
| `iteration-tracking` | Downstream return per the inter-stage feedback protocol | tier, boundary_id, finding | label update + log row | Tier 1 (auto) |
| `trend-reporting` | Stage 13 Close | release_version | Milestone rollup comment | Tier 1 (auto) |

**Planned CLI dependencies:** `gh` (project, issue, label, comment); file I/O (iteration-log.md, calibration-data.md, stage-io-contracts.md, gate-evaluation-spec.md); markdown table parsing.

**Planned directory layout:**

```
release/skills/handoff-coordinator/
├── SKILL.md
├── reference/boundary-config.yaml
└── engineering/invocation-examples.md
```

**Advancement trigger:** Architecture Path §Phase 2 criteria (≥3 releases operational + manual invocation >10 min per boundary + iteration cap triggered ≥1 time + calibration accuracy ≥80%).

**Design constraints from Phase 1 protocol:**
- Evaluator stays pure — skill must not conflate assessment with orchestration
- Iteration cap overrides remain boundary-specific (default 2,  → 3)
- Five-phase structure preserved

---

## Versioning

**Schema version:** 1.0

Schema consumers (, boundary-specific protocols) should reference the schema version to detect breaking changes. Breaking changes (phase additions/removals, output template modifications, iteration log schema changes) increment the major version. Non-breaking changes (new boundary-specific caps, additional trend computations, routing refinements) increment the minor version.
