<!-- reference-durability: allow-link -->
---
title: "ADR-176 — An arm's escalation posture is carried by its emitter, not by the check's mode dial"
status: Accepted
date: 2026-09-02
release: label-and-reference-integrity
deciders: "Stage 5 Solutioning spoke (four-candidate design exploration on the class, four on the registry home) + Stage 6 Engineering spoke (build, mutation testing, live consumer proof) + Collective Review (the operator-run label cascade is gated separately at Stage 9)"
tags: [deploy-check, gate-posture, advisory-only, verdict-class, label-parity, fail-open, non-escalating-arm, ADR-174, ADR-175]
source_observations:
  - "The mode resolver that decides whether a deploy check warns or fails is keyed on the CHECK id. A check with several finding arms therefore has exactly one dial for all of them: flipping the check to enforce arms every arm at once, including arms whose finding class must never block."
  - "A new finding class was needed whose remedy overwrites live label metadata — repository state that no revert restores — and which the gate structurally cannot distinguish from a deliberate operator override. Routing it through the escalating emitter would have made 32 such rows blocking the moment anyone flipped the shared dial, for reasons unrelated to that class."
  - "The check already carried a prose guarantee of exactly this kind and it was already false: a comment asserting one arm 'Never FAILs' sat directly above a call to the escalating emitter with no mode guard. The comment was accurate when written and drifted from the code afterwards, which is the failure mode a prose guarantee has."
  - "A structurally non-escalating emitter already existed for a different reason — a check whose predicate cannot distinguish a violation from a correct record. Its body contains no mode branch and no failure-counter increment anywhere, so the guarantee is a property of the code's shape rather than of a default value a later edit could flip."
  - "The readiness protocol that governs a check's warn-to-enforce graduation is written about hooks and whole checks. It says nothing about adding a finding class to an existing check, so nothing in the corpus stated which of two emitters a new arm should take, or on what basis."
  - "This check's own posture had already been ratified as terminally advisory on architectural grounds — its verdict is not deterministic for a fixed tree, because it reads live state outside the repository. An arm that could escalate would contradict a ratification the corpus already carries."
---

# ADR-176 — An arm's escalation posture is carried by its emitter, not by the check's mode dial

## Status

**Accepted.** Authored at Engineering for the `label-and-reference-integrity` release.

**Numbering provenance.** Held **ADR-172** branch-local. The allocator returns the next free number above the mainline anchor and deliberately ignores branch-local claims, so it returned a number two siblings on this same branch had already taken; 172 is the first number free in this tree. If the mainline claims 172 first, `release/tools/renumber-adr.py` renumbers this record at merge, and in-release citations that read "ADR-172" denote it.

**Numbering provenance — `172 → 176`.** Held **ADR-172** branch-local; renumbered to **ADR-176** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 172. In-release citations that read "ADR-172" denote this record.

## Context

A deploy check's escalation posture is resolved per **check id**. One check, one dial. That was adequate while every arm of a check reported the same kind of finding, and it stops being adequate the moment a check grows an arm whose finding class is categorically different from its siblings'.

This release added exactly such an arm. Three existing arms of the label-parity check are name-keyed: a declared label absent from the live set, a live label registered nowhere, a live label the grammar declares excluded. Each has a remedy an operator can execute and verify, and each is a legitimate candidate for enforcement once its shakedown window closes. The new arm reports a label that exists on **both** sides whose colour or description disagrees with its declaration. Two properties make it different in kind:

- **The gate cannot tell a violation from a correct record.** A divergent attribute is either drift or a deliberate operator override made in the web UI, and nothing observable distinguishes them. Reporting it is useful; *failing* on it punishes the correct case.
- **The remedy is not revertible.** Reconciling means overwriting live label metadata. Labels are repository **state**, not repository **content**: reverting the commit that declared a row does not change the label, and no snapshot in the repository holds the prior value.

Under a per-check-id dial, routing this arm through the escalating emitter would mean that any future decision to enforce the *name-keyed* arms — a decision taken for entirely unrelated reasons — would simultaneously make three dozen divergence rows blocking. Nothing at the flip site would signal that, because the flip is a mode file and the arms are not visible from it.

**The corpus was silent on the question.** The readiness protocol that governs warn-to-enforce graduation is written about hooks and about whole checks. Nothing in it addresses adding a finding class to an existing check, so nothing stated which emitter a new arm should take or on what basis.

**And the obvious alternative — say so in a comment — is already demonstrably insufficient.** This same check carries a comment asserting that one of its arms "Never FAILs", sitting directly above a call to the escalating emitter with no mode guard. That comment was true when written. It is false now, and nothing caught the drift, because a comment is not a constraint.

## Decision

**An arm whose finding class must never escalate expresses that by the emitter it calls, not by a mode setting, a default value, or a comment.**

The platform already carries a structurally non-escalating emitter, introduced for a different check whose predicate could not distinguish a violation from a correct record. Its body contains **no branch on any mode and no increment of the failure counter anywhere**. That absence is the guarantee: there is no value to flip, no branch to reach, and no configuration state that changes the outcome. The escalating emitter, by contrast, resolves the check's mode on every call and increments the failure counter in its enforce branch — so an arm routed through it inherits the check's dial whether or not its author intended to.

Concretely, for the arm introduced here:

1. The arm calls the non-escalating emitter, and the call site carries a comment stating **why** — naming the per-check-id resolver as the mechanism and the irreversible remedy as the stake.
2. The class is **excluded from the primitive's exit expression**, so a run whose only finding is divergence still exits clean. The property holds at both layers rather than only at the consumer.
3. The check's shared mode dial is untouched. An operator who later flips the name-keyed arms to enforce gets exactly what they asked for and nothing else.
4. The arm is paired with a **suppression registry**, so it drains to zero once every member of its population carries a recorded disposition. That is what distinguishes a non-escalating arm from a permanent signal stream: it can reach the clean state and stay there.

**When this shape is correct** — all three conditions, not any one:

- the arm's finding class cannot be auto-remediated by the gate, because the gate cannot distinguish a violation from a correct record;
- a bulk remediation would write irreversible state outside version control;
- the check's own posture has been ratified as terminally advisory, or the arm would otherwise contradict a standing ratification.

An arm that fails any of these belongs on the shared dial with its siblings. This is not a licence to make arms advisory whenever enforcement is inconvenient — the emitter choice is a claim about the finding class, and the claim has to be true.

## Decision kernel (version-agnostic)

> Where a check's escalation posture is resolved per check rather than per arm, an arm that must never escalate carries that constraint in the emitter it calls, so the guarantee is a property of the code's shape rather than of a value a later edit could flip. A prose guarantee is not a constraint: the same check already carried a comment promising an arm would never fail, above a call that could. A reader can therefore no longer infer an arm's posture from the check's mode — the emitter call is the authority, and it is greppable.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Route the new arm through the escalating emitter** and rely on the check staying in warn mode | Rejected | The dial is per check id, so this defers the decision to whoever next flips the check for unrelated reasons. It makes an irreversible-remedy class blocking as a side effect of a decision about a different class. |
| Route it through the escalating emitter and **document the constraint in a comment** | Rejected — falsified in place | This check already does exactly that for another arm, and that comment is already false. The failure mode is demonstrated rather than hypothesised. |
| Add a **per-arm mode dial** to the resolver | Rejected — disproportionate | Generalises a resolver every check depends on, for one arm, and multiplies the operator-facing configuration surface. The emitter selection achieves the same guarantee with no new configuration and no new precedence rule to reason about. |
| Give the class a **default-off flag** so it only reports when asked | Rejected | The consuming check is the only caller, so default-off is equivalent to not shipping the class, and reproduces the prior state in which the divergence was surfaced but never gated on. |
| Emit the class from a **separate read-only mode** with the gate path untouched | Rejected | A class no gate consumes cannot discharge the fail-open obligation this release exists to close, and reproduces "surfaced, not fixed" verbatim. |
| Ship the arm **without a suppression registry** | Rejected | Leaves an arm that reports the same rows on every run forever. A non-escalating arm that cannot reach zero is a signal stream, and a signal stream everyone learns to skip is not a gate. The registry is what makes the arm drainable, and is the condition under which advisory-only is defensible rather than merely quiet. |

## Consequences

**An arm's posture is no longer inferable from its check.** A reader who wants to know whether a given arm can block must read the emitter call, not the mode file. This is a real cost and is stated rather than minimised: it trades one uniform rule ("the check's mode decides") for a per-arm fact that has to be looked up. The compensation is that the fact is in the code, is greppable by emitter name, and cannot drift from behaviour — whereas the uniform rule was already being contradicted by a comment nobody had noticed was false.

**The mode file is now an incomplete description of a check's behaviour.** Flipping a check to enforce arms its escalating arms only. Anyone auditing enforcement coverage must enumerate emitters, not checks.

**The non-escalating emitter's caller set grows, and its log line is now visibly over-specific.** That emitter's message hard-codes a pointer to one particular authoritative gate, which was accurate for its founding caller and is not for most of the others. Adding a caller makes that more obviously wrong without making it newly wrong. Not fixed here — the remedy is a judgement about the emitter's contract, not a defect with one obvious repair.

**A suppression registry is now part of the shape, not an optional extra.** An advisory arm ships with the surface that lets its population reach zero. Without it, the arm's honest description is "a permanent stream", and the case for advisory-only collapses into a case for not shipping the class.

**The readiness protocol's gap is named rather than closed.** It still governs hooks and whole checks and says nothing about arms. This record supplies the arm-posture rule; the protocol's own citation surface remains uncorrected and is a separate item.

## Reversibility

**CHEAP / Confidence HIGH** for every change this record governs. The arm, its emitter selection, the registry file and the consumer wiring are all repository content, revertible by reverting the commit. The arm is outside the checks that gate merges, and it cannot move any exit code, so a revert is not time-pressured.

**MODERATE / Confidence HIGH** for the operator-run reconciliation this arm's findings recommend — overwriting live label metadata. It is deliberately outside this release's acceptance criteria: the release lands complete with every divergent row carrying a *recorded disposition*, and nothing requires the disposition to have been *discharged*. The only restoration substrate is an operator-captured live-label listing taken before the edit, and it restores attributes, never issue associations.

**IRREVERSIBLE / Confidence HIGH** for nothing in this record. That separation is the point: the decision ships without authorising any irreversible act.

## Related ADRs

- **ADR-174** — established that a contradiction between two governed surfaces gets its own verdict class rather than being folded into a class with a different remedy, and that a consumer treats an unrecognised class as a finding rather than an absence. This record answers the question ADR-174 leaves open once a class exists: what *posture* the new arm carries, and where that posture lives.
- **ADR-175** — decided how a declared kind projects into the same check's canonical set. It shares this check and this release; the two are independent, and the arm this record governs neither reads nor is read by that projection.
