<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-162 — System of record per mirrored data element — authority follows authorship
status: Proposed — flips to Accepted when the operator ratifies it at this release's Stage 9 Plan Review gate. The flip is recorded in this file's own `status:` field, which is where it must be verified — never inferred from milestone closure, from a merged pull request, or from a review comment.
date: 2026-08-29
release: one-system-of-record-per-element
deciders: "Stage 5 Solutioning spoke (options analysis, evidence-grounding, blast radius) + release hub (carried constraint on the supersession scope) + operator (Stage 4 plan-review determination that ADR-051 is superseded in part, never in full) + Stage 6 Engineering spoke (authorship)"
tags: [architecture, source-of-record, external-mirror, data-authority, reconciliation, supersedes-in-part, health-check, raid, dual-format]
supersedes: ADR-051 (Decision 1 only — the system-level canonical assignment; Decisions 2-5 stand)
source_observations:
  - "Three governance surfaces declared incompatible systems of record for the same externally-mirrored data, with zero cross-citations reconciling them. A reconciliation probe found that none of the three referenced either of the others' claim, so a consumer could resolve the same disagreement in opposite directions depending on which surface it happened to read."
  - "The three claims are not three answers to one question. The operations-governance claim is a WRITE-DIRECTION claim (an un-pushed local edit is held locally until sync completes). The tracker-schema claim is a RENDER-SOURCE claim (the local register file is the source of a one-way projection). The health-check ADR's claim is an AUTHORITY claim (whose value wins on disagreement). Each is true on its own axis, which is why picking a single system-level winner would have broken something true in each."
  - "A fourth surface, the external-sync path contract, uses the phrase source of truth in the write-direction sense inside the same sentence that describes the authority sense. The term was load-bearing on two axes at once."
  - "The platform already states the authorship rule for a different population: the external-target knowledge scope record decides that the target is the sole source of truth for its own facts. Extending that principle to the operational-mirror population is a generalization of a ratified rule, not a new invention."
  - "The platform cannot write external systems: the external-sync path contract makes the path read-and-poll only, and a platform-side write guard blocks the inverse. An authority rule that named an external system canonical for a locally-authored element would therefore assign that element a system of record the platform can never write."
  - "The one-way render contract already halts rather than publishes when a render's source artifact does not resolve. That existing guard is the enforcement for the locally-mastered branch of the reconciliation rule; no new enforcement mechanism was needed for it."
  - "A controlled three-arm experiment over the ADR durability linter, varying only the status line on byte-identical copies of the superseded record, showed that a Superseded leading token whole-file exempts the record from the lint. A full supersession would therefore have removed a record carrying four in-force decisions from continuous-integration durability coverage silently, with no finding emitted."
  - "A census of the ADR corpus found that the partial-supersession pointer is carried in the body Status block alone by the large majority of partially-superseded records, and on the frontmatter status line by exactly one. The delivery child's acceptance criterion reads the status LINE, so the majority convention would have shipped a defect that looks correct."
---

# ADR-162 — System of record per mirrored data element — authority follows authorship

## Status

**Proposed.** Flips to **Accepted** at this release's Stage 9 Plan Review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure or from a merged pull request.

**Supersedes in part [ADR-051](ADR-051-health-check-mcp-primary-source-set.md)** (Decision 1 only). ADR-051 remains `Accepted`, editable, and in force for its other decisions; the disposition is stated in full under `## Decision` below.

**Numbering.** ADR numbers are platform-global monotonic across both homes (`core/ADRs/` and `release/ADRs/`). This record was allocated from the binding oracle at authorship time and is **claimed at merge, never reserved**. A concurrent unmerged sibling release has claimed the same number on its own branch; an unmerged claim is advisory, a gap blocks the repository while a duplicate is tooled, and whichever release merges second renumbers via the platform's renumbering tool.

## Context

The platform mirrors data between its own local artifacts and the external systems of engagement it reads — Jira, Confluence, Smartsheet, SharePoint, Google Drive, GitHub. For any element that exists on both sides, two questions arise the moment the two copies disagree, and the corpus had been answering them as though they were one question.

