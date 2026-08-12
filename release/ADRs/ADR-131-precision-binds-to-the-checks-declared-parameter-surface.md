<!-- reference-durability: allow-link -->
---
title: ADR-131 — A precision obligation binds to the check's declared parameter surface, never to the ACs' self-reported scopes
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-09
release: triage-and-backlog-instrumentation
deciders: "Workspace owner (D-1, D-2, D-3 rendered at the Stage-5 design gate; premise finding D-6 classified C2 and recorded); designed at Stage 5 Solutioning, authored at Stage 6 Engineering"
tags: [architecture, release-pipeline, gates, acceptance-criteria, intake, mechanical-checks, specificity-arm, prose-exemption, reversibility-cheap]
source_observations:
  - "The originating card's stated premise is falsified. It asserts that lint-card AC sets *cannot* express 'and it does not flag correct content'. One of the three cards it cites shipped exactly such a control verbatim — a named near-miss input with an asserted non-flag — and its check is nonetheless the one now reporting up to 73 false stale entries. A precision criterion existed and the over-firing shipped anyway."
  - "The obligation gap, as distinct from the expressibility gap, is real and total. A probe across all four acceptance-criteria-governing surfaces returned zero hits for a precision or near-miss obligation, with a non-zero sensitivity arm on all four and a fabricated-token specificity arm returning zero on all four."
  - "The compliance that failed was genuine, not nominal. Two fixture harnesses shipped inside the same release branch as the checks they cover, both carrying labelled must-flag and must-not-flag arms. The engineers complied with the probe-level obligation that already existed."
  - "The defect is a parameter-combination blind spot, not a missing arm. The stale set is computed against the full baseline while only the scoped subset is scanned, so every baselined entry outside the scope reads stale. The harness does exercise the path-scoping flag — but with the baseline disabled, a mode in which the stale set is structurally always empty. Both parameters were exercised individually; their combination never was."
  - "The card's own proposed binding is vacuous against the card's own motivating defect. It requires the precision arm 'at each scope the ACs themselves reference'; the failing card's ACs referenced no scope at all, so the clause is satisfied by construction on the very card that failed."
  - "The check's parameter surface is enumerable and non-trivial. Its argument parser declares ten parameters, five of which change the examined population or the comparison set. An author asked to enumerate that list cannot leave the failing combination untested by accident."
  - "The target block already owns this population by its own text. Its three-limb capability-class predicate names 'a script / check / hook, a CI job', 'a deploy run, a gate evaluation, a PR event', and 'a verdict, a blocked action' — so a mechanical check satisfies all three limbs verbatim and the scoping is inherited rather than invented."
  - "The conformance-test enumeration is open where the exempt-class list is closed. The block declares its exempt list closed in terms ('extending this list is a governed change, not an authoring choice') and makes no such declaration about the conformance tests, in a file that is meticulous about closure elsewhere. The fifth test identifier was free corpus-wide."
  - "The designated positive control conforms only partially, and for a structural reason. The sibling card chosen to prove the shape is authorable is itself a card that ADDS a check; its acceptance criteria carry a named near-miss but name no parameter surface, because at intake its enforcement surface was still an open design question."
---

# ADR-131 — A precision obligation binds to the check's declared parameter surface, never to the ACs' self-reported scopes

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number is the mainline anchor plus one, re-derived against the mainline at Engineering Commit 0 rather than pre-allocated. The union of both record directories was contiguous through the tail with no gaps and no duplicates up to the anchor, so the claimed slot is the next genuinely free one rather than merely an unused one, and a fabricated control number returned zero. The number-checking tool reads the *worktree* and would pass on a number already taken on the mainline, so it was deliberately not used as the allocator.

**A cross-branch claim on this same number was resolved before authoring.** A sibling card in this release independently recorded this number for a follow-up item that does not author a record in-release. Because this card authors here and that one does not, the number is this record's; the follow-up re-derives at its own authoring time and must not carry a baked number. Per the number-binds-at-merge decision, a branch-local claim is **detection, never binding** — if a sibling release takes this slot before merge, the reconciliation runs through the sanctioned tool rather than by hand, so the provenance note lands with it.

## Context

A capability-only acceptance-criteria set is satisfiable by an over-firing check. A lint that flags *everything* passes "it detects the defect class" perfectly, and no criterion in such a set contradicts it. That is the gap the originating work item exists to close, and the gap is real.

**But the item's stated cause is wrong, and the wrong half is load-bearing.** The item asserts that lint-card AC sets *cannot express* the precision half. They can, and one of the three cards it cites did — it shipped a control naming a concrete near-miss input and asserting the check does not flag it. Two fixture harnesses shipped inside that same release branch, both carrying labelled must-flag and must-not-flag arms. The engineers complied. **And the check that carries all of that is the one now reporting up to 73 false stale entries.**

