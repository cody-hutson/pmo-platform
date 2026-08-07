<!-- reference-durability: allow-link -->
---
title: ADR-120 — The Axis-1 delivery work-status label surface is its own grammar group with its own name prefix, homed in the shared base pack, and blocked is not one of its values
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-07
release: methodology-fields-and-statuses
deciders: "Workspace owner (premise rejection and row home ratified at the Stage-5 wave-2 gate; group and prefix ratified at the same gate); designed at Stage 5 Solutioning, authored at Stage 6 Engineering"
tags: [architecture, labels, taxonomy, methodology-packs, work-item, lifecycle, grammar, single-source-of-truth, reversibility-cheap]
source_observations:
  - "The generic Axis-1 delivery state machine has shipped at the entity layer, with a closed enum and a negative test, and the field name it would be surfaced under returned zero occurrences across the whole tracked corpus at the release baseline. The concept appears in 43 places; not one of them defines a field, a value list, or a label surface."
  - "The status-label invariant check discriminates by the `status: ` NAME PREFIX at five sites in the deploy script, and reads a pack's grammar `group` field at zero sites. A subject probe returned 5 prefix matches and 0 group reads over the same file, so the zero is a real absence rather than an empty extraction."
  - "The label grammar states that each group definition carries its own cardinality rule, and the status group's rule is the one-status-label mutex. Filing a second value domain under that group inherits its mutex."
  - "Five ratified statements across two pack-composition decision records home the Axis-1 work-status base projection in the shared base pack, and the release plan that CREATED that file scoped it to `Axis-1 work-status, priority, universal labels`. A whole-corpus read of every case-insensitive occurrence found zero statements homing the base projection in an archetype pack; both control arms of that probe discriminated on a non-empty population."
  - "Every prohibition in the corpus is scoped to the state MACHINE — the pack meta-schema says a pack must not declare a pack-level work-status machine, the packs README says no work-status machine, and the base pack's own header said no work-status block. Every homing statement names the base pack. The originating card conflated the prohibited machine with the explicitly-permitted projection."
  - "The card's own acceptance criteria were mutually unsatisfiable as written: one pinned the values to the entity enum verbatim, which makes them archetype-invariant by construction, and another pinned the contribution home to the archetype packs, which is the delta surface. Honouring both writes an identical row set into every declared archetype."
  - "The RAID entity faced the same flag-versus-state question and the corpus already ruled it: a legacy escalated value was crosswalked to a lifecycle state plus an orthogonal escalation condition, recorded explicitly as `not a state`, with a negative test pinning it."
  - "The two value domains share the tokens for active work and for completion, and the GitHub label namespace is flat. Two cards in one release were about to contribute rows into that shared namespace."
---

# ADR-120 — The Axis-1 delivery work-status label surface is its own grammar group with its own name prefix, homed in the shared base pack, and blocked is not one of its values

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number is `anchor(mainline) + 1`, derived at Engineering Commit 0 against the mainline anchor, per the rule ADR-115 ratifies. At that instant three sibling branches held unmerged claims on this same number and one of them also held the next. Those claims are **advisory** and do not bind the sequence. A reservation strictly above them was considered and rejected: it lands a multi-number hole, and the contiguity gate fails a gap exactly as readily as a duplicate — a duplicate inconveniences one branch, a gap blocks the repository. The rejection is not theoretical here; the gate was run against both candidates at Commit 0 and returned FAIL-on-gap for the reserved number and PASS for this one, with a duplicate control arm confirming the gate is not gap-only. If a sibling merges first, this record renumbers at merge time by the sanctioned tool, and this section gains a numbering-provenance note.

## Context

The platform ships a generic Axis-1 delivery state machine at the entity layer — a closed enum with a negative test, inherited by every work-item kind. It has never had a **surface**. There is no field definition, no documented boundary against the release-pipeline status axis, and no label projection, so an operator asking *where is this work right now* has no answer that is not issue archaeology.

