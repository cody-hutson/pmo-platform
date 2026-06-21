<!-- reference-durability: allow-link -->
<!-- provenance: UNSOURCED-DOMAIN -->

# Capacity Model

## Purpose

Models the *effective* delivery capacity of a **managed delivery team** — the agile
squads a TPM plans for — accounting for context-switching across concurrent projects,
team-growth drag, effort allocation, team stability, vendor ramp-up, staffing-concentration
(bus-factor) risk, and the demand-versus-supply gap. It is read by the delivery-engine
skill: **Mode D (Sprint Planning)** reads the capacity formula (§1), the context-switching
penalties (§3), the Brooks's-Law thresholds (§4), the 60/20/20 effort split (§5), and the
team-stability and vendor-ramp thresholds (§6–§7) when building a capacity model and sprint
scope; **Mode E (Execution Control Tower)** reads the demand-supply gap RAG bands (§9) and
the context-switch signal when assessing whether committed demand exceeds effective supply.

**Sibling relationship.** This doc is the topical home for the **supply** calculation —
how nominal hours become *effective* delivery capacity. Two of its inputs are owned
elsewhere and are **referenced, not restated**: the **focus factor** (the first multiplier
in §1) is owned by [`estimation-standards.md` §3 Canonical Focus-Factor Table](estimation-standards.md) — see §2; the **platform-level bus-factor rule** is owned by
[`km-protocols.md` §4 Bus-Factor Rules](../../../../core/disciplines/km-protocols.md#bus-factor) — see §8. `sprint-defaults.md` owns the sprint **cadence** parameters (sprint length,
WIP limits, velocity-stabilization windows) and the per-sprint capacity knobs (planned
utilization, unplanned reserve, tech-debt allocation); this doc gives those knobs their
steady-state capacity context (see §5).

> **Content provenance: `UNSOURCED-DOMAIN`.** Several thresholds in this doc are
> `UNSOURCED-DOMAIN` best-practice — anchored to named PMO/SE domain references (Brooks,
> *The Mythical Man-Month*; Weinberg context-switching loss; PMI capacity/allocation
> conventions), not to an internal audit. The "full content spec" the originating issue
> cited (an upscale gap analysis) is **absent from the repository**; no citation to it is
> fabricated. Values are anchored to existing in-corpus data (`sprint-defaults.md`,
> `estimation-standards.md`) wherever a quantitative anchor exists; every value not so
> anchored is tagged `UNSOURCED-DOMAIN` inline.

---

## 1. The Capacity Formula

Effective per-project delivery capacity for a team working across **N concurrent projects**
is a multiplicative chain — each factor strips a known loss from the nominal hours:

```
Nominal hours      = team_members × working_hours/day × sprint_days
Focus-adjusted     = Nominal hours × FF              (FF from §2; canonical source estimation-standards.md §3)
Context-adjusted   = Focus-adjusted × CS(N)          (CS(N) context-switch multiplier from §3)
Effective capacity = Context-adjusted × allocation   (work-class allocation from §5)
```

The chain is multiplicative (not additive) so the factors **compose into a single product**
and never double-count a loss: the focus factor removes the within-project overhead
(meetings, email, ceremony), and the context-switch multiplier `CS(N)` removes the
*additional* cross-project tax that running N projects in parallel imposes on top of it.

**Effective rate** (the headline figure) is `FF × CS(N)` — the fraction of nominal hours
that survives to planned, per-project delivery before the work-class split is applied.

### Worked example — the acceptance case: team of 2, **3 concurrent projects**

```
FF              = 0.65            (canonical default, from estimation-standards.md §3 focus-factor table)
CS(3)           = 0.90            (context-switch multiplier at N = 3 concurrent projects, §3)

Effective rate  = FF × CS(3)
                = 0.65 × 0.90
                = 0.585           ≈ 60% effective per project        ← AC satisfied

Per-project hours (2-week sprint, 8 h days, 2-person team):
  Nominal       = 2 × 8 × 10                       = 160 h
  × FF 0.65                                        = 104 h
  × CS(3) 0.90                                     =  93.6 h   (≈ 58.5% of the 160 nominal h — the "~60% effective")
```

So a 2-person team carrying **3 concurrent projects** converts its **160 nominal hours**
into **≈ 93.6 effective hours *per project*** — not the full 160 — because the
context-switching tax of running three in parallel multiplies an additional `CS(3) = 0.90`
onto the focus-adjusted figure. The headline effective rate is **0.585 ≈ 60%**, satisfying
the acceptance criterion (capacity for a team of 2 on 3 projects shows ~60% effective with
the context-switching penalty applied).

> The work-class split (§5) is applied *after* this point when the planner needs the
> committed-delivery slice specifically: `Committed delivery ≈ 93.6 h × 0.60 ≈ 56 h` per
> project, with the remaining effective hours reserved for unplanned work and improvement.

---

## 2. Focus Factor (reference-only — owned by estimation-standards.md)

The **focus factor (FF)** is the first multiplier in §1 — the fraction of nominal hours
left for planned work after meetings, email, ceremony, and *within-project* context
switching. **This doc does not define a focus-factor table.**

**Canonical source: [`estimation-standards.md` §3 Canonical Focus-Factor Table](estimation-standards.md).** Read FF and its valid range from that table by its role; do not
restate the value here. As of the canonical table's current state, **FF = 0.65** (valid
range **0.60 – 0.75**); this doc's worked examples (§1) use **0.65**, but the live value is
always whatever the canonical table holds — a change to the default or range is made in
`estimation-standards.md` §3 and inherited here automatically.

> **Why referenced, not restated:** the focus factor has exactly one canonical home so it
> cannot drift. `estimation-standards.md` §3 is the owner; this doc and `sprint-defaults.md`
> §1.2 are consumers that cite the table by role. Defining a second copy here would
> re-create the triple-source the consolidation in `estimation-standards.md` exists to
> retire.

---

## 3. Context-Switching Penalties

Running a team across multiple concurrent projects imposes a productivity tax *on top of*
the within-project focus-factor loss: every switch carries a re-orientation cost, and the
cost grows with the number of parallel projects. This penalty is expressed as a
**multiplier `CS(N)`** keyed by the concurrent-project count `N`, applied to the
focus-adjusted hours in §1.

| Concurrent projects (N) | Context-switch multiplier `CS(N)` | Effective productivity per project | Consistency with the in-corpus anchor |
|---|---|---|---|
| **1** | **1.00** | 100% of focus-adjusted | dedicated — no cross-project penalty |
| **2** | **0.95** | ~95% per project | mild penalty |
| **3** | **0.90** | ~90% per project | **the acceptance case** (§1 worked example) |
| **4** | **0.80** | ~80% per project | approaching the danger zone |
| **5+** | **0.20 – 0.55** (steep) | **5 – 20% per project at the high end** | **directly adopts the `sprint-defaults.md` §1.2 datum** |

**Anchoring (normative).** The **5+ row directly adopts** the existing in-corpus datum in
[`sprint-defaults.md` §1.2](sprint-defaults.md) — *"Context switching at 5+ concurrent
projects reduces effective productivity to 5-20% per project."* The two MUST never
contradict: at `N ≥ 5` this table and `sprint-defaults.md` §1.2 state the same 5–20% floor.
The **N = 1…4 ramp is `UNSOURCED-DOMAIN`** best-practice (Weinberg context-switching loss —
the classic domain reference puts per-added-task loss at ~10–20%), chosen so the curve
(a) starts at `1.00` for a dedicated team, (b) passes through `0.90` at N = 3 to satisfy the
acceptance case, and (c) lands on the existing 5–20% figure at N = 5+.

