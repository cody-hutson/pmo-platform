---
title: ADR-007 — Core module boundary lock-in (file-placement decisions for the module-restructure core migration)
status: Accepted
date: 2026-05-27
deciders: "operator + Stage 5 Solutioning spoke + adversarial review"
tags: [architecture, module-boundary, file-placement, cycle-prevention]
source_observations:
  - Stage 5 spec (sub-task — core migration spec) — file-placement decisions for 8 sub-units
  - Adversarial review — 4 Blocker findings; operator standing-GO at Collective Review APPROVE WITH OVERRIDES 2026-05-27 ratified the spec with deferred-residual acceptance
  - Empirical filesystem survey at HEAD d849255: 45 standards, 21 specs, 21 disciplines, 16 schemas, 8 governance roadmaps, 13 engineering tools, 8 rules, 14 allowlists, 10 hooks
---

# ADR-007 — Core module boundary lock-in (file-placement decisions)

## Status

Accepted (operator standing-GO at Collective Review 2026-05-27; spec authored at Stage 5 sub-task; ADR authored at Stage 6). Sibling to ADR-006 (skill map) — ADR-007 locks the non-skill content boundary.

**Amended in part by ADR-012 (2026-06-02):** the roadmaps-split clause (§ Context item 5 / § Decision "roadmaps (6/1/1)") is superseded — roadmap instances are de-scoped to operator-local authoring, not module-placed. All non-roadmap boundary locks below stand.

## Context

The core/ module hosts the shared kernel — content consumed by BOTH operations and release. At Stage 5 Solutioning for the core migration, six categories of file-placement decisions surfaced as non-obvious (per-file audience analysis required rather than whole-directory migration):

1. RELEASE_LOG.md placement (operator-instance vs core/governance/)
2. Standards split (core vs release vs operations)
3. Specs split (core vs release)
4. Engineering tools split (core/deploy/tools/ vs release/tools/)
5. Roadmaps split (core vs operations vs release)
6. .claude/rules/ split (core vs release)
7. Agent definitions placement (8 .claude/agents/pmo-*.md → release/ per Surface 1.4)
8. raid-log.schema.json (operations-only artifact → operations/, not core/)

Adversarial review surfaced 4 Blocker findings, with figures as of that review (PR-1 standards arithmetic 33+13≠46 actually 45; PR-2 RELEASE_LOG.md orphans 30 incoming refs; PR-3 cycle-prevention grep under-specified — empirical ≥80 baseline; FM-1 + FM-2 cascade-omission patterns) and Counter-Designs CD-1 (rewrite-map authoring at Stage 5 vs 6) and CD-2 (RELEASE_LOG.md template-at-core counter-design). Operator decision at Collective Review APPROVE WITH OVERRIDES 2026-05-27 ratified the spec's classifications with deferred-residual acceptance — cross-citation rewrite work routes to follow-on cleanup tickets.

## Decision

**The canonical file-placement boundary for the core/ module is LOCKED at these per-class classifications:**

