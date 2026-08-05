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

## Output Surfaces

The five dimensions, the 1–5 scale, and the PASS / CONDITIONAL / FAIL thresholds are
surface-neutral and apply unchanged to every output. What varies by surface is what a given
score *looks like* — the behavioral markers. This section names the surfaces and fixes how a
scorer selects one; each dimension below then carries a **Surface lens** stating how its
markers read on each surface, or declaring the dimension surface-invariant.

| Surface | The output is… | Who acts next, and where |
|---------|----------------|--------------------------|
| **Deliverable** | an artifact produced *for* a reader outside this working session — a status post, a comms draft, a populated template, a filed or written artifact, a report | a party outside the session receives the output and acts on it |
| **Conversational** | a turn addressed *to the operator who invoked it* — an orchestration progress turn, a decision briefing, a readiness or gate verdict, an analysis answer, a stage sub-task output | the invoking operator, or an agent this session dispatches, decides on the output |

**"Surface" here means the output's audience-and-consumption class** — not the separate sense
of a surface as the file or system a fact is written to.

### Selecting the surface

Do this before scoring any dimension.

**S-1 — The next-actor test.** Ask *who acts next, and where*. If the next actor is outside
this session and the output is the thing they receive and act on, the surface is
**Deliverable**. If the next actor is the invoking operator or an agent this session
dispatches, and the output is the thing they decide on, the surface is **Conversational**.

**S-2 — Record the verdict.** Write the selected surface and its one-line basis into the
scoring worksheet before scoring begins. A scorecard with no recorded surface is incomplete.

**S-3 — A mixed output is decomposed, never blended.** When one response contains both a
conversational span and a self-contained deliverable artifact, score them as **two outputs**:
the artifact on the Deliverable surface, the containing turn on the Conversational surface.
Report both scorecards. Do not average them, and do not pick a dominant surface. A span is a
*self-contained deliverable* when it is delimited — a fenced block, a named file path, or an
explicit instruction to paste it somewhere — **and** could be handed to its recipient with no
surrounding prose. A span that cannot survive extraction is conversational content and is
scored as such.

**S-4 — Ambiguity defaults to Conversational.** When S-1 does not resolve, score on the
Conversational surface and note the ambiguity in the worksheet. This default is not the
lenient one: the Conversational lens requires the turn to render the decision it exists to
render, where the Deliverable lens would only ask whether an artifact was produced.

**S-5 — Markers cite observable text.** Every per-surface marker below names a feature a
scorer can point at in the output — a named actor, a named gate, a delimited artifact, an
evidence label — never a quality adjective. A proposed marker that cannot be satisfied by
pointing at a span does not belong in this rubric.

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

**Surface lens**

| Surface | How the markers above read |
|---------|----------------------------|
| **Deliverable** | As written — each gap closes into a concrete deliverable (draft text, populated template, computed value). |
| **Conversational** | Substitute the deliverable anchor: each item is **closed out inside the turn** — a rendered decision with its rationale, a computed verdict, a resolved question, or an explicit deferral naming its owner and its trigger. An item pushed to "I'll handle that next turn" with no named trigger is deferred, not resolved. |

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

**Surface lens**

| Surface | How the markers above read |
|---------|----------------------------|
| **Deliverable** | As written — owner is a named person, deadline is a specific date with day-of-week validated, context is sufficient to act without a clarifying question. |
| **Conversational** | Substitute the three anchors. **Owner → the named next actor:** the operator, a named spoke or sub-agent, or a named external party — never "the team" and never an unnamed "someone". **Deadline → the named next gate or trigger:** the stage gate, the checkpoint, or the stated condition that fires the action — never "soon" or "next turn". **Context → unchanged.** A 5 names all three; a 1 issues a directive with no named actor and no named gate. |

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

**Surface lens** — **surface-invariant.** The evidence-quality labels and their thresholds
apply unchanged on both surfaces: a claim made in a conversational turn carries exactly the
same labeling obligation as a claim made in a filed artifact. No per-surface substitution
applies, and none should be added — this invariance is asserted, not accidental.

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

**Surface lens**

