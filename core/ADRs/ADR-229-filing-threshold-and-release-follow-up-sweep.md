---
title: ADR-229 — A work item passes a filing threshold; a release files its follow-ups in one sweep per repository
status: Accepted — operator-ratified at the releases-file-only-the-follow-ups-that-matter Stage 13 Close ratification beat (Phase A13), 2026-11-04
date: 2026-11-03
release: releases-file-only-the-follow-ups-that-matter
deciders: "Workspace owner (ratified at the Stage 13 Close ratification beat); design authored at Stage 5 Solutioning and revised after the adversarial design review"
tags: [governance, intake, release-pipeline, filing-threshold, shared-kernel, reversibility-moderate]
source_observations:
  - "A target release delivered three cards and filed eighteen follow-up issues; a post-release review kept about three and closed fifteen. Three mechanisms produced them: every review finding routed to an issue, an issue opened per deferral at the GO/NO-GO only to hold it, and residuals an ADR already declared filed again."
  - "A backlog triage measured 320 issues opened in four weeks against 102 closed, most filed by release runs about themselves, and counted 21 related observations into 2 stories and 4 rewrites."
  - "An adversarial design review found that nothing guarded how an item leaves the ledger, that two criterion limbs had no text to read, and that filing paths after Stage 9 bypassed the ledger."
supersedes: none
---

# ADR-229 — A work item passes a filing threshold; a release files its follow-ups in one sweep per repository

## Status

**Accepted** — operator-ratified at the `releases-file-only-the-follow-ups-that-matter` Stage 13 Close ratification beat (Phase A13), 2026-11-04, as one record of a decision rendered per record, under Gate 13 criterion G-CL9's authored-by-this-release limb. Authored at Stage 6 Engineering of that release as `Proposed`, after the operator's Stage 5 decision record rendered the scope this record documents. The ratification is recorded in this file's frontmatter `status:` field and is never inferred from a review comment or from milestone closure. The decision this record documents shipped in **v5.00**.

**Numbering provenance.** Claimed as **229** against an anchor of **228** on `origin/main`, read from `release/tools/renumber-adr.py --next-free` at Engineering Commit 0. A branch claim is detection-only and never binds; should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Citations from other branch-authored artifacts use the slug token `{{ADR:<slug>}}`, which carries no number shape and resolves at the claim.

## Context

A release could create more work than it resolved, and the few follow-ups that mattered were buried among many that did not. Three mechanisms produced the volume. Every review finding was routed to its own issue, with no test of whether it was worth one. Each deferral at the GO/NO-GO needed an issue of its own, opened only to hold the deferral. And residuals an ADR already declared were filed again as issues. Automatic intake logging filed at its highest dial with no value test either.

The same shape showed at Stage 2 Triage, where the observation path converted each observation into its own card, one to one, when related observations were counters for one piece of work.

The operator stated the principle once: **a release that creates more work than it resolves is, in most cases, not acceptable.**

Two forces bound the answer. The rule is consumed by two modules — the release pipeline, which routes a release's follow-ups, and automatic intake logging, which runs with or without a release — so it is shared-kernel content. And an adversarial review of the first design showed that the rule needs a guard on how an item *leaves* the count as well as how it enters, and that filing paths after the Stage 9 gate bypassed any count taken there.

## Decision

1. **One filing threshold, two limbs, its home in `core/`.** An item becomes a work item only when it is user-visible, security-relevant or privacy-relevant, **and** reads at least Minor. The rule's single home is `core/standards/work-item-filing-threshold.md`, because both modules consume it (ADR-007's shared-kernel placement). Every other surface cites it and restates none of it.
2. **Every follow-up a release would file waits in the record where it surfaced, tagged there with its class.** No routing point before the filing step files one. The release-side routing — the tag, the records, what a cut may do — lives once, in `release/references/standards/finding-disposition-framework.md` § 8.
3. **Stage 9 Phase A7.6 assembles, reads and counts them** — `resolved` against `proposed`, with each source's count reconciling to the ledger — and the operator accepts or cuts an excess before anything is filed.
4. **Stage 13 Phase A10.5 files one sweep per repository**, plus separate issues only for genuine bugs and features, with what surfaced after Stage 9 confirmed by the operator first. Filed follow-ups carry no milestone and enter Stage 2 Triage like any intake.
5. **`intake-desk` Mode C applies the threshold before its clamp, at every dial, in or out of a run**, and holds a passing signal for the sweep when the hub names the run.
6. **Stage 2 counts related observations into the work they point to** — an owner first, otherwise one story per group — and closes each counted observation as completed with a pointer.

