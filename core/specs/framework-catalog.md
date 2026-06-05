---
title: Framework Catalog
purpose: Authoritative registry of every named framework/methodology/standard the platform references — version anchors, applicability, review tier
status: ACTIVE
owner: Workspace owner ([OPERATOR_NAME])
introduced: v11.12
schema_version: 1
last_full_catalog_review: 2026-05-15
adr: ""
consumers: deploy.sh Check 18, OPERATIONS.md Framework Review Cadence Protocol, framework-corpus-discipline.md
cross_references: version-field-semantics.md (parallel anchor mechanism), methodology-parameterization-v1.md, methodology-archetype-matrix.md
---
<!-- reference-durability: allow-link -->

# Framework Catalog

Authoritative registry of every named framework, methodology, or standard the platform references. This catalog is the **single source of truth** for framework version anchors — per-doc `framework_version_anchor:` frontmatter (where present) is a *derived demonstration*, not the source (see [`standards/framework-corpus-discipline.md`](../standards/framework-corpus-discipline.md) § 5). The catalog is the registry read by `deploy.sh` Check 18 (it follows Check 13's `TEMPLATE_SYNC_MAP` registry pattern, not Check 14's corpus glob).

**Schema** (11 columns):

| Column | Type | Rule |
|---|---|---|
| `framework` | string | Canonical name |
| `class` | enum `EXTERNAL`\|`INTERNAL` | Industry-standard vs platform-owned |
| `version_anchor` | string, non-empty | **Authoritative anchor.** EXTERNAL: edition/year. INTERNAL: platform release tag (composes with [`version-field-semantics.md`](../standards/version-field-semantics.md)) |
| `canonical_doc` | repo path \| `—` | Doc owning this framework's platform treatment (drives Check 18b); `—` if referenced inline only |
| `adopted` | YYYY-MM-DD \| release tag | Platform adoption point |
| `applicability_scope` | string | Where it governs |
| `tier` | enum `stable`\|`evolving`\|`emerging` | Drives cadence (see [`standards/framework-corpus-discipline.md`](../standards/framework-corpus-discipline.md) § 3 + [OPERATIONS.md § Framework Review Cadence Protocol](../governance/OPERATIONS.md)) |
| `review_cadence` | derived | `stable→36mo`, `evolving→12mo`, `emerging→continuous` (Check 18a asserts it matches `tier`) |
| `last_reviewed` | YYYY-MM-DD | Last cadence review |
| `next_review_due` | YYYY-MM-DD \| `continuous` | Computed = `last_reviewed` + cadence; `continuous` for emerging |
| `owner` | string | Accountable party |

**Tier-assignment rule** is objective (not vibes) and codified in [OPERATIONS.md § Framework Review Cadence Protocol](../governance/OPERATIONS.md). Tier is re-evaluated at each triggered review — a framework may graduate `emerging → evolving → stable`. Seed rows bootstrap `last_reviewed: 2026-05-15` (catalog introduction); `next_review_due` is the computed cadence horizon.

## Catalog

| framework | class | version_anchor | canonical_doc | adopted | applicability_scope | tier | review_cadence | last_reviewed | next_review_due | owner |
|---|---|---|---|---|---|---|---|---|---|---|
| PMBOK | EXTERNAL | PMBOK 7th (2021) | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| SAFe | EXTERNAL | SAFe 6.0 | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | evolving | 12mo | 2026-05-15 | 2027-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Scrum | EXTERNAL | Scrum Guide 2020 | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | evolving | 12mo | 2026-05-15 | 2027-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Kanban | EXTERNAL | Kanban (Anderson 2010) | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| XP | EXTERNAL | XP (Beck 2nd ed. 2004) | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Waterfall | EXTERNAL | PMBOK predictive lifecycle | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| PRINCE2 | EXTERNAL | PRINCE2 2017 | — | v11.01 | delivery_approach enum (methodology-archetype-matrix.md) | evolving | 12mo | 2026-05-15 | 2027-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Nonaka SECI | EXTERNAL | Nonaka SECI (1995) | — | v11.12 | knowledge-architecture / corpus curation | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Diátaxis | EXTERNAL | Diátaxis (current/rolling) | — | v11.12 | documentation taxonomy | evolving | 12mo | 2026-05-15 | 2027-05-15 | Workspace owner ([OPERATOR_NAME]) |
| ADKAR | EXTERNAL | ADKAR (Prosci, current ed.) | — | v11.12 | change-management skill | evolving | 12mo | 2026-05-15 | 2027-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Cost of Delay | EXTERNAL | Cost of Delay (Reinertsen 2009) | — | v11.12 | prioritization / WSJF | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| three-gulfs-methodology | INTERNAL | v11 | pmo-platform/reference/explanation/three-gulfs-methodology.md | v11 | eval design / failure analysis | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| failure-mode-standard | INTERNAL | v9.0 | pmo-platform/reference/specs/failure-mode-standard.md | v9.0 | skill authoring (failure-mode discipline) | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| review-discipline-principles | INTERNAL | v10.2 | pmo-platform/reference/explanation/review-discipline-principles.md | v10.2 | review-class skills | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| decision-discipline | INTERNAL | v10.2 | pmo-platform/reference/explanation/decision-discipline.md | v10.2 | decision-class work | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| methodology-parameterization-v1 | INTERNAL | v11.01 | pmo-platform/reference/specs/methodology-parameterization-v1.md | v11.01 | delivery_approach parameterization | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| five-function-spine | INTERNAL | v11.03 | pmo-platform/reference/explanation/five-function-spine-and-process-flows.md | v11.03 | function mapping / role-skill wave | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| practice-efficacy-framework | INTERNAL | v11.13 | pmo-platform/reference/standards/practice-efficacy-framework.md | v11.13 | efficacy measurement for adopted platform practices | emerging | continuous | 2026-05-23 | continuous | Workspace owner ([OPERATOR_NAME]) |
| review-composition-framework | INTERNAL | v11.13 | pmo-platform/reference/standards/review-composition-framework.md | v11.13 | cross-stage review composition + agent-correction discipline | emerging | continuous | 2026-05-22 | continuous | Workspace owner ([OPERATOR_NAME]) |
| initiative-roadmap-framework | INTERNAL | v11.13 | pmo-platform/reference/standards/initiative-roadmap-framework.md | v11.13 | initiative roadmaps + cohesion-check (instances operator-local per ADR-012) | emerging | continuous | 2026-05-23 | continuous | Workspace owner ([OPERATOR_NAME]) |
| km-governance-framework | INTERNAL | v11.13 | pmo-platform/reference/standards/km-governance-framework.md | v11.13 | KM corpus governance for adopted platform knowledge artifacts (ownership / approval / retirement / meta-governance) | emerging | continuous | 2026-05-23 | continuous | Workspace owner ([OPERATOR_NAME]) |

## Notes

- **EXTERNAL `canonical_doc = —`:** per-framework dedicated docs are pending downstream work. EXTERNAL frameworks are currently referenced inline (release-process.md methodology cadence table, [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md), [`release-personas.md`](../../release/references/specs/release-personas.md), roadmaps). Check 18b SKIPs rows with `canonical_doc = —` (no doc to consistency-check).
- **INTERNAL `canonical_doc` + Check 18b frontmatter SKIP:** Check 18b asserts `framework_version_anchor:` (YAML frontmatter) == catalog `version_anchor` *only for docs that carry YAML frontmatter*. `three-gulfs-methodology.md`, `failure-mode-standard.md`, `methodology-parameterization-v1.md`, and `five-function-spine-and-process-flows.md` use the inline `**Status:**`-style metadata convention (no YAML frontmatter) → Check 18b SKIPs them (documented v1 limitation, parallels doc-link Pattern-C manual-checklist deferral). `review-discipline-principles.md` and `decision-discipline.md` carry YAML frontmatter and are 18b-machine-checked.
- **Tier distribution (seed):** no `emerging` rows — all 17 seed frameworks are established (settled field / mature INTERNAL standards ≥2 minor releases stable). The `emerging` tier is defined and available; it is assigned when a genuinely unsettled framework is registered, or when an INTERNAL standard is in its first 2 minor releases of life.
- **Adding a framework:** append a row here (the catalog is the governed registry — new frameworks enter the platform *via this catalog* by convention). Assign `tier` per the [OPERATIONS.md](../governance/OPERATIONS.md) rule; compute `next_review_due`; set `last_reviewed` to the registration date.
