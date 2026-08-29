<!-- derived-surface: source=release/ADRs/ADR-*.md (filename + frontmatter) · projector=release/tools/generate-adr-index.py · anchor=none (no run-scoped input) · derived-columns=ADR,Title,Status,Date,Release · source-column=NONE (whole-table projection; every column is derivable, so there is no hybrid round-trip limb) · contract=release/references/standards/release-corpus-schema.md § Derived-Surface Contract · REGION-SCOPED: only the ADR-INDEX region below is projected -->
# Release Module Architecture Decision Records (ADRs)

Architecture Decision Records for the `release/` module of the pmo-platform — the SDLC / pipeline domain (Stages 1-13 of the release pipeline, file-contention audits, pipeline reference-doc layout). Each ADR captures a structurally-load-bearing decision with status, context, decision rationale, consequences, reversibility, and cross-ADR composition.

## Format

ADRs follow the canonical **[ADR schema](../../core/schemas/adr-schema.md)** — the single source for the frontmatter field set and body-section contract. [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) is the canonical worked exemplar.

## Naming convention

`ADR-NNN-kebab-case-title.md` where NNN is monotonically increasing **across the platform, not per module**. `core/ADRs/` and `release/ADRs/` share ONE global sequence, so the two directories interleave: which numbers are release-scoped is not a fact to be enumerated, it is a fact **derivable from which directory the file sits in**. The generated index below is that derivation for this module; the core module's records live in [`../../core/ADRs/`](../../core/ADRs/).

A number is **allocated at authorship and bound at merge** — an unmerged claim on a sibling branch does not bind the sequence, and stepping past one lands a gap that the contiguity gate fails as readily as a duplicate. The binding oracle and the merge-time reconciliation are tooled: `release/tools/renumber-adr.py --next-free` / `--renumber`. See [ADR-115](ADR-115-adr-number-claim-binds-at-merge.md) for the decision and [`../../core/ADRs/README.md`](../../core/ADRs/README.md) § Renumber log for the worked precedents.

**Enforcement.** The platform-wide-unique + gap-free numbering rule is enforced in CI by `release/tools/check-adr-numbers.py`, and the completeness of the index below by `release/tools/generate-adr-index.py --verify` — both in the `adr-number-integrity` job in `.github/workflows/repo-integrity.yml`.

## Release-scoped ADRs

**This table is a DERIVED surface.** Every column — link, title, status, date, release — is projected from the ADR file set and each record's own frontmatter. It is not hand-maintained, and a hand-edited row fails `--verify`. Regenerate with `python3 release/tools/generate-adr-index.py --write`. Contract: [`../references/standards/release-corpus-schema.md`](../references/standards/release-corpus-schema.md) § Derived-Surface Contract. Founding record: [ADR-117](ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md).

<!-- ADR-INDEX:BEGIN -->
<!-- The table below is GENERATED from the ADR file set. Do not hand-edit a row: `generate-adr-index.py --verify` fails a hand-edit, and the record's own frontmatter is the source for every column. Add an ADR, then run `python3 release/tools/generate-adr-index.py --write`. -->

