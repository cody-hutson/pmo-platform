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
| **Version** | slug-only pre-claim per ADR-092; recorded determination **v4.27**, **PROVISIONAL** — re-rendered at Stage 6; see the note below |
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

**D-Version is `v4.27` and is PROVISIONAL. It read `v4.25` at Engineering Commit 0 and was re-rendered at the final Engineering commit.** It is a *recorded determination*, not a reservation: it binds only at the Stage-12 atomic compare-and-swap per ADR-092, and the plan file, the branch, and all hub state key on the **milestone slug**, never on the version. **Nothing renamed** — that is the property slug-primary identity exists to deliver, and this re-render is precisely the case it was designed for.

**Why it moved: two sibling releases claimed and shipped while this one was in Engineering.** The reference-constant-integrity release took **`v4.25`** and the corpus-tolerance-and-hygiene release — the in-flight sibling this plan's contention map already names — took **`v4.26`**. Both are tagged and both carry a mainline release-ledger row. **The Commit-0 note recorded that the corpus-tolerance-and-hygiene sibling "claims no slot"; that was true when written and is false now**, and it is corrected here rather than annotated, because a plan carrying a superseded freeness claim is indistinguishable from one whose claim still holds.

**Re-verified at the final Engineering commit** against freshly-fetched refs, on the same three independent claimed-set arms — each carrying a live sensitivity control that returned non-zero on a known-taken slot, and a specificity control proving the probe is exact rather than prefix-matching. **Origin tags:** subject `v4.27` → 0; sensitivity `v4.26` → 1; specificity — the exact pattern `v4.2` matches nothing while the glob `v4.2*` matches 7, so the probe is exact and the instrument is demonstrably live. **Published GitHub Releases:** subject 0 of 168; sensitivity `v4.26` → 1. **Mainline release ledger at the remote tip:** subject 0 of 27 `v4.x` rows; sensitivity `v4.26` → 1 and `v4.25` → 1. All three place the anchor at **`v4.26`** and **`v4.27` free**. **That reading was true at the final Engineering commit and is superseded as of the Stage-6 reconciliation merge — see D-17.** The anchor is now `v4.27` and the next free slot is `v4.28`. The measurement above is left standing rather than rewritten, because it was correct against the tree it was taken on; what changed is the population, not the probe.

**One sibling holds an advisory claim on the same slot, and this plan deliberately does not step around it.** The path-and-citation-reconciliation release has re-rendered its own provisional determination to `v4.27` on an unmerged branch. Per **ADR-115** an unmerged branch claim is **advisory, not binding**: next-free is `anchor(origin/main) + 1`, never `max(claimed_set) + 1`. Reserving `v4.28` to dodge the sibling would leave a permanent hole in the version sequence — and a gap blocks the repository, whereas a duplicate inconveniences one branch and is resolved mechanically at the Stage-12 atomic claim. The collision is therefore **recorded, not avoided**; whichever release reaches the compare-and-swap second re-derives there. A further re-determination at Stage 12 is expected, not exceptional, and **no version literal ships in this release's code**.

**That sibling reached the compare-and-swap first, and this release is the one that re-derives.** The path-and-citation-reconciliation release merged to the mainline during the Stage-6 reconciliation; its claim is no longer advisory but binding, carrying a tag and a mainline ledger row. This is the designed outcome of the rule above rather than a surprise — the slot was never reserved, the collision was recorded in advance, and slug-primary identity means **nothing renames**: no branch, no plan filename, and no hub state keys on the number. The determination is **not** re-rendered here, deliberately: it binds at the Stage-12 atomic compare-and-swap, and re-rendering it mid-branch would replace one point-in-time claim with another that the next sibling merge can invalidate just as fast. Recorded in D-17 and surfaced for the operator instead.

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
docs/module-apis.md
release/tools/automated-closeout.sh
.github/corpus-home-tolerance.arming
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
release/ADRs/ADR-135-a-gate-ships-armed-by-a-committed-default.md
release/ADRs/README.md
core/ADRs/README.md
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
| `release/tools/check-line-range-overlap.py` | EDIT | the contention-classifier card — the branch input mode; **plus** the Stage-7 stale-read regression guard, `--self-test` Group-E arm **E10** (see **D-22**) |
| `docs/module-apis.md` | EDIT | the contention-classifier card — the tool-description phrase the branch input mode made true (ratified at the Stage-6 reconciliation, see **D-13**) |
| `release/tools/automated-closeout.sh` | EDIT | the close-ordering gate card — close-ordering; **plus** the Stage-7 corpus-home resolver repair, CH-1/CH-2 (see **D-20**) |
| `.github/corpus-home-tolerance.arming` | EDIT | Stage-7 remediation — the arming-posture sentinel flipped `pending` → `armed`, as rule R8 requires of the change that lands the seam (see **D-20**) |
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
| `release/ADRs/ADR-135-a-gate-ships-armed-by-a-committed-default.md` | **ADD** | the matrix-delivery gate card — AC5, the v4.03 record authored retroactively (promoted from CONDITIONAL, see **D-11**) |
| `release/ADRs/README.md` | EDIT | Stage-7 remediation — the GENERATED ADR index, regenerated so `ADR-135` has its row (see **D-19**, **D-21**) |
| `core/ADRs/README.md` | EDIT | Stage-7 remediation — the sibling ADR index, carrying the `renumber-adr.py` § Renumber-log row for the 133 → 134 move (see **D-21**) |
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

