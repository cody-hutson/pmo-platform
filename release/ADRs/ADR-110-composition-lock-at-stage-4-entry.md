<!-- reference-durability: allow-link -->
---
title: ADR-110 — A Milestone's composition is locked to additions at Stage-4 Planning entry; the lock binds the act, not the disposition, and its unmarked state is not eligibility
status: Proposed
date: 2026-08-03
release: release-bundle-and-sequence-gates
deciders: "Workspace owner — the add-only-vs-bidirectional direction was an open [ASSUMPTION – CONFIRM] on the originating ticket and was resolved at Stage 5 Solutioning; the act-typed framing and the three-valued boundary state were forced by a Stage-5 Phase-A6.5 adversarial review that returned two blockers, and were adopted in a targeted revision. The +1-file emission point was accepted by the operator at the revision's decision gate."
tags: [release-pipeline, bundle-mutability, composition-lock, gate-criteria, fail-closed, monotonicity]
source_observations:
  - "The A7 Bundle Mutability Protocol described mid-flight scope-add as a permitted, ceremonied path: sub-windows B and C were declared mutable, and only Collective Review approval was a hard lock. The operating intent was the opposite."
  - "The churn formula's `issues_added` term only has meaning if adding issues to a running bundle is expected; the protocol budgeted for the act rather than forbidding it."
  - "The T1 Approved-queue-depth trigger is explicitly a prompt to consider folding newly-approved theme-matching work into an existing bundle, and its detector routes the operator to the amend disposition."
  - "A first design gated the composition lock on the `amend` outcome path itself. Because `amend` is a many-to-one bucket carrying removals and zero-delta re-sequences as well as additions, that guard would have made three shipped consumers unreachable in sub-windows B and C — the protocol would have stranded the removals its own triggers T3 and T6 generate."
  - "A first boundary probe inferred eligibility from a zero result on a single milestone-scoped query. Measured against the live population, that probe returned a determinate, clean zero for milestones whose planning sub-task had detached or whose title had drifted — reading a closed, fully-executed release as a legal amend target."
  - "Coverage is not soundness: widening the probe to a union of two limbs lowered the error rate without changing its direction, because both limbs still derive an affirmative eligibility from an absence."
---

# ADR-110 — A Milestone's composition is locked to additions at Stage-4 Planning entry; the lock binds the act, not the disposition, and its unmarked state is not eligibility

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from Milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes **in-flight branch and pull-request claims**, not only what is on `origin/main`. This record's number was re-derived at Engineering Commit 0 by enumerating both ADR directories across `origin/main` and every unmerged remote branch — a working-tree glob is not the authority, because it cannot see a sibling release's in-flight allocation. The design-time allocation was invalidated exactly that way when a sibling release merged four ADRs between Stage-5 exit and Engineering start.

## Context

The A7 Bundle Mutability Protocol governs how a bundle may change between Milestone creation and Collective Review approval. It divides that window into three sub-windows — A (creation → Stage-4 Planning entry), B (Stage-4 entry → Stage-5 Solutioning), C (Stage-5 → Collective Review approval) — and made all three mutable, reserving immutability for the post-Collective-Review hard lock.

That is the inverse of the operating intent. **Once a Milestone enters Stage 4, its composition is closed**: Stage 4 computes a File Change Matrix, a Contention Map, a dependency graph, a Parallelization Map, a quota budget and a Release Class *over the composition*. Adding an issue after that invalidates all six artifacts, silently, while spokes are already executing against them.

The gap was not a defect in any one release. It was that the codified protocol actively described the permitted path for the behaviour the operator wanted forbidden — and budgeted for it: the churn formula carries an `issues_added` term, and the T1 Approved-queue-depth trigger exists precisely to prompt folding newly-approved theme-matching work into an existing bundle. The absent artifact was a composition-lock boundary at Stage-4 entry.

Two questions were left open on the originating ticket and had to be resolved rather than assumed: whether the lock is add-only or bidirectional, and whether it admits a hotfix/P1 exception.

## Decision

**A Milestone's composition is locked to additions at Stage-4 Planning entry.** Three properties make the lock hold, and each was chosen against a specific failure the design process surfaced.

### 1. The lock is add-only, not a symmetric freeze

Sub-windows B and C become **add-immutable**. Removals and deferrals remain legal at their existing ceremony — amend-log in B, Tier 2 `[SCOPE CHANGE]` in C. Newly-Approved theme-matching work routes to a **next** bundle.

### 2. The rule is act-typed and stated once

The rule is stated at the definition surface as a property of the **act**:

> For a Milestone at or past Stage-4 Planning entry, `issues_added` MUST be 0 for every refresh disposition.

It is **not** a condition on the `amend` outcome path. This distinction is load-bearing. `amend` is a many-to-one bucket: three shipped consumers route non-addition changes through it — the Major-scope-change classification for a removal, the re-sequence disambiguation rule for a zero-delta reorder, and the cascading-rebundle response for a namesake removal. A guard written as *"`amend` requires a pre-Stage-4 target"* would make all three unreachable in sub-windows B and C, because every Milestone in B/C is at-or-past the boundary by the definition of the boundary. The protocol would then forbid the removals its own triggers T3 and T6 generate.

Stating the rule on the act also closes it permanently: a future fifth outcome path inherits the guard without an edit, where a per-cell condition would reopen the hole. Enumerating the current paths against the act shows one guard suffices — `no-op` changes nothing, `defer` removes, `re-bundle` lifts the lock by construction, and `amend` is the only path that can carry an addition into a locked bundle.

Consequently the three enforcement surfaces — the outcome-path table, the Stage-3 A9.8 amend-target exclusion, and gate criterion `G-BR5` — **cite** the rule; exactly one surface states it. `G-BR5` fires on `path == amend AND issues_added > 0`.

### 3. Boundary state is three-valued, and the unmarked state is not eligibility

`lock_state(M)` resolves in order: an emitted `### Composition Lock` H3 in the Milestone description ⇒ **LOCKED**; otherwise an attachment-limb ∨ exact-title-limb hit ⇒ **LOCKED `[LEGACY-TITLE-INFERRED]`**; otherwise **UNMARKED**.

`UNMARKED` is *"eligibility not established"* — not *"pre-Stage-4"*. An addition-carrying `amend` against an `UNMARKED` target is permitted only with an explicit eligibility basis recorded in the `[BUNDLE AMENDMENT]` comment the outcome path already mandates. The order-2 union is used **monotonically**: it may only ever *establish* a lock, never certify openness.

This is the property that makes the lock sound rather than merely well-covered. A two-valued probe derives an affirmative permission from an absence, so its false negatives fail **open** — and a determinate, clean zero from a renamed or detached Milestone is indistinguishable from a genuine one. Under a three-valued resolution the same failure falls through to `UNMARKED`, which forces an attestation. **Soundness comes from the state machine's default, not from probe coverage** — so widening the probe is an improvement, never the safety property.

