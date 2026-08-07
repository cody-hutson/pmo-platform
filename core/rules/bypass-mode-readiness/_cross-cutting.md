<!-- reference-durability: allow-link -->
## Absolute-Path-Aware Verb Anchor

All three regex-based PreToolUse hooks that match Bash verb invocations (`block-destructive.sh`, `block-egress.sh`, `block-rm-prefer-trash.sh`) detect verbs invoked at canonical absolute-path prefixes — not only verb-at-command-start. The canonical anchor pattern is:

```
(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?<verb>
```

with a companion variant for git-family rules in `block-destructive.sh`:

```
(^|[^[:alnum:]_-])(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?git[[:space:]]+<subverb>
```

Each hook declares `readonly ANCHOR_PREFIX_BASH` (and `ANCHOR_PREFIX_GIT` in `block-destructive.sh`) near its other readonly constants. The optional prefix group captures the 5 canonical macOS/Linux absolute-path prefixes:

| Prefix | Path |
|---|---|
| (group absent) | `<verb>` — line-start / separator anchor (backward-compatible) |
| `/bin/` | macOS/Linux base path |
| `/usr/bin/` | macOS/Linux user path |
| `/usr/local/bin/` | `/usr/local`-installed tools |
| `/opt/homebrew/bin/` | Homebrew on Apple Silicon |
| `/opt/local/bin/` | MacPorts |

Pre-anchor baseline: invocations like `/bin/rm -rf /`, `/usr/bin/curl -X POST <unallowed-host>`, `/bin/unlink ${HOME}/Claude/foo`, and `/usr/bin/git push --force origin main` evaded their respective hooks because the verb-detection anchor required the verb to start at line-start or after a command separator with no allowance for absolute-path prefixes. Post-anchor: every Bash-branch verb-matched rule in the 3 hooks composes uniformly with the new anchor; the `extract_target_tokens()` awk script in `block-rm-prefer-trash.sh` was updated to strip the canonical absolute-path prefix before the verb-equality check (atomically coupled with the regex change within the same hook file).

Backward compatibility: when the optional prefix group is absent (the common case — `rm foo`, `git push`, `cat ~/.ssh/id_rsa`), the regex degenerates to the original pattern. All 217 pre-anchor fixtures continue to pass unchanged; 23 new fixtures (8 in `block-destructive`, 8 in `block-egress`, 7 in `block-rm-prefer-trash`) exercise the new absolute-path detection AND genuine false-positive guards (composition with chained-command tokenizer, quoted-content occurrences, non-canonical prefixes).

Out of scope per parent body (deliberate):
- Symlinked tool resolution (e.g., `~/.local/bin/rm → /bin/rm`) — operator-instance customization
- Custom PATH entries beyond the canonical 5 (e.g., `${HOME}/bin/rm`) — operator-instance escape hatch
- `block-credential-reads.sh` and `block-mcp-writes.sh` — Read-tool / MCP-tool matched, NOT Bash-verb anchored; absolute-path bypass is structurally irrelevant
- WebFetch-branch rules in `block-egress.sh` (BLOCK-EGRESS-012 / -013) — tool-name matched, not verb-anchored
- Write/Edit-branch rules in `block-destructive.sh` (BLOCK-DESTRUCTIVE-016 / -019) — file-path matched, not verb-anchored

## CLAUDE_HOOK_BYPASS — Escape Hatch Usage

**When to use:** A hook is blocking a legitimate action you cannot refactor around, OR a hook has a bug that's blocking all Bash calls and you need to edit the hook.

**How to use:**
```bash
# Exit your current claude session, then:
CLAUDE_HOOK_BYPASS=1 claude
```

All security hooks exit 0 immediately when the env var is set, logging each invocation to `.claude/hooks/bypass-log.jsonl` for audit.

**Anti-injection guarantee:** Claude cannot set `CLAUDE_HOOK_BYPASS` mid-session. `block-destructive.sh` BLOCK-DESTRUCTIVE-023 denies any Bash invocation containing `CLAUDE_HOOK_BYPASS=`. This creates an asymmetry: the operator (pre-launch shell) can enable bypass, but prompt-injection cannot.

