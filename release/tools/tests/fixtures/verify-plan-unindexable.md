<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — an unindexable verification table (ERROR, never silence)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> This header DECLARES verification content — it names `AC` and `Expected
> result` — and yet resolves no method column, so every row beneath it is
> dropped. The tool doctrine is explicit that this must not read as "nothing
> declared, therefore no violations": the drop is reported as ONE ERROR per
> table block, carrying the header verbatim and the number of rows suppressed.
>
> Per block, not per row: the operator needs "this table suppressed N rows", not
> N identical errors.
>
> Its false-positive control is `verify-plan-nonverif-table.md`.

## Verification Plan

| Issue | AC | Expected result |
|---|---|---|
| #817 | AC-1 | the row cannot be graded, and says so |
| #818 | AC-2 | the second suppressed row |
