<!-- reference-durability: allow-link -->
<!-- provenance: UNSOURCED-DOMAIN -->

# Estimation Standards

## Purpose

This document is the canonical source of **estimation discipline** for the delivery-engine skill — how an estimate's precision is bounded by lifecycle phase, how far out work may be committed versus forecast, the **canonical focus-factor table this doc owns**, the three-zone buffer model, the **buffer-consumption RAG banding** (§4.1), the rule that velocity and derived estimates are expressed as ranges rather than points, the contingency-versus-management-reserve distinction, the **milestone-variance (SPI) RAG banding** (§7), and the **estimation-calibration loop** — the post-hoc estimate-versus-actual measurement, its bias band, and its consumer contracts (§8). It is read by the delivery-engine skill: **Mode D (Sprint Planning)** reads the Cone-of-Uncertainty band widths, planning-horizon commitment rules, the focus-factor table, the buffer model, the buffer-consumption banding, the milestone-variance RAG, and the estimation-calibration loop (§8) when building a capacity model and sprint scope; **Mode E (Execution Control Tower)** reads the velocity-as-range enforcement rule (§5) when reporting velocity or capacity.

**Sibling relationship.** This doc is the topical home for **estimation** parameters. Its two siblings own adjacent axes: `sprint-defaults.md` owns sprint **cadence** parameters (sprint length, WIP limits, velocity-stabilization windows, ceremony time-boxes) and the iteration-vs-flow decision model; the capacity-model reference doc (this skill's `references/` set) owns the **supply** calculation (available-hours derivation, effective capacity). Where those docs need the focus factor, they reference the canonical table in §3 of this doc by its role and do not restate the value — see the Consumers note in §3.

**Content provenance: `UNSOURCED-DOMAIN`.** This doc was authored from the originating issue's Description (Cone of Uncertainty, planning-horizon rules, focus-factor table, buffer three-zone model, velocity-as-range enforcement, contingency vs. management reserve) plus `domain: governance/PMO` best-practice (Boehm's Cone of Uncertainty; PMI estimation and reserve-analysis conventions; story-point range estimation) and the existing sibling reference docs. The detailed "full content spec" the originating issue cited (an upscale gap analysis) is **absent from the repository**; no citation to it is fabricated. The quantitative tables below are derived from the named domain anchors. The **focus-factor value (§3) is in-corpus-grounded** — it is promoted unchanged from the sole prior occurrence in `sprint-defaults.md` §1.2, not invented here.

---

## 1. Cone of Uncertainty

The reliability of an estimate is a function of how much is known when it is made. Early in a project's life, the same scope can credibly cost a multiple of — or a fraction of — the point figure; the achievable precision tightens as the work moves through its lifecycle phases. The table below maps lifecycle phase to the **estimate-variance band** that bounds a credible range at that phase.

| Lifecycle phase | What is known | Variance band (low × — high ×) | Worked illustration (point figure = 100) |
|---|---|---|---|
| **Initial concept** | A named idea; no requirements | 0.25× – 4× | a credible range is 25 – 400 |
| **Approved concept** | Funded; high-level scope agreed | 0.5× – 2× | a credible range is 50 – 200 |
| **Requirements defined** | Requirements baselined | 0.67× – 1.5× | a credible range is 67 – 150 |
| **Design complete** | Solution designed; interfaces known | 0.8× – 1.25× | a credible range is 80 – 125 |
| **Build underway** | Construction started; few unknowns | 0.9× – 1.1× | a credible range is 90 – 110 |

**Cone rule (normative).** An estimate's stated range MUST be **no tighter than the variance band for the item's current lifecycle phase**. A range narrower than the phase band asserts a precision the phase does not support and is rejected — widen the range to at least the band, or advance the item to the next phase before committing a tighter figure. The band only ever tightens as the work matures; it never widens, so re-estimating at a later phase may legitimately narrow a range but re-estimating at an earlier phase may not narrow one.

**Reading the band.** The band is multiplicative around the current point figure, not additive. At Design-complete (0.8× – 1.25×) a 10-point item carries a credible range of 8 – 13 points; quoting "10 points" flat at that phase violates the velocity-as-range rule (§5), and quoting "10 – 10.5" violates this cone rule (tighter than the 0.8× – 1.25× band).

---

## 2. Planning-Horizon Rules

How precisely work may be expressed depends on how far out it sits. Near-term work is committed; mid-term work is a forecast range; far-term work is a notional theme-level placeholder. The table below sets the estimate-class and the allowed precision per horizon.

| Horizon | Estimate class | Allowed precision | Commitment semantics |
|---|---|---|---|
| **Current iteration** | Committed | Item-level points within the phase cone band (§1); a Sprint Goal is a commitment, individual item completion is a forecast | The team commits to the Sprint Goal, not to every item |
| **Next 1–2 iterations** | Forecast | Range only (range no tighter than the phase cone band); no per-item commitment | Used for near-term sequencing and dependency staging |
| **Beyond the forecast horizon** | Notional | Theme- or epic-level magnitude only (e.g., T-shirt size); no story-point figure | Used for roadmap shaping; re-estimated when it enters the forecast horizon |

**Horizon rule (normative).** No work item carries a **point commitment beyond the committed horizon** (the current iteration). Work in the forecast horizon is expressed as a range; work beyond it is expressed at theme/epic magnitude only. An estimate that commits a specific point figure to an item two or more iterations out asserts a confidence the horizon does not support and is downgraded to a forecast range (or to theme magnitude, per the horizon).

**Interaction with the cone (§1).** The two rules compose: the cone bounds **how tight** a range may be at a given maturity; the horizon bounds **whether a point or a range** is even permitted at a given distance. A near-term item at Build-underway may quote a tight (0.9× – 1.1×) range; a far-term item at Initial-concept may quote only a theme magnitude — and never a point.

---

## 3. Canonical Focus-Factor Table (OWNER)

