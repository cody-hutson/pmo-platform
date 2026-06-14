<!-- reference-durability: allow-link -->

# Lifecycle Stages — Universal Delivery Lifecycle (15-Stage Model)

## Purpose

This document is the canonical **enumeration** of the **15-stage universal delivery lifecycle** — the sequence of stages a managed project moves through from demand intake to post-implementation closure. It is the **temporal axis** of project delivery: WHAT sequence of stages work passes through, with per-stage entry criteria, exit criteria, and the artifacts each stage consumes and produces. It is read by the delivery-engine skill: **Mode C (Refinement Manager / DoR Gate)** reads the *entry criteria* of the execution stages; **Mode F (DoD & Release Readiness Gate)** reads the *exit criteria* of the validation stages — including the QA/Acceptance exit predicate that blocks a move to Plan Review while a P1 defect is open (§5).

**This is the project delivery lifecycle, NOT the platform's release pipeline.** The platform's 13-stage release pipeline ([`release/references/pipeline/`](../../../../release/references/pipeline/README.md)) is the Process layer that governs how the platform builds its *own* releases; it is itself described in the pipeline README as compressed from the PMO Reference Model Part 6 — the 15-stage universal delivery lifecycle this document enumerates. Same lineage, different artifact, different consumer. This document is a delivery-engine reference for the *projects the platform manages*; do not cross-wire it with the release pipeline or renumber either.

**Grounding.** The 15-stage count and its five-phase super-grouping (Capture → Prepare → Build → Validate → Deliver) are internally grounded — cited as the authoritative model in [`core/schemas/navigation-layer-schema.md`](../../../../core/schemas/navigation-layer-schema.md), [`core/schemas/frontmatter-schema.md`](../../../../core/schemas/frontmatter-schema.md), and the release-pipeline README — and nine of the fifteen stage names are directly cited in the pipeline-stage docs (`Identify` + `Capture` at Stages 1–2, `QA` + `acceptance review` at Stages 8–9, `Verify` / `Clean` / `Close` at Stages 13–15). The Part-6 *source document* that defines the per-stage prose is absent from the repository (consistent with the content-sourcing decision for this release), so the six reconstructed stages carry an inline `UNSOURCED-DOMAIN` provenance flag at the prose level — the count and grouping are not unsourced.

**Three-axis relationship (the coherence point).** This document is one of three that together describe project governance; each owns a distinct axis and does not restate the others:

- `lifecycle-stages.md` (this doc) = the **temporal axis** — the 15-stage sequence a project moves through.
- [`gate-definitions.md`](gate-definitions.md) = the **decision-instance axis** — the 11 named lifecycle gates (LG-0 Idea Screen … LG-10 Closure), each a specific go/kill checkpoint with entry/exit/authority/artifacts/escalation.
- [`gate-checklists.md`](gate-checklists.md) = the **gate-type taxonomy** — which of 5 *kinds* of gate (Phase / Quality / Flow / Approval / Hypothesis) each instance is, and the per-type checklists.

The §3 stage↔gate seam wires this doc's stages to the gate-definitions instances; §6 forward-notes the gate-type relationship. This doc references gates by their `LG-N` identity; it does not define them.

---

## 1. The Five-Phase Super-Grouping

The 15 stages are grouped into five phases (verbatim from `navigation-layer-schema.md` — do not rename). The phases are an organizing super-structure; the stages are the unit of transition.

| Phase | Member stages | Phase intent |
|---|---|---|
| **Capture** | 1 Identify · 2 Capture | Surface demand and record it as a structured, classified work item. |
| **Prepare** | 3 Classify & Prioritize · 4 Define Requirements · 5 Plan & Sequence · 6 Design / Solution | Make the work ready to build — sized, prioritized, specified, planned, and designed. |
| **Build** | 7 Build / Develop · 8 Developer Testing | Implement the solution and verify it at the developer level. |
| **Validate** | 9 QA / Acceptance Testing · 10 Plan Review / Authorize | Independently validate quality against acceptance criteria and authorize release. |
| **Deliver** | 11 Release Preparation · 12 Deploy / Execute · 13 Verify · 14 Clean / Stabilize · 15 Close / Post-Implementation | Stage, deploy, verify, stabilize, and formally close the work. |

