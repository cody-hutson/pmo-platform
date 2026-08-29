<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser's job is to group checks by their #N
     issue headers), not references to real work items. -->
# vTEST Release Plan — escaped-pipe CONTROL twin (no escape anywhere)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G7.
>
> CONTROL twin of `verify-plan-escaped-pipe.md`. Structurally identical — same
> sections, same issue grouping, same column shape, same matchers — except that
> every method here is expressible without an alternation, so no cell needs a
> markdown pipe escape and no row carries a bare pipe.
>
> WHAT THIS ARM IS FOR. The sensitivity fixture asserts that escaped rows PASS
> after the fix. On its own that is compatible with a parser that has simply
> become permissive. This twin asserts the other half: on input carrying no
> escape, the fix is INERT and every row still passes exactly as it did before.
> A sensitivity arm whose control does not also behave is not a control.
>
> It also carries no malformed row, which is the point: the parity guard must
> fire on the sensitivity fixture and stay silent here.

## Verification Plan

**#911 — no escape needed**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `grep -cE 'Verification Plan' release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md` ≥ 2 | ≥2 |
| AC-2 | file-path+state | `grep -c 'sentinel-alpha' release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md` ≥ 1 | ≥1 sentinel-alpha |

**#912 — a well-formed row, same shape as the malformed one in the twin**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-3 | file-path+state | `grep -c 'orphan' release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md` ≥ 1 | ≥1 orphan |

## Cross-Issue Acceptance Criteria (fixture-scoped)

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#911 × #912 on `the fixture surface`):** the scaffold-bullet form has no escape to resolve here. *Method:* `grep -cE 'Verification Plan' release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md` ≥ 2. *Graded at Stage 9 QC3.5 on the merged PR.*

<!-- AUTHORING NOTE: the header test in the CIAC table parser is a SUBSTRING
     match, so a data cell whose prose contains the word "method" or "predicate"
     is re-read as a header row and the real data row is never emitted. Keep
     those two words out of the cells below. -->

| Identifier | Predicate | Method | Expected |
|---|---|---|---|
| CIAC-2 (#911 × #912) | the CIAC table form has no escape to resolve here | `grep -cE 'Verification Plan' release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md` ≥ 2 | ≥2 |