**Application rule.** Use the multiplier form, not a flat subtraction, so `CS(N)` composes
with FF into the single product of §1. When a team's concurrent-project count crosses into
the **5+ steep zone**, the penalty is no longer a planning nuisance but a structural signal:
flag it (the team is over-spread) rather than silently planning at the diminished rate.

---

## 4. Brooks's-Law Thresholds (team-growth drag)

> *"Adding manpower to a late software project makes it later."* — Brooks, *The Mythical
> Man-Month*. The thresholds below are `UNSOURCED-DOMAIN` (classic SE reference), anchored
> to the existing `sprint-defaults.md` §2.1 team-split threshold so the doc set agrees.

Adding people to a team does not buy linear throughput, and inside a deadline-bound effort
it can buy *negative* near-term throughput. Three rules govern team growth:

| Rule | Threshold / model | Consequence |
|---|---|---|
| **(a) Onboarding ramp-down** | A new member runs at reduced effective capacity for an onboarding window (model a **ramp-down period of ~2–6 weeks**, per the vendor curve in §7) during which an existing member's time is partly consumed mentoring | Net team capacity **drops** before it rises — adding a person to a late project subtracts near-term throughput |
| **(b) Communication-overhead ceiling** | Pairwise communication paths grow as **n(n − 1)/2** with team size n; beyond a soft ceiling the coordination cost dominates the added throughput | At **> 9 members → split the team** (consistent with `sprint-defaults.md` §2.1, "8–10 … approaching team split threshold") |
| **(c) Deadline ramp-window freeze** | Do **not** add headcount inside the final ramp-window of a deadline-bound effort | The onboarding ramp-down (rule a) lands precisely when there is no slack to absorb it, making the deadline *less* likely, not more |

**Application rule (normative).** When a capacity shortfall is detected late in a
deadline-bound effort, **do not default to "add people."** Per rule (c), added headcount
inside the ramp-window degrades near-term capacity (rule a); the legitimate levers are
scope reduction, reprioritization, or — if headcount must be added — accepting the
ramp-down cost explicitly and re-baselining the deadline. The `n(n − 1)/2` ceiling (rule b)
makes "just add more people" self-defeating well before the team is large.

---

## 5. 60/20/20 Effort-Allocation Split (capacity domain)

> **Disambiguation (read first).** This is the **capacity-domain** effort split — how a
> managed team's *standing* capacity is apportioned across work classes. It is **distinct
> from** the *release-bundle* "60/20/20 allocation" used at **Stage 3 Bundle**
> ([`stage-03-bundle.md`](../../../../release/references/pipeline/stage-03-bundle.md)),
> which is an **issue-type mix** for a release bundle (≤5–8 issues: ~60% feature / 20% debt
> / 20% protocol). **Different concept, same digits** — an agent grepping "60/20/20" will
> hit both meanings; this section is the capacity-domain one.

The capacity-domain 60/20/20 split apportions a managed team's effective capacity (the
output of §1) across three work classes:

| Slice | Share | Work class | What it covers |
|---|---|---|---|
| **Planned delivery** | **60%** | Committed, prioritized backlog work | The sprint/iteration commitment — features and scoped stories |
| **Unplanned reserve** | **20%** | Interrupts, production noise, in-flight discoveries | Buffer so the commitment survives the inevitable unplanned arrivals |
| **Improvement + tech-debt** | **20%** | Refactoring, tooling, debt paydown, learning | Non-negotiable floor that prevents debt accumulation and capability decay |

**Relationship to `sprint-defaults.md` §1.2 (normative, one sentence).** The 60/20/20 split
is the **steady-state team-allocation target**; the per-sprint knobs in
[`sprint-defaults.md` §1.2](sprint-defaults.md) (75% planned utilization, 20% unplanned
reserve, 15% tech-debt minimum) are the **per-iteration planning dials that realize it** —
the steady-state target and the per-sprint dials are two lenses on the same capacity, not a
contradiction (the per-sprint figures are applied within a single iteration; the 60/20/20
is the standing apportionment across iterations). The split values are `UNSOURCED-DOMAIN`
best-practice.

---

## 6. Team-Stability Threshold

A team's velocity history is only trustworthy if the team that produced it is the team that
will deliver next. Membership churn resets that trust.

| Parameter | Threshold | Anchor |
|---|---|---|
| **Stable-membership window** | Velocity history is treated as **reliable only after ≥ 6 consecutive sprints with unchanged core membership** | Anchored to [`sprint-defaults.md` §3.1](sprint-defaults.md) velocity-stabilization timeline (6–8 sprints = reliable baseline) |
| **Membership-change reset** | A core-membership change (add or lose a member) **resets the stable-sprint counter to zero** | A post-change velocity is an *emerging* signal (`±50–100%` band per `sprint-defaults.md` §3.1), not a reliable baseline |

**Application rule (normative).** Do not forecast from a velocity history shorter than the
stable-membership window, and **treat any core-membership change as resetting the clock** —
the velocity from before the change does not carry forward as a reliable baseline. A planner
that ignores a recent membership change and forecasts from the pre-change velocity is
asserting a stability the team does not have. (This is the in-corpus complement to
`estimation-standards.md` §5 velocity-as-range enforcement: even a stable team's velocity is
a range, and an unstable team's is wider still.)

---

## 7. Vendor Ramp-Up Timeline

A vendor or contractor augmentation is a special case of added headcount (it triggers the
Brooks's-Law onboarding ramp-down, §4 rule a) and reaches productivity on a curve, not a
step. The time-to-productivity curve below is `UNSOURCED-DOMAIN` best-practice:

| Tenure window | Effective productivity (vs. a ramped team member) | Notes |
|---|---|---|
| **0 – 2 weeks** | **~25%** | Environment access, codebase orientation, domain context; consumes mentoring time from an existing member |
| **2 – 6 weeks** | **~60%** | Contributing on bounded, well-specified work; still needs review depth |
| **6 – 12 weeks** | **~90%** | Approaching parity on the team's work; near-full effective contribution |

**Application rule (normative).** When sizing capacity that includes a vendor in the
0–12-week window, **discount the vendor's nominal hours by the curve** — do not count a
week-one vendor as a full team member. The curve **composes with §4 rule (a)**: a vendor
added inside a deadline ramp-window both ramps slowly (this table) *and* consumes an existing
member's mentoring time (Brooks), so the near-term net capacity addition can be small or
negative.

---

## 8. Bus-Factor Rules (managed-team lens)

> **Platform-level bus-factor is owned elsewhere — do not restate it here.** The
> pmo-platform *itself* is single-operator; per
> [`km-protocols.md` §4 Bus-Factor Rules](../../../../core/disciplines/km-protocols.md#bus-factor),
> **bus-factor = 1 is a named accepted residual, not a defect** — the operating model is
> single-operator, and the codified K1 corpus (files-are-the-memory + auto-memory +
> governance corpus) is the standing structural control. This section does **not** restate,
> override, or contradict that rule; it scopes a *different* context.

This section addresses bus-factor only as a **staffing-concentration risk for the managed
delivery team** the TPM plans for — a distinct context from the single-operator platform:

| Aspect | Managed-team lens (this doc) |
|---|---|
| **What it measures** | How many team members hold the working knowledge of a given component, integration, or domain |
| **The risk signal** | A component whose knowledge sits with **one** team member is a **delivery risk** — that member's absence (PTO, illness, attrition) stalls or de-risks the work |
| **Capacity treatment** | Surface single-owner components as a **capacity signal** when planning: flag for **cross-training** or **codification** so the team's effective capacity is not silently coupled to one person's availability |
| **What it does NOT do** | It does **not** set a platform-wide "bus-factor ≥ N" rule — for the platform itself, `km-protocols.md` §4 governs (bus-factor = 1 accepted) |

**Application rule (normative).** When modeling a managed team's capacity, treat a
single-owner component as a **staffing-concentration risk to surface**, not as a number to
enforce: name the component, the sole owner, and the mitigation (cross-train or codify) per
the "No passive risk voice" guardrail. For the **platform's own** bus-factor posture, defer
entirely to `km-protocols.md` §4 — this doc adds no competing rule.

---

## 9. Demand-Supply Gap RAG Thresholds

The demand-supply gap measures whether a team's **committed demand** fits inside its
**effective supply** (the §1 output). It is expressed as a ratio and banded RAG:

```
Demand-supply ratio = committed demand (planned work, in the team's unit)
                      ÷ effective supply (effective capacity from §1, same unit)
```

| Band | Ratio | Reading | Action |
|---|---|---|---|
| **🟢 Green** | **≤ 0.85** | Committed demand fits inside effective supply with headroom | Healthy — the unplanned-reserve slice (§5) is intact |
| **🟡 Amber** | **0.85 – 1.00** | Demand approaches the supply ceiling; reserve is being consumed | Watch — protect the reserve; resist mid-sprint scope additions |
| **🔴 Red** | **> 1.00** | **Over-committed** — demand exceeds effective supply | Act — re-scope, de-commit, or re-baseline; do not plan into the red |

**Anchoring (normative).** The **Green ceiling at 0.85** is anchored to the
[`sprint-defaults.md` §1.2](sprint-defaults.md) planned-utilization cap (75%, valid range
70–85%) — the existing rule that a team is never planned above 85% utilization. The Green
band therefore aligns with the existing utilization cap rather than introducing a divergent
threshold. The Amber/Red boundaries above 0.85 are `UNSOURCED-DOMAIN` best-practice.

**Application rule.** Mode E reads this band when an at-risk assessment hinges on whether
committed demand exceeds effective supply. A **Red** reading is not a status note — it is a
forcing function: the commitment cannot be met from current effective supply, and the
planner surfaces the de-commit / re-scope / re-baseline decision rather than reporting the
team "behind."

**Cross-reference — buffer-consumption and milestone-variance RAG (owned by estimation-standards.md).**
Two related discipline parameters live in the estimation-domain reference doc, not here:
the **buffer-consumption RAG banding** ([`estimation-standards.md` §4.1](estimation-standards.md))
and the **milestone-variance (SPI) RAG** ([`estimation-standards.md` §7](estimation-standards.md)).
Read them there by role; this doc does **not** restate the bands (duplicate-source-discipline —
estimation-standards.md owns estimation/buffer/variance, this doc owns supply). One shared
anchor binds the two docs: the **0.85 Amber→Red ceiling** in this section's demand-supply
band is **the same structural boundary** that estimation-standards.md §4.1 adopts as its
buffer-consumption Yellow→Red boundary, so buffer-Red and demand-Red fire at one point across
the skill.

---

## Applicability

Per [`applicability-framework.md`](../../../../core/disciplines/applicability-framework.md).
The capacity model below is a **contextual** practice (org-scale + methodology axes) — it
applies to the capacity of a *managed delivery team*, not to the single-operator platform
running the PMO.

- **Universality:** contextual            # org-scale axis + methodology axis
- **Applies when:** the capacity being modeled is that of a **managed delivery team**
  (`org_scale ∈ {small-team, multi-team}` for the team under management) — the agile
  squads a TPM plans for.
- **Contraindicated when:** **CI-5** — do **NOT** apply concurrent-project context-switching
  penalties (§3), the demand-supply RAG bands (§9), or the team-allocation split (§5) to the
  **single-operator PMO's own throughput** (the operator is not a sprint team, and
  bus-factor = 1 for the platform is governed by `km-protocols.md` §4, not by §8 here); also
  **CI-4** for the velocity-dependent thresholds (§6) on non-time-boxed (Waterfall/PRINCE2)
  tracks.
- **On conflict:** `decision-discipline.md` M1 (contextual localization); co-manifestation
  when `dual_framing_enabled: true` — produce both the agile capacity framing and the
  phase-gate framing rather than forcing one.

---

## Anti-Patterns

### Planning concurrent-project teams at full focus factor — PROC

- **Signature (observable signal):** A sprint plan sizes a team carrying multiple
  concurrent projects at `Nominal × FF` only, with no `CS(N)` multiplier — the per-project
  effective hours equal the single-project figure despite N > 1.
- **Conditional:** do NOT size per-project capacity at `FF` alone when the team carries
  N > 1 concurrent projects, because the cross-project context-switch tax (§3) is a real
  loss on top of FF, and omitting `CS(N)` over-commits the team by the full switching penalty
  (10% at N = 3, far more at N = 5+).
- **Root cause:** Treating the focus factor as if it already captures cross-project
  switching — it does not; FF is the *within-project* overhead, `CS(N)` is the *additional*
  cross-project tax. Collapsing the two double-counts availability.
- **Mitigation:** When N > 1, apply the full §1 chain — `Nominal × FF × CS(N)` — reading
  `CS(N)` from the §3 table for the team's concurrent-project count; surface the penalty in
  the capacity model so the operator sees the cross-project cost.
- **Principal-vs-junior response:** A junior plans at FF and reports the team "has capacity";
  a principal applies `CS(N)`, shows the ≈ 58.5% effective rate at N = 3, and flags that the
  team is spread across too many projects when N reaches the 5+ steep zone.

### Adding headcount inside a deadline ramp-window expecting immediate throughput — PROC

- **Signature (observable signal):** A capacity shortfall late in a deadline-bound effort is
  answered by "add a person / pull in a vendor," with the plan crediting the addition at full
  capacity from week one.
- **Conditional:** do NOT add headcount inside the final ramp-window of a deadline-bound
  effort expecting immediate throughput, because Brooks's Law (§4) makes the onboarding
  ramp-down (§4 rule a, §7 vendor curve) land precisely when there is no slack to absorb it —
  net near-term capacity drops, making the deadline less likely.
- **Root cause:** Modeling headcount as instantly fungible — ignoring that a new member runs
  at reduced effective capacity for 2–6 weeks (§7) and consumes an existing member's
  mentoring time during that window.
- **Mitigation:** Late in a deadline-bound effort, reach for scope reduction or
  reprioritization first; if headcount must be added, model the §7 ramp curve and the §4
  ramp-down explicitly and re-baseline the deadline rather than crediting full capacity.
- **Principal-vs-junior response:** A junior adds a body and reports capacity restored; a
  principal shows the ramp-down dip, names the `n(n − 1)/2` communication ceiling, and either
  cuts scope or re-baselines with the ramp cost made visible.

### Forecasting from velocity history across a membership change — INPUT

- **Signature (observable signal):** A forecast or capacity plan uses a velocity baseline
  whose window spans a core-membership change (a member joined or left), treating the
  pre-change velocity as still reliable.
- **Conditional:** do NOT forecast from a velocity baseline that spans a core-membership
  change without resetting the stable-sprint counter, because a membership change resets the
  team's velocity trust to an emerging (`±50–100%`) signal (§6), and forecasting from the
  pre-change figure asserts a stability the team no longer has.
- **Root cause:** Treating velocity as a property of the *role slots* rather than of the
  *specific stable team* — a changed team is a new system whose throughput must re-stabilize.
- **Mitigation:** On any core-membership change, reset the stable-membership window (§6) and
  treat post-change velocity as an emerging range until ≥ 6 stable sprints accrue; widen the
  forecast band accordingly and state that the change reset the baseline.
- **Principal-vs-junior response:** A junior carries the old velocity forward and forecasts
  tightly; a principal flags the membership change, widens the range to the emerging band, and
  qualifies the forecast as low-confidence until the team re-stabilizes.
