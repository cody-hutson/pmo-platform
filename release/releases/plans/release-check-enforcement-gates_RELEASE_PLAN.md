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

*Phase C1 (G6-05). Authored at Engineering Commit 0 in provisional form; **refreshed at Engineering Commit 7 — the final slice — to describe what actually shipped.** All seven commits have landed.*

**Outcome.** The platform's deploy-time triage-readiness gate reported on the wrong things. It read a priority field through a carrier the corpus does not use, so it failed most of the issues it evaluated for a reason that had nothing to do with their readiness. It evaluated the entire backlog on every deploy rather than the release actually being deployed, so an unrelated stale card could block work it had no bearing on. It did not know about the two newest work-item forms, so it graded them against a rubric written for a different shape. A sibling check could not tell "named in another milestone" from "named in no milestone", so the operator could not act on its findings. The pipeline's own stage artifacts were missing the label its own gates key on, so the pipeline tripped itself. Two review stages never read the one CI signal that actually blocks a merge. And nothing checked whether a ticket's stated expected behaviour is contained by the files it says it touches.

**Each of those instruments now measures the thing it claims to measure.** The detector fix landed **first**, so the scope decision downstream of it was rendered on corrected data rather than on a count inflated by a reader bug — and that decision, taken at commit 3, split one undifferentiated backlog-wide authority into a standing detector plus a release-scoped gate, with an ADR recording the durability contract. Nothing was silenced: every finding that used to gate and no longer does is still emitted, at recommend-tier, with its tier named. Three of the seven commits ship **hermetic regression nets that drive the shipped code** — extracted between its own sentinels and graded against deliberately regressed copies that must go red — rather than replicas of it. The last commit adds the one genuinely new capability: an advisory triage determination that asks whether a ticket's asserted outcomes are producible from its own declared scope, homed as a **stage-local, non-gate-blocking** criterion riding an A6 summary field that already existed, so it adds review coverage on the pipeline's most expensive failure class without adding an enforcement layer, a registry criterion, or a single edit to any contended surface.

**Issues resolved.** Seven parent cards, one commit each; each is marked as closed at Stage 13. See § Members and the designated reference block at the foot of this plan.

**Key decisions.** Recorded per-card in § Operator Decisions and in the Deviation Log, which grew from 12 rows at Commit 0 to its present size — most of that growth is adversarial-review findings **fixed before their commit was written** rather than discovered after. The release's single D-class scope decision belongs to the Check-22 population card and was rendered on the corrected failure decomposition the first commit produced. Two Blockers were pinned into Engineering as gating acceptance criteria and both are discharged executably, with evidence, in § Verification Plan. Two counter-designs were adopted; three were routed to next-release issues with the reason stated rather than declined silently.

**Reversibility.** **MODERATE** overall / confidence **HIGH**. Nine of ten register risks are `git revert`-clean at whole-release and per-issue granularity (one commit per issue). Two exceptions are named in § Rollback: the label backfill is a GitHub state mutation outside the repository, and a deploy executed between merge and any revert ran under the changed enforcement scope and cannot be un-run. Two skill packages were rebuilt in-release; a revert of either content commit must re-run the package build in the same change.

**Downstream impact.** The enforcement posture does **not** change in this release beyond the population scoping the Check-22 card's decision records; the priority-detector fix is deliberately posture-neutral, so a drop in the failure count must not be read as a graduation. The new triage determination is advisory by construction — it is outside the Layer-2 judgment aggregate, outside the Stage-2 Workflow-Readiness pass set, and outside the deploy-time check's population, and no path leads from it to a blocked intake. It carries a cutover clause, so it fires only on issues entering triage after this release's merge SHA; this release is exempt from its own new determination.

