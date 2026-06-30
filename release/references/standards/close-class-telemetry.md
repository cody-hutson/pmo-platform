---
title: Close-Class Telemetry
purpose: K1 codified-knowledge standard defining the `Close-Class-Telemetry:` RELEASE_LOG H4 field — a mechanical read-model of how well a release CLOSED (retro-register canonical-form conformance, lessons-learned population, carry-forward closure, decision-rollup presence) measured at Stage 13 from filesystem registers + `gh` state, NOT the event log
type: standard
parallel_to: release-velocity-tracking.md (the mechanical-source sibling H4 field this standard mirrors — both compute from filesystem/`gh` state at Stage 13, NOT the event log; both follow the additive-H4-field placement, N/A discipline, grandfather policy, and failure-mode shape), deployment-cycle-time.md (the visible-H4 measurement-field precedent), deferred-item-tracking.md (the `status: deferred` closure-rate source this consumes)
reversibility: CHEAP (forward-only additive H4 field; pre-cutover releases lack the field and consumers treat as absent; the whole instrument reverts with one commit — no master-table schema change)
consumers: "release/references/pipeline/stage-13-close.md Phase B (capture surface — appended in the Stage 13 chore PR); release/governance/release-process.md Stage 13 § close-class-telemetry convention; release-planner Mode B (close-quality calibration); pmo-qa-auditor (close-out quality review); synthesize-release-learnings.sh (Indicator 4 cross-release pattern-emergence-rate — the POINTER target, computed there, not here)"
version: v1.00
---

<!-- reference-durability: allow-version-ref -->
# Close-Class Telemetry

## 1. Purpose

Close-class telemetry = a mechanical read-model of **how well a release closed** — the Stage 13 close-out ceremony's own quality signals, measured per release. Where deployment-cycle-time measures GO→deploy latency and release-velocity measures bundle throughput, this instrument measures the *closing* discipline: did the retro register conform to its canonical form, did the lessons-learned register get populated, did the carry-forward items actually close, and is the release-level decision rollup present.

Prior to this standard, none of these close-quality signals existed as a machine-readable field. The retro register, the lessons-learned register, and the carry-forward (`status: deferred`) items all existed as artifacts, but whether a given release produced them *in conforming form* was nowhere recorded — a release could close with an empty register or an unconformant retro and nothing surfaced it as a measured gap. This standard codifies the `Close-Class-Telemetry:` H4 field schema, its mechanical sources, its explicit-N/A semantics, and the deliberately-narrow indicator scope (anti-overfit — see § 2.1), so the close-quality signals are produced consistently per release and consumed deterministically by close-quality calibration (release-planner Mode B) and close-out review (pmo-qa-auditor).

**Scope:** per-release close-out quality, captured at Stage 13 close, derived from **mechanical sources** — the operator-instance retro/lessons registers (grep of canonical-form section markers + populated-row counts), the `gh` `status: deferred` label state over the milestone (carry-forward closure), and the release-level `Outcome:` field + Stage-13 A7.1 rollup (decision-rollup presence). The instrument reads filesystem registers and `gh` state — it does **NOT** read the pipeline-event-log (that is the disjoint surface owned by the cycle-time / DORA read-models; see § 8 boundary clause).

**Out of scope:** per-issue close quality (the field is release-level only); the cross-release pattern-emergence rate (Indicator 4 — computed by `synthesize-release-learnings.sh`, referenced here as a POINTER, never recomputed — see § 4 Indicator 4); a per-phase evidence-preservation ledger (Indicator 6 — no pipeline-wide evidence ledger exists; scoped to the single Stage-13 close-gate boolean and otherwise N/A-until-source-exists — see § 4 Indicator 6); deployment latency / bundle throughput (the disjoint sibling fields).

### 1.1 The anti-overfit posture (load-bearing)

This standard deliberately ships **fewer fully-built indicators than the close-out ceremony could theoretically expose.** Six indicators were considered; they are NOT all built as rates, because building a rate whose denominator is undefined, or whose source does not yet exist, manufactures a precise-looking number with no real signal (the same synthesized-data-biases-baseline trap release-velocity-tracking.md names). The scope is therefore tiered:

| Indicator | Disposition | Why |
|---|---|---|
| 1 `retro_register_canonical_form_conformance_rate` | **BUILD (read-model)** | The retro register has verbatim canonical-form section markers (the Kerth + PMBOK 7 headers); conformance is a real grep-able ratio. |
| 2 `lessons_learned_register_population_rate` | **BUILD (read-model)** | The lessons/actions tables are template-prompted rows; populated ÷ prompted is a real ratio. |
| 3 `carry_forward_closure_rate` | **BUILD (read-model)** | `status: deferred` label state over the milestone is a real `gh`-queryable closure ratio. |
| 4 `cross_release_pattern_emergence_rate` | **POINTER ONLY** | Already computed by `synthesize-release-learnings.sh` (qualifying-clusters ÷ events-in-window). Reference it; never recompute it. |
| 5 `decision_record_release_level_rollup_rate` | **NARROWED — presence/coverage, NOT a rate** | The denominator (how many decisions *should* roll up) is undefined release-to-release; ship rollup PRESENCE (is the `Outcome:` field + A7.1 rollup present?), DEFER the rate. |
| 6 `phase_completion_evidence_preservation_rate` | **N/A-ONLY / DEFERRED** | No pipeline-wide evidence ledger exists. Scope to the single Stage-13 close-gate (G-CL4) boolean; mark the broader per-phase reading N/A-until-source-exists. Build no per-phase machinery. |

The discipline: **measure what has a real, mechanical denominator; pointer to what is already measured; explicitly defer what has no source yet.** A deferred indicator is recorded as deferred (with its blocking reason), never silently dropped and never faked with a synthetic denominator.

## 2. What is measured

The `**Close-Class-Telemetry:**` field carries the three built indicators, the Indicator-4 pointer, the Indicator-5 presence flag, and the Indicator-6 close-gate boolean, plus a producing-tool marker:

| Sub-signal | Indicator | Source | Format | Notes |
|---|---|---|---|---|
| **retro-conformance** | 1 | grep of the canonical-form section markers in the operator-instance retro register for the version (the verbatim Kerth + PMBOK 7 headers from [`release-learnings-register-template.md`](../templates/release-learnings-register-template.md)) | `<present>/<expected> (<ratio>)` | conformant markers present ÷ expected canonical-form markers. The template's section headers are kept verbatim precisely so consumers can grep them (the template says so). |
| **lessons-population** | 2 | populated lessons/actions rows ÷ template-prompted rows in the lessons-learned register | `<populated>/<prompted> (<ratio>)` | A template-prompted row left as the `<…>` placeholder is unpopulated; a row with real content is populated. |
| **carry-forward-closure** | 3 | `gh` `status: deferred` label state over the release milestone — deferred items that have since closed ÷ total deferred items raised by/at this release's close | `<closed>/<raised> (<ratio>)` | Sources the `status: deferred` label per [`deferred-item-tracking.md`](deferred-item-tracking.md). N/A when this release raised zero carry-forward items. |
| **pattern-emergence** | 4 | **POINTER** to `synthesize-release-learnings.sh --mode aggregate` | `deferred-to-aggregate (see synthesize-release-learnings.sh)` | NOT recomputed here — the field carries the pointer; the rate lives at the synthesizer (§ 4 Indicator 4). |
| **rollup-presence** | 5 | presence of the release-level `Outcome:` field (per [`decision-outcome-tracking.md`](decision-outcome-tracking.md)) + the Stage-13 A7.1 recommendation↔choice rollup | `present` / `absent` (presence, NOT a rate) | The rate is DEFERRED (denominator undefined). Presence answers "did the release record its decision rollup at all?" |
| **evidence-close-gate** | 6 | the single Stage-13 close-gate G-CL4 ("verification evidence persisted") boolean | `pass` / `fail` / `N/A` (single gate, NOT a per-phase rate) | The broader per-phase evidence-preservation reading is `N/A-until-source-exists` — no pipeline-wide evidence ledger to measure against. |
| **mechanism** | — | literal `compute-close-class-telemetry.sh` | suffix | Discoverability marker, mirroring the velocity field's `mechanism:` convention. |

## 3. Unit / Format

### 3.1 Rates (round-half-up, taken by reference)

