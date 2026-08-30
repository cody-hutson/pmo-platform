<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column),
     not references to real work items. -->
# vTEST Release Plan — verify-release-plan.sh fixture (header-trap CONTROL)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`.
>
> THE CONTROL TWIN of `verify-plan-header-trap.md`. Identical table shape and
> identical row count; the only difference is that no data cell carries the
> header vocabulary (`predicate`, `expected`, `verification method`).
>
> Without this twin the trap arm proves nothing: a parser that dropped every row
> would report a stable count on the trap file alone. The assertion is that the
> two files report the SAME record count — and under a mutation that reverts the
> positional anchor, only the trap file loses rows, so the pair separates.

## Verification Plan

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #711 | AC-1 | `grep -c 'header-trap-alpha' release/tools/tests/fixtures/verify-plan-header-trap-control.md` ≥ 1 | ≥1 |
| #711 | AC-2 | this cell states a rule and the count it wants inline: `grep -c 'header-trap-beta' release/tools/tests/fixtures/verify-plan-header-trap-control.md` ≥ 1 | ≥1 |
| #711 | AC-3 | this cell names a check in its own text: `grep -c 'header-trap-gamma' release/tools/tests/fixtures/verify-plan-header-trap-control.md` ≥ 1 | ≥1 |
| #711 | AC-4 | `test -f release/tools/verify-release-plan.sh` | file exists |
