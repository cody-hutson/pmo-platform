# Hub session state — M4 tree fixture, the NO-DECISION-ROW slug

The explicit zero-state, and the fourth bucket is not decoration.

This slug has a hub-state directory and **no decision-class row anywhere in the log**
— `log-m4.md` carries exactly one row for it and that row is `gate-outcome`, not
`decision`. Nothing was ever rendered here that a commitment sweep could have found,
so the absence of a ledger says nothing at all. Reporting it as flagged would be
wrong; dropping it from the partition would be worse, because then the buckets would
not sum to the scanned denominator and the screen could lose a directory without
saying so.

An absent note and a clean population are the same output, which is the defect family
this whole release exists to close. Every scanned directory therefore lands in a named
bucket, and the screen prints whether the four buckets sum to the denominator it
scanned.

Same non-empty-directory rationale as its siblings, and deliberately carries no
`AI-<digits>` token.
