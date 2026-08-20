---
title: core/references/reference/
purpose: README for the reference folder — factual technical descriptions of platform machinery, consulted mid-task by both operations and release.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# core/references/reference/

**Purpose:** Reference docs — technical descriptions of the machinery and how it behaves (Diátaxis Reference). Factual lookup the platform's cross-cutting work consults mid-task (consumed by BOTH operations and release, which is why it lives under `core/`).
**Organization:** Flat. One `.md` per reference topic.
**Governance:** [../../governance/OPERATIONS.md](../../governance/OPERATIONS.md) § README-Per-Folder Convention.
**Layer:** 1 (Engineering, git-tracked).

> Quadrant taxonomy: see `core/README.md`.

Key entries:
- [toolchain-operational-reference.md](toolchain-operational-reference.md) — non-obvious operational behaviors of the gh CLI, zsh, GitHub's repository/Projects surfaces, and a known third-party Claude plugin.
- [claude-code-runtime-state.md](claude-code-runtime-state.md) — known Claude Code runtime-state surfaces: backups, session storage, keychain, env-var precedence.
- [operator-instance-home-and-isolation-key.md](operator-instance-home-and-isolation-key.md) — how the operator-instance runtime-state family resolves today (the config/state split already in force), the resolved fork record governing its relocation out of the personal namespace, and the ordered slice plan the relocation build consumes.
