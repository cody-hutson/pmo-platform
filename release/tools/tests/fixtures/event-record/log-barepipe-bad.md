# Pipeline Event Log — BARE-PIPE fixture

A payload carrying an UNESCAPED `|`. § 4.3a reserves the bare pipe as the column
delimiter and requires `\|` inside a field, so this row splits into more than 10
columns and every field after the payload's pipe is shifted.

This is the case `log-escapedpipe-clean.md` must be distinguished FROM. The two
fixtures are a matched pair: one carries pipes and is clean, the other carries
pipes and is broken, and a validator that cannot tell them apart is exactly the
probe that produced this card's own wrong number.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T12:30:00Z | fixture-barepipe-bad | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | resolved | triggers:[T1 | T2] |
