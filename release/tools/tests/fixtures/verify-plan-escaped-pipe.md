<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser's job is to group checks by their #N
     issue headers), not references to real work items. -->
# vTEST Release Plan — escaped-pipe field-parity fixture (SENSITIVITY arm)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G7.
>
> Every check below carries a markdown pipe escape (`\|`) — the correct GFM way
> to author a literal pipe inside a table cell — except the last, which carries a
> genuinely UNESCAPED bare pipe and must therefore render ERROR rather than a
> verdict derived from cells read at shifted indices.
>
> Its control twin is `verify-plan-escaped-pipe-control.md`, structurally
> identical except that no row needs an alternation. Without that twin a green
> run here would prove nothing: an all-PASS result is only evidence if the same
> shape without the trigger also passes.
>
> CIAC-1 below is the opposite guard, and it exists because the fix that resolves
> the escape in TABLE cells was briefly applied to bullets too. A bullet is never
> split on pipes, so a `\|` inside one is matcher syntax rather than markdown,
> and substituting it silently rewrites the author's pattern. sentinel-omega.

## Verification Plan

**#911 — escaped pipe in the Verification-Plan table**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `grep -cE 'Verification Plan\|Acceptance Criteria' release/tools/tests/fixtures/verify-plan-escaped-pipe.md` ≥ 2 | ≥2 |
| AC-2 | file-path+state | `grep -c 'sentinel-alpha' release/tools/tests/fixtures/verify-plan-escaped-pipe.md` ≥ 1 | ≥1 sentinel-alpha |

**#912 — an unescaped bare pipe is malformed GFM, and is named as such**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-3 | file-path+state | `grep -c '^| orphan' release/tools/tests/fixtures/verify-plan-escaped-pipe.md` ≥ 1 | ≥1 |

## Cross-Issue Acceptance Criteria (fixture-scoped)

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#911 × #912 on `the fixture surface`):** a bullet is never split on pipes, so a `\|` inside one is NOT a markdown escape — it is verbatim matcher syntax, and under a BRE matcher it is the alternation operator. The parser must pass it through untouched. *Method:* `grep -c "sentinel-alpha\|sentinel-omega" release/tools/tests/fixtures/verify-plan-escaped-pipe.md` ≥ 2. *Graded at Stage 9 QC3.5 on the merged PR.*

<!-- AUTHORING NOTE: the header test in the CIAC table parser is a SUBSTRING
     match, so a data cell whose prose contains the word "method" or "predicate"
     is re-read as a header row and the real data row is never emitted. Keep
     those two words out of the cells below. -->

| Identifier | Predicate | Method | Expected |
|---|---|---|---|
| CIAC-2 (#911 × #912) | the CIAC table form splits on the same separator as the Verification-Plan table, so it carries the same defect | `grep -cE 'Verification Plan\|Acceptance Criteria' release/tools/tests/fixtures/verify-plan-escaped-pipe.md` ≥ 2 | ≥2 |
