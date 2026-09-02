<!-- reference-durability: allow-link -->
---
title: ADR-173 — ADR citations bind at the claim, not at authorship; the sweep's exemption is regions that record a number, and where it cannot decide it names rather than rewrites
status: Proposed — authored at Stage 6 Engineering for the `adr-corpus-integrity` release. Ratification is rendered by the operator at the Stage 13 close gate and is recorded in this file's `status:` field, never inferred from milestone closure.
date: 2026-09-01
release: adr-corpus-integrity
deciders: "Workspace owner (ratification at this release's Stage 13 close gate); direction chosen at Stage 5 Solutioning against a scored six-candidate matrix, authored at Stage 6"
tags: [architecture, adr, governance, concurrency, release-mechanics, tooling, late-binding, reversibility-moderate]
source_observations:
  - "A release lost an identifier three times to concurrent releases: its version slot twice and its ADR number twice. The two version losses cost ZERO sweeps because the version was tokenized; the two ADR losses cost two corpus-wide sweeps and a hand-repaired residual. The contrast is within one release, on one branch, at the same moments."
  - "The first ADR loss landed at Engineering Commit 0 and its sweep touched 1 file. The second landed after Engineering and its sweep touched 98 occurrences across 14 files, because by then every Engineering surface had been authored against the provisional number. The cost is a function of authoring latency, not of collision frequency."
  - "Of 175 lines in the corpus that RECORD an ADR number, the pre-change exemption protected 60 — 34.3%. The unprotected set includes 5 of 5 tokens in one ratified record's own numbering-lineage block and 3 of 4 in another's, where the note's head is protected and its hard-wrapped continuation lines are not."
  - "Seven lines of historical narrative were swept by a renumber and then reverted by hand, because the exemption keyed on a head string the tool itself writes and matched line-wise."
  - "The exemption's two consumers did not agree. The rewrite path and the post-move dangling verify consulted the predicate; the dry-run reporting path consulted neither and counted raw matches, so it predicted rewriting the very lines the apply path correctly left alone."
  - "No gate reads a bare ADR-NNN out of prose. The contiguity checker performs zero content reads — its entire input is one filename glob. Only path-bearing citations are covered, by the doc-link checks. Both error directions are therefore invisible to every gate, which is why the review report is emitted unconditionally."
  - "A reservation held against a shared surface converts the cheap failure into the expensive one: the contiguity checker fails a GAP as readily as a DUPLICATE, and an unclaimed reservation from an abandoned branch IS a gap."
---

# ADR-173 — ADR citations bind at the claim, not at authorship; the sweep's exemption is regions that record a number, and where it cannot decide it names rather than rewrites

## Status

**Proposed** — authored at Stage 6 Engineering for the `adr-corpus-integrity` release, per the Stage-6 ADR-authoring precedent. Ratification is the operator's at the Stage 13 close gate and is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Amends ADR-115.** This record contests nothing ADR-115 decided. ADR-115 established that an ADR number is allocated at authorship and bound at merge, that only the mainline binds, and that the reconciliation is tooled, gate-identified and lossless. All three clauses stand verbatim. This record adds the clause ADR-115 explicitly did not evaluate — *when a number may enter branch-authored prose* — and widens the reconciliation tool's exemption from a shape test to a population.

**Numbering.** This record's number was derived at Engineering Commit 0 against the mainline anchor, per the rule ADR-115 ratifies and this record extends. Two independent methods agreed at that instant: an enumerate-and-parse of every path under both ADR directories on `origin/main` returned 169 records with zero duplicates and zero gaps, giving anchor 169 and next-free 170; and the governed `--next-free` oracle returned 170. Two sibling milestones were concurrently in planning, and their claims — like this one — are advisory until merge.

**Numbering provenance — `170 → 173`.** Held **ADR-170** branch-local; renumbered to **ADR-173** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 170. In-release citations that read "ADR-170" denote this record.

## Context

A release's **version** has a late-binding rule. The plan carries the token `{{RELEASE_VERSION}}`, and the concrete number is computed and compare-and-swap-claimed atomically at the merge, at which point one stamping pass resolves the token everywhere (ADR-092). Before that moment no artifact commits a version number to prose, so a concurrent release taking the slot costs nothing.

