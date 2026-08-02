---
title: Review Discipline Principles
purpose: Shared discipline methodology for review-class skills (audits, QA, reviews)
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
framework_version_anchor: "v10.2"
applies_to: build-reviewer, pmo-qa-auditor, pmo-skill-editor Mode D, future audit skills; Section 1 Rule 15 and Section 8 additionally bind any agent asserting a zero, clean, absent, or N-of-M verification result — that obligation attaches to the ACT of claiming a verified result, not to the actor's skill class, and reaches orchestrating agents and one-off sessions equally
source: Extracted from build-reviewer/SKILL.md (2026-04-18 Anthropic mapping analysis)
---

# Review Discipline Principles

Shared discipline methodology for review-class skills. When a skill's primary function is reviewing, auditing, or evaluating another output, it inherits the rules below. Review-class skills include `build-reviewer`, `pmo-qa-auditor`, `pmo-skill-editor` Mode D, and any future audit skill.

---

## Section 1 — Anti-Laziness Rules (15 rules)

These rules govern HOW findings are produced — the output discipline that separates principal-grade review from surface pass. Rules 1–10 are extracted verbatim from `release/skills/build-reviewer/SKILL.md` and apply unchanged to any review-class skill; rules 11–15 were added subsequently and are native to this shared discipline.

1. **No surface-level passes.** "This section looks well-structured" is not a finding. Either identify a specific issue or provide specific evidence that the section is complete and correct.

   *Application:* Every dimension you evaluate must terminate in either a concrete finding or a concrete verification statement — never a vague impression.

2. **No assumption of correctness.** The fact that something has been through 8 rounds of remediation does not make it correct. Prior reviewers may have introduced new issues while fixing old ones.

   *Application:* Treat the target as freshly suspect regardless of its history. Prior sign-off is not evidence of current correctness.

3. **No finding-free dimensions.** If you find zero issues in a dimension, you must explain what you checked and why you are confident there are no issues. A blank dimension is not acceptable.

   *Application:* A "no findings" result requires positive evidence, not absence of effort. State the checks performed and why they justify confidence.

4. **No symptom-only findings.** Every finding must include a root cause. "The reference is wrong" is a symptom. "The reference was not updated when Section X was renamed during a prior remediation" is a root cause.

   *Application:* Every finding traces to a root cause. A symptom without a root cause is an incomplete finding and must be rejected. See Section 2 for the required root-cause format.

5. **No resolution-free findings.** Every finding must include a specific, actionable recommendation. "This should be fixed" is not a recommendation.

   *Application:* Each finding names a specific change: file, section, wording, or structural adjustment. The consuming implementer should be able to act on the recommendation without additional design work.

6. **No scope avoidance.** You must review all 30 documents plus the runtime extract. You may not skip files because they are "less important."

   *Application:* In any review, "scope" means the full declared scope. Skipping artifacts for convenience is a review-discipline failure. Generalize to: cover all declared review inputs.

7. **No severity inflation or deflation.** Use the framework's own severity model honestly. Not everything is critical, and not everything is low.

   *Application:* Apply the severity model as defined (e.g., CRITICAL/HIGH/MEDIUM/LOW with observable thresholds — see Section 5). Do not escalate to draw attention; do not de-escalate to avoid controversy.

8. **No redundant findings.** If the same root cause produces multiple symptoms, group them under one finding with the root cause identified.

   *Application:* Consolidate findings that share a root cause. List the symptoms under the single root-cause finding rather than filing each symptom as its own finding.

9. **No narrative padding.** Findings should be precise and concise. Do not pad findings with unnecessary context or hedging language.

   *Application:* State the finding, the evidence, the root cause, and the recommendation. No preamble, no hedging, no restating what the document already says.

10. **No self-referential validation.** Do not treat the framework's internal consistency as proof of external correctness. A framework can be internally consistent and still miss its stated goals.

    *Application:* "The document references itself correctly" is not proof the document achieves its purpose. Validate against the declared external goals — not the document's own claims about itself.

