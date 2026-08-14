<!-- reference-durability: allow-link -->
---
title: "ADR-133 — Degraded-state emit contract: a check reports its own measurement status"
status: Proposed
date: 2026-08-14
release: check-fail-open-elimination
deciders: "operator (Stage-4 gate: Release Class + scope; Collective Review scope-lock) + Stage 5 Solutioning spoke (design, D-1 through D-4) + hub adversarial evaluation (R1, verified rather than accepted) + Stage 6 Engineering spoke (implementation)"
tags: [probe-validity, review-discipline, deploy-check, emitter-class, fail-open, degraded-state, extend-before-create, vocabulary-canonicalization]
source_observations:
  - "Six checks across four surfaces emitted the same output for a degraded measurement and for a clean result. Each was found independently, by a different agent, on a different surface, none of them looking for a pattern."
  - "Three of the six were fixed independently, by three authors, with three different shapes, before any rule existed — the release resolver's four-token state enum, the SSOT kind-vocabulary reader's exit-3 partial-parse path, and the primitive sentinel's NOT-EVALUATED terminal state."
  - "Four prior-art mechanisms were already in the repository when the umbrella card was filed, and two more were surfaced at design time: a named DEGRADED-STATE CONTRACT bound twice in one file, and a denominator-plus-control instrument-form emit adopted by the seven most recently authored checks."
  - "The convention is therefore emergent rather than novel. Its job is to name what independent authors converged on and make it inheritable, not to invent a shape."
  - "Four divergent spellings of one state were live in a single file at the design baseline: the hyphenated terminal token (5 emitted), a space-separated variant (8 emitted), a third variant on the release-resolution axis (1), and the partial-state marker (1). One check was internally inconsistent — it set the hyphenated form as its own state value while emitting the space form at eight sites."
  - "The machine-readable status register was frozen with zero renames because three live branches compare against its string values; renaming for cosmetic tidiness would have authored a spec-vs-reality defect inside the canonicalization itself."
  - "A standalone tool on another module never sources the deploy surface (subject 0; the zero is usable — the extraction is 781 lines and a generic-token control arm returns 76). An emitter-only primitive therefore cannot reach one of the two live instances."
---

# ADR-133 — Degraded-state emit contract: a check reports its own measurement status

## Status

**Proposed.** Authored at Engineering for the `check-fail-open-elimination` release; ratified at that release's plan-review gate.

## Context

A family of checks shares one failure shape: **when the measurement breaks, the output is indistinguishable from success.** A missing label reads as "none scaffolded"; an unguarded escalating emitter contradicts a comment claiming it is warn-only; a traceback through a pipeline prints "no drift". In each case the check has a *degraded* state it cannot represent, so degradation silently collapses into the *clean* state, and a reader sees green without being able to tell whether the check ran, ran partially, or crashed.

The umbrella card asked which of four prior-art mechanisms already in the repository should *become* the shared primitive. That framing does not survive a read of the four. They are not four candidates for one slot — they answer four different questions:

| Mechanism | The question it answers | Axis |
|---|---|---|
| A structurally non-escalating emitter | *How* is a non-gating finding emitted, provably? | **Emitter** |
| A distinct input-failure exit code | *How* does the state cross a process boundary? | **Transport** |
| The `NOT-EVALUATED` sentinel | *What* state — the whole leg was not measured | **Vocabulary (terminal member)** |
| The `DEGRADED` marker | *What* state — measured, but partial or via a fallback | **Vocabulary (partial member)** |

Selecting one and discarding three ships a primitive that can either name a state it cannot emit, or emit a state it cannot name. Naming the category error is part of the decision.

Two further constraints shaped the answer. First, the governing probe-validity discipline already names this gap in its own words — its instrument-form obligation states that a check whose runtime output carries only a finding count leaves a reader unable to distinguish *zero found* from *nothing examined* — and then mandates the denominator-plus-control record without mandating a **measurement-occurrence** state. The clause stops one step short of closing the gap it describes. Second, the affected surfaces are in different languages on different modules, and one of them structurally cannot call a function defined on the other.

## Decision

**D1 — Adopt the composed contract, not one mechanism.** Freeze the state *vocabulary* (the terminal and partial members together) as a new rider in the probe-validity section of the review discipline; mandate the structurally-non-escalating emitter *shape* as the emitter class; mandate the input-failure exit code as the transport across a process boundary. The four mechanisms compose; they do not compete.

**D2 — Two registers, both frozen, neither invented.**

- **Register A — machine-readable status field:** `fetched` · `truncated` · `degraded` · `not-run` · `fixture`. Frozen **as-is, with zero renames**, because live consumer branches compare against these exact strings. On a non-measuring status the counters are **absent, never zero**, and a consumer must branch on the status before reading any counter.
- **Register B — human-readable emitted token:** `NOT-EVALUATED` (the whole leg was not measured) · `DEGRADED` (measured, but partial or via a fallback), closed at two members, with the mandated discriminator clause *"this is not a clean result"* on the terminal member.

Divergent spellings reconcile **to the hyphenated terminal form** — not because it was the majority spelling (it was not) but because it is the value the code already assigns and branches on, and because the space form is not a greppable token: it matches ordinary prose, and the grading probe for this convention is a grep. Freezing a token a grep cannot isolate would author a probe-validity defect into the convention that governs probe validity.