A release's **ADR numbers** had no equivalent rule. They were allocated at authorship and written literally — into the filename, into the release plan, into every design doc, spec amendment, test comment and commit message authored after that point — and they bound only at merge (ADR-115). The number was therefore committed to prose *long before* it was decided, so every concurrent allocation forced the losing branch to renumber **and sweep every artifact already written against the old number**.

**The renumber itself was already solved.** ADR-115 selected the tooled reconciliation, the tool executes it in individually-verifiable steps, and gate `G-EX9` asserts it was tooled and complete. That machinery worked. What was unaddressed is the **blast radius the sweep has to cover**, which grows with how long the branch has been authoring against the provisional number — and which ADR-115's Consequences section neither bounds nor measures.

The gap was not "renumbering is broken". It was that **an identifier which is not yet decided was nevertheless committed to prose**, which is precisely the failure mode ADR-092 exists to prevent for the sibling identifier.

**A second, independent defect sat inside the sweep.** The tool exempted lines that RECORD an old number from the rewrite, so the audit trail a move creates is not erased by the next move. But that exemption was keyed on two strings *the tool itself writes*, and it matched one line at a time. Three consequences followed structurally rather than incidentally: it could not see a **region**, so a hard-wrapped continuation line of a provenance note fell outside it and was swept; it could not express **"I don't know"**, so on prose where a record and a citation are lexically identical it had to guess; and nothing forced its consumers to agree, so the reporting path and the apply path answered different questions.

**Neither error direction is caught by a gate.** A falsified record — a recorded number silently rewritten — leaves prose that is internally consistent and false, and the verify step exempts it by the same predicate that failed to protect it. A stale citation left un-swept is likewise invisible: the contiguity checker globs filenames and never opens a file, and only path-bearing citations reach the doc-link checks. What separates the two is not detectability but *recoverability*: the falsified record is silently wrong, while an un-swept citation can be **loudly listed**.

## Decision

**(1) An ADR number enters branch-authored prose only at the Stage-12 claim.**

Before that, an in-release record is cited as `{{ADR:<slug>}}`. The token carries no `ADR-\d` shape, so it is inert to every ADR-reading instrument, and it is **slug-keyed** rather than number-keyed because the slug already exists and is already relied upon as renumber-stable.

**The filename keeps its literal number.** ADR-115 § Portability conflict falsified deferring it — a compare-and-swap over a filename plus N citations plus three index surfaces is not an object any host offers, and a token in a filename produced a malformed name under the contiguity checker. That evidence is **accepted and is not re-argued**; it falsifies deferring the *filename*, and no filename is deferred here. What ADR-115 declined to evaluate is the *citation* side, which is where the whole measured cost sits.

**(2) The stamp is the LAST step of the claim.**

The Stage-12 identifier sequence is `detect → reconcile (if needed) → stamp → verify-zero-tokens`. Because the number is written only after it binds, a stamped citation cannot go stale, and a mid-release renumber costs nothing because nothing carries a number yet. The verify limb is read-only, asserts zero residual tokens, and **fails on a token found in link position** — a token inside a link target is parsed as a path and reported as a broken cross-reference by continuous integration on every push before the stamp runs, so the prose-only constraint is enforced rather than documented.

**(3) The sweep's exemption population is REGIONS that record a number**, not lines that match the tool's own output.

One classifier over a registry of region rows, consulted by every caller. Widening the population is **adding a registry row**, never editing a predicate body — which is what makes covering three defect facets one change rather than three patches. The Deviation-Log region row tolerates a numeric or ordinal heading prefix, because the tight form missed a genuine section heading and a missed section sweeps its rows silently; heading recognition is fence-aware, so a comment inside a fenced block is not a heading.

**(4) Where the classifier cannot decide, the sweep NAMES the site and does not rewrite it.**

The verdict domain is three-valued — `RECORD`, `AMBIGUOUS`, `CITE`. A boolean predicate is structurally forced to guess on a release-plan Deviation-Log row, because a row recording an earlier hop and a row citing a live blocker differ in prose and not in shape. Widening `RECORD` to cover both stops sweeping the live citation; leaving `RECORD` narrow falsifies the historical one. The third verdict is the only shape that is wrong on neither.

