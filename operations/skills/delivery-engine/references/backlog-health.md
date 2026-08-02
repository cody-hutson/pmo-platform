# Backlog Health

## Purpose

Structured reference for assessing backlog health, enforcing work item readiness standards, and diagnosing common backlog pathologies. Consumed by delivery-engine (Mode A) for backlog health diagnostics and improvement recommendations.

---

## 1. Backlog Health Indicators

### 1.1 Primary Health Metrics

| Indicator | Healthy Target | Warning Threshold | Alarm Threshold | Measurement |
|-----------|---------------|-------------------|-----------------|-------------|
| **Refinement ratio** | 2+ sprints of refined work ahead | 1-2 sprints ahead | <1 sprint ahead | Count of items meeting DoR / sprint velocity |
| **Backlog size** | 3-6 months of work at current throughput | 6-12 months | >12 months or >200 items | Total estimated effort / average throughput |
| **Age distribution** | <10% of items older than 3 months | 10-25% older than 3 months | >25% older than 3 months | Item age histogram |
| **Estimation coverage** | >90% of items in next 2 sprints estimated | 75-90% estimated | <75% estimated | Estimated items / total items in near-term backlog |
| **Type balance** | Mix matches capacity allocation (features ~60%, tech debt ~20%, bugs ~15%, other ~5%) | One type >80% of backlog | Single type dominates with others starving | Item count by type / total |
| **Dependency ratio** | <15% of items have unresolved dependencies | 15-30% with dependencies | >30% or any blocked dependency in next sprint | Items with active dependencies / total |
| **Blocker count** | Zero blocked items in current sprint | 1-2 blocked items | >2 blocked items or any blocked >24 hours | Count of items in "blocked" state |
| **Rejection rate** | <10% of items rejected at DoR check | 10-20% rejected | >20% rejected | Items failing DoR / items submitted for refinement |

### 1.2 Health Dashboard Formula

**Backlog Health Score** = weighted average of indicator scores (0-100):

| Indicator | Weight | Score 100 | Score 50 | Score 0 |
|-----------|--------|-----------|----------|---------|
| Refinement ratio | 25% | 2+ sprints | 1 sprint | <1 sprint |
| Age distribution | 20% | <10% aged | 10-25% aged | >25% aged |
| Estimation coverage | 15% | >90% | 75-90% | <75% |
| Dependency ratio | 15% | <15% | 15-30% | >30% |
| Type balance | 15% | Within 10% of target | Within 20% | >20% deviation |
| Blocker count | 10% | Zero | 1-2 | >2 |

**Interpretation:** >80 = Healthy; 60-80 = Attention needed; <60 = Immediate intervention required.

---

## 2. INVEST Criteria Checklist

Every work item entering execution must satisfy INVEST criteria. This is the operational Definition of Ready (DoR) foundation.

### 2.1 INVEST Assessment

| Criterion | Definition | Pass Example | Fail Example | Remediation |
|-----------|-----------|--------------|-------------|-------------|
| **I -- Independent** | Item can be developed and delivered without waiting for other items to complete | "As a user, I can reset my password via email" (self-contained) | "Build the API endpoint" (depends on "Design the API schema" being done first) | Decompose to remove dependency; or explicitly sequence with dependency tracking |
| **N -- Negotiable** | Item describes desired outcome, not prescribed implementation; scope can be adjusted | "Users can search products by name, category, or SKU" (what, not how) | "Implement ElasticSearch with 3 index types and a React component using Material UI" (dictates implementation) | Rewrite as user-facing outcome; move technical decisions to team |
| **V -- Valuable** | Item delivers identifiable value to a user or stakeholder when completed | "Customers can track their order status in real-time" (clear user value) | "Refactor database connection pooling" (no visible user value as written) | Frame tech work as enabler with explicit value chain: "Refactor pooling to support 2x concurrent users" |
| **E -- Estimable** | Team can estimate the item with reasonable confidence; unknowns are bounded | "Add email notification when order ships" (team has done similar work; estimates 3-5 points) | "Integrate with the vendor's new API" (team has never seen the API; no documentation available) | Spike first: time-boxed research to reduce unknowns, then re-estimate the resulting stories |
| **S -- Small** | Item covers one coherent concern and needs no further slicing to deliver; under a time-boxed approach it also fits within a single iteration, no larger than 1/3 of sprint capacity | "Display order confirmation with order number and estimated delivery" (2-3 days of work) | "Build the entire checkout flow" (2+ sprints of work spanning multiple concerns) | Split by workflow step, business rule variation, CRUD operation, or data variation |
| **T -- Testable** | Clear, specific acceptance criteria exist that can be verified | "Given a valid email, when user clicks reset, then a reset link is sent within 60 seconds" | "The system should be user-friendly" (not testable; subjective) | Write Given/When/Then acceptance criteria; if you cannot write a test, the requirement is not clear enough |

### 2.2 INVEST Scoring

For each criterion: 1 (Met) or 0 (Not Met). Minimum DoR threshold: 5 of 6 criteria met (the one failure must not be "Valuable" or "Testable" -- these two are non-negotiable).

