# docs

User-facing documentation for pmo-platform: install, first-task walkthrough, first-real-work guide, workspace architecture, update procedure, and the consolidated cross-module API reference.

## Onboarding documents

- [ONBOARDING_JOURNEY.md](ONBOARDING_JOURNEY.md) — "where am I, and where does my host plug in." The journey-map that heads this set: the ordered clone→working-install arc (J1–J7), the four host-adapter extension points, and the config seam where onboarding-time choices land. Declares the arc and links out to the docs below for every "how."
- [INSTALL.md](INSTALL.md) — "do this." Step-by-step installation procedure (prerequisites, clone, bootstrap, verification, troubleshooting).
- [GETTING_STARTED.md](GETTING_STARTED.md) — "try this." First-task walkthrough that exercises a real skill invocation end-to-end (5–8 minutes).
- [FIRST_STEPS.md](FIRST_STEPS.md) — "now do real work." Bridges from the first-skill taste to operating the platform: explore by Q&A, the work→release mental model, audience tracks (configure a project / hook up a repo + run a release), and the conventions to know up front.
- [workspace-setup.md](workspace-setup.md) — "why this." Architectural rationale for the four-sibling-directory workspace layout and the package / operator-instance boundary.
- [UPDATE.md](UPDATE.md) — "keep this current." Version-update procedure that preserves operator additions to managed config files.

## Reference

- [module-apis.md](module-apis.md) — consolidated public-API catalog across `core/`, `operations/`, and `release/` modules, with composition patterns and versioning conventions.

## Operating the platform

- [release-record-keeping.md](release-record-keeping.md) — "where's the evidence?" The operator's walk through the release-record surfaces to trace when/where a change shipped and find its proof, plus why the records live in two homes (tracked corpus vs operator-instance runtime).

## Scripts

- [scripts/setup-workspace.sh](scripts/setup-workspace.sh) — workspace bootstrap (consumed by INSTALL.md).
- [scripts/validate-install.sh](scripts/validate-install.sh) — post-install + first-task validation (consumed by INSTALL.md § 3 and GETTING_STARTED.md § 7).

## Reading order

A first-time operator can skim ONBOARDING_JOURNEY.md first for the whole-journey map (and to see which host choices are configurable), then reads INSTALL.md, runs the install, reads GETTING_STARTED.md, runs the first task, then works through FIRST_STEPS.md to connect a repo or project and run real work. After that, workspace-setup.md and module-apis.md provide architectural depth on demand, and release-record-keeping.md is the reference to reach for when operating the platform — tracing a shipped change back to its evidence. UPDATE.md becomes relevant when the next release ships.
