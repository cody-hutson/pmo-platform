<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: The _pmo/ entity page is the SSOT on person_id; the roster and leadership-owner refs are consumers
status: Accepted
date: 2026-06-30
release: 21-shared-entity-storage-layout
deciders: "[operator]"
tags: [pmo-entity-store, person-id-ssot, compose-not-fork, shared-entity-layout, alias-convention, reversibility-moderate]
---

# ADR-058 — The `_pmo/` entity page is the SSOT on `person_id`

## Status

**Proposed** — flips to Accepted at the Stage 9 review.

Number **058** — the Stage-5 decision record (#2631) named **054** (the spoke first proposed 041, taken, reassigned to 054), but the global ADR sequence spans both `core/ADRs/` and `release/ADRs/` (one sequence; `check-adr-numbers.py` enforces it) and 054 was already claimed in `release/ADRs/`. Reassigned to the next gap-free slot **058** at Engineering time. Binds atomically at Stage 12.

## Context

Shared entities — a Person, a System, a Vendor — are referenced by many projects, but the platform had **no single home** for them: a Person appeared inline in each PROJECT.md table, re-typed and re-spelled per project, with no dedup anchor. The cross-entity model already names `person_id` as the global deduplication anchor (`entity-field-schemas.md` §3.10, V-PER-02: globally unique within the cross-project-shared tier) and the most-resolved-against FK target across the graph (X-01/X-04/X-12/X-15/X-18/X-20/X-21/X-23/X-27/X-30..X-33).

After this card was authored, two adjacent surfaces shipped that also touch Person identity: the **people-roster** (`people-roster-template.yaml`, the functional coverage view) and the **ADR-040 leadership-owner refs** (`project_owner` / `portfolio_owner` / `program_owner` / `sponsor` lifted to `Person.person_id`). The risk: three Person homes, no SSOT.

The forks: **(1)** does the `_pmo/` page become the SSOT, or is the roster the record? **(2)** is rename-safety (`aliases:`) a frozen Person *field*, or a convention?

## Decision

**The `projects/_pmo/{people,systems,vendors,workstreams,decisions,dependencies}/` entity page is the canonical SSOT, keyed on the entity's id (`person_id` for Person); the people-roster and the ADR-040 leadership-owner refs are read-time *consumers* that resolve against it — compose, not fork. There is no second Person home.**

1. **The `_pmo/` page is the record; the roster is a view — composition, not duplication.** The Person entity page (`entity-field-schemas.md` §3.10, conforming to the §6.2 worked example) carries the identity anchor `person_id`. The people-roster supplies *functional* attributes (capability tags, coverage edges, escalation) and joins the page on `person_id` (`people-coverage-graph.md` §2); the ADR-040 leadership-owner refs resolve *against* `person_id`. No surface re-stores identity — the page is the single record, mirroring the no-parallel-store rule the coverage graph already enforces.

2. **`person_id` is the immutable dedup spine.** Every cross-entity FK targets `person_id`, so one person is never represented twice and a rename never breaks a link. The id is globally unique (V-PER-02) — the invariant the whole graph leans on.

3. **`aliases:` is a template convention, not a frozen-schema field (Q2).** Rename-safety is an optional `aliases:` list authored by the entity-page template and homed in `people-coverage-graph.md §2.3` — it adds **no field** to the frozen Person entity (§3.10) and no field to the roster, preserving the frozen-schema boundary. On rename: append the prior name to `aliases[]`, update `full_name`, **never** edit `person_id`, **never** delete an alias.

4. **The dependency view carries `storage_tier: portfolio-level` (Q1).** `_pmo/dependencies/` is a portfolio-level **view** over the Cross-Project Dependency entity whose authoritative home stays `projects/_config/` (§3.15) — composed, not relocated. The `storage_tier` frontmatter tags it as the view.

5. **Never auto-create a Person.** Project initiation (project-initiator Mode A Step 2b) bootstraps `_pmo/` and links existing entities by id, but an unresolved person name routes to the operator clarification queue (Tier-1) — never a scaffold-time auto-create (mirrors the ADR-040 resolve-by-name migration: zero-match → queue; never first-match auto-pick; never silently dropped).

## Alternatives considered

- **Make the people-roster the Person record** — rejected: the roster is operator-instance functional config (capability/coverage), not the identity SSOT; promoting it would fork identity away from the entity model's `person_id` anchor and re-introduce the per-instance-store problem.
- **Add `aliases` as a frozen §3.10 Person field** — rejected: it would be a Tier-2 SCOPE CHANGE to the frozen entity surface for a rename-safety affordance that lives correctly in the view/convention layer; the convention home (people-coverage-graph §2.3) preserves the frozen boundary (Q2).
- **Relocate Cross-Project Dependency from `_config/` into `_pmo/`** — rejected: §3.15 already homes it at the portfolio tier; a `storage_tier`-tagged view composes the two without a relocation that would break the §3.15 contract (Q1).

## Consequences

- Shared entities have a single home; a Person edited once on the `_pmo/` page is correct everywhere (the roster and the ADR-040 refs resolve to it). Per-project Person duplication ends.
- Six entity-page templates land under `operations/templates/`; the `_pmo/` six-subfolder tree is bootstrapped by project-initiator Mode A Step 2b (git-ignored Layer-2 ops tree).
- `aliases:` rename-safety is a documented convention (people-coverage-graph §2.3) — no frozen-schema change.
- The `_pmo/` tree is git-ignored (Layer 2), so its pages are operator-managed and out of the platform's tracked diff; the templates that author them are tracked (Layer 1).

## Reversibility

**MODERATE / Confidence HIGH.** The tracked deliverables (templates, the project-initiator Step 2b edit, the §2.3 convention, this ADR) are git-revertible by the single release PR. The `_pmo/` pages themselves are git-ignored Layer-2 data with no git safety net — but no *live* project data is migrated under this ADR (that is #363's gated Stage-12 step); the POC pages are seed data. Once consumers hard-bind to `_pmo/` page identity at scale, the SSOT becomes load-bearing (days-scale unwind), hence MODERATE. Confidence HIGH that `_pmo/`-as-SSOT and compose-not-fork are correct — both were forced by the `person_id` dedup anchor and the existing no-parallel-store rule, not by preference.

## Related ADRs

- **ADR-040** (leadership-owner Person ref) — supplies the leadership-owner refs that resolve against this SSOT; the resolve-by-name + clarification-queue migration pattern Step 2b mirrors.
- **ADR-060** (PROJECT.md composed index) — same milestone; the composed index wiki-links INTO these entity pages.
- **ADR-059** (`plan_type` open discriminator) — same milestone; a typed Plan's relationships resolve against these pages.