11. **Numeric verification before subjective grouping.** When evaluating whether items belong together (issue clusters, finding groups, document subsets), prefer a numeric test over thematic intuition. Numeric tests (e.g., dependency edge counts, severity threshold scores, quantitative criteria) are auditable, repeatable, and survive operator handoffs. Thematic groupings are not.

    *Application:* Before proposing any structural grouping, identify the available numeric tests for that domain and apply them. State the test, the threshold, and the result. If no numeric test applies, state that explicitly — not "these feel like they belong together."

12. **Confidence-tiered evidence with file:line cites.** Findings or recommendations should carry both a confidence tier (HIGH / MEDIUM / LOW) and a specific evidence reference (file path + line number, issue + comment, governance section). HIGH-confidence claims with cited evidence ship clean; MEDIUM-confidence claims hold for operator review; LOW-confidence claims downgrade to observation.

    *Application:* Every finding cites its strongest evidence as `file:line` or equivalent. The confidence tier maps to disposition: HIGH → ship; MEDIUM → review-required; LOW → observation. Findings without confidence tiers default to MEDIUM.

13. **Per-batch verification on iterated work.** When executing in batches (e.g., per-document review, per-issue mutation, per-file edit), verify each batch's outcome before proceeding to the next. Catching one error at batch 2 of 6 is dramatically cheaper than catching it after batch 6 — and the verification itself surfaces drift before downstream damage.

    *Application:* Define the per-batch verification before execution starts. After each batch, run the verification and confirm the expected outcome. Failure halts the batch sequence pending operator decision; do not proceed silently.

14. **N-1 internal edges as cohesion test for grouping decisions.** When deciding whether to bundle items together (e.g., issues into a milestone, findings into a pattern, requirements into a phase), apply the N-1 internal edges criterion: a tight bundle of N items has at least N-1 internal dependency or relational edges. Below N-1, the bundle is loose and should split.

    *Application:* For any proposed grouping of N items, compute the count of internal edges. If count ≥ N-1, accept the bundle. If count < N-1, identify the weakest edge cut and split. Document the edge count + cut decision; do not propose tight bundles without the test.

15. **A zero is not a result until the probe is shown to detect, and to discriminate.** A verification probe that returns zero, empty, clean, absent, or "N of M" establishes nothing until the probe has been shown capable of returning non-zero on an input it must flag, and of returning zero on a near-miss input it must not flag. A sensitivity control that returns zero alongside the subject means the probe is broken, not that the data is clean. A specificity control that returns non-zero means the probe over-matches, not that the subject is dirty.

    *Application:* Every claim of the form "0 occurrences" / "no findings" / "CLEAN" / "N of M" carries five values inline — the invocation that produced it, the denominator it searched, the sensitivity arm of its control with its observed non-zero result, the specificity arm with its observed zero result wherever that arm is required, and evidence that the extraction was non-empty and untruncated for the subject and for every control arm. When any required value cannot be established, the verdict is INDETERMINATE naming the missing element — never a pass. Section 8 defines the record format, the arm-selection rule, the verdict rule, and how INDETERMINATE maps into a consuming verdict enum that has no member for it.

---

## Section 2 — Root-Cause Requirement

Section 1 Rule 4 forbids symptom-only findings. Section 2 defines the format and rejection threshold.

### Required root-cause format

Every finding's root cause must follow the chain:

```
[systemic pattern] → [proximal cause] → [observable signal]
```

- **Systemic pattern** — the class of failure (e.g., "reference not updated after rename", "invariant not enforced at boundary", "schema drift between producer and consumer").
- **Proximal cause** — the specific mechanism by which the pattern manifested here (e.g., "Section X was renamed without updating the 4 incoming references").
- **Observable signal** — what the review actually saw (e.g., "Doc 07 Section 4 references 'Conflict Registry' but the current heading in Doc 05 is 'Conflict Ledger'").

### Rejection threshold

A finding that terminates at the observable signal only — without identifying the proximal cause and the systemic pattern it exemplifies — is **invalid** and must be rejected or revised. "The reference is wrong" is a symptom. "The reference was not updated when Section X was renamed during a remediation pass, producing broken reference chains wherever that section is cited" is a valid root cause.

### Worked example

**Invalid (symptom-only):**
> Finding: The AC in issue #X doesn't match the implementation.

