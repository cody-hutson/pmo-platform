---
title: Claude Code Runtime State Reference
purpose: Factual lookup for the known runtime-state surfaces Claude Code maintains on the host — config auto-snapshot backups, session storage, OS-keychain entries, and env-var precedence — so harness work relies on them intentionally rather than rediscovering them by home-directory inspection.
type: reference
status: ACTIVE
layer: 1
reversibility: CHEAP / Confidence HIGH
consumers: Any agent performing harness, account-switcher, deploy, or runtime-state-dependent work (release-pipeline spokes, harness sessions, repo-maintenance sessions).
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# Claude Code Runtime State Reference

Technical descriptions of the runtime-state surfaces Claude Code keeps on the host — facts to stand on while working, not goal-oriented procedures (those are how-to guides) and not enforced rules (those are standards). Each section catalogs a surface that is otherwise discovered only by home-directory inspection: where the surface lives, on what cadence it is written or rotated, who owns it, and how the surface came to be known. The point is intentional reliance — a harness session should consult this catalog rather than re-derive the layout each time, and should treat a `UNKNOWN` cadence as a genuine open question rather than assume a value.

This catalog covers the **non-deploy-managed** runtime state. The deploy-managed surfaces (`~/.claude/skills/`, `~/.claude/skills/packages/`) are enumerated separately in [`../../disciplines/architecture-overview.md`](../../disciplines/architecture-overview.md) § "What gets deployed vs read in place"; the two are complementary.

Alongside the written-on-disk surfaces, this document also carries **measured resolution-time findings** — see § "Context-resolution semantics". Resolution-time behavior is already in scope here: the "Env-var precedence" surface below is a precedence rule rather than a file.

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

## Context-resolution semantics

**Measurement date:** 2026-08-16 (Sunday) · **Runtime version observed:** Claude Code 2.1.233 · **Host platform:** Darwin 25.5.0

A discovery record of how the runtime resolves context files, measured so that a downstream anchoring design is selected against observed behavior rather than assumption. **This section records findings only. It states no recommended mechanism and selects no candidate shape** — selection is a downstream design decision and is deliberately absent here.

Because runtime behavior can change between measurement and use, the date and version above are the staleness handle: a consumer re-checks them before relying on anything below.

### Candidate-shape verdicts

Each shape carries exactly one verdict token — `VIABLE`, `NOT-VIABLE`, or `UNMEASURED` — and every `UNMEASURED` verdict states the reason measurement could not be completed on this instance.

| Candidate shape | Verdict | Fixture and observed result |
|---|---|---|
| **Shape A — a context file placed on the operations side that references the platform sources** | `UNMEASURED` — **reason:** neither instrument capable of answering it was available on this instance; no fixture resolved, so no result exists to grade. | Fixture **FX-NEST** (a purpose-built nested context-file tree plus a no-context control tree) **could not be constructed** — the platform's own autonomy-ceiling control refuses creation of any file carrying the context-file basename, anywhere on disk. The substitute, fixture **FX-SESSION-NEW** (a fresh non-interactive session rooted at an existing directory), **terminated at authentication** before resolving any context. Observed result in both arms: no context set was produced. |
| **Shape B — an import or inclusion chain rooted at the workspace-root charter** | `UNMEASURED` — **reason:** no live instance of the mechanism exists to observe, and the fixture that would create one is the same blocked FX-NEST; whether an inclusion resolves across the tracked/untracked boundary was therefore never exercised. | Fixture **FX-LIVE-CHARTER** (the live workspace-root charter, inspected for import directives) resolved to **0 import directives** against **18** ordinary markdown links in the same file — i.e. the charter uses linking, not inclusion, so there was no existing chain whose resolution could be watched. |
| **Shape C — reliance on the runtime's own directory-walk discovery, unaided** | `UNMEASURED` — **reason:** the recorded-session instrument does not persist the resolved context set (demonstrated broken below), and the live-session instrument could not authenticate; walk-up depth was therefore never observed. | Fixture **FX-TRANSCRIPT** (a real recorded session that ran rooted at the operations workspace and at directories beneath it) resolved to **364 recorded working-directory entries across 4 distinct depths** — confirming sessions genuinely run at those locations — but **0 records of the resolved context set**, because that set is not written to the session store at all. |

### Measured findings

These were measured and are stated as results, independent of the verdicts above.

- **The operations workspace carries no context file at its root, and none on the path from its active project subdirectories up to the workspace-root charter.** The only context files anywhere beneath it sit inside an archived implementation folder, off the live path.
- **The user-scope context carrier does not exist.** There is no user-scope context file and no user-scope rules directory, so nothing today carries procedures independently of a session's location.
- **A user-scope memory surface and the workspace-root charter load together in one session.** These are two different carriers, and their coexistence shows the runtime combines across carrier classes rather than letting one displace the other. This says nothing about precedence *within* the context-file carrier, which was not measured.
- **Session identity is keyed by working directory, not by context-file location.** A directory that holds a context file but was never a session's working directory receives no session key, while directories that were working directories each receive one. The session key is therefore a sound instrument for *where sessions ran* and an unsound one for *what context resolved* — a distinction that misleads if the key is read as a context root.
- **A session's context root and its working directory can differ.** A spawned agent thread does not acquire a key for its own working directory; it operates under the key of the session that spawned it. Any behavior that depends on working-directory discovery therefore needs separate confirmation for spawned threads, which need not resolve context from the directory they are running in.

### Probe records

Every probe carries a sensitivity arm with an observed non-zero result and a specificity arm with an observed zero.