**The two questions are different.** *Authority* asks whose value wins on disagreement. *Mutation direction* asks which system this platform is permitted to write. A surface that answers one and uses the vocabulary of the other reads as a contradiction of every surface that answered the opposite question.

That is exactly what had happened. Three governance surfaces each declared a "source of truth" for the same mirrored data and none cited either of the others:

- The operations governance rule states that truth lives locally until sync completes. Read on its own axis this is a **write-direction** statement: an edit made locally and not yet pushed is held locally, and the local copy is what the platform acts on until the push lands. It says nothing about who wins a genuine disagreement.
- The tracker schema's Confluence dual-format model names the RAID Log's local CSV the source of truth for the stakeholder-facing Confluence view. Read on its own axis this is a **render-source** statement: the rendered page is a projection, and the projection has a source.
- ADR-051's first decision states that the MCP-read sources are canonical and local is fallback or supplement. This is a genuine **authority** claim, and it is the only one of the three that is.

A fourth surface — the external-sync path contract — uses the phrase in the write-direction sense inside the same sentence in which it describes the authority sense.

**Why a single system-level winner was never available.** Naming the external systems universally authoritative assigns a system of record to elements the platform alone authors, and the platform cannot write external systems: the sync path is read-and-poll only. Such an element would have an authority it can never reach. Naming the local artifacts universally authoritative inverts a settled decision by fiat and makes every stakeholder-visible tracker value subordinate to a possibly-stale local copy — the outcome ADR-051's own alternatives section rejected, for reasons that still hold. A hand-assigned lookup table of elements satisfies neither: it has no generating rule, so the element that appears next has no answer and the table drifts the moment a new mirrored element exists.

**The rule the platform already had.** [ADR-109](ADR-109-external-target-knowledge-scope.md) decides, for a different population, that the target is the sole source of truth for its own facts — authority attaches to *where the fact is authored*, not to a class of system. Applying the same principle to the operational-mirror population resolves all four surfaces without overriding any of them, and it generates an answer for elements not yet enumerated. The decision below is that extension.

## Decision

### 1. Authority follows authorship

**A mirrored data element's system of record is the system in which that element is authored.** Authority attaches to the **element**, never to the system; the platform's write-direction is a separate axis and constrains only what it may mutate, never what is authoritative.

The two axes are named, and a surface that speaks about one does not thereby decide the other. A statement that the platform holds un-pushed edits locally is a write-direction statement and settles no authority question. A statement that a rendered artifact has a local source is a render-source statement and settles the authority question only for the elements that source authors.

### 2. The system-of-record table — the rule's worked output

The table below is the rule applied, not a second rule. An element absent from it is resolved by asking where it is authored.

| # | Mirrored data element | Authored in | System of record | Mirror direction | On disagreement |
|---|---|---|---|---|---|
| **E1** | **RAID content** — the rows of the RAID Log's full-schema local CSV | the platform (agents and the operator author rows) | **Local** — the project's `[Project]_RAID_Log.csv` | local to Confluence, **one-way render** | **Local wins.** The Confluence view is regenerated from the local CSV; a Confluence-side edit is superseded by the next render and reported as render-drift. It is never merged back. |
| **E2** | **External ticket state** — status, assignee and due date of a work item in Jira, Smartsheet, GitHub or a comparable tracker | the external tracker (people working outside the platform) | **External** — the system named by the item's `source_system` | external to local, **read and poll only** | **External wins.** The local copy is corrected to the external value. A *more recent local* value is reported to the operator as an unpushed human action; the platform never writes the external system. |
| **E3** | **Confluence-rendered artifacts** — a stakeholder page produced from a local source artifact | the local source artifact | **Local source** | local to Confluence, **one-way render** | **Local wins**, as E1. The dual-format render contract's existing orphan guard is the enforcement: a render whose source artifact does not resolve **halts**; it does not publish. |

E1 and E3 share a branch; E2 is its inverse. That asymmetry **is** the reconciliation contract, and it is the reason a single system-level winner was never available.

### 3. The reconciliation rule — directional in every branch

**When a local value and an external value for the same element disagree, the value held by that element's system of record wins.** The non-system-of-record side is corrected toward it — by regenerating the render when the system of record is local, or by updating the local copy when the system of record is external. Where the platform cannot perform the correction because the system of record is external and the platform is read-only against it, the divergence is **reported to the operator as an unpushed human action**: never auto-applied, and never resolved in the platform's favour.

