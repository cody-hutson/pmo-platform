---
title: Release Plan — hub-emits-state-gates-read (the hub emits the state its gates read, and the platform can measure whether its decisions are observable)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: hub-emits-state-gates-read
release_class: novel
reversibility: CHEAP / Confidence HIGH — every member is a bounded edit to tracked files plus three new files, single PR and single merge, so `git revert -m 1` of the merge restores `main` byte-for-byte. Two qualifications, both recorded in § Rollback Strategy: the two `packages/*.skill` artifacts are rebuilt from reverted source rather than reverted independently, and the version tag is retained and recorded rather than deleted.
---
# Release Plan — `hub-emits-state-gates-read`

**Milestone:** `hub-emits-state-gates-read` (milestone #342) · hub sub-task **#7261** = Stage-4 plan source, the late-add editability addendum, the consolidated Stage-5 Amendment Pass, and two **Decision Recorded** gate comments · **#7305 · #7309 · #7313 · #7317 · #7321 · #7393** = the Stage-5 design sources · **#7306** = the Stage-6 Engineering sub-task that authored this file.
**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.
**Topology:** D-C **SINGLE** — one release branch (`release/hub-emits-state-gates-read`), one PR opened at Commit 0 in draft so CI runs while later cards land, one merge, base `main`. This plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. SINGLE implies P0 by the posture taxonomy's own mapping, and the contention map independently supports it: four of six cards write into two shared files. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.
**Release class:** `novel` — rendered by the operator at the Stage-4 plan-approval gate, concurring with the milestone's standing declaration. Differentiation posture: full Stage-9 review depth, higher engagement density, no stage skips, four Cross-Issue Acceptance Criteria.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7261, its late-add `### Agent-Editability Read` addendum, the consolidated **Stage 5 Amendment Pass** posted on the same sub-task, and both **Decision Recorded** comments on it (the Procedure-0 plan-approval gate and the second-render Collective Review scope-lock). It reconciles those to the six Stage-5 design specifications. **Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority.** Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7306, card #4027).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination. It sets the floor and binds no concrete number. The Stage-4 recorded determination was provisional-display **v4.61** (anchor `v4.60` + minor bump); the Commit-0 re-verify recomputed the same value against fresh authoritative host state. The slot is contended — see § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-11 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/hub-emits-state-gates-read` |
| **PR** | #7416 — opened in **draft** at Commit 0 per the SINGLE topology, so CI runs while the remaining cards land on the same branch; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `hub-emits-state-gates-read` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-10, domain: governance }`

**Domain classification.** Form **X** (sourcing-exempt): every add/edit row targets an internal `pmo-platform` artifact — pipeline governance, skill definitions and their reference docs, platform standards, an ADR, and two built skill packages — so no external body of practice is consumed and no Form-A citation exists to record. Dominant domain **`governance`**; secondary **`software`** for the two `packages/*.skill` build artifacts, the `evals/` fixture file, and the one `*.sh` edit row. Dominant is recorded in the label, secondary noted here, per the A3-time classification rule. Transcribed unchanged from Stage-4 Phase A1.5; no Mode B → Mode A upgrade applies, because no external source is consumed at all.

**Why the label is load-bearing rather than ceremonial.** It is read by the Stage-13 close-class rung, by the Stage-5 impact-method selector (which is what routed every design spoke to the default markdown-tree blast-radius tool rather than a domain sibling), by the design-review checklist's guide resolution, and by Stage 7 Phases A and C. A transcription that dropped it would silently starve four consumers.

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `origin/main` = `a30838589583bcddf5f88183cfff1a8ea2475300`. The Stage-4 baseline pin was `a3083858`; **the substrate did not move between Planning and Engineering** — zero commits landed on `main` in the interval, so the plan's pin and the Commit-0 base are the same commit. | `git fetch --tags origin`; `git fetch origin main`; `git rev-parse origin/main` |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.61`.** `anchor()` = **`v4.60`**, the highest claimed version in the mainline lineage. `FLOOR(minor)` = `(4, 61)`; `v4.61` is absent from `claimed_set()`, so the walk terminates at the floor. | **Tag arm (binding)** — 204 tag refs read, 199 conforming to `vN.M`, majors `{1,2,3,4}`, max `v4.60`. **Published-release arm (corroborating)** — `gh api repos/:owner/:repo/releases/latest` → `v4.60`. **Ledger arm (corroborating)** — `git show origin/main:release/releases/RELEASE_LOG.md`, parsed by header name not ordinal (`Version` col 0, `State` col 6): 227 data rows, all `VERIFIED`, **0 `DEPLOYED`**, and **0 rows mentioning `v4.61`**. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** The planned version `v4.61` is **not** in the claimed set **and** equals the recomputed next-free, which is the conjunction the gate requires. No colliding tag exists. | Sensitivity arm, same instrument and population — the identical membership test resolves `v4.60` and `v4.01` as **present**, so membership detection demonstrably fires. Specificity arm — `v4.99` resolves **absent** on the same non-empty tag set, so an absent reading is a real absence rather than a dead matcher. Subject — `v4.61` absent. |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp hub-emits-state-gates-read` → **exit 0** (`verify-stamp OK`). | Read-only and network-free — the identical pre-flight the Stage-12 atomic claim runs. The Header `**Version**` cell carries the literal unresolved `{{RELEASE_VERSION}}` token and no other text, which is what the Stage-12 claim resolves and renames on. |

**The tag arm binds; the other two corroborate and never authorize.** Stated because the ledger arm's reading is the one most easily misread: **0 `DEPLOYED` rows and 0 rows naming `v4.61` is not evidence that `v4.61` is free.** A ledger row is written after a claim, so its absence is consistent both with an unclaimed slot and with a claim whose ledger write has not landed yet. Freeness is established by the tag arm alone; the ledger arm's value here is that its 227-row `VERIFIED` sensitivity reading proves the parser read real state cells rather than missing the header.

**The slot is contended, and that is recorded rather than gated.** At Commit 0 there are **five** in-flight sibling release branches carrying open draft PRs — `closeout-correctness-batch` (#7253, `634cda91`), `authoring-bar-and-consumers` (#7410, `a12e6cfe`), `deploy-tools-and-tests-batch` (#7404, `d04163fe`), `governance-pointer-fixes` (#7401, `f75ceb61`), and `pack-conformance-and-parity` (#7400, `f8e3a55f`). The Stage-4 roster measured **n=1** from the open-PR-plus-remote-head derivation; four further releases have since branched, which is the growth the Stage-4 hub divergence note predicted. `closeout-correctness-batch` records the identical next-free `v4.61`. This does not convert D-Version into a gate: the number binds only at the Stage-12 atomic compare-and-swap, whichever release merges first takes the slot, and the loser recomputes upward with no rework because the branch and plan-file names are slug-primary and do not rename.

**Why the number is recorded but not bound.** Step 2's `v4.61` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. **The numbers in this section are deliberately not restamped later** — they are a reading at a named SHA, reproducible by re-running the recorded commands at that SHA.

**`${AUDIT_DATE_UTC}` resolution — a deliberate non-resolution.** The date-variable convention resolves such a token at Stage-6 first commit. It is **not** resolved here, and the deviation is the specification rather than an oversight: `${AUDIT_DATE_UTC}` is the Mode J audit-folder anchor, produced by **each run** of the capability rather than authored once, so the literal token must appear verbatim in every artifact this release adds under `core/skills/pmo-qa-auditor/`. The shipped mode-spec states the rule in its own words — a resolved date written into a spec is a defect. Engineering therefore substitutes no date into those artifacts. The UTC date at Commit 0 was **2026-09-11**; it is recorded here, where it is provenance, and nowhere that a run would read it.

---

## Scope

### Issues Included

| # | Issue | Title | Limb | Size | Editability class |
|---|-------|-------|------|------|-------------------|
| 1 | #4027 | Build the repeatable hub & spoke decision health-check | B | L | `sanctioned-session-required` |
| 2 | #4028 | The DS1–DS7 decision-coverage scorecard | B | S | `sanctioned-session-required` |
| 3 | #5232 | Single-source the hub's gate contract | A | L | `sanctioned-session-required` |
| 4 | #5278 | The hub creates the state surfaces its gates read | A | M | `sanctioned-session-required` |
| 5 | #5282 | The action-item ledger is written by a forcing function | A | S | `unconstrained` |
| 6 | #7392 | `recommendation-choice-delta` carries a declared emission obligation | A | S | `sanctioned-session-required` |

**Six members.** The milestone was operator-locked at five cards at the Stage-4 plan-approval gate; **#7392 was admitted afterwards by an operator-settled scope extension**, and its `### Agent-Editability Read` row was appended to the Stage-4 plan by addendum before its sub-tasks were stamped. Both surfaces are transcribed here; this file is the single record from Commit 0 forward.

### Two limbs, one object

**Limb A** (#5232 · #5278 · #5282 · #7392) is the hub's own gate and emission contract — one solution seam across four cards. **Limb B** (#4027 → #4028) is the decision-health audit capability, a strict two-step serial chain. The limbs share **zero** files.

The bundle is coherent at the **capability** altitude and is not coupled at the **build** altitude, and the plan says so rather than conflating them: both limbs act on the same object — *the hub's decision record* — with Limb A making the record exist and single-sourcing the contract that governs it, and Limb B making the record's completeness measurable. Either limb could ship without the other. Coherence is the standard a vertical slice must meet; coupling is not, and claiming it would justify the bundle on evidence this plan does not have.

### Exclusions

N/A — enumerated over the classes that could produce one: no member was descoped at Stage 4, none was descoped at either Collective Review render, and no successor slice was cut. The one scope *reduction* proposed during the release — withdrawing the M4 population screen — was **declined** by the operator at the second Collective Review render (see § Deviation Log DEV-2), so it is not an exclusion.

### Dependency Graph

Directional. `A → B` reads *"B cannot start until A lands."*

| Edge | Kind | Basis |
|---|---|---|
| **#7253 → {#5232, #5278, #5282, #7392}** | **HARD (external, Tier-S)** | The in-flight sibling release edits four of this release's files and records the same version slot. Dispositioned at the Stage-4 gate as *proceed in parallel, re-baseline at Stage 9*. |
| **#7253 → #4027** | **SOFT (read-edit)** | The sibling edits `release/skills/release-executor/SKILL.md`, which #4027 reads as an oracle source. It changes the oracle set under #4027's feet but blocks nothing — and it is the live case that proves the content-hash half of the oracle pin earns its keep. |
| **#5278 ↔ #5282** | **JOINT (bidirectional, one seam)** | Both build on the same landed upstream and both target Procedure 4a. Not an ordering edge — a fusion edge; solutioned in one spoke. |
| **#5232 → {#5278, #5282}** | **SOFT (file contention only)** | Shared files, no semantic dependency. The gate *register* and the emission *forcing function* are separable; sequencing is a merge-order convenience, not a build gate. |
| **#7392 → {#5278, #5282}** | **SOFT (file contention only)** | Shares `orchestration-playbook.md` and `hub-action-tracking.md`. Its invocation clause is authored branch-agnostically by #5278's own change, so no hunk is shared. |
| **#4027 → #4028** | **HARD (build-blocking)** | #4028's deliverable lands *inside* a file #4027 creates. The single-definition-site rule makes the rubric the only home for the seam set, and #4028 has no standalone execution surface. A spec-freeze checkpoint sits between them; it is discharged. |
| **Limb A ⟂ Limb B** | **NONE** | Set intersection of the two limbs' matrix path sets = 0. Sensitivity arm on the same instrument: the intersection *within* Limb A returns 4 shared paths and within Limb B returns 4, so the instrument finds overlaps where they exist. Specificity arm: Limb A intersected against the sibling PR's editset returns 4. No arm ran on an empty set. |

**Circular chains: zero**, over the six intra-release edges above. Sensitivity arm: adding the inverse edge `#4028 → #4027` to the same walker produces a detected 2-cycle, so the walker fires on a cycle when one exists.

### Bundle Refresh State

N/A — enumerated over the four refresh triggers: no batch of new approved theme-matching issues entered, no member's priority shifted, no dependency state changed, and the Stage-4 boundary refresh ran as Phase A0 rather than as a separate refresh. The one composition change — admitting #7392 — was an operator-settled scope extension recorded at its own gate, not a refresh outcome.

---

## Implementation Sequence

Dependency-ordered. Waves are sequencing units, not approval gates.

| # | Wave | Work | Rationale |
|---|---|---|---|
| **0** | Pre-Engineering | Operator disposition of the sibling-release serialization edge; scope-lock; the M4 control-arm design iteration | All three discharged. The serialization edge resolved to *proceed in parallel, re-baseline at Stage 9*; scope locked at the second Collective Review render; the M4 control-arm iteration precedes Engineering because the operator kept M4 **and** required its control arm first. |
| **1** | Stage 5 — wave 1 | #5232 (solo) · #5278 + #5282 (one joint spoke) · #4027 (solo) | Three parallel spokes. The joint spoke is mandated; splitting it would produce two designs on one seam. |
| **2** | Stage 5 — wave 2 | #4028 (solo), then the freeze amendment, then #7392 | #4028 serializes behind #4027 on the spec-freeze checkpoint. The freeze was re-opened once on the operator's rendered decision and re-frozen; #7392 entered as a late add behind a fresh capacity checkpoint. |
| **3** | **Stage 6 — Engineering** | **Single write-serialized spoke. Commit order: `#4027 → #4028 → #5232 → #5278 → #5282 → #7392`** | **Limb B first.** It is additive and touches nothing Limb A touches, so it lands clean and de-risks the wave. Then #5232 establishes the gate register, so the later cards' amendments cite an existing register instead of a forward reference. #5282 and #7392 land last — they are the cards most exposed to the sibling release's in-flight change. |
| **4** | Stage 7 — Dev Testing | 6 per-issue spokes | Split into batches per the Quota Budget rather than launched 6-wide. |
| **5** | Stage 8 — QA | 6 per-issue spokes | Same split. |
| **6** | Stages 9 → 13 | Release-scoped singletons | Standard tail. Stage 9 re-measures the cross-PR population and re-baselines. |

**Why #4027 leads Engineering rather than #5232.** The instinct is to lead with the largest-blast-radius card. That is wrong here: #5232 touches files a sibling release is *also* editing, so leading with it maximizes the window in which this branch and the sibling diverge on the same lines. #4027 and #4028 touch **zero** contended files. Landing Limb B first converts the release's riskiest merge surface into its last commits, where the sibling's state is best known.

**Package rebuild sequencing.** `packages/pmo-qa-auditor.skill` rebuilds **once**, after #4028's commit. `packages/release-hub.skill` rebuilds **once**, after the last Limb-A commit. Rebuilding either once per card is the shape that produces package drift, and the contention map resolves both to a single rebuild.

### Issue #4027 — the repeatable decision health-check

**Change specification.** Fill the Mode J run machinery with a frozen oracle-roster derivation predicate; author the dimension rubric's **shape** (the seam-set table contract, the coverage/grade two-axis model, the cardinality-free index formula and its sibling ceiling term, the comparability guard); retire the mode's provisioning-state declarations while **retaining** its two runtime absence guards; add the characterization-fixture families; and seed the committed decision-health summary. Seam *content* is #4028's.

**Standing constraint.** The capability derives and SHA-pins its oracle set at run time and encodes **no cardinality** in any artifact. The figure the card records is a dated anchor for its own history, never a value to encode — and the anchor decayed between filing and planning, which is the decay this capability exists to detect.

### Issue #4028 — the DS1–DS7 coverage scorecard

**Change specification.** Fill the rubric's seam rows and per-seam behavioural anchors inside the shape #4027 freezes, and emit the index each run. May not alter the identifier grammar, the two-axis separation, the coverage vocabulary and its ordered predicate, the `instrumented(s)` rule, the index formula, the ceiling term and its invariant, the comparability guard, or the cardinality-freedom constraint.

### Issues #5232 · #5278 · #5282 · #7392 — the hub gate and emission contract

**Change specification.** #5232 consolidates the hub's operator-stop enumerations into one authoritative gate register in the deployed contract and relocates the gate-eligibility precondition and its two classification inputs beside it. #5278 and #5282 give the action-item ledger a forcing function at the routing point, with a sweep whose window tiles the release rather than firing only at its own point, and an honest close-time attestation that declines to recommend where its basis cannot discriminate. #7392 gives `recommendation-choice-delta` a declared emission obligation with a conditional row derived from transition safety and a recorded promotion condition. Each card's detailed specification lives on its Stage-5 sub-task and is not restated here.

### Agent-Editability Read

**Derivation** — controls read at commit `a3083858`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — two `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`. Block 2 (repository-membership, worktree-guarded) is the operative arm for in-repo work. Tracked-index test over 2030 tracked paths: `*/OPERATIONS.md` → 2, `*/RELEASE_PROTOCOL.md` → 1, and the `CLAUDE.md` / `.claude/` arms → 0 tracked and discarded at this SHA. **Tier-0 union in repo-relative terms = those three paths.**
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — scope regex requires a path under `{operations,release,core,pmo-platform}/skills/<name>/` whose tail is `SKILL.md` or a file under `references/`; arming key present; exemption list resolved at the **deployed** path and present with one entry. Arming-key control arm: 52 skills repo-wide carry the key, so a hit on these targets is a discriminating read rather than a pattern that matches everything.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #4027 | `core/skills/pmo-qa-auditor/SKILL.md` | no | **yes** | `sanctioned-session-required` | `sanctioned-session-required` | `sanctioned-session: pmo-skill-editor Mode A` |
| #4027 | `core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md` | no | **yes** | `sanctioned-session-required` | ″ | ″ |
| #4027 | `core/skills/pmo-qa-auditor/references/decision-audit-dimension-rubric.md` | no | **yes** | `sanctioned-session-required` | ″ | ″ |
| #4027 | `core/skills/pmo-qa-auditor/evals/decision-audit-characterization-fixtures.md` | no | no — scope regex covers `references/`, not `evals/` | `unconstrained` | ″ | ordinary Engineering spoke |
| #4027 | `release/releases/decision-health-summary.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #4027 | `release/references/protocols/decision-audit-cadence.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #4027 | `packages/pmo-qa-auditor.skill` + `.sha256` | no | no | build-generated | ″ | `build-skill-packages.sh` (class of source) |
| #4028 | `core/skills/pmo-qa-auditor/references/decision-audit-dimension-rubric.md` | no | **yes** | `sanctioned-session-required` | `sanctioned-session-required` | `sanctioned-session: pmo-skill-editor Mode A` |
| #4028 | `core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md` | no | **yes** | `sanctioned-session-required` | ″ | ″ |
| #4028 | `packages/pmo-qa-auditor.skill` + `.sha256` | no | no | build-generated | ″ | `build-skill-packages.sh` (class of source) |
| #5232 | `release/skills/release-hub/SKILL.md` | no | **yes** | `sanctioned-session-required` | `sanctioned-session-required` | `sanctioned-session: pmo-skill-editor Mode A` |
| #5232 | `release/skills/release-hub/references/orchestration-playbook.md` | no | **yes** | `sanctioned-session-required` | ″ | ″ |
| #5232 | `release/skills/release-hub/references/decision-briefing.md` | no | **yes** | `sanctioned-session-required` | ″ | ″ |
| #5232 | `release/references/how-to/hub-spoke-bridge.md` | no | no — not under a skills tree | `unconstrained` | ″ | ordinary Engineering spoke |
| #5232 | `core/ADRs/ADR-053-pre-gate-eligibility-forcing-function.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #5232 | `core/disciplines/autonomous-execution-model.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #5232 | `packages/release-hub.skill` + `.sha256` | no | no | build-generated | ″ | `build-skill-packages.sh` (class of source) |
| #5278 | `release/skills/release-hub/references/orchestration-playbook.md` | no | **yes** | `sanctioned-session-required` | `sanctioned-session-required` | `sanctioned-session: pmo-skill-editor Mode A` |
| #5278 | `core/standards/hub-session-continuity.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #5278 | `core/standards/hub-action-tracking.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #5278 | `release/tools/check-event-record-integrity.sh` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #5282 | `release/references/how-to/hub-spoke-bridge.md` | no | no | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5282 | `core/standards/hub-action-tracking.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #7392 | `release/skills/release-hub/references/orchestration-playbook.md` | no | **yes** | `sanctioned-session-required` | `sanctioned-session-required` | `sanctioned-session: pmo-skill-editor Mode A` |
| #7392 | `core/standards/hub-action-tracking.md` | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #7392 | `release/references/standards/pipeline-event-log-schema.md` | no | no — second segment is `references`, not `skills` | `unconstrained` | ″ | ordinary Engineering spoke |
| #7392 | `packages/release-hub.skill` + `.sha256` | no | no | build-generated | ″ | `build-skill-packages.sh` (class of source) |

**Zero `tier-0-floored` rows.** That is the discriminating negative this section exists to produce, and the arm-level derivation above is what makes it checkable rather than assumed. Per-path rows are retained, never collapsed into the card class. Read-only inputs are excluded by construction — citing an enforcing surface is not editing it.

---

## Stage Applicability Matrix

| Stage | #4027 | #4028 | #5232 | #5278 | #5282 | #7392 | Basis |
|---|---|---|---|---|---|---|---|
| 5 Solutioning | APPLY | APPLY | APPLY | APPLY (joint) | APPLY (joint) | APPLY | Every card defers a design choice to Solutioning; none is trivial. |
| 6 Engineering | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | All six change files. |
| 7 Dev Testing | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | All six have functional impact. No skip recommended — a skip must carry its own evidence against the stage criteria, and none of the six can produce it. |
| 8 QA | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Every card carries per-criterion acceptance criteria that need grading. |
| 9 Plan Review | APPLY (release-scoped) | — | — | — | — | — | Release-scoped singleton. **GO/NO-GO is a human gate.** |
| 10 / 11 | **N/A** | **N/A** | **N/A** | **N/A** | **N/A** | **N/A** | Compress into Stage 9 and git-native mechanisms for a git-native release. No non-git deploy and no destructive operation in this release, so no compression exception activates. Both sub-tasks were closed with the Skip Closure Format posted first. |
| 12 Execute | APPLY (release-scoped) | — | — | — | — | — | **Human gate.** The atomic version claim fires here. |
| 13 Close | APPLY (release-scoped) | — | — | — | — | — | Includes the close-time action-item resolution gate — **which this release's own changes alter**; see § Risk Register. |

**Parallel-eligible spoke counts:** Stage 5 = 3 (worst wave) · Stage 7 = 6 · Stage 8 = 6.

---

## File Change Matrix

```
# ── ADD (4) ──
core/skills/pmo-qa-auditor/references/decision-audit-dimension-rubric.md      add
core/skills/pmo-qa-auditor/evals/decision-audit-characterization-fixtures.md  add
release/releases/decision-health-summary.md                                   add
release/releases/plans/hub-emits-state-gates-read_RELEASE_PLAN.md             add

# ── EDIT (17) ──
core/skills/pmo-qa-auditor/SKILL.md                                           edit
core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md             edit
release/references/protocols/decision-audit-cadence.md                        edit
release/skills/release-hub/SKILL.md                                           edit
release/skills/release-hub/references/orchestration-playbook.md               edit
release/skills/release-hub/references/decision-briefing.md                    edit
release/references/how-to/hub-spoke-bridge.md                                 edit
release/references/standards/pipeline-event-log-schema.md                     edit
release/tools/check-event-record-integrity.sh                                 edit
core/ADRs/ADR-053-pre-gate-eligibility-forcing-function.md                    edit
core/disciplines/autonomous-execution-model.md                                edit
core/standards/hub-session-continuity.md                                      edit
core/standards/hub-action-tracking.md                                         edit
packages/pmo-qa-auditor.skill                                                 edit
packages/pmo-qa-auditor.skill.sha256                                          edit
packages/release-hub.skill                                                    edit
packages/release-hub.skill.sha256                                             edit

# ── DELETE (0) ──
# none — this release declares no rename, relocation, or deletion.
```

### CONDITIONAL rows — both fired, both promoted in this commit

The Stage-4 matrix carried two `CONDITIONAL` rows whose conditions resolved at Stage 5. A fired conditional is promoted in the same commit carrying its now-concrete path; a row left `CONDITIONAL` after its condition has resolved is an authoring defect, because it is indistinguishable from a row whose condition never fired and it buys exemption from the delivery check for the price of one token.

| Stage-4 conditional | Condition | Resolved to | Effect on the matrix |
|---|---|---|---|
| `CONDITIONAL:gate-register-host` (add) — *the authoritative gate register, path named at Stage 5* | **FIRED.** #5232's design converts the playbook's existing gate-set section into a delimited gate register in place. | `release/skills/release-hub/references/orchestration-playbook.md` | **Promoted into an existing `edit` row; the `add` row retires.** No new file: the register is authored inside a file already declared. |
| `CONDITIONAL:rec-choice-delta-emitter` (edit) — *the `recommendation-choice-delta` emitter, home identified at Stage 5* | **FIRED.** #7392's design places the obligation row inside the playbook's emission-contract block and its schema declaration in the event-log schema. | `release/skills/release-hub/references/orchestration-playbook.md` (already declared) **+** `release/references/standards/pipeline-event-log-schema.md` | **Promoted; one new concrete `edit` row** for the schema file, which the Stage-4 late-add editability addendum already classified. |

**Matrix arithmetic against the Stage-4 baseline, stated so the delta is checkable rather than asserted.** Stage-4 declared **20** rows (5 add = 4 concrete + 1 conditional; 15 edit = 14 concrete + 1 conditional). Live: add 5 − 1 (the conditional retires into an existing edit row) = **4**; edit 15 − 1 (the conditional retires) + 1 (`pipeline-event-log-schema.md`, its resolution) + 1 (`decision-audit-cadence.md`, the operator's retirement-site decision) + 1 (`check-event-record-integrity.sh`, the operator's decision to keep the population screen) = **17**. Total **21**, a net **+1** against the Stage-4 baseline with **zero files added** beyond the Stage-4 add set. This reproduces the net the operator rendered at the second Collective Review, arrived at independently from the row set rather than transcribed as a figure.

### New-executable companion obligations

**N/A — enumerated over all 21 add/edit rows.** Exactly one row is a `*.sh` path, `release/tools/check-event-record-integrity.sh`, and it is an **`edit`** of a file already tracked at `origin/main` rather than an `add`. The obligation fires on an `add` row for a tracked executable, so it does not fire here; and the companion is in any case already discharged — that script already carries its four invocation forms in `core/config/allowlists/script-execution-allowlist.txt` (bracket-token, worktree-glob, dot-relative, and bare repo-relative). The enumeration is stated rather than the bare N/A, so a reader can see which population was walked and why the one candidate row does not qualify.

### Read-only inputs

```
release/skills/release-executor/SKILL.md                                      READ
release/skills/release-hub/SKILL.md                                           READ  (as an oracle source for #4027, distinct from #5232's edit)
core/schemas/per-skill-output-contracts.md                                    READ
core/disciplines/architecture-overview.md                                     READ
core/ADRs/ADR-103-decision-audit-host-qa-auditor-mode-j.md                    READ
release/ADRs/ADR-197-action-item-status-classified-by-membership.md           READ
core/standards/hub-action-tracking.md                                         READ  (as a governing rule for #4027, distinct from #5282/#7392's edit)
core/deploy/deploy.sh                                                         READ  (the release-skill roster the oracle predicate resolves against)
core/hooks/block-autonomy-ceiling.sh                                          READ
core/hooks/block-skill-direct-edit.sh                                         READ
```

### Release-wide explicit non-scope

```
core/governance/OPERATIONS.md                                                 NOT EDITED
operations/OPERATIONS.md                                                      NOT EDITED
release/governance/RELEASE_PROTOCOL.md                                        NOT EDITED
core/CLAUDE.md.template                                                       NOT EDITED
core/skills/pmo-qa-auditor/references/architecture-conformance-dimension-rubric.md  NOT EDITED
release/releases/architecture-conformance-summary.md                          NOT EDITED
```

The first four are the repo-tracked members of the Tier-0 floor union plus the charter template: naming them out of scope is what makes the *zero `tier-0-floored` rows* claim in § Agent-Editability Read checkable. The last two are the sibling audit mode's own rubric and summary — named because this release models three new artifacts on them and a reader could reasonably expect them to be touched; they are precedents to follow, not surfaces to edit, and a second producer writing the sibling summary would destroy that mode's single-record.

---

## Contention Map

### Within-release contention

| File | Claimants | Intent | Resolution |
|---|---|---|---|
| `core/skills/pmo-qa-auditor/references/decision-audit-dimension-rubric.md` | #4027 (add), #4028 (edit) | add / edit | **Producer-consumer, by design.** #4027 creates the file's shape; #4028 fills its content. The spec-freeze checkpoint sits between them and is discharged. This is the hard edge, not a collision. |
| `core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md` | #4027, #4028 | edit / edit | Sequence #4027 → #4028. |
| `core/skills/pmo-qa-auditor/SKILL.md` | #4027 | edit | Single claimant. |
| `release/skills/release-hub/references/orchestration-playbook.md` | #5232 (gate register), #5278 (the sweep subsection), #7392 (one emission-contract row) | edit ×3 | **Disjoint regions.** Sequence #5232 → #5278 → #7392 in the commit order. #7392's row lands inside the emission-contract delimiters; #5232's register replaces the gate-set section above them. |
| `release/references/how-to/hub-spoke-bridge.md` | #5232, #5282 | edit / edit | **Disjoint sections.** Sequence #5232 → #5282. Graded post-merge by CIAC-4. |
| `core/standards/hub-action-tracking.md` | #5278, #5282, #7392 | edit ×3 | Sequence #5278 → #5282 → #7392. #5278 and #5282 are one joint design; #7392 inherits the same subsection with both branches already written. |
| `packages/pmo-qa-auditor.skill` + `.sha256` | #4027, #4028 | build-generated | **Rebuild ONCE after #4028's commit**, not per card. |
| `packages/release-hub.skill` + `.sha256` | #5232, #5278, #5282, #7392 | build-generated | **Rebuild ONCE after the last Limb-A commit**, not per card. Sequential rebuilds of one package is the shape that produces package drift. |

No file requires a scope split. Every within-release contention resolves by commit ordering.

### Cross-PR Overlap Audit

**Baseline SHA:** `a3083858`.

#### In-Flight Release Roster

**Measured at:** `a3083858` · `2026-09-10T13:20:00Z` (Stage-4 audit start) · **Population:** n=**1** sibling.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `closeout-correctness-batch` | `#7253` (draft) | `284d5cc3` | `minor` | `v4.61` | `v4.61` | `release/references/how-to/hub-spoke-bridge.md` · `release/skills/release-hub/references/orchestration-playbook.md` · `core/standards/hub-action-tracking.md` · `packages/release-hub.skill` · `packages/release-hub.skill.sha256` |

**The roster is a pinned measurement and carries no verdict.** It is Stage-9's baseline input, never its substitute; that phase re-measures fresh pre-GO and renders the contention verdict. **Its population was already known to be understated when it was taken**, and the understatement is recorded rather than buried: the open-PR-plus-remote-head derivation is structurally blind to a release still at Stage 4, which has neither branch nor PR, and the hub's own read at the same instant found four further milestones in flight. At Commit 0 four of those have branched and opened draft PRs, so the live sibling population is **five** — enumerated in § Commit-0 Version Re-Verify Record. The Stage-4 row is left as the measurement it was, at the SHA and instant it was taken.

**`overlap_class` per contended file:** `core/standards/hub-action-tracking.md`, `release/references/how-to/hub-spoke-bridge.md` and `release/skills/release-hub/references/orchestration-playbook.md` are each `line-range-overlap` — adjacent prose edits in one file from two releases. The two `packages/release-hub.skill` artifacts are a guaranteed binary collision, resolved only by rebuilding after the merge and never by hand-resolving the artifact. `release/skills/release-executor/SKILL.md` is `read-edit` — not a merge conflict but an oracle-set drift exposure, and the case that proves the content-hash pin does the work the anti-hardcode rule alone cannot.

**Structural-blast-radius sub-audit.** This release's mover-set is **empty** — 21 matrix rows, zero renames, relocations or deletions. Sensitivity arm: the same classifier applied to a corpus-reorg window returns non-empty rename and delete rows, so the empty result is a property of this matrix and not of the classifier. With an empty mover-set no sibling can intersect this release via the mover axis, which is exactly why the direct editset intersection and the version-slot token were computed separately rather than inferred from a mover sweep returning nothing.

**Baseline-pin temporal limitation, stated rather than buried.** This audit is pinned at `a3083858` and the sibling is a draft that may merge at any time before Stage 9. Because it will change files this release edits, the stale-pin self-invalidation trigger **is expected to fire at Stage 9 entry** — a prediction this plan makes, not a residual it hopes against.

#### Re-baseline re-measurement — the sibling merged before Stage 9

**Measured at:** `origin/main` @ `ea424cc1` · release head `65f2dd6c` (the post-merge head, before this subsection's commit) · open-PR population read at `2026-09-11T21:43:20Z`. The prediction above held, one stage early. The sibling merged during Stage 6, and the operator decided to re-baseline the branch at Stage 6 so that the last card builds on post-merge `main`. The Stage-4 roster above is left as the measurement it was, on the reasoning DEV-10 records.

**What `main` carried in.** The re-baseline merged two first-parent merges into this branch:
- `closeout-correctness-batch`, merged as `b255f99a` and claimed as `v4.63`. Its net change is **22** files. **6** are in this release's write set and **3** are in its read set.
- A `v4.62` Stage-13 corpus chore, `ea424cc1`. Its net change is **7** release-corpus files. **0** are in this release's write set.

`release/tools/automated-closeout.sh` was not in the Stage-4 intersection. It is not among the § File Change Matrix rows; it entered this release's change set with the close-time measurement commit.

| File | Class | Resolution |
|---|---|---|
| `release/references/how-to/hub-spoke-bridge.md` | `line-range-overlap` — **conflicted, 1 region** | An adjacency conflict in the § Procedure 7a decision table. Rows 1–2 come from this branch. Rows 3–5, and the two paragraphs after the table, come from `main`. No row was edited by both sides, and the result equals the line-level union of both. **INT-2 MET.** Control: resolving the conflict to the sibling's side alone is NOT MET on the rows-1–2 check. |
| `release/tools/automated-closeout.sh` | `line-range-overlap` — **conflicted, 2 regions** | The self-test fixture reset is a union: this branch's reader restore, plus every `STATE_AI_*` reset either side carries. The claim lines take `main`'s witness-gated form. Self-test group M (five arms) is registered with the witness gates in its own commit. At the pure-merge commit, disabling one M arm left the suite green, with stderr byte-identical to a healthy run. After registration, the same mutation fails and names group M. |
| `core/standards/hub-action-tracking.md` | `line-range-overlap` — auto-merged | A line-level union with no overlapping hunk. **INT-3 MET**: the § 4 routing-point-5 row is `main`'s text, the Composition block carries this release's sweep subsection byte-identical, and neither states a gate-state count the other contradicts. |
| `release/skills/release-hub/references/orchestration-playbook.md` | `line-range-overlap` — auto-merged | A line-level union with no overlapping hunk and no hand-edit. The `EMISSION-CONTRACT` block holds **18** data rows before and after, byte-identical. The Procedure 4a step-5 sweep binding is intact. |
| `packages/release-hub.skill` + `.sha256` | binary | Taken from `main`, the sibling's build, and never hand-resolved. The package stays stale against this branch's source until the release's single rebuild from post-merge source, which is the last Limb-A card's. |
| `release/skills/release-executor/SKILL.md` | `read-edit` | The decision health-check's oracle source changed under it, as RSK-7 predicted. No committed artifact of this release pins its content hash, because the pin is taken at run time, so there is nothing to reconcile. |
| `release/ADRs/ADR-197-action-item-status-classified-by-membership.md` | `read-edit` (renumbered) | The sibling renumbered its membership record at its version claim. The § Read-only inputs row now points at the post-claim path, found by slug. |

**Open-PR population: 4.** GraphQL `totalCount` reads 4 and the list read returns 4. Each PR's file list matches the host's `changed_files` count, so no list is truncated. One of the four is this release's own PR. The other three were checked against this release's write set and its read set:

| In-flight PR | Files | ∩ write set | ∩ read set |
|---|---|---|---|
| `deploy-tools-and-tests-batch` | 23 | **0** | **0** |
| `authoring-bar-and-consumers` | 16 | **0** | **0** |
| `chore/v4.63-stage-12-release-log` | 2 | **0** | **0** |

The **write set** is **33** paths. It is the union of the branch's net change against `main` (29 paths) and the plan's declared add/edit rows, including DEV-15 (24 paths). The union keeps rows that are planned but not yet landed in scope: the event-log schema file and the `release-hub` package pair. Method: `LC_ALL=C sort -u` into `comm -12`, never `sort -n`. **Planted-path control, same pipeline:** one write-set path appended to a real PR's file list is reported, count 1, so each zero above is a measured zero. Specificity: three paths outside the write set return 0.

**Version slot.** `v4.61`, `v4.62` and `v4.63` are tagged on `origin`; the sibling holds `v4.63`. The next free version for bump-class `minor` reads `v4.64` at this measurement. As before, it binds only at the Stage-12 atomic claim, and nothing in this plan is restamped.

---

## Risk Register

| ID | Risk | Class | Likelihood | Impact | Reversibility | Mitigation |
|---|---|---|---|---|---|---|
| **RSK-1** | The sibling release merges mid-pipeline; this branch diverges on five files including a built package | dependency / contention | **HIGH** | Merge conflict at Stage 12; worst case a silently wrong standard after resolution | MODERATE | Operator-dispositioned: proceed in parallel, re-baseline at Stage 9 (the trigger fires anyway), rebuild the package **after** the merge, never resolve the artifact by hand. |
| **RSK-2** | #5282's fix is designed against a gate predicate the sibling's ADR replaces | dependency (semantic) | **HIGH** | A forcing function keyed to a predicate that no longer exists | MODERATE | That ADR was made a **mandatory** Stage-5 input for the joint spoke rather than advisory, and was read at the sibling head. |
| **RSK-3** | #5278's premise is mis-aimed; the fix targets a surface that is absent *by design* | scope | **MEDIUM** | A shipped detector that fires on correct behaviour — the worst outcome for a gate-efficacy card | MODERATE | Settled at Stage 5 before anything was designed. Lazy creation is correct, so the card narrowed to the detection limb. |
| **RSK-4** | #4027 or #4028 bakes a frozen oracle cardinality into an artifact | scope / decay | **MEDIUM** — the card's own history shows the pull | The capability inherits the exact decay it exists to detect | CHEAP at design time, EXPENSIVE once shipped | CIAC-3 grades it at Stage 9 with a mandatory seeded control. The dated anchor is recorded in prose and encoded nowhere. |
| **RSK-5** | #5232's consolidation lands one *more* enumeration instead of collapsing the existing ones | scope | MEDIUM | The card's own defect, reproduced by its fix | CHEAP | CIAC-1 grades the count post-merge against a control arm that returns the pre-state. |
| **RSK-6** | This release edits the close-time gate that its own Stage 13 must pass | reflexive / rollback | MEDIUM | Close-out runs against a gate this release just changed | MODERATE | Resolved by the **warn-mode cutover freeze**: the obligation is in force from the merge because the standard loads from the repo tree rather than from a package, and warn-mode is what makes that window survivable — an omission is reported, not blocked. The posture decision is carried as an open action item to the Stage-9 briefing. |
| **RSK-7** | The oracle source changes under #4027 between design and run | dependency (soft) | MEDIUM | The oracle set shifts | CHEAP | This is what the run-time derivation requirement is for, and it is **re-aimed by measurement**: the sibling changes that file's *content* at constant entry count and an identical entry-title set, so a cardinality-only pin would report "no drift" and be wrong. The **content-hash half** of the pin is what closes this risk. |
| **RSK-8** | Sequential rebuilds of one package across a limb | contention | MEDIUM | Package drift against the source baseline | CHEAP | Rebuild once per package, after the last commit of its limb. Explicit in the Implementation Sequence. |
| **RSK-9** | Wide Stage 7/8 batches against a partially-drawn usage window | capacity | MEDIUM | Batch deferral mid-stage | CHEAP | Split the batches per the Quota Budget. The runtime capacity checkpoint is the load-bearing gate at every launch. |
| **RSK-10** | The version slot is claimed by one of five in-flight siblings before this release reaches Stage 12 | contention (version) | **MEDIUM–HIGH** | The provisional display value copied into sub-task bodies and chip prompts goes stale | CHEAP | Architecturally arbitrated: the number binds only at the atomic compare-and-swap, the loser recomputes upward with no rework, and the branch and plan-file names are slug-primary so nothing renames. Recorded because a plan silently carrying the provisional value as if uncontested would mislead every downstream reader. |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential (dependency-ordered), single write-serialized spoke chain |
| **Commit strategy** | One or more coherent commits per card, in the Implementation-Sequence order, each message prefixed `hub-emits-state-gates-read:` |
| **Review approach** | Single PR for the entire release, opened **draft** at Commit 0 so CI runs while later cards land; transitioned to ready-for-review at the Stage-9 gate |
| **Deployment mechanism** | Git merge + direct skill-file copy + manifest execution |
| **Stacked-base cleanup posture** | N/A — no stacked-base waves are planned; the release is a single branch off `main` |

---

## Verification Plan

### Per-Issue Verification

One row per acceptance criterion, in the criterion list's order. The `AC` cell holds the identifier only; the method cell carries a reproducible probe, never a restatement of the criterion.

| Issue | AC | Verification Method | Expected Result |
|-------|----|--------------------|-----------------|
| #4027 | AC-1 | Run Mode J on-command against a resolved version window; inspect the emitted deliverable set and the scorecard in the run's analysis folder | The six-deliverable set and the coverage scorecard are present, and the run's oracle pin records path, content hash, entry count, entry-title set and roster membership per source |
| #4027 | AC-2 | Read the cadence protocol; assert a cadence statement and a 90-day sentinel are present and mirror the sibling audit cadences in shape | Both present; the provisioning note is retired and no citation dangles to a removed section |
| #4027 | AC-3 | Re-run Mode J against the same window anchors and compare the emitted findings against the first run's | The finding set reproduces. **`[DEFERRED — graded at Stage 8]`** for the comparison against the original spike's findings: that artifact is operator-instance-resident and unreadable from a fresh clone, which is precisely why this release lands a *tracked* summary to give the criterion a tracked oracle |
| #4028 | AC-1 | Extract the per-seam coverage state, grade and index from one run's output; assert every rubric seam is present and that no non-graded seam carries a grade | Every seam appears with a coverage state; only `measured` seams carry a grade; the index and the instrumentation ceiling both render, with `coverage_index ≤ instrumentation_ceiling` |
| #4028 | AC-2 | Compare two runs' indices across a window boundary with the seam-id set unchanged | The indices are comparable and the distribution renders alongside. A changed seam-id set renders `re-based` rather than trending across the discontinuity |
| #5232 | AC-1 | Re-run the corpus gate-enumeration probe over the hub skill tree, the how-to directory, the disciplines directory and the ADR corpus, counting surfaces that *enumerate* rather than *cite* | Exactly **1** definitional source · control: the identical probe at `a3083858` → **6** enumerating surfaces |
| #5232 | AC-2 | Read the register; assert every entry names the acting party and states stop-versus-execute | No entry is actor-less; the previously-passive scaffold entry resolves to one or the other |
| #5232 | AC-3 | Read the engagement contract as it exists in the **deployed** skill; assert the gate-eligibility precondition is present there | Present in the deployed contract, not only in an out-of-tree file |
| #5232 | AC-4 | Resolve every relative reference cited by the deployed release-hub skill from the deployed skill root, and read the committed target → class → justification classification table | **Zero** fail to resolve · control, same instrument and target: a deliberately-broken reference introduced into the same tree **is** reported. The classification table is required because a zero is satisfied identically by a correct triage and a wrong one, and the link checker cannot see a backticked runtime-load path |
| #5232 | AC-5 | Read the engagement contract's case taxonomy | The briefed-but-unprompted case is present and typed as a defect; it is absent at `a3083858` |
| #5232 | AC-6 | Introduce an unresolvable deployed-skill reference and confirm the automated check surface reports it | The check surface reports it. **`[DEFERRED — mechanism was a Solutioning determination; graded at Stage 8 against the mechanism the design selected]`** |
| #5278 | AC-1 | Read both emitters; assert a written finding stating whether the two empty surfaces share a root cause | The determination is written down, either way — the criterion is discharged by a recorded finding, not by a particular answer |
| #5278 | AC-2 | Exercise a run that emits decision-class events with no hub-state directory | The condition is reported rather than passing silently |
| #5278 | AC-3 | Read the close-time gate spec; assert the two causes are distinguished | *No ledger and none was owed* and *no ledger but decisions were emitted* are separately named, and the instrument declines to recommend a cause where its basis cannot discriminate |
| #5278 | AC-4 | Run a release that renders no durable commitment | **No ledger is created** · control, same instrument and target: a run that *does* render a commitment creates one, so the absence is lazy creation working rather than a write that failed |
| #5282 | AC-1 | Grade three worked scenarios — a deferred edit, a finding routed to a follow-up card, and a verification owed later | All three classify decidably · control: a deliberately-ambiguous fourth scenario is classified as ambiguous rather than forced |
| #5282 | AC-2 | Run a release scenario carrying a durable commitment and no ledger row | The gap is reported before close |
| #5282 | AC-3 | Exercise the gate against populated, empty and absent ledgers | Three distinct outcomes · control: the populated arm returns the populated verdict, so the three-way split is a real discrimination rather than a single path |
| #5282 | AC-4 | Read the standard; assert the release-shape conclusion is recorded either way | The conclusion is stated in the standard, not left implicit |
| #7392 | AC-1 | Parse the emission-contract block between its delimiters; assert a row for this subtype naming its gate, actor and obligation class | The row is present and the block holds one more data row than at `a3083858` · control: the pre-existing rows parse at their recorded count, so the increment is measured rather than assumed |
| #7392 | AC-2 | Read the amended procedure; assert the trigger fires at an observable routing point rather than at the decision moment | The obligation is stated at the routing point, and the sweep's window covers this routing point **and** every preceding routing point of the release at which no sweep was rendered |
| #7392 | AC-3 | Exercise a routing point where the rendered choice differs from the recommendation | A delta row is produced |
| #7392 | AC-4 | Assert the sweep subsection has exactly one definitional site and that this subtype reuses it | One definitional site; the invocation clause is branch-agnostic, so it reaches every branch by construction |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit read against:

`ac_baseline: { #4027: 3, #4028: 2, #5232: 6, #5278: 4, #5282: 4, #7392: 4, read_at: a3083858 }`

This is a pinned measurement and carries no verdict. A count that no longer matches at Stage 7/8 is a mechanical signal to re-bind the ordinals, not a failure. **One measurement note, recorded because a reader reproducing it will hit the same thing:** #5232 states its criteria as a **numbered** list rather than a checkbox list, so a checkbox-only extractor returns zero on that card while returning correct counts on the other five. The ordinal is the position in the criterion list whatever its marker shape; the count of 6 is read from the numbered list and matches the Stage-4 baseline.

**Null-result arms.** Every row above whose expected result is a null carries a control arm run on the **same instrument against the same target**, stated inline. Recorded honestly: this is an **authoring convention with no executor behind it** — the executor that grades per-issue rows receives the expected-result cell and does not read it, so a conforming control arm, a fabricated one, and no arm at all produce the same verdict. These arms are what a human reviewer checks. Do not cite their presence as evidence that a null verdict *was* checked.

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation
- [ ] Output Contract Compliance

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**

- [ ] **CIAC-1 (#5232 × #5278 × #5282 × #7392 on the hub gate/emission contract):** after the merge, exactly one artifact in the corpus *defines* the hub's operator-stop points, and every surface amended by the other cards that names a gate **cites** that definition rather than carrying its own list — so the emission amendments do not become one more enumeration. *Shared surface:* the authoritative gate register in the deployed contract, plus `orchestration-playbook.md`, `hub-spoke-bridge.md`, `decision-briefing.md`. *Method:* `python3` re-run of the Stage-4 enumeration probe over `release/skills/release-hub/`, `release/references/how-to/`, `core/disciplines/` and `core/ADRs/`, counting surfaces that enumerate rather than cite; expect exactly 1 definitional source. **Control arm, same instrument and target:** the identical probe against `a3083858` returns **6** enumerating surfaces. *Graded at Stage 9 on the merged PR.*

- [ ] **CIAC-2 (#4027 × #4028 on the dimension rubric):** every `DS`-prefixed seam identifier the Mode J run machinery emits appears in the rubric's seam set, and every seam in the rubric is emitted — set equality, not overlap. *Shared surface:* the rubric file, the single definition site. *Method:* extract the seam-identifier set with the **unbounded** pattern `DS\d+` from `decision-audit-mode-spec.md` and from `decision-audit-dimension-rubric.md` with `python3`; assert the two sets are equal and both non-empty. **The extractor is deliberately unbounded:** a bounded pattern is a frozen cardinality living inside the gate that polices frozen cardinalities, and under it a seam outside the bound is invisible to *both* extractions, so set equality reads MET over two truncated sets. *Graded at Stage 9 on the merged PR.*

- [ ] **CIAC-3 (#4027 × #4028 on the oracle-cardinality anti-hardcode requirement):** **no** line this release adds under `core/skills/pmo-qa-auditor/` carries a frozen oracle cardinality. *Shared surface:* `decision-audit-mode-spec.md`, `decision-audit-dimension-rubric.md`, `pmo-qa-auditor/SKILL.md`, `decision-audit-characterization-fixtures.md`. *Method:* `python3` scan of the **added lines** of those four files in this release's diff for an integer adjacent to `oracle` or `seam`, **excluding the `DS<n>` identifier token class**; expect **zero**. **Mandatory seeded control, same instrument and target:** an added line reading `7 seams is the reconciled set` must make this criterion grade NOT MET. A run reporting zero without that control arm having fired is a broken probe, not a pass. *Graded at Stage 9 on the merged PR.*

- [ ] **CIAC-4 (#5232 × #5282 on `hub-spoke-bridge.md`):** the merged file carries exactly one gate-eligibility statement and exactly one close-time gate description — the two cards edit the same file in adjacent regions and must not each leave a copy. *Shared surface:* `release/references/how-to/hub-spoke-bridge.md`. *Method:* count occurrences of the eligibility definitional block and of the close-time gate-description block in the merged file; expect 1 and 1. **Control arm:** the same counter against `a3083858` returns 1 and 1, establishing the pre-state, so a post-merge 2 is attributable to this release. *Graded at Stage 9 on the merged PR.*

**Why CIAC-3's scope is added-lines-only, stated because the change is not cosmetic.** The Stage-4 method scanned the four files whole and expected zero. Measured against the criterion's own stated shape — a quantity within three words of the nouns — `pmo-qa-auditor/SKILL.md` returns **7** matches at `a3083858`, over 1770 lines: three genuine set cardinalities belonging to a *different* mode's detector battery, and four structural identifier-adjacency matches. The instrument is sound — the same scan returns **0** on two real sibling files and **0** on a fabricated noun, so 7 is discrimination and not saturation. The consequence is that the whole-file criterion **grades NOT MET on the merged tree for reasons wholly unrelated to this release.** Of the three available corrections, an enumerated exemption leaves four matches behind and narrowing the nouns leaves two; only added-lines scoping closes it, and it is the posture the repository's reference-durability gate already uses. The noun set drops the bare `failure mode` in the same change, because the shipped anti-hardcode rule's subject is **oracle** cardinality at every site that states it and that noun belongs to the other mode; `seam` is carried as **this release's own added constraint**, stated as such rather than attributed to the shipped rule.

---

## Quota Budget

**Verdict:** **WARN**
**Parallel-eligible spokes per parallel stage:** Stage 5: **3** · Stage 7: **6** · Stage 8: **6**
**Per-spoke cost estimate:** size-bucket ordinal band; no telemetry medians available, so the per-bucket cutover conditions are not met. Worst batch composition = 2 × `size:L` + 1 × `size:M` + 3 × `size:S`.
**Assumed/stated remaining usage-window envelope:** **`partial`** (~half drawn) — stated by the operator at the plan-approval gate. The Stage-4 field read `UNSTATED` and the conservative default applied; the operator's statement supersedes it and is recorded here rather than leaving the stale token.
**Estimated cumulative draw % (worst parallel batch):** `[ASSUMPTION – CONFIRM]` a large-weighted six-wide batch projects into the **50–80 %** band against a `partial` envelope. This is a projection of a stated band, never a measurement; no instrument for this axis is readable from inside a session.
**Routing:** **WARN → window-aware launch timing + batch splitting.** Split the Stage 7 and Stage 8 batches rather than launching six-wide; the Engineering commit order already groups them by limb. Stage 5's worst wave was 3 and needed no split.
**Note:** the runtime capacity checkpoint re-validates at every spoke launch — wave or singleton, every stage — and gates on a second axis this section deliberately does not carry, the host-API quota read at runtime and combined deferral-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time.

---

## Release Class declaration

**Class: `novel`** — rendered by the operator at the Stage-4 plan-approval gate, concurring with the milestone's standing declaration and the platform default.

| Class | Trigger | Fires? | Evidence |
|---|---|---|---|
| `routine` | all issues low-priority **and** small | **NO** | two members are `size:L` |
| `routine` | executable from precedent | **NO** | four of six members defer a design choice to Solutioning |
| `routine` | zero new files added | **NO** | three new files |
| `novel` | ≥1 member introduces a new reference doc, schema, or definition site | **YES** | the dimension rubric is a **new definition site**, not an amendment to one; the committed summary and the fixture file are both net-new surfaces |
| `novel` | a structural first rather than a correction | **YES** | #5232 establishes an authoritative register where six divergent enumerations exist |
| `cross-cutting` | ≥3 pipeline stage specs declared as changes | **NO** | zero |
| `cross-cutting` | ≥3 of the rule-defining surfaces | **NO** | the blast radius is two skills and their governing standards; the mover-set is empty and no reorg is involved |
| `hotfix` | production incident / expedited path | **NO** | neither |

**Differentiation posture:** full Stage-9 review depth and higher engagement density — consistent with no stage skips and four Cross-Issue Acceptance Criteria.

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|---|---|---|
| #4027 | `git revert` the card's commits; the three added files disappear with them | Low — additive, zero contended files |
| #4028 | Forward fix preferred (its content lands inside a file #4027 creates) | Low–Medium |
| #5232 | `git revert` the card's commits, then rebuild `packages/release-hub.skill` from the reverted source | Medium — six surfaces, one of them the deployed contract |
| #5278 · #5282 | Forward fix preferred (one solution seam, entangled by construction) | Medium |
| #7392 | `git revert` the card's commits; the emission-contract block returns to its prior row set | Low |

### Whole-Release Rollback

Single PR, single merge, so whole-release rollback is a single `git revert -m 1` of the merge commit. Three qualifications:

1. **The version tag is retained and recorded, never deleted.** A rollback records the withdrawal; it does not erase the claim. Version tags are host-protected and the delete is rejected for every account.
2. **The two `packages/*.skill` artifacts are rebuilt from the reverted source**, not reverted independently, or the package and source hashes diverge and the freshness gate turns red on a tree that is otherwise correct.
3. **A revert restores the prior close-time gate text**, which is the correct outcome and is also why the reflexive risk matters — the close-out that runs *before* any rollback decision will already have used the new gate. The warn-mode cutover is what keeps that survivable.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/skills/pmo-qa-auditor/` (SKILL.md + `references/` + `evals/`) | the installed skill path | direct copy via the deploy script | `diff` shows no differences; the package content baseline reconciles |
| 2 | `release/skills/release-hub/` (SKILL.md + `references/`) | the installed skill path | direct copy via the deploy script | as above |

### Schema Migrations

N/A — enumerated over the classes that could produce one: no data schema changes shape, no identifier is renumbered, no stored artifact changes format, and the one schema *file* this release edits gains a declaration row without altering any existing row's shape. Nothing requires a migration of stored state.

---

## Deviation Log

| # | Deviation from the Stage-4 transcription source | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The milestone carries six members, not five.** The Stage-4 plan was authored against a five-card operator-locked composition; #7392 was admitted afterwards. | Operator-settled scope extension, with the late-add editability addendum posted to the Stage-4 plan before its sub-tasks were stamped | **RATIFIED before Engineering.** Carried into every release-scoped section of this file. The Stage-4 comment plus its addendum are the transcription source; this file is the single record from Commit 0 forward. |
| **DEV-2** | **The M4 population screen stays in scope.** The consolidated Amendment Pass recommended deferring it and declared its removal the release's only matrix delta. | Operator decision at the second Collective Review render | **OPERATOR DECISION — diverges from the amendment's recommendation.** M4 ships only once its re-entry conditions are met: a two-arm fixture on the note text with a computed denominator, and a lifecycle partition placing in-flight slugs in a separate not-yet-assessable bucket. The control-arm design iteration therefore **precedes** Engineering rather than running alongside it. Scope is locked either way — this is a design refinement inside locked scope. |
| **DEV-3** | **`release/references/protocols/decision-audit-cadence.md` moves from a `READ` row to an `edit` row.** The Stage-4 matrix listed it read-only. | Operator decision at the second Collective Review render | **RATIFIED.** The file genuinely gets edited — retiring the mode-spec's provisioning section without retiring the cadence protocol's citation of it would leave a dangling pointer to a removed section. The alternative offered, retaining the cited section as a stub, was declined: it would leave live text existing only to be pointed at. This is the **+1** in the matrix delta. |
| **DEV-4** | **Both Stage-4 `CONDITIONAL` matrix rows are promoted to concrete paths in this commit.** | The Stage-4 File-Change-Matrix authoring contract: a fired conditional is promoted in the same commit, carrying its now-concrete path | **PROMOTED, with the accounting shown.** Both conditions fired at Stage 5. The gate-register host resolved into a file already declared, so its `add` row retires with no new file; the emitter home resolved into that same file plus one new concrete `edit` row. § File Change Matrix carries the row-by-row arithmetic. A row left `CONDITIONAL` after its condition resolved buys exemption from the delivery check for the price of one token, which is why this is done at Commit 0 rather than deferred. |
| **DEV-5** | **The frozen rubric shape was re-opened once and re-frozen.** #4027's Stage-5 design froze six properties; the operator re-opened the coverage axis for a third value, and the amendment that delivered it also widened the coverage-assignment predicate. | Operator decision at the Stage-5 wave-2a gate, ratified at the amendment gate | **RATIFIED.** The predicate widening was **declared rather than slid in**: delivering the third value correctly required it, because the *instrumented, occasions-owed, zero-rows* state otherwise has no home that reads correctly and both naive homes read benign for the audit's most actionable finding. The index is numerically invariant across the amendment, enumerated over every reachable seam state, so run 1 cannot read as a regression. |
| **DEV-6** | **The re-freeze was itself re-opened on four items**, all of them machinery the freeze amendment added rather than properties the original freeze set. | Consolidated Amendment Pass, ratified at the second Collective Review render | **RATIFIED.** The ceiling term is redefined on the instrumentation predicate so it carries no window term, and its relation to the index is restated as a **detector** rather than an invariant — a run observing the inequality violated has found evidence from an undeclared producer, which is a finding worth surfacing. The instrumentation predicate's second limb becomes a **declared-producer** test resolved against two independently-maintained surfaces. Its retrievability qualifier moves from the numerator, where it patched a broken predicate, to the denominator, where it is load-bearing. Net clause count: zero. |
| **DEV-7** | **The cardinality-freedom constraint's scope is narrowed and re-attributed.** #4027's design carried it as a local election on one file. | Consolidated Amendment Pass, ratified at the second Collective Review render | **RATIFIED.** It is a shipped standing rule stated at five sites, all broader than one file, so it is restated at its **shipped scope** across every artifact this release touches under the audit skill — not row 1 only. Two refinements ride with it: the shipped rule's subject is **oracle** cardinality and does not reach `seam`, which this release carries as its **own** added constraint stated as such; and the digit clause is scoped to **bare cardinality integers**, with predicate comparators and quantifiers exempt, because the absolute form was unsatisfiable by the same handoff's own mandated content. |
| **DEV-8** | **Two identifier riders are adopted.** | Consolidated Amendment Pass riders, ratified at the second Collective Review render | **RATIFIED.** Seam-id **contiguity is dropped and no-reuse kept** — the two together have no satisfying assignment once a seam is retired, which the governing cadence protocol expressly permits, and the downstream machinery consumes only set membership, never the ordinal. CIAC-2's extractor becomes **unbounded**. Both are one-line corrections that become MODERATE once the seams are authored. |
| **DEV-9** | **CIAC-3's method is re-specified**, from a whole-file scan of four files to an added-lines scan with a narrowed noun set, an excluded identifier token class, and a mandatory seeded control. | Consolidated Amendment Pass (Theme 3), ratified at the second Collective Review render | **RATIFIED, and the re-specification changed which fix survives.** The criterion's own stated shape returns 7 matches on one of its declared files for pre-existing reasons, so the Stage-4 form graded NOT MET on any merged tree. The rationale and the measurement are carried under § Cross-Issue Acceptance Criteria rather than only here, because a reader grading the criterion needs them at the criterion. |
| **DEV-10** | **The Stage-4 In-Flight Release Roster's population of n=1 understated the field at the instant it was taken, and understates it further at Commit 0.** | Hub divergence recorded at the Procedure-0 gate; re-measured at Commit 0 | **RECORDED, not restated.** The Stage-4 row is left as the measurement it was, at the SHA and instant it was taken; the live population of five is recorded in § Commit-0 Version Re-Verify Record with the reason the Stage-4 derivation is structurally blind to a release still at Stage 4. Re-writing the pinned row would destroy the prior Stage 9 needs to diff against. |
| **DEV-11** | **`${AUDIT_DATE_UTC}` is deliberately NOT resolved at Commit 0**, against the date-variable convention's stated default. | #4027's Stage-5 design, recorded explicitly so the default is not applied mechanically against the spec's intent | **DECLARED.** The token is runtime-resolved and must appear literally in every artifact this release adds under the audit skill, because the folder it anchors is produced by each run rather than authored once. A resolved date written into a spec is a defect by the shipped spec's own words. The Commit-0 UTC date is recorded in § Commit-0 Version Re-Verify Record as provenance only. |
| **DEV-12** | **The Quota Budget's envelope field moves from `UNSTATED` to `partial`.** | Operator statement at the plan-approval gate | **RATIFIED.** The Stage-4 field recorded the refuse-to-synthesize token because no band had been captured; the operator then stated one. The verdict stays **WARN** and the batch split stands. |
| **DEV-13** | **No new ADR is authored for the coverage-axis canonicalization.** The question was deferred from the Stage-5 amendment gate to Stage-6 Engineering *"where the change's true shape is visible in the diff"*, and tracked as an action item so it could not be skipped under build pressure. | Engineering determination at Commit 0, against the landed diff | **DISCHARGED — decided NO, with the promotion condition recorded rather than left implicit.** Rendered against the diff as the deferral asked. The rubric landed **three** canonicalizations: the roster predicate, the coverage vocabulary with its ordered predicate, and the declared-producer instrumentation test. Three grounds against authoring a record: (i) the sibling audit mode set the precedent deliberately, homing its own canonicalization in its rubric's reconciliation record, and this rubric mirrors that section for exactly this content; (ii) the host decision of record already governs the mode, the layer split, the cadence home and the derive-at-run-time requirement — the roster predicate *closes an item that decision left open* rather than overturning it, which is not ADR-shaped; (iii) the strongest argument **for** a record was reach — that the instrumentation test would bind any future audit axis borrowing the shape — and that consumer is **speculative**, measured rather than assumed: of the sibling audit-cadence axes, none computes an instrumentation ceiling or measures observability today, so the record would have one reader who is already inside the file. The content is not lost: the reconciliation record carries both canonicalizations with their rejected alternatives and the measurement that rejected them. **Promotion condition, recorded so this is a deferral and not a drop:** a second axis measuring instrumentation coverage makes the test a cross-axis contract, and that is the trigger to lift it to the ADR corpus. Reversibility **CHEAP** — the content is already written; promoting it is a move, not an authoring pass. Confidence **HIGH** on (i) and (ii), **MEDIUM** on (iii), which is why the promotion condition rides with it. |

| **DEV-14** | **The plan file's own frontmatter `status:` read `Executing`, outside the declared enum.** Authored at Commit 0; no card's design fault. | The release-corpus schema's Plan-status lifecycle, which states the enum `ACTIVE` / `CLOSED` / `ABANDONED` and instructs `ACTIVE` at authorship | **CORRECTED to `ACTIVE` by the #5232 spoke.** Not cosmetic: the Stage-13 close-out *"fails loudly on a value outside the enum rather than overwriting it"*, so left alone this release's own close-out would refuse to transition its own plan. Reproduced before the change (`lint_release_corpus.py --check plan-identity` exit 1, one non-advisory finding naming this plan), clean after (exit 0), with a sensitivity arm that re-fired on a mutated value. The body Header table's `**Status**` row is deliberately **left alone** — the same schema registers it as non-authoritative narrative annotation that no tool reads, and editing it would manufacture a second surface to keep in sync. This also cleared the red `Close-out automation smoke (macOS)` check, whose 28-step job carried exactly one failing step: the one running that command. |
| **DEV-15** | **Three files outside the § File Change Matrix are edited by #5232**, two of them ratified in the spoke's brief and one a cascade repair. | Operator ratification of the seventh consolidation surface, carried in the Stage-6 spoke brief; plus the rename-reference-cascade obligation for the third | **RATIFIED / RECORDED.** (1) `release/governance/release-process.md` — the **seventh** enumeration, which stated three abstract classes in a third shape, repeated the same false canonical pointer, and then claimed one sentence later that it *"cites that reserved list rather than maintaining a parallel copy"*. AC-1 cannot pass while it stands, and it sits in a governance file above the skill. (2) `.github/workflows/link-check.yml` — the AC-4 / AC-6 mechanism; the Stage-5 design named it as file-change-spec row 8 and the Commit-0 transcription did not carry it into the matrix. (3) `core/schemas/touchpoint-phaseout-schema.md` — a one-line sampling-frame repoint. Its census frame named the bridge as the home of the touchpoint enumeration, which **this change made false**; a dangling reference the change itself created is repaired in the same change rather than deferred, per the rename-reference-cascade obligation. Matrix effect: **+3 edit rows**, zero files added beyond them. |
| **DEV-16** | **AC-4's "expect 0" is met for the files this card owns and NOT for the deployed skill as a whole.** 12 of the baseline 38 deployed-root findings remain. | Engineering determination at the #5232 commit, measured against the reconstructed runtime root | **SURFACED, not absorbed — hub disposition required.** The residual 12 sit entirely in `milestone-readiness-checklist.md` (8), `spoke-launch.md` (3) and `readiness-map-template.md` (1) — three deployed `release-hub` reference files that are **not** in #5232's ratified write-set per § Agent-Editability Read, and that the Stage-5 design's blast radius does not list. The design's AC-4 says *"expect 0"* while its file spec triages only two of the six deployed files, so the criterion and the file set do not agree; the spoke did not self-authorize the wider edit. The three files are `sanctioned-session-required` and would land in the same editor session, so the remedy is cheap (**CHEAP / HIGH**) — it is an authorization question, not a difficulty one. Until dispositioned, the new CI job ships **warn-mode**, so the residual is reported on every PR and blocks nothing. |
| **DEV-17** | **No ADR is authored for the gate-register canonicalization**, though the Stage-5 design named one as file-change-spec row 7. | Engineering determination at the #5232 commit — **surfaced for hub disposition, not self-decided** | **OPEN — routed to the hub.** The design cited it, slug `hub-gate-register-single-source`, as *"to be authored at Stage 6 Commit 0"*, but the ratified § File Change Matrix carries **no** ADR add row and § Agent-Editability Read lists no ADR path for #5232, so authoring one is outside the locked scope this spoke was given. The substance is not lost: the host decision (six candidates), the 12-row reconciliation and the reserved-set amendment are all recorded in **ADR-053 itself**, which this card amends on exactly the membership question — the shape DEV-13 set the precedent for. **Promotion condition:** if the hub rules an independent record is owed, it is an authoring pass over content already written, not new analysis (**CHEAP / HIGH**); no unstamped `{{ADR:…}}` token was introduced on this branch, so nothing orphans if the answer is no. |
| **DEV-18 – DEV-20** | Recorded in the #5278 Stage-6 Engineering output on sub-task #7318, not in this log. DEV-19 is the operator decision behind AI-008, discharged under #5282 below. | The #5278 Engineering spoke; DEV-18 and DEV-19 operator-ratified at that disposition | **POINTER ONLY — transcription is the hub's.** Numbered here so the sequence reads as intact rather than skipped. The substance lives at its source and is not paraphrased into a second copy. |
| **DEV-21** | **The #5282 Stage-6 brief omitted three ratified amendment deltas that bind E1, and framed AI-005's form as an open choice.** The brief carried the joint design's seven E1 elements. The consolidated Stage-5 amendment pass, ratified at the second Collective Review render, adds to E1 the **catch-up limb** (AM-T4), the **named** warn-mode cutover clause with its clarifying half-sentence (AM-T1), and **M3's three-row attestation table as a hub obligation** (AM-T3b). The brief offered AI-005 as either "a new Protocol 4" or "an amendment under Protocol 3"; AM-T1 had already decided a third form — named, not numbered — under which the `THREE` count stays true. | The ratified amendment pass, which the brief's primary design input predates | **IMPLEMENTED PER THE AMENDMENT; surfaced.** The amendment is the later authority, and the live ledger corroborates the catch-up limb's premise — this release's first three commitments, AI-001 to AI-003, carry `source_stage 4`: created at Procedure 0, which no sweep point covers. Executing the brief as written would have shipped a sweep blind to Procedure 0 and a cutover clause that forces a count cascade. |
| **DEV-22** | **E3 cites the attestation signal table rather than restating it** in decision-table rows 1–2. The brief specified the design's three-row table as those rows' content. | Amendment AM-T3b, the shipped E4 tool, and the duplicate-source discipline | **MINOR ADJUSTMENT, with rationale.** AM-T3b relocated the table to the standard because all three of its rows read what a sweep *rendered*, which a close-time tool cannot see. A decision-table cell cannot hold a three-row table without duplicating it. And the shipped tool is a **four**-outcome classifier — two of its outcomes are explicit no-recommendation states — so prose restating three rows would have misdescribed the code in the same commit range. The cells name both producers and cite the standard. |
| **DEV-23** | **E6 — the ADR — is not authored.** The joint design names one, slug `commitment-emission-forced-at-the-routing-point`, to be authored at Engineering. | Engineering determination at the #5282 commits — **surfaced for hub disposition, not self-decided**, on the DEV-17 precedent | **OPEN — routed to the hub.** The ratified § File Change Matrix carries **no** ADR add row, § Agent-Editability Read lists no ADR path for #5282, and the record is not on the branch — the #5278 spoke did not author it. Authoring it would be outside the locked write set, which is the situation DEV-17 records for #5232. The substance is not lost: the determination, its rejected alternatives and its measurements sit in the standard's § 4 and in the joint design. **The slug appears nowhere in the tree in stamp-token form**, so nothing orphans if the answer is no. **Promotion condition:** an authoring pass over content already written (**CHEAP / HIGH**), its number read at that time from `renumber-adr.py --detect` against the `origin/main` anchor. |
| **DEV-24** | **The amendment's E1 delta row lists MJ-2's canonicality sentence; it is left to #7392's F1.** | Amendment MJ-2's own text, which scopes the sentence to F1 | **DEFERRED TO THE OWNING CARD, by construction.** The sentence states that the choice-delta row is canonical for the detector and its prose payload is narrative. Its subject — the `recommendation-choice-delta` branch of the sweep — does not exist until #7392 adds it, so authoring it now would write a sentence about absent content into #7392's surface. The subsection is shaped so that branch lands beside it without re-opening this text. |

---

## Verification Evidence

Populated incrementally by each Stage-6 Engineering spoke as its card lands, and re-executed
at Stage 7. **Every null claim below carries a control arm run on the same instrument against
the same target**; where an arm did not fire, the result is recorded as a broken probe rather
than as a clean one.

### #4027 — decision health-check (Commit 0 + two card commits)

| # | Check | Result | Arms |
|---|---|---|---|
| **V1** | **Doc-link integrity** over the card's seven changed/added files | **0 broken cross-refs** | Sensitivity: a seeded broken relative link in the same scanned directory **was reported** (`broken-cross-ref`, P1). Specificity: a resolving link in that same probe file was **not** reported. Probe removed after the arm fired. Deploy-time Check 14 independently reads `no broken cross-refs in scope`. |
| **V2** | **Plan-depth lint** on the release plan (workspace-rooted link form) | **0 depth-sensitive links** | Sensitivity: a seeded `../`-relative link in a probe plan at the same authoring depth **was reported** with the ADR-092 rename rationale. Specificity: a workspace-rooted link in that same probe was **not** reported. |
| **V3** | **Link-resolver self-test** (parser/resolver/exclusion regression probe) | **OK — 11 fixtures passed** | The self-test is itself the arm: a parser regression fails it independently of any corpus scan. |
| **V4** | **Coverage-vocabulary cascade** — the retired value name is gone from the Mode J sense and nowhere else | **pre 15 across 7 files → post 5 across 5 files** | Population: 1836 readable text files of 2033 tracked paths. Sensitivity: a control token resolves **175** times on the same walk, so the scan reads real content. Specificity: a fabricated same-shape token returns **0**. The 5 survivors are the 3 homonyms in an unrelated acceptance mechanism plus 2 terminal historical records, each **read at its site and classified**, never matched-and-swept — and each verified **byte-unchanged** by an empty diff against the baseline on both the committed and worktree surfaces. A run returning zero for all fifteen would have over-swept. |
| **V5** | **Dangling-citation check** after retiring the mode-spec's provisioning section | **0 references to it remain** | Population: 1769 files. Sensitivity: the same instrument resolves **7** references to the mode-spec section the guard folded into, so it reaches real citations. The seven `§0`-shaped hits it did return all belong to unrelated documents' own section zero. |
| **V6** | **CIAC-3 as amended** — added-lines scan of the four declared files for an integer adjacent to the scored nouns, excluding the identifier token class | **0 hits over 755 added lines** | **Mandatory seeded control FIRED**: an added line reading the forbidden construct is reported. Run twice during authoring — the first pass returned **7**, one a genuine breach (the coverage vocabulary stated as a count) and six structural adjacencies; all seven were corrected before commit. See the note below. |
| **V7** | **Canonical-structure compliance** (Check 6) | **OK — `pmo-qa-auditor`** | Read from the deploy-check verdict rather than re-derived, per the size-conformance rule. 55 OK rows in that block, zero FAIL or DRIFT. |
| **V8** | **Frontmatter description length** | **993 of 1024 characters — PASS** | Unchanged by this card's edits; measured rather than assumed. |
| **V9** | **Skill-package freshness** (Check 7) | **STALE — expected, not a defect** | `pmo-qa-auditor` reports source-changed-since-build. The rebuild is **deliberately deferred** to after the sibling card's commit per the contention resolution: sequential rebuilds of one package across a limb is the shape that produces package drift. This FAIL is the expected mid-limb state and clears when the package is rebuilt once, before the PR leaves draft. |

**Two deploy-check FAILs are pre-existing and not this card's**, verified rather than assumed: a
release-body-drift finding across the logged release population, and a count-structure finding in
two reference documents. Each names files this branch does not touch — an empty diff against the
baseline on every one of them is the evidence.

**A finding about CIAC-3's own specification, surfaced because it will recur.** The criterion's
**authoring constraint** was narrowed to *bare cardinality integers*, with predicate comparators
and quantifiers exempt; its **grading method** was narrowed on different axes — added-lines,
noun set, identifier-token exclusion — and **not** on that one. The two are therefore asymmetric,
and a faithful implementation of the stated method over-fires on section numbers, ordered-list
markers, and existential quantifiers, none of which state a cardinality. This card authored
around the asymmetry rather than arguing it: headings, family identifiers and list markers keep
digits away from the scored nouns, so the criterion reads zero by its own stated method. The one
**genuine** breach the scan caught — the coverage vocabulary written as a count, at eight sites —
is corrected by naming the values instead. Recorded for Stage 9 because the next card editing
these files will meet the same asymmetry.

### #5232 — the hub gate register (three card commits)

| # | Check | Result | Arms |
|---|---|---|---|
| **V5** | **AC-1 — how many surfaces enumerate the reserved touchpoints?** Predicate: a line carrying **≥3 distinct reserved-touchpoint names** outside the `GATE-REGISTER` block. Denominator: **930** tracked markdown files (`release/releases/` excluded as terminal records) | **0** | **Sensitivity:** the identical predicate and instrument over the pre-change blobs at `a3083858` returns **3 surfaces / 5 enumeration sites** (ADR-053:25 · bridge:132,163,2245 · touchpoint-phaseout-schema:183) — the control fires, so the post-zero is a measurement, not a dead pattern. **Specificity:** the same predicate at threshold ≥2 with the block skip **disabled** still returns 3 surfaces, all prose mentions naming Stage 9 / Stage 12 as examples rather than enumerations — the predicate is still live against this corpus |
| **V6** | **AC-2 — register completeness.** Every row carries an acting party and a `STOP` / `EXECUTE-AND-REPORT` / `STOP-IF` disposition | **12 / 12 rows complete** | Read directly; no row is actor-less. The previously passive *"scaffold reviewed"* entry resolves to `EXECUTE-AND-REPORT` with the hub named as actor |
| **V7** | **INT-1 — every register `Emission key` resolves to an `EMISSION-CONTRACT` row** | **12 / 12 resolve; 0 unresolvable** | **Sensitivity:** a fabricated key (`not-a-real-gate`) injected into the register's key set **is reported** by the same set-difference. One row (Tier-0 Premise Rejection) carries `—`, a declared absence rather than an unresolvable key, and is stated as a measured gap in the register itself |
| **V8** | **INT-1 — exactly one delimited block of each kind** | **1 `GATE-REGISTER`, 1 `EMISSION-CONTRACT`** | Delimiter count 2 and 2 |
| **V9** | **AC-3 / AC-4 — deployed-root reachability** over a runtime root reconstructed from all **55** committed `.skill` packages | **38 → 12** | **Sensitivity:** the baseline run reports **38 findings over 22 distinct targets**, reproducing the Stage-5 measurement exactly. All **26** findings in the three files this card owns are cleared; the **12** residual are in three deployed reference files outside this card's write-set (see DEV-16) |
| **V10** | **AC-6 — the detection regression is itself detected.** Known-answer fixture, run before the subject scan, hard-gated independent of warn-mode | **sensitivity PASS · specificity PASS · negative PASS** | **Sensitivity:** 2/2 planted breaks reported. **Specificity:** exactly 2 findings — the 2 resolvable refs (including the sibling-skill hop) and all 4 non-link targets correctly skipped. **Negative:** the same engine over a clean fixture returns 0, so the detector is not stuck-on |
| **V11** | **In-repo link integrity** over the shared CI scan scope + tracked allowlist | **exit 0, 0 findings** | **Sensitivity:** a broken link planted in an in-scope file **was reported**; the file was then restored and verified at exactly one changed line |
| **V12** | **No-renumber invariant** — the count-bearing section title and every ordinal citation survive | **title byte-identical; 3/3 ordinals on each consumer** | `decision-briefing.md § The 5 information-sufficiency gates` unchanged, so `core/standards/hub-action-tracking.md`'s citation still resolves and this card contributes **no** edit to a file already claimed by a sibling card and in-flight PR #7253 |
| **V13** | **Skill structure + packaging pre-checks** | **Check 6 OK (55 scanned, 0 FAIL)** | SKILL.md 260 lines (limit 500); frontmatter `description:` 773 chars (limit 1024) |

#### AC-4 reference-triage classification table (per AM-T7)

The grader reads this rather than a bare "zero unresolved", because a correct triage and a wrong one satisfy a zero identically. **RUNTIME-LOAD** = the hub is instructed to *read* it during a run; **PROVENANCE** = rationale / standard / decision record the hub does not execute. Every target below was resolved against the reconstructed runtime root, never assumed.

| Target (repo-relative) | Class | Disposition | Justification |
|---|---|---|---|
| `release/skills/release-hub/references/*.md` (intra-tree siblings) | RUNTIME-LOAD | **stays a markdown link** | Deployed beside the caller; resolves from the installed tree |
| `release/skills/{release-planner,pmo-release-manager}/SKILL.md` | RUNTIME-LOAD | **stays a markdown link — deliberately NOT converted** | A sibling-skill hop resolves at runtime *and* in-repo. The triage tested each target against the reconstructed root rather than pattern-matching `../`, which is what preserved these four links; a blind sweep would have broken them |
| `release/references/how-to/hub-spoke-bridge.md` | RUNTIME-LOAD — **declared residual** | backticked path; dependency stated in prose | The bridge is not deployed, and R6 rejects deploying it (a new resolver arm, roughly double package size, and it would import the bridge's own outbound references into the surface under repair). **What is no longer residual is gate classification:** AM-T7 moved Gate 0's two classification inputs into the deployed contract, so the hub never needs this file to decide whether to open a gate. What remains is the reusable-template read, which is repository-side by design |
| `core/standards/{hub-session-continuity,hub-action-tracking,failure-mode-standard}.md` · `core/specs/reversibility-protocol.md` · `core/ADRs/ADR-019` · `core/ADRs/ADR-033` · `release/governance/release-process.md` · `release/references/standards/{triage-design-rereview,bundle-composition-doctrine}.md` | PROVENANCE | backticked repo-relative path | Rationale and authoring standards the hub cites but does not execute. The engine extracts only inline links (a bracketed label followed by a parenthesized target) and reference-style definitions, so a path in backticks is genuinely not a navigational affordance — and it is the corpus's own established convention for citing a non-deployed file |
| `operations/skills/{intake-desk,delivery-engine}/SKILL.md` | PROVENANCE **by necessity** | backticked repo-relative path | These are deployed skills, but they sit in a different module: **no single link form resolves in both trees** — the runtime form (`../intake-desk/SKILL.md`) is broken in-repo and the repo form is broken at runtime. Naming the path as text is the only form that is honest in both |

**Residual, stated rather than absorbed:** 8 further distinct targets across `milestone-readiness-checklist.md` (8 findings), `spoke-launch.md` (3) and `readiness-map-template.md` (1) are unresolvable from the deployed root and are **not triaged here** — those three files are outside this card's ratified write-set. They are reported by the new CI job, which ships warn-mode, so they are visible and non-blocking. See DEV-16.

### #5282 — the commitment sweep (four card commits)

Numbered from **V14** so no row collides: the #5232 block above restarted at V5, so V5–V9 already each name two different checks.

| # | Check | Result | Arms |
|---|---|---|---|
| **V14** | **INT-1 — the L1/L2 test lives at exactly one definitional site.** A six-token terminated set — `L1`, `L2`, `UNDECIDED`, the L2 limb name, the sweep subsection head, the L1 limb phrase — counted inside the two **citing** item-4 spans | **bridge Operating-Principle item 4 → 0 · briefing Principle item 4 → 0** | **Sensitivity:** the same set over the standard → **17**; a restatement **planted** into each span → **5** each. **Specificity:** fabricated tokens → **0**. **Amendment delta:** Procedure 4a step 5 carries the branch-agnostic *"the § 4 sweep"*, and the narrow form reads **0** |
| **V15** | **E3 disjointness from in-flight PR #7253** | **rows changed {1, 2}; rows 3–4 byte-unchanged; predicate block 13 / 13 lines byte-identical; 0 verdict cells changed; column arity 7 on every row** | Structural parse of the section, not a substring test. **Controls:** a mutated row 3 is reported; a mutated predicate line is reported. **Sibling side**, re-measured at its current head `22b737a4`: amends rows 3–4, adds row 5, rows 1–2 in no hunk across 39 content lines |
| **V16** | **AI-005 — no count cascades** | **asserted cardinality `['THREE','3']` → `['THREE','3']`; numbered series `[1,2,3]` on both sides** | **Controls:** `THREE → FOUR` is detected; a synthetic `Protocol 4` heading is detected. **Cross-file:** 0 sites state this count — armed by 23 other files that cite the standard across 82 occurrences |
| **V17** | **Invariants the design declares untouched** — the five-row cadence table, `at all 5 routing points`, the three enum headings and their value sets, the 13-field schema, the 7 transitions | **byte-identical, entry `9539ec24` → final** | **Control:** a `5 → 6` heading mutation is detected |
| **V18** | **Check 68 enum parity** — its parity map names three anchors in this file | **all three sections byte-identical (16 / 26 / 11 lines)** | **Control:** a one-value mutation is detected. Settled by measuring the sections directly: running the check script itself was refused by `BLOCK-DESTRUCTIVE-022`, with no permitted invocation form |
| **V19** | **INT-3 pre-check** — no added sentence claims a gate-state count | **0 across 60 added lines** | **Sensitivity:** the same regex fires on the pre-existing `3-valued` text in the § 4 row-5 cell |
| **V20** | **AI-008 — mode read back from the pushed commit via `git ls-tree`**, not from the command's exit code | **`100755`, blob `c61e1c42` unchanged** | **Sensitivity:** the same probe at the parent reads `100644`. **Specificity:** the sourced library `version-grammar.sh` still reads `100644` |
| **V21** | **Link integrity and package cascade** | **0 broken links, exit 0 · 0 skills cascade** | A planted break is reported by the identical scan. `--skills-for-paths` read on **STDIN**; the same invocation resolves `orchestration-playbook.md` to `release-hub`, so the zero is a reading |

**ADR index:** N/A — this card adds no record under `release/ADRs/` (DEV-23).

---

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | | |
| Merge PR | | | |
| Tag release | | | |
| Skill deployment | | | |
| Manifest execution | | | |
| State anchor update | | | |
| Post-execution verification | | | |

---

## Change Description

(Authored by the Stage-6 Engineering spoke at PR-creation time per [`release/governance/RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol — operator-facing voice, six sub-sections. Distinct from the user-facing release note authored at Stage 13 per [`release/references/standards/release-notes-standard.md`](/release/references/standards/release-notes-standard.md). Populated once the last card lands, before the PR is transitioned to ready-for-review at the Stage-9 gate.)

---

## Baseline pin

`origin/main` @ **`a3083858`** (`a30838589583bcddf5f88183cfff1a8ea2475300`), measured 2026-09-10 at Stage-4 Phase A0 and re-confirmed unmoved at Engineering Commit 0 on 2026-09-11 — zero commits landed on `main` in the interval, so the plan's pin and the Commit-0 base are the same commit. Read by the Stage-9 mid-pipeline divergence re-check, which is **expected to fire**: five sibling releases are in flight on files this release edits.

**Divergence event — recorded beside the pin, which is deliberately NOT restamped.** Between Limb B and the first Limb-A card, sibling release `governance-pointer-fixes` merged and `origin/main` advanced to **`e8665feb`** (11 commits, 8 files). The #5232 spoke merged that into the release branch: the merge was **clean, with no conflict resolution**, because the intersection of the merged file set with this branch's changed set is **0** — measured with `comm -12` over both sorted name-only sets, with a control arm (the branch set against itself) returning 9. The pinned reading above is left exactly as taken, per the same reasoning DEV-10 records: a pin rewritten in place destroys the prior the Stage-9 re-check diffs against. Stage 9 reads the pin as the Stage-4 measurement and this paragraph as what happened since. **Version consequence, no rework:** `v4.61` is now claimed by that sibling, so the next free for bump-class `minor` is `v4.62`. Nothing in this plan restamps — the branch and plan file are slug-primary, the Header `**Version**` cell carries the unresolved token, and the number binds only at the Stage-12 atomic claim. The § Commit-0 Version Re-Verify Record's `v4.61` readings are likewise left as the readings they were at their named SHA.

---

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member enumeration IS its subject matter; the numbers are the release's own scope, not prose citations, and relocating them would delete the plan's scope statement -->

Every member of this milestone is transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body. The members are #4027, #4028, #5232, #5278, #5282 and #7392.

- **#4027** — no capability exists to audit how the hub and its spokes decide, across releases, so decision-observability gaps surface one close-out at a time.
- **#4028** — the per-seam coverage scorecard and its run-over-run index have no definition site, so "how much of what we decided got recorded" has no answer.
- **#5232** — the hub's operator-stop points are enumerated six different ways, and the one surface marked canonical carries a different shape entirely.
- **#5278** — the hub emits decision events while the state surfaces its gates read go unwritten, leaving the close-time resolution gate with nothing to resolve.
- **#5282** — the action-item ledger is written by instruction rather than by a forcing function, so a durable commitment can be made and never recorded.
- **#7392** — the `recommendation-choice-delta` emission has no declared obligation, so a divergence between what was recommended and what was chosen leaves no durable row.
