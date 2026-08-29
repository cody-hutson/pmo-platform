# Gate Checklists

## Purpose

Structured reference for gate type selection, checklist generation, and go-live readiness assessment across delivery methodologies. Consumed by delivery-engine (Modes C, F) for gate calibration and checkpoint design.

---

## 1. Five Gate Types

Every gate in any delivery approach classifies into exactly one of five types. Selection depends on the decision being made, not the methodology being used.

### Gate Type Definitions

| Gate Type | Purpose | Authority | Trigger Condition | Mechanism | Output |
|-----------|---------|-----------|-------------------|-----------|--------|
| **Phase Gate** | Project-altitude go/kill/hold/recycle investment decision | Steering Committee / LPM | End of lifecycle phase or PI boundary | Binary pass/fail blocking progression | Go / Kill / Hold / Recycle decision |
| **Quality Gate** | Work-item fitness-for-progression check | Technical Leads / Developers | Work item requests transition (e.g., "Ready" to "In Progress", "Done" claim) | Binary pass/fail on quality measures (DoR, DoD) | Pass (transition allowed) / Fail (item returned) |
| **Flow Gate** | Capacity-constrained entry/exit controlling WIP and cycle time | SDM + WIP limits (policy-driven) | Item arrives at capacity-constrained column or commitment point | Automatic per policy; no human decision required when WIP is at limit | Pull allowed / Blocked (WIP full) |
| **Approval Gate** | Stakeholder/authority sign-off before release or deployment | Business Owner / CAB / Change Authority | Release candidate ready; deployment window reached | Formal sign-off requirement; documented authorization | Approved / Rejected / Conditional |
| **Hypothesis Gate** | Evidence-driven continue/change/stop on investment thesis | Epic Owner + LPM | PI boundary or measurement milestone | Data-driven portfolio decision against pre-defined success criteria | Persevere / Pivot / Cancel |

### Gate Type Selection Decision Model

Use this decision tree to select the correct gate type:

1. **Is this a strategic investment decision (fund/kill/hold)?** --> Phase Gate
2. **Is this a work item readiness or completion check?** --> Quality Gate
3. **Is this a capacity constraint enforcement?** --> Flow Gate
4. **Is this a stakeholder authorization for release/deployment?** --> Approval Gate
5. **Is this a hypothesis validation against evidence?** --> Hypothesis Gate

If the answer is unclear, default to the gate type matching the decision authority level: team-level = Quality Gate, project-level = Phase or Approval Gate, portfolio-level = Hypothesis Gate.

---

## 2. Per-Gate-Type Checklist Templates

### 2.1 Phase Gate Checklist

**When:** End of lifecycle phase, PI boundary, or major milestone.
**Who:** Steering Committee, Portfolio Manager, or delegated authority per governance tier.

| # | Assessment Item | Evidence Required | Pass Criteria |
|---|----------------|-------------------|---------------|
| 1 | Deliverables from current phase complete | Artifact inventory with completion status | All mandatory deliverables accepted |
| 2 | Quality criteria met for phase | Quality metrics report (defect counts, test results) | Zero critical defects; high-severity defects within tolerance |
| 3 | Budget within tolerance | EVM report or burn rate analysis | CPI/SPI within defined tolerance band |
| 4 | Schedule within tolerance | Milestone tracker, velocity/throughput data | Critical path items on schedule or recovery plan approved |
| 5 | Risks assessed and mitigated | Updated RAID log with all items reviewed | No unmitigated critical risks; all high risks have response plans |
| 6 | Stakeholder alignment confirmed | Sign-off log or confidence vote results | Required stakeholders have approved |
| 7 | Next phase plan ready | Plan document with resource commitments | Resources confirmed; plan reviewed and approved |
| 8 | Lessons from current phase captured | Retrospective output or lessons learned log | Lessons documented; actionable items assigned |

