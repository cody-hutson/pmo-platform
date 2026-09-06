---
title: "ADR-191 — An emitter asserts only properties of its own emit; a check-scoped or id-scoped claim is a caller-supplied input"
status: Accepted (operator-ratified at the deploy-checks-hardening-batch Stage 5 Collective Review scope-lock, 2026-09-05; the operator adopted a third shape after rejecting both the card enumerated)
date: 2026-09-06
release: deploy-checks-hardening-batch
deciders: Stage 5 Solutioning spoke (five-candidate design exploration, two eliminated on in-corpus evidence) + operator at the Collective Review scope-lock + Stage 6 Engineering on the branch-mechanism deviation
tags: [deploy-checks, emitter-family, advisory-class, per-caller-fact, closed-set-parameter, static-conformance, ADR-134, ADR-094]
source_observations:
  - "The shared advisory emitter appended one fixed clause to every emit, naming a gate identifier and asserting a check-level enforce-capability posture. Measured over the live corpus at authorship: 16 call sites across 9 check-id families, of which 12 carried a gate identifier belonging to a different check. Both halves of the clause are per-caller facts, so neither could be correct for more than one caller."
  - "The enforce-capability half was false under either reading of its subject. Read as the check identifier, it was false at 2 of the 9 families — each carries a live escalating leg under the same identifier. Read as the check number, which is how the console groups the line, it was false at 6 of the 8 checks involved. A remedy that fixed the falsity without fixing which question the sentence answered would have left a reader unable to tell."
  - "Eight of the nine families had no gate to point at. A design making an authority a required input would have pushed eight callers into inventing one, so the parameter would have had to admit a sentinel value that means 'none' at nearly every site."
  - "The corpus had already worked around the shared sentence twice, in two different ways, and both workarounds were load-bearing. Three checks split their advisory arm onto a disjoint check identifier specifically so the shared sentence would not lie; another check had to place its mode resolver ahead of a sibling leg for the same reason. Three independent artifacts working around one sentence is a structural signal rather than three coincidences."
  - "The emitter's non-escalation is structural, not a default: its body carries no mode branch, no enforce branch, and no failure-counter increment. Its own header states this, the degraded-state emit contract fixes it as a class property, and a live regression harness executes two of its arms against a real failure counter to prove it. An in-body raise to satisfy the loud-failure requirement would have falsified all three."
  - "The escape-helper commit that landed immediately before this one on the same release branch introduced a call to a top-level helper inside both the advisory and the warn emitter bodies. The sibling regression harness inlines three functions into its synthesized runner and that helper is not among them, so under nounset the runner aborts before printing its counter. Two of that harness's seven arms fail on the branch as a result; restoring the helper to the extraction turns all seven green. Diagnosed, reproduced and reverted during this record's authorship; not remediated here."
supersedes: none
---

# ADR-191 — An emitter asserts only properties of its own emit; a check-scoped or id-scoped claim is a caller-supplied input

## Status

**Accepted** — operator-ratified at the `deploy-checks-hardening-batch` Stage 5 Collective Review scope-lock on 2026-09-05. The card that raised the defect enumerated two remedy shapes; the operator adopted **neither**, and ratified a third that splits the remedy by the *kind* of fact each half is.

**Numbering provenance.** This record was authored at the next free number computed from the mainline anchor plus one. A branch claim is detection-only and never binds, and the detector reported one such claim at this number on an unrelated branch; per the numbering rule that claim is not an input, so this record takes the slot rather than skipping it. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Citations use the slug token `{{ADR:advisory-emit-asserts-only-its-own-scope}}`, which carries no number shape and resolves at the claim.

## Context

A shared emitter in the deploy-check surface appended one fixed clause to every advisory line it produced. The clause made two claims: it named a gate identifier as *the* authority for the finding, and it asserted that the emitting check is never enforce-capable.

**Both claims are per-caller facts, and the emitter is shared.** That is the whole defect, and it is worth stating as a general property rather than as two bugs. A fact that varies by caller, stated once in shared code, is wrong for every caller but the one it was written for. It cannot be repaired by choosing a better value, because there is no value that is correct at more than one site.

The two halves are *different kinds* of fact, and the design turns on that difference.

