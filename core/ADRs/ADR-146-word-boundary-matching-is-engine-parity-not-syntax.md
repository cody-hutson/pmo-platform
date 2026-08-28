<!-- reference-durability: allow-link -->
---
title: "ADR-146 — Whole-token matching under `git grep` is an engine-parity problem, not a syntax problem"
status: Proposed — flips to Accepted at this release's operator gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-24
release: checks-see-whole-subject
deciders: "Stage 5 Solutioning spoke (design) + two independent adversarial design-review passes (one Blocker each) + operator (ADR authorization; canonical-idiom gate) + Stage 6 Engineering spoke (build)"
tags: [probe-validity, regex-engine, git-grep, cascade-sweep, evidence-grounding, review-discipline, false-negative]
source_observations:
  - "A count-cascade sweep concluded `0 remaining occurrences` using a boundary-escape pattern under an extended-regex engine that does not implement the escape. The scan reported clean. Nothing had been verified, and the output was byte-indistinguishable from a genuine clean result."
  - "The engine does not reject or drop an escape POSIX does not define. It executes the escape as the literal character following the backslash — so a boundary escape searches for the letter `b`. The escaped pattern and its literal twin returned an identical 322-file set while the PCRE form returned a different 423-file set."
  - "The behaviour is a property of escapes, not of one escape. A digit-class escape and its literal twin both returned an identical 1,284-file set, while the PCRE form returned 1,641."
  - "The failure is bidirectional. Where the substituted literal is absent the probe returns a clean-looking zero; where it is present the probe returns matches at a success exit status, on text the author never asked for. No output signature separates either case from a correct result, so no diagnostic tell can be relied on."
  - "The originating work item prescribed a digit-only character class as the portable remedy. Measured against a five-line fixture it returned four matches where the oracle returned one — it matched the token flanked by letters and by an underscore. A digit class is not a word boundary."
  - "The PCRE form was then prescribed as the primary remedy and is also wrong for this job. A boundary escape asserts a word/non-word TRANSITION; a token whose own edge character is non-word, preceded by whitespace, presents none. Measured over a live population of four, the PCRE form returned zero."
  - "The whole-word flag is orthogonal to the pattern dialect, and the resulting over-match MIRRORS with spelling: for one parenthesised token against an oracle of 3, the escaped spelling returned 337 under basic regex and 3 under extended regex, while the bare spelling returned 3 and 337 respectively. A remedy expressed as a flag recipe cannot express a failure whose direction depends on the dialect."
  - "An intermediate design tried to establish engine capability by comparing a pattern against its construct-stripped twin over the corpus being measured, and treating identical result sets as proof the construct was literalised. Measured, that rule condemned 18 of 30 real corpus tokens on a fully working engine — a 60% false-alarm rate — plus every true zero, plus the design's own control arm."
---

# ADR-146 — Whole-token matching under `git grep` is an engine-parity problem, not a syntax problem

## Status

**Proposed.** Authored at Stage 6 Engineering for the `checks-see-whole-subject` release. It flips to Accepted when the operator ratifies it at the release gate; the flip is recorded in this file's `status:` field.

**Numbering provenance — `142 → 146`.** Held **ADR-142** branch-local; renumbered to **ADR-146** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 142. In-release citations that read "ADR-142" denote this record.

## Context

A verification sweep exists to enumerate every occurrence of an old value when a count, an enumeration, or a threshold changes. Matching a bare token *without* matching its superstrings is precisely that job — `54` must not match `543` — so a word-boundary escape is the natural and idiomatic reach, and the repository-wide search tool is the natural instrument inside a repository.

That combination is silently broken. The tool's default and extended-regex engines are POSIX engines, and a backslash escape POSIX does not define is neither rejected nor dropped: it executes as the literal character following the backslash. A pattern asking for a word boundary is executed as a search for the letter `b`. There is no error, no warning, and no distinguishing exit status.

Three properties make this worse than an ordinary tooling quirk.

**It generalises past one escape.** The same literalisation was measured on the digit, whitespace and word-character shorthands. A prohibition scoped to the boundary escape alone leaves the rest of the class canonically permitted.

**It is bidirectional.** Where the substituted literal happens to be absent from the corpus, the probe returns a clean-looking zero — the false-CLEAN direction. Where it happens to be present, the probe returns matches at a success exit status, on text the author never asked for — the false-ALARM direction. Because both directions exist, *no output signature is diagnostic*: any tell keyed on a zero result or a failure exit status is defeated by the second direction, and an author taught that tell will certify a probe that is searching for different text.

