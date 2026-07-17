---
title: Core Module
purpose: Module README for the Core module — the shared kernel consumed by both operations and release; enumerates the module's public API of skills, disciplines, schemas, deploy infrastructure, and ADRs.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Core Module

The Core module hosts the shared kernel — capability consumed by BOTH operations AND release. Includes shared skills, security hooks, disciplines (decision/discovery/review), schemas, configuration templates, deploy infrastructure, and platform-architecture ADRs. Consumer audience: BOTH PMO practitioners AND platform builders.

**Module version:** 0.1.0
**Current state:** pre-public-flip.

## Public API

<!-- module-apis.md: this Public API section is enumerated at docs/module-apis.md § Core module public API. On change, update both. -->

Skills exposed to BOTH consumer modules:

| Skill | Mode | Description |
|---|---|---|
| `prompt-builder` | invocation | Builds/improves prompts of every kind (Claude prompts, SKILL.md, agent prompts) |
| `pmo-qa-auditor` | invocation | Reviews skill outputs against principal-contributor standard |
| `eval-writer` | invocation | Authors rigorous eval suites for AI agents, skills, LLM systems |
| `pmo-skill-router` | invocation | Capstone suite router — classifies a role-shaped request against the `core/skills/registry.md` registry and routes it to the correct role-Specialist |

**Public references:**
- `core/CLAUDE.md.template` — depersonalized workspace-root template
- `core/config/*.template` — settings templates
- `core/hooks/*.sh` + `core/hooks/.mode` — security hook layer
- `core/disciplines/decision-discipline.md` — Decision Discipline Framework
- `core/disciplines/discovery-discipline.md` — Discovery Discipline Framework
- `core/disciplines/review-discipline-principles.md` — Review Discipline Principles
- `core/disciplines/diataxis-framework.md` — Diátaxis documentation framework (non-binding conceptual reference)
- `core/schemas/*.md` — shared schemas (gate-evaluation-spec, etc.)
- `core/governance/*` — cross-module governance (knowledge-architecture.md, label-taxonomy.md, etc.)
- `core/deploy/deploy.sh` + `core/deploy/tools/*` — deploy infrastructure
- `core/ADRs/*` — platform-architecture ADRs

**Public templates:** `core/CLAUDE.md.template`, settings templates, hook-config templates.

## Internal API

Files in the Core module that are NOT part of the public API and SHOULD NOT be referenced from other modules:

- `core/_internal/` — module-private working refs (when added).
- `core/deploy/_internal/*.sh` — deploy-script internal helpers.

Initial: empty internal-API list. Cross-module audit may surface additions over time.

## Cross-Module Dependencies

**Core depends on NO other module.** This is the architectural invariant.

PROHIBITED references:
- Any path under `operations/`
- Any path under `release/`

If a core file needs operations or release content, it is mis-classified. The cross-module audit at [`deploy/tools/cross-module-audit.sh`](deploy/tools/cross-module-audit.sh) grep-checks `core/` for `operations/` and `release/` references and fails on any match.

Permitted: external dependencies (published packages, OS tools, github.com via `gh` CLI, etc.).

## Versioning

| Bump | Trigger |
|---|---|
| MAJOR | Remove `prompt-builder`/`pmo-qa-auditor`/`eval-writer`; rename `CLAUDE.md.template`; change hook layer API; remove a discipline doc |
| MINOR | Add new shared skill; add new discipline doc; add new shared schema |
| PATCH | Internal refactor; clarifying language; spelling fix |

Pre-public-flip: module version advisory. Post-flip: load-bearing.

Core MAJOR bumps cascade — operations and release MUST re-test against the new major. Pre-1.0 (current): operations and release pin to `core 0.X`.

Changes recorded in the repository `CHANGELOG.md` prefixed by `(core)`.

## Cross-Module Audit

The architectural invariant is **0 code-import cycles** from `core/` to `operations/` or `release/`, codified in [`ADRs/ADR-007-core-module-boundary.md`](ADRs/ADR-007-core-module-boundary.md).

Documentary markdown-doc-link and narrative-mention references from `core/{disciplines, schemas, standards, ADRs, rules, governance, README.md}` to `operations/*` and `release/*` are accepted cohesion per the ADR-007 v2 carry-forward scope. Code-import cycles remain BLOCKER.

Re-verify at any SHA by running [`deploy/tools/cross-module-audit.sh`](deploy/tools/cross-module-audit.sh). Output writes to `audit-output/` (gitignored) by default.

## Module contents

This module hosts the shared kernel: the shared skills (`prompt-builder`, `pmo-qa-auditor`, `eval-writer`, and the `pmo-skill-router` suite router), the logical skill registry at [`skills/registry.md`](skills/registry.md) (the single classification source the router reads to route a role-shaped request, per [`ADRs/ADR-035-registry-as-classification-source.md`](ADRs/ADR-035-registry-as-classification-source.md)), the security hook layer under `core/hooks/`, the universal disciplines (decision / discovery / review), the shared schemas, the shared standards (depersonalization-spec, knowledge-architecture, label-taxonomy, etc.), the depersonalized `CLAUDE.md.template`, the deploy infrastructure (`deploy/deploy.sh` + `deploy/tools/`), and the cross-cutting platform ADRs in [`ADRs/`](ADRs/). Release-scope ADRs live separately in [`../release/ADRs/`](../release/ADRs/).

## Future-Extraction Readiness

This module is the **most extractable** — it has zero internal dependencies on other modules and is consumed broadly. Self-containment invariants:

1. NO references to `operations/` or `release/`.
2. No operator-instance identifiers in template content.
3. Documentation references use module-relative paths.

If core extracts to its own repo, operations and release become external consumers — versioning becomes load-bearing immediately.
