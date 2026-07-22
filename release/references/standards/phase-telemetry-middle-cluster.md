---
title: Phase-Distinctive Telemetry — Middle Cluster (Verify / Authorize)
purpose: K1 codified-knowledge standard defining the middle-cluster phase-distinctive quality-attribute telemetry read-models — how well built work is "sound coming OUT" across Verify (Stages 7-8) and Authorize (Stage 9) — computed as an on-demand window read-model over EXISTING pipeline-event-log subtypes, NOT a new event schema and NOT the calibration-data.md surface
type: standard
parallel_to: dora-telemetry.md (the on-demand window read-model whose §3.1 surfacing model + N/A discipline + read-model-only OUT boundary this standard adopts verbatim), close-class-telemetry.md (the 4-way anti-overfit disposition template — BUILD / POINTER / NARROWED / DEFER — this standard applies per indicator), phase-telemetry-front-cluster.md (the sibling cluster — Demand + Definition + Solution-design — split from this one on the pipeline-temporal cluster axis; identical anatomy, disjoint phase surface)
reversibility: CHEAP (forward-only additive read-model; pre-cutover windows excluded; computes lazily from existing events; no event-log schema change, no master-table change — the whole instrument reverts with one commit; the cluster split re-merges to one file if fragmentation ever bites)
consumers: "release-planner Mode B (middle-cluster quality calibration once a window establishes); pmo-qa-auditor (phase-quality review — Verify handoff-fidelity, Authorize decision-quality); release/references/standards/phase-telemetry-front-cluster.md (sibling cluster, shared anatomy)"
version: v1.00
---

<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->

# Phase-Distinctive Telemetry — Middle Cluster (Verify / Authorize)

## 1. Purpose

Middle-cluster telemetry = a set of mechanical read-models of **how well built work is "sound coming OUT"** of the pipeline — the quality-attribute signals distinctive to the pipeline's verify-and-authorize phase-classes:

- **Verify** (Stages 7-8) — *handoff fidelity*: how deep the composed dev-test / QA loop runs, and whether defects escape dev-test into QA.
- **Authorize** (Stage 9) — *convergent-gate decision quality*: whether the plan-review gate triggers exception paths, and whether its decision record is present.

Prior to this standard, the platform shipped the Build+Deploy telemetry layer (DORA-4, [`dora-telemetry.md`](dora-telemetry.md)) and the Close-class layer ([`close-class-telemetry.md`](close-class-telemetry.md)), but the **phase-distinctive observability** columns for the verify-and-authorize phase-classes — named in the v11.01 audit finding F-Release-1 and deferred when the DORA slice was scoped to its four-metric anchor — had no machine-readable instantiation. The underlying signals already exist in the pipeline-event-log (dev-test / QA iteration rows, dev-test verdicts, QA rejections, plan-review gate-outcomes, Stage-9 escalations) — but no read-model composed them into the middle-cluster frame. This standard codifies the middle-cluster indicators' definitions, their EXISTING event sources (zero new event types), their computation, their explicit per-indicator N/A semantics, and the on-demand window surface, so the middle-cluster signals are produced consistently and consumed deterministically by middle-cluster calibration (release-planner Mode B) and phase-quality review (pmo-qa-auditor).

**Scope:** the 11 candidate middle-cluster indicators, anti-overfit-dispositioned (§ 1.1 / § 4), computed over a bounded version window from EXISTING pipeline-event-log subtypes (`iteration/{dt-eng-pass-N, qa-dt-pass-N}`, `gate-outcome/{dt-pass, dt-conditional-pass, dt-return, qa-rejection, plan-review-go, plan-review-no-go}`, `escalation/*`). Read-model only — the computation reads the event stream; it NEVER emits a row back into it.

**Out of scope:** the Demand + Definition + Solution-design phase-classes (the sibling cluster — [`phase-telemetry-front-cluster.md`](phase-telemetry-front-cluster.md)); the DORA-4 build+deploy metrics and the close-class close-quality metrics (the disjoint sibling instruments); any indicator whose present data source does not exist — deferred per § 4, never given bespoke machinery; **the pipeline-event-log schema itself** — this standard is a schema READER (CIAC-1), it defines no event subtype and writes no schema.

