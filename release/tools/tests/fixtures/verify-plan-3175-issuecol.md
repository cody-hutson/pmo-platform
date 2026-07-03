# vTEST Release Plan — verify-release-plan.sh fixture (Issue-column shape)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` (sub-task #3175).
> Exercises the CANONICAL Issue-keyed table shape — a single table with an
> explicit `Issue` column supplying the per-issue grouping (the m-5 alternate to
> the enclosing-`#N`-subsection-header form). Fast local greps only.

## Verification Plan

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #801 | AC-1 | `grep -c 'Issue-column shape' release/tools/tests/fixtures/verify-plan-3175-issuecol.md` ≥ 1 | ≥1 |
| #801 | AC-2 | `test -f release/tools/verify-release-plan.sh` | file exists |
| #802 | AC-1 | `grep -c 'never-appears-XYZ' release/tools/tests/fixtures/verify-plan-3175-issuecol.md` ≥ 3 | ≥3 (intentional FAIL) |
