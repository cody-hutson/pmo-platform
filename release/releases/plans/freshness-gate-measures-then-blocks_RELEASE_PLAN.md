---
title: Release Plan — freshness-gate-measures-then-blocks (the freshness gate measures, then blocks)
type: release-plan
plan_type: release
status: EXECUTING
release: version-less (slug-keyed; no tag claimed)
milestone: 385-freshness-gate-measures-then-blocks
release_class: cross-cutting
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `freshness-gate-measures-then-blocks`

**Milestone:** `freshness-gate-measures-then-blocks` (#385) · hub sub-task #6907 = Stage-4 plan source (approved 2026-09-04 at Procedure 0 Step 7) · #6921 / #6930 / #6935 / #6942 / #6948 / #6999 = the six Stage-5 Solutioning sources · #6923 = this Engineering slice, which lands this file as **Engineering Commit 0**.

**Version identity:** **version-less / slug-keyed** (decision D-Version, recorded at Stage 4 Plan Review — a determination, not an operator gate). The release's identity is the capability slug `freshness-gate-measures-then-blocks`. **No version key is claimed and no tag is cut at Stage 12.** The version half of the Engineering-Commit-0 re-verify (steps 1–3) and the Stage-12 atomic version claim are **INAPPLICABLE** — there is no floor to derive, no candidate to compute, and no tag to claim. No release-version stamp token is emitted anywhere in this plan — the token is **named, never spelled**, deliberately not even as a prose mention, because the stamp tooling scans pre-claim plans at the `plans/` root for that literal double-brace substring and **declines its rename when two or more carry it**; a version-less plan that merely mentioned the token would register as a second candidate and silently cost a concurrent versioned release its rename. See § Operator Decisions § D-Version for the full finding, the corpus basis, and the `--verify-stamp` verdict recorded verbatim.

**Topology:** D-C SINGLE — one release branch (`release/freshness-gate-measures-then-blocks`), one PR, one merge; this plan lands as **Engineering Commit 0**.

**Concurrency posture:** **P0 fully-serial.** Stage 6 is write-serialized on one shared branch across six slices; four of the six write `core/deploy/deploy.sh` and three write the PF regression suite. Slices route one at a time in the § Implementation Sequence order; the next slice waits until the prior commit lands. No force-push (including `--force-with-lease`) on the shared release branch.

**Release class:** `cross-cutting` (decision D-ReleaseClass) · engagement **Tight** · Stage-9 review **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-04, domain: software }` — determined at Stage 4 Phase A1.5 (Form X verbatim, § 5.7 exemption: the File Change Matrix is entirely internal pmo-platform artifacts, so the design depends on no external best-practice). Classification rationale: every matrix row is a CI workflow, shell tooling, or a shell regression suite — executable platform tooling rather than governance prose. Secondary domain `governance` (four doc surfaces: `gate-efficacy-standard.md`, `skill-deployment.md`, `gate-criteria-spec.md`, `release-process.md`). `software` dominates.

**Baseline pin:** `origin/main` @ `ef008d6d9c32c5982feb943a1a916c4b80c7c321`, tip 2026-09-03T22:00:00-05:00 (merge of PR #6906). Measured 2026-09-04T03:40:20Z at Stage 4; re-confirmed byte-identical at Engineering Commit 0.

> **Provenance.** This file transcribes the Stage-4 release plan approved on hub sub-task #6907 (operator-approved 2026-09-04, decision D-PlanApproval), reconciled to the six approved Stage-5 Solutioning designs and to the decisions rendered at the **Collective Review scope-lock gate** (2026-09-04). Where a later decision superseded a Stage-4 determination, the transcribed section carries the **later** value and § Deviation Log records the delta. Authored at Engineering Commit 0 by the first Engineering spoke (#6923).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (slug-keyed; no tag, no stamp manifest) |
| **Bump Class** | N/A — inapplicable, not failed. A `version-less` release has no bump class: there is no floor to derive and no candidate to compute. |
| **Date Created** | 2026-09-04 (Friday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/freshness-gate-measures-then-blocks` |
| **Baseline pin** | `origin/main` @ `ef008d6d9c32c5982feb943a1a916c4b80c7c321` |
| **PR** | #7007 (draft at Stage 6; transitions to ready at the Stage 9 gate) |
| **Milestone** | `freshness-gate-measures-then-blocks` (#385) |

---

## Scope

### Release Outcome Statement (as amended at Collective Review)

**AFTER:** A green `skill-package-freshness` check means the content arm actually executed and found every deployed `.skill` package current; a stale package cannot merge to `main`.

**BEFORE:** The check reads green when its rebuild dependency is missing (it measures nothing), the sentinel sits at `warn`, the job is not a required status check, and `strict=false` lets a stale package land behind a concurrent merge — six packages were rebuilt by hand on 2026-09-01.

**Actor(s):** release hub; any merging session. **Success indicator:** a seeded stale package turns the required check red on a PR; the hand-rebuild class does not recur.

**Amendment (2026-09-04, decision D-StrictReopen).** The original AFTER clause read "…cannot merge to `main`, **including through the concurrent-merge race**." That clause is discharged only by `strict=true`, which decision D-Strict dropped from release scope — it appears in no member body and is repo-wide across all nine currently-required contexts. The hub's original D-Strict recommendation asserted the Outcome Statement was *fully* satisfied without `strict`; that was wrong, and the BEFORE clause names `strict=false` as the cause of exactly this vector. The concurrent-merge-race residual is carried forward as a follow-up, not claimed as shipped.

### Members

Six, not five. The original composition was five; **#6998 was milestoned into this release at the Collective Review scope-lock gate** by operator direction (decision D-AC3Card), carrying #5500's AC3 branch-2 finding plus the remediation path that gates registration.

| # | Issue | Sub-slice | Size | Title (short) |
|---|---|---|---|---|
| 1 | #4332 | D1 | M | Install the pinned packager deps in the freshness workflow; fail, not warn, on a missing module |
| 2 | #5242 | D1 | M | `_c7_compute_verdict` fail-closed — emit `NOT-EVALUATED` when the staged rebuild cannot execute |
| 3 | #5897 | D1 | M | Every caller of the engine's one-line protocol honours the third verdict token; the sentinel graduates |
| 4 | #5500 | D2 | M | Package-freshness drift regrew on `main` after its remediation shipped — find the mechanism |
| 5 | #6181 | D2 | S | State the live pre-merge mode where a criterion author reads it |
| 6 | #6998 | D2 | M | Automated-dependency and out-of-band PRs stale `.skill` packages, bypassing both #188 controls |

Root cause (chain): *required condition held by convention, not construction* → *the freshness engine's content arm has an undeclared runtime dependency and no unevaluated-predicate state, while the gate sits at warn, unregistered, `strict=false`* → *green runs that measured nothing*.

### Exclusions

Enumerated over the adjacent-candidate set surfaced at Stage 3 / Stage 4 / Stage 5; three found, all deliberately not pulled in.

- **#5554** (deploy replaces deployed allowlists wholesale) — checked and it does not bind. `build-skill-packages.sh` is present in four invocation forms in the script-execution allowlist, and sibling PR #6745's hunks in that file are disjoint from those rows.
- **#5053** (Check 51's warn→enforce flip is unreachable from a release branch because its mode resolver reads untracked instance paths) — same *class* as this release's flip, but it does not bind: this gate's sentinel is a **tracked** repo file read at a repo-relative path, and #5053's failure mode is specifically an untracked instance path.
- **#6417** (arm the g1-enforcement warn→enforce flip once the shakedown floor is met per emit site) — a thematic sibling, not a dependency. Its framing and this release's Risk R5 are the same problem; recommend surfacing when #6417 is next triaged.

---

## Dependency Graph

Declared in the milestone: D1 (#4332 → #5242 → #5897) → D2 (#5500 → #6181), with #6998 added at Collective Review as a D2 member that **gates the Tier-0 registration step**. Verified edge-by-edge against issue bodies **and** code.

| Edge | Character | Verified basis |
|---|---|---|
| #4332 → #5242 | **Root-cause**, not sequence | #5242 records "root cause undetermined"; #4332 traces it file-by-file. #5242 AC3 discharges by citing #4332's trace. |
| #5242 → #5897 | **HARD build-blocking, and inverted** — the *consumer* limb must precede the *producer* limb | `cmd_check_package_freshness`'s `*)` arm fail-closes to `exit 1` on any unrecognised token; the lifecycle Check-7 caller has its own `*)` arm; the workflow's `Gate decision` `case "$RC"` has arms `0)` / `2)` / `*)` and **no `3)` arm**. Emitting the new token first reds every PR in the repository, including this release's own. |
| D1 → D2 | Confirmed | The gate cannot meaningfully block until the probe can tell fresh from unmeasured. |
| #5500 → #6181 | Confirmed | #6181 is terminal — it grades whether the flip landed and re-reads citing ACs. |
| #5500 AC4 ← D1 | **New, real** | #5500 AC4 is byte-for-byte the same mechanism as #5242 AC1 and #5897 AC2 — three criteria, one implementation → CIAC-1. |
| #4332 AC3 ≡ #5242 AC2 ≡ #6181 AC3 | **New — convergence** | One falsification artifact discharges a criterion in three cards → CIAC-2. |
| #6998 → [T0 operator registration] | **New at Collective Review** | Registering the required check before the bot-PR remediation path exists would stall Dependabot **security** updates on a public repository. Sequence steps 14–15 therefore depend on #6998. |
| #5897 → [T0 operator registration] | Confirmed, mis-attributed in the original sub-task | Branch-protection registration is **#5897's** dependency, not #5500's AC. |

**Circular chains: none, and the zero is real.** 3-colour DFS back-edge detection over the verified edge set; denominator 7 nodes / 8 edges; subject arm **0** back-edges. Sensitivity arm: a synthetic `#6181 → #4332` edge returned the back-edge `('6181','4332')`. Specificity arm: a benign forward edge `#4332 → #6181` returned **0**.

---

## Implementation Sequence

**Seven write-serialized slots on one release branch**, superseding the Stage-4 draft ordering. Slot 1 is three commits; every other slot is one. `#5897` occupies **two non-adjacent slots** (decision D-5897Form: one card, two ordered commits — not a card split), because its two changes carry opposite ordering constraints.

| Slot | Card | Commit(s) | Why here |
|---|---|---|---|
| **0** | — | Release plan committed as **Engineering Commit 0** | Single-branch topology; from this commit the plan file is the durable surface every later stage reads |
| **1** | **#4332** | **C1** workflow dependency install · **C2** honest prereq guard (FAIL) · **C3** packager-stderr capture + the mtime-inertness comment | Nothing downstream is *observable* until the content arm can run. C2 is the arm that makes a future degradation visible; C3 is why this defect stayed invisible for the life of the gate |
| **2** | **#5897 Commit A** | Caller mapping across **three** dispatch surfaces + `gate-criteria-spec.md` G6-06 + PF-suite re-point | **Consumer-first, deliberately inverted from the declared order.** A caller arm for a token nobody emits yet is inert and safe; the reverse order routes an unrecognised token to a fail-closed `*)` arm and reds every PR in the repository |
| **3** | **#5242** | Emit `NOT-EVALUATED` from `_c7_compute_verdict`; `c7_can_rebuild` probes the **module**, not just interpreter + `unzip`; PF-9a–d | The producer half. Slots 2+3 may land as one atomic commit; they may **not** land in the opposite order |
| **4** | **#5500** | Regrowth-mechanism finding + the `release-process.md` prose correction + the recorded verify-only verdict | The release's only genuinely open design surface. Sited after slots 1–3 so the finding is written against a probe that can actually measure |
| **5** | **#6181** | `core/rules/skill-deployment.md` Part 1 (two-surface distinction, sentinel-as-authority, two-switch decomposition) | Lands whichever arm the conditional takes. Part 2 — the single sentence anchored on the new `**Current pre-merge mode:**` literal — does **not** land here; see slot 6 |
| **6** | **#5897 Commit B** | Sentinel `warn` → `enforce`, **plus #6181's Part 2 sentence in the same commit** | Arm A, conditioned. Co-committing Part 2 with the sentinel is structural: no commit and no arm outcome can strand a governance rule file asserting a mode the sentinel does not hold |
| **7** | **#6998** | `.github/dependabot.yml` npm registration · `SECURITY.md` reconciliation + admin-override framing · PF-9/PF-10 | Sequenced **after** #5897 Commit B (decision D-PFSequence) — it extends the same PF suite that Commit B re-points, so it must be authored against post-flip text |

**Post-Engineering sequence steps (not commits):**

| # | Step | Owner | Note |
|---|---|---|---|
| 8 | Seeded-stale proof on the release branch, **check still NON-required** | Stage 7/8 | Seed → observe red → **revert byte-exact** → observe green. A red *non-required* check cannot block the merge, which is precisely why the proof runs before registration |
| 9 | Confirm the seed is fully reverted and CI is green | Stage 9 | Gate on this. Never merge with an unread red check |
| 10 | Stage 12 merge | Stage 12 | Version-less: no tag is claimed |
| 11 | **[T0 — OPERATOR]** Add `Pre-merge .skill package content-freshness gate` to `required_status_checks` | Operator | **After merge**, and **after #6998's remediation path has landed**. No spoke can execute this; it is an out-of-tree branch-protection setting |
| 12 | **[T0 — OPERATOR]** Re-read protection and assert the context is present | Operator | The registration is not complete until read back |
| 13 | Mark #4332, #5242, #5897, #5500, #6181, #6998 as closed at Stage 13 | Stage 13 | Version-less close-out routes through the Phase-B chore-PR path |

**Where the Tier-0 step lands, stated plainly:** *between* the release merge and Stage-13 close — **not** inside the engineering commits, and **not** before the merge. Placing it earlier makes the release a subject of a required check it is still in the middle of repairing; placing it after Stage 13 leaves the Outcome Statement undischarged.

**Operator handoff for steps 11–12** (out-of-tree, no spoke path):

> **Run in your terminal:**
> ```bash
> gh api repos/cody-hutson/pmo-platform/branches/main/protection/required_status_checks/contexts \
>   -X POST -f 'contexts[]=Pre-merge .skill package content-freshness gate'
> ```
> **Effect:** the freshness gate becomes a required check on `main`; a PR carrying a stale `.skill` package can no longer merge. `strict` is **not** touched (decision D-Strict / D-StrictReopen). Reversibility: **CHEAP** (remove the context; no git history involved either way).
> **After you run it:** re-read `required_status_checks.contexts` and assert the context is present, against the recorded pre-state of **9 contexts / `strict: false`** measured at `ef008d6d`.

---

## Stage Applicability Matrix

Release Class `cross-cutting` → Stage 5 activation bias **ALL**, Stage 9 depth **Deep**.

| Stage | #4332 | #5242 | #5897 | #5500 | #6181 | #6998 |
|---|---|---|---|---|---|---|
| 5 Solutioning | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| 6 Engineering | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| 7 Dev Testing | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| 8 QA Testing | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| 9 Plan Review | APPLY (release-scoped, Deep) | | | | | |
| 10 Dry Run | APPLY (release-scoped) | | | | | |
| 11 Snapshot | APPLY (release-scoped) | | | | | |
| 12 Execute | APPLY (release-scoped) | | | | | |
| 13 Close | APPLY (release-scoped) | | | | | |

**No stage is skipped for any card, and the reason is stated rather than defaulted.** Stage 5 is not skipped because none of the six is trivial — even #4332, which has a verbatim in-repo exemplar, carried a real design fork (install the dependency **or** narrow the register row). Stages 7–8 are not skipped because every card has functional impact, including #6181, whose AC3 is itself a CI demonstration. Sub-tasks: #6921/#6923/#6925/#6927 (#4332) · #6930/#6932/#6933/#6934 (#5242) · #6935/#6936/#6938/#6940 (#5897) · #6942/#6945/#6946/#6947 (#5500) · #6948/#6949/#6950/#6951 (#6181) · #6999/#7000/#7001/#7002 (#6998) · #6952–#6956 (Stages 9–13, release-scoped).

---

## Contention Map

**Within-release contention — severe and expected. It is the reason the posture is P0.**

| File | Cards | Overlap character | Resolution |
|---|---|---|---|
| `core/deploy/deploy.sh` | #4332, #5242, #5897 | Same file; for #5242/#5897 the **same one-line verdict protocol** — a true semantic collision, not adjacency | Serial sequencing. Slots 2→3 are ordered by the fail-closed hazard, not by convenience |
| `core/deploy/tests/test_package_freshness_exit_codes.sh` | #5897, #5242, #6998 | Append-shaped — new PF-N arms at the tail of an established suite, plus #5897's re-point of PF-2/PF-6 to a synthetic `warn` sentinel | Append pattern; structurally HIGH, operationally LOW. #6998's arms are authored after #5897 Commit B (D-PFSequence) |
| `.github/workflows/skill-package-freshness.yml` | #4332, #5897 | #4332 owns the header sentence, the dependency step and the prerequisite guard; #5897 owns the `3)` dispatch arm (D-ThirdArm) | Two cards, disjoint regions, serialized. **A cross-card edit here at slot 1 would collide with slot 2** |
| `core/standards/gate-efficacy-standard.md` | #5897 only | Under Arm A, #6181's write set is **one file**; the register row is #5897's alone (R-3) | Land once, in #5897's commit. Stage 6 must not double-write it |
| `.github/skill-package-freshness.enforce` | #5897 Commit B only | Single token, single writer | #6181 grades it |
| `core/schemas/gate-criteria-spec.md` | #5897 only | G6-06 states this probe's exit enumeration and warn-mode posture; found independently by both D1 spokes (D-G6Scope) | Added to #5897's write set and to CIAC-3 |
| `release/governance/release-process.md` | #5500 only | The `:594` "Pre-merge CI backstop (Stage 6)" clause — the governance limb of the regrowth | **#5500's alone.** #6998 names it in its Affected Files for traceability only — do not double-write |

**Regions inside `core/deploy/deploy.sh`,** so the three-card overlap is legible rather than a bare filename collision:

| Region | Lines (live at `ef008d6d`) | Cards |
|---|---|---|
| `_c7_compute_verdict` (+ its protocol header) | 3283–3389 | #4332 (mtime-inertness comment, call-site stderr), #5242 (token, module probe) |
| `build_skill_to_dir` | 3814–3863 | #4332 (stderr capture) |
| `cmd_check` Check-7 caller | ~5846–5860 | #5897 Commit A |
| `flag_not_evaluated` (existing emitter) | 5999–6008 | #5897 Commit A — **must be hoisted to top level**; it is defined 148 lines *after* the Check-7 call site inside the same `cmd_check` body, so calling it from there does not resolve |
| `cmd_check_package_freshness` (+ VERDICT→EXIT contract) | 16363–16422 | #5897 Commit A |

**The card line pointers are stale and must not be navigated from.** #4332's body cites `build_skill_to_dir` at `:1467` (live: `:3814` — stale by ~2,347 lines) and the prereq guard at `:72` (live: `:93-94`). #5897's Affected Files line pointer is stale by roughly 1,070 lines. Stage 6 uses the live line numbers recorded here and in the Stage-5 specs.

---

## Cross-PR Overlap Audit

### Baseline SHA

`ef008d6d` (`origin/main`, tip 2026-09-03T22:00:00-05:00, merge of PR #6906). **Measured at:** 2026-09-04T03:40:20Z. **Window searched:** all open PRs at that instant, plus `<release-base>..origin/main` for the mover classifier.

### In-Flight Release Roster

**Population: n=1 sibling.** Stated with its baseline per audit-baseline discipline — a sibling branching after this instant is invisible to this pin, and the sibling-merge self-invalidation trigger is **live**, not theoretical.

| Slug | PR | Head SHA | Bump-class | EDITSET ∩ FCM |
|---|---|---|---|---|
| `hooks-block-only-their-scope` | #6745 (draft) | `7e4c0034` | `UNRESOLVABLE` | `core/deploy/deploy.sh` |

**Same-file intersection: `core/deploy/deploy.sh`. Line-range overlap: ZERO — and the zero is real.** `deploy.sh` is byte-identical at #6745's base (`9a7fb2d3`) and at `origin/main` (`ef008d6d`), verified by an empty `git diff --stat` on that path, so the two PRs' line coordinates are directly comparable rather than merely assumed so. #6745's hunks are `[13761, 13767]` and `[13796, 13892]`; the five subject regions above sit ~10,000 lines away. Denominator: 2 sibling hunks × 5 subject regions = **10 pairs tested**; subject arm **0** overlapping pairs. Sensitivity arm: probe interval `[13800, 13810]`, deliberately inside a sibling hunk, returned `[(13800, 13810)]` — **fires**. Specificity arm: probe interval `[1, 10]`, deliberately outside every hunk, returned no overlap.

`overlap_class = single-pr` per path-region. The collision is **file-level only**; the residual is re-baselining churn, not a semantic collision (Risk R4). **Structural-blast-radius (Tier-S): no edge** — #6745's mover-set contains 2 `ADDED` files and no rename/relocate/delete rows intersecting this release's surface, and this release declares no movers of its own.

---

## Risk Register

| ID | Risk | Owner | Severity | Reversibility | Mitigation |
|---|---|---|---|---|---|
| **R1** | `strict=true` is repo-wide and unsupported by any member body | Operator | HIGH | CHEAP but wide | **RETIRED by D-Strict** — the context is registered alone. See R10 for the residual the amendment carries. |
| **R2** | **New verdict token meets the fail-closed `*)` arm.** Producer-before-consumer reds every PR in the repository, including this release's own | Engineering | **HIGH** | CHEAP (revert) | Slots 2→3 are consumer-first, or land atomically. A PF arm asserts the degraded token maps to its intended exit rather than to `*)`. **Three** dispatch surfaces, not two — the workflow's `Gate decision` `case` is the third |
| **R3** | **Reflexive self-block.** The release repairs the gate its own PR passes through | Engineering | MEDIUM | CHEAP | Run the proof while the check is **non-required**; revert byte-exact; gate the merge on a green re-run; register post-merge. Independently de-risked: the write set stales **zero** `.skill` packages (probed against all 60 `TEMPLATE_SYNC_MAP` entries; subject arm 0/5, control arm `output-format.md`→6 / `template-storage.md`→6 / `regression-checks.md`→1) |
| **R3b** | **Stale test expectation, not a stale package.** Flipping the committed sentinel to `enforce` maps STALE to exit 1; PF-2 (`:375`) and PF-6 (`:514`) both assert `RC = 2` while inheriting the **committed** sentinel, so the suite exits 1 and `install-tests.yml` goes red | Engineering | **HIGH** | CHEAP | **D-PFSuite:** the PF suite enters #5897's write set as its 6th file. Re-point PF-2, PF-6 and #5242's PF-9a to a *synthetic* `warn` sentinel, mirroring PF-3's existing synthetic-`enforce` pattern, so the suite asserts the **contract** rather than the repository's current posture. No prior artifact in this release enumerated this |
| **R4** | Sibling #6745 re-baselining churn in `core/deploy/deploy.sh` | Hub | LOW | CHEAP | Line ranges disjoint (arms shown above). Re-run the sibling-merge stale-pin trigger at Stage 9 entry; #6745 is a **draft**, so its merge timing is unpredictable |
| **R5** | **Premature flip on a vacuous warn log.** The sentinel demands ">=3 days, zero false positives", but the content arm has never run in CI — the existing warn log is the output of a probe that measured nothing, so "zero false positives" is unfalsifiable rather than satisfied | Operator | **HIGH** | MODERATE | The warn-log clock **restarts at slot 1**. Arm A accepts the seeded-stale proof as substitute evidence — a positive falsification rather than an absence of complaints. Do not read pre-#4332 history as a shakedown |
| **R6** | #5500 AC2 is genuinely open at plan time | Engineering | MEDIUM | n/a (discovery) | Sited at slot 4, after the probe can measure. **Resolved at Stage 5:** #188 Part B was never built and Part C was relaxed on the same premise |
| **R7** | `--user` install invisible under a sandboxed HOME | Engineering | MEDIUM | CHEAP | **Framing corrected at Stage 5:** `deploy.sh` assigns `HOME` **0** times (it reads it 21; the broad control pattern fired at 21, so the narrow zero is a real absence). The freshness probe does not sandbox HOME the way the PF suite does, so the `PYTHONPATH` pin is **not load-bearing on this path**. It is carried anyway — for provisioning parity between the only two workflows that reach the packager, and so an engine change that ever sandboxes HOME cannot silently re-open the gap |
| **R8** | Out-of-tree change has no git trace | Operator | LOW | CHEAP | Pre-state recorded here (**9 contexts, `strict: false`, measured `ef008d6d`**); post-state read back at sequence step 12 |
| **R9** | Register-row drift — a flip that does not update `gate-efficacy-standard.md` re-creates the declared-vs-actual gap this release exists to close | Engineering | MEDIUM | CHEAP | The register row is in the File Change Matrix, assigned to #5897 alone |
| **R10** | **Concurrent-merge-race residual.** With `strict=false`, a stale package can still land behind a concurrent merge even once the gate is required | Operator | MEDIUM | CHEAP | **Carried forward, not claimed as shipped.** The Outcome Statement was amended to remove the claim rather than ship it undischarged (D-StrictReopen). A `strict=true` change is its own card with its own blast-radius review |
| **R11** | **Registration stalls Dependabot security updates.** Once the sentinel flips AND the gate is registered, a bot PR touching a manifest inside a rostered skill's content set turns a **required** check red and cannot self-remediate — on a public repository | Operator | **HIGH** | CHEAP | **#6998 ships the documented remediation path in this release, before registration** (D-Dependabot). Sequence steps 11–12 depend on it. Auto-rebuild was rejected on three verified blockers, not on cost: `GITHUB_TOKEN`-triggered events spawn no new workflow run (so the required check never re-reports and the PR stays blocked), Dependabot-triggered workflows receive a read-only token and no secrets, and `required_signatures: true` is live on `main` |
| **R12** | **`Shell harness (macOS)` is not a required context.** PF-9/PF-10 report but cannot block | Engineering | LOW | n/a | **Do not credit the PF suite as a gate** — doing so would repeat #188's error at smaller scale. Recorded as a bounded claim, raised by the #6998 spoke against its own deliverable |

### Rollback strategy

Every limb is independently revertible and none is IRREVERSIBLE. Sentinel flip: one token, one commit. Verdict-token change: a code revert; the `*)` fail-closed arm means a partial revert degrades to blocking-not-silent, which is the safe direction. Workflow dependency install: a CI-only change with no runtime surface. Branch-protection registration: operator removes the context — CHEAP, but leaves no git trace, hence R8's read-back record.

**Composite rollback order is the inverse of the sequence:** deregister the required check first, then revert the sentinel, then the code. Reverting the code while the check is required and enforcing would leave the gate hard-failing on a fail-closed unknown token.

---

## Cross-Issue Acceptance Criteria

Four CIACs. This release is an unusually strong CIAC candidate: its members are slices of one gate, and three separate cards each carry a criterion only the *integrated* release can satisfy.

- [ ] **CIAC-1 (#5242 × #5897 × #5500 — the one-line verdict protocol):** the "measurement did not run" state is expressed **once**, by a single third verdict token emitted from the shared `_c7_compute_verdict` body, and every caller maps it. No card authors a parallel probe. *Shared surface:* `core/deploy/deploy.sh` — `_c7_compute_verdict`, the `cmd_check` Check-7 caller, `cmd_check_package_freshness`. *Method:* `grep -c 'NOT-EVALUATED' core/deploy/deploy.sh` returns a non-zero count with exactly one emission site, and `bash core/deploy/deploy.sh --check-package-freshness` in an environment where the staged rebuild cannot run reports the new verdict rather than `content-fresh — OK`. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#4332 × #5242 × #6181 — the falsification artifact):** one seeded-stale demonstration discharges #4332 AC3, #5242 AC2 and #6181 AC3 — the release builds it **once**, as an arm of the existing PF suite, not three times. *Shared surface:* `core/deploy/tests/test_package_freshness_exit_codes.sh`. *Method:* `grep -c 'PF-' core/deploy/tests/test_package_freshness_exit_codes.sh` returns strictly more than the pre-release count of 8, and the added seeded-stale arm carries its restore-and-pass control in the PF-6/PF-7 pattern. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#5897 × #6181 × #6998 — declared-vs-actual mode, FIVE surfaces):** every surface that states this gate's enforcement posture agrees with the sentinel token as merged. *Shared surface:* `.github/skill-package-freshness.enforce`, `core/standards/gate-efficacy-standard.md`, `core/rules/skill-deployment.md`, the `skill-package-freshness.yml` header, and `core/schemas/gate-criteria-spec.md` G6-06. *Method:* read the sentinel's first non-comment token, then assert each of the four prose surfaces states that same mode. **Null arm:** the assertion "no surface still describes the superseded mode" carries its control — the same search for the *current* mode string must return non-zero on those same files, so a zero cannot mean the paths failed to resolve. **Scope is deliberately narrow:** do not widen the null arm repo-wide; 19 frozen release artifacts legitimately still record `warn-mode-initial` and flagging them would be a false positive against immutable records. **`core/rules/skill-deployment.md` agrees vacuously today** — it mentions the pre-merge gate zero times (control: 3 mentions of "Check 7", all referring to the always-enforce *deploy-time* check), so #6181's authoring must write the live mode there or this CIAC fails at Stage 9. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#4332 × #5242 — content-arm reach):** the staged rebuild executes for **every** rostered skill in CI, not a subset — the arm's denominator is stated and equals the roster size. *Shared surface:* the `.github/workflows/skill-package-freshness.yml` job output and `_c7_compute_verdict`'s per-skill stderr. *Method:* read the gate job's step summary on the release PR and assert the count of skills reaching the staged-rebuild comparison equals the rostered count (**55** at `ef008d6d`), with zero `staged rebuild failed to run` warnings. **Null arm:** the zero-warning assertion is controlled by CIAC-2's seeded-stale run, which must show a non-zero finding on the same instrument. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## File Change Matrix

Machine-readable, one path per line, `<path>  <VERB>` columnar-in-fence form. **Net movement since Stage 4:** #5897 grew 3 → 6 files (D-ThirdArm + D-G6Scope + D-PFSuite); #5500 nets **−1** (releases `core/deploy/deploy.sh` and the PF suite back to D1 under CIAC-1/CIAC-2, acquires `release/governance/release-process.md`); #6181 narrows to **one** file under Arm A (R-3 — the `gate-efficacy-standard.md` row is the Arm-B path and belongs to #5897 under Arm A); #6998 adds three files, none of them a sibling's.

```
# ── #4332 — the content arm can run, and says so when it cannot ──
.github/workflows/skill-package-freshness.yml                   edit
core/deploy/deploy.sh                                           edit

# ── #5242 — the engine can express "not measured" ──
core/deploy/deploy.sh                                           edit
core/deploy/tests/test_package_freshness_exit_codes.sh          edit

# ── #5897 — every caller reads the new state; the sentinel graduates ──
core/deploy/deploy.sh                                           edit
.github/workflows/skill-package-freshness.yml                   edit
.github/skill-package-freshness.enforce                         edit
core/standards/gate-efficacy-standard.md                        edit
core/schemas/gate-criteria-spec.md                              edit
core/deploy/tests/test_package_freshness_exit_codes.sh          edit

# ── #5500 — regrowth mechanism + the governance limb of the regrowth ──
release/governance/release-process.md                           edit

# ── #6181 — the live mode is stated where a criterion author reads it ──
core/rules/skill-deployment.md                                  edit

# ── #6998 — the automated-dependency and out-of-band ingress paths ──
.github/dependabot.yml                                          edit
SECURITY.md                                                     edit
core/deploy/tests/test_package_freshness_exit_codes.sh          edit

# ── release artifact ──
release/releases/plans/freshness-gate-measures-then-blocks_RELEASE_PLAN.md   add
```

```
#### Read-only inputs
core/hooks/block-autonomy-ceiling.sh                            READ
core/hooks/block-skill-direct-edit.sh                           READ
release/skills/pmo-skill-refiner/scripts/package_skill.py       READ
release/skills/pmo-skill-refiner/scripts/quick_validate.py      READ
release/skills/pmo-skill-refiner/eval-viewer/tests/package.json READ
release/skills/pmo-skill-refiner/eval-viewer/tests/package-lock.json  READ
.github/workflows/install-tests.yml                             READ
core/config/allowlists/script-execution-allowlist.txt           READ

#### Release-wide explicit non-scope
packages/                                                       NOT EDITED
core/deploy/tools/build-skill-packages.sh                       NOT EDITED
core/ADRs/                                                      NOT EDITED
release/ADRs/                                                   NOT EDITED
```

**No `add` row for a tracked executable**, so the `script-execution-allowlist.txt` companion obligation does not fire. `build-skill-packages.sh` is already allowlisted in four invocation forms, so the #5500 Notes blocker is cleared and no new row is owed.

**`packages/` is explicit non-scope, and the claim is measured.** None of the write-set basenames appears among the **60** `TEMPLATE_SYNC_MAP` entries (subject arm 0/5), while the control arm returns `output-format.md`→6, `template-storage.md`→6, `regression-checks.md`→1. No write-set path sits under a skills tree. **This release stales zero `.skill` packages by either input vector** — which is what makes the seeded-stale proof safe to run on the release branch. The two npm manifests inside `release/skills/pmo-skill-refiner/` are **read and sandbox-seeded, never edited**, so #6998's editability class is decided by conjunct 1 like the other five, not by the file-suffix arm.

**ADR index: N/A — this release adds no record under `release/ADRs/`.** The honest no-op, recorded rather than silent. No ADR is owed by any member: this is a defect repair restoring a predicate the corpus already declares in four places, and it canonicalizes no new architectural position.

---

## Agent-Editability Read

**Derivation — controls read at commit `ef008d6d`:**

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: **2 blocks observed**. Block 1 (anchored, 11 arms) covers the workspace charter, OPERATIONS, RELEASE_PROTOCOL and the agent-config root; Block 2 (repository-membership, anchor-free, guarded by `is_platform_worktree`) covers `*/CLAUDE.md` · `*/OPERATIONS.md` · `*/RELEASE_PROTOCOL.md`. Unreachable-arm test at the read SHA: the three agent-config arms project to paths the repository does not track (tracked-index probe → **0**; control probe for the three governance basenames → **3** tracked paths, so the zero is a real absence), and are discarded from the repo-relative union.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`; exemption list resolves to a deployed hook directory unreachable from a release session and is recorded **`undetermined`**, never `absent`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #4332 | `.github/workflows/skill-package-freshness.yml` | no | no — **conjunct 1** | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #4332 | `core/deploy/deploy.sh` | no | no — conjunct 1 | `unconstrained` | | ordinary Engineering spoke |
| #5242 | `core/deploy/deploy.sh` | no | no — conjunct 1 | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5242 | `core/deploy/tests/test_package_freshness_exit_codes.sh` | no | no — conjunct 1 | `unconstrained` | | ordinary Engineering spoke |
| #5897 | `.github/skill-package-freshness.enforce` | no | no — conjunct 1 | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5897 | `core/standards/gate-efficacy-standard.md` | no | no — conjunct 1 | `unconstrained` | | ordinary Engineering spoke |
| #5897 | `core/schemas/gate-criteria-spec.md` | no | no — conjunct 1 | `unconstrained` | | ordinary Engineering spoke |
| #5500 | `release/governance/release-process.md` | no | no — conjunct 1 | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6181 | `core/rules/skill-deployment.md` | no | no — conjunct 1 | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6998 | `.github/dependabot.yml` | no | no — conjunct 1 | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6998 | `SECURITY.md` | no | no — conjunct 1 | `unconstrained` | | ordinary Engineering spoke |
| — | `release/releases/plans/…_RELEASE_PLAN.md` | no | no — conjunct 1 | `unconstrained` | | ordinary Engineering spoke |

**All-`unconstrained` is a discriminating negative, not a default.** `conjunct 1` decided every skill-gate row — the write set contains no path under `*/skills/<skill>/`, so the `undetermined` exemption list never became load-bearing. `core/rules/skill-deployment.md` is a near-miss worth naming: it *documents* skill deployment but lives at `core/rules/`, outside `SKILL_SCOPE_RE`. **#6998's class was re-derived, not copied** — its npm manifests do sit under `release/skills/<skill>/`, but they are read-only inputs, so no write-set path reaches the suffix arm at all.

**The Tier-0 obligation in this release is not a write.** Sequence steps 11–12 are a branch-protection change — out-of-tree, no `Write`/`Edit` payload, therefore invisible to both controls and correctly absent from the table. `CLAUDE_HOOK_BYPASS` is not an execution-path value under any classification here.

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential (dependency-ordered), P0 fully-serial |
| **Commit strategy** | One commit per logical unit, in the § Implementation Sequence slot order; slot 1 is three commits, #5897 occupies two non-adjacent slots |
| **Review approach** | Single PR for the entire release (milestone-ships-as-one-PR), created **draft** at Stage 6 and transitioned to ready at the Stage 9 gate |
| **Deployment mechanism** | Git merge. No skill-package rebuild beat fires (the write set stales zero packages); no Layer-2 propagation target |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A). No stacked-base waves are planned |
| **Force-push posture** | Prohibited on the shared release branch, including `--force-with-lease` (P0 under multi-chip activity) |

---

## Verification Plan

### AC baseline

`ac_baseline: { #4332: 5, #5242: 3, #5897: 2, #5500: 4, #6181: 4, #6998: 5, read_at: ef008d6d9c32c5982feb943a1a916c4b80c7c321 }`

Read 2026-09-04 from the six issue bodies' `### Acceptance Criteria` sections. #5500's criteria are authored as a numbered list rather than a checkbox list; the ordinal is the list position either way.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|--------------------|-----------------|
| #4332 | AC-1 | Read the gate job log for the `Ensure PyYAML` step line `PyYAML 6.0.2 via …` | The reported interpreter path is an **Xcode** `/usr/bin/python3` resolution, not a brew or setup-python one |
| #4332 | AC-2 | Rename `release/skills/pmo-skill-refiner/scripts/quick_validate.py`, then run `cd release/skills/pmo-skill-refiner && /usr/bin/python3 -c 'import scripts.package_skill'`; restore byte-exact | Non-zero exit with the guard's `::error::` text while renamed; exit 0 after restore. A guard never shown to fire is not a guard |
| #4332 | AC-3 | CIAC-2's single seeded-stale demonstration (this card authors none of it) | The gate reports non-green — valid **only** after the slot-6 sentinel flip; under `warn` a STALE verdict maps to job `exit 0` |
| #4332 | AC-4 | `grep -c 'INERT' core/deploy/deploy.sh` over the `_c7_compute_verdict` header, then `bash core/deploy/deploy.sh --check-package-freshness` | The comment names the mtime fallback's inertness on a fresh checkout; the probe's verdict line is unchanged (comment-only edit) |
| #4332 | AC-5 | Enumerate `.github/workflows/*.yml` and classify each by whether it reaches `build_skill_to_dir` | Reaching set **2 of 24**, of which **1** degraded and **1** already correct · control: the same instrument over `runs-on` → **24/24**, and over `zzz_no_such_token_zzz` → **0/24** |
| #5242 | AC-1 | `bash core/deploy/deploy.sh --check-package-freshness` in an environment where the staged rebuild cannot run | The probe reports the `NOT-EVALUATED` verdict rather than `content-fresh — OK`; advisory under `warn`, blocking under `enforce` |
| #5242 | AC-2 | CIAC-2's seeded-stale demonstration | The gate is non-green after the slot-6 flip |
| #5242 | AC-3 | Read #4332's Stage-5 trace and the landed Commit-3 diagnostic | Root cause cited, not independently re-investigated: `package_skill.py:17` → `quick_validate.py:28` → `import yaml`, with the workflow installing no dependency |
| #5897 | AC-1 | CIAC-2's seeded-stale demonstration on the release PR | The pre-merge gate fails on a deliberately stale package |
| #5897 | AC-2 | Run `--check-package-freshness` in both a rebuild-capable and a rebuild-incapable environment | Distinct non-fresh verdict in the incapable environment · control: the capable environment on the same instrument reports `content-fresh — OK` |
| #5500 | AC-1 | Re-run `bash core/deploy/deploy.sh --check-package-freshness` at the release-branch head **after slot 3** and record the `Gate decision` line verbatim, paired with CIAC-4's reachable-skill denominator | The recorded verdict is the **CI** line, not a local one. Taken before D1 lands, `FRESH 55` and "measured nothing" are the same observable — which is the whole defect |
| #5500 | AC-2 | Read the landed regrowth-mechanism finding against #188's Part B / Part C control claims | The finding names which control did not hold: Part B was never built (retired as "superseded in substance" against a gate with no working content arm), Part C relaxed on the same premise at `release-process.md:594` |
| #5500 | AC-3 | `grep -n 'CI-gated, not only reconciled' release/governance/release-process.md` | The false coverage claim is corrected in place · control: the same search for the surrounding `Pre-merge CI backstop` heading returns non-zero on the same file, so a zero cannot mean the path failed to resolve |
| #5500 | AC-4 | Bound to CIAC-1 — no parallel probe is authored | The `NOT-EVALUATED` token discharges it; a second probe would be the duplication the card's own composition note warns against |
| #6181 | AC-1 | Read `core/rules/skill-deployment.md` for the pre-merge mode statement · control arm on the adjacent Check 13b "ships warn-mode initial" line in the same file | The live pre-merge mode appears at the surface a criterion author consults; the control fires, so the assertion is not reading a dead path. **AC1 is an addition, not a caveat** — the file's four "enforced by Check 7" statements are true as written of the always-enforce *deploy-time* check |
| #6181 | AC-2 | Read the decision record for D-6181Arm (Arm A) plus the landed sentinel change | The flip lands with its substitute evidence recorded; a silent continuation of warn mode with neither is the failure this card exists to prevent |
| #6181 | AC-3 | CIAC-2's seeded-stale demonstration | A stale package exits 1 and fails CI · control: a byte-exact restore shows a fresh package exits 0 |
| #6181 | AC-4 | Enumerate backlog acceptance criteria citing this gate's exit code and re-read each against the merged mode | Every citing criterion is satisfiable under the mode actually in force. **Scope is bounded:** 6 live mode-bearing surfaces (all #5897's write set), 10 live mode-agnostic (none becomes false after the flip), 19 frozen audit records deliberately excluded |
| #6998 | AC-1 | Read the landed remediation path in `SECURITY.md` and confirm its commit precedes sequence step 11 | A documented, self-service path exists **before** the gate is registered as a required status check |
| #6998 | AC-2 | Read the same remediation path for its coverage of the out-of-band `claude/*` fix-PR ingress | The out-of-band path is covered by the same mechanism, or an explicitly stated separate one |
| #6998 | AC-3 | `grep -n 'package-ecosystem' .github/dependabot.yml` | An `npm` entry is registered with `open-pull-requests-limit: 0`, and the file's single-entry rationale is reconciled with the npm manifests that actually exist · control: the same search returns the pre-existing `github-actions` entry, so a zero cannot mean the path failed to resolve |
| #6998 | AC-4 | Run the added PF arm simulating a bot-shaped staling PR | The probe catches the staled package · control: the same probe on a clean tree passes |
| #6998 | AC-5 | Read the remediation path against the three verified auto-rebuild blockers | The path does not stall a Dependabot **security** update: it blocks with a documented self-service remediation rather than attempting an auto-rebuild that cannot re-report the required check |

### Executor dispatch coverage — what `verify-release-plan.sh` can run here, and what it cannot

Recorded at Engineering Commit 0 so Stage 9 reads a **declared** position rather than an unexplained roll-up. First run at slot 1: **8 PASS / 3 FAIL / 11 SKIP / 18 ERROR over 30 per-issue rows, 0 declared-deferred** (the tool's own roll-up line; a line-based re-tally of the emitted table undercounts it, so the roll-up is the figure of record).

| Element | Result | What it means here |
|---|---|---|
| **Survival row 1 — `domain_practice`** (`provenance-survival`) | **PASS ×3** | `PROV-PRESENCE` 1 conformant label · `PROV-GRAMMAR` form=X, date=2026-09-04, in-label domain present · `PROV-COVERAGE` over 635 plan lines. `PROV-DELTA` **SKIP** — the set-difference limb has no producer surface unless the Stage-4 comment is supplied to the run; it explicitly does **not** pass by default |
| **Survival row 2 — File Change Matrix** (`fcm-delivery`) | **FCM-1 PASS**, `FCM-COVERAGE` **SKIP** | The one ADD obligation (this plan file) is delivered and matched. Coverage is `declared=28 interpreted=26 uninterpreted=2`. The two unreadable rows are **`SECURITY.md`** and **`packages/`**, identified by replicating the tool's own `pathof()` recognizer over the fenced block — the replication reproduces `28/26/2` exactly. Both fall in the recognizer's **own documented residual class** (repository-root files with no directory segment; bare directory rows), of which its source records 52 of 54 corpus-wide as real declarations. **They are left as authored:** `SECURITY.md` is an `edit`, not an ADD, so no delivery obligation is lost, and `packages/` is explicit non-scope. Rewriting a correct path to satisfy a recognizer would be gaming the instrument |
| **Survival row 3 — CIAC** (`integration`) | **CIAC-1 PASS · CIAC-2 PASS · CIAC-3 SKIP · CIAC-4 SKIP** | Both SKIPs are `tool-invocation-outside-executor-allowlist` — the methods name a mode-string read and a CI step-summary read, neither of which the executor is permitted to run. They are graded at **Stage 9 QC3.5 on the merged PR**, which is where the plan already assigns them |
| **Survival row 4 — Verification Plan** | Parsed, **30 rows indexed** | The parser reaches every row; nothing is silently dropped |
| **18 ERROR — `unclassified-method (no family match)`** | Expected, not a defect | These rows are **named reads of named surfaces**, which AC-Binding Limb 1 admits explicitly alongside commands. The executor dispatches five runnable families and has no family for a documentary read, so it reports ERROR rather than inventing a verdict. Stage 7/8 grade them by reading the named surface |
| **2 of the 3 FAIL — `sync` family** | Attributable, and **not** to this diff | Both are the shared `deploy.sh --check` exit being non-clean on this operator instance. The only check this diff touches is Check 7, which passes **directly**: `--check-package-freshness` → rc 0, `55 rostered skill package(s) content-fresh — OK`, verified twice. **Stage 7 should re-run `deploy.sh --check` and grep for `  FAIL:` lines** — that is the discriminator between a real failure and operator-instance drift, and a bare exit-1 does not distinguish them |

**Honest limit on this record.** The run transcribed above executed against the plan as it stood at Commit-0 authoring time, before the stamp-token redaction and the PR-cell population; those edits touch prose cells, not the parsed structures, but the run was **not** re-attributed to the final file. A re-run against the committed file was still executing at handoff. Stage 7 re-executes the plan-verification step as its own gate input, which is the authoritative reading.

### Release-Scoped Verification

| ID | Claim | Method | Expected |
|---|---|---|---|
| **V-1** | Plan conformance | `bash release/tools/verify-release-plan.sh release/releases/plans/freshness-gate-measures-then-blocks_RELEASE_PLAN.md` | Every family PASS or a named SKIP. The release-version-stamp element is **correctly absent** — it fires only when a version-stamp token is present, and a version-less plan emits none |
| **V-2** | Stamp-manifest declaration honesty | `bash release/tools/claim-version.sh --verify-stamp freshness-gate-measures-then-blocks` | Verdict `TOKEN-LESS PLAN` (exit 1) — the **declared** version-less state, recorded verbatim. Any OTHER non-zero verdict (`HALT`) is a real manifest defect and blocks |
| **V-3** | Doc-link integrity | `deploy.sh --check` Check 14 over the modified `.md` files | Every internal markdown link in a modified file resolves |
| **V-4** | PF regression suite | `bash core/deploy/tests/test_package_freshness_exit_codes.sh` | All PF arms PASS at every slot boundary, including after the slot-6 sentinel flip (R3b's re-point is what makes this survivable) |
| **V-5** | CIAC-1..4 verdicts | Per § Cross-Issue Acceptance Criteria methods | Graded release-level at Stage 9 QC3.5 on the merged PR |
| **V-6** | Seed reverted byte-exact | `git diff origin/main -- packages/` at the release-branch head after sequence step 8 | Empty — the seeded-stale artifact leaves no residue · control: the same command during the seeded window returns a non-empty diff |
| **V-7** | Release-level checklist | Per `verification-checklist.md`: File Integrity · Content Correctness · Cross-Reference Validity · Skill Invocation · Output Contract Compliance | All PASS or explained |

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage:** Stage 5: 6 · Stage 7: 6 · Stage 8: 6
**Worst parallel batch — 3, not 6.** The D1→D2 dependency edge already serialises each parallel stage into D1 = {#4332, #5242, #5897} = **3 spokes** and D2 = {#5500, #6181, #6998} = **3 spokes**. The split-batch mitigation the WARN band would otherwise recommend is delivered for free by the dependency structure.
**Per-spoke cost estimate:** size-bucket ordinal band (no telemetry medians available; the bucket cutover predicate is unmet). Worst batch composition: 3 × `size:M`.
**Assumed/stated remaining usage-window envelope:** not operator-stated at hub start → conservative default assumed. `[ASSUMPTION – CONFIRM]`, never `[SOURCE]`.
**Estimated cumulative draw % (worst parallel batch):** below the 50% PASS boundary. A projection of a declared band, not a reading.
**Routing:** PASS — proceed at the batch shape the dependency graph already imposes.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch and is the load-bearing check; this plan-time estimate is advisory. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Operator Decisions (recorded)

### D-Version — RECORDED DETERMINATION (rule-determined; not an operator gate)

- **Determination:** **version-less / slug-keyed.** The release's identity is the capability slug. Bump class / next-free: **N/A**. **No tag at Stage 12.**
- **Consequence for the Commit-0 re-verify, step by step.** Step **1** (`git fetch --tags origin && git fetch origin main`) was **EXECUTED** on its own merit — the release branch is cut from fresh authoritative `origin/main`, which that step supplies regardless of identity mode; its *downstream* purpose does not apply. Step **2** (recompute next-free for the bump class) is **N/A**: there is no floor to derive and no candidate to compute. Step **3** (PROCEED/HALT on claimed-set membership) is **N/A**: its predicate has no operands, and a vacuous PROCEED would assert a verification that did not occur. Step **3b** was **RUN as directed and its verdict recorded verbatim** in § Verification Evidence.
- **Why the token is absent.** `RELEASE_PROTOCOL.md` § Release-identity mode states for `version-less` that the allocation rule is *"inapplicable, not failed: there is no floor to derive, no candidate to compute, and no tag to claim,"* and expressly forbids synthesizing a placeholder version to force a version-less release through it. The same section states that for a version-less release *"the plan and branch stay slug-primary permanently — there is no number to bind, and the rename never fires."* Inserting a stamp token to make step 3b return exit 0 would therefore (a) declare a versioned identity this release does not have, and (b) actively harm a concurrent release: the claim tool derives its stamp slug by scanning pre-claim plans at the `plans/` root for that literal token and **declines its rename when two or more carry it**, so a version-less plan that merely carried the token would register as a second candidate and silently cost an in-flight versioned release its rename. This plan therefore names the construct and never spells it.
- **Reversibility / Confidence:** CHEAP / HIGH.

### D-ReleaseClass — SETTLED: `cross-cutting`

By trigger **(c)** only — 4 verified in-bundle compositional edges against a threshold of 3. Triggers (a) and (b) do **not** fire: 0 stage-spec files, 0 of the 6 rule-defining governance surfaces. `novel` (b) also fires; multi-trigger resolution orders `cross-cutting` first. Posture: engagement **Tight** · Stage 9 review **Deep** · Stage 5 activation **ALL** · Stage 13 outcome-window **30-day**.

### D-Strict / D-StrictReopen — `strict=true` STAYS DROPPED; the Outcome Statement is AMENDED

Register the required-check context alone; do **not** set `strict=true`. Basis: the token appears in zero of the member bodies (probed all five original bodies; control arm `freshness` returned 2–9 hits per body, so extraction was live), and `strict` is repo-wide — it would apply to all 9 currently-required contexts and every open PR. **The hub's original claim that the Outcome Statement was *fully* satisfied without `strict` was wrong** — it read the AFTER clause's first half and stopped at the comma, while the BEFORE clause names `strict=false` as the cause of exactly that vector. The Outcome Statement was amended to remove the concurrent-merge-race claim rather than ship it undischarged; the residual is carried as Risk R10.

### D-6181Arm — Arm A (flip), CONDITIONED

The sentinel flips `warn` → `enforce` this release, on the explicit sequencing: sentinel (slot 6) → seeded-stale proof **while the check is still non-required** → byte-exact revert and green re-run → merge → register the required context **post-merge**, and **after #6998's remediation path exists**. Arm A with registration moved earlier is **not** authorized. Basis: the sentinel's stated precondition (">=3-day warn-log review with zero false positives") is unfalsifiable rather than satisfied, because the content arm has never executed in CI; a positive falsification test is accepted as the substitute evidence.

**Arm B costs more than the Stage-4 plan stated, and that is a binding constraint on any Stage-9 reversal.** #4332 AC3 requires *"confirm the CI gate reports non-green"* and #5242 AC2 requires *"a seeded stale package makes the gate non-green."* Under `warn`, a stale package is green-with-annotation, so **both are unsatisfiable as written under Arm B** — reversing does not cost one N/A, it breaks two other cards' acceptance criteria and requires re-scoping them.

### D-5897Form — One card, two ordered commits

#5897 is **not** split into `-a` / `-b`. The ordering constraint is real and verified, but it is enforced as commit order on one branch, consistent with the milestone-ships-as-one-PR convention.

### D-C Branch Topology — SINGLE · D-Concurrency Posture — P0 fully-serial

One release branch, one PR, one merge; this plan lands as Engineering Commit 0. P0 was the undeclared default at Stage 4 and is independently supported by the contention map: three of six cards write `core/deploy/deploy.sh` and three write the PF suite.

### D-StderrCommit — APPROVED as a scope addition (#4332's third commit)

The packager's stderr is discarded **twice** — at `core/deploy/deploy.sh:3355` (the `_c7_compute_verdict` call site) and at `:3861` (inside `build_skill_to_dir`, wrapping the `python3 -m scripts.package_skill` invocation). That double suppression is why the `staged rebuild failed to run` line never named `ModuleNotFoundError`. Approved on the reasoning that it addresses *why the defect stayed invisible*, not only that it existed. Capture-and-emit-on-failure, using `sed -n` over a file rather than a pipe into a short-circuiting reader, per the repo's SIGPIPE-idiom gate.

### D-GuardSeverity — FAIL, not warn

The prerequisite arms fail rather than annotate, and the three arms (`unzip`, `/usr/bin/python3`, the packager import chain) are uniform because `_c7_compute_verdict` treats the first two identically. Basis, in order of weight: (1) the in-tree precedent already decided this for this predicate — the PF suite states that *a skip returns non-zero because an assertion that did not execute has established nothing*; (2) a `::warning::` on a green job is the invisibility under repair — the live run carried 55 degradation lines and concluded `success`; (3) the gate is **not** a required check today (9 contexts, `strict: false`, this gate absent — read live), so a hard-failing guard cannot block a merge in this release, and landing FAIL after registration would be strictly more expensive; (4) it matches the fail-closed `*)` arm already in the same call path.

### D-ThirdArm — the workflow's `3)` arm belongs to #5897

The workflow's `Gate decision` `case "$RC"` is a **third dispatch surface** (arms `0)` / `2)` / `*)`, with no `3)` arm — verified). It is a hard prerequisite of #5242's producer change, but it is caller-mapping work, so it lands with the other two caller mappings in #5897's Commit A. **#4332 does not add it**, even though the file is in #4332's write set — splitting the caller set across cards is what produced the original three-surface blind spot.

### D-Blocking / D-BlockingForm — `NOT-EVALUATED` is sentinel-aware, expressed through the sentinel

The unevaluated state is **advisory under `warn`** and **blocking under `enforce`**. Precedence stays **STALE > NOT-EVALUATED > FRESH**, so every existing blocking behaviour survives unchanged. The *mechanism* is the spec's, not the hub brief's literal "exit 3 → red under enforce": `deploy.sh` declares in-tree that *enforcement policy stays in the sentinel, which this probe remains the single reader of; the CI caller dispatches on the integer and never re-parses the sentinel file*, and the workflow has **0** sentinel-reading lines (all three mentions are prose). The literal form would have required the workflow to read the sentinel, breaking that invariant. Corroboration: exit 3 already means "could not run" in 41 places in `deploy.sh` and never "ran and found a blocking condition".

### D-G6Scope — `core/schemas/gate-criteria-spec.md` G6-06 enters scope

A fourth surface asserting the content-freshness claim and stating the warn-mode posture, found independently by both D1 spokes. Added to #5897's write set and to CIAC-3.

### D-PFSuite — the PF regression suite enters #5897's scope as its 6th file

See Risk R3b. Re-point PF-2, PF-6 and #5242's PF-9a to a synthetic `warn` sentinel, mirroring PF-3's existing synthetic-`enforce` pattern.

### D-CIAC3Vacuous — a binding constraint on #6181

`core/rules/skill-deployment.md` mentions the pre-merge CI gate, `skill-package-freshness`, or required status checks **zero** times (control: 3 mentions of "Check 7", all referring to the always-enforce deploy-time check — extraction confirmed live). It does not contradict the gate's mode; it is **silent** on it. CIAC-3 therefore agrees vacuously today, and #6181's authoring must write the live mode there or CIAC-3 fails at Stage 9.

### D-Dependabot / D-AC3Card / D-ScopeLock — #6998 milestoned into this release

#5500's AC3 branch 2 resolved to one card, milestoned by operator direction (the hub had recommended leaving it unmilestoned). It carries both the ingress finding and the remediation path. **Sequence steps 11–12 now depend on it.** Composition otherwise locked as briefed.

### D-NpmEntry — `open-pull-requests-limit: 0`

Registering the ecosystem is what makes `SECURITY.md`'s two label sentences true and the npm security surface audit-discoverable. The zero-limit form achieves that while disabling version updates entirely, so it adds **no** new PRs that would themselves stale a package and meet the now-required gate. The alternative (`monthly + groups`) would manufacture the exact PR class the remediation path has to absorb, in the same release that creates the requirement.

### D-AdminOverride — documented, framed explicitly as non-routine

The admin-merge exception is written into `SECURITY.md` with non-routine framing, on this release's own thesis: declared must match actual.

### D-PFSequence — no split; #6998's PF arms are sequenced after #5897 Commit B

A Tier 2 `[SCOPE CHANGE]` on the shared PF suite, resolved by sequencing rather than by splitting the card.

### D-R4Handoff — `gate-efficacy-standard.md` under-enumeration folds into #5897's edit

### D-ADR — NO ADR

No ADR is owed. This is a defect repair restoring a predicate the corpus already declares in four places; it canonicalizes no new architectural position. The three canonicalizations #4332 made are structural-spec values whose correct record is the Stage-5 Evidence-Grounding artifact.

---

## Findings routed forward (not fixed in this release)

- **F-1 — the milestone description named a caller that does not exist, and omitted one that does.** `cmd_report` spans 417 lines and contains **zero** references to `_c7_compute_verdict`, `Check 7`, `package-freshness` or `freshness` (sensitivity control returned 69 hits for `PASS` over the same range; specificity arm 0). The real second caller is the lifecycle Check-7 arm. Recorded; the description is a historical record and is not amended.
- **F-3 — the carried depth finding is off by one.** Both the milestone Notes and the Stage-4 plan say "all five `.github/*.enforce`"; there are **six**, all tracked and all reading `warn` (specificity arm on a fabricated glob returned 0). Out of scope here; it should not propagate into the next triage of the thematic sibling (#6417).
- **Warn-mode sentinels have no repo-derivable graduation deadline** — the general case behind Risk R5, across all six `.github/*.enforce` sentinels. This release resolves it for **one** sentinel by substituting a positive falsification test for a passive review window; if that pattern holds it is the generalisable answer for the other five.
- **`pyyaml==6.0.2` will be pinned at three sites with no single source** after this release (`eval-viewer-tests.yml`, `install-tests.yml`, and the new step). A pin-drift gate or a shared composite action is the durable fix. Next-release candidate.
- **`BLOCK-DESTRUCTIVE-022` blocks sourcing `core/hooks/lib/fragile-ref-patterns.sh`,** so no spoke can run the durability detector the governed way. An intake obligation on the hub, surfaced to the operator rather than auto-created.
- **Removing the npm manifests from the compiled package's content set** is the durable follow-up to #6998, not this release's work.
- **`stage-06-engineering.md:71` carries an orthogonal trigger-breadth error** alongside the mode claim #6181 owns. Both land in #6181's edit; they are two errors in one line, not one.

---

## Non-coverage — what this release does NOT deliver

Enumerated over the four classes the Outcome Statement's clauses imply, so the omissions are legible rather than silent.

1. **The concurrent-merge race.** `strict=true` is not set (D-Strict / D-StrictReopen). A stale package can still land behind a concurrent merge. Carried as Risk R10 and as an amendment to the Outcome Statement, not claimed as shipped.
2. **The required-check registration itself.** It is an out-of-tree, operator-only branch-protection change at sequence steps 11–12, after merge. Nothing in this PR makes the gate required.
3. **Auto-rebuild for bot PRs.** Rejected on three verified blockers, not on cost. #6998 ships block-with-documented-remediation instead.
4. **The other five warn-mode sentinels.** This release graduates exactly one.

---

## Deviation Log

| Δ | Departure from the Stage-4 plan as first drafted | Severity | Basis |
|---|---|---|---|
| **Δ1** | Composition is **six** members, not five — #6998 added | scope | Operator direction at the Collective Review scope-lock gate (D-AC3Card). Composition Lock amended in the milestone description |
| **Δ2** | `strict=true` dropped; Outcome Statement amended | scope | D-Strict + D-StrictReopen. The hub's original "fully satisfied" claim was wrong and is corrected on the record |
| **Δ3** | #5897 is one card with two ordered commits, not a `-a`/`-b` split | minor | D-5897Form |
| **Δ4** | #4332 gains a **third** commit (packager-stderr capture) beyond the two Stage 4 scoped | scope | D-StderrCommit, approved as a scope addition |
| **Δ5** | The prerequisite guard **fails** rather than warns, and all three arms are uniform — wider than AC2's literal text | minor | D-GuardSeverity + D-Uniform, flagged rather than folded in silently |
| **Δ6** | `core/schemas/gate-criteria-spec.md` and the PF suite enter #5897's write set (3 → 6 files) | scope | D-G6Scope + D-ThirdArm + D-PFSuite |
| **Δ7** | #5500's write set nets **−1** — it releases `deploy.sh` and the PF suite to D1 and acquires `release/governance/release-process.md` | scope | Collective Review determination; AC4 binds to CIAC-1, AC1/AC2/AC3 land on the governance limb |
| **Δ8** | #6181's write set narrows to **one** file under Arm A | minor | R-3 — the `gate-efficacy-standard.md` row is the Arm-B path; Stage 6 must not double-write it |
| **Δ9** | Plan step 5 ("route the lifecycle caller to `flag_not_evaluated`") **does not compile** as written and is replaced by a hoist-to-top-level | scope | `flag_not_evaluated` is defined at `:5999`, 148 lines *after* the Check-7 call site at `:5851`, inside the same `cmd_check` body. All six existing call sites fall after `:5999`; not one precedes it |
| **Δ10** | The implementation sequence is re-expressed as **seven write-serialized slots** rather than the Stage-4 16-step list | minor | The Stage-4 list interleaved commits with operator steps and predates #6998 and D-PFSequence. The post-Engineering steps are carried separately above, unchanged in substance |
| **Δ11** | R7's mechanism is corrected: the `PYTHONPATH` pin is carried for **provisioning parity**, not because this workflow sandboxes HOME | minor | `deploy.sh` assigns `HOME` 0 times (control fired at 21 reads) |
| **Δ12** | AC5's denominator is **2 of 24**, not "9 of 24" | minor | Re-measured under the approved ADJUST's own scope; the plan-time figure used a wider "mention" pattern |

---

## Verification Evidence

*(Populated progressively at Stage 6 C4 and re-executed at Stage 7. Entries below are Commit-0 evidence.)*

**Stamp-manifest declaration honesty (V-2), recorded at Commit 0 — quoted with two normalizations, both stated:**

```
claim-version: stamp pre-flight — plan release/releases/plans/freshness-gate-measures-then-blocks_RELEASE_PLAN.md carries no <STAMP-TOKEN> token to resolve
claim-version: verify-stamp TOKEN-LESS PLAN — the pre-claim plan release/releases/plans/freshness-gate-measures-then-blocks_RELEASE_PLAN.md EXISTS but carries no <STAMP-TOKEN> token, so the Stage-12 claim would rename it with nothing to resolve. Two readings, both actionable: the plan was authored without the placeholder, or a stamp already resolved its tokens and did not complete the rename (the "half-applied" state the post-CAS recovery messages name). Restore the placeholder if the release has not claimed; finish the rename by hand if it has.
exit 1
```

**Normalization 1 — `<STAMP-TOKEN>`, and it is load-bearing rather than cosmetic.** The tool's own message contains the literal double-brace placeholder; reproducing it here would make this file carry the token it is reporting the absence of, which is self-falsifying **and** actively harmful — the claim tool derives its stamp slug by scanning pre-claim plans at the `plans/` root for that literal substring and declines its rename when two or more carry it. **This exact failure occurred and was caught here:** the first draft of this block quoted the message unredacted, and `--verify-stamp` consequently returned **exit 0 / `verify-stamp OK`** — a false PASS produced entirely by the plan quoting the token, on a release that claims no version. The token was removed and the verb re-run; the transcript above is the re-run.

**Normalization 2 — the plan path.** The tool prints the plan's absolute path, which on any operator machine carries a home-directory segment. This repository is public, so the quoted lines carry the repo-relative path instead. Both normalizations are confined to those two substrings; nothing else in the quoted text is altered, and the verdict token, the reasoning and the exit code are the tool's own.

**Reading:** `TOKEN-LESS PLAN` is the *declared* version-less state, not the verb's `HALT` verdict. The verb distinguishes three exit-1 verdicts — `NO PRE-CLAIM PLAN`, `TOKEN-LESS PLAN`, and `HALT` — and only the third means a broken manifest. Of the two readings the message offers, the first is correct and intentional: the plan was authored without the placeholder because this release claims no version. Recorded per V-2's expected result; **any other non-zero verdict would block.**

**PF regression suite (V-4), at slot 1:** `bash core/deploy/tests/test_package_freshness_exit_codes.sh` → **11 passed, 0 failed, 0 skipped**, exit 0. **PF-2c is the load-bearing arm for #4332's stderr-capture commit** — it asserts zero `staged rebuild failed` lines across the roster by reading the probe's captured output, so a stderr-shape change had to be shown not to disturb it. It was not disturbed. This is the pre-flip baseline; Risk R3b's re-point is what has to keep it green through slot 6.

**#4332 AC5 (V-5 input), re-derived at slot 1 rather than restated:** reaching set **2 of 24** — `skill-package-freshness.yml` (degraded, fixed at slot 1) and `install-tests.yml` (already correct). Sensitivity arm `runs-on` → 24/24; specificity arm on a fabricated token → 0/24; extraction non-empty for all 24 files (min 3,629 bytes). **The first pass of this probe was broken and is recorded as such:** its comment classifier keyed on a leading `#` only, so `repo-integrity.yml`'s echoed prose string mentioning the lifecycle flag counted as an invocation and the reaching set read **3**. Re-classified against the executable-line criterion it is 2, which independently reproduces the Stage-5 finding.

**Artifact-acceptance / deliverable state:** this release is deployable-class. `deliverable_state: deployed-copy-synced` — the source changes are committed on the release branch and the release declares **no Layer-2 propagation target** (no skill source is edited, so the S-2 copy mechanism has nothing to sync).

---

## Operational Deployment Manifest

**N/A — enumerated over the three propagation classes this platform defines: (1) `{operations,release,core}/skills/*` → installed skill copies via the S-2 mechanism; (2) `core/rules/*` → deployed rule mirrors; (3) `TEMPLATE_SYNC_MAP` canonicals → in-package targets. None is present in this release's write set.** `core/rules/skill-deployment.md` is a near-miss on class (2) and is worth naming: it is a rule *document* under `core/rules/`, and the mirror-pair propagation applies to it only if a deployed counterpart exists — this release edits the source of record and adds no new cross-tree reference form, so no mirror obligation is created.

### Schema Migrations

**N/A — enumerated over the two migration classes the plan template recognises (data-shape migrations against a tracked schema, and consumer-contract bumps against an emitted stream). Neither is present:** no schema file is edited, and no emitted-stream contract changes. The `NOT-EVALUATED` verdict token is an *additive* member of an existing one-line protocol whose consumers are all mapped in the same release (CIAC-1), which is a caller-mapping obligation rather than a migration.

---

## Change Description

*(Authored at PR-creation time per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol. Operator-facing, pre-merge. Distinct from the user-facing release note authored at Stage 13 Close.)*

### Outcome

This release makes the pre-merge `.skill` package-freshness gate actually measure what it claims, and then makes it block. Today the gate publishes a green **content** verdict having compared **0 of 55** packages by content: its staged rebuild needs PyYAML, the workflow installs none, and the resulting failure is swallowed twice before anyone can read it. The release installs the dependency, makes a degraded environment fail loudly instead of annotating a green job, teaches the engine to say *"I could not measure"* as a first-class verdict, graduates the sentinel from `warn` to `enforce`, and reconciles the five surfaces that describe the gate's posture. It also closes the two ingress paths — Dependabot **security** updates and out-of-band fix PRs — that stale a package while passing every control, because registering a required check without them would stall security updates on a public repository.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #4332 | The freshness workflow installs the packager's transitive PyYAML dependency, fails loudly when it cannot measure, and no longer discards the packager's own error text | DONE |
| #5242 | `_c7_compute_verdict` emits `NOT-EVALUATED` when the staged rebuild cannot execute, and probes the module rather than only the interpreter | DONE |
| #5897 | All three dispatch surfaces read the third verdict token; the sentinel graduates to `enforce`; the register row and G6-06 match the merged mode | DONE |
| #5500 | The regrowth mechanism is named — #188 Part B was never built and Part C was relaxed on the same premise — and the governance limb of that claim is corrected | DONE |
| #6181 | `core/rules/skill-deployment.md` states the live pre-merge mode where a criterion author reads it, co-committed with the sentinel so no arm can strand it | DONE |
| #6998 | The npm ecosystem is registered, `SECURITY.md`'s two false label claims are reconciled, and a documented remediation path ships before registration | DONE |

### Key decisions

- **D-Strict / D-StrictReopen:** `strict=true` stays dropped and the Outcome Statement is amended rather than shipped undischarged. The concurrent-merge-race residual is carried forward as Risk R10.
- **D-GuardSeverity:** the prerequisite guard **fails**, it does not warn — landed now, while the gate is provably non-required, because landing it after registration would be strictly more expensive.
- **D-6181Arm:** Arm A (flip), conditioned on sentinel → proof-while-non-required → byte-exact revert → merge → register post-merge.
- **D-Blocking:** `NOT-EVALUATED` is advisory under `warn` and blocking under `enforce`, expressed through the sentinel rather than through a hard-coded integer, preserving the in-tree invariant that the probe is the sentinel's single reader.
- **D-AC3Card:** #6998 was milestoned into this release, making the Tier-0 registration depend on it.

### Reversibility

**CHEAP — HIGH confidence.** Every limb reverts independently: `git revert` on the code commits, one token on the sentinel, one CI step on the dependency install, and an operator-side context removal on the registration. The composite rollback order is the inverse of the sequence — deregister, then revert the sentinel, then the code.

### Downstream impact

- The gate becomes a real pre-merge control, so every subsequent PR that edits a rostered skill's `SKILL.md` or `references/` must rebuild and commit its package in the same change.
- Expect the gate job to get **slower**, not faster: 55 real packager invocations replace 55 immediate failures. A runtime increase is the fix working.
- The warn-log graduation clock for this sentinel restarts at slot 1; pre-release history carries no information about false positives.
- The pattern this release establishes — substituting a positive falsification test for a passive review window — is the generalisable answer for the other five warn-mode sentinels.

### Cross-references

- Release plan: this file, top section
- Milestone: `freshness-gate-measures-then-blocks`
- User-facing release notes: authored at Stage 13 Close per the release-notes standard; a version-less release files its note under the unversioned notes home.

---

## Deployment Execution Log

*(Populated during Stage 12.)*

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | | |
| Merge PR | | | |
| Tag release | | N/A | Version-less — no tag is claimed |
| Skill deployment | | N/A | No skill source edited |
| Manifest execution | | N/A | No Layer-2 propagation target |
| Post-execution verification | | | |
