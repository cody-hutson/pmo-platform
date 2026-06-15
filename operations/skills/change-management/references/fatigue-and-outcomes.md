# Fatigue & Outcomes Reference

## Purpose

This reference owns the **change-fatigue capability layer** and the **deployed-vs-adopted
outcome-measurement method** for the change-management skill Mode G (Adoption Tracking) —
the per-change fatigue read over the standing cumulative change load, the band → remediation
routing, the deployed-vs-adopted scorecard, and the verdict rule. It is the
capability-orchestration sibling of `adoption-tracking.md`, in the same relationship both
hold to the model-owning references: it applies the saturation MODEL and the adoption-KPI
MODEL without redefining either.

**It does not own the saturation threshold.** The saturation math, the four bands, and the
cross-change load template are owned by `impact-assessment.md` §Cumulative Change Load
Assessment. This doc owns only the per-change fatigue read, the band → remediation routing,
and the outcome scorecard.

**Duplicate-source contract (load-bearing).** This doc owns the capability/output layer
ONLY. The MODELS it instruments are owned elsewhere and consumed BY REFERENCE — restating
any of them here is a duplicate-source-discipline violation (register-or-remove), because it
forks a single-source value into a second drift target:

| Model the capability reads | Owner (reference, do NOT restate) |
|---|---|
| Cumulative-change-load saturation math + the four bands (cut-points) + the cross-change load template | `impact-assessment.md` §Cumulative Change Load Assessment (CANONICAL) |
| The ADKAR-symptom read of saturation + the §9 threshold rule (do-not-add-load-at-Critical) | `adkar-framework.md §9` |
| Adoption KPIs + their thresholds + their measurement horizons + the exit criteria | `hypercare-plan.md` (Exit Criteria + ADKAR Reinforcement Activities) |
| The reinforcement-window horizon (the "recent" bound for the fatigue denominator) | `hypercare-plan.md` (T-Minus / Go-Live-Through-Exit timeline; reinforcement check) |
| The "declaring victory at go-live / confusing deployment with adoption" anti-pattern | `hypercare-plan.md` + `readiness-checklist.md` |

Do NOT restate the band cut-points, the KPI thresholds, the KPI horizons, or the
reinforcement-window length in this doc. Cite the section; read the value from it.

## When to run

The two capabilities are cross-cutting Mode G capabilities — they have no independent
trigger. They run when Mode G runs (the Mode A methodology selection includes ADKAR, or on
an explicit adoption-instrumentation request) and a go-live / hypercare is in flight:

- **Change-fatigue monitoring** runs whenever this change's impacted audiences may also be
  carrying other concurrent or recently-landed changes (the fatigue denominator is inherently
  multi-change; it reads the standing cumulative load and filters to this change's audiences).
- **Outcome measurement** runs once a change has deployed (or is approaching its KPI
  horizons), to report actual-vs-target against the Mode D adoption KPIs.

The capabilities read their impacted audiences from the Mode A impact assessment
(`impact-assessment.md`) — which supplies, per group, the impacted population and the
five-dimension overall severity that the saturation math already uses — and the
go-live / hypercare timeline + adoption KPIs from the Mode D hypercare plan
(`hypercare-plan.md`).

## 1. Change-Fatigue Monitoring

The saturation math and the bands are owned by `impact-assessment.md` §Cumulative Change
Load Assessment; the ADKAR-symptom read and the §9 threshold rule are owned by
`adkar-framework.md §9`. This section owns the **per-change fatigue read**, the **counting
rule**, and the **band → remediation routing**.

### Saturation source (delegation)

The saturation percentage and the four bands (Low / Moderate / High / Critical, with their
cut-points and the Prosci/McKinsey grounding statistics) are read from `impact-assessment.md`
§Cumulative Change Load Assessment — the inventory → score(1-4)/dimension → aggregate →
normalize method and the band table. The ADKAR-symptom read of an over-saturated audience
and the do-not-add-load threshold rule are read from `adkar-framework.md §9`. **No band
numbers are restated here** — they are cited by section name. The fatigue table is a *view*
over the impact-assessment load math, filtered to this change's audiences.

### Counting rule (the per-change fatigue denominator)

- **What counts toward an audience's load:** concurrent **in-flight** changes (go-live not
  yet passed) **plus** changes still inside their **hypercare reinforcement window** — i.e.
  changes whose go-live is recent enough that the audience is still in the reinforcement /
  valley phase and its absorption capacity is still depressed. "Recent" is defined by the
  reinforcement-window horizon in `hypercare-plan.md` (through the reinforcement check on the
  Go-Live-Through-Exit timeline), **not** a fresh hardcoded look-back constant — anchoring
  "recent" to an existing horizon avoids minting a new threshold.
