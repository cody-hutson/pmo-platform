---
title: ADR-170 — Partial supersession is a reciprocal frontmatter edge, not a status value
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-09-01
release: adr-corpus-status-integrity
deciders: "Workspace owner (architecture ratified at the Stage 9 review); design authored at Stage 5 Solutioning, implemented at Stage 6 Engineering"
supersedes: none
tags: [architecture, governance, adr-corpus, supersession, frontmatter, schema, reciprocity, durability-lint, immutability, derived-surface]
source_observations:
  - "Corpus measurement at authoring (2026-09-01): 169 ADR records — 115 under core/ADRs/ and 54 under release/ADRs/. Frontmatter parsed 169 of 169; sensitivity control on `title:` returned 169, specificity control on a fabricated key returned 0."
  - "The `supersedes:` field was present on 14 of the 169 records at authoring, 10 of them valued `none`, leaving 4 real values — and it was absent from the schema's own §2 field table. Of those 4, 3 were partial and all 3 carried their scope in free-prose parentheticals."
  - "The reciprocal field `superseded_by:` was present on 0 of the 169 records at authoring, while `frontmatter-schema.md` § Lineage Fields already governed `supersedes`/`superseded_by` as a documented inverse pair for operational artifacts and `km-protocols.md` already asserted that pairing maps to the ADR `Superseded` class. The ADR corpus was the one population missing half of a pairing the platform already shipped."
  - "A lexical census at authoring found 13 distinct spellings of the partial-supersession relation across 42 occurrences — including `superseded in part`, `supersedes-in-part`, `Superseded-in-part`, `Amended in part` and `superseded in its substrate`. The predicate was authored wide across spaced, hyphenated, dashed and `in its <noun>` arms; its sensitivity arms fired on both a spaced and a hyphenated instance and its specificity arms returned False on a whole-supersession line and on `supersedes nothing`, so it discriminates scope rather than matching the stem."
  - "Two records carried a partial-supersession pointer in frontmatter at authoring, and they disagreed with each other on the hyphen: one wrote `superseded-in-part by`, the other `superseded in part by`. Two instances that cannot agree on a spelling is the direct evidence that no carrier existed."
  - "`check-adr-durability.py` derived its whole-file exemption from `FROZEN_STATUSES = (\"Superseded\", \"Deprecated\")`, matched on the status leading token — so a record flipped to `Superseded` leaves the lint's population silently."
  - "The originating card named a frontmatter partial-supersession tail on ADR-078 as the working precedent. That tail did not exist: ADR-078 read a bare `status: Accepted` both at the card's own baseline and at this release's. The quoted string was its `## Status` BODY line, not a frontmatter value."
  - "ADR-046's `## Consequences` asserted that ADR-012 carried a supersession-in-part pointer back to it. A grep for `ADR-046` over ADR-012 and over ADR-017 returned 0 hits each, against a control arm proving the matcher fired on those same paths. The record asserted its own enforcement and the assertion was false."
---
<!-- reference-durability: allow-link -->

# ADR-170 — Partial supersession is a reciprocal frontmatter edge, not a status value

## Status

**Proposed.** Ratification flips this field at the Stage 9 Plan Review gate.

**Numbering provenance.** The number was READ from the allocation oracle at authoring, never reserved: `renumber-adr.py --next-free` reported `ANCHOR 169 (origin/main)` and `NEXT-FREE 170`, with `--detect` reporting `CLAIMED-SET-BRANCH-ONLY 170 (detection only — never binds)`. The claim binds at merge per ADR-115; if a sibling branch claims the same slot first, the merge-time renumber moves this record and writes its own provenance note.

## Context

Supersession in this corpus is overwhelmingly **partial**. A superseding ADR retires a clause, a rule, a decision item, or a substrate choice, while the rest of the superseded record continues to bind. The corpus had no way to say that.

At authoring the measured state was this. The `supersedes:` field existed on a small minority of records and was **absent from the schema's own field table** — a de-facto convention nobody had written down. Its reciprocal did not exist at all. Meanwhile the relation itself was being written in prose in thirteen different spellings, including two records that carried a frontmatter pointer and disagreed with each other on whether the words were hyphenated.

Two failures followed, and they compound.

**No machine-readable carrier.** The derived release index projects only the `status:` **leading token** by design, so a supersession pointer written as a prose tail is invisible to the one surface built to prevent status drift. A relation that cannot be read by a machine cannot be checked by one.

**No reciprocity.** ADR-046 asserted as a *consequence* that ADR-012 carried a back-pointer to it. That pointer did not exist, in either ADR-012 or ADR-017. Nothing caught it, because nothing was looking — the edge was authored on one side only and the record's own claim about its enforcement went unverified for months.

