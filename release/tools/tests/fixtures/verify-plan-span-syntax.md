<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — a command the handlers cannot split, and a span no backtick closes

> Arm group G21 (V6236-AC1, with D55 and D38's closed-span rule). A command carrying an unterminated quote is input the executor could not read, so it reads ERROR naming the quote, on the cross-issue route and as a designated command; a genuine shell operator stays UNRUNNABLE. A command inside a span no backtick closes is prose, so it runs on no route: the per-issue keyword and residual routes, the cross-issue route, and a method naming more than one command. Each control is the same command, closed, and it runs.

## Verification Plan

**#985 — a span no backtick closes, and a genuine operator**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | grep: `grep -c -F "AC-1" release/tools/tests/fixtures/verify-plan-span-syntax.md | never runs: the span is not closed (keyword route) |
| AC-2 | `ls release/tools/tests/fixtures/verify-plan-span-syntax.md | never runs: the span is not closed (the residual route) |
| AC-3 | `python3 tools/check.py --self-test` beside `ls release/tools/tests/fixtures/verify-plan-span-syntax.md | the tool is named; the unclosed span is prose and never runs |
| AC-4 | `ls release/tools/tests/fixtures/verify-plan-span-syntax.md` | control: the same command, closed, runs and passes |
| AC-5 | `grep -c -F "AC-5" release/tools/tests/fixtures/verify-plan-span-syntax.md \| wc -l` at least 1 | a genuine shell operator stays UNRUNNABLE |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#985 × #986 on `fixture`):** an unterminated quote on the cross-issue route. *Method:* `grep -c "unterminated release/tools/tests/fixtures/verify-plan-span-syntax.md` at least 1.
- [ ] **CIAC-2 (#985 × #986 on `fixture`):** an unterminated quote in a designated command beside a tool. *Method:* `python3 tools/check.py` beside `grep -c "unterminated release/tools/tests/fixtures/verify-plan-span-syntax.md` at least 1.
- [ ] **CIAC-3 (#985 × #986 on `fixture`):** a span no backtick closes, on the cross-issue route. *Method:* `grep -c -F "CIAC-3" release/tools/tests/fixtures/verify-plan-span-syntax.md
- [ ] **CIAC-4 (#985 × #986 on `fixture`):** control, the same command, closed. *Method:* `grep -c -F "CIAC-4" release/tools/tests/fixtures/verify-plan-span-syntax.md` at least 1.
