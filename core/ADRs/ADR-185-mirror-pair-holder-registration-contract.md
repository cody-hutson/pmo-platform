<!-- reference-durability: allow-link -->
---
title: "ADR-185 — A mirror-pair path-set holder registers itself in-band, and the marker is the contract"
status: Accepted (operator-ratified at the rules-mirror-delivered sub-wave-1 Collective Review, 2026-09-04)
date: 2026-09-04
release: rules-mirror-delivered
deciders: Stage 5 Solutioning spoke (five-candidate design exploration on the registration shape; three canonicalizations grounded against the live corpus) + operator at the sub-wave-1 Collective Review
tags: [mirror-pairs, rules-mirror, deploy-check, registration-contract, arity-generality, single-engine, ADR-030, ADR-008]
source_observations:
  - "Two independent artifacts each declared the source-side mirror-pair path set, and the platform's correctness depended on those declarations being identical. Nothing asserted it. The invariant was stated in prose beside one of the arrays — the shape of an invariant that is asserted nowhere and therefore decays."
  - "The parity held at authoring time as an artefact of the author noticing, not of any control: the release that added three members shipped a one-sided edit at an intermediate commit, and it escaped both the automated check surface and PR review before being caught by hand."
  - "The two holders' separators genuinely differ — one splits on a colon, the other on a literal tab — and so do their array identifiers. Discovery keyed on an identifier returns zero paths from one side and reads as parity, so an identifier-keyed extractor is falsified by measurement rather than by preference."
  - "The consuming code on both sides splits on the FIRST separator occurrence. A last-occurrence split against a value carrying a second separator compares every pair against a path that does not exist, while reporting clean."
  - "A third holder was concurrent rather than hypothetical: the mirror carrier shipping in the same release introduces a copy set of the same paths."
  - "The corpus already carries a machine-greppable in-band declaration idiom of the form `# <token>: k=v`, used inside the deploy script and in a second tree for machine-read declarations. The alternatives are markdown-only or carry no parseable attributes."
  - "A heuristic arm for unmarked holders was measured and deferred: 75 tracked files name two or more of the source paths and three name all of them, of which one is a documentation enumeration needing permanent exemption. A tuned threshold plus an exemption register is a larger surface than the defect."
supersedes: none
---

# ADR-185 — A mirror-pair path-set holder registers itself in-band, and the marker is the contract

## Status

**Accepted** — operator-ratified at the `rules-mirror-delivered` sub-wave-1 Collective Review, 2026-09-04.

**Numbering provenance.** This record was authored at the next-free number computed from the mainline anchor at Engineering Commit 0. An ADR number is *allocated at authorship but claimed at merge*, so a record on a live branch is exposed to every sibling that merges ahead of it; the detector's own branch-claim reading is explicitly non-binding, and pre-reserving a higher slot is no remedy because the contiguity gate fails a gap as readily as a duplicate. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations of this record use the slug token `{{ADR:mirror-pair-holder-registration-contract}}`, which carries no number shape and resolves at the claim.

## Context

More than one tracked artifact independently declares the **source-side mirror-pair path set** — the list of in-repo files that mirror out to the workspace rules directory. One declaration is the *enforced* set: it is what the mirror-sync check iterates. Another is the *topology* set: it is what dependency and impact analysis believes the mirror surface to be. Their agreement is load-bearing and was asserted nowhere.

When a member was added to one and not the other, the two desynchronised **silently**. The impact view then under-reported the mirror consequence of a rule edit while the sync check still enforced it, or the reverse, depending on which side was missed. Neither side errored. Both kept returning clean.

Three facts about the substrate shape the decision, and each is measured rather than assumed.

**The framing "these two agree" is itself the defect.** Writing the assertion pairwise encodes arity 2 in the shape of the check, so the next holder is not covered and the same failure recurs one level of abstraction up. That is not a hypothetical: the mirror carrier shipping in this same release introduces a third holder of the same paths.

**Discovery cannot key on the array identifier.** The two holders name their arrays differently, and their entries use different separators — a colon on one side, a literal tab on the other. An extractor keyed on an identifier returns zero paths from the side that does not use it, and a zero-path holder trivially agrees with everything. The failure mode of a naive shared extractor is therefore not an error but a **false parity**.

**Only the source half is comparable.** One holder's entries expand a deploy-root variable in their second field while the other's second field is repository-relative. The two halves are not in the same form, so a cross-holder comparison is meaningful on the source field alone.

## Decision

**A holder of the source-side mirror-pair path set registers itself, in band, by wrapping its list in a marker pair that declares that holder's own extraction parameters.** The marker is the registration contract. There is no registry file.

