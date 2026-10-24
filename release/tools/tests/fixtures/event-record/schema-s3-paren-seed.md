# Event-log schema — § 3 COLUMN-3 PARENTHETICAL-SEED fixture

A synthetic schema whose only job is to spring, in one table, every shape the
column-3 parenthetical rule must survive, none of which the live schema may
carry. The `decision` cell holds a parenthetical that contains another, with a
backticked file name in the OUTER span; a backticked token interrupted by a
one-character parenthetical, the glue probe; a second, separate parenthetical;
and legitimate subtypes before the first span, between the two and after the
second. The `re-review` cell carries an unclosed parenthesis ahead of its
dotted subtype. The validator's parser must register exactly the legitimate
subtypes, each captured whole. Graded with `log-s3-paren-seed.md`.

## 3. Event-Type Enum — fixture

| `event_type` | Description | Allowed `event_subtype` values |
|---|---|---|
| `decision` | nested, glued and separate parentheticals, with legitimate subtypes before, between and after them | `scope-lock` (the outer span cites (an inner span) `zzz-cited-file.md`) / `delegation` (a second span) / `d-class` / `zzz-glue(x)seed` |
| `re-review` | an unclosed parenthesis ahead of a dotted subtype | `phase-a0-row` / (an unclosed parenthesis / `phase-0.5-row` |

## 4. End of fixture