So the naive remedy — "require a precision criterion" — would not have caught the defect it is built on. That matters, because shipping the naive remedy would have produced a rule that reads like coverage and delivers none, which is the exact failure the originating item itself warns about: *a vacuously-satisfied precision criterion is worse than none, because it looks like coverage.*

**What actually failed is a parameter-combination blind spot.** The stale set is computed against the full baseline while only the scoped subset is scanned, so every baselined entry outside the scope reads stale. The harness *does* exercise the path-scoping flag — but with the baseline disabled, and in that mode the stale set is structurally always empty. Both parameters were exercised individually. Their combination never was. The discrimination arm was real, non-vacuous, and blind: it ran on the *content* axis while the defect lived on the *scope-by-comparison-set* axis.

**Two things follow, and they point in opposite directions from the item's own text.**

First, the missing thing is not expressibility but **obligation**. A probe across all four acceptance-criteria-governing surfaces returned zero hits for any precision or near-miss requirement, with a live sensitivity arm on all four and a clean specificity arm on all four. Nothing obliges an author to write the arm, so writing it is discretionary and its absence is invisible.

Second, the obligation must bind to the right thing. The item proposes binding it *"at each scope the ACs themselves reference."* That formulation is **self-referential and vacuous against the item's own motivating defect** — the failing card's acceptance criteria referenced no scope at all, so the clause is satisfied by construction on precisely the card that failed. A rule that passes the case that motivated it is not a rule.

**A third constraint shaped the answer.** The natural home for this obligation already exists and already owns the population by its own text: the capability-class block's three-limb predicate names *"a script / check / hook, a CI job"*, *"a deploy run, a gate evaluation, a PR event"*, and *"a verdict, a blocked action"*. A mechanical check satisfies all three limbs verbatim. So the scoping the item asks for — apply to check cards, do not become universal boilerplate — is available for free, or it can be re-declared by hand in a parallel block and kept in agreement forever.

## Decision

**(1) The obligation binds to the check's own declared invocation surface — each parameter that narrows the examined population or changes the comparison set.** Not to the scopes the acceptance criteria happen to mention.

This is the whole substance of the decision. A parameter surface is enumerable from the check's own argument parser: the failing check declares ten parameters, five of which change the examined population or the comparison set. An author asked to enumerate *that* list cannot leave the failing combination untested by accident. A self-reported scope list, by contrast, can be satisfied by silence — and was.

**(2) It ships as a conditional fifth conformance test extending the existing capability-class block, not as a parallel block.**

The fire predicate is **inherited, not invented**: a mechanical check already satisfies the block's existing three-limb predicate verbatim, and the block's closed exempt list already excludes reference-content, refactor, bookkeeping and spike work. No fresh fire-predicate and no second exempt list are authored, so nothing can drift out of sync with the predicate that scopes it. The conformance-test enumeration is open where the exempt list is explicitly closed — the block declares the exempt list closed in terms and makes no such declaration about the tests, in a file meticulous about closure elsewhere.

**No criterion identifier is added, renumbered, removed, or re-typed.** The obligation extends a criterion body. This keeps the gate-transition pass-rate denominator, the gate's criterion count, and the evaluated set of the deploy-time proxy check each untouched — the discipline the target file states verbatim about itself: *extend the criterion body, do not add an ID.*

**(3) The base conjunction is left unchanged, and the new test is conditional on it.**

The set-level rejection rule keeps its existing four-way conjunction and gains the fifth only where the capability is a mechanical check. A capability-class item that ships no check is therefore **provably** unaffected — which is the property that answers the originating item's own second acceptance criterion, that the obligation must not become universal boilerplate.

**(4) The obligation is stated with a deferral rider, because one limb is structurally unauthorable at intake for a card that ADDS a check.**

A check that does not yet exist has no declared invocation surface to enumerate, and its enforcement surface is frequently still an open design question at intake. For a card **modifying** an existing check, the parameter limb is graded at intake as written. For a card **adding** one, that limb is satisfied by naming the intended narrowing parameters or marking the enumeration deferred to design exit, where it then binds and is graded. The first two limbs — the named near-miss and its explicitly stated zero — are graded at intake in both cases.

**The rider is stated in the rule itself, not left as reviewer folklore.** This is the decision's least obvious half and the one most likely to be dropped by a later simplification, so it is recorded here: an undischarged deferral marker is an **unsatisfied** obligation, never an exemption. Without that closing clause the rider is an escape hatch; with it, it is a schedule.

