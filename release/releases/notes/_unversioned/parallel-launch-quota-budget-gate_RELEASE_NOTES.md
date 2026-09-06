---
version: parallel-launch-quota-budget-gate
date: 2026-06-14
type: note
issues: ["#23", "#24"]
pr: "#911"
links:
  plan: release/releases/plans/parallel-launch-quota-budget-gate_RELEASE_PLAN.md
  log_anchor: "#parallel-launch-quota-budget-gate-version-less"
reversibility-tier: CHEAP
themes: ["cluster:release-pipeline", "cluster:parallel-orchestration"]
summary: "Parallel release work now checks the operator's usage window before launching, so a batch no longer fails partway through from quota exhaustion."
requires_action: false
breaking: false
components: ["hub-spoke-bridge.md", "stage-04-planning.md", "quota-budget-protocol.md", "pipeline-event-log-schema.md", "ADR-026"]
followups: []
---

# Parallel release work checks the usage window before it launches

2026-06-14 · parallel-launch-quota-budget-gate

Running several release tasks at once used to launch them blind to how much of the operator's usage window was left, so a batch could fail partway through once the window was exhausted — leaving half-done work to clean up. The release pipeline now estimates the cost of a parallel batch and checks it against the remaining window before launching, and it re-checks before each wave of work rather than just once at planning time.

> **Skip the rest** unless you run platform releases or read release notes for what changed in the pipeline.

## Who this affects

- The workspace operator and anyone who runs the release pipeline with several tasks moving in parallel (planning, solutioning, testing, or QA waves).

## What changed for everyone using the platform

- **A usage-window check before parallel work launches.** Before the pipeline fires off a batch of parallel tasks, it now estimates the batch's cost and compares it against how much of the usage window is left, then either proceeds, runs the tasks one at a time, holds the batch for the next window, or trims the per-task cost. *Why it matters:* a batch no longer half-completes and then fails on a depleted window — you get a recommended course of action up front instead of a pile of started-but-failed work to recover.
- **The check runs before every wave, not just once at planning.** The pipeline estimates the budget once when it plans the release and then re-validates it before each parallel wave, accounting for work done in between and how much of the window has elapsed. *Why it matters:* a window that was fine at planning time but has since been drawn down is caught before the next batch launches, instead of after it fails.
- **The constraint is named correctly — a usage window, not a rate limit.** The guidance treats the limit as a cumulative usage window over a period and routes an overrun to the mitigations that actually address it (run serially, defer, or reduce scope). *Why it matters:* the fix you are offered matches the real problem, rather than a timing tweak that does not move a cumulative-usage limit.
- **A record of what each launch reserved.** Parallel launches can now record an entry noting the estimated cost they reserved against the window. *Why it matters:* the budget estimates get more accurate over time as real launch costs accumulate, so future checks are grounded in observed cost rather than a fixed guess.

## Known limits

- The check reads the remaining-window state from what the operator states at session start (with an optional per-batch update); there is no automatic platform query for remaining quota yet, so an out-of-date stated value can produce an over-cautious hold — which the operator can override for a single batch.
- The cost-per-task estimate starts from a heuristic and is marked for calibration after a few more releases; early estimates are deliberately conservative.

Report issues at https://github.com/cody-hutson/pmo-platform/issues with the `cluster: release-pipeline` label.

## Reversibility

CHEAP / HIGH confidence. A single `git revert -m 1` of the release pull request reverses the change. It is an additive guidance-and-gate change over the prior "launch everything at once" behavior — no data migration and nothing to re-sync afterward. Standard rollback window.

---

### Operator and engineering detail

