<!-- reference-durability: allow-link -->
---
title: "ADR-147 — One frontmatter-strip transform: a shared library bound to a committed conformance fixture, over replication governed by a registry comment"
status: Accepted
date: 2026-08-28
release: ci-stable-under-transient-conditions
deciders: "Stage 5 Solutioning spoke (five-option design exploration; the portable-form fork resolved on measurement rather than on shell semantics) + Collective Review (scope-lock; the empty-body guard was admitted into scope) + Stage 6 Engineering spoke (build, corpus re-derivation, mutation verification)"
tags: [release-notes, frontmatter-strip, shared-library, conformance-fixture, portability, awk, fail-closed, irreversible-mutation, replication-drift, ADR-068]
source_observations:
  - "A transform the governing standard calls DETERMINISTIC had four implementations plus two independent language mirrors. Measured over the live note corpus, two of them already computed different bytes from the other four for three notes."
  - "The invariant that the copies move together was carried by a prose comment naming SIBLING COPIES. That comment's own list was incomplete: it named two of the four shell sites and neither language mirror — and the sites it omitted are exactly the ones that had drifted."
  - "The drift was not detected by any gate, because the gate that would detect it is one of the copies. It fail-OPENS: on the runner where the transform degrades it compares an empty body against an empty body and reports no drift, at exit 0, with no diagnostic."
  - "The three call sites fail three different ways from one root cause. One fail-opens, one fail-safes behind its own guard, and one — the publisher — had no guard at all, so a degraded transform reaches an overwrite of a published Release body that no revert recovers."
  - "The mechanism sentence in the defect report could not be confirmed: no host reachable from the authoring environment could execute the divergent implementation, and a careful reading of the documented address semantics does not obviously produce the reported behaviour. The behaviour itself is measured; the explanation is not."
  - "A replacement whose equivalence is measurable on the available host was reachable, and a replacement whose correctness depends on the disputed semantics was not. Those are different epistemic positions for what looks like the same size of change."
  - "The conformance fixture's expectations had to be hand-authored. Generating them from any implementation would have made the fixture agree with that implementation by construction, which is the failure mode the fixture exists to prevent."
---

# ADR-147 — One frontmatter-strip transform: a shared library bound to a committed conformance fixture, over replication governed by a registry comment

## Status

**Accepted.** Authored at Engineering for the `ci-stable-under-transient-conditions` release, under the Collective Review scope-lock that admitted the publisher's empty-body guard into this card's scope.

## Context

The release-notes standard defines the published GitHub Release body as a **deterministic transform** of the committed in-repo note: strip the YAML frontmatter, publish the rest. One sentence, one rule, and the standard is explicit that every emit path must derive the body this way rather than composing one by hand.

It was implemented six times. Twice inline in the close-out tool, once each in the drift gate and the re-emitter, and modelled twice more in Python — once to predict the bytes an emit would publish, once to lint the body a Release page would render. Four implementations of a deterministic transform is a contradiction of the standard that defines it, and they had not stayed in step: measured across the live note corpus, the close-out tool's copy and the linter's model each computed different bytes from the other four for three notes — the three whose frontmatter is preceded by a lint directive, which the repaired form drops and the unrepaired form publishes as raw YAML.

**The invariant that held them together was a comment.** One of the copies carried a block headed `SIBLING COPIES of this transform, which must move together`, listing where the others lived. Its list named two of the four shell sites and neither Python mirror — and the sites it omitted are precisely the ones that had drifted. This is the whole argument in miniature: a comment cannot fail. It had been wrong for some time, and nothing anywhere reported that.

Two further findings make this a decision rather than a cleanup.

**First, the failure is not uniform across the callers, and the worst case is the one with no guard.** The same degraded transform produces three different severities. In the drift gate it fail-**opens**: an empty extracted body compared against an empty published body reports *no drift*, exit 0, no diagnostic — a live close gate that cannot fail on the runner where it degrades. In the re-emitter it fail-**safes**: that tool carries its own empty-body abort and refuses to publish. In the publisher it had **no guard at all**, so an empty body flows into an edit of a published Release body. That edit overwrites, and the platform keeps no version history for a Release body: it is the only genuinely irreversible path in the close-out sequence, and it was the one call site with nothing standing in front of it. Adopting fail-closed semantics for the transform *increases* that exposure rather than reducing it — an empty result becomes reachable where the old form leaked YAML instead — so the guard is a necessary companion to the transform change, not an improvement bundled alongside it.

**Second, and this is what decided the form of the replacement: the reported mechanism could not be confirmed.** The defect report attributes the empty output to a specific reading of how the divergent implementation's address ranges behave on one userland. No host reachable from the authoring environment could execute that userland, and a careful reading of the documented semantics does not obviously produce the reported behaviour. The *behaviour* is well-evidenced — it was measured at a coverage gate's first enablement, and the two affected tools were pinned to the runner where they are known good on the strength of it. The *explanation* is not. That distinction is load-bearing, because the obvious repair — write a different form of the same construct — would rest its correctness on a second reading of exactly the semantics whose first reading is in dispute, and would be unverifiable from the same host for the same reason.

