<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Release Plan — stage9-gate-integrity (every control this release ships is demonstrated failing before it is trusted)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: stage9-gate-integrity
release_class: novel
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-14, domain: governance }
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `stage9-gate-integrity`

**Milestone:** `stage9-gate-integrity` (milestone 322). Six build cards on one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. This file is `stage9-gate-integrity_RELEASE_PLAN.md` and the branch is `release/stage9-gate-integrity`; no version stem appears in the filename, in the branch name, or in this plan's identity prose. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket.
**Topology:** **D-C SINGLE** (operator-rendered at the Stage-4 D-Gate) — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (D-Concurrency Posture, Stage-4, declared with evidence rather than defaulted). Stage-6 work routes one card at a time in the approved sequence on the shared branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`novel`** — re-derived from the taxonomy at the Stage-4 gate and operator-rendered, correcting the milestone's proposed `routine`. Posture: engagement density **Standard** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL**, activated on 6 of 6 · Stage-13 outcome window **30-day**.

---

## Provenance

This file transcribes the **Stage-4 Release Planning** analysis approved at the plan-approval gate, reconciled forward through the six **Stage-5 Solutioning** designs, the six **Phase A6.5 adversarial design reviews**, and the operator decisions rendered at the **Collective Review scope-lock gate on 2026-08-14 (Friday)**. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and § Deviation Log records the delta. The Stage-4 and Stage-5 output comments are the historical record and are not edited.

Every issue reference below sits inside this reference block and is accompanied by the summary noun phrase that makes it readable without opening the ticket. The six cards are named throughout by those phrases:

| Card | Summary noun phrase |
|---|---|
| #4215 | the deployment-emitter card |
| #4735 | the hub-emission read-back card |
| #4438 | the matrix-delivery gate card |
| #4760 | the draft-state gate card |
| #4724 | the contention-classifier card |
| #4439 | the close-ordering gate card |

---

## Release Outcome Statement

**AFTER** — Every control this release ships is demonstrated failing on a fixture in which its observing step is removed, and passing on the conformant control. The Stage-9 gate, the close-ordering gate, the contention classifier, the deployment emitter, and the hub's own emission are each observed by something other than themselves.

**BEFORE** — Eight instances of one defect class sit in the pipeline: a declared control with no observing step. Four of the eight are inside the fixes for the other four. The File Change Matrix's declared ADDs are compared against nothing; a draft release pull request can be granted GO; the contention classifier reports clean on a population it could not read; nothing emits `deployment-status`, so Cycle-Time is structurally `N/A`; the hub's Stage-9 emission is never read back; the Procedure 7a close gate passes vacuously when the ledger it reads does not exist.

**Success Indicator:** every ticket below closes with its acceptance criteria verified, and **every control the release adds or repairs carries a recorded two-arm demonstration** — non-conformant fixture RED, conformant control GREEN, both with non-empty extraction. That is CIAC-6, and it is the release's own definition of done.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | slug-only pre-claim per ADR-092; recorded determination **v4.25**, **PROVISIONAL** — see the note below |
| **Date Created** | 2026-08-14 (Friday) — Stage-4 planning |
| **Scope-lock / Collective Review** | 2026-08-14 (Friday) |
| **Commit 0 authored** | 2026-08-14 (Friday) |
| **Release Manager** | Agent-assisted, release-hub Mode O |
| **Status** | Executing — Stage 6 Engineering |
| **Branch** | `release/stage9-gate-integrity` |
| **Base commit** | `8f48357f`, equal to `origin/main` at branch cut and still equal to `origin/main` at Commit 0 |
| **First build commit** | this plan file — Engineering Commit 0 |
| **Pull request** | created by the hub at Stage 6 Phase C2, in **draft** state |
| **Milestone** | `stage9-gate-integrity`, milestone 322 |
| **Release class** | `novel` |
| **Topology and posture** | D-C SINGLE topology, P0 fully-serial posture |

**D-Version is `v4.25` and is PROVISIONAL.** It is a *recorded determination*, not a reservation: it binds only at the Stage-12 atomic compare-and-swap per ADR-092, and the plan file, the branch, and all hub state key on the **milestone slug**, never on the version. The determination was **re-verified at Engineering Commit 0** against freshly-fetched refs, on three independent claimed-set arms each carrying a live sensitivity and specificity control — origin tags, published GitHub Releases, and the mainline release ledger read at the remote tip. All three place the anchor at `v4.24` and `v4.25` free. One sibling release is in flight — the corpus-tolerance-and-hygiene release, draft pull request #5269 — and it is **slug-only per ADR-092 and claims no slot**, so it cannot collide at determination time. A further re-determination at Stage 12 is expected, not exceptional, and **no version literal ships in this release's code**.

---

## Scope

| Ticket | Card | Size | Pts | Priority | Disposition | One-line scope |
|---|---|---|---|---|---|---|
| #4215 | the deployment-emitter card | `size:S` | 2 | — (unlabeled) | build, sequence position 1 | nothing emits `deployment-status`, so Cycle-Time is structurally `N/A` log-wide |
| #4735 | the hub-emission read-back card | `size:S` | 2 | P2 | build, sequence position 2 | the release hub's Stage-9 emission is never read back, so a missed emit is invisible |
| #4438 | the matrix-delivery gate card | `size:M` | 4 | P2 | build, sequence position 3 | no gate compares the approved File Change Matrix's declared ADDs against the merged diff |
| #4760 | the draft-state gate card | `size:M` | 4 | Major | build, sequence position 4 | Stage 9 can render GO on a draft release pull request — Phase A8's transition is described, never asserted |
| #4724 | the contention-classifier card | `size:M` | 4 | P2 | build, sequence position 5 | the line-range-overlap classifier accepts only pull requests, so the PR-less arm cannot be classified |
| #4439 | the close-ordering gate card | `size:S` | 2 | P2 | build, sequence position 6 | the Procedure 7a HARD gate passes vacuously when no action-item ledger exists |

**Raw 18 points** · release class `novel` → `class_weight` **1.15** · **effective points 21** (`round_half_up(18 × 1.15) = 21`), inside the 15–25 band. The G3-15 gate is an upper-bound predicate only; verdict **PASS**. The weights are declared in `core/config/platform-config.toml.template` under `[bundling].release_class_capacity_weights`, and the `XS=1 / S=2 / M=4 / L=8 / XL=16` scale in `release/references/standards/bundle-composition-doctrine.md § 3`, so no degraded-path computation and no operator confirmation of the figure is owed. **This supersedes the Stage-4 summary's "18 effective points"**, which was the raw figure computed before the class was re-rendered `routine → novel` in the same comment; § Deviation Log records the delta.

**Composition Lock:** locked at Stage-4 Planning entry, 2026-08-14 (Friday). **Zero membership change since the lock** — every adjustment recorded below is an `amend`-class change inside the locked set. Files were added to the change matrix at Collective Review; **files, not cards.**

### Approved implementation sequence

