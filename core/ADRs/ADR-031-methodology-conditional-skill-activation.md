<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-031 — Methodology-conditional skill activation — dormant-under-non-matching-delivery-approach + release-side methodology-row sourcing
status: Accepted
date: 2026-06-20
release: 04-ROLE-delivery-coverage (v2.09)
deciders: "Workspace owner (operator-adopted at the 04-ROLE-delivery-coverage Collective Review scope-lock); design authored at Stage 5 Solutioning (the pmo-release-train-engineer spoke); ADR materialized at Stage 6 per the ADR-007 / ADR-028 / ADR-029 Stage-6 ADR-authoring precedent"
tags: [architecture, skills, methodology, delivery-approach, conditional-activation, dormant-gating, role-specialist, safe, parameterization, blast-radius, reversibility]
source_observations:
  - "pmo-release-train-engineer (#1111) Stage-5 finding D2: NO existing PMO skill gates on `delivery_approach`. The RTE is a SAFe-specific role; the platform default is Scrum. A SAFe role that fires under a non-SAFe config would cross-fire with pmo-scrum-master / pmo-program-manager and emit a methodology view the operator's config does not run — the role needs a defined off-state, and the platform had no convention for one."
  - "pmo-release-train-engineer (#1111) Stage-5 finding D1: the shared `operations/skills/_shared/five-model-variations.md` carries 5 model variations and has a blast radius of ~5 first-order / ~265 second-order consumers; it has NO SAFe column. Forcing a 6th column to carry the RTE's SAFe parameterization would ripple across every consumer for one role's benefit."
---

# ADR-031 — Methodology-conditional skill activation: dormant-under-non-matching-delivery-approach + release-side methodology-row sourcing

## Status

