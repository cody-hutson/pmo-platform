<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — no-AC CONTROL (the AC column restored)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> The control twin of `verify-plan-no-ac.md`. Structurally identical, with the
> same two Method cells byte-for-byte; the ONLY difference is the `AC` column.
> Without this twin a green run on the trap would prove nothing — an all-PASS
> result is evidence only if the same shape without the trigger also passes.

## Verification Plan

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #811 | AC-1 | `test -f release/tools/verify-release-plan.sh` | the executor file exists |
| #812 | AC-2 | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-3175-canonical.md` >= 1 | at least one Verification Plan heading |
