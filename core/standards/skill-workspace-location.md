# Skill Workspace Location Convention

**Last Refreshed:** 2026-05-11

## §1 Purpose

Disambiguate two PMO-internal organizational conventions for skill-adjacent artifacts:

- **`release/skills/<skill>-workspace/iteration-N/`** — operational baselines (regression benchmarks, eval iterations) for permanent skills.
- **`pmo-platform/analysis/<audit-name>-YYYY-MM-DD/`** — read-once analysis artifacts (audits, reviews, gap analyses, one-time AC evidence).

Both are **PMO-only conventions that extend — but do not modify — the Anthropic `anthropic-skills:skill-creator` scaffolder output**. The Anthropic scaffolder operates on the skill directory at `skills/<skill>/` and remains the authority over its contents; PMO conventions govern the sibling/parallel surfaces (`skills/<skill>-workspace/`) and the parent `analysis/` directory.

**Reversibility tier:** MODERATE — Confidence: HIGH. Convention documentation is reversible via doc edit, but existing canonical references in 5+ files use `skills/<skill>-workspace/` already (`pmo-skill-refiner/SKILL.md`, `regression-protocol.md`, `eval-framework.md`, `regression-checks.md` entry format, `registry.md` refiner dependency-edge declaration). Reversal would require coordinated edits to those files.

## §2 Decision rule

Apply the criterion test for each candidate location. The two tests are mutually exclusive in normal use; when both seem to match, criterion priority resolves the case (read §3 boundary case treatment).

### Use `release/skills/<skill>-workspace/iteration-N/` when **ALL** of these hold:

1. The artifact is an **operational baseline** for a permanent skill — regression benchmark, eval iteration, before/after refinement comparison.
2. The artifact has a **succession lifecycle** — `iteration-1`, `iteration-2`, ... where each iteration potentially supersedes the prior.
3. The artifact is **scoped to a single skill** (not a cross-skill audit).

### Use `pmo-platform/analysis/<audit-name>-YYYY-MM-DD/` when **ANY** of these hold:

1. The artifact is **read-once** — won't be iterated; serves as a snapshot or evidence package.
2. The artifact spans **multiple skills** or **system-wide concerns** (audit, gap analysis, demonstration of a cross-skill workflow).
3. The artifact is **one-time AC evidence** for an issue — e.g., a demo proving an AC at the time of PR merge, where preserving it long-term is optional.

## §3 Boundary case treatment

The boundary case that motivated: **a one-time AC demonstration that produces iteration-1 evidence for a permanent skill**.

Resolution: route to `pmo-platform/analysis/<audit-name>-YYYY-MM-DD/` per `analysis/` criterion 3 (one-time AC evidence). The artifact is dated, read-once evidence for the PR — not the start of an operational succession.

**Transition rule:** When/if the skill subsequently acquires an operational baseline (first non-demo invocation that warrants regression tracking), THAT artifact lands at `release/skills/<skill>-workspace/iteration-1/` per `<skill>-workspace/` criteria 1-3. The transition is one-shot and forward-only — never migrate the original AC-demo evidence from `analysis/` to `<skill>-workspace/`; the AC-demo evidence remains in `analysis/` (or its preservation point in git history, if cleaned up by a subsequent chore).

**Source:** This was such a boundary case. The original demo evidence correctly landed in the dated analysis directory under `pmo-platform/analysis/` per criterion 3. The artifacts were subsequently removed by commit `6bc8517` on 2026-05-02 (superseded; preserved in PR  git history). The first operational baseline for the canary will land at `release/skills/pmo-skill-refiner-selftest-canary-workspace/iteration-1/benchmark.json` on first regression-warranting invocation, per this convention.

## §4 Anti-patterns

- **Do NOT mix the conventions in the same release branch for the same artifact.** Creating both `<skill>-workspace/iteration-1/` AND `analysis/<audit>-YYYY-MM-DD/iteration-1/` for the same evaluation run is a structural defect — pick one per the criterion test in §2.
- **Do NOT force one-time AC evidence into `<skill>-workspace/iteration-1/`.** The naming format `iteration-N` implies a succession lifecycle; using it for a single read-once artifact mis-shelves the artifact class and pollutes the operational baseline namespace.
- **Do NOT force operational iteration tracking into `analysis/<audit>-YYYY-MM-DD/`.** The `<audit>-YYYY-MM-DD/` naming format expects an audit identity and a date; operational benchmarks at iteration-N have neither (the unit is iteration number scoped to a skill, not a dated audit).
- **Do NOT cross-shelf cross-skill audits into `<skill>-workspace/`.** Audits and gap analyses typically span multiple skills (e.g., `skill-review-2026-04-18/` covered the suite); co-locating them with a single skill is structurally wrong.

## §5 Scope of authorship

This convention governs the sibling/parallel surfaces to `skills/<skill>/`, not the skill directory itself.

- **`skills/<skill>/`** — Anthropic `anthropic-skills:skill-creator` is the scaffolder of record. SKILL.md authoring, references/, and evals/ contents follow the Anthropic scaffolder's output schema. PMO governance layers on top (canonical-skill-structure.md, principal-standard-checklist.md, failure-mode-standard.md) but does not modify the directory shape Anthropic produces.
- **`skills/<skill>-workspace/`** — PMO-only convention. Anthropic does not scaffold this directory. Contents are operational evaluation data (benchmarks, run logs, comparison artifacts), not authoring surface. Workspace contents are **exempt from skill-authoring rules** that target `skills/<skill>/` (e.g., a hypothetical future Check 13 that scans for duplicate prose across `skills/<skill>/SKILL.md` files should not also scan `<skill>-workspace/` artifacts).
- **`pmo-platform/analysis/`** — PMO-only convention per `CLAUDE.md § Governance File Map`. Dated subfolders per audit; each subfolder's structure is audit-specific. Anthropic has no surface here.

## §6 Cross-references

- `release/skills/pmo-skill-refiner/SKILL.md` — source of the `skills/<skill>-workspace/` eval workspace pattern.
- `release/skills/pmo-skill-refiner/references/regression-protocol.md` — regression protocol declares `<skill>-workspace/iteration-N/` benchmark path.
- `release/skills/pmo-skill-refiner/references/eval-framework.md` — eval framework declares same.
- `release/references/specs/skill-suite-regression-checks.md` — entry format declares `release/skills/<skill>-workspace/iteration-<N>/benchmark.json` as the canonical regression iteration reference path.
- `core/skills/registry.md` — pmo-skill-refiner dependency-edge declaration; the refiner writes-to path includes `release/skills/<skill>-workspace/iteration-N/`.
- `CLAUDE.md § Governance File Map` — declares `pmo-platform/analysis/<audit-name>-YYYY-MM-DD/` for read-once engineering analysis artifacts.

## §7 Upstream compatibility

`anthropic-skills:skill-creator` scaffolds new skills and iterates existing skills via eval-driven loops. Schema review at 2026-05-11 (Stage 5 Solutioning) confirms: the scaffolder operates on the skill directory at `skills/<skill-name>/` only. No `*-workspace` sibling convention; no `analysis/` placement rule; no canary/demo subdirectory convention.

Both `skills/<skill>-workspace/` and `analysis/<audit-name>-YYYY-MM-DD/` operate outside the Anthropic scaffolder's defined surface — they govern artifacts the scaffolder does not produce. **No CONFLICT.** Both conventions are additive PMO-only extensions.
