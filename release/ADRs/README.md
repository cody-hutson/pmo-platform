# Release Module Architecture Decision Records (ADRs)

Architecture Decision Records for the `release/` module of the pmo-platform — the SDLC / pipeline domain (Stages 1-13 of the release pipeline, file-contention audits, pipeline reference-doc layout). Each ADR captures a structurally-load-bearing decision with status, context, decision rationale, consequences, reversibility, and cross-ADR composition.

## Format

ADRs follow the canonical **[ADR schema](../../core/schemas/adr-schema.md)** — the single source for the frontmatter field set and body-section contract. [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) is the canonical worked exemplar.

## Naming convention

`ADR-NNN-kebab-case-title.md` where NNN is monotonically increasing across the platform (NOT per-module). ADR-003 + ADR-004 + ADR-006 + ADR-007 + ADR-008 + ADR-009 live in [`../../core/ADRs/`](../../core/ADRs/); this module holds ADR-001, ADR-002, ADR-005, ADR-011, ADR-021, ADR-024, ADR-025, ADR-026, ADR-036, ADR-037, ADR-072, ADR-073, ADR-074, ADR-078. Future release-scoped ADRs continue the global sequence. The platform-wide-unique + gap-free numbering rule is enforced in CI by `release/tools/check-adr-numbers.py` (the `adr-number-integrity` job in `.github/workflows/repo-integrity.yml`).

## Release-scoped ADRs