Adding that surface looks like a one-line pack contribution and is not, because three separate things collide at once.

**First, the label namespace is flat and the two axes overlap.** The delivery enum and the release-pipeline status set genuinely share the tokens for active work and for completion. GitHub has one namespace for labels; there is no scoping. Two cards in the same release were about to contribute rows into that namespace against the same two names.

**Second — and this is the half that is easy to miss — the invariant that would catch the collision does not discriminate the way the grammar does.** The status-label invariant check selects labels by their **name prefix**. It reads a pack's grammar `group` field nowhere. So the grammar group and the runtime behaviour are decoupled: a row can be filed under a perfectly correct new group and still trip the one-status-label mutex on every issue in the repository, because the check never looks at the group. A naming decision that reads as cosmetic is therefore load-bearing, and independently so from the group decision.

**Third, the originating card's homing premise was wrong, and its own acceptance criteria contradicted each other.** The card asserted that the shared base pack "cannot host" these rows, citing that pack's own header note. But every *prohibition* in the corpus is scoped to the state **machine** — a pack must not declare a pack-level work-status machine, must not re-found the base — while every *homing* statement points at the base pack for the work-status **projection**, including the release plan that created the file. Machine and projection are different objects: a pack projects labels over the base, it does not re-found it. The card conflated them. And its criteria could not both be satisfied: pinning the values to the entity enum verbatim makes them archetype-invariant by construction, which is precisely what the base pack exists to carry, while pinning the home to the archetype packs puts a shared base into the delta surface and duplicates one invariant enum once per declared archetype.

Underneath all three is one question: **is the delivery axis a variation of the pipeline axis, or a second axis entirely?** Everything else follows from the answer.

## Decision

**(1) Delivery work-status is a distinct label group, `work-status`, defined by the grammar.**

It is not a reuse of the pipeline status group. A group definition carries its own cardinality rule, and the status group's rule **is** the one-status-label mutex — so filing Axis-1 rows there would make the two axes mutually exclusive, which is the exact inverse of the distinction this work exists to create. Escaping that would require amending the status group's rule with a second-family carve-out, which is a grammar change performed worse: it buys none of the clarity and leaves one group owning two value domains under a single rule that can be correct for only one of them.

The new group carries its own cardinality rule, orthogonal to and composing with the status rule. Neither group constrains the other; an item may carry one label from each. Absence of a work-status label is **not** a violation — the rule asserts mutual exclusivity within the group, never presence.

The grammar defines the group; the pack populates it. The contract direction in the existing label-grammar clause — *the grammar defines the groups; a pack only populates them and may never define a new group or rule* — is preserved exactly and its text is untouched.

**(2) The rows carry a `work-status: ` name prefix, and that prefix is a mechanism, not a convention.**

Both halves are required and neither substitutes for the other. The **group** is the documentation contract; the **prefix** is the runtime contract. Because the status-label invariant check matches on the name prefix and never reads the group, a row named under the `status: ` prefix would trip the mutex release-wide no matter which group it declared — and, symmetrically, a correct group with a colliding name buys nothing at runtime. The chosen prefix sits outside the check's match by construction, which is the whole point of choosing it.

The consequence is binding on future work: **renaming these rows into any `status: `-prefixed form is a release-wide regression, not a cosmetic change.** That sentence is the reason this ADR exists rather than an inline comment.

**(3) The concrete rows are contributed by the shared base pack as the shared base projection; both archetype packs stay untouched.**

This reverses the originating card's stated home and amends the acceptance criterion that encoded it. The basis is the pack-composition grammar's own division of labour: the base pack carries the shared base projection, and archetype packs carry only their sub-state deltas. The values are the entity enum verbatim, so the sub-state delta is empty — there is, by construction, nothing for an archetype pack to declare. Homing them in the delta surface would duplicate one invariant enum once per declared archetype and turn any future enum change into a cascade across every one of them.

