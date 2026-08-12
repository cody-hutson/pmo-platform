# INSTALL.md — pmo-platform

User-facing install procedure for first-touch onboarding.

For architectural reference (what the install does and why), see [workspace-setup.md](workspace-setup.md). For the first-task walkthrough after install, see [GETTING_STARTED.md](GETTING_STARTED.md).

> **Scope:** This release supports macOS (Darwin 12+) only. Cross-platform support (Linux / WSL / Windows) is on the roadmap.

---

## TL;DR

If you already have the prerequisites (see § 1), four commands install pmo-platform:

```bash
git clone https://github.com/cody-hutson/pmo-platform.git ~/Claude/pmo-platform
cd ~/Claude/pmo-platform
./install.sh
./docs/scripts/validate-install.sh
```

`./install.sh` is the public install entry — a thin wrapper at repo root that delegates workspace bootstrap to `docs/scripts/setup-workspace.sh` and then runs the skill-deployment phase. The two underlying steps are still individually runnable for advanced debugging.

Then read [GETTING_STARTED.md](GETTING_STARTED.md). If anything fails, see § 5 Troubleshooting.

---

## 1. Before you install

You need four things installed before you run the setup script. Three more are recommended.

### Required

**macOS (Darwin 12+).** Setup hard-fails on non-Darwin platforms (exit code 78).

```bash
uname -s && sw_vers -productVersion    # Expect: Darwin / 12.0 or later
```

**Claude Code.** The platform is a Claude Code extension. Install per the [official setup docs](https://code.claude.com/docs/en/setup); the typical macOS path is Homebrew cask:

```bash
brew install --cask claude-code
command -v claude                       # Expect: a path under /opt/homebrew/bin or /usr/local/bin
```

**git.** Pre-installed via Xcode Command Line Tools on most macOS systems; install if absent:

```bash
xcode-select --install                  # If git --version fails
git --version                           # Expect: a version string starting with `git version 2.`
```

**jq.** Required for the hook layer's JSON parsing. The PreToolUse security hooks resolve `jq` from a fixed absolute-path allowlist — `/usr/bin/jq`, `/opt/homebrew/bin/jq`, `/usr/local/bin/jq` (the locations `brew install jq` uses) — and **fail closed** (block the tool call) in enforce mode when it cannot be found, so `jq` is load-bearing for the security perimeter, not optional:

```bash
brew install jq
jq --version                            # Expect: a jq-1.x version string
```

### Recommended

**bash 5+.** macOS ships bash 3.2.57; setup-workspace and its helpers are written to run under that system bash by design (no Homebrew bash prereq). Installing bash 5 is recommended for general workspace use but is not required to install pmo-platform:

```bash
brew install bash
bash --version                          # Expect: GNU bash, version 5.x
```

**trash.** The `block-rm-prefer-trash.sh` hook suggests trash-equivalent commands; without `trash` installed, the hook falls back to AppleScript via osascript (works, but slower):

```bash
brew install trash
command -v trash                        # Expect: a path under /opt/homebrew/bin or /usr/local/bin
```

**Node.js + npm.** Required only if you configure MCP servers in `~/.claude/settings.json` (typical MCP server declarations use `npx -y @org/server@version`). The pmo-platform base install does not require Node.js:

```bash
brew install node
node --version && npm --version         # Both commands succeed (exit 0)
```

---

## 2. Clone + bootstrap

### 2a. Clone the repo

```bash
git clone https://github.com/cody-hutson/pmo-platform.git ~/Claude/pmo-platform
cd ~/Claude/pmo-platform
```

The default workspace location is `~/Claude/pmo-platform`. To install elsewhere, pass `--workspace-root` and `--source-repo` to setup-workspace in § 2b.

### 2b. Run the install

```bash
./install.sh
```

`./install.sh` is the public install entry; it runs two phases in order:

**Phase 1 — workspace bootstrap.** Delegates to `docs/scripts/setup-workspace.sh --source-repo <repo-root>` (the repo root is auto-detected from the location of `install.sh` itself, so the README's three-command flow works without any operator-side path math). The bootstrap script:

1. Detects platform (Darwin required; exits 78 otherwise).
2. Checks prerequisites (`python3`, `shasum`, `git`, `jq`). On missing, prints the exact `brew install` command and exits 69.
3. Validates the source repo (the auto-detected repo root); exits 66 if missing or templates absent.
4. Computes the active token set from three sources: `core/CLAUDE.md.template`, `core/settings.json.template`, and `core/deploy/composition-surface-manifest.sh`. The manifest is a deliberate third input, not an accident of layout — ADR-122 makes the CLAUDE.md template's whole body a managed section, so the reserved-token vocabulary that used to be declared in its authoring header now lives in the manifest and is grepped from there.
5. Detects state at `~/Claude/.claude/.workspace-setup.state` and routes one of three branches: fresh-install, re-bootstrap, or guided recovery.
6. Creates the workspace directory layout.
7. Resolves operator-identifying tokens — via interactive prompts by default, or from each token's declared default with no read from stdin under `--non-interactive`; writes the canonical `operator.toml` at `~/.config/pmo-platform/operator.toml` (XDG-spec; mode 0600).
8. Substitutes tokens into `CLAUDE.md` and `.claude/settings.json` from the templates, and scaffolds an empty `~/Claude/.claude/settings.local.json` — **your** settings overlay (see below).
9. Installs the PreToolUse hooks at `~/Claude/.claude/hooks/` from `core/hooks/*.sh`.
10. Installs composition-surface seed files (allowlists, exemption lists) from `core/config/allowlists/` to runtime locations (`~/Claude/.claude/` for hook-tier; `~/Claude/personal/pmo-instance/` for instance-tier), wrapped in MANAGED SECTION + OPERATOR ADDITIONS fences per [`composition-surface-spec.md` §2](../core/standards/composition-surface-spec.md). Install-if-missing semantics: operator edits to OPERATOR ADDITIONS sections are preserved on re-run.
11. Runs a post-install verification gate. On pass, writes `.workspace-setup.state` with `verification_passed: true` and prints the validate-install invocation hint.

**Where your own Claude Code settings go.** The install creates two settings files, and the split matters:

| File | Owner | What happens to it |
|---|---|---|
| `~/Claude/.claude/settings.json` | **Platform (Layer 1)** | Rendered from `core/settings.json.template`. Re-rendered whole-file by `./update.sh` so security-hook registrations stay current — anything you add here is migrated out and replaced. |
| `~/Claude/.claude/settings.local.json` | **You (Layer 2)** | Created empty (`{}`) once, then never touched by the package. Claude Code merges it over the managed file natively. Git-ignored. |

Put extra permissions, `env` values, and your own hooks in **`settings.local.json`**. If you do edit the managed file, the update guard will move your keys into the overlay and back the old file up rather than dropping them — but the overlay is the intended home. See [UPDATE.md § 1.1](UPDATE.md).

**Phase 2 — skill deployment.** After workspace bootstrap completes successfully, `install.sh` sources `core/deploy/orchestrate.sh` and invokes `phase_deploy_skills`, which calls `core/deploy/deploy.sh --deploy`. This populates `~/.claude/skills/` so the post-install sanity check at [GETTING_STARTED.md § 2](GETTING_STARTED.md) succeeds out of the box.

**Useful flags (forwarded to setup-workspace.sh):**

| Flag | Purpose |
|---|---|
| `--source-repo PATH` | Path to the cloned pmo-platform (default: `~/Claude/pmo-platform`) |
| `--workspace-root PATH` | Workspace destination (default: `~/Claude`). Also the Phase 2 deploy-target root — skills deploy under `PATH/.claude/skills` instead of the live `~`, so a sandboxed install redirects every write. |
| `--config-root PATH` | Root for operator config writes (default: `~/.config/pmo-platform`; or `PMO_PLATFORM_CONFIG_ROOT` env var). Used by integration tests + sandboxed dry-runs to isolate from operator state. |
| `--init-only-state` | Verify artifacts empirically without performing install operations; writes state file on pass |
| `--non-interactive` | Resolve every token from its declared default and never read stdin, so a fresh install completes unattended. A required token with no available default exits non-zero naming the token — no value is ever silently substituted. Does not change interactive behavior. |
| `--dry-run` | Preview planned actions; perform no state mutation |
| `--help` | Show the canonical usage banner |

**Sandboxing for tests and dry-runs:** the three root flags (`--workspace-root`, `--config-root`, `--source-repo`) together let an integration test point every write at `/tmp` without touching the operator's real `$HOME` state — including **Phase 2 skill deployment**: `--workspace-root` doubles as the deploy-target root, so `~/.claude/skills` and the Cowork session-skills base are redirected under the sandbox rather than written to the live home. `--config-root` has a corresponding env-var fallback (`PMO_PLATFORM_CONFIG_ROOT`) honored when the flag is absent; the deploy phase reads `PMO_PLATFORM_DEPLOY_ROOT` directly, which `--workspace-root` sets for you (use it when invoking `core/deploy/deploy.sh --deploy` standalone).

**Re-run safety.** It is safe to invoke setup-workspace more than once. On re-run, the script reads `.workspace-setup.state`, reuses cached tokens from `~/.config/pmo-platform/operator.toml`, and prompts only on per-file hook drift (with caching to avoid re-prompting on unchanged source SHAs).

---

## 3. Verify install

After setup completes successfully, run the validate-install script:

```bash
./docs/scripts/validate-install.sh
```

The script prints a per-check status line and exits 0 on success. If any check fails, the script prints the specific failing assertion with diagnostic context.

For deeper reference on what setup did and why, see [workspace-setup.md](workspace-setup.md).

### 3a. Activate ambient intake (optional, operator-performed)

**Ambient intake** watches a drop-zone directory for transcripts and emails, classifies and registers what appears there on a schedule, and — separately — polls your external tracker for changes. Install lays the groundwork for it; it does not switch it on.

**What install already did.** Setup created three directories under your operator-instance folder — `inbox/` (the drop-zone), `ambient-intake/` (the sweep's run-log), and `external-sync/` (the tracker-poll snapshot and its run-log) — and seeded `automation_level` in your `operator.toml`. Resolve where they landed:

```bash
grep -A1 '^\[automation\]' ~/.config/pmo-platform/operator.toml
ls -d "${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"/personal/pmo-instance/{inbox,ambient-intake,external-sync}
```

**Nothing runs until you register the scheduled tasks.** This is deliberate, and it is the one step the installer cannot perform for you: the tasks live on the agent-runtime scheduled-task surface, which a shell script has no way to reach. The same rule already governs the platform-health sentinels — the platform ships the specification, your instance owns the registration, because a registration carries an instance-local path and is not portable.

To activate, register two scheduled tasks on the `mcp__scheduled-tasks` surface from an agent session:

| Task name | What it does | Prompt to register it with |
|---|---|---|
| `ambient-intake-sweep` | Enumerates the drop-zone, skips files already ingested, and drives the daily intake steps | The thin-bootstrap prompt in [`core/standards/c2-intake-sweep-path-a.md`](../core/standards/c2-intake-sweep-path-a.md) § 9 |
| `external-sync-path-b` | Polls your configured tracker adapters, diffs against the snapshot, and proposes reconciliations | The thin-bootstrap prompt in [`core/standards/c3-external-sync-path-b.md`](../core/standards/c3-external-sync-path-b.md) § 10 |

Both prompts are deliberately thin: they point at the tracked specification rather than copying it, so the registration cannot drift away from the source. Register them with a once-daily cadence at an early-morning local hour, and with completion notification on — every run pings and writes a run-record, which is what makes a silent failure visible.

**How much the sweeps may do on their own** is governed by `automation_level` in your `operator.toml`. The seeded default, `recommend`, means the platform drafts and surfaces but writes nothing without your approval. The other values are `off` and `bounded_auto`; the template at `core/config/operator.toml.template` documents what each one permits.

**To reverse any of this:** delete a scheduled task or set it to `enabled:false` — that is the reversal for the registration half, which no revert can undo because it is not a tracked file. To keep a registered sweep quiet without deregistering it, set `automation_level = "off"`. The three directories are inert when empty and can be left in place or removed with `rmdir`.

**One operational caveat:** scheduled tasks run only while the agent application is open. A task whose window passes while the app is closed defers to the next launch. That is a property of the scheduler, not a fault in the sweep.

---

## 4. Next steps

You are ready to use pmo-platform. Continue with the first-task walkthrough:

→ [GETTING_STARTED.md](GETTING_STARTED.md)

For updating to a future release without re-installation, see [UPDATE.md](UPDATE.md). The update mechanism preserves your operator additions to composition-surface managed config files (allowlists, exemption lists) while refreshing package-managed content. (CLAUDE.md is not refreshed by `update.sh` — re-run `setup-workspace.sh` to pick up template changes.)

---

## 5. Troubleshooting

Each entry below cites the code path in `setup-workspace.sh` that produces the observable signal, so you can match the symptom to the exact failure mode.

### 5.1. Setup exits immediately on a non-Darwin platform

**Symptom.** Setup exits with code 78. Stderr emits:

```
ERROR: setup-workspace.sh is Darwin-only.
ERROR: Cross-platform support deferred per Stage 5 Recommendation #3.
ERROR: Current platform: <Linux | etc.>
```

**Diagnosis.** Cross-platform support is deferred for this release. Setup runs the platform check (`uname -s`) before any other work and refuses to proceed on Linux, WSL, or other non-Darwin systems.

**Fix.** Run setup on macOS. Cross-platform (Linux / WSL / Windows) support is on the roadmap.

### 5.2. Setup exits 69 with a "Missing required tools" message

**Symptom.** Setup exits with code 69. Stderr emits:

```
ERROR: Missing required tools: <tool list>
ERROR:
ERROR: Hook-Blocked → User-Side Handoff per CLAUDE.md convention:
ERROR: Run in your terminal:
ERROR:   brew install <tool list>
ERROR: Then re-invoke this script.
```

**Diagnosis.** One or more of `python3`, `shasum`, `git`, or `jq` is missing on `PATH`. The script enumerates the missing tools and prints a ready-to-run `brew install` command.

**Fix.** If `brew` is itself missing (`brew install: command not found`), install Homebrew first using the official one-liner from [brew.sh](https://brew.sh/):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the on-screen instructions to add Homebrew to your `PATH`, then restart your shell and verify:

```bash
brew --version                          # Expect: a Homebrew version string
```

Then run the `brew install` command that setup-workspace printed, and re-invoke setup-workspace.

### 5.3. Setup exits 66 with a "Source repo not found" or templates-missing message

**Symptom.** Setup exits with code 66. Stderr emits one of:

```
ERROR: Source repo not found at: <path>
ERROR: Source repo does not contain core/ subdirectory: <path>/core
ERROR: Required templates not found:
ERROR:   <path>/core/CLAUDE.md.template
ERROR:   <path>/core/settings.json.template
```

**Diagnosis.** Setup looked for the source repo at `--source-repo` (default `~/Claude/pmo-platform`) and either the directory was absent, lacked the `core/` subdirectory, or lacked the template files. This usually means the clone did not complete, the clone landed at a different path, or the source branch does not include the templates.

**Fix.** Confirm the clone path and contents:

```bash
ls ~/Claude/pmo-platform/core/CLAUDE.md.template
ls ~/Claude/pmo-platform/core/settings.json.template
```

If both files exist at a non-default path, pass `--source-repo` explicitly:

```bash
./docs/scripts/setup-workspace.sh \
  --source-repo /custom/path/to/pmo-platform
```

If the templates are missing, re-clone from `https://github.com/cody-hutson/pmo-platform.git` on a branch that includes them.

### 5.4. Setup is interrupted mid-run (Ctrl-C, terminal close, signal)

**Symptom.** Setup exits with code 130. Stderr emits:

```
ERROR: Interrupted by signal
WARN: Rolling back partial state (INSTALL_COMPLETE=0, exit_code=130)
```

**Diagnosis.** The SIGINT/SIGTERM trap fired. Setup writes rollback ops as it works; on interruption it iterates the recorded ops in reverse, removing only the files and directories it created in this run. Operator-customized files outside the rollback list are not touched.

**Fix.** Re-invoke setup-workspace:

```bash
./docs/scripts/setup-workspace.sh
```

Token responses you entered in the cancelled run are not cached (the cache writes only on a successful completion path through the verification gate). The re-run starts the prompt sequence from the beginning. If you do not yet know an answer (e.g., your organization name), enter a placeholder; setup re-prompts only on missing/placeholder tokens during future re-runs.

### 5.5. Setup detects an existing state file with `verification_passed: false`

**Symptom.** Setup prints:

```
WARN: State file present but invalid/incomplete: <path>/.workspace-setup.state
WARN:
WARN: Options:
WARN:   (R)epair  — backup state file + re-run fresh-install steps
WARN:   (B)ackup  — rename state file to .bak.<timestamp> and run fresh-install
WARN:   (E)xit    — exit without modification
WARN:
Recovery action (R/B/E):
```

**Diagnosis.** A prior setup run completed phases but the verification gate failed (or the state file is corrupt). The state-file routing detects `verification_passed != true` and enters guided recovery; your existing files are not modified until you pick an option.

**Fix.** Choose **R** or **B** to restart fresh-install (both back up the existing state file with a `.bak.<timestamp>` suffix and re-run all install phases); choose **E** to exit without changes and investigate further. If you re-ran setup after a force-quit (Failure Mode 5.4 above), R/B both let you proceed without losing operator-customized files.

If a specific hook is showing drift and you want to force re-install of that hook only without re-prompting, delete the target hook file and re-run setup — the hook install loop installs from source whenever the target is absent:

```bash
rm ~/Claude/.claude/hooks/<hook-name>.sh
./docs/scripts/setup-workspace.sh
```

The re-run sees the missing hook, installs it fresh from the source `core/hooks/`, and resumes through the normal flow.

---

## License + scope

pmo-platform is distributed under BSL 1.1 — see [LICENSE](../LICENSE).
