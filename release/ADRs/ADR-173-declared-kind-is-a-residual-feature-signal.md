<!-- reference-durability: allow-link -->
---
title: "ADR-173 — A declared work-item kind is a RESIDUAL feature signal in the allocation map, never a co-equal one"
status: Accepted
date: 2026-09-02
release: label-and-reference-integrity
deciders: "Stage 5 Solutioning spoke (three-option analysis on the tier placement, three on which implementation the fix lands in) + Stage 6 Engineering spoke (build, simulation, re-derivation against the closed release that surfaced the defect)"
tags: [release-velocity, allocation, work-class, label-taxonomy, work-item-kind, precedence, measurement-fidelity, plug-and-play, ADR-018, ADR-175]
source_observations:
  - "A closed release recorded its allocation as wholly debt on a membership that was half stories. The bucket was defensible on the merits; the route was not — the stories carried a provenance label the map did not recognise and a kind label the map named no arm for, so they fell to the conservative default. An issue of that shape could not register as feature allocation regardless of its content, so the metric was not measuring what it reported."
  - "The map was a hand-maintained enumeration that had drifted from the live label set on THREE independent counts, not the one the defect report named. Two further tokens were phantom — named by the map, present in no live label set and in no pack declaration — so their arms read as coverage while covering nothing."
  - "The provenance label the defect report proposed adding is not a content class at all. The intake template that applies it carries a REQUIRED category dropdown of seven options, and the label's own name is not among them; the template applies no category at submission and triage applies the chosen category later. Adding it to the feature arm would have encoded a submission channel as a work class."
  - "Two implementations of the map exist in one file. The one the acceptance criteria named has ten call sites and zero outside its own self-test block — it is the self-tested reference. The value that reaches the permanent ledger is computed by a second implementation in the file's production pass. Six of the eight graded criteria measured the reference, so a change landing only there would have passed seven of eight and moved the recorded metric by zero."
  - "Simulated against a deployment declaring its own kinds, the intuitive repair inverts every bug in the ledger: folded into the existing feature arm, a bug carrying both its category label and its kind projection resolves FEATURE, because the feature signal wins precedence. The same fold sends a protocol story to feature rather than protocol-slack."
---

# ADR-173 — A declared work-item kind is a RESIDUAL feature signal in the allocation map, never a co-equal one

## Status

**Accepted.** Authored at Engineering for the `label-and-reference-integrity` release.

**Numbering provenance.** Holds **ADR-173** branch-local. The binding oracle — the highest number on the mainline plus one — resolved to **170** at authoring time, and the tool's own detection listing shows 170, 171 and 172 already claimed **on this branch**, by sibling records committed ahead of this one. Those three are not the advisory sibling-branch claims the oracle is designed to step past: they are in this working tree and merge in the same unit, so taking 170 would be an immediate in-tree duplicate rather than a deferred one. This record therefore takes the next number after the branch's own contiguous claims. If the mainline claims 173 first, the renumbering tool moves this record at merge and in-release citations that read "ADR-173" denote it.

## Context

The release-velocity instrument maps each delivered issue's labels onto three work-class buckets — feature, protocol-slack, debt — whose realized split is the measured counterpart of the 60/20/20 allocation target set at bundling. The map was a literal enumeration: a fixed list of label tokens per bucket, scanned in order, with an unlisted issue falling off the end into the conservative debt default.

A closed release recorded **wholly debt** on a membership that was half stories. Every story carried a provenance label and a work-item-kind label, and the map named an arm for neither, so all three fell to the default. The bucket was defensible — that release genuinely repaired instrumentation — but the **route** was not: an issue of that shape could not reach the feature bucket regardless of its content. The same finding had been recorded independently at three prior closes before it was filed.

**Measuring the map found more drift than the report named.** Of thirteen tokens, three were phantom — present in no live label set and in no pack declaration. One of them was the *only* token in the feature arm besides the single live one, so the feature arm had been carrying two dead entries and one live entry for the whole of the pre-`v4.x` ledger. A dead arm has no failure signal of its own: it produces no error, only a quieter bucket.

