# RAID Templates

## Purpose

Structured templates for Risk, Issue, Action, and Decision log entries with scoring guidance, escalation formats, and methodology-aware variation. Consumed by delivery-engine (Mode G) for RAID entry creation, risk assessment, and escalation preparation.

---

## 1. Risk Entry Template

### 1.1 Required Fields

| Field | Description | Example |
|-------|-----------|---------|
| **ID** | Unique identifier: R-[project code]-[sequential number] | R-[PROJECT_KEY]-042 |
| **Category** | Risk category from taxonomy (see 1.2) | Technical / Integration |
| **Title** | Brief descriptive title (<80 characters) | Vendor API documentation delayed beyond Sprint 14 |
| **Description** | Structured risk statement: "If [event/condition], then [impact on project objectives], caused by [root cause]" | If the vendor delivers API documentation after Sprint 14, then the integration feature will be delayed by 2+ sprints and the PI objective will be at risk, caused by vendor resource constraints and no SLA on documentation delivery |
| **Probability** | Likelihood of occurrence (1-5 scale; see Section 5) | 4 (High: 50-75%) |
| **Impact** | Consequence if it occurs (1-5 scale; see Section 5) | 4 (Major: PI objective at risk) |
| **Exposure Score** | Probability x Impact | 16 (Critical) |
| **Response Strategy** | Selected from taxonomy (see Section 6) | Mitigate + Prepare contingency |
| **Mitigation Actions** | Specific actions to reduce probability and/or impact | 1) Escalate to vendor PM for expedited documentation (by Apr 5). 2) Begin building mock API from available examples (start Apr 3). 3) Identify alternative vendor with compatible API |
| **Owner** | Person accountable for monitoring and response execution | [COLLEAGUE_D] (Integration Lead) |
| **Trigger Date** | Date by which risk materializes or becomes irrelevant | Sprint 14 end (Apr 12) -- if documentation not received, contingency activates |
| **Status** | Current lifecycle state | Open / Mitigating / Triggered / Closed / Accepted |
| **Review Date** | Next scheduled review | Apr 7 (Sprint Planning) |
| **Date Identified** | When the risk was first logged | Mar 28, 2026 |
| **Last Updated** | Most recent update timestamp | Apr 2, 2026 |

### 1.2 Risk Category Taxonomy

| Category | Sub-Categories | Examples |
|----------|---------------|---------|
| **Technical** | Architecture, Integration, Performance, Security, Data, Infrastructure | API incompatibility; performance degradation under load; data migration errors |
| **Schedule** | Dependencies, Resource availability, Estimation accuracy, Critical path | Vendor late; key person unavailable; underestimated complexity |
| **Scope** | Requirements volatility, Scope creep, Regulatory change | New compliance requirement mid-project; stakeholder adds features |
| **Resource** | Staffing, Skills, Budget, Vendor capacity | Key developer resignation; budget freeze; vendor resource contention |
| **Organizational** | Change management, Stakeholder, Political, Process | Sponsor turnover; reorganization; competing priorities from leadership |
| **External** | Market, Regulatory, Vendor, Force majeure | Market shift invalidates assumptions; new regulation; vendor acquisition |

---

## 2. Issue Entry Template

### 2.1 Required Fields

| Field | Description | Example |
|-------|-----------|---------|
| **ID** | Unique identifier: I-[project code]-[sequential number] | I-[PROJECT_KEY]-019 |
| **Category** | Issue category (same taxonomy as Risk but for materialized problems) | Technical / Integration |
| **Title** | Brief descriptive title (<80 characters) | Authentication service returns 500 errors on concurrent sessions >50 |
| **Description** | Clear problem statement: what is happening, when it started, who/what is affected | Since Sprint 12 deployment, the authentication service fails with 500 errors when concurrent sessions exceed 50. This blocks load testing and will prevent go-live if unresolved. Affects all user-facing features. |
| **Severity** | Technical impact (assessed by QA/Dev; see Section 5.3) | S2 (High: major feature broken, no workaround) |
| **Priority** | Business urgency (set by PO/Business) | P1 (blocks go-live path) |
| **Impact Description** | Quantified impact across dimensions: schedule, cost, scope, quality, strategic | Schedule: load testing blocked (2-week delay). Scope: all user features affected. Quality: cannot validate production readiness. Strategic: go-live date at risk. |
| **Resolution Actions** | Specific steps to resolve with owners and dates | 1) Root cause analysis -- Dev team (by Apr 3). 2) Fix implemented and unit tested (by Apr 5). 3) Load test re-run (by Apr 8). |
| **Owner** | Person accountable for driving resolution | [COLLEAGUE_C] (Tech Lead) |
| **Target Date** | Date by which resolution is expected | Apr 8, 2026 |
| **Status** | Current state | Open / In Progress / Resolved / Closed / Deferred |
| **Source** | Where the issue originated | R-[PROJECT_KEY]-031 (escalated from risk) / Sprint 12 testing / Production monitoring |
| **Date Identified** | When discovered | Mar 25, 2026 |
| **Last Updated** | Most recent update | Apr 2, 2026 |