The marker is emitted at the boundary-crossing act (the hub's Stage-4 planning sub-task creation), which makes the boundary *observable* rather than only inferred, and retires the heuristic going forward without a backfill. Its form is the verbatim H3 block, matching the marker convention already gate-enforced on that same surface.

### 4. No exception path, and three lift conditions

There is **no** hotfix or P1 carve-out. The `hotfix` Release Class is already the emergency route: a corrective P1/P2 forms its own small bundle, which reaches Stage 12 *faster* than a host bundle it would also contaminate — injecting corrective work into a `cross-cutting` bundle inherits that bundle's deep review posture and its ship date.

The lock lifts on Stage 13 Close; on refresh outcome path (3) `re-bundle`, whose description rewrite clears the marker and returns the bundle to sub-window A; or on run abandonment, recorded as one of those two. No fifth outcome path is created. `re-bundle` is not an exception to the rule — it is the lift condition, and its price (re-running Stage 4) is what stops it becoming a rubber-stamp bypass.

## Consequences

**The churn term becomes a violation detector.** `issues_added` is retained rather than deleted — four surfaces consume `composition_delta_pct`. Under the lock it is identically zero in sub-windows B and C *by construction*, so a non-zero value computed there is not a churn measurement at all: it is evidence the lock was breached. The same term is `G-BR5`'s conditional, which makes the detector and the gate one mechanism instead of two.

**`amend` loses a target class, not a change class.** Removals, deferrals and zero-delta re-sequences are unaffected in every sub-window. Only the addition is excluded, and only at or past the boundary.

**The failure direction is toward refusing a legal amend.** Fail-closed is deliberate: an indeterminate read, a query error or absent tooling all resolve to non-eligibility. The operator clears a false refusal with one recorded line; a false permission silently invalidates six Stage-4 artifacts.

**Every addition-amend becomes auditable.** The recorded eligibility basis means a reviewer can distinguish *"the probe correctly reported no lock"* from *"the probe reported nothing because the Milestone was renamed."* Without it, a violation leaves no trace separating the two.

**Legacy Milestones are attributed, never laundered.** Order-2 results carry the `[LEGACY-TITLE-INFERRED]` tag and are never reported as an affirmative pass; `UNMARKED` is reported as `UNMARKED`. An inert marker that reads green is worse than one that says it did nothing.

**Cost:** one criterion and one self-repair row on an existing gate (a non-breaking minor schema bump), one description PATCH inside a step that already performs one, and a coupling to the scaffolded planning sub-task's title — mitigated by stating the boundary definitionally first and isolating the marker to a single resolution table, so a scaffold-convention change touches one place.

## Alternatives considered and rejected

### Candidate B — bidirectional lock (symmetric freeze in B/C)

Forbid additions **and** removals from Stage-4 entry; any composition change re-enters Stage 3. Rejected on four grounds, in order of weight:

1. **Monotonicity inversion (decisive on its own).** It makes sub-windows B/C *stricter than the hard lock*. Gate criterion `G6-02`'s self-repair sanctions recording a documented deviation *if the issue was descoped* at Stage 6 — past Collective Review — and the Collective Review **Adjust** arm names *"defer issue"* explicitly. Forbidding in B/C what the protocol permits later is incoherent.
2. **Asymmetric invalidation.** Additions invalidate every artifact Stage 4 computed over the composition. Removals shrink that surface and cannot invalidate a completed design. The lock's direction follows the invalidation's direction.
3. **Removals get mis-routed off their correct classification.** Under a bidirectional lock, a sub-30% theme-preserved T3 or T6 removal has `amend` forbidden by the lock, `re-bundle` gated behind *"> 30% OR theme broken"*, and `defer` gated behind *"release no longer viable"* — so it is forced onto a disposition whose own trigger predicate it does not satisfy. *(This leg is deliberately narrow. A stronger form — that T3/T6 would have **no legal disposition** — was drafted and **withdrawn as overstated**: the cascading-rebundle response enumerates three T6 dispositions, and `re-bundle` and `defer` both survive a bidirectional lock. The defect is mis-routing, not deadlock.)*
4. **Corroborating:** refresh outcome path (4) `defer` already records removal with a sub-window B/C deviation-log entry, so removal in B/C is a named, ceremonied path in the shipped protocol.

### Candidate D — confidence-gated soft lock

Permit additions in B/C but price them with a mandatory full re-derivation of the Stage-4 artifact set. Rejected: it permits the exact act the constraint forbids, and it is the status quo with more ceremony — sub-window C *already* required a Tier 2 `[SCOPE CHANGE]` for an addition, and that ceremonied path **is** the defect. Ceremony is not control.

### Candidate E — status quo (lock only at Collective Review)

Rejected: it leaves the operating constraint uncodified and the protocol describing the forbidden behaviour as supported.

### Mechanism alternatives

A **new continuous `deploy.sh` check** asserting no in-flight Milestone gained an issue was rejected on temporal shape as much as cost: the lock is an *event-time* rule that fires when a disposition is rendered, not a continuous-state invariant, so a per-deploy monitor would poll for a condition that only exists at a decision moment. **Protocol prose alone** was rejected because it leaves the boundary ungraded at the gate that already evaluates outcome-path selection. **Filtering the existing T1 detector** was rejected as a no-op — that detector emits counts and themes and names no target Milestone, so there is nothing for an eligibility filter to filter; the exclusion belongs on the operator's disposition, not the monitor's output.

A **generic operator-override escape clause** inside A7 was rejected as a duplicate source: the operator can already override any gate with documented rationale platform-wide, so a bespoke escape adds no capability, only a legitimizing surface.

## Opposing view

**Candidate C — add-only plus a removal-reconciliation rider.** As decided, but a removal in sub-window C that severs a cross-issue dependency edge would additionally oblige re-running the affected sibling's integration criteria before Collective Review.

The hazard C names is real: removal is not free once sibling designs cite the removed issue. It was not adopted because the hazard is **already owned** — the Collective Review protocol's cross-issue dependency-satisfaction check and its scope-confirmation check fire at exactly the moment C's rider would, and a Tier 2 `[SCOPE CHANGE]` already routes the removal to the operator with an impact assessment. Adding a parallel obligation would duplicate a live gate and land new machinery on the integration-criteria surface, which is a wider blast radius than the decision needs.

The decision therefore carries C's *concern* as a pointer to the existing check rather than as a new obligation. If practice shows the Collective Review check missing severed edges, C is the recorded upgrade path.
