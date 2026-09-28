---
title: Deployment Cycle Time
purpose: K1 codified-knowledge standard defining how deployment cycle time (Stage 9 GO → Stage 12 completion) is measured, formatted, surfaced in RELEASE_LOG.md, and baselined for the PMO platform
type: standard
parallel_to: gate-evaluation-spec.md (calibration-data surface for gate-boundary cycles; this standard's cycle is the disjoint deployment-cycle class)
reversibility: CHEAP (forward-only metric; pre-cutover releases exempt; baseline establishes lazily)
consumers: "release/governance/release-process.md Stage 12 § Phase B5 emit format; release-planner Mode B (capacity calibration); automated-closeout.sh (cycle-time read consumer); synthesize-release-learnings.sh (cross-release synthesizer); pmo-qa-auditor (decision-outcome review)"
version: v12.12
---
<!-- reference-durability: allow-link -->

# Deployment Cycle Time

## 1. Purpose

Deployment cycle time = elapsed time between Stage 9 GO authorization and Stage 12 completion of skill / harness deploys. Establishes the baseline + variance signal the platform needs to detect Stage 9 → Stage 12 process-discipline drift and inform capacity planning.

Prior to this standard, no machine-readable cycle-time metric existed for the deployment phase. Stage 9 GO was a free-form issue comment; Stage 12 completion was a `Timestamp:` line in the visible-H4 Deployment Log block. Computing the delta required manual inspection per release with no consistent reporting surface. This standard codifies the formula, the units, the RELEASE_LOG surfacing convention, and the N=3 baseline trigger so the metric is both produced consistently per release and consumed deterministically by downstream read-models (release-planner Mode B, automated-closeout.sh, release-synthesizer).

**Scope:** Stage 9 GO timestamp → latest Stage 12 deploy-skill / deploy-harness event timestamp, derived from existing pipeline-event-log events. Content-only / governance-only releases that emit no deploy-skill or deploy-harness events record `Cycle-Time: N/A` and are excluded from baseline computation.

**Out of scope:** Engineering-cycle latency (Stage 6 → Stage 12 — DORA "lead time for changes" approximation); deployment frequency (deploys per calendar interval); per-skill propagation latency (sub-event resolution). These are derivable from the same underlying event stream but require their own metric specs.

## 2. What is measured
<!-- design-artifact: flow-class=data-flow; name=cycle-time-anchor-identity; depicts=release/tools/compute-cycle-time.sh,release/tools/append-pipeline-event.sh,release/references/standards/pipeline-event-log-schema.md,release/references/pipeline/stage-09-plan-review.md,release/references/pipeline/stage-12-execute.md -->

Cycle time = `T_DEPLOY - T_GO`, where:

| Anchor | Event type | Event subtype | Source actor | Reference |
|---|---|---|---|---|
| **T_GO** (Stage 9 GO timestamp) | `gate-outcome` | `plan-review-go` | `operator`, at stage `9` — the only (stage, actor) the writer admits for this subtype (renders the GO decision after PR diff review) | [`release/references/pipeline/stage-09-plan-review.md`](../pipeline/stage-09-plan-review.md) |
| **T_DEPLOY** (Stage 12 completion timestamp) | `deployment-status` | `deploy-skill` OR `deploy-harness` | `hub` (per-target emit during `core/deploy/deploy.sh --deploy`) | [`release/references/pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) |

Both anchors source the `ts_iso` field (ISO8601 UTC timestamp; schema-locked per [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 2 field 1).

### 2.1 Selection rule

- **T_GO** = the earliest (`MIN(ts_iso)`) row of the release's **Stage-9 GO identity**: `event_type=gate-outcome`, `event_subtype=plan-review-go`, `stage=9`, `actor=operator`. The subtype alone does not identify the GO: before the writer enforced this identity, `plan-review-go` was also written for Stage-7 and Stage-8 verdicts, Stage-4 plan approvals, Stage-12 execute authorizations and stage-completion notes, and MIN over the subtype anchored T_GO on the earliest of them — a too-early T_GO yields a positive, plausible, inflated duration that no check flags. Those historical rows stay in the append-only log and are inert to this rule. A release normally carries exactly one row of this identity — multi-PR releases coalesce to a single GO decision per [`release/governance/release-process.md`](../../governance/release-process.md) Stage 9 — and when a GO is re-rendered the earliest still anchors, so re-authorization time counts as the Stage 9 → Stage 12 friction this metric exists to show. A release with no row of this identity reads `N/A` with its own reason even when rows of the subtype exist under another stage or actor; a subtype fallback would re-admit the defect.
- **T_DEPLOY** = latest (`MAX(ts_iso)`) `deployment-status` event with `event_subtype=deploy-skill` OR `deploy-harness` **and `outcome=resolved`** for the release. Multi-skill releases emit one row per affected target per [`release/references/pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) § Phase H; the LAST resolved emission anchors Stage 12 completion. The schema's other three `deployment-status` subtypes never anchor: a `deploy-package` row records a distribution-artifact copy, not runtime propagation; a `deploy-rules-mirror` row is written once per release-stamped deploy whether or not a rule changed; `deploy-helper` has no producer. § 4 names each of them in the N/A reason rather than dropping it. The mirror row is not admitted for a forward-looking reason: the rules-mirror carrier writes one row on every release-stamped invocation — `resolved` when the mirror copy succeeds, `escalated` when it fails — so admitting it would make every stamped content-only release whose mirror copy succeeded compute, which § 4 excludes from the baseline. The cost is stated rather than hidden. A release whose change did reach the runtime, but whose only `deployment-status` rows are of excluded subtypes, reads `N/A` with those rows named: a false negative, never a wrong value. The known instances are `v4.54`, `v4.55`, `v4.58` and `one-system-of-record-per-element`.

### 2.2 Delta computation

`cycle_time_seconds = (T_DEPLOY - T_GO)` via ISO8601 datetime subtraction. Reference implementation: Python 3.9+ `datetime.fromisoformat(...).timestamp()` arithmetic (same portability tier as `block-rm-prefer-trash.sh` realpath per [`core/rules/bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md)).

## 3. Unit / Format

- **Internal:** integer seconds (Python `datetime` subtraction → `total_seconds()`).
- **Display format:** `<X>m` when seconds < 3600; `<H>h<M>m` when seconds ≥ 3600. Examples: `47m`, `2h17m`, `0m` (sub-minute, valid).
- **Rationale:** Compact human-readable form matching GitHub's commit-time UI convention. Operators read `2h17m` on sight without ISO 8601 duration parsing. Alternative `HH:MM` form (e.g., `0:47` / `2:17`) was considered and rejected — ambiguous between hours-minutes and minutes-seconds for sub-hour values.
- **Field name:** `Cycle-Time:` — TitleCase-hyphen, matching the established visible-H4 sibling-field convention (`Deployed at:`, `Merge commit SHA:`, `Phase A.5 main-divergence pre-check:`, `Timestamp:`, `Result:`).

### 3.1 RELEASE_LOG.md surface
<!-- design-artifact: flow-class=data-flow; name=cycle-time-na-reason-carriage; depicts=release/tools/compute-cycle-time.sh,release/tools/automated-closeout.sh,release/references/pipeline/stage-12-execute.md -->

The cycle-time field lands as a sibling field inside the visible-H4 `#### Deployment Log v<X.Y>` block per D-RELEASE_LOG-Field-Placement (B) — NOT as a main-table column. Field position: after `**Timestamp:**` line (latest-emitted field; matches the "last event in Stage 12" semantic).

**Default emit (non-N/A, pre-baseline):**

```markdown
**Cycle-Time:** 47m  (T_GO=2026-XX-XXT14:22:01Z → T_DEPLOY=2026-XX-XXT15:09:34Z; mechanism: compute-cycle-time.sh)
```

**N/A (any cause):**

```markdown
**Cycle-Time:** N/A (<compute-cycle-time.sh's own reason, verbatim — § 4 lists the causes>)
```

**Post-baseline (N ≥ 3) with comparison:**

```markdown
**Cycle-Time:** 47m (-12% vs 53m baseline)  (T_GO=...; T_DEPLOY=...; mechanism: compute-cycle-time.sh; baseline=cycle-time-baseline.md@<sha>)
```

Emit mechanism: Stage 12 spoke invokes [`compute-cycle-time.sh <version>`](../../tools/compute-cycle-time.sh) at Phase B5 and embeds the returned value into the visible-H4 emit. Per Stage 12 chore-PR convention, the field lands on main via the `chore/vX.Y-stage-12-release-log` PR, never direct-to-main.

When the value is `N/A`, the field carries the tool's own N/A line verbatim — the text `compute-cycle-time.sh --version <the RELEASE_LOG row's Version cell>` prints on stderr after its `Cycle-Time: ` prefix, naming each missing anchor's cause (§ 4) — and never a hand-written cause phrase. The key is pinned because the reason names it: a line produced under the milestone slug differs from the Version-keyed one in that token. Commentary belongs in `**Result:**` or the release notes. At close, `automated-closeout.sh` re-runs the tool under the same key, carries the same value or verbatim reason into its report, JSON report and chore-PR body, and reports whether this field begins with it: `CONFORMANT`, `DIVERGENT`, `ABSENT` or `NOT-EVALUATED`. `DIVERGENT` records a disagreement between the field and the tool's value at close, with the tool's `--iso` anchors beside it, and never a finding against the field: a hand-written release-level row typed as a deploy can anchor the tool, so either side can be the wrong one. The close-out does not rewrite the field.

| Producer | What it emits | Consumer | Where it lands |
|---|---|---|---|
| `compute-cycle-time.sh` stdout | the value: `<X>m`, `<H>h<M>m` or `N/A` | the Stage 12 Phase B5 author; `automated-closeout.sh` `read_state` | this field; the close-out report, JSON report and chore-PR body |
| `compute-cycle-time.sh` stderr | on `N/A` only, one line `Cycle-Time: N/A (<reason>)` | the same two consumers | this field, verbatim after the prefix; the same close-out surfaces |
| `automated-closeout.sh` `read_state` | the field verdict, and a NOT-EVALUATED result when the tool could not measure | the operator at close | the report's phase row, with its detail; the chore-PR body, as the verdict's class and the result's class and exit code only |

## 4. N/A semantics

Releases whose `T_DEPLOY` cannot be anchored — no resolved `deploy-skill` / `deploy-harness` event — record `Cycle-Time: N/A` and are explicitly excluded from baseline computation. `compute-cycle-time.sh` reports each such release under exactly ONE of three causes, in one reason:

| Cause | The release's `deployment-status` rows | The reason says |
|---|---|---|
| **None** | none at all — a content-only release deployed without a release stamp, or not yet deployed, or a release whose change reached the runtime through a carrier that writes no `deployment-status` row (the hook tier and the composition surfaces, through `update.sh` or `setup-workspace.sh --refresh-hooks`) | `no deployment-status event for <release>` |
| **Failed** | ≥1 `deploy-skill` / `deploy-harness` row, none `outcome=resolved` | the non-resolved outcomes, then *the deploy ran and its targets did not succeed* — the only cause that says so |
| **Excluded** | rows exist, none of an anchor subtype | the anchor rule (§ 2.1), then each subtype present with its row count, its resolved / not-resolved tally and its producer — rows written by the deploy emitter, or hand-written — excluded by definition, not by target failure |

A release-stamped deploy of a content-only release is the **Excluded** case, not **None**: the rules-mirror carrier runs on every invocation and writes its one `deploy-rules-mirror` row before any skill, package or harness target, even on a run that then stops on a bad artifact name. An event log the tool cannot read is none of the three: the tool exits `1` (§ 7) and names no cause, because a read that never happened is not a measured absence.

**Rationale:** Cycle-time measures the operator-experienced latency of Stage 12 propagation for content that actually deploys. Content-only releases exercise a different latency profile (merge-only) that this metric is not designed to characterize. Conflating both classes would distort the baseline and produce misleading post-baseline comparisons.

**Explicit-N/A discipline:** `Cycle-Time: N/A` is not blank-fill. The field is present in every visible-H4 Deployment Log block; the value is `N/A` (with parenthetical reason) when source events are missing. Absence of the field on a post-cutover release is a Check 14 / Check 15 surfaceable defect.

**Anchor-absence interaction:** both anchors are emitted — T_DEPLOY by `core/deploy/deploy.sh --deploy --release <slug>` for skill and harness deploys, T_GO by the Stage 9 Plan Review spec's Phase C1 step, which records the GO/NO-GO verdict and its `gate-outcome` row as one action. A release still reads `Cycle-Time: N/A` when an anchor is absent for it — a release whose change reached the runtime only through a carrier that writes no `deployment-status` row is the **None** cause above — and its reason names the cause. An absent T_GO is reported at close by Check 61 (`deploy.sh --check-decision-emission`, advisory), which asserts at least one `plan-review-go` row per post-cutover VERIFIED release at any stage or under any actor; the stage-`9` `operator` identity is held by Phase C1's typed read-back and by the writer. An absent anchor is recorded, never backfilled: T_GO and T_DEPLOY are their rows' own timestamps, so a row written after the event anchors the metric on the wrong instant (FM1).

### 4.1 `Cycle-Time: N/A` is a known, documented state (not a data-quality defect)

`Cycle-Time: N/A` in a Deployment Log block means a cycle-time anchor could not be resolved, and its reason names which cause applies — the T_GO half and the T_DEPLOY half (§ 4) each carry their own. It is a real, final value, not a gap: the `deployment-status` emitter exists (`core/deploy/deploy.sh --deploy --release <slug>` writes one row per deployed target, plus the rules-mirror carrier's one row per invocation), so an N/A is no longer structural for every release. One carve-out stays structural: a release whose change reached the runtime only through a carrier that writes no `deployment-status` row — the hook tier and the composition surfaces — has no T_DEPLOY row to anchor on, and reads the **None** cause. An N/A MUST NOT be read as a missing measurement, backfilled, estimated, or re-anchored on a subtype § 2.1 excludes.

The § 5 baseline counts non-N/A values only: an N/A release neither enters the rolling window nor shifts it.

**Scope note.** The decision-telemetry join key ([`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 2a) and the minimum-emission gate (`deploy.sh --check-decision-emission`, Check 61) do **NOT** address this. They govern **decision** events; the `deployment-status` rows come from the deploy emitter named above. `--check-decision-emission` deliberately does not assert `deployment-status` — it is not a `MUST` row of the orchestration playbook's `EMISSION-CONTRACT` block, and asserting a class the playbook never instructs is precisely what CIAC-3 forbids (mechanically enforced by `release/tools/check-emission-contract-subset.sh`). A gate that asserted a `deployment-status` row would not measure this N/A either: every release-stamped deploy writes the rules-mirror row, so the gate would pass for a stamped content-only release, and it would still fail for a release whose change reached the runtime only through the hook tier or the composition surfaces — the carve-out above.

## 5. Baseline mechanism

Per the platform's calibration discipline ([`gate-evaluation-spec.md § Layer 3 Calibration`](../../../core/schemas/gate-evaluation-spec.md)):

| Phase | Trigger | Action |
|---|---|---|
| **Pre-baseline** | Count of non-N/A cycle-time values across closed post-cutover releases < 3 | Each release records its cycle-time; no baseline comparison rendered. Visible-H4 field carries the raw value only. |
| **Baseline establishment** | Count reaches 3 (N=3) | Compute median + median absolute deviation (MAD) over the 3 most recent non-N/A values; record in `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/cycle-time-baseline.md` (NEW; lazily created at the first release that crosses N=3). |
| **Post-baseline** | Count ≥ 3 | Each new release's cycle-time is compared against the rolling-3 median; deviation reported in the visible-H4 block as `Cycle-Time: 47m (-12% vs 53m baseline)` or similar. |

**N=3 rationale:** Aligns with the platform-wide calibration threshold per [`gate-evaluation-spec.md § Layer 3 Calibration`](../../../core/schemas/gate-evaluation-spec.md) — "when ≥ 3 records exist: include historical comparison". The same N=3 minimum applies across Stage 7/8 calibration, doc-link maintenance shakedown windows, release-corpus-schema field promotion, and hub-spoke-bridge audit-class threshold calibration ([`hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) `[CALIBRATE-AFTER-3]` precedent). Selecting N=3 for cycle-time baseline keeps the cycle-time metric within the established calibration discipline.

**Baseline file lifecycle:** `cycle-time-baseline.md` is NOT created by this standard or this release. The first Stage 13 spoke that observes N=3 non-N/A values initializes the file with the rolling-3 median + MAD. Subsequent Stage 13 spokes append the new release's value and recompute the rolling-3 median.

**Trend detection (deferred to post-baseline):** Specific alerting thresholds (e.g., "alert when single release exceeds 3× median", "alert when 3-release rolling median exceeds 1.5× baseline") are TBD post-baseline. The threshold cannot be calibrated without baseline data. Open a follow-on Stage 5 spec once N=5 to N=10 non-N/A values exist (recommended target: after several capability tracks have shipped and the metric has been observed across diverse release classes). Until then, the standard records cycle time and reports raw values only; no alerting fires.

## 6. DORA alignment

This metric is a workspace-internal instantiation of two DORA primitives:

- **Lead time for changes** (commit-to-deploy interval) — DORA measures from commit; this standard measures from Stage 9 GO. The GO timestamp is downstream of commit and isolates the human decision-to-deploy latency, not the engineering-cycle latency. The narrower window is intentional: capture process-discipline drift (slow Stage 9 → Stage 12 = process friction), not engineering cycle drift (slow Stage 6 → Stage 12 = work complexity).
- **Deployment frequency** (deploys per unit time) — derivable from the same `deployment-status/deploy-skill` / `deploy-harness` event stream by counting events per calendar interval. Out of scope for this standard; available to downstream consumers via the same query primitive.

Reference: Forsgren, Humble, Kim — *Accelerate* (2018); DORA State of DevOps Report (annual). Informational citation only — this standard does not adopt DORA's measurement protocol verbatim, and DORA is NOT added to `upstream-reference-catalog.md` (scope per [`upstream-reference-catalog.md`](../../../core/standards/upstream-reference-catalog.md) is "canonical upstream sources for PMO skill artifacts", which excludes external benchmarks).

## 7. Computation tool

Reference implementation: [`release/tools/compute-cycle-time.sh`](../../tools/compute-cycle-time.sh)

**Form factor:** Wrapper script composing over [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh). The existing primitive stays unchanged; the wrapper adds the deploy-event subtype filter + ISO8601 delta arithmetic + format selection.

**Why wrapper, not extension:** Extending `query-pipeline-event.sh` with subtype filtering + delta computation would change its contract (currently: pure filter; proposed: filter + arithmetic). Cycle-time computation is a downstream READ-MODEL on top of the filter primitive — keeping the primitive small preserves its reuse for other future read-models on the same event stream (decision-outcome correlation; release-synthesis composition). Localization-Check rationale per [`decision-discipline.md § Mechanism 1`](../../../core/disciplines/decision-discipline.md).

**CLI:**

```bash
./compute-cycle-time.sh <version>           # human-readable: "47m" or "2h17m" or "N/A"
./compute-cycle-time.sh <version> --seconds # integer seconds: "2820" or "N/A"
./compute-cycle-time.sh <version> --iso     # both timestamps: "T_GO=<iso>; T_DEPLOY=<iso>; delta=2820s"
```

**Exit codes:**
- `0` — success: a value, or `N/A` with its reason on stderr — a legitimate result when an anchor cannot be resolved (§ 2.1 for T_GO, § 4 for T_DEPLOY)
- `1` — invalid args / log file missing
- `2` — malformed row (ts_iso parse failure — pipeline-event-log integrity violation; escalate)

## 8. Consumers

| Consumer | Today | Future |
|---|---|---|
| `release-planner` Mode B (durable release plan authoring) | Reads `cycle-time-baseline.md` for capacity calibration (e.g., "expected GO-to-deploy: ~47m based on rolling-3 median; allocate operator time block") — wiring deferred until baseline establishes | Active downstream consumer post-N=3 |
| `automated-closeout.sh` | Invokes `compute-cycle-time.sh` at `read_state`; carries its value, or its verbatim N/A reason, into the close-out report, JSON report and chore-PR body; reports read-only whether the Deployment Log field carries it | Active downstream consumer in same release — Stage 13 wrapper script |
| `synthesize-release-learnings.sh` | MAY compose cycle-time into release-synthesis row payload | Active downstream consumer in same release — Stage 13 synthesizer |
| `pmo-qa-auditor` (decision-outcome review) | Reads cycle-time as one signal in deployment-quality assessment | Active downstream consumer |
| Future trend-detection automation | Post-baseline; not in current scope | Active downstream consumer after N=5–10 non-N/A values establish trend stability |

## 9. Cutover

**Applies to:** cycle-time is measured for all releases going forward. It first applies at the next release that ships at least one skill or harness change AND consistently emits the `gate-outcome/plan-review-go` + `deployment-status/deploy-skill` / `deploy-harness` events.

**Pre-cutover releases:** exempt. No backfill of historical cycle-times.

**Baseline trigger:** the count of non-N/A cycle-time values across closed post-cutover releases has reached 3, so the baseline exists (`cycle-time-baseline.md` records the release that initialized it); § 5 governs its maintenance.

## 10. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **INPUT** | Computing cycle-time from synthesized / inferred timestamps | When `pipeline-event-log.md` does not contain the release's Stage-9 GO row (`plan-review-go` at stage `9`, actor `operator`), do NOT substitute a synthesized timestamp (e.g., PR merge time, issue-comment scrape, operator's recollection, or a `plan-review-go` row written at another stage or under another actor) — emit `Cycle-Time: N/A` instead | Convenience pressure: "the release deployed successfully, surely we can reconstruct GO from the PR timeline" — synthesized timestamps drift from the actual operator-rendered GO event and silently bias the baseline | This standard § 2.1 binds T_GO to the Stage-9 GO row identity in `pipeline-event-log.md`; § 4 explicitly directs `N/A` emit when the source event is missing; § 5 baseline mechanism excludes N/A rows | Principal: carries the tool's own N/A line verbatim (N/A with the reason `compute-cycle-time.sh` prints), opens a tracking issue if the gap is systemic. Junior: scrapes PR timeline for an approximate GO timestamp → publishes a "47m" cycle-time that conflates merge-prep latency with deploy latency → biases the rolling-3 baseline |
| FM2 | **PROC** | Including N/A releases in baseline calculation | When computing the rolling-3 median for baseline establishment / maintenance, do NOT count releases that emitted `Cycle-Time: N/A` — N/A releases are excluded by § 4 design | "Just use the most-recent 3 releases" shortcut: counting N/A as zero seconds would crush the median; counting N/A as a separate cohort destroys the comparison validity | This standard § 4 explicitly states "explicitly excluded from baseline computation"; § 5 baseline trigger counts non-N/A values only | Principal: filters the source data to non-N/A rows before computing median; documents the exclusion in baseline.md. Junior: takes the last-3-rows blindly → either includes N/A as zero (artifact-low baseline) or as missing-row (off-by-N count) → baseline value drifts on every release-class change |
| FM3 | **OUT** | Committing cycle-time field updates direct-to-main | When backfilling cycle-time onto a post-cutover release's Deployment Log block (e.g., after instrumentation lands and a retroactive recompute is possible), do NOT commit the visible-H4 edit directly to main — use a Stage 13 chore-PR per the chore-PR convention | Direct-to-main is prohibited regardless of update size per [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" — the rule does not exempt cosmetic / metadata edits | This standard § 3.1 cross-references the chore-PR convention; field placement inside the visible-H4 block inherits the same chore-PR discipline as `Result:` and `Timestamp:` | Principal: opens a `chore/vX.Y-cycle-time-backfill` branch, edits RELEASE_LOG.md, opens a chore PR per the existing chore-PR convention. Junior: pushes directly to main "because it's a metric backfill, not a code change" → triggers Stage 12/13 chore-PR convention violation, no reviewable diff |
| FM4 | **TRIG** | Treating any timestamped gate-outcome row as T_GO | When multiple `gate-outcome` rows exist for the release, do NOT take the FIRST row's `ts_iso` by event type or by subtype alone — only the Stage-9 GO identity qualifies as T_GO (`plan-review-go` at stage `9`, actor `operator`) | A release commonly has multiple `gate-outcome` rows (g1-g2, g3-release-readiness, dt-pass, qa-acceptance, plan-review-go) — taking the first row gives an earlier-stage gate timestamp, not the Stage 9 GO, and before the writer enforced the GO identity `plan-review-go` itself was written at other stages — for Stage-7 and Stage-8 verdicts, Stage-4 plan approvals and Stage-12 execute authorizations | This standard § 2.1 binds T_GO to the full row identity (event type, subtype, stage `9`, actor `operator`); `compute-cycle-time.sh` selects on all four in one self-tested predicate, and `append-pipeline-event.sh` refuses the subtype under any other stage or actor | Principal: selects on the full identity; if no row of that identity exists, emits N/A per FM1. Junior: filters on `gate-outcome`, or on `plan-review-go` alone, and takes MIN(ts_iso) → anchors on a Stage-7 verdict or a Stage-4 plan approval → cycle-time is hours-to-days too long, baseline corrupted |

## 11. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Source events schema | [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 2-3 | Defines `ts_iso` field, `gate-outcome/plan-review-go` subtype, `deployment-status/deploy-skill` + `deploy-harness` subtypes |
| Event capture surface | [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) | Append-only event stream; data source for the computation |
| Query primitive | [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) | Read helper; this standard's `compute-cycle-time.sh` composes over it |
| Compute wrapper | [`compute-cycle-time.sh`](../../tools/compute-cycle-time.sh) | Reference implementation of § 2.2 delta computation + § 3 format selection |
| Calibration threshold | [`gate-evaluation-spec.md § Layer 3 Calibration`](../../../core/schemas/gate-evaluation-spec.md) | N=3 baseline rule (this standard inherits, does not redefine) |
| Stage 9 GO emission | [`pipeline/stage-09-plan-review.md`](../pipeline/stage-09-plan-review.md) | T_GO source — operator-emitted `plan-review-go` event |
| Stage 12 deploy emission | [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) | T_DEPLOY source — hub-emitted `deploy-skill` / `deploy-harness` events at Phase H |
| Pipeline rules cross-reference | [`release/governance/release-process.md`](../../governance/release-process.md) Stage 12 Phase B5 + Stage 13 § Post-deploy verification | Stage 12 spoke invokes `compute-cycle-time.sh`; Stage 13 spoke maintains baseline |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at `core/standards/` |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags (TRIG / INPUT / PROC / OUT / HAND) |
| Chore PR convention | [`release/governance/release-process.md`](../../governance/release-process.md) Stage 12 / Stage 13 § Chore PR convention | All RELEASE_LOG.md cycle-time edits land via chore PR, never direct-to-main |
| Cross-issue (decision-outcome) | `decision-outcome-tracking.md` (sibling release) | Decision-outcome spec MAY reference cycle-time as one input to decision-outcome correlation |
| Cross-issue (automated-closeout) | `automated-closeout.sh` (sibling release) | Invokes `compute-cycle-time.sh` and carries its verbatim N/A reason; verifies the Deployment Log field read-only |
| Cross-issue (synthesize-release-learnings) | `synthesize-release-learnings.sh` (sibling release) | MAY compose cycle-time into release-synthesis row payload |
| Source Stage 5 spec | Stage 5 Solutioning canonical spec | Stage 5 Solutioning canonical spec |

## Version History

Tracked in git history.
