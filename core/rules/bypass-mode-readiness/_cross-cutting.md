<!-- reference-durability: allow-link -->
## Absolute-Path-Aware Verb Anchor

All four regex-based PreToolUse hooks that match Bash verb invocations (`block-destructive.sh`, `block-egress.sh`, `block-fs-boundary.sh`, `block-rm-prefer-trash.sh`) detect verbs invoked at canonical absolute-path prefixes — not only verb-at-command-start. The canonical anchor pattern is:

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

## Command-Start Position Canonicalization

The anchor above recognises a command start at exactly two places: start-of-line, and immediately after `;`, `&` or `|`. A shell starts a command in many more positions than that, so the same verb with the same target received a **different verdict depending on where it sat** — the guard tracked lexical position rather than the action. Wrapping a deletion in a function body was enough to make it invisible, and nothing reported the skip.

All four hooks now canonicalize the command **before** matching, via one shared primitive — `core/hooks/lib/command-position.awk`. Genuine command starts are rewritten into positions the existing anchor already recognises (a `; ` is inserted in front of them). The anchor itself, every rule pattern, every rule ID and every block message are unchanged.

Two properties make the widening safe rather than merely broader:

1. **Insertion-only on the syntactic axis.** The canonicalizer does not delete, reorder or rewrite command text (the single exception is dropping one leading backslash on the verb position, so `\rm` reads as `rm`). Anything the anchor matched before still matches — the change is additive.
2. **Quote-neutralized detection.** Structural characters inside a quoted span cannot open a segment, so shell text carried *as content* — `echo "cleanup() { rm -rf /tmp/x; }" > s.sh`, `sed 's/(rm foo)/X/'`, `grep -E '(rm |mv)' f` — is not treated as a command start. This is load-bearing, not cosmetic: writing a shell script as content is ordinary work in this repo, and a guard that fires on it gets disabled by the operator — a worse security outcome than the gap it closed. Two of those three shapes were blocked *before* this change; quote-neutralization is what makes them allow.

Positions closed: grouping (`{ … }`, `( … )`, function bodies), compound-command keywords (`then`, `do`, `else`, `elif`, `in`), the bounded command-prefix word set (`sudo`, `time`, `env`, `nohup`, `command`, `builtin`, `exec`, `xargs`), `VAR=value` assignment prefixes, leading redirects, and the escaped verb. The prefix set is a **bounded enumeration, never a wildcard** — an unlisted leading word is treated as the command, exactly as before.

`xargs` is a special case: the verb reads its targets from stdin, so no argv target exists. The canonicalizer emits a deliberately variable-shaped `$XARGS-STDIN` sentinel, which routes to each token extractor's **existing** unresolvable-under-strict-policy branch. No new rule ID and no new message were introduced for it.

**Fail direction.** Each hook canaries the primitive before trusting its output — a truncated or corrupt copy would emit an empty string and take the hook's whole matcher with it, which is a fail-OPEN strictly worse than the gap being closed. On canary failure the always-enforce pair (`block-destructive.sh`, `block-rm-prefer-trash.sh`) DENY via `deny_missing_primitive`; the mode-capable pair (`block-egress.sh`, `block-fs-boundary.sh`) deny in enforce and degrade to the raw command in warn — which is exactly their pre-canonicalization behaviour, so warn never loses coverage it already had. Unbalanced quotes make the mask unreliable, so the input is handed back byte-identical for the same reason.

**Deliberately not routed through it:** `BLOCK-DESTRUCTIVE-022` (its segment loop and cumulative quote-parity tracking own their own lexical model and read the raw command), `block-egress.sh`'s `egress_neutralize_quoted()` path for `BLOCK-EGRESS-007`, and the argument-text extractors (osascript POSIX-file paths, URL and ssh-host extraction). Those parse argument text, which canonicalization is not for.

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

The security/floor class always enforces because the failure mode — a silently-disabled egress / PII / credential guard leading to a leaked commit or PR on a public repo — is irreversible. The only way a security/floor hook goes inert under master-OFF is the operator's explicit, logged `[security_hooks].security_class_master_optout = true` (a public-surface-safety downgrade the operator consciously accepts). `CLAUDE_HOOK_BYPASS` remains the operator's per-session, audit-logged escape for the always-enforce set. A security/floor hook still honors its OWN per-hook mode dial (`.mode` / `.scope-segregation-mode` / `.gh-path-leak-mode` / `git-pre-commit-pii.mode`) independently of the master switch.

