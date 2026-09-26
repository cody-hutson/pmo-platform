# Pipeline Event Log — C4 COLLISION CONTROL fixture

Every row of `log-c4-collision.md`, unchanged, plus the two events `fixture-c4-rel-a`
owes for its own action items (AI-001 `action-item-superseded`, AI-002
`action-item-opened`). Against `c4-collision-tree/` nothing may be reported for
`fixture-c4-rel-a`; against `c4-collision-tree-control/` every pair agrees, and both
C4 lines — the ledger-row line and the limb-(c) pair line — must read 0 violation(s)
+ 0 legacy at every cutover. Keep prose in lists.

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
| 2026-08-24T10:00:08Z | fixture-c4-rel-a | 13 | decision | action-item-superseded | hub | milestone:#1 | CHEAP | superseded | ms:#1; ai:AI-001; reason:own-terminal-event |
| 2026-08-24T10:00:09Z | fixture-c4-rel-a | 5 | decision | action-item-opened | hub | AI-002 | CHEAP | resolved | ms:#1; note:own-presence-event |
