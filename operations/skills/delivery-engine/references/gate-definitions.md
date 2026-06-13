<!-- reference-durability: allow-link -->
<!-- provenance: UNSOURCED-DOMAIN -->

# Gate Definitions — Project Lifecycle Gate Sequence

## Purpose

This document is the canonical **sequence** of project-lifecycle gates — eleven gates, **LG-0 (Idea Screen)** through **LG-10 (Closure)** — that a managed project passes through from idea to closed. Each gate carries entry criteria, exit criteria, key decisions, authority holder, artifacts required, and an escalation path. It is read by the delivery-engine skill: **Mode F (DoD & Release Readiness Gate)** applies the per-gate exit criteria and the §4 transition rule; **Mode G (RAID / Decision / Milestone Update)** attributes gate decisions to the correct lifecycle gate and authority holder; **Mode C (DoR Gate)** references it for context to situate DoR as LG-4.

**Boundary vs. `gate-checklists.md` (the sibling doc).** `gate-checklists.md` owns the gate-**TYPE** taxonomy — what KINDS of gates exist (Phase / Quality / Flow / Approval / Hypothesis), the per-type checklist templates, go-live readiness dimensions, risk-based calibration, methodology variation, and gate anti-patterns. This doc owns the lifecycle-gate **INSTANCE sequence** — which gates THIS project lifecycle has, in order, and the entry/exit/authority/artifacts/escalation for each. They are different axes. This doc **cross-references** `gate-checklists.md` for every checklist template and gate-type classification; it never restates them. See [`gate-checklists.md`](gate-checklists.md).

**Namespace vs. pipeline-stage gates.** These are **project-lifecycle** gates, prefixed `LG-` (Lifecycle Gate). They are NOT the platform-release pipeline's stage gates (e.g., "Gate 9 = Plan Review", "Gate 12 = Execute") defined in [`core/schemas/gate-criteria-spec.md`](../../../../core/schemas/gate-criteria-spec.md), which govern how the platform builds its own releases and carry `G-PR*/G-EX*/G-CL*` IDs. Both conventions legitimately render "Gate N"; the `LG-` prefix prevents cross-reference collision. When this doc says "Gate 9" it means LG-9 (Post-Implementation Review), never the pipeline's Stage-9 Plan Review.

**Content provenance: `UNSOURCED-DOMAIN`.** This doc was authored from the originating issue's Description (the eleven-gate lifecycle requirement and the gate-transition acceptance criterion) plus `domain: governance/PMO` best-practice (Cooper Stage-Gate Idea Screen; PMBOK phase-gate reviews and benefits-realization) and the existing sibling reference docs. The detailed "full content spec" the originating issue cited (an upscale gap analysis) is **absent from the repository**; no citation to it is fabricated. Entry/exit criteria below are derived from the named domain anchors and the sibling-doc reconciliation, not copied from a source spec.

---

## 1. Lifecycle Gate Model (LG-0 — LG-10) — Overview

The project lifecycle passes through eleven gates in order. The table below establishes the whole sequence at a glance and sets the gate-TYPE cross-reference once, table-wide (each type links into [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)).

| Gate | Name | Gate type (→ `gate-checklists.md §1`) | Authority holder | Primary decision |
|---|---|---|---|---|
| **LG-0** | Idea Screen | Hypothesis | Portfolio / Intake authority | Advance to business-case work, or screen out |
| **LG-1** | Portfolio Intake / Business Case | Phase | Steering / Lean Portfolio Mgmt | Fund / hold / reject the business case |
| **LG-2** | Project Initiation / Kickoff | Phase | Steering Committee / Sponsor | Authorize the project; commit initiation resources |
| **LG-3** | Plan Baseline / Readiness | Phase | Steering Committee | Baseline the plan; authorize execution |
| **LG-4** | Sprint DoR (Execution Entry) | Quality | Tech Leads / Product Owner | Admit the work item to execution (Ready / not-Ready) |
| **LG-5** | Dev Complete (DoD) | Quality | Tech Leads / Developers | Accept the increment as Done / return it |
| **LG-6** | QA Gate | Quality | QA Lead | Pass to release readiness / return to development |
| **LG-7** | Release Readiness | Approval | Business Owner / Release Manager | Go / no-go on release candidate |
| **LG-8** | Go-Live / Deployment Approval | Approval | Change Authority / CAB | Approve deployment into production |
| **LG-9** | Post-Implementation Review (PIR) | Hypothesis | Epic Owner / Sponsor | Persevere / pivot / cancel; benefits verdict |
| **LG-10** | Closure | Approval | Sponsor / PMO | Formally close the project; release resources |

