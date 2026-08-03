<!-- reference-durability: allow-link -->
---
title: ADR-107 — Payload-frontmatter templates carry their provenance header in a sidecar, not inline
status: Accepted
date: 2026-08-03
release: governance-hardening
deciders: "Workspace owner — the operator assigned the key-collision decision to the domain-disambiguation card at the Stage-4 re-plan gate, expressly separating the DECISION from the migration. Designed and authored at Stage 6 against the reused Stage-5 architecture assessment."
tags: [templates, provenance, frontmatter, yaml, domain-token, duplicate-key, sidecar, template-protocol, reversibility-cheap]
source_observations:
  - "Seven canonical templates carry a `domain:` key whose value space is disjoint from the one the template provenance header requires. Both schemas call their field the three-domain classification and both mark it required, so the names match and the meanings do not."
  - "Duplicate keys in one YAML document resolve last-wins with no error. A provenance header written into the occupied slot would silently delete the value every artifact these templates produce is born with — no parser complains, no gate fires."
  - "Two cards in the same release routed these seven templates to a disambiguation registry as though it would unblock them. A registry maps a token to a concept; it does not change a YAML document. Each card's reasoning was locally correct and no card owned the resolution — an absent dependency edge, not a missing one."
  - "The seven templates' frontmatter is not metadata about the template. It is the born-entity frontmatter of the artifact the template produces, copied into the instance verbatim. One of the seven says so in an inline comment directly beneath the block."
  - "Every template whose frontmatter IS its own provenance header carries an explicit marker telling readers not to copy the block into a rendered instance. Nine of nine carry it; zero of the seven do. The two populations are structurally distinguishable, not merely differently populated."
  - "The template protocol already routes provenance to a sibling file when the frontmatter position holds data rather than metadata — its stated rationale for CSV templates. The corpus already runs the mirror of that convention on the payload side, carrying a produced artifact's frontmatter in a sidecar for the two CSV templates whose format cannot hold it inline."
---

# ADR-107 — Payload-frontmatter templates carry their provenance header in a sidecar, not inline

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes in-flight pull-request claims, not only what is on the mainline. Allocated at commit time: the ADR-numbering tool reported a contiguous `001..106` with no duplicates, so this ADR takes **107**. Referenced by **slug** (`payload-frontmatter-template-provenance`), never by integer, so the number re-resolves if a concurrent release claims 107 first.

## Context

The bare token `domain` names six different concepts in this corpus. Five of them never meet; the corpus-wide index of all six is `core/specs/domain-token-registry.md`, shipped alongside this record. **Exactly two can meet in one file, and they do, in exactly seven files.**

- **Artifact-provenance** (`core/schemas/frontmatter-schema.md` § Category 6) classifies an artifact *instance* by where it came from: `source` | `managed` | `generated`.
- **Template-provenance** (`core/standards/template-protocol.md` § 4.2) classifies a *template structure* by canon family and rendered-output audience: `project` | `software` | `platform-internal`.

Both are called *"three-domain classification"* at their own owning files. Both are marked required. **Their value spaces are disjoint.** A file carrying both carries two `domain:` keys meaning two unrelated things.

**Seven canonical templates are in exactly that position.** Each produces a managed project artifact — a tracker, or a project page — and each carries that artifact's born-entity frontmatter at the top of the file, `domain: managed` included, with placeholders the instantiating skill substitutes. That block is the template's **payload**: it is copied into the produced artifact, not read as metadata about the template. One of the seven states this directly in a comment beneath the block, naming it the born-entity frontmatter of the produced entity.

So the frontmatter slot — a markdown file has exactly one — is **occupied**. Every template also owes a provenance header, and that header carries a `domain:` of its own.

**The failure mode is silent, which is why this needs a decision rather than a sweep.** Writing the provenance header into the occupied block puts two `domain:` keys in one YAML document. Duplicate keys resolve **last-wins with no error**: no parser complains, no gate fires, and the produced artifacts simply start being born with the wrong provenance — or with a value from a disjoint enum that no consumer of concept 2 can interpret. The loss surfaces downstream, far from the edit that caused it.

**Why no card owned this.** Two cards in this release route these seven templates to the disambiguation registry as though authoring it would unblock them. It cannot: a registry maps a token to a concept, it does not change a YAML document. And the registry's own governing decision, ADR-050, forbids the rename that would dissolve the collision. Each card's reasoning is individually correct — the registry card refuses to rename, the sweep cards decline to force a header onto a colliding key — and each assumed another would close the gap. **This is an absent dependency edge, not a broken one.** It was surfaced by reading the release's cards as one system rather than one at a time, and the resolution was assigned to this card expressly as a **decision**, separated from the migration that follows it.

## Decision

**The seven templates form a named class — *payload-frontmatter templates* — and that class carries its L4 provenance header in a sidecar file, never inline.**

A **payload-frontmatter template** is a template whose top-of-file YAML block is the born-entity frontmatter of the artifact it produces, copied into the instance rather than read as metadata about the template. The class today is exactly:

`operations/templates/communications-tracker-template.md` · `daily-status-log-template.md` · `milestone-tracker-template.md` · `open-meetings-tracker-template.md` · `project-md-composed-index-template.md` · `sprint-tracker-template.md` · `transcript-register-template.md`

**They are resolved, not exempt.** These seven owe a provenance header exactly as every other canonical template does — an owner, a family, a lifecycle state, a canonical path. What blocks them is one occupied slot, and the corpus already holds the mechanism that unblocks it.

**The mechanism is the placement convention that already exists, applied on its own stated rationale.** The template protocol routes provenance to a sibling file for CSV templates, and the reason it gives is that the file's own frontmatter position *holds data, not metadata* — a CSV's header row is data. A payload-frontmatter template is in the identical position, reached by a different cause: the slot holds data because the template's product owns it, not because the format cannot hold YAML. **Same predicate, different cause.** The corpus already runs the mirror of this convention on the payload side, carrying a produced artifact's frontmatter in a sidecar for the two CSV templates whose format cannot hold it inline — so both directions of the sidecar are established practice, not invention.

**The class is readable from the file, not inferred from absence.** Every template whose frontmatter *is* its own provenance header carries an explicit marker instructing readers not to copy the block into a rendered instance — nine of nine carry it. **Zero of the seven do**, and one carries the opposite marker naming its block as the produced entity's born frontmatter. A future reader classifies a template by reading it, not by observing that a header is missing.

**This decision renames nothing.** All six `domain`-named concepts keep their field names, and the `domain: managed` in each of the seven stays exactly where it is, byte for byte. ADR-050's rejection of the rename stands and is not amended.

### Scope — what this decides and what it hands on

| | |
|---|---|
| **Decided here** | That the class exists, which seven files are in it, that they are resolved rather than exempt, and that the resolution is the sidecar route. |
| **Bound downstream** | A provenance-header sweep **must not** insert an inline header into any of the seven. The same sidecar carries the template's `template_family`, for the same reason and by the same route. A coverage check over template provenance must read sidecars as well as inline blocks, or it reports these seven as un-provenanced forever. |
| **Deliberately not decided** | The sidecar's **filename form and field set**. Two forms are live — a `.meta.yml` suffix in use today, and a `.provenance.yml` form the template protocol declares with zero files yet written to it. Reconciling them belongs to the work that generalizes the placement convention. |
| **Deliberately not done** | The migration. No sidecar file is created by this decision. Authoring the seven is separate, sequenced work, and this record is what lets it proceed against an answer instead of an assumption. |

## Alternatives considered

**Declare the seven a permanently-exempt class.** This was the other disposition explicitly on the table, and it is the cheaper one — it requires no sidecar and no follow-on work. **Rejected**, because the exemption would be permanent for a *removable* cause. Nothing about these seven makes them intrinsically un-provenanced; they are ordinary canonical templates that happen to have a full frontmatter slot, and the mechanism that frees the slot already exists in the protocol that governs them. Three costs make the exemption worse than it looks: the provenance population becomes permanently un-auditable, since every future coverage check must carry a seven-file special case forever; `template_family` is stranded for the same seven by the same argument, which is the exact outcome the taxonomy work exists to prevent; and an exemption granted for a mechanical reason tends to be read later as a statement that these templates *don't need* provenance, which is not true and was never the finding.

**Rename one of the two fields.** This dissolves the collision at the root and is the intuitive fix. **Out of scope and settled**: ADR-050 rejected renaming the pre-existing `domain`-named fields and prescribed a disambiguation note instead. Re-opening it here would require superseding that ADR, not merely noting an exception. The live blast radius is also worse than the figure ADR-050 reasoned from — 44 declarations across 39 files in markdown alone, plus sidecar carriers outside that sweep, plus the SQLite projections of the same concept, plus an unfinished deprecation migration on that very field. **Renaming a field during an unfinished migration of the same field is the strictly worse sequencing**, independent of the merits.