## Decision

**One implementation per language, extracted to a shared home, with the cross-implementation invariant expressed as a committed fixture rather than a comment.**

**The transform is extracted to a sourced shell library** and the three shell tools source it rather than carrying copies. The two Python mirrors are aligned to the same frozen semantics. The implementation count goes from six to three — one per language runtime that genuinely needs one — and the shell count from four to one.

**The replacement is an `awk` state machine, chosen on epistemic grounds rather than on taste.** Its program state is an explicit counter in the source, with no implementation-defined range machine to disagree about, and — decisively — its equivalence to the shipped repaired form is **measurable on the host that exists**: byte-identical across the entire live note corpus, with a deliberately-wrong variant differing on every note in that corpus so the null result is a measurement rather than a vacuum. A second form of the disputed construct would have relocated the unverified premise instead of removing it. When one candidate's correctness is checkable here and another's is not, that difference outranks familiarity.

**The semantics are frozen as five numbered rules**, stated in the governing standard and summarised at the library: a lead-in before the opening fence is dropped; the opening fence and frontmatter are dropped; the closing fence is dropped and the remainder emitted verbatim, so a horizontal rule inside the body survives; fewer than two exact fences yields **empty** — fail-closed; and the fence match is exact, so a fence carrying trailing whitespace does not close the block.

**Fail-closed obliges every publishing caller to guard.** Rule four is chosen because it is the behaviour the callers' existing aborts were already written against, and because the alternative — returning the whole file when no fence is found, as one mirror did — publishes machine metadata onto a public page. But a fail-closed transform is only safe if the callers refuse its empty result. **Every call site that publishes must guard on empty**, and the guard is part of adopting the semantics, not a separate concern.

**The cross-implementation invariant is a committed fixture, and its expectations are hand-authored.** Each implementation's self-test iterates the fixture and asserts byte-equality, so a divergent reimplementation fails a named test instead of publishing quietly. The expectations are derived from the five rules by hand, never generated by running a transform: a fixture whose expectations are produced by the code it checks agrees with that code by construction and can never fail. Each binding also carries a **vacuity floor** — an assertion that the fixture was non-empty when iterated — because an absent or truncated fixture directory iterates zero times and reports clean, which is the same success-without-checking shape this whole change exists to remove.

## Decision kernel (version-agnostic)

> When a specification declares a transform deterministic and that transform has more than one implementation, the invariant that the implementations agree must be **executable**. A prose registry naming the sibling copies is not a control: it cannot fail, it goes stale silently, and it goes stale first in exactly the places that have already drifted. Extract to one implementation per language runtime, and bind every implementation to a single committed fixture whose expectations are authored from the specification rather than generated from any implementation. Where two candidate implementations are both plausible but only one's equivalence is measurable from the available environment, prefer the measurable one — a design that rests on an unverified reading of a disputed semantic is not equivalent in risk to one that removes the disputed construct. Where the chosen semantics are fail-closed, the guard at every mutating caller is part of the adoption, not a follow-on: making an empty result reachable without refusing it converts a wrong-output defect into a destructive one.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Extract to a shared library; bind all implementations to a committed fixture** | **Selected** | Removes the disputed construct rather than reasoning about it; equivalence measurable on the available host; the sync invariant becomes a test that can fail. |
| **A different form of the same construct**, portable across both userlands | Rejected — on principle, not taste | The root cause is that two competent readings of one address construct disagree and nothing in the environment can adjudicate. A different form of that construct relocates the adjudication problem rather than removing it, and its equivalence would be unmeasurable from the same host for the same reason the original defect went undetected. |
| **A pure-shell read loop** — the only candidate with zero external surface | Rejected | Genuinely attractive on dependency grounds. It loses on the file-or-stream duality one caller relies on, and on last-line-without-newline handling, both of which must be hand-managed correctly at every site — trading a portability hazard for a correctness hazard, in a fix whose entire subject is silent wrongness. |
| **A helper in the second language**, called as a subprocess | Rejected | Makes a second runtime a hard dependency of a tool that deliberately pins a minimal executable search path, and adds a fourth implementation to a problem defined by having too many. It would also register as a new tracked executable, incurring allowlist, manifest and coverage obligations for something that is one function. |
| **Repair each site in place and keep the registry comment as the sync mechanism** | Rejected — the repo already ran this experiment | Cheaper by one file. Rejected because the outcome is already observable: the registry's own list is incomplete today, and the sites it omits are the ones that drifted. Retaining the mechanism that failed, to govern the fix for the failure it caused, is not a conservative choice. |
| **Ship the transform change without the publisher's empty-body guard** | Rejected | Adopting fail-closed semantics makes an empty body *reachable* at a call site that previously leaked frontmatter instead. Without the guard the change would convert a wrong-output defect into a destructive one at the only irreversible step in the sequence. |
| **Generate the fixture expectations from the new implementation** | Rejected | Would make the fixture agree with that implementation by construction. A fixture that cannot fail is the artifact this decision exists to replace, rebuilt in a new medium. |
| **Lift the two affected tools' runner pins in the same change** | **Deferred, not rejected** | The original basis for those pins is discharged by this decision, and lifting them is owed. It is gated on a falsification — do those suites degrade under the coverage job's shallow checkout? — that could not be executed in this environment. Moving a suite onto a partition it has never run on, on unexecuted evidence, would trade one fail-open for another inside the release built to eliminate them. Each tool's header now records the pin's narrowed basis and what would lift it. |

