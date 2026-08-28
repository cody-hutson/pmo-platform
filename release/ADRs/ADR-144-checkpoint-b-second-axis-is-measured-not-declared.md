<!-- reference-durability: allow-link -->
---
title: "ADR-144 — Checkpoint B's second axis is measured, not declared: scoping refuse-to-synthesize to the usage-window axis"
status: Accepted
date: 2026-08-27
release: ci-stable-under-transient-conditions
deciders: "Stage 5 Solutioning spoke (four-fork design exploration) + Collective Review (scope-lock; the governing skill's zero-tool-calls assertion was admitted into scope) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [quota-budget, checkpoint-b, host-api, rate-limit, graphql, evidence-grading, refuse-to-synthesize, fail-open, hub-spoke, ADR-026, ADR-102]
source_observations:
  - "Measured mid-release: the host's GraphQL pool sat at 0/5000 while its REST pool sat at 4966/5000. Every Issue-and-PR command failed while direct REST paths kept working, and the launch gate rendered PROCEED throughout — it was reading a different exhaustion surface entirely."
  - "The rate-limit endpoint returns each pool's limit, remaining, used and reset, and repeated reads during one session left the REST pool's used counter at zero — so the probe does not draw against the pools it reports."
  - "Because the endpoint is unmetered, an exhausted pool presents as a SUCCESSFUL read returning zero remaining, never as a probe failure. A probe failure therefore evidences an instrument or authentication fault and carries no exhaustion signal at all."
  - "The usage-window axis has no equivalent instrument: the platform-side quota surface is not queryable from within a session, so its figures are projections of an operator-stated band decayed for elapsed time."
  - "The protocol's refuse-to-synthesize rule asserted of `this check` that it does not measure remaining quota and that no verdict it renders may be presented as a measurement. Read as a blanket claim it becomes false the moment one input is instrument-read."
  - "A consuming rule in the bridge enumerates the briefing-triggering verdicts BY NAME rather than as `any non-PROCEED`. A newly minted verdict token would therefore have matched nothing, and a blocked launch would have proceeded silently."
  - "The governing hub skill justified gating every singleton launch on the ground that the gate costs zero tool calls. Making the gate measured falsifies that ground, so the justification had to be re-stated rather than left standing."
---

# ADR-144 — Checkpoint B's second axis is measured, not declared

## Status

**Accepted.** Authored at Engineering for the `ci-stable-under-transient-conditions` release, against the Collective Review scope-lock that admitted the governing hub skill's zero-tool-calls assertion into this card's scope.

## Context

The quota-budget protocol's Checkpoint B is the load-bearing gate on every spoke launch. It modelled exactly one exhaustion axis: the per-account usage window. That axis is, by construction, **unmeasurable from inside a session** — the platform-side quota surface is not queryable, so the check consults an operator-*declared* band and the elapsed time since the declaration. The protocol codified that limit honestly and forcefully in a refuse-to-synthesize rule: the check does not measure remaining quota, and no verdict it renders may be presented as a measurement. Every rendered figure carries an assumption label, never a source label. That rule is deliberate, load-bearing, and correct.

A second exhaustion axis existed the whole time and was modelled nowhere. The host's REST and GraphQL quotas are **separate pools** that deplete independently, and the failure is on record: the GraphQL pool reached zero while the REST pool sat essentially untouched. Every Issue-and-PR command failed while direct REST paths kept working — and the gate rendered PROCEED throughout, because it was reading the wrong surface. For a spoke whose entire output channel is a GitHub Issue comment, that is not degradation; it is total loss of the deliverable *after* the full usage-window draw has already been spent.

Adding the axis is straightforward. What is not straightforward is the property it drags in behind it. **The host-API axis is measurable and the usage-window axis is not.** The rate-limit endpoint returns each pool's remaining and limit, and — verified rather than assumed — the endpoint is itself unmetered, so the probe does not draw against the pools it reports.

That single asymmetry forces three things the protocol had never had to answer:

1. **The check would carry two evidence grades at once.** One axis yields a reading; the other yields a projection. The refuse-to-synthesize rule, written when there was only one axis, asserts its claim of *"this check"* — which becomes a false blanket statement the moment any input is instrument-read.
2. **Exhaustion on the new axis never presents as a probe failure.** Because the endpoint is unmetered, a depleted pool returns a *successful* read showing zero. A probe that *fails* is therefore reporting an instrument or authentication fault, and carries no capacity signal whatsoever.
3. **A new verdict token would have failed silently.** A consuming rule downstream enumerates the briefing-triggering verdicts **by name**, not as "any non-PROCEED". A freshly minted token would have matched nothing there, and a blocked launch would have proceeded with no briefing at all.

The cheap path was to add the axis and leave the refuse-to-synthesize rule alone. It would have passed every check, because nothing mechanically reads that rule. It would also have left a governing document asserting, of a check that now measures, that the check never measures.

## Decision

**The host-API axis is a measured input, and the refuse-to-synthesize rule is scoped to the usage-window axis rather than applied to the check as a whole.**

Four clauses follow from that, and each exists because the alternative is a specific defect:

- **Per-axis evidence grades.** A host-API figure is a reading and is labelled as one; a usage-window figure remains a projection and keeps its assumption label. **Neither grade is ever borrowed by the other axis, and the two axes are never averaged.** A number blending a reading with a projection is neither, and destroys both grades — which is why the axes combine by disjunction rather than arithmetic.
- **DEFER-dominant disjunction, minting nothing.** A host-API DEFER makes the gate render DEFER; otherwise the usage-window verdict passes through **unchanged and uninspected**. The verdict vocabulary is untouched, so every downstream rule that switches on the enum — including the one that enumerates its triggers by name — keeps working with no edit. The pass-through is deliberately opaque: whatever the usage-window branch renders is carried through as-is, so that branch can grow without the combination rule changing.
- **A probe failure fails OPEN, on evidentiary grounds and not convenience.** Exhaustion cannot present as a probe failure, so a probe failure carries no exhaustion signal. Failing closed there would deadlock the pipeline on a fault that says nothing about capacity. The basis is recorded as unstated, the axis renders PROCEED, and the reason is **rendered visibly** rather than swallowed.
- **The rendered line names both bases.** With two axes, a verdict naming no basis cannot tell a reader which axis produced it. Two-basis rendering is therefore an explicit obligation, not an inference — it is what keeps the fail-open branch from becoming a silent hole, because an unstated basis stays visible in the audit surface while being inert in the verdict.

The axis binds at Checkpoint B only. Checkpoint A stays usage-window-only, because a plan-time pool reading has no predictive value at Engineering time: the pools reset hourly and are drained by concurrent sessions the planner cannot observe. That omission is recorded in the protocol as a decision, so a later reader does not "fix" it by adding a reading with the authority of a measurement and the accuracy of a guess.

## Decision kernel (version-agnostic)

> When a gate acquires a second input that is **instrument-read** while its existing input is **declared**, a refuse-to-synthesize rule written for the declared input must be **scoped to that input**, never applied to the gate as a whole. Evidence grade attaches to the axis, not to the check; the axes combine by disjunction rather than by averaging, so no verdict blends a reading with a projection. Where exhaustion cannot present as a probe *failure*, a failed probe carries no exhaustion signal and the axis fails **open**, with the missing basis rendered.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Leave refuse-to-synthesize as a blanket rule** and add the axis under it | Rejected | Forces a genuine instrument reading to be labelled an assumption. That is the same class of error the rule exists to prevent — mislabelling what the session actually knows — pointed the other way. |
| **Delete the refuse-to-synthesize rule** | Rejected | The usage-window axis is still unmeasurable and still needs the rule. Deleting it to accommodate a second axis discards a correct, load-bearing constraint for an unrelated reason. |
| **Mint a new verdict token** for a host-API block | Rejected — on consequence, not taste | A downstream consuming rule enumerates its triggering verdicts by name. A new token matches nothing there, so a blocked launch launches anyway with no briefing. The failure would be silent. |
| **Combine the axes on a severity ladder** (take the maximum) | Rejected | Asserts a total ordering over verdicts the protocol never declared, and reaches into the wave and singleton verdict sections — an unnecessary and contended edit surface. |
| **Combine the axes as a weighted capacity score** | Rejected | Averages a reading with a projection into a figure that is neither, destroying both evidence grades. This is precisely what refuse-to-synthesize forbids in spirit. |
| **Declare the host-API state**, mirroring the operator-stated usage-window capture | Rejected | Structurally worse than the axis it imitates: the pools are drained by concurrent sessions the operator cannot see, so a human cannot state the value even in principle. |
| **Estimate pool draw** from a count of host calls | Rejected | Measured: repeated identical reads consumed nothing, because unchanged responses are not metered. An estimator built on a call count systematically over-predicts. |
| **Read the pools lazily**, after an observed command failure | Rejected | Purely reactive. The recorded defect is that the gate rendered PROCEED *before* the failure; a reading taken afterwards cannot gate anything. |
| **Read the pools per spoke launch** | Rejected | The reading cannot change between two launches issued in one routing turn, so the extra calls buy no fidelity. |
| **Fail CLOSED on an unreadable probe** | Rejected | Would deadlock the pipeline on an instrument fault that carries no capacity signal, since exhaustion presents as a successful read rather than a failure. |
| **Scope refuse-to-synthesize to the usage-window axis; read once per routing turn; combine DEFER-dominant; fail open with the basis rendered** | **Selected** | The only option that keeps the honest constraint where it belongs, adds a genuine measurement where one exists, mints nothing, and leaves behavior bit-for-bit unchanged whenever the pools are healthy. |