**It sits inside the discipline written to forbid exactly this.** The probe-validity section defines the verdict for a sensitivity arm that returns zero: the probe is unusable, and the subject is never reported clean. A sweep that concludes "0 remaining occurrences" through a literalised escape has verified nothing, and its output is indistinguishable from a genuine clean result. Canonicalising the broken idiom inside the standard that forbids false-clean probes is the defect this decision exists to eliminate.

The originating work item proposed two remedies. Both were measured, and both were wrong.

## Decision

**Whole-token matching under the repository search tool is canonicalised as a property of the token and the pattern dialect, not as a recipe of flags. The fixed-string whole-word form is PRIMARY. Passing any POSIX-undefined escape to the tool's POSIX engines is FORBIDDEN. Engine capability is asserted once per engine and construct against a purpose-built fixture — never by comparing result sets over the corpus being measured.**

Four parts.

**1. The forbidden form is a class, not an instance.** Passing a POSIX-undefined escape — the Perl shorthand classes and assertions and their kin — to the tool under extended regex or a bare pattern is forbidden. Escapes POSIX *does* define are dialect-specific rather than literalised, and are governed by part 3 rather than by this prohibition. Writing the prohibition as "any backslash escape" would have been wrong in the opposite direction.

**2. The whole-word flag is orthogonal to the pattern dialect.** It constrains where a match may begin and end; it does not change how the pattern is parsed. The dialect is chosen by the pattern flag. *The property:* any form that interprets the token as a **pattern** obliges the author to escape every regex metacharacter in the token **for that dialect** first. Fixed-string forms do not.

**3. The permitted set, in order.** The whole-word fixed-string form is primary — a literal token is not a pattern, and it is the only form correct under raw substitution and across both token edge classes. The whole-word extended-regex form and the explicit word-class alternation are permitted where the pattern is deliberately authored as extended regex *and* every metacharacter in the substituted token is escaped for it. The fixed-string form without the whole-word flag is permitted where the token's own edge characters are non-word and already bound it. A file-scoped line-scan predicate in a general-purpose language is permitted, and is named as *the* mechanism rather than as an instance of "not this tool" — the plain search binary on a given workstation may itself be a shim that returns a plausible zero on a pattern it rejects. The PCRE form with boundary escapes is **not permitted for whole-token matching**; it remains permitted for genuine PCRE constructs other than word boundary.

**4. Engine capability is asserted against a constructed fixture, once.** Before relying on a probe whose pattern uses a construct the executing engine may not implement, run that construct against a purpose-built two-line fixture — one line the construct must match and which does not carry the literalised twin text, one line carrying the literalised twin text and nothing the construct matches. The fixture is disposable and lives in the run directory. The arms and the verdicts are the ones the probe-validity section already defines; this adds no predicate and no verdict.

The operational form lives at the point of use in the Stage-5 sweep specification; the mechanism, the obligation and the worked record live once in the probe-validity discipline.

## Alternatives Considered

Four candidates were generated across three altitude bands before any matrix was scored. Two were eliminated on hard constraints; the survivors were then traded off.

**Candidate A — delegate to PCRE and use boundary escapes.** The originating work item's first prescription, and a survivor of the first narrowing pass. **Eliminated, on both limbs.** A boundary escape asserts a word/non-word *transition*, so a token whose own edge character is non-word — a parenthesis, a section glyph — presents none and the assertion cannot be satisfied. Measured over a live population of four, the escaped form returned **zero**; measured on a parenthesised token against an oracle of **3**, the raw substitution returned **320** and the escaped substitution returned **0**. It fails by under-matching *and* by over-matching depending on how the token is substituted, which is the same over/under-matching breach that killed candidate B, on the opposite limb. It is also build-dependent: PCRE is a compile-time option, so a corpus-wide rule resting on it fails silently on a build that lacks it.

**Candidate B — hand-write the boundary as an explicit character class.** The originating work item's second prescription, spelled with a digit-only class. **Eliminated.** It is an over-matching predicate: measured against a five-line fixture it returned **4 matches where the oracle returned 1**, matching the token flanked by letters and by an underscore. A digit class is not a word boundary. Canonicalising it would have breached the over-matching-probe rule inside the section that owns that rule. **This is the rejected option that most needs to survive in the record** — without it, a future reader re-derives the same digit-only class from the same intuition. The *corrected* word-class form survives as a permitted alternative carrying an escaping obligation.

