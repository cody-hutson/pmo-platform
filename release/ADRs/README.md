# Release Module Architecture Decision Records (ADRs)

Architecture Decision Records for the `release/` module of the pmo-platform — the SDLC / pipeline domain (Stages 1-13 of the release pipeline, file-contention audits, pipeline reference-doc layout). Each ADR captures a structurally-load-bearing decision with status, context, decision rationale, consequences, reversibility, and cross-ADR composition.

## Format

ADRs follow the format established by [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) — frontmatter with `title / status / date / release / deciders / tags / source_observations`, body with `Status / Context / Decision / Consequences / Reversibility / Related ADRs` sections. See [`../../core/ADRs/README.md`](../../core/ADRs/README.md) § Canonical ADR Format for the full template documentation.

## Naming convention

`ADR-NNN-kebab-case-title.md` where NNN is monotonically increasing across the platform (NOT per-module). ADR-003 + ADR-004 + ADR-006 + ADR-007 + ADR-008 + ADR-009 live in [`../../core/ADRs/`](../../core/ADRs/); this module holds ADR-001, ADR-002, ADR-005, ADR-011, ADR-021, ADR-024. Future release-scoped ADRs continue the global sequence.

## Release-scoped ADRs

| ADR | Title | Status | Date | Release |
|---|---|---|---|---|
| [ADR-001](ADR-001-cross-pr-overlap-audit-baseline.md) | Cross-PR Overlap Audit baseline policy when open-PR set is empty | Accepted | 2026-05-01 | file-overlap-audit |
| [ADR-002](ADR-002-modular-pipeline-stages-split.md) | Modular Pipeline Stages Split | Accepted | 2026-05-10 | platform-architecture-operating-model |
| [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) | Append-pattern aware cross-PR contention scoring (extends ADR-001) | Accepted | 2026-05-17 | stage-execution-and-process-discipline |
| [ADR-011](ADR-011-analysis-class-methodology-design-treatment.md) | Analysis-class methodology-design treatment: Stage 5 persona variant (not a new stage) | Proposed | 2026-06-02 | v1.04-planning |
| [ADR-021](ADR-021-liveness-oracle-selection.md) | Liveness oracle: all-process lsof cwd snapshot, fail-closed | Accepted | 2026-06-11 | v1.11-cleanup-orphan-state-reliability |
| [ADR-024](ADR-024-spoke-launch-quota-reservation-telemetry-event.md) | Per-spoke quota telemetry: a new `spoke-launch` event_type, not a `test-run` payload key | Proposed | 2026-06-13 | parallel-launch-quota-budget-gate |

ADR-001 / ADR-002 / ADR-005 were migrated from an earlier `governance/adr/` layout. ADR-011, ADR-021, and ADR-024 are authored natively in the modular-monolith layout.

## Scope

This module's ADRs govern release-process mechanics: how the 13-stage pipeline operates, how file-contention is detected and resolved across PRs, how stage shards are structured. Decisions that apply platform-wide (cross-module governance, cardinality models, PMBOK alignment, module boundary definitions, tooling design) live in [`../../core/ADRs/`](../../core/ADRs/).

## ADR composition

```
ADR-001 (cross-PR overlap audit baseline) ──extends──> ADR-005 (append-pattern scoring)
        │
        ├─── consumed by Stage 4 file contention audit (release-process.md / pipeline/stage-04-planning.md)

ADR-002 (modular pipeline stages split)
        │
        └─── consumed by per-stage-shard-standard.md and release/references/pipeline/* (13 stage shards + README)
```

ADR-001 establishes the baseline-pinned analysis policy (last-N merged PRs + open PRs at audit-start commit SHA) when the open-PR set is empty at audit time. ADR-005 extends ADR-001 with append-pattern detection (`overlap_class` enum: `append-pattern` / `line-range-overlap` / `single-pr`) — files with `overlap_class = append-pattern` are informational only since append-pattern PRs almost never conflict at merge time. ADR-002 records the architectural decision to split the legacy monolithic `pipeline-stages.md` into 13 self-contained per-stage shards.

## Cross-numbering with core/ADRs/

| ADR | Module | Status |
|---|---|---|
| ADR-001 | release | migrated (2026-05-27) |
| ADR-002 | release | migrated (2026-05-27) |
| ADR-003 | core | migrated (2026-05-27) |
| ADR-004 | core | migrated (2026-05-27) |
| ADR-005 | release | migrated (2026-05-27) |
| ADR-006 | core | authored (2026-05-27) |
| ADR-007 | core | authored (2026-05-27) |
| ADR-008 | core | authored (2026-05-27); implementation follow-on |
| ADR-009 | core | authored (2026-05-27); implementation follow-on |
| ADR-011 | release | authored at Stage 6 (2026-06-02) |
| ADR-021 | release | authored at Stage 6 (2026-06-11) |
| ADR-024 | release | authored at Stage 6 (2026-06-13) |

> ADR-010 is core-scope and indexed in [`../../core/ADRs/README.md`](../../core/ADRs/README.md); ADR-011 continues the platform-global monotonic sequence as a release-scoped decision. ADR-012 through ADR-020 are core-scope and indexed in the core README; ADR-021 resumes the release-scoped thread after them. ADR-022 and ADR-023 are core-scope and indexed in the core README; ADR-024 resumes the release-scoped thread after them.

## Authoring new ADRs

New release-scoped ADRs ship through the pipeline at Stage 5 (Solutioning) per [`../../core/disciplines/decision-discipline.md`](../../core/disciplines/decision-discipline.md) and [`../references/pipeline/stage-05-solutioning.md`](../references/pipeline/stage-05-solutioning.md). File path: `release/ADRs/ADR-NNN-<short-slug>.md`. After authoring, append the new ADR row to the table above + add cross-reference to consuming files via [`../../core/standards/per-stage-shard-standard.md`](../../core/standards/per-stage-shard-standard.md) § Related ADRs (if applicable).

## Status enum

ADR `status:` follows the [Nygard convention](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

| Status | Meaning |
|---|---|
| Proposed | Decision drafted, not yet operator-ratified |
| Accepted | Operator-ratified at Collective Review or equivalent gate |
| Deprecated | Superseded by a later ADR; remains for audit trail |
| Superseded | Replaced; cite the superseding ADR in `## Status` block |

## Related references

- [`../../core/ADRs/README.md`](../../core/ADRs/README.md) — core-module ADR index + canonical format documentation
- [`../../core/disciplines/decision-discipline.md`](../../core/disciplines/decision-discipline.md) — when to write an ADR + decision-class classification
- [`../references/pipeline/stage-05-solutioning.md`](../references/pipeline/stage-05-solutioning.md) — Stage 5 ADR materialization process
