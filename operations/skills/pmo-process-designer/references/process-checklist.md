# Process Checklist — PMO Reference

## Purpose

This file provides the structured review checklist for validating process designs
and process documentation quality. The pmo-process-designer skill reads this file
in Mode B (Process Documentation & Optimization) to evaluate existing processes
and validate new process designs before deployment.

---

## Process Review Dimensions

Every process review evaluates six dimensions. Each dimension is scored independently
using the three-level scale below.

### Scoring Scale

| Score | Label | Meaning |
|-------|-------|---------|
| **Pass** | Fully satisfies the dimension | All criteria met; no gaps; ready for deployment |
| **Partial** | Satisfies the dimension with gaps | Core intent is met but specific criteria are missing or incomplete; requires remediation before deployment |
| **Fail** | Does not satisfy the dimension | Fundamental gaps that would cause the process to fail in operation; requires redesign |

### Overall Process Score

| Result | Criteria | Action |
|--------|----------|--------|
| **Approved** | All 6 dimensions Pass | Deploy the process |
| **Conditional** | No dimension Fails; at least one Partial | Document remediation items; deploy with tracked remediation plan |
| **Rejected** | Any dimension Fails | Redesign required; re-review after remediation |

---

## Dimension 1: Completeness

Does the process cover all required elements from trigger through output?

| Criterion | Pass | Partial | Fail |
|-----------|------|---------|------|
| **Trigger defined** | Specific event or condition that initiates the process is documented | Trigger exists but is vague or ambiguous | No trigger defined; unclear when process starts |
| **Inputs specified** | All required inputs listed with source and format | Inputs listed but missing source or format for some | Inputs not documented |
| **Steps sequenced** | All steps numbered and sequential; no gaps in flow | Steps exist but sequence has gaps or ambiguous ordering | Steps missing or unordered |
| **Outputs defined** | All outputs listed with consumer and format | Outputs listed but missing consumer or format | Outputs not documented |
| **Roles assigned** | Every step has a named responsible role | Most steps have roles; some are unassigned | No role assignments |
| **End state clear** | Process has a defined completion condition | Completion implied but not explicit | Process has no clear end state |

---

## Dimension 2: Clarity

Can a person unfamiliar with the process execute it correctly from the documentation alone?

| Criterion | Pass | Partial | Fail |
|-----------|------|---------|------|
| **Unambiguous language** | Each step has only one possible interpretation | Minor ambiguities that context resolves | Steps could be interpreted multiple ways with different outcomes |
| **Jargon controlled** | Technical terms defined on first use or linked to glossary | Some undefined jargon; context makes meaning guessable | Extensive jargon without definition; insider knowledge required |
| **Step granularity appropriate** | Steps are at the right level — not too coarse (skips important detail) nor too fine (micromanages) | Granularity mostly appropriate with occasional under- or over-specification | Steps too coarse to execute or too fine to follow practically |
| **Visual aids present** | Flowcharts, diagrams, or decision trees supplement text where complexity warrants | Text-only but still followable | Complex branching described only in prose; needs visual aid but lacks one |

---

## Dimension 3: Decision Clarity

Are all decision points in the process explicitly identified with criteria and authority?

| Criterion | Pass | Partial | Fail |
|-----------|------|---------|------|
| **Decision points identified** | Every branch point is explicitly marked as a decision | Most branches marked; some implicit | Decision points embedded in narrative without explicit marking |
| **Decision criteria stated** | Each decision has explicit criteria (what condition triggers which branch) | Criteria exist but are vague ("if appropriate," "as needed") | No criteria; decision left to judgment without guidance |
| **Decision authority named** | Each decision names who makes it (specific role or named individual) | Authority implied but not explicitly stated | No authority defined; unclear who decides |
| **Default path defined** | When no decision is made (timeout, unavailable authority), a default path exists | Default path exists for some decisions but not all | No defaults; process halts on any undecided branch |
| **Escalation path defined** | When decision authority cannot resolve, escalation path is documented | Escalation exists for critical decisions only | No escalation path defined |

---

## Dimension 4: Exception Handling

Does the process define what happens when things go wrong?

