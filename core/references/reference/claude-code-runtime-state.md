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

**Measurement date:** 2026-08-16 (Sunday), re-measured 2026-08-17 (Monday), depth re-measured 2026-08-18 (Tuesday) · **Runtime version observed:** Claude Code 2.1.233 (the first two dates; the depth re-measurement did not record a version) · **Host platform:** Darwin 25.5.0

A discovery record of how the runtime resolves context files, measured so that a downstream anchoring design is selected against observed behavior rather than assumption. **This section records findings only. It states no recommended mechanism and selects no candidate shape** — selection is a downstream design decision and is deliberately absent here.

Because runtime behavior can change between measurement and use, the dates and version above are the staleness handle: a consumer re-checks them before relying on anything below.

**Four measurement passes, and the later ones supersede the first on two of the three verdicts.** The first pass recorded every candidate shape `UNMEASURED` because no instrument was available: fixtures carrying the context-file basename are refused by the autonomy-ceiling control, and a non-interactive session could not authenticate. The second pass dissolved both blockers — the reproduction procedure needs **no fixtures** (it uses a directory chain that already carries context at more than one level), and the authentication failure was an expired login rather than an architectural limit on nested sessions. A third arm was added after review observed that the second pass had not exercised the configuration a downstream anchoring design actually depends on. A fourth pass, run independently at Stage 7 Dev Testing, re-ran the same instrument on a deeper chain and **raised the measured depth floor**; it changed no verdict token and left the upper bound unprobed. All four passes are recorded below; the verdicts state the current position.

### Candidate-shape verdicts

