<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — 96-update-install-config-safety

> **Milestone:** `96-update-install-config-safety` (#239) · **Release Class:** `novel` (engagement **Standard**, Stage-9 review depth **Deep**, Stage-5 activation bias **ALL**) · **Version:** `{{RELEASE_VERSION}}` *(unresolved by design — the token binds to the won tag at the Stage-12 atomic claim, when `claim-version.sh --stamp-slug` resolves it and renames this file; the provisional determination re-verified at Engineering Commit 0 is recorded in § Commit-0 Version Re-Verify, per ADR-092)* · **Scope:** 4 issues · 18 effective pts · One release branch, one PR, one merge gate (D-C **SINGLE**, D-Concurrency **P0 fully-serial**).

This plan transcribes the Stage-4 Release Planning output rendered on hub sub-task #4776 (plan gate approved 2026-08-05, Wednesday), reconciled against the four Stage-5 Solutioning outputs consumed at Collective Review (#4778 · #4782 · #4786 · #4790) and against live mainline state at Commit 0. Deltas discovered between plan approval and Commit 0 are folded into § Deviation Log rather than silently applied. Authored as **Engineering Commit 0** by the first Stage-6 spoke (#4779, card #1531).

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` — slug-primary pre-claim (ADR-092); bump class `minor` |
| **Date Created** | 2026-08-05 (Wednesday) — Stage-4 plan gate |
| **Commit 0 authored** | 2026-08-06 (Thursday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/96-update-install-config-safety` |
| **PR** | (populated at PR creation — hub-owned, after the final slice) |
| **Milestone** | `96-update-install-config-safety` (239) |
| **Baseline** | `origin/main` @ `86bc649e` (Stage-4 pinned `c0122aa0`; **7 commits of drift** — see DEV-1) |

## Summary (30 seconds)

Four open build cards, one theme: **the install/update path stops losing operator configuration and stops requiring a human at the keyboard.** After this release a fresh install completes with stdin closed, an `operator.toml` carrying operator-added tables round-trips under a gate that fails exactly when a production consumer would, the managed `settings.json` no longer silently drops operator hook registrations, `update.sh` refreshes the Customizable files its spec has long claimed it would, and a config surface for git-native release automation exists that degrades to a no-op with no consumer present.

- **The `routine` class did not survive the taxonomy.** All four `routine` triggers are falsified; two `novel` triggers fire. Re-classified at the Stage-4 D-Gate: Stage-9 depth Standard → **Deep**, engagement Light → **Standard**.
- **#1531's residual is one function, not "the installer prompts".** `setup-workspace.sh` has exactly **4** interactive prompt sites; three already degrade safely on closed stdin. Only `resolve_token` hard-fails.
- **Two ACs on #1531 were mutually unsatisfiable as written** — AC-1 said "template defaults" while the template ships `""` for every required identity field and AC-2 forbids substituting empty. Restated at the gate as *each token's **declared** non-interactive default*.
- **A live managed-key config-loss defect was found inside the gate's own subject.** `[paths].cowork_install_path` is blanked on every first install: the resolver stores `[COWORK_INSTALL_PATH]` while the writer reads the registered `[COWORK_INSTALL_PATH_BASE]`. Operator-approved for in-scope fix (D-1531-D Option 1).
- **ADR-120 ratified at Stage 5, scoped CLAUDE.md-only** — no JSON-structural model. That decoupled #1355 from #3831 and let #1355 **expand** to own the `settings.json` refresh under ADR-121. *(Both records shifted +1 from their Stage-4/Stage-5 draft numbers after a concurrent release claimed 119 on the mainline. Every ADR number in this plan is the SHIPPED number — see DEV-6.)*
- **The sharpest assertion in the release is a probe-shape one.** Five production consumers read `operator.toml` with a **line-anchored, section-blind** `grep -E '^key'`. A section-aware assertion would pass on an indented re-emit that every one of those consumers would miss — silently dropping the **autonomy ceiling** to its fallback. The gate probes with the consumers' own shape.

## Commit-0 Version Re-Verify

Run at Engineering Commit 0 on **2026-08-06 (Thursday)** per the release-identity two-phase binding discipline. `v4.13` was rule-computed as the provisional determination at Stage 4 (bump-class `minor`, anchor `v4.12`; recorded on #4776). This re-verify is the **first detection rung**; the Stage-12 atomic claim is the resolving authority. Protocol is **detect-and-HALT, no auto-retry** — a collision here stops Engineering and returns D-Version to the operator.

**Method.** `git fetch --tags origin && git fetch origin main`, then each arm of the claimed set evaluated independently against `origin/main` at `86bc649e`. Ledger input read via `git show origin/main:<path>`, never the worktree copy.

| Claimed-set arm | Probe | Result |
|---|---|---|
| Origin tags | `git ls-remote --tags origin` | `refs/tags/v4.13` × **0** over a **310**-ref denominator (controls: `v4.12` × 1, `v4.11` × 1 — the tag probe is live) |
| Published GitHub Releases | `gh release list --limit 300 --json tagName` | `v4.13` × **0** over a **154**-release denominator (controls: `v4.12` × 1, `v4.11` × 1; specificity `v4.14` × 0) |
| Mainline release ledger | `git show origin/main:release/releases/RELEASE_LOG.md` | `v4.13` rows × **0** over a **161**-version-row denominator (control: `v4.12` × 1). **0** in-flight `DEPLOYED`-not-`VERIFIED` rows against **161** `VERIFIED` |
| Rule-computed next-free | `claim-version.sh --sha 86bc649e --bump minor --dry-run` | **`v4.13`** |

**Verdict: PROCEED.** `anchor()` = `v4.12`; floor (`minor`) = `v4.13`; `claimed_set()` has no member at or above the floor on any of the three surfaces, each with a control arm that returned non-zero. **`v4.13` remains next-free and equals the recomputed next-free.** No HALT condition present.

**Grammar note (recorded, not a divergence).** The per-release increment advances the **MINOR** component of the two-component `vMAJOR.MINOR` grammar, which is what `--bump minor` computes. `--bump patch` computes the three-component hotfix slot and is not the cadence bump.

## Scope

### Release Outcome Statement

**AFTER** — The update/install path preserves operator configuration by construction and can be driven unattended: a fresh install completes non-interactively, an `operator.toml` carrying operator-added tables round-trips under a regression gate that fails if any table or key is dropped, an operator who has customized the managed `settings.json` is warned or migrated before a re-render would drop their keys, `update.sh` refreshes the Customizable files (CLAUDE.md, settings.json) that its spec has long declared it would, and a config surface for git-native release automation exists and degrades to a no-op off the git-based path.

**BEFORE** — Config safety is partial and the spec overstates it: the installer cannot complete a fresh run unattended, the shipped `operator.toml` round-trip has no test asserting its own invariant, the managed `settings.json` is overwritten whole-file with nothing guarding or steering operator customizations, `update.sh` does not refresh Customizable files despite the spec describing the mechanism, and there is no config surface for git-native release automation.

### Members

| Issue | Size | Title | Order |
|---|---|---|---|
| #1531 | `S` (2) | `setup-workspace.sh` non-interactive fresh install + `operator.toml` config-preservation regression gate | E1 |
| #1842 | `M` (4) | Operator config surface for git-native release automation (toggles + no-op degradation) | E2 |
| #3831 | `L` (8) | CUSTOMIZABLE update-refresh mechanism (gated on ADR-120) | E3 |
| #1355 | `M` (4) | Managed `settings.json` overwrite is unguarded (expanded at Stage 5 to own the refresh; carries ADR-121) | E4 |

**Closed and out of build scope:** #1354 (delivered by v3.86 #2232) · #1492 (delivered 2026-06-27). Their closure rationale was re-read at Stage 4 and holds.

**Scope LOCKED at Stage-4 Planning entry, 2026-08-05 (Wednesday).** 4 members / 18 effective pts, inside the 15–25 target band. All four Stage-5 designs accepted at Collective Review; zero HALTs outstanding.

## Dependency Graph

```
ADR-120 (Accepted) ═══hard═══► #3831      #3831 AC-1 requires status: Accepted
ADR-120 ┄┄soft, conditional┄► #1355       RESOLVED at Stage 5 → DECOUPLES
#1842 ┄┄soft┄► #1531                       #1531's gate fixture must cover #1842's operator.toml surface
#1531 ⋈ #1842 ⋈ #1355   file contention   docs/scripts/setup-workspace.sh
#1531 ⋈ #3831 ⋈ #1355   file contention   core/deploy/tests/test_upgrade_config_durability.sh
#3831 ⋈ #1355           file contention   core/standards/composition-surface-spec.md · docs/UPDATE.md
```

**Circular-chain check: zero cycles.** Transitive closure over the six edges yields a DAG rooted at ADR-120 with #1531/#1842 as independent sources. Sensitivity arm: injecting a synthetic `#1355 ⇒ ADR-120` edge produces a detected cycle, so the checker can see one.

**The conditional edge resolved at Stage 5.** ADR-120 was ratified **CLAUDE.md-only** — no JSON-structural composition model; `composition-surface-spec.md` §2.3 stands verbatim. That selects the *decoupled* branch: #1355's mechanism is independent of #3831's design, and the blanket serialization the milestone description implied is **not** warranted. #1355 stays last on file-contention grounds alone.

## Implementation Sequence

**Stage 6 Engineering routes write-serialized in dependency order on ONE branch** (`D-C = SINGLE`, `D-Concurrency = P0 fully-serial`). The next slice waits until the prior commit lands on the release branch. Force-push — including `--force-with-lease` — is prohibited on the shared branch under any multi-chip activity.

| Order | Slice | Why here |
|---|---|---|
| 0 | **Commit 0** — this plan file | Plan on disk before any implementation commit |
| **E1** | **#1531** (S) | Foundation. Lands `--non-interactive` on `setup-workspace.sh` and the preservation suite in `test_upgrade_config_durability.sh` — the two most-contended files — first, so every later card rebases onto a settled base. Depends on nothing. |
| **E2** | **#1842** (M) | Immediately after, so the `operator.toml` surface E1's gate asserts actually exists in this release (CIAC-1). Pulled earlier than the milestone description's step 5: its "fully independent" claim was falsified by three verified couplings. Does **not** depend on ADR-120. |
| ⛔ | **ADR-120 Accepted** | **HARD GATE — a Stage-5→Stage-6 boundary condition on #3831 alone, not an Engineering step.** **DISCHARGED:** ratified at Stage 5 Collective Review (operator-rendered, 2026-08-06), scope CLAUDE.md-only, mechanism = extend `COMPOSITION_SURFACE_FILES` rather than a new `CUSTOMIZABLE_FILES` array. |
| **E3** | **#3831** (L) | Once ADR-120 is Accepted. Largest, highest-reversibility-cost card; goes after the two cheap ones so a NO-GO on the ADR would have cost the least sunk work. |
| **E4** | **#1355** (M) | Last. Shares `setup-workspace.sh` with E1/E2 and `composition-surface-spec.md` + `docs/UPDATE.md` with E3 — landing last means it rebases once onto a settled base and reconciles both governance surfaces in one informed pass. |

**Delivery strategy.** D-C **SINGLE** (one `release/96-update-install-config-safety` branch, one PR, one merge). Justified by the contention map: three of four cards claim `test_upgrade_config_durability.sh` and three claim `setup-workspace.sh`, so per-issue branches would move contention from commit-order to PR-merge-order without reducing it, while adding rebase cost on two thin-history files.

## Stage Applicability Matrix

**Zero stage skips.** All four members run Stages 5–13. Stage 5 was release-wide all-or-nothing per the planning↔solutioning handoff rule.

| Issue | Size | S5 | S6 | S7 | S8 | S9 | S12/13 |
|---|---|---|---|---|---|---|---|
| #1531 | S | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #1842 | M | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #3831 | L | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #1355 | M | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**#1842 is the non-obvious Stage-7 entry:** its document-inspection ACs do not make it doc-only — adding to `core/config/operator.toml.template` exercises the `write_operator_toml` round-trip and touches the pinned section-blind grep in `core/hooks/block-autonomy-ceiling.sh`.

## File Change Matrix

**Machine-readable path list** — one repo-relative path per line, for deterministic extraction by Stages 7 / 8 / 9. **Reconciled at the pre-PR pass against the landed diff** (`git diff --name-only origin/main...HEAD`, n=32) so the extraction target and the tree agree; see DEV-7 for the three phantom rows removed and the surfaces added.

```
docs/scripts/setup-workspace.sh
docs/scripts/validate-install.sh
core/CLAUDE.md.template
core/settings.json.template
core/config/platform-config.toml.template
core/deploy/compose.py
core/deploy/composition-surface-manifest.sh
core/deploy/deploy.sh
core/deploy/lib-composition.sh
core/deploy/tests/test_upgrade_config_durability.sh
core/deploy/tests/test_compose.py
core/deploy/tests/test_install_end_to_end.sh
core/deploy/tests/test_lib_composition.sh
core/hooks/block-autonomy-ceiling.sh
core/hooks/prime-autonomy-ceiling-cache.sh
core/hooks/tests/block-autonomy-ceiling.test.sh
core/hooks/tests/prime-autonomy-ceiling-cache.test.sh
core/schemas/platform-config-schema.md
core/standards/composition-surface-spec.md
core/standards/depersonalization-spec.md
core/ADRs/ADR-120-claude-md-composition-surface-recategorization.md
core/ADRs/ADR-121-settings-json-baseline-anchored-refresh.md
install.sh
update.sh
docs/INSTALL.md
docs/UPDATE.md
docs/platform-config-reference.md
release/governance/release-process.md
release/tools/lib/platform-toggle.sh
release/tools/tests/test_platform_toggle.sh
release/releases/plans/96-update-install-config-safety_RELEASE_PLAN.md
.github/workflows/release-tooling-smoke.yml
```

### Per-path intent

| Path | Card | Intent | Change |
|---|---|---|---|
| `docs/scripts/setup-workspace.sh` | E1, E2, E4 | **edit** | E1: `--non-interactive` parse arm + a defaults-resolution branch in `resolve_token` that never reads stdin, plus the `[COWORK_INSTALL_PATH_BASE]` resolver-arm correction. E2/E4 per their own designs. |
| `core/CLAUDE.md.template` | E1 | **edit** | One token: `[COWORK_INSTALL_PATH]` → `[COWORK_INSTALL_PATH_BASE]`. **Must land paired with the `setup-workspace.sh` resolver arm** — the template drives `ACTIVE_TOKENS` via `compute_active_tokens` (AI-005). |
| `core/deploy/tests/test_upgrade_config_durability.sh` | E1, E3, E4 | **edit** (append suites) | Each card appends a **new named suite** and never edits Suites F/G/T. Suite letters coordinated: **P** (Preservation) = #1531 · **C** (Customizable) = #3831 · **S** (Settings) = #1355. |
| `install.sh` | E1 | **edit** | Usage text only — `phase_workspace_bootstrap` already forwards `"$@"` verbatim, so no code change. |
| `docs/INSTALL.md` | E1 | **edit** | Flag-table row + reconcile the "via interactive prompts" prose. Reconcile, do not annotate. |
| `update.sh` | E3 | **edit** | Customizable regeneration phase (sibling to the managed-section phase); workspace-root resolver tier. |
| `core/deploy/compose.py` | E3 | **edit** | Emit the markdown marker form. The **read** path already handles it; scope is the emitter, not the parser. |
| `core/deploy/composition-surface-manifest.sh` | E3 | **edit** | Extend `COMPOSITION_SURFACE_FILES` per ADR-120. **Bash-3.2 constraint:** plain assignment only — no `declare -a`. |
| `core/deploy/tests/test_compose.py` | E3 | **edit** | New case: markdown marker **emission** (existing coverage is extraction-only). |
| `core/deploy/lib-composition.sh` · `core/deploy/tests/test_lib_composition.sh` | E3, E4 | **edit** | The dialect-aware writer/reader half of the composition primitive plus its unit suite. Not in the Stage-4 matrix — see DEV-7. |
| `core/deploy/deploy.sh` · `docs/scripts/validate-install.sh` · `core/deploy/tests/test_install_end_to_end.sh` | E3, E4 | **edit** | Deploy-check + install-validation + end-to-end coverage that had to move with the re-categorization and the settings guard. Not in the Stage-4 matrix — see DEV-7. |
| `core/config/platform-config.toml.template` | E2 | **edit** | **This is where #1842's config surface actually landed** — a new `[git_release_automation]` section with three boolean toggles, NOT `operator.toml`. Always-on declarations + detection/degradation rule stated in-section. **CIAC-1.** |
| `release/tools/lib/platform-toggle.sh` · `release/tools/tests/test_platform_toggle.sh` · `.github/workflows/release-tooling-smoke.yml` | E2 | **add** | #1842's terminal in-code absent-key resolver (AI-002), its suite, and the CI smoke that runs it. Not in the Stage-4 matrix — see DEV-7. |
| `core/schemas/platform-config-schema.md` · `docs/platform-config-reference.md` | E2 | **edit** | Schema + operator reference rows for the new section. Not in the Stage-4 matrix — see DEV-7. |
| `core/hooks/block-autonomy-ceiling.sh` · `core/hooks/prime-autonomy-ceiling-cache.sh` (+ their two `tests/` suites) | E2 | **edit** | The two autonomy-ceiling readers hardened from section-BLIND to section-AWARE while deliberately keeping the column-0 anchor (strict parity), so #1531's P-7 premise stays true of them. Discharges **R-5 / AI-001** at the reader rather than only at the writer. Not in the Stage-4 matrix — see DEV-7. |
| `core/config/operator.toml.template` | — | **NO EDIT** | The Stage-4 matrix assigned #1842's toggles here. **They did not land here** — `platform-config.toml.template` is the platform-behavior surface and `operator.toml` is the operator-identity surface (ADR-022 split). The row is retained as a NO-EDIT so the "no second `automation_level`" constraint (R-5) stays visible: it is discharged by construction, since the two surfaces are different files. **CIAC-1.** |
| `core/settings.json.template` | E4 | **edit** | Per the #1355 design. |
| `core/standards/composition-surface-spec.md` · `core/standards/depersonalization-spec.md` | E3, E4 | **edit** | E3 amends under ADR-120; E4 reconciles after. **CIAC-2.** |
| `core/ADRs/ADR-120-claude-md-composition-surface-recategorization.md` | E3 | **add** | The formal-ADR gate for #3831. **Drafted as ADR-119; shipped as ADR-120** — a concurrent release claimed 119 on the mainline mid-run (DEV-6). The Stage-4 "contiguous 001..118 at the Stage-4 pin" re-verification is superseded by that claim; allocation is `anchor(origin/main) + 1` per ADR-115, not `max(claimed_set) + 1`. |
| `core/ADRs/ADR-121-settings-json-baseline-anchored-refresh.md` | E4 | **add** | The formal-ADR gate for #1355's expanded scope. **Drafted as ADR-120; shipped as ADR-121.** The Stage-5 note that "the spoke-proposed 121 was corrected to 120 to preserve contiguity" is **falsified** — 121 is the number this record actually holds, because the sibling above consumed 120 after the mainline took 119. Contiguity is a consequence of the anchor rule, never an input to it. |
| `docs/UPDATE.md` | E3, E4 | **edit** | E3: the Customizable row. E4: the Layer-2 overlay guidance. **CIAC-3.** |
| `release/governance/release-process.md` | E2 | **edit** | Config-gating + no-op degradation narrative. |
| `core/deploy/tests/run-install-regression.sh` | — | **NO EDIT** | `test_upgrade_config_durability.sh` is already registered in the explicit `REGRESSION_MEMBERS` array. #1531 AC-4 is satisfied by construction — a registration line would be a no-op diff on a shared file. |

### Deliverable-domain classification

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-05, domain: software }`

The matrix is entirely internal pmo-platform artifacts, so external sourcing is exempt. Dominant domain **`software`** (executable installer/updater code + its test harness); secondary **`governance`** (the spec, the two ADRs, `release-process.md`, `docs/UPDATE.md`).

## Contention Map

Baseline `c0122aa0`. `prior` = commits touching the path across all history.

| File | prior | #1531 | #1842 | #3831 | #1355 | Class | Resolution |
|---|---|---|---|---|---|---|---|
| `core/deploy/tests/test_upgrade_config_durability.sh` | 2 | ✓ | (fixture) | ✓ | ✓ | `line-range-overlap` | Strict E1→E3→E4; each appends a new named suite, never edits Suites F/G/T. **CIAC-4.** |
| `docs/scripts/setup-workspace.sh` | 14 | ✓ | ✓ | ✗ | ✓ | `line-range-overlap` | E1 → E2 → E4. |
| `core/standards/composition-surface-spec.md` | 5 | ✗ | ✗ | ✓ | ✓ | `line-range-overlap` | E3 → E4. **CIAC-2.** |
| `docs/UPDATE.md` | 3 | ✗ | ✗ | ✓ | ✓ | `append-pattern` | E3 → E4, different sections. **CIAC-3.** |
| `core/CLAUDE.md.template` | — | ✓ | ✗ | ✗ | ✗ | `single-pr` | Sole writer #1531 at Commit-1; #3831 reads its post-edit state later in the release. |
| `core/config/operator.toml.template` | 14 | (fixture) | ✓ | ✗ | ✗ | `single-pr` | Sole writer #1842. |
| `update.sh` · `compose.py` · `composition-surface-manifest.sh` · `test_compose.py` | 6 / 2 / 5 / 2 | ✗ | ✗ | ✓ | ✗ | `single-pr` | Sole writer #3831. Thin history on two — R-9. |
| `core/settings.json.template` | 7 | ✗ | ✗ | ✗ | ✓ | `single-pr` | Sole writer #1355. |
| `release/governance/release-process.md` | 41 | ✗ | ✓ | ✗ | ✗ | `append-pattern` | Sole writer in-release; highest-traffic file in the matrix — cross-release re-check at Stage 9. |

### Cross-PR and in-flight baseline

**Open-PR population at the Stage-4 pin: n=1 of 1 repo-wide** — a dependabot lockfile PR whose edit surface is disjoint from every path above (`EDITSET ∩ FCM = ∅`). **In-flight release roster: n=0 siblings** at `c0122aa0` / `2026-08-05T23:02:11Z`, pinned per audit-baseline discipline with both control arms reported. Per that discipline the zero is **not load-bearing alone** — Stage 9 Phase A6.6 re-measures before it is relied upon. **Structural blast radius: mover-set empty** — the matrix declares zero renames, relocations or deletions.

## Risk Register

| # | Risk | Sev | Rev. | Conf. | Mitigation / Owner |
|---|---|---|---|---|---|
| **R-1** | **ADR-120 is a hard gate on the release's largest card** (#3831 is 8 of 18 pts). | CRITICAL | EXPENSIVE | HIGH | **DISCHARGED** — ratified at Stage 5 Collective Review, scope CLAUDE.md-only. The pre-agreed deferral path was not needed. |
| **R-2** | **`composition-surface-spec.md` §2.3 forecloses a comment-fence for `settings.json`** — JSON has no comment syntax. An ADR-120 assuming a symmetric fence would contradict the spec it amends. | CRITICAL | EXPENSIVE | HIGH | **DISCHARGED** — ADR-120 scoped CLAUDE.md-only; §2.3 stands verbatim. #1355 then expanded to own the `settings.json` refresh under ADR-121. |
| **R-3** | **No release-identity mode declared (G3-19).** | HIGH | CHEAP | HIGH | **DISCHARGED** — declared at the Stage-4 gate: mode `versioned`, bump-class intent `minor`. |
| **R-4** | **Test-file contention: 3 of 4 cards claim `test_upgrade_config_durability.sh`** (thin history — weak regression signal). | HIGH | CHEAP | HIGH | Strict E1→E3→E4 append-only-new-suite ordering with coordinated suite letters P/C/S. **CIAC-4.** |
| **R-5** | **`block-autonomy-ceiling.sh` pinned SECTION-BLIND-GREP assumption.** The hook resolves the autonomy ceiling by `grep '^automation_level'` without parsing the `[automation]` section. A second same-named key silently mis-resolves it — **fail-open on a security control**. | HIGH | MODERATE | HIGH | #1842 introduces no `automation_level` key outside `[automation]`; #1531 Suite P asserts `grep -c '^automation_level' == 1`. **AI-001.** |
| **R-6** | **`update.sh schema_migrate()` only WARNS; it does not migrate.** New `operator.toml` keys therefore never reach an existing install. The no-op contract must default on an **absent** key, not a `false` one. | HIGH | CHEAP | HIGH | #1842's standalone verification asserts absent-key defaults. Confirmed independently by four spokes this release. **AI-002.** |
| **R-7** | **#1842's consumers ship in another milestone** (#1843/#1844 in milestone 262), so standalone correctness is unverifiable by integration. | MEDIUM | CHEAP | HIGH | The 4-assertion by-construction approach, graded at Stage 8. **AI-003.** |
| **R-8** | **#3831 rollback is asymmetric.** Reverting the platform does not un-write a managed-section fence already rendered into an operator's live `CLAUDE.md`. | MEDIUM | **EXPENSIVE** | HIGH | Route regeneration through the existing tamper-backup path so a bad regen is operator-recoverable. Stated as a rollback-infeasibility note in the Stage-9 briefing. |
| **R-9** | **Thin regression history on three matrix files** (2 prior commits each). | MEDIUM | CHEAP | HIGH | Stage 7 runs the **full** `run-install-regression.sh`, not only the new suites. |
| **R-10** | **Class under-ceremony.** | LOW | CHEAP | HIGH | **DISCHARGED** — re-classified `routine` → `novel` at the Stage-4 D-Gate. |
| **R-11** | **Redundant-work risk on #1531 AC-4.** | LOW | CHEAP | HIGH | **DISCHARGED** — `run-install-regression.sh` already registers the suite file. Recorded as **no harness edit needed**. |
| **R-12** | **`[paths].cowork_install_path` is blanked on every first install** — the resolver stores `[COWORK_INSTALL_PATH]`, the writer reads the registered `[COWORK_INSTALL_PATH_BASE]`. A faithful AC-3 comparator fails today. | HIGH | CHEAP | HIGH | Operator-approved in-scope fix (D-1531-D Option 1). **Both edits must land together** — the template drives `ACTIVE_TOKENS`. **AI-005.** |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#1531 × #1842 on `core/config/platform-config.toml.template` × `core/deploy/tests/test_upgrade_config_durability.sh`) — RESTATED at the pre-PR pass (operator decision D-N).** The Stage-4 form asked whether #1531's preservation gate covered "whatever `operator.toml` surface #1842 lands", and carried an unfilled `<the surface #1842 landed>` placeholder as its method. **#1842 landed no `operator.toml` surface at all** — its config went to `core/config/platform-config.toml.template` under a new `[git_release_automation]` section — so the coverage question is vacuous and the *real* surviving coupling is **non-interference**, which is what AI-001 / R-5 always named. The autonomy-ceiling readers resolve their dial with a **column-0 anchor**, so a second column-0 `automation_level` anywhere in the config surface #1531's gate round-trips would resolve ambiguously and silently drop the ceiling to its fallback. The constraint: **#1842's shipped surface introduces no key that collides with the `operator.toml` key namespace #1531's Suite P pins.** It is discharged *by construction* — the two surfaces are different files under the ADR-022 identity/behavior split — and the shipped `[git_release_automation]` header states the same disjointness ("different FILES … no shared key name or key prefix"). #1531's Suite P-7 holds the complementary half, asserting the dial resolves exactly once at column 0 in the seeded `operator.toml` fixture. *Method:* `grep -c '^automation_level' core/config/platform-config.toml.template` — expect zero. *Graded at Stage 9 on the merged PR.*
- [ ] **CIAC-2 (#1355 × #3831 on `core/standards/composition-surface-spec.md`):** after both land, the spec states **one** categorization for `settings.json` — no residual pairing of §2.3's "wholly Customizable … not Composition-surface" with an unreconciled refresh claim, and every amended clause cites its authorizing ADR (ADR-120 for the `CLAUDE.md` category **assignment**, ADR-121 for the Customizable category's update-time **behavior**; neither amends §2.3). **Method restated at the pre-PR pass:** the Stage-4 method was a three-alternate substring grep, which exits 0 whenever *any* alternate matches — and `COMPOSITION_SURFACE_FILES` always matches — so it passed unconditionally and could not fail. The falsifiable residue is the unreconciled hedge itself: the spec's "specified but not yet implemented" wording is what an unreconciled pairing would leave behind. *Method:* `grep -c 'not yet implemented' core/standards/composition-surface-spec.md` — expect zero. *Graded at Stage 9.*
- [ ] **CIAC-3 (#1355 × #3831 on `docs/UPDATE.md`):** the Customizable row and the Layer-2 overlay guidance agree — the file states one refresh mechanism for `settings.json` with no surviving contradiction between the two cards' edits. *Method:* `grep -n 'settings\.json\|settings\.local\.json\|not refreshed by' docs/UPDATE.md` — the two sections are mutually consistent. *Graded at Stage 9.*
- [ ] **CIAC-4 (#1531 × #3831 × #1355 on `core/deploy/tests/test_upgrade_config_durability.sh`):** the merged file runs green end-to-end with all three new suites present **and** pre-existing Suites F, G and T still passing, with no suite-letter collision, and the HARD sandbox invariant (`mktemp -d` root redirection, trap cleanup, before/after per-file-hash manifest of the real `$HOME/.claude` byte-identical) holding across the combined run. *Method:* `bash core/deploy/tests/run-install-regression.sh` exits 0 and its summary shows no net assertion loss. *Graded at Stage 9.*

## Verification Plan

### Per-issue AC → verification method

**#1531 — non-interactive fresh install + `operator.toml` preservation gate**

| AC | Method | Expected observable |
|---|---|---|
| AC-1 fresh non-interactive install | reproduction-and-observe — Suite P arms P-1/P-2 with stdin closed (`0<&-`) and no pre-existing tokens file | exit 0; `operator.toml` written; state file `verification_passed = true`; **zero** unresolved `[TOKEN]` markers in the rendered `CLAUDE.md` **and** zero empty managed `[identity]` keys |
| AC-2 required token with no default fails loud | reproduction-and-observe — Suite P arm P-3 with `GIT_CONFIG_GLOBAL` pointing at an empty file | non-zero exit; stderr contains the literal `[OPERATOR_NAME]`; **no `operator.toml` written** (fail-before-write) |
| AC-3 no table and no key dropped | file-content assertion — Suite P arms P-4…P-7 over a fully-populated fixture, fresh + re-bootstrap | `comm -23 before after` empty on the `SECTION\|key=rawvalue` extraction; table-set equality; type fidelity unquoted; `grep -c '^<key>' == 1` for each consumer-read key |
| AC-3 probe validity | negative control — Suite P arm P-8 | the comparator **reports a difference** against a deliberately mutated copy (one table deleted, one key indented) — a green suite must be provably able to fail |
| AC-4 gate runs in the existing harness | system-state assertion | `grep -n 'test_upgrade_config_durability.sh' core/deploy/tests/run-install-regression.sh` resolves in the explicit `REGRESSION_MEMBERS` array; **no edit was required** |

**#1842 — git-automation config surface.** Standalone no-consumer verification, four assertions in catch order: (1) **absent-key** default, not false-key default — the production state of every existing install, since `schema_migrate()` never migrates; (2) off-path no-op is *silent*, not merely harmless — no error, warning, or non-zero exit; (3) the new surface survives `write_operator_toml` unchanged; (4) autonomy-ceiling non-interference — `grep -c '^automation_level' == 1` and the resolved ceiling unchanged from pre-change.

**#3831 — CUSTOMIZABLE refresh.** ADR-120 `status: Accepted`; sandboxed perturbed managed-section source → `update.sh` exits `EX_OK 0` (not `EX_NOCHANGE`); operator content outside the fence byte-identical; `compose.py` emits the markdown marker form; resolver correct under all precedence paths.

**#1355 — `settings.json` operator-key durability.** Positive **and** negative arms: with an operator key present → the key survives or is migrated; with no operator keys → clean exit and **no** warning (the negative arm is what catches a mis-firing guard). Build against **4** missing registrations plus the `Stop` block — the corrected measurement, taken against `~/Claude/.claude/settings.json` (the deployed target), not `~/.claude/settings.json`.

### Release-scoped verification

- `core/deploy/deploy.sh --check` — full run at Stage 7; every FAIL either fixed or explained.
- Doc-link integrity (Check 14) on all modified `.md` files.
- Full `bash core/deploy/tests/run-install-regression.sh` — all registered suites, not only the new ones (R-9).
- Skill-package freshness: **no rostered skill source is in the matrix**, so no `.skill` rebuild is owed. Re-check at Stage 7 against the landed diff.

### Anti-vacuity discipline (release-wide)

Every count in this release carries its denominator, a sensitivity arm with an observed non-zero, and a specificity arm. **A zero whose control arm also returned zero is a BROKEN PROBE, not a clean result.** Three vacuity traps are specifically named:

1. **Exit code alone** — the installer's own verification gate rejects *unresolved* `[TOKEN]` markers only; an **empty substitution leaves no marker** and passes. Every AC-1 assertion therefore also probes non-emptiness.
2. **Section-aware parsing** — a section-aware `awk` assertion passes on an indented re-emit that four line-anchored production consumers would miss. Probe with the consumers' own shape.
3. **`yes ""` is not stdin-closed** — it supplies infinite empty lines and never EOF. That is an interactive simulation; the AC-1 assertion closes the descriptor.

## Rollback Strategy

**Whole-release reversibility: MODERATE / Confidence HIGH.**

- **Reversible (all git-revertable):** #1531, #1842 and #1355 are additive and content-only; `git revert -m 1` of the release PR restores each file's bytes. No state migration.
- **Asymmetric — #3831 (EXPENSIVE):** once a managed-section fence is rendered into an operator's live `CLAUDE.md`, reverting the platform does not un-write the operator's file. Mitigated — not undone — by routing regeneration through the existing tamper-backup path so a bad regen is operator-recoverable. This is a rollback-**infeasibility** note, stated explicitly in the Stage-9 briefing, not a claim of clean revert.
- **Deploy impact:** none in the #1531 slice — no `{core,operations,release}/skills/`, `packages/`, or harness entries. Re-check at the release's end against the whole landed diff.

## Operator Decisions (D-Gate Block)

| ID | Decision | Verdict | Rendered |
|---|---|---|---|
| D-1 | Release plan + Release Outcome Statement | **APPROVED (scope-lock)** — authorizes scaffolding, the description `[ADJUST]`s, the action items and the scope-lock emission; authorizes no build, no ADR decision, no merge | 2026-08-05 |
| D-2 / D-ReleaseClass | Release Class | **`routine` → `novel`** — all four `routine` triggers falsified, two `novel` triggers fire. Stage-9 depth → **Deep**, engagement → **Standard** | 2026-08-05 |
| D-3 / D-QuotaBudget | Quota-budget wave shape | **2+2 split** — the heaviest spoke never shares a window slice with a second above-median spoke. A default, re-validated at every wave, not a commitment | 2026-08-05 |
| D-C | Branch topology | **SINGLE** — one branch, one PR, one merge | 2026-08-05 |
| D-Concurrency | Stage-6 parallelism posture | **P0 fully-serial** | 2026-08-05 |
| D-Version | Version determination | **`v4.13`** — rule-computed next-free, a recorded determination and **not** an operator gate. Binds at the Stage-12 claim | 2026-08-05 |
| D-Identity | Release-identity mode | **`versioned`**, bump-class intent `minor` (closes G3-19) | 2026-08-05 |
| D-1531-A | Non-interactive mechanism | **`--non-interactive` flag** — names the *invariant* both ACs assert. `--accept-defaults` rejected: it names a value policy that promises exactly what AC-2 forbids. Env twin explicitly deferred, not adopted | 2026-08-06 |
| D-1531-B | Default table + failure contract | Declared per-token defaults — git-derived for NAME/EMAIL/GIT_EMAIL, literal constants for ROLE_TITLE/ORGANIZATION; **validate the default**; `exit 1` naming the token; the `*` fallback arm is the durable AC-2 path | 2026-08-06 |
| D-1531-B′ | AC-1 restatement | **ADOPTED** — "each token's **declared** non-interactive default", not "template defaults". The two ACs were otherwise mutually unsatisfiable | 2026-08-06 |
| D-1531-C | Gate scope | Assert **Δ1–Δ4** (type fidelity · `passthrough()` branch · column-0 anchoring · managed-key durability). Do **not** assert comments, `[[array-of-tables]]`, duplicate sections, or multi-line arrays — those are documented or separately routed | 2026-08-06 |
| D-1531-D | `cowork_install_path` blanking | **Option 1 — fix in-scope.** Two one-token edits that must land together (AI-005) | 2026-08-06 |
| D-1531-E | Gate placement | **Extend** `test_upgrade_config_durability.sh` — no new harness, no `REGRESSION_MEMBERS` edit | 2026-08-06 |
| D-1531-F | Suite-letter coordination | **P** = #1531 · **C** = #3831 · **S** = #1355 | 2026-08-06 |
| D-D | ADR-120 (drafted as ADR-119) | **Status `Proposed` → `Accepted`.** Scope **CLAUDE.md only**; mechanism = **extend `COMPOSITION_SURFACE_FILES`**, not a new array. Overturns #3831's own AC-2 — Stage 5 working as intended | 2026-08-06 |
| D-E | #1355 scope | **EXPANDS to own the `settings.json` refresh** (Tier 2 `[SCOPE CHANGE]`), carrying **ADR-121** (drafted as ADR-120). Keeps the Outcome Statement true as written rather than narrowing it | 2026-08-06 |
| — | #1842 reader semantics | **Strict-parity reader.** The permissive variant would have *raised* the ceiling `recommend → bounded_auto` on 2 of 14 fixtures for an operator who changed nothing — a silent security-posture widening delivered by an update. Rejected on evidence | 2026-08-06 |
| — | #1842 ADR requirement | **None required.** The Stage-5 corollary drawn from this — *"which is why ADR-120, not 121, is free for #1355"* — was **falsified in flight** and is corrected here: a concurrent release claimed 119 on the mainline, so #3831's record took 120 and #1355's took **121** after all. #1842 needing no ADR remains true; the number it freed was consumed by the shift, not by #1842. See DEV-6 | 2026-08-06 |
| **D-N** | **CIAC-1 restatement** (pre-PR pass) | **RESTATED to the surface that actually shipped.** #1842 landed its config in `core/config/platform-config.toml.template` `[git_release_automation]`, **not** `operator.toml`, so the Stage-4 coverage question was vacuous and its method carried an unfilled `<the surface #1842 landed>` placeholder that made `verify-release-plan.sh` exit 3. Restated as the **non-interference** constraint AI-001 / R-5 always named, with an executing method. CIAC-2's method was restated in the same pass for the same class of defect — it was a substring grep that could not fail | 2026-08-07 |

## Action Items

| ID | Item | Owner | State |
|---|---|---|---|
| **AI-001** | #1842 must not introduce a second `automation_level` key (or the hook must become section-aware) | #1842 design + DT | **Closed — BOTH limbs satisfied.** #1842 introduced no `automation_level` key at all (its surface is a different file entirely — **CIAC-1**), *and* both autonomy-ceiling readers were hardened from section-BLIND to section-AWARE, keeping the column-0 anchor so #1531's P-7 premise stays true of them. Asserted by Suite P-7 |
| **AI-002** | The no-op contract defaults on an **absent** key, not `false` | #1842 | OPEN — satisfied by the shipped resolver; verified at Stage 7/8 |
| **AI-003** | Stage 8 verifies #1842 standalone with no consumer present | Stage 8 | OPEN |
| **AI-004** | Stage 9 A6.6 re-measures the in-flight sibling roster | Stage 9 | OPEN |
| **AI-005** | The two cowork-token edits MUST land together — `core/CLAUDE.md.template` drives `ACTIVE_TOKENS` | #1531 (E1) | Closed at Commit 1 |

## Deviation Log

**DEV-1 — the pinned baseline moved before Engineering started.** Stage 4 pinned `origin/main` at `c0122aa0`; the release branch is cut from `86bc649e` — **7 commits of drift**, the `v4.12` close-out chain (`release-notes-and-learnings` Stage-13 corpus update plus a re-emit resolver fix). Resolved by construction: the branch is cut from post-merge `main`, and every count in this plan that depends on the tree is restated against the Commit-0 baseline. Verified non-colliding with this release's matrix: the drift touches `release/releases/` corpus files and `release/tools/reemit-release-bodies.sh`, none of which appear in the File Change Matrix.

**DEV-2 — R-1 and R-2 were discharged before Engineering opened, not carried.** Both CRITICAL risks were gated on ADR-120, which was ratified at Stage-5 Collective Review with a CLAUDE.md-only scope. Recorded rather than deleted so the Stage-9 reviewer sees that the two highest-severity entries were closed by a decision, not by omission.

**DEV-3 — the #3831/#1355 mechanism inverted at Stage 5.** ADR-120 was ratified as an **extension of `COMPOSITION_SURFACE_FILES`**, not the new `CUSTOMIZABLE_FILES` array the Stage-4 plan and #3831's own AC-2 both assumed. The Stage-4 File Change Matrix entry "Add the `CUSTOMIZABLE_FILES` array" is superseded accordingly, and #1355 **expanded** (Tier 2 `[SCOPE CHANGE]`) to own the `settings.json` refresh rather than the release narrowing its Outcome Statement.

**DEV-4 — #1531 gained a fifth file the Stage-4 matrix does not list.** `core/CLAUDE.md.template` enters the matrix under D-1531-D Option 1. Contention is **0** — no sibling card touches it — but #3831 reads its post-edit state later in the release, so the E1 edit is deliberately kept to a single token.

**DEV-5 — a hub measurement was taken against the wrong file and is corrected here.** The `settings.json` registration gap was first measured against `~/.claude/settings.json` (Claude Code's user-global config, which carries no `hooks` key). The deployed target is `~/Claude/.claude/settings.json`. Re-measured: **18** distinct `.sh` registered in the template vs **14** deployed — **4** missing plus the `Stop` block, not 3. The decision is unaffected; the build target is not.

**DEV-6 — both ADR numbers shifted +1 mid-run, and the shift DID require a citation sweep.** Drafted at Stage 5 as ADR-119 (#3831) and ADR-120 (#1355). A concurrent release — the `ci-selftest-and-check-hardening` line — claimed **119** on the mainline before either draft was written to disk, and under ADR-115 next-free is `anchor(origin/main) + 1`, so both advanced: #3831's record ships as **ADR-120**, #1355's as **ADR-121**. `release/ADRs/ADR-119-selftest-coverage-is-discovered-with-a-committed-manifest-floor.md` is that other release's record and is **unrelated to this one** — it must not be repointed or removed.

Both shipped records state that the renumber "required no citation sweep". **That claim was false and is corrected in the records themselves.** It held for the ADR *files* — neither was ever created at its drafted number — but not for this plan, which had already been written at Commit 0 against the drafted numbers and carried **24** `ADR-119` references and **10** `ADR-120` references, all of them meaning the two in-release records, plus **two ADR file paths that never existed** in the machine-readable File Change Matrix. Every one was re-classified and repointed at the pre-PR pass; **zero** referred to the real mainline ADR-119. The corpus itself never drifted — `composition-surface-spec.md`, `setup-workspace.sh` and the test suites were authored after the shift and already cite 120/121 correctly. The lesson is narrow and worth keeping: a renumber's blast radius is the set of artifacts already written against the old number, which at Commit-0-authored-plan timing is never empty.

**DEV-7 — the File Change Matrix was reconciled to the landed diff at the pre-PR pass.** The matrix declares itself a machine-readable path list "for deterministic extraction by Stages 7 / 8 / 9", so a stale list mis-aims the reviewer rather than merely reading oddly. Measured against `git diff --name-only origin/main...HEAD` (n=**32**): **19** landed paths were absent from the list and **3** listed paths were never touched. The three phantoms were the two non-existent ADR filenames (DEV-6) and `core/config/operator.toml.template` — the surface the Stage-4 matrix assigned #1842's toggles to, which they did not land on. The absent 19 are the surfaces the four Stage-5 designs grew past the Stage-4 matrix: the platform-toggle library and its suite plus the CI smoke that runs it, the schema and operator-reference rows for the new config section, the two autonomy-ceiling readers and their suites, the composition primitive and its unit suite, `deploy.sh` / `validate-install.sh` / the end-to-end suite, `depersonalization-spec.md`, and the plan file itself. The list now matches the tree exactly.

## Out of Scope — Logged, Not Acted On

1. **Check 44(b) cannot see `[CLAUDE_*]` / `[COWORK_*]` tokens.** Its probe is `\[OPERATOR_[A-Z0-9_]+\]` × `--include='*.md'` × `{core,release,operations}` — it misses the `.md.template` extension, the `docs/` root, and `.sh` files entirely. This is the mechanism that would have caught R-12. Next-release issue.
2. **Multi-line arrays are corrupted into invalid TOML** by `write_operator_toml`'s single-line parser — `k = [` survives and the continuation lines are dropped. Undocumented, unlike the `[[array-of-tables]]` collapse which is documented on purpose. Next-release issue.
3. **A fresh install never receives `[adapters]` / `[projects]` / `[methodology]` / `[automation]` / `[session_retro]`** — `operator.toml.template` is not in the composition-surface manifest, so those consumers run on in-code fallbacks. Empirically confirmed; routed to #1842's absent-key contract rather than built here.
4. **`update.sh schema_migrate()` performs no migration** — it warns and continues. A general config-surface gap, independently confirmed by four spokes this release. Worth its own intake ticket.
5. **`refresh_hooks_flow` never persists its checksum baseline**, and `setup-workspace.sh` states "14 files" against a 19-entry manifest. Surfaced at Stage 5, deliberately not bundled.

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing. Populated as each member lands and **refreshed by the final Engineering slice** — this is the Commit-0 initialization.*

### Outcome

The install and update path stops losing operator configuration and stops requiring a human at the keyboard. A fresh install can now complete with stdin closed, taking each token's declared default and failing loudly by name when a required one has none. An `operator.toml` carrying operator-added tables round-trips under a regression gate that probes with the same line-anchored shape the production consumers use, so it fails exactly when they would.

### Issues delivered

| Issue | Outcome | Status |
|---|---|---|
| #1531 | `--non-interactive` fresh install + `operator.toml` preservation gate (Suite P) + the `cowork_install_path` blanking fix | IN PROGRESS |
| #1842 | Operator config surface for git-native release automation, degrading to a no-op on an absent key | PENDING |
| #3831 | `update.sh` refreshes the Customizable files, under ADR-120 | PENDING |
| #1355 | Managed `settings.json` operator keys migrated rather than dropped, under ADR-121 | PENDING |

All four are **marked as closed at Stage 13** via the release close-out; none closes at merge.

### Key decisions

- **ADR-120 ratified CLAUDE.md-only**, extending `COMPOSITION_SURFACE_FILES` rather than minting a parallel array — which decoupled #1355 from #3831 and let it expand to own the `settings.json` refresh under ADR-121.
- **`--non-interactive`, not `--accept-defaults`** — the flag names the invariant both acceptance criteria assert, where the alternative would have promised exactly the silent substitution one of them forbids.
- **The preservation gate probes with the consumers' own shape.** A section-aware assertion would have passed on an indented re-emit that four production readers — including two that resolve the autonomy ceiling — would have missed.
- **#1842 takes the strict-parity reader.** The permissive variant silently *raised* the autonomy ceiling for an operator who changed nothing.

### Reversibility

**MODERATE / Confidence HIGH.** Three of four members are additive and content-only and revert with `git revert -m 1`. #3831 is asymmetric: reverting the platform does not un-write a managed-section fence already rendered into an operator's live `CLAUDE.md`; regeneration routes through the tamper-backup path so a bad regen is operator-recoverable.

### Downstream impact

*(Populated at Stage 6 completion by the final Engineering slice.)*

### Cross-references

Milestone #239 · Stage-4 plan #4776 · Stage-5 designs #4778 / #4782 / #4786 / #4790 · Stage-6 sub-tasks #4779 / #4783 / #4787 / #4791 · Stage-9 review #4794 · user-facing note authored at Stage 13 to `release/releases/notes/`.

## Identity Note (ADR-092)

This plan file and its branch are **slug-primary**. The `{{RELEASE_VERSION}}` token in the Header is deliberately left unresolved: `claim-version.sh --stamp-slug` resolves it to the won tag on the compare-and-swap win path and renames this file to the version-keyed form in the same stamp commit. The token is load-bearing, not decorative — the stamp pre-flight **HALTs the claim** on a plan that carries none, and the slug-primary conformance check keys its pre-claim window on the token's presence.

The concrete version named in § Commit-0 Version Re-Verify is a **dated measurement**, not an identity binding — it records what was observed and computed at Commit 0 and is deliberately NOT tokenized, because resolving it at claim time would rewrite the evidence. Until the claim lands, no downstream artifact may treat any version as claimed for this release.
