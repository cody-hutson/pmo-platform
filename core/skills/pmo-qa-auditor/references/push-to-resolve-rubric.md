---
title: Push-to-Resolve Rubric — PMO Reference
purpose: The reference defining the push-to-resolve scoring rubric pmo-qa-auditor uses to evaluate whether an output drives items to resolution rather than dumping status.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Push-to-Resolve Rubric — PMO Reference

## Purpose

This file defines the scoring rubric for evaluating whether PMO agent outputs
demonstrate push-to-resolve quality — resolving actionable items as far as
possible so the operator reviews completed work, not to-do lists. The
pmo-qa-auditor skill reads this file in Mode C (Push-to-Resolve Audit) to
score outputs across five dimensions.

---

## Scoring Scale

Each dimension is scored on a 5-point scale:

| Score | Label | Meaning |
|-------|-------|---------|
| **5** | Exemplary | Exceeds push-to-resolve standard; output is immediately actionable with no gaps |
| **4** | Satisfactory | Meets push-to-resolve standard; minor opportunities for deeper resolution |
| **3** | Marginal | Partially resolved; some items are actionable but others remain as tasks for the operator |
| **2** | Below Standard | Predominantly unresolved; operator must do substantial work to make output usable |
| **1** | Failure | Task dump; output lists what should be done without doing any of it |

### Overall Score Thresholds

| Threshold | Average Score | Disposition |
|-----------|--------------|-------------|
| **PASS** | >= 4.0 | Output is ready for operator review |
| **CONDITIONAL PASS** | 3.0 - 3.9 | Output requires targeted remediation before review; specific gaps identified |
| **FAIL** | < 3.0 | Output requires fundamental rework; not ready for operator review |

---

## Dimension 1: Completeness

*Was every gap resolved or explicitly deferred with rationale?*

| Score | Behavioral Marker |
|-------|------------------|
| **5** | Every identified gap is resolved with a concrete deliverable (draft text, populated template, computed value). Zero open items without resolution. Any deferred items have explicit rationale and a named next step. |
| **4** | All critical gaps resolved. 1-2 minor gaps deferred with rationale and proposed resolution approach. |
| **3** | Major gaps resolved but 3+ minor gaps left as operator tasks. Deferred items have rationale but no proposed resolution. |
| **2** | Some gaps resolved but critical items left as "needs further investigation" without investigation. |
| **1** | Gaps identified but not resolved. Output is a gap list, not a resolution. "The following items need to be addressed: ..." |

**Anti-patterns to detect:**
- "Consider doing X" without doing X (recommendation without resolution)
- "Further analysis needed" without performing the analysis or specifying what analysis
- "Stakeholder input required" when the agent could propose the answer and flag for confirmation
- Listing open questions without proposing answers

---

## Dimension 2: Specificity

*Are actions specified with owner, deadline, and context?*

| Score | Behavioral Marker |
|-------|------------------|
| **5** | Every action item names a specific owner (person, not team), includes a deadline (specific date with day-of-week validated), and provides sufficient context for the owner to act without asking clarifying questions. |
| **4** | Actions have owners and deadlines. Context is present but occasionally requires one clarifying question. |
| **3** | Actions have owners but deadlines are vague ("next week," "soon") or missing for some items. Context is thin. |
| **2** | Actions name teams instead of individuals. Deadlines are generalized ranges. Context requires significant clarification. |
| **1** | Actions are vague directives without owners, deadlines, or context. "Follow up on testing." "Address risk items." |

**Anti-patterns to detect:**
- "The team should..." (no individual accountability)
- "By end of sprint" or "ASAP" (not a specific date)
- "Coordinate with stakeholders" (which stakeholders? about what? by when?)
- Date ranges instead of specific dates ("week of April 6" instead of "April 6 (Monday)")

---

## Dimension 3: Evidence Quality

*Are claims tagged with evidence quality labels?*

| Score | Behavioral Marker |
|-------|------------------|
| **5** | Every factual claim is tagged: [SOURCE] for verified data, [INFERRED] for logical derivation, [ASSUMPTION - CONFIRM] for proposed answers to unknown facts, [CONTEXT] for session-provided information, [RECOMMENDED] for agent judgment. No untagged assertions. |
| **4** | >90% of claims tagged. Occasional untagged claim where the source is obvious from context. |
| **3** | Major claims tagged. Minor claims or supporting details untagged. Tagging is inconsistent. |
| **2** | Some tagging present but applied inconsistently. Multiple factual claims without evidence basis. |
| **1** | No evidence tagging. Claims presented as fact without source attribution. Dates, statuses, and metrics cited without verification. |

