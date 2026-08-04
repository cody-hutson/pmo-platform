<!-- reference-durability: allow-link -->
---
title: ADR-112 — Decision-time adherence extends the decision-confidence gate at the trigger layer
status: Proposed
date: 2026-08-03
release: agent-edit-discipline-codification
deciders: "Workspace owner (ratifies at the Stage 9 GO gate); design authored at Stage 5 Solutioning under the Principal Engineer persona; scope confirmed at Collective Review"
tags: [decision-confidence, adherence, agent-behavior, pre-action-gate, core-rules, trigger-predicate, reversibility-cheap]
source_observations:
  - "A session-review retrospective over a one-month window found that the most frequent agent failure class is not a missing rule but a held rule that fails to apply at the decision point. The largest single cluster — roughly thirteen instances — is trust-an-intermediate-signal-over-ground-truth, and every instance was already covered by a codified discipline that did not fire."
  - "The Decision-Confidence Protocol carries a signal, a threshold matrix, a bounded pause-to-learn loop, an anti-theater guard and a named consumer — and no trigger predicate. Its only trigger statement was the negative one in its omission-semantics section."
  - "That omission-semantics bullet and the decision-discipline triage table's status-reads exemption row BOTH excluded the exact moment the super-cluster fires: a status read promoted into a load-bearing claim. The gates did not under-fire by accident; they were specified not to fire there."
  - "Three of the four disciplines whose non-firing the retrospective reports are already bullets in the charter's Universal Preferences list, so adding a twenty-ninth bullet is the intervention already falsified for this failure class."
  - "The deploy check's mirror-pair array declares its pairs almost entirely as core/rules source paths mirrored into the workspace rules directory; the charter template and the disciplines directory have zero entries, so an edit to either never reaches the running agent."
  - "A corpus-wide probe for an existing decision-time adherence or rule-surfacing mechanism returned zero files against a sensitivity arm that returned thirteen, so the gap is genuinely unowned rather than mis-searched."
---

# ADR-112 — Decision-time adherence extends the decision-confidence gate at the trigger layer

## Status

**Proposed.** Flips to **Accepted** at this release's Stage-9 GO gate. Per the established precedent the flip is verified against this file's own `status:` field and is never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes in-flight pull-request claims. Re-verified at Engineering Commit 0: the union of both directories reports a contiguous `001..109` with no gaps and no duplicates, and the one open pull request claims ADR-110 and ADR-111. This ADR therefore takes **112**.

One consequence is worth stating plainly here rather than discovering at merge: **on this branch in isolation the sequence skips 110 and 111**, both held by that open pull request, and the platform's gap-free gate fails a gap as readily as a duplicate — verified live, the checker reports `GAP: the global sequence 001..112 is not contiguous`. That is the gate working correctly, not a mis-numbering. The sequence closes when the holder of 110/111 lands, so **the holder merging first is a pre-merge condition this release verifies before its own merge**. Taking 110 instead would trade a transient, self-closing gap for a permanent duplicate, which is the worse failure and is what the later-claimant-renumbers convention exists to prevent. If that pull request is ever abandoned rather than merged, the correct remedy is to renumber this record down to the true next-free slot as a full reference cascade — not to leave the gap standing.

## Context

The platform's rule corpus is not short of rules. It is short of a moment at which a rule is *retrieved*.