---

## 3. Action Entry Template

### 3.1 Required Fields

| Field | Description | Example |
|-------|-----------|---------|
| **ID** | Unique identifier: A-[project code]-[sequential number] | A-[PROJECT_KEY]-087 |
| **Description** | Specific, measurable action to be performed | Conduct vendor API documentation review session with integration team and vendor technical contact |
| **Owner** | Person accountable for completing the action | [COLLEAGUE_D] |
| **Due Date** | Completion deadline | Apr 5, 2026 |
| **Status** | Current state | Not Started / In Progress / Complete / Overdue / Cancelled |
| **Source** | Which Risk, Issue, or Decision generated this action | R-[PROJECT_KEY]-042 (Mitigation Action #1) |
| **Source Type** | Risk / Issue / Decision / Meeting / Retrospective | Risk |
| **Completion Evidence** | What demonstrates the action is done | Meeting minutes with vendor; updated API integration spec; follow-on stories created |
| **Date Created** | When action was logged | Mar 28, 2026 |
| **Date Completed** | When action was verified complete | -- (pending) |

### 3.2 Action Lifecycle Rules

1. **Every action must have exactly one owner.** Shared ownership = no ownership.
2. **Every action must have a due date.** "ASAP" is not a date.
3. **Actions are generated by, not independent of, RAID items.** Every action traces to a source. Orphan actions (no parent risk, issue, or decision) indicate process gaps.
4. **Overdue actions auto-escalate.** If not completed by due date and not rescheduled with justification, escalate to PM within 1 business day.
5. **Completion requires evidence.** "Done" is not evidence. The completion evidence field must describe what was produced or verified.

---

## 4. Decision Entry Template

### 4.1 Required Fields

| Field | Description | Example |
|-------|-----------|---------|
| **ID** | Unique identifier: D-[project code]-[sequential number] | D-[PROJECT_KEY]-015 |
| **Title** | Decision statement (<100 characters) | Selected blue-green deployment over big-bang for go-live |
| **Description** | Full decision context: what was decided and why it needed a decision | The team needed to select a deployment strategy for go-live. Options were blue-green (parallel environments), canary (gradual rollout), and big-bang (all-at-once). Decision was needed by Sprint 13 to allow infrastructure provisioning. |
| **Decision Maker** | Person or body with decision authority | Project Steering Committee (per RACI: Accountable = CIO, Responsible = PM) |
| **Date** | When decision was made | Mar 20, 2026 |
| **Rationale** | Why this option was chosen over alternatives; trade-offs accepted | Blue-green selected for: instant rollback capability (requirement given high-risk profile), zero-downtime deployment (business continuity requirement), proven pattern for the tech stack. Trade-off accepted: higher infrastructure cost (~$15K/month for dual environments during transition). Canary rejected: insufficient monitoring maturity. Big-bang rejected: unacceptable risk for Tier 1 initiative. |
| **Impact** | What changes as a result of this decision | Infrastructure: provision parallel production environment by Sprint 14. Budget: $15K/month additional infra cost approved. Testing: add deployment verification tests to regression suite. |
| **Reversibility** | How easily this decision can be reversed | Medium: blue-green infrastructure can be decommissioned within 1 sprint. Decision is reversible before go-live; after go-live, switching strategies requires re-planning. |
| **Status** | Current state | Proposed / Made / Implemented / Superseded / Reversed |
| **Alternatives Considered** | Options that were evaluated | Canary (rejected: monitoring immaturity), Big-bang (rejected: risk profile too high), Rolling (rejected: not supported by current architecture) |
| **Related Items** | Links to risks, issues, or actions | R-[PROJECT_KEY]-028 (deployment risk); A-[PROJECT_KEY]-071 (provision parallel environment) |

### 4.2 Decision Quality Criteria

A well-documented decision includes:
- **The reasoning chain (WHY)** -- not just the decision (WHAT). Junior practitioners log the decision; principal practitioners log the reasoning.
- **Alternatives considered with explicit rejection rationale** -- "We considered X and rejected it because Y" prevents re-litigation.
- **Reversibility assessment** -- one-way-door decisions require more governance than two-way-door decisions.
- **Impact across dimensions** -- schedule, budget, scope, quality, risk implications of the decision.

---

## 5. P x I Scoring Guidance

### 5.1 Probability Scale (1-5)

| Score | Label | Probability Range | Behavioral Indicator |
|-------|-------|------------------|---------------------|
| 1 | Very Low | <10% | "Almost certainly won't happen; would be a major surprise" |
| 2 | Low | 10-25% | "Unlikely but not impossible; we've seen similar happen rarely" |
| 3 | Medium | 25-50% | "Could go either way; roughly coin-flip odds" |
| 4 | High | 50-75% | "More likely than not; we have evidence suggesting this will happen" |
| 5 | Very High | >75% | "Almost certain; would be surprising if it didn't happen" |

### 5.2 Impact Scale (1-5)

| Score | Label | Schedule Impact | Budget Impact | Scope Impact | Quality Impact | Strategic Impact |
|-------|-------|----------------|---------------|-------------|---------------|-----------------|
| 1 | Negligible | <1 day delay | <1% overrun | Cosmetic change | No quality impact | No strategic impact |
| 2 | Minor | 1-5 day delay | 1-5% overrun | Minor feature adjustment | Minor quality concession documented | Minor strategic misalignment |
| 3 | Moderate | 1-4 week delay | 5-10% overrun | Feature deferred or reduced | Quality gates require additional iteration | Stakeholder concern raised |
| 4 | Major | 1-3 month delay | 10-25% overrun | Major scope reduction | Significant quality compromise | Strategic objective at risk |
| 5 | Severe | >3 month delay or project failure | >25% overrun or budget exceeded | Project scope fundamentally changed | Unacceptable quality; go-live cannot proceed | Strategic objective fails |

### 5.3 Severity Classification (for Issues/Bugs)

| Level | Label | Definition | SLA Target | Governance |
|-------|-------|-----------|------------|-----------|
| S1 | Critical | System down; data corruption; security breach; complete loss of critical function | Immediate response; fix within hours | Pre-authorized bypass; skip refinement; inject mid-sprint; mandatory post-hoc documentation |
| S2 | High | Major feature broken; no workaround available; significant user impact | Fix within current sprint | Prioritized to top of sprint; elevated within normal flow |
| S3 | Medium | Feature impaired but workaround exists; moderate user impact | Fix in next sprint | Normal backlog refinement and sprint planning |
| S4 | Low | Cosmetic issue; minor inconvenience; edge case | Backlog; may defer indefinitely | Standard prioritization; may be closed as Won't Fix |

**Critical distinction:** Severity (technical impact) != Priority (business urgency). A Sev-4 cosmetic bug on the CEO's dashboard can be P1 (high business urgency). These must be assessed independently.

### 5.4 Exposure Score Interpretation

| Score Range | Severity | Color | Owner Level | Response Time |
|-------------|----------|-------|-------------|--------------|
| 1-4 | Low | Green | Team / SM | Next scheduled review |
| 5-9 | Medium | Yellow | Project Manager | 1-2 weeks |
| 10-14 | High | Orange | Program Manager / RTE | 1-3 business days |
| 15-19 | Very High | Red | Program Manager + Sponsor | 1 business day |
| 20-25 | Critical | Dark Red | Portfolio Manager / Executive | 4-24 hours |

---

## 6. Risk Response Strategy Selection

### 6.1 Threat Response Decision Model

| Strategy | Definition | When to Select | Example |
|----------|-----------|---------------|---------|
| **Avoid** | Eliminate the threat entirely by changing plans, scope, or approach | High-impact + high-probability AND a viable alternative path exists | Remove risky vendor integration from scope; use proven technology instead of experimental |
| **Mitigate/Reduce** | Take action to reduce probability and/or impact before the risk materializes | Most common response; cost-effective reduction available; probability or impact can be meaningfully lowered | Add integration tests to catch failures early (reduce impact); hire specialist to reduce technical risk (reduce probability) |
| **Transfer** | Shift the financial or operational impact to a third party | Financial risk that can be insured or contracted away; partner is better positioned to absorb | Purchase insurance; use fixed-price vendor contract; SLA with penalties |
| **Accept (passive)** | Acknowledge without taking action; absorb consequences if it occurs | Low-impact risk where response cost exceeds risk cost; risk is inherent to the work | "If the marketing campaign is delayed 1 week, we accept the minor visibility reduction" |
| **Accept (active)** | Acknowledge and set aside contingency reserve for response if triggered | Medium-impact risk with known trigger and planned response; management reserve appropriate | Reserve 2 sprint capacity for unexpected integration issues; document trigger and response |
| **Share** | Allocate ownership and consequences to the party best positioned to manage | Multi-party risk where no single party owns the full picture; joint ventures; platform dependencies | Shared risk register between vendor and client; joint testing responsibility |
| **Prepare contingency** | Pre-plan a specific response that activates only when a defined trigger event occurs | Known trigger exists; time-sensitive response needed; activation criteria are clear | "If vendor misses April 12 deadline, activate backup vendor engagement (pre-negotiated contract)" |

### 6.2 Response Selection Decision Tree

```
Is the risk acceptable as-is (low exposure, low cost of occurrence)?
  YES --> Accept (passive)
  NO -->
    Can the risk be eliminated by changing plans?
      YES (and alternative is viable) --> Avoid
      NO -->
        Can probability or impact be cost-effectively reduced?
          YES --> Mitigate
          NO -->
            Can impact be transferred to a third party?
              YES --> Transfer
              NO -->
                Is a specific trigger event identifiable?
                  YES --> Prepare contingency (with active acceptance of residual risk)
                  NO --> Accept (active) with contingency reserve
```

### 6.3 Opportunity Response Strategies

| Strategy | Definition | When to Select |
|----------|-----------|---------------|
| **Exploit** | Ensure the opportunity is realized | High-value opportunity; actions can guarantee realization |
| **Enhance** | Increase the probability or positive impact | Opportunity is valuable but uncertain; actions can improve odds |
| **Share** | Allocate to the party best positioned to realize it | Partner or team is better positioned to capitalize |
| **Accept** | Welcome if it occurs but take no proactive action | Low-effort opportunity; benefit is incremental |

---

## 7. SIOR Escalation Format

### 7.1 Template

```
ESCALATION: [Risk/Issue ID] -- [Title]
Escalated by: [Name, Role]
Escalated to: [Name/Body, Role]
Date: [Date]  |  Decision needed by: [Deadline]

SITUATION
[Clear problem statement. What is happening. When it was discovered.
Current state of the risk/issue. What has been tried.]

IMPACT
- Schedule: [Specific impact with dates/durations]
- Budget:   [Specific impact with amounts]
- Scope:    [What deliverables/features are affected]
- Quality:  [What quality criteria are at risk]
- Strategic: [How this affects strategic objectives]

OPTIONS
1. [Option A]: [Description]
   - Pro: [Benefits]
   - Con: [Costs/risks]
   - Cost: [Time/money/resource required]

2. [Option B]: [Description]
   - Pro: [Benefits]
   - Con: [Costs/risks]
   - Cost: [Time/money/resource required]

3. [Option C]: [Description]
   - Pro: [Benefits]
   - Con: [Costs/risks]
   - Cost: [Time/money/resource required]

RECOMMENDATION
[Preferred option with explicit rationale. Why this option
over the alternatives. What decision is needed and by when.]
```

### 7.2 Escalation Quality Rules

1. **Never escalate a problem without options.** Minimum 2 alternatives with trade-offs.
2. **Always include a recommendation.** Escalation enables decision, not just awareness.
3. **Quantify impact across dimensions.** "It's a big risk" is not an escalation; "2-week schedule delay affecting 3 downstream features and $50K in additional vendor cost" is.
4. **Include a decision deadline.** "When convenient" is not a deadline.
5. **Pre-notify the person being escalated to.** Surprise escalations damage trust.

---

## 8. Methodology Variation: Risk Management Approaches

| Dimension | P x I (Traditional) | ROAM (SAFe) | Lean Problem-Solving | Empirical (Scrum/Kanban) |
|-----------|-------------------|-------------|---------------------|------------------------|
| **Mechanism** | 5x5 scoring matrix; risk register; Monte Carlo (optional) | Four categories: Resolved, Owned, Accepted, Mitigated | A3 thinking; 5 Whys; poka-yoke prevention | Sprint-as-containment; impediment log; blocker clustering |
| **Scoring** | Quantitative (P x I = 1-25) | Categorical (no numeric score) | Flow-based data | Empirical from actual flow |
| **Best for** | Regulated environments; many risks needing comparison; audit trails | Rapid categorization at PI boundaries; team self-management | Root cause analysis; systemic prevention | Team-level; short feedback loops |
| **Artifact** | Risk register (spreadsheet or tool) | ROAM Board (visual, physical or digital) | A3 report; visual boards | Impediment log; aging WIP charts |
| **Review cadence** | Weekly formal review; quarterly deep review | Every PI boundary; ART Sync for in-flight | Continuous (gemba walks; daily management) | Daily Scrum (impediments); Sprint Retro (process risks) |
| **Limitation** | False precision danger; register can become compliance artifact | No quantitative comparison between risks; less suitable for large risk portfolios | Requires mature problem-solving culture; less structured for portfolio-level | Iterative delivery necessary but not sufficient for explicit risk thinking |

**Compatibility note:** These approaches are not mutually exclusive. Common combinations:
- ROAM for team-level + P x I for portfolio-level (SAFe organizations)
- Lean problem-solving for root cause + P x I for risk tracking (manufacturing-influenced IT)
- Empirical (Scrum) for sprint-level + P x I for project-level (Hybrid environments)

---

## 9. Anti-Patterns

| Anti-Pattern | Detection Signal | Root Cause | Remediation |
|-------------|-----------------|------------|-------------|
| **Stale RAID logs** | Items >30 days without update; no closures in 60 days; register growing but never shrinking | RAID treated as compliance artifact, not decision tool; no review cadence enforcement | Minimum weekly review; enforce closure; age-based escalation (>30 days = auto-escalate); quarterly audit |
| **Missing owners** | Risk/issue/action entries with "TBD" or blank owner fields; items with departed employees as owners | No ownership enforcement at creation; no offboarding handoff process | Reject RAID entries without owners; monthly ownership audit; mandatory reassignment when employees depart |
| **Risks without response strategies** | Risks identified and scored but no mitigation, contingency, or explicit acceptance documented | Identification treated as sufficient; no "so what?" discipline | Require response strategy selection at identification; block RAID entry acceptance without strategy |
| **Severity/priority conflation** | All issues marked P1/S1; no differentiation in triage; everything treated as critical | No clear definitions; single dimension used for both | Separate fields; define thresholds per Section 5; require both dimensions at triage |
| **Risk avoidance as strategy** | Excessive analysis paralysis; inability to start without complete information; treating uncertainty as eliminable | Confusing risk management with risk elimination; DeMarco & Lister: "risk avoidance is itself the greatest risk" | Embrace uncertainty; use iteration as risk reduction; accept that some risk is inherent to all work |
| **Sham progress reporting** | Projects consistently green then sudden red; Mum Effect (reluctance to report bad news) | Punishing the messenger; self-reported RAG with no objective thresholds | Formula-driven RAG from tool telemetry; independent "watermelon checks"; psychologically safe reporting culture |
| **Hero-dependent tracking** | Single person tracks all risks; tracking stops when they're unavailable; no distributed ownership | Risk management treated as specialized function | Bus factor >= 2; distribute ownership; integrate risk discussion into regular cadences |
| **Decision amnesia** | Same decisions relitigated; "didn't we already decide this?"; no decision log | Decisions not documented or not findable; rationale not captured | Log all significant decisions with rationale and alternatives; make decision log searchable and referenced |