## Alternatives Considered

- **The threshold's home.** Housing it in the review discipline's residual-risk section was rejected: that file carries its own severity scale and binds review-class work only, and intake is not review-class. The work-item authoring standard was rejected: it reads existing declarations and introduces no new rule. The decision discipline's pattern cache was rejected: it is a different sense of "observation" and scoped to decision-class work. The Tier-0-floored operations file was rejected: every future change to the rule would be operator-executed. A hub-action-tracking section was rejected: Mode C outside a run has no hub. An operations-module home was rejected by ADR-007's shared-kernel placement. The minimal-addition discipline was the strongest opposing view and was rejected because its test is a text test while the threshold is a value test, so two tests would share one name.
- **The gate binding.** A new Stage 9 gate criterion was weighed against a Phase A7.6 line with a required Phase C disposition graded under the existing G-PR6. Neither is graded by an executable today; the line was chosen on reversibility and blast radius. A machine-readable disposition segment on the Stage 9 pipeline event was recorded as the seam a future runner can read, and not shipped, because no reader exists.
- **Mode C placement.** A create-path-only threshold and a configuration knob were rejected in favour of a step before the clamp that runs at every dial.
- **The grouping key at Stage 2.** Grouping by a shared file alone was rejected; observations group by the surface each names and the outcome it asks for.
- **The filing actor.** Filing from intake-desk's interactive mode, from Mode C, or at Stage 9 was rejected; Stage 13 files, after the last producer.
- **A single sweep across repositories.** Rejected: one sweep cannot span two trackers, so a release files one per repository holding an item.
- **The Stage 13 slot before its producers.** Rejected: the post-deploy checks that surface late follow-ups run later in Phase A, so the filing step runs after them.

## Consequences

- **The net work line is a disposition prompt, not a bound.** It counts what the release's own records hold, with each source's count reconciling to the ledger; an item no record holds is outside it. Filing behaviour can move it, so it is not a measurement of escaped work, and it must not be read as one until the parent epic's independent escaped-defect signal exists.
- **The GO on an EXCESS is held by conduct.** No executable grades a GO recorded on an EXCESS without a disposition line; the only script that names G-PR6 checks that the gate-outcome row is present. The operator's reading at Phase C is the check.
- **The charter residual is wider than at Stage 4.** `core/CLAUDE.md.template` describes Mode C's `bounded_auto` path as "authors → validates → creates"; with the threshold applying at every dial, in or out of a run, that clause overstates Mode C always, not only during a run. Accepted for the next charter revision; owner: the operator.
- **A hold outside a run lives in the caller's output.** A below-threshold signal Mode C holds outside a release run is recorded only where the calling skill's output lives; a caller with no persisted output leaves it in the session transcript. *Monitoring criteria:* a signal raised again within 30 days of being held, or a Stage 2 triage that finds an item filed after an earlier hold of the same signal, re-opens this residual.
- **A sibling release may become bound mid-run.** The family anchor is the start of Stage 9 Phase A, so a release already past Stage 4 when this merges is bound if its Stage 9 has not started; anything it filed earlier enters its ledger as `pre-filed`.
- **Counted observations close `completed`.** An epic whose child observation is counted reads it as done; the story takes the members' common parent epic so the epic's open work stays visible.

## Reversibility

**MODERATE.** Revert the merge, rebuild the six packages, redeploy. Issues filed and observations counted under the rule stay valid records and reopen individually.

## Related ADRs

- ADR-007 — the core module boundary: content both modules consume is shared kernel and lives in `core/`, which places the threshold's home.
- ADR-019 — Specialists compose and do not absorb: `pmo-release-manager` points at the Stage 9 and Stage 13 steps and owns no mechanics of its own.
- ADR-109 — external-target knowledge scope: a target repository's sweep renders against the target's own work-item form, read live at filing, and the platform stores nothing about the target but its tracker address.
- ADR-115 and ADR-181 — the number binds at merge, and in-release prose cites this record by its slug token.

## References

- #8146 — the story: a release files only the follow-ups that matter, in one sweep per repository.
- #7537 — the parent epic, owner of the independent escaped-defect signal the net work line is not.
- #8606 — the Stage 5 sub-task: the first design, the adversarial review, the operator's decision record and the revised design.
- #8603 — the Stage 4 sub-task: the plan and its decision record.
