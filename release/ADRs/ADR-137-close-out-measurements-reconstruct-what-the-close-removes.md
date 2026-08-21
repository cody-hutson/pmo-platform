<!-- reference-durability: allow-link -->
---
title: ADR-137 — A chore-PR-borne close-out measurement reconstructs what the close removes; it does not assume its evidence is invariant
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-21
release: closeout-reports-what-shipped
deciders: "Workspace owner. Judged warranted by the Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) against the ADR authoring guide's when-to-write rubric; its drafted decision statement was falsified by the Phase A6.5 Independent Adversarial Design Review and restated at the Collective Review scope-lock gate. Authored at Stage 13 Close of the same release, after the version tag was claimed."
supersedes: none
tags: [architecture, release-pipeline, close-out, measurement, evidence-reconstruction, velocity, telemetry, reversibility-moderate]
source_observations:
  - "Three sibling instruments write measurement fields into one Stage-13 chore PR — **Cycle-Time:**, **Velocity:**, and **Close-Class-Telemetry:** — and all three are computed at a point where the close has not finished. The constraint is therefore shared, and before this record it was written down for none of them."
  - "The sequencing invariant that creates the constraint is normative and lives in the stage spec: `release/references/pipeline/stage-13-close.md` § Phase B — 'Stage 13 chore PR MUST land on main BEFORE Phase C C1 Milestone close.' Paired with the chore-PR convention in `release/references/standards/release-velocity-tracking.md` (the field lands on main via the Stage 13 chore PR, never direct-to-main), post-close computation is unavailable to any of the three."
  - "Close-time variance one — the Stage-12 auto-close outcome. A predicate reading issue state is bimodal on whether the release PR's close keywords resolved: when they did, members are already CLOSED at the measurement and the number is right; when they did not, the remedy runs twenty dispatch positions downstream and the field books delivered 0 on a release that shipped everything. Seven rows in the hot ledger recorded exactly that."
  - "Close-time variance two — the Phase A2 disposition, which the Stage 5 design did not name. `stage-13-close.md` Phase A2 disposes a bundled-but-not-closed member by 'apply `status: deferred` label … → remove milestone'. Membership is read via `gh issue list --milestone`, so a dispositioned member is in neither the delivered set nor the planned set."
  - "The drafted principle would have rejected the predicate this release shipped. Stage 5 drafted 'computed from evidence that is invariant across the close'; the A6.5 review falsified it against the design's own cited clause, which the design had quoted with an ellipsis that elided the '→ remove milestone' step. The label is invariant; the population is not."
  - "The design's sole counter-example for non-tautology did not survive measurement. Both cited issues read milestone=NONE, and the timeline shows the demilestone preceding the `status: deferred` label by one second — the co-occurrence the claim rested on has never existed at any instant. Measured across all seven under-delivered ledger rows plus this release's own slice, the drafted predicate resolves the ratio to exactly 1.00 everywhere: a loud defect converted into a silent one."
  - "The shipped implementation reconstructs rather than assumes. `release/tools/compute-release-velocity.sh` derives `delivered` from the current milestone membership — which IS the shipped set, by Phase A2 construction — and recovers `planned` by reading `demilestoned` events over the bounded terminal-status population and returning any that names this milestone. Timeline events are immutable, which is what makes the recovery order-independent across a dry run, a `--no-merge` run, and an `--apply` run."
  - "The known bound is recorded in the shipped tool's own header rather than discovered later: the recovery join is keyed on the milestone TITLE (the `demilestoned` event payload carries no stable milestone id) and is temporally unbounded, so it under-reports a re-bundled member and over-reports one demilestoned long after the release closed."
---

# ADR-137 — A chore-PR-borne close-out measurement reconstructs what the close removes; it does not assume its evidence is invariant

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering.** `137` is the mainline anchor plus one, derived at Stage 13 across **both** record directories (`core/ADRs/` and `release/ADRs/`) via the `--next-free` oracle rather than reserved at design time. Stage 5 deliberately declined to reserve a number, because a number claimed at design and merged later is a reservation hazard against a sibling's unmerged claim.