**Important:** Each Claude invocation is a fresh process — the env var must be set per-launch. Closing Claude and reopening without the env var restores full enforcement.

## Master Activation Layer (opt-in, durable)

A durable master switch governs whether the `block-*` hook layer is active, so a fresh public clone imposes no *workflow* guards until the operator opts in, and the choice survives `update.sh`.

**State home (durable, update-safe):** `[security_hooks].master_enabled` in the individual-tier XDG file `~/.config/pmo-platform/platform-config.toml` (honors `PMO_PLATFORM_CONFIG_ROOT`). This is an Operator-instance-category surface `update.sh` never overwrites, so the value survives version upgrades. The in-repo `core/config/platform-config.toml.template` ships the schema **default OFF** — a fresh clone with no XDG value resolves OFF. The installer (`docs/scripts/setup-workspace.sh`) writes the opt-in value at install time, default OFF; declining leaves the workflow hooks inert.

**How it is read:** each hook sources `core/hooks/lib/master-enable.sh` (co-deployed to `.claude/hooks/lib/` beside `dep-resolve.sh`) with a guarded source plus a single `master_enable_gate <class>` call, placed immediately after the hook's `CLAUDE_HOOK_BYPASS` check and before its `.mode` read. The reader is jq-free and section-aware. **Fail-toward-current-behavior:** if the lib is missing, the hook does NOT gate — it keeps its existing `.mode` enforcement. A hook that cannot read master state never silently disables itself; this is the deliberate opposite of the fail-closed dependency posture — "cannot read master state" must never equal "guard off".

**Runtime precedence inside each hook (highest first):** `CLAUDE_HOOK_BYPASS` (per-session) → **master-enable** (durable) → **workspace-scope** (per-tool-call) → `.mode` / own-mode (per-hook dial) → rule evaluation. Upstream of all four sits **loading** — whether the session resolved a settings surface declaring the wiring at all.

**Workspace-scope layer (`core/hooks/lib/scope-guard.sh`).** Each hook sources it with the same guarded-source idiom as `master-enable.sh` and calls `scope_guard_gate "$CWD"` at the point where the tool-call payload's working directory is already parsed. The hook is inert for a tool call whose working directory is not under the governed workspace root. It is a **separate lib, not a function in `master-enable.sh`**, because its fail direction is deliberately **inverted on the cwd axis**: an undeterminable working directory resolves to *do not enforce*, since current behavior for a session that cannot be shown to be inside the governed root is "no hooks fire at all". That is the same fail-toward-current-behavior principle master-enable states, evaluated on a different axis — which is exactly why the two must not share a function. On the **lib-presence** axis the direction is **not** inverted and matches master-enable: a missing `scope-guard.sh` does NOT gate, so the hook keeps enforcing. Inverting that axis too would make deleting one file a silent total kill switch for every security-class hook. `block-autonomy-ceiling` places the call after its Tier-0 floor, mirroring where it already places master-activation: that floor is path-scoped, not session-scoped.

**Security scope (the load-bearing invariant).** Master-OFF governs the **workflow-class** hooks only. Two classes are declared at each hook's gate call site:

| Class | Hooks | master-OFF behavior |
|---|---|---|
| **workflow** | `block-draft-files`, `block-fragile-refs`, `block-fs-boundary`, `block-mcp-writes`, `block-skill-direct-edit`, and the mode-gated ceiling of `block-autonomy-ceiling` | hook goes inert (`exit 0`) |
| **security / floor** | `block-credential-reads`, `block-destructive`, `block-rm-prefer-trash`, `block-egress`, `block-gh-path-leak`, `block-scope-segregation`, `block-shell-injection`, plus the `block-autonomy-ceiling` Tier-0 always-block floor and `git-pre-commit-pii` | ALWAYS enforce — never silently disabled |

The security/floor class always enforces because the failure mode — a silently-disabled egress / PII / credential guard leading to a leaked commit or PR on a public repo — is irreversible. The only way a security/floor hook goes inert under master-OFF is the operator's explicit, logged `[security_hooks].security_class_master_optout = true` (a public-surface-safety downgrade the operator consciously accepts). `CLAUDE_HOOK_BYPASS` remains the operator's per-session, audit-logged escape for the always-enforce set. A security/floor hook still honors its OWN per-hook mode dial (`.mode` / `.scope-segregation-mode` / `git-pre-commit-pii.mode`) independently of the master switch.

