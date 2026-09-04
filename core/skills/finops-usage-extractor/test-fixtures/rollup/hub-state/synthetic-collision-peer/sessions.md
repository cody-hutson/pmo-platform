# Hub Session Boundaries — synthetic-collision-peer (SYNTHETIC FIXTURE)

Fabricated Surface-C data for `rollup-attribution.sh --self-test`. No real session values.

The **collision-determinism** arm's second half. This directory declares the same `worktree`
key (`collide-wt`) as `synthetic-slug-release/`, so the map builder sees one key claimed by
two milestones. The jq reduction is last-wins, and the record it feeds asserts
`reproducible: true` — so the builder sorts its `find` output (`LC_ALL=C`) to make the
outcome deterministic and emits one `WARNING:` on stderr to make it visible. Fail-visible,
never a silent drop.

No session record uses `collide-wt`, so this fixture proves the collision handling without
perturbing any graded resolution.

## Hub Sessions

| session_id | started_at | ended_at | worktree | commit_sha_start | commit_sha_end | events_emitted |
|---|---|---|---|---|---|---|
| collide-wt__2020-01-01T02:00:00Z__1111aaa | 2020-01-01T02:00:00Z | 2020-01-01T02:20:00Z | collide-wt | 1111aaa | 2222bbb | 1 |
