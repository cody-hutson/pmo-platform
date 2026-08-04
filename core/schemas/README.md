---
title: core/schemas/
purpose: Index of the structured contract schemas — the typed-format definitions agents and gates validate documents and handoffs against.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: readers navigating the core/schemas corpus; agents and gates locating the typed-format definition they validate against; the governance file map
---
<!-- reference-durability: allow-link -->
# core/schemas/

**Purpose:** Structured contract schemas — the typed-format definitions that agents and gates validate documents and handoffs against.
**Organization:** One `.md` per schema; flat. This index enumerates the current set by directory listing — it does **not** hardcode a count; regenerate from `ls core/schemas/*.md` on change.
**Governance:** [../governance/OPERATIONS.md](../governance/OPERATIONS.md) § README-Per-Folder Convention.
**Layer:** 1 (Engineering, git-tracked)

## Index

| Schema | Coverage area |
|---|---|
| [../schemas/adr-schema.md](../schemas/adr-schema.md) | ADR frontmatter (7 fields) + body-section (7) contract |
| [../schemas/agent-processing-contracts.md](../schemas/agent-processing-contracts.md) | Agent ↔ document-ecosystem integration contracts |
| [../schemas/field-lifecycle-matrix.md](../schemas/field-lifecycle-matrix.md) | Field create / update / retire lifecycle across the ecosystem |
| [../schemas/frontmatter-schema.md](../schemas/frontmatter-schema.md) | Document-ecosystem metadata frontmatter schema |
| [../schemas/gate-criteria-spec.md](../schemas/gate-criteria-spec.md) | Stage-gate pass/fail criteria (G1..GN) specification |
| [../schemas/gate-evaluation-spec.md](../schemas/gate-evaluation-spec.md) | Three-layer gate evaluation (metrics / judgment / calibration) |
| [../schemas/handoff-coordinator-spec.md](../schemas/handoff-coordinator-spec.md) | Five-phase inter-stage handoff coordination contract |
| [../schemas/navigation-layer-schema.md](../schemas/navigation-layer-schema.md) | View-generation / navigation layer specification |
| [../schemas/per-skill-output-contracts.md](../schemas/per-skill-output-contracts.md) | Per-skill output-contract schemas |
| [../schemas/project-schema.md](../schemas/project-schema.md) | PROJECT.md schema (delivery_approach, fields, lifecycle) |
| [../schemas/routing-rules.md](../schemas/routing-rules.md) | File classification + routing rules |
| [../schemas/sqlite-index-schema.md](../schemas/sqlite-index-schema.md) | Document-ecosystem SQLite cache schema |
| [../schemas/stage-io-contracts.md](../schemas/stage-io-contracts.md) | Per-stage required input/output artifact contracts |
| [../schemas/touchpoint-phaseout-schema.md](../schemas/touchpoint-phaseout-schema.md) | Operator-touchpoint inventory + phase-out-plan schema (autonomy phase-out grammar) |
| [../schemas/tracker-schemas.md](../schemas/tracker-schemas.md) | PMO operational tracker schemas (RAID, comms, meetings, …) |
| [../schemas/work-item-type-schema.md](../schemas/work-item-type-schema.md) | Declarative work-item type-pack meta-schema (the grammar for declaring kinds) |
