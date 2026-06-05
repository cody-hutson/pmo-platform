---
title: Anthropic Base-vs-Build Registry
purpose: Observational catalog of PMO source-roster skills mapped against the Anthropic skill catalog
type: reference
framework: pmo-platform/reference/protocols/platform-health-audit-framework.md
audit_baseline_sha: 4a943131c9e0323d5811f92704914657d7f7c314
audit_baseline_date: 2026-05-03
anthropic_catalog_sources: hybrid (plugin-cache ∪ anthropic-skills:* namespace, deduped)
anthropic_catalog_enumeration_method: see framework §3.1
baseline_policy_reference: audit-baseline-when-target-population-is-empty discipline
precedent: D-Hub-3 Hybrid baseline precedent
row_count: 22
enum: extends | replaces | independent | pass-through
adr: the base-vs-build registry ADR
---
<!-- reference-durability: allow-link -->

# Anthropic Base-vs-Build Registry

## §Purpose

Observational catalog of every PMO source-roster skill (per
[skill-deployment.md](../rules/skill-deployment.md) §Tracked Skills + ADR-04
canary, 22 entries total) mapped against the Anthropic skill catalog (Hybrid baseline per
framework §3.1). Describes overlap status (one of `extends` / `replaces` / `independent` /
`pass-through`) and intentional differentiation. Cataloging is observational only; the
registry does NOT prescribe migration, consolidation, or build-vs-buy actions (per
 body AC3 and the audit-class
output discipline at [review-discipline-principles.md](../disciplines/review-discipline-principles.md)).

The methodology lives in
[`platform-health-audit-framework.md`](../../release/references/protocols/platform-health-audit-framework.md);
this file is the instance.

---

## §Baseline anchor

| Field | Value |
|---|---|
| `audit_baseline_sha` | `4a943131c9e0323d5811f92704914657d7f7c314` |
| `audit_baseline_date` | 2026-05-03 |
| `anthropic_catalog_sources` | Hybrid: Source A (plugin-cache, 17 skills across 9 packs) ∪ Source B (`anthropic-skills:*` namespace, 9 skills), deduped |
| `enumeration_method` | See [framework §3.1](../../release/references/protocols/platform-health-audit-framework.md) |

**Reproducibility:** Any reader can re-run the framework §3.1 enumeration commands at any
future SHA + date and observe drift versus the recorded baseline. The
`audit_baseline_sha`
+ `audit_baseline_date` travel with the registry header; updates per framework §3.3 (a/b/c)
trigger taxonomy.

**Pattern reference:** the audit-baseline-when-target-population-is-empty discipline
+ the D-Hub-3 file-overlap-audit precedent.

---

## §Schema

Each row carries 8 columns:

| Column | Type | Required | Definition |
|---|---|---|---|
| `skill_name` | string (kebab-case) | yes | Matches directory name in `pmo-platform/skills/` |
| `deploy_status` | enum: `deployed` \| `source-only-canary` | yes | Per the registry ADR D-Plan-2a (ii); preserves ADR-04 source-only canary semantics |
| `anthropic_overlap_status` | enum: `extends` \| `replaces` \| `independent` \| `pass-through` | yes | Per the registry ADR D-Plan-2b (iii); closed 4-element enum |
| `anthropic_skill_ref` | string \| `null` | conditional | Anthropic-side identifier; `null` when `anthropic_overlap_status` = `independent` |
| `anthropic_skill_provenance` | enum: `plugin-cache` \| `anthropic-skills` \| `both` \| `n/a` | yes | Per framework §3.1 Hybrid baseline; `n/a` for `independent` rows |
| `overlap_rationale` | string (1-3 sentences) | yes | Observational, descriptive, not prescriptive |
| `overlap_notes` | string \| `null` | optional | Free-form per the registry ADR D-Plan-2b (iii); used for namespace collision, intentional-fork rationale, partial-subset detail, or canary-status reference |
| `build_buy_observation` | string (≤30 words) | yes | Observational language only; describes the observed state, not a prescription. Renamed from M-AC2's `build_buy_recommendation` per the registry ADR body AC3 prohibition on prescriptive verbs (per the registry ADR D-Plan-2b) |

---

## §Observational discipline

All registry content uses observational language only — describes the observed state of
each skill against the Anthropic catalog at the pinned baseline. Per
 body AC3 and
[review-discipline-principles.md](../disciplines/review-discipline-principles.md) audit-class output
discipline, prescriptive verbs (`recommend`, `migrate`, `consolidate`, `should`) are
out-of-bounds in registry content.

