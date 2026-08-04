<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Canonical initiative / roadmap / milestone vocabulary + initiative→epic/project label mapping
status: Accepted
date: 2026-06-29
release: 34-terminology-and-controlled-vocabulary
deciders: "Technical Program Manager (operator)"
tags: [terminology, glossary, initiative, roadmap, label-taxonomy, vocabulary, grouping-label, work-hierarchy, reversibility-moderate]
source_observations: "2026-06-29 live corpus survey (baseline e0286d9): glossary Appendix B declared 'Initiative … not modeled'; initiative-roadmap-framework scoped a roadmap to 'one initiative'; the initiative:* label namespace was retired (0 live labels) with grouping migrated to epic:* (8) + project:* (9). The §Initiative-Labels grouping-vs-level prose had already been reframed in a prior release; the dead label rows + the glossary/framework contradictions were the residual delta this ADR closes."
---

# ADR-049 — Canonical initiative / roadmap / milestone vocabulary + initiative→epic/project label mapping

## Status

**Proposed** — flips to Accepted at the Stage 9 review.

Number **049** — next gap-free after 048; binds atomically at Stage 12.

## Context

The platform's terminology contract carried a three-way contradiction about "Initiative" and "Roadmap," verified against live state as of baseline `e0286d9` (2026-06-29):

1. **Glossary Appendix B** listed `Initiative` as a "Portfolio-level concept not modeled at platform layer" — directing the reader to Milestone or "cross-Milestone roadmap theme," i.e. asserting the concept is *not* modeled.
2. **The initiative-roadmap framework** (`core/standards/initiative-roadmap-framework.md`) scoped a roadmap to **"one initiative"** in its §2.1 artifact-hierarchy diagram and its Vision-vs-Roadmap boundary clarification.
3. **The label namespace** that once carried "initiative" — `initiative:*` — **was retired**: 0 live labels. The 3 example rows documented in `label-taxonomy.md § Initiative Labels` (`initiative:project-data-architecture`, `:template-architecture`, `:knowledge-architecture`) plus an unregistered-sibling note all referenced labels that no longer exist. Cross-milestone grouping now rides two live namespaces: **`epic:*`** (8 labels — the skill-suite thrusts) and **`project:*`** (9 labels — cross-cutting initiatives). The `area:*` namespace named in the originating issue's acceptance criteria **never existed** (0 labels) — the live replacement namespaces are `epic:*` + `project:*`.

A prior release had already reframed the `§ Initiative Labels` *prose* ("an initiative label is a grouping mechanism, not a hierarchy level") and named `work-organization-mapping-framework.md` as the work-hierarchy SSOT. That left the dead label *rows*, the glossary "not modeled" assertion, and the framework's "one initiative" scoping as the residual contradiction this ADR closes. The work-hierarchy SSOT fixes the levels — Portfolio → Program → Project → Milestone/Workstream → Work Item — and **excludes Initiative as a level**; this ADR's canonical wording adopts that established corpus position rather than inventing a new one.

## Decision

1. **Canonical `Initiative`** = a **multi-milestone grouping theme; not a hierarchy level** — a cross-milestone grouping label (`epic:*` / `project:*`), never a container tier or a `parent_ref` target. Recorded as glossary `{#term-initiative}` (Category 6).
2. **Canonical `Roadmap`** = an **architected path across milestones; may span one or more initiatives** — one-per-initiative is the **default**, not a definitional limit. Program-altitude, Living. Recorded as glossary `{#term-roadmap}` (Category 6). This resolves the framework's "one initiative" scope by reframing it as the default case (preserving the existing one-initiative pilot roadmaps as conformant) rather than a hard limit.
3. **`Milestone`** is already canonical (glossary `{#term-milestone}`, scope-boxed grouping that ships as one release) — affirmed, no change.
4. **Label mapping.** The retired `initiative:*` namespace maps to the two live grouping namespaces by role: **`epic:*`** for the skill-suite thrusts, **`project:*`** for cross-cutting initiatives. Initiative-the-concept maps to the grouping-label *namespaces*, NOT to a dedicated Projects single-select field — a Projects "Initiative" field is an OPTIONAL future add, not a dependency of this decision (the grouping signal already rides labels today, and standing up Projects board structure on the public repo is constrained by operator policy). The ADR cites the namespaces by role; the enumerated live-label list lives in `label-taxonomy.md` (the labels SSOT), which tracks label churn.
5. **SSOT discipline.** The glossary is the single source of truth for the term wording; `initiative-roadmap-framework.md` and `label-taxonomy.md` **cite** the canonical terms, never re-define them (parameterize / cite-not-duplicate).

## Alternatives Considered

The canonical wording itself was constrained rather than chosen — § Context records that the work-hierarchy SSOT already fixes the levels and excludes Initiative as one, so this record *adopts that established corpus position rather than inventing a new one*. Three genuine alternatives are named in § Decision.

- **Map Initiative to a dedicated Projects single-select field** — **not taken.** § Decision item 4 maps Initiative-the-concept to the grouping-label *namespaces* instead: the grouping signal already rides labels today, and standing up Projects board structure on the public repo is constrained by operator policy. A Projects field remains an optional future add, not a dependency of this decision.
- **Enforce the framework's "one initiative" scoping as a hard limit** — **not taken.** § Decision item 2 reframes it as the *default* case, which preserves the existing one-initiative pilot roadmaps as conformant; a hard limit would have made them non-conformant.
- **Enumerate the live grouping labels in this record** — **not taken.** § Decision item 4 cites the namespaces by role and leaves the enumerated live-label list in the labels SSOT, which tracks label churn.

§ Decision item 3 records the corresponding non-change: the already-canonical `Milestone` term is affirmed rather than re-litigated.

## Consequences

- The glossary gains two canonical terms (`Initiative`, `Roadmap`) in Category 6 and its Appendix B Initiative row no longer asserts "not modeled" — it redirects to the canonical term.
- `initiative-roadmap-framework.md` gains an additive canonical-scope note; the existing one-initiative narrative is preserved, so the existing pilot roadmaps remain conformant (now explicitly the "default case").
- `label-taxonomy.md § Initiative Labels` documents the live `epic:*` / `project:*` grouping namespaces in place of the dead `initiative:*` rows; a reader's `gh label list` now matches the doc.
- An autonomous agent reading the corpus cold can resolve what Initiative and Roadmap canonically mean from the glossary alone, reconciled with the framework and the live label namespace.
- Runtime blast radius: **none** — no code consumes these terms; the change is governance/reference vocabulary only.

## Reversibility

**MODERATE** — the change ripples canonical vocabulary into the glossary, the framework, and the label taxonomy. Runtime effect is none (no consumer code). Revert is a single-PR `git revert` of the release merge commit (D-C SINGLE topology), which removes this ADR and its README registration together; `check-adr-numbers.py` stays gap-free because 049 was the highest number.

## Related ADRs

- [ADR-012](ADR-012-roadmap-instance-descope.md) — roadmap-instance de-scope (roadmap *framework* retained as convention; instances operator-local).
- [ADR-046](ADR-046-roadmap-instance-in-repo-home.md) — roadmap-instance in-repo home (`/roadmaps/` default + token override).
- [ADR-018](ADR-018-work-item-type-layer.md) — Work-Item Type Layer (the thin-generic-entity decision; "Initiative is not a level" aligns with the methodology-invariant hierarchy this ADR cites).
- [ADR-007](ADR-007-core-module-boundary.md) — establishes the Stage-6 ADR-authoring precedent this ADR follows.
