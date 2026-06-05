# Dependency Rules

## Purpose

Structured reference for dependency identification, classification, lifecycle management, risk scoring, and escalation across delivery methodologies. Consumed by delivery-engine for dependency tracking, risk assessment, and escalation trigger evaluation.

---

## 1. Dependency Classification

### 1.1 Five Dependency Types

| Type | Definition | Example | Detection Method | Typical Risk Level |
|------|-----------|---------|-----------------|-------------------|
| **Internal team** | Dependency between items within the same team's backlog | Story B requires Story A's API to be complete | Sprint planning; backlog refinement; dependency mapping during grooming | Low -- team controls both sides |
| **Cross-team** | Dependency between items owned by different teams in the same program | Team Alpha needs Team Beta's authentication service before building user management | PI Planning (SAFe); cross-team refinement; Scrum of Scrums; Nexus Daily Scrum | Medium -- coordination required but shared governance |
| **Cross-project** | Dependency between items in different projects, potentially different programs | [PROJECT_KEY] project depends on ERP upgrade project completing data migration | Portfolio review; program-level dependency mapping; project charter review | High -- different governance, timelines, priorities |
| **Vendor/external** | Dependency on a third party outside organizational control | Waiting for vendor API documentation; dependent on partner's release schedule | Vendor management; contract review; procurement tracking | High -- limited influence; SLA-dependent |
| **Technical/infrastructure** | Dependency on shared technical resources, platforms, or infrastructure | Deployment depends on new server provisioning; feature depends on database schema migration | Architecture review; infrastructure planning; DevOps pipeline analysis | Variable -- depends on infrastructure maturity |

### 1.2 Dependency Direction

| Direction | Meaning | Action Required |
|-----------|---------|----------------|
| **Inbound** | This item depends on another item completing first | Track the source item's progress; escalate if at risk |
| **Outbound** | Another item depends on this item completing | Prioritize accordingly; communicate progress to dependent team |
| **Bidirectional** | Both items depend on each other (circular) | Design problem; decompose to break the cycle or create shared interface contract |

**Rule:** Bidirectional dependencies are design smells. If detected, escalate to architecture review. Resolve by: (1) creating an interface contract both sides can develop against independently, (2) merging the items into one, or (3) decomposing differently to eliminate the cycle.

---

## 2. Dependency Lifecycle

### 2.1 Five-Stage Lifecycle

```
Identified --> Assessed --> Assigned --> Tracked --> Resolved/Escalated
```

| Stage | Definition | Entry Criteria | Exit Criteria | Owner |
|-------|-----------|---------------|---------------|-------|
| **Identified** | Dependency discovered and logged | Any team member identifies a dependency during planning, refinement, or execution | Type classified; direction determined; source and target items linked | Discoverer (logs it) |
| **Assessed** | Risk scored; impact quantified; need-by date established | Type and direction known | Risk score assigned; need-by date set; impact on critical path evaluated | PM / Scrum Master / RTE |
| **Assigned** | Owner designated; resolution plan created | Risk assessment complete | Owner accepted; resolution approach documented; communication plan set | PM assigns; owner accepts |
| **Tracked** | Active monitoring against need-by date; progress reported | Owner assigned and resolution underway | Dependency resolved (deliverable available) or escalation triggered | Owner (reports progress); PM/SM (monitors) |
| **Resolved/Escalated** | Dependency satisfied or escalated due to risk | Deliverable available (resolved) or escalation trigger hit (escalated) | Resolved: dependent item unblocked. Escalated: escalation path activated per rules below | Owner confirms resolution; PM/SM confirms unblock |

### 2.2 Lifecycle Enforcement Rules

1. **Every dependency must have an owner.** Unowned dependencies are invisible risks. If no owner is assigned within 1 business day of identification, auto-escalate to PM.
2. **Every dependency must have a need-by date.** The need-by date is when the dependent item needs the dependency resolved to avoid schedule impact -- not when it would be "nice to have."
3. **Dependencies identified during PI Planning are logged on the Program Board** with red strings (SAFe) or equivalent cross-team visibility mechanism.
4. **Dependencies are reviewed at every cadence point** appropriate to their type: Daily (internal team blockers), Sprint/iteration (cross-team), PI/monthly (cross-project and vendor).

---

## 3. Risk Scoring for Dependencies

### 3.1 Dependency Risk Score

**Risk Score = Probability of Delay x Impact of Delay**

#### Probability of Delay (1-5)

| Score | Probability | Indicators |
|-------|------------|------------|
| 1 | Very low (<10%) | Owner confirmed on track; deliverable is routine; no blockers |
| 2 | Low (10-25%) | Owner reports minor concerns; deliverable is standard work; schedule has buffer |
| 3 | Medium (25-50%) | Owner reports challenges; deliverable depends on another dependency; buffer consumed |
| 4 | High (50-75%) | Owner reports significant risk; deliverable is behind schedule; escalation pending |
| 5 | Very high (>75%) | Owner acknowledges likely delay; deliverable is blocked; no resolution path visible |

