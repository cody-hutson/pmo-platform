---
title: ADR-234 — Issue-body section reads are single-sourced in the bundle parser, and a section ends only at structure
status: Proposed — authored at Engineering Commit 0 of the sequencing-layer-foundation release; ratified at that release's Stage 13 Close
date: 2026-11-05
release: sequencing-layer-foundation
deciders: "Workspace owner (Stage 4 plan gate and Collective Review scope lock); design authored by the joint Stage 5 Solutioning spokes and revised on the Phase A6.5 adversarial review's counter-design"
tags: [release-pipeline, issue-body-parse, single-source, section-extractor, duplicate-logic, gate-measurement]
source_observations:
  - "The A3.5 dependency mirror carried its own section extractor — a verbatim copy whose docstring said it mirrored the bundle parser's semantics, with the same two-blank-line terminator. A repair to one copy could not reach the other; the 2026-09-20 root-cause records on both cards called two in-place repairs a deferral of the class fix."
  - "At the 2026-09-26 readiness read, a heading followed by two or three blank lines returned an empty string in both copies: Dependencies read as an empty set with status clean, Affected Files as failed (lowering the G3-14 rate), Acceptance Criteria as present with zero criteria, and the mirror mirrored zero dependencies while exiting 0. An empty string was also what a genuinely empty section returned, so no caller could tell the two apart."
  - "On the 2026-11-05 snapshot, dropping the gap terminator changed the Affected Files, Dependencies and Acceptance Criteria parse of 0 of 810 open bodies, while the Stage-5 design that kept it would have flipped 8 of 8 eligible frozen G3-14 sample bodies from clean to failed on one doubled internal blank line."
  - "All 11 gap terminations observed on the 2026-11-05 snapshot and the frozen sample (1 live, 10 frozen) stopped a section just before a `---` separator line followed by an HTML marker comment."
  - "At Engineering Commit 0 (2026-11-05), the repaired extractor and the pre-repair one produced identical caller output on 814 of 814 open bodies and 40 of 40 frozen bodies; 3 live sections end at a break line with no gap before it, each followed by a provenance footer that changes no read."
  - "G3-14 counts only `clean` and `failed`; Check 22 reads Acceptance Criteria presence as a two-field contract; the two G3-20 readers test `extract_section(...) is not None`."
supersedes: none
---

# ADR-234 — Issue-body section reads are single-sourced in the bundle parser, and a section ends only at structure

## Status

**Proposed** — authored at Engineering Commit 0 of the `sequencing-layer-foundation` release, after the operator's Collective Review scope lock rendered the decisions it records. It is ratified at that release's Stage 13 Close; the ratification is recorded in this file's frontmatter `status:` field and is never inferred from a review comment or from milestone closure.

**Numbering provenance.** Claimed as **230** against an anchor of **229** on `origin/main`, read from `release/tools/renumber-adr.py --detect --mainline-ref origin/main` at Engineering Commit 0. The detector also reported branch-only claims on 230 and 231 on other release branches; a branch claim is detection-only and never binds, so this record takes the mainline next-free slot rather than stepping above them. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Other branch-authored artifacts cite this record by the ADR slug token carrying the slug `issue-body-reads-single-sourced-in-the-bundle-parser`, which has no number shape and resolves at the claim.

**Numbering provenance — `230 → 234`.** Held **ADR-230** branch-local; renumbered to **ADR-234** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 230. In-release citations that read "ADR-230" denote this record.

## Context

Two release tools read issue bodies section by section: the bundle parser, whose parse rate is the measured quantity behind gate G3-14, and the native-dependency mirror that Stage 2 Triage runs to project a body's `Blocked by` edges onto the tracker's native surface. Each carried its own section extractor. The mirror's copy said in its own docstring that it mirrored the parser's semantics, and a repair that lands in one copy does not reach the other.

Both copies ended a section at the next H2 or H3 heading or at the first run of two blank lines. The blank-line search began at the heading line's own newline, so a heading followed by two blank lines matched that run at offset zero and returned an empty string. An empty string is also what a genuinely empty section returns, so every caller read the misread as "present and empty". The parser's three readers erred in two directions: Dependencies toward a clean read, Affected Files toward a failed one that lowered the gated rate, and Acceptance Criteria toward a false emptiness finding. The mirror silently mirrored no dependencies at all. One newline moved a gated measurement.

The same release moves the dependency direction grammar out of the mirror into a shared home, so where the extractor lives also decides where the grammar lives, and the two moves have to agree on direction or they form an import cycle. The parser is loaded alone, by path, by three readers — the deploy check's priority and acceptance-criteria delegates, the milestone position tool, and a degraded-root test that copies only the parser — so whatever the parser loads at import, they must load too.

## Decision

