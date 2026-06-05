# Readiness Checklist Reference

## Purpose

This reference defines the go-live readiness assessment dimensions, ADKAR readiness
scoring, RAG thresholds, and Go/No-Go decision model. It is the authoritative source
for the change-management skill (Mode C) and artifact-generator when producing or
validating readiness checklists.

## Readiness Assessment Dimensions

Seven dimensions must be assessed before any production deployment. Each dimension
contains specific checklist items with defined evidence requirements.

### Dimension 1: Training Completion

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| All High/Critical severity groups have completed training | Training attendance records + knowledge assessment results | Green: 100% complete. Amber: >=80% complete, remainder scheduled before go-live. Red: <80% complete or unscheduled gaps. |
| Super user network is trained and operational | Super user roster + deep training completion + sandbox practice evidence | Green: All super users trained and practiced. Amber: >=90% trained, remainder in progress. Red: <90% trained or no super user network. |
| Kirkpatrick Level 2 (Learning) targets met | Knowledge assessment pass rates per group | Green: >=80% pass rate across all groups. Amber: 70-79% pass rate. Red: <70% pass rate. |
| Training prerequisite artifacts complete | SOPs, job aids, talk tracks, FAQ in final status | Green: All final. Amber: >=90% final, remainder in review. Red: <90% final or critical artifacts missing. |
| Experiential learning (70%) component delivered | Sandbox access logs, supervised practice records | Green: All High/Critical groups had sandbox practice. Amber: Practice scheduled but not all complete. Red: No sandbox/practice provided. |

