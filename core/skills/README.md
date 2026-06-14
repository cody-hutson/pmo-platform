# core/skills/

**Purpose:** Source-of-truth skill definitions for the **universal-discipline** subset of the PMO Agent Suite — skills consumed across the platform regardless of operations-vs-release surface (cross-cutting authoring + audit + prompt-engineering capability). Each skill is a `SKILL.md` plus optional `references/`, `evals/`, and supplementary content.
**Organization:** One subfolder per skill. Roster source-of-truth is `core/deploy/deploy.sh` the per-module arrays (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS) + `SUPPLEMENTARY_SKILLS` (per ADR-04); `deploy.sh --check` Check 5 asserts roster ↔ directory equivalence.
**Governance:** [../rules/skill-deployment.md](../rules/skill-deployment.md), [../standards/canonical-skill-structure.md](../standards/canonical-skill-structure.md), [../standards/version-field-semantics.md](../standards/version-field-semantics.md).
**Layer:** 1 (Engineering, git-tracked)
**Sibling catalogs:** [`../../operations/skills/README.md`](../../operations/skills/README.md) (operations skills), [`../../release/skills/README.md`](../../release/skills/README.md) (release-pipeline skills).

> This index enumerates the universal-discipline roster; it does **not** hardcode a skill count. The count is asserted by `deploy.sh --check` Check 5 against the `deploy.sh` arrays (the parameterized source of truth). Regenerate this table from `deploy.sh` on roster change.

## Index — universal-discipline skills

| Skill | One-line | Class |
|---|---|---|
| `eval-writer` | Authors rigorous eval suites for AI agents, skills, and LLM systems | deployed |
| `pmo-qa-auditor` | Reviews skill outputs against the principal-contributor standard | deployed |
| `prompt-builder` | Builds/improves prompts (Claude, SKILL.md, agent/system) | deployed + supplementary (full-tree) |

## Placement rationale

These three skills land at `core/skills/` (not `operations/skills/` or `release/skills/`) because their domains of consumption are universal across the platform:

- **`eval-writer`** — authors evals for any AI agent, skill, or LLM system; consumers span operations skills, release-pipeline skills, and any future Claude-adjacent build surface.
- **`pmo-qa-auditor`** — review-class skill applied to skill outputs from any class (operations OR release). Per Stage 7 Dev Testing + Stage 8 QA contracts at `release/governance/release-process.md`, this auditor evaluates all skill outputs, not only release-pipeline-class skill outputs.
- **`prompt-builder`** — improves prompts of any class (slash commands, SKILL.md instances, agent system prompts), spanning workspace-global infrastructure.

The placement reflects the universal-vs-release-pipeline-split rule (see [../standards/universal-vs-release-pipeline-split-rule.md](../standards/universal-vs-release-pipeline-split-rule.md)).
