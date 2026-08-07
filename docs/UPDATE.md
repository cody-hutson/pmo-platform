# UPDATE.md — Updating pmo-platform

User-facing update procedure for in-place version upgrades without re-installation.

For installation, see [INSTALL.md](INSTALL.md). For workspace architecture, see [workspace-setup.md](workspace-setup.md).

---

## TL;DR

```bash
cd ~/Claude/pmo-platform
git pull
./update.sh
```

The `update.sh` script regenerates package-managed content from current templates + your `operator.toml`, preserving your custom additions verbatim.

---

## 1. What gets updated

| Category | Update behavior |
|---|---|
| **Universal** (skill prompts, hook scripts, schemas) | Refreshed by `git pull`; no separate action |
| **Customizable** (`settings.json`) | Composed at install by `setup-workspace.sh`; **refreshed by `update.sh`** (whole-file re-render) under a guard that migrates any keys you added to `.claude/settings.local.json` and backs the file up first |
| **Composition-surface** (allowlists, exemption lists, `CLAUDE.md`) | Managed section regenerated; OPERATOR ADDITIONS section preserved verbatim |
| **Operator-instance** (`projects/`, `personal/`, `knowledge/`) | Never touched |

The contract is defined at [`core/standards/composition-surface-spec.md`](../core/standards/composition-surface-spec.md).

**Your workspace `CLAUDE.md` is refreshed by `update.sh`** (ADR-120). When the shipped template changes, its managed section is regenerated from the current template plus your `operator.toml`, and anything you put in its `OPERATOR ADDITIONS` section at the bottom of the file is preserved verbatim. A copy of the previous file is written to `<workspace-root>/.backup-pre-update-<timestamp>/CLAUDE.md` before every regeneration. Two consequences worth knowing: content placed **outside** both fences is not carried forward (put your additions inside the `OPERATOR ADDITIONS` fence), and re-running `setup-workspace.sh` no longer overwrites an existing `CLAUDE.md` — it is preserved, and `update.sh` is how it moves forward.

**Your `.claude/settings.json` is refreshed by `update.sh`** (ADR-121). This is the file that registers the platform's security hooks against the events they guard, so a workspace installed before a hook was wired used to hold that hook on disk while nothing ever invoked it. Phase 5d now re-renders the whole file from the current template plus your `operator.toml`, immediately after the hook scripts themselves are refreshed. Before it writes, a guard classifies what is there: an untouched platform copy is regenerated with no ceremony; anything you added is **moved into `.claude/settings.local.json`** and the previous file copied to `<workspace-root>/.backup-pre-update-<timestamp>/settings.json`, with every moved key named in the output. If a key being moved already exists in your overlay with a different value, the refresh **aborts for that run** and tells you so rather than guessing — resolve the conflict in the overlay and re-run.

### 1.1 Customizing your settings

Put your own Claude Code settings in **`<workspace-root>/.claude/settings.local.json`**, never in `.claude/settings.json`.

- `.claude/settings.json` is **platform-managed (Layer 1)**. It is re-rendered whole-file from the shipped template, so anything you add there is migrated out and replaced on the next update.
- `.claude/settings.local.json` is **yours (Layer 2)**. Claude Code merges it over the managed file natively, it is git-ignored, and the package never regenerates it — `setup-workspace.sh` and `update.sh` only create it empty (`{}`) if it does not exist.

Extra permissions, `env` values, and your own hooks all belong in the overlay. There is deliberately no pointer comment inside `.claude/settings.json` itself: JSON has no comment syntax, and the installer strips the template's one comment key so the runtime file is clean JSON.

## 2. What does NOT get updated

- Your work: `projects/`, `personal/notes/`, `knowledge/`
- OPERATOR ADDITIONS sections in composition-surface managed files (allowlists, exemption lists, `CLAUDE.md`)
- Values you've set in `~/.config/pmo-platform/operator.toml`
- **`.claude/settings.local.json`** — your settings overlay. Created empty once if absent, then never touched again.
- User-scoped Claude config at `~/.claude/`