- **The ADR row fired: `D-ADR-Disposition = author-retroactively` is rendered, and the record is authored.** The number was deliberately unallocated at Stage 5 — allocating before the disposition is rendered writes a path into the machine-readable set that can never match, precisely the false-positive class this card's gate exists to prevent. Allocated at Engineering time via `release/tools/renumber-adr.py --next-free`, global-monotonic across **both** `core/ADRs/` and `release/ADRs/`: the mainline anchor is `ADR-132`, so next-free is **`ADR-135`**. Per ADR-115 an unmerged branch claim is **advisory** and next-free is `anchor(origin/main) + 1`, never `max(claimed_set) + 1` — a gap blocks the repository, a duplicate inconveniences one branch and is tooled at Stage 12. All four open sibling branches were checked and none claims `133`.
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
| **D-10** | **Two of the read-back card's three source changes WERE blocked at the edit gate and did not land during Engineering.** `block-skill-direct-edit.sh` is in **enforce** mode and rejected `BLOCK-SKILL-EDIT-002` on `release/skills/release-hub/references/orchestration-playbook.md` and `BLOCK-SKILL-EDIT-001` on `release/skills/release-hub/SKILL.md` absent a `pmo-skill-editor` session sentinel. A `pmo-skill-editor` Mode A session was opened; its own guardrail forbids synthesizing the sentinel to clear the gate and directs an enforce-mode block to the Hook-Blocked → User-Side Handoff convention instead. | **resolved — landed via the sanctioned minter** | **Landed at commit `b22701eb`.** All three source changes and the dependent package rebuild are in the branch as one four-file commit: `release/skills/release-hub/SKILL.md`, `release/skills/release-hub/references/orchestration-playbook.md`, `packages/release-hub.skill` and `packages/release-hub.skill.sha256`. The unblocking mechanism was the sanctioned sentinel minter `core/deploy/tools/start-skill-editor-session.sh`, which minted a real session on the first attempt: **zero `BLOCK-SKILL-EDIT` firings**, no sentinel forged, no `CLAUDE_HOOK_BYPASS`, no second-tool re-attempt. The refusal recorded in the finding column is *why* that minter exists — the block was surfaced rather than worked around, and the tool was built in response. **Note:** the rebuild also clears the pre-existing Check-7 staleness this package carried on `origin/main` independently of this release. That clearance is now measured, not predicted — see Verification Evidence row 4, where the surviving Check-7 FAIL names `pmo-skill-refiner`, a skill this branch does not touch. |
| **D-11** | **Two fixtures beyond the nine scope-locked at Collective Review entered the matrix, and the ADR row was promoted out of the CONDITIONAL block.** `fcm-glob.md` and `fcm-truncating.md` cover two arms the scope-lock's nine could not reach: the glob/placeholder path-form taxonomy, and extraction fidelity across an in-fence `#` comment. Both were required by A6.5 findings the same gate rendered (FMF-3, PRF-1). The ADR row's condition — `D-ADR-Disposition = author-retroactively` — is rendered and the record is authored, so it is promoted with its allocated concrete path. | amend — scope, evidence-driven | § File Change Matrix carries thirteen unconditional ADDs. The recursion holds: these ADD rows are judged by the gate they exist to test, and the promoted ADR row is the AC5 obligation. |
| **D-12** | **`core/config/allowlists/script-execution-allowlist.txt` is edited, but NOT on its declared condition.** Its Stage-4 condition was "any new tracked `*.sh` shipping"; that condition did not fire. The edit adds the four-form rows for `release/tools/compute-dora-metrics.sh` and `core/deploy/tests/test_deploy_sandbox.sh`, authorized by the operator at the deployment-emitter card's gate and recorded there but never applied. **The authorized path for the second tool was recorded as `release/tools/tests/test_deploy_sandbox.sh`; no such file exists.** The repository holds exactly one file of that name, at `core/deploy/tests/test_deploy_sandbox.sh`, and it is the deploy-sandbox safety proof — which is what an edit to `core/deploy/deploy.sh` obliges a spoke to run. Rows were written at the real path; a row at the recorded path would have been inert and would have unblocked nothing. | amend — scope, operator-authorized, path corrected | Row promoted to the unconditional block as an EDIT. Both tools now carry the four invocation forms, mirroring `compute-cycle-time.sh`. **The path correction is surfaced for operator confirmation rather than treated as settled.** |
| **D-13** | **One file outside the frozen File Change Matrix was edited.** `docs/module-apis.md` carries a one-line tool-description update ("cross-PR" → "cross-PR / cross-branch") landed by the contention-classifier card alongside the capability that made it true. | amend — scope, **ratified** by the operator at the Stage-6 reconciliation | **Closed, not open.** The path is now declared in § File Change Matrix as an **EDIT** row owned by the contention-classifier card, in both the machine-readable fence and the companion intent table. Declaring it in both is required rather than tidy: a bare fence path carrying no intent verb parses as *uninterpreted*, which drops the `fcm-delivery` coverage record from PASS to SKIP — so a half-declaration would have degraded the very gate this release ships. `G-PR11` is unaffected either way; it grades declared **ADD** obligations and EDIT rows never enter the obligation set. The reason to declare it is the **outbound** half of scope-boundary verification (Stage 7 DT / Stage 8 QA), which reads the diff against the matrix and would otherwise render an undeclared file as a scope breach rather than as a doc kept honest. |
| **D-14** | **`release/references/how-to/hub-spoke-bridge.md` is declared EDIT by three cards; one of the three has now landed, two have not.** At Engineering close all three were undelivered and the file was byte-unchanged across the branch. For the close-ordering card that was **half of AC1**: three milestone-close paths exist, the tooling edit covers the automated one, and the uncovered hub-direct path at Procedure 7 Step 5 is the shape that closed the originating milestone with six open items — the one path no script can reach. | **partially resolved** — the close-ordering obligation ratified and landed; the read-back and draft-state obligations remain open | The file was held read-only for the whole of Engineering, so Engineering did not write it. **The operator unfroze it at the Stage-6 reconciliation for the close-ordering obligation specifically, and that edit is landed:** Procedure 7 Step 5 now states the 7a ordering and the three-valued disposition at the close action itself, citing the owning standard rather than restating its predicate. AC1 is therefore satisfied in substance and not merely in letter — the incident's own path is covered. **Still open:** the read-back card's Procedure 4a obligation and the draft-state card's Procedure 5 obligation are undelivered, so **CIAC-5 will read two of its three obligations absent** and should be graded against that, not against a blanket absence. Those two need the same operator disposition the close-ordering obligation just received: authorize the edits, or accept the residual with the coverage gap named. |
| **D-15** | **The plan-verification executor cannot be invoked by an agent, and Engineering declined to unblock itself.** `release/tools/verify-release-plan.sh` — the tool the Stage-6 §C4 contract names as the emitter of this section, and the tool this release extends most heavily — has **no row** in `core/config/allowlists/script-execution-allowlist.txt`, so `BLOCK-DESTRUCTIVE-022` refuses to execute it. Adding the four-form row would have unblocked it in one edit. | **open — surfaced, not self-authorized; reproduced live at Stage 7** | Engineering did **not** add the row: an allowlist row is a governed change and the two rows this release does add were operator-authorized at a named gate (**D-12**). The Verification Evidence section is authored in the executor's shape and every check is run through a registered entry point instead, with the substitute instrument named per row. **This is the same shape as D-12** — a tool the pipeline depends on that nobody registered — and it wants the same operator disposition. **Reproduced at Stage-7 remediation:** `BLOCK-DESTRUCTIVE-022` fired again on this tool, and the remediating spoke likewise declined to self-authorize a row; its edit to the executor is covered by CI's own invocation of the suite instead. Measured both sides: `verify-release-plan` returns **0** rows in branch source **and 0** in the deployed allowlist — so this row is genuinely open, not merely undeployed. |
| **D-19** | **One file outside the frozen File Change Matrix was edited at Stage-7 remediation.** `release/ADRs/README.md` — the GENERATED ADR index — was regenerated because the ADR-number integrity gate reported `MISSING ADR-135`: the record landed on this branch without an index pass, leaving 38 rows against 39 records. | amend — scope, Stage-7 gate remediation, **surfaced for operator confirmation** | Produced by the gate's own named remedy, `python3 release/tools/generate-adr-index.py --write`, and committed unedited; `--verify` then reports SCANNED 39 / ROWS 39 / COUNT 0. No row is hand-authored, because the gate classifies a hand-edited cell as `DRIFT`. Declared in § File Change Matrix in **both** the machine-readable fence and the companion intent table, on the **D-13** precedent and for the same reason: the outbound half of scope-boundary verification reads the diff against the matrix, and an undeclared path renders as a scope breach rather than as an index kept honest. Declared **EDIT**, so it never enters the `G-PR11` obligation set. |
| **D-20** | **This release ARMED the corpus-home tolerance suite, and the resolver it grades is repaired here rather than disarmed.** The suite's failure was first filed as inherited on the strength of a `git diff --name-only` scan for files named `corpus-home`, which returned nothing. **That probe measured the wrong population.** The arming detector counts instance-resolution TOKENS IN THE RESOLVER, not filenames. Re-measured with the suite's own `ARMING_NEEDLE` over the non-comment lines of `release/tools/automated-closeout.sh`: `origin/main` carries **0**, this branch carried **4**, all four attributable to this release's own hub-state work. The CH-1/CH-2 resolver defect is genuinely **pre-existing**; the suite sat in `PENDING-SEAM` — structurally green, unable to redden a PR before a seam landed — and **this release armed it**. `release-tooling-smoke` is `success` on the mainline's last five runs including the merge-base, and the check is not branch-protection-required, so merging as-is would have turned a currently-green job red on the mainline with nothing to stop it. | amend — scope, Stage-7 gate remediation, **operator-decided: fix the resolver, do not disarm the detector** | `--check-paths` now resolves through an explicit corpus home in three states: in-tree corpus present → repo-homed (byte-identical to prior behaviour, so no ordinary checkout or CI runner is affected); in-tree absent and instance corpus present → instance-homed (**CH-2**); neither present → a per-path `N/A` record for every corpus label and exit 0 (**CH-1** + **CH-4**). `.github/corpus-home-tolerance.arming` flipped `pending` → `armed` in this same change, as **R8** requires, and is deliberately NOT flipped back — that is the state R8 warns about, where a later revert loses tolerance coverage with nothing recording it. Both arms recorded with non-empty extraction: fixture A exits 0 with a per-path record for all four labels inside the instance home and no `N/A` token; fixture B exits 0 with a per-path `N/A` for all four. Suite verdict moves **FAIL (R3, R5, R8)** → **PASS-SEAM-LANDED**, all eight rules green, posture aligned. `ARM_SURFACE_N` moves **0 → 10**, closing the asymmetry in which the release armed a corpus-path suite while touching only hub-state resolution. CH-3 held under a dedicated specificity arm: a 3-of-4 in-tree corpus **with an instance path set** still exits 1, so a set-but-absent instance path cannot convert a genuine resolution defect into a tolerated absence. Both paths declared in § File Change Matrix in **both** the fence and the intent table, per the **D-13** precedent; declared **EDIT**, so neither enters the `G-PR11` obligation set. |
| **D-21** | **The mainline claimed ADR-133 mid-session, so this release's ADR renumbered to 134.** Not a planned delta and not one of the Stage-7 fixes: `origin/main` advanced from `320cfa27` to `f35a3b8c` while Stage-7 remediation was in flight, and a sibling release landed a **different** ADR-133 (`the-material-edit-test-names-an-effect-not-a-field`) on the mainline. This branch's unmerged `ADR-133-a-gate-ships-armed-by-a-committed-default` collided, and `release/ADRs/README.md` conflicted on the merge because two records claimed one row. | amend — forced by mainline movement, **surfaced for operator confirmation** | Who yields is not a judgement call: ADR numbers are one global sequence across `core/ADRs` and `release/ADRs`, binding anchors on the **mainline**, and an unmerged claim is advisory — it reserves nothing. The mainline's 133 is merged and this branch's was not, so this branch moved; renumbering the merged record would have rewritten mainline history and pushed churn onto a release that already shipped. Resolved with the sanctioned tool, never by hand: `check-adr-numbers.py` reported the duplicate, `renumber-adr.py --detect` independently classified this claim `DUPLICATE / MAINLINE / next=134`, and `--next-free` returned **134**. The move ran under `--renumber 133 134 --apply` — git mv of the record, **8** citations rewritten across the record and this plan, both ADR indexes regenerated by `generate-adr-index.py`, a provenance Status note written, and **R6** verifying zero dangling in-scope citations. The merge's index conflict was resolved by taking the mainline row and letting regeneration re-add this record at its new number, so the index is derived rather than hand-merged. Post-state: `check-adr-numbers.py` **PASS — 134 ADRs, contiguous 001..134, no duplicates**. `core/ADRs/README.md` is newly declared in § File Change Matrix as **EDIT** because the tool writes its § Renumber log there. |
| **D-22** | **The stale-read fix shipped with no regression guard, and the fixture structurally could not express the failing state.** `885e3229` repaired a silent stale-read in `resolve_member` — the bounded PR fetch was gated on `not sha`, so a `refs/pull/<N>/head` that was present but BEHIND its upstream was never refreshed and the tool classified an OLD revision at exit 0. The fix is correct and is verified by live measurement. What it did not carry is an arm that fails when it regresses: the hermetic fixture builds every ref with `git update-ref`, so its refs are **fresh by construction** and the failing state was inexpressible. The suite could not have caught the defect, and could not catch its return. In a tool whose entire defect history is *silent wrong answers*, that is one refactor from recurrence. | amend — scope, Stage-7 remediation, **test-only; no production behaviour change** | **A tenth Group-E arm, `E10`, constructs the state the fixture could not.** A two-revision head `release/epsilon` is added (revision **A** edits lines 60-62; revision **B** additionally edits 41-43, which OVERLAPS `release/alpha`), a bare "remote" repo is created **inside the fixture tmp** holding `refs/pull/44/head` at **B**, and the local `refs/pull/44/head` is seeded at **A**. Both arms recorded with non-empty extraction: **CONFORMANT** — the shipped resolver refreshes the stale ref and classifies at **B**, ranges `[(38,46),(57,65)]`, 393 bytes, verdict `line-range-overlap`, exit 0; **DEFECTIVE** — the same call with the fetch skipped reads **A**, ranges `[(57,65)]`, 237 bytes, verdict `append-pattern`. The second edit is what makes the arm bite: the stale read does not merely report old line numbers, it **downgrades a real contention to the benign class at exit 0**. `allow_fetch=False` is not an approximation of the pre-fix gate but is EQUIVALENT on this input — for a ref that is PRESENT, both skip the same fetch and resolve the same ref. **Negative control, run rather than asserted:** the pre-fix conditional was restored in a scratch copy by an asserted transform (an unmatched pattern aborts, so the control cannot read green for the wrong reason); that copy's `--self-test` exits **3** with **three** E10 assertions naming the stale revision, and **every other arm — E1-E9, Groups A-D — still passes**, so the mutation is observed by the new arm and by nothing else. `resolve_member` is **untouched**: its AST source segment is byte-identical between `HEAD` and the worktree (sha256 `5d3b0976...`), as are `main`, `extract_patch`, `classify_overlap_class` and `build_diff_argv`; the same probe correctly reports `run_self_test` and `_build_fixture` as DIFFERENT, so it can tell them apart. **The suite's no-network contract holds and is now asserted rather than assumed:** the remote is a filesystem path, so `git fetch` uses the local transport, and the arm itself checks that the configured URL resolves inside the fixture tmp. Confirmed empirically — the full suite exits 0 under `GIT_ALLOW_PROTOCOL=file`, with a sensitivity arm showing an `https` fetch REFUSED under that setting (`transport 'https' not allowed`) and a specificity arm showing the same fetch failing at DNS without it, so the pass is a property of the suite and not of an inert variable. **The machine-readable matrix is unchanged** — `release/tools/check-line-range-overlap.py` was already an unconditional row declared in **both** the fence and the intent table; only its Owning card(s) cell gains this scope. No new path, no ADD, no fixture file, no allowlist row, no CI surface. Group-E arms move **9 → 10**; `run_self_test` assertion sites move **70 → 83**. |
| **D-18** | **The two allowlist rows this release authorizes are in branch source but absent from the DEPLOYED allowlist the hooks actually read — the runtime half of the change has not happened.** This reconciles a contradiction the hub carried for two stages: one spoke ran a governed script fine while two were blocked on it. The cause is that hooks resolve their allowlist from the **deployed** copy, never from branch source, so a source-only row changes nothing at runtime until a deploy lands it. | **source-remediated, runtime-pending** | Measured per script as source-count / deployed-count: `test_deploy_sandbox` **5 / 0** and `compute-dora-metrics` **5 / 0** — both authorized at **D-12**, both present in source, neither deployed. Control arm `compute-cycle-time` reads **4 / 4**, so the probe is not stuck on zero. **One correction to the finding as it reached this stage:** `start-skill-editor-session` was reported deployed-count 0; it measures **6 / 6**, i.e. fully deployed. The runtime evidence agrees and is what makes the measurement falsifiable rather than asserted — that minter is exactly what landed **D-10** with zero hook firings, which a genuinely undeployed row could not have done. Every count here predicts the runtime outcome actually observed this stage: `automated-closeout` (deployed 5) ran, `verify-release-plan` (deployed 0) was refused. **Operator disposition needed:** deploy the allowlist so the authorized rows take effect, or accept that the two authorized tools stay agent-unreachable until the next deploy. No agent self-authorized a row. |
| **D-17** | **The recorded version determination `v4.27` is superseded; the slot was taken by a third sibling during the Stage-6 reconciliation.** The path-and-citation-reconciliation release merged to the mainline mid-reconciliation and claimed `v4.27` — tag present, mainline ledger row present — converting the advisory branch claim this plan already recorded (§ Header) into a binding one. Re-verified at the remote tip on both arms the brief names: origin tags place `v4.27` taken, and the mainline release ledger read at `origin/main` (never the worktree copy) carries a `v4.27` row. The anchor is now `v4.27`; next free is **`v4.28`**. The ledger's `v4.99` row is the fabricated specificity control the corpus documents and is excluded from the anchor, not treated as a claim. | **surfaced — recorded, NOT re-versioned** | **No version was re-rendered, deliberately.** Per ADR-092 the determination binds only at the **Stage-12 atomic compare-and-swap**, and this branch ships **no version literal in code**; per ADR-115 next-free is `anchor(origin/main) + 1`. Re-rendering here would swap one point-in-time claim for another that the next sibling merge can invalidate equally fast — the same churn D-Version already absorbed twice. Slug-primary identity means **nothing renames**: not the branch, not this filename, not hub state. **Operator disposition needed only if a number is wanted before Stage 12**; otherwise the compare-and-swap re-derives it and this row is the audit trail that the collision was seen rather than missed. |
| **D-16** | **The schema's own version labels were inconsistent mid-branch, and are reconciled by the final Engineering slice.** The first Gate-9 addition on this branch labelled its changelog block with a version number the mainline had already spent on an unrelated refinement, and left `**Schema version:**` unbumped — so the file briefly carried two blocks reading the same version and a header naming neither addition. The second addition re-derived correctly and bumped the header, and rightly declined to relabel a sibling's committed block. | amend — record reconciliation, no behaviour change | One block on this branch carrying **both** additions, duplicate heading removed, sequence gap-free and duplicate-free from the mainline value. Verified with a parser over the labels — **not** a substring scan — run against the pre-fix file as its control: the control reports the duplicate and a non-descending sequence, the subject reports neither. No criterion ID, column, row, or type moved. |

