<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — an empty Method cell inside an INDEXED table

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> The same doctrine one row down. This table indexes cleanly, and one of its rows
> declares a check while naming no method to run it. That is an unreadable
> declaration, not an absence, so it is a NAMED ERROR rather than a silent drop.
> The first row is the in-fixture control: it grades normally.

## Verification Plan

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #821 | AC-1 | `test -f release/tools/verify-release-plan.sh` | the executor file exists |
| #821 | AC-2 |  | this row declares a check and names no method |
