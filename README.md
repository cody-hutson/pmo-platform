# pmo-platform

> A PMO platform with composable modules — operations, release, and core — designed to run with [Claude Code](https://claude.com/claude-code) (the CLI or the Desktop app).

## What is it

pmo-platform is a modular-monolith codebase for program-management and release-pipeline work. Three modules cover distinct capability surfaces and serve two consumer audiences:

- **PMO practitioners** (Senior Program Managers, Technical Program Managers, PMO Directors) use the **operations** module for day-to-day program work — daily status updates, RAID Log maintenance, stakeholder communications, project artifact generation, transcript routing, and tracker upkeep.
- **Platform builders** (engineers, release managers, DevOps) use the **release** module for software-delivery management — bundling backlog items into versioned releases, driving the 13-stage pipeline from intake through close, executing deploys, and authoring release notes.

A shared **core** module hosts the security hooks, decision/discovery/review disciplines, schemas, deploy infrastructure, and the shared skills (`prompt-builder`, `eval-writer`, `pmo-qa-auditor`) consumed by both consumer modules.

Each module is independently consumable. A PMO practitioner can install the platform and use only the operations module; a platform-builder team can drive releases against any tracked repository using only the release module. Composing the two modules is also supported — the release module can ship releases for the operations module (and for itself).

## Quick install

**Requirements:** [Claude Code](https://claude.com/claude-code) — the CLI *or* the Desktop app UI — plus macOS 12+, `git`, and `python3`. Three commands install pmo-platform on a fresh machine:

```bash
git clone https://github.com/cody-hutson/pmo-platform.git ~/Claude/pmo-platform
cd ~/Claude/pmo-platform
./install.sh
```

`./install.sh` bootstraps the workspace layout, resolves the operator-identity tokens, installs the core security hooks, lays down composition-surface seed files with marker fences (so future updates preserve any custom additions), and deploys all platform skills to the runtime path Claude Code expects. It is idempotent — running it again on an existing workspace updates rather than overwrites.

For prerequisites, the full step-by-step procedure, and troubleshooting, see [docs/INSTALL.md](docs/INSTALL.md). For the version-update procedure that preserves operator additions, see [docs/UPDATE.md](docs/UPDATE.md).

## Getting started

After install, take the 5-minute taste: the first-task walkthrough at [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) exercises one real skill end-to-end — invoke it, read the output, change your workspace identity, and re-invoke to watch context flow through.

For the whole-journey map — the ordered clone→working-install arc and where each host choice (repo, ticketing, KB, AI tool) plugs in — see [docs/ONBOARDING_JOURNEY.md](docs/ONBOARDING_JOURNEY.md).

Then go further with **[docs/FIRST_STEPS.md](docs/FIRST_STEPS.md)**, which takes you from "I tried one skill" to running real work:

1. **Explore** — the fastest way to learn the platform: open Claude Code in the repo and play Q&A with it ("explain the 13-stage pipeline", "what's a hub vs a spoke?"). The repo documents itself.
2. **Orient** — the one mental model everything runs on: a typed work item → Triage → a versioned Milestone → a *hub* session that spawns a *spoke* per pipeline stage → close.
3. **Pick your track:**
   - **PMO practitioner** → configure your first project (`/project-initiator`, `PROJECT.md`, `delivery_approach`) and use the daily [operations](operations/README.md) skills.
   - **Platform builder** → hook up your GitHub repo (issues, a Milestone, the project board), then drive a release with the [release](release/README.md) module's hub.

FIRST_STEPS.md also covers the conventions worth knowing up front — governed-vs-ad-hoc changes, "recommend-then-you-decide" autonomy, evidence labels, and how to read a Decision Briefing.

After that, the module READMEs cover each module's full skill roster.

## Configuration

Platform behavior is configurable from one place. Every field — what it does, its default, and where to set it — is in the [configuration catalog](docs/platform-config-reference.md). Two surfaces hold your choices: `operator.toml` (environment + identity + host adapters — repo, ticketing, KB, AI tool) and `platform-config.toml` (tunable behavior — bundling, release-class default, calibration). Both ship as templates `./install.sh` lays down; values resolve most-specific-wins (global default → portfolio → program → project → individual). Setting a value for your own scope is a local edit; changing a shipped default is a governed change. See the **Platform-Config Resolution Protocol** in [OPERATIONS.md](core/governance/OPERATIONS.md) for precedence + update rules.

## Module overview

| Module | Role | More |
|---|---|---|
| [`operations/`](operations/README.md) | PMO operations capability — the skill suite for PMO practitioners | [Module README](operations/README.md) |
| [`release/`](release/README.md) | Release pipeline / SDLC management — the skill suite for platform builders | [Module README](release/README.md) |
| [`core/`](core/README.md) | Shared kernel — hooks, schemas, shared skills, disciplines, deploy infrastructure | [Module README](core/README.md) |
| [`docs/`](docs/) | User-facing documentation — install, getting started, workspace setup, module APIs | [Docs index](docs/) |

For the consolidated cross-module API reference, see [docs/module-apis.md](docs/module-apis.md).

Top-level layout:

```
pmo-platform/
├── operations/   # PMO operations module (skills, governance, templates)
├── release/      # Release pipeline module (skills, pipeline definitions, ADRs)
├── core/         # Shared kernel (hooks, schemas, disciplines, deploy infra)
├── docs/         # User-facing docs (INSTALL, GETTING_STARTED, workspace-setup, module-apis)
├── packages/     # .skill distribution artifacts per module
├── CHANGELOG.md  # Keep a Changelog 1.1.0 format
├── LICENSE       # BSL 1.1
└── README.md     # This file
```

## Architecture

The repository is laid out as a **modular monolith**: one repository, three modules, each with a documented `Public API` section in its README. Modules talk only through declared public surfaces; internal references stay inside their owning module. Extraction-readiness is preserved — if any module proves genuinely independent over time, it can be lifted into its own repository without rewriting consumer references.

The API-contract discipline buys two properties at low cost. First, the contract is explicit: any cross-module reference shows up in the consumer's reference list as a `via-public-api` entry, so drift between modules is visible at deploy time. Second, the kernel stays the kernel: anything `core/` exports is consumed by both operations and release, so changes to the shared surface get reviewed against both consumers.

Cross-cutting capability lives in the core module as separately-named **disciplines** (decision, discovery, review) — small reference documents that operationalize how the platform treats tier classification, premise interrogation, and post-artifact verification. They're consumed by skills in both operations and release; their structural separation from any one skill keeps them composable.

For the architectural deep-dive (workspace layout, token-resolved config templates, where the security hooks live, how the deploy script bootstraps a fresh clone, how each module's skill roster maps to consumer audiences), see [docs/workspace-setup.md](docs/workspace-setup.md).

## License

Business Source License 1.1 (BSL 1.1).

- Non-production use is granted: personal use, educational use, and internal business operations (including use by employees, contractors, and agents for your own internal program and project management) are permitted.
- Production-as-commercial-offering requires a separate commercial license. The platform may not be incorporated into hosted services, managed services, or commercial software products without separate arrangement.
- The license converts to Apache 2.0 on the Change Date (2030-05-27), four years after first publicly available distribution of the licensed version.

See [LICENSE](LICENSE) for the full terms and the licensor contact for commercial-licensing inquiries.

## Security

Found a vulnerability? Report it **privately** per the [Security Policy](SECURITY.md) — please don't open a public issue. The repo runs full-history `gitleaks` in CI, and native GitHub secret scanning + push protection are enabled.

## Contributing

pmo-platform is a single-operator project under BSL 1.1. **External pull requests are not accepted** and write access is limited to approved collaborators — see [CONTRIBUTING.md](CONTRIBUTING.md). You're welcome to fork for your own non-production use within the license and to read the code to learn the platform.

## Status

**Active development — not yet production-ready for public consumption.** The downloadable surfaces (`install.sh`, the four onboarding documents under `docs/`, the three module READMEs, and the consolidated API reference) are in place and exercised end-to-end. The platform is functionally adequate for personal use and internal-business use per the BSL 1.1 grant above. A broader public-release readiness validation is in flight; the timing of that validation is not committed.

## Acknowledgments

Built to run on top of [Anthropic Claude Code](https://claude.com/claude-code) and follows the Anthropic Skills convention for skill packaging. The Business Source License 1.1 framework is provided by MariaDB Corporation Ab. The [`CHANGELOG.md`](CHANGELOG.md) format follows [Keep a Changelog](https://keepachangelog.com/) 1.1.0 with semantic versioning adapted for the platform's release-milestone numbering.