**Valid (root-cause):**
> Finding: The AC in issue #X declares "OPERATIONS.md Universal Preferences updated" but the implementation updated CLAUDE.md.
> Root cause: [AC–target drift] → [the AC was drafted before the governance file map in CLAUDE.md moved Universal Preferences from OPERATIONS.md to CLAUDE.md] → [AC text still names OPERATIONS.md; implementation correctly targets CLAUDE.md].
> Recommendation: Restate AC in the release plan's AC-restatement section.

---

## Section 3 — Systemic Pattern Analysis

After individual findings are written, identify recurring root causes across findings. This is a distinct post-findings activity, not a restatement of individual findings.

### Pattern categories

Every systemic pattern must be classified into one of:

- **Design flaws** — the structure or contract was wrong from the start.
- **Implementation gaps** — the design is sound but not fully realized in the artifact.
- **Interface mismatches** — two components/files/sections disagree on a contract (naming, schema, sequencing).
- **Governance failures** — the rule existed but was not enforced, applied, or updated.
- **Capacity shortfalls** — the work was beyond the available time, attention, or expertise and shows the shortfall.

### Output format

For each systemic pattern:

| Field | Content |
|---|---|
| Pattern name | Short noun phrase |
| Category | One of the five above |
| Member findings | List of Finding IDs this pattern explains |
| Implication | What this pattern predicts about the artifact's future behavior if unaddressed |

A pattern with fewer than 2 member findings is a single finding, not a pattern — demote it back to the findings register.

---

## Section 4 — Residual Risk Register

The residual risk register captures risks that are **consciously not remediated** at the artifact level. These are acknowledged-and-carried, not overlooked.

### Distinction from unresolved findings

- **Unresolved findings** — findings where a recommendation exists but has not yet been applied. These remain open work items.
- **Residual risks** — risks where the review judges that no artifact-level remediation is appropriate (e.g., the risk is infrastructural, operator-dependent, or cost-prohibitive relative to severity) and the risk is consciously carried forward.

The distinction matters because "unresolved" implies follow-up work; "residual" implies the risk is part of the operating environment and must be monitored, not fixed.

### Required fields per residual risk

| Field | Content |
|---|---|
| Risk name | Short noun phrase |
| Disposition reason | Why this risk is carried rather than remediated (e.g., "remediation requires infrastructure change outside artifact scope", "cost of mitigation exceeds cost of residual exposure at current severity") |
| Monitoring criteria | Observable signal(s) that indicate the risk is materializing and would require re-triage |

A residual risk without monitoring criteria is not a residual risk — it is a forgotten risk. Monitoring criteria are mandatory.

---

## Section 5 — 6-Deliverable Output Structure

Principal-grade review produces six deliverables, not one summary. Each is defined below with required fields.

### (a) Findings register

The primary output — every finding as a row with:

- Finding ID (unique within the review)
- Finding statement
- Evidence (quotation, file+line, or artifact reference)
- Root cause (per Section 2 format)
- Severity (per severity model below)
- Recommendation (specific, actionable — per Rule 5)

### (b) Critical path findings

The subset of the findings register whose unresolved state would cause production failure if left unresolved. Identified as a distinct list, not just a severity filter — criticality is a judgment about blocking effect, not a proxy for severity.

### (c) Systemic pattern analysis

Per Section 3. Pattern table + member findings + implications.

### (d) Residual risk register

Per Section 4. Accepted-and-carried risks with monitoring criteria.

### (e) Complexity assessment

An honest evaluation of whether the target's complexity is proportionate to its goals. Answers: is the framework as complex as it needs to be, or has it accumulated complexity beyond its goals? A target can be internally consistent and still over-engineered — call this out when it is.

### (f) Remediation priority

An ordered list of findings (by Finding ID) showing the recommended order of remediation. Order reflects: blocking-effect first, then systemic-pattern fixes (one fix resolves many symptoms), then isolated findings. Include a short justification per ordering decision.

### Severity model

Generalized from the Copilot Builder-specific CS1–CS4 severity classes. Apply to any review unless the domain provides its own calibrated severity model:

| Severity | Observable threshold |
|---|---|
| **CRITICAL** | Would cause production failure or a governance breach if unresolved. Blocks release. |
| **HIGH** | Materially degrades correctness, reliability, or integrity. Should block release unless explicitly carried. |
| **MEDIUM** | Noticeable defect with a workaround. Should be fixed in the next revision. |
| **LOW** | Cosmetic, stylistic, or low-impact drift. Fix opportunistically. |

Apply Rule 7 — do not inflate or deflate. Use observable thresholds, not vibes.

---

## Section 6 — Reviewer Calibration

Review discipline is not context-free. Calibrate the review to its operator, its severity frame, and its place in the review history.

### (a) Operator profile awareness

A review serves an operator. Know who. A principal-grade review for a senior IT Program Manager differs from a sanity-check review for a new contributor. The same finding may warrant different levels of detail, different severity framings, and different recommendations depending on operator expertise, operational context, and downstream consumers.

Capture the operator profile at the top of the review. Name the operator (or role) and state the assumptions the review is calibrated to.

### (b) Severity-class discipline

The severity model (Section 5) is a commitment, not a suggestion. Each severity class has observable thresholds. A finding either meets the threshold or it does not. Do not apply severity by feel; do not promote to draw attention; do not demote to avoid friction.

If a finding's severity is contested, state the reasoning against the threshold — not the reasoning against the reviewer's comfort.

### (c) Round-based framing

Reviews rarely occur in isolation. Name the review round and the findings of prior rounds. A round-N review's job is not to recycle round-(N−1)'s findings — it is to find what round-(N−1) missed. Acknowledge prior findings that have been resolved; do not re-file them. Acknowledge prior findings that are still open; do not add noise to them unless there is new evidence.

A review that repeats prior findings without new evidence is a review-discipline failure (see Rule 2 and Rule 8).

---

## Section 7 — Anti-Patterns for Reviewers Themselves

Section 1 governs OUTPUT (how findings are written and structured). Section 7 governs POSTURE (biases/meta-failures that corrupt findings even when output format is correct).

### (a) Reviewer bias: assuming prior remediation = correct

Prior rounds of remediation bias the reviewer toward "probably fine." Treat prior remediation as a signal that the target was once broken, not that it is now correct. Each round may have introduced regressions while fixing the originally-reported issues. Review the whole target fresh.

### (b) Finding inflation under adversarial posture

Principal-grade review is adversarial — but adversarial is not the same as confrontational. Inflating findings (filing low-severity issues as medium; splitting one root cause into many findings to pad the count; filing speculative findings without evidence) degrades the review's signal-to-noise ratio and undermines subsequent rounds. Inflation is a review failure even if each individual finding is technically valid.

### (c) Scope creep in the review itself

A review's scope is declared up front (e.g., 12 dimensions + 6 deliverables is substantial). Expanding the review beyond its declared scope — even with good intent — produces unreviewed additions to the review itself and confuses the operator about what was and was not examined. Declare the scope, execute the scope, and surface scope-expansion candidates as follow-up recommendations, not as in-line additions to the current review.

### (d) Self-referential validation

Rule 10 in output form: a framework can be internally consistent and still miss its stated goals. Reviewer-posture form: the reviewer cannot validate its own conclusions. The review's confidence in itself is not evidence. External validation — fresh eyes, new evidence, cross-reference with source-of-truth artifacts — is how review conclusions become trustworthy. A review that ends with "I am confident this is complete" without external validation is incomplete.

### Boundary clarification

Section 1 vs. Section 7 is the output-vs-posture boundary. If a failure shows up in the WRITTEN findings (missing root cause, vague recommendation, redundant findings), it is a Section 1 violation. If a failure shows up in the REVIEWER'S STANCE toward the target (deference to prior rounds, inflation under pressure, scope drift, self-validation), it is a Section 7 violation. Both types must be avoided. The distinction matters because remediation differs: Section 1 failures are fixed by revising findings; Section 7 failures are fixed by recalibrating the reviewer's posture.

---

## Section 8 — Probe Validity

