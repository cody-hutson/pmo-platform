<!-- reference-durability: allow-link -->
---
title: "ADR-175 — A kind projection of a declared category row is one classification at two altitudes, not two competing labels"
status: Accepted
date: 2026-09-01
release: label-and-reference-integrity
deciders: "Stage 5 Solutioning spoke (three-option analysis on the resolution mechanism, three on the cardinality exposure) + Stage 6 Engineering spoke (build, fixture proof, re-measurement) + Collective Review (the irreversible label cascade is gated separately at Stage 9)"
tags: [label-taxonomy, label-grammar, label-parity, work-item-kind, cardinality, escape-hatch, namespace-resolution, plug-and-play, ADR-018, ADR-070, ADR-174]
source_observations:
  - "A parity gate registered an entire label family as a namespace prefix, so every live label beginning with that prefix passed without any selected pack declaring the corresponding kind. The gate was believed to reconcile the family; it verified only that the string began with the prefix. Five live labels sat undeclared and unreported, spanning several hundred issues."
  - "The blind spot was encoded in the gate's own fixture suite: the suite used one of the five undeclared labels as its NON-orphan exemplar, with a comment asserting the prefix resolution. The test that would otherwise have caught the defect asserted it instead."
  - "The obvious repair — deleting the prefix from the registered set — produces the correct result on the shipped corpus and fails the acceptance criterion, because the criterion's fixture is an operator-local pack declaring a kind with no label row. A label-row-only predicate reports that kind identically with and without the pack: subject and control collapse into the same answer, which is a degenerate probe rather than a check."
  - "The schema binds the two declaration forms in one direction only. A kind-projection label row must name the kind it projects; no clause requires a label row per declared kind. Declared kinds and declared kind-projection rows are therefore two different sets that coincide in the shipped corpus and diverge in exactly the operator-local case the plug-and-play grammar exists to serve."
  - "Narrowing the resolution surfaced a second-order exposure: 188 issues carry both a content-class category row and its kind projection, which the one-category-label rule reads as two category labels on one axis. Probed for an enforcer across all 38 deploy checks with two firing controls — the single subject hit was an unrelated string match. No check enforces that cardinality anywhere in the platform."
  - "One live label in the family resolves to no declared kind and is nonetheless correct: a frozen legacy alias of a category row that three named consumers read, and that the grammar states outright must not be deleted. A hardening with no tolerated arm would report it forever and invite exactly the deletion those consumers cannot survive."
---

# ADR-175 — A kind projection of a declared category row is one classification at two altitudes, not two competing labels

## Status

**Accepted.** Authored at Engineering for the `label-and-reference-integrity` release.

**Numbering provenance.** Held **ADR-171** branch-local. The binding oracle is the highest number on the mainline plus one, which resolved to 170 at authoring time; 170 is held by the sibling record landed earlier on this same branch, so this record takes 171. Stepping higher to dodge a *visible claim on another unmerged branch* was rejected deliberately: a duplicate is the cheap failure the renumbering tool resolves at merge, whereas a gap fails the contiguity gate and blocks every subsequent record until someone fills it. If the mainline claims 171 first, the tool renumbers this record at merge and in-release citations that read "ADR-171" denote it.

**Numbering provenance — `171 → 175`.** Held **ADR-171** branch-local; renumbered to **ADR-175** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 171. In-release citations that read "ADR-171" denote this record.

## Context

A label family projecting the work-item-kind discriminator onto the label surface was registered in the parity gate as a **namespace prefix**, alongside two genuinely open namespaces. A prefix registration says "anything under this prefix is registered." For the two open namespaces that is correct — an initiative or epic slug is operator-minted, unbounded, and has no declaration surface to resolve against. For the kind family it was wrong, and wrong in a way that made the family unfalsifiable: a kind has exactly one declaration surface, so a prefix match discards the only check available.

The consequence was not subtle once measured. Five live kind labels had no pack declaration and no gate complaint. The gate reported a clean kind family while holding no evidence about it whatsoever.