---

## Change Description

*Authored at Stage 6 Phase C1 by the final Engineering spoke, once the full set of landed cards was known.*

### Outcome

Six controls in the release pipeline were declared but never observed anything. This release makes each of them observe, and — the part that distinguishes it from the four prior attempts at the same class — **demonstrates each one failing** on a fixture with its observing step removed before trusting it green.

Concretely, after this release: a deploy emits one `deployment-status` row per target and a failed deploy raises the change-failure rate instead of improving it; the hub's Stage-9 emission is read back as a `POST == PRE + 1` delta rather than a non-zero absolute; the approved File Change Matrix's declared ADDs are compared against the merged diff, with an absent matrix reading MATRIX-UNDELIVERED rather than N/A; a draft release pull request cannot be granted GO, on two independently-taken observations rather than one self-consumed record; the cross-branch contention classifier reports what it could not read instead of reporting clean; and the Procedure 7a action-item gate is **wired to the close it guards** — it had never once run.

The release's own definition of done is CIAC-6, and it is met per-control with both arms recorded.

### Issues resolved

Six cards, one branch, one merge, in the approved sequence:

| Card | What it now does that it did not |
|---|---|
| the deployment-emitter card | emits `deployment-status` per target; a totally-failed deploy yields `N/A` cycle time and 100 % change-failure rate, not a measured duration and 0 % |
| the hub-emission read-back card | reads its own emission back as a stage-scoped delta; **all three source edits landed** at `b22701eb` via the sanctioned skill-editor minter — see **D-10**, resolved |
| the matrix-delivery gate card | grades declared-vs-delivered matrix ADDs; ships `G-PR11`, a glob path-form arm, and eleven fixtures |
| the draft-state gate card | ships `G-PR12`; binds `isDraft` at the GO instant, on a Phase A8 read-back plus an independent Phase A9 gate-instant read |
| the contention-classifier card | classifies a PR-less branch arm, and a read it could not perform is no longer a benign verdict |
| the close-ordering gate card | dispatches the Procedure 7a HARD GATE immediately before the milestone close, three-valued, with the SURFACE attestation clause implemented |