**This doc is the single canonical source for the focus factor.** The focus factor is the fraction of nominal team hours actually available for planned delivery work, after meetings, email, context-switching, and ceremony overhead are removed. It is applied by the supply calculation when deriving effective capacity from available hours.

| Parameter | Default | Valid range | Drivers (what the factor accounts for) |
|---|---|---|---|
| **Focus Factor** | **0.65** | **0.60 – 0.75** | Meetings, email and messaging, context-switching, ceremony overhead (planning, review, retro, refinement) |

**Calibration guidance.** Start a new or unmeasured team at the **0.65** default. Move toward the top of the range (0.75) for a co-located, single-initiative team with low ceremony overhead and minimal context-switching; move toward the bottom (0.60) for a team carrying multiple concurrent initiatives, heavy meeting load, or frequent interrupt work. Calibrate from observed delivered-vs-planned ratios over a stabilized velocity window rather than asserting a figure — the range is the credible band, the default is the starting point.

**Consumers note.** Referenced by: `sprint-defaults.md` §1.2 (capacity planning — the row points here and shows 0.65 only inside its worked arithmetic example, annotated as the canonical default); the capacity-model reference doc (this skill's `references/` set — effective-capacity calculation). These docs cite this table by its role and **do not restate the value**, so the focus factor has exactly one canonical home. A change to the default or range is made here and inherited by every consumer; no consumer holds a divergent copy.

---

## 4. Buffer Three-Zone Model

Reserve is held at three distinct zones, each covering a different class of uncertainty, owned by a different authority, and released by a different mechanism. Conflating them — for example funding an unknown-unknown from the iteration buffer — is the failure this model forecloses.

| Zone | What it covers | Risk class | Who owns it | Typical size band | Release mechanism |
|---|---|---|---|---|---|
| **(a) Iteration buffer** | Intra-sprint unplanned work: interrupts, small discoveries, production noise | Known-unknown (within the sprint) | The delivery team | ~15 – 30% of sprint capacity (the unplanned-work reserve) | Consumed silently within the sprint; not requested |
| **(b) Feature / release buffer** | Contingency for identified, scoped risk inside the release baseline | Known-unknown (within scope) | The team or the PM | Risk-sized; set by the magnitude of the identified in-scope risks | Drawn down as in-scope risks materialize; tracked against the baseline |
| **(c) Management reserve** | Genuinely unforeseen scope — outside the baseline | Unknown-unknown (outside scope) | The sponsor / governance | Held above the team; sized by portfolio risk appetite | Released only by a formal governance decision; never auto-consumed |

**Buffer rule (normative).** **Never fund an unknown-unknown from a known-unknown buffer.** Iteration and feature buffers (zones a and b) cover risks that are inside scope and already identified; they are not a slush fund for genuinely new scope. New, unforeseen scope is funded from management reserve (zone c) by an explicit governance release — surfacing the reserve draw as a decision, not absorbing it silently. This rule sets up the contingency-vs-management-reserve distinction in §6.

---

## 4.1 Buffer-Consumption Banding

The §4 three-zone model answers **which reserve owns a risk** (iteration / feature / management) — a risk-class and ownership taxonomy. This section answers a different, orthogonal question: **how much of the buffer is already burned.** A planner needs both — a 70%-consumed iteration buffer is a healthy ownership story (zone a is the right reserve) and a worrying consumption story (the watch band). Do not conflate the two: naming the active consumption band is never the same as naming the §4 ownership zone.

The band is a 🟢/🟡/🔴 RAG on the **fraction of the iteration buffer (zone a) consumed** — consumed ÷ the established iteration-buffer figure (~15–30% of sprint capacity, per §4 zone a).

| Band | Iteration-buffer consumed | Reading | `WHEN…THEN…` decision rule |
|---|---|---|---|
| **🟢 GREEN** | **≤ 0.50** | Buffer healthy; ample reserve remains for intra-sprint unplanned work | WHEN consumption ≤ 0.50 THEN treat the buffer as intact — no escalation; plan normally |
| **🟡 YELLOW** | **0.50 – 0.85** | Watch; reserve is eroding and a few more interrupts exhaust it | WHEN consumption is 0.50–0.85 THEN flag the watch state — resist mid-sprint scope additions and protect the remaining reserve |
| **🔴 RED** | **> 0.85** | Buffer near or over exhausted; the next unplanned arrival breaks the commitment | WHEN consumption > 0.85 THEN escalate — re-scope, de-commit, or draw a higher reserve zone (§4 b/c) by explicit decision; do not silently absorb further unplanned work |

**Boundary anchoring (normative — both boundaries adopt existing in-corpus values, neither is invented).** The **0.85 Yellow→Red boundary is the same ceiling, by role, as the demand-supply Amber→Red boundary** in the capacity-model reference doc's §9 Demand-Supply Gap RAG (itself anchored to the 85% planned-utilization cap in `sprint-defaults.md` §1.2). Buffer-Red and demand-Red therefore fire at one structural point — the skill carries **one** 0.85 ceiling, not two competing ones. The **0.50 Green→Yellow boundary is the design midpoint of the §4 zone-a iteration-buffer band** (~15–30%) — "half the buffer consumed" is the natural watch threshold.

**Application rule.** When a buffer-consumption figure is available, name the active band and its decision rule. When no iteration-buffer figure has been established, the band **cannot be computed** — state that explicitly and recommend establishing the iteration-buffer figure (§4 zone a, ~15–30% of sprint capacity); never default the band to GREEN on absent input.

---

## 5. Velocity-as-Range Enforcement

**Velocity, and every estimate derived from it, is expressed as a range — never a single point value.** A point figure asserts a precision that the Cone of Uncertainty (§1) does not support at any pre-Build phase and that velocity variance does not support even for a stable team. This section is the normative home of that rule and the agent behavior it requires.

**Range rule (normative).** A bare point estimate is **rejected** and **returned as a range**. The returned range is **no tighter than the Cone-of-Uncertainty band (§1) for the item's current lifecycle phase**, and for velocity it is built from the last 3–5 completed iterations (minimum / average / maximum, outlier iterations excluded with documentation per the velocity-stabilization rules in `sprint-defaults.md` §3). An estimate or velocity figure emitted as a single number violates this rule.

**Worked agent-behavior example.**

> **Input:** "5 story points."
> **Response:** REJECT — a point estimate is not accepted. Returned as a range (here, **"5 – 7 story points"**) rather than a single figure. The returned range is set **no tighter than the item's Cone-of-Uncertainty band for its current phase (§1)** — §1 defines how the band sets the width (e.g., 100 → 80 – 125; 10 → 8 – 13 at Design-complete). State the phase and the band that produced the width.

The range is never tighter than the phase band: at an earlier phase the same 5-point figure returns a wider range (at Requirements-defined, the 0.67× – 1.5× band gives ~3 – 8); at Build-underway it may return a tighter one (0.9× – 1.1× gives ~5 – 6). The phase, not the convenience of a round number, sets the width.

**Guardrail cross-walk.** delivery-engine **Mode D** (Sprint Planning) and **Mode E** (Execution Control) inherit this rule. A Mode D capacity model or a Mode E velocity report that emits a **point** value violates this rule and the `Velocity gaming` anti-pattern remediation in `sprint-defaults.md` §6 (velocity used for planning only, tracked as a range; point-figure velocity invites the Goodhart's-Law inflation that the anti-pattern warns against). When either mode would emit a point figure, it returns the range instead and cites the phase band that set the width.

---

## 6. Contingency vs. Management Reserve

Contingency and management reserve are both "reserve," but they answer different risk classes, sit at different baseline positions, are owned by different authorities, and are released by different mechanisms. The platform keeps them distinct because funding one from the other (§4's buffer rule) hides risk and bypasses governance.

| Dimension | Contingency reserve | Management reserve |
|---|---|---|
| **Risk class** | Known-unknowns — identified risks with estimated impact | Unknown-unknowns — genuinely unforeseen scope or events |
| **Baseline position** | **Inside** the cost/schedule baseline | **Outside** the baseline (held above it) |
| **Who owns it** | The project — team or PM | The sponsor / governance authority |
| **Release mechanism** | Consumed by the project as identified risks materialize; tracked against the baseline | Released only by a **formal governance decision**; converting it into baseline is itself a baseline change |
| **Estimate relationship** | Part of the estimate (the estimate already carries it) | Not part of the estimate (the estimate excludes it) |
| **Maps to buffer zone (§4)** | Zones (a) iteration buffer + (b) feature/release buffer | Zone (c) management reserve |

**Reserve rule (normative).** **Never fund an unknown-unknown from contingency.** Contingency is sized to the identified, in-scope risks and is exhausted legitimately only by those risks. When genuinely new scope appears, it is funded from **management reserve** by a formal governance release — which surfaces the new scope as a decision and keeps the baseline honest — not absorbed silently into contingency, which would hide the scope growth and erode the risk signal the two-tier model exists to preserve.

---

## 7. Milestone-Variance RAG

Milestone variance measures whether a milestone is **ahead of, on, or behind** its schedule baseline, and bands the answer RAG so a single milestone-level health signal is consistent with the platform's schedule-health convention. It is expressed as the **Schedule Performance Index (SPI)** — the EVM-standard schedule-earned ratio that the gate-checklists reference doc already cites (CPI/SPI tolerance) — not as an ad-hoc ±%-slip figure.

```
Milestone variance (SPI) = earned schedule value (work completed, in baseline units)
                           ÷ planned schedule value (work that should be complete by now, same units)
```

An SPI of 1.00 is exactly on schedule; below 1.00 is behind; above 1.00 is ahead.

**Band adoption (normative — single-sourced by reference, not restated here).** The 🟢 / 🟡 / 🔴 SPI band thresholds are **defined canonically** in the comms-writer reference doc's [`channel-formats.md`](../../comms-writer/references/channel-formats.md) § RAG Threshold Standards (row **Schedule (SPI)**), which the weekly-status-rollup metric-registry already consumes by reference for SPI. §7 **adopts that single platform schedule-RAG convention by reference** and does not restate the band values here — there is exactly one owner for the thresholds, and this doc reuses it rather than forking a parallel band.

**Milestone application of the band (normative).** Band the milestone's SPI against that canonical Schedule (SPI) standard, then apply the milestone-specific decision rule:

- **🟢 GREEN** — on or ahead of schedule (within tolerance): report on-track; no milestone escalation.
- **🟡 YELLOW** — slipping, recoverable but eroding: flag the milestone at the next status; watch the critical path and name the recovery lever.
- **🔴 RED** — materially behind, baseline at risk: escalate — replan the critical path and surface the re-baseline / de-scope decision; do not report the milestone merely "behind."

**Naming guard (normative).** Name this metric **"milestone variance (SPI)"** or **"milestone slip"** — **NEVER "Schedule Variance."** The "Schedule Variance" label is reserved against to avoid collision with the EVM Schedule Variance (SV = earned − planned, a *cost*-denominated figure), per the metric-registry naming rule. The milestone-variance signal here is the *index* (SPI ratio), not the EVM SV difference.

**Application rule.** Compute and band milestone variance only when a **schedule baseline exists** (a planned milestone %-complete or earned/planned schedule value). When no baseline exists, the SPI **cannot be computed** — emit `variance: not computable — no schedule baseline` and flag the missing baseline as a planning gap; never fabricate a RAG color on absent input.

---

## 8. Estimation-Calibration Loop

§1–§7 set how an estimate is *bounded* before the work is done. This section closes the loop from the other side: it measures, after the work is done, **how far the estimates actually landed from the outcomes**, and defines the one governed way that measurement is expressed, banded, and fed forward.

**Scope and altitude.** The unit of analysis is **one team · one signal family (§8.1) · one window of 3–5 completed iterations**. Per-item figures are inputs only and are never reported as a team signal. **Per-person attribution and cross-team comparison are prohibited** — `sprint-defaults.md` §3.2 rules 3 and 5 (velocity is team-specific and is never a performance metric) extend to this metric by identical reasoning, and are restated here rather than left implicit for a new measure. **Portfolio-altitude rollup is out of scope for this section** and belongs to a separate sibling item; a rollup would first have to solve cross-team unit incommensurability, which is a different problem from this one. This section builds no rollup hook.

**Content provenance: in-corpus-grounded.** Every boundary, window, threshold, and controlled vocabulary in this section is **adopted from an existing in-corpus owner** — §1's Cone-of-Uncertainty rows, §5's velocity window, `sprint-defaults.md` §3.1/§3.2, and `core/schemas/gate-evaluation-spec.md` § Layer 3. **No value in this section is minted here.** Where a figure is derived rather than adopted, the derivation is shown (§8.4).

**Validity threats are declared before any conclusion is drawn.** This is a measurement method, and its six known threats — **V1** small-sample instability · **V2** survivorship · **V3** re-scoring circularity · **V4** Goodhart pressure · **V5** unit drift · **V6** self-normalization — are stated in full, with mitigations and honest residuals, in **§8.7**. **§8.7 is read before a §8 output is treated as a finding**, not after. The evidence-quality bar in §8.7 is normative and binds every emission.

---

### 8.1 The estimation ratio (per item)

```
Estimation ratio    R = actual ÷ estimate        (same unit on both sides; estimate > 0)
```

**Sign convention (normative).** `R` is **always** `actual ÷ estimate` — the arithmetic never inverts. `R = 1.00` is exact, and the direction of the miss is carried by **which side of 1.00** the figure sits on, exactly as §7's SPI carries schedule direction. **A bare `|R − 1|`, a bare "accuracy %", or any other absolute-error form is prohibited**: collapsing direction destroys the only information that selects a corrective lever (§8.2).

**The three signal families.** Each family pairs a different promise with a different outcome. They are computed and reported separately.

| | Family | `estimate` (the promise) | `actual` (the outcome) | Unit | Grain | `R > 1.00` reads as | Concern side |
|---|---|---|---|---|---|---|---|
| **F1** | **Re-scored effort / size** | the committed story-point figure — the **midpoint of the committed range** (§5) | the story-point figure the team assigns at close, **blind** to the original | story points | **item** | the item was **bigger** than estimated → under-estimating | `R > 1` |
| **F2** | **Elapsed / cycle time** | the **§2 committed-horizon budget** — the length of one iteration, in **business days**, for a committed item | elapsed **business days**, item start → DoD met | business days | **item** | the item took **longer** than the committed horizon allowed → horizon over-commitment | `R > 1` |
| **F3** | **Delivered-vs-planned count** | points (or item count) **planned into** the iteration | points (or item count) that **met DoD** in that iteration | points or items | **iteration** | the team delivered **more** than it planned → under-committing | `R < 1` (over-committing) |

**Three normative rules on the families:**

1. **Never pool across families.** F1 and F2 are item-grain; F3 is iteration-grain. Each family carries its **own** `N`, bias, spread, and band. A single "overall" R population is prohibited — it would average an item-grain and an iteration-grain quantity.
2. **The direction of concern flips at F3, so emit the word, not the number.** Because F3's estimate is a *commitment* rather than a *size*, its bad side is `R < 1`. Bias is therefore **always emitted with a direction word** drawn from the closed set `under-estimating | over-estimating | over-committing | under-committing` — never as a bare figure. (F1/F2: `R > 1` → `under-estimating`, `R < 1` → `over-estimating`. F3: `R < 1` → `over-committing`, `R > 1` → `under-committing`.)
3. **Every pair carries its `Estimate Phase`** — the §1 lifecycle-phase row the estimate was made at. Without it the realized-versus-claimed comparison in §8.4 is not computable, and the pair is **incomplete rather than partially usable** (§8.5).

---

### 8.2 Calibration bias and calibration spread (per team-window)

```
Calibration bias      B = median(R)          over the window, after documented outlier exclusion
Calibration spread    S = max(R) ÷ min(R)    over the same window, same exclusions
```

The window is **3–5 completed iterations**, adopted from §5's velocity window; outlier iterations are excluded **with documentation**, per `sprint-defaults.md` §3.2 rule 2.

**Why the median, and why this deviation from §5 is named rather than silent.** §5 builds a velocity range from minimum / average / maximum. Bias uses the **median** instead, because `R` is a **ratio** — floored at 0, unbounded above, and right-skewed — where a single over-run dominates the arithmetic mean. In the §8.4 worked fixture, replacing its largest ratio with a single `R = 4.00` over-run moves the mean from 1.22 to 1.69 while leaving the median at 1.20, exactly unmoved. The deviation from §5's "average" is deliberate and is recorded here so a reader does not have to discover it.

**Why max ÷ min, and why it introduces no new machinery.** Spread **is** §5's own minimum/maximum convention applied to `R`. It adds no new statistic, no percentile, and no threshold. It is also **coverage-comparable to a §1 cone band** — full range against full range. An interquartile form would systematically read narrower than a cone band and would silently overstate a team's precision, which is the opposite of what this section is for. The documented-exclusion discipline (`sprint-defaults.md` §3.2 rule 2) is what makes a min/max estimator safe, and that discipline is already mandatory.

**Bias and spread never collapse into one figure (normative).** They are two different defects with **opposite** remedies, and only bias is banded. Consider two teams with identical mean absolute relative error:

| | `B` (median R) | `S` (max ÷ min) | What is actually true | The correct lever | What a single collapsed "accuracy" number would do |
|---|---|---|---|---|---|
| **Team A** | **1.30** | 1.15 | Systematically under-estimates by ~30%; **highly predictable** | **A multiplier.** Apply ≈1.3 to the next estimate, or move the focus factor toward the bottom of §3's valid range as a governed change. One lever, high confidence. | Reports "poor accuracy" — the verdict is right, but it names no direction, so the team guesses the lever |
| **Team B** | **1.00** | 2.60 | **Zero systematic bias**; large item-to-item scatter | **Decompose smaller, advance the cone phase, or widen the emitted range (§5).** A multiplier is useless here | Reports "poor accuracy" — and the obvious remedy, a correction factor, **injects a bias where none existed**, making Team B strictly worse |

**The purpose of this loop is to select a lever, and a single number cannot.** Bias is systematic and is correctable by a multiplier; spread is random and is **not**. Applying Team A's correction to Team B is not merely unhelpful — it is harmful. Therefore this section emits **two figures and never one**, only **bias** is banded, and any consumer acting on a §8 output must name **which of the two** drove its recommendation (§8.6).

---

### 8.3 Estimation-bias band

A 🟢/🟡/🔴 RAG on the **calibration bias `B`** for one team, one signal family, one window.

| Band | Calibration bias `B` | Reading | `WHEN…THEN…` decision rule |
|---|---|---|---|
| **🟢 GREEN** | **0.90 ≤ B ≤ 1.10** | No actionable systematic bias — the central multiplier sits inside the tightest band the cone recognises | WHEN 0.90 ≤ B ≤ 1.10 THEN report calibrated — make **no** bias adjustment; spread, not bias, is the remaining lever |
| **🟡 YELLOW** | **0.80 ≤ B < 0.90** or **1.10 < B ≤ 1.25** | Emerging systematic bias — outside Build-underway precision, still inside Design-complete precision | WHEN B is in the yellow band THEN surface `B`, its **direction word**, `N`, and the confidence word as a `[RECOMMENDED]` estimate adjustment; do **not** change the §3 focus factor |
| **🔴 RED** | **B < 0.80** or **B > 1.25** | Material systematic bias — the central multiplier is looser than the credible range a Design-complete estimate is even permitted to claim | WHEN B is red THEN surface direction and magnitude; recommend re-baselining (re-anchor the reference stories, or propose a focus-factor move **inside §3's valid range as a governed change**); and widen every emitted range per §5 until the next window closes |

**Boundary anchoring (normative — both boundaries adopt existing in-corpus values, neither is invented).** The **🟢/🟡 boundary at 0.90 / 1.10 directly adopts the §1 Build-underway variance band** (`0.9× – 1.1×`) — the tightest band the cone recognises, and the maturity every *closed* item has necessarily reached. The **🟡/🔴 boundary at 0.80 / 1.25 directly adopts the §1 Design-complete band** (`0.8× – 1.25×`). Both are existing §1 table cells read verbatim, so this doc carries **one** cone table rather than a cone table plus a competing bias table. Two properties are load-bearing rather than incidental:

- **The cone rows are multiplicative and reciprocal-symmetric** (`1 ÷ 0.8 = 1.25` exactly; `1 ÷ 0.9 = 1.11` against the tabled `1.1`, symmetric to rounding), so over- and under-estimation are penalised **equally**. An additive ±% band would not have this property and would silently treat one direction as worse than the other.
- **The band inherits the cone's own semantics.** "🔴 RED" is literally the statement *"this team's systematic multiplier is wider than the credible range §1's cone rule permits a Design-complete estimate to claim."* The band therefore measures conformance to a rule this doc already asserts, instead of importing an outside standard.

*Anchor considered and rejected:* the canonical Schedule (SPI) band adopted by §7. It is **one-sided** — being ahead of schedule is good, so SPI carries no upper bound — whereas estimation deviation is bad in **both** directions. Mirroring its magnitudes symmetrically would be a derivation rather than an adoption, and would compete with §1's rows inside this same file.

**Naming guard (normative).** Name the per-item metric **"estimation ratio"**, the window figures **"calibration bias"** and **"calibration spread"**, and the band the **"estimation-bias band"**. **NEVER "estimation variance"** — §1 already uses "estimate-variance band" for the cone, and §7's naming guard already reserves "variance" against the EVM Schedule Variance collision. **NEVER "velocity" or "velocity accuracy"** — §5 owns velocity at this altitude, and the release-pipeline velocity field is owned elsewhere (§8.5). **NEVER a single collapsed "accuracy score"** — bias and spread never collapse (§8.2).

This band is **orthogonal to the four bands the delivery-engine reference set already carries**, and must not be conflated with any of them:

| Band | Owner | What it bands |
|---|---|---|
| **Buffer-consumption** | §4.1 of this doc | buffer **burn** — consumed ÷ the iteration-buffer figure |
| **Milestone-variance (SPI)** | §7 of this doc (values adopted by reference from the canonical Schedule-RAG home) | **schedule** earned versus planned |
| **Floor-RAG** | `tech-debt-capacity.md` §1.1 | tech-debt **allocation** versus the floor |
| **Demand-supply gap** | the capacity-model reference doc §9 | committed **demand** versus effective supply |
| **Estimation-bias** *(this section)* | §8.3 | **forecast quality over a closed window** |

Five orthogonal bands, each owned by its topical doc. **None of the other four measures forecast quality, and §8.3 measures nothing the other four measure** — a team can be schedule-🟢 while under-estimating by 40% (it padded the schedule) and schedule-🔴 while estimating perfectly (it was blocked). Neither predicts the other.

**Band-ownership determination (normative — the [ADR-065](../../../../core/ADRs/ADR-065-health-rag-band-canonical-home.md) two-branch test).** ADR-065 scopes exactly four project-health indicators — **Schedule/SPI, Budget/CPI, Risk, and Scope** — to a single canonical shared home. It does **not** claim every RAG band on the platform, as the three sibling bands in the table above (which it leaves undisturbed) demonstrate. Its posture therefore resolves to a two-branch test that any new band must be routed through:

| Branch | Predicate | Required posture | This doc's instance |
|---|---|---|---|
| **1** | The band is an **instance of one of the four canonical indicators** | **Adopt by reference; never restate the values** | **§7** — milestone variance adopts the canonical Schedule (SPI) band by reference |
| **2** | The band measures something **no canonical indicator owns** | **Owned by its topical doc**, carrying (a) a distinct name, (b) an explicit orthogonality statement, and (c) boundary anchoring to existing in-corpus values | **§8.3** |

**Verdict: Branch 2.** The falsification test is applied against the nearest incumbent, Schedule/SPI: it measures *schedule earned against schedule planned at a point in time* — a progress signal — whereas calibration bias measures *the systematic multiplier between an estimate and its realized outcome across a closed window* — a forecast-quality signal. They dissociate in **both** directions, as stated above. Budget/CPI is cost-denominated rather than sizing; Risk and Scope are not ratio metrics at all. **No canonical indicator owns this measurement**, so §8.3 owns it here and discharges all three Branch-2 obligations: (a) the naming guard above, (b) the orthogonality table above, and (c) the boundary anchoring above. Creating a **new shared band document** instead is the option ADR-065 itself already rejected under reuse-first — the bar for a new governance file is *necessary*, not *plausible* — and it is rejected here for that same recorded reason.

**Window-size anchoring (normative).** The window floor and the confidence qualifier **adopt `sprint-defaults.md` §3.1's Velocity Stabilization Timeline verbatim**, and are consistent with the platform-wide calibration-availability rule in `core/schemas/gate-evaluation-spec.md` § Layer 3 ("< 3 records → *Insufficient calibration data*"). No private threshold is minted.

| Window (completed iterations) | Confidence word (`sprint-defaults.md` §3.1, verbatim) | §8 posture |
|---|---|---|
| **1–2** | **Unreliable** | `not computable` — do not band, do not feed forward |
| **3–5** | **Emerging pattern** | Band; a 🔴 warrants re-check at the next window before any governed focus-factor change |
| **6–8** | **Reliable baseline** | Band; a 🔴 supports a governed focus-factor proposal |
| **9+** | **High confidence** | Band; the cross-window trend is meaningful |

**Confidence-qualifier rule (normative).** Every emitted `B` and `S` carries its window's confidence word. **A band emitted without its confidence word is incomplete** and is not a valid §8 output. This applies to the estimation ratio the same window-qualification discipline the delivery-engine skill already enforces for velocity.

**Application / negative-path rule (normative — fails closed).** Compute and band the estimation bias **only when the window carries at least 3 completed iterations** of estimate/actual pairs for that family. Below that the band **cannot be computed** — emit

```
estimation bias: not computable — N iteration(s) of history (< 3); do not use for forecasting
```

and recommend accruing the window. **Never default the band to GREEN**, never band a 1–2-iteration window, and never approximate across the floor. Absent or partial input yields the not-computable string, never a colour — the same negative-path posture §4.1 ("never default the band to GREEN on absent input") and §7 ("never fabricate a RAG color on absent input") already carry.

---

### 8.4 Calibration spread → §1 cone-phase equivalence (no second band)

**Spread is not banded and introduces no new boundary.** It is expressed as an equivalence against §1's own rows, read as `high ÷ low` widths:

| §1 lifecycle phase | §1 variance band | Width (`high ÷ low`) |
|---|---|---|
| **Build underway** | 0.9× – 1.1× | **1.22** |
| **Design complete** | 0.8× – 1.25× | **1.56** |
| **Requirements defined** | 0.67× – 1.5× | **2.24** |
| **Approved concept** | 0.5× – 2× | **4.00** |
| **Initial concept** | 0.25× – 4× | **16.00** |

Every value in the Width column is **§1's own two cells divided** — nothing is added to the corpus's stock of thresholds.

**Realized-precision phase.** A team's realized precision is the **narrowest §1 row whose width is ≥ S** (inclusive). It is emitted as a **sentence, never a colour**:

> *realized precision: Requirements-defined-equivalent (S = 1.9) — these items were estimated at Design-complete.*

When `S` exceeds 16.00, emit `realized precision: wider than Initial-concept (S = <value>)`. **Never extrapolate a sixth row.**

**Why this is the section's most useful output.** When the realized phase is **wider** than the phase the estimates were made at, the team is claiming a precision it does not have — which is exactly the condition §1's cone rule already forbids ("an estimate's stated range MUST be no tighter than the variance band for the item's current lifecycle phase"). §8.4 makes that rule **measurable** rather than merely asserted, and the remedy — widen the emitted §5 range to the realized band — **mutates nothing**.

**Worked computation (synthetic fixture — 5 F1 pairs, one window).** Illustrative figures only, in the manner of §1's "point figure = 100" illustration.

| Item | Estimate | Actual (blind re-score) | R |
|---|---|---|---|
| a | 3 | 5 | 1.67 |
| b | 5 | 5 | 1.00 |
| c | 8 | 10 | 1.25 |
| d | 5 | 6 | 1.20 |
| e | 13 | 13 | 1.00 |

`R` sorted: 1.00, 1.00, **1.20**, 1.25, 1.67 → **`B` = 1.20** → direction **under-estimating** → band **🟡 YELLOW** (1.10 < B ≤ 1.25). **`S` = 1.67 ÷ 1.00 = 1.67** → the narrowest row with width ≥ 1.67 is **Requirements-defined (2.24)** → realized precision **Requirements-defined-equivalent**. If these items were estimated at Design-complete, §5's emitted range for this team widens to the 0.67× – 1.5× band until the next window closes. **Boundary cases:** a `B` sitting exactly on a boundary takes the **tighter** band (the bounds are inclusive as tabled); an `S` sitting exactly on a row width takes **that** row.

---

### 8.5 Inputs — the actuals-capture contract

The capture surface that supplies §8 pairs MUST carry the following field set. Field names are **Title Case with spaces**, the convention the platform's tracker schemas use; if the capture surface derives the window from an entity, the entity-join-key form (`*_id`) is the correct variant for that one field and satisfies this contract equally.

| Field | Type | Required | Notes |
|---|---|---|---|
| **Signal Family** | enum `F1` \| `F2` \| `F3` | Yes | Pairs from different families are **never pooled** (§8.1 rule 1) |
| **Estimate** | number > 0 | Yes | F1: the committed point figure (the §5 range **midpoint**). F2: the §2 committed-horizon budget in **business days**. F3: points or items planned into the iteration |
| **Actual** | number ≥ 0 | Yes | F1: the **blind** re-score at close. F2: elapsed **business days**, start → DoD met. F3: points or items delivered |
| **Estimate Phase** | enum — the five §1 lifecycle-phase names | Yes | The cone row the estimate was made at. **Required** — §8.4's realized-versus-claimed comparison is not computable without it |
| **Window Key** | string | Yes | The iteration or period identifier that groups pairs into a window, and against which documented outlier exclusion is applied |
| **Evidence Grade** | enum `[SOURCE]` \| `[INFERRED]` \| `[ASSUMPTION – CONFIRM]` | Yes | **F1 is capped at `[INFERRED]`** — a re-score is itself an estimate (§8.7 V3) |
| **Excluded Reason** | string | No | Present **if and only if** the pair is excluded from the window, carrying the documented reason per `sprint-defaults.md` §3.2 rule 2 |

**Two writes at two gates, never one (normative — fails closed).** A pair is **not** written by a single instruction at close. The promise half and the outcome half are written at **different gates**, by **different mode invocations**, and the contract names both:

| Write | Gate | Emitted by | Fields written | Posture |
|---|---|---|---|---|
| **W1 — admission** | **LG-4 DoR exit PASS / CONDITIONAL PASS** (item admitted to execution) | delivery-engine **Mode C** | `Signal Family`, `Estimate`, `Estimate Phase`, `Start Date`, `Window Key`, `Evidence Grade` | Creates the record. `Estimate` and `Estimate Phase` are **frozen** here and never rewritten at close |
| **W2 — close** | **LG-5 Dev Complete (DoD) exit PASS / CONDITIONAL PASS** | delivery-engine **Mode F** | `Actual`, `Actual Date`, and (F2) the derived elapsed figure | Completes the record against the frozen promise. Carries **no** `Estimate` — that is what keeps the F1 re-score blind |

**W1 is not optional and its absence is not recoverable at close.** A close instruction is a **modification of an existing record**; a close fired against an item that was never admitted has **no record to modify**, so the pair is unwritable and the close must record a capture exception (`no-estimate-of-record`) instead. **A capture contract that names only the close is not a capture path** — it describes half a write and reads as complete. Any surface implementing this contract states, per field, **which of the two writes owns it**; a field owned by neither is a defect in the surface, not a value to improvise at close.

**Explicit-N/A discipline (normative — fails closed).** A pair either carries the **full** required field set or is **absent**. **Never a partial row, and never a zero-filled `Actual`.** A zero-filled actual is indistinguishable from a genuinely zero-effort item and would drag `B` toward 0 — a synthesized figure silently biasing the baseline is exactly the failure this discipline forecloses.

**Forward-only (normative).** **Never backfill historical pairs.** A reconstructed estimate is not the estimate that was made, and a backfilled population is precisely the survivorship-biased one §8.7 V2 warns about. Capture is grandfathered forward from the point the surface lands.

**No per-person attribution (normative).** A pair carries no individual attribution. `sprint-defaults.md` §3.2 rule 5 binds here (§8.7 V4).

**Boundary — the release-pipeline velocity instrument is neither read nor written (normative).** F3 has the same *shape* as the release-pipeline delivered-versus-planned ratio recorded in the release log, and **must never share a value with it.** That instrument measures the release pipeline's own throughput and explicitly declares that it is not a managed-delivery-team capacity model, naming this doc and the capacity-model doc as the owners of the team-altitude figure. **Different concept, same digits** — the same disambiguation form that standard already uses for the two 60/20/20 allocations. What is reusable is the **pattern** (explicit-N/A, forward-only grandfathering, the N=3 trigger, parser safety), never the field. **Cite the convention; share no value.**

---

### 8.6 Consumption — the feedback and reporting contracts

Two consumers read §8 outputs. **Both are read-only against §8, and neither writes any value into this document.** These contracts are complete as written: a consumer needs nothing from §8 that is not listed here.

#### 8.6.1 The estimate-feedback consumer (delivery-engine Mode D)

**MAY read**, and only these: `B`, its **direction word**, its **band**, `S`, the **realized-precision phase**, `N`, and the **confidence word**.

Two levers, **both non-mutating**:

- **Lever 1 — bias → a multiplier proposal.** When the band is 🟡 or 🔴, surface `[RECOMMENDED] apply ×B to the next <family> estimate`, rendering **the prior value, `B`, the direction word, the band, `N`, and the confidence word**. It is **offered, never applied**. A focus-factor move is surfaced as a `[RECOMMENDED]` proposal **inside §3's valid range** and requires a governed edit — §3's Consumers note makes the focus factor a value two other docs inherit by role without restating it, so an automated write there would propagate with no diff trail.
- **Lever 2 — spread → a range-width floor.** When the realized-precision phase (§8.4) is **wider** than the item's declared `Estimate Phase`, §5's emitted range widens to the realized band. **This mutates nothing** — it makes §5's existing normative rule bind at the team's *measured* precision rather than its *claimed* precision. This is the substantive feedback path, and it is a demonstrable change to a future estimate.

**MUST NOT:**

- **MUST NOT write to §3**, or to any other stored value in this document. The feedback posture is advisory for this release; an enforcing path is an explicit non-goal.
- **MUST NOT emit a point figure.** §5 binds unconditionally; a bias-adjusted estimate is still returned as a range.
- **MUST NOT apply a bias when the band is 🟢 or when the figure is `not computable`.**
- **MUST NOT apply a bias derived from a family whose pairs it did not read** (§8.1 rule 1).
- **MUST NOT act on an F1-only 🔴** without corroboration from F2 or F3 (§8.7 V3).

#### 8.6.2 The team calibration report (delivery-engine Mode E)

Renders, per **team**, per **window**, per **signal family**:

| Element | Rendering |
|---|---|
| **Coverage** | `N` iterations, plus the pair count **against the iteration's planned item count**, plus the confidence word |
| **Bias** | `B` with its **direction word** and its 🟢/🟡/🔴 band, citing §8.3 **by role** — the boundary values are not restated in the report |
| **Spread** | `S` with its realized-precision phase, and whether that phase is wider than the declared `Estimate Phase` |
| **Trend** | across consecutive windows, using **`improving` / `stable` / `degrading`** — adopted verbatim from `core/schemas/gate-evaluation-spec.md` § Layer 3, not a new enum |
| **Inflation flag** | when `B` trends toward 1.00 **while points-per-item trends up**, flag it as **inflation, not calibration** — the throughput cross-check `sprint-defaults.md` §3.2 rule 4 already mandates |

**Negative path (normative — fails closed).** With `N < 3`, render `not computable — N iteration(s) (< 3)` plus the missing-input recommendation. **Never a defaulted colour.**

**MUST NOT render:** a cross-team comparison; a per-person figure; a portfolio rollup; or a **single collapsed accuracy number** (§8.2).

---

### 8.7 Validity threats and the evidence-quality bar

*Declared before any §8 output is read as a finding. Each threat carries a mitigation and an honest residual.*

**V1 — Small-sample instability.** `B` and `S` computed over 1–2 iterations are dominated by a single item. *Mitigation:* the hard not-computable floor at **N ≥ 3** (§8.3), adopted from `sprint-defaults.md` §3.1; **median and min/max order statistics** rather than mean and standard deviation, which are robust to a single outlier; and the confidence word on every emission. *Residual:* at N = 3–5 the window is only an `Emerging pattern`, so a 🔴 at N = 3 warrants re-check at the next window before any governed focus-factor change. **This residual is why the confidence word must travel with the figure.**

**V2 — Survivorship: only closed items have actuals.** An abandoned, descoped, or still-open item contributes no pair — and abandoned items are systematically the *badly-estimated* ones, so the observed population is biased **toward** looking calibrated. *Mitigation:* two-part. (a) The report renders **pair count against the iteration's planned item count** (§8.6.2), so the coverage gap is visible rather than silent. (b) **F3 is structurally immune** — its denominator is the *plan*, not the closed set — so **F3 is the coverage control on F1 and F2**. When F1/F2 read 🟢 while F3 reads 🔴, survivorship is the first hypothesis, and the report says so. *Residual:* F1/F2 optimism is labelled, not eliminated.

**V3 — Re-scoring circularity (F1 only).** F1's "actual" is a re-score — an estimate measured against an estimate. *Mitigation:* the re-score is **blind** (assigned before the original figure is read); F1's `Evidence Grade` is **capped at `[INFERRED]`** and never `[SOURCE]`; and **an F1-only 🔴 may not drive an action** without corroboration from F2 or F3. *Residual:* F1 is the weakest of the three families and is a **proxy actual**, not a measured one. It is retained because it is the only family that measures *sizing* directly.

**V4 — Goodhart pressure once accuracy is measured.** The cheapest way to score well is to inflate estimates, which drives `B` → 1.00 while destroying the estimate's information content. This is not speculative — `sprint-defaults.md` §6 already names velocity gaming, with the detection signal "average story points per item trends upward while items per sprint stays flat," and §3.2 rule 5 records that a substantial share of practitioners admit to point manipulation when velocity is tied to reviews. *Mitigation:* the per-person and cross-team prohibitions are **restated for this metric** rather than left implicit (§8 preamble); the throughput cross-check §3.2 rule 4 already mandates becomes an **emission rule** (§8.6.2's inflation flag); and the advisory-only posture keeps the output a proposal a human weighs, which is a materially weaker incentive than an automated adjustment. *Residual:* the loop cannot make gaming impossible. It can make it **visible**, which is the honest claim.

**V5 — Unit drift across the window (F1, F3).** Story points are team-relative and drift as reference stories change; an `R` computed across a window spanning a re-anchoring compares two different units. *Mitigation:* the `Window Key` field plus `sprint-defaults.md` §3.2 rule 2's documented-exclusion mechanism — a re-anchoring event excludes the prior windows, with the exclusion documented. *Residual:* detection of a re-anchoring is manual; this section supplies the exclusion mechanism, not the detector.

**V6 — Self-normalization (F2).** If F2's `estimate` were derived from the same window's own throughput, then `median(R)` would be ≈ 1.00 **by construction** and the metric would measure nothing. *Mitigation:* **F2's estimate is the §2 committed-horizon budget** — an externally-set promise, in business days, for one iteration — and is **never** a window-derived figure. *Residual:* none for the specified form; this is an implementation hazard, which is why it is stated normatively here rather than only as a caution.

**Evidence-quality bar (normative).** A §8 finding is **load-bearing only at `[SOURCE]` or `[INFERRED]`**. An `[ASSUMPTION – CONFIRM]`-graded pair **may** be counted in `N` and reported, but **may not alone drive a 🔴 verdict or a focus-factor recommendation**. Combined with V3's cap on F1, the operative rule is: **an F1-only 🔴 requires F2 or F3 corroboration before any action.**
