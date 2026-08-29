---
title: Release Plan — warn-mode-gate-graduation
purpose: Stage-4 release plan for the five warn-mode-gate cohort defects — a warn-mode gate cohort can terminate, because every gate that declares a warn posture either has a readable advance signal or carries a recorded, architecturally-grounded disposition.
type: release-plan
plan_type: release
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Release Plan: warn-mode-gate-graduation — The Warn-Mode Gate Cohort Can Terminate

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against tags, published Releases, ledger rows, and in-flight sibling holds; anchor tag **v4.43**, recomputed next-free **v4.44**, free at Commit 0 (no tag, no `RELEASE_LOG` row, no `plans/v4/` file). |
| **Date Created** | 2026-08-28 (Friday) |
| **Commit-0 Date** | 2026-08-29 (Saturday) — the `${AUDIT_DATE_UTC}` / `${DECISION_DATE_UTC}` resolution instant for every load-bearing date this release writes |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/warn-mode-gate-graduation` |
| **PR** | opened as a DRAFT after the first Engineering spoke's commits; the release ships as a SINGLE PR with one merge gate |
| **Milestone** | `warn-mode-gate-graduation` (#313) |
| **Release Class** | `routine` — retained at the Stage-4 D-2 gate **with a posture divergence** (below) |
| **Composition** | capability-slice; Frame F1 (SAFe Feature-Slicing + Vertical Slice) |
| **Effective points** | **18** across **5** issues — 14 at bundling, plus 4 when #6298 was added at plan approval (D-3). Inside the 15-25 band and under the G3-15 bound of ≤ 25. |
| **Branch topology** | **SINGLE** — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** — rule-determined by the default-when-undeclared clause plus a 4-way contention on `core/deploy/deploy.sh`. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `e19a9d30682abefac51cca1ff8aa0ebbf8708593` — the pinned baseline; every Engineering spoke branches from it |

**Stamp manifest.** The `**Version**` cell above is a machine-read manifest, not prose. It carries the literal `{{RELEASE_VERSION}}` token, which the Stage-12 claim resolves at the merge SHA while renaming this file to `release/releases/plans/v4/vX.Y_RELEASE_PLAN.md`. Asserted read-only at Commit 0 by `release/tools/claim-version.sh --verify-stamp warn-mode-gate-graduation`; a plan that fails that assertion is never committed, because Stage 12 could then neither resolve the version nor complete the rename.

## Release Outcome Statement

**AFTER** this release: the warn-mode gate cohort can terminate. Every gate in the cohort either has an advance signal a pull-request agent can read, or carries a recorded disposition whose grounds are stated and durable.

**BEFORE:** the cohort's advance signal is a git-ignored per-check `*-warn-log.jsonl` that no PR agent can read, so `shakedown continues` is unfalsifiable and self-perpetuating. Two of the three named drain sinks are never written at all. The G3-14 / G3-15 bundle-metrics gates have **no runner on any surface** — zero executable artifacts implement either predicate — so their `warn → enforce` ladder has no rung to stand on. The shared `deploy-check-warn-log.jsonl` grows without bound (94,559,661 B / 385,770 rows at the pin). Requirement (b′) blocks `posture: required` for every deploy-time-only member.

*Amended 2026-08-29 (Saturday), D-8:* the Stage-4 framing had #4214 owning the G3-14 / G3-15 evaluator via its AC3. #4214's Stage-5 spec asked to retire that AC as unsatisfiable and ships 0 new files / 0 new checks; #6298's spec had planned to consume it. Under both specs as written, nobody built the evaluator. D-8 resolves ownership to **#6298**, which lands **first**.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Layer | Size | Stage 5 |
|---|-------|---------------------|-------|------|---------|
| 1 | #6298 | bundle-metrics gate integrity — CI runner for G3-14 / G3-15 | infrastructure | M (4) | APPLIED |
| 2 | #4214 | warn-mode declarations must name a written sink | foundation | M (4) | APPLIED |
| 3 | #5588 | shared warn-log lifecycle (rotation + orphan disposal) | infrastructure | S (2) | APPLIED |
| 4 | #4751 | enforce-flip disposition for the two new gates + sibling ids | governance | M (4) | APPLIED |
| 5 | #1686 | `g1-enforcement` warn → enforce flip | governance | M (4) | APPLIED |

Effective scope is **5 members / 18 pts**. Stage 5 activation is **ALL** per the D-2 posture divergence — no member took the `SKIP-where-trivial` path.

### Ratified premise corrections (D-1, D-3, D-8, D-9)

These supersede the corresponding text in the Stage-4 planning comment. The superseded text is **not** transcribed here.

1. **#4214 is a 2-of-3 fix, not 3-of-3.** `deploy-check-warn-log.jsonl` **is** written continuously — 94,559,661 B / 385,770 rows / 62 distinct check ids at the pin. Only the two `gate-g3-*` sinks are genuinely absent.
2. **The #4214 → #1686 edge is soft, not hard.** #1686's drain evidence already exists at scale in the shared log (180,052 `g1-enforcement` rows in the three row shapes its AC1 requires). The native dependency mirror already carried no such edge. Sequencing is retained for register-row form and 3-way table contention only.
3. **Membership is 5, not 4; effective points 18, not 14.** #6298 was created and added at plan approval (D-3).
4. **#4751's gates are Checks 66 / 67** — not `g3-14` / `g3-15`. #6298 does **not** unblock #4751.
5. **Zero gates flip warn → enforce this release.** The Outcome Statement is satisfied by recorded decisions and by a real blocking pre-merge assertion that arms no flip. A recorded deferral is a decision.
6. **G3-14 / G3-15 have no runner at all** (D-8) — they are class-3 prose-declared normative predicates, not deploy-time-only automated gates. The Stage-4 "deploy-time-only" framing was a hub error, independently re-measured by three parties.

## Release Class

**`routine`** — retained at D-2. Trigger (b) fires cleanly and was measured, not assumed: every declared change-spec file carries ≥ 3 prior release touches (6-month commit counts — `deploy.sh` 292 · `gate-criteria-spec.md` 66 · `gate-efficacy-standard.md` 45 · `bypass-mode-readiness.md` 34 · `progressive-rollout-convention.md` 4). Trigger (a) does not fire (#4214 is P2-High). Trigger (c) holds — zero unconditional new workflow files.

**Posture divergence (D-2), adopted from the `novel` tier:**

| Dimension | `routine` default | **In force** | Why |
|---|---|---|---|
| Engagement density | Light | **Light** (concur) | Bounded, single-capability |
| Stage 9 review depth | Standard | **DEEP for any card that actually flips a gate** | Premature-flip blast radius is EXPENSIVE (#1686) and corpus-wide (#4751); `routine`'s low-blast-radius default does not hold for a flip card |
| Stage 5 activation bias | SKIP-where-trivial | **ALL** | Design uncertainty is surfaced, not met-by-letter |
| Stage 13 outcome-window | 30-day | **30-day** (concur) | — |

**The DEEP trigger is card-scoped, not release-scoped.** It fires only on a card that actually flips a gate. Rendered at D-8: it does **not** fire on #6298, whose AC set is satisfiable with the `deploy-check-ci.enforce` sentinel still reading `warn`.

## Implementation Sequence

**D-8 order — fully serial on one branch:**

**#6298 → #4214 → #5588 → #4751 → #1686**

| Position | Issue | Pts | Rationale |
|---|---|---|---|
| 1 | **#6298** | 4 | Builds the tree-resident G3-14 / G3-15 integrity evaluator and its CI entry point. Lands first so #4214's deadline-arm reader has an entry point at its own commit and no transient Check-62 WARN occurs. Also lands Engineering Commit 0 (this plan). |
| 2 | **#4214** | 4 | Sink-naming convention + the flip-register row form both downstream cards consume. Ratified **DEFERRED WITH A DEADLINE** (D-9); its deadline-arm reader rides #6298's entry point. |
| 3 | **#5588** | 2 | Retention contract must settle before either register-editing card lands — the drain's consumption horizon is the floor for the rotation ceiling (CIAC-1). Scope is live file + orphan disposal (D-10 / D-4); backup amplification routes to a follow-up. |
| 4 | **#4751** | 4 | Enforce-flip disposition for Checks 66 / 67 + the sibling-id cohort. Consumes #4214's register-row form. |
| 5 | **#1686** | 4 | `g1-enforcement` flip decision. Sequenced last for register-table contention and convention coherence, not for evidence. |

**Branch topology D-C: SINGLE** — one release branch, one PR, one merge. The `#4214 → #1686` edge is soft; the `#4214 ↔ #5588` coupling is a contract, not a sequence edge.

