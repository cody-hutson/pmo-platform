<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Artifact-name segment order — project-code-first, with charset-vs-grammar enforcement honestly bounded
status: Accepted
date: 2026-06-30
release: 20-records-management-naming-and-cleanup
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment, corrected post-A6.5) + operator at the Collective Review scope-lock"
tags: [artifact-naming, segment-order, project-code-first, charset-vs-grammar, single-canonical-regex, g10-05, reversibility-moderate]
---

# ADR-055 — Artifact-name segment order — project-code-first

## Status

**Accepted** — scope-locked at the Collective Review (2026-06-30); the standard + this ADR land on the release branch + PR, with PR-review at Stage 9 as the dry-run gate (Claude Code path).

Number **055** — next gap-free after 054 (`records-classification-retention-model`, this release's first spoke) and 053 (`pre-gate-eligibility-forcing-function`); `find release/ADRs core/ADRs -name 'ADR-*.md'` reports 053 + 054 as the highest assigned at the authoring commit. Referenced by **slug** (`artifact-name-segment-order`), never by integer, so the number re-resolves if a concurrent release claims 055 first. Binds atomically at Stage 12.

## Context

The unified artifact-naming standard (#369) must fix the **segment order** of an artifact filename — and the original Stage-5 framing over-claimed *how that order is enforced*. Both questions are settled here.

**Two grounded order candidates:**

- **(a) type-first** — the literal #117 "type-first sort" phrase, so a raw `ls` groups by artifact kind.
- **(b) project-code-first** — the convention in all five live sources (`artifact-generator` line 291, `daily-status`, `tracker-schemas`, `operational-artifact-template-standard` Element F, and the daily-status `[Project]_AM_Update_[DATE]` pattern).

**The enforcement over-claim (the A6.5 adversarial finding this ADR corrects).** The original spec asserted that "the validation regex, the 7 emitter wirings, and #232's validator all bind to this order" and framed the QA gate as "the *enforcement* complement … both consume the one regex." A self-test falsified the regex half of that claim: `123.md`, `Plan.md`, and `ABC_2026-03-18_Cutover-Plan.md` (date in the middle) all **match** a charset regex, because a flat `(_segment)*` alternation is structurally **order- and arity-agnostic**. A charset regex cannot pin segment order or the presence of a project-code + type segment. The spec had already isolated this exact gap for ISO-date *validity* (a separate structural check) but had not generalized the lesson to grammar/order.

## Decision

**Adopt project-code-first segment order — `[ProjectCode]_[Type]_[…]_[YYYY-MM-DD].ext`, where `[Type]` is the single `-`-joined slug of a catalog type. Enforce order and arity through a complementary structural grammar check (G10-05) plus the write-time emitter convention — NOT through the charset regex, whose enforcement scope is honestly bounded to charset/separator (T1).**

1. **Order = project-code-first.** The "scannable by artifact kind" goal of #117 is met by (i) the controlled type vocabulary at the **second** segment and (ii) G10-04 / grep-by-type tooling — **NOT** by lead-segment lexical sort. Project-first preserves cross-project grouping in shared listings and conforms every existing filename (zero in-repo renames).

2. **The charset regex is a T1 gate only — the enforcement claim is downgraded.** The single canonical file regex guarantees charset + separator + no-shell-meta + closed-charset structure. It does **not** guarantee segment order, segment arity, the presence of a project-code/type segment, or ISO-date validity. This is stated verbatim in the standard's `## Validation Model` and is the load-bearing correction to the original ADR's over-claim.

3. **Order/arity are enforced by a complementary structural check (G10-05) + the emitter convention.** This is the identical producer/consumer split already used for ISO-date validity (the G10-03 check), now generalized to grammar/order. G10-05 pins an alpha-led first segment + **≥ 2 segments** (the `(_…)+` is one-or-more), closing the `123.md` / `Plan.md` arity/lead holes. Strict *positional* order (date strictly last) is the write-time emitter convention + the one-segment slug rule — a documented convention, an accepted T2 residual, not something G10-05 fully pins.

4. **One canonical file regex, published identically everywhere.** A précis/short regex is **not** published alongside the load-bearing one; the original spec's two non-equivalent regexes (a narrow Summary form lacking in-segment `-`, and a full body form with it) are collapsed to exactly one — the full-expanded in-segment-`-` form — referenced character-for-character by the QA G10 gate, #232's references, and any future validator. Any human-readable gloss is an annotated breakdown of that identical string, never a second pattern.

## Alternatives considered

- **Type-first segment order** — rejected: forces renames of every existing artifact and inverts the established convention for a benefit (scan by kind) the controlled type vocabulary + grep tooling already deliver at the second segment. The #117 *intent* (scan by kind) is preserved; the #117 *mechanism* (lead-segment lexical sort) is not.
- **A position-pinning regex that enforces order in the charset gate itself** — deferred (not rejected on merits): a fully position-pinning regex (project code, then `_`, then the type alternation, then an optional date *last*) would be materially harder to read and maintain for a marginal gain over "emitter convention + G10-05." Flagged as a future hardening, not adopted now.
- **Keep the dual regex (a readable précis + a precise body form)** — rejected: the two were behaviorally non-equivalent (the précis rejected the spec's own flagship compound-modifier example), and two strings presented as "the validation regex" guarantee that a downstream consumer binds to whichever it reads first. One canonical regex is what #232 / G10 single-source consumption requires.
- **Mint the type as multiple `_`-segments** — rejected: a multi-segment type (e.g. `Go-No-Go_Checklist`) is indistinguishable from a project+type pair and makes the catalog-resolution check non-deterministic. The one-segment `-`-joined slug makes the type↔segment map invertible, so G10-04 is a one-line lookup.

## Consequences

- The naming standard ships with **one** file regex, an explicit T1/T2/T3 validation model with the regex's scope honestly bounded, and a complementary G10-05 grammar check closing the falsifiable arity/lead holes — so the enforcement claim now matches what the controls actually guarantee.
- **The single canonical file regex, the G10-05 grammar check, the 7 emitter wirings, and #232's folder validator all bind to this model** (order is project-code-first; the charset regex enforces charset/separator, G10-05 enforces grammar/order). This is the corrected, accurate version of the original "all bind to this order" claim.
- **Accepted T2 residual:** `ABC_2026-03-18_Cutover-Plan.md` (date middle, type after) passes both the charset regex and G10-05 — strict date-last position is the write-time emitter convention, not a gate guarantee. Documented in the standard, not silently elided.
- Zero in-repo renames result from the order decision (project-code-first conforms every existing filename); the operator-side `projects/` syntax migration is a separate Layer-2 action, not gated by this ADR.

## Reversibility

**MODERATE / Confidence HIGH.** The standard, this ADR, the seven emitter references, the G10 gate, and the two OPERATIONS.md cross-references are each individually CHEAP to reverse (`git revert` the release PR). The **order** decision is MODERATE: project-code-first is convention-conforming so it costs zero renames *now*, but once artifacts and consumers rely on the order, reversing to type-first would force a corpus-wide rename. Confidence is HIGH that project-code-first is correct (it is the convention in all five live sources, and the #117 scan-by-kind intent is delivered by the type vocabulary + tooling) and that the charset-vs-grammar enforcement split is correct (the regex over-claim was falsified by direct self-test; the producer/consumer split is the same one already proven for ISO-date validity).

## Related ADRs

- **ADR-054** (records classification + retention model) — sibling spoke in this same release (`20-records-management-naming-and-cleanup`); precedent for the slug-referenced, integer-rebinds-at-Stage-12 ADR-numbering discipline used here.
- **ADR-036** (version-claim determinism) — the version token binds at Stage 12; consistent with this ADR's integer-binds-at-authoring / slug-referenced-forever posture.
- **ADR-052** (engineering parallelism postures) — precedent cited by ADR-054 for the same numbering discipline.
