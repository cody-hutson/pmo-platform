<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — THE FALSE-POSITIVE CONTROL (a table making no claim)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> Built from a REAL shipped shape: an AC-baseline table whose own prose reads
> "the baseline is a pinned measurement and carries no verdict". It shares the
> single word `Issue` with the verification schema and declares nothing else.
>
> The looser discriminator `any header keyword matched AND no method column`
> fires here — and ERROR means exit 3, so it would turn a correct, shipped,
> unchangeable plan red. Sharing one word with the schema is not a verification
> claim. This table must produce ZERO records and exit 0.

## Verification Plan

The baseline below is a pinned measurement and carries no verdict.

| Issue | AC count at plan time | Read at |
|---|---|---|
| #819 | 4 | the plan revision this row was pinned against |
| #820 | 7 | the plan revision this row was pinned against |