**The repair is not the one-line deletion it looks like.** Removing the prefix from the registered set makes the five report correctly on the shipped corpus. It also fails the acceptance criterion that matters, and the failure is invisible unless the probe is shaped to expose it. The criterion's fixture is an **operator-local pack declaring a kind with no label row** — the ordinary shape of the plug-and-play override model, where a deployment brings its own kinds and the corpus never carries them. A predicate resolving only against declared label rows cannot see that pack. It reports the kind as unregistered *with* the pack selected and *without* it: subject arm and control arm return the same answer, so the criterion is satisfiable by an implementation that ignores operator-local packs entirely. That is the same defect class as the one being repaired — a scope predicate narrower than the population it is believed to cover — reintroduced by the repair.

The schema is what makes the two sets differ. It requires a kind-projection label row to **name** the kind it projects, and requires nothing in the other direction: no clause obliges a label row per declared kind. "Declared kinds" and "declared kind-projection rows" are therefore distinct sets. They coincide in the shipped corpus, which is why the difference is easy to miss, and they diverge in precisely the case the plug-and-play grammar exists to serve.

**Narrowing the resolution then exposed a cardinality question that had been dormant.** Where a deployment declares a kind whose identifier is also the name of an existing archetype-invariant **category** row, an issue may carry both labels — the content-class row and its kind projection. The one-category-label rule reads that as two category labels on one axis. The exposure is live and growing: 188 issues carry such a pair today, including two of the work items this release is itself resolving.

The tempting framing was that the release must not close cards breaching the invariant it is hardening. That framing is false, and measuring it is what shows the correct remedy. The gate being hardened reconciles the label **registry** — does a live label resolve to a declaration. The cardinality rule governs label **application** — how many category labels one issue carries. They are different questions on different objects, and **no check in the platform enforces the second**: probed across all 38 deploy checks with two controls that fire, the single subject match was an unrelated string. The rule is a prose-declared normative predicate with no runner. That does not make the exposure acceptable; it makes the correct remedy structural rather than a mass relabel of 188 issues.

## Decision

**A kind projection whose declared join names a live category row is the SAME classification asserted at two altitudes — the content-class row and its kind projection — not two competing category labels. The one-category-label rule is satisfied by the pair, and only under that declaration.**

And, as the resolution change that forces the question:

**A kind label resolves against the SELECTED packs' declarations — as a label row or as a declared kind, unioned — never by namespace prefix. The family remains an unenumerated pattern in the grammar and stops being a pattern in the gate.**

Four obligations follow, and none substitutes for the others.

**1. Resolve against the union of both declaration forms, not either alone.** A live kind label is registered when a selected pack declares it as a label row *or* declares the corresponding kind. Resolving on rows alone blinds the gate to a kind-only operator-local pack — the criterion's own fixture. Resolving on kinds alone drops every non-kind label a pack contributes. The union is monotone with respect to false reports and is the only form under which the acceptance probe discriminates: the projected label is absent from the finding arm with the operator-local pack selected, and present without it.

**2. The gate's source list must reach the packs that declare the kinds.** Kinds are operator-local by grammar and are never authored into the shipped corpus. A gate whose canonical set is built from corpus packs alone would, the moment resolution narrows, report a deployment's own legitimately-declared kinds as unregistered — converting a correct hardening into a permanent false finding for every deployment that uses the override model as designed. Reaching the operator-local packs is part of the decision, not a follow-on convenience.

**3. Bind the cardinality exception to the declaration, and to nothing else.** The pair is one assertion **because the join declares it so**. Where no selected pack declares the kind, no join exists, and the pair is two category labels that the rule binds normally. The exception does not reach a kind label that joins no declaration, and it does not reach a declared kind with no co-extensive category row. It licenses exactly one shape and leaves the rule's cardinality intact everywhere else.

