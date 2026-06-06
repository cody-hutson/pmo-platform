---
title: ADR-015 — Centralized-diagram location under the modular-monolith tree
status: Accepted
date: 2026-06-05
deciders: "operator + Stage 5 Solutioning (design-artifact backfill) + Stage 5 Collective Review scope-lock"
tags: [architecture, design-artifact, file-placement, modular-monolith, diagrams, governance]
source_observations:
  - Stage 5 Solutioning (design-artifact Part 2 backfill) — the design-artifact standard directs centralized diagrams to a pre-restructure path that does not exist on disk; producing an artifact at that path would create an orphaned tree outside the module structure
  - Current-state survey at this branch — no diagrams/ directory exists anywhere in the tree; no core/reference/ parent exists; the restructure flattened each pre-restructure reference/<subtype>/ directly to core/<subtype>/ (disciplines, standards, specs, schemas all sit flat under core/)
  - Co-location precedent — skills already co-locate auxiliary content under <module>/skills/<skill>/references/, establishing the skill-owned auxiliary-directory shape
  - Stage 5 Collective Review scope-lock (2026-06-05) — three candidate paths existed (the standard's cited path plus two restructure hypotheses); the location is canonicalized and the standard's in-scope path occurrences corrected in the same change
  - Source finding lineage — the design-artifact pilot (architecture / platform-structure) cannot be produced correctly until the centralized-diagram location is resolved under the restructured tree
---

# ADR-015 — Centralized-diagram location under the modular-monolith tree

## Status

Accepted at the v1.05 Stage 5 Collective Review scope-lock (2026-06-05). This decision clears the location blocker that gated the design-artifact backfill pilot: the pilot artifact and the in-scope path corrections to the design-artifact standard land in the same change that records this ADR. Per the core-ADR convention, this decision is captured as a committed ADR document rather than a GitHub issue.

## Context

The design-artifact standard (`core/standards/design-artifact-standard.md`) defines a hybrid storage model: cross-cutting platform-anchor diagrams (referenced from three or more parent docs) are centralized in a dedicated diagrams directory, and skill-owned flow diagrams are co-located with the skill. The standard names the centralized directory and the skill-owned directory using **pre-restructure paths** (`pmo-platform/reference/diagrams/` for centralized; `pmo-platform/skills/<skill>/diagrams/` for skill-owned).

Those paths are dead. The platform was restructured into a modular monolith — three modules (`core/`, `release/`, `operations/`) — and no `pmo-platform/` tree exists on disk. A current-state survey at this branch establishes three facts that bound the decision:

1. **No `diagrams/` directory exists anywhere** in the tree (`core/`, `release/`, `operations/`, `docs/`). The centralized-diagram location is unmaterialized, not merely renamed.
2. **No `core/reference/` parent exists.** The restructure did not preserve a `reference/` parent. It flattened each pre-restructure `reference/<subtype>/` directly to `core/<subtype>/`: `explanation/ → disciplines/`, `standards/ → standards/`, `specs/ → specs/`, `schemas/ → schemas/`. All of these now sit flat under `core/`.
3. **Skills co-locate auxiliary content** under `<module>/skills/<skill>/references/`, establishing the co-located-auxiliary-directory shape for skill-owned material.

Following the standard literally — creating `pmo-platform/reference/diagrams/` — would build an orphaned tree outside the module structure, which is the precise failure the storage model is meant to prevent (an unmaintained, off-structure artifact location). The location must be canonicalized under the restructured tree before any centralized artifact is produced.

## Decision

**The canonical centralized-diagram location is `core/diagrams/`. The canonical skill-owned-diagram location is `{core,operations,release}/skills/<skill>/diagrams/`** (the diagrams directory follows the skill into whichever module owns it).

Concretely:

1. **Centralized diagrams → `core/diagrams/`.** Cross-cutting platform-anchor diagrams that meet the three-or-more-parent centralization threshold live as dedicated files under `core/diagrams/`, a new peer of `core/standards/`, `core/specs/`, and the other flattened reference-class subtrees.
2. **Skill-owned diagrams → the skill's module.** A skill-specific flow diagram that is owned by the skill's behavior (not a cross-cutting concern) co-locates at `<owning-module>/skills/<skill>/diagrams/`, matching the existing `<module>/skills/<skill>/references/` co-location shape.
3. **The standard's in-scope path occurrences are corrected in the same change.** The centralized-diagram-location path strings in the design-artifact standard are updated from the dead pre-restructure paths to these canonical paths. Non-diagram pre-restructure path drift elsewhere in the standard and the broader corpus is a separate, broader path-drift concern tracked on its own and is not folded into this decision.

## Options considered

| Option | Decision | Rejection rationale |
|---|---|---|
| **`core/diagrams/`** | **Chosen** | Follows the restructure's flattening invariant (a new cross-cutting reference-class directory lands flat under `core/`, peer to `standards/`/`specs/`/`schemas/`); centralized diagrams are platform anchors consumed by skills in both `operations/` and `release/`, and the modular-monolith rule places shared cross-consumer artifacts in the `core/` kernel; the standard that governs them is itself `core/`-owned. |
| `core/reference/diagrams/` | Rejected | No `core/reference/` parent directory exists. The restructure flattened `reference/<subtype>/` to `core/<subtype>/` with no `reference/` parent, so nesting a `reference/` level here would contradict the established invariant and orphan the directory one level too deep. |
| `release/references/diagrams/` | Rejected | Mis-scopes a platform-wide anchor as release-module-private. The centralized artifacts (architecture, concept models, the pipeline flow) are consumed by both consumer modules; placing them under `release/` would violate module-boundary discipline by hiding a cross-consumer artifact inside one consumer. |

## Consequences

### Positive

- **On-structure, not orphaned.** Centralized diagrams land inside the kernel that both consumer modules already read, so the artifact location is maintained by the same conventions as the rest of `core/`.
- **Invariant-consistent.** `core/diagrams/` extends the existing flattened-reference-class pattern rather than introducing a new nesting shape, so a reader who knows `core/standards/` and `core/specs/` already knows where centralized diagrams live.
- **Skill ownership preserved.** Skill-owned diagrams travel with the skill into its module, so a skill's behavioral artifacts stay co-located with its definition.
- **The pilot unblocks.** With the location canonical, the architecture pilot (`core/diagrams/architecture-platform-structure.md`) is produced correctly, and the standard's path strings stop pointing at a dead tree.

### Negative

- **The standard carried a dead path until now.** Any reader who followed the pre-restructure path before this correction would have found nothing; the corrected paths resolve the latent trap going forward.
- **Two diagram homes to remember.** Centralized-versus-co-located remains a judgment call (the three-or-more-parent centralization test), now resolving to two concrete locations rather than one — but that duality is inherent to the hybrid storage model the standard already chose, not new here.

## Reversibility

**CHEAP.** The decision materializes as a new directory plus path-string edits in one standard. Reverting is a clean `git revert` of the change — no data migration, no consumer-contract break, no stakeholder-facing surface. Confidence: HIGH.

## Related ADRs

- **ADR-007** (core module boundary lock-in) — composes with this decision: ADR-007 locked the file-placement boundary for the kernel's reference-class subtrees; `core/diagrams/` is a new peer in that same kernel boundary, governed by the same shared-cross-consumer-artifact rationale.
- **ADR-006** (skill-to-module map) — composes: the skill-owned-diagram location (`<module>/skills/<skill>/diagrams/`) follows the ADR-006 partition that places each skill in its owning module.
- **Composes with** the design-artifact standard (the storage-model owner whose centralized-and-skill-owned path strings this decision canonicalizes) and the architecture-overview / operating-model disciplines (the parent docs the first centralized artifact depicts).
