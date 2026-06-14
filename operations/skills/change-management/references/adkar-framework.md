# ADKAR Framework Reference

## Purpose

This reference is the authoritative source for the ADKAR change-adoption methodology
consumed by the change-management skill (Modes A — Impact assessment, C — Readiness
checklist, D — Change matrix review) and the sibling references. It owns the ADKAR
scoring scale, the barrier-point rule, the sponsor-engagement model, ADKAR-gated
training timing, change-champion sizing, the valley-of-despair model, change-fatigue
thresholds, and ADKAR-element outcome measurement. The sibling references consume the
scale and barrier-point rule defined here by reference rather than redefining them:
`impact-assessment.md` (Mode A) and `readiness-checklist.md` (Mode C) point to this
file for the scale and barrier rule, and retain their own application-specific layers
(the ADKAR-Dimension Interaction Matrix and the Barrier Point Decision Logic /
Readiness Summary Table respectively).

## 1. The ADKAR Model

ADKAR is a sequential, goal-oriented model: change is achieved one person at a time,
and each element is a prerequisite for the next. An individual cannot build durable
Ability without Knowledge, cannot retain Knowledge without Desire, and cannot form
Desire without Awareness. Reinforcement is what prevents regression after the change
lands.

| Element | Question it answers | What "achieved" looks like | Primary failure signal |
|---------|--------------------|-----------------------------|------------------------|
| **Awareness** | Why is this change happening? | The person can state the business reason and the personal impact in their own words | "Why are we doing this?"; rumors; lack of context |
| **Desire** | What's in it for me? Why should I support it? | The person chooses to participate and support the change | Disengagement, seeking exit, passive resistance |
| **Knowledge** | How do I change? | The person knows the new process, tools, and behaviors required | Honest attempts fail; frequent questions; rework |
| **Ability** | Can I do it, in practice, under real conditions? | The person demonstrates the new behavior consistently in production conditions | Inconsistent execution; reverting under pressure |
| **Reinforcement** | Will it stick? | The new behavior is sustained; old behaviors do not resurface | Backsliding post-go-live; old behaviors resurface |

**Sequential-gate principle:** Assess elements in A → D → K → Ab → R order. The first
element that falls short is the constraint on everything downstream — investing in a
later element while an earlier one is unmet wastes the investment.

## 2. ADKAR Scoring Scale (1-5) — CANONICAL

This is the single-source-of-truth ADKAR scale. Score each ADKAR element 1-5 per
stakeholder group, grounded in observable behaviors (not aspirational intent). The
right-hand column gives the per-element diagnostic signal that indicates the element
is the barrier point and names the intervention required before advancing.

| Score | Label | Observable Indicators (level) |
|-------|-------|-------------------------------|
| 5 | **Strong** | Active advocacy; consistent demonstration; no regression risk |
| 4 | **Adequate** | Meets threshold; functional capability; minor gaps manageable |
| 3 | **Borderline** | Inconsistent; requires active support to maintain; at risk under pressure |
| 2 | **Weak** | Significant gaps; frequently reverts; requires intensive intervention |
| 1 | **Absent** | No evidence of this element; foundational work required |

### Per-Element Barrier Signals and Interventions

| ADKAR Element | Barrier Point Signal (score <=3) | Intervention Required Before Advancing |
|---------------|----------------------------------|----------------------------------------|
| **Awareness** | "Why are we doing this?"; rumors; lack of context | Executive sponsor messaging, burning-platform narrative, role-specific impact statements |
| **Desire** | Disengagement, seeking exit, passive resistance | WIIFM framing, involvement in design, address fears directly, peer influence via champions |
| **Knowledge** | Honest attempts fail, frequent questions, rework | Formal training, eLearning, job aids, sandbox environments, mentoring |
| **Ability** | Inconsistent execution, reverting under pressure | Hands-on practice, coaching, shadowing, protected learning time |
| **Reinforcement** | Backsliding post-go-live, old behaviors resurface | Recognition, metrics tied to new behaviors, celebrations, onboarding integration |

