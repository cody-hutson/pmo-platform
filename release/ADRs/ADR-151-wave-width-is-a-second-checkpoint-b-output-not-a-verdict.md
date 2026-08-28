<!-- reference-durability: allow-link -->
---
title: "ADR-151 — Wave width is a second Checkpoint B output, not a verdict"
status: Accepted
date: 2026-08-27
release: ci-stable-under-transient-conditions
deciders: "Stage 5 Solutioning spoke (six-candidate design exploration) + Collective Review (scope-lock; the bridge's consuming rules were admitted into scope) + Stage 6 Engineering spoke (build, interface reconciliation)"
tags: [quota-budget, checkpoint-b, wave-width, parallelism, interruption-cost, exposure-bound, hub-spoke, ordinal-band, ADR-102, ADR-156]
source_observations:
  - "Observed on a prior release: a three-wide Stage-7 wave hit the account session limit and all three spokes terminated simultaneously, none having posted. Recovery worked — each resumed from transcript — but the same interruption in a serial arrangement would have cost one spoke and banked two completed results."
  - "That release recorded eight session-limit interruptions across its run; the only three-wide wave was the one that lost every spoke in it at once. The hub revised its own posture to strictly serial mid-release on that evidence, by hand, with no rule telling it to."
  - "Parallel and serial arrangements of the same batch draw the SAME cumulative total against the usage window. What differs between them is only how much in-flight work a single interruption destroys."
  - "The verdict hierarchy brackets both width endpoints and defines nothing between them: PROCEED means every spoke goes in flight at once, SERIALIZE means exactly one does. The interval's interior was undefined."
  - "A survey of shipped release plans found repeated ad-hoc plan-time width caps — several different numeric values keyed on several different things (the envelope, a dependency, nothing at all) — and no governed home for any of them. The governed corpus carried no wave-width convention of any kind; a sensitivity control on adjacent Checkpoint-B vocabulary fired, so the absence was measured rather than a broken probe."
  - "Plan-time capping had already been tried and observed to fail: the release that lost a three-wide wave had itself planned that width at Checkpoint A, whose verdict was PASS. Nothing at runtime narrowed it."
  - "Three consuming rules bound the PROCEED verdict to launching every actionable spoke, and two of the three lived in the hub-and-spoke bridge rather than in the protocol. Left unedited they would have discarded a width output entirely, and the feature would have shipped inert while rendering a width line."
  - "Every release plan surveyed recorded its usage-window band as unstated or conservative-default, so the unstated row is the modal case rather than an edge case."
---

# ADR-151 — Wave width is a second Checkpoint B output, not a verdict

## Status

**Accepted.** Authored at Engineering for the `ci-stable-under-transient-conditions` release, against the Collective Review scope-lock that admitted the hub-and-spoke bridge's consuming rules into this card's scope. Sequenced after the host-API axis decision recorded at ADR-156, on the same protocol section.

**Numbering provenance — `145 → 151`.** Held **ADR-145** branch-local; renumbered to **ADR-151** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 145. In-release citations that read "ADR-145" denote this record.

## Context

Checkpoint B of the quota-budget protocol gates every spoke launch and renders a verdict: PROCEED, SERIALIZE, DEFER or REDUCE-scope for a wave, and a reduced pair for a singleton. The verdict answers one question — *does the cumulative draw fit the remaining envelope?* — and it answers it correctly. It deliberately does not read how the batch is arranged, because arrangement buys nothing on the envelope.

That is exactly right for the envelope, and it leaves a second quantity ungoverned. **Cumulative draw is invariant under width**: N spokes draw N spokes' worth whether they run all-at-once or one-at-a-time. **Interruption cost is not.** A wave of width `W` that dies mid-flight destroys up to `W` in-flight spoke-runs; a narrower arrangement destroys fewer and banks the rest. Width is the only lever on that loss, and nothing in the gate touched it.

