---
title: FinOps Usage Store Schema — Agent Token-Spend Runtime Store
purpose: The canonical data contract for the operator-local Agent-FinOps usage store — the JSONL record kinds, fields, versioning, write-discipline, and summation invariant for per-session and per-subagent token counts extracted from local Claude Code session data. v1.1.0 (the C2 attribution slice) adds the roll-up and coverage record kinds; the session→work-item mapping algorithm lives in the FinOps attribution-convention standard. v1.2.0 replaces `session.cwd` (a full absolute working-directory path) with `session.worktree` (its basename only) as a data-minimization control, under the conditioned frozen-kind exemption recorded in § Versioning, and adds five additive per-session analysis sub-aggregates (`by_skill` / `by_mcp` / `by_model` / `tool_calls` / `stop_reason`) plus `dimension_coverage`, the best-effort population label the intelligence layer slices on. v2.0.0 counts every token and turn figure once per API response within one transcript file (transcript lines grouped by `message.id`, usage max-merged), not once per transcript line — a breaking change to the meaning of frozen fields, taken as a major bump. The same version flags, on each session and subagent record, the API responses whose final usage never reached the transcript (`incomplete_responses`, beside `unevaluated_responses` for those the flag cannot evaluate).
type: schema
status: ACTIVE
schema_version: "2.0.0"
reversibility: MODERATE / HIGH confidence (consumed by the C2 attribution slice + the downstream agent-finops-intelligence milestone; additive extension is backward-compatible, a breaking field change is a major bump + a downstream coordination event **unless the § Versioning frozen-kind exemption's three conditions all hold**)
consumers: "finops-usage-extractor (producer); the C2 attribution/roll-up slice (extends v1.1.0 rollup record); the agent-finops-intelligence milestone — estimation, reporting, calibration (version-pin >= v2.0.0 wherever token figures are compared across stores; v2.0.0 adds two always-present counts to the session and subagent records and changes no other record shape since v1.2.0)"
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# FinOps Usage Store Schema

> **v2.0.0** data contract for Agent token-spend FinOps. The frozen **v1.0.0** core (slice C1, the data foundation) defines the `meta` / `session` / `subagent` record kinds; **v1.1.0** (the C2 attribution slice) adds the `rollup` and `coverage` record kinds additively (the frozen v1.0.0 kinds are unchanged); **v1.2.0** replaces `session.cwd` with `session.worktree` (its basename only — a data-minimization control) under the conditioned frozen-kind exemption in § Versioning, **adds five additive per-session analysis sub-aggregates** (`by_skill` / `by_mcp` / `by_model` / `tool_calls` / `stop_reason`, each token-bearing map carrying an always-present reserved `"unknown"` bucket) plus `session.dimension_coverage`, and stops encoding which phase has run in the version number; **v2.0.0** corrects the counting unit of every token and turn figure (§ Counting unit) and adds two always-present counts to the `session` and `subagent` records, `incomplete_responses` and `unevaluated_responses`, which flag the responses whose final usage never reached the transcript (§ Incomplete responses); no record kind changes. This doc is the schema authority; the `finops-usage-extractor` skill is the producer.

## Purpose + Scope

Defines the operator-local Agent-FinOps usage store: WHERE it lives, its FORMAT, and the FROZEN v1.0.0 record kinds. The store is a **derived cache** — a deterministic projection of local Claude Code session transcripts (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/**/*.jsonl`), which remain the source of truth (the same derived-cache posture as the SQLite index schema). It is NOT an audit log: the extractor may rebuild it from source at any time.

## Store Location

Resolved from the `<OPERATOR_INSTANCE_FINOPS_STORE_PATH>` token per the depersonalization-spec token vocabulary: (a) the `operator.toml [paths].operator_instance_finops_store_path` override if set, else (b) the default `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/finops`. Store file: `<resolved-path>/usage.jsonl`.

The store is **git-ignored** operator-instance data — its records carry `git_branch`, `worktree` (a directory basename, not a home path — v1.2.0 data-minimization), and work-item identifiers, so on a PUBLIC repo it must never commit. This is enforced two ways: the static `.gitignore` patterns (the `personal/` + `pmo-instance/` homes plus defensive finops stems), AND a resolve-time `git check-ignore` guard in the extractor that refuses to write when the resolved store falls inside a git repository but is not ignored there (see the extractor's exit-code contract).

## Format

JSONL — one JSON object per line, discriminated by a top-level `record` field. Line 1 is the `meta` record; subsequent lines are `session` / `subagent` records. Consumers filter by `.record` (jq-native).

## Counting unit (v2.0.0)

- **An API response** is the set of a transcript file's `assistant` records that share one `message.id`. The transcript writes each content block (thinking, text, tool use) as its own record and repeats the response's whole `message.usage` on each, and a spawned-agent transcript's first record can carry a partial streaming `output_tokens` whose final value arrives on a later record.
- **Every token figure is summed once per response**, each usage field — the `tool_use` request counts included — taken at its maximum across the response's records, so the result does not depend on record order. A record with no `message.id` is its own response.
- **Per-response fields:** `turns` (the response count), `heuristic_turns` (usage-less responses), `incomplete_responses` / `unevaluated_responses` (responses with no stop reason; § Incomplete responses), `token_source`, the `by_*` keys, `stop_reason` (the last non-null reason across the response's records; `"unknown"` when none carries one) and `tool_calls` (one call per `tool_use` `id`). `model`, `service_tier` and the timestamps stay record-derived.
- **Only the top-level `message.usage` fields are read.** Usage that appears only inside other-type `message.usage.iterations` entries (an advisor or fallback sub-call) is not counted.
- **The unit is scoped to one transcript file.** A response that a resumed or forked session copies into a second transcript file is counted once in each file, which raises the figures. Measured on 2026-11-05 over the full local transcript population (8,352 files), the copies carry 2.52 % of per-response mass overall: 7.39 % of main-session mass and 0.28 % of subagent mass. Removing that residual needs a cross-file `message.id` index, which the store does not carry; a separate follow-up correction owns it, and this version does not.
- **Data flow (Tier-A):**

  | Producer | Fields | Consumers |
  |---|---|---|
  | `extract-usage.sh` | `session` / `subagent` `tokens`, `turns`, `heuristic_turns`, `incomplete_responses`, `unevaluated_responses`, `tool_use`, `by_*`, `stop_reason`, `tool_calls`; `meta.schema_version` | `rollup-attribution.sh` (sums `session.tokens`; preserves the version; does not read the two counts, so a roll-up over a session with incomplete responses inherits its lower bound) · `report-usage.sh` (windowed sums; prints the version; does not read the counts, so it renders such figures without a lower-bound label) · `estimate-usage.sh` (rollup comparables; prints the version; does not read the counts, so a comparable built on such sessions can be understated) |

- **Stores built before v2.0.0 counted per transcript line and are inflated.** Against the per-response sum, over 5,610 session files measured on 2026-09-26:

  | Token type | Factor |
  |---|---|
  | cache-read | ×2.33 |
  | cache-write | ×2.74 |
  | output | ×1.78 |
  | uncached input | ×3.35 |

  These are corpus averages that vary by session class and over time (a later sample: output ×2.94 in main sessions, ×1.28 in subagent sessions). They are not a per-store divisor: only a rebuild from source is exact. A store built before v2.0.0 is identifiable by its `meta.schema_version` (1.x).

## Versioning

`schema_version` travels in the `meta` record (semver). **v1.0.0 (C1, this doc) freezes** the `meta`, `session`, and `subagent` record kinds and their field sets, and reserves `provider` (optional). **v1.1.0 (the C2 attribution slice) adds** the `rollup` and `coverage` record kinds plus two optional `session` fields (`branch_switch` / `git_branches`) — all additive; the frozen v1.0.0 kinds are unchanged. An additive change is a minor bump; a breaking change to a frozen kind is a major bump plus a coordination event across the downstream `agent-finops-intelligence` consumers, which pin `schema_version >= 2.0.0`.

**Frozen-kind exemption (conditioned, per-change, never standing).** A **breaking** change to a frozen kind normally takes a **major** bump plus a coordination event across pinned consumers. It may instead take a **minor** bump when **all three** conditions hold at the time of the change:

1. **Derived-cache condition** — the store is a derived cache, deterministically rebuildable from source by `extract-usage.sh --rebuild`, so the change is a **rebuild, not a data migration**, and no operator data can be lost by it.
2. **No-external-consumer condition** — **no consumer outside this repository's tracked corpus reads the changed field.** The store is operator-local and unpublished, so there is no third-party reader to coordinate with. *If any external or unknown consumer reads the field, this condition fails.*
3. **Same-PR condition** — **every in-repo consumer of the changed field is updated in the same pull request**, so the coordination event the major-bump rule exists to force is internal to that PR and has already occurred by the time the version ships.

**If any condition fails — in particular if a live consumer reads the changed field outside the same PR — the change takes the major bump and the coordination event, unchanged.** The exemption is **claimed per change**: the Version-History row for that version must name it, and the rationale must be recorded in an ADR. A later frozen-kind change re-tests all three conditions from scratch; nothing here makes minor bumps the default for frozen-kind changes.

**Applied once, at v1.2.0** (`session.cwd` → `session.worktree`; ADR-101): (i) held — the store is a derived cache and the change ships with `--rebuild` as the default mode; (ii) held — the store is git-ignored operator-local data with no published consumer; (iii) held — the sole in-repo reader, `rollup-attribution.sh`, is updated in the same PR, together with the attribution convention's T1/T3 rule text and every affected fixture. A **store-shape preflight** (exit 3) additionally makes a stale on-disk store fail loudly rather than silently, so condition (i)'s "rebuild, not migration" is enforced at runtime rather than assumed.

**v2.0.0 — counting unit (major).** No record kind is added or renamed and no existing field changes shape, but what `tokens`, `turns`, `heuristic_turns`, `tool_use` and the v1.2.0 maps count is corrected — once per API response within one transcript file, not once per transcript line (§ Counting unit) — so 1.x and 2.x figures are not comparable. The frozen-kind exemption was re-tested from scratch and **not claimed**. Condition (i) fails where sources have aged out: a rebuild cannot restore a session whose transcript is gone, so the extractor preserves the prior store instead (§ Store write-discipline). And the exemption's premise does not hold when only values change, because an unprepared consumer reading a field whose meaning silently changed is exactly what the major-bump rule protects. **The counting unit is the major component of the version:** an additive (minor) change keeps the unit, so the extractor's counting-unit boundary keys on the major alone, never on the full version string. The same version adds `incomplete_responses` and `unevaluated_responses` to the `session` and `subagent` records (§ Incomplete responses); that part is additive, so it rides this bump rather than taking a second one.

**Phase progression — what the version number does and does not tell you.** Through v1.1.0 the version encoded *which phase had run*: extraction alone wrote `"1.0.0"`, and a roll-up pass bumped it to `"1.1.0"`, so a consumer pinning `>= 1.1.0` was implicitly guaranteed the store held `rollup` records. **v1.2.0 retires that guarantee**, because v1.2.0 changed the *extraction* phase's own record shape — an extraction-only store is no longer v1.0.0-conformant, so it must report `1.2.0` too, and there is no semver that says "v1.2.0 session shape, no rollup kinds". Both phases therefore emit `meta.schema_version = "1.2.0"`. **From v1.2.0 the version no longer encodes which phase has run.** The canonical "a roll-up has run" predicate is the presence of the mandatory run-level record — `any(.record == "coverage")` (exactly one per roll-up run, always emitted). **Consumers MUST gate on that predicate, never on `schema_version` alone.** From v2.0.0 extraction writes the version and the roll-up preserves it, so the version also identifies the counting unit.

## Store write-discipline

The store holds **exactly one `session` record per `session_id`** (and one `subagent` record per `(session_id, subagent_id)`). It is a **keyed projection, NOT an append-only log** — the append-only-log write-discipline of the operator-instance run-logs (`external-sync/run-log.jsonl`, `ambient-intake/run-log.jsonl`, which accrete one line per run event) does NOT transfer here. Re-extraction of a session **replaces** its record(s); **newest-wins**.

- **`--rebuild` (the DEFAULT mode):** truncate + rewrite the entire store from source → one record per `session_id` **by construction** (`session_id` = the source filename stem, which is unique per file). Records are emitted in a **deterministic total order** (sort by `started_utc`, then `session_id`, then record kind — `session` before `subagent` — then `subagent_id`), so the record **body is a pure function of the source**: two rebuilds over unchanged source produce a **byte-identical body** (idempotent by `diff`) **modulo the extraction-time metadata** — the per-record `extracted_utc` and the `meta` line's `created_utc` / `last_extract_utc`, which record when extraction ran and update by design. Only files with ≥1 assistant record (spend-bearing sessions) yield a record; zero-assistant files (project summary/index files, empty transcripts) are skipped. The rewrite is atomic — the extractor writes `usage.jsonl.tmp` and then `mv`s it over `usage.jsonl` (same directory → same filesystem → atomic rename), so an interrupted run never leaves a partial store.
- **`--incremental` (opt-in, mtime-gated optimization):** for each source session whose transcript mtime is newer than `meta.last_extract_utc`, **upsert by `session_id`** — drop any existing `session` / `subagent` lines for that `session_id`, then append the freshly-extracted lines; rewrite `meta.last_extract_utc`. One record per `session_id` **by invariant**. The incremental rewrite uses the same tmp-then-`mv` atomic path.
- **Counting-unit boundary (v2.0.0).** When the on-disk store declares another counting unit — another schema **major** version, or an unreadable one — `--rebuild` first keeps it once, as a store, at `<resolved-path>/prior/schema-<old>/usage.jsonl`: a hard link to the store it replaces, readable by the existing tools with `STORE=<resolved-path>/prior/schema-<old>`, and git-ignored like the store. If it cannot be kept, the run fails closed (exit 3) with the store unchanged. `--incremental` falls back to `--rebuild` rather than upserting per-response records into a store of another unit. A store of the current unit (the same major, as after an additive minor bump) is neither kept nor falls back.

Both modes yield the same terminal invariant: no duplicate `session_id`, and the per-session token totals reflect the current source.

## Record: `meta` (line 1)

| Field | Type | Notes |
|---|---|---|
| `record` | `"meta"` | discriminator |
| `schema` | string | `"finops-usage-store"` |
| `schema_version` | semver | current `"2.0.0"`. **Written by extraction and preserved by the roll-up** — from v1.2.0 the version no longer encodes which phase has run (see § Versioning), and from v2.0.0 its major component names the store's counting unit (§ Counting unit). To test whether a roll-up has run, gate on `any(.record == "coverage")`, never on `schema_version` alone |
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
| `worktree` | string\|null | worktree / working-directory **basename** (v1.2.0 — replaces `cwd`; the full absolute path is never persisted). The join key for attribution tiers T1 and T3 — identical to the hub-state Surface-C `worktree` column and the Surface-B composite's first component |
| `git_branch` | string\|null | work-item attribution surface (C2 consumes); null on legacy sessions → C2 `unattributed` |
| `branch_switch` | bool (optional, v1.1.0) | `true` when the session's source records span >1 distinct `gitBranch`; **absent or `false` ⇒ single-branch** (graceful default). A source-level property populated by the extraction phase where present; consumed by the roll-up multi-branch guard so a branch-switching session is never silently attributed to one collapsed branch |
| `git_branches` | array[string] (optional, v1.1.0) | the distinct branch set observed when `branch_switch` is `true` (absent otherwise) |
| `started_utc` / `ended_utc` | ISO 8601 UTC | first / last record timestamp |
| `model` | string | dominant / last model id |
| `service_tier` | string\|null | dominant / last service tier (e.g. `standard`) — cost-determining, parallel to `model` |
| `turns` | int | API-response count (§ Counting unit; the assistant-record count before v2.0.0) |
| `tokens` | object | `{input, output, cache_creation:{total, ephemeral_1h, ephemeral_5m}, cache_read}` (ints) — see below |
| `tool_use` | object | `{web_search_requests, web_fetch_requests}` (ints — the "tool" dimension) |
| `by_skill` | object (v1.2.0, additive) | per-skill token split — `{"<skill>": {turns, tokens}}`, where `tokens` reuses the **identical** four-leaf `session.tokens` shape. **Best-effort**: the source population is partial, so the reserved key `"unknown"` (always present, may be zero) carries the uncovered remainder. **Invariant: `Σ by_skill.*.tokens == session.tokens`.** Label every rendered slice with `dimension_coverage.by_skill` |
| `by_mcp` | object (v1.2.0, additive) | per-MCP-**server** token split — same shape, same always-present reserved `"unknown"` key, same conservation invariant. Best-effort; label with `dimension_coverage.by_mcp` |
| `by_model` | object (v1.2.0, additive) | per-model token split — same shape + reserved key + invariant. **Exact, not dominant/last**: each turn's `message.usage` block belongs to exactly one model, so this is a true partition — it **supersedes `session.model`** (retained, unchanged, as the dominant/last summary) for cost-splitting a mixed-model session |
| `tool_calls` | object (v1.2.0, additive) | `{"<tool-name>": <int>}` — **client-side** tool invocations by name, counted from the turn content, once per `tool_use` `id`. `{}` when none; never absent. **Distinct from `tool_use`**, which counts *server-side* tool requests (`web_search_requests` / `web_fetch_requests`) from `message.usage.server_tool_use` — the two are never folded. No token split (a tool call is a count, not a partition of tokens), hence no reserved key and no conservation invariant |
| `stop_reason` | object (v1.2.0, additive) | `{"<stop-reason>": <int>}` — API-response counts by turn-end reason (the last non-null reason across the response's records); responses carrying no stop reason count under the always-present reserved `"unknown"` key. **Invariant: `Σ stop_reason.* == turns`** |
| `dimension_coverage` | object (v1.2.0, additive) | population honesty for the **best-effort** dimensions only — `{"by_skill": {covered_token_fraction, basis}, "by_mcp": {…}}`. `covered_token_fraction` ∈ [0,1], **token basis**, `= 1 − (by_X."unknown" total ÷ session total)` (`1` when the session total is 0). `basis` ∈ `best-effort` \| `exact` — the enum reserves the upgrade path, so a later deterministic source flips the value with no shape change. **No entry for `by_model` / `tool_calls` / `stop_reason`** — those are exact by construction, and a constant `1.0` would train consumers to ignore the field. A consumer rendering a `by_skill` / `by_mcp` slice without this label is NOT MET |
| `subagent_count` | int | # of `subagent` records for this session (drill-down; already inside `tokens`) |
| `token_source` | enum | `exact` \| `heuristic` \| `mixed` |
| `heuristic_turns` | int | responses estimated via the fallback (usage-less responses) |
| `incomplete_responses` | int | API responses whose final usage never reached the transcript: none of the response's records carries a stop reason, and every one carries a `message.id`, a usage block and the `stop_reason` key (§ Incomplete responses). **Always present**, `0` when none. When non-zero, the record's `tokens` and `tool_use` are **lower bounds** |
| `unevaluated_responses` | int | API responses that carry no stop reason but that the flag cannot evaluate, because a record lacks the `message.id`, the usage block or the `stop_reason` key (§ Incomplete responses). **Always present**, `0` when none; `incomplete_responses: 0` means "none incomplete" only beside it. A record carrying neither count predates the flag and is **not evaluated** — never read the absence as `0` |
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

**Analysis sub-aggregates (v1.2.0, additive) — shape and invariants.** The five `by_*` / count dimensions are **session-grain projections of per-turn data**, not a turn-grain re-grain: each assistant turn's `message.usage` block belongs to exactly one model / at most one skill / at most one MCP server / exactly one stop reason, so summing those blocks per key is **exact**, not approximate. What a session-grain projection drops is only intra-session ordering and timing, which no declared consumer reads.

```jsonc
"by_skill":   { "<skill-name>": { "turns": <int>, "tokens": { … } }, "unknown": { "turns": <int>, "tokens": { … } } },
"by_mcp":     { "<mcp-server>": { "turns": <int>, "tokens": { … } }, "unknown": { … } },
"by_model":   { "<model-id>":   { "turns": <int>, "tokens": { … } }, "unknown": { … } },
"tool_calls": { "<tool-name>": <int> },
"stop_reason":{ "<stop-reason>": <int>, "unknown": <int> },
"dimension_coverage": {
  "by_skill": { "covered_token_fraction": <float 0..1>, "basis": "best-effort" },
  "by_mcp":   { "covered_token_fraction": <float 0..1>, "basis": "best-effort" }
}
```

- **The entry value of a token-bearing map is the wrapper `{turns, tokens}` — NOT a bare tokens object.** An accessor must reach `.tokens` before summing the four leaves; testing the entry itself for `input` finds nothing and silently yields `0`. The wrapper is deliberate: `turns` makes a per-key turn count available without a second map.
- **`tokens` reuses the identical four-leaf `session.tokens` shape** (same nested `cache_creation`), so a downstream question like *"which skill's cache-reads?"* is answerable at the same leaf granularity as the session total. A scalar-total value shape would not answer it.
- **The reserved `"unknown"` key is the honesty mechanism** and is **always present on every token-bearing map, even when zero.** It carries the remainder that the source did not attribute, which is what makes a partial dimension structurally incapable of under-reporting — the uncovered spend is *in the map*, never dropped. Same always-emitted discipline as the roll-up's `unattributed` row; different key name, deliberately, because `unattributed` already means *work-item resolution failed* and drives four other fields.
- **Conservation invariants (asserted in the extractor `--self-test`):** `Σ by_X.*.tokens == session.tokens` for X ∈ {`skill`, `mcp`, `model`}, leaf by leaf; and `Σ stop_reason.* == turns`. `tool_calls` carries no reserved key and no conservation invariant — a tool call is a count, not a partition of tokens.
- **`dimension_coverage` is a stored projection of the `"unknown"` buckets, not a second source of truth.** It is stored rather than left derivable for one reason: the label must be impossible to render without. The self-test asserts the projection agrees with its bucket, so it cannot drift. Precedent: `coverage.attributed_token_fraction` is likewise derivable from the rollup rows and stored anyway.
- **These are partitions *within* `session.tokens`, never additional summands.** The summation invariant below is unchanged by them — a roll-up that added a `by_*` map on top of `session.tokens` would double-count.

> **Spawn-ledger marker — disposition at v1.2.0 (supersedes the routing clause in the `rollup` kind's *No `by_role` field* note below).** That note routes the reliable hub-vs-spoke **role split**, and the hub-emitted **spawn-ledger marker** it depends on, to the downstream intelligence milestone as a future. **The marker was not built there.** v1.2.0 ships the best-effort `by_skill` / `by_mcp` dimensions above *instead*: they answer *which skill spent it* at whatever coverage the source supplies, and label that coverage honestly — they do **not** answer *hub vs spoke*, which still has no reliable local signal, and they do not make issue-grain reliable. The marker remains an **open enhancement on the Agent-FinOps parent epic**, not on any milestone that has shipped; it is a hub-session-continuity / hub-spoke-bridge change, outside this schema's file set. If it lands, `dimension_coverage.by_skill.basis` flips from `best-effort` to `exact` **with no shape change** — that enum value is the reserved upgrade path, and the only surface here the marker would touch.

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
| `started_utc` / `ended_utc` / `model` / `turns` / `tokens` / `tool_use` / `token_source` / `heuristic_turns` / `incomplete_responses` / `unevaluated_responses` / `extracted_utc` | — | same shapes as `session` (`tokens` uses the same nested `cache_creation` structure) |

> **Cross-session subagent note (C1/C2 boundary).** This platform's hub-spoke model spawns spokes as **separate session files**, so `subagent` (in-transcript sidechain) records are rare in practice; cross-file spokes are `session` records that **C2 attributes** as subagents-of-a-parent via `git_branch` + timestamps. C1 does not do cross-file attribution — that is C2's roll-up scope. C1's `subagent` record kind covers only the in-transcript sidechain case, so a Stage-7 check must not false-flag "missing per-subagent counts" when a session simply has no sidechains.

## Incomplete responses (v2.0.0, additive)

A streamed API response reports its usage twice. The opening event carries a provisional `output_tokens` and no stop reason; the closing event carries the stop reason together with the final cumulative usage, including `server_tool_use`. The transcript writes one record per content block, so a record written before the closing event holds only the opening snapshot. When no record of a response is written after the closing event, none of its records carries a stop reason, and the usage they carry is the opening snapshot.

- **Incomplete.** A response is **incomplete** when it carries no stop reason — read by the same rule as `stop_reason`, the last non-null reason across the response's records, in `message.stop_reason` or at the record's top level — and it is **evaluable**: its records were grouped by `message.id`, and every one carries a usage block and the `stop_reason` key in either placement.
- **Not evaluated.** A response that carries no stop reason but is not evaluable counts in `unevaluated_responses` — never as incomplete, and never as complete either. The transcript records measured when this version was written all carried the `message.id` and the `stop_reason` key, so in practice only legacy and synthetic records are not evaluated. The count exists so that a change in the harness's write shape reads as *not evaluated* rather than as *complete*.
- **Partition.** A response that carries no stop reason is exactly one of the two, so on every `session` record `incomplete_responses + unevaluated_responses == stop_reason."unknown"`.
- **What is recorded.** An incomplete response is still counted once, at its max-merged recorded usage; no estimate is substituted, and `token_source` is unchanged. When `incomplete_responses` is non-zero, **every figure the record carries for those responses is a lower bound** — all four `tokens` leaves and `tool_use`, not output alone. Output is the most understated; the input and cache figures can be understated too, because the closing usage is cumulative, and the server-side tool counts are absent. A roll-up over records inherits the lower bound of its records.
- **Not a `token_source` value.** `token_source` says where a figure came from (exact or heuristic); completeness is a separate question, so it is a separate field, and folding it into that enum would break every consumer that switches on it.
- **Absence is not zero.** Records this version writes always carry both counts. A record without them — one written before the flag existed, including every record of a store kept under `prior/` — is **not evaluated**.
- **Invariants** (asserted in the extractor `--self-test`): on every `session` and `subagent` record, `0 ≤ incomplete_responses ≤ turns − heuristic_turns` (an incomplete response carries usage on every record, so it is never a heuristic one) and `incomplete_responses + unevaluated_responses ≤ turns`; on every `session` record, the partition above.
- **Consumers.** A rendering of a record's `tokens` or `tool_use`, or of a roll-up over records, whose `incomplete_responses` is non-zero SHOULD label those figures a lower bound. No consumer reads the two counts yet (§ Counting unit, the data-flow table).

## Record: `rollup` (v1.1.0, additive)

One per resolved work item, **plus** exactly one `work_item_kind:"unattributed"` row (always emitted, even when empty), and one `work_item_kind:"multi-branch"` row when any session switched branches mid-session. A rolled-up projection of `session` records — **honors the summation invariant**: `tokens` = Σ `session.tokens` over `session_ids` ONLY (subagent drill-downs are already inside their `session.tokens`; never re-summed). The session→work-item mapping algorithm — the ordered resolver, the work-item-key format, and the `unattributed` rule — is defined in `core/standards/finops-attribution-convention.md`; this record is the SHAPE the algorithm emits.

| Field | Type | Notes |
|---|---|---|
| `record` | `"rollup"` | discriminator (v1.1.0, additive) |
| `work_item` | string | `#N` (issue) \| `milestone:<release-key>` \| `"unattributed"` \| `"multi-branch"`. `<release-key>` is the milestone **slug** (canonical, slug-primary per ADR-092) or a `vX.Y` emitted by the post-claim version-branch tier — see [`finops-attribution-convention.md`](../standards/finops-attribution-convention.md) § Work-item key format |
| `work_item_kind` | enum | `issue` \| `milestone` \| `unattributed` \| `multi-branch` |
| `attribution_tier` | enum | provenance of the resolution — `branch-milestone` \| `issue-event-keyed` \| `hub-state-lineage` \| `pr-resolved` \| `unattributed` |
| `reproducible` | bool | `true` for every local-only tier; `false` for `pr-resolved` (a network `gh` PR-resolve is time-varying and not part of a deterministic rebuild) |
| `tokens` | object | `{input, output, cache_creation:{total, ephemeral_1h, ephemeral_5m}, cache_read}` = Σ over `session_ids` (same nested shape as `session.tokens`) |
| `tool_use` | object | `{web_search_requests, web_fetch_requests}` rolled up over `session_ids` |
| `session_count` | int | # of `session` records rolled into this work item |
| `session_ids` | array[string] | contributing session UUIDs — the reconciliation surface the ground-truth + conservation checks read |
| `token_source` | enum | `exact` \| `heuristic` \| `mixed` (`mixed` if the contributing sessions differ, or any is `heuristic`) |
| `attribution_basis` | string | human-readable resolution note (e.g. `"slug-primary release branch release/<milestone-slug> -> milestone <slug>"`, or `"branch release/vX.Y-<slug> → milestone"` for the version-form tier; for `unattributed`, the reason the session did not resolve) |
| `rolled_up_utc` | ISO 8601 UTC | roll-up computation time (extraction-time metadata; excluded from idempotence comparison) |

> **No `by_role` field.** A per-session hub-vs-spoke split is deliberately NOT emitted at v1.1.0: release-branch spokes share the hub's release-branch shape — `release/<milestone-slug>` since ADR-092, `release/vX.Y-*` before it — so a branch/worktree heuristic cannot separate hub from spoke with any confidence. A reliable role split needs a hub-emitted spawn-ledger marker (the hub logs each spoke's worktree / session id at spawn) and is deferred to the `agent-finops-intelligence` milestone — an unreliable split presented as data is worse than its absence.

## Record: `coverage` (v1.1.0, additive)

Exactly one per roll-up run — the run-level attribution-health metric. It cannot live on the frozen `meta` record (that would touch a v1.0.0 kind) and it is a run aggregate that does not fit a per-work-item `rollup` row, so it is its own additive kind (queryable via `jq 'select(.record=="coverage")'`).

| Field | Type | Notes |
|---|---|---|
| `record` | `"coverage"` | discriminator (v1.1.0, additive) |
| `attributed_token_fraction` | float 0..1 | tokens resolved to a real work item (`milestone:*` or `#N`) ÷ Σ all tokens |
| `unattributed_token_fraction` | float 0..1 | `1 − attributed_token_fraction` — the not-cleanly-attributed remainder (the explicit `unattributed` bucket **plus** the `multi-branch` bucket) |
| `milestone_grain_token_fraction` | float 0..1 | tokens resolved to a `milestone:*` work item ÷ Σ all |
| `issue_grain_token_fraction` | float 0..1 | tokens resolved to a bare `#N` (`issue-event-keyed` or `pr-resolved`) ÷ Σ all |
| `multi_branch_token_fraction` | float 0..1 | tokens in the `multi-branch` bucket ÷ Σ all (a diagnostic sub-fraction of `unattributed_token_fraction`) |
| `tier_distribution` | object | token fraction per `attribution_tier` — keys `{branch-milestone, issue-event-keyed, hub-state-lineage, pr-resolved, unattributed}` |
| `unattributed_session_rate` | float 0..1 | # sessions → `unattributed` ÷ # sessions (count basis, complements the token basis) |
| `pr_resolved_present` | bool | `true` if a `--resolve-prs` pass contributed non-reproducible rows (so a later local-only rebuild legitimately differs without reading as drift) |
| `count_once_overlap` | int | # of in-transcript sidechain `subagent` records whose identity (`subagent_id`) collides with a standalone `session` record's `session_id` — the hub↔spoke file-boundary count-once guard (see the summation invariant below). **`0` on the current separate-file hub-spoke model** (a `subagent_id` is a sidechain-root uuid within the hub file, never a standalone file stem, so no collision arises); a **non-zero value is fail-visible** — the overlapping sidechain spend was excluded from the hub session's roll-up contribution (the standalone session is authoritative) and warrants operator review of a possible harness double-emit |
| `health` | enum | `OK` \| `WARN` \| `FAIL` versus the `unattributed_token_fraction` threshold defined in `core/standards/finops-attribution-convention.md` |
| `rolled_up_utc` | ISO 8601 UTC | run time (extraction-time metadata; excluded from idempotence comparison) |

## Summation invariant (load-bearing — C2 roll-up contract)

A work-item total = **Σ `session.tokens` over its sessions** ONLY, where a single session's cost-relevant token total is the four leaf integers `input + output + cache_creation.total + cache_read` (`cache_creation.total` is the rolled cache-write; the `ephemeral_1h` / `ephemeral_5m` split and `service_tier` are cost-determining refinements consumed downstream, not additional summands). `subagent` records are an attribution drill-down and are ALREADY included in their `session.tokens`; they are **NEVER** added on top. The roll-up MUST honor this (the roll-up's conservation check reconciles `Σ rollup.tokens` against `Σ session.tokens`; the ground-truth correctness check is separate — see the attribution-convention standard).