**Scoring discipline:** Ground every score in observable behaviors and diagnostic
signals per element — not desired state. Scoring the aspiration rather than the
observation is the single most common assessment failure (see Anti-Patterns).

## 3. Scoring Template (per element x per stakeholder group)

Score each cell 1-5 per the §2 scale. One row per stakeholder group. This matrix is
the numeric structure a readiness or impact assessment reads from — it produces the
per-group, per-element numeric scores.

| Stakeholder Group | A | D | K | Ab | R | Barrier Point | Overall Readiness |
|-------------------|---|---|---|----|----|--------------|-------------------|
| [Group Name] | 1-5 | 1-5 | 1-5 | 1-5 | 1-5 | First element <=3, or "None" | Ready / Conditional / Not Ready |

- **Barrier Point** is computed per §4.
- **Overall Readiness** is the verdict derived from the barrier point per §4.
- Score per the §2 scale, grounded in observable behaviors — never aspirational.

## 4. Barrier-Point Rules — CANONICAL

The **barrier point** is the first ADKAR element (in sequence) scoring at or below 3.
It is the constraint that gates adoption: addressing it must precede investment in any
later element.

```
FOR each stakeholder group:
  Score Awareness    (1-5)
  Score Desire       (1-5)
  Score Knowledge    (1-5)
  Score Ability      (1-5)
  Score Reinforcement(1-5)

  barrier_point = first element, in A -> D -> K -> Ab -> R order, where score <= 3

  IF barrier_point exists:
    READINESS = NOT READY  (intervene at the barrier element first)
    ACTION    = the per-element intervention for the barrier element (see §2)
  ELSE IF any element = 4 (none <= 3):
    READINESS = CONDITIONAL (monitor closely; support plan required)
    ACTION    = targeted support for the element(s) at 4
  ELSE (all elements = 5):
    READINESS = READY
```

**Address-barrier-first rule:** Address the barrier point BEFORE investing in later
elements. Sending someone to Knowledge training when they score 2 on Desire wastes the
training budget entirely — the constraint is motivation, not skill.

### Per-Element Intervention (when each element is the barrier)

The intervention table in §2 (Per-Element Barrier Signals and Interventions) is the
authoritative map from the barrier element to the action required. When the barrier is
Awareness or Desire, no downstream Knowledge/Ability work should proceed for that group
until the barrier is cleared.

**Adoption evidence:** Organizations using barrier-point assessment achieve
approximately **95% adoption** versus **~35% without**. [SOURCE: Prosci / industry
benchmark]

## 5. Sponsor-Engagement ABCs

Active and visible sponsorship is the single strongest predictor of change success.
The sponsor's role is modeled as three obligations — the "ABCs."

| ABC | What it means | Observable failure signal | CM intervention |
|-----|---------------|---------------------------|-----------------|
| **A — Active and visible participation** | The sponsor participates throughout the lifecycle, not just at kickoff — visible at milestones, town halls, and go-live | Sponsor appears at launch then disappears; delegates all change activity | Build a sponsor roadmap of scheduled, visible touchpoints across the lifecycle; brief the sponsor before each |
| **B — Building a coalition of sponsorship** | The sponsor recruits and aligns peer leaders so sponsorship is consistent across the affected org, not a single voice | Peer leaders send conflicting signals; middle managers undercut the change | Map the sponsorship coalition; equip each peer leader with aligned talk tracks; surface and resolve misalignment early |
| **C — Communicating directly with employees** | The sponsor communicates the "why" directly to employees — the business reason and the personal impact — rather than routing it through the project team | Employees hear the "why" only from the PMO, never from leadership; the message reads as a project, not a business decision | Sponsor-authored (not ghost-written-feeling) direct communications; sponsor presence at the WIIFM conversation |

**Composes with:** `hypercare-plan.md` documents the "Sponsor In Name Only" (SINO)
anti-pattern and the effective-sponsor statistic (changes with effective sponsorship
succeed at a far higher rate than those without). adkar-framework.md owns the ABC
*obligation model*; do not restate the SINO anti-pattern table or the statistic here —
reference `hypercare-plan.md` for them.