| Criterion | Pass | Partial | Fail |
|-----------|------|---------|------|
| **Failure modes identified** | Common failure scenarios are documented with response | Major failures covered; edge cases missing | No failure handling documented |
| **Error recovery defined** | For each failure mode, recovery steps return the process to a known state | Recovery exists for some failures | No recovery procedures |
| **Timeout handling** | Process defines what happens when a step exceeds expected duration | Timeouts defined for critical steps only | No timeout handling; process can hang indefinitely |
| **Rollback capability** | Process can be reversed or unwound if a late-stage failure occurs | Partial rollback; some steps are irreversible and documented as such | No rollback consideration; process assumes success |

---

## Dimension 5: Traceability

Can each process element be traced to its justification and its consumers?

| Criterion | Pass | Partial | Fail |
|-----------|------|---------|------|
| **Upstream trace** | Process links to the business need, requirement, or governance mandate it serves | General rationale exists but no specific link | No rationale for why this process exists |
| **Downstream trace** | Process outputs link to consuming processes or artifacts | Most outputs have consumers identified | Outputs produced but consumers unknown |
| **Requirement-to-step mapping** | Each requirement the process fulfills maps to specific step(s) | Mapping exists for major requirements | No mapping; requirements and steps are disconnected |
| **Test-to-requirement mapping** | Acceptance criteria or tests exist for each requirement the process addresses | Tests exist for critical requirements | No testing or verification defined |

---

## Dimension 6: Testability

Can the process be verified to work correctly before deployment?

| Criterion | Pass | Partial | Fail |
|-----------|------|---------|------|
| **Acceptance criteria defined** | Process has explicit criteria for "this process works correctly" | General success criteria exist | No acceptance criteria |
| **Dry-run feasible** | Process can be tested in a non-production context | Partial dry-run possible; some steps require production | Process can only be tested live |
| **Metrics defined** | Process health metrics are specified (cycle time, error rate, compliance rate) | Some metrics identified | No process metrics |
| **Verification method defined** | How to confirm the process produces correct outputs is documented | Verification implied but not specified | No verification approach |

---

## Cross-Reference Validation Rules

After dimension scoring, validate cross-process integrity:

| Validation | Check | Pass Criteria | Failure Impact |
|-----------|-------|---------------|---------------|
| **Requirement → Step** | Does each requirement map to at least one process step? | Every requirement has a traceable implementation step | Unimplemented requirements; governance gaps |
| **Step → Output** | Does each process step produce a defined output? | Every step either produces an output or modifies state that a subsequent step consumes | Dead-end steps; wasted effort |
| **Output → Consumer** | Does each process output have a defined consumer? | Every output is consumed by a downstream process, artifact, or decision | Zombie outputs; artifacts created but never used |
| **Input → Source** | Does each process input have a defined source? | Every input can be obtained from a named source process or artifact | Missing inputs; process cannot start |
| **Decision → Authority** | Does each decision point have a named authority? | Every decision has exactly one accountable authority (single-A rule) | Accountability gaps; decisions stall |
| **Exception → Recovery** | Does each exception have a recovery path? | Every identified failure mode has a defined response | Unhandled failures; process breaks silently |

---

## Lifecycle Alignment Check

Validate that the process fits within the delivery lifecycle stage it claims to serve.

| Lifecycle Function | Process Must Demonstrate | Red Flag |
|-------------------|------------------------|----------|
| **Capture** (Intake, Triage) | Standardized entry criteria; classification mechanism; routing rules | Process accepts unstructured input without classification |
| **Prepare** (Planning, Solutioning) | Decomposition from upstream; readiness criteria for execution handoff | Process produces outputs that execution cannot consume without rework |
| **Build** (Engineering, Dev Testing) | Quality gates embedded in flow; feedback loops within the process | Quality checked only at process exit; no mid-process gates |
| **Validate** (QA, Plan Review) | Independence from Build; criteria defined before validation begins | Validation criteria created after seeing the output (confirmation bias) |
| **Deliver** (Execute, Verify, Close) | Rollback capability; verification against acceptance criteria; closure protocol | No rollback plan; no verification step; process ends without formal closure |

---

## Review Worksheet Summary

| Dimension | Score | Notes | Remediation Required? |
|-----------|-------|-------|----------------------|
| 1. Completeness | ___ | | |
| 2. Clarity | ___ | | |
| 3. Decision Clarity | ___ | | |
| 4. Exception Handling | ___ | | |
| 5. Traceability | ___ | | |
| 6. Testability | ___ | | |
| **Cross-Reference Validation** | ___ / 6 passing | | |
| **Lifecycle Alignment** | ___ | | |
| **Overall** | Approved / Conditional / Rejected | | |
