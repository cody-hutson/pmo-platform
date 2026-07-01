# Skill Compliance Auditor — scenario template + calibration-row schema

Reference detail for `skill-compliance-auditor`. The SKILL.md body carries the
operating instructions; this file holds the two detail-heavy contracts a run
consumes — the three-strictness scenario template (Stage 1) and the trigger-rate
calibration-row schema (Stage 4 output). Externalized per the D-Refs / K1↔K2
load-vs-reference boundary (`core/standards/canonical-skill-structure.md §5`;
`core/disciplines/knowledge-architecture.md §3`): this is reference-on-demand
detail, not always-load operating instruction.

<!-- reference-durability: allow-link -->

## 1. The three-strictness scenario template (Stage 1)

The scenario set is **template-first hybrid**: the template fixes the *structure*
of the three strictness slots (deterministic, reproducible across runs); an LLM
fills only the *domain-specific prose* within each fixed slot. Reproducible
structure is what makes a compliance-rate delta between two runs interpretable as
skill-drift rather than scenario-noise.

For a target skill `S` with declared trigger phrases `T(S)`, domain `D(S)`, and
sibling set `Sib(S)` (skills whose `description:` trigger surface overlaps `S`,
read from the `registry.md` routing view):

| Slot | Fixed structure (template) | LLM-filled (domain prose) | What it diagnoses |
|---|---|---|---|
| **explicit** | A request that names ≥1 phrase from `T(S)` verbatim. | The surrounding task prose in `D(S)`. | Baseline firing — does `S` fire when explicitly named? A miss here is a hard trigger break. |
| **neutral** | A request that describes a task in `D(S)` using **none** of the phrases in `T(S)`. | The domain task, phrased naturally without trigger words. | `description:` health — does `S` fire on the domain task when the trigger words are absent? A pass-on-explicit / fail-on-neutral is the canonical `description:`-drift signal. |
| **competing** | A request where `S` and ≥1 member of `Sib(S)` both plausibly apply; the prompt names neither skill. | A task sitting in the overlap of `D(S)` and a sibling's domain. | Trigger-surface collision — does `S` lose the request to a sibling? Requires the LLM judge (below) to decide whether the *right* skill fired. |

**Reproducibility rule.** The template seed (the fixed slot structure + the
`T(S)`/`D(S)`/`Sib(S)` inputs resolved from the corpus) is recorded with each run
and re-used for trend comparisons on the same target, so a rate delta is
attributable to `S` and not to a regenerated scenario set. Do **not** regenerate
scenarios freely from an LLM run-to-run — that drifts the measuring instrument
underneath the metric.

## 2. Trace classification — deterministic-first (Stage 3)

Classification is **deterministic-first**; the LLM judge is reserved only for the
one question a grep cannot answer.

- **Structural (deterministic, all slots):** grep the captured tool-call trace for
  the target skill's Skill-tool invocation. Emit `fired` (present, at the right
  point), `sibling-captured` (a *different* Skill-tool call is present), or
  `not-fired` (no Skill-tool call). An unreadable/absent trace is `capture-failed`
  — never scored as fired or not-fired. `scripts/measure-skill-compliance.sh
  --classify <skill> <trace-file>` implements this and is self-tested (including a
  substring-boundary assertion so `S` does not match a longer sibling name).
- **LLM judge (competing slot only):** the structural check answers "did `S`
  fire?"; on a competing scenario it cannot answer "was firing (or not firing)
  *appropriate*?" when two skills legitimately overlap. A binary LLM judge decides
  `appropriate` / `inappropriate` for the competing slot only. This mirrors the
  eval-writing consensus (binary structural checks first; an LLM judge only where
  judgment is irreducible). If the judge is unavailable, the competing slot is
  reported `structural-only (judge unavailable)` rather than erroring.

## 3. The trigger-rate calibration-row schema (Stage 4 output)

Each Measure run appends one row per target skill to the shared calibration-data
surface at `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md`, under the
**`trigger-rate` metric class** (the class reserved in the ADR authored with this
skill). The class name and namespace are fixed there so no other consumer of the
shared surface (the `gate-evaluation-spec.md` calibration framework, a future
`eval-writer` enhancement) collides with it.

Row fields:

| Field | Meaning | Evidence label |
|---|---|---|
| `metric_class` | Always `trigger-rate` (the reserved namespace). | `[SOURCE]` |
| `target_skill` | The skill measured. | `[SOURCE]` |
| `run_date` / `sha` | Survey date + repo SHA at the run. | `[SOURCE]` |
| `explicit_rate` | fired ÷ explicit scenarios. | `[SOURCE]` (structural tally) |
| `neutral_rate` | fired ÷ neutral scenarios. | `[SOURCE]` |
| `competing_rate` | appropriate ÷ competing scenarios (judge-incorporated). | `[INFERRED]` (judge-graded) |
| `scenario_cap` | The per-run scenario-count cap that applied. | `[SOURCE]` |
| `judge_invoked` | Whether the competing-slot LLM judge ran. | `[SOURCE]` |

The append is additive — it never rewrites an existing row or another consumer's
class. Retiring the skill retires the `trigger-rate` class from the surface.

## 4. Reading the rates

- **explicit low** → a hard trigger break (the skill does not fire even when
  named); highest-priority `description:` fix.
- **explicit high, neutral low** → `description:` drift (fires when named, misses
  the domain task); the canonical signal this skill exists to surface.
- **competing low** → sibling-capture / trigger-surface collision; the fix is a
  trigger-surface disambiguation between `S` and the capturing sibling, not a
  broadening of `S`.

A flagged rate names the diagnostic and the operator's lever; it is `[RECOMMENDED]`
advisory input to the operator's own `description:`-edit decision, never an edit
the skill performs.
