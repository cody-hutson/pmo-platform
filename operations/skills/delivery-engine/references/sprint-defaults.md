<!-- reference-durability: allow-link -->
# Sprint Defaults

## Purpose

Default parameters for sprint-based and flow-based delivery, including iteration configuration, WIP limits, capacity planning, and the decision model for choosing iteration vs. continuous flow. Consumed by delivery-engine (Mode D) for sprint/flow setup and ongoing calibration.

---

## 1. Default Sprint Parameters

### 1.1 Sprint Length

| Parameter | Default | Valid Range | Selection Guidance |
|-----------|---------|-------------|-------------------|
| **Sprint length** | 2 weeks | 1-4 weeks | 2 weeks is industry standard and Scrum Guide recommended maximum of 1 month |

**Sprint length selection factors:**

| Factor | Shorter (1 week) | Standard (2 weeks) | Longer (3-4 weeks) |
|--------|------------------|-------------------|-------------------|
| Feedback frequency need | High (rapidly changing requirements) | Normal | Lower (stable requirements) |
| Deployment capability | CI/CD mature; can deploy weekly | Standard deployment pipeline | Limited deployment windows |
| Team maturity | High (can plan and deliver in 1-week cycles) | Any | Any (but longer sprints mask problems) |
| Stakeholder availability | Available weekly for review | Available biweekly | Limited availability |
| Story size distribution | Small, well-decomposed stories dominate | Mixed sizes | Larger items; decomposition still maturing |
| Overhead tolerance | Team accepts higher ceremony-to-delivery ratio | Balanced | Minimizes ceremony overhead |

**Warning:** Sprint length >4 weeks violates the Scrum Guide maximum and delays risk detection. If the team cannot deliver a meaningful increment in 2 weeks, the problem is decomposition -- not sprint length.

### 1.2 Capacity Planning

| Parameter | Default | Range | Source |
|-----------|---------|-------|--------|
| **Planned utilization** | 75% | 70-85% | C03 universal; C06 portfolio guidance |
| **Focus Factor** | 0.65 | 0.60-0.75 | Accounts for meetings, email, context switching |
| **Unplanned work reserve** | 20% | 15-30% | Buffer for interrupts, production issues, discoveries |
| **Technical debt allocation** | 15% | 15-20% | Non-negotiable minimum; prevents debt accumulation |

**Capacity calculation:**

```
Available hours = Team members x Working hours x Sprint days
Planned capacity = Available hours x Focus Factor
Sprint capacity = Planned capacity x (1 - Unplanned reserve)
Feature capacity = Sprint capacity x (1 - Tech debt allocation)
```

**Example (5-person team, 2-week sprint, 8hr days):**
- Available hours: 5 x 8 x 10 = 400 hours
- Planned capacity: 400 x 0.65 = 260 hours
- Sprint capacity: 260 x 0.80 = 208 hours
- Feature capacity: 208 x 0.85 = 177 hours (remaining 31 hours for tech debt)

**Critical rule:** Never plan at 100% utilization. SAFe teams planned at 100% achieve only ~50% of planned business value. Context switching at 5+ concurrent projects reduces effective productivity to 5-20% per project.

### 1.3 Sprint Event Time-Boxes

| Event | Time-Box (2-week sprint) | Time-Box (1-week sprint) | Purpose |
|-------|-------------------------|-------------------------|---------|
| **Sprint Planning** | 4 hours max | 2 hours max | Forecast sprint scope; create Sprint Goal |
| **Daily Scrum** | 15 minutes | 15 minutes | Inspect progress toward Sprint Goal; adapt plan |
| **Sprint Review** | 2 hours max | 1 hour max | Inspect increment; adapt Product Backlog |
| **Sprint Retrospective** | 1.5 hours max | 45 minutes max | Inspect process; create improvement plan |
| **Backlog Refinement** | ~10% of sprint capacity | ~10% of sprint capacity | Decompose, clarify, estimate upcoming items |

**Scaling note (for 4-week sprint):** Planning scales to 8 hours max; Review to 4 hours; Retro to 3 hours. These are maximums -- effective teams finish faster.

---

## 2. WIP Limits

### 2.1 Starting WIP Limits by Team Size

| Team Size | Column WIP Limit (starting) | System WIP (total in-flight) | Rationale |
|-----------|---------------------------|------------------------------|-----------|
| 3-4 | 2-3 per column | 4-6 total | Team size - 1 heuristic |
| 5-7 | 3-5 per column | 6-10 total | Sweet spot for most Scrum teams |
| 8-10 | 5-7 per column | 8-14 total | Approaching team split threshold |

**Sizing heuristics (from multiple sources):**
- **Start from observation:** Observe natural WIP, then progressively reduce
- **Team size multiplier:** Team size x 1.5-2.5, adjusted for complexity
- **Scrum.org Featureban:** 2/3 to 3/4 of team size optimal for collaboration
- **Reinertsen:** Start at 2x observed average WIP, then work down
- **Personal WIP:** Ideal = 1 item per person; principal-level practitioners enforce this

### 2.2 WIP Limit Types