**Class-declaration integrity.** Each hook declares its class at the gate call site (`readonly MASTER_ENABLE_CLASS=...`) — self-documenting at the edit surface, with no central name-list to drift. A `deploy.sh --check` reconcile check asserts the declared classes match the always-enforce / security registry, so a security hook cannot be silently reclassified as workflow.

**Scope of this layer.** The master switch governs every `core/hooks/block-*.sh` hook, including the non-registry hooks owned by their own discipline docs (`block-skill-direct-edit`, `block-fragile-refs`, `block-gh-path-leak`, `block-draft-files`) — each carries the same gate at its own call site. This layer governs hook *activation*; per-session runtime-config verification (session-launch model/effort posture) is a sibling concern owned by its own hook and documentation, and layers onto this same `CLAUDE_HOOK_BYPASS` / `.mode` precedence chain.

## Allowlist Maintenance

Eight allowlists govern specific surfaces:

| File | Surface | Format | Match |
|---|---|---|---|
| `.claude/script-execution-allowlist.txt` | subprocess script execution — `bash`/`sh`/`zsh <path>.sh` **and** `source` / `.` of a script, including every `.sh`-bearing token after `-c` | bash glob patterns | shell `case` globbing |
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

**Allowlist files are explicitly excluded from the self-mod guard** (NEW-B BLOCK-DESTRUCTIVE-019) — Claude can append to them without bypass. The guard's protected set is `CLAUDE.md`, `pmo-platform/**`, `.claude/settings.json`, `.claude/hooks/*` and `.claude/rules/*`, less that rule's two exemptions (a repo-rooted worktree cwd, and the git-ignored `pmo-platform/analysis/<subfolder>/…` workspace).

## Warn-Mode vs. Enforce-Mode

**Which hooks a mode file reaches is derived, not memorized.** A hook is in a mode file's cohort exactly when its own `MODE_FILE` names that file. Reproduce the shared-`.mode` cohort with:

```
git grep -l 'MODE_FILE="${HOOK_DIR}/\.mode"' -- ':(glob)core/hooks/*.sh'
```

`.claude/hooks/.mode` is currently read by **seven** hooks — four inside this registry (`block-egress.sh`, `block-mcp-writes.sh`, `block-shell-injection.sh`, `block-fs-boundary.sh`) and three owned by other discipline docs (`block-skill-direct-edit.sh`, `block-fragile-refs.sh`, `block-draft-files.sh`). Four further hooks carry their **own** mode file and are unaffected by a `.mode` change: `block-autonomy-ceiling.sh` (`.autonomy-mode`), `block-scope-segregation.sh` (`.scope-segregation-mode`), `verify-session-config.sh` (`.verify-session-config-mode`), `block-gh-path-leak.sh` (`.gh-path-leak-mode`). Giving a hook its own mode file removes it from the shared cohort and adds a row to that list; re-run the command above rather than trusting this paragraph's count after any such change.

**`block-gh-path-leak.sh` left the shared cohort, and the reason generalizes.** Its rule guards a public issue/PR surface and needed its posture promoted on its own evidence. Promoting it through the shared file would have promoted seven unrelated hooks at the same instant, with no shakedown of their own — a cohort dial is the wrong instrument for a per-rule decision. It now reads `.gh-path-leak-mode` and reads it **exclusively**: the shared `.mode` is never consulted, in either direction, so a later cohort flip cannot re-flip it and a shared file set to `off` cannot silence it.

**Two mode-precedence models coexist in this platform deliberately — do not harmonize them.** A hook with its own mode file reads that file *exclusively*, with no fallback to the shared `.mode`. The deploy-check cohort resolves the opposite way: `resolve_check_mode()` in `core/deploy/deploy.sh` prefers a per-check file and *falls back* to the shared `deploy-check.mode`. Both apply most-specific-wins; they differ on what a missing specific value should mean, because the cost functions differ. The check cohort is a **reporting** cohort — a dialed-down check still reports, so a fallback costs visibility. The hook cohort is an **enforcement** cohort — a dialed-down hook stops guarding, and on a public surface the resulting exposure is IRREVERSIBLE. A future reader who unifies these two on consistency grounds re-couples a security guard to a dial it was deliberately removed from.