The three built indicators are 2-decimal ratios, rounded **round-half-up** at the second decimal — taken **by reference** from the single definitional home at `bundle-composition-doctrine.md § 3 Step 5 Risk-Weighting` (the same canonical mode release-velocity-tracking.md § 3.2 takes by reference), so a producer and an enforcer cannot disagree at a half-integer boundary. This standard does NOT re-derive the mode; the producing tool implements that one canonical mode.

### 3.2 Field name + RELEASE_LOG surface

- **Field name:** `**Close-Class-Telemetry:**` — TitleCase-bold, matching the established visible-H4 sibling-field convention (`**Cycle-Time:**`, `**Velocity:**`, `**Result:**`, `**Outcome:**`).
- **Placement:** inside the visible-H4 `#### Deployment Log v<X.Y>` block, as a sibling structured field — NOT a main-table column. The master-table schema is untouched. This follows the additive-H4-field placement precedent the platform has validated for the cycle-time, velocity, and outcome fields (a main-table column was explicitly rejected as high-cost main-table churn).
- **Field position:** after `**Velocity:**` and the `**Outcome:**` fields — close-class telemetry is the close-quality summary, read last after the deploy-latency / throughput / outcome fields. The field-ordering convention extends to `… Cycle-Time → Velocity → Result → Outcome → Outcome rationale → Close-Class-Telemetry`.

**Default emit (non-N/A):**

```markdown
**Close-Class-Telemetry:** retro-conformance <Pc>/<Ec> (<ratio>); lessons-population <Pl>/<Tl> (<ratio>); carry-forward-closure <Cf>/<Rf> (<ratio>); pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence <present|absent>; evidence-close-gate <pass|fail|N/A>; mechanism: compute-close-class-telemetry.sh
```

Worked example (a release whose retro fully conformed — all 10 canonical-form markers present — with 8/10 lessons rows populated, 2/3 carry-forwards since closed, rollup present, close-gate passed):

```markdown
**Close-Class-Telemetry:** retro-conformance 10/10 (1.00); lessons-population 8/10 (0.80); carry-forward-closure 2/3 (0.67); pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence present; evidence-close-gate pass; mechanism: compute-close-class-telemetry.sh
```

**N/A emit (a release that authored no retro register and raised no carry-forwards):**

```markdown
**Close-Class-Telemetry:** retro-conformance N/A — no retro register found for v<X.Y>; lessons-population N/A — no lessons register found; carry-forward-closure N/A — no carry-forward items raised; pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence <present|absent>; evidence-close-gate <pass|fail|N/A>; mechanism: compute-close-class-telemetry.sh
```

Emit mechanism: the Stage 13 spoke invokes `compute-close-class-telemetry.sh <version> --milestone <N>` at the Stage 13 chore PR and embeds the returned value into the visible-H4 block. Per the chore-PR convention the field lands on main via the Stage 13 chore PR, never direct-to-main.

## 4. The six indicators (definitions + the anti-overfit dispositions)

### Indicator 1 — `retro_register_canonical_form_conformance_rate` (BUILD)

**Definition:** of the canonical-form section markers the retro register is supposed to carry, what fraction are present and conformant. **Source:** grep the operator-instance retro register for the version against the canonical-form section markers — the verbatim headers from [`release-learnings-register-template.md`](../templates/release-learnings-register-template.md): the Kerth block (`## 1. Kerth Retrospective`, `### 1.1 Prime Directive`, `### 1.2 Three-question framework`, `### 1.3 Ritual of closure`), the PMBOK 7 block (`## 2. PMBOK 7 Lessons-Learned`, `### 2.1 Situation`, `### 2.2 Outcome`, `### 2.3 Lessons`, `### 2.4 Next-cycle Actions`), and the `## 3. Triple Linkage` block. The template mandates these headers be kept verbatim precisely so audits/consumers can grep them. **Rate:** conformant-markers-present ÷ expected-markers. **N/A:** when no retro register exists for the version (`N/A — no retro register found`).

### Indicator 2 — `lessons_learned_register_population_rate` (BUILD)

**Definition:** of the template-prompted lessons/actions rows, what fraction carry real content (vs an unfilled `<…>` placeholder). **Source:** the lessons-learned register's `### 2.3 Lessons` table (`| L1 | … |` rows) and `### 2.4 Next-cycle Actions` table (`| A1 | … |` rows) — the rows the template prompts. A row whose content cells are still the `<…>` placeholder is unpopulated; a row with real content is populated. **Rate:** populated-rows ÷ template-prompted-rows. **N/A:** when no lessons register exists, or it prompts zero rows.

