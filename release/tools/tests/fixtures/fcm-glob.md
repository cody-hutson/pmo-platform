# fcm-glob — glob-arm and placeholder-arm coverage for the fcm-delivery family

Globs are an ESTABLISHED authored form in this corpus — 27 glob-bearing path tokens
across 15 plans — and a path-form taxonomy derived from the one specimen that failed
carried no arm for them. Without a glob arm every one of those rows is a guaranteed
FAIL on a correctly-authored plan.

Two forms are exercised:
  - an authored glob (`release/tools/tests/fixtures/fcm-*.md`), delivered;
  - a PLACEHOLDER-bearing path (`core/ADRs/ADR-NNN-<slug>.md`), which normalizes into
    the same glob arm rather than resolving to a "longest literal ancestor directory".
    Normalization keeps the declared basename residue (`.md`) and the directory, which
    is strictly more specific than an ancestor-prefix match and is what lets the arm
    resolve the row that actually vanished in v4.03.

Expected: both rows `PASS — declared-add-delivered`, exit 0.

## File Change Matrix

| Path | Operation | Notes |
|---|---|---|
| `release/tools/tests/fixtures/fcm-*.md` | ADD | authored glob form |
| `core/ADRs/ADR-NNN-<slug>.md` | ADD | placeholder form, normalized into the glob arm |

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