The base pack's header note is **reconciled in the same edit**, not annotated around: it correctly said the pack declares no work-status *machine*, and it now also says the archetype-invariant work-status *label projection* is carried there. Leaving the note as-is while adding the rows would have left the file reading as its own contradiction.

**(4) `blocked` is a derived condition of an unsatisfied dependency edge — neither an Axis-1 state nor a work-status row. This decision ships no blocked artifact.**

It cannot be an Axis-1 **state**: the enum is closed at the entity layer with a negative test, and a pack extending it would re-found a machine the meta-schema forbids packs from re-founding. It cannot be a **row** in this group either: the group's rule is one-per-item, so an item would have to be *either* blocked *or* in progress — the precise conflation the originating card's own assumption identified when it observed that a blocked item still occupies a lifecycle state.

It does not need to be either, because the platform already carries the fact. Blocking relationships are declared in the packs' allowed relationship types and mirrored natively, and the dependency entity carries its own lifecycle. Storing blocked-ness as a value or a field would be a **second source of truth** for a fact the edge already holds — one that drifts the moment the edge is satisfied and the flag is not cleared.

The corpus has ruled this exact shape once already: a legacy escalated value on the RAID entity was crosswalked to a lifecycle state **plus an orthogonal escalation condition**, recorded explicitly as *not a state*. Blocked is to the delivery axis what escalated was to that one.

**Nothing is dropped.** The originating card's guard — *do not silently drop the capability* — is honoured by observing that the capability was never missing. Should a surfaced, filterable blocked marker later be wanted, its home is pre-registered: the cross-cutting control facet, which exists for exactly this shape of orthogonal, filterable, gate-readable dimension. Pre-registering it costs nothing now and prevents the question being re-litigated from scratch later.

## Alternatives Considered

Six candidates were generated for the group question and narrowed to three before scoring; the narrowed-out three are recorded because each is the obvious first idea for a different reader.

