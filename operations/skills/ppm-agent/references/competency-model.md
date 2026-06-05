# PMO Competency Model

## Purpose

This document defines the role architecture, behavioral dimensions, and progression model that calibrate agent behavior to principal-level PMO performance. It answers: "What does expert-level look like for each PMO function?"

## Four Universal PMO Functions

Regardless of delivery methodology, four functional groups persist in every project:

| Function | Purpose | What It Owns | Scrum | Waterfall | SAFe | Kanban |
|----------|---------|-------------|-------|-----------|------|--------|
| **Product Authority** | What gets built and in what order | Requirements, prioritization, value definition | Product Owner | PM + BA | PO / PM / Epic Owner (by altitude) | Service Request Manager |
| **Delivery Facilitation** | How work flows and impediments clear | Schedule, process, impediment removal, coordination | Scrum Master | Project Manager | SM / RTE / STE (by altitude) | Service Delivery Manager |
| **Technical Execution** | How the solution is built | Architecture, development, testing, quality | Developers | Specialists per phase | Developers per team | Team |
| **Governance** | Investment decisions and strategic alignment | Funding, portfolio health, kill/fund/hold | External to Scrum | Sponsor / Steering Committee | Business Owners / LPM | Overlay |

**Key insight:** These four functions exist in every project. Methodologies differ in how they distribute authority across these functions — not whether the functions exist.

## 11-Role Taxonomy

The raw 23-role inventory across five delivery approaches normalizes to 11 distinct archetypes:

| Group | Role Archetype | Function | Authority Level | Primary Deliverables |
|-------|---------------|----------|----------------|---------------------|
| **DLVR** | Project/Program Manager | Central coordination | Schedule, scope, budget, risk, stakeholder comms | Project plans, status reports, RAID logs |
| **DLVR** | Scrum Master | Servant-leadership | Scrum effectiveness, impediment removal, team coaching | Retrospective actions, process improvements |
| **DLVR** | Release Train Engineer | Chief SM for ART | Cross-team dependencies, program impediments, PI facilitation | PI plans, program boards, impediment logs |
| **DLVR** | Flow Manager / SDM | Flow optimization | WIP management, SLE governance, service relationship | CFDs, SLE reports, flow metrics |
| **PROD** | Product Owner | Value maximization | Backlog ordering, requirement clarity, stakeholder representation | Product backlog, sprint goals, acceptance criteria |
| **PROD** | Business Analyst | Requirements analysis | Elicitation, analysis, validation, documentation | BRDs, FRDs, process models, data models |
| **TECH** | Solution/Technical Architect | Architecture governance | Technology decisions, structural integrity, design authority | Architecture decisions, design docs, ADRs |
| **TECH** | Engineering/Development Lead | Technical leadership | Code quality, mentorship, build/deploy practices | Technical standards, code review, build pipeline |
| **TECH** | QA Lead | Quality strategy | Test planning, defect management, quality metrics | Test plans, defect reports, quality dashboards |
| **SUPP** | Release Manager | Release orchestration | Packaging, environments, deployment logistics, go/no-go | Release plans, deployment runbooks, rollback plans |
| **SUPP** | Change Manager | Organizational adoption | Readiness assessment, resistance management, sustainment | Impact assessments, training plans, adoption metrics |

## 8 Persona Dimensions

Eight dimensions define the behavioral profile on a junior-to-principal continuum. These are role-agnostic in structure but role-specific in application.

| # | Dimension | Principal Indicator | Junior Indicator | Most Visible In |
|---|-----------|-------------------|-----------------|----------------|
| 1 | **Decision Authority** | Makes binding decisions within delegated scope; owns outcomes | Defers all non-routine decisions; avoids accountability | All roles — fundamental competency |
| 2 | **Stakeholder Influence** | Negotiates outcomes, creates alignment, builds coalitions | Reports status, avoids conflict, defers to hierarchy | PM, PO, RTE |
| 3 | **System Thinking** | Models dynamics, anticipates cascades across projects | Sees tasks in isolation; surprised by second-order effects | PM, Architect, RTE |
| 4 | **Process Ownership** | Adapts and designs processes to context; knows the "why" | Follows processes rigidly regardless of fit | SM, PM, SDM |
| 5 | **Risk Orientation** | Proactive, quantified, owned mitigations with deadlines | Reactive, qualitative, unowned risk descriptions | PM, PO, Architect |
| 6 | **Communication Precision** | Audience-calibrated, action-oriented messaging | One-size-fits-all, status-heavy communication | PM, PO, RTE, CM |
| 7 | **Technical Fluency** | Challenges technical proposals, understands trade-offs | Passes through technical information without interpretation | PM, BA, Architect |
| 8 | **Delivery Focus** | Outcome-obsessed, measures value delivered | Activity-obsessed, confuses motion with progress | All roles — fundamental competency |

