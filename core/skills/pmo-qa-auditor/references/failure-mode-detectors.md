<!-- reference-durability: allow-link -->
# Failure-Mode Detector Battery — PMO QA Auditor Reference

## Purpose

This file defines the **named failure-mode detector battery** the pmo-qa-auditor applies
when assessing platform health and when reviewing individual skill outputs for ownership
clarity. It is the canonical home of **8 named detectors** (`FMD-1`–`FMD-8`, surfaced as
**D1–D8** in prose and in the report section) plus the **RACI validation gate (G9)** data
source.

The 8 detectors are **runtime detection infrastructure**, distinct from the authoring
discipline a SKILL.md documents in its own `## Domain-Specific Failure Modes` section. The
authoring format is shared — each detector is written to the same 5-field conditional
template per `core/specs/failure-mode-standard.md` — but the surface is different: these
detectors describe the *platform-wide* failure modes the auditor detects in other skills'
outputs and in platform state, not the auditor's own authoring-failure surface. The 8
detectors and their category tags are pre-canonicalized in the
`core/specs/failure-mode-standard.md` cross-validation mapping table (the 8-to-taxonomy
mapping) and its worked "Automation complacency" conversion; this doc lifts that mapping
and gives each detector an observable signature, a numeric threshold, and a current-status
read.

The auditor consults this doc in **Mode E (Platform Health Audit)** — where the battery
produces a `## Failure-Mode Detector Battery` status section in `findings-register.md` —
and in **Mode A (Single Output Review)** for the per-output detectors and the G9 RACI gate.

## Threshold Dependency (references owners — does not re-derive)

Every threshold below is **grounded in existing corpus precedent**, not invented. Where a
threshold is owned elsewhere in the corpus, this doc **references that owner by role-name or
path; it does not restate the value** (per duplicate-source-discipline — one owner per
threshold). Each detector's **Threshold owner/source** field names the grounding. The
ownership map:

| Threshold | Owner / source (referenced, not re-derived) |
|---|---|
| Automation-sample interval (`1/N` runs) | `core/specs/failure-mode-standard.md` Relationship-to-pmo-qa-auditor worked conversion ("sample at rate 1/N runs"); N resolved in this doc. |
| RACI single-Accountable rule | `operations/skills/delivery-engine/references/gate-definitions.md` LG-2-EX-4 ("a RACI naming the single Accountable per gate type") + `gate-checklists.md` ("Clear RACI with single Accountable per gate"). Owns D2 + G9. |
| Echo-chamber detection signal | `core/skills/eval-writer/references/failure-modes.md` F-30 ("Echo chamber / round-over-round opinion divergence / mandatory devil's-advocate; heterogeneity"). Owns the D3 signal + mitigation. |
| Push-to-resolve target (`>= 80%`) | `core/skills/pmo-qa-auditor/SKILL.md` Mode C scorecard ("Target: >= 80%") + `references/push-to-resolve-rubric.md`. Owns the D4 floor. |
| SPOF concentration threshold (`>= 3 contexts`) | `operations/skills/pmo-technical-analyst/SKILL.md` ("SPOF in 3+ contexts -> auto-elevate to a standalone RAID entry"). Owns the D5 threshold. |
| Hallucination zero-tolerance | CLAUDE.md Guardrails ("No fabricated owners, dates, metrics") + `pmo-qa-auditor/SKILL.md` G4 evidence-quality gate. Owns the D7 posture. |
| Rolling rigor metrics (evidence-label density, push-to-resolve trend, gate-PASS rate) | The metric-registry role-names consumed by `references/watermelon-detection.md`; referenced by role-name, un-evaluable-not-silently-clean when the owner is absent. Feeds D4 / D6 / D8 trend axes. |

Two thresholds are **operator/portfolio-specific absolutes** and are **NOT canonicalized
inline** — they resolve from the platform-behavior config surface at evaluation time:

| Config-referenced threshold | Config key (resolves at eval time) | Detector |
|---|---|---|
| Concurrency ceiling (max sustainable concurrent active workstreams) | `platform-config.toml` `[failure_mode_detectors].concurrency_ceiling` | D6 |
| Walk-back / retraction rate floor | `platform-config.toml` `[failure_mode_detectors].walk_back_rate_floor` | D8 |

> Resolution note: this doc names the config keys; the values resolve from the
> platform-behavior config surface (`platform-config.toml`, global-default-to-individual
> precedence per the Platform-Config Resolution Protocol). If no `[failure_mode_detectors]`
> section exists yet, that key-addition is a **separate** improvement outside this card's
> scope; a detector whose config key cannot be resolved is **un-evaluable**, not silently
> clean (it reports INDETERMINATE for that axis, the same posture watermelon-detection uses
> for an unresolved registry band).

## Detector Schema

Every detector is specified with the **5 template fields** per
`core/specs/failure-mode-standard.md` — **Signature**, **Conditional** (the
`do NOT X[, when Y], because Z` form), **Root cause**, **Mitigation**, **Principal vs.
junior** — **plus** four detector-specific fields:

| Field | Content |
|---|---|
| **Category** | The taxonomy tag (TRIG / INPUT / PROC / OUT / HAND), lifted verbatim from the `failure-mode-standard.md` 8-to-taxonomy mapping. |
| **Threshold trigger** | The numeric / threshold firing condition. |
| **Current-status read** | The line the auditor reports for this detector in the Mode E battery section. |
| **Surface** | Where the detector fires: Mode A (per-output), Mode E (platform-trend roll-up), or both. |
| **Threshold owner/source** | The corpus grounding for the threshold (referenced, not re-derived). |

## Detectors

### FMD-1 — Automation complacency — PROC

- **Signature:** Audit reports cite automated gate/check results (deploy `--check` greens,
  prior gate verdicts, auto-write tracker updates) as evidence without any record of the
  underlying check being re-derived or sampled for correctness in the recent window.
- **Conditional:** do NOT accept an automated gate or check result as evidence when the
  underlying check has not been sampled for correctness in the last N runs, because
  automation complacency erodes detection over time.
- **Root cause:** Automation success rate creates false confidence; sampling discipline
  decays silently because a green is cheaper to trust than to re-derive.
- **Mitigation:** Sample at a fixed interval of 1 in N runs; on a sampled run, re-derive the
  check outcome from source data; flag drift when sampled-versus-automated divergence is
  observed (any divergence on a sampled run renders a finding).
- **Principal vs. junior:** Principal re-derives the check outcome from source on sampled
  runs and records the sample result; junior trusts the automated verdict and moves on.
- **Category:** PROC.
- **Threshold trigger:** sample interval **1 in 5 runs**; any sampled divergence fires.
- **Current-status read:** "Automation-sample posture: last sampled run <date/SHA>; <K> of
  last 5 gate-runs sampled; divergence: none / <cite>."
- **Surface:** Mode E roll-up (with a Mode A signal when an output cites an automated result
  as its sole evidence).
- **Threshold owner/source:** `core/specs/failure-mode-standard.md` worked conversion ("sample
  at rate 1/N runs"); N=5 chosen as the detection-latency-versus-sampling-cost balance (1/3
  over-samples a complacency trend, 1/10 too sparse to catch drift before it compounds).
  [SOURCE: failure-mode-standard.md worked conversion + INFERRED band]

### FMD-2 — Faceless PMO — OUT

- **Signature:** A reviewed stakeholder-facing output (status, comm, exec brief, escalation)
  carries no operator or accountable-owner anchor — no named Responsible/Accountable, no
  operator voice, generic "the PMO" or passive-voice attribution throughout.
- **Conditional:** do NOT pass a stakeholder-facing output that names no accountable owner
  (no Responsible/Accountable anchor) when the output asserts a decision, commitment, or risk
  position, because a faceless PMO output severs the accountability anchor and the operator's
  name and voice are the trust carrier for the audited suite.