## 6. Training-Timing Rules (ADKAR-gated)

Training builds the Knowledge and Ability elements. It is wasted if delivered before
the Awareness and Desire gates are met, or mistimed relative to go-live.

| Rule | Constraint | Rationale |
|------|-----------|-----------|
| **ADKAR gate** | Deliver Knowledge/Ability training only when Awareness >= 4 AND Desire >= 4 for the group | A group below the Desire barrier will not absorb training; address the barrier first (§4) |
| **Pre-go-live window** | Deliver Knowledge training 2-4 weeks before go-live | Earlier (6+ weeks) -> forgetting before use; final week -> no time to practice and reach Ability |
| **Practice before production** | Schedule supervised practice (Ability) between Knowledge delivery and go-live | Ability forms under practice, not in the classroom; the gap between classroom Knowledge and production Ability is the valley-of-despair driver (§8) |

**Composes with:** `training-plan.md` owns the *channel and curriculum design* — the
70-20-10 experiential model, the super-user network, and Kirkpatrick measurement.
adkar-framework.md owns the *ADKAR-gate rule* (when a group is ready to be trained) and
the *timing window*. Reference `training-plan.md` for the "training too early" and
"training too late" channel-design anti-patterns and the 70-20-10 split; do not restate
them here.

## 7. Change-Champion Ratio — CANONICAL

A **change champion** is an influence and advocacy node — a peer-credible individual
(Desire >= 4) who carries the change through the *adoption* network. This is DISTINCT
from a **super user**, which is a task and system-support node carried by the
*capability* network. The two networks are sized independently and must not be
conflated: a super user supports "how do I do this in the system," a champion shifts
"do I want this and do my peers."

> **Super-user sizing is owned by `training-plan.md`** (the support-capacity ratios,
> e.g. the go-live 1:8 ratio). Do not size the support network from this table or the
> advocacy network from the super-user table — sizing one network for the other's job
> is an anti-pattern (§13).

### Champion Sizing Formula

```
champion_count = ceil( impacted_population / denominator )

where denominator is read from the severity-banded table below,
keyed on the group's overall change severity (impact-assessment.md five-dimension
severity, 1-4).
```

### Severity-Banded Champion Denominators [RECOMMENDED — tune per program]

| Overall Severity | Denominator (1 champion per N impacted) | Network posture |
|------------------|------------------------------------------|-----------------|
| **4 — Critical** | 1:10 | Dense advocacy network; identity-level change needs many peer voices |
| **3 — High** | 1:20 | Substantial advocacy network |
| **2 — Medium** | 1:40 | Light advocacy network |
| **1 — Low** | Awareness-only — no dedicated champions | Communication suffices; no advocacy network needed |

The denominators are deliberately sparser than super-user support ratios: an advocacy
node influences a wider span than a support node assists. Values are `[RECOMMENDED]`
planning defaults — tune per program and per the credibility density of the population.

### Selection Criteria

- **Peer credibility, NOT title** — influence comes from being trusted by peers, not
  from position.
- **Desire >= 4** — a champion must have crossed their own Desire gate; a resistant
  "champion" amplifies resistance.
- **Positive influence** — recruit the people others already follow, not only the
  enthusiastic volunteers.

## 8. Valley-of-Despair Model

When a change goes live, productivity dips before it recovers — the "valley of despair"
J-curve. The dip is not a sign of failure; it is the expected gap between Ability built
in training and Ability demanded under live production pressure.

- **Why the dip happens:** Classroom/sandbox Knowledge does not equal production
  Ability. Under real volume, edge cases, and time pressure, the new behavior is slower
  and error-prone before it becomes fluent.
- **Support-ramp implication:** Do NOT pull support at the bottom of the valley.
  Withdrawing super users and coaching at peak disruption converts a temporary dip into
  permanent regression (a barrier at Ability/Reinforcement).

**Composes with:** `hypercare-plan.md` owns the valley *parameter values* — the
dip magnitude, the peak-disruption timing, and the recovery-with-vs-without-structured-CM
curve. adkar-framework.md owns the *concept and the support-ramp rule*; reference
`hypercare-plan.md` for the numeric parameters and the support-ramp schedule.

