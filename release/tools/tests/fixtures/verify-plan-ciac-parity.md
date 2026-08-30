<!-- repo-integrity: allow-issue-ref -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their Issue column /
     #N headers), not references to real work items. -->
# vTEST Release Plan — a CIAC parity-error record must survive the read

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G11.
>
> The SECOND emitter carrying an empty interior field, and the evidence the
> hazard was already half-known: the Verification-Plan parity emit writes the
> literal `ROW` into field 2 on purpose, while the CIAC parity emit writes an
> empty string. The same author guarded one and not the other.
>
> Under a whitespace delimiter that empty field collapses, the family marker
> shifts out of position, the row fails the `parity-error` test in the consumer
> and is re-labelled `integration` — so a row the parser explicitly REFUSED to
> index is dispatched as a cross-issue check, and the field-count diagnostic is
> run as its method.
>
> CIAC-2 below carries a genuinely unescaped bare pipe and must render ERROR with
> family `parity-error`. CIAC-1 is the conformant control.

## Verification Plan

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #822 | AC-1 | `test -f release/tools/verify-release-plan.sh` | the executor file exists |

## Cross-Issue Acceptance Criteria (fixture-scoped)

<!-- AUTHORING NOTE: the CIAC table header test is a SUBSTRING match, so a data
     cell whose prose contains the word "method" or "predicate" is re-read as a
     header row. Keep those two words out of the cells below. -->

| Identifier | Predicate | Method | Expected |
|---|---|---|---|
| CIAC-1 (#822) | the conformant control row carries its header field count | `test -f release/tools/verify-release-plan.sh` | ok |
| CIAC-2 (#822) | this row carries an unescaped bare | pipe and is malformed GFM | `test -f release/tools/verify-release-plan.sh` | ok |