**The authority is a fact the caller already owns and already states.** The one check for which the named gate is genuinely the authority writes that gate into its own check banner and into its own detail string. The shared default was therefore pure duplication at the single site where it was true, and a falsehood everywhere else. Eight of the nine emitting families have no gate to point at at all — one of them structurally, because no enforce flip is planned for it.

**The enforce-capability posture is a fact no caller stated anywhere.** It is also the half that can be *graded* against measured behaviour: whether a given check identifier can escalate is observable by counting its escalating emits. So it is the half that must become an input, and the only half worth parameterising.

**A third defect sat inside the second claim: its subject was ambiguous.** The emitted line leads with the check identifier, so a reader takes the subject to be the identifier; the console groups the line under a check-number header, so a reader equally takes it to be the number. The two readings give different answers about how false the sentence is. A remedy that corrected the falsity without resolving the ambiguity would leave the next reader unable to tell which question the sentence had answered.

**One constraint bounded the whole solution space before any option was scored.** The requirement that a caller supplying no input "fail loudly" is satisfiable inside the emitter only by giving that emitter an escalation path. The **absence** of any escalation path is precisely the guarantee the emitter's own header states, the degraded-state emit contract fixes as a class property, and a live regression harness proves by execution against a real failure counter. Buying the loud failure in-body would have spent three artifacts to satisfy one criterion.

## Decision

**An emitter asserts only properties of its own emit. Anything scoped to the check, to the check identifier, or to a downstream gate is a per-caller fact, and it is supplied by the caller.**

Four sub-decisions follow, each with its own reason.

**D1 — The authority is DELETED from shared code, not parameterised.** No authority parameter exists. A caller that has an authority names it in its own detail text, where the one such caller already did; a caller that has none says nothing. Deletion is chosen over parameterisation because the population is overwhelmingly authority-less: a required authority argument would need a "none" sentinel at eight of nine families, and a sentinel that is the answer almost everywhere is a field that should not exist. This also removes duplication at the only site where the claim was ever true, rather than adding a second home for it.

**D2 — The posture becomes a required closed-set argument, with the check identifier as its subject.** The set has exactly two members, one asserting that no emit under this identifier can gate and one asserting that this emit cannot while siblings can. The identifier — not the check number — is the subject, and it is printed literally in the rendered clause, because the number is a console grouping with no runtime identity while the identifier is what the mode resolver keys on and what the emitted record carries. Printing the subject closes the ambiguity by construction rather than by convention. The set has exactly two members because the measured population resolves into two classes with no residual; a free string cannot be graded, and a third member would have no instance.

**The tokens deliberately avoid the word "advisory".** That word already carries three senses in this corpus — the emitter class, the flip-decision posture meaning *enforce-capable but held at warn*, and ordinary prose. The second of those is the **opposite** of what the token must convey, so a token spelled from it would be actively misleading.

**D3 — The contract is graded by a static assertion OUTSIDE the emitter body, and this is the load-bearing decision.** A missing token, or a declared posture contradicting the measured escalation surface of its own identifier, fails the build. It does not raise at runtime, and the emitter acquires no escalation path. This is where the loud-failure requirement is discharged, and it is the only place it can be discharged without falsifying the class guarantee. The harness extracts every region it asserts on from the live source at run time; reports denominators rather than pinning them, because a pinned call-site count is a drift alarm rather than a conformance gate; and carries sensitivity arms that mutate a copy — flipping one declared posture, dropping one argument — so that each of its zeros is a measurement rather than a blind spot.

**The runtime behaviour on an omitted token is deliberately silent and deliberately correct.** The emitter renders only the class-true clause and asserts no scope at all. It never guesses, and it never aborts the run: the surrounding script arms `nounset`, so reading the argument defensively is what keeps a two-argument caller from taking down an entire check suite instead of reporting one bad call. The omission is invisible at runtime **by design**, which is exactly why the static gate is not optional — it is the only thing that sees it.

**D4 — The declared coverage boundary is stated, not implied.** The assertion is that *shared code* cannot ship a per-caller fact, and the property is structural: the emitter has no authority parameter and no authority literal. A caller that writes a wrong authority into its **own** detail prose is not detected, because detail is caller-owned free text for every member of this emitter family and grading it is a different instrument. The residual is named here rather than papered over.