**Decision options:** Go (proceed to next phase) / Kill (terminate project) / Hold (pause pending resolution) / Recycle (redo current phase with corrections)

### 2.2 Quality Gate Checklist

**When:** Work item requests state transition.
**Who:** Technical Leads, Developers, QA (team-level authority).

#### Definition of Ready (DoR) -- Entry to Execution

| # | Criterion | Pass Criteria |
|---|-----------|---------------|
| 1 | Acceptance criteria defined | Specific, testable criteria written in Given/When/Then or equivalent |
| 2 | Dependencies identified | All dependencies mapped; none in "blocked" state |
| 3 | Sized/estimated | The work is bounded by one of: a size estimate (story points or T-shirt); a time-box; or a scope-box -- stated acceptance criteria plus an explicit out-of-scope boundary. Stated scope with no out-of-scope boundary is not a bound and does not pass. |
| 4 | Design reviewed (if applicable) | Technical approach agreed; no open architecture questions |
| 5 | Test approach identified | Test strategy clear; test data available or plan to create |
| 6 | Small enough | Meets INVEST "Small" criterion; under a time-boxed approach it also fits one iteration |

**Note -- bounding forms.** Criterion 3 tests that the work is *bounded*, not that a human estimated it. A size estimate, a time-box, and a scope-box are three forms of one control. A scope-box is a bound only when it carries **both** stated acceptance criteria **and** an explicit out-of-scope boundary -- a stated line of the form "Out of scope: the upstream API contract; migration of existing records." Scope with no out-of-scope boundary is unbounded and fails criterion 3. Criterion 6 is the separate *smallness* test and stays INVEST-anchored: the "fits one iteration" clause applies under a time-boxed approach, where an iteration exists to fit inside; an item bounded by a scope-box is judged small by INVEST alone, never by its own scope statement (an item always fits the scope it declares, so that would test nothing). An item admitted on a scope-box carries no estimate of record, so no calibration admission row is emitted for it at DoR exit. **Vocabulary:** the platform glossary defines TIME-BOXED / SCOPE-BOXED / DEPLOYMENT-BOXED at the *container* tier (Sprint / Milestone / Release); "time-box" and "scope-box" are used here at the *work-item* tier for the same bounding senses -- the same distinction, one altitude down.

**Axis-1 advance this PASS authorizes.** A DoR exit `PASS` / `CONDITIONAL PASS` authorizes the Work Item Axis-1 advance `WorkItem-backlog → WorkItem-ready`, projected by the label row `work-status: ready`. The advance is **emitted, not applied** -- delivery-engine emits the transition and Tracker Manager performs the validated write; the label is **named, never applied** by this skill. The machine and its qualifying evidence are owned by `../../../../core/standards/entity-lifecycle-protocol.md` §3.10. **This is a footer on the template, not a criterion** -- the checklist items above are unchanged, and the advance is downstream of the verdict rather than an input to it.

#### Definition of Done (DoD) -- Exit from Execution

| # | Criterion | Pass Criteria |
|---|-----------|---------------|
| 1 | Acceptance criteria met | All criteria verified with evidence |
| 2 | Code reviewed | Peer review complete; no unresolved comments |
| 3 | Tests passing | Unit tests, integration tests per pyramid; >80% coverage on new code |
| 4 | No regression | Automated regression suite green |
| 5 | Documentation updated | API docs, user docs, runbooks updated as applicable |
| 6 | Deployable | Artifact builds cleanly; deployment pipeline green |
| 7 | PO accepted | Product Owner has inspected and accepted the increment |

**Axis-1 advance this PASS authorizes.** A DoD exit `PASS` / `CONDITIONAL PASS` authorizes the Work Item Axis-1 advance `WorkItem-in-review → WorkItem-done`, projected by the label row `work-status: done` (the preceding `WorkItem-in-progress → WorkItem-in-review` advance fires at gate-open, when the completion claim is raised). `WorkItem-done` is **terminal** in §3.10, so this advance carries the evidence bar of a terminal action. The advance is **emitted, not applied** -- delivery-engine emits the transition and Tracker Manager performs the validated write; the label is **named, never applied** by this skill. **This is a footer on the template, not a criterion** -- the checklist items above are unchanged.

