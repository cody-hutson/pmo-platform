---
title: Decision-Time Adherence — Adherence Checkpoints
purpose: The operating rule that surfaces an already-held discipline at the moment of decision — a bounded index of observable trigger signatures, each binding a governing rule, a required ground-truth read, and an emitted token.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Decision-Time Adherence — Adherence Checkpoints

**Authoritative mechanism:** [`core/specs/decision-confidence-protocol.md`](../specs/decision-confidence-protocol.md). This rule is that protocol's **objective-trigger layer** and its deployed obligation surface. The protocol owns the confidence signal, the reversibility × autonomy threshold, and the bounded pause-to-learn loop; this rule owns *when the gate fires* and *what is emitted when it does*.

## Purpose

A rule the agent holds is not a rule the agent applies. The recurring failure is not a missing discipline — it is a **held discipline that does not surface at the moment of decision**. This rule closes that gap for one bounded, recurring class: **promoting a derived observation into a load-bearing claim**.

## § 1 — What fires a checkpoint

A checkpoint fires when **both** hold:

1. You are about to state, rely on, or act on a claim; **and**
2. The claim's ground is an **intermediate signal** — something derived, secondhand, or transient — rather than a direct read of the thing the claim is about.

Three intermediate-signal shapes recur: **your own tool output** (a search result, an exit code, a count you produced); **another agent's or tool's self-report** (a delegated summary, a "clean" verdict, a status line); and **a transiently-observable population** (a queue, a list, a set that can be empty right now and non-empty in an hour).

The trigger is **observable**, not introspective. It is never "am I unsure?" — an agent that mis-reads a derived result as a fact is, by construction, not unsure. It is: *what is this claim standing on?*

## § 2 — The Adherence Checkpoint Index

| ID | Trigger signature (observable) | Governing rule | Required ground-truth read | Locus |
|---|---|---|---|---|
| **DTA-1** | About to report a **zero / clean / absent / N-of-M** result produced by a probe you ran | [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) § 1 Rule 15 + § 8 (`PV-0`..`PV-6`) | Run the **sensitivity arm** in the same invocation shape and record its observed non-zero result; state the denominator and how it was obtained. A zero whose control arm also returned zero is a broken probe, not a clean result. | transient/ambiguous-state reads |
| **DTA-2** | About to rely on a **delegated agent's, subagent's, or tool's self-reported summary** as evidence | [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) § 8 `PV-3` (extraction) + § 7(d) (no self-referential validation) | Read the **underlying artifact** the summary describes, at its canonical home. A summary is a pointer to evidence, never the evidence. | close-out · planning |
| **DTA-3** | About to classify or conclude from a **population observed empty** at the moment of assessment (a queue, an in-flight set, an alert list) | [`CLAUDE.md.template`](../CLAUDE.md.template) § Universal Preferences — *Audit-baseline discipline* | **Pin the baseline**: a commit anchor plus a bounded recent window (or an analogous time-anchor); record it with the finding; re-check the population before the result is relied upon. | planning · close-out |
| **DTA-4** | About to **recommend** work derived from a point-in-time artifact — an analysis, an audit, a snapshot, a prior-session note, a summary, or recalled framing | [`decision-discipline.md`](../disciplines/decision-discipline.md) § 2.1.1 (Audit-Snapshot Reconciliation) + [`CLAUDE.md.template`](../CLAUDE.md.template) § Universal Preferences — *Verify before recommend* | Run § 2.1.1's verification primitives 1 + 2 (and 3 when the recommendation names a specific symbol or section). | planning |
| **DTA-5** | About to report a write or any externally-observable state mutation as **done** | [`CLAUDE.md.template`](../CLAUDE.md.template) § Quality Standards — *Write-first-speak-second* | **Read back the mutated state.** Report the observed post-state, not the intended one. | close-out |

The **Locus** column is the scope boundary, not decoration: these are the three loci where residual failures cluster. A claim outside them does not gain a checkpoint by resemblance.

## § 3 — The token