### Indicator 3 — `carry_forward_closure_rate` (BUILD)

**Definition:** of the carry-forward items this release raised at close, what fraction have since closed. **Source:** the `gh` `status: deferred` label per [`deferred-item-tracking.md`](deferred-item-tracking.md) — enumerate the issues this release's close labelled `status: deferred` (de-milestoned, left OPEN per the Stage 13 Phase A2 procedure), then check how many are now CLOSED. **Rate:** closed-deferred ÷ raised-deferred. **N/A:** when this release raised zero carry-forward items (`N/A — no carry-forward items raised`) — a clean close with nothing deferred is N/A, not a 0/0 rate.

### Indicator 4 — `cross_release_pattern_emergence_rate` (POINTER ONLY)

**Definition:** the rate at which recurring cross-release patterns emerge (qualifying clusters ÷ events-in-window). **Disposition:** this is **NOT computed by this instrument.** It is computed by [`synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) (which already owns the trailing-window + cluster machinery), surfaced via its aggregate/rate output. The `Close-Class-Telemetry:` field carries a literal **pointer** (`pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh)`), never a recomputed value. **Why pointer, not recompute:** the synthesizer already computes qualifying-clusters and events-in-window from the event stream; recomputing them here would duplicate the window/cluster logic and risk a producer/producer disagreement. Single source of the rate; this field references it by role.

### Indicator 5 — `decision_record_release_level_rollup_rate` (NARROWED → presence, rate DEFERRED)

**Definition (as scoped):** is the release-level decision rollup PRESENT — the `Outcome:` field (per [`decision-outcome-tracking.md`](decision-outcome-tracking.md)) plus the Stage-13 A7.1 recommendation↔choice delta rollup. **Disposition:** ship **presence/coverage**, **DEFER the rate.** The rate's denominator — "how many decisions *should* roll up to the release level" — is undefined release-to-release (a release may make zero, one, or many roll-up-worthy decisions, with no canonical count), so a rate would have a manufactured denominator. Presence is real and mechanical: the `Outcome:` field either is or is not in the RELEASE_LOG block, and the A7.1 rollup either did or did not run. **Documented as presence-not-rate:** the field emits `rollup-presence present|absent`, NOT a ratio. The rate is explicitly deferred until a canonical roll-up-worthy-decision denominator exists (it does not today).

### Indicator 6 — `phase_completion_evidence_preservation_rate` (N/A-ONLY / DEFERRED)

**Definition (as scoped):** the fraction of pipeline phases whose completion evidence was preserved. **Disposition:** **N/A-only / deferred.** No pipeline-wide evidence ledger exists — there is no per-phase evidence store to measure a preservation rate against. Building per-phase machinery to manufacture one is explicitly out of scope. The instrument therefore scopes Indicator 6 to the **single Stage-13 close-gate boolean** — G-CL4 ("verification evidence persisted") per [`stage-13-close.md`](../pipeline/stage-13-close.md) § 7 — emitting `evidence-close-gate pass|fail|N/A`. The broader per-phase reading is marked **N/A-until-source-exists** and documented as deferred (its blocking reason: no pipeline-wide evidence ledger). Do NOT build per-phase evidence machinery to fill this; record the deferral.

## 5. N/A semantics (per-indicator, independent)

Each indicator resolves its own N/A independently — a release can yield a real value for some indicators and N/A for others. N/A is never blank-fill; it carries a parenthetical reason.

| Indicator | N/A condition |
|---|---|
| 1 retro-conformance | no retro register found for the version → `N/A — no retro register found for v<X.Y>` |
| 2 lessons-population | no lessons register found, or zero template-prompted rows → `N/A — no lessons register found` |
| 3 carry-forward-closure | this release raised zero carry-forward (`status: deferred`) items → `N/A — no carry-forward items raised` (a clean close, NOT a 0/0 rate) |
| 4 pattern-emergence | always the pointer (`deferred-to-aggregate`) — not an N/A, a structural deferral to the synthesizer |
| 5 rollup-presence | not a rate — emits `present`/`absent`; the RATE is deferred (denominator undefined), documented as presence-not-rate |
| 6 evidence-close-gate | the G-CL4 gate did not run / is unreadable → `N/A`; the per-phase reading is `N/A-until-source-exists` (no ledger) |

**Explicit-N/A discipline:** every indicator slot in the field is present with a value, an `N/A (reason)`, a pointer (Indicator 4), or a presence flag (Indicator 5). A missing slot is a tool defect, not a silent N/A. A release either carries the full field (post-cutover) or carries no field at all (pre-cutover, grandfathered) — never a partial field with a slot dropped.

**Why N/A and not zero:** a release with no retro register genuinely has no conformance to measure; recording it as `0.00` would crush any close-quality calibration the same way a synthesized velocity ratio biases the capacity weights. The calibration population counts only non-N/A indicator values.

## 6. Domain alignment (release close-out discipline)

This instrument is the measurement layer for the platform's **close-out discipline** — the Stage 13 Kerth-retrospective + PMBOK-7 lessons-learned ceremony (`stage-13-close.md` § 6 Outputs). It makes the ceremony's quality *measurable*: a retro that was run but left half its canonical sections empty, a lessons register that was created but never populated, carry-forwards that were raised but never closed — each is now a surfaced ratio rather than an unmeasured gap. The instrument does NOT change the ceremony or the templates; it reads their output. The retro/lessons templates keep their section headers verbatim (the template mandates this) precisely so this read-model can grep them — the measurement contract and the template are co-designed, zero duplication.

## 7. Computation tool

Reference implementation: [`release/tools/compute-close-class-telemetry.sh`](../../tools/compute-close-class-telemetry.sh).

**Form factor:** a thin wrapper mirroring the `compute-release-velocity.sh` form factor and exit-code contract — stdlib-only (`/usr/bin/python3`), PATH pinned to system tools, a built-in `--self-test`, and a `--json` detail mode. It sources from **mechanical surfaces** (filesystem registers + `gh` state), NOT the event log: (a) the retro register file (grep canonical-form markers), (b) the lessons register file (count populated vs prompted rows), (c) `gh issue list --label "status: deferred"` over the milestone (carry-forward closure), (d) the RELEASE_LOG `Outcome:` field + A7.1 rollup presence (Indicator 5), (e) the G-CL4 close-gate boolean (Indicator 6). Indicator 4 is emitted as the `deferred-to-aggregate` pointer string — the tool never recomputes it.

**CLI:**

```bash
./compute-close-class-telemetry.sh <version> --milestone <N> [--retro <path>] [--lessons <path>]   # the field value
./compute-close-class-telemetry.sh <version> --milestone <N> --json                                # JSON of all indicators
./compute-close-class-telemetry.sh --self-test                                                     # validate logic, no network
```

**Exit codes:**
- `0` — success (an indicator may legitimately produce N/A — no register, no carry-forwards; or the Indicator-4 pointer / Indicator-5 presence / Indicator-6 boolean)
- `1` — invalid args / required input missing / `gh` unavailable when carry-forward closure is requested
- `2` — malformed source (a register that exists but cannot be parsed, or a milestone that does not resolve — source-integrity violation; escalate)

**Manual-fill fallback:** if the tool cannot run at capture time (e.g. `gh` unavailable in the close worktree), the Stage 13 spoke MAY compute the indicators by hand from the registers + milestone state and embed them — exactly as the velocity and cycle-time fields degrade gracefully to manual N/A during an instrumentation gap. The field and the convention bind either way.

## 8. Boundary statement (mechanical-source, NOT the event log)

Close-class telemetry sources from **filesystem registers + `gh` state**, NOT the pipeline-event-log. This is the deliberate boundary that distinguishes it from the event-log read-models (deployment-cycle-time, DORA): those answer "what happened in the pipeline event stream"; this answers "what close-out artifacts did the release produce, and in what conforming form". The retro/lessons registers are operator-instance markdown files; the carry-forward state is `gh` label state; the rollup presence and close-gate are RELEASE_LOG / gate surfaces. None of these is an event-log read — the event log is untouched by this instrument. (Indicator 4's pattern-emergence rate IS an event-log read-model, which is exactly why it is delegated to `synthesize-release-learnings.sh` and only pointed-to here, never computed here.)

## 9. Cutover / grandfather

**GRANDFATHER. No backfill.** Pre-cutover Deployment Log blocks carry **no** `**Close-Class-Telemetry:**` field. The field is present going-forward only, on releases entering Stage 13 strictly AFTER this field's introducing-release merge SHA. **The introducing release itself is exempt** (reflexive-pipeline-loop discipline — a release shipping the close-class convention does not retroactively self-instrument). Pre-cutover rows carry no field (no backfill) — reconstructing whether a historical release's retro conformed or its carry-forwards closed is unreliable (registers may have been authored post-hoc, deferred items re-triaged across the version lineage), so a backfilled value would be synthesized, not measured. The calibration population counts only non-N/A post-cutover fields, so grandfathered rows are simply absent.

## 10. Parser-safety invariant

The `**Close-Class-Telemetry:**` field lives in the `#### Deployment Log v<X.Y>` visible-H4 block, NOT in the master table. Every RELEASE_LOG row-parser anchors exclusively on master-table rows beginning with a pipe (`^| v<X.Y>`); a line beginning `**Close-Class-Telemetry:**` does not start with `|`, so it matches none of those anchors and shifts no positional field index. No row-parser change and no deploy-check change is required; the master-table schema is untouched. The sibling `**Cycle-Time:**`, `**Velocity:**`, and `**Outcome:**` fields have co-resided in the same block across the full release history with all row-parsers green — `**Close-Class-Telemetry:**` is the next sibling in a proven-safe container.

