<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N token below is synthetic
     release-plan test data, not a reference to a real work item. -->
# vTEST Release Plan — verify-release-plan.sh fixture (the class column is a reader annotation)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`, arm V6180-AC5. This
> table carries a `Predicate class` column; its twin `verify-plan-class-inert-control.md`
> carries the identical rows without it. Every row must receive the SAME family and
> verdict in both files: a row is routed away from the executor only by a declaration
> IN its method cell, in the one declared-deferred form, bracket spelling (AC-1) or
> phrase spelling (AC-2); a class cell routes nothing (AC-3) and never displaces a
> runnable probe (AC-4).

## Verification Plan

**#951 — the class column is a reader annotation**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | behavioral/domain | [DEFERRED — judge-rubric read of the rendered decision at Stage 8] | named SKIP through the in-method declared-deferred form, bracket spelling |
| AC-2 | behavioral/domain | declared, verification deferred to Stage 8 named read of the decision record | named SKIP through the in-method declared-deferred form, phrase spelling |
| AC-3 | behavioral/domain | judge-rubric read of the rendered decision | not PASS — the class cell is not a routing input |
| AC-4 | runtime | `grep -c 'class-inert-token' release/tools/tests/fixtures/verify-plan-class-inert.md` at least 1 | executes — a class never displaces a runnable probe |