**The obvious repair encodes a submission channel as a work class.** The report's measurable outcome names the provenance label directly. But that label is not a content class: the intake template that applies it carries a *required* category dropdown of seven options and the label's own name is not among them, the template applies no category at submission, and triage applies the chosen category afterwards. An issue carrying it already declares its content class through a *different* label. Adding it to the feature arm would double-count and would make the map say something the taxonomy does not.

**The real gap was a missing tier, and the tier's placement is the decision.** The work-item-kind labels are declared by the selected packs — a resolution surface the platform already reconciles against, and the same surface the sibling record in this release narrows the parity gate onto. Reading kinds gives the map a derived input instead of a hand-maintained list. But *where* the kind signal sits in the precedence order is not settled by deciding to read it, and the intuitive placement is wrong in a way only a deployment using the plug-and-play override model would surface.

**Simulated, folding the kind signal into the existing feature arm inverts every bug in the ledger.** On a deployment declaring a `bug` kind, an issue carrying both the `bug` category row and its `type:bug` projection resolves **feature**, because the feature signal wins precedence — and by the sibling record in this release, that pair is one classification at two altitudes, not two competing signals. The same fold sends a protocol story to feature rather than protocol-slack. The corpus packs do not declare a `bug` kind today, so the inversion is invisible on the shipped configuration and arrives with the first deployment that declares one.

**And the fix had to land in a function the graded criteria did not name.** The file carries two implementations of the map. The one the criteria name has ten call sites and **zero** outside its own self-test block — it is the self-tested *reference*, and the file says so outright. The value that reaches the permanent ledger comes from a second implementation in the production pass. Six of the eight criteria graded the reference. A change landing only there would have gone green on seven of eight while the recorded metric moved by exactly zero.

## Decision

**A declared work-item kind is a RESIDUAL feature signal: it resolves only where the declared category/cluster tier is silent. The map is a three-tier resolution — T1 declared category/cluster, T2 declared work-item kind, T3 stated default — and the tier order is load-bearing, not stylistic.**

And, as the corollary that makes the change observable at all:

**The resolution is defined ONCE and handed across the implementation boundary, never re-derived on both sides.**

Four obligations follow, and none substitutes for the others.

**1. The kind tier sits below the category tier, and the reason is compositional rather than aesthetic.** A kind label whose name is co-extensive with a live category row is *the same assertion at two altitudes* — the taxonomy binds them by declaration. The category altitude must therefore resolve first, or the projection contradicts its own parent. Placed there, precedence alone does the disambiguating work: wherever a kind name collides with a category row, that row is present on the issue and resolves at T1, so no runtime read of the category facet is needed. The alternative placements require exactly that second read, and get the answer wrong until they have it.

**2. The default is a stated branch, not the end of an enumeration.** T3 is written as its own arm with its rationale cited inline. An enumeration that ends by falling off gives a reader no way to distinguish "this case was considered and lands in debt" from "this case was never considered." The partition invariant — the three buckets always sum to delivered — depends on totality, and totality reached by omission is an accident that holds rather than a property that is asserted.

**3. The kind set is derived from the pack declarations at run time, through the existing resolver, and the map does not enumerate it.** A kind a deployment adds to its own pack resolves with no edit to the tool and no edit to the standard; a kind-shaped label no selected pack declares resolves at the default, so the derivation is not over-broad. The resolver is the one the parity gate already uses — not a second copy of the resolution rule, which would be a drift surface rather than a convenience. When it is unavailable the tool **announces a degraded measurement and falls back to T1 + T3**; it never silently drops the tier, because a dropped kind tier under-reports the feature bucket and reads as a healthier mix than the truth.

**4. Every token in the category tier must be a declared row, and that is asserted rather than assumed.** The three phantom tokens are retired. Retiring them changes no issue's class — the affected issues still resolve to the same bucket, now through the default rather than through a dead arm — so this is a coverage correction, not a measurement correction, and it is stated as such. The producing tool's self-test asserts every surviving category token against the pack set with a firing control, so the phantom class is a pre-merge failure instead of a silent drift.

