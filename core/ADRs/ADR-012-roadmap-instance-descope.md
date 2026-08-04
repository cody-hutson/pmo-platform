---
title: ADR-012 — Initiative-roadmap instances de-scoped from the tracked tree (operator-local authoring)
status: Accepted
date: 2026-06-02
deciders: "operator (directive) + roadmap-instance-descope enhancement intake"
tags: [architecture, governance, artifact-class, file-placement, public-repo-boundary]
source_observations:
  - Operator directive — initiative-roadmap *instances* are operator-instance planning content that should not be tracked in the public-template repo; untrack-in-place, keep operator-local copies
  - Reference-map survey at this branch — the 6 instances under core/governance/roadmaps/ are load-bearing for 1 framework standard, 4 enforcement surfaces (deploy.sh Check 24, gate-criteria-spec G3-13, Stage 13 Close forcing-function, Stage 5 Collective Review cohesion-check), and ~12 reference/registry files
  - core/specs/label-taxonomy.md — <OPERATOR_INSTANCE_ROADMAPS_PATH> token already in use, establishing the operator-local reference pattern
  - ADR-006 + ADR-007 — placed the roadmap instances in-repo (core held 6 of 8 roadmaps; roadmaps split 6/1/1); both immutable, amended-in-part here
---

# ADR-012 — Initiative-roadmap instances de-scoped from the tracked tree

## Status

Accepted per operator directive (roadmap-instance-descope enhancement). **Amends in part** ADR-006 and ADR-007 — specifically their roadmap-placement clauses (ADR-006's core-module roadmap count; ADR-007's "Roadmaps split" decision and the "roadmaps (6/1/1)" boundary lock). All other ADR-006/007 decisions (the skill-to-module map; every non-roadmap file-placement lock) stand unchanged.

## Context

The platform repo is a reusable, publicly-shareable PMO template. Initiative-roadmap *instances* (`core/governance/roadmaps/*.md`) are operator-instance planning artifacts: specific Now / Next / Later content, internal milestone and issue numbering, capacity-audit dates, open-vs-shipped status. They describe one operator's program, not reusable platform structure.

ADR-006 / ADR-007 (module-restructure, 2026-05-27) placed the roadmap instances in `core/governance/roadmaps/` as part of the core kernel. Since then the instances became load-bearing for:

- **1 framework standard** — `initiative-roadmap-framework.md`, the reusable convention defining when and how a roadmap is authored.
- **4 enforcement surfaces** — `deploy.sh` Check 24 (frontmatter lint + 90-day staleness), `gate-criteria-spec.md` G3-13 Roadmap-Cascade Validation, the Stage 13 Close forcing-function checklist, and the Stage 5 Collective Review cohesion-check.
- **~12 reference / registry files** — operating-model, module-apis, framework-catalog, architecture-overview, label-taxonomy, the two OPERATIONS files, discovery-discipline, hub-spoke-bridge, pipeline-event-log-schema, and others.

The instances cannot simply be deleted: doing so orphans immutable ADRs, dangles the ~12 references counted at the time, and silently no-ops the 4 enforcement surfaces (each SKIPs cleanly on absent dirs, which reads as "passing" when it is in fact unenforced).

## Decision

**Initiative-roadmap instances are de-scoped from the tracked tree and authored operator-local at `<OPERATOR_INSTANCE_ROADMAPS_PATH>`.** Concretely:

1. **Untrack in place (forward-only).** The then-current 6 instances are removed from the index (`git rm --cached`) and ignored via `.gitignore`; operator-local copies persist on disk. History retains prior commits — this decision does not rewrite history.
2. **Framework retained, re-scoped.** `initiative-roadmap-framework.md` stays as the reusable convention; its §2.1 location, `consumers:` frontmatter, and enforcement sections are amended to reflect operator-local instances.
3. **Enforcement dropped, not dormant.** The 4 enforcement surfaces are removed. None can run without tracked instances, and a permanently-skipping check is dead code that misreports as a pass.
4. **References re-pointed, not deleted.** Every live reference resolves to the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token, or to `initiative-roadmap-framework.md` where the content is codified in-repo (e.g. the F9 4-case diagnostic at framework §7.4) — preserving fidelity to the source without requiring the instance in-repo.
5. **Historical artifacts untouched.** Baselined release plans and `release/ADRs/ADR-005` reference roadmaps as point-in-time audit evidence; they are left unedited (editing a baselined record would falsify the audit trail).

**Removal depth:** "keep framework, drop enforcement" — operator-selected over "remove the whole apparatus" and "keep checks dormant."

## Consequences

### Positive

- **Template purity** — a downloader receives the roadmap *convention*, not one operator's planning data.
- **No planning-metadata leak** — internal milestone/issue numbering and capacity dates leave the published content surface.
- **Durable, scalable references** — the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token is path-stable and applies uniformly across the three module roadmap dirs (core / release / operations).
- **No dead machinery** — dropping (rather than dormant-skipping) the 4 enforcement surfaces removes silently-passing checks.

### Negative

- **No in-repo freshness enforcement** — roadmap staleness and cohesion become an operator-local discipline; the platform no longer mechanically surfaces a 90-day-stale roadmap.
- **Convention without enforcement** — the framework documents the convention, but the repo cannot verify conformance of out-of-repo instances.
- **History retention** — forward-only untrack means the instances remain reachable in prior commits; a separate history-rewrite is required if true removal is later needed (e.g. post public-flip).

## Reversibility

**MODERATE.** Re-tracking is mechanically cheap (`git add` the instances, revert the `.gitignore` rule), but the reference re-points and the framework re-scope span the ~15 files counted at the time; reverting all of them is days-not-hours. The untrack itself is CHEAP; the corpus reconciliation is what raises the tier. No data loss — instances persist on disk and in history.

## Related ADRs

- **ADR-006** (skill-to-module map) — amended in part: the core-module roadmap count no longer includes tracked instances. The skill-to-module map is unchanged.
- **ADR-007** (core module boundary) — amended in part: the "Roadmaps split" decision and the "roadmaps (6/1/1)" boundary lock are superseded; instances are operator-local, not module-placed. All non-roadmap boundary locks stand.
- **Composes with** `initiative-roadmap-framework.md` (the retained convention) and `public-repo-gitignore-template.md` (published-content boundary discipline — the same template-purity principle applied at the extracted-repo surface).