1. the deployment-emitter card — smallest blast radius, and it unblocks the release's only hard edge from step 2 onward
2. the hub-emission read-back card — consumes the emitter; also lands the release-hub package rebuild early, where a freshness drift is cheap to catch
3. the matrix-delivery gate card — first claimant on the Stage-9 spec and first allocator on the `G-PR` sequence
4. the draft-state gate card — second `G-PR` allocator, so the ID allocation is deterministic rather than a merge-time negotiation
5. the contention-classifier card — third and last co-editor of the Stage-9 spec; its own tool is uncontended
6. the close-ordering gate card — last claimant on both `core/deploy/deploy.sh` and the hub bridge, and the natural place to render the one AC that is not release-buildable

This diverges from the milestone's declared order, and the divergence is deliberate. The declared order front-loads the widest card (five claimed paths) and defers the narrowest (one path) to position 3, leaving the release's only hard edge unsatisfied through two cards. The approved order satisfies that edge first, then walks the two hot files — the Stage-9 spec and the gate-criteria schema — in a single direction, so each co-editor rebases onto a settled predecessor rather than a concurrent one.

**The edge from the deployment-emitter card to the hub-emission read-back card is verification-order, not build-order.** The two share zero files: the emitter card claims `core/deploy/deploy.sh` plus the two metric consumers; the read-back card claims the release-hub skill surface. The read-back card's code can be written at any point; what the edge constrains is *grading* its AC2, which asserts a positive `T_DEPLOY − T_GO` and therefore needs the emitter to exist. Under P0 fully-serial the distinction is inert; it is recorded because it would become load-bearing under any non-serial posture.

---

## Release Class

**`novel`**, re-derived trigger by trigger from `release/references/standards/release-class-taxonomy.md` rather than inherited from the hub's configured default.

**`routine` fires zero of its four triggers:**

| `routine` trigger | Verdict | Evidence |
|---|---|---|
| (a) all issues P3/P4 and `size:S`/`size:M` | **FAIL** | Sizes qualify (3 × S, 3 × M); severities do not. Four cards are P2, one is Major, one is unlabeled. **Zero** cards are P3/P4. |
| (b) all change-spec files have ≥ 3 prior release touches | **FAIL** | Measured across nine candidate paths: `deploy.sh` 234 · `hub-spoke-bridge.md` 79 · `automated-closeout.sh` 65 · `gate-criteria-spec.md` 53 · `stage-04-planning.md` 29 · `orchestration-playbook.md` 19 · `stage-09-plan-review.md` 16 · `append-pipeline-event.sh` 12 — and **`check-line-range-overlap.py` = 1**. One file below threshold fails the universal. |
| (c) zero new files added | **FAIL** | The unconditional ADD set is non-empty — this plan file plus nine test fixtures. |
| (d) zero new D-class decisions in the release plan | **FAIL** | The plan carries D-Version, D-Concurrency Posture, D-C Branch Topology, and D-ADR-Disposition. |

**`novel` trigger (b) — "≥ 1 D-class decision in the release plan" — fires unambiguously**, and trigger (a) fires on the ADR disposition. **`cross-cutting` does not fire:** (a) the matrix touches **2** `pipeline/stage-*.md` files, not ≥ 3 — held at 2 by the explicit non-scope of the Stage-12 and Stage-13 specs; (b) the matrix touches **2** of the seven-file governance set (the hub bridge and the gate-criteria schema); (c) there is **1** in-bundle hard edge, not ≥ 3 — the shared-surface coordination edges are contention, which the Contention Map models separately.

Multi-trigger resolution (`cross-cutting` > `novel` > `routine`) therefore yields **`novel`**. Re-rendering `routine → novel` is cheaper-to-stricter: it adds ceremony, invalidates no downstream artifact, and reverts at the next gate. **CHEAP / Confidence HIGH.**

---

## Dependency Graph

Directional; `→` reads *must precede*. Edge class distinguishes what the edge actually constrains.

```
matrix-delivery gate ────┐
contention-classifier ───┤ (no build dependency between any of these four)
draft-state gate ────────┤
close-ordering gate ─────┘

deployment-emitter ──[HARD, verification-order]──▶ hub-emission read-back
```

| Edge | Class | Constrains | Evidence |
|---|---|---|---|
| deployment-emitter → hub-emission read-back | **HARD** — verification-order | the read-back card's AC2 only | That AC asserts a positive `T_DEPLOY − T_GO`. The token `deployment-status` occurred **0** times in `core/deploy/deploy.sh` at baseline, while `release/tools/compute-cycle-time.sh` already reads the `deploy-skill` and `deploy-harness` subtypes for `T_DEPLOY`. The emitter card supplies the only missing half. **Confirmed — the edge holds.** |
| matrix-delivery gate ↔ draft-state gate | SOFT — ID allocation | `G-PR` criterion numbering | Both add a Gate 9 criterion to one sequence at `G-PR1..G-PR10`. Whichever lands second takes the next free number. Graded by CIAC-1. |
| matrix-delivery gate ↔ contention-classifier ↔ draft-state gate | SOFT — co-edit | the Stage-9 spec | Three cards, three different phases of one 156-line file. Graded by CIAC-3. |
| hub-emission read-back ↔ draft-state gate ↔ close-ordering gate | SOFT — co-edit | the hub bridge | Procedures 4a / 5 / 7a respectively. Graded by CIAC-5. |
| deployment-emitter ↔ close-ordering gate | SOFT — co-edit | `core/deploy/deploy.sh` | Reduced from 3-way to 2-way by the D-Gate-Home decision routing the matrix-delivery assertion to `verify-release-plan.sh`. Graded by CIAC-4. |
| matrix-delivery gate ↔ close-ordering gate | SOFT — shared pattern | anti-vacuity control surface | Both ACs require a control proving a new gate fires. Graded by CIAC-2. |

**No additional hard edges found. Zero circular chains.**

---

## Stage Applicability Matrix

Default is all stages. Skips require evidence; none is claimed.

| Card | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9–S13 | Skip rationale |
|---|---|---|---|---|---|---|
| the deployment-emitter card | ✅ | ✅ | ✅ | ✅ | ✅ | Call-site selection inside a 13,034-line script, subtype-per-target mapping, plus two metric consumers added at scope-lock. Not trivial despite `size:S`. |
| the hub-emission read-back card | ✅ | ✅ | ✅ | ✅ | ✅ | Which hub surface carries the read-back, and how to prove the emission check is non-vacuous on this failure mode. |
| the matrix-delivery gate card | ✅ | ✅ | ✅ | ✅ | ✅ (release-scoped) | Where the assertion lives, CONDITIONAL-vs-unconditional row semantics, the Deviation-Log contract shape. |
| the draft-state gate card | ✅ | ✅ | ✅ | ✅ | ✅ | Four-surface edit including a spec reconciliation no card declares; fail-closed criterion with both control arms. |
| the contention-classifier card | ✅ | ✅ | ✅ | ✅ | ✅ | Additive input mode requiring a branch-population contract and verdict-vocabulary parity with the pull-request path. |
| the close-ordering gate card | ✅ | ✅ | ✅ | ✅ | ✅ | Close-ordering inside an 8,725-line script plus an anti-vacuity fixture. |

