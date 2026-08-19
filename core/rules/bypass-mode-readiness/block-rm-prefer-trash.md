<!-- reference-durability: allow-link -->
## `block-rm-prefer-trash.sh` (BLOCK-TRASH-001..003)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-rm-prefer-trash.sh` |
| Matcher | Bash |
| Scope | Workspace-scoped deletion containment; `rm`/`rmdir`/`unlink`/`trash`/`osascript` Trash-verb whose resolved path is outside `${HOME}/Claude/` or unresolvable under strict policy; `rm` inside workspace redirects to Trash via auto-detected command |
| Mode | Always-enforce (matches `block-destructive` / `block-credential-reads` posture; not gated by `.claude/hooks/.mode`) |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-TRASH-001 | `rm`/`rmdir`/`unlink` (any `git <verb>` invocation exempt) with resolved path outside `${HOME}/Claude/`, OR unresolvable under strict policy (variable / `$(...)` subshell / backtick tokens) |
| BLOCK-TRASH-002 | `rm`/`rmdir`/`unlink` (any `git <verb>` invocation exempt) with resolved path inside `${HOME}/Claude/` — blocks permanent deletion; stderr suggests Trash-equivalent command (auto-detected via 3-tier: `trash` in PATH → `/opt/homebrew/opt/trash/bin/trash` → `osascript` Finder fallback) |
| BLOCK-TRASH-003 | `trash` invocation OR `osascript` Trash-verb (`delete POSIX file`, `move ... to trash`) with resolved path outside `${HOME}/Claude/`, OR unresolvable under strict policy. `trash`/`osascript` Trash-verb targeting paths INSIDE the workspace are explicitly ALLOWED (the approved deletion mechanism) |

### Path Resolution — block-rm-prefer-trash.sh

**Command-position model (runs first).** Before any pattern is matched, the command is canonicalized by the shared primitive `core/hooks/lib/command-position.awk`, which all four regex-anchored hooks consume. The anchor recognises a command start only at start-of-line or after `;`/`&`/`|`; the canonicalizer inserts a `; ` in front of every *genuine* command start so those positions become ones the anchor already sees — grouping (`{ … }`, `( … )`, function bodies), compound-command keywords, the bounded command-prefix word set (`sudo`, `time`, `env`, `nohup`, `command`, `builtin`, `exec`, `xargs`), `VAR=value` prefixes, leading redirects, and the escaped verb `\rm`. Detection is quote-neutralized, so a verb appearing inside a quoted span is content, not a command. Both the verb regex and `extract_target_tokens()` read the canonicalized form — they are atomically coupled, and canonicalizing only one of them either fires the gate and extracts nothing or leaves the regex gating first. `xargs` has no argv target, so the canonicalizer emits a `$XARGS-STDIN` sentinel that routes to step 2's existing unresolvable branch rather than a new rule. See the § Command-Start Position Canonicalization and § Known Limitations sections of the parent readiness doc for the closed set and the nested-shell residual this deliberately does not close.

For each target token after the matched verb (flag tokens skipped; bare shell structure such as a subshell's closing `)` is skipped too, so a targetless `( rm -rf )` does not resolve `)` as a relative path):

1. Strip surrounding single/double quotes.
2. Detect unresolvable patterns: tokens containing `$`, backtick, or `$(` → **strict-policy BLOCK** (do not attempt to resolve dynamic values; emit BLOCK-TRASH-001 / BLOCK-TRASH-003 with "use explicit absolute paths" guidance).
3. Tilde expansion: `~` → `$HOME`; `~/<path>` → `$HOME/<path>`.
4. Absolute (`/<path>`) → use as-is; otherwise → join with `payload.cwd`.
5. Normalize via Python `os.path.realpath` (system-default `/usr/bin/python3`). Collapses `..`/`./`, does not require path existence, and follows symlinks. Stage 5 spec referenced GNU `realpath -m`, but macOS ships BSD realpath without `-m` and `/usr/bin/realpath` is absent on this system; Python 3.9+ `os.path.realpath` is the portable equivalent.
6. Prefix-match resolved path against `${HOME}/Claude/`.

**Git subcommand exemption (broad):** Any command beginning with `git <verb>` exits 0 before verb detection runs (per the requirement-6 literal reading — version-controlled deletes have their own recoverability via git history). This exemption is broader than `git rm` / `git clean` alone and covers `git worktree remove`, `git stash drop`, `git filter-branch`, etc. — those are handled by other hooks (`block-destructive.sh`) or by git's internal mechanisms.

**Symlink-following posture (intentional):** `os.path.realpath` follows symlinks. A symlink inside `${HOME}/Claude/` pointing to a target outside the workspace will resolve to the outside target and be blocked. This matches the strict-policy requirement: "block any file deletion whose resolved path is outside `${HOME}/Claude/`."

**Trash-command auto-detection (3-tier):** when emitting BLOCK-TRASH-002 suggestions:

1. `command -v trash` under pinned PATH → emit `trash '<abs_path>'`. On systems with a user-installed `/usr/bin/trash` (root-owned binary, present on the canonical workspace), this tier resolves successfully.
2. `[ -x /opt/homebrew/opt/trash/bin/trash ]` → emit `/opt/homebrew/opt/trash/bin/trash '<abs_path>'`. Required when `trash` was installed keg-only via `brew install trash` (default Homebrew install is keg-only — `/opt/homebrew/bin/trash` is NOT created).
3. Fallback → emit `osascript -e 'tell application "Finder" to delete POSIX file "<abs_path>"'`. Always-available on macOS 14+.

See [`§ Absolute-Path-Aware Verb Anchor`](../bypass-mode-readiness.md) — this hook's `extract_target_tokens()` awk script strips the canonical absolute-path prefix before the verb-equality check, atomically coupled with the anchor regex within the hook file. See [`§ Known Limitations`](../bypass-mode-readiness.md) for the nested-shell, quoted-path, other-deletion-mechanism, and pre-existing-`/usr/bin/trash` residuals.
