# Core Module Architecture Decision Records (ADRs)

Architecture Decision Records for the `core/` module of pmo-platform-v2. Each ADR captures a structurally-load-bearing decision with status, context, decision rationale, consequences, reversibility, and cross-ADR composition.

## Format

ADRs follow the format established by ADR-005 (see [`../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md`](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md)) — frontmatter with `title / status / date / release / deciders / tags / source_observations`, body with `Status / Context / Decision / Consequences / Reversibility / Related ADRs` sections.

## Naming convention

`ADR-NNN-kebab-case-title.md` where NNN is monotonically increasing across the platform (NOT per-module). ADR-003 + ADR-004 are foundational core-scope decisions migrated from an earlier governance location. ADR-001 + ADR-002 + ADR-005 (release-scope) live in [`../../release/ADRs/`](../../release/ADRs/). ADR-006..009 are module-restructure decisions.

## Cross-numbering across the ADR migration + module-restructure ADR materialization

| ADR | Module | Source | Owner | Date |
|---|---|---|---|---|
| ADR-001 | release | pmo-platform | migrated | 2026-05-01 |
| ADR-002 | release | pmo-platform | migrated | 2026-05-10 |
| ADR-003 | **core** | pmo-platform | migrated | 2026-05-10 |
| ADR-004 | **core** | pmo-platform | migrated | 2026-05-10 |
| ADR-005 | release | pmo-platform | migrated | 2026-05-17 |
| ADR-006 | **core** | module-restructure | module-restructure | 2026-05-27 |
| ADR-007 | **core** | module-restructure | module-restructure | 2026-05-27 |
| ADR-008 | **core** | module-restructure | architectural intent; later implementation | 2026-05-27 |
| ADR-009 | **core** | module-restructure | architectural intent; later implementation | 2026-05-27 |

## Module-restructure ADR composition graph

```
ADR-006 (skill-to-module map)        ┐
        │                            │
        └──→ ADR-007 (core boundary) ┤
                │                    │
                ├──→ ADR-008 (deploy.sh array design)
                └──→ ADR-009 (rewrite-map CLI design)
```

ADR-006 establishes the 22-skill 3-module partition; ADR-007 extends to the non-skill content boundary (hooks, disciplines, schemas, standards, specs, tools, rules, governance, agents); ADR-008 + ADR-009 codify the architectural intent for the two tooling adaptations that consume the ADR-006 + ADR-007 decisions. ADR-003 + ADR-004 (foundational governance — see § Foundational ADRs in core below) predate the module split and are platform-wide cross-cutting decisions consumed by both the modular-monolith partition (ADR-006/007) and the cross-stage execution model.

## Module-restructure ADRs

### ADR-006 — Skill-to-module map

**Status:** Accepted (operator standing-GO 2026-05-27).
**Decision:** 22 skills partition as operations=12, release=6+1 canary, core=3.
**Reversibility:** MODERATE (re-classification involves cross-wave migration redo).
**File:** [ADR-006-skill-to-module-map.md](ADR-006-skill-to-module-map.md)

### ADR-007 — Core module boundary lock-in

**Status:** Accepted.
**Decision:** File-placement boundary locked for hooks (10), allowlists (14), disciplines (21), schemas (15 + 1 to operations), standards (34 core / 11 release), specs (12 core / 9 release), tools (4 core / 9 release), roadmaps (6/1/1), rules (7/1), governance (OPERATIONS + README to core; RELEASE_PROTOCOL to release; RELEASE_LOG to operator-instance), and agent definitions (8 to release).
**Reversibility:** MODERATE.
**Amended in part:** the "roadmaps (6/1/1)" clause is superseded by ADR-012 — roadmap instances de-scoped to operator-local authoring.
**File:** [ADR-007-core-module-boundary.md](ADR-007-core-module-boundary.md)

### ADR-008 — deploy.sh per-module array design

**Status:** Accepted as architectural intent; implementation followed.
**Decision:** Per-module arrays (OPERATIONS_SKILLS / RELEASE_SKILLS / CORE_SKILLS / CANARY_SKILLS / HARNESS_LIST); empty-array guard at every iteration site under `set -euo pipefail`; `resolve_skill_module()` helper with `die`-on-miss.
**Reversibility:** CHEAP.
**File:** [ADR-008-deploy-sh-per-module-array-design.md](ADR-008-deploy-sh-per-module-array-design.md)

### ADR-009 — Rewrite-map CLI design

**Status:** Accepted as architectural intent; implementation followed.
**Decision:** `check-doc-links.py` extended with `--from-path X --to-path Y` two-flag CLI; V1/V2 prefix split; EMIT-ONLY enforced via Fixture 6 mtime/content-hash assertion; asymmetric-flag error emits dual stderr/stdout; asymmetry warning when from/to segment counts differ.
**Reversibility:** CHEAP.
**File:** [ADR-009-rewrite-map-cli-design.md](ADR-009-rewrite-map-cli-design.md)

### ADR-012 — Roadmap-instance de-scope (amends ADR-006 + ADR-007)

**Status:** Accepted (operator directive 2026-06-02).
**Decision:** Initiative-roadmap *instances* de-scoped from the tracked tree to operator-local authoring (`<OPERATOR_INSTANCE_ROADMAPS_PATH>`); the roadmap *framework* is retained as the reusable convention; the 4 in-repo enforcement surfaces (deploy.sh Check 24, gate-criteria-spec G3-13, Stage 13 forcing-function, Stage 5 cohesion-check) are dropped. Amends the roadmap-placement clauses of ADR-006/007 — all non-roadmap decisions stand.
**Reversibility:** MODERATE.
**File:** [ADR-012-roadmap-instance-descope.md](ADR-012-roadmap-instance-descope.md)