The gap has a shape worth naming: the verdict hierarchy already **brackets both endpoints of width and defines nothing between them.** PROCEED is the whole batch in flight; SERIALIZE is one at a time. The missing heuristic is the interior of an interval the gate already owns — not a new mechanism.

Two forces made the absence actively harmful rather than merely incomplete.

**First, the gate permits a reasoning error.** "Parallel-safe" is a *file-contention* property: it says a stage's spokes share no write surface. The protocol is explicit that this is orthogonal to the usage-window envelope. But with no width output anywhere, a hub reading "Stage 7 is parallel-safe" has nothing to consult about arrangement, and the coordination property is the nearest thing to hand. That substitution is what produced the wave that lost every spoke in it. The host-API axis added at ADR-156 introduces the *identical* substitution one axis over: a healthy pool is an **availability** property too, and reads just as easily as permission to go wide.

**Second, plan-time capping had already been tried and had already failed.** Several shipped release plans invented a local width cap at planning time. The release that lost a three-wide wave had planned that width itself, and its plan-time verdict was PASS. A plan-time number has no runtime authority; nothing narrowed the wave when the envelope tightened under it.

## Decision

**Checkpoint B renders `W_max` — the maximum spokes it may put in flight simultaneously — as a SECOND OUTPUT alongside its verdict, never as a verdict token.**

Four properties are load-bearing, and each is a decision rather than an implementation detail.

1. **It is an output, not a token.** The rendered verdict set stays exactly the closed set it already was, for both the wave and the singleton form. This is what lets the width output ride the existing combination rule's opaque pass-through untouched, and what keeps the enum a stable cross-artifact contract with the host-API axis.

2. **It keys on the verdict's own basis** — the operator-stated band decayed for elapsed time — and on nothing else. Explicitly *not* on the stage's parallelism class, and *not* on the host-API reading. Zero new inputs, zero new tool calls on the usage-window axis.

3. **It is an absolute integer, mapped from an ordinal band.** Loss is counted in spoke-runs, so the bound is counted in spoke-runs. The mapping is a table rather than arithmetic because the refuse-to-synthesize rule forbids the usage-window axis from computing a figure it cannot measure, and because halving an ordinal is a category error. **The conservative-default band is deliberately capped tighter than a stated partial band**: the assume-less-headroom posture cannot buy more width than a band the operator actually stated, which converts a standing request for a stated band into a live incentive.

4. **A narrowed wave splits into re-gated sub-waves.** When `W_max` is below the actionable count, the wave runs as successive sub-waves and the gate fires again before each. Narrowing therefore bounds the loss **and** multiplies how often the envelope is re-read, which is the same argument the protocol already makes for preferring a runtime check over a one-and-done plan-time one — applied at the sub-wave grain.

One measured input is admitted, and it is the only one on this axis: **an observed interruption demotes the basis one step**, floored at strictly serial. Refuse-to-synthesize forbids *projecting* remaining quota; it does not forbid reading an event the hub witnessed. A spoke dying at the session limit **falsifies** whatever band was stated before it, and continuing to launch against the stale declaration is the failure the demotion closes. This codifies as a rule exactly what a hub already did by hand.

## Decision kernel (version-agnostic)

The usage-window gate answers two questions with different units — **whether** to launch (envelope, answered by the verdict) and **how many at once** (exposure, answered by `W_max`). They share one basis and one rendered line. Width is never a verdict token, never derived from a coordination or availability property, and never a fixed count: it is a loss bound that moves with the envelope.

## Alternatives Considered

Six candidates were generated before any was specified; five were rejected.

- **A new verdict token (`NARROW` / `SPLIT`).** **Rejected.** It breaks the cross-issue contract that freezes the rendered verdict set, and it would force a parallel decision about whether the token exists at all in the singleton form. The endpoints of width are already *in* the hierarchy; minting a token for the interior claims the hierarchy does not already own it.

