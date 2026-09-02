# Hub Session Boundaries — synthetic-malformed (SYNTHETIC FIXTURE)

Fabricated Surface-C data for `rollup-attribution.sh --self-test`. No real session values.

**This file must contribute ZERO entries to the worktree→milestone map.** It reproduces the
two malformation shapes observed in the live hub-state population, both of which the
pre-fix extraction ingested as if they were session rows:

1. **A pipe table with no `session_id` header.** The pre-fix header-skip was
   `$0 !~ /session_id/`, which cannot skip a header that does not contain `session_id` — so
   the header row itself was read as data, and a hardcoded `$5` yielded the literal column
   label `Action` as a worktree key.
2. **A conforming header followed by a width-mismatched data row.** A hardcoded `$5` on a
   narrower row lands on a different column and reads narrative prose as a worktree key.

The fix binds the `worktree` column index and the field count from the row that declares
**both** `session_id` and `worktree`, and ingests only later rows of that width. Neither
shape below can survive it.

## Shape 1 — pipe table, no `session_id` header

| Sub-task | Issue | Wave 1 | Action |
|---|---|---|---|
| S-01 | #9001 | scaffolded | consumed |
| S-02 | #9002 | scaffolded | re-spawned |
| S-03 | #9003 | held | consumed |

## Shape 2 — conforming header, width-mismatched data row

| session_id | started_at | ended_at | worktree | commit_sha_start | commit_sha_end | events_emitted |
|---|---|---|---|---|---|---|
| malformed-narrow__2020-01-01T00:00:00Z__9999999 | 2020-01-01T00:00:00Z | Stage 12 Execute — HELD |
