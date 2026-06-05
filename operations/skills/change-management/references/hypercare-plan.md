# Hypercare Plan Reference

## Purpose

This reference defines the dual-faceted hypercare model, support escalation structure,
T-minus timeline, exit criteria, and super user activation protocol. It is the
authoritative source for the change-management skill (Mode D) and artifact-generator
when producing or validating hypercare plans.

## Dual-Faceted Hypercare Model

Hypercare is NOT just technical support. It is a dual-faceted phase requiring both
technical issue resolution AND organizational change reinforcement operating in
parallel.

| Facet | Owner | Focus | Mechanisms | Without This Facet |
|-------|-------|-------|-----------|-------------------|
| **Technical Support** | IT/Technical Lead | System stability, defect resolution, performance monitoring, incident management | 3-tier escalation, SLA-driven response, monitoring dashboards, incident triage | System issues go unresolved; user frustration compounds adoption resistance |
| **OCM Reinforcement** | Change Management Lead | Adoption reinforcement, behavior change sustainability, emotional support through transition | Super user floor support, ADKAR Reinforcement activities, coaching, recognition, feedback loops | Users revert to old behaviors; adoption plateaus; productivity dip extends from weeks to months |

**CF-017 design principle:** Technical support resolves what is broken. OCM
reinforcement ensures what is working gets adopted. Both facets must be planned,
staffed, and governed independently -- then coordinated through a unified hypercare
governance structure.

## 3-Tier Support Escalation Model

### Tier Definitions

| Tier | Staffing | Scope | SLA Target | Escalation Trigger |
|------|---------|-------|-----------|-------------------|
| **Tier 1 (Floor Support)** | Super users + designated floor support staff | First-contact resolution: how-to questions, navigation help, process clarification, known-issue workarounds | Response: immediate (minutes). Resolution: within 1 hour. | Issue requires system access, configuration change, or is not in known-issue list |
| **Tier 2 (Functional/Technical Support)** | Functional leads + application support team | Configuration issues, data corrections, process exceptions, defect workarounds | Response: within 1 hour. Resolution: within 4 hours (standard) / 2 hours (critical). | Issue requires vendor engagement, code change, or impacts multiple users/processes |
| **Tier 3 (Vendor/Engineering)** | Vendor support + development team + infrastructure team | System defects, performance issues, integration failures, data integrity problems | Response: within 2 hours. Resolution: per severity SLA (S1: immediate, S2: within sprint, S3: next sprint). | Issue requires product fix, infrastructure change, or vendor patch |

### Escalation SLA by Severity

| Severity | Tier 1 Response | Tier 2 Response | Tier 3 Response | Resolution Target |
|----------|----------------|-----------------|-----------------|------------------|
| **S1 (Critical)** | Immediate + escalate to Tier 2 | Within 15 minutes | Within 1 hour | ASAP; all-hands until resolved; war room activated |
| **S2 (High)** | Within 15 minutes | Within 1 hour | Within 2 hours | Within 1 business day |
| **S3 (Medium)** | Within 1 hour | Within 4 hours | Within 1 business day | Within 1 sprint |
| **S4 (Low)** | Within 4 hours | Within 1 business day | Backlog | Scheduled in backlog |

**Reference statistic:** Expect 3-5 critical issues per Tier 1 deployment (historical
average). Plan for this volume -- do not assume zero critical issues.

### Escalation Path Template

```
User encounters issue
  → Tier 1 (Super User / Floor Support)
    [Resolved?] → YES → Log and close
    [Resolved?] → NO → Escalate to Tier 2 with:
      - Issue description
      - Steps to reproduce
      - Business impact
      - Workaround attempted
  → Tier 2 (Functional/Technical Support)
    [Resolved?] → YES → Log, close, update known-issue list
    [Resolved?] → NO → Escalate to Tier 3 with:
      - Full diagnostic information
      - Business impact assessment
      - Workaround status
  → Tier 3 (Vendor/Engineering)
    [Resolved?] → YES → Log, close, update knowledge base, communicate fix
    [Resolved?] → NO → War room activation (S1) or backlog prioritization (S2-S4)
```