**Class-declaration integrity.** Each hook declares its class at the gate call site (`readonly MASTER_ENABLE_CLASS=...`) — self-documenting at the edit surface, with no central name-list to drift. A `deploy.sh --check` reconcile check asserts the declared classes match the always-enforce / security registry, so a security hook cannot be silently reclassified as workflow.

**Scope of this layer.** The master switch governs every `core/hooks/block-*.sh` hook, including the non-registry hooks owned by their own discipline docs (`block-skill-direct-edit`, `block-fragile-refs`, `block-gh-path-leak`, `block-draft-files`) — each carries the same gate at its own call site. This layer governs hook *activation*; per-session runtime-config verification (session-launch model/effort posture) is a sibling concern owned by its own hook and documentation, and layers onto this same `CLAUDE_HOOK_BYPASS` / `.mode` precedence chain.

## Allowlist Maintenance

Eight allowlists govern specific surfaces:

| File | Surface | Format | Match |
|---|---|---|---|
| `.claude/script-execution-allowlist.txt` | `bash <path>.sh` invocations | bash glob patterns | shell `case` globbing |
| `.claude/egress-allowlist.txt` | `curl` / `gh api` upload targets | hosts / gh-api path patterns | bash glob |
| `.claude/webfetch-allowlist.txt` | WebFetch domains | domain patterns | bash glob |
| `.claude/ssh-allowlist.txt` | SSH destinations | host patterns | bash glob |
| `.claude/mcp-write-allowlist.txt` | MCP write tools | exact tool names | `grep -Fxq` |
| `.claude/shell-injection-allowlist.txt` | Legitimate script-execution-plus-metachar patterns | bash glob patterns | shell `case` globbing |
| `.claude/fs-boundary-allowlist.txt` | `block-fs-boundary.sh` allowed roots | absolute-path strings (NOT bash glob) | resolved-path prefix-match |
| `.claude/scope-segregation-allowlist.txt` | `block-scope-segregation.sh` known-safe content strings (false-positive escape) | fixed-string substrings | substring match |

These eight are the allowlists the bypass-mode hooks consult. The broader workspace carries additional allowlists owned by other surfaces (e.g. the skill-editor exemption list, the reference-durability allowlist, the doc-link skip list) — those belong to their own discipline docs, not this registry.

> **Coverage boundary — what an allowlist in this table IS and IS NOT.** Each file above is read by a PreToolUse hook, so it constrains a tool call only when that hook is in force — which requires **all four** of these, and fails when any one fails: (1) **loading** — the session resolved a settings surface declaring the hook wiring (any session, main or spawned, whose working directory is under the governed workspace root; a session resolving no such surface loads no hooks at all, and one outside the root is excluded by `core/hooks/lib/scope-guard.sh`); (2) **bypass** — `CLAUDE_HOOK_BYPASS` was not set in the launching environment (layer 1, which exits **both** hook classes, so the security/workflow asymmetry does **not** exist there); (3) **master-activation class** — a `security`-class hook always enforces, a `workflow`-class hook is inert while master activation is off; (4) **mode** — most block hooks warn-and-allow in warn mode, a minority are mode-independent. Naming fewer than four overstates the coverage. Canonical statement: [`core/standards/subagent-security-posture.md` § 3.1](../../standards/subagent-security-posture.md).
>
> Where those conditions hold, an allowlist is a **control**. Where any fails, it is a **convention**: it still records what the platform intends to permit and is still the right thing to maintain, but it is not an interlock and no threat model may treat it as one. Do not accept a residual on the basis that an allowlist "will catch" an invocation without first checking the four conditions on the path that invocation actually runs on.

**Adding entries:** Use the atomic-append helper:
```bash
./.claude/hooks/allowlist-add.sh <allowlist-file> '<entry>'
```

The helper validates that the target is one of the 8 known allowlists and that the entry has no control characters. All additions are logged to `.claude/hooks/allowlist-additions.log`.

