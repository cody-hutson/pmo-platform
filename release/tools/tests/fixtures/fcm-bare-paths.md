# fcm-bare-paths — intent-undeclared arm for the fcm-delivery family

The dominant historical shape: a fenced block of bare repository paths carrying no
intent verb at all. 962 of the corpus's 2,047 declaration rows are bare, so this is
not an edge case.

A marker-less path resolves to `unknown`, NEVER to `edit` — which is the deliberate
divergence from the shipped `bundle-issues-parser.py` default. Defaulting here would
convert "intent was never declared" into "no ADDs were declared, therefore no
violations", verbatim the vacuity this family exists to close.

Expected: `SKIP — fcm-rows-uninterpreted:3`, exit 0. Not PASS, and not silence.

## File Change Matrix

```
core/does-not-exist.md
release/tools/verify-release-plan.sh
release/tools/tests/test_verify_release_plan.sh
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |
