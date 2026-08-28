# Pipeline Event Log — ESCAPED-PIPE fixture (the D-1 regression guard)

**This file exists to fail anyone who re-implements a bare-pipe count.**

Schema § 4.3a ADMITS `\|` inside a payload for multi-value fields. A row carrying
escaped pipes therefore has MORE than 11 bare pipes and is still perfectly
conformant: it splits to exactly 10 fields under the canonical `" | "`
delimiter, and once `\|` is stripped exactly 11 structural pipes remain.

The card that produced this validator claimed 20 malformed rows on the live log
and named their line numbers. All 20 were conformant. The probe had counted bare
pipes — the exact defect the card's own comment names. Every row below MUST
PASS; a validator that flags any of them is wrong, and this fixture is how that
mistake is prevented from shipping twice.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T11:00:00Z | fixture-escapedpipe | 5 | decision | cascade-sweep-block | hub | sub-task:#1 | CHEAP | resolved | triggers:[T1\|T2\|T3]; files_swept:4; verdict:UPDATE |
| 2026-08-24T11:00:01Z | fixture-escapedpipe | 5 | decision | scope-lock | hub | milestone:#1 | CHEAP | resolved | members:[#1\|#2\|#3\|#4\|#5\|#6\|#7]; pts:24 |
| 2026-08-24T11:00:02Z | fixture-escapedpipe | 7 | test-run | suite-pass | spoke:#1 | #1 | CHEAP | resolved | suite:hook-suite; env:[a\|b]; pass:268; fail:0 |
