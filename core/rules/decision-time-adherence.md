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
| **DTA-6** | About to **create a new entry — or add a new durable claim to an existing entry — in the operator auto-memory store**, when the operator did not ask for it in this turn | [`memory-architecture.md`](../disciplines/memory-architecture.md) § 5 write rule 4 (*No unrequested save.*) | **Search the corpus for an existing governed home for the claim**, and state what the search returned. A governed home exists → do not save; the corpus is SSOT and a memory copy is a shadow SSOT. A home is in flight → save only as an eviction-pointer to it. No home **and** the claim is durable (still true and useful months from now) **and** non-obvious (hard to re-derive) → save, stating that justification. Anything else → **do not save**. | close-out |
| **DTA-7** | About to report a **rename, move, or delete as done** — the path, filename, section heading, identifier, key, or existence of a **referenceable** entity changed in this change | [`rename-reference-cascade.md`](rename-reference-cascade.md) § 2 (the sweep) + § 4 (the observable) | **Re-run the identical search for the old identifier**, over the same population searched before the change, and observe zero. The pre-change count is the sensitivity arm — a post-zero is evidence only where the same search returned non-zero first. The state a rename claim rests on is the **reference graph**, not the entity, so reading back the renamed entity alone does not discharge it: this is the identity-change specialization of `DTA-5`. | close-out |

The **Locus** column is the scope boundary, not decoration: these are the three loci where residual failures cluster. A claim outside them does not gain a checkpoint by resemblance.

## § 3 — The token

When a checkpoint fires, emit one line, inline, before or alongside the claim:

```
[DTA-<n>: <the ground-truth read performed> → <what was observed>]
```

**Composition rule (no double emission).** Where the governing rule already defines its own trailer, **that trailer satisfies the checkpoint**. `DTA-4` is discharged by the existing `[VERIFIED <YYYY-MM-DD>: <read> → <result>]` trailer, and `DTA-7` by the `[REFCASCADE: <invocation> over <population> → pre <N> / post 0]` trailer; no `[DTA-4: …]` or `[DTA-7: …]` line is added.

A checkpoint that fired and emitted nothing is indistinguishable from a checkpoint that never fired. The token is what makes adherence reviewable — the same property [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) § 8 `PV-6` requires of a mechanized check.

## § 4 — What does NOT fire a checkpoint

Stated positively, so the index cannot creep:

- **A read that stays a read.** An observation reported *as* an observation — "the search returned three files" — carries no checkpoint. Only its **promotion** into a load-bearing claim does.
- **A direct canonical read.** You opened the file and read the line. There is no intermediate signal, so there is nothing to check.
- **Routine tool use with no claim attached.** Navigation, listing, opening — none of it fires.
- **A claim already covered by a stage's own gate.** Where a pipeline stage or skill already runs an equivalent grounding gate on the same claim, that gate discharges it. No double-gating.
- **The mechanism exemptions in [`decision-discipline.md`](../disciplines/decision-discipline.md) § 3.** Those remain exempt from the M1/M2/M3 Decision-Briefing mechanisms and this rule does not re-open them. This rule binds the **claim**; § 3 governs the **briefing**. They are different objects.
- **An authorized or mechanical memory write.** `DTA-6` binds the *unrequested creation* of a durable claim in the operator auto-memory store, and nothing else. It does not fire on a save the operator asked for (the request is the authorization); on an eviction, eviction-pointer, or re-point performed under the encode-and-evict lifecycle (already gated by that lifecycle's corpus-presence check); on a maintenance edit that adds no new durable claim, including the index line accompanying an already-authorized save; on a write to any other memory surface (session state, corrections, portfolio, operational trackers, project files — each governed by its own row in the cross-surface contract); or on any read.

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
