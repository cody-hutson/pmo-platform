<!-- reference-durability: allow-link -->
# Watermelon Detection — PMO QA Auditor Reference

## Purpose

This file defines the **watermelon (green-masking-risk) detection** capability the
pmo-qa-auditor applies when reviewing status / health outputs. A "watermelon" is a
status reported GREEN on the outside while the underlying evidence is amber or red —
the most common PMO data-integrity failure. The auditor consults this file in
**Mode A (Single Output Review)** and **Mode C (Push-to-Resolve Audit)** whenever the
output under review asserts or rolls up a health/RAG status, to test that the reported
green is not masking contradicting evidence.

This doc is the **canonical home** of the watermelon signal set. It defines 8 named
signals (`W1`–`W8`), each with detection logic, data sources, the RAG-threshold it keys
off, false-positive filters, and an escalation action; plus the rule that composes fired
signals into a watermelon verdict.

## Threshold Dependency (references metric-registry.md — does not re-derive)

The numeric RAG thresholds the signals key off (SPI/CPI bands, the risk band, the
Overdue-RAID-Count band, the velocity-variance spike band, the milestone-slip band, and
the green/yellow/red decision rules) are **owned and canonicalized by the metric registry**
— see [`metric-registry.md`](../../../../operations/skills/weekly-status-rollup/references/metric-registry.md).
This doc **references those thresholds by their registry role-name; it does not restate
their values** (per duplicate-source-discipline — one owner per threshold). If a signal
below says "in the Overdue-RAID-Count RED band" or "outside the velocity-variance spike
band," the *value* of that band lives in the registry, not here. Each signal's
**RAG-threshold dependency** field names the registry role it consumes.

A signal's **firing condition is the green-masking contradiction**, not a re-stated
threshold. The registry's band tells you the *materiality of a metric in isolation*; a
watermelon signal fires on the *conjunction of a GREEN report with a contradicting band
reading*. W3 makes this concrete: the registry owns the Overdue-RAID-Count band
(🟢 / 🟡 / 🔴); W3 fires on **GREEN-reported-health while overdue RAID exists** — it reads
the band from the registry rather than inventing one (see W3 and the Verdict-Composition
note).

> Resolution note: until the metric registry lands, each signal's threshold dependency is
> a named-but-unresolved reference (the role-name is stable; the value resolves when the
> registry exists). Detection logic that needs a value reads it from the registry at
> evaluation time. A signal whose band cannot be resolved (registry absent, or the source
> artifact not provided) is **un-evaluable**, not silently clean — see the
> INDETERMINATE / EVIDENCE-GAP outcome in Verdict Composition.

## Signal Schema

Every signal is specified with these five fields:

| Field | Content |
|---|---|
| **Detection logic** | The precise firing condition — the observable predicate over the output + sources. |
| **Data sources** | The artifacts/fields the auditor reads to evaluate the predicate (health indicator, RAID log, velocity figures, risk register, etc.). |
| **RAG-threshold dependency** | The `metric-registry.md` role-name(s) the predicate keys off (referenced, not re-derived). |
| **False-positive filters** | The conditions under which a fired predicate is NOT a watermelon (legitimate explanations) — applied before the signal counts. |
| **Escalation action** | What the auditor emits when the signal survives its FP filters — the evidence-cited finding + routing. |

Each signal also carries a **Severity: STRONG | WEAK** used by the verdict-composition
rule below.

## Signals

### W1 — Persistent-green under recurring RAID  · Severity: STRONG

- **Detection logic:** health = GREEN across ≥N consecutive reporting windows while ≥1 RAID
  item recurs or reopens across those same windows.
- **Data sources:** health-indicator history (PORTFOLIO.md / roll-up), RAID log entry
  history (recurrence / reopen events).
- **RAG-threshold dependency:** the registry **Risk** band; the consecutive-window count N
  per the registry / portfolio reporting-cadence role.
- **False-positive filters:** the recurring item is an explicitly **accepted** risk with a
  documented acceptance (not an open contradiction); OR the recurrence is an
  administrative re-log of a closed item.
