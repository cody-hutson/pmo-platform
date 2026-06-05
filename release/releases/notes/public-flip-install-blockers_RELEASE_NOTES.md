---
version: public-flip-install-blockers
date: 2026-06-04
type: note
issues: ["#606", "#607", "#608", "#609", "#610", "#611", "#612", "#613", "#614", "#615", "#144", "#233", "#242", "#243", "#265", "#632"]
pr: "#627"
links:
  plan: null
  log_anchor: "#public-flip-install-blockers"
reversibility-tier: CHEAP
themes: ["cluster:bootstrap", "cluster:session", "cluster:validate", "cluster:update"]
summary: "Fresh-install / onboarding blockers gating the private->public flip. Fixes the headline launch blocker (a fresh install deployed ZERO skills) and the no-Cowork hard-fail, plus a config-first install-path resolver (ADR-013), honored sandbox overrides, two-hash managed-section tamper detection (ADR-014), a wired update.sh no-change exit, validate-install.sh false-positive repairs, deploy.sh --check/--report fixes, count-convention reconciliation, .version reconciliation to the v3.x tag scheme, deploy-test harness hygiene, and a repaired-and-wired version-skew notifier. Version-less release (no vX.Y, no git tag); #632 folded in as a post-GO fast-follow; #265 verified no-op."
requires_action: false
breaking: false
components: ["install.sh", "core/deploy/deploy.sh", "core/deploy/compose.py", "core/hooks/notify-version-skew.sh", "update.sh", "docs/scripts/validate-install.sh", "core/rules/skill-deployment.md", "core/settings.json.template", "ADR-013", "ADR-014"]
followups: []
---

# Fresh-install & onboarding blockers — zero-skills fix, no-Cowork deploy, config-first install path, tamper-aware update

2026-06-04 · public-flip-install-blockers (version-less)

This release closes the fresh-install and onboarding blockers that gate the private->public flip. The headline launch blocker was that a brand-new user running the documented install got **zero skills** deployed; the second was a hard-fail on any machine without an active Cowork session. Both are fixed, along with a cluster of install-path resolution, sandboxing, validation, update-safety, and deploy-tooling defects surfaced by the pre-flip onboarding sweep. It is internal install/onboarding tooling hardening — no change to in-session platform behavior — and it ships **version-less** by operator decision: no `vX.Y` is assigned and no git tag is cut; `.version` is reconciled to the latest-tag (`v3.x`) scheme independently.

## Who this affects

- **Any new user installing from a fresh clone.** A fresh `./install.sh` now deploys the full skill roster to `~/.claude/skills/` instead of zero skills, on a machine with or without an active Cowork session.
- **Anyone running on a machine without Cowork.** Skill deployment no longer hard-fails when no Cowork path exists; the user-local mirror is reached and the full roster lands.
- **Anyone running `validate-install.sh`, `deploy.sh --check/--report`, or `update.sh`.** Several false-positives and a non-wired exit path are corrected, so these report real state and exit with the documented codes.
- **Anyone relying on sandbox overrides (`--workspace-root` / `--config-root`).** The overrides are now honored through skill deployment (Phase 2), not just Phase 1.

## What changed for everyone using the platform

### Fresh-install bootstrap