## Stage Applicability Matrix

| Issue | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| #6298 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #4214 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #5588 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #4751 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #1686 | YES | YES | YES | YES | YES | YES | YES | YES | YES |

**No stage skips for any member.** Every member edits `core/deploy/deploy.sh`; gate posture and log lifecycle are both functional behavior. Nothing here is documentation-only, so the Stage 7/8 no-functional-impact skip is unavailable to all five.

## File Change Matrix

```
# -- #6298 -- bundle-metrics gate integrity (Check 73 + fixture suite) --
core/deploy/deploy.sh                                            edit
core/deploy/tests/test_check73_bundle_metrics_discrimination.sh  add
core/deploy/tests/fixtures/bundle-metrics/g3-14/                  add
core/deploy/tests/fixtures/bundle-metrics/g3-15/                  add
core/config/allowlists/script-execution-allowlist.txt            edit
.github/workflows/install-tests.yml                              edit
.github/workflows/deploy-check-ci.yml                            edit
.github/deploy-check-ci.enforce                                  edit
core/standards/gate-efficacy-standard.md                         edit

# -- #4214 -- drain-sink convention (re-cut to the 2 genuinely-absent sinks) --
core/deploy/deploy.sh                                            edit
core/standards/gate-efficacy-standard.md                         edit
core/schemas/gate-criteria-spec.md                               edit

# -- #5588 -- shared warn-log lifecycle --
core/deploy/deploy.sh                                            edit

# -- #5588 -- CONDITIONAL on the Stage-5 prune-tool branch --
core/deploy/tools/prune-warn-log.sh                              CONDITIONAL:stage5-selects-prune-tool-branch
core/config/allowlists/script-execution-allowlist.txt            CONDITIONAL:stage5-selects-prune-tool-branch

# -- #4751 -- enforce-flip decision, Checks 66/67 + sibling ids --
core/deploy/deploy.sh                                            edit
core/standards/gate-efficacy-standard.md                         edit
core/standards/progressive-rollout-convention.md                 edit

# -- #1686 -- g1-enforcement.mode flip --
core/deploy/deploy.sh                                            edit
core/standards/gate-efficacy-standard.md                         edit
core/rules/bypass-mode-readiness.md                              CONDITIONAL:bypass-checklist-governs-deploy-check-modes
```

