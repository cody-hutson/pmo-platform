<!-- reference-durability: allow-link -->
## `block-fs-boundary.sh` (BLOCK-FS-BOUNDARY-001..003)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-fs-boundary.sh` |
| Matcher | Bash |
| Scope | Workspace-boundary scoping for Bash file commands beyond settings.deny coverage (cat/head/tail/sed); file-read (cat/head/tail/less/more/base64/xxd/od/hexdump/strings) + file-write (cp/mv/tee/dd) source+target; resolved-path prefix-match against `.claude/fs-boundary-allowlist.txt`; strict-policy on unresolvable tokens |
| Mode | Warn-mode initial (shared `.claude/hooks/.mode`); flip-to-enforce per the [`§ Shakedown → Enforce Transition Checklist`](core/rules/bypass-mode-readiness.md) |

Added in the modular-monolith-cleanup release. Composes with Anthropic's native `settings.deny` `Read(...)` / `Edit(...)` rules (which natively cover the Read tool, Edit/Write tools, and the recognized Bash file-command subset cat/head/tail/sed per `code.claude.com/docs/en/permissions`). This hook closes the residual Bash gap for cp / mv / tee / dd / base64 / xxd / od / hexdump / strings / less / more. Mode-gated via shared `.claude/hooks/.mode` (same file as `block-egress` + `block-mcp-writes`) — initial state `warn` per Shakedown → Enforce Transition Checklist.

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-FS-BOUNDARY-001 | File-read verb (`cat` / `head` / `tail` / `less` / `more` / `base64` / `xxd` / `od` / `hexdump` / `strings`) with resolved target path outside the allowed roots in `.claude/fs-boundary-allowlist.txt` |
| BLOCK-FS-BOUNDARY-002 | File-write verb (`cp` / `mv` / `tee` / `dd`) with resolved source OR target path outside the allowed roots in `.claude/fs-boundary-allowlist.txt` |
| BLOCK-FS-BOUNDARY-003 | Resolved path unresolvable under strict policy (variable / `$(...)` subshell / backtick token) for any of the file-read or file-write verbs above |

**Settings.deny pairing:** the hook's verb coverage closes the residual Bash gap; for the Read tool, the Edit/Write tools, and the recognized Bash subset (cat / head / tail / sed), Anthropic's native `permissions.deny` rules in `.claude/settings.json` are the primary line of defense. The two surfaces are kept coherent — the deny patterns mirror the allowlist's negative space for the Read/Edit Anthropic surfaces (per-subdir explicit deny for `~/Documents/`, `~/Desktop/`, `~/Music/`, `~/Pictures/`, `~/Movies/`, `~/Public/`, the high-risk `~/Library/` subdirs, and other-user homes `//Users/<other-user>/**`). Per Stage 5 spec Section 1, the two surfaces are not perfectly DRY by design — `settings.deny` is deny-list-based while the hook is allowlist-based; the gitignore-spec syntax used by `settings.deny` does not support an "allow inside a deny region" pattern, so `~/Library/Application Support/Claude/local-agent-mode-sessions/` (the Cowork install path required by `deploy.sh --deploy`) is preserved via per-subdir explicit-deny on the Library sub-paths that need blocking, leaving the install path accessible.

### Path Resolution — block-fs-boundary.sh

For each target token extracted by `extract_target_tokens(verb)` (flag tokens skipped, same chained-command tokenizer as `block-rm-prefer-trash.sh`):

1. Strip surrounding single/double quotes.
2. Detect unresolvable patterns: tokens containing `$`, backtick, or `$(` → **strict-policy BLOCK** (do not attempt to resolve dynamic values; emit BLOCK-FS-BOUNDARY-003 with "use explicit absolute paths" guidance).
3. Tilde expansion: `~` → `$HOME`; `~/<path>` → `$HOME/<path>`.
4. Absolute (`/<path>`) → use as-is; otherwise → join with `payload.cwd`.
5. Normalize via Python `os.path.realpath` (system-default `/usr/bin/python3`). Collapses `..`/`./`, does not require path existence, and follows symlinks. Same `os.path.realpath` posture as `block-rm-prefer-trash.sh` (and `block-destructive.sh`).
6. Walk `.claude/fs-boundary-allowlist.txt` line-by-line; tilde-expand each entry; trim trailing slash; prefix-match the resolved path against each allowed root. First match → allow. No match → block (or warn-log when `.mode = warn`).

**Allowlist format:** one absolute path per line (NOT a bash glob — exact prefix-match after realpath); `#` introduces comments; blank lines ignored; trailing slashes normalized on both entry and target. Tilde-prefixed entries expand to `$HOME`. Subpaths of an allowed root are implicitly allowed.

**Symlink-following posture (intentional):** same as `block-rm-prefer-trash.sh` — `os.path.realpath` follows symlinks. A symlink inside an allowed root pointing to a target outside any allowed root resolves to the outside target and is blocked. This matches the strict-policy requirement: "block any file access whose resolved path is outside the allowed roots."

**Absolute-path-aware verb anchor:** same anchor pattern as the other three regex-based PreToolUse hooks — file-read and file-write verbs invoked via canonical absolute-path prefix (`/bin/cat`, `/usr/bin/cp`, etc.) are detected uniformly with the verb-at-command-start form. See [`§ Absolute-Path-Aware Verb Anchor`](core/rules/bypass-mode-readiness.md).

See [`§ Known Limitations`](core/rules/bypass-mode-readiness.md) for this hook's shell-redirection, nested-shell + quoted-path, and `~/Library/<unenumerated-subdirs>` settings.deny-coverage-gap residuals.
