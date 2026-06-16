<!-- reference-durability: allow-link -->
<!-- provenance: MIXED — referenced bands carry their source doc's provenance; registry-owned bands tagged per-row -->

# Metric Registry

## Purpose

This registry is the canonical **cross-level index** for metric → RAG-threshold → decision-rule mappings at four organizational levels (Portfolio / Program / Project / Team). It is the single home a reader consults to find which metric drives a health color at which level, what its threshold bands are, and what decision the band triggers.

**This registry is an INDEX.** Where a band is owned by a sibling reference doc, this registry REFERENCES it (it does not restate the numbers):

- Project schedule / budget / risk / scope bands → [`comms-writer/references/channel-formats.md`](../../comms-writer/references/channel-formats.md) § RAG Threshold Standards.
- Team capacity-utilization band → [`delivery-engine/references/capacity-model.md`](../../delivery-engine/references/capacity-model.md).
- Portfolio health / dependency-ratio cut-points → [`delivery-engine/references/backlog-health.md`](../../delivery-engine/references/backlog-health.md).
- RAID-AGE escalation timing → `escalation-thresholds.md` (owned by the ppm-agent skill — see References). *Named-but-unlinked while that doc is unshipped; the link hardens when it lands.*

This registry **OWNS** only the metrics that exist nowhere else: **Overdue RAID Count** and the cross-level roll-ups. Consumers — the watermelon-detection reference (see References) and the stale-RAID protocol (see References) and any sibling-class consumer — **REFERENCE** the rows here; they do not re-derive them.

**Consuming skill:** `weekly-status-rollup` (its Section 1 Portfolio Health Dashboard health-color logic + Health Indicators composition). **Read-back surface:** `PORTFOLIO.md` Health Indicators.

## RAG Band Legend

| Band | Meaning |
|---|---|
| 🟢 GREEN | Within tolerance — no action beyond normal cadence |
| 🟡 YELLOW | At risk — watch / mitigate; not a confirmed breach (≡ "Amber" in referenced sources) |
| 🔴 RED | Breached — escalate / gate / replan per the metric's decision rule |

**Boundary convention.** Registry-owned bands use **lower-inclusive / upper-exclusive** boundaries. For a **lower-is-better** metric: 🟢 `x < g` · 🟡 `g ≤ x < r` · 🔴 `x ≥ r`. For a **higher-is-better** metric (e.g. SPI), polarity inverts: 🟢 `x ≥ g` · 🟡 `r ≤ x < g` · 🔴 `x < r`. This makes boundary values (exactly SPI 0.95, exactly 2 RAID items, exactly 0.85 utilization) classify deterministically — the determinism this registry exists to create.

**Precedence.** Where a band is REFERENCED from a sibling doc that declares its own inclusivity (e.g. `capacity-model.md` GREEN `≤ 0.85`, where 0.85 IS green), the **referenced source's inclusivity governs** and is reproduced verbatim. This boundary convention applies only to registry-owned bands; it never overrides a referenced source.

**Vocabulary mapping.** 🟡 YELLOW ≡ **Amber** — referenced sources that label the middle band "Amber" (`channel-formats.md`) or "🟡 Amber" (`capacity-model.md`) read as this registry's 🟡 YELLOW without translation drift.

## Decision-Rule Grammar

Every decision rule below conforms to one fixed grammar so consumers can cite a rule verbatim rather than re-derive it:

```
WHEN <metric> <comparator> <threshold> THEN <RAG> → <action> <target> [WITHIN <SLA>]
```

The `<action>` is drawn from the closed set:

- **hold** — no action beyond normal cadence; the metric is within tolerance.
- **watch** — track at the next status cadence; mitigation in progress, no escalation yet.
- **escalate** — raise to the named owner / sponsor for a decision, optionally within an SLA.
- **gate** — block the gated activity (a change, a commit, a release) until the condition clears.
- **replan** — re-baseline the affected plan (schedule, budget, scope) — the current plan can no longer hold.

