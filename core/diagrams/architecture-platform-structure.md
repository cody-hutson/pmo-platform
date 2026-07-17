---
title: Architecture — Platform Structure
purpose: The centralized, canonical ASCII-tree map of the pmo-platform modular-monolith top-level structure, referenced from the architecture overview, operating model, and module READMEs.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Architecture — Platform Structure

**Flow class:** Architecture (per the design-artifact standard's 7-flow-type taxonomy — structural map of files, layers, and modules).
**Tool:** ASCII tree in a plain fenced code block (the architecture-class rendering tool — text-based, GitHub-native, agent-readable; proprietary and binary diagram formats are rejected for architecture artifacts).
**Subject:** The current modular-monolith top-level layout of the pmo-platform repository.
**Storage:** Centralized design artifact. This file is referenced from ≥3 parent docs (the architecture overview, the operating model, the README layout section, and the per-module READMEs), so it meets the centralization threshold and lives as a dedicated file under `core/diagrams/` rather than embedded in any single parent.
**Status:** Canonical. This artifact is the centralized, current-state structural map; it supersedes the older embedded tree that predates the modular-monolith restructure.

## Purpose

This artifact anchors the platform's current structural state in one place. It exists so a human reader can see how the repository is laid out without reading the source tree, and so an agent can hold a coherent mental model of module boundaries across handoffs and cross-skill work. It depicts **structure** (where things live and how the modules partition), not behavior (how the pipeline runs) — behavior lives in the disciplines and pipeline docs linked at the foot of this file.

## What this depicts

The repository is a **modular monolith**: one repository, three capability modules, each with a documented public API in its module README. The three modules are:

- **`core/`** — the shared kernel. Hosts the security hooks, the decision/discovery/review disciplines, the schemas and specs, the deploy infrastructure, and the shared skills consumed by both consumer modules. Anything `core/` exports is consumed by both `operations/` and `release/`, so changes to the shared surface get reviewed against both consumers.
- **`operations/`** — the PMO-operations capability module, used by PMO practitioners for day-to-day program work (daily status, RAID maintenance, communications, artifact generation, transcript routing, tracker upkeep).
- **`release/`** — the release-pipeline / SDLC-management module, used by platform builders to bundle backlog items into versioned releases, drive the 13-stage pipeline, execute deploys, and author release notes.

Modules talk only through declared public surfaces; internal references stay inside their owning module. Extraction-readiness is preserved — a module that proves genuinely independent can be lifted into its own repository without rewriting consumer references.

## Top-level structure

```
pmo-platform/                      ← modular-monolith repository root
├── core/                          ← SHARED KERNEL (consumed by operations + release)
│   ├── ADRs/                      ← Architecture Decision Records (monotonic NNN across the platform)
│   ├── config/                    ← operator-identity + token configuration
│   ├── deploy/                    ← deploy infrastructure (deploy.sh + tools/, e.g. corpus linters)
│   ├── disciplines/               ← cross-cutting disciplines (decision / discovery / review),
│   │                                 architecture-overview, operating-model, knowledge-architecture
│   ├── diagrams/                  ← centralized cross-cutting design artifacts (this file lives here)
│   ├── governance/                ← OPERATIONS.md + module README (core-owned governance)
│   ├── hooks/                     ← security + integrity PreToolUse hooks and their allowlists
│   ├── rules/                     ← Claude Code operating manual (git-workflow, release-process, …)
│   ├── schemas/                   ← stage-I/O contracts, gate-criteria, tracker schemas, …
│   ├── skills/                    ← shared skills (prompt-builder, eval-writer, pmo-qa-auditor)
│   ├── specs/                     ← reversibility, autonomy-tiers, failure-mode, ticket-IA, …
│   ├── standards/                 ← K1 codified standards (incl. the design-artifact standard)
│   ├── CLAUDE.md.template         ← token-resolved workspace-config seed
│   └── settings.json.template     ← token-resolved settings seed
│
├── operations/                    ← PMO OPERATIONS MODULE (PMO practitioners)
│   ├── skills/                    ← 13 operations skills (ppm-agent, daily-status, comms-writer,
│   │                                 delivery-engine, tracker-manager, artifact-generator, …)
│   ├── templates/                 ← project + tracker templates (RAID, PROJECT.md, status-log, …)
│   ├── OPERATIONS.md              ← operations-module governance
│   └── README.md                  ← operations module Public API
│
├── release/                       ← RELEASE PIPELINE MODULE (platform builders)
│   ├── ADRs/                      ← release-scope Architecture Decision Records
│   ├── governance/                ← release-process.md + RELEASE_PROTOCOL (release-module governance)
│   ├── references/                ← pipeline/ (13 stage definitions), standards/, specs/,
│   │                                 protocols/, how-to/, templates/
│   ├── releases/                  ← release corpus — plans/, notes/, RELEASE_LOG/INDEX/DIGEST, hub-state/
│   ├── skills/                    ← 6 release skills + 1 source-only self-test canary
│   │                                 (release-planner, release-executor, build-reviewer,
│   │                                 implementation-planner, pmo-skill-editor, pmo-skill-refiner)
│   ├── tools/                     ← release tooling (cleanup-orphan-state.sh, link/contention checks)
│   └── README.md                  ← release module Public API
│
├── docs/                          ← USER-FACING DOCUMENTATION
│   ├── INSTALL.md                 ← install procedure + prerequisites
│   ├── GETTING_STARTED.md         ← 5-minute first-task walkthrough
│   ├── FIRST_STEPS.md             ← "tried one skill" → running real work
│   ├── UPDATE.md                  ← version-update procedure (preserves operator additions)
│   ├── workspace-setup.md         ← architectural deep-dive (layout, tokens, hooks, deploy)
│   ├── module-apis.md             ← consolidated cross-module API reference
│   └── scripts/                   ← documentation support scripts
│
├── packages/                      ← .skill distribution artifacts (one per deployed skill)
│
├── .github/                       ← CI workflows (depersonalization, issue-ref, dead-file,
│                                     reference-durability, secret-scanning, SAST, CodeQL)
├── install.sh                     ← idempotent fresh-clone bootstrap
├── update.sh                      ← version-update entry point
├── CHANGELOG.md                   ← Keep a Changelog 1.1.0 format
├── LICENSE                        ← Business Source License 1.1
├── SECURITY.md                    ← security policy + contact
├── CONTRIBUTING.md                ← contribution model
├── README.md                      ← repository overview + quick install
└── .version                       ← current platform version marker
```

## Module-partition summary

| Module | Role | Consumer audience | Deployed skills |
|---|---|---|---|
| `core/` | Shared kernel — hooks, disciplines, schemas, specs, standards, deploy infra, shared skills | Both (operations + release) | 3 |
| `operations/` | PMO-operations capability | PMO practitioners | 13 |
| `release/` | Release-pipeline / SDLC management | Platform builders | 6 (+1 source-only canary) |

The skill partition (operations = 13, release = 6 + 1 canary, core = 3) is the locked skill-to-module map. The kernel's three shared skills (`prompt-builder`, `eval-writer`, `pmo-qa-auditor`) are the ones invoked from both consumer modules; everything else lives in the module whose capability it serves.

## How structure maps to behavior

This artifact is the structural anchor. The behaviors that run on top of this structure are documented elsewhere and linked below:

- The cross-cutting **disciplines** (decision, discovery, review) are small reference documents in `core/disciplines/` that operationalize how the platform treats tier classification, premise interrogation, and post-artifact verification. Their structural separation from any one skill is what keeps them composable across both consumer modules.
- The **13-stage release pipeline** (intake → triage → bundle → planning → solutioning → engineering → dev-testing → QA → plan-review → dry-run → snapshot → execute → close) is defined stage-by-stage under `release/references/pipeline/`, with the operating rules in `release/governance/`.
- The **deploy bridge** (`core/deploy/deploy.sh`) is what propagates skill changes from the tracked tree to the runtime skills path.

## Maintenance + refresh

This artifact is current-only: a single canonical version lives here, and git history is the version database (`git log --follow` on this path retrieves prior states). When a future release materially changes the top-level structure — adds or removes a module, relocates a kernel subtree, or changes the module partition — that release refreshes this artifact as part of its close-out, and the close-out gate verifies the refresh occurred. Path-string and structural drift in this file is surfaced by the deploy-time and CI link/integrity scans.

## Related References

This block carries the bidirectional cross-reference contract: each source doc this artifact depicts links back to this file from its own Related References section.

- [`core/disciplines/architecture-overview.md`](../disciplines/architecture-overview.md) — the prose single-source-of-truth for how the platform works (module isolation, deployment model, governance tiers). This artifact is the centralized structural tree that overview narrates; the overview reciprocates with a link here.
- [`core/disciplines/operating-model.md`](../disciplines/operating-model.md) — skill ownership, governance composition, and the per-stage execution blueprint that runs on top of this structure. Reciprocates with a link here.
- [`README.md`](../../README.md) — the repository overview, whose "Top-level layout" and "Architecture" sections present the same modular-monolith structure for a first-time reader. This artifact is the detailed, agent-maintained expansion of that layout.
- [`operations/README.md`](../../operations/README.md) — the operations-module Public API (the 13-skill operations roster this tree summarizes).
- [`release/README.md`](../../release/README.md) — the release-module Public API (the release-skill roster and pipeline surface this tree summarizes).
- [`core/README.md`](../README.md) — the kernel-module Public API (the shared hooks, disciplines, schemas, and 3 shared skills this tree summarizes).
- [`core/standards/design-artifact-standard.md`](../standards/design-artifact-standard.md) — the governing standard under which this artifact is produced, stored (`core/diagrams/`), named, and refreshed.
