---
title: ADR-002 — Modular Pipeline Stages Split
status: Accepted
date: 2026-05-10
release: platform-architecture-operating-model
deciders: "Cody Hutson (operator) + Stage 5 Solutioning spoke"
tags: [architecture, governance, pipeline, reference-doc-layout]
source_observations:
  - Stage 4 release plan (D-Modular-Path = A, D-Cascade-Strategy = A)
  - Stage 5 spec (§ 7 ADR Candidacy)
  - Collective Review record 2026-05-10 (CONFLICT-1 ADR numbering = three sequential)
---

# ADR-002 — Modular Pipeline Stages Split

## Status
Accepted (operator decision rendered at Stage 4 D-Modular-Path 2026-05-07; ADR
authored at Stage 6 per Stage 5 spec § 7; numbered ADR-002 per Collective Review
CONFLICT-1 resolution 2026-05-10 — three sequential ADRs across related issues).

## Context

The monolithic `release/references/pipeline-stages.md` grew, as of authoring, to 1,317 lines
covering 13 stages plus 3 nested protocols (Collective Review, DT↔Engineering
Iteration Loop, DT↔QA Handoff). At that size:

- Per-stage edits required scrolling through the entire file to locate the target.
- Multiple stage definitions in one file complicated multi-agent edits (file-level
  contention even when changes were stage-disjoint).
- Cross-stage queries (grep across the pipeline) still worked, but single-stage
  reads carried the whole file's content cost.
- The file violated the parent initiative's AC1 "modularity approach for pipeline documentation."

Fresh grep at Stage 5 entry (SHA `8531611`, 2026-05-06) counted **115 substantive
cross-references across 33 files** pointing to the monolithic path, as of that grep. The cascade
fan-out was deep enough that any split needed a one-shot cascade plan, not a
piecemeal migration.

Forward refs in `execution-framework.md` and `terminology-glossary.md` already
anticipated a per-stage anchor convention (`pipeline-stages.md#stage-N`), but
those refs were prose-form (not actual markdown anchors). The empirical pattern
across 115 refs was uniformly prose-form using §N notation (e.g., `§5`, `§6 Outputs`).

## Decision

**Split `release/references/pipeline-stages.md` into a
`release/references/pipeline/` directory containing 14 files:**

1. **One per-stage file for each of the 13 stages**: `stage-NN-<name>.md` (zero-padded NN, kebab-case name)
   - `stage-01-intake.md` ... `stage-13-close.md`
   - Per-file schema: H1 file title + numbered H2 headings (`## 1. Purpose` ...
     `## 10. Retro`) preserving the 10-point framework
   - Nested protocols live inside owning stage file:
     - `stage-05-solutioning.md` absorbs Release-Level Checkpoint: Collective Review
     - `stage-07-dev-testing.md` absorbs DT↔Engineering Iteration Loop Protocol
       and DT↔QA Handoff Protocol

2. **`README.md`**: directory index absorbing cross-cutting content
   - Overview, How to Read, Stage Index table
   - Cross-Cutting Reference Map (Framework Alignment, Methodology Variation,
     Collective Review, DT↔Engineering, DT↔QA, schema specs)
   - Framework Alignment table (Process / Methodology / Framework / Tool layers)
   - Methodology Variation Across Stages table (per-archetype variation per
     `delivery_approach` enum)

**Naming convention:** Zero-padded NN + kebab-case name per `tree-audit-2026-04-18`
SUMMARY.md O6/P2 NARA finding (ASCII-safe, lowercase, hyphenated, filesystem-sort
aligned with index order). Names match milestone AC example (`stage-05-solutioning.md`).

**Anchor convention:** Numbered H2 headings auto-slug to `#N-section-name`
(e.g., `## 5. Process` → `#5-process`). Prose refs using `§N` notation map
mechanically to the new anchors via the 6-rule cascade matrix.

**Cascade scope:** All 115 substantive cross-references across 33 files, as of that grep, are
rewritten via the 6-rule R1-R6 matrix in PR-1. The monolithic source file is
deleted in the same PR. Historical references in archive classes (release plans,
`pmo-platform/governance/RELEASE_LOG.md`, `pmo-platform/analysis/`,
`pmo-platform/engineering/evals/results/`, `.skill` packages) are preserved as-is.

