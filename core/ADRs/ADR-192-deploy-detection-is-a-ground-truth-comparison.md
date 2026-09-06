---
title: "ADR-192 — Deploy selection asks the installed corpus, not the repository history"
status: Accepted (operator-ratified at the deploy-checks-hardening-batch Stage 5 Collective Review scope-lock, 2026-09-05, which re-shaped the card's acceptance criterion from report-the-undetectable-case to resolve-it-then-assert)
date: 2026-09-05
release: deploy-checks-hardening-batch
deciders: Stage 5 Solutioning spoke (five-candidate design exploration, three eliminated on in-corpus evidence) + operator at the Collective Review scope-lock + Stage 6 Engineering on the log-literal cascade
tags: [deploy, change-detection, ground-truth, proxy-failure, stale-baseline, EX_NOCHANGE, template-sync-exclusion, ADR-165, ADR-013, ADR-006, ADR-008]
source_observations:
  - "The primary propagation command reported deploying zero skills and exited 0 while the installed corpus sat six days behind source, immediately after a release that edited fifteen skill sources. The remedy that worked on the same working tree seconds later was the explicit redeploy-everything mode, which bypasses change detection entirely and deployed forty-one skills. The roster was identical across both runs; only the detection differed."
  - "The window's left edge is a tag, not a deployment record. The detector resolves its diff base by describing the nearest tag, falling back to the previous tag only when HEAD is exactly a tagged commit. At the authorship baseline HEAD stood nine commits past the most recent tag, so the exact-match branch did not fire and every skill edit at or before that tag was outside the window permanently."
  - "The error is one-directional and therefore silent. The window can only ever under-report: a skill outside it is never deployed, and a skill inside it that is already current re-copies harmlessly and counts zero. The failure mode is always 'too few', and the zero it prints is byte-identical to the zero a correct run prints."
  - "The honest predicate already existed in the same file twice — in the skill-sync check and in the user-local-mirror-sync check — and the partial-deployment recovery standard already used exactly that comparison to define its full-success state. The deploy path never asked it. The same file already carried the precedent for the placement, having hoisted the rules-mirror carrier above the same early exit for the same reason."
  - "Measured at authorship against the live user-local mirror: a bare recursive references/ diff without the injected-basename exclusion flagged eleven of the fifty-five roster skills on a fully current instance, every one an injected-template artifact and zero of them a real difference; the same comparison carrying the exclusion flagged none. The Stage 5 measurement of the same property against the Cowork session target returned twelve and zero. The two populations differ; the property does not."
  - "The reported count is footprint-derived. The deploy increments its skills-changed counter only when a skill's deployed content manifest differs before and after, so the count is defined over what was written rather than over what was selected, and the earlier idempotency fix is what decoupled the two."
  - "A pre-existing regression harness matched the no-changes log line with a fixed-string comparison on its exact literal and skipped its assertions when the match failed. Rewording the head of that line converted two passing assertions into a silent skip. The same harness seeded its mirror fixture with empty directories, which sufficed while selection tested only directory presence and reads as a wholly stale instance once selection asks the content question."
supersedes: none
---

# ADR-192 — Deploy selection asks the installed corpus, not the repository history

## Status

**Accepted** — operator-ratified at the `deploy-checks-hardening-batch` Stage 5 Collective Review scope-lock on 2026-09-05 (Saturday). The ratification carried a re-shaping of the originating acceptance criterion: the card as written asked that the undetectable case *report* as a failure, and the operator adopted *resolve it, then assert on what survives*.

**Numbering provenance.** This record was authored at the next free number computed from the mainline anchor plus one, advanced past one slot already occupied by a sibling record on this same release branch. A branch claim is detection-only and never binds for mainline purposes, but a same-branch claim is a file that already exists, and taking its number would be a duplicate rather than a claim. Citations use the slug token `{{ADR:deploy-detection-is-a-ground-truth-comparison}}`, which carries no number shape and resolves at the claim.

## Context

The deploy path selected what to deploy by asking the repository what had changed since the last tag, and used that answer as a proxy for what was missing from the installed corpus.

**The proxy is valid only under a precondition that is unstated, unenforced, and structurally unrepresentable: that the instance was last deployed at exactly the diff base.** Nothing records where the instance stands. The deployed corpus carries no provenance marker of any kind, so the precondition is not merely unverified — there is no artifact in which it could be written down. One commit past the tag the window stops covering the release's own skill edits, and it never covers them again.

**The resulting failure is silent by construction, and that is what makes it worth a record.** The window can only under-report, so the observable is always a zero — and a zero from a genuinely current instance and a zero from a comparison that could not see the work are the same characters and the same exit status. Every downstream consumer that reads the summary or the exit status reads them identically. A release could therefore close green, with every gate passing, over an instance running stale skills, and no artifact anywhere would record that the propagation did not happen.

**Four governed claims in the corpus were conditionally false while this stood.** The solutioning stage's forecast discipline classifies the skill-sync and mirror-sync checks as effects that a deploy resolves; those two checks print remediation strings pointing at the deploy; an architecture record instructs re-running the deploy to restore; and the skill-deployment rule states that edits require an explicit deploy to refresh. Each was true only when the tag window happened to still contain the change. This is the strongest argument for resolving rather than reporting: reporting leaves all four conditionally untrue.

**The honest predicate was already in the file, twice, and the deploy path never asked it.** So the defect is a *wiring* problem, not a missing detector — the question had two implementations and one governed definition, and the one caller that most needed it was the one caller that did not call it.

## Decision

**Deploy selection asks the installed corpus what it has, not the repository what changed. The tag diff is retained and unioned with that answer; residual drift surviving the deploy fails the run through the failure channel that already exists.**

Five sub-decisions follow.

**D1 — Resolve, then assert; do not merely report.** The drifted set is unioned into the candidate set *before* the no-changes early exit, so the deploy repairs what is measurably stale. The non-zero exit is reserved for residual drift that survives the repair. Reporting alone would have satisfied the criterion's letter while leaving the four governed claims above conditionally false; resolving makes them unconditional for the first time.

**D2 — The provenance-marker shape is rejected, and the ground is the sharpest available.** Recording a deployed-from commit at deploy time and diffing from it introduces a second baseline that can go stale — which is precisely the sibling defect, still open, in which a checksum baseline going stale causes a refresh command to silently deploy nothing. Answering a stale-baseline failure with a second baseline is the one move the pair of defects jointly forbids. A content comparison has no baseline to go stale: it compares the two artifacts whose relationship is the actual subject. It also catches a class no commit marker can see at all — an installed copy edited by hand.

**D3 — Union with the tag diff; never replace it.** The tag diff remains the sole source of the deleted-skill set, because a deletion is a repository fact with no on-disk counterpart to compare against, and it likewise remains the source of the changed-package and changed-harness sets. The two answer different questions — what changed in the repository, and what is stale on disk — so a union strictly adds and no skill that deploys today stops deploying.

**D4 — The residual assertion is scoped to what the invocation claimed, and this is a hard constraint rather than a preference.** Auto-detect and the full-roster mode claim the roster; a named deploy claims only those names. The post-merge deploy hook computes its own list and calls the named form, so a full-roster assertion there would fail every hook run on unrelated pre-existing drift. Narrowing manual mode is what keeps that hook working.

**D5 — The fix is skills-only, and the boundary is required rather than convenient.** Packages are deliberately excluded from the no-change signal upstream *because* they re-copy every run; widening the reported signal to packages would make that signal unreachable. Packages carry their own content-freshness gate and their own baseline sidecars. Making package selection ground-truth-based would not change the upstream exclusion, so the boundary buys correctness rather than costing it.

**The exit-code contract is preserved, and the reason is structural rather than lucky.** The skills-changed count is incremented only where the deployed content manifest differs before and after a skill's deploy, so it is defined over what was *written*, not over what was *selected*. Widening the candidate set therefore cannot inflate it, and the no-change exit stays reachable by exactly the path it uses today. Honest selection and the no-change contract were never in tension; the earlier idempotency fix is what decoupled them.

**The injected-template exclusion is part of the decision, not an implementation detail.** The predicate compares source against installed content, and a set of runtime-only files is injected into the installed tree by single-source-of-truth design and is absent from source deliberately. Comparing without excluding them reports a large fraction of the roster as drifted on a fully current instance — every finding false. Under this decision's repair semantics that is an unterminating repair loop, and under its assertion semantics a permanently red deploy. The exclusion is therefore load-bearing for correctness, and it is graded by a dedicated regression arm carrying its own sensitivity control rather than trusted to review.

## Alternatives Considered

Five shapes were generated before any was scored; four were rejected, three of them on in-corpus evidence rather than on preference.

**Detect-and-fail — keep the proxy, add a validity predicate, exit non-zero when detection cannot be established. Rejected: it cannot be built without the adopted shape.** To know that detection could not establish what to deploy, you must compare against ground truth — at which point you are holding the repair and declining to apply it. The cheaper heuristics that avoid the comparison (is the diff base an ancestor? did the exact-match branch fire?) do not catch the observed case, in which every repository-side signal is healthy.

**Deploy-provenance marker — record the deployed-from commit at deploy time and diff from it. Rejected: it rebuilds the sibling defect.** The still-open sibling instance *is* the failure of a checksum baseline going stale, and it is named in the originating card's own body. Answering a stale-baseline defect with a second baseline is the one move the pair jointly forbids. A marker also cannot see a hand-edited installed copy, because a commit identifier carries no content.

**Always deploy the full roster — make the incremental mode behave as the explicit redeploy-everything mode. Rejected on signal quality, not on cost.** It is the current workaround and the card's own control arm, so it is known to work; but it makes the summary report the whole roster on every run, destroying both the field the update path parses and the operator's only at-a-glance signal.

**Status quo plus louder documentation — point the operator at the redeploy-everything mode in the summary text. Rejected:** it leaves the defect in place and moves the burden onto a human reading a line that is, by construction, identical to the line a correct run prints.

**Ground-truth selection plus a residual assertion — adopted.** It is the only candidate that closes the observed defect, catches a hand-edited installed copy, introduces no new staleable baseline, makes the four governed claims unconditional, preserves the no-change exit contract, keeps the summary informative, and needs no predicate that does not already exist in the tree.

## Consequences

**The primary propagation command can now exit non-zero on a state it previously reported as success.** That new reachable state propagates: the orchestrator's phase handler treats any non-zero as a phase failure, the update path propagates it without setting its deployed flag, and a fresh install aborts rather than completing over a corpus that did not land. Each is the intended reading — a deploy that could not make the corpus current is not a successful deploy.

**A read-only installed target becomes a deploy failure where it was previously a diagnostic annotation.** This is the named risk. It is reported with its own cause token and carries the remedy string the skill-sync check already prints, promoted from annotation to actionable guidance because this is the run that failed and the operator is reading it now. Measured at authorship, no installed skill directory on the reference instance was read-only.

**The no-changes line now states the denominator it verified.** Previously that sentence was a claim about the tag window and said nothing whatever about the instance. The original sentence is preserved verbatim as the line's prefix rather than reworded, because a regression harness matches it with a fixed-string comparison to decide whether that branch was reached at all — rewording the head would have converted two passing assertions into a silent skip. Extending a line that a consumer matches on is safe; rewording it is a reference cascade.

**A knowingly-accepted duplication is registered rather than left to be discovered.** The drift predicate now exists in three shapes: this emitter, and the inline forms inside the skill-sync and mirror-sync checks. Those two carry per-skill issue accounting, cause annotation and supplementary-content walks that the deploy path does not need, so folding them onto the emitter inside this change would have multiplied its blast radius across the check surface for no defect closure. The emitter is authored to a signature they can migrate onto.

**Relationship to the post-merge-deploy record: complementary, not superseding.** That record fixed the *trigger* — that a deploy runs after a merge — and states explicitly that the deploy script is not modified by it; its own source observations already name this defect's cause. This record fixes the *detection*. Neither subsumes the other, and the named-form constraint that record established is what bounds D4 above.

**What this decision does not assert.** It does not claim the installed corpus is observable from the repository — the opposite is the whole point. It does not extend to packages or harness artifacts (D5). It does not detect an installed skill that no longer belongs to the roster, because the roster arrays are the population; a deleted skill's stale copy remains the deleted-skill warning's business.

## Reversibility

**CHEAP** · Confidence **HIGH**.

The change is one added pure emitter plus one call-site pair inside a single function, with no new file, flag, exit code, emitter class, or failure channel — the residual assertion appends to the failure array that both exit paths already carried. Reverting is the removal of those three regions; nothing downstream acquires a new dependency on them, because the summary field and the exit-code contract are both unchanged in derivation. The one behaviour that cannot be un-observed is a deploy that has already repaired a stale instance, and a repaired instance is the desired end state under either version of the code.

Confidence is HIGH rather than MEDIUM because the adopted predicate is not new: it is the one two existing checks already run and the one the partial-deployment recovery standard already uses to define its success state, so the risk is in the wiring, which is small and covered by a dedicated four-arm regression.

## Related ADRs

- **ADR-165** — post-merge deploy trigger. Complementary, not superseding: it fixed the *trigger* and states explicitly that the deploy script is not modified by it, while this record fixes the *detection*. Its reliance on the named deploy form is the constraint that bounds D4's manual-mode narrowing, and its own source observations already name this defect's cause.
- **ADR-013** — session-less install support. A machine with no resolved session is a supported install shape, so the absence of that target must never read as drift; the predicate scans it only when a session resolved.
- **ADR-006** — canary is source-only. The canary skill is never a deploy target, so it sits outside the scanned roster by construction; including it would yield a finding no deploy could ever clear.
- **ADR-008** — per-module array design. The roster arrays are the single source of truth for the deployable population, and the empty-array guards this record's emitter uses are that record's Rule 2.
- **ADR-117** — derived-surface contract. The core ADR directory carries no projector and no projected region, which is why this record adds no index regeneration step.

## References

- Partial-deployment recovery standard — defines its full-success state as exactly the source-versus-installed comparison this decision adopts, so the predicate is a governed definition rather than an invented one.
- Skill-deployment rule — states that skill edits require an explicit deploy to refresh; one of the four claims this decision makes unconditional.