## Decision kernel (version-agnostic)

> When a classification map gains a second signal that is a *projection* of a signal it already reads, the new signal is residual to the original, not co-equal: the altitude that owns the assertion resolves first, or the projection can contradict its own parent. Placing it co-equally is invisible on the configuration in front of you precisely when the collision requires a declaration your corpus does not yet carry — so the failing case must be built as a fixture rather than waited for. Where a rule has two implementations and only one is under test, a change graded solely against the tested one certifies a no-op: bind them by passing the resolved value across the boundary rather than re-deriving it on both sides, and grade the untested one against the tested one over a shared fixture set with a planted-divergence control. A default reached by falling off an enumeration is an accident that holds; a default written as its own branch with a cited rationale is a property.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Add the provenance label to the feature arm** (the defect report's literal remedy) | Rejected | Encodes a submission channel as a content class. The intake template's required category dropdown does not offer the label's own name, and the template applies no category at submission — so an issue carrying it already declares its class through a different label, and the arm would double-count. It also fixes one of three drift counts and leaves the map free to drift again on the next pack change. |
| **Fold the kind tokens into the existing feature arm** (kind as a co-equal signal) | Rejected | Simulated: inverts every bug on any deployment declaring a `bug` kind, because the feature signal wins precedence and the category/kind pair is one assertion at two altitudes. Sends a protocol story to feature. Requires a runtime read of the category facet to exclude the collisions — the read the chosen order makes unnecessary. |
| **Place the kind tier ABOVE the category tier** | Rejected | Same inversion, reached faster: the kind signal would pre-empt an explicit category assertion rather than merely tie with it. Also needs the co-extensive-category test at runtime. |
| **Kind tier BELOW the category tier, above the default** | **Selected** | The only order under which the category/kind collisions resolve correctly with no second read: precedence subsumes the co-extensiveness test. Leaves the category tier's internal order byte-unchanged, so no issue carrying a mapped category changes class. Reaches the same outcome as the sibling record's cardinality clause by a mechanism that requires nothing of it. |
| **Parse the pack declarations in the tool itself** | Rejected | A second implementation of the resolution rule, in a second instrument, that must agree with the first forever. The seam the sibling record ships exists precisely so there is one. The degrade path is the correct answer to an unavailable resolver, not a private parser. |
| **Enumerate the kind tokens in the map** as a fourth literal arm | Rejected | Reproduces the defect being repaired one level up: a hand-maintained list of a pack-declared set, drifting the moment a deployment declares a kind. It also cannot satisfy the criterion that a newly-declared kind resolves without editing the tool. |
| **Edit the self-tested reference only** (the implementation the criteria name) | Rejected | Passes seven of the eight graded criteria and moves the emitted allocation by zero — the reference has no call site outside its own self-test. Green on a defect that did not move is worse than red, because it closes the card. |
| **Edit both implementations independently** | Rejected | Satisfies every criterion and re-creates the two-copies problem the file had already solved once, for the delivery predicate, by defining the constant in one place and passing it across. Re-solving a solved problem in the opposite direction is a regression in the file's own design. |
| **Resolve once and pass the result across the boundary** | **Selected** | Reuses the file's existing precedent verbatim — the delivery-exclusion constant crosses on an argument for exactly this reason. The tier order is still expressed on both sides (that is what keeps the tested half a real reference), so the halves are additionally bound by a cross-implementation assertion graded over a shared fixture set with a planted-divergence control. |
| **Backfill the corrected allocation onto the written ledger rows** | Rejected | The standard's own failure modes forbid backfilling a synthesized measurement onto a historical row, and the ground holds here: the rows were derived under a different rule and re-deriving them would bias the calibration population they feed. The series is non-homogeneous across this release as a result — named and routed forward rather than absorbed. |
| **Map the two remaining unmapped category rows** in the same change | Rejected for this release | Neither is named by the graded criteria, and both are genuinely open questions about what class an observation or a sub-task represents — a different decision, not a longer version of this one. Routed forward so a grader does not read this record as covering them. |

## Consequences

**An issue whose only class signal is its work-item kind can reach the feature bucket for the first time.** The closed release that surfaced the defect re-derives from wholly-debt to a split, with the three stories moving and the three bugs staying, and the buckets still partitioning delivered exactly. That re-derivation is carried as a permanent self-test arm rather than a transcript, with the retired map inlined beside it as a fidelity control — without the control, a green run cannot distinguish "the fix works" from "the fixture never had the defect."

**The map stops being hand-maintained on its kind axis and stays hand-maintained on its category axis.** That asymmetry is deliberate and worth stating: kinds are operator-local by grammar and have a declaration surface, so they are derivable; the category tier's tokens are corpus-governed and few, so an assertion against the pack set is a better instrument than a derivation. The self-test asserts the category tokens; the resolver derives the kind tokens.

**A deployment that declares its own kinds is measured correctly here for the first time, and its bugs are not inverted.** Both properties are graded together, because the second is the failure the first would otherwise introduce. The tier-order regression arm is the one that fails if a future change flattens the tiers, and it is written to say so in its own failure message.

**The calibration series is non-homogeneous across this release.** Most written velocity rows record a zero feature bucket under the defective map, and the recalibration consumer reads the allocation actuals without distinguishing pre-fix from post-fix derivations. Backfilling is correctly forbidden. The discontinuity is real, is not this decision's to resolve, and is routed forward rather than left to be discovered by whoever runs the recalibration.

**The two implementations are now bound by an assertion rather than by a comment.** The file previously carried a comment stating that the halves implement the same rule. It was true and unenforced. The binding is now a self-test arm that extracts the untested implementation's own shipped source, runs it against the tested one over a shared fixture set, and requires a planted divergence to be detected — so a change to one half that is not made to the other fails pre-merge instead of drifting into the ledger.

**Retiring the phantom tokens changes no issue's class, and saying so is part of the change.** Every issue that reached a phantom arm still resolves to the same bucket through the default. A future reader must not restore an arm on the strength of its value having been preserved — which is why the surviving assertion pins both the value *and* the changed path.

**The degrade path can under-report the feature bucket, and it announces rather than hides that.** An unavailable resolver drops the kind tier, which biases the measurement toward debt — the direction that reads as a healthier mix than the truth. The announcement goes to stderr, so the emitted field stays byte-identical for the consumers that read it as an opaque value.

## Reversibility

**CHEAP / Confidence HIGH.** Every change is repository content — the tier restructure, the derived kind set, the retired tokens, the standard's map and failure-mode row, and the self-test arms. All revert by reverting the commit. No repository state, label state, or ledger row is mutated: the written velocity rows are left exactly as they are, and the corrected derivation applies forward only.

**One asymmetry is worth naming rather than filing under the tier.** Reverting restores the phantom tokens along with everything else, and their arms would again read as coverage. The self-test assertion that keeps them retired reverts with them, so a partial revert that keeps the assertion and restores the tokens fails pre-merge — which is the correct behaviour and is stated so a future reverter is not surprised by it.

## Related ADRs

- **ADR-018** — establishes the work-item-kind discriminator whose label projection this map now reads as a residual signal. This record governs the projection's PRECEDENCE inside one measurement instrument; it does not touch the discriminator.
- **ADR-175** — the sibling record from this release. It establishes that a kind projection of a declared category row is one classification at two altitudes, and narrows the parity gate onto the pack declarations. This record consumes that resolver rather than forking one, and its chosen tier order reaches the same non-competition conclusion by precedence rather than by a runtime test — so the two remain consistent without either depending on the other's mechanism.
- **ADR-174** — the sibling record establishing that an unrecognized verdict class is a finding rather than an absence. The same instinct governs the degrade path here: an unavailable kind tier is announced, never silently absorbed into a quieter bucket.