## 3. Procedure

### 3.1 Pre-flight (manual)

```bash
cd ~/Claude/pmo-platform
git status                                  # Expect: clean (no uncommitted changes)
git pull                                    # Pull latest from upstream
cat .version                                # Note new version
```

If your working tree is not clean, commit or stash before proceeding — `update.sh` does not modify the package directory itself, but a clean tree makes the upgrade auditable.

### 3.2 Run update.sh

```bash
./update.sh
```

The script:

1. **Pre-flight**: verifies `~/.config/pmo-platform/operator.toml` is present. If absent, prompts you to run `docs/scripts/setup-workspace.sh` first.
2. **Schema diff**: compares `operator.toml` `schema_version` to current template's `schema_version`. On drift, advises manual review.
3. **Regenerate composition-surface managed sections**: for each file in `core/deploy/composition-surface-manifest.sh`, computes source SHA; if installed `managed_sha` differs, backs up the runtime file then regenerates the MANAGED SECTION fence with current template content (token-substituted from `operator.toml`). OPERATOR ADDITIONS section preserved verbatim. Independently, it also **detects in-fence tampering**: if you hand-edited content inside a MANAGED SECTION, the live managed body no longer matches the stored `installed_sha` anchor, so the file is backed up to `~/Claude/.backup-tampered-<timestamp>/` and regenerated — distinct from the source-changed regeneration path, and caught even when the source template is unchanged. (Files installed before this anchor existed have no `installed_sha`; they are treated as "unknown, not tampered" and the anchor is back-filled on the next regeneration — run `./update.sh --force-regen` once after upgrading to back-fill all anchors immediately.)
4. **Skill redeploy**: invokes `core/deploy/orchestrate.sh phase_deploy_skills`, which calls `core/deploy/deploy.sh --deploy`. This ensures any new skills shipped in the pulled release land in `~/.claude/skills/` without a separate operator step.
5. **State update**: writes timestamp to `~/.config/pmo-platform/.last-update`.

### 3.3 Useful flags

| Flag | Purpose |
|---|---|
| `--dry-run` | Preview planned regenerations; perform no writes |
| `--force-regen` | Regenerate every composition-surface file unconditionally (default: only those whose source SHA changed) |
| `--workspace-root PATH` | Workspace root for managed-section regen targets + backup dir (default: `~/Claude`; or `PMO_PLATFORM_WORKSPACE_ROOT` env var) |
| `--config-root PATH` | Root for operator config reads (operator.toml) + state writes (.last-update). Default: `~/.config/pmo-platform`; or `PMO_PLATFORM_CONFIG_ROOT` env var |
| `--help` | Show usage |

The root flags + env-var counterparts let integration tests sandbox cleanly without modifying the operator's real `$HOME` state. Precedence: CLI flag > env var > `$HOME`-based default.

### 3.4 Verify

```bash
./docs/scripts/validate-install.sh
```

The validate script asserts: hooks installed, composition-surface files present, settings.json valid, CLAUDE.md tokens resolved.

---

## 4. Adding new operator additions after an update

To extend an allowlist (e.g., add a new permitted host to `egress-allowlist.txt`):

1. Open the runtime file: `~/Claude/.claude/egress-allowlist.txt` (hook-tier) or `~/Claude/personal/pmo-instance/<file>.txt` (instance-tier).
2. Add entries **inside the OPERATOR ADDITIONS fence** (between `=== BEGIN OPERATOR ADDITIONS ===` and `=== END OPERATOR ADDITIONS ===`).
3. Save. `update.sh` on future runs will preserve your additions verbatim.

Editing **inside the MANAGED SECTION fence** is detected as tampering at the next `update.sh` (the live managed body stops matching the stored `installed_sha` anchor): your hand-edited file is backed up to `~/Claude/.backup-tampered-<timestamp>/` and the managed section is regenerated (per [`composition-surface-spec.md` §2.5](../core/standards/composition-surface-spec.md)). Always add operator content to the OPERATOR ADDITIONS section instead.

