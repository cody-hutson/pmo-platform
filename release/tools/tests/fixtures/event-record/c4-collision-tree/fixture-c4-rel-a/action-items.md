# Action-Item Ledger — C4 collision tree, `fixture-c4-rel-a` (the VICTIM)

The directory name is the release key. AI-001 (limb b) and AI-002 (limb a) are
satisfied only by `fixture-c4-rel-b`'s events, so only a bare-id join reads them
clean. AI-003 is clean, and is the ledger row that hides `fixture-c4-rel-b`'s
limb-(c) finding from a bare-id join. Paired log: `log-c4-collision.md`.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:00Z | 5 | #1 | deferred-edit | hub | collision victim, terminal status without its own terminal event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision.md | superseded | 2026-08-24T10:00:03Z | superseded in fixture |
| AI-002 | 2026-08-24T10:00:02Z | 5 | #1 | reminder | hub | collision victim, no event in its own release | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision.md | open | — | — |
| AI-003 | 2026-08-24T10:00:01Z | 5 | #1 | reminder | hub | own event present; the ledger-side donor of the limb-c collision | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-c4-collision.md | open | — | — |
