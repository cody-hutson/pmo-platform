<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data, not references to real work items. -->
# vTEST Release Plan — verify-release-plan.sh fixture (not this runner's job, versus could not evaluate)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`, suite group G19, arms
> V6854-AC1 to V6854-AC4. A row this executor is not the runner for grades a named SKIP
> whether the plan declares it (AC-1, AC-2) or its method simply carries no command the
> executor runs (AC-3 to AC-5, AC-18 to AC-20, CIAC-1). Prose that merely opens with a
> verb is a named read, never a command (AC-18 to AC-20). A row whose probe input cannot
> be read, whose method cell is empty, whose command names no operand, or whose command
> states no comparator where its exit status is not the claim is ERROR (AC-7 to AC-13,
> AC-16, AC-22, CIAC-2); the controls beside them PASS (AC-6, AC-14, AC-15, AC-17,
> AC-21). AC-0 carries no issue value, so the markdown block shows it under a (plan)
> header. The roll-up line keeps what the run did not grade apart from what it could
> not evaluate. AC-14 reads this file's own line count, at least 10.

## Verification Plan

| AC | Verification method | Expected result |
|---|---|---|
| AC-0 | `test -f release/tools/tests/fixtures/verify-plan-not-my-runner.md` | an unattributed row: no Issue column and no issue header above it |

**#990 — not this runner's job, versus could not evaluate**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | [DEFERRED — the rendered decision is graded by the Stage 8 reader] | named SKIP, declared |
| AC-2 | declared, verification deferred to the Stage 8 named read of the decision record | named SKIP, declared |
| AC-3 | judge-rubric read of the rendered decision against its criterion | named SKIP, no command in method |
| AC-4 | Read Rule 7 in `core/specs/label-taxonomy.md` and confirm it names the kind label | named SKIP, no command in method |
| AC-5 | Run the checker against a fixture holding one live Removed entry and assert the output names it | named SKIP, no command in method |
| AC-6 | `head -n 1 release/tools/tests/fixtures/verify-plan-not-my-runner.md` at least 1 | executed: a runnable probe no keyword claims |
| AC-7 | `grep -c 'x' release/tools/tests/fixtures/verify-plan-no-such-fixture.md` expect 0 | ERROR: the probe input could not be read |
| AC-8 |  | ERROR: an empty method cell |
| AC-9 | `head -n 1 release/tools/tests/fixtures/verify-plan-no-such-fixture.md` expect 0 | ERROR: head exits 1 on a file it cannot read, which is not a zero |
| AC-10 | `grep -c` expect 0 | ERROR: grep given no pattern names no operand |
| AC-11 | `cat release/tools/tests/fixtures/verify-plan-not-my-runner.md` — expect `warn` | ERROR: no comparator, and exit 0 of cat is not the claim |
| AC-12 | `ls release/tools/tests/fixtures/` lists `verify-plan-no-such-fixture.md` | ERROR: no comparator, and an ls listing a directory says only that it exists |
| AC-13 | `test -d` the directory `release/tools/tests/fixtures/verify-plan-no-such-dir/` | ERROR: a unary primary with no operand |
| AC-14 | `wc -l release/tools/tests/fixtures/verify-plan-not-my-runner.md` at least 10 | PASS: the count of wc is its first field, this file's line count |
| AC-15 | `ls release/tools/tests/fixtures/verify-plan-not-my-runner.md` | PASS: an ls naming a file is an existence check |
| AC-16 | `ls -1` present | ERROR: an ls naming no path |
| AC-17 | `test -f release/tools/tests/fixtures/verify-plan-not-my-runner.md` | PASS: a primary with its operand |
| AC-18 | grep the QC4-05 criterion in the gate criteria spec | named SKIP: prose that opens with a verb is a named read |
| AC-19 | test the merged decision records the chosen branch | named SKIP: the same, with no routing keyword |
| AC-20 | grep the `release/tools/verify-release-plan.sh` usage block for its family list | named SKIP: verb-initial prose beside a backticked path is still prose |
| AC-21 | `grep -F 'Verification method' release/tools/tests/fixtures/verify-plan-not-my-runner.md` | PASS: the exit 0 of grep is its claim, a line matched |
| AC-22 | `cat release/tools/tests/fixtures/verify-plan-not-my-runner.md` beside `grep -c -F 'AC-' release/tools/tests/fixtures/verify-plan-not-my-runner.md` at least 1 | ERROR: the designated command states no comparator, and exit 0 of cat is not the claim |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#990 × #991 on `fixture`):** a recorded decision with nothing to run. *Method:* confirm the recorded no-overlap decision in the Stage 4 comment.
- [ ] **CIAC-2 (#990 × #991 on `fixture`):** a reader whose exit status is not the claim, in the cross-issue handler. *Method:* `cat release/tools/tests/fixtures/verify-plan-not-my-runner.md`.