**4. A tolerated legacy alias is filtered, never declared.** One live label in the family resolves to no declared kind and is correct anyway — a frozen alias of a category row, read by three named consumers, which the grammar states must not be deleted. It is excluded from the finding arm and added to **no** arm and to **no** canonical set. The distinction is load-bearing: declaring it canonical would make it *required-if-absent* in the enforce-capable arm, when what is true of it is that it is *tolerated-if-present*. Its home is the gate's own corpus-side constant rather than a pack contribution or an operator-local allowlist — a contribution surface can be overridden and an operator-local surface can be dropped, and a tolerance that a deployment can silently discard is not a tolerance.

## Decision kernel (version-agnostic)

> Register a namespace as a resolution pattern only when its members have no declaration surface to resolve against; where a declaration surface exists, resolve against it, because a prefix match on a declarable family discards the only check available. When two declaration forms are bound in one direction only, resolve against their union — the direction that is unbound is exactly where the sets diverge, and a probe that cannot separate the two forms is degenerate rather than passing. Where a taxonomy projects one classification at two altitudes and a declared join binds them, that is one assertion and a cardinality rule must say so explicitly; where no join exists, the rule binds unchanged. A value that is correct-if-present but not required-if-absent is filtered from the reporting arm, never added to the canonical set.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Delete the prefix from the registered set** and change nothing else | Rejected | Correct on the shipped corpus, degenerate against the operator-local fixture: it reports the projected kind identically with and without the declaring pack, so subject and control collapse. Satisfiable by an implementation that ignores operator-local packs entirely — the defect class being repaired, reintroduced by the repair. |
| Keep the prefix, add a **post-filter** re-checking the family against declared kinds | Rejected | Establishes a second resolution path parallel to the existing declaration parse, for a result the union already produces. Two paths that must agree are a drift surface; one path that unions two inputs is not. |
| **Union the declared kinds into the concrete set, then drop the prefix** | **Selected** | The only form under which the acceptance probe discriminates. Reuses the existing parse shape rather than introducing a second resolver, and its finding arm on the shipped corpus is identical to the one-line option's — so the extra parser buys correctness on the operator-local case and costs nothing on the corpus case. |
| Declare the contested kind in a **shipped corpus pack** to resolve the cardinality pair | Rejected | The grammar states outright that declared kinds are operator-local and are never authored into this corpus. It would make the corpus canonicalize on a label only a deployment can legitimize — backwards, and contradicted by the pack comment that correctly declines to re-project it. |
| **Retire the co-extensive category row** so the kind projection is sole-canonical | Rejected | Reaches 377 carriers plus the intake template that auto-applies it plus every consumer enumerating by it, to make the corpus depend on a label no corpus pack declares. Larger blast radius, wrong direction. |
| **Strip one label from all 188 dual-carrying issues** | Rejected for this release | Treats the symptom without closing the intake path — the pair has been re-accruing steadily — and stacks a second bulk repository-state cascade onto a release already carrying an irreversible one. The structural clause is what stops the accrual; the population disposition is separable and is routed forward. |
| Amend the cardinality rule's numbered text directly | Rejected | Weakens a one-category-label invariant generally in order to license one declared shape. The clause lives in the kind-label section with a single cross-reference from the rule, so the invariant's text stays strict and the exception stays bounded and readable in one place. |
| Home the tolerated alias as a **pack label row** | Rejected | The schema makes the declaration join REQUIRED on a kind-projection row, and this alias joins no declaration — the row would be schema-invalid, and the grammar states outright it is not a kind row. |
| Home the tolerated alias in an **operator-local allowlist** | Rejected | Allowlists are the operator-local surface; this tolerance is corpus-governed, frozen by the grammar, and names three in-corpus consumers. An operator-local home lets a deployment silently drop it and shrink the population a sibling check counts. |
| Emit the undeclared kinds as a **new verdict class** rather than into the existing finding arm | Rejected for this release, recommended for re-review | Was rejected on the ground that the consumer selected classes by value and would silently drop a third token. The sibling record landed in this same release falsifies that ground — unrecognized classes now bucket and report. It is rejected now on a different and narrower basis: the graded criteria name the existing arm by name, so a distinct class would make six of them read false as written. A class split is a criteria change first and a code change second. |

## Consequences

**The kind family is falsifiable for the first time.** A live kind label that no selected pack declares is reported, by name. The gate's claim about the family is now backed by evidence rather than by a string prefix.