Section 1 Rule 15 forbids reporting a zero, clean, absent, or N-of-M result the probe has not been shown to produce validly. Section 8 defines the record format, the arm-selection rule, the verdict rule, the declared coverage boundary, and the rejection threshold.

Element IDs `PV-0` through `PV-6` are stable and citable individually. Consuming surfaces cite them by identifier; they do not restate them.

### § 8.1 — The obligations (PV-0 … PV-6), the riders, and the verdict rule

```
PV-0  INVOCATION.   Cite the exact command, query, or read that produced the result,
                    in a form a reviewer can re-run. A claim with no cited invocation
                    is a prediction, not a verification.

PV-1  DENOMINATOR.  State the population actually examined, as a number, together
                    with how that number was obtained. The denominator is the
                    population searched — not the sample returned, not the first
                    page, not the default scope of the tool. When the tool's default
                    scope is narrower than the claim's scope, say so.

PV-2  CONTROL — SENSITIVITY ARM.
                    Run an input the probe MUST flag, in the same invocation shape as
                    the subject, and record its observed result. This arm's PASS
                    condition is NON-ZERO. It proves the probe can detect.

      PV-2a  Mutation form. Where the subject is an artifact that should be clean,
             the sensitivity arm is a deliberately-introduced defect of the class
             being checked: introduce it, confirm the probe flags it, revert.

      PV-2b  Bounding form. Where the probe is scoped to a region of a larger
             artifact, additionally assert that the region-scoped count is strictly
             less than the whole-artifact count for at least one source. Otherwise
             the probe may have degenerated to an artifact-wide match, and a hit
             from the wrong region reads as confirmation.

      PV-2c  CONTROL — SPECIFICITY ARM.
             Run a NEAR-MISS input the probe MUST NOT flag — an input that differs
             from a true positive only in the property being tested — and record its
             observed result. This arm's PASS condition is ZERO. It proves the probe
             can discriminate.

             A control is DISCRIMINATING when BOTH arms are observed as specified.
             "Discriminating" is the conjunction of the two arms; it is never an
             adjective asserted over a single arm. An input that both arms would
             treat alike proves nothing about either.

             REQUIRED when any of these hold:
               (i)   the probe is a reusable mechanized check rather than a one-shot
                     invocation;
               (ii)  the claim is PRESENT-AND-WRONG rather than ABSENT;
               (iii) the obligation being discharged itself names a must-not-flag
                     input.
             OPTIONAL for a one-shot absence probe, where the sensitivity arm alone
             is proportionate. Stating that PV-2c was not triggered, and why, is part
             of the record; silence is not.

      PV-2d  FIXTURE FORM (probes reachable only by a remote trigger).
             Where the probe runs only in CI — no local invocation reproduces it —
             the control arms are NOT a mutation of a tracked declaration pushed to a
             live branch. They are a COMMITTED FIXTURE carrying a labeled
             expected-match set: must-flag cases and must-not-flag cases, exercised
             by an entry point that is invocable locally AND invoked by the CI job,
             so both surfaces measure the same thing. Where the CI job asserts inline
             rather than delegating to such an entry point, extracting the assertion
             into one is part of the work, not an exemption from this rider.

PV-3  EXTRACTION.   Show that the bytes the probe actually read were non-empty and
                    untruncated — a byte or line count of the input, not of the
                    output. A probe over an empty or truncated input returns zero for
                    a reason unrelated to the claim.

PV-4  QUOTE THE MATCH. A claim that something is PRESENT-AND-WRONG quotes the matched
                    text verbatim. A pattern that missed by a space, a delimiter, or
                    a case is visible in the quoted match and invisible in the count.

PV-5  APPLIES TO EACH CONTROL ARM.
                    PV-0, PV-1, PV-3 and PV-4 bind EVERY arm of the control with the
                    same force as the subject. Two distinct failures follow, and the
                    second is the one this rider exists to catch:
                      - A SENSITIVITY arm whose own extraction was empty reports
                        "0 flagged" and reads as a probe that cannot detect.
                      - A SPECIFICITY arm whose own extraction was empty returns
                        ZERO, which is that arm's PASS condition, and therefore reads
                        as a PASSING control while proving nothing. It is VACUOUS,
                        not passing. A specificity arm is only informative when its
                        input is shown non-empty and shown to contain the near-miss.

PV-6  INSTRUMENT FORM.
                    PV-0..PV-5 bind the CLAIM, whoever or whatever makes it — an agent
                    asserting a result in prose, or an instrument emitting one at
                    runtime. Where the probe is a mechanized, reusable check rather
                    than an agent's one-shot invocation, THE CHECK ITSELF CARRIES THE
                    RECORD: its denominator and its control-arm results are fields of
                    the check's own emitted output, not of the prose report about it.
                    A check whose runtime output states only a finding count has not
                    discharged PV-1 or PV-2 — a reader cannot distinguish "zero found"
                    from "nothing examined." The § 8.2 record form is the shape; a
                    mechanized check may render it as structured output.

VERDICT RULE
  (every line names an arm; the bare word "control" is not a verdict input)

  zero + PV-0, PV-1, PV-3 established
       + PV-2  sensitivity arm observed NON-ZERO
       + PV-2c specificity arm observed ZERO, wherever PV-2c is triggered
                                        ->  CLEAN

  zero + any required element above not established
                                        ->  INDETERMINATE, naming the missing element

  PV-2  sensitivity arm returns ZERO    ->  BROKEN PROBE. The probe cannot detect.
                                            Report the probe unusable. NEVER report
                                            the subject as clean.

  PV-2c specificity arm returns NON-ZERO
                                        ->  OVER-MATCHING PROBE. The probe cannot
                                            discriminate. Report the probe unusable.
                                            NEVER report the subject as flagged.

  PV-2c specificity arm returns ZERO    ->  This is that arm's PASS condition. It is
                                            NOT a broken probe — provided PV-5 holds
                                            on it. A specificity arm whose own
                                            extraction was empty is VACUOUS, not
                                            passing, and the verdict is INDETERMINATE
                                            naming PV-5.

MAPPING INTO A CONSUMING VERDICT ENUM
  INDETERMINATE is a statement about the PROBE, not about the deliverable.
  1. Its FIRST disposition is always REPAIR THE PROBE AND RE-RUN. INDETERMINATE is
     never a terminal verdict where a valid probe can be constructed.
  2. Only where no valid probe can be constructed does it map into the consuming
     context's enum, and then to that enum's NON-PASSING member. In an acceptance-
     grading enum whose members are MET / NOT MET / PARTIAL / N/A-WITH-RATIONALE /
     REINTERPRET-WITH-RATIONALE / FLAG-UPSTREAM, the mapping is NOT MET — not
     PARTIAL, because the deficiency is in the probe's validity, not in the
     deliverable's completeness.
  3. Where the missing element is owned upstream of the grading context,
     FLAG-UPSTREAM is the correct mapping.
  4. INDETERMINATE NEVER maps to MET, and never to N/A-WITH-RATIONALE. A grader
     holding an unrepresentable verdict drifts toward the member with no cost
     attached; naming the mapping is what stops that drift.
```