**Stage 5: 6 of 6 activated.** **Stages 7 / 8: 6 of 6 activate** — every card changes runtime behaviour of a gate, a check, or an emitter; none is documentation-only.
**Parallel-eligible spoke count: Stage 5 = 6 · Stage 7 = 6 · Stage 8 = 6.**

---

## Contention Map

Measured, not assumed.

### Within-release

| Ways | Path | Claimants | Class |
|---|---|---|---|
| **3-way** | `release/references/pipeline/stage-09-plan-review.md` | matrix-delivery gate, contention-classifier, draft-state gate | Three different phases of one 156-line file |
| **3-way** | `release/references/how-to/hub-spoke-bridge.md` | hub-emission read-back (read-only), draft-state gate, close-ordering gate | Procedures 4a / 5 / 7a |
| **2-way** | `core/deploy/deploy.sh` | deployment-emitter, close-ordering gate | Reduced from 3-way at the D-Gate-Home decision |
| **2-way** | `core/schemas/gate-criteria-spec.md` | matrix-delivery gate (conditional), draft-state gate | ID-allocation coupling |

**Uncontended (1 claimant each):** the Stage-4 planning spec, `verify-release-plan.sh`, `test_verify_release_plan.sh` and the nine test fixtures (all the matrix-delivery gate card) · `check-line-range-overlap.py` (the contention-classifier card) · `automated-closeout.sh` (the close-ordering gate card) · the orchestration playbook and the release-hub skill surface (the hub-emission read-back card) · the readiness-scan spec (the draft-state gate card) · `compute-cycle-time.sh` and `compute-dora-metrics.sh` (the deployment-emitter card).

**The two `core/deploy/deploy.sh` claimants are disjoint by construction and both spokes must keep it that way.** The deployment-emitter card edits the shared-function block, `cmd_deploy()`, and `cmd_self_test()`; the close-ordering gate card's fixture home is `cmd_self_test()`. The two `cmd_self_test()` additions are **separate assertion groups** — the emitter's group DS and the close-ordering card's own — and neither is nested inside the other's conditional. That independence is exactly what CIAC-4 grades.

### Cross-PR contention

**Baseline SHA:** `8f48357f` · measured 2026-08-14 (Friday).

One sibling release is in flight — the corpus-tolerance-and-hygiene release, draft pull request #5269, head `77733b52`, slug-only per ADR-092 and claiming no version slot. Its edit set intersects this matrix at **`core/deploy/deploy.sh`** and **`core/schemas/gate-criteria-spec.md`** — this release's two hottest files, contended internally *and* across releases. Merges against that sibling must be serialized.

**Audit-baseline caveat (explicit, per the discipline).** The **P₂** arm — remote `release/*` heads with no open pull request — measured **0** at baseline, and a default-to-zero over a transiently-empty population is not load-bearing on its own. It has since **repopulated 0 → 2**: `release/reference-constant-integrity` and `release/skill-suite-conformance`, both without a pull request. Neither intersects this matrix, so the contention verdict is unchanged — but **the contention-classifier card's live cross-check arm now has members and must be run at Stage 7, not skipped**, and the roster is re-measured at Stage 9 Phase A6.6 before GO.

---

## Risk Register

Severity is impact-on-this-release. Every entry names an owner surface and a mitigation.

| ID | Risk | Sev | Class | Mitigation |
|---|---|---|---|---|
| **R1** | **Cross-release collision on `core/deploy/deploy.sh`** — two internal claimants plus the in-flight sibling. Highest merge-conflict surface in the release. | **HIGH** | Contention | Serialize merges against the sibling. Re-run Stage 9 Phase A6.6 pre-GO against a re-measured roster. |
| **R2** | **Cross-release collision on `core/schemas/gate-criteria-spec.md`** — the sibling edits the same schema this release adds ≥ 1 Gate 9 criterion to. | **HIGH** | Contention | Same serialization. Read the sibling's diff on this file before allocating `G-PR` IDs. |
| **R3** | **`G-PR` criterion ID collision** — two cards allocate from a sequence at `G-PR1..G-PR10`. | MED | Dependency | The matrix-delivery gate card is sequenced before the draft-state gate card. Graded by CIAC-1. **Re-check the live max `G-PR` ID at Commit 0** — max on main at baseline is `G-PR10`, and the second allocator's `G-PR12` presumes the first's `G-PR11` lands (INT-1). |
| **R4** | **Lost edit on the Stage-9 spec** — three claimants on a 156-line file. | MED | Contention | P0 fully-serial Stage-6 posture. Graded by CIAC-3. |
| **R5** | **Lost edit on the hub bridge** — three claimants across Procedures 4a / 5 / 7a. | MED | Contention | Same. Graded by CIAC-5. |
| **R6** | **The draft-state gate card's AC1 contradicts readiness-scan § 5.1 state 4**, which grades `draft-blocked` as PASS on the premise the A8 transition clears it. A fail-closed Gate-9 criterion binding `isDraft == false` disagrees. | **HIGH** | Scope | The readiness-scan spec is in the matrix. The reconciliation is explicit: either § 5.1 state 4 becomes non-PASS at Stage 9, or the new criterion fires only after A8. |
| **R7** | **The draft-state gate card's AC3 is largely pre-shipped** — Procedure 5 Step 2b already reads the draft flag. Risk of a vacuous AC graded MET on work predating the release. | MED | Scope | AC3 grades the *residual*: the read exists; what is missing is that its result **binds** the gate. |
| **R8** | **The close-ordering gate card's AC3 is not release-buildable** — the card marks it an operator action. Grading it produces a false NOT MET at Stage 8. | MED | Scope | Routed to tracked hub action item **AI-001**; grade the release on ACs 1–2 only. |
| **R9** | **The matrix-delivery gate card is reflexive** — the gate it ships reads this very plan's File Change Matrix. | MED | Scope | Self-application is **declared, not defaulted**. This matrix carries marker-bearing unconditional ADD rows precisely so the reflexive run is a real PASS rather than an intent-undeclared SKIP. |
| **R10** | **Package drift on the release-hub package** — the read-back card edits the skill source; a missed rebuild fails the package-freshness check at deploy. | MED | Rollback/CI | Both package rows are in the matrix. Rebuild via `core/deploy/tools/build-skill-packages.sh` in the same pull request. |
| **R11** | **The contention-classifier card cannot be verified against a live PR-less sibling** at the original baseline. | MED | Verification | A **constructed fixture** carries the branch arm. The P₂ repopulation to 2 additionally enables a live cross-check arm at Stage 7. |
| **R12** | **Emitted telemetry survives rollback** — the deployment emitter's rows persist in the append-only event log after a `git revert`. | LOW | Rollback | Named, not mitigated: the rows are honest records of a deploy that occurred. **Do not prune the log.** Rollback remains CHEAP / Confidence HIGH for code. |
| **R13** | **Anti-vacuity controls diverge** — two cards each require a control proving a new gate fires; authored independently they become two bespoke arms with no shared entry point. | LOW | Consistency | Graded by CIAC-2 — one locally-invocable entry point. |
| **R14** | **A `--release` slug typo is permanent.** The event writer's slug guard is a **negative** predicate — it rejects the version grammar, not everything that is not a real slug — so a plausible single-character typo passes and creates a phantom, unresolvable DORA occasion in an append-only log. | MED | Source integrity | The emitter adds a **shape** guard (non-empty, no whitespace, no bare pipe) at the emit boundary, which closes the row-corrupting cases. Positive slug resolution against the release ledger is **NOT** implemented and is a named residual — see § Deviation Log D-5. |
| **R15** | **`set -e` truncates the emission set.** `deploy.sh` runs `set -euo pipefail`; an unguarded non-zero anywhere in a deploy loop body exits the shell mid-iteration, skipping the remaining targets' emits *and* the terminal failure summary. Every emitted row is truthful, but the emitted **set** is silently partial. | LOW | Source integrity | Named, not mitigated. The emitter's non-emission inventory records the `set -e` exits alongside the explicit `die` exits so the four `die` points do not read as the complete exit inventory. |

