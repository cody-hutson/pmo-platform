<!-- reference-durability: allow-link -->
---
title: "ADR-117 — The ADR index is a derived surface and cannot drift; the conformance claim is scoped to a named baseline and its residual is stated"
status: Proposed (flips to Accepted at this release's Stage 9 plan-review gate)
date: 2026-08-04
release: adr-corpus-conformance
deciders: "Workspace owner (ratifies at this release's Stage 9 plan-review gate); the index-as-derived-surface direction and the conformance-claim scoping were both rendered at the Collective Review scope-lock, designed at Stage 5 Solutioning, authored at Stage 6"
tags: [architecture, adr, governance, derived-surface, duplicate-source-discipline, projection, conformance, audit-baseline, reversibility-cheap]
source_observations:
  - "The release ADR README carried FOUR independent hand-maintained enumerations of ONE file set — an index table, a prose roster inside the naming-convention paragraph, a cross-numbering table, and a scope-narrative paragraph — and at the release baseline they topped out at four DIFFERENT numbers. Four maxima over one population is not four stale copies of one fact; it is the proof that the copies drift independently, at independent rates, with nothing reconciling them."
  - "Of the rows the index table did carry at the release baseline, half contradicted the record they pointed at. Eight of sixteen showed a Status the record's own frontmatter disagreed with — every one of them reading Proposed against an Accepted record — and nine of sixteen showed a Title the record's own `title:` field disagreed with. Five rows of sixteen were correct on every column."
  - "The originating observation reported the gap as two missing rows, because two were the only ones a prose line happened to name as pending. Re-derived against the file set at the sweep baseline the figure was fourteen. The observation was not wrong about what it saw; it was reading one enumeration and the defect spanned four."
  - "Adding the missing rows would have left three drifting enumerations behind and re-created the defect on the next merge, because a hand-typed row is a second copy of a fact the record already owns. The stale-Status half in particular is untouched by adding rows: it is a per-cell drift, not a coverage gap."
  - "The core module's README was measured before being treated as the same defect. Roughly a third of core records are file-linked there, and the ones that are appear under thematic groupings rather than in sequence. It was never an index; a completeness criterion applied to it would have been a criterion against a document that had not claimed the property."
  - "The mechanism this record selects is not new. The repository already carries a governed Derived-Surface Contract with a worked instance (a release ledger projected from another, verified by re-derivation at a deploy check), and a second instance of the same shape in a generated hook registry. Both predate this decision."
  - "The residual this record names materialized DURING the release that authored it, before that release merged. A sibling release merged into the mainline mid-Engineering carrying two new ADRs, both missing the exact section this release had just driven to full presence across its own branch. The prediction did not need to wait for a future merge to be confirmed."
  - "The merge-time renumber tool rewrote three index surfaces in this same README by hand, and its behavioural fixture synthesized a README carrying all three so the assertions would find them. Converting the index without amending both would have left a green suite asserting against a shape the corpus no longer had — the tool would then have hand-edited a generated region and failed the projection check its own run triggered."
---

# ADR-117 — The ADR index is a derived surface and cannot drift; the conformance claim is scoped to a named baseline and its residual is stated

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** The number was bound against the mainline only, per the binding rule this release's own sibling record establishes. It is the next free slot over the union of the mainline and this branch's tree, and it was chosen by measurement rather than by increment: the two adjacent candidates were each simulated against the merge union, and both introduced a defect this one does not — the lower added a third duplicate, the higher landed a gap. As with every ADR, the number is allocated at authorship and bound at merge; if a sibling merges ahead of this record, the reconciliation is tooled and the record's own Status block will carry the provenance note.

**Numbering provenance — `113 → 117`.** Authored branch-local as **ADR-113**; renumbered to **ADR-117** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 113. In-release citations that read "ADR-113" denote this record.

## Context

This release set out to bring the ADR corpus into conformance with its own standard, and to close an observation that the release module's index was missing entries. Both halves turned out to be claims about a **population that other branches are actively growing**, and that is the property this record exists to reason about.

**The index half was a bigger defect than a coverage gap.** The README did not carry one drifting index; it carried four independent enumerations of the same file set, each with its own maximum, plus a per-cell drift in the one enumeration that mattered — half the rows contradicting the record they linked to on Status, and more than half on Title. A remedy that added the missing rows would have fixed the smallest of the four problems and left the mechanism that produced all four untouched.

**The conformance half cannot be closed the same way, and the difference is a property of the two populations rather than a difference in effort or ambition.** An index gap has a mechanical remedy: one generated row. A conformance gap has an authored remedy: a body section written under a no-fabrication clause, on a record that may be ratified and therefore only hygiene-editable. And the corpus deliberately retains gaps this release was not permitted to close — sections whose backfill would be authoring decision content rather than recording it, and one frozen record that can never conform at all because the immutability policy forbids the two edits it needs.

So the two halves needed different answers, and the failure mode would have been to give them the same one: either overclaiming the conformance half to match the index half, or underclaiming the index half to match the conformance half. Both were available and both are wrong.

## Decision

**(1) The release module's ADR index is a DERIVED surface, projected from the ADR file set, with every column derived.**

The table in `release/ADRs/README.md` is generated by `release/tools/generate-adr-index.py` into a delimited managed region. The record's filename supplies the link; the record's own frontmatter supplies title, status, decision date and originating release. **Nothing in the table is hand-typed**, and a hand-edited cell fails `--verify`.

All five columns are derived, and that is the load-bearing half of the decision rather than an implementation detail. Projecting coverage alone — rows in, rows out — would have closed the missing-record defect and left the stale-Status and stale-Title defects untouched, which between them accounted for more of the wrong information in that table than the missing rows did. **Deriving the cells is what makes status drift structurally impossible; adding rows would only have made it currently-absent.**

The `status:` **leading token** is projected and its sanctioned prose tail is not. A ratification promise is a claim about a future gate; it is tracked on the record and by the ratification-flip backstop, and copying it into a navigation surface would re-create the duplicate-source defect one layer down.

**(2) The mechanism is the existing Derived-Surface Contract, not a new one.** The surface registers in `release/references/standards/release-corpus-schema.md` § Derived-Surface Contract with the same header marker, the same emission-and-custody rules and the same verification posture as the release-ledger instance that contract already governs. There is **no hybrid source column**: unlike the release index's hand-authored theme cell, every column here is derivable, so the projection is whole-table and needs no round-trip integrity limb. The contract requires that split to be declared, so it is declared.

Verification asserts a **set difference in both directions** plus per-cell equality, and prints its own denominators. Both directions are required and the reason is asymmetric: a per-cell comparison alone passes a table that is simply missing a record, and a coexistence check alone passes a table whose every row contradicts its record. This surface carried **both** defects at once.

**(3) The core module's README is a curated thematic document and is NOT converted.** It groups records by theme and links what a reader needs in context; it never enumerated its module's full set and never claimed to. Flattening it into an index would destroy the curation that is its value and create a second hand-maintained copy of a fact each record already owns. The negative is recorded in the file itself and registered in the contract, so the question is closed rather than merely unasked.

**(4) The completeness claim is scoped to a named, reproducible baseline — never asserted as an unbounded universal.** Every conformance criterion this release discharges reads: *every ADR reachable from this branch's own tree at the final Engineering commit, excluding frozen records, satisfies P — derived by this command, whose denominator the command itself prints.* That is honest, because it states what was actually examined; reproducible, because the command and the anchor are both on the record; and not falsifiable by a sibling, because a later merge does not retroactively change what a tree contained.

**(5) The residual is named, in one sentence, and it is not hedging.**

> After this release, an ADR merged from a sibling branch may be non-conformant on the required section set, and nothing in the repository will say so — **the index cannot drift; the corpus can.**

**(6) A delta-scoped structural guard narrows that residual, and its scoping follows the same emptiness argument.** The durability lint gains one structural rule, warn-mode, firing only on an ADR that is net-new against the diff base and missing a section, or on a changed ADR that has **lost** a section it carried at the base. It asserts presence — never position, never a heading-form count — over the frozen-excluded population, and reports a visible skip rather than reading green when no diff base is supplied. The rule and its rejected alternatives are owned by the section-set record it amends, not restated here.

## Alternatives Considered

**On the index mechanism:**

| Option | Verdict | Why |
|---|---|---|
| **Add the missing rows** (the originating observation's own remedy) | **Rejected on measurement** | Closes the smallest of four defects. It leaves three further enumerations drifting, does nothing about the per-cell Status and Title drift that made half the existing rows wrong, and re-creates the coverage gap on the next merge because a hand-typed row is a second copy of a fact the record already owns. |
| **Project coverage only** — generate which records appear, keep the cells hand-authored | **Rejected** | Would have made the missing-row class impossible and left the larger class untouched. More of the wrong information in that table was in the cells than in the absences. |
| **Whole-file generation** (the hook-registry shape: prose as source fragments, assemble everything) | **Rejected** | The README's prose — scope, composition, authoring procedure — is genuinely hand-authored and genuinely belongs to this file. Moving it into fragments to satisfy a projector would relocate content for the tool's convenience and add a directory of files where a delimited region does the same job. Reserved for the case where the prose itself is per-item, which the hook registry's is and this one is not. |
| **A delimited managed region, all columns derived** | **SELECTED** | Confines the projection to the surface that actually drifted, leaves the hand-authored prose where its authors put it, and reuses a marker-plus-region convention the repository already carries in more than one file. |
| **Extend the existing ledger projector** | **Rejected** | Its population is the release ledger, not a file set; it shares the *pattern* and none of the *inputs*. Extending it would have meant two unrelated populations behind one entry point. The pattern is what was extended; the script is new. |
| **Extend the durability lint instead** | **Rejected** | It is the one tool that already reads ADR content, which makes it the tempting host — but it carries a scope declaration, landed one wave earlier in this same release and pinned by its own self-test, that it does not check structural conformance. Extending it to project an index would have broken a deliverable a week old. |

**On the conformance claim:**

| Option | Verdict | Why |
|---|---|---|
| **Assert the universal** — "every ADR conforms" | **Rejected** | Unsatisfiable as literally written, for two independent reasons. One frozen record can never conform, because the two edits it needs are edits the immutability policy forbids on a superseded record. And the population is grown by branches this one cannot see — the claim would have been falsified by a merge that had already happened by the time the release reached its final Engineering slice. |
| **Assert the universal, re-derived at execution** (the prior stage's answer) | **Rejected as necessary but insufficient** | Re-derivation fixes the *denominator*; it does not fix the *claim*. A universal re-derived at noon is still falsified by a merge at one o'clock. Adopted for the denominator, rejected as the claim's form. |
| **Scope to a named baseline + name the residual** | **SELECTED** | States what was verified, how to reproduce it, and precisely what remains unguarded. The audit-baseline discipline applied to a population known to be moving rather than one that merely might be. |
| **Drop the completeness criterion entirely** | **Rejected** | The criterion is discharged for the index half without qualification. Dropping it to match the harder half would discard a real, structurally-guaranteed property because a different property could not be guaranteed. |
| **Block the release on a whole-corpus structural guard** | **Rejected** | It would fire on records this release was explicitly not permitted to fix. Guarding before cleaning, and the delta-scoped rule reaches the same net-new population without it. |

**On the core README:** converting it was considered and rejected under (3). A fifth index — this time generated — over a population the file had never claimed to enumerate would have answered a completeness question nobody had correctly asked.

## Consequences

**Easier.** A merged release ADR cannot be absent from its index, and an index row cannot contradict the record it points at — both are now checked by re-derivation rather than by discipline, on a job that already runs on every ADR-touching pull request. Authoring an ADR loses a manual step and gains a command. The merge-time renumber no longer hand-edits three surfaces in this file; it renames the record and the row falls out of the projection. Three enumerations that could drift are gone, replaced by a statement of the numbering rule, which cannot.

**Harder — and stated plainly.** The repository gains a script and a gate to maintain, which is the honest cost of a projection over a thin index. A contributor who edits a row by hand now gets a failing check instead of a silent divergence; that is the intended behaviour and it will surprise someone at least once, so the region says so in its own text. The index's Title column now shows each record's own `title:` field, which for several records is shorter than the string the README had carried — the README's version was not a summary, it was a copy that had drifted, and the record's field is the one the schema names as authoritative.

**Unchanged, deliberately.** The corpus is not fully conformant to the section set after this release and this record does not claim otherwise. Sections whose backfill would be authoring rather than recording remain out of scope with their blocking authority named, and one frozen record remains permanently non-conformant. The residual in Decision (5) is the honest statement of what that leaves open.

**A residual the conversion surfaced rather than created.** Three release records carry a `title:` that does not begin with the `ADR-NNN — ` prefix the schema specifies, and three carry a `title:` that does not match their own H1. The projector reports each as a visible note and uses the field verbatim rather than normalizing it, because rewriting an identity field to satisfy a projector would be the tool dictating to the record. They are schema-conformance findings on a different axis, left for the surface that owns them.

**The suppression ratchet held; the suppression population did not shrink, and the distinction matters.** The `allow-issue-ref` marker ratchet requires the marked/total ratio to be non-increasing across a release, and it is: `58/114` on the mainline base becomes `58/118` here. **Zero markers were retired.** The marked file set is identical at both ends — 58 files in both, none added, none removed, verified by set difference in both directions with a specificity arm returning zero on a marker token that does not exist. The ratio fell **only because the denominator grew**, from the four records this release adds. The criterion the release discharges is genuinely met — it binds net-new markers and forbids a frozen count, and it does both — but it is a criterion about **not getting worse**, and reading `58/118` as progress would be reading a denominator change as a corpus change. Retiring the existing 58 is a corpus sweep in its own right, graded on that sweep; it is a genuine follow-up rather than a defect in what shipped here, and it is recorded so nobody later infers the reduction from the falling ratio.

## Reversibility

**CHEAP.** Reverting the projection means deleting the region markers and keeping the table as ordinary markdown; the generated content is already the correct content, so nothing is lost in the reversal and no record is touched. The gate is a single workflow step. Reverting the claim-scoping is a wording change in the release's own criteria.

The one edge that is not cheap is the collapsed enumerations, and it is cheap for a different reason: they are recoverable from git, and none of them carried information that is not derivable from the file set. Confidence: **HIGH**.

## Related ADRs

- **ADR-118** (the ADR section set and the durability-hygiene carve-out, same release) — the **companion, not the parent**. ADR-118 governs what an ADR must contain and who may edit it; this record governs how the corpus is indexed and how far a conformance claim over it may reach. Decision (6) here amends nothing in ADR-118; the delta-scoped structural rule and its rejected scopings are ADR-118's own, recorded there.
- **ADR-115** (an ADR number is allocated at authorship and bound at merge, same release) — the numbering half of the same concurrency problem. That record reasons about a number contended across branches; this one reasons about a *claim* contended the same way. The two share a root cause: an answer computed confidently over a population that other branches are still growing.
- **ADR-105** (the release corpus has typed sources, one projector and per-field provenance) — the founding record of the Derived-Surface Contract this surface registers under. This record adds a second family to that contract and re-uses its marker, custody rules and verification posture rather than defining a parallel mechanism.
- **ADR-030** (hook registry drop-in with a generated index) — the second in-corpus instance of a generated index, and the one whose whole-file assembly shape was considered and rejected here for a surface whose prose is not per-item.
- No superseding or superseded relationship. This is the first ADR to govern the ADR index itself.

## References

- #1488 — the ADR-corpus conformance story this record is the design decision for; it supplied the conformance-claim half and the scoping question.
- #3383 — the observation that the release index was missing entries; its two-row estimate is what the four-enumeration measurement corrected, and its remedy is what Alternatives rejects.
- #286 — the release milestone under which the corpus sweep and this record were authored and reviewed.
