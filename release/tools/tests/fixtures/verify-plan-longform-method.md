<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — THE EQUALITY-REGRESSION GUARD

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> This header indexes TODAY, and it indexes only because the method-column match
> CONTAINS rather than EQUALS. Tightening it to full-cell equality was proposed as
> defence-in-depth and REJECTED on measurement: equality gains the same 59 rows
> the widening gains but silently de-indexes 20 rows that work today, across two
> live shipped plans carrying `Verification method (FMF-1-scoped)` and
> `Verification method class`. Adopting it would have shipped a fresh instance of
> the very defect this change exists to close.
>
> This fixture is that measurement, made executable. Its seeded-failure twin
> switches the clause to equality; this table must then stop indexing.

## Verification Plan

| AC | Assertion | Verification method (FMF-1-scoped) | SI clause |
|---|---|---|---|
| AC-1 | the long-form header still resolves a method column | `test -f release/tools/verify-release-plan.sh` | SI-1 |
| AC-2 | containment is load-bearing, not stylistic | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-3175-canonical.md` >= 1 | SI-2 |
