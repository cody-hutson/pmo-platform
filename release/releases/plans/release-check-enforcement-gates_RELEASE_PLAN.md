---
title: Release Plan — release-check-enforcement-gates (the deploy-time enforcement gates measure what they claim to measure)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: release-check-enforcement-gates
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — `release-check-enforcement-gates`

**Milestone:** `release-check-enforcement-gates` (milestone 300). Seven parent members, one branch, one pull request, one merge gate.
**Version identity:** **slug-primary** per **ADR-092**. This file is `release-check-enforcement-gates_RELEASE_PLAN.md` and the branch is `release/release-check-enforcement-gates`; no version stem appears in the filename, the branch name, or any path. Bump class is `minor`. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket and resolves the `{{RELEASE_VERSION}}` token carried below.
**Topology:** **SINGLE** — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial.** Stage-6 work routes one card at a time in the approved sequence on the single branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`cross-cutting`** (confirmed against live file state at the Stage-4 gate). Posture: engagement density **Tight** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**. Class weight **1.3**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, **reconciled forward** through the seven Stage-5 Solutioning designs, their independent Phase-A6.5 adversarial reviews, the wave-1 and wave-2 consolidated Decision Briefings, and the Commit-0 version re-verify recorded below. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and the Deviation Log records the delta with its evidence. The Stage-4 output comment is the historical record and is not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` — slug-primary pre-claim (ADR-092); bump class `minor` |
| **Date created** | 2026-08-05 (Wednesday) — Stage-4 planning |
| **Commit 0 authored** | 2026-08-06 (Thursday) — day-of-week validated |
| **Build anchor** | `origin/main` @ `50f26869` · read 2026-08-06 (Thursday) local / `2026-08-07T01:44Z` |
| **Release manager** | Agent-assisted (`release-hub` Mode O) |
| **Branch** | `release/release-check-enforcement-gates` |
| **Members** | 7 parent cards; raw Σ 36 pts × class weight 1.3 = **47 effective pts** (operator-accepted at the recorded G3-15 override) |

### Commit-0 version re-verify

The Stage-4 version determination is **provisional** until the Stage-12 atomic claim, and this rung exists because the anchor moves. It already moved once in this release: Stage-4 measured anchor `v4.12` → next-free `v4.13`, and a sibling release claimed `v4.13` mid-run. Re-measured here from scratch rather than carried.

| Arm | Probe | Result |
|---|---|---|
| **Anchor** | `git fetch --tags origin`, then the sorted tag surface | highest present = **v4.13** |
| **Anchor cross-read** | highest version row in the release ledger, read from the mainline (`git show origin/main:release/releases/RELEASE_LOG.md`) rather than a worktree copy | **v4.13** — tag surface and ledger **agree** at this instant |
| **Bump class** | capability release; no breaking contract change | **minor** |
| **Target** | is the recomputed next-free slot present on the origin tag surface? | **0 occurrences** — not claimed |
| **Sensitivity control** (known PRESENT) | the immediately preceding slot on the same surface | **1 occurrence** — the probe detects a real claim |
| **Specificity / extraction** | total tags returned by the same surface read | **157** — the surface is non-empty, so the zero above is reachable rather than a dead read |
| **`claimed_set()` in-flight** | `gh pr list --state open`, then per-PR version-token scan | **no claim on the next slot** — see below |

**Recomputed next-free for a `minor` bump: `v4.14`.** This **equals** the figure the hub recorded, so the detect-and-HALT rung does **not** fire and no `[SCOPE CHANGE]` is raised. `v4.14` is a **provisional display value only**; it appears in no filename, no branch name, and no path.

**One material change against the Stage-4 record, surfaced rather than carried silently.** Stage 4 recorded the In-Flight Release Roster as **n=0** siblings. At this anchor it is **n=1**: a draft sibling release pull request is open on branch `release/hub-spoke-execution-safety`, created `2026-08-07T01:10Z`. It is **slug-primary and carries no version token in its body or its plan filename**, so it holds no claim on the next slot and does not change the computation. It does mean the slot is **contested in principle** — whichever release reaches its Stage-12 ref-CAS first binds `v4.14`, and the loser re-derives. That is the designed behaviour of the atomic claim, not a defect; it is recorded here so Stage 12 is not surprised, and so a stale "roster empty" reading is not carried into Stage 9 Phase A6.6, which re-measures fresh and owns the `CONTENTION-*` verdict.

**Freeness is read from the tag surface, not the ledger.** A tag is written atomically at the instant of the claim; the ledger row and the published release land later through separate follow-up pull requests. A check consulting the ledger alone can return a false PROCEED. Both surfaces were read here and agree; where they disagree, the tag governs.

---

## Change Description

*Phase C1 (G6-05). Authored at Engineering Commit 0 in provisional form so it is present before the pull request is marked ready for review; **the final Engineering slice refreshes it** to describe what actually shipped rather than what was planned.*

**Outcome.** The platform's deploy-time triage-readiness gate reports on the wrong things. It reads a priority field through a carrier the corpus does not use, so it fails most of the issues it evaluates for a reason that has nothing to do with their readiness. It evaluates the entire backlog on every deploy rather than the release actually being deployed, so an unrelated stale card can block work it has no bearing on. It does not know about the two newest work-item forms, so it grades them against a rubric written for a different shape. A sibling check cannot tell "named in another milestone" from "named in no milestone", so the operator cannot act on its findings. The pipeline's own stage artifacts are missing the label its own gates key on, so the pipeline trips itself. Two review stages never read the one CI signal that actually blocks a merge. And nothing checks whether a ticket's stated expected behaviour is contained by the files it says it touches. This release makes each of those instruments measure the thing it claims to measure — and takes the detector fix **first**, so the scope decision downstream of it is rendered on corrected data rather than on a count inflated by a reader bug.

**Issues resolved.** Seven parent cards; each is marked as closed at Stage 13. See § Members and the designated reference block at the foot of this plan.

**Key decisions.** Recorded per-card in § Operator Decisions and in the Deviation Log. The release's single D-class scope decision belongs to the Check-22 population card and is rendered on the corrected failure decomposition this release's first commit produces.

**Reversibility.** **MODERATE** overall / confidence **HIGH**. Nine of ten register risks are `git revert`-clean at whole-release and per-issue granularity (one commit per issue). Two exceptions are named in § Rollback: the label backfill is a GitHub state mutation outside the repository, and a deploy executed between merge and any revert ran under the changed enforcement scope and cannot be un-run.

**Downstream impact.** The enforcement posture does **not** change in this release unless the population card's decision says so; the priority-detector fix is deliberately posture-neutral, so a drop in the failure count must not be read as a graduation.

**Cross-references.** § Dependency Graph, § Contention Map, § Cross-Issue Acceptance Criteria, and the designated reference block.

---

## Scope

### Summary

Seven cards, one theme: **every deploy-time enforcement gate in this release measures the thing it claims to measure.** All seven repros were re-run against a pinned baseline at planning time and **7/7 still reproduced**; two carried scope corrections that changed the build, and one needed an operator decision before Engineering. Both were rendered at the Stage-4 gate and are recorded below.

- **The measuring instrument is corrected first.** The Check-22 priority criterion binds a carrier the corpus does not use, which inflates the failure count the population-scope decision is weighed against. It leads the sequence.
- **Then applicability, then scope.** The kind-form applicability declaration lands before the enforcement-scope decision, so the larger structural edit lands on a settled applicability matrix rather than under one.
- **The second cluster is independent.** The sibling-check sub-class split and the label backfill share a tool and a verification order but no file region with the first cluster.
- **Two cards are freely orderable** and carry disjoint file sets.

### Members

| # | Card | Size | One line |
|---|---|---|---|
| 1 | **#4561** | M (4) | Check-22 / G1-06 binds a priority carrier the corpus does not use |
| 2 | **#3821** | M (4) | Check-22 title floor + the doc-impact gate do not know the two new kind forms |
| 3 | **#3820** | L (8) | Check 22 gates deploys on backlog-wide triage status, not the release being deployed |
| 4 | **#3711** | M (4) | Check 56 M2 cannot distinguish named-in-another-milestone from named-in-no-milestone |
| 5 | **#3709** | M (4) | Pipeline stage sub-tasks ship without the label the pipeline's own gates key on |
| 6 | **#3826** | M (4) | Stage 5-9 review and the readiness scan miss the required issue-reference-validity CI gate |
| 7 | **#3703** | L (8) | No gate checks that stated expected behaviour is contained by the declared affected files |

Raw Σ **36** pts (re-sized from 34 when card 5 was re-scoped at the Stage-4 gate) × class weight 1.3 = **47 effective pts** against a 25-pt ceiling. **Settled**, not re-litigated: the operator recorded a G3-15 override with disposition *(C) reframe / keep-with-rationale*, and the 4-way `core/deploy/deploy.sh` contention discovered at Stage 4 is **new evidence for** that disposition — the named weakest cut runs straight through a 4-way edit surface, so a split would put two editors of one file into two different releases.

### Scope lock

Composition was locked at the Stage-4 plan-approval gate. Post-lock changes enter through the Deviation Log with an evidence line, never silently.

---

## Dependency Graph

```
                 ┌──────────┐
                 │  #4561   │  Check-22 G1-06 priority-carrier detector
                 └────┬─────┘
                      │  E1 (HARD, precedence-bearing)
                      │  corrects the instrument #3820 measures with
                      ▼
   ┌──────────┐  C1  ┌──────────┐        X1 (external, outbound)
   │  #3821   │╌╌╌╌╌╌│  #3820   │───────────────────────▶  #1686
   └──────────┘      └──────────┘                       (warn-mode-gate
    kind-form         enforce scope                       graduation)
    applicability     + new ADR

   ┌──────────┐  S1  ┌──────────┐
   │  #3711   │─────▶│  #3709   │      C3 contention + soft verification order
   └──────────┘      └──────────┘

   ┌──────────┐      ┌──────────┐
   │  #3826   │      │  #3703   │      independent, disjoint file sets
   └──────────┘      └──────────┘

   ══ C2: #4561 ╌ #3821 ╌ #3820 ╌ #3711 all EDIT core/deploy/deploy.sh ══
      (4-way edit contention spanning BOTH clusters)

   ───▶ hard/directed edge      ╌╌╌ file contention (not a dependency)
```

| ID | Edge | Class | Basis |
|---|---|---|---|
| **E1** | #4561 → #3820 | **HARD — precedence-bearing** | The detector defect inflates the failure count the scope decision is weighed against; both card bodies state the reciprocal reasoning. |
| **C1** | #3821 ⟂ #3820 | File contention | Both edit the gate-criteria schema's Gate-1 section on orthogonal axes; both bodies state "not blocking; sequence to avoid edit contention". |
| **C2** | #4561 ⟂ #3821 ⟂ #3820 ⟂ #3711 | File contention — the release's dominant surface | All four declare an edit to the deploy script. Spans **both** clusters. |
| **C3** | #3711 ⟂ #3709 | File contention | Both target the milestone-membership tool on opposite legs; the second declares a read, not an edit. |
| **S1** | #3711 → #3709 | **SOFT — verification ordering** | Landing the sub-class split first means the backfill card's "both gates read clean" criterion grades against the final emitted row shape and needs no re-run. |
| **X1** | #3820 → #1686 | External, **outbound** | Operator-authorized dependency exception. The external card is blocked *by* this release; it does not block this release. |

**Circularity: zero.** Two directed edges over disjoint node pairs cannot form a cycle. *Probe:* all directed edges enumerated from the seven bodies' Dependencies/Notes sections read in full; denominator 7 nodes / 2 directed edges. Sensitivity — E1 is a detected non-zero directed edge, so the enumeration is not blind. Specificity — the reverse edge #3820 → #4561 is **absent from both bodies**, so the asymmetry is real rather than an artifact of one-sided reading.

---

## Implementation Sequence

Stage 6 is **write-serialized** by design, so this is a **commit order on one release branch**, not a parallel plan. Design order and commit order differ; noted where they do.

| # | Issue | Why here |
|---|---|---|
| **0** | *(Engineering Commit 0)* | This plan file + the Commit-0 version re-verify. Authored by the first Stage-6 spoke, not by Stage 4. |
| **1** | **#4561** | **Foundation.** E1's tail — it corrects the measuring instrument the scope decision is weighed against. Also the narrowest, most testable change on the 4-way contended function, so it opens that surface first. |
| **2** | **#3821** | Second on **both** contended surfaces. Placed before #3820 deliberately: it is the *additive applicability declaration*, and the enforcement-layer edit is structurally larger and better landed on a settled applicability matrix than under one. |
| **3** | **#3820** | **Consumes** #4561's corrected count and #3821's decomposed kind-form class. Carries the release's only D-class scope decision and its only new ADR. |
| **4** | **#3711** | Opens the second cluster; also the last of the four deploy-script editors, placed after the first trio so the two checks' edits do not interleave in one function region. |
| **5** | **#3709** | S1 — lands after #3711 so its "both gates read clean" criterion grades against the final emitted row shape. |
| **6** | **#3826** | Independent, disjoint file set. Freely orderable; placed here to keep the two contention clusters contiguous. |
| **7** | **#3703** | Independent, disjoint. **Commits last, designed first** — largest design surface with a real over-firing risk, so its Solutioning was front-loaded. |

**Closure phrasing.** Every member above is to be **marked as closed at Stage 13**. Per-issue close-family verbs are deliberately avoided in this plan's prose, because the plan is transcribed into the pull-request body at Engineering and the auto-close parser is lexical — it fires on a close-family verb followed by a number regardless of the section it sits in.

**One commit per issue.** Per-issue revert granularity is a deliverable of this release, not an accident of how it was built.

---

## Stage Applicability Matrix

`cross-cutting` → Stage-5 activation bias **ALL**. Default for every stage is APPLY; a SKIP requires a stated reason. **No stage is skipped for any issue** — every card edits a shipped gate or check, so neither the Stage-5 nor the Stage-7/8 skip conditions are met.

| Issue | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Why Stage 5 activates |
|---|---|---|---|---|---|---|---|---|
| **#4561** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Which carrier set is canonical, and how the spec and detector are kept from diverging |
| **#3821** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | *Where* the pack-resolved kind set is resolved, without hardcoding an archetype |
| **#3820** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | **D-class decision** (three-option scope choice) + ADR threshold call |
| **#3711** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Output-shape choice with a stated downstream-parse risk |
| **#3709** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | A 74-item backfill needs a stated method and a recurrence guard, not a one-liner |
| **#3826** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Reuse the repo-integrity checker vs. a grep vs. a shared primitive |
| **#3703** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Largest design surface; the over-firing discriminator *is* the design |

**Parallel-eligible spoke counts:** Stage 5 = 7 · Stage 7 = 7 · Stage 8 = 7.

---

## Contention Map

### Within-release

| Shared surface | Cards | Edit / read | Severity |
|---|---|---|---|
| **`core/deploy/deploy.sh`** | **#4561, #3821, #3820, #3711** (edit) · #3709 (no change) | **4-way EDIT** | **HIGH — the release's dominant contention surface.** |
| **`core/schemas/gate-criteria-spec.md` § Gate 1** | **#3821, #3820, #3826** (edit) · **#4561 (verify-only)** | **3-way EDIT, 4-way touch** | **HIGH** — the three edits land on orthogonal axes within one section. |
| `core/deploy/tools/check-milestone-epic-membership.py` | #3711 (edit) · #3709 (read) | 1 edit, 1 read | MEDIUM |
| `core/deploy/tools/README.md` | #3711 · #3820 (conditional) | 2-way update | LOW — separate check rows |
| `release/references/how-to/hub-spoke-bridge.md` | #3826 (edit) · #3709 (regression-guard read) | 1 edit, 1 read | LOW |
| `.github/workflows/install-tests.yml` | #4561 | append-pattern | NONE — concurrent additions merge cleanly |
| Singletons | the label taxonomy, the readiness-scan spec, the Stage-07/08/02 pipeline files, the intake style guide, the two issue templates, the new ADR, the new regression test, the script-execution allowlist | — | NONE |

**Correction against the Stage-4 record (mandatory reconcile).** Stage 4 recorded the gate-criteria schema's Gate-1 section as a **2-way edit** (#3821, #3820) with #4561 verifying. Post-Solutioning it is a **3-way EDIT — #3821, #3820, #3826 — plus #4561 verify-only**, and **#3703 has exited the surface**. `[SOURCE]` hub consolidated determination across the Stage-5 wave outputs, relayed at Stage-6 chip briefing. Corroborating body-level probe at this build anchor: #3826's body carries **0** literal mentions of that file and #3703's carries **1** (a gate-ID citation, not an edit) — i.e. **the issue bodies do not yet reflect the post-Solutioning matrix**, which is expected (Stage 5 is where a file change matrix expands) and is recorded here so the three remaining editors of that section do not re-derive it from stale bodies. **The one thing that does not change: #4561 is verify-only on this file and authors no edit to it.**

**Resolution.** The Implementation Sequence serializes all four deploy-script editors (1 → 2 → 3 → 4) and all three Gate-1 editors (2 → 3 → 6). Under SINGLE topology every Engineering commit lands sequentially on one branch, so contention resolves at **commit ordering**, not at merge. No scope split is needed.

### Cross-release

- **Open-PR contention at the build anchor:** one draft sibling release pull request (`release/hub-spoke-execution-safety`) and one post-close chore pull request on the previously-claimed version. The sibling's declared file set **overlaps this release on one path** — the script-execution allowlist — which is an append-pattern file; concurrent additions in different regions merge cleanly. No other declared path overlaps.
- **Merged-PR window:** at Stage 4, 6 of 11 then-known matrix paths had been touched by merged work since the bundle base. That is a **staleness signal**, not a merge-conflict risk. The downstream rungs are Stage 9 Phase A6.5 mid-pipeline divergence (HALT-eligible), the Stage 7/8 entry informational checks, and the Stage 12 pre-merge check.

---

## Risk Register

| ID | Risk | Sev | Reversibility | Owner | Mitigation |
|---|---|---|---|---|---|
| **R1** | **Card 5's scope was 74× its stated size.** The body asserted a single residual unlabelled sub-task; a complete-population sweep measured **74**. | HIGH | CHEAP | #3709 | **SETTLED** at the Stage-4 gate: option (A) re-scope in place, backfill all 74, re-size S → M. The body, size, and criteria were amended. Zero post-mandate leaks — all 74 predate the creation-time mandate, which is confirmed holding. |
| **R2** | **The deploy script is a 4-way edit surface** spanning both clusters. | HIGH | CHEAP | all four | Strict serialization 1 → 2 → 3 → 4. Under SINGLE topology this is a commit-order constraint, not a merge-conflict risk. |
| **R3** | **The scope decision rests on a moving denominator.** The Check-22 population has been measured at 207, 204, 202, 189, 188, 169, 166 and — at this build anchor — **153**. | HIGH | MODERATE | #3820, #4561 | Both cards carry a pinned-baseline criterion. **Re-pin at build time and again at Stage 9.** No count from the Stage-4 comment enters a shipped artifact unmeasured; the build-time re-pin is recorded in § Verification Plan. |
| **R4** | A sub-scope of card 6 was a measured no-op at planning time. | MEDIUM | CHEAP | #3826 | Dropped from the build and **recorded as already-resolved on the card** — deliver the record, not silence. Headline scope unaffected. |
| **R5** | **Card 7 over-fires and has no script executor** — a judgment-assisted semantic check. | MEDIUM | CHEAP | #3703 | A legitimate *declared, verification-deferred* case: record the declared method, do not lossily rewrite it. Its false-positive-rate criterion over a contained-scope sample is the calibration gate and must actually run. |
| **R6** | **Card 3's blast radius is platform-wide until reverted** — the chosen scope changes when *every* future deploy blocks. | MEDIUM | **MODERATE** | #3820 | Card's own rating. Mode-file and doc edits revert cleanly; deploys executed between merge and any revert ran under the new scope. Accepted, and gated at Stage-9 Deep review. |
| **R7** | Card 4's output-shape change could break a downstream parser. | MEDIUM | CHEAP | #3711 | Repo-wide consumer probe **with a control** before changing the shape. |
| **R8** | The planning-stage structural-reorg predicate over-fires on release-plan re-versions. | LOW | CHEAP | — | Out of scope; inspected and dismissed at Stage 4. Logged to § Recommendations. |
| **R9** | **Release is oversize** — 47 effective pts against a 25 ceiling. | MEDIUM | MODERATE | release | **Settled** at the recorded G3-15 override, disposition (C). Carried, not re-litigated. R2 is corroborating evidence for (C). |
| **R10** | Matrix paths touched by merged work since the bundle base. | LOW | CHEAP | release | Stage 9 Phase A6.5 + Stage 7/8 entry checks + Stage 12 pre-merge check are the downstream rungs. |
| **R11** | **The version slot is contested in principle.** In-flight sibling population moved 0 → 1 since Stage 4. | LOW | CHEAP | release | Designed behaviour of the atomic claim: whichever release reaches its Stage-12 ref-CAS first binds the slot; the loser re-derives at no rename cost, because every name here is slug-primary. Stage 9 Phase A6.6 re-measures and owns the verdict. |
| **R12** | **Three degradation postures could land in one check.** The three Check-22 cards each specify what happens when their block-start primitive is unavailable, and they did not originally agree. | MEDIUM | CHEAP | #4561, #3821, #3820 | Commit 1 lands the **single-finding, criterion-not-evaluated** posture and states it as a named convention in the block, so the two following editors bind to it rather than inventing a third. See the Deviation Log. |

**Rollback complexity:** MODERATE overall. Ten of twelve risks are `git revert`-clean; the two exceptions are named in § Rollback.

---

## Release Class Declaration

**`cross-cutting` — CONFIRMED** against live file state at Stage 4.

| Trigger | Fires? | Evidence |
|---|---|---|
| (a) The matrix touches ≥3 pipeline stage files | **FIRES** | Exactly three distinct stage files, all present on the mainline |
| (b) The matrix touches ≥3 of the closed 7-member governance set | does not fire | Two members touched |
| (c) ≥3 in-bundle compositional edges | does not fire | Exactly one precedence-bearing edge (E1); the rest is file contention, not dependency |

Single-trigger classification via (a); multi-trigger resolution is not engaged. **Differentiation posture:** engagement density **Tight** (per-spoke completion surfaces a consolidated briefing; the cross-decision upstream-compatibility scan is explicit at every D-decision) · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

---

## Operator Decisions (D-Gate block)

| Decision | Verdict | Rendered | Reversibility |
|---|---|---|---|
| Stage-4 release plan + Release Outcome Statement | **APPROVED** | Stage-4 plan-approval gate, 2026-08-05 | MODERATE · HIGH |
| **R1** — card 5 disposition | **(A) re-scope in place** — backfill all 74, re-size S → M | Stage-4 plan-approval gate | CHEAP · HIGH |
| Quota-budget envelope | Conservative default retained; the runtime checkpoint re-validates each wave | Stage-4 plan-approval gate | CHEAP · HIGH |
| **D-Concurrency posture** | **P0 fully-serial** | Stage-4 D-Gate | CHEAP · HIGH |
| **D-Version** | **Recorded determination, not a gate** — rule-computed, no operator judgment applies. Re-verified at Commit 0 above. | Procedure-0 entry; re-verified 2026-08-06 | CHEAP · HIGH |
| **#4561 D-3** (schema Gate-1 one-line reconcile) and **D-4** (regression test + CI wiring) | **APPROVED as Tier-2 matrix expansions** at the wave-1 consolidated briefing; **D-3 subsequently re-routed** to the three Gate-1 editors, leaving #4561 verify-only on that file | wave-1 briefing, then hub routing | CHEAP · HIGH |
| **#3820's ADR** | Threshold call belongs to that card. **Next-free is ADR-120**, not the ADR-119 the Stage-4 plan named — see the Deviation Log. | pending at Stage 5/6 for that card | CHEAP · HIGH |

The release's **single D-class scope decision** (the three-option enforcement-scope choice) belongs to card 3 and is rendered on the corrected failure decomposition commit 1 produces.

---

## Quota Budget

**Verdict:** **WARN** (Checkpoint A).
**Parallel-eligible spokes per parallel stage:** Stage 5: 7 · Stage 7: 7 · Stage 8: 7.
**Per-spoke cost estimate:** size-bucket **ordinal band** — source **heuristic**; telemetry medians are not available, and no comparable population meets the per-bucket cutover predicate, so every bucket retains its ordinal band as the floor. Worst batch: 2 × L + 4 × M + 1 × M.
**Assumed/stated remaining usage-window envelope:** **UNSTATED by the operator at hub start** → conservative default assumed. This is the estimate's weakest input and carries `[ASSUMPTION – CONFIRM]`.
**Estimated cumulative draw % (worst parallel batch):** **not computable as a percentage** — the per-spoke figure is ordinal and the envelope is assumed rather than stated. Ordinal cumulative is **high**.
**Routing:** **WARN → window-aware launch timing + split batch.** Split each parallel wave **4 + 3**, distributing the two L cards across *different* sub-waves rather than co-launching them.
**Honesty note:** FAIL was considered and **not** rendered — rendering FAIL on an assumed envelope would over-claim a measurement never taken. WARN is the honest band, and its routing is actionable.
**Note:** the runtime checkpoint re-validates at **every** parallel wave with PROCEED / SERIALIZE / DEFER / REDUCE-scope. Staggering is a rate-limit defence, not a usage-window mitigation — this is an envelope problem, never a timing problem. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Cross-Issue Acceptance Criteria

Release-scoped cohesion constraints spanning ≥2 issues, graded on the **merged pull request** at Stage 9. Distinct from per-issue criteria and from the Stage-5 per-issue-pair integration criteria.

- [ ] **CIAC-1 (#4561 × #3821 × #3820 — the deploy script's Check-22 block):** the three edits **compose into one check**, not three forked code paths — after all three land, Check 22 retains exactly **one** bundled-issue-population query site and **one** priority-detection primitive.
  *Shared surface:* the Check-22 block.
  *Method (**qualified at Commit 0 — see below**):* enumerate matches **within the Check-22 block range only**, assert exactly one issue-list query site, and assert its scope filter matches the scope recorded in the schema's Gate-1 enforcement-layer split.
  > **Method qualifier (mandatory before Stage 9 runs it).** The Stage-4 method as written — a bare repo-wide `grep -n 'status: bundled' core/deploy/deploy.sh` — returns **9 hits at this build anchor** (verified: lines 5024, 5151, 5155, 5163, 5577, 5583, 5659, 5700, 11355), of which **only line 5700 is a query site** and only that one sits inside the Check-22 block. *Controls:* sensitivity — the literal `Check 22` returns 11 hits, so the file is readable and the pattern class is live; specificity — `status: zzqqxx` returns 0, so a zero is reachable. **The method needs a block-range qualifier**, or it grades an assertion it cannot support. Separately, CIAC-1's second clause (*one priority-detection primitive*) has **no stated method at all** in the Stage-4 plan; the executable form is the drift-guard arm shipped by commit 1 (see § Verification Plan), which discriminates an intact delegation from a regressed one.
- [ ] **CIAC-2 (#4561 × #3820 — the decomposed failure count):** the enforce-scope rationale cites a G1-06 failure count measured **after** the detector fix, at a pinned commit anchor, decomposed by cause.
  *Shared surface:* the rationale text in the schema's Gate-1 enforcement-layer split.
  *Method:* read the recorded rationale; assert it names per-cause counts (kind-form scope / detector carrier / genuinely-absent field) **plus** a commit anchor and read date, and that the anchor is at or after commit 1. **This is the release's reason for existing** — it is the cohesion constraint the keep-together decision was made to protect.
- [ ] **CIAC-3 (#3821 × #3820 × #3826 — the schema's Gate-1 section):** all scope statements land and are mutually consistent — none overwrites another, and a kind-form card declared **exempt** is not counted inside the population another card's chosen scope enforces against.
  *Method:* read the section; assert every landed scope statement is present and that no card class is simultaneously exempt-by-one and enforced-by-another.
  > **Widened at Commit 0.** Stage 4 authored this as a 2-way constraint. The wave-1 briefing widened it to grade N-way consistency as the section's editor set grew, and referred to the widened constraint as `CIAC-6`. The Stage-4 plan authored only CIAC-1..5 and the Gate-1 consistency constraint is **CIAC-3**; this plan therefore widens CIAC-3 rather than minting a sixth identifier, and records the naming delta so Stage 9 grades the constraint **once**, across all three editors plus the verify-only touch, under whichever label it reads. **Routed to the hub for confirmation** — it is a labelling reconciliation, not a new criterion.
- [ ] **CIAC-4 (#3711 × #3709 — the sibling check's M2 leg):** after both land, one run of the membership tool emits sub-class-distinguished rows **and** carries zero findings traceable to a missing sub-task label.
  *Method:* run the tool against the repository; assert every emitted `named-not-member` row carries a sub-class token, and assert no emitted row references a stage-shaped title lacking the sub-task label.
- [ ] **CIAC-5 (#3826 × #3703 — advisory posture):** both cards add a **non-blocking** signal; neither introduces a hard-fail path, so the release adds review coverage without adding an enforcement layer.
  *Method:* locate each added check in its stage file; assert each is stated as advisory with its authoritative gate named.

---

## File Change Matrix

Machine-readable path list — **one path per line, no decoration** — for deterministic extraction by downstream Stage 7 / 8 / 9 chips. This is the union known at Engineering Commit 0: the Stage-4 matrix reconciled forward through the Solutioning designs the hub has consolidated. Later Engineering slices that expand it record the delta in the Deviation Log and extend this block in the same commit.

```
core/deploy/deploy.sh
core/deploy/tests/test_g1_06_priority_carrier.sh
core/config/allowlists/script-execution-allowlist.txt
.github/workflows/install-tests.yml
core/schemas/gate-criteria-spec.md
core/deploy/tools/check-milestone-epic-membership.py
core/deploy/tools/README.md
core/specs/label-taxonomy.md
release/references/specs/release-readiness-scan-spec.md
release/references/pipeline/stage-07-dev-testing.md
release/references/pipeline/stage-08-qa-testing.md
release/references/pipeline/stage-02-triage.md
release/references/how-to/hub-spoke-bridge.md
release/references/how-to/intake-style-guide.md
.github/ISSUE_TEMPLATE/bug.yml
.github/ISSUE_TEMPLATE/improvement.yml
core/ADRs/ADR-120-<slug>.md
release/releases/plans/release-check-enforcement-gates_RELEASE_PLAN.md
```

Per-path intent:

| Path | Card(s) | Intent | Note |
|---|---|---|---|
| `core/deploy/deploy.sh` | #4561, #3821, #3820, #3711 | **edit** ×4 | Priority-carrier detection · title-floor kind resolution · Check-22 query scope + the enforcement emitter · the sibling check's M2 warn line |
| `core/deploy/tests/test_g1_06_priority_carrier.sh` | #4561 | **add** | Hermetic fixture table + executable-glue arm + drift guard |
| `core/config/allowlists/script-execution-allowlist.txt` | #4561 | **edit** | Companion allowlist rows for the added executable, in all four resolved invocation forms, so the test is runnable agent-side on arrival |
| `.github/workflows/install-tests.yml` | #4561 | **edit** | Wire the new regression test **and** the pre-existing title-floor test, which had never been CI-wired |
| `core/schemas/gate-criteria-spec.md` | #3821, #3820, #3826 · **#4561** | **edit** ×3, **verify** ×1 | Gate-1 kind-form applicability · Gate-1 enforcement-layer split · required-CI-check coverage · **#4561: carrier-set agreement only, no edit** |
| `core/deploy/tools/check-milestone-epic-membership.py` | #3711 · #3709 | **edit** · **verify-no-change** | M2 sub-class emit + self-test mutation-kill cases · the exemption predicate is correct, the input data is wrong |
| `core/deploy/tools/README.md` | #3711 · #3820 | **edit** · **edit (conditional)** | The sibling check's M2 output shape · the Check-22 evaluated population, only if that row describes it |
| `core/specs/label-taxonomy.md` | #3709 | **edit** | Its rule and the bridge procedure name different application points for the same label — reconcile to one authority |
| `release/references/specs/release-readiness-scan-spec.md` | #3826 | **edit** | Add the required-CI-checks dimension; split mergeability into draft-blocked vs. checks-failing |
| `release/references/pipeline/stage-07-dev-testing.md` | #3826 | **edit** | Issue-reference-validity spot-check (advisory) |
| `release/references/pipeline/stage-08-qa-testing.md` | #3826 | **edit** | Same spot-check |
| `release/references/pipeline/stage-02-triage.md` | #3703 | **edit** | Scope-altitude consistency check + a conforming gate ID |
| `release/references/how-to/hub-spoke-bridge.md` | #3826 · #3709 | **edit** · **verify-no-change** | Required-check read as a numbered step · **must-NOT-change:** the creation-time sub-task-label mandate, its template row, and the blocking unlabelled class must all survive |
| `release/references/how-to/intake-style-guide.md` | #3703 | **edit** | Scope-altitude guidance + two worked examples |
| `.github/ISSUE_TEMPLATE/bug.yml` | #3703 | **edit** | Expected-behaviour ↔ affected-files relationship |
| `.github/ISSUE_TEMPLATE/improvement.yml` | #3703 | **edit** | Description / proposed-change ↔ affected-files relationship |
| `.github/ISSUE_TEMPLATE/epic.yml`, `story.yml` | #3821 | **reference only — no change** | Field-set and title-convention inputs to the mapping |
| `core/ADRs/ADR-120-<slug>.md` | #3820 | **add (conditional)** | Only if the chosen scope meets the ADR threshold. **120 is next-free**, verified global-monotonic across both homes at this build anchor |
| `release/releases/plans/…_RELEASE_PLAN.md` | — | **add** | This file. Engineering Commit 0; flat slug-primary path |

**Non-file state mutation — not representable above, and not `git revert`-ible.** Card 5 applies a label to **74** GitHub issues. See § Rollback.

**Path count:** 18 machine-readable rows (17 repo paths + this plan). Two are new files; one is a conditional add.

---

## Verification Plan

### Build-time re-pin (R3 discharge)

Mandated by R3 and by card 1's own pinned-baseline criterion: **no count from the Stage-4 comment enters a shipped artifact unmeasured.** Re-measured at the build anchor `origin/main` @ `50f26869`, 2026-08-06 (Thursday) / `2026-08-07T01:44Z`.

| Quantity | Stage-4 figure | Corrected figure | **Re-pinned at build anchor** |
|---|---|---|---|
| Check-22 query denominator — **open** `status: bundled` | 207 | **204** (state-open qualifier) | **153** |
| …never reach the priority criterion (label-count fail, then `continue`) | 151 | — | **104** |
| …reach evaluation (improvement + bug + observation) | 56 | — | **49** (31 improvement / 14 bug / 4 observation) |
| …priority-criterion applicable (improvement + bug) | 51 | — | **45** |
| Kind-form cohort share of the non-sub-task bundled population | 52 of 103 | **47 of 103** | **64 of 93** |
| Non-sub-task bundled population | 103 | — | **93** (60 sub-task rows excluded) |
| Priority-label family count (must be zero) | 0 | — | **0** |

**The denominator is the point, not the numerator.** This population has now been measured at 207, 204, 202, 189, 188, 169, 166 and 153. A bare count from any of those instants is stale on arrival; every count above carries its anchor, and Stage 9 re-pins again.

**Kind-form cohort — definition stated, because the figure is only meaningful with it.** *Cohort* = open `status: bundled` cards, **sub-task rows excluded**, carrying a work-hierarchy kind label (`type:epic` / `type:story` / `type:task` / `type:card`). At the build anchor: **64 of 93**, decomposing as **40** carrying a kind label and **no** intake-tier label at all (these fail the label-count criterion and `continue` before any other criterion runs) and **24** carrying a kind label *and* exactly one intake-tier label (these reach evaluation). The complement is 29 with no kind label, 25 of which carry exactly one intake-tier label. `type:epic` and `type:card` are present in the label vocabulary but carry **0** members at this anchor; the cohort is entirely `type:story` (27) + `type:task` (37).

> **Probe record.** *Invocation:* `gh issue list --state open --label "status: bundled" --limit 5000 --json number,title,body,labels`, then the check's own Step-1/2/3 classification replicated in a single pass. *Truncation guard:* 153 returned against an independent `--json number --jq 'length'` count of **153** — neither arm reached the limit. *Extraction non-emptiness:* **153 of 153** bodies non-empty, **686,076** total body characters — a hash or count over a failed read compares equal to any other failed read, so this is proven rather than assumed. *Sensitivity:* the shared detector resolves **19** of the 45 applicable bodies (non-zero, so the detector is not blind), and a synthetic heading-form fixture resolves its level. *Specificity:* a synthetic non-priority heading resolves nothing; a synthetic mid-prose mention resolves nothing; a control marker never used in the corpus returns **0 of 153**. *Label-family arm:* `priority:` → **0**; sensitivity control `type:` → **8** labels; specificity control `zzqqxx:` → **0**. **No zero in this section rests on a probe whose control also returned zero.**

### Per-issue verification

| Card | Method | Expected result |
|---|---|---|
| **#4561** | Run the hermetic regression test; re-read the check's inline comment; re-run the population survey at a pinned anchor; enumerate the priority label family | Every live carrier resolves its P-level digit and the no-carrier control does **not**; the comment asserts no contradicted carrier distribution; before/after counts recorded with anchor and read date; label-family count 0 with a non-zero sensitivity arm |
| **#3821** | Read the Gate-1 applicability surface and the doc-impact row; search both gate surfaces for the kind names as scope literals; run both gates over one fixture per live kind plus a governance-intake control | Both gates state in-scope-with-mapping **or** exempt-with-rationale — never silence; the kind set resolves via the pack union, never a hardcoded pair; every fixture yields a determinate verdict; governance-intake verdicts **byte-identical** to the pre-change run |
| **#3820** | Read the Gate-1 enforcement-layer split; locate the ADR or the recorded non-threshold rationale; read the Check-22 issue query; fixture run with one out-of-release failure and the control with that same failure moved *into* the release | Scope and rationale recorded; query filter matches the documented scope; the out-of-release failure does **not** block and the control behaves per the recorded scope; per-cause counts pinned |
| **#3711** | Fixture with one reference of each sub-class; the same fixture for both counters; the opposite-leg fixture; **mutate the sub-class resolution to a constant** and confirm the new self-tests fail | Sub-classes distinguishable **from the emitted text alone**; both counters emitted and summing to the total; the opposite leg byte-identical; the M2 route still passes through the warn emitter; the mutation kills the new cases |
| **#3709** | Per-issue label read after backfill; re-run the membership tool; **must-NOT-change** search of the bridge template and the blocking unlabelled class; full-population sweep with the truncation guard and both probe arms | Every backfilled issue carries the label; no residual finding traceable to the label class; the creation-time mandate still present in the template and the unlabelled class still blocking; sweep count recorded with its baseline date |
| **#3826** | Read the readiness-spec dimension list and the mergeability dimension; read both stage files for a spot-check naming **both** enforced classes; read the bridge procedure for a **numbered** step; fixture pull request with one failing required check plus an all-passing control | Dimension present and states that any failing required check is a NO-GO input; draft-blocked and checks-failing are distinct named states; the read is a numbered step, not prose; the fixture reports NOT-READY naming the check and the control reports READY; the spot-check is stated advisory with branch protection named authoritative |
| **#3703** | Read the triage stage file for the check and a conforming gate ID; **declared method** — run the judgment-assisted check against two named fixture bodies, each with a contained-scope control; read the check definition for annotation-not-block; sample run for false-positive rate at a pinned anchor | Check and conforming gate ID present; both fixture shapes flagged and both controls **not** flagged; the output is an annotation with no blocking path; both worked examples present; false-positive rate recorded with commit anchor and read date. **The executor is a reasoning agent, not a script — a legitimate declared, verification-deferred case; the method is recorded, not lossily rewritten** |

**Non-vacuity is a hard requirement, not a nicety.** Every card's criteria already carry an explicit control arm — a no-priority body, a governance-intake control, an in-release failure, a contained-scope issue, an all-passing pull request. **A control that cannot fail is a broken probe, and a zero whose control also returned zero is reported as unusable, never as clean.** Do not let a later slice silently drop one.

**Cross-issue:** CIAC-1..5 above, graded at Stage 9 on the merged pull request. Per single-runner discipline, Stage 9 reads verdicts emitted at Stage 6/7 rather than re-running the methods.

---

## Delivery Strategy

- **One release branch** `release/release-check-enforcement-gates`, cut from the mainline at the build anchor. Slug-primary; no version stem.
- **One pull request**, created in **draft** at Stage 6 and transitioned to ready-for-review at the Stage-9 gate — so the operator reviews completed work, not work in progress.
- **One commit per issue**, plus this Commit 0. Per-issue revert granularity is a deliverable.
- **Commit-message form** `fix(#N): …` / `feat(#N): …` referencing the issue number. Signed commits per repository policy; never bypassed.
- **Concurrency posture P0 fully-serial** — one Engineering chip at a time; the next waits until the prior commit lands. Force-push, including the lease-guarded form, is prohibited on the shared branch.
- **Parser-clean body discipline.** Close-family verbs adjacent to an issue number appear in exactly one place in the pull-request body — the dedicated issue-references block. Everywhere else uses safe phrasing, because the auto-close parser is lexical and section context does not constrain it.

---

## Rollback

| Layer | Mechanism | Reversibility |
|---|---|---|
| Whole release | revert the merge commit | **CHEAP** |
| Single issue | revert that issue's commit — preserved by one-commit-per-issue | **CHEAP** |
| **Card 3's scope change** | reverting restores the backlog-wide query. Any deploy executed between merge and revert ran under the new scope; that cannot be un-run | **MODERATE** |
| **Card 5's label backfill** | **not `git revert`-ible.** Applying a label to 74 GitHub issues is state outside the repository | **CHEAP but out-of-band** — reverse sweep over the recorded identifier list |
| The new ADR | reverting removes the file; **the number is not reused** — ADR numbers are immutably allocated and supersession is a status transition plus a new record | CHEAP |

**Rollback pre-condition — must be satisfied before card 5 executes.** The backfill **records the exact issue-number list it mutated** into this plan's Deviation Log or the issue thread. Without that list the reverse sweep cannot distinguish issues this release labelled from issues that already carried the label, and a blind reverse sweep would strip correctly-labelled sub-tasks. **This is the release's single genuine rollback hazard.**

**Trigger points:** Stage-9 Deep review (pre-merge — the answer there is NO-GO, not rollback); the Stage-12 pre-merge freeness check; post-merge, operator-authorized per the release protocol.

---

## Deviation Log

Deltas discovered after the Stage-4 output, folded in here rather than silently applied. Each carries its evidence.

| # | Delta | Class | Evidence | Disposition |
|---|---|---|---|---|
| **AI-007a** | **Kind-form cohort figure corrected.** Stage 4 recorded 52 of 103; the corrected figure is **47 of 103**, and the population has moved repeatedly since. | Substantive | Hub correction relayed at Stage-6 chip briefing; re-measured at this build anchor as **64 of 93** with the cohort definition stated in § Verification Plan | **Recorded with all three figures and their anchors.** A bare share is meaningless without its denominator and its definition; both are now stated. |
| **AI-007b** | **Check-22 denominator corrected.** Stage 4 recorded 207; the corrected figure is **204** at the time of that measurement, with the **state-open** qualifier. It has since read 202, 189, 188, 169, 166. | Substantive | Hub correction; re-measured here at **153** with a truncation guard and an extraction-non-emptiness proof | **Re-pinned.** R3 is the standing mitigation: re-pin at build time and again at Stage 9. |
| **AI-007c** | **Gate-1 contention corrected.** Stage 4 recorded a 2-way edit (#3821, #3820) with #4561 verifying. It is a **3-way EDIT (#3821, #3820, #3826) plus #4561 verify-only**, and **#3703 has exited** the surface. | Substantive | Hub consolidated determination across the Stage-5 wave outputs; corroborating body-level probe at this anchor recorded in § Contention Map | **Contention Map and matrix updated.** #4561 authors no edit to that file. |
| **D-1** | **#4561's design reframed from *canonicalize* to *reconcile*.** The canonical carrier decision already exists on the mainline as **ADR-111**, dated 2026-08-03, which names the deploy-time gate check as the surface still owing reconciliation and forbids authoring a fourth carrier-specific matcher. | Substantive | ADR-111 read at the mainline; its consequence clause quoted verbatim in the Stage-5 output | **Design against live state.** Check-22 delegates to the shared detector; it authors no grammar. Materially narrows the change on the 4-way contended function. |
| **D-3** | **#4561's proposed one-line reconcile of the schema's Gate-1 line was approved, then re-routed.** Approved as a Tier-2 matrix expansion at the wave-1 briefing; subsequently re-routed to the three Gate-1 editors, leaving #4561 **verify-only**. | Routing | Wave-1 briefing decision; hub routing relayed at Stage-6 chip briefing | **Not taken by commit 1.** The residual is surfaced to the hub in commit 1's output: the schema's illustrative regex is **unanchored** and, run literally, resolves a priority from mid-prose. Whoever edits that section should fix it; if none does, it routes as a next-release issue. **AC-5 still passes on set-agreement**, which is what the card asks. |
| **D-4** | **#4561 adds a regression test and CI wiring** — a matrix expansion beyond the card's two declared files. | Scope (Tier 2) | Approved at the wave-1 briefing. Grounding: of the test scripts under the deploy test directory, a measured minority were CI-wired and the direct sibling precedent (the title-floor test) was **not** among them | **Approved and taken.** The new test is wired, **and the orphaned sibling test is wired in the same step** — a one-line adjacent fix to a net that never ran. |
| **AI-adv-1** | **Degradation posture corrected before commit 1 was written.** The Stage-5 design claimed to follow the sibling primitive-degradation idiom "verbatim"; the adversarial review proved it did not — the sibling **exits the check** on a missing primitive (one finding) while the design flagged and continued, measured at **1 + N** findings, all of which increment the issue counter in enforce mode. | Major | Phase-A6.5 adversarial review, executed against the live payload | **Corrected in commit 1: single finding, criterion marked not-evaluated, no fan-out.** Both sibling Check-22 cards specify the same posture; commit 1 states it as a named convention in the block so the two following editors bind to it (R12). |
| **AI-adv-2** | **The anti-drift net could not detect its own regression.** Falsification proved all three drift arms and all sixteen fixtures returned GREEN on a state where the delegation had been deleted and only its comment retained. | Major | Phase-A6.5 falsification run, two states (intact / regressed) | **Corrected in commit 1.** The guard arm is tightened to non-comment lines and an **executable-glue arm** is added, and the discrimination is demonstrated rather than asserted — see commit 1's output. |
| **AI-adv-3** | **The delegate's failure posture is stated, and stderr is no longer discarded.** The design redirected the delegate's error stream to the null device, leaving a failure message that named only a path. | Minor-to-Major | Phase-A6.5 review; the four sibling delegating checks all capture and surface the stream | **Corrected in commit 1**, consistent with the systemic finding that several checks cannot represent a degraded state distinctly from a clean one. |
| **AI-ADR** | **The release's new-ADR number is ADR-120, not ADR-119.** | Substantive | Verified at this build anchor: **119** records across both homes, contiguous, highest present **ADR-119** | **Matrix updated.** Allocate at the mainline next-free slot; a working-tree glob is not the authority for the anchor, and an unmerged sibling claim is advisory. |
| **AI-CIAC** | **CIAC-3 widened; naming reconciled.** The wave-1 briefing widened the Gate-1 consistency constraint to N-way and called it `CIAC-6`; the Stage-4 plan authored only CIAC-1..5 and that constraint is CIAC-3. | Labelling | Wave-1 briefing text vs. the Stage-4 criteria list | **CIAC-3 widened in place**; no sixth identifier minted. **Routed to the hub for confirmation.** |
| **AI-CIAC-1m** | **CIAC-1's grading method is not runnable as written** — the bare repo-wide search returns 9 hits, only one of which is a query site. | Method defect | Measured at this build anchor with sensitivity and specificity controls | **Qualifier written into CIAC-1 above** and surfaced to the hub. Its second clause has no stated method at all; the executable form is commit 1's drift-guard arm. |
| **AI-roster** | **In-flight sibling population moved 0 → 1** since Stage 4. | Baseline | `gh pr list --state open` at this build anchor | **R11 opened.** No effect on the computed next-free; the slot is contested in principle and resolves at the atomic claim. |

---

## Recommendations

Carried forward from Stage 4, plus what Commit 0 found. None is actioned inside this release unless a card owns it.

1. **Re-pin every count at build time and again at Stage 9.** Discharged for the counts above; still binding on the cards that have not yet built.
2. **Preserve the control arm in every acceptance criterion through Solutioning.** A rewrite that silently drops one converts a valid gate into a vacuous one.
3. **State the quota envelope at hub start** so the runtime checkpoint has a real input rather than inheriting the conservative default.
4. **The planning-stage structural-reorg predicate over-fires on release-plan re-versions** (R8). Re-versioning now moves a plan across a directory boundary, so the dir-crossing predicate fires on routine history. Worth an intake ticket.
5. **The stage-title predicate that card 5's sweep uses carries a measured false-positive rate.** Classify by title *shape* with a read-through, never by the bare prefix.
6. **The schema's Gate-1 illustrative regex is unanchored** and, taken literally, resolves a priority from mid-prose. It also cites no reference implementation, which is the duplicate-source condition that produced card 1's bug. Owned by whichever Gate-1 editor takes it; otherwise a next-release issue (D-3 above).
7. **A third divergent priority reader survives** outside this release's scope — the approved-queue-depth tool still binds a label prefix set that the label taxonomy forbids, so it reports its whole population as unlabelled. Filing it closes the three-reader divergence completely.
8. **The governing ADR for card 1's design is still at `Proposed`** although its implementation is merged. This is the platform's known ratification-flip gap rather than a defect in that record, and it does not block: the decision is recorded and its implementation shipped.

---

## References

Designated reference block. Each entry pairs the tracker number with a summary noun phrase, so the meaning survives even if the number does not.

### Issue References

| Number | What it is |
|---|---|
| Milestone **300** | `release-check-enforcement-gates` — this release's milestone; seven parent members, 47 effective points on a recorded override, composition locked at the Stage-4 plan-approval gate. |
| **#4561** | Check-22 / G1-06 binds a priority carrier the corpus does not use — the detector fix that corrects the instrument the scope decision is weighed against. Marked as closed at Stage 13. |
| **#3821** | Check-22 title floor and the doc-impact gate reconciled with the two new kind forms. Marked as closed at Stage 13. |
| **#3820** | Check 22 gates deploys on backlog-wide triage status rather than the release being deployed — the release's single D-class scope decision. Marked as closed at Stage 13. |
| **#3711** | The membership check's M2 leg cannot distinguish named-in-another-milestone from named-in-no-milestone. Marked as closed at Stage 13. |
| **#3709** | Pipeline stage sub-tasks ship without the label the pipeline's own gates key on — re-scoped from 1 to 74 at the Stage-4 gate. Marked as closed at Stage 13. |
| **#3826** | Stage 5-9 review and the readiness scan miss the one CI signal that actually blocks a merge. Marked as closed at Stage 13. |
| **#3703** | No gate checks that a ticket's stated expected behaviour is contained by the files it declares. Marked as closed at Stage 13. |
| **#1686** | Warn-mode gate graduation — blocked *by* this release's scope decision; an outbound external edge that does not block this release. |
| **#4775** | The Stage-4 release-planning sub-task carrying this plan's source output and the original version determination. |
| **#4808** | The Stage-5 Solutioning sub-task for the detector card, carrying its design, its adversarial review, and the hub's independent verification. |
| **#4810** | The Stage-6 Engineering sub-task for the detector card, where this Commit 0 is reported. |
| **#4907** | The systemic finding that several checks fail open — a broken measurement is indistinguishable from a clean result. Commit 1's degradation posture is written to conform to it. |

### Related records

- **ADR-092** — release identity is slug-primary; the version binds only at the Stage-12 atomic claim. Governs every naming decision in this plan.
- **ADR-111** — the P-level digit is the canonical priority satisfier and the carrier is not part of the contract; it ships the reference implementation and names the deploy-time gate check as the surface owing reconciliation. Governs card 1's design.
- **ADR-008 / Pattern-P4** — the deploy script is declared cross-module orchestration infrastructure and is exempted from the cross-module boundary audit, which is the dispositive sanction for its consumption of release-module tools.