## 9. Change-Fatigue / Saturation Thresholds

Change fatigue is the ADKAR-level symptom of cumulative change overload. A group at or
past saturation cannot form new Desire or absorb new Knowledge, and previously-achieved
Reinforcement begins to regress.

### ADKAR Symptom Mapping

| Saturation state | ADKAR manifestation |
|------------------|---------------------|
| Approaching saturation | Desire regresses (change is "one more thing"); Reinforcement of prior changes weakens |
| At / past saturation | New Knowledge cannot be absorbed (no cognitive headroom); Desire collapses; old behaviors resurface across multiple changes |

**Threshold rule:** When a group is at or past saturation, do not launch new
Knowledge/Ability activity into it — landing the in-flight changes (and protecting
their Reinforcement) takes priority over starting new ones.

**Composes with:** `impact-assessment.md` owns the cumulative-change-load *saturation
math* — the inventory/score/aggregate/normalize method, the 0-40% Low through 76-100%
Critical bands, and the saturation statistic. adkar-framework.md owns the *ADKAR-symptom
mapping*; reference `impact-assessment.md` for the load-calculation method and the
saturation bands.

## 10. Outcome Measurement

Each ADKAR element has its own measurement method. The element-level measurement layer
below complements — and does not replace — the training-effectiveness and adoption-KPI
layers owned elsewhere.

| ADKAR Element | What to measure | Method |
|---------------|-----------------|--------|
| **Awareness** | Can people state the "why"? | Pulse survey / sponsor-message recall |
| **Desire** | Are people choosing to participate? | Engagement signals, voluntary adoption rate, resistance log |
| **Knowledge** | Do people know how? | Knowledge assessment pass rate (Kirkpatrick Level 2 — owned by `training-plan.md`) |
| **Ability** | Can people do it in production? | On-the-job observation, error/rework rate, time-to-proficiency |
| **Reinforcement** | Did it stick (no backsliding)? | Sustained-adoption metric; the post-go-live reinforcement check (owned by `hypercare-plan.md`); recognition-mechanism activity |

**Reinforcement focus:** The distinctive ADKAR measurement obligation is proving the
change *stuck* — no regression to old behaviors. This is measured past go-live, at the
reinforcement-check milestone defined in `hypercare-plan.md`.

**Composes with:** `training-plan.md` owns the Kirkpatrick Level 1-4 model; readiness
and hypercare references own the adoption KPIs and exit criteria. adkar-framework.md
owns the *element-level measurement map* — reference the siblings for Kirkpatrick and
the adoption-KPI set rather than restating them.

## 11. Unified Assessment Procedure

This is the deterministic procedure an agent executes to produce an ADKAR assessment.
It ties §§2-7 into a runnable flow.

```
1. ENUMERATE the stakeholder groups in scope.

2. For EACH group, SCORE the five ADKAR elements 1-5 per the §2 scale,
   grounded in observable behaviors.

3. For EACH group, COMPUTE the barrier point per §4:
   barrier_point = first element (A -> D -> K -> Ab -> R) with score <= 3, else "None".
   Derive the readiness verdict (NOT READY / CONDITIONAL / READY) per §4.

4. For EACH group, COMPUTE the champion count per §7:
   a. Determine the group's overall change severity (1-4).
   b. Read the denominator from the §7 severity band.
   c. champion_count = ceil(impacted_population / denominator)
      (Severity 1 / Low -> awareness-only, champion_count = 0.)

5. EMIT:
   - the per-group scoring table (§3),
   - the barrier list (each group's barrier point + readiness verdict),
   - the total champion count (sum across groups).
```

An agent that can execute steps 1-5 from this document alone produces numeric scores,
identified barriers, and a calculated champion count — the three outputs an ADKAR
assessment requires.

## 12. Worked Example — 3 Stakeholder Groups

A worked end-to-end assessment for three named groups, demonstrating the §11 procedure.

### Step 2-3: Scoring + Barrier Points