**Count-once across the hub↔spoke file boundary (precondition of the summation invariant).** `Σ session.tokens` is correct **only if each unit of spoke spend is embedded in exactly one `session` record** — either the hub session's whole-file total (as an in-transcript `isSidechain` subagent) **XOR** the spoke's own standalone `session` record — **never both**. On this platform, hub-spawned spokes run as **separate session files**, so the hub's `Task` spawn does not embed spoke spend in the hub's whole-file total (the property that makes the sum count-once). This precondition is the boundary complement of the "`subagent` records are drill-downs, never summed on top" rule above. Should a future harness change ever make a spoke appear **both** as an `isSidechain` subagent inside the hub file **and** as its own standalone `session` record, the standalone `session` record is authoritative and the overlapping sidechain contribution is excluded from any additional sum; the roll-up detects the collision (a `subagent` record whose `subagent_id` equals a standalone `session.session_id`), deducts the overlapping sidechain copy from the hub session's contribution, and surfaces the count in its `coverage` record (`count_once_overlap`) for operator review.

The session→work-item mapping algorithm that the `rollup` record projects — the ordered resolver, work-item-key format, `unattributed` rule, multi-branch handling, and the `coverage` health threshold — is defined in `core/standards/finops-attribution-convention.md`.

## Reserved: `provider` (optional)

