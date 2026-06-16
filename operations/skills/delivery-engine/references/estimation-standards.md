<!-- reference-durability: allow-link -->
<!-- provenance: UNSOURCED-DOMAIN -->

# Estimation Standards

## Purpose

This document is the canonical source of **estimation discipline** for the delivery-engine skill — how an estimate's precision is bounded by lifecycle phase, how far out work may be committed versus forecast, the **canonical focus-factor table this doc owns**, the three-zone buffer model, the **buffer-consumption RAG banding** (§4.1), the rule that velocity and derived estimates are expressed as ranges rather than points, the contingency-versus-management-reserve distinction, and the **milestone-variance (SPI) RAG banding** (§7). It is read by the delivery-engine skill: **Mode D (Sprint Planning)** reads the Cone-of-Uncertainty band widths, planning-horizon commitment rules, the focus-factor table, the buffer model, the buffer-consumption banding, and the milestone-variance RAG when building a capacity model and sprint scope; **Mode E (Execution Control Tower)** reads the velocity-as-range enforcement rule (§5) when reporting velocity or capacity.

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

| Band | SPI | Reading | `WHEN…THEN…` decision rule |
|---|---|---|---|
| **🟢 GREEN** | **≥ 0.95** | On or ahead of schedule (within tolerance) | WHEN SPI ≥ 0.95 THEN report on-track — no milestone escalation |
| **🟡 YELLOW** | **0.85 – 0.94** | Slipping; recoverable but eroding | WHEN SPI is 0.85–0.94 THEN flag the milestone at the next status; watch the critical path and name the recovery lever |
| **🔴 RED** | **< 0.85** | Materially behind; baseline at risk | WHEN SPI < 0.85 THEN escalate — replan the critical path and surface the re-baseline / de-scope decision; do not report the milestone merely "behind" |

**Band anchoring (normative — adopted by reference, not restated as a divergent value).** These bands are **adopted by reference from the platform-canonical Schedule-RAG standard** in the comms-writer reference doc's RAG Threshold Standards (Schedule/SPI: Green ≥0.95 / Amber 0.85–0.94 / Red <0.85), which the weekly-status-rollup metric-registry already consumes by reference for SPI. This doc reuses the **one** platform schedule-RAG convention rather than inventing a parallel band.

**Naming guard (normative).** Name this metric **"milestone variance (SPI)"** or **"milestone slip"** — **NEVER "Schedule Variance."** The "Schedule Variance" label is reserved against to avoid collision with the EVM Schedule Variance (SV = earned − planned, a *cost*-denominated figure), per the metric-registry naming rule. The milestone-variance signal here is the *index* (SPI ratio), not the EVM SV difference.

**Application rule.** Compute and band milestone variance only when a **schedule baseline exists** (a planned milestone %-complete or earned/planned schedule value). When no baseline exists, the SPI **cannot be computed** — emit `variance: not computable — no schedule baseline` and flag the missing baseline as a planning gap; never fabricate a RAG color on absent input.