## 11. Consumers

| Consumer | Role |
|---|---|
| `release/references/pipeline/stage-13-close.md` Phase B | Capture surface — the Stage 13 chore PR embeds the `**Close-Class-Telemetry:**` field (via the tool, or manual-fill) in the same commit that transitions the row `DEPLOYED → VERIFIED` and adds `**Outcome:**` / `**Velocity:**` |
| `release/governance/release-process.md` Stage 13 | Documents the close-class-telemetry convention (what is captured, when, how) — cites this standard by role; does NOT restate the field anatomy |
| `release-planner` Mode B (durable release plan authoring) | Reads close-quality data for calibration once the population establishes |
| `pmo-qa-auditor` (close-out quality review) | Reads the indicators as close-out quality signals in a review |
| `synthesize-release-learnings.sh` | Owns Indicator 4 (cross-release pattern-emergence rate) — this field POINTS to it (`deferred-to-aggregate`), never recomputes it |
| `automated-closeout.sh` (RELEASE_LOG row-parser) | Invariant against this field — its row-parsers anchor on master-table rows (`^| v<X.Y>`); the `**Close-Class-Telemetry:**` H4 field line is structurally invisible to them (§ 10) |

## 12. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **PROC** | Manufacturing a rate for a deferred indicator | When emitting Indicator 5 (decision rollup) or Indicator 6 (phase evidence), do NOT synthesize a denominator to produce a rate — emit the presence flag (I5) or the single-gate boolean (I6), with the deferral documented | The denominator does not exist: "how many decisions SHOULD roll up" (I5) and "how many phases have a preserved-evidence ledger" (I6) have no canonical count. Inventing one (e.g., "count the D-decisions in the plan") produces a precise-looking ratio with no real signal and biases any calibration that reads it | This standard § 1.1 + § 4 ship I5 as presence-not-rate and I6 as a single-gate boolean N/A-until-source-exists; the producing tool emits `rollup-presence present|absent` and `evidence-close-gate pass|fail|N/A`, never a ratio | Principal: emits the presence flag / boolean and records the rate as deferred with its blocking reason. Junior: counts plan D-decisions as the I5 denominator → publishes a "0.67 rollup rate" that conflates plan decisions with roll-up-worthy decisions → calibration reads a fabricated signal |
| FM2 | **PROC** | Recomputing the Indicator-4 pattern-emergence rate inline | When populating the Indicator-4 slot, do NOT re-implement the trailing-window + cluster computation — emit the `deferred-to-aggregate` pointer; the rate is owned by `synthesize-release-learnings.sh` | The synthesizer already computes qualifying-clusters ÷ events-in-window from the event stream. Recomputing here duplicates the window/cluster machinery and creates a producer/producer disagreement (two tools, two slightly-different cluster definitions, two different rates for the same window) | This standard § 4 Indicator 4 + § 8 fix I4 as a POINTER; the producing tool emits the literal pointer string and has no window/cluster code | Principal: emits `pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh)` and lets the synthesizer own the rate. Junior: re-implements a cluster scan in this tool → its rate diverges from the synthesizer's on the same data → two contradictory pattern-emergence numbers in the corpus |
| FM3 | **INPUT** | Counting an N/A register as a zero rate | When a release authored no retro / lessons register, or raised zero carry-forwards, do NOT record `0.00` — emit `N/A (reason)`; N/A is excluded from the calibration population | Convenience collapse: "no register, so 0% conformance". But 0.00 means "register present, fully unconformant" (a real bad-close SIGNAL); N/A means "no register to measure" (no population). Recording N/A as zero fabricates a bad-close signal and biases close-quality calibration toward false-negative health | This standard § 5 records each indicator's N/A explicitly (not blank, not zero) with a parenthetical reason; the producing tool emits the N/A field and exit 0; the calibration counts only non-N/A values | Principal: emits `retro-conformance N/A — no retro register found` when the register is absent; `0/9 (0.00)` ONLY when the register exists but conforms to nothing. Junior: reports 0.00 for an absent register → an un-instrumented close reads as "worst-possible close quality", masking that nothing was measured |
| FM4 | **OUT** | Committing the close-class field direct-to-main, or at Stage 12 | When adding the `**Close-Class-Telemetry:**` field, do NOT commit the visible-H4 edit directly to main, and do NOT emit it at Stage 12 — it lands via the Stage 13 chore PR | Direct-to-main is prohibited regardless of edit size (the git-workflow "What NOT To Do" rule does not exempt metadata edits); and the close-quality indicators are not authoritative until Stage 13 produces the registers, closes the carry-forwards, and runs the close-gate — a Stage-12 emit would record premature (often empty) values | This standard § 3.2 + § 11 land the field at the Stage 13 chore PR (same commit as `DEPLOYED → VERIFIED` and the `**Outcome:**`/`**Velocity:**` fields) | Principal: appends the field in the Stage 13 chore PR after the registers/carry-forwards/close-gate exist. Junior: emits close-class telemetry at Stage 12 with empty registers → records `N/A` everywhere or a premature 0.00 → the close-quality record is misleading |

