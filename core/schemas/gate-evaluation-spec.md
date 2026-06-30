---
title: Gate Evaluation Specification
purpose: Defines the three-layer assessment protocol for stage-gate transitions — how to evaluate gate readiness (metrics, judgment, calibration) and whether to proceed.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the handoff-coordinator-spec (invokes it at each boundary); gate-criteria-spec.md (the WHAT it assesses); every stage-transition gate
---
<!-- reference-durability: allow-link -->
# Gate Evaluation Specification

Defines the three-layer assessment protocol for stage-gate transitions: how to evaluate gate readiness (metrics, judgment, calibration) and whether to proceed (decision matrix). This file defines HOW to assess and WHETHER to proceed. For WHAT each gate checks (criteria definitions), see [gate-criteria-spec.md](gate-criteria-spec.md). For field state per stage (structural gates), see [field-lifecycle-matrix.md](field-lifecycle-matrix.md). For artifact deliverables per boundary, see [stage-io-contracts.md](stage-io-contracts.md).

**Relationship to the architecture stack:**
- [gate-criteria-spec.md](gate-criteria-spec.md) — defines WHAT gates check: criteria with ID/Criterion/Type/Check/Automation fields. This file consumes those criteria by routing through the `Check` column.
- [field-lifecycle-matrix.md](field-lifecycle-matrix.md) — defines field state per stage and structural gate requirements. Evaluation validates these structural gates first (inheritance sequence).
- [stage-io-contracts.md](stage-io-contracts.md) — defines artifact deliverables per stage boundary. Gates validate field/anchor/artifact state; I/O contracts validate handoff completeness.
- [calibration-data.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) — tracks assessment accuracy over time. Fed by this protocol; consumed by calibration layer.
- [pipeline/](../../release/references/pipeline/) — §7 Stage-Transition Gate sections provide per-stage criteria for Gates 4+.
- [review-composition-framework.md § 6 Calibration Ledger](../standards/review-composition-framework.md) — extends Layer 3 (Calibration) with per-dimension judge-vs-operator agreement tracking at [`<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/`](<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/). Stage-gate accuracy (this protocol) and per-dimension judge-vs-operator agreement (the framework's ledger) cover distinct domains.

**Consumers:**
- Handoff coordinator — will consume this protocol as transition input (Phase 2+)
- Agents executing stage transitions — read this protocol at each boundary

---

## Schema

**Schema version:** 1.0
**Introduced in:** v7.5

---

## Boundary Source Mapping

The evaluator consumes criteria from two source paths depending on the boundary:

| Boundary Range | Criteria Source | Metrics Source | Judgment Source |
|---|---|---|---|
| Gates 1→2, 2→3, 3→4 | [gate-criteria-spec.md](gate-criteria-spec.md) structured tables | Evaluator's per-boundary computed metrics (below) + aggregate pass rates from structural criteria | gate-criteria-spec.md `Check=judgment` criteria |
| Gates 4→5 through 12→13 | each [`pipeline/stage-NN-*.md`](../../release/references/pipeline/) §7 Metrics line | §7 Metrics line (comma-separated, verified against GitHub/file state) | §7 Judgment dimensions (named, 1-5 scaled) |

**Two assessment paths:**
- **Path A (Structured):** gate-criteria-spec.md tables — route by `Check` column. Used for Gates 1-3 where structured criteria exist.
- **Path B (Semi-structured):** each `pipeline/stage-NN-*.md` §7 (Stage-Transition Gate) prose — parse Metrics/Judgment/Calibration sections. Used for Gates 4+ where criteria are enumerated in stage definitions.

**Convergence path:** Future releases may extend gate-criteria-spec.md to cover Gates 4+, converging all boundaries to Path A. The dual-source model is necessary for boundaries not yet covered by gate-criteria-spec.md.

---

## Three-Layer Assessment Protocol

At each stage boundary, the executing agent performs a three-layer assessment:

### Layer 1: Metrics (Deterministic)

Compute deterministic criteria from GitHub state or file state. Report PASS/FAIL per metric with actual value vs. threshold.

**Source mapping:**
- **Gates 1-3 (Path A):** Evaluate gate-criteria-spec.md criteria where `Check=structural` as binary PASS/FAIL. Compute per-boundary metrics (see Per-Boundary Computed Metrics below). Aggregate: `structural_pass_rate = structural_passes / total_structural_criteria`.
- **Gates 4+ (Path B):** Parse §7 Metrics line. Each named metric verified against GitHub/file state. Report PASS/FAIL per metric.

**Default thresholds:**
- Structural pass rate: = 1.0 (all structural criteria must pass)
- Ratio metrics (dependency satisfaction, contention density, etc.): ≥ 0.8 unless boundary-specific threshold overrides
- Capacity utilization: ≤ 1.2

Thresholds are adjustable post-calibration (see Calibration layer).

### Layer 2: Judgment (LLM-Graded)

LLM-assess qualitative dimensions on a 1-5 scale. Each score requires a 1-2 sentence evidence summary. Scores without evidence are invalid.

**Scoring rubric (all boundaries, all judgment criteria/dimensions):**

| Score | Label | Definition |
|---|---|---|
| 5 | Exceptional | Exceeds standard, no concerns, sets a reusable pattern |
| 4 | Strong | Meets all requirements, minor notes only |
| 3 | Adequate | Meets minimum bar, some concerns worth noting |
| 2 | Weak | Below standard, specific deficiencies that should be remediated |
| 1 | Failing | Does not meet requirements, blocks proceeding |

**Source mapping:**
- **Gates 1-3 (Path A):** Score each gate-criteria-spec.md criterion where `Check=judgment` individually (e.g., G1-02 "Description is actionable," G3-04 "Scope is implementation-ready").
- **Gates 4+ (Path B):** Score each §7 Judgment dimension (e.g., Stage 5: "design specificity, architecture alignment, blast radius coverage, decision quality, handoff completeness" — 5 dimensions, each scored 1-5).

### Layer 3: Calibration (Self-Updating)

Compare the current assessment against historical data when available.

**Data source:** [calibration-data.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md)

**Availability:**
- When < 3 records exist for this boundary: note "Insufficient calibration data (N records). Threshold adjustment not yet available."
- When ≥ 3 records exist: include historical comparison table in assessment output. Report accuracy trend (improving/stable/degrading).

**Recalibration triggers:**
1. After each Stage 13 close: fill outcome columns for all assessment rows in that release.
2. Accuracy < 70% for a boundary: flag boundary for threshold review. The assessment at that boundary should note the calibration warning.
3. 3+ consecutive PROCEED WITH CAVEATS at the same boundary: pattern investigation — are caveats chronic or did thresholds drift?

---

## Consumer Contract: gate-criteria-spec.md

The evaluator routes gate-criteria-spec.md criteria by the `Check` column:

| Check Value | Evaluator Action | Assessment Output |
|---|---|---|
| `structural` | Binary field presence/format check against GitHub issue state | PASS/FAIL per criterion |
| `judgment` | LLM assessment against criterion description using scoring rubric | 1-5 score per criterion with evidence |

**Aggregation:** Structural criteria pass rate feeds the metrics layer as a computed metric.

**Inheritance:** Per gate-criteria-spec.md §Inheritance Rules — validate the inherited structural gate (from field-lifecycle-matrix.md) first. If the structural gate fails, the named gate fails without evaluating additional criteria. If the structural gate passes, evaluate named gate criteria.

**Tier-branched criteria:** Some `gate-criteria-spec.md` criteria branch evaluation rules on the issue's primary intake-tier label. When evaluating a tier-branched criterion, the evaluator MUST route label-first BEFORE applying the structural/judgment Check column:

1. Read the issue's labels via `gh issue view <N> --json labels --jq '.labels[].name'`.
2. Identify the primary intake-tier label: `observation` or `improvement`. Per `pipeline/stage-01-intake.md` §5 Routing these are mutually exclusive at well-formed intake.
3. Apply the criterion branch matching the present tier label:
   - `observation` present → apply the observation branch text.
   - `improvement` present (and `observation` absent) → apply the improvement branch text.
   - Neither present → FAIL the criterion with self-repair pointing to `intake-style-guide.md` §2.
   - Both present → FAIL the criterion with self-repair directing label disambiguation.
4. Pass the selected branch text (only) to the LLM judgment evaluator. The LLM never sees the inactive branch — branch routing is upstream of scoring.

**Identification:** Tier-branched criteria are identified in `gate-criteria-spec.md` by a `Tier-branched:` prefix in the Criterion column. Registry:

| Criterion ID | Branches | Source |
|---|---|---|
| G1-02 | `improvement` (Description actionable) / `observation` (three fields promotable) |  |

**Three assessment methods (mapped to three layers):**
1. **Structural criteria** (from gate-criteria-spec.md `Check=structural`) → binary PASS/FAIL → feeds metrics layer
2. **Computed metrics** (from evaluator's per-boundary definitions below) → value vs. threshold → PASS/FAIL → feeds metrics layer
3. **Judgment criteria** (from gate-criteria-spec.md `Check=judgment`) → LLM 1-5 score → feeds judgment layer

---

## Per-Boundary Computed Metrics

### Gate 3→4 (Bundle → Planning)

| Metric | Formula | Source | Threshold |
|---|---|---|---|
| Dependency satisfaction | `deps_in_compatible_states / total_deps` | GitHub API: check each dependency's issue status. Compatible = Approved/Bundled/Done. | ≥ 0.8 |
| Scope coherence | `shared_affected_files / total_unique_files` | Parse Affected Files from issue bodies, compute cross-issue overlap. | Report only (informational density metric, no threshold) |
| Capacity utilization | `bundle_size / capacity_heuristic` | bundle_size = Milestone issue count. capacity_heuristic = rolling max of last 5 releases. | ≤ 1.2 |
| Contention density | `files_with_2+_issues / total_unique_files` | Cross-issue affected-files analysis. | ≤ 0.5 |
| Structural pass rate | `gate_criteria_structural_passes / total_structural_criteria` | gate-criteria-spec.md G3-01 through G3-06 `Check=structural` criteria (G3-01, G3-02, G3-03, G3-06 = 4 structural). | = 1.0 |

**capacity_heuristic computation:** Rolling max of last 5 releases (Milestone issue counts). When fewer than 5 releases exist, use max of all available releases.

### Gates 1→2, 2→3

These boundaries use `structural_pass_rate` as the sole metrics-layer input:
- Gate 1→2: `structural_pass_rate` from gate-criteria-spec.md Gate 1 `Check=structural` criteria (G1-01, G1-03, G1-05a, G1-06, G1-07 = 5 structural). Threshold: = 1.0.
- Gate 2→3: `structural_pass_rate` from gate-criteria-spec.md Gate 2 `Check=structural` criteria (G2-03, G2-04, G2-05, G2-06, G2-07 = 5 structural). Threshold: = 1.0.

Per-boundary computed metrics for these gates are future enhancement material.

### Gate 4→5/6 (Planning → Solutioning/Engineering)

Applies to the Planning exit boundary — Path A routes through Stage 5 (Solutioning activated), Path B routes directly to Stage 6 (Solutioning skipped per applicability matrix). Both paths consume the same release plan, so the same metrics gate both routings.

| Metric | Formula | Source | Threshold |
|---|---|---|---|
| Dependency sequence integrity | `issues_in_sequence / total_bundle_issues` | Release plan Implementation Sequence | = 1.0 |
| File change matrix coverage | `issues_with_affected_files_matrix / total_issues` | Release plan File Change Matrix | = 1.0 |
| Risk register density | `risks_registered / max(3, bundle_size / 3)` | Release plan Risk Register | ≥ 1.0 (informational) |
| Verification plan specificity | Per-issue `has_verification_step`, averaged | Release plan Verification Plan | ≥ 0.9 |
| Delivery strategy completeness | `all(branch_named, merge_approach, rollback)` | Release plan Delivery Strategy | = TRUE |
| Contention detection coverage | `files_in_matrix == files_from_issue_bodies` | Cross-check matrix vs. issues | = TRUE |

### Gate 5→6 (Solutioning → Engineering — Path A only)

Applies only when Solutioning was activated for the release (Path A). When Solutioning was skipped (Path B), Engineering receives Planning-level specs directly and this gate does not fire.

| Metric | Formula | Source | Threshold |
|---|---|---|---|
| ADR closure | `adr_closed / adr_opened` | GitHub Issues with `adr` label + milestone | = 1.0 |
| Design spec depth | Per-issue `has_structure_detail`, averaged | Stage 5 outputs | ≥ 0.8 |
| Blast radius mapping | `issues_with_blast_radius / total_issues` | Stage 5 outputs | = 1.0 |

### Gate 6→7 (Engineering → Dev Testing)

Source:  (Phase 1 Foundation). Extracted from pipeline/stage-06-engineering.md §7 Metrics line; formalized per evaluator-metric schema.

| Metric | Formula | Source | Threshold |
|---|---|---|---|
| Commit coverage | `issues_with_commits / total_release_issues` | `git log --grep` against Milestone issue list | = 1.0 |
| Sub-task closure | `eng_subtasks_closed / total_eng_subtasks` | `gh issue list` for Stage 6 sub-tasks in Milestone | = 1.0 |
| PR metadata completeness | `all([milestone, labels, assignee, reviewer, project])` | `gh pr view --json` | = TRUE |
| Verification evidence density | `issues_with_verification_block / total_issues` | PR body parse for Verification Evidence section | = 1.0 |
| Deployed-copy sync status | `diff(source, deployed_copy) == 0` per mirror file | `core/deploy/deploy.sh --check` | = TRUE |
| Undocumented deviations | `deviations_unlogged / total_deviations` | Release-plan deviation log vs. PR diff | = 0 |
| Layer boundary compliance | `files_changed_in_layer_2 == 0` | `git diff --stat` filtered by `projects/` | = TRUE |

**Judgment dimensions:** Consumed from pipeline/stage-06-engineering.md §7 (implementation fidelity, convention compliance, verification thoroughness, deviation handling, PR reviewability). No new dimensions defined here.

**Structural pass rate:** Aggregate of boolean-gated rows above.

### Gates 7→8 through 12→13

Consume each `pipeline/stage-NN-*.md` §7 (Stage-Transition Gate) Metrics line directly. Each named metric verified against GitHub/file state. No additional evaluator-defined metrics at present. Per-boundary computed metrics may be added as calibration data validates which metrics have discriminating power.

---

## Decision Matrix

| Metrics Pass Rate | Judgment Avg | Judgment Floor | → Recommendation |
|---|---|---|---|
| = 100% | ≥ 3.0 | ≥ 2 | **PROCEED** |
| ≥ 80% | ≥ 3.0 | ≥ 2 | **PROCEED WITH CAVEATS** (list failing metrics) |
| = 100% | ≥ 3.0 | 1 | **PROCEED WITH CAVEATS** (flag critical-weakness dimension) |
| ≥ 80% | ≥ 3.0 | 1 | **PROCEED WITH CAVEATS** (list failing metrics + flag critical-weakness dimension) |
| = 100% | < 3.0 | ≥ 2 | **HOLD** (judgment average below threshold) |
| ≥ 80% | < 3.0 | any | **HOLD** (judgment average below threshold) |
| < 80% | any | any | **HOLD** (metrics insufficient) |
| any | any | 1 (multiple) | **HOLD** (multiple critical weaknesses) |

**Calibration modifier (when ≥3 records exist for boundary):**
- Historical accuracy ≥ 70%: use matrix as-is (thresholds reliable)
- Historical accuracy < 70%: append "CALIBRATION WARNING" to recommendation; recommend threshold review before next release
- Historical accuracy ≥ 90% for 5+ releases: may relax metrics threshold to ≥ 70% for PROCEED WITH CAVEATS (pending operator approval)

**Confidence derivation:**
- **HIGH:** PROCEED with ≥ 90% metrics pass + judgment avg ≥ 4.0
- **MED:** PROCEED or PROCEED WITH CAVEATS with metrics 80-100% + judgment avg 3.0-3.9
- **LOW:** any HOLD, or PROCEED WITH CAVEATS with metrics < 90% or judgment avg < 3.5

---

## Assessment Output Template

```markdown
## Gate Assessment: [Boundary Name]

**Version:** vX.Y | **Boundary:** Stage N → N+1 | **Date:** YYYY-MM-DD

### Metrics Layer
| Metric | Threshold | Actual | Result |
|---|---|---|---|
| [metric name] | [expected] | [value] | PASS/FAIL |
**Pass rate:** X/Y (Z%)

### Judgment Layer
| Dimension/Criterion | Score | Evidence |
|---|---|---|
| [name or ID] | N/5 | [1-2 sentence justification] |
**Average:** X.X | **Floor:** X

### Calibration (when ≥3 records exist)
| Prior Version | Confidence | Rec | Outcome Items | Escapes | Accuracy |
|---|---|---|---|---|---|
| vX.Y-2 | ... | ... | ... | ... | ... |
**Trend:** [improving/stable/degrading]

### Recommendation
**Confidence:** HIGH/MED/LOW
**Decision:** PROCEED / PROCEED WITH CAVEATS / HOLD
**Rationale:** [one sentence]
**Caveats:** [if applicable — list failing metrics or weak dimensions]
```

---

## Architecture Path

| Phase | When | Mechanism | Advancement Criteria |
|---|---|---|---|
| **Phase 1: Manual Protocol** | Current | Agent reads gate-evaluation-spec.md at each boundary. Manually computes metrics from GitHub (`gh` CLI). LLM-scores judgment dimensions. Posts assessment in stage review comment. Records calibration row. | ≥3 releases calibrated + manual assessment >15 min/boundary + threshold adjustment performed ≥1 time + handoff coordinator operational |
| **Phase 2: Standalone Skill** | Future release | Skill auto-computes metrics via `gh` CLI, auto-scores judgment from issue/PR state, produces structured assessment output matching per-skill-output-contracts.md pattern. Per-boundary config (YAML or per-stage sections). | Skill produces reliable assessments (accuracy ≥80%) + operator not overriding PROCEED recommendations + inter-stage orchestration exists |
| **Phase 3: Orchestration Layer** | Future release | Auto-invoked at stage transitions by handoff coordinator. No manual trigger — evaluator runs as part of transition protocol. Human sees assessment in stage review comment. | Pipeline operates with minimal human intervention at non-Tier 3 gates |

**Phase 2 trigger:** File a GitHub Issue for skill creation when Phase 1 advancement criteria are met.

---

## Interaction with QA Checkpoints

The QA checkpoint capability defines 4 QA checkpoints at specific pipeline locations. These are complementary — QA checkpoints define WHAT to check at 4 locations, the evaluator defines HOW to assess and WHETHER to proceed at ALL locations.

| QA Checkpoint | Stage Boundary | Evaluator Interaction |
|---|---|---|
| DoR gate at Triage | 1→2 / 2→3 | Checkpoint criteria feed evaluator's metrics layer as structural checks |
| Dependency check at Solutioning | 4→5 / 5→6 | Checkpoint criteria extend evaluator's metrics layer |
| Pre-merge QA | 7→8 / 8→9 | QA-specific criteria — evaluator assesses the gate, not the QA test itself |
| Post-deploy verify | 12→13 | Checkpoint criteria feed evaluator's metrics layer at close gate |

When QA checkpoints are implemented, the evaluator can consume them as additional metrics-layer inputs at the corresponding boundaries without modification to this file.

---

## Versioning

**Schema version:** 1.1
**Introduced in:** v7.5

**v1.1 changes (non-breaking — minor):**
- Added "Tier-branched criteria" routing protocol to Consumer Contract. Backwards-compatible: criteria without `Tier-branched:` prefix evaluate identically to v1.0. Forward-extends: tier-branched criteria route by primary intake-tier label before LLM judgment evaluation.

Schema consumers (handoff coordinator) should reference the schema version to detect breaking changes. Breaking changes (section additions, decision matrix modifications, assessment template changes) increment the major version. Non-breaking changes (new per-boundary metrics, calibration trigger refinements) increment the minor version.
