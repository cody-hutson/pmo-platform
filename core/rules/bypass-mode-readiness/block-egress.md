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
| **Path location** | The path is found by walking flags, so `gh api -X POST <path>` and `gh api <path> -X POST` are equivalent, and a value-taking flag's value is never mistaken for the path. |
| **Command position** | A write is adjudicated wherever it sits — a loop body, an `if` branch, a subshell, a command substitution, a backtick, behind `xargs` or a wrapper, or behind a `VAR=x` assignment prefix. The verb is matched on its basename, so every absolute-path form is covered and an unlisted prefix does not evade. |
| **Every invocation** | Each `gh api` in a command is adjudicated, with its own method determination. A second write cannot hide behind an allowlisted first one, and a read co-located with a write is not judged against the write allowlist. |
| **Write detection** | An explicit `-X` / `--method` write verb, **or** an implicit POST — `gh` defaults the method to POST when `-f` / `-F` / `--field` / `--raw-field` / `--input` is present, so a field flag alone is a write. |
| **Comments** | A `#` that opens a word in unquoted text starts a comment, and the scanner treats the remainder of that LINE as quote-inert — an apostrophe in `# don't re-run` cannot desynchronize the scan, so an ordinary command carrying one is not this rule's business. Comment text is **not stripped**: a write reached through a separator inside a comment stays adjudicated exactly as the replaced matcher adjudicated it. |
| **Cannot-evaluate** | Four named causes, each with its own remediation: `not-allowlisted`, `unresolvable` (a placeholder or shell expansion in the path authority), `unparseable` (an unterminated quote in **command** text — a comment cannot produce one), `no-path`. None exits silently. |

**The `unresolvable` cause is not an allowlist problem, and its message says so.** `gh` resolves `{owner}` / `{repo}` at execution time from the environment, a default-repo setting, or the current remote — none of which a PreToolUse hook can see. No allowlist row can ever match such a path, so the remediation is to spell the owner and repository out in the command. Expanding them from the remote was rejected: the hook could resolve to a different repository than the command reaches, producing an allow for a repository it never adjudicated.

**Rollout is split by fail-direction, and is NOT the shared `.mode` dial.** Repairs — quote handling, the flag walk, `--` — enforce from day one, because they can only stop a wrong denial. Widenings — command position, every-invocation, implicit POST — ship in the `shadow` phase defined by the progressive-rollout convention (`core/standards/progressive-rollout-convention.md`): they evaluate, record a `would-fire` entry in `egress-warn-log.jsonl` carrying the cause class and path, and take no action. A deny is classified as a widening exactly when the replaced matcher could not have produced it, **so no rung can allow a case the replaced matcher denied.**

Read that claim precisely, because it is narrower than it first appears. The *repairs* deliberately turn some old denials into passes — a quoted allowlisted path passing is the whole point of the change. What the **ladder** must never do is withhold a deny the old code already produced, and it is the ladder the sentence governs. `unparseable` sits on the enforcing side for exactly that reason: it denies at every rung, and it is raised only for a real `gh api` invocation at a command position the replaced matcher could have reached, so the class produces no deny the old code did not already produce and softens none that it did. A wrapper, a `$( )` and a glued verb are outside that position set on purpose — the old matcher never adjudicated them, and a command that cannot be parsed cannot execute, so nothing is lost by allowing them.

The phase is one constant in the hook; advancing or retreating it is a single edit. Flipping the shared `.mode` is **not** the instrument for this rule — that file is a cohort dial and would soften every mode-capable hook in the bundle at once.

**Reading the shadow log.** A rising `not-allowlisted` count means real writes are reaching unadjudicated paths and an allowlist row may be warranted. A rising `unresolvable` count means the opposite — agents are writing variable-bearing authority paths, and the fix is to spell them out. Conflating the two is the failure this rule was filed about.