### 1.1 The anti-overfit posture (load-bearing)

This standard deliberately ships **fewer fully-built indicators than the verify-and-authorize phases could theoretically expose.** Eleven indicators were considered; they are NOT all built as rates, because building a rate whose denominator is undefined, or whose source does not yet exist, manufactures a precise-looking number with no real signal (the synthesized-data-biases-calibration trap [`close-class-telemetry.md § 1.1`](close-class-telemetry.md) names). The scope is therefore tiered exactly as close-class tiered its six:

| Disposition | Meaning | Count (middle) |
|---|---|---|
| **BUILD** | a real mechanical denominator over an existing signal → computed as a rate / mean | 4 |
| **POINTER** | already computed elsewhere → reference it by role, never recompute | 1 |
| **NARROWED** | presence is mechanical, but the quality *rate*'s denominator is undefined → emit presence, defer the rate | 1 |
| **DEFER** | no present mechanical source → N/A-until-source-exists, build no bespoke machinery | 5 |

The middle cluster is the more DEFER-heavy of the two (5 of 11) — the verify-and-authorize signals lean on structured payload fields (handoff-conformance, lane, ambiguity, decision-vocabulary) that the current 10-column event schema does not carry. This is the anti-overfit posture working as designed: rather than invent a semantic scanner for each, the standard defers them with their blocking reasons (§ 4.1) and builds only the 4 with a real mechanical denominator. The discipline: **measure what has a real, mechanical denominator; pointer to what is already measured; narrow to presence what has no principled rate; explicitly defer what has no source yet.**

## 2. What is measured

The middle-cluster read-model carries the four BUILD indicators, the one POINTER, the one NARROWED presence, and the five DEFER records, plus a producing-tool marker. The BUILD rates are 2-decimal ratios (§ 3.1); the composed-loop depth is a 2-decimal mean.

| # | Phase | Indicator | Disposition | Source (existing) | Format |
|---|---|---|---|---|---|
| 16 | Verify | `forward-handoff-payload-conformance` | **DEFER** | no payload-conformance event in the 10-column schema | `N/A — deferred (reason)` |
| 17 | Verify | `lane-2-through-dt` | **DEFER** | no "lane" field in the event schema | `N/A — deferred (reason)` |
| 18 | Verify | `composed-loop-iteration-depth` | **BUILD** (mean) | event-log: mean over subjects of the count of `iteration/{dt-eng-pass-N, qa-dt-pass-N}` rows | `<mean> mean passes over <N> issue(s)` |
| 19 | Verify | `escape-rate` | **BUILD** | event-log: subjects with `gate-outcome/dt-pass` then a later `gate-outcome/qa-rejection` ÷ dt-pass subjects | `<n>/<d> (<ratio>)` |
| 20 | Verify | `ambiguous-ac` | **DEFER** | verdict enum is MET/NOT-MET/PARTIAL — no ambiguity value (PARTIAL ≠ ambiguous) | `N/A — deferred (reason)` |
| 21 | Verify | `conditional-accept-rate` | **BUILD** | event-log: `gate-outcome/dt-conditional-pass` rows ÷ all dev-test verdict rows (dt-pass + dt-conditional-pass + dt-return) | `<n>/<d> (<ratio>)` |
| 22 | Authorize | `decision-record-conformance` | **NARROWED** | event-log: presence of a `gate-outcome/plan-review-{go,no-go}` record (+ G-PR6); deep conformance is qualitative | `presence <present/absent>` |
| 23 | Authorize | `vocabulary-distinguishing` | **DEFER** | semantic analysis of decision-record vocabulary — no structured field | `N/A — deferred (reason)` |
| 24 | Authorize | `exception-plan-trigger-rate` | **BUILD** | event-log: plan-reviews resulting in a `plan-review-no-go` OR a Stage-9 `escalation/*` ÷ plan-reviews | `<n>/<d> (<ratio>)` |
| 25 | Authorize | `decision-outcome-correlation` | **POINTER** | [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) `--event-subtype recommendation-choice-delta --window N` look-back | pointer string |
| 26 | Authorize | `phase-b-3-tier-presentation` | **DEFER** | structural/text property of the briefing, not an event | `N/A — deferred (reason)` |
| — | — | `mechanism` | — | literal `compute-middle-cluster-telemetry.sh` | suffix |