- **A ratio or split-factor keyed on the band.** **Rejected on the quantity it is meant to bound.** Under a ratio, loss scales with the batch: a twenty-wide wave halved still risks ten spoke-runs. The design exists to bound loss *absolutely*, and a ratio is the one form that structurally cannot.

- **A computed fractional exposure** — the largest width whose projected cost stays under a fraction of the remaining envelope. **Rejected as a mechanism, retained as rationale.** It requires arithmetic over a *stated* envelope, and the unstated band is the modal case; it would also emit exactly the synthesized figure the refuse-to-synthesize rule forbids on this axis. It survives as the derivation of the ordinal table's constants.

- **Plan-time capping only** — formalize the observed ad-hoc caps at the plan-time checkpoint and leave the runtime gate unchanged. **Rejected as empirically falsified, and this is the strongest evidence in the set.** Several release plans have already done exactly this. The wave that lost every spoke in it was itself plan-capped, and its plan-time verdict was PASS. The option has been run and observed to fail; nothing at runtime narrowed the wave.

- **Parameterize the existing verdict** as `SERIALIZE(W)`. **Rejected.** One token would then mean both "strictly serial" and "bounded-parallel", collapsing the distinction the hierarchy's surface-reduced column depends on. It is the selected design with the verdict's meaning destroyed.

- **A second output field on the check, keyed on the verdict's own basis.** **Selected.** It bounds loss absolutely, leaves the verdict enum untouched, renders on the modal unstated band, adds no tool call on the usage-window axis, and is reversible by reverting prose.

## Consequences

**Positive.** Repeated ad-hoc plan-time caps collapse into one governed table with one key, so a recalibration edits one place and the consuming rules cite rather than restate it. The gate gains a bound on interruption loss it structurally lacked. Narrowing compounds: a split wave re-reads the envelope once per sub-wave instead of once per batch. The anti-substitution statement lands *at the gate*, where the error is made, and forecloses both available substitutions — the coordination property and the availability property — so the newer host-API axis does not inherit the defect this record exists to close.

**Negative, and named rather than hidden.** On releases where the band is never stated — the observed default — the posture moves from launching the whole batch to launching a pair at a time. **The cost is latency, not quota**: cumulative draw is unchanged, which is this decision's own premise. The escape is one sentence from the operator at hub start, which is the incentive the design intends.

**Residual.** The width values are provisional and carry a calibrate-after-three flag. They bound the distribution of *work destroyed per interruption*, and no release has yet recorded that distribution — the gate emits no pipeline event, so no runtime record of it exists by construction. Wiring such an event is a separate substrate decision recorded at ADR-102, not a widening of this gate. Until then the values calibrate against the protocol's registered trigger, and the honest statement is that they are provisional on a quantity nobody has measured.

**Interface.** Because `W_max` is an output rather than a token, the rule combining the two Checkpoint B axes needs no edit: on a healthy host-API reading it passes the usage-window branch's output through opaquely, width field included. That opacity is a property this decision depends on and does not modify.

## Reversibility

**CHEAP / Confidence HIGH.** Governed prose across the protocol, the bridge and the hub's launch reference, plus one skill-package rebuild. Reverting the commit and rebuilding the package restores prior behavior exactly; no schema, no executable path, no host-side state. Partial revert is **not** safe in one direction: reverting the consuming rules while keeping the protocol section ships a width output nothing reads — an inert feature that renders a line and changes nothing.

## Related ADRs

- **ADR-156** — the host-API second axis on the same checkpoint. Sequenced immediately before this decision on the same protocol section; its opaque pass-through is what carries this decision's width output through the combination step unedited. Its scoping of refuse-to-synthesize to the usage-window axis is what preserves this decision's ordinal-table justification.
- **ADR-102** — the quota-budget successor substrate. Owns the telemetry-event decision this record's residual depends on; the width values stay uncalibrated until that substrate carries a per-launch record.
- **ADR-026** — the declared-but-unwired startup-reservation telemetry event, superseded in its substrate choice by ADR-102 for the cost-estimate section only.
