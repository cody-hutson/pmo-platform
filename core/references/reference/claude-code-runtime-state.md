<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Claude Code Runtime State Reference
purpose: Factual lookup for the known runtime-state surfaces Claude Code maintains on the host — config auto-snapshot backups, session storage, OS-keychain entries, and env-var precedence — so harness work relies on them intentionally rather than rediscovering them by home-directory inspection.
type: reference
layer: 1
reversibility: CHEAP / Confidence HIGH
consumers: Any agent performing harness, account-switcher, deploy, or runtime-state-dependent work (release-pipeline spokes, harness sessions, repo-maintenance sessions).
---

# Claude Code Runtime State Reference

Technical descriptions of the runtime-state surfaces Claude Code keeps on the host — facts to stand on while working, not goal-oriented procedures (those are how-to guides) and not enforced rules (those are standards). Each section catalogs a surface that is otherwise discovered only by home-directory inspection: where the surface lives, on what cadence it is written or rotated, who owns it, and how the surface came to be known. The point is intentional reliance — a harness session should consult this catalog rather than re-derive the layout each time, and should treat a `UNKNOWN` cadence as a genuine open question rather than assume a value.

This catalog covers the **non-deploy-managed** runtime state. The deploy-managed surfaces (`~/.claude/skills/`, `~/.claude/skills/packages/`) are enumerated separately in [`../../disciplines/architecture-overview.md`](../../disciplines/architecture-overview.md) § "What gets deployed vs read in place"; the two are complementary.

## Per-surface entry schema

Each surface below is one H2 section carrying a fixed five-field record:

| Field | Content |
|---|---|
| **Surface name** | Human-readable name of the runtime-state surface (the H2 heading). |
| **Path / mechanism** | Concrete path glob or mechanism. |
| **Cadence** | When the surface is written or rotated. Marked `UNKNOWN` where empirically undisambiguated, with the open question stated inline — never a fabricated value. |
| **Scope-class** | `host-owned` (Claude Code writes it) / `operator-owned` (the operator sets it; precedence is host-defined) / `OS-owned` (an OS store such as the macOS Keychain; a host tool writes entries into it). Drives the correct cross-reference target and the hook-governance question. |
| **Discovery-source** | How the surface is known: an in-repo `file:line`, an issue reference plus context, or an external/extracted-repo reference. An empirical-only discovery cites its originating context, never a fabricated doc. |

## `~/.claude/backups/` config auto-snapshots

- **Path / mechanism:** `~/.claude/backups/.claude.json.backup.<unix-ms>` — Unix-epoch-millisecond-suffixed copies of `~/.claude.json` (the global Claude Code config). Each launch/write event deposits a new suffixed copy alongside the prior ones.
- **Cadence:** **UNKNOWN.** Open question: "on launch" vs. "on significant config change" — empirically undisambiguated. The single observation is five backups across roughly 24 hours, which is consistent with either hypothesis; do not rely on a fixed interval or assume one snapshot per launch. (Disambiguating this cadence is a separate low-priority test, out of scope for this catalog — see Provenance.)
- **Scope-class:** `host-owned` (Claude Code writes the snapshots).
- **Discovery-source:** Empirical — the account-switcher harness's Stage 5 surfaced five backups across ~24h; the originating context is preserved in the catalog work item (see Provenance). The account-switcher harness has since been extracted to its own repository (per [`../../rules/harness-deployment.md`](../../rules/harness-deployment.md) § "Account-switcher (relocated)"), so there is no in-repo `file:line` for the observation — the issue plus extracted repo is the citation.

## Session storage layout

- **Path / mechanism:** Claude Code keeps per-session state under `~/.claude/` (session records and transcripts). State only the concrete sub-path(s) verifiable at the time of consultation; an unverified sub-path is `UNKNOWN`, not a guess.
- **Cadence:** Per-session write — the surface is touched on session activity, not on a fixed clock. Mark `UNKNOWN` for any sub-path whose write trigger is not verifiable.
- **Scope-class:** `host-owned` (Claude Code writes the session state).
- **Discovery-source:** Home-directory inspection at consultation time — record the exact directory-listing evidence and date when pinning a sub-path. This catalog does not fabricate a layout; a sub-path that cannot be verified is left `UNKNOWN` with the open question noted.

## OS-keychain entry naming

- **Path / mechanism:** macOS Keychain entries used by host tooling — most notably the `gh` CLI credential helper, which uses the macOS Keychain by default. The keychain is an OS store, not a file path; entries are addressed by service/account name rather than by a filesystem glob.
- **Cadence:** Written on authentication (`gh auth login` and equivalents) — event-driven, not periodic.
- **Scope-class:** `OS-owned` (the macOS Keychain owns the store; the host tool writes entries into it).
- **Discovery-source:** [`../../standards/secrets-handling-policy.md`](../../standards/secrets-handling-policy.md) § "§2 Storage Matrix" (the OS-keychain storage tier — `C2`, `gh` CLI → macOS Keychain) plus the ssh-agent/keychain residual in [`../../rules/bypass-mode-readiness.md`](../../rules/bypass-mode-readiness.md) (keychain auto-load failure mode). The storage-tier policy is the home for keychain policy — this entry cross-references it and does not restate the tier matrix. Exact entry *names* that are not verifiable at consultation time are `UNKNOWN`.

## Env-var precedence

- **Path / mechanism:** The order in which Claude Code and the harness resolve environment configuration — for example the workspace-root resolution chain. This is a resolution-time precedence rule, not a written-on-disk surface.
- **Cadence:** n/a — precedence is resolved at runtime; nothing is written.
- **Scope-class:** `operator-owned` (the operator sets the environment; the precedence ordering itself is host-defined).
- **Discovery-source:** [`../../rules/doc-link-maintenance.md`](../../rules/doc-link-maintenance.md) documents the workspace-root precedence as `--workspace-root` > `$CLAUDE_WORKSPACE_ROOT` > the in-repo default. State only precedence rules verifiable from in-repo evidence; any ordering not so verifiable is `UNKNOWN`.

## Related

- [`../../rules/bypass-mode-readiness.md`](../../rules/bypass-mode-readiness.md) — its `_cross-cutting.md` ssh-agent socket side-channel residual is the keychain failure-mode touch-point (`commit.gpgsign=true` fails when the agent has no key loaded; `ssh-add --apple-use-keychain …` reloads it from Keychain).
- [`../../standards/secrets-handling-policy.md`](../../standards/secrets-handling-policy.md) § "§2 Storage Matrix" — the OS-keychain storage tier; the policy home for the keychain entry above (this catalog points to it rather than restating the tier matrix).
- [`../../disciplines/architecture-overview.md`](../../disciplines/architecture-overview.md) § "What gets deployed vs read in place" — the deploy-managed runtime surfaces (`~/.claude/skills/`, `~/.claude/skills/packages/`); this catalog covers the non-deploy-managed remainder.
- [`toolchain-operational-reference.md`](toolchain-operational-reference.md) — sibling reference doc cataloging non-obvious operational behaviors of the toolchain (gh CLI, zsh, GitHub surfaces), complementary to these runtime-state surfaces.
- Folder purpose and governance: [`README.md`](README.md).

## Provenance

- Catalog work item: #163 — Catalog Claude Code runtime-state surfaces (the `~/.claude/backups/` discovery context, the four seed surfaces, and the build rule that the `~/.claude/backups/` cadence stays UNKNOWN rather than fabricated). Empirically disambiguating that cadence ("on launch" vs. "on significant config change") is explicitly a separate low-priority test, out of scope for this catalog.
