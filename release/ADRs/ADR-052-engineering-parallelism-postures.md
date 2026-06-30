<!-- reference-durability: allow-link -->
---
title: "ADR-052 — Stage-6 Engineering parallelism posture taxonomy (names existing D-C SINGLE / OPTION-A topology behavior as postures + adds dispatch)"
status: Accepted
date: 2026-06-30
release: 73-concurrent-execution-safety
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Collective Review scope-lock"
tags: [release-ops, hub-spoke, stage-6, engineering, concurrency, parallelism-posture, multi-chip-safety, force-push-safety, d-concurrency-posture]
source_observations:
  - "Originating gap: Stage-6 concurrency reads as an unconditional 'NO — write-serialized' line, but the hub-spoke bridge File-contention boundary already branches on D-C topology (SINGLE serial / OPTION-A per-branch). What is missing is the vocabulary (named postures), the per-posture safety contract (multi-chip-safety-class), the Stage-4 selection (D-Concurrency Posture), and a force-push prohibition. A survey confirmed no parallelism-posture taxonomy file shipped and no posture identifier appeared in the bridge's Stage-6 region."
  - "Phase A0 framing correction: the bridge is ALREADY topology-conditional, so this work NAMES existing behavior (SINGLE = P0, OPTION-A = P2) and adds dispatch — it does NOT introduce conditionality from a frozen unconditional baseline. Mis-framing it as 'flip the NO to conditional' would duplicate existing behavior and lose the safety contract."
  - "Source incident: a prior release's Engineering spoke force-pushed with a stale lease (the lease validated against the spoke's outdated local ref, not the current remote tip), momentarily rewinding sibling commits that had landed on the shared release branch during the spoke's compute window. The convergent safe path was a stacked side-branch alongside the release branch. This is direct evidence that --force-with-lease is insufficient under multi-chip activity and that the per-sub-task-branch merge-queue is the validated safe path."
---

# ADR-052 — Stage-6 Engineering parallelism posture taxonomy (names existing topology behavior as postures + adds dispatch)

## Status