Programmatic addition is also supported:

```bash
./.claude/hooks/allowlist-add.sh .claude/egress-allowlist.txt 'my-internal-host.example.com'
```

This appends to the OPERATOR ADDITIONS section automatically.

---

## 5. Version-skew notification

A SessionStart hook at [`core/hooks/notify-version-skew.sh`](../core/hooks/notify-version-skew.sh) compares your local `.version` to the `tag_name` of the latest published GitHub Release (queried via the Releases API, cached daily) and prints a one-line notice whenever the two differ — an exact-match check, so a `.version` that is *ahead* of the latest Release also triggers the notice:

```
→ pmo-platform vX.Y → vX.Z available. Run ./update.sh to apply.
```

The hook is passive — it does NOT auto-apply updates. Operator decides when to run `update.sh`.

`.version` is **release-cut-owned**: for a versioned release it is stamped to the shipped version by the Stage 13 close-out (`release/tools/automated-closeout.sh` `phase_bump_version`, per [`release/references/pipeline/stage-13-close.md` § Phase B5.7](../release/references/pipeline/stage-13-close.md)); a version-less release leaves it unchanged. `update.sh` only *propagates* the source value to the deployed `<ws>/.claude/.version` snapshot (per ADR-017) — it does not author it, so a clone on current `main` reads the version that shipped, and the banner above clears once the stamped value matches the latest published Release.

---

## 6. Troubleshooting

### 6.1 `update.sh` exits 65 — `operator.toml` not found

The script could not locate `~/.config/pmo-platform/operator.toml`. You have not yet completed initial install — run `docs/scripts/setup-workspace.sh` first.

### 6.2 `update.sh` exits 73 — regeneration failure

A composition-surface file regeneration failed. The script:

- Restored the file from its in-script backup.
- Printed the failing file path.

Check `~/Claude/.backup-pre-update-<timestamp>/` for the pre-attempt content. Re-run `./update.sh --dry-run` to inspect what was attempted; report a bug if the failure mode is non-obvious.

### 6.3 An allowlist no longer respects an entry I added

Likely the entry was added inside the MANAGED SECTION instead of OPERATOR ADDITIONS. Check the affected file:

```bash
less ~/Claude/.claude/<allowlist>.txt
```

Move your entries into the OPERATOR ADDITIONS section. The next `update.sh` detects the in-fence edit (via the `installed_sha` anchor), backs up your hand-edited file to `~/Claude/.backup-tampered-<timestamp>/`, and regenerates the managed section (your OPERATOR ADDITIONS are preserved). Recover your edited entries from the backup, then re-add them inside OPERATOR ADDITIONS.

### 6.4 SessionStart shows no version-skew notice

The hook fails silently on any error to avoid blocking session start. Common causes:

- The hook is not registered as a `SessionStart` hook in `.claude/settings.json`. A workspace installed before the hook was wired won't carry the entry — run `./update.sh`, whose Phase 5d refreshes `settings.json` under the operator-key guard and installs the `.version` snapshot the hook reads (`.claude/.version`). A full `setup-workspace.sh` re-run also works but is no longer necessary for this.
- `gh` CLI not authenticated. Run `gh auth status`.
- `operator_github` not set in `operator.toml`. Required to query the release API.
- Network unavailable. The hook caches results for 24h; you'll see the notice after connectivity returns.

---

## 7. References

- [INSTALL.md](INSTALL.md) — initial installation
- [workspace-setup.md](workspace-setup.md) — workspace architecture
- [GETTING_STARTED.md](GETTING_STARTED.md) — first-task walkthrough
- [`core/standards/composition-surface-spec.md`](../core/standards/composition-surface-spec.md) — durability contract spec
- [`core/standards/depersonalization-spec.md`](../core/standards/depersonalization-spec.md) — token vocabulary
