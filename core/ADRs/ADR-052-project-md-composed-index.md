<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: PROJECT.md is a composed wiki-link index, not the entity container
status: Proposed (flips to Accepted at the Stage 9 review)
date: 2026-06-30
release: 21-shared-entity-storage-layout
deciders: "[operator]"
tags: [project-schema, composed-index, wiki-link, shared-entity-layout, gated-migration, reversibility-expensive]
---

# ADR-052 — PROJECT.md is a composed wiki-link index, not the entity container

## Status

**Proposed** — flips to Accepted at the Stage 9 review.

Number **052** — next gap-free after 051; binds atomically at Stage 12.

## Context

PROJECT.md is the project's context file, but it had grown into the project's **container**: People, Systems, Milestones, Plans, and Workstreams lived as inline markdown tables, re-typed per project. The same shared entity (a Person, a System) appeared duplicated across every project that touched it, and an edit meant hunting the right table cell in the right file. Two adjacent capabilities now make a better shape possible: the `_pmo/` shared-entity SSOT (#362 / ADR-054) gives those entities a single home, and the typed-plan discriminator (#159 / ADR-055) gives plans stable ids. With both, PROJECT.md can become a thin **index** rather than the container.

The constraint: `project-schema.md` §8 enumerates the PROJECT.md-reading consumers (delivery-engine, ppm-agent, daily-status, …) that parse `delivery_approach` and `status` in place. Any redesign must not break them. And the live PROJECT.md files sit in the git-ignored `projects/` ops tree — migrating them has no git rollback.

The forks: **(1)** what stays inline vs. becomes a link? **(2)** how does migration of live files happen safely?

## Decision

**PROJECT.md is redesigned as a thin composed wiki-link index (≤50 lines): Methodology + Status stay inline; People / Systems / Milestones / Plans / Workstreams become `[[wiki-link]]` lists into the `_pmo/` entity pages (#362) and the #159 typed plans. New projects scaffold in this shape; live-project migration is a gated, per-project, snapshot-before / verify-after step.**

1. **Container → index.** PROJECT.md stops *holding* shared entities and starts *pointing at* them. The inline tables become `[[wiki-link]]` lists into the `_pmo/` SSOT pages (people/systems/workstreams/decisions/dependencies) and the typed plans. An entity is edited once on its page; PROJECT.md is the dashboard, not the store. Obsidian's graph view renders the project↔entity edges the wiki-links create.

2. **Methodology + Status stay inline — forced by consumer back-compat.** The §8 consumers read `delivery_approach`, `dual_framing_enabled`, and `status` directly from PROJECT.md. Those fields stay **inline** in the composed index (the Methodology block + the Status line), so every consumer parses the migrated file unchanged. The Agile / Waterfall / Hybrid / Dual-Framing conditional toggles are preserved in the inline Methodology block (sprint-cadence vs. phase-gate vs. both; the Dual-Framing Bridge link).

3. **New projects scaffold composed; migration is gated.** `project-initiator` Mode A Step 3 scaffolds the composed-index template (`references/project-md-composed-index-template.md`) for **new** projects (CHEAP, no live data). Migrating **existing** live PROJECT.md files is the EXPENSIVE step, gated per project by the 4-step Migration Protocol (M1 extract + snapshot → M2 author/link `_pmo/` pages with alias tracking → M3 replace tables with wiki-link lists → M4 verify links), homed in `project-schema.md §7`. The POC project is decided at the Stage-12 gate; Engineering delivers the template + skill + protocol + ADR only — it migrates no live PROJECT.md.

4. **The consumer count is parameterized, not hardcoded.** `project-schema.md`'s "13 PROJECT.md-reading skills" hardcode is re-grounded to "the §8 consumer table" so the count stays accurate as consumers are added/removed (parameterize-over-hardcode); AC-4 back-compat reads the count from the live table, not the card's frozen "13".

## Alternatives considered

- **Keep the inline-table monolith** — rejected: it is the per-project duplication and edit-hunt problem #362/#363 exist to eliminate; with the `_pmo/` SSOT now available, the tables are redundant copies.
- **Move Methodology / Status to links too** — rejected: the §8 consumers parse them in place; linking them out would break every consumer's read path (a hard back-compat regression) for no dedup benefit (Methodology/Status are project-scoped, not shared entities).
- **Migrate all live PROJECT.md files in this release** — rejected: the live ops tree is git-ignored (no rollback); a bulk live-data migration is EXPENSIVE and gated. The POC-then-bulk sequence (one project at the Stage-12 gate, bulk as a follow-up) is the lower-regret path.

## Consequences

- PROJECT.md becomes a ≤50-line dashboard; shared entities are edited once on their `_pmo/` page and stop being duplicated per project; the Obsidian graph shows project↔entity relationships.
- New projects scaffold in the composed-index shape immediately (project-initiator Step 3); existing projects migrate on a gated, per-project schedule.
- The §7 Migration Protocol + the parameterized §8 consumer-count land in `project-schema.md`; the composed-index template lands under `operations/templates/`.
- Live-project migration is deferred to Stage 12 (gated) — no live PROJECT.md is touched by Engineering. The git-ignored ops tree means the snapshot (`08-Generated/_migration-snapshot/`) is the only rollback path; this is a documented, accepted residual on the EXPENSIVE step.

## Reversibility

**EXPENSIVE / Confidence MEDIUM.** The tracked deliverables (template, the project-initiator Step 3 swap, the §7 protocol + §8 parameterization, this ADR) are git-revertible by the single release PR (CHEAP). The **live-project migration** is the EXPENSIVE surface: it rewrites git-ignored ops-tree files with no git history, so rollback is re-inlining table data from the entity pages via the `08-Generated/_migration-snapshot/` copy. That is why migration is gated per project, CHEAP-changes-first, POC-before-bulk. Confidence MEDIUM on the migration step (live-file risk); HIGH that the composed-index shape + inline-Methodology/Status back-compat are correct (forced by the §8 consumer read paths, not preference).

## Related ADRs

- **ADR-054** (`_pmo/` entity-page SSOT) — supplies the entity pages the composed index wiki-links INTO; hard prerequisite (#362 → #363).
- **ADR-055** (`plan_type` open discriminator) — supplies the typed plans the `## Plans` wiki-link section points at (#159 pairs-with #363).
- **ADR-040** (leadership-owner Person ref) — the resolve-by-name + clarification-queue pattern the migration's M2 alias-tracking step mirrors.