**Authored after the tag claim, deliberately.** This record and the sibling skill-version bump in the same chore PR both depend on the release identity existing. Stage 13 is the first point at which it does.

## Context

Three instruments write a measurement field into the Stage-13 chore PR: `**Cycle-Time:**`, `**Velocity:**`, and `**Close-Class-Telemetry:**`. Two normative constraints fix when they may run. The field lands on main through the Stage 13 chore PR and never direct-to-main; and the chore PR must land on main *before* the Phase C milestone close. A chore-PR-borne measurement is therefore computed while the close is still in progress — and the close is not a passive backdrop to that measurement. It is an active mutator of the very population the measurement reads.

Two distinct close-time variances hit these instruments, and they are independent:

1. **The Stage-12 auto-close outcome.** Whether the release PR's close keywords resolved determines whether members read CLOSED at measurement time. A predicate gated on issue state inherits that bimodality directly. This is the variance the release's originating defect reported, and it is real: seven rows in the hot ledger recorded a zero delivered figure on releases that shipped their whole slice.

2. **The Phase A2 disposition.** The stage spec disposes a bundled-but-not-closed member by applying a terminal `status:` label **and then removing the milestone**. Because membership is read by milestone, a dispositioned member leaves the readable population entirely — it is in neither the delivered set nor the planned set.

The Stage 5 design named the first variance and drafted the governing principle as *"computed from evidence that is invariant across the close."* The Phase A6.5 adversarial review falsified that framing, and did so against the design's own cited evidence: the design had quoted the Phase A2 clause with an ellipsis that elided the `→ remove milestone` step, so the refutation sat inside the citation. Its sole counter-example for non-tautology did not survive measurement either — both issues read `milestone=NONE`, and the timeline shows the demilestone preceding the terminal label by one second, so the state the claim described never obtained at any instant.

The consequence is the reason this record exists rather than a field-schema note. **As drafted, the principle rejects the predicate the release shipped.** Milestone membership is not invariant across the close; the *label* is invariant, the *population* is not. A principle that forbids the only workable design is not a principle, and one left in a field-schema section is where no sibling instrument's author would look for it.

## Decision

A close-out measurement borne by the Stage-13 chore PR is governed by two clauses.

**1 — It must not derive from a value the close itself sets.** Issue state is the disqualified case: it is bimodal on the Stage-12 auto-close outcome, which nothing in the measurement controls.

**2 — Where a disposition step inside Stage 13 removes evidence the measurement needs, the measurement must reconstruct the removed part from an immutable record.** It may not assume the evidence is still present, and it may not read the post-disposition population as though it were the pre-disposition one. Silently reading the survivors is the failure this clause names: it does not error, it produces a plausible number that has quietly lost its subtrahend.

**Invariance is explicitly rejected as the test.** It is unachievable for a population the close is chartered to mutate, and demanding it forbids every available design. Reconstructibility is achievable, is testable, and is what the instrument actually owes its reader.

As shipped in `release/tools/compute-release-velocity.sh`, the two clauses resolve to: `delivered` = the current milestone membership, which *is* the shipped set by Phase A2 construction and needs no state predicate at all; `planned` = `delivered` plus the members Phase A2 removed on the way out, recovered by reading `demilestoned` events across the bounded terminal-status population and matching those that name this milestone. Timeline events are immutable, which is precisely what makes the recovery order-independent across a dry run, a `--no-merge` run, and an `--apply` run.

The rule binds all three sibling instruments, not only velocity. The question each instrument's author owes at authoring time is not *"is my evidence stable?"* but *"what does the close remove between my read and the close, and can I reconstruct it?"*

## Alternatives Considered

