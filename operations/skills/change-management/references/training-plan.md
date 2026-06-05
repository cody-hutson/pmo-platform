# Training Plan Reference

## Purpose

This reference defines the training design model, needs assessment method, super user
network design criteria, and training effectiveness measurement framework. It is the
authoritative source for the change-management skill (Mode B) and artifact-generator
when producing or validating training plans.

## 70-20-10 Learning Design Model

Training effectiveness depends on designing across three learning channels in the
correct proportions:

| Channel | Proportion | Mechanism | Examples | Budget Allocation Error |
|---------|-----------|-----------|---------|----------------------|
| **Experiential (70%)** | 70% of learning | Hands-on use, real tasks, practice in production-like environments | Sandbox exercises, shadowing, supervised live transactions, structured on-the-job tasks | Most organizations leave this to chance |
| **Social (20%)** | 20% of learning | Peer coaching, mentoring, communities of practice, change champion interactions | Super user floor support, buddy systems, peer Q&A sessions, CoP meetings | Often unfunded; depends on champion network |
| **Formal (10%)** | 10% of learning | Classroom, eLearning, instructor-led training, certifications | Training sessions, eLearning modules, webinars, documentation walkthroughs | Organizations invest 90% of L&D budget here |

**Design rule:** A training plan that is 100% formal classroom sessions ignores the
70% and 20% channels where most learning actually occurs. Every training plan must
include deliberate design for all three channels.

### Channel Design by Impact Severity

| Impact Severity | Formal (10%) | Social (20%) | Experiential (70%) |
|----------------|-------------|-------------|-------------------|
| **Low (1)** | Email communication or FAQ | Peer mention at team meeting | Normal workflow with minor adjustment |
| **Medium (2)** | 30-min walkthrough or eLearning module | Super user available for questions | Guided first-use with job aid |
| **High (3)** | Half-day instructor-led session + eLearning | Dedicated super user on floor for 2 weeks post-go-live | Sandbox practice sessions + supervised live transactions for first week |
| **Critical (4)** | Multi-day instructor-led program + eLearning + certification | Dedicated coaching for 4+ weeks; champion network fully activated | Extended sandbox with realistic scenarios + supervised production use for 2-4 weeks + protected learning time |

## Training Needs Assessment Method

### Step 1: Derive from Impact Assessment

Training needs flow directly from the impact assessment. For each row in the impact
assessment table:

| Impact Assessment Field | Training Plan Field | Derivation |
|------------------------|--------------------|-----------|
| Impacted Audience | Training Audience | Direct mapping |
| Impact Severity (per dimension) | Training Depth | Severity determines formal/social/experiential mix |
| ADKAR Barrier Point | Training Sequencing | Barrier point determines what to address first |
| Current State / Future State | Training Content | The delta defines what must be learned |
| Impact Dimensions | Training Focus | Which dimensions scored highest determines training type |

### Step 2: ADKAR Sequencing Validation

Before investing in Knowledge training, validate that Awareness and Desire are
sufficient (score >= 4 on 1-5 scale). Training delivered to a group scoring <=3 on
Desire will not produce behavior change.

| ADKAR Readiness | Training Decision |
|----------------|------------------|
| Awareness <=3 | Do NOT schedule training yet. Run awareness campaign first (executive messaging, impact briefings, WIIFM sessions). |
| Desire <=3 | Do NOT schedule training yet. Run desire-building activities (involvement in design, address fears, WIIFM framing, peer champion engagement). |
| Awareness >=4, Desire >=4 | Clear to schedule Knowledge training. |
| Knowledge delivered, Ability <=3 | Add hands-on practice, coaching, shadowing, protected learning time. |
| All >=4 but Reinforcement <=3 | Post-go-live: add recognition, metrics tied to new behaviors, celebrations. |

### Step 3: Readiness Level Classification

| Readiness Level | Definition | Required Training Investment |
|----------------|-----------|----------------------------|
| **Training Required** | Impact severity >=3 on any dimension, OR role fundamentally changes | Full training program across all three channels |
| **Awareness Only** | Impact severity 1-2, AND role does not fundamentally change | Communication + documentation + super user availability |
| **No Action** | Not impacted by this change | None; exclude from training plan to avoid noise |

## Super User Network Design

### Decision: Super Users vs. Standard Training Only

| Factor | Invest in Super Users | Standard Training Sufficient |
|--------|----------------------|----------------------------|
| System complexity | High (ERP, EHR, custom platforms) | Low (SaaS with familiar UX) |
| User population | >50 impacted users | <50 impacted users |
| Process change severity | High (new workflows, role changes) | Low (same workflow, new tool) |
| Geographic distribution | Distributed (need local floor presence) | Co-located (central support works) |
| Go-live support model | Extended hypercare with floor support | Standard help desk adequate |

