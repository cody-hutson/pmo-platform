<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — a binary test whose last word is spelled like a unary primary

> Arm group G19 (V6854-AC3 k). The reader table's operand rule refuses a `test` primary that names no operand, and a word spelled like a primary is one only where a primary can stand: opening the expression, or after `!`, `(`, `-a` or `-o`. After a binary operator the same word is that operator's operand, so the command names its operand and `test` itself decides the row. AC-1 and AC-2 carry that shape, and each reads the verdict `test` gives it, on the per-issue route, on the cross-issue route and to the authoring lint. The controls read the same on every executor: a binary test whose last word is not spelled like a primary, and a primary after `!` with no operand, which stays refused.

## Verification Plan

**#987 — a binary test whose last word is spelled like a primary**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `test abc != -f` | PASS: the command names its operand, and the expression holds |
| AC-2 | `test abc = -f` | FAIL: the same shape, and the expression does not hold, so the row reads the verdict `test` gives it |
| AC-3 | `test abc = abc` | control: a binary test whose last word is not spelled like a primary reads PASS on every executor |
| AC-4 | `test ! -d` | control: a primary after `!` names no operand and stays refused (ERROR no-operand:test) |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#987 × #988 on `fixture`):** the same binary shape on the cross-issue route. *Method:* `test abc != -f`.
