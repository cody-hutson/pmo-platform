# Hub session state — M4 tree fixture, the NOT-YET-ASSESSABLE slug

**The false positive the lifecycle term exists to remove**, and the reason the screen
has four buckets rather than two.

This slug has rendered decisions and has no `action-items.md` — which is bit-for-bit
what the FLAGGED slug looks like on those two terms alone. The difference is that it
carries **no row at stage 13**: it has not reached close, so it has not yet had the
opportunity to record a commitment. A screen predicated on
`(>=1 decision row) AND (no ledger)` alone reports this healthy in-flight release as
a finding, and would go on doing so at every close, forever — which is exactly how a
report gets ignored.

The residue of a classification gets its OWN named state rather than being folded
into whichever verdict the `else` reaches. `not-yet-assessable` is that state, and
the arms assert this slug is in it AND absent from `flagged`, because "absent from
flagged" alone is satisfied by a screen that lost the slug entirely.

Same non-empty-directory rationale as its sibling, and deliberately carries no
`AI-<digits>` token.