The lifecycle spans **Intake (Stages 1–2) through Post-Implementation (Stage 15)**.

---

## 2. The 15 Stages

Each stage below carries the fixed 4-field block: **Phase**, **Intent**, **Entry criteria** (ALL must hold to enter), **Exit criteria** (ALL must hold to leave — a violated exit criterion BLOCKS the move to the next stage), **Artifacts consumed**, **Artifacts produced**, and **Gate at exit** (the `LG-N` reference from [`gate-definitions.md`](gate-definitions.md), or "none — intra-phase flow"). Stage names directly cited from the in-repo Part-6 citations are unflagged; reconstructed stages carry an inline `UNSOURCED-DOMAIN` flag.

### 2.1 Identify

**Phase:** Capture
**Intent:** Surface and recognize demand from any source (request, incident, idea, strategic mandate).

**Entry criteria** (ALL must hold to enter):
- A demand signal exists from a named source — evidence: an inbound request, incident, idea, or mandate is on record with a requester.

**Exit criteria** (ALL must hold to leave):
- The demand is recognized as in-mandate for the portfolio — evidence: a recorded acknowledgement that the demand belongs to this delivery surface (not redirected elsewhere).

**Artifacts consumed:** Inbound demand signal (request / incident / idea / mandate).
**Artifacts produced:** A recognized demand item with a named requester.

**Gate at exit:** LG-0 (Idea Screen) sits at the lifecycle entry boundary spanning Identify→Capture; the Idea Screen formally screens the captured item in or out (see §3).

### 2.2 Capture

**Phase:** Capture
**Intent:** Record the demand as a structured, classified work item at the point of intake.

**Entry criteria** (ALL must hold to enter):
- A recognized demand item exists from Stage 1 — evidence: the Stage 1 exit is recorded.

**Exit criteria** (ALL must hold to leave):
- The work item is captured with a one-line problem statement, a named requester, and an initial type — evidence: the intake record exists with these fields populated, not placeholders.
- A strategic-fit hypothesis is stated (which objective the item serves) — evidence: the fit statement is present even if unvalidated.

**Artifacts consumed:** Recognized demand item.
**Artifacts produced:** A structured intake record (problem statement, requester, type, strategic-fit hypothesis).

**Gate at exit:** LG-0 (Idea Screen) — the Idea Screen's exit predicate (strategic-fit screen + rough size band + no disqualifying constraint) is evaluated here before the item advances into Prepare (see §3).

### 2.3 Classify & Prioritize

`UNSOURCED-DOMAIN` — reconstructed from PMBOK Planning process group + standard backlog-triage practice; the Part-6 source prose is absent from the repo.

**Phase:** Prepare
**Intent:** Assign type, size band, and priority; confirm the item is worth advancing.

**Entry criteria** (ALL must hold to enter):
- The item cleared the Idea Screen (LG-0 exit PASS) — evidence: the screen decision is recorded.

**Exit criteria** (ALL must hold to leave):
- The item carries a confirmed type, a rough size/effort band, and a priority — evidence: the three fields are populated (a T-shirt size or effort tier, not a point estimate, suffices at this stage).
- A duplicate check has been performed against the active backlog — evidence: a recorded duplicate-screen result.

**Artifacts consumed:** Structured intake record.
**Artifacts produced:** A classified, prioritized work item with a size band.

**Gate at exit:** none — intra-Prepare flow. (The business-case decision for project-altitude work is LG-1; for work-item-level flow this stage feeds Define Requirements directly.)

### 2.4 Define Requirements

`UNSOURCED-DOMAIN` — reconstructed from PMBOK Planning process group + standard SDLC requirements practice; the Part-6 source prose is absent from the repo.

**Phase:** Prepare
**Intent:** Elaborate acceptance criteria, scope, and constraints to the level required for planning and design.

**Entry criteria** (ALL must hold to enter):
- The item is classified and prioritized (Stage 3 exit) — evidence: the classification is recorded.

**Exit criteria** (ALL must hold to leave):
- Acceptance criteria are defined as specific, testable conditions — evidence: AC written in Given/When/Then or an equivalent testable form.
- Scope boundaries and known constraints are stated — evidence: an in/out-of-scope statement and a constraints note.

**Artifacts consumed:** Classified, prioritized work item.
**Artifacts produced:** A requirements set (testable AC, scope statement, constraints).

