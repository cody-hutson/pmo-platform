<!-- reference-durability: allow-link -->
---
title: ADR-126 — The sub-task status mirror stays a point-in-time snapshot, and label materialization gets a read-only emit path rather than an automated one
status: Accepted
date: 2026-08-07
release: methodology-fields-and-statuses
deciders: "Workspace owner (the non-resync decision ratified at the Stage-5 wave-1 gate; the extended apply-set ratified at the wave-2 gate); designed at Stage 5 Solutioning, authored at Stage 6 Engineering"
tags: [architecture, labels, taxonomy, lifecycle, sub-tasks, tooling, deploy-checks, single-source-of-truth, reversibility-mixed]
source_observations:
  - "The originating card's acceptance criterion required the sub-task status mirror to resync on later parent transitions. The label grammar's own composition rule states the opposite in its own text — the mirror is a point-in-time snapshot taken at creation and deliberately not auto-resynced. The criterion and the ratified grammar were in direct contradiction, so one of them had to give."
  - "A whole-corpus probe over executable files found ZERO behavioral sites that read a sub-task's status VALUE. The denominator is 8 files referencing sub-tasks in code; the three places where sub-task and status co-occur are one explanatory comment, a set of test-fixture rows, and an invariant check that uses the sub-task marker as an EXCLUSION filter rather than reading the value it would resync. The sensitivity arm is non-zero — 21 files do read a status value — so the zero is a real absence rather than a stuck probe."
  - "The milestone carrying this decision holds 22 sub-tasks. A resync obligation would rewrite that population on every parent transition, to maintain a field with no reader."
  - "The card reported two declared status rows as absent from the live label set. At build time only one was absent; the other had become live carrying GitHub's default grey and a null description — the signature of a create that passed neither a colour nor a description."
  - "The issue-event history of an unrelated concurrent release shows that row being applied to a work item roughly eighteen minutes before the build-time probe, by a sibling release performing exactly the Stage-6 transition the card reports as never firing. The label did not exist at the card's own re-probe the previous day. The correlation is exact: the one declared-but-unmaterialized status row that became live is the one that got applied to an issue."
  - "A corpus-wide search for a label-creation call returns zero occurrences, against a sensitivity arm of five files that call the label command in read-only list form. There is no governed materialization path; the ungoverned one is a side effect of application."
  - "The parity gate compares label NAMES only. At the build-time baseline, of 34 declared rows that were live, only 2 matched their declaration on both colour and description. A green gate is therefore evidence about names alone, and the malformed-row class it cannot see is large rather than incidental."
---

# ADR-126 — The sub-task status mirror stays a point-in-time snapshot, and label materialization gets a read-only emit path rather than an automated one

## Status

**Accepted.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent.

**Numbering.** This record's number is the mainline anchor plus one, where the anchor already includes this release's two earlier records, derived at build time per the rule the numbering ADR ratifies. At that moment **four** sibling branches held unmerged claims on a number below this one and two of them also held the number directly below it; **no branch held this one**. Those claims are *advisory* and do not bind the sequence. A reservation strictly above every sibling claim was considered and rejected on that ADR's own ground — a gap blocks the repository where a duplicate merely inconveniences one branch — and the rejection was verified against the enforcing predicate rather than argued from the document, with three arms: this number returns **PASS** on a contiguous `001..122` with no gaps and no duplicates; the reserved slot one higher returns **FAIL — GAP**, naming the number it skipped; and a deliberate collision on an already-taken number is **detected**, which is what makes the PASS meaningful rather than blind. An earlier hub ruling directed allocation from one number higher on the premise that three siblings needed three reserved slots; that premise was falsified at build time — the two numbers below this one were taken by *this release's own* earlier cards, not by siblings, and the siblings pile on a single lower number that no reservation strategy resolves. If a sibling merges first, this record renumbers at merge time by the sanctioned tool and this section gains a numbering-provenance note.

