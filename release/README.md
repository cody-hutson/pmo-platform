# Release Module

The Release module hosts release-pipeline / SDLC management capability — the skills, references, schemas, and tools a platform builder uses to plan, build, deploy, and close software releases. Consumer audience: platform builder (engineering, release manager, DevOps).

**Module version:** 0.1.0
**Current state:** pre-public-flip.

## Public API

<!-- module-apis.md: this Public API section is enumerated at docs/module-apis.md § Release module public API. On change, update both. -->

Skills exposed to other modules and to consumers:

| Skill | Mode | Description |
|---|---|---|
| `release-planner` | invocation | Plans the release lifecycle (backlog analysis, bundling, dry-run) |
| `release-executor` | invocation | Executes approved release plans (deploy, verify, rollback, close) |
| `build-reviewer` | invocation | Production-readiness review of governed document packs |
| `implementation-planner` | invocation | Converts build-reviewer findings into remediation plans |
| `pmo-skill-editor` | invocation | Edit/audit/regression-test any skill |
| `pmo-skill-refiner` | invocation | Create/refine PMO-platform skills (wraps Anthropic scaffolder) |

Canary (not part of Public API, source-only): `pmo-skill-refiner-selftest-canary`.

**Public references:** `release/RELEASE_PROTOCOL.md`, `release/references/pipeline/stage-*.md` (13 stage shards), `release/references/how-to/hub-spoke-bridge.md`, `release/references/standards/*.md`, `release/references/protocols/*.md`, `release/references/specs/*.md`, `release/schemas/*`, `release/tools/*` (release engineering tools), `release/ADRs/*`.

**Public templates:** release plan template (under `release/references/templates/`), design review checklist, decision briefing template.

## Internal API

Files in the Release module that are NOT part of the public API and SHOULD NOT be referenced from other modules:

- `release/references/_internal/` — module-private working refs (when added).
- Per-skill `references/` subtrees — skill-internal.
- `release/tools/_internal/*.sh` — engineering-tool helpers not invocable from outside the module.

Initial: empty internal-API list. Cross-module audit may surface additions over time.

## Cross-Module Dependencies

The Release module DEPENDS ON `core/` ONLY.

Permitted cross-module references:
- `core/skills/prompt-builder` (skill authoring)
- `core/skills/pmo-qa-auditor` (gate audits — G4, G7)
- `core/skills/eval-writer` (eval-set authoring at Stage 7 DT)
- `core/disciplines/decision-discipline.md`
- `core/disciplines/discovery-discipline.md`
- `core/disciplines/review-discipline-principles.md`
- `core/hooks/*`
- `core/governance/CLAUDE.md`
- `core/schemas/*`
- `core/deploy/deploy.sh` + `core/deploy/tools/*`

PROHIBITED: any reference into `operations/`.

Compatible with: `core 0.X` (pre-1.0 contract).

## Versioning

| Bump | Trigger |
|---|---|
| MAJOR | Remove public skill; rename public reference; change pipeline-stage spec semantics |
| MINOR | Add new pipeline-stage spec; add new release tool; add new ADR; add new standard/protocol |
| PATCH | Internal refactor; clarifying language; spelling fix |

Pre-public-flip: module version advisory. Post-flip: load-bearing.

Changes recorded in the repository `CHANGELOG.md` prefixed by `(release)`.

## Cross-Module Audit

The architectural invariant is **0 code-import cycles** from `release/` into `operations/` or back into `core/` outside the declared Public API. Codified in [`../core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md).

Re-verify at any SHA by running [`../core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh). Output writes to `audit-output/` (gitignored) by default.

## Module contents

This module hosts the release skills — the canonical roster is the `RELEASE_SKILLS` array in [`core/deploy/deploy.sh`](../core/deploy/deploy.sh), Check 5-asserted against the on-disk `release/skills/` directories — plus the pipeline-stage shards under `release/references/pipeline/`, the hub-spoke bridge how-to, the release-relevant standards and protocols, the release schemas, the release-governance protocol (`release/governance/RELEASE_PROTOCOL.md`), the release tools, and the release-scope ADRs.

## Future-Extraction Readiness

This module is designed to be extractable to its own repo if needed in the future. Self-containment invariants:

1. All references resolve to `core/` (permitted) or within `release/` (intra-module). No `operations/` references.
2. Skill descriptions parameterize target repo path (don't hardcode `pmo-platform`).
3. Pipeline shards reference module-relative paths; tools accept target repo path as parameter.

Cross-module audit at [`../core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh) verifies these invariants. Plug-and-play discipline: the release module accepts any target repo (tools accept the target repo path as a parameter).
