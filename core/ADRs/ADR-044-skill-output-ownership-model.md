<!-- reference-durability: allow-link -->
---
title: ADR-044 — Skill output ownership is entity-keyed in the data architecture; the skill registry stays a skill catalog
status: Accepted
date: 2026-06-26
release: "skill-output-ownership (design; not yet bundled)"
deciders: "operator + Stage 5 Solutioning (pmo-architect)"
tags: [architecture, skills, data-architecture, ownership, entity-model, owning-agent-matrix, registry, separation-of-concerns, compose-not-absorb, reversibility]
source_observations:
  - "Behavior-level review of all 44 skills: the same artifact/decision is produced by many skills — go/no-go re-exposed by 7, RAID originated by 6 (papered over with R-PPM/R-DE/R-PD/R-TA/R-CM ID-namespacing), findings registers by 6, status documents by 3 — surfacing as release rework."
  - "registry.md is keyed on the skill (trigger-surface + modes + dependencies + an upkeep owner); a shared output whose identity spans skills has no single registry row, so the registry structurally cannot host output ownership."
  - "project-entity-model already governs ownership for data-backed entities: the §6 owning-agent matrix names one Creator + one Maintainer per entity; entity-field-lifecycle-matrix.md (CW-BASE) gives the maintainer every write post-create and routes producers. The entity-maintainer ≠ tracker-row-writer split is already in production for RAID Item and Decision."
---

# ADR-044 — Skill output ownership is entity-keyed in the data architecture

## Status

Accepted — operator-ratified by merge of the ADR-044 PR (2026-06-27 UTC). Drafted at Stage 5 Solutioning for the skill-output-ownership design; recorded as Proposed at authoring and flipped to Accepted on the operator's review-and-merge, which served as the ratification gate.

## Context

A behavior-level review of the skill suite found many skills producing the same artifact or decision, deconflicted only by local convention (ID-namespacing, output grain, altitude) that drifts and surfaces as release rework. The intuitive fix — record "who owns producing X" on the skill registry — fails on inspection: the registry is keyed on the *skill*, but a shared output (a go/no-go spanning seven skills, a RAID entry produced by six) has an identity that spans skills. There is no single skill row to host it, and an ownership plane on the registry would duplicate a concern the platform already owns elsewhere.

The data architecture already governs ownership. The project-entity-model's §6 owning-agent matrix names exactly one Creator and one Maintainer per entity; the write-authority rule (CW-BASE) gives the maintainer every write after create-commit and demotes producers to routed recommendations. The "many producers, one maintainer" shape the review flagged as a collision is, for data-backed entities, the *governed* pattern already in production for RAID Item and Decision.

The real gaps are narrower: (1) some produced outputs have no entity, so the §6 matrix cannot cover them; and (2) nothing checks a new skill against the ownership model at authoring time, so a new skill silently becomes the next producer.

## Decision

1. **Ownership of a produced output is a property of the data ENTITY, not of the skill.** The §6 owning-agent matrix (with CW-BASE write-authority) is the single source of truth. The skill registry is NOT extended with ownership; it stays a skill catalog (identity + routing).
2. **Every produced output is classified into one of three architectural classes:**
   - **Data-backed** (RAID Item, Decision, Milestone, Work Item) — already governed by the §6 matrix + write-authority. No change.
   - **Rendering** (status update, executive brief, communications draft) — a read-time projection of owned entities; holds no data of its own and is **ownerless by design**.
   - **Missing-entity** (the findings register) — promoted to a first-class entity so the §6 matrix governs it. The **Finding** entity is the first instance.
3. **Ownership is enforced by four invariants** over the data model: **I1** every entity has exactly one Maintainer; **I2** a non-maintainer writer routes through the maintainer's channel (creator → reader post-create); **I3** any skill declaring maintainer-write to an entity must be that entity's §6 Maintainer; **I4** a rendering declares no ownership and only reads owned entities.
4. **Enforcement is a build-time reconciliation, not a new artifact.** The cross-skill audit reconciles each skill's declared outputs (per-skill-output-contracts) against the §6 owning-agent matrix and escalates a would-be second maintainer (I1 + I3). The ownership model is a discipline plus a check over existing sources of truth — no new ownership store.

## Consequences

- The registry is untouched; its single responsibility (skill identity + routing) and its consumers (the router) are insulated.
- Ownership stays in one home, keyed on the entity — scalable and drift-free.
- One new entity (Finding) and the rendering classification are additive data-model changes; the audit gains an ownership-collision check. Both are downstream implementation, tracked separately.
- ADRs remain platform-governance artifacts outside the project-entity model; their ownership is governed by the ADR convention and the system/solution boundary.
- Design-of-record only; it binds no skill to an ownership document (deferred until the model and its check are proven).

## Reversibility

CHEAP — design-only; no schema or skill binding. The downstream entity addition and audit check are additive and revertible (MODERATE once the audit depends on them). Confidence: HIGH that ownership belongs in the data architecture — the entity is the only key under which a cross-skill output has a single home.

## Related ADRs

- **ADR-038 (registry as CMDB)** — this decision *affirms* ADR-038's scoping of the registry `owner` axis to skill upkeep and *declines* to extend the registry with output ownership. A boundary affirmation, not a schema extension.
- **ADR-018 (work-item type layer) + project-entity-model** — ownership lives in that model's §6 owning-agent matrix; the Finding entity is added under the same data-architecture initiative.
- **ADR-019 (Specialists compose, not absorb)** — the producer→maintainer pattern is the data-side analogue: producers route to the single maintainer rather than re-implementing the write.
