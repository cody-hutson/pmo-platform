# vTEST Release Plan — verify-release-plan.sh fixture (canonical Issue-keyed shape)

> Fixture for `release/tools/tests/test_verify_release_plan.sh` (sub-task #3175).
> Exercises the CANONICAL per-issue table shape (bold `**#N — …**` subsection
> headers supply the per-issue grouping) across all five check families, plus a
> canonical-scaffold Cross-Issue Acceptance Criteria section. All methods are
> fast, local greps against this fixture tree — no deploy.sh --check delegation
> here (that path is validated once against the real release plan).

## Verification Plan

**#901 — per-issue family**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `grep -c 'Verification Plan' release/tools/tests/fixtures/verify-plan-3175-canonical.md` ≥ 1 | ≥1 |
| AC-2 | file-path+state | `test -f release/tools/verify-release-plan.sh` | file exists |
| AC-3 | file-path+state | `grep -c 'NONEXISTENT_TOKEN_ZZZ' release/tools/tests/fixtures/verify-plan-3175-canonical.md` ≥ 5 | ≥5 (intentional FAIL — count is 0) |

**#902 — deferred + runtime family**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | behavioral/domain, DEFERRED | [DEFERRED — first multi-issue release post-deploy] run against a future plan | tracked; deferred |
| AC-2 | runtime | dispatch the runtime suite for this deliverable; no-match row fires → suite-skip | suite-skip (no-op) |

## Cross-Issue Acceptance Criteria (release-scoped)

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#901 × #902 on `the fixture surface`):** both issues' fixtures co-occur the executor's two consumed-surface anchors. *Method:* `grep -cE 'Verification Plan|Cross-Issue' release/tools/tests/fixtures/verify-plan-3175-canonical.md` ≥ 2. *Graded at Stage 9 QC3.5 on the merged PR.*