**What the `.gh-path-leak-mode` dial does and does not reach.** Mode is condition 4 of the four conditions in § Master Activation Layer — loading, bypass, master-activation class, mode. This hook ships at `warn`, and **its posture is not the binding constraint on whether it runs at all**: condition 1 (loading) fails for any session rooted in the repo or a worktree, because the PreToolUse wiring exists only at the workspace-project settings surface. That is remedied by an operator running `docs/scripts/setup-workspace.sh --rehome-hook-wiring`, reported afterwards by the `INSTALL-HOOK-WIRING-REHOME` check in `docs/scripts/validate-install.sh`. **No mode change substitutes for it, and a flip to `enforce` is never the remedy for it.**

**Why the enforce flip is deferred, and what has to happen before it can be decided.** The warn window to date produced zero deployed warn-log lines, and that is no evidence either way: a zero whose instrument was never connected measures the wiring, not the behavior. The flip therefore waits on real log data — which requires the re-home first. Because `warn` plus un-re-homed produces an *empty observable set* indistinguishable from `shipped and clean`, the re-home is tracked as a post-deploy operator action **with a verification**, not as a note: read the `INSTALL-HOOK-WIRING-REHOME` verdict first, and only then is a warn-log reading interpretable at all. Carried with the flip decision: promoting this rule to `enforce` returns a hard block on the operator's own `gh` writes, so the escape surface (the `path-leak: allow` marker, `CLAUDE_HOOK_BYPASS=1`, and `.gh-path-leak-mode=off`) must be re-checked against real warn-log evidence at that point.

| Value | Behavior |
|---|---|
| `enforce` | Hook exits 2 on violation (default after initial shakedown) |
| `warn` | Hook logs to its own warn log (`egress-warn-log.jsonl`, `mcp-warn-log.jsonl`, `shell-injection-warn-log.jsonl`, `fs-boundary-warn-log.jsonl`, …) and exits 0 |
| `off` | Hook exits 0 immediately (disables the hook) |
| `LIB-MISSING` (any value) | **Mode-coupled.** When `lib/dep-resolve.sh` is absent, unreadable, unparseable or stale, a hook with a mode surface denies (`exit 2`, `BLOCKED (fail-closed)`) in `enforce`, and in `warn`/`off` exits 0 after emitting a `[CLAUDE-HOOK:<hook>:LIB-MISSING] WARN (degraded, …)` notice on stderr. The notice is emitted in `off` as well as `warn`: `off` disables *rule enforcement*, not *install-integrity reporting*, and a silent degrade would leave nothing for an operator to notice. Recovery is a bundle reinstall — see § Recovery Procedures. |

**Destructive + credential-read + rm-prefer-trash hooks always enforce** (high-confidence, narrow rules, low false-positive risk) and have no mode surface at all.

**One exception, and it is a per-RULE-ARM exception rather than a hook-level one.** `block-destructive.sh` reads no mode file and is not part of any `.mode` cohort — that is unchanged. But BLOCK-DESTRUCTIVE-022 now carries **two** phase-gated widenings, each on its own per-rule constant declared in the hook and each currently reading `warn`, so both record rather than block: the third arm (direct execution, added when the rule's scope was widened to execution capability) behind `DESTRUCTIVE_022_EXEC_PHASE`, and the **non-shell interpreters** (`python`, `python3`, `perl`, `ruby`, `node`, admitted to the interpreter arm's verb set) behind `DESTRUCTIVE_022_INTERP_PHASE`. The families are separate so the two rollouts can retreat independently. The interpreter arm's **shell** verbs and the source arm remain always-enforce and are not routed through either router. The distinction matters when reading this section: "always-enforce" still describes the hook's relationship to the shared dial, and it no longer describes every arm of every rule inside it. A per-rule rollout constant is deliberately not a fifth condition on the four-condition coverage boundary — it is a property of one arm, and it is stated in that rule's own fragment where its coverage boundary lives. The seven `.mode` readers listed above have warn-mode, as do the four hooks reading their own mode file.

**The always-enforce three keep an unconditional `LIB-MISSING` deny, and that is load-bearing rather than incidental.** Their matchers span Read, Bash, Write and Edit, so a missing helper stays immediately visible even while the mode-capable cohort is degrading — which is the property that makes degrading the cohort acceptable in the first place. `core/hooks/tests/check-hook-dep-hardening.sh` CHECK-4 fails if one of the three acquires a mode-coupled guard.