- **How load is scored:** severity-weighted per the existing 1-4-per-dimension method in
  `impact-assessment.md` — a count of low-severity changes is not the same load as the same
  count of critical changes. The fatigue status for an audience is the saturation **band**
  that the impact-assessment load math assigns to that audience for this set of changes.
- **When the cumulative-load table is absent:** produce the load row(s) for this change's
  audiences using the impact-assessment method (push-to-resolve — do not skip the read),
  and label any unsourced concurrent-change severity `[ASSUMPTION – CONFIRM]`.

### Band → remediation routing

The remediation per fatigued audience maps deterministically to the impact-assessment band
(this is a 1:1 read of the band → action column in `impact-assessment.md` plus the
`adkar-framework.md §9` threshold rule — it adds the capability framing, not a new threshold):

| Saturation band (read from `impact-assessment.md`) | Fatigue status | Remediation |
|---|---|---|
| Low | Capacity | None — proceed |
| Moderate | Strain | **Sequence** — stagger this change's training/comms peaks to avoid overlap with other in-flight changes |
| High | Near-saturation / fatigued | **Stagger / defer** — defer non-critical elements of this change; increase support for current changes |
| Critical | Saturated | **Pause** — do not add new Knowledge/Ability load (per `adkar-framework.md §9` threshold rule); land in-flight changes first |

Flag any audience in the **High** or **Critical** band as **fatigued**. The band labels and
their cut-points are NOT restated here — read them from `impact-assessment.md`.

### Change-fatigue table (output format) — attaches to the adoption-tracking surface

The fatigue table shares the audience-row spine and the evidence-label + reversibility
conventions of the consolidated adoption-tracking table (`adoption-tracking.md` §4) — it is a
sibling adoption capability that attaches to that surface, not a parallel artifact.

| Column | Source / Rule | Notes |
|---|---|---|
| **Impacted Audience** | from the Mode A impact assessment | a specific named functional group — never "all users" (inherits the audience-blind guardrail) |
| **Concurrent / Recent Change Load** | saturation band read from `impact-assessment.md`, scoped to this change's audiences, "recent" per the counting rule | `[SOURCE]` on the load figure; `[ASSUMPTION – CONFIRM]` where concurrent-change data is unavailable; cite the band by name, do not restate the cut-point |
| **Fatigue Status** | Capacity / Strain / Near-saturation (fatigued) / Saturated (fatigued) per the band → remediation map | flag High and Critical as fatigued |
| **Remediation** | the band-mapped remediation (None / Sequence / Stagger-defer / Pause) | deterministic from the band; do not free-form |
| **Reversibility · Confidence** | tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) + confidence (HIGH / MEDIUM / LOW) per the skill's Reversibility Discipline | required on every decision-class row for pmo-qa-auditor G4 |

Table shape (one row per audience):

```
| Impacted Audience | Concurrent / Recent Change Load | Fatigue Status | Remediation | Reversibility · Confidence |
|-------------------|---------------------------------|----------------|-------------|----------------------------|
| <named group>     | <band, by ref> [SOURCE]         | Capacity / Strain / Near-saturation (fatigued) / Saturated (fatigued) | None / Sequence / Stagger-defer / Pause | <tier> · <confidence> |
```

Worked example row (real-shaped audience):

```
| Buying & Planning | High (per impact-assessment load table) [SOURCE] | Near-saturation (fatigued) | Stagger / defer — defer non-critical training; +support | MODERATE · HIGH |
```

## 2. Outcome Measurement (Deployed vs Adopted)

The adoption KPIs, their thresholds, and their horizons are owned by `hypercare-plan.md`
(Exit Criteria); `adkar-framework.md §10` owns the ADKAR-element-level outcome map; the
deployed-vs-adopted anti-pattern is owned by `hypercare-plan.md` + `readiness-checklist.md`.
This section owns the **deployed-vs-adopted rule**, the **verdict scale**, and the
**scorecard format**.

### KPI source (delegation)

The adoption KPIs are the `hypercare-plan.md` Exit Criteria — read the KPI definitions, their
thresholds, and their measurement horizons from that reference. **No KPI is redefined here
and no new KPI is introduced** — outcome measurement consumes the Mode D Hypercare KPI
dictionary as its measurement surface (the Mode D KPI table is unchanged by this capability).

