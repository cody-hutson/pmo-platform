# Adoption Tracking Reference

## Purpose

This reference owns the **adoption-instrumentation layer** for the change-management
skill Mode G (Adoption Tracking) — the per-group champion-ratio comparison and
under-target flag, the valley-of-despair prep-plan assembly and timing-window binding,
the sponsor-engagement touchpoint tracking and decline/absence flag, and the unified
adoption-tracking-table output contract. It is the capability-orchestration sibling of
`adkar-assessment.md`, in the same relationship both hold to `adkar-framework.md`:
`adkar-assessment.md` applies the ADKAR scale and barrier rule without redefining them,
and this doc applies the champion / valley / sponsor MODELS without redefining them.

**Duplicate-source contract (load-bearing).** This doc owns instrumentation ONLY. The
MODELS it instruments are owned elsewhere and consumed BY REFERENCE — restating any of
them here is a duplicate-source-discipline violation (register-or-remove), because it
forks a single-source value into a second drift target:

| Model the instrumentation reads | Owner (reference, do NOT restate) |
|---|---|
| Change-champion ratio target + formula + severity-banded denominators | `adkar-framework.md §7` (CANONICAL) |
| Valley-of-despair model + the support-ramp rule | `adkar-framework.md §8` |
| Valley dip magnitude / peak-disruption timing / recovery curves + the OCM Reinforcement T+ schedule | `hypercare-plan.md` (Valley-of-Despair Parameters + ADKAR Reinforcement Activities) |
| Sponsor-engagement ABC obligation model + observable failure signals + interventions | `adkar-framework.md §5` |
| Sponsor-In-Name-Only (SINO) anti-pattern + the effective-sponsor success statistic | `hypercare-plan.md` |

Do NOT restate the §7 denominators, the valley parameter values, the ABC obligation
table, or the sponsor statistic in this doc. Cite the section; read the value from it.

## When to run

- **Mode G adoption tracking** runs when the Mode A methodology selection (SKILL.md
  Step 2.5) includes ADKAR, or on an explicit adoption-instrumentation request
  ("champion ratio", "are we resourced for adoption", "is sponsorship slipping",
  "valley of despair prep", "adoption tracking").
- The instrumentation reads its impacted audiences from the Mode A impact assessment
  (`impact-assessment.md`) — which supplies, per group, the impacted population and the
  five-dimension overall severity (1-4) that keys the champion denominator — and the
  go-live / hypercare timeline and valley parameters from the Mode D hypercare plan
  (`hypercare-plan.md`).

## 1. Champion-Ratio Tracking

The target is owned by `adkar-framework.md §7`; this section owns the actual-vs-target
comparison and the under-target flag.

- **Target** = `adkar-framework.md §7` `champion_count = ceil(impacted_population /
  denominator)`, where the denominator is read from the §7 severity band keyed on the
  group's overall change severity (read it from §7; do not restate the band values).
- **Active-champion counting rule:** a champion counts as ACTIVE only when it satisfies
  the §7 selection criteria — peer-credible and `Desire >= 4` — AND is currently engaged
  in the advocacy network (not merely nominated). A nominated-but-inactive name, or a
  name with `Desire < 4`, does NOT count toward the active total (counting it inflates
  the ratio and masks the gap).
- **Gap + flag rule:**
  - `champion_gap = active_champions − target`.
  - `active_champions < target` ⇒ flag the group **UNDER-TARGET**. Flag severity scales
    with the gap magnitude and the group's change severity (a large gap on a severity-4
    group is a higher-severity flag than a small gap on a severity-2 group).
  - Remediation = recruit `ceil(target − active)` additional champions, selected per the
    §7 criteria (peer-credible, Desire >= 4, positive influence).
  - Severity 1 / Low groups are awareness-only per §7 (target = 0) — no champion network
    is sized, so UNDER-TARGET does not apply.
- **Worked micro-example (regression fixture by reference).** Reuse the
  `adkar-framework.md §12` groups rather than inventing a parallel fixture. Reading that
  fixture, Warehouse Ops is severity-4, population 220 → target = ceil(220 / 10) = 22
  (the §7 value computed in §12). If 14 champions are active → `champion_gap = 14 − 22 =
  −8` → flag **UNDER-TARGET (−8)**; remediation = recruit 8 more per §7 criteria. (The
  target 22 is read from §12 / §7; this section adds only the −8 gap and the flag.)

## 2. Valley-of-Despair Preparation

The model and the support-ramp rule are owned by `adkar-framework.md §8`; the parameter
values and the OCM Reinforcement schedule are owned by `hypercare-plan.md`. This section
owns the prep-plan assembly and the window binding.

