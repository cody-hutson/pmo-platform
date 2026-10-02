<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their #N headers), not
     references to real work items. -->
# vTEST Release Plan — verify-release-plan.sh fixture (a documented-decision method on a per-issue row)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`, arms V6685-AC1, V6685-AC2
> and V6685-AC4. A per-issue row whose method is a documented decision (a named read of a
> named surface, with no command this executor runs) grades a named SKIP that carries its
> rationale. Declared in the method cell (AC-1, AC-2), it is the declared-deferred SKIP and
> its reason travels in the emitted method. Left undeclared (AC-3), it is the per-issue
> no-command SKIP, never a PASS and never an unclassified ERROR. The cross-issue criterion
> (CIAC-1) keeps the integration family's documented-decision SKIP, unchanged. CIAC-1 is
> undeclared on purpose: it is the control for the integration family's own hatch, so do
> not rewrite it into the declared-deferred form, which would grade the declaration instead.
> No documented-decision row here opens with an allowlisted verb word or carries a
> backticked span, so each stays a named read on every route. The malformed-method control
> twin is verify-plan-documented-decision-control.md.

## Verification Plan

**#964 — a documented-decision method on a per-issue row**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | [DEFERRED — named read of the merged ADR's Decision section, which records the chosen branch; graded at Stage 8] | named SKIP (declared-deferred) carrying this rationale |
| AC-2 | declared, verification deferred to the Stage 8 named read of the merged ADR's Decision section | named SKIP (declared-deferred) carrying this rationale |
| AC-3 | named read of the merged ADR's Decision section; confirm it records the chosen branch | named SKIP (no command in method); never PASS, never an unclassified ERROR |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#965 × #966 on `the decision record`):** both cards agree on where the decision is recorded. *Method:* confirm the recorded decision in the merged ADR's Decision section, a named read with nothing to run. *Graded at Stage 9 QC3.5 on the merged PR.*
