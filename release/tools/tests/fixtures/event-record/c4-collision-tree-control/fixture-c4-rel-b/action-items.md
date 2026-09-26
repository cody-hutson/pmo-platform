# Action-Item Ledger — C4 collision CONTROL tree, `fixture-c4-rel-b`

The collision tree's `fixture-c4-rel-b` ledger, made to agree with every event this
release emitted: the AI-003 and AI-006 rows it owes are present, and AI-005 is a
well-formed row rather than the C5-rejected one, so C5 has nothing to report either.
AI-006 is `done`, matching the terminal event that closes its straddling pair.
Paired log: `log-c4-collision-control.md`.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:02Z | 5 | #2 | deferred-edit | hub | terminal status matched by its own terminal event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | superseded | 2026-08-24T10:00:03Z | superseded in fixture |
| AI-002 | 2026-08-24T10:00:04Z | 5 | #2 | reminder | hub | own opened event present | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | open | — | — |
| AI-003 | 2026-08-24T10:00:05Z | 5 | #2 | reminder | hub | the row this release owes for its own AI-003 event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | open | — | — |
| AI-005 | 2026-08-24T10:00:06Z | 5 | #2 | reminder | hub | well-formed; own opened event present | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | open | — | — |
| AI-006 | 2026-08-12T10:00:00Z | 5 | #2 | reminder | hub | the row this release owes for its straddling AI-006 pair | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | done | 2026-08-24T10:00:07Z | resolved in fixture |
