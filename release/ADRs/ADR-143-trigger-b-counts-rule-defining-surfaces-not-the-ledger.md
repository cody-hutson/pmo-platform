<!-- reference-durability: allow-link -->
---
title: ADR-143 — A release-class predicate counts rule-defining surfaces, not the ledger the release is mandated to write
status: Accepted — ratified by the operator at the v4.40 release close gate (2026-08-28). The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-24
release: pipeline-spec-self-consistency
deciders: "Workspace owner. Design decision rendered at Stage 5 Solutioning for the release-class trigger-(b) card and accepted by the hub at Procedure 4; the card itself argued both framings and resolved neither, which is why this record exists."
supersedes: none
tags: [governance, release-pipeline, classification, release-class, taxonomy, predicate-design, measurement-led, reversibility-cheap]
source_observations:
  - "The threshold read one lower than it was written. Every *deployable*-class release writes a mandatory `RELEASE_LOG` row at Stage 12 and transitions it at Stage 13, so for any plan that **declares the ledger as a File Change Matrix row** membership handed the count one free touch and the `≥3` threshold behaved as `≥2`. The free touch is a property of the matrix **declaration**, not of the Stage-12 **write**: a release that performs the mandated write without naming `RELEASE_LOG.md` in its matrix never gained the touch at all, which is why § Consequences measures the effect at 24 of 178 plans rather than universally."
  - "Measured, not argued. Re-counting the 20 pinned shipped releases `v4.19`–`v4.38` under three readings, divergence against the operator's declared class was: literal **2**, named-exclusion **1**, remove-from-set **0**."
  - "One case decides the fork. `v4.32`'s ledger row is an *inbound-reference repair* — substantive in diff, mechanical in meaning, and outside any mandatory-write exclusion — so a named exclusion misses it and re-renders the release `cross-cutting` against an operator-declared `novel`."
  - "The exclusion list does not close. Repairing `v4.32` needs a second qualifier for mechanical cascades; `v4.34`'s historical Deployment-Log correction needs a third. Each addition re-opens the interpretive gap the change exists to shut."
  - "The stated cost does not survive measurement. Across 178 tracked release plans, 24 name `RELEASE_LOG.md` in their File Change Matrix and only 2 carry a genuine format/convention change; neither produced a `cross-cutting` classification via trigger (b). Ten plans flip the trigger's verdict under the new reading and **zero** declared classes change."
  - "The signal was never in the ledger. `RELEASE_LOG.md` carries no rules about itself: its row lifecycle and emit format are specified in the Stage-12 and Stage-13 stage specs (counted by trigger (a)), its Deployment-Log field anatomy in `release-process.md`, and its gate assertions at `G-EX4` / `G-EX5` / `G-CL3` in `gate-criteria-spec.md` (both counted by trigger (b))."
  - "The mandatory-row premise is no longer universal by specification. Close-class conditioning means a `task-artifact`-class release writes no release row at all — so a Stage-3 classification predicate built on the row's presence has arithmetic that depends on a Stage-13 branch."
  - "Practice had already diverged from the text twice, on two different rationales: an operator adjudication against a strict-letter fire on *shallow single-line registrations*, and a second against the *mandatory mechanical row*. N=2 for divergence, N=1 for the rationale this record fixes."
  - "Blast radius is one line. Across 1768 tracked files the seven-member set is restated on 11 lines, of which exactly **1** is live corpus — the taxonomy row itself; the other 10 are frozen per-release audit records. No `deploy.sh` check and no gate reads the trigger arithmetic."
---

# ADR-143 — A release-class predicate counts rule-defining surfaces, not the ledger the release is mandated to write

## Status

**Accepted** — ratified by the operator at the v4.40 release close gate (2026-08-28). The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `143` was derived at Engineering time, immediately before this file was authored, via `release/tools/renumber-adr.py`. The oracle's `--next-free` reads the mainline anchor and returned `142`; that number is already bound on this same release branch by the record authored one build earlier, and `--detect` confirms it `BINDS`. `143` is therefore this branch's contiguous next, with the mainline reaching `ADR-141` and no hole beneath either claim. The number was deliberately **not** reserved at design time: the oracle is a *read*, not a reservation. A sibling unmerged release branch also claims `143`; that claim is **detection-only and does not bind**, and stepping past it to `144` would land a gap at `143` if that branch never merges. The asymmetry is the whole rule — a duplicate is mechanically renumberable by this same tool at merge time, whereas a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole. That is why allocation happens here, takes the contiguous next, and never reserves high.

## Context

The `cross-cutting` release class fires on any of three triggers. Trigger (b) read:

> File Change Matrix touches ≥3 of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md}

Six of those seven documents define how the platform behaves. The seventh, `RELEASE_LOG.md`, is a per-release **ledger**: it records what happened. And every *deployable*-class release is **mandated** to write to it — a `DEPLOYED` row at Stage 12, a transition to `VERIFIED` at Stage 13, both asserted by structural auto-gates.

So the set contained one member whose presence in any honest File Change Matrix was guaranteed by the pipeline itself. A release that touched two genuine governance surfaces counted three. **A `≥3` threshold written into the spec behaved as `≥2` in practice**, and it did so invisibly, because the free touch looked exactly like a real one.

