---
title: Decision-Confidence Protocol
purpose: Canonical mechanism for an agent to decide proceed-vs-pause-vs-escalate on a pending decision — a 3-source consistency signal (never verbalized self-confidence), a reversibility × autonomy threshold matrix (no global numeric cutoff), and a bounded pause-to-learn loop that injects new external signal. Consumed by decision-class pipeline stages and skills as a pre-action gate.
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: "Decision-class skills and pipeline stages (pre-action gate across the six in-scope decision-domains: Deferrals, Estimations, Slicing & Decomposition, Internal Knowledge Depth, Tool Use, Design & Architecture); the Stage-4 currency-check (named consumer); the Adherence Checkpoint Index in core/rules/decision-time-adherence.md (named consumer — the deployed trigger layer of the § 1.0 predicate)"
applies_to: Any agent decision point across the six in-scope decision-domains (Deferrals, Estimations, Slicing & Decomposition, Internal Knowledge Depth, Tool Use, Design & Architecture); decision-class skills and pipeline stages; the Stage-4 currency-check (named consumer).
parallel_to: reversibility-protocol.md (the cost-of-error axis) + autonomy-tiers.md (the standing-authorization axis) — this protocol composes both as its two threshold axes, never restating their tables. Imports discovery-discipline.md § 2.5 as the pause-to-learn gap-closer; registers a 3rd pre-action sibling alongside autonomous-execution-model.md Retry/Escalate; reuses decision-discipline.md verification + ceremony-guard mechanisms.
source: "The decision-confidence Research spike (COMPOSE posture, hard design constraints); the Stage 5 Solutioning design; co-developed with the Define ADR sibling. See § Provenance."
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# Decision-Confidence Protocol

## Purpose

This protocol operationalizes the question an agent faces *before* it acts on a non-obvious decision: **proceed now, pause to learn, or escalate?** It supplies (1) a confidence **signal** derived from observable consistency cross-checks — never the agent's verbalized self-confidence; (2) a **threshold model** that scales the proceed-vs-pause decision to the action's reversibility tier crossed with its autonomy tier, because no single global numeric cutoff is defensible; and (3) a **bounded pause-to-learn loop** that, when the signal is low, injects new external signal, terminates against a budget and explicit exit conditions, and routes the residue to escalation rather than stalling.

The protocol is a **compose, not a redefine** layer. It does not invent a new tier vocabulary, a new triage, or a new escalation surface — it binds the ones the platform already has into a single pre-action gate. The cost-of-error axis is `reversibility-protocol.md`; the standing-authorization axis is `autonomy-tiers.md`; the gap-closer is `discovery-discipline.md` § 2.5; the escalation surface is `autonomous-execution-model.md`'s Escalate Pattern; the verification primitives and ceremony guards are `decision-discipline.md`. This protocol is the missing connective tissue between those five docs — the **mid node** in the `discovery → [decision-confidence] → RCA` sequence. `[SOURCE: decision-confidence Research spike — COMPOSE posture]`

## Definition

**Decision-confidence** is an agent's grounded justification for proceeding with a pending decision, measured by the *consistency of independent cross-checks under the conclusion* — not by how certain the agent reports feeling. The distinction is load-bearing and is the protocol's first hard constraint.

| | Decision-confidence (this protocol) | Verbalized self-confidence (rejected) |
|---|---|---|
| **What it is** | An observable composite: do independent derivations agree, is the gap nameable, what is the weakest evidence label? | An introspected self-report ("I'm 90% sure"). |
| **Why** | Consistency across independent paths is checkable by a reviewer and by a gate. | A self-report is unfalsifiable and is the least-trustworthy signal in the evidence. `[SOURCE: Research spike hard design constraints]` |
| **Status in this protocol** | The **only** admitted signal (§ 1). | **Named and rejected** as an input (§ 1, § 5). A gate that reads a self-report back in is a guard violation. |