#### Impact of Delay (1-5)

| Score | Impact | Indicators |
|-------|--------|------------|
| 1 | Negligible | Dependent item has alternative path; delay <1 day; non-critical path |
| 2 | Minor | Dependent item delayed 1-3 days; workaround available; not on critical path |
| 3 | Moderate | Sprint goal at risk; dependent item delayed 1-2 weeks; on secondary critical path |
| 4 | Major | PI objective at risk; multiple items blocked; milestone at risk; customer impact |
| 5 | Severe | Release at risk; cross-project cascade; regulatory deadline threatened; revenue impact |

#### Risk Score Routing

| Score Range | Severity | Review Cadence | Escalation Target |
|-------------|----------|---------------|-------------------|
| 1-7 | Low | Next scheduled review (sprint/weekly) | Team / Scrum Master |
| 8-14 | Medium | Weekly dedicated review | Project Manager |
| 15-19 | High | Twice weekly; active tracking | Program Manager / RTE |
| 20-25 | Critical | Daily; active escalation | Portfolio Manager / Executive |

---

## 4. Escalation Triggers

### 4.1 Automatic Escalation Rules

| Trigger | Condition | Escalation Path | Time to Respond |
|---------|-----------|-----------------|-----------------|
| **Unresolved within 1 sprint of need-by date** | Need-by date is within 1 sprint and dependency is still in "Tracked" stage with no resolution in sight | Owner --> PM --> Program Manager | 2 business days |
| **External dependency with no SLA** | Vendor/external dependency has no agreed service level or response commitment | PM --> Program Manager --> Procurement/Vendor Management | 5 business days to establish SLA; escalate weekly until resolved |
| **Cross-project dependency with no liaison** | Dependency exists between projects but no single point of contact is designated for coordination | PM --> Program Manager | 3 business days to assign liaison |
| **Dependency owner unresponsive** | No status update in 5+ business days; owner not responding to inquiries | PM --> Owner's manager --> Program Manager | 2 business days |
| **Critical path dependency at risk** | Dependency on the critical path shows probability of delay >= 3 | PM --> Program Manager --> Portfolio (if cross-project) | 1 business day |
| **Cascading dependency failure** | One dependency delay triggers delays in 3+ downstream items | PM --> Program Manager --> Portfolio Manager | Same day |
| **Blocked item aging** | Item blocked by dependency for >50% of sprint length with no state change | Scrum Master --> PM | Same day (swarming conversation) |

### 4.2 Escalation Communication Format (SIOR)

Every dependency escalation must follow the SIOR framework:

| Component | Content | Example |
|-----------|---------|---------|
| **S -- Situation** | What dependency, between whom, current state | "Cross-team dependency: Team Alpha's user auth module depends on Team Beta's API gateway, which was due Sprint 14 and is now at risk for Sprint 15." |
| **I -- Impact** | Quantified impact across schedule, cost, scope, quality | "If delayed beyond Sprint 15: 3 dependent stories blocked, Sprint Goal at risk, Feature delivery pushed to next PI, customer demo date missed." |
| **O -- Options** | What was tried + 2-3 alternatives with trade-offs | "1) Swarm Beta's API work (adds 2 devs, compresses to 3 days). 2) Alpha builds mock service (1 sprint rework later). 3) Descope dependent stories from this PI." |
| **R -- Recommendation** | Preferred course with rationale and decision deadline | "Recommend Option 1: swarm. Requires Beta PM approval by end of day Wednesday to preserve Sprint 15 commitment." |

---

## 5. Methodology Variation Table

| Dimension | Scrum | Kanban | SAFe | Waterfall | PRINCE2 | Hybrid |
|-----------|-------|--------|------|-----------|---------|--------|
| **Discovery mechanism** | Sprint Planning; Refinement; Daily Scrum impediments | Board visualization; blocker flags; replenishment meeting | PI Planning (Program Board with red strings); Scrum of Scrums; ART Sync | WBS decomposition; critical path analysis; network diagrams | Product-based planning; stage planning; product flow diagrams | Both: PI Planning for cross-team + WBS for phase-level |
| **Tracking mechanism** | Impediment log; sprint burndown; DoR dependency check | Blocker flags on board; aging WIP charts; blocked item metrics | Program Board; dependency matrix; ART-level tracking | Gantt chart; critical path method; dependency arrows | Stage Plan; Exception Reports when tolerance breached | Dual: agile board + Gantt for cross-phase |
| **Escalation path** | SM --> PO --> PM | SDM --> escalation cadence | SM --> RTE --> PM --> LPM | PM --> Steering Committee | PM --> Project Board (exception process) | Zone-dependent: agile path within sprints, waterfall path at phase gates |
| **Blocker handling** | Surface at Daily Scrum; SM removes impediments; swarm if persistent | Blocker flag on board; blocked items count against WIP; trigger root cause analysis | Impediment raised at ART Sync or Scrum of Scrums; RTE coordinates resolution | Change Request if scope-affecting; otherwise PM resolves within authority | Exception Report if tolerance exceeded; PM manages within tolerance | Agile zone: SM resolves. Waterfall zone: PM + CR process if needed |
| **Cross-team coordination** | Scrum of Scrums (if multi-team); shared backlog refinement | Enterprise Services Planning cadence network; cross-team WIP visibility | ART Sync (weekly); System Demo (per iteration); PI Planning (per PI) | Program coordination meetings; integrated master schedule | Programme level (MSP); project-to-project interface in stage plans | Phase-level integration meetings + sprint-level cross-team sync |
| **Dependency types emphasized** | Internal team and cross-team | Flow-based (upstream/downstream bottleneck) | All five types (explicit at PI Planning) | Cross-project and vendor (formal contracts) | Stage-to-stage; product-to-product | All types; zone boundary dependencies are unique to hybrid |