**Gate at exit:** none — intra-Prepare flow.

### 2.5 Plan & Sequence

`UNSOURCED-DOMAIN` — reconstructed from PMBOK Planning process group + standard capacity-and-dependency planning practice; the Part-6 source prose is absent from the repo.

**Phase:** Prepare
**Intent:** Commit capacity, establish a timeline, and map dependencies.

**Entry criteria** (ALL must hold to enter):
- Requirements are defined (Stage 4 exit) — evidence: the requirements set exists.

**Exit criteria** (ALL must hold to leave):
- Capacity is committed against the planned scope for the planning horizon — evidence: a capacity assessment referencing team availability (capacity discipline per [`capacity-model.md`](capacity-model.md)).
- A timeline with milestones is established — evidence: a scheduled plan with dated milestones.
- Dependencies are identified with owners and need-by dates — evidence: a dependency register with an owner and date per edge (see [`dependency-rules.md`](dependency-rules.md)).

**Artifacts consumed:** Requirements set.
**Artifacts produced:** A baselined plan (committed capacity, timeline, dependency register).

**Gate at exit:** LG-3 (Plan Baseline / Readiness) for project-altitude work — the plan is baselined and execution is authorized here (see §3).

### 2.6 Design / Solution

`UNSOURCED-DOMAIN` — reconstructed from PMBOK Planning process group + standard SDLC design practice; the Part-6 source prose is absent from the repo.

**Phase:** Prepare
**Intent:** Resolve design decisions and produce implementation-ready specifications; validate feasibility.

**Entry criteria** (ALL must hold to enter):
- The plan is baselined for the window this work falls in (Stage 5 / LG-3 exit) — evidence: the baseline is recorded.

**Exit criteria** (ALL must hold to leave):
- A technical approach is resolved with no open architecture question — evidence: a design note (or a recorded "no design needed").
- Feasibility is validated against the requirements and constraints — evidence: a feasibility assessment referencing the constraints from Stage 4.

**Artifacts consumed:** Baselined plan; requirements set.
**Artifacts produced:** Implementation-ready design specs; feasibility assessment.

**Gate at exit:** LG-4 (Sprint DoR / Execution Entry) admits the refined, designed work item to execution at the Prepare→Build boundary — the Definition of Ready (see §3).

### 2.7 Build / Develop

**Phase:** Build
**Intent:** Implement the solution per the design and requirements.

**Entry criteria** (ALL must hold to enter):
- The work item passed Execution Entry (LG-4 DoR exit PASS) — evidence: the DoR result is recorded.

**Exit criteria** (ALL must hold to leave):
- The implementation is complete and committed against the acceptance criteria — evidence: the change is committed and a "done" claim is raised referencing the AC.

**Artifacts consumed:** Design specs; requirements set; admitted (DoR-passed) work item.
**Artifacts produced:** The implemented increment (committed change).

**Gate at exit:** none — intra-Build flow into Developer Testing. (The Dev Complete / DoD gate LG-5 fires after developer testing, at the Build→Validate boundary.)

### 2.8 Developer Testing

**Phase:** Build
**Intent:** Unit and integration verification of the increment by the builder.

**Entry criteria** (ALL must hold to enter):
- An implemented increment exists with a "done" claim (Stage 7 exit) — evidence: the committed change and the claim are on record.

**Exit criteria** (ALL must hold to leave):
- Unit and integration tests pass with coverage on the new code — evidence: a green test run / coverage report.
- The automated regression suite is green — evidence: a passing regression run.
- The increment builds cleanly — evidence: a successful build.

**Artifacts consumed:** Implemented increment.
**Artifacts produced:** A developer-tested increment with test/coverage/build evidence.

**Gate at exit:** LG-5 (Dev Complete / DoD) — the Definition of Done is evaluated at the Build→Validate boundary before the increment passes to QA (see §3).

### 2.9 QA / Acceptance Testing

**Phase:** Validate
**Intent:** Independent QA and acceptance review against the acceptance criteria. **This is the AC-critical stage** — its exit predicate blocks a move to Plan Review while a P1 defect is open (§5).

**Entry criteria** (ALL must hold to enter):
- The increment passed Dev Complete (LG-5 DoD exit PASS) — evidence: the DoD result is recorded.
- A test environment with representative data is available — evidence: the environment is reachable and seeded.