- **Escalation action:** flag `W1 watermelon — green held N windows while RAID <ID> recurred`;
  cite the window dates + RAID ID; route per the auditor's finding-escalation.

### W2 — Green project-RAG over Amber/Red component-RAG  · Severity: STRONG

- **Detection logic:** rolled-up project RAG = GREEN while ≥1 component / sub-dimension RAG
  = Amber (🟡) or Red (🔴).
- **Data sources:** project-level RAG, component/sub-dimension RAGs (the health dimensions:
  Schedule / Scope / Quality / Stakeholders + Integration Risk).
- **RAG-threshold dependency:** the registry **SPI / CPI** bands and **Risk** band at the
  component level, read against the project-level roll-up. The transparent worst-component
  roll-up rule itself is owned upstream (registry → `channel-formats.md` § RAG Threshold
  Standards); W2 detects a *violation* of that roll-up, it does not re-derive it.
- **False-positive filters:** the amber/red component is **out of scope** for the rolled-up
  status by a documented rule (e.g., a deferred workstream excluded from the baseline); OR
  the roll-up rule legitimately weights the component to non-material.
- **Escalation action:** flag `W2 watermelon — project GREEN over component <name> <Amber|Red>`;
  cite both RAG values + the roll-up that should have propagated; require a transparent
  worst-component roll-up.

### W3 — Stale / overdue RAID under green  · Severity: STRONG