- **Root cause:** Generated outputs default to institutional voice ("the PMO recommends"); the
  named-owner step is friction the generator skips when no owner is in the input.
- **Mitigation:** For every decision/commitment/risk in a stakeholder-facing output, require a
  named Responsible AND a named Accountable (a person or role, not "the team"); flag any
  decision-bearing output where one or more decisions lack both. Composes with the G9 RACI gate
  — D2 is the platform-trend roll-up of the per-output G9 findings.
- **Principal vs. junior:** Principal names the owner or flags its absence as a finding with
  the exact owner-line remediation; junior ships "the PMO will follow up" and the
  accountability gap surfaces when the commitment is missed and no one owns it.
- **Category:** OUT.
- **Threshold trigger:** per-output: **one or more decision/commitment/risk with no named
  Responsible+Accountable** in a stakeholder-facing output fires. Mode-E roll-up: **more than
  20%** of reviewed decision-bearing outputs in the window carry one or more ownerless decisions
  renders a platform-trend flag.
- **Current-status read:** "Ownership-anchor posture: <K> of <M> reviewed decision-bearing
  outputs carried one or more ownerless decisions (<percent>); threshold 20%."
- **Surface:** Mode A per-output (with a Mode E roll-up).
- **Threshold owner/source:** RACI single-Accountable rule — `gate-definitions.md` LG-2-EX-4 +
  `gate-checklists.md`. Per-output is zero-tolerance (the rule is binary); the 20% roll-up band
  is the conventional one-in-five trend signal. [SOURCE: gate-definitions.md binary rule +
  INFERRED roll-up band]

### FMD-3 — Echo chamber — INPUT

- **Signature:** A recommendation or analysis output presents a conclusion with only
  confirming evidence — no contradicting evidence considered, no disconfirming source cited, no
  alternative weighed — and (Mode E) the same recommendation recurs across successive outputs
  with no opposing view ever surfacing (round-over-round opinion divergence near zero).
- **Conditional:** do NOT accept a recommendation as evidence-grounded when it cites only
  confirming evidence and no disconfirming source was sought, because the echo chamber is
  self-reinforcing recommendation with no contradicting evidence and it manufactures false
  confidence the operator cannot calibrate against.
- **Root cause:** Confirming evidence is easier to find and feels like corroboration; the
  disconfirming search is extra work the generator skips, and an agent that agrees with its own
  prior output reads as consistent rather than uncritical.