This was not a theoretical reading. It surfaced when a release declared `novel` at Stage 3 on a count of 2, and a Stage-5 spoke re-counting the seven-member set literally read 3 and disagreed with the classification the release was already executing under. The operator ruled the row non-counting at the Collective Review gate — a ruling recorded in one milestone's amendment log, binding nothing. Measurably binding nothing: another release plan counts the ledger toward the threshold explicitly, and a third release hit the same wall independently three months earlier on a different rationale.

The card that produced this record named two candidate framings, argued for one, and stated what it would lose — but did not resolve. That is what makes this a decision rather than an edit, and it is why the rejected alternative is recorded here rather than left to be re-litigated.

## Decision

**`RELEASE_LOG.md` is removed from the trigger-(b) named set.** The set is six rule-defining governance surfaces. A referenced block sited beside the class table states the exclusion, names where the ledger's own rules actually live, and carries a worked example with its arithmetic shown.

The change is **not** an exclusion clause scoped to mandatory writes. That distinction is the decision.

### The principle

**A classification predicate must not count an artifact the classified process is itself mandated to produce.**

A predicate exists to discriminate. An input the process guarantees carries no information about the case being classified — it shifts every count by a constant, which is indistinguishable from lowering the threshold, except that lowering the threshold would have been a visible decision and this was not.

### Why membership was the wrong shape rather than a missing clause

The competing framing kept the member and excluded the mandatory writes. It fixes the case that surfaced the defect. It does not fix the next one.

The measurement is the argument. Across the 20 pinned shipped releases `v4.19`–`v4.38`, divergence against the operator's declared class was **2** under the literal reading, **1** under the named exclusion, and **0** under removal. The single case separating the two candidates is `v4.32`, whose ledger row is an **inbound-reference repair** — a substantive diff that is mechanically meaningless about release shape, and squarely outside a mandatory-write exclusion. The named exclusion does not reach it and re-renders that release `cross-cutting` against an operator-declared `novel`.

Repairing that requires a second qualifier for mechanical cascades. `v4.34`'s historical Deployment-Log correction then requires a third. Archive relocations would require a fourth. **The exclusion list is open-ended; the removal is closed.** Each carve-out re-opens precisely the interpretive gap — *is this touch the counting kind?* — that the change exists to shut, and re-opens it at Stage 3, where the operator has the least context and the least appetite for adjudication.

Removal also keeps the arithmetic independent of the **close class**. Close-class conditioning means a `task-artifact`-class release writes no release row at all. An exclusion clause presumes the row exists in order to exclude it; a Stage-3 predicate whose count depends on a Stage-13 branch is a coupling that should not exist in either direction.

### What the change does not lose

`RELEASE_LOG.md` carries no rules about itself. Its own header names its specification elsewhere, and a change to the ledger's format or convention therefore lands, by construction, on a surface the predicate still counts: the row lifecycle and emit format in the Stage-12 and Stage-13 stage specs (**trigger (a)**), the Deployment-Log field anatomy in `release-process.md`, and the gate assertions at `G-EX4` / `G-EX5` / `G-CL3` in `gate-criteria-spec.md` (**trigger (b)**, both retained members).

Empirically the loss is nil. Two genuine convention changes exist across the 178 tracked plans present at **2026-08-24**. One added a `## Velocity` section and also edited two retained members — it counts 2 under the new reading and was declared `novel`, so the strict-letter fire would have been the *wrong* answer even with a real format change on the table. The other added a schema field and fires on four other named surfaces regardless.

## Alternatives Considered

Five candidates were generated; the originating card named two of them. The rejections are the load-bearing content of this record.

| # | Candidate | Why rejected |
|---|---|---|
| **A** | **Named exclusion** — count a named-surface touch only when *substantive*, explicitly excluding the mandatory Stage-12 row and Stage-13 transition | **The runner-up, and the framing the card leaned toward.** 1 divergence per 20 against removal's 0. It mis-renders the inbound-reference-repair case, which no mandatory-write exclusion reaches, and repairing that needs a second qualifier and then a third. It also presumes the row exists, so it breaks on a close class that writes none. **An exclusion list that grows by one carve-out per newly-observed edit shape is not a closed rule.** |
| **B** | **Remove the member** — six rule-defining surfaces | **SELECTED.** 0 divergences per 20; 0 declared-class changes across all 24 corpus plans naming the ledger. |
| **C** | **Change nothing in the spec; record the prior ruling as precedent elsewhere** | The status quo the work was filed against, and it is *measured* to have already failed: the ruling existed in one milestone's amendment log while another plan counted the ledger toward the threshold explicitly, and a third release hit the same ambiguity independently. Precedent that does not bind is not a remedy. |
| **D** | **Generalize a "substantive change" qualifier across all seven members** | Reaches strictly more cases — including the shallow-touch ambiguity neither A nor B fixes. Rejected as disproportionate: it converts a mechanically countable predicate into a judgment call at every member, at the stage with the least context, and re-introduces "both readings are defensible" as a *feature*. The underlying shallow-touch gap is real, unowned, and routed out as its own work rather than absorbed here. |
| **E** | **Two-tier set** — rule-defining members count 1, ledger members count ½ | Preserves a weak ledger signal at the cost of fractional arithmetic in a predicate a human evaluates at a gate, for a signal measured at 2 occurrences in 178 plans, neither of which changed a classification. Ceremony with no measured payoff. |