**Rollback complexity: LOW.** Single branch, single merge, all six cards additive; per-card revert is viable. The only asymmetry is R12.

---

## Cross-Issue Acceptance Criteria

Six CIACs. Each is release-scoped, spans ≥ 2 cards, requires no dependency edge, and maps onto a *measured* finding. Graded at **Stage 9 QC3.5 / Phase A3.6 on the merged pull request**.

- [ ] **CIAC-1 (matrix-delivery gate × draft-state gate — the Gate 9 criteria table):** the merged Gate 9 section carries both new criteria as **distinct, gap-free, sequentially-numbered** `G-PR` IDs, with no duplicate ID and no renumbering of the shipped `G-PR1..G-PR10`. *Shared surface:* `core/schemas/gate-criteria-spec.md` § Gate 9. *Method:* extract the Gate 9 section, collect every `G-PR<N>` token, version-sort unique — the result is ≥ 12 members forming a gap-free run from `G-PR1`, and the duplicate-detecting pass returns empty.

- [ ] **CIAC-2 (matrix-delivery gate × close-ordering gate — the anti-vacuity control surface):** both cards' anti-vacuity controls are reachable from **one locally-invocable entry point** that CI also invokes — not two bespoke inline assertions. *Shared surface:* the `deploy.sh --self-test` assertion-group surface. *Method:* both control arms are named in the self-test output of a single entry point, each arm's identifier resolves at least once inside that entry point, and neither arm is invoked only from CI workflow YAML.

- [ ] **CIAC-3 (matrix-delivery gate × contention-classifier × draft-state gate — the Stage 9 spec):** all three cards' edits are present in the merged file with **no lost edit and phase ordering preserved** (Phase A6.6 precedes Phase A8). *Shared surface:* `release/references/pipeline/stage-09-plan-review.md`. *Method:* an anchor resolves for each of the three edits, and the A6.6 anchor's line number is strictly less than the A8 anchor's.

- [ ] **CIAC-4 (deployment-emitter × close-ordering gate — `core/deploy/deploy.sh`):** both additions are present and independent — the `deployment-status` emitter call is **not** gated behind the Procedure-7a fixture's flag, nor the reverse — and `./deploy.sh --check` introduces **no new FAIL** relative to the pre-release baseline. *Shared surface:* `core/deploy/deploy.sh`. *Method:* the token `deployment-status` resolves at least once **and** the 7a fixture identifier resolves at least once, with neither inside the other's conditional block; plus a `--check` FAIL-line diff against `8f48357f`, keyed on the `"  FAIL:"` line set and **never** on the exit code — the exit status mirrors operator-instance drift, not real failures.

- [ ] **CIAC-5 (hub-emission read-back × draft-state gate × close-ordering gate — the hub bridge):** all three cards' obligations are present in the merged file at their **own** procedures — Procedure 4a (emission), Procedure 5 (draft-state binding), Procedure 7a (close-ordering) — with no procedure's content displaced into another's. *Shared surface:* `release/references/how-to/hub-spoke-bridge.md`. *Method:* each of the three procedure anchors and its card-specific obligation text resolves, and the three line ranges are disjoint.

- [ ] **CIAC-6 (all six cards — the systemic guard):** **every control this release adds or repairs is demonstrated failing on a fixture in which its observing step is removed, and passing on the conformant control. Both arms recorded with non-empty extraction.** *Shared surface:* the release's control surface as a whole — no single file. *Method:* per-control, the two arms are named and their observed outputs recorded; an arm whose extraction is empty does not count as a demonstration, and a control that only ever passes is a finding.

**Why CIAC-6 exists.** The systemic finding rendered at Collective Review is that the release's own defect class — *a declared control with no observing step* — appeared **eight** times, and **four of those eight were inside the fixes for the other four**. Every one of instances 4–8 was caught by **execution**, never by reading: three adversarial reviewers built degenerate implementations and ran them, and one ran mutation testing. CIAC-6 promotes that check from ad hoc review practice to a contracted, graded criterion.

**Deliberately NOT authored as a CIAC:** the `T_DEPLOY − T_GO` positivity constraint spanning the deployment-emitter and hub-emission read-back cards. That pair carries a dependency edge, which routes it to the per-issue-pair `INT-N` namespace, and the read-back card's AC2 already grades it. Authoring it here would duplicate an existing AC and blur the CIAC/INT boundary. Recorded so the omission reads as a decision, not a gap.

**INT-1 (matrix-delivery gate → draft-state gate):** the second allocator's `G-PR12` presumes the first's `G-PR11` lands. The live max `G-PR` ID on `origin/main` is **`G-PR10`** at Commit 0; re-check before allocating.

---

## File Change Matrix

**Machine-readable path list** — one path per line, so Stage 7, 8 and 9 chips extract this block deterministically. **Unconditional set** — every path here is expected in the merged diff.

```
release/releases/plans/stage9-gate-integrity_RELEASE_PLAN.md
release/references/pipeline/stage-09-plan-review.md
release/references/pipeline/stage-04-planning.md
release/references/how-to/hub-spoke-bridge.md
release/references/specs/release-readiness-scan-spec.md
core/schemas/gate-criteria-spec.md
core/deploy/deploy.sh
release/tools/check-line-range-overlap.py
release/tools/automated-closeout.sh
release/tools/verify-release-plan.sh
release/tools/compute-cycle-time.sh
release/tools/compute-dora-metrics.sh
release/tools/tests/test_verify_release_plan.sh
release/tools/tests/fixtures/fcm-declared-absent.md
release/tools/tests/fixtures/fcm-conformant.md
release/tools/tests/fixtures/fcm-deviation-recorded.md
release/tools/tests/fixtures/fcm-conditional.md
release/tools/tests/fixtures/fcm-no-matrix.md
release/tools/tests/fixtures/fcm-bare-paths.md
release/tools/tests/fixtures/fcm-readonly-rows.md
release/tools/tests/fixtures/fcm-glob.md
release/tools/tests/fixtures/fcm-truncating.md
release/tools/tests/fixtures/fcm-diff-absent.tsv
release/tools/tests/fixtures/fcm-diff-present.tsv
release/ADRs/ADR-133-a-gate-ships-armed-by-a-committed-default.md
core/config/allowlists/script-execution-allowlist.txt
release/skills/release-hub/references/orchestration-playbook.md
release/skills/release-hub/SKILL.md
packages/release-hub.skill
packages/release-hub.skill.sha256
```