- **Window derivation:** `valley_window = [go_live + peak_start, go_live + peak_end]`,
  where the peak band is read from the `hypercare-plan.md` Valley-of-Despair Parameters
  by deployment class (Standard ≈ week 2; Complex ERP/EHR ≈ week 2-4). The window is
  computed from THIS project's go-live so the prep plan is project-specific, not generic.
- **Prep-plan assembly:** bind the `hypercare-plan.md` OCM Reinforcement schedule (the
  T+ activities — quick-wins, floor-observation debrief, retrospective, recognition
  event, targeted coaching, metrics review) to the window; the prep plan is the windowed
  subset of those activities plus the §8 support-ramp guard. Do not author a new
  intervention catalog — the interventions already exist and are dated against T+.
- **Support-ramp flag rule:** any planned support step-down (super-user ratio drop,
  cessation of daily standups, help-desk hours cut) scheduled INSIDE `valley_window`
  violates the `adkar-framework.md §8` do-not-pull-support-at-the-bottom rule → flag it.
- **Missing go-live:** if the go-live date is unavailable, label it
  `[ASSUMPTION – CONFIRM]` and proceed with a relative window (T+ offsets from an assumed
  go-live), surfaced as an assumption for the operator to confirm.

## 3. Sponsor-Engagement Tracking

The §5 ABC obligation model and the §13 SINO anti-pattern are owned by
`adkar-framework.md`; the SINO hypercare activities and the effective-sponsor statistic
are owned by `hypercare-plan.md`. This section owns the touchpoint tracking, the status
rule, and the decline/absence flag.

- **Signal set** = the three `adkar-framework.md §5` ABCs made trackable (read §5 for the
  obligation model and its observable failure signals; do not restate the ABC table):
  - **A — Active/visible:** count of scheduled + attended sponsor touchpoints in the
    window (milestone presence, town halls, go-live visibility).
  - **B — Building coalition:** peer-leader alignment status {present / mixed / absent}.
  - **C — Communicating directly:** the "why" comms sponsor-authored vs PMO-ghostwritten.
- **Status rule:** any ABC exhibiting its §5 failure-signal → **At-Risk**; a sponsor who
  is absent, silent, or has delegated all change activity → **SINO** (per the §13 /
  `hypercare-plan.md` SINO anti-pattern).
- **Trend rule:**
  - **Decline** = sponsor-touchpoint cadence falling below the planned sponsor roadmap.
  - **Absence** = no sponsor touchpoint in the trailing window.
  - **Decline OR absence ⇒ a TOP-TIER risk** (a `R-CM-###` Risk routed to the operator),
    because active and visible sponsorship is the lead success predictor — the
    effective-vs-ineffective-sponsor success statistic in `hypercare-plan.md` is the
    rationale (reference it; do not restate the figure as a new canonical value here).
- **No numeric sponsor score.** Sponsor engagement is categorical {Active / At-Risk /
  SINO} by design — the §5 model is a set of obligations, not a 1-5 scale. Inventing a
  numeric sponsor score would canonicalize a threshold with no corpus basis; "decline"
  and "absence" are defined relative to THIS project's planned sponsor roadmap, not an
  absolute cutoff.

## 4. Adoption-Tracking Table (Output Format) — the shared adoption-instrumentation surface

One consolidated table, audience-rowed (the skill's audience-first principle). This is
the named artifact Mode G emits and the shared surface that the ADKAR Assessment Table
(`adkar-assessment.md`) and sibling adoption work attach to — keep the audience-row
spine and the evidence-label + reversibility conventions identical across the set.

| Column | Source / Rule | Notes |
|---|---|---|
| **Impacted Audience** | from the Mode A impact assessment | a specific named functional group — never "all users" (inherits the audience-blind guardrail) |
| **Champion Ratio (active / target)** | active counted per §1; target read from `adkar-framework.md §7` | the target reads §7 (`ceil(pop/denom)`); the table never restates the denominators |
| **Champion Status** | At target / UNDER-TARGET (gap) per §1 | `⚠ UNDER-TARGET (−N)` when active < target |
| **Sponsor ABC Status** | Active / At-Risk / SINO per §3 | name the failing ABC on At-Risk (e.g. "At-Risk (B: peer-leaders mixed)") |
| **Sponsor Trend** | stable / declining / absent per §3 | declining or absent ⇒ a top-tier `R-CM-###` Risk |
| **Valley Prep Window** | `valley_window` derived per §2 | dated from go-live + complexity band; `[ASSUMPTION – CONFIRM]` if go-live unknown |
| **Valley Prep Status** | Drafted / Bound / Gap per §2 | flag a support step-down landing inside the window |
| **Reversibility · Confidence** | tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) + confidence (HIGH / MEDIUM / LOW) per the skill's Reversibility Discipline | required on every decision-class cell for pmo-qa-auditor G4 |

Table shape (one row per audience):

