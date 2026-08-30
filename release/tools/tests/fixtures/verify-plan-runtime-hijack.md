<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N token below is synthetic
     release-plan test data, not a reference to a real work item. -->
# vTEST Release Plan — verify-release-plan.sh fixture (runtime-suite hijack + floor)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`.
>
> TWO PROPERTIES, one table.
>
> **The hijack.** `classify_family` used to match `*exercise*` / `*runtime*suite*`
> BEFORE the executable arm, so a bash `case` took the runtime route first. AC-1
> and AC-2 below carry the SAME `grep -c` command; AC-2 merely says "Exercise the
> register" in front of it. Before the fix AC-1 earned a real PASS and AC-2 got a
> fabricated one from a family that executed nothing. **AC-1 and AC-2 must now
> agree — same family, same verdict.** Measured over the whole indexed corpus,
> 2 of 2 runtime-suite rows were hijacked executable assertions like this one.
>
> **The floor.** AC-3 carries `exercise` and no fail-word and no executable
> probe: it must NOT be PASS. AC-4 and AC-5 declare a test-run subtype, which is
> the surviving declaration route, and must be SKIP and FAIL respectively.
> `handle_runtime_suite` executes nothing, so PASS is unreachable by
> construction — VERDICT_PASS does not appear in its body.

## Verification Plan

**#721 — runtime-suite hijack and verdict floor**

| AC | Verification Method | Expected Result |
|---|---|---|
| AC-1 | `grep -c 'hijack-token' release/tools/tests/fixtures/verify-plan-runtime-hijack.md` ≥ 1 | ≥1 — earned by execution |
| AC-2 | Exercise the register, then dispatch the runtime suite for it: `grep -c 'hijack-token' release/tools/tests/fixtures/verify-plan-runtime-hijack.md` ≥ 1 | ≥1 — must equal AC-1 exactly |
| AC-3 | Exercise the suite for this deliverable | must NOT be PASS |
| AC-4 | the declared outcome for this deliverable is suite-skip | honest no-op |
| AC-5 | the declared outcome for this deliverable is suite-fail | a declared failure still fails |
