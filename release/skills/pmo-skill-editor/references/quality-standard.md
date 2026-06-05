# Quality Standard — PMO Reference

## Purpose

This file defines the quality standard for PMO skill outputs and operational
artifacts. The pmo-skill-editor skill reads this file in Mode D (Quality
Standards Enforcement) to evaluate skill quality, calibrate methodology-aware
quality expectations, and enforce behavioral standards.

---

## Quality Philosophy Spectrum

Every delivery approach embodies a quality philosophy. The correct philosophy
depends on context — there is no universal "best" position.

| Position | Philosophy | Mechanism | Strength | Weakness | Fits When |
|----------|-----------|-----------|----------|----------|-----------|
| **Inspect at Gates** | Quality discovered through formal reviews at phase transitions | Phase-end reviews, gate criteria, formal sign-off | Auditability, clear documentation | Late discovery = exponential cost (Boehm: 50-200x) | Regulated environments requiring audit trails; compliance-driven |
| **Continuous Inspection** | Quality checked at every transition using explicit policies | Column exit criteria, distributed DoD | Distributed responsibility, fast feedback | Requires explicit policy discipline | Teams with mature flow practices; Kanban/Scrumban |
| **Build Quality In** | Quality embedded throughout delivery via practices and DoD | Sprint DoD, cross-functional teams, automated testing | Early feedback, team ownership | Requires engineering discipline | Sprint-based delivery; Scrum, SAFe, Hybrid |
| **Prevent at Source** | Quality designed so defects cannot occur | TDD, pair programming, jidoka, poka-yoke | Lowest total cost of quality | Highest practice maturity required | Engineering-led teams with high trust; XP, Lean |
| **Adaptive Quality** | Quality approach selected per context from available options | Process goal diagrams, consumable solutions | Flexibility, context-sensitivity | Requires judgment and experience | Organizations wanting contextual quality governance; DA |

**Selection logic:** Determine the dominant context factor first:
1. If regulatory requirements exist → Inspect at Gates is mandatory (supplement with others)
2. If team maturity is high and delivery is continuous → Prevent at Source yields lowest total cost
3. If team is mid-maturity with sprint cadence → Build Quality In is the pragmatic default
4. If flow-based with explicit policies → Continuous Inspection aligns with the delivery model
5. If context varies across portfolio → Adaptive Quality applies different approaches per initiative

---

## Skill Quality Dimensions

Six dimensions define quality for PMO skill outputs. Each dimension is evaluated
independently. The overall quality assessment is the minimum dimension score —
a single failing dimension means the output does not meet the quality standard.

### Dimension 1: Structural Completeness

*Does the output contain all required sections and fields per its schema?*

| Level | Criteria |
|-------|---------|
| **High** | All required sections present; all fields populated; schema-compliant; no placeholder content ([INSERT], [TBD]) |
| **Acceptable** | All required sections present; >90% of fields populated; remaining gaps have explicit rationale |
| **Below Standard** | Missing required sections; >10% of fields empty without rationale; placeholder content present |

### Dimension 2: Evidence Quality

*Are claims grounded in traceable evidence?*

| Level | Criteria |
|-------|---------|
| **High** | Every factual claim tagged ([SOURCE], [INFERRED], [ASSUMPTION - CONFIRM], [CONTEXT], [RECOMMENDED]); dates verified against authoritative source; no untagged assertions |
| **Acceptable** | >90% of claims tagged; occasional untagged claim where source is obvious; dates verified for critical items |
| **Below Standard** | Claims presented without evidence tags; dates not verified; metrics without methodology; status claims without source |

### Dimension 3: Decision Clarity

*Does the output enable decisions rather than defer them?*

| Level | Criteria |
|-------|---------|
| **High** | Recommendations are explicit with rationale; trade-offs named with principal-level judgment; decisions framed with options, not presented as binary; risk implications stated for each option |
| **Acceptable** | Recommendations present; rationale provided; some decisions could be sharper or more fully framed |
| **Below Standard** | No recommendations; decisions deferred to operator without analysis; options listed without evaluation; "it depends" without specifying on what |

### Dimension 4: Artifact Readiness

*Is the output immediately usable by its consumer?*

| Level | Criteria |
|-------|---------|
| **High** | Output is paste-ready, file-ready, or execution-ready; operator action is review/approve, not create/complete; format matches the target system (email, tracker, governance doc) |
| **Acceptable** | Output is usable with minor adjustments (name confirmation, final date validation); operator effort is review-level |
| **Below Standard** | Output requires substantial operator work to become usable; template not populated; format does not match target |

### Dimension 5: Routing Correctness

*Is the output directed to the right destination with the right governance?*

| Level | Criteria |
|-------|---------|
| **High** | File written to correct location per project folder structure; tier-appropriate governance applied (Tier 1: approval sought, Tier 2: auto-written, Tier 3: routed, Tier 4: flagged); follow-up tags applied correctly |
| **Acceptable** | Correct destination; governance mostly appropriate; minor routing gaps (e.g., follow-up tag missing on a non-critical item) |
| **Below Standard** | Wrong destination; tier governance violated (Tier 1 written without approval, Tier 2 not written); missing follow-up tags on critical items |