### Deployed-vs-adopted rule

- **Deployed** = go-live occurred. Binary; evidence = the cutover record. Deployment proves
  the change shipped — it proves nothing about adoption.
- **Adopted** = the KPI verdicts at each KPI's defined horizon. A change is "adopted" only
  when its adoption KPIs are MET at their horizons.
- The split is **mandatory in every scorecard header**: a one-line `Deployed: Yes/No
  (go-live date)` precedes the KPI rows. A change with go-live complete but KPIs not yet at
  horizon reads **"Deployed — adoption not yet proven"**, never "successful".

### Verdict scale

| Verdict | When | Rule |
|---|---|---|
| **MET** | the KPI is at or past its horizon AND the measured actual meets the target | the only verdict that supports an "adopted" claim for that KPI |
| **ON-TRACK** | the KPI is trending toward target but has not yet sustained the required window | mirrors the hypercare exit "declining trend / sustained 2 consecutive weeks" language — not yet MET, not failing |
| **NOT-MET** | the KPI is at or past its horizon AND the measured actual is below target | a real miss — route remediation |
| **NO-DATA** | the KPI's horizon has not yet been reached (or telemetry is unavailable) | = "deployed, not yet measurable"; **never** report as MET or as success |

Before a KPI's horizon, its verdict is **NO-DATA**. Reporting an actual before the horizon is
the deployed-vs-adopted error itself — the "actual" is read at each KPI's `hypercare-plan.md`
horizon, not at go-live.

### Outcome scorecard (output format) — attaches to the adoption-tracking surface

| Column | Source / Rule | Notes |
|---|---|---|
| **KPI** | the `hypercare-plan.md` Exit-Criteria KPI | cite the KPI; do not restate its threshold |
| **Target** | the KPI's threshold, by reference to `hypercare-plan.md` | read the value; do not restate it as a new canonical figure |
| **Actual** | the measured value at the KPI's horizon | `[SOURCE]` on measured actuals; `[ASSUMPTION – CONFIRM]` where telemetry is unavailable |
| **Horizon** | the KPI's defined measurement horizon, from `hypercare-plan.md` | the point at which "actual" is read |
| **Verdict** | MET / ON-TRACK / NOT-MET / NO-DATA per the verdict scale | pre-horizon ⇒ NO-DATA |
| **Reversibility · Confidence** | tier + confidence per the skill's Reversibility Discipline | required on every decision-class row for G4 |

Table shape (preceded by the Deployed header; one row per KPI):

```
Deployed: <Yes/No> (<go-live date or [ASSUMPTION – CONFIRM]>)

| KPI | Target (by ref) | Actual | Horizon | Verdict | Reversibility · Confidence |
|-----|-----------------|--------|---------|---------|----------------------------|
| <hypercare KPI> | <threshold, by ref> | <measured> [SOURCE] | <T+ horizon> | MET / ON-TRACK / NOT-MET / NO-DATA | <tier> · <confidence> |
```

Worked example:

```
Deployed: Yes (2026-04-06)

| KPI | Target (by ref) | Actual | Horizon | Verdict | Reversibility · Confidence |
|-----|-----------------|--------|---------|---------|----------------------------|
| Adoption rate (DAU / Expected) | per hypercare Exit Criteria | not yet at horizon | sustained 2 consecutive wks | NO-DATA — deployed, not yet proven | CHEAP · HIGH |
```

(An externally-shared scorecard that asserts ADOPTED is EXPENSIVE / IRREVERSIBLE per the
skill's Reversibility Discipline — this capability inherits those tiers; it does not lower
them.)

## 3. Composition / Ownership Seam

| Reference | Owns |
|---|---|
| `impact-assessment.md` §Cumulative Change Load | the saturation math, the four bands + cut-points, the cross-change load template, the grounding statistics |
| `adkar-framework.md §9` | the ADKAR-symptom read of saturation + the do-not-add-load-at-Critical threshold rule |
| `adkar-framework.md §10` | the ADKAR-element-level outcome-measurement map |
| `hypercare-plan.md` | the adoption-KPI dictionary + thresholds + horizons + exit criteria; the reinforcement-window horizon; the deployed-vs-adopted ("declaring victory at go-live") anti-pattern |
| `readiness-checklist.md` | the deployment-vs-adoption anti-pattern (readiness-side) |
| `adoption-tracking.md §4` | the consolidated adoption-tracking table (the shared surface the fatigue table + outcome scorecard attach to) |
| **this doc** | the per-change fatigue read + counting rule + band → remediation routing; the deployed-vs-adopted rule + verdict scale + scorecard format |

