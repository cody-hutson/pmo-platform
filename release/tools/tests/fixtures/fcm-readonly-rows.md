# fcm-readonly-rows — exclusion arm for the fcm-delivery family

Non-change classes are EXCLUDED from the obligation set, not merely un-flagged. A
`READ`-only input and a `NOT EDITED` / `NOT TOUCHED` non-scope row are declarations
that the file is deliberately not being changed; asserting them as delivery
obligations would make the gate a false-positive generator on the live corpus (the
v4.03 matrix alone carries four READ-only rows).

Two independent exclusion signals are exercised here: the block label, and the row verb.

Expected: `PASS`, exit 0, with `excluded=4` and `obligations=1` in the coverage record —
the one real ADD is delivered; the four excluded rows raise nothing.

## File Change Matrix

```
core/does-not-exist.md  ADD
```

#### Read-only inputs

```
release/tools/blast-radius.sh  READ
core/schemas/gate-criteria-spec.md  READ
```

#### Release-wide explicit non-scope

```
core/deploy/deploy.sh  NOT EDITED
release/tools/automated-closeout.sh  NOT TOUCHED
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