### Read-only inputs

```
core/schemas/gate-criteria-spec.md                            READ
release/references/standards/bundle-composition-doctrine.md   READ
core/standards/progressive-rollout-convention.md              READ
core/rules/git-workflow.md                                    READ
release/references/specs/release-class-taxonomy.md            READ
release/references/standards/quota-budget-protocol.md         READ
```

**New-executable companion obligation.** `core/deploy/tests/test_check73_bundle_metrics_discrimination.sh` is a new executable; its `core/config/allowlists/script-execution-allowlist.txt` row lands in the **same commit**, per the precedent both `test_check45_*` and `test_version_freeness_injection.sh` carry. #5588's conditional `prune-warn-log.sh` row is declared under the same token as its own allowlist companion, so if that branch fires both promote together.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-29, domain: governance }`

Sourcing-exempt — every matrix path is an internal pmo-platform artifact — and domain-classified `governance`.

## Contention Map

| Path | Class | Claimants |
|---|---|---|
| `core/deploy/deploy.sh` | **MULTI-WAY x5** | #6298, #4214, #5588, #4751, #1686 |
| `core/standards/gate-efficacy-standard.md` | **MULTI-WAY x4** | #6298, #4214, #4751, #1686 |
| `core/config/allowlists/script-execution-allowlist.txt` | single (+1 conditional) | #6298; #5588 conditionally |
| `core/schemas/gate-criteria-spec.md` | single | #4214 |
| `core/standards/progressive-rollout-convention.md` | single | #4751 |
| `core/rules/bypass-mode-readiness.md` | single, **CONDITIONAL** | #1686 |
| `core/deploy/tools/` | single, **CONDITIONAL** | #5588 |

**The sharpest contention is the table, not the file.** Four cards write rows into the same markdown register in `gate-efficacy-standard.md`. Serial commits resolve the mechanical conflict; CIAC-2 is what makes the resulting table coherent rather than merely conflict-free.

