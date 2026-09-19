# Action-Item Ledger — M4 tree fixture, the LEDGER-BEARING slug

Authored as its own file rather than copied from `ledger-clean.md`, deliberately: a
byte copy would imply a mirror relationship that nothing enforces, and the next
editor would have to guess whether a divergence was a defect or an intent. Its
`target` column points at `log-m4.md`, which is the log this tree is paired with.

It carries the same reconciled pattern — AI-001 `done` with a matching
`action-item-resolved` event, AI-002 `open` owing no terminal event — so C4 and C5
stay clean and the engine reaches the M4 screen at exit 0. That is what lets the
screen be graded on its NOTES while the exit code stays out of it.

**This is also the only arm in the harness that enters the ledger resolver's
DIRECTORY branch.** Every other arm passes a ledger FILE, and the production sweep
passes a directory — so the branch C4 and C5 actually use in production was reached
by no self-test arm at all until this tree existed. Closing that gap is a side effect
of the M4 screen, not its purpose, and it is worth more than the screen.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:00Z | 5 | #1 | deferred-edit | hub | tree fixture action item, resolved | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-m4.md | done | 2026-08-24T10:00:01Z | resolved in fixture |
| AI-002 | 2026-08-24T10:00:02Z | 5 | #1 | reminder | hub | tree fixture action item, still open — owes no terminal event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-m4.md | open | — | — |