**Candidate C — ask the tool for whole-word matching directly.** Chosen, and then sharpened. The whole-word flag reproduced the oracle exactly across seven token shapes with no build dependency and no hand-written class to mis-spell. The sharpening came from a second adversarial pass: the flag alone is not the decision, because it is orthogonal to the dialect and the over-match mirrors with spelling. **The fixed-string pairing is the recorded primary**, measured correct on five of five tokens spanning both edge classes; the bare whole-word flag is not.

**Candidate D — forbid the repository search tool for token sweeps outright.** **Eliminated on blast-radius ceiling.** Banning the tool reaches every probe-authoring surface in the corpus rather than the sweep path this decision owns, and a rule that bans a *tool* rather than a *construct* does not travel to the other engines the same hazard class inhabits. Its useful half — keep the sweep file-scoped — is retained inside the surviving design as a reinforcement rather than a ban.

### The rejected mechanism, recorded because re-deriving it is the likely error

An intermediate design replaced the (correctly rejected) diagnostic-signature tell with an **oracle-equivalence arm**: run the pattern and its construct-stripped twin over the same input and require the result sets to differ; identical sets were to mean the construct had been literalised.

**That premise is false, and the mechanism is rejected outright rather than gated.** A construct that *is* implemented may still fail to discriminate on a given corpus — every occurrence of the token may already satisfy the constraint — so identical result sets are the **expected** outcome of a working engine on most real tokens, and the **only possible** outcome for a true zero. Measured over 30 word-edged tokens drawn from the corpus's own citation vocabulary, the rule returned a broken-probe verdict on **18 of 30** while running on a fully functional engine — a 60% false-alarm rate — condemned **every** true zero, and condemned the design's own control arm.

The root cause is the same pattern this release exists to close: the invariant wanted was a property of the **engine**, and the mechanism shipped was a comparison over the **corpus being measured**, whose outcome additionally depends on whether the construct happens to discriminate there. Guarantee and mechanism diverged, and nothing in the arm checked the difference.

The instrument that works was already present in the lineage and had been discarded: a committed fixture built so that a conforming engine and a literalising engine *must* return disjoint, both non-empty sets. Part 4 of the Decision restores it. **Never establish engine capability by comparing two result sets over the corpus being measured.**

## Consequences

A probe whose engine silently literalises a construct now reaches the broken-probe branch of the verdict rule instead of passing a construct-free sensitivity arm and being scored clean. The verdict vocabulary gains no member; a previously unreachable branch becomes reachable, which is the teeth this decision adds.

The coverage map gains an observed shape. The wrong-pattern class becomes **bidirectional** — it previously carried the false-alarm direction only, and recorded the false-clean direction as unobserved and therefore uncovered. That statement is no longer true and has been reconciled rather than annotated.

The design-review self-check for sweep reproducibility now rejects a declared sweep command that is syntactically runnable but semantically inert on this platform, and the corresponding audit check is re-aimed from a tool-pair prohibition to a **permitted-invocation set**: name the engine, be re-runnable with explicit file scope, and do not rely on a construct that engine does not implement. That re-aim also admits a file-scoped line-scan predicate in a general-purpose language, which is what sweep authors on this platform actually use.

One cost is accepted deliberately. The obligation in part 4 asks for one fixture assertion per engine and construct per session. That is one assertion amortised across a release, not one extra corpus sweep per probe — which is precisely what the rejected mechanism would have charged.

A residual is disclosed rather than closed. No lint arm ships to enforce the forbidden form in committed scripts, because the population is measured at **zero** across the script-class corpus at authoring time, and a new executable would carry an allowlist and CI-wiring obligation for no yield. **Flip trigger, recorded:** the first live occurrence of the forbidden form in a committed script re-opens the lint decision.

## Reversibility

**CHEAP / Confidence HIGH.** The decision is prose in four existing surfaces plus this record. Reverting restores every surface at commit granularity, and no executable behaviour changes.

## Related ADRs

None. No existing decision governs regex-engine parity or probe-idiom canonicalisation; both ADR directories were searched before this record was authored.
