# Hook test fixtures

## `stop-payload.json` — the pinned `Stop` hook payload

This file is the **payload contract pin** for `core/hooks/session-retro-trigger.sh`.
It contains **only keys the harness actually sends** on a `Stop` event. It exists so
that a hook test can never again be written from the code's own premise — the defect
that let the sampling predicate read two fields (`tool_call_count`, `turn_count`) that
the payload has never carried.

**Provenance.** Pinned against the live Claude Code harness contract by reading the
shipped CLI bundle's hook-input schema and the `Stop` payload construction site
directly, not from documentation or inference. The payload is assembled as
`{...base_envelope, hook_event_name: "Stop", stop_hook_active, last_assistant_message}`,
where the base envelope carries `session_id`, `transcript_path`, `cwd`, and the
optional `permission_mode` / `agent_id` / `agent_type`.

| Key | Type | Presence |
|---|---|---|
| `session_id` | string | always |
| `transcript_path` | string | always — absolute path to the session JSONL |
| `cwd` | string | always |
| `permission_mode` | string | optional |
| `hook_event_name` | string | always — literal `"Stop"` |
| `stop_hook_active` | bool | always — true when the agent is continuing *because* a `Stop` hook blocked |
| `last_assistant_message` | string | optional — text of the final assistant message |
| `agent_id` / `agent_type` | string | subagent invocations only; absent on the main thread |

**Deliberately absent:** `tool_call_count` and `turn_count`. The hook's `--self-test`
asserts their absence as a **negative control** — a future editor who re-introduces
counter-reading fails that assertion rather than shipping a predicate that can never
fire. Do not add keys here to make a test pass; the fixture's whole value is that it
mirrors the harness rather than the code.

`SubagentStop` is a **separate** event with its own `agent_id` / `agent_transcript_path`
keys. This hook registers on `Stop` only.

## `walk-payload-corpus.txt` — the tracked payload differential

The exit bar several changes to the guards' token walks share is a **differential**: no
payload's verdict may move from refused to allowed except as a declared precision
improvement, with the detector shown able to fire first. Run as per-change scratch, that
bar could not be re-run by the next stage or the next change. This file is the one
committed corpus every such change and every reviewer adds rows to, and the hook suites
read it through their own harness, so the runner and the CI hook-test job exercise it on
every run with no separate tool.

**Row format.** One payload per line, seven fields separated by `|`; the command is the
last field and may itself contain `|`. Lines starting with `#` and blank lines are ignored.

| Field | Meaning |
|---|---|
| `id` | Unique across the file. A new row takes an id no other row carries. |
| `hook` | The guard the row is run against, by basename without `.sh` (`block-destructive`). A suite runs only the rows that name its guard. |
| `group` | A name the reader reports by: one arm per group. A group starting with `open-` records an execution the guard allows today, declared open. |
| `twin` | The id of the same invocation with its quoting removed, or `-`. |
| `gt` | Ground truth taken when the row was authored, by running the command under the real interpreters with marker scripts: `X` the unlisted script ran, `o` only the allowlisted one ran, `w` the extensionless wrapper ran, `e` another extensionless file in the fixture directory ran in the script's place (one named `extglob` or `-n`), `s` a program fed on standard input ran and no script named on the command line did, `-` nothing ran, `?` not run. The suite does not re-run ground truth. |
| `verdict` | The guard's recorded verdict: `a` allowed, `B` refused (exit 2), `W` warned at a rollout phase (exit 0 and a would-fire record). |
| `command` | The Bash command, with the placeholders below. |

**Placeholders.** `@D@` is the fixture directory; the reader allowlists exactly
`@D@/ok.sh` and `@D@/ok.py` in a hermetic root of its own. `@LONGX@` and `@LONGN@` are
4,100 repetitions of `x` and `n`, `@SHORTX@` 4,000 of `x`, `@MIDX@` and `@MIDN@` 1,000 of
`x` and `n`, `@QPAD@` 2,050 pairs of empty double quotes. Anything else — `$NOPE7019`,
`$VAR`, `$HOME` — is plain text to the guard, because a PreToolUse hook sees argv
unexpanded. A command that needs a newline cannot be written in this format.

**What the block-destructive reader asserts** (arms `WALKCORPUS-*`). The corpus resolves
and its identity is printed; the hermetic hook is live; every row parses; each group's
rows return their recorded verdicts; a quoted row is never weaker than its unquoted twin,
on the verdicts observed in that run, outside the `open-` groups (a quoted spelling may
be stricter than its twin, never looser); every `open-` row is still a recorded allow;
and the suite's own operand-walk mutant (the `AC-D022` reversion) moves at least one recorded
refusal to an allow, while still refusing others — the detector shown able to fire, and
shown alive.

**The corpus identity is recomputed from the file itself.** It is the SHA-256 of this
file at a named commit:
`git show <commit>:core/hooks/tests/fixtures/walk-payload-corpus.txt | shasum -a 256`.
The reader prints the same digest, with the row counts, on its first arm and again in a
`RESIDUAL:` line, which the runner forwards from a green run as well as a red one, so
every run's output carries the identity of the corpus it graded and a reader can
recompute it from the committed file. No digest is stored inside the file, which is what let an earlier,
comment-carried corpus drift from its own recorded digest.

**Adding rows.** Append rows with fresh ids, in a block headed by a `#` line that names
where they came from. Record the verdict the guard returns on the commit that adds them;
a change that moves a verdict updates that row's `verdict` in the same commit, so the
diff of this file is the record of every verdict a change moved — and a move from `B` or
`W` to `a` must be a declared precision improvement, verified against the real
interpreter, named in that change's evidence. A row for a guard whose suite has no reader
yet adds the reader to that suite in the same change.
