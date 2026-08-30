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
core/ADRs/ADR-164-written-is-not-repo-derivable.md               add

# -- #5588 -- shared warn-log lifecycle --
core/deploy/deploy.sh                                            edit
core/ADRs/ADR-165-bounded-by-relocation-not-by-discard.md         add

# -- #5588 -- CONDITIONAL rows RESOLVED AT D-10: the prune-tool branch was NOT selected --
# Stage 5 chose byte-budget segment rotation with permanent retention, so no
# operator-run tool and no new executable exist. Both rows below are therefore
# NOT PROMOTED, the conditional cross-milestone edge to #5227 / #5558 does not
# form, no `## Dependency Exceptions` entry is owed, and Release Class `routine`
# trigger (c) holds at zero new files outside the ADR.
# core/deploy/tools/prune-warn-log.sh                            NOT PROMOTED (stage5 selected in-line rotation)
# core/config/allowlists/script-execution-allowlist.txt          NOT PROMOTED (no new executable to allowlist)

# -- #4751 -- enforce-flip decision, Checks 66/67 + sibling ids --
core/deploy/deploy.sh                                            edit
core/standards/gate-efficacy-standard.md                         edit
# -- #4751 -- RESOLVED AT D-14/D-29: the ladder file is NOT edited, and that is a
# determination rather than a silent drop. The enum is shadow -> warn -> enforce
# -> removed and this card advances nothing: all ten ids stay on the `warn` rung.
# `RATIFIED ADVISORY` and `DEFERRED — precondition-blocked` are REGISTER
# dispositions ("the advance is declined" / "the advance is blocked"), not new
# rungs, so no ladder vocabulary is minted and the file's contract is unchanged.
# It stays a READ-ONLY input, cited by every row this card writes.
# core/standards/progressive-rollout-convention.md                NOT EDITED (register disposition, not a ladder rung)

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
| `core/standards/progressive-rollout-convention.md` | **VOID** (was single) | none — #4751 determined at D-14 that a register disposition is not a ladder rung, so the file stays a read-only input |
| `core/rules/bypass-mode-readiness.md` | single, **CONDITIONAL** | #1686 |
| `core/deploy/tools/` | **VOID** (was single, CONDITIONAL) | none — the #5588 branch that would have claimed it was not selected at D-10 |
| `core/ADRs/` | single | #5588 (ADR-165), alongside #6298's ADR-166 and #4214's ADR-164 — three distinct files, no cell contention |

**The sharpest contention is the table, not the file.** Four cards write rows into the same markdown register in `gate-efficacy-standard.md`. Serial commits resolve the mechanical conflict; CIAC-2 is what makes the resulting table coherent rather than merely conflict-free.

