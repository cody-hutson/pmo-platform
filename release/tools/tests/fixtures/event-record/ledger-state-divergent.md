# Action-Item Ledger — STATE-DIVERGENT fixture

**The single most important fixture in this set.**

Every row is structurally perfect: 13 fields, `status` inside the § 2.3 enum,
`resolved_at` and `resolution` populated. Every id joins 1:1 against
`log-clean.md` — AI-001 and AI-002 both have events there, and no id exists on
one surface and not the other. **A presence predicate passes this fixture.**

And the record is stale. AI-002 carries the terminal status `done` while the only
word the log has for it is `action-item-opened`: the terminal transition was
never emitted. The card that produced this validator proposed exactly that
presence predicate — "a reconciliation reports 1:1 across the full population" —
and it passed 13 of 13 on the live data while 12 of those 13 rows were in this
state. A gate that passes on stale data is worse than one that fails, because
nothing prompts anyone to look.

C4 therefore asserts an id join PLUS terminal-state agreement, and this fixture
is what proves the second limb is live rather than decorative.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-24T10:00:00Z | 5 | #1 | deferred-edit | hub | fixture action item, genuinely resolved | event | after fixture merge | file:log-clean.md | done | 2026-08-24T10:00:01Z | resolved in fixture |
| AI-002 | 2026-08-24T10:00:02Z | 5 | #1 | reminder | hub | fixture action item, marked done with no terminal event | event | after fixture merge | file:log-clean.md | done | 2026-08-24T10:00:09Z | claimed resolved; the log never heard about it |
