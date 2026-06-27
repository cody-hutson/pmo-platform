<!-- reference-durability: allow-link -->
---
title: ADR-046 — Roadmap-instance in-repo home — shipped /roadmaps/ folder + token-as-override
status: Proposed (supersedes-in-part ADR-012's location clause; flips to Accepted at the Stage 9 review)
date: 2026-06-27
release: 40-initiative-roadmap-vocabulary-and-home
deciders: "Workspace owner (architecture ratified at the Stage 9 review); design authored at Stage 5 Solutioning"
supersedes: ADR-012 (location clause only)
tags: [architecture, roadmaps, plug-and-play, in-repo-home, git-ignored, token-override, analysis-workspace-pattern, reversibility]
---

# ADR-046 — Roadmap-instance in-repo home — shipped `/roadmaps/` folder + token-as-override

## Status

**Proposed — supersedes-in-part [ADR-012](ADR-012-roadmap-instance-descope.md) (its *location* clause only).** ADR-012 de-scoped roadmap *instances* from the tracked tree to operator-local authoring at the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token, which left "where do they live?" as an unresolved per-instance question. This ADR resolves the location; ADR-012's "instances are **not tracked**" decision is preserved unchanged. Flips to Accepted at the Stage 9 review.

## Context

ADR-012 corrected an over-coupling (roadmap instances should not be tracked platform content) but replaced a concrete home with an abstract token, so no fixed location ships on install — the three `*/governance/roadmaps/` dirs are git-ignored with no tracked marker and therefore do not exist on a fresh clone. The platform already solved this exact shape for read-once analysis: the `analysis/` workspace (`analysis-workspace-standard.md`) ships a tracked folder + `README` while git-ignoring all content. Roadmap instances are the same kind of operator-local working material.

## Decision

1. **Roadmap instances get a single canonical in-repo home: repo-root `/roadmaps/`.** The folder + its `README.md` ship tracked; every instance under it is git-ignored. This is the `analysis/` pattern (`/<dir>/*` ignored, `!/<dir>/README.md` tracked) applied to roadmaps — the folder exists on a fresh clone, the instances never enter git history. Supersedes ADR-012's per-instance location indirection; preserves its "not tracked" decision.

2. **The `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token is redefined as the override indirection, not eliminated.** Its **default resolution is `/roadmaps/`**; a deployment may repoint it elsewhere for plug-and-play storage. Existing token references continue to resolve — they now point at the shipped folder by default. The token is the seam; the folder is the default value.

3. **The hierarchy stays invariant.** A roadmap is a cross-milestone grouping artifact, not a container tier — consistent with the work-item hierarchy being methodology-invariant (`work-organization-mapping-framework.md`). This ADR governs *where instances are stored*, not the work hierarchy.

## Consequences

- **Plug-and-play home ships out of the box.** Agents and operators have a known default location without per-user configuration, while users who need bespoke storage repoint one token. The `analysis/`-pattern precedent means one mechanism governs both operator-working-material folders.
- **ADR-012 is preserved as a historical record** (immutable-ADR posture); it carries a supersession-in-part pointer to this ADR for the location clause only — its de-scope, framework-retention, and enforcement-drop decisions stand.

## Reversibility

**MODERATE** — folder + `.gitignore` idiom + token-default redefinition + framework/template reconcile; revertable in days (`git revert` + token-default rollback), no data loss.