The obvious repair — flip each superseded record's `status:` to `Superseded`, or append a prose tail to it — is **forbidden**, and for two independent reasons that both had to be discovered rather than assumed:

1. The authoring guide's forbidden list is explicitly **closed**, and it names the status value with exactly one exception: the Nygard `Deprecated` / `Superseded` transitions. Most partial-supersession targets are `Accepted`. Appending a supersession tail to their status is a status-value edit that is not a Nygard transition.
2. The `status:` leading token is not a label — it is a **permission state**. The durability lint derives its whole-file exemption from it. A record flipped to `Superseded` therefore does not merely get mislabelled; it drops out of the population that polices it, and it can never receive another edit, edge, or missing-section backfill again. The two records that already carried a frontmatter tail were not a precedent to standardize. They were records that had taken a forbidden edit, which is exactly why they disagreed.

## Decision

**Partial supersession is carried by a reciprocal pair of frontmatter fields, and never by the `status:` value.**

**1 — The carrier is the inverse pair `supersedes:` / `superseded_by:`**, with a two-token scope grammar:

```
<entry>        := ADR-NNN SP <scope> [ SP "(" <scope-label> ")" ] [ SP "—" SP <free rationale> ]
<scope>        := "whole" | "in-part"
<field-value>  := "none" | <entry> [ "," SP <entry> ]*
```

Only the two leading tokens are load-bearing. Free rationale after an em-dash is preserved on the record and ignored by the parser, so the explanatory prose the corpus already writes survives verbatim. The canonical parser symbol `SUPERSESSION_ENTRY_RE` is defined once in the ADR schema and cited — never restated — by every consumer. A scope label names a structural referent: a decision item, a clause, a rule, a named section. It never carries a commit SHA or a count, because those rot inside a record that is immutable by policy.

This **adopts** a convention the platform already governs for operational artifacts rather than minting a second one. The populations stay disjoint; only the implementation was missing.

**2 — `superseded_by:` is partial-only, and this asymmetry is the whole design.** A *whole* supersession keeps the sanctioned Nygard `status: Superseded by ADR-NNN` transition as its reciprocal. A *partial* supersession lands `superseded_by: ADR-NNN in-part (scope)` on the target while its `status:` stays `Accepted`.

State the reason as a property, not a preference: the leading token is a **permission state**. Flipping a partially-superseded record would both assert a retirement its own superseder denies **and** remove a still-binding record from the durability lint's population. Keeping the target `Accepted` is what keeps it editable and keeps it policed.

The asymmetry also discharges a hard constraint by construction rather than by exception. The corpus's one whole-supersession target is a frozen record that may take no edits at all — and under this decision it needs none, because the `status:` value it already carries **is** its reciprocal.

**3 — Reciprocity is a checked invariant, not a discipline.** Rule **R6 RECIPROCITY** in the ADR durability lint asserts both directions: every `supersedes:` entry requires its reciprocal on the target, and every `superseded_by:` entry requires a matching entry on the superseder. R6 is **delta-scoped** on the lint's existing diff-base machinery and adds no new cutover constant — it sees only edges whose superseder or target changed in the diff, so it never fires on a pre-existing one-sided edge. Without a diff base it emits a visible skip rather than reading green. Frozen records are exempt on the same ground as the lint's other rules. An edge that genuinely cannot be landed **declares** itself with a `reciprocity-exempt` marker carrying a reason, and R6 reports the exemption rather than suppressing the count.

**4 — Partial-supersession state is NOT projected into the derived index, and the reason is recorded.** The projector's population is the release module only; the partial edges live overwhelmingly on the core side, which it deliberately does not read. A column would therefore render a small minority of its subject and silently omit the rest — reproducing at a new column exactly the several-enumerations-several-maxima defect the derived-surface contract exists to prevent. A derived surface is read as complete, so a column that is right about a minority of its subject is worse than no column. The non-projection and this reason are recorded in the projector's own derivation docstring.

**5 — The pair carries supersession only.** `amends-in-part` is supersession-in-part and uses the pair. *Qualifies*, *extends*, *composes* and *refines* are **not** carrier-eligible and stay in `## Related ADRs` prose. A record that qualifies another without contradicting it has superseded nothing, and the corpus contains at least one pair where the superseding record says so in its own words while an inventory counted it as an edge.

## Alternatives Considered