**Anti-patterns to detect:**
- Dates not traceable to PROJECT.md or carry-forward tracker
- Status claims not sourced from status log or source artifact
- Metrics without methodology or data source
- "As discussed" or "as agreed" without reference to specific meeting/date
- Fabricated specificity (precise numbers without source)

---

## Dimension 4: Operational Value

*Would a PM act on this output today?*

| Score | Behavioral Marker |
|-------|------------------|
| **5** | Output is immediately usable: paste-ready communications, populated templates, computed decisions with rationale, filed artifacts. The operator's next action is "review and approve," not "now build the thing." |
| **4** | Output is usable with minor adjustments (name substitutions, final date confirmations). Operator effort is review-level, not creation-level. |
| **3** | Output provides a strong starting point but requires operator work to complete. ~50% of the value is delivered; ~50% remains as operator tasks. |
| **2** | Output provides analysis but not resolution. Operator must translate analysis into deliverables. Value is informational, not operational. |
| **1** | Output is a summary of what should be done. Operator must create all deliverables from scratch. Output has the same information the operator started with. |

**Anti-patterns to detect:**
- Status recaps that add no decisions or actions (status theater)
- Analysis without recommendations (information dumping)
- Recommendations without deliverables (task dumping)
- "Draft to follow" without the draft
- Audit findings without remediation plans

---

## Dimension 5: Behavioral Calibration

*Does the output demonstrate principal-level judgment or junior-level task execution?*

This dimension evaluates the output against the five meta-behaviors of principal-level
coordination from the PMO competency model.

| Score | Behavioral Marker |
|-------|------------------|
| **5** | Output demonstrates all five meta-behaviors where applicable: altitude switching (adapts framing to audience), tension holding (acknowledges competing forces without premature resolution), invisible orchestration (enables direct coordination rather than centralizing), narrative control (selects facts and framing that drive decisions), graceful degradation (consciously prioritizes when resources constrain). |
| **4** | Output demonstrates 3-4 meta-behaviors. Shows principal-level judgment in critical areas. Minor lapses in one meta-behavior. |
| **3** | Output demonstrates 1-2 meta-behaviors. Shows competent execution but lacks the strategic overlay. Follows processes correctly without adapting to context. |
| **2** | Output follows rules without understanding why. Applies same approach regardless of context. Shows rule-following without rule-understanding. |
| **1** | Output dumps tasks without judgment. Lists information without interpretation. Reports activity without assessing progress toward outcomes. Defers all decisions. |

**Principal vs. junior behavioral markers:**

| Meta-Behavior | Principal Marker | Junior Marker (Anti-Pattern) |
|---------------|-----------------|------------------------------|
| **Altitude Switching** | Same information reframed at different organizational levels within a single output when multiple audiences are served | Single-altitude communication regardless of audience |
| **Tension Holding** | Competing priorities named explicitly with "both are true" framing; resolution proposed but not forced | Tension collapsed prematurely ("we should just do X") or ignored entirely |
| **Invisible Orchestration** | Actions designed so parties coordinate directly; agent creates conditions, not bottlenecks | All coordination flows through agent; or agent disengages leaving no coordination mechanism |
| **Narrative Control** | Facts selected and framed to drive specific decisions; no misrepresentation but deliberate emphasis | Data dump without interpretation; or spin that misrepresents reality |
| **Graceful Degradation** | When constraints exist, explicit statement of what is being protected and what is being sacrificed with rationale | Tries to maintain everything (quality collapses uniformly) or freezes without prioritizing |

---

## Scoring Worksheet

| Dimension | Score (1-5) | Evidence / Notes |
|-----------|------------|-----------------|
| 1. Completeness | ___ | |
| 2. Specificity | ___ | |
| 3. Evidence Quality | ___ | |
| 4. Operational Value | ___ | |
| 5. Behavioral Calibration | ___ | |
| **Average** | ___ | |
| **Disposition** | PASS / CONDITIONAL / FAIL | |

**Remediation for CONDITIONAL PASS:** Identify the specific dimensions scoring < 4
and provide targeted feedback. The output is reworked on those dimensions only, not
entirely regenerated.

**Remediation for FAIL:** Identify root cause — is it a skill gap (wrong approach),
a context gap (missing information), or a calibration gap (wrong judgment level)?
Root cause determines whether the fix is re-execution with better input, skill
modification, or reference file update.
