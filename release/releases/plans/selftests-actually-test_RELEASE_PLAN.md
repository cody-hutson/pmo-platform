---
title: Release Plan — selftests-actually-test
purpose: Stage-4 release plan for the nine self-test honesty defects — every suite in this bundle passes today with the behavior it claims to cover removed.
type: release-plan
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->

# Release Plan: selftests-actually-test — A Self-Test That Passes Proves the Behavior Under Test Actually Ran

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure: `max(claimed tags v4.x, RELEASE_LOG v4.x rows) + 1`; tags max **38**, ledger rows max **38**, published Releases max **38**, so next-free is **v4.39**. |
| **Date Created** | 2026-08-23 (Sunday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/selftests-actually-test |
| **PR** | not yet opened — the release ships as a SINGLE PR with one merge gate; the hub opens it once the sequence has landed enough to warrant it |
| **Milestone** | selftests-actually-test |
| **Release Class** | `routine` — CONFIRMED at Stage 4 (D2), confirming the Stage 3 declaration |
| **Raw points** | **20** — nine members; seven `size:S` plus `#5273` re-labelled `size:M` → `size:S` at D3 |
| **Branch topology** | **SINGLE** — one branch, one PR, one merge gate |
| **Concurrency posture** | **P0 fully-serial**. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `8dc00db1` — fetched at Engineering Commit 0; identical to the Stage-4 pin, so no re-baseline was required |

## Release Outcome Statement

**Before:** a self-test in this bundle can report green while the behavior it names is absent — the suite asserts against its own inline copy of the predicate, against a fixture seeded to the value the subject already produces by default, or against nothing at all.

**After:** every suite in this bundle fails when the behavior under test is removed. Each card's evidence records **both** directions — clean tree green, seeded defect red.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Size | Stage 5 |
|---|-------|---------------------|------|---------|
| 1 | #5241 | `test-status-label-invariant.sh` never reads its own subject | S | SKIP |
| 2 | #4441 | package-freshness SKIP gating + PF-2 discriminator | S | SKIP |
| 3 | #4914 | `check-work-hierarchy` self-test 69 → 71 | S | SKIP |
| 4 | #5273 | duplicate-key limbs on the existing re-bootstrap block | S | APPLY |
| 5 | #5272 | `refresh_hooks` seed must differ from default | S | APPLY |
| 6 | #4913 | `cleanup-orphan-state` hermetic + exclusion removed | S | APPLY |
| 7 | #5237 | Arm D glob widening | S | APPLY |
| 8 | #4443 | wire the three unwired suites | M | APPLY |
| 9 | #5239 | `release-tooling-smoke.yml` sibling arms | S | SKIP |

Effective scope is **9 members / 20 pts**. The milestone `## Composition` block was amended at D1 from *10 issues / 24 pts*, dropping `#5238` (CLOSED `not_planned`, labelled `duplicate`; its scope is subsumed by the acceptance criteria on `#4913`). Both totals sit inside the 15-25 pt band, so this was an amend, not a re-bundle.

Stage 5 applies to **5 of 9**; Stages 7 and 8 apply to **9 of 9** — no card qualifies for the no-functional-impact skip.

## Dependency Graph

Directional; edge class stated with its evidence. No circular chains (36 issue pairs walked).

```
WAVE 1  (no inbound edges — fully independent)
  #5241  test-status-label-invariant.sh executes deploy.sh
  #4441  package-freshness SKIP gating + PF-2 discriminator
  #4914  check-work-hierarchy self-test 69 -> 71

WAVE 2  (HARD edge — same file, different regions)
  #5273  duplicate-key limbs -> existing re-bootstrap block
     |
     |  HARD: both edit core/deploy/tests/test_install_end_to_end.sh
     v
  #5272  refresh_hooks seed != default  (+ AC-3 enumeration lands at :244)

WAVE 3  (SOFT edge — shared verification surface, not shared file)
  #4913  cleanup-orphan-state hermetic + exclusion removed
     |
     |  SOFT: both change `check-selftest-coverage.py --reconcile` output
     v
  #5237  Arm D glob widening
     |
     |  SOFT (WARN-only, non-blocking)
     v
  #4443  wire the three unwired suites

WAVE 4  (CI-workflow surface — highest blast radius)
  #4443  install-tests.yml
  #5239  release-tooling-smoke.yml     (file-disjoint from #4443)
```

**Edge `#5237 → #4443` is SOFT, and the evidence says so.** Widening Arm D's globs makes `release/tools/tests/ac3_concurrent_load.sh` newly *reported* — but Arm D calls `warn()`, and `warn()` only prints `::warning::`. The Arm D block never sets `failed`, and the return is `return 1 if failed else 0`. Widening the glob cannot redden CI. Per the coordination-not-relocation pattern this is a coordination note: `ac3_concurrent_load.sh` stays owned by `#5237`, and is not moved into `#4443`'s scope.

**Edge `#4913 → #5237` is SOFT (attribution, not blocking).** Both mutate what one `--reconcile` run prints. Sequencing them lets a changed verdict be attributed to a specific fix rather than to the pair.

## Implementation Sequence

Single shared branch, one PR, one merge gate. **D-Concurrency Posture: P0 fully-serial** — two serialization constraints plus a repo-wide CI blast radius. Posture parallelism is opt-in and nothing here earns the opt-in.

| # | Issue | Why here |
|---|-------|----------|
| 1 | `#5241` | Highest severity (High). Self-contained, one file, zero inbound edges. |
| 2 | `#4441` | Independent. One file. |
| 3 | `#4914` | Independent. `self_test()` only — no behavioral change to the tool. |
| 4 | `#5273` | Must precede `#5272` (same file). Re-scoped — edits the existing re-bootstrap block. |
| 5 | `#5272` | Follows `#5273`. Seed fix; AC-3 discharged record-only per D4. |
| 6 | `#4913` | Precedes `#5237` for verification attribution on the shared `--reconcile` surface. |
| 7 | `#5237` | Follows `#4913`. Capture `--reconcile` at three points: base, post-`#4913`, post-`#5237`. |
| 8 | `#4443` | CI surface. **Intra-issue order is load-bearing:** characterise/fix the hang (or remove with a recorded reason) **before** wiring; bounded timeout lands with the wiring. |
| 9 | `#5239` | CI surface, file-disjoint from `#4443`. Last: `release-tooling-smoke.yml` gates every PR. |

Waves 1-3 are suite/tool fixes that fail closed locally. Wave 4 edits the two workflow files that gate every PR in the repo, so they land after the suites they wire are green.

## Contention Map

**Declared matrices are disjoint. Execution is not.**

| Surface | Issues | Class | Resolution |
|---------|--------|-------|------------|
| `core/deploy/tests/test_install_end_to_end.sh` | `#5273`, `#5272` | **HARD — same file** | Serialize `#5273` → `#5272`. Different regions, so low conflict risk when serialized, high if parallel. |
| `core/deploy/tests/test_verify_session_config.sh` | `#4443`, `#5272` | **LATENT** | Record-only discharge of `#5272` AC-3 (D4) avoids the edit entirely. |
| `check-selftest-coverage.py --reconcile` output | `#4913`, `#5237` | **SOFT — shared verdict, not shared file** | Serialize for attribution; capture the output at three points. |
| `.github/workflows/` (two distinct files) | `#4443`, `#5239` | **NONE** | `install-tests.yml` vs `release-tooling-smoke.yml` — disjoint. |

**All five shipped mode templates carry the identical literal `warn`.** Any install-if-missing or preserve assertion written against any of them inherits the seed-equals-default collapse. This is the root enabler behind `#5272`, and the durable fix is a fixture deriving its seed as *any value other than the shipped default* rather than hardcoding one.

### File Change Matrix (machine-readable)

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-23, domain: software }`

Every path is a test suite, a bash/python tool, a CI workflow, or a skill script — no governance, pipeline-spec, or ADR surface is touched. Deliverable class is `software`; no secondary domain.

```
# ── Wave 1 ──
core/deploy/tools/tests/test-status-label-invariant.sh          edit
core/deploy/tests/test_package_freshness_exit_codes.sh          edit
core/deploy/tools/check-work-hierarchy.py                       edit
# ── Wave 2 (serialized: #5273 then #5272) ──
core/deploy/tests/test_install_end_to_end.sh                    edit
core/deploy/tests/test_refresh_hooks.sh                         edit
# ── Wave 3 ──
release/tools/cleanup-orphan-state.sh                           edit
core/deploy/allowlists/selftest-coverage-exclusions.txt         edit
release/tools/check-selftest-coverage.py                        edit
# ── Wave 4 ──
core/deploy/tests/test_check19_event_log_integrity.sh           edit
.github/workflows/install-tests.yml                             edit
.github/workflows/release-tooling-smoke.yml                     edit
core/skills/finops-usage-extractor/scripts/rollup-attribution.sh edit
core/skills/finops-usage-extractor/scripts/report-usage.sh      edit
core/skills/finops-usage-extractor/scripts/estimate-usage.sh    edit
# ── CONDITIONAL rows ──
core/deploy/tests/test_check19_event_log_integrity.sh           delete  CONDITIONAL:HANG-UNFIXABLE
release/tools/tests/ac3_concurrent_load.sh                      edit    CONDITIONAL:RENAME-AND-WIRE-PATH
```

```
#### Read-only inputs
core/hooks/.mode.template                                       READ
core/hooks/.autonomy-mode.template                              READ
core/hooks/.gh-path-leak-mode.template                          READ
core/hooks/.verify-session-config-mode.template                 READ
core/hooks/deploy-check.mode.template                           READ
core/deploy/tests/test_instance_path_roundtrip.sh               READ
core/deploy/tests/test_verify_session_config.sh                 READ
```

`CONDITIONAL:HANG-UNFIXABLE` fires only if `#4443`'s design decision routes to removal. `CONDITIONAL:RENAME-AND-WIRE-PATH` fires only if `#5237`'s design decision routes to rename-and-wire instead of glob-widening; exactly one of the two `#5237` paths resolves, and whichever fires is promoted into the unconditional set in the same commit. The two `READ` suites become `edit` only if `#4443` wiring requires in-file changes beyond the workflow. There are no `add` rows — every fix is an in-place edit, so the new-executable allowlist companion obligation does not fire.