- **"Evidence invariant across the close" (the Stage 5 draft).** Rejected on falsification. Milestone membership is mutated by Phase A2 inside Stage 13, so the principle rejects the shipped predicate. Adopting it would have left the corpus stating a rule the code it governs cannot satisfy.
- **Narrow the principle to "invariant across the Stage-12 auto-close outcome."** Rejected as too weak. It is true, but it binds only the first variance and would license precisely the label-over-a-mutated-population predicate the review falsified — the ratio pinning to a constant on every governed close, which feeds a capacity-weight recalibration that a constant cannot move.
- **Move the measurement after member closure.** Rejected. The field lands in the chore PR and the chore PR lands before milestone close, so escaping requires a governance change to the sequencing invariant, a prohibited direct-to-main write, or a second chore PR landing the field outside its own normative commit. Recorded here as *expensive and reversibility-regressing* rather than architecturally sealed: the A6.5 review correctly reduced the stronger "architecturally unavailable" claim, and a door closed by cost should be recorded as closeable by choice.
- **A positive delivered marker (`status: done`).** Rejected on measurement, not preference: it is never applied to release members, so the predicate would report zero delivered on every release — strictly worse than the defect.
- **Refuse the ratio entirely via the Explicit-N/A discipline until a Stage-3 membership snapshot exists.** Weighed seriously, and it is the honest posture if reconstruction is unavailable. Rejected for this release because the standard prohibits a partial field, so a points-present/ratio-absent form is not currently expressible without a grammar amendment, and the amendment would discard the allocation repair that reconstruction delivers.

## Consequences

**Positive.** One testable rule now binds all three chore-PR-borne instruments, and it is stated where a sibling author will find it rather than inside one field's schema section. The rule is falsifiable at authoring time by a concrete question about the close's own mutations. Applying it surfaced a standing contradiction that had shipped unnoticed: the standard defines `planned` as membership at the Stage-3 Bundle commit while the implementation read close-time membership.

**Negative, and stated rather than absorbed.** Reconstruction costs strictly more than a plain read — bounded additional event reads over the terminal-status population, on an instrument that previously needed none.

**The reconstruction is best-effort in both directions, and this record does not claim otherwise.** The recovery join is keyed on the milestone **title**, because the `demilestoned` event payload carries no stable milestone id, and it is **temporally unbounded**: any demilestone naming that title counts, whenever it happened. It therefore under-reports when a Phase-A2-demilestoned member is later re-bundled elsewhere, or when the title no longer resolves to a live milestone after a rename — and in that case a zero-recovery outcome is indistinguishable from having nothing to recover. It over-reports when a member was milestoned mid-release for provenance and demilestoned long after the release closed. `planned` is consequently **not a guaranteed bound in either direction**, and this ADR asserts reconstructibility as an obligation, not as a proof of exactness.

**Reachability of that divergence is narrow, and that is why the bound was accepted rather than closed.** Measured at a release's own Stage 13, the demilestone and the close are the same step, so the divergence is not reachable on the live path; it bites on **recomputation of a historical row**, where the elapsed window admits later demilestones.

**One decision is deliberately left open, and the operator holds it.** Closing both gaps requires a durable Stage-3 membership snapshot, which the platform does not take. That work was scoped out of this release rather than absorbed into it, and this record does not pre-decide it: a title-keyed, temporally-unbounded join is the accepted interim, not the endorsed end state.

## Reversibility

**MODERATE.** Confidence **HIGH**.

The record itself is CHEAP to revert — prose in one file with no cascade. The decision it ratifies is MODERATE: reverting it means restoring a state-gated predicate and re-editing the standard sections and the stage-spec clauses that were reconciled to it, plus the historical ledger rows recomputed under the new predicate. Those row corrections are a durable audit-record data edit, so a revert is reconstructable only because the divergence was recorded rather than absorbed.

## Related ADRs

- **ADR-036 — Deterministic version-claiming.** Governs how the release identity this record is dated and homed against is allocated; the same claim is what made the sibling skill-version bump in this chore PR expressible.
- **ADR-133 — The material-edit test names an effect, not a field.** Adjacent within this same chore PR: it supplies the test under which the sibling skill edits counted as material, and shares this record's posture that a governing rule should name the effect it cares about rather than the surface it happens to land on.
- **ADR-129 — Close-class is a declared deliverable value conditioning one gate spec.** Governs the close-class telemetry instrument, one of the three sibling instruments this record binds.

**No supersession.** This record amends no prior ADR. No existing ADR or standard governed the evidence-selection constraint on chore-PR-borne close-out measurements, which is why the record was warranted rather than an amendment to the velocity standard's field schema.
