# fcm-deviation-recorded — AC2 arm for the fcm-delivery family

A declared, unconditional ADD that the diff set does not deliver, WITH the explicit
`NOT DELIVERED` Deviation-Log row that AC2 requires. The row is what converts the
FAIL into a PASS — "the check passes only with that entry present" — so this fixture
and `fcm-declared-absent.md` differ in exactly one artifact.

Expected: `PASS — deviation-recorded:core/does-not-exist.md`, exit 0.

## File Change Matrix

```
core/does-not-exist.md  ADD
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| 1 | **NOT DELIVERED — `core/does-not-exist.md`** (declared ADD in the File Change Matrix) | scope | dropped — superseded during Engineering; recorded rather than silently omitted |
