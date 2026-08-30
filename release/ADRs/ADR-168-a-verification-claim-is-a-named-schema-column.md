<!-- reference-durability: allow-link -->
---
title: ADR-168 — An unindexable verification table ERRORs only when it names a verification-schema column; sharing the word `Issue` is not a verification claim — and the method-column match stays CONTAINMENT, because equality silently de-indexes twenty live rows
status: Proposed — authored at Stage 6 Engineering for the record-format/silent-drop card. Ratification is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a plan row.
date: 2026-08-30
release: warn-mode-gate-graduation
deciders: "Workspace owner. Design rendered at Stage 5 Solutioning for the verify-release-plan record-format card and accepted by the hub at Procedure 4; implemented and re-measured at Stage 6. Recorded because BOTH halves are decisions a future author would re-litigate from the acceptance criterion alone — the criterion says a dropped row must produce a diagnostic, and the correct implementation deliberately does NOT diagnose one unreadable-looking table."
supersedes: none
tags: [architecture, release-pipeline, verify-release-plan, silent-drop, false-positive, discriminator, containment-not-equality, probe-validity, reversibility-cheap]
source_observations:
  - "The looser discriminator produces a MEASURED false positive, not a hypothetical one. `h_hits >= 1 && col_method == 0` fires on declarations-have-a-firing-surface_RELEASE_PLAN.md:332, an AC-baseline table whose own prose two lines above reads 'the baseline is a pinned measurement and carries no verdict'. The plan's real per-issue table sits directly beneath it and parses correctly. ERROR means exit 3, so the rule would turn a correct, shipped, unchangeable plan red."
  - "Scored over a 77-block denominator, three candidate predicates separate cleanly. E1 (h_hits >= 1): sensitivity 8 blocks / 61 rows, specificity 1 block / 2 rows — REJECTED on the false positive. E2 (h_hits >= 2): specificity 0 but blind to 40 real rows across the three `Command` blocks. E3 (names AC, Expected or Predicate): sensitivity 7 blocks / 59 rows, specificity 0."
  - "Tightening the method-column match to full-cell equality is itself a silent-drop regression, measured block-by-block over all 77 blocks: equality gains 59 rows and LOSES 20, de-indexing v3.65.1 (`| AC | Assertion | Verification method (FMF-1-scoped) | SI clause |`, 11 rows) and v4.36 (`| Issue | Verification method class | Expected result |`, 9 rows). Containment-preserving widening gains the same 59 and loses 0, swallowing 0 of the 27 correct-skip blocks."
  - "The measurement stood single-source through two stages. The hub's independent check was invalid and reported unusable, and the sibling card that landed immediately before made no header-matcher change, so it had no opportunity to falsify it either. Stage 6 is the FIRST implementation to exercise the widening path; the amendment held and is now carried by an executable mutation arm rather than by one measurement."
  - "All 59 droppable rows sit in MERGED, IMMUTABLE plans. A parser that refuses them emits a finding nobody can act on — you cannot re-author a shipped plan. ADR-147's own stated ground for route-don't-extend is that a false positive erodes trust in a control faster than a missed detection does, and its non-conformant population every one of the five had a codified home already. Neither holds here."
  - "`command` is matched by full-cell EQUALITY while the two long forms take containment. The split is not stylistic: containment on the long forms is load-bearing for 20 live rows, and `command` is a short common English word on which containment is the false-positive risk. Measured, the combination swallows 0 correct-skip blocks."
---

# ADR-168 — A verification claim is a NAMED SCHEMA COLUMN, not a shared word; and the method-column match stays containment

## Status

**Proposed** — authored at Stage 6 Engineering. Ratification is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `168` was derived at Engineering time, immediately before this file was authored, via `release/tools/renumber-adr.py --detect`. The oracle reported `ANCHOR 165 origin/main` and `NEXT-FREE 166`; `--detect` additionally reported `CLAIMED-SET-BRANCH-ONLY 166,167 (detection only — never binds)`, both `BINDS`, and computed `next=168`. `--next-free` alone is **mainline-anchored and under-reports** on a branch that already carries claims, which is why the union of the mainline anchor and this branch's own claims is the operative input. The number was deliberately **not** reserved at design time — the oracle is a *read*, not a reservation. A duplicate is mechanically renumberable by this same tool at merge time, whereas a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole. That asymmetry is the whole rule.

**A pre-existing collision on this branch is recorded, not silently stepped over.** `--detect` reports `core/ADRs/ADR-165-bounded-by-relocation-not-by-discard.md` as `DUPLICATE MAINLINE` — mainline already carries `ADR-165-post-merge-skill-deploy-is-a-local-git-hook.md`. That record belongs to another card and is **not** touched here; it is surfaced so the collision is resolved deliberately at merge rather than discovered there.

## Context

`release/tools/verify-release-plan.sh` grades every release plan's Verification Plan. Its per-issue parser resolves a column map from each table block's header, and a table for which it cannot resolve a **method** column has its rows dropped by a bare `if (col_method == 0) next`.

That drop was silent. Measured over the corpus — 187 plans, 48 carrying a Verification-Plan section, 77 table blocks inside them — it removed **61 rows across 8 blocks** from both the numerator and the denominator of the verdict roll-up. A roll-up can be arithmetically correct while an entire declared table is invisible, which is the exact defect class the surrounding milestone exists to eliminate one layer down: *an unparseable, absent, empty or truncated input must NEVER read as "nothing declared, therefore no violations."*

