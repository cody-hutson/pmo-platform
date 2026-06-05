---
title: ADR-006 — Skill-to-module map (canonical 3-module decomposition for pmo-platform-v2)
status: Accepted
date: 2026-05-27
deciders: "operator + Stage 5 Solutioning spoke + adversarial review"
tags: [architecture, module-boundary, skill-classification, extraction-readiness]
source_observations:
  - pmo-platform/skills/ at HEAD d849255 — 21 SKILL_LIST skills + 1 canary = 22 active skill directories
  - Stage 5 spec (sub-task — API contracts) — canonical skill-to-module map authoring
  - Adversarial review — 3 Major findings (PR-1, PR-2, CD-1) advisory; operator standing-GO at Collective Review APPROVE WITH OVERRIDES 2026-05-27 ratified the 3-module decomposition
---

# ADR-006 — Skill-to-module map (canonical 3-module decomposition)

## Status

Accepted (operator standing-GO at Collective Review 2026-05-27; spec authored at Stage 5 sub-task; ADR authored at Stage 6). Numbered ADR-006 because ADR-001..005 were taken between 2026-04-29 and 2026-05-17 for earlier foundational decisions.

**Amended in part by ADR-012 (2026-06-02):** the core-module roadmap count no longer includes tracked roadmap instances — instances are de-scoped to operator-local authoring per ADR-012. The skill-to-module map below is unchanged.

## Context

This release introduces `pmo-platform-v2` as a new private modular-monolith repo with structural axis `operations/` + `release/` + `core/` + `docs/` + `packages/`. The platform's 22 active skill directories (21 SKILL_LIST + 1 canary) must classify to exactly one module per the parent issue Acceptance Criteria. Three classification axes were considered:

1. **3-module decomposition** (operations / release / core) — adopted by Stage 5 spec per `harness-plan § 2.2`.
2. **4-module decomposition** (operations / release / platform-meta / core) — advisory counter-design from the adversarial review CD-1, preserving the canonical 4-scope manifest at `operating-model.md § 1.3` (project-ops / platform-pipeline-stage-ownership / platform-pipeline-decision-briefing / platform-meta).
3. **Per-skill containers** — rejected at Stage 5 as exploding the module boundary surface.

Empirical evidence: pipeline-reference density survey at HEAD `d849255` returned 22:0 release-side-vs-operations-side citation skew for the contested boundary cases (build-reviewer, implementation-planner, pmo-skill-editor, pmo-skill-refiner). Adversarial review FM-1 flagged that aggregate density "22 cluster" conceals fine-grain variance (pmo-skill-editor pipeline-density = 6; build-reviewer pipeline-density = wider distribution).

Operator decision at Collective Review (APPROVE WITH OVERRIDES 2026-05-27) ratified the 3-module decomposition with the 4-module counter-design accepted as deferred residual.

## Decision

**The canonical skill-to-module map for pmo-platform-v2 is:**

| Module | Count | Skills |
|---|---|---|
| **operations** | 12 | artifact-generator, change-management, comms-writer, daily-status, delivery-engine, file-router, pmo-process-designer, pmo-technical-analyst, ppm-agent, project-initiator, tracker-manager, weekly-status-rollup |
| **release** | 6 + 1 canary | build-reviewer, implementation-planner, pmo-skill-editor, pmo-skill-refiner, release-executor, release-planner; canary: pmo-skill-refiner-selftest-canary |
| **core** | 3 | eval-writer, pmo-qa-auditor, prompt-builder |
| **TOTAL** | 22 | 21 SKILL_LIST + 1 canary |

**Contested-case resolutions** (per pipeline-reference density at HEAD `d849255`):

- `pmo-skill-editor` → **release** (pipeline-bound at Stage 7 secondary skill per `operating-model.md`; cited from release pipeline shards)
- `pmo-skill-refiner` → **release** (pipeline-bound; spawns at Stage 6/12 per release-executor)
- `build-reviewer` → **release** (platform-meta scope but pipeline-coupled by audience — consumed at Stage 4/9 review surfaces)
- `implementation-planner` → **release** (Stage 4 spoke per `stage-to-skill-mode-mapping.md`)

**Canary handling:** `pmo-skill-refiner-selftest-canary` lives in release/ as canary-source-only; NOT part of release's Public API.

**Agent definitions** (`.claude/agents/pmo-*.md`, 8 files) classify to **release/.claude/agents/** per Stage 5 spec Surface 1.4 — pipeline-bound spoke personas with zero operations-side consumers.

## Consequences

1. **Module migration scope locked:**
   - operations migration absorbs 12 skills + raid-log.schema.json + project-data-architecture roadmap
   - release migration absorbs 6 skills + 1 canary + 8 agent definitions + 11 release-standards + 9 release-specs + release-process.md rule + RELEASE_PROTOCOL.md + release-process-fitness roadmap + 9 release-tools

2. **Core-module (this ticket) scope locked:**
   - 3 shared skills (eval-writer, pmo-qa-auditor, prompt-builder) + hooks + disciplines + schemas + 34 standards + 12 specs + cross-cutting governance + 6 roadmaps + deploy.sh + 4 deploy-callable tools + 7 rules + CLAUDE.md.template

3. **Re-classification protocol:** Future re-classifications require ADR-006 amendment + per-module migration update. Per the operator standing-GO Collective Review acceptance, the 4-module counter-design (CD-1) remains a documented alternative; if extraction-readiness validation surfaces the 3-module collapse as load-bearing-defective, ADR-006 may amend to a 4-module structure (Reversibility: MODERATE — folder rename + skill-list updates).

4. **Cross-module dependency contract (per module READMEs at SHA `28bb313`):**
   - operations depends ON core ONLY (PROHIBITED into release)
   - release depends ON core ONLY (PROHIBITED into operations)
   - core depends on NO module (PROHIBITED into operations and release)
   - Cycle-prevention enforced at audit.

5. **Adversarial advisory findings carried as residual:**
   - PR-1 (3-vs-4 module decomposition) — operator-accepted at scope-lock; 4-module path remains documented at CD-1 evidence
   - PR-2 (8 agent definitions absent from map) — resolved by sibling spec Surface 1.4; this ADR codifies the resolution
   - FM-3 (eval-writer → pmo-skill-refiner cross-module conceptual reference) — accepted as Stage 6 deferred work; audit re-checks at extraction-readiness validation

## Reversibility

**MODERATE** — re-classification involves cross-module migration redo (file moves + per-module README updates + cross-citation rewrites). CHEAP for single-skill re-classifications (e.g., promote prompt-builder from core to platform-meta); MODERATE for whole-axis re-decomposition (e.g., 3→4 module collapse).

**Confidence:** HIGH at operator standing-GO ratification; MEDIUM-HIGH at extraction-readiness validation (extraction-readiness validation will empirically verify).

## Related ADRs

- ADR-007 — Core Module Boundary Lock-In (file-placement decisions; consumes this skill map for the 3-skill core boundary)
- ADR-008 — deploy.sh Per-Module Array Design (consumes this skill map for SKILL_LIST partitioning)
- ADR-009 — Rewrite-Map CLI Design (downstream cross-module ref rewriting; depends on this map for source/target classification)
