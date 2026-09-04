# Hub Session Boundaries — synthetic-slug-release (SYNTHETIC FIXTURE)

Fabricated Surface-C data for `rollup-attribution.sh --self-test`. No real session values.

This directory basename is a **slug**, not a `vX.Y` version — the canonical post-ADR-092
run-key form (`hub-session-continuity.md` § 2), and the form the shipped `v[0-9]*` predicate
dropped. The sibling `v9.9/` directory is the legacy-version arm; the two together are the
two-form proof.

## Hub Sessions

| session_id | started_at | ended_at | worktree | commit_sha_start | commit_sha_end | events_emitted |
|---|---|---|---|---|---|---|
| slug-synthetic-cc33__2020-01-01T00:05:00Z__aaa1111 | 2020-01-01T00:05:00Z | 2020-01-01T00:25:00Z | slug-synthetic-cc33 | aaa1111 | bbb2222 | 2 |
| shadow-wt__2020-01-01T00:30:00Z__ccc3333 | 2020-01-01T00:30:00Z | 2020-01-01T00:50:00Z | shadow-wt | ccc3333 | ddd4444 | 1 |
| collide-wt__2020-01-01T01:00:00Z__eee5555 | 2020-01-01T01:00:00Z | 2020-01-01T01:20:00Z | collide-wt | eee5555 | fff6666 | 1 |

The `shadow-wt` row is the **shadowing-guard** arm: a session on branch
`release/synthetic-slug-release-suffix` joins this row, so the authored `<slug>` here must
win over the branch-parsed `<slug>-suffix`. The `collide-wt` row is one half of the
**collision-determinism** arm — its peer lives in `synthetic-collision-peer/`, and no
session record uses it, so the collision is observable without perturbing any resolution.
