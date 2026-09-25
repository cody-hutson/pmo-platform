<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N token below is synthetic
     release-plan test data, not a reference to a real work item. -->
# vTEST Release Plan — verify-release-plan.sh fixture (control twin: a genuinely malformed per-issue method)

> Control twin of verify-plan-documented-decision.md, for arm V6685-AC3. Every row names a
> command this executor could run but cannot read, so it is never a named SKIP and never a
> PASS: the fix for a documented-decision method is not satisfied by making every row the
> executor does not run a SKIP. AC-1 (an unterminated quote) reaches the per-issue handler
> through a routing word. AC-2 (an unterminated quote) carries no routing word and no
> runnable probe, so it takes the documented-decision method's own route, the classifier
> residual. The handler cannot split either command into the words its author meant, so it
> refuses both before they run. AC-3 is the padding the card names: a documented-decision
> method padded with a backticked test primary that has no operand, refused as naming no
> operand, never a PASS.

## Verification Plan

**#967 — a genuinely malformed per-issue method**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep -c "unterminated release/tools/tests/fixtures/verify-plan-documented-decision.md` at least 1 | never a named SKIP or a PASS: the command cannot be split into words (unterminated quote) |
| AC-2 | `head -n 1 "release/tools/tests/fixtures/verify-plan-documented-decision.md` at least 1 | never a named SKIP or a PASS: the command cannot be split, and no routing word reaches it |
| AC-3 | `test -f` the merged ADR at its delivered path; a named read of its Decision section | ERROR: a test primary with no operand is refused, never a PASS |
