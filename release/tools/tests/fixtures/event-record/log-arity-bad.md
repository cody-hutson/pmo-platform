# Pipeline Event Log — ARITY-BAD fixture

Two rows with the wrong field count under the canonical `" | "` delimiter: one
short (9 fields, `outcome` dropped) and one long (11 fields, an extra column).

This is C1's dirty arm. A consumer reading by field POSITION on either row gets
silently shifted data — `payload` read as `outcome`, or `subject` read as
`actor` — with no error anywhere. That silence is why arity is checked at all.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T12:00:00Z | fixture-arity-bad | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | note:nine-fields-outcome-column-dropped |
| 2026-08-24T12:00:01Z | fixture-arity-bad | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | resolved | note:eleven-fields | extra-column |
