---
milestone: prov-fixture-conformant
release_class: novel
---

# prov-conformant — FIXTURE (provenance-survival)

Offline fixture for the `provenance-survival` family: cases **P1** (conformant
plan, no comment supplied), **P3** (delta PASS when paired with
`prov-comment-with-label.txt`) and **P7-X** (the exemption form is accepted).

It is also the substitution BASE for the source-value arms (P6 / P9 / bad-date):
those variants differ from this file in exactly one field, so the suite rewrites
the `source:` value on a staged copy rather than committing a near-identical file
per value. The structural shapes get their own fixtures; only one-field value
variants are substituted, and the substitution is visible in the suite.

The File Change Matrix below declares a READ row and no ADDs on purpose. It
keeps `fcm-delivery` at a named `fcm-no-unconditional-adds` SKIP so this
fixture's process exit code is driven by the provenance records alone — without
it every provenance arm would be graded through an unrelated family's ERROR.

### Domain Practice Provenance

domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-24, domain: governance }

## File Change Matrix

```
#### Read-only inputs
release/tools/verify-release-plan.sh                                        READ
```