**Rewriting is the irreversible error; naming is the reversible one, and no gate catches either.** That asymmetry is the whole argument for the third verdict, and it is why the review block is emitted on **every** path including zero sites: a step that is silent when it finds nothing is indistinguishable from a step that did not run, and after clause (1)'s premise correction that block is the only detector the un-swept side has.

**Ambiguous sites do not change the exit code.** The Stage-12 routing rule classifies a renumber as Tier-1 mechanical remediation and escalates Tier 2 only on a non-zero exit, so making a correct run exit non-zero would convert every ambiguous site into a spurious escalation. The obligation is carried instead by the Stage-12 disposition step and by `G-EX9`, whose criterion is an ALL-conjunction and therefore returns non-satisfaction on an undispositioned site. The claim is scoped to the exit status and is stated that way: ambiguous sites are non-blocking on the exit code, **not** consequence-free.

**(5) The exemption has exactly ONE authority, and every consumer calls it.**

Three call sites: the citation rewrite, the post-move dangling verify, and the dry-run reporting path — which consulted no predicate at all before this record and is the third caller by construction. Parity is **structural, not asserted**: the reporting path calls the rewrite function and discards the returned text, so it is the apply path minus the write and a divergence is impossible without deleting a call. It additionally mirrors the verify path's projected-region strip before counting, because the rewrite function has no region awareness and without the strip the reporting path predicts an edit the projector will itself undo.

**(6) Branch-scoping is unchanged.**

ADR-115 § Decision (2)'s branch-scoped sweep property stands verbatim. A token resolves against the on-disk ADR file set within the branch diff, so it can never reach whichever *other* record holds a number on the mainline — the property falls out by construction rather than by a hand-verified whole-file exclusion.

**(7) The step count is restated here, and ADR-115's is left alone.**

ADR-115 § Decision (2) states the tool performs the move in *six* individually-verifiable steps. The tool ships **seven**: refuse-or-proceed, `git mv`, branch-scoped citation sweep, index-surface update plus renumber-log append, `## Status` provenance note, zero-dangling verify, and package-staleness disclosure. ADR-115 is `Accepted` and ADR-118 § Decision (2) places `## Decision` on a **closed** forbidden list, so that enumeration is **not correctable in place** and is deliberately preserved. This clause is the correction; ADR-115's edit in this release is confined to one `## Related ADRs` bullet pointing here. A hygiene class for *"a count the record's own artifact has since falsified"* is a genuine governance gap and is surfaced as an observation rather than resolved inside this record.

## Alternatives Considered

Six candidates were generated; three survived narrowing to a scored matrix.

**Reservation on the mainline (a ledger or marker committed to `main`) — REJECTED on the platform's own evidence, not on taste.** The contiguity checker returns a `GAP` problem for any hole in the sequence, and the tool's own header states the asymmetry: a duplicate is the cheap failure and a gap is the expensive one. A reservation held by a branch that is later abandoned **is** that hole, and releasing it is a distributed-garbage-collection problem the platform has no mechanism for. Reservation therefore trades the failure mode ADR-115 mechanized away for the one the corpus calls expensive. It also requires a direct-to-mainline write, which contradicts ADR-115 § Decision (1).

**Reservation on a host surface (an issue, a label, a project field) — REJECTED, and worse.** A reservation on a surface the gate does not read is advisory *exactly like a branch claim*, so it reserves nothing while adding a second definition of the number space — the drift class the checker's single-import contract exists to prevent.

**Slug-primary citation with no stamping pass — FALLBACK ONLY.** It satisfies the outcome, introduces no shared state and carries no gap risk, but it orphans every existing numeric citation in the corpus. Retained as the degradation path if the stamp mode is ever removed, not selected.

**Fixing the sweep alone, with no sequencing change — REJECTED.** It leaves the measured cost intact: the 98 occurrences across 14 files were all *legitimate* citations of a provisional number, and a better exemption does not stop them from needing to move.

**Deferring the FILENAME — OUT OF SCOPE BY PRIOR DECISION,** falsified by ADR-115 § Portability conflict and not re-litigated here.

