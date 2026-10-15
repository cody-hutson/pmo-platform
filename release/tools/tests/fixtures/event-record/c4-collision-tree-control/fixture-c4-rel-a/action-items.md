# Action-Item Ledger — C4 collision CONTROL tree, `fixture-c4-rel-a`

Authored as its own file rather than copied from `c4-collision-tree/`, because no
mirror between the two trees is enforced. The rows are the collision tree's, and
against `log-c4-collision-control.md` each one is satisfied by this release's OWN
events: AI-001's terminal status by its own `action-item-superseded`, AI-002 by its
own `action-item-opened`, AI-003 by its own opened event.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:00Z | 5 | #1 | deferred-edit | hub | terminal status matched by its own terminal event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | superseded | 2026-08-24T10:00:08Z | superseded in fixture |
| AI-002 | 2026-08-24T10:00:02Z | 5 | #1 | reminder | hub | own opened event present | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | open | — | — |
| AI-003 | 2026-08-24T10:00:01Z | 5 | #1 | reminder | hub | own opened event present | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision-control.md | open | — | — |
