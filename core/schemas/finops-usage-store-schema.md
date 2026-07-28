---
title: FinOps Usage Store Schema — Agent Token-Spend Runtime Store
purpose: The canonical data contract for the operator-local Agent-FinOps usage store — the JSONL record kinds, fields, versioning, write-discipline, and summation invariant for per-session and per-subagent token counts extracted from local Claude Code session data. v1.1.0 (the C2 attribution slice) adds the roll-up and coverage record kinds; the session→work-item mapping algorithm lives in the FinOps attribution-convention standard. v1.2.0 replaces `session.cwd` (a full absolute working-directory path) with `session.worktree` (its basename only) as a data-minimization control, under the conditioned frozen-kind exemption recorded in § Versioning.
type: schema
status: ACTIVE
schema_version: "1.2.0"
reversibility: MODERATE / HIGH confidence (consumed by the C2 attribution slice + the downstream agent-finops-intelligence milestone; additive extension is backward-compatible, a breaking field change is a major bump + a downstream coordination event **unless the § Versioning frozen-kind exemption's three conditions all hold**)
consumers: "finops-usage-extractor (producer); the C2 attribution/roll-up slice (extends v1.1.0 rollup record); the agent-finops-intelligence milestone — estimation, reporting, calibration (version-pin >= v1.2.0)"
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# FinOps Usage Store Schema

> **v1.2.0** data contract for Agent token-spend FinOps. The frozen **v1.0.0** core (slice C1, the data foundation) defines the `meta` / `session` / `subagent` record kinds; **v1.1.0** (the C2 attribution slice) adds the `rollup` and `coverage` record kinds additively (the frozen v1.0.0 kinds are unchanged); **v1.2.0** replaces `session.cwd` with `session.worktree` (its basename only — a data-minimization control) under the conditioned frozen-kind exemption in § Versioning, and stops encoding which phase has run in the version number. This doc is the schema authority; the `finops-usage-extractor` skill is the producer.

## Purpose + Scope

Defines the operator-local Agent-FinOps usage store: WHERE it lives, its FORMAT, and the FROZEN v1.0.0 record kinds. The store is a **derived cache** — a deterministic projection of local Claude Code session transcripts (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/**/*.jsonl`), which remain the source of truth (the same derived-cache posture as the SQLite index schema). It is NOT an audit log: the extractor may rebuild it from source at any time.

## Store Location

Resolved from the `<OPERATOR_INSTANCE_FINOPS_STORE_PATH>` token per the depersonalization-spec token vocabulary: (a) the `operator.toml [paths].operator_instance_finops_store_path` override if set, else (b) the default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops`. Store file: `<resolved-path>/usage.jsonl`.

The store is **git-ignored** operator-instance data — its records carry `git_branch`, `worktree` (a directory basename, not a home path — v1.2.0 data-minimization), and work-item identifiers, so on a PUBLIC repo it must never commit. This is enforced two ways: the static `.gitignore` patterns (the `personal/` + `pmo-instance/` homes plus defensive finops stems), AND a resolve-time `git check-ignore` guard in the extractor that refuses to write when the resolved store falls inside a git repository but is not ignored there (see the extractor's exit-code contract).

## Format

JSONL — one JSON object per line, discriminated by a top-level `record` field. Line 1 is the `meta` record; subsequent lines are `session` / `subagent` records. Consumers filter by `.record` (jq-native).

## Versioning

`schema_version` travels in the `meta` record (semver). **v1.0.0 (C1, this doc) freezes** the `meta`, `session`, and `subagent` record kinds and their field sets, and reserves `provider` (optional). **v1.1.0 (the C2 attribution slice) adds** the `rollup` and `coverage` record kinds plus two optional `session` fields (`branch_switch` / `git_branches`) — all additive; the frozen v1.0.0 kinds are unchanged. An additive change is a minor bump; a breaking change to a frozen kind is a major bump plus a coordination event across the downstream `agent-finops-intelligence` consumers, which pin `schema_version >= 1.2.0`.

**Frozen-kind exemption (conditioned, per-change, never standing).** A **breaking** change to a frozen kind normally takes a **major** bump plus a coordination event across pinned consumers. It may instead take a **minor** bump when **all three** conditions hold at the time of the change:

1. **Derived-cache condition** — the store is a derived cache, deterministically rebuildable from source by `extract-usage.sh --rebuild`, so the change is a **rebuild, not a data migration**, and no operator data can be lost by it.
2. **No-external-consumer condition** — **no consumer outside this repository's tracked corpus reads the changed field.** The store is operator-local and unpublished, so there is no third-party reader to coordinate with. *If any external or unknown consumer reads the field, this condition fails.*
3. **Same-PR condition** — **every in-repo consumer of the changed field is updated in the same pull request**, so the coordination event the major-bump rule exists to force is internal to that PR and has already occurred by the time the version ships.

**If any condition fails — in particular if a live consumer reads the changed field outside the same PR — the change takes the major bump and the coordination event, unchanged.** The exemption is **claimed per change**: the Version-History row for that version must name it, and the rationale must be recorded in an ADR. A later frozen-kind change re-tests all three conditions from scratch; nothing here makes minor bumps the default for frozen-kind changes.

**Applied once, at v1.2.0** (`session.cwd` → `session.worktree`; ADR-099): (i) held — the store is a derived cache and the change ships with `--rebuild` as the default mode; (ii) held — the store is git-ignored operator-local data with no published consumer; (iii) held — the sole in-repo reader, `rollup-attribution.sh`, is updated in the same PR, together with the attribution convention's T1/T3 rule text and every affected fixture. A **store-shape preflight** (exit 3) additionally makes a stale on-disk store fail loudly rather than silently, so condition (i)'s "rebuild, not migration" is enforced at runtime rather than assumed.

**Phase progression — what the version number does and does not tell you.** Through v1.1.0 the version encoded *which phase had run*: extraction alone wrote `"1.0.0"`, and a roll-up pass bumped it to `"1.1.0"`, so a consumer pinning `>= 1.1.0` was implicitly guaranteed the store held `rollup` records. **v1.2.0 retires that guarantee**, because v1.2.0 changed the *extraction* phase's own record shape — an extraction-only store is no longer v1.0.0-conformant, so it must report `1.2.0` too, and there is no semver that says "v1.2.0 session shape, no rollup kinds". Both phases therefore emit `meta.schema_version = "1.2.0"`. **From v1.2.0 the version no longer encodes which phase has run.** The canonical "a roll-up has run" predicate is the presence of the mandatory run-level record — `any(.record == "coverage")` (exactly one per roll-up run, always emitted). **Consumers MUST gate on that predicate, never on `schema_version` alone.**

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
| `schema_version` | semver | current `"1.2.0"`. **Both phases emit it** — from v1.2.0 the version no longer encodes which phase has run (see § Versioning). To test whether a roll-up has run, gate on `any(.record == "coverage")`, never on `schema_version` alone |
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

## Record: `rollup` (v1.1.0, additive)

One per resolved work item, **plus** exactly one `work_item_kind:"unattributed"` row (always emitted, even when empty), and one `work_item_kind:"multi-branch"` row when any session switched branches mid-session. A rolled-up projection of `session` records — **honors the summation invariant**: `tokens` = Σ `session.tokens` over `session_ids` ONLY (subagent drill-downs are already inside their `session.tokens`; never re-summed). The session→work-item mapping algorithm — the ordered resolver, the work-item-key format, and the `unattributed` rule — is defined in `core/standards/finops-attribution-convention.md`; this record is the SHAPE the algorithm emits.

| Field | Type | Notes |
|---|---|---|
| `record` | `"rollup"` | discriminator (v1.1.0, additive) |
| `work_item` | string | `#N` (issue) \| `milestone:vX.Y` \| `"unattributed"` \| `"multi-branch"` |
| `work_item_kind` | enum | `issue` \| `milestone` \| `unattributed` \| `multi-branch` |
| `attribution_tier` | enum | provenance of the resolution — `branch-milestone` \| `issue-event-keyed` \| `hub-state-lineage` \| `pr-resolved` \| `unattributed` |
| `reproducible` | bool | `true` for every local-only tier; `false` for `pr-resolved` (a network `gh` PR-resolve is time-varying and not part of a deterministic rebuild) |
| `tokens` | object | `{input, output, cache_creation:{total, ephemeral_1h, ephemeral_5m}, cache_read}` = Σ over `session_ids` (same nested shape as `session.tokens`) |
| `tool_use` | object | `{web_search_requests, web_fetch_requests}` rolled up over `session_ids` |
| `session_count` | int | # of `session` records rolled into this work item |
| `session_ids` | array[string] | contributing session UUIDs — the reconciliation surface the ground-truth + conservation checks read |
| `token_source` | enum | `exact` \| `heuristic` \| `mixed` (`mixed` if the contributing sessions differ, or any is `heuristic`) |
| `attribution_basis` | string | human-readable resolution note (e.g. `"branch release/vX.Y-<slug> → milestone"`; for `unattributed`, the reason the session did not resolve) |
| `rolled_up_utc` | ISO 8601 UTC | roll-up computation time (extraction-time metadata; excluded from idempotence comparison) |

> **No `by_role` field.** A per-session hub-vs-spoke split is deliberately NOT emitted at v1.1.0: release-branch spokes share the hub's `release/vX.Y-*` branch shape, so a branch/worktree heuristic cannot separate hub from spoke with any confidence. A reliable role split needs a hub-emitted spawn-ledger marker (the hub logs each spoke's worktree / session id at spawn) and is deferred to the `agent-finops-intelligence` milestone — an unreliable split presented as data is worse than its absence.

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
| 1.2.0 | 2026-07-27 | **Frozen-kind replacement under the § Versioning frozen-kind exemption** (conditions (i)–(iii) all verified; rationale in ADR-099) — `session.cwd` (full absolute working-directory path) is **replaced** by `session.worktree` (its basename only): a data-minimization control; no absolute path is persisted, and the T1/T3 join key becomes identical on both sides. A **store-shape preflight** (exit 3) refuses a pre-v1.2.0 on-disk store rather than silently emitting an empty roll-up. **From this version `schema_version` no longer encodes which phase has run** — both phases emit `1.2.0`; the "roll-up has run" predicate is the presence of the `coverage` record. The frozen v1.1.0 `rollup` and `coverage` record kinds and the `subagent` kind are unchanged. |