| Path | Intent | Owning card(s) |
|---|---|---|
| `release/releases/plans/stage9-gate-integrity_RELEASE_PLAN.md` | **ADD** | this plan, landing as Engineering Commit 0 |
| `release/references/pipeline/stage-09-plan-review.md` | EDIT | the matrix-delivery gate card (Phase A3.7 read-only consumption), the contention-classifier card (classification phase), the draft-state gate card (Phase A8 assertion) |
| `release/references/pipeline/stage-04-planning.md` | EDIT | the matrix-delivery gate card — the File Change Matrix authoring contract |
| `release/references/how-to/hub-spoke-bridge.md` | EDIT | the hub-emission read-back card (Procedure 4a), the draft-state gate card (Procedure 5), the close-ordering gate card (Procedure 7a) |
| `release/references/specs/release-readiness-scan-spec.md` | EDIT | the draft-state gate card — § 5.1 state 4 reconciliation |
| `core/schemas/gate-criteria-spec.md` | EDIT | the matrix-delivery gate card (`G-PR11` plus its self-repair row), the draft-state gate card (`G-PR12`) |
| `core/deploy/deploy.sh` | EDIT | the deployment-emitter card (flag, emitter, observer, self-test group DS), the close-ordering gate card (Procedure-7a fixture), the hub-emission read-back card (self-test group DE arm `DE-4b` — see Deviation Log **D-9**) |
| `release/tools/check-line-range-overlap.py` | EDIT | the contention-classifier card — the branch input mode |
| `release/tools/automated-closeout.sh` | EDIT | the close-ordering gate card — close-ordering |
| `release/tools/verify-release-plan.sh` | EDIT | the matrix-delivery gate card — the FCM-delivery assertion family |
| `release/tools/compute-cycle-time.sh` | EDIT | the deployment-emitter card — a failed deploy must not anchor `T_DEPLOY` |
| `release/tools/compute-dora-metrics.sh` | EDIT | the deployment-emitter card — a failed deploy must enter the change-failure-rate **numerator** |
| `release/tools/tests/test_verify_release_plan.sh` | EDIT | the matrix-delivery gate card — the AC4 arms |
| `release/tools/tests/fixtures/fcm-declared-absent.md` | **ADD** | the matrix-delivery gate card — the declared-but-absent fixture |
| `release/tools/tests/fixtures/fcm-conformant.md` | **ADD** | the matrix-delivery gate card — the conformant control fixture |
| `release/tools/tests/fixtures/fcm-deviation-recorded.md` | **ADD** | the matrix-delivery gate card — the deviation-recorded fixture |
| `release/tools/tests/fixtures/fcm-conditional.md` | **ADD** | the matrix-delivery gate card — the unfired-conditional fixture |
| `release/tools/tests/fixtures/fcm-no-matrix.md` | **ADD** | the matrix-delivery gate card — the absent-matrix fixture |
| `release/tools/tests/fixtures/fcm-bare-paths.md` | **ADD** | the matrix-delivery gate card — the marker-less fixture |
| `release/tools/tests/fixtures/fcm-readonly-rows.md` | **ADD** | the matrix-delivery gate card — the excluded-non-change-class fixture |
| `release/tools/tests/fixtures/fcm-glob.md` | **ADD** | the matrix-delivery gate card — the glob and placeholder path-form fixture |
| `release/tools/tests/fixtures/fcm-truncating.md` | **ADD** | the matrix-delivery gate card — the in-fence-comment extraction-fidelity fixture |
| `release/tools/tests/fixtures/fcm-diff-absent.tsv` | **ADD** | the matrix-delivery gate card — the diff-set seam, absent arm |
| `release/tools/tests/fixtures/fcm-diff-present.tsv` | **ADD** | the matrix-delivery gate card — the diff-set seam, present arm |
| `release/ADRs/ADR-133-a-gate-ships-armed-by-a-committed-default.md` | **ADD** | the matrix-delivery gate card — AC5, the v4.03 record authored retroactively (promoted from CONDITIONAL, see **D-11**) |
| `core/config/allowlists/script-execution-allowlist.txt` | EDIT | the deployment-emitter card — the operator-authorized rows for `compute-dora-metrics.sh` and `test_deploy_sandbox.sh` (promoted from CONDITIONAL, see **D-12**) |
| `release/skills/release-hub/references/orchestration-playbook.md` | EDIT | the hub-emission read-back card — the Procedure 4a read-back |
| `release/skills/release-hub/SKILL.md` | EDIT | the hub-emission read-back card — the hub skill surface |
| `packages/release-hub.skill` | EDIT | the hub-emission read-back card — package rebuild |
| `packages/release-hub.skill.sha256` | EDIT | the hub-emission read-back card — package content baseline |

**Thirteen unconditional ADDs, every one a concrete resolvable path.** This is deliberate and it is the release dogfooding its own gate. The matrix-delivery gate card ships the check that compares a plan's declared ADDs against the merged diff; a matrix that declared its ADD set only in prose, or only as a glob, would make that reflexive run **vacuous** — a marker-less matrix yields an intent-undeclared verdict, which is a SKIP rather than a PASS. Naming the eleven fixtures individually, plus this plan file and the retroactive ADR, creates real obligations the new gate can judge. **The eleven fixture filenames are the matrix-delivery gate card's to deliver**; a rename is an `amend`-class Deviation Log entry, never a silent substitution.

> **The glob caveat is now historical, and the reason matters.** Stage 5's amendment declared the fixtures as `release/tools/tests/fixtures/fcm-*`, which adversarial review showed would yield a **guaranteed FAIL**: globs had no arm in the drafted path-form taxonomy. Stage 6 measured the corpus and found **27 glob-bearing path tokens across 15 plans** — an established authored form, not an edge case — and shipped the glob arm. Concrete paths are still what this matrix declares, because a concrete path is the stronger obligation; but a plan that declares a glob is now correctly judged rather than mechanically failed.

**The plan file's row is unconditional, not conditional.** Stage 4 declared it CONDITIONAL on `D-C Branch Topology = SINGLE`, because under an OPTION-A topology the plan would land on `main` via a separate chore pull request and be absent from the release pull request's diff. **D-C SINGLE is rendered**, so the condition has fired and the row is promoted. A fired conditional that stays in the CONDITIONAL block is indistinguishable from one that never fired.

### CONDITIONAL rows

Declared separately so the matrix-delivery gate can honour its own AC3 — *distinguishes CONDITIONAL matrix rows from unconditional ADDs*. A CONDITIONAL row that does not fire is **not** a declared-but-absent violation.

```
(none — both Stage-4 conditional rows have fired and are promoted; see D-11 and D-12)
```

**Both original CONDITIONAL rows have fired and are promoted into the unconditional set above.** A fired conditional left in this block is indistinguishable from one that never fired, which is the authoring defect the promotion rule in `stage-04-planning.md` now names.

