<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column),
     not references to real work items. -->
# vTEST Release Plan — verify-release-plan.sh fixture (header-trap: schema words in DATA cells)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`.
>
> THE TRAP ARM for the header-detection fix landed by `94dcadb7`. Three of the
> four data rows below carry, inside a DATA cell, one of the words the header
> name-filter matches: `predicate`, `expected`, `verification method`. Before
> that commit the parser tested EVERY row for those words and consumed the first
> match as a header — the row produced NO record at all (not a PASS, not a FAIL,
> not an ERROR) and the column map was re-pointed, so every later row read its
> cells at a shifted index. Two acceptance-criterion rows of a live release plan
> vanished to exactly this.
>
> The fix is POSITIONAL: only `block_row == 1` is header-eligible, so every later
> row is a data row whatever words it contains. That fix shipped with **no test**
> — 0 of 5 fixtures carried a trap data row. This fixture is that arm.
>
> Its twin, `verify-plan-header-trap-control.md`, is byte-for-byte the same table
> with the trap vocabulary removed. **Both must report the same record count.**
> The pair is the assertion: a matching count on the trap alone proves nothing,
> because a parser that dropped every row would also "match".

## Verification Plan

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #711 | AC-1 | `grep -c 'header-trap-alpha' release/tools/tests/fixtures/verify-plan-header-trap.md` ≥ 1 | ≥1 |
| #711 | AC-2 | this cell states a predicate and the expected count inline: `grep -c 'header-trap-beta' release/tools/tests/fixtures/verify-plan-header-trap.md` ≥ 1 | ≥1 |
| #711 | AC-3 | this cell names a verification method in its own text: `grep -c 'header-trap-gamma' release/tools/tests/fixtures/verify-plan-header-trap.md` ≥ 1 | ≥1 |
| #711 | AC-4 | `test -f release/tools/verify-release-plan.sh` | file exists |