### 2.3 Flow Gate Checklist

**When:** Work item arrives at capacity-constrained boundary (Commitment Point, column with WIP limit).
**Who:** Policy-driven; SDM or team enforces. No human decision when limits are clear.

| # | Assessment Item | Pass Criteria |
|---|----------------|---------------|
| 1 | WIP limit not exceeded | Column/swimlane WIP < limit; if at limit, pull is blocked |
| 2 | Item meets column entry criteria | Explicit policies for the column are satisfied |
| 3 | Upstream work complete | Previous column's exit criteria met (no partial transitions) |
| 4 | Pull signal present | Downstream capacity available; item is highest-priority eligible |

**Note:** Flow gates are the only gate type that can be fully automated. They do not require human judgment when policies are explicit and WIP limits are enforced.

### 2.4 Approval Gate Checklist

**When:** Release candidate ready for deployment; change request at approval threshold.
**Who:** Business Owner, CAB, Change Authority, or designated approver.

| # | Assessment Item | Evidence Required | Pass Criteria |
|---|----------------|-------------------|---------------|
| 1 | All quality gates passed | Test reports, DoD evidence | No bypassed quality gates |
| 2 | Deployment plan documented | Deployment runbook with steps, timing, responsibilities | Plan reviewed by ops team |
| 3 | Rollback plan documented and tested | Rollback procedure with tested restore point | Rollback validated in staging or equivalent |
| 4 | Communication plan executed | Stakeholder notification log | All affected parties notified per plan |
| 5 | Training/enablement complete | Training completion records | Required training delivered and confirmed |
| 6 | Security review passed | Security scan results, penetration test (if applicable) | No critical/high vulnerabilities unresolved |
| 7 | Change window confirmed | Deployment schedule with maintenance window | Window approved; conflict-free |
| 8 | Approver sign-off obtained | Formal sign-off record | All required approvers have signed |

### 2.5 Hypothesis Gate Checklist

**When:** PI boundary, measurement milestone, or Epic review point.
**Who:** Epic Owner + LPM; Portfolio governance.

| # | Assessment Item | Evidence Required | Pass Criteria |
|---|----------------|-------------------|---------------|
| 1 | Hypothesis clearly stated | Original hypothesis from Lean Business Case | Hypothesis is testable and measurable |
| 2 | Leading indicators measured | Dashboard or measurement report | Data collected per measurement plan |
| 3 | Evidence assessed against success criteria | Analysis comparing actuals to targets | Clear signal: meeting/exceeding or falling short |
| 4 | Investment to date quantified | Budget actuals | Spend within guardrails |
| 5 | Remaining investment estimated | Forecast to completion | Remaining cost justified by expected value |
| 6 | Alternative options evaluated | Options analysis (continue, pivot, cancel) | At least 2 alternatives with trade-offs documented |
| 7 | Decision recommendation prepared | Recommendation with rationale | Clear Persevere / Pivot / Cancel recommendation |

---

## 3. Go-Live Readiness Assessment

Nine non-negotiable dimensions for deployment readiness. Each dimension receives a RAG score. Overall go-live requires: zero Red dimensions, maximum 2 Amber dimensions (with documented mitigation plans).

### 3.1 Nine-Dimension Assessment

