<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N token below is synthetic
     release-plan test data, not a reference to a real work item. -->
# vTEST Release Plan — verify-release-plan.sh fixture (control twin: no class column)

> Control twin of verify-plan-class-inert.md for arm V6180-AC5: the identical rows without the Predicate class column.

## Verification Plan

**#951 — the class column is a reader annotation**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | [DEFERRED — judge-rubric read of the rendered decision at Stage 8] | named SKIP through the in-method declared-deferred form, bracket spelling |
| AC-2 | declared, verification deferred to Stage 8 named read of the decision record | named SKIP through the in-method declared-deferred form, phrase spelling |
| AC-3 | judge-rubric read of the rendered decision | not PASS — the class cell is not a routing input |
| AC-4 | `grep -c 'class-inert-token' release/tools/tests/fixtures/verify-plan-class-inert.md` at least 1 | executes — a class never displaces a runnable probe |