**Allowlist files are explicitly excluded from the self-mod guard** (NEW-B BLOCK-DESTRUCTIVE-019) — Claude can append to them without bypass. Only `.claude/settings*.json` and `.claude/hooks/*` are protected.

## Warn-Mode vs. Enforce-Mode

`.claude/hooks/.mode` (shared between `block-egress.sh`, `block-mcp-writes.sh`, `block-shell-injection.sh`, and `block-fs-boundary.sh`):

| Value | Behavior |
|---|---|
| `enforce` | Hook exits 2 on violation (default after initial shakedown) |
| `warn` | Hook logs to `egress-warn-log.jsonl` / `mcp-warn-log.jsonl` / `shell-injection-warn-log.jsonl` / `fs-boundary-warn-log.jsonl` and exits 0 |
| `off` | Hook exits 0 immediately (disables the hook) |

**Destructive + credential-read + rm-prefer-trash hooks always enforce** (high-confidence, narrow rules, low false-positive risk). Egress, MCP writes, shell-injection, and fs-boundary have warn-mode.

**Initial deploy state:** `warn` (fast-path 3-day shakedown). User flips to `enforce` after reviewing warn logs and adding any legitimate false-positive patterns to the relevant allowlist.

## Recovery Procedures

### Hook error loop (all Bash calls blocked)

1. Exit Claude
2. Relaunch: `CLAUDE_HOOK_BYPASS=1 claude`
3. Edit the faulty hook (hook is bypassed so the edit succeeds)
4. Exit Claude
5. Relaunch without env var to restore enforcement

### Missing `jq` dependency

The hook fails OPEN with a loud stderr warning and logs to `.claude/hooks/hook-errors.log`. Install jq: `brew install jq` (or ensure `/usr/bin/jq` exists — macOS 14+ ships jq by default).

### Allowlist overflow / legitimate block

1. Read the block stderr — it includes the specific `allowlist-add.sh` command to run
2. Run the command to add the entry
3. Retry the original action

### Warn-mode shakedown — flip to enforce

After the shakedown period:
1. Review logs: `cat .claude/hooks/egress-warn-log.jsonl`, `cat .claude/hooks/mcp-warn-log.jsonl`, `cat .claude/hooks/shell-injection-warn-log.jsonl`, `cat .claude/hooks/fs-boundary-warn-log.jsonl`
2. Add any legitimate patterns to the respective allowlists
3. Flip `.claude/hooks/.mode` from `warn` to `enforce`
4. Monitor `.claude/hooks/block-log.jsonl` for 48 hours
5. Roll back to `warn` (single-file edit) if issues surface

## Known Limitations

