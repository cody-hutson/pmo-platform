<!-- reference-durability: allow-link -->
---
title: "ADR-151 — Issue-body anchor resolution is a numeric-only surfacing instrument, not a gate"
status: Accepted
date: 2026-08-25
release: checks-see-whole-subject
deciders: "operator (Stage-5 Collective Review acceptance + the D-20 ruling on the shakedown prose) + Stage 5 Solutioning spoke (design) + two independent adversarial reviewers + Stage 6 Engineering spoke (implementation)"
tags: [deploy-check, issue-intake, precision, advisory-severity, coverage-boundary, extend-before-create, PV-7, ADR-132]
source_observations:
  - "The candidate extension target was the inverse of this predicate on both axes: the issue-reference validity gate scans changed repo markdown and resolves #N against GitHub issues, while this subject is GitHub issue bodies resolved against repo files. It shares neither population nor target, and it backs one of nine required branch-protection contexts."
  - "A named-anchor arm is not implementable at acceptable precision. Prose carries no closing delimiter, so a named anchor's extent is not lexically determinable; the most conservative matcher built for it still produced roughly 30 false positives across 121 named sites (~25%). The numeric arm measured 2 findings over 206 verdicted targets."
  - "The uncovered classes are large enough that declaring them without counting them would itself be the defect: 211 named-arm sites, 181 bound citations behind an unmodelled prefix (54 of them naming a real ATX heading in the tracked markdown file they cite), 216 anchors bound to no path, 27 degraded — against 206 that receive a verdict at all."
  - "Admitting the two dominant unmodelled prefixes to the citation grammar ALONE would flag correct citations, because the target-side heading extractor does not model them either. The reviewer measured one such false positive directly. Symmetry is only safe when applied to both grammars together."
  - "The heading extractor was locale-dependent at first implementation: the section glyph is addressed as its UTF-8 bytes, so under a character-oriented locale it silently returned a SHORT number set rather than erroring — 18 numbers under LC_ALL=C versus 2 under en_US.UTF-8 on the same tracked file, which would have surfaced as false findings, not as an error."
  - "The unbound-path field was emitted empty into a tab-separated row read with `IFS=<tab> read`, which collapses runs of IFS whitespace; every field after the gap shifted left and 216 citations were recoded from one Register A class into another with both counters still reading plausible."
---

# ADR-151 — Issue-body anchor resolution is a numeric-only surfacing instrument, not a gate

## Status

**Accepted.** Authored at Engineering for the `checks-see-whole-subject` release; ratified at that release's plan-review gate.

**Numbering provenance — `145 → 151`.** Held **ADR-145** branch-local; renumbered to **ADR-151** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 145. In-release citations that read "ADR-145" denote this record.

## Context

A precondition that cites a file plus a section anchor — `some-standard.md § 4.1` — is the most confident-looking construct in an issue body and the least self-checking. Two things break it silently. The section number may be correct for a *different* file, and the target may be restructured long after the citing issue was written. Neither leaves a trace: a stale anchor looks exactly like a fresh one, and no reader who has not opened the target can tell.

Nothing in the repository asked the question. The link-resolution check stops at the file — a link to a document that exists passes, whatever section the surrounding prose claims. The reference-durability standard asks whether a fragile construct belongs in durable corpus at all, which says nothing about whether a number quoted beside an inline summary is real. And the cross-skill citation-anchor check names this predicate in its own declared coverage boundary as one it explicitly does **not** run.

Three questions had to be answered in order, and each of the last two only looks easy until the one before it is measured.

## Decision

### 1. A new tool, not an extension of the required gate

The Stage-4 risk register recorded the issue-reference validity gate as the natural extension point, on the strength of a vocabulary match: both deal in issues. Read at source it is the **inverse on both axes** — it collects files via a diff over changed repo markdown and resolves the `#N` tokens it finds against GitHub issues. This predicate's population is GitHub issue bodies and its resolution target is repo files.

Extend-before-create sets the bar at *necessary, not plausible*, and it does not reach here: there is no shared population and no shared target. What the two share is only that a heuristic false positive in the candidate surface would block **every pull request in the repository**, because that gate backs one of nine required branch-protection contexts — and its own allowlist entry already records that it is deliberately not a deploy-check leg and should not become one.

Blast radius on required contexts is therefore **zero by construction**: a new file, two additive call sites, no required context touched.

### 2. Numeric anchors only — and the named arm is counted, not ignored