### ADR-013 — detect_install_path session-resolution policy + COWORK_AVAILABLE seam

**Status:** Accepted (Stage 5 Collective Review scope-lock 2026-06-03).
**Decision:** Resolve the Cowork install path via a deterministic ladder (operator.toml `[paths].cowork_install_path` base → single candidate → fingerprint + skill-count → logged mtime last resort → structured terminal), demoting mtime from primary signal to logged last resort; remove the hardcoded fallback session UUID (the last literal UUID in the tree) in favor of the structured terminal; re-point Check 8 to validate the detected path against the configured base (config-absent → SKIP); and introduce a module-level `COWORK_AVAILABLE` flag so `cmd_deploy` warns and continues to the unconditional user-local `~/.claude/skills` mirror when no Cowork session resolves, instead of hard-failing. Separates *resolution* (which path, or none) from *the deploy command's response to none*.
**Reversibility:** CHEAP.
**File:** [ADR-013-detect-install-path-session-resolution.md](ADR-013-detect-install-path-session-resolution.md)

### ADR-014 — Two-hash separation for managed-section tamper detection

**Status:** Accepted (Stage 5 Collective Review scope-lock 2026-06-03).
**Decision:** Add a second MANAGED-fence marker `installed_sha` = SHA-256 of the post-substitution installed managed body — the tamper anchor — alongside the existing `managed_sha` (source-template hash, the regeneration trigger). `update.sh` re-hashes the live managed body each run and compares to the stored `installed_sha`; on mismatch it backs the file up to `~/Claude/.backup-tampered-<ts>/` and force-regenerates (independently of the source-SHA skip). The hash byte-domain is single-sourced via `compose.py`'s `_extract_managed_body` (shared by the writer and a new `compose.py installed-sha` subcommand) so writer/reader cannot drift. Comparing the post-substitution anchor (not the source-template hash) is what prevents a false-positive storm on every token-bearing allowlist. Missing `installed_sha` ⇒ "unknown, not tampered" (self-healing back-compat; back-filled on next regen / `--force-regen`). Reconciles the prior §2.4 ⇄ §2.5/§3.2 spec contradiction. Closes the release's R-SEC managed-section tamper gap.
**Reversibility:** CHEAP.
**File:** [ADR-014-managed-section-two-hash-tamper-detection.md](ADR-014-managed-section-two-hash-tamper-detection.md)

## Foundational ADRs in core (migrated from pmo-platform/governance/adr/)

### ADR-003 — Operating Model Composition

**Status:** Accepted (operator decision; migrated to core/ADRs/ on 2026-05-27).
**Decision:** Three foundational design choices for `operating-model.md` — (1) declared-primary-with-secondaries cardinality model for stage-to-skill mapping; (2) cite-not-duplicate citation discipline; (3) cross-reference pattern with the function-spine companion document (ADR-004). Cross-cutting governance — consumed platform-wide by the skill-build wave.
**Reversibility:** MODERATE.
**File:** [ADR-003-operating-model-composition.md](ADR-003-operating-model-composition.md)

### ADR-004 — Five-Function Spine and Cross-Cutting Process Flows

**Status:** Accepted (operator decision; migrated to core/ADRs/ on 2026-05-27).
**Decision:** Universal PMBOK Process Groups (Initiating / Planning / Executing / Monitoring & Controlling / Closing) decomposition; 13×3 archetype × stage variants matrix (applies to ALL delivery approaches, not release-only); 10-flow cross-cutting taxonomy. Cross-cutting methodology + execution-framework — consumed platform-wide.
**Reversibility:** MODERATE.
**File:** [ADR-004-five-function-spine.md](ADR-004-five-function-spine.md)

**Note:** ADR-001 / ADR-002 / ADR-005 are release-scope decisions migrated to [`../../release/ADRs/`](../../release/ADRs/) — release-pipeline-specific (Cross-PR Overlap Audit baseline policy, Modular Pipeline Stages Split, Append-pattern aware contention scoring).

## Authoring new ADRs

New ADRs go to the ADRs/ subdirectory of the module that authored the decision:

- Cross-module / platform-architecture decision → `core/ADRs/`
- Operations-specific decision (PMO workflow, project artifact) → `operations/ADRs/`
- Release-specific decision (pipeline mechanic, release-process discipline) → `release/ADRs/`

Decisions affecting multiple modules but rooted in core go to `core/ADRs/` with cross-references from the consumer modules.

## Status enum

ADR `status:` follows the [Nygard convention](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

| Status | Meaning |
|---|---|
| Proposed | Decision drafted, not yet operator-ratified |
| Accepted | Operator-ratified at Collective Review or equivalent gate |
| Deprecated | Superseded by a later ADR; remains for audit trail |
| Superseded | Replaced; cite the superseding ADR in `## Status` block |

## Reversibility tier

ADR `Reversibility:` follows [reversibility-protocol.md](../specs/reversibility-protocol.md):

| Tier | Meaning |
|---|---|
| CHEAP | Undo in hours (e.g., CLI flag addition) |
| MODERATE | Undo in days, minor data loss (e.g., file re-classification) |
| EXPENSIVE | Undo in weeks, stakeholder impact (e.g., module renaming post-public-flip) |
| IRREVERSIBLE | Cannot undo (e.g., GitHub-published release with breaking semantics) |