### Hook layer (`core/hooks/` + `core/config/allowlists/`)
- **10 hooks** as of authoring (8 block-*.sh + 2 helpers) → `core/hooks/`
- **14 allowlist files** (`.claude/*.txt`) → `core/config/allowlists/` (corrects Stage 4 plan's "8" count via empirical survey as of authoring)
- **9 test fixtures** + test-runner.sh → `core/hooks/tests/`
- **2 mode files** (`.mode`, `deploy-check.mode`) → `core/hooks/{.mode.template, deploy-check.mode.template}` (operator-instance live values at install-time)
- **Runtime artifacts** (*.jsonl warn-logs, hook-errors.log) → NOT migrated; auto-create in operator instance

### Disciplines (`core/disciplines/`)
- 21 .md files from `pmo-platform/reference/explanation/` → `core/disciplines/` (1:1 mapping, no exclusions)

### Schemas (`core/schemas/`)
- 15 .md files → `core/schemas/` (universal)
- **raid-log.schema.json** → `operations/schemas/` (operations-only artifact)

### Standards (`core/standards/` = 34 of 45)
- **34 universal** → `core/standards/` (per per-file audience analysis during the core migration)
- **11 release-specific** → `release/standards/`
- **0 operations-specific**

### Specs (`core/specs/` = 12 of 21)
- **12 universal** → `core/specs/`
- **9 release-pipeline-specific** → `release/specs/`

### Engineering tools (`core/deploy/tools/` = 4 of 13)
- **4 deploy.sh-callable** → `core/deploy/tools/` per FX1 reconciliation 2026-05-27
  (check-doc-links.py, check-version-anchors.py, generate_release_index.py, lint_release_corpus.py)
- **9 release-pipeline** → `release/tools/`

### Governance roadmaps (`core/governance/roadmaps/` = 6 of 8)
- **6 cross-cutting** → `core/governance/roadmaps/` (automation, data-architecture-family, governance-hygiene, knowledge-architecture, skills-distribution, template-architecture)
- **1 operations** → `operations/governance/roadmaps/project-data-architecture.md`
- **1 release** → `release/governance/roadmaps/release-process-fitness.md`

### `.claude/rules/` mirror (`core/rules/` = 7 of 8)
- **7 universal** → `core/rules/` (bypass-mode-readiness, doc-link-maintenance, governance-files, git-workflow, harness-deployment, operations-bridge, skill-deployment)
- **1 release** → `release/rules/release-process.md` (13-stage pipeline)

### Top-level governance
- `OPERATIONS.md` + `README.md` → `core/governance/` (universal)
- `RELEASE_PROTOCOL.md` → `release/governance/`
- `RELEASE_LOG.md` → **operator-instance** at `~/Claude/personal/pmo-instance/RELEASE_LOG.md` per harness plan § 2.4 — NOT in any module
- `governance/adr/` → the migration sub-task owns ADR migration end-to-end (R5); existing ADR-001..005 land at appropriate per-module ADRs/

### Agent definitions
- `.claude/agents/pmo-*.md` → `release/.claude/agents/`
- Pipeline-bound spoke personas; zero operations-side consumers

### Workspace-root template
- `core/CLAUDE.md.template` (depersonalized) — operator-instance setup script writes `~/Claude/CLAUDE.md` with substitutions applied

## Consequences

1. **Module-migration scope locked — populations as of authoring: operations migration absorbs raid-log.schema.json + 1 operations roadmap; release migration absorbs 11 release-standards + 9 release-specs + 9 release-tools + 1 release-roadmap + release-process.md + RELEASE_PROTOCOL.md + 8 agent definitions.**

2. **Tooling-adaptation scope locked: deploy.sh adapt; path rewrites; Check 14/15.** The adaptation reads `core/deploy/deploy.sh` byte-identical-to-source as starting point; path rewrites read cross-module reference scope (≥80 baseline cycle violations per adversarial PR-3); Check 14/15 tooling extends `core/deploy/tools/check-doc-links.py`.

3. **RELEASE_LOG.md operator-instance routing (adversarial PR-2 acceptance):** as of authoring, 30 standards + OPERATIONS.md + schemas cite RELEASE_LOG.md as incoming reference. Per operator standing-GO, these citations remain in-text at the core-migration close — cross-citation rewrite work deferred to follow-on tickets. Counter-design CD-2 (templated artifact at core) NOT adopted this release; preserves operator-instance separation per harness plan § 2.4.

4. **Cycle-prevention contract:** Core MUST NOT depend on operations or release. Verified via `grep -rln "operations/|release/" pmo-platform-v2/core/`. Per adversarial PR-3 baseline, ≥80 matches existed as of the core-migration close (disciplines residual); subsequent audits resolve at extraction-readiness validation.

5. **Per-file rationale durability:** ADR-007 supersedes any prior per-file classification claim in Stage 4 plan or Stage 5 spec where contradicted. Future re-classifications require ADR-007 amendment.

## Reversibility

**MODERATE** — re-classification involves file moves + cross-module reference cascade updates per per-edit discipline. CHEAP for individual file moves (e.g., reclassify a single standard from core to release); MODERATE for multi-file re-classification (e.g., move all 6 then-current cross-cutting roadmaps to a different module).

**Confidence:** MEDIUM-HIGH at operator standing-GO ratification; the 4 Blocker findings from adversarial review carry forward as residual but operator accepted with explicit deferred-resolution route. HIGH at extraction-readiness validation (will empirically test).

## Composition with adversarial review findings

| Finding | Disposition |
|---|---|
| PR-1 (standards arithmetic 45 ≠ 46) | Resolved — empirical re-count during the core migration; 34 core + 11 release = 45 total |
| PR-2 (RELEASE_LOG.md orphans 30 incoming refs, as of that review) | Accepted as residual; deferred cleanup. Counter-design CD-2 documented but NOT adopted. |
| PR-3 (cycle-prevention grep ≥80 matches, as of that review) | Accepted as residual; ADR-007 locks the boundary; rewrite map deferred to subsequent migration tickets |
| PR-4 (block-skill-direct-edit hook semantics) | Resolved — hook stays at core/hooks/; pmo-skill-editor at release/skills/ creates Case D dependency edge (release → core, acceptable) |
| FM-1 + FM-2 cascade-omissions | Resolved — empirical counts cited inline in this ADR; commit messages cite per-batch arithmetic |
| FM-3 spec-vs-reality canonicalization | Resolved — solutioning-output-template.md routes to release/ |
| FM-4 Knowable-now without evidence | Accepted — per-file audience tables in spec sufficient; full grep-evidence at audit |
| FM-5 hook-count cascade | Resolved — 10 .sh files (8 block-* + 2 helpers) verified empirically |
| CD-1 rewrite-map at Stage 5 vs 6 | DEFERRED — operator standing-GO; map authored at Stage 6, not Stage 5 |
| CD-2 RELEASE_LOG.md template-at-core | NOT ADOPTED — operator-instance preferred per harness plan § 2.4 |
| CD-3 operating-model.md routing | Accepted — file routes to core/disciplines/ per spec; 55 pipeline citations residual; a later audit may surface as Case B for refactor |
| CD-4 ADR-007 rewrite-strategy enum | DEFERRED — Surface 10 rewrite-strategy enum lives in the migration spec, not ADR-007 |
| CD-5 pre-commit grep in Surface 13 | NOT ADOPTED — per-batch commit verification used instead |
| CD-6 ADR-007 ownership | Resolved — Stage 6 authors substance (this file); content is canonicalized BY this ADR |

## Carry-Forward Extension

Per the cross-module reference cleanup execution (operator-ratified at the Stage 5 spec and the prior audit recommendations), the ADR-007 carry-forward contract is **extended** from its v1 narrow scope to a broader v2 documentary-cohesion scope:

**v1 scope (original Decision 4):** documentary markdown-doc-links from `core/{disciplines, schemas}` to `release/governance/release-process.md` OR `release/references/pipeline/*` are accepted cohesion.

**v2 scope (extended):**
- **Source files allowed:** `core/{disciplines, schemas, standards, ADRs, rules, governance, README.md}` + `core/deploy/tools/README.md` (audit-doc README)
- **Target prefixes allowed:** `operations/` + `release/` (full module subtrees)
- **Cross-ref-type allowed:** markdown-doc-link OR narrative-mention (NOT code-import — code-import remains BLOCKER per architectural invariant)

**Architectural rationale:** Core foundational concept docs (disciplines, schemas, standards, ADRs, rules) legitimately reference operations and release content as documentary cohesion. Specifically:
- Core ADRs describing the module boundary naturally enumerate content from all modules.
- `core/schemas/per-skill-output-contracts.md` enumerates output contracts for skills in ALL modules.
- `core/disciplines/architecture-overview.md` documents the cross-module architecture itself.
- `core/disciplines/operating-model.md` spans both core foundation + release pipeline implementation by design.
- `core/rules/git-workflow.md` describes branch + PR conventions referencing release-side patterns.

**Architectural invariant preserved:** Zero code-import cycles from `core/` to `operations/` or `release/`. The classifier still rejects `from operations.X import Y` and `source release/...` patterns as `cycle-code-import` (BLOCKER).

**Deploy infrastructure exemption (Pattern-P4):** `core/deploy/deploy.sh` + `core/deploy/tools/{cross_module_audit_helper.py, cross-module-audit.sh, check-doc-links.py}` are exempt from cross-module audit by design — they operate ACROSS modules per ADR-008 per-module array design.

**Prose-disjunction exemption (Pattern-P5):** Known prose patterns (`release/issue`, `release/deployment`, `release/vX.Y-description`) are recognized as English compound nouns / branch-name templates, not file references.

**Audit results post-cleanup (2026-05-27):**

| Metric | Pre-cleanup baseline | Post-cleanup | Delta |
|---|---|---|---|
| Total findings | 955 | 871 | -84 (deploy-infra + prose-disjunction exempted at scan) |
| `(g) operator-decide` count | 388 | 0 | -388 (all reclassified via extension + Public API) |
| `via-public-api` count | 478 | 555 | +77 (Pattern-P2/P3: operations/templates/ + operations/skills/ Public API path-prefix) |
| `info-adr-007-carry-forward` count | 89 | 316 | +227 (Pattern-P1: extended carry-forward) |
| `cycle-code-import` count | 0 | 0 | 0 (invariant preserved) |

## Related ADRs

- ADR-006 — Skill-to-module map (consumes for the 3 core skills)
- ADR-008 — deploy.sh Per-Module Array Design (locks how deploy.sh array partitioning reads this file-placement boundary; later adds an audit tooling exemption)
- ADR-009 — Rewrite-Map CLI Design (locks how cross-module rewrites consume this boundary)