| Probe | Denominator | Subject result | Sensitivity arm | Specificity arm |
|---|---|---|---|---|
| **P1** — context files beneath the operations workspace | all files beneath it | **2** (both inside an archived implementation folder; none at its root or at any active project root) | same invocation across the whole workspace → **12** | nonsense basename across the whole workspace → **0** |
| **P2** — user-scope context carrier | the user-scope runtime directory | context file **absent**; rules directory **absent** | user-scope memory file → **present** | nonsense user-scope path → **absent (0)** |
| **P3** — context files on this session's ancestor chain | 6 ancestor directories from working directory to filesystem root | **1** of 6 (the workspace-root charter only) | the one that exists resolved → **1** | the other 5 → **0** |
| **P4** — session-key derivation | **119** session keys | a context-file-bearing directory that was never a working directory → **0** keys; this thread's own working directory → **0** keys | working-directory-rooted sibling keys → **4**; all keys → **119** | key for a directory that was never a working directory → **0** |
| **P5** — working-directory depth of a recorded operations-workspace session | **364** working-directory records in that session | **4** distinct working directories, the deepest **2 levels** below the operations-workspace root | working-directory field extraction → **364** | nonsense field name, same file → **0** |
| **P6** — import directives in the live charter | the workspace-root charter | **0** | ordinary markdown links in the same file → **18** | nonsense pattern, same file → **0** |

### Broken probe — recorded as unusable, not as a negative result

**P7 — reading the resolved context set out of the session store.** Applied to the recorded operations-workspace session, a search for the injected-context marker returned **0**. That zero is **uninformative and is not reported as an absence of loaded context**.

The demonstration is a positive control against known ground truth: the same invocation was run against **this session's own transcript**, where the injected-context block is known with certainty to be present in the live context. It returned **0** there as well, under two independent marker spellings. An instrument that returns zero on a case known to be positive is not measuring the property. The session store does not persist the resolved context set, so no session transcript — past or future — can answer what a session loaded.

This is recorded so the instrument is not retried: transcript archaeology cannot answer context-resolution questions on this runtime.

### Instruments attempted and unavailable

Four independent routes were attempted. Three were unavailable and one was broken; the questions they would have answered are the three unmeasured verdicts above, each carrying its reason.

| Instrument | Outcome |
|---|---|
| Purpose-built context-file fixtures | **Unavailable** — the autonomy-ceiling control refuses creation of a file with the context-file basename at any path, including throwaway scratch paths. The control was not worked around: renaming the fixture would have destroyed what the experiment tests, and re-routing the same creation through a different tool would have re-attempted a refused action. |
| A fresh non-interactive session rooted at a chosen directory | **Unavailable** — terminates at authentication before any context resolution occurs. No credential was sought or supplied. |
| Startup diagnostics from such a session | **Unavailable** — authentication fails ahead of diagnostic output, so nothing is emitted. |
| Reading the resolved set out of the session store | **Broken** — see P7 above; fails its own positive control. |

### Questions this record does not close

Each remains open because the instruments above were unavailable, not because a negative result was observed.

- **Walk-up depth** — how many parent levels the runtime searches, and whether it crosses a repository boundary or a tracked/untracked boundary.
- **Accumulate versus stop-at-first** — whether several context files on one chain combine or the nearest wins.
- **Scope precedence within the context-file carrier** — which of a user-scope and a project-scope context file wins, and whether they merge or override.

### Reproducing this measurement where the instruments are available

On an instance where a non-interactive session can authenticate, the three open questions are answerable without any fixture that a control would refuse: root a session at each level of a directory chain that already carries context files at more than one level, and have it read back the context-file paths its own harness injected. The sensitivity arm is a chain known to carry a context file; the specificity arm is a directory chain carrying none, which must return an empty set. A run that cannot produce a non-empty sensitivity arm has not measured anything and is recorded as unmeasured rather than as an absence.

## Related

- [`../../rules/bypass-mode-readiness.md`](../../rules/bypass-mode-readiness.md) — its `_cross-cutting.md` ssh-agent socket side-channel residual is the keychain failure-mode touch-point (`commit.gpgsign=true` fails when the agent has no key loaded; `ssh-add --apple-use-keychain …` reloads it from Keychain).
- [`../../standards/secrets-handling-policy.md`](../../standards/secrets-handling-policy.md) § "§2 Storage Matrix" — the OS-keychain storage tier; the policy home for the keychain entry above (this catalog points to it rather than restating the tier matrix).
- [`../../disciplines/architecture-overview.md`](../../disciplines/architecture-overview.md) § "What gets deployed vs read in place" — the deploy-managed runtime surfaces (`~/.claude/skills/`, `~/.claude/skills/packages/`); this catalog covers the non-deploy-managed remainder.
- [`toolchain-operational-reference.md`](toolchain-operational-reference.md) — sibling reference doc cataloging non-obvious operational behaviors of the toolchain (gh CLI, zsh, GitHub surfaces), complementary to these runtime-state surfaces.
- Folder purpose and governance: [`README.md`](README.md).

## Provenance

- Context-resolution discovery work item: #5161 — Measure the runtime's context-resolution semantics so a downstream operations-workspace anchoring design is selected against evidence (the § "Context-resolution semantics" record: three candidate-shape verdicts, six two-armed probes, one broken probe demonstrated against a positive control, and the build rule that an unavailable instrument yields an `UNMEASURED` verdict with its reason rather than a negative result).
- Catalog work item: #163 — Catalog Claude Code runtime-state surfaces (the `~/.claude/backups/` discovery context, the four seed surfaces, and the build rule that the `~/.claude/backups/` cadence stays UNKNOWN rather than fabricated). Empirically disambiguating that cadence ("on launch" vs. "on significant config change") is explicitly a separate low-priority test, out of scope for this catalog.