**Exit criteria** (ALL must hold to leave — BLOCKING):
- **No open defect of severity P1 (Critical) is associated with the work item** — evidence: the defect tracker shows no open P1 against the item (the AC predicate; see §5 for the full enforcement spec). This is severity-specific: P1 hard-blocks; P2/P3/P4 route to the gate authority's risk judgment.
- Planned QA test cases are executed with a recorded pass rate meeting the agreed threshold — evidence: a test-execution report with pass rate vs. threshold.
- Regression and integration testing across affected interfaces is green end-to-end — evidence: an integration/regression run covering the touched interfaces.
- Scoped non-functional checks (performance / security as scoped) are met — evidence: the scoped NFR results.

**Artifacts consumed:** Developer-tested increment; acceptance criteria (from Stage 4).
**Artifacts produced:** A QA-passed increment; test-execution report; defect inventory with severities; acceptance verdict per criterion.

**Gate at exit:** LG-6 (QA Gate) sits at the **Stage 9 (QA/Acceptance) → Stage 10 (Plan Review/Authorize)** boundary; LG-6's exit criterion `[LG-6-EX-2]` ("zero open critical or high-severity defects") is the gate-side predicate this stage's P1 exit criterion feeds (see §3 and §5).

### 2.10 Plan Review / Authorize

`UNSOURCED-DOMAIN` — reconstructed from PMBOK Monitoring & Controlling process group + standard release-authorization (go/no-go) practice; the Part-6 source prose is absent from the repo.

**Phase:** Validate
**Intent:** Go/No-Go authorization of the validated work with an evidence package. **The QA→here move is the AC's blocked transition** when a P1 defect is open.

**Entry criteria** (ALL must hold to enter):
- The increment passed the QA Gate (LG-6 exit PASS), which includes the no-open-P1 predicate (Stage 9 exit) — evidence: the QA Gate result is recorded with the defect inventory.
- A release candidate is identified — evidence: a named, versioned candidate exists.

**Exit criteria** (ALL must hold to leave):
- A documented Go/No-Go decision is rendered with an evidence package — evidence: a recorded authorization decision referencing the QA results and AC verdicts.
- The go-live readiness assessment shows no Red dimension (at most two Amber with documented mitigations) — evidence: the completed readiness assessment (see [`gate-checklists.md §3`](gate-checklists.md)).

**Artifacts consumed:** QA-passed increment; release candidate; acceptance report.
**Artifacts produced:** A release authorization decision with evidence package.

**Gate at exit:** LG-7 (Release Readiness) — the Go/No-Go on the release candidate at the Validate→Deliver boundary (see §3).

### 2.11 Release Preparation

`UNSOURCED-DOMAIN` — reconstructed from PMBOK Executing process group + standard release-management practice; the Part-6 source prose is absent from the repo.

**Phase:** Deliver
**Intent:** Stage the release — runbook, rollback plan, communications, and pre-deployment snapshots.

**Entry criteria** (ALL must hold to enter):
- The release is authorized (Stage 10 / LG-7 exit PASS) — evidence: the authorization decision is recorded.

**Exit criteria** (ALL must hold to leave):
- A deployment runbook is documented and reviewed by operations — evidence: a reviewed runbook.
- A rollback plan is documented and validated against a tested restore point, with quantitative rollback triggers defined — evidence: a verified rollback procedure plus recorded error-rate / response-time / availability thresholds (see [`gate-checklists.md §3.3`](gate-checklists.md)).
- Stakeholder communications and required enablement are prepared — evidence: a drafted comms plan and training-completion status.

**Artifacts consumed:** Release authorization decision.
**Artifacts produced:** A deployment-ready release package (runbook, validated rollback + triggers, comms/training).

**Gate at exit:** LG-8 (Go-Live / Deployment Approval) — the Change Authority approves deployment into production at the Release-Prep→Deploy boundary (see §3).

### 2.12 Deploy / Execute

**Phase:** Deliver
**Intent:** Deploy to production, execute the cutover, and monitor.

**Entry criteria** (ALL must hold to enter):
- Deployment is approved (Stage 11 / LG-8 exit PASS) — evidence: the change record with approver sign-off is recorded.
- A pre-deployment backup is taken and monitoring is configured — evidence: a verified backup and active monitoring/alerting before cutover.

