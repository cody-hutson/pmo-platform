<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->
# Quota-Budget Protocol — Dual-Checkpoint Parallel-Launch Gate

> **Part of:** the hub-and-spoke release bridge ([`../how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md)) and the Stage 4 planning spec ([`../pipeline/stage-04-planning.md`](../pipeline/stage-04-planning.md)).
> **Operationalizes:** the per-account 5-hour usage-window constraint documented in [`../how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) § Per-Account Usage Window Constraint.

## 1. Purpose + Scope

This protocol is the active enforcement mechanism for the per-account **5-hour usage-window** constraint on parallel spoke launches. The window meters *cumulative total token consumption* within a sliding ~5-hour period (it resets five hours after window-start). This is a **usage-window** constraint — **not a rate limit**; the two are different constraint classes with different mitigations, and conflating them routes an envelope problem to a timing-only fix that does not change cumulative consumption.

The protocol defines two checkpoints:

- **Checkpoint A — Stage 4 plan-time estimate.** A one-time, agent-computed budget estimate authored into the release plan. It is advisory: it sizes the worst parallel batch against the assumed envelope so the operator sees capacity risk before Engineering.
- **Checkpoint B — runtime re-validation (load-bearing).** Fires before *every* parallel spoke wave at hub routing time. It re-estimates cumulative draw against the *remaining* window envelope and renders a verdict that gates the launch. The runtime checkpoint is load-bearing because Stage 4 estimates the budget once, but parallel batches fire at multiple routing points across a release (Stage 5 / Stage 7 / Stage 8 waves), each facing a potentially different remaining envelope; a one-and-done plan-time check misses the mid-release drift the runtime check catches.

**Scope.** The protocol governs parallel spoke launches at the parallel-safe stages (Stage 5 Solutioning, Stage 7 Dev Testing, Stage 8 QA Testing per the Procedure 2 Step 5 Parallelism Rules table). It does not apply to the write-serialized stages (Stage 6 Engineering, Stage 13 Close), which launch one spoke at a time by design and therefore have no concurrent-batch cumulative-draw surface.

## 2. The two checkpoints

| Checkpoint | Stage | Nature | Output | Gating |
|---|---|---|---|---|
| **A** | Stage 4 Planning | Agent-computed plan-time estimate | `### Quota Budget` section in the release plan; verdict PASS / WARN / FAIL | Advisory — surfaces capacity risk; does not block |
| **B** | Hub runtime (per wave) | Runtime re-validation before each parallel wave | Verdict PROCEED / SERIALIZE / DEFER / REDUCE-scope (usage-window axis); STAGGER labeled secondary (rate-limit only) | **Load-bearing** — gates the launch; SERIALIZE / DEFER / REDUCE-scope produce a Decision Briefing before any spoke fires |

Checkpoint A's plan-time estimate is the *baseline budget* Checkpoint B refines at runtime with observed per-spoke actuals, elapsed-window time, and operator-stated quota state.

## 3. Checkpoint A — Stage 4 plan-time estimate

Checkpoint A runs as the terminal Phase-A step (A6) of Stage 4 Planning, after the plan is assembled. It summarizes plan-level capacity by reading the parallel-eligible spoke count from the **A2 Stage Applicability Matrix** and the contention output from **A4**.

### 3.1 Input contract

| Input | Source |
|---|---|
| Parallel-eligible spoke count per parallel stage (Stage 5 / 7 / 8) | A2 Stage Applicability Matrix (the matrix records which stages apply per issue; the parallel-safe stages are 5 / 7 / 8 per the Parallelism Rules table) |
| Per-spoke cost estimate | Per-spoke cost-estimate heuristic (§ 5) — size-bucket ordinal band until telemetry medians are available |
| Cumulative work estimate | parallel-eligible count × per-spoke cost estimate, per parallel batch (worst batch) |
| Assumed/stated remaining usage-window envelope | Operator-stated quota state at hub start (§ 6), OR a conservative default when unstated |
| Estimated cumulative draw % | cumulative estimate ÷ envelope, expressed as a percentage of the worst parallel batch |
| Contention context | A4 file-contention output (informs whether the parallel-eligible count is realizable under the selected D-C topology) |

### 3.2 Bands and routing tree

The bands are expressed as a fraction of the stated/assumed envelope. They are provisional with one empirical datum — `[CALIBRATE-AFTER-3]` (MEDIUM confidence), calibration target = the cumulative-draw budget (§ 7):

```
PASS  (cumulative draw < 50% of envelope)      → proceed parallel; no warning in plan
WARN  (cumulative draw 50–80% of envelope)     → window-aware launch timing + quota-budgeting
                                                  (split batch) recommended in the plan
FAIL  (cumulative draw > 80% of envelope)       → three outcomes:
                                                  (a) split-batch (run across multiple windows)
                                                  (b) reduce per-spoke cost (compact prompts,
                                                      narrower scope, fewer canonical reads)
                                                  (c) escalate Tier 2 [SCOPE CHANGE]
                                                      (reduce release size)
```

The WARN band routes to **window-aware timing + quota-budgeting**, NOT to a stagger delay — stagger is a rate-limit defense and does not change cumulative consumption (§ 4.4). Checkpoint A's verdict is advisory; the binding gate is Checkpoint B at runtime.

## 4. Checkpoint B — runtime re-validation (load-bearing)

Checkpoint B fires before the hub issues N parallel Agent invocations in the same response (per [`../how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) § Spoke Launch Mechanisms § Default). It is the load-bearing gate.

### 4.1 Input contract

| Input | Source |
|---|---|
| Baseline budget | Checkpoint A's `### Quota Budget` plan estimate |
| Observed per-spoke actuals | Two substrates, measuring different quantities (§ 5.2): **(a)** `finops-usage-extractor` `estimate-usage.sh` — **cumulative per-spoke draw, LOCAL, reproducible** — the quantity § 4.2's arithmetic consumes, and the PRIMARY source; **(b)** per-spoke *startup-cost* telemetry from earlier waves this release — the `spoke-launch` / `quota-reservation` event in [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3, **declared but not currently emitted**. Refines the per-spoke cost estimate from the heuristic to observed medians, subject to § 5.1's per-bucket cutover predicate |
| Elapsed-window time | Time elapsed since hub session start (contributes to remaining-envelope refinement) |
| Operator-stated quota state | The session-start capture + per-batch optional override (§ 6) |

### 4.2 Procedure

1. Compute `N_planned` — the parallel-eligible sub-tasks actionable at this routing point per Procedure 2.
2. Estimate cumulative cost: `N_planned × per-spoke-cost-estimate` (from the Checkpoint A baseline, refined by observed actuals from prior waves this release where available).
3. Compare against the *remaining* window envelope (operator-stated state at hub start, adjusted for elapsed-window time and any per-batch override).
4. Render a verdict (§ 4.3).
5. On SERIALIZE / DEFER / REDUCE-scope: produce a Decision Briefing surfacing the verdict + recommendation to the operator **BEFORE** launching any spoke in the wave.

### 4.3 Verdict hierarchy (usage-window axis)

The verdict hierarchy is the binding output. Each verdict names the surface it reduces, so an envelope problem is never routed to a timing-only fix:

| Verdict | Meaning | Surface reduced |
|---|---|---|
| **PROCEED** | Cumulative estimate fits the remaining envelope comfortably | none — launch all N in parallel (existing behavior) |
| **SERIALIZE** | Envelope is tight; launch one spoke at a time, halt on first usage-limit failure | the simultaneous-spawn/draw **count** (one in-flight draw at a time) |
| **DEFER** | Remaining envelope cannot absorb the batch | the batch is held for the next window; cumulative draw deferred entirely (see the operator-override exit, § 4.5) |
| **REDUCE-scope** | The batch can fit only with a smaller per-wave footprint | the per-wave **consumption** (compact prompts, narrower scope, fewer canonical reads per spoke) |

### 4.4 Secondary — STAGGER (rate-limit only, not load-bearing for the usage window)

A hub MAY add an in-prompt `sleep <position × delay>` stagger to spread *momentary peak* draw — a defense against the separate **rate-limit** constraint (tokens/sec or concurrent in-flight reservations). It is harmless, but it is **not load-bearing for the 5-hour usage window**: spreading N spokes across a few minutes changes nothing about cumulative token consumption within the window. STAGGER is therefore a *labeled secondary* defense — never the mitigation for a usage-window overrun. Route a usage-window problem to SERIALIZE / DEFER / REDUCE-scope, never to STAGGER.

### 4.5 DEFER operator-override-to-PROCEED exit

When Checkpoint B renders **DEFER**, the hub offers the operator an explicit override-to-PROCEED exit. The override is the escape hatch for a wrong-stated-envelope deadlock — a DEFER driven by a conservative or stale stated state that the operator knows to be wrong (e.g., the operator just refreshed quota by doing nothing for several hours). The override:

- is **operator-initiated** (the hub renders DEFER as the *recommended* verdict; the operator chooses to override), not a default path the hub takes;
- is **deviation-logged** (a recorded, auditable choice in the release plan's Deviation Log), mirroring the recorded-decision discipline of [`triage-design-rereview.md`](triage-design-rereview.md);
- does not reopen the gate at every wave — it is an explicit, recorded exit for a specific batch, not a standing PROCEED.

This keeps the override from training reflexive override (which would defeat the gate): the gate still renders DEFER as recommended, and overriding it is a deliberate, logged act.

## 5. Per-spoke cost-estimate heuristic

Until per-spoke startup-token telemetry medians are available, the per-spoke cost estimate is a **size-bucket ordinal band** keyed to the spoke's work-item size label:

| Size bucket | Ordinal cost band |
|---|---|
| `size:S` | lowest |
| `size:M` | low–moderate |
| `size:L` | moderate–high |
| `size:XL` | highest |

The ordinal band is a relative ranking, not an absolute token count — it lets Checkpoint A rank a batch's worst-case draw before any telemetry exists.

### 5.1 Cutover to observed medians — conditioned, and evaluated PER BUCKET

The ordinal band is **superseded for a size bucket `B`** — replaced by an absolute token figure Checkpoint B compares against the remaining envelope directly — when **all** of the following hold at evaluation time. Until then `B` keeps its band:

| # | Condition | Threshold provenance |
|---|---|---|
| **(i)** | `n_B ≥ 3` eligible comparables contribute to `B`'s figure | the platform-wide calibration threshold ([`../../../core/schemas/gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md)) |
| **(ii)** | `rMAD_B ≤ 0.50` | the attribution convention's WARN boundary ([`../../../core/standards/finops-attribution-convention.md`](../../../core/standards/finops-attribution-convention.md)). Above it the telemetry's spread exceeds the ordinal band's own resolution, so an absolute figure is *less* informative than a ranking, not more |
| **(iii)** | the estimate's rendered confidence for `B` is **≥ MEDIUM after all caps** | so a network-resolved or best-effort-heavy population cannot silently promote itself |
| **(iv)** | the best-effort attribution **token fraction** for `B`'s comparable set is `≤ 0.50` | the same convention's FAIL boundary |
| **(v)** | the **leave-one-out median absolute percentage error** over `B`'s comparables is `≤ 50 %` | measured by `estimate-usage.sh --delta` |

**The ordinal band is the retained FLOOR, not a thing being deleted.** A bucket failing any condition keeps it.

**A mixed state — some buckets superseded, some not — is the expected steady state, not a defect.** Partial supersession is neither a broken cutover to be forced through nor a reason to abandon the cutover.

Conditions (i)–(iv) measure **precision** (the comparables agree with *each other*). Only **(v)** measures **accuracy** (they agree with *reality*) — a tight cluster of systematically-wrong comparables passes (i)–(iv) cleanly. All five are `[CALIBRATE-AFTER-3]`: no usage distribution exists to calibrate them against.

### 5.2 The two candidate substrates, and their unit divergence

Two telemetry substrates are declared for this estimate. They measure **different quantities**, and the difference is load-bearing:

| Substrate | Measures | Status |
|---|---|---|
| `spoke-launch` / `quota-reservation` (§ 4.1; [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3) | a **startup reservation** — prompt-construction cost at spawn | **Defined in the schema enum but not currently emitted.** No producer exists. Retained as a declared input; if wired it composes with, rather than replaces, cumulative draw. |
| `finops-usage-extractor` → `estimate-usage.sh` | **cumulative per-spoke draw** — what a spoke consumes over its life | **PRIMARY.** This is the quantity § 4.2's arithmetic consumes: the usage window meters *cumulative* total token consumption (§ 1), so a startup-only figure would under-estimate a batch's draw. LOCAL and reproducible — no network call. |

The size↔points bridge is local and in-repo: a `rollup` row keyed `milestone:vX.Y` joins [`../../releases/RELEASE_LOG.md`](../../releases/RELEASE_LOG.md)'s governed `**Velocity:**` field for that version → `(planned points, release class)` → tokens-per-point → × the canonical point scale, which is **cited by role from [`bundle-composition-doctrine.md`](bundle-composition-doctrine.md) § 3 Step 5 and never restated here**.

The substrate decision — FinOps primary, `spoke-launch` retained as declared-but-unwired — is recorded at **[ADR-100](../../ADRs/ADR-100-quota-budget-successor-substrate-finops-cumulative-draw.md)**, which supersedes [`ADR-026`](../../ADRs/ADR-026-spoke-launch-quota-reservation-telemetry-event.md) **in its substrate choice for this section only**; ADR-026's event definition and writer-contract reasoning stand.

## 6. Operator-interaction surface

The hub learns the operator's current quota state via a **hybrid** mechanism:

- **Session-start capture (the common case).** At hub session start, the hub captures the operator's initial quota state — `fresh` / `partial-N%` / `near-tail` — and propagates it to every routing decision, adjusting for elapsed-window time since capture. This is low-friction and covers the common case.
- **Per-batch optional override (the drift case).** Before a parallel wave, the operator MAY update the stated state (e.g., "I just did other work" / "fresh quota now"). The override is *optional* — zero-friction when unused, available when state changed. It handles the mid-release drift the runtime checkpoint exists to catch.

A future platform-side quota API (currently not queryable from within a session) is the eventual ground-truth surface; it slots into the Checkpoint B input contract (§ 4.1, "remaining window envelope") without reworking the verdict logic when it ships. The verdict logic accepts any capture mechanism behind the stable "remaining envelope" input, so the capture surface is swappable.

## 7. Calibration

The following are provisional with one empirical datum and carry the `[CALIBRATE-AFTER-3]` flag (MEDIUM confidence):

- the Checkpoint A PASS / WARN / FAIL bands (§ 3.2);
- the per-spoke cost estimate (§ 5, until telemetry medians replace the heuristic);
- the **§ 5.1 cutover predicate's own thresholds** — `n_B ≥ 3`, `rMAD_B ≤ 0.50`, confidence `≥ MEDIUM`, best-effort token fraction `≤ 0.50`, and leave-one-out median absolute percentage error `≤ 50 %`. These are the calibration target for the band→telemetry cutover, and the **calibrating instrument is the leave-one-out backtest** (`estimate-usage.sh --delta`), which is the only one of the five that measures accuracy rather than self-consistency. Recalibrate per bucket, never globally;
- the **cumulative-draw budget** threshold — the per-spoke cost estimate combined with the batch-vs-remaining-window threshold at which Checkpoint B renders SERIALIZE / DEFER / REDUCE-scope.

**The calibration target is the cumulative-draw budget — NOT a stagger-delay value and NOT a fixed batch-size count.** A fixed concurrent-count is not the binding predictor: a small batch on a near-tail window can overrun while a large batch on a fresh window succeeds. The binding variable is the *remaining* window envelope against cumulative draw, which a count does not read. The calibration trigger is registered at Stage 13 on the release log; recalibrate after this protocol's introducing release plus two further post-cutover releases supply an outcome distribution.

## 8. Composition

- **Per-Account Usage Window Constraint** ([`../how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) § Per-Account Usage Window Constraint) — this protocol is the active gate that operationalizes that subsection's documented constraint and load-bearing mitigations (pre-flight check / quota-budgeting / window-aware timing / serialize-on-failure / reduce-consumption). The subsection documents the *what*; this protocol defines the *gate*.
- **Parallelism Rules orthogonality** ([`../how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) Procedure 2 Step 5) — parallel-safe is a *coordination*/file-contention property, orthogonal to the usage-window envelope. The two gates compose: a stage marked parallel-safe has no file-contention surface but may still require SERIALIZE / DEFER / REDUCE-scope under the usage-window gate.
- **Hub action tracking** ([`../../../core/standards/hub-action-tracking.md`](../../../core/standards/hub-action-tracking.md)) — when DEFER fires, the hub MAY emit an action-item entry (e.g., "Resume Stage 5 batch after window-reset at HH:MM") so the deferred batch is tracked and resumed.
- **Autonomy Tier (no downgrade).** The usage-window verdicts are decisions about *whether and when* to launch a batch; they do not reclassify the parallel-safe stages' Autonomy Tier (Stage 5 / 7 / 8 remain auto-launch). They do not apply to the write-serialized stages (6 / 13), which launch one spoke at a time by design.

## 9. Cutover

Applies to releases entering the pipeline on or after this protocol's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>); the introducing release itself is exempt (reflexive-pipeline-loop discipline — the gate shipping in a release cannot retroactively bind its own pipeline run, whose parallel waves fired before the gate existed). All releases that entered the pipeline prior to the introducing release are also exempt.
