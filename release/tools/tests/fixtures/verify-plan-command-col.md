<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — `Command` header dialect

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> The second unrecognised spelling. `command` is matched by FULL-CELL EQUALITY,
> never by containment: it is a short common English word, and containment on it
> is the false-positive risk that would swallow tables making no verification
> claim. The two long forms take containment for the opposite reason — see the
> equality-regression guard in `verify-plan-longform-method.md`.

## Verification Plan

**#816 — the Command dialect, grouped by an enclosing subsection header**

| # | Command | Expected |
|---|---|---|
| 1 | `test -f release/tools/verify-release-plan.sh` | the executor file exists |
| 2 | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-3175-canonical.md` >= 1 | at least one Verification Plan heading |