**Widening `RECORD` to cover Deviation-Log rows instead of introducing a third verdict — REJECTED.** It stops sweeping genuine live citations there, which is the inverse defect. Both fixtures exist, are lexically identical, and are both swept today; a boolean predicate must pick one and be wrong on the other.

## Consequences

**Easier.** A concurrent ADR allocation costs the losing branch a rename and an index update rather than a corpus-wide citation sweep, and the cost stops being a function of authoring latency. The exemption's coverage of recorded-number lines rises from a third of the population to the population itself, and widening it further is a registry row rather than a predicate edit. The reporting path and the apply path can no longer disagree, because one calls the other. A site the tool cannot classify is surfaced with its file and line instead of being silently rewritten.

**Harder, stated plainly.** Authors now write a token where they used to write a number, and a release that authors an ADR carries one more Stage-12 step. **The verify step loses a detector it used to have:** because ambiguous lines are excluded from the dangling scan, the post-move verify can no longer catch a genuinely stale citation inside a Deviation Log. That is a real trade, not an oversight — scanning them would revert a correct move on every ambiguous site — and it is why the review block is unconditional and why the disposition obligation is carried at Stage 12 and at `G-EX9`.

**A residual worth naming.** The range-splitting class survives outside record regions. A range straddling swept and unswept tokens in ordinary prose is still split into an incoherent low-above-high pair; this record fixes the Deviation-Log instance, not the range class, and that is deliberately **not** claimed as covered.

**A second-order effect.** The 188 release plans already in the corpus carry literal numbers **by design** and are historical record. The convention is forward-only, and the `AMBIGUOUS` verdict is what protects them from a future sweep "fixing" them.

**Not changed.** ADR-115 § Decision (1) and (2) stand verbatim. No ADR filename gains a placeholder token. The contiguity checker's verdict semantics, arguments and continuous-integration invocation are byte-identical. The exemption's canonical shape detector is preserved as a named module symbol with its pattern byte-unchanged — its role narrows from *the* predicate to one registry row — because a sibling release re-targets the verify side of that same symbol and a silent rename would break it.

## Reversibility

**MODERATE / Confidence HIGH**, and the two halves unwind at different costs.

The **exemption rewrite** is CHEAP: one classifier plus a registry in one file, and reverting it restores the *known* defective sweep rather than an unknown state. The **token convention** is CHEAP today and becomes MODERATE once a second release has authored tokens, because a revert would then strand unresolved tokens in shipped prose. The `--stamp --check` limb on `G-EX9` bounds that exposure, since no release can merge carrying an unresolved token.

Reverting the mechanism while keeping the rule is coherent and returns the platform to literal citations at authorship. Reverting the rule while keeping the mechanism is not, because the stamp's refusal logic encodes the rule.

## Related ADRs

- [ADR-115](ADR-115-adr-number-claim-binds-at-merge.md) — the record this one **amends**. Its allocation rule, its mainline-binds clause and its tooled-reconciliation clause all stand verbatim; this record adds the citation-time rule it explicitly declined to evaluate, and its § Portability conflict evidence against deferring the filename is accepted rather than contested.
- [ADR-092](../../core/ADRs/ADR-092-plan-file-claim-time-stamping.md) — plan-file claim-time stamping, the precedent this record **generalizes from the version to the citation**. The `{{RELEASE_VERSION}}` token resolved on the compare-and-swap win path is the shape `{{ADR:<slug>}}` copies, including the double-brace spelling.
- [ADR-117](ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) — the ADR index as a derived surface. Its derived-surface contract is the authority for the region strip the reporting path now mirrors: a row inside a projected region is derived from the file set and belongs to whichever record still holds the number, so counting it as a citation is a false prediction even when the arithmetic coincides.
- [ADR-118](../../core/ADRs/ADR-118-adr-section-set-and-durability-hygiene-carve-out.md) — the ADR section set and the durability-hygiene carve-out. Its closed forbidden list is what bounds this release's edit to ADR-115 to a single `## Related ADRs` bullet, and is why § Decision (7) restates the step count here instead of correcting it there.
- [ADR-062](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md) — canonical-spec-edit-wins. Applied here: the originating tickets carry a framing that measurement falsified — that a stale citation is visible to the index gate — and their bodies are left as historical record rather than amended.
