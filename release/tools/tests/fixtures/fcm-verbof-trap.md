# fcm-verbof-trap — annotation prose must not decide intent

The TRAP arm for `verbof()`. Both rows below declare their intent as the first
verb token and then say something else in annotation prose.

Before the fix, `verbof()` asked which of its words appeared ANYWHERE in the row
and resolved ties by a fixed enum order, so both rows were misread, in OPPOSITE
directions:

- row 1 was tested for `ADD` before `EDIT`, so a declared EDIT became an
  unconditional ADD obligation. The file pre-exists, so the family emitted
  `FAIL: declared-add-delivered-as-edit ... the ADD declaration was wrong` —
  blaming the author for a parser decision.
- row 2 was tested for `RENAME` before `ADD`, so a declared ADD was classified
  `rename`, counted `excluded`, and its obligation VANISHED with no record. That
  second direction is the vacuity class this tool exists to close, occurring
  inside the tool.

Its twin `fcm-verbof-control.md` carries the same two paths and the same two
intents with the annotations deleted. **The FCM-1 record must be identical
across the pair** — annotation prose cannot move a verdict. The coverage record
is NOT identical, and deliberately so: row 1 here is prose-led (its winning verb
is not its first token), so this fixture reports `prose_led=1` and the control
reports `prose_led=0`. Prose changes the DISCLOSURE, never the verdict.

Expected against `fcm-diff-present.tsv`: `FCM-1 = declared-add-delivered:core/does-not-exist.md`,
PASS, with `obligations=1 excluded=0 prose_led=1`.

## File Change Matrix

```
release/tools/verify-release-plan.sh  scheduled EDIT; it will add a new dispatch arm
core/does-not-exist.md  ADD (renamed from the earlier name)
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
