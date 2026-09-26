<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — the CIAC authoring lint (regression: shapes a shape-only lint read clean and the grader misgrades)

> Arm V6236-AC1, the regression fixture: the four cross-issue criterion shapes the Stage-5 review found a shape-only lint would read clean while the grader applies a different predicate. Each is one count-mode command naming its input, one span, no shell syntax. The grader reads no comparator in CIAC-1, CIAC-3 and CIAC-4, so it grades the exit status: a zero that holds reads FAIL, and a count that misses its claim reads PASS. The lint derives its clean reading from the grader's own readers, so it flags those three, and reads CIAC-2 clean because the grader reads its emphasised comparator. Every probe reads the flag-set twin, which carries none of these tokens but CIAC-4's.

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#975 × #976 on `fixture`):** a zero stated with an arrow. *Method:* `grep -c -F "lone-producer-1" release/tools/tests/fixtures/verify-plan-ciac-lint.md` → 0, the enumeration present.
- [ ] **CIAC-2 (#975 × #976 on `fixture`):** a zero stated with an emphasised comparator. *Method:* `grep -c -F "echo-pipe-2" release/tools/tests/fixtures/verify-plan-ciac-lint.md` → expect **0** on the merged PR.
- [ ] **CIAC-3 (#975 × #976 on `fixture`):** a zero stated with a participle. *Method:* `grep -c -F "fallback-3" release/tools/tests/fixtures/verify-plan-ciac-lint.md` expected **0** · control: the same instrument for another token must return **non-zero**.
- [ ] **CIAC-4 (#975 × #976 on `fixture`):** a bound stated in words. *Method:* `grep -c -F "a prose procedure" release/tools/tests/fixtures/verify-plan-ciac-lint.md` returns strictly more than the pre-release count of 8.