**The fixture suite that encoded the defect now encodes its inverse, in pairs.** The suite previously used an undeclared kind label as its non-orphan exemplar. It now asserts that label as a finding, asserts the declared kinds as non-findings, and carries the operator-local case as a **two-armed** assertion — reported without the declaring pack, absent with it. A one-armed version of that assertion passes under the rejected one-line option, which is why both arms are mandatory rather than thorough.

**The tolerated alias needs a class of its own in the reasoning even though it produces no output.** It is inert by construction — filtered before the arm is built, contributing to nothing. That inertness is precisely what bounds the hardening: it is the reason a correct narrowing cannot shrink the population a sibling check counts, which is the failure the grammar warns about.

**Every deployment's operator-local packs are now read by the gate.** This widens what the gate sees, and the widening is the point. A deployment with no operator-local packs is unaffected — the source list is guarded exactly like the corpus list and adds nothing when the directory is absent.

**One behaviour extends into the enforce-capable arm and is stated rather than discovered later.** Because declared kinds join the canonical set, a kind declared by a selected pack whose projected label does **not** exist reports as absent-from-live, which is the enforce-capable direction. On the shipped corpus this is vacuous — every corpus-declared kind carries both a row and a live label — so the arm is unchanged there. On a deployment declaring a kind whose label was never created, it is a true finding of exactly the class that arm exists for, and it is a consequence of treating a declared kind as a declaration rather than a hint.

**The 188-issue cardinality exposure is bounded by the clause and not resolved by it.** The clause states which pairs are conformant; it does not relabel anything. On a deployment whose packs do not declare the kind, the pair remains non-conformant and the two work items this release owns are resolved by a two-label strip. The residual population is deliberately routed forward rather than absorbed, and a downstream grader must not read this record's criteria as covering it.

**The cardinality rule remains unenforced by any check, and this record does not change that.** It is a prose-declared predicate whose runner does not exist. Naming that plainly is the point: a clause added to an unenforced rule improves what a reader is told and nothing about what the platform catches. Whether to build the enforcer is a separate decision with its own cost.

**The class-split question is deferred with its ground already falsified, which is the honest form of a deferral.** The original basis for folding these findings into the existing arm no longer holds. The current basis is narrower and is about grading instruments rather than about the code. That distinction is recorded here so the re-review starts from the real reason rather than re-deriving a stale one.

## Reversibility

**CHEAP / Confidence HIGH** for every content change — the resolution narrowing, the tolerated-alias constant, the source-list extension, the fixture inversion, and all four grammar clauses. All are repository content, revertible by reverting the commit. The gate's finding arm is warn-capable and outside the CI-required subset, so a revert is not time-pressured.

**IRREVERSIBLE / Confidence HIGH** for the label retirements this decision's findings authorize but do not execute. Label state is not in version control. Re-creating a deleted label restores its name, colour and description from an operator-captured listing; it does **not** restore its issue associations, which no artifact that will exist can reconstruct. The retirement reach is wider than the pair-carrier count that motivated it — a deletion reaches every carrier at once, including carriers outside the measured intersection — and the sign-off must name the wider figure. Process weight scales accordingly: the retirements carry an explicit sign-off gate with a rollback-infeasibility statement, while everything above carries lightweight confirmation.

## Related ADRs

- **ADR-018** — establishes the work-item-kind discriminator this label family projects onto the label surface. This record governs how that projection RESOLVES and how it composes with category cardinality; it does not touch the discriminator itself.
- **ADR-070** — fixes the methodology-pack composition grammar: the grammar owns groups and rules, packs contribute concrete rows. The union decision here is an application of that division — the grammar declines to enumerate the kinds, so the gate must resolve against the packs rather than against the grammar.
- **ADR-174** — the sibling record from this release. It establishes that a verdict class exists to separate conditions whose remedies differ, and that an unrecognized class is a finding rather than an absence. Its consumer fix is what falsified this record's original ground for declining a class split, which is why the deferral above is recorded with its reasoning rather than its conclusion.
