---
title: ADR-003 — Operating Model Composition (cardinality, citation discipline, cross-reference pattern)
status: Accepted
date: 2026-05-10
deciders: "operator + Stage 5 Solutioning spoke"
tags: [architecture, governance, operating-model, composition, role-skills]
source_observations:
  - Stage 4 release plan (D-Operating-Model-Sections = A, D-182-vs-519-Boundary = A)
  - Stage 5 spec (D-182-Stage-Row-Schema, D-182-Citation-Discipline, D-182-Cross-Ref-Pattern)
  - Collective Review record 2026-05-10 (CONFLICT-1 ADR numbering = three sequential; CONFLICT-2 cross-ref pattern = data-inline)
---

# ADR-003 — Operating Model Composition (cardinality, citation discipline, cross-reference pattern)

## Status

Accepted (operator decision rendered at Stage 4 D-Operating-Model-Sections 2026-05-07; design surfaces resolved at Stage 5 spec 2026-05-10; ADR authored at Stage 6 per Stage 5 spec § 6 ADR Recommendation; numbered ADR-003 per Collective Review CONFLICT-1 resolution 2026-05-10 — three sequential ADRs: ADR-002, ADR-003 (this ADR), ADR-004).

## Context

[`core/disciplines/operating-model.md`](../disciplines/operating-model.md) is the composition view of the PMO platform — it composes three layers (Skill Ownership, Governance Composition, Per-Stage Execution Blueprint) into a single reference for downstream consumers. It is foundational governance architecture; the skill-build wave and role-skill wave compose against the file's per-stage execution blueprint as their build spec. The cardinality model, citation discipline, and cross-reference pattern adopted in the file are non-obvious choices among plausible alternatives; preserving the rationale here protects future authors from re-litigating these decisions without surfacing the prior evidence.

Three load-bearing design choices were made during authoring. Each shapes how operating-model.md interacts with the rest of the platform's governance corpus, and each has plausible alternatives that a future author may want to revisit. Recording rationale now prevents the rationale from being lost if the file is re-organized in a later release.

## Decision

### Decision 1 — Cardinality model: declared-primary-with-secondaries

The platform's skill-to-stage binding is **many-to-many with declared primary**. A skill may own (be the primary executor of) multiple stages or modes; a stage may have one primary skill plus secondary skills (cross-cutting flags, friction logs, regression checks). Stages with no current owner are documented as **GAP** with forward-reference to the skill-build milestone that will fill them. Four cardinality types apply: 1:1, 1:many, many:1, 0:1 (GAP).

