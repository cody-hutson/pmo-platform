# Pipeline Event Log — CLEAN fixture

Every row here is conformant: 10 fields under the canonical `" | "` delimiter,
declared enums, well-formed timestamps. This is the arm that must PASS.

AI-001 is fully reconciled (opened AND resolved). AI-002 is opened only — it is
the id `ledger-state-divergent.md` marks `done`, which is how C4's currency limb
is made to fire while the id join stays 1:1.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T10:00:00Z | fixture-clean-release | 5 | decision | action-item-opened | hub | AI-001 | CHEAP | resolved | ms:#1; note:opened-for-fixture |
| 2026-08-24T10:00:01Z | fixture-clean-release | 13 | decision | action-item-resolved | hub | AI-001 | CHEAP | resolved | ms:#1; note:resolved-for-fixture |
| 2026-08-24T10:00:02Z | fixture-clean-release | 5 | decision | action-item-opened | hub | AI-002 | CHEAP | resolved | ms:#1; note:opened-never-closed |
| 2026-08-24T10:00:03Z | fixture-clean-release | 5 | decision | decision-superseded | hub | sub-task:#1 | CHEAP | superseded | superseded:D-7; by:D-37; reason:band-expansion-retired |
| 2026-08-24T10:00:04Z | fixture-clean-release | 9 | gate-outcome | plan-review-go | operator | milestone:#1 | EXPENSIVE | resolved | verdict:GO |