### Super User Selection Criteria

| Criterion | Requirement | Rationale |
|-----------|-----------|-----------|
| **Domain expertise** | Deep knowledge of business process being changed | Can answer "why" questions, not just "how" questions |
| **Peer credibility** | Respected by colleagues; opinion influences others | Selection by peer credibility, NOT by title or management appointment |
| **Positive influence** | Constructive attitude toward the change (Desire >=4) | Negative or neutral super users undermine adoption |
| **Availability** | Can commit time during training and go-live periods | Part-time super users are ineffective at critical moments |
| **Communication skill** | Can explain concepts clearly to varied audiences | Technical knowledge without communication skill limits reach |

**Critical rule:** Super users are business domain experts, NOT IT staff. They must
understand the business process context, not just the system mechanics.

### Super User Ratio Guidelines

| Context | Ratio (Super User: End Users) | Rationale |
|---------|-------------------------------|-----------|
| Standard deployment | 1:25 to 1:50 | Adequate for steady-state support |
| Complex system (ERP/EHR) | 1:15 to 1:25 | Higher complexity requires more accessible support |
| Go-live intensive period | 1:8 | Peak support need; floor presence critical |
| Post-hypercare steady state | 1:50 | Reduced need as proficiency stabilizes |

### Super User Engagement Timeline

| Phase | Timing | Activity |
|-------|--------|---------|
| **Selection** | 3-4 months before go-live | Identify candidates using selection criteria; secure manager approval for time commitment |
| **Deep Training** | 2-3 months before go-live | Train super users ahead of end users; deeper curriculum covering edge cases and troubleshooting |
| **Practice** | 1-2 months before go-live | Super users practice in sandbox; participate in UAT; develop job aids and FAQ |
| **End User Training Support** | 2-4 weeks before go-live | Super users co-facilitate training sessions; provide real-time coaching during practice |
| **Go-Live Floor Support** | Go-live through hypercare | Super users on floor at 1:8 ratio; first-line support before help desk escalation |
| **Steady State Transition** | Post-hypercare | Reduce ratio to 1:25-50; transition to CoP model; onboard new hires through super user mentoring |

## Training Effectiveness Measurement (Kirkpatrick 4-Level Model)

| Level | What It Measures | Method | When | Target |
|-------|-----------------|--------|------|--------|
| **Level 1: Reaction** | Did participants find the training valuable and relevant? | Post-training survey (satisfaction, relevance, engagement) | Immediately after training | >= 4.0/5.0 average satisfaction |
| **Level 2: Learning** | Did participants acquire the intended knowledge and skills? | Knowledge check, quiz, hands-on assessment, certification | End of training session or within 1 week | >= 80% pass rate on knowledge assessment |
| **Level 3: Behavior** | Are participants applying what they learned on the job? | Observation, supervisor assessment, system usage data, task completion time comparison | 2-4 weeks post-training (T+2 to T+4) | >= 70% demonstrating new behaviors consistently |
| **Level 4: Results** | Did the training produce the desired business outcomes? | Business metrics: error rates, processing time, adoption rates, support ticket volume | 4-8 weeks post-go-live (T+4 to T+8) | Error rates within acceptable thresholds; adoption rate >= 80% |

**Measurement priority:** Most organizations measure only Level 1 (reaction) and stop.
Principal-level training plans measure through Level 3 (behavior) at minimum and
define Level 4 (results) targets. Measuring only Level 1 is the training equivalent
of watermelon reporting -- satisfaction scores can be green while adoption is red.

## Training Needs Matrix Schema (Mode B Output)

### Required Fields per Training Row

| Field | Description | Required |
|-------|-----------|----------|
| Impacted Group | Specific stakeholder group from impact assessment | Yes |
| Group Lead/Owner | Person responsible for this group's training | Yes |
| Readiness Level | Training Required / Awareness Only / No Action | Yes |
| Training Content | Specific topics derived from current-to-future state delta (never "TBD") | Yes |
| Formal Component (10%) | Classroom, eLearning, documentation planned | Yes |
| Social Component (20%) | Super user support, buddy system, CoP access planned | Yes |
| Experiential Component (70%) | Sandbox access, supervised practice, on-the-job support planned | Yes |
| Owner | Who delivers or coordinates the training | Yes |
| Target Date | Linked to project milestone | Yes |
| Dependencies | What must complete before training (e.g., "UAT validated scenarios", "SOPs finalized") | Yes |
| ADKAR Readiness | Awareness/Desire scores confirm readiness for Knowledge training | Recommended |
| Effectiveness Measurement | Which Kirkpatrick levels will be measured and how | Recommended |
| CM Notes | Sequencing, audience-specific considerations | Recommended |

