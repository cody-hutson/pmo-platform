---
title: "Playbook: Per-Skill Evals"
purpose: The playbook for authoring per-skill eval suites — the artifacts that slot into a skill's evals/ directory and feed the skill-creator harness (evals.json to grading.json to benchmark.json).
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Playbook: Per-Skill Evals

**Invoked by:** "Write evals for <skill>", "audit my evals for <skill>", "what evals does <skill> need", or any reference to a specific pmo-platform skill path (`<module>/skills/<name>/`).

**Convention assumptions:** This playbook produces artifacts that slot into the `<module>/skills/<name>/evals/` directory and are consumed by `anthropic-skills:skill-creator`'s harness (evals.json → grading.json → benchmark.json). If invoked against a non-pmo-platform skill with a different directory convention, adapt paths but preserve artifact semantics.

**Dispatches into:** the generic core — `decision-tree.md` rules fire off the skill's Stage 0 characterization. This playbook adds convention knowledge, not rule logic.

---

## Inputs

- Skill directory path (e.g., `operations/skills/daily-status/`)
- Skill's SKILL.md (for understanding what it does and observable failure modes)
- Any existing evals (`evals/evals.json`) for Review mode
- User-described failure modes (if they've already hand-coded some)
- Existing platform conventions: `.claude/rules/`, `CLAUDE.md`

## Pre-authoring checks

1. **Does the skill already have evals?** If yes, default to Review mode first. Author mode for NEW evals should layer on top of what exists.
2. **Is there a conversation history of failures?** Check `projects/_config/CORRECTIONS.md`, recent issues on the skill, or user's described pain points. These are gold for Stage 2 taxonomy — real observed failures beat imagined ones.
3. **What's the skill's output type?** Code-checkable (structured JSON, markdown with schema, file outputs) → heavy on code assertions. Subjective (prose, communication, decisions) → LLM judges required.

## Author mode workflow

### Step 1 — Read the skill
Read the full SKILL.md. Note:
- What the skill produces (output contract)
- Any "anti-patterns" or "hard rejections" listed
- Any existing test cases or expected behaviors
- References to shared platform rules (e.g., "no generalized dates" from CLAUDE.md quality standards)

### Step 2 — Characterize (Stage 0)
Fill the 5-tuple. For pmo-platform skills:
- **Single-agent vs multi-agent:** usually single-agent (one skill = one dispatch). Multi-agent if the skill explicitly coordinates subagents.
- **Tool use:** yes for skills that read/write files, run scripts, call MCP tools. No for pure generation skills.
- **HITL present:** yes ([OPERATOR_NAME] reviews outputs). This is always yes for pmo-platform.
- **Dev vs production:** dev for in-development skills; "production" in pmo-platform context means "routinely used in workflows."
- **Safety criticality:** routine for most skills. Elevated for skills that touch compliance, finance, or legal artifacts.

### Step 3 — Collect or infer failure taxonomy (Stage 2)
If the user has a trace corpus (past outputs, past failures), read by hand and cluster into binary taxonomy. If not:
1. Read CLAUDE.md quality standards — these are [OPERATOR_NAME]'s already-coded failure modes (e.g., "no generalized dates," "no unmarked recommended dates," "no status theater").
2. Read the skill's SKILL.md for any anti-patterns it already defines.
3. Ask the user 1–3 targeted questions about failures they've observed (stop at 3).
4. Populate `failure-taxonomy.md` with observed + anticipated failures. Map to F-XX where the research supports it. Use local IDs (F-LOCAL-01) when a skill-specific failure doesn't fit.

### Step 4 — Apply the decision tree (Stage 3)
Run rules off the 5-tuple. For a typical pmo-platform skill (single-agent, tool-use=yes, HITL=yes, dev, routine):
- RULE F-A1 fires → Stage 1-4 required
- RULE B-A1 fires if tool-use → T3 + T7
- RULE B-A2 fires if structured output → code assertions preferred

Write the judges per rule.

### Step 5 — Produce artifacts

Populate `<module>/skills/<skill-name>/evals/` with:

**`evals.json`** — anthropic-skills:skill-creator schema:
```json
{
  "skill_name": "<name>",
  "evals": [
    {
      "id": 1,
      "name": "descriptive-name",
      "prompt": "A realistic user prompt that exercises this failure mode",
      "expected_output": "Plain-language description of what a passing output looks like",
      "files": []
    }
  ]
}
```
Aim for one eval per top-prevalence failure mode in the taxonomy. A typical skill needs 3–6 evals.

**`judge_prompts/<name>.md`** — one file per LLM judge:
```markdown
# Judge: <criterion>

**Template:** T1 (binary) — see references/rubric-templates.md
**Failure modes covered:** F-XX, F-YY
**Anti-patterns guarded:** A-04 (binary), A-11 (pinned), A-15 (CoT-blinded if applicable)

## System prompt
[T1 adapted]

## User prompt template
[with substitution variables explicitly listed]

## Substitution variables
- {{INPUT}}: the user prompt that invoked the skill
- {{OUTPUT}}: the skill's produced output
- {{CRITERION}}: <specific binary criterion>

## Judge model
claude-sonnet-4-6 (cross-family with opus-4-7 agent; Module 6 F-03)
Temperature: 0
Pinned snapshot: required (A-11)

## CoT handling
<If agent produces CoT and CoT is adversarially shapeable, blind judge (F-15).
Otherwise, include CoT with caveat.>
```

**`rubrics.md`** — scoring scale and calibration thresholds:
```markdown
# Rubrics: <skill name>

## Scoring scale
Binary PASS/FAIL. Rationale: A-04. No 1–5 scales.

## Per-judge thresholds
| Judge | Pass criterion | Calibration requirement |
|---|---|---|
| <name> | Output satisfies <criterion> | α ≥ 0.80 on 30-item gold set |
```

**`failure-taxonomy.md`** — the binary failure modes:
```markdown
# Failure Taxonomy: <skill name>

## Observed failures (from trace corpus)
| Local ID | Description | F-XX mapping | Prevalence (n / N traces) |
|---|---|---|---|

## Anticipated failures (from decision tree)
| Rule | F-XX | Evaluator type | Coverage |
|---|---|---|---|
```

**`characterization.md`** — the 5-tuple:
```markdown
# Characterization: <skill name>

- Single-agent vs multi-agent: single-agent
- Tool use: [yes/no — enumerate tools]
- HITL: yes ([OPERATOR_NAME] reviews outputs before acting)
- Dev vs prod: [dev/production]
- Safety criticality: routine
- Topology: N/A (single-agent)

## Triggered decision-tree rules
- RULE F-A1 (all systems)
- RULE B-A1 (tool use) [if applicable]
- ...
```

**`calibration-protocol.md`** — how to validate judges:
```markdown
# Calibration Protocol: <skill name>

## Gold set
≥30 hand-labeled examples. Store at `calibration/gold-set.json` (not tracked in main evals/ — treat as separate artifact).

## Labeling rubric
[Binary criteria — same as judge's CRITERION with examples of PASS and FAIL]

## Metrics
- Per-class precision and recall (not raw accuracy — A-03)
- Krippendorff α against human labels (A-07)

## Thresholds
- α ≥ 0.80: reliable; single judge suffices
- 0.67 ≤ α < 0.80: tentative; add second-family judge
- α < 0.67: rework rubric (A-10)

## Bias tests
- Position: pairwise with swap — win counts only if both orders agree (F-01)
- Verbosity: score-vs-length correlation; reject judges with |r| > 0.3 (F-02)
- Self-enhancement: judge model family ≠ agent model family (F-03)
```

### Step 6 — Hand off
Output message ends with:

> **Next:** Run `anthropic-skills:skill-creator` to execute these evals. It will spawn subagent runs (with/without skill), capture timing, and produce a benchmark.json. Reference: `anthropic-skills:skill-creator` SKILL.md §Running and evaluating test cases (Anthropic built-in skill).

## Review mode workflow

### Step 1 — Read the target's existing evals
`evals.json`, `judge_prompts/`, `rubrics.md`, `failure-taxonomy.md`, `characterization.md`, `calibration-protocol.md` (whichever exist).

### Step 2 — Grade each artifact
For each existing file, run the `references/anti-patterns.md` Review checklist (A-01 through A-23). For each judge, check:
- Binary output (A-04)?
- Cross-family model (F-03)?
- Pinned snapshot (A-11)?
- Calibration protocol documented (F-A2)?
- CoT-blinded if applicable (A-15)?

### Step 3 — Assess coverage
Apply the decision tree fresh. Compare required evals vs. existing evals. Flag gaps.

### Step 4 — Produce review report
Per SKILL.md §Output format §Review mode. Every finding gets file:line evidence and a proposed fix.

## Examples

**Example invocation 1:**
> User: "Write evals for daily-status — I want to catch generalized dates and fabricated action items."
> Playbook: Per-skill Author.
> Outputs: full evals/ directory. Failure taxonomy leads with F-LOCAL-01 (generalized dates — maps to F-05 criteria drift from CLAUDE.md's "no generalized dates" quality standard), F-LOCAL-02 (fabricated action items — maps loosely to F-42 hallucinated policy adapted for internal context). Judges are binary T1 adaptations, blinded to any CoT the skill produces, cross-family (Sonnet judging Opus).

**Example invocation 2:**
> User: "Review prompt-builder's evals — are they catching undertriggering?"
> Playbook: Per-skill Review.
> Outputs: structured report. Likely finds: `evals.json` has no assertions field populated (per anthropic-skills:skill-creator schema, that's fine at drafting stage); no judge_prompts/ directory (fail — all three test prompts expect subjective grading); no calibration-protocol.md (fail — no α/κ thresholds); undertriggering specifically isn't tested directly (gap — recommend description optimization via anthropic-skills:skill-creator's run_loop).
