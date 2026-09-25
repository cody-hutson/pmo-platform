<!-- reference-durability: allow-link -->
## `block-egress.sh` (BLOCK-EGRESS-001..013)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-egress.sh` |
| Matcher | Bash, WebFetch |
| Scope | Credential reads via Bash, network upload (curl/wget/gh gist), network tools (nc/scp/ssh), WebFetch domain allowlist |
| Mode | Warn-mode initial (shared `.claude/hooks/.mode`); flip-to-enforce per the [`§ Shakedown → Enforce Transition Checklist`](../bypass-mode-readiness.md) |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-EGRESS-001 | Subprocess read of credential dirs (`~/.ssh`, `~/.aws`, `~/.config/gh`) |
| BLOCK-EGRESS-002 | Subprocess read of `.env` variants / SSH private keys / `*.pem` / `*.key` (`.env.example` allowed) |
| BLOCK-EGRESS-003 | `base64` encoding of credential dirs |
| BLOCK-EGRESS-004 | `curl -X POST` / `-d` / `-F` / `-T` to non-allowlisted host |
| BLOCK-EGRESS-005 | `wget --post-data` / `--post-file` |
| BLOCK-EGRESS-006 | `gh gist create` (unconditional) |
| BLOCK-EGRESS-007 | `gh api` write to a non-allowlisted, or unresolvable, API path |
| BLOCK-EGRESS-008 | `nc` / `ncat` |
| BLOCK-EGRESS-009 | `scp` to remote target |
| BLOCK-EGRESS-010 | `rsync` to remote target |
| BLOCK-EGRESS-011 | `ssh` to non-allowlisted host |
| BLOCK-EGRESS-012 | WebFetch to `file://` / `localhost` / `127.0.0.1` |
| BLOCK-EGRESS-013 | WebFetch to non-allowlisted domain |

See [`§ Absolute-Path-Aware Verb Anchor`](../bypass-mode-readiness.md) — the Bash-branch egress verbs compose with the canonical anchor; the WebFetch-branch rules (BLOCK-EGRESS-012 / -013) are tool-name-matched, not verb-anchored. **BLOCK-EGRESS-007 is the one exception and does not read the anchor at all** — see below.

### What BLOCK-EGRESS-007 adjudicates

`-007` resolves command position at token level over quote-neutralized segments rather than matching a regex anchor. What that changes, stated as behaviour rather than mechanism:

| Property | Behaviour |
|---|---|
| **Spelling invariance** | Bare, single-quoted and double-quoted spellings of one path produce one verdict. The allowlist is matched against the resolved, unquoted path; a quoted pattern in the allowlist can never match. |
| **Allowlist scope** | The path is matched only against rows declared `gh-api-path` and rows with no scope directive — never against a row declared `host`, and never against a pattern whose first path segment carries a glob character — so a host wildcard such as `*.github.com` cannot grant a write to a path that merely ends in host-shaped text. BLOCK-EGRESS-004 is scoped the same way to `host` rows and rows with no directive. The grammar is stated in the egress allowlist's own header. |
| **Path location** | The path is found by walking flags, so `gh api -X POST <path>` and `gh api <path> -X POST` are equivalent, and a value-taking flag's value is never mistaken for the path. |
| **Command position** | A write is adjudicated wherever it sits — a loop body, an `if` branch, a subshell, a command substitution, a backtick, behind `xargs` or a wrapper, or behind a `VAR=x` assignment prefix. The verb is matched on its basename, so every absolute-path form is covered and an unlisted prefix does not evade. |
| **Every invocation** | Each `gh api` in a command is adjudicated, with its own method determination. A second write cannot hide behind an allowlisted first one, and a read co-located with a write is not judged against the write allowlist. |
| **Write detection** | An explicit `-X` / `--method` write verb, **or** an implicit POST — `gh` defaults the method to POST when `-f` / `-F` / `--field` / `--raw-field` / `--input` is present, so a field flag alone is a write. |
| **Comments** | A `#` that opens a word in unquoted text starts a comment, and the scanner treats the remainder of that LINE as quote-inert — an apostrophe in `# don't re-run` cannot desynchronize the scan, so an ordinary command carrying one is not this rule's business. Comment text is **not stripped**: a write reached through a separator inside a comment stays adjudicated exactly as the replaced matcher adjudicated it. |
| **Cannot-evaluate** | Four named causes, each with its own remediation: `not-allowlisted`, `unresolvable` (a placeholder or shell expansion in the path authority), `unparseable` (the scanner finds an unterminated quote in **command** text; a comment it recognizes cannot produce one, and a well-formed command it mis-models can — see below), `no-path`. None exits silently. |

**The `unresolvable` cause is not an allowlist problem, and its message says so.** `gh` resolves `{owner}` / `{repo}` at execution time from the environment, a default-repo setting, or the current remote — none of which a PreToolUse hook can see. No allowlist row can ever match such a path, so the remediation is to spell the owner and repository out in the command. Expanding them from the remote was rejected: the hook could resolve to a different repository than the command reaches, producing an allow for a repository it never adjudicated.

**Rollout is split by fail-direction, and is NOT the shared `.mode` dial.** Repairs — quote handling, the flag walk, `--` — enforce from day one, because they can only stop a wrong denial. Widenings — command position, every-invocation, implicit POST — ship in the `shadow` phase defined by the progressive-rollout convention (`core/standards/progressive-rollout-convention.md`): they evaluate, record a `would-fire` entry in `egress-warn-log.jsonl` carrying the cause class and path, and take no action. A deny is classified as a widening exactly when the replaced matcher could not have produced it, **so no rung can allow a case the replaced matcher denied.**