- **Fresh install deploys the full skill roster, not zero skills (#606).** Phase 2 skill deployment used release change-detection (an empty diff on a clean clone -> nothing to deploy) instead of a full-roster deploy. Bootstrap now deploys the complete roster on a fresh install. *Why it matters:* this was the launch blocker — a new public user got 0 skills.
- **Manual-mode bootstrap installs `.skill` packages (#144).** `deploy.sh` manual mode skipped `.skill`-package installation (the initial bootstrap mechanism gap); the bootstrap path now installs them.

### Install-path resolution (SESSION)

- **Config-first install-path resolution ladder — ADR-013 (#233, #243, #607).** `detect_install_path()` now resolves via a config-first ladder (reading `operator.toml`) with structured terminal output, replacing the session-tiebreaker heuristic. The hardcoded fallback session-path and the literal session UUID that could reference an orphaned session are removed. A `COWORK_AVAILABLE` flag-guard makes a session-less machine deploy the user-local skill roster instead of hard-failing (#607). Check-8 is re-pointed to the `operator.toml` config.

### Sandboxing & honored overrides

- **Sandbox overrides honored through skill deploy (#611).** The documented sandboxing was Phase-1-only — skill deployment ignored `--workspace-root` / `--config-root`. The overrides are now honored in Phase 2 (HONOR override), so a sandboxed deploy stays inside the sandbox.

### Validation (`validate-install.sh`)

- **A5 no longer false-positives on legitimate vocabulary (#608).** The A5 check flagged legitimate `CLAUDE.md` vocabulary as unresolved tokens; it now distinguishes real unresolved tokens from intentional vocabulary.
- **A9 checks the correct skills path (#609).** A9 checked the workspace skills path instead of the `$HOME` install path; it now checks the path skills actually deploy to.

### Update safety (`update.sh`)

- **Two-hash managed-section tamper detection — ADR-014 (#612).** Managed-section tampering was silently ignored and the documented `.backup-tampered-` was never implemented. `update.sh` now detects managed-section tampering via a two-hash scheme and writes the documented tamper backup before overwriting. *Why it matters:* this strengthens the update-time integrity guarantee — a hand-edited managed section is detected and preserved instead of silently clobbered.
- **`EX_NOCHANGE` (exit 64) wired (#613).** The documented no-change exit code was not wired; `update.sh` now exits 64 when there is nothing to apply.

### Deploy tooling (`deploy.sh`)

- **`--check` no longer false-DRIFTs sync-map references; `--warn` exits 0 (#610).** `deploy.sh --check` false-DRIFTed on sync-map-injected references and `--warn` did not exit 0; both are corrected.
- **`--report` continues past skill FAILs — verified no-op (#265).** The intended behavior (a complete drift report that does not stop at the first skill FAIL) was already in place after the earlier re-version work; verified no code change required this release.

### Counts, version, and harness hygiene

- **SKILL_LIST count convention reconciled (#242).** The `deploy.sh` SKILL_LIST count and the `skill-deployment.md` "custom" count were reconciled to a single convention.
- **`.version` reconciled to the v3.x tag scheme (#614).** `.version` (previously `v1.04`) is reconciled to the latest-tag (`v3.x`) scheme, and the release-tagging convention for the public flip is documented. This release itself is version-less and untagged; the reconciliation is independent of it.
- **Deploy-test harness hygiene (#615).** The composition-surface count drift (14<->17) is reconciled and the CI install-tests workflow now runs the full test set rather than 2 of 5.

### Version-skew notifier (folded-in fast-follow)

- **`notify-version-skew.sh` repaired and wired (#632).** The version-skew notifier was non-functional (a `REPO_ROOT` path bug) and was not wired into the settings template. It now uses a 2-candidate `.version` resolver, ships a snapshot via `setup-workspace`/`update`, is wired into `SessionStart` via `core/settings.json.template`, and has a regression test wired into the install-tests CI. This makes #614's `.version` reconciliation functional. Folded into this release as a post-GO fast-follow per operator direction (the standalone main-targeted PR was superseded).

## Operator action

None. This release is internal install / onboarding tooling hardening. There is no configuration to set and no in-session behavior change. Public-distribution operators inherit the working fresh-install path automatically; the `.version` reconciliation and the version-skew notifier wire in with no manual step.

## Known limits

- **Version-less by design.** No `vX.Y` is assigned and no git tag is cut for this release; it ships under the themed slug `public-flip-install-blockers`. The corpus row, index, and digest entry below carry the slug in place of a version, and the Tag column is `(none)`. The `.version` reconciliation (#614) is to the independent v3.x tag scheme and does not version this release.
- **Outcome window.** Per the `novel` release class, a 30-day Stage 13 outcome window applies — the fresh-install / no-Cowork fix is confirmed in DT/QA (8/8 suites, 72 assertions, full acceptance matrix PASS) and is monitored for a real first-public-install signal over the window.

## Process note

This release shipped single-branch (D-C SINGLE) via one release PR (#627), Release Class `novel`, version-less per operator decision at Stage 4. DT/QA ran 8/8 test suites (72 assertions) with the full acceptance matrix PASS and security strengthened by the #612 two-hash managed-section tamper detection. #632 (the version-skew notifier) was folded into the release branch as a post-GO fast-follow — the repaired hook was wired and its regression test added to CI, with #627 CI green on the new head — superseding the standalone main-targeted PR. #265 was carried as a verified no-op (the `--report` continue-past-FAIL behavior was already present from the earlier v18->v1.0x re-version; no code shipped for it). The release is version-less and untagged; there is no signed-annotated tag and no GitHub Release for it.

## Reversibility

CHEAP / HIGH. The changes are localized to the install / deploy / update tooling and its tests plus two ADRs and the skill-deployment rule; `git revert c0480974f42fc12e4c3e87b220d8d4850eb24190` reverts the whole release (single merge commit), and individual clusters revert cleanly. No schema migrations, no breaking interfaces, no data changes; the `.version` reconciliation is a one-line value change.

### References

- Milestone: public-flip-install-blockers
- Release PR: #627 at `c0480974f42fc12e4c3e87b220d8d4850eb24190`
- ADRs: ADR-013 (config-first install-path session resolution) · ADR-014 (managed-section two-hash tamper detection)
- Issues — bootstrap: #606 · #144; session: #233 · #243 · #607; sandbox: #611; validate: #608 · #609; update: #612 · #613; deploy/count/version/hygiene: #610 · #242 · #614 · #615; folded-in fast-follow: #632; verified no-op: #265
- Tag: (none) — version-less release, no git tag cut
