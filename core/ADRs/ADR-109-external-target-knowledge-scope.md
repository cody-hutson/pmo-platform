<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
---
title: ADR-109 — External-target knowledge scope — the target is SSOT for its own facts
status: Accepted
date: 2026-08-03
release: governance-hardening
deciders: "Workspace owner (ratified at the Stage 9 review); design authored at Stage 5 Solutioning and corrected at Stage 6 against the live adapter interface"
tags: [architecture, knowledge-management, memory, ssot, external-target, adapters, no-shadow-ssot, reversibility-cheap]
source_observations:
  - "A convention about an external target repository was held in the operator auto-memory store as prose, cached from a prior session rather than read from the target, and had drifted: the memory named a ratification label the target no longer used, and the named label was dead in the target. The drift was caught only by an unrelated live re-read; nothing structural forced that read before the cached value was acted upon."
  - "The target repository self-describes its product but not its release or backlog conventions, so those conventions had no repo-local home. The platform corpus is correctly instance-agnostic and carries zero references to that target, so they had no corpus home either."
  - "The tier classifier's Q2 contextual-scope enumeration is closed over this install's own contexts — org-wide practice, org-wide facts, one project's state, emergent — and carries no scope value for a repository the toolkit operates upon. A target fact therefore routes by nearest fit rather than by a rule."
  - "The no-shadow-SSOT invariant prohibits a second copy of a fact whose SSOT is another surface. For an external-target referent the owning surface is not in the contract table at all, so there is no owner to shadow: the invariant is structurally silent rather than violated."
  - "The one adapter interface the corpus specifies is scoped entirely to version-claiming. Its operation set returns versions and claim outcomes; none of its operations resolves a referent. A design that delegates a referent read to it would cite an operation that does not exist."
---

# ADR-109 — External-target knowledge scope — the target is SSOT for its own facts

## Status

**Proposed.** **Extends** — does **not** supersede — [ADR-045](ADR-045-cross-surface-memory-contract.md), which generalized [ADR-029](ADR-029-memory-corpus-ssot-boundary.md)'s Knowledge cut into the cross-surface contract. Both prior records are left byte-unchanged; this scope reaches them by reference, the same posture ADR-045 adopted toward ADR-029. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes in-flight pull-request claims. Allocated at commit time: the union of both directories reported a contiguous `001..108` with no gaps and no duplicates, and the only open pull request is this release's own, so this ADR takes **109**.

## Context

[ADR-045](ADR-045-cross-surface-memory-contract.md) settled which of **this install's** surfaces owns a fact. Every surface it enumerates belongs to the install: the codified corpus, the auto-memory store, the governance context files, the operational state tree, the operator-local roster, `operator.toml`. A third case is absent from that table and from the classifier that feeds it — a fact about an **external target**: a repository or system the toolkit *operates upon* rather than *is*.

**The observed failure was not a mis-homing. It was a fused fact.** The memory entry that drifted did not hold one fact; it held two welded together — an **operator-side practice** (*"I ratify a work item with a status label"*, a decision about how the operator works, legitimately holdable) and a **target-side referent** (*"…and the label is named X"*, an observable property of another repository that must never be held). The classifier inspected the half it could see, routed the entry by that half, and the referent rode along as an unowned payload that nothing ever reconciled against its source. There was no step that *decomposed* a fact before homing it.

**Why the existing machinery could not catch it.** The classifier's Q2 contextual-scope enumeration is closed over this install's own contexts and offers no scope value for a target, so a target fact routes by nearest fit. The no-shadow-SSOT invariant prohibits a second copy of a fact *whose SSOT is another surface* — but for a target referent the owning surface is not in the contract table at all, so there is no owner to shadow and the invariant is structurally silent rather than breached. The standing drift detector's classes all key on an issue tie or a wikilink; a target referent has neither. The gap was unreachable from the existing machinery, which is why the report was correctly typed as a defect rather than an enhancement.

**The decomposition test, run against the reported cases.** Each convention the report treated as an irreducible "target convention" splits with no residue: *ratify via a status label* is practice, the label's **name** is a referent; *one pull request per milestone* is pure practice; a *close-out definition of done* is practice, and where the target documents it, a live file read; and the *milestone-filter method* was never a target fact at all — it is host mechanics, encodeable into **this** corpus. Four of four decompose. That a single memory note held all four classes side by side is the clearest evidence that no decomposition step existed.

## Decision

1. **The classifier gains a pre-step, Q0.** Before homing any fact, ask whether it asserts something about a repository or system other than this install's own platform. If yes, **decompose** it: the target-side referent goes to the read-live rule below; the operator-side practice continues to Q1 with the referent removed. A fact that cannot be cleanly split is treated as target-side.

2. **The target is the sole source of truth for its own facts.** No surface of this install may hold a resolved target-side referent — not the corpus, not the auto-memory store, not operator config. **The fix is the removal of a storable value, not a new storage home.**

3. **The only stored item is the target's address** — the `identifier` field of an `operator.toml [trackers.<id>]` destination, which already exists. No new configuration surface is created. The address is retained because it is irreducible (no read is possible without it), because it is operator-declared rather than agent-inferred, and because a stale address fails hard on the next call rather than returning a plausible wrong answer.

4. **The read is governed by three requirements, stated host-agnostically.** It is **fresh at every use** (resolved against authoritative target state at the moment of use, never from a snapshot or a remembered answer); it goes **through the selected host surface**, which is operator configuration resolved from the `operator.toml [adapters]` selector table, with capability text naming the *operation* and never the host tool that satisfies it; and **nothing is retained** — the resolved value is used and discarded.

5. **No adapter interface specifies a referent-read operation today, and this ADR says so rather than pretending otherwise.** The one adapter interface the corpus specifies is scoped entirely to version-claiming; its operations return versions and claim outcomes, never a referent. Requirement 4 is therefore a **requirement on the read**, not a delegation to an existing operation. An adapter operation that resolves a target-side referent is a **named gap** owned by the adapter-interface work, and requirement 4 is the contract it must satisfy when it ships. Until then the read is performed directly against the target under the same three requirements.

6. **Divergence surfaces as a halting resolution failure, never a stale value.** Because nothing is stored, a changed target cannot produce a stale answer; it produces a read that returns zero matches, or more than one, where the practice expects exactly one. The agent surfaces that and asks the operator to restate the practice. **There is no offline fallback, by design** — a fallback cache would reintroduce the defect as a feature.

7. **Where a target self-describes, that is the preferred source.** Reading the target's own in-repo convention file *is* a target-side derivation, and is preferred over any operator-side restatement, because the convention and its subject then version together. This creates no obligation on a repository the operator may not control.

8. **A drift class is named and its detector is deferred.** `external-target-referent-stored` — any surface of this install holding a resolved target-side referent as a value rather than reading it live. It ships **doc-only**, matching the deferred-enforcement posture already recorded in the cross-surface contract's composition boundaries. It is deliberately **not** added to the standing detector's five classes, and that count is unchanged; when a detector ships, the class joins that table and the count moves five → six.

### Scope

**The bound is structural, not a promise, and it is stated in three clauses because a reader who finds only the first could misread this scope as a general licence.**

- **This scope grants no write permission.** It adds a classifier step and an SSOT assignment. It contains no clause permitting any surface to hold anything. Its net effect on memory-write authority is **strictly negative**: it names a newly prohibited pattern — a stored target-side referent — where none was previously named.
- **The scope predicate is negative and exact.** It applies **only** to a fact whose source of truth is a repository other than this install's platform. Content whose SSOT is this corpus (`core/`, `release/`) is **definitionally outside** it and remains governed by the two-tier assignment and the no-shadow-SSOT invariant, unchanged. There is no reading under which corpus-SSOT content qualifies.
- **Encode-then-evict is untouched and untouchable by this scope.** That lifecycle graduates tacit knowledge *into this corpus*. External-target facts are never universal-for-this-platform, so they never become K1 and are never eligible to graduate. The lifecycle, its VERIFY-CORPUS gate, its ARCHIVE-first step, and its ordering guarantee are left byte-unchanged.

## Alternatives Considered

| # | Alternative | Kill-reason |
|---|---|---|
| **A** | **Prohibition only** — add "do not cache external-target facts" to the memory contract and name no home. | A prohibition with no home leaves the fact homeless. The agent still needs the value, so it re-caches. It also fails the reported defect's central question outright, which asks **where** the knowledge should authoritatively live. |
| **B** | **A new per-target registry** in operator config holding each target's conventions as declared values. | A second registry keyed on the same address as the existing per-destination subtable is itself a shadow SSOT, at the configuration layer. It is net-new where a covering surface exists, and it carries a wider blast radius: setup round-trip preservation, update migration, and depersonalization-token review. |
| **C** | **Conventions as a sub-key on the existing per-destination subtable.** | **Does not solve the defect.** Storing conventions is storing a cache; the drift class survives intact, merely relocated from a memory file to a configuration file. This is the answer most readers reach for, and it dies on the defect it fails to fix rather than on a close score. |
| **D** | **The target self-describes** — the target authors its own conventions file and the toolkit reads it. | Unenforceable as the primary: it requires write access to a repository the operator may not control, and creates a cross-repo dependency this repository can neither enforce nor verify. **Folded into the decision** as the *preferred source when a target does self-describe*, since a live file read is already a target-side derivation. |

**On the one real cost, stated rather than minimised.** With nothing cached there is no offline fallback: a session that cannot reach the target cannot resolve a target-side referent and must halt. That is a deliberate trade and the correct one here, because the defect under repair is precisely *"served a stale value silently."* A fallback cache would reintroduce it as a feature. The workload makes the cost negligible — a handful of target reads per release, where latency is irrelevant.

## Consequences

- **Drift is eliminated by construction, not by detection.** There is no stored value to go stale, so compliant behaviour cannot drift. A detector would only catch non-compliance; the teeth here are structural.
- **The failure mode inverts from silent to loud.** A divergence that previously produced a confident wrong answer now produces a halting resolution failure at the point of use.
- **No offline resolution.** Named above as an accepted cost, not a defect.
- **Zero new configuration surfaces and zero new anchors a consumer must learn.** The scope lands as a subsection of the section that already owns *which surface is authoritative when a fact could live in two*, so every existing pointer into that section reaches it with no consumer edit.
- **An honest gap is left visible.** No adapter operation resolves a referent today. Recording that is preferable to citing an interface that would not satisfy the read — the failure this ADR exists to remove is precisely the one where a plausible-looking reference is trusted instead of checked.
- **Verification of the concrete instance is operator-side.** The originating case is closed by an operator-local memory edit that an engineering pull request structurally cannot make. Acceptance grades it on operator-side evidence, not on an in-repository search.
- **ADR-029 and ADR-045 are left byte-unchanged.** This record extends the cut; it does not rewrite either predecessor.

## Reversibility

**CHEAP / Confidence HIGH.** Three files: two additive documentation edits and this record. `git revert -m 1` of the release pull request restores the prior state. No configuration migration, no runtime surface, no compiled package, no data migration, and no consumer state to unwind.

## Related ADRs

- [ADR-029](ADR-029-memory-corpus-ssot-boundary.md) — the original Knowledge cut (superseded by ADR-045; left byte-unchanged).
- [ADR-045](ADR-045-cross-surface-memory-contract.md) — the cross-surface memory contract across all four memory types. **This ADR extends it with a third scope and supersedes nothing.**
- [ADR-017](ADR-017-distribution-architecture.md) and [ADR-022](ADR-022-platform-config-vs-operator-toml-split.md) — name `operator.toml` as the home for adapters and consolidate the host-adapter selector table this scope's read requirement resolves through.
