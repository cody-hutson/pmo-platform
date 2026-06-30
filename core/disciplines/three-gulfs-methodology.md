---
title: Three Gulfs Methodology
purpose: The diagnostic methodology for locating where a skill, agent, or pipeline stage is weak along three gulfs — Intention, Execution, and Comprehension — turning open-ended quality questions into structured diagnostic axes.
type: discipline
framework_version_anchor: "v11"
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Three Gulfs Methodology

## Purpose

Three Gulfs is a diagnostic methodology for locating where a skill, agent, or pipeline stage is weak along three dimensions: whether it understands user **intent**, whether it performs the right **execution**, and whether its output is **legible** enough for a user to verify success. Applied at skill creation, skill improvement, and eval design, it turns open-ended quality questions ("is this skill any good?") into structured diagnostic axes that point to specific failure modes and specific fixes.

The methodology layers above — not replaces — existing artifacts. [skill-creator/agents/grader.md](../../release/skills/pmo-skill-refiner/agents/grader.md) remains the grading workflow; the pipeline-stage eval framework remains the runner. Three Gulfs informs *what* gets authored upstream of those tools, giving eval authors and skill designers a shared vocabulary for classifying gaps.

## The Three Gulfs

### Gulf of Intention

**Question it answers:** Does the system understand what the user *wanted* before acting?

**Skill-context failure mode:** The skill triggers on the wrong request (false positive) or fails to trigger when it should (false negative). Trigger-word mismatch. Ambiguous requests executed without clarification. Competing skills route the same request differently. Bare description that doesn't discriminate from adjacent skills.

**Diagnostic question:** If a user's request is ambiguous, does the skill recognize the ambiguity and surface it — or does it execute the most literal interpretation and hope for the best?

### Gulf of Execution

**Question it answers:** Does the system perform the right *steps* to achieve the understood intent?

**Skill-context failure mode:** Wrong tool invoked. Step skipped. Wrong file path written to. Downstream handoff malformed. Mid-stage validation bypassed. Fabricated output substituted for work that was never done.

**Diagnostic question:** Given correct intent, does the skill execute every step of the intended workflow — including the quiet ones (validation, logging, regression checks) that don't produce visible artifacts?

### Gulf of Evaluation

**Question it answers:** Can the user *tell* whether their goal was achieved?

**Skill-context failure mode:** Output is correct but illegible. Skill reports success but produced nothing. Reasoning hidden from user. Errors swallowed silently. Confirmation message claims done when it isn't. Output format that buries the answer.

**Diagnostic question:** When the skill finishes, can a user verify the result without re-doing the work? Is every claim the skill makes traceable to a file, output, or action the user can inspect?

## Applying the Three Gulfs

### During skill creation

When authoring a new skill (via `skill-creator`), apply the Three Gulfs as a lens during the Interview phase — before drafting SKILL.md body content. For each gulf:

- **Intention:** What request shapes trigger this skill? Which adjacent skills could compete? Which ambiguous requests need clarification before execution? (Informs description drafting and trigger eval queries.)
- **Execution:** What tools, steps, and outputs does the skill invoke? Where could execution silently go off the rails? (Informs SKILL.md body and integration/contract assertions.)
- **Evaluation:** How will the user know it worked? What's the legible output surface? Which failure modes need to surface rather than swallow? (Informs output format specification and grader rubric design.)

A skill that passes only on Gulf of Execution — it does the thing, but the user can't tell it did — will fail in practice. All three gulfs must be addressed for the skill to be useful.

### During skill improvement

When improving an existing skill, map user feedback to the Three Gulfs to locate the weakest dimension. Feedback usually clusters — "it keeps triggering when I don't want it to" is Intention, "it skipped the deploy step" is Execution, "I couldn't tell it actually ran" is Evaluation.

Fix where the feedback clusters densest first rather than distributing small edits across the skill. A gulf-targeted fix repairs the structural weakness; ad hoc edits paper over symptoms without closing the underlying gap.

### During eval design

Three Gulfs gives eval authors a second slicing dimension orthogonal to the canonical eval-type taxonomy. Each assertion can be tagged with the gulf it primarily probes, enabling diagnostic reports — e.g., "Stage 7 is weak on Gulf of Evaluation: output-clarity assertions are failing."

The mapping below shows how each of the six eval types maps to the three gulfs. The relationship is **many-to-many**; **primary** in bold marks the gulf each eval type most directly probes.