**"Flag both without a direction" is not an available outcome.** Every branch of the rule names a winner and names who performs the correction.

### 4. ADR-051's disposition — superseded in part

**ADR-051 Decision 1 is superseded in part.** Its *system-level* assignment — that the mirrored external sources are canonical and local is fallback or supplement — is replaced by an *element-level* assignment resolved by authorship. **For every element an external system authors — work-item state, externally-authored plans and schedules, assignees, due dates — the outcome is unchanged and the external source remains authoritative.** Decision 1 was over-broad, not wrong.

**ADR-051's Decisions 2, 3, 4 and 5 remain in force, unchanged and unfrozen** — drift resolution by recency with the audience-facing priority twist; both-stale to the operator with no auto-resolve; the unreachable-source degradation envelope **including its MEDIUM auto-action cap**; and the degradation posture for the source that has no connector. ADR-051 therefore remains `Accepted` and editable, so those decisions keep a live home and stay inside continuous-integration durability coverage.

**Decision 2's re-ranging is a consequence, not a second supersession.** Its antecedent — that the mirrored and local copies disagree — presupposes Decision 1's canonical-set assignment, so re-typing Decision 1 re-ranges Decision 2 over the elements whose system of record is external. That is the population Decision 2 was written for. Its text is unchanged and it remains in force.

### 5. The population boundary against ADR-109

This record governs the **project-operational mirror** population: elements the platform mirrors between its own local operational artifacts and external systems of engagement. [ADR-109](ADR-109-external-target-knowledge-scope.md) governs the **platform-target referent** population: facts about a repository or system the toolkit *operates upon*.

**The populations are disjoint, and ADR-109's no-local-retention rule does not extend here.** ADR-109 forbids retaining a resolved target-side referent anywhere, with no offline fallback by design. That rule is correct for its population and would be wrong for this one: the local operational trackers **are** the platform's operational memory, the render contract requires a local source artifact to render from, and the sync path contract explicitly persists a local snapshot. ADR-109's own scope clause already bounds it to a fact whose source of truth is a repository other than this install's platform, so the boundary is a reading of that clause rather than an amendment to it.

Stating this boundary is load-bearing. Left unstated, the two records read as contradictory, and the corpus gains one more uncited authority-adjacent surface — the exact defect this record exists to remove.

## Alternatives Considered

Three viable alternatives were weighed for the rule itself, and three for how ADR-051's disposition is represented.

### The rule

| Option | Decision | Rationale |
|---|---|---|
| **Local always wins** — elevate the operations-governance claim to an authority rule | Rejected | Inverts ADR-051 by fiat and re-opens a settled decision whose stated rationale still holds: audience-facing systems are what stakeholders read, so treating a possibly-stale local copy as canonical lets internal drift mask the drift that actually reaches stakeholders. |
| **External always wins** — elevate ADR-051's Decision 1 to a universal rule | Rejected | Structurally unbuildable for locally-authored elements. The platform cannot write external systems, so any element only the platform authors would be assigned a system of record it can never reach; and a wiki-side edit to a rendered page would outrank the local artifact that generated it, leaving the render contract's orphan guard with no source to reject against. |
| **A per-element table, hand-assigned** | Rejected as the primary form | Satisfies the immediate need but is a lookup list with no generating rule: the element that appears next has no answer, and the table drifts the moment a new mirrored element exists. Retained as the rule's *worked output* (Decision 2) rather than as the rule. |
| **Authority follows authorship** | **Accepted** | The only option that leaves all four surfaces true rather than overriding three of them; it generates an answer for elements not yet enumerated; and it is already the platform's rule for the platform-target population, so adopting it here extends a ratified principle rather than minting a new one. |

### The representation of ADR-051's disposition