**Rationale.** Three plausible alternatives were considered. Strict 1:1 (each stage → exactly one skill) would force artificial bundling — Stage 7 Dev Testing today legitimately has multiple skill owners (`pmo-qa-auditor` Modes A+D for skill outputs and governance docs respectively, plus `pmo-skill-editor` Mode C for skill-modification PRs), and forcing a single owner would either degrade review coverage or fragment the skill ownership unnaturally. Phase-per-skill bundling (group stages by phase, assign one skill per phase) would break the canonical [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) row-per-stage alignment and lose the per-stage execution-tier classification that the release pipeline depends on. Many-to-many without a declared primary would lose the "who owns this stage's gate decision" affordance — every gate decision needs an accountable executor, even when multiple skills contribute. Declared-primary-with-secondaries is the only scheme that honors empirical many-to-many reality (Stage 7's multi-skill ownership; `release-planner` covering Stages 3+4+10) while preserving accountability at the gate level. The four cardinality types make the empirical reality enumerable: when a stage is described as "GAP" with a forward-ref, the skill-build consumers know exactly what skill is expected to fill it. See [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) § Gaps for the current 5 gaps (G1-G5) with their forward-reference milestones — the cardinality model is what makes that gap-vs-coverage classification possible.

### Decision 2 — Cite-not-duplicate citation discipline

operating-model.md cites existing canonical sources rather than duplicating their content. Specifically: [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) is cited for the "Owning Skill" row in each per-stage block (the canonical Stage → Skill → Mode binding lives there); [`schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) is cited for the "Quality Gate" row (per-stage gate criteria G1-G3 and planned G7/G8/G13 live there); [`schemas/stage-io-contracts.md`](../schemas/stage-io-contracts.md) is cited for the "Handoff Contract" row (per-boundary I/O contracts live there); [`github-projects-guide.md`](../disciplines/github-projects-guide.md) and [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) are cited for the "Tracking Actions" row (field IDs and lifecycle live there); [`pipeline/stage-NN-<name>.md`](../../release/references/pipeline) is cited for the "Canonical definition" sub-row (the 10-point definition of each stage lives there).

**Rationale.** This decision is a direct application of [`architecture-overview.md`](../disciplines/architecture-overview.md) Key Principles § 1 — "One source, one truth: every file has exactly one authoritative location." The alternative considered was duplicate-inline: restate each schema's row contents directly in operating-model.md so the file is self-contained and a reader does not need to chase links across multiple files. Duplicate-inline was rejected on two grounds. First, the maintenance cost is unbounded — every schema change (e.g., a new G2-05 criterion added to [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) Gate 2, or a new boundary added to [`stage-io-contracts.md`](../schemas/stage-io-contracts.md)) would require updating operating-model.md as well, creating a guaranteed drift target. Second, duplicate-inline creates a dual source of truth: when operating-model.md and the cited schema disagree, downstream consumers do not know which to trust. The cite-not-duplicate discipline is fragile when sources move (anchor link breakage) but robust against semantic drift (the source of truth never drifts because there is only one). The fragility is mitigated by structurally consistent anchor patterns (`#gate-1` / `#boundary-stage-N--stage-N+1`) that change infrequently and are caught by [`./deploy.sh --check`](../deploy/deploy.sh) drift checks. The drift cost is bounded; the semantic-drift cost (under duplicate-inline) is not.

### Decision 3 — Cross-reference pattern with the function-spine companion document: data-inline + single column-header note

operating-model.md and [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md) are cross-referenced as follows: operating-model.md's per-stage blocks inline the Primary Function name from the spine doc's function-mapping table as plain-text data in a `**Universal Function:** <name>` sub-row (e.g., `**Universal Function:** Executing` for Stage 6 Engineering). A single column-header note above § 3.2 cross-references the spine doc once (link only) for readers wanting Secondary Functions, Cross-Cutting Flow touchpoints, and per-stage Primary-classification rationale. Reciprocally, the spine doc cites operating-model.md once in its Related References section. Total cross-references between the two files: 2 (1 per direction).

**Rationale.** The Stage 5 spec originally proposed Pattern B (bidirectional per-stage pointers — 13 hyperlinks per file, 26 total cross-references; see § 5 Pattern B for the rejected design). Collective Review post-Stage-5 identified this as a coherence threshold violation: 26 cross-references between two files would create cross-file hop fatigue (readers must navigate between files for the full per-stage picture) and would be redundant — once a reader is on operating-model.md and learns the Primary Function for Stage 6 is "Executing", they already have the answer the spine doc would give them; chasing a hyperlink to confirm wastes attention. The selected pattern (CONFLICT-2 resolution = data-inline + single column-header note) preserves the data contract (operating-model.md still carries the Primary Function value per stage) while collapsing cross-file traffic from 26 to 2. The trade-off accepted is that readers wanting Secondary Functions or Cross-Cutting Flow touchpoints must follow the single column-header note cross-reference — but those readers are explicitly opting into the spine doc's deeper view, whereas Pattern B would have imposed cross-file navigation on every reader at every stage. The 1-direction-each-way pattern reflects a minimum-coupling discipline: between two files that are conceptually independent but mutually referable, prefer two small cross-refs (one per direction) over many bidirectional pointers — bidirectional density signals that the two files should probably be merged, while sparse mutual reference signals that the separation is load-bearing. The Stage 4 spoke author judgment cited the same principle ("structurally independent... weak mutual reference possible but not blocking").

## Consequences

**Positive:**

- **Downstream consumer reuse.** The skill-build wave and role-skill wave compose against operating-model.md's per-stage execution blueprint as their build spec. The declared-primary-with-secondaries cardinality model makes the build target enumerable per stage.
- **Drift is bounded.** Cite-not-duplicate means schema updates do not require operating-model.md updates; the file inherits new criteria automatically as long as anchor links resolve. [`./deploy.sh --check`](../deploy/deploy.sh) catches anchor drift.
- **Cross-file traffic is finite.** The 2-cross-reference pattern between operating-model.md and the function-spine doc means readers can read either file end-to-end without context-switching for the dominant use case (per-stage execution composition view OR per-stage function classification view).
- **GAP / coverage classification is enumerable.** The cardinality model's 0:1 type makes platform gaps explicit. Stages 1, 2, 6, 9 are GAP (per [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) G1, G2, G4, G5); Stage 5 is partial-fit (G3). The skill-build and role-skill wave milestones know exactly what they are filling.
- **Per-skill ownership is grounded in evidence.** The 22-entry ownership manifest in operating-model.md § 1.3 derives each out-of-scope statement from the skill's own SKILL.md `## Operating Principles` section — not invented for the manifest. Skills citing operating-model.md cannot diverge from their own declared scope.

**Negative:**

- **Cite-not-duplicate creates anchor dependencies.** If `gate-criteria-spec.md` is restructured and Gate 2's anchor changes, every per-stage Quality Gate citation in operating-model.md breaks until the cited file is also updated. Mitigated by structural anchor patterns (`#gate-N`) that are themselves load-bearing and unlikely to change.
- **Per-skill manifest must be refreshed when SKILL.md Operating Principles change.** The 22-entry manifest in § 1.3 cites SKILL.md content verbatim in some cases (e.g., `release-planner`'s "Read-only. The only file you write is the release plan file"). If a SKILL.md Operating Principles update changes the skill's scope, the manifest entry must be updated. Mitigated by the harness-changes-governed discipline — SKILL.md changes route through `pmo-skill-editor`, which can flag downstream manifest references.
- **Per-skill SKILL.md updates are deferred (AC7).** operating-model.md as a reference doc is operative without per-skill SKILL.md updates citing it back. But for skills to actually read operating-model.md at invocation (rather than only at human-author time), per-skill SKILL.md `## Operating Principles` sections will need a cite-operating-model.md addition. This is a 22-file PR appropriate for a follow-on milestone. This release ships the reference doc only; downstream skill-update milestone enforces consumption.
- **Cardinality model is hard to revise post-production.** Once role-skills compose against the declared-primary-with-secondaries model, switching to a different cardinality scheme (e.g., phase-per-skill bundling) would require re-architecting every skill-build that has shipped. Mitigated by Decision 1's rationale paragraph — the alternatives were considered up front and rejected with evidence, making future re-design less likely.

**Mitigation of negatives:**

- Anchor-dependency drift is caught by [`./deploy.sh --check`](../deploy/deploy.sh) drift checks; per-anchor structural patterns (`#gate-N`, `#boundary-stage-N--stage-N+1`, `#stage-NN-<name>`) are themselves stable.
- Per-skill manifest drift is mitigated by `pmo-skill-editor` routing — when a SKILL.md edit changes scope, the editor's diff-context surface can flag the operating-model.md manifest entry as needing review.
- AC7 (per-skill SKILL.md cite-operating-model.md updates) is explicitly deferred to a follow-on milestone, not lost — the operating-model.md author paragraph closing § 1.2 documents the deferral as a known load-bearing follow-on.
- Cardinality model revision (if ever needed) is governed by a new ADR that supersedes this one, following the same operator-decision discipline (operator-rendered at Stage 4 2026-05-07).

## Alternatives Considered

### Decision 1 alternatives

- **(A) Strict 1:1 (each stage → exactly one skill)** — REJECTED. Misrepresents empirical reality at Stage 7 (multi-skill ownership: `pmo-qa-auditor` Modes A+D + `pmo-skill-editor` Mode C). Forcing single ownership would either degrade review coverage or split skills unnaturally.
- **(B) Phase-per-skill bundling (group stages by phase, assign one skill per phase)** — REJECTED. Breaks the canonical [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) row-per-stage alignment and loses the per-stage execution-tier classification. The platform's release-pipeline gate-decision granularity is per-stage, not per-phase.
- **(C) Declared-primary-with-secondaries (selected).**
- **(D) Many-to-many without a declared primary** — REJECTED. Loses the gate-decision accountability affordance — every gate decision needs an accountable executor, even when multiple skills contribute. Cardinality without a primary cannot answer "who owns this stage's gate" for Stages 7-8.

### Decision 2 alternatives

- **(A) Cite-not-duplicate (selected).**
- **(B) Duplicate-inline (restate schema row contents directly in operating-model.md)** — REJECTED. Unbounded maintenance cost (every schema change requires updating operating-model.md); guaranteed drift target; creates dual source of truth. Violates [`architecture-overview.md`](../disciplines/architecture-overview.md) Key Principle § 1 "One source, one truth."

### Decision 3 alternatives

- **(A) Data-inline + single column-header note (selected per Collective Review CONFLICT-2 resolution).**
- **(B) Bidirectional per-stage pointers (13 hyperlinks per file, 26 total cross-references — Stage 5 spec § 5 Pattern B)** — REJECTED. Coherence threshold violation (cross-file hop fatigue); redundant for the dominant reader use case (reading operating-model.md and seeing `**Universal Function:** Executing` answers what a hyperlink to spine doc would also answer). The spoke author judgment cited at Stage 4 ("structurally independent... weak mutual reference possible but not blocking") set the precedent the Collective Review then formalized.
- **(C) No cross-reference (zero hyperlinks between the two files)** — REJECTED. Loses the reciprocal-navigation affordance — readers on one file cannot discover the companion file. The Related References section in the spine doc and the column-header note in operating-model.md preserve reciprocity at minimum density.

## Reversibility

**EXPENSIVE.** Once role-skills are shipped composing against this operating-model.md, revising any of the three decisions cascades:

- **Cardinality model revision** would require updating every skill-build that consumes operating-model.md (potentially 5+ role-skill files in the role-skill wave alone) plus updating [`stage-to-skill-mode-mapping.md`](../../release/references/specs/stage-to-skill-mode-mapping.md) per-row entries.
- **Citation discipline revision** (switching to duplicate-inline) would require re-authoring operating-model.md to inline all cited schema content, plus establishing a drift-detection mechanism for the new dual-source state.
- **Cross-reference pattern revision** (switching to bidirectional 26-cross-ref pattern) would require adding 24 cross-references (12 new per stage in operating-model.md, 12 new in the spine doc), plus updating ADR-004's Decision 1 rationale (which currently cites the 2-cross-ref total as a positive consequence of Primary+Secondary scheme).

Reversal is structurally possible but operationally expensive — comparable to ADR-004's cardinality decision in terms of downstream cascade scope. Decision revision should be accompanied by a new ADR superseding this one, citing the new evidence that justifies the revision.

A row-level revision within the existing decisions (e.g., one skill's per-stage ownership updates from primary to secondary, or one anchor cite updates because a schema is restructured) is CHEAP — operating-model.md is a reference document and row-level edits cascade via standard pipeline workflow.

## References

- Parent issue — Architecture: Operating model (skill ownership, governance composition, stage execution blueprint)
- Stage 5 spec (D-182-Stage-Row-Schema, D-182-Citation-Discipline, D-182-Cross-Ref-Pattern, D-182-ADR-Recommendation)
- Stage 4 release plan (operator decision record D-Operating-Model-Sections = (A); D-182-vs-519-Boundary = (A); 2026-05-07)
- Collective Review record (CONFLICT-1 ADR numbering = three sequential ADR-002/003/004; CONFLICT-2 cross-ref pattern = (A) data-inline + single column-header note; 2 total cross-refs with spine doc)
- Companion file: [`core/disciplines/operating-model.md`](../disciplines/operating-model.md)
- Companion ADR: [`ADR-004-five-function-spine.md`](ADR-004-five-function-spine.md) (authored on this PR's feature branch ahead of this ADR)
- Companion ADR: [`ADR-002-modular-pipeline-stages-split.md`](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md) (authored on the release branch — modular `pipeline/stage-NN-<name>.md` paths cited throughout operating-model.md depend on this PR's cascade)
- Foundational principle: [`architecture-overview.md`](../disciplines/architecture-overview.md) Key Principles § 1 "One source, one truth"
- Stage 6 spoke output (this Engineering execution)
