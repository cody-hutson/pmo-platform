# fcm-home-readme — a registered in-repo home's README ADD is recognised

A registered in-repo home is tracked as its README alone: everything else
under it is git-ignored. Two of the three homes had no entry in the
`pathof()` first-segment alternation, so a plan that declared one of those
READMEs as an ADD read the row as uninterpreted, and FCM-COVERAGE could not
reach PASS on a release that ships a home.

Both rows below must be graded `declared-add-delivered` against the seam
`fcm-diff-home-readme.tsv`, and the coverage record must read
`uninterpreted=0`. Before the enum gained the two segments, both rows were
counted as uninterpreted and coverage read SKIP.

## File Change Matrix

```
local-state/README.md   ADD
analysis/README.md      ADD
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