- **The ADR row fired: `D-ADR-Disposition = author-retroactively` is rendered, and the record is authored.** The number was deliberately unallocated at Stage 5 — allocating before the disposition is rendered writes a path into the machine-readable set that can never match, precisely the false-positive class this card's gate exists to prevent. Allocated at Engineering time via `release/tools/renumber-adr.py --next-free`, global-monotonic across **both** `core/ADRs/` and `release/ADRs/`: the mainline anchor is `ADR-132`, so next-free is **`ADR-133`**. Per ADR-115 an unmerged branch claim is **advisory** and next-free is `anchor(origin/main) + 1`, never `max(claimed_set) + 1` — a gap blocks the repository, a duplicate inconveniences one branch and is tooled at Stage 12. All four open sibling branches were checked and none claims `133`.
- **The allowlist row fired, but NOT on its declared condition — see D-12.** Its Stage-4 condition was *"any new tracked `*.sh` shipping"*, and that condition did **not** fire: no tracked executable shell script is an ADD in this matrix (the eleven fixtures are `.md` and `.tsv`; the test script already exists). The file is nonetheless edited, on a different and operator-authorized basis. Leaving the row conditional on a predicate that is false would have been an authoring defect in the opposite direction — a real edit shielded by a condition that never fired.
- **New-executable companion obligation: does NOT fire.** Per the Stage-4 authoring contract the obligation attaches to an `add` row for a tracked executable, and there is none. Should any card diverge and author a new `*.sh`, the allowlist row plus all four invocation forms is **mandatory in this release**, not a follow-up.

### Release-wide explicit non-scope

Each entry is a recorded decision, not an omission.

```
release/tools/append-pipeline-event.sh                    — NOT EDITED   (the deploy and hub emitters: `deployment-status` and its subtypes are already accepted; the gap is the caller)
release/references/standards/pipeline-event-log-schema.md — NOT EDITED   (all five subtypes already declared; no schema change needed)
release/references/pipeline/stage-12-execute.md           — NOT TOUCHED  (the draft-state card's relationship statement lands in the Stage-9 spec; holds the cross-cutting trigger at 2)
release/references/pipeline/stage-13-close.md             — NOT TOUCHED  (the close-ordering card's change is a tooling plus Procedure-7a change, not a stage-spec change)
```

**`release/tools/compute-cycle-time.sh` and `release/tools/compute-dora-metrics.sh` were in this non-scope block at Stage 4 and are no longer.** Both moved into the unconditional matrix at Collective Review. The rationale is measured, not asserted: a release in which **every** deploy target failed yielded a measured `Cycle-Time delta=9001s` and `change_failure_rate: 0.0% (0/1)`. Failed deploys entered the change-failure-rate **denominator only** — the numerator was keyed exclusively to a rollback event — so the platform's change-failure rate **improved as deploys failed**, permanently, in an append-only log. The deployment-emitter card's own acceptance criterion, *"returns a value rather than `N/A`"*, was therefore **satisfied by total failure** and could not distinguish being met from being defeated.

**Package rebuild is in scope, not incidental.** The hub-emission read-back card edits the release-hub skill source, so the package and its content-baseline sidecar must be rebuilt via `core/deploy/tools/build-skill-packages.sh` in the same pull request, or the package-freshness check fails at deploy.

---

## Verification Plan

### Per-issue

- **The deployment-emitter card — the emitter and its two consumers.** A deploy carrying `--release <slug>` emits one `deployment-status` row per affected target; the identical deploy **without** the flag emits exactly **zero** rows, so the flag's presence is what the arms separate. A per-target failure emits a row carrying the failed terminal state *before* the terminal failure summary, and the deploy still exits non-zero. A totally-failed deploy yields **`N/A`** from `compute-cycle-time.sh`, not a measured duration, and **100 %** from `compute-dora-metrics.sh`'s change-failure rate, not 0 %. A deploy that reaches the no-changes exit emits zero rows — the honest `N/A`, which **Stage 8 must not grade as a defect**. And a deploy that deployed real targets with no `--release` supplied emits a named warning identifying the omission, so the forgotten-flag state is no longer byte-identical to the honest-`N/A` state.
- **The hub-emission read-back card.** The read-back asserts a **`POST == PRE + 1` delta** on the queried row set scoped to the gate stage, not a non-zero absolute. The drafted absolute form was measured on a live release returning **10**, of which **8** predated the gate — the control passed with the intended row absent. The delta form is what makes a missed emit observable.
- **The matrix-delivery gate card.** A plan declaring an ADD that the merged diff does not contain fails; a conformant plan passes; a CONDITIONAL row that did not fire is not a violation; a marker-less matrix reports an intent-undeclared verdict rather than a zero-obligation clean. A **glob arm** joins the path-form taxonomy. **Both carried obligations are discharged at Stage 6 — see § FCM population, pinned below.**

#### FCM population — pinned denominator and shipped-instrument survey (matrix-delivery gate card)

**Method, stated so it is reproducible.** The population is `find release/releases/plans -name '*_RELEASE_PLAN.md'`. A plan is **FCM-bearing** when the *shipped* extractor returns a non-empty body for the heading `File Change Matrix`. The extractor's awk program was lifted **programmatically from the tool source** and SHA-pinned rather than transcribed, so the survey ran the same bytes the gate runs; a transcribed model is the instrument-substitution error that produced the earlier disagreement.

| Reading | At `origin/main` `8f48357f` | At branch tip | What question it answers |
|---|---|---|---|
| Plan files | 164 | 165 | the corpus |
| Loose mention of the string anywhere | 142 | 143 | *narrative* mentions too — **not a denominator** |
| Anchored heading `^#+ File Change Matrix` | **116** | **117** | plans with a matrix heading |
| **Shipped extractor returns a non-empty body** | **116** | **117** | **← THE DENOMINATOR** |

**The two anchored readings agree as SETS, not merely as counts** — zero files carry a heading with an empty extracted body, and zero carry a body without an anchored heading. The denominator is therefore robust to which of the two probes is used. Specificity arm (`File Change Matrixzzz`) → 0; sensitivity arm (a sibling heading) → non-zero. **This reconciles all four prior measurements: 142 is the loose-grep superset, 116 is both anchored probes at `main`, and the 127 / 126 readings reproduce under no probe run here — they were measured with a fence-aware model of an extractor that does not ship.**

**Row-level census under the shipping parser:** 1,767 declaration rows across the 117 — 349 unconditional ADD obligations, 3 conditional ADDs, 60 excluded (READ / non-scope / rename), 676 genuinely uninterpreted, and 84 marked-but-pathless rows (the shape whose `Path` column holds human labels; a **named** error, not a silent zero). Path forms: **27 glob-bearing tokens across 15 plans**, which is what makes the glob arm mandatory rather than optional.

**Same-path reconciliation, and why the row-granularity finding needed it.** The dominant authored shape is a machine-readable fence of **bare** paths plus a companion table carrying the intent for the same paths — the matrix states each declaration twice, in two forms, deliberately. Counting the bare copy as uninterpreted reports a fully-declared matrix as partially-understood, and **this plan's own matrix was the first casualty**: before the fix it reported 30 uninterpreted rows and could not have reached PASS however carefully it was authored. A matrix is one declaration set keyed by path, so a bare row whose path carries a verb anywhere in the same matrix is a second expression of a known declaration. Only a path with no marked row anywhere is genuinely intent-undeclared.