The `build_buy_observation` column name (renamed from M-AC2's `build_buy_recommendation`)
embodies this discipline at the schema level: the column describes what is observed, not
what action is to be taken.

---

## §Row count rationale

Per the registry ADR D-Plan-2a (ii), the registry has **22 rows** — full source roster from
`pmo-platform/skills/` directory listing at audit-baseline SHA. The roster includes:

- 21 entries deployed via `deploy.sh` `SKILL_LIST` (S-2 mechanism per
  [skill-deployment.md](../rules/skill-deployment.md))
- 1 source-only entry `pmo-skill-refiner-selftest-canary` per ADR-04 (in source roster but
  excluded from Cowork deployment)

The `deploy_status` column tags the canary as `source-only-canary` to preserve ADR-04
semantics without redefining "deployed". This honors M-AC3 wording ("All 22 deployed
skills") literally while disclosing the canary's source-only status transparently.

---

## §Update triggers

See [framework §3.3 Registry Update Protocol](../../release/references/protocols/platform-health-audit-framework.md)
for the (a/b/c) trigger taxonomy:

- (a) New PMO skill built — author adds row at skill-creation PR
- (b) Anthropic releases new skill — registry walked for new overlap relationships
- (c) Anthropic deprecates existing skill — affected `anthropic_overlap_status` re-classified

See [framework §3.5](../../release/references/protocols/platform-health-audit-framework.md) for the 5-trigger event
taxonomy (T1-T5) consumed by a future `mcp__scheduled-tasks` registration.

---

## §Registry rows

### Row 1 — artifact-generator

| Column | Value |
|---|---|
| `skill_name` | `artifact-generator` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Produces or updates project artifacts (FRDs, RAID logs, project plans, agendas). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill targeting project artifact generation; no Anthropic equivalent observed in Hybrid baseline. |

### Row 2 — build-reviewer

| Column | Value |
|---|---|
| `skill_name` | `build-reviewer` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Conducts production-readiness review of governed document packs (Copilot Builder Agent, PMO platform, generic). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for governed-document-pack review with pluggable dimension packs; no Anthropic equivalent observed. |

### Row 3 — change-management

| Column | Value |
|---|---|
| `skill_name` | `change-management` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Plans and tracks organizational change for go-lives and system transitions (impact assessment, training plan, readiness, hypercare, adoption). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill targeting deployment change management; no Anthropic equivalent observed in Hybrid baseline. |

### Row 4 — comms-writer

| Column | Value |
|---|---|
| `skill_name` | `comms-writer` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Produces audience-calibrated stakeholder communications (email, Teams, Confluence, exec briefs, agendas). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for stakeholder communication authoring; no Anthropic equivalent observed in Hybrid baseline. |

### Row 5 — daily-status

| Column | Value |
|---|---|
| `skill_name` | `daily-status` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Generates Teams-ready AM and PM daily status updates from carry-forward trackers and recent transcripts. No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for daily-cadence status generation tied to project trackers; no Anthropic equivalent observed. |

### Row 6 — delivery-engine

| Column | Value |
|---|---|
| `skill_name` | `delivery-engine` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Operational backbone for backlog health through release readiness (DoR/DoD gates, sprint planning, RAID updates, velocity tracking). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill spanning Agile and Waterfall delivery governance; no Anthropic equivalent observed. |

### Row 7 — eval-writer

| Column | Value |
|---|---|
| `skill_name` | `eval-writer` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Authors rigorous eval suites for AI agents, skills, and LLM systems per the 2026 eval-writing consensus (trace-driven error analysis, binary LLM judges, cross-family validation). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for AI eval authorship and judge calibration; no Anthropic equivalent observed in Hybrid baseline. |

### Row 8 — file-router

| Column | Value |
|---|---|
| `skill_name` | `file-router` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Classifies, routes, and triggers processing for new files arriving in the PMO workspace via three-layer classification (content analysis, project identification, filename patterns). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for workspace file ingestion routing; no Anthropic equivalent observed in Hybrid baseline. |

### Row 9 — implementation-planner

| Column | Value |
|---|---|
| `skill_name` | `implementation-planner` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Converts build-reviewer findings registers into sequenced, minimal-change remediation plans (RT-1..RT-8 remediation types). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for governed-pack remediation sequencing; no Anthropic equivalent observed in Hybrid baseline. |

### Row 10 — pmo-process-designer

| Column | Value |
|---|---|
| `skill_name` | `pmo-process-designer` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Converts business context into structured, traceable requirements and process documentation (workflow docs, gap analysis, traceability matrix, compliance mapping). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for requirements documentation and traceability; no Anthropic equivalent observed in Hybrid baseline. |

### Row 11 — pmo-qa-auditor

| Column | Value |
|---|---|
| `skill_name` | `pmo-qa-auditor` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Reviews skill outputs against the Principal Standard. Evaluates rigor, accuracy, judgment, and operational value. No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | A future `platform-health` mode consumes this registry as input (see framework §4 placeholder). |
| `build_buy_observation` | PMO custom skill for skill-output quality auditing; no Anthropic equivalent observed in Hybrid baseline. |

### Row 12 — pmo-skill-editor

| Column | Value |
|---|---|
| `skill_name` | `pmo-skill-editor` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `extends` |
| `anthropic_skill_ref` | `anthropic-skills:skill-creator` |
| `anthropic_skill_provenance` | `both` |
| `overlap_rationale` | Edit, audit, and regression-test skills in the PMO Agent Suite. Functional overlap with `anthropic-skills:skill-creator` on the modify-skill surface; PMO version adds cross-skill regression awareness, exemption-list governance, and Gate 2 hook enforcement. |
| `overlap_notes` | Coupling intensity is lighter than `pmo-skill-refiner` — the `pmo-skill-editor` SKILL.md frontmatter does not explicitly cite `anthropic-skills:skill-creator`. The relationship is extends-by-functional-overlap (specialization on the modify-skill surface) rather than explicit-wrapping. |
| `build_buy_observation` | PMO custom skill specializing the modify-skill surface that `anthropic-skills:skill-creator` also occupies. |

### Row 13 — pmo-skill-refiner

| Column | Value |
|---|---|
| `skill_name` | `pmo-skill-refiner` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `extends` |
| `anthropic_skill_ref` | `anthropic-skills:skill-creator` |
| `anthropic_skill_provenance` | `both` |
| `overlap_rationale` | Wraps `anthropic-skills:skill-creator` (default Anthropic scaffolder) with a PMO refinement layer — Interview mode capture, 7-field PMO injection (delivery_approach, output-contract stub, dependency-graph node, evidence-quality protocol, failure-mode discipline, Principal Standard checklist, reversibility declaration), and the preserved Anthropic eval harness. |
| `overlap_notes` | Explicit wrapping documented in SKILL.md frontmatter description: "wraps an Anthropic scaffolding skill (default: anthropic-skills:skill-creator)". Coupling intensity is heavier than `pmo-skill-editor`. |
| `build_buy_observation` | PMO custom skill explicitly wrapping `anthropic-skills:skill-creator`; PMO refinement layer extends the Anthropic scaffolder. |

### Row 14 — pmo-skill-refiner-selftest-canary

| Column | Value |
|---|---|
| `skill_name` | `pmo-skill-refiner-selftest-canary` |
| `deploy_status` | `source-only-canary` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Source-only smoke test for the `pmo-skill-refiner` factory; reports skill-roster drift between `pmo-platform/skills/` directory and `deploy.sh` `SKILL_LIST`. No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | ADR-04 source-only canary; not deployed to the Cowork install path; serves as a PMO `pmo-skill-refiner` regression sentinel. |
| `build_buy_observation` | PMO custom canary fixture; no Anthropic equivalent observed (Anthropic catalog has no source-only-canary class). |

### Row 15 — pmo-technical-analyst

| Column | Value |
|---|---|
| `skill_name` | `pmo-technical-analyst` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Reviews technical artifacts with senior TPM judgment (FDD review, integration risk, architecture assessment, dependency identification, feasibility feedback). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for senior-TPM technical artifact review; no Anthropic equivalent observed in Hybrid baseline. |

### Row 16 — ppm-agent

| Column | Value |
|---|---|
| `skill_name` | `ppm-agent` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Strategic brain of the PMO — reads any project artifact and pushes every actionable item toward resolution (transcript triage, risk assessment, decision framing). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for portfolio-level project artifact processing; no Anthropic equivalent observed. |

### Row 17 — project-initiator

| Column | Value |
|---|---|
| `skill_name` | `project-initiator` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Manages the full project lifecycle — initiation (folder structure, PROJECT.md, PORTFOLIO.md update) and closure (tracker finalization, summary, archive). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for project lifecycle scaffolding and closure; no Anthropic equivalent observed in Hybrid baseline. |

### Row 18 — prompt-builder

| Column | Value |
|---|---|
| `skill_name` | `prompt-builder` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `replaces` |
| `anthropic_skill_ref` | `anthropic-skills:prompt-builder` |
| `anthropic_skill_provenance` | `anthropic-skills` |
| `overlap_rationale` | Direct namespace collision with `anthropic-skills:prompt-builder`. Both surfaces ship a `prompt-builder` skill; PMO's runtime-resolution mechanism (slash command namespacing) follows PMO's deploy roster, so PMO's `prompt-builder` is the active install for that name. |
| `overlap_notes` | Intentional namespace separation — PMO version operates independently in PMO context; the two implementations are functionally distinct despite the shared name. The collision is an observation, not a constraint on either surface. |
| `build_buy_observation` | PMO `prompt-builder` namespace-collides with `anthropic-skills:prompt-builder`; both surfaces ship distinct implementations under the same name. |

### Row 19 — release-executor

| Column | Value |
|---|---|
| `skill_name` | `release-executor` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Executes approved release plans (snapshot creation, file-change application, IMP item closure, release log update, verification). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for PMO platform release execution; no Anthropic equivalent observed in Hybrid baseline. |

### Row 20 — release-planner

| Column | Value |
|---|---|
| `skill_name` | `release-planner` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Plans the PMO platform release lifecycle (backlog analysis, dependency mapping, release bundle suggestions, dry-run diffs). No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | Future enhancement: `release-planner` MAY consume this registry for cross-Anthropic-overlap capacity heuristics at Stage 3 Bundle (soft outbound handoff per the release milestone description). |
| `build_buy_observation` | PMO custom skill for PMO platform release planning; no Anthropic equivalent observed in Hybrid baseline. |

### Row 21 — tracker-manager

| Column | Value |
|---|---|
| `skill_name` | `tracker-manager` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Generic update engine for operational trackers in `04-PMO-Operations/`. Receives TRACKER_UPDATE instructions, validates against schemas, produces a combined change summary. No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for operational tracker schema-validated updates; no Anthropic equivalent observed in Hybrid baseline. |

### Row 22 — weekly-status-rollup

| Column | Value |
|---|---|
| `skill_name` | `weekly-status-rollup` |
| `deploy_status` | `deployed` |
| `anthropic_overlap_status` | `independent` |
| `anthropic_skill_ref` | `null` |
| `anthropic_skill_provenance` | `n/a` |
| `overlap_rationale` | Generates weekly executive status roll-up across all active projects (project health, risks, decisions, milestones). Writes back updated health indicators to PORTFOLIO.md. No Anthropic counterpart observed in Hybrid baseline. |
| `overlap_notes` | `null` |
| `build_buy_observation` | PMO custom skill for weekly executive portfolio status; no Anthropic equivalent observed in Hybrid baseline. |

---

## §Summary tally

| Classification | Count | Skills |
|---|---|---|
| `extends` | 2 | `pmo-skill-editor`, `pmo-skill-refiner` |
| `replaces` | 1 | `prompt-builder` |
| `independent` | 19 | `artifact-generator`, `build-reviewer`, `change-management`, `comms-writer`, `daily-status`, `delivery-engine`, `eval-writer`, `file-router`, `implementation-planner`, `pmo-process-designer`, `pmo-qa-auditor`, `pmo-skill-refiner-selftest-canary`, `pmo-technical-analyst`, `ppm-agent`, `project-initiator`, `release-executor`, `release-planner`, `tracker-manager`, `weekly-status-rollup` |
| `pass-through` | 0 | (none observed in current source roster; reserved for future) |
| **TOTAL** | **22** | (matches `pmo-platform/skills/` directory listing at audit-baseline SHA) |

**Deploy status tally:**

| Status | Count | Skills |
|---|---|---|
| `deployed` | 21 | (all rows except row 14) |
| `source-only-canary` | 1 | `pmo-skill-refiner-selftest-canary` (row 14, per ADR-04) |

**Anthropic provenance tally:**

| Provenance | Count | Notes |
|---|---|---|
| `both` | 2 | `pmo-skill-editor`, `pmo-skill-refiner` (both reference `anthropic-skills:skill-creator`, observable in plugin-cache AND `anthropic-skills:*` namespace) |
| `anthropic-skills` | 1 | `prompt-builder` (references `anthropic-skills:prompt-builder`, observable only in `anthropic-skills:*` namespace) |
| `plugin-cache` | 0 | (no PMO skill currently references a plugin-cache-only Anthropic skill) |
| `n/a` | 19 | (all `independent` rows) |

---

**End of registry.**