| # | Dimension | Green Criteria | Amber Criteria | Red Criteria |
|---|-----------|---------------|----------------|-------------|
| 1 | **Technical Readiness** | Performance validated against benchmarks; integration verified end-to-end; architecture stable | Minor performance gaps with known workarounds; integration verified with exceptions documented | Performance not validated; integration failures unresolved; architecture unstable |
| 2 | **Business Readiness** | Training complete for all user groups; comms sent; change management plan executed | Training >80% complete; comms drafted but not all sent; CM plan in progress | Training <80%; no comms plan; CM not started |
| 3 | **Operational Readiness** | Runbooks documented and reviewed; monitoring active with alerts configured; support team briefed and staffed | Runbooks drafted but not reviewed; monitoring partially configured; support team identified | No runbooks; no monitoring; support team not identified |
| 4 | **Test Quality** | >95% critical tests passing; zero critical/high open defects; regression suite green | >90% critical tests passing; zero critical defects; high defects have approved workarounds | <90% critical tests passing; or any open critical defects |
| 5 | **Compliance** | Regulatory clearance obtained; security scan passed; audit trail complete and verified | Security scan passed with accepted exceptions; audit trail complete | Regulatory clearance pending; security vulnerabilities unresolved |
| 6 | **Rollback Capability** | Rollback plan documented, tested, and validated; triggers defined with quantitative thresholds | Rollback plan documented but not tested; triggers defined | No rollback plan; or plan exists but untested and no triggers |
| 7 | **Stakeholder Readiness** | UAT sign-off obtained from all required stakeholders; training validated; go-live comms approved | UAT sign-off from primary stakeholders; training delivered; comms drafted | UAT incomplete; no stakeholder sign-off |
| 8 | **Documentation** | Release notes published; operational docs complete; support guides available | Release notes drafted; operational docs >80% complete | No release notes; operational docs incomplete |
| 9 | **Risk Assessment** | All risks ROAM'd or mitigated; residual risk formally accepted by sponsor; no unowned risks | All risks assessed; most mitigated; sponsor aware of residual risk | Unassessed risks; unowned risks; sponsor not briefed |

### 3.2 Gates That Never Compress

Even in emergency or time-pressure scenarios, these six gates are non-negotiable:

1. **Security review** -- vulnerabilities in production create unbounded liability
2. **Data integrity verification** -- data corruption is often irreversible
3. **Backup before deployment** -- enables rollback; without it, failure is permanent
4. **Rollback plan existence** -- "hope it works" is not a deployment strategy
5. **Senior engineer code review** -- minimum one qualified reviewer on all production changes
6. **Post-deployment monitoring configured** -- blind deployment prevents detection

### 3.3 Quantitative Rollback Triggers

Define these thresholds before deployment; monitor continuously post-deployment:

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Error rate | >5% above pre-deployment baseline | Initiate rollback evaluation |
| Response time | >10% degradation from baseline | Initiate rollback evaluation |
| Critical business function | Unavailable | Immediate rollback |
| Data corruption | Any detected | Immediate rollback; halt all writes |

### 3.4 Hotfix Frequency as Quality Health Metric

Post-deployment monitoring should track hotfix frequency as a leading indicator of release quality:

| Threshold | Status | Interpretation | Action |
|-----------|--------|---------------|--------|
| <1 hotfix/month | Healthy | Normal operations | Continue monitoring |
| 2-3 hotfixes/month | Warning | Process or quality gap emerging | Root cause analysis; review test coverage |
| Weekly or more | Alarm | Systemic quality failure | Stop feature work; convene quality review |
| Hotfix-to-release ratio >5% | Target breach | Release quality problem | Review and tighten go-live gates |

---

## 4. Risk-Based Gate Calibration

Gate rigor scales with project risk profile. Applying identical gates to all projects regardless of risk is the "Context-Free Gates" anti-pattern.

### 4.1 Three-Tier Calibration Model