## T-Minus Timeline

### Pre-Go-Live Preparation

| Timing | Activity | Owner | Deliverable |
|--------|---------|-------|------------|
| **T-4 weeks** | Hypercare plan drafted; support team identified; escalation paths defined | CM Lead + Technical Lead | Draft hypercare plan |
| **T-3 weeks** | Super users confirm go-live availability; support channel setup begins | CM Lead | Super user schedule; channel configuration |
| **T-2 weeks** | Hypercare plan approved; support team briefed; known-issue list seeded from UAT | Project Sponsor | Approved hypercare plan |
| **T-1 week** | Dry run of escalation paths; monitoring dashboards configured; war room logistics confirmed | Technical Lead | Tested escalation; active monitoring |
| **T-1 day** | Final readiness check; all support staff confirmed; communication channels tested | PM/TPM | Final readiness confirmation |

### Go-Live Through Exit

| Phase | Timing | Governance Cadence | Support Level | OCM Activities |
|-------|--------|-------------------|---------------|---------------|
| **Intensive** | Go-live through T+2 weeks | Daily standup (15 min) + daily review (30 min) | Maximum: super users at 1:8 ratio; Tier 2 on standby; Tier 3 on-call | Floor presence; real-time coaching; feedback collection; daily issue triage; ADKAR Reinforcement check |
| **Stabilization** | T+2 through T+4 weeks | Daily standup; weekly review replaces daily review | Moderate: super users at 1:15-25 ratio; Tier 2 normal hours; Tier 3 standard SLA | Targeted coaching for struggling groups; recognition for early adopters; process refinement based on feedback |
| **Transition** | T+4 through T+8 weeks | Weekly review only | Reduced: super users at 1:25-50 ratio; Tier 2 on-demand; Tier 3 standard SLA | CoP model activation; onboarding materials finalized; steady-state support documentation |
| **Exit** | T+8+ (or when exit criteria met) | Biweekly review, then close | BAU support model | Formal hypercare close; lessons learned; adoption metrics baseline established |

**Critical rule:** Do NOT scale back support at week 2 post-go-live. Week 2 is the
peak disruption window (valley of despair). Scaling back support at the point of
maximum need extends the recovery period from 60-90 days to 6-12 months.

### Valley of Despair Parameters

| Parameter | Standard Deployment | Complex Deployment (ERP/EHR) |
|-----------|-------------------|---------------------------|
| Productivity dip magnitude | 10-25% | 40-60% |
| Peak disruption timing | Approximately week 2 | Week 2-4 |
| Recovery with structured CM | 60-90 days | 90-120 days |
| Recovery without structured CM | 6-12 months | 12-18 months |
| Executive preparation | Briefed on J-curve before go-live | Briefed with quantified impact projections |

## Exit Criteria

Hypercare exits when ALL of the following criteria are met. No single criterion
can be waived without sponsor approval and documented rationale.

### Quantitative Exit Criteria

| Criterion | Metric | Threshold | Measurement Method |
|-----------|--------|-----------|-------------------|
| **Incident rate trending down** | Support tickets per day/week | Declining trend for 2 consecutive weeks; current rate within 120% of pre-change baseline (or projected steady-state) | Ticketing system trend analysis |
| **Adoption rate at target** | Daily Active Users / Expected Users | >= 80% adoption rate sustained for 2 consecutive weeks | System usage analytics |
| **Proficiency targets met** | Task completion time (new process) | Within 125% of target time for >=70% of users | Time-motion observation or system telemetry |
| **Error rate acceptable** | Error count per transaction type | Declining trend; current rate within defined threshold per process | System error logs; quality audits |
| **Support ticket volume trending** | New tickets per day | Declining trend for 2 consecutive weeks; no S1 open; S2 count within threshold | Ticketing system |
| **System stability confirmed** | Uptime, performance, integration health | >=99.5% uptime; response times within SLA; no degraded integrations | Monitoring dashboard |
| **BAU team ready** | BAU support team staffed, trained, and handling tickets independently | BAU team resolving >=80% of Tier 1/2 tickets without escalation to project team | Ticket resolution attribution |

