---
title: DORA Telemetry
purpose: K1 codified-knowledge standard defining how the four DORA delivery metrics (deployment frequency, lead time for changes, change failure rate, mean time to restore) are measured, formatted, and surfaced for the PMO platform — the workspace's DORA-4 instantiation, computed as a read-model over existing pipeline-event-log subtypes plus a thin commit-time read
type: standard
parallel_to: deployment-cycle-time.md (the sibling GO→deploy latency instrument; this standard's lead_time_for_changes is the DORA-canonical commit→deploy window — a SIBLING signal, disjoint anchor, never recomputed from it), release-velocity-tracking.md (the sibling release-bundle throughput instrument; both are read-models over the same event/source streams with the same N/A discipline, grandfather policy, and failure-mode shape)
reversibility: CHEAP (forward-only read-model; pre-cutover windows excluded; computes lazily from existing events; no event-log schema change, no master-table change — the whole instrument reverts with one commit)
consumers: "release/references/pipeline/stage-06-engineering.md §7 (lead-time commit-anchor note); release/references/pipeline/stage-12-execute.md §7 (deployment-frequency + lead-time T_DEPLOY anchor note); release/references/pipeline/stage-13-close.md §7 (CFR + MTTR rollback-event note); release-planner Mode B (capacity calibration once a window establishes); pmo-qa-auditor (decision-outcome / deployment-quality review)"
version: v1.00
---
<!-- reference-durability: allow-link -->

# DORA Telemetry

## 1. Purpose

DORA telemetry = the four DORA delivery metrics computed as a read-model over the PMO platform's own release pipeline:

1. **deployment_frequency** — how often the platform deploys (deploy events per calendar interval).
2. **lead_time_for_changes** — the elapsed time from a change's commit to its deploy (the DORA-canonical commit→deploy window).
3. **change_failure_rate** — the fraction of deploys that required a remediation (rollback).
4. **mean_time_to_restore** — the mean elapsed time from a failure signal to its restoration.

Prior to this standard, the platform measured one deployment-phase latency (deployment cycle time = Stage 9 GO → Stage 12 completion) and one release-bundle throughput (release velocity), but it had no machine-readable instantiation of the four DORA primitives as a coherent set. The underlying events already exist in the pipeline-event-log — `deployment-status/deploy-*` for the frequency and lead-time anchors, and `self-repair/rollback` for the failure/restore signals — but no read-model composed them into the DORA-4 frame. This standard codifies the four metrics' definitions, their event sources (all EXISTING subtypes — zero new event types), their computation, the explicit N/A semantics for each, and the surfacing convention, so the DORA-4 set is produced consistently and consumed deterministically by downstream read-models (release-planner Mode B; pmo-qa-auditor deployment-quality review).

**Scope:** the four DORA metrics computed over a bounded version/time window from existing pipeline-event-log events (`deployment-status/deploy-skill` + `deploy-harness` as the deploy anchor; `self-repair/rollback` as the failure/restore signal) plus a thin `git log --format=%cI` read for the commit-time numerator of lead time. Read-model only — the computation reads the event stream; it NEVER emits a row back into it.

**Out of scope:** the GO→deploy deployment-cycle-time window (the disjoint sibling instrument — see § 6); release-bundle throughput / velocity (the disjoint sibling instrument); per-skill propagation latency (sub-event resolution); the fifth-and-later DORA "reliability" metric families (availability, SLO-attainment) — the platform has no SLO surface to measure them against, so they are N/A-until-source-exists and not computed here.

## 2. What is measured

Each metric sources its anchors from existing pipeline-event-log subtypes (schema-locked per [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 2-3) plus, for lead time only, a commit-time read from git.

| Metric | Anchor event(s) | Event subtype(s) | Numerator / denominator | Source actor |
|---|---|---|---|---|
| **deployment_frequency** | `deployment-status` | `deploy-skill` OR `deploy-harness` | count of DISTINCT deploy occasions ÷ window length (calendar interval) | `hub` (per-target emit during `core/deploy/deploy.sh --deploy`) |
| **lead_time_for_changes** | `deployment-status` (T_DEPLOY) + git commit-time (T_COMMIT) | `deploy-skill` OR `deploy-harness` | `T_DEPLOY − T_COMMIT` per deploy, summarized as the window median | `hub` (deploy) + git (`%cI` committer-date) |
| **change_failure_rate** | `deployment-status` + `self-repair` | `deploy-skill`/`deploy-harness` (deploys) + `rollback` (failures) | rollback-correlated deploys ÷ total deploys in window | `hub` (deploy) + `operator` (rollback) |
| **mean_time_to_restore** | `self-repair` | `rollback` | mean(`T_RESTORE − T_FAILURE`) over rollback pairs in window | `operator` (rollback authorized post-regression) |

All event anchors source the `ts_iso` field (ISO8601 UTC; schema-locked per [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 2 field 1). The commit-time anchor sources git's committer-date (`%cI`, strict-ISO8601) — chosen over author-date (`%aI`) because committer-date reflects when the change entered the integration history (the DORA "change" boundary), not when it was first written.

### 2.1 Selection rules

- **deployment_frequency** — count DISTINCT deploy occasions, NOT raw `deploy-*` rows. A single release emits one `deploy-skill`/`deploy-harness` row per affected target per [`stage-12-execute.md`](../pipeline/stage-12-execute.md) § Phase B; those rows share a near-coincident `ts_iso` cluster and a common release version. The frequency unit is the deploy OCCASION (one release's Stage 12 deploy beat), resolved by collapsing same-version deploy rows to one occasion — NOT one increment per target (see § 10 FM2).
- **lead_time_for_changes** — per deploy occasion, `T_DEPLOY` = `MAX(ts_iso)` of the occasion's `deploy-*` rows (the last target to land anchors completion, consistent with deployment-cycle-time.md § 2.1); `T_COMMIT` = the committer-date of the FIRST commit in the deployed range (the earliest change the deploy carried). The window summary is the **median** of the per-occasion lead times, not the mean — lead time is right-skewed (a few long-gestation changes distort a mean), and DORA itself reports lead-time as a banded median.
- **change_failure_rate** — a deploy occasion is "failed" iff a `self-repair/rollback` event correlates to it (same release version, OR a `rollback` whose `ts_iso` falls in the occasion's post-deploy window before the next deploy occasion). CFR = failed occasions ÷ total occasions in window.
- **mean_time_to_restore** — pair each `self-repair/rollback` event with its triggering failure signal; `T_RESTORE` = the rollback `ts_iso`, `T_FAILURE` = the `ts_iso` of the deploy occasion the rollback remediates (the failure surfaced no earlier than that deploy). MTTR = mean of the per-pair deltas.

### 2.2 Delta computation

Lead-time and MTTR deltas are computed via ISO8601 datetime subtraction (Python 3.9+ `datetime.fromisoformat(...)` arithmetic, the same portability tier as [`compute-cycle-time.sh`](../../tools/compute-cycle-time.sh)). Frequency and CFR are integer-count ratios.

## 3. Unit / Format

- **deployment_frequency:** `<N> deploys / <window>` (e.g., `4 deploys / 30d`), plus the derived cadence label `daily` / `weekly` / `monthly` for at-a-glance reading.
- **lead_time_for_changes:** the window median in the same compact `<X>m` / `<H>h<M>m` / `<D>d<H>h` form deployment-cycle-time.md § 3 uses for sub-hour/over-hour values, extended with a `<D>d` day unit because lead time routinely spans days where cycle time spans minutes.
- **change_failure_rate:** a percentage to one decimal (e.g., `12.5%`), with the raw `<failed>/<total>` occasion counts in a parenthetical.
- **mean_time_to_restore:** the same compact duration form as lead time (`<X>m` / `<H>h<M>m` / `<D>d<H>h`).
- **Field name:** `DORA:` — TitleCase, matching the established field-naming convention. The four metrics render as labelled sub-signals inside one block (see § 3.1), mirroring how release-velocity-tracking.md carries five sub-signals under one `**Velocity:**` field.

### 3.1 Surface

DORA telemetry is a **window read-model, not a per-release visible-H4 field.** Unlike `Cycle-Time:` and `Velocity:` (one value per release, surfaced in that release's `#### Deployment Log` block), the four DORA metrics are only meaningful over a window of multiple deploys — a single release has no "frequency" and a one-deploy CFR is 0% or 100% with no signal. Therefore DORA telemetry is computed ON DEMAND over a window by the computation tool (§ 7) and surfaced where a window read-model belongs — a release-planner capacity-calibration read, a pmo-qa-auditor deployment-quality assessment, an operator's periodic health read — NOT appended to any single release's RELEASE_LOG row.

**This is the load-bearing OUT-class boundary:** the DORA read-model reads the event log; it NEVER writes a DORA row back into `pipeline-event-log.md` (see § 10 FM3). Emitting a derived DORA metric as an event would corrupt the event stream's "primary observations only" invariant — the metric is a function OF the events, not itself an event.

**Default emit (human-readable, non-N/A):**

```
DORA (window=30d, ending 2026-XX-XX):
  deployment_frequency:  4 deploys / 30d (weekly)
  lead_time_for_changes: 2d4h (median over 4 deploys)
  change_failure_rate:   25.0% (1/4 occasions)
  mean_time_to_restore:  3h12m (mean over 1 rollback)
  mechanism: compute-dora-metrics.sh
```

**Per-metric N/A is independent** — see § 4. A window with zero rollbacks renders `change_failure_rate: 0.0% (0/4 occasions)` (a real zero, NOT N/A — see § 4) and `mean_time_to_restore: N/A (no rollback events in window)`.

## 4. N/A semantics (per-metric, independent)

Each of the four metrics resolves its own N/A independently — a window can yield a real value for some metrics and N/A for others. N/A is never blank-fill; it carries a parenthetical reason.

| Metric | N/A condition | Real-zero condition (NOT N/A) |
|---|---|---|
| **deployment_frequency** | zero `deploy-skill`/`deploy-harness` events in window → `N/A (no deploy events in window)` | n/a — zero deploys is N/A, not a zero rate, because "0 deploys / 30d" is the absence of the measured population, not a measured cadence |
| **lead_time_for_changes** | zero deploy occasions, OR no resolvable commit-time for any occasion → `N/A (no deploy occasion with a resolvable commit anchor)` | n/a |
| **change_failure_rate** | zero deploy occasions in window (denominator undefined) → `N/A (no deploy occasions — denominator undefined)` | **zero rollbacks WITH ≥1 deploy occasion → `0.0%` is a REAL value, not N/A** — a window that deployed and had no failures genuinely has a 0% failure rate |
| **mean_time_to_restore** | zero `self-repair/rollback` events in window → `N/A (no rollback events in window)` | n/a — MTTR over zero restores is undefined, not zero (there is no restoration time to average) |

**The CFR zero-vs-N/A distinction is the load-bearing one** (see § 10 FM1): a window with deploys and no rollbacks has CFR = 0.0% (signal: clean window). A window with NO deploys has CFR = N/A (no denominator). Conflating them — reporting N/A as 0%, or 0% as N/A — either fabricates a clean-window signal or discards one.

**Explicit-N/A discipline:** every metric in a rendered DORA block is present with either a value or `N/A (reason)`. A missing metric line is a tool defect, not a silent N/A. The four metrics are independently resolvable, so a partial block (3 values + 1 N/A) is the normal case, not a degraded one.

**Pre-cutover / instrumentation-gap interaction:** until `deployment-status/deploy-*` and `self-repair/rollback` events are consistently emitted to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md), a window will yield `N/A` for the affected metrics regardless of whether deploys/rollbacks actually occurred. This is graceful degradation (no false signal); the metrics fill lazily as the instrumentation populates.

## 5. Baseline / window mechanism

DORA metrics are **window read-models** — they do not establish a single rolling baseline value the way deployment-cycle-time.md does. The "baseline" for DORA is the chosen window itself (e.g., trailing 30 days, or trailing N deploy occasions). Per the platform calibration discipline ([`gate-evaluation-spec.md § Layer 3 Calibration`](../../../core/schemas/gate-evaluation-spec.md)), a window-over-window TREND read is meaningful only after ≥3 comparable windows exist:

| Phase | Trigger | Action |
|---|---|---|
| **Pre-trend** | Fewer than 3 comparable closed windows of DORA data | Each window read renders the four current values; no window-over-window comparison. |
| **Trend establishment** | 3 comparable windows accrue (N=3) | A window-over-window delta may be reported (e.g., "deployment_frequency up from 3 to 4 deploys/30d across the last 3 windows"); the comparison is rendered by the consumer, not embedded in the event log. |
| **Post-trend** | ≥3 windows | Consumers (release-planner Mode B) may read the trend for capacity calibration. |

**N=3 rationale:** aligns with the platform-wide calibration threshold ([`gate-evaluation-spec.md § Layer 3`](../../../core/schemas/gate-evaluation-spec.md) — "when ≥ 3 records exist: include historical comparison"), the same threshold deployment-cycle-time.md and release-velocity-tracking.md inherit. DORA telemetry does not invent a private threshold.

**No baseline FILE is created by this standard.** Unlike `cycle-time-baseline.md` (a single rolling-3 median that lazily materializes), DORA has no single value to persist — it is recomputed on demand over the requested window. A future trend-detection consumer MAY persist a window-series, but that is out of scope here.

## 6. DORA alignment + the deployment-cycle-time sibling boundary

This standard IS the workspace's DORA-4 instantiation — it adopts the four DORA metric DEFINITIONS directly (deployment frequency, lead time for changes, change failure rate, mean time to restore per Forsgren/Humble/Kim, *Accelerate*, 2018; DORA State of DevOps Report, annual). It does NOT adopt DORA's industry benchmark BANDS (Elite/High/Medium/Low) as platform thresholds — a single-operator self-building platform is not the multi-team SaaS context those bands were calibrated for; the bands would mis-signal. DORA is an informational citation only and is NOT added to [`upstream-reference-catalog.md`](../../../core/standards/upstream-reference-catalog.md) (scope excludes external benchmarks, consistent with deployment-cycle-time.md § 6).

**The lead-time sibling boundary (load-bearing).** `lead_time_for_changes` here measures the **DORA-canonical commit→deploy window** (`T_COMMIT → T_DEPLOY`). This is a SIBLING to deployment-cycle-time.md's **GO→deploy window** (`T_GO → T_DEPLOY`), NOT a duplicate and NOT a recomputation of it:

| Instrument | Window | What it isolates |
|---|---|---|
| `deployment-cycle-time.md` (`Cycle-Time:`) | Stage 9 GO → Stage 12 deploy (`T_GO → T_DEPLOY`) | the human decision-to-deploy latency (process-discipline drift) |
| this standard (`lead_time_for_changes`) | first commit → Stage 12 deploy (`T_COMMIT → T_DEPLOY`) | the engineering-cycle latency (work complexity + integration lag) — the DORA-canonical "change" boundary |

The two windows share the `T_DEPLOY` anchor (both source `MAX(ts_iso)` of the occasion's `deploy-*` rows) but differ in their start anchor — GO (a gate-outcome event) vs first-commit (a git committer-date). deployment-cycle-time.md § 6 already names this distinction ("DORA measures from commit; this standard measures from Stage 9 GO … the narrower window is intentional"); this standard supplies the commit-anchored half it deferred. **Neither recomputes the other** — they read different start anchors and answer different questions. A consumer wanting both reads both; this standard does not import the GO→deploy value.

## 7. Computation tool

Reference implementation: [`release/tools/compute-dora-metrics.sh`](../../tools/compute-dora-metrics.sh)

**Form factor:** a wrapper composing over [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) (the deploy + rollback event reads) plus a thin `git log --format=%cI` read for the commit-time numerator of lead time. It mirrors the [`compute-cycle-time.sh`](../../tools/compute-cycle-time.sh) form factor and exit-code contract: `set -euo pipefail`, PATH pinned to system tools, `/usr/bin/python3` stdlib only, a built-in `--self-test`, and the same 0/1/2 exit-code semantics.

**Why wrapper, not extension:** extending `query-pipeline-event.sh` with DORA aggregation would change its contract (currently a pure filter; proposed: filter + multi-metric arithmetic + git read). DORA computation is a downstream read-model on top of the filter primitive — keeping the primitive small preserves its reuse for the other read-models on the same stream (cycle-time, velocity, synthesizer). The git commit-time read is a thin addition the wrapper owns; the event reads delegate to the primitive unchanged.

**CLI:**

```bash
./compute-dora-metrics.sh --window 30d              # human-readable four-metric block
./compute-dora-metrics.sh --window 30d --json       # machine detail: JSON of all four metrics + N/A reasons
./compute-dora-metrics.sh --window-occasions 10     # window by trailing N deploy occasions instead of days
./compute-dora-metrics.sh --metric deployment_frequency --window 30d   # single metric only
./compute-dora-metrics.sh --self-test               # validate logic, no network/git dependency
```

**Exit codes:**
- `0` — success (any metric may legitimately produce N/A — empty population for that metric; or a legitimate real-zero CFR)
- `1` — invalid args / log file missing / required dependency unavailable
- `2` — malformed source (a `ts_iso` parse failure, or a `%cI` commit-time parse failure — source-integrity violation; escalate)

## 8. Consumers

| Consumer | Today | Future |
|---|---|---|
| `release-planner` Mode B (durable release plan authoring) | Reads a DORA window for capacity calibration (e.g., "median lead time ~2d4h; size the next bundle's commit-to-deploy expectation accordingly") — wiring deferred until a window establishes | Active downstream consumer post-trend (N=3 windows) |
| `pmo-qa-auditor` (decision-outcome / deployment-quality review) | Reads CFR + MTTR as deployment-quality signals in a review | Active downstream consumer |
| Future trend-detection automation | Post-trend; window-over-window series; not in current scope | Active downstream consumer after ≥3 comparable windows establish |

## 9. Cutover

**Applies to:** DORA metrics are computed over windows going forward, from events emitted post-cutover. The metrics first yield non-N/A values once the `deployment-status/deploy-*` and `self-repair/rollback` events are consistently emitted across a window's worth of releases.

**Pre-cutover windows:** excluded. No backfill of historical DORA metrics — a window that predates consistent event emission yields N/A for the affected metrics (graceful degradation, not a gap to fill).

**Window-trend trigger:** deferred until 3 comparable windows of post-cutover DORA data accrue (§ 5). Cannot be predicted — depends on release cadence and the resolution of the instrumentation gap (§ 4).

## 10. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **INPUT** | Computing change_failure_rate over a pre-cutover or empty-deploy window | When a window contains zero `deploy-skill`/`deploy-harness` occasions (pre-instrumentation, or a content-only stretch), do NOT report `change_failure_rate: 0.0%` — emit `N/A (no deploy occasions — denominator undefined)` | Convenience collapse: "no failures, so 0%". But 0% means "deployed and nothing broke" (a clean-window SIGNAL); N/A means "nothing deployed to measure" (no population). Reporting an empty window as 0% fabricates a clean-window signal and biases any window-over-window trend toward false health | This standard § 4 binds CFR's N/A to a zero-DENOMINATOR (zero occasions), and binds `0.0%` to ≥1 occasion with zero rollbacks; § 2.1 defines the occasion population explicitly | Principal: checks the denominator first — zero occasions → `N/A (no deploy occasions)`; ≥1 occasion, zero rollbacks → `0.0%`. Junior: reports 0% for any window without a rollback row → an instrumentation-gap window reads as "perfect deployment health", masking that nothing was measured |
| FM2 | **PROC** | Counting per-target deploy rows as frequency increments | When computing deployment_frequency, do NOT count each `deploy-skill`/`deploy-harness` ROW as one deploy — collapse same-version (same release occasion) rows to ONE occasion | A single release emits one `deploy-*` row per affected target (per stage-12-execute.md § Phase B); a 6-skill release emits 6 rows for ONE deploy occasion. Counting rows inflates frequency 6× and makes a wide release look like high cadence | This standard § 2.1 defines the frequency unit as the deploy OCCASION (same-version row collapse), NOT the raw row; the computation tool groups by version before counting | Principal: groups `deploy-*` rows by release version, counts DISTINCT occasions. Junior: `grep -c deploy-skill` → reports 6 deploys for one release → deployment_frequency is N× too high, every wide release reads as a cadence spike |
| FM3 | **OUT** | Emitting a computed DORA metric back into the event log | When surfacing a DORA window, do NOT append a `dora-metric` (or any synthesized) row to `pipeline-event-log.md` — DORA is a read-model that READS the event stream; it never writes to it | "It would be convenient to cache the computed metric as an event for the next reader." But a DORA metric is a FUNCTION of the events, not a primary observation; writing it back pollutes the append-only stream with derived data, double-counts on the next read (the cached row would itself be re-aggregated), and violates the event-log "primary observations only" invariant | This standard § 1 scope + § 3.1 state read-model-only explicitly; the computation tool has no write path to the event log — it composes over the READ primitive (`query-pipeline-event.sh`) and a read-only `git log` | Principal: renders the DORA block to stdout / the consumer surface; the event log is untouched. Junior: appends a `release-synthesis/dora-rollup` row "for caching" → the next window read re-aggregates the cached metric as if it were a deploy event → frequency and lead-time double-count, the stream is corrupted |
| FM4 | **INPUT** | Anchoring lead-time on author-date or on the wrong commit | When computing `lead_time_for_changes`, do NOT use git author-date (`%aI`) and do NOT anchor on the LAST commit in the range — use committer-date (`%cI`) of the FIRST (earliest) commit the deploy carried | Author-date is when the change was first WRITTEN (can predate integration by weeks for a long-lived branch); the DORA "change" boundary is when it entered the integration history (committer-date). Anchoring on the last commit measures only the final touch, not the change's full gestation | This standard § 2 binds T_COMMIT to `%cI` committer-date; § 2.1 binds it to the FIRST commit in the deployed range (the earliest change the deploy carried) | Principal: reads `%cI` of the earliest commit in the deployed range as T_COMMIT. Junior: uses `%aI` of HEAD → a rebased / long-branched change reports a multi-week lead time that reflects authoring lag, not delivery latency → the lead-time median is inflated and non-comparable |

## 11. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Source events schema | [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 2-3 | Defines `ts_iso`, the `deployment-status/deploy-skill` + `deploy-harness` subtypes, and the `self-repair/rollback` subtype this standard reads |
| Event capture surface | [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) | Append-only event stream; the read-model's data source (read-only — never written by this standard) |
| Query primitive | [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) | Read helper; `compute-dora-metrics.sh` composes over it for the deploy + rollback reads |
| Compute wrapper | [`compute-dora-metrics.sh`](../../tools/compute-dora-metrics.sh) | Reference implementation of the four-metric computation + format selection |
| Sibling latency instrument | [`deployment-cycle-time.md`](deployment-cycle-time.md) | The GO→deploy window; this standard's `lead_time_for_changes` is the SIBLING commit→deploy window (§ 6) — disjoint anchor, never recomputed from it |
| Sibling throughput instrument | [`release-velocity-tracking.md`](release-velocity-tracking.md) | The release-bundle throughput read-model; this standard mirrors its N/A discipline, grandfather policy, and failure-mode shape |
| Calibration threshold | [`gate-evaluation-spec.md § Layer 3 Calibration`](../../../core/schemas/gate-evaluation-spec.md) | N=3 window-trend rule (inherited, not redefined) |
| Stage 6 lead-time anchor | [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) | T_COMMIT source — the first commit on the release branch (lead-time numerator) |
| Stage 12 deploy anchor | [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) | T_DEPLOY + frequency source — hub-emitted `deploy-*` events at Phase B |
| Stage 13 rollback anchor | [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) | CFR + MTTR source — `self-repair/rollback` events (post-merge regression remediation) |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags (TRIG / INPUT / PROC / OUT / HAND) |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at `core/standards/` and `release/references/standards/` |

## Version History

Tracked in git history.
