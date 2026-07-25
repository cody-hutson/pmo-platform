<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-090 — The structural/path-move blast-radius mode EXTENDS blast-radius.sh (same scanner, new query), qualifying ADR-068's sibling decision; its merge-gate is a soft update-or-accept criterion rolled out shadow -> warn -> enforce"
status: Accepted
date: 2026-07-25
release: v3.90-blast-radius-scan-correctness
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Stage-5 D-gate"
tags: [release-ops, stage-5, stage-6, solutioning, engineering, blast-radius, impact-analysis, tool-family, structural-path-move, sibling-vs-extend, scanner-boundary, schema-v1, merge-gate, progressive-rollout, precedent, adr-068-qualification]
source_observations:
  - "Originating gap: a directory/file MOVE breaks a consumer class neither existing tracer sees — a file that hard-codes the OLD path as a string literal (a script's RELEASE_NOTES_DIR default, a config path, an allowlist entry). The doc tracer answers 'who references this file?', the domain sibling answers 'who imports this module?'; neither answers 'who hard-codes this path?'. This is not hypothetical: the release-notes-folder move silently broke the Stage-13 GitHub-Release emit for ~5 releases before it was root-caused (#230 -> RCA #3118)."
  - "Architecture fork (D-1): the instrument could EXTEND blast-radius.sh with a --mode=structural branch, or ship as a new sibling CLI (as ADR-068 chose for the domain fan-out). The discriminating question is whether the new capability needs a different SCANNER or just a different QUERY over the same scan list."
  - "Gate-hardness fork (D-2): the structural query is a grep -F path-literal substring match — it deliberately over-includes reconcilable non-consumers (historical comments, archived plans, coincidental substrings, prose documenting the old layout). A hard merge-block on a raw literal hit would false-positive-stop a legitimate merge."
---

# ADR-090 — Structural/path-move mode extends blast-radius.sh (qualifying ADR-068); soft update-or-accept gate, shadow → warn → enforce

## Status

Accepted — operator-ratified at the Stage-5 D-gate (D-1 / D-2 approved as recommended). Authored at Stage 6 per the Stage-6 ADR-authoring precedent established by ADR-062 (substrate-vs-canonical) and ADR-068 (the domain-fan-out sibling decision this ADR qualifies). Stage 5 produced the ADR *spec* (the design decision block in the #3120 Stage-5 output); Engineering authored this record as commit-A content and closes it before Stage-6 exit.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/`, resolved at the authoring commit with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. This ADR is referenced downstream **by slug**, never by its number — the number is an authoring-time assignment, not a stable cross-reference handle.

This decision is extended or reversed only by a **successor / superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the successor) — never by an in-place edit of this record.

## Context

