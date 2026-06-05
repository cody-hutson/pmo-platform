# operations/skills/

**Purpose:** Source-of-truth skill definitions for the **operations-class** subset of the PMO Agent Suite — skills consumed by PMO operations (portfolio / project / cross-project work). Each skill is a `SKILL.md` plus optional `references/`, `evals/`, and supplementary content.
**Organization:** One subfolder per skill. Roster source-of-truth is `core/deploy/deploy.sh` `SKILL_LIST` + `SUPPLEMENTARY_SKILLS` (per ADR-04); `deploy.sh --check` Check 5 asserts roster ↔ directory equivalence.
**Governance:** [../../core/rules/skill-deployment.md](../../core/rules/skill-deployment.md), [../../core/standards/canonical-skill-structure.md](../../core/standards/canonical-skill-structure.md), [../../core/standards/version-field-semantics.md](../../core/standards/version-field-semantics.md).
**Layer:** 1 (Engineering, git-tracked)
**Sibling catalogs:** [`../../release/skills/README.md`](../../release/skills/README.md) (release-pipeline skills), [`../../core/skills/README.md`](../../core/skills/README.md) (universal-discipline skills).

> This index enumerates the operations-class roster; it does **not** hardcode a skill count. The count is asserted by `deploy.sh --check` Check 5 against the `deploy.sh` arrays (the parameterized source of truth). `version:` values are each skill's `SKILL.md` frontmatter per `version-field-semantics.md`. Regenerate this table from `deploy.sh` + frontmatter on roster change.

## Index — operations-class skills

| Skill | `version:` | One-line | Class |
|---|---|---|---|
| `artifact-generator` | v10.2 | Produces/updates project artifacts; stages output in 08-Generated/ for review | deployed |
| `change-management` | v10.2 | Plans/tracks organizational change for go-lives and system transitions | deployed |
| `comms-writer` | v10.2 | Audience-calibrated, ready-to-send stakeholder communications | deployed |
| `daily-status` | v10.2 | Teams-ready AM/PM daily status updates from trackers + transcripts | deployed |
| `delivery-engine` | v11.16 | Backlog health → release readiness; DoR/DoD quality gates | deployed |
| `file-router` | v11.04 | Classifies, routes, and triggers processing for new workspace files | deployed |
| `pmo-process-designer` | v11.16 | Business context → structured, traceable requirements + process docs | deployed |
| `pmo-technical-analyst` | v10.2 | Senior-TPM review of technical artifacts; surfaces non-obvious risk | deployed |
| `ppm-agent` | v10.2 | Strategic brain — reads any artifact, pushes actionable items to resolution | deployed |
| `project-initiator` | v11.16 | Full project lifecycle — scaffold new projects, close completed ones | deployed |
| `tracker-manager` | v10.2 | Generic update engine for operational trackers in 04-PMO-Operations/ | deployed |
| `weekly-status-rollup` | v10.2 | Weekly executive status roll-up across all active projects | deployed |

Cowork-provided proprietary skills (`docx`, `pdf`, `pptx`, `xlsx`, `schedule`) are managed by Anthropic and are **not** version-controlled here.
