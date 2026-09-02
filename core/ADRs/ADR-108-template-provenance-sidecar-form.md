<!-- reference-durability: allow-link -->
---
title: ADR-108 — The provenance sidecar is a full-filename `.provenance.yml` carrying the whole L4 header
status: Accepted
date: 2026-08-03
release: governance-hardening
deciders: "Workspace owner — ADR-107 named the class and routed the sidecar's filename form and field set forward to the work that generalizes the placement convention. This is that work. Designed and authored at Stage 6 against the Stage-5 architecture assessment, whose DD-4 selected the sidecar mechanism (M3) after independent review falsified the registry-binding alternative."
tags: [templates, provenance, sidecar, yaml, template-protocol, placement-convention, reversibility-cheap]
source_observations:
  - "ADR-107 decided that a payload-frontmatter template carries its provenance in a sidecar, and explicitly left the sidecar's filename form and field set undecided, naming the placement-convention work as the owner."
  - "Two sidecar forms are live in the corpus and they describe different subjects. Two `.meta.yml` files carry the PRODUCED artifact's born frontmatter for a format that cannot hold it inline. Zero `.provenance.yml` files exist; the form is declared by the protocol and never written to."
  - "The protocol's own CSV paragraph is internally inconsistent: the rule says `<file>.provenance.yml` (append) and the worked example replaces the extension. With zero files on disk, nothing had yet forced the ambiguity to resolve."
  - "The provenance field set is fifteen fields, twelve of them Required. The slot-ownership problem is a problem for the whole header, not for any one field — relocating a single field would leave the other fourteen unplaced."
  - "A coverage probe that reads only `operations/templates/*.md` cannot see a sidecar. Under any sidecar route, such a probe reports every sidecar carrier as un-provenanced, permanently and silently."
---

# ADR-108 — The provenance sidecar is a full-filename `.provenance.yml` carrying the whole L4 header

## Status

**Accepted.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. Per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes in-flight pull-request claims. Allocated at commit time: the union of both directories reported a contiguous `001..107` with no gaps and no duplicates, and the only open pull request is this release's own, so this ADR takes **108**. Referenced by **slug** (`template-provenance-sidecar-form`), never by integer.

## Context

[ADR-107](ADR-107-payload-frontmatter-template-provenance.md) established that a **payload-frontmatter template** — one whose top-of-file YAML block is the born-entity frontmatter of the artifact it produces — carries its L4 provenance header in a sidecar rather than inline. It named the class, listed its then-known members, and stated the mechanism. It then recorded one item as **deliberately not decided**: *the sidecar's filename form and field set*, routed to "the work that generalizes the placement convention."

This is that work. The generalization of `template-protocol.md` §4.4 — from *CSV templates* to *any template whose inline frontmatter slot is owned by another schema* — cannot ship without answering both questions, because it is the change that first causes sidecar files to exist.

**What the corpus offered, and why it did not settle it.** Two forms are live and they are not competitors:

- `<file>.meta.yml` — **two** files, both carrying the *produced artifact's* born frontmatter (`type: tracker`, `domain: managed`, `trust_category:`) for a CSV whose format cannot hold it inline. This is the **payload** sidecar.
- `<file>.provenance.yml` — declared by `template-protocol.md` §4.4 for CSV provenance, with **zero** files written to it. This is the **provenance** sidecar.

They describe different subjects: one is metadata about the *artifact the template renders*, the other is metadata about the *template file itself*. Reading them as two spellings of one thing is the error; the reconciliation is a role distinction, not a merge.

**The declared form was itself ambiguous.** §4.4's rule said `<file>.provenance.yml` and its worked example wrote `raid-log-template.provenance.yml` for `raid-log-template.csv` — appending in the rule, substituting in the example. With no files on disk the contradiction had never been forced.

**And the field set was open in a way that mattered.** §4.2 defines **15 fields, 12 Required**. An earlier candidate design proposed relocating `template_family` alone to a registry column. Independent review falsified it on the field-count argument among others: slot ownership blocks the *whole* header, so moving one field leaves fourteen unplaced and the templates still un-provenanced.

## Decision

**A provenance sidecar is `<full template filename>.provenance.yml`, in the same directory, carrying the entire §4.2 header — all 15 fields, the 12 Required ones included — verbatim and unchanged.**

**Filename: append, never substitute.** `person-entity-template.md` → `person-entity-template.md.provenance.yml`. `raid-log-template.csv` → `raid-log-template.csv.provenance.yml`. Two reasons, both structural rather than aesthetic:

1. **Substitution collides.** A family shipping both a `.md` and a `.csv` template would resolve both to one `<stem>.provenance.yml`. Appending keeps the mapping injective for every possible registry state, not merely the current one.
2. **Substitution discards information.** The provenance describes a specific file, and that file's format is part of its identity — `canonical_path` and the P5 gate both read it. Dropping the extension from the sidecar's own name makes the sidecar describe a stem rather than a file.

Appending also matches the construction the corpus already runs on the payload side (`raid-log-template.csv.meta.yml`), so the two sidecar families are named by one consistent rule.

**Field set: the whole header, unchanged.** The sidecar is a **placement** decision, never a schema variant. There is exactly one provenance schema and exactly one set of gate-evaluation inputs; the sidecar changes only which path they are read from. A subset would fork the contract and force every consumer and every gate to carry two read paths for one schema — the cost that made the single-field alternative wrong, reproduced at a smaller scale.