Each shape carries exactly one verdict token — `VIABLE`, `NOT-VIABLE`, or `UNMEASURED` — and every `UNMEASURED` verdict states the reason measurement could not be completed on this instance. A token may be qualified in the prose beside it (Shape C's `VIABLE` holds at the depths measured and asserts no upper bound), but the token itself is always exactly one of the three, so a downstream consumer citing "the verdict token" cites an unambiguous string.

| Candidate shape | Verdict | Fixture and observed result |
|---|---|---|
| **Shape A — a context file placed on the operations side that references the platform sources** | `VIABLE` — **measured.** A context file on an ancestor directory is resolved from a session rooted below it, and it **accumulates with** the further ancestors' context files rather than displacing them. Measured in the configuration this shape actually runs in: session root carrying **no** context file of its own, beneath **two** ancestors that each carry one. | Fixture **FX-CHAIN** (a directory chain in the live workspace already carrying context at more than one level — no fixture creation, so the autonomy-ceiling control is never engaged). Arms and their layouts are in the probe table below. Sensitivity: a root known to carry context returned a non-empty set. Specificity: a chain carrying none returned `NONE` while the invoking session was itself context-rich, which is what excludes inheritance. |
| **Shape B — an import or inclusion chain rooted at the workspace-root charter** | `UNMEASURED` — **reason:** there is no live instance of the mechanism to observe, and no pass exercised inclusion resolution. The first pass's blocker (an un-constructable fixture) no longer applies — the later passes needed no fixtures — but they measured **walk-up and precedence**, not inclusion. Whether an inclusion directive resolves at all, or resolves across the tracked/untracked boundary, remains unexercised. | Fixture **FX-LIVE-CHARTER** (the live workspace-root charter, inspected for import directives) resolved to **0 import directives** against **18** ordinary markdown links in the same file — i.e. the charter uses linking, not inclusion, so there was no existing chain whose resolution could be watched. |
| **Shape C — reliance on the runtime's own directory-walk discovery, unaided** | `VIABLE` — **at the depths measured; measured to a floor, not to a ceiling.** Walk-up resolves ancestors from a session root that carries no context file of its own, to a measured depth of **≥ 4 levels**. The upper bound is **UNMEASURED** (see Bounds); this verdict states what was observed and asserts no bound. | Fixture **FX-CHAIN**, same instrument as Shape A. The earlier fixture **FX-TRANSCRIPT** (a real recorded session rooted at the operations workspace and beneath it) resolved to **364 recorded working-directory entries across 4 distinct depths** — confirming sessions genuinely run at those locations — but **0 records of the resolved context set**, because that set is not written to the session store at all. That instrument is broken for this question and is not what produced this verdict. |

### Measured findings

These were measured and are stated as results, independent of the verdicts above.

- **Walk-up is CONFIRMED.** A session rooted at a directory carrying no context file of its own loads the context file from an ancestor. Resolution proceeds upward from the session root.
- **Walk-up does not stop at the first hit.** From a root carrying no context file, beneath two ancestors that each carry one, **both** ancestors' files loaded. Resolution continues past the nearest context-bearing ancestor and picks up the further one as well.
- **Scope precedence is ACCUMULATIVE with ancestor-first ordering, not nearest-wins.** Where several context files lie on one chain they combine; the ancestor appears first and the nearest last. This is union-with-ordering — the ordering a more-specific-refines-less-specific model requires — and it is the opposite of the intuitive nearest-wins assumption. The distinction is load-bearing for any anchoring design: under nearest-wins, a context file placed below the workspace root would **displace** the root charter rather than add to it.
- **Accumulation holds both when the session root carries its own context file and when it does not.** The first configuration was measured in the second pass; the second — root carries none, two ancestors each carry one — in the third. A design resting on accumulation depends on the second, which is why it was measured separately rather than extrapolated from the first.
- **Walk-up depth is measured at ≥ 4 levels.** Four levels is the **floor established by the deepest chain exercised**, not a ceiling. See Bounds.
- **The operations workspace carries no context file at its root, and none on the path from its active project subdirectories up to the workspace-root charter.** The only context files anywhere beneath it sit inside an archived implementation folder, off the live path. *(Measured before the anchoring work; a workspace on which the installer has since run carries the anchor at the operations-workspace root.)*
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

**Context-resolution probes (passes 2 and 3).** Instrument: a fresh non-interactive session rooted at a chosen directory, reporting back the context-file paths its own harness injected. Each probe is a **separate process**, which is what makes the specificity arm meaningful. The per-arm **directory layout** is recorded, not only the verdict token — a downstream consumer cannot check whether a verdict applies to its own configuration from a token alone, and a design once cited one of these verdicts for a configuration it had not covered.

| Probe | Session root | Context files on the ancestor chain | Depth below the highest carrier | Result |
|---|---|---|---|---|
| **P8** — sensitivity arm | workspace root, which **carries** a context file | 1, at the root itself | 0 | returned **2 paths** — non-empty, so the instrument can detect injection |
| **P9** — specificity arm | a freshly created temp directory whose **entire** ancestor chain carries none | 0 | n/a | returned **`NONE`** — zero, so the instrument does not manufacture results. Returned `NONE` **while the invoking session was itself context-rich**, which is what excludes inheritance: under inheritance it would have returned the invoker's context |
| **P10** — walk-up | an intermediate directory carrying **no** context file of its own | 1, on an ancestor | 1 level | the ancestor's context file **loaded** — walk-up CONFIRMED |
| **P11** — accumulation, root-carries-own | a directory that **carries** its own context file, with one ancestor also carrying one | 2, one of them at the root | 1 level | **both** loaded, ancestor first and nearest last — union with ordering, not nearest-wins |
| **P12** — accumulation, root-carries-none *(the configuration an operations-side anchor actually runs in)* | a directory **three levels** below the workspace root, carrying **no** context file, beneath **two** ancestors that each carry one | 2, **both above the root** | 3 levels | **both ancestors loaded** — walk-up does not stop at the first hit; accumulation holds when the nearest carrier is not the session root. Raises the measured depth floor from ≥ 2 to **≥ 3** |
| **P13** — depth, root-carries-none *(fourth pass, Stage 7 Dev Testing, 2026-08-18 Tuesday)* | a directory carrying **no** context file, beneath carriers **2 levels** and **4 levels** above it | 2, **both above the root** | 4 levels | **both loaded, ancestor-first** — accumulation holds at the greater separation, and resolution reaches a carrier four levels up. Raises the measured depth floor from ≥ 3 to **≥ 4** |

P12 was added after review observed that P11 measures the case where the nearest carrier **is** the session root — structurally the case a runtime is most likely to special-case, since a root-local file is not a walk-up result at all — and that no arm had covered the configuration where every carrier is an ancestor. The two are different claims and only P12 establishes the second.

P13 came from an independent fourth pass that re-ran this same instrument on a deeper chain, with its own two arms: a sensitivity arm (a root that carries one context file → **1 path**) and the same specificity arm (a chain carrying none → **`NONE`**, returned while the invoking session was itself context-rich). It moves only the **floor**. No arm probed a chain deeper than four levels, so the upper bound is exactly as unmeasured after P13 as before it — see Bounds.

### Bounds, stated rather than implied

- **Walk-up depth is measured at ≥ 4 levels.** Four levels is the deepest chain exercised, so it is the **floor, not the ceiling**. Nothing here establishes where resolution stops — whether at a git root, a home directory, or the filesystem root.
- **The walk-up upper bound is UNMEASURED.** A deeper chain would be needed and this record does not assert one. A design **must not** read the ≥ 4 floor as a limit, and must not assume any specific bound: the honest reading is that resolution reaches at least four levels and may reach further. The floor has now moved twice — ≥ 2 → ≥ 3 → ≥ 4 — each time because a deeper chain was exercised, never because a bound was found. That the floor moves when someone measures deeper is precisely the evidence that it is not a ceiling.
- **Accumulation is measured for context files on a single ancestor chain.** It is not a claim about precedence between a project-scope context file and a user-scope carrier, which remains unmeasured within the context-file carrier class.
- **One observation carrying an interpretation caveat.** A user-scope memory surface was injected in both context-bearing probes but not in the context-free one. That is consistent with memory injection being gated on workspace recognition rather than being unconditionally user-scope, but a single probe with an unvalidated interpretation is not a finding. Recorded as an open question, not a result.

### Broken probe — recorded as unusable, not as a negative result

**P7 — reading the resolved context set out of the session store.** Applied to the recorded operations-workspace session, a search for the injected-context marker returned **0**. That zero is **uninformative and is not reported as an absence of loaded context**.

The demonstration is a positive control against known ground truth: the same invocation was run against **this session's own transcript**, where the injected-context block is known with certainty to be present in the live context. It returned **0** there as well, under two independent marker spellings. An instrument that returns zero on a case known to be positive is not measuring the property. The session store does not persist the resolved context set, so no session transcript — past or future — can answer what a session loaded.

This is recorded so the instrument is not retried: transcript archaeology cannot answer context-resolution questions on this runtime.

### Instruments attempted and unavailable

Four independent routes were attempted in the first pass. Three were unavailable and one was broken. **Two of those blockers were later dissolved**, which is why the verdicts above are no longer all `UNMEASURED`; the table records the current status of each route so a future reader does not re-attempt a route on stale information.

| Instrument | First-pass outcome | Current status |
|---|---|---|
| Purpose-built context-file fixtures | **Unavailable** — the autonomy-ceiling control refuses creation of a file with the context-file basename at any path, including throwaway scratch paths. The control was not worked around: renaming the fixture would have destroyed what the experiment tests, and re-routing the same creation through a different tool would have re-attempted a refused action. | **Still unavailable, and no longer needed.** The control's refusal stands and was never bypassed. The reproduction procedure requires **no fixtures** — it uses a directory chain that already carries context at more than one level, and such a chain already exists. The blocker was real; the dependency on it was not. |
| A fresh non-interactive session rooted at a chosen directory | **Unavailable** — terminates at authentication before any context resolution occurs. No credential was sought or supplied. | **Available.** The failure was an **expired login**, not an architectural limit on nested sessions: an auth-status read returned logged-out. Once re-authenticated, every probe ran without engaging any control. This is the instrument that produced P8–P12. |
| Startup diagnostics from such a session | **Unavailable** — authentication fails ahead of diagnostic output, so nothing is emitted. | **Not re-attempted** — the session-reports-its-own-context instrument above answered the questions, so this route was not needed. |
| Reading the resolved set out of the session store | **Broken** — see P7 above; fails its own positive control. | **Still broken.** The session store does not persist the resolved context set at all, so no amount of authentication changes this. Recorded so it is not retried. |

### Questions this record does not close

Three of these were open in the first pass because its instruments were unavailable. Two are now closed by measurement; the rest remain open, and each states why.

**Closed by the later passes:**

- **Accumulate versus stop-at-first** — **CLOSED.** Several context files on one chain **combine**, ancestor first and nearest last. Walk-up does not stop at the first carrier it finds. Measured in both configurations (P11, P12).
- **Walk-up depth, lower bound** — **CLOSED to a floor of ≥ 4 levels** (P12, then P13). The *upper* bound is a separate question and is still open, below.

**Still open:**

- **Walk-up upper bound** — where resolution stops, and whether it crosses a repository boundary, a tracked/untracked boundary, a home directory, or the filesystem root. Answering it needs a chain deeper than four levels; no such chain has been exercised. The fourth pass reached four and stopped there because that was the deepest chain to hand, not because resolution failed at the fifth.
- **Scope precedence within the context-file carrier** — which of a user-scope and a project-scope context file wins, and whether they merge or override. The accumulation finding covers context files on one **ancestor chain**; it says nothing about the user-scope carrier, which sits outside that chain.
- **Whether user-scope memory injection is gated on workspace recognition** — a single probe with an unvalidated interpretation, recorded as a question rather than a result.
- **Whether a spawned agent thread resolves context from its own working directory** — session identity keys on working directory and a spawned thread runs under its parent's key, so any working-directory-dependent behavior needs separate confirmation for spawned threads. Unaffected by the later passes.

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
- Context-resolution re-measurement: the anchoring work item that consumes this record — the later passes that dissolved two of the first pass's three blockers and converted two verdicts from `UNMEASURED` to `VIABLE` (probes P8–P13: walk-up CONFIRMED, precedence ACCUMULATIVE with ancestor-first ordering, depth floor ≥ 4 levels, upper bound still `UNMEASURED`). The build rule this pass adds: a probe record states the **configuration** each arm ran in — the directory chain and where its context files sat — not only the verdict token, because a consumer cannot check a verdict's applicability to its own configuration from a token alone.
- Depth re-measurement (P13): produced as a by-product of Stage 7 Dev Testing on the anchoring card, which re-ran the accumulation instrument on a chain with carriers 2 and 4 levels up and reported the floor moving ≥ 3 → ≥ 4 with both arms. The build rule this pass adds: **a floor that moves whenever a deeper chain is exercised is evidence of an unfound ceiling, not of a converging bound** — so a consumer that needs the upper bound must measure it, and may not infer it from successive floors.
- Catalog work item: #163 — Catalog Claude Code runtime-state surfaces (the `~/.claude/backups/` discovery context, the four seed surfaces, and the build rule that the `~/.claude/backups/` cadence stays UNKNOWN rather than fabricated). Empirically disambiguating that cadence ("on launch" vs. "on significant config change") is explicitly a separate low-priority test, out of scope for this catalog.