When a checkpoint fires, emit one line, inline, before or alongside the claim:

```
[DTA-<n>: <the ground-truth read performed> → <what was observed>]
```

**Composition rule (no double emission).** Where the governing rule already defines its own trailer, **that trailer satisfies the checkpoint**. `DTA-4` is discharged by the existing `[VERIFIED <YYYY-MM-DD>: <read> → <result>]` trailer; no `[DTA-4: …]` line is added.

A checkpoint that fired and emitted nothing is indistinguishable from a checkpoint that never fired. The token is what makes adherence reviewable — the same property [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) § 8 `PV-6` requires of a mechanized check.

## § 4 — What does NOT fire a checkpoint

Stated positively, so the index cannot creep:

- **A read that stays a read.** An observation reported *as* an observation — "the search returned three files" — carries no checkpoint. Only its **promotion** into a load-bearing claim does.
- **A direct canonical read.** You opened the file and read the line. There is no intermediate signal, so there is nothing to check.
- **Routine tool use with no claim attached.** Navigation, listing, opening — none of it fires.
- **A claim already covered by a stage's own gate.** Where a pipeline stage or skill already runs an equivalent grounding gate on the same claim, that gate discharges it. No double-gating.
- **The mechanism exemptions in [`decision-discipline.md`](../disciplines/decision-discipline.md) § 3.** Those remain exempt from the M1/M2/M3 Decision-Briefing mechanisms and this rule does not re-open them. This rule binds the **claim**; § 3 governs the **briefing**. They are different objects.

## § 5 — When the ground-truth read comes back wrong

The checkpoint's job ends at the read. What the read *says* is the protocol's job:

- Read corroborates the claim → the signal is `CONVERGENT` → proceed, carrying the token.
- Read contradicts the claim, or the read cannot be performed → the signal is `DIVERGENT` or `UNGROUNDED` → enter [`decision-confidence-protocol.md`](../specs/decision-confidence-protocol.md) § 2's threshold matrix and, where it routes there, its § 3 bounded pause-to-learn loop with exits `E1`–`E4`.

The checkpoint is a **brake, never an accelerator** — it can force a read, and it never grants an action a higher autonomy tier than it already holds (the protocol's invariant `I2`).

## § 6 — Declaration contract (what makes a rule index-eligible)

A discipline becomes a checkpoint only by declaring **all four** fields:

| Field | Requirement |
|---|---|
| `trigger` | An **observable** signature a reader can falsify — a tool-call shape, a turn shape, or a claim shape. "When the agent is unsure" is not a trigger. |
| `ground-truth read` | The specific read that discharges it, stated as a **method** (what to read, and what the read must establish) rather than as a host command. |
| `token` | The one-line observable emitted, or the name of the existing trailer it reuses. |
| `locus` | Which locus the checkpoint belongs to. A discipline with no recurring locus is not a checkpoint. |

**A discipline that cannot state an observable trigger is not index-eligible.** It remains a rule; it does not become a checkpoint. This gate — not author discretion — is what bounds the index.

## § 7 — Composition (compose, do not duplicate)

| Surface | Relationship |
|---|---|
| [`decision-confidence-protocol.md`](../specs/decision-confidence-protocol.md) | Owns the mechanism (signal / threshold / loop / guard). This rule is its § 1.0 trigger layer, deployed. |
| [`decision-discipline.md`](../disciplines/decision-discipline.md) § 3 | Governs the Decision **Briefing**. This rule governs the **claim**. Its exemptions stand unchanged. |
| [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) § 1 Rule 15 + § 8 | The governing rule for `DTA-1` / `DTA-2`. Cited, never restated — `PV-0`..`PV-6` live there. |
| [`reconcile-dont-annotate.md`](../disciplines/reconcile-dont-annotate.md) | The edit-time twin of `DTA-4`: verify before you recommend; reconcile when you are already editing. |
| [`autonomous-execution-model.md`](../disciplines/autonomous-execution-model.md) | Where a `DIVERGENT` read escalates (§ 5). |
