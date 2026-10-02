<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — a declared deferral in a span no backtick closes

> Arm group G21 (V6236-AC1, with D38's closed-span rule). A span no backtick closes is prose, so a command written there runs on no route, and every reader of a declared deferral reads that piece as the prose it is: a deferral written in it is read, never hidden. AC-1 and CIAC-1 carry the deferral in the only span, unclosed; AC-2 and CIAC-2 put a closed probe first and the deferral in an unclosed piece led by an allowlisted verb. Each reads the declared-deferred SKIP, and the authoring lint reads each CIAC DECLARED, naming its evidence. The controls, AC-3 and CIAC-3, carry the same deferral in prose, and read the same on every executor.

## Verification Plan

**#988 — a declared deferral in a span no backtick closes**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep [DEFERRED — graded at Stage 8 from arm V988-AC1] | declared-deferred: the only span is unclosed, and the deferral in it is read |
| AC-2 | `grep -c -F "AC-2" release/tools/tests/fixtures/verify-plan-span-deferral.md` at least 1, then `grep [DEFERRED — graded at Stage 8 from arm V988-AC2] | declared-deferred: a closed probe first, then the deferral in an unclosed piece led by a verb |
| AC-3 | `grep -c -F "AC-3" release/tools/tests/fixtures/verify-plan-span-deferral.md` at least 1, then [DEFERRED — graded at Stage 8 from arm V988-AC3] | control: the same deferral in prose reads declared-deferred on every executor |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#988 × #989 on `fixture`):** the only span, unclosed, carries the deferral. *Method:* `grep [DEFERRED — graded at Stage 9 from arm V988-CIAC1]
- [ ] **CIAC-2 (#988 × #989 on `fixture`):** a closed probe first, then the deferral in an unclosed piece led by a verb. *Method:* `grep -c -F "CIAC-2" release/tools/tests/fixtures/verify-plan-span-deferral.md` at least 1, then `grep [DEFERRED — graded at Stage 9 from arm V988-CIAC2]
- [ ] **CIAC-3 (#988 × #989 on `fixture`):** control, the same deferral in prose. *Method:* `grep -c -F "CIAC-3" release/tools/tests/fixtures/verify-plan-span-deferral.md` at least 1, then [DEFERRED — graded at Stage 9 from arm V988-CIAC3]