**Concurrent-release note (D-17).** PR #6353 (`release/declarations-have-a-firing-surface`, draft) is building concurrently and collides on 4 of this release's surfaces, including `core/deploy/deploy.sh` and `core/standards/gate-efficacy-standard.md`. The operator decided to proceed on the pinned baseline and reconcile at **Stage 9 Phase A6.5**. No spoke merges, rebases onto, or coordinates with that branch.

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#4214 x #5588 — the retention contract on `core/deploy/deploy.sh`):** the rotation/prune ceiling #5588 introduces is >= the drain consumption horizon #4214's sink contract depends on, and both cards read the same declaration site rather than either carrying a literal. *Method (**ratified replacement** — the Stage-4 form returned 3 hits, all comment prose, and was ungradeable): assert `WARN_LOG_RETENTION_DAYS >= GATE_ROLLOUT_ESCALATE_DAYS` — two symbols, one declaration block, no literal in either card. The shared read symbol is `warn_log_segment_set()`.* Graded at Stage 9 QC3.5 on the merged PR.
  - **Symbol renamed at D-27** (`SKILL_SUITE_GATE_ESCALATE_DAYS` → `GATE_ROLLOUT_ESCALATE_DAYS`), re-cut by #5588's commit while only one card had landed. The old name was a mis-named subject: it governs a bundle-metrics gate rollout, not the skill suite. The new name derives from Check 74's own id `gate-rollout-graduation` and carries no `verify-release-plan.sh` classifier keyword.
  - **The invariant is now held by DERIVATION, not by comparison of two hand-maintained numbers.** `WARN_LOG_RETENTION_DAYS` is assigned from `GATE_ROLLOUT_ESCALATE_DAYS` rather than from a literal, so the `>=` relation cannot be broken by an edit and no runtime assertion is owed. Retention itself is **permanent** — the lifecycle bounds the hot file by relocation and discards nothing — so the day count is a declared lower bound the implementation exceeds without limit, never a disposition clock.

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
| #4214 | AC-1 | `grep -c "core/hooks/gate-g3-1" core/schemas/gate-criteria-spec.md` — the cross-layer hook-layer prefix no longer appears on any G3-14 / G3-15 declaration. Paired arm: `grep -c "gate-g3-14-warn-log.jsonl" core/schemas/gate-criteria-spec.md` and the same for `gate-g3-15-warn-log.jsonl` — each resolves to the byte-identical declaration pair Check 73 conjunct C73-b asserts. Specificity arm: `grep -c "ZZZ_FABRICATED_TOKEN_CONTROL" core/schemas/gate-criteria-spec.md` returns 0 | **1** (was **4** — all four declarations re-pointed; the survivor is the § Versioning entry narrating the change, which a declaration-form assertion must not delete) · each retired basename → **2** agreeing declarations · `specified, not yet emitting` → **16** lines (was 11) · specificity **0** |
| #4214 | AC-2 | `grep -c "Written sink and terminable shakedown" core/standards/gate-efficacy-standard.md` — the clause stating W1 (a drain-history criterion may be declared only where the sink is written, else the disclosure) and W2 (the exit criterion must be evaluable from committed state). Specificity arm: `grep -c "ZZZ_FABRICATED_TOKEN_CONTROL" core/standards/gate-efficacy-standard.md` returns 0 | **3** lines — the section heading plus its two in-file citations; at least 1 required · specificity **0** |
| #4214 | AC-3 | *(re-rendered per D-5 — the original asserted a row appended to a sink this design retires.)* `grep -c "gate-rollout-graduation — GRADUATION-OVERDUE" core/deploy/deploy.sh` — Check 74's escalation branch, the single path on which the deadline arm increments the finding count. Sensitivity arm: `grep -c "gate-rollout-graduation" core/deploy/deploy.sh` is non-zero. Specificity arm: `grep -c "ZZZ_FABRICATED_TOKEN_CONTROL" core/deploy/deploy.sh` returns 0. The executed falsification triple is recorded in the PR evidence block and re-run at Stage 7 | **1** escalation branch · sensitivity **10** · specificity **0**. Executed at Stage 6 through the repo primitive: arming date 240d past → GRADUATION-OVERDUE, findings **2 → 3**; 70d (past review, inside escalation) → GRADUATION-DUE warn, findings stay **2**; 0d → OK, findings **2**. The escalation boundary is what moves the count, not merely an elapsed date |
| #4214 | AC-4 | *(token re-cut at D-27 — the symbol this row named was renamed by #5588's commit. The assertion itself is identical; only its spelling moved.)* `grep -c "GATE_ROLLOUT_ESCALATE_DAYS" core/standards/gate-efficacy-standard.md` — the G3-14 / G3-15 register row names the committed constants a reviewer can read, so its ending condition no longer rests on a git-ignored drain. Paired arms, one per declared prefix so no cell carries a table-breaking alternation: `grep -c "^readonly GATE_ROLLOUT_" core/deploy/deploy.sh`, `grep -c "^readonly WARN_LOG_" core/deploy/deploy.sh` — the rollout and warn-log constants are declared in the tracked script, not in operator config. **The `^readonly SKILL_SUITE_GATE_` arm was RETIRED at D-29, not merely re-counted:** that rename emptied the prefix, and an arm that can only ever return 0 is a dead control, not a passing one. Specificity arm: `grep -c "ZZZ_FABRICATED_TOKEN_CONTROL" core/deploy/deploy.sh` returns 0 | register row **1** · tracked constants **4 + 3 = 7** (D-29 completed the family rename, so all four rollout constants now carry the `GATE_ROLLOUT_` prefix: the arm reads 4 rather than the post-D-27 1, the `SKILL_SUITE_GATE_` arm is retired at 0, and the `WARN_LOG_` arm is unchanged at 3 — **the total is invariant at 7 across both renames**, which is the check that the rename moved constants between prefixes rather than adding or losing any) · specificity **0**. The row names its blocker and its exit criterion reads committed state, so it is no longer "signal not derivable" |
| #4214 | AC-5 | `grep -c "Sink (W1)" core/standards/gate-efficacy-standard.md` and `grep -c "Ending condition (W2)" core/standards/gate-efficacy-standard.md` — the G3-14 / G3-15 register row carries both axes' fields after this change. Specificity arm: `grep -c "ZZZ_FABRICATED_TOKEN_CONTROL" core/standards/gate-efficacy-standard.md` returns 0 | **2** lines each — the register row plus the § Version History entry recording it · specificity **0**. The row is **extended, not rewritten**: its SPLIT DISPOSITION verdict and the permanence of its live limb are byte-preserved |
| #5588 | AC-1 | *(re-cut at #5588's own commit onto the criterion's SECOND limb — "all appends demonstrably route through one helper" — which is the limb this design satisfies. The first limb counted direct `>>` appends and would have read 12 forever: the 12 append sites are deliberately untouched, which is why the blast radius is two lines rather than twelve.)* `grep -c "pmo_instance_path)/deploy-check-warn-log.jsonl" core/deploy/deploy.sh` — expect 0 hot-path literals, because both writer variables now assign from the bounded choke point instead of resolving the path themselves. Paired arm: a count of the `warn_log_path` assignment form resolves to the 2 writer sites. Sensitivity arm: a count of `WARN_LOG` in the same file is non-zero, so a zero here is falsifiable rather than a dead pattern. Specificity arm: a count of `ZZZ_FABRICATED_TOKEN_CONTROL` returns 0 | **0** hot-path literals (was 2) · both writers bounded · sensitivity non-zero · specificity 0. The 12 append sites keep `>> "$VAR" 2>/dev/null \|\| true` verbatim |
| #5588 | AC-2 | *(rendered executable at #5588's own commit — the tokens now exist.)* The bound is asserted where it is DECLARED, because under this design the ceiling is structural rather than emergent: `grep -c "^readonly WARN_LOG_HOT_BUDGET_BYTES=" core/deploy/deploy.sh` — expect 1 budget declaration, the single value the rotation compares against. Paired arm: the one over-budget comparison in `warn_log_path` is what fires the move, so the ceiling has one reader and one writer. Sensitivity arm: a count of `warn_log_path` in the same file is non-zero. Specificity arm: a count of `ZZZ_FABRICATED_TOKEN_CONTROL` returns 0. The **executed** conservation run — rotate a fixture copy of the live log 3 times, then reassemble the family and assert it is byte-identical to the pre-rotation fixture, with a seeded-deletion control that must FAIL — is recorded in the PR evidence block and re-run at Stage 7 | budget declaration **1** · one comparison, one choke point · sensitivity non-zero · specificity **0**. Hot-file bytes stop growing at the budget while the family keeps every row |
| #5588 | AC-3 | *(rendered executable at #5588's own commit.)* Satisfied by construction — retention is permanent and a rotation boundary is a rename, so no record the drain needs can be lost. Asserted structurally at the read surface the drain is required to use: `grep -c "^warn_log_segment_set() {" core/deploy/deploy.sh` — expect 1 definition, so the family has exactly one read surface and a drain cannot resolve a second one. Paired arm: a count of the literal hot-path resolution is 0, so nothing reads or writes the hot file by name any more. Sensitivity arm: a count of `warn_log` in the same file is non-zero (7 references to the symbol alone). Specificity arm: a count of `ZZZ_FABRICATED_TOKEN_CONTROL` returns 0. Survival across the boundary is additionally graded on the merged PR by the retention-contract criterion | read-surface definitions **1** · literal hot-path resolutions **0** (was 2) · specificity **0** |
| #5588 | AC-4 | *(rendered executable at #5588's own commit — the disjunction is settled: #5588 took the SECOND limb, retaining append-path silence with a recorded rationale plus one new observable at the choke point.)* `grep -c "warn-log rotation failed" core/deploy/deploy.sh` — expect 1 rotation-failure notice, the line that converts silent unbounded degradation into one visible message at one site. Paired arm: the retained silence and the stderr stream choice each carry their rationale in the same block. Sensitivity arm: a count of `WARN:` in the same file is non-zero. Specificity arm: a count of `ZZZ_FABRICATED_TOKEN_CONTROL` returns 0 | notice **1** · rationale recorded at the declaration site · specificity **0**. All 12 append sites keep `2>/dev/null \|\| true` verbatim; the residual is accepted and written down, not silent |
| #5588 | AC-5 | Run `./deploy.sh --check` | Green |
| #4751 | AC-1 | Both new gates' flip-decision rows carry a decision, the finding count observed at decision time, AND the population it was measured over — asserted on the two distinctive population strings the gates themselves emit, so a row carrying a decision but no denominator cannot pass: `grep -cE "0 findings over 239 of 258 tracked\|56 skills and 1,540 discriminating pairs" core/standards/gate-efficacy-standard.md` — exactly 2. Specificity arm: `grep -c "zzz-no-such-population-string" core/standards/gate-efficacy-standard.md` returns 0 | **2** — Check 66 (`citation-anchor`) DEFERRED — precondition-blocked, 0 findings over 239 of 258 tracked `*.md`; Check 67 (`trigger-collision`) DEFERRED — precondition-blocked, no pair at or above threshold over 56 skills and 1,540 discriminating pairs with EXEMPT 0. Both decisions recorded; neither flipped |
| #4751 | AC-2 | Exactly one register row per cohort id, keyed on the resolution pointer this card introduced (no pre-existing row carries that anchor, so the count is this card's rows and nothing else): `grep -c "::--self-test" core/standards/gate-efficacy-standard.md` — exactly 10. Specificity arm: `grep -c "::--zzz-not-an-anchor" core/standards/gate-efficacy-standard.md` returns 0 | **10** = the **8 undisposed sibling ids** (Checks 51 / 52 / 53 / 54 / 55 / 56 / 57 / 59) plus the 2 gates AC-1 covers. The **3 cross-referenced ids** (`decision-emission` Check 61, `register-runner-resolution` Check 62, `version-freeness` Check 41) each still resolve to exactly 1 pre-existing row and are NOT re-decided |
| #4751 | AC-3 | [DEFERRED-family routing] **N/A BY CONSTRUCTION — no card's landing makes this executable, and that is the point.** Zero gates flip warn → enforce this release (ratified premise 5 / D-14), so there is no flipped gate to demonstrate a fixture failure on. Recorded N/A-with-reason rather than passed, which is what the criterion's own wording instructs. The property it reaches for is nevertheless continuously asserted for Checks 54 / 57 / 66 / 67 by standing `--self-test` arms that hard-FAIL on EVERY mode — observed this stage: Check 66 9/9 with must-flag 3/3 NON-ZERO, Check 67 3 arms PASS, Check 57 9/9, Check 54 PASS | **N/A**, recorded as such rather than passed. This row is the one residual the plan's Stage-7 entry condition names as permanently permitted |
| #4751 | AC-4 | Every held row names the observable condition that would end the hold AND the written sink that produces that observation: `grep -c "Sink (W1)" core/standards/gate-efficacy-standard.md` — exactly 12. Specificity arm: `grep -c "Sink (W9)" core/standards/gate-efficacy-standard.md` returns 0 | **12** = the **10 rows this card wrote** (the same 10 the AC-2 anchor count identifies, each also naming an Ending condition — verified per-row at Stage 6: 10/10 carry both fields plus the shared `$(pmo_instance_path)/deploy-check-warn-log.jsonl` sink from the written-sink declaration set) plus the 2 pre-existing G3-14 / G3-15 declarations. Two AC4 defects on this card's OWN gates were fixed rather than recorded: Check 67 deferred its flip to a `bypass-mode-readiness.md` section that does not exist (0 of 44 headings match), and Check 66 named a git-ignored `.mode` file as its flip surface |
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
| **R3** | Rotation policy chosen without the drain floor satisfies #5588 at the cost of breaking #4214 | MODERATE | Stage 5 | **DISCHARGED at D-10 — structurally, not by tuning.** The worst contiguous 30-day window measures 78,642,875 B against a 90-day drain horizon, so no *discarding* rotation satisfies both cards at any budget; that is a contradiction, not a parameter to pick. Resolved by bounding the hot file through relocation into numbered segments with permanent retention and zero discard, which makes the ceiling unconditionally ≥ any horizon. CIAC-1's invariant is now held by derivation rather than by comparing two hand-maintained numbers | MODERATE |
| **R4** | 4-way concurrent edits to one markdown register table | MODERATE | Stage 6 | Serial commit order; CIAC-2 grades table coherence | CHEAP |
| **R5** | 5-way contention on `core/deploy/deploy.sh` (926 KB) | MODERATE | Stage 6 | P0 fully-serial posture; single PR | CHEAP |
| **R6** | #4751's AC2 population is 8 undisposed ids, not 11 | MODERATE | Stage 5 | Re-scope AC2 to the 8; cross-reference the 3 existing rows | CHEAP |
| **R7** | Orphaned 70,480,021 B pre-relocation warn log, frozen at 2026-06-21, owned by no card | MODERATE | Stage 5 | **DISCHARGED at D-4 / D-10** — in scope for #5588 (live file + orphan disposal) | CHEAP |
| **R8** | #1686 declares an edit to `core/rules/bypass-mode-readiness.md`, whose checklist governs the shared hook `.mode`, not `g1-enforcement.mode` | LOW | Stage 5 | Drop the row or narrow to a precedent citation; marked CONDITIONAL in the matrix | CHEAP |
| **R9** | G3-14 / G3-15 declare `core/hooks/gate-g3-1*-warn-log.jsonl` while every sibling row uses the instance path — pre-relocation prefix drift | LOW | Stage 5 | In scope for #4214 (it already edits `gate-criteria-spec.md`) | CHEAP |
| **R10** | #4214 and #1686 carry no `project:` label | LOW | Phase B3 | Out of scope — metadata hygiene, filed separately | CHEAP |
| **R11** | Premature-flip blast radius | MODERATE | Stage 9 | DEEP review depth on any card that actually flips (D-2). Rendered at D-8: the trigger does **not** fire on #6298. | **EXPENSIVE** if flipped prematurely |
| **R12** | Concurrent PR #6353 collides on 4 shared surfaces | MODERATE | Stage 9 A6.5 | D-17: proceed on the pinned baseline; reconcile at A6.5. No spoke coordinates with that branch. | MODERATE |