The marker form is `# mirror-pair-set: BEGIN holder=<id> sep=<colon|tab> field=<n>` opening the region and `# mirror-pair-set: END` closing it, following the platform's existing `# <token>: k=v` in-band declaration idiom. `sep` is a **word, never a literal character**: a literal tab inside a comment is invisible to a reviewer and a literal colon inside a `k=v` grammar is ambiguous with the `=`.

Four properties are part of the decision, not implementation detail:

1. **The markers sit outside the array literal's own delimiters.** Adding or removing a member edits array rows without touching the registration, so the two edits cannot be confused and a member change cannot silently deregister a holder.
2. **Extraction splits on the FIRST separator occurrence**, matching each consuming holder's runtime semantics byte-for-byte. This is single-engine discipline at the extractor level: the assertion's notion of "the source path" is identical to the consuming code's.
3. **Fewer than two discovered holders is a FAILURE.** "All holders agree" over zero or one holder is vacuously true, and a pass in that state is indistinguishable from a working check. Zero holders is an input failure — the marker convention moved — and exits distinctly rather than reading green.
4. **A marker that announces itself but does not satisfy the grammar is reported, not skipped.** A typo'd marker that reads as "not a holder" would deregister the holder and restore exactly the silence being removed.

**The contract binds every future holder.** Any artifact that declares its own copy of the source-side path set MUST carry a marker pair with a distinct holder id. Reusing an existing holder's array in place is preferred and satisfies the contract trivially — a holder that cannot desynchronise beats one whose desynchronisation is merely detected.

## Alternatives considered

**Pairwise hardcoded comparison** — two inline extractions and a sorted diff, the "roughly five lines of shell" the originating observation proposed. **Rejected**: it fails the arity requirement by construction, because the shape encodes arity 2. Adding a third holder is a rewrite, not an edit. It is the defect restated one level of abstraction up.

**A central holder registry** — a tracked allowlist file with one row per holder. **Rejected**, and this is the decision's closest call, because the platform does ship allowlists of exactly this shape and both options make holder N+1 a one-line change. The tiebreak is *where the line goes*. In a registry it goes in a **different file from the holder** — a second place to forget, which is the identical two-place-update failure this decision exists to close, relocated from the pair set to the registry. In-band, it goes **inside the holder**, so forgetting to register and forgetting the holder are the same act. A registry is also a fourth list of the same kind, answering "who holds the list of holders?" with another list.

**Single-source generation** — one canonical data file both consumers read, dissolving the parity problem rather than asserting it. **Rejected here and RECORDED AS THE NAMED SUCCESSOR.** It is the better end state, and it is deliberately not the state this decision reaches, for a measured reason: the deploy script is the fresh-install entrypoint, so an absent or partial external data file yields a **silently empty enforced set** — the enforced list would read as zero members and every pair would trivially pass. This decision makes divergence loud; that one would make one specific absence silent. It becomes correct once a carrier makes the single source verifiable at build time, and should be revisited then.

**In-band markers plus a heuristic arm** for unmarked candidate holders. **Deferred, not rejected** — it narrows the residual below to a detectable warning, but needs a tuned threshold *and* an exemption register, which is a larger standing surface than the defect being closed.

## Consequences

**Adding holder N+1 costs one marker pair inside the new holder and zero change to the asserting check.** That is the property the decision was chosen for, and it is what makes the concurrent third holder safe rather than a re-litigation.

**A member add or removal becomes a checked multi-file edit.** Removing a member from one holder and not another now fails the assertion naming both the path and the lagging holder, on the pre-merge surface as well as after merge.

**Accepted residual: a holder authored WITHOUT a marker is invisible to the assertion.** No discovery mechanism removes this without guessing, and the guessing was measured and found more expensive than the defect. It is closed **contractually** by this record rather than heuristically, with the mirror carrier as the contract's first bound consumer. If a holder ever appears outside the marker set, the deferred heuristic arm is the recorded remedy.

**A scanner that discovers markers by line will discover its own examples.** Any file documenting the marker — this record included — must quote it in a form that does not match, or it registers itself as a broken holder. This is not hypothetical: the primitive's first live run discovered its own docstring and fixtures and correctly reported them unparseable. Documentation of the marker is box-quoted for that reason, and the primitive carries a self-test asserting its own source registers zero holders.

**The assertion reads only tracked source text, and that is why it can run pre-merge.** The pre-merge roster admits a check only when it is network-free, install-independent, posture-required, and lacks a dedicated mirror workflow. Reading source text rather than a deployed tree satisfies all four. The pre-existing mirror-sync check cannot join that roster, because its verdict is install-dependent — it diffs against a workspace directory that is absent in CI and the public repository, where it correctly skips. Folding parity into that check's body would have made parity inherit the install-dependence and be permanently barred from the one surface where the original defect escaped. That is the reason the assertion is a **new check adjacent to** the mirror-sync check rather than an extension of it.