The rider was not anticipated at design time. It was found by the sibling card designated as this obligation's own positive control — a card that adds a check, and which therefore conforms only partially for exactly this structural reason. That card discharged the limb at its design exit and re-authored its acceptance criteria to make the zero explicit, so the pattern is proven in-tree before the rule shipped rather than asserted.

**(5) The doctrine lands on both surfaces of the registered prose exemption in one change.**

The rule text is carried, stated rather than cited, by both the enforcement schema and the authoring guide, under a registered per-domain prose exemption. That exemption's stated consideration is that an edit to any doctrine line must land on both surfaces in the same change. **A one-sided edit is silent divergence, and the exemption is what makes it silent** — so the co-edit is compelled, not discretionary, and it is why this change touches a file the originating item's own affected-files list omitted.

**(6) The obligation is prospective, not retroactive.**

It applies from its introducing release forward. Already-closed items are not reopened: their implementations already carry two-armed fixtures, the gap is in acceptance-criteria prose, and editing prose on a closed item changes no behavior. The live test set is the introducing release's own check-shipping items, graded at acceptance against this shape — which is what makes the release its own first test of the rule it ships.

## Alternatives Considered

**A — A new parallel block with its own fire predicate and its own exempt list.** Rejected. It must author a fresh classification for a population the existing predicate already classifies correctly, and then keep the two in agreement by hand forever. It would also register a *second* prose exemption, adding a third and fourth doctrine copy to a surface that already carries two. Worse, a second obligation on the same field invites authors to satisfy whichever is cheaper — which raises the vacuous-satisfaction risk the originating item names as its own principal danger.

**C — Instrument-only: require the check to emit its own arms and leave acceptance-criteria guidance alone.** Rejected as a standalone answer, and **absorbed** as a component. It never fires at intake, which is exactly where the originating item wants the obligation to bite. Its substance survives: the stated observable must include the arm's observed zero, which is the instrument-form obligation surfacing at the acceptance criterion rather than only in the tool.

**D — A mechanical lint over acceptance-criteria prose.** Rejected on three independent grounds, and recorded at length because **it will be re-litigated**. First, it contradicts the originating item's own explicit posture: *keep this as a template/guidance change rather than a new gate unless the recurrence continues.* Second, prose-matching a criterion is precisely the "looks like coverage" failure this decision exists to avoid — a lint that confirms the *words* are present certifies nothing about whether the arm was run. Third, a sibling milestone is concurrently building a check that asserts acceptance-criteria *presence*, so building a second prose-grading check here would collide with it.

**D is the named graduation lever, not a permanent no.** If recurrence continues past this release, the sibling milestone's presence-check is the natural host for a shape-grading upgrade, and this rule is its rule source. What is rejected is building it *now*, ahead of the evidence that guidance alone is insufficient.

**The rejected binding — "at each scope the ACs themselves reference."** Recorded separately because it is the item's own text and will otherwise look like an oversight rather than a decision. It is vacuous against the item's own motivating defect, as set out in Context.

## Consequences

**The co-edit liability grows from four doctrine elements to five.** The registered prose exemption buys standalone readability on both surfaces at the cost of **no mechanical drift detection** — nothing fails when the two copies diverge. This decision adds a fifth element to that hand-synced set. The debt is named rather than hidden, and its retirement lever is named with it: a byte-parity check over the mirrored doctrine region would retire the liability entirely, and is deliberately **not** built here because it is a separable capability that would widen this release past its size band.

**The deploy-time proxy check is not extended, and its silence is not a defect.** That check implements only the first of the criterion's two branches and therefore cannot evaluate a rider on the second. The second branch is graded by the judgment path and re-run at the pre-plan crisping gate. Stating this is the point — an unstated coverage boundary reads as a gap.

**A pre-existing surface acquires an obligation it did not have, and one of the three check-shipping cards in the introducing release fully conformed before the rule existed.** The other two did not: one names the sensitivity arm as its deliverable and carries no must-not-flag arm on a check that is explicitly path-scoped; the other carries a must-fail control on a *comparison* rather than a specificity arm on the *checker*. Both were re-authored against this shape during the same release. That is the intended cost — the rule is exercised against live work, not against a hypothetical.

**The mechanization path is narrower than the other four tests.** The first four conformance tests are stated in mechanical form and become implementable as a structural check once the criterion's fire predicate has a recorded body declaration. This one additionally needs the item's *deliverable class* — mechanical check or not — recorded in the body, because that is its fire condition. Until such a declaration exists, this test is graded by judgment like the branch it belongs to.

**Reversibility: CHEAP.** Every change is additive prose in an existing table or block; rollback is a revert of the release merge. **Confidence: HIGH** on the binding and the placement, **MEDIUM** on whether guidance alone suppresses recurrence — which is precisely the measurement that decides whether alternative D is ever built.