| ADR | Title | Status | Date | Release |
|---|---|---|---|---|
| [ADR-001](ADR-001-cross-pr-overlap-audit-baseline.md) | Cross-PR Overlap Audit baseline policy when open-PR set is empty | Accepted | 2026-05-01 | file-overlap-audit |
| [ADR-002](ADR-002-modular-pipeline-stages-split.md) | Modular Pipeline Stages Split | Accepted | 2026-05-10 | platform-architecture-operating-model |
| [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) | Append-pattern aware cross-PR contention scoring (extends ADR-001) | Accepted | 2026-05-17 | stage-execution-and-process-discipline |
| [ADR-011](ADR-011-analysis-class-methodology-design-treatment.md) | Analysis-class methodology-design treatment: Stage 5 persona variant (not a new stage) | Proposed | 2026-06-02 | v1.04-planning |
| [ADR-021](ADR-021-liveness-oracle-selection.md) | Liveness oracle: all-process lsof cwd snapshot, fail-closed | Accepted | 2026-06-11 | v1.11-cleanup-orphan-state-reliability |
| [ADR-024](ADR-024-cross-release-impact-model.md) | Cross-release impact model: structural-blast-radius axis (F1–F6 ref-form sweep) + GO baseline-currency | Accepted | 2026-06-14 | cross-release-impact-model |
| [ADR-025](ADR-025-sior-escalation-canonicalization.md) | SIOR escalation canonicalization: single-source protocol doc + link-reference consumption | Accepted | 2026-06-13 | sior-escalation-discipline-across-the-comms-triage-technical |
| [ADR-026](ADR-026-spoke-launch-quota-reservation-telemetry-event.md) | Per-spoke quota telemetry: a new `spoke-launch` event_type, not a `test-run` payload key | Proposed | 2026-06-13 | parallel-launch-quota-budget-gate |
| [ADR-036](ADR-036-version-claim-determinism.md) | Deterministic version-claiming: a host-agnostic capability (slug-primary, defer-to-claim, atomic CAS) bound to a config-selected `repo_host` adapter | Accepted | 2026-06-21 | release-version-claim-determinism |
| [ADR-037](ADR-037-version-slot-cross-release-contended-axis.md) | Version slot as a cross-release contended axis (extends ADR-024): version-slot virtual-path token on the unchanged `serialize()` predicate | Proposed | 2026-06-21 | release-version-claim-determinism |
| [ADR-072](ADR-072-region-scoped-av-invariant-verification.md) | Region-scoped AV invariant verification: QC4-05 restricts each assertion to a declared lexical region (region × polarity) so a comment-vs-code / negation match cannot produce a verdict | Proposed | 2026-07-03 | 70-verification-execution-surface |
| [ADR-073](ADR-073-cross-issue-integration-check-stage9-extension.md) | Cross-issue release-integration check: extend Stage 9 (Phase A3.6 + QC3.5 + G-PR10) over a new Stage 7.5, reading the executor-emitted CIAC verdicts read-only (single-runner) with a G-PR9-style evidence-freshness guard | Proposed | 2026-07-03 | 70-verification-execution-surface |
| [ADR-074](ADR-074-stage8-consumes-runtime-evidence-for-behavioral-ac.md) | Stage 8 consumes the Stage-7 A8 runtime `test-run` result for behavioral-AC acceptance (Phase A validates the envelope, Phase B adds the Test-results read) rather than defining its own Stage-8 execution step — one dispatch map, honest `suite-skip` fallback for unmapped domains | Proposed | 2026-07-03 | 70-verification-execution-surface |
| [ADR-078](ADR-078-hub-owned-subtask-close.md) | Hub-owned sub-task close (spoke posts output; hub closes) — relocates sub-task-close ownership from spoke to hub so the authorized-close guardrail false-positive is removed in-git (the spoke's close *action* was the harness-warning trigger; no harness change) | Proposed | 2026-07-11 | 98-pipeline-freshness-and-spoke-safety |

ADR-001 / ADR-002 / ADR-005 were migrated from an earlier `governance/adr/` layout. ADR-011, ADR-021, ADR-024, ADR-025, and ADR-026 are authored natively in the modular-monolith layout.

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

ADR-024 (cross-release impact model) ──extends──> ADR-037 (version slot as a cross-release contended axis)
        │
        └─── ADR-037 adds the version-slot virtual-path token to the unchanged serialize() predicate (mechanics in stage-03-bundle.md §A9.6.1 Step 2a); slug-anchored to the version-claim-determinism founding ADR (ADR-036)
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
| ADR-024 | release | authored at Stage 6 (2026-06-14) |
| ADR-025 | release | authored at Stage 6 (2026-06-13) |
| ADR-026 | release | authored at Stage 6 (2026-06-13) |
| ADR-036 | release | authored at Stage 6 (2026-06-21) |
| ADR-037 | release | authored at Stage 6 (2026-06-21) |
| ADR-072 | release | authored at Stage 6 (2026-07-03) |
| ADR-073 | release | authored at Stage 6 (2026-07-03) |
| ADR-074 | release | authored at Stage 6 (2026-07-03) |
| ADR-078 | release | authored at Stage 6 (2026-07-11) |

> ADR-010 is core-scope and indexed in [`../../core/ADRs/README.md`](../../core/ADRs/README.md); ADR-011 continues the platform-global monotonic sequence as a release-scoped decision. ADR-012 through ADR-020 are core-scope and indexed in the core README; ADR-021 resumes the release-scoped thread after them. ADR-022 and ADR-023 are core-scope and indexed in the core README; ADR-024, ADR-025, and ADR-026 resume the release-scoped thread after them. ADR-027 through ADR-035 are core-scope and indexed in the core README; ADR-036 and ADR-037 resume the release-scoped thread after them. ADR-038 through ADR-071 are core-scope and indexed in the core README; ADR-072, ADR-073, and ADR-074 resume the release-scoped thread after them. ADR-075 and ADR-076 are release-scoped but pending indexing above; ADR-077 is core-scope and indexed in the core README; ADR-078 resumes the release-scoped thread after them.

## Authoring new ADRs

New release-scoped ADRs ship through the pipeline at Stage 5 (Solutioning) per [`../references/pipeline/stage-05-solutioning.md`](../references/pipeline/stage-05-solutioning.md). For **when to write an ADR** (the trigger / non-trigger rubric), the copy-paste template, and the supersede-not-edit immutability policy, see [`../../core/standards/adr-authoring-guide.md`](../../core/standards/adr-authoring-guide.md). File path: `release/ADRs/ADR-NNN-<short-slug>.md`. After authoring, append the new ADR row to the table above + add cross-reference to consuming files via [`../../core/standards/per-stage-shard-standard.md`](../../core/standards/per-stage-shard-standard.md) § Related ADRs (if applicable).

## Status enum

ADR `status:` follows the [Nygard convention](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

| Status | Meaning |
|---|---|
| Proposed | Decision drafted, not yet operator-ratified |
| Accepted | Operator-ratified at Collective Review or equivalent gate |
| Deprecated | Superseded by a later ADR; remains for audit trail |
| Superseded | Replaced; cite the superseding ADR in `## Status` block |

## Related references

- [`../../core/standards/adr-authoring-guide.md`](../../core/standards/adr-authoring-guide.md) — when to write an ADR (trigger/non-trigger rubric), copy-paste template + worked example, supersede-not-edit policy
- [`../../core/schemas/adr-schema.md`](../../core/schemas/adr-schema.md) — canonical ADR frontmatter + body-section schema (field/section contract)
- [`../../core/ADRs/README.md`](../../core/ADRs/README.md) — core-module ADR index
- [`../../core/disciplines/decision-discipline.md`](../../core/disciplines/decision-discipline.md) — decision-class briefing discipline (the sibling; does NOT govern ADR authoring)
- [`../references/pipeline/stage-05-solutioning.md`](../references/pipeline/stage-05-solutioning.md) — Stage 5 ADR materialization process
