<!-- reference-durability: allow-link -->
## `block-destructive.sh` (BLOCK-DESTRUCTIVE-001..023)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-destructive.sh` |
| Matcher | Bash, Write, Edit |
| Scope | Destructive git ops, rm -rf catastrophic paths, primary-write guard, tamper resistance, script-exec ban |
| Mode | Always-enforce (high-confidence, narrow rules, low false-positive risk; not gated by `.claude/hooks/.mode`) |

> **Coverage boundary of BLOCK-DESTRUCTIVE-022 (and of every rule in this registry) — FOUR conditions.** "Always-enforce" above describes condition 4 only. A PreToolUse-enforced control is in force only when **all four** hold, and not when any one fails: (1) **loading** — the session resolved a settings surface declaring the hook wiring (any session, main or spawned, whose working directory is under the governed workspace root; a session resolving no such surface loads no hooks at all, and one outside the root is excluded by `core/hooks/lib/scope-guard.sh`); (2) **bypass** — `CLAUDE_HOOK_BYPASS` was not set in the launching environment (layer 1, which exits **both** hook classes, so the security/workflow asymmetry does **not** exist there; -023 denies *setting* it mid-session, which does not narrow the pre-launch case); (3) **master-activation class** — this hook is `security` class and therefore always enforces, going inert only on an explicit logged security-class opt-out; (4) **mode** — this hook is mode-independent. Naming fewer than four overstates the coverage. Canonical statement: [`core/standards/subagent-security-posture.md` § 3.1](../../standards/subagent-security-posture.md).
>
> **The specific over-claim this exists to stop:** describing `script-execution-allowlist.txt` as a *control* on a path where condition 1 does not hold. Where the wiring is not loaded, the allowlist is a convention — it governs review, not execution.

> **What BLOCK-DESTRUCTIVE-022 resolves, and what it cannot.** Given all four conditions above, the rule adjudicates **the script the interpreter executes** — the first non-flag operand of each `bash`/`sh`/`zsh` command on the line. It resolves: an absolute or relative path, a path in single or double quotes, a path behind interpreter flags (`bash -x <script>`), and a `.sh` passed as an *argument* to another script (the argument is not what executes, so the executed script is what is checked). It evaluates **every** command on a line, so an allowlisted first command does not shield a later one across `;`, `&&`, `||`, or `|`.
>
> It **cannot** resolve a **variable-bearing path** — a PreToolUse hook sees unexpanded argv, so `bash "$DIR/x.sh"` has no resolvable target. That case **fails closed** (denied), consistent with the dependency gate's posture that a control which cannot evaluate its input must deny rather than guess. Invoke with a literal path, or register the resolved path.
>
> Two forms are **out of this rule's scope** by construction, not by defect: direct execution of an executable script (`./x.sh`, no interpreter token) is not an interpreter invocation, and a script fetched or generated at runtime is not visible as a path at PreToolUse time.

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
| BLOCK-DESTRUCTIVE-019 | Write/Edit to Layer 1 primary paths when cwd is not under `pmo-platform/.claude/worktrees/` (the repo-rooted worktree base, mirroring the hook's Layer-1 detection base) |
| BLOCK-DESTRUCTIVE-020 | PATH manipulation (`PATH=`, `export PATH`, `unset PATH`) |
| BLOCK-DESTRUCTIVE-021 | alias / function override of critical tools (`grep`, `jq`, `bash`, `sh`, `printf`) |
| BLOCK-DESTRUCTIVE-022 | Bash subprocess script execution not in `.claude/script-execution-allowlist.txt` |
| BLOCK-DESTRUCTIVE-023 | Mid-session setting of `CLAUDE_HOOK_BYPASS` or `PMO_SCOPE_GUARD_ROOT` (anti-injection) |

See [`§ Absolute-Path-Aware Verb Anchor`](../bypass-mode-readiness.md) for the canonical anchor pattern (including the git-family variant declared in this hook as `ANCHOR_PREFIX_GIT`) and [`§ Known Limitations`](../bypass-mode-readiness.md) for the Write/Edit primary-write-guard `os.path.realpath` normalization posture (BSD/macOS portability).

> **Second gate on governance-file writes (scope of the -019 worktree exemption).** The BLOCK-DESTRUCTIVE-019 worktree exemption (allowing Layer-1 writes from a repo-rooted worktree cwd) does NOT clear governance-file writes on its own. `block-autonomy-ceiling.sh` BLOCK-AUTONOMY-001 independently blocks writes to the governance set (`CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`, any `SKILL.md`, `.claude/settings.json`, `.claude/hooks/*`, `.claude/rules/*`) as an irreducible Tier-0 operator-only action — with NO worktree exemption and gated by its own `.autonomy-mode` (not the shared `.mode`). So a governance edit from a worktree passes -019 but still faces BLOCK-AUTONOMY-001; the -019 exemption is not a blanket Layer-1 write allowance.