### Qualitative Exit Criteria

| Criterion | Assessment Method | Threshold |
|-----------|------------------|-----------|
| **Super user confidence** | Super user survey or interviews | >=80% report confidence in supporting users independently |
| **Functional lead satisfaction** | Functional lead feedback | All functional leads agree their team is operating in new process |
| **No open critical process gaps** | Process gap register | Zero open critical gaps; medium gaps have remediation plans |

### Exit Decision Model

```
IF all quantitative criteria met
  AND all qualitative criteria met
  AND sponsor approves
THEN → EXIT HYPERCARE → Transition to BAU support model

IF most criteria met but 1-2 quantitative criteria borderline
  AND sponsor approves with conditions
THEN → CONDITIONAL EXIT → Extend monitoring for 2 weeks; re-assess

IF any critical criterion not met (S1 open, adoption <60%, error rate increasing)
THEN → EXTEND HYPERCARE → Address root cause; re-assess in 1 week
```

## Super User Activation Protocol

### Go-Live Activation

| Activity | Timing | Detail |
|---------|--------|--------|
| **Pre-positioning** | T-1 day | Super users assigned to physical/virtual locations; schedules confirmed; communication channels tested |
| **Briefing** | T-1 day (afternoon) | Final briefing: known issues, escalation paths, hot spots, first-hour priorities |
| **Go-live coverage** | T+0 | Super users at stations before first users arrive; 1:8 ratio active |
| **Daily debrief** | T+0 through T+14 | End-of-day debrief: issues encountered, patterns observed, morale assessment, next-day priorities |
| **Issue feed** | Continuous | Super users feed issues to Tier 2 with standardized format (description, steps, impact, workaround) |
| **Adoption observation** | Continuous | Super users report adoption signals: who is using new process, who is reverting, what is confusing |

### ADKAR Reinforcement Activities (OCM Facet)

| Timing | Activity | Purpose | Owner |
|--------|---------|---------|-------|
| **T+1 day** | Quick wins communication | Highlight early successes; build momentum | CM Lead |
| **T+3 days** | Floor observation debrief | Identify where users are struggling; adjust support | Super Users + CM Lead |
| **T+1 week** | First-week retrospective | Capture lessons; adjust hypercare plan if needed | PM/TPM + CM Lead |
| **T+2 weeks** | Recognition event | Celebrate adoption milestones; reinforce new behaviors | Sponsor + CM Lead |
| **T+2-4 weeks** | Targeted coaching | Focus on groups still at ADKAR Ability barrier | Super Users |
| **T+4 weeks** | Adoption metrics review | Quantitative assessment of behavior change | CM Lead |
| **T+8 weeks** | Reinforcement check | Verify no backsliding; onboarding integration confirmed | CM Lead |

## Methodology Variation for Hypercare Duration

| Methodology | Hypercare Duration | Rationale | Governance Model |
|-------------|-------------------|-----------|-----------------|
| **Waterfall** | 2-4 weeks (standard); up to 12 weeks (complex ERP/EHR) | Big-bang deployment creates single high-intensity hypercare period | Daily reviews stepping down to weekly |
| **Scrum** | 1-2 sprints post-release | Incremental releases reduce per-release hypercare intensity | Sprint ceremonies provide built-in feedback loops |
| **SAFe** | 1 PI boundary (or IP iteration) | PI-cadenced releases align hypercare to PI rhythm; IP iteration absorbs hypercare activities | ART-level monitoring; I&A as hypercare retrospective |
| **Kanban** | Continuous (no discrete hypercare period) | Continuous deployment means continuous support; no "go-live" event | Service Delivery Reviews monitor adoption continuously |
| **PRINCE2** | Per stage boundary; defined in Benefits Management Approach | Stage-based delivery creates discrete hypercare windows per stage | Stage boundary review includes benefits realization check |
| **Hybrid** | Varies by stream: sprint-based for agile components, phase-based for waterfall components | Dual hypercare model matching dual delivery model | Integration sprint reviews + phase gate reviews |
| **Lean** | Ongoing (gemba-based); no discrete period | Continuous improvement culture means ongoing support is the norm | Daily gemba; obeya room coordination |

