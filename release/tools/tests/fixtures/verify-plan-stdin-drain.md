<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their #N headers), not
     references to real work items. -->
# vTEST Release Plan — a stdin-reading method cell inside each dispatch loop

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G12.
>
> AC-3 and CIAC-2 each name `grep -c -F` and no file, so the verb reads its stdin.
> Before the fix that stdin is the loop's own record stream: AC-3 counts the three
> records after it (`count=3`), CIAC-2 counts the one after it (`count=1`), and
> AC-4..AC-6 and CIAC-3 vanish with no record while the roll-up still reports six
> rows. After it, all six rows and all three CIACs emit, the two planted cells are
> a named ERROR (`stdin-reader:grep`) rather than a count over nothing, and every
> control row grades PASS. Both planted cells say `expect 0`, so a fix that only
> isolated the loop would grade them PASS on the null device -- which is why the
> named verdict is asserted separately from the row count.

## Verification Plan

**#990 — the per-issue loop**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-2 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-3 | content | `grep -c -F "AC-"` expect 0 | planted: grep reading stdin |
| AC-4 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control after the planted cell |
| AC-5 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control after the planted cell |
| AC-6 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control after the planted cell |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#990 × #991 on `fixture`):** control one. *Method:* `test -f release/tools/verify-release-plan.sh`.
- [ ] **CIAC-2 (#990 × #991 on `fixture`):** planted reader. *Method:* `grep -c -F "CIAC"` expect 0.
- [ ] **CIAC-3 (#990 × #991 on `fixture`):** control after the planted cell. *Method:* `test -f release/tools/verify-release-plan.sh`.
