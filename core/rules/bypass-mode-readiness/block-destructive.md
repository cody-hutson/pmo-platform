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

> **What BLOCK-DESTRUCTIVE-022 resolves, and what it cannot.** Given all four conditions above, the rule adjudicates **the file that executes** — the first non-flag operand of each command on the line whose command word is `bash`, `sh`, `zsh`, `source`, or `.`. Both verb families run through **one** matcher, so the guarantees below hold identically for an interpreter invocation and for a sourced file; sourcing executes the file's contents in the current shell, which is the same execution capability, not a lesser one.
>
> It resolves: a path in single or double quotes; a path behind flags (`bash -x <script>`, `. -x <file>`); a script passed as an *argument* to another script (the argument is not what executes, so the executed script is what is checked); and a verb preceded by a **prefix run** — **variable assignments** (`VAR=v bash <script>`) and **transparent command wrappers** from a bounded set (`sudo`, `env`, `command`, `builtin`, `exec`, `nohup`, `time`, `xargs`, and the compound-command keywords `then`, `do`, `else`, `elif`, `in`, `!`), in any order and interleaved — because command position is resolved by walking that prefix run rather than by assuming the first token. The wrapper set mirrors the one in `core/hooks/lib/command-position.awk`, matched on the token's basename so `/usr/bin/env bash <script>` resolves too; its gating direction is that a word **missing** from it leaves an invocation un-adjudicated (the status quo) and can never admit an evasion that would otherwise have been caught. It evaluates **every** command on a line, so an allowlisted first command does not shield a later one across `;`, `&&`, `||`, or `|`.
>
> One consequence of `xargs` being in that set is worth stating on its own. `xargs <interpreter> <path> …` executes `<path>`, which is adjudicated normally — an allowlisted target still allows. `xargs <interpreter>` with **no** argv operand takes its operand list from **stdin**, which a PreToolUse hook cannot see, so the executed target is unresolvable and the invocation **fails closed** (denied), on the same reasoning as the variable-bearing path below.
>
> **The candidate operand differs per verb, and neither is "any path".** The interpreter arm adjudicates an operand ending in `.sh`; an extensionless or differently-suffixed operand (`bash /tmp/evil`) is **not** adjudicated by it. The `source`/`.` arm adjudicates a path-shaped operand — one beginning `/`, `./`, `../`, or ending `.sh` or `.bash`. Two consequences worth stating rather than leaving to be discovered: a literal `~/…` operand reaches the filter only through the `.sh`/`.bash` branches, because the tilde branch is subject to tilde expansion when used as a shell pattern and so never matches a literal tilde token; and an operand that is neither path-shaped nor `.sh`-suffixed is outside both arms.
>
> It **cannot** resolve a **variable-bearing path** — a PreToolUse hook sees unexpanded argv, so `bash "$DIR/x.sh"` has no resolvable target. That case **fails closed** (denied) on **both** verbs, consistent with the dependency gate's posture that a control which cannot evaluate its input must deny rather than guess. Invoke with a literal path, or register the resolved path.
>
> **Quoted-fragment suppression (why a described execution is not a blocked one).** The matcher is lexical: it splits raw argv on separators, so a separator and an interpreter appearing inside a **quoted argument** are shredded into fragments that look like commands. To stop the rule firing on text that *describes* an execution rather than performing one, such a fragment is skipped — but the test for "fragment" is **not** whether its own quotes balance. Quote parity cannot decide it: `bash <script>.sh --msg "it's here"` is a real execution whose segment carries one `'`, and `bash -c 'echo hi; bash <script>.sh'` puts a real command in an odd-parity fragment of a program string that genuinely executes. Odd parity is ordinary well-formed shell, not evidence that nothing ran.
>
> The discriminator has **two** conditions, and a segment is skipped only when **both** hold.
>
> The first is **who opened the quote**. Quote state is tracked across the whole command under shell quoting rules (inside `'…'` only the closing quote is special; inside `"…"` a backslash escapes the next character; inside `$'…'` a backslash escapes the next character too, so `\'` does *not* close it — a separate state, because reading it under the `'…'` rule ends one quote out of phase; outside quotes a backslash escapes the next character, so `\'` opens nothing). The command that opened the quote must be one of a small allowlisted set of verbs that cannot evaluate their arguments (`gh`, `printf`, `echo`, `jq`). `git` is deliberately **not** in the set: `git -c alias.x='!<cmd>' x` evaluates its own quoted argument, so it fails the set's membership criterion.
>
> The second is **whether the quoting construct itself expands anything**. `'…'` and `$'…'` perform no expansion, so they are inert unconditionally. `"…"` performs parameter expansion, command substitution and arithmetic expansion, so a double-quoted run is skippable only while **untainted** — no `$` and no backtick seen since it opened. An escaped `\$` or ``\` `` does not taint, because the backslash is matched first and consumes the character after it.
>
> **The invariant, and the thing to check any edit against:** *a suppression may fire only when the enclosing context provably cannot cause the shell to evaluate the segment.* A segment whose start state is *outside quotes* begins at **command position** and is **always** adjudicated — which covers unquoted `$( … )`, backticks and `<( … )` with no extra rule. Condition 1 is what keeps `bash -c '…'` safe: the quote is opened by `bash`, so no prefix in front of it (`echo x; bash -c '…'`) can reattribute the program string to `echo`. Condition 2 is what keeps `echo "$( … )"` safe: **the shell** expands a command substitution before the enclosing verb ever runs, so a verb that genuinely cannot evaluate its argument does not have to — `$( )` does not *prefix* the inner command, it *encloses* it, and enclosure is not answered by asking about the carrier. Tainting on `$` and the backtick covers the class by construct rather than by shape, since every expansion inside `"…"` is introduced by one of those two characters.
>
> **Heredocs are outside the model, so suppression is switched off entirely for any command containing `<<`.** A heredoc body line is not a command line, but the matcher splits on newlines and cannot tell: a body line that opens a quote poisons the carried state, and a real execution after the terminator would then read as interior to it. Declining to suppress is the fail-closed answer to a construct the model does not cover; the cost is that `<<`-bearing commands keep the false positive.
>
> The gating direction is deliberate and is the second property to preserve if the set is ever edited: a verb **missing** from it means a false positive persists, and can never mean an evasion is admitted. The inverse construction — a denylist of *evaluating* verbs — would make one missed entry a silent fail-open, which is not an acceptable trade inside a fail-closed control.
>
> Forms **out of this rule's scope** by construction, not by defect: direct execution of an executable script (`./x.sh`, no interpreter token) is not an interpreter invocation; a script fetched or generated at runtime is not visible as a path at PreToolUse time; **`eval` and `timeout`** are deliberately *not* in the wrapper set above — `eval` re-parses a program string this lexical matcher cannot resolve (the same nested-shell residual `command-position.awk` records for `bash -c '…'`), and `timeout` carries a duration operand the walk would additionally have to consume; a wrapper's **own flags** terminate the walk, so `sudo -u u bash <script>` and `xargs -n1 bash` resolve to the flag and are not adjudicated; and **grouping constructs** (`{ bash <script>; }`, `( bash <script> )`) are a *segmentation*-layer residual rather than a prefix one — the -022 splitter separates on `;`, `&`, `|` and newline only, so a verb behind `{` or `(` is not at a segment head for the walk to reach.
>
> An earlier revision of this note recorded the whole wrapper class as deliberately open, on the reasoning that closing it "requires a denylist of evaluating verbs" whose one missed entry would be a silent fail-open. That reasoning belongs to the **suppression** set two paragraphs above, where a missed entry does exactly that. It does not transfer here: the wrapper set gates *adjudication*, not suppression, so its failure directions are the mirror image — a missing word leaves the status quo, and a wrongly-included word over-blocks, which is recoverable. The class is now closed for the enumerated words and the residuals above are what remain.

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