**Extraction fidelity.** The shipped shared `_extract_section` is fence-blind: **26 of the 117** matrices truncate at an in-fence `#` comment. Making the *shared* seam fence-aware was measured against both of its live consumers before adoption and **rejected on the measurement** — it changes `v4.14`'s Verification-Plan parse from 32 to 70 records, 39 of them spurious. The FCM path therefore ships its own section-scoped fence-aware extractor and the shared seam is left byte-identical. An odd fence count in an extracted body is retained as an exact truncation detector: on this corpus it fires on all 26 truncated sections and on 0 of the other 91.

**Cutover posture, stated explicitly.** Forward-only and **run-target-triggered** — the check fires only when the executor is pointed at a specific plan and never sweeps the corpus, so a historical plan is judged only when someone deliberately points the tool at it. After same-path reconciliation, **52 of 117** are coverage-PASS-eligible today, 42 carry a mix of marked and genuinely-bare rows, and 23 carry no marker at all; all 65 of the latter emit a **named** `fcm-rows-uninterpreted:<n>` SKIP rather than a silent zero, which is the row-granularity answer to the finding that "silence must not read as zero" had been implemented at section granularity only. **No historical plan is red-lined and no plan is re-authored by this release.**

**Self-application is non-vacuous and PASSES.** Replaying the shipped predicate against this plan and the live `origin/main..HEAD` range: body untruncated (6 fence markers, even), `declared=34 interpreted=34 obligations=13 excluded=4 conditional=0 uninterpreted=0 pathless=0`, and all **13** unconditional ADD obligations present as additions → **MATRIX-DELIVERED**. The earlier amendment's remedy — adding `EDIT` markers — would have produced exactly zero obligations, because `EDIT` rows never enter the obligation set.
- **The draft-state gate card.** A draft release pull request fails the new Gate-9 criterion; a ready one passes. The draft-state read folds into the phase that **already makes a host call inside the A8→GO window**, so the observation is real rather than a self-consumed record, and it adds zero API calls. Reading once at A8 *maximised* the window it was chosen to avoid — measured across 11 release pull requests at median 8 minutes, maximum 60, with GO inside it.
- **The contention-classifier card.** A **single extraction engine** serves both arms, so parity is by construction rather than by assertion. Three silent-empty channels exist; the guard must cover all three. Channel 3 — a whole-file delete of 8,629 bytes that exits 0 and parses to an empty list — defeats an anti-vacuity control that asserts non-empty *extraction*, because the collapse happens at *parse*. The branch arm is verified against a **constructed fixture**; the live cross-check arm against the two repopulated PR-less siblings runs at Stage 7.
- **The close-ordering gate card.** A milestone close with an absent action-item ledger fails rather than passing vacuously; a close with a clean ledger passes. The **SURFACE attestation clause** is implemented, and the dispatch guard is wired into a test arm — the drafted fix's own arms could not reach it. AC1 needs a **documentation edit as well as a tooling edit**: three milestone-close paths exist, tooling covers one, and the uncovered hub-direct path is the shape that closed the originating milestone with six open items. AC3 is **not release-buildable** and is routed to action item **AI-001**.

### Integration criteria

**INT-1 (matrix-delivery gate → draft-state gate):** the second allocator's `G-PR12` presumes the first's `G-PR11` lands; the live max `G-PR` ID is re-checked before allocation. Graded at Stage 8 Phase B under the per-criterion verdict enum.

The `T_DEPLOY − T_GO` positivity constraint is graded per-issue on the hub-emission read-back card's AC2, not as a CIAC — see the note under § Cross-Issue Acceptance Criteria.

### Release-level

- `core/deploy/deploy.sh --check` against an expected-red baseline pinned at branch cut, including doc-link integrity across modified markdown files. The comparison is a **`"  FAIL:"` line-set diff**, never the exit code: `--check`'s exit status mirrors operator-instance drift rather than real failures, so keying on it would produce a finding on every run.
- `core/deploy/deploy.sh --self-test` — the shared assertion-group entry point carrying both the deployment-emitter card's group DS and the close-ordering gate card's anti-vacuity arms (CIAC-2).
- `release/tools/compute-cycle-time.sh --self-test` and `release/tools/compute-dora-metrics.sh --self-test` — the failed-deploy legibility arms.
- Runtime-suite selection per the runtime-suite selection map, driven by the modified path set; one `test-run` event per suite.
- The six Cross-Issue Acceptance Criteria above, graded at Stage 9.

**No Stage 6, 7, or 8 spoke emits a `gate-outcome/plan-review-go` row.** That class fires **exactly once, at Stage 9, actor `operator`**. Emitting it earlier reproduces, in this release's own telemetry, the anchor-identity defect filed as a separate bug and deliberately kept out of this composition-locked milestone. Verified clean at Commit 0: **0** `gate-outcome` rows for this release.

---

## Rollback Strategy

A `git revert -m 1 <merge-sha>` on the single merge commit restores every code surface atomically. There is no migration, no data mutation, no external state, no schema versioning, and no corpus backfill. **CHEAP / Confidence HIGH.**

Per-card pre-merge rollback is equally cheap: each card is a distinct commit in a known sequence and can be dropped or amended before the pull request merges. All six cards are additive.

**One asymmetry, and it does not revert.** The deployment emitter writes rows into the operator-instance pipeline event log at deploy time. That log is **append-only Vital-retention**: a code revert does not un-write emitted rows, and a row can be redacted but never deleted. The correct posture is to **leave them** — they are honest records of a deploy that actually happened — and the plan says so rather than letting a reviewer assume the revert is total.

**Rollback trigger conditions:** (1) the new Gate-9 criterion fails a pull request that is genuinely ready, a false positive on the draft-state read; (2) the File Change Matrix gate reports a declared-but-absent ADD on a conformant plan, indicating a path-form taxonomy gap rather than a real omission; (3) the deployment emitter writes a row for a target that did not deploy, or suppresses one for a target that did.

**Rollback is operator-authorized.** No spoke initiates a rollback; a spoke surfaces the trigger and the operator renders it.

---

