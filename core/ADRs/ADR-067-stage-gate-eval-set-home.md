<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-067 — Stage-gate eval-set home: pipeline stage-gate eval sets live at core/skills/eval-writer/evals/stage-gates/<gate>/evals.json, kept out of eval-writer's demonstration evals.json"
status: Accepted
date: 2026-07-02
release: 83-eval-framework-completion
tags: [eval-framework, eval-writer, stage-gate, canonical-home, placement-correctness, pipeline, core, knowledge-architecture]
source_observations:
  - "Originating need (eval-framework-completion): two eval-framework cards author stage-gate eval content into the eval-writer skill area in the same release — a Stage-3 Bundle gate eval set (11 typed assertions + an escape-rate metric) and a Stage-7 Dev Testing branch-freshness assertion. Both cards' Stage-5 designs flagged the exact sub-path + layout as a Collective-Review reconciliation item: if the two land in divergent layouts, the eval home forks on its first two occupants."
  - "Dead-path reconciliation (Stage 5 survey, 2026-07-02): the stage-gate playbook's nominal default output path core/schemas/gate-prompts/<gate-id>/ does not exist in the live tree (no gate-prompts/ directory anywhere), and its companion calibration-data path is dead. So the playbook's documented home cannot be adopted as-is — it would require standing up an absent directory tree for a single assertion."
  - "Live precedent (Stage 5 survey, 2026-07-02): the corpus already homes a non-skill, discipline/stage-scoped eval SET with typed assertions at core/disciplines/evals/people-graph-consumption/evals.json — a header block plus a typed-assertions array. This is the nearest precedent for a stage-gate eval set and the layout this ADR canonicalizes mirrors it (one directory per set)."
---

# ADR-067 — Stage-gate eval-set home (per-gate directories under eval-writer's evals/stage-gates/)

## Status

Accepted — operator-ratified at this release's Collective Review scope-lock (the Status-enum gate the core-ADR README names: "Operator-ratified at Collective Review or equivalent gate"). Authored at Stage 6 per the Stage-6 ADR-authoring precedent, jointly for the two eval-framework cards that co-author into the stage-gate eval home (the Stage-3 Bundle gate eval set and the Stage-7 Dev Testing branch-freshness assertion) so the home is recorded once, not in two competing ADRs.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/`, resolved at the authoring commit with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. Referenced downstream **by slug**, never by number. Extended or reversed only by a **successor / superseding ADR** — never by an in-place edit of this record.

**Deliberate `deciders`-field omission.** This ADR is authored **without** a `deciders` frontmatter field, pending ratification of the literal-name `deciders` convention (not yet landed). The core-ADR README frontmatter template lists `deciders`; this ADR is a deliberate exception to that template until the convention resolves. The omission is not a defect — do not add the field before the convention lands. (Consistent with the immediately-preceding ADR-065, authored under the same pending convention.)

## Context