```
| Impacted Audience | Champion Ratio (active/target) | Champion Status | Sponsor ABC Status | Sponsor Trend | Valley Prep Window | Valley Prep Status | Reversibility · Confidence |
|-------------------|--------------------------------|-----------------|--------------------|---------------|--------------------|--------------------|----------------------------|
| <named group>     | <active> / <target §7>         | At target / ⚠ UNDER-TARGET (−N) | Active / At-Risk (<ABC>) / SINO | stable / declining / absent | <T+ window> | Drafted / Bound / Gap | <tier> · <confidence> |
```

- **Evidence labels:** `[SOURCE]` on measured values (touchpoint counts, rosters);
  `[CONTEXT]` on memory-sourced champion/sponsor names ("from project context, not
  current artifact"); `[ASSUMPTION – CONFIRM]` on unknown counts/dates. No fabricated
  champion or sponsor names.
- **RAID routing:** every UNDER-TARGET champion gap and every declining/absent sponsor
  emits a `R-CM-###` RAID entry, routed via the skill's Section 7 Next Actions /
  Section 8 RAID Updates — remediation routed, not just described.
- **Extension contract (coherence note).** Sibling adoption capabilities attach their
  columns to THIS table — keep the audience-row spine and the evidence-label +
  reversibility conventions identical so the surface stays one consolidated artifact.

## 5. Composition / Boundaries

- **Reads:** Mode A impacted audiences (per-group population + severity → the champion
  denominator); Mode D hypercare KPIs + valley parameters + sponsor hypercare activities
  + the go-live/hypercare timeline (→ the valley window and the OCM Reinforcement
  schedule).
- **Owns:** instrumentation ONLY — the comparison/flag/window/touchpoint/table logic.
- **Does NOT own:** the champion target/denominators, the valley parameters, the ABC
  obligation model, or the sponsor statistic — those stay in `adkar-framework.md` and
  `hypercare-plan.md` and are consumed by reference.
- **Emits:** the adoption-tracking table + champion-gap findings + valley prep plan +
  sponsor-engagement status + `R-CM-###` RAID entries.

## 6. Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|---|---|---|---|
| **Re-canonicalizing a model here** | The §7 denominators, the valley parameter values, the ABC table, or the sponsor statistic are restated in this doc | "Self-contained doc" instinct overriding duplicate-source-discipline | Reference the owning section (`adkar-framework.md §5/§7/§8`, `hypercare-plan.md`); read the value, never copy it |
| **Inventing a numeric sponsor score** | Sponsor engagement scored 1-5 like ADKAR | Familiar scale reached for where the §5 model is categorical | Keep status categorical {Active / At-Risk / SINO}; "decline/absence" is relative to the planned sponsor roadmap, not an absolute cutoff |
| **Counting nominated-but-inactive champions** | The active total includes names that are merely nominated or have Desire < 4 | Larger active count makes the gap look smaller | Count a champion ACTIVE only when Desire >= 4 AND currently engaged (per §1) |
| **Generic valley plan** | The prep plan is a generic restatement of the valley model, not bound to this project's go-live window | Skipping the window derivation (no go-live anchor) | Derive `valley_window` from go-live + complexity band; `[ASSUMPTION – CONFIRM]` the go-live if unknown and proceed with a relative window |
| **Champion = super-user conflation** | The advocacy network is sized from super-user support ratios (or vice versa) | Treating the two networks as one | Size champions per §7 (advocacy); super users per `training-plan.md` (support) — distinct networks, distinct denominators |

## 7. Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|---|---|---|
| **Champion-gap rigor** | Counts only Desire >= 4, currently-engaged champions; flags UNDER-TARGET with the exact gap and the recruit count; reads the target from §7 | Counts every nominated name; reports "champions identified" with no target comparison; restates the §7 denominators |
| **Valley-window binding** | Derives the window from this project's go-live + complexity band; binds the existing OCM schedule; flags a support step-down inside the window | Emits a generic "expect a dip around week 2" note with no project-specific window and no support-ramp check |
| **Sponsor-trend discipline** | Tracks ABC touchpoints over time; raises a top-tier `R-CM-###` Risk on decline/absence; keeps the status categorical | Reports a one-time "sponsor engaged: yes"; misses the trend; invents a numeric sponsor score |
| **Evidence labeling** | `[SOURCE]` on measured touchpoints, `[CONTEXT]` on memory-sourced names, `[ASSUMPTION – CONFIRM]` on unknowns; no fabricated names | Fills champion/sponsor names from memory without labels; fabricates counts to complete the table |
| **Duplicate-source discipline** | References the owning section for every model value; the doc reads on its own without restating a single denominator or parameter | Copies the §7 band and the valley parameters into this doc "for convenience", forking two drift targets |