**Numbering provenance — `122 → 126`.** Held **ADR-122** branch-local; renumbered to **ADR-126** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 122. In-release citations that read "ADR-122" denote this record.

## Context

The originating card reported one symptom with two layers: two declared pipeline status rows had no live counterpart, and no observable step advanced a work item's status when engineering began. It carried an acceptance criterion requiring a third thing — that a sub-task's mirrored status resync when its parent transitions.

**The resync criterion contradicted ratified governance in the same breath.** The label grammar's composition rule for sub-tasks states, in its own text, that the mirror is a point-in-time snapshot taken at creation and is *deliberately* not auto-resynced. The criterion asked the release to build precisely what the grammar declares it will not do. That is not a gap to close; it is a disagreement to settle.

**The materialization layer was misdiagnosed, and the correction matters more than the card.** Four candidate root causes were handed down — the gate is not run, not enforcing, not covering the status group, or the scaffolding is broken. All four are false. Detection already works: the gate reported both rows, and the card was *filed from that output*. Enforcement mode is not the cause either, because a check that cannot create a label cannot clear a MISSING it reports — escalating it converts a silent warning into a permanent red and moves nothing. A corpus-wide search for a label-creation call returns **zero** occurrences against a non-zero sensitivity arm. **The declared-to-live step has no owner and no implementation.**

**And the build-time state was not what the card described.** Only one of the two rows was absent. The other had become live — carrying the default grey and a null description, the signature of a create given neither. The provenance resolved during this build: the issue-event history of a concurrent sibling release shows that row being applied to a work item minutes earlier, by a release performing exactly the Stage-6 transition this card reports as never firing. The row did not exist at the card's own re-probe the previous day.

Three conclusions follow, and they reframe the card. First, **the transition does fire** — it fired in a sibling release while this one was being built, so the card's behavioural claim is true of one milestone and not of the pipeline. Second, **there is an ungoverned materialization path**: applying an unrecognized label brings it into existence malformed. Third, and most consequential, **the parity gate cannot see the result**, because its diff compares names only. Of 34 declared rows that were live at the baseline, **2** matched their declaration on both colour and description. The malformed-row class is not an edge case; it is nearly the whole surface.

## Decision

**(1) The sub-task status mirror is not resynced, and the grammar rule is not amended.**

The composition rule stands byte-unchanged. The mirror remains what it says it is: a hygiene snapshot of the parent's lifecycle position at creation, for board and query legibility, and not an invariant-enforced field.

The decisive evidence is that **the field has no reader.** A probe over every executable file in the corpus found **zero** behavioural sites that read a sub-task's status *value*. The three places where the two concepts co-occur are an explanatory comment, a set of test fixtures, and an invariant check that uses the sub-task marker as an **exclusion filter** — it asks *is this a sub-task?* in order to skip it, and never reads the value a resync would maintain. The sensitivity arm is non-zero, so this is a measured absence rather than a stuck probe.

Against that zero stands a real cost. The milestone carrying this decision holds **22** sub-tasks; a resync obligation rewrites that population on every parent transition. **Maintaining a field that nothing reads, at a cost that scales with every release, is the definition of ceremony.** The originating criterion is therefore graded **satisfied by intent**: the intent was observability of actively-engineered work, and that is delivered by the parent's own status row — now materialized — not by propagating a copy to children no consumer inspects.

The honest counter is recorded rather than suppressed: a *future* consumer might want a child-level status, and this decision makes that consumer's arrival more expensive. That trade is accepted because the reverse error is worse — a maintained-but-unread field drifts silently, and drift discovered later is more expensive than a resync built later, on demand, by whoever actually needs it.

**(2) Materialization gets a read-only emit path, deliberately not an automated one.**

The parity primitive gains an `--emit-fix` flag that **renders** the reconciling label commands and **runs none of them**. It is a separate boolean flag rather than an output-format value, because the deploy path pins the output format and parses that shape; adding a value there would have broken the gate it was meant to serve.