| Surface | How the markers above read |
|---------|----------------------------|
| **Deliverable** | As written — paste-ready communications, populated templates, computed decisions with rationale, filed artifacts. The reader's next action is "review and approve", not "now build the thing". |
| **Conversational** | Substitute the artifact anchor: the turn **renders the decision the operator has to make** — the options, the recommendation, the evidence behind it, and the gate it belongs to — so the operator's next action is **decide**, not **ask a follow-up question**. A 5 needs no follow-up question before the operator can act. A 3 renders the analysis but leaves the operator to assemble the decision from it. A 1 reports state and hands the decision back untouched. |

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

**Surface lens**

| Surface | How the markers above read |
|---------|----------------------------|
| **Deliverable** | As written — the five meta-behaviors are read against a single artifact serving one or more audiences. |
| **Conversational** | Three of the five read unchanged: Tension Holding, Narrative Control, Graceful Degradation. Two take a per-surface reading. **Altitude Switching:** substitute the multi-audience anchor with a **named level transition** — a sentence naming the level the turn is speaking at, plus one at each move between levels (a stated summary-then-detail marker, or a detail span delimited and introduced as such). The marker is satisfied by pointing at those sentences; a turn carrying none is single-altitude. **Invisible Orchestration:** the turn hands the operator a decision they can make without routing back through the agent, rather than designing for external parties to coordinate directly. |

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
| **Output surface** | Deliverable / Conversational | (per S-1; under S-3, one worksheet per decomposed output) |
| **Surface-selection basis** | ___ | (the next-actor answer, one line) |
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

---

## Marker Reproducibility Calibration

Per-surface markers are only useful if two scorers reading the same output and the same
markers land on the same score. This section fixes how that is measured, what the bar is, and
what happens when the bar is missed. Run it whenever these markers change, and on whatever
cadence the auditing skill declares.

**Unit of analysis.** One rating unit is one (output × dimension) pair. A sample of 10 outputs
therefore yields 50 rating units across the five dimensions.

**Raters.** Two independent scorers, each scoring from the markers alone, neither seeing the
other's scores and neither discussing the sample until scoring is complete.

**Statistic.** Krippendorff alpha, using the **ordinal** difference function. Chance-corrected
agreement is required; raw percent agreement is not an acceptable substitute, because a high
raw figure is compatible with near-zero chance-corrected reliability. The ordinal difference
function is required because the scale is ordinal: a 4-versus-5 disagreement is a smaller
error than a 1-versus-5, and a nominal statistic scores the two identically.

**Reporting grain.** Report alpha twice.

- **Pooled alpha** over all (output × dimension) rating units — the headline figure the
  threshold gates on.
- **Per-dimension alpha**, computed within a single dimension across the distinct outputs —
  the diagnostic that localizes an unreproducible marker set to the dimension that owns it.

**Threshold and action.**

| Pooled alpha | Reading | Action |
|--------------|---------|--------|
| >= 0.80 | Reliable | Markers are reproducible. Ship. |
| 0.67 – 0.79 | Tentative | Add a third independent scorer and recompute before relying on these markers. |
| < 0.67 | Not reproducible | **Rework the rubric's markers, not the scorers.** The per-dimension alpha names which dimension to rework. |

**Sample floor.** At least 30 rating units and at least 10 distinct outputs. Ten outputs
across five dimensions satisfies both.

**Validity threat — non-independence.** Rating units drawn from the same output are
correlated: a well-executed output tends to score well on every dimension. A pooled alpha over
(output × dimension) units therefore overstates agreement relative to an equal number of
independent items. The per-dimension alpha is the mitigation — it is computed within one
dimension across distinct outputs, so it carries no within-output correlation. A pooled alpha
that clears the bar while a per-dimension alpha falls below it is a finding, not a rounding
artifact.

**Sampling frame.** Draw outputs from durable, re-fetchable records rather than from ephemeral
session transcripts, so an independent reviewer can reconstruct the sample. State the selection
rule and the exact retrieval command alongside the sample, and draw from at least two distinct
originating contexts so the result is not an artifact of a single run.

**Backward-compatibility control.** Alongside the surface sample, re-score at least five
Deliverable-surface outputs under both the previous and the current text of this rubric. Every
disposition — PASS, CONDITIONAL PASS, or FAIL — must be unchanged. A changed disposition on a
deliverable output means the edit was not marker-additive and must be corrected before the
revised rubric is relied on.
