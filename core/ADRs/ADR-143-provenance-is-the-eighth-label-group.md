<!-- reference-durability: allow-link -->
---
title: "ADR-143 — Provenance is the eighth label group: how a work item entered the tracker is its own axis"
status: Accepted
date: 2026-08-27
release: ci-stable-under-transient-conditions
deciders: "Stage 5 Solutioning spoke (six-option group analysis) + Collective Review (scope-lock; the label-grammar conditional was ratified as FIRING) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [label-taxonomy, label-grammar, label-parity, provenance, auto-promotion, pattern-detection, methodology-packs, ADR-018, ADR-070]
source_observations:
  - "A machine-applied label had been named in a pipeline stage spec for the auto-promotion path, but was declared in no pack and existed in no live label set — so the promotion path it gated could not have succeeded even once."
  - "The label grammar declared its group set closed at seven. Every one of the seven was tested against the row and each failed for a different, load-bearing reason — so the row had no lawful home at all, not merely an awkward one."
  - "The Category group was disqualified by the one-category-label rule: the filing mechanism already applies a category label at creation, so a second category label on the same issue violates the grammar's first rule."
  - "The Triage Flag group was structurally disqualified rather than stylistically: its group definition and the removal rule both mandate removal once triage executes, while a downstream schema-maintenance trigger counts this label on CLOSED issues in a trailing window. Homing the row there would have left that trigger unable to fire, and nothing would have reported the silence."
  - "The Disposition group would have parsed cleanly and written a false definition: dispositions are final triage decisions rendered by a human, and this marker is applied by a machine at creation, before any triage has occurred."
  - "The parity engine's row parser collects only name, colour and description, and states inline that group is a documentation facet with no live GitHub counterpart. Adding an eighth group value therefore changes no automated verdict anywhere — the automation risk of opening the closed set is zero, which is what made the honest option also the cheap one."
  - "The grammar doc forbids a pack from defining a new group or rule, so the group definition had to land in the grammar and the concrete row in the pack. The two edits are not substitutes; either alone leaves the row either homeless or ungoverned."
---

# ADR-143 — Provenance is the eighth label group

## Status

**Accepted.** Authored at Engineering for the `ci-stable-under-transient-conditions` release, against the Collective Review scope-lock that ratified the label-grammar conditional as FIRING.

## Context

The label grammar states that the taxonomy's group set is closed, and enumerates it: Category, Status, Work-Status, Cluster, Initiative, Triage Flag, Disposition. Each group definition fixes a *purpose*, a *cardinality rule*, and a *lifecycle role*, and the composition rules constrain any live label set against them. Concrete rows are contributed by the methodology packs; the grammar owns the groups, and a pack "may never define a new group or rule."

A mechanism in the release pipeline files issues automatically: when a cross-release pattern detector finds a keyword cluster recurring above a threshold, it opens a work item and labels it as machine-filed. That machine-filed marker had been named in a stage spec's prose but had never been declared as a row anywhere, and never existed in the live label set.

Declaring it forced a question the grammar had not been asked before: **which group does a label belong to when it records neither what an item *is*, nor where it *sits*, nor what was *decided* about it — but how it *arrived*?**

Every existing group was tested. None admits the row:

- **Category** answers *what an issue is*. The filing mechanism already applies a category label at creation, so adding a second one violates the one-category-label rule directly.
- **Cluster** answers *which domain an issue belongs to*, is bounded to one domain per issue, and is namespaced. An origin marker is not a domain.
- **Status** and **Work-Status** answer *where an item sits* on two different lifecycle axes, and both are mutually exclusive within their group. Origin is not a lifecycle position; it never changes.
- **Initiative** is a namespace pattern for grouping work under an umbrella, not a per-item property.
- **Triage Flag** conforms structurally and fails on a consequence. Its group definition and the removal rule both mandate that the label be removed once triage executes — but a downstream schema-maintenance trigger counts this very label on **closed** issues in a trailing window. A label removed at triage makes that trigger structurally unable to fire, and its silence would be indistinguishable from "no items qualified."
- **Disposition** would parse cleanly and state something false. Dispositions are *final triage decisions*, applied when a decision is rendered. This marker is applied by a machine at creation, before any triage has happened.

The cheap answer was Disposition. It required no grammar edit, collided with no rule, and would have passed every automated check — because the parity engine does not read the `group` key at all. It would also have written into a K1 grammar document a definition that is simply not true of the row it covers.

## Decision

**Provenance is a first-class label group — the eighth — and the group set is no longer closed at seven.**

A provenance label records **how a work item entered the tracker**. Its grammar clauses:

- **Purpose:** origin. Was this item filed by a person, or emitted by a mechanism?
- **Cardinality:** zero or one per issue, and **orthogonal to every other group**. It never competes with a category, status, work-status, cluster, or disposition label, because it answers a different question. Most issues carry none — provenance is recorded only when the origin is not the default human-filed path.
- **Lifecycle role:** applied **at creation**, by the mechanism that files the item, and **never removed** — not at triage, not at close.

The persistence clause is the group's distinguishing property, not a detail. It is promoted to a composition rule (**Rule 9**) rather than left inside the group's prose, so that the reason Triage Flag was rejected survives as an enforceable clause. Without it, a future reader looking only at the row would see a temporary-looking marker and "simplify" it into Triage Flag, silently disabling every rule that counts the label after close — the exact failure this ADR exists to prevent, arrived at by a reasonable-looking edit.

**Two edits, two obligations, neither substitutable.** The group definition lands in the grammar document, because the grammar owns group definitions and a pack may never define one. The concrete row lands in the base methodology pack, because packs carry concrete rows. Declaring the row without defining its group leaves it referencing a group that does not exist; defining the group without the row leaves the grammar describing a group nothing populates.

## Decision kernel (version-agnostic)

> A label that records an item's **origin** — how it entered the tracker — belongs to the Provenance group. Provenance is orthogonal to every other group, is applied at creation by the filing mechanism, and is never removed, because downstream rules read it on closed items. A group whose lifecycle mandates removal may not host a label that downstream rules count after close.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| Home the row in **Category** | Rejected | Violates the one-category-label rule — the filing mechanism already applies a category. |
| Home the row in **Cluster** | Rejected | Cluster is a domain axis, bounded to one domain per issue and namespaced. An origin marker is not a domain. |
| Home the row in **Status** / **Work-Status** | Rejected | Both are mutually-exclusive lifecycle positions. Origin is not a position and never advances. |
| Home the row in **Initiative** | Rejected | A namespace pattern for umbrella grouping, not a per-item property. |
| Home the row in **Triage Flag** | Rejected — **on consequence, not taste** | The group mandates removal after triage; a downstream trigger counts the label on closed issues. Homing it here disables that trigger silently. |
| Home the row in **Disposition** | Rejected | Structurally clean, semantically false: dispositions are human triage decisions; this is machine-applied at creation. |
| **No label at all** — body marker plus a rewritten downstream query | Rejected | Trades a four-line grammar addition for a rewrite of two shipped sections of a schema contract, and discards the label surface every consumer already queries. |
| **New Provenance group** | **Selected** | The only option that names the row for what it is, collides with no rule, and preserves the closed-issue counting the pipeline depends on. |

## Consequences

**The group set is open where it was closed.** The grammar previously asserted seven groups in three places; it now asserts eight. Any future reader who assumed the enumeration was permanent must instead treat it as an enumerated-and-extensible set — extended by an ADR, never by a pack.

**Automation is unaffected, and this was verified rather than assumed.** The parity engine's row parser collects only `name`, `color` and `description`, and its own inline comment states that `group` is a documentation facet with no live GitHub counterpart. An eighth group value cannot change a MISSING verdict, an ORPHAN verdict, or the emitted fix commands. The cost of opening the set is therefore bounded to documentation, which is what makes the honest option affordable.

**Declaration is not materialization, and the gap is visible.** Declaring the row does not create the GitHub label — the grammar states this explicitly, and no enforcement mode can change it, because a check that cannot create a label cannot clear a MISSING it reports. Until an operator runs the create, the parity gate reports this row as MISSING. That report is **expected and correct**, not a defect: it is the gate doing exactly what it is for.

**A mechanism that applies labels must verify them first.** The corollary this ADR forces into the tooling: a filing mechanism that applies a label it does not create must check the label exists *before* it starts creating issues. Otherwise the unknown label reaches the API and is brought into existence with a default colour and no description — an ungoverned row that the name-only parity diff cannot see, which is the very defect class the emit-fix path exists to close.

## Reversibility

**CHEAP / Confidence HIGH** for the grammar and pack edits — both are content, revertable by reverting the commit, with no automated consumer reading the changed key.

**MODERATE / Confidence HIGH** for the live label once materialized. A label is repository **state**, not repository content: reverting the commit that declared the row does not delete the label it produced, and deletion is a separate manual action. Rollback ordering therefore matters — revert the merge first, then delete the label, so the parity checker does not immediately re-flag the deletion as fresh drift.

## Related ADRs

- **ADR-018** — establishes the work-item-type discriminator and the "project labels over the base" model this group composes with.
- **ADR-070** — fixes the methodology-pack composition grammar: the grammar owns groups, packs contribute rows. This ADR adds a group under that division of authority rather than working around it.