| Risk Tier | Gate Count | Reporting Cadence | Approval Authority | Change Control | Example |
|-----------|-----------|-------------------|-------------------|----------------|---------|
| **High-risk** | 8+ gates (all five types active) | Weekly | Executive + Compliance | Formal CCB with full impact assessment | Enterprise ERP implementation; regulatory system |
| **Medium-risk** | 4-6 gates (phase + quality + approval) | Biweekly | Steering Committee | Standard process with documented rationale | Cross-functional feature initiative; vendor integration |
| **Low-risk** | 2 gates (start + close; quality automated) | Monthly | PM-level authority | Lightweight / CI/CD automated | Internal tool enhancement; single-team feature |

### 4.2 Six Calibration Factors

Assess each factor to determine the appropriate risk tier:

| Factor | High-Risk Signal | Low-Risk Signal |
|--------|-----------------|-----------------|
| **Financial exposure** | >$500K investment; budget overrun impacts P&L | <$50K; contained within team budget |
| **Regulatory impact** | Compliance-mandated; audit-visible; penalties for failure | No regulatory implications |
| **Organizational complexity** | Cross-BU; multiple teams; external vendors | Single team; single department |
| **Technical novelty** | New technology; unproven architecture; no team experience | Well-understood stack; team has delivered similar |
| **Customer impact** | Customer-facing; revenue-impacting; SLA-governed | Internal-only; no customer visibility |
| **Strategic importance** | Tied to OKRs; board-visible; competitive differentiator | Operational improvement; maintenance |

**Scoring rule:** If ANY factor is High-Risk, the project requires at minimum Medium-risk governance. If 3+ factors are High-Risk, apply High-risk governance.

### 4.3 Risk-Weighted Gate Readiness Scoring

Not all gate checklist items are equal. Weight items by failure impact to prevent low-risk completions from masking high-risk gaps:

**Formula:** Gate Readiness Score = SUM(item_weight x completion_status) / SUM(item_weight)

| Weight | Criteria |
|--------|----------|
| 3 (Critical) | Business criticality, regulatory exposure, data integrity |
| 2 (Important) | Customer impact, technical risk, integration dependencies |
| 1 (Standard) | Documentation, communication, training |

**Gate eligibility threshold:** >= 0.85 (configurable per organization). Completing ten weight-1 items does not compensate for one incomplete weight-3 item.

---

## 5. Methodology Variation Table

How gates operate across delivery approaches:

| Approach | Active Gate Types | Primary Gate Mechanism | Authority Model | Gate Cadence |
|----------|------------------|----------------------|-----------------|-------------|
| **Scrum** | Quality (DoR, DoD) | Team-owned DoR/DoD; Sprint Review is NOT a gate | PO (what), Developers (how), SM (process) | Per Sprint (quality); Sprint Review is checkpoint only |
| **Kanban** | Flow, Quality (column policies) | WIP limits + explicit column policies; Commitment Point and Delivery Point | Policy-driven; SDM manages capacity | Continuous; seven cadences replace batch gates |
| **Waterfall** | Phase, Approval, Quality | Formal phase gates with binary Go/Kill/Hold/Recycle; CCB for changes | Steering Committee; PM as command center | Per phase boundary |
| **SAFe** | All five types | PI Planning confidence vote; WSJF; Lean Budget Guardrails; cascading DoD layers | LPM (strategy), RTE (coordination), PO (team value) | PI boundary (phase/hypothesis); Sprint (quality); continuous (flow) |
| **PRINCE2** | Phase (Stage), Approval, Quality | Tolerance-based exception management; Stage Gate at stage boundaries | Project Board (Executive + Senior User + Senior Supplier) | Per stage boundary; exception-driven within stages |
| **Hybrid** | Phase + Quality + Approval | Phase gates at zone boundaries; DoR/DoD within agile execution zone | Dual: POs prioritize (agile), Steering Committee approves (traditional) | Phase boundaries + Sprint cadence |
| **XP** | Quality (engineering practices) | TDD, pair programming, CI as implicit quality gates | Business (scope), Technical (implementation) | Continuous (engineering practices); weekly iterations |

### Cross-Approach Gate Occurrence Summary

