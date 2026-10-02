<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — declined-by-design rows, one per historical SKIP shape

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G13, arm V6236-AC4: every row declines by design, so the plan exits 0.

## Verification Plan

**#981 — declined-by-design per-issue rows**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `python3 tools/check.py --self-test` present | declined: a tool outside the verb set |
| AC-2 | `PORTFOLIO.md` carries the row, present | declined: an identifier in the command position |
| AC-3 | named read of the decision record, present | declined: no runnable command |
| AC-4 | declared, verification deferred to Stage 8 named read of the decision record | declined: declared deferral |
| AC-5 | [DEFERRED — the checker ships in a later release] | declined: declared deferral, bracket spelling |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#981 × #982 on `fixture`):** a refused tool. *Method:* `python3 tools/sets.py` compares the two sets.
- [ ] **CIAC-2 (#981 × #982 on `fixture`):** a refused deploy tool. *Method:* `deploy.sh --check` runs clean.
- [ ] **CIAC-3 (#981 × #982 on `fixture`):** prose. *Method:* read the script and confirm both behaviours are present.
- [ ] **CIAC-4 (#981 × #982 on the fixture):** a bullet whose procedure sits on its next line.
  *Method:* confirm the ordering by reading both anchors.
- [ ] **CIAC-5 (#981 × #982 on `fixture`):** declared. *Method:* declared, verification deferred to the CI run of the arm that asserts it.
