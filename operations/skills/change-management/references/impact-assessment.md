# Impact Assessment Reference

## Purpose

This reference defines the schema, severity scale, and assessment methodology for
change impact assessments. It is the authoritative source for the change-management
skill (Mode A) and artifact-generator when producing or validating impact assessments.

## Five-Dimension Impact Assessment Framework

Every change must be assessed across five dimensions. Each dimension requires different
interventions, and the assessment must be performed per stakeholder group -- not as a
single organizational score.

### Dimensions

| Dimension | Assessment Focus | Visibility | Typical Interventions |
|-----------|-----------------|------------|----------------------|
| **Process** | Which business processes change? How significantly? New approval chains, workflow steps added/removed, decision authority shifts | High -- visible in day-to-day work | Process documentation, SOP updates, walkthrough sessions |
| **Technology** | Which systems change? New interfaces? Data migration? New tools replacing existing? | High -- visible in tools used | System training, sandbox access, job aids, go-live support |
| **People** | Which roles affected? How many? New skills required? Role redefinition? Headcount changes? | Moderate -- felt personally | Role-specific training, coaching, career path communication, skill gap analysis |
| **Organization** | Reporting structure changes? New teams formed? Governance changes? Decision rights shifted? | Moderate -- felt structurally | Org design communication, RACI updates, governance model briefings |
| **Culture** | Behavioral norms challenged? Values alignment? Decision-making style shift? Collaboration model change? | Low -- hardest to see, longest to change | Leadership modeling, reinforcement mechanisms, recognition redesign, community building |

**Critical rule:** A change that scores Low on Process but Critical on Culture requires
a culture-focused intervention, not process training. Dimension severity drives
intervention selection independently.

### Impact Severity Scale (1-4)

| Level | Label | Definition | CM Investment | Example |
|-------|-------|-----------|---------------|---------|
| 1 | **Low** | Minor adjustment within existing competency. Users adapt with minimal support. | Awareness communication only | New report format in existing system |
| 2 | **Medium** | Moderate change requiring learning but within familiar domain. Workarounds exist during transition. | Targeted communication + documentation + light training | New approval workflow in existing tool |
| 3 | **High** | Significant change to daily work. New skills, tools, or processes required. No simple workaround. | Full training program + dedicated support + change champions | New ERP module replacing manual process |
| 4 | **Critical** | Fundamental role change. Identity, competency, or status disrupted. May involve job redefinition. | Comprehensive CM program: sponsor engagement + multi-wave training + coaching + extended hypercare | ERP implementation replacing legacy system across all business functions |

### Per-Dimension Severity Assessment Table (Template)

| Stakeholder Group | Process | Technology | People | Organization | Culture | Overall Severity | ADKAR Barrier Point |
|-------------------|---------|------------|--------|--------------|---------|-----------------|---------------------|
| [Group Name] | 1-4 | 1-4 | 1-4 | 1-4 | 1-4 | Max of dimensions | Element scoring <=3 |

**Overall severity** = maximum severity across all five dimensions for that stakeholder
group. A group scoring 1/1/1/1/4 is a severity-4 change for that group because of
the culture dimension.

## ADKAR Barrier Point Integration

For each stakeholder group, score each ADKAR element (1-5) to identify the barrier
point -- the first element scoring <=3.

| ADKAR Element | Score Range | Barrier Point Signal | Intervention Required Before Advancing |
|---------------|------------|---------------------|---------------------------------------|
| **Awareness** | 1-5 | "Why are we doing this?"; rumors; lack of context | Executive sponsor messaging, burning platform narrative, role-specific impact statements |
| **Desire** | 1-5 | Disengagement, seeking exit, passive resistance | WIIFM framing, involvement in design, address fears directly, peer influence via champions |
| **Knowledge** | 1-5 | Honest attempts fail, frequent questions, rework | Formal training, eLearning, job aids, sandbox environments, mentoring |
| **Ability** | 1-5 | Inconsistent execution, reverting under pressure | Hands-on practice, coaching, shadowing, protected learning time |
| **Reinforcement** | 1-5 | Backsliding post-go-live, old behaviors resurface | Recognition, metrics tied to new behaviors, celebrations, onboarding integration |

