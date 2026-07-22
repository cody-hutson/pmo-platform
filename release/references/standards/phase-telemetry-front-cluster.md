---
title: Phase-Distinctive Telemetry — Front Cluster (Demand / Definition / Solution-design)
purpose: K1 codified-knowledge standard defining the front-cluster phase-distinctive quality-attribute telemetry read-models — how well work is "well-formed going IN" across Demand (Stages 1-2), Definition (Stages 3-4), and Solution-design (Stage 5) — computed as an on-demand window read-model over EXISTING pipeline-event-log subtypes plus a thin gh gauge, NOT a new event schema and NOT the calibration-data.md surface
type: standard
parallel_to: dora-telemetry.md (the on-demand window read-model whose §3.1 surfacing model + N/A discipline + read-model-only OUT boundary this standard adopts verbatim), close-class-telemetry.md (the 4-way anti-overfit disposition template — BUILD / POINTER / NARROWED / DEFER — this standard applies per indicator), phase-telemetry-middle-cluster.md (the sibling cluster — Verify + Authorize — split from this one on the pipeline-temporal cluster axis; identical anatomy, disjoint phase surface)
reversibility: CHEAP (forward-only additive read-model; pre-cutover windows excluded; computes lazily from existing events; no event-log schema change, no master-table change — the whole instrument reverts with one commit; the cluster split re-merges to one file if fragmentation ever bites)
consumers: "release-planner Mode B (front-cluster capacity/quality calibration once a window establishes); pmo-qa-auditor (phase-quality review — Demand triageability, Definition capacity-feasibility, Solution-design implementation-readiness); release/references/standards/phase-telemetry-middle-cluster.md (sibling cluster, shared anatomy)"
version: v1.00
---

<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->

# Phase-Distinctive Telemetry — Front Cluster (Demand / Definition / Solution-design)

## 1. Purpose

Front-cluster telemetry = a set of mechanical read-models of **how well work is "well-formed going IN"** to the pipeline — the quality-attribute signals distinctive to the pipeline's front three phase-classes:

- **Demand** (Stages 1-2) — first-pass *triageability*: is work reaching the triage gate cleanly, quickly, and attributed?
- **Definition** (Stages 3-4) — scoped *capacity-feasibility*: does a plan, once made, survive; are bundles stable; is capacity honoured?
- **Solution-design** (Stage 5) — *implementation-readiness*: does the design survive to Engineering; is scope locked on the first pass?

Prior to this standard, the platform shipped the Build+Deploy telemetry layer (DORA-4, [`dora-telemetry.md`](dora-telemetry.md)) and the Close-class layer ([`close-class-telemetry.md`](close-class-telemetry.md)), but the **phase-distinctive observability** columns for the front three phase-classes — named in the v11.01 audit finding F-Release-1 and deferred when the DORA slice was scoped to its four-metric anchor — had no machine-readable instantiation. The underlying signals already exist in the pipeline-event-log (triage gate-outcomes, scope-change / escalation returns, planning + bundle decisions, re-review rows, scope-lock decisions) plus `gh` state (the approved queue) — but no read-model composed them into the front-cluster frame. This standard codifies the front-cluster indicators' definitions, their EXISTING event sources (zero new event types), their computation, their explicit per-indicator N/A semantics, and the on-demand window surface, so the front-cluster signals are produced consistently and consumed deterministically by front-cluster calibration (release-planner Mode B) and phase-quality review (pmo-qa-auditor).

**Scope:** the 15 candidate front-cluster indicators, anti-overfit-dispositioned (§ 1.1 / § 4), computed over a bounded version window from EXISTING pipeline-event-log subtypes (`gate-outcome/g1-g2`, `scope-change/*`, `escalation/*`, `decision/{scope-lock, a7-bundle-*, ...}`, `re-review/{phase-a0-row, phase-0.5-row}`) plus a thin best-effort `gh` read for the one gh-sourced gauge (approved-queue-depth). Read-model only — the computation reads the event stream; it NEVER emits a row back into it.

**Out of scope:** the Verify + Authorize phase-classes (the sibling cluster — [`phase-telemetry-middle-cluster.md`](phase-telemetry-middle-cluster.md)); the DORA-4 build+deploy metrics and the close-class close-quality metrics (the disjoint sibling instruments); any indicator whose present data source does not exist — deferred per § 4, never given bespoke machinery; **the pipeline-event-log schema itself** — this standard is a schema READER (CIAC-1), it defines no event subtype and writes no schema.

### 1.1 The anti-overfit posture (load-bearing)

This standard deliberately ships **fewer fully-built indicators than the front three phases could theoretically expose.** Fifteen indicators were considered; they are NOT all built as rates, because building a rate whose denominator is undefined, or whose source does not yet exist, manufactures a precise-looking number with no real signal (the synthesized-data-biases-calibration trap [`close-class-telemetry.md § 1.1`](close-class-telemetry.md) names). The scope is therefore tiered exactly as close-class tiered its six:

| Disposition | Meaning | Count (front) |
|---|---|---|
| **BUILD** | a real mechanical denominator over an existing signal → computed as a rate / median / gauge | 9 |
| **POINTER** | already computed elsewhere → reference it by role, never recompute | 3 |
| **NARROWED** | the quality *rate*'s denominator is undefined, but the indicator has a bounded promotion path once its source exists → emit presence, never a rate. Two realizations: a **computed** presence flag where the presence source already exists (the sibling cluster's I22), or a **static determination record** where it does not yet (I3 — § 4) | 1 |
| **DEFER** | no present mechanical source → N/A-until-source-exists, build no bespoke machinery | 2 |

The discipline: **measure what has a real, mechanical denominator; pointer to what is already measured; narrow to presence what has no principled rate; explicitly defer what has no source yet.** A deferred indicator is recorded as deferred with its blocking reason (§ 4), never silently dropped and never faked with a synthetic denominator. The 9-of-15 BUILD ratio mirrors close-class's own posture (3 BUILD of 6) scaled up.

## 2. What is measured

The front-cluster read-model carries the nine BUILD indicators, the three POINTERs, the one NARROWED presence, and the two DEFER records, plus a producing-tool marker. All BUILD rates are 2-decimal ratios (§ 3.1); the cycle-time is a compact duration; the approved-queue-depth is an integer gauge.

| # | Phase | Indicator | Disposition | Source (existing) | Format |
|---|---|---|---|---|---|
| 1 | Demand | `zero-round-trip-triage-rate` | **BUILD** | event-log: subjects reaching `gate-outcome/g1-g2` with no `scope-change/*` or `escalation/*` at/before the gate ÷ subjects reaching `g1-g2` | `<n>/<d> (<ratio>)` |
| 2 | Demand | `decision-date-setting` | **DEFER** | `gh` Decision-Date field deliberately unpopulated (no-backfill-at-scale) | `N/A — deferred (reason)` |
| 3 | Demand | `source-of-origin-attribution` | **NARROWED** | none today — no structured intake source field exists to read, so the slot carries a static determination record, not a computed flag (§ 4 I3) | `presence/coverage; rate deferred` (literal) |
| 4 | Demand | `triage-cycle-time` | **BUILD** | event-log ts-delta: subject first-seen → `gate-outcome/g1-g2`, window **median** | compact duration |
| 5 | Demand | `approved-queue-depth` | **BUILD** (gauge) | `gh`: count of open `status: approved` ∪ `status: bundled` issues — a level gauge, not a rate | `<N> open` |
| 6 | Definition | `plan-survival-rate` | **BUILD** | event-log: planned per-issue subjects (a `decision` at stage 4) with no subsequent `scope-change/{tier-2-scope-change, tier-3-plan-rejection}` ÷ planned | `<n>/<d> (<ratio>)` |
| 7 | Definition | `bundle-amendment-rate` | **BUILD** | event-log: distinct `milestone:*` bundles with an `a7-bundle-{amend,rebundle,defer}` ÷ bundled milestones | `<n>/<d> (<ratio>)` |
| 8 | Definition | `phase-a0-c3-rate` | **BUILD** | event-log: `re-review/phase-a0-row` rows carrying a C3 class token ÷ phase-a0 re-review rows | `<n>/<d> (<ratio>)` |
| 9 | Definition | `capacity-overrun` | **POINTER** | [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) Gate 3→4 `Capacity utilization` (`bundle_size/capacity_heuristic`) | pointer string |
| 10 | Definition | `file-contention-detection` | **POINTER** | [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) Gate 3→4 `Contention density` (`files_with_2+_issues/total_unique_files`) | pointer string |
| 11 | Sol-design | `plan-survival-post-solutioning-rate` | **BUILD** | event-log: `decision/scope-lock` subjects with no `scope-change/*` at/after the lock ÷ scope-locked subjects | `<n>/<d> (<ratio>)` |
| 12 | Sol-design | `adr-closure` | **POINTER** | [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) Gate 5→6 `ADR closure` (`adr_closed/adr_opened`) | pointer string |
| 13 | Sol-design | `quality-attribute-trade-off-mention` | **DEFER** | no structured field; a semantic text-scan is not a mechanical denominator | `N/A — deferred (reason)` |
| 14 | Sol-design | `phase-0.5-c3-rate` | **BUILD** | event-log: `re-review/phase-0.5-row` rows carrying a C3 class token ÷ phase-0.5 re-review rows | `<n>/<d> (<ratio>)` |
| 15 | Sol-design | `collective-review-scope-lock-first-pass-rate` | **BUILD** | event-log: subjects scope-locked exactly once (approved first pass, no re-lock) ÷ scope-locked subjects | `<n>/<d> (<ratio>)` |
| — | — | `mechanism` | — | literal `compute-front-cluster-telemetry.sh` | suffix |

