# Pipeline Event Log — ENUM-BAD fixture

Rows that are structurally perfect — 10 fields, clean pipe grammar — and
semantically undeclared. C1 passes every one of them; only C2 fires.

That separation is the point. Structural validity and enum conformance are
independent failures, and the live population carries rows of exactly this shape:
undeclared subtypes written by direct edit, invisible to the writer's own
validator because the writer was never the thing that wrote them.

Rows, in order: an undeclared `event_subtype`; an undeclared `event_type`; an
off-enum `outcome`; an off-enum `reversibility`; a stage outside 1..13; a
malformed `ts_iso`; an actor outside the declared forms.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T13:00:00Z | fixture-enum-bad | 5 | decision | zzz-undeclared-subtype | hub | sub-task:#1 | CHEAP | resolved | note:subtype-not-in-section-3 |
| 2026-08-24T13:00:01Z | fixture-enum-bad | 5 | zzz-undeclared-type | anything | hub | sub-task:#1 | CHEAP | resolved | note:type-not-in-section-3 |
| 2026-08-24T13:00:02Z | fixture-enum-bad | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | finished | note:outcome-off-enum |
| 2026-08-24T13:00:03Z | fixture-enum-bad | 5 | decision | scope-lock | hub | sub-task:#1 | TRIVIAL | resolved | note:reversibility-off-enum |
| 2026-08-24T13:00:04Z | fixture-enum-bad | 14 | decision | scope-lock | hub | sub-task:#1 | CHEAP | resolved | note:stage-out-of-range |
| 2026-08-24 13:00:05 | fixture-enum-bad | 5 | decision | scope-lock | hub | sub-task:#1 | CHEAP | resolved | note:ts-not-iso-8601-utc |
| 2026-08-24T13:00:06Z | fixture-enum-bad | 5 | decision | scope-lock | robot | sub-task:#1 | CHEAP | resolved | note:actor-outside-declared-forms |