### Dimension 2: Communication Sent

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| All planned communications sent per schedule | Comms tracker with sent dates and confirmation | Green: 100% of scheduled comms sent. Amber: >=90% sent, remainder scheduled. Red: <90% sent or key audiences missed. |
| Executive sponsor messaging delivered | Sponsor communication records (email, town hall, video) | Green: Sponsor communicated to all impacted groups. Amber: Sponsor communicated to High/Critical groups only. Red: No sponsor messaging delivered. |
| WIIFM (What's In It For Me) addressed per audience | Audience-specific WIIFM content in comms | Green: All groups received role-specific WIIFM. Amber: Generic WIIFM sent; not role-specific. Red: No WIIFM communication. |
| J-curve expectation set with executives | Executive briefing on productivity dip expectations | Green: Executives briefed on J-curve and planned response. Amber: Executives aware but no formal briefing. Red: Executives not prepared for productivity dip. |

### Dimension 3: Support Model Active

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| Hypercare plan approved | Signed hypercare plan with timeline, escalation paths, exit criteria | Green: Plan approved by project sponsor. Amber: Plan drafted, not yet approved. Red: No hypercare plan exists. |
| Escalation path documented and communicated | Escalation matrix with L1/L2/L3 contacts, SLAs, and communication channels | Green: Escalation path documented, communicated to all support staff, and tested. Amber: Documented but not yet communicated or tested. Red: Not documented. |
| Super users deployed at go-live ratio | Super user schedule for go-live period at 1:8 ratio | Green: Schedule confirmed, super users committed. Amber: Schedule drafted, some availability gaps. Red: No go-live super user schedule. |
| Support channels configured | Help desk, Slack/Teams channels, ticketing system ready | Green: All channels active and tested. Amber: Channels configured but not tested. Red: Channels not configured. |

### Dimension 4: Stakeholder Signoff

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| Go/No-Go attendees identified | Attendee list with roles and decision authority | Green: All required attendees confirmed. Amber: >=80% confirmed. Red: <80% confirmed or key decision-makers missing. |
| Decision criteria documented | Written criteria for Go, Conditional Go, and No-Go outcomes | Green: Criteria documented and shared with attendees. Amber: Criteria drafted but not shared. Red: No decision criteria exist. |
| Sponsor commitment confirmed | Sponsor availability for go-live window and first week post-go-live | Green: Sponsor committed and scheduled. Amber: Sponsor aware but not formally committed. Red: Sponsor unavailable. |
| Functional lead signoff obtained | Written approval from each functional area lead | Green: All functional leads signed off. Amber: >=80% signed off, remainder in progress. Red: <80% signed off. |

### Dimension 5: Technical Readiness

These items integrate with delivery engine outputs. When delivery engine has produced
cutover plans and environment readiness assessments, use them as [SOURCE].

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| Zero open Critical (S1) defects | Defect log showing S1 count = 0 | Green: Zero S1. Red: Any open S1 (no Amber -- this is binary). |
| Zero open High (S2) defects (or approved exceptions) | Defect log showing S2 count = 0, or exception approvals with documented workarounds | Green: Zero S2. Amber: S2 defects exist with approved exceptions and documented workarounds. Red: S2 defects without exceptions. |
| Security review complete | Security review report with sign-off | Green: Complete, no critical findings. Amber: Complete with medium findings being remediated. Red: Not complete or critical findings open. |
| Data integrity verification complete | Data validation report | Green: All data verified. Amber: >=95% verified, remainder in progress. Red: <95% verified. |
| Backup before deployment confirmed | Backup schedule and verification plan | Green: Backup scheduled and procedure tested. Amber: Backup scheduled but not tested. Red: No backup plan. |
| Rollback plan exists and is tested | Documented rollback procedure with test results | Green: Rollback tested successfully. Amber: Rollback documented but not tested. Red: No rollback plan. |
| Post-deployment monitoring configured | Monitoring dashboard, alert thresholds, on-call schedule | Green: Monitoring active and tested. Amber: Monitoring configured but not tested. Red: Not configured. |
| Senior engineer code review complete | Review records showing >=1 senior engineer review | Green: Complete. Red: Not complete (no Amber -- this is binary). |
| 100% regression test pass | Automated regression test results | Green: 100% pass. Amber: >=98% pass with known exceptions. Red: <98% pass. |

**Non-negotiable gates (never compress, even in emergencies):**
1. Security review
2. Data integrity verification
3. Backup before deployment
4. Rollback plan existence
5. >=1 senior engineer code review
6. Post-deployment monitoring configured

### Dimension 6: Data Readiness

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| Data migration validated | Migration validation report with record counts and integrity checks | Green: All data migrated and validated. Amber: >=95% validated, known exceptions documented. Red: <95% validated. |
| Data cutover plan documented | Step-by-step cutover procedure with timing and rollback | Green: Plan documented, reviewed, and rehearsed. Amber: Plan documented but not rehearsed. Red: No plan. |
| Reference data synchronized | Cross-system reference data validation | Green: All reference data synchronized. Amber: Minor discrepancies with remediation plan. Red: Significant discrepancies. |

### Dimension 7: Process Readiness

| Checklist Item | Evidence Required | RAG Threshold |
|---------------|------------------|---------------|
| SOPs updated for new processes | SOP documents in final status | Green: All SOPs final and distributed. Amber: >=90% final. Red: <90% final. |
| Job aids distributed | Distribution records | Green: All job aids distributed to impacted groups. Amber: Distributed to High/Critical groups; others pending. Red: Not distributed. |
| New terminology communicated | Glossary distributed; terminology used in all training materials | Green: Glossary final and distributed. Amber: Glossary drafted, not yet distributed. Red: No glossary. |
| Process handoff points validated | End-to-end process testing with real-world scenarios | Green: All handoff points tested successfully. Amber: >=80% tested. Red: <80% tested. |

## ADKAR Readiness Scoring

For each stakeholder group, score ADKAR elements 1-5. The barrier point is the first
element scoring <=3.

### Scoring Guide

| Score | Label | Observable Indicators |
|-------|-------|----------------------|
| 5 | **Strong** | Active advocacy; consistent demonstration; no regression risk |
| 4 | **Adequate** | Meets threshold; functional capability; minor gaps manageable |
| 3 | **Borderline** | Inconsistent; requires active support to maintain; at risk under pressure |
| 2 | **Weak** | Significant gaps; frequently reverts; requires intensive intervention |
| 1 | **Absent** | No evidence of this element; foundational work required |

### Barrier Point Decision Logic

```
FOR each stakeholder group:
  Score Awareness (1-5)
  Score Desire (1-5)
  Score Knowledge (1-5)
  Score Ability (1-5)
  Score Reinforcement (1-5)

  barrier_point = first element where score <= 3

  IF barrier_point exists:
    READINESS = NOT READY for go-live (address barrier point first)
    ACTION = interventions specific to the barrier element
  ELSE IF any element = 4:
    READINESS = CONDITIONAL (monitor closely; support plan required)
    ACTION = targeted support for elements at 4
  ELSE (all elements >= 5):
    READINESS = READY
```

**Critical rule:** Address the barrier point BEFORE investing in later elements.
A group scoring Awareness=5, Desire=2, Knowledge=4, Ability=3, Reinforcement=1
has a barrier point at Desire. All Knowledge training delivered to this group is
wasted until Desire is addressed.

### ADKAR Readiness Summary Table (Template)

| Stakeholder Group | A | D | K | Ab | R | Barrier Point | Readiness | Required Action |
|-------------------|---|---|---|----|----|--------------|-----------|-----------------|
| [Group] | 1-5 | 1-5 | 1-5 | 1-5 | 1-5 | Element or "None" | Ready/Conditional/Not Ready | Specific intervention |

## RAG Threshold Framework

### Overall Dimension RAG

Each dimension receives an overall RAG based on its individual items:

| RAG | Rule |
|-----|------|
| **Green** | All items within the dimension are Green |
| **Amber** | No items are Red, but at least one item is Amber |
| **Red** | Any item within the dimension is Red |

### Overall Readiness RAG

| RAG | Rule |
|-----|------|
| **Green** | All 7 dimensions are Green |
| **Amber** | No dimensions are Red, but at least one is Amber |
| **Red** | Any dimension is Red |

## Go / Conditional Go / No-Go Decision Model

### Decision Criteria

| Decision | Criteria | Required Actions |
|----------|---------|-----------------|
| **Go** | All 7 dimensions Green. All ADKAR groups Ready or Conditional with support plans. All non-negotiable technical gates passed. Sponsor approves. | Proceed to deployment per cutover plan. Activate hypercare. |
| **Conditional Go** | No dimensions Red. Some dimensions Amber with documented remediation plans and committed completion dates before or within 48 hours of go-live. All non-negotiable technical gates passed. Sponsor approves with conditions. | Proceed with conditions: remediation items tracked daily; escalation if conditions not met by committed dates; go/no-go recheck at T-24 hours. |
| **No-Go** | Any dimension Red. OR any non-negotiable technical gate not passed. OR ADKAR barrier point at Desire or Awareness for any High/Critical severity group. OR sponsor does not approve. | Halt deployment. Identify critical path to readiness. Reschedule go-live. Communicate delay to stakeholders. |

### Decision Authority

| Role | Authority |
|------|----------|
| **Project Sponsor** | Final Go/No-Go authority. Cannot be overridden by project team. |
| **Project Manager/TPM** | Recommends decision based on readiness evidence. Presents readiness assessment. |
| **Functional Leads** | Sign off on their domain readiness. Can veto within their domain. |
| **Technical Lead** | Signs off on technical readiness. Can veto on non-negotiable gates. |
| **Change Management Lead** | Signs off on OCM readiness (training, comms, support, ADKAR). Recommends on people readiness. |

### Escalation Rules

| Situation | Escalation Path |
|-----------|----------------|
| Disagreement on readiness RAG | Escalate to project sponsor with evidence from both sides |
| Non-negotiable gate not met | No escalation available -- gate must be met. Escalate timeline impact to sponsor. |
| Sponsor unavailable for decision | Escalate to sponsor's delegate (must be pre-identified in project charter) |
| Conditional Go conditions not met by committed date | Automatic escalation to sponsor for re-decision (Go or No-Go) |

## Readiness Verdict Output Format

### Summary Block (Required)

```
OVERALL READINESS: [GO / CONDITIONAL GO / NO-GO]
Assessment Date: [Date]
Go-Live Target: [Date]
Assessed By: [Name/Role]

Dimension Summary:
  Training Completion:    [GREEN/AMBER/RED]
  Communication Sent:     [GREEN/AMBER/RED]
  Support Model Active:   [GREEN/AMBER/RED]
  Stakeholder Signoff:    [GREEN/AMBER/RED]
  Technical Readiness:    [GREEN/AMBER/RED]
  Data Readiness:         [GREEN/AMBER/RED]
  Process Readiness:      [GREEN/AMBER/RED]

Non-Negotiable Gates: [X/6 PASSED]
ADKAR Groups Ready:   [X/N READY, Y CONDITIONAL, Z NOT READY]
```

### Remediation Plan (Required for Amber/Red Items)

| Item | Current Status | Required Action | Owner | Deadline | Escalation If Missed |
|------|---------------|----------------|-------|----------|---------------------|
| [Item] | Amber/Red | Specific action | [Name] | [Date] | [Escalation path] |

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **Readiness theater** | All items marked READY without evidence; checklist completed in a single meeting | Checklist treated as a compliance exercise rather than a genuine assessment | Require evidence source for every READY item; independent verification of critical items |
| **Declaring victory at go-live** | Support removed at deployment; adoption metrics not tracked; "project complete" at go-live | Confusing deployment with adoption; project mentality vs. product mentality | Track adoption metrics through T+8 weeks minimum; maintain champion network through valley of despair |
| **Compressing non-negotiable gates** | Schedule pressure leads to skipping security review, untested rollback, or no monitoring | Gates perceived as bureaucracy rather than risk management | Non-negotiable gates listed above cannot compress; gate skip = automatic No-Go |
| **Ignoring ADKAR barrier points** | Groups with Desire <=3 sent to training anyway; low adoption post-go-live | Treating readiness as a checklist rather than a diagnostic | Run ADKAR assessment per group; address barrier points before downstream activities |
| **Unanimous Green without challenge** | All dimensions Green on first assessment; no Amber items found | Assessment conducted by people too close to the project; confirmation bias | Include at least one independent reviewer; compare against baseline readiness from similar past projects |

## Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|-----------|-------------------|----------------|
| **Readiness assessment** | Uses evidence-based assessment with verifiable sources per item; challenges Green ratings without evidence; includes independent review | Accepts self-reported readiness; does not require evidence; checks boxes without verification |
| **Go/No-Go governance** | Enforces non-negotiable gates without exception; uses structured decision model; educates executives about J-curve before go-live | Allows gates to compress under pressure; does not distinguish non-negotiable from flexible items |
| **ADKAR integration** | Runs barrier point assessment per group; blocks training for groups with Desire <=3; addresses barrier before advancing | Skips ADKAR assessment; treats all groups as equally ready; sends resistant groups to training |
| **Post-go-live planning** | Plans support ramp matching valley of despair timing (peak at week 2); does not reduce support before T+4 weeks | Panics at productivity dip; pulls support at week 2; declares success at go-live |
| **Remediation rigor** | Every Amber/Red item has specific action, owner, deadline, and escalation path; tracks daily during go-live window | Flags items as "at risk" without specific remediation; no ownership or deadlines for resolution |