Read that claim precisely, because it is narrower than it first appears. The *repairs* deliberately turn some old denials into passes — a quoted allowlisted path passing is the whole point of the change. What the **ladder** must never do is withhold a deny the old code already produced, and it is the ladder the sentence governs. `unparseable` sits on the enforcing side for exactly that reason: it denies at every rung, and it is raised only for a real `gh api` invocation at a command position the replaced matcher could have reached, so it softens no deny the old code produced. **It is not, however, free of new denies.** The deny costs nothing for a genuinely malformed command, which cannot run either. But the scanner reads some well-formed syntax as an unterminated quote — a heredoc body, an escaped, ANSI-C or nested quote, a comment it does not recognize — and there the class denies what the replaced matcher never did: a read (that matcher required an explicit write method), an implicit-POST write, or a write it had allowlisted. A wrapper, a `$( )` and a glued verb are outside that position set on purpose — the old matcher never adjudicated them, so allowing them loses no deny it produced. A genuinely malformed command there cannot execute anyway; a well-formed one the scanner mis-models executes unadjudicated and leaves no record.

The phase is one constant in the hook; advancing or retreating it is a single edit. Flipping the shared `.mode` is **not** the instrument for this rule — that file is a cohort dial and would soften every mode-capable hook in the bundle at once.

**Reading the shadow log.** A rising `not-allowlisted` count means real writes are reaching unadjudicated paths and an allowlist row may be warranted. A rising `unresolvable` count means the opposite — agents are writing variable-bearing authority paths, and the fix is to spell them out. Conflating the two is the failure this rule was filed about.

**Reading `unparseable` records.** Their `evidence` is the constant `path=unknown cause=unparseable`, so the warn-log and block-log records of this one class also carry a `features` object and a top-level `hook_build`, and they are classified by `features.shell_parse`, scoped by `features.oracle` — the parser that judged the syntax: `error` → rejected by the recorded oracle, `ok` → benign-shape (a false refusal of a well-formed command), `skipped` or `unavailable` → unclassified. An `error` record is a true positive only where the oracle's grammar is the executing shell's: the oracle is bash, the shell that runs a command may differ, and zsh accepts some commands bash rejects, so an `error` record can still be a false refusal — the residual the record names its oracle for. `features.heredoc` splits the false refusals by heredoc delimiter quoting, and reads `unavailable` when its scan could not run. Both computations are linear in the command's length and share one size cap, so neither can hold the deny past the hook's timeout. `hook_build` names the hook build that wrote the record: a record carrying `hook_build` whose features all read `unavailable` (the oracle `unknown`) is a current-build record whose features could not be computed, and one carrying `hook_build` without `features` is a current-build record whose features could not be written — neither is ever one from before the field set existed. No field carries the command's text, an offset or a length. The decision and its rejected alternatives are recorded in ADR-205.

### Allowlist row scope — who writes a row, and which rule reads it
<!-- design-artifact: flow-class=data-flow; name=egress-allowlist-row-scope; depicts=core/config/allowlists/egress-allowlist.txt,core/hooks/block-egress.sh,core/hooks/allowlist-add.sh -->

`egress-allowlist.txt` serves two match domains. A declared row is consulted only in the domain its scope directive names — `# egress-scope: host` or `# egress-scope: gh-api-path`, on the line directly above it — and a row with no directive is consulted in both, which is the behaviour every row had before directives existed.

| Producer | What it writes | Region of the deployed file | Scope the row carries |
|---|---|---|---|
| The package source, through the composition writer | every managed row, each under its own directive | MANAGED SECTION — regenerated on every update | declared |
| `allowlist-add.sh <file> '<entry>' --scope <domain>` | the directive and the entry, adjacent, before the END marker — or, when the entry is already there as a bare row, the directive directly above that row (upgrade in place) | OPERATOR ADDITIONS — preserved verbatim | declared |
| `allowlist-add.sh <file> '<entry>'` with no `--scope` | the entry alone, before the END marker, plus a notice saying how it will be matched | OPERATOR ADDITIONS | none — both domains |
| An operator editing inside the fence | rows, with or without a directive above each | OPERATOR ADDITIONS | as written |

| Consumer | Domain it asks for | Rows it consults |
|---|---|---|
| BLOCK-EGRESS-004 — the host of a curl upload | `host` | rows declared `host`, and rows with no directive |
| BLOCK-EGRESS-007 — the path of a `gh api` write | `gh-api-path` | rows declared `gh-api-path`, and rows with no directive — minus every pattern whose first path segment carries `*`, `?` or `[` |
| BLOCK-EGRESS-011 / -013 — their own single-domain files | none | every row; a directive line there is an ordinary comment |
| `allowlist-add.sh`'s duplicate check | — | the exact entry line; with `--scope`, the exact directive-plus-entry pair, and any bare copy of the entry inside the region, which it declares in place |

**Why the leading-glob exclusion holds whatever a row declares.** A host wildcard can match a path only by absorbing the whole front of it, and a query string lets any write end in host-shaped text, so a pattern that begins with a glob is exactly the shape that must never grant a `gh api` write. The exclusion keeps that true for rows with no directive, for mis-declared rows, and for an allowlist the update path has not yet regenerated. **It works in one direction only.** It keeps a glob off gh-api paths and does nothing at the host check, so a row with no directive and no `/` stays a curl host candidate — a glob such as `gist*` grants an upload to every host it matches, and a slashless literal matches its one exact string in both domains. A directive is what confines such a row. **Why a directive binds one row only.** A scope that ran on to later rows would silently re-scope a row added below it; binding the next line alone means a row's domain is always the line directly above it. **Revert safety.** A directive is a comment line, so the matcher that predates directives reads the same file exactly as it read the file before, and a revert restores the prior grant set without touching the preserved operator region. The decision and its rejected alternatives are recorded in ADR-206.