**Accepted.** Operator-adopted at the Collective Review scope-lock for `04-ROLE-delivery-coverage` (v2.09), where CR-3 (parameterization sourcing) and CR-4 (the activation convention) were ratified as the two facets of one decision and consolidated into this single ADR per the decision-discipline ceremony guard. Design authored at Stage 5 Solutioning (the `pmo-release-train-engineer` spoke, #1111); ADR materialized at Stage 6 post-build per the ADR-007 / ADR-028 / ADR-029 Stage-6 ADR-authoring precedent. Ships in the v2.09 release PR (reviewed at Stage 9).

## Context

The role-Specialist suite delivered by `04-ROLE-delivery-coverage` includes `pmo-release-train-engineer` (RTE) — a **SAFe-specific** role (Agile Release Train facilitation, Program-Increment planning). The platform's default `delivery_approach` is **Scrum** (`operator.toml`), and SAFe is one archetype among several defined in `release/references/specs/methodology-archetype-matrix.md`. Building a methodology-specific role surfaced two coupled questions the platform had no precedent for:

1. **Activation:** How does a role that is only meaningful under a specific `delivery_approach` behave when that approach is **not** active? No existing PMO skill gates on `delivery_approach` (#1111 finding D2). An always-active RTE would cross-fire with `pmo-scrum-master` and `pmo-program-manager` under the default Scrum config and emit a SAFe view the operator does not run.
2. **Parameterization placement:** Where does the SAFe parameterization the active RTE consumes live? The shared `operations/skills/_shared/five-model-variations.md` has no SAFe column and a high blast radius (~5 first-order / ~265 second-order consumers, #1111 finding D1) — adding a 6th column there ripples across every consumer for one role.

These are facets of one decision: **how a methodology-conditional role activates, and where its active-state config comes from.**

## Decision

Adopt a **methodology-conditional skill-activation convention** with two coupled parts:

1. **Dormant-under-non-matching-config activation.** A methodology-conditional skill **gates on `delivery_approach` at invocation**:
   - the configured approach **matches** the skill's methodology (e.g., SAFe for the RTE) → **ACTIVE**;
   - the configured approach does **not** match (e.g., the default Scrum) → **DORMANT**, emitting a non-fire notice rather than producing output;
   - the field is **absent** → DORMANT with an `[ASSUMPTION – CONFIRM]` surfacing the missing config — **never a silent default-fire**.

   Dormant-under-non-matching-config is **correct behavior, not a defect** (a DT/QA acceptance criterion, not a bug). The convention is reusable: future methodology-specific roles (other SAFe roles, Kanban-specific roles, etc.) gate the same way. It composes with role-boundary deconfliction — the RTE's dormancy under Scrum *plus* its primary-role/trigger boundary against `pmo-scrum-master` (team-process, Scrum-default) and `pmo-program-manager` (delivery-accountability, methodology-general) together prevent cross-fire.

   **Conditional is the exception; adaptive is the rule.** This ADR governs only the *conditional* mode — a methodology-**exclusive** role (one with no meaning outside its methodology, like the SAFe RTE) going dormant. It does NOT govern the common case. The **default is adaptive**: a skill stays always-active and *renders the selected methodology's view by nature* (Scrum sprint framing vs SAFe PI framing vs Kanban flow) through the **work-organization-mapping framework** ([`core/disciplines/work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md)) — the Layer-3 consumer of `delivery_approach`. Use conditional activation (this ADR) ONLY when the role itself is methodology-exclusive; use adaptive rendering (the framework) for every skill that merely varies its output by methodology. Mis-applying the gate to an adaptive skill would wrongly *silence* a skill that should simply adapt — the failure mode this distinction exists to prevent.

2. **Release-side methodology-row sourcing.** The active RTE consumes its SAFe parameterization from the **SAFe row of `release/references/specs/methodology-archetype-matrix.md`** (the per-archetype matrix that already carries per-archetype rows) — it does **NOT** add a column to the high-blast-radius shared `_shared/five-model-variations.md`. The skill "renders the SAFe view by nature" from the canonical archetype row; it does not fork or restate the parameterization. This is the same one-owner-of-truth posture as ADR-028 (consume by reference from the canonical owner, do not fork).

## Consequences

- **A reusable platform convention** for methodology-conditional roles exists, anchored by the RTE as first consumer — future archetype-specific roles inherit the dormant-gating + canonical-row-sourcing shape rather than re-deciding it.
- **The RTE ships config-gated** — dormant under the default Scrum config (no cross-fire), active only under a SAFe `delivery_approach`. Its behavioral validation (firing under SAFe; not firing under non-SAFe) is conditional on a SAFe instance and is a DT/QA acceptance criterion.
- **No high-blast-radius edit** to the shared five-model file; the archetype matrix is the single home for archetype-specific parameterization.
- **Methodology stays config, not skill-fork** — consistent with the platform's methodology-as-config posture (the work-org-mapping framework renders the chosen view); the suite's public corpus stays methodology-neutral and the RTE projects the SAFe view from config.

## Alternatives rejected

- **Add a 6th (SAFe) column to `_shared/five-model-variations.md`.** Rejected: ~5/265 blast radius for one role's benefit; the archetype matrix already carries per-archetype rows and is the correct home.
- **Always-active RTE (no gate).** Rejected: cross-fires with `pmo-scrum-master` / `pmo-program-manager` under the default Scrum config and emits a methodology view the operator's config does not run.
- **Silent default to Scrum-equivalent behavior when not SAFe.** Rejected: masks the methodology mismatch; a SAFe role silently behaving as something else is a correctness hazard, not graceful degradation. Dormant-with-notice is honest.
- **Two separate ADRs (one per CR).** Rejected per the ceremony guard: the sourcing decision is the active-state of the activation decision; one coherent record reads better and avoids parallel-ADR drift.

## Reversibility

**CHEAP** at ship — additive (a new convention doc-pattern + the RTE's invocation gate + a canonical-row reference); revert the v2.09 release PR and nothing else depends on it yet. Trends **MODERATE** as future methodology-conditional skills adopt the convention and cite this ADR. **Confidence: HIGH** on the diagnosis (both findings are directly grounded in the RTE Stage-5 survey) / **HIGH** on the recommendation (the canonical-row sourcing mirrors the established ADR-028 posture; the dormant-gating is the minimal correct off-state).

## Related ADRs

- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — Specialists compose, not absorb; the RTE composes `delivery-engine` + `ppm-agent` and adds only the ART/PI-tier synthesis, so the methodology gate lives in the thin Specialist, not in the composed function-skills.
- [ADR-004](ADR-004-five-function-spine.md) — the archetype × stage matrix that defines the methodology archetypes (SAFe among them) the gate keys on.
- [ADR-022](ADR-022-platform-config-vs-operator-toml-split.md) — `operator.toml` is the environment/identity surface that carries the `delivery_approach` selector this convention reads.
- [ADR-028](ADR-028-operations-consume-core-safety-controls-via-public-api.md) — consume-by-reference-from-the-canonical-owner posture; the release-side-row sourcing is the same one-owner-of-truth principle applied to methodology parameterization.
- [`work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md) — the **adaptive** complement to this ADR's **conditional** mode: the Layer-3 framework by which always-active skills render the selected methodology's view. This ADR is the exception; that framework is the rule.

## Architecture context

This activation pattern is one node in a **toolkit × methodology × adapter** architecture that is currently logged across several artifacts but not yet unified under one trunk (see the `architecture-overview` linkage gap noted at the 04-ROLE-delivery-coverage Collective Review). The four participating layers and their canonical homes:

| Layer | Canonical home | This ADR's relation |
|---|---|---|
| **Methodology selection** | `operator.toml` `delivery_approach` ([ADR-022](ADR-022-platform-config-vs-operator-toml-split.md)) | the config value this ADR's gate reads |
| **Methodology definitions** | [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md) + `methodology-parameterization-v1.md` ([ADR-004](ADR-004-five-function-spine.md)) | the SAFe row the active skill sources from |
| **Skills follow methodology** | adaptive → `work-organization-mapping-framework.md`; conditional → **this ADR** | this ADR is the conditional half |
| **Plug-and-play host adapters** | `operator.toml` `[adapters]` (selectors; implementations roadmapped under the PORT-Adapters epic) | orthogonal — *which* host tools a skill leverages, independent of *which* methodology it renders |
| **Domain best-practice toolkit** | `core/standards/domain-best-practices/` | orthogonal quality axis — *what good looks like* in a domain, independent of methodology |