### § 8.2 — The probe record (copy-paste form for any output asserting a zero)

```
**Probe:** <exact command>
**Denominator:** <N> (<how counted>)
**Control — sensitivity:** <input the probe must flag> -> observed <non-zero result>
**Control — specificity:** <near-miss input the probe must not flag> -> observed 0
                           (or: NOT TRIGGERED — <which PV-2c condition fails>)
**Extraction:** <bytes or lines read> for the subject; <same> for each control arm
**Result:** <N>
**Verdict:** CLEAN | INDETERMINATE (<missing element>) | BROKEN PROBE |
             OVER-MATCHING PROBE
```

### § 8.3 — Coverage map: the 12 observed shapes against the catching clause

```
 #  Shape (as observed)                                        Class                        Clause      Caught
 1  Page-1 sampling presented as the population                wrong denominator            PV-1        yes
 2  Line truncation on a longer-than-cut line                  truncated extraction         PV-3        yes
 3  Shell modifier silently returns 0 bytes; grep over the
    empty file reports clean                                   empty extraction             PV-3        yes
 4  Unsatisfiable expectation — literal count sought against
    a template holding a repeat block                          non-discriminating predicate PV-2        yes
 5  Wrong artifact compared (raw archive vs a content
    manifest sidecar)                                          wrong subject                none        NO — GAP
 6  Anchored grep vs prefixed output                           non-discriminating predicate PV-2        yes
 7  Right token, wrong section                                 wrong scope                  PV-2b       yes
 8  Zero-byte control — a mutation control produced a 0-byte
    mutant and reported "0 flagged"                            empty extraction, on the
                                                               control                      PV-3 + PV-5 yes
 9  Hard-wrapped corpus defeats a line-anchored grep           match unit != semantic unit  none        NO — GAP
10  Ref probe scoped to heads reports an existing non-head
    ref as missing                                             wrong denominator            PV-1        yes
11  Whitespace assumption — pattern expects a space the live
    text does not carry (a false ALARM)                        wrong pattern                PV-4        yes
12  Predicted instead of measured — state reasoned about
    rather than read                                           no probe at all              PV-0        yes

Verdict: 10 of 12 shapes are caught by a self-executable clause; 2 are not (shapes 5, 9).
```