**Concurrent-release note (D-17).** PR #6353 (`release/declarations-have-a-firing-surface`, draft) is building concurrently and collides on 4 of this release's surfaces, including `core/deploy/deploy.sh` and `core/standards/gate-efficacy-standard.md`. The operator decided to proceed on the pinned baseline and reconcile at **Stage 9 Phase A6.5**. No spoke merges, rebases onto, or coordinates with that branch.

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#4214 x #5588 — the retention contract on `core/deploy/deploy.sh`):** the rotation/prune ceiling #5588 introduces is >= the drain consumption horizon #4214's sink contract depends on, and both cards read the same declaration site rather than either carrying a literal. *Method (**ratified replacement** — the Stage-4 form returned 3 hits, all comment prose, and was ungradeable): assert `WARN_LOG_RETENTION_DAYS >= SKILL_SUITE_GATE_ESCALATE_DAYS` — two symbols, one declaration block, no literal in either card. The shared read symbol is `warn_log_segment_set()`.* Graded at Stage 9 QC3.5 on the merged PR.

- [ ] **CIAC-2 (#6298 x #4214 x #4751 x #1686 — the `gate-efficacy-standard.md` flip-decision register):** after the merge the register contains one row per cohort member touched by this release, each carrying a disposition from the closed set {flipped · shakedown-continues · DEFERRED-precondition-blocked · RATIFIED-ADVISORY · DEFERRED-WITH-DEADLINE · SPLIT-DISPOSITION}, and no member is left without a row. *Method:* extract the register table; assert every id named in #4751's enumeration, plus `g1-enforcement` and the G3-14 / G3-15 pair, resolves to exactly one row with a non-empty disposition cell; control arm — a fabricated id must resolve to zero rows. Graded at Stage 9 QC3.5 on the merged PR.

- [ ] **CIAC-3 (#4214 x #4751 x #6298 — the sink-naming convention):** every gate this release holds at warn names a sink that #4214's convention requires to be written, so the held row is satisfied *using* the convention rather than independently of it. *Method:* for each held row, assert the named sink path appears in the convention's written-sink declaration set in `core/standards/gate-efficacy-standard.md`; a held row naming a sink absent from that set is NOT MET. #6298's Check 73 conjunct C73-b is the forward-going mechanical enforcement of the same relation. Graded at Stage 9 QC3.5 on the merged PR.

CIAC-1 is the highest-value of the three: it is the only predicate that prevents #5588 from resolving itself by breaking #4214.

## Verification Plan

**AC baseline:** #6298 → 5 criteria · #4214 → 5 · #5588 → 5 · #4751 → 4 · #1686 → 7 (+4 superseded, excluded). **Total 26.**

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #6298 | AC-1 | Discrimination pair, anchored at `bash core/deploy/tests/test_check73_bundle_metrics_discrimination.sh`: invert the `_g3_14_compute_verdict` floor comparison → the at-floor fixture returns BREACH and the run exits non-zero; restore → exits clean. The verb sits outside this executor's read-only allowlist, so the row reports an honest SKIP naming `bash`; the pair is run and recorded in the PR evidence block at Stage 7 | Seeded run exits **non-zero**; control run exits **0** with four arms executed and one opposite-verdict pair per gate |
| #6298 | AC-2 | Both runner declarations are tree-resident: `grep -lE "Pre-merge load-bearing check subset\|Run Check 73 bundle-metrics discrimination fixtures" .github/workflows/deploy-check-ci.yml .github/workflows/install-tests.yml` — exactly 2 files match. The live checks-list read on the open PR stays a reviewer action | Contexts **"Pre-merge load-bearing check subset"** and the `install-tests` shell-tests job both present and reporting (both workflows filter-free, so neither can be absent) |
| #6298 | AC-3 | Workflow-denominator probe: `grep -rlE "test_check73_bundle_metrics_discrimination" .github/workflows` — at least 1 workflow file references the runner (was 0). Specificity arm: the same probe over a fabricated `g3-99` id returns no files | Target **≥ 1** (was 0); sensitivity `deploy.sh` > 0; specificity `g3-99` = 0 — all three reported. Strengthened arm asserts R1 ∧ R2 reachability with an inverting control |
| #6298 | AC-4 | Every coverage-register row carrying the Check 73 runner-def also carries the required posture on the same row: `grep -cE "runner-def: core/deploy/tests/test_check73.*required \(warn-mode-initial\)" core/standards/gate-efficacy-standard.md` — exactly 3 rows (G3-14, G3-15, C73-b); the runner-def alone also counts 3, so no row is left at advisory | `posture` reads **`required (warn-mode-initial)`**, not `advisory`; each names its CI job |
| #6298 | AC-5 | No workflow gained a bare full-sweep invocation: `grep -rcE "^[^#]*deploy[.]sh[[:space:]]+[-]{2}check([[:space:]]\|$)" .github/workflows` — expect 0. The two-dash token is written as an ERE bracket form so the row classifies per-issue instead of colliding with the sync family's keyword. Control arm: dropping the trailing boundary, so the pattern also admits the `-required-subset` form, returns 6 — the zero is a measured absence, not a dead pattern | **0** — only the existing `--check-required-subset` and the fixture suite are invoked; no full `--check` sweep enters CI |
| #4214 | AC-1 | [DEFERRED] verification deferred to #4214 — the written-sink declaration set is #4214's own deliverable and is absent from `core/standards/gate-efficacy-standard.md` at this commit (measured: 0 occurrences). #4214's Engineering spoke renders this row executable at its own commit, naming the token it introduces | Every declaring gate writes, or carries a recorded deadline-armed deferral |
| #4214 | AC-2 | [DEFERRED] verification deferred to #4214 — the convention clause does not exist at this commit. Its spoke replaces this cell with `grep -c "<clause-token>" core/standards/gate-efficacy-standard.md`, at least 1, once the token is chosen | Convention clause present |
| #4214 | AC-3 | [DEFERRED] verification deferred to #4214 — the D-9 deadline-arm reader resolves against #6298's Check 73 entry point, which landed at this commit; the reader itself is #4214's deliverable and is not yet in the tree | Deadline-arm reader resolves against #6298's Check 73 entry point |
| #4214 | AC-4 | [DEFERRED] verification deferred to #4214 — the register evaluation depends on the row form #4214 introduces; no cohort row carries that form at this commit | Every row resolves to flipped, or to a deferral whose blocker is no longer "signal not derivable" |
| #4214 | AC-5 | [DEFERRED] verification deferred to #4214 — one-row-per-cohort-member becomes assertable only after the row form lands; graded jointly with CIAC-2 on the merged PR | One row per cohort member |
| #5588 | AC-1 | Direct unbounded appends to the shared warn log: `grep -cE '>>[[:space:]]*"[$](WARN_LOG\|_rfc_warn_log)"' core/deploy/deploy.sh` — expect 0 once #5588's bounded writer lands. 12 at this commit, so the probe is live rather than vacuous | Zero unbounded direct appends · **control:** `pmo_instance_path` → 19 refs (non-zero) |
| #5588 | AC-2 | [DEFERRED] verification deferred to #5588 — driving appends past the ceiling needs a sandbox run, which sits outside this executor's read-only verb allowlist; run and recorded at Stage 7 | Size / line count stops growing |
| #5588 | AC-3 | [DEFERRED] verification deferred to #5588 — the rotation boundary does not exist at this commit; drain survival is graded with CIAC-1 on the merged PR | No records the drain needs are lost (CIAC-1) |
| #5588 | AC-4 | [DEFERRED] verification deferred to #5588 — the criterion admits either silence removal or a documented accepted risk, a disjunction no single mechanical probe can settle; #5588's spoke records which limb it took and renders the matching assertion | Silence removed, or documented accepted risk |
| #5588 | AC-5 | Run `./deploy.sh --check` | Green |
| #4751 | AC-1 | [DEFERRED] verification deferred to #4751 — no register row names Check 66 or Check 67 at this commit (measured 0), so the decision, finding count and measured population have no surface to read yet | Checks 66 / 67 each carry a decision + finding count + measured population |
| #4751 | AC-2 | [DEFERRED] verification deferred to #4751 — the sibling-id enumeration is graded against rows #4751 has not yet written; re-scoped to 8 undisposed + 3 cross-referenced per Stage-4 R6 | All covered — **re-scoped to 8 undisposed + 3 cross-referenced** (Stage-4 R6) |
| #4751 | AC-3 | [DEFERRED] N/A by ratified premise 5 — zero gates flip warn → enforce this release, so there is no flipped gate to fixture-fail. Recorded as N/A rather than passed, which is what the criterion's own wording instructs | Real failure demonstrated — **N/A if no gate flips**, recorded as such rather than passed |
| #4751 | AC-4 | [DEFERRED] verification deferred to #4751 — the ending-condition-and-sink pair on each held row is #4751's deliverable; graded with CIAC-3 on the merged PR | Names the ending condition **and** the sink (CIAC-3) |
| #1686 | AC-1 | [DEFERRED] verification deferred to #1686 — the shared warn log is git-ignored and lives outside the tree this executor reads. Already MET at plan time, with the counts alongside measured at the operator instance | **Already MET at plan time** — 45 days; gating 148,324 / recommend 31,426 / advisory 302 |
| #1686 | AC-2 | [DEFERRED] verification deferred to #1686 — same instance-local log as AC-1, and the classification is a judgment over row shapes rather than a tree-resident assertion | Zero unresolved false positives; recommend-tier counted separately and excluded |
| #1686 | AC-3 | [DEFERRED] verification deferred to #1686 — running the Check-22 region is a deploy-time execution, outside this executor's read-only verb allowlist | Post-filter finding count 0 · **control:** seed a defect → count > 0 |
| #1686 | AC-4 | [DEFERRED] verification deferred to #1686 — already MET at plan time (0 findings, control 190/190); re-running the evaluation region is a deploy-time execution this executor cannot perform | **Already MET at plan time** — 0 findings (control 190/190 rows matched the issue-# shape) |
| #1686 | AC-5 | [DEFERRED] verification deferred to #1686 — driving the four resolver verdicts is an execution, not a read; run and recorded at Stage 7 | Invalid case BLOCKS |
| #1686 | AC-6 | [DEFERRED] verification deferred to #1686 — the disclosure line is #1686's own deliverable and is absent from the tree at this commit | Names the intended release + milestone-set denominator |
| #1686 | AC-7 | [DEFERRED] verification deferred to #1686 — seeding a structural G1 defect and running at `enforce` is an execution; ratified premise 5 additionally holds that no gate flips this release, so the enforce arm has no armed gate to run against | Blocks on seeded; passes clean |

**Method-rendering obligation (the rows above are authored incrementally, like the Change Description).** Every method cell is mechanically classifiable by `release/tools/verify-release-plan.sh`, so no row can reach Stage 7 as an unreadable ERROR. A cell reading `[DEFERRED]` is a **standing obligation on the named card's Engineering spoke**, not a waiver: that spoke replaces its own rows with executable assertions **at its own commit**, when it knows the tokens its implementation introduces. Rendering them earlier would mean inventing symbol names for unlanded work and binding the implementation to a guess.

**Stage-7 entry condition.** Dev Testing does not accept a deferred row for a card that has landed. Before Stage 7 opens, every `[DEFERRED]` cell whose owning card is merged must have been replaced; the residual deferrals permitted at Stage 7 are only those whose subject is genuinely unreachable from a read-only tree probe — the instance-local warn log (#1686 AC-1 / AC-2), executions outside the executor's verb allowlist, and #4751 AC-3, which is N/A by ratified premise 5. A run whose SKIP count has not fallen as cards land is the signal that this obligation was skipped.

**Seeded-failure discipline.** Every card delivering an entry point ships a seeded-failure run **and** a passing control run in the same evidence block. An entry point that cannot be made to fail is not a gate, and a green run alone does not distinguish the two.

## Risk Register

| # | Risk | Sev | Owner-stage | Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R1** | #4214 ships a fix for a non-problem on 1 of its 3 named sinks | **HIGH** | Stage 5 | **DISCHARGED at D-1** — sink set re-cut to the two genuinely-absent gate sinks | CHEAP |
| **R2** | The release closes with zero gates flipped to enforce | **HIGH** | Phase B3 | **Accepted and expected.** The Outcome Statement is satisfied by recorded decisions plus a real blocking pre-merge assertion; a recorded deferral is a decision. #6298 additionally arms a genuinely blocking discrimination assertion **without** flipping any gate. | n/a (expectation) |
| **R3** | Rotation policy chosen without the drain floor satisfies #5588 at the cost of breaking #4214 | MODERATE | Stage 5 | CIAC-1 (replaced grading command); #5588 sequenced before both register-editing cards | MODERATE |
| **R4** | 4-way concurrent edits to one markdown register table | MODERATE | Stage 6 | Serial commit order; CIAC-2 grades table coherence | CHEAP |
| **R5** | 5-way contention on `core/deploy/deploy.sh` (926 KB) | MODERATE | Stage 6 | P0 fully-serial posture; single PR | CHEAP |
| **R6** | #4751's AC2 population is 8 undisposed ids, not 11 | MODERATE | Stage 5 | Re-scope AC2 to the 8; cross-reference the 3 existing rows | CHEAP |
| **R7** | Orphaned 70,480,021 B pre-relocation warn log, frozen at 2026-06-21, owned by no card | MODERATE | Stage 5 | **DISCHARGED at D-4 / D-10** — in scope for #5588 (live file + orphan disposal) | CHEAP |
| **R8** | #1686 declares an edit to `core/rules/bypass-mode-readiness.md`, whose checklist governs the shared hook `.mode`, not `g1-enforcement.mode` | LOW | Stage 5 | Drop the row or narrow to a precedent citation; marked CONDITIONAL in the matrix | CHEAP |
| **R9** | G3-14 / G3-15 declare `core/hooks/gate-g3-1*-warn-log.jsonl` while every sibling row uses the instance path — pre-relocation prefix drift | LOW | Stage 5 | In scope for #4214 (it already edits `gate-criteria-spec.md`) | CHEAP |
| **R10** | #4214 and #1686 carry no `project:` label | LOW | Phase B3 | Out of scope — metadata hygiene, filed separately | CHEAP |
| **R11** | Premature-flip blast radius | MODERATE | Stage 9 | DEEP review depth on any card that actually flips (D-2). Rendered at D-8: the trigger does **not** fire on #6298. | **EXPENSIVE** if flipped prematurely |
| **R12** | Concurrent PR #6353 collides on 4 shared surfaces | MODERATE | Stage 9 A6.5 | D-17: proceed on the pinned baseline; reconcile at A6.5. No spoke coordinates with that branch. | MODERATE |

**Rollback strategy.** Mode flips are the cheap half — a graduation is one committed token, so reverting is a one-line revert commit. The **rotation is the expensive half**: records discarded by a rotation boundary are **IRREVERSIBLE**. The rotation change therefore ships behind a conservatively-wide retention window (CIAC-1) and is verified against the drain horizon *before* first execution. Release-level rollback = revert the single merge commit; instance-level warn-log state is not restored by that revert.

## Authorized ADRs

| Scope | Author | Allocation |
|---|---|---|
| A stage gate whose subject is out-of-tree GitHub state is made (b′)-`required` by splitting its predicate and CI-gating only the tree-resident half | **#6298** (D-11 as revised by D-16 — #4751's ADR folds into this one record, covering both altitudes) | `python3 release/tools/renumber-adr.py --next-free`; never hand-reserved. Mainline anchor is ADR-161 across both ADR directories. PR #6353's ADR-163 claim is **unmerged and advisory only**. |

## Baseline Pin

`e19a9d30682abefac51cca1ff8aa0ebbf8708593`

Every Engineering spoke branches from this SHA. It is the Stage-5 pin and the Commit-0 pin; no re-baseline was required. Two findings in this release rest on populations a one-line edit can change — the `.github/deploy-check-ci.enforce` token (`warn`) and the absence of a `paths:` filter on the two extended workflows. Both are pinned here per audit-baseline discipline and **must be re-read before Stage 9 relies on them**.

## Quota Budget

**Verdict:** WARN. Parallel-eligible spokes per parallel stage: Stage 5: 5 · Stage 7: 5 · Stage 8: 5. Worst parallel batch = 5 spokes. The usage-window envelope is **UNSTATED**, so the conservative default applies — the resulting band is a projection of an assumed envelope, **never a measurement**. Routing: window-aware launch timing; split the 5-spoke batch. Checkpoint B re-validates at every launch and is the operative gate; this Checkpoint A estimate is advisory.

## Change Description

> **Authoring state.** This section is authored incrementally across the release's five Engineering commits, one block per card, in the D-8 sequence. It is complete when the last Engineering spoke fills the final block, and it is committed on the release branch **before** the PR is transitioned draft → ready at the Stage 9 gate.

### Outcome

The warn-mode gate cohort can terminate. Before this release, a gate in the cohort advanced only on "drain evidence" — rows in a per-gate warn log that is git-ignored, unreadable by a pull-request agent, and in two cases never written at all. That made `shakedown continues` a disposition with no observation that could ever end it, and the cohort accumulated rows that could not be closed. After this release, every gate in the cohort either has an advance signal a pull-request agent can read, or carries a recorded disposition whose blocker is named and checkable.

**No gate flips `warn → enforce` in this release, and that is the intended outcome, not a shortfall.** The premature-flip blast radius was classified EXPENSIVE at the plan gate. The release buys a real blocking pre-merge assertion without arming a single flip.

### Issues delivered

| Issue | What landed | State |
|---|---|---|
| **#6298** | Check 73 `bundle-metrics-gate-integrity` — the G3-14 / G3-15 evaluators, their boundary fixtures, a discrimination suite, and the two workflow extensions that make Requirement (b′) derive `required` for the tree-resident half. | **LANDED** |
| #4214 | warn-mode declarations must name a written sink | PENDING |
| #5588 | shared warn-log lifecycle — live file + orphan disposal | PENDING |
| #4751 | enforce-flip disposition for Checks 66 / 67 + the sibling-id cohort | PENDING |
| #1686 | `g1-enforcement` flip decision | PENDING |

All five are marked as closed at Stage 13 by the automated close-out. The release PR carries no auto-close keywords, so the merge itself closes nothing.

### Key decisions

- **D-8 — evaluator ownership.** Two specs each assumed the other would build the G3-14 / G3-15 evaluator, so under both as written nobody built it. Ownership resolved to #6298, which therefore lands **first** rather than second.
- **The predicate is split by locus of input** (ADR-163). Both gates' subject is out-of-tree GitHub state, so a merge gate on the live evaluation would go red for reasons no PR author can see or repair. The tree-resident machinery is gated at `required`; the backlog-resident half is recorded as a **permanent** advisory residual on architectural grounds — not deferred, not awaiting evidence.
- **Extend, do not create.** Two existing filter-free workflows absorbed the new check. Zero new workflows, sentinels, branch-protection contexts, or macOS jobs.
- **A disposition must name its blocker, not its schedule.** The register's `shakedown continues` shape names a schedule and is unfalsifiable; the replacement rows name conditions a reader can check.

### Reversibility

**CHEAP** for everything landed so far. Check 73 is additive: reverting the two commits removes a roster row, a lifecycle block, three verdict bodies, four fixtures, one suite and one workflow step, and leaves every pre-existing gate at exactly its prior posture. No gate posture was flipped, so there is no armed enforcement to stand down. The single merge commit is revertable with `git revert -m 1`.

The **expensive** half of this release is #5588's rotation, still pending: records discarded by a rotation boundary are IRREVERSIBLE, which is why CIAC-1 pins the rotation ceiling to the drain horizon and why #5588 is sequenced before both register-editing cards.

### Downstream impact

- **`--check-required-subset` now has two members.** Its aggregate is ANY-FAIL, so it can now go red for a bundle-metrics integrity failure where previously only a hook-registry staleness could redden it. The sentinel still reads `warn`, so an in-scope FAIL reports without blocking.
- **`install-tests.yml` gains one unconditionally-blocking step.** A discrimination failure reddens every PR regardless of any sentinel. This is the arm that makes the assertion real.
- **The gate-coverage register gained three rows and one permanent-residual row**, and the Check-38 row's stale `paths-filtered` surface declaration was reconciled in passing — a contradicted row sitting next to rows being edited is the annotate-don't-reconcile failure.
- **Stage-3 → 4 bundling behaviour is unchanged.** Nothing in this card evaluates a live backlog or a live milestone.

### Cross-references

- `core/ADRs/ADR-163-split-predicate-gate-graduation.md` — the reusable decision, both altitudes
- `core/standards/gate-efficacy-standard.md` — Requirements (a) / (b) / (b′), § Verdict-Input Closure, and both registers this release writes into
- `core/schemas/gate-criteria-spec.md` — G3-14 / G3-15 definitional home (read-only for #6298; edited by #4214)
- `core/standards/progressive-rollout-convention.md` — owns the `warn → enforce → removed` ladder; advance is an operator decision, never auto-promoted by hit count

## Change Log

| Date | Change | Source |
|---|---|---|
| 2026-08-28 (Friday) | Plan authored at Stage 4; 4 members / 14 pts | Stage-4 planning spoke |
| 2026-08-28 (Friday) | D-1 premise corrections ratified; D-2 posture divergence; D-3 adds #6298 (5 members / 18 pts); D-4 #5588 scope | Operator, Stage-4 plan-review gate |
| 2026-08-29 (Saturday) | D-8 evaluator ownership → #6298, lands first; D-9 #4214 DEFERRED WITH A DEADLINE; D-10 #5588 scope; D-11/D-16 ADR authorized and consolidated; CIAC-1 grading command replaced | Operator, Stage-5 Wave-1 completion |
| 2026-08-29 (Saturday) | Transcribed to this file as Engineering Commit 0; version re-verified (anchor `v4.43`, next-free `v4.44`, free) | Stage-6 spoke, sub-task #6308 |