## Risk Register

| ID | Sev | Risk | Owner | Mitigation | Reversibility |
|----|-----|------|-------|------------|---------------|
| **R-1** | **HIGH** | `#5273`'s premise moved 12h pre-planning. A spoke following the card literally authors a parallel second-invocation block, duplicating scaffolding already shipped. | Stage 5 `#5273` | Re-scoped at D3 to *add the two duplicate-key limbs to the existing re-bootstrap block*. | CHEAP |
| **R-2** | MED | **Line-number rot in three cards.** `#5272`, `#5273` and `#4443` all cite positions that have moved. | Engineering | **Edit by anchor or content, never by line number.** Cited positions in issue bodies are historical and may be wrong. | CHEAP |
| **R-3** | MED | `#4443`'s hanging suite is unbounded — timed out at 45 s having emitted 171 bytes. Wiring before characterising burns a runner and can block the release PR. | `#4443` | Intra-issue order: characterise or fix (or remove with recorded reason) before wiring. Bounded timeout is an explicit acceptance criterion. | CHEAP |
| **R-4** | MED | Verification-attribution ambiguity: `#4913` and `#5237` both mutate one `--reconcile` verdict. | `#4913`/`#5237` | Serialize `#4913` → `#5237`; capture output at base, post-`#4913`, post-`#5237`. | CHEAP |
| **R-5** | MED | **Hidden file contention** `#5272` × `#5273` — invisible in both cards' declared Affected Files. | Stage 5 `#5272` | Serialize (Wave 2). Record-only discharge at D4 avoids the edit entirely. | CHEAP |
| **R-6** | MED | Wave 4 edits the two workflow files that gate **every PR in the repo**. A bad edit reddens all subsequent PRs, not just this release. | `#4443`/`#5239` | Land last, after the suites they wire are green. Revert is one commit. | CHEAP (revert); blast radius repo-wide |
| **R-7** | MED | Quota: worst parallel batch is **9 spokes** (Stages 7/8) against an unstated envelope. | Hub | Split 5 + 4; Checkpoint B is the load-bearing gate at every launch. | CHEAP |
| **R-8** | LOW | `test_instance_path_roundtrip.sh` runs 17.6 s; wiring three suites adds real CI wall-time. | `#4443` | Bounded timeout; consider a dedicated job rather than inflating an existing one. | CHEAP |
| **R-9** | LOW | `## Composition` block overstated scope (10 / 24 vs live 9 / 22 at planning). | Operator | Amended at D1. | CHEAP |
| **R-10** | LOW | Milestone carries no `## Parallelization Map` section. | Operator | Convention is not uniformly applied (1 of 6 recent milestones); non-blocking. | CHEAP |

