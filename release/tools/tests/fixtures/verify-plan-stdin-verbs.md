<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their #N headers), not
     references to real work items. -->
# vTEST Release Plan — every allowlisted stdin-capable verb, in both dispatch loops

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G12.
>
> Every planted row names a reader and no readable input: grep, head, wc and cat
> with no file operand, grep with the explicit stdin operand `-`, a device path, and
> an option the executor's model does not know. The per-issue planted rows carry
> "present" so the keyword classifier dispatches them. Each planted row is followed
> by a control, so a row that drained the record stream shows up as the control
> after it going missing. Before the fix the first planted grep (AC-2, CIAC-2) reads
> the rest of its loop's records and every later row vanishes. After it, every row
> emits, each planted row is a named ERROR carrying its refusal reason, and every
> control row grades PASS. The one exception is AC-8: its `cat` carries no argument
> at all, and a bare verb names a tool in prose rather than a command, so that row
> names no command and reads a named SKIP; nothing in it reads stdin.

## Verification Plan

**#995 — the per-issue loop**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-2 | content | `grep -c -F "AC-"` present, expect 0 | planted: grep, no file operand |
| AC-3 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-4 | content | `head -n 1` present, expect 0 | planted: head, no file operand |
| AC-5 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-6 | content | `wc -l` present, expect 0 | planted: wc, no file operand |
| AC-7 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-8 | content | `cat` present, expect 0 | planted: cat, no argument at all |
| AC-9 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-10 | content | `grep -c -F "AC-" -` present, expect 0 | planted: grep, explicit stdin operand |
| AC-11 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-12 | content | `grep -c -F "AC-" /dev/stdin` present, expect 0 | planted: a device path, not a repository file |
| AC-13 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-14 | content | `grep -c --not-an-option "AC-" release/tools/verify-release-plan.sh` present, expect 0 | planted: an option the model does not know |
| AC-15 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#995 × #996 on `fixture`):** control one. *Method:* `test -f release/tools/verify-release-plan.sh`.
- [ ] **CIAC-2 (#995 × #996 on `fixture`):** planted grep. *Method:* `grep -c -F "CIAC"` expect 0.
- [ ] **CIAC-3 (#995 × #996 on `fixture`):** control three. *Method:* `test -f release/tools/verify-release-plan.sh`.
- [ ] **CIAC-4 (#995 × #996 on `fixture`):** planted head. *Method:* `head -n 1` expect 0.
- [ ] **CIAC-5 (#995 × #996 on `fixture`):** control five. *Method:* `test -f release/tools/verify-release-plan.sh`.
- [ ] **CIAC-6 (#995 × #996 on `fixture`):** planted cat. *Method:* `cat -u` expect 0.
- [ ] **CIAC-7 (#995 × #996 on `fixture`):** control seven. *Method:* `test -f release/tools/verify-release-plan.sh`.
