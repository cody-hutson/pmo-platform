<!-- reference-durability: allow-link -->
---
title: "ADR-186 — The rules mirror has two carriers on two paths, and the deploy script is only one of them"
status: Proposed
date: 2026-09-04
release: rules-mirror-delivered
deciders: Stage 5 Solutioning spoke (four-branch design exploration on the pair-set source; four-surface exploration on the instruction carrier) + Stage 6 Engineering + operator decisions D-D2 / D-E / D-3
tags: [rules-mirror, deploy, composition-surface, context-load, carrier-boundary, ADR-013, ADR-030, ADR-113, ADR-122]
source_observations:
  - "The mirror-sync check verified a directory that nothing in the repository wrote. Its advertised remedy — re-run the deploy to restore — named a command with no code path behind it, so the remedy could not work and had not been noticed because an absent mirror reported as a clean skip."
  - "An absent mirror and a byte-identical mirror produced the same check output. The two states are opposite conclusions and were rendered identically, so no reader could distinguish a synchronised workspace from one that had never been populated."
  - "The deploy script states in its own usage banner that it does not refresh composition surfaces and does not source the composition-surface manifest. Both surfaces that would carry the instruction to read the mirror are registered composition-surface rows, so the content carrier structurally cannot deliver them."
  - "The composition writer wraps every managed section in a BEGIN/END fence and appends an operator-additions section. A fenced target is not byte-identical to its source, and the mirror check's entire invariant is byte-identity — so the two delivery mechanisms are structurally incompatible rather than merely separate."
  - "The pair set was function-local to the check, so the carrier could not read it. The alternative to hoisting was a second declaration, which is the silent desync the mirror-pair-parity contract exists to prevent."
  - "The parity primitive skips a declaration container's own delimiters by name and knows array literals, not heredocs. A heredoc container was measured to make the primitive return UNPARSEABLE, so the container shape is load-bearing on another card's shipped contract."
  - "The workspace charter's operations branch never named the rules directory, so no operations session loaded any of it. The gap was at session altitude: no wording change inside a rule file can reach a session that never loads that file."
supersedes: none
---

# ADR-186 — The rules mirror has two carriers on two paths, and the deploy script is only one of them

## Status

**Proposed** — authored at Stage 6 Engineering for the `rules-mirror-delivered` release; ratification at Collective Review.

**Numbering provenance.** This record was authored at the next free number on this branch. The binding oracle is the mainline anchor plus one; a branch claim is detection-only and never binds. The immediately preceding number is claimed by a sibling record shipping in this same release, so this record takes the next slot rather than duplicating it. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Citations use the slug token `{{ADR:rules-mirror-carrier-boundary}}`, which carries no number shape and resolves at the claim.

## Context

The deployed rules mirror at `<deploy-root>/.claude/rules/` is not tracked in git. It can therefore exist only by being deployed. Nothing deployed it.

The mirror-sync check nonetheless iterated a declared pair set and asserted byte-identity between each in-repo source and its deployed counterpart. On a workspace where the mirror was absent — which was every workspace, since no producer existed — each pair reported a clean `SKIP`. The check printed, passed, and measured nothing. Its remediation text told the operator to re-run the deploy "to restore" a directory the deploy had never created.

Two distinct defects sat inside that one behaviour, and they need separating because they have different fixes.

**The missing producer.** No file in the repository wrote the mirror. This is a content-delivery gap, and its fix is a carrier on the deploy path.

**The missing instruction.** Even a perfectly populated directory reaches a session only because a resolved context file tells the agent to read it. The workspace charter routes platform-engineering sessions to the rules directory and routes operations sessions to a different set that never names it. An operations session bound by those rules would not load them however complete the mirror became. This is a context-resolution gap at **session altitude**, and no edit inside a rule file can close it — a rule the session never loads cannot instruct the session to load itself.

Treating these as one problem produces a design that ships bytes nobody reads.

## Decision

**The rules mirror has two carriers, on two delivery paths, and they are not interchangeable.**