---

## 6. Dependency Board Design

### 6.1 Visualization Requirements

A dependency board (physical or digital) should make the following visible at a glance:

| Element | Representation | Purpose |
|---------|---------------|---------|
| **Source item** | Card/tile with team, sprint, status | Shows who provides |
| **Target item** | Card/tile with team, sprint, status | Shows who needs |
| **Dependency type** | Color code (internal=green, cross-team=yellow, cross-project=orange, vendor=red, infrastructure=blue) | Risk visibility by type |
| **Direction** | Arrow from source to target | Shows flow of dependency |
| **Need-by date** | Date label on dependency link | Shows deadline urgency |
| **Risk score** | RAG indicator on dependency link | Shows current risk level |
| **Status** | Identified / Assessed / Assigned / Tracked / Resolved | Shows lifecycle stage |

### 6.2 SAFe Program Board Convention

In SAFe, dependencies between teams are visualized on the Program Board during PI Planning:

- **Red strings** connect dependent items across team boards
- Each string has a direction (from provider to consumer)
- Dependencies are reviewed during the Management Review and Problem-Solving session
- Confidence vote at the end of PI Planning validates that dependency risks are acceptable

### 6.3 Dependency Matrix (Alternative View)

For portfolio-level visibility, a matrix format works when the board becomes too dense:

| | Team A | Team B | Team C | Vendor X |
|---|---|---|---|---|
| **Team A** | -- | 2 outbound (low risk) | 1 outbound (medium risk) | 0 |
| **Team B** | 2 inbound | -- | 1 bidirectional (HIGH) | 1 inbound (high risk) |
| **Team C** | 1 inbound | 1 bidirectional (HIGH) | -- | 0 |
| **Vendor X** | 0 | 1 outbound | 0 | -- |

**Hot spots:** Bidirectional dependencies (design smell) and high-risk vendor dependencies get immediate attention.

---

## 7. Anti-Patterns

| Anti-Pattern | Detection Signal | Root Cause | Remediation |
|-------------|-----------------|------------|-------------|
| **Hidden dependencies** | Dependencies discovered at integration, not at planning; "surprise" blockers in mid-sprint; integration failures from uncoordinated teams | No explicit dependency identification step in planning; teams plan in isolation; no cross-team visibility | Mandate dependency identification in refinement and planning; cross-team refinement sessions; PI Planning for scaled environments |
| **Single-threaded external dependencies** | One vendor contact; no SLA; no contingency; team blocked waiting for response | No vendor management discipline; dependency accepted without risk assessment | Require SLA for all vendor dependencies; designate backup contacts; create contingency plan for every external dependency (what if they're 2 weeks late?) |
| **Blocked and silent** | Impediments surface only at next Daily Scrum (24hr delay); team starts new work when blocked instead of swarming | Culture of waiting; blockers not visible; no swarming norm; no andon signal equivalent | Andon signal culture -- raise blockers immediately, not at standup; visual blocker flags (NOT a separate "Blocked" column); swarm on blocked items |
| **Dependency optimism** | All dependencies rated low risk; "they said they'd have it done"; no verification of provider's progress | No independent verification; social pressure to rate dependencies as "fine" | Independent verification: check provider's board/burndown, not just their verbal status; trust but verify |
| **Hero-dependent coordination** | One person (PM, RTE, or tech lead) tracks all dependencies; coordination stops when they're unavailable | Dependency management treated as specialized function rather than team capability | Distribute dependency ownership; require bus factor >= 2 for coordination roles; make dependency status part of regular team cadences |
| **Methodology silos** | Waterfall and agile teams manage dependencies in separate systems with no unified view; steering committee cannot see cross-methodology dependencies | Separate tools and processes per delivery approach with no normalization | Unified dependency view at program/portfolio level; normalize dependency data across approaches; single dependency board regardless of team methodology |
| **Circular dependencies** | Two items depend on each other; no progress possible without one going first | Poor decomposition; tightly coupled architecture; interface not defined | Break cycle: define interface contract, build to contract independently; or merge items; or decompose differently |