**Scope of the attestation guarantee across the corpus — read this before generalising the paragraph above.** The out-of-process contract attestation described here is implemented on the **always-enforce three only**. Every other hook that sources the same dependency helper retains the prior guard shape and therefore the identical corruption exposure: a syntactically valid helper whose top level runs `exit 0` defeats their `-n` syntax precheck by construction. This section describes corpus-wide posture, so the narrower guarantee is stated here rather than left to the decision record — a green dependency-integrity result on the floor does **not** close the class for the mode-capable cohort.

**Scope of that guarantee, stated plainly.** The deny holds for a helper that is **absent · unreadable · truncated · syntactically valid but semantically corrupt (including a top level that runs `exit 0`, and the define-every-symbol-then-exit variant) · version-skewed (carrying the wrong contract token) · swapped mid-guard between the out-of-process check and the in-process source**. The guarantee is asserted rather than described: `core/hooks/tests/hook-fail-closed.test.sh` section (6) executes every one of those states against all three hooks with every mode file present and set `off`, and requires both `exit 2` and a readable block message. It pairs each with a healthy-lib control — a benign payload that must still be allowed and a violating payload that must still be denied on the hook's own rule — because a matrix proving only denial would pass a guard that denies everything.

The mechanism is that the helper is **attested out of process before it is admitted to the hook's shell**, so a helper that terminates the shell can never produce the token the guard requires; an `EXIT` trap covers the in-process source that cannot be eliminated, writing to a saved stderr descriptor because the redirection suppressing the source's diagnostics is still in effect while the trap body runs; and the expected contract value is captured `readonly` above any source, since a sourced file cannot overwrite a readonly. `bash -n` is deliberately **not** the control — a syntax check verifies that the helper parses, never that it means what the hook expects, and it passes a top-level `exit 0` by construction. The governing decision record is the hook-dependency integrity invariant ADR in `core/ADRs/`, which supersedes in part the mode-coupling record's narrower statement of this guarantee.

**What remains outside the guarantee, and why it is not a boundary the guard can hold.** An **adaptive** helper that satisfies the out-of-process attestation and then defeats the in-process layer still yields an allow. Stripping the `EXIT` trap is one route and **not the only one**: the guard's verdict variable is writable, so a helper that assigns it the passing value and then exits reaches the same outcome without touching the trap. The earlier wording named only the trap and so under-described its own boundary. That is a *compromise* rather than a *corruption*: it requires code that detects which evaluation it is in. The helper and the hook that sources it ship with identical ownership and identical write permissions, so a writer able to do that can replace the hook itself — no in-process check is a security boundary against them. The guard is specified to the corruption-and-partial-install population and claims nothing beyond it.

**One consequence to know before editing the helper.** The contract token is a breaking-change signal: bump it only when the helper's contract changes, and edit every carrier in the same commit. A skewed token denies every matching tool call across the floor, and `CLAUDE_HOOK_BYPASS` cannot clear it. `check-hook-dep-hardening.sh` CHECK-6 fails the build on disagreement, so skew introduced in the repository cannot reach a deploy — but a hand-edited or partially-installed *deployed* bundle is outside its reach, and recovery for that is the bundle reinstall in § Recovery Procedures. The helper must also stay side-effect-free at its top level: it is now evaluated twice per invocation, once for attestation and once for real.

**Initial deploy state:** `warn` (fast-path 3-day shakedown). User flips to `enforce` after reviewing warn logs and adding any legitimate false-positive patterns to the relevant allowlist.

## Recovery Procedures

### Hook error loop (all Bash calls blocked)

1. Exit Claude
2. Relaunch: `CLAUDE_HOOK_BYPASS=1 claude`
3. Edit the faulty hook (hook is bypassed so the edit succeeds)
4. Exit Claude
5. Relaunch without env var to restore enforcement

**`CLAUDE_HOOK_BYPASS` does not clear a `LIB-MISSING` block.** The `lib/dep-resolve.sh` guard is evaluated *before* the bypass check in every hook that carries it, so a missing or corrupt helper blocks regardless of the environment variable. The procedure above applies to rule-match and hook-error loops, not to helper-integrity failures. Recovery for that class is a **hook-bundle reinstall from your own terminal** — `bash docs/scripts/setup-workspace.sh` — which the hooks do not gate, because they gate the agent's tool calls and not the operator's shell. Since the guard became mode-coupled, a hook whose mode file reads `warn` or `off` degrades instead of blocking and prints the reinstall instruction itself; the hard block now comes only from `enforce` and from the three always-enforce hooks.

### Missing `jq` dependency

