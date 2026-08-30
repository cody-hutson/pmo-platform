# fcm-verbof-pathword — a path segment is not a declaration

The SCOPE half of the `verbof()` fix. Row 1 is a bare path whose own slug
contains the word `edit`; row 2 is a different path carrying a real marker.

Before the fix, `verbof()` ran on the whole uppercased row including the
declared path, so `block-skill-direct-edit.sh` classified as `edit` on the
strength of its own filename — an intent the author never declared. The parser
then reported a fully-interpreted matrix where one row had in fact declared
nothing. `isconditional()`, thirty lines below `verbof()` in the same function,
already strips the declared path before testing, and records why: the specimen
that motivated it declared a path whose slug contained `conditional`, and
matching it downgraded a FAIL to a WARN-tier SKIP. `verbof()` was simply never
given the same fix.

The declared path is now removed before classification, so row 1 resolves to
`unknown` — intent undeclared, COUNTED and REPORTED — and never to `edit`.
Row 2 is the control: an explicit marker on a different path still classifies,
so the strip narrows the input rather than disabling the classifier.

Expected against `fcm-diff-absent.tsv`: `SKIP — fcm-rows-uninterpreted:1`, exit 0,
with `declared=2 interpreted=1`.

## File Change Matrix

```
core/hooks/block-skill-direct-edit.sh
release/tools/verify-release-plan.sh  EDIT
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