**Reading the sequence.** A project advances LG-N → LG-(N+1) only when ALL of LG-N's exit criteria hold (§4). LG-4 through LG-6 are the **work-item-level** gates (per increment / per sprint); LG-0 through LG-3 and LG-7 through LG-10 are **project-altitude** gates. The same work item may cycle LG-4 → LG-5 → LG-6 many times within a single LG-3-to-LG-7 project window.

---

## 2. Per-Gate Definitions

Every gate below uses the fixed 6-field block. Exit criteria are the machine-checkable unit (§4): each `[LG-N-EX-k]` is phrased as an observable, evidence-testable predicate. Entry criteria `[LG-N-EN-k]` gate whether the review may OPEN.

### Gate 0 — Idea Screen (LG-0)

**Gate type:** Hypothesis → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Portfolio / Intake authority (the single Accountable)
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-0-EN-1] An idea is captured as a work item with a one-line problem statement and a named requester (evidence: the intake record exists).
- [LG-0-EN-2] A strategic-fit hypothesis is stated — which objective / OKR the idea serves (evidence: the fit statement is present, even if unvalidated).
**Exit criteria** (ALL must hold to PASS and transition to LG-1):
- [LG-0-EX-1] The idea passes a strategic-fit screen against current portfolio objectives (evidence: a recorded fit decision referencing the objective).
- [LG-0-EX-2] A rough order-of-magnitude size/effort band is assigned (evidence: a T-shirt size or effort tier recorded — not a point estimate).
- [LG-0-EX-3] No disqualifying constraint is present — regulatory bar, duplicate of in-flight work, or out-of-mandate scope (evidence: a screened-constraints note; duplicate check performed against the active backlog).
**Key decisions:** Advance to business-case work (LG-1) / screen out (kill) / park for a future portfolio cycle (hold).
**Artifacts required:** Intake record (one-line problem + requester + strategic-fit hypothesis). Cross-ref the intake's governed home where one exists (the work-tracker intake item).
**Escalation path:** Escalate to the Portfolio lead when strategic fit is contested or two requesters dispute priority; trigger = unresolved fit dispute at screen time.
**Checklist template:** → [`gate-checklists.md §2.5`](gate-checklists.md#25-hypothesis-gate-checklist) (Hypothesis Gate Checklist)

### Gate 1 — Portfolio Intake / Business Case (LG-1)

**Gate type:** Phase → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Steering / Lean Portfolio Management
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-1-EN-1] The idea cleared LG-0 (evidence: LG-0 exit recorded PASS).
- [LG-1-EN-2] A draft business case exists with a problem statement, expected outcome, and an order-of-magnitude cost band (evidence: the business-case document is attached).
**Exit criteria** (ALL must hold to PASS and transition to LG-2):
- [LG-1-EX-1] The business case quantifies expected value against cost with a stated assumption set (evidence: value/cost figures with named assumptions; not "TBD").
- [LG-1-EX-2] Funding is authorized for the initiation phase, with a budget guardrail (evidence: a recorded funding decision and a guardrail figure).
- [LG-1-EX-3] A sponsor is named and has accepted accountability (evidence: the sponsor field is populated by a person, not a role placeholder).
- [LG-1-EX-4] Portfolio capacity is confirmed to absorb the work, or a sequencing decision is recorded (evidence: a capacity check referencing current portfolio load — see `capacity-model.md`, authored in this same release, once available).
**Key decisions:** Fund / hold / reject the business case (go / kill / hold).
**Artifacts required:** Business case (value, cost, assumptions); funding decision record; named sponsor.
**Escalation path:** Escalate to the portfolio governing body when the business case exceeds the authority holder's funding threshold or when capacity cannot absorb the work without displacing a committed initiative; trigger = funding-threshold breach or capacity conflict.
**Checklist template:** → [`gate-checklists.md §2.1`](gate-checklists.md#21-phase-gate-checklist) (Phase Gate Checklist)

### Gate 2 — Project Initiation / Kickoff (LG-2)

**Gate type:** Phase → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Steering Committee / Sponsor
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-2-EN-1] The business case cleared LG-1 and funding is authorized (evidence: LG-1 exit PASS + funding record).
- [LG-2-EN-2] A draft project charter exists naming scope, objectives, and the sponsor (evidence: the charter draft is attached).
**Exit criteria** (ALL must hold to PASS and transition to LG-3):
- [LG-2-EX-1] The project charter is approved — scope, objectives, success measures, and constraints are stated and signed (evidence: an approved charter with a sign-off record).
- [LG-2-EX-2] A core team is identified with named roles for the accountable disciplines (evidence: a roster with names, not role placeholders, for the irreducible roles).
- [LG-2-EX-3] Initial high-level risks are logged in the RAID artifact with owners (evidence: ≥1 RAID entry per identified high risk, each with a named owner — see the delivery-engine RAID artifact).
- [LG-2-EX-4] Governance cadence and decision authority are defined (evidence: a stated reporting cadence and a RACI naming the single Accountable per gate type).
**Key decisions:** Authorize the project and commit initiation resources / hold for charter rework / recycle to LG-1 for business-case revision.
**Artifacts required:** Approved project charter; team roster; initial RAID entries; governance/RACI definition.
**Escalation path:** Escalate to the Sponsor when the charter scope conflicts with the funded business case, or when a required accountable role cannot be staffed; trigger = scope-vs-funding conflict or an unstaffable accountable role.
**Checklist template:** → [`gate-checklists.md §2.1`](gate-checklists.md#21-phase-gate-checklist) (Phase Gate Checklist)

### Gate 3 — Plan Baseline / Readiness (LG-3)

**Gate type:** Phase → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Steering Committee
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-3-EN-1] The project cleared LG-2 and the team is staffed (evidence: LG-2 exit PASS + roster).
- [LG-3-EN-2] A draft delivery plan exists with a scope breakdown and a sequencing view (evidence: the plan draft / backlog is attached).
**Exit criteria** (ALL must hold to PASS and transition to LG-4):
- [LG-3-EX-1] The plan is baselined — scope, schedule milestones, and budget are committed and version-stamped (evidence: a baselined plan with a baseline date).
- [LG-3-EX-2] The backlog is sufficiently refined for the first execution increment to start, with a Definition of Ready agreed (evidence: a DoR exists and the first increment's candidate items reference it — see [`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist)).
- [LG-3-EX-3] Cross-team and external dependencies are identified with owners and need-by dates (evidence: a dependency register with owner + date per edge — see [`dependency-rules.md`](dependency-rules.md)).
- [LG-3-EX-4] Capacity is confirmed against the planned scope for the first planning horizon (evidence: a capacity assessment referencing team availability — see `capacity-model.md`, authored in this same release, once available).
**Key decisions:** Baseline the plan and authorize execution / hold pending dependency or capacity resolution / recycle to LG-2 for charter/scope rework.
**Artifacts required:** Baselined delivery plan; refined backlog with agreed DoR; dependency register; capacity assessment.
**Escalation path:** Escalate to the Steering Committee when a critical dependency has no committed owner/date, or when confirmed capacity cannot meet the baselined scope; trigger = uncommitted critical dependency or a capacity-vs-scope shortfall at baseline.
**Checklist template:** → [`gate-checklists.md §2.1`](gate-checklists.md#21-phase-gate-checklist) (Phase Gate Checklist)

### Gate 4 — Sprint DoR (Execution Entry) (LG-4)

**Gate type:** Quality → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Tech Leads / Product Owner
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-4-EN-1] The plan is baselined (LG-3 exit PASS) for the project window the increment falls in (evidence: LG-3 exit recorded).
- [LG-4-EN-2] A candidate work item is proposed for execution entry (evidence: the item exists in the backlog with a summary).
**Exit criteria** (ALL must hold to PASS and transition to LG-5 — these ARE the Definition of Ready; run the template, do not restate it):
- [LG-4-EX-1] Acceptance criteria are defined as specific, testable conditions (evidence: AC written in Given/When/Then or equivalent — per [`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist) DoR #1).
- [LG-4-EX-2] Dependencies are identified and none are in a blocked state (evidence: the item's dependency links are mapped and clear — DoR #2).
- [LG-4-EX-3] The item is sized/estimated (evidence: an estimate is assigned — DoR #3; estimation discipline per `estimation-standards.md`, authored in this same release, once available).
- [LG-4-EX-4] The technical approach is reviewed where applicable, with no open architecture question (evidence: design note or a recorded "no design needed" — DoR #4).
- [LG-4-EX-5] A test approach is identified with test data available or a plan to create it (evidence: a stated test strategy — DoR #5).
- [LG-4-EX-6] The item is small enough to fit one iteration (evidence: it meets the INVEST "Small" criterion; otherwise it is sliced — DoR #6).
**Key decisions:** Admit to execution (Ready) / return for refinement (not Ready) / slice into smaller items.
**Artifacts required:** The DoR checklist run against the item ([`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist)); the refined work item (AC, estimate, dependencies).
**Escalation path:** Escalate to the Product Owner when an item is repeatedly returned as not-Ready (≥2 refinement cycles) or when a blocking dependency cannot be cleared by the team; trigger = repeat not-Ready or an unclearable blocker.
**Checklist template:** → [`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist) (Definition of Ready)

### Gate 5 — Dev Complete (DoD) (LG-5)

**Gate type:** Quality → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Tech Leads / Developers
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-5-EN-1] The item passed LG-4 DoR and was admitted to execution (evidence: LG-4 exit PASS).
- [LG-5-EN-2] Implementation is claimed complete and committed (evidence: the change is committed; a "done" claim is raised).
**Exit criteria** (ALL must hold to PASS and transition to LG-6 — these ARE the Definition of Done; run the template, do not restate it):
- [LG-5-EX-1] All acceptance criteria are met and verified with evidence (evidence: each AC checked against an artifact — per [`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist) DoD #1).
- [LG-5-EX-2] Code is peer-reviewed with no unresolved comments (evidence: a completed review record — DoD #2).
- [LG-5-EX-3] Tests pass per the test pyramid with coverage on new code (evidence: a green test run / coverage report — DoD #3).
- [LG-5-EX-4] The automated regression suite is green (evidence: a passing regression run link — DoD #4).
- [LG-5-EX-5] Documentation is updated as applicable (evidence: the relevant docs/runbooks reflect the change — DoD #5).
- [LG-5-EX-6] The artifact builds cleanly and the deployment pipeline is green (evidence: a successful build — DoD #6).
- [LG-5-EX-7] The Product Owner has inspected and accepted the increment (evidence: a recorded PO acceptance — DoD #7).
**Key decisions:** Accept the increment as Done / return it to development with the specific failing criterion cited.
**Artifacts required:** The DoD checklist run against the increment ([`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist)); review record; test/coverage evidence; PO acceptance.
**Escalation path:** Escalate to the Tech Lead when a "done" claim repeatedly fails DoD, or when acceptance is blocked by an unowned defect; trigger = repeat DoD failure or an unowned blocking defect. (Do NOT round a near-miss up to PASS — gate criteria are binary per criterion; see the delivery-engine gate-washing guardrail.)
**Checklist template:** → [`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist) (Definition of Done)

### Gate 6 — QA Gate (LG-6)

**Gate type:** Quality → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** QA Lead
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-6-EN-1] The increment passed LG-5 DoD (evidence: LG-5 exit PASS).
- [LG-6-EN-2] A test environment with representative data is available (evidence: the environment is reachable and seeded).
**Exit criteria** (ALL must hold to PASS and transition to LG-7):
- [LG-6-EX-1] Planned QA test cases are executed with a recorded pass rate meeting the agreed threshold (evidence: a test-execution report with pass rate vs. threshold).
- [LG-6-EX-2] Zero open critical or high-severity defects against the increment (evidence: the defect tracker shows no open critical/high — or an explicitly approved, documented exception).
- [LG-6-EX-3] Regression and integration testing across affected interfaces is green end-to-end (evidence: an integration/regression run covering the touched interfaces).
- [LG-6-EX-4] Non-functional checks required for this increment are met — performance / security as scoped (evidence: the scoped NFR results; security scan clean of unresolved critical/high — cross-ref [`gate-checklists.md §3`](gate-checklists.md#3-go-live-readiness-assessment) Compliance dimension).
**Key decisions:** Pass to release readiness / return to development with the failing test or defect cited / accept a documented exception (only where the gate type's checklist permits a CONDITIONAL outcome).
**Artifacts required:** Test-execution report; defect inventory with severities; integration/regression evidence; NFR results as scoped.
**Escalation path:** Escalate to the QA Lead and the increment's Tech Lead when a critical defect cannot be resolved within the release window, or when test coverage is insufficient to render a verdict; trigger = unresolvable critical defect or a coverage gap that blocks a PASS/FAIL call.
**Checklist template:** → [`gate-checklists.md §2.2`](gate-checklists.md#22-quality-gate-checklist) (Quality Gate / DoD) + [`gate-checklists.md §3`](gate-checklists.md#3-go-live-readiness-assessment) (Test Quality dimension)

### Gate 7 — Release Readiness (LG-7)

**Gate type:** Approval → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Business Owner / Release Manager
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-7-EN-1] All in-scope increments passed LG-6 QA (evidence: LG-6 exit PASS for each increment in the release).
- [LG-7-EN-2] A release candidate is assembled and identified (evidence: a named, versioned release candidate exists).
**Exit criteria** (ALL must hold to PASS and transition to LG-8 — run the nine-dimension readiness assessment, do not restate it):
- [LG-7-EX-1] The nine-dimension go-live readiness assessment shows zero Red dimensions and at most two Amber (with documented mitigations) (evidence: the completed RAG assessment — per [`gate-checklists.md §3`](gate-checklists.md#3-go-live-readiness-assessment)).
- [LG-7-EX-2] A deployment plan / runbook is documented and reviewed by operations (evidence: a reviewed runbook — Approval checklist #2, [`gate-checklists.md §2.4`](gate-checklists.md#24-approval-gate-checklist)).
- [LG-7-EX-3] A rollback plan is documented and validated against a tested restore point (evidence: a rollback procedure verified in staging or equivalent — Approval #3; one of the never-compress gates, [`gate-checklists.md §3.2`](gate-checklists.md#32-gates-that-never-compress)).
- [LG-7-EX-4] Quantitative rollback triggers are defined with thresholds (evidence: error-rate / response-time / availability thresholds recorded — per [`gate-checklists.md §3.3`](gate-checklists.md#33-quantitative-rollback-triggers)).
- [LG-7-EX-5] Stakeholder communications and required enablement/training are prepared (evidence: a drafted comms plan and training-completion status — Approval #4/#5).
- [LG-7-EX-6] Security review is passed with no unresolved critical/high vulnerability (evidence: a clean security scan — Approval #6; a never-compress gate, [`gate-checklists.md §3.2`](gate-checklists.md#32-gates-that-never-compress)).
**Key decisions:** Go / no-go on the release candidate / conditional-go with named mitigations / hold for readiness remediation.
**Artifacts required:** Nine-dimension readiness assessment; deployment runbook; validated rollback plan + triggers; comms/training status; security review result.
**Escalation path:** Escalate to the Business Owner when any readiness dimension is Red, when a never-compress gate cannot be satisfied, or when the change window conflicts with another release; trigger = a Red dimension, an unmet never-compress gate, or a window conflict.
**Checklist template:** → [`gate-checklists.md §2.4`](gate-checklists.md#24-approval-gate-checklist) (Approval Gate) + [`gate-checklists.md §3`](gate-checklists.md#3-go-live-readiness-assessment) (nine-dimension readiness)

### Gate 8 — Go-Live / Deployment Approval (LG-8)

**Gate type:** Approval → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Change Authority / CAB
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-8-EN-1] The release candidate passed LG-7 Release Readiness (evidence: LG-7 exit PASS).
- [LG-8-EN-2] A change request is raised with the deployment window and back-out plan attached (evidence: the change record exists with window + back-out).
**Exit criteria** (ALL must hold to PASS and transition to LG-9):
- [LG-8-EX-1] All upstream quality gates are evidenced as passed with none bypassed (evidence: LG-5/LG-6/LG-7 records present and complete — Approval checklist #1, [`gate-checklists.md §2.4`](gate-checklists.md#24-approval-gate-checklist)).
- [LG-8-EX-2] A backup is taken before deployment, enabling rollback (evidence: a verified pre-deployment backup — a never-compress gate, [`gate-checklists.md §3.2`](gate-checklists.md#32-gates-that-never-compress)).
- [LG-8-EX-3] The change window is confirmed and conflict-free (evidence: an approved, scheduled window — Approval #7).
- [LG-8-EX-4] All required approvers have signed off (evidence: a formal sign-off record with every required approver — Approval #8).
- [LG-8-EX-5] Post-deployment monitoring and alerting are configured before cut-over (evidence: monitoring active with alerts — a never-compress gate, [`gate-checklists.md §3.2`](gate-checklists.md#32-gates-that-never-compress)).
**Key decisions:** Approve deployment into production / reject / approve with conditions (e.g., reduced blast-radius rollout).
**Artifacts required:** Change record with window + back-out plan; pre-deployment backup confirmation; approver sign-off record; monitoring/alerting configuration.
**Escalation path:** Escalate to the Change Authority chair (and invoke the rollback decision per the quantitative triggers) when a required approver withholds sign-off, when the backup cannot be verified, or when monitoring is not in place at the window; trigger = missing sign-off, unverified backup, or absent monitoring at cut-over.
**Checklist template:** → [`gate-checklists.md §2.4`](gate-checklists.md#24-approval-gate-checklist) (Approval Gate) + [`gate-checklists.md §3.2`](gate-checklists.md#32-gates-that-never-compress) (gates that never compress)

### Gate 9 — Post-Implementation Review (PIR) (LG-9)

**Gate type:** Hypothesis → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Epic Owner / Sponsor
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-9-EN-1] The change is live in production (LG-8 exit PASS) and hypercare/the stabilization window is complete (evidence: deployment confirmed + the agreed stabilization period elapsed).
- [LG-9-EN-2] Leading-indicator and outcome data have been collected per the measurement plan (evidence: a measurement report exists for the agreed metrics).
**Exit criteria** (ALL must hold to PASS and transition to LG-10 — Closure):
- [LG-9-EX-1] Realized outcomes are assessed against the LG-1 business-case success criteria (evidence: an actuals-vs-targets analysis referencing the original success measures).
- [LG-9-EX-2] A persevere / pivot / cancel (benefits) verdict is recorded with rationale (evidence: a documented decision tied to the outcome data).
- [LG-9-EX-3] Lessons learned are captured and actionable follow-ups are assigned with owners (evidence: a retrospective output with assigned actions).
- [LG-9-EX-4] Operational ownership of the deployed change is confirmed for the post-project run state (evidence: a named operational owner / run-team handoff — Operational Readiness, cross-ref [`gate-checklists.md §3`](gate-checklists.md#3-go-live-readiness-assessment)).
- [LG-9-EX-5] Any residual risks or open follow-ups are recorded in the RAID artifact with owners and a disposition (evidence: RAID entries for each residual, each owned and dispositioned).
**Key decisions:** Persevere / pivot / cancel on the investment thesis; benefits-realization verdict; authorize transition to formal Closure (LG-10).
**Artifacts required:** Outcome-vs-target analysis; benefits verdict record; lessons-learned / retrospective output; operational-ownership handoff; residual-risk RAID entries.
**Escalation path:** Escalate to the Sponsor when realized outcomes materially miss the business-case targets (pivot/cancel territory), or when no operational owner will accept the run-state handoff; trigger = a material benefits shortfall or an unowned run state. (Closure does NOT proceed on an unowned run state — LG-9-EX-4 must hold.)
**Checklist template:** → [`gate-checklists.md §2.5`](gate-checklists.md#25-hypothesis-gate-checklist) (Hypothesis Gate Checklist)

### Gate 10 — Closure (LG-10)

**Gate type:** Approval → see [`gate-checklists.md §1`](gate-checklists.md#1-five-gate-types)
**Authority holder:** Sponsor / PMO
**Entry criteria** (ALL must hold to OPEN the gate review):
- [LG-10-EN-1] PIR (LG-9) is complete with a recorded benefits verdict (evidence: LG-9 exit PASS).
- [LG-10-EN-2] Operational ownership of the delivered change is confirmed (evidence: the LG-9-EX-4 handoff record).
**Exit criteria** (ALL must hold to PASS — LG-10 is the terminal gate; passing it closes the project):
- [LG-10-EX-1] All deliverables are accepted and formally signed off, or remaining items are explicitly transferred with an owner (evidence: a final acceptance/sign-off record; any carry-over item names a receiving owner).
- [LG-10-EX-2] Financials are reconciled and the budget is closed (evidence: a final cost reconciliation against the LG-1 funding guardrail).
- [LG-10-EX-3] Project resources are released and reallocation is recorded (evidence: team members released / reassigned per a recorded decision).
- [LG-10-EX-4] Project records, lessons learned, and artifacts are archived to their governed homes (evidence: artifacts filed; the lessons-learned log is closed and discoverable).
- [LG-10-EX-5] All RAID items are closed or explicitly transferred to an operational owner with a disposition (evidence: the RAID artifact shows no open project-scoped items; transferred items name the receiving owner).
- [LG-10-EX-6] Stakeholders are notified of formal closure (evidence: a closure communication sent to the named stakeholder set).
**Key decisions:** Formally close the project and release resources / hold closure pending final sign-off or financial reconciliation.
**Artifacts required:** Final acceptance/sign-off record; cost reconciliation; resource-release record; archived project records + closed lessons-learned log; closed/transferred RAID; closure communication.
**Escalation path:** Escalate to the Sponsor / PMO when final deliverable acceptance is withheld, when financials cannot be reconciled, or when RAID items remain open with no operational owner to accept them; trigger = withheld final acceptance, an unreconciled budget, or orphaned open RAID items at closure.
**Checklist template:** → [`gate-checklists.md §2.4`](gate-checklists.md#24-approval-gate-checklist) (Approval Gate Checklist)

---

## 3. Critical Handoff Checklists

Four lifecycle boundaries carry the highest unwind cost when a handoff is incomplete. This section names each, states the gate boundary it protects, and points to the checklist template to run at that boundary. It does **not** restate the checklist content — the templates live in [`gate-checklists.md`](gate-checklists.md) §2/§3 (R-3a de-dup boundary).

| # | Critical handoff | Gate boundary | Checklist template (→ `gate-checklists.md`) | Why critical |
|---|---|---|---|---|
| **H1** | Design → Build | LG-4 → LG-5 (DoR → Dev Complete) | [§2.2 Definition of Ready](gate-checklists.md#22-quality-gate-checklist) | Building on an unready story is the costliest early-stage rework — under-specified AC surface as mid-sprint defects. |
| **H2** | Build → Test | LG-5 → LG-6 (DoD → QA) | [§2.2 Definition of Done](gate-checklists.md#22-quality-gate-checklist) | "Done-but-untested" defects escape downstream where they are far costlier to fix. |
| **H3** | Test → Release | LG-6 → LG-7 → LG-8 (QA → Readiness → Go-Live) | [§2.4 Approval Gate](gate-checklists.md#24-approval-gate-checklist) + [§3 nine-dimension](gate-checklists.md#3-go-live-readiness-assessment) + [§3.2 gates that never compress](gate-checklists.md#32-gates-that-never-compress) | Deployment is high-blast-radius; the never-compress gates (security, backup, rollback, monitoring) live on this boundary. |
| **H4** | Release → Operate | LG-8 → LG-9 → LG-10 (Go-Live → PIR → Closure) | [§3 Operational Readiness dimension](gate-checklists.md#3-go-live-readiness-assessment) + [§2.5 Hypothesis Gate](gate-checklists.md#25-hypothesis-gate-checklist) | Hypercare / benefits-realization handoff; an unowned post-deploy run state is a silent failure that blocks Closure (LG-9-EX-4 / LG-10-EX-5). |

To run any of these handoffs, open the linked template in `gate-checklists.md` and evaluate it against the boundary's exit criteria in §2 above.

---

## 4. Gate Transition Rule

This is the machine-checkable rule that satisfies the acceptance criterion: *at a gate transition with unmet exit criteria, the agent blocks the transition with an evidence-backed rejection citing the specific violated exit criterion.*

When an agent is asked to advance work from Gate N to Gate N+1:

1. Locate Gate N's **Exit criteria** block (§2, the `[LG-N-EX-*]` list).
2. Evaluate EACH `[LG-N-EX-k]` against available evidence as **PASS / FAIL / NO-EVIDENCE**.
3. If ALL are PASS → transition **ALLOWED**.
4. If ANY is FAIL or NO-EVIDENCE → transition **BLOCKED**. Emit an evidence-backed rejection naming the FIRST violated criterion by ID:
   > "Gate N→N+1 BLOCKED: [LG-N-EX-k] unmet — <criterion text>. Evidence: <what was checked and what was missing or failing>. To unblock: <the specific remediation>."
5. A BLOCK is **binary** — "close enough" on any `[LG-N-EX-k]` is still a BLOCK (gate-washing guardrail; see the delivery-engine SKILL.md `## Guardrails`). Render **PASS WITH CONDITIONS** only where the gate type's checklist in [`gate-checklists.md §2`](gate-checklists.md#2-per-gate-type-checklist-templates) explicitly permits a CONDITIONAL outcome (e.g., an Approval gate's Conditional sign-off).

**Worked example.** Advancing an increment LG-5 → LG-6 when the regression suite is failing:

> Gate LG-5→LG-6 BLOCKED: [LG-5-EX-4] unmet — the automated regression suite is not green. Evidence: the latest regression run reports 3 failing cases in the checkout flow (run #482). To unblock: fix the 3 failing cases and attach a green regression run, then re-request the LG-5 exit.

**Reversibility framing.** A gate BLOCK is a CHEAP/MODERATE decision-class output — it returns work, it does not destroy it — and inherits the delivery-engine reversibility-tier discipline (see the delivery-engine SKILL.md `## Reversibility Discipline`). Label the BLOCK verdict with its tier and confidence like any other decision-class output.

**Terminal gate.** LG-10 (Closure) has no successor. Its exit criteria are evaluated the same way; when all pass, the project is formally closed. There is no LG-10 → LG-11 transition.

---

## 5. Cross-References

| Document | Relationship |
|---|---|
| [`gate-checklists.md`](gate-checklists.md) | Gate-TYPE taxonomy + per-type checklist templates + nine-dimension go-live readiness + calibration + anti-patterns. This doc cross-references it for every checklist template; the de-dup boundary is §1 of this doc's Purpose. |
| [`core/schemas/gate-criteria-spec.md`](../../../../core/schemas/gate-criteria-spec.md) | The platform-release **pipeline-stage** gates (`G-PR*/G-EX*/G-CL*`). Disambiguated from these project-lifecycle `LG-` gates by the namespace note in Purpose. |
| [`sprint-defaults.md`](sprint-defaults.md) | Sprint cadence / capacity / velocity handling, consumed at the LG-4 (DoR) and LG-5 (DoD) work-item gates. |
| [`dependency-rules.md`](dependency-rules.md) | Dependency types + escalation triggers, consumed at LG-3 (dependency register) and LG-4 (dependency clearance). |
| `estimation-standards.md` · `capacity-model.md` (same dir; authored in this same release) | Estimation and capacity references consumed at LG-1/LG-3 (capacity confirmation) and LG-4 (sizing). Links added when those docs land on this branch. See § Provenance. |
| delivery-engine `SKILL.md` (`../SKILL.md`) | The consumer skill — Mode F applies these gates' exit criteria + the §4 transition rule; Mode G attributes gate decisions; Mode C references for context. |

**Sibling-list reconciliation (out of scope here).** Three other corpus docs carry divergent, partial project-lifecycle gate lists today (`pmo-process-designer/references/traceability-matrix.md`, `ppm-agent/references/artifact-gap-detection.md`, `comms-writer/references/channel-formats.md`). Reconciling them to this canonical eleven-gate sequence is tracked separately and is NOT performed in this doc.

---

## Version History

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-06-13 | Initial authoring — canonical eleven-gate project-lifecycle sequence (LG-0 Idea Screen → LG-10 Closure), per-gate 6-field blocks with `LG-N-EX-k` exit-criterion IDs, the §4 gate-transition BLOCK rule, and the four critical-handoff pointers. Provenance `UNSOURCED-DOMAIN`. Authored under the delivery-capacity-and-lifecycle-gating release (eleven-gate A2 model per Collective Review operator override). |