1. **The bundle parser is the single home.** `release/tools/bundle-issues-parser.py` owns the issue-body section extractor — `extract_section`, `extract_section_aliased`, and `extract_section_with_alias`, which returns the matched heading alias with the section for a reader whose heading confers direction — and the dependency heading alias list. The dependency direction grammar moves into the same home in the grammar slice of this release. No third module is created.
2. **The mirror loads the parser; the parser loads nothing local.** `native-dep-mirror.py` loads the parser by path, relative to its own file, through a loader that never raises, and binds every name it exposed before from the loaded module, so no caller of the mirror changes. When the parser cannot be loaded, the mirror's run and its self-test exit 2 — its infrastructure-failure class — rather than tracing back at import. The dependency runs in one direction only, so there is no cycle, and the parser's standalone loaders are untouched.
3. **A section ends only at structure.** A section runs from its heading to the next H2 or H3 heading or to a break line — three or more hyphens, indented at most three spaces, with optional trailing spaces or tabs, matched with a carriage return tolerated so a CRLF body reads like an LF one. A run of blank lines never ends a section. The extractor still returns a plain string for a present heading — empty or blank when the next heading or break line follows directly — and `None` only for an absent heading, so every caller keeps its contract. Leading blank lines are kept as they always were; the only change a caller sees is a section no longer cut short at a blank-line gap, or ended at a break line it used to read past.

## Alternatives Considered

**Where the extractor lives.**

- *Two in-place repairs.* Rejected: it keeps the duplication that produced the twin defect, which the duplicate-source discipline's register-or-remove rule forbids, and both root-cause records called it a deferral of the class fix.
- *Each tool loads the other* (the parser loads the mirror for the grammar, the mirror loads the parser for the extractor). Rejected: an import cycle.
- *The mirror is the home.* Rejected: the parser would have to load the mirror — a tool that writes native tracker state — which breaks every reader that loads the parser alone, or forces a fallback copy, which is the duplication again.
- *A new shared module* both tools load (the precedent is the deploy tooling's shared frontmatter reader). This is the opposing view, and the strongest one. It was rejected because extending the parser in place meets every constraint — acyclic, standalone-loadable, already the seam the next reader extends — so a net-new module has no in-place-infeasibility reason under ADR-094, and it would give the parser a load dependency that its degraded-root test and the deploy check's delegates would then have to carry.
- *Make the tools an importable package.* Rejected on blast radius: it renames hyphenated tool paths that allowlist rows, CI steps, skills and documents cite, a structural change where a behavioural one suffices.

**How a section ends.**

- *Keep the two-blank-line terminator, skip leading blank lines, and return a distinguishable degraded record* when a gap ended a read with text still following — the Stage-5 design. Rejected at the Collective Review on the adversarial review's counter-design: it moves the whitespace sensitivity rather than removing it, because one doubled blank line inside a section would then turn a gated read from clean to failed; it changes the return contract of every caller and adds two record types; and the gap terminator's only observed job — stopping a section before a separator footer — changes no caller's output once the break line ends the section instead.
- *A degraded state spelled `None`.* Rejected: both G3-20 readers test `is not None`, so a present-but-misheaded declaration would read as absent.
- *Raise on a degraded read.* Rejected: one such body would make the deploy check's delegate fail for the whole population.
- *End also at any thematic break (`***`, `___`), or strip HTML comments before reading.* Not adopted: the decision names the hyphen break line, the separator issue bodies actually use; the wider forms carry no observed case.
- *Skip leading blank lines.* Not adopted: once no whitespace ends a section, skipping them has no reading effect, and it would change the text every caller receives.

## Consequences

- One extractor: a repair lands once, and the two tools cannot drift apart on how a section reads.
- The gated parse rate no longer moves on blank-line count anywhere in a section — after a heading or inside it.
- The parser's public names become a two-tool contract. Renaming or removing one breaks the mirror's binding at load, and the mirror reports that as exit 2 rather than misreading.
- Text after a blank-line gap that is neither an H2 or H3 heading nor a break line now joins the section. Un-headed trailing text a body appends to a section is read as part of it. The authoring-time measurement found no case where that changes a read; the residual is recorded at MEDIUM confidence for bodies not yet written.
- A break line now ends a section where the old extractor read past it, including a hyphen line inside a fenced example — the extractor was already fence-blind for headings.
- Later readers — the release's chain-head view, and a shared acceptance-criteria reader planned after this release — read through this home rather than adding a reader of their own.

## Reversibility

**CHEAP** while nothing builds on the home: one merge revert restores both copies and the old terminator, and no persisted state depends on the change. **MODERATE** once a later reader is built on this seam, because reverting then strands that reader.

## Related ADRs

- ADR-111 — a consumer of an issue-body field reads it through the shared detector; this record extends that rule to a second tool and fixes how the detector ends a section.
- ADR-094 — extend-before-create: in-place extension wins over a new module when it meets every constraint.
- ADR-181 — ADR citations bind at the claim, which is why branch artifacts cite this record by its slug token.

## References

- #7177 — the card: a heading carrying two blank lines read as an empty section, so a declared dependency vanished.
- #6397 — the card that moves the dependency direction grammar into the same home.