| Eval Type | Gulf of Intention | Gulf of Execution | Gulf of Evaluation |
|---|---|---|---|
| **1. Structural** (deterministic: format, fields, file existence) | secondary — malformed input schema indicates misread intent | secondary — missing output file indicates execution gap | **primary** — output format/legibility is the evaluation surface |
| **2. Contract** (deterministic/LLM: handoff integrity) | **primary** — consumed upstream inputs correctly = understood intent | **primary** — produced required downstream outputs = executed the contract | secondary |
| **3. Principal Behavior** (LLM-graded: acts like skilled PMO pro) | secondary | **primary** — principal-level *doing* (judgment, proactivity in execution) | **primary** — principal-level *communicating* (clear reasoning, legible outputs) |
| **4. Comparison** (diff vs. baseline) | — | secondary — deviation from baseline may indicate execution drift | **primary** — baseline *is* the evaluation standard |
| **5. Integration** (end-to-end chain) | secondary — chain kickoff implies intent captured | **primary** — multi-stage execution is the literal definition | secondary |
| **6. Proactivity** (LLM-graded: surfaces what user didn't ask) | **primary** — surfacing ambiguity = modeling intent, not just request | secondary — proactively doing more than asked is execution-adjacent | secondary |

Eval authors apply this mapping two ways: (1) when writing a new assertion, pick the gulf it primarily probes and tag it; (2) when reviewing an eval suite, check for gulf coverage gaps — a suite dense on Execution but sparse on Evaluation is structurally incomplete, regardless of how many assertions it has.

## Relationship to grader.md

[skill-creator/agents/grader.md](../../release/skills/pmo-skill-refiner/agents/grader.md) defines the 7-step workflow for grading skill outputs (Read Transcript → Examine Output Files → Evaluate Each Assertion → Extract and Verify Claims → Read User Notes → Critique the Evals → Write Grading Results). Three Gulfs adoption does **not** reframe this workflow.

The distinction is workflow vs. taxonomy:

| Dimension | grader.md | Three Gulfs |
|---|---|---|
| **What it is** | Workflow for evaluating expectations against a transcript + outputs | Taxonomy for what to evaluate |
| **Scope** | skill-creator's per-assertion grading | Pipeline-wide framing across stages and skills |
| **Consumer** | Subagent spawned during `iteration-N/` grading | Eval authors designing assertions; Solutioning agents designing test cases |
| **Change cadence** | Stable (process rarely changes) | Reference doc (cited; rarely rewritten) |

grader.md operates on pre-existing expectations — they are input, not output. Three Gulfs informs upstream expectation *authorship*, shaping what gets graded rather than how grading happens. Replacing the 7-step process with a 3-gulf process would conflate workflow with taxonomy and lose the procedural clarity grader.md provides. The two compose cleanly: Three-Gulfs-tagged assertions flow into grader.md unchanged.

## Relationship to the eval framework

The eval framework establishes the pipeline-stage eval framework with an assertion YAML schema and a runner. Three Gulfs integrates via an **optional** `gulf:` field on each assertion:

```yaml
assertions:
  - id: stage-6-pr-metadata
    type: structural
    gulf: evaluation
    ...
```

Optional is deliberate. Requiring `gulf:` on every assertion would force every eval author to make a taxonomy call, raising friction for deterministic structural checks where the mapping is mechanical. Optional preserves diagnostic value without gating eval authorship.

When `gulf:` is populated, the runner can produce gulf-sliced diagnostic reports — per-stage pass rates by gulf — surfacing structural weaknesses the type taxonomy alone can't distinguish. When `gulf:` is absent, the assertion still runs; only the second slicing dimension is unavailable for that row.

The authoritative mapping table (see "Applying the Three Gulfs → During eval design" above) lives in this reference doc. `engineering/evals/README.md` is expected to cite this doc rather than duplicate the table, keeping the taxonomy in one place.

## References

- **Don Norman, *The Design of Everyday Things*** — Origin of the Gulf of Execution and Gulf of Evaluation in human–computer interaction. Introduced in the 1988 edition; revised 2013.
- **Gulf of Intention** — Extension of Norman's two-gulf framework to LLM agent systems, reflecting the observation that user-intent recognition is a distinct failure surface where current agents most often break. Adopted as standard PMO-platform methodology per the adopting work item.
- **Related platform artifacts:**
  - Canonical eval-type taxonomy (6 types: Structural, Contract, Principal Behavior, Comparison, Integration, Proactivity).
  - Parent issue: adopt Three Gulfs eval methodology for skill development.
  - Eval runner for pipeline stage assertions; consumes the optional `gulf:` field defined here.
  - `skill-creator/SKILL.md` — Interview mode applies Three Gulfs framing before open-ended interviewing (integration lands as a follow-up).
  - [skill-creator/agents/grader.md](../../release/skills/pmo-skill-refiner/agents/grader.md) — 7-step grading workflow; unchanged by Three Gulfs adoption (see "Relationship to grader.md").