| Level | Scope | Purpose | Enforcement |
|-------|-------|---------|-------------|
| **Per column** | Single workflow state | Prevent bottleneck buildup | Most common; visible on board |
| **Per swimlane** | Work type or class of service | Ensure capacity across work types | Prevents one type from starving others |
| **Per person** | Individual contributor | Reduce context switching | Ideal = 1; signal when violated |
| **System-wide** | Entire board | Control total WIP across all states | Sprint boundary creates implicit system WIP (CONWIP) |
| **Queue columns** | Buffers between states | Minimize wait time | Should have the lowest limits (aspirationally zero) |

### 2.3 WIP Limit Rules

1. **Blocked items count against WIP limits** (DJAA/Kanban University standard). Starting new work when blocked items consume WIP forces conversation about blockers.
2. **Expedite items add to WIP limits** (not replace). One expedite lane with WIP limit of 1 is additive.
3. **Never raise WIP limits reactively.** If team feels "idle," investigate downstream bottleneck and swarm -- do not raise limits.
4. **Sprint as implicit WIP limit:** Scrum creates CONWIP -- the Sprint boundary constrains total work in flight. Kanban Guide for Scrum Teams adds explicit per-state WIP limits within Sprint.

### 2.4 WIP Limit Calibration Over Time

| Signal | Action |
|--------|--------|
| Items aging >50% of sprint length | WIP too high; reduce by 1 |
| Team frequently idle waiting for pull | WIP may be too low; investigate (often a decomposition issue, not a WIP issue) |
| Blocked items >25% of WIP | Systemic blocker; root cause before adjusting limits |
| Throughput increasing with lower WIP | Keep reducing; not yet at optimal |
| Throughput declining as WIP drops | Found the floor; increase by 1 |

**Research evidence:** Properly implemented WIP limits increase throughput by 40% while reducing delivery time by up to 60%.

---

## 3. Velocity Baseline Requirements

### 3.1 Velocity Stabilization Timeline

| Sprint Count | Velocity Reliability | Use For |
|-------------|---------------------|---------|
| 1-2 sprints | Unreliable | Do not use for forecasting |
| 3-5 sprints | Emerging pattern | Rough forecasting with wide ranges (+/-50-100%) |
| 6-8 sprints | Reliable baseline | Standard forecasting with ranges (+/-20-30%) |
| 9+ sprints (stable team) | High confidence | Tight forecasting (+/-10-15%) |

### 3.2 Velocity Expression Rules