**Barrier point rule:** Address the barrier point BEFORE investing in later elements.
Sending someone to Knowledge training when they score 2 on Desire wastes the training
budget entirely. Organizations using barrier point assessments achieve approximately
95% adoption vs. 35% without.

### ADKAR-Dimension Interaction Matrix

| Dimension Severity | ADKAR Priority Focus | Rationale |
|--------------------|---------------------|-----------|
| Process = High/Critical | Knowledge + Ability | New workflows require learning and practice |
| Technology = High/Critical | Knowledge + Ability | New systems require hands-on competence |
| People = High/Critical | Desire + Knowledge | Role changes trigger identity concerns before skill needs |
| Organization = High/Critical | Awareness + Desire | Structural changes require early "why" and buy-in |
| Culture = Critical | Desire + Reinforcement | Behavioral norm shifts require sustained motivation and structural reinforcement |

## Cumulative Change Load Assessment

Cumulative change load must be assessed across ALL concurrent changes per stakeholder
group before approving new initiatives.

### Calculation Method

1. **Inventory:** List all concurrent changes impacting each stakeholder group (not
   just the current project -- include all active initiatives)
2. **Score:** Assign each change a severity score (1-4) per dimension for that group
3. **Aggregate:** Sum severity scores across all concurrent changes per group
4. **Normalize:** Divide by maximum possible score to produce a saturation percentage

| Saturation Level | Score Range | Interpretation | Action |
|-----------------|-------------|---------------|--------|
| **Low** | 0-40% | Capacity available for additional change | Proceed normally |
| **Moderate** | 41-60% | Some strain; sequencing matters | Sequence changes to avoid peak overlap; monitor engagement |
| **High** | 61-75% | Near saturation; risk of fatigue | Defer non-critical changes; increase support for current changes |
| **Critical** | 76-100% | At or past saturation | Do not add new changes; focus on landing current changes; triage and defer |

**Reference statistic:** 73-78% of organizations report being near, at, or past change
saturation (Prosci benchmarking). Organizations with effective portfolio change
management realize 40% more value from initiatives (McKinsey).

### Load Assessment Template

| Stakeholder Group | Change 1 (Severity) | Change 2 (Severity) | Change 3 (Severity) | Aggregate Score | Max Possible | Saturation % | Status |
|-------------------|--------------------|--------------------|--------------------|-----------------|--------------|--------------| ------|
| [Group] | [1-4] | [1-4] | [1-4] | Sum | N x 4 | Agg/Max | Low/Mod/High/Crit |

## Methodology Variation Table

Impact assessment approach varies by delivery methodology:

| Methodology | Assessment Timing | Assessment Cadence | Primary Framework | Integration Point |
|-------------|------------------|-------------------|------------------|------------------|
| **Waterfall** | Front-loaded during planning phase; comprehensive before build begins | Once at project initiation; refresh at each phase gate | Lewin + ADKAR | Phase gate review; change control board |
| **Scrum** | Incremental per sprint; brief impact check per PBI with change implications | Every sprint (lightweight); deep assessment when scope changes | ADKAR + Bridges | Sprint Planning (what changes?); Sprint Review (did impact land?) |
| **SAFe** | PI-cadenced; assessed at PI Planning for upcoming features | Every PI boundary; refreshed at I&A | Kotter + 7-S + ADKAR | PI Planning (alignment); I&A (improvement); IP iteration (training) |
| **PRINCE2** | Stage-gate; assessed within Benefits Management Approach | Each stage boundary | Benefits Management | Stage boundary review; benefits review |
| **Kanban** | Continuous; assessed per work item when impact threshold met | On-demand; triggered by impact severity threshold | STATIK + ADKAR | Service Delivery Review; Operations Review |
| **Hybrid** | Dual-cadence: sprint-level for agile streams, phase-gate for waterfall streams | Per sprint (agile) + per phase gate (waterfall); integration sprint reviews | 7-S + phased stream integration | Integration sprint reviews + phase gate CABs |
| **Lean** | Continuous; gemba-based daily observation of change absorption | Daily (gemba); formal monthly or quarterly review | Respect for People + kata | Gemba walks; obeya room reviews |

