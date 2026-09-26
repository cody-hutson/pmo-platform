# Action-Item Ledger — C4 collision tree, `fixture-c4-rel-b` (the DONOR)

The directory name is the release key. AI-001 and AI-002 are the near-misses: the
same statuses as `fixture-c4-rel-a`'s rows, and clean because this release emitted
its own events for them. There is deliberately no AI-003 row and no AI-006 row —
this release emitted both ids, so each is a limb-(c) finding here.

AI-005 is one column short, so C5 rejects it and limbs (a) and (b), which read the
row's `status` by position, exclude it. Limb (c) reads only the id cell, which sits
first at any arity, so the row still puts AI-005 on this ledger and this release's
own AI-005 event must raise no limb-(c) finding. Paired log: `log-c4-collision.md`.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:02Z | 5 | #2 | deferred-edit | hub | near-miss, terminal status matched by its own terminal event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision.md | superseded | 2026-08-24T10:00:03Z | superseded in fixture |
| AI-002 | 2026-08-24T10:00:04Z | 5 | #2 | reminder | hub | near-miss, own opened event present | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision.md | open | — | — |
| AI-005 | 2026-08-24T10:00:06Z | 5 | #2 | reminder | hub | C5-rejected row, one column short; its id is still on this ledger | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision.md | open | — |
