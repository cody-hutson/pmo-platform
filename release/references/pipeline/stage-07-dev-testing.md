<!-- reference-durability: allow-link -->
# Stage 7: Dev Testing

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Independent quality review of implemented changes — the Layer 2 automated review that catches what Engineering's self-review misses. Produces a scored quality report with findings for human review, NOT auto-correction. Key principle: the reviewer must not be the author. Dev Testing runs with fresh context — not the implementing agent's conversation.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Developer-level testing; unit and integration verification | Independent quality review of PR content against AC and platform standards |
| Governance Focus | Test coverage, defect tracking | Quality scoring, escape detection, eval set results |
| Artifact Inputs | Source code, unit tests, build artifacts | PR with committed changes, verification plan, Engineering self-verification evidence |
| Artifact Outputs | Test results, defect reports, coverage metrics | Quality review report with LLM-graded assessment, eval set results, escape detection |

Key compression: Ref Model assumes automated test suites, CI pipelines, and runtime environments. Our platform is documentation and governance — "testing" = content quality review + structural validation + contract verification. The independent reviewer replaces the peer code reviewer of traditional software engineering.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Decision maker: Human operator | — | — | Tier 3 (accepts/rejects findings) |
| Quality reviewer (primary): QA Auditor Skill 11 | Dev Testing (PR + release plan → eval-assertion ladder → PR-comment quality report) | Mode G | Tier 1/2 split |
| Standards checker (secondary): Principal Eng Skill 9 | Implementation & Code Quality | Mode 3 (Tech Lead) | Tier 1 (Auto) |

Author-reviewer separation: Current state = fresh conversation session. Future state = eval scripts per the canonical eval-type taxonomy. Anti-pattern: running Dev Testing in the same session as Engineering.

