# fcm-conditional — AC3 arm for the fcm-delivery family

CONDITIONAL-vs-unconditional discrimination. A conditional ADD that did not fire and
carries no record is NOT a hard failure — the gate cannot evaluate a prose condition,
and pretending otherwise would make it wrong in an unfalsifiable way. It is not silence
either: the verdict is a named SKIP and the conditional count rides in the coverage
record, so a matrix whose rows all migrate into the exempt block is visible rather than
quietly green.

Expected: `SKIP — conditional-unrecorded`, exit 0, and `conditional=1` in the coverage
record.

## File Change Matrix

#### CONDITIONAL rows

```
core/does-not-exist.md  ADD  CONDITIONAL:AC-posture-flip
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