- **Mitigation:** For every recommendation/analysis, require one or more considered-and-rejected
  alternatives OR an explicit disconfirming-evidence search result; over a window, track opinion
  divergence round-over-round — zero divergence across three or more successive related outputs
  with no opposing view renders an echo-chamber flag. (Mirrors the eval-writer F-30 mitigation:
  mandatory devil's-advocate; heterogeneity.)
- **Principal vs. junior:** Principal surfaces the considered-and-rejected alternative and the
  disconfirming search; junior presents the confirming case as settled and the operator
  over-trusts a one-sided recommendation.
- **Category:** INPUT.
- **Threshold trigger:** per-output: **0 disconfirming sources and 0 considered alternatives**
  on a recommendation-class output fires. Mode-E: **three or more successive related outputs
  with round-over-round divergence of 0** renders a trend flag.
- **Current-status read:** "Echo-chamber posture: <K> recommendation-outputs with no
  disconfirming evidence (<percent>); longest zero-divergence streak: <N> outputs (flag at 3)."
- **Surface:** both (Mode A per-output + Mode E roll-up).
- **Threshold owner/source:** `eval-writer/references/failure-modes.md` F-30 ("round-over-round
  opinion divergence") supplies the signal; the three-output streak matches the platform's
  recurring N=3 emergence/corroboration convention (the pmo-technical-analyst "3+ contexts"
  rule; the observation-log emergence convention). [SOURCE: eval-writer failure-modes.md F-30 +
  the 3-context convention]

### FMD-4 — Quality drift — OUT

- **Signature:** Rigor declines across a *series* of successive outputs from the same skill —
  evidence-label density falls, push-to-resolve score trends down, gate-PASS rate degrades
  window-over-window — a downward trend no single output review (Mode A) would catch.
- **Conditional:** do NOT treat a single passing output as evidence of stable quality when the
  skill's rolling rigor metrics (evidence-label percentage, push-to-resolve score, gate-PASS
  rate) are trending down across the audit window, because quality drift is a declining-rigor
  trend across successive outputs and a point-in-time PASS masks a trajectory toward FAIL.
- **Root cause:** Each output clears the bar individually while the bar-clearance margin erodes;
  the trend is invisible without a window comparison, and per-output review is structurally blind
  to trajectory.
- **Mitigation:** Compute rolling rigor metrics over the audit window; flag when any tracked
  metric degrades by one or more severity-bands or by 15 or more percentage points
  window-over-window, OR when push-to-resolve score drops below its 80% target across the
  window. Cite the trend, not a single output.
- **Principal vs. junior:** Principal compares the window and flags the trajectory
  ("push-to-resolve 88% to 79% over 4 outputs"); junior reviews each output in isolation, passes
  each, and the drift compounds until an output finally fails hard.
- **Category:** OUT.
- **Threshold trigger:** **15-point or greater** drop OR **one or more severity-band** decline
  window-over-window in any rolling rigor metric; push-to-resolve **below 80%** across the
  window.
- **Current-status read:** "Quality-drift posture: push-to-resolve window trend
  <start-percent> to <end-percent> (target >= 80%); evidence-label density trend <delta>;
  gate-PASS-rate trend <delta>."
- **Surface:** Mode E roll-up.
- **Threshold owner/source:** push-to-resolve target 80% is owned by `pmo-qa-auditor/SKILL.md`
  Mode C scorecard; the 15-point band aligns to one severity-band step in the skill's
  Critical/Major/Minor model (10 points is within normal output-to-output variance, 20 too
  coarse for early warning). [SOURCE: SKILL.md Mode C 80% target + INFERRED 15pt band aligned to
  severity bands]

### FMD-5 — SPOF (single point of failure) — TRIG

- **Signature:** A capability, knowledge area, or decision authority is concentrated in a
  single skill, single named person, or single artifact across the reviewed set — the same one
  owner appears as the sole Responsible+Accountable for a capability cluster with no documented
  backup.
- **Conditional:** do NOT classify a capability as healthy when a single skill, person, or
  artifact is its sole point of failure with no documented backup, because SPOF concentration
  means the capability dies the day that one node is unavailable and the concentration is
  invisible until the node fails.
- **Root cause:** Concentration is efficient day-to-day (one expert is faster than a documented
  hand-off), so the backup/cross-training step is perpetually deferred; the risk is latent until
  realized.
- **Mitigation:** Enumerate capability-to-sole-owner edges across the reviewed set; flag any
  capability whose Responsible AND Accountable are the same single node in three or more contexts
  with no named backup (auto-elevate to a finding). Reuses the cross-artifact SPOF-elevation rule
  from pmo-technical-analyst (a SPOF named in 3+ contexts becomes a standalone RAID entry).
- **Principal vs. junior:** Principal enumerates the concentration and flags it as a SPOF finding
  with the backup-owner remediation; junior treats each single-owner mention as normal context
  and the SPOF persists into go-live (the exact pmo-technical-analyst failure mode).
- **Category:** TRIG.
- **Threshold trigger:** **same sole node across three or more contexts, 0 named backups** fires.
- **Current-status read:** "SPOF posture: <N> capabilities with a single sole-owner node across
  three or more contexts and no backup; nodes: <cite>."
- **Surface:** Mode E roll-up.
- **Threshold owner/source:** lifted verbatim from `pmo-technical-analyst/SKILL.md` ("SPOF in 3+
  contexts -> auto-elevate to a standalone RAID entry"). [SOURCE: pmo-technical-analyst/SKILL.md
  SPOF cross-artifact rule]

### FMD-6 — Breadth burnout — PROC

- **Signature:** Too many concurrent workstreams degrade depth — the reviewed set shows many
  parallel in-flight items each handled shallowly (thin outputs, deferred sub-steps, rising
  surfaced-not-resolved rate) consistent with attention spread past sustainable concurrency.
- **Conditional:** do NOT sustain concurrent active workstreams past the depth-degradation
  threshold when per-workstream output depth is observably falling (rising surfaced-not-resolved
  rate, thinning artifacts), because breadth burnout trades depth for breadth and the platform
  ships many shallow outputs instead of fewer principal-grade ones.
- **Root cause:** Adding a workstream is easier than finishing one; concurrency creep is
  invisible per-item (each looks fine in isolation) and only the aggregate depth-decline reveals
  it — the same blindness as quality drift, on the concurrency axis.
- **Mitigation:** Track concurrent-active-workstream count against per-workstream depth; flag
  when concurrency exceeds the documented ceiling AND push-to-resolve or depth metrics degrade
  concurrently (concurrency alone is not the failure — concurrency *with* depth-decline is).
  Surface the trade as a finding for operator re-prioritization.
- **Principal vs. junior:** Principal flags "concurrency N exceeds ceiling while push-to-resolve
  fell to <percent>" and recommends sequencing; junior keeps absorbing workstreams, each output
  thins, and depth collapses across the board.
- **Category:** PROC.
- **Threshold trigger:** **concurrent-active count above the documented ceiling** AND **15-point
  or greater** depth-metric decline window-over-window (conjunction required). The ceiling is
  operator-config (resolved at eval time, not canonicalized inline).
- **Current-status read:** "Breadth posture: <N> concurrent active workstreams (ceiling
  <config>); concurrent depth-metric trend <delta>; conjunction fired: yes/no."
