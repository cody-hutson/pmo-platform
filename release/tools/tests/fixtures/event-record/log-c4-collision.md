# Pipeline Event Log — C4 COLLISION fixture

Paired with `c4-collision-tree/`. Two releases share action-item ids, as every pair
of releases does. Each C4 limb has one finding a bare-id join HIDES and one
near-miss that differs only in owning its event (or row) in its own release:

- limb (b): `fixture-c4-rel-a` AI-001 is `superseded`; only `fixture-c4-rel-b`
  emitted the terminal event. Near-miss: `fixture-c4-rel-b` AI-001.
- limb (a): `fixture-c4-rel-a` AI-002 has no event in its own release.
  Near-miss: `fixture-c4-rel-b` AI-002.
- limb (c): `fixture-c4-rel-b` emitted AI-003 and files no AI-003 row;
  `fixture-c4-rel-a` does. Near-miss: `fixture-c4-rel-a` AI-003.
- LEGACY: the two `v0.92` rows carry a version-form release key, predate the
  self-test's MID cutover, and name two milestones, so `v0.92` is
  release-INDETERMINATE. `fixture-c4-rel-b` names two milestones too, and is a
  slug: it must NOT be reported indeterminate.
- limb (c) reads only the ledger's id cell: `fixture-c4-rel-b` emitted AI-005, and
  its ledger carries an AI-005 row that C5 rejects for arity. The row IS on the
  ledger, so C5 reports it and limb (c) must stay silent about AI-005.
- limb (c) is dated by the pair's own rows: `fixture-c4-rel-b` AI-006 has one row
  before the self-test's MID cutover and one after, and no ledger row. A pair is
  graded when ANY of its own rows is, so AI-006 is a VIOLATION at MID — dating it by
  its earliest row would read it LEGACY there.

The id sits in the subject on some rows and in the payload on others. Keep prose
in lists — any other line starting with a pipe is read as a log row.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-01T09:00:00Z | v0.92 | 5 | decision | action-item-opened | hub | milestone:#93 | CHEAP | resolved | ai:AI-004; note:legacy-version-keyed-row |
| 2026-08-01T09:00:01Z | v0.92 | 13 | decision | action-item-resolved | hub | milestone:#94 | CHEAP | resolved | ai:AI-004; note:legacy-key-names-a-second-milestone |
| 2026-08-12T10:00:00Z | fixture-c4-rel-b | 5 | decision | action-item-opened | hub | AI-006 | CHEAP | resolved | ms:#2; note:straddling-pair-row-before-mid |
| 2026-08-24T10:00:00Z | fixture-c4-rel-a | 5 | decision | action-item-opened | hub | AI-001 | CHEAP | resolved | ms:#1; note:victim-opened-only |
| 2026-08-24T10:00:01Z | fixture-c4-rel-a | 5 | decision | action-item-opened | hub | milestone:#1 | CHEAP | resolved | ms:#1; ai:AI-003; note:own-event-limb-c-near-miss |
| 2026-08-24T10:00:02Z | fixture-c4-rel-b | 5 | decision | action-item-opened | hub | AI-001 | CHEAP | resolved | ms:#2; note:donor-opened |
| 2026-08-24T10:00:03Z | fixture-c4-rel-b | 13 | decision | action-item-superseded | hub | milestone:#2 | CHEAP | superseded | ms:#2; ai:AI-001; reason:donor-terminal-event |
| 2026-08-24T10:00:04Z | fixture-c4-rel-b | 5 | decision | action-item-opened | hub | milestone:#3 | CHEAP | resolved | ms:#2; ai:AI-002; note:donor-opened |
| 2026-08-24T10:00:05Z | fixture-c4-rel-b | 5 | decision | action-item-opened | hub | AI-003 | CHEAP | resolved | ms:#2; note:no-ledger-row-in-own-release |
| 2026-08-24T10:00:06Z | fixture-c4-rel-b | 5 | decision | action-item-opened | hub | AI-005 | CHEAP | resolved | ms:#2; note:own-event-for-a-c5-rejected-row |
| 2026-08-24T10:00:07Z | fixture-c4-rel-b | 13 | decision | action-item-resolved | hub | AI-006 | CHEAP | resolved | ms:#2; note:straddling-pair-row-after-mid |