## 3. Unit / Format

### 3.1 Rates (round-half-up, taken by reference)

The BUILD rate indicators are 2-decimal ratios, rounded **round-half-up** at the second decimal — taken **by reference** from the single definitional home at [`bundle-composition-doctrine.md § 3 Step 5`](bundle-composition-doctrine.md) (the same canonical mode [`release-velocity-tracking.md § 3.2`](release-velocity-tracking.md) and [`close-class-telemetry.md § 3.1`](close-class-telemetry.md) take by reference), so a producer and an enforcer cannot disagree at a half-integer boundary. This standard does NOT re-derive the mode; the producing tool implements that one canonical mode. The triage-cycle-time uses the compact `<X>m` / `<H>h<M>m` / `<D>d<H>h` duration form [`dora-telemetry.md § 3`](dora-telemetry.md) uses. The approved-queue-depth is a bare integer level gauge (a count, not a rate — a queue depth has no denominator).

### 3.2 Surface — on-demand window read-model (adopts dora-telemetry.md § 3.1)

Front-cluster telemetry is a **window read-model, not a per-release visible-H4 field, and NOT a `calibration-data.md` row.** Per-phase populations only signal over a window of multiple items (a single release triages / plans / designs too few items for a rate to mean anything — the same reason [`dora-telemetry.md § 3.1`](dora-telemetry.md) makes DORA a window read-model, and the same reason the `calibration-data.md` row is a boundary-keyed, dimension-agnostic gate-outcome surface that structurally cannot host named per-phase read-models — [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) § Versioning, the v1.2 "**Calibration:**" bullet). The indicators are therefore computed **on demand over a window** by the computation tool (§ 7) and surfaced where a window read-model belongs — a release-planner capacity/quality calibration read, a pmo-qa-auditor phase-quality assessment — **NOT** appended to any single release's RELEASE_LOG row and **NOT** written into `calibration-data.md`.

**This is the load-bearing OUT-class boundary:** the read-model reads the event log; it NEVER writes a front-cluster row back into `pipeline-event-log.md` (§ 12 FM3). A front-cluster metric is a FUNCTION of the events, not itself an event.

**Default emit (human-readable):**

```
Front-cluster telemetry (window=trailing 5 versions) — Demand / Definition / Solution-design:
  [Demand]
    zero-round-trip-triage-rate:  7/9 (0.78)
    triage-cycle-time:            2h15m (median over subjects)
    approved-queue-depth:         42 open (approved+bundled)
    source-of-origin-attribution: NARROWED — presence/coverage; rate deferred (no structured intake source field)
    decision-date-setting:        DEFER — gh field deliberately unpopulated (no-backfill-at-scale); N/A-until-populated
  [Definition]
    plan-survival-rate:           5/6 (0.83)
    bundle-amendment-rate:        1/4 (0.25)
    phase-a0-c3-rate:             2/11 (0.18)
    capacity-overrun:             POINTER — gate-evaluation-spec.md Gate 3->4 Capacity utilization
    file-contention-detection:    POINTER — gate-evaluation-spec.md Gate 3->4 Contention density
  [Solution-design]
    plan-survival-post-solutioning-rate:            8/9 (0.89)
    phase-0.5-c3-rate:                              1/9 (0.11)
    collective-review-scope-lock-first-pass-rate:   6/9 (0.67)
    adr-closure:                                    POINTER — gate-evaluation-spec.md Gate 5->6 ADR closure
    quality-attribute-trade-off-mention:            DEFER — no structured field (semantic scan); N/A-until-source
  mechanism: compute-front-cluster-telemetry.sh
```

Per-indicator N/A is independent (§ 5). A window with no phase-a0 re-review rows renders `phase-a0-c3-rate: N/A (no phase-a0 re-review rows in window)`; a window that deployed no gh reader renders `approved-queue-depth: N/A (gh unavailable ...)`.

## 4. The fifteen indicators (definitions + the anti-overfit dispositions)

### Demand phase-class (Stages 1-2 — triageability)

**I1 — `zero-round-trip-triage-rate` (BUILD).** Of the subjects that reached the triage gate, what fraction reached it cleanly — no return trip during triage. **Numerator:** subjects with a `gate-outcome/g1-g2` and NO `scope-change/*` or `escalation/*` row at or before the g1-g2 timestamp. **Denominator:** subjects with a `gate-outcome/g1-g2`. **N/A:** no triaged subjects in window.

**I2 — `decision-date-setting` (DEFER).** *Blocking reason:* the `gh` Decision-Date field exists but is deliberately unpopulated per the no-backfill-at-scale decision (memory: "No Projects board on public repo"). A rate over an intentionally-empty field reads structurally-low — that measures the backfill decision, not decision-quality. **N/A-until-populated**; no bespoke machinery. Promote to BUILD only if/when Decision-Date is consistently populated going forward.

