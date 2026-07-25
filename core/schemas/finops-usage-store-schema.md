---
title: FinOps Usage Store Schema — Agent Token-Spend Runtime Store
purpose: The canonical data contract for the operator-local Agent-FinOps usage store — the JSONL record kinds, fields, versioning, write-discipline, and summation invariant for per-session and per-subagent token counts extracted from local Claude Code session data. The C2 attribution slice extends this with the roll-up record kind at v1.1.0.
type: schema
status: ACTIVE
schema_version: "1.0.0"
reversibility: MODERATE / HIGH confidence (consumed by the C2 attribution slice + the downstream agent-finops-intelligence milestone; additive extension is backward-compatible, a breaking field change is a major bump + a downstream coordination event)
consumers: "finops-usage-extractor (producer); the C2 attribution/roll-up slice (extends v1.1.0 rollup record); the agent-finops-intelligence milestone — estimation, reporting, calibration (version-pin >= v1.1.0)"
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# FinOps Usage Store Schema

> Frozen **v1.0.0** data contract for Agent token-spend FinOps (slice C1, the data foundation). The C2 attribution slice extends it additively to v1.1.0 (`rollup`). This doc is the schema authority; the `finops-usage-extractor` skill is the producer.

## Purpose + Scope

Defines the operator-local Agent-FinOps usage store: WHERE it lives, its FORMAT, and the FROZEN v1.0.0 record kinds. The store is a **derived cache** — a deterministic projection of local Claude Code session transcripts (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/**/*.jsonl`), which remain the source of truth (the same derived-cache posture as the SQLite index schema). It is NOT an audit log: the extractor may rebuild it from source at any time.

## Store Location

Resolved from the `<OPERATOR_INSTANCE_FINOPS_STORE_PATH>` token per the depersonalization-spec token vocabulary: (a) the `operator.toml [paths].operator_instance_finops_store_path` override if set, else (b) the default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops`. Store file: `<resolved-path>/usage.jsonl`.

The store is **git-ignored** operator-instance data — its records carry `git_branch`, `cwd` (an operator home path), and work-item identifiers, so on a PUBLIC repo it must never commit. This is enforced two ways: the static `.gitignore` patterns (the `personal/` + `pmo-instance/` homes plus defensive finops stems), AND a resolve-time `git check-ignore` guard in the extractor that refuses to write when the resolved store falls inside a git repository but is not ignored there (see the extractor's exit-code contract).

## Format

JSONL — one JSON object per line, discriminated by a top-level `record` field. Line 1 is the `meta` record; subsequent lines are `session` / `subagent` records. Consumers filter by `.record` (jq-native).

## Versioning

`schema_version` travels in the `meta` record (semver). **v1.0.0 (C1, this doc) freezes** the `meta`, `session`, and `subagent` record kinds and their field sets, and reserves `provider` (optional). **C2 adds v1.1.0:** the `rollup` record kind (additive; existing kinds unchanged). An additive change is a minor bump; a breaking change to a frozen kind is a major bump plus a coordination event across the downstream `agent-finops-intelligence` consumers, which pin `schema_version >= 1.1.0`.

## Store write-discipline

The store holds **exactly one `session` record per `session_id`** (and one `subagent` record per `(session_id, subagent_id)`). It is a **keyed projection, NOT an append-only log** — the append-only-log write-discipline of the operator-instance run-logs (`external-sync/run-log.jsonl`, `ambient-intake/run-log.jsonl`, which accrete one line per run event) does NOT transfer here. Re-extraction of a session **replaces** its record(s); **newest-wins**.

- **`--rebuild` (the DEFAULT mode):** truncate + rewrite the entire store from source → one record per `session_id` **by construction** (`session_id` = the source filename stem, which is unique per file). Records are emitted in a **deterministic total order** (sort by `started_utc`, then `session_id`, then record kind — `session` before `subagent` — then `subagent_id`), so the record **body is a pure function of the source**: two rebuilds over unchanged source produce a **byte-identical body** (idempotent by `diff`) **modulo the extraction-time metadata** — the per-record `extracted_utc` and the `meta` line's `created_utc` / `last_extract_utc`, which record when extraction ran and update by design. Only files with ≥1 assistant record (spend-bearing sessions) yield a record; zero-assistant files (project summary/index files, empty transcripts) are skipped. The rewrite is atomic — the extractor writes `usage.jsonl.tmp` and then `mv`s it over `usage.jsonl` (same directory → same filesystem → atomic rename), so an interrupted run never leaves a partial store.
- **`--incremental` (opt-in, mtime-gated optimization):** for each source session whose transcript mtime is newer than `meta.last_extract_utc`, **upsert by `session_id`** — drop any existing `session` / `subagent` lines for that `session_id`, then append the freshly-extracted lines; rewrite `meta.last_extract_utc`. One record per `session_id` **by invariant**. The incremental rewrite uses the same tmp-then-`mv` atomic path.

Both modes yield the same terminal invariant: no duplicate `session_id`, and the per-session token totals reflect the current source.

## Record: `meta` (line 1)

| Field | Type | Notes |
|---|---|---|
| `record` | `"meta"` | discriminator |
| `schema` | string | `"finops-usage-store"` |
| `schema_version` | semver | `"1.0.0"` |
| `generated_by` | string | `"finops-usage-extractor"` |
| `generator_version` | string | the skill's `version` frontmatter value |
| `source_root` | string | resolved session-data root (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects`) |
| `created_utc` / `last_extract_utc` | ISO 8601 UTC | rewritten each rebuild |
| `token_model` | string | `"exact-source; fallback ceil(words/0.75) per context-budget-auditor"` |

## Record: `session`

One per `<session-uuid>.jsonl`. **`tokens` is the whole-file total (inclusive of any in-transcript sidechain subagents).**

| Field | Type | Notes |
|---|---|---|
| `record` | `"session"` | discriminator |
| `session_id` | string | session UUID (filename stem / `.sessionId`) |
| `project_dir` | string | `~/.claude/projects/<dir>` basename |
| `cwd` | string\|null | working dir (operator-local; git-ignored) |
| `git_branch` | string\|null | work-item attribution surface (C2 consumes); null on legacy sessions → C2 `unattributed` |
| `started_utc` / `ended_utc` | ISO 8601 UTC | first / last record timestamp |
| `model` | string | dominant / last model id |
| `service_tier` | string\|null | dominant / last service tier (e.g. `standard`) — cost-determining, parallel to `model` |
| `turns` | int | assistant-record count |
| `tokens` | object | `{input, output, cache_creation:{total, ephemeral_1h, ephemeral_5m}, cache_read}` (ints) — see below |
| `tool_use` | object | `{web_search_requests, web_fetch_requests}` (ints — the "tool" dimension) |
| `subagent_count` | int | # of `subagent` records for this session (drill-down; already inside `tokens`) |
| `token_source` | enum | `exact` \| `heuristic` \| `mixed` |
| `heuristic_turns` | int | turns estimated via the fallback |
| `extracted_utc` | ISO 8601 UTC | extraction time |

**`tokens` shape** (the cost-determining structure):

```jsonc
"tokens": {
  "input":  <int>,
  "output": <int>,
  "cache_creation": {
    "total":        <int>,   // source cache_creation_input_tokens (rolled cache-write, the cost-faithful figure)
    "ephemeral_1h": <int>,   // source cache_creation.ephemeral_1h_input_tokens (priced higher; 0 when the nested block is absent)
    "ephemeral_5m": <int>    // source cache_creation.ephemeral_5m_input_tokens (0 when the nested block is absent)
  },
  "cache_read": <int>
}
```

- `cache_creation.total` = the source rolled `cache_creation_input_tokens` (authoritative; never null when the flat source field is present).
- `ephemeral_1h` / `ephemeral_5m` = the nested breakdown, **defaulting to `0` when the nested `cache_creation` object is absent** (legacy records pre-dating 1h caching), so `total` stays cost-faithful and the tiers are a best-effort refinement.
- Invariant (asserted in the extractor `--self-test`): when the tiers are present, `ephemeral_1h + ephemeral_5m == total`.
- `service_tier` is captured at session grain as dominant / last — the same grain already accepted for `model`. A session that mixes tiers/models across turns cannot be exactly cost-split from this rollup; per-turn cost precision, if ever required, is a downstream estimation concern reading source, not a C1 re-grain.

## Record: `subagent`

One per in-transcript sidechain (`isSidechain==true` group). A drill-down of the session's sidechain spend — **NOT summed on top of `session.tokens`.**

| Field | Type | Notes |
|---|---|---|
| `record` | `"subagent"` | discriminator |
| `session_id` | string | parent session UUID |
| `subagent_id` | string | sidechain root uuid (or spawning Task tool_use id) |
| `parent_uuid` | string | links to the spawning assistant turn |
| `git_branch` | string\|null | inherited from session |
| `service_tier` | string\|null | dominant / last tier for the subagent (parallel to `model`) |
| `started_utc` / `ended_utc` / `model` / `turns` / `tokens` / `tool_use` / `token_source` / `heuristic_turns` / `extracted_utc` | — | same shapes as `session` (`tokens` uses the same nested `cache_creation` structure) |

> **Cross-session subagent note (C1/C2 boundary).** This platform's hub-spoke model spawns spokes as **separate session files**, so `subagent` (in-transcript sidechain) records are rare in practice; cross-file spokes are `session` records that **C2 attributes** as subagents-of-a-parent via `git_branch` + timestamps. C1 does not do cross-file attribution — that is C2's roll-up scope. C1's `subagent` record kind covers only the in-transcript sidechain case, so a Stage-7 check must not false-flag "missing per-subagent counts" when a session simply has no sidechains.

## Summation invariant (load-bearing — C2 roll-up contract)

A work-item total = **Σ `session.tokens` over its sessions** ONLY, where a single session's cost-relevant token total is the four leaf integers `input + output + cache_creation.total + cache_read` (`cache_creation.total` is the rolled cache-write; the `ephemeral_1h` / `ephemeral_5m` split and `service_tier` are cost-determining refinements consumed downstream, not additional summands). `subagent` records are an attribution drill-down and are ALREADY included in their `session.tokens`; they are **NEVER** added on top. C2's `rollup` MUST honor this (graded by CIAC-1).

## Reserved: `provider` (optional)

Emitted ONLY when the OFF-by-default `provider-usage-connector.sh` runs. Declared (reserved) here so formalizing it later is not a breaking bump. Never required; extraction completes from local data alone without it.

## Version History

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-07-25 | Initial freeze — `meta` / `session` / `subagent` record kinds; `provider` reserved; cache-write tier split (`cache_creation.{total, ephemeral_1h, ephemeral_5m}`) + `service_tier`; keyed-projection write-discipline; summation invariant. |