## Consequences

**A fourth consumer of the transform now costs one source line rather than one more copy and one more registry entry.** That is the ordinary benefit, and it is the smaller one.

**The larger consequence is that the sync invariant acquired the ability to fail.** It moved from a comment — which had been wrong, silently, for some time — to a fixture that three self-tests iterate. A future implementation that diverges now fails a named test in the suite that owns it. The change is measurable in the right direction: the repo-wide population of the divergent literal fell from nineteen occurrences across twelve files to two, and both survivors are immutable historical artifacts excluded by construction — a shipped release plan and a frozen illustrative example, editing either of which would falsify the record.

**One correction is behaviourally inert today, and it was checked rather than assumed.** The linter's model additionally stopped treating a whitespace-padded fence as closing and stopped returning the whole file when no fence is found. Re-derived over the live corpus at the time of the change, its blocking finding count is unchanged and no note flips — with a seeded control proving the predicate can fire, so the null result is a measurement. The correction removes a latent divergence rather than changing a verdict.

**The guard adds a new reachable failure state to the publishing phase, and that is the point.** That phase previously had no way to refuse an empty body. It can now halt a close where it would otherwise have published nothing over something. A close that halts is recoverable; a blanked Release body is not.

**The documentation surfaces were swept, and the reason is not tidiness.** Several of the occurrences were copy-paste snippets in runbooks and chip prompts — executable guidance, whose next use would have reintroduced the defect into a new call site. Guidance that ships a broken idiom is a live re-infection path, not a stylistic residual.

**The GNU-side behaviour of both the old and the new form remains unexecuted from the authoring environment.** This is the honest residual, and it is why the runner pins stay. The transform's equivalence is measured on one userland and argued structurally for the other; the argument is strong — the chosen program uses no construct whose behaviour is in dispute — but it is an argument. The first execution-grade evidence will come from the coverage job once the pins lift, and the conformance fixture is what will make that run informative: an empty strip cannot agree with a non-empty committed expectation on any host, so a degraded transform is named rather than silently tolerated.

**A fixture directory is now load-bearing infrastructure.** It lives outside the discovery scope that would give it a self-test of its own, which is why every binding carries a vacuity floor. Deleting or truncating it turns three suites red rather than green — verified by mutation, not asserted.

## Reversibility

**CHEAP / Confidence HIGH.** The change is a new sourced library, a committed fixture, and edits replacing inline transforms with calls to it. No schema change, no data migration, no host-side state, and — critically — **no published artifact is mutated by the change itself**. `git revert` restores the prior bytes exactly.

The revert is bounded in an unusual and favourable way: because the transform is byte-equivalent to the shipped repaired form across the entire live corpus, a close that ran under this change publishes exactly what a close under the prior code would have published on the host where the prior code worked. A revert therefore cannot strand a Release page in a state the old code would not also have produced.

Two properties are worth naming. **The revert is self-announcing**: the conformance arms shipped with the fix fail on reverted code, so a partial or accidental revert turns the suites red rather than silently restoring the replication. And **the guard is separately revertible** from the transform — but should not be reverted alone: with fail-closed semantics in place and the guard removed, the publisher regains the irreversible path this decision exists to close.

The **ADR itself** is immutable by convention: superseding it is a Status transition plus a new record, never an in-place edit or a deletion.

## Related ADRs

- **[ADR-068](../../core/ADRs/ADR-068-domain-fan-out-sibling-vs-extend.md)** — sibling-vs-extend for the domain fan-out tracer, whose resolution extracted the shared schema emitter rather than maintaining two. The direct in-family precedent, on the same tool family, for the same call: two implementations of one declared-single contract are a drift defect regardless of how carefully the copies are annotated. This decision applies that precedent and adds the part ADR-068 did not need — a committed fixture, because here the implementations span two languages and no shared call path can bind them.
- **[ADR-152](ADR-152-dry-run-predicts-apply-asserts-mode-branch-placement.md)** — dry-run predicts, apply asserts. A sibling in this release on the same tool, and the same underlying posture in a different register: a convention that lives only as comments gets rediscovered one instance at a time. Its paired-arm discipline is the reason this decision's fixture bindings each carry a vacuity floor — a check that passes on the defective input is worse than no check.