**I3 — `source-of-origin-attribution` (NARROWED → static determination record).** Whether intake carries where the work originated. Two things are missing, not one: a *quality* rate has no principled denominator ("was the source attributed *meaningfully*" is qualitative), **and** there is today **no structured intake source field to read at all** — so there is nothing mechanical for a presence/coverage read to count either. The indicator therefore **emits a static determination record** — the literal string `presence/coverage; rate deferred (no structured intake source field)` — **not a computed flag**: nothing is read, and nothing can flip. That is what the tool does, and § 2's Format cell and § 5's N/A row record the same thing.

**Why this stays NARROWED rather than becoming DEFER.** The disposition marks *how far the indicator can go once its source exists*: I3's promotion path is a **BUILD coverage rate** the moment intake templates carry a structured source field (presence would then be mechanically countable), whereas a DEFER (I2, I13) has no such bounded next step recorded. The operative anti-overfit guard is identical under either label — **never emit a rate for a sourceless indicator** — and the tool honours it. Compare the sibling [`phase-telemetry-middle-cluster.md § 4 I22`](phase-telemetry-middle-cluster.md), the other NARROWED in this instrument: its presence source *does* exist, so it emits a genuinely computed `present|absent` that flips on an empty stream. One disposition token, two realizations — a computed presence flag where the presence source exists, a static determination record where it does not yet — and in neither case a rate. (Mirrors [`close-class-telemetry.md § 4 Indicator 5`](close-class-telemetry.md)'s presence-not-rate determination.)

**I4 — `triage-cycle-time` (BUILD).** The elapsed time from a subject's first appearance in the event stream to its triage gate. **Per subject:** `T(g1-g2) − T(first-seen)`; the window summary is the **median** (triage latency is right-skewed — a few long-gestation items distort a mean, the same reason DORA reports lead-time as a median). **N/A:** no triaged subjects in window.

**I5 — `approved-queue-depth` (BUILD, gauge).** The current level of demand-pressure downstream of triage: how many issues sit approved-but-unshipped. **Source:** `gh issue list --state open` over the union of `status: approved` and `status: bundled`. This is a **level gauge (an integer count), not a 0-1 rate** — a queue depth has no denominator. **N/A:** `gh` unavailable (the tool degrades gracefully, exit 0).

### Definition phase-class (Stages 3-4 — capacity-feasibility)

**I6 — `plan-survival-rate` (BUILD).** Of the per-issue plans made at Planning, what fraction survived without a scope reversal. **Numerator:** planned subjects (a `decision`-class event at stage 4, excluding `milestone:*` bundle-level subjects and re-review rows — see FM2) with no subsequent `scope-change/{tier-2-scope-change, tier-3-plan-rejection}`. **Denominator:** planned subjects. **N/A:** no subjects reached a plan in window.

**I7 — `bundle-amendment-rate` (BUILD).** Of the bundles formed, what fraction were later amended. **Numerator:** distinct `milestone:*` subjects with an `a7-bundle-amend` / `a7-bundle-rebundle` / `a7-bundle-defer` decision. **Denominator:** distinct `milestone:*` subjects appearing in any `decision` row (bundled milestones). **N/A:** no bundled milestones in window.

**I8 — `phase-a0-c3-rate` (BUILD).** Of the Phase-A0 (Stage-4-entry) re-reviews, what fraction raised a fundamental premise challenge (C3). **Numerator:** `re-review/phase-a0-row` rows whose payload carries a C3 class token (the C1/C2/C3 classification per [`triage-design-rereview.md § 5`](triage-design-rereview.md)). **Denominator:** `re-review/phase-a0-row` rows. **N/A:** no phase-a0 re-review rows in window. *Source note:* the C3 token is read from the re-review row payload as the **structured class token** `class:C3` (whitespace-tolerant, case-insensitive) — **not** as a bare `C3` substring. Payloads are free text to 300 chars, so a `class:C1` row whose prose merely *mentions* C3 ("no C3-level challenge raised") would score as a premise challenge under a substring test and fabricate a dirty signal in this indicator's numerator. A window of re-review rows with zero C3 tokens is a real `0.00` (no premise challenges), distinct from N/A (no re-reviews to measure).

**I9 — `capacity-overrun` (POINTER).** Whether a bundle overran the capacity heuristic. **Already computed** by [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) Gate 3→4 `Capacity utilization` = `bundle_size / capacity_heuristic` (threshold ≤ 1.2). The read-model **references** it — it does not recompute the heuristic (FM4). *Why pointer:* the gate evaluator already owns `capacity_heuristic` (rolling max of last 5 releases); recomputing it here would duplicate the rolling-window logic and risk a producer/producer disagreement.