1. **Always express velocity as a range, not a point.** "28-35 points/sprint" not "32 points/sprint."
2. **Use the last 3-5 sprints** for the range (minimum, average, maximum). Exclude outlier sprints (team member illness, holidays, etc.) with documentation.
3. **Velocity is team-specific and cannot be compared across teams.** A team with velocity 40 is not "better" than a team with velocity 20.
4. **Track throughput (items completed) alongside velocity.** If velocity trends upward but throughput is flat, investigate story point inflation (Goodhart's Law).
5. **Never use velocity as a performance metric.** 42% of practitioners admit to point manipulation when velocity is tied to reviews.

### 3.3 Team Maturity and Estimation Accuracy

| Team Maturity | Estimation Variance | Guidance |
|---------------|-------------------|----------|
| New teams (sprints 1-5) | +/-50-100% | Wide velocity ranges; set expectations with stakeholders |
| Established teams (6+ months) | +/-20-30% | Reliable for sprint commitment; use for release planning |
| Highly mature teams (12+ months) | +/-10-15% | High confidence; consider #NoEstimates or Monte Carlo |

---

## 4. Iteration vs. Continuous Flow Decision Model

Use this model to determine whether a team should use timeboxed iterations (Sprint-based), continuous flow (Kanban), or hybrid (Scrumban):

### 4.1 Decision Factors

| Factor | Choose Iteration (Sprint) | Choose Continuous Flow (Kanban) | Choose Hybrid (Scrumban) |
|--------|--------------------------|-------------------------------|-------------------------|
| **Team cadence discipline** | Team needs rhythm and synchronization | Team is mature and self-governing | Team transitioning; needs cadence with flow benefits |
| **Stakeholder expectations** | Expect periodic demos and releases | Accept on-demand delivery | Mixed expectations |
| **Work arrival pattern** | Batch commitment works; requirements stable within sprint | Work arrives unpredictably; interrupt-driven | Mixed: some planned, some interrupt |
| **Item size variation** | Items sized similarly; fit within sprint | Items vary dramatically in size | Mixed portfolio |
| **Delivery priority** | Batch predictability matters; synchronized releases | Speed of individual item delivery matters | Both matter |
| **Historical data** | Insufficient (<6 sprints of throughput data) | Stable throughput data available | Emerging data |
| **Team agile maturity** | New to agile; needs structured ceremonies | Experienced; can self-govern with policies | Intermediate |
| **Planning needs** | Organization needs synchronized planning cycles | Planning is lightweight and on-demand | Mix of synchronized and on-demand |

### 4.2 Flow Model Selection Output

| Model | Primary Mechanism | Planning Trigger | Forecasting Method |
|-------|------------------|-----------------|-------------------|
| **Sprint (Scrum)** | Timeboxed iterations with Sprint Goal | Sprint Planning ceremony | Velocity range over last 3-5 sprints |
| **Continuous Flow (Kanban)** | WIP limits with pull policies | Replenishment meeting when queue drops below threshold | Monte Carlo simulation at P85; cycle time percentiles |
| **Hybrid (Scrumban)** | Sprint cadence with WIP limits and pull | Planning triggers replace fixed cadence | Velocity for Sprint-level; cycle time for individual items |

**Transition note:** Most teams transitioning between models find Scrumban more productive than either pure approach. The progression is typically: Scrum (learn cadence) --> Scrumban (add flow) --> Kanban (if mature enough to self-govern).

---

## 5. Methodology Variation Table

| Parameter | Scrum | Kanban | Scrumban | SAFe (Team) | SAFe (ART) | XP |
|-----------|-------|--------|----------|-------------|------------|-----|
| **Iteration length** | 1-4 weeks (2 default) | None (continuous) | Optional cadence | 2 weeks standard | PI = 8-12 weeks (5 iterations + IP) | 1-2 weeks |
| **WIP mechanism** | Sprint as CONWIP | Explicit per-column | Sprint + per-column | Sprint + per-column | PI as portfolio WIP | Implicit (small team) |
| **Capacity model** | Velocity-based | Throughput-based | Hybrid | Story points + PI capacity | ART velocity + load factor | Ideal days + load factor |
| **Planning cadence** | Per sprint | On-demand (trigger) | Trigger-based | Per sprint + PI Planning | PI Planning (2-day event) | Weekly Planning Game |
| **Forecasting** | Velocity range | Monte Carlo / SLE | Hybrid | Velocity + PI confidence vote | PI Objectives + capacity | Ideal days |
| **Ceremony overhead** | ~15% of sprint | Minimal (cadences only) | Reduced Scrum ceremonies | Scrum + ART events | PI Planning + System Demos | Weekly iterations + daily standup |
| **Tech debt approach** | 15-20% sprint capacity | Intangible Class of Service | Reserved capacity | Enabler Stories (20-30%) | Enabler Features + IP iteration | Refactoring continuous; YAGNI |

---

## 6. Anti-Patterns

| Anti-Pattern | Detection Signal | Root Cause | Remediation |
|-------------|-----------------|------------|-------------|
| **Mini-waterfall** | Most items complete in last 2 days of sprint; work batched by phase (all analysis, then all dev, then all test) | Sequential work within timebox; specialists not cross-functioning; no swarming | Limit personal WIP to 1; swarm on items; cross-functional pairing; split stories smaller |
| **WIP limit inflation** | Limits raised because team "has nothing to do"; limits trend upward over time | Downstream bottleneck invisible; confusing idle time with blocked time | Investigate bottleneck; swarm on blocked items; never raise limits reactively; use idle time for tech debt or refinement |
| **Cherry-picking** | Easy items selected instead of priority order; high-priority items age while low-priority items complete | No pull discipline; no explicit policies; comfort-seeking over value delivery | Enforce pull from top of priority queue; make pull policies explicit; track aging WIP |
| **Velocity gaming** | Average story points per item trends upward while items/sprint stays flat; velocity inflation around review periods | Velocity tied to performance evaluation; Goodhart's Law | Use velocity for planning only; track throughput as the honest signal; periodic blind re-estimation exercises |
| **100% utilization planning** | Plans show no slack; no buffer for unplanned work; every hour accounted for; team burns out | Executive pressure for "fully loaded" teams; confusing utilization with productivity | Cap planned utilization at 85%; track outcomes not hours; educate stakeholders on Focus Factor |
| **Sprint scope creep** | Items added mid-sprint without removing others; Sprint Goal abandoned; PO injects work daily | Sprint boundary not respected; PO treats sprint as Kanban without WIP limits | Protect sprint scope; PO can only add by removing equal-sized item; track mid-sprint changes |

---

## 7. Applicability

Per [`applicability-framework.md`](../../../../core/disciplines/applicability-framework.md). The sprint-cadence defaults below are a **contextual** (methodology-axis) practice — they apply only where the delivery methodology is time-boxed.

### Applicability (per applicability-framework.md)
- **Universality:** contextual            # §938 axis position — methodology-axis
- **Applies when:** `delivery_methodology ∈ {Scrum, XP, SAFe, Hybrid (iterative phase), Custom (timeboxed lifecycle)}`
- **Contraindicated when:** **CI-4** (sprint/velocity ceremonies — `delivery_methodology ∈ {Waterfall, PRINCE2}`, non-time-boxed); also **CI-5** when `org_scale = single-operator` and a ceremony presumes multi-team coordination (scrum-of-scrums in a one-person PMO)
- **On conflict:** §4 rung 4 (co-manifestation) when `spm_comanaged: true` — produce BOTH the sprint-cadence framing AND the phase-gate framing rather than forcing one; §4 rung 1 (contextual localization via decision-discipline.md M1) otherwise
- **Evidence tier:** ref `corpus-curation.md`; tiebreak input only — not defined here