| Option | Decision | Rationale |
|---|---|---|
| **Full supersession** — `status: Superseded by …` | Rejected | Measured, not argued: a `Superseded` leading token whole-file exempts the record from the ADR durability lint, silently removing a record carrying four in-force decisions from continuous-integration coverage. It also freezes the record against all further edits, so recovering the orphaned decisions would cost a third record, and it publishes a status that is factually wrong. |
| **Body `## Status` block only, frontmatter left bare** | Rejected | The dominant corpus convention, and the trap: the delivery child's acceptance criterion reads the frontmatter `status:` **line**, so following precedent here ships a defect that looks correct. |
| **Superseding-side pointer only** — a `supersedes:` key on this record and nothing on ADR-051 | Rejected | Leaves the superseded record silent. A reader who arrives at ADR-051 alone never learns that its first decision moved, which is the failure this release exists to remove. |
| **Frontmatter `status:` tail carriage on an `Accepted` leading token, plus the `## Status` body block, plus a cross-reference, plus a scoped `supersedes:` key here** | **Accepted** | The only candidate that satisfies the delivery child's status-line criterion, preserves durability-lint coverage, and renders truthfully in the generated index. The status-tail form is explicitly sanctioned by the ADR schema's leading-token rule and by the index generator's own contract, and one corpus record already carries it. |

## Consequences

- **(+)** All four pre-existing surfaces stay true. Each is re-typed onto its own axis rather than overridden, so no surface has to be contradicted to make the corpus consistent.
- **(+)** The rule generates. An element not in the table resolves by asking where it is authored, so the record does not have to be amended every time a new mirrored element appears.
- **(+)** One home per fact. The rule is stated once here; the operations governance rule, the tracker schema and ADR-051 cite it and restate none of it — the property whose absence created the defect.
- **(+)** ADR-051 stays `Accepted` and editable, so its surviving decisions keep a live home and remain inside durability-lint coverage.
- **(+)** No new enforcement mechanism is required for the locally-mastered branch: the render contract's existing orphan guard already halts a render whose source does not resolve.
- **(−)** A partial supersession is harder to read than a clean one. A reader must consult two records to learn the full state of the health-check source contract. This is accepted deliberately: the alternative orphans in-force decisions.
- **(−)** The element-level assignment costs more thought at the point of use than a system-level rule. A consumer must ask where the element is authored rather than which system it came from. That question is the decision's whole content, so the cost is intrinsic rather than incidental.
- **(−)** The unpushed-human-action branch of the reconciliation rule terminates in an operator report rather than an automated correction. This is a consequence of the read-only external posture, not of this decision, and it is named here so the residual is visible rather than discovered.

## Reversibility

Split, because the two halves genuinely differ.

- **The system-of-record assignment (the decision content): `MODERATE` · confidence `HIGH`.** Reversing after the delivery children ship costs a third record plus re-editing the citing surfaces — days, no data loss. Confidence is HIGH because the rule is derived from an already-ratified principle and is falsifiable against four independent surfaces, all of which it leaves true.
- **The supersession mechanics (the status-line form): `CHEAP` · confidence `HIGH`.** A one-line frontmatter edit plus two prose blocks; reverting is a single-commit reversal. Confidence is HIGH because the form was verified by a controlled experiment against the durability linter rather than asserted from convention.

## Related ADRs

- [ADR-051](ADR-051-health-check-mcp-primary-source-set.md) — **superseded in part** by this record (Decision 1 only, the system-level canonical assignment); its Decisions 2 through 5 remain in force and unchanged.
- [ADR-064](ADR-064-dual-format-document-model.md) — the local-source-to-stakeholder-render dual-format model and its orphan guard; the mechanism behind elements E1 and E3.
- [ADR-109](ADR-109-external-target-knowledge-scope.md) — the authorship principle this record generalizes, and the **disjoint** population boundary stated in Decision 5.
- [ADR-045](ADR-045-cross-surface-memory-contract.md) — the no-shadow-source-of-truth invariant across this install's surfaces, which this record extends to externally-mirrored elements.

### Provenance

- Decision card: #5837 — decide the system of record for each externally-mirrored data element; this record is its sole deliverable.
- Delivery child: #5844 — one system of record per mirrored element plus a governed home for external identity; it amends ADR-051's status line and adds the citations in the operations governance rule and the tracker schema.
- Release: the `one-system-of-record-per-element` milestone; design authored at Stage 5 Solutioning (sub-task #6277), built at Stage 6 Engineering (sub-task #6278).
