<!-- reference-durability: allow-link -->
## `block-fs-boundary.sh` (BLOCK-FS-BOUNDARY-001..004)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-fs-boundary.sh` |
| Matcher | Bash |
| Scope | Workspace-boundary scoping for Bash file commands beyond settings.deny coverage (cat/head/tail/sed); file-read (cat/head/tail/less/more/base64/xxd/od/hexdump/strings) + file-write (cp/mv/tee/dd) source+target; resolved-path prefix-match against `.claude/fs-boundary-allowlist.txt`; expansion-bearing operands dispositioned by an ordered guard cascade over their literal spans (refuse the ambiguous, the `$(` and backtick execution surfaces and the traversing, classify a decidable prefix, admit-and-record the undecidable) |
| Mode | Warn-mode initial (shared `.claude/hooks/.mode`); flip-to-enforce per the [`§ Shakedown → Enforce Transition Checklist`](../bypass-mode-readiness.md) |

Added in the modular-monolith-cleanup release. Composes with Anthropic's native `settings.deny` `Read(...)` / `Edit(...)` rules (which natively cover the Read tool, Edit/Write tools, and the recognized Bash file-command subset cat/head/tail/sed per `code.claude.com/docs/en/permissions`). This hook closes the residual Bash gap for cp / mv / tee / dd / base64 / xxd / od / hexdump / strings / less / more. Mode-gated via shared `.claude/hooks/.mode` (same file as `block-egress` + `block-mcp-writes`) — initial state `warn` per Shakedown → Enforce Transition Checklist.

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-FS-BOUNDARY-001 | File-read verb (`cat` / `head` / `tail` / `less` / `more` / `base64` / `xxd` / `od` / `hexdump` / `strings`) with resolved target path outside the allowed roots in `.claude/fs-boundary-allowlist.txt` |
| BLOCK-FS-BOUNDARY-002 | File-write verb (`cp` / `mv` / `tee` / `dd`) with resolved source OR target path outside the allowed roots in `.claude/fs-boundary-allowlist.txt` |
| BLOCK-FS-BOUNDARY-003 | Operand refused by the guard cascade below: the `xargs` stdin sentinel (G0), a quoted structural construct carrying the canonicalizer's sentinel (G1), a `$(...)` subshell or backtick execution surface (G2), or a literal `..` traversal component / absent cwd for a relative token / unavailable path normalizer (G3) |
| BLOCK-FS-BOUNDARY-004 | **Advisory, non-blocking.** An expansion-bearing operand with no decidable literal prefix to classify — the genuinely undecidable class. Admitted, and recorded on every invocation that reaches the verb check. **The disposition is mode-independent; the record is not.** It never blocks at any `.mode` value, `enforce` included — but at `.mode=off` the hook exits before the verb check, so no advisory record is written. Recording is scoped to `warn` and `enforce` |

**Settings.deny pairing:** the hook's verb coverage closes the residual Bash gap; for the Read tool, the Edit/Write tools, and the recognized Bash subset (cat / head / tail / sed), Anthropic's native `permissions.deny` rules in `.claude/settings.json` are the primary line of defense. The two surfaces are kept coherent — the deny patterns mirror the allowlist's negative space for the Read/Edit Anthropic surfaces (per-subdir explicit deny for `~/Documents/`, `~/Desktop/`, `~/Music/`, `~/Pictures/`, `~/Movies/`, `~/Public/`, the high-risk `~/Library/` subdirs, and other-user homes `//Users/<other-user>/**`). Per Stage 5 spec Section 1, the two surfaces are not perfectly DRY by design — `settings.deny` is deny-list-based while the hook is allowlist-based; the gitignore-spec syntax used by `settings.deny` does not support an "allow inside a deny region" pattern, so `~/Library/Application Support/Claude/local-agent-mode-sessions/` (the Cowork install path required by `deploy.sh --deploy`) is preserved via per-subdir explicit-deny on the Library sub-paths that need blocking, leaving the install path accessible.