Decision-confidence is **paired with but distinct from** reversibility (the *what-if-wrong cost*, per `reversibility-protocol.md` § Definition) and from autonomy (the *who-acts-under-what-authorization*, per `autonomy-tiers.md` § Definition). All three travel together: the signal says *how grounded the conclusion is*; reversibility says *how expensive being wrong is*; autonomy says *how much standing authorization already exists*. The threshold model (§ 2) is exactly the rule that combines them. `[INFERRED: from reversibility-protocol.md § Definition confidence-pairing + autonomy-tiers.md § Definition orthogonality]`

This protocol governs **decision-class** work in the sense `decision-discipline.md` § 1.1 defines it — a recommendation, a proceed/defer choice, a plan, an escalation, a proposed action. It does not fire on observations, status summaries, or evidence citations (those are not decisions; see § 6 omission semantics).

## § 1.0 — The objective trigger predicate

The sections below specify *how* the gate decides. This section specifies *when it must fire* — the layer the protocol previously left unstated, and the reason a held rule can be correct, available, and still not applied.

**The predicate.** The gate fires when **both** hold: (1) the agent is about to state, rely on, or act on a claim; and (2) that claim's ground is an **intermediate signal** — something derived, secondhand, or transient — rather than a direct read of the thing the claim is about. Three intermediate-signal shapes recur: the agent's **own tool output** (a search result, an exit code, a count it produced), **another agent's or tool's self-report** (a delegated summary, a "clean" verdict, a status line), and a **transiently-observable population** (a queue, a list, a set that can be empty now and non-empty in an hour).

**The predicate is observable, never introspected.** It asks *what is this claim standing on?* — not *am I unsure?* This is load-bearing rather than stylistic: **a gate with a self-assessed trigger cannot fire on a moment the agent does not perceive as a decision.** An agent that mis-reads its own derived result as a fact is, by construction, not unsure — so a confidence-keyed trigger is silent in exactly the case that most needs it. This predicate exists for that case. It is the same constraint § 1.3 applies to the signal, applied one layer earlier: § 1.3 forbids a self-report as an *input*; § 1.0 forbids it as a *trigger*.

**Division of labor with the deployed rule.** This section owns the predicate. The **deployed trigger index** — the bounded set of checkpoint signatures, each binding a governing rule, a required ground-truth read, and an emitted token — lives in `core/rules/decision-time-adherence.md`, together with the index-eligibility gate that bounds its growth. This spec says *when the gate fires*; that rule says *which checkpoint fires and what is emitted*. Neither restates the other.

## § 1 — The Confidence Signal

The signal is a **composite from three observable sources**, each independently checkable, collapsed to a small ordinal state. It is deliberately *not* a number and *not* a self-report.

### 1.1 The three signal sources

| # | Source | What it observes | Why it is trustworthy (not a self-report) |
|---|---|---|---|
| **CS-1** | **Cross-check agreement** | Does an independent path corroborate the conclusion? A second tool or query, a re-derivation, or a canonical-source read per `decision-discipline.md` § 2.1 Localization Check + § 2.1.1 verification primitives. | Agreement across independent derivations is observable as agree/disagree; it is the Research-preferred consistency signal, not an introspection. `[SOURCE: decision-discipline.md § 2.1.1]` |
| **CS-2** | **Gap-namability** | Can the agent name the *specific* missing fact — a file, a value, a dependency state — rather than only "I'm unsure"? | A named gap is checkable and routable; a vague unease is neither. This operationalizes the "name the specific gap" constraint. `[SOURCE: Research spike hard design constraints]` |
| **CS-3** | **Evidence-label floor** | What is the *weakest* evidence label under the conclusion, using the CLAUDE.md vocabulary `[SOURCE]` > `[INFERRED]` > `[ASSUMPTION – CONFIRM]`? | Reuses the existing five-label evidence vocabulary as a grounding floor; an `[ASSUMPTION – CONFIRM]` under a load-bearing claim is an observable low-ground signal, not a feeling. `[SOURCE: CLAUDE.md § Universal Preferences — Evidence quality labels]` |