**Exit criteria** (ALL must hold to leave):
- The deployment completes and the cutover executes per the runbook — evidence: a deployment completion record.
- Post-deployment monitoring is live and reporting — evidence: monitoring active with alerts firing on threshold breach.

**Artifacts consumed:** Deployment-ready release package.
**Artifacts produced:** The change live in production; a deployment completion record.

**Gate at exit:** none — the Go-Live approval (LG-8) gates *entry* to deployment; intra-Deliver flow continues into Verify.

### 2.13 Verify

**Phase:** Deliver
**Intent:** Confirm the deployment succeeded and verify the change against the acceptance criteria in production.

**Entry criteria** (ALL must hold to enter):
- The change is live in production (Stage 12 exit) — evidence: the deployment completion record exists.

**Exit criteria** (ALL must hold to leave):
- The deployment is verified against the acceptance criteria in the production environment — evidence: a post-deployment verification result referencing the AC.
- No critical post-deploy defect is open — evidence: the defect tracker shows no open critical against the live change (or a documented, approved exception).

**Artifacts consumed:** The change live in production; acceptance criteria.
**Artifacts produced:** A post-deployment verification result.

**Gate at exit:** none — intra-Deliver flow into Clean / Stabilize. (The Deployment-Verified handoff boundary is checklist-governed per [`gate-definitions.md §3`](gate-definitions.md) H4; the next named gate is LG-9 PIR after stabilization.)

### 2.14 Clean / Stabilize

**Phase:** Deliver
**Intent:** Close out artifacts, stabilize the change in production (hypercare), and hand to operations.

**Entry criteria** (ALL must hold to enter):
- The deployment is verified (Stage 13 exit) — evidence: the verification result is recorded.

**Exit criteria** (ALL must hold to leave):
- The agreed stabilization / hypercare window is complete — evidence: the stabilization period has elapsed with monitored stability.
- Operational ownership of the deployed change is confirmed — evidence: a named operational owner / run-team handoff record.
- Outcome and leading-indicator data have been collected per the measurement plan — evidence: a measurement report for the agreed metrics.

**Artifacts consumed:** Post-deployment verification result.
**Artifacts produced:** A stabilized, operationally-owned change; a measurement report.

**Gate at exit:** LG-9 (Post-Implementation Review) — the benefits/outcome review fires at/after stabilization, before Closure (see §3).

### 2.15 Close / Post-Implementation

**Phase:** Deliver
**Intent:** Final closure — records update, resource release, and post-implementation review / lessons learned.

**Entry criteria** (ALL must hold to enter):
- The PIR is complete with a recorded benefits verdict (Stage 14 / LG-9 exit PASS) — evidence: the PIR result is recorded.
- Operational ownership is confirmed — evidence: the LG-9 handoff record.

**Exit criteria** (ALL must hold to leave — this is the terminal stage; passing closes the work):
- All deliverables are accepted and formally signed off, or remaining items are explicitly transferred with an owner — evidence: a final acceptance/sign-off record.
- Project records, lessons learned, and artifacts are archived to their governed homes — evidence: artifacts filed; the lessons-learned log closed and discoverable.
- All RAID items are closed or explicitly transferred to an operational owner with a disposition — evidence: the RAID artifact shows no open project-scoped items.
- Stakeholders are notified of formal closure — evidence: a closure communication to the named stakeholder set.

**Artifacts consumed:** Stabilized change; measurement report; PIR result.
**Artifacts produced:** A closed work item (final acceptance, archived records, closed RAID, closure communication).

**Gate at exit:** LG-10 (Closure) — the terminal gate; passing it formally closes the project. There is no successor stage (see §3).

---

## 3. Stage→Gate Seam (references [`gate-definitions.md`](gate-definitions.md) — does NOT define gates)

[`gate-definitions.md`](gate-definitions.md) establishes the canonical **eleven-gate project lifecycle: LG-0 (Idea Screen) → LG-10 (Closure)**, each gate with entry/exit criteria, authority holder, artifacts, and escalation path. This table records only **which lifecycle-stage boundary each gate sits at**; gate identity, entry/exit criteria, authority, and escalation are defined in [`gate-definitions.md`](gate-definitions.md), not here.