**Carrier 1 — content, on the deploy path.** A producer in the deploy script lays the mirror down from the single pair-set declaration, verifying each copy with a byte-identity check and routing any failure into the deploy's terminal failure array. It runs **before** the deploy's no-changes early exit, because the mirror is not a function of the skill, package, or harness change sets and must not be gated on them; gating it there would make the never-populated state unreachable by the exact command the check's own remediation prints.

**Carrier 2 — instruction, on the composition surface.** The charter's operations routing branch and the operations context anchor each gain a load step naming the mirror. These are `.template` sources delivered by the workspace update path, never by the deploy script.

**The pair set is declared once and read twice.** The declaration is hoisted out of the check into a top-level pure emitter that both the check and the carrier read. No second list is created. The declaration gains a third field carrying an operations class per member; the classification rides on the declaration rather than in a parallel list, so it cannot drift from the set it annotates.

**Membership is expressed only by that declaration.** The carrier copies the declared set and performs no directory recursion. A recursive copy would restore payload the admission standard removed while the declaration still read compliant.

**The subset an operations session loads is defined by a criterion, not an enumeration.** The criterion has one home; the current members are listed in an index generated from the declaration on every deploy. Neither context file enumerates members or states a count.

**The check distinguishes five states** rather than two, discriminating "never deployed anything here" from "deployed, but the mirror is missing" using a signal every deploy writes independently of any session. The former withholds its verdict through an emitter that structurally cannot move the exit code; the latter is a finding.

## Options considered

**For the pair-set source.** (a) Hoist to one emitter read by both callers — **selected**; no new holder, nothing to desync. (b) Let the carrier declare its own copy set — rejected: it is exactly the silent desync the parity contract exists to prevent, and "a check catches it" is a mitigation for a defect you chose to create. (c) Derive the set from a glob over the rules directory — rejected: a predicate rather than a list, it silently over-copies the moment a member is removed from the set while its file remains. (d) Parse the marker region out of the script's own source at runtime — rejected on maintainability; a script that reads its own text to find its data must locate itself and couples the deploy hot path to marker parsing.

**For the instruction carrier.** (a) The charter's operations routing branch — **selected as authoritative**; the instruction lands at the exact site of the gap. (b) The operations context anchor — **selected as pointer**; the charter alone leaves the root class the anchor exists to serve uncovered. (c) The program governance file — rejected: one hop further from the resolution layer, and agent-unwritable, so it would be operator-executed for no reach gain.

**For the declaration container.** An array literal, not a heredoc — **forced by measurement**, not preference. The parity primitive skips a container's delimiters by name and knows array literals; a heredoc body makes it parse the terminator as an entry and return UNPARSEABLE. Keeping the literal is what let the hoist land with zero change to that primitive.

## Consequences

**The mirror's payload is bounded by the declared set.** The carrier has no recursion and no glob, so payload changes require a declaration edit, which the parity check and the admission budget both see.

**The deploy script remains the sole byte-identical content carrier and never touches the composition surface.** This preserves the separation the platform already relies on: content delivery is byte-identical by contract, while composition wraps managed sections in fences and cannot be byte-identical by construction.

**A release that edits a context-file template owes a second command at execution.** Running only the deploy ships the mirror without the instruction to read it. This obligation is recorded as an execution-stage convention with an explicit statement that **no automated detection backstop exists** for the class — unlike the references-only convention, which has a check behind it. The manifest row is the only control, so it is not optional. Closing that detection gap is deferred, and naming the absence is what keeps it countable rather than invisible.

**The check gains a failing state it structurally did not have.** A workspace whose mirror was never populated can now return a non-zero issue count where it previously returned clean. On a tree that has never been deployed the verdict is withheld instead, and the non-escalation is a property of the emitter's shape rather than a default a later edit could flip.

**A failed mirror copy now fails the whole deploy.** This failure class did not previously exist. It is deliberate: a silently-partial mirror is the state the new verdict semantics exist to make impossible.

**The first populated mirror changes what every subsequent session loads at start.** Reversibility is **CHEAP** with **HIGH** confidence — re-running the deploy from reverted sources restores the prior content — but the effect is observable immediately, and reverting the source alone does not un-populate the directory. Repopulation is a second, operator-run action.