### Key decisions

- **The close-ordering gate blocks the close by being *guarded*, not by being *early*.** A dispatch line at the correct position carrying a permissive guard passes every ordering assertion and blocks nothing. The control therefore executes the two shipped dispatch lines lifted verbatim from the tool's own text, with a permissive variant as its negative control.
- **SURFACE states require attestation to pass, and the attestation is emitted.** The originating incident's own state at close was `NOT-RECORDED`. A gate that passes that state silently would not have caught the incident it was built for, so the two SURFACE states now take a closed-enum operator attestation naming which of the two causes holds, and that attestation lands as a `decision` row. It does **not** clear an open row — an unresolved commitment is dispositioned, never attested away.
- **AC3 of the close-ordering card is not release-buildable** and is routed to action item **AI-001** rather than graded. Stage 8 records it `OUT-OF-SCOPE — routed to AI-001`, never NOT MET.
- **The warn-mode rationale was re-derived after its original ground turned out to be an empty population.** The claim that a blocking SURFACE state "would fail every CI close" was measured false: no CI workflow runs an apply-mode close at all. The decision survives on the governing standard; the argument for it was replaced rather than left standing, and the corrected form is stronger — because CI never executes the close dispatch, the constructed fixture is the only automated execution that path will ever get.
- **The version determination moved twice and nothing renamed.** Identity is slug-primary, which is what let two siblings claim and ship mid-build without touching this branch, this plan's filename, or any hub state. The current determination records an advisory collision with a third sibling rather than reserving above it.

