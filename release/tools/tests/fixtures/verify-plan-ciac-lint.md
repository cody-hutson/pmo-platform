<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — the CIAC authoring lint (flag set)

> Arm V6236-AC1: `--ciac-lint` reads each entry below as grading will, runs nothing, and flags every entry but the controls (CIAC-1, and CIAC-13, whose deferral phrase is the probe's own pattern). Each other entry carries one defect.

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#971 × #972 on `fixture`):** control, one allowlisted command naming its input. *Method:* `grep -c -F "CIAC-1" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1.
- [ ] **CIAC-2 (#971 × #972 on `fixture`):** a tool outside the verb set. *Method:* `python3 tools/check.py --self-test` exits 0.
- [ ] **CIAC-3 (#971 × #972 on `fixture`):** a prose procedure. *Method:* read both files and confirm the two lists agree.
- [ ] **CIAC-4 (#971 × #972 on `fixture`):** a methodology word ahead of the marker. *Method:* `grep -c -F "CIAC-4" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1.
- [ ] **CIAC-5 (#971 × #972 on `fixture`):** a refused tool, then an allowlisted span. *Method:* `python3 tools/sets.py` compares the sets, unlike `grep -c -F "CIAC-5" release/tools/tests/fixtures/verify-plan-ciac-lint.md` would.
- [ ] **CIAC-6 (#971 × #972 on `fixture`):** a reader naming no input. *Method:* `grep -c -F "CIAC-6"` at least 1.
- [ ] **CIAC-7 (#971 × #972 on `fixture`):** a bare verb. *Method:* `grep` the fixture for the token.
- [ ] **CIAC-8 (#971 × #972 on `fixture`):** two commands in one clause. *Method:* `grep -c -F "CIAC-8" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1, then `test -f release/tools/tests/fixtures/verify-plan-ciac-lint.md`.
- [ ] **CIAC-9 (#971 × #972 on `fixture`):** two comparator phrases that disagree. *Method:* `grep -c -F "CIAC-9" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1, expect 1.
- [ ] **CIAC-10 (#971 × #972 on the fixture):** a bullet whose procedure wraps to the next line.
  *Method:* `grep -c -F "CIAC-10" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1.
- [ ] CIAC-11 (#971 × #972 on the fixture): unbolded, so the grading parser never reads it. *Method:* `grep -c -F "CIAC-11" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1.
- [ ] **CIAC-12 (#971 × #972 on `fixture`):** declared, with nothing named. *Method:* declared, verification deferred.
- [ ] **CIAC-13 (#971 × #972 on `fixture`):** the deferral phrase is the probe's own pattern. *Method:* `grep -c -F "deferred to #13" release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1.
- [ ] **CIAC-14 (#971 × #972 on `fixture`):** a pipeline. *Method:* `grep -c -F "CIAC-14" release/tools/tests/fixtures/verify-plan-ciac-lint.md | wc -l` at least 1.
- [ ] **CIAC-15 (#971 × #972 on `fixture`):** an unterminated quote. *Method:* `grep -c "CIAC-15 release/tools/tests/fixtures/verify-plan-ciac-lint.md` at least 1.
- [ ] **CIAC-16 (#971 × #972 on `fixture`):** a count with no comparator the grader reads. *Method:* `grep -c -F "CIAC-16" release/tools/tests/fixtures/verify-plan-ciac-lint.md` → 1.
- [ ] **CIAC-17 (#971 × #972 on `fixture`):** a reader whose exit status is not its claim. *Method:* `cat release/tools/tests/fixtures/verify-plan-ciac-lint.md` shows the entry.
- [ ] **CIAC-18 (#971 × #972 on `fixture`):** a test primary with no operand. *Method:* `test -f` holds.
- [ ] **CIAC-19 (#971 × #972 on `fixture`):** a span no backtick closes. *Method:* `grep -c -F "CIAC-19" release/tools/tests/fixtures/verify-plan-ciac-lint.md
- [ ] **CIAC-20 (#971 × #972 on `fixture`):** prose that opens with a verb. *Method:* grep the fixture for the CIAC-20 entry and confirm it is present.
- [ ] **CIAC-21 (#971 × #972 on `fixture`):** declared, with one spanned issue's criterion only. *Method:* declared, verification deferred to #971 AC-1.
- [ ] **CIAC-22 (#971 × #972 on `fixture`):** declared with a reason, not a surface. *Method:* [DEFERRED — the checker ships in a later release]