| ADR | Title | Status | Date | Release |
|---|---|---|---|---|
| [ADR-001](ADR-001-cross-pr-overlap-audit-baseline.md) | Cross-PR Overlap Audit baseline policy when open-PR set is empty | Accepted | 2026-05-01 | file-overlap-audit |
| [ADR-002](ADR-002-modular-pipeline-stages-split.md) | Modular Pipeline Stages Split | Accepted | 2026-05-10 | platform-architecture-operating-model |
| [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) | Append-pattern aware cross-PR contention scoring (extends ADR-001) | Accepted | 2026-05-17 | stage-execution-and-process-discipline |
| [ADR-011](ADR-011-analysis-class-methodology-design-treatment.md) | Analysis-class methodology-design treatment: Stage 5 persona variant (not a new stage) | Accepted | 2026-06-02 | v1.04-planning |
| [ADR-021](ADR-021-liveness-oracle-selection.md) | Liveness oracle: all-process lsof cwd snapshot, fail-closed | Accepted | 2026-06-11 | v1.11-cleanup-orphan-state-reliability |
| [ADR-024](ADR-024-cross-release-impact-model.md) | Cross-release impact model (structural-blast-radius axis via F1–F6 ref-form sweep + GO baseline-currency) | Accepted | 2026-06-14 | cross-release-impact-model |
| [ADR-025](ADR-025-sior-escalation-canonicalization.md) | SIOR escalation canonicalization: single-source protocol doc + link-reference consumption | Accepted | 2026-06-13 | sior-escalation-discipline-across-the-comms-triage-technical |
| [ADR-026](ADR-026-spoke-launch-quota-reservation-telemetry-event.md) | Per-spoke quota telemetry: a new `spoke-launch` event_type, not a `test-run` payload key | Accepted | 2026-06-13 | parallel-launch-quota-budget-gate |
| [ADR-036](ADR-036-version-claim-determinism.md) | Deterministic version-claiming: a host-agnostic capability (slug-primary identity, intent-to-bump, defer-to-claim, atomic compare-and-swap) bound to a config-selected repo_host adapter | Accepted | 2026-06-21 | release-version-claim-determinism |
| [ADR-037](ADR-037-version-slot-cross-release-contended-axis.md) | Version slot as a cross-release contended axis (extends ADR-024) via a version-slot virtual-path token on the unchanged serialize() predicate | Accepted | 2026-06-21 | release-version-claim-determinism |
| [ADR-052](ADR-052-engineering-parallelism-postures.md) | Stage-6 Engineering parallelism posture taxonomy (names existing D-C SINGLE / OPTION-A topology behavior as postures + adds dispatch) | Accepted | 2026-06-30 | 73-concurrent-execution-safety |
| [ADR-054](ADR-054-records-classification-retention-model.md) | Records classification + retention model — 4-class value-based taxonomy, derived not minted, destruction=none | Accepted | 2026-06-30 | 20-records-management-naming-and-cleanup |
| [ADR-055](ADR-055-artifact-name-segment-order.md) | Artifact-name segment order — project-code-first, with charset-vs-grammar enforcement honestly bounded | Accepted | 2026-06-30 | 20-records-management-naming-and-cleanup |
| [ADR-056](ADR-056-generated-cleanup-trigger-surface.md) | Generated-artifact cleanup trigger surface — a new on-demand skill (/generated-cleanup), schedulable via the existing /schedule seam, distinct from the orphan-state cleanup script | Accepted | 2026-06-30 | 20-records-management-naming-and-cleanup |
| [ADR-066](ADR-066-design-gate-delivery-approach-conditioning.md) | Design-before-slicing gate conditioned on delivery_approach: a new Gate-3 criterion (G3-18) that biases the design-invocation expectation per the declared methodology via the §5 Skill Consumption Pattern, base behavior unchanged when the axis is absent | Accepted | 2026-07-01 | 105-knowledge-corpus-tail-closeout |
| [ADR-072](ADR-072-region-scoped-av-invariant-verification.md) | Region-scoped AV invariant verification | Accepted | 2026-07-03 | 70-verification-execution-surface |
| [ADR-073](ADR-073-cross-issue-integration-check-stage9-extension.md) | Cross-issue release-integration check: Stage-9 extension over new Stage 7.5 | Accepted | 2026-07-03 | 70-verification-execution-surface |
| [ADR-074](ADR-074-stage8-consumes-runtime-evidence-for-behavioral-ac.md) | Stage 8 consumes Stage-7 runtime evidence for behavioral-AC acceptance (does not re-execute) | Accepted | 2026-07-03 | 70-verification-execution-surface |
| [ADR-075](ADR-075-plan-verification-executor-shared-contract.md) | Plan-verification executor: a versioned shared-executor contract over a thin check-family dispatcher | Accepted | 2026-07-03 | 70-verification-execution-surface |
| [ADR-076](ADR-076-comment-author-association-trust-boundary.md) | Comment author-association trust boundary at the pipeline's comment-I/O seam | Accepted | 2026-07-04 | 109-comment-trust-boundary |
| [ADR-079](ADR-079-hub-owned-subtask-close.md) | Hub-owned sub-task close (spoke posts output; hub closes) | Accepted | 2026-07-11 | 98-pipeline-freshness-and-spoke-safety |
| [ADR-086](ADR-086-event-log-schema-decision-subtype-extension.md) | Event-log schema decision-subtype extension (cascade-sweep-block + session-retro) | Accepted | 2026-07-19 | pipeline-telemetry-tail |
| [ADR-088](ADR-088-release-state-binding-and-mechanical-merge-boundary.md) | Release-state binding points: Gate 3 asserts identity-mode intent, not claim-time freeness; mechanical merge is safe only for pure-additive ledgers | Accepted | 2026-07-22 | version-identity-and-corpus-ledgers |
| [ADR-093](ADR-093-scoped-conditional-binding-acceptance-fit-gate.md) | Scoped, conditional-binding acceptance-fit gate at Stage 2 with phased rollout | Proposed | 2026-07-25 | intake-and-gate-protocol-hardening |
| [ADR-094](ADR-094-extend-before-create.md) | Extend-before-create lands as a separately-triggered SR-G6 (non-T3), generalizing ADR-090; a Maintainability value-extension, not a new discipline | Proposed | 2026-07-25 | intake-and-gate-protocol-hardening |
| [ADR-099](ADR-099-mode-r-disposition-set-fit-test.md) | Milestone-readiness disposition set: closed as a vocabulary, not a cardinality | Proposed | 2026-07-27 | release-hub-mode-r-depth |
| [ADR-100](ADR-100-event-log-payload-pipe-grammar.md) | Event-log payload pipe grammar (escaped `\|` as the canonical multi-value separator) | Proposed | 2026-07-27 | decision-telemetry-emission |
| [ADR-102](ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md) | The quota-budget gate's per-spoke cost successor is the FinOps store's cumulative per-spoke draw, not ADR-026's `spoke-launch` startup reservation | Proposed | 2026-07-28 | agent-finops-intelligence |
| [ADR-105](ADR-105-release-corpus-normalization.md) | The release corpus has two typed file sources and two run-scoped inputs, one projector, and per-field provenance — not one authoritative ledger | Accepted | 2026-08-02 | governance-hardening |
| [ADR-110](ADR-110-composition-lock-at-stage-4-entry.md) | A Milestone's composition is locked to additions at Stage-4 Planning entry; the lock binds the act, not the disposition, and its unmarked state is not eligibility | Proposed | 2026-08-03 | release-bundle-and-sequence-gates |
| [ADR-111](ADR-111-priority-carrier-agnostic-p-level-detection.md) | The P-level digit is the canonical priority satisfier; the carrier is not part of the contract | Proposed | 2026-08-03 | release-bundle-and-sequence-gates |
| [ADR-115](ADR-115-adr-number-claim-binds-at-merge.md) | An ADR number is allocated at authorship and bound at merge; only the mainline binds, and the reconciliation is tooled | Accepted | 2026-08-04 | adr-corpus-conformance |
| [ADR-117](ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) | The ADR index is a derived surface and cannot drift; the conformance claim is scoped to a named baseline and its residual is stated | Accepted | 2026-08-04 | adr-corpus-conformance |
| [ADR-119](ADR-119-selftest-coverage-is-discovered-with-a-committed-manifest-floor.md) | Self-test coverage is discovered against a declared scope, floored by a committed manifest, and gated by a thin caller over a committed engine | Accepted | 2026-08-05 | ci-selftest-and-check-hardening |
| [ADR-123](ADR-123-epic-rollup-close-is-an-audit-not-a-gate.md) | The epic rollup-close surface is an audit, not a gate, and its two undecidable gates are annotated rather than adjudicated | Proposed | 2026-08-07 | methodology-fields-and-statuses |
| [ADR-128](ADR-128-version-tags-are-retained-not-reaped.md) | Version tags are retained, not reaped: the retention rule is homed beside the branch-deletion rule, and the recovery tool reads host policy rather than assuming it | Accepted | 2026-08-06 | hub-spoke-execution-safety |
| [ADR-129](ADR-129-close-class-is-a-declared-deliverable-value-conditioning-one-gate-spec.md) | The close class is a declared deliverable-type value that conditions one gate spec, never a parallel close path | Proposed | 2026-08-07 | 58-task-artifact-lifecycle-and-knowledge |
| [ADR-131](ADR-131-precision-binds-to-the-checks-declared-parameter-surface.md) | A precision obligation binds to the check's declared parameter surface, never to the ACs' self-reported scopes | Proposed | 2026-08-09 | triage-and-backlog-instrumentation |
| [ADR-133](ADR-133-the-material-edit-test-names-an-effect-not-a-field.md) | The material-edit test names an effect, not a field | Proposed | 2026-08-15 | skill-suite-conformance |
| [ADR-135](ADR-135-a-gate-ships-armed-by-a-committed-default.md) | A gate ships armed by a committed default; arming is never deferred to a later step that can be forgotten | Proposed | 2026-08-14 | stage9-gate-integrity |
| [ADR-137](ADR-137-close-out-measurements-reconstruct-what-the-close-removes.md) | A chore-PR-borne close-out measurement reconstructs what the close removes; it does not assume its evidence is invariant | Proposed | 2026-08-21 | closeout-reports-what-shipped |
| [ADR-142](ADR-142-resolve-the-root-do-not-exempt-the-fixture.md) | Self-test reachability at a destructive-scope boundary is restored by resolving the root, not by exempting the fixture | Accepted | 2026-08-24 | selftests-actually-test |
| [ADR-143](ADR-143-trigger-b-counts-rule-defining-surfaces-not-the-ledger.md) | A release-class predicate counts rule-defining surfaces, not the ledger the release is mandated to write | Accepted | 2026-08-24 | pipeline-spec-self-consistency |
| [ADR-144](ADR-144-g1-03-admits-a-second-evidence-shape.md) | G1-03 admits a second evidence shape: label-position probe markers, two co-present, Evidence-section-scoped | Accepted | 2026-08-24 | pipeline-spec-self-consistency |
| [ADR-145](ADR-145-subtype-payload-vocabulary-registry-disjoint-from-the-source-enum.md) | Subtype payload vocabularies are declared in a registry disjoint from the `--source` enum | Accepted | 2026-08-24 | pipeline-spec-self-consistency |
| [ADR-146](ADR-146-supersession-is-an-append-and-integrity-is-a-dated-read-only-sweep.md) | Supersession is an append-only event with a two-id vocabulary, and log integrity is validated by a read-only cutover-dated population sweep | Accepted | 2026-08-24 | pipeline-spec-self-consistency |
| [ADR-147](ADR-147-domain-practice-source-grammar-routes-it-does-not-extend.md) | The domain_practice source grammar is a closed three-form set that ROUTES the unmatched case, and survival across Commit-0 is asserted absolutely rather than only by delta | Accepted | 2026-08-25 | pipeline-spec-self-consistency |
| [ADR-148](ADR-148-surface-1-emit-provenance-not-existence.md) | A backstop records its pre-mutation observation as a witness token, and the downstream check asks provenance rather than existence | Accepted | 2026-08-24 | pipeline-spec-self-consistency |
| [ADR-154](ADR-154-arm-e-population-is-the-directory-never-the-manifest.md) | The tool-coverage engine hosts a second invariant whose population is the directory, never the manifest | Accepted | 2026-08-28 | ci-stable-under-transient-conditions |
| [ADR-156](ADR-156-checkpoint-b-second-axis-is-measured-not-declared.md) | Checkpoint B's second axis is measured, not declared: scoping refuse-to-synthesize to the usage-window axis | Accepted | 2026-08-27 | ci-stable-under-transient-conditions |
| [ADR-157](ADR-157-wave-width-is-a-second-checkpoint-b-output-not-a-verdict.md) | Wave width is a second Checkpoint B output, not a verdict | Accepted | 2026-08-27 | ci-stable-under-transient-conditions |
| [ADR-158](ADR-158-dry-run-predicts-apply-asserts-mode-branch-placement.md) | Dry-run predicts, apply asserts: mode-branch placement in phased close-out tooling | Accepted | 2026-08-27 | ci-stable-under-transient-conditions |
| [ADR-159](ADR-159-one-frontmatter-strip-bound-to-a-conformance-fixture.md) | One frontmatter-strip transform: a shared library bound to a committed conformance fixture, over replication governed by a registry comment | Accepted | 2026-08-28 | ci-stable-under-transient-conditions |
<!-- ADR-INDEX:END -->