- **Log rotation deferred** — `block-log.jsonl`, `bypass-log.jsonl`, warn logs are append-only and grow unbounded. Follow-up release will add rotation.
- **cwd detection** — Primary-write guard relies on the payload `cwd` field. If Claude-under-injection constructs an absolute-path target (`${HOME}/Claude/CLAUDE.md` while cwd=worktree), the guard allows the write per AC spec. This is a defense-in-depth gap; operator can tighten by changing the rule to deny any primary Layer 1 target regardless of cwd.
- **MCP tool UUID churn** — MCP server UUIDs (e.g., `mcp__8db9f365-...__`) can change on reinstall/reauth. Allowlist entries tied to specific UUIDs need re-add after changes. Future work: support wildcard `mcp__*__<tool_name>` patterns.
- **BSD grep extensions** — Regex uses POSIX-ERE only. On macOS, certain GNU grep extensions (`\b` word boundaries) do not work consistently — we use `([[:space:]]|$)` terminators instead.
- **Hook tamper via `/opt/homebrew/bin`** — PATH pinning is `/usr/bin:/bin` only; if a tool under `/opt/homebrew/bin` were compromised and the hook relied on it, tamper would succeed. We avoid this by using absolute paths for all critical tools (`/usr/bin/grep`, `/usr/bin/jq`, etc., all under `/usr/bin` which is root-owned).
- **`block-rm-prefer-trash.sh` nested-shell** — `bash -c "rm /tmp/foo"` and similar nested invocations bypass the word-boundary regex prefix class (same class of limitation that affects `block-destructive.sh` and `block-egress.sh`). Mitigating would require nested-shell parsing across all regex-based hooks. Defer to a future systemic hardening release.
- **`block-rm-prefer-trash.sh` other deletion mechanisms** — `find ... -delete`, `mv foo /dev/null`, `> file` (truncation) are not classified as deletion verbs and pass the hook. Out of scope for v1; add rules if encountered in practice.
- **`block-rm-prefer-trash.sh` quoted-path tokenization** — Paths containing spaces (e.g., `rm "file with spaces.txt"`) are tokenized incorrectly by simple whitespace splitting. v1 accepts this limitation given the rarity of space-containing paths in this workspace; same mitigation class as the nested-shell limitation above.
- **`block-rm-prefer-trash.sh` `trash` binary may pre-exist outside Homebrew** — The 3-tier auto-detection's tier 1 (`command -v trash` under pinned PATH `/usr/bin:/bin`) may resolve to a user-installed `/usr/bin/trash` on systems where one was placed manually before this hook shipped. The canonical workspace currently has such a binary (root-owned Mach-O universal). This is a feature, not a bug — tier 1 succeeds and the user-visible suggestion is the simplest invocation form. If `/usr/bin/trash` is removed, tier 2 (keg-only path) takes over cleanly.
- **`block-fs-boundary.sh` shell-redirection v1 limitation** — `>`, `>>`, `<` redirection targets are not classified as file-write verbs and pass the hook. v1 covers explicit verbs (cat / head / tail / less / more / base64 / xxd / od / hexdump / strings / cp / mv / tee / dd) only. Operator may extend the hook in a future release if encountered in practice.
- **`block-fs-boundary.sh` nested-shell + quoted-path limitations** — inherits the same class of limitations documented for `block-rm-prefer-trash.sh` (nested `bash -c "cat ..."`, paths with spaces). Out of scope for v1.
- **`block-fs-boundary.sh` settings.deny coverage gap for `~/Library/<unenumerated-subdirs>`** — settings.deny uses per-subdir explicit-deny (Mail, Messages, Calendars, Containers, Group Containers, Cookies, Safari, Chromium, Application Support/Google/Chrome, Application Support/Firefox) rather than `Library/**` catch-all because Anthropic gitignore-spec does not support an allow-inside-deny pattern at the settings.deny layer. The hook closes the gap for Bash commands (resolved-path prefix-match against the allowlist excludes `~/Library/` except the Cowork install path). Read/Edit tool access to unenumerated Library subdirs is accepted v1 residual; operator may add entries to settings.deny if specific subdirs surface as concerns.
- **Path-normalization posture across all hooks (BSD/macOS realpath portability):** Two hooks normalize file paths before applying boundary rules:
  - `block-rm-prefer-trash.sh` (deletion-target normalization)
  - `block-destructive.sh` (Write/Edit primary-write guard `abs_target` resolution at the `[ -e "$FILE_PATH" ]` branch)

  Both hooks normalize via Python `os.path.realpath` invoked through `/usr/bin/python3` (Python 3.9+, system-default on macOS 12+). The other four hooks (`block-egress.sh`, `block-mcp-writes.sh`, `block-credential-reads.sh`, `block-skill-direct-edit.sh`) do not perform path normalization — they rely on regex-based or prefix-based matchers that do not need symlink/`..` resolution.

  Stage 5 specs originally referenced GNU `realpath -m`, but `/usr/bin/realpath` does not exist on macOS and `/bin/realpath` is BSD-only without the `-m` flag. Python `os.path.realpath` is the portable equivalent on BSD/macOS and GNU/Linux alike: collapses `..`/`./`, does not require path existence, follows symlinks (intentional for strict-boundary enforcement). Both hooks degrade gracefully if `/usr/bin/python3` is somehow absent — they fall back to the un-normalized path string, which still catches absolute-path cases via existing prefix-match rules but misses the `../`-escape edge case. Test fixtures at `.claude/hooks/tests/block-destructive.test.sh` cover the `../`-escape edge case for `block-destructive.sh`; `.claude/hooks/tests/block-rm-prefer-trash.test.sh` covers it for `block-rm-prefer-trash.sh`.