### 1.2 The collapse rule — a three-value signal state

The three sources collapse to one of three ordinal states (mirroring how `staleness-confidence-standard.md` collapses many mechanisms to a few bands — small, ordinal, auditable):

- **`CONVERGENT`** — CS-1 corroborated **and** CS-3 floor ≥ `[INFERRED]`. No load-bearing gap; the conclusion is proceed-eligible (the matrix still decides whether it actually proceeds).
- **`DIVERGENT`** — CS-1 independent paths disagree, **or** CS-2 names a gap that would change the conclusion. A real, *named* gap exists.
- **`UNGROUNDED`** — CS-3 floor is `[ASSUMPTION – CONFIRM]` on a load-bearing claim **and** CS-1 has no corroborating path. The conclusion rests on an unverified assumption.

### 1.3 The rejected signal (hard constraint)

Verbalized self-confidence — "I'm 90% sure," "I feel good about this" — is **NOT an input** to the signal. It is named here as the rejected signal so that a downstream gate or guard can flag any implementation that smuggles a self-report back in. The signal must be reconstructable from CS-1/CS-2/CS-3 observations alone; if a proceed decision cannot cite which source produced `CONVERGENT`, the gate has been bypassed. `[SOURCE: Research spike — "do NOT gate on verbalized self-confidence (least trustworthy)"]`

## § 2 — The Threshold Model (Reversibility × Autonomy)

There is no defensible single global numeric cutoff. `[SOURCE: Define scope; Research spike]` Instead, the signal state from § 1 selects an action from a **two-axis decision matrix** keyed on the two existing tier specs — `reversibility-protocol.md` (CHEAP → IRREVERSIBLE) as the cost-of-error axis, `autonomy-tiers.md` (Tier 0 → Tier 3) as the standing-authorization axis. The matrix encodes the Research rule "scale the pause to cost-of-error × fallback quality": reversibility approximates cost-of-error, autonomy approximates how much fallback (standing authorization) already exists.

This protocol **does not restate** the four reversibility tiers or the four autonomy tiers — it references them. For tier definitions and observable indicators, read `reversibility-protocol.md` § The Four Tiers and `autonomy-tiers.md` § Tier 0–3. `[SOURCE: CLAUDE.md § Quality Standards — "Parameterize over hardcode"]`

### 2.1 Action vocabulary

Three actions, each routing to an existing surface:

- **PROCEED** — act, carrying the reversibility tier label per `reversibility-protocol.md` § How to apply the tier.
- **PAUSE-TO-LEARN** — run the bounded loop (§ 3) to inject new external signal before deciding.
- **ESCALATE** — surface a Decision Briefing per `autonomous-execution-model.md` § Escalate Pattern (the gap + what was tried becomes the briefing Context), tiered per `decision-discipline.md` § 3.

### 2.2 The matrix

The cell action is a function of the § 1 signal state (rows) and the reversibility tier (columns). Autonomy tier modulates the IRREVERSIBLE column per invariant I1 below; for CHEAP–EXPENSIVE the autonomy axis enters via the I2 ceiling, not by relaxing the cell.

| Signal ↓ / Cost → | CHEAP | MODERATE | EXPENSIVE | IRREVERSIBLE |
|---|---|---|---|---|
| **CONVERGENT** | PROCEED | PROCEED | PROCEED (state rollback) | PROCEED **only at Autonomy Tier 0/1** (operator sign-off already gates it); else ESCALATE |
| **DIVERGENT** | PROCEED (cost trivial) | PAUSE-TO-LEARN | PAUSE-TO-LEARN → ESCALATE if unresolved | ESCALATE (never auto-proceed) |
| **UNGROUNDED** | PAUSE-TO-LEARN | PAUSE-TO-LEARN | ESCALATE | ESCALATE |

Reading the matrix: a `DIVERGENT` signal *proceeds* at CHEAP (the cost of being wrong is trivial — pausing would be the theater) but *escalates* at IRREVERSIBLE (no learning loop can buy back an irreversible mistake). The same signal, different action, because the cost axis moved. This is the whole point of refusing a global cutoff.

