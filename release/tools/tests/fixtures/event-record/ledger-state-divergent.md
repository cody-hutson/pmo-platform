# Action-Item Ledger — STATE-DIVERGENT fixture

Every row is structurally perfect: 13 fields, `status` inside the § 2.3 enum,
`resolved_at` and `resolution` populated. And the record is stale: AI-002 carries
the terminal status `done` while the only word `log-clean.md` has for it is
`action-item-opened`. The card that produced this validator proposed a presence
predicate — "a reconciliation reports 1:1 across the full population" — and it
passed 13 of 13 on the live data while 12 of those 13 rows were in this state.

This file now pins the C5 boundary: C5 grades STRUCTURE, never currency, so it
must PASS this ledger (arm "C5 passes a well-formed but state-stale ledger"). C4
is release-scoped and a ledger FILE's release is its directory, so this file
cannot pair with `log-clean.md`. The same stale shape — presence clean inside the
release, currency stale — is `fixture-c4-rel-a` AI-001 in `c4-collision-tree/`,
where C4 asserts it per release.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:00Z | 5 | #1 | deferred-edit | hub | fixture action item, genuinely resolved | event | after fixture merge | file:log-clean.md | done | 2026-08-24T10:00:01Z | resolved in fixture |
| AI-002 | 2026-08-24T10:00:02Z | 5 | #1 | reminder | hub | fixture action item, marked done with no terminal event | event | after fixture merge | file:log-clean.md | done | 2026-08-24T10:00:09Z | claimed resolved; the log never heard about it |
