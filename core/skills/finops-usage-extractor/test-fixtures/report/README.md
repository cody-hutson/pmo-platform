# finops-usage-extractor — synthetic report fixtures

These files are **fabricated** synthetic FinOps usage stores used only by
`report-usage.sh --self-test`. They contain **no real extracted values** — every
`session_id`, `git_branch`, `worktree`, `project_dir`, timestamp, work item and
token count is invented (per the CIAC-3 data-hygiene rule: the tooling's tests
never read the operator-local store, and no real session-data value appears in any
committed artifact on this public repo).

The two `synthetic-operator` path strings are **deliberate negative controls**, not
observed values: `usage.jsonl` carries a path-mangled `project_dir` and
`usage-v110.jsonl` a raw absolute `cwd`, so SM-4 can prove the renderer emits
neither. A test that asserts "the render contains no home path" is worthless unless
the fixture contains one.

| Fixture | Exercises |
|---|---|
| `usage.jsonl` | **The main v1.2.0 rolled-up store** — 8 sessions across **5 Monday-start weeks** beginning 2026-06-01, one week (2026-06-15) deliberately **empty**. Covers: all three `token_source` values; a `milestone:*` × 2, a bare `#N` × 2, plus the `unattributed` and `multi-branch` buckets; one row per `attribution_tier` **including a `pr-resolved` / `reproducible:false` row**; 5 distinct `worktree` basenames (one of which, `heur-wt`, is **purely heuristic** so a `[INFERRED]` row renders beside exact ones); `by_skill` / `by_mcp` on a subset with per-period coverage drifting 17% → 100% (drives the TC-gate and the COVERAGE-DRIFT note) and a **rising** `release-hub` signal that must still yield no direction; a mixed-model session for `by_model`; `tool_calls`; `stop_reason`; one `subagent` drill-down record that must contribute **zero**; one session absent from every `rollup.session_ids[]` (drives the explicit `(not-rolled-up)` bucket); and a path-mangled `project_dir` (the SM-4 negative control). |
| `usage-v110.jsonl` | **A pre-v1.2.0 store** — session records carry `cwd` (a fabricated absolute path) and **no** `worktree`, and none of the five v1.2.0 analysis dimensions. Drives SM-9 (each best-effort dimension renders an explicit `UNAVAILABLE` line rather than being silently omitted, while the exact dimensions still render and the run exits 0) and INT-4 (the directory dimension still resolves to a **basename**, never the path, before the rename). |
| `usage-no-rollup.jsonl` | **A store with sessions but no `coverage` record**, while `meta.schema_version` still reads `1.2.0`. Drives SM-9b: the "a roll-up has run" predicate is the presence of the run-level `coverage` record — **never** the version string, which both extraction and roll-up emit identically from v1.2.0 and which the roll-up rewrites unconditionally. |
| `report.expected.json` | The `--json` oracle for SM-11, compared modulo `generated_utc`. Regenerate with the same window the self-test uses (`--since <min session date> --until <max session date> --json --trend`, clock pinned via `FINOPS_REPORT_NOW`) whenever the model shape changes intentionally. |

**Conservation invariants hold in every fixture session** and are what the report's
own SM-5 check reconciles against: `Σ by_X.*.tokens == session.tokens` leaf by leaf
for X ∈ {skill, mcp, model} (the always-present reserved `"unknown"` bucket carries
the remainder), and `Σ stop_reason.* == turns`. Each `rollup.tokens` equals the sum
of `session.tokens` over its `session_ids`.