The eval framework gained stage-gate eval content in this release: assertion-cluster eval sets that grade the **output of a pipeline stage gate** (as opposed to per-skill eval suites, which grade a skill's own output). Two such sets were authored concurrently — a Stage-3 Bundle gate eval set and a Stage-7 Dev Testing branch-freshness assertion — and both home into the eval-writer skill area. The **area** was already resolved (the eval-writer skill, `core/skills/eval-writer/`); the **exact sub-path and file layout** were not, and both cards' Stage-5 designs escalated the layout to Collective Review to prevent the two sets diverging on their first occupancy of the home.

Three placement facts drove the decision:

1. **The stage-gate playbook's nominal default home does not exist.** The playbook documents `core/schemas/gate-prompts/<gate-id>/` as the default output path for gate content, but no `gate-prompts/` directory exists anywhere in the live tree, and its companion calibration-data path is dead. Adopting it would mean standing up an absent tree for a single assertion — the opposite of reuse-first.

2. **A live precedent exists for a non-skill, stage/discipline-scoped eval set with typed assertions.** `core/disciplines/evals/people-graph-consumption/evals.json` is exactly that shape — a header block plus a typed-`assertions` array, one directory per set. Every eval set in the corpus is a single `evals.json` under an `evals/` (or `evals/<set>/`) directory.

3. **eval-writer already carries its own demonstration `evals.json`.** That file (`core/skills/eval-writer/evals/evals.json`) holds the skill's *own* worked-example evals (the demonstration suite). Folding stage-gate content into it would mix two concerns — the skill's self-demonstration and the platform's stage-gate judgment content — in one file and one escape-rate accounting.

## Decision

**Pipeline stage-gate eval sets are homed at `core/skills/eval-writer/evals/stage-gates/<gate>/evals.json` — one directory per gate — and are kept OUT of eval-writer's demonstration `evals.json`.**

Concretely:

1. **Per-gate directories.** Each stage-gate eval set lives in its own sub-directory under `core/skills/eval-writer/evals/stage-gates/`, named for the gate (e.g. `stage-03-bundle/`, `stage-07-dev-testing/`), each containing a single `evals.json`. This mirrors the `core/disciplines/evals/<set>/` precedent — one directory per set — so each stage-gate set is independently runnable and versionable, and the escape-rate accounting stays per-set (not merged across gates).

2. **Kept out of the demonstration suite.** The stage-gate sets are NOT appended to `core/skills/eval-writer/evals/evals.json`. eval-writer authors stage-gate content; it does not fold that content into its own demonstration evals. The demonstration file stays a demonstration file.

3. **One shared index.** A single `core/skills/eval-writer/evals/stage-gates/README.md` indexes every stage-gate set, restates the escape-rate metric for human readers, and carries any cross-set records (such as the dated calibration-aggregation deferral this release records). There is exactly one index — not one per set.

4. **Schema conformance.** Every stage-gate set conforms to the live eval schema (header + `evals[]`; each eval `{id, name, prompt, expected_output, files, assertions[]}`; each assertion `{text, type}` with `type` binary — `structural` = mechanically checkable / `judgment` = a single binary LLM-judge call). **No Likert scale** — binary judges only, per the eval-writer consensus and consistent with the `people-graph-consumption` precedent (typed, binary).

The eval framework's people-graph-consumption discipline eval set is the cited precedent for the layout (one directory per set, header + typed assertions); this ADR extends that same shape to the stage-gate class and fixes its home under the eval-writer skill area.

## Alternatives Considered

- **(A — one combined stage-gate set file.)** Home all gates' evals in a single `core/skills/eval-writer/evals/stage-gates/evals.json`, distinguished by an eval-name prefix. REJECTED — it mixes multiple gates' escape-rate accounting in one header and couples the merge order of independent cards. It buys fewer files at the cost of a muddied per-gate escape-rate metric. The per-gate-directory layout keeps each gate's metric and lifecycle separate.

- **(B — the playbook's `core/schemas/gate-prompts/<gate-id>/` default.)** Adopt the stage-gate playbook's documented default output path. REJECTED — the `gate-prompts/` tree does not exist in the live tree and its companion calibration path is dead; adopting it would require standing up an absent directory tree for the first set, against reuse-first / minimal-addition. (A future consolidation could revisit if a `gate-prompts/` tree is ever materialized for other reasons — not this release.)

- **(C — fold stage-gate evals into eval-writer's demonstration `evals.json`.)** Append the stage-gate evals as new objects in the existing demonstration suite. REJECTED — it conflates the skill's self-demonstration with platform stage-gate judgment content and merges their escape-rate accounting. The demonstration file must stay a demonstration file.

- **(D — the abandoned `engineering/evals/eval-sets/` path.)** Home the sets at the path named in the cards' original (pre-re-versioning) bodies. REJECTED — that path is dead (the `engineering/` eval tree was removed in the module restructure); it is historical-record only, not a live surface.

## Consequences

- **+ One canonical, recorded home for stage-gate eval sets.** The layout question the two co-authoring cards raised is settled and citable by slug: per-gate directories under `evals/stage-gates/`, out of the demonstration suite, one shared index. Future stage-gate sets extend the index rather than re-litigating the home.

- **+ Per-set escape-rate accounting preserved.** Because each gate gets its own directory and header, its escape-rate metric is tracked independently — a wide release touching several gates does not smear one gate's rate into another's.

- **+ Divergence guard for the co-authoring cards.** The two eval-framework cards that share this home in this release land in one consistent layout (shared `stage-gates/` prefix, shared header-key convention, single index, one ADR) — the exact fork this ADR exists to prevent.

- **− Stage-gate content lives under the eval-writer *skill* directory, not a schema/gate directory.** A reader might expect gate content under `core/schemas/`. This is a conscious placement: the eval-writer skill is the resolved owner of eval-authoring content, the schema/gate default path does not exist, and the discipline-eval precedent already homes non-skill eval sets under a skill/discipline `evals/` tree. Should a `gate-prompts/` tree ever be materialized platform-wide, a successor ADR may consolidate — but that is not urgent (the current home is correct, single-owner, and precedented).

## Reversibility

**CHEAP / Confidence HIGH.** The decision RECORDS a directory layout for net-new files (the stage-gate sets, the index, and this ADR are all additive). `git revert` of the release PR restores prior state — no data migration, no routing primitive / schema / executable touched, no existing eval set moved. Relocating the home later is a file move plus an index/link update.

## Related ADRs

- **ADR-061** (trigger-rate metric class and eval-writer boundary) — establishes the eval-writer boundary this ADR builds on: eval-writer authors eval content (here, stage-gate sets); it does not own the runtime that executes them. ADR-067 places the authored stage-gate content within that boundary.
- **ADR-065** (health-RAG band canonical home) — the immediately-preceding placement-correctness ADR authored under the same pending-`deciders` convention; ADR-067 follows its frontmatter form and deliberate `deciders`-omission precedent.
- **ADR-007** (cross-module doc-link posture) — the markdown-doc-link edges this ADR's index and the Stage-7 doc reference rely on (eval home ↔ pipeline shard ↔ runner) are sanctioned markdown-doc-links, not code edges.