**Nest the provenance header under a distinct key inside the existing block** — for example a `template_provenance:` mapping holding the L4 fields. This keeps everything in one file and does resolve the duplicate-key problem. **Rejected** because it forks the provenance schema: the seven would carry their header at a different path from the other canonical templates, so every consumer and every gate would need two read paths for one contract. It also puts template metadata inside a block that is copied into the produced artifact, so instances would inherit provenance about the template that produced them — a second, subtler correctness problem in place of the first.

**Leave it undecided and let the sweep cards handle it.** This is the status quo, and it is what produced the gap. **Rejected**: it ships a release in which two cards assert an unblock that does not occur, and the first naive inline insert triggers the silent deletion. Where a decision has an owner and a deadline, "the next card will handle it" is how it acquires neither.

## Consequences

**Positive.**

- The gap closes with a named owner. Two downstream cards route to an answer rather than to an assumption, and the seven templates have a stated path to provenance instead of an indefinite hold.
- **The silent-deletion failure is converted into a stated prohibition.** The failure mode's whole danger was invisibility; a sweep author now has a written instruction not to touch these seven inline, rather than a hazard they would have to rediscover.
- The class is defined by a **readable structural property**, not by a file list. A template authored next year whose frontmatter is its product's payload is in the class by construction, and the seven-file enumeration is a snapshot of the class rather than its definition.
- No mechanism is invented. The resolution generalizes a convention already in the governing protocol, on that convention's own stated rationale — so the follow-on work is an extension with a precedent, not a new abstraction needing its own justification.

**Negative, and accepted.**

- **Provenance for these seven lives in a second file**, so a reader who opens only the template does not see it, and any tool reading provenance must know to look. This is inherent to the sidecar route and is the same cost the CSV case already pays.
- **The seven remain without provenance until the migration lands.** This record unblocks that work; it does not perform it. Until then the templates are correctly classified as pending rather than exempt — a better state than before, but not a finished one.
- **The sidecar's exact form is still open**, with two live conventions in the corpus and no reconciliation. Deciding it here would have pre-empted the work that owns the placement convention; leaving it open means the follow-on work carries one more decision than it otherwise would.
- A future maintainer could read the seven-file list as the class definition and miss a new member. The structural marker described above is the mitigation, and it is stated in both this record and the registry so the list is never the only signal.

**Verification.** The claims are checkable by: counting templates carrying the do-not-copy marker against those that do not, and confirming the partition matches the inline-header partition exactly; confirming no template in the corpus carries two `domain:` keys; confirming this ADR references its own decision by slug rather than by integer; and confirming the registry's §3 names the class, its disposition and the seven files.

## Reversibility

**CHEAP / Confidence HIGH.** This record and its registry index entry are two documentation surfaces; nothing executable changes and no file is migrated. Reverting the release restores the prior state exactly, and the governed forward path is a successor ADR under the immutable-ADR rule rather than an edit to this one.

Confidence is HIGH because the decision rests on a structural property that was measured rather than assumed — the two template populations partition exactly on an explicit in-file marker, with the complementary counts closing against the whole population — and because the mechanism chosen is one the governing protocol already carries for the same stated reason. The one genuinely open question, the sidecar's exact form, is named as open rather than resolved by assumption.

The **commitment** recorded here is likewise cheap to revisit: no artifact yet depends on it. That changes once the seven sidecars exist, at which point moving to a different resolution becomes a migration rather than a decision — which is the argument for recording the decision *before* the migration, not after.

## Related ADRs

- **ADR-050** — settled that the `domain`-named fields are **not renamed** and prescribed a disambiguation note as the fix. This ADR operates strictly inside that constraint: it resolves the one place two `domain` concepts collide, without renaming either. The disambiguation note ADR-050 prescribed ships in this same release as `core/specs/domain-token-registry.md`, whose § 3 is this decision's index entry.
- **ADR-062** — the substrate-vs-canonical precedent under which a card's body is preserved as historical record and corrections land in the live surface rather than by rewriting the ticket. The framing this decision corrects — that a registry could unblock the seven — is left standing in the originating cards and reconciled here.