### Prerequisite Artifact Tracker (Required Output)

| Artifact | Status | Owner | Needed By | Dependent Training |
|----------|--------|-------|-----------|--------------------|
| [SOPs, job aids, talk tracks, FAQ, sandbox config, eLearning modules] | Draft / In Review / Final / Missing | [Owner] | [Date] | [Which training sessions depend on this] |

## Methodology Variation Table

| Methodology | Training Timing | Primary Mechanism | Training Cadence | Super User Role |
|-------------|----------------|------------------|-----------------|----------------|
| **Waterfall** | Front-loaded: 2-4 weeks pre-deployment | Instructor-led sessions + eLearning + UAT participation | One-time before go-live; refresher at go-live | Critical for go-live floor support |
| **Scrum** | JIT each sprint; formal in Sprint 0 | Sprint Review as built-in demo; targeted micro-training per feature | Per sprint for changed features | Ongoing; rotates with feature releases |
| **SAFe** | IP iteration (dedicated training cadence) | PI-aligned training waves; IP sprint reserved for learning | Every PI boundary; IP iteration is the training window | Embedded in ART; aligned to PI cadence |
| **PRINCE2** | Role-specific; aligned to stage boundaries | Product-based training per Work Package | Per stage; training validates Product Descriptions | Optional; depends on project scale |
| **Kanban** | On-demand; pulled when capacity allows | Training triggered by WIP item type | Continuous; no batch training cadence | Continuous support model; always available |
| **Hybrid** | Formal per stream timing; JIT reinforcement | Instructor-led for waterfall streams + sprint demos for agile streams | Dual cadence matching delivery streams | Supports both streams; bridges methodology gap |
| **Lean** | Ongoing coaching; TWI (Training Within Industry) methodology | Sensei model; experienced coach teaches through gemba practice; Shu-Ha-Ri learning progression | Continuous; daily coaching cycles | Part of leader standard work; 25% increase in frontline adoption |
| **XP** | Experienced coach required; pair programming as training | Coaching + pair programming (simultaneous delivery and learning) | Continuous; embedded in daily practice | N/A -- pairing replaces traditional super user model |

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **90/10 inversion** | 90%+ of training budget on classroom; no sandbox, no coaching, no super users | Organizations default to formal training because it is the most visible and measurable channel | Redesign with explicit 70-20-10 allocation; fund sandbox environments and super user time |
| **Training too early** | Training delivered 6+ weeks before go-live; users forget by go-live; retraining needed | Schedule-driven training placement; not aligned to go-live timeline | ADKAR sequencing: deliver Knowledge training 2-4 weeks before go-live; use Awareness/Desire activities for earlier engagement |
| **Training too late** | Training in final week before go-live; no practice time; users floundering at go-live | Training treated as checkbox; compressed by upstream delays | Build training dates into the project critical path; training delays = go-live delays |
| **% trained as success metric** | Track training attendance but not behavior change or proficiency | Measuring inputs (attendance) not outcomes (adoption) | Measure through Kirkpatrick Level 3 (behavior) minimum; define adoption KPIs at training design time |
| **Management-appointed super users** | Super users selected by management title rather than peer credibility | Confusion of organizational authority with peer influence | Use selection criteria table above; validate candidates have peer credibility and domain expertise |
| **Uniform training for all groups** | Same training curriculum regardless of impact severity or audience role | No stakeholder segmentation in training design | Derive training depth from impact severity per group; High/Critical severity groups get full 70-20-10 design |

## Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|-----------|-------------------|----------------|
| **Learning design** | Designs for 70-20-10 with deliberate activities in all three channels; allocates budget proportionally | Defaults to classroom training only; leaves experiential and social learning to chance |
| **ADKAR sequencing** | Validates Awareness and Desire scores before scheduling Knowledge training; addresses barrier points first | Schedules training without checking readiness; sends resistant groups to training expecting it to create desire |
| **Effectiveness measurement** | Defines Kirkpatrick Level 3/4 targets at training design time; measures behavior change post-training | Measures only Level 1 (satisfaction surveys); declares training successful based on attendance |
| **Super user design** | Selects for peer credibility with appropriate ratios; provides deeper training months before go-live; maintains weekly engagement | Assigns by management appointment; provides same training as end users; no engagement between training and go-live |
| **Timing** | Aligns training timing to methodology cadence and ADKAR readiness; builds training into project critical path | Places training where schedule has room; compresses training when upstream delays occur |