### Dimension 6: Anti-Pattern Detection

*Does the output avoid known anti-patterns?*

| Level | Criteria |
|-------|---------|
| **High** | Zero anti-patterns detected; output actively demonstrates anti-pattern awareness (e.g., names risks with owners instead of passive descriptions; uses specific dates instead of ranges; actions have full packages) |
| **Acceptable** | No critical anti-patterns; 1-2 minor anti-pattern signals that do not materially affect quality |
| **Below Standard** | Anti-patterns present: status theater, task dumping, passive risk voice, placeholder content, unvalidated dates, evidence-free claims |

---

## Methodology-Aware Quality Calibration

Quality expectations vary by delivery methodology. The same output may be assessed
differently depending on the project's delivery approach.

| Quality Aspect | Agile Context | Waterfall Context | Hybrid Context |
|---------------|---------------|-------------------|----------------|
| **Documentation depth** | JBGE — sufficient for purpose, no more; favor working deliverables over exhaustive documentation | Comprehensive — every deliverable documented to audit standard; 20-40% of time on documentation is normal | Balanced — comprehensive for governance artifacts, JBGE for sprint-level work |
| **Gate formality** | Team-owned DoD; lightweight commitment/delivery points | Formal sign-off with steering committee; documented gate decisions | Dual: formal at phase boundaries, team-owned within sprints |
| **Estimation precision** | Ranges with confidence levels; story points or relative sizing | Specific dates with EVM tracking; formal estimates | Ranges upstream; specific dates at commitment points |
| **Risk treatment** | Empirical — sprint as containment; impediment surfacing | Structured — P x I matrix; formal risk register; Monte Carlo for high-stakes | Dual-track: register for known, board for emerging |
| **Change governance** | PO reprioritizes backlog; no formal CR for in-sprint changes | Formal Change Request through CCB for any scope/schedule/cost change | Threshold model: formal CR above threshold, PO authority below |
| **Progress reporting** | Burndown, velocity, flow metrics; Sprint Review is primary | Gantt chart, SPI/CPI, milestone tracking; formal status reports | Both: flow metrics for sprints, milestone metrics for phases |

---

## Principal vs. Junior Behavioral Markers

Quality judgment is not mechanical — it requires calibration to the eight persona
dimensions. These markers distinguish principal-level quality from junior-level
compliance.

| Dimension | Principal Quality Behavior | Junior Quality Behavior |
|-----------|--------------------------|------------------------|
| **Decision Authority** | Makes binding quality judgments within delegated scope; accepts risk when justified and documents rationale | Defers all quality judgments; escalates every edge case; cannot distinguish critical from non-critical |
| **System Thinking** | Assesses quality impact across connected artifacts; identifies cascade effects of quality gaps | Evaluates each artifact in isolation; misses downstream impact of quality issues |
| **Process Ownership** | Adapts quality criteria to context; defends deviations from standard when context warrants | Applies identical quality checklist regardless of context; cannot justify why a criterion matters |
| **Risk Orientation** | Uses quality gaps as risk signals; connects defect patterns to systemic causes; quantifies quality risk | Treats each quality issue independently; no pattern analysis; describes risk without quantification |
| **Communication Precision** | Quality feedback is specific, actionable, and prioritized; distinguishes "must fix" from "nice to have" | Quality feedback is vague ("needs improvement"), unprioritized, or exhaustive without hierarchy |
| **Delivery Focus** | Measures quality by outcomes (decisions enabled, risks mitigated, actions completed) not by compliance (sections filled, fields populated) | Measures quality by checklist completion; treats all fields as equally important |

---

## Quality Anti-Patterns

| Anti-Pattern | Signal | Quality Impact | Remediation |
|-------------|--------|---------------|-------------|
| **Coverage theater** | High scores on structural completeness but poor decision clarity and operational value | Artifact exists but drives no decisions; zombie artifact in formation | Evaluate by operational value first; structural completeness is necessary but not sufficient |
| **Gate compression** | Quality checks skipped under time pressure; "we'll fix it later" | Late-discovered defects at exponential cost; Boehm's curve applies to PMO artifacts too | Establish quality checks that never compress; track compression frequency |
| **Rubber-stamp review** | Review completed in <2 minutes on substantive content; "LGTM" without feedback | Defects pass through; review provides false confidence | Set review time expectations; require substantive comments on material content |
| **One-size-fits-all quality** | Same quality checklist for Agile sprint output and Waterfall phase gate | Agile output over-governed or Waterfall output under-governed | Use methodology-aware calibration table; match quality expectations to delivery approach |
| **Quality as overhead** | Quality activities treated as cost, not investment; first to cut under pressure | Defect accumulation; rework spiral; velocity degradation | Frame quality as velocity enabler (Fowler's Design Stamina Hypothesis: quality investment pays back within weeks) |
| **Metric gaming** | Scores optimized for measurement, not for actual quality (Goodhart's Law) | Metrics show green but outcomes show red; watermelon quality | Evaluate by outcomes (decisions, actions, risk mitigation) not by metrics alone |