| Gate Type | Waterfall | Scrum | Kanban | SAFe | PRINCE2 | Hybrid |
|-----------|-----------|-------|--------|------|---------|--------|
| Phase Gate | Primary | None | None | PI boundary | Stage boundary | Zone boundary |
| Quality Gate | Phase-end reviews | DoR/DoD | Column policies | Cascading DoD | Quality Review Technique | DoR/DoD + phase QA |
| Flow Gate | None | Sprint as CONWIP | Primary (WIP limits) | WIP + Sprint | None | WIP within agile zone |
| Approval Gate | Primary | None | None | LPM approval | Change Authority | Phase-level sign-off |
| Hypothesis Gate | None | None | None | Pivot/Persevere | None | None |

---

## 6. Gates vs. Checkpoints

| Property | Gate | Checkpoint |
|----------|------|------------|
| **Authority** | Can block progression; produces binary pass/fail | Informs without preventing; surfaces risk and drives adaptation |
| **Decision output** | Go / No-Go / Hold / Recycle | Observations, recommendations, action items |
| **Failure consequence** | Work stopped; item returned; escalation triggered | Discussion; adaptation; continued flow |
| **Examples** | DoR, DoD, Phase Gate, CCB approval, WIP limit | Sprint Review, Daily Scrum, Sprint Retrospective, System Demo |

**Critical clarification (2020 Scrum Guide):** "The Sprint Review should never be considered a gate to releasing value." This is one of the most commonly confused distinctions in agile practice.

**Design principle:** Gates sit at critical boundaries where the cost of passing incorrectly is high. Checkpoints sit at cadence points where the cost of not adapting is high. Both are necessary; confusing them causes either governance paralysis (treating checkpoints as gates) or quality escape (treating gates as checkpoints).

---

## 7. Anti-Patterns

### Gate Anti-Pattern Detection and Remediation

| Anti-Pattern | Detection Signal | Remediation | Susceptible Approaches |
|-------------|-----------------|-------------|----------------------|
| **Rubber-stamping** | >95% approval rate; reviews <15 min; gatekeepers don't read materials | Explicit kill criteria; track decision distribution (healthy target: 10-20% killed/recycled); accountability for gate decisions | Waterfall, PRINCE2 |
| **Over-gating** | 13+ gate reviews; shadow IT proliferating; velocity near zero; governance cycle time exceeds delivery | Risk-based calibration with S/M/L tiers; WIP limits on governance pipeline; governance cycle time SLAs | Over-governed PMOs |
| **Under-gating** | Defects flow to late stages; "agile means no governance" mindset; correction costs escalating | Minimum viable gates aligned to risk profile; automated CI/CD quality gates; shift-left quality practices | Scrum (when DoR/DoD are weak) |
| **Criteria drift** | Different gatekeepers apply different standards; criteria change informally | Version-control gate criteria; periodic governance retrospectives; decision logs linked to criteria versions | All approaches |
| **Authority dilution** | 20+ gate attendees; no single accountable decision-maker; consensus without accountability | Clear RACI with single Accountable per gate; limit gate participants to RACI roles | SAFe (at scale) |
| **Gate shopping** | Teams route around governance to find sympathetic authority | Standardized scorecards; transparent decision logs; automated assessments | All approaches |
| **Zombie gates** | Gates in documentation but never enforced in 2+ cycles | Regular governance audits; sunset unenforced gates | Kanban, mature agile teams |
| **Asymmetric gates** | Entry strict but exit lax (or vice versa) | Design criteria holistically across full lifecycle; include business value at exit | Hybrid |
| **Context-free gates** | Same criteria for $10K and $10M initiatives | Risk-based calibration with categorization matrix at intake | Over-standardized PMOs |
| **Gate-as-ceremony** | Artifacts don't influence decisions; "we have a document" mentality | Embed governance in platforms with required fields and automated health checks | All approaches |