## Consequences

**Positive:**

- Per-stage edits operate on ~50-360 line files (vs. the 1,317 lines the monolith carried at the time).
  Average stage file is ~70-90 lines; only `stage-07-dev-testing.md` is large
  (~360 lines at the time, due to two nested protocols) — acceptable cohesion vs. fragmentation.
- Cross-stage queries continue to work via `grep -r pipeline/` (or
  `release/references/pipeline/`).
- Stage-specific PRs and audits target a single stage file; reviewers see only
  the relevant scope.
- File length policy precedent for the repo: per-doc files stay under 500 lines
  where the content can be meaningfully decomposed (closes parent initiative AC2 direction).
- Future stages (e.g., a hypothetical Stage 14) extend the directory naturally
  by adding `stage-14-<name>.md` + a row in the README Stage Index.
- Methodology Variation cross-stage table lives in README — single
  authoritative source for the 13 × 8 archetype matrix.

**Negative:**

- Cross-stage queries that previously used single-file scrolling now require
  multi-file grep. Acceptable per current consumer-skill access patterns (which
  are already grep-driven).
- The cascade rewrite is EXPENSIVE to revert (the then-current 115 refs across 33 files would
  need to revert). Mitigated by single-PR atomicity — `git revert` on the merge
  commit restores all 115 refs, as counted at the time, in one operation.
- One additional indirection for newcomers: "Where is Stage 7 defined?" requires
  pointing to `pipeline/stage-07-dev-testing.md` rather than `pipeline-stages.md`
  Stage 7 section. README Stage Index mitigates by serving as the entry point.

**Mitigation of negatives:**

- Cross-stage grep is the platform's existing consumer pattern; no consumer
  skill relied on single-file scrolling.
- Revert cost is one-shot (single PR); ADR-002 records the design so reverting
  would be a deliberate decision, not accidental drift.
- The README's Stage Index and Cross-Cutting Reference Map are the navigation
  surfaces — consumers learn `pipeline/` once and use the index.

## Alternatives Considered

- **(A) Modular split with cascade (selected)** — clean cut: split file, cascade
  rewrite the then-current 115 refs, delete monolithic source. One PR, one revert path. Auditable
  via AV-1 grep test (zero substantive matches post-PR).

- **(B) Forwarding stub: keep `pipeline-stages.md` as a 13-bullet index pointing
  to the new modular files** — REJECTED. Creates two sources of truth for stage
  content ("which file should I read?"). Existing 115 refs would point to the
  index, not the canonical per-stage files; new readers would need to follow
  one extra hop. The index would inevitably drift over time. AV-1 grep test
  would become ambiguous (correct refs to a stub vs. canonical refs both look
  fine until clicked).

- **(C) Transitional alias: keep monolithic file as a literal redirect/alias
  pattern** — REJECTED. Markdown does not natively redirect. Any attempt to
  simulate redirects (e.g., a single-line `# See pipeline/` file) is a worse
  forwarding stub. Markdown-renderer behavior is also non-standard for redirect
  conventions.

- **(D) No split — keep monolithic file** — REJECTED. Does not address parent initiative AC1
  (modularity approach) or AC2 (file length guidelines). The 1,317-line file
  is already past the size where any further growth is sustainable.

## Reversibility

EXPENSIVE — reverting requires:

1. `git revert` on the PR-1 merge commit (restores the monolithic file and all
   115 cascade refs, as of that grep).
2. Removal of the new `pipeline/` directory (handled by the same revert).
3. Removal of ADR-002 (this file) or supersede with ADR-NNN if the policy
   changes again.

Mitigation: PR-1 is a single atomic merge. Revert is one operation. If a
future release wants to revisit the decision, ADR-NNN can supersede ADR-002
with a documented rationale.

## References

- Parent initiative — Design modular file structure for pipeline documentation
- Tree-audit NARA naming finding: `pmo-platform/analysis/tree-audit-2026-04-18/SUMMARY.md` O6/P2
- Cascade verification: AV-1 grep test in PR-1 body