---

## 3. Work Item Age Limits

### 3.1 Age Limits by Item Type

| Item Type | In-Progress Age Limit | Backlog Age Limit (before re-triage) | Kill Threshold | Rationale |
|-----------|----------------------|--------------------------------------|---------------|-----------|
| **User Story** | <2 sprints (if in progress >2 sprints, split or escalate) | 3 months | 6 months without activity | Stories are perishable; context and value decay |
| **Bug (Sev-1/2)** | Sev-1: hours; Sev-2: within sprint | N/A (triaged immediately) | N/A | Severity drives urgency |
| **Bug (Sev-3/4)** | 1 sprint max | 3 months | 6 months (Sev-4 may be closed as Won't Fix) | Low-severity bugs lose context over time |
| **Spike** | 1 sprint max (strict time-box) | 1 sprint (if not started) | 2 sprints | Spikes that sit become stale; re-scope needed |
| **Enabler** | 1-2 sprints depending on type | 2 sprints (architecture enablers may be longer) | 1 PI without progress | Enablers blocked by dependencies should escalate |
| **Tech Debt** | 2 sprints max | 6 months | 12 months (re-justify from scratch) | Long-lived debt items may indicate systemic issue |
| **Epic** | Governed by hypothesis gate (Persevere/Pivot/Cancel per PI) | N/A (epics are containers) | PI boundary without progress triggers review | Epics are investment vehicles, not perpetual containers |

### 3.2 Age-Based Escalation Rules

| Age Threshold | Action | Owner |
|---------------|--------|-------|
| Item in progress >50% of sprint length with no state change | Flag as aging; trigger team discussion | Scrum Master / SDM |
| Item in progress >1 sprint | Mandatory swarming or split decision | Team + PO |
| Backlog item untouched 3 months | Mandatory re-triage: keep, kill, or re-scope | PO |
| Backlog item untouched 6 months | Auto-escalate to kill review; default is close | PO + PM |
| Backlog item untouched 12 months | Kill (close as Won't Do) unless explicitly re-justified from scratch | PM |

---

## 4. Backlog Grooming Cadence

### 4.1 Refinement Schedule

| Backlog Level | Cadence | Duration | Participants | Focus |
|---------------|---------|----------|-------------|-------|
| **Team backlog** | Weekly (or ~10% of sprint capacity) | 1-2 hours per session | PO, Developers, QA | Decompose items for next 2 sprints; clarify acceptance criteria; estimate; apply INVEST |
| **Program backlog** | Biweekly | 1-2 hours | PM, POs, Architects, Tech Leads | Feature-level refinement; cross-team dependency identification; priority alignment |
| **Portfolio backlog** | Monthly (or per PI cadence) | 2-4 hours | Portfolio Manager, PMs, Business Owners | Epic-level review; strategic alignment check; demand triage; kill/fund/hold decisions |

### 4.2 Refinement Quality Checklist

Each refinement session should produce:

| Output | Required | Verification |
|--------|----------|-------------|
| Items decomposed to deliverable size -- sprint-ready under a time-boxed approach | Yes | INVEST "Small" criterion met |
| Acceptance criteria written | Yes | Given/When/Then format; INVEST "Testable" met |
| Estimates assigned | Yes, under a time-boxed approach | Story points or T-shirt size; team consensus. Under any approach the item carries a bound of record -- a size estimate, a time-box, or a scope-box |
| Dependencies identified and mapped | Yes | Any dependency logged with owner and need-by date |
| Questions resolved or spikes created | Yes | No "TBD" on items in the next 2-sprint window |
| Priority validated against current goals | Yes | PO confirms ordering reflects Sprint/PI Goals |

---

## 5. Definition of Ready (DoR) Minimum Standard

### 5.1 Per-Methodology DoR

| Methodology | DoR Standard | Enforcement Mechanism | Key Variation |
|-------------|-------------|----------------------|---------------|
| **Scrum** | INVEST criteria met; acceptance criteria written; estimated; dependencies mapped; fits in sprint | Sprint Planning gate: items not meeting DoR are not pulled into Sprint Backlog | Team owns DoR; PO ensures items are ready before planning |
| **Kanban** | Meets Commitment Point entry criteria; Class of Service assigned; meets explicit column policy | Pull policy at Commitment Point: items not meeting criteria stay in options/exploration | Policy-driven; SDM ensures criteria are explicit |
| **SAFe** | INVEST met; Feature acceptance criteria defined; team capacity confirmed; PI dependencies mapped | PI Planning readiness: Features not meeting DoR are marked uncommitted | Layered DoR: Story-level + Feature-level + PI-level |
| **Waterfall** | Requirements documented and approved; design complete for work package; resources assigned | Work Package authorization: PM must approve before team begins | Formal authorization gate; PM specifies what, team determines how |
| **Hybrid** | Agile zone: INVEST + estimation. Waterfall zone: requirements baseline + design approval | Zone-dependent: agile uses sprint planning gate; waterfall uses work package authorization | Zone boundary crossing requires explicit handoff |
| **XP** | Customer has written story card; programmers can estimate; story is small enough for weekly iteration | Planning Game: customer sets priority, programmers set estimates | Simplest DoR; relies on pair programming and TDD to catch gaps |

### 5.2 Universal DoR Minimum (Cross-Methodology)

Regardless of methodology, no item should enter active work without:

1. **Clear outcome statement** -- what "done" looks like from the user/stakeholder perspective
2. **At least one testable acceptance criterion** -- verifiable, not subjective
3. **Bounded for delivery** -- a size estimate, a time-box (fits within one iteration or one reasonable flow cycle), or a scope-box (stated acceptance criteria plus an explicit out-of-scope boundary); scope with no out-of-scope boundary is not a bound
4. **Known dependencies declared** -- or explicitly stated as "none identified"
5. **Assigned to a team or individual** -- ownership clear

---

## 6. Methodology Variation Table

| Health Dimension | Scrum | Kanban | SAFe | Waterfall | Hybrid |
|-----------------|-------|--------|------|-----------|--------|
| **Backlog structure** | Single Product Backlog ordered by PO | Input queue + done queue; flow-based | Multi-level: Portfolio > Program > Team backlogs | Requirements baseline + WBS; frozen after approval | Dual: waterfall requirements baseline + agile sprint backlog |
| **Refinement mechanism** | Dedicated refinement sessions (~10% of sprint) | Replenishment meeting when queue drops below threshold | PI Planning + Sprint-level refinement | Phase-gate requirements reviews | Agile refinement within sprints; waterfall requirements reviews at phase gates |
| **Health measurement** | Velocity trend; refinement ratio; sprint completion rate | Throughput; cycle time; aging WIP; WIP distribution | PI predictability; Feature cycle time; Program Board health | Requirements stability; baseline change frequency | Both: velocity within sprints + requirements stability at phase level |
| **Age management** | Sprint boundary forces age discipline; backlog grooming catches old items | Aging WIP charts reveal stale items; explicit column age policies | PI boundary forces review; uncommitted objectives tracked | Phase completion forces closure; change requests re-enter pipeline | Phase boundaries + sprint boundaries both enforce |
| **Pathology signals** | Velocity volatile; sprint completion <70%; refinement skipped | WIP aging; throughput declining; queue growing; blocked items accumulating | PI predictability declining; uncommitted objectives growing; Feature cycle time increasing | Requirements churn; baseline changes frequent; scope creep | Zone boundary conflicts; dual-tracking overhead; inconsistent DoR between zones |

---

## 7. Anti-Patterns

| Anti-Pattern | Detection Signal | Root Cause | Remediation |
|-------------|-----------------|------------|-------------|
| **Backlog as graveyard** | >200 items; items untouched 90+ days; 12+ month old items; growing faster than throughput | No retirement criteria; political unwillingness to kill items; treating backlog as wish list rather than economic queue | Quarterly zombie hunts; enforce aging thresholds (3mo = attention, 6mo = re-triage, 12mo = kill or re-justify); connect backlog size to throughput |
| **Everything is priority 1** | All items marked highest priority; no differentiation; "97 of 100 items marked priority 1" (Reinertsen) | No explicit prioritization framework; political pressure; fear of saying "not now" | Enforce MoSCoW (Must-haves <=60% of effort); apply WSJF for sequencing; require "if we do this, what do we stop?" |
| **No refinement cadence** | Items enter sprint unrefined; acceptance criteria missing at planning; estimates done under time pressure | Refinement seen as optional; PO unavailable; team sees refinement as overhead | Dedicate 10% of sprint capacity; track refinement ratio as health metric; make it non-negotiable |
| **One workflow fits all** | Bugs queue behind stories in refinement; spikes run with no bound of any kind; CRs bypass governance | Tool configured with single workflow for all types; no type-specific lifecycle awareness | Configure type-specific workflows; spike DoR/DoD with an explicit bound (a time-box or a scope-box); severity-driven routing for bugs |
| **Severity/priority conflation** | All bugs marked Sev-1/P1; no triage differentiation; everything urgent | No clear definitions; single dimension used for both; fear of deprioritization | Separate severity (technical impact, QA-assessed) from priority (business urgency, PO-set); define thresholds |
| **Spike without boundaries** | Open-ended research with no bound of any kind -- neither a time-box nor a scope-box -- no defined question, no output artifact | Missing spike DoR/DoD; spike treated as story | An explicit bound: a time-box (max 1 sprint) **or** a scope-box (stated acceptance criteria plus an explicit out-of-scope boundary); clear research question; DoD = findings documented + follow-on stories created |
| **Permanent tech debt deferral** | Tech debt items logged but never addressed; no reserved capacity; crisis-driven fixes only | No Intangible Class of Service capacity; no structural mechanism for debt reduction | Reserve 15-20% capacity; dedicated Intangible CoS in Kanban; treat recurring defects as debt signal |
| **Demand flooding** | Triage backlog growing; average triage time exceeding SLA; intake overwhelmed | Absent project size thresholds; no minimum viable information requirements; political "projectization" of BAU work | WIP limits on intake queue; enforce T-shirt sizing thresholds; auto-route XS items |