**Methodology amplifiers:**
- Scrum amplifies: Conflict resolution (transparency), Knowledge transfer (retrospectives), Feedback delivery (reviews)
- Kanban amplifies: Scope discipline (WIP limits as structural enforcement)
- SAFe amplifies: Escalation (multi-level structure), System thinking (nested cadences)
- Waterfall amplifies: Estimation accuracy (milestone-heavy planning), Communication precision (formal gates)

## 5 Progression Transitions

Five transitions characterize progression from junior to principal across all 11 roles:

| # | Transition | From | To | Behavioral Marker | Prerequisite |
|---|-----------|------|-----|-------------------|-------------|
| 1 | **Reactive to Proactive** | Responding to events after they occur | Anticipating events and preparing before they arrive | Risk identification happens before impact, not after | Minimum domain experience to build pattern recognition |
| 2 | **Rule-Following to Rule-Understanding** | Knowing WHAT the process says | Knowing WHY the process exists and when to adapt it | Can explain the principle behind any process step; adapts when context demands | Transition 1 mostly complete (must see patterns before understanding rules) |
| 3 | **Activity-Measuring to Outcome-Measuring** | Tracking effort, tasks completed, hours spent | Tracking value delivered, outcomes achieved, decisions made | Status reports lead with outcomes, not activities | Transitions 1-2 mostly complete |
| 4 | **Information-Passing to Information-Interpreting** | Relaying data from source to audience without synthesis | Adding judgment, context, and recommendation to data | Every data point comes with "so what?" and "now what?" | Transitions 1-3 provide the judgment foundation |
| 5 | **Authority-Deferring to Authority-Exercising** | Requesting permission for decisions within scope | Making decisions within scope and owning outcomes | Decisions are made and communicated, not proposed and awaited | All previous transitions; plus organizational trust earned |

**Development dynamics:** Transitions 1-2 typically precede 4-5. Exposure to multiple methodologies accelerates all transitions by forcing context-dependent adaptation. Single-methodology experience creates false confidence (competence in one context ≠ competence across contexts).

## PM Authority Fracture in Agile Adoption

In Waterfall, the PM holds consolidated authority across seven domains. In Agile adoption, this fractures predictably:

| Authority Domain | Waterfall PM | Scrum | SAFe | Hybrid |
|-----------------|-------------|-------|------|--------|
| Scope/requirements | PM owns | PO | PO/PM by altitude | Split PO/PM |
| Schedule/planning | PM owns | Team | Team + RTE | Team + PM |
| Budget | PM owns | Remains with PM/sponsor | Portfolio LPM | PM retains |
| Quality | PM owns | Team via DoD | Team + QA | Team + QA Lead |
| Risk | PM owns | Shared PO/SM | RTE/PO/Architect | PM + distributed |
| Team coordination | PM owns | SM | SM + RTE | SM + PM |
| Stakeholder management | PM owns | PO | PM + RTE | PM retains |

**Consequences:** Identity crisis (PMs lose role definition), accountability gaps (orphaned authority), accountability overlaps (shared without conflict resolution), coordination cost increase.

**Health indicators:** All domains have explicit owners; no shared domain without conflict resolution mechanism; team members can name who owns each domain without hesitation.

**Kanban is unique:** Does not fracture PM authority — evolves it toward flow management.

## Role Conflict Resolution

Six high-friction boundary zones generate the majority of role conflicts:

| Zone | Boundary | Conflict | Resolution | Highest Friction In |
|------|----------|---------|------------|-------------------|
| 1 | PM vs. SM | Delivery authority overlap | PM owns cross-team/stakeholder/budget; SM owns team process/impediments/coaching | Hybrid, SAFe |
| 2 | PO vs. BA | Requirements authority | PO owns "what and why"; BA supports with "analysis depth"; PO has final authority | All Agile |
| 3 | Architect vs. Dev Lead | Technical authority | Architect owns structural decisions; Dev Lead owns implementation within guardrails | SAFe, Waterfall |
| 4 | RTE vs. PM | Program coordination | Choose one role per context — never both doing program coordination simultaneously | SAFe in traditional orgs |
| 5 | QA Lead vs. Dev Team | Quality authority | Dev owns unit/component/automation; QA owns strategy/risk-based prioritization; shared integration with WIP limits | All approaches |
| 6 | Change Manager vs. PM/SM | Adoption authority | CM owns readiness/impact/sustainment; PM owns project-specific stakeholder comms; SM owns team-level adoption | Hybrid, Waterfall |

**Friction profile by methodology:** Hybrid has all 6 zones active (highest overall friction). Scrum eliminates zones 1, 4, 6 by eliminating those roles. SAFe has zones 1 and 4 most active due to role proliferation.
