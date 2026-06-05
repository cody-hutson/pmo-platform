# Operations Module

The Operations module hosts PMO-operations capability — the skills, references, and templates a PMO practitioner uses to manage project work day-to-day. Consumer audience: PMO practitioner (Senior Program Manager, Technical Program Manager, PMO Director).

**Module version:** 0.1.0
**Current state:** pre-public-flip.

## Public API

<!-- module-apis.md: this Public API section is enumerated at docs/module-apis.md § Operations module public API. On change, update both. -->

Skills exposed to other modules and to consumers:

| Skill | Mode | Description |
|---|---|---|
| `artifact-generator` | invocation | Produces PMO project artifacts; stages in `08-Generated/` |
| `change-management` | invocation | Plans and tracks organizational change for go-lives |
| `comms-writer` | invocation | Stakeholder communications across email/Teams/Confluence |
| `daily-status` | invocation | AM/PM Teams-ready daily status updates |
| `delivery-engine` | invocation | Backlog → release-readiness; DoR/DoD gates; sprint planning |
| `file-router` | invocation | Classifies and routes incoming files in PMO workspace |
| `pmo-process-designer` | invocation | Converts business context into structured requirements/processes |
| `pmo-technical-analyst` | invocation | Reviews technical artifacts (FDDs, integration specs) with TPM judgment |
| `ppm-agent` | invocation | Strategic PMO brain — pushes actionable items to resolution |
| `project-initiator` | invocation | Project lifecycle scaffolding (init + closure) |
| `tracker-manager` | invocation | Generic update engine for operational trackers |
| `weekly-status-rollup` | invocation | Weekly executive status across active projects |

**Public references:**
- `operations/OPERATIONS.md` (module governance)
- `operations/references/*.md` (operations-private explanation docs)
- `operations/templates/` (canonical-template registry — RAID Log, Project Plan, Test Plan, FRD, FDD, Comms Plan, Training Plan, PMO_Platform_Template, hypercare-plan, raid-log-template, communications-tracker-template, open-meetings-tracker-template, key-terms-glossary-template, spm-bridge-template, milestone-tracker-template, sprint-tracker-template, transcript-register-template, daily-status-log-template, daily-status-update-framework-template, executive-status-report-prompt-template, raid-templates)
- `operations/skills/{<skill>}/references/` (skill-internal template references — including `requirements-template.md`, `project-md-template.md`, `raid-templates.md` consumed by the 5-Layer Template Architecture)

The expanded enumeration is operator-ratified at Wave F-2 Pattern-P2/P3 per-edit plans (Stage 5 spec Decision Table Rule 4 — single-consumer in-source → move to Public API). Adding `operations/templates/` + `operations/skills/<skill>/references/` to Public API legitimizes cross-module documentary references from release-side template architecture docs (`release/skills/{release-planner, pmo-skill-refiner}/references/template-{taxonomy, protocol, storage}.md`) as `via-public-api`.

## Internal API

Files in the Operations module that are NOT part of the public API and SHOULD NOT be referenced from other modules:

- `operations/references/_internal/` — module-private working refs (when added).
- Per-skill `references/` subtrees — skill-internal; consumed only by that skill.

Initial state: empty internal-API list (all references currently public). Cross-module audit may surface additions over time.

## Cross-Module Dependencies

The Operations module DEPENDS ON `core/` ONLY.

Permitted cross-module references:
- `core/skills/prompt-builder` (skill authoring)
- `core/skills/pmo-qa-auditor` (output audits)
- `core/skills/eval-writer` (eval authoring)
- `core/disciplines/decision-discipline.md`
- `core/disciplines/discovery-discipline.md`
- `core/disciplines/review-discipline-principles.md`
- `core/hooks/*`
- `core/governance/CLAUDE.md`
- `core/schemas/*`
- `core/deploy/deploy.sh`

PROHIBITED: any reference into `release/`.

Compatible with: `core 0.X` (pre-1.0 contract).

## Versioning

| Bump | Trigger |
|---|---|
| MAJOR | Remove public skill; rename public reference; change skill public-API signature |
| MINOR | Add new public skill; add new public reference; add new template |
| PATCH | Internal refactor; spelling fix; clarifying language |

Pre-public-flip: module version is advisory. Post-flip: module version is load-bearing — cross-module consumers MAY pin to a major version.

Changes recorded in the repository `CHANGELOG.md` prefixed by `(operations)`.

## Cross-Module Audit

The architectural invariant is **0 code-import cycles** from `operations/` into `release/` or back into `core/` outside the declared Public API. Codified in [`../core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md).

Re-verify at any SHA by running [`../core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh). Output writes to `audit-output/` (gitignored) by default.

## Module contents

This module hosts the operations skills (`artifact-generator`, `change-management`, `comms-writer`, `daily-status`, `delivery-engine`, `file-router`, `pmo-process-designer`, `pmo-technical-analyst`, `ppm-agent`, `project-initiator`, `tracker-manager`, `weekly-status-rollup`) and the operations governance file (`operations/OPERATIONS.md`).

## Future-Extraction Readiness

This module is designed to be extractable to its own repo if needed in the future. Self-containment invariants:

1. All references resolve to `core/` (permitted) or within `operations/` (intra-module). No `release/` references.
2. Templates carry no operator-instance identifiers.
3. Documentation references use module-relative paths or `core/`-routed paths.

Cross-module audit at [`../core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh) verifies these invariants.