### 2.3 Two cross-axis invariants

Both are inherited from the axis specs, not invented here — they are the composition guards that keep this gate from becoming a self-elevation path:

- **I1 — IRREVERSIBLE never auto-proceeds on a non-`CONVERGENT` signal.** This mirrors `reversibility-protocol.md` (IRREVERSIBLE requires sign-off regardless of confidence — § Confidence Pairing) and `autonomy-tiers.md` § Boundary Tests test 3 ("IRREVERSIBLE actions cannot be Tier 3"). An IRREVERSIBLE action under a `DIVERGENT`/`UNGROUNDED` signal routes to ESCALATE; under `CONVERGENT` it still requires the operator sign-off the Tier-0 gate already imposes. `[SOURCE: reversibility-protocol.md § Confidence Pairing; autonomy-tiers.md § Boundary Tests]`
- **I2 — the matrix lowers ceremony, never raises autonomy.** A cell may force a PAUSE or an ESCALATE, but it can **never** grant an action a higher autonomy tier than `autonomy-tiers.md` already permits. Decision-confidence is a brake, not an accelerator: a `CONVERGENT` signal does not promote a Tier-1 draft into a Tier-3 auto-write. This blocks the gate becoming a self-elevation path (the FM-3 self-elevation failure mode in `autonomy-tiers.md`). `[SOURCE: autonomy-tiers.md § Failure modes FM-3]`

## § 3 — The Bounded Pause-to-Learn Loop

When the matrix routes to PAUSE-TO-LEARN, the agent runs a bounded loop whose job is to **inject new external signal**, not to re-think the same inputs. The loop's gap-closer is `discovery-discipline.md` § 2.5 knowability triage — that import is what turns "pause" into a *directed* gap-close instead of an open-ended stall.

### 3.1 The five-step loop

1. **Name the gap.** Reuse the CS-2 named gap from § 1 — the loop never starts from vague unease.
2. **Triage knowability** per `discovery-discipline.md` § 2.5: **Knowable-now** → fetch the canonical source (a `[verify-before-recommend]` read); **Knowable-later** → spike / time-boxed investigation / Stage-5 design decision (exit the loop, route out); **Knowable-only-by-operating** → reversibility-MODERATE "ship-and-observe" (exit, route out). This is the load-bearing import. `[SOURCE: discovery-discipline.md § 2.5]`
3. **Inject the new external signal** — the fetch/derivation from step 2. A cycle that injects *nothing* new is a guard violation (§ 5): the loop has not learned, it has only stalled.
4. **Re-evaluate the § 1 signal** with the new input — recompute CS-1/CS-2/CS-3 and the collapsed state.
5. **Exit-or-iterate** against the budget and exit conditions (§ 3.2, § 3.3).

### 3.2 Budget

Default **1 cycle**, hard cap **2**. A pause-to-learn is cheaper than Retry (transient cap=3 in `autonomous-execution-model.md` § Escalate Pattern) and must terminate faster, because it sits *before* an action rather than on a transient failure mid-action. The budget is modeled on the iteration-threshold precedent in `autonomous-execution-model.md` (generic-boundary cap=2). `[SOURCE: autonomous-execution-model.md § Escalate Pattern iteration thresholds]`

### 3.3 Exit conditions

The loop ends when **any** of the four fires — satisfying the hard "must have an exit condition" constraint. `[SOURCE: Research spike — pause must be bounded + have an exit condition]`

- **E1 — Resolved.** The signal flips to `CONVERGENT` → re-enter the § 2 matrix and PROCEED.
- **E2 — Not-knowable-now.** § 2.5 routes the gap to Knowable-later or Knowable-only-by-operating → exit to a spike or a ship-and-observe decision, carrying the reversibility tier.
- **E3 — Budget exhausted.** The cap is reached and the signal is still `DIVERGENT`/`UNGROUNDED` → **ESCALATE** via `autonomous-execution-model.md` § Escalate Pattern; the named gap plus what was tried becomes the briefing's Context.
- **E4 — Cost-changed.** If learning reveals the action is more irreversible than first classified, re-enter the matrix at the higher tier (discovery-shifts-reversibility per `discovery-discipline.md` § 5.4). `[SOURCE: discovery-discipline.md § 5.4]`

