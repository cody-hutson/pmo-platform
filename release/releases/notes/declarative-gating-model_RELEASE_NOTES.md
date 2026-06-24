---
version: declarative-gating-model (version-less)
date: 2026-06-24
type: note
issues: ["#1870", "#1875", "#1876"]
pr: "#1890"
links:
  plan: release/releases/plans/declarative-gating-model_RELEASE_PLAN.md
  log_anchor: "#declarative-gating-model-version-less"
reversibility-tier: MODERATE
themes: ["cluster:templates-schemas", "project:project-data-architecture"]
summary: "The work-item type-pack meta-schema can now declare a gate whose condition is a related item's workflow status (e.g. a child can't start until its parent Epic is design-approved) or a set-aggregate over related items (e.g. a Kanban WIP limit) — not just the item's own fields."
requires_action: false
breaking: false
components: ["work-item-type-schema.md", "ADR-039"]
followups: ["control-field axis sibling (#1803) — same construct slot reserved, not built here"]
---

# Gates can now depend on a related item's status — or a limit across a set of items

## What changed for everyone

The platform's methodology configuration (the work-item type-pack) lets you declare *gates* — conditions that must hold before a work item can move to its next status. Until now, a gate could only check the item's **own** fields. This release adds two new kinds of gate condition:

- **Related-item-status gates.** A gate can now depend on the workflow status of a *related* work item. For example: a child Story can't be groomed to `ready` until its parent Epic is design-approved; a Story can't leave `ready` while a blocking Spike isn't `done` yet. The condition is resolved across the relationship you declare (parent/child, depends-on, blocks). *Why it matters:* the lean reality that upstream design and discovery gate downstream build is now expressible as configuration — at whatever point in the cycle the dependency actually sits, not only at a release boundary.
- **Set-aggregate gates.** A gate can now depend on an *aggregate over a set* of related items — most importantly a **Kanban WIP limit** ("no more than N items in-progress at once"). *Why it matters:* WIP/pull limits are the defining gate of flow-based methods, and they're now first-class instead of inexpressible.

These compose with the methodology you've configured: a kind declares that a gate *exists*; your project's lifecycle decides whether it *fires* — so the same pack behaves correctly whether you run Scrum, Kanban, or a hybrid. Mutually-gating loops (A waits on B while B waits on A) are detected and refused rather than deadlocking.

This release was **research-led**: two timeboxed spikes first established that a *single* extensible model could cover the cross-methodology gate landscape (rather than needing several distinct ones), and the build then implemented exactly that model — so the design rests on evidence, not assumption.

## For operators / builders

- The construct lives in `core/schemas/work-item-type-schema.md` **only**: an optional `condition` object on a `criteria.checks[]` entry, with a required `condition.kind` discriminator over three kinds — `related-item-status` and `set-aggregate` (built) and `control-field` (reserved for the field-axis sibling). Absent a `condition`, a check behaves exactly as before — fully backward-compatible, so the meta-schema stays v1 (no version bump).
- EAD materialization gains an `x-pmo-aggregate` annotation class (modeled on the existing `x-pmo-referential` plus the chain-17 `BELONGS_TO` rollup traversal in `core/disciplines/project-entity-model.md`). Cycle-safety is detect-and-refuse — a static gating-graph check at pack-validation, a runtime block, and a cardinality bound — enforced in `tracker-manager` (no new enforcer).
- The GitHub use case is specified as the first plug-and-play adapter; per-tracker adapter config is operator-local (K4).
- Rationale is recorded in the founding `core/ADRs/ADR-039-declarative-gate-conditions.md` (subordinate to ADR-018).

Version-less (theme-named) per the operator's Stage-4 D-Version decision — a research-led milestone shipped without a tag. No action required; nothing breaks. Reversibility: MODERATE (whole-release `git revert` of the squash commit from PR #1890).
