---
title: "Playbook: Stage-Gate Evals"
purpose: The playbook for authoring pipeline stage-gate eval content — the Judgment layer that slots into the three-layer gate assessment protocol at gate-evaluation-spec.md.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Playbook: Stage-Gate Evals

**Invoked by:** "Write the judge for Stage X→Y", "author the calibration content for Gate N", "write the judgment layer for G3-04", or any reference to `gate-evaluation-spec.md`, `gate-criteria-spec.md`, or `pipeline/`.

**Convention assumptions:** This playbook produces content that slots into the existing three-layer gate assessment protocol at `core/schemas/gate-evaluation-spec.md`. It authors the **Judgment layer** (and optionally companion calibration rows). It does not reinvent the Metrics layer — that stays deterministic and lives in the existing criteria spec.

**Dispatches into:** the generic core — `decision-tree.md` rules apply. This playbook adds gate-specific convention knowledge.

---

## Background: the three-layer assessment

Per `gate-evaluation-spec.md`:

1. **Metrics (deterministic):** computed from GitHub state / file state. PASS/FAIL per metric. Structural gate criteria from `gate-criteria-spec.md` (where `Check=structural`) + per-boundary computed metrics.
2. **Judgment (LLM-graded):** qualitative dimensions scored 1–5 with evidence. Each dimension = one criterion (Gates 1-3) or one §7 judgment dimension (Gates 4+).
3. **Calibration (self-updating):** historical comparison from `engineering/evals/results/calibration-data.md` when ≥3 records exist for the boundary.

**This playbook produces Judgment-layer content** — the judge prompts and rubrics that make Layer 2 operational. The spec defines WHERE judgment happens; this playbook authors WHAT the judge reads.

### Relationship to Module 6 rubric templates
Gates use a **1–5 scale** per the spec (not binary). This is a deliberate convention choice — calibration data across multiple releases requires finer resolution than binary, and the evidence-per-score requirement mitigates verbosity bias.

When authoring, use Template 4 (handoff quality) as the structural base for gate-level judgment prompts — gates ARE handoffs (from one stage to the next).

---

## Inputs

- Gate ID (e.g., "Gate 3", "G3-04", "Stage 7→8")
- `gate-evaluation-spec.md` — three-layer protocol
- `gate-criteria-spec.md` — criterion definitions (Check=structural vs Check=judgment)
- `pipeline/stage-NN-*.md` §7 — for Gates 4+, judgment dimensions defined in prose
- `calibration-data.md` — existing calibration schema

## Pre-authoring checks

1. **Which boundary?** Gate N→N+1. Record the transition and both stages.
2. **Which criteria route to judgment?** From `gate-criteria-spec.md`, find criteria with `Check=judgment`. From each `pipeline/stage-NN-*.md` §7 (Stage-Transition Gate), find judgment dimensions. Each gets its own judge prompt.
3. **Does this gate already have judge content?** Look at `core/schemas/gate-prompts/<gate-id>/` if it exists. Author mode = create; Review mode = audit.
4. **Is there calibration data?** Check `calibration-data.md` for this boundary. ≥3 rows = calibration layer is active; <3 = note "insufficient calibration data" in the rubric.

## Author mode workflow

### Step 1 — Enumerate judgment criteria for the gate

For Gates 1-3 (Path A): read `gate-criteria-spec.md`, filter to `Check=judgment`. Example (Gate 3):
```
G3-04: Scope is implementation-ready
G3-05: Bundle rationale is documented
```

For Gates 4+ (Path B): read the specific `pipeline/stage-NN-*.md` §7 (Stage-Transition Gate) entry for the stage, parse Judgment dimensions. Example (Stage 5 exit, from your reading of release-process.md):
```
design specificity, architecture alignment, blast radius coverage, decision quality, handoff completeness
```

### Step 2 — Characterize the gate (Stage 0, adapted)

