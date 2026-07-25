# Pipeline Event Log — SYNTHETIC FIXTURE

Fabricated Surface-B data for `rollup-attribution.sh --self-test`. No real values.
The T1 (issue-event-keyed) resolver reads decision/gate-outcome/escalation rows whose
`payload` carries `session:<composite>` and whose subject/actor names an issue.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2020-01-01T00:00:30Z | v9.9 | 6 | decision | d-class | spoke:#4242 | #4242 | MODERATE | resolved | session:quirky-synthetic-aa11__2020-01-01T00:00:30Z__abc1234; note:synthetic |
| 2020-01-01T00:03:00Z | v9.9 | 6 | iteration | dt-adjust | hub | #4242 | CHEAP | resolved | note:ignored-event-type-not-a-decision |
| 2020-01-01T00:04:00Z | v9.9 | 9 | gate-outcome | plan-review-go | operator | #9999 | MODERATE | resolved | session:absent-worktree-zz99__2020-01-01T00:04:00Z__ffff000; note:no-matching-session |