ADR-001 / ADR-002 / ADR-005 were migrated from an earlier `governance/adr/` layout; every record after them was authored natively in the modular-monolith layout.

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

This graph is a curated statement of **relationships between records**, not an enumeration of the population — the population is the generated table above. A composition edge is added here only when one record actually extends, supersedes, or is consumed alongside another.

## Authoring new ADRs

New release-scoped ADRs ship through the pipeline at Stage 5 (Solutioning) per [`../references/pipeline/stage-05-solutioning.md`](../references/pipeline/stage-05-solutioning.md). For **when to write an ADR** (the trigger / non-trigger rubric), the copy-paste template, and the supersede-not-edit immutability policy, see [`../../core/standards/adr-authoring-guide.md`](../../core/standards/adr-authoring-guide.md). File path: `release/ADRs/ADR-NNN-<short-slug>.md`.

After authoring, run `python3 release/tools/generate-adr-index.py --write` — **do not hand-add a row.** The index above is a projection; a hand-added row fails `--verify` the moment it diverges from the record, which is exactly the drift this surface was converted to eliminate. Then add cross-references to consuming files via [`../../core/standards/per-stage-shard-standard.md`](../../core/standards/per-stage-shard-standard.md) § Related ADRs (if applicable).

## Status enum

ADR `status:` follows the [Nygard convention](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

| Status | Meaning |
|---|---|
| Proposed | Decision drafted, not yet operator-ratified |
| Accepted | Operator-ratified at Collective Review or equivalent gate |
| Deprecated | Superseded by a later ADR; remains for audit trail |
| Superseded | Replaced; cite the superseding ADR in `## Status` block |

The schema permits an optional prose tail after the leading token (a ratification anchor or a supersession pointer). The generated index above shows the **leading token only** — a ratification promise is tracked on the record and by the Stage-13 flip gate, never in an index.

## Related references

- [`../../core/standards/adr-authoring-guide.md`](../../core/standards/adr-authoring-guide.md) — when to write an ADR (trigger/non-trigger rubric), copy-paste template + worked example, supersede-not-edit policy
- [`../../core/schemas/adr-schema.md`](../../core/schemas/adr-schema.md) — canonical ADR frontmatter + body-section schema (field/section contract)
- [`../../core/ADRs/README.md`](../../core/ADRs/README.md) — core-module curated thematic document (NOT an index — see its own § Format note)
- [`../references/standards/release-corpus-schema.md`](../references/standards/release-corpus-schema.md) — § Derived-Surface Contract, which governs the generated table above
- [`../../core/disciplines/decision-discipline.md`](../../core/disciplines/decision-discipline.md) — decision-class briefing discipline (the sibling; does NOT govern ADR authoring)
- [`../references/pipeline/stage-05-solutioning.md`](../references/pipeline/stage-05-solutioning.md) — Stage 5 ADR materialization process