## 4. Composition / Boundaries

- **Reads:** Mode A impacted audiences (per-group population + severity → the saturation
  read); the standing cumulative change load (`impact-assessment.md` method) for the fatigue
  denominator; Mode D hypercare adoption KPIs + their horizons + the reinforcement-window
  horizon + the go-live/cutover record.
- **Owns:** the capability/output layer ONLY — the per-change fatigue read, the band →
  remediation routing, the deployed-vs-adopted rule, the verdict scale, and the two table
  formats.
- **Does NOT own:** the saturation math / bands, the §9 threshold rule, the adoption-KPI
  definitions / thresholds / horizons, or the reinforcement-window length — those stay in
  `impact-assessment.md`, `adkar-framework.md`, and `hypercare-plan.md` and are consumed by
  reference.
- **Emits:** the change-fatigue table + the outcome scorecard (both attached to the
  adoption-tracking surface) + fatigue / outcome findings + `R-CM-###` RAID entries for
  fatigued audiences and NOT-MET outcomes, routed via the skill's Section 7 Next Actions /
  Section 8 RAID Updates.

## 5. Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|---|---|---|---|
| **Restating the saturation bands here** | The Low/Moderate/High/Critical cut-points (or the Prosci saturation statistic) are written into this doc | "Self-contained doc" instinct overriding duplicate-source-discipline | Reference `impact-assessment.md` §Cumulative Change Load by section name; read the band, never copy the number |
| **Scoring adoption at go-live (deployed-vs-adopted error)** | The outcome scorecard reports "actual" — or an "adopted/successful" verdict — at go-live, before the KPI horizons | Go-live is the visible, celebratable event; the horizon lands weeks later | Read "actual" at each KPI's `hypercare-plan.md` horizon; pre-horizon verdict is NO-DATA = "deployed, not yet proven", never MET |
| **Fatigue table that counts changes without severity weighting** | The load cell is a raw count of concurrent changes ("faces 4 changes → fatigued") rather than the severity-weighted saturation band | Counting is easier than running the impact-assessment 1-4/dimension math | Derive the load from the `impact-assessment.md` saturation band (severity-weighted), not a raw change count |
| **Inventing a new "recent" look-back constant** | "recent" is defined as a fresh hardcoded window (e.g. "last 90 days") with no corpus basis | Reaching for a familiar fixed window instead of an existing horizon | Anchor "recent" to the `hypercare-plan.md` reinforcement-window horizon — a pointer to an existing number, not a new threshold |
| **ADOPTED claim without a reversibility tier** | A scorecard asserts a change is adopted/successful with no reversibility tier on the determination | Treating the outcome verdict as a status note rather than a decision-class output | Pair every deployed-vs-adopted determination with a reversibility tier + confidence (an externally-shared ADOPTED claim is EXPENSIVE/IRREVERSIBLE) per the skill's Reversibility Discipline |

## 6. Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|---|---|---|
| **Saturation-source discipline** | References the `impact-assessment.md` band for every fatigue read; the fatigue table reads as a view over the existing load math with no restated cut-point | Restates the band cut-points "for convenience" in this doc, forking a second drift target |
| **Deployed-vs-adopted rigor** | Splits Deployed (go-live) from Adopted (KPI verdicts at horizon); reports NO-DATA pre-horizon and keeps hypercare open | Reports "go-live successful, adoption complete" on go-live day; support is pulled before the horizon |
| **Counting-rule discipline** | Counts concurrent in-flight changes plus changes inside the reinforcement window, severity-weighted; anchors "recent" to the hypercare horizon | Counts only in-flight changes (misses the valley overlap) or invents a fixed look-back constant |
| **Verdict calibration** | Uses MET / ON-TRACK / NOT-MET / NO-DATA; never forces a MET/NOT-MET call before the horizon closes | Forces a binary verdict pre-horizon, reading a deployed-but-unmeasured KPI as a pass |
| **Reversibility labeling** | Carries a reversibility tier + confidence on every fatigue status, remediation, and outcome verdict; treats a shared ADOPTED claim as EXPENSIVE/IRREVERSIBLE | Reports fatigue flags and outcome verdicts as bare status with no tier, failing G4 |