**Rollback strategy.** Mode flips are the cheap half — a graduation is one committed token, so reverting is a one-line revert commit.

**The rotation is no longer the expensive half, and the reason is a property of the mechanism rather than a mitigation bolted onto it.** The Stage-4 reading — *"records discarded by a rotation boundary are IRREVERSIBLE"* — assumed a discarding rotation, which D-10 rejected. Under the design that shipped, a rotation boundary is a same-directory **rename**: nothing is discarded, an in-flight append follows the inode into the segment, and the whole family is reconstituted by concatenating `warn_log_segment_set()` in order. **Reversibility: MODERATE / Confidence HIGH** for the rotation, superseding the IRREVERSIBLE classification rather than merely qualifying it. Verification still runs against a fixture copy *before* first execution — a non-lossy mechanism is a reason to lower the tier, not a reason to skip the rehearsal.

**One genuinely one-way step remains, and it is not the rotation.** Adopting the orphaned pre-relocation log as segment `00000` is an operator-run move of ~70 MB of instance state that cannot land in a PR diff and cannot be rehearsed by reading one. That is why Stage 10 stays uncompressed.

Release-level rollback = revert the single merge commit. Instance-level warn-log state is not restored by that revert — but because rotation discards nothing, the post-revert instance holds every record it held before, distributed across the hot file and its segments; a `cat` of the family in order restores the single-file shape.