Emitted ONLY when the OFF-by-default `provider-usage-connector.sh` runs. Declared (reserved) here so formalizing it later is not a breaking bump. Never required; extraction completes from local data alone without it.

## Version History

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-07-25 | Initial freeze — `meta` / `session` / `subagent` record kinds; `provider` reserved; cache-write tier split (`cache_creation.{total, ephemeral_1h, ephemeral_5m}`) + `service_tier`; keyed-projection write-discipline; summation invariant. |
| 1.1.0 | 2026-07-25 | Additive (the C2 attribution slice) — `rollup` record kind (with `attribution_tier` provenance + `reproducible` flag; no `by_role`); `coverage` run-level health record; optional `session.branch_switch` / `session.git_branches`; count-once precondition on the summation invariant. Frozen v1.0.0 kinds unchanged. |
| 1.2.0 | 2026-07-27 | **Frozen-kind replacement under the § Versioning frozen-kind exemption** (conditions (i)–(iii) all verified; rationale in ADR-101) — `session.cwd` (full absolute working-directory path) is **replaced** by `session.worktree` (its basename only): a data-minimization control; no absolute path is persisted, and the T1/T3 join key becomes identical on both sides. A **store-shape preflight** (exit 3) refuses a pre-v1.2.0 on-disk store rather than silently emitting an empty roll-up. **Additive** — five per-session analysis sub-aggregates `by_skill` / `by_mcp` / `by_model` / `tool_calls` / `stop_reason` (each token-bearing map carrying an always-present reserved `"unknown"` bucket, so `Σ by_X.*.tokens == session.tokens`; `Σ stop_reason.* == turns`), plus `session.dimension_coverage` labelling the best-effort population of `by_skill` / `by_mcp` on a token basis. `by_model` is an exact per-turn partition that supersedes the dominant/last `session.model` for cost-splitting; `tool_calls` (client-side, by name) is distinct from the frozen `tool_use` (server-side requests) and is never folded into it. **From this version `schema_version` no longer encodes which phase has run** — both phases emit `1.2.0`; the "roll-up has run" predicate is the presence of the `coverage` record. The frozen v1.1.0 `rollup` and `coverage` record kinds and the `subagent` kind are unchanged. |
| 2.0.0 | 2026-11-05 | **Counting unit corrected — major bump; the frozen-kind exemption was re-tested and not claimed** (condition (i) fails where sources have aged out; its premise does not hold for a same-name value change). Token and turn figures are counted once per API response within one transcript file (records grouped by `message.id`, usage max-merged), not per transcript record. The unit is per file: a response that a resumed or forked session copies into a second file is still counted once in each, 2.52 % of per-response mass overall and 7.39 % of main-session mass (measured 2026-11-05), a residual owned by a separate cross-file follow-up. Inflation factors of a 1.x store at the fix: ×2.33 cache-read, ×2.74 cache-write, ×1.78 output, ×3.35 uncached input. The counting-unit boundary keys on the major version: `--rebuild` keeps a store of another unit once under `prior/`, and `--incremental` falls back to `--rebuild`. Coordination event: the roll-up preserves the version instead of stamping 1.2.0; the report and the estimator read figures unit-agnostically and print the version; pins re-pinned to >= 2.0.0. No record kind changed and no existing field changed shape. **Additive** — `session` / `subagent` `incomplete_responses` and `unevaluated_responses`: the API responses whose final usage never reached the transcript, and those that carry no stop reason but cannot be evaluated (§ Incomplete responses); when the first is non-zero, the record's token and `tool_use` figures are lower bounds. |
