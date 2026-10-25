# Pipeline Event Log — § 3 COLUMN-3 PARENTHETICAL-SEED fixture

Five structurally perfect rows, graded against `schema-s3-paren-seed.md`.
Rows one to three are declared: a subtype that sits between two parentheticals
in its cell, a subtype after the second of them, and a dotted subtype after an
unclosed parenthesis. Rows four and five carry the two tokens only a broken
narrowing reads: the file name the fixture schema cites inside the outer span
of a nested parenthetical, and the token an empty-string replacement would fuse
out of the glue probe. Under the correct rule exactly rows four and five are
enum violations, and the self-test arm binds both by subtype name.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T14:00:00Z | fixture-s3-paren-seed | 5 | decision | delegation | hub | release-level | CHEAP | resolved | note:subtype-between-two-parentheticals |
| 2026-08-24T14:00:01Z | fixture-s3-paren-seed | 5 | decision | d-class | hub | release-level | CHEAP | resolved | note:subtype-after-the-second-parenthetical |
| 2026-08-24T14:00:02Z | fixture-s3-paren-seed | 5 | re-review | phase-0.5-row | hub | release-level | CHEAP | resolved | note:dotted-subtype-after-an-unclosed-parenthesis |
| 2026-08-24T14:00:03Z | fixture-s3-paren-seed | 5 | decision | zzz-cited-file.md | hub | release-level | CHEAP | resolved | note:file-name-cited-inside-a-nested-parenthetical |
| 2026-08-24T14:00:04Z | fixture-s3-paren-seed | 5 | decision | zzz-glueseed | hub | release-level | CHEAP | resolved | note:token-an-empty-replacement-would-fuse |