## 13. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Mechanical-source sibling field | `release-velocity-tracking.md` | The sibling H4 field this standard mirrors — both compute from filesystem/`gh` state at Stage 13 (NOT the event log); shared section structure, N/A discipline, grandfather policy, failure-mode shape |
| Visible-H4 field precedent | `deployment-cycle-time.md` | The first visible-H4 measurement field; the additive-not-main-table placement precedent |
| Retro/lessons template (Indicators 1+2 source) | [`release-learnings-register-template.md`](../templates/release-learnings-register-template.md) | The verbatim canonical-form section markers (Indicator 1) and template-prompted rows (Indicator 2) this read-model greps |
| Carry-forward closure (Indicator 3 source) | [`deferred-item-tracking.md`](deferred-item-tracking.md) | The `status: deferred` label state this indicator reads for closure-rate |
| Pattern-emergence rate (Indicator 4 owner) | [`synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) | Owns the cross-release pattern-emergence rate; this field POINTS to it (`deferred-to-aggregate`), never recomputes it |
| Rollup presence (Indicator 5 source) | [`decision-outcome-tracking.md`](decision-outcome-tracking.md) | The release-level `Outcome:` field whose presence (with the Stage-13 A7.1 rollup) Indicator 5 records |
| Evidence close-gate (Indicator 6 source) | [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) § 7 | The G-CL4 "verification evidence persisted" close-gate Indicator 6 scopes to (single boolean; per-phase reading N/A-until-source-exists) |
| Point scale rounding mode | `bundle-composition-doctrine.md § 3 Step 5` | Owns the round-half-up definitional home (taken by reference; § 3.1) |
| Capture surface | [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) Phase B | Where the field is embedded (Stage 13 chore PR) |
| Convention documentation | `release/governance/release-process.md` Stage 13 | Documents what/when/how the field is captured |
| Compute wrapper | [`compute-close-class-telemetry.sh`](../../tools/compute-close-class-telemetry.sh) | Reference implementation of § 4 indicator computation + § 3 format selection |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at the standards set |

## Version History

Tracked in git history.