`release/tools/blast-radius.sh` is the doc-corpus inbound-reference tracer (markdown-tree path-string fan-out); `release/tools/domain-blast-radius.sh` is its domain-fan-out sibling (code import-graph). Both emit the schema-v1 contract through the shared `release/tools/lib/schema-v1-emit.sh` library. A **directory or file move** exposes a third question neither answers: *which files hard-code the OLD path as a string literal?* — the class of consumer that a path move silently breaks. The Stage-13 GitHub-Release emit depended on exactly such a consumer (a `release/releases/notes` path default), and a folder move broke it undetected for roughly five releases (#230 → RCA #3118).

Two design forks were surfaced at Stage 5 and taken to the operator D-gate:

1. **Where does the capability live** — extend `blast-radius.sh` in place, or ship a new sibling CLI as ADR-068 did for the domain fan-out?
2. **How hard is the merge-gate** — a soft, reconcilable disposition per consumer, or a hard merge-block on any hit?

The ADR-068 precedent looms over fork 1: it chose a **sibling** for the domain fan-out, so a naive reading says "siblings are the pattern here." That reading is wrong, and this ADR records why.

## Decision

### D-1 — EXTEND `blast-radius.sh` with `--mode=structural` (NOT a new sibling)

The structural/path-move mode is an **additive mode branch on the existing doc tracer**, keyed off a `--mode=structural` flag (default-absent = the unchanged doc tracer). The mode reuses `build_scan_list`, `DEFAULT_EXCLUSIONS` (including the `.claude/worktrees/` exclusion), `SCANNED_TYPES`, `resolve_root`, the `grep -F` machinery, and the shared schema-v1 library **verbatim, read-only**; it adds a structural target normalizer (no regular-file requirement — the moved-away path need not exist), a `find_structural_consumers()` query, and a `main` dispatch. The default doc-tracer path (`find_first_order` → aggregate → `compute_second_order`) is **not modified**.

**The scanner-boundary that qualifies ADR-068.** ADR-068 chose a sibling for the domain fan-out because that fan-out needs a **fundamentally different scanner**: code file types (not the doc corpus), import-statement tokenization (not path strings), a different candidate denominator. Its rationale — forking the doc scan loop would put every reflexive doc-corpus Stage-5 run at regression risk — is a statement about a *different scan loop*. The structural/path-move query reuses the doc scan loop **unchanged**; it needs a **different query over the same scan list**, not a different scanner. The discriminating test this ADR records for all future tool-family decisions:

> **Same-scanner → extend; different-scanner → sibling.**
> Does the new capability need a *different scanner* (different file types / different tokenization / different candidate set), or just a *different query* over the same scan list? Different scanner → sibling CLI (ADR-068). Same scanner, new query → extend with a mode branch (this ADR).

ADR-068's sibling rationale is therefore **scanner-specific and does not reach this case** — it is qualified, not contradicted. A `structural-blast-radius.sh` sibling would re-implement the full CLI scaffold (arg-parsing, root resolution, the exclusion test, JSON assembly, the presenters, `main`) purely to serve a query that needs none of the divergence that justified the domain sibling — duplication without the compensating necessity.

**Regression isolation.** The mode is additive: the default path's control flow is untouched, so the reflexive doc-corpus Stage-5 A3 carries a structural no-regression guarantee (the same guarantee ADR-068 bought by *not* forking). The commit-split isolates the mode code from the gate wire-in; the shared cross-issue acceptance criterion asserts the default path's schema-v1 emit and first-order count are unchanged on a unique-basename target.

### D-2 — SOFT update-or-accept-per-consumer gate, rolled out shadow → warn → enforce

The structural query is a `grep -F` path-literal substring match; it deliberately **over-includes** reconcilable non-consumers (a path in a historical comment, an archived plan, a coincidental substring, prose documenting the old layout). The Stage-5 Phase A3.3 consumer sweep therefore requires each flagged consumer to carry an explicit **disposition** — **updated** (path rewritten) or **accepted** (recorded "not a real consumer, reason: …") — and flags only *unreconciled* consumers (neither disposition). This is a **soft, reconcilable** gate, never a hard merge-block on a raw literal hit, so a false positive cannot day-one-block a legitimate merge.

The gate criterion (**SR-G5** in `stage-05-solutioning.md` § 7.2) rolls out **shadow → warn → enforce**: report-only first (characterize the false-positive rate on real moves), then non-blocking warn, then gate-blocking on any unreconciled consumer once the rate is understood. It **ships in shadow** for its introducing release.

## Alternatives Considered

- **(A) A new `structural-blast-radius.sh` sibling — REJECTED.** It isolates the default path (the ADR-068 benefit) but duplicates the entire CLI scaffold for a query that reuses the doc scanner unchanged — the divergence that justified the domain sibling (different file types / tokenization / denominator) is simply absent here. The regression isolation a sibling buys is instead obtained for free by the additive mode branch (the default path's functions are not touched) plus the commit-split and the default-path acceptance criterion. Duplication without necessity.

- **(B) A hard merge-block on any structural hit — REJECTED.** A `grep -F` literal match over-includes by construction; a hard block on every hit would false-positive-stop legitimate merges (a path named in a comment or an archived plan is not a live consumer). The soft update-or-accept disposition is reconcilable and cannot wedge a merge on a false positive; the shadow → warn → enforce rollout lets the gate earn its teeth against a measured false-positive rate rather than asserting them on day one.

- **The selected approach** — extend with a mode branch + a soft, progressively-rolled-out gate — is the minimal-blast-radius codification: additive mode code (arg + normalizer + query + dispatch), a protocol section, a regression fixture, and a shadow-mode gate criterion, `git revert`-able with no data migration, reusing the established doc scanner rather than forking it or duplicating it.

## Consequences

**Positive:**
- **The default doc-corpus path is untouched** — the mode is additive; the reflexive Stage-5 A3 the pipeline runs on itself carries a structural no-regression guarantee.
- **The path-move consumer class is now catchable at design time** — the exact miss that broke the Stage-13 GitHub-Release emit (#230 → #3118) is reproduced by a committed regression fixture and caught by the mode.
- **The tool-family decision rule is now explicit** — "same-scanner → extend; different-scanner → sibling" gives future fan-out concerns a reproducible test, and resolves the apparent tension with ADR-068 (it is qualified, not contradicted).
- **The gate cannot false-positive-block a merge** — the soft update-or-accept disposition + shadow rollout keep a literal-match over-inclusion from wedging a legitimate merge.

**Negative / costs:**
- Extending adds a **mode dimension** to a previously single-purpose script — a real simplicity cost, mitigated by a clean `--mode` dispatch that leaves the default (mode-absent) path byte-identical.
- The `grep -F` literal match **over-includes** — the soft gate makes this reconcilable rather than blocking, but a real structural move still requires a human disposition pass over the flagged set.
- Second-order is scoped out for the structural mode (a path-literal consumer sweep is first-order by nature), so the mode does not trace transitive path-derivation chains; stated as a known scope boundary, not a silent undercount.

## Reversibility

**CHEAP (mode code) / MODERATE (gate wire-in) · Confidence HIGH.** The mode code is additive (a flag, a normalizer, a query function, a dispatch branch, a protocol section, a regression fixture) — a `git revert` restores the prior single-purpose tracer with no data migration and no consumer impact (the schema contract is unchanged). The gate wire-in (Phase A3.3 + SR-G5) is MODERATE only because it introduces a merge-gate criterion; the commit-split isolates it so it can be reverted or held at shadow without losing the mode, and it ships in shadow (no blocking authority) for its introducing release. The reflexive-cutover clause means no prior release is retroactively bound.

## Related ADRs

- **ADR-068** (domain-fan-out sibling vs. extend) — the decision this ADR **qualifies**. ADR-068 chose a sibling for the domain fan-out because it needs a different scanner; ADR-090 records the boundary ("same-scanner → extend; different-scanner → sibling") that makes the structural mode an extend without contradicting ADR-068. Read them together.
- **ADR-062** (substrate-vs-canonical precedent) — establishes the Stage-6-ADR-authoring precedent and the role-string `deciders` convention this ADR follows.
- **ADR-050** (deliverable-domain axis) — the `domain:` class field the sibling tracer dispatches on; ADR-090's scanner-boundary test generalizes the extend-vs-sibling question that axis first raised.

### Issue References
Originating deliverable: #3120 (milestone `blast-radius-scan-correctness`, #272). The historical miss this mode reproduces and prevents: #230 → RCA #3118. Sibling in-release fixes on the same tool: #3300 (worktree exclusion — the corrected scan base this mode runs on), #3291 (path-true consumer matching), #675 (LC_ALL=C pin). The Stage-5 design that produced this ADR's spec is the #3120 Stage-5 Solutioning output.