The hook fails **CLOSED**: `deny_missing_dep` emits a `DEPENDENCY-MISSING` block naming the missing tool and exits 2, and the hook logs to `.claude/hooks/hook-errors.log`. A security control that cannot evaluate its input must deny, never allow (`GHSA-9cjm-v22x-4x33`); the historical fail-open behavior described here previously is the defect that advisory removed. Mode-capable hooks degrade to exit 0 with a stderr notice in `warn`/`off`; the always-enforce three deny regardless. Install jq: `brew install jq` (or ensure `/usr/bin/jq` exists — macOS 14+ ships jq by default).

### Allowlist overflow / legitimate block

1. Read the block stderr — it includes the specific `allowlist-add.sh` command to run
2. Run the command to add the entry
3. Retry the original action

### Warn-mode shakedown — flip to enforce

After the shakedown period:
1. Review logs: `cat .claude/hooks/egress-warn-log.jsonl`, `cat .claude/hooks/mcp-warn-log.jsonl`, `cat .claude/hooks/shell-injection-warn-log.jsonl`, `cat .claude/hooks/fs-boundary-warn-log.jsonl`, `cat .claude/hooks/destructive-warn-log.jsonl`
   - **`destructive-warn-log.jsonl` is listed here to be READ, not to be flipped by this procedure.** It is the drain for **both** of BLOCK-DESTRUCTIVE-022's phase-gated arms — the exec arm and the non-shell interpreter arm — each gated by its own per-rule constant (`DESTRUCTIVE_022_EXEC_PHASE`, `DESTRUCTIVE_022_INTERP_PHASE`), not by `.mode`; flipping `.mode` neither advances nor retreats either. Rows carry an `arm` field (`exec` | `interp-nonshell`) so the two graduations are separable; a row with no such field predates the field and belongs to the exec arm, which was then the only writer. It appears in this list because a drain nobody is told to read is the failure this whole subsection exists to prevent. Its own graduation is forced by `deploy.sh` Check 71, on a committed deadline rather than on this review.
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
- **Command-start position — SAME-SHELL positions CLOSED, nested-shell positions STILL OPEN.** Read both halves; the first is not the second. The mechanism is the shared canonicalizer `core/hooks/lib/command-position.awk`, described in the § Command-Start Position Canonicalization section of this file.
  - **Closed** (all four regex-anchored hooks): same-shell command starts the anchor could not see — grouping (`{ … }`, `( … )`, function bodies), compound-command keywords (`then`/`do`/`else`/`elif`/`in`), the bounded command-prefix word set (`sudo`, `time`, `env`, `nohup`, `command`, `builtin`, `exec`, `xargs`), `VAR=value` assignment prefixes, leading redirects, and the escaped verb (`\rm`).
  - **Still open — `nested-shell`:** `bash -c "rm /tmp/foo"`, `sh -c "…"`, `eval '…'`, `alias x='…'`, and command-substitution / backtick bodies. These carry a program string for *another* shell, which a lexical matcher does not parse; delimiter recognition is deliberately suppressed inside `$( … )` for the same reason. Mitigating requires nested-shell parsing across all regex-based hooks. **Defer to a future systemic hardening release** — filed as its own item. **Still open for every rule listed here, including `BLOCK-EGRESS-007`** — the token-level rewrite described below closes the tokenization residual for that rule but does not descend into a nested shell's program string.
  - **Still open — other deletion mechanisms:** `find … -exec rm`, `find … -delete`. Same residual class as below.
  - **Still open — rule-local terminator classes.** Closing the *position* does not close a rule whose own pattern then rejects the match. `BLOCK-DESTRUCTIVE-004` terminates its target with `([[:space:]]|$|/\*)`, which does not admit `;`, so `{ rm -rf /; }` reaches the rule at a correct command start and is still declined by the terminator class. Measured, not inferred: the identical payload with a space before the `;` DOES fire. That is a defect in the rule's own pattern rather than in the anchor, and is tracked separately with the root-filesystem guard; the containment guard `BLOCK-TRASH-001` denies these payloads today.
  - **A lexical matcher has a coverage boundary by construction** — it approximates a grammar it does not parse. Every extension buys a bounded set of positions and cannot buy completeness. This change is explicitly NOT class closure.