- **ssh-agent socket side channel** — Credential-read hooks (BLOCK-CREDENTIAL-READ-001..006) and credential-egress hooks (BLOCK-EGRESS-001..003) gate **file reads** of `~/.ssh/*`, `~/.aws/*`, `~/.config/gh/*`, `.env` variants, `*.pem`, `*.key` via Read tool matchers and command-string regex on Bash tool. They do NOT gate **use of a key already loaded into the OS ssh-agent socket** (the agent inherits `SSH_AUTH_SOCK` from the operator's login environment; `ssh-keygen -Y sign` reads no `~/.ssh/*` path and matches no hook regex). This is a structural property of macOS launchd ssh-agent, not a hook-layer defect — the hook layer scans command strings; the agent socket leaves no command-string fingerprint a regex can match. Accepted residual per operator decision 2026-05-15 (see `SECURITY.md` § Documented Non-Goals — `ssh-agent socket side channel`). **Operational failure mode:** with `commit.gpgsign=true` set globally, any commit (operator or agent) fails when the agent has no key loaded (e.g., post-reboot before keychain auto-load, or after `ssh-add -d`). **Recovery:** `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_signing` reloads the key from Keychain; the global posture resumes. **Hardening migration path (deferred to Phase 4+):** the framework tracks migration to a confirm-on-use agent (1Password SSH Agent OR Secretive with macOS Secure Enclave) where each signing operation requires explicit operator approval, defeating silent injection-driven signing while preserving Verified commits. Same threat-actor surface as the $ARGUMENTS injection class; same hook-layer governance surface as the workspace-boundary hook.

## Shakedown → Enforce Transition Checklist

Before flipping `.mode` from `warn` to `enforce`:

- [ ] At least 3 days of warn-mode activity logged
- [ ] `egress-warn-log.jsonl` reviewed — all entries are either in allowlist or intentional blocks
- [ ] `mcp-warn-log.jsonl` reviewed — same criteria
- [ ] `shell-injection-warn-log.jsonl` reviewed — same criteria
- [ ] `fs-boundary-warn-log.jsonl` reviewed — all entries are either in `.claude/fs-boundary-allowlist.txt` or intentional blocks
- [ ] `allowlist-additions.log` reviewed — all additions have plausible reasons
- [ ] No critical false-positive patterns remaining (i.e., any legitimate action has a working allowlist entry)
- [ ] `block-destructive`, `block-credential-reads`, and `block-rm-prefer-trash` hooks have been exercised without false positives (these are always-enforce)
- [ ] Operator confirms readiness via commit to `.mode` change (note: this flip affects all four warn-mode hooks — `block-egress`, `block-mcp-writes`, `block-shell-injection`, `block-fs-boundary` — simultaneously)

## Related

- [`core/standards/subagent-security-posture.md`](../../standards/subagent-security-posture.md) — Composes-with at Mechanism 2 (hook surface). The PreToolUse hooks documented in this file operate at session level; subagent tool calls fire the same hooks transparently. The subagent-security-posture standard codifies the 4-mechanism defense-in-depth for hub-orchestrated autonomous subagent spawning.
- [`core/standards/secrets-handling-policy.md`](../../standards/secrets-handling-policy.md) — Policy substrate (L4) declaring secret categories, storage matrix, and audit greps. This file is the L2 runtime-enforcement layer that blocks Claude-tool access to the credential paths the policy categorizes. The two compose: the policy says *where* each category lives; this file says *what blocks access* to those locations during a session.
- [`core/standards/canonical-skill-structure.md`](../../standards/canonical-skill-structure.md) — owner of `block-skill-direct-edit.sh` (BLOCK-SKILL-EDIT-001..002), a sibling `core/hooks/` PreToolUse hook outside this bypass-mode registry.
- [`core/standards/reference-durability-standard.md`](../../standards/reference-durability-standard.md) — owner of `block-fragile-refs.sh` (BLOCK-FRAGILE-REF-001..004), a sibling `core/hooks/` PreToolUse hook outside this bypass-mode registry.