## Authorized ADRs

| Scope | Author | Allocation |
|---|---|---|
| A stage gate whose subject is out-of-tree GitHub state is made (b′)-`required` by splitting its predicate and CI-gating only the tree-resident half | **#6298** (D-11 as revised by D-16 — #4751's ADR folds into this one record, covering both altitudes) | `python3 release/tools/renumber-adr.py --next-free`; never hand-reserved. Mainline anchor is ADR-161 across both ADR directories. PR #6353's ADR-166 claim is **unmerged and advisory only**. |
| A warn-mode declaration carries two axes — W1 the sink is written, W2 the shakedown is terminable from committed state — and only the repo-derivable axis can end a shakedown | **#4214** (D-11, restored by D-23: the release ships **three** authorized ADRs, not two; D-16's count rested on a hub arithmetic error) | Allocated at this card's Engineering commit as the next number above the **union** of the mainline anchor and this branch's own in-flight claim. `renumber-adr.py --detect` reports `ANCHOR 162 origin/main` / `NEXT-FREE 163` / `CLAIMED-SET-BRANCH-ONLY 163 (detection only — never binds)`, so `--next-free` alone would have collided with ADR-166 on this same branch. **ADR-164** re-verified to report `BINDS`; never hand-reserved. |
| An append-only operator-instance log whose consumer needs its full history is bounded by **relocation into numbered segments, not by discard** — and the choice rests on measured feasibility and cost, never on a never-delete doctrine | **#5588** (D-11, restored by D-23 — the third of the release's three authorized ADRs). Grounds are the strongest of the set: this is the **third pass at one question class** (#3715 bounded the release logs → #3387 / ADR-106 declined the purge → #5588), and ADR-106 exists precisely because an earlier adjudication of that class left no durable record. | Allocated at this card's Engineering commit as the next number above the **union** of the mainline anchor and this branch's own two in-flight claims. `renumber-adr.py --detect` reports `ANCHOR 162 origin/main` / `NEXT-FREE 163` / `CLAIMED-SET-BRANCH-ONLY 163,164`, so `--next-free` alone would have collided **twice** on this same branch. **ADR-165** re-verified to report `BINDS`; never hand-reserved. A concurrent release (PR #6393, draft) independently claims 163 and 164 against the same anchor — correct behaviour by both sides, since unmerged sibling claims are advisory. Whoever merges second renumbers; a gap blocks the repo, a duplicate is tooled. |

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
| **#4214** | **W1 / W2 — the two axes of a warn-mode declaration**, added to `gate-efficacy-standard.md`: a drain-history flip criterion may be declared only where the sink is written (W1), and a shakedown must carry an exit criterion evaluable from committed state (W2). The finding that earns the card its keep is that these are **independent**: the cohort whose sink IS written has been stalled throughout, so writtenness was never the binding constraint. G3-14 / G3-15's four phantom sink declarations are reconciled to the shared deploy-check warn log with the `specified, not yet emitting` disclosure; their register row is **extended** with its Sink (W1) and Ending condition (W2) fields rather than rewritten; and Check 74 `gate-rollout-graduation` makes the integrity limb's residual flip deadline-armed and repo-derivable. Records ADR-164. | **LANDED** |
| **#5588** | **The warn log is bounded by relocation, not by discard.** The hot file is renamed whole into a numbered same-directory segment once it passes a byte budget; **retention is permanent and no record is ever discarded**. All three branches the ticket offered — size/age rotation, lifecycle truncation, append-forever plus a prune tool — discard at their boundary, and the arithmetic rules that whole class out: the worst contiguous 30-day window measures **78,642,875 B** against a 90-day drain horizon, so any ceiling low enough to *solve* the growth problem is one to two orders of magnitude below what the sibling drain needs. That is a contradiction, not a tuning problem. Both writer variables now assign from one bounded choke point, so **all 12 append sites are untouched** and the blast radius is two changed lines behind one new block. `warn_log_segment_set()` is the family's single read surface: a drain that opens the hot file directly returns a plausible wrong answer after the first rotation rather than an error. The gate-rollout escalation constant was re-cut from `SKILL_SUITE_GATE_ESCALATE_DAYS` to `GATE_ROLLOUT_ESCALATE_DAYS` (D-27) — a mis-named subject, renamed while only one card had landed — and the retention window is now **assigned from** that floor symbol, so the cross-card invariant holds by derivation instead of by two hand-maintained numbers. Records ADR-165. | **LANDED** |
| **#4751** | **The cohort's flip decision is recorded, and it is a TWO-CLASS split rather than one blanket deferral.** Ten register rows land in `gate-efficacy-standard.md`, one per cohort id. The split is not a bin-pack: two independent axes — **subject locus** (does the primitive read out-of-tree GitHub state?) and **drain behaviour** (rows in the written sink plus the current tree verdict) — partition the ten ids **identically**, and both were re-measured at the merge baseline. Five ids whose subject is live GitHub state (Checks 51 / 52 / 53 / 55 / 56) are **RATIFIED ADVISORY, permanently**: their Verdict-Input Closure over repo paths is empty, so no pull request can repair their verdict, a network-dependent member would make a transient `gh` outage merge-blocking under the subset's fail-closed aggregate, and their findings are a permanent signal stream (279–2,035 rows, still emitting) rather than a drainable backlog. Five in-tree ids (Checks 54 / 57 / 59 / 66 / 67) are **DEFERRED — precondition-blocked, NOT evidence-blocked**, the Check 45(b) / Check 62 shape: their evidence is met, repo-derivable and measured zero with **firing** control arms, and the single blocker is Requirement (b′) — 0 of 22 workflow files reference any of them. Check 59 splits out with its evidence limb recorded **UNVERIFIED**, because it returns `SKIP: not a release branch` and a SKIP is not a zero. `DEFERRED WITH A DEADLINE` was considered and rejected on grounds: that form exists for a shakedown that *cannot* terminate, and each of these gates' standing `--self-test` hard-FAILs on every mode, which proves it can still fire. Two AC4 defects on this card's own gates were **fixed rather than recorded** — Check 67 deferred its flip to a `bypass-mode-readiness.md` section that does not exist (0 of 44 headings match; 4 of the 5 prose occurrences point at a different section governing the PreToolUse-hook layer), and Check 66 named a git-ignored `.mode` file as its flip surface, reproducing inside its own declaration the not-repo-derivable defect this milestone exists to close. Both now cite the committed `resolve_check_mode "<id>" "enforce"` default and the register row. The rollout-constant rename was completed at D-29 (`GATE_ROLLOUT_PHASE` / `_ARMED` / `_REVIEW_DAYS`), retiring a 3/1 split family. **No gate flips, no ADR is minted, and no verdict moves.** | **LANDED** |
| #1686 | `g1-enforcement` flip decision | PENDING |