**D3 — The emitter-class taxonomy is the rule with teeth.** Every non-clean emit records a class, and the three classes are mutually exclusive:

| Class | Predicate | Gates? |
|---|---|---|
| **FINDING** | Measured; a real defect | Yes, at enforce |
| **ADVISORY** | **Measured**; the predicate cannot separate a legitimate state from a defect | **Never — structurally** |
| **NOT-EVALUATED** | **Not measured**, or measured only partially | **Never — structurally** |

ADVISORY and NOT-EVALUATED are both non-gating and **mean opposite things**: one says *"I measured and here is a signal I cannot gate on"*, the other says *"I did not measure."* Collapsing them is this record's own defect one level up.

**D4 — Extend the existing emitter family; do not parallel it.** The deploy surface's emitter family already models severity-class as one-function-per-class across five members. The NOT-EVALUATED class becomes a sixth member in that family's established shape — no mode branch, no failure-counter increment — inheriting the non-escalation guarantee verbatim. **In-place parameterization of the advisory emitter was rejected on evidence:** its log line asserts that the check is never enforce-capable, which is false of an enforce-capable check that merely could not read its input this run, and writing that assertion into the warn log the enforce-flip decision is read from would relocate the defect from a comment into an emitted record. Its greppable prefix is the one machine-readable point in the emit; two classes under one prefix re-creates the conflation the emitter exists to remove.

**D5 — The transport is conditional on the KIND of condition, not applied uniformly.** An **input failure** crosses a process boundary as the input-failure exit code and may gate. A **measurement outage** must never gate: it crosses **in band**, inside the emitted line, per the fan-in-never-gate obligation. A surface whose consumer treats any non-zero exit as a hard failure would convert a measurement outage into a gate, which is the same fail-open class inverted.

## Decision kernel (version-agnostic)

A check's emitted state set must carry a **distinct member for every reachable state of its predicate**. Degraded and clean may never share a member. The degraded member never gates, and its counters are **absent rather than zero**.

## Alternatives Considered

**Emitter-only — a new function on the deploy surface, no vocabulary freeze.** Cheapest, one function, zero documentation churn. **Rejected on cross-surface reach:** a standalone tool on another module never sources the deploy surface, so one of the two live instances would remain a local guard — the precise outcome the umbrella card exists to prevent. It also leaves the release-wide conformance criterion with no frozen set to grade against. This was the runner-up.

**Vocabulary-only — freeze the tokens in the governing doc, write no code.** Language- and surface-agnostic; reaches every future instance. **Rejected for want of a forcing function:** every instance still hand-rolls its own guard, which is the multiple-local-guards outcome the card rejects, and it does not subsume the instance whose defect is an **emitter-class** error rather than a naming error.

**A new exit code for partial degradation.** Cross-language and machine-readable by construction. **Rejected on the card's own grounds:** roughly thirty call sites branch on the existing three-value exit contract, so adding a member makes every existing `else` branch silently wrong. Fixing a fail-open by authoring one of the same class is disqualifying.

## Consequences

**Positive.** Four spellings of one state collapse to one, and a check that was internally inconsistent — setting one form as its state value while emitting another — becomes self-consistent. The convention reaches every surface and language, so the next instance inherits the fix by reading one section rather than by copying a guard. The release-wide conformance criterion gains a frozen set to grade emitters and tool rows against. The class taxonomy turns the sibling emitter fix into a one-line call change plus a comment reconciliation rather than a second local guard.

**Negative, named.** Register A is frozen with `fixture` and `not-run` as members, which are per-check concerns rather than universal states; freezing them avoids a rename cascade today at the cost of a slightly loose enum, and a future tightening is a rename, i.e. a fresh decision. The instrument-form denominator-and-control emit is adopted by only a fraction of the check corpus and is **not** made mandatory here — mandating it retroactively is its own card; this rider **cites** that obligation rather than widening it.

**Blast radius.** The governing document carries a large first-order referrer set, but the change is **additive**: the overwhelming majority cite it by section, which a new rider is inherited by rather than broken by. Only referrers that **enumerate** the element series are consumers of the change, and every such enumeration is edited in the same release.

## Reversibility

**MODERATE · Confidence HIGH.** This changes an output vocabulary, so a revert after downstream adoption strands adopted tokens. Mitigated by construction: Register A is frozen with zero renames, so no live consumer changes meaning, and the terminal-token reconciliation is confined to one file plus one test harness. A post-adoption revert therefore costs a **token-orphaning**, not a behavior regression — the adopted call sites keep working and emit an unfrozen token. Named residual, accepted at this tier. Before downstream adoption the tier is CHEAP: revert the release merge, five files, no moves, renames or deletes.

## Related ADRs

- [ADR-120](ADR-120-g1-enforcement-authority-is-class-scoped-and-release-scoped.md) — shipped the release-resolution state enum that separates *no release in flight* from *in flight but unidentified* from *identified but wrong*. One of the three instances fixed independently before this convention existed; retained here as a regression arm and as evidence that the convention is emergent.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — the extend-before-create determination this record's D4 discharges: the emitter family is extended with a sixth class member rather than paralleled by a second mechanism.
- [ADR-092](ADR-092-plan-file-claim-time-stamping.md) — the slug-primary release-identity decision this release's plan file and branch are keyed on; cited for the authoring context, not for the emit contract.