- **Surface:** Mode E roll-up.
- **Threshold owner/source:** the depth-decline axis reuses D4's 15-point band; the absolute
  concurrency ceiling is operator/portfolio-specific and resolves from
  `platform-config.toml` `[failure_mode_detectors].concurrency_ceiling` (NOT canonicalized here).
  [SOURCE: D4 band reuse; ceiling routed to config]

### FMD-7 — AI hallucination — INPUT

- **Signature:** A reviewed output asserts a fabricated owner, date, metric, citation, or
  file/symbol that does not exist in any cited source — a confident claim with no verifiable
  backing (ties directly to the G4 evidence-quality gate and the platform "no fabricated owners,
  dates, metrics" guardrail).
- **Conditional:** do NOT pass an output asserting an owner, date, metric, or citation that
  cannot be traced to a cited source when the claim is load-bearing, because AI hallucination is
  fabricated owners/dates/metrics and an un-grounded load-bearing claim acted on as fact is the
  highest-consequence data-integrity failure.
- **Root cause:** Generative fluency produces plausible specifics to fill a gap; an
  invented-but-plausible date or owner reads as authoritative, and the verification-against-source
  step is the one most tempting to skip under output pressure.
- **Mitigation:** Spot-check every load-bearing [SOURCE]-labeled claim against its cited source
  when the source is in context; for any owner/date/metric with no cited source, render a
  hallucination finding (zero-tolerance — one ungrounded load-bearing specific fires). This is the
  runtime detector that operationalizes the G4 gate and the platform guardrail — D7 is the named
  detector, G4 is the per-output gate enforcement.
- **Principal vs. junior:** Principal traces the claim to source, finds the invented date, and
  renders FAIL with the source-check as evidence; junior accepts the confident specific and
  certifies a fabrication into a stakeholder output.
- **Category:** INPUT.
- **Threshold trigger:** **zero-tolerance — one ungrounded load-bearing owner/date/metric/citation**
  fires (per-output). Mode-E roll-up: **count per window**, trend flag if rising.
- **Current-status read:** "Hallucination posture: <N> ungrounded load-bearing specifics this
  window; per-output zero-tolerance; trend <delta>."
- **Surface:** both (Mode A per-output + Mode E roll-up).
- **Threshold owner/source:** CLAUDE.md guardrail ("No fabricated owners, dates, metrics") + the
  G4 evidence-quality gate; zero-tolerance is the existing guardrail posture, not a new threshold.
  [SOURCE: CLAUDE.md Guardrails + SKILL.md G4]

### FMD-8 — Trust erosion — HAND

- **Signature:** Accumulating unverified or walked-back claims across the reviewed set — a rising
  count of claims later contradicted/retracted, commitments missed, or "verified" assertions that
  did not hold — a confidence-decay trend at the hand-off boundary between the suite and the
  operator.
- **Conditional:** do NOT report platform trust as stable when the rolling count of
  unverified-or-walked-back claims is rising across the audit window, because trust erosion is
  accumulating unverified or walked-back claims and each retraction compounds the operator's
  discount on every future claim.
- **Root cause:** A single walk-back feels recoverable, so the cumulative pattern is
  under-weighted; trust is a slow-moving aggregate that no single retraction triggers an alarm on
  — the erosion is only visible in the running tally.
- **Mitigation:** Maintain a rolling tally of unverified-on-emission claims and
  walked-back/retracted claims across the window; flag when the walk-back rate rises
  window-over-window OR exceeds the documented rate; route persistent erosion to the operator at
  the hand-off boundary (this is a HAND-category escalation, not a silent metric).
- **Principal vs. junior:** Principal surfaces "walk-back rate rose <x> to <y> over the window" as
  an escalation and names the erosion explicitly; junior treats each retraction as an isolated
  correction and the operator quietly stops trusting the suite's claims.
- **Category:** HAND.
- **Threshold trigger:** **walk-back/retraction rate rising window-over-window** OR **above the
  documented rate**; a persistent rise escalates. The documented rate floor is operator-config
  (resolved at eval time).
- **Current-status read:** "Trust posture: <N> unverified-on-emission + <M> walked-back claims
  this window; walk-back rate trend <delta>; escalation fired: yes/no."
- **Surface:** Mode E roll-up.
- **Threshold owner/source:** composes with the platform "Verify before recommend" +
  "Audit-baseline discipline" rules (CLAUDE.md); the rolling-tally trend framing is consistent
  with D4/D6. The absolute rate floor resolves from `platform-config.toml`
  `[failure_mode_detectors].walk_back_rate_floor` (NOT canonicalized here). [SOURCE: CLAUDE.md
  Verify-before-recommend + Audit-baseline discipline; rate floor routed to config]

## RACI Validation Gate (G9) — data source

The **RACI validation gate (G9)** is a Mode A gate-class check (not a 9th detector).
RACI-ambiguity is a **per-output** property — this artifact has no clear owner — exactly
parallel to the SKILL.md-conditional G7 and the Stage-5-spec-conditional G8. G9 fires
per-output in Mode A; **D2 (Faceless PMO) is its Mode-E platform-trend roll-up**. The gate
namespace (per-output verdicts) and the detector namespace (platform trends) stay cleanly
separated.

- **Fires when:** the output under audit assigns, implies, or depends on **ownership of an
  action, decision, deliverable, or risk** (any output with action items, RAID entries,
  commitments, escalations, or a decision frame). Does **not** fire on pure-analysis outputs
  that assign no ownership (parallel to the G7/G8 conditional-fire — omission when no ownership
  is asserted is the correct non-ceremony signal).
- **Criterion:** every owned item has a **clear single Responsible AND a single Accountable** (a
  named person or role, not "the team" / "the PMO" / passive voice). Consulted and Informed are
  **not** gate-blocking — their absence is an OBSERVATION, not a FINDING. The gate's teeth are on
  **R and A** per the platform RACI convention ("single Accountable per gate").
- **Verdict:** **PASS** = every owned item has a single R and a single A. **FAIL** = one or more
  owned items with a missing or ambiguous R or A (no Accountable, multiple un-disambiguated
  Accountables, or a "the team"-class non-owner), with the exact item plus the suggested
  owner-line in the Remediation field. Binary — no PARTIAL, per the skill's Operating principles.
- **Threshold:** **one or more owned items lacking a single clear R or A renders FAIL.**
  (Zero-tolerance on owned items, consistent with the single-Accountable convention.)
- **Why R+A and not full RACI:** the platform convention is "single Accountable per gate type"
  — Accountable is the load-bearing role, Responsible is the doer. Consulted/Informed gaps are
  quality observations, not ownership-failure findings. Gating on R+A matches the established
  convention and avoids false-positive FAILs on outputs that legitimately omit Consulted/Informed.
- **Threshold owner/source:** `operations/skills/delivery-engine/references/gate-definitions.md`
  LG-2-EX-4 + `gate-checklists.md` (single Accountable per gate).

## Verdict / reporting (Mode E battery section format)

In **Mode E**, the battery produces a `## Failure-Mode Detector Battery` section in
`findings-register.md` — **one status line per detector**, listing the detector id and name,
its category, its current-status read, and its threshold. All 8 detectors appear every run
(an un-fired detector reports its clean/posture status; an un-evaluable axis reports
INDETERMINATE with the missing input named — never silently clean). Format:

```
## Failure-Mode Detector Battery

| Detector | Category | Current status | Threshold |
|---|---|---|---|
| D1 Automation complacency | PROC | <current-status read> | 1/5 sample; any sampled divergence |
| D2 Faceless PMO | OUT | <current-status read> | per-output: >=1 ownerless decision; roll-up >20% |
| D3 Echo chamber | INPUT | <current-status read> | 0 disconfirming/0 alternatives; streak >=3 |
| D4 Quality drift | OUT | <current-status read> | >=15pt or >=1 band decline; push-to-resolve <80% |
| D5 SPOF | TRIG | <current-status read> | sole node across >=3 contexts, 0 backups |
| D6 Breadth burnout | PROC | <current-status read> | concurrency > ceiling AND >=15pt depth decline |
| D7 AI hallucination | INPUT | <current-status read> | zero-tolerance: 1 ungrounded load-bearing specific |
| D8 Trust erosion | HAND | <current-status read> | walk-back rate rising w/o/w OR > documented rate |
```

The in-chat SUMMARY echo carries a one-line detector-battery status line (the count of
fired detectors plus the headline posture), pointing to the `findings-register.md` section.
The battery section is observational (it describes observed platform-trend state); the
issue-drafts it informs carry reversibility tiers per the Mode E output discipline.

## References

- `core/specs/failure-mode-standard.md` — the 8-to-taxonomy mapping (the category tags D1–D8
  lift) + the worked "Automation complacency" conversion (the D1 conditional) + the 5-field
  template these detectors are authored to.
- `operations/skills/pmo-technical-analyst/SKILL.md` — the SPOF "3+ contexts -> standalone RAID
  entry" rule (D5 threshold).
- `core/skills/eval-writer/references/failure-modes.md` — F-30 "round-over-round opinion
  divergence" (D3 signal + mitigation).
- `operations/skills/delivery-engine/references/gate-definitions.md` +
  `operations/skills/delivery-engine/references/gate-checklists.md` — "single Accountable per
  gate" (D2 + G9).
- `core/skills/pmo-qa-auditor/references/push-to-resolve-rubric.md` + this skill's Mode C
  scorecard — push-to-resolve 80% target (D4 floor).
- `core/skills/pmo-qa-auditor/references/watermelon-detection.md` — the structural model for a
  reference-by-role-name threshold-dependency note; the metric-registry role-names D4/D6/D8
  consume.
- `core/config/platform-config.toml.template` — the `[failure_mode_detectors]` section that owns
  the D6 concurrency ceiling and D8 walk-back rate floor (config-referenced; key-addition is a
  separate improvement when absent).
- The auditor consults this doc in Mode E (Platform Health Audit) and Mode A (Single Output
  Review, for the per-output detectors + the G9 gate) per the SKILL.md Reference Docs table.
