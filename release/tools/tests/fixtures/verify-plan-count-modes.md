<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser's job is to group checks by their #N
     issue headers), not references to real work items. -->
# vTEST Release Plan — matcher count-mode fidelity fixture

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G8.
>
> One row per matcher OUTPUT SHAPE. The defect being pinned is that a single
> count expression — sum the last colon-separated field of every line — is
> correct for exactly one of these shapes and silently wrong for the rest:
>
>   * `grep -c` prints `<n>` or `<path>:<n>`, so the last colon field IS a count.
>   * `grep -n` prints `<line>:<text>`, so the last colon field is TEXT, which
>     numeric coercion turns into 0 — a row with real hits reporting zero.
>   * a plain match prints the line, with the same result.
>
> The two count-mode rows are the CONTROL: they returned the right answer before
> the fix and must still return it after, so a green match-mode row is evidence
> of a repair rather than of a counter that now says whatever is needed.
>
> The last row is the FALSE-PASS arm and it is the reason this fixture exists.
> sentinel-beta sentinel-beta sentinel-gamma sentinel-gamma sentinel-gamma

## Verification Plan

**#921 — count mode (the shape that always worked)**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `grep -c 'sentinel-beta' release/tools/tests/fixtures/verify-plan-count-modes.md` ≥ 2 | ≥2 |
| AC-2 | file-path+state | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-count-modes.md release/tools/tests/fixtures/verify-plan-escaped-pipe.md` ≥ 2 | ≥2 across two files |

**#922 — match mode (the shape that reported a false zero)**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-3 | file-path+state | `grep -n 'sentinel-beta' release/tools/tests/fixtures/verify-plan-count-modes.md` ≥ 2 | ≥2 |
| AC-4 | file-path+state | `grep 'sentinel-gamma' release/tools/tests/fixtures/verify-plan-count-modes.md` ≥ 2 | ≥2 |

**#923 — a matcher that could not run is not a zero**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-5 | file-path+state | `grep -c 'sentinel-delta' release/tools/tests/fixtures/no-such-fixture-zzz.md` expect 0 | ERROR, never PASS — grep exits 2 on an unreadable path, and an unread count is not a zero |
