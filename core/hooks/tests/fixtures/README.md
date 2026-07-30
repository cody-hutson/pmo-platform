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
