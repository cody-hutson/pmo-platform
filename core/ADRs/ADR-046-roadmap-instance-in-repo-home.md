<!-- reference-durability: allow-link -->
---
title: ADR-046 — Roadmap-instance in-repo home — shipped /roadmaps/ folder + token-as-override
status: Accepted
date: 2026-06-27
release: 40-initiative-roadmap-vocabulary-and-home
deciders: "Workspace owner (architecture ratified at the Stage 9 review); design authored at Stage 5 Solutioning"
supersedes: ADR-012 in-part (location clause), ADR-017 in-part (roadmaps placement in the operator-instance path family)
tags: [architecture, roadmaps, plug-and-play, in-repo-home, git-ignored, token-override, analysis-workspace-pattern, operator-instance-path-family, migration, reversibility]
---

# ADR-046 — Roadmap-instance in-repo home — shipped `/roadmaps/` folder + token-as-override

## Status

**Proposed — supersedes-in-part [ADR-012](ADR-012-roadmap-instance-descope.md) (its *location* clause) and ADR-017 (the roadmaps member of the operator-instance path family).** ADR-012 de-scoped roadmap *instances* from the tracked tree to operator-local authoring at the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token; ADR-017 then centralized that token under the `personal/pmo-instance/` operator-instance path family. Between them, roadmaps resolved to `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/roadmaps` — operator-local, outside the repo, with no folder shipped on install. This ADR moves the *location* in-repo; ADR-012's "instances are **not tracked**" decision is preserved unchanged (instances stay git-ignored). Flips to Accepted at the Stage 9 review.

## Context

ADR-012 corrected an over-coupling (roadmap instances should not be tracked platform content) but replaced a concrete home with an abstract token, so no fixed location ships on install — the three `*/governance/roadmaps/` dirs are git-ignored with no tracked marker and therefore do not exist on a fresh clone. The platform already solved this exact shape for read-once analysis: the `analysis/` workspace (`analysis-workspace-standard.md`) ships a tracked folder + `README` while git-ignoring all content. Roadmap instances are the same kind of operator-local working material.

## Decision

1. **Roadmap instances get a single canonical in-repo home: repo-root `/roadmaps/`.** The folder + its `README.md` ship tracked; every instance under it is git-ignored. This is the `analysis/` pattern (`/<dir>/*` ignored, `!/<dir>/README.md` tracked) applied to roadmaps — the folder exists on a fresh clone, the instances never enter git history. Supersedes ADR-012's per-instance location indirection; preserves its "not tracked" decision.

2. **The `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token is redefined as the override indirection, not eliminated.** Its **default resolution is `/roadmaps/`**; a deployment may repoint it elsewhere for plug-and-play storage. Existing token references continue to resolve — they now point at the shipped folder by default. The token is the seam; the folder is the default value.

3. **The hierarchy stays invariant.** A roadmap is a cross-milestone grouping artifact, not a container tier — consistent with the work-item hierarchy being methodology-invariant (`work-organization-mapping-framework.md`). This ADR governs *where instances are stored*, not the work hierarchy.

4. **Roadmaps leave the operator-instance path family by design — authored content ships in-repo; runtime state stays operator-local.** The `personal/pmo-instance/` family (ADR-017) holds operator *runtime state* and *append-only audit trails* (`hub-state`, `inbox`, `external-sync`, `releases`/`RELEASE_LOG`/`notes`) — machine-written, never authored-then-referenced. Roadmaps are *authored planning content*, the same nature as the in-repo `analysis/` workspace, so they follow the `analysis/` pattern (in-repo, ships on install, contents git-ignored) rather than the runtime-state family. Roadmaps are the only family member that moves; the rest stay operator-local. The token + `operator.toml` override field are retained, so the family's resolution mechanism is unchanged — only roadmaps' default value moves.

## Migration

Existing roadmap instances at the prior operator-local home (the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` default, or a deployment's override) are **copied** into `/roadmaps/` on adoption; originals are retained until the operator confirms. Instances remain git-ignored throughout, so the migration is an operator-local file move with **no repo-history effect**. A deployment that had *set* an explicit `operator_instance_roadmaps_path` keeps that override — the default change does not disturb a configured value.

## Alternatives Considered

§ Context frames the problem as a shape the platform had already solved once (the read-once analysis workspace, which ships a tracked folder plus README while git-ignoring all content), so the selected design is that precedent applied rather than a new mechanism. The paths not taken are named in § Decision.

- **Eliminate the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token and hardcode the new home** — **not taken.** § Decision item 2 redefines the token as the *override indirection* rather than removing it: its default resolution becomes the shipped folder, existing references continue to resolve, and a deployment may still repoint it. The token is the seam; the folder is the default value.
- **Keep roadmaps in the operator-instance path family** (the status quo the record supersedes in part) — **not taken.** § Decision item 4 gives the criterion: that family holds operator *runtime state* and append-only audit trails, which are machine-written and never authored-then-referenced, whereas roadmaps are *authored planning content*. Roadmaps are the only family member that moves; the rest stay operator-local.
- **Track the instances** — **not taken, and not re-opened.** The superseded record's "instances are not tracked" decision is preserved unchanged; this decision moves the *location* only.

§ Migration records the corresponding operational choice: existing instances are **copied** and the originals retained until the operator confirms, rather than moved destructively.

## Consequences

- **Plug-and-play home ships out of the box.** Agents and operators have a known default location without per-user configuration, while users who need bespoke storage repoint one token. The `analysis/`-pattern precedent means one mechanism governs both operator-working-material folders.
- **ADR-012 is preserved as a historical record** (immutable-ADR posture); it carries a supersession-in-part pointer to this ADR for the location clause only — its de-scope, framework-retention, and enforcement-drop decisions stand.
- **Update-safe by design.** `/roadmaps/` is absent from `update.sh`'s composition-surface regeneration manifest, and its contents are git-ignored — so no update path (managed-section regeneration, `git pull`, or `setup-workspace.sh`) reads, overwrites, or deletes operator roadmap instances. Only the tracked `README` marker is ever touched. This is the same structural guarantee `analysis/` carries: content survival on update is a *consequence of the git-ignored-plus-not-in-manifest design*, not a feature that must be separately protected.

## Reversibility

**MODERATE** — folder + `.gitignore` idiom + token-default redefinition + framework/template reconcile; revertable in days (`git revert` + token-default rollback), no data loss.