## § 4 — Six-Domain Application

The protocol is domain-general, not bespoke per decision type. The table below shows, per in-scope decision-domain, the dominant signal source (§ 1) and the most common pause-routing (§ 3) — so a consumer can see how the same mechanism instantiates across the six domains named in scope. `[SOURCE: Define scope — six in-scope decision-domains]`

| Decision domain | Dominant signal source | Typical reversibility band | Typical pause routing |
|---|---|---|---|
| **Deferrals** (defer vs. do-now) | CS-1 — does roadmap/priority state corroborate the defer? | MODERATE | E1: fetch canonical priority / roadmap state |
| **Estimations** (sizing / effort) | CS-3 — is the estimate `[INFERRED]` or `[ASSUMPTION – CONFIRM]`? | CHEAP–MODERATE | E2: knowable-only-by-operating → ship a ranged estimate + observe |
| **Slicing & Decomposition** | CS-2 — can the cleavage point be named? (ties to `discovery-discipline.md` § 2.4) | MODERATE | E1: fetch the dependency / file-contention map |
| **Internal Knowledge Depth** (do I actually know this?) | CS-3 floor — the canonical `UNGROUNDED` trigger | varies | E1: fetch the canonical source — the purest `[verify-before-recommend]` case |
| **Tool Use** (which tool / is the call right?) | CS-1 — cross-check via dry-run / read-back corroboration | CHEAP–EXPENSIVE | E1: dry-run / verify-post-write |
| **Design & Architecture** | CS-1 + CS-2 — cross-check against ADRs; name the unknown | EXPENSIVE–IRREVERSIBLE | E3: escalate fast (high cost axis routes the matrix to ESCALATE) |

## § 5 — The Anti-Theater Guard

A pause-to-learn that does not actually learn is theater. The guard makes the loop's three load-bearing properties **observable**, so a reviewer or a downstream gate can confirm a pause was real and not a stall dressed up as diligence. The guard's *specification* lives here (these are properties of the loop this spec defines); its *live wiring* into a consumer is the Create-stage build's responsibility.

| Guard signal | Observable | Where in the loop | Violation reads as |
|---|---|---|---|
| **New-signal-injected** | A pause cited a *specific* external fetch/derivation (a file read, a tool call, a re-derivation) that was not in the inputs before the pause. | § 3.1 step 3 | A pause that re-states the same inputs and "concludes" without fetching anything. |
| **Bounded** | The loop ran ≤ the budget (default 1, cap 2) and the cycle count is reportable. | § 3.2 | An unbounded re-think with no cycle ceiling. |
| **Has-exit** | The loop terminated on a named exit condition E1–E4. | § 3.3 | A pause that neither resolved (E1), routed out (E2/E4), nor escalated (E3) — i.e., a silent stall. |

A loop that cannot demonstrate all three is not a pause-to-learn; it is a stall, and the guard flags it. The guard reuses `decision-discipline.md` § 5 ceremony-management guards as its enforcement posture — the question is the same one § 5 asks of any process step: did observable work happen, or only paperwork? `[SOURCE: decision-discipline.md § 5 Ceremony-Management Guards]`

## § 6 — Named Candidate Consumer

Per the AC "≥1 candidate live consumer named (handed to Create)," the **primary named consumer is the Stage-4 currency-check** — the Stage-4 Phase A0 bundle-refresh trigger evaluation, a live decision point that today decides amend / re-bundle / defer / no-op on a bundled milestone. It is a fitting first consumer because (a) it is a real Deferral/Slicing-class decision, and (b) it *already* composes discovery posture — Phase A0 is a named discovery surface, so the § 3 import seam exists without new plumbing. `[SOURCE: discovery-discipline.md Stage-4 Phase A0 discovery surface; decision-discipline.md § 2.1.1 audit-snapshot reconciliation (the same currency discipline at the recommendation surface)]`

