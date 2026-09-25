<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their #N headers), not
     references to real work items. -->
# vTEST Release Plan — a method naming several commands is graded on its designated command

> Fixture for `release/tools/tests/test_verify_release_plan.sh`, arms V6837-AC4 and
> V7531-CIAC6. Every command reads this file, and every pattern is written with a
> bracketed hyphen, so no method cell matches its own pattern: the counts come from
> the data section at the end (the first token twice, the second once, the third
> never). AC-2 and CIAC-2 carry a false second command; AC-3 a false first command;
> AC-4 a second command with no comparator the vocabulary reads; AC-5 and CIAC-3 a
> second command naming no input and stating no comparator; AC-6 and CIAC-4 a second
> command naming no input with a comparator of its own; AC-7 and AC-8 a comparator
> written for the second command, which the pre-change tool reads for the first.
> AC-11 and AC-12 grade one command whose comparator carries emphasis or is outside
> the vocabulary; AC-13 opens with a bare verb and AC-14 with a tool span, each ahead
> of its probe.

## Verification Plan

**#970 — multi-command methods**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; paired arm `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 1 | the designated command holds and the second does not run: the can't-run slot, never PASS |
| AC-2 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; paired arm `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2 | a false second command does not run: the can't-run slot, never PASS |
| AC-3 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 3; paired arm `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 1 | a false designated command: FAIL before and after |
| AC-4 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; specificity arm `grep -c -E 'LIMB[-]GAMMA' release/tools/tests/fixtures/verify-plan-multi-limb.md` returns zero | the second command states no comparator the vocabulary reads, and it does not run: the can't-run slot, never PASS |
| AC-5 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; control arm on the same file `grep -c -E 'LIMB[-]BETA'` is non-zero | the second command names no input: it does not run, and no later row is lost |
| AC-6 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; control arm on the same file `grep -c -E 'LIMB[-]BETA'` expect 1 | a second command naming no input, with a comparator of its own: it does not run either |
| AC-7 | `grep -c -E 'LIMB[-]GAMMA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 0; control `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` at least 1 | the null holds on its own comparator and the control does not run: the can't-run slot (the old reading graded the null against the control's comparator) |
| AC-8 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 0; control `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` at least 1 | a violated null: FAIL (the old reading passed it) |
| AC-9 | `test -f release/tools/tests/fixtures/verify-plan-multi-limb.md` | control after the planted rows: PASS |
| AC-10 | `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2 | one command: graded exactly as before |
| AC-11 | `grep -c -E 'LIMB[-]GAMMA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect **0** | one command whose null carries markdown emphasis: read as expect 0, PASS |
| AC-12 | `grep -c -E 'LIMB[-]GAMMA' release/tools/tests/fixtures/verify-plan-multi-limb.md` returns 0 | returns N is not a comparator: graded on the exit status, which reads a zero count as FAIL |
| AC-13 | `grep` names the tool in prose; the probe is `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 1 | a bare verb is prose: the probe is the designated command, PASS |
| AC-14 | `python3 release/tools/verify-release-plan.sh --version` names a tool; the probe is `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 1 | a tool span is prose until the tool predicate names it: one command, PASS |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#970 × #971 on `fixture`):** two commands, and the designated one holds. *Method:* `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; paired arm `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 1.
- [ ] **CIAC-2 (#970 × #971 on `fixture`):** a false second command. *Method:* `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; paired arm `grep -c -E 'LIMB[-]BETA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2.
- [ ] **CIAC-3 (#970 × #971 on `fixture`):** a second command naming no input. *Method:* `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; control arm on the same file `grep -c -E 'LIMB[-]BETA'` is non-zero.
- [ ] **CIAC-4 (#970 × #971 on `fixture`):** a second command naming no input, with a comparator of its own. *Method:* `grep -c -E 'LIMB[-]ALPHA' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 2; control arm on the same file `grep -c -E 'LIMB[-]BETA'` expect 1.
- [ ] **CIAC-5 (#970 × #971 on `fixture`):** control after the planted entries. *Method:* `test -f release/tools/tests/fixtures/verify-plan-multi-limb.md`.

## Fixture data (read by the commands above; not a verification table)

LIMB-ALPHA first line
LIMB-ALPHA second line
LIMB-BETA only line
