# fcm-verbof-control — the specificity twin of fcm-verbof-trap

Same two paths, same two intents, annotations deleted. The ONLY variable across
the pair is annotation prose.

Without this twin the trap arm proves nothing: a parser that classified both
rows correctly for the wrong reason, or one that dropped row 1 entirely, would
also produce a passing FCM-1. The assertion is that the FCM-1 record — id,
verdict and observed text — is IDENTICAL across the pair, while the coverage
record differs by exactly one field (`prose_led`), which is the disclosure that
one row in the trap was read from a weaker signal.

Expected against `fcm-diff-present.tsv`: `FCM-1 = declared-add-delivered:core/does-not-exist.md`,
PASS, with `obligations=1 excluded=0 prose_led=0`.

## File Change Matrix

```
release/tools/verify-release-plan.sh  EDIT
core/does-not-exist.md  ADD
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