## Consequences

**Positive.** A per-caller fact can no longer be stated from shared code, and the class of defect this record addresses becomes unrepresentable rather than merely fixed. Adding a new advisory family costs one token at one call site, and omitting it fails the build instead of shipping a false sentence a reader may notice several stages later. The claim now sits adjacent to the call it governs, which is the property this corpus already identified as what makes a claim checkable. The emitted record schema is untouched: the clause is console-only, and widening it for a fact a static assertion already grades would relocate a claim into an emitted record, which the degraded-state emit contract warns against by name.

**Negative.** Every call site is touched, and a future one must remember a third argument that has no runtime consequence when omitted. The gate is what makes that acceptable, and the gate is a separate artifact that must keep running; a release that disables it restores the silent-omission hazard without restoring the false sentence.

**The disjoint-identifier workarounds are RETAINED and are load-bearing under the new shape.** Three checks split their advisory arm onto its own identifier when the shared sentence was the only thing available. Those splits are what make the stronger of the two posture tokens *measurably* true at six families. Merging the identifiers back would re-introduce a false claim by another route, so the workaround outlives the defect that forced it.

**One mechanism deviation was forced at implementation and is recorded rather than smoothed over.** The design specified the posture branch as a `case` construct. The live regression harness asserts that the extracted emitter body contains no `case ` substring at all — a substring test, blind to whether the construct branches on a mode — so the specified mechanism would have reddened a gate the design was written to protect. The branch ships as `if`/`elif` instead. Behaviour is identical; the deviation is in spelling only, and it is noted because the collision was invisible from the design surface and the next author of an emitter-family change will meet it too.

## Alternatives Considered

**Parameterise both facts.** The card's first named shape. Rejected because its loud-failure limb is unsatisfiable in-body without an escalation path, and because it forces a "none" authority sentinel at eight of nine families.

**Emit a bare marker and let each caller write its own detail.** The card's second named shape. Rejected on the card's own stated ground: the card asks that a silent wrong default become a loud missing input, and this option converts it into *nothing at all* — the posture claim disappears, and there is no subject left to grade.

**A declaration registry keyed by check identifier, consulted by the emitter.** Rejected on adjacency, which this corpus has already ruled on for this exact emitter: a registry moves a per-call-site claim thousands of lines from the call it governs, reproducing in a new form the very defect of a fact stated far from where it is true. A secondary objection — the natural implementation wants an associative array and this surface runs under a shell version that has none — is real but not the deciding one.

**Split the emitter into two class members, one per posture.** Rejected because it multiplies functions on the wrong axis. The emitter family's axis is the emit *class*, and a new member is admitted only as a new class. Posture scope is not a class; both members would still be the same class, and every future reader would have to learn a second axis to read the family.

## Reversibility

**CHEAP.** Confidence **HIGH**. The change is additive at every surface: one defaulted argument on one shared function, one literal appended per call site, one new test file, one workflow step, one sentence in a discipline rider. It introduces no out-of-tree state, no deployed-copy propagation and no data migration, and it does not alter the emitted-record schema — so reverting the release merge restores the prior behaviour byte-for-byte. The one asymmetry worth naming is that a revert also removes the static gate, which returns the surface to a state where a per-caller fact in shared code is possible again; that is a restoration of the prior risk rather than a new one.

## Related ADRs

- **The degraded-state emit contract** (referenced in this record's `tags`) — this record extends its emitter-class table with a scope rule and supersedes nothing in it. That table is what this decision reads strictly: the "never gates" cell is a property of the **class**, never of the **check**, and the retired sentence over-reached the table it implemented.
- **The extend-before-create determination record** (referenced in this record's `tags`) — the static gate ships as a new member file plus one workflow step, which is that harness directory's designed extension point rather than a new mechanism, so no net-new check number or runner is created.

## References

- The probe-validity rider in the review discipline gains one sentence carrying the scope principle in surface-agnostic form, so the next emitter surface does not re-derive it.
- The regression harness that proves the emitter's non-escalation by execution is the artifact whose arms constrain where the loud failure may live; its extraction anchors are named in the emitter's own header so a future reflow does not silently break them.
