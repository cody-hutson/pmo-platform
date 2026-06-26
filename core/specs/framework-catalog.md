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
| ADKAR | EXTERNAL | ADKAR (Prosci, current ed.) | operations/skills/change-management/references/adkar-framework.md | v11.12 | change-management skill | evolving | 12mo | 2026-05-15 | 2027-05-15 | Workspace owner ([OPERATOR_NAME]) |
| Cost of Delay | EXTERNAL | Cost of Delay (Reinertsen 2009) | operations/skills/intake-desk/references/intake-governance.md | v11.12 | prioritization / WSJF | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| three-gulfs-methodology | INTERNAL | v11 | core/disciplines/three-gulfs-methodology.md | v11 | eval design / failure analysis | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| failure-mode-standard | INTERNAL | v9.0 | core/standards/failure-mode-standard.md | v9.0 | skill authoring (failure-mode discipline) | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| review-discipline-principles | INTERNAL | v10.2 | core/disciplines/review-discipline-principles.md | v10.2 | review-class skills | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| decision-discipline | INTERNAL | v10.2 | core/disciplines/decision-discipline.md | v10.2 | decision-class work | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| methodology-parameterization-v1 | INTERNAL | v11.01 | release/references/specs/methodology-parameterization-v1.md | v11.01 | delivery_approach parameterization | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| five-function-spine | INTERNAL | v11.03 | core/disciplines/five-function-spine-and-process-flows.md | v11.03 | function mapping / role-skill wave | stable | 36mo | 2026-05-15 | 2029-05-15 | Workspace owner ([OPERATOR_NAME]) |
| practice-efficacy-framework | INTERNAL | v11.13 | core/standards/practice-efficacy-framework.md | v11.13 | efficacy measurement for adopted platform practices | emerging | continuous | 2026-05-23 | continuous | Workspace owner ([OPERATOR_NAME]) |
| review-composition-framework | INTERNAL | v11.13 | core/standards/review-composition-framework.md | v11.13 | cross-stage review composition + agent-correction discipline | emerging | continuous | 2026-05-22 | continuous | Workspace owner ([OPERATOR_NAME]) |
| initiative-roadmap-framework | INTERNAL | v11.13 | core/standards/initiative-roadmap-framework.md | v11.13 | initiative roadmaps + cohesion-check (instances operator-local per ADR-012) | emerging | continuous | 2026-05-23 | continuous | Workspace owner ([OPERATOR_NAME]) |
| km-governance-framework | INTERNAL | v11.13 | core/standards/km-governance-framework.md | v11.13 | KM corpus governance for adopted platform knowledge artifacts (ownership / approval / retirement / meta-governance) | emerging | continuous | 2026-05-23 | continuous | Workspace owner ([OPERATOR_NAME]) |
| Gang of Four | EXTERNAL | Gang of Four (1994) | — | domain-aware-stage5-design | software domain best-practice guide (maintainability / evolvability / scalability — patterns); referenced by core/standards/domain-best-practices/software.md | stable | 36mo | 2026-06-07 | 2029-06-07 | Workspace owner ([OPERATOR_NAME]) |
| ADR — Nygard | EXTERNAL | Nygard (2011) | — | domain-aware-stage5-design | software domain best-practice guide (decisions as maintainability artifacts) + KM-artifact lifecycle ADR-instance grounding; referenced by core/standards/domain-best-practices/software.md | stable | 36mo | 2026-06-07 | 2029-06-07 | Workspace owner ([OPERATOR_NAME]) |
| Fowler design heuristics | EXTERNAL | Fowler — YAGNI (current bliki ed.) | — | domain-aware-stage5-design | software domain best-practice guide (simplicity-first heuristic — ET5, paired contraindication mandatory); referenced by core/standards/domain-best-practices/software.md | evolving | 12mo | 2026-06-07 | 2027-06-07 | Workspace owner ([OPERATOR_NAME]) |
| domain-best-practices/software | INTERNAL | domain-aware-stage5-design | core/standards/domain-best-practices/software.md | domain-aware-stage5-design | software-domain design-consumption guide (Stage 5/7) | emerging | continuous | 2026-06-07 | continuous | Workspace owner ([OPERATOR_NAME]) |
| domain-best-practices/governance | INTERNAL | domain-aware-stage5-design | core/standards/domain-best-practices/governance.md | domain-aware-stage5-design | governance-domain design-consumption guide (Stage 5/7) | emerging | continuous | 2026-06-07 | continuous | Workspace owner ([OPERATOR_NAME]) |
| work-organization-mapping-framework | INTERNAL | declarative-workitem-type-model | core/disciplines/work-organization-mapping-framework.md | declarative-workitem-type-model | work-organization standardization (universal hierarchy concept + hierarchy-by-methodology map + best-practice default work-item schemas + user plug-and-play); consumed by intake-desk / delivery-engine / ppm-agent + the declarative work-item type layer | emerging | continuous | 2026-06-07 | continuous | Workspace owner ([OPERATOR_NAME]) |
| agent-script-promotion-framework | INTERNAL | v1.09 | core/standards/agent-script-promotion-framework.md | v1.09 | agent-to-script promotion governance — AS0–AS4 ladder, triggers, authoring/testing/drift/interface/versioning across the script estate (core hooks/deploy, release tools, skill-bundled scripts) | emerging | continuous | 2026-06-11 | continuous | Workspace owner ([OPERATOR_NAME]) |
| Kotter 8-Step | EXTERNAL | Kotter (Leading Change, 2nd ed. 2012) | operations/skills/change-management/references/kotter-8-step.md | pmo-skill-reference-substrate | change-management skill (methodology suite) | evolving | 12mo | 2026-06-14 | 2027-06-14 | Workspace owner ([OPERATOR_NAME]) |
| Lewin 3-Stage | EXTERNAL | Lewin (Field Theory in Social Science, 1951) | operations/skills/change-management/references/lewin-3-stage.md | pmo-skill-reference-substrate | change-management skill (methodology suite) | stable | 36mo | 2026-06-14 | 2029-06-14 | Workspace owner ([OPERATOR_NAME]) |
| Bridges Transition | EXTERNAL | Bridges (Managing Transitions, 4th ed. 2017) | operations/skills/change-management/references/bridges-transition.md | pmo-skill-reference-substrate | change-management skill (methodology suite) | evolving | 12mo | 2026-06-14 | 2027-06-14 | Workspace owner ([OPERATOR_NAME]) |
| McKinsey 7-S | EXTERNAL | McKinsey 7-S (Peters & Waterman / Pascale & Athos, 1980) | operations/skills/change-management/references/mckinsey-7s.md | pmo-skill-reference-substrate | change-management skill (methodology suite) | stable | 36mo | 2026-06-14 | 2029-06-14 | Workspace owner ([OPERATOR_NAME]) |
| Fowler Technical Debt Quadrant | EXTERNAL | Fowler — Technical Debt Quadrant (2009 bliki) | operations/skills/delivery-engine/references/tech-debt-classification.md | v2.01 | tech-debt classification / Mode D sprint planning | evolving | 12mo | 2026-06-15 | 2027-06-15 | Workspace owner ([OPERATOR_NAME]) |
| facilitation-techniques-corpus | INTERNAL | v2.22 | core/standards/facilitation-techniques/README.md | v2.22 | delivery-lifecycle facilitation-techniques corpus (in-execution technique surfacing); consumed by delivery-engine Mode D/E | emerging | continuous | 2026-06-25 | continuous | Workspace owner ([OPERATOR_NAME]) |

## Notes

- **EXTERNAL `canonical_doc`:** The change-management methodology suite (ADKAR, Kotter, Lewin, Bridges, McKinsey 7-S) and Cost of Delay carry populated `canonical_doc` paths — dedicated reference docs exist as of the `pmo-skill-reference-substrate` release. The remaining EXTERNAL rows (the `delivery_approach` frameworks and the domain-guide-source rows Gang of Four / Nygard / Fowler) carry `canonical_doc = —` and are referenced inline (release-process.md methodology cadence table, [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md), [`release-personas.md`](../../release/references/specs/release-personas.md), roadmaps, the software domain guide). Check 18b SKIPs rows with `canonical_doc = —` (no doc to consistency-check), and SKIPs populated rows whose docs use the no-frontmatter house style (the methodology-suite docs).
- **INTERNAL `canonical_doc` + Check 18b frontmatter SKIP:** Check 18b asserts `framework_version_anchor:` (YAML frontmatter) == catalog `version_anchor` *only for docs that carry YAML frontmatter with that key*. `three-gulfs-methodology.md`, `failure-mode-standard.md`, `methodology-parameterization-v1.md`, and `five-function-spine-and-process-flows.md` use the inline `**Status:**`-style metadata convention (no YAML frontmatter) → Check 18b SKIPs them (documented v1 limitation, parallels doc-link Pattern-C manual-checklist deferral). `review-discipline-principles.md`, `decision-discipline.md`, and the two `domain-best-practices/` guide docs (`software.md`, `governance.md`) carry YAML frontmatter with the `framework_version_anchor:` key and are 18b-machine-checked. The three EXTERNAL domain-guide-source rows (Gang of Four / ADR — Nygard / Fowler) carry `canonical_doc = —` (the platform references them inline from the software guide rather than owning a dedicated per-framework doc — the same inline-reference posture every other EXTERNAL row uses); Check 18b SKIPs them. The software guide is a *consumer* of those frameworks, not their canonical platform doc, so its own INTERNAL row (`domain-best-practices/software`) carries the doc's anchor.
- **Tier-assignment policy (not a point-in-time count):** the `emerging` tier is assigned when a genuinely unsettled framework is registered, or when an INTERNAL standard is in its first 2 minor releases of life; `evolving` for frameworks on a 1–3y revision cadence or INTERNAL standards edited within the last 2 minor releases; `stable` for canonical sources unchanged ≥5y with no active revision program or INTERNAL standards unchanged ≥2 minor releases. The two `domain-best-practices/` guide docs are `emerging` (first releases of life); their cited EXTERNAL sources are `stable` (Gang of Four 1994, Nygard 2011) or `evolving` (Fowler's living bliki heuristic). Tier is re-evaluated at each triggered review (a framework may graduate `emerging → evolving → stable`).
- **Adding a framework:** append a row here (the catalog is the governed registry — new frameworks enter the platform *via this catalog* by convention). Assign `tier` per the [OPERATIONS.md](../governance/OPERATIONS.md) rule; compute `next_review_due`; set `last_reviewed` to the registration date.