## 4. Inputs
From Engineering: PR with committed changes, sub-task completion status, self-verification evidence, deviation log.
From Planning: release plan (verification plan, AC per issue, file change matrix).
From Solutioning (when activated): design specs, ADR decisions.
From QA (return path, when applicable): QA Return to Dev Testing payload per [DT↔QA Handoff Protocol](#dtqa-handoff-protocol) — triggers Pass N+1 full re-review.
Contextual: `core/rules/`, `principal-standard-checklist.md`, `regression-checks.md`, `grader.md`.

Set at Stage 7: quality review scores (1-5 per dimension), finding list with severity, escape rate, overall verdict (PASS/CONDITIONAL PASS/FAIL).

## 5. Process
**Phase A — Structural Review (Tier 1 Auto):** Deterministic checks, always-on unless the entry is marked **conditional** — PR completeness (Blocker), layer boundary (Blocker), deployed copy sync (Blocker), sub-task completion (Warning), regression check (Warning), **deprecated-path scan for new-file deliverables (Blocker, conditional)**, **domain-practice provenance verification (Warning, conditional — per § Domain-Practice Provenance Verification Step below)**, **A8 runtime-suite gate (Blocker, conditional — per § A8 Runtime-Suite Gate below)**.

**Deprecated-path scan for new-file deliverables (Source: deprecated-path scan spec):** For each new file in the PR scope, execute a deterministic grep scan against the release's `Files Removed` list. The list is sourced from the release plan's explicit `Files Removed` section when present; otherwise derive via `git diff main..release/<milestone> --diff-filter=D --name-only`. For each match, classify as Tier 1 (Engineering re-author via `fix(dt):` commit per [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol)) by default. **Exception:** matches where the PR body explicitly documents the reference as "intentional documentary reference to deprecated path with paired new-path fallback" are downgraded to Note severity (no routing). Tier escalation to Tier 2 (Scope Change) when re-author requires design revision; Tier 3 (Plan Rejection) when the removed path was load-bearing on the new file's premise.

**Cutover discipline:** Applies to all releases going forward.

**Domain-Practice Provenance Verification Step:** Phase A asserts that the release plan file (`release/releases/plans/v<X.Y>_RELEASE_PLAN.md`) carries a `domain_practice` provenance label authored by the Stage 4 Planning spoke's Domain-Best-Practice Sourcing-or-Flag Step. This is a Tier-1 deterministic check — it verifies *that a domain was declared*, not that the design conforms to it (conformance is the separate Phase C dimension; see the provenance-vs-conformance composition note under Phase C). The label is verified for:

1. **Presence:** the release plan must contain a single-line `domain_practice:` label (within the `### Release Class declaration` H3 or a sibling `### Domain Practice Provenance` H3, per the Stage 4 placement convention).
2. **`date` field populated:** the label's `date` field must be a `YYYY-MM-DD` value (mandatory in BOTH Mode A and Mode B, so staleness is detectable).
3. **`source` field present:** one of three legitimate forms:
   - Mode A — a citation URL or repo-relative path
   - Mode B — the literal token `UNSOURCED-DOMAIN` paired with a `rationale` sub-field
   - Software / governance / pipeline-internal exemption — the literal token `N/A — pipeline-internal release`, per the Stage 4 pipeline-internal exemption
4. **`domain:` class field present (mandatory in every mode):** the label must carry a `domain:` key INSIDE the `domain_practice` object, naming the deliverable's abstract domain class (e.g., `software`, `governance`, `web`, `data`). Per Stage 4 §5.7 the `domain:` field is mandatory in EVERY mode — Mode A, Mode B, AND the pipeline-internal exemption — so no release reaches Stage 5/7 carrying an unclassified deliverable, and the design-aware downstream consumers (the impact-analysis method selector, the design-best-practice review criterion, and the domain-guide index) all read this one field. The check asserts the key is present and in-label (a sibling-to-`source` member of the `domain_practice` object, not a separate top-level frontmatter key). This field is the input the Phase C domain-practice conformance dimension resolves the guide from — the provenance step verifying its presence is what lets Phase C assume a resolvable class.

**Verification command:**
```bash
# (1) label present; (2) the in-label domain: class field present
grep -nE "^[[:space:]]*domain_practice:" release/releases/plans/v<X.Y>_RELEASE_PLAN.md
grep -nE "domain_practice:.*\bdomain:[[:space:]]*[A-Za-z]" release/releases/plans/v<X.Y>_RELEASE_PLAN.md
```

**Failure classification:**

| Finding | Severity | Routing |
|---|---|---|
| Label absent | Warning | Tier 1 — Engineering adds the label via `fix(dt):` commit; flags the domain-detection follow-up if the auto-detection mechanism is the gap |
| Label present, `date` field missing or malformed | Warning | Tier 1 — Engineering refreshes the label via `fix(dt):` commit |
| Label present, Mode B `UNSOURCED-DOMAIN` with no `rationale` sub-field | Warning | Tier 1 — Engineering adds rationale via `fix(dt):` commit |
| Label present, Mode B `UNSOURCED-DOMAIN` with rationale — but rationale does not name the unresolved domain | Note | Logged; no routing (the explicit UNSOURCED-DOMAIN flag with any rationale satisfies the disclosure obligation) |
| Label present, but the mandatory in-label `domain:` class field is absent (or placed as a separate top-level key rather than inside `domain_practice`) | Warning | Tier 1 — Engineering adds the in-label `domain:` class field via `fix(dt):` commit; the field is mandatory in every mode per Stage 4 §5.7 |

**A8 Runtime-Suite Gate (Blocker, conditional):** When the PR touches a code path that maps to a runtime test suite per [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md) (rows 1–5; row 6 is the explicit no-match fallback), Phase A runs the selected suite as a gate input and records the outcome as a `test-run` event. This is a Tier-1 deterministic check (a suite passes or fails — it is not an LLM-graded quality score, so it belongs in Phase A, not the Phase C scored dimensions). A doc/governance/spec-only PR matches the map's no-match row → A8 emits `test-run/suite-skip` and is a no-op gate (no ceremony). **Row 4 (tool self-tests) is CI-enforced, not hand-run:** the `selftest-discovery` job in `.github/workflows/release-tooling-smoke.yml` executes every discovered `--self-test` across the two release tool trees on any in-scope PR, so A8 cites an enforced gate for that row rather than a command someone claims to have run — and a self-test recorded as PASS with no CI evidence is now a finding, not a formality.

**Execution environment:** the selected runner executes in a **`HOME`-overridden `/tmp` sandbox** (`HOME=$(mktemp -d)` before invocation) — the suite mutates a real install path; unsandboxed it corrupts the operator's live `~/.claude/`. Two execution loci, same result surface: (1) **CI (authoritative)** — the deploy/hook suites run as discrete steps in `.github/workflows/install-tests.yml`; A8's preferred evidence is the CI run result (`projects_to:actions-run:<url>` in the event payload); (2) **Local DT fallback** — when CI evidence is unavailable at review time, the DT spoke runs the selected runner locally under the `/tmp` HOME-override and records the pass/fail counts.

**Pass/fail → verdict mapping (the gate teeth):**

| Suite result | A8 finding | Severity | Phase D verdict effect | `test-run` subtype emitted |
|---|---|---|---|---|
| All selected suites pass | A8 clean | — (no finding) | no effect | `suite-pass` |
| Any selected suite fails | A8-FAIL | **Blocker** | FAIL (any Blocker → FAIL per Phase D) → routes to Engineering as Tier 1 `fix(dt):` when fixable-in-scope, else Tier 2/3 | `suite-fail` |
| No path matches (map no-match row) | A8 not-applicable | — | no effect | `suite-skip` |
| Suite selected but runner errors (infra) | A8-INFRA | Warning | logged; operator / CI investigates (not an Engineering code fix) | `suite-fail` with `reason:runner-error` |

A failing runtime suite is the strongest possible "the code does not work" signal — stronger than any content-quality dimension — so it is a Blocker, consistent with Phase D's "any blocker → FAIL". The A8 outcome populates the **Test-results** field of the DT↔QA Handoff Payload (see § DT↔QA Handoff Protocol → Forward Handoff).

**Cutover discipline:** Applies to all releases going forward.

**S7-I04 Branch-freshness assertion (Blocker, deterministic):** Phase A asserts the release branch has no base-branch commits unreachable from `HEAD` — a branch that has fallen behind its base can merge stale. This is a Tier-1 deterministic check (the branch is fresh or it is not; it is not an LLM-graded score). It runs the executable runner [`assert_branch_fresh.py`](../../skills/pmo-skill-refiner/scripts/assert_branch_fresh.py) (`git log --oneline <base> ^HEAD`; empty → PASS/exit 0, non-empty → FAIL/exit 1 listing the unreachable commits). The graded/discoverable half is the `stage-07-branch-freshness` eval in the Stage-7 stage-gate eval set (`core/skills/eval-writer/evals/stage-gates/stage-07-dev-testing/evals.json`). A FAIL is a Blocker routed Tier 1 — Engineering rebases the branch onto its base and re-runs, per the DT↔Engineering Iteration Loop Protocol. **Cutover discipline:** applies to all releases going forward.

**Plan-verification re-execution (optional, deterministic):** Dev Testing MAY re-run [`release/tools/verify-release-plan.sh`](../../tools/verify-release-plan.sh) against the release plan as an independent re-execution of the plan's per-issue / integration / regression / sync checks — the authoritative re-run of the Engineering self-verification whose evidence Phase A consumes. It sits alongside the A8 runtime-suite gate: A8 gates the runtime suites, while the plan-verification executor re-runs the whole plan's declared check set (dispatching the runtime-suite family through the same `test-run` event path A8 uses, so a re-run and an A8 run agree by construction). A non-zero exit (any FAIL/ERROR verdict) flags a check that no longer holds on the final PR SHA — routed like any Phase-A finding. The executor is also the sole runner of the plan's Cross-Issue Acceptance Criteria methods; the Stage-9 release-integration check reads those emitted verdicts read-only, so re-running here refreshes them against the PR head.

**Required-gate spot-check (advisory, Note severity — never a Blocker).** Phase A reads the release PR verdicts of the required branch-protection checks rather than re-implementing their detection. The `Issue-reference validity gate` is the worked example: it already scans exactly the changed-deliverable delta for the two classes it enforces — a bare `#N`-form issue reference placed outside a designated reference block and carrying no inline provenance marker, and a deprecated `IMP-NNN` reference — and it has already run on the current PR head, so its verdict cannot drift from what branch protection applies at merge. Read every required row with `gh pr checks <PR> --required --json name,state,bucket,link`; in this `--json` form the command exits **0** even when a required row is failing or pending — the exit code signals only an unresolvable PR or an authentication failure — so branch on the parsed rows and never on the exit code. Four outcomes, and only the first is clean: a `bucket` of `pass` on every required row is clean; any row with a `bucket` of `fail` raises an advisory Note naming that gate — and, for the issue-reference gate, both enforced classes above — following the row link for the file-and-line findings; any row with a `bucket` of `pending`, `cancel`, or `skipping` raises an advisory Note that the gate has not returned a verdict and must be re-read before the stage verdict, because unresolved is NOT clean; and a missing row, an empty result, or a failed read raises an advisory Note that the gate did not report at all, which a renamed context or a mis-scoped workflow would produce, because unread is NOT clean.

**Authoritative gate: branch protection.** This spot-check is a review signal only. It has no gate authority, cannot fail Phase A, and never produces a Blocker or a Warning — every outcome above routes as a Note. Enforcement belongs to branch protection on the default branch, which blocks the merge independently; a second blocking path would create a second place for one finding to stop a release with no added protection. Two scope notes for readers: the gates scan only lines ADDED since the PR base, so pre-existing references in untouched regions are correctly not flagged; and the release tracking surface is exempt by design, because issue and pull-request references are native provenance there.

**Cutover discipline:** Applies to all releases going forward.

**Phase B — Contract Review (Tier 1/2):** 3 checks — AC verification per issue (LLM-graded, Blocker), stage input consumption (LLM-graded, Warning), stage output completeness (Deterministic, Warning).

**Phase C — Content Quality Review (Tier 2 Recommend):** 5 always-on scored dimensions + 1 conditional (domain-practice conformance). The 5 always-on dimensions — clarity (1-5, threshold 3), accuracy (1-5, threshold 3), internal consistency (1-5, threshold 4, Blocker), convention depth (1-5, threshold 3), escape detection (count) — score on every release. The conditional 6th dimension (domain-practice conformance, below) scores only when a domain guide applies for the deliverable's domain.

> **Provenance vs. conformance — two distinct, composed checks.** The Phase A *Domain-Practice Provenance Verification Step* checks that the `domain_practice` **label is present** (dated, sourced, and carrying the mandatory `domain:` class field) — it verifies *that a domain was declared*. It is Tier-1 deterministic ("label present", a grep). The Phase C *domain-practice conformance dimension* checks that **the design meets that declared domain's authoritative practice** — it verifies *that the design is right for the declared domain*. It is Tier-2 LLM-graded ("design meets the domain's practice"). Provenance is necessary but not sufficient: a present, well-formed label can still front a domain-wrong design. The two checks compose — provenance gates label hygiene, conformance gates design conformance; neither subsumes the other.

- **domain-practice conformance** (1-5, threshold 3, **conditional** — scored only when a domain guide applies for the deliverable's domain): assess the implemented design against the target domain's authoritative practice. This is a WIRING of the shipped applicability framework — it invokes, and does NOT redefine, [`applicability-framework.md`](../../../core/disciplines/applicability-framework.md) §2 Applicability Profile, §3 Contraindication Catalog (CI-*), and the §4 precedence ladder, against the deliverable's domain guide under [`core/standards/domain-best-practices/`](../../../core/standards/domain-best-practices/). Resolve the guide `core/standards/domain-best-practices/<domain>.md` from the `domain:` class field inside the release plan's `domain_practice` label (the abstract domain signal the Phase A provenance step verified present — this dimension consumes that field, it does not re-derive the domain). Then run §2 `APPLIES-WHEN` scoping → §3 `CONTRAINDICATED-WHEN` evaluation (any CI-* that fires on an applied practice is a finding) → score conformance to the guide's practice dimensions. This is the ASSESSMENT counterpart to Phase A's provenance (label-present) check — see the composition note above. When no guide exists for the resolved domain, emit a `Note`-severity `DOMAIN-PRACTICE-NOT-ASSESSED` finding naming the unresolved domain (an honest signal — no score, no block; it feeds the domain-guide library demand-signal). **Governance / pipeline-internal deliverables run the FULL walk — no exemption short-circuit:** a governance deliverable carries `domain: governance`, so resolve `governance.md`, confirm `APPLIES-WHEN`, and run the §3 check (the governance guide's contraindication is CI-3 — research-grade / formal-audit imposed where lightweight self-review suffices). A well-behaved governance design does not trip CI-3 and meets the compliance/auditability/traceability dimensions → conformance met, no false finding. The `N/A — pipeline-internal release` token governs the Phase A *provenance* exemption only; it does NOT exempt this conformance dimension. (This is consistent with Stage 4 §5.7's "sourcing-exempt, not classification-exempt" reconciliation: a pipeline-internal release skips external sourcing, but its `domain:` class still resolves the governance guide, which IS the encoding of the platform's own internal-deliverable practice.)

**Domain-practice conformance — failure classification (mirrors the Phase A provenance-table form):**

| Finding | Severity | Routing |
|---|---|---|
| Domain guide exists; a `CONTRAINDICATED-WHEN` CI-* fires on an applied practice | Blocker when the contraindication is structural; else Major | Tier 1 — Engineering re-designs the contraindicated practice via `fix(dt):` commit; Tier 2 when it needs design revision |
| Domain guide exists; conformance score < threshold 3 | Warning → Major/Minor at report assembly | Tier 1 — Engineering addresses the shortfall via `fix(dt):` commit |
| No guide for the resolved domain (`DOMAIN-PRACTICE-NOT-ASSESSED`) | Note | Logged; no routing; flags the domain-guide library demand-signal (the missing-guide gap) |

**Cutover (introducing-release-exempt):** The domain-practice conformance dimension applies to releases entering Stage 7 Dev Testing strictly AFTER this dimension's introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the dimension shipping in a release does not score its own Stage 7 (it would assess its own not-yet-shipped rule, a reflexive-pipeline loop); the introducing release's own Stage 7 runs under the rules in force before this dimension shipped.

**Phase D — Report Assembly (Tier 1 Auto):** Compile findings, classify (Blocker/Warning/Note), assign per-finding disposition (fix-now / defer / accept) per the [Finding Disposition Decision Framework](#finding-disposition-decision-framework), calculate escape rate, render verdict: PASS (no blockers, all ≥ threshold) / CONDITIONAL PASS (no blockers, 1-2 below) / FAIL (any blocker).

**Phase E — Human Review + Iteration Routing (Tier 3):** Review findings, accept or override with rationale. Apply the [Finding Disposition Decision Framework](#finding-disposition-decision-framework) to render per-finding disposition (fix-now / defer / accept). Route per verdict: PASS/CONDITIONAL PASS → advance to Stage 8. FAIL with Tier 1 findings → return to Engineering per [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol); Engineering fixes via Phase E, DT re-enters at targeted re-review scope. FAIL with Tier 2/3 findings → escalate to operator per inter-stage feedback protocol. On Pass 2+, DT executes targeted re-review (per iteration protocol), then re-enters Phase D for updated verdict before returning to Phase E.

**Ticket lifecycle:** Claim: set Stage→7-DevTesting. Execute: Pass 1 = A-E. Pass 2+ = targeted re-review per iteration protocol → D → E. Resolve: post quality report (with iteration history if applicable), route per final verdict. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** Tracking (handoff payload format); Handoff (DT↔QA protocol). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Quality Review Report: section scores, finding list with severity and routing tier classification, escape rate, overall verdict. Report terminates with the structured Handoff Payload per [DT↔QA Handoff Protocol §Forward Handoff](#dtqa-handoff-protocol) — this is Stage 8's authoritative input. Downstream: PASS/CONDITIONAL PASS → to Stage 8 (quality report + PR). FAIL with Tier 1 findings → classified finding list to Engineering for iteration (per [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol)). FAIL with Tier 2/3 findings → escalation package to operator. Pass 2+ reports: appended "Iteration N" section with re-verification results and updated verdict. On QA return path: DT emits Return-to-QA Verified signal per [DT↔QA Handoff Protocol §Return Path](#dtqa-handoff-protocol) after confirming fix.

Stage 7 does NOT produce: design decisions (Stage 5), acceptance verdicts (Stage 8), deployment actions (Stage 12). Stage 7 does NOT fix findings — it classifies and routes them.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all files reviewed, all AC checked, no unresolved Blockers, quality scores ≥ threshold (or override documented), escape rate logged, report posted; incoming deferred items accounted (every item whose Target stage = this stage, per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md), is picked up or re-deferred with rationale — zero unaccounted incoming deferrals); registered eval invocations executed (or SKIP no-op recorded) per [§ Automated Eval Invocation Protocol](#automated-eval-invocation-protocol).
Judgment (1-5): review thoroughness, finding quality, independence (escape count > 0 expected), report clarity.
Calibration: precision tracking, escape-to-QA rate, time-to-complete. Threshold adjustment after 3+ releases.

## 8. Automation Level
Overall Tier 1/2 mix. Structural checks (A1-A5) automatable now (deterministic). Content quality (C1-C4) requires LLM grading. Human decision stays Tier 3. Leverages existing infrastructure: `principal-standard-checklist.md`, `regression-checks.md`, `grader.md`, `run_eval.py`.

## 9. Gap Summary
4 gaps. Key: fresh-context separation not enforceable (P3).

## 10. Retro
To be populated after execution.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `dt-pass` / `dt-conditional-pass` / `dt-return` | DT verdict rendered at end of Phase A review; ALSO captured in `calibration-data.md` — payload carries `projects_to: calibration-data.md:<row-anchor>` | `spoke:#N` (DT spoke) |
| `iteration` | `dt-eng-pass-N` | DT↔Eng iteration counter post-increment per DT↔Engineering Iteration Loop Protocol below; ALSO captured in `iteration-log.md` — payload carries `projects_to: iteration-log.md:<row-anchor>` | `hub` |
| `scope-change` | `tier-1-adjust` | Escape detected during deprecated-path scan or AC re-check; routed as Tier 1 finding to Engineering for `fix(dt):` commit | `spoke:#N` |
| `test-run` | `suite-pass` / `suite-fail` / `suite-skip` | Phase A8 runs the selected runtime suite per [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md); `suite-fail` → Blocker → FAIL | `spoke:#N` (DT spoke) |

Cutover discipline: Applies to all releases going forward — this stage emits these events for any release at Stage 7.

## DT↔Engineering Iteration Loop Protocol

This protocol instantiates the general [Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol) for the Stage 6 (Engineering) ↔ Stage 7 (Dev Testing) boundary. It defines how DT findings route back to Engineering, how Engineering responds, and how DT re-reviews — iterating until the quality gate passes or escalation triggers. Feedback arriving as PR review comments or issue-thread comments enters this loop only from trusted-set authors — the author-association trust boundary ([`release-process.md` § Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol)) gates ingest; an untrusted-authored comment is surfaced to the operator as untrusted third-party content and is never classified into the loop's tiers.

### Loop Flow
<!-- design-artifact: flow-class=agent-process; name=dt-engineering-iteration-loop; depicts=release/references/pipeline/stage-06-engineering.md,release/references/pipeline/stage-07-dev-testing.md -->

```
Pass 1: DT full review (Phases A–D) → Quality Review Report
  ↓
Finding classification → route per severity and scope
  ↓
┌─ Tier 1 findings (Minor Adjustment) → Engineering fixes on release branch
│   Engineering commits with fix(dt): convention, [ADJUST] tag per the inter-stage feedback protocol
│   ↓
│   Pass 2+: DT targeted re-review (affected assertions + regression)
│   ↓
│   Clean → advance to Stage 8
│   New findings → re-classify and loop
│
├─ Tier 2 findings (Scope Change) → escalate to operator
│   [SCOPE CHANGE] signal per the inter-stage feedback protocol
│   Operator decides: adjust plan or proceed with deviation documented
│
└─ Tier 3 findings (Plan Rejection) → escalate to operator
    [PLAN REJECTION] signal per the inter-stage feedback protocol
    Operator re-runs upstream stage for affected issue(s)
```

### Finding Classification

DT classifies each finding by severity (Blocker/Warning/Note per Phase D) AND by routing tier:

| Finding Severity | Routing | Feedback Tier | Action |
|---|---|---|---|
| Blocker — fixable within scope | Engineering | Tier 1 (Minor Adjustment) | Engineering fixes, DT re-reviews |
| Blocker — requires scope change | Operator | Tier 2 (Scope Change) | Operator decides adjustment |
| Blocker — plan fundamentally unworkable | Operator | Tier 3 (Plan Rejection) | Operator returns to upstream stage |
| Warning — fixable within scope | Engineering | Tier 1 (Minor Adjustment) | Engineering fixes, DT re-reviews |
| Warning — requires judgment call | Operator | Tier 2 (Scope Change) | Operator decides accept or fix |
| Note | Logged | — | No action required; tracked for calibration |

**Classification rule:** "Fixable within scope" = the fix does not change acceptance criteria, does not require new files outside the change matrix, and does not alter the design approach. When uncertain, classify as Tier 2 (over-escalate per the inter-stage feedback protocol escalation rule).

### Finding Disposition Decision Framework

The Finding Classification table above is the **WHERE-axis** — it routes a finding (Engineering vs operator) at Tier 1/2/3. This subsection adds the **WHEN-axis** — for each finding, *fix-now* (this release) vs *defer* (a future release) vs *accept* (as-is). The two axes compose: classify WHERE first, then dispose WHEN. Disposition is applied by the human at Phase E (Tier 3); the framework is advisory input, not auto-correction.

The disposition matrix (5 factors), the Step 1 weighted-disposition logic, the Step 2 tie-break, and the scoring skeleton are the **stage-agnostic core** — defined once in [`release/references/standards/finding-disposition-framework.md`](../standards/finding-disposition-framework.md) and shared verbatim with Stage 8 QA. The factors are **Effort (H)**, **Best-Practice Alignment (H)**, **Downstream Impact (M)**, **Reversibility/Risk (M)**, and **Scope-Window (L, gate-modifier)**; the decision logic weights signals High = 3 / Medium = 2 / Low = 1 and resolves ties Reversibility-Accept > cheap-and-open-Fix-Now > Defer. Stage 7 reuses that shared core unchanged and defines only its own **Step 0 precedence gate** below.

#### Step 0 — Stage-7 precedence gate (applied before weighing)

An open **Blocker** is **fix-now** when "fixable within scope" (per the Classification rule above), else **escalate** (Tier 2/3). An open Blocker is **never** Defer or Accept by the weighted layer; doing so requires an explicit operator override with documented rationale. A **Note** is **Accept (informational)** — the `Note → Logged → No action` row above *is* the accept disposition. (This gate is why a trivial best-practice Blocker/Warning can never be silently "accepted as-is" — the originating failure this framework prevents.) Warnings, and Blockers the gate did not force, fall through to the shared Step 1 / Step 2 logic in the framework doc.

This gate is the Stage-7-specific Step 0 that the shared framework's § 6 contract requires each consuming stage to inject. Stage 8 QA injects a strictly stronger gate (NOT-MET acceptance criterion → no defer/accept without a recorded operator override) over the same shared core.

#### Disposition → routing consequence

The disposition the human renders maps onto the existing severity (Blocker/Warning/Note) + routing-tier structure as follows — it layers on the Finding Classification table; it does not replace it:

| Disposition | Routing consequence | Tier |
|---|---|---|
| Fix-now (in scope) | Engineering `fix(dt):` commit on the release branch (the existing DT↔Engineering loop) | Tier 1 |
| Fix-now (needs scope change) | Operator decides per inter-stage feedback protocol | Tier 2 |
| Defer | Open a **next-release issue** (new disposition — the finding leaves this release with a tracked home) | — |
| Accept | Note / logged + one-line rationale; no routing | — |

#### Worked example (representative DT finding)

*Representative-maps the originating "v7.2 F-02" case (a trivial best-practice finding wrongly recommended "accept-as-is") to a current-tree equivalent.*

**Finding F-EX (representative):** During Pass 1 DT of a release, the deprecated-path scan (Phase A) flags one new file containing a single documentary reference to a removed path; the fix is to swap it for the current path. Severity: **Warning**. PR/branch: **open**.

| Factor | Signal | Reading |
|---|---|---|
| Effort | Fix-Now | one-line edit, single file, no design decision |
| Best-Practice Alignment | Fix-Now | moves toward the documented current-path convention (cite-able) |
| Downstream Impact | Defer | no downstream stage depends on it |
| Reversibility / Risk | Fix-Now | additive one-line swap, CHEAP, no regression risk |
| Scope-Window | Fix-Now | branch still open |

**Disposition:** Step 0 — Warning, gate does not force. Step 1 — `Effort=Fix-Now AND (Best-Practice=Fix-Now) AND Reversibility≠Accept AND Scope-Window=open` → **Fix-Now**. Routed Tier 1 (`fix(dt):` commit). **This is the correct call** — the prior ad-hoc "accept-as-is" is foreclosed: a trivial, documented-best-practice, low-risk fix on an open branch is fix-now, exactly per operator feedback. Had the branch been **merged** (Scope-Window=Defer), Step 1's Defer clause fires → open a next-release issue (not silent accept).

#### Stage 7 ↔ Stage 8 differentiation (for the QA adaptation)

Stage 8 QA ([`stage-08-qa-testing.md`](stage-08-qa-testing.md)) reuses the shared matrix (factors + Steps 1–2) **unchanged** and **strengthens only Step 0**: a **NOT-MET acceptance criterion** cannot be deferred or accepted without an **explicit operator override** — strictly stronger than the Stage 7 Blocker gate (Stage 7 permits in-scope Blocker auto-fix-now; Stage 8 forbids any non-fix disposition of a NOT-MET AC absent operator sign-off). The QA per-criterion verdict (MET / NOT MET / PARTIAL) keys the strengthened gate. The shared core (matrix + Steps 1–2 + scoring) lives in the framework doc so both stages cite one source.

### Targeted Re-Review (Pass 2+)

After Engineering commits fixes, DT runs a targeted re-review — not a full re-run:

| Scope | What re-runs | What does NOT re-run |
|---|---|---|
| Fixed findings | Re-verify specific assertions that failed in prior pass | Assertions that passed and were not in the blast radius of fixes |
| Regression | Re-run structural checks (Phase A) that could be affected by new commits | Phase C scoring on unchanged content |
| New scope | If Engineering fix touched files not in the original finding, extend review to those files | Full Phase A–D on the entire PR |

**Pass 2+ report format:** Appended section in the Quality Review Report — "Iteration N" with: findings addressed, re-verification results, new findings (if any), updated verdict.

### Escalation Threshold

If the DT↔Engineering loop exceeds **3 iterations** (Pass 1 + 2 re-reviews) without reaching PASS or CONDITIONAL PASS:

1. DT stops the loop and escalates to the operator with `[ESCALATION: ITERATION LIMIT]` signal.
2. Escalation package includes: iteration history (findings per pass, fixes per pass, persistence pattern), hypothesis on root cause (upstream spec issue, systemic quality gap, or DT calibration drift).
3. Operator triages: (a) return to Planning/Solutioning for the affected issue(s), (b) override DT findings with documented rationale, (c) adjust DT thresholds if calibration drift is confirmed.

**Rationale:** 3 iterations is the threshold — not a hard cap. The operator may authorize additional iterations if the convergence trend is positive (finding count decreasing). The threshold exists to surface issues that indicate upstream problems rather than Engineering-fixable defects.

### Engineering Commit Convention for DT Fixes

| Element | Convention |
|---|---|
| Prefix | `fix(dt):` |
| Description | Specific fix, not generic ("correct evidence label on Stage 4 AC" not "fix DT findings") |
| Issue reference | `(#N)` for the parent issue the finding relates to |
| Signal tag | [ADJUST] per the inter-stage feedback protocol Tier 1 |
| Example | `fix(dt): correct evidence label on Stage 4 AC [ADJUST]` |

Engineering MAY batch multiple Tier 1 fixes into a single commit when they address the same finding category. Each batch commit lists all findings addressed.

### Iteration Tracking

| Metric | Where Tracked | Purpose |
|---|---|---|
| Iteration count per release | Quality Review Report, Iteration N sections | Calibration: high counts signal upstream quality issues |
| Per-finding lifecycle | Quality Review Report (found → routed → fixed → re-verified) | Traceability: every finding has a resolution |
| Findings by tier per pass | Quality Review Report summary | Pattern detection: persistent Tier 2+ findings signal design gaps |
| Cumulative iteration data | [calibration-data.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) | Cross-release calibration: iteration trends inform threshold adjustment |

### Automation Trajectory

| Aspect | Current State | Target State |
|---|---|---|
| DT pass execution | Auto-executed within the Stage-7 spoke — Mode G runs the registered eval sets per § Automated Eval Invocation Protocol; operator engagement only on FAIL/EXCEPTION | Extend registration as additional stage-gate eval sets are authored (per the stage-gates index) |
| Finding classification | LLM-graded during report assembly | Rule-based for structural, LLM for content |
| Engineering fix routing | Operator relays findings to Engineering session | Agent-to-agent handoff with structured finding payload |
| Re-review trigger | Operator triggers DT re-review session | Auto-triggered on `fix(dt):` commit detection |
| Escalation | Operator monitors iteration count | Auto-escalation at threshold with structured package |
| Finding disposition | Human applies the disposition matrix at Phase E (Tier 3) | Scoring function auto-recommends disposition; human confirms (Tier 2) — per-factor signals become structured finding metadata |

The disposition scoring-function stub — `disposition(finding) → {fix-now, defer, accept, escalate}` — lives with the shared mechanics in [`release/references/standards/finding-disposition-framework.md`](../standards/finding-disposition-framework.md) § 5 (the stage-agnostic Steps 1–2 skeleton; Stage 7's open-Blocker Step 0 gate is prepended per § 6). The function is **advisory** (recommends; human confirms) until calibration data justifies promotion, consistent with Stage 7's no-auto-correction principle.

## DT↔QA Handoff Protocol

This protocol defines the paired handoff formats at the Stage 7 (Dev Testing) ↔ Stage 8 (QA Testing) boundary:
- **Forward handoff:** Stage 7 → Stage 8 — the structured quality-report payload Stage 8 consumes as Phase A input.
- **Return path:** Stage 8 → Stage 7 — the QA-initiated iteration variant when Phase C Lane 2 findings require DT re-review before Engineering fix.

Both formats are human-readable (markdown) AND machine-parseable (stable headings, fixed-schema tables, ID-keyed findings). This supports current operator review and the future skill-chain automation trajectory.

Relationship to other protocols:
- Instantiates the general [Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol) at the DT↔QA boundary.
- Composes with the [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol) — the return path enters that loop as its QA-initiated variant.
- Preserves the layered review model: QA findings re-enter the quality layer (Stage 7) before reaching the fix layer (Stage 6); QA does not route directly to Engineering.

### Forward Handoff: Stage 7 → Stage 8

Stage 7's terminal report section is the **Handoff Payload** — a structured block at the end of the Quality Review Report under the exact H3 heading `### Output for Stage 8`. Stage 8 Phase A Entry Validation extracts required fields from this section; it is the authoritative interface between the stages.

#### Required fields

| Field | Type | Source | Purpose (for Stage 8) |
|---|---|---|---|
| Verdict | Enum: `PASS` / `CONDITIONAL PASS` / `FAIL` | Phase D | Phase A entry gate (only `PASS` / `CONDITIONAL PASS` advance) |
| Iteration count | Integer ≥ 0 | Iteration history | Calibration + escape analysis |
| PR reference | SHA or `#N` or branch @ SHA | Branch state | Confirms PR still mergeable |
| Files reviewed | List of repo-relative paths (with line ranges when scoped) | Phase A1 | Scope anchor for acceptance review |
| AC map | Table: `AC · Issue # · Verdict (PASS / PARTIAL / NOT VERIFIED) · Evidence` | Phase B | Primary input for Phase B acceptance review |
| Findings | Table: `F-ID · Severity · Dimension · Routing tier · Origin · Status · Evidence · Recommendation` | Phase D | Context for Phase B and escape detection |
| Escape summary | Table: `Origin stage · Count` | Phase D | Stage 7 escape count + calibration |
| Downstream attention | List of F-IDs flagged for Stage 8 scrutiny (may be `None`) | Phase E | Focuses Stage 8 review |
| Cross-issue notes | Markdown bullets (may be `None`) | Phase E | Release-level context |
| Test-results | Table: `Suite · Selected-by (map row #) · Result (PASS / FAIL / SKIP) · Pass/Fail counts · Env · Evidence (Actions URL or local) · pipeline-event ts` (single line `NONE — no runtime code path changed` when the map's no-match row fired) | Phase A8 | Confirms the runtime-code gate ran; carries the machine-readable outcome QA / downstream reads without opening Actions logs |

#### Format conventions

| Convention | Rule | Rationale |
|---|---|---|
| Heading anchor | Section heading is exactly `### Output for Stage 8` | Stable parse anchor |
| Verdict line | First non-heading line: `**Verdict:** <enum> — <one-line rationale>` | Deterministic top-line extraction |
| Table schemas | Column order and header text exactly as specified above | Consistent extraction across releases |
| Finding IDs | `F-NN` (zero-padded preferred, `F-N` acceptable) | Stable cross-iteration reference |
| Evidence citations | Inline code for paths/commands, markdown link for URLs | Separates reference from narrative |
| Enum values | Exact casing from schema — no synonyms | Deterministic enum parse |
| Severity vocabulary | `Blocker` / `Major` / `Minor` / `Cosmetic` / `Informational` | Matches persona and the routing protocol |
| Routing tier values | `Tier 1` / `Tier 2` / `Tier 3` / `—` (Notes) | Per the inter-stage feedback protocol and the iteration-loop classification |
| Origin stage | `S4` / `S5` / `S6` / `S7 (pass N)` / `S8 (return)` | Enables escape provenance |
| Test-results table | Columns exactly `Suite · Selected-by · Result · Pass/Fail · Env · Evidence · Event ts`; `Result` ∈ `PASS` / `FAIL` / `SKIP`; one row per selected suite, or a single `NONE — …` line | Deterministic extraction of the runtime-gate outcome |

**Severity vocabulary reconciliation (Phase D ↔ Findings table):** Phase D's `Blocker / Warning / Note` are verdict-severity buckets (3-bucket) used to render the overall pass/fail verdict. The Findings-table `Severity` column reports finding-level severity using the 5-bucket vocabulary (`Blocker / Major / Minor / Cosmetic / Informational`). DT skills emitting findings into the Handoff Payload MUST translate at report-assembly time as follows:

| Phase D verdict bucket | Findings-table severity | Rule |
|---|---|---|
| Blocker | Blocker | 1:1 — verdict-blocking findings remain Blockers in the Findings table |
| Warning | Major OR Minor | Judgment call at report assembly — Major when the warning names a specific quality defect with remediation, Minor when it is a convention or clarity observation |
| Note | Cosmetic OR Informational | Cosmetic for presentation/style observations, Informational for context-only notes that carry no remediation expectation |

Phase D's verdict line continues to use the 3-bucket vocabulary; only the Findings table uses the 5-bucket vocabulary. A report with `Blocker/Warning/Note` in its Findings `Severity` column fails parse validation — DT must translate before emitting.

#### Example (abbreviated)

```markdown
### Output for Stage 8

**Verdict:** PASS — no blockers, all AC met, all quality scores at or above threshold.

**Iteration count:** 0 (Pass 1 only)
**PR reference:** release/vX.Y-<capability-slug> @ <SHA>
**Files reviewed:**
- release/governance/release-process.md (lines 27-51)
- release/governance/release-process.md (mirror)

**AC map:**
| AC | Verdict | Evidence |
|---|---|---|
| AC1 | PASS | §Inter-Stage Feedback Protocol, lines 27-51 |
| AC2 | PASS | Tier 1/2/3 definitions, lines 43-59 |
| AC3 | PASS | Signal tags `[ADJUST]` / `[SCOPE CHANGE]` / `[PLAN REJECTION]` |
| AC4 | PASS | Boundary generalization paragraph |

**Findings:**
| F-ID | Severity | Dimension | Tier | Origin | Status | Evidence | Recommendation |
|---|---|---|---|---|---|---|---|
| F-01 | Cosmetic | Convention depth | — | S6 | Open | Tier 3 parenthetical names Planning/Solutioning | Accept as-is; generalization paragraph mitigates |
| F-02 | Informational | Escape detection | — | S6 | Open | New signal tags — first platform use | Accept; first real-world usage will validate |

**Escape summary:**
| Origin | Count |
|---|---|
| S4 | 0 |
| S5 | 0 |
| S6 | 0 |

**Downstream attention:** None — all findings are Cosmetic / Informational.

**Cross-issue notes:** the DT-Eng iteration loop will specialize this protocol at DT↔Engineering; no blocking dependency.

**Test-results:** NONE — no runtime code path changed (doc/governance change; selection-map no-match row → `test-run/suite-skip`).
```

When the PR touches a runtime code path, the Test-results block renders one row per selected suite instead of the `NONE` line:

```markdown
**Test-results:**
| Suite | Selected-by | Result | Pass/Fail | Env | Evidence | Event ts |
|---|---|---|---|---|---|---|
| hook-suite | map row 3 | PASS | 268/0 | sandbox-home-tmp | actions-run:<url> | 2026-06-13T14:00:00Z |
| deploy-suite | map row 2 | PASS | 24/0 | sandbox-home-tmp | actions-run:<url> | 2026-06-13T14:00:01Z |
```

#### Parse contract

Stage 8 Phase A treats `### Output for Stage 8` as the authoritative input. Any claim not present in this section must be reconstructed from the full report narrative — the handoff payload is the single source of truth for the stage boundary. When Phase A cannot extract a required field, the entry gate fails and Stage 8 posts a [ADJUST] signal per the inter-stage feedback protocol Tier 1 requesting an amended handoff; DT amends in-place (no full re-review required for format-only corrections).

#### Validation against empirical output

This format codifies the established convention — closed Stage 7 reports consistently produce Summary / Detail / Evidence / Decisions & Recommendations / Output for Stage 8 sections, with `Verdict:` as the lead of the Output block and findings with F-IDs, severity, and recommendations. This protocol formalizes that shape and adds the missing `Routing tier` and `Origin` columns to the findings table, plus the explicit `AC map` and `Escape summary` tables. Retrofit of prior reports is not required; the contract binds from this protocol forward.

### Return Path: Stage 8 → Stage 7

When Stage 8 Phase C produces a Lane 2 (AC Gap) finding, the release cannot advance until the gap closes. Per the layered review model, QA findings re-enter the quality layer (DT) before reaching the fix layer (Engineering) — QA does not route directly to Engineering. This preserves the independent-reviewer invariant at every transition.

#### QA → DT Return Handoff

Stage 8 posts a structured `### QA Return to Dev Testing` section on the relevant sub-task with these required fields:

| Field | Type | Purpose |
|---|---|---|
| Trigger lane | Enum: `Lane 2` (Lane 1 logs only; Lane 3 escalates to Stage 9) | Confirms routing reason |
| QA finding ID | `QF-NN` | Stable reference across iterations |
| Failed AC | Table: `AC · Issue # · Verdict (NOT MET / PARTIAL) · Evidence of gap` | DT's re-review anchor |
| DT-side hypothesis | One line (optional) | Why QA thinks DT missed — aids calibration |
| Requested scope | Always `Full re-review (per the loop protocol)` | Binds DT scope explicitly |
| Return timestamp | ISO-8601 | Iteration history |
| QA iteration count at return | Integer | Informs composed-loop escalation |

#### DT scope on QA returns

When DT receives a QA return, DT executes a **full re-review** (all Phase A–D assertions against the full PR diff), not the targeted re-review of the native DT-Eng iteration loop. Rationale:

- QA findings are by definition DT escapes — DT's prior pass missed an AC gap that QA detected.
- Targeted re-review assumes fix isolation. On a QA return the trigger is NOT a fix — it is a miss. Targeted scope on a miss would compound the miss.
- Full scope catches correlated misses — if DT miscalibrated one dimension, related dimensions in the same review may also be affected.

This boundary-specific rule does not change the DT-Eng loop's targeted default for the native DT↔Engineering loop (whose input is a fix, not a miss). When the full-scope rule ships, the targeted/full distinction retires and all DT re-reviews become full scope — this protocol aligns with that target state already.

#### DT processing after return

DT runs Pass N+1 (where N = DT's iteration count prior to the QA return). Three outcomes:

| Outcome | Action | Signal |
|---|---|---|
| DT confirms the QA finding as a DT escape | Add QF-NN to findings with `Origin: S8 (return)`, classify via routing-tier rule, route per the iteration-loop protocol (Engineering fix via `fix(dt):` commit) | Enter the DT-Eng loop |
| DT disputes the QA finding (disagrees AC is unmet) | Post `[SCOPE CHANGE]` signal per the inter-stage feedback protocol Tier 2 — operator adjudicates. DT does NOT unilaterally close a QA finding | Escalation to operator |
| DT discovers additional escapes during full re-review | Add to findings with `Origin: S7 (pass N+1 full)`; include in the iteration loop and report in the Verified signal | Continue in the DT-Eng loop |

#### DT → QA Verified Signal

When DT's post-return iteration reaches `PASS` or `CONDITIONAL PASS`, DT posts a `### Return to QA — Verified` section on the sub-task with:

| Field | Type | Purpose |
|---|---|---|
| QA finding ID(s) closed | List of `QF-NN` | Traceability to Stage 8 Phase C findings |
| Resolution commits | SHA list per the fix(dt): convention | Audit trail |
| DT re-review verdict | Enum: `PASS` / `CONDITIONAL PASS` | QA Phase A re-entry gate |
| Scope executed | `Full re-review` | Confirms full re-review alignment |
| Additional findings surfaced | Count (may be 0) with F-ID list | QA attention flag for Pass M+1 |
| DT iterations contributed | Integer | Composed-loop calibration input |

The Verified Signal augments the original Forward Handoff (it does not replace it). Its `verdict` (enum: `PASS` / `CONDITIONAL PASS`), `DT iterations contributed` (integer), and `Origin` labels applied to newly surfaced findings follow the forward-handoff enum vocabulary so that QA Phase A can extract them with the same parser. QA Pass M+1 entry validation re-checks the original Handoff Payload (the 10 required handoff fields remain authoritative) plus the Verified Signal closures — it does NOT validate the Verified Signal as a standalone handoff payload. The Verified Signal's 6 fields above are the complete contract for the signal itself; the re-entry gate passes when (a) the original Handoff Payload still parses, (b) each listed QA finding ID is marked closed with a resolution commit, and (c) the DT re-review verdict is `PASS` or `CONDITIONAL PASS`.

#### Integration with DT-Eng iteration loop
<!-- design-artifact: flow-class=agent-process; name=qa-return-to-dt; depicts=release/references/pipeline/stage-07-dev-testing.md,release/references/pipeline/stage-08-qa-testing.md -->

The return path composes with the DT-Eng iteration loop as its QA-initiated variant:

```
Stage 8 Phase C Lane 2 → QA Return to DT (this protocol)
  ↓
DT Pass N+1: Full re-review (per the full re-review rule)
  ↓
┌─ Confirms finding → enter the DT-Eng iteration loop
│   Engineering fix (fix(dt): commit) → DT targeted re-review (per the full re-review rule)
│   DT PASS → Return to QA — Verified (this protocol)
│   ↓
│   QA Phase D Pass M+1 (full re-review per Stage 8 §5 Phase D)
│
├─ Disputes finding → [SCOPE CHANGE] to operator (per the inter-stage feedback protocol Tier 2)
│
└─ Finds new escape during full re-review → enter the DT-Eng iteration loop for the new finding
    Include in Verified signal when closing
```

#### Iteration caps

| Loop | Cap | Rationale |
|---|---|---|
| DT↔Engineering iteration loop | 3 iterations | Finding-count convergence surfaces Engineering-fixable defects vs. upstream issues |
| QA Phase D (Stage 8 §5) | 2 QA Pass cycles | Per existing Stage 8 definition: more than 2 QA passes signals systemic issue |
| Composed (QA→DT→Eng→DT→QA) | No separate cap — each loop caps independently | Whichever inner cap fires first triggers its own escalation |

When any cap fires, the enclosing loop escalates per the inter-stage feedback protocol (Tier 2 for calibration drift; Tier 3 if the miss indicates a planning defect).

#### Automation trajectory

| Aspect | Current State | Target State |
|---|---|---|
| QA return trigger | Operator relays Lane 2 finding to DT session | Auto-trigger on Lane 2 finding in QA report |
| Return payload | Markdown section drafted by QA skill | Structured payload emitted by QA skill chain |
| DT scope enforcement | Mode G's QA-return input contract enforces full re-review scope (= target, v3.68) | Eval runner enforces full scope on QA-originated triggers |
| Verified signal | Markdown comment | Structured payload consumed by QA skill chain |
| Calibration detection | Operator notices recurring QA escapes | Auto-detect DT calibration drift from escape trend in calibration-data.md |

## Automated Eval Invocation Protocol

This protocol registers **automated eval invocation** at pipeline stage gates:
which stage events auto-execute which eval surfaces, through which executor mode,
and how an eval result projects into the stage's existing gate machinery. Ownership
split: the executor modes own eval EXECUTION (ladder mechanics, grading, report
assembly — their own mode specs); this protocol owns automated INVOCATION — trigger
registration, the result→gate contract, escalation wiring, the autonomy
declaration. Eval AUTHORING remains eval-writer's (it authors; it does not run). It
instantiates the general
[Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol)
for eval-result escalation, and extends the stage-gate evaluation surface the way
[`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) itself
anticipates — outcomes reach the evaluator through this shard's §7 Metrics line
(Path B): no modification to that spec, no parallel gate, no new verdict values.
Stage 8 registers its EI-S8 rows in its own shard (§5 Phase B), consuming the
record schema, projection rule, escalation mapping, and autonomy declaration
defined once, here. Per-stage EI rows live in the owning stage's shard; the shared
machinery lives here.

### Trigger registration (Stage-7 EI rows)

| ID | Stage event | Trigger criterion (fires when ALL hold) | Eval surface executed | Executor |
|---|---|---|---|---|
| EI-S7-01 | Stage-7 spoke entry (Pass 1) | The release enters Stage 7 (DT spoke dispatched) AND ≥1 eval set exists under `core/skills/eval-writer/evals/stage-gates/stage-07-dev-testing/` | The Stage-7 stage-gate eval set(s), executed as written (assertion sourcing + binary judges per the executor mode's reference spec) | pmo-qa-auditor Mode G — Dev Testing |
| EI-S7-02 | Stage-7 re-entry (Pass ≥ 2) | A post-`fix(dt):` targeted re-review OR a QA-return full re-review begins | Affected assertions (targeted) / full set (QA return) — scope per § Targeted Re-Review and § DT scope on QA returns | pmo-qa-auditor Mode G — Dev Testing |

No registered set / no applicable surface → record **Result `SKIP`** (one-line
no-op, no ceremony) — mirroring the A8 no-match row. New stage-gate eval sets (per
the stage-gates index) append EI rows at their owning stage's shard; registration is
append-pattern.

### Eval-invocation record (the result schema)

One record per suite/contract execution, emitted in the executing mode's stage
report (Stage 7: the Quality Review Report on the PR; Stage 8: the Acceptance
Report). Column vocabulary derives from the A8 **Test-results** table — the
existing machine-readable run-outcome surface at this boundary:

| Suite | Registered-by | Result | Assertions (pass/fail) | Executor | Evidence | Timestamp |
|---|---|---|---|---|---|---|
| `<suite_name from the set header>` | `EI-S<stage>-<NN>` | `PASS` / `FAIL` / `SKIP` / `EXCEPTION` | per assertion type, e.g. `structural 3/0 · judgment 1/0` | mode identifier + session class | command / run pointer (reproducible) | ISO-8601 |

- **Result semantics:** `PASS` = every assertion passed · `FAIL` = ≥1 failed ·
  `SKIP` = no registered/applicable surface (no-op) · `EXCEPTION` = the run could
  not execute (tool error, missing fixture, unresolvable input) — carries a
  `reason:` note, the registration analogue of A8's `reason:runner-error`.
- Per-assertion results are binary PASS/FAIL for `structural` / `judgment` types;
  `acceptance`-type results ARE the Stage-8 §5 per-criterion verdicts (consumed
  verbatim — this record adds no verdict values).
- The record lives in the report BODY. The DT→QA Handoff Payload is unchanged (10
  required fields stand; eval-FAIL findings flow into its existing Findings table
  via the projection below). No new pipeline-event type ships with this protocol —
  the A8 `test-run` event remains runtime-suite-scoped; the record + the release
  plan's Verification Evidence carry the audit trail.

### Result → gate projection (the contract)

Eval results project INTO the stage's existing finding/verdict machinery — never
around it:

| Eval outcome | Stage-7 projection | Stage-8 projection |
|---|---|---|
| Assertion PASS | No finding; record only | (`acceptance`) a verdict row under the Stage-8 §5 enum |
| `structural` / `judgment` assertion FAIL | A finding at the severity the graded check declares (e.g., `stage-07-branch-freshness` FAIL = Blocker per S7-I04), entering Phase D verdict computation + the Finding Classification table (Tier 1/2/3) | A format/entry finding per the Phase A [ADJUST] machinery; report self-conformance failures fixed before posting |
| `acceptance` NOT MET | — (Stage 8 owns) | NOT MET (Blocker) → Lane 2 + the Step-0 hard-precedence gate (existing, unchanged) |
| Run EXCEPTION | **Warning** finding, infra class, per the A8-INFRA pattern — logged; operator/CI investigates; never a silent pass | same |

The gate verdict is still rendered by the stage's own machinery (Stage 7 Phase D:
PASS / CONDITIONAL PASS / FAIL; Stage 8 Phase B/E: the §5 enum + ACCEPT /
CONDITIONAL ACCEPT / REJECT / HOLD). This contract adds no verdict values and no
parallel gate path — it is the projection seam between an executed eval surface and
the verdict machinery the stage already runs; the gate evaluator consumes the
outcome through the §7 Metrics line as it consumes every other Phase-A/B check.

#### Worked example (FAIL → Tier 1, end-to-end)

`EI-S7-01` fires at a release's Stage-7 entry; the executor mode runs
`stage-07-dev-testing-gate`; `assert_branch_fresh.py` exits 1 listing two
unreachable base commits.

| Suite | Registered-by | Result | Assertions (pass/fail) | Executor | Evidence | Timestamp |
|---|---|---|---|---|---|---|
| stage-07-dev-testing-gate | EI-S7-01 | FAIL | structural 2/1 · judgment 1/0 | Mode G (DT spoke) | `assert_branch_fresh.py` exit 1 — `<sha1>`, `<sha2>` unreachable | `<ts>` |

Projection: the failed assertion grades S7-I04 → finding `F-NN` **Blocker** →
Phase D verdict **FAIL** (any Blocker) → Finding Classification: fixable within
scope → **Tier 1 [ADJUST]** → Engineering `fix(dt): rebase release branch onto base
[ADJUST]` → `EI-S7-02` fires on the Pass-2 targeted re-review → PASS → record
appended. Operator engagement occurred only at the existing Phase E review. Had the
rebase invalidated a design premise → **Tier 2 [SCOPE CHANGE]**. EXCEPTION variant:
the runner cannot resolve the base ref → Result `EXCEPTION (reason: runner-error)`
→ Warning finding, infra class — operator/CI investigates; the invocation does not
self-certify, and the §7 metric records the run as unresolved.

### FAIL/EXCEPTION escalation (operator-engagement conditions)

Wired to the
[Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol)
Tier classification — operator escalation only on FAIL/EXCEPTION:

| Outcome | Operator engagement | Protocol tier |
|---|---|---|
| PASS / SKIP | None — results recorded; operator sees post-hoc in the stage report | — |
| FAIL, fixable within scope | Via the stage's existing loop — the drafted finding routes to Engineering; operator reviews at Phase E | Tier 1 `[ADJUST]` |
| FAIL, requires scope change | Operator decides | Tier 2 `[SCOPE CHANGE]` |
| FAIL, plan unworkable | Operator returns upstream (RCA per that protocol's Tier-3 clause) | Tier 3 `[PLAN REJECTION]` |
| EXCEPTION | Operator/CI investigates (infra class — not an Engineering code fix); Tier 1 `[ADJUST]` when the cause is a plan/artifact correction (e.g., a stale fixture path) | per the A8-INFRA pattern |
| `acceptance` NOT MET / AC-blocking PARTIAL | Per the Stage-8 Step-0 gate — fix-now default; defer/accept only with the recorded Operator Override Record | Lane 2 (existing) |

Escalation OUTPUTS (finding blocks, tier-signal comments) are engagement-class
outputs — communication form per the operator engagement charter
(`core/specs/engagement-charter.md`); ROUTING per this table.

### Autonomy declaration (prefixed per `core/specs/autonomy-tiers.md` § Tier Disambiguation)

- The invocation ACTION is **Autonomy Tier 2 — Bounded Auto** (registered as an
  example in [`core/specs/autonomy-tiers.md`](../../../core/specs/autonomy-tiers.md)
  § Tier 2). **Declared scope:** execute the EI-registered eval surfaces read-only
  against PR/branch/issue state; write results ONLY to the executing mode's declared
  report surface; draft findings per the projection table.
- **Outside scope (descends to Autonomy Tier 1 — Recommend):** waiving or
  suppressing any FAIL; modifying any eval set or fixture (authoring is
  eval-writer's — execution never edits); committing fixes (Stage 7 classifies and
  routes); rendering Phase-E verdicts; any other write.
- **On FAIL/EXCEPTION the disposition descends to Autonomy Tier 1** — the invocation
  surface stops at drafted-finding + routing recommendation; the stage machinery and
  operator dispose per the escalation table above.
- Stage-level **Automation Tier** labels are unchanged (this shard §8 "Tier 1/2
  mix"; stage-08 §8 "Automation Tier 2 (Recommend)") — distinct, numerically
  inverted conventions; always prefix.

### Relationship to adjacent execution surfaces

- **A8 Runtime-Suite Gate** — runtime test suites; its own dispatch map and
  `test-run` events. Unchanged; this protocol borrows its record vocabulary and
  INFRA pattern.
- **Plan-verification re-execution (`verify-release-plan.sh`)** — the optional
  Phase-A plan-check executor (plan rows + CIAC methods), a distinct check surface.
  NOT registered here; future candidate if its optional status graduates.
- **Skill-eval harness (`run_eval.py`, pmo-skill-refiner)** — skill-level evals
  outside stage gates; out of scope.

### Cutover + pilot

Applies to releases entering Stage 7 / Stage 8 strictly AFTER this protocol's
introducing-release merge SHA recorded in
[`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). **The
introducing release itself is exempt from the gate-binding clauses** (the §7 Metrics
clause and the EI rows bind from the next release) — with one bounded exception:
**the pilot.** The introducing release executes `EI-S7-01` during its own Stage-7 DT
pass as the pilot-conformance run: results recorded in the record schema in the DT
report, the pilot row mirrored into the release plan's Verification Evidence. The
pilot is evidence-producing, not gate-binding — the introducing release's verdicts
render under pre-protocol semantics, and a pilot FAIL routes through the ordinary
pre-existing Stage-7 finding machinery the projection maps into anyway.
