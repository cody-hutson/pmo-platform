---
name: finops-usage-extractor
description: >
  Extracts per-session and per-subagent agent token-spend from local Claude Code session data
  into the operator-local, git-ignored FinOps usage store (schema authority:
  core/schemas/finops-usage-store-schema.md). Exact message.usage counts are primary; the
  context-budget-auditor skill's ceil(words/0.75) heuristic is the fallback for usage-less
  records only. Read-only on the source transcripts — writes only the resolved store. It also
  attributes and rolls per-session spend up to its owning work item (milestone-grain reliable;
  unattributed fail-visible) with a coverage metric. Distinct
  from context-budget-auditor, which measures STATIC corpus footprint; this measures RUNTIME
  session spend. Use to populate or
  refresh token-usage data, or to attribute and roll it up, for FinOps reporting. Triggers: "extract token usage", "refresh the
  finops store", "how much token spend", "run the finops extractor",
  "roll up token usage", "attribute token spend", "which work item spent the tokens".
version: v3.93
license: BUSL-1.1
delivery_approach: advisory
---
<!-- repo-integrity: allow-issue-ref -->

# finops-usage-extractor

## Purpose

Read-only extraction of runtime token spend from local Claude Code session transcripts into the operator-local usage store defined by `core/schemas/finops-usage-store-schema.md`. It sums each session's exact `message.usage` token dimensions (input / output / cache-write with tier split / cache-read) plus tool-use request counts and the cost-determining `service_tier`, and normalizes them into a versioned JSONL derived cache. Exact source counts are authoritative; the context-budget-auditor skill's `ceil(words/0.75)` heuristic is the fallback for records that lack `message.usage`.

This skill measures **runtime session spend** — distinct from context-budget-auditor, which measures **static corpus footprint**. It reuses that skill's estimation *method* (the word→token fallback), not its scanner.

## Scope

Two phases over one source (the local session store), one skill:

- **Extraction + normalization (C1).** `extract-usage.sh` parses local Claude Code session transcripts into the frozen **v1.0.0** store (`meta` / `session` / `subagent` record kinds; `provider` reserved-optional). Exact `message.usage` counts are primary; the word→token heuristic is the usage-less fallback.
- **Attribution + roll-up (C2).** `rollup-attribution.sh` reads that store and writes the additive **v1.1.0** `rollup` + `coverage` records: it resolves each `session` to its owning work item, rolls per-session spend up to that work item (honoring the summation invariant), and emits a run-level attribution-health `coverage` record. The session→work-item mapping ALGORITHM — the ordered LOCAL-ONLY resolver (issue-event key → release/chore branch → hub-state lineage → `unattributed`, plus an opt-in network PR-resolve) — lives in `core/standards/finops-attribution-convention.md`; the record SHAPES live in the store schema. Milestone-grain is reliable from local data alone; issue-grain is best-effort (a decision-event key, or the opt-in `--resolve-prs` resolve); everything unresolved lands in an explicit `unattributed` bucket, fail-visible. Reliable issue-grain and a hub-vs-spoke role split need a hub-emitted spawn-ledger marker and are deferred to the downstream agent-finops-intelligence milestone.

## Usage

```
bash core/skills/finops-usage-extractor/scripts/extract-usage.sh [--rebuild | --incremental] [--self-test]
```

- **`--rebuild` (DEFAULT):** truncate + rewrite the entire store from source (idempotent by construction — deterministic record order, byte-identical across runs over unchanged source; atomic tmp-then-`mv`).
- **`--incremental` (opt-in):** mtime-gated optimization — upsert only sessions whose transcript changed since the last extraction; one record per `session_id`, newest-wins.
- **`--self-test`:** run the built-in assertions (heuristic estimator, cache-tier invariant, idempotence) against the synthetic fixtures in `test-fixtures/` — no source or store access required.

The optional plan-gated provider connector (`scripts/provider-usage-connector.sh`) is **OFF by default** and never on the critical path — extraction completes fully from local session data alone.

Roll-up + attribution (run after extraction):

```
bash core/skills/finops-usage-extractor/scripts/rollup-attribution.sh [--emit] [--resolve-prs] [--self-test]
```

- **`--emit` (DEFAULT):** resolve every `session` to its work item and write the `rollup` + `coverage` records into the store (strip any prior ones, append fresh, bump `meta.schema_version` to 1.1.0). **LOCAL-ONLY** — no network, no `gh`. Idempotent over an unchanged store (byte-identical body modulo the `rolled_up_utc` metadata); session/subagent lines untouched.
- **`--resolve-prs` (OPT-IN):** additionally resolve `fix/*` / `feat/*` branches via a read-only `gh` PR→closing-issue query (network; non-reproducible). Absent → those sessions degrade to `unattributed`. Every resulting row is stamped `attribution_tier: pr-resolved` + `reproducible: false`.
- **`--self-test`:** run the ground-truth labeled-fixture attribution check (CIAC-1 primary), the conservation identity (secondary), coverage + health, multi-branch bucketing, and idempotence against the synthetic `test-fixtures/rollup/` set — no operator-store or network access.

