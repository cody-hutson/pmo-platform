# Action-Item Ledger — CLEAN fixture

13 fields per row, `status` inside the § 2.3 enum, and — the part that matters —
STATE AGREEMENT with `log-clean.md`: AI-001 is `done` here and the log carries an
`action-item-resolved` event for it.

AI-002 appears as `open`, and that is the interesting row. The log has only an
`action-item-opened` for it — which is CORRECT, because a non-terminal status
owes no terminal event. `ledger-state-divergent.md` carries the same id as `done`
against the same log, and that is what must fail. The two ledgers differ in
exactly one cell, so the arm they discriminate is unambiguous: not presence, not
arity, not the enum — **currency**.

Both directions of the id join are clean here: no id sits on the ledger without
an event, and no id has events without a ledger row.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:00Z | 5 | #1 | deferred-edit | hub | fixture action item, resolved | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-clean.md | done | 2026-08-24T10:00:01Z | resolved in fixture |
| AI-002 | 2026-08-24T10:00:02Z | 5 | #1 | reminder | hub | fixture action item, still open — owes no terminal event | event | after fixture merge | file:release/tools/tests/fixtures/event-record/log-clean.md | open | — | — |