### § 8.4 — Declared coverage boundary (state this; do not imply more)

```
COVERED — 10 of the 12 observed shapes, across 6 classes:
  wrong-denominator (2 shapes) . truncated-or-empty-extraction (3) .
  non-discriminating-predicate (2) . wrong-scope (1) . no-probe (1) .
  wrong-pattern-false-alarm (1).
The class names are the unit of this list and the shape count is the unit of the
numeral; both are stated so the two can be reconciled against Section 8.3 in one
read rather than inferred.

NOT COVERED — SHAPE BOUNDARY: wrong subject (a 7th class, 1 shape). When the probe
examines a different artifact than the claim is about, both control arms behave
correctly and the record looks healthy. No self-check detects it. It is caught only
by a reviewer comparing the artifact named in PV-1 against the artifact the claim
concerns. Stated as a residual risk, not implied as covered.

NOT COVERED — MATCH-UNIT BOUNDARY: match unit != semantic unit (an 8th class, 1
shape — shape 9). A line-anchored probe over hard-wrapped text returns zero on a
clause spanning a line break while PV-3 is satisfied: the extraction was whole and
untruncated, so no clause fires and the verdict rule returns CLEAN on a false zero.
Normalize the match unit to the semantic unit before trusting such a zero.

NOT COVERED — ACTOR BOUNDARY: this discipline is DELIVERED to the agents that read
the surfaces citing it — review-class skills that load this file, the Stage-5
evidence-grounding review, the per-stage spoke prompt convention, and, for the
orchestrating hub, `hub-spoke-bridge.md` Procedure 7 Step 4, which states itself to
be the hub's delivery surface for Rule 15. A session outside all of those
conventions is bound by the rule as an ACT and is not REACHED by any delivery
surface. That is a delivery gap, distinct from the enforcement gap: the rule is not
merely unenforced there, it is unread. Named here so the coverage claim is not
larger than the delivery.

ASYMMETRY BY DESIGN. PV-0..PV-3 fire on a zero/clean/absent claim. PV-4 and the
PV-2c specificity arm are the two clauses extended to the false-alarm direction.
PV-2c catches an over-matching pattern whenever a discriminating near-miss input is
available; an over-match the prober could not conceive of remains uncovered — the
same epistemic boundary PV-1's denominator carries. The observed population for this
class is a single shape, already caught by PV-4, so no coverage FRACTION is claimed
for the residual: an "N of M" with no M is exactly what Rule 15 forbids. That shape
is the false-ALARM direction only. The same wrong-pattern class can also produce a
false CLEAN — a pattern that misses text it should have matched — a direction not
observed here and therefore carrying no row in § 8.3: unobserved, not covered.
```

---

## See also

- `core/standards/review-composition-framework.md` § 8 Agent-Correction Layer — references the anti-laziness rules of Section 1 as the human-inherited mitigation pool; its § 8.4 maps a named subset of those rules to agent-context applications alongside 3 novel agent-only failure modes (self-preference bias, hallucinated specificity, context anxiety). The rule count is owned by Section 1 of this file and is not restated there.