Automation was rejected on a property of the object rather than on caution. **A label is repository *state*, not repository *content*.** Every other artifact this pipeline produces is a file, and a revert of the merge undoes it. A created label survives that revert, and any work item that acquired it keeps it. An automated creator would therefore mint state inside a pipeline whose entire rollback story assumes content — so materialization stays an operator action with an auditable diff, and the rollback obligation is named explicitly at the release record rather than presumed git-native.

**(3) The emit path reconciles as well as creates — because create-only would have left the defect standing.**

This is the decision most easily got wrong, and the build produced its own counter-example. Had the emit path only created absent rows, it would have run to completion, reported success, and left the malformed row exactly as it found it — a row whose name is right and whose every other field is wrong, invisible to the name-only diff. The emit path therefore classifies into three buckets: **create** (declared, absent), **reconcile** (live, diverged), and **unresolvable** (declared with no colour — not emittable, because a colourless create takes the default grey and *reproduces the very shape being repaired*).

The two blocks are rendered separately and the reconcile block carries a review warning, because the asymmetry is real: creating an absent row is additive, whereas rewriting a live row's metadata may overwrite a deliberate operator override. **The gate cannot distinguish an override from drift, so a human decides per row.** This release applies the ratified subset and leaves the remainder surfaced rather than swept.

**(4) The transition is not restated; its precondition is.**

The Stage-6 status transition is already codified — the edge and its actor in the ticket-architecture transition table, the paired add-and-remove mechanism in the same file's agent-actions table, and the stage claim step in the stage spec. Authoring another copy was declined: a restatement is a drift target that outlives the release that wrote it.

What no surface asserted is the **precondition** they all assume — *a transition can only apply a label that exists*. That is the genuinely absent rule, and it is what the governance edits state, at the two surfaces where the assumption is actually made: the release process's Stage-6 section, and the scaffolding step that pastes a parent's status label into a create call. Both cite the mechanism rather than repeating it.

## Alternatives Considered

**On the resync criterion:**

| Option | Verdict | Why |
|---|---|---|
| Amend the grammar rule and build the resync | **Rejected** | Reverses a ratified design decision to satisfy a criterion written without knowledge of it, and buys a per-transition rewrite of a 22-item population to maintain a field with zero measured readers. |
| Build the resync without amending the rule | **Rejected — incoherent** | Ships behaviour the grammar explicitly disclaims. The next reader cannot tell which surface is authoritative, which is worse than either choice made cleanly. |
| **Leave the rule untouched; record the decision; grade the criterion satisfied-by-intent** | **SELECTED** | The intent is observability of active work, which the parent's now-materialized row delivers directly. The criterion's literal form was an implementation guess, not the requirement. |

**On materialization:**

| Option | Verdict | Why |
|---|---|---|
| Automate creation inside the deploy path | **Rejected** | Mints repository state from a pipeline whose rollback model assumes content. A revert would not undo it, and the failure mode is silent accumulation. |
| Escalate the gate to enforce and let red block | **Rejected** | A check that cannot create a label cannot clear the finding it raises. This converts a silent warning into a permanent red without materializing anything — motion, not progress. |
| Create the rows by hand this release and write no tool | **Rejected** | Fixes today's instance and leaves the class open. The next declared row repeats the defect, and the malformed-row class stays invisible. |
| **Read-only emit path; operator runs the commands** | **SELECTED** | Closes the class, keeps state creation deliberate and auditable, and needs no new enforcement mode. |

**On the emit path's scope:**

| Option | Verdict | Why |
|---|---|---|
| Emit creates only | **Rejected — falsified in this build** | Would have left the malformed row standing while reporting success, which is the exact failure the card exists to end. |
| Emit creates and reconciles as one undifferentiated block | **Rejected** | Invites a mass overwrite of live metadata that may encode deliberate overrides. The blast radius at baseline was 32 rows. |
| Widen the gate's own diff to compare colour and description | **Rejected — out of matrix** | Changes what an existing green check means, on a surface the release plan records as already correct. Routed as a follow-on instead. |
| **Emit both, in separate blocks, with the reconcile block warned** | **SELECTED** | Surfaces the whole truth while keeping the safe half runnable on its own. |