A named anchor (`§ Run-Directory Discipline`) has no lexically determinable **extent**: prose carries no closing delimiter, and corpus headings additionally carry parentheticals, em-dash suffixes, and leading articles. Three formulations were built and measured; each traded one false-positive class for another, and the most conservative still produced roughly 30 false positives across 121 sites.

That failure is **structural, not a threshold to tune** — the same shape ADR-132 recorded when a symmetric predicate flagged 39 of 42 epics. The decision is to ship the arm that measures and **count** the arm that does not: named anchors are emitted as their own Register A row, so the coverage gap sits on the instrument's own face rather than in a paragraph about it.

### 3. Advisory permanently — there is no graduation path to describe

The residual cannot be closed by more work of the same kind. The corpus labels sections in conventions the extractor does not enumerate, so a citation naming a real-but-unmodelled label is **indistinguishable** from one naming nothing. Measured: 181 bound citations sit behind an unmodelled prefix, and 54 of them name a genuine ATX heading in the tracked markdown file they cite.

So this check never increments the findings counter, in any mode. That property is discharged **by shape rather than by default**: the block resolves no mode, branches on no mode, and does not reference the escalating emitter at all. Both emitters it does use are structurally incapable of reaching the counter, so the guarantee survives a future cohort flip without anyone re-reading the comment that asserts it.

The corollary is what makes this a decision rather than a default. Because no enforce flip is planned, the usual warn-mode shakedown ladder and its mode-file flip path are **omitted** from both wiring points — carrying that language would narrate a transition that is not planned to occur, sitting directly against the posture beside it. An advisory check that quietly acquires a flip criterion is how surfacing becomes verdicting.

### 4. A declared coverage boundary carries counts that were taken

The instrument declares every class it does not cover, and each declaration carries a **measured** number: 211 named-arm sites, 181 out-of-model-prefix sites, 216 anchors bound to no path, 27 degraded, 850 sites entering some Register A member, 206 verdicted.

This is the load-bearing half of the record. A boundary item declared *as measured* with no measurement behind it is precisely the defect this release is named for, and it is easy to ship by accident — the first pass at this specification declared exactly such a count, and the residual behind it turned out to be 3.7× the class the declaration was written to admit.

### 5. Symmetry between the two grammars is only safe applied to both at once

The obvious next move is to admit the dominant unmodelled prefixes to the citation grammar. Measured, that move **produces false positives**: the target-side heading extractor does not model those prefixes either, so a citation naming a real heading resolves against a number set that cannot contain it, and a correct citation is reported as unresolved.

The residual is therefore **declared at its true size** rather than half-closed. Widening both grammars together is the better instrument and remains available; it is a larger change than this predicate's mandate, and the number is now published so the decision can be made on it.

## Consequences

**Positive.** The question is asked for the first time, at the two moments it can act — triage, when an issue is being read anyway, and the standing deploy check, which covers the case triage cannot: a target restructured long after its citing issue was triaged, since a triaged issue is never re-triaged. Both surfaces are report-only, so the worst case of a wrong answer is a line a human dismisses.

**Negative, and accepted.** Coverage is a minority of citation sites: 206 verdicted against 850 seen. The instrument is honest about that rather than quiet about it, but a reader who mistakes a clean run for "every anchor here resolves" will be wrong. Both wiring points and the intake doctrine say so explicitly, in those words.

**The two implementation defects are recorded here deliberately**, because both are the *same class* as the defect the check exists to catch and neither was visible by reading. A locale-sensitive extractor returned a short heading set instead of an error, which would have surfaced as false findings against correct citations. An empty tab-separated field collapsed under `read` and silently recoded 216 citations from one Register A class into another, with both counters still reconciling and both still reading plausible. A predicate about invisible drift is not exempt from invisible drift, and the guard against it is a control arm that must fire — not a careful reading.

## Alternatives considered

**Extend the required issue-reference gate.** Rejected: no shared population, no shared target, and a heuristic false positive there blocks every pull request in the repository.

**Extend the cross-skill citation-anchor check.** Rejected: its declared scope is tracked markdown under the three skill roots, and reaching into issue bodies would breach a boundary that file states in prose.

**Extend the documentation link checker.** Rejected, and it surfaced an independent finding: three tracked files document a `broken-anchor` category that the code never emits, so a reader may reasonably conclude the repository already validates anchors. It does not. Filed separately rather than folded in.

**A prose-only intake rule with no mechanism.** Kept as a required *companion* rather than an alternative — it is where the expectation is stated for authors — but it cannot satisfy an acceptance criterion that asks for resolution.

**Gate on the result.** Rejected on the measured residual. A false positive in a gate costs far more than a missed anchor, and 54 known-good citations sit in the unmodelled class today.
