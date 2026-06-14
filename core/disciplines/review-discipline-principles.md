---
title: Review Discipline Principles
purpose: Shared discipline methodology for review-class skills (audits, QA, reviews)
applies_to: build-reviewer, pmo-qa-auditor, pmo-skill-editor Mode D, future audit skills
source: Extracted from build-reviewer/SKILL.md (2026-04-18 Anthropic mapping analysis)
---

# Review Discipline Principles

Shared discipline methodology for review-class skills. When a skill's primary function is reviewing, auditing, or evaluating another output, it inherits the rules below. Review-class skills include `build-reviewer`, `pmo-qa-auditor`, `pmo-skill-editor` Mode D, and any future audit skill.

---

## Section 1 — Anti-Laziness Rules (14 rules)

These rules govern HOW findings are produced — the output discipline that separates principal-grade review from surface pass. Rules 1–10 are extracted verbatim from `release/skills/build-reviewer/SKILL.md` and apply unchanged to any review-class skill; rules 11–14 were added subsequently and are native to this shared discipline.

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

## See also

- [`../standards/review-composition-framework.md § 8 Agent-Correction Layer`](../standards/review-composition-framework.md) — references the 14 anti-laziness rules of Section 1 as the human-inherited mitigation pool; § 8.4 maps 6 of the 14 rules to agent-context applications alongside 3 novel agent-only failure modes (self-preference bias, hallucinated specificity, context anxiety).
