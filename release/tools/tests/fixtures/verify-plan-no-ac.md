<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — no-AC column (the COLLAPSE population, SENSITIVITY arm)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> THE POPULATION THE OLD FIXTURES DID NOT CONTAIN. All five pre-existing
> verify-plan fixtures carry a literal `AC` column — 10 of 10 indexed blocks —
> so the entire fixture corpus was drawn from the population that is IMMUNE to
> the empty-field collapse. That is why 146 green assertions never saw it.
>
> This header carries no `AC` cell, so the parser emits an EMPTY second field.
> Under a whitespace delimiter that field collapses, every later field shifts one
> position left, and the consumer reads the *Expected result* cell as the Method
> — grading the row on the wrong cell while the tally stays correct.
>
> Its control twin is `verify-plan-no-ac-control.md`, whose ONLY difference is
> that it carries the AC column. The two Method cells are byte-identical, so the
> arms compare directly.

## Verification Plan

| Issue | Verification Method | Expected Result |
|---|---|---|
| #811 | `test -f release/tools/verify-release-plan.sh` | the executor file exists |
| #812 | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-3175-canonical.md` >= 1 | at least one Verification Plan heading |