## Impact Assessment Schema (Mode A Output)

### Required Fields per Impact Row

| Field | Description | Required | Source |
|-------|-----------|----------|--------|
| Change ID | Unique identifier linking to change matrix | Yes | Change matrix or auto-generated |
| Impacted Audience | Specific stakeholder group (never "All users") | Yes | Stakeholder map |
| Current State | As-is process, tools, behaviors for this audience | Yes | FDD, process documentation, interviews |
| Future State | To-be process, tools, behaviors | Yes | FDD, design documentation |
| Key Process Change | The delta in plain language from audience perspective | Yes | Derived from current/future state |
| Impact Summary | What this means for this audience day-to-day | Yes | Derived from analysis |
| Impact Frequency | Daily / Weekly / Monthly / One-time | Yes | Process analysis |
| Impact Severity | 1-4 per five-dimension framework | Yes | Assessment |
| Impact Dimensions | Which of the 5 dimensions are affected and at what level | Yes | Assessment |
| ADKAR Barrier Point | First ADKAR element scoring <=3 for this group | Recommended | ADKAR assessment |
| Training Implications | What training is needed based on severity and barrier point | Recommended | Derived from ADKAR |
| CM Notes | Audience-specific considerations, sequencing, dependencies | Recommended | Analysis |

### Severity Distribution Summary (Required Output)

After producing the impact table, summarize severity distribution:

| Severity | Count | % of Total | Groups Affected |
|----------|-------|-----------|-----------------|
| Critical (4) | N | % | [List groups] |
| High (3) | N | % | [List groups] |
| Medium (2) | N | % | [List groups] |
| Low (1) | N | % | [List groups] |

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **Technology-only assessment** | Only technology dimension scored; people/culture dimensions blank or uniformly "Low" | Treating change as a system implementation rather than an organizational transition | Require all five dimensions scored per group; flag any group with blank dimensions |
| **Uniform severity** | All groups scored the same severity | No stakeholder segmentation; one-size-fits-all assessment | Re-assess per group with group-specific current/future state analysis |
| **Ignoring cumulative load** | Impact assessed in isolation from other concurrent initiatives | Project-centric thinking; no portfolio view of change | Run cumulative load assessment across all concurrent changes per group |
| **Aspirational scoring** | ADKAR scores reflect desired state, not actual state | Reluctance to acknowledge readiness gaps | Ground ADKAR scores in observable behaviors and diagnostic signals per element |
| **Culture blindness** | Culture dimension consistently scored 1 (Low) across all changes | Culture is hardest to see; assessors default to visible dimensions | Ask diagnostic questions: "Does this change how decisions are made? How people collaborate? What behaviors are rewarded?" |
| **Static assessment** | Impact assessment produced once and never updated | Treated as a document deliverable rather than a living tool | Set review cadence matched to methodology (see Methodology Variation Table); refresh at every scope change |

## Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|-----------|-------------------|----------------|
| **Dimension coverage** | Assesses all five dimensions per stakeholder segment; sizes CM investment proportionally to each dimension | Assesses only the technology dimension; applies uniform CM regardless of dimension scores |
| **ADKAR integration** | Runs barrier point assessment per group; addresses barrier point before investing in later elements | Applies uniform interventions regardless of readiness level; skips Desire to jump to Knowledge |
| **Cumulative load** | Assesses load across all concurrent initiatives before approving new ones; recommends deferral when saturation is high | Launches initiatives independently without load assessment; treats each project in isolation |
| **Stakeholder segmentation** | Produces distinct assessments per audience group with group-specific current/future states | Produces a single assessment for "All users" with generic impact descriptions |
| **Severity calibration** | Uses the 1-4 scale with evidence-based justification per dimension; acknowledges when culture is the highest-severity dimension | Defaults to technology severity as the overall severity; systematically underrates people and culture |
