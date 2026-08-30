<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — `Method class` header dialect

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> One of the two unrecognised header spellings that account for the ENTIRE
> droppable population in the plan corpus: `Method class` (4 plans) and `Command`
> (3 plans). Before the widening every row under this header was dropped with no
> record and no diagnostic — the roll-up reported all-PASS over what survived.

## Verification Plan

| Issue | Method class | Expected result |
|---|---|---|
| #814 | `test -f release/tools/verify-release-plan.sh` | the executor file exists |
| #815 | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-3175-canonical.md` >= 1 | at least one Verification Plan heading |