| Option | Verdict | Ground |
|---|---|---|
| A `status:` prose tail — the originating card's implied design | **Rejected** | Closed-forbidden-list item 4 (the status value, outside the Nygard transitions); invisible to the derived index by that surface's own contract; and the status tail is already overloaded, carrying ratification anchors on most of the records that have one. The two live instances are forbidden edits, not precedent. |
| Mechanical flip of every target to `Superseded` | **Rejected** | Asserts a retirement the superseder explicitly denies — one superseding record says so about its own target, in its own words — **and** silently removes still-binding records from the durability lint's population by moving them into the frozen state. Two independent disqualifiers. |
| Extend the event log's `superseded:`/`by:`/`reason:` payload vocabulary | **Rejected** | Category error. That vocabulary is an event-log payload keyed on a decision-id namespace that its own governing record writes verbatim precisely because canonicalizing would break the join. Different population, different keyspace. Cited here as naming precedent only. |
| A new `## Supersession` H2 body section | **Rejected** | Net-new structure where a governed field pair already exists, and body prose is not machine-readable — which is the defect this decision exists to close. |
| Superseder-side `supersedes:` only, with the target side derived by inversion | **Rejected — and this is the closest call** | Genuinely attractive: it cannot be one-sided and creates no second copy. Rejected because ADR records are **read individually**. A reader opening the superseded record would learn nothing about its own standing. The corpus already pays this cost deliberately on its one whole edge, where the target carries its own status transition rather than relying on the superseder's field. The second copy is **accepted and made non-drifting by R6** rather than avoided. |
| Project partial supersession into the derived index | **Rejected on measurement** | Would render the release-side edges and silently omit the core-side majority. See Decision part 4. |

## Consequences

### Positive

- **The relation becomes machine-readable**, so reciprocity can be checked instead of trusted. The failure that motivated this decision — a record asserting a back-pointer that did not exist — is now detectable by a rule rather than by a reader who happens to look.
- **A partially-superseded record stays editable and stays policed.** It remains `Accepted`, inside the durability lint's population, able to receive further edges and hygiene.
- **The frozen record needs no edit**, because a whole edge's reciprocal is the status value it already carries. The hard freeze constraint is satisfied by construction rather than by a carve-out.
- **No new SSOT, no new tool, no new gate, no new workflow step.** The decision extends an existing schema section, an existing lint, and an existing CI surface.

### Negative — the accepted residuals, named rather than discovered later

- **The edge is authored twice, by design.** Both endpoints carry it, because records are read individually. R6 is what keeps the two copies honest; without it this would be a drift surface rather than a contract.
- **Partial-supersession state is invisible to the release index**, by measured decision. A reader who wants it reads the records.
- **This carrier does not close every representation gap.** One record names its supersession targets in prose by description only, with the numbers appearing solely in a discovery field, so the edge is invisible to any declarative-zone probe. Another supersedes-in-part a decision that has no ADR record at all — correctly handled in prose, and correctly *not* forced into the field, which is why `supersedes:` stays optional.
- **The overloaded `status:` tail is untouched.** Most records carrying a tail carry a ratification anchor rather than a supersession pointer, and that overload is out of this decision's scope, which is supersession only.

## Reversibility

**CHEAP / Confidence HIGH.** Every edit is additive — one schema field pair, one guide list entry, one lint rule, one docstring paragraph, three record frontmatter lines, and this ADR. Nothing is deleted, no record changes meaning, and reverting the single release merge restores every surface atomically.

One asymmetry is worth naming rather than assuming symmetry: this record claims its number **at merge**. A revert frees the number, but a sibling release that allocated above it in the interim will not renumber — so a revert-then-reland re-claims a *different* number, and any citation authored in the interim must be re-derived.

## Related ADRs

- **ADR-115** — the ADR number claim binds at merge. This record's number was read from the oracle, not reserved, and its Numbering provenance note records the oracle's output at authoring.
- **ADR-117** — the derived-surface and scoped-conformance contract. This decision **respects and does not amend** it: Decision part 4 declines to add a column precisely because that contract's scoping makes a partial column misleading.
- **ADR-118** — the ADR section set and the durability-hygiene carve-out this decision operates inside. Adding a `superseded_by:` pointer to an `Accepted` record is admissible under that carve-out's open permitted list because it records an external fact and revises no decision, alternative, consequence, or status value.
- **ADR-146** — supersession is an append and integrity is a dated read-only sweep. Cited as the **naming precedent** for the vocabulary and explicitly **not** as the carrier: its `superseded:`/`by:`/`reason:` triple is an event-log payload over a different population and a different keyspace.
- **ADR-045 and ADR-029** — the corpus's one whole-supersession edge, and the retained Nygard form. ADR-029 is the record this decision's partial-only asymmetry lets alone entirely.

**This ADR supersedes nothing.**