A roadmap-maintenance skill is the **preferred** live consumer *if it ships in the same window* — but this protocol does **not** hard-bind to it; the Stage-4 currency-check keeps the consumer independent of any in-flight skill. This section satisfies the Define→Create handoff: the Create slice's scope is "the consumer named in the Define spec," and this is that name.

The **second named live consumer** is the **Adherence Checkpoint Index** in `core/rules/decision-time-adherence.md` — the deployed trigger layer this spec's § 1.0 predicate governs. Its relationship to the gate is directional and narrow: a checkpoint's required ground-truth read is performed *first*, and the read's outcome enters this protocol's § 2 threshold matrix only when it comes back `DIVERGENT` or `UNGROUNDED` (the read contradicts the claim, or cannot be performed). A corroborating read carries the checkpoint's token and proceeds without invoking the matrix — the checkpoint is the cheap rung, this gate is the expensive one, and routing every corroborated read through the matrix would be the ceremony § 5 exists to catch.

### 6.1 Omission semantics — when the protocol does NOT fire

The gate is for decisions, not for everything:

- **Observations / status / evidence citations reported _as_ observations** — not decision-class (per `decision-discipline.md` § 1.1); no signal computed. **But an observation _promoted into a load-bearing claim_ is a decision-class input** and carries its adherence checkpoint per `core/rules/decision-time-adherence.md` § 2. The distinction is the § 1.0 predicate: a read that stays a read is exempt; a read the agent then stands a conclusion on is not. This narrowing is deliberate — the unqualified form of this bullet exempted the exact moment the recurring adherence failures occur.
- **A well-understood one-line action with a `[SOURCE]`-floor and a CHEAP tier** — `CONVERGENT` at CHEAP is PROCEED by the matrix; invoking the loop would be the theater the guard exists to catch.
- **An action already covered by a named standing authorization** — autonomy classification governs; this protocol does not re-open an approval the framework already granted (it lowers ceremony, never raises it — I2).

## § 7 — Composition with the Sibling Docs

This protocol composes five existing docs; the relationship to each is stated here and must agree, cell-for-cell, with the Define ADR's per-doc relationship table.

| Sibling doc | This protocol's relationship | Direction |
|---|---|---|
| [`reversibility-protocol.md`](reversibility-protocol.md) | The **cost-of-error axis** of the § 2 matrix. Referenced, never restated. The protocol promotes confidence from a *label* (its confidence-pairing) toward a *gate* — that label→gate edit is the Create slice's single-writer change, not this spec's. | composes (axis) |
| [`autonomy-tiers.md`](autonomy-tiers.md) | The **standing-authorization axis** of the § 2 matrix. Referenced, never restated. Invariants I1/I2 cite its Boundary Tests and FM-3. | composes (axis) |
| [`discovery-discipline.md`](../disciplines/discovery-discipline.md) | § 2.5 knowability triage is the § 3 loop's gap-closer (step 2); § 5.4 discovery-shifts-reversibility is exit E4. This protocol is the **mid node**: discovery (pre-artifact) → [decision-confidence] → RCA (post-failure). | imports |
| [`autonomous-execution-model.md`](../disciplines/autonomous-execution-model.md) | The PAUSE-TO-LEARN trigger is the **3rd pre-action sibling** to Retry/Escalate; ESCALATE (E3) routes to its Escalate Pattern; the § 3.2 budget is modeled on its iteration thresholds. Registering the 3rd sibling in that file is the Create slice's additive edit, not this spec's. | registers-into |
| [`decision-discipline.md`](../disciplines/decision-discipline.md) | CS-1 reuses its § 2.1 Localization Check + § 2.1.1 verification primitives; ESCALATE tiering uses its § 3 triage; the § 5 anti-theater guard reuses its § 5 ceremony guards. | reuses |
| [`core/rules/decision-time-adherence.md`](../rules/decision-time-adherence.md) | The deployed **trigger layer + obligation surface**. This spec owns the mechanism (§ 1.0 predicate, § 1 signal, § 2 matrix, § 3 loop, § 5 guard); that rule owns which checkpoint fires and what token is emitted. Its § 6 declaration contract is what bounds the index. | deploys |