**Rollback complexity: LOW overall.** Every change is additive-to-a-test or an in-place assertion fix; no data migration, no schema change, no governance surface, no new file. The one elevated-blast-radius surface is the two CI workflows (R-6), mitigated by sequencing them last.

**1 HIGH · 6 MEDIUM · 3 LOW.**

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints. Graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (`#4913` × `#5237` on `check-selftest-coverage.py` output):** One `--reconcile` run satisfies **both** limbs simultaneously — no `::warning::` naming `cleanup-orphan-state.sh` and enforced == discovered (`#4913`), **and** Arm D either names `ac3_concurrent_load.sh` or that file is wired or renamed (`#5237`). *Method:* `python3 release/tools/check-selftest-coverage.py --reconcile` — assert absence of `cleanup-orphan-state` in `::warning::` lines and presence of the Arm D disposition.

- [ ] **CIAC-2 (all nine cards — the release's own outcome statement, made gradable):** Every card whose acceptance criteria demand falsification records **both directions** — clean tree green, seeded defect red — in its Stage 7/8 evidence block. A card recording only the green arm has not demonstrated the release's After statement. *Method:* per-issue evidence carries a two-arm record; Stage 9 asserts 9 of 9 present.

- [ ] **CIAC-3 (`#4443` × `#5237` on the unwired-suite population):** After both land, every member of *committed test suites referenced by no workflow* is **either** wired **or** recorded as deliberately unwired with a stated reason — no member is silently carried. *Method:* diff Arm D's `UNWIRED SUITE:` listing against the recorded-exclusion set; the symmetric difference must be empty.

- [ ] **CIAC-4 (`#5272` × `#5273` on seed-vs-default distinguishability):** Both suites' fixture seeds differ from the shipped default they are asserted against, so no assertion can pass by coincidence. *Method:* extract each seed literal and compare against the corresponding template or generator default; assert inequality on both.

## Delivery Strategy

Single release branch `release/selftests-actually-test` off `origin/main` @ `8dc00db1`. The plan file lands as **Engineering Commit 0**, before any card's commits. Each card commits in the Implementation Sequence order above, referencing its source issue number in the commit message body. Force-push on the shared release branch is prohibited, including `--force-with-lease`.

## Verification Plan

Per-issue: each card's own acceptance criteria, verified by running the card's suite in both directions — unmutated (must pass) and mutated to break the behavior under test (must fail). Recording only the passing direction does not discharge the criterion.

Integration: `core/deploy/deploy.sh --check` for doc-link integrity on modified markdown; the two CI workflow files exercised by the PR's own check run.

Regression: the runtime suites mapped to the touched code paths, run under the `/tmp` `HOME`-override sandbox.

## Rollback Strategy

Every change is an in-place edit to a test, tool, workflow, or skill script. Revert is `git revert -m 1` on the release merge commit; no data migration, schema change, or governance surface is involved. The two CI workflow files are the only elevated-blast-radius surface — a bad edit there reddens every PR in the repo until reverted, which is one commit.

## Operational Deployment Manifest

No deployed-copy propagation target: this release edits test suites, repo tools, CI workflows, and skill scripts. The `finops-usage-extractor` script edits ride the normal skill-package rebuild beat if a rostered skill's `SKILL.md` or `references/` changes; no `SKILL.md` edit is planned, so no package rebuild is expected. Confirm at Stage 12.

## Verification Evidence

Populated by each Engineering spoke as its card lands, and by the plan-verification executor at Stage 6 Phase C4. Per the release outcome statement and CIAC-2, each per-issue block records both the unmutated-pass and the mutated-fail observation.

**How to read these blocks.** Every figure below is a transcribed measurement from a Stage 6, Stage 7 or Stage 8 run — no figure is derived, rounded, or inferred. **Unmutated** is the clean-tree arm the assertion must pass. **Mutated** is the arm that breaks the specific behavior under test and must fail; where a mutation is described as *targeted*, it reddens one named assertion while its siblings keep passing, which is what establishes that assertions bind to their real subjects rather than to a shared banner. **Counterfactual**, where present, runs the *pre-change* assertion against the *same* mutation, so the record demonstrates the defect and not merely the fix. **CI arm** records whether the authoritative CI locus executed; a CI arm that did not run is stated as unestablished rather than substituted with a local run. **Iteration** records arms added by the Stage-7 `fix(dt):` pass.

**Step-numbering basis, stated so every `step N` below is checkable against one source.** A `step N` is the Actions **jobs-API `steps[].number`** for the named job — the 1-indexed runtime step record returned by `GET /repos/{owner}/{repo}/actions/jobs/{job_id}`, which counts `Set up job`, the checkout and the prerequisite steps. It is **not** the index of the step inside the workflow YAML's `steps:` list, and **not** an index over only the suite-running steps. Two Stage-7 Pass-1 reports counted on different bases, which is how one card's arm came to be recorded at a step number belonging to another's. Under this basis a job's post-cleanup records carry non-contiguous numbers — `Shell harness (macOS)` runs steps 1–34 and then 68–69 — so a job's *step-record count* and its *highest step number* are different figures, and any `N of M` over steps must say which population it counts.

**Delivered-head anchor, defined so it does not go stale under later documentary commits.** Throughout this section, *the delivered head* means **`aa590212`** — the last head at which this release's **code** state changed, and the head every CI figure below is read at. It is not the superseded Stage-6 head `c7022376`. Commits landing above `aa590212` are documentary (`fix(dt): … [ADJUST]`, this plan file only), so no file any of the jobs named below executes differs between `aa590212` and the branch tip; a figure read here therefore still holds at the tip without being re-read. The two CI loci are `Install tests` → run `32801582953` → job `97663355998` `Shell harness (macOS)` (**36 of 36 step records `success`, 0 `skipped`**), and `Release tooling smoke` → run `32801582845` → jobs `97663355553` `Discovered tool self-tests (Ubuntu)` (**12 of 12 `success`, 0 `skipped`**) and `97663355638` `FinOps usage-extractor script self-tests (Ubuntu)` (**11 of 11 step records `success`, 0 `skipped`**). Where a bullet states an epoch (`on c7022376`), that statement is historical and retained as record.

**CIAC-2 tally: 9 of 9 cards carry a two-arm record.** All nine additionally carry at least one limb that is single-source, warn-only, or unexecuted — counted and stated, not glossed: each is named in *Arms not established* at the end of this section rather than being filled in.

#### `#5241` — status-label-invariant suite never reads its own subject
- **Unmutated:** 11 passed / 0 failed, exit 0. Reproduced three times independently — Stage 6, Stage 7 (fresh session, re-derived rather than accepted), and again after the Stage-7 `fix(dt):` here-string conversion.
- **Mutated (literal AC-2):** `deploy.sh` stubbed to a no-op — 5 passed / 6 failed, exit 1, leading with `subject never reached Check 16 — no banner in output`.
- **Mutated (targeted):** the I4 jq predicate broken alone — 9 passed / 2 failed, exit 1, with I1/I2/I3 still PASS.
- **Counterfactual:** the pre-fix suite under the byte-identical no-op mutation — 4 passed / 0 failed, **exit 0**. The defect, reproduced.
- **Iteration (`fix(dt):`):** jq guard forced to fire — 0 passed / 1 failed, exit 1 (fails closed); the pre-fix guard under the identical mutation prints `SKIP: jq unavailable` and exits 0 having run zero assertions. Targeted break of the converted here-string reader — 10 passed / 1 failed, exit 1, ten siblings green.
- **CI arm:** step 34 of `Shell harness (macOS)`. Did not run on `c7022376` — the job aborted at step 11. Re-enabled by the `fix(dt):` probe commit, and **run at the delivered head `aa590212`**: job `97663355998`, step 34 conclusion `success`, log line `status-label-invariant subject-execution suite: 11 passed, 0 failed`. The local Dev Testing run was the labelled fallback; the authoritative arm has since executed.

#### `#4441` — package-freshness PF-2 passes where no content verdict ran
- **Unmutated:** 11 passed / 0 failed / 0 skipped, exit 0. Reproduced at Stage 7 and again after the Stage-7 `fix(dt):` pass.
- **Mutated (degraded packager, content verdict intact):** the **old** suite exits **0** with PF-2 still PASS and its content assertion never run; the **new** suite exits **1** with PF-2b and PF-2c red, naming 55 degraded skills. Stage 7 reproduced this assertion-for-assertion through a *different* degradation mechanism.
- **Mutated (SKIP gate, truth table over the shipped expression):** the decisive row `(FAIL=0, SKIP=1) → 1`; the pre-change expression returns **0** on that same row.
- **Iteration (`fix(dt):`):** builder path made absent and the normalization branch forced — the head suite prints the builder's real last line; the pre-fix suite under the identical two mutations prints a **blank** in the same position, which is the `(last line: )` defect reproduced.
- **CI arm:** step 25 of `Shell harness (macOS)`, conclusion `skipped` on `c7022376`. Did not run; carried forward unestablished at Stage 7 rather than substituted. Re-enabled by the `fix(dt):` probe commit, and **run at the delivered head `aa590212`**: job `97663355998`, step 25 conclusion `success`, log line `test_package_freshness_exit_codes.sh: 11 passed, 0 failed, 0 skipped`.
- **What that CI arm does and does not establish (bounded deliberately).** It establishes that the *suite* now executes in CI. It does **not** establish the card's real blast-radius change — that a SKIP reddens CI — because `SKIP` was **0** on that run, so the `SKIP != 0` limb of the shipped exit expression was never entered. Stage 7 Pass 2 cited this same datum (`11 passed, 0 failed, 0 skipped`) as that chain having been *"observed in CI for the first time"*; **that claim is retracted here.** A run with zero skips is structurally incapable of discriminating a gate that fires only on `SKIP != 0`. The chain stays where Stage 7 Pass 1 put it — structural inference, plus the two falsifications that were run (the suite-level fixture and the expression-level truth table above) — and is listed under *Arms not established*. The Pass-2 comment on the release PR is left unamended as historical record.

#### `#4914` — work-hierarchy self-test pins neither the SKIP row nor the exit guard
- **Unmutated:** 71 passed / 71, exit 0.
- **Mutated (targeted ×2):** deleting the SKIP row fails **G1 alone**; deleting the exit guard fails **G2 alone**.
- **Counterfactual:** pre-change, at `909230dd`, *both* mutations returned **69 / 69, exit 0** — the deletes were green.
- **Derivation probe:** adding a fourth scan root keeps `configured - 1` green while hardcoding the same number reddens it, so the value is genuinely derived rather than shaped to look derived.
- **CI arm:** split across two workflows, and **both limbs have now run at the delivered head `aa590212`**. The A8 gate ran **12 / 12 step records `success`, zero `skipped`** in `Discovered tool self-tests (Ubuntu)` (job `97663355553`). The routed regression is step 31 of `Shell harness (macOS)` — `test_g1_form_family.sh`, which consumes this card's tool through `KIND_TOOL`. It did not run on `c7022376` (the step-11 abort); at `aa590212` it ran, conclusion `success`, `Result: 32 passed, 0 failed`, `G1 form-family scope regression: PASSED` (job `97663355998`).

#### `#5273` — re-bootstrap duplicate-key class has no runtime coverage
- **Unmutated:** 59 passed / 0 failed, both locally and in CI.
- **Mutated:** the suppression lever — 58 passed / 1 failed, duplicate count **2**. Limb 1 and limb 2 each redden **alone**.
- **Lever validity:** both forms of the card's literal lever are invalid and were measured as such — count **1** is a false green, count **0** never touches the duplicate direction. AC-3 is graded on the suppression lever for that reason.
- **Generalisation established at Stage 7:** a duplicate placed in a *different* section still reddens limb 1 (whole-file class), and the fail-closed dispatch was verified by execution rather than read.
- **CI arm:** step 12 of `Shell harness (macOS)` — its own designated A8 runner. Skipped on `c7022376`; did not run there. **Run at the delivered head `aa590212`**: job `97663355998`, step 12 conclusion `success`, log line `test_install_end_to_end.sh: 59 passed, 0 failed`.

#### `#5272` — refresh-hooks asserts a seed equal to the template default
- **Unmutated:** 45 passed / 0 failed, exit 0, with both `.mode preserved (operator choice)` and `mode template present (fixture precondition)` present. Reproduced independently at Stage 7 and again at the `fix(dt):` pass.
- **Mutated:** the `.mode` clobber — 44 passed / 1 failed, exit 1.
- **Counterfactual:** the prior hardcoded-seed assertion **PASSES** under the identical clobber that reddens the new derived-seed assertion.
- **Exhaustive limb:** the seed derivation was exercised across five template-default values (`warn`, `enforce`, `off`, `banana`, empty); seed ≠ default in all five, and the branch is binary, so this is exhaustive over the reachable space rather than a sample.
- **Iteration (`fix(dt):`):** the fixture-precondition assertion, previously justified by code reading, was falsified by mutation — with the shipped template renamed away it fails **alone** (44 / 1) while `.mode preserved` still reports PASS, which is exactly the vacuous pass the precondition exists to report.
- **CI arm:** step 13 of `Shell harness (macOS)`, conclusion `skipped` on `c7022376` (read from the Actions API, not inferred from the workflow file). **Run at the delivered head `aa590212`**: job `97663355998`, step 13 conclusion `success`, log line `test_refresh_hooks.sh: 45 passed, 0 failed (bash 3.2.57(1)-release)`, with `PASS: .mode preserved (operator choice)` and `PASS: mode template present (fixture precondition)` both present in that step's region. This is the **green arm only** — AC-2's red and counterfactual arms stay Stage-6-attested, and stay listed under *Arms not established*.

#### `#4913` — cleanup-orphan-state self-test is unreachable behind its boundary guard
- **Unmutated:** the reachability arms pass on the clean tree; the manifest regenerates to a stable projection proven by SHA, line count and partition delta.
- **Mutated:** five targeted arms, each reddening its own subject, **including a pre-fix counterfactual**; the wrong-order silent no-op was deliberately reproduced rather than argued.
- **CI arm:** ran, and discharged an open item — the SKIP ledger emits **8 of 16** in CI against **7** locally, and the 8th entry is one the local empty-bare-origin harness could not have produced. AC-4 limb (a) was upgraded from code-reading to measured on that evidence.
- **Iteration (`fix(dt):`):** the derived ADR index was stale — `SCANNED 42 / ROWS 41 / MISSING ADR-142`, gate red. Regenerated with the tool's own `--write`: `SCANNED 42 / ROWS 42`, COUNT 0, exit 0, and the `ADR-number integrity gate` is green on the post-fix head. Falsification is the projector's own and ran in both directions.

#### `#5237` — coverage Arm D is blind to suites not matching its filename pattern
- **Unmutated:** the shipped gate engine runs clean on the unmodified tree.
- **Mutated:** **four** targeted arms, each reddening **one** assertion alone, **plus an unmutated control**. The Stage-6 ladder is a five-**row** table whose first row is `M0 — none (control)` — exit 0, 36/36, baseline green — and whose four remaining rows are the reddening arms; that report's own prose reads *"these four are real reddening mutations against a real gate."* The population is four arms over a control, not five arms. Arm D population visibility **15 → 16**.
- **Decisive isolation (Stage 7):** the pre- and post-change engines were run against the *identical* shipped tree, and the **only** output delta across the whole run was the Arm D line.
- **Deviation reproduced, not accepted:** removing `is_file()` and `T-33c` together yields **35 / 35, exit 0** — nothing reddens — confirming the Stage-5 design had specified a guard no mutation could falsify, which is why the Stage-6 spoke added a third assertion.

#### `#4443` — three suites wired to nothing; the expensive one misdiagnosed as a hang
- **Unmutated:** all three newly-wired suites executed and succeeded in CI (`Shell harness (macOS)` steps 8, 9, 10) — they did not merely acquire a referrer, they ran. `--fast` executed for the first time in CI: `5 passed, 0 failed`, `T5 … PASS`, both `ARM REACH` PASS lines.
- **Mutated:** the timeout limb — 4 of 4 arms redden, each naming the affected suite. Structural block-scoped parse: 50 step blocks, each of the three newly-wired steps carrying exactly one owning `run:` step with `timeout-minutes: 5`; a fabricated suite yields 0 owning steps.
- **Census:** population **35** (33 `.sh` + 2 `.py`), **31/35 → 34/35**, sole remaining unwired suite `test_lib_instance_path.sh` (hub-excluded, own card). Sensitivity and specificity arms both fired.
- **Iteration (`fix(dt):`):** the falsification probe could not falsify — under `/bin/bash -e {0}` the intended non-zero exit was not in a tested context, so the step aborted before capturing it and the probe reddened the job exactly when a suite correctly detected the injected failure. Made a tested context. Control (untested shape, reduced) aborts before the capture; treatment captures the identical status and continues. `Workflow SAST (actionlint)`: 2 findings before, 0 after, measured with the CI flag; green on the post-fix head.
- **Iteration — the repaired probe kept its teeth (the arm that matters, three directions).** The bullet above records only that the fix *works*; this one records that it did not cost the probe its ability to object. Re-mutation of the shipped Arm-2 shape: **(A1)** shipped tested context + suite exits **1** → `Falsification OK`, tail reached, exit **0**; **(A2)** shipped tested context + **suite exits 0 despite the deliberately injected failing assertion** → `::error::… this suite's wiring cannot detect a failure`, `probe_fail=1`, **exit 1** — *the probe still reddens*; **(B1)** pre-fix untested shape + suite exits 1 → aborts before capture, no output — *the defect*. **Bounded, deliberately:** A1/A2/B1 were driven through a **reduced-shape re-implementation** of Arm 2 in a scratch context, not by pushing a suite that exits 0 under injection and observing the shipped workflow redden — see *Arms not established*. At the delivered head `aa590212` the shipped probe (step 11 of `Shell harness (macOS)`, job `97663355998`) emits **3** runtime `Falsification OK` lines — one per newly-wired suite, each naming its suite and its non-zero exit — and **0** probe-authored runtime `::error::` lines; the `::error::` matches inside that step's log are all source-echo, and were separated from the runtime output by group scoping rather than by a whole-log scan.

#### `#5239` — three finops sibling self-tests run in CI with no precision probe
- **Unmutated:** each of the three siblings passes on the clean tree; the shipped step bodies were executed **verbatim from the YAML** rather than paraphrased.
- **Mutated:** 12 local arms (3 subjects × verbatim / guard-2 specificity / anchor guard / blindness), each with a control; each subject reddens **alone** while the other two stay green in the same mutated tree.
- **CI arm:** ran, and is the one card in this bundle whose CI evidence is complete — a different workflow *and* job from the aborted `Shell harness (macOS)` one: `Release tooling smoke` → job `97663355638` `FinOps usage-extractor script self-tests (Ubuntu)`, at the delivered head `aa590212`. **Population, stated rather than implied:** the jobs API returns **11 step records** for that job — nine numbered 1–9, plus the two post-job records numbered 18 and 19 — and **11 of 11 are `success`, 0 `skipped`**. The **9 / 9** figure counts the **nine non-post steps (numbers 1–9)**, five of which are `Precision probe` steps (two pre-existing, three added by this card); each probe's log line carries the subject's real exit code.
- **Iteration (`fix(dt):`):** no code change. A claim about this card was falsified at Stage 7 — that an unprefixed marker would have shipped three permanently-passing probes. Measured, the steps still exit 1 via guard 1; the prefix protects guard 2's wrong-reason discrimination. Retracted in the PR body's Summary. This card's entry under *Arms not established* is a separate matter (the unmeasured base-vs-head differential).

### Arms not established

Stated rather than implied, per the release's own outcome statement. Each of these is a limb that was **not** measured; none is filled in with a substitute. An entry marked **DISCHARGED** was subsequently established at the delivered head and is retained here as record rather than deleted, so the sequence stays readable — an unmarked entry is still open.

- **`#5237`** — Arm D is warn-only, so its exit code is invariant: 0 before, 0 after, and still 0 if the widening were wrong. AC-1 is gradable on the `UNWIRED SUITE:` line and the population delta, never on the exit code, the green CI, or the absence of a warning.
- **`#4443`** — the `--fast` path was never executed at authoring time; a script-execution control refused all three subject suites and the spoke abandoned and surfaced rather than editing the allowlist. CI was its first execution, and it passed — but one of those five assertions (`GUARD 2`) self-labels a **vacuous PASS** on CI, so the tally is 4 substantive + 1 vacuous.
- **`#4443` (the probe's own reddening arm, *on CI*)** — that the repaired falsification probe still reddens was established by a **reduced-shape re-implementation** of its Arm 2 in a scratch context, in all three directions. It was **not** established by mutating a wired suite to exit 0 under injection, pushing, and observing `Shell harness (macOS)` go red; both Dev Testing and QA are scope-barred from mutating tracked source and pushing. The shipped chain (`|| rc=$?` → `if [ "$rc" -eq 0 ]` → `::error::` → `probe_fail=1` → `exit "$probe_fail"`) is directly readable and the reduced shape drove exactly that chain in both directions, so this is a bounded limitation on the *locus* of the measurement, not an unmeasured claim.
- **`#4441` (the SKIP → red-CI chain)** — the card's real blast-radius change, that a skipped assertion now reddens CI, has **never been observed in Actions**. The CI arm that has now run (step 25 at `aa590212`, `11 passed / 0 failed / 0 skipped`) reports **0 skips**, so the `SKIP != 0` limb was never entered; on a healthy runner the one reachable skip site does not fire. Carried as structural inference plus the two falsifications that were run — the suite-level fixture (`8/0/1 exit 0` → `10/0/1 exit 1`, siblings byte-identical) and the expression-level truth table (decisive row `(FAIL=0, SKIP=1) → 1`; the pre-change expression returns **0** on that same row). Stage 7 Pass 2's contrary claim is retracted in the `#4441` block above.
- **`#4913`** — a local SKIP count is a harness artefact of an empty bare origin, not what CI emits; AC-2 is carried on Stage-6 evidence and was not upgraded at Stage 7.
- **`#5239`** — no base-vs-head differential was measured for the long-running check, so "pre-existing" is strong inference rather than a measured delta.
- **`#5272`** — AC-2's red and counterfactual arms are Stage-6-attested and were not independently re-established at Stage 7, because reproducing them requires mutating source and the Dev Testing spoke is scope-barred from doing so. The green arm was independently reproduced.
- **`#5273`** — the **false-green** form of the card's literal lever (schema flip against a prior config already carrying `[automation]`, count 1, suite 59/0) was not independently reproduced; it needs a bespoke pre-seeded fixture whose construction would change the subject under test. Carried from Stage 6 as-stated. Separately, AC-2's *"a successful TOML parse"* is delivered as the operator-ratified **shape** parse: the shipped limb pair **admits** `automation_level = "off` (unterminated string), `custom_array = ["a", "b"` (unclosed array) and `k =` (empty value), all of which `tomllib` rejects, and **rejects** `"quoted.key" = 1`, which is valid TOML. Tightening the predicate is explicitly out of scope — it is a design decision, and the Stage-5 blast radius is a job that gates every pull request in the repository.
- **`#5241` · `#4441` · `#4914` · `#5272` · `#5273` — DISCHARGED at `aa590212`.** Each card's CI arm sat at a step of `Shell harness (macOS)` (34, 25, 31, 13, 12 respectively, on the numbering basis stated at the head of this section) that the step-11 abort skipped, so none of the five ran on `c7022376`. Every affected spoke carried the arm forward as unestablished and labelled its local run a fallback. The `fix(dt):` probe repair re-enabled all five, and **all five have since run green at the delivered head** — run `32801582953`, job `97663355998`, **36 of 36 step records `success`, 0 `skipped`**: step 34 `11 passed / 0 failed` · step 25 `11 passed / 0 failed / 0 skipped` · step 31 `32 passed / 0 failed` · step 13 `45 passed / 0 failed` · step 12 `59 passed / 0 failed`. Discharging the *execution* limb does not discharge `#4441`'s SKIP-direction limb or `#5272`'s red/counterfactual limbs, which have their own entries above.

## Hub-Rendered D-Decisions

| # | Decision | Verdict | Reversibility |
|---|----------|---------|---------------|
| D1 | Release plan approved; scope committed | **APPROVED** — Composition amended as a sequence, recorded here in full because two of its three figures are quoted elsewhere: **10 issues / 24 pts → 9 issues / 22 pts** at D1 (dropping `#5238`) **→ 9 issues / 20 pts** once D3's `size:M` → `size:S` re-label lands in the same amendment. **20 pts is the effective total**, and is the figure carried by the Header `Raw points` row, `## Scope`, D3 below, and the milestone's `## Composition` and `### Composition Amendment` blocks. Every figure in the sequence sits inside the 15–25 pt band, so no step was out of band. | MODERATE · HIGH |
| D2 | Release Class | **`routine`** — confirms the Stage 3 declaration. Rests on the zero-new-files trigger; the *≥1 D-class decision* trigger fires mechanically on every release via the recurring version and concurrency-posture entries, and is treated as non-discriminating. | CHEAP · MEDIUM |
| D3 | `#5273` scope | **RE-SCOPED** to *add two limbs to the existing re-bootstrap block*; `size:M` → `size:S`. Release effective total → 20 pts (in band). | CHEAP · MEDIUM |
| D4 | `#5272` AC-3 discharge | **RECORD-ONLY** — discharged by recording the sibling-collapse finding rather than editing that file under `#5272`. Dissolves the cross-card write collision. | CHEAP · MEDIUM |
| D-Version | Version selection | **minor bump**; next-free recomputed at Engineering Commit 0 as **v4.39** against tags, ledger rows, and published Releases. The number binds only at the Stage-12 atomic claim. | CHEAP · HIGH |
| D-Concurrency | Concurrency posture | **P0 fully-serial** — force-push on the shared release branch prohibited, including `--force-with-lease`. | CHEAP · HIGH |

## Deviation Log

Recorded per spoke as deviations arise. A deviation is flagged, never silently taken.

## Change Description

A self-test that passes now proves the behavior under test actually ran. Nine defects were fixed
across nine commits, each one an assertion that reported green without being able to report anything
else.

**What changed, by class of blindness closed:**

| Card | The gate could not fail because… | What now makes it falsifiable |
|---|---|---|
| `#5241` | the suite passed with its subject stubbed to a no-op | it executes the real subject and asserts against real output |
| `#4441` | a SKIP was indistinguishable from a pass | `SKIP != 0` gates the exit, plus a positive and a negative discriminator limb |
| `#4914` | two pinned behaviors could be deleted with the suite still green | each is pinned independently and reddens its own case alone |
| `#5273` | the exactly-once predicate had never been exercised in the `>1` direction | two limbs assert whole-file `(section, key)` uniqueness and TOML shape |
| `#5272` | the seed equalled the template default equalled the asserted value | the seed is derived at run time as a legal mode that differs from the shipped default |
| `#4913` | the self-test was unreachable behind a boundary check that hard-exits | the boundary predicate accepts the script's own physical checkout root |
| `#5237` | the coverage arm was blind to suites whose filename did not match its pattern | the glob is widened and the extraction is testable |
| `#4443` | three suites were committed and invoked by nothing | they are wired, with the expensive arm split behind a fast selector and a bounded timeout |
| `#5239` | three sibling self-tests ran in CI with no precision probe | each carries a probe matching the two instances already established in that file |

**Cross-cutting properties of the change set.**

Every card was verified by **mutation, not inspection**: the assertion was shown to FAIL under a change
that breaks its specific subject and PASS unmutated, with both results recorded. Where a card fixed an
assertion that previously could not fail, a **counterfactual arm** was additionally run — the *old*
assertion against the *same* mutation — to demonstrate the defect rather than merely the fix.

Mutations are **targeted**: each reddens one assertion while its siblings continue to pass, which
establishes that assertions bind to their real subjects rather than to a shared banner.

**Three defects of the release's own class were caught inside the fixes for it, before commit**: a guard
no mutation could falsify; a comment that duplicated an exit-contract literal and would have silently
disabled a shipped CI probe; and three probes whose markers matched a green run and would therefore have
passed permanently. Each was found by the author mutating their own work.

**Premise corrections.** Three cards carried premises that were false on live mainline, established by
measurement rather than assumed: `#4913`'s stated mechanism (the real defect is reachability, not
hermeticity); `#4443`'s "hangs indefinitely" (it terminates near 42 minutes and was killed at
approximately its own completion time); and `#5273`'s "no runtime coverage" (coverage shipped six days
before the card was filed — the residual is that the coverage itself had never been shown able to fail
in the direction that mattered). Issue bodies were left unamended as historical record; the corrected
premises live in the Stage 5 and Stage 6 records.

**One architectural decision was recorded.** `#4913` retains a guard ordering that diverges from the
convention two sibling tools follow, because the rejected alternative would strip the only barrier on
the one self-test in the corpus that performs real destructive git operations. Unrecorded, the next
reader reverts it and reopens the defect.

**Scope discipline.** Findings surfaced outside the locked bundle were routed rather than absorbed:
four follow-up work items were filed, and one security finding is handled fix-forward outside this
release. No card widened past its acceptance criteria; one design that specified four wiring targets was
held to the three its own AC names.

## Issue References

Members of this release: #5241, #4441, #4914, #5273, #5272, #4913, #5237, #4443, #5239. Each is transitioned to closed at Stage 13 per the block-close protocol; no close-family verb appears against these numbers anywhere else in this document.
