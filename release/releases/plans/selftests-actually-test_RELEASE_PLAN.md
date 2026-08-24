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

## Hub-Rendered D-Decisions

| # | Decision | Verdict | Reversibility |
|---|----------|---------|---------------|
| D1 | Release plan approved; scope committed | **APPROVED** — Composition amended 10 issues/24 pts → 9 issues/22 pts | MODERATE · HIGH |
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