**Cross-reference constraint:** this file references its peers but introduces no runtime dependency on a *consumer* — the Stage-4 currency-check (§ 6) cites this file, not the reverse.

## Failure Modes

Per `failure-mode-standard.md` 5-field template (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) with category tag (TRIG / INPUT / PROC / OUT / HAND).

**FM-1 — Self-confidence smuggling (gating on a self-report)** — Category: INPUT

- *Signature:* A proceed decision cites "I'm confident" / a numeric self-rating instead of CS-1/CS-2/CS-3 observations; the signal state cannot be reconstructed from observable sources.
- *Conditional:* Do NOT collapse the three-source signal into a verbalized self-confidence judgment when the conclusion is load-bearing, because a self-report is the least-trustworthy signal in the evidence and is unfalsifiable by a reviewer. `[SOURCE: Research spike hard design constraints]`
- *Root cause:* Agent reaches for the fast introspective answer ("do I feel sure?") instead of running the cross-check; the self-report is cheaper to produce than a CS-1 corroboration.
- *Mitigation:* § 1.3 names self-confidence as a rejected input; the guard (§ 5) requires the proceed decision to name which source produced `CONVERGENT`. A proceed that cannot cite a source is treated as gate-bypassed.
- *Principal-vs-junior response:* Junior — writes "confident, proceeding"; Principal — names the corroborating path ("CS-1: re-derived against the canonical roadmap state; CS-3 floor `[SOURCE]`") or runs the loop.

**FM-2 — Unbounded pause (the loop becomes a stall)** — Category: PROC

- *Signature:* The agent "pauses to learn" but iterates indefinitely, re-reasoning over the same inputs without injecting a new external signal and without hitting an exit condition.
- *Conditional:* Do NOT re-enter the pause loop a third time, or re-run it without a step-3 new-signal injection, because the budget is 1 (cap 2) and a cycle that injects nothing has not learned — it has stalled, and the matrix would have routed an unresolved signal to ESCALATE.
- *Root cause:* Agent treats "pause" as permission to keep thinking rather than as a directed fetch; conflates deliberation with learning.
- *Mitigation:* § 3.2 hard cap (2) + § 3.3 E3 (budget-exhausted → ESCALATE) + the guard's bounded + new-signal-injected signals (§ 5). A pause with no fetch is a guard violation.
- *Principal-vs-junior response:* Junior — loops "let me reconsider" with no new input; Principal — fetches the named gap once, re-evaluates, and escalates on cap with the attempt log as Context.

**FM-3 — Global-cutoff regression (one threshold for all decisions)** — Category: PROC

- *Signature:* A consumer applies a single proceed/pause threshold regardless of reversibility or autonomy — e.g., "always pause when unsure" or "always proceed when CS-3 ≥ `[INFERRED]`" — ignoring the matrix.
- *Conditional:* Do NOT apply one global proceed-vs-pause cutoff across decisions of different reversibility, because the cost of being wrong is not constant — a `DIVERGENT` signal should proceed at CHEAP and escalate at IRREVERSIBLE, and a single cutoff destroys that scaling. `[SOURCE: Define scope — no clean global numeric cutoff exists]`
- *Root cause:* Agent reaches for a simple scalar threshold because it is easier to implement than a 2-axis matrix; over-simplifies the model the AC explicitly forbids.
- *Mitigation:* § 2 is a matrix, not a number; the column axis is mandatory. Invariant I1 forbids the IRREVERSIBLE column from collapsing to the CHEAP behavior.
- *Principal-vs-junior response:* Junior — "I'll pause whenever confidence is low"; Principal — reads the reversibility tier first, then selects the matrix cell.