## 3. Unit / Format

### 3.1 Rates + mean (round-half-up, taken by reference)

The BUILD rate indicators are 2-decimal ratios, rounded **round-half-up** at the second decimal — taken **by reference** from the single definitional home at [`bundle-composition-doctrine.md § 3 Step 5`](bundle-composition-doctrine.md) (the same canonical mode the DORA and close-class siblings take by reference). The composed-loop-iteration-depth is a 2-decimal **mean** (rounded the same way) — a per-issue loop-depth average, not a 0-1 rate (a loop depth has no 0-1 ceiling). This standard does NOT re-derive the rounding mode; the producing tool implements that one canonical mode.

### 3.2 Surface — on-demand window read-model (adopts dora-telemetry.md § 3.1)

Middle-cluster telemetry is a **window read-model, not a per-release visible-H4 field, and NOT a `calibration-data.md` row.** Per-phase populations only signal over a window of multiple items (a single release verifies / authorizes too few items for a rate to mean anything). The indicators are computed **on demand over a window** by the computation tool (§ 7) and surfaced where a window read-model belongs — a release-planner quality-calibration read, a pmo-qa-auditor phase-quality assessment — **NOT** appended to any single release's RELEASE_LOG row and **NOT** written into `calibration-data.md` (which is a boundary-keyed, dimension-agnostic gate-outcome surface per [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) § Versioning, the v1.2 "**Calibration:**" bullet — it structurally cannot host named per-phase read-models).

**This is the load-bearing OUT-class boundary:** the read-model reads the event log; it NEVER writes a middle-cluster row back into `pipeline-event-log.md` (§ 12 FM3). A middle-cluster metric is a FUNCTION of the events, not itself an event.

**Default emit (human-readable):**

```
Middle-cluster telemetry (window=trailing 5 versions) — Verify / Authorize:
  [Verify]
    composed-loop-iteration-depth: 1.40 mean passes over 5 issue(s)
    escape-rate:                   1/8 (0.13)
    conditional-accept-rate:       2/11 (0.18)
    forward-handoff-payload-conformance: DEFER — no payload-conformance event; N/A-until-source
    lane-2-through-dt:             DEFER — no 'lane' field in the event schema; N/A-until-source
    ambiguous-ac:                  DEFER — verdict enum has no ambiguity value; N/A-until-source
  [Authorize]
    exception-plan-trigger-rate:   1/4 (0.25)
    decision-record-conformance:   NARROWED — presence present; deep conformance qualitative (rate deferred)
    decision-outcome-correlation:  POINTER — query-pipeline-event.sh --event-subtype recommendation-choice-delta --window N
    vocabulary-distinguishing:     DEFER — semantic (no structured field); N/A-until-source
    phase-b-3-tier-presentation:   DEFER — structural/text property, not an event; N/A-until-source
  mechanism: compute-middle-cluster-telemetry.sh
```

Per-indicator N/A is independent (§ 5). A window with no dev-test verdicts renders `escape-rate: N/A (no dt-pass subjects in window)` and `conditional-accept-rate: N/A (no dev-test verdicts in window)`.

## 4. The eleven indicators (definitions + the anti-overfit dispositions)

### Verify phase-class (Stages 7-8 — handoff fidelity)

**I16 — `forward-handoff-payload-conformance` (DEFER).** Whether the Stage-7→8 forward-handoff payload carried every required field. *Blocking reason:* the 10-column event schema carries no payload-conformance event; measuring it would need a new structured signal. **N/A-until-source.**