## Domain Practice Provenance

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-14, domain: governance }`

Sourcing-exempt: the entire File Change Matrix is internal platform artifacts. The domain is classified from the matrix — the dominant domain is **`governance`** (two pipeline stage documents, a gate schema, a spec, a how-to, and a skill surface), with **`software`** secondary for the six tool and test scripts plus `deploy.sh`. Sourcing exemption and domain classification are distinct properties; exemption from external sourcing does not make the release domain-less.

---

## Deviation Log

Deltas discovered after Stage 4 are recorded here rather than silently applied.

| ID | Delta | Class | Disposition |
|---|---|---|---|
| **D-1** | Stage 4's summary figure of "18 effective points" was the **raw** total, computed before the class was re-rendered `routine → novel` in the same comment. Under `novel`'s 1.15 weight the effective figure is **21**. | amend — arithmetic reconciliation | § Scope carries 21; band verdict PASS is unchanged (15–25). |
| **D-2** | `release/tools/compute-cycle-time.sh` and `release/tools/compute-dora-metrics.sh` moved from the **explicit non-scope block** into the unconditional matrix. | amend — scope, operator-rendered at Collective Review | Both listed in § File Change Matrix; the stale non-scope rows are removed rather than annotated, and the rationale is recorded in that section. |
| **D-3** | The plan-verification test script (EDIT) and nine `fcm-*` fixtures (ADD) entered the matrix. Stage 4's matrix carried neither, and the matrix-delivery gate card's AC4 cannot be satisfied without them. | amend — scope, operator-rendered at Collective Review | Enumerated individually as concrete paths. The recursion is deliberate: these ADD rows are judged by the gate they exist to test. |
| **D-4** | The plan-file row was **promoted** from CONDITIONAL to unconditional. Its condition — `D-C Branch Topology = SINGLE` — is rendered, so it has fired. | amend — matrix form | § File Change Matrix carries it in the unconditional block, with the promotion rule stated. |
| **D-5** | **Named residual, not fixed.** The emitter's `--release` slug is guarded by a **shape** check plus the event writer's **negative** version-grammar predicate. Neither positively resolves the slug against the release ledger, so a plausible typo still produces a permanent, unresolvable DORA occasion. | accepted residual | Recorded as **R14**. Positive resolution is a next-release candidate; it was declined here as scope the operator did not authorize at the gate. |
| **D-6** | **Characterization corrected.** The `deploy-rules-mirror` subtype was designed as *cleanup* — a subtype with no code path. It is not. It has an **enumerated 11-path target set** in `core/deploy/deploy.sh`, an invariant asserted by a live check, and an identical pair set in the blast-radius tool; `.claude/rules` is untracked, so the mirror exists **only by being deployed**. | amend — record, no behaviour change | The three-subtype emitting decision **stands**. The residual is recorded as a **coverage hole downstream of an open producer defect**, explicitly *not* equivalent to `deploy-helper`, which is genuinely target-less. Routed to next-release intake; when the producer ships, the subtype is re-evaluated rather than silently staying dark. |
| **D-7** | The **P₂** cross-release arm repopulated **0 → 2** since baseline (`release/reference-constant-integrity` and `release/skill-suite-conformance`, both without a pull request). | amend — measurement refresh | Neither intersects this matrix, so the contention verdict is unchanged. The contention-classifier card's live cross-check arm now has members and **must be run at Stage 7**. Roster re-measured at Stage 9 Phase A6.6. |
| **D-8** | **CIAC-6 authored after Stage 4.** The Stage-4 plan carried five CIACs; the sixth was authored at Collective Review against the systemic finding. | amend — release-scoped criterion | § Cross-Issue Acceptance Criteria carries six. |
| **D-9** | **The declined `--self-test` arm is re-decided and IMPLEMENTED.** Stage 5 declined a `decision/scope-lock`-specific omission arm on the ground that it had "zero discriminating power" because the verdict loop is class-uniform. Adversarial review falsified that by mutation testing, and this stage reproduced the result directly against the shipped entry point: with the predicate's subtype conjunct deleted, `--self-test` emits **exactly one** failure and it is the new arm — every pre-existing arm survives the mutation. The remaining objection was contention on `core/deploy/deploy.sh`; measured at Stage 6, **none of the three open sibling pull requests touching that file has a hunk anywhere near the assertion block**. | amend — scope, evidence-driven | `DE-4b` added to assertion group DE. The machine-readable matrix is **unchanged** — `core/deploy/deploy.sh` was already an unconditional row; only its Owning card(s) cell gains the hub-emission read-back card. No new path, no ADD, no allowlist row, no CI surface. |
| **D-10** | **Two of the read-back card's three source changes are BLOCKED at the edit gate and did not land.** `block-skill-direct-edit.sh` is in **enforce** mode and rejects `BLOCK-SKILL-EDIT-002` on `release/skills/release-hub/references/orchestration-playbook.md` and `BLOCK-SKILL-EDIT-001` on `release/skills/release-hub/SKILL.md` absent a `pmo-skill-editor` session sentinel. A `pmo-skill-editor` Mode A session was opened; its own guardrail forbids synthesizing the sentinel to clear the gate and directs an enforce-mode block to the Hook-Blocked → User-Side Handoff convention instead. | **open — blocked, not deferred** | Surfaced to the hub with the verbatim replacement text for both files. The dependent package rebuild (`packages/release-hub.skill{,.sha256}`) is blocked behind them. **Note:** that package is **already stale on `origin/main`** independently of this release — the rebuild clears a pre-existing Check 7 failure as well as carrying this card's change. |
| **D-11** | **Two fixtures beyond the nine scope-locked at Collective Review entered the matrix, and the ADR row was promoted out of the CONDITIONAL block.** `fcm-glob.md` and `fcm-truncating.md` cover two arms the scope-lock's nine could not reach: the glob/placeholder path-form taxonomy, and extraction fidelity across an in-fence `#` comment. Both were required by A6.5 findings the same gate rendered (FMF-3, PRF-1). The ADR row's condition — `D-ADR-Disposition = author-retroactively` — is rendered and the record is authored, so it is promoted with its allocated concrete path. | amend — scope, evidence-driven | § File Change Matrix carries thirteen unconditional ADDs. The recursion holds: these ADD rows are judged by the gate they exist to test, and the promoted ADR row is the AC5 obligation. |
| **D-12** | **`core/config/allowlists/script-execution-allowlist.txt` is edited, but NOT on its declared condition.** Its Stage-4 condition was "any new tracked `*.sh` shipping"; that condition did not fire. The edit adds the four-form rows for `release/tools/compute-dora-metrics.sh` and `core/deploy/tests/test_deploy_sandbox.sh`, authorized by the operator at the deployment-emitter card's gate and recorded there but never applied. **The authorized path for the second tool was recorded as `release/tools/tests/test_deploy_sandbox.sh`; no such file exists.** The repository holds exactly one file of that name, at `core/deploy/tests/test_deploy_sandbox.sh`, and it is the deploy-sandbox safety proof — which is what an edit to `core/deploy/deploy.sh` obliges a spoke to run. Rows were written at the real path; a row at the recorded path would have been inert and would have unblocked nothing. | amend — scope, operator-authorized, path corrected | Row promoted to the unconditional block as an EDIT. Both tools now carry the four invocation forms, mirroring `compute-cycle-time.sh`. **The path correction is surfaced for operator confirmation rather than treated as settled.** |

---

## Change Description

*Authored at Stage 6 Phase C1 by the final Engineering spoke, once the full set of landed cards is known. It is committed on the release branch before the pull request is marked ready-for-review, so the section is visible in the pull-request diff at Stage 9 Plan Review.*

**Owed sub-sections:** Outcome · Issues resolved · Key decisions · Reversibility · Downstream impact · Cross-references.

---

## Verification Evidence

*Populated at Stage 6 Phase C4 and refreshed at Stage 7 and Stage 8. Emitted in the `verify-release-plan.sh --format=md` shape.*

---

## Deployment Execution Log

*Authored at Stage 12 Phase B5. Not written by Engineering.*