**I10 — `file-contention-detection` (POINTER).** Whether a bundle's files collided across issues. **Already computed** by [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) Gate 3→4 `Contention density` = `files_with_2+_issues / total_unique_files` (threshold ≤ 0.5). The read-model **references** it, never recomputes the cross-issue file analysis.

### Solution-design phase-class (Stage 5 — implementation-readiness)

**I11 — `plan-survival-post-solutioning-rate` (BUILD).** Of the designs whose scope was locked, what fraction survived to Engineering without a scope change. **Numerator:** `decision/scope-lock` subjects with no `scope-change/*` at or after the earliest scope-lock. **Denominator:** scope-locked subjects. **N/A:** no scope-locked subjects in window.

**I12 — `adr-closure` (POINTER).** Whether the design's ADRs closed. **Already computed** by [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) Gate 5→6 `ADR closure` = `adr_closed / adr_opened` (threshold = 1.0). The read-model **references** it, never recomputes the `adr`-label query.

**I13 — `quality-attribute-trade-off-mention` (DEFER).** Whether a design spec surfaced its quality-attribute trade-offs. *Blocking reason:* no structured field records a trade-off mention; a semantic text-scan of design specs is not a mechanical denominator (it is exactly the synthesized-denominator FM1 rejects). **N/A-until-source.** Promote to BUILD only if a structured trade-off field is added to the Solutioning output template.

**I14 — `phase-0.5-c3-rate` (BUILD).** Of the Phase-0.5 (Stage-5-entry) re-reviews, what fraction raised a fundamental premise challenge (C3). **Numerator:** `re-review/phase-0.5-row` rows carrying a C3 class token. **Denominator:** `re-review/phase-0.5-row` rows. **N/A:** no phase-0.5 re-review rows in window. *Source note* as I8.

**I15 — `collective-review-scope-lock-first-pass-rate` (BUILD).** Of the scope-lock decisions, what fraction locked on the first pass — approved without a re-lock. **Numerator:** subjects with exactly one `decision/scope-lock` row (a single lock = first-pass approval; a re-lock means the first did not hold). **Denominator:** subjects with ≥1 `decision/scope-lock`. **N/A:** no scope-locked subjects in window. *Why count-based:* scope-lock is by definition the approval decision — a second scope-lock for the same subject is the mechanical signal that the first pass did not hold, so the count (not a fragile outcome-token parse) is the defensible first-pass denominator.

### 4.1 Deferred indicators — out-of-scope this release (Collective Review D4)

Per the Collective Review D4 decision, the DEFER indicators are recorded here as out-of-scope for this release, each with its blocking reason, so a future planner can promote them when a source appears — not silently dropped:

| Indicator | Blocking reason | Promotion trigger |
|---|---|---|
| **I2** `decision-date-setting` | `gh` Decision-Date deliberately unpopulated (no-backfill-at-scale) — a rate reads structurally-low, not quality | Decision-Date populated consistently going forward |
| **I13** `quality-attribute-trade-off-mention` | no structured field — a semantic text-scan is not a mechanical denominator | a structured trade-off field added to the Solutioning output template |

## 5. N/A semantics (per-indicator, independent)

Each indicator resolves its own N/A independently — a window can yield a real value for some indicators and N/A for others. N/A is never blank-fill; it carries a parenthetical reason.

| Indicator | N/A condition |
|---|---|
| I1 zero-round-trip-triage-rate | no `gate-outcome/g1-g2` subjects in window |
| I4 triage-cycle-time | no triaged subjects in window |
| I5 approved-queue-depth | `gh` unavailable (cannot read the queue) |
| I6 plan-survival-rate | no subjects reached a plan in window |
| I7 bundle-amendment-rate | no bundled milestones in window |
| I8 phase-a0-c3-rate | no `phase-a0-row` re-review rows in window |
| I11 plan-survival-post-solutioning-rate | no scope-locked subjects in window |
| I14 phase-0.5-c3-rate | no `phase-0.5-row` re-review rows in window |
| I15 collective-review-scope-lock-first-pass-rate | no scope-locked subjects in window |
| I3 source-of-origin-attribution | not a rate — a **static determination record** (`presence/coverage; rate deferred`), emitted as a literal because no structured intake source field exists to read; the quality rate is a reached deferral (no structured denominator) — § 4 I3 |
| I9 / I10 / I12 | not an N/A — a POINTER to the owning gate metric |
| I2 / I13 | DEFER — `N/A — deferred (blocking reason)`, a reached determination (§ 4.1) |

**Explicit-N/A discipline:** every indicator slot is present with a value, an `N/A (reason)`, a POINTER, a presence flag, or a DEFER record. A missing slot is a tool defect, not a silent N/A. **Why N/A and not zero:** a window with no re-reviews genuinely has no C3-rate to measure; recording `0.00` would crush any calibration the same way a synthesized velocity ratio biases the capacity weights. The calibration population counts only non-N/A values. The one load-bearing zero-vs-N/A case is the C3-rates and bundle-amendment: **`0.00` with a non-empty population is a real clean signal** (re-reviews ran, zero premise challenges); **N/A is an empty population** (no re-reviews to measure) — conflating them fabricates a clean signal or discards one.

