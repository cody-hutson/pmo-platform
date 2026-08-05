---
title: Rename Reference Cascade — pmo-platform
purpose: The operating rule that treats a rename, move, or delete of a referenced entity as a graph operation — every referencing site is located, classified, and updated in the same change, before the change is reported done.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Rename Reference Cascade — pmo-platform

**Scope note.** This rule governs the **identifier cascade at edit time**. Whether a markdown link still *resolves* is a separate, automated discipline owned by [`doc-link-maintenance.md`](doc-link-maintenance.md). The two are complements, not alternatives — see § 5.

## Purpose

Renaming, moving, or deleting a referenced entity is a **graph operation, not a local edit**. The entity is one node; every site that names it is an edge. Change the node without changing its edges and you leave dangling references: links that no longer navigate, prose that cites a file that no longer exists, string literals pointing at a moved path, index rows enumerating a name nothing answers to.

The failure is not ignorance of the rule. It is that a rename *feels finished* the moment the entity itself is correct. This rule moves the done-condition from the entity to the graph.

## § 1 — What fires the rule

The rule fires when **both** hold:

1. You are changing the **identity** of something — its path, its filename, its section heading, its identifier, its key, or its existence; **and**
2. That identity is **referenceable** — some other site could name it.

One operation class, three shapes:

| Shape | Examples |
|---|---|
| **Rename** | a file basename · a section heading (and therefore its anchor) · a config key · a check or gate identifier · a skill, label, or field name |
| **Move** | a file to another directory · a section to another file · content to another owner |
| **Delete** | a file · a section · a registry row · an allowlist entry · a memory-store entry |

**Delete is in scope and is the easiest to miss.** There is no new name to search for, so nothing prompts the sweep — yet the dangling references it leaves are identical.

The trigger is **observable, not introspective**. It is never "does this feel risky?" — an agent that treats a rename as a local edit is, by construction, not worried. It is: *did the name of something change?*

## § 2 — The obligation

Before the change is reported done:

1. **Search for the old identifier** across every reference form (§ 3) and every surface in scope. Record the **invocation**, the **population searched**, and the **count found**.
2. **Read each hit and classify it** — update · preserve-with-reason · not-a-reference — *before* editing. A find-and-replace is not context-aware; a sweep is read → classify → plan → edit, per file.
3. **Update every hit that must change, in the same change** as the identity change itself. The corpus is never left half-renamed, and the whole operation reverts as one unit.
4. **Re-run the identical search** and observe zero.
5. **Emit the observable** (§ 4).

The step-1 count is not bookkeeping: it is the sweep's own **control arm**. A search that found nothing *before* the rename cannot demonstrate anything by finding nothing after it.

## § 3 — Reference forms and surfaces

A reference is anything that **names** the entity — not only a markdown link. Sweep every form present in the surfaces you touch.

| Form | Where it hides | Reached by an automated link check? |
|---|---|---|
| Markdown link | `[text](path)` · `[text][label]` · `[label]: path` | **Yes** — this is the only form a link checker extracts |
| Inline path in prose | a path written as backticked text rather than as a link | No |
| Frontmatter field value | a field naming a file, sibling, or consumer by path or basename | No |
| Section anchor | a heading slug, same-page or cross-file | No — pure anchors are skipped by construction |
| String literal in code or config | a path in a script array, a default, a glob, an allowlist entry, a workflow step | No |
| Registry or index row | a mirror-pair map · an enumerated list · a **count** of the set | No |
| Identifier reference in prose | a check number · a gate ID · a skill name · a decision-record number · a field name | No |
| Out-of-repo reference | an auto-memory entry · an operator-instance file · a deployed mirror | No — outside every in-repo scan surface |

**The surfaces are wider than the repository.** A rename inside the repo can dangle a reference held in the auto-memory store or in a deployed mirror; a deletion in the memory store can dangle a link in a surviving memory. Both are in scope for the sweep even though no in-repo check can see them.

**A count is a reference.** Where the entity belongs to an enumerated set, the set's cardinality names it too — adding or removing a member without updating every stated count leaves the same dangling condition in numeric form.

## § 4 — The observable

Report the sweep, not the intention:

```
[REFCASCADE: <search invocation> over <population> → pre <N> / post 0]
```

`pre <N>` is load-bearing. A post-count of zero is evidence **only** when the identical search returned non-zero before the change; otherwise the zero is indistinguishable from a search that never matched anything. Where the pre-count is legitimately zero — a new entity nothing references yet — say so; that is a cheap rename, and stating it *is* the record.

Where a surface genuinely cannot be searched, name the surface and why, rather than reporting a zero the sweep did not establish.

A sweep that ran and emitted nothing is indistinguishable from a sweep that never ran.

This obligation is registered as **`DTA-7`** in the Adherence Checkpoint Index of [`decision-time-adherence.md`](decision-time-adherence.md), so it surfaces at the moment the change is reported done. Per that index's composition rule, the token above **is** the checkpoint's emission — no separate `[DTA-7: …]` line is added.

## § 5 — What this rule does not own (compose, do not duplicate)

| Surface | Owns | The boundary |
|---|---|---|
| [`doc-link-maintenance.md`](doc-link-maintenance.md) and its authoritative standard | **Link resolution, detected after the fact** — does a markdown link still resolve? Enforced by an automated checker over a declared scan scope, at deploy time and pull-request time. | That check is a **detector**; this rule is an **obligation**. It sees one reference form inside one declared scope; this rule binds every form and every surface, at the moment of the edit. **Passing that check is not evidence the cascade was done.** |
| [`artifact-naming-standard.md`](../standards/artifact-naming-standard.md) § Retroactive-Rename Protocol | **The artifact-file instance** — renaming a non-conforming file to conform, with its ordered steps and its reversibility note. | That protocol is this rule applied to one entity class. Follow it for artifact-file renames; this rule generalizes it to any referenceable entity. Nothing here restates its steps. |
| The Stage-5 cascade-completeness sweep and the structural path-move consumer sweep | **The release-pipeline instances** — a count / enumeration / threshold change, and a path move's hard-coded consumers, each swept at design time against a spec's affected-files matrix, with a gate. | Those fire inside a release spoke and are scoped to the value or path being changed. This rule binds any agent edit, including one that never enters the pipeline. |
| [`reference-durability-standard.md`](../standards/reference-durability-standard.md) | Whether a reference **should exist at all** in durable corpus. | Orthogonal. A reference can be perfectly cascaded and still be a durability violation; a durable inline summary has no reference to cascade. |
| The memory↔corpus encode-and-evict lifecycle's re-point step | The **eviction instance** — reconciling surviving memories that link an evicted memory. | That step is this rule applied to the memory store at one named moment. |

## § 6 — Reporting a rename as done

Reporting a rename, move, or delete as complete is a state-mutation claim, and the state that mutated is the **reference graph** — not the entity. Reading back the renamed file alone does not discharge it; the post-sweep zero does. This is the mutation-class specialization of the write-first-speak-second guardrail in [`CLAUDE.md.template`](../CLAUDE.md.template) § Quality Standards: read back what actually changed.