| Gate (from gate-definitions.md) | Sits at lifecycle boundary | Gate's role |
|---|---|---|
| **LG-0** — Idea Screen | lifecycle entry — Stages 1–2 (Identify → Capture) → entry to Prepare | Screen captured demand in or out |
| **LG-1** — Portfolio Intake / Business Case | project-altitude — after Stage 3 (Classify & Prioritize), funding the business case | Fund / hold / reject the business case |
| **LG-2** — Project Initiation / Kickoff | project-altitude — authorizes the project before plan baselining | Authorize the project; commit initiation resources |
| **LG-3** — Plan Baseline / Readiness | Stage 5 (Plan & Sequence) → Stage 6 (Design / Solution) | Baseline the plan; authorize execution |
| **LG-4** — Sprint DoR (Execution Entry) | Stage 6 (Design / Solution) → Stage 7 (Build / Develop) — the Prepare→Build boundary | Admit the work item to execution (Definition of Ready) |
| **LG-5** — Dev Complete (DoD) | Stage 8 (Developer Testing) → Stage 9 (QA / Acceptance) — the Build→Validate boundary | Accept the increment as Done (Definition of Done) |
| **LG-6** — QA Gate | **Stage 9 (QA / Acceptance) → Stage 10 (Plan Review / Authorize)** | **Quality gate — reads the no-open-P1 exit predicate (the AC; §5)** |
| **LG-7** — Release Readiness | Stage 10 (Plan Review / Authorize) → Stage 11 (Release Preparation) — the Validate→Deliver boundary | Go / no-go on the release candidate |
| **LG-8** — Go-Live / Deployment Approval | Stage 11 (Release Preparation) → Stage 12 (Deploy / Execute) | Approve deployment into production |
| **LG-9** — Post-Implementation Review (PIR) | Stage 14 (Clean / Stabilize) → Stage 15 (Close) — at/after stabilization | Persevere / pivot / cancel; benefits verdict |
| **LG-10** — Closure | terminal — at Stage 15 (Close) | Formally close the project; release resources |

**Reading the seam.** Gates LG-4 through LG-6 are the **work-item-level** gates (per increment / per sprint), sitting on the Prepare→Build→Validate transitions; LG-0 through LG-3 and LG-7 through LG-10 are **project-altitude** gates. A single work item may cycle LG-4 → LG-5 → LG-6 many times within one project window. The seam is intentionally **not** one-gate-per-stage-boundary: gates sit at the **decision-significant** boundaries, and several intra-phase stage transitions (e.g., Classify → Define Requirements, Deploy → Verify) carry no named gate (the "none — intra-phase flow" entries in §2). The two named critical-handoff boundaries that this doc's stages cross without a *new* gate — Deployment Verified (Stage 13→14) and Release→Operate (Stage 14→15) — are checklist-governed per [`gate-definitions.md §3`](gate-definitions.md) (H3/H4).

**The load-bearing cell** is LG-6 at the Stage 9 → Stage 10 boundary: this is where the AC's P1 block is enforced (§5). The two endpoint cells (LG-0 at lifecycle entry; LG-10 at Close) anchor the sequence.

---

## 4. Five-Model Terminology Mapping

The grid below maps the 15 universal stages onto the **five methodology archetypes named in the originating requirement** (Scrum / Kanban / Waterfall / Hybrid / SAFe), showing how each stage expresses under that archetype (compress / rename / map-to-ceremony). The SAFe and Hybrid columns use the semantic anchors defined in [`methodology-parameterization-v1.md §3`](../../../../release/references/specs/methodology-parameterization-v1.md) (SAFe = Essential 5.0+ with PI cadence + ART; Hybrid = the SPM-co-managed dual-lifecycle pattern).