> **Limit of that pairing — it does NOT cover the `-004` residual.** `settings.deny` entries are **path-pattern** rules (e.g. `Read(//Users/*/.ssh/**)`); they cannot expand `$X` any more than this hook can. The pairing paragraph above is true for **literal** paths only. An operand admitted under `-004` — `cat "$X"` where `$X` expands to an out-of-boundary path — is therefore **not** caught by a second layer, and it is wrong to describe it as defence-in-depth. What bounds the residual is the cascade itself (every *decidable* hostile shape stays refused) plus the `-004` record, which keeps the admitted class measurable so a later narrowing has data — **on an instance where the hook actually runs.** That second bound is mode-scoped and the first is not: at `.mode=off` the hook exits before the verb check, so the class is still admitted but nothing is recorded, and the measurability argument holds for `warn` and `enforce` only. An operator reading this table to decide an enforce flip should read the `-004` record count from a `warn`-mode instance; a zero count on an `off` instance is the dial, not the population.

### Path Resolution — block-fs-boundary.sh

For each target token extracted by `extract_target_tokens(verb)` (flag tokens skipped, same chained-command tokenizer as `block-rm-prefer-trash.sh`):

1. Strip surrounding single/double quotes.
2. **Guard cascade over the operand's literal spans** (classify the skeleton, not the token). Evaluated in this order — *refuse-before-decide*, so an ambiguous or executable construct can never reach the code that could admit it:

   | Guard | Condition | Disposition | Rule ID |
   |---|---|---|---|
   | G0 | token is exactly `$XARGS-STDIN` (the canonicalizer's stdin sentinel) | REFUSE | `-003` |
   | G1 | token carries the canonicalizer's quoted-span sentinel | REFUSE | `-003` |
   | G2 | token contains `$(` or a backtick — execution surface | REFUSE | `-003` |
   | G3 | a literal span holds a `..` component; or the token is relative and `payload.cwd` is absent; or python3 is unresolvable / `realpath` fails | REFUSE | `-003` |
   | G5 | a decidable literal prefix (text before the first expansion, truncated at its last `/`) resolves **outside** all allowed roots | REFUSE | `-001` / `-002` |
   | G4 | that decidable literal prefix resolves **inside** an allowed root | ALLOW, silent | — |
   | G6 | no decidable prefix — the operand opens with an expansion | ALLOW, recorded at `warn`/`enforce` (no record at `.mode=off`) | `-004` |

   An **expansion span** is `$NAME`, the `$1`/`$@`/`$#`-class, or an *unquoted* `${…}`. Each is substituted with a sentinel that is a single path segment containing no `/` and no `.`, so an expansion can never introduce a separator or a traversal component into the skeleton that steps 3–6 then classify. A `$` that introduces none of those shapes is **not guessed at** — the split fails and the operand is refused.

   > **Why a *quoted* `${…}` is refused rather than parsed.** `core/hooks/lib/command-position.awk` replaces command-structural characters inside a quoted span with a sentinel byte. On the canonicalized stream this hook actually reads, a quoted `${VAR}` and a quoted `$(cmd)` are therefore **byte-identical**. **Any policy that admits braced parameter expansions silently admits command substitution.** G1 refuses on the sentinel instead of parsing the brace, which handles the ambiguity locally and leaves the shared canonicalizer untouched. An *unquoted* `${…}` keeps its own glyphs, so G2 reads it directly: an unquoted `$(` or backtick is caught there, and every other unquoted brace form passes G1 and G2 to the rest of the cascade — one carrying a parameter-transformation operator included, as the coverage boundary below declares. Do not "simplify" G1 into a brace test: it would re-admit quoted command substitution, and the suite's three-way G1 arm exists to fail exactly that edit.
   >
   > **Why G0 is carved out.** The canonicalizer routes an `xargs` denial **through** this unresolvable branch, emitting the literal token `$XARGS-STDIN`. A rule that allowed on a leading expansion would parse it as `$XARGS` plus a literal `-STDIN`, find an empty prefix, and admit it — turning that denial off with no other arm noticing. G0 is ordered ahead of the `$NAME` parser for that reason.
   >
   > **Coverage boundary of G2 — what it reads, and what it is declared not to cover.** G2 reads the operand's own text for two execution surfaces, `$(` and a backtick, and refuses either wherever it appears; inside balanced quotes the canonicalizer has already masked both, and G1 refuses them first. Parameter-transformation operators are NOT refused at G2. `${parameter@operator}` is a bash parameter expansion; on a shell that implements it, its `P` member re-expands the variable's *value* as a prompt string, which performs command substitution — an execution surface with no `$(` and no backtick anywhere in the operand. Older bash releases and zsh reject the operator outright; the suite's `XFORM-SEM-01` arm runs the demonstration on the first bash at five fixed locations that accepts the operator, and reports NOT-EVALUATED where none does. Unquoted, such an operand is an expansion span like any other brace form: admitted under G6 when no decidable literal prefix precedes it, with a `-004` record wherever the hook reaches its verb check (`warn` and `enforce`, never `.mode=off`); admitted silently under G4 behind a decidable prefix inside an allowed root; and refused under G5 behind one outside every allowed root. Quoted, it is refused — by G1, which refuses every quoted brace, and only while the canonicalizer's quote mask is available: unbalanced quotes hand the command back unchanged, and the quoted form then takes the unquoted one's verdict. The difference between the two spellings is G1's, not a judgment about the operator. All of this concerns an operand the token walk hands to the cascade; a word it never hands over is not examined at all, whatever it carries — a flag-position word such as `-${VAR@P}`, an assignment ahead of the verb such as `VAR=${VAR@P}`, and every word of a command this guard does not list. The operator family is routed to its own card; nothing here closes it.
   >
   > **G2 does not see a value the shell re-evaluates.** This is a declared exclusion, not an oversight. An arithmetic context (`${v:offset}`, `${array[index]}`) or an indirection (`${!ref}`) runs a command substitution carried in *another variable's value* — the suite's `XFORM-RESID-04` arm observes all three on `/bin/bash` — while the operand shows nothing, and no lexical guard can refuse those without refusing ordinary substring, index and indirection forms. Refusing the transformation operator alone would close one spelling of a class whose other spellings stay open, so the limit is stated instead of half-closed — the same limit that admits `cat "$X"`. That wider class of value-re-evaluating brace forms is routed to a card of its own as well. This guard scopes where the file verbs it lists may read and write; it is not a control on what a command may execute.
   >
   > Each refusal this boundary names is mode-coupled like every `-001` to `-003` verdict: it blocks at `.mode=enforce`, warns and admits at `.mode=warn`, and is absent at `.mode=off` and while master activation is off.

   G5 refuses under `-001`/`-002`, not `-003`, and its message names the resolved **prefix** and says so — an operator is never told a path fully resolved when only its prefix did.
3. Tilde expansion: `~` → `$HOME`; `~/<path>` → `$HOME/<path>`.
4. Absolute (`/<path>`) → use as-is; otherwise → join with `payload.cwd`.
5. Normalize via Python `os.path.realpath` (system-default `/usr/bin/python3`). Collapses `..`/`./`, does not require path existence, and follows symlinks. Same `os.path.realpath` posture as `block-rm-prefer-trash.sh` (and `block-destructive.sh`).
6. Walk `.claude/fs-boundary-allowlist.txt` line-by-line; tilde-expand each entry; trim trailing slash; prefix-match the resolved path against each allowed root. First match → allow. No match → block (or warn-log when `.mode = warn`).

**Allowlist format:** one absolute path per line (NOT a bash glob — exact prefix-match after realpath); `#` introduces comments; blank lines ignored; trailing slashes normalized on both entry and target. Tilde-prefixed entries expand to `$HOME`. Subpaths of an allowed root are implicitly allowed.

**Symlink-following posture (intentional):** same as `block-rm-prefer-trash.sh` — `os.path.realpath` follows symlinks. A symlink inside an allowed root pointing to a target outside any allowed root resolves to the outside target and is blocked. This matches the strict-policy requirement: "block any file access whose resolved path is outside the allowed roots."

**Absolute-path-aware verb anchor:** same anchor pattern as the other three regex-based PreToolUse hooks — file-read and file-write verbs invoked via canonical absolute-path prefix (`/bin/cat`, `/usr/bin/cp`, etc.) are detected uniformly with the verb-at-command-start form. See [`§ Absolute-Path-Aware Verb Anchor`](../bypass-mode-readiness.md).

See [`§ Known Limitations`](../bypass-mode-readiness.md) for this hook's shell-redirection, nested-shell + quoted-path, and `~/Library/<unenumerated-subdirs>` settings.deny-coverage-gap residuals.
