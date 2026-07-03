---
title: ADR Authoring Guide — When to Write, Copy-Paste Template, Supersede-Not-Edit Policy
purpose: The canonical authoring guide for Architecture Decision Records — the when-to-write / when-NOT rubric, the copy-paste ADR markdown template + one worked example, and the supersede-not-edit immutability policy. This is the guide the ADR schema (§6 Boundary) and the roadmap framework designate as the owner of ADR mechanics/policy.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: core/standards/initiative-roadmap-framework.md (cites for ADR mechanics/policy); release/ADRs/README.md + core/ADRs/README.md (when-to-write pointer); release/references/pipeline/stage-05-solutioning.md (ADR-when-to-write rubric); .github/ISSUE_TEMPLATE/adr.yml (authoring reference); adr-helper skill (consumes the template)
parallel_to: adr-schema.md (the data contract — field + body-section list; this guide references it, does not restate it), decision-discipline.md (governs decision-class briefings, NOT ADR authoring)
---
<!-- reference-durability: allow-link -->
# ADR Authoring Guide — When to Write, Template, Supersede-Not-Edit Policy

An **Architecture Decision Record (ADR)** captures a single structurally-load-bearing decision and the rationale behind it — including the rejected alternatives — as an immutable, append-only record. This guide owns the **policy + ergonomics** of ADRs: *when* to write one (and when not), the copy-paste *template* + a worked example, and the *supersede-not-edit* immutability rule.

The **field + body-section data contract** (which frontmatter fields exist, their types + allowed values, the required body sections and their order) is owned by [`core/schemas/adr-schema.md`](../schemas/adr-schema.md). This guide's template *references* that schema for the field list — one source of truth — and does not restate it. The boundary is defined at [`adr-schema.md` §6](../schemas/adr-schema.md).

## When to write an ADR

Write an ADR when **any** of the following triggers fires. Each trigger is grounded in the shipped ADR corpus (a corpus witness is named so the threshold is calibrated against real records, not abstract judgment).

| # | Trigger | Corpus witness |
|---|---|---|
| T-ADR-1 | A **structurally load-bearing** decision with ≥2 viable options where the *rejected* options must survive as rationale — a choice future readers will otherwise re-litigate without the record. | ADR-027 (Release-Class weighting vs. per-issue Tier — rejected alternatives recorded); ADR-005 (append-pattern detection vs. line-overlap scoring — six alternatives A–F recorded). |
| T-ADR-2 | A decision that **binds a contract** across modules, stages, or artifacts — a boundary, an enum, or a resolution ladder that others must honor. | ADR-007 (core module boundary); ADR-016 (intake front-door boundary + handoff contract); ADR-062 (substrate-vs-canonical precedent). |
| T-ADR-3 | A decision that **supersedes or amends** a prior ADR — immutability forces a new record rather than an in-place edit (see § Supersession + immutability). | ADR-045 (supersedes ADR-029); ADR-046 (supersedes-in-part ADR-012's location clause). |

The governing question is: *"Is this an architecture **decision** whose rejected alternatives or cross-artifact contract must be preserved?"* If yes and a trigger fires, write the ADR. The cross-frame meta-discipline (how the ADR *form* is applied across frames) is a separate concern — this guide governs *whether* to write one.

## When NOT to write an ADR

Do **not** write an ADR in the following cases — the record would be ceremony that outweighs the decision, and (for the last case) would create duplicate-source debt.

| # | Non-trigger | Why not |
|---|---|---|
| N-ADR-1 | A **single forced approach** — one reasonable option, with no rejected alternatives worth preserving. | Nothing to re-litigate; the design spec plus the commit message already carry the decision. A release whose decisions each had a single reasonable approach needs no ADR. |
| N-ADR-2 | A **reversible, low-blast-radius mechanical change** — a doc repoint, an index-row backfill, a typo fix, any CHEAP-and-obvious edit. | The record would outweigh the decision. (This guide's own reference repoints and an index-row backfill are the exemplar: they ship as ordinary Stage-6 edits, no ADR.) |
| N-ADR-3 | A **decision already governed by an existing ADR or standard** — restating it mints a parallel record. | Cite the existing ADR (e.g., "per ADR-023") instead of authoring a duplicate. Duplicate-source debt is a maintenance liability, not a decision record. |

## ADR template (copy-paste)

Copy the block below into `core/ADRs/ADR-NNN-<kebab-title>.md` (cross-cutting, platform-wide decisions) or `release/ADRs/ADR-NNN-<kebab-title>.md` (release-pipeline-scoped decisions). `NNN` is the next free number in the platform-wide monotonic sequence (enforced by `release/tools/check-adr-numbers.py`; the number is claimed at merge, and a collision is resolved by renumbering with a provenance note — see § Supersession + immutability).

The **frontmatter fields and their allowed values are defined once** in [`adr-schema.md` §2](../schemas/adr-schema.md) — fill each field per that contract; the template does not restate the field rules. The **body sections** are the six required sections from [`adr-schema.md` §3](../schemas/adr-schema.md) with `## Alternatives Considered` inserted before `## Consequences` (the Nygard-classic section, present in the ADR-005 exemplar and required by the ADR issue template's Considered-Options field).

```markdown
---
# Fields + allowed values per core/schemas/adr-schema.md §2 (do not restate here — fill per the contract).
title: ADR-NNN — <human title>          # matches the H1 below
status: Proposed                        # Proposed | Accepted | Deprecated | Superseded (Nygard leading token; optional prose tail)
date: YYYY-MM-DD                        # decision / authoring date
release: <release-slug-or-version>      # the release the decision was rendered in
deciders: "<who decided, in prose>"     # e.g. operator + Stage 5 spoke + reviewers
tags: [<discovery>, <tags>]
source_observations:
  - "<the grounding observation / evidence this decision rests on>"
---

# ADR-NNN — <human title>

## Status

<Restate the status. When Superseded, cite the superseding ADR here — see adr-schema.md §5.>

## Context

<The forces / problem the decision addresses. What made a decision necessary?>

## Decision

<The decision, stated actively: "We will …" / "The platform adopts …">

## Alternatives Considered

<Each option evaluated, with why it was rejected. This is the load-bearing section — it is why
the ADR exists (the rejected options survive here so future readers do not re-litigate them).>

## Consequences

<Resulting trade-offs — positive AND negative. What becomes easier; what becomes harder.>

## Reversibility

<One of CHEAP | MODERATE | EXPENSIVE | IRREVERSIBLE (+ optional rationale) per
core/specs/reversibility-protocol.md.>

## Related ADRs

<Cross-ADR composition / supersession links, in ADR-number form (ADR-005) — never issue #N.>
```

Author ADR body/frontmatter references in **ADR-number form** (`ADR-005`), never issue `#N` — this keeps the repository-integrity issue-reference gate green (see both ADR READMEs' § Repo-integrity authoring discipline).

## Worked example

A condensed real ADR (distilled from [ADR-005](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md), the canonical worked exemplar named in both ADR READMEs). Trimmed to show the shape; the live record carries the full detail.

```markdown
---
title: ADR-005 — Append-pattern aware cross-PR contention scoring (extends ADR-001)
status: Accepted
date: 2026-05-17
release: stage-execution-and-process-discipline
deciders: "operator + Stage 5 Solutioning spoke"
tags: [audit, baseline, release-ops, file-overlap, contention-scoring]
source_observations:
  - "The first cross-PR file-overlap audit (2026-05-01) surfaced 4 HIGH-tier files; manual
     classification revealed 3 of 4 were structurally append-pattern (new rows appended, never
     rewritten) and almost never conflict at merge — but the 8-column schema could not express it."
---

# ADR-005 — Append-pattern aware cross-PR contention scoring (extends ADR-001)

## Status

Accepted (operator decision at Stage 4 D-E 2026-05-17; ADR authored at Stage 6 per the Stage 5 spec).

## Context

ADR-001 established the Cross-PR Overlap Audit baseline (HIGH ≥3 / MEDIUM 2 / LOW 1 PRs). Its first
application flagged 4 HIGH-tier files, but 3 were append-pattern — the schema treated all multi-PR
files uniformly, over-reporting append-only files as contention and diluting the signal.

## Decision

Extend the contention-matrix schema with two columns (`line_ranges`, `overlap_class`); classify each
contended file by pairwise hunk overlap; preserve the ADR-001 baseline unchanged for pre-cutover audits.

## Alternatives Considered

- (A) Schema extension + zero-tolerance threshold + canonical script — SELECTED (all surfaces agree).
- (B) Schema-only, no script — REJECTED (≥3-PR hand-classification is not reproducible).
- (C) Script-only, no schema column — REJECTED (overlap_class must persist as a durable artifact).
- (E) Modify ADR-001 in place — REJECTED (violates the "ADR-001 unchanged" constraint).
- (F) Renumber ADR-002 — REJECTED (ADR numbering is append-only; breaks cross-references).

## Consequences

Positive: future audits surface actionable (line-range-overlap) contention; append signal preserved
without dilution; ADR-001 baseline byte-preserved. Negative: coordinate-shift conservatism; a new
script joins the audit toolchain; unified-diff edge cases surface as warnings.

## Reversibility

CHEAP — additive at the schema layer (two columns appended; pre-cutover audits unaffected); the
script is a single new file; revert is a `git revert` on the release merge plus two file deletes.

## Related ADRs

Extends ADR-001 (baseline preserved unchanged). Both remain operative: ADR-001 as the 8-column
baseline, ADR-005 as the 10-column enrichment.
```

## Supersession + immutability

**ADRs are immutable once Accepted.** A ratified ADR is an append-only record. To change a decision, **do not edit the Accepted ADR** — author a **new** ADR that supersedes it, and update only the superseded ADR's `## Status` block to point forward (`Superseded by ADR-NNN`) per [`adr-schema.md` §5](../schemas/adr-schema.md). The body below `## Status` stays byte-frozen for the audit trail. The Nygard `Deprecated` / `Superseded` statuses (see both READMEs' Status-enum table) are the *only* mutations a live ADR receives after acceptance. Renumbering at merge (collision resolution) is the one mechanical exception, and it is recorded in a `## Status` "Numbering provenance" note (specimens: ADR-005, ADR-028/029, ADR-032, ADR-033).

This composes with [`adr-schema.md` §5](../schemas/adr-schema.md), which owns the *representation* — how supersession is expressed in frontmatter and prose: (a) `status:` begins with `Superseded` (optionally `Superseded by ADR-NNN`); (b) the `## Status` block cites the superseding ADR; (c) `## Related ADRs` carries the link. This guide owns the *policy* (supersede-not-edit); the schema owns the representation. Live specimen: ADR-029 (`status: Superseded by ADR-045`), whose `## Status` records that the record remains unchanged for audit trail — the policy is already practiced; this guide codifies it.

## Related

- [`core/schemas/adr-schema.md`](../schemas/adr-schema.md) — the ADR data contract (frontmatter fields + body sections + supersession representation). This guide's template references it; the two are paired (policy/ergonomics here, data contract there) per its §6 Boundary.
- [`core/ADRs/README.md`](../ADRs/README.md) and [`release/ADRs/README.md`](../../release/ADRs/README.md) — the core-module and release-module ADR indexes; each carries the Status enum, the Reversibility tier table, and the § Repo-integrity authoring discipline (author ADRs to those gates).
- [`core/disciplines/decision-discipline.md`](../disciplines/decision-discipline.md) — the sibling discipline for **decision-class briefings** (recommendations the operator acts on). It does **not** govern ADR authoring; this guide does. Cross-referenced to keep the boundary explicit.
- [`release/references/pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) — the Stage 5 process where ADRs are materialized during a release (the `adr-opened` / `adr-closed` audit-trail events cite this guide's when-to-write rubric).
- [`core/specs/reversibility-protocol.md`](../specs/reversibility-protocol.md) — the four-tier reversibility enum used by the `## Reversibility` section.