| Universal stage(s) | Scrum | Kanban | Waterfall | Hybrid | SAFe |
|---|---|---|---|---|---|
| 1–2 Identify / Capture | Product Backlog item created | Card enters Backlog column | Demand log / change request | Demand intake (shared) | Portfolio Kanban / Epic intake |
| 3 Classify & Prioritize | Backlog refinement | Replenishment / prioritization | Initiation gate | Refinement (agile track) | WSJF prioritization |
| 4 Define Requirements | Story elaboration + AC | Card readiness policy | Requirements spec phase | Requirements (predictive track) | Story / Feature elaboration |
| 5 Plan & Sequence | Sprint Planning | Pull / WIP-limited commit | Planning phase + WBS | Front-loaded plan + sprint plan | PI Planning |
| 6 Design / Solution | In-sprint design | In-flow design | Design phase (gated) | Predictive design | Architectural runway / design |
| 7 Build / Develop | Sprint execution | Pull through Dev column | Build phase | Iterative build (agile track) | Team sprints inside the PI |
| 8 Developer Testing | In-sprint dev test | In-flow verification | Build-phase unit test | Iterative dev test | Team-level test in sprint |
| 9 QA / Acceptance | In-sprint QA toward DoD | QA column toward exit policy | Test phase (gated) | QA in the agile zone | System-level test / cascading DoD |
| 10 Plan Review / Authorize | DoD acceptance (not a release gate) | Delivery-point policy | Phase-gate approval | Bridge gate (predictive ↔ iterative) | System Demo + Inspect & Adapt |
| 11 Release Preparation | Release-ready increment | Continuous-delivery prep | Deployment-plan phase | Release prep (shared) | Release-on-demand prep |
| 12 Deploy / Execute | Sprint release | Continuous deploy | Deploy phase | Deploy (shared) | Release on demand |
| 13 Verify | Increment validation | Post-deploy flow check | Verification phase | Verify (shared) | Solution validation |
| 14 Clean / Stabilize | Sprint cleanup | Continuous stabilization | Stabilization phase | Stabilize (shared) | Stabilize / hardening |
| 15 Close / Post-Impl | Sprint Retrospective | Service-delivery review | Project closure phase | Closure + retro | Inspect & Adapt / PI retro |

**These five archetypes are five of the eight canonical `delivery_approach` values** defined in [`methodology-parameterization-v1.md`](../../../../release/references/specs/methodology-parameterization-v1.md); XP, PRINCE2, and Custom follow the same stage model and are omitted here only because this mapping scopes to the five named in the originating requirement. This is a labeled subset, not a competing five-archetype taxonomy — do not infer a methodology universe of five.

---

## 5. Stage Exit-Criteria Enforcement

Exit criteria are **BLOCKING**: a work item cannot move to the next stage while any exit criterion for its current stage is unmet. The agent renders the block with evidence — it does not advance the item and round up. A BLOCK is **binary**: "close enough" on any exit criterion is still a BLOCK (the gate-washing guardrail; see the delivery-engine SKILL.md `## Guardrails`).

### 5.1 QA / Acceptance (Stage 9) → Plan Review / Authorize (Stage 10)

This is the acceptance criterion for the universal lifecycle: *a work-item move from QA/Acceptance to Plan Review BLOCKS when a P1 defect is open, with evidence.* The gate that fires at this boundary is **LG-6 (QA Gate)**; its exit criterion `[LG-6-EX-2]` ("zero open critical or high-severity defects") is the gate-side predicate this stage exit criterion feeds.

**Blocking exit predicate (Stage 9):** No open defect of severity **P1 (Critical)** is associated with the work item. A P1 defect is "open" when its status is not in a closed / resolved-verified terminal state.

**Enforcement behavior:** When a move from QA/Acceptance (Stage 9) to Plan Review (Stage 10) is requested and a P1 defect is open, the agent **BLOCKS** the transition and emits an evidence-backed rejection naming: (a) the specific P1 defect id(s) and current status, (b) the exit criterion violated, and (c) the required remediation — resolve-and-verify the P1, or obtain a documented severity-downgrade decision from the accountable authority (the LG-6 QA Lead per [`gate-definitions.md`](gate-definitions.md)). The agent does not advance the item; it does not mark Plan Review entry-eligible.

**Evidence format the rejection cites:**

> BLOCKED — QA/Acceptance (Stage 9) → Plan Review (Stage 10). Open P1 defect `<ID>` (status: `<status>`) violates Stage 9 exit criterion "no open P1 defect" and the LG-6 QA Gate exit criterion `[LG-6-EX-2]`. To unblock: resolve-and-verify `<ID>`, or record an authority severity downgrade, before re-requesting the move.

This predicate is **severity-specific**: P2/P3/P4 defects do not auto-block — they route to the gate authority's risk-acceptance judgment per the gate model (see [`gate-definitions.md §4`](gate-definitions.md)). Only **P1** hard-blocks.

