# release/skills/

**Purpose:** Source-of-truth skill definitions for the **release-pipeline-class** subset of the PMO Agent Suite — skills consumed by the 13-stage release pipeline + skill authoring/curation tooling. Each skill is a `SKILL.md` plus optional `references/`, `evals/`, and supplementary content.
**Organization:** One subfolder per skill. Roster source-of-truth is `core/deploy/deploy.sh` `SKILL_LIST` + `SUPPLEMENTARY_SKILLS` + the source-only `-selftest-canary` (per ADR-04); `deploy.sh --check` Check 5 asserts roster ↔ directory equivalence.
**Governance:** [../../core/rules/skill-deployment.md](../../core/rules/skill-deployment.md), [../../core/standards/canonical-skill-structure.md](../../core/standards/canonical-skill-structure.md), [../../core/standards/version-field-semantics.md](../../core/standards/version-field-semantics.md).
**Layer:** 1 (Engineering, git-tracked)
**Sibling catalogs:** [`../../operations/skills/README.md`](../../operations/skills/README.md) (operations skills), [`../../core/skills/README.md`](../../core/skills/README.md) (universal-discipline skills).

> This index enumerates the release-pipeline-class roster; it does **not** hardcode a skill count. The count is asserted by `deploy.sh --check` Check 5 against the `deploy.sh` arrays (the parameterized source of truth). `version:` values are each skill's `SKILL.md` frontmatter per `version-field-semantics.md`. Regenerate this table from `deploy.sh` + frontmatter on roster change.

## Index — release-pipeline-class skills

| Skill | `version:` | One-line | Class |
|---|---|---|---|
| `build-reviewer` | v10.2 | Final production-readiness review of governed document packs → findings register | deployed |
| `implementation-planner` | v10.2 | build-reviewer findings → sequenced minimal-change remediation plans | deployed |
| `pmo-skill-editor` | v10.2 | Edit, audit, and regression-test any skill in the suite | deployed |
| `pmo-skill-refiner` | v11.16 | Creates/refines PMO skills (wraps Anthropic scaffolder + PMO injection) | deployed + supplementary (full-tree) |
| `release-executor` | v10.2 | Executes approved release plans (snapshot, apply, close, verify, rollback) | deployed |
| `release-planner` | v12.09 | Plans the release lifecycle (backlog analysis, bundling, dry run) | deployed |
| `pmo-skill-refiner-selftest-canary` | `-canary` | Source-only eval canary (ADR-04); never deployed | canary (source-only) |
