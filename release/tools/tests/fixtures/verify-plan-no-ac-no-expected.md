<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — TWO empty interior fields (no AC and no Expected)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> Six indexed blocks in the plan corpus carry no `Expected` column and five lack
> BOTH. This is the shape that falsifies the cheap fix a later editor will reach
> for — reordering the record so the nullable field sits last. There is no single
> last position that is safe, because `ac` and `expected` can be empty in the
> same record, so only a non-whitespace delimiter fixes the class.

## Verification Plan

| Issue | Verification Method |
|---|---|
| #813 | `test -f release/tools/verify-release-plan.sh` |
