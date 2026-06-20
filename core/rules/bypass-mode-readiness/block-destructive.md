<!-- reference-durability: allow-link -->
## `block-destructive.sh` (BLOCK-DESTRUCTIVE-001..023)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-destructive.sh` |
| Matcher | Bash, Write, Edit |
| Scope | Destructive git ops, rm -rf catastrophic paths, primary-write guard, tamper resistance, script-exec ban |
| Mode | Always-enforce (high-confidence, narrow rules, low false-positive risk; not gated by `.claude/hooks/.mode`) |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-DESTRUCTIVE-001 | `git push --force` / `-f` (allows `--force-with-lease`, `--force-if-includes`) |
| BLOCK-DESTRUCTIVE-002 | `git reset --hard` |
| BLOCK-DESTRUCTIVE-003 | `git clean -f` / `-fd` |
| BLOCK-DESTRUCTIVE-004 | `rm` on catastrophic system paths (`/`, `/Users`, `/Applications`, `/Library`, `/System`, `/bin`, `/sbin`, `/usr`, `/etc`, `/var`) |
| BLOCK-DESTRUCTIVE-005 | `rm -rf $HOME` literal (bare — subpaths allowed) |
| BLOCK-DESTRUCTIVE-006 | `rm -rf .git` |
| BLOCK-DESTRUCTIVE-007 | `rm -rf Projects/` (legacy uppercase project dir) |
| BLOCK-DESTRUCTIVE-008 | `rm -rf projects/` (Layer 2 Cowork) |
| BLOCK-DESTRUCTIVE-009 | `rm -rf pmo-platform/` (Layer 1 source tree) |
| BLOCK-DESTRUCTIVE-010 | `git update-ref` on main / master / HEAD |
| BLOCK-DESTRUCTIVE-011 | `git symbolic-ref HEAD` to main / master |
| BLOCK-DESTRUCTIVE-012 | `git push` with plus-refspec (`+main` / `+refs/heads/main`) |
| BLOCK-DESTRUCTIVE-013 | `git reflog expire` / `git reflog delete` |
| BLOCK-DESTRUCTIVE-014 | `git filter-branch` |
| BLOCK-DESTRUCTIVE-015 | `git filter-repo` |
| BLOCK-DESTRUCTIVE-016 | Write/Edit to `.git/config`, `.git/hooks/*`, `.git/info/*` |
| BLOCK-DESTRUCTIVE-019 | Write/Edit to Layer 1 primary paths when cwd is not under `.claude/worktrees/` |
| BLOCK-DESTRUCTIVE-020 | PATH manipulation (`PATH=`, `export PATH`, `unset PATH`) |
| BLOCK-DESTRUCTIVE-021 | alias / function override of critical tools (`grep`, `jq`, `bash`, `sh`, `printf`) |
| BLOCK-DESTRUCTIVE-022 | Bash subprocess script execution not in `.claude/script-execution-allowlist.txt` |
| BLOCK-DESTRUCTIVE-023 | Mid-session setting of `CLAUDE_HOOK_BYPASS` (anti-injection) |

See [`§ Absolute-Path-Aware Verb Anchor`](../bypass-mode-readiness.md) for the canonical anchor pattern (including the git-family variant declared in this hook as `ANCHOR_PREFIX_GIT`) and [`§ Known Limitations`](../bypass-mode-readiness.md) for the Write/Edit primary-write-guard `os.path.realpath` normalization posture (BSD/macOS portability).