A one-month session-review retrospective found that the dominant agent failure class is a **held** discipline that does not surface at the decision point — not a missing one. Its largest cluster shares a single shape: an agent takes an **intermediate signal** (its own tool output, a delegated agent's self-reported summary, a population that happens to be empty right now) and promotes it into a load-bearing claim without reading the thing the claim is actually about. Every instance in that cluster was already covered by a codified discipline.

Two structural facts explain why the existing gates were silent rather than merely ignored.

**First, the pre-action gate has no trigger.** The Decision-Confidence Protocol specifies, in order: a three-source consistency signal, a reversibility × autonomy threshold matrix, a bounded pause-to-learn loop, an anti-theater guard, and a named consumer. Read end to end, it says a great deal about *how* to decide and nothing about *when it must fire*. Its only trigger statement is a negative one, in its omission-semantics section.

**Second, that negative statement excluded the failure moment by name.** The protocol's omission bullet exempted "observations / status / evidence citations" from computing any signal, and the decision-discipline triage table's `Exempt: Status reads` row exempted the same class from the briefing mechanisms. Both are correct about a read that stays a read. Neither distinguished a read that is then *stood on*. So the gates did not under-fire by accident — they were specified not to fire on a status read, and the super-cluster is precisely a status read promoted into a claim.

A third fact constrains the remedy. Three of the four disciplines the retrospective names as non-firing are **already bullets** in the charter's Universal Preferences list. Adding another bullet is the intervention already falsified for this failure class. And the charter template — like the disciplines directory — has **no mirror-pair entry** in the deploy check, so an edit to either never reaches a running agent at all. Only the rules directory carries a governed mirror contract.

The design question was therefore not "what rule is missing" but "what layer is missing, and where must it live to be loaded."

## Decision

**Extend the Decision-Confidence Protocol with an objective trigger predicate — a new `§ 1.0` — rather than paralleling it with a second pre-action gate.** The predicate fires when the agent is about to state, rely on, or act on a claim **and** that claim's ground is an intermediate signal rather than a direct read of its subject. The predicate is **observable, never introspected**: it asks *what is this claim standing on?*, not *am I unsure?* This is load-bearing rather than stylistic, because an agent that mis-reads a derived result as a fact is by construction not unsure — a confidence-keyed trigger is silent in exactly the case that most needs it.

**Narrow the two exemptions in the files that own them.** The protocol's omission bullet now distinguishes an observation reported *as* an observation (exempt) from an observation *promoted into a load-bearing claim* (decision-class, carries a checkpoint). The decision-discipline triage table gains one sentence stating the boundary: that table governs the **briefing**; the new rule binds the **claim**. No triage row is added, changed, or renumbered.

**Carry the deployed obligation as a new rule** — `core/rules/decision-time-adherence.md` — holding a bounded **Adherence Checkpoint Index** of five checkpoints keyed on observable claim signatures. Each row binds a governing rule, a required ground-truth read stated as a method rather than a host command, and a locus. The rule lands in the rules directory because that is the only tracked corpus surface with a governed mirror contract to the running agent; the mechanism stays in the spec, so neither file restates the other.

**Emit a one-line token when a checkpoint fires**, extending the shipped evidence-trailer shape rather than introducing a second trailer family. Where a governing rule already defines its own trailer, that trailer **satisfies** the checkpoint — no double emission.

**Bound the index by an admission criterion, not by author discretion.** The rule publishes a four-field declaration contract — `trigger`, `ground-truth read`, `token`, `locus` — and states that a discipline which cannot express an observable trigger is **not index-eligible**: it remains a rule and does not become a checkpoint. This is what keeps the index from becoming the twenty-nine-and-climbing surface it replaces, and it is the consumable input the four sibling authoring disciplines in this release are designed against.

**Alternatives considered and rejected** (recorded so they are not re-litigated):

| Option | Disposition | Reason |
|---|---|---|
| A parallel point solution in the rules directory, with no seam extension | **Rejected** | Two pre-action gates with overlapping domains force the agent to first decide *which gate applies* — and that indecision is the same class of non-firing this ADR exists to fix. It would also leave the protocol's omission bullet asserting the opposite of a sibling rule: a contradiction across two sources of truth. |
| A pre-tool-use hook that detects an un-grounded claim and injects the rule | **Deferred, not rejected** | The strongest mechanical teeth, but a hook observes a *tool call* while this trigger is *claim*-shaped, so a hook cannot see the moment. The platform separately records the hook-deploy path and a subagent hook-bypass gap as open blockers. Recorded as a fast-follow. |
| A new row in the decision-discipline triage table | **Rejected** | That table's mechanisms are Decision-Briefing templates. Firing three briefing templates on every probe result *is* the universal friction the acceptance criteria forbid. The disciplines directory also has no mirror pair. |
| A twenty-ninth bullet in the charter's Universal Preferences list | **Rejected** | Three of the four non-firing disciplines are already bullets in that list, so this is the intervention already falsified for this failure class. The list has no trigger, no observable, and no admission criterion, so it cannot express a checkpoint — and it has no mirror pair. |
| Add the check to each consuming skill definition | **Rejected** | N-way duplication across skills, and the super-cluster fires in ad-hoc conversational turns where no skill is loaded. |

## Consequences

**Positive.** One pre-action gate family rather than two, so there is no which-gate ambiguity to resolve at the moment of decision. The exemption and its narrowing stay co-located in the file that owns each. The index is bounded by a stated admission criterion rather than by author discretion, so it cannot grow to cover everything. Four sibling disciplines in this release gain a consumable surfacing contract instead of becoming four more clauses that may not fire. The obligation lands on the one corpus surface with a governed mirror contract, so it can actually reach a running agent. And because a fired checkpoint emits an observable token, adherence becomes reviewable rather than assumed.

**Negative, and stated plainly.** The teeth are **governance-layer only** until a hook layer ships: the mechanism's enforcement is the agent honoring the index plus a reviewer inspecting the emitted token. Nothing blocks an un-tokened claim mechanically.

**A second negative, which is easy to misread as green.** The deploy check **detects** mirror drift; it does not **push** the mirror. Provisioning the rule into the workspace rules directory is an operator-side manual step, and until it is done the check emits a clean `SKIP` for the new pair. That `SKIP` is the correct signal for a fresh checkout or a continuous-integration run, and it is **not** evidence that the rule reached the running agent. Reporting the discipline "live" on the strength of a repo-level read alone would be exactly the intermediate-signal promotion this ADR exists to catch.

**Scope discipline.** Two checkpoints cite the charter as the definitional home of the discipline they bind. The index **cites and never restates**, so no shadow source of truth is created: a governing rule's content changes at its own home with zero index edit.

## Reversibility

**CHEAP / Confidence HIGH.** Every edit is additive: one new rule file, one new spec section inserted ahead of an existing one without renumbering, one narrowed exemption clause, one appended composition row, one appended array entry, one appended sentence, and two enumeration cascades. A revert of the release restores the prior state exactly, and the deploy check's mirror-pair set returns to its prior count. No data migration, no schema change, no consumer contract broken.

## Related ADRs

- [ADR-047](ADR-047-decision-confidence-compose-posture.md) — the decision-confidence compose posture. This extension **is** that posture applied: the protocol gains a layer it lacked rather than a sibling it would contradict.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — the substrate-versus-canonical precedent that governs translating a deployed-mirror path reference back to its tracked corpus home.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — extend-before-create. The determination recorded here is a split one: **extend** the spec, because its existing loop and cross-check primitives are the ones the mechanism needs; **create** the rule, because the spec directory has no mirror contract and none of the existing rules governs agent decision behavior.
- [ADR-030](ADR-030-hook-registry-drop-in-with-generated-index.md) — the hook registry, which would host the deferred mechanical-teeth layer if and when its two recorded blockers clear.