## Consequences

**The gate now costs a tool call, and the justification for gating every launch had to be re-stated rather than assumed.** The governing hub skill justified gating even a singleton launch on the ground that the gate costs zero tool calls. That ground is now false as stated. The *conclusion* survives — one read per routing turn, not per spoke, is still small enough that no launch shape is too small to gate — but it survives on a restated basis, because a justification nobody re-derives is one a future reader will discover is wrong at the worst moment.

**One call spends one axis to read the other.** The probe does not draw against the pools it measures, but it is a tool call, so it draws against the usage window. That cost is **cross-axis** and is stated in the protocol rather than hidden. It is bounded by reading once per routing turn and reusing the result for every launch issued in that turn.

**Behavior is unchanged whenever the pools are healthy — and that is an exactly testable claim, not a reassurance.** Because the combination rule is a pass-through on a host-API PROCEED, the gate's rendered verdict is identical to its pre-change verdict for the same usage-window inputs. The widening is strictly one-directional: the gate can now block in states where it previously could not, and can never proceed in a state where it previously blocked.

**The verdict enum survives as a cross-artifact contract.** Minting nothing is what lets every downstream consumer keep working unedited, including the by-name enumeration that would have silently dropped a new token. This is the load-bearing reason for the disjunction, and it is recorded so that a future reader tempted to add a more expressive token knows what it would break.

**An unstated host-API basis is inert in the verdict and non-inert in the audit surface.** The fail-open branch does not gate, but the rendering obligation still forces the missing basis onto the rendered line. That split is what keeps failing open from becoming an invisible hole: a launch that proceeded blind is distinguishable afterwards from one that proceeded on a healthy reading.

**Only two pools are modelled, and the others are a known gap rather than an oversight.** The endpoint returns a wider resource map whose other pools carry substantially tighter limits. They are deliberately not modelled here; the pool table is the extension seam, so a further pool lands as a row rather than a redesign.

## Reversibility

**CHEAP / Confidence HIGH.** The change is protocol and documentation prose across governed markdown, with no executable path, no schema change, no host-side state, and no data migration. Reverting the commit restores the prior text exactly, and because the combination rule is a pass-through on a healthy reading, a revert cannot strand any state the gate produced.

One residual is worth naming: the change also reaches a packaged skill's source files, whose compiled package is rebuilt rather than merged. Correct recovery there is a rebuild from the reverted source, not a byte restore of the package.

## Related ADRs

- **[ADR-102](ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md)** — fixes the substrate for the *usage-window* axis's per-spoke cost estimate. This ADR adds a different axis with a different instrument and does not disturb that choice; the two axes measure different quantities and neither substitutes for the other.
- **[ADR-026](ADR-026-spoke-launch-quota-reservation-telemetry-event.md)** — defines the startup-reservation telemetry event that remains declared-but-unwired. This ADR does not wire it: the gate's audit surface stays the rendered verdict line, and adding a second axis widens what that line must name rather than changing what the gate emits.
