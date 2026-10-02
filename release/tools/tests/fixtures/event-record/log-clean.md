# Pipeline Event Log — CLEAN fixture

Every row here is conformant: 10 fields under the canonical `" | "` delimiter,
declared enums, well-formed timestamps. This is the arm that must PASS.

AI-001 is fully reconciled (opened AND resolved). AI-002 is opened only. No C4 arm
grades this log against a ledger file any more: C4 joins on (release, id), and a
ledger's release is the name of its directory, so a ledger FILE here is release
`event-record` and pairs with none of these `fixture-clean-release` rows. C4's arms
run on `hub-state-tree/` and `c4-collision-tree*/`.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T10:00:00Z | fixture-clean-release | 5 | decision | action-item-opened | hub | AI-001 | CHEAP | resolved | ms:#1; note:opened-for-fixture |
| 2026-08-24T10:00:01Z | fixture-clean-release | 13 | decision | action-item-resolved | hub | AI-001 | CHEAP | resolved | ms:#1; note:resolved-for-fixture |
| 2026-08-24T10:00:02Z | fixture-clean-release | 5 | decision | action-item-opened | hub | AI-002 | CHEAP | resolved | ms:#1; note:opened-never-closed |
| 2026-08-24T10:00:03Z | fixture-clean-release | 5 | decision | decision-superseded | hub | sub-task:#1 | CHEAP | superseded | superseded:D-7; by:D-37; reason:band-expansion-retired |
| 2026-08-24T10:00:04Z | fixture-clean-release | 9 | gate-outcome | plan-review-go | operator | milestone:#1 | EXPENSIVE | resolved | verdict:GO |