Two questions follow, and neither is answerable from the acceptance criterion. The criterion says only that *a dropped or unparseable row produces a diagnostic rather than an absence*.

**First: which tables are droppable at all?** The entire population reduces to two unrecognised header spellings — `Method class` (4 plans) and `Command` (3 plans). Widening the match absorbs them. But **27 blocks / 266 rows** in the same corpus are *correctly* skipped today: they are not per-issue tables, and the parser is right to say nothing about them.

**Second: what happens to whatever the widening does not absorb?** The file's own doctrine is unambiguous — a row the parser refuses to index is an ERROR and never a SKIP, *because a skip says "nothing to assert here", whereas this row declares a check that cannot be read*. But ERROR sets exit 3. A rule that over-fires does not merely add noise; it turns a shipped, merged, unchangeable plan red, and the author has no way to fix it.

So the real decision is a **discrimination** problem: separate 59 rows that were wrongly silenced from 266 rows that are correctly silent, using only what a table header says about itself.

## Decision

### 1. The ERROR discriminator is "names a verification-schema column", not "matched any header keyword"

```awk
if (h_method == 0 && (h_ac > 0 || h_expected > 0 || h_pred > 0)) { … latch … }
```

A table ERRORs when it **declares verification content** — it names `AC`, `Expected` or `Predicate` — and yet resolves no method column. A table sharing only the word `Issue` with the schema is **not** making a verification claim, and stays silent.

The rejected alternative is the obvious one, and it was rejected on a measurement rather than a preference:

| Predicate | Sensitivity (pre-widening) | Specificity (post-widening) | Verdict |
|---|---|---|---|
| `h_hits >= 1 && col_method == 0` | 8 blocks / 61 rows | **1 block / 2 rows** | **REJECTED** — measured false positive |
| `h_hits >= 2 && col_method == 0` | 4 blocks / 19 rows | 0 | Safe, but blind to 40 real rows |
| **`col_method == 0 && (col_ac > 0 \|\| col_expected > 0 \|\| col_pred > 0)`** | **7 blocks / 59 rows** | **0** | **ADOPTED** |

The false positive is a real shipped file: an AC-baseline table whose own prose declares that it *carries no verdict*. Under the loose rule, a correct plan exits 3.

**The ERROR is block-scoped, not row-scoped** — one record per table, carrying the offending header verbatim and the count of rows suppressed. The operator needs *"this table suppressed N rows"*, not N identical errors, and the verbatim header is what lets the author see which column is missing.

**`table-unindexable` is excluded from the `per_issue_rows` denominator.** It is a diagnostic about a table, not a graded row; counting it would inflate the very denominator the roll-up exists to make honest.

### 2. The method-column match stays CONTAINMENT for the long forms, EQUALITY for `command`

```awk
else if (c ~ /verification method/ || c ~ /method class/ ||
         c == "method" || c == "command")            { h_method = i; h_hits++ }
```

Tightening the two long forms to full-cell equality was proposed as defence-in-depth and is **rejected**. Measured block-by-block over all 77 blocks:

| Candidate | Rows gained | Rows lost | Correct-skip blocks swallowed |
|---|---|---|---|
| Full-cell equality | 59 | **20** | 0 |
| **Containment-preserving** | **59** | **0** | **0** |

Equality de-indexes two live shipped plans that index today *only because* the rule contains rather than equals. Adopting it would have shipped a fresh instance of the defect this card exists to close — a silent drop, introduced by the fix for a silent drop.

`command` takes equality for the opposite reason: it is a short common English word, and containment on it is precisely the false-positive risk the discriminator above is designed to avoid.

## Consequences

**The residual fails loud rather than vanishing.** An unforeseen sixth header spelling is no longer dropped; it reaches the ERROR arm carrying its own header text, so the next dialect is discovered by a red run rather than by a census.

**A future AC-baseline table that authors a literal `AC` column will trip the discriminator.** This is stated rather than hidden. The mitigation is in the record itself — the ERROR carries the header verbatim, so the author sees exactly what tripped it. This is preferable to the tighter predicate, which is silent on 40 real rows.

**Widening is correct HERE and is not a general licence.** ADR-147's `route, don't extend` rule argues on its face against absorbing a non-conformant dialect, and that ADR is cited here with the caveat that cuts against this decision rather than without it. ADR-147's own stated ground is that a false positive *erodes trust in a control faster than a missed detection does*, and its non-conformant population had **a codified home already**. Neither holds here: all 59 rows sit in merged, immutable plans that cannot be re-authored, so refusing them produces exactly the un-actionable false positive ADR-147 guards against. The route-don't-extend remedy belongs at **plan-authoring** time — a conformance check against `release-plan-template.md`, which prescribes the canonical header and which nothing currently enforces. That is logged as out of scope and is not solved here.

**Both halves are now carried by executable arms, not by a measurement.** The containment amendment stood single-source through two stages: the hub's independent check was invalid and reported unusable, and the sibling card that landed immediately before made no header-matcher change, so it had no opportunity to falsify it. Stage 6 is the first implementation to exercise the widening path. Suite arm `G11-M3` tightens the clause to equality and asserts the long-form header stops indexing; `G11-M5` loosens the discriminator and asserts the false-positive control goes red at exit 3. A future author who reaches for either alternative is now told by a failing test, not by this file alone.

**Reversibility: CHEAP.** Both halves are single-clause changes in one awk program, each independently revertible, each with a mutation twin that pins its behaviour.