## Dependencies

- **`jq`** (REQUIRED) — the extractor parses session JSONL with `jq` throughout. Missing `jq` is a hard preflight failure (**exit 5**). Note: context-budget-auditor is pure-bash; `jq` is a genuinely new runtime dependency here, hence the explicit declaration + preflight.
- **`git`** (REQUIRED) — the fail-closed store guard uses `git check-ignore` to refuse writing a store path that is inside a repository but not git-ignored. Missing `git` fails the same preflight (**exit 5**).
- **`bash`** — bash-3.2-safe integer arithmetic (the reused context-budget-auditor heuristic is already bash-3.2-safe).

## Read-only posture

The extractor **never writes to** `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects` (the source transcripts). It writes exactly one path: `<resolved-store>/usage.jsonl` (via an atomic `usage.jsonl.tmp` → `mv`). The store path resolves from config (`operator.toml [paths].operator_instance_finops_store_path`, default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops`) — no hardcoded operator path.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | OK — extraction completed (or `--self-test` passed) |
| `2` | Usage error (unknown flag / bad invocation) |
| `3` | Source unreadable (session-data root missing or unreadable) |
| `4` | Store-not-git-ignored — the resolved store is inside a git repo but not ignored there; the write is refused (fail-closed public-repo exfil guard) |
| `5` | Missing dependency (`jq` or `git` not on PATH) |

## Domain-Specific Failure Modes

### Double-counting sidechain subagents — PROC

- **Signature (observable signal):** a work-item or session total that is visibly inflated — the store's `session.tokens` plus the session's `subagent.tokens` both counted, so a roll-up reads roughly double the true spend for any session that has sidechains.
- **Conditional:** do NOT add `subagent.tokens` on top of `session.tokens` when computing a session or work-item total, because `session.tokens` is already the whole-file total (inclusive of every in-transcript sidechain) and `subagent` records are a drill-down, not an additional summand.
- **Root cause:** the two record kinds look additive (both carry a `tokens` object of the same shape), so a summation that filters `.record=="session" or .record=="subagent"` silently double-counts sidechain spend.
- **Mitigation:** sum `session.tokens` ONLY (the four leaf integers `input + output + cache_creation.total + cache_read`); treat `subagent` records purely as an attribution drill-down. The schema's summation invariant states this; the `--self-test` idempotence check guards the per-session digest.
- **Principal response vs. junior response:** a principal reads the schema's summation invariant before writing any aggregation and encodes "session-only" once; a junior writes an intuitive `select(.record=="session" or .record=="subagent")` sum and ships a doubled total that only surfaces on sessions that happen to have sidechains.

### Dropping legacy null-`gitBranch` sessions — INPUT

- **Signature (observable signal):** the store's session count is lower than the source session-file count, and older sessions are silently absent — total spend under-reports because pre-attribution sessions were skipped.
- **Conditional:** do NOT skip or discard a session record when its `git_branch` is null, because a null branch is a legacy pre-field-introduction session whose spend is still real and must land in the store (attribution to a work item is C2's `unattributed` bucket, not a C1 drop condition).
- **Root cause:** conflating "cannot attribute to a work item" (a C2 concern) with "cannot extract" (a C1 concern) — the extractor treats a missing attribution key as a reason to skip rather than capturing null and deferring attribution.
- **Mitigation:** capture `git_branch: null` where the source lacks it; extract the session's tokens regardless; leave attribution entirely to C2. Never gate extraction on the presence of an attribution surface.
- **Principal response vs. junior response:** a principal separates extraction from attribution by contract and captures null fail-visibly; a junior filters `select(.gitBranch!=null)` at read time and silently loses every legacy session's spend.

### Presenting heuristic figures as exact — OUT

- **Signature (observable signal):** a downstream cost figure carries no provenance, so a ±25% heuristic estimate is indistinguishable from an exact provider count in the store and in any report built on it.
- **Conditional:** do NOT emit a session/subagent record without setting `token_source` (and `heuristic_turns`) when any turn was estimated via the fallback, because a consumer cannot otherwise exclude or flag heuristic-derived totals and will treat an approximation as an exact cost.
- **Root cause:** the fallback estimator produces integers in the same fields as the exact path, so without an explicit provenance flag the two are byte-identical downstream.
- **Mitigation:** always set `token_source` to `exact` / `heuristic` / `mixed` and record `heuristic_turns`; the fallback fires only for records lacking `message.usage`, and exact source counts are always primary when present.
- **Principal response vs. junior response:** a principal makes provenance a first-class field so a consumer can exclude heuristic totals; a junior lets the fallback fill the same fields silently and ships a store where approximate and exact cost cannot be told apart.

### Mis-parsing a harness-auto branch as a work item — INPUT

- **Signature (observable signal):** a `rollup` row books real spend to a `milestone:*` or `#N` the session never worked on, because a harness-auto `claude/<adjective-noun>` / `agent-*` branch name was force-parsed into a work item.
- **Conditional:** do NOT parse a `git_branch` into a work item unless it matches the reliable `release/vX.Y-*` / `chore/vX.Y-*` prefix (T2) or the opt-in `fix/*` / `feat/*` PR path (T-PR), because a harness-auto worktree branch is an adjective-noun-hash with no work-item content, and coercing it fabricates an attribution.
- **Root cause:** conflating "the session has a branch" with "the branch names a work item" — the harness auto-branch class carries no work-item signal at all.
- **Mitigation:** only the T2 / T-PR prefixes parse from the branch string; the issue-event key (T1) and hub-state lineage (T3) resolve from local hub-state instead; everything else → `unattributed` with the reason recorded in `attribution_basis`.
- **Principal response vs. junior response:** a principal enumerates the branch classes (per `git-workflow.md`) and parses only the ones that encode a work item; a junior regexes a version out of any branch and silently mis-attributes every auto-worktree session.

### Silently collapsing a branch-switching session onto one branch — PROC

- **Signature (observable signal):** a session that spanned two branches (e.g. `release/vX.Y-a` then `fix/b`) has its ENTIRE token total booked to one milestone, over-crediting that work item and starving the other.
- **Conditional:** do NOT run a session through the branch tiers when `branch_switch == true`, because the store collapses `git_branch` to a single value and attributing the whole session to it mis-allocates the spend that belonged to the other branch(es).
- **Root cause:** the single-valued `session.git_branch` hides that the source records spanned multiple branches; a resolver reading only the collapsed value cannot see the switch.
- **Mitigation:** the multi-branch guard sits ABOVE the resolver — `branch_switch == true` routes the session to a distinct `multi-branch` bucket carrying `git_branches[]`, never to a single milestone; `coverage.multi_branch_token_fraction` surfaces the volume for review.
- **Principal response vs. junior response:** a principal treats branch attribution as unsafe whenever the branch is not single-valued and buckets it honestly; a junior attributes to whichever branch the extractor happened to keep.

### Presenting heuristic / network-derived attribution as authoritative — OUT

- **Signature (observable signal):** a downstream report cannot tell a deterministic `branch-milestone` attribution from a fuzzy `issue-event-keyed` one or a non-reproducible `pr-resolved` one, so a best-effort guess is consumed as ground truth.
- **Conditional:** do NOT emit a `rollup` row without its `attribution_tier` and `reproducible` provenance, and do NOT put the `--resolve-prs` network resolve on a path that must be reproducible, because a network PR-resolve is time-varying and a fuzzy event-key match is not id-equality — a consumer must be able to weight or exclude them.
- **Root cause:** every tier produces a `#N` / `milestone:*` in the same field, so without an explicit provenance tag a strong and a weak attribution are byte-identical downstream.
- **Mitigation:** every row carries `attribution_tier` (the 5-value enum) and `reproducible`; the default path is LOCAL-ONLY and reproducible; `pr-resolved` rows are `reproducible: false` and recorded in `coverage.pr_resolved_present`; the health threshold + `tier_distribution` let the downstream calibration slice tune the mix.
- **Principal response vs. junior response:** a principal makes provenance first-class so a consumer can exclude weak tiers; a junior ships a roll-up where a deterministic milestone and a network-guessed issue look identical.

## Guardrails (Platform)

- **Data hygiene (CIAC-3):** the store holds real session-data values (branch names, token counts, session UUIDs, `cwd` home paths) that MUST NEVER be committed or published on this PUBLIC repo. The store is git-ignored operator-instance data; the fail-closed `check-ignore` guard (exit 4) is the runtime enforcement. This skill's `test-fixtures/` are **synthetic** (fabricated) — never real transcripts.
- **No-invention / evidence labels:** exact `message.usage` counts are `[SOURCE]`; heuristic figures are `[INFERRED]` and always flagged via `token_source`.
- **Reversibility:** MODERATE / Confidence HIGH — the store is a derived cache (operator-deletable; rebuilt from source); the schema freeze is the load-bearing stability control. The C2 attribution phase is additive (v1.1.0 `rollup` + `coverage`) and content-only; the `unattributed` bucket makes the resolver safe-by-construction (it never claims a grain it cannot deliver).