**The two sidecar roles coexist, and neither is renamed.** `.meta.yml` carries the produced artifact's frontmatter; `.provenance.yml` carries the template's L4 header. A single template may legitimately own both. This is the reconciliation ADR-107 routed forward: **complementary by subject, not competing by form.**

**Any coverage check over template provenance must read both placements.** A probe scoped to `operations/templates/*.md` under-reports by exactly the sidecar population. The obligation is stated in §4.4 with the two-glob form, because a check that silently under-reports is worse than no check: it reports the sidecar carriers as un-provenanced forever and gives a false clean on the population it can see.

### Scope

| | |
|---|---|
| **Decided here** | The sidecar's filename construction, its field set, and that `.meta.yml` and `.provenance.yml` are complementary rather than competing. |
| **Bound downstream** | Every future sidecar uses the append form and carries the full header. Any provenance coverage check reads both globs. A template may own both sidecar kinds without either being wrong. |
| **Not decided here** | Whether the two CSV templates now owe a `.provenance.yml` in addition to their existing `.meta.yml`. Under this decision they do, and the form is now unambiguous — but authoring them is a different population from this card's twelve and is left to the work that owns the CSV registry rows. |
| **Not decided here** | Enforcement. Nothing in `core/deploy/`, `.github/`, or `core/config/` validates provenance presence or family-enum membership today, and this ADR adds no check. The obligation above is a stated contract, not a gate. |

## Alternatives Considered

**Substitute the extension** (`person-entity-template.provenance.yml`). This is what §4.4's worked example implied, and it reads more cleanly. **Rejected** on the collision and information-loss arguments above. The tidier name is not worth a mapping that stops being injective the first time a family ships two formats.

**Adopt `.meta.yml` for both roles**, since it is the form with files actually on disk. **Rejected**: it collapses two distinct subjects into one filename, so a reader — and any future check — could not tell whether a given sidecar describes the template or the artifact the template renders. The existing `.meta.yml` files would also have to be re-interpreted retroactively, changing the meaning of shipped files to save a suffix.

**Nest the provenance under a distinct key inside the occupied block.** Considered and rejected in ADR-107 for the payload class, on the grounds that it forks the read path and leaks template metadata into every rendered instance. Nothing in the filename-form question revives it.

**Carry only `template_family` on some other surface and leave the rest.** The candidate design independent review falsified. **Rejected**: 15 fields, 12 Required — the slot is occupied for all of them, so a one-field answer resolves one-fifteenth of the problem while adding a second binding surface for a field that already has a conforming one.

**Leave the form undecided and let each author choose.** **Rejected**: this is the status quo that produced the ambiguity, and it stops being survivable the moment the first sidecar file exists. Seven exist as of this release.

## Consequences

**Positive.**

- The generalization of §4.4 can ship, and with it the seven sidecars that unblock the entity templates' provenance. ADR-107's deferred item closes with a named owner rather than aging.
- The `.meta.yml` / `.provenance.yml` question resolves without renaming or reinterpreting any shipped file. Both forms keep their meaning; what changes is that the distinction is written down.
- A pre-existing internal contradiction in §4.4 is corrected at the moment it would first have mattered, rather than after files had been authored on both readings.
- The naming rule is total: it produces a unique sidecar name for any template in any format, so no future registry state can force a re-decision.

**Negative, and accepted.**

- **The filename is long and doubly-suffixed.** `person-entity-template.md.provenance.yml` is not elegant. This is the accepted cost of an injective, format-preserving mapping.
- **Provenance for these templates lives in a second file.** A reader who opens only the template does not see it. Inherent to the sidecar route; the same cost the CSV case already carried in principle.
- **The obligation to read both globs is stated, not enforced.** No check exists to validate it, so a future coverage probe can still be written single-glob and silently under-report. Enforcement is named as absent rather than implied.
- **The two CSV templates are now knowably owed a `.provenance.yml` that this release does not author.** The gap is smaller and better-specified than before, but it is a gap, and it is stated rather than quietly carried.

**Verification.** Checkable by: confirming every sidecar on disk is named `<full template filename>.provenance.yml` and resolves to an existing template; confirming each parses as exactly one YAML document whose key count equals the shipped inline exemplar's; confirming the two-glob probe returns the full provenance population where the single-glob probe returns strictly fewer; and confirming §4.4 states one filename rule with no contradicting example.

## Reversibility

**CHEAP / Confidence HIGH.** The decision surface is one protocol section plus seven additive sidecar files; nothing executable changes, no template body is restructured, and no shipped file is renamed. `git revert` restores byte-for-byte, and the governed forward path is a successor ADR under the immutable-ADR rule.

Confidence is HIGH because both open questions were settled against measured state rather than preference — the `.meta.yml` files were read and found to carry a different subject, the field count was re-derived from §4.2 (15 total, 12 Required) rather than transcribed, and the sidecars were validated to parse as single documents with a key count matching the shipped inline exemplar. The one judgment call, append-versus-substitute, rests on an injectivity argument that holds for registry states the corpus does not yet contain, which is the property a naming rule needs.

Cost of reversal rises once sidecars are consumed by an automated check. None is today, which is the argument for settling the form now rather than after one exists.

## Related ADRs

- **ADR-107** — named the payload-frontmatter class, decided that it takes the sidecar route, and explicitly deferred the filename form and field set to this record. This ADR closes that deferral and changes nothing ADR-107 decided.
- **ADR-050** — settled that the `domain`-named fields are not renamed. Unaffected: this decision renames no field and moves no value, it only fixes where a header file lives and what it must contain.