**Cross-references.** § Dependency Graph, § Contention Map, § Cross-Issue Acceptance Criteria, § Verification Plan, § Deviation Log, and the designated reference block.

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
| **R12** | **Three degradation postures could land in one check.** The three Check-22 cards each specify what happens when their block-start primitive is unavailable, and they did not originally agree. | MEDIUM | CHEAP | #4561, #3821, #3820 | Commit 1 lands the **single-finding, criterion-not-evaluated** posture and states it as a named convention in the block, so the two following editors bind to it rather than inventing a third. See the Deviation Log. **Closed at Commit 2:** #3821's own block-start resolve BINDS to that convention verbatim (one finding, `NOT-EVALUATED`, no per-issue fan-out) and its regression net asserts the posture directly — exactly one block-level finding, zero guessed per-issue verdicts, with a control proving F0/F1 cards are still evaluated in that state. The offered CD-2 shared helper was **declined**, deliberately and for the second time; rationale below. |

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
  >
  > **Re-verified under the corrected method at Engineering Commit 2 (#3821), and it holds.** Query-site clause: the block range `Check 22 … Check 23` holds **exactly 1** `gh issue list` invocation. Detector clause, run over the block's **non-comment** lines: **1** reference to the shared detector and **0** P-level grammar constructs. *Controls:* sensitivity — the literal `Check 22` returns 11 file-wide, and the same non-comment extractor finds the block's AC-pattern grammar (1 hit), so both extractors are live; specificity — `status: zzqqxx` returns 0, so a zero is reachable. **The field-section tests commit 2 adds are not a second primitive**: they match a `### Priority` / `### Severity` *heading* to decide whether the criterion applies, while the P-level itself is still resolved only through the shared detector's map. Applicability and detection are different questions, and CIAC-1 counts the second one. Commit 2 introduces a **second delegated primitive of a different kind** — the pack-union kind vocabulary — which CIAC-1 does not constrain and which is likewise resolved by delegation rather than re-implemented.
  >
  > **Re-verified at Engineering Commit 3 (#3820), and it holds — including through the query-scope change.** Query-site clause: the block range holds **exactly 1** `gh issue list` invocation; commit 3 appended a `--milestone` argument to that existing site rather than adding a second one, which is why the invariant survives a change to *what* the query asks. Detector clause, over the block's **non-comment** lines: **1** reference to the shared detector and **0** P-level grammar constructs. *Controls:* sensitivity — the literal `Check 22` returns 12 file-wide and the same non-comment extractor finds the block's AC-pattern grammar (2 hits), so both extractors are live; specificity — `status: zzqqxx` returns 0, so a zero is reachable. **Commit 3 adds a milestone-lookup call, and it is not a new form:** the repository now holds **3 call sites of ONE form** (`per_page=100` + `--paginate`), the two pre-existing ones in the membership tool and commit 3's, which copies them. A third *form* would have been the defect; a third *call site of the same form* is not.
- [ ] **CIAC-2 (#4561 × #3820 — the decomposed failure count):** the enforce-scope rationale cites a G1-06 failure count measured **after** the detector fix, at a pinned commit anchor, decomposed by cause.
  *Shared surface:* the rationale text in the schema's Gate-1 enforcement-layer split.
  *Method:* read the recorded rationale; assert it names per-cause counts (kind-form scope / detector carrier / genuinely-absent field) **plus** a commit anchor and read date, and that the anchor is at or after commit 1. **This is the release's reason for existing** — it is the cohesion constraint the keep-together decision was made to protect.
  > **Discharged at Engineering Commit 3.** The recorded rationale in the schema's Gate-1 enforcement-layer split carries a per-cause decomposition (population 256 · pre-filter 258 · post-class-filter 150 · demoted 108, split 90 sub-task-carrying / 18 kind-form-or-unresolved, and by criterion 94 / 7 / 7 · post-milestone-filter 1), a read date, and a branch anchor **at commit 2**, which is after commit 1. Every figure was measured by driving the **shipped** evaluation region over the live population rather than a replica, and the design-time figures were **not** carried forward — the population moved from 169 at design time to 256 at build time, so a carried number would have been wrong by half.
  > **One correction to how this criterion reads its own cause list.** The Stage-4 method names *detector carrier* and *genuinely-absent field* as causes, which were the right partition when the question was "why does the priority criterion fail". After commit 1 the detector-carrier cause is **gone by construction** — the check authors no carrier — so the live decomposition is over the *population* causes the scope decision actually turns on. The decomposition is present, per-cause, anchored and dated; the cause vocabulary is the post-commit-1 one, and that is stated rather than silently substituted.
- [ ] **CIAC-3 (#3821 × #3820 × #3826 — the schema's Gate-1 section):** all scope statements land and are mutually consistent — none overwrites another, and a kind-form card declared **exempt** is not counted inside the population another card's chosen scope enforces against.
  *Method:* read the section; assert every landed scope statement is present and that no card class is simultaneously exempt-by-one and enforced-by-another.
  > **Re-verified at Engineering Commit 3, on both halves of the grading method.** Commit 3's additions to the section are keyed by **form family** in the row-label column, never by criterion ID, so they add **zero** rows of the counted shape. Verified structurally rather than asserted: the row-shape projection over the criterion tables is **byte-identical before and after this commit** — 37 rows, and the `$2/$5/$6` field projection hashes identically — so neither the count nor the column positions moved. That second half matters because the grader emits a field tuple rather than a tally, and the enforcement-layer split could have been expressed as a table-header change that shifts every existing row's field boundaries; it was deliberately expressed in prose plus a separate family-keyed table instead, for exactly that reason. *Control:* the same projection against a nonexistent row prefix returns 0.
  > **Consistency clause holds across the three editors.** Commit 3 declares kind-form cards **outside the enforce population** and simultaneously **inside** detector-tier coverage — those are different authorities, not a contradiction, and the section states both. No card class is exempt-by-one-card and enforced-by-another: commit 2's kind-form applicability governs *which criteria read* an F2 card, commit 3's authority map governs *whether any of its findings can block*, and the map cites the applicability block rather than restating it.
  > **#3703's non-interference arm, discharged at Engineering Commit 7 — with the roster corrected and the arms attached.** The Stage-5 handoff proposed a `#3821 × #3820 × #4561` roster; that roster is **wrong on two of three members** and the hub's reconciliation (already recorded at Deviation Log **AI-007c**) is authoritative: **#3821, #3820 and #3826 EDIT**, **#4561 is verify-only** (its own Affected Files says `verify` and routes the detector fix to the deploy script), and **#3703 has exited the surface entirely**. The `3-way` count in the handoff was right only by coincidence. Adopted as stated here; **no sixth identifier is minted**.
  > *#3703 arm, measured at this build anchor:* `core/schemas/gate-criteria-spec.md` — **empty diffstat** across commit 7 (untouched) · `grep -c 'SA-G1'` → **0** with the same-path sensitivity arm `G1-09` → **38** and specificity `SA-G9` → **0** · range-anchored criteria rows `awk '/^\| ID \| Criterion \| Type \| Check/,/^\*\*Applies-to column triple/' … \| grep -c '^\| G1-'` → **10**, unchanged and invariant after this card (*sensitivity:* `^\| G2-` → 26; *specificity:* `^\| G9-` → 0; the superseded unanchored form returns **37**, which is why it is not the method). `core/deploy/deploy.sh` and `core/schemas/gate-evaluation-spec.md` likewise carry **empty diffstats**. The `all nine` claim at the §12 enforcement primitive is **asserted against #3820's record, not #3703's** — see the explicit non-edit proof at § Verification Plan (Engineering Commit 7).
  > **Widened at Commit 0.** Stage 4 authored this as a 2-way constraint. The wave-1 briefing widened it to grade N-way consistency as the section's editor set grew, and referred to the widened constraint as `CIAC-6`. The Stage-4 plan authored only CIAC-1..5 and the Gate-1 consistency constraint is **CIAC-3**; this plan therefore widens CIAC-3 rather than minting a sixth identifier, and records the naming delta so Stage 9 grades the constraint **once**, across all three editors plus the verify-only touch, under whichever label it reads. **Routed to the hub for confirmation** — it is a labelling reconciliation, not a new criterion.
- [ ] **CIAC-4 (#3711 × #3709 — the sibling check's M2 leg):** after both land, one run of the membership tool emits sub-class-distinguished rows **and** carries zero findings traceable to a missing sub-task label.
  *Method:* run the tool against the repository; assert every emitted `named-not-member` row carries a sub-class token, and assert no emitted row references a stage-shaped title lacking the sub-task label.
  > **Limb 1 is discharged at Engineering Commit 4, executably.** Every `#N` in an emitted `named-not-member:` list is immediately followed by exactly one token from the closed four-value enum. Runnable form — **zero output is PASS**, any printed line is a ref missing its token:
  > ```
  > python3 core/deploy/tools/check-milestone-epic-membership.py --repo <owner>/<repo> --leg M2 \
  >   | awk -F'\t' '$1=="M2"{print $5}' \
  >   | grep -oE 'named-not-member: [^;]*' \
  >   | grep -oE '#[0-9]+(\[[a-z-]+(:[a-z-]*#?[0-9]*)?\])?' \
  >   | grep -vE '\[(elsewhere:ms#[0-9]+|no-milestone|member-excluded(:sub-task)?|unresolved)\]$'
  > ```
  > Measured at commit 4: **14 named-not-member refs across 7 rows, 14 carrying a conforming token, 0 output → PASS.** *Control:* the same pipeline with the enum's `no-milestone` alternative deleted prints **11** lines, so the filter can go red on the defect it names.
  > **The `named-not-member: [^;]*` segment scope is load-bearing, and it was found by running the grader rather than by writing it.** Without it the pipeline reads the whole detail field, picks up the **unannotated `member-not-named:` refs** — deliberately unannotated, since that leg is byte-identical by requirement — and reports **1** false finding out of **15** extracted refs. A grader that fails on a ref the design requires to carry no token is measuring the wrong property. Stage 9 must use the segment-scoped form above.
  > **Limb 2 — the "structurally vacuous" framing does NOT reproduce at this anchor, and the correction is recorded rather than inherited.** The Phase-A6.5 review classed limb 2 as structurally, not transiently, vacuous: M2's membership basis is open-milestone-scoped, so a cohort that is entirely closed-and-unmilestoned can never reach a row, and a re-measurement cannot cure that. **Re-measured directly at commit 4, and the criterion's own live population is not empty.** Over the stage-titled population: **33** issues lack the `sub-task` label, of which **16** sit in an OPEN milestone (reachable through M2's member side) and **12** are named in an open milestone's `### Scope` (reachable through M2's named side). Limb 2 therefore has a real, observable population and its zero is a **discriminating** zero, not a vacuous one. *Arms:* sensitivity — the same predicate over the stage-titled population returns **1** genuine hit, so the extractor and the title test are live; specificity — a ghost issue number and a fabricated label both return **0**. Direct limb-2 run over all **15** refs in all emitted rows: **0** hits, 15/15 read.
  > **What survives of the review's finding, and it is the part that matters.** Limb 2's ability to go red *from the sibling label-backfill card specifically* still depends on that card's own frozen target set, which the review measured as entirely closed with none in an open milestone. Those two facts are compatible: the criterion is evaluable in general and blind to that particular cohort. **Grade limb 2 on its own population with the arms above — do not grade it as evidence that the backfill worked**, and do not treat a re-measurement as the remedy for the cohort-specific blindness, because the only change that would lift it (widening the membership fetch to all milestone states) is settled as **rejected** by both sibling designs on identical grounds.
  > **Truncation caveat, load-bearing on the figures above.** The 33/16/12 are computed over the primitive's own stage-title fetch, which is capped at 1,000 rows while the live population is **3,166** issues *(independent count via the search API; specificity arm on a fabricated title token → 0)*. The three figures are therefore **lower bounds**, and the cap is a pre-existing fail-open on the M3 leg's input, surfaced and routed rather than fixed here — see the Deviation Log.
- [ ] **CIAC-5 (#3826 × #3703 — advisory posture):** both cards add a **non-blocking** signal; neither introduces a hard-fail path, so the release adds review coverage without adding an enforcement layer.
  *Method:* locate each added check in its stage file; assert each is stated as advisory with its authoritative gate named.
  > **Discharged for the #3703 half at Engineering Commit 7, and every zero carries a control arm.** The Stage-5 handoff specified the non-membership assertion as a bare `grep -c … → 0`, which the adversarial review correctly named as the release's own fail-open shape sitting inside the design that discharges it: a moved path, a renamed token, or a typo returns the same zero and the check reports clean. **The method below is the corrected form and is what Stage 9 runs** — each zero is paired with a positive arm at the *same path*, and **a run where the control arm also returns 0 is a BROKEN PROBE, not a pass.**
  >
  > | Path | subject `SA-G1` | sensitivity (same path) | specificity (same path) | lines |
  > |---|---|---|---|---|
  > | `core/schemas/gate-criteria-spec.md` | **0** | `G1-09` → **38** | `SA-G9` → 0 | 1,104 |
  > | `core/deploy/deploy.sh` | **0** | `recommend_g1_enforcement` → **12** | `SA-G9` → 0 | 12,449 |
  > | `core/schemas/gate-evaluation-spec.md` | **0** | `Check=judgment` → **6** | `SA-G9` → 0 | 355 |
  >
  > **Probe valid.** Every file is readable and non-empty, every sensitivity arm is non-zero, every specificity arm is zero. The structural claim these zeros support: `SA-G1` is not a registry criterion, so the Layer-2 judgment aggregate never sees it, the Gate-1 judgment denominator stays at **4**, and no new HOLD path is reachable.
  >
  > **The advisory posture is also true on the merits, not only by non-membership.** Re-derived at this build anchor: **no machine consumer of the A4 `feasibility` emit exists** anywhere under `core/deploy/deploy.sh`, `core/deploy/tools/`, or `release/tools/` — 125 files searched, the single `feasibility` hit is a **test-fixture issue body**, which is data, not a consumer. *Sensitivity:* `status: bundled`, a genuinely machine-consumed token in the same trees, returns **4** files. *Specificity:* `ZZZ_NOT_A_REAL_FIELD` → **0**. So the emit reaches the operator through the A6 summary and reaches no gate.
  >
  > **In-file assertion (the "stated as advisory with its authoritative gate named" half).** `stage-02-triage.md` § Scope-Altitude Determination (A4.7) states the Authority verbatim — *stage-local, Advisory, non-gate-blocking* — names the three aggregation surfaces it is outside, and states that no failure path blocks triage intake; §7 repeats the posture at the Stage-Transition Gate so the criterion's absence from the Workflow-Readiness pass set reads as designed rather than as an omission.

---

## File Change Matrix

Machine-readable path list — **one path per line, no decoration** — for deterministic extraction by downstream Stage 7 / 8 / 9 chips. This is the union known at Engineering Commit 0: the Stage-4 matrix reconciled forward through the Solutioning designs the hub has consolidated. Later Engineering slices that expand it record the delta in the Deviation Log and extend this block in the same commit.

```
core/deploy/deploy.sh
core/deploy/tests/test_g1_06_priority_carrier.sh
core/deploy/tests/test_g1_form_family.sh
core/deploy/tests/test_g1_release_resolver.sh
core/deploy/tools/check-work-hierarchy.py
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
release/skills/pipeline-triage/SKILL.md
release/skills/pipeline-triage/references/triage-execution.md
packages/pipeline-triage.skill
packages/pipeline-triage.skill.sha256
core/ADRs/ADR-120-g1-enforcement-authority-is-class-scoped-and-release-scoped.md
core/schemas/stage-io-contracts.md
core/specs/engagement-charter.md
release/governance/release-process.md
release/references/pipeline/stage-09-plan-review.md
release/references/specs/release-class-taxonomy.md
release/references/specs/release-outcome-statement-template.md
release/references/standards/bundle-composition-doctrine.md
release/skills/release-hub/references/orchestration-playbook.md
packages/release-hub.skill
packages/release-hub.skill.sha256
release/releases/plans/release-check-enforcement-gates_RELEASE_PLAN.md
```

Per-path intent:

| Path | Card(s) | Intent | Note |
|---|---|---|---|
| `core/deploy/deploy.sh` | #4561, #3821, #3820, #3711 | **edit** ×4 | Priority-carrier detection · title-floor kind resolution · Check-22 query scope + the enforcement emitter · the sibling check's M2 warn line |
| `core/deploy/tests/test_g1_06_priority_carrier.sh` | #4561 | **add** | Hermetic fixture table + executable-glue arm + drift guard |
| `core/deploy/tests/test_g1_form_family.sh` | #3821 | **add** | Hermetic form-family net: one fixture per **pack-resolved** kind (vocabulary read from the SSOT, so no kind is named in the test either) + F0/F1/F3 fixtures + a degraded-vocabulary arm + the anti-drift guard. Extracts and executes the shipped evaluation region between the `C22-EVAL` sentinels |
| `core/deploy/tools/check-work-hierarchy.py` | #3821 | **edit (additive)** | `--emit-kinds` vocabulary mode + a **partial-parse** control on the SSOT reader: the matched `kind_id` count is cross-checked against the `[[kinds]]` table count, and an unreadable pack is recorded rather than swallowed, so a degraded read exits 3 instead of returning a plausible short vocabulary. `load_licensed_kinds`'s signature and return value are unchanged |
| `core/deploy/tests/test_g1_release_resolver.sh` | #3820 | **add** | Hermetic net for the release-identity resolver: extracts and executes the shipped resolver between the `C22-RESOLVER` sentinels against a `gh` stub that honours the real API's pagination semantics over a 201-row fixture, and grades the pagination arms against a deliberately **regressed** copy that must go red. Also holds the asserted-vs-detected provenance split and the three verdicts that must never be rendered as a missing milestone |
| `core/config/allowlists/script-execution-allowlist.txt` | #4561, #3821, #3820 | **edit** ×3 | Companion allowlist rows for each added executable, in all four resolved invocation forms, so the test is runnable agent-side on arrival |
| `.github/workflows/install-tests.yml` | #4561, #3821, #3820 | **edit** ×3 | Wire each new regression test **and** the pre-existing title-floor test, which had never been CI-wired |
| `core/schemas/gate-criteria-spec.md` | #3821, #3820, #3826 · **#4561** | **edit** ×3, **verify** ×1 | Gate-1 kind-form applicability · Gate-1 enforcement-layer split · required-CI-check coverage · **#4561: carrier-set agreement only, no edit** |
| `core/deploy/tools/check-milestone-epic-membership.py` | #3711 · #3709 | **edit** · **verify-no-change** | M2 sub-class emit + self-test mutation-kill cases · the exemption predicate is correct, the input data is wrong |
| `core/deploy/tools/README.md` | #3711 · #3820 | **edit** · **edit (conditional)** | The sibling check's M2 output shape · the Check-22 evaluated population, only if that row describes it |
| `core/specs/label-taxonomy.md` | #3709 | **edit** | Its rule and the bridge procedure name different application points for the same label — reconcile to one authority |
| `release/references/specs/release-readiness-scan-spec.md` | #3826 | **edit** | Add the required-CI-checks dimension; split mergeability into draft-blocked vs. checks-failing |
| `release/references/pipeline/stage-07-dev-testing.md` | #3826 | **edit** | Issue-reference-validity spot-check (advisory) |
| `release/references/pipeline/stage-08-qa-testing.md` | #3826 | **edit** | Same spot-check |
| `release/references/pipeline/stage-02-triage.md` | #3820 · #3703 | **edit** ×2 | #3820: the enforcement-primitive line's restated population becomes a pointer to the governed record — **line 295 only**, one line changed · #3703: scope-altitude consistency check + a conforming gate ID |
| `release/references/how-to/hub-spoke-bridge.md` | #3826 · #3709 | **edit** · **verify-no-change** | Required-check read as a numbered step · **must-NOT-change:** the creation-time sub-task-label mandate, its template row, and the blocking unlabelled class must all survive |
| `release/references/how-to/intake-style-guide.md` | #3703 | **edit** | Scope-altitude guidance + two worked examples |
| `.github/ISSUE_TEMPLATE/bug.yml` | #3703 | **edit** | Expected-behaviour ↔ affected-files relationship |
| `.github/ISSUE_TEMPLATE/improvement.yml` | #3703 | **edit** | Description / proposed-change ↔ affected-files relationship |
| `release/skills/pipeline-triage/SKILL.md` | #3703 | **edit** | **The executor.** A4 row names the A4.7 sub-check and its emit enum. Without it the criterion ships **dormant** — defined in the stage shard, never run by the skill that runs Stage 2, which is the measured `G2-13`/`A4.6` failure reproduced deliberately |
| `release/skills/pipeline-triage/references/triage-execution.md` | #3703 | **edit** | Same executor, per-phase detail: the A4 block's Definition / Run / Emit gain the A4.7 determination and the five-value enum, citing the stage shard for the predicate rather than restating it |
| `packages/pipeline-triage.skill` + `.sha256` | #3703 | **rebuild** | Content-baseline sidecar for the two skill-file edits above, per the Stage-6 C4 package-rebuild beat |
| `.github/ISSUE_TEMPLATE/epic.yml`, `story.yml` | #3821 | **reference only — no change** | Field-set and title-convention inputs to the mapping |
| `core/ADRs/ADR-120-g1-enforcement-authority-is-class-scoped-and-release-scoped.md` | #3820 | **add** | Threshold met; authored at Engineering Commit 3. **120 is next-free on the mainline** (contiguous 001..119), and the number is held branch-local per the allocate-at-authorship / bind-at-merge rule. Two live sibling branches also hold a 120; stepping past them to 121 was tried and **rejected by the numbering gate as a GAP**, because the gate enforces a gap-free global sequence — first-to-merge takes the number and the others renumber |
| `core/schemas/stage-io-contracts.md`, `core/specs/engagement-charter.md`, `release/references/pipeline/stage-09-plan-review.md`, `release/references/specs/release-outcome-statement-template.md`, `release/references/standards/bundle-composition-doctrine.md` | #3826 | **edit** ×5 | Readiness-scan **cascade consumers**. Each restated the scan's dimension cardinality inline; each is now count-free and cites the spec that owns the set. One line each except stage-09, which carries two |
| `release/references/specs/release-class-taxonomy.md` | #3826 | **edit** | Cascade consumer **plus** the second `allow-link` marker. The file's own markdown link is pre-existing and untouched; editing the count-bearing line is what exposes it to the required durability gate's added-line scan, so the per-file marker records the file's existing retained posture |
| `release/governance/release-process.md` | #3826 | **edit** | Two changes, one commit. (a) Cascade consumer — the readiness-scan restatement is de-numerated. (b) **The assigned doc-impact residual** — the file's three `Documentation Impact` scope restatements collapse to pointers at the schema row that already declares itself their authority |
| `release/skills/release-hub/references/orchestration-playbook.md` | #3826 | **edit** | Cascade consumer. **Skill reference file** → package rebuild in the same commit |
| `packages/release-hub.skill` + `.sha256` | #3826 | **rebuild** | Content-baseline sidecar for the reference-file edit above, per the Stage-6 C4 package-rebuild beat |
| `release/releases/plans/…_RELEASE_PLAN.md` | — | **add** | This file. Engineering Commit 0; flat slug-primary path |

**Non-file state mutation — not representable above, and not `git revert`-ible.** Card 5 applies a label to **74** GitHub issues. See § Rollback.

### Tier-A activated design artifacts

Declared for the Stage-13 **G-CL6** design-artifact refresh gate (Phase A5), which verifies each artifact's last commit SHA sits inside this release's branch range and its diff is non-trivial. **One** Tier-A activation fired in this release.

| Artifact | Class | Where it lives | Activating card |
|---|---|---|---|
| `SA-G1` fire / non-fire logic — Limb A ∨ (SA1 ∧ SA2 ∧ SA3), guarded by N1–N7 | **decision-tree** (≥1 gate, per `design-artifact-standard.md` § 7 Tier-A) | ASCII flow-block embedded in the **Scope-Altitude Determination (A4.7)** sub-block of `release/references/pipeline/stage-02-triage.md` | #3703 (Engineering Commit 7) |

No other card activated a Tier-A artifact; the omission is the correct non-ceremony signal, not a gap.

**Path count:** 35 machine-readable rows (34 repo paths + this plan). Four are new files; the conditional ADR add is now unconditional — the threshold is met and the record is authored. *(Extended at Engineering Commit 2 — #3821 added `core/deploy/tests/test_g1_form_family.sh` and `core/deploy/tools/check-work-hierarchy.py`. Extended again at Engineering Commit 3 — #3820 added `core/deploy/tests/test_g1_release_resolver.sh` and took `release/references/pipeline/stage-02-triage.md` as a second editor. Extended again at Engineering Commit 6 — #3826 added ten paths: eight cascade consumers outside its declared four-file matrix, plus the rebuilt skill package and its sidecar. The cascade was known and approved at the wave-2 briefing; the paths were not in this block. Extended a final time at Engineering Commit 7 — #3703 added the two `pipeline-triage` executor files plus its rebuilt package and sidecar, and **returned three contended surfaces** (`core/schemas/gate-criteria-spec.md`, `core/deploy/deploy.sh`, and the §12 enforcement-primitive region of `stage-02-triage.md`) that its superseded design would have taken. See the Deviation Log.)*

---

## Verification Plan

### Enforce-scope re-pin — #3820, recorded with its anchor (Engineering Commit 3)

Every figure below is measured by driving the **shipped** Check-22 evaluation region — extracted verbatim between its own sentinels — over the live population, so what is reported is what the check does rather than a replica of it. Read `2026-08-06 (Thursday)`; branch anchor at commit 2, which is at or after commit 1 as the decomposition criterion requires.

| Quantity | Value |
|---|---|
| Open `status: bundled` population | **256** *(truncation-guarded: 256 ≠ `--limit` 5000; extraction non-empty at 1,149,485 body chars)* |
| Structural findings **before** the class filter, backlog-wide | **258** |
| Structural findings **after** the class filter, backlog-wide | **150** |
| Structural findings demoted to detector-tier | **108** across 108 cards — G1-09 94 · G1-05a 7 · G1-01 7 |
| — cards demoted whose sole cause is the sub-task conjunct | **0** — `F1 ∩ sub-task = 0`, so the conjunct is a **guard**, not a change |
| — cards demoted by the family conjunct | **108** (90 also carry `sub-task`; 18 are kind-form / unresolved-form) |
| Structural findings **after** the milestone filter — this release | **1** — the `[Bug]:` title prefix on card 1's own issue |
| Multi-tier cards in the population | **0** — the cell is empty and is held by fixture |
| Enforce population, this milestone | **7** — the same seven parent issues, reproducing the design exactly |

*Controls.* Sensitivity: the same query against this milestone returns **31** rows and the evaluation emits 25 detector-tier rows, so neither the query nor the evaluator is a constant. Specificity: the identical query against a nonexistent milestone returns **0**, and a nonexistent label returns **0** — so a zero is reachable and the non-zero results above are discriminating.

**The pagination defect is worse at build time than the pinned finding stated.** Measured live: `state=open` default → **30**, `per_page=100` → **45**, paginated → **45**. The open-milestone set is now **45**, so the superseded un-paginated form was **already truncating** — silently dropping 15 of 45 (33%) — rather than sitting one milestone from the boundary. On `state=all`: default **30**, `per_page=100` **100**, paginated **217**.

**Plan-carrier figure re-derived on the full universe.** Release-plan basenames matching a milestone title: **28 of 154 (18.2%)** against the fully-paginated 217-title universe. *Control:* the same measurement against a truncated 100-title universe returns **18 of 154 (11.7%)** — which reproduces the superseded figure exactly and is itself a direct demonstration of the truncation mechanism. *Specificity:* a synthetic stem is absent from the title set. The conclusion is unchanged — the plan path is a poor release-identity carrier — but the number that supported it was measured through the defect it was describing.

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
| **#3709** | Identifier list recorded **before** the first edit; per-issue pre-state re-read at mutation time and label read after; full-population sweep with the truncation guard and all four probe arms; two-tier classification with the residual read individually; **before/after** on the evidence-preservation denominator and on the scaffold-completeness findings; **must-NOT-change** search of the bridge template and the blocking unlabelled class | List recorded and non-empty with length equal to the mutated count; every backfilled issue carries the label and the legacy alias is preserved; zero genuine stage sub-tasks left unlabelled; **the denominator rises and the false "not scaffolded" milestones clear** — the criteria that can fail; the scaffold-completeness findings clear on every reachable row; the two originally-named gates show **no new finding** (a no-harm result, explicitly not a remediation claim); the creation-time mandate still present in the template and the unlabelled class still blocking; every count recorded with its baseline date |
| **#3826** | Read the readiness-spec dimension list and the mergeability dimension; read both stage files for a spot-check naming **both** enforced classes; read the bridge procedure for a **numbered** step; fixture pull request with one failing required check plus an all-passing control | Dimension present and states that any failing required check is a NO-GO input; draft-blocked and checks-failing are distinct named states; the read is a numbered step, not prose; the fixture reports NOT-READY naming the check and the control reports READY; the spot-check is stated advisory with branch protection named authoritative |
| **#3703** | Read the triage stage file for the check and a conforming gate ID; **declared method** — run the judgment-assisted check against two named fixture bodies, each with a contained-scope control; read the check definition for annotation-not-block; sample run for false-positive rate at a pinned anchor | Check and conforming gate ID present; both fixture shapes flagged and both controls **not** flagged; the output is an annotation with no blocking path; both worked examples present; false-positive rate recorded with commit anchor and read date. **The executor is a reasoning agent, not a script — a legitimate declared, verification-deferred case; the method is recorded, not lossily rewritten** |

**Non-vacuity is a hard requirement, not a nicety.** Every card's criteria already carry an explicit control arm — a no-priority body, a governance-intake control, an in-release failure, a contained-scope issue, an all-passing pull request. **A control that cannot fail is a broken probe, and a zero whose control also returned zero is reported as unusable, never as clean.** Do not let a later slice silently drop one.

**Cross-issue:** CIAC-1..5 above, graded at Stage 9 on the merged pull request. Per single-runner discipline, Stage 9 reads verdicts emitted at Stage 6/7 rather than re-running the methods.

### Form-family baseline — #3821, recorded with its anchor (Engineering Commit 2)

The population moves, so the number is meaningless without the anchor and the definition. Both are stated; Stage 9 **re-reads** rather than trusting this row.

| Field | Value |
|---|---|
| **Population** | open, `status: bundled`, `--limit 5000`, truncation-guarded (returned count matched an independent count; 224 ≠ the limit) |
| **Denominator** | **224** issues · **224/224** bodies non-empty · 1,049,309 body characters |
| **Anchor / read** | mainline `f157a811`, branch tip `5effaf72` · read `2026-08-07T02:20Z` (**2026-08-06 Thursday** local — day-of-week validated) |
| **Partition** | **F0 0 · F1 123 · F2 39 · F3 62 = 224.** Cards in more than one family: **0**. Cards in no family: **0**. |
| **F2 composition** | 17 story-typed · 22 task-typed. The epic and card kinds are **licensed but carry zero live members** — the vocabulary is resolved from the packs, not from the population, so an empty kind is covered by the rule and is not evidence against it. |
| **F3 composition** | 4 carry a `type:` label the packs do **not** declare (correctly F3, not F2); the remainder carry no kind label at all. |
| **Verdict movement** | F1 **192 → 192 findings, byte-identical**. F2 **39 → 14**: every one of the 39 previously terminated at the label-count branch with a single mis-worded G1-09; post-change 14 cards carry a real criterion finding (7 title-floor, 7 AC-structural) and **25 are clean and determinate**. F3 **62 → 62**, same count, correct wording. Whole-population gating findings **251 → 226**. |
| **Cohort-definition note** | Two definitions of "kind-form cohort" differ and must not be conflated: *any* `type:*` label vs. a **pack-declared** kind label. This release's rule acts on the second. Non-sub-task at this anchor: 166 total, **106** carrying any `type:*`, **74** carrying a pack-declared kind. The figure that governs the F2 rule is the pack-resolved one. |

**Probe validity.** Sensitivity: `### Proposed Change` present in 8 of the 39 F2 bodies; cards with ≥1 intake-tier label = 123. Specificity: `### Zzzsentinel` → 0; a bogus label → 0; the bundled query with a non-existent status label → 0. Extraction non-empty: 224/224 bodies, 39/39 F2 bodies. **No zero above rests on a probe whose control also returned zero.**

### M2 sub-class baseline — #3711, recorded with its anchor (Engineering Commit 4)

The population moves, so the number is meaningless without the anchor. The Solutioning design measured this leg at a **31**-milestone / **4**-row / **6**-ref state; it is no longer that state, which is why the design's expected-emit block was an anchor and never a shipped expectation. Stage 9 **re-reads** rather than trusting this row.

| Field | Value |
|---|---|
| **Anchor / read** | branch tip `0dd00ac7` · read **2026-08-06 (Thursday)** — day-of-week validated |
| **Population** | `MILESTONES 45 · DECLARED 0 · COUNT_M1 0 · COUNT_M2 7` |
| **Sub-class decomposition** | `COUNT_M2_NNM 14` = **ELSEWHERE 3 · NO_MILESTONE 11 · MEMBER_EXCLUDED 0 · UNRESOLVED 0`.** Sum invariant holds: 3 + 11 + 0 + 0 = 14 |
| **Resolver state** | `M2_REF_RESOLUTION fetched 14 14` — one batched call, every candidate resolved, **zero calls on a clean leg** by construction (the fetch is gated on a non-empty candidate set built from the same set-difference the join consumes) |
| **Opposite leg** | `member-not-named` is **1** row (ms#289 → `#231`) — non-zero at this anchor, where the design measured 0. Its ref carries **no token**, by requirement |
| **Movement vs. the design anchor** | milestones 31 → 45 · M2 rows 4 → 7 · NNM refs 6 → 14. Every figure moved; none was carried forward |
| **What the free indices alone would have produced** | **11 of the 14** refs are closed and milestone-less, invisible to both free indices. Without the deferred overlay they read `unresolved`; with it they read `no-milestone`. That 11/14 is the measured value of the fetch the design added after falsifying the zero-fetch premise |

**Probe validity.** Sensitivity: the sub-class filter's control arm (one enum alternative deleted) prints **11** lines, so it can go red; the stage-title predicate returns **1** genuine hit over the stage-titled population. Specificity: a fabricated tool name in the tool README → **0**; a ghost issue number → **0**; a fabricated label → **0**. Extraction non-empty: 15/15 refs read, 14 in limb 1's scope. **No zero above rests on a probe whose control also returned zero**, and the one probe that returned a wrong answer — limb 1 unscoped, reporting 1 false finding — is recorded at the criterion rather than quietly corrected.

### Sub-task label backfill — mutation ledger, recorded pre-execution (Engineering Commit 5)

**This block is the release's rollback key, committed to git.** The backfill applied the `sub-task` label to 74 tracker issues — state outside this repository that `git revert` cannot undo. The identifier list below was recorded on the Engineering sub-task thread **before the first label edit**, and is duplicated here because a recovery key must be strictly more durable than the state it recovers: a tracker comment lives on the same mutable surface being mutated, a committed plan does not.

| Field | Value |
|---|---|
| **Anchor / read** | branch tip `2b64775c` · population read **2026-08-06 (Thursday)** local, `04:41Z–04:44Z` UTC — day-of-week validated; UTC had rolled to the 7th at execution time, recorded rather than smoothed |
| **Denominator** | 392 open + 4,001 closed = **4,393** issues. Truncation guard **PASS** — 392 ≠ 5,000 and 4,001 ≠ 8,000; neither arm returned a row count equal to its limit |
| **Classification** | `^Stage [0-9]` → **3,028** hits; **2,949** already carried the label; **79** did not. Two-tier: Tier-1 head-vocabulary screen auto-admitted **74**, Tier-2 residual **5** read individually and all five classified **prose**, not sub-tasks |
| **Prose exclusions** | five defect cards whose titles merely begin "Stage N" — each read in full and each carrying an intake-template body (`### Severity` / `### Priority` / `## Problem`) and a lifecycle category label |
| **Reconciliation** | **IDENTICAL to the Solutioning baseline, issue for issue — zero delta.** Fourth independent measurement of this cohort across four anchors and a population that moved 4,199 → 4,317 → 4,327 → 4,393. The defect class gained and lost nothing |
| **Cohort** | 74/74 CLOSED · **0** in an open milestone (60 across 24 closed milestones, 14 with no milestone) · created 2026-06-14 → 2026-07-26 · post-mandate leaks **0** · 43 carry the legacy alias |
| **Execution** | **MUTATED 74 · SKIPPED-PRE-EXISTING 0**. Two frames exist and only one of them is the rollback key: the **client-invocation** window ran `04:50:11Z → 04:52:30Z`, while the tracker's own `created_at` events run `04:50:12Z → 04:52:31Z` — each server event lands about a second after the invocation that caused it. **The selector is the tracker frame, and its bound is `04:50:11Z` through `04:52:31Z` inclusive**, replayed against the live timeline at Stage 9: selects exactly **74 of 74**. Additive only; legacy alias preserved on all 43; **zero** labels removed on any issue; zero aborts |

**Mutated identifiers — the reverse sweep's scope bound. Nothing outside this list may be stripped.**

```
1044 1045 1046 1047 1048 1049 1050 1052 1053 1054 1055 1056
1560 1802 1901 2051 2387 2446 2496 2547 2587 2655 2705 2706
2707 2708 2709 2710 2711 2720 2721 2722 2759 2760 2761 2762
2763 2764 2765 2766 2767 2768 2770 2771 2773 2774 2775 2776
2777 2778 2779 2780 2781 2782 2783 2784 2785 2786 2787 2791
2792 2793 2930 3129 3131 3330 3443 3444 3446 3580 3845 3848
3952 4047
```

**The selector is the tracker's own label-application event, not this text.** A reverse sweep strips only where a `sub-task` label-application event exists inside the recorded execution window — a record the tracker writes and no editor can forge, reconstructible at any future date. Validated with three arms before being relied on: **sensitivity** — backfilled issues carry an event inside the window; **specificity** — a prose false-positive the release deliberately did not touch carries none; **discrimination** — a correctly-labelled sub-task created before this release carries its event *outside* the window and therefore cannot be stripped. That third arm is the one the pre-condition existed for, and it is demonstrated rather than asserted.

**The selector, stated once, in the frame it is evaluated in.**

```bash
gh api "repos/<owner>/<repo>/issues/<n>/timeline?per_page=100" --paginate \
  --jq '[.[]|select(.event=="labeled" and .label.name=="sub-task")|.created_at]'
# strip ONLY where an event exists with
#   2026-08-07T04:50:11Z <= created_at <= 2026-08-07T04:52:31Z
gh issue edit <n> --remove-label sub-task
```

**Read the bound in the tracker's frame, never the client's.** The window above is `created_at` on the **server-recorded** event. The client-invocation window is one second shorter at its upper edge (`…04:52:30Z`), and a selector written in that frame drops **#4047**, whose event is stamped `04:52:31Z` — 73 of 74, with the miss silent. This is the defect class the release exists to eliminate arriving in the rollback key itself: two timestamps that look interchangeable, one of which is a valid selector and one of which is not.

**Replayed at Stage 9 against GitHub's own timeline, all four candidate bounds against one captured event set** — 74 cohort issues, exactly one `labeled: sub-task` event each, zero read failures, max 59 timeline rows on any issue (`< 100`, so no pagination loss):

| Bound | Frame | Selects |
|---|---|---|
| `>= 04:55:00Z` — the pre-execution forward estimate | neither (estimate) | **0 of 74** |
| `04:50:11Z – 04:52:30Z` | client invocation | **73 of 74** — misses #4047 |
| `04:50:00Z – 04:53:00Z` | rounded, both-sided | 74 of 74 |
| **`04:50:11Z – 04:52:31Z`** | **tracker `created_at`** | **74 of 74** ← recorded bound |

Specificity holds at the recorded bound: #4840 (correctly-labelled sub-task predating this release) is stamped `2026-08-05T23:50:45Z` and falls outside; #3826 (prose false-positive) carries no event at all. **Controls selected: 0.**

**Pre-state was verified at mutation time, not once in prose.** Each issue's live label set was re-read immediately before its own edit; a pre-existing label would have been recorded as an explicit skip rather than counted as a mutation. Zero skips occurred, which closes the window between recording and mutating.

**Pre-mutation metric baselines, captured because the mutation destroys them — and their post-states.**

| Measurement | Before | After | Discriminating? |
|---|---|---|---|
| Evidence-preservation denominator, 24 affected milestones | **S = 308** | **S = 366** (+58) | **Yes** — moves only if the work happened |
| Milestones falsely reporting "no stage sub-tasks scaffolded" | **4** (holding 31 / 7 / 1 / 1) | **0** | **Yes** |
| Scaffold-completeness `UNLABELLED` findings, reachable set | **6** rows | **0** rows | **Yes** |
| Genuine stage sub-tasks missing the label, whole population | **74** of 79 label-missing | **0** of 5 label-missing | **Yes** |

Predicted before execution and matched exactly: 2 of the 60 milestoned issues are terminal-stage and correctly drop out of the denominator, giving +58 rather than +60. Understatement was **58/366 = 15.8 %**. Truncation guard on every arm: max rows in any milestone **31 < 500**; population arms 392 ≠ 5,000 and 4,001 ≠ 8,000. Sensitivity after: **24 of 24** milestones return a non-zero denominator, where 20 did before.

**These four are the criteria that can fail if the work is not done.** The two gates the card originally named cannot — they are structurally blind to a cohort that is entirely closed with none in an open milestone — and that no-harm result is reported as no-harm, not as remediation.

### Required-gate coverage — #3826, executed against the real branch head (Engineering Commit 6)

The design's own constraint was that the change must not turn the required durability gate red. That was verified twice at design time in a reconstructed sandbox. **At build time it is verified against the actual thing**: the workflow's scan step, extracted verbatim (11,864 bytes) and run over the real `origin/main`-to-branch-head diff, with the detector's own checked-in fixture self-test run first as the harness-validity control.

| Arm | What it runs | Result |
|---|---|---|
| **Harness control** | the detector's committed fixture self-test | **27 FLAG / 24 CLEAN, 51 passed, 0 failed**, exit 0 — reproduces the design and review figures exactly |
| **LIVE** | the extracted scan step over the real 6-commit diff | **exit 0** — no net-new fragile reference |
| **Non-vacuity control** | LIVE plus one bare issue reference in body prose | **exit 1**, `issue-reference placement · OUTSIDE-BLOCK`, line named |
| **Marker control** | LIVE minus **both** `allow-link` markers | **exit 1**, Class L on **both** exposed files, every offending line named |

The non-vacuity arm is what makes the LIVE pass mean something, and it independently proves the marker is Class-L-scoped: the positional issue-reference detector still fires with the marker present. The marker arm proves both markers are load-bearing on the declared surface, not decoration. Both control commits were throwaway and the tree was hard-reset to the real head after each; the head SHA is unchanged across the sequence.

**Doc-link integrity:** Check 14 over the governance + skill scope — **no broken cross-refs in scope**.

**Cascade re-pin at build time (the figure did not move a fifth time, but its disposition did).**

| Arm | Design figure | **Build-time** |
|---|---|---|
| Out-of-matrix | 13 substitutions / 11 lines / 9 files | **13 / 11 / 9 — reproduces exactly** |
| Whole change | 32 / 27 / 11 | **28 / 25 / 11** |

The whole-change figure fell by four, and **not** because a measurement changed. Adversarial review found that four of the declared tokens — the spec's two `operator-enumerated` phrases and its `CONFIRM-13` decision name — must be **preserved**, because the same commit adds a note affirming the operator enumeration is still 13. Substituting them would have made the file contradict itself inside one commit. They are now PRESERVE, so 32 − 4 = 28 and two lines drop out of the substitution set. *Controls:* sensitivity — the post-edit 14-form count in the spec returns **11**; specificity — a fabricated 97-form returns **0** repo-wide; truncation guard — the same invocation walks **1,087** markdown files, and every non-substituted hit was read individually and is a different 13 (pipeline-stage, gate, row identifier, fitness-rubric) or a correct historical PRESERVE.

**Added-line hygiene on the shipped diff:** `#N`-form issue references **0** (sensitivity control on an injected reference → 1); raw ledger URLs **0**; version tokens **1**, the schema version in the gate-criteria file, which carries `allow-version-ref`.

**Runtime suite:** the change matches the selection map's **no-match row** — thirteen markdown files plus a rebuilt skill archive, touching none of the compose, deploy, hook, tool-self-test or install paths. `test-run/suite-skip` is the honest verdict. The event log itself is an operator-instance surface not present in this worktree, so the determination is recorded here rather than appended there.

---

### Scope-altitude operand determinacy — #3703, the gating AC discharged executably (Engineering Commit 7)

Collective Review pinned one Blocker into Engineering as a gating acceptance criterion: operand determinacy was fixed for **S** and left field-keyed on `###` headings for **A**, so on one motivating fixture `A = ∅` and the second conjunct of Limb A was unevaluable. **It is graded on evidence, never on a "fixed it" statement** — the measurement is below.

**The heading census, re-derived rather than inherited.** The handoff carried a false figure (*"the fixture carries zero `###` headings of any kind"*) produced by a regex whose `^` anchored to the start of the *string* rather than each line. Re-measured here line-anchored, over the four motivating fixtures plus two controls, at branch tip `05c965a3` / read **2026-08-07 (Friday)** — day-of-week validated:

| Body | len (chars) | `^### ` | `^## ` | `### Affected Files` | `### Acceptance Criteria` | actual carrier |
|---|---|---|---|---|---|---|
| fixture 1 (bug form) | 2,612 | **8** | 0 | **1** | 0 | H3 template render; `### Expected Behavior` present |
| fixture 2 | 2,674 | **1** | 5 | 0 | 0 | H2 sections + **bold-prose** assertion block |
| fixture 3 | 4,067 | 1 | 4 | 0 | 0 | **bold-prose** scope + assertion blocks |
| fixture 4 | 6,062 | **0** | 9 | 0 | 0 | **H2** template render throughout |
| control A | 9,831 | 12 | 0 | 1 | 1 | well-formed improvement form |
| control B | 7,363 | 12 | 0 | 1 | 1 | well-formed improvement form |

*Probe validity.* Sensitivity — both controls return 12/1/1, so the extractor detects the headings it is looking for. Specificity — an impossible heading token returns **0** on all six. Truncation/extraction — every body is non-empty at the lengths shown. **Probe valid.** Measured result: **1 of 4** motivating fixtures carries the declared-scope field at `###`; **0 of 4** carry the acceptance-criteria field at `###`; and the fixture the handoff called heading-free carries **1**, while the fixture it did *not* classify carries **0**. The superseded tell therefore **inverted on its own fixtures** — it missed the case it named and matched the case it did not.

**What shipped.** Three rules, all inside the A4.7 block, none touching any contended surface:

| Rule | What it does | Which pinned criterion it satisfies |
|---|---|---|
| **R0** — form-agnostic field resolution | A field name resolves at **any heading level** and in **bold-prose block form**, for **both** operands. Heading level is a rendering artifact, never a semantic boundary. | AC-G1 (the A-side twin of S4, generalized so the same defect cannot reappear on the S side for a different body) |
| **A1** — assertion outside a named block | An outcome asserted in a scope/disposition narrative, or inside another criterion's conditional clause, is a member of **A** — the exact mirror of S4's authorized-means clause widening **S**. | AC-G1 |
| **A2** — determinacy floor | **A** is empty only when nothing is asserted in any form; that state emits `UNKNOWN(no-resolvable-assertion)`, **never `CONTAINED`**. | AC-G1 + the fail-open obligation |

Limb A's second conjunct is re-worded from *"≥1 acceptance criterion"* to **"≥1 asserted outcome in A"**, matching Limb B's operand-shaped wording. Shape 2's tell is re-authored to key on **"no declared-scope block resolves under R0 in any form"** and carries an explicit statement that a heading count is not the test — stated on both the enforcement surface and the authoring surface, so the false figure cannot be re-inherited from either.

**The predicate run against all six bodies — both arms, and they differ.**

| Body | A resolves? | S determinate? | Verdict | Basis |
|---|---|---|---|---|
| fixture 1 | ✔ via `### Expected Behavior` (R0) | ✖ standalone `OR` (S3) | **FLAG(Limb A, Shape 1)** | Declared scope forks; `### Expected Behavior` asserts the end-state unconditionally, and its reachability differs by branch |
| fixture 2 | ✔ via **bold-prose** assertion block (R0) — **∅ under the superseded table** | ✖ no scope block in **any** form | **FLAG(Limb A, Shape 2)** | One criterion's object is conditioned on another's outcome while two siblings assert full coverage; the two resolutions are different surfaces |
| fixture 3 | ✔ via bold-prose blocks (R0) | ✖ wholly-deferral scope **paired with** concrete deliverables in the criteria | **FLAG(Limb A)** — the N1-narrowed case, not a named shape | N1 exempts a *wholly* deferred scope whose criteria are correspondingly deferred; these are not |
| fixture 4 | ✔ via **H2** blocks (R0) — **∅ under the superseded table** | ✖ two deferral markers **+** two concrete paths | **FLAG(Limb A)** — mixed-deferral, **not** Shape 2 | The scope block resolves, so Shape 2 does not apply. Under the superseded `###`-keyed table both operands read ∅ and this body would have been classified Shape 2 — the inversion, in the one place it would have shipped |
| **control A** | ✔ | ✔ four concrete paths, no `OR`, no deferral | **NOT FLAGGED** | Limb A cannot fire on a determinate S. Limb B blocked by **N7** (its outcomes are produced by *reading/verifying* a required CI gate and branch protection) and **N5** (its consequential claims are unscored) |
| **control B** | ✔ | ✔ three concrete paths + prose qualifiers (S1 records, never narrows) | **NOT FLAGGED** | Each asserted outcome names a member of S as its producing surface; SA1 cannot name a missing one |

**Non-vacuity.** Four bodies FLAG and two do not; the two control arms are the A6.5 review's own over-fire counterexample and the top admitted-contained issue of the pinned calibration sample, so neither is cherry-picked. **A run where both arms returned the same result would be a BROKEN PROBE, not a pass** — this one does not.

**Explicit NON-EDIT, proven structurally rather than asserted.** #3703 writes nothing at the §12 enforcement-primitive region — the #3820 collision site. Extractor: `awk '/^## 12\. Enforcement Surface/,/…/'` over the base blob and the head file.

| Section extracted | base `05c965a3` | head | identical |
|---|---|---|---|
| **§12 Enforcement Surface** (the collision site) | 13 lines / `2c50bdbdb3da828d` | 13 lines / `2c50bdbdb3da828d` | **YES** |
| §5 Process *(sensitivity — where this commit does edit)* | 218 lines / `6bb1806986c68dfe` | 326 lines / `4d983a364df98df0` | NO |
| a nonexistent section *(specificity)* | 0 lines | 0 lines | **reported VACUOUS, not clean** |

The `all nine` count, the judgment-class enumeration, and the observation `n/a` list all stand verbatim as #3820 left them. Corroborating diffstats: `core/schemas/gate-criteria-spec.md`, `core/deploy/deploy.sh`, `core/schemas/gate-evaluation-spec.md` — **all empty across this commit**.

**Executor reachability — why two skill files are paid.** The criterion's emit slot already exists on **every** A6-field enumeration, so no enumeration is edited. Class-derived probe (not instance-keyed — the defect the A6.5 review named on the handoff's own census): `git ls-files -z | xargs -0 grep -lE 'Dependency-position signal'` returns **5** files; **4** are A6 enumerations and all four carry `feasibility` (7 / 4 / 5 / 4 hits); the fifth is a back-reference in the gate schema that carries none and enumerates nothing. *Specificity:* `ZZZ-position signal` → **0**. **Probe valid.** The two files this commit edits — the executor `SKILL.md` A4 row and its `references/triage-execution.md` A4 block — are the **only** two sites that enumerate the A4 emit channel itself, and both are edited. Leaving them unedited is the measured `G2-13`/`A4.6` failure (a criterion gate-blocking since v3.94 that the executing skill has no step to run), reproduced deliberately.

**Corpus freeness, re-pinned at build time** (denominator **1,607** tracked files at this branch tip, up from 1,596 at the design anchor). Subject arms before the edit: `SA-G1` → 0 · `SA-G` → 0 · `A4.7` → 0 · `G1-10` → 0. *Sensitivity:* `SR-G6` → 9 · `MD-G1` → 1 · `A4.6` → 10 · `G2-13` → 16 · `G1-09` → 9. *Specificity:* `SA-G9` → 0 · `A4.99` → 0 · `ZZZ_NOT_REAL_TOKEN` → 0. **Probe valid.** One subject moved: `scope-altitude` reads **1**, and the single hit is **this plan's own File Change Matrix row** written at Commit 0 — the ID space is genuinely free.

**Issue-reference gate.** `grep -cE '#[0-9]{3,4}'` → **0** in the style guide and **0** in the triage stage file; `allow-issue-ref` → **0** (no override marker added). *Sensitivity:* the identical pattern over this plan returns **115**, so the probe detects references where they exist. Both worked examples in the new §4c are authored **shape-only**, with de-identified prose attribution, in the demonstrated form of the section immediately above them.

**Template invariance.** Both issue templates parse as YAML after the edit; field **ids** and **`validations` blocks** are byte-identical to the base blob (9 fields / 12 fields, unchanged). **No field added; no `validations` changed** — the change is field-description text only, which is the whole of what a presence-only form layer can carry.

**AC-6 calibration sample pinned at Stage 6, and its bound stated out loud.** The design's re-runnability contract requires the twenty drawn bodies to be pinned by digest at Engineering so the false-positive rate is byte-comparable at any later commit. Captured here: **20 of 20** resolve, **20 of 20** non-empty (2,470–18,477 chars), each with a SHA-256 body digest recorded in the Stage-6 sub-task output alongside its ordinal — the drawn numbers themselves stay in the Stage-5 record and the independent review that reproduced the draw in the same order, rather than being re-introduced as twenty bare references into a durable-corpus file. *Specificity arm:* a ghost issue number resolves to a zero-length body, so an unresolvable row is detectable rather than silently skipped. **Stated bound, not discovered later:** the frame's own selection predicate is a line-anchored `### Affected Files`, and the sample is **20 of 20 H3-conformant** — while **3 of 4** bodies that motivate the check are not. **AC-6 therefore measures the false-positive rate on H3-conformant bodies only; the non-conformant class is uncalibrated.** That is the honest half of the adversarial review's mitigation; widening the draw with a second non-H3 stratum is the measuring half and is routed rather than taken, because scope is hard-locked.

**A figure struck rather than inherited.** The handoff's *"1,612 tracked files carry `5-test rule`"* is a `grep -lic` artifact (`-c` overrides `-l`, so every processed file emits `path:0` and `wc -l` counts files *processed*). Correct: **16 files / 44 occurrences** over a 1,607-file corpus — and 1,612 exceeded the handoff's own stated denominator, which is the most detectable broken probe there is. The placement conclusion it was offered for (a new §4c rather than a sixth test in the 5-Test Rule) **survives on its qualitative ground** — §4c is a body-quality rule, not an authoring-readiness test, and its structural sibling sits directly above it — but the measurement is withdrawn, not restated.

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
| **Card 5's label backfill** | **not `git revert`-ible.** Applying a label to 74 tracker issues is state outside the repository. Reverse sweep is bounded by the recorded identifier list and selected by the tracker's own label-application event inside the recorded execution window | **MODERATE, out-of-band** — mechanically reversible, but only through the ledger; see § Sub-task label backfill |
| The new ADR | reverting removes the file; **the number is not reused** — ADR numbers are immutably allocated and supersession is a status transition plus a new record | CHEAP |

**Rollback pre-condition — DISCHARGED at Engineering Commit 5, before the first label edit.** The backfill **records the exact issue-number list it mutates** into this plan and the Engineering sub-task thread. Without that list the reverse sweep cannot distinguish issues this release labelled from issues that already carried the label, and a blind reverse sweep would strip correctly-labelled sub-tasks. **This is the release's single genuine rollback hazard.** The list is recorded in § Sub-task label backfill above, and the discrimination it exists to provide is **demonstrated rather than asserted**: a correctly-labelled sub-task created before this release carries its label-application event outside the recorded window and therefore cannot be selected.

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
| **D-3-taken** | **The orphaned Gate-1 line edit is taken by commit 2.** #4561 correctly declined it as a verify-only editor; the hub reassigned it to #3821, which already edits that section. | Routing | Hub routing relayed at the Stage-6 chip briefing for #3821 | **Taken.** The criterion now **cites** the shared detector (reference module + governing record) instead of restating a pattern, per that record's own consequence clause. No corrected regex is restated — a criterion that prints a grammar *is* a private grammar, and a second copy drifts from the first by construction. |
| **AI-adv-4** | **The applicability cell for the AC criterion was wrong on the story kind form.** The Stage-5 design marked the evidence / AC / priority criteria `n/a` family-wide for kind forms; the story kind form declares a **required** Acceptance Criteria field whose description restates the very patterns that criterion enforces. 17 of 39 kind-form cards at this anchor are story-typed. | Major | Phase-A6.5 premise-rejection finding, corroborated here by reading the form and by a body-section probe over the live kind-form cohort | **Corrected in commit 2, at the level of the RULE rather than the cell.** F2 applicability is now **derived per issue from the body's declared field sections**, never asserted per family — so the epic/story difference falls out of the bodies and no cell can be individually wrong again. Sections measured across the 39-card F2 cohort: AC 9, Evidence 7, Priority 10 *(sensitivity: `### Proposed Change` → 8; specificity: `### Zzzsentinel` → 0; extraction non-empty 39/39)*. |
| **AI-adv-5** | **The doc-impact scope key leaked.** The Stage-5 design keyed the criterion's exemption to the authoring **form**, whose stated safeguard was that formless kinds ride the interim improvement vehicle "and are gated as F1". That is false: the interim vehicle stamps **no** intake-tier label, so those cards land in the kind-form family with a fully-authored declaration and would be exempted; and the key has **no evaluator at all** for a kind with no dedicated form. | Major | Phase-A6.5 premise-rejection + counter-design, corroborated here: the interim form's label array carries no tier label, and **6 of 39** F2 cards at this anchor carry a filled doc-impact section | **Counter-design ADOPTED in commit 2.** The criterion is keyed to the **issue body's** section. Same three properties the form key claimed — derived, no kind literal, self-revoking — plus the two it lacked: total over the population, and evaluable for formless kinds. |
| **AI-adv-6** | **The kind resolver was fail-open under partial degradation.** Its only alarm fired at the *empty* set, so every partial read returned a plausible non-empty subset with exit 0. Reproduced here: an unreadable pack file → 1 of 4 kinds, exit 0; a valid-TOML trailing comment on a `kind_id` → 3 of 4, exit 0; a valid-TOML single-quoted `kind_id` → 3 of 4, exit 0. One pack declares 3 of the 4 live kinds, so a single file loss removes 75% of the vocabulary silently. | Major | Phase-A6.5 failure-mode finding, independently reproduced at this build anchor against purpose-built degraded pack trees | **Fixed in commit 2.** The reader cross-checks its matched `kind_id` count against the file's own `[[kinds]]` table count and records an unreadable pack instead of swallowing it; all three arms now exit 3. **Specificity preserved:** a *deselected* pack (absent directory or absent file) is configuration, not degradation, and stays exit 0 — asserted by a dedicated self-test arm so the fix cannot fail loud on a correctly-configured instance. |
| **AI-adv-7** | **The `≥2 intake-tier labels` case would have lost a correct verdict.** The branch being replaced covered both the 0 case and the ≥2 case; the design's three families covered 0 only, so ≥2 would have fallen to the unresolved family, which is forbidden from carrying the "apply correct single label" remediation that is exactly right for it. | Major (latent) | Phase-A6.5 failure-mode finding. Live population at this anchor: **0** cards with ≥2 tier labels *(sensitivity: cards with ≥1 tier label → 123; specificity: a bogus label → 0)* — an empty cell, not a safe one, and this release performs 74 label mutations | **Fixed in commit 2 by statement rather than coincidence.** A fourth family (multi-tier) is stated ahead of the others and keeps today's emit **and** its remediation verbatim. Because the cell is empty live, it is exercised only by a fixture — and a purpose-built regression that deletes the branch turns that arm red, so the branch cannot rot unobserved. |
| **AI-adv-8** | **The new applicability block's row shape could inflate a sibling's row-count assertion.** The Gate-1 consistency criterion counts rows by a file-wide `\| G1-` prefix. | Minor | Phase-A6.5 failure-mode finding | **Honored in commit 2, and the delta is pinned rather than left to be discovered.** The new applicability block adds **zero** `\| G1-`-prefixed rows (its first column is the field the criterion reads). The file-wide count still moves **35 → 37**, entirely from splitting the one G1-09 self-repair row into its three cases — the same two-branch shape the file already uses elsewhere — and a row-by-row diff confirms that split is the *only* delta. No criterion row is added, renumbered, removed, or re-typed. |
| **AI-schema-ver** | **Schema version set to 2.9.** | Substantive | Mainline held **2.8** at this build anchor; re-derived rather than carried, per that value's own version-derivation note | **Set to v2.9 by commit 2.** The two remaining Gate-1 editors follow: the next bump lands at **2.10**, and an appending editor appends to that block. On a merge conflict at this line the resolution is to re-derive from the mainline and restate the enumeration — never to take either side's value. |
| **AI-schema-ver-3** | **Schema version set to 2.10 by commit 3.** | Substantive | Re-derived at commit time exactly as that value's own note prescribes: mainline held **2.8**, commit 2 landed **2.9** on this branch, so this bump re-derives to **2.10** and carries commit 2's block forward verbatim. The rule has now fired **four** times and the block says so | **Set to v2.10.** The remaining Gate-1 editor (**#3826**, commit 6) **appends its change bullets to the v2.10 block** rather than authoring a fresh block or taking a number — this reverses the instruction in that card's own design, which was written when v2.9 was expected to be the last bump on this branch. Stated here and in the version block so the appending editor does not append to a superseded block and produce a false historical record. |
| **AI-R12** | **The shared primitive-availability helper was offered a second time and DECLINED again.** | Decision | Offered by the Phase-A6.5 counter-design to commit 1; carried forward to commit 2 as optional, with decline as the stated default and the hub concurring | **Declined, and the reason is now stronger than it was at commit 1.** The condition for adopting was that commit 2's own change make the helper *strictly cheaper*; it does the opposite. Commit 2 adds a second block-start resolve whose degraded posture is not merely similar to commit 1's but **differently shaped** — commit 1 withholds one criterion for the whole population, commit 2 withholds a whole family's family-assignment while leaving two families fully evaluated. A helper general enough to express both would have to parameterize the withheld scope, which is more surface on a 4-way-contended function than the two explicit blocks it replaces. The named in-block convention is doing the work a helper would: commit 2 **bound** to it by statement, and the binding is asserted by test. |
| **AI-G-AC** | **The gating acceptance criterion pinned at Collective Review — the release-identity validator was specified without pagination.** The tracker API does not auto-paginate and its default page is 30 rows. | **Blocker**, deferred into Engineering as a gating AC | Re-measured live at Engineering Commit 3, and it is **worse than the pinned finding stated**: the open-milestone set now reads **45**, so the default read returns **30** and the specified form was **already truncating**, dropping 15 of 45 (33%) — not "one milestone from truncation". *Arms:* default 30 · `per_page=100` 45 · paginated 45 (state=all: default 30 · `per_page=100` 100 · paginated 217) | **Fixed by copying the form already in this repository** — `per_page=100` + `--paginate`, the same form the milestone-membership tool uses above a comment stating this exact harm. **No third lookup form authored.** `state=all` is also taken, so *closed* and *absent* are distinct reason tokens. Evidence is executable, not attested: a hermetic net drives the **shipped** resolver against a 201-row stub and grades every pagination arm against a deliberately regressed copy that must go red. |
| **AI-G-FM1** | **FM-1 was graded "narrowed, not closed" — the *valid-but-wrong* release sub-state passes existence-and-open validation untouched.** | Major, carried forward as a finding | Two concurrently-open release branches make it reachable today | **Not claimed closed, and the over-claim is removed rather than restated.** The record now says validation proves a milestone **exists and is open**, never that it is the **correct** one, and the residual is bounded by **disclosure**: the resolved slug, its source, and the milestone-set denominator are logged before any finding, so a wrong scope is legible at read time. The alternative — a second network probe to detect concurrent release contexts — was weighed and rejected: it adds a new failure mode to bound a residual the disclosure line already surfaces. |
| **AI-G-PR2** | **The branch carrier was adopted on N=1 against a measured 28.9% historical match across three documented branch forms, and detached HEAD yields no candidate.** | Major, carried forward as a finding | Corpus documents `release/<slug>` and the version-prefixed `release/vX.Y-<slug>`; the session protocol prescribes a detached HEAD at session end | **Both corrections taken, and the residual stated rather than papered over.** The rung is now **form-total** — both the full suffix and the version-stripped remainder are offered and whichever validates wins — and an unrecognized form returns `UNRESOLVED form-unrecognized` routed **advisory**, never `INVALID`, so branch-naming variance can never become a gating finding. The residual is written into the record: detached HEAD and post-merge mainline both resolve to `NONE`, so the gate's live window is **an attached release branch during Engineering through Plan Review** — narrower than the stage range implies. |
| **AI-G-PROV** | **The fail-closed disposition was being applied to a candidate nobody asserted.** The design's safety argument rested on the candidate being an *assertion*, but the branch rung *detects* — it fires on every run with no operator intent. | Major (adopted from the adversarial review's mitigation) | Three concrete paths: a milestone closed at release close while a worktree is still attached; an offline or rate-limited run on a release branch; any unhandled branch form | **Token space split by PROVENANCE, not only by outcome.** An **asserted** candidate that will not validate fails closed; a **detected** one degrades to advisory. Held by test: the detected miss and the asserted miss return different tokens, and the arm fails if they collapse. |
| **AI-G-PLACE** | **The resolver's placement was specified by region ("after X, before Y") with a gating emit sitting between the two anchors**, so the not-applicable guarantee held for the resolver's own emit and not for the check as a whole. | Major | The scope sub-check between the two anchors calls the gating emitter | **Pinned by ordinal, not by region.** The resolver runs **before** the scope sub-check and short-circuits the whole check on `NONE`. Demonstrated at runtime: a live `--check` from this detached worktree emitted exactly one advisory line and evaluated nothing. |
| **AI-G-ADR** | **ADR-120 is contended by two live sibling branches, and stepping past it to 121 is wrong.** | Substantive — **self-caught** | The numbering gate rejected 121 with `GAP: the global sequence 001..121 is not contiguous`; the ADR README's renumber log records the rule: an unmerged claim does not bind the sequence, a gap fails as readily as a duplicate, first-to-merge takes the number | **Corrected to ADR-120 before commit.** The reasoning "two siblings hold it, step past" is the exact error that log documents; running the governed checker rather than reasoning about it is what caught it. Recorded in the record's own numbering-provenance note so the next claimant does not repeat it. |
| **AI-G-A3** | **A structural-criterion count quoted from the peer gate-evaluation schema disagrees with this schema's own `Check` column.** The design's trace quoted the peer's parenthetical rather than recomputing from the column. | Major | The peer's parenthetical omits one criterion the `Check` column marks structural | **The figure is NOT authored into the governed record.** Writing it would have converted an existing inconsistency into a freshly-authored governed statement. The version block states that no count is restated from a peer schema and names the `Check` column as the authority. **Reconciling the peer surface is routed** — it is outside this card's two declared edit rows. |
| **AI-adv-9** | **The stated reason for declining the M2 emitter fix was false.** The Stage-5 design declined it because routing M2 through the advisory emitter "would put the byte-identity leg at risk". | Major | `git grep -F 'member-not-named'` at the build anchor returns **4 lines, all in the primitive, 0 in the deploy script** *(sensitivity: the sibling token → 10 lines / 3 files; specificity: a fabricated token → rc=1, 0 lines)*. The emitter question is entirely deploy-script-side and downstream of the primitive's output, so swapping it cannot perturb one byte of that leg | **Decline KEPT, rationale REPLACED.** The binding constraint is the card's **acceptance criterion asserting M2 still routes through the WARN emitter unconditionally** — the advisory emitter would make that criterion NOT-MET. The false coupling is not restated anywhere in commit 4, and the in-file comment now names the criterion as the reason. The two follow-up issues carrying the falsified rationale in their Dependencies/Risks fields need an operator edit; **routed, not amended** (a spoke does not edit issue bodies). |
| **AI-adv-10** | **The `no-milestone` token was unreachable for the modal live case.** The overlay's return-map shape was never specified, and the obvious implementation — comprehending only the nodes whose milestone is truthy — drops every null-milestone key, which the resolution rule then reads as absence and reports `unresolved`. | Major | Reproduced as a mutant of the shipped parser: dropping the null keys turns **11 of 14** live refs from `no-milestone` into `unresolved` — a 79% mis-token rate that the design's specified fixtures could not see, because none of them supplied an overlay entry with a null value | **Fixed in commit 4 by specifying the contract as TRI-STATE** — `{ref: n}` resolved-with-milestone · `{ref: None}` resolved-with-none · **key absent** did-not-resolve — with the parse layer keeping empty-but-decodable (`{}`) distinct from undecodable (`None`). Four dedicated assertions plus the mutant: the defect now **kills 2 arms** where it previously killed none. |
| **AI-adv-11** | **A crashed primitive rendered Check 56 GREEN on all three legs.** Exit 1 means both "findings present" and "the primitive raised"; a traceback lands on the same captured stream, parses as TSV with zero rows, and the block printed `OK: no drift`. | Major | Reproduced before and after: the pre-change projection on a 4-line traceback prints the OK line *(control: the same projection on a real M2 row prints WARN, so the projection is live)*; the post-change block prints **NOT-EVALUATED** on the same input and still prints **OK** on a genuinely clean emit | **Fixed in commit 4 with a structural-validity sentinel** — exactly one `COUNT_M2` row is the evidence the emit completed, counted by awk exact field equality. Adopts the existing posture rather than inventing one: **one finding naming the cause, every leg gated behind it**, through the same emitter the sibling exit-3 branch uses. The guard covers **M3 as well as M1/M2** — M3's own OK line is the same false green, and half-fixing it would have left the defect in place. The new fetcher is separately wrapped so it structurally cannot raise, and reports `degraded` distinctly from `fetched`, so this change adds no new instance of the pattern it removes. |
| **AI-adv-12** | **Three smaller review findings taken in the same commit.** A ref that is a `sub-task` member of the milestone being emitted would have read `[elsewhere:ms#<itself>]`; the new operator-facing detail line copied a `paste -sd'; '` idiom whose `-d` is a **cycling delimiter list**; and the replacement warn line was drafted across three rendered lines. | Minor→Major | `printf 'a\nb\nc\nd\n' \| paste -sd'; ' -` → **`a;b c;d`** — the second boundary is a bare space, indistinguishable from an intra-record one, against a live population of 7 M2 rows. The self-milestone case measures **0** live today *(sensitivity: relaxing the exclusion surfaces 54; specificity: a ghost ref → 0)* but the eligible population is large and a sibling card enlarges it | **All three taken.** A fourth enum value `member-excluded[:sub-task]` names the self-milestone case and the resolver now takes the emitted row's own milestone; the detail line joins with an `awk` accumulator and an explicit `"; "`, which also emits **no trailing newline** so the warn line stays single-line — the jsonl writer escapes backslash and double-quote only, and an embedded newline would write malformed JSONL into the warn log the enforce-flip decision is read from. |
| **AI-c56-trunc** | **The primitive's stage-title fetch is truncated at 1,000 rows against a live population of 3,166 issues** — a 68% under-read that silently shrinks the M3 orphan set. | Major — **surfaced, NOT fixed** | Independent count via the search API: **3,166** stage-titled issues *(specificity: a fabricated title token → 0)*; the tool's own fetch returns exactly **1,000**, the cap it passes | **Routed, not taken.** It is a fail-open on the **M3** leg's input, and this card's declared scope is the M2 leg; taking it would change a leg three other cards read. It belongs to the systemic fail-open cluster already filed. Recorded because the CIAC-4 limb-2 figures are computed over the truncated set and are therefore **lower bounds** — stated at that criterion rather than left for a grader to discover. |
| **AI-adv-13** | **CIAC-4 limb 2's "structurally vacuous" classification does not reproduce.** The review classed it vacuous by construction because the sibling card's cohort is entirely closed and unmilestoned. | Substantive — **correction to a review finding** | Re-measured at commit 4: **33** stage-titled issues lack the label, **16** sit in an open milestone and **12** are Scope-named, so the criterion has a real observable population *(sensitivity: 1 genuine hit over the stage-titled set; specificity: ghost number and fabricated label both 0)* | **Recorded at the criterion, with the part of the finding that survives.** The criterion is evaluable in general **and** blind to that one frozen cohort — compatible facts. Limb 2 is graded on its own population with its arms, never as evidence the backfill worked, and a re-measurement is explicitly not offered as the remedy for the cohort-specific blindness. |
| **AI-adv-14** | **The specified test suite left one property untested and the gap was caught by a mutation, not by review.** A mutant that removes the fetcher's degraded-vs-clean flag killed **0** assertions on the first pass. | Minor | Five mutants run against a throwaway copy; four killed 9 / 2 / 2 / 3 arms, the fifth killed **0** | **Closed before commit.** Four transport-substitution arms were added and the same mutant now kills one. **A mutation that kills zero assertions is treated as a build failure, not a pass** — the whole point of running them. Also reconciles the design's internally-inconsistent M-2 prediction (`57→56` in one place, `55` in another) in favour of the arithmetic: the counter mutation kills exactly **2**. |
| **AI-adv-15** | **AC-3 was recorded "structurally unverifiable" against a gate leg that was never examined.** The Solutioning design enumerated the membership leg and the status-label check, found both scoped to open state, and concluded no end-to-end verification existed. It never reached the **third leg of the same tool** — scaffold-completeness — whose `UNLABELLED` class reads **closed** milestones by documented design. | Major — **premise rejection** | Six `UNLABELLED` rows observed live at this build anchor across six milestones, **including the exact issue the criterion names** *(specificity: a milestone holding none of the cohort → 0 findings)*. The leg's closed-milestone reach is documented in the tool at the resolver, whose comment states a scaffold audit of a historical release must be able to read a closed milestone | **Counter-design ADOPTED in commit 5.** The end-to-end form of AC-3 is restored and graded, not recorded unverifiable: all **6** rows present before, **0** after — measured, not predicted. The recorded-vacuity language is withdrawn. **Honest bound:** the 6 are a *lower* bound, not a count — see AI-c56-trunc-2. |
| **AI-adv-16** | **The additive-only analysis was run in one direction only.** The design proved the backfill is a no-op for the 43 issues already carrying the legacy alias, and stopped. For the **31** carrying neither label the family predicate flips false→true, moving them out of the work-item population and changing the scaffold denominator — and the file carried **three** present-tense prose claims that the backfill falsifies, on a file the design marked no-change. | Major — **premise rejection** | The review named two claim sites; a read of the whole file at this anchor found a **third**, in the fixture comment. Corpus sweep for other stale claims on the cohort: **0** outside this file *(sensitivity: the same pattern unrestricted → 2 files; specificity: a fabricated identifier → 0)* — the second file is a frozen historical plan citing a source comment, correctly untouched | **All three reconciled in commit 5, prose only.** Tense-shifted to historical with the reason the guard still matters stated inline: the limb fires on a **shape**, the backfill cleared one population, and the fixture is synthetic so the guard survives the remediation of every instance it was built to catch. **Zero behavioural change** — self-test 71/71 before and after. Fixing two of three would have shipped the same drift one screen down. |
| **AI-adv-17** | **The one acceptance criterion that can fail depended on a baseline the mandated execution order never captured.** The order was ledger → verify pre-state → mutate → verify post-state; none of those steps records the evidence-preservation denominator, and the mutation destroys it. | Major — **failure mode (PROC)** | The criterion's "before" appears nowhere in the specified procedure steps or handoff notes | **Baseline capture added to the gated order and folded into the ledger itself**, so the "before" lands in the same artifact, at the same gate, as the identifier list — one transaction, not two. Applied to **both** discriminating criteria: the evidence-preservation denominator and the scaffold-completeness findings. Both post-states measured; deltas in § Per-issue verification. |
| **AI-adv-18** | **Silent idempotence plus an open window made the ledger the sole rollback discriminator, and an unverifiable one.** The mutating command succeeds identically on a no-op, and post-state verification returns the same verdict whether this release applied the label or it was already present. | Major — **failure mode (INPUT)** | The population moved twice during Solutioning alone, so the drift rate is non-zero by the design's own measurement | **Counter-design ADOPTED in commit 5, both halves.** (a) The selector is now the **tracker's own label-application event** bounded to the execution window — third-party-recorded, per-issue verifiable, and validated with a discrimination arm proving a pre-existing sub-task falls outside the window. (b) Pre-state is **re-read per issue immediately before its own edit**, so a label appearing mid-sweep is recorded as an explicit skip rather than silently absorbed. Zero skips occurred. The ledger is demoted to the corroborating intent record and the scope bound, and is **committed to git** rather than living only on the mutable surface it recovers. |
| **AI-adv-19** | **Blast radius was traced against the edited file, not the mutated attribute.** A label backfill changes the membership of every mechanism that *partitions on* that label, not only the gates that *report on* it — including a planning cache fingerprint defined by the label's absence. | Major — **failure mode (OUT)** | Predicate-scoped enumeration at this anchor returns **11** consumers keyed on the label *(sensitivity: the same sweep unrestricted → 12 files; specificity: a fabricated label token → 0)*, of which the file-scoped analysis named 4 | **Enumeration produced with a disposition per consumer** — the mitigation the review asked for. **2 affected and intended** (evidence-preservation denominator; scaffold-completeness findings). **3 structurally blind** — all fetch open state or open milestones, and the cohort is 74/74 closed with none in an open milestone. **2 affected in principle with no live effect** — the planning cache fingerprint and the close-out resolver, both keyed per-milestone, and all 24 milestones are already closed. **4 not consumers** — fixture-driven or literal prose. **Live impact today: nil**; the finding was the missing enumeration, not a live break. The planning surface's stated premise is **deliberately not edited**: a governance mandate is not mechanical enforcement, so its fail-closed title-shape conjunct remains correct. |
| **AI-c56-trunc-2** | **The stage-title fetch truncation is worse than commit 4 measured, and it bounds this card's own figures.** Commit 4 recorded a 1,000-row cap against 3,166; the population reads **3,028** by this card's own complete sweep, so the leg reads roughly a third of it. | Major — **surfaced, NOT fixed** | Probed directly rather than inherited: a milestone holding **31** unlabelled stage-titled issues nonetheless reported **zero** scaffold-completeness findings — the truncation artifact, not a clean milestone | **Routed, not taken** — the same leg three other cards read, and already owned by the systemic fail-open cluster. **Recorded because it makes this card's 6-row before/after a strict lower bound**, stated at the criterion rather than left for a grader to discover. The delta remains discriminating regardless: 6 → 0 is a real observed change, and a lower bound that goes to zero is still a proof the class cleared on every row the instrument can see. |
| **AI-ledger-thresh** | **The pre-execution ledger's own rollback threshold was wrong, and would have selected nothing.** It stated a forward-estimated timestamp later than the actual mutation window. | Substantive — **self-caught, post-execution** | Client-invocation window `04:50:11Z–04:52:30Z` against a stated threshold of `04:55Z`; the ledger comment itself posted `04:49:23Z`, and all 74 mutations are strictly after it | **Corrected by amendment, not by editing the record.** The pre-execution comment is left byte-intact — its entire value is that it was written *before* the mutation, and editing it would destroy that property. The corrected selector is **bounded on both sides** and its lower bound is safe by construction. A rollback key that fails closed by matching nothing is the same broken-probe shape this release exists to eliminate, which is why it is corrected loudly rather than quietly. **Superseded in part by AI-008 below:** the window quoted here is the *client* frame, and the amendment's own execution record carried it forward as though it were the selector. |
| **AI-008** | **The rollback record existed in three durable copies and they disagreed, and the only correct one was the ephemeral one.** The parent-card pointer (#3709, `5212541993`) carried the pre-execution forward estimate `>= 04:55Z`; this plan carried the client-invocation window ending `04:52:30Z`; only the #4841 amendment's both-sided selector spanned the real event set. **Root cause: a frame mix** — the client's invocation timestamps and the tracker's `created_at` timestamps were treated as one clock, and they differ by about a second. | Major — **failure mode (OUT)**, caught at Stage 9 Plan Review | Replayed against GitHub's own `labeled` timeline over one captured event set (74 cohort issues, exactly one event each, 0 read failures, max 59 rows `< 100`): `>= 04:55Z` selects **0**; `04:50:11Z–04:52:30Z` selects **73**, missing **#4047** at `04:52:31Z`; `04:50:11Z–04:52:31Z` selects **74**. Controls: #4840 (pre-existing sub-task) at `2026-08-05T23:50:45Z` falls outside, #3826 carries no event — **0 controls selected** | **Every durable copy reconciled to `04:50:11Z` through `04:52:31Z` inclusive, in the tracker frame, with the frame named at each site so the two clocks cannot be conflated again.** The plan's Execution row and selector block now state both frames and which one is the key; a correcting comment is appended to the #3709 pointer and a second amendment to #4841. **No pre-execution record was edited** — both originals remain `created_at == updated_at`, which is the property that makes them evidence. A rollback key that is wrong in the copy most likely to outlive the others is worse than one that is wrong loudly. |
| **AI-relproc** | **The doc-impact scope narrowing has two restatements in a Tier-1 governance file that commit 2 does not edit.** The release-process governance file states the declaration rule at Stage 1 (already carrying a per-template exemption register) and the resolution rule at Stage 13 ("every closed issue in the release"). | Residual — **routed, not taken** | Phase-A6.5 failure-mode finding; both restatements read at this build anchor | **NOT taken by commit 2, deliberately.** The review explicitly reserved the mirror-vs-collapse choice from Engineering because the two options have materially different blast radii on a Tier-1 surface, and the hub's routing to #3821 did not assign it. Commit 2 instead marks the schema row **the authority** for this scope, so a reader landing on a restatement is pointed at the owner. **Routed to the hub** to assign the mirror or the collapse — to a later commit in this release, or to a next-release issue. |
| **AI-relproc-2** | **The routed residual above is DISCHARGED at Engineering Commit 6 — collapse, not mirror.** The hub assigned it to card 6 because that file is already inside its cascade scope, so the choice cost no additional contention. | Residual — **taken** | Three occurrences of the declaration measured in the governance file at this build anchor *(sensitivity: the bare word in the same file → 3; specificity: a fabricated section name → 0)*; the schema row already declares itself the authority and names two of the three as derivative | **All three collapse to pointers.** Each keeps its stage-narrative sentence — the field is declared at Stage 1, implemented at Stage 6, gated at Stage 13 — and hands every scope, grammar, and posture question to the row that owns it. The choice was doctrine-determined rather than open: register-or-remove, and the sibling commit had already established the authority locally with the durable reason that a criterion which prints a grammar **is** a private grammar. A second copy of a scope statement is a shadow SSOT that drifts, which is the same defect the sibling remand was fixing one file over. |
| **AI-cascade-6** | **Card 6 expands the machine-readable matrix by ten paths.** Eight readiness-scan cascade consumers outside its declared four-file set, plus a rebuilt skill package and its sidecar. | scope (approved in kind) | The cascade breadth was measured and re-presented at the wave-2 briefing and its disposition — absorb in-release — was approved there; the individual paths were never written into the extraction block | **Block extended in the same commit**, per its own rule. Nothing is newly *decided*; the already-approved scope is made extractable by the downstream chips. |
| **AI-count-preserve** | **Four declared substitutions were wrong, not missing.** Card 6's design listed the readiness spec's two `operator-enumerated` phrases and its `CONFIRM-13` decision name among the tokens to renumber. | Major | Adversarial review, second pass: the same commit adds a note affirming the operator enumeration is still 13, so substituting those tokens would make the file contradict itself **inside one commit** — and the third declared substitution on that line had no correct target at all | **Marked PRESERVE; the surrounding prose carries the distinction instead.** The spec now states both facts explicitly — thirteen operator-enumerated dimensions plus one derived gate-state row, fourteen rows in total — so every count in the file means one or the other and never both. Whole-change figure moves **32 → 28**; the out-of-matrix figure is unchanged at 13 / 11 / 9. **This is a disposition change, not a measurement change**, and it is recorded as one rather than quietly restating a smaller number. |
| **AI-overclaim** | **The design's replacement sentence about draft pull requests was false — and it was itself the correction of an earlier false sentence in the same paste block.** | Major | Two independent measurements of the **same** draft pull request, separated only by time, returned **opposite constant** merge-state values. The field tracks CI state, not draft-ness | **The claimed relationship is deleted, not restated with a corrected constant.** Draft-ness is read from the field that carries it, and the spec now says explicitly that no fixed relationship between draft-ness and merge-state holds, because one stated in either direction is falsified by re-reading at a different moment. A **third** wrong host fact in the same block was the live risk; removing the claim closes it in a way that replacing the constant would not. |
| **AI-borrow-passset** | **The new dimension's clean predicate was stricter than the gate that actually merges, and the disagreement was unregistered.** | Major | The Stage-12 pre-merge mergeability step accepts three merge-state values; the dimension accepted one — so two values the merge step passes would have produced a Stage-9 condition, and the immediately preceding release merged at one of them | **The pass set is borrowed and cited, not authored.** The dimension defers to the Stage-12 step for which values are acceptable and states that Stage 9 is deliberately not stricter than the gate that merges. Register-or-remove, applied to a duplication the design had registered against the wrong partner. |
| **AI-settle** | **A not-yet-reported check would have downgraded a healthy release.** The unresolved state was derived purely from "bucket is not pass", at the phase most likely to observe a pending context. | Major | The scan runs immediately after evidence assembly on a freshly-pushed head; the evidence command documents a dedicated exit code for pending checks | **A bounded settle allowance is borrowed from the existing Stage-12 pending-computation backoff**, and the unresolved state is entered only after its cap. No new mechanism — the platform already had this pattern for exactly this case. |
| **AI-version-field** | **Card 6's design directed a `version:` frontmatter bump on the readiness spec; it was NOT taken.** | minor — deliberate non-execution, recorded rather than silent | That field is a **platform release tag**, not a per-file schema version: three sibling specs carry the identical value, and it is absent from the platform-doc frontmatter required set, so no gate asks for it. Writing a concrete value now would write a **provisional release version** into a file, which this release's slug-primary identity rule prohibits outright | **Left unchanged and the reasoning recorded.** The design's premise — "a corpus-schema version, not the release version" — does not survive contact with the standard that defines the field. The spec's own Version-History table carries the change record instead, which is where a reader looks. |
| **AI-schema-line** | **Card 6's declared edit line in the gate-criteria schema had moved, and so had its version block.** | minor | Five commits landed between the design and this build; the schema grew, and the block moved v2.9 → v2.10 exactly as this plan's own version-derivation row predicted | **Re-read live and appended, never assumed.** The criterion edit landed at the live line; the change bullets were appended to the **v2.10** block per that block's standing instruction, which has now fired a **fifth** time. No fresh block authored, no number taken. |
| **AI-G-OPERAND** | **The gating acceptance criterion pinned at Collective Review — operand determinacy was fixed for the declared-scope operand and left field-keyed on `###` headings for the asserted-outcome operand.** On one motivating fixture the asserted-outcome operand resolved to ∅, so the second conjunct of the indeterminacy limb was unevaluable and its criterion was a graded FAIL as authored. | **Blocker**, deferred into Engineering as a gating AC | Re-measured line-anchored at this build anchor over four motivating fixtures plus two controls: **1 of 4** carry the declared-scope field at `###`, **0 of 4** carry the acceptance-criteria field at `###`; one fixture renders entirely at `##` and two carry their blocks in bold prose *(sensitivity: both controls return 12 `###` headings and 1/1 of each field; specificity: an impossible heading token → 0 on all six; extraction non-empty 6/6)* | **Fixed at the extraction layer, symmetrically, so the defect cannot reappear one operand to the other side.** Three rules ship inside the A4.7 block: **R0** resolves a field name at any heading level and in bold-prose block form **for both operands**; **A1** is the asserted-outcome twin of the authorized-means rule; **A2** is a determinacy floor emitting `UNKNOWN(no-resolvable-assertion)`, never `CONTAINED`. The limb's second conjunct is re-worded to *"≥1 asserted outcome in A"*, matching the containment limb's operand-shaped wording. Graded executably: the predicate is run against all six bodies, **4 FLAG / 2 controls NOT FLAGGED** — see § Verification Plan. **A-side-only would have been insufficient:** the H2-rendered fixture's *declared-scope* operand also read ∅ under the superseded table, and it would have been mis-classified as the no-scope-block shape. |
| **AI-hub-jq** | **A false `[SOURCE]` figure inherited from the hub was shipping as a durable detection tell.** The claim *"the fixture carries zero `###` headings of any kind"* was produced by a regex whose `^` anchors to the start of the *string*, not each line. | Major — **correction to an upstream premise** | The same read line-anchored returns **1** (`### DoR completion — triage drain …`) against a control returning 8; the fixture the claim did *not* classify is the one that actually carries **0** | **The tell is re-authored, not patched.** It now keys on *"no declared-scope block resolves under R0 in any form"* and states explicitly that a heading count is **not** the test — carried on **both** the enforcement surface and the authoring surface, so the figure cannot be re-inherited from either. Recorded because the superseded tell **inverted on its own fixtures**: it missed the case it named and matched the case it did not, and shipping it would have made the check wrong in the two directions it exists to distinguish. |
| **AI-E20** | **A `grep -lic` artifact in the design handoff overstated a corpus figure by 100×.** `-c` overrides `-l`, so the pipeline emits `path:0` for every processed file and the row count is files *processed*, not files *matching*. | Major | Re-run in both forms at this anchor: correct `grep -lE` → **16 files**, `grep -oiE` → **44 occurrences**, against a tracked-file denominator of **1,607**. The handoff's **1,612** exceeded its own stated 1,596-file denominator | **Struck, not restated.** The conclusion it was offered for — a new authoring section rather than a sixth test in the 5-Test Rule — **survives on its qualitative ground** (a body-quality rule is not an authoring-readiness test, and its structural sibling sits directly above it). The measurement is withdrawn so Engineering and any later re-litigation do not inherit it. A count larger than its own population is the most detectable broken probe there is, and none of the handoff's arms caught it. |
| **AI-CIAC5-arms** | **The non-membership probes discharging CIAC-5 shipped without a control arm** — the only uncontrolled zeros in the handoff, inside the design that discharges the fail-open pattern. | Major — **failure mode (OUT)** | Every *other* declared method in the same handoff carries one; the asymmetry sat exactly on the row whose claim is *"satisfied by absence"* | **Each zero is paired with a positive arm at the same path, and the pairing is normative in the criterion text.** `G1-09` → 38 · `recommend_g1_enforcement` → 12 · `Check=judgment` → 6, against `SA-G1` → 0 and `SA-G9` → 0 on all three. **A run where the control arm also returns 0 is a BROKEN PROBE, not a pass** — stated at the criterion. The underlying claim is separately true on the merits: **no machine consumer of the A4 emit exists** across 125 tooling files *(sensitivity: a genuinely machine-consumed token in the same trees → 4 files; specificity: a fabricated field → 0)*; the one textual hit is a test-fixture issue body. |
| **AI-cascade-7** | **Card 7 expands the machine-readable matrix by four paths and RETURNS three contended surfaces.** The two `pipeline-triage` executor files plus its rebuilt package and sidecar are added; the gate schema, the deploy script, and the §12 region of the triage stage file are dropped. | Scope (Tier 2) | The re-designed architecture homes the criterion as a stage-local advisory determination rather than a registry criterion, which is what removes it from all three contended surfaces | **Block extended in the same commit**, per its own rule. The two skill files are the **executor**, and the cost of declining them is the measured dormancy failure this release is otherwise fixing. Net contention effect is **negative**: the gate schema stays 3-way and the deploy script stays at four touches. |
| **AI-CD1-routed** | **The adversarial review's counter-design — resolve both operands from the Phase-A1 template-resolution step rather than from heading literals — is NOT taken.** | Counter-design — **routed, not taken** | It re-couples this card to the Template Detection Logic block that a sibling card edits **in this release**, re-importing the exact contention the re-design spent its argument shedding; the review itself recommends the cheap fix for this release and the counter-design as the durable answer | **Cheap fix taken; counter-design routed as a next-release issue.** R0 generalizes the extraction rule inside the A4.7 block with zero upstream coupling. The durable version — consuming a governed, template-aware resolved field map instead of re-deriving from heading forms — is the better long-run shape and is recorded here so it is not re-derived from scratch. |
| **AI-a47-enum** | **The design directed an `A4.7` clause into the §5 Phase-A enumeration; the sibling sub-determination `A4.6` is not enumerated there.** | minor — **house-style reconciliation, recorded rather than silent** | Read at this anchor: the §5 Phase-A line enumerates A0 / A1 / A2 / A2.5 / A3 / A3.5 / A4 / A5 / A5.5 / A6 / A6.5; `A4.6` appears only inside A0's parenthetical, never as a peer member | **Named as a sub-clause of A4, not as a peer enumeration member.** The phase list names `A4.7` — which is what the design asked for and what executor reachability needs — without creating an asymmetry in which one conditional sub-determination is a peer and its sibling is not. The `A1–A6.5` range strings are unaffected: an interior sub-phase leaves both endpoints true, **7 files PRESERVE**. |
| **AI-fm3** | **A governed output-contract surface carried the same A6 field enumeration and was never dispositioned.** The skill-output ownership registry holds three independent enumerations for this skill and appeared in neither the handoff's blast radius nor its cascade sweep. | Major — **failure mode (HAND)** | Class-derived probe rather than the instance-keyed one the handoff ran: 5 files carry the `Dependency-position signal` enumeration, of which 4 are A6 enumerations and all 4 carry `feasibility` (7 / 4 / 5 / 4 hits); *specificity:* a fabricated signal name → 0 | **Dispositioned N/A, and recorded as N/A rather than left unexamined.** The registry says *"feasibility flags"* generically and *"feasibility"* in its enrichment list; both stay true after an A4.7 sub-check adds a value to an existing field, so no edit is owed. *"N/A, recorded"* and *"never examined"* are different states, and distinguishing them is the whole content of the fail-open finding this release is closing. |
| **AI-ac6-stratum** | **The false-positive calibration sample and the defect class the check exists for are disjoint on the exact axis the operand table keys.** | Major — **failure mode (PROC)** | Measured at pinning time: **20 of 20** drawn bodies carry the declared-scope field at `###`, while **3 of 4** motivating defects do not | **The bound is stated, not measured away.** AC-6 measures the false-positive rate **on H3-conformant bodies only**, and the non-conformant class is recorded as uncalibrated. Widening the draw with a second non-H3 stratum is the option that actually measures the check; it is **routed**, not taken, because scope is hard-locked and the stratum change would alter a pinned sample the review independently reproduced. The design's own recency-bias threat is a different, adjacent threat and both are now named. |
| **AI-pkg-preexisting** | **A second stale skill package is present and is not this card's.** | minor | Card 6's own reference-file edit made its package stale and it was rebuilt in the same commit; the other skill's sources are untouched by this commit *(probe: 0 hits, against a sensitivity arm returning 1 for the rebuilt skill)* | **Rebuilt only what this card made stale.** The pre-existing drift is attributed and left with its own owner rather than absorbed. The freshness gate is warn-mode and is not a required context, so it reports rather than blocks. |

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