- **Detection logic:** **green-masking condition** — overall project/health RAG = GREEN
  while ≥1 RAID **action** is OVERDUE. The firing trigger is the *contradiction* (GREEN
  reported while overdue RAID exists), per the registry's stated W3 contract
  (`metric-registry.md` Consumers row: "its W3 green-masking trigger: overdue ≥ 1 while
  overall RAG green"). **OVERDUE is rule-defined** as *past the due-date AND not rescheduled
  with justification* per `raid-templates.md §3.2` item 4 — a past-due item that was
  rescheduled-with-justification is **not** overdue and does not fire W3. The **AC reference
  case is 5 overdue items under green** (5 ≥ 3 ⇒ the registry's Overdue-RAID-Count 🔴 RED
  band, an unambiguous masked breach).
- **Data sources:** RAID log (Status field = `Overdue` per `raid-templates.md §3.2`;
  each action's due-date and any reschedule justification), the health indicator asserting
  GREEN.
- **RAG-threshold dependency:** the registry-owned **Overdue RAID Count** band
  (🟢 `0` / 🟡 `1 ≤ count < 3` / 🔴 `count ≥ 3`) — **referenced from the registry, not
  re-thresholded here.** W3 does not assert its own count cut-point; the count→band mapping
  is the registry's. W3's *severity contribution* keys off the green-masking contradiction:
  any overdue RAID under a GREEN report is a STRONG contradiction (the registry band scales
  the *evidence weight* cited in the flag — a 🔴 RED count is a harder masked breach than a
  🟡 YELLOW one, and the flag reports the band). The per-item lifecycle/overdue-state
  definition is `raid-templates.md §3.2` item 4; per-item AGE-escalation timing is owned by
  `escalation-thresholds.md` (the registry references it, this doc does not re-derive it).
- **False-positive filters:** every overdue item is rescheduled with a documented
  justification (then it is not "overdue" per the §3.2 rule and W3 does not fire); OR the
  items are trivial / closed-pending administrative cleanup with no delivery impact. Apply
  the §3.2 definition before counting — "past the due date" alone is not "overdue."
- **Escalation action:** flag `W3 watermelon — GREEN with <count> overdue RAID action(s)
  [registry band: <🟢|🟡|🔴>]: <IDs>`; cite each RAID ID + its due-date + days-overdue +
  the registry Overdue-RAID-Count band the count falls in, as the evidence; route to the
  status author for a corrected (non-green) health or a documented reschedule.
  **This is the headline watermelon-AC path.**

### W4 — Velocity spike beyond credible band  · Severity: WEAK

- **Detection logic:** reported velocity changes window-over-window by an amount that puts
  the **Velocity-Variance metric into its registry RED band**, AND the new figure falls
  outside the Cone-of-Uncertainty range that governs velocity expression.
- **Data sources:** velocity figures across windows (sprint/iteration reports).
- **RAG-threshold dependency:** the registry **Velocity Variance** band (its 🔴 RED
  spike cut-point is the watermelon-spike trigger — registry-owned, not re-stated here);
  the **velocity-as-range** rule (`estimation-standards.md §5`) supplies the credibility
  band the new figure is tested against.
- **False-positive filters:** a documented **re-baseline** (team-size change, scope change,
  calendar effect) explains the jump; OR the figure is correctly expressed as a range whose
  movement is within the §5 band.
- **Escalation action:** flag `W4 (weak) — velocity variance in RED band, outside credible
  range`; cite the two window figures + the registry band; contributes to a Tier-2 verdict
  only with corroboration.

### W5 — Zero open risks on an active project  · Severity: WEAK

- **Detection logic:** open-risk count = 0 on a project that is ACTIVE and past initiation.
- **Data sources:** risk register / RAID log (open-risk count), project lifecycle state.
- **RAG-threshold dependency:** the registry **Risk** band — 0 open risks against the
  expected floor for an active project.
- **False-positive filters:** a genuinely low-risk maintenance/BAU project with a documented
  risk-review that found none; OR a brand-new project still in initiation.
- **Escalation action:** flag `W5 (weak) — zero open risks on active project`; cite the risk
  register freshness date; contributes to Tier-2 with corroboration.

### W6 — Milestone dates not aging  · Severity: WEAK

- **Detection logic:** milestone target dates unchanged across ≥N windows while
  percent-complete is also flat (no progress, no date movement).
- **Data sources:** milestone target-date history, percent-complete history.
- **RAG-threshold dependency:** the registry **SPI** (schedule) band and the **Milestone
  Slip Rate** decision rule.
- **False-positive filters:** the milestone legitimately has slack and is genuinely on-track
  (progress IS occurring, dates correctly stable); OR a documented hold.
- **Escalation action:** flag `W6 (weak) — milestone <name> dates static with flat %-complete`;
  cite the unchanged dates + flat %; contributes to Tier-2.

### W7 — 100% task completion under slipping features/scope  · Severity: WEAK

- **Detection logic:** task-completion ≈ 100% while feature/scope completion (or SPI) lags —
  tasks closed but outcomes not delivered.
- **Data sources:** task-completion metric, feature/scope-completion metric, SPI.
- **RAG-threshold dependency:** the registry **SPI** band and the **Scope** band; the
  task-vs-feature cross-reference.
- **False-positive filters:** the remaining features are genuinely out of the current
  window's committed scope; OR a documented phase boundary where task-complete precedes
  feature-integration by design.
- **Escalation action:** flag `W7 (weak) — tasks 100% but features/SPI lagging`; cite the
  task vs. feature figures; contributes to Tier-2.

### W8 — Self-reported RAG without objective derivation  · Severity: WEAK

- **Detection logic:** a RAG status is asserted with no `[SOURCE]` tag to an objective metric
  and no derivation-rule run (the status is opinion, not computed).
- **Data sources:** the RAG assertion + its evidence labels; the metric(s) that should drive it.
- **RAG-threshold dependency:** all registry RAG bands — the derivation provenance the
  status should cite.
- **False-positive filters:** the RAG IS derivation-backed and merely under-labeled (the
  source exists and is cited elsewhere in the same output); OR a qualitative dimension with no
  objective metric by design, explicitly marked as judgment.
- **Escalation action:** flag `W8 (weak) — RAG self-reported, no [SOURCE]/derivation`; require
  a derivation-rule run + [SOURCE] tag; contributes to Tier-2; aligns with the
  `failure-mode-standard.md` Watermelon-RAG-acceptance INPUT discipline (re-derive, surface the
  conflict — never silently accept). **Base-rate caution:** W8 fires on an *absence* of
  labeling, which is the un-instrumented default for many human-authored status outputs.
  Treat W8 as a corroborator only with a **non-W8 WEAK signal** (W4–W7); do not let W8 + one
  other weak collapse the 2-weak gate into a 1-weak gate (see Verdict Composition).

## Verdict Composition

Fired signals (those surviving their false-positive filters) compose into a single verdict
by **severity tier** — NOT by any-1-fires (which over-flags) and NOT by a weighted score
(which would re-introduce a second threshold-owning surface that drifts against the
registry):

- **WATERMELON-FLAG (Tier 1)** — **≥1 STRONG signal** (W1, W2, or W3) survives its FP filters.
  A single strong contradiction of green is sufficient. (The headline AC case: W3 fires → Tier 1.)
- **WATERMELON-FLAG (Tier 2)** — **≥2 independent WEAK signals** (from W4–W8) survive on the
  **same project / reporting window**. Soft indicators must corroborate.
- **INDETERMINATE / EVIDENCE-GAP** — **≥1 signal is un-evaluable** because the output omits the
  artifact the signal needs (RAID log absent, component RAGs not provided, velocity figures
  missing) OR a referenced registry band cannot be resolved (the registry is unavailable),
  AND no STRONG signal has independently fired on the evidence that *is* present. The verdict
  is NOT NO-FLAG — absence of evidence is not evidence of absence, and silently passing a
  missing-artifact case as clean is itself a watermelon vector.
- **NO-FLAG (CLEAN)** — **all signals were evaluable** and none survived its filters: no STRONG
  signal, fewer than 2 corroborating WEAK signals, and no evidence gap. Record the signals
  evaluated and the FP filters that explained any near-misses, so CLEAN is distinguishable
  from un-evaluated.

**Same-evidence de-duplication (no double-count).** When **multiple signals fire on the same
RAID item / same evidence row** — most commonly a single RAID action that is both *recurring*
(W1) and *overdue* (W3) under green — count the **highest-severity signal once** for tier
purposes and list the others as **contributing facets**, not independent corroborators. One
item must never be reported as two independent STRONG signals (it overstates corroboration and
apparent severity, the inverse of the reviewer-fatigue problem the tiered rule exists to
avoid). This binds especially at Tier 2, where the ≥2 WEAK signals must be **independent**
(distinct evidence rows) to corroborate — two weak signals reading the same underlying row
count as one.

**Resolution precedence.** Evaluate in this order: (1) apply each signal's FP filters; (2)
de-duplicate signals sharing an evidence row to their highest-severity facet; (3) if any
STRONG signal survives → **Tier 1**; else (4) if ≥2 *independent* WEAK signals survive →
**Tier 2**; else (5) if ≥1 signal was un-evaluable for missing evidence →
**INDETERMINATE / EVIDENCE-GAP**; else (6) **NO-FLAG (CLEAN)**. A STRONG fire (step 3)
outranks an evidence gap — a confirmed masked breach is reported even if other signals could
not be evaluated.

Every flag carries the firing signal IDs + the cited evidence (the Escalation-action output
of each fired signal). A WATERMELON-FLAG is an evidence-integrity finding, not a verdict on
the project — it asserts "the reported green is not supported," and routes to the status
author for a corrected health or a documented justification. An INDETERMINATE verdict routes
to "request the missing artifact" — a distinct, valuable auditor action — not to silence.

```
  ┌──────────────────────────────────────────┐
  │ Status/health output under review         │
  └───────────────────┬──────────────────────┘
                      │ evaluate W1..W8 (apply each signal's FP filters,
                      │ then de-dup signals sharing one evidence row)
            ┌─────────▼─────────┐
            │ ≥1 STRONG fired?   │──YES──▶ WATERMELON-FLAG (Tier 1)
            │ (W1 / W2 / W3)     │         cite firing STRONG signal + evidence
            └─────────┬─────────┘         (STRONG outranks an evidence gap)
                  NO  │
            ┌─────────▼─────────┐
            │ ≥2 INDEPENDENT     │──YES──▶ WATERMELON-FLAG (Tier 2)
            │ WEAK fired on same │         cite the ≥2 corroborating WEAK signals
            │ project/window     │
            │ (W4..W8)           │
            └─────────┬─────────┘
                  NO  │
            ┌─────────▼─────────┐
            │ ≥1 signal          │──YES──▶ INDETERMINATE / EVIDENCE-GAP
            │ un-evaluable       │         name the missing artifact/band;
            │ (missing artifact  │         route: request the missing evidence
            │  or unresolved band)│         (NOT NO-FLAG — do not pass as clean)
            └─────────┬─────────┘
                  NO  │
            ┌─────────▼─────────┐
            │ NO-FLAG (CLEAN)    │
            │ (all signals       │
            │  evaluated; none   │
            │  surviving)        │
            └────────────────────┘
```

## Domain-Specific Failure Modes

These anti-patterns govern the AUDITOR applying watermelon detection (distinct from the
signals, which describe the *project's* reporting failure). Per
`core/standards/failure-mode-standard.md` 5-field template; ≥3 entries; category tags.

### Reported RAG accepted as evaluated without running the signals — INPUT

- **Signature (observable signal):** a Mode A/C audit of a health output records the
  output's self-asserted GREEN as the health verdict without evaluating W1–W8 against the
  underlying RAID/velocity/risk evidence.
- **Conditional:** do NOT accept a reported GREEN as evaluated when the underlying RAID,
  risk, and schedule evidence is in scope, because the auditor is the watermelon backstop and
  certifying the reported status instead of testing it is the green-masking failure with the
  auditor as the amplifier.
- **Root cause:** an authoritative-looking GREEN status is already present in the input;
  running 8 signals costs effort while agreeing with a confident status feels like confirmation.
- **Mitigation:** evaluate W1–W8 against the artifact evidence (RAID overdue counts, risk
  register, velocity figures, component RAGs) before recording any health verdict; when a
  STRONG signal or ≥2 independent WEAK signals survive, render WATERMELON-FLAG with the cited
  evidence; when the evidence needed is absent, render INDETERMINATE — never NO-FLAG by default.
- **Principal response vs. junior response:** Principal re-derives, finds W3 (5 overdue RAID
  under green), and flags with the RAID IDs. Junior copies the reported GREEN into the audit
  and certifies the watermelon.

### Signal fired without applying its false-positive filter — PROC

- **Signature (observable signal):** a WATERMELON-FLAG is emitted on a raw predicate match
  (e.g., zero open risks, or a past-due RAID item) without checking the signal's FP filters
  (e.g., a documented risk-review found none on a BAU project; or the item was rescheduled
  with justification, so it is not "overdue" per `raid-templates.md §3.2`).
- **Conditional:** do NOT emit a watermelon flag on a bare predicate match when the signal's
  FP filters apply, because every signal lists legitimate explanations and skipping them
  manufactures false flags that train reviewers to ignore the auditor.
- **Root cause:** the predicate is easy to evaluate; the FP filter requires reading the
  justification/context, which is extra work.
- **Mitigation:** for every fired predicate, apply the signal's False-positive-filters field
  before counting it; a predicate that survives its filters counts, one that is explained does
  not (record it as evaluated-and-filtered, not flagged). For W3 specifically, apply the §3.2
  "past-due AND not rescheduled-with-justification" definition before counting an item overdue.
- **Principal response vs. junior response:** Principal checks the reschedule justifications
  before flagging W3. Junior flags every past-due item, including the ones rescheduled with
  documented justification.

### Weak signal escalated to a standalone flag (or W8 collapsing the corroboration gate) — OUT

- **Signature (observable signal):** a single WEAK signal (W4–W8) is emitted as a
  WATERMELON-FLAG without the ≥2-corroboration the verdict rule requires; or W8 (a near-always
  fired absence-of-[SOURCE] signal) is paired with one other weak signal and reported as "2
  corroborating signals," collapsing the 2-weak gate into a 1-weak gate.
- **Conditional:** do NOT raise a standalone WATERMELON-FLAG on one WEAK signal, and do NOT
  count W8 as an independent corroborator of a single other weak signal, because the
  verdict-composition rule requires ≥2 *independent* corroborating weak signals (or ≥1 STRONG)
  — a lone weak signal, or a near-universal one inflating the count, over-flags and is exactly
  the any-1-fires failure the tiered rule rejects.
- **Root cause:** a single suspicious indicator feels flag-worthy in isolation; the
  corroboration gate is a second step that is easy to skip, and W8 fires on the corpus's
  default un-instrumented state rather than on an anomaly.
- **Mitigation:** apply the Verdict-Composition rule — a lone WEAK signal records as "noted,
  insufficient for a flag"; promote to Tier-2 only when ≥2 *independent* WEAK signals
  corroborate on the same project/window (W8 corroborating only a non-W8 weak signal), or when
  a STRONG signal independently fires.
- **Principal response vs. junior response:** Principal records a lone W5 as noted and waits for
  independent corroboration; treats W8 as a quality modifier, not a vote. Junior raises a
  watermelon flag on zero-open-risks alone, or counts W8 + one other weak as two, and the flag
  is dismissed as noise.

### Evidence gap silently passed as NO-FLAG — OUT

- **Signature (observable signal):** a signal could not be evaluated because the output omits
  the artifact it needs (the RAID log is not in the status, component RAGs were not provided,
  the registry band is unresolved) and the audit records NO-FLAG / CLEAN, indistinguishable
  from "evaluated and clean."
- **Conditional:** do NOT record NO-FLAG when ≥1 signal was un-evaluable for missing evidence
  and no STRONG signal independently fired, because absence of evidence read as evidence of
  absence is itself a watermelon vector — a status that omits the very artifacts the signals
  test should not earn a clean verdict by virtue of the omission.
- **Root cause:** the verdict rule's binary FLAG/NO-FLAG shape (before this doc's
  INDETERMINATE outcome) had nowhere to put "couldn't evaluate," so missing-artifact cases
  collapsed into the clean terminal.
- **Mitigation:** render **INDETERMINATE / EVIDENCE-GAP**, name the missing artifact or band,
  and route to "request the missing evidence." Reserve NO-FLAG (CLEAN) for the case where all
  signals were evaluable and none survived. A STRONG fire still outranks an evidence gap.
- **Principal response vs. junior response:** Principal flags "INDETERMINATE — component RAGs
  not provided; cannot evaluate W2" and requests them. Junior records NO-FLAG and the masked
  component never surfaces.

## References

- [`metric-registry.md`](../../../../operations/skills/weekly-status-rollup/references/metric-registry.md)
  — owns the RAG thresholds the signals key off (SPI/CPI bands, Risk band, the registry-owned
  **Overdue RAID Count** band 🟢 `0` / 🟡 `1 ≤ count < 3` / 🔴 `count ≥ 3`, the Velocity-Variance
  spike band). Referenced by role-name, not re-derived. The registry's Consumers row states
  W3's green-masking contract directly.
- `raid-templates.md §3.2` item 4 (Action Lifecycle Rules — "Overdue actions auto-escalate …
  to PM within 1 business day") — the per-item **OVERDUE definition** W3 uses: past the
  due-date AND not rescheduled with justification.
- `escalation-thresholds.md` (owned by the ppm-agent skill) — per-item RAID **AGE**-escalation
  timing; the registry references it for age timing and this doc defers to the registry for it
  (single-sourced).
- `core/standards/failure-mode-standard.md` — the Watermelon-RAG-acceptance INPUT entry W8 aligns
  to; the 5-field template this doc's failure-mode section uses.
- The auditor consults this doc in Mode A (Single Output Review) + Mode C (Push-to-Resolve
  Audit) per [`../SKILL.md`](../SKILL.md).

### Provenance

- Reference doc created per the health-and-raid-determinism milestone (v1.20), tracking item
  **#270**. Consumes the metric registry from tracking item **#271** and
  the RAID-age escalation owner **#269**.