Gates are **seams in the pipeline MAS**. The characterization 5-tuple adapts:
- Single-agent vs multi-agent: MAS (pipeline is a multi-agent system — skills + operator + stages)
- Tool use: n/a at the gate level (gates evaluate artifacts, not actions)
- HITL: yes (operator renders final decision; agent assessment is advisory)
- Dev vs production: the gate is a production artifact (pipeline is live)
- Safety criticality: varies by gate — Gate 12 (Execute) and Gate 13 (Close) are higher stakes than Gate 1 (Intake)

Because this is a MAS seam, Rule C-A1 + C-A4 (pipeline topology) apply:
- Three-tier portfolio: the gate itself is a seam-level eval
- Handoff rubric (T4) at every seam — this gate IS the rubric

### Step 3 — Write one judge prompt per judgment criterion

Use Template 4 (handoff quality) adapted, OR Template 1 (binary with 1–5 scale override). Each criterion gets:

**Structure:**
```markdown
# Judge: <Gate ID>-<Criterion ID> — <Criterion name>

**Spec source:** gate-evaluation-spec.md §Three-Layer, Layer 2
**Criterion source:** gate-criteria-spec.md <ID> OR pipeline/stage-NN-*.md §7
**Template base:** T4 (handoff quality) adapted to 1–5 scale

## System prompt

You are a release-quality judge for the PMO pipeline at stage boundary <X→Y>.

Your job is to assess <criterion name>: <one-sentence definition from spec>.

Output a single score 1–5 with a 1–2 sentence evidence summary citing specific
artifacts (file paths, GitHub state, issue numbers). Scores without evidence are
invalid.

SCORING RUBRIC (applies to all gate judgment criteria):
- 5 Exceptional: Exceeds standard, no concerns, sets a reusable pattern
- 4 Strong: Meets all requirements, minor notes only
- 3 Adequate: Meets minimum bar, some concerns worth noting
- 2 Weak: Below standard, specific deficiencies
- 1 Failing: Does not meet requirements, blocks proceeding

BIAS GUARDS:
- Do not consider response length of the underlying artifact
- Do not favor specific authors or skills
- If evidence is insufficient to score, output: { score: null, reason: "insufficient evidence" }

## User prompt template

GATE BOUNDARY: {{BOUNDARY}}  (e.g., "Stage 3 → Stage 4")
CRITERION: {{CRITERION_ID}} — {{CRITERION_NAME}}
CRITERION DEFINITION: {{CRITERION_DEFINITION}}

ARTIFACTS IN SCOPE:
{{ARTIFACT_REFERENCES}}

RELEASE CONTEXT:
- Version: {{VERSION}}
- Bundle size: {{BUNDLE_SIZE}}
- Issues: {{ISSUE_NUMBERS}}

EVIDENCE:
{{EVIDENCE_EXCERPT}}

Your score and evidence:

## Substitution variables
- {{BOUNDARY}}: stage transition string
- {{CRITERION_ID}}: e.g., "G3-04"
- {{CRITERION_NAME}}: e.g., "Scope is implementation-ready"
- {{CRITERION_DEFINITION}}: one-sentence from gate-criteria-spec.md
- {{ARTIFACT_REFERENCES}}: file paths / GitHub URLs in scope
- {{VERSION}}: release version
- {{BUNDLE_SIZE}}: Milestone issue count
- {{ISSUE_NUMBERS}}: comma-separated
- {{EVIDENCE_EXCERPT}}: relevant artifact excerpts

## Judge model
Pinned snapshot (A-11). Cross-family with agent-under-evaluation (F-03).
For pmo-platform skills running on claude-opus-4-7: judge = claude-sonnet-4-6.

## CoT handling
Gate artifacts (issues, release plans) don't have CoT per se — only final
authored content. No CoT blinding needed.
```

### Step 4 — Write the rubric file

One `rubrics.md` per gate covering all criteria:

```markdown
# Rubrics: Gate <ID>

## Criterion map
| Criterion ID | Name | Judge file | Score scale |
|---|---|---|---|
| G3-04 | Scope is implementation-ready | `G3-04-scope-readiness.md` | 1-5 |
| G3-05 | Bundle rationale is documented | `G3-05-bundle-rationale.md` | 1-5 |

## Aggregate decision
Per gate-evaluation-spec.md §Decision Matrix:
- All judgment criteria ≥ 4 → PROCEED (strong/exceptional)
- Any criterion at 3 → PROCEED WITH CAVEATS
- Any criterion at 1–2 → HOLD

## Calibration thresholds
- α ≥ 0.80 across ≥30 historical assessments → reliable
- 0.67 ≤ α < 0.80 → add second-family judge for this gate only
- α < 0.67 → rework rubric language (criteria wording), not ensemble (A-10)
```

### Step 5 — Write calibration protocol

```markdown
# Calibration: Gate <ID>

## Gold set
≥30 historical gate assessments with known outcomes (Items, Escapes, Cycle from calibration-data.md).

## Metrics
- Per-criterion precision / recall on the training set
- Krippendorff α: judge vs. operator final decision, across ≥30 assessments
- Position-consistency: criteria independently assessed; no order effect (F-01)

## Reports
Append new assessment rows to `engineering/evals/results/calibration-data.md`.
Accuracy column (last) computed when ≥3 rows per boundary exist.

## Review cadence
- Every release close: fill outcome columns (Items, Escapes, Cycle)
- Accuracy <70% for a boundary: flag for threshold review (recalibration trigger from spec)
- 3+ consecutive CAVEATS at same boundary: pattern investigation
```

### Step 6 — Output path

Default: `core/schemas/gate-prompts/<gate-id>/`
```
gate-prompts/
└── G3/
    ├── G3-04-scope-readiness.md
    ├── G3-05-bundle-rationale.md
    ├── rubrics.md
    └── calibration-protocol.md
```

Alternative paths: propose if you see a better home (e.g., co-locating with criteria in `reference/schemas/` or linking from `engineering/evals/`).

### Step 7 — Hand off

> **Next:** The judge prompts slot into `gate-evaluation-spec.md`'s Layer 2 assessment. Operator (or handoff-coordinator agent) invokes the judges at the boundary and records results in `calibration-data.md`. After ≥3 assessments per boundary, Layer 3 calibration activates automatically.

## Review mode workflow

Similar to per-skill Review, but comparisons are against `gate-evaluation-spec.md`'s protocol:

1. **Structural compliance:** Does the gate have judge content for every `Check=judgment` criterion? Every §7 judgment dimension?
2. **Schema conformance:** Do judge prompts use the 1–5 rubric? Cross-family models? Pinned snapshots? Evidence requirement?
3. **Calibration:** Is the calibration column populated for this boundary's assessments? Accuracy trend reported?
4. **Anti-pattern audit:** Full A-01..A-23 checklist.

Report follows the standard Review report format from SKILL.md.

## Tensions that surface at gates

Module 6 §10 tensions relevant to stage-gates:

- **T-2 Single judge vs ensemble:** For high-stakes gates (Gate 9 Plan Review, Gate 12 Execute), the spec's Rule D-A6 says heterogeneous ensemble (3–5 models). For Gate 3 Bundle, a single-family judge is likely sufficient. Note this in rubrics.md per-gate.
- **T-4 Criteria drift:** Gate criteria evolve across releases. Version rubrics alongside the gate-criteria-spec changes. When the spec updates criteria wording, the judge prompt SHOULD change too — that's Layer 3 recalibration territory.
- **T-11 Handoff length vs fidelity:** The gate artifact excerpt ({{EVIDENCE_EXCERPT}}) has to be enough to judge but not so much it blows context. Default: excerpt the sections directly relevant to the criterion; include full-artifact reference link so the judge can request more if needed.
