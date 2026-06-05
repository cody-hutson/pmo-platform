<!-- reference-durability: allow-link -->
# Harness Deployment — pmo-platform

## What is a "harness artifact"?

A **harness artifact** is a workspace-global runtime tool (bash entrypoint + slash command + supporting docs/config) that lives outside the skill system but is governed and deployed identically: source-of-truth in git, deploy-script-driven sync to the runtime path. Examples: `account-switcher` (Mac-app multi-account launcher with `clone-prefs` mirroring).

Harness artifacts differ from skills in that they are **not** invoked by Claude as part of a chained PMO workflow. They are operator-facing utilities (slash commands + bash) that interact with the macOS / Electron / filesystem surface. The deploy mechanism is symmetric with skills (`pmo-platform/skills/<name>/` → installed location); the operator-state preservation policy is the additional concern unique to harness.

## Paths

- **Git source:** `pmo-platform/harness/<name>/` (in repo)
- **Runtime location:** `~/.claude/<name>/`
- **Slash command source:** `pmo-platform/harness/<name>/commands/*.md`
- **Slash command runtime:** `~/.claude/commands/<file>.md`

Slash commands deploy to the workspace-global commands directory (NOT under the harness's own runtime dir) so they are invocable as `/<file>` from any Claude Code session.

## Selected Deployment Mechanism

- **Mechanism:** S-2 (direct file copy) — same as skill deployment per `skill-deployment.md`
- **Implemented in:** `deploy.sh` `deploy_harness_artifact()` function, called from `cmd_deploy` for every entry in `HARNESS_LIST` that matches a deploy invocation (auto-detected from git diff OR manual via `./deploy.sh --deploy <name>`)
- **Verification:** post-copy `diff -q` against source; failures appended to `FAILURES` array and surfaced as deploy errors

## Tracked Harness Artifacts

Current roster: see `deploy.sh` `HARNESS_LIST` array. `deploy.sh --check` Check 11 asserts every artifact directory under `pmo-platform/harness/` has a runtime counterpart at `~/.claude/<name>/` and that source files (excluding the `config.toml` template + operator-state allowlist) match runtime byte-identically.

## Operator-State Preservation Policy

This is the load-bearing difference between harness deploy and skill deploy. Harness artifacts mutate runtime state during normal operation (logs, runtime markers, operator-customized config). The deploy mechanism MUST NEVER overwrite that state.

### File classification

| File class | Source presence | Deploy behavior | Drift check |
|---|---|---|---|
| `*.sh` (executables) | YES (canonical) | Overwrite target; preserve `+x` bit | Byte-identical match required |
| `*.md` (docs, top-level) | YES (canonical) | Overwrite target | Byte-identical match required |
| `commands/*.md` (slash commands) | YES (canonical) | Overwrite to `~/.claude/commands/` | Byte-identical match required |
| `config.toml` (TEMPLATE) | YES (defaults / placeholder) | **Only if target doesn't exist** (initial deploy); never overwrites operator's customized runtime instance | Presence-only check (template vs. customized values diverge by design) |
| `swap-history.log` | NO | NEVER touched (target-only operational log) | Skipped (target-only file) |
| `.statusline-marker` | NO | NEVER touched (target-only runtime state) | Skipped (target-only file) |

### Operator-state allowlist

The list of target-only filenames that the deploy mechanism must never touch lives in `deploy.sh` `HARNESS_OPERATOR_STATE` array. To register a new operator-state file for a future harness artifact, append the filename and update the table above.

### config.toml smart-merge — current behavior + future direction

The deploy mechanism ships **only-if-not-exists** semantics: the source `config.toml` is a template with placeholder values; if the runtime instance exists, deploy preserves it verbatim. If the template adds new keys in a future release, the operator must merge manually (the deploy log emits `PRESERVED:` so the operator knows the template changed but their instance was kept).

A future hardening pass (out of scope) may introduce true TOML smart-merge (source provides defaults; operator's existing values preserved on key conflicts). The behavioral contract is the same — operator customizations always preserved — so the only-if-not-exists implementation is a forward-compatible subset of the smart-merge target.

## Deployment Steps (Post-Merge)

1. **Auto-detected deploy** — `./deploy.sh --deploy` detects changed harness artifacts via tag-based git diff and includes them alongside changed skills.
2. **Manual deploy** — `./deploy.sh --deploy account-switcher` (or any other registered harness name). Manual mode validates the artifact exists in `pmo-platform/harness/<name>/` before proceeding.
3. **Verify deployment** — invoke the slash command in Claude Code or run the bash entrypoint directly; confirm expected behavior.
4. **Drift check (optional)** — `./deploy.sh --check` Check 11 reports any source/runtime divergence on the next run.

## Drift Check Semantics

`deploy.sh --check` Check 11 (always-enforce) validates:

1. **Every `HARNESS_LIST` entry has a source dir** at `pmo-platform/harness/<name>/`. Missing source dir → FAIL.
2. **Every `HARNESS_LIST` entry has a runtime dir** at `~/.claude/<name>/`. Missing runtime dir → DRIFT (with remediation: `./deploy.sh --deploy <name>`).
3. **Source files (excluding `config.toml` + operator-state)** match runtime byte-identically. Any mismatch → DRIFT.
4. **`config.toml`** runtime presence is checked (operator-state preservation means content may diverge by design); missing runtime config.toml → DRIFT (initial deploy needed).
5. **Slash commands** at `pmo-platform/harness/<name>/commands/*.md` match `~/.claude/commands/<file>.md` byte-identically. Missing or divergent → DRIFT.

The mirror-pair sync between `.claude/rules/harness-deployment.md` and `pmo-platform/engineering/rules/harness-deployment.md` (this file) is enforced by `deploy.sh --check` Check 9 (rules-mirror sync).

## Adding a New Harness Artifact (Operator Workflow)

1. Create source directory: `mkdir -p pmo-platform/harness/<name>/commands`
2. Author the bash entrypoint (`<name>.sh` or similar), README, AUTO_*.md notes, and slash command (`commands/<name>.md`)
3. If the artifact has a `config.toml`, author it as a TEMPLATE with placeholder values (no operator-identifying data)
4. Update `deploy.sh` `HARNESS_LIST` to include the new artifact name
5. If the artifact creates additional operator-state files at runtime (logs, markers, etc.) that the source does not ship, append those filenames to `deploy.sh` `HARNESS_OPERATOR_STATE`
6. Update the file-class table in this doc to reflect any new file class
7. Run `./deploy.sh --deploy <name>` to perform initial deploy; verify with `./deploy.sh --check`
8. Mirror the governance doc edits (this file ↔ `.claude/rules/harness-deployment.md`) and run `deploy.sh --check` Check 9 to confirm

## Account-switcher (relocated)

`account-switcher` was the inaugural harness artifact when this governance shipped. It was extracted to its own private repo at `[OPERATOR_GITHUB]/claude-account-switcher` in the extraction release — see Repo Cleanup + Modular-Monolith initiative. At extraction time it was the only registered harness artifact, so `HARNESS_LIST=()` is empty in `core/deploy/deploy.sh`.

This file governs **remaining harness artifacts** (none at extraction time; future entries land under `harness/<name>/` at repo root per Source convention above). The operator-state preservation policy, drift-check semantics, and deployment steps below apply unchanged when a new harness artifact ships.

For account-switcher itself (Mac-app multi-account launcher with `clone-prefs` mirroring), see `[OPERATOR_GITHUB]/claude-account-switcher` — README at the repo root documents install, configuration, and slash-command usage.

## Cross-Reference

- Symmetric pattern for skills: see [skill-deployment.md](skill-deployment.md). Both governance docs are byte-identical-mirrored to `.claude/rules/`.
- Hook compliance for harness artifacts: see [bypass-mode-readiness.md](bypass-mode-readiness.md) for the workspace's PreToolUse hook layer that gates destructive ops, credential reads, and egress patterns. Harness bash entrypoints must remain compliant with these hooks.
- Release process for harness changes: see [release-process.md](../../release/governance/release-process.md). Harness changes follow the standard 13-stage pipeline (Stages 10-11 compress for git-native releases). Operational deployment of harness artifacts at Stage 12/13 uses `./deploy.sh --deploy` (auto-detected or manual).
