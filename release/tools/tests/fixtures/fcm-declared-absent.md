# fcm-declared-absent — MUST-FLAG arm for the fcm-delivery family

The sensitivity arm of the AC4 pair: a declared, unconditional ADD that the diff set
does not deliver, with NO Deviation-Log entry excusing it. This is the exact shape of
the v4.03 defect the family exists to catch, reduced to a synthetic minimum.

Expected: `FAIL — declared-add-not-delivered:core/does-not-exist.md`, exit 3.

## File Change Matrix

```
core/does-not-exist.md  ADD
release/tools/verify-release-plan.sh  EDIT
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