| Stakeholder Group | A | D | K | Ab | R | Barrier Point | Readiness |
|-------------------|---|---|---|----|----|--------------|-----------|
| **Buying & Planning** | 5 | 4 | 4 | 4 | 4 | None (no element <=3) | Conditional |
| **Warehouse Ops** | 4 | 2 | 3 | 2 | 1 | **Desire** (first element <=3) | Not Ready |
| **Customer Service** | 5 | 5 | 4 | 4 | 5 | None | Conditional |

- Buying & Planning: no element <=3, but elements at 4 -> **Conditional** (support plan).
- Warehouse Ops: Desire = 2 is the first element <=3 -> **Not Ready**; intervene at
  Desire (WIIFM, involvement, address fears) BEFORE any Knowledge/Ability training.
- Customer Service: no element <=3, elements at 4 -> **Conditional**.

### Step 4: Champion Count (per §7)

| Stakeholder Group | Overall Severity | Impacted Population | Denominator (§7) | champion_count = ceil(pop / denom) |
|-------------------|------------------|---------------------|------------------|-------------------------------------|
| **Buying & Planning** | 3 — High | 60 | 1:20 | ceil(60 / 20) = **3** |
| **Warehouse Ops** | 4 — Critical | 220 | 1:10 | ceil(220 / 10) = **22** |
| **Customer Service** | 2 — Medium | 45 | 1:40 | ceil(45 / 40) = **2** |

### Step 5: Emit

- **Numeric scores:** produced per group above (the 5-element 1-5 matrix).
- **Identified barriers:** Buying & Planning — None (Conditional); Warehouse Ops —
  **Desire** (Not Ready); Customer Service — None (Conditional).
- **Total champion count:** 3 + 22 + 2 = **27 champions** across the three groups.

This example is the regression fixture: an agent reading only this document must
reproduce these numbers from the §11 procedure.

## 13. Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **Skipping the barrier point** | Groups with Desire or Awareness <=3 sent to Knowledge/Ability training anyway | Treating ADKAR as a checklist rather than a sequential gate | Compute the barrier point per §4; block downstream investment until the barrier element is cleared |
| **Aspirational scoring** | ADKAR scores reflect desired state, not observed behavior | Reluctance to acknowledge readiness gaps | Ground every score in observable behaviors and the §2 per-element signals; require evidence per score (see also the impact-assessment.md aspirational-scoring entry) |
| **Champion = super-user conflation** | The advocacy network is sized from super-user ratios, or the support network from champion ratios | Treating the two networks as one | Size champions per §7 (advocacy/influence) and super users per `training-plan.md` (support/capacity) as distinct networks with distinct denominators |
| **Sponsor In Name Only** | A named sponsor who is absent, silent, or delegates all change activity | Sponsorship treated as a title, not the ABC obligations | Hold the sponsor to the §5 ABCs (Active/Build/Communicate); see the SINO anti-pattern in `hypercare-plan.md` |
| **Pulling support in the valley** | Super users and coaching withdrawn at peak disruption | Mistaking the expected J-curve dip for failure or "project complete" | Maintain the support ramp through the valley per §8 and the `hypercare-plan.md` schedule; do not reduce support at the bottom |

## 14. Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|-----------|-------------------|----------------|
| **Scoring rigor** | Grounds each ADKAR score in observable behaviors and the §2 signals; cites evidence per score | Scores the aspiration; assigns uniform scores without per-group diagnosis |
| **Barrier-point discipline** | Computes the barrier per §4; blocks downstream investment until the barrier element is cleared | Applies uniform interventions regardless of barrier; trains groups stuck at Desire |
| **Sponsor activation** | Holds the sponsor to the §5 ABCs with a scheduled roadmap of visible touchpoints | Accepts a named-only sponsor; routes the "why" through the PMO instead of leadership |
| **Champion sizing** | Sizes the advocacy network per §7, distinct from the support network; selects on peer credibility and Desire | Conflates champions with super users; selects on title or volunteer enthusiasm |
| **Reinforcement measurement** | Measures that the change stuck past go-live (no backsliding) at the reinforcement-check milestone | Declares success at go-live; never measures sustained adoption |