## Consequences

**What this buys.** The predicate means what it says. `≥3` requires three rule-defining surfaces, and the count no longer moves with a write the pipeline itself mandates. There is one reading of trigger (b) rather than two defensible ones, which removes the adjudication that had already been performed twice at gates and recorded in places that bound nothing.

**Measured effect on classification.** Across all 178 tracked plans present at **2026-08-24**, 24 name the ledger in their File Change Matrix and 10 flip the trigger's verdict — in every case from FIRE to no-fire. **Zero declared classes change.** Seven of the ten were declared non-`cross-cutting`, meaning the strict-letter fire was spurious in every one; the three declared `cross-cutting` all survive on another trigger. Trigger (b) is an OR-limb into a highest-ceremony-wins reduction, so removing a member can only make the class **cheaper**, never stricter, and only for releases that fired on (b) alone.

**No gate re-arms, no check re-runs.** Trigger (b) is evaluated by a human at Stage 3. The gate criterion that reads the class asserts enum-membership of the declared value and non-emptiness of its rationale — never the arithmetic that produced it. No `deploy.sh` check reads the set. No skill package rebuilds.

**A residual, stated rather than hidden.** A convention change confined to the emission-time date-anchor taxonomy that `RELEASE_LOG.md` cites is counted by **neither** the old reading nor the new one. This change does not create that gap and does not close it — the convention never lived in the ledger.

**A second ambiguity is left open, deliberately.** Whether a *shallow* touch — a single-line registration on a named surface — should count toward the threshold is a distinct question, with its own prior operator adjudication against the strict letter. Candidate D would have reached it. It is routed as separate work rather than folded in, because the right remedy is genuinely open and bundling it here would have traded a closed decision for an open one.

**Cutover, and the reflexive loop.** The new reading applies to releases classified at Stage 3 strictly after this note's introducing-release merge SHA recorded in the release log; pre-cutover classifications are grandfathered, and **the introducing release itself is exempt**. A release cannot fire its own new classification rules on its own planning, and the exemption clause is what makes that explicit rather than accidental.

**The worked illustration this record first carried does not survive re-derivation, and the correction is the more useful lesson.** It read: the introducing release's rationale records 2 rule-defining surfaces; a literal post-close re-count under the old seven-member set reads 3 once the mandatory Stage-12 ledger row lands; the new reading returns it to 2 and the rationale stays true. Re-derived by parsing that release's own File Change Matrix at Commit 0 (`b2baa7bb`), at its Stage-7 head and after its Stage-8 amendment, the matrix names **three** rule-defining surfaces at every one of those points — `gate-criteria-spec.md`, `hub-spoke-bridge.md` and `release-process.md`. So the count is **3 under both readings**, trigger (b) **fires** under both, and `RELEASE_LOG.md` never enters the arithmetic at all, because that release performs its Stage-12 write without ever declaring the ledger as a matrix row.

Two things follow, and only one is about this decision. The recorded rationale's **2 is wrong about its own matrix**, and was wrong at Stage 4 — before the ledger question arose. That is a rationale-integrity defect this decision neither caused nor cures; it is corrected in the milestone's own `## Release Class` block. And this decision's effect on the introducing release is **nil rather than restorative**: removal moves no count here. That is not an embarrassment to the rule — it is precisely the pattern § Consequences measures across the corpus, where 10 plans flip the trigger's verdict and **zero** declared classes change. The class was never in question either way, because trigger (a) fires independently on the stage specs.

**Frozen release plans are not corrected.** Ten per-release plans restate the seven-member set, measured at **2026-08-24**. They are immutable audit records of what rule each release was classified under; retroactively editing them would falsify exactly the history the cutover clause exists to preserve.

## Reversibility

**CHEAP · confidence HIGH.** One table cell, one referenced block, and one appended anti-pattern sentence in a single tracked file, plus this record. No schema migration, no data movement, no path move. Full rollback is a single-file revert.

## Related ADRs

| ADR | Relationship |
|---|---|
| [ADR-027](../../core/ADRs/ADR-027-release-bundle-risk-weight-keys-on-release-class.md) | **Composes.** Release Class is the key that bundle risk-weighting multiplies against, so a trigger that fires spuriously propagates into the point band. This decision narrows trigger (b)'s member set; it changes no class value and therefore moves no weight — the measured effect is zero declared classes changed. |
| [ADR-115](ADR-115-adr-number-claim-binds-at-merge.md) | **Composes.** The numbering rule this record's `## Status` block applies — allocate at authorship, bind at merge, take the contiguous next, never reserve past an unmerged sibling claim. |
| [ADR-117](ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) | **Composes.** The derived-surface contract under which this record's index row is projected rather than hand-written. |
