# Action-Item Ledger — ARITY-BAD fixture

Rows with the wrong field count (11 and 15 against the required 13), plus one
well-formed row carrying an off-enum `status`.

**C5 is a PRECONDITION of C4, not an extension.** `status` is column 11, read by
position. On a field-shifted row that read returns some other column entirely, so
a C4 verdict computed on it would be meaningless — not wrong-but-close, meaning-
less. C5-failing rows are therefore reported AND excluded from C4's denominator,
with the exclusion printed rather than silently applied.

The off-enum row is separate from the arity rows on purpose: it is parseable, so
it stays in C4's denominator and only trips the enum limb.

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-010 | 2026-08-24T14:00:00Z | 5 | #1 | reminder | hub | eleven fields, three columns short | event | after merge | open |
| AI-011 | 2026-08-24T14:00:01Z | 5 | #1 | reminder | hub | fifteen fields, two columns long | event | after merge | file:x | open | — | — | extra | extra2 |
| AI-012 | 2026-08-24T14:00:02Z | 5 | #1 | reminder | hub | parseable row carrying an off-enum status | event | after merge | file:x | archived | — | — |
