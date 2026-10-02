<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — a method this executor cannot run

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G17, arm V6848-AC2: a tool the method invokes is named and reported UNRUNNABLE, never PASS; a label, a file name or a word the method only mentions is never named.

## Verification Plan

**#981 — can't-run-here**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `awk 'END{print NR}' core/CLAUDE.md.template` expect 4 | awk, no family keyword |
| AC-2 | `awk 'END{print NR}' core/CLAUDE.md.template` — at least 1 line present | awk, with a keyword |
| AC-3 | `python3 release/tools/check-adr-numbers.py` exits 0 | an interpreter |
| AC-4 | the `PARSE-07`, `PARSE-12a`, `PARSE-14a`, `PMO_SCOPE_GUARD_ROOT`, `G-CL`, `_pmo` and `status` labels are present (grep them) | identifiers only |
| AC-5 | `G-CL` then `bash release/tools/tests/test_verify_release_plan.sh` present | the tool, not the identifier before it |
| AC-6 | `grep -c -F "RUNNABLE_VERBS" release/tools/verify-release-plan.sh` at least 1 | control: a runnable probe still executes |
| AC-7 | the hand-maintained `case` arms are gone, and the `source` field is present | mentions only: a shell word with no argument is prose |
| AC-8 | re-run the fixture with a control arm on `core/hooks/block-destructive.sh`, present | a script path mentioned in prose is not a command |
| AC-9 | `grep -c -F "RUNNABLE_VERBS" release/tools/verify-release-plan.sh` at least 1 and `awk 'END{print NR}' core/CLAUDE.md.template` expect 4 | a runnable probe, then a tool: never a pass |
| AC-10 | `awk 'END{print NR}' core/CLAUDE.md.template` expect 4 and `grep -c -F "RUNNABLE_VERBS" release/tools/verify-release-plan.sh` at least 1 | a tool, then a runnable probe: never a pass |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#981 × #982 on `fixture`):** an interpreter. *Method:* `python3 release/tools/check-adr-numbers.py`.
- [ ] **CIAC-2 (#981 × #982 on `fixture`):** prose around an identifier. *Method:* grep the `PORTFOLIO.md` contract field set for the shared key.
- [ ] **CIAC-3 (#981 × #982 on `fixture`):** control. *Method:* `grep -c -F "VERDICT_PASS" release/tools/verify-release-plan.sh` at least 1.
- [ ] **CIAC-4 (#981 × #982 on `fixture`):** a runnable probe, then a tool. *Method:* `grep -c -F "VERDICT_PASS" release/tools/verify-release-plan.sh` at least 1 and `awk 'END{print NR}' core/CLAUDE.md.template` expect 4.