## Consequences

**Easier.** A declared label row now has a defined route to existence, and the route is inspectable before it runs. The malformed-row class becomes *visible* for the first time — it was always there, and nothing could see it. A release that depends on a status transition can check its precondition instead of discovering it.

**Harder, stated plainly.** **The parity gate still compares names only.** This record does not change that, and a green Check 51 remains evidence about names alone. The colour and description surface is reported by the emit path and enforced by nothing — a deliberate scope boundary, not an oversight, and it will stay open until the follow-on lands. Anyone reading a green gate as *the label set matches its declarations* will be wrong, and this paragraph exists so that misreading has somewhere to be corrected.

**A residual this release does not close.** The ungoverned creation path — application bringing an unknown label into existence malformed — remains open. Nothing here prevents it; the emit path only repairs the result. Preventing it would require validating labels at the point of application, which is a different surface and a different card.

**A second-order effect worth naming.** Two cards in this release resolve to the same diagnosis: **specification without binding.** One found a state machine whose named advancer is unwired; this one found a label declaration with no materializer, and a gate that reports the gap it cannot close. That the shape recurs across independently-filed cards is a signal about the corpus rather than about either card. It is recorded as an observation, not legislated into a rule by this record.

**Not changed.** The sub-task composition rule is byte-untouched. The gate's MISSING/ORPHAN verdict logic, its existing parsers, and their fixtures are byte-untouched — the new row parser and the classifier are siblings, added alongside. No output format changes, so the deploy path's parse is unaffected. No pack file, no skill file, and no deploy script is edited.

## Reversibility

**MIXED — and the split is the point.** Confidence **HIGH**.

The **corpus half is CHEAP**: four markdown and code surfaces plus this record, all additive. No file renamed, moved, or deleted; no heading removed; no existing function signature changed; no schema version bumped; no skill package rebuilt. A single revert of the merge restores every one of them.

The **live half is not reversible by git at all.** Materialization created labels in the repository, and a revert does not delete them. Removal is a separate manual operation, and the order matters: **revert the merge first, then delete the labels** — reverting first restores the gate to its pre-release state so it does not immediately re-flag the deletion as fresh drift. Any work item that acquired one of these labels keeps it until edited. The reconciled row is a further asymmetry: its previous colour and description were the default grey and null, so "reverting" it means re-introducing a malformed row, which no one should want — in practice that row is **forward-only**.

This asymmetry is the concrete reason Decision (2) refused to automate creation. A pipeline whose rollback story is *revert the merge* must not be allowed to mint state that the merge does not own.

## Related ADRs

| ADR | Relationship |
|---|---|
| **ADR-018** | The work-item-type layer that owns the base lifecycle machine the status labels project. This record touches the label surface only and re-founds nothing. |
| **ADR-062** | Canonical-spec-edit-wins. Applied twice here: the originating card's resync criterion lost to the ratified grammar rule, and its body was left as a historical record rather than amended. |
| **ADR-069** | The methodology pack as the composing unit — the packs are where the declared rows this emit path materializes actually live. |
| **ADR-070** | The pack composition grammar and its label-contribution facet. The emit path is group-agnostic by construction, so it materializes any contributed row without knowing which group it belongs to. |
| **ADR-092** | The version-identity decision governing the release this record ships in — slug-primary in flight, version bound at the atomic claim. |
| **ADR-115** | The ADR-number binding rule this record's numbering follows, and whose rejection of reserving a slot above unmerged sibling claims § Status applies and verifies against the enforcing predicate. |
| **ADR-124** | This release's first record, the Axis-1 work-status label surface. Its six declared rows were materialized by the emit path this record decides — the two cards meet at exactly one point, and it is that apply-set. |
| **ADR-125** | This release's second record. Its closing observation and this one's are the same finding reached independently from two cards: the platform specifies obligations without a gate that verifies an actor is wired to them. |