### Reversibility

**CHEAP / Confidence HIGH.** A single `git revert -m 1 <merge-sha>` restores every code surface atomically. No migration, no data mutation, no external state, no schema versioning, no corpus backfill; all six cards are additive and per-card pre-merge revert is equally cheap.

**One asymmetry, and it does not revert:** the deployment emitter writes rows into an append-only Vital-retention event log at deploy time. A code revert does not un-write them. The correct posture is to leave them — they are honest records of a deploy that happened. Recorded as **R12**.

### Downstream impact

- **Stage 13 close-out gains a phase that can halt it.** A release reaching `--apply` with an unresolved action item, or with no ledger and no attestation, does not close. This is the intended behaviour and it fires on this very release: its own ledger carries one open row.
- **`release-executor` Mode D wraps the close-out tool** and must surface a BLOCK rather than retry, and must thread the new attestation flag when the operator supplies one.
- **Stage 9 gains two criteria** (`G-PR11`, `G-PR12`). Both carry the standard introducing-release exemption, so this release's own Stage 9 is graded under the pre-existing checks.
- **One skill package changed** — `packages/release-hub.skill{,.sha256}`, rebuilt at `b22701eb` once the skill-source edits landed through the sanctioned minter (**D-10**). That rebuild clears the release-hub staleness the mainline carried independently of this release; the Check-7 FAIL that survives names `pmo-skill-refiner`, whose source this branch does not touch.