**FM-4 — Self-elevation via the gate (confidence as an accelerator)** — Category: TRIG

- *Signature:* A `CONVERGENT` signal is used to justify acting at a higher autonomy tier than the action is authorized for — "I'm convergent, so I can auto-write this" on a Tier-1 draft surface.
- *Conditional:* Do NOT let a `CONVERGENT` signal promote an action above its `autonomy-tiers.md` ceiling, because this protocol lowers ceremony but never raises autonomy (I2) — confidence is a brake, not an accelerator, and a high signal on an under-authorized action is still under-authorized.
- *Root cause:* Agent misreads "the gate said proceed" as "the gate granted authority"; conflates the proceed-vs-pause decision with the who-acts decision.
- *Mitigation:* Invariant I2 (§ 2.3) caps the matrix at the autonomy ceiling; the gate output is PROCEED-at-the-existing-tier, never PROCEED-at-a-higher-tier. Cross-references `autonomy-tiers.md` FM-3 (self-elevation).
- *Principal-vs-junior response:* Junior — "convergent, so auto-writing the adjacent file"; Principal — proceeds only at the action's authorized tier; an adjacent action is tiered separately.

## Cross-Reference

- [reversibility-protocol.md](reversibility-protocol.md) — cost-of-error axis of the § 2 matrix; confidence-pairing label this protocol promotes toward a gate
- [autonomy-tiers.md](autonomy-tiers.md) — standing-authorization axis of the § 2 matrix; Boundary Tests + FM-3 cited by invariants I1/I2
- [discovery-discipline.md](../disciplines/discovery-discipline.md) — § 2.5 knowability triage (§ 3 gap-closer); § 5.4 discovery-shifts-reversibility (exit E4); the upstream node in discovery → [this] → RCA
- [autonomous-execution-model.md](../disciplines/autonomous-execution-model.md) — Retry/Escalate/Rollback; PAUSE-TO-LEARN is the 3rd pre-action sibling; Escalate Pattern is exit E3; iteration thresholds are the § 3.2 budget precedent
- [decision-discipline.md](../disciplines/decision-discipline.md) — § 2.1 Localization Check + § 2.1.1 verification primitives (CS-1); § 3 triage (ESCALATE tiering); § 5 ceremony guards (§ 5 anti-theater guard)
- [staleness-confidence-standard.md](staleness-confidence-standard.md) — sibling collapse-to-bands exemplar (different axis: staleness depth, not decision certainty)
- [failure-mode-standard.md](../standards/failure-mode-standard.md) — 5-field template + category tags used in § Failure Modes (FM-1..FM-4)
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) — Evidence quality labels (CS-3 floor); Reversibility discipline; Verify-before-recommend

---

*This protocol is a foundation document. It composes `reversibility-protocol.md`, `autonomy-tiers.md`, `discovery-discipline.md`, `autonomous-execution-model.md`, and `decision-discipline.md`; it is consumed by the Stage-4 currency-check (§ 6) and any decision-class skill or pipeline stage that adopts the pre-action gate. The label→gate edit to `reversibility-protocol.md` and the 3rd-sibling registration in `autonomous-execution-model.md` are downstream single-writer changes, not part of this spec.*

## Provenance

This spec's design lineage, for audit only — not load-bearing on the protocol's content (the protocol reads version-agnostically above).

- #1612 — the decision-confidence Research spike that produced the COMPOSE posture and the four hard design constraints this spec operationalizes.
- #2283 — the Define task (spec + ADR) under which this spec was authored; carries the COMPOSE recipe and the per-doc relationship posture.
- #2286 — the Define ST1 sub-task that scoped this spec's acceptance criteria (signal, threshold, bounded loop, six-domain application, named consumer).
- #2285 — the downstream Create task that builds the gate, integrates the named consumer, and wires the anti-theater guard.
