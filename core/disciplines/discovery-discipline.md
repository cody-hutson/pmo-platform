---
title: Discovery Discipline Framework
purpose: Shared discipline methodology for discovery-class work (premise-interrogation, gap-surfacing, assumption-auditing as a first-class activity-class)
applies_to: hub-spoke-bridge.md Stage 4/5 phases, release-personas.md Stage 5, release-planner / pmo-skill-editor / pmo-qa-auditor (discovery-audit modes), intake authoring, roadmap revision, post-failure / post-surprise contexts
parallel_to:
  - ../disciplines/decision-discipline.md
  - ../disciplines/review-discipline-principles.md
  - ../standards/failure-mode-standard.md
  - ../specs/reversibility-protocol.md
source: premise-interrogation at Triage→Design (first concrete shipped instance) + initiative-roadmap F9 gap-analysis + Review Composition Framework (adjacent classes) + Stage 13 self-learnings (pattern-emergence instance) + 2026-04-25 forked-session observation surfacing the parts-without-whole gap
---

# Discovery Discipline Framework

Shared discipline methodology for discovery-class work. When a consumer's primary function is asking *"what should this be?"* / *"what don't we know?"* / *"what assumptions are operating?"* / *"what evidence is missing?"* / *"where does scope cleave?"* — surfacing the question set BEFORE an artifact exists to be reviewed — it inherits the rules below.

**Relationship to the four sibling meta-protocols:** Parallel, not extension. Each sibling governs a distinct activity-class with a distinct temporal anchor and audience:

| Sibling | Activity-class | Primary question | Temporal anchor |
|---|---|---|---|
| `explanation/decision-discipline.md` | Decision | "What should we choose?" | At the decision point (recommendation drafted; operator about to act) |
| `explanation/review-discipline-principles.md` | Review | "Is this correct?" | After the artifact exists (audit / QA / review of produced output) |
| `standards/failure-mode-standard.md` | Failure-mode authoring | "What fails, why, and how?" | Pre-authoring (skill spec definition); enforced at G7 |
| `specs/reversibility-protocol.md` | Tier classification | "What's the cost of being wrong?" | At decision-output time (paired with recommendation); enforced at G4 |
| `explanation/discovery-discipline.md` (this file) | **Discovery** | **"What should this be? What don't we know?"** | **Before the artifact exists** (pre-shape, pre-decision, pre-review) |

Cross-reference between the four siblings and this file; no inheritance. A skill performing multiple functions cites the relevant sibling for each — discovery-class output cites this file; the downstream decision cites `decision-discipline.md`; the eventual review cites `review-discipline-principles.md`.

---

## Section 1 — Scope and Applicability

### 1.1 What is discovery-class work?

Discovery-class work produces a question set, gap inventory, premise audit, scope-cleavage map, and evidence-quality scorecard that downstream stages consume. It is the activity that shapes what should exist before it exists. Examples:

- **Premise interrogation** — challenging stale assumptions during stage entry (Triage→Design re-review per Stage 5 Phase 0.5 delta).
- **Gap surfacing** — naming what is missing from a framework, intake, or roadmap (F9 4-case diagnostic per `initiative-roadmap-framework.md`).
- **Assumption auditing** — surfacing implicit assumptions and labeling them `[ASSUMPTION – CONFIRM]` per CLAUDE.md "No invention."
- **Evidence-quality challenge** — applying the 5-label vocabulary (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`) to factual claims at the point they are made.
- **Knowability assessment** — distinguishing "we don't know yet" from "we can't know" and routing accordingly (spike vs. constraint).
- **Scope-cleavage identification** — naming where work naturally splits before bundling, so 1→N decomposition (per the fission protocol) operates on visible cleavage lines rather than ad-hoc partitioning.
- **Pattern emergence** — surfacing repeating signals across ≥N instances per the observation-log emergence rule (N=2 same-(domain, theme) within 180 days per `decision-discipline.md` § 4).
- **Pre-bundling premise check** — verifying milestone goal and deliverables before Stage 3 commits scope.
- **Adversarial review of designs** — applying discovery posture to a Stage 5 design draft before Engineering authorizes (in-bundle composition with the adversarial-reviewer instance).

NOT discovery-class work: rendering a decision (decision-class — `decision-discipline.md`); auditing an existing artifact for correctness (review-class — `review-discipline-principles.md`); validating implementation against acceptance criteria (QA-class — `release-process.md` § QA Checkpoint Framework); selecting among already-surfaced options (decision-class downstream of discovery).

### 1.2 Consumer scope

This framework applies to any discovery-producing agent. Current primary consumers:

- **Stage 5 spokes** (per `pipeline/stage-05-solutioning.md` Phase 0.5 + A1/A3/A4) — discovery is the dominant Stage 5 posture before specification drafting.
- **Stage 4 hub at Phase A0** (per `pipeline/stage-04-planning.md` currency check) — bundle-refresh trigger evaluation is discovery-class.
- **Stage 13 spoke** (per the audit-trail synthesis) — pattern-emergence detection across release boundaries.
- **`release-planner` Mode D / Phase A1 scope assessment** — naming what is in/out of scope is a discovery activity.
- **`pmo-skill-editor` Mode D audit + future discovery-audit modes** — surfacing what a skill spec assumes but does not name.
- **`pmo-qa-auditor`** — discovery-class gates surface ahead of the review-class gates.
- **Intake authoring (issue templates `improvement.yml` / `observation.yml`)** — `[ASSUMPTION – CONFIRM]` labeling at intake is discovery output.
- **Roadmap revision** (per `<OPERATOR_INSTANCE_ROADMAPS_PATH>/`) — §3 Identified Gaps with F9 case-classification is discovery output.

This file is the canonical source. Skill SKILL.md files cite this file as `applies_to:` when discovery is a load-bearing function. CLAUDE.md Universal Preferences activates this file workspace-wide.

### 1.3 What discovery is NOT

Five negative bounds (each maps to one anti-pattern in § 6):

- Discovery is NOT premature solutioning — surfacing options is the work; choosing among them is `decision-discipline.md`.
- Discovery is NOT downstream review — `review-discipline-principles.md` audits the artifact after it exists; discovery shapes what should exist before it does.
- Discovery is NOT decision-class output — discovery surfaces premises and gaps; decision selects after they are surfaced.
- Discovery without output is governance theater — surfacing questions without producing the 5 named outputs in § 4 leaves no artifact for downstream consumers.
- Discovery is NOT optional when scope is ambiguous — the activation triggers in § 3 fire as conditional rules, not as posture-by-preference.

---

## Section 2 — Posture

Discovery posture is the active stance the agent takes BEFORE drafting an artifact. Five named posture elements; each is independently verifiable in discovery output.

### 2.1 Premise interrogation

**Posture:** Treat every premise the upstream stage handed off as freshly suspect. Premises that survived prior stages may have decayed (currency drift), been subsumed (a sibling shipped a broader fix), or been contradicted by recent learnings.

**Operationalization:** Apply the C1/C2/C3 classification per `triage-design-rereview.md` § 3 (current / candidate-for-amendment / should-be-challenged) at every Stage 4 Phase A0 currency check and every Stage 5 Phase 0.5 re-review delta. C3 fires Tier 0 — Premise Rejection per `release/governance/release-process.md` Inter-Stage Feedback Protocol.

**Distinction from review:** Premise interrogation asks "should this be?" not "is this correctly stated?" — the premise may be flawlessly articulated and still wrong.

### 2.2 Gap surfacing

**Posture:** Name what is missing — from a framework, intake, change matrix, or roadmap — rather than working around the gap silently.

**Operationalization:** Apply the F9 4-case diagnostic per [`initiative-roadmap-framework.md`](../standards/initiative-roadmap-framework.md) §7.4:

| Case | Signal | Routing |
|---|---|---|
| (a) work doesn't exist | nothing in the backlog covers the gap | file intake (`improvement.yml` or `observation.yml`) |
| (b) work exists but isn't mapped | issue exists but doesn't surface to the framework | fix the mapping (label, milestone, cross-ref) |
| (c) work exists unbundled | approved issue isn't in a milestone | bundle into next-appropriate milestone (Stage 3) |
| (d) already shipped | a closed issue already addressed the gap | mark contribution to outcome + fix mapping |

**Distinction from review:** Gap surfacing asks "what's missing?" not "what's wrong with what's here?" — surface validation answers a different question.

### 2.3 Assumption auditing

**Posture:** Every factual claim and every premise carries one of the 5 evidence-quality labels per CLAUDE.md Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. Unlabeled claims are the auditor's signal that discovery posture was not applied.

**Operationalization:** At authoring time, every claim labels itself; at review time (the `[verify-before-recommend]` gate), every `[ASSUMPTION – CONFIRM]` is verified against the canonical source before action.

**Distinction from decision:** Assumption auditing asks "what are we assuming?" not "what should we choose?" — surfacing the assumption set is upstream of selecting among options.

### 2.4 Scope-cleavage identification

**Posture:** Before bundling N items, before authoring an N-line spec, before drafting a release plan — name where the work naturally splits.

**Operationalization:** Apply the N-1 internal edges criterion per `review-discipline-principles.md` § 1 rule 14 inverted for discovery: where cohesion is weakest, scope cleaves. Surface the cleavage lines as discovery output for downstream Stage 4 / Stage 6 to consume (1→N fission operates on visible cleavages).

**Distinction from decision:** Scope-cleavage identification surfaces the split-points; the decision to split (or not) is downstream `decision-discipline.md` territory.

### 2.5 Knowability assessment

**Posture:** Distinguish three states for every named gap:

| State | Meaning | Downstream routing |
|---|---|---|
| **Knowable now** | The answer exists in the workspace; we just haven't fetched it | `[verify-before-recommend]` — fetch the canonical source |
| **Knowable later** | The answer requires work we haven't done | spike / time-boxed investigation / Stage 5 design decision |
| **Knowable only by operating** | The answer requires production data we don't yet have | reversibility-protocol MODERATE/HIGH-confidence tier; ship and observe |

**Operationalization:** Every entry in the open-question register (§ 4.1) carries one of the three knowability states.

**Distinction from QA:** Knowability assessment asks "can we know?" not "did we verify?" — verification presumes the answer is knowable.

---

## Section 3 — Activation Triggers

Discovery fires conditionally — when the trigger conditions below evaluate true. Activation is the workspace-global posture per CLAUDE.md Universal Preferences (D-DiscoveryActivationModel resolution: universal-preference clause); the conditional triggers below identify the discrete activity boundaries.

### 3.1 Stage-entry boundaries (always-fires)

Discovery activity fires at every stage-entry boundary where premise currency is load-bearing:

- **Triage → Design (Stage 2 → Stage 4):** Re-review per `triage-design-rereview.md` § 6 — D1/D2/D3 currency checks. C3 classifications trigger Tier 0 — Premise Rejection.
- **Stage 4 Phase A0:** Bundle-refresh currency check per `release/governance/release-process.md` § A7 — T1/T2/T3 trigger evaluation; non-zero triggers route to amend / re-bundle / defer / no-op.
- **Stage 5 Phase 0.5:** Re-Review Delta per `triage-design-rereview.md` § 6 when Stage 4 re-review predates Stage 5 entry by >7 days OR Stage 5 A3 blast radius exposes new context.
- **Stage 12 Phase A.5:** Main-divergence pre-check per `release/governance/release-process.md` Stage 12 — detect new context committed to main since release-branch base.

Trigger condition: **the boundary is being crossed for an in-scope issue.** Operator override allowed with documented rationale; silent skipping is a discipline failure.

### 3.2 Scope-inflection contexts (conditional)

Discovery activity fires when scope shape may be changing:

- **Pre-bundling at Stage 3:** Before a Milestone is created (or a new-track A6 placement rationale is drafted), discovery posture interrogates the proposed scope.
- **Pre-roadmap-revision:** Before a roadmap is amended (per `<OPERATOR_INSTANCE_ROADMAPS_PATH>/` event-bound cadence or 90-day staleness), discovery surfaces gaps via F9.
- **Pre-skill-editor edit at Mode A:** Before a SKILL.md edit ships, discovery surfaces what the spec assumes but does not name.

Trigger condition: **scope mutation is proposed.** The discovery output is the input to the decision-class output that authorizes the mutation.

### 3.3 Post-event contexts (conditional)

Discovery activity fires after events that imply premises may have decayed:

- **Post-failure:** After a QC1/QC2/QC3/QC4 gate fails, before remediation drafts; discovery surfaces whether the failure exposed a premise problem (Tier 0 candidate) or a localized defect (Tier 1/2/3).
- **Post-surprise:** After a Stage 13 self-learnings triple (`surprise` / `would-change` / `watch-for`) — surprise is the canonical post-event discovery trigger.
- **Post-correction:** After an operator correction (per `projects/_config/CORRECTIONS.md`), discovery interrogates whether the correction surfaces a class-potential pattern (observation log emergence rule).

Trigger condition: **an event has happened that may invalidate a prior premise.** The discovery output names which premises require re-review.

### 3.4 Intake-authoring (conditional)

Discovery activity fires at intake-authoring time:

- **`improvement.yml`:** Every required field is a discovery prompt — Evidence (`[SOURCE]`-labeled), Acceptance Criteria (knowable-now), Risks (`[ASSUMPTION – CONFIRM]` labels), Dependencies (named cleavage points).
- **`observation.yml`:** Three fields — what is missing, what good looks like, which file/section — are pure discovery output.

Trigger condition: **an intake ticket is being authored.** The template fields are the discovery scaffolding.

---

## Section 4 — Output Contract

A discovery activity produces 5 named outputs (per D-OutputContract resolution: 5-output contract). Each output traces to an existing pipeline-instance owner so downstream consumers know where to read it.

### 4.1 Output 1 — Open-question register

**Definition:** A list of questions the upstream-stage handoff did not answer but downstream stages need answered before they can proceed.

**Format:** Each entry — question text + addressed-to (which stage / role / artifact) + knowability state (per § 2.5) + blocking-or-non-blocking flag.

**Lives where:** In the discovery output artifact (Stage 5 sub-task comment, intake ticket body, roadmap revision draft). Blocking entries surface as Tier 0/1/2 escalations per `release/governance/release-process.md` Inter-Stage Feedback Protocol.

### 4.2 Output 2 — Gaps with F9 case-classification

**Definition:** A list of gaps named in the framework / intake / change matrix / roadmap surface being interrogated, each classified per the F9 4-case diagnostic in § 2.2.

**Format:** Each entry — gap description + case (a/b/c/d) + routing (file intake / fix mapping / bundle / mark contribution) + evidence label.

**Lives where:** §3 Identified Gaps in roadmap files; Affected Files / Risks sections in intake tickets; Phase A4 design specification drafting in Stage 5 sub-task comments.

### 4.3 Output 3 — Scope-cleavage points

**Definition:** A list of natural split-points in the scope being interrogated, named with the cleavage criterion (cohesion edge, dependency boundary, file-contention surface, audience-shift, lifecycle-mismatch, etc.).

**Format:** Each entry — cleavage point + criterion + recommended fission-or-keep decision (Stage 4 D-C input).

**Lives where:** Stage 4 plan Phase A2 dependency-graph construction;  fission protocol input; release-planner Mode B Implementation Sequence rationale.

### 4.4 Output 4 — Premises requiring re-review

**Definition:** A list of premises from upstream stages that discovery activity flagged for re-review, classified per `triage-design-rereview.md` § 3 (C1 / C2 / C3) with PT-type for any C3 (PT-1 stale assumption / PT-2 subsumption / PT-3 best-practices conflict / PT-4 learnings contradiction).

**Format:** Each entry — premise text + source (upstream sub-task / file / governance section) + C-classification + PT-type-if-C3 + recommended action (continue / amend / Tier 0 escalation).

**Lives where:** Stage 5 Phase 0.5 re-review section in sub-task comments; Tier 0 escalation blocks on parent issues; release plan deviation log entries.

### 4.5 Output 5 — Evidence-quality labels

**Definition:** Every factual claim in the discovery output, AND every premise the discovery activity is consuming, carries one of the 5 evidence-quality labels per CLAUDE.md Universal Preferences.

**Format:** Inline labels in the prose — `[SOURCE: file:line]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. `[ASSUMPTION – CONFIRM]` entries route to Output 1 (open-question register).

**Lives where:** Inline in every discovery output document. Verification of `[ASSUMPTION – CONFIRM]` against canonical sources happens at `[verify-before-recommend]` time.

### 4.6 Omission semantics

When discovery activity fires but produces zero entries in any of the 5 outputs, the discovery output explicitly states "zero entries — verified by [method]" — silent omission is governance theater per § 6 anti-pattern 4. The non-ceremony pattern (decision-discipline.md § 5 G2) applies: if a discovery activity is exempt from producing an output, it OMITS the output section entirely; if the output applies and surfaces zero items, the empty result is explicit and audited.

---

## Section 5 — Composition with Sibling Meta-Protocols

Discovery composes with — does not replace — the four sibling meta-protocols. Each composition direction is named below.

### 5.1 Composition with `decision-discipline.md`

**Direction:** Discovery is upstream of decision.

**Mechanism:** Discovery outputs (Output 1 open-question register; Output 3 scope-cleavage points; Output 4 premises requiring re-review) are the input that decision-class work consumes when applying the Three Mechanisms (Localization Check / Opposing View / Pattern Cache Scan). A Decision Briefing missing prerequisite discovery output (e.g., D-class decision rendered without the question register that surfaced the alternatives) is a discipline failure — the decision is operating in absence of the discovery posture.

**Cross-reference rule:** A decision-class output that consumed discovery output cites the discovery artifact (sub-task comment, intake ticket body, roadmap §3) in its Localization Check Evidence subsection.

### 5.2 Composition with `review-discipline-principles.md`

**Direction:** Discovery is upstream of review. Temporal-anchor distinction (per D-BoundaryWithReview resolution: temporal-anchor distinction).

**Mechanism:** Discovery fires BEFORE the artifact exists (asks *"what should this be?"*); review fires AFTER the artifact exists (asks *"is this correct?"*). Same architectural pattern as Tier 0 (stage ENTRY) vs Tier 1/2/3 (stage EXECUTION) in `release/governance/release-process.md` Inter-Stage Feedback Protocol.

**Cross-reference rule:** A review-class output (audit, QA finding, retrospective) that detects a gap which discovery posture would have surfaced cites discovery-discipline.md as the upstream gate that failed to fire. Conversely, a discovery activity that produces an artifact for downstream review names the review-class consumer (Stage 7 DT, Stage 8 QA, Stage 13 audit) and the dimensions review will validate.

### 5.3 Composition with `failure-mode-standard.md`

**Direction:** Discovery surfaces failure modes ahead of authoring.

**Mechanism:** Skill SKILL.md `## Domain-Specific Failure Modes` sections are authored by surfacing what fails through discovery posture (premise interrogation, gap surfacing, assumption auditing). The 5-field template (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) is the structured artifact discovery produces in the failure-mode authoring context.

**Cross-reference rule:** Skill-authoring discovery activity (per `pmo-skill-editor` Mode A / Mode C creation) cites this file as the posture source; the resulting `## Domain-Specific Failure Modes` section is discovery output in the failure-mode-standard format.

### 5.4 Composition with `reversibility-protocol.md`

**Direction:** Discovery may shift reversibility-tier classification.

**Mechanism:** Discovery activity can surface new evidence (Output 5 evidence-quality labels; Output 4 premise re-review) that changes the reversibility tier of a previously-classified decision. A decision originally tiered CHEAP may shift to MODERATE when discovery reveals a previously-unsurfaced downstream consumer (broader stakeholder impact); a decision tiered IRREVERSIBLE may shift to EXPENSIVE when discovery identifies a heretofore-unmapped reversal mechanism.

**Cross-reference rule:** A reversibility tier change driven by discovery output cites the discovery artifact + the new evidence label that triggered the shift. The G4 gate evaluates whether the cited evidence is sufficient for the proposed tier change.

---

## Section 6 — Anti-Patterns

Four discovery-specific anti-patterns. Each is the inverse of one § 2 posture element OR one § 5 composition rule.

### 6.1 Anti-pattern — Premature solutioning

**Signature:** A discovery activity terminates by drafting an implementation spec before producing Outputs 1-5. The agent reached for "what should we build?" before completing "what don't we know?" / "what's missing?"

**Conditional:** do NOT draft a specification when premise currency has not been verified, because solutioning closed-form before discovery completes locks-in premises that may decay or be subsumed.

**Root cause:** Time pressure + bias toward action. The agent treats discovery as a tax on getting to specification; principal-grade treats discovery as the substrate specification depends on.

**Mitigation:** When the impulse to draft a spec surfaces, check whether all 5 outputs are populated (or explicitly OMITTED per § 4.6). Empty outputs that should have entries are the stop signal.

### 6.2 Anti-pattern — Review-as-discovery

**Signature:** A surface-validation finding (the file references the wrong section; the AC list has 7 items but only 5 are testable) is framed as discovery output. The activity asks *"is this correct?"* about an existing artifact and reports the answer as if it shaped what should exist.

**Conditional:** do NOT route a review-class finding to a discovery-output consumer (Stage 4 Phase A0 currency check, Stage 5 Phase 0.5 re-review) when the finding concerns artifact correctness rather than premise validity, because the consumer expects pre-artifact shaping signal and receives post-artifact validation noise.

**Root cause:** Conflation of post-artifact validation with pre-artifact shaping. The temporal-anchor distinction in § 5.2 is the discipline fence.

**Mitigation:** Before producing discovery output, name the temporal anchor — does this fire BEFORE the artifact exists (discovery) or AFTER (review)? Route correctly.

### 6.3 Anti-pattern — Decision-as-discovery

**Signature:** A Decision Briefing is produced with a single recommended option and no alternatives surfaced. The activity renders a decision and labels the rendering as discovery output.

**Conditional:** do NOT produce a single-option recommendation labeled as discovery output when alternative premises remain un-interrogated, because the decision is operating in absence of the discovery posture that should have surfaced the alternatives.

**Root cause:** Convergence bias. The agent arrived at an answer and back-rationalized the discovery activity to support it.

**Mitigation:** Discovery output enumerates options (§ 4.3 scope-cleavage points; § 4.1 open questions); decision selects among them (Three Mechanisms per `decision-discipline.md` § 2). The two outputs come from two activities — separate them in time and in artifact.

### 6.4 Anti-pattern — Discovery-without-output

**Signature:** A discovery activity fires (premise interrogation runs, gap analysis performed, assumption audit conducted) but produces no durable artifact. The activity happened in the agent's reasoning and disappeared with the session.

**Conditional:** do NOT conclude a discovery activity without producing the 5 named outputs (§ 4) in a durable artifact (sub-task comment, intake ticket body, roadmap revision draft), because discovery whose output is not externalized cannot be consumed by downstream stages and cannot be audited.

**Root cause:** Files-are-the-memory principle (CLAUDE.md Universal Preferences) violated. Discovery in-session reasoning is ephemeral; durable artifact is the only persistence layer.

**Mitigation:** Every discovery activity terminates by writing the 5 outputs to a named durable artifact. § 4.6 omission semantics applies — empty outputs are explicit, not silent.

---

## Section 7 — Consumer Binding

The protocol applies workspace-wide per CLAUDE.md Universal Preferences activation clause. Specific pipeline-instance owners consume discovery output at the surfaces below.

### 7.1 Stage 4 Phase A0 — Bundle currency check

**Discovery activity:** Re-evaluate T1 (Approved-queue depth) / T2 (Priority shift) / T3 (Dependency-state change) trigger conditions since Stage 3 bundle creation. Each fired trigger is a § 4.4 premise-requiring-re-review entry classified per the churn-budget threshold.

**Output consumed by:** Stage 4 spoke routing decision (amend / re-bundle / defer / no-op) per `release/governance/release-process.md` § A7.

**Failure mode if discovery posture not applied:** Stage 4 produces a plan against a stale bundle scope; Stage 5 surfaces the drift downstream at higher cost.

### 7.2 Stage 5 Phase 0.5 — Re-Review Delta

**Discovery activity:** Delta D2 (best-practice currency) + D3 (learnings contradictions) per `triage-design-rereview.md` § 6 when Stage 4 re-review predates Stage 5 entry by >7 days OR Stage 5 A3 blast radius exposes new context. C3 classifications fire Tier 0 — Premise Rejection.

**Output consumed by:** Stage 5 spoke design-specification drafting (Phase A4) OR Tier 0 escalation block per `release/governance/release-process.md` Inter-Stage Feedback Protocol.

**Failure mode if discovery posture not applied:** Specification drafted against a decayed premise; Engineering implements; Stage 7 DT or Stage 8 QA surfaces the gap at maximum remediation cost.

### 7.3 Stage 5 Phase A3 — Blast radius analysis

**Discovery activity:** Transitive dependency mapping via `release/tools/blast-radius.sh` per `protocols/blast-radius-protocol.md`. Output is a § 4.3 scope-cleavage map naming files newly exposed to the design's impact surface.

**Output consumed by:** Stage 5 spoke design specification (A4); Collective Review N-way consistency table (Output Contract § 6 in `release/governance/release-process.md`).

**Failure mode if discovery posture not applied:** Cross-file blast surfaces in Stage 12 Phase A.5 main-divergence pre-check (worst case: Stage 13 QC4 regression).

### 7.4 Stage 7 DT — Escape detection

**Discovery activity:** Search for "things the spec required that implementation missed" — the gap between AC and behavior. Each escape is a § 4.2 gap (case (b) work-exists-but-isn't-mapped: AC exists, implementation isn't mapped to it) or case (a) work-doesn't-exist (AC exists, no implementation present).

**Output consumed by:** Engineering remediation via `fix(dt):` commits per `pipeline/stage-07-dev-testing.md` DT↔Engineering Iteration Loop Protocol.

**Failure mode if discovery posture not applied:** Surface-level review pass; defects ship to Stage 8 QA or production.

### 7.5 Stage 8 QA — Boundary-condition testing

**Discovery activity:** Edge cases not explicitly in spec — the § 2.5 knowability assessment applied to AC coverage. Each boundary case is a § 4.1 open-question register entry (addressed-to: Engineering, knowability: knowable-by-testing).

**Output consumed by:** QA acceptance sign-off or rejection per `release/governance/release-process.md` Stage 8.

**Failure mode if discovery posture not applied:** AC met in the literal but boundary defects ship.

### 7.6 Stage 12 Phase A.5 — Main-divergence pre-check

**Discovery activity:** Detect new context committed to main since release-branch base. Each new commit is a § 4.4 premise-requiring-re-review entry (premise: "the base state we planned against is current").

**Output consumed by:** Stage 12 spoke merge decision (continue / escalate Tier 2 [SCOPE CHANGE]) per `release/governance/release-process.md` Stage 12 Phase A.5.

**Failure mode if discovery posture not applied:** Release branch merges against drifted main; conflict surfaces post-merge.

### 7.7 Stage 13 audit-trail synthesis

**Discovery activity:** Cross-release pattern detection — each `surprise` / `would-change` / `watch-for` triple is a § 4.4 premise-requiring-re-review entry surfaced across release boundaries. Patterns meeting auto-promotion predicate (≥3 events across ≥2 versions) become discovery output that decision-class work then consumes.

**Output consumed by:** `pipeline-event-log.md` synthesis runs per `pipeline-event-log-schema.md` § 11; auto-promoted-pattern Issues per § 11.5.

**Failure mode if discovery posture not applied:** Recurring class-defects ship multiple releases without surfacing the pattern.

### 7.8 Pattern-emergence at observation log

**Discovery activity:** Operator-correction observation log + emergence rule (N=2 same-(domain, theme) within 180 days) per `decision-discipline.md` § 4. Each pattern-emergence event is a § 4.4 premise-requiring-re-review entry that may shift workspace-wide rules.

**Output consumed by:** `memory/feedback_*.md` files promoted to CONFIRMED-PERMANENT status; rule-promotion ceremony per `decision-discipline.md`.

**Failure mode if discovery posture not applied:** Operator corrections repeat without crystallizing into rules; the same surface-level defect surfaces N+1 times.

### 7.9 F9 gap-analysis diagnostic at roadmap revision

**Discovery activity:** §3 Identified Gaps in roadmap files use the F9 4-case classification per § 2.2.

**Output consumed by:** Roadmap §4 Now/Next/Later sequencing; intake-creation routing.

**Failure mode if discovery posture not applied:** Roadmap §3 defaults to "file intake" without diagnostic; bundling and scope decisions operate without case-classification.

---

## Section 8 — Retrospective Validation

The discipline emerged from observing ≥9 concrete pipeline instances of discovery-class activity, six of which have shipped. The retrospective composition map below shows how each instance fits under the umbrella; the umbrella generalizes from the concrete instances rather than positing the discipline ahead of evidence.

### 8.1 Shipped concrete instances

| Instance | Shipped | Pipeline surface | Discovery output produced |
|---|---|---|---|
| Premise-interrogation at Triage→Design re-review | 2026-04-25 | Stage 2 / Stage 4 Phase A0 / Stage 5 Phase 0.5 | C1/C2/C3 classification per `triage-design-rereview.md` § 3; Tier 0 escalations |
| Adversarial-hub + Evidence-Grounding (R1) | shipped | Stage 5 Phase A canonicalization steps; Collective Review N-way table | R4 N-way consistency disagreements; evidence-grounding artifacts |
| Design-artifact discipline (Stage 5 + Stage 13) | shipped | Stage 5 Phase A6; Stage 13 G-CL6 | Tier-A activated design artifacts declared in release plan |
| Review Composition Framework | shipped | Cross-class composition rules | Adjacent-class boundary articulation (anchor for § 5.2 here) |
| Five-Function Spine | shipped | Workspace-wide architectural model | Spine-function classification per scope |
| Initiative-roadmap framework + F9 gap-analysis | shipped | `<OPERATOR_INSTANCE_ROADMAPS_PATH>/` §3 Identified Gaps | F9 4-case diagnostic — referenced verbatim in § 2.2 |
| Engagement charter / research brief | shipped | Pre-engagement intake | Charter scope + research questions |
| Stage 13 self-learnings capture | shipped | Stage 13 audit-trail synthesis | `surprise` / `would-change` / `watch-for` triple; cross-release pattern detection |
| Release-process fitness audit | shipped | Audit instance | Dimensional blind spots surfaced |

### 8.2 In-flight and forward-reference instances

| Instance | State | Pipeline surface | Composition role |
|---|---|---|---|
| Ticket fission (1→N decomposition) | IN-BUNDLE | Stage 4 Planning / Stage 6 Engineering | Sister discovery instance — discovery produces the cleavage map (§ 4.3) that fission operates on |
| Adversarial reviewer @ Stage 5 | IN-BUNDLE | Stage 5 Phase A4 | Discovery posture applied to a Stage 5 design draft (review-class skill consuming this protocol) |
| QA REJECT re-scope path | OPEN | Stage 8 → Stage 5 return | Post-rejection discovery — re-running premise interrogation when QA exposes a premise problem |
| Knowledge Architecture initiative | OPEN | Workspace-wide K1-K5 placement | Adjacent discipline — K1/K3 placement is itself a discovery output (where should this knowledge live?) |

### 8.3 Generalization confidence

**HIGH confidence on the existence of the gap** — 13 concrete instances surveyed across ≥7 distinct pipeline surfaces (9 shipped in §8.1 + 4 in-flight/forward-reference in §8.2); nine cited as composition anchors in this doc. The parts-without-whole pattern was named verbatim in 's own scope statement.

**MEDIUM confidence on the activation model** — universal-preference clause vs. per-stage triggers were both viable per D-DiscoveryActivationModel; the universal-preference option was selected because all four siblings use that pattern. Per-stage triggers can be added LATER via additive composition without breaking the universal-preference clause.

**HIGH confidence on the temporal-anchor distinction (§ 5.2)** — the Tier 0 / Tier 1-3 architectural pattern in `release/governance/release-process.md` already articulates this exact distinction for inter-stage feedback; discovery-discipline inherits the same architectural pattern at the activity-class level.

---

## Cutover

Applies to all discovery activity going forward. The release that shipped this protocol is exempt — a protocol cannot fire on its own discovery activity without creating a reflexive-pipeline loop; that release's own Stage 5 spokes used pre-cutover ad-hoc discovery patterns. Releases already in flight when the protocol shipped are likewise grandfathered.

---

## See also

- `../disciplines/decision-discipline.md` — decision-class output discipline (downstream of discovery)
- `../disciplines/review-discipline-principles.md` — review-class output discipline (temporal-anchor distinction § 5.2)
- `../standards/failure-mode-standard.md` — failure-mode authoring template (discovery surfaces failure modes ahead of authoring § 5.3)
- `../specs/reversibility-protocol.md` — reversibility tier classification (discovery may shift tier § 5.4)
- `release/references/standards/triage-design-rereview.md` — premise-interrogation operationalization (§ 6 currency-check schema; § 9 Tier 0 escalation template)
- `../standards/initiative-roadmap-framework.md` §7.4 — F9 4-case gap-analysis diagnostic source (referenced in § 2.2; codified in the framework, instances operator-local)
- `release/governance/release-process.md` — Inter-Stage Feedback Protocol (Tier 0 / Tier 1-3 architectural pattern referenced in § 5.2)
- `release/references/pipeline/stage-05-solutioning.md` — Phase 0.5 re-review delta (canonical discovery activity instance — § 7.2)
