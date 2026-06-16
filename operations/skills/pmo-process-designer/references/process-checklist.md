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

---

## Requirement Quality (Mode A)

> **Scope:** This section governs **Mode A (Requirements Definition)** only. It is independent of the six **process**-review dimensions above (Mode B). Mode A runs the four-check Requirement Quality gate (steps 4a–4d in SKILL.md) over each structured requirement; Mode B's process scoring is unchanged. Two of the four checks — INVEST and Given-When-Then — are **consumed by reference** from the canonical rubrics named below and are deliberately **not** restated here (restating would fork the canonical and break duplicate-source discipline). The two genuinely net-new artifacts — the 8-domain completeness set and the NFR category set — are authored in full below because the corpus has no canonical source for them.

### 1. INVEST scoring (pointer — do not re-author)

INVEST scoring applies to **story-class / Functional requirements** (keyed on the requirement's own type tag from SKILL.md Mode A step 3, **not** on any project-level methodology field). For a formal "system shall…" Waterfall requirement, INVEST is reported **`N/A — formal requirement, not a user story`** and the 8-domain completeness check (below) is primary — do not force-score Independent/Small against a compliance statement.

| What | Where it lives (canonical — read this, do not copy it here) |
|------|--------------------------------------------------------------|
| The six INVEST dimensions (Independent, Negotiable, Valuable, Estimable, Small, Testable) — definition + validation question + failure signal + the per-dimension remediation framing | `operations/templates/requirements-template.md` § "INVEST Quality Criteria for User Stories" |
| The scoring **mechanic**: score each dimension **1 (Met) / 0 (Not Met)**; readiness threshold is **≥ 5 of 6** criteria met; a **0 on Valuable or Testable is a hard fail** regardless of total (these two are non-negotiable) | `operations/skills/delivery-engine/references/backlog-health.md` § 2.2 "INVEST Scoring" |

**Output:** a six-row pass/fail table per scored story (one row per dimension, each marked Met/Not Met) + the overall ≥ 5/6 verdict. For every dimension scored 0, draft the specific fix (push-to-resolve) using the per-dimension remediation column from `requirements-template.md` — do not just flag "fails Estimable"; state the remediation ("fails Estimable — team has not seen the vendor API; recommend a time-boxed spike, then re-score"). Each drafted remediation is a decision-class output and carries a reversibility tier per the SKILL.md Reversibility Discipline.

### 2. Given-When-Then enforcement on acceptance criteria (pointer — do not re-author)

| What | Where it lives (canonical — read this, do not copy it here) |
|------|--------------------------------------------------------------|
| The Given-When-Then (Gherkin) format and rules — one G-W-T scenario per AC; 3–7 AC per story; "Then" must be observable (reject subjective terms — "fast", "user-friendly"); negative/edge cases are separate criteria; good/poor worked examples | `operations/templates/requirements-template.md` § "Acceptance Criteria Writing Guide" |
| The **checklist-format escape hatch** for non-behavioral requirements (configuration, data, infrastructure): `- [ ] verifiable condition` is acceptable in lieu of G-W-T | same section, "Alternative: Checklist Format" |

**Enforcement:** when a **behavioral** AC is not in Given-When-Then form, **do not pass it** — reject and produce the drafted G-W-T rewrite (push-to-resolve). **Escape hatch (load-bearing):** for a non-behavioral requirement, the checklist format is acceptable — do **not** false-positive-reject a well-formed infra/data/config checklist by demanding G-W-T ceremony it does not need.

### 3. The 8-domain completeness checklist (net-new — authored here)

Run every structured requirement against the eight completeness domains below. Mark each domain **Covered / Partial / Gap** (reuse the three-level Pass/Partial/Fail scale defined in the Scoring Scale at the top of this file). For every **Partial** or **Gap**, draft the missing piece (DRAFT-labeled, per the REQ-014a–c push-to-resolve pattern) rather than silently leaving it blank. Surface the result as an 8-row coverage strip per requirement (or a roll-up matrix for a set). **Domain 7 (Non-functional) feeds the NFR prompt in §4.**

Each domain is grounded in an existing in-corpus source (this is a reconciliation of existing canon lifted to the requirement altitude, not an invented set):

| # | Completeness domain | The question the requirement must answer | Grounded in |
|---|---------------------|------------------------------------------|-------------|
| 1 | **Actor / role** | Who initiates or benefits from this requirement? | Mode A step 4 (actor) |
| 2 | **Trigger / precondition** | What event or state starts it? | Mode A step 4 (trigger) + Dimension 1 (Trigger defined) |
| 3 | **Expected behavior** | What must the system do? | Mode A step 4 (expected behavior) |
| 4 | **Acceptance criteria** | How is "done" verified? (Given-When-Then per §2, or checklist for non-behavioral) | Mode A step 4 (AC) + Dimension 6 (Acceptance criteria defined) |
| 5 | **Exception / error handling** | What happens when it fails? | Mode A step 4 (exception handling) + Dimension 4 (Exception Handling) |
| 6 | **Data / inputs-outputs** | What data is consumed and produced, with source and format? | Dimension 1 (Inputs specified / Outputs defined) |
| 7 | **Non-functional constraints** | What performance / security / reliability / etc. bounds apply? (feeds §4) | binds to the NFR set in §4 |
| 8 | **Traceability** | Source up + design / delivery / evidence down? | Mode A "maintain the chain" + Dimension 5 (Traceability) |

### 4. NFR category set + prompt-when-absent (net-new — authored here)

The corpus has no canonical non-functional-requirement category taxonomy, so the set below is grounded externally to **ISO/IEC 25010 (Product Quality Model)** — the recognized international standard for software quality attributes (supersedes ISO/IEC 9126). Use these seven categories both as the domain-7 reference and as the prompt enumeration.

| NFR category (ISO/IEC 25010) | Prompt the requirements author for… |
|------------------------------|--------------------------------------|
| **Performance efficiency** | throughput, response-time, and capacity targets |
| **Security** | authentication / authorization, data protection, audit, compliance constraints |
| **Reliability / Availability** | uptime target, fault tolerance, recoverability (RTO / RPO) |
| **Usability / Accessibility** | accessibility standard (e.g., WCAG), learnability, error prevention |
| **Compatibility / Interoperability** | integration contracts, data-exchange formats, co-existence |
| **Maintainability** | modularity, testability, change-cost expectations |
| **Scalability / Portability** | growth headroom, environment portability |

**Prompt-when-absent rule:** after classifying requirements (SKILL.md step 3) and running the 8-domain checklist (§3), check whether the requirements **set** contains **any** requirement of type Non-Functional (or any domain-7 entry). **When the count is zero, do not pass silently** — emit a single consolidated NFR prompt enumerating the seven categories above and ask which apply, drafting `[INFERRED]` / `[ASSUMPTION – CONFIRM]` candidate NFRs where the business context implies them (e.g., a payments flow implies a Security + Performance NFR even if unstated). The prompt counts against the Max-5-questions budget as **one** question, not seven.