**I17 — `lane-2-through-dt` (DEFER).** The fraction of work routed through the Lane-2 dev-test path. *Blocking reason:* the event schema has no "lane" field — routing lane is not recorded. Building a rate would require inventing the field (exactly the synthesized-denominator FM1 rejects). **N/A-until-source.**

**I18 — `composed-loop-iteration-depth` (BUILD, mean).** How deep the composed DT↔Engineering / QA↔DT loop ran per issue. **Per subject:** the count of `iteration/{dt-eng-pass-N, qa-dt-pass-N}` rows (how many times it looped). **Window summary:** the **mean** over subjects with ≥1 iteration row. This is a per-issue mean, not a 0-1 rate — a loop that iterated twice has depth 2. **N/A:** no iteration rows in window.

**I19 — `escape-rate` (BUILD).** Of the work that passed dev-test, what fraction was then rejected at QA — a defect that escaped dev-test. **Numerator:** subjects with a `gate-outcome/dt-pass` and a *later* `gate-outcome/qa-rejection` (temporal ordering required — the escape surfaced after the DT pass; "later" is decided on **parsed datetimes**, never on raw timestamp strings — § 10 FM5). **Denominator:** subjects with a `gate-outcome/dt-pass`. **N/A:** no dt-pass subjects in window. *Boundary note:* this is issue-level (a defect escaping DT into QA), distinct from `calibration-data.md`'s gate-level `Escapes` column.

**I20 — `ambiguous-ac` (DEFER).** The fraction of acceptance criteria that were ambiguous. *Blocking reason:* the QA verdict enum is MET / NOT-MET / PARTIAL — there is no ambiguity value, and PARTIAL ≠ ambiguous (a PARTIAL-rate is an adjacent buildable proxy but measures partial-acceptance, not AC ambiguity). **N/A-until-source.**

**I21 — `conditional-accept-rate` (BUILD).** Of the dev-test verdicts, what fraction were conditional passes. **Numerator:** `gate-outcome/dt-conditional-pass` rows. **Denominator:** all dev-test verdict rows (`dt-pass` + `dt-conditional-pass` + `dt-return`). **N/A:** no dev-test verdicts in window.

### Authorize phase-class (Stage 9 — convergent-gate decision quality)