All five are marked as closed at Stage 13 by the automated close-out. The release PR carries no auto-close keywords, so the merge itself closes nothing.

### Key decisions

- **D-8 — evaluator ownership.** Two specs each assumed the other would build the G3-14 / G3-15 evaluator, so under both as written nobody built it. Ownership resolved to #6298, which therefore lands **first** rather than second.
- **The predicate is split by locus of input** (ADR-166). Both gates' subject is out-of-tree GitHub state, so a merge gate on the live evaluation would go red for reasons no PR author can see or repair. The tree-resident machinery is gated at `required`; the backlog-resident half is recorded as a **permanent** advisory residual on architectural grounds — not deferred, not awaiting evidence.
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

- `core/ADRs/ADR-166-split-predicate-gate-graduation.md` — the reusable decision, both altitudes
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
| 2026-08-29 (Saturday) | **D-29** completes the rollout-constant family rename (`SKILL_SUITE_GATE_PHASE` / `_ARMED` / `_REVIEW_DAYS` → `GATE_ROLLOUT_*`; 31 occurrences across 2 files, 0 residual, plus 2 knock-ons — the Check-74 specificity arm re-namespaced and the declaration block's own "skill-suite" prose retired). #4751's ten flip-decision rows land with the CIAC-2 row-form contract; #4214's AC-4 `^readonly SKILL_SUITE_GATE_` arm retired as a dead control; #4751's four AC rows rendered executable | Stage-6 spoke, sub-task #6306 |
| 2026-08-29 (Saturday) | D-27 renames `SKILL_SUITE_GATE_ESCALATE_DAYS` → `GATE_ROLLOUT_ESCALATE_DAYS` (12 occurrences, 3 files); CIAC-1 and #4214 AC-4 re-cut onto the new token; #5588's five AC rows rendered executable; R3 discharged and the rotation reclassified IRREVERSIBLE → MODERATE; the two CONDITIONAL prune-tool matrix rows resolved NOT PROMOTED; ADR-165 authorized row added | Stage-6 spoke, sub-task #6305 |