Accepted — operator-ratified at this release's Collective Review scope-lock (the same Status-enum gate the release-ADR README names: "Operator-ratified at Collective Review or equivalent gate"). This release is a single-card release, so scope-lock is the per-spoke Procedure 4 acceptance event rather than a multi-issue Collective Review; the operator's scope-lock approval IS the acceptance.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/`, resolved at the authoring commit with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. The ADR is referenced downstream **by slug**, never by its number — the number is an authoring-time assignment, not a stable cross-reference handle.

This decision is extended or reversed only by a **successor / superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the successor) — never by an in-place edit of this record.

## Context

Stage-6 Engineering concurrency is governed by an unconditional-looking "NO — write-serialized" line in the hub-spoke bridge Parallelism Rules. But the bridge's File-contention boundary rules **already** branch on the D-C topology selected at Stage 4: under D-C SINGLE topology, every Engineering commit serializes at commit/push on the shared release branch; under D-C OPTION-A topology, per-issue branches isolate commit-time writes and contention surfaces at PR-merge order. The conditionality exists; what is missing is four things:

1. **Vocabulary** — there is no named posture identifying each concurrency contract, so the choice cannot be stated, selected, or reasoned about as a first-class decision.
2. **A safety contract** — no per-posture attribute declares which push modes are safe under N concurrent writers.
3. **A Stage-4 selection** — there is no `D-Concurrency Posture` decision at the planning D-Gate where the contention map, the topology, and the wave count are already in hand.
4. **A force-push prohibition** — a prior multi-chip near-miss proved that `--force-with-lease` is not sufficient to make a history-rewriting push safe when concurrent writers race (the lease validates against the operator's last fetch, not the true remote tip), so the rewinding-push class must be contractually excluded.

## Decision

Adopt a named parallelism posture taxonomy (P0–P4) that **names the existing topology behavior** (SINGLE = P0 fully-serial; OPTION-A = P2 per-sub-task-branch merge-queue) and adds **posture dispatch** at Stage-6 routing — **without re-typing the routing primitive**. The hub's Procedure 2 routing logic, the File-contention boundary's operand types, and the topology-branch verdicts are unchanged; only the *naming* and a thin dispatch read of the release plan's `D-Concurrency Posture` decision are added on top.

1. **Ship P0 / P1 / P2 / P3; P4 is a stub.** P0 fully-serial (the default), P1 serialized-commit-lane, P2 per-sub-task-branch merge-queue (**ships first**, empirically validated), and P3 parallel-push rebase-retry (constrained) ship as selectable postures. P4 commit-broker is a named taxonomy-extension stub, `[CALIBRATE-AFTER-N]`-gated, not built.
2. **Default-serial floor.** When `D-Concurrency Posture` is undeclared, the posture is P0 fully-serial — today's exact safe-by-construction behavior. Posture parallelism is opt-IN.
3. **Per-posture `multi-chip-safety-class`.** Every posture declares one class from a fixed 3-value enum (`single-writer-only` / `multi-writer-safe-fast-forward-only` / `multi-writer-safe-rebase-retry`). The force-push / history-rewriting class is **named-and-excluded**: no posture may declare a class permitting `--force`, `--force-with-lease`, or `--force-if-includes` to the shared release branch under multi-chip activity.
4. **Ship-vs-stub rule.** A posture ships only when validated — either **validated-by-composition** (its mechanism is a strict composition of already-safe primitives; P1 and P3-under-its-no-force-constraint) or by **its own evidence** (empirical; P2). A posture introducing a novel mechanism with no validating evidence (P4) is a stub until evidence exists.

The executable mechanics — the per-posture mechanics, the safety-class attribute table, the force-push prohibition, the selection inputs — live in the new standard `release/references/standards/parallelism-posture-taxonomy.md`, which this ADR records the *decision* for. The Stage-4 `D-Concurrency Posture` decision rides the existing release-plan D-Gate block (no new schema); the Stage-6 dispatch rides the existing hub Procedure 2 routing (no new routing primitive).

## Alternatives Considered

- **(A) Flip the unconditional "NO" to a from-scratch conditional — REJECTED.** This mis-frames the work: the bridge is already topology-conditional, so a from-scratch conditional duplicates existing behavior and obscures that the postures are a *naming* of it. It also fails to deliver the safety-class attribute and the force-push contract, which are the load-bearing additions.

- **(B) Generic OS-level file-locking — REJECTED.** Already rejected at the platform layer (the hub-session-continuity reference states there is no file-locking mechanism); a lock does not address the lease-race or commit-ordering and is not platform-native. The posture taxonomy is the platform-native answer to the same write-contention class.

- **(C) Build all five postures including the commit-broker now — REJECTED.** The broker introduces a novel integration authority with no validating evidence; shipping it first violates the ship-the-validated-answer discipline. The merge-queue posture (P2) has direct empirical validation and ships first; the broker is a `[CALIBRATE-AFTER-N]` stub.

- **The selected approach** — name-existing-behavior + dispatch + four-postures-and-a-stub — is the **minimal-blast-radius** way to make the concurrency choice explicit and plug-and-play: it augments behavior and naming on top of the already-conditional bridge, leaves the routing primitive untyped and unchanged, and is `git revert`-able with no data migration. This is the same minimal-blast-radius reuse pattern by which an immutable ADR augments behavior rather than re-typing a shared primitive (the precedent recorded in ADR-037, which extends ADR-024 by a new record + a virtual-path token rather than re-typing the shared `serialize()` operands).

## Consequences

**Positive:**
- The concurrency choice becomes **explicit and plug-and-play** — selectable at the Stage-4 D-Gate from inputs already in hand (contention map, overlap_class distribution, topology, wave count).
- The **force-push / history-rewriting class is contractually excluded** — the near-miss is incident-proofed by construction across every non-serial posture.
- The **default-serial floor bounds the blast radius** — undeclared = P0 = today's exact behavior, so a release that ignores the decision is unaffected, and a revert of posture dispatch leaves serial behavior intact.

**Negative / costs:**
- A new D-decision (`D-Concurrency Posture`) now rides Stage-4 and Stage-6 routing for all future releases — bounded by the default-serial floor (opt-IN).
- P4 (commit-broker) is a named-but-unbuilt extension point — intentional deferred scope, not silent debt.

## Reversibility

**CHEAP / Confidence HIGH** — the change is additive prose plus one new standards doc plus this ADR; the predicate / routing primitive is untouched. A `git revert` of the single release PR restores the prior state with no data migration. Partial-ship is safe: the default-serial floor means undeclared = serial = today's behavior even if posture dispatch is reverted.

## Related ADRs

- **ADR-005** (append-pattern-aware cross-PR contention scoring) — the `overlap_class` distribution is one of the four posture-selection inputs, consumed as an advisory signal, not as a rule.
- **ADR-037** (version slot as a cross-release contended axis) — pattern precedent for minimal-blast-radius reuse: augment behavior on the existing machinery rather than re-typing a shared primitive; extend by a new record rather than an in-place edit.
- Topology context is the hub-spoke bridge File-contention boundary rules (D-C SINGLE / D-C OPTION-A).