| Option | Verdict | Why |
|---|---|---|
| **Reuse the `status` group with a distinguishing name prefix** | **Rejected** | The apparent saving — "no grammar change" — is illusory. The group's cardinality rule *is* the mutex, so reuse either inherits a rule that makes the two axes mutually exclusive, or forces an amendment to the highest-traffic clause in the grammar. That is a grammar change done worse, and it leaves one group permanently owning two value domains. |
| **A Projects single-select field only, with no labels at all** | **Rejected** | The only zero-grammar-change option, and scored honestly for that reason. It fails the pack-contribution criterion outright, and it puts the delivery axis on a surface the parity gate cannot reconcile. |
| **Rename the pipeline `status:*` family and give the delivery axis the `status: ` prefix** | **Rejected at narrowing** | Renames a live label family across the open backlog and every corpus read-site, and re-opens a deliberately-kept invariant, for zero capability gain. |
| **File the rows under the `category` group with a registered namespace** | **Rejected at narrowing** | The category group classifies what an issue *is*, under a one-per-issue rule. Work-status answers where the work *is*. A literal category error. |
| **Define the group as a namespace pattern only, with no concrete rows** | **Rejected at narrowing** | The value set is closed and fixed by the entity enum — the opposite of the open-ended families that motivated the namespace-pattern form. It also makes the rows permanently unmaterializable, because a parity gate cannot report a missing row for a group that enumerates none. |
| **Add `blocked` to the Axis-1 enum, or ship it as a row in this group** | **Rejected** | Recorded in Decision (4): the first re-founds a closed entity-layer machine; the second forces a false choice between two facts that are simultaneously true. |
| **Home the rows in the archetype packs (the originating card's stated home)** | **Rejected, and this is the reversal** | Recorded in Decision (3): it inverts the base/delta division, contradicts the file's founding scope, and duplicates one invariant enum per declared archetype. Fully specified as a fallback at design time so the work was unblocked either way; the operator ratified the reversal. |

## Consequences

**Positive.**

- The two-axis boundary is documented for the first time, with the token collision named rather than latent, and with the mechanical separator installed rather than assumed.
- One value domain, one home, one editable enum. A future change to the delivery enum is a two-file edit — the entity layer and its single projection — rather than a cascade across every declared archetype.
- The group scales to every declared archetype with **no further rows**, because the base machine is archetype-invariant. An archetype that genuinely needs sub-states adds only its delta, which is what the pack grammar already provides for.
- The parity gate needs no change: its parser is group-blind, keying on label name alone, so the new rows are discovered by the same path that discovers every existing one. This was verified rather than assumed.
- The blocked question is closed with a recorded answer and a pre-registered home, so it does not return as an open assumption on the next card that touches this surface.

**Negative, and named rather than hidden.**

- The new group's cardinality rule is **documentation-only** in the release that introduces it. The status-label invariant check lives in a file this release deliberately excludes from its change set, so no invariant asserts work-status mutual exclusivity or presence. A sibling invariant is the obvious follow-on; until it lands, the rule binds authors and reviewers, not the gate.
- The rows land **declared**, not live. Declaration and materialization are different acts, and materialization is a sibling card's surface. Absent that card extending its apply set, this change would *widen* the declared-versus-live gap rather than close it. The apply set was extended for exactly this reason.
- Rollback of the declaration is git-native, but rollback **after** materialization is not: labels are repository state, not repository content, and a revert cannot remove them.
- Board colours are reused from the pipeline lifecycle palette, so a reader distinguishes the two axes by **prefix**, not by colour. That is the intended design — the prefix is the separator — but it is stated here rather than left as a surprise on first sight of a board.
- Every row must carry a colour. This is not a style rule: the sibling materialization path skips a colourless row and reports it unresolved, so a colourless row would be unmaterializable through the exact path that is supposed to create it.

## Reversibility

**CHEAP.** Confidence **HIGH**.

The change is additive and section-local across a small set of markdown and configuration files: a new group section, one new composition rule, a handful of count-and-enumeration cascade updates, two enum-row updates, and one additive block of pack rows. No file is renamed, moved, or deleted; no heading is removed; no code path changes; no schema version bumps; no skill package rebuilds. A single revert of the merge restores every surface this decision touches.

The one asymmetry worth naming: **once the rows are materialized as live labels, revert stops being complete**, because label deletion is repository-settings mutation rather than repository content. That step is operator-run and out-of-band, and it must be named in the release's rollback record rather than assumed to ride along with the revert.

## Related ADRs

| ADR | Relationship |
|---|---|
| **ADR-018** | The establishing work-item-type decision — the thin entity plus declarative type layer, and the entity layer's ownership of the Axis-1 base machine that packs project over. This record is an instance of that ownership, not a competitor to it. |
| **ADR-069** | The methodology pack as the plug-and-play composing unit. Names the shared base pack as the carrier of the generic Axis-1 work-status base, and states the machine-versus-projection distinction in a single sentence — packs project labels over the base, they do not re-found it. The direct basis for Decision (3). |
| **ADR-070** | The pack composition grammar — the grammar-altitude sibling of ADR-069. Its label-contribution facet is the mechanism Decision (3) uses, and its base-carries-the-shared-projection / archetypes-carry-only-deltas division is the rule Decision (3) applies. This record extends ADR-070 at instance altitude and supersedes nothing. |
| **ADR-077** | The cross-cutting control field layer — the pre-registered home for a surfaced blocked marker should one later be wanted, per Decision (4). |
| **ADR-115** | The ADR-number binding rule this record's numbering follows, and whose rejection of reserving a slot above unmerged sibling claims this record's § Status applies directly. |
| **ADR-092** | The version-identity decision governing the release this record ships in — slug-primary in flight, version bound at the atomic claim. |