**Dual-checkpoint gate (#23)** — The enforcement is a two-point gate. Checkpoint A is a terminal Phase A6 Quota-Budget Pre-Check in `stage-04-planning.md` that estimates parallel-eligible spoke count (A2-sourced from the Stage Applicability Matrix) against the window envelope and emits a `### Quota Budget` section into the release plan with a PASS / WARN / FAIL routing tree. Checkpoint B is the load-bearing runtime check: a new Procedure 2 Step 5.5 in `hub-spoke-bridge.md` plus a Checkpoint-B invocation hook on the § Spoke Launch Mechanisms default multi-launch paragraph, rendering a PROCEED / SERIALIZE / DEFER / REDUCE-scope verdict on the usage-window axis before each parallel launch. A DEFER verdict carries an operator-initiated, deviation-logged, one-batch override exit so a stale-envelope DEFER is escapable without a deadlock and without training reflexive override. A Procedure 2 Step 5 orthogonality note records that "parallel-safe" is coordination semantics, not usage-window semantics — the two gates compose rather than substitute.

**Usage-window constraint subsection + framing correction (#24)** — `hub-spoke-bridge.md § Spoke Launch Mechanisms` gains the canonical `### Per-Account Usage Window Constraint` subsection (renamed from the earlier "Quota Constraint" framing), documenting the cumulative-draw failure mode, a cumulative-vs-rate-limit contrast, and the load-bearing mitigation set (pre-flight check / quota-budgeting / window-aware timing / serialize-on-failure / reduce-per-spoke). In-prompt `sleep` stagger is demoted to a labeled secondary rate-limit-only defense — explicitly never the mitigation for a usage-window overrun — and the same constraint-class separation is held consistently across the subsection, the Step 5 orthogonality note, and the Stage 5 persona anti-pattern in `release-personas.md`. The binding variable is documented as the remaining-window envelope, not a fixed concurrent count; a batch-size heuristic is a floor for *running* the check, not a stagger trigger. The v11.27 first-failure (2026-05-24, nine Stage 5 spokes launched near the tail of the window, all returning a session limit on cumulative startup draw) is preserved as the canonical empirical reference for the cumulative-draw failure mode.

**Telemetry surface + decision record** — `pipeline-event-log-schema.md` § 3 adds a `spoke-launch` event type with a `quota-reservation` subtype carrying `tokens_used:` on the payload, reconciled to the real `payload`-convention surface (no fictional event invented), with `append-pipeline-event.sh` carrying the data-driven enum plus a static fallback mirror in lockstep (`--self-test` PASS, 11 event types). `ADR-026-spoke-launch-quota-reservation-telemetry-event.md` (with a README index row) records the telemetry-event decision; it was renumbered from a Stage-5 ADR-024 draft to avoid an in-flight collision.

**Version-less identity** — Authored in-pipeline as `v1.15`; `v1.15` / `v1.16` / `v1.17` (and subsequently `v1.18`–`v1.20`) were all claimed by concurrent releases during this session's pipeline run, so this release ships **version-less** under the slug `parallel-launch-quota-budget-gate` (the #769 version-collision class). No signed-annotated tag was cut and no GitHub Release was published; the merge commit `b2b5f69873075de6f9516e3f1d053a7829416114` is this release's sole durable anchor. Every load-bearing `v1.15` anchor and the cutover clause were reconciled to the slug / introducing-release-SHA markerless form, so no `allow-version-ref` marker was needed for the cutover prose. Deploy no-op — the changed set is text-only K1 corpus plus release-pipeline spec/protocol docs plus one release tool, with no `SKILL.md`, no `packages/`, and no hook/harness path touched.

For full implementation detail see the [RELEASE_LOG.md entry](../../RELEASE_LOG.md#parallel-launch-quota-budget-gate-version-less) and [the release plan](../../plans/_unversioned/parallel-launch-quota-budget-gate_RELEASE_PLAN.md).

### References

- Milestone: [parallel-launch-quota-budget-gate](https://github.com/cody-hutson/pmo-platform/milestone/159)
- Integration PR: [#911](https://github.com/cody-hutson/pmo-platform/pull/911) at `b2b5f69873075de6f9516e3f1d053a7829416114`
- Closed issues: [#23](https://github.com/cody-hutson/pmo-platform/issues/23) · [#24](https://github.com/cody-hutson/pmo-platform/issues/24)
- QA acceptance: [#787](https://github.com/cody-hutson/pmo-platform/issues/787) (#23 — 11/11) · [#783](https://github.com/cody-hutson/pmo-platform/issues/783) (#24 — 6/6)