## 6. Domain alignment — the "well-formed going IN" cluster + the fission boundary

This instrument is the measurement layer for the pipeline's **front three phase-classes**, cleaved from the Verify + Authorize classes on the **pipeline-temporal cluster axis** (not on data-source homogeneity — the pipeline-event-log is the shared backbone for both clusters, so a source split does not cleave). The front cluster answers *"is work well-formed going IN"* (triageability, capacity-feasibility, implementation-readiness); the middle cluster ([`phase-telemetry-middle-cluster.md`](phase-telemetry-middle-cluster.md)) answers *"is built work sound coming OUT"*. The two files build in parallel on disjoint surfaces (the makespan reason for the fission); they share this identical anatomy (DORA/close-class read-model shape, N/A discipline, failure-mode shape) and a cross-reference stanza (§ 13). The split is CHEAP-reversible — re-merge to one file if fragmentation ever bites.

## 7. Computation tool

Reference implementation: [`release/tools/compute-front-cluster-telemetry.sh`](../../tools/compute-front-cluster-telemetry.sh).

**Form factor:** a wrapper composing over [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) (the event reads) plus a thin best-effort `gh` read for the one gh-sourced gauge. It mirrors the [`compute-dora-metrics.sh`](../../tools/compute-dora-metrics.sh) / [`compute-close-class-telemetry.sh`](../../tools/compute-close-class-telemetry.sh) form factor and exit-code contract: `set -euo pipefail`, PATH pinned to system tools, `/usr/bin/python3` stdlib only, a built-in `--self-test`, a `--json` detail mode, a `--window N` (trailing N distinct versions), a `--indicator <name>` single-indicator mode, and the 0/1/2 exit-code semantics. The nine BUILD indicators are computed in a single python pass over the event stream; the POINTER indicators emit their pointer string; the NARROWED emits its determination record (a literal here — I3 has no presence source to read; § 4 I3); the DEFER indicators emit their record.

**CLI:**

```bash
./compute-front-cluster-telemetry.sh                       # human block, all events
./compute-front-cluster-telemetry.sh --window 5            # trailing 5 distinct versions
./compute-front-cluster-telemetry.sh --json                # JSON of all indicators
./compute-front-cluster-telemetry.sh --indicator plan-survival-rate   # single indicator
./compute-front-cluster-telemetry.sh --self-test           # validate logic, no network/gh
```

**Exit codes:**
- `0` — success (any indicator may legitimately produce N/A — empty population; a POINTER; a NARROWED presence; or a DEFER reason)
- `1` — invalid args / required dependency (`query-pipeline-event.sh` / `python3`) unavailable
- `2` — malformed source (a `ts_iso` parse failure — source-integrity violation; escalate)

**Manual-fill fallback:** if the tool cannot run at read time, the indicators may be computed by hand from the event stream + milestone state exactly as the DORA and close-class fields degrade gracefully — the standard and the convention bind either way.

## 8. Boundary statement (event-log READER; read-only; NOT calibration-data.md; NOT a schema write)

Front-cluster telemetry sources from the **pipeline-event-log** (plus one `gh` gauge). This is the deliberate boundary that distinguishes it from close-class telemetry (which sources filesystem registers + `gh` state). Three boundaries are load-bearing and were scope-locked at Collective Review:

1. **Read-model, not writer.** The read-model READS the event stream; it NEVER appends a front-cluster row back into `pipeline-event-log.md` (§ 3.2 / § 12 FM3).
2. **NOT `calibration-data.md`.** The AC's parenthetical "land in the `calibration-data.md` schema" was corrected at Collective Review: `calibration-data.md` is a boundary-keyed, dimension-agnostic **gate-outcome** surface ([`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) § Versioning, the v1.2 "**Calibration:**" bullet — *"the calibration row is boundary-keyed and dimension-agnostic"*) that structurally cannot host named per-phase read-models; the v3.34 pattern the AC invoked landed DORA as an **on-demand window read-model** and close-class as a RELEASE_LOG H4 field — not in `calibration-data.md`. This standard adopts the DORA window read-model surface.
3. **Schema READER (CIAC-1).** Every indicator sources from an EXISTING [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 subtype (+ `gh`). This standard defines no new event subtype and writes no schema — the 2 DEFER indicators are deferred *precisely because* building them would need a new signal, which is what keeps "no new schema" true. If a DEFER indicator is later promoted to BUILD, that promotion is where a co-write with the schema would bind — out of scope here.

## 9. Cutover / grandfather

**GRANDFATHER. No backfill.** Front-cluster telemetry is computed over windows going forward, from events emitted post-cutover. Pre-cutover windows are **excluded** — a window that predates consistent event emission yields N/A for the affected indicators (graceful degradation, not a gap to fill). No backfill of historical front-cluster metrics: reconstructing whether a historical triage round-tripped or a historical plan survived is unreliable (the event stream may have been sparsely emitted), so a backfilled value would be synthesized, not measured. The calibration population counts only non-N/A post-cutover reads. The window-over-window TREND read is meaningful only after ≥3 comparable windows accrue — the platform-wide N=3 calibration threshold ([`gate-evaluation-spec.md § Layer 3`](../../../core/schemas/gate-evaluation-spec.md)), inherited, not redefined.

## 10. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **INPUT** | Reporting a C3-rate / plan-survival-rate of `0.00` over an empty window | When a window contains zero `phase-a0-row` re-reviews (or zero planned subjects), do NOT report `0.00` — emit `N/A (no ... in window)` | Convenience collapse: "no C3 rows, so 0%". But `0.00` means "re-reviews ran and none challenged a premise" (a real clean-input SIGNAL); N/A means "no re-reviews to measure" (no population). Reporting an empty window as 0.00 fabricates a clean-input signal and biases any window-over-window trend toward false health | § 5 binds every BUILD rate's N/A to a zero-DENOMINATOR (empty population) and `0.00` to a non-empty population with a zero numerator; the tool emits `rate: null` → `N/A` for the empty case | Principal: checks the denominator first — zero re-reviews → `N/A`; ≥1 re-review, zero C3 → `0.00`. Junior: divides 0 by 0 → NaN or forces 0.00 → an un-instrumented window reads as "perfect input quality", masking that nothing was measured |
| FM2 | **PROC** | Polluting the plan-survival denominator with incidental stage-4 rows | When computing `plan-survival-rate`, do NOT count every subject with any event at stage 4 as "planned" — a `milestone:*` bundle row (I7's population) and a `re-review/phase-a0-row` (a re-review, not a plan) also occur at stage 4 | Stage 4 hosts multiple event kinds (per-issue planning decisions, bundle amendments, Phase-A0 re-reviews). Counting all stage-4 subjects inflates the denominator with non-plans and drags the survival rate toward a meaningless value | § 4 I6 binds the "planned" anchor to a per-issue `decision`-class event at stage 4, EXCLUDING `milestone:*` subjects and re-review rows; the tool filters `etype == "decision" and not subject.startswith("milestone:")` | Principal: anchors "planned" on the per-issue planning decision. Junior: `grep stage==4` → counts bundles and re-reviews as plans → the survival rate is diluted and non-comparable across windows |
| FM3 | **OUT** | Emitting a computed front-cluster metric back into the event log | When surfacing a front-cluster window, do NOT append a `phase-telemetry` (or any synthesized) row to `pipeline-event-log.md` — the read-model READS the event stream; it never writes to it | "It would be convenient to cache the computed rate as an event for the next reader." But a front-cluster metric is a FUNCTION of the events, not a primary observation; writing it back pollutes the append-only stream with derived data, double-counts on the next read, and violates the event-log "primary observations only" invariant (the same OUT boundary [`dora-telemetry.md § 10 FM3`](dora-telemetry.md) names) | § 3.2 + § 8 state read-model-only explicitly; the tool has no write path to the event log — it composes over the READ primitive (`query-pipeline-event.sh`) only | Principal: renders the block to stdout / the consumer surface; the event log is untouched. Junior: appends a `phase-telemetry/front-rollup` row "for caching" → the next window read re-aggregates the cached metric as if it were a primary event → the stream is corrupted |
| FM4 | **PROC** | Recomputing a POINTER metric inline | When populating I9 (capacity-overrun), I10 (file-contention), or I12 (adr-closure), do NOT re-implement the gate metric — emit the pointer; the metric is owned by [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) | The gate evaluator already computes `capacity_utilization`, `contention_density`, and `adr_closure` from its own sources (milestone counts, cross-issue file analysis, `adr`-label state). Recomputing here duplicates that logic and risks a producer/producer disagreement (two tools, two slightly-different capacity heuristics, two rates for the same bundle) | § 4 I9/I10/I12 fix these as POINTERs; the producing tool emits the pointer string and has no capacity/contention/adr code | Principal: emits `POINTER — gate-evaluation-spec.md Gate 3->4 Capacity utilization` and lets the gate own the value. Junior: re-implements the rolling-5 capacity heuristic in this tool → its number diverges from the gate's on the same bundle → two contradictory capacity readings in the corpus |
| FM5 | **INPUT** | Matching a classification by bare substring instead of by its structured token | When an indicator's numerator keys on a classification carried in a free-text payload (I8 / I14's C3), do NOT test `"C3" in payload` — match the structured token `class:C3`; the payload is prose up to 300 chars and will contain the letters incidentally | A classification and a mention of a classification are different observations. `class:C1; note: no C3-level challenge raised` is a row that explicitly did NOT challenge a premise; a substring test counts it as one. The defect is latent by construction — it fires only once real re-review rows accrue, i.e. exactly when the indicator first becomes useful, so a green run over a window with no re-reviews is no evidence at all for this path | § 4 I8's source note binds the match to the structured `class:C3` token (whitespace-tolerant, case-insensitive) per [`triage-design-rereview.md § 5`](triage-design-rereview.md); the tool implements it as a token regex and the self-test carries a `class:C1`-mentioning-C3 fixture row that fails a substring implementation | Principal: matches the token the schema defines, and writes the adversarial fixture (a row whose prose mentions the class it is not) at the same time as the matcher. Junior: greps for the letters, sees the fixture pass on rows where prose and class agree, and ships a numerator that inflates the moment a reviewer writes a sentence about C3 |
| FM6 | **PROC** | Ordering events by raw timestamp string instead of parsed datetime | When establishing "did X happen at/after Y" over event rows, do NOT compare the `ts` strings — parse once at ingest and compare `datetime` values; validating that a timestamp parses is not the same as ordering on it | Lexicographic order equals chronological order only under ONE fixed timestamp format. A fractional-second ISO stamp (`…:00.500Z`) parses cleanly, clears the exit-2 source-integrity gate, and then sorts BEFORE `…:00Z` because `.` < `Z` — so a later event is read as earlier. In this instrument that inverts a round-trip / escape / scope-break test and publishes a **fabricated clean signal**, the same outcome FM1 exists to prevent, reached through a wrong population rather than an empty one. It raises no error and the output looks healthy | The tool parses `ts` once at ingest, carries the `datetime` on the row, and every temporal comparison orders on it; `ts` is retained for display only. The self-test carries a discriminating same-second fixture (one Z-form row, one fractional-second row) that a raw-string implementation fails | Principal: treats "it parses" and "it orders" as two separate obligations, and tests the ordering with a fixture whose string order contradicts its true order. Junior: sees `parse_iso()` called on every row, concludes timestamps are handled, and compares the strings — correct on every canonical row and silently wrong on the first non-canonical one |

## 11. Consumers

| Consumer | Role |
|---|---|
| `release-planner` Mode B (durable release plan authoring) | Reads a front-cluster window for capacity/quality calibration once a window establishes (e.g., "plan-survival ~0.83; size the next bundle's scope-lock expectation accordingly") — wiring active post-trend (N=3 windows) |
| `pmo-qa-auditor` (phase-quality review) | Reads the front-cluster indicators as phase-quality signals — Demand triageability, Definition capacity-feasibility, Solution-design implementation-readiness — in a review |
| [`phase-telemetry-middle-cluster.md`](phase-telemetry-middle-cluster.md) | Sibling cluster (Verify + Authorize) — shared anatomy, disjoint phase surface; the two clusters compose into the full 5-phase phase-distinctive telemetry surface |
| [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) | Owns the three POINTER metrics (Gate 3→4 capacity + contention; Gate 5→6 ADR closure) — this standard POINTS to them, never recomputes |

## 12. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Window read-model model + OUT boundary | [`dora-telemetry.md`](dora-telemetry.md) § 3.1 / § 10 | The on-demand window surface + read-model-only OUT-class boundary this standard adopts verbatim |
| 4-way anti-overfit disposition template | [`close-class-telemetry.md`](close-class-telemetry.md) § 1.1 / § 4 | The BUILD / POINTER / NARROWED / DEFER disposition tiering this standard applies per indicator |
| Sibling cluster | [`phase-telemetry-middle-cluster.md`](phase-telemetry-middle-cluster.md) | Verify + Authorize — split on the cluster axis; identical anatomy |
| Source events schema (READ only) | [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 | Defines every event subtype this standard reads; this standard is a READER (CIAC-1), never writes it |
| Query primitive | [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) | Read helper; the compute tool composes over it |
| POINTER metric owner | [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) | Gate 3→4 capacity + contention; Gate 5→6 ADR closure — the POINTER targets |
| Re-review classification (C3 source) | [`triage-design-rereview.md`](triage-design-rereview.md) § 5 | The C1/C2/C3 classification the phase-a0 / phase-0.5 C3-rates read from the re-review row payload |
| Point scale rounding mode | [`bundle-composition-doctrine.md`](bundle-composition-doctrine.md) § 3 Step 5 | Owns the round-half-up definitional home (taken by reference; § 3.1) |
| Compute wrapper | [`compute-front-cluster-telemetry.sh`](../../tools/compute-front-cluster-telemetry.sh) | Reference implementation of § 4 indicator computation + § 3 format selection |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at the standards set |

## Version History

Tracked in git history.