### Cross-references

Governing surfaces this release implements against, each cited rather than restated: the action-item standard's § 4 routing-point-5 hard-gate obligation and its three-valued verdict; the hub bridge's § Procedure 7a predicate, decision table, and attestation clause; the gate-criteria schema's Gate 9 registry and its own versioning rule; the Stage-4 File Change Matrix authoring contract; and the release-readiness scan's § 5.1 draft-state reconciliation. Decision records: **ADR-092** (slug-primary release identity), **ADR-115** (an ADR or version claim binds at merge, not at authoring), **ADR-100** (event-log pipe grammar), and the newly authored **ADR-135**.

---

## Verification Evidence

*Populated at Stage 6 Phase C4 by the final Engineering spoke; refreshed at Stage 7 and Stage 8.*

**Emitter note, stated rather than glossed.** This section is authored in the `verify-release-plan.sh --format=md` shape but was **not emitted by that tool**: the executor is not registered in `core/config/allowlists/script-execution-allowlist.txt`, so `BLOCK-DESTRUCTIVE-022` refuses to run it, and Engineering declined to add its own allowlist row. Every check below was therefore run through an entry point that *is* registered, and each row names the instrument it actually used. See **D-15** — this is the same shape as **D-12**: a tool the pipeline depends on that nobody registered.

