<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — the CIAC authoring lint (control twin: every entry lints clean or declared)

> Arm V6236-AC1, the control: `--ciac-lint` reads every entry below as gradable by its sole runner, or as declared with the evidence surface its guarantee lives in, so it flags none and exits 0. The declared entries name a path, an arm label, and a criterion for each spanned issue in each of the three reference forms.

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#973 × #974 on `fixture`):** a count naming its input. *Method:* `grep -c -F "CIAC-1" release/tools/tests/fixtures/verify-plan-ciac-lint-control.md` at least 1.
- [ ] **CIAC-2 (#973 × #974 on `fixture`):** a file-state probe, whose exit status is its claim. *Method:* `test -f release/tools/tests/fixtures/verify-plan-ciac-lint-control.md`.
- [ ] **CIAC-3 (#973 × #974 on `fixture`):** a match whose exit status is its claim. *Method:* `grep -q -F "CIAC-3" release/tools/tests/fixtures/verify-plan-ciac-lint-control.md`.
- [ ] **CIAC-4 (#973 × #974 on `fixture`):** an emphasised null, over the flag-set twin, which never carries the token. *Method:* `grep -c -F "absent-token-4" release/tools/tests/fixtures/verify-plan-ciac-lint.md` expect **0**.
- [ ] **CIAC-5 (#973 × #974 on `fixture`):** a scope assertion, graded natively. *Method:* `git diff --name-only origin/main...HEAD -- release/tools/tests/fixtures/verify-plan-ciac-lint-control.md` at most 1.
- [ ] **CIAC-6 (#973 × #974 on `fixture`):** a predicate no command can grade, declared at a path. *Method:* declared, verification deferred to the CI run of the suite arm that asserts it, in `release/tools/tests/test_verify_release_plan.sh`.
- [ ] **CIAC-7 (#973 × #974 on `fixture`):** declared at an arm label. *Method:* declared, verification deferred to arm V6236-AC1, which the suite's CI job runs.
- [ ] **CIAC-8 (#973 × #974 on `fixture`):** declared at a criterion for each spanned issue. *Method:* declared, verification deferred to #973 AC-1 and plan #974 AC-2.
- [ ] **CIAC-9 (#973 × #974 on `fixture`):** declared at a design criterion and an issue criterion. *Method:* declared, verification deferred to design #973 INT-1 and #974 AC-3.