## Project-Level RAG Composition

This registry produces per-**metric** RAG. The single **PROJECT-level** RAG is composed **UPSTREAM** by the transparent-roll-up rule in [`channel-formats.md`](../../comms-writer/references/channel-formats.md) § RAG Threshold Standards — *"component-level RAGs that roll up transparently to the project-level RAG"* (`channel-formats.md:245-246`), i.e. the project color is driven by its **worst component** (a watermelon-prevention dominance rule). That composition is executed in `weekly-status-rollup` Section 1 (Portfolio Health Dashboard health-color logic). This registry does **NOT** define a divergent composition algorithm.

NOTE: `weekly-status-rollup` Section 1's composition is currently expressed as qualitative prose, not a formal algorithm; formalizing a worst-of / dominant-color algorithm is a candidate follow-on and does not block this registry.

## Project Metrics

The AC-bearing level. Each band cell for a REFERENCED row says "see `<doc:line>`" (it does not reprint the sibling's numbers — duplicate-source-discipline; the `<!-- reference-durability: allow-link -->` fence at the top of this file permits the cross-links). The `Provenance` column records each band's source status as one of `referenced:<file:line>` | `audited:<file:line>` | `UNSOURCED-DOMAIN`, making source-of-truth status machine-checkable per row.

| Metric | Formula | Data Source | 🟢 GREEN | 🟡 YELLOW | 🔴 RED | Provenance | Decision Rule |
|---|---|---|---|---|---|---|---|
| **Schedule Performance Index (SPI)** | `earned schedule value ÷ planned schedule value` (EVM SPI; "X% behind schedule" ⇒ SPI = 1 − X/100, e.g. 8% behind ⇒ 0.92) | `PROJECT.md` milestone %-complete + plan baseline (EVM tracker) | see `channel-formats.md:239` (`≥ 0.95`) | see `channel-formats.md:239` (`0.85 ≤ SPI < 0.95`) | see `channel-formats.md:239` (`< 0.85`) | `referenced:channel-formats.md:239` | `WHEN 0.85 ≤ SPI < 0.95 THEN 🟡 YELLOW → watch milestone; flag at next status. WHEN SPI < 0.85 THEN 🔴 RED → escalate to sponsor WITHIN 2 business days; replan critical path.` |
| **Budget (CPI)** | `earned value ÷ actual cost` (EVM CPI) | EVM tracker / cost actuals | see `channel-formats.md:240` (`≥ 0.95`) | see `channel-formats.md:240` (`0.85 ≤ CPI < 0.95`) | see `channel-formats.md:240` (`< 0.85`) | `referenced:channel-formats.md:240` | `WHEN 0.85 ≤ CPI < 0.95 THEN 🟡 YELLOW → watch spend. WHEN CPI < 0.85 THEN 🔴 RED → escalate; re-baseline budget.` |
| **Scope** | approved CRs impacting baseline (qualitative bands per source) | `PROJECT.md` + change log | see `channel-formats.md:242` | see `channel-formats.md:242` | see `channel-formats.md:242` | `referenced:channel-formats.md:242` | `WHEN major baseline-impacting CR THEN 🔴 RED → gate change-control.` |
| **Risk** | open high / critical risk profile (qualitative bands per source) | RAID Log | see `channel-formats.md:241` | see `channel-formats.md:241` | see `channel-formats.md:241` | `referenced:channel-formats.md:241` | `WHEN any critical risk unmitigated OR ≥3 high risks THEN 🔴 RED → escalate.` |
| **Integration Risk** | cross-system integration health (the 5th `weekly-status-rollup` dimension; qualitative) | `PROJECT.md` Health Indicators + technical-analyst findings | `no open integration blockers` | `integration risk identified, mitigation in progress` | `integration blocker with confirmed timeline impact` | `UNSOURCED-DOMAIN` | `WHEN integration risk active w/ mitigation THEN 🟡 YELLOW → watch. WHEN blocker w/ timeline impact THEN 🔴 RED → escalate.` |
| **Overdue RAID Count** | `count of RAID items past due / review date` | RAID Log | `0` | `1 ≤ count < 3` | `count ≥ 3` | `audited:raid-templates.md:89 (lifecycle); count-band registry-owned` | `WHEN 1 ≤ count < 3 THEN 🟡 YELLOW → watch; clear at next cadence. WHEN count ≥ 3 THEN 🔴 RED → escalate.` (Per-item AGE escalation timing per `escalation-thresholds.md` — not yet shipped; referenced, not restated. Per-item lifecycle escalation per `raid-templates.md §3.2 item 4`.) |

The five non-RAID Project rows give the registry a strict **superset** of `weekly-status-rollup`'s five Health-Indicator dimensions — Schedule (SPI) / Scope / Quality (via Risk + Integration) / Stakeholders (see note) / Integration Risk — closing the consumer's coverage. An explicit **Stakeholder Engagement** row is optional: `UNSOURCED-DOMAIN`, bands `0 / 1 / ≥2` overdue executive items, lower-is-better.

## Program Metrics

Seed set; each row REFERENCES its owner where one exists.

| Metric | Formula | Data Source | 🟢 GREEN | 🟡 YELLOW | 🔴 RED | Provenance | Decision Rule |
|---|---|---|---|---|---|---|---|
| **Aggregate SPI** | roll-up of constituent projects' SPI | program EVM roll-up | see `channel-formats.md:239` (`≥ 0.95`) | see `channel-formats.md:239` (`0.85 ≤ SPI < 0.95`) | see `channel-formats.md:239` (`< 0.85`) | `referenced:channel-formats.md:239` | `WHEN 0.85 ≤ aggregate SPI < 0.95 THEN 🟡 YELLOW → watch program schedule. WHEN < 0.85 THEN 🔴 RED → escalate to program sponsor; replan.` |
| **Cross-Project Dependency Health** | `% items with unresolved cross-project dependencies` | program dependency register | see `backlog-health.md:20` (`< 15%`) | see `backlog-health.md:20` (`15–30%`) | see `backlog-health.md:20` (`> 30%`) | `referenced:backlog-health.md:20` | `WHEN 15% ≤ unresolved-dep ratio ≤ 30% THEN 🟡 YELLOW → watch. WHEN > 30% OR any blocked dep in next sprint THEN 🔴 RED → escalate.` (Cite `backlog-health.md:20`; do NOT cite `dependency-rules.md` — it uses a 1–5 scale, not %.) |
| **Velocity Variance** | `\|actual − planned velocity\| ÷ planned` | sprint metrics roll-up | `< 10%` | `10 ≤ variance < 30%` | `≥ 30%` | `UNSOURCED-DOMAIN` | `WHEN 10% ≤ variance < 30% THEN 🟡 YELLOW → watch throughput. WHEN ≥ 30% THEN 🔴 RED → escalate; investigate.` (The `≥ 30%` band is the velocity-spike watermelon signal that watermelon-detection references.) |
| **Milestone Slip Rate** *(optional)* | `slipped milestones ÷ total milestones in window` | milestone tracker | `< 15%` (red boundary anchored; green/amber UNSOURCED) | `UNSOURCED-DOMAIN` | `≥ 15%` | `audited:failure-mode-standard.md:202` (red boundary only) | `WHEN slip rate ≥ 15% THEN 🔴 RED → escalate; re-baseline program plan.` (Include only if slip rate adds signal beyond Aggregate SPI. Name it "Milestone Slip Rate," **never** "Schedule Variance.") |
| **Program Risk Exposure** | `count of program-level RED risks` | program RAID roll-up | `0` | `1` | `≥ 2` | `UNSOURCED-DOMAIN` | `WHEN count = 1 THEN 🟡 YELLOW → watch. WHEN count ≥ 2 THEN 🔴 RED → escalate to program sponsor.` |

## Portfolio Metrics

Seed set.

| Metric | Formula | Data Source | 🟢 GREEN | 🟡 YELLOW | 🔴 RED | Provenance | Decision Rule |
|---|---|---|---|---|---|---|---|
| **Portfolio Health Index** | `% active projects at 🟢` | `PORTFOLIO.md` roll-up | see `backlog-health.md:37` (`> 80`) | see `backlog-health.md:37` (`60–80`) | see `backlog-health.md:37` (`< 60`) | `referenced:backlog-health.md:37` | `WHEN 60 ≤ index ≤ 80 THEN 🟡 YELLOW → attention needed; review at-risk projects. WHEN < 60 THEN 🔴 RED → immediate intervention.` |
| **Count of RED Projects** | `count of active projects at 🔴` | `PORTFOLIO.md` | `0` | `1` | `≥ 2` | `UNSOURCED-DOMAIN` | `WHEN count = 1 THEN 🟡 YELLOW → watch. WHEN count ≥ 2 THEN 🔴 RED → portfolio-level escalation.` |
| **Aggregate Overdue-Decision Count** | `count of overdue portfolio decisions` | `PORTFOLIO.md` decision log | `0` | `1 ≤ count < 3` | `count ≥ 3` | `UNSOURCED-DOMAIN` | `WHEN 1 ≤ count < 3 THEN 🟡 YELLOW → watch; clear at next cadence. WHEN count ≥ 3 THEN 🔴 RED → escalate to sponsor.` |
| **Aggregate Budget Health** | portfolio CPI roll-up | portfolio EVM roll-up | see `channel-formats.md:240` (`≥ 0.95`) | see `channel-formats.md:240` (`0.85 ≤ CPI < 0.95`) | see `channel-formats.md:240` (`< 0.85`) | `referenced:channel-formats.md:240` | `WHEN 0.85 ≤ portfolio CPI < 0.95 THEN 🟡 YELLOW → watch portfolio spend. WHEN < 0.85 THEN 🔴 RED → escalate.` |

## Team Metrics

Seed set.

| Metric | Formula | Data Source | 🟢 GREEN | 🟡 YELLOW | 🔴 RED | Provenance | Decision Rule |
|---|---|---|---|---|---|---|---|
| **Capacity Utilization** | `committed demand ÷ effective supply` (effective-capacity formula in `capacity-model.md §1`) | sprint plan + capacity model | see `capacity-model.md:274` (🟢 `≤ 0.85`) | see `capacity-model.md:275` (🟡 `0.85 – 1.00`) | see `capacity-model.md:276` (🔴 `> 1.00`) | `referenced:capacity-model.md:274` | `WHEN 0.85 < utilization ≤ 1.00 THEN 🟡 YELLOW → protect reserve; resist mid-sprint scope additions. WHEN > 1.00 THEN 🔴 RED → re-scope / de-commit / re-baseline.` (Reproduce the source's inclusivity — `≤ 0.85` is GREEN; do NOT restate as `< 85%`. Reference the effective-capacity formula; do not restate it.) |
| **Sprint Commitment Reliability** | `delivered ÷ committed` | sprint board | see `backlog-health.md:18` (`> 90%`) | see `backlog-health.md:18` (`75–90%`) | see `backlog-health.md:18` (`< 75%`) | `referenced:backlog-health.md:18` | `WHEN 75% ≤ reliability ≤ 90% THEN 🟡 YELLOW → watch. WHEN < 75% THEN 🔴 RED → investigate estimation / over-commitment.` |
| **Blocked-Item Count** | `count of items in blocked state` | sprint board | `0` | `1 ≤ count ≤ 2` | `> 2` | `UNSOURCED-DOMAIN` | `WHEN 1 ≤ count ≤ 2 THEN 🟡 YELLOW → watch; unblock at next cadence. WHEN > 2 THEN 🔴 RED → escalate blockers.` |
| **Bus-Factor Risk** | bus-factor-critical artifacts without a K1 externalization path | KM artifact frontmatter + `grep` | per `km-protocols.md §4` | per `km-protocols.md §4` | per `km-protocols.md §4` | `referenced:km-protocols.md:86` | `WHEN a bus-factor-critical artifact lacks an externalization path THEN escalate per km-protocols.md §4.` (Single-operator framing: bus-factor = 1 is the operating model, not a defect — do NOT restate the rule; reference `km-protocols.md §4`.) |

**Provenance discipline.** Every band cell-set carries a `Provenance` value. REFERENCED bands say "see `<doc>`" + link; they never reprint a sibling's numbers. The only registry-OWNED numeric band is **Overdue RAID Count** (plus the `UNSOURCED-DOMAIN` qualitative / seed bands), which carry inline values. **Never fabricate an `audited:` citation** — if no in-corpus anchor exists, the value is `UNSOURCED-DOMAIN` (per the `capacity-model.md` precedent for above-cap Amber/Red boundaries).

## Lag / Lead Indicator Classification

Each registry metric is additionally classified as a **lagging** or **leading** indicator. This is a *property of the existing rows* — it adds no new metric, no new band, and no PROJECT.md field; it lets a consumer audit the **balance** of the metric set it reports (see Consumers — `weekly-status-rollup` Section 7.2 Lag-to-Lead Balance Audit).

- **Lagging** — measures an outcome **after** it has occurred; corrective action is reactive. (Schedule/budget variance already realized, overdue counts already accrued.)
- **Leading** — **predictive**; movement precedes the outcome, so action can be preventive. (Throughput/velocity trend, capacity pressure, dependency exposure ahead of the slip.)

| Metric | Level | Class | Rationale (one line) |
|---|---|---|---|
| Schedule Performance Index (SPI) | Project | **Lagging** | Earned-vs-planned schedule already accrued |
| Budget (CPI) | Project | **Lagging** | Earned-vs-actual cost already spent |
| Scope | Project | **Lagging** | CRs already approved against baseline |
| Risk | Project | **Leading** | Open high/critical risks precede the issue they predict |
| Integration Risk | Project | **Leading** | Identified integration risk precedes the blocker |
| Overdue RAID Count | Project | **Lagging** | Items already past due |
| Aggregate SPI | Program | **Lagging** | Roll-up of realized project SPI |
| Cross-Project Dependency Health | Program | **Leading** | Unresolved-dependency ratio precedes the cross-project slip |
| Velocity Variance | Program | **Leading** | Throughput deviation precedes delivery miss (also the velocity-spike watermelon signal) |
| Milestone Slip Rate | Program | **Lagging** | Slips already occurred in the window |
| Program Risk Exposure | Program | **Leading** | Open program RED risks precede the program-level issue |
| Portfolio Health Index | Portfolio | **Lagging** | Composed from projects already at their current color |
| Count of RED Projects | Portfolio | **Lagging** | Projects already RED |
| Aggregate Overdue-Decision Count | Portfolio | **Lagging** | Decisions already overdue |
| Aggregate Budget Health | Portfolio | **Lagging** | Portfolio CPI roll-up of realized spend |
| Capacity Utilization | Team | **Leading** | Demand-vs-supply pressure precedes the over-commitment miss |
| Sprint Commitment Reliability | Team | **Lagging** | Delivered-vs-committed for a sprint already closed |
| Blocked-Item Count | Team | **Leading** | Active blockers precede the throughput drop |
| Bus-Factor Risk | Team | **Leading** | Externalization-gap precedes the knowledge-loss event |

A consumer reports the **lag : lead ratio** over the metrics it actually surfaces; a set heavily weighted toward lagging indicators is a steering-by-rear-view-mirror balance risk. This classification does not change any band, decision rule, or composition above.

## AC Worked Example — milestone 8% behind schedule

```
Input:   Daily Status reports a milestone running 8% behind schedule.
Metric:  Project Metrics → Schedule Performance Index (SPI).
Formula: "X% behind schedule" ⇒ SPI = 1 − X/100 = 1 − 0.08 = 0.92.
Band:    SPI band (referenced, channel-formats.md:239): 🟢 ≥0.95 · 🟡 0.85≤SPI<0.95 · 🔴 <0.85.
Test:    0.92 ∈ [0.85, 0.95) → 🟡 YELLOW.  (Boundary convention: higher-is-better, upper-open.)
Rule:    "WHEN 0.85 ≤ SPI < 0.95 THEN 🟡 YELLOW → watch milestone; flag at next status."
Metric RAG: 🟡 YELLOW, citing SPI band channel-formats.md:239.
Project RAG: per the transparent-roll-up rule (channel-formats.md:245-246), the project color is
             driven by its worst component. With Schedule 🟡 and no component worse than 🟡, the
             project rolls up to 🟡 YELLOW — satisfying the AC ("project shows yellow") through the
             referenced composition rule, not a registry-invented algorithm.
Output:  🟡 YELLOW at both metric and project level, with the cited 0.85/0.95 SPI thresholds.
```

## Consumers

Consumers cite these rows verbatim; they do not re-derive thresholds (duplicate-source-discipline). REFERENCED rows are followed to their owning doc for the live band.

| Consumer | What it references here |
|---|---|
| `weekly-status-rollup` (Section 1 health logic + Health Indicators composition) | The per-metric Project rows + the Project-Level RAG Composition clause. |
| `weekly-status-rollup` (Section 7 Portfolio Governance — governance use) | The **Lag / Lead Indicator Classification** (Section 7.2 lag-to-lead balance audit), the per-metric `WHEN…THEN…` **Decision Rule** cells (Section 7.4 per-metric decision-rule validation — cited verbatim, not re-derived), and the Team **Capacity Utilization** row (Section 7.5 capacity dashboard, which follows it to `capacity-model.md`). Section 7.1's watermelon scan consumes the **W1–W8 signal set by reference** from `watermelon-detection.md` (owned by `pmo-qa-auditor`, core module, via-public-api) — see the reciprocal note below. |
| `watermelon-detection.md` (the pmo-qa-auditor reference — see References) | The Overdue RAID Count owned row (its W3 green-masking trigger: overdue ≥ 1 while overall RAG green), the Velocity Variance `≥ 30%` spike signal, and the SPI / CPI bands for schedule / budget-watermelon signals. |
| `OPERATIONS.md` RAID protocol (the stale-RAID auto-escalation protocol — see References) | The RAID-derived metrics here for count→RAG; defers per-item AGE escalation to `escalation-thresholds.md`. |

**Reciprocal note — the watermelon signal set now has TWO active consumers.** `watermelon-detection.md` (owned by `pmo-qa-auditor`, core module) defines the canonical W1–W8 signal set; it references this registry for the bands its signals key off (Overdue RAID Count, Velocity Variance `≥ 30%`, SPI/CPI). As of `weekly-status-rollup` v2.01, the **roll-up's Section 7.1 is also an active consumer** of that signal set — it runs W1–W8 **by reference** (via-public-api; no local fork) to scan each project per the verdict-composition rule. So the W1–W8 set is consumed by the *auditor* (output audits) **and** the *roll-up* (portfolio governance) from the single canonical home; the bands those signals key off remain owned here.

## References

- **Overdue RAID Count** lifecycle anchor — `raid-templates.md §3.2 item 4` ("Overdue actions auto-escalate … to PM within 1 business day"): the per-item lifecycle escalation this registry's count→RAG band sits alongside.
- **RAID-age escalation owner** — `escalation-thresholds.md`, owned by the ppm-agent skill; named-but-unlinked while unshipped. GitHub issue **#269**.
- **watermelon-detection** consumer — `watermelon-detection.md`, owned by the pmo-qa-auditor skill. GitHub issue **#270**.
- **stale-RAID protocol** consumer — the Stale-RAID Auto-Escalation Protocol in the `OPERATIONS.md` Cross-Skill Protocols. GitHub issue **#261**.
- This registry's tracking item — GitHub issue **#271**.