### Release-level

| # | Check | Instrument | Result |
|---|---|---|---|
| 1 | Close-out tool self-test (carries the Procedure 7a anti-vacuity group) | `automated-closeout.sh --self-test` | **PASS** — suite green, group AI included |
| 2 | Deploy self-test (carries assertion group DS + group DE) | `core/deploy/deploy.sh --self-test` | **PASS**, exit 0 — DS-1..DS-10 green, including the two DS-10 control arms |
| 3 | Procedure 7a predicate regression suite | `release/tools/tests/test_action_item_gate_predicate.sh` | **PASS** — 23 assertions, 0 failures, G1–G5 all green |
| 4 | `deploy.sh --check` FAIL-line set vs. baseline | `core/deploy/deploy.sh --check`, keyed on the **verdict-position** `FAIL:` line set and **never** on the exit code. Verdict position means the token in the verdict column of a timestamped log line, matched as `^\[HH:MM:SS±ZZZZ\]\s+FAIL:`. The earlier `"  FAIL:"` keying is **withdrawn**: it counts a per-skill detail line *and* its own roll-up as two findings | **2 FAIL lines, zero of them new, both inherited.** (i) Check-7 skill-package staleness on **`pmo-skill-refiner`**; (ii) `count-structure` drift at `core/disciplines/orchestration-mechanisms.md:26`, `core/standards/version-field-semantics.md:87`, `release/references/how-to/intake-style-guide.md:266`. **The earlier structural proof rested on a false premise and is replaced.** It asserted the branch changes **0** files under `core/skills/` / `release/skills/` / `operations/skills/` / `packages/` (control: 26 changed files). Re-measured against `origin/main` at `a7907fcb`: the branch changes **4** such files — `release/skills/release-hub/SKILL.md`, `release/skills/release-hub/references/orchestration-playbook.md`, `packages/release-hub.skill`, `packages/release-hub.skill.sha256` — out of **32** changed files total. The correct proof is not absence but **non-intersection**: the one skill surface this branch touches is `release-hub`, and touching it *cleared* that package's staleness rather than causing any (**D-10**); neither surviving FAIL names a path in this branch's change set. Attribution was measured, not asserted — `pmo-skill-refiner` returns 0 hits against the 32-file set with `release-hub` as the sensitivity control at 4, and the three `count-structure` paths return 0 with `gate-criteria-spec.md` as the sensitivity control at 1 |
| 5 | Shell syntax + static analysis on every edited script | `bash -n`, `shellcheck -S error` | **CLEAN** |
| 6 | File Change Matrix self-application (the reflexive `G-PR11` run) | declared-ADD set from this plan's own intent table vs. `git diff --diff-filter=A origin/main...HEAD`, compared as **sets** with `comm` over a plain lexical sort | **MATRIX-DELIVERED** — 13 declared unconditional ADDs, 13 delivered; declared-but-absent **empty**, delivered-but-undeclared **empty**. **Control:** dropping one declared row makes the instrument report that row, so the two empties are a property of the diff and not of an inert comparison |
| 7 | Doc-link integrity across modified markdown | `deploy.sh --check` Check 14 (inside run 4) | **CLEAN** — zero link findings in the FAIL set |
| 8 | Cross-Issue Acceptance Criteria | graded at Stage 9 QC3.5 / Phase A3.6 | deferred to Stage 9 by design; CIAC-6's per-control arms are recorded below |

### CIAC-6 — per-control two-arm demonstration (the close-ordering gate card)

> *Every control this release adds or repairs is demonstrated **failing** on a fixture in which its observing step is removed, and **passing** on the conformant control. Both arms recorded with non-empty extraction.*