**I22 — `decision-record-conformance` (NARROWED → presence).** Whether the Stage-9 plan-review produced its decision record. Presence is mechanical: a `gate-outcome/plan-review-{go,no-go}` record (with the G-PR6 record) either is or is not in the window. **Deep conformance** — does the record meet every G-PR6 field — is qualitative, so the **rate is deferred**; the indicator **emits `presence present|absent`, NOT a ratio** (mirrors [`close-class-telemetry.md § 4 Indicator 5`](close-class-telemetry.md)'s presence-not-rate determination).

**I23 — `vocabulary-distinguishing` (DEFER).** Whether the decision record's vocabulary distinguished its decision classes. *Blocking reason:* this is a semantic analysis of decision-record vocabulary — no structured field records it, and a text-scan is not a mechanical denominator. **N/A-until-source.**

**I24 — `exception-plan-trigger-rate` (BUILD).** Of the plan-reviews, what fraction triggered an exception path. **Numerator:** distinct plan-reviews that resulted in a `gate-outcome/plan-review-no-go` OR a Stage-9 `escalation/*`. **Denominator:** distinct plan-reviews (subjects with a `plan-review-go`/`plan-review-no-go` verdict). **N/A:** no plan-reviews in window. *Why distinct-subject:* counting no-go rows plus escalation rows against a plan-review denominator could exceed 1; keying both numerator and denominator on the distinct plan-review subject keeps it a clean 0-1 rate (an exception-triggered plan-review counts once regardless of how many escalations it spawned).

**I25 — `decision-outcome-correlation` (POINTER).** Whether operator choices correlated with prior agent recommendations at the decision gate. **Already computed** by the [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) `--event-subtype recommendation-choice-delta --window N` look-back (the detective-only rec↔choice delta read-model per [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3). The read-model **references** it, never recomputes the delta look-back. *Why pointer:* the look-back already owns the rec↔choice delta window; recomputing here would duplicate it and risk a producer/producer disagreement.

**I26 — `phase-b-3-tier-presentation` (DEFER).** Whether the Stage-9 Phase-B briefing used the 3-tier presentation. *Blocking reason:* this is a structural/text property of the briefing, not an event — nothing in the event stream records the briefing's tier structure. **N/A-until-source.**

### 4.1 Deferred indicators — out-of-scope this release (Collective Review D4)

Per the Collective Review D4 decision, the DEFER indicators are recorded here as out-of-scope for this release, each with its blocking reason, so a future planner can promote them when a source appears — not silently dropped:

| Indicator | Blocking reason | Promotion trigger |
|---|---|---|
| **I16** `forward-handoff-payload-conformance` | no payload-conformance event in the 10-column schema | a structured handoff-conformance signal added to the schema |
| **I17** `lane-2-through-dt` | no "lane" field in the event schema | a routing-lane field added to the event schema |
| **I20** `ambiguous-ac` | verdict enum has no ambiguity value (PARTIAL ≠ ambiguous) | an ambiguity verdict value or structured AC-ambiguity field |
| **I23** `vocabulary-distinguishing` | semantic analysis — no structured field | a structured decision-vocabulary field |
| **I26** `phase-b-3-tier-presentation` | structural/text property of the briefing, not an event | a structured briefing-tier signal |

Each of these promotions would need a **new event signal** — which is the CIAC-1 seam: promoting a DEFER indicator to BUILD is where a co-write with [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) would bind. Deferring them is what keeps this standard's "no new schema" invariant true (§ 8).

## 5. N/A semantics (per-indicator, independent)

Each indicator resolves its own N/A independently — a window can yield a real value for some indicators and N/A for others. N/A is never blank-fill; it carries a parenthetical reason.

| Indicator | N/A condition |
|---|---|
| I18 composed-loop-iteration-depth | no `iteration` rows in window |
| I19 escape-rate | no `gate-outcome/dt-pass` subjects in window |
| I21 conditional-accept-rate | no dev-test verdict rows in window |
| I24 exception-plan-trigger-rate | no plan-reviews in window |
| I22 decision-record-conformance | not a rate — `presence present/absent`; the quality rate is a reached deferral (deep conformance qualitative) |
| I25 | not an N/A — a POINTER to the rec↔choice-delta look-back |
| I16 / I17 / I20 / I23 / I26 | DEFER — `N/A — deferred (blocking reason)`, a reached determination (§ 4.1) |

**Explicit-N/A discipline:** every indicator slot is present with a value, an `N/A (reason)`, a POINTER, a presence flag, or a DEFER record. A missing slot is a tool defect, not a silent N/A. **Why N/A and not zero:** a window with no dev-test verdicts genuinely has no escape-rate to measure; recording `0.00` would crush any calibration the same way a synthesized ratio biases the weights. The one load-bearing zero-vs-N/A case: **`0.00` escape-rate with a non-empty dt-pass population is a real clean signal** (work passed DT, none escaped to QA); **N/A is an empty population** (no DT passes to measure) — conflating them fabricates a clean signal or discards one.

## 6. Domain alignment — the "sound coming OUT" cluster + the fission boundary

This instrument is the measurement layer for the pipeline's **verify-and-authorize phase-classes**, cleaved from the Demand + Definition + Solution-design classes on the **pipeline-temporal cluster axis** (not on data-source homogeneity — the pipeline-event-log is the shared backbone for both clusters). The middle cluster answers *"is built work sound coming OUT"* (handoff fidelity, decision quality); the front cluster ([`phase-telemetry-front-cluster.md`](phase-telemetry-front-cluster.md)) answers *"is work well-formed going IN"*. The two files build in parallel on disjoint surfaces (the makespan reason for the fission); they share this identical anatomy and a cross-reference stanza (§ 12). The split is CHEAP-reversible — re-merge to one file if fragmentation ever bites.

## 7. Computation tool

Reference implementation: [`release/tools/compute-middle-cluster-telemetry.sh`](../../tools/compute-middle-cluster-telemetry.sh).

**Form factor:** a wrapper composing over [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) (the event reads). It mirrors the [`compute-dora-metrics.sh`](../../tools/compute-dora-metrics.sh) / [`compute-close-class-telemetry.sh`](../../tools/compute-close-class-telemetry.sh) form factor and exit-code contract: `set -euo pipefail`, PATH pinned to system tools, `/usr/bin/python3` stdlib only, a built-in `--self-test`, a `--json` detail mode, a `--window N` (trailing N distinct versions), a `--indicator <name>` single-indicator mode, and the 0/1/2 exit-code semantics. The four BUILD indicators are computed in a single python pass over the event stream; the POINTER indicator emits its pointer string; the NARROWED emits presence; the DEFER indicators emit their record.

**CLI:**

```bash
./compute-middle-cluster-telemetry.sh                      # human block, all events
./compute-middle-cluster-telemetry.sh --window 5           # trailing 5 distinct versions
./compute-middle-cluster-telemetry.sh --json               # JSON of all indicators
./compute-middle-cluster-telemetry.sh --indicator escape-rate   # single indicator
./compute-middle-cluster-telemetry.sh --self-test          # validate logic, no network
```

**Exit codes:**
- `0` — success (any indicator may legitimately produce N/A — empty population; a POINTER; a NARROWED presence; or a DEFER reason)
- `1` — invalid args / required dependency (`query-pipeline-event.sh` / `python3`) unavailable
- `2` — malformed source (a `ts_iso` parse failure — source-integrity violation; escalate)

**Manual-fill fallback:** if the tool cannot run at read time, the indicators may be computed by hand from the event stream exactly as the DORA and close-class fields degrade gracefully — the standard and the convention bind either way.

## 8. Boundary statement (event-log READER; read-only; NOT calibration-data.md; NOT a schema write)

Middle-cluster telemetry sources from the **pipeline-event-log**. Three boundaries are load-bearing and were scope-locked at Collective Review:

1. **Read-model, not writer.** The read-model READS the event stream; it NEVER appends a middle-cluster row back into `pipeline-event-log.md` (§ 3.2 / § 12 FM3).
2. **NOT `calibration-data.md`.** The AC's parenthetical "land in the `calibration-data.md` schema" was corrected at Collective Review: `calibration-data.md` is a boundary-keyed, dimension-agnostic **gate-outcome** surface that structurally cannot host named per-phase read-models; this standard adopts the DORA on-demand window read-model surface instead.
3. **Schema READER (CIAC-1).** Every BUILD + POINTER indicator sources from an EXISTING [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 subtype. This standard defines no new event subtype and writes no schema — the 5 DEFER indicators are deferred *precisely because* building them would need a new signal (a structured payload field or a new subtype), which is what keeps "no new schema" true. Promoting a DEFER indicator is where a co-write with the schema would bind — out of scope here (§ 4.1).

## 9. Cutover / grandfather

**GRANDFATHER. No backfill.** Middle-cluster telemetry is computed over windows going forward, from events emitted post-cutover. Pre-cutover windows are **excluded** — a window that predates consistent event emission yields N/A for the affected indicators (graceful degradation, not a gap to fill). No backfill of historical middle-cluster metrics: reconstructing whether a historical defect escaped DT or a historical plan-review triggered an exception is unreliable (the event stream may have been sparsely emitted — indeed the DT/QA iteration and verdict subtypes populate only as the hub-spoke instrumentation matures), so a backfilled value would be synthesized, not measured. The calibration population counts only non-N/A post-cutover reads. The window-over-window TREND read is meaningful only after ≥3 comparable windows accrue — the platform-wide N=3 calibration threshold ([`gate-evaluation-spec.md § Layer 3`](../../../core/schemas/gate-evaluation-spec.md)), inherited, not redefined.

## 10. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **INPUT** | Reporting an escape-rate / conditional-accept-rate of `0.00` over an empty window | When a window contains zero `gate-outcome/dt-pass` subjects (or zero dev-test verdicts), do NOT report `0.00` — emit `N/A (no ... in window)` | Convenience collapse: "no QA rejections, so 0% escape". But `0.00` means "work passed DT and none escaped to QA" (a real clean-verify SIGNAL); N/A means "no DT passes to measure" (no population). Reporting an empty window as 0.00 fabricates a clean-verify signal and biases any window-over-window trend toward false health | § 5 binds every BUILD rate's N/A to a zero-DENOMINATOR (empty population) and `0.00` to a non-empty population with a zero numerator; the tool emits `rate: null` → `N/A` for the empty case | Principal: checks the denominator first — zero dt-pass → `N/A`; ≥1 dt-pass, zero escapes → `0.00`. Junior: forces 0.00 for any window without a qa-rejection → a pre-instrumentation window reads as "perfect verify quality", masking that nothing was measured |
| FM2 | **PROC** | Manufacturing a rate for a DEFER indicator | When emitting I16/I17/I20/I23/I26, do NOT synthesize a denominator (a lane guess, a PARTIAL-as-ambiguous conflation, a decision-vocabulary text-scan) to produce a rate — emit the DEFER record with its blocking reason | The denominator does not exist: routing-lane, AC-ambiguity, decision-vocabulary, and briefing-tier have no structured field in the 10-column event schema. Inventing one produces a precise-looking ratio with no real signal and biases any calibration that reads it — and reclassifies the read-model as an event-log *writer* the moment the "new signal" is added | § 1.1 + § 4 ship the 5 as DEFER with blocking reasons; the tool emits their DEFER string, never a ratio; § 4.1 records the promotion trigger (a new event signal) as the CIAC-1 seam | Principal: emits `DEFER — no 'lane' field in the event schema` and records the promotion trigger. Junior: maps PARTIAL verdicts to "ambiguous" → publishes an "ambiguous-AC rate" that conflates partial-acceptance with ambiguity → calibration reads a fabricated signal |
| FM3 | **OUT** | Emitting a computed middle-cluster metric back into the event log | When surfacing a middle-cluster window, do NOT append a `phase-telemetry` (or any synthesized) row to `pipeline-event-log.md` — the read-model READS the event stream; it never writes to it | "It would be convenient to cache the computed rate as an event for the next reader." But a middle-cluster metric is a FUNCTION of the events, not a primary observation; writing it back pollutes the append-only stream, double-counts on the next read, and violates the event-log "primary observations only" invariant (the same OUT boundary [`dora-telemetry.md § 10 FM3`](dora-telemetry.md) names) | § 3.2 + § 8 state read-model-only explicitly; the tool has no write path to the event log — it composes over the READ primitive only | Principal: renders the block to stdout / the consumer surface; the event log is untouched. Junior: appends a `phase-telemetry/middle-rollup` row "for caching" → the next window read re-aggregates the cached metric as a primary event → the stream is corrupted |
| FM4 | **PROC** | Recomputing the rec↔choice-delta look-back inline | When populating I25 (decision-outcome-correlation), do NOT re-implement the trailing-window rec↔choice delta scan — emit the pointer; the look-back is owned by [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) `--event-subtype recommendation-choice-delta --window N` | The query primitive already owns the rec↔choice delta window read-model. Recomputing here duplicates the window logic and risks a producer/producer disagreement (two tools, two slightly-different delta definitions, two correlations for the same window) | § 4 I25 fixes it as a POINTER; the producing tool emits the pointer string and has no delta-scan code | Principal: emits `POINTER — query-pipeline-event.sh --event-subtype recommendation-choice-delta --window N` and lets the primitive own the read. Junior: re-implements a delta scan in this tool → its correlation diverges from the primitive's on the same window → two contradictory decision-correlation numbers in the corpus |
| FM5 | **PROC** | Ordering events by raw timestamp string instead of parsed datetime | When deciding "did the QA rejection come *after* the DT pass" (I19), do NOT compare the `ts` strings — parse once at ingest and compare `datetime` values; validating that a timestamp parses is not the same as ordering on it | Lexicographic order equals chronological order only under ONE fixed timestamp format. A fractional-second ISO stamp (`…:00.250Z`) parses cleanly, clears the exit-2 source-integrity gate, and then sorts BEFORE `…:00Z` because `.` < `Z` — so a rejection that genuinely followed its DT pass reads as preceding it, the escape is silently dropped, and the instrument publishes `escape-rate 0/1 (0.00)`. That is a **fabricated clean signal** — the same outcome FM1 exists to prevent, reached through a wrong population rather than an empty one, and it raises no error | The tool parses `ts` once at ingest, carries the `datetime` on the row, and orders I19 on it; `ts` is retained for display only. § 4 I19 states the parsed-datetime requirement, and the self-test carries a discriminating same-second fixture (one Z-form dt-pass, one fractional-second qa-rejection) that a raw-string implementation fails. Mirrors the sibling [`phase-telemetry-front-cluster.md § 10 FM6`](phase-telemetry-front-cluster.md) | Principal: treats "it parses" and "it orders" as two separate obligations, and writes the fixture whose string order contradicts its true order. Junior: sees `parse_iso()` called on every row, concludes timestamps are handled, compares strings — correct on every canonical row, and silently reports perfect DT quality the first time a non-canonical stamp appears |

## 11. Consumers

| Consumer | Role |
|---|---|
| `release-planner` Mode B (durable release plan authoring) | Reads a middle-cluster window for quality calibration once a window establishes (e.g., "escape-rate ~0.13; weight the next release's DT rigor accordingly") — wiring active post-trend (N=3 windows) |
| `pmo-qa-auditor` (phase-quality review) | Reads the middle-cluster indicators as phase-quality signals — Verify handoff-fidelity (loop depth, escape rate), Authorize decision-quality (exception trigger, decision-record presence) — in a review |
| [`phase-telemetry-front-cluster.md`](phase-telemetry-front-cluster.md) | Sibling cluster (Demand + Definition + Solution-design) — shared anatomy, disjoint phase surface; the two clusters compose into the full 5-phase phase-distinctive telemetry surface |
| [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) | Owns the I25 POINTER (rec↔choice-delta look-back) — this standard POINTS to it, never recomputes |

## 12. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Window read-model model + OUT boundary | [`dora-telemetry.md`](dora-telemetry.md) § 3.1 / § 10 | The on-demand window surface + read-model-only OUT-class boundary this standard adopts verbatim |
| 4-way anti-overfit disposition template | [`close-class-telemetry.md`](close-class-telemetry.md) § 1.1 / § 4 | The BUILD / POINTER / NARROWED / DEFER disposition tiering this standard applies per indicator; the NARROWED presence-not-rate determination (I22) mirrors its Indicator 5 |
| Sibling cluster | [`phase-telemetry-front-cluster.md`](phase-telemetry-front-cluster.md) | Demand + Definition + Solution-design — split on the cluster axis; identical anatomy |
| Source events schema (READ only) | [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 | Defines every event subtype this standard reads; this standard is a READER (CIAC-1), never writes it |
| Query primitive + I25 POINTER owner | [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) | Read helper the compute tool composes over; also owns the rec↔choice-delta look-back (I25 POINTER target) |
| Point scale rounding mode | [`bundle-composition-doctrine.md`](bundle-composition-doctrine.md) § 3 Step 5 | Owns the round-half-up definitional home (taken by reference; § 3.1) |
| Compute wrapper | [`compute-middle-cluster-telemetry.sh`](../../tools/compute-middle-cluster-telemetry.sh) | Reference implementation of § 4 indicator computation + § 3 format selection |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at the standards set |

## Version History

Tracked in git history.