**Why exit-criterion encoding (not a gate redefinition).** The *gate* that fires at this boundary (LG-6) is owned by [`gate-definitions.md`](gate-definitions.md); this doc owns the *stage exit criterion* — the temporal predicate that the gate's quality check reads. The predicate stated here and the gate criterion `[LG-6-EX-2]` are two views of the same rule: this doc binds it to the Stage 9 → Stage 10 transition; gate-definitions.md binds it to the LG-6 QA Gate's authority and escalation path.

**Reversibility framing.** A stage BLOCK is a CHEAP/MODERATE decision-class output — it returns work, it does not destroy it — and inherits the delivery-engine reversibility-tier discipline (see the delivery-engine SKILL.md `## Reversibility Discipline`). Label the BLOCK verdict with its tier and confidence like any other decision-class output.

---

## 6. Relationship to Gate Types and Gate Checklists

Each lifecycle gate instance in [`gate-definitions.md`](gate-definitions.md) is one of the **five gate TYPES** defined in [`gate-checklists.md §1`](gate-checklists.md) — Phase / Quality / Flow / Approval / Hypothesis — and each runs the per-type checklist template in [`gate-checklists.md §2`](gate-checklists.md). This doc does not classify gate types or restate checklists; it records stage placement (§3) and stage exit criteria (§2, §5). The gate-type taxonomy is owned by [`gate-checklists.md`](gate-checklists.md); the gate instances and their types are listed in [`gate-definitions.md §1`](gate-definitions.md).

For example: LG-6 (the QA Gate carrying the AC's P1 predicate) is a **Quality** gate — it runs the Quality Gate / DoD checklist plus the Test-Quality readiness dimension per [`gate-definitions.md`](gate-definitions.md) Gate 6. The temporal predicate lives here (§5); the gate type, authority, and checklist live in the gate docs.

---

## 7. Cross-References

| Document | Relationship |
|---|---|
| [`gate-definitions.md`](gate-definitions.md) | The eleven-gate lifecycle-instance sequence (LG-0 → LG-10). This doc's §3 seam references it for gate identity; §5 binds the AC predicate to LG-6. The de-dup boundary: this doc owns stage exit criteria; gate-definitions.md owns gate entry/exit/authority/escalation. |
| [`gate-checklists.md`](gate-checklists.md) | The gate-TYPE taxonomy (5 types) + per-type checklist templates + nine-dimension readiness. §6 forward-notes the type relationship; this doc never restates checklist content. |
| [`methodology-parameterization-v1.md`](../../../../release/references/specs/methodology-parameterization-v1.md) | The canonical 8-value `delivery_approach` enum. §4's five-model grid is a labeled five-of-eight subset; SAFe/Hybrid semantics anchor to this doc's §3 definitions. |
| [`dependency-rules.md`](dependency-rules.md) | Dependency types + escalation triggers, consumed at Stage 5 (Plan & Sequence — dependency register) and Stage 6 (DoR dependency clearance). |
| [`estimation-standards.md`](estimation-standards.md) · [`capacity-model.md`](capacity-model.md) (same dir) | Estimation and capacity references consumed at Stage 3 (size band), Stage 5 (capacity commitment), and Stage 6 (DoR sizing). |
| delivery-engine [`SKILL.md`](../SKILL.md) | The consumer skill — Mode C reads stage entry criteria (DoR is the entry gate to Build); Mode F reads QA/Acceptance exit criteria and the §5 P1 block (the AC). |

---

## Version History

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-06-13 | Initial authoring — the canonical fifteen-stage universal delivery lifecycle (Identify → Close, grouped into the five Capture/Prepare/Build/Validate/Deliver phases), per-stage 4-field blocks with entry/exit criteria and artifacts, the §3 stage↔gate seam to the committed eleven-gate LG-0…LG-10 model, the §4 five-model terminology mapping (a labeled five-of-eight subset of the `delivery_approach` enum), and the §5 QA→Plan-Review P1-defect blocking exit predicate (the AC, bound to LG-6). Nine stage names are in-repo Part-6-grounded; six (Stages 4 and 11, plus reconstructed prose) carry `UNSOURCED-DOMAIN` provenance. Authored under the delivery-capacity-and-lifecycle-gating release. |