**Conformant control:** the unmutated branch — `automated-closeout.sh --self-test` → `self-test: PASS`, non-empty output.

**Non-conformant arms — 15 mutants, 15 killed, 0 survivors.** Each mutant removes one observing step, is run through the same entry point, and is reverted from git before the next:

| # | Observing step removed | Arms that fired | Killed |
|---|---|---|---|
| M1 | dispatch guard → `\|\| true` (the degenerate adversarial review proved the drafted design could not detect) | AI-F1 ×2, AI-F4 | ✓ 3 |
| M2 | gate removed from the dispatch entirely (**the originating defect's exact state**) | AI-F anti-vacuity | ✓ 1 |
| M3 | SURFACE states pass unattested (**the pre-review design**) | AI-C, AI-D | ✓ 2 |
| M4 | `EMPTY-LEDGER` collapsed into `NOT-RECORDED` (3-valued → 2-valued) | AI-D, AI-E ×2, AI-G | ✓ 4 |
| M5 | attestation emission removed **while still reporting `emitted`** | AI-C2 ×4, AI-D2 | ✓ 5 |
| M6 | gate never blocks on `UNRESOLVED` | AI-A ×2, AI-L | ✓ 3 |
| M7 | gate always blocks | AI-B ×2, AI-B2 | ✓ 3 |
| M8 | column addressing → row pattern-match | AI-B2 ×2, AI-G | ✓ 3 |
| M9 | predicate splits on a bare pipe (the GFM escaped-pipe hazard) | 7 arms, 15 assertions | ✓ 15 |
| M11 | operator-instance path tokenisation removed | AI-P ×2 | ✓ 2 |
| M12 | row 6 recomputes the verdict *after* the close | AI-K | ✓ 1 |
| M13 | attestation clears an `UNRESOLVED` verdict | AI-L | ✓ 1 |
| M14 | the parity arm's canonical source made unreadable *(reflexive)* | AI-G anti-vacuity | ✓ 1 |
| M15 | arm F's own close-witness neutered *(reflexive)* | AI-F2 sensitivity, AI-F3 negative control | ✓ 2 |

**M14 and M15 are the reflexive pair and they are the ones that matter most.** A control that cannot detect its own neutering is the defect this release exists to eliminate, and two prior cards in this milestone shipped exactly that shape before it was caught. M14 removes the parity arm's ability to read its canonical source; M15 removes the dispatch harness's ability to observe the close at all. Both go RED rather than green-because-inert.

**How the dispatch guard became reachable by a test arm.** The pre-existing suite calls phases *directly*, and the dispatch block is main-body code below the argument-parsing banner — structurally outside every arm's reach, which is why a `|| true` variant passed the drafted design's whole arm set. Arm **F** extracts the two dispatch lines *verbatim from the tool's own text*, executes them in a subshell with both phases stubbed and a witness on the close, and carries three limbs that are each other's controls: the shipped line with a blocking gate must leave the close unfired **and** exit 3 (F1); the shipped line with a passing gate must fire the close (F2 — the sensitivity limb, without which F1's clean result would be meaningless); and a constructed `|| true` line must let the close through (F3 — the negative control, without which the arm could not tell a fail-closed gate from a no-op one). Arm **F4** adds the whole-block invariant: 34 of 34 dispatch lines carry the fail-closed guard, with a specificity control proving the filter rejects an unguarded line.

**All three verdict states are exercised, and asserted on the verdict global rather than the detail prose.** `RESOLVED` (arms B, B2), `UNRESOLVED` (A, H, I, J, L), `NOT-RECORDED` (C, C2, P) and `EMPTY-LEDGER` (D, D2) each drive a distinct fixture; arm **E** asserts that the two SURFACE states resolve **distinct** `STATE_AI_GATE` values, because comparing detail strings would pass on any two different sentences while the value every downstream consumer reads went unchecked.

**Live specimen — evidence, not fixture.** The shipped predicate run against this release's own action-item ledger resolves `TOTAL=1 UNRES=1` → `UNRESOLVED`. It proves the gate *sees* a real open row; it proves nothing about blocking, which is what the constructed fixture and the executed dispatch are for. That row is **AI-001**, and the gate now holds this release's own close until the operator disposes it.

### Per-issue — the close-ordering gate card

| AC | Verdict | Evidence |
|---|---|---|
| AC1 — milestone close sequenced after the 7a verdict | **MET at the tooling surface; PARTIAL release-wide** | The gate is dispatched immediately before the close and the close is structurally unreachable on a BLOCK (arm F). **Three milestone-close paths exist and tooling covers one**; the hub-direct narrative path — the shape that closed the originating milestone — is **not** covered, because that file did not land. See **D-14** |
| AC2 — an anti-vacuity control proves 7a can block | **MET** | The CIAC-6 table above; M2 and M6 both go RED |
| AC3 — the originating milestone's open items dispositioned | **OUT-OF-SCOPE — routed to AI-001** | Operator action, not release-buildable. Recorded at **R8**. Stage 8 records this verdict, never NOT MET |

---

## Deployment Execution Log

*Authored at Stage 12 Phase B5. Not written by Engineering.*