- **`block-rm-prefer-trash.sh` other deletion mechanisms** — `find ... -delete`, `mv foo /dev/null`, `> file` (truncation) are not classified as deletion verbs and pass the hook. Out of scope for v1; add rules if encountered in practice.
- **Quoted-path tokenization — now a PER-HOOK split, not a blanket residual.** Simple whitespace splitting tokenizes a quoted operand incorrectly, and an unstripped quote leaves a token that matches no allowlist pattern. The residual is open or closed *per rule*, and recording it as one blanket limitation is no longer accurate:

  | Surface | State |
  |---|---|
  | `block-rm-prefer-trash.sh` | **OPEN.** Paths containing spaces (e.g. `rm "file with spaces.txt"`) still tokenize incorrectly. Accepted given the rarity of space-containing paths in this workspace; same mitigation class as the nested-shell limitation above. |
  | `block-fs-boundary.sh` | **OPEN.** Inherits the same class — see its own entry below. |
  | `block-destructive.sh` `BLOCK-DESTRUCTIVE-022` | **CLOSED.** The operand is quote-normalized before the allowlist filter, so a quoted script path is adjudicated rather than falling through. |
  | `block-egress.sh` `BLOCK-EGRESS-007` | **CLOSED, structurally.** The matcher neutralizes quoted spans during tokenization, so bare, single-quoted and double-quoted spellings of one path produce one token and one verdict. Closed by construction rather than by a strip applied to an extracted token. |
  | `block-egress.sh` all other rules | **OPEN.** `-001`..`-006` and `-008`..`-011` remain regex-anchored and carry the original limitation. |

  A reader who takes this as a blanket residual will either re-fix something already closed or assume cover that two of these surfaces do not have.
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
- [ ] `destructive-warn-log.jsonl` reviewed — **read-only for this flip, and read PER ARM.** It belongs to BLOCK-DESTRUCTIVE-022's two phase-gated arms, each graduating on its own constant and its own deadline (`deploy.sh` Check 71 reports a verdict per family), not on `.mode`. Split the rows on the `arm` field before drawing any conclusion — a combined count is evidence for neither decision. Reviewing it here keeps it from going unread; flipping `.mode` does not move it.
- [ ] `allowlist-additions.log` reviewed — all additions have plausible reasons
- [ ] No critical false-positive patterns remaining (i.e., any legitimate action has a working allowlist entry)
- [ ] `block-credential-reads` and `block-rm-prefer-trash` hooks have been exercised without false positives (these are always-enforce). **`block-destructive` is no longer wholly in that category and must not be checked off as if it were:** its **shell** interpreter verbs and its source arm are always-enforce, but its exec arm and its **non-shell interpreter** verbs are each phase-gated at `warn`, so "exercised without false positives" cannot be asserted for the rule as a whole from a run in which two of its widenings could not produce a block. Assess the always-enforce verbs here and read the drain — split on the `arm` field — for the other two.
- [ ] Operator confirms readiness via commit to `.mode` change (note: this flip affects **every** hook whose `MODE_FILE` names the shared `.mode`, simultaneously — currently seven: `block-egress`, `block-mcp-writes`, `block-shell-injection`, `block-fs-boundary`, **plus the three registry-external readers** `block-skill-direct-edit`, `block-fragile-refs`, `block-draft-files`. It does **not** affect the four hooks carrying their own mode file, each of which graduates on its own evidence. Re-derive the cohort before flipping — see § Warn-Mode vs. Enforce-Mode for the command)

## Related

- [`core/standards/subagent-security-posture.md`](../../standards/subagent-security-posture.md) — Composes-with at Mechanism 2 (hook surface). The PreToolUse hooks documented in this file operate at session level; subagent tool calls fire the same hooks transparently. The subagent-security-posture standard codifies the 4-mechanism defense-in-depth for hub-orchestrated autonomous subagent spawning.
- [`core/standards/secrets-handling-policy.md`](../../standards/secrets-handling-policy.md) — Policy substrate (L4) declaring secret categories, storage matrix, and audit greps. This file is the L2 runtime-enforcement layer that blocks Claude-tool access to the credential paths the policy categorizes. The two compose: the policy says *where* each category lives; this file says *what blocks access* to those locations during a session.
- [`core/standards/canonical-skill-structure.md`](../../standards/canonical-skill-structure.md) — owner of `block-skill-direct-edit.sh` (BLOCK-SKILL-EDIT-001..002), a sibling `core/hooks/` PreToolUse hook outside this bypass-mode registry.
- [`core/standards/reference-durability-standard.md`](../../standards/reference-durability-standard.md) — owner of `block-fragile-refs.sh` (BLOCK-FRAGILE-REF-001..004), a sibling `core/hooks/` PreToolUse hook outside this bypass-mode registry.