## Hypercare Plan Schema (Mode D Output)

### Required Sections

| Section | Content | Source |
|---------|---------|--------|
| **Hypercare Window** | Start date, end date, phase durations (Intensive/Stabilization/Transition/Exit) | Project timeline + methodology variation |
| **Support Model per Audience** | For each impacted group: support channel, Tier 1 contact, escalation path, known risk areas, monitoring indicators | Impact assessment + escalation model |
| **Escalation Matrix** | 3-tier model with contacts, SLAs, and escalation triggers per severity | This reference |
| **Exit Criteria** | Quantitative and qualitative criteria with thresholds and measurement methods | This reference |
| **Adoption KPIs** | Measurable indicators of behavior change per audience group | Impact assessment + ADKAR targets |
| **Hypercare Schedule** | Daily standups, review cadence, phase transitions | T-minus timeline |
| **Super User Deployment** | Roster, assignments, ratio, schedule, debrief cadence | Super user activation protocol |
| **OCM Reinforcement Plan** | ADKAR Reinforcement activities, recognition events, feedback mechanisms | OCM facet activities |

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **Technical-only hypercare** | Hypercare plan covers only defects and system issues; no OCM activities, no super user plan, no adoption tracking | Treating hypercare as a technical warranty period rather than a dual-faceted phase | Add OCM facet per CF-017: super user deployment, ADKAR Reinforcement activities, adoption KPIs, behavioral observation |
| **Support pullback at week 2** | Super user coverage reduced at T+2 weeks; help desk hours cut; daily standups stopped | Budget/resource pressure; misreading initial stability as sustained adoption | Week 2 is peak disruption. Maintain Intensive phase support through T+2 weeks minimum; step down to Stabilization only when incident trend confirms |
| **No exit criteria** | Hypercare has a fixed end date but no defined criteria for when it is safe to exit | Treating hypercare as a calendar period rather than a criteria-gated phase | Define quantitative exit criteria before go-live; do not exit until all criteria met |
| **Declaring victory at go-live** | Go-live celebrated as project completion; hypercare treated as afterthought | Project mentality (deliver and close) vs. product mentality (deliver and support) | 54% of major initiatives fail partly due to premature victory (Kotter). Track adoption through T+8 weeks minimum. |
| **SINO during hypercare** | Sponsor absent during hypercare; no executive reinforcement of new behaviors | Sponsor treats go-live as their endpoint; no defined sponsor hypercare obligations | Define sponsor hypercare activities: visible presence in first week, recognition at T+2 weeks, adoption review at T+4 weeks. 79% success with effective sponsors vs. 27% without. |
| **Flat support model** | Same support level from go-live through exit; no phase differentiation | No graduated support design; one-size-fits-all approach | Design Intensive/Stabilization/Transition/Exit phases with explicit step-down criteria |

## Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|-----------|-------------------|----------------|
| **Dual-facet design** | Plans both technical support AND OCM reinforcement as parallel workstreams with independent staffing, activities, and metrics | Plans only technical support; treats hypercare as a defect warranty period |
| **Valley preparation** | Educates executives about J-curve before go-live; designs support ramp matching valley timing (do not reduce at week 2) | Panics at productivity dip; interprets the valley as failure rather than expected transition; pulls support at week 2 |
| **Exit governance** | Defines quantitative exit criteria before go-live; does not exit until criteria met; uses data to justify extension when needed | Uses a fixed calendar period for hypercare; exits regardless of adoption state; declares success at the end date |
| **Super user activation** | Deploys super users at 1:8 ratio for go-live; runs daily debriefs; uses super user observations to adjust support plan | No super user deployment; relies entirely on help desk; no floor presence during critical first weeks |
| **Sponsor engagement** | Ensures sponsor is visibly present during first week; schedules recognition event; involves sponsor in adoption review | Does not involve sponsor during hypercare; sponsor presence ends at go-live |
