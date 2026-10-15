---
title: Release Plan — ci-wiring-and-required-checks (eight CI and pipeline controls reach the class they name, not the instance first seen)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.75; the concrete number binds at the Stage-12 atomic claim)
milestone: ci-wiring-and-required-checks
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH — every card reverts CHEAP on the branch and a merge revert restores `main`; the qualifications are in § Rollback Strategy — the operator's branch-protection registrations stay in place by default, the deployed rules mirror and skill copy are re-laid by the next deploy, and a claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `ci-wiring-and-required-checks`

**Milestone:** `ci-wiring-and-required-checks` (ms#396). The Stage-4 planning sub-task **#8160** carries the approved three-part plan, Addendum 1 (two parts, for the reopened #6179), the Gate 1 record, the scope-change realization record (PA-006), the addendum-gate record, the scaffolding record, the Tier-1 adjustment record, the gate-passage record and the **Collective Review scope-lock decision record** (comment 6202269172, 2026-10-15). The eight Stage-5 designs are on **#8238, #8242, #8246, #8250, #8254, #8258, #8262 and #8266**, their Phase A6.5 adversarial reviews on **#8276, #8278, #8279, #8281, #8287, #8282, #8285 and #8289**, and the per-card scope-lock records on the eight Stage-6 sub-tasks **#8239, #8243, #8247, #8251, #8255, #8259, #8263 and #8267**. This file is Engineering Commit 0, authored by #8239's spoke.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.75`**. The Stage-4 gate recorded `v4.74`; the sibling `telemetry-is-computable` merged and its close-out tagged `v4.74`, so the hub recorded the recomputed next-free `v4.75` on #8239 (comment 6202378482, a recorded determination, not a gate). The concrete version binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the release-version stamp placeholder. Both halves of the Commit-0 re-verify ran — § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one branch `release/ci-wiring-and-required-checks`, one pull request opened in **draft** after Commit 0, one merge into `main`. **Concurrency posture:** **P0 fully serial** (PA-001) — eight cards in § Implementation Sequence order, one Engineering spoke at a time, each starting from the branch head; no force-push under any posture.

**Release class:** `cross-cutting` — trigger (a) on exactly three stage files (operator-ratified 2026-10-01; confirmed at the Stage-4 gate). Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the approved Stage-4 plan and Addendum 1 on #8160 and every decision record there, **amended by the Collective Review scope-lock** of 2026-10-15. The File Change Matrix, Contention Map, Risk Register, Verification Plan and Deviation Log carry the scope-lock's amendments, drawn from the eight Stage-5 designs, their Phase A6.5 reviews and decision-record addenda, the hub's carry-forward comment on each design sub-task, and the eight per-card scope-lock records. **Where a design and a scope-lock record differ, the record governs; each such difference is recorded in § Deviation Log.** Every thread comment consumed is `OWNER`-authored (Comment-Ingestion Trust Boundary). Rules are stated inline; issue numbers identify the cards and the records that decided them, and § Issue References closes the file.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version: the members change rule and protocol text inside existing files and add checks; no member adds a skill or a governance file). Provisional display v4.75 (re-determined from v4.74, which the sibling `telemetry-is-computable` claimed); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-10-15 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) landed; cards 1–8 pending |
| **Branch** | `release/ci-wiring-and-required-checks` |
| **Branch base** | `origin/main` @ `201970851da959db01111ef155f2f96d6676bfeb` (`20197085`, the merge of the `v4.74` Stage-13 chore PR) |
| **PR** | Draft, opened after Engineering Commit 0 (SINGLE topology); its number is recorded in the Commit-0 interim output on #8239 and written into this cell by #7036's plan-update commit; it transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `ci-wiring-and-required-checks` (ms#396) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-10-08, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every File Change Matrix row targets an internal platform artifact. The dominant deliverable class is `software` — one deploy script, eight workflows, four tools and three test suites, sixteen CLI modes; the secondary class is `governance` — pipeline specs, two rule files, one skill reference, one standard. Transcribed unchanged from the Stage-4 Phase A1.5 output and carried unchanged by every Stage-5 design (§ 5.7).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1–3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `20197085` (`201970851da959db01111ef155f2f96d6676bfeb`). The branch was created from it before this file was written; the release branch did not exist on the remote (re-checked with `git ls-remote --heads origin release/ci-wiring-and-required-checks` → empty) |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 201970851da959db01111ef155f2f96d6676bfeb --bump minor --dry-run` (the adapter's own `anchor()` and `claimed_set()`; no tag pushed) | **`v4.75`** (exit 0; "would claim v4.75 (no tag pushed)") — equal to the hub's recorded determination |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.7*'                       (tag arm — binds)
             gh release list (the published-Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md, filtered for v4.75 (ledger arm)
Denominator: 10 ls-remote lines (v4.70..v4.74, each with its peeled ref); the ledger at origin/main
Control - sensitivity: the same readers on the v4.74 slot — tag v4.74 (peeled ff3eecdf), Release
             v4.74 (published 2026-10-09), and 7 ledger lines naming v4.74. Every arm resolves and
             returns non-zero, so a zero on the v4.75 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple has
             no near-miss class the probe must reject
Extraction:  the full ls-remote output for the v4.7 prefix; the ledger read from origin/main
             (never the worktree copy)
Result:      0 occupants of the (4,75) slot on every arm
Verdict:     CLEAN — v4.75 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** one sibling release branch with a draft pull request, bump-class `minor`, recomputing `v4.75` (§ Cross-PR Overlap Audit → In-Flight Release Roster). Merge order arbitrates the slot at the Stage-12 compare-and-swap; the sibling has not claimed, so this is an enumeration, not a collision. Three other release hubs are in flight on the same version axis (the hub's recorded determination), so a later collision is expected to be caught at the Stage-12 claim, not prevented here.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp ci-wiring-and-required-checks`, run after this file was written and before it was committed; required exit 0. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal release-version stamp placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1`, `CIAC-2` as restated by Addendum 1) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (with the scope-lock amendments and the eight-card AC baseline) | § Verification Plan |
| 5 | Release-version stamp manifest (the placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA) | § Cross-PR Overlap Audit → Baseline SHA |

### Commit-0 pre-flight (risk R-10 — the sanctioned-session path)

Read-only at Commit 0:

- `release/skills/release-hub/SKILL.md:8` carries `skill_discipline_migrated_v10_2: true`, and `core/hooks/block-skill-direct-edit.sh:206` scopes `references/*.md` under a skill, so the skill gate binds `release/skills/release-hub/references/orchestration-playbook.md` — the one sanctioned surface left on #7036 (D-S5-6). Of the 61 distinct paths in § File Change Matrix, exactly 1 matches the gate's scope regex and 0 match the Tier-0 floor's three basenames (probe in § Agent-Editability Read).
- The `pmo-skill-editor` skill is listed for this session, so the sanctioned session (Mode A, targeted edit) is invocable. CR-17's Stage-12 routing sentence rides the same session (scope-lock record on #8239).
- **Verdict: PROCEED.** R-10's early warning is discharged at Commit 0 with no edit.

---

## Scope

### Issues Included

Eight content members. **26 raw points; 34 effective** under `cross-cutting` (round_half_up(26 × 1.3)) — 9 over the 15–25 band, accepted by the operator as an extension of the 2026-10-08 override D-A1 at the Collective Review (CR-1): #7036 S→M and #6203 XS→S, as their designs and reviews agreed.

| Order | Issue | Title (as filed) | Size | Pts | Stage-6 sub-task |
|---|---|---|---|---|---|
| 1 | #7036 | The parser-clean discipline names PR bodies only, so a commit-message close-verb auto-closed a member issue before its Stage 13 gate | M | 4 | #8239 |
| 2 | #7418 | install-tests timeout guard enumerates 4 suites while the workflow runs 32; 28 suite steps unbounded | M | 4 | #8243 |
| 3 | #7423 | Shared warn-mode emitter names a graduation form its own checks forbid | S | 2 | #8247 |
| 4 | #6179 | Six checks are declared posture=required and ci-enforce; branch protection enforces none of them | M | 4 | #8251 |
| 5 | #6203 | check-event-record-integrity.sh ships non-executable, so the invocation Stage 12 mandates fails | S | 2 | #8255 |
| 6 | #7491 | The post-merge deploy hook omits the release flag, so the first deploy after every release merge emits no deployment-status rows | M | 4 | #8259 |
| 7 | #6888 | A sibling release's merge can darken another branch's CI with no push of its own | M | 4 | #8263 |
| 8 | #6855 | git-workflow.md claims the declaration obligation covers every marker class; the matchers enforce one | S | 2 | #8267 |

**Acceptance criteria.** Each criterion's single home is its issue body; § Verification Plan binds each by ordinal and never restates it. The bodies stay historical except where the hub's post-lock Tier-1 pass amends them (#7423 AC-2 under CR-11; #6888 criterion 4 under CR-20); an amended criterion's bound row is updated by that card's Stage-6 spoke in the same change.

### Exclusions

- **Closed member, attached:** #6112 — no gap review needed (its suite is still in the regression runner's executed array and the runner is workflow-invoked; Stage-4 closed-member check).
- **Coordination, not dependencies** (merge-order and file contention only): #7490 (ms#378, the same parser-clean discipline text as #7036); #6852 (ms#413, the matcher lines #6855 does not widen); #6356 (the post-merge hook #7491 no longer edits); #5287 (ms#334, in PR #7919, the marker-scan derivation); #8143 (the Stage-7 required-context read #6888's baseline touches); #8048 (the 128 KiB PR-body transport — named in #6179's `Close-keyword leak detection` hold); #7026 (ms#404, a warn-to-enforce graduation decision adjacent to #7423); #8092 (its first defect — the one live, undeclared required context — is handed to #6179 under D-A2 option B; its other two stay with it); #7670 (owns the flip that ends the `Cross-reference integrity` hold).
- **Explicit non-scope:** `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md` are not edited (the Tier-0 floor). Historical release records under `release/releases/` are never rewritten. The held contexts' warn-to-enforce flips are not claimed (§ Release Outcome Statement, "Not claimed").

---

## Decision Record

### Stage-4 plan gate (operator, 2026-10-08) — #8160 comment 6071836777

| Ref | Decision | Operator's choice |
|---|---|---|
| PA-001 | Plan approval and the Stage-6 concurrency posture (D-4) | **Approve as drafted** — P0 fully serial |
| PA-002 · D-1 | Outcome clause 5 and the population install-tests bounds | **Narrow the statement** to the criterion's glob |
| PA-003 · D-2 | Posture of the gates this release adds | **A — no operator step:** #6203's CI job and #6888's workflow declare a non-required posture; #7036's commit scan, scoped to release heads, is folded into the already-required commit-message job so it blocks from day one |
| PA-004 · D-3 | The nine declared-required contexts absent from live branch protection | **B — pull into this release** (realized by PA-006) |

Recorded determinations: D-Version (versioned, minor, provisional `v4.74` — since re-determined, below) · Release Class `cross-cutting` · Topology SINGLE.

### Scope-change realization (operator, 2026-10-08) — #8160 comment 6071891442

PA-006: **reopen #6179 with a one-card planning addendum.** The operator ruled that reopening a member already attached to the milestone is not an addition under the Composition Lock (`issues_added` = 0). The lock rule's silence on that case is filed as #8237.

### Addendum gate (operator, 2026-10-08) — #8160 comment 6072783657

| Ref | Decision | Operator's choice |
|---|---|---|
| PA-007 · D-A1 | Size of the refined #6179 | **Accept M, keep whole** — then 23 raw / 30 effective, an override of the 15–25 band |
| PA-008 · D-A2 | The one live required context no header declares (`Close-out automation smoke (macOS)`) | **B — resolve it in this release** |
| PA-009 | The drafted card on the Composition Lock's silence about reopened members | **File it as shown** |

### D-Version (recorded determination) and its re-determination

- **At the Stage-4 gate:** versioned · bump-class `minor` · provisional `v4.74` (the adapter's dry-run at `4babbba9`). CHEAP / HIGH.
- **Re-determined before Commit 0 (hub, 2026-10-15 — #8239 comment 6202378482):** the sibling `telemetry-is-computable` merged and its close-out tagged `v4.74`; the recomputed next-free for a minor bump is **`v4.75`**, provisional. Not a gate. The Commit-0 re-verify above confirms it.

### Collective Review scope-lock (operator, 2026-10-15) — #8160 comment 6202269172

**Verdict:** the scope-lock is approved as the hub recommended; **scope is hard-locked through Stage 9**. Any later change is a governed override with its own briefing and impact assessment. Stage 6 is authorized — serial posture P0, #7036 first; #7423 and #6888 build after their bounded Solutioning revisions are consumed.

| Q | Ref | Decision |
|---|---|---|
| Q1 | PA-013 | **Scope-lock approved as recommended** — every row CR-1 to CR-26 as recommended; resolutions 2(a) to 2(d) and R-5 are lock conditions; the baseline-pin N-way row is overridden |
| Q2 | PA-014 | **#6179 vs ADR-183: hold and route** — the `Behavioral-regression pass-rate gate` row stays as ADR-183 has it this release; the record's internal conflict (Decision 3's advisory pull-request rung against the registration step Decision 5 imported) goes to a decision of its own, which the hub routes |
| Q3 | PA-015 | **#6203 ships enforcing at deploy time on day one, as an operator-ratified exception** to ADR-135 clause 3 and its rejected alternative A2 — basis: the whole firing population was read (110 interpreter-line files, 21 firings, 16 true positives, 5 named exemptions) and the remedy is one command |
| Q4 | PA-016 | **#6888: readers at the event** — the routing-pass step is dropped; the merging release's Stage-12 tail runs the sweep after its merge and reports darkened pull requests, and a spoke that pushes to a release branch checks mergeability after its push; size stays M |

**N-way override (verbatim):** "Override: convention baseline-pin accepted as diverged because Stage 6 re-derives every anchor from the branch head. Deviation logged for Stage 13 retrospective."

| Row | Card | Ruling |
|---|---|---|
| CR-1 | release | Size **26 raw / 34 effective** accepted as an extension of D-A1; release kept whole. #7036 S→M, #6203 XS→S |
| CR-2 | release | (a) a scope-lock record on every card's Stage-6 sub-task; (b) a bounded Solutioning revision for **#6888** (Q4) and **#7423** (CR-26) before their Stage 6 |
| CR-3 | release | One intake pass after the lock — existing owners searched first; anything implying a governance-file change surfaced for sign-off. The #6855 residual card (presence runner, fail-loud malformed-marker report, binding assertion) is filed beside the open card on the same matchers |
| CR-4 | release | A peer message to the `controls-fail-loud` hub session: whichever release merges second owes one exemption row for #6203's check |
| CR-5 | release | Outcome wording (i), (ii) and (iii) applied to the milestone description (§ Release Outcome Statement carries the result) |
| CR-6 | #7036 | **Keep the ratified scan scope — release heads only.** Do not block non-release heads |
| CR-7 | #7036 | Endorse the ADR-135 reading for the register row: the gate enforces from its first run, and measuring specificity over the whole history first (22 of 22 true over 5,465 messages) takes it outside ADR-135's ground for rejecting alternative A2. The register row states this |
| CR-8 | #7418 | Three-fold budget multiplier as designed, with the review's F-3 (one runner step set to its twin's budget) |
| CR-9 | #7418 | Job-level timeout taken (D-S5-5) as its own commit, with the review's C-3 values |
| CR-10 | #7423 | Review C-1 — cover the class (seven checks), not the first-seen instance; still S |
| CR-11 | #7423 | D-6 option (b) — the doc-link arm prints no mode-file instruction; the hub amends AC-2 |
| CR-12 | #6179 | Q2 above |
| CR-13 | #6179 | D-A, D-B and D-D to D-G accepted as recommended: an advisory reconciler whose verdict check turns red on a measured divergence and is skipped on `NOT-EVALUATED`; the smoke workflow converted filter-free and its contexts declared (D-A2 option B); `Close-keyword leak detection` corrected to advisory and held; the exit-code and token change; the matrix with optional row O-1, not O-2. Size M |
| CR-14 | #6179 | Registration at Stage 12, as designed — not before this card lands |
| CR-15 | #7491 | Review C-2 — filter the stamped deploy's target set by roster membership, with F-1 folded in (an empty release key fails closed at all three touchpoints); C-1 not taken |
| CR-16 | #7491 | The design's calls accepted with the review's P-1 corrections: a stamped deploy states its target set and the bare form is refused; the decision record is written, ratifying at Stage 13 Close and citing ADR-186 and ADR-194; AC-1 graded as the live Phase C2 read at this release's own Stage 12 |
| CR-17 | #7491 | The B4 routing sentence is #7036's, ridden in its sanctioned session |
| CR-18 | #6888 | K3 — the read-only push-time detector; no write-scoped workflow token and no `pull_request_target` |
| CR-19 | #6888 | Q4 above |
| CR-20 | #6888 | The roster record is informational, not verdict-bearing; criterion 4 is reworded by the hub |
| CR-21 | #6203 | Q3 above |
| CR-22 | #6203 | The matrix: 12 of the 16 conditional mode rows fire, 4 are withdrawn (`path-leak-patterns.sh` stays `100644`, because making it executable turns the required `shell-tests` job red), plus two new files |
| CR-23 | #6855 | Narrow the rule to the one marker, re-based on the two standards (ADR-117's quoted line sits under its Consequences, not its Decision) |
| CR-24 | #6855 | Review C-1 replaces the replacement sentence: a row with no quantifier over other markers, plus one line of `core/ADRs/README.md` reconciled in the same commit (a third file; still S) |
| CR-25 | #6855 | Accepted knowingly: a `Runner: NONE` named gap, with the row's opening reworded so it does not read as partly enforced; AC-2 met by a recorded three-arm probe attached to the Stage-7 sub-task instead of a committed fixture |
| CR-26 | #7423 | The emitter mechanism takes ADR-193's closed-set token shape (the review's C-2), via a bounded Solutioning revision |

**Lock conditions:** **2(a)** the registration track is defined once, in #6179's Change 3f · **2(b)** a new self-testing tool's exit codes align: 2 = cannot assert, 3 = `NOT-EVALUATED` · **2(c)** every tool that builds a git fixture clears every variable `git rev-parse --local-env-vars` prints · **2(d)** #7036's and #6855's passages in `core/rules/git-workflow.md` carry one runner-label token, so #6855's third criterion's count reads 2 · **R-5** this plan's stamped-deploy row takes the B4 form at Commit 0 (§ Delivery Strategy, § Operational Deployment Manifest).

**Fold-ins named by the per-card scope-lock records** (each card's Stage-6 spoke builds them; the record on its sub-task governs): #7036 — P-1 (11 commit-driven closures on record, 7 of them undeclared) and F-1 with ADR-052 (the printed lease-push remedy conditioned on single-writer state, in its three places). #7418 — F-1 with C-1(a) (one committed integer as a population tripwire), C-2 (a ceiling on what counts as a bound), the two new files, and an ADR-119 citation. #7423 — F-3 (a stale-claim limb in the arm) and F-4 (edges E1 and E7 restated; under Q3 #6203 makes no emitter call, so E1 is contractual only). #6179 — C-3, P-2, F-1 to F-4. #6203 — F-1's mitigations (a trace row and a banner sentence), F-2 to F-5, P-2, C-2, and CR-4's merge-order obligation. #7491 — the sibling-merged-first reconcile (one sentence of the cycle-time standard and the shared comment block in the deploy tool) and R-4 per its carry-forward comment. #6888 — F-3, F-4, F-5, P-4, P-5, C-3, the eight-path matrix. #6855 — F-2 (its register row rides the late commit), F-4, P-2.

**Minor review findings** not named by a record are not decided at Stage 6; they are seeded into § Deviation Log at Commit 0 and carried to Stage 9.

---

## Dependency Graph

**Native edges (GitHub Issue Dependencies API): none** — measured at Stage 4 on all eight members (14 reads on the seven, 2 on #6179, each with a control card that returns edges).

**Derived edges** (Stage-4 analysis and Addendum 1, with the scope-lock's restatements):

| # | Edge | Class | Basis and current state |
|---|---|---|---|
| E1 | #7423 → #6203 | build → **contractual only** | Under Q3 #6203's check enforces at deploy time and makes no warn-emitter call, so #6203 does not read #7423's emitter contract (#7423 record, F-4). The order stands |
| E2 | #7036 → every later commit on the branch | process | The rule #7036 writes binds every commit message from Commit 0; from #7036's step commit the required job scans every commit on this release head |
| E3 | #7036 → #6855 | compositional → **does not fire** | #7036 adds no override marker and no marker matcher (design D-S5-4), so the matcher population #6855 reconciles is unchanged |
| E4 | #6203 → any later card adding a shebang-bearing file under the two tool directories | compositional | #7036's tool and #6888's tool ship `100755`; #7036's INT-1 asserts its mode at the release head |
| E5 | #7418 → any later card wiring a `core/deploy/tests/` suite step | compositional | A suite step added after #7418 must carry `timeout-minutes` or the job reddens |
| E6 | file contention | — | § Contention Map |
| E7 | #7423 → #6179 | build, conditional → **does not fire** | #6179's design homes no deploy-time arm in `core/deploy/deploy.sh` |
| E8 | #7418 → #6179 | compositional, conditional → **does not fire** | #6179 wires no new `core/deploy/tests/` suite step into `install-tests.yml` |
| E9 | #6179 → #6203, #6888 | compositional | Their new gate headers are written against #6179's settled definition of divergence |
| E10 | #6179 ↔ #7036 | shared decision surface | #7036's register row points at the `Close-keyword leak detection` row of the registration-disposition table rather than restating it, so the two cannot disagree (#7036 design D-S5-7). The token is re-read when the late register commit lands (DEV-17) |
| E11 | #6179 ↔ #6888 | compositional | The Stage-12 registration moves the required-context count (18 → 22 by #6179's design); #6888's baseline treats it as a recorded change, not a darkening (IP-12) |
| E12 | #6179 ↔ #6203 | file contention | `core/deploy/tools/reconcile-gate-posture.py`: content (#6179, order 4), then mode bit (#6203, order 5) |

No circular chain. Cross-milestone: coordination only (§ Scope → Exclusions).

---

## Implementation Sequence

**Topology:** D-C SINGLE, one branch, P0 fully serial. One Engineering spoke at a time; each starts from the branch head with the earlier cards on it, **re-derives every anchor from the branch head** (the N-way override), syncs by merging `origin/main` into the branch (no rebase, no force-push), commits per slice and pushes each slice as it lands.

| Order | Work | Stage-6 sub-task | Execution path | Why here |
|---|---|---|---|---|
| **0** | Engineering Commit 0 — this file | #8239 | ordinary Engineering spoke | The plan, with the Commit-0 re-verify (steps 1–3, then 3b) and the R-10 pre-flight |
| **1** | #7036 | #8239 | ordinary spoke for the tool, fixture, workflow step and document edits; **sanctioned session** (`pmo-skill-editor` Mode A) for the playbook, with the package rebuild inside it | The one sanctioned-session card, so a gate failure surfaces at the first spoke; it writes the commit-message rule every later commit obeys (E2) |
| **2** | #7418 | #8243 | ordinary spoke | Its timeout invariant exists before any later card wires a suite step (E5) |
| **3** | #7423 | #8247 | ordinary spoke, **after its bounded Solutioning revision (CR-26) is consumed** | Head of the deploy-script chain; settles the shared warn-emitter contract |
| **4** | #6179 | #8251 | ordinary spoke | Settles the definition of divergence before #6203 and #6888 write gate headers (E9) |
| **5** | #6203 | #8255 | ordinary spoke | Lands the mode gate before the remaining cards add files (E4) |
| **6** | #7491 | #8259 | ordinary spoke | Deploy tool, Stage-12 text and tests; after #7036 so its `stage-12-execute.md` anchors are settled |
| **7** | #6888 | #8263 | ordinary spoke, **after its bounded Solutioning revision (Q4) is consumed** | New workflow and tool, Stage-7 baseline, the readers at the event |
| **8** | #6855 | #8267 | ordinary spoke | Reads the final matcher population; its rule row lands after #7036's passage in the same file |
| **late** | Release-wide register commit | the hub routes it | ordinary spoke | Every gate-coverage register row this release owes, and #6179's regions of the same standard, land in **one** late commit as one hunk (R-11, R-21) — after every runner pointer they name exists on the branch |

**Change specifications.** Each is the card's Stage-5 design as its scope-lock record amends it; the design comments are the spec anchor each card reads directly. Line anchors in the designs are `4babbba9` positions (several designs re-pinned at `2de37298` or `ff3eecdf`); every card re-anchors by content at the branch head.

- **Card 1 — #7036** · M · design on #8238 (comments 6074715938 to 6074721309); review on #8276 with its decision-record addendum; carry-forward comment 6075359059; scope-lock record on #8239.
  - **New tool** `core/deploy/tools/check-commit-close-keywords.py` (tracked `100755`) and its fixture `core/deploy/tools/fixtures/commit-close-keywords/cases.txt`: the commit-message arm of the close-keyword parser-clean discipline — the host's documented grammar (nine keywords as a whole word; a colon or blanks; an issue reference in any documented form; a bare number is never a reference), line by line, report never echoing message text, exit 0 clean · 1 finding · 3 not evaluated. The printed remedy is conditioned on single-writer state per review F-1 and ADR-052 (fold-in).
  - **Thin-caller step** in the required `Commit-message depersonalization gate` job (`.github/workflows/commit-message-depersonalization.yml`): self-test, then the scan over the PR's `base..head` range, on `release/*` heads only (CR-6); the job's `name:` and its `gate-efficacy:` declaration line untouched.
  - **Regenerated manifest** `core/deploy/allowlists/selftest-coverage-manifest.txt` (never hand-edited) and **one inventory row** in `core/deploy/tools/README.md`, in the tool's commit.
  - **The discipline restated once** in `core/rules/git-workflow.md` (§ Commit Messages bullet; the canonical bullet naming all three parser inputs — title, body, commit messages — with the title rule cross-referenced; the commit-message trap rewritten per review P-1 to lead with the plain declaration line in a commit body, with the partitive and the colon as its disguised forms, and conditioned per F-1; the two-arm spot-check; the enforcement bullet carrying the runner-label token `**Runner: NONE — a registered named gap.**` per lock condition 2(d)), and projected into `release/references/how-to/hub-spoke-bridge.md` (heading renamed to "Close-Keyword Parser-Clean Discipline", two-arm self-check and its result line, the history sentence restated as the measured series per P-1), `release/references/pipeline/stage-12-execute.md`, `release/references/pipeline/stage-13-close.md`, `release/references/specs/release-personas.md` and `core/disciplines/operating-model.md`.
  - **Sanctioned session** (`pmo-skill-editor` Mode A) for `release/skills/release-hub/references/orchestration-playbook.md`: the prompt-construction list member renamed, and the Stage-12 routing sentence that names B1, B3 and B5 also names B4 (CR-17); then `packages/release-hub.skill` and its `.sha256` sidecar rebuilt in the same PR.
  - **Owed to the late register commit:** two gate-coverage register rows — the commit-message arm (with CR-7's ADR-135 sentence) and the class 3-O named gap for the pre-push self-check. Change 13 (`CONTRIBUTING.md`) does not fire: CR-6 keeps the ratified scope.
- **Card 2 — #7418** · M · design on #8242 (comments 6075552232 to 6075554516); review on #8278 with its addendum; carry-forward 6076047874; scope-lock record on #8243. The guard becomes one committed suite `core/deploy/tests/test_install_tests_step_timeouts.py` with a labeled fixture `core/deploy/tests/fixtures/step-timeouts/labeled-steps.yml`, called by the falsification probe's first arm; every suite-invoking step of `.github/workflows/install-tests.yml` gains a measured `timeout-minutes` (CR-8, with F-3); the job-level timeout lands as its own commit with the review's C-3 values (CR-9); fold-ins F-1 with C-1(a) and C-2; ADR-119 cited. One register row owed to the late commit.
- **Card 3 — #7423** · S · design on #8246 (comments 6078893759 to 6078895205), **superseded in its emitter mechanism by the bounded Solutioning revision CR-26 sends it through** (posted on #8246); review on #8279 with its addendum; carry-forward 6079610363; scope-lock record on #8247. `core/deploy/deploy.sh` (the shared emitter and the class of seven checks, CR-10) and `core/deploy/tests/test_advisory_emitter_contract.sh`. **Provisional** until the revision is consumed.
- **Card 4 — #6179** · M · design on #8250 (comments 6079985639 to 6079989701); review on #8281; carry-forward 6080746836; scope-lock record on #8251. The reconciler `core/deploy/tools/reconcile-gate-posture.py` and its workflow; the smoke workflow converted filter-free and declared; `Close-keyword leak detection` corrected to advisory and held; the `Behavioral-regression pass-rate gate` held as ADR-183 has it (Q2 — no advisory correction, no "registration is not a graduation step" text); the registration track defined once (lock 2(a), Change 3f); registration of four contexts at Stage 12 (CR-14). Its regions of the gate-efficacy standard land in the late commit.
- **Card 5 — #6203** · S · design on #8254 (comments 6085968415 to 6085971415); review on #8287; carry-forward 6086871628; scope-lock record on #8255. New tool `core/deploy/tools/check-tool-exec-mode.py` (`100755`) and its list `core/deploy/allowlists/skip-tool-exec-mode-check.txt`; 16 mode-only changes (the four named CLIs and 12 of the 16 unnamed files, CR-22); a deploy-time check enforcing on day one (Q3) and a `repo-integrity.yml` job; exit codes per lock 2(b); the git-environment strip per lock 2(c); CR-4's exemption row for `release/tools/lib/host-refusal-class.sh` if it is on `main` when the card builds.
- **Card 6 — #7491** · M · design on #8258 (comments 6081123527 to 6081127051); review on #8282; carry-forward comments 6081901270, 6081911842 and 6084324580; scope-lock record on #8259. A stamped deploy states its target set (`--no-targets`, the bare form refused) in `core/deploy/deploy.sh`; Stage-12 Phase B4 derives targets from the merge, filtered by roster membership (CR-15), with the empty-key fail-closed fold-in; the Phase C2 row read; `core/rules/skill-deployment.md`; the hook test and the deploy honesty suite; one line of `release/references/standards/partial-deployment-recovery.md`; the decision record (CR-16); the sibling-merged-first reconcile in `release/references/standards/deployment-cycle-time.md`. The post-merge hook source is **not** edited.
- **Card 7 — #6888** · M · design on #8262 (comments 6084048073 to 6084052757), **amended by the bounded Solutioning revision Q4 sends it through** (posted on #8262); review on #8285; carry-forward 6085273658; scope-lock record on #8263. The read-only push-time workflow and its tool; the Stage-7 baseline; the readers at the event (Q4). **Provisional** until the revision is consumed.
- **Card 8 — #6855** · S · design on #8266 (comments 6086807418 to 6086808672); review on #8289; carry-forward 6087572295; scope-lock record on #8267. Narrow the declaration-obligation row in `core/rules/git-workflow.md` § Repository-Integrity Gates (CR-23, CR-24's claim-free row), one reconciled line of `core/ADRs/README.md`, the `Runner: NONE` named gap (CR-25; the same token as #7036's passage, lock 2(d)). Its register row rides the late commit.

---

## Stage Applicability Matrix

Stage-5 activation (`core/standards/planning-solutioning-handoff.md` § 3–4): all eight fire; release-level rollup **ACTIVATE**. Stages 5–8 run per issue; Stages 9–13 are release-scoped.

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | 5 | 6 | 7 | 8 | 9–13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| #7036 | ✗ | ✓ | ✗ | ✓ | ✗ | ✓ | ACTIVATE | ✓ | ✓ (sanctioned session) | ✓ | ✓ | release-scoped |
| #7418 | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ | ACTIVATE | ✓ | ✓ | ✓ | ✓ | 〃 |
| #7423 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | ✓ (+ bounded revision) | ✓ | ✓ | ✓ | 〃 |
| #6179 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | ✓ | ✓ | ✓ (tree side) | ✓ (tree side) | 〃 — registration graded at Stage 12 by read-back |
| #6203 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | ✓ | ✓ | ✓ | ✓ | 〃 |
| #7491 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | ✓ | ✓ | ✓ | ✓ | 〃 — AC-1 graded at Stage 12 (CR-16) |
| #6888 | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | ✓ (+ bounded revision) | ✓ | ✓ (fixture) | ✓ (fixture) | 〃 — first real observation post-merge |
| #6855 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | ✓ | ✓ | ✓ | ✓ | 〃 |

Release-scoped sub-tasks: Stage 9 #8270 · Stage 10 #8271 · Stage 11 #8272 · Stage 12 #8273 · Stage 13 #8274. **Stages 10 and 11 stay open, not compressed**, for the one out-of-tree component — the operator's registration of required status contexts on `main` (scaffolding record, #8160 comment 6072881991); everything tracked in git stays compressed.

---

## File Change Matrix

Machine-readable form, one path per line. Rows whose condition fired at or before Commit 0 are promoted into their card's block; rows that stay conditional carry a condition token. Mode-only changes are `EDIT` rows. **#7423's and #6888's rows are provisional** until their bounded Solutioning revisions are consumed: each card's Stage-6 commit promotes, adds or records its rows against its revision.

```
# ── release-wide ──
release/releases/plans/ci-wiring-and-required-checks_RELEASE_PLAN.md  ADD
core/standards/gate-efficacy-standard.md  EDIT

# ── #7036 — the close-keyword discipline covers every parser input (order 1) ──
core/deploy/tools/check-commit-close-keywords.py  ADD
core/deploy/tools/fixtures/commit-close-keywords/cases.txt  ADD
.github/workflows/commit-message-depersonalization.yml  EDIT
core/deploy/allowlists/selftest-coverage-manifest.txt  EDIT
core/deploy/tools/README.md  EDIT
core/rules/git-workflow.md  EDIT
release/references/how-to/hub-spoke-bridge.md  EDIT
release/references/pipeline/stage-12-execute.md  EDIT
release/references/pipeline/stage-13-close.md  EDIT
release/references/specs/release-personas.md  EDIT
core/disciplines/operating-model.md  EDIT
release/skills/release-hub/references/orchestration-playbook.md  EDIT
packages/release-hub.skill  EDIT
packages/release-hub.skill.sha256  EDIT

# ── #7418 — the timeout guard becomes an invariant (order 2) ──
.github/workflows/install-tests.yml  EDIT
core/deploy/tests/test_install_tests_step_timeouts.py  ADD
core/deploy/tests/fixtures/step-timeouts/labeled-steps.yml  ADD

# ── #7423 — the warn emitter prints the caller's graduation form (order 3; provisional) ──
core/deploy/deploy.sh  EDIT
core/deploy/tests/test_advisory_emitter_contract.sh  EDIT

# ── #6179 — declared and live required contexts reconciled (order 4) ──
core/deploy/tools/reconcile-gate-posture.py  EDIT
.github/workflows/gate-posture-reconciliation.yml  EDIT
core/deploy/tools/lint_release_corpus.py  EDIT
.github/workflows/release-tooling-smoke.yml  EDIT
.github/workflows/pr-body-parser-clean.yml  EDIT
.github/workflows/security.yml  EDIT
.github/workflows/eval-viewer-tests.yml  EDIT
core/deploy/tests/test_gate_efficacy_declarations.py  EDIT
.github/deploy-check-ci.enforce  EDIT

# ── #6203 — tool-mode class check (order 5) ──
core/deploy/tools/check-tool-exec-mode.py  ADD
core/deploy/allowlists/skip-tool-exec-mode-check.txt  ADD
release/tools/check-ac-binding.py  EDIT
release/tools/check-adr-durability.py  EDIT
release/tools/check-selftest-coverage.py  EDIT
release/tools/generate-adr-index.py  EDIT
core/deploy/tools/backfill-relationship-edges.py  EDIT
core/deploy/tools/build-doc-index.py  EDIT
core/deploy/tools/check-adr-flip.py  EDIT
core/deploy/tools/check-doc-frontmatter.py  EDIT
core/deploy/tools/check-host-binding.py  EDIT
core/deploy/tools/check-identity-conformance.py  EDIT
core/deploy/tools/check-issue-ref-validity.sh  EDIT
core/deploy/tools/check-pv7-vocabulary.sh  EDIT
core/deploy/tools/check-rules-budget.py  EDIT
core/deploy/tools/compose-portfolio.py  EDIT
core/deploy/tools/stamp-node-frontmatter.py  EDIT
.github/workflows/repo-integrity.yml  EDIT

# ── #7491 — the release's Stage-12 deploy is stamped (order 6) ──
core/hooks/tests/git-post-merge-deploy.test.sh  EDIT
core/rules/skill-deployment.md  EDIT
core/deploy/tests/test_deploy_detection_honesty.sh  EDIT
release/references/standards/partial-deployment-recovery.md  EDIT
release/references/standards/deployment-cycle-time.md  EDIT
core/ADRs/ADR-NNN-release-identity-is-stamped-at-stage-12.md  ADD

# ── #6888 — darkening detected at the event (order 7; provisional) ──
.github/workflows/sibling-merge-dark-branch.yml  ADD
release/tools/check-dark-branch.py  ADD
release/references/pipeline/stage-07-dev-testing.md  EDIT
release/references/pipeline/stage-08-qa-testing.md  EDIT
release/tools/automated-closeout.sh  EDIT

# ── #6855 — the declaration-obligation row states its scope (order 8) ──
core/ADRs/README.md  EDIT

# ── CONDITIONAL — each row moves to the block above in the commit where its condition fires ──
.github/workflows/behavioral-regression.yml  EDIT  CONDITIONAL:behavioral-regression-hold-text-owed-under-Q2
.github/behavioral-regression.enforce  EDIT  CONDITIONAL:behavioral-regression-hold-text-owed-under-Q2
release/skills/release-hub/SKILL.md  EDIT  CONDITIONAL:release-hub-version-bumped-in-sanctioned-session
```

#### Read-only inputs

```
release/tools/version-grammar.sh  READ
core/ADRs/ADR-165-post-merge-skill-deploy-is-a-local-git-hook.md  READ
core/schemas/gate-criteria-spec.md  READ
core/deploy/tools/build-skill-packages.sh  READ
.github/workflows/link-check.yml  READ
.github/workflows/skill-count-imp-check.yml  READ
.github/workflows/deploy-check-ci.yml  READ
core/hooks/git-post-merge-deploy.sh  READ
```

#### Release-wide explicit non-scope

```
core/governance/OPERATIONS.md  NOT EDITED
operations/OPERATIONS.md  NOT EDITED
release/governance/RELEASE_PROTOCOL.md  NOT EDITED
```

Matrix notes:

1. **Paths several cards share appear once.** `core/deploy/deploy.sh` (#7423, #6203, #7491); `core/deploy/tools/README.md` (#7036, #6179, #6203); `core/deploy/allowlists/selftest-coverage-manifest.txt` (#7036, #6203, #6888 — regenerated, never hand-merged); `release/references/how-to/hub-spoke-bridge.md` (#7036, #6888); `core/rules/git-workflow.md` (#7036, #6855); `release/references/pipeline/stage-12-execute.md` (#7036, #7491, and #6888 under Q4); `core/deploy/tools/reconcile-gate-posture.py` (#6179 content, #6203 mode bit); `core/standards/gate-efficacy-standard.md` (every gate-adding card, in the late commit).
2. **Unconditional ADDs: 10** — the plan file; #7036's tool and fixture; #7418's suite and fixture; #6203's tool and list; #7491's decision record; #6888's workflow and tool. These are what the delivery check compares against the merged diff.
3. **#7491's decision record** is written in the `ADR-NNN` placeholder form because its number binds when #7491 builds: at Commit 0 `python3 release/tools/renumber-adr.py --detect` reads ANCHOR 216 on `origin/main` and NEXT-FREE 217, with 217 and 218 claimed branch-only by the open sibling #7919 (detection only, never binds) — whichever release merges second renumbers (DEV-20).
4. **The two remaining conditional rows** are recorded rather than decided. The `Behavioral-regression pass-rate gate` rows fire only if #6179's build owes hold text there under Q2 — the advisory correction the design specified is withdrawn by Q2, and the card's spoke surfaces to the hub if the reconciler cannot express the hold without it. The `release-hub` `SKILL.md` row fires only if the sanctioned session bumps the skill's `version:` (the version-bump decision is the editor's; the playbook edits rename a label and add one routing term).
5. **Dropped rows** — § Deviation Log: `.github/workflows/commit-parser-clean.yml` (a conditional ADD, NOT DELIVERED); the three `release-executor` rows (EDIT); the four withdrawn mode rows; #6855's six `matchers-widened` rows; #7423's four rows under `graduation-form-homed-in-hook-registry` and `mode-file-form-reconciled`; #7036's three candidate surfaces; #7491's hook source and its two second-deploy-path rows; #6888's three conditional rows.
6. **New-executable companion obligation:** no unconditional ADD is a shell script, so no `core/config/allowlists/script-execution-allowlist.txt` row is owed; each new tool is Python run through an interpreter, whose allowlist section is filled from observed traffic, not in advance.
7. **Mirror pairs.** `core/rules/git-workflow.md` and `core/rules/skill-deployment.md` are mirror-pair sources; their deployed copies are re-laid by the Stage-12 deploy, never by this release's commits. A Check 9 finding on either is expected before merge.
8. **Placement:** no rename, relocation or delete; every new file sits at a current-main path.

---

## Agent-Editability Read

Controls re-read at the branch base `20197085`: the Tier-0 floor (`core/hooks/block-autonomy-ceiling.sh`, the three floored basenames `CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`; the repository tracks 0 paths under `.claude/`) and the sanctioned-session gate (`core/hooks/block-skill-direct-edit.sh:206`, `SKILL_SCOPE_RE`; arming key at `:276`).

```
Probe:       the gate's scope regex and the floor's basename set over the 61 distinct matrix paths
Denominator: 61 paths (every row of § File Change Matrix, conditional rows included)
Control - sensitivity: release/skills/release-hub/SKILL.md matches the regex; the basename of
             release/governance/RELEASE_PROTOCOL.md is in the floor set
Control - specificity: a skill script path (release/skills/release-hub/scripts/x.sh) does not match
Extraction:  the full path list
Result:      Tier-0 ∩: 0 of 61. Skill-gate conjunct 1: 1 of 61
Verdict:     CLEAN
```

| Card | Path | Tier-0 ∩ | Skill-gate ∩ | Class | Execution path |
|---|---|---|---|---|---|
| #7036 | `release/skills/release-hub/references/orchestration-playbook.md` | no | **yes** — scope regex true; `release/skills/release-hub/SKILL.md:8` carries the arming key | `sanctioned-session-required` | `sanctioned-session: pmo-skill-editor Mode A` |
| #7036 | `packages/release-hub.skill`, `packages/release-hub.skill.sha256` | no | n/a — produced by `core/deploy/tools/build-skill-packages.sh` | class of source | build script, run inside the session |
| #7036 | every other row of the card | no | no | `unconstrained` | ordinary Engineering spoke |
| all other cards | every row | no | no | `unconstrained` | ordinary Engineering spoke (provisional for #7423 and #6888, whose revisions could add a skill surface) |

`#7036` is the release's only sanctioned-session card; its sanctioned surface narrowed from two files to one (D-S5-6: `release/skills/release-executor/SKILL.md:302` is a scope-neutral mention). An `unconstrained` row means no control refuses the write; the workflow, rule, spec and standard edits are governed changes approved through this plan.

---

## Contention Map

### Within-release contention

| File | Cards | Region relation |
|---|---|---|
| `core/deploy/deploy.sh` | #7423, #6203, #7491 | disjoint regions (the emitter and seven call sites; one new check block; the deploy function, usage and help); serial order resolves it |
| `core/deploy/tools/README.md` | #7036, #6179, #6203 | one inventory row each, plus one coverage-rule sentence (#6203) |
| `core/deploy/allowlists/selftest-coverage-manifest.txt` | #7036, #6203, #6888 | generated and sorted — regenerate, never hand-merge |
| `release/references/how-to/hub-spoke-bridge.md` | #7036, #6888 (provisional) | the Stage-4 template's Scope block and Procedure 3 (#7036) against the Stage-9 mergeability read (#6888); about 1,145 lines apart |
| `core/rules/git-workflow.md` | #7036, #6855 | § Commit Messages and § PR Process step 5 (#7036) against § Repository-Integrity Gates (#6855); one runner-label token across both (lock 2(d)) |
| `release/references/pipeline/stage-12-execute.md` | #7036, #7491, #6888 (Q4) | #7036's one sentence near the chore-PR example; #7491's Phase B4 and C2; #6888's Stage-12 tail sweep under Q4 |
| `core/deploy/tools/reconcile-gate-posture.py` | #6179, #6203 | content, then mode bit; no textual contact |
| `core/standards/gate-efficacy-standard.md` | all gate-adding cards | one late commit, one hunk (R-11, R-21) |
| `packages/release-hub.skill` and `.sha256` | #7036 | rebuilt after every mainline sync (R-12) |

Resolution: the serial order. No scope split is needed for contention. Each Stage-6 spoke re-derives its anchors from the branch head.

### Cross-release contention

The one open sibling is `controls-fail-loud` (PR #7919, draft, `MERGEABLE` at Commit 0). Its 40 changed files intersect 12 matrix paths: `core/standards/gate-efficacy-standard.md`, `core/deploy/allowlists/selftest-coverage-manifest.txt`, `release/references/how-to/hub-spoke-bridge.md`, `release/references/pipeline/stage-13-close.md`, `packages/release-hub.skill`, `packages/release-hub.skill.sha256`, `.github/workflows/install-tests.yml`, `core/deploy/deploy.sh`, `.github/workflows/release-tooling-smoke.yml`, `core/deploy/tests/test_gate_efficacy_declarations.py`, `release/tools/automated-closeout.sh` and `core/ADRs/README.md`. Two semantic contacts: it adds `release/tools/lib/host-refusal-class.sh` at `100644` with an interpreter line, so whichever release merges second owes #6203's exemption row (CR-4, acknowledged by the other hub); and it adds ADR-217 and ADR-218, the slots #7491's record would otherwise take (DEV-20).

---

## Cross-PR Overlap Audit

### Baseline SHA

**`4babbba9`** (`4babbba94f3ddf99a658d39fc0dbb7af0f664066`) — the Stage-4 Phase A0 audit-start pin (2026-10-08T23:29:00Z), transcribed unchanged as Survival-Set row 9. The Stage-9 revalidation predicate (and Stage-12 A.5's) is `git log 4babbba9..origin/main --name-status --find-renames`, intersected with this release's matrix paths.

**Engineering Commit-0 branch base:** `20197085` (`201970851da959db01111ef155f2f96d6676bfeb`). Unlike a quiet window, this one **does** touch matrix paths — the sibling `telemetry-is-computable` merged in it — which is why the scope-lock overrode the baseline-pin convention (N-way override, DEV-1):

```
Probe:       git diff --name-only 4babbba9 20197085, intersected (exact line) with the 61 matrix paths
Denominator: 61 commits and 39 changed files in the window; 61 matrix paths
Control - sensitivity: the same intersection with release/releases/RELEASE_LOG.md as the only pattern
             → 1 hit (the probe sees a changed path when one is listed)
Control - specificity: NOT TRIGGERED — the match is whole-line and literal, so a partial-path
             near-miss is excluded by construction
Extraction:  the full 39-line name list; the full 61-line path list
Result:      10 matrix paths changed in the window — core/standards/gate-efficacy-standard.md,
             release/references/pipeline/stage-12-execute.md, release/references/pipeline/stage-13-close.md,
             release/skills/release-hub/references/orchestration-playbook.md, packages/release-hub.skill,
             packages/release-hub.skill.sha256, core/deploy/deploy.sh,
             .github/workflows/release-tooling-smoke.yml,
             release/references/standards/deployment-cycle-time.md, release/tools/automated-closeout.sh
Verdict:     MEASURED — the drift the N-way override names; every card re-anchors by content
```

### Open PRs and recently merged PRs

- **Stage 4 (at the pin):** 2 open PRs, both release siblings: #7919 (`controls-fail-loud`) and #7901 (`telemetry-is-computable`).
- **At Commit 0:** 1 open PR (`gh pr list --state open --limit 500` → 1 row): #7919. `telemetry-is-computable` merged as `v4.74` (PR #7901, merge `ff3eecdf`) with its Stage-12 and Stage-13 chores (PRs #8284 and #8301).

### Structural sub-audit

N/A — the matrix intents are {ADD, EDIT}: 0 renames, relocations or deletes, so the mover set is empty. Version axis: this release contributes `Δversion/4.75.0`, shared with the sibling below.

### In-Flight Release Roster

**Stage-4 measurement (transcribed):** measured at `4babbba9` · 2026-10-08T23:29:00Z · population n=2.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `controls-fail-loud` | `#7919` | `2b427a23` | `minor` | `v4.70` (stale) | `v4.74` | 7 unconditional and 6 conditional paths (the Stage-4 roster) |
| `telemetry-is-computable` | `#7901` | `037f29d3` | `minor` | `v4.70` (stale) | `v4.74` | 7 unconditional and 2 conditional paths (the Stage-4 roster) |

`telemetry-is-computable` has since merged and claimed `v4.74`.

**Commit-0 re-read** (a pinned measurement carrying no verdict; Stage 9 Phase A6.6 re-measures the population): measured at `20197085` · 2026-10-15T21:30Z · population n=1 (open PRs with a `release/*` head, drafts included, plus remote `release/*` heads with no PR, minus this release; `git ls-remote --heads origin 'refs/heads/release/*'` → 1 head, with a PR).

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `controls-fail-loud` | `#7919` | `76aadeb9` | `minor` | `v4.70` (stale — claimed since) | `v4.75` | the 12 paths listed in § Contention Map → Cross-release contention |

The sibling recomputes this release's slot, so the two are co-contenders for `v4.75`; merge order arbitrates at the Stage-12 compare-and-swap.

---

## Integration Points

| # | Surface | Parties | What must agree |
|---|---|---|---|
| IP-1 | The shared warn emitter's contract (`core/deploy/deploy.sh`) | #7423 and its existing callers; #6203 contractual only (Q3) | ADR-193's closed-set token shape (CR-26) and the class of seven checks (CR-10) |
| IP-2 | Gate posture headers and the gate-coverage register | #7036, #7418, #6179, #6203, #6888, #6855 | each new or changed gate declares a posture branch protection delivers, with a register row whose runner pointer resolves (late commit) |
| IP-3 | Live branch protection (out of tree) | #6179; the operator | the registered set after the Stage-12 step equals the REGISTER rows that passed AC-5's preconditions |
| IP-4 | The commit-message surface of the release PR | every card | G6-02 needs each member's number in a commit; the close-keyword rule forbids pairing it with a close-family verb; from #7036's step commit the required job enforces it on this release head |
| IP-5 | The override-marker matcher population | #6855 | unchanged by #7036 (no marker, no matcher); #6855 narrows the rule to the one marker |
| IP-6 | `install-tests.yml` step list | #7418 and any card adding a suite step | every suite-invoking step carries a timeout; the population is derived |
| IP-7 | Skill packages | #7036; the build script; the package-freshness gate | `release-hub` rebuilt in the same PR as the playbook edit, and after every mainline sync |
| IP-8 | Mirror pairs | #7036, #6855 (`git-workflow.md`), #7491 (`skill-deployment.md`) | source edited; mirror re-laid by the Stage-12 deploy |
| IP-9 | The stamped deploy and its rows | #7491; Stage 12 | targets derived from the merge and filtered by roster membership; an empty key fails closed; Phase C2 reads the rows |
| IP-10 | `deployment-status` rows and their consumers | #7491; the merged sibling's cycle-time standard | the sibling-merged-first sentence reconciled in `deployment-cycle-time.md` |
| IP-11 | The tool-mode population | #6203; #7036's and #6888's new tools | each new tool ships `100755` (#7036 INT-1) |
| IP-12 | The required-context count | #6179's Stage-12 registration; #6888's baseline | a registration is a recorded baseline change, not a darkening |

**Per-issue integration criteria from Stage 5 that name #7036** (graded at Stage 8 under the standard per-criterion enum): #7036 **INT-1** (× #6203 on the tool-mode population: at the release head the new tool is tracked `100755` and no exemption entry #6203 introduces names it); #7418 **INT-1** (× #7036 on the commit-message surface: each commit #7418 adds carries the card's number only as a trailing reference, with no close-family verb directly before any issue reference); #6855 **INT-1** and **INT-2** (× #7036 on `core/rules/git-workflow.md` and the register: the two passages' links to the standard use the same leading-`/` form, every named gap the rule sends its reader to has exactly one register row, and the two passages do not contradict each other on what is enforced).

---

## Risk Register

Each mitigation names the gate that would catch the risk. Tier is reversibility; L and I are likelihood and impact.

| ID | Risk | L / I | Tier | Mitigation and catching gate | Owner |
|---|---|---|---|---|---|
| R-1 | No size headroom | — | — | **Superseded by R-24** (Addendum 1); the band is now an operator override | operator |
| R-2 | A sibling merge darkens this release's PR | H / M | CHEAP | Stage-9 mid-pipeline divergence check (primary); Stage 7 and 8 entry checks; Stage-12 pre-merge check. Sync by merging `origin/main` into the branch, never by rewriting it | hub |
| R-3 | Version slot `v4.75` shared with the open sibling | H / L | CHEAP | Commit-0 re-verify (clean); Stage-12 pre-merge freeness check; the atomic claim arbitrates | hub |
| R-4 | **This release's own commit messages close a member issue at merge.** G6-02 requires each member's number in a commit, and quoting the defect string reproduces it. The record is not one instance: 11 commit-driven closures on the default branch, 7 of them through a pull request whose body declared no closure of that issue, 4 of those against an explicit `References` line (review P-1 on #8276). A pushed message changes only by a history rewrite pushed with a lease (`--force` is denied); ADR-052 names-and-excludes that push class for the shared release branch under multi-chip activity, so it is available only while the branch has a single writer, and under this release's P0 posture it is the operator's call | M / H | MODERATE for the message (a rewrite the operator authorizes, single-writer only); CHEAP for the issue state (reopen) | From #7036's step commit, the close-keyword step of the required `Commit-message depersonalization gate` job scans every commit message on this release head and fails on a pairing; before every push, the pre-push arm (the same tool over `origin/main..HEAD`); Commit 0 and #7036's tool commit are proven clean before the step is wired. Convention for every commit: the member's number only as a trailing parenthesised reference; no close-family verb directly before any issue reference; the defect described, never quoted | every Stage-6 spoke; hub |
| R-5 | #7423's emitter change reaches every caller | M / H | MODERATE | CR-26 — ADR-193's closed-set token shape via a bounded Solutioning revision; caught by the emitter contract suite (`core/deploy/tests/test_advisory_emitter_contract.sh`) and by the Stage-9 divergence check | #7423 spoke |
| R-6 | A new gate ships declaring a posture branch protection does not deliver | M / M | CHEAP | #6179's reconciler and the restated CIAC-2, graded at Stage 9 with a live read that returned | hub; operator |
| R-7 | #6888's push-time workflow cannot be exercised before merge | M / M | MODERATE | Stage 7 fixture mode or a declared deferral; first real observation recorded in the Stage-13 outcome window. Under CR-18 it holds no write scope | #6888 spoke |
| R-8 | #7491's fix does not reach every deploy path | M / M | MODERATE | CR-16: the release's own Stage-12 B4 stamps whatever deploy ran first; unstamped carriers (the hook, `update.sh`) stay unstamped by design; caught by the Phase C2 row read | #7491 spoke |
| R-9 | **A timeout sized too tight reddens healthy suites.** The four install-tests jobs are live required contexts, so a mis-sized budget blocks every PR in the repository | M / H | CHEAP | CR-8 — each step budget is three times the slowest observed CI run of that step, rounded up to five minutes with a five-minute floor, and one runner step takes its twin's budget (review F-3); the job-level limits land as their own commit with the review's C-3 values — `install-regression` sized above its two runner budgets in sequence, `cross-platform` given its own floor (CR-9). Caught by the four jobs on the release PR; one revert restores service | #7418 spoke |
| R-10 | **The sanctioned-session card burns a spoke.** An ordinary Engineering edit of a skill surface is refused or logged by the skill-edit gate | M / L | CHEAP | The sanctioned surface is one file — `release/skills/release-hub/references/orchestration-playbook.md` — and CR-17's routing sentence rides the same session; #7036 leads the sequence; discharged at Commit 0 by the pre-flight | hub |
| R-11 | Three-way append collision on the gate-coverage register | H / L | CHEAP | One late commit, one hunk; keep every side's rows. Caught as a merge conflict, never silently | late-commit spoke |
| R-12 | Skill packages conflict on every sibling merge | H / L | CHEAP | Rebuild after each mainline sync; caught by the package-freshness gate | #7036 spoke; hub |
| R-13 | Rule-text regression reaches every session | L / M | CHEAP | Stage-9 Deep review of the two passages in `core/rules/git-workflow.md`; mirror parity at deploy | hub |
| R-14 | Rollback leaves operator-side state | L / M | MODERATE | § Rollback Strategy; the registrations stay by default | operator |
| R-15 | The slug over-names the release | M / L | CHEAP | The Outcome Statement's "Not claimed" line | operator |
| R-16 | PR body size | L / M | CHEAP | Evidence lives in this file, not the PR body (two PR-body workflows fail past 131,072 bytes, #8048) | every spoke |
| R-17 | A registered context that does not report on every pull request | L / H | CHEAP | AC-5 (ii), read at the release head; the post-step roster equality on every open PR | #6179 spoke; operator |
| R-18 | A registered job that cannot fail | M / M | CHEAP | Only REGISTER-class rows are registered; the runner is read, not the declaration | #6179 spoke |
| R-19 | A newly required context binds every open PR at once | M / H | CHEAP | The per-PR read immediately before the step; `enforce_admins` is off; one settings action removes a context | operator; hub |
| R-20 | Ordering between the registration and the merge | M / M | CHEAP | No job `name:` of a live or to-be-registered context changes; one step with a read before and after; CIAC-2 holds on either side of it | hub; spokes |
| R-21 | The standard is contended on three sides | H / L | CHEAP | Late commit (R-11) | late-commit spoke |
| R-22 | Shared-parser drift (the reconciler imports a parser the sibling rewrites) | L / M | CHEAP | The declared count re-read after each mainline sync | #6179 spoke |
| R-23 | A merge-blocking check with an out-of-tree input | M / H | MODERATE | CR-13 keeps the reconciler advisory; a refused read yields neither verdict (AC-3 (b)) | #6179 spoke |
| R-24 | **Capacity: 34 effective points against a 25 ceiling** (CR-1) | H / M | CHEAP | Accepted by operator override (DEV-2); the relief valves stay named in the addendum | operator |
| R-25 | A card absorbs another card's work | M / M | CHEAP | D-A2 option B takes only #8092's first defect | operator |
| R-26 | Nothing in the tree proves the operator step happened | M / M | CHEAP | The read-back and a reconciler run with a returned live read, recorded on the release | hub |

---

## Delivery Strategy

| Element | Value |
|---|---|
| Topology | D-C SINGLE — one branch `release/ci-wiring-and-required-checks`, one release PR |
| Concurrency posture | **P0 fully serial** (PA-001) |
| Base | `origin/main` at Commit 0: `20197085` |
| PR | Opened as a draft after Commit 0; title `release(ci-wiring-and-required-checks): CI and pipeline controls reach the class they name`; made ready at the Stage-9 gate. Parser-clean body: the eight members appear in the Issue References block as `References`, and they are transitioned to closed at Stage 13 |
| Commits | Commit 0 = this file; then one or more commits per card in sequence order, each slice pushed as it lands; the release-wide register commit last. Messages carry the `release(ci-wiring-and-required-checks):` prefix; each member's number appears as a trailing parenthesised reference on at least one commit (G6-02); R-4's convention binds every message |
| Sync | `git fetch origin main`, then `git merge origin/main` on the branch at each stage entry; no rebase, no force-push |
| Sanctioned session | #7036's one skill surface (`orchestration-playbook.md`, with CR-17's sentence), followed by the `release-hub` package rebuild in the same PR |
| Generated files | Packages by `core/deploy/tools/build-skill-packages.sh`; the self-test manifest by `python3 release/tools/check-selftest-coverage.py --emit-manifest` |
| Stacked-base cleanup posture | n/a — no stacked PRs |
| Merge | By the Stage-12 procedure; the version is claimed atomically at the merge SHA by the claim tool with `--stamp-slug` passed explicitly |
| Stamped deploy (R-5, the B4 form) | Stage-12 Phase B4 as #7491 lands it — never the bare form the approved plan named, which #7491's change refuses. From the executor's worktree detached at an `origin/main` that contains the merge: the release key, bound once, read back non-empty before stamping (an empty key fails closed); the targets derived from the release's merge commit against its first parent and kept only when they are members of the deploy roster (CR-15); then `bash core/deploy/deploy.sh --deploy --release <milestone-slug> <target>…` with the targets named, or `bash core/deploy/deploy.sh --deploy --release <milestone-slug> --no-targets` when the derived set is empty. For this release the derived set is expected to name `release-hub`. No hook-bundle refresh is owed: no card edits a hook source |
| Operator-executed steps | **One:** registration of required status contexts on `main`'s branch protection at Stage 12, after the Stage-9 GO (CR-14) — the four contexts whose rows are REGISTER and whose AC-5 preconditions hold at the release head, by #6179's design. `Close-keyword leak detection` is corrected to advisory and held (CR-13); the four held contexts are never registered by this step. Pre-step and post-step reads per Addendum 1; the read-back is recorded on the release |

---

## Verification Plan

Every method cell carries its probe literally, reproducible from the cell alone. The plan-driven executor `release/tools/verify-release-plan.sh` runs a cell's one read-only command (`grep`, `test`, `ls`, `head`, `wc`, `cat`) or a scope assertion; a cell naming an interpreter run is declared deferred to the runner that executes it (ADR-207), and a limb only a reader can grade is marked `[READER-GRADED — …]` after the command's comparator (ADR-208). **Most rows of cards 2–8 are re-bound by that card's own Stage-6 spoke** in the commit where the card lands, to the method its locked design names; the Commit-0 rows below carry the binding that is settled now.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #7036 | AC-1a | `grep -c -F 'PR Body Parser-Clean' release/references/how-to/hub-spoke-bridge.md` expect 0 | zero · control: the same command at the branch base → 4 (the heading and its three references, one of them wrapped) |
| #7036 | AC-1b | `grep -c -F 'Close-Keyword Parser-Clean Discipline' release/references/how-to/hub-spoke-bridge.md` expect 4 | four — the heading and its three references, each on one line · at the branch base → 0 |
| #7036 | AC-1c | `grep -c -F 'Close-keyword parser-clean discipline (PR title, PR body, commit messages)' core/rules/git-workflow.md` expect 1 | one — the canonical bullet names all three parser inputs · at the branch base → 0 |
| #7036 | AC-2 | [DEFERRED — the sense-aware sweep spans seven files and seven old names, a multi-file read the plan verifier does not run; its runner is this card's Stage-6 self-verification, recorded on sub-task 8239 as a pre and post count over the seven settled files, and re-run at Stage 8] | the seven old names read zero over the seven files · pre-change count 17 lines (the sensitivity arm) |
| #7036 | AC-2a | `grep -c -F 'parser-clean PR body' release/references/pipeline/stage-06-engineering.md` expect 1 | one — the Gate-6 homonym is untouched (the probe's specificity arm) |
| #7036 | AC-2b | `grep -c -F 'Parser-clean PR body discipline' core/rules/git-workflow.md` expect 0 | zero · control: the same command at the branch base → 2 |
| #7036 | AC-3a | `grep -c -F 'check-commit-close-keywords.py' .github/workflows/commit-message-depersonalization.yml` expect 5 | five — the step calls the tool and the header and comments name it · at the branch base → 0 |
| #7036 | AC-3b | `grep -c -F 'name: Commit-message depersonalization gate' .github/workflows/commit-message-depersonalization.yml` expect 1 | one — the registered context's job name is unchanged |
| #7036 | AC-3c | [DEFERRED — an interpreter run of the tool's self-test, which the plan verifier does not run; its runner is the close-keyword step of the Commit-message depersonalization gate job on this release's PR, and this card's Stage-6 and Stage-7 local runs] | exit 0; 14 of 14 must-flag cases fire, 20 of 20 must-not-flag cases stay silent; the plumbing and degraded-read arms pass |
| #7036 | AC-3d | [DEFERRED — the register rows land in the release-wide late commit; that commit re-binds this row to a fixed-string count of the row's runner-def pointer in the gate-efficacy standard, and to a count of the phrase that binds the PR-body arm to its disposition row] | the commit-message arm's row present with its runner pointer; the PR-body arm's outcome read from its disposition row, never restated |
| #7036 | AC-4a | [DEFERRED — two replays through the tool over historical ranges, an interpreter run the plan verifier does not run; its runner is Stage 8] | exit 1 on the card's reproduction range (55 commits, 1 finding at `00cf9b2f` line 25) and on the colon-form range (1 commit, 1 finding at `438d5b38` line 18) |
| #7036 | AC-4b | [DEFERRED — the residuals are stated in the late commit's register row; that commit re-binds this row to a fixed-string count of the phrase naming the split-line residual] | the residuals stated: a pairing split across two lines, markdown link syntax, the host's merge-commit and squash messages, an administrator bypass, and the non-release heads under CR-6 |
| #7418 | AC-1a | `grep -c -F 'SUITES = [' .github/workflows/install-tests.yml` expect 0 | zero · control: the same command at the branch base → 1 |
| #7418 | AC-1b | `grep -c -F 'NAMED_STEPS = [' .github/workflows/install-tests.yml` expect 0 | zero · control: the same command at the branch base → 1 |
| #7418 | AC-1c | `grep -c -E 'test_[a-z0-9_]+\.sh' core/deploy/tests/test_install_tests_step_timeouts.py` expect 0 | zero — the suite names no suite and no step · the same pattern over the workflow reads 99 at the pin, so it matches what it must not find |
| #7418 | AC-2 | [DEFERRED — an interpreter run of the committed suite, which the plan verifier does not run; its runner is the first arm of the falsification-probe step in the shell-tests job of install-tests.yml on this release's PR, and this card's Stage-6 run] | exit 0; the last line reads the covered-of-total success line with the two numbers equal · control: the same suite on a copy of the pin's workflow exits 1 reading 6 of 37 |
| #7418 | AC-3 | [DEFERRED — the sensitivity arm runs inside the suite on every invocation, stripping each bounded suite step's timeout in turn in memory; its runner is as AC-2, and a seeded copy with one timeout line deleted, run through the suite's workflow option, is exercised at Stage 7] | every bounded live suite step is flagged when stripped; the seeded copy exits 1 and names the step |
| #7418 | AC-4 | `grep -c -F 'name: "must-not-flag:' core/deploy/tests/fixtures/step-timeouts/labeled-steps.yml` at least 5 [READER-GRADED — the same suite run's specificity control line reports every labeled near-miss left uncounted, and a seeded copy with the precision probe's timeout deleted exits 1 naming that step] | seven labeled near-misses, all left uncounted; the hard case is on the bounded side |
| #7418 | AC-5 | `grep -c -F 'Timeout guard OK — %d of %d' core/deploy/tests/test_install_tests_step_timeouts.py` at least 1 [READER-GRADED — at Stage 8, the Shell harness (macOS) job log on the release PR carries the covered-of-total success line] | at least one · the log carries the line |
| #7423 | AC-1 | [DEFERRED — re-bound by this card's Stage-6 spoke after its bounded Solutioning revision (CR-26) is consumed; graded at Stage 8] | one graduation instruction, the committed-default form |
| #7423 | AC-2 | [DEFERRED — the criterion is amended by the hub under CR-11 (the doc-link arm prints no mode-file instruction); the row is re-bound by this card's Stage-6 spoke in the same change] | as amended |
| #7423 | AC-3 | [DEFERRED — a before-and-after comparison of two full deploy-check runs, which one command cannot grade; graded at Stage 8 by a reader comparing the exit status and the finding-count line] | exit status and finding count unchanged |
| #7423 | AC-4 | [DEFERRED — scoped to the emitter's body, which a whole-file count cannot isolate; re-bound after the revision; graded at Stage 8 by reading the function] | no hardcoded per-caller fact in the emitter |
| #6179 | AC-1 | `grep -c -F 'enforcement=branch-protection:"Shell harness (macOS)"' .github/workflows/install-tests.yml` at least 1 | at least one — holds at the branch base; the criterion is recorded discharged |
| #6179 | AC-2 | [DEFERRED — a fact about live branch protection, which the plan verifier cannot read; graded at Stage 8 from a recorded live read naming the six functional contexts] | six functional contexts in the live required set |
| #6179 | AC-3 | [DEFERRED — re-bound by this card's Stage-6 spoke to the arm that asserts the failing verdict; the measuring run with a returned live read is graded at Stage 12 by read-back (CR-14)] | a measured divergence fails; a refused read yields neither verdict; one measuring run recorded on the release |
| #6179 | AC-4 | [DEFERRED — the reconciler's self-test is an interpreter run; re-bound by this card's Stage-6 spoke to one label-presence probe per arm] | each sensitivity arm fires; each specificity arm stays silent on the same non-empty input |
| #6179 | AC-5 | [DEFERRED — registration is an operator settings action after the Stage-9 GO; graded at Stage 12 from the live read-back recorded on the release; the table half is re-bound by this card's Stage-6 spoke] | every declared-required context that is not live has a recorded disposition that was carried out |
| #6179 | AC-6 | [DEFERRED — re-bound by this card's Stage-6 spoke to the disposition row of the one live, undeclared context, resolved in this release under D-A2 option B] | the context is declared and reports on every pull request, or has left the live required set |
| #6203 | AC-1 | `test -x release/tools/check-event-record-integrity.sh` | exit 0 — holds at the branch base; the criterion is recorded discharged |
| #6203 | AC-2 | [DEFERRED — re-bound by this card's Stage-6 spoke to the check's identifier in its two hosts (the deploy-time check, enforcing on day one under Q3, and the repo-integrity job)] | the check present in both hosts; the exemption list explicit |
| #6203 | AC-3 | [DEFERRED — re-bound by this card's Stage-6 spoke to a label-presence probe on the arms its tool's self-test carries] | one arm fires on a non-executable CLI; one stays silent on a sourced library |
| #6203 | AC-4 | `test -x release/tools/check-ac-binding.py -a -x release/tools/check-adr-durability.py -a -x release/tools/check-selftest-coverage.py -a -x release/tools/generate-adr-index.py` | exit 0 · control: the same command at the branch base exits 1 (all four are `100644`) |
| #7491 | AC-1 | [DEFERRED — graded as the live Phase C2 stamped-deploy row read at this release's own Stage 12 (CR-16), not at Stage 8] | the release's skill and package rows present for its slug |
| #7491 | AC-2 | [DEFERRED — re-bound by this card's Stage-6 spoke to the zero-target arm of the deploy honesty suite] | a zero-target stamped deploy writes the rules-mirror row only |
| #7491 | AC-3 | [DEFERRED — re-bound by this card's Stage-6 spoke to the refusal arm: the bare stamped form is refused before anything is written] | the flag alone cannot satisfy the criterion |
| #7491 | AC-4 | [DEFERRED — re-bound by this card's Stage-6 spoke under the design's AC-4 wording, pointed at the exact-vector arms of the hook test (review P-2)] | the hook never forwards a release key, on both invocation sites |
| #6888 | AC-1 | `test -f .github/workflows/sibling-merge-dark-branch.yml` | exit 0 · control: the same command at the branch base exits 1. Presence only; behaviour is AC-3's row |
| #6888 | AC-2 | [DEFERRED — re-bound by this card's Stage-6 spoke after the bounded revision (Q4); graded at Stage 8 on a fixture rollup] | a collapsed rollup is not read as green |
| #6888 | AC-3 | [DEFERRED — a push-triggered workflow cannot run from the PR branch; graded on a fixture at Stage 8, then observed after merge] | a darkened branch is flagged; a green one is not |
| #6888 | AC-4 | [DEFERRED — the criterion is reworded by the hub under CR-20 (the roster record is informational); the row is re-bound by this card's Stage-6 spoke in the same change] | as amended |
| #6855 | AC-1 | [DEFERRED — re-bound by this card's Stage-6 spoke to the narrowed, claim-free row (CR-23, CR-24)] | rule scope and matcher scope agree |
| #6855 | AC-2 | [DEFERRED — met by the recorded three-arm probe attached to the Stage-7 sub-task, not a committed fixture (CR-25)] | detected before the change, covered after |
| #6855 | AC-3 | `grep -c -F 'Runner: NONE' core/rules/git-workflow.md` expect 2 | two — #7036's and #6855's passages carry one runner-label token (lock 2(d)) · at the branch base → 0; after #7036 alone → 1 |

**AC baseline** (re-read at Commit 0 from the eight issue bodies; Stage 4 read 28 at `4babbba9`, Addendum 1 raised it to 34):

`ac_baseline: { #6179: 6, #6203: 4, #6855: 3, #6888: 4, #7036: 4, #7418: 5, #7423: 4, #7491: 4, read_at: 20197085 }`

Sub-criterion rows (`AC-<n><suffix>`) split one criterion into single-command rows; the criterion count is the baseline above.

### Release-Level Verification

| Check | Verification Method | Expected Result |
|---|---|---|
| Source and deployed copies agree, net of the expected mirror drift | `bash core/deploy/deploy.sh --check` | zero net-new findings against the Commit-0 baseline run on this branch; a Check 9 mirror-pair finding on `core/rules/git-workflow.md` or `core/rules/skill-deployment.md` is expected before merge and is cleared by the Stage-12 deploy |
| The three floored governance files are untouched | `git diff --name-only origin/main...HEAD -- core/governance/OPERATIONS.md operations/OPERATIONS.md release/governance/RELEASE_PROTOCOL.md` expect 0 | zero · control: the same assertion over `release/releases/plans/ci-wiring-and-required-checks_RELEASE_PLAN.md` returns at least 1 |
| The commit range is parser-clean | [DEFERRED — an interpreter run of the commit-message tool over origin/main..HEAD; its runners are the close-keyword step of the required job on every push to this release head, the pre-push arm of every Stage-6 spoke, and the hub's pre-gate read before Stage 9 and immediately before the Stage-12 merge] | zero pairings across every commit message on the branch |
| Packages match source | The live-required package-freshness gate on the release PR | green |
| Cross-issue criteria are gradable | `release/tools/verify-release-plan.sh --ciac-lint` on the committed plan | no flagged entry |

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#7036 × #6888 on `release/references/how-to/hub-spoke-bridge.md`):** After both cards land, the one how-to file both of them edit carries neither first-instance scoping: the discipline heading text that names PR bodies alone is gone, and the mergeability read is no longer scoped to Stage 9 alone. *Method:* `grep -c -E 'PR Body Parser-Clean|mergeability read \(Stage 9 ONLY\)' release/references/how-to/hub-spoke-bridge.md` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm, same instrument and same target: the identical count returned 5 at the baseline pin and 5 at the Commit-0 branch base (lines 411, 983, 1017, 1022 and 2174). The #6888 limb is provisional until its bounded revision (Q4) is consumed; if the revision leaves the Stage-9 read as it is, the hub re-binds this criterion as a Tier-1 adjustment.
- [ ] **CIAC-2 (#6179 × #6203 × #6888 × #7036 on the `gate-efficacy:` posture headers and the registration-disposition table of the gate-efficacy standard):** At the release head, every status context that a workflow header declares required and that live branch protection does not carry is a row of the registration-disposition table, and no header this release adds or edits contributes a context to that set. *Method:* declared, verification deferred to core/deploy/tools/reconcile-gate-posture.py, run at Stage 9 with a live read of the required status contexts that returned. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm, same instrument and same target at the baseline pin: the identical run reported 9 contexts declared required and not live, each of the 9 a row of that table.

Lint record — § Verification Evidence carries the Commit-0 `CIAC-LINT-SUMMARY` line. Stage 4 linted the same two entries clean (`declared=2 parsed=2 clean=1 declared-deferral=1 flagged=0`). Three cohesion constraints are carried as integration points rather than criteria (IP-1, IP-5, IP-11).

---

## Quota Budget

**Verdict:** WARN (per `quota-budget-protocol.md` Checkpoint A, recomputed for eight at Addendum 1)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 8 (ran) · Stage 7: 8 · Stage 8: 8
**Per-spoke cost estimate:** about 5% of one 5-hour window per analysis spoke (the hub's measured reference)
**Assumed/stated remaining usage-window envelope:** the approved plan's conservative assumption — half of one window for this hub's worst batch
**Estimated cumulative draw % (worst parallel batch):** 8 × 5% = 40% of a full window → 80% of the assumed envelope
**Routing:** WARN: window-aware timing + quota-budget/split — three waves at Stages 7 and 8 read PASS; Stage 6 is serial (P0)
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant per `quota-budget-protocol.md` § 4.3b. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time (§ 3.1). Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`cross-cutting`** — confirmed at Stage 4 and re-checked at Addendum 1. Trigger (a) fires on exactly three `pipeline/stage-*.md` files on unconditional evidence: `stage-07-dev-testing.md` (#6888), `stage-12-execute.md` and `stage-13-close.md` (#7036). `stage-06-engineering.md` is not counted — its one hit names the G6-03 metadata-parse criterion, a different property under the same words. `stage-08-qa-testing.md` (#6888) and #7491's and #6888's edits to `stage-12-execute.md` fall in files already counted or add a fourth. Trigger (c) holds on the derived graph (E4, E5, E9, E11 unconditional). `novel` (b) also fires; multi-trigger resolution gives `cross-cutting`.

- **Differentiation posture:** Engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day** (#6888, #7491 and #6179's check are first exercised for real after merge).
- **Size bound:** `effective_pts: raw 26 × 1.3 = 34 — over the 15–25 band; accepted by operator override at the Collective Review (CR-1), deviation logged` (DEV-2).

---

## Release Outcome Statement

The operator-approved statement, verbatim from the milestone description (CR-5 applied):

**AFTER:** Eight CI and pipeline controls reach the class they name, not the instance first seen: every invocable CLI in `release/tools/` ships executable behind a mode check; the declaration-obligation rule states the marker scope its matchers enforce; the parser-clean discipline covers commit messages as well as PR bodies; a warn emit prints the graduation form its own check sanctions; install-tests bounds every step that runs a `core/deploy/tests/` shell suite and reports covered over total; a branch darkened by a sibling merge is flagged at the merge; the release's Stage 12 deploy stamps that release's skill and package deployment-status rows, whether or not an unstamped deploy has already run; and every status context a workflow declares `required` is either live in branch protection or held under a recorded disposition that names what ends the hold, every live required context is declared, and a check fails when the declared and live sets diverge.

**BEFORE:** Six controls cover only the first-observed instance — four shebang-bearing CLIs in `release/tools/` still ship `100644`; bare-only override matchers sit under a rule that claims every marker class; a commit-body close verb auto-closed a member issue before Stage 13; one shared warn-mode emitter appends a mode-file graduation instruction that contradicts the callers documenting a committed default; the install-tests guard checks two enumerated lists naming five steps while the workflow runs 37 such suite steps, 31 of them unbounded by the recorded predicate; and nine status contexts are declared required and absent from live branch protection, five of them a bare `required` that the gate-efficacy standard says must not be written, while one live required context is declared by no header and the job built to reconcile the two sets cannot fail — and two detectors fire on the victim's activity: a sibling-darkened branch reads green until its next stage entry, and the first post-merge deploy emits zero deployment-status rows, indistinguishable from nothing to deploy.

**Not claimed:** registration of the held contexts, each waiting on its own warn-to-enforce flip; that the reconciliation check blocks a merge — it fails, which is not the same thing; and per-step timeouts for steps outside the named glob, which are bounded only by a job-level limit.

**Actor(s):** platform engineering session; the operator, for the branch-protection step. **Success Indicator:** each member's acceptance signal verified at Stage 8; one PR; and the live read-back of the required set recorded on the release.

---

## Rollback Strategy

| Scope | Action | Tier |
|---|---|---|
| Before merge, one card | `git revert` that card's commits on the branch; never rewrite pushed history | CHEAP |
| After merge, whole release | A revert of the merge commit through a fix-forward PR; the version tag is **retained and recorded**, never deleted (tag retention) | MODERATE |
| Operator-side state after a revert | (1) `./deploy.sh --deploy` re-lays the rules mirror and the `release-hub` copy; (2) **the registrations stay in place by default** — the registered jobs and their `required` declarations predate this release, so the registration stays true on the reverted tree. A context is un-registered only if it proves unable to report or reddens for a reason unrelated to its invariant, with its declaration corrected to `advisory` in the same fix | MODERATE |
| #7036 alone | Revert its commits and rebuild the `release-hub` package; reverting the workflow step alone restores the job to its one-property behaviour | CHEAP |
| #7418 alone | Revert first if any suite flaps on a slow runner — the four jobs are live required contexts | CHEAP |
| #6888 alone | Disable the workflow; it has no consumer that blocks | CHEAP |
| #7491 alone | Revert the tool and the stage text together — the stage text's zero-target command needs the tool's `--no-targets` | CHEAP |
| #6179 alone | Revert its commits; a declaration corrected from `required` to `advisory` would revert to a bare `required` on an unregistered context, so fix-forward is preferred | CHEAP |
| #6203, #6855, #7423 alone | Revert the commits; no state outside the tree | CHEAP |

Rollback infeasibility: none. The one irreversible exposure in this release is R-4, and it is prevented, not rolled back.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/rules/git-workflow.md`, `core/rules/skill-deployment.md` | the deployed rules mirror | the Stage-12 stamped deploy (the B4 form in § Delivery Strategy), which re-lays the mirror | `./deploy.sh --check` Check 9 in sync |
| 2 | `release/skills/release-hub/` (the playbook) + `packages/release-hub.skill` | the user-local skills mirror and the Cowork install | the same stamped deploy, naming `release-hub` among the targets derived from the merge and filtered by roster membership | `./deploy.sh --check` Checks 1, 2, 7, 12 and 13 green for `release-hub`; the Phase C2 row read shows a resolved `deploy-skill` row for it |
| 3 | workflows, tools, tests, specs, standards, the decision record | none (repository-resident) | merge | Stage-12 `deploy.sh --check`; the required jobs on `main` |
| 4 | live branch protection on `main` | out of tree | the operator's registration step (§ Delivery Strategy) | the read-back of the required set, recorded on the release |

**`deliverable_state: deployed-copy-synced`** for rows 1 and 2, reached at Stage 12 when they verify by content; rows 3 and 4 have no propagation target, so the source change on the branch (and, for row 4, the recorded read-back) is their end state.

### Schema Migrations

N/A — enumerated over {event-log columns, the subtype enum, payload registries, the RELEASE_LOG field grammar, the gate-coverage register's columns}; none changes shape.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **N-way override (verbatim):** "Override: convention baseline-pin accepted as diverged because Stage 6 re-derives every anchor from the branch head. Deviation logged for Stage 13 retrospective." The window `4babbba9..20197085` touches 10 matrix paths (§ Cross-PR Overlap Audit) | Collective Review scope-lock (Q1) | **RECORDED** — for the Stage 13 retrospective |
| **DEV-2** | **Band override:** `effective_pts: raw 26 × 1.3 = 34`, over the 15–25 band — an extension of the 2026-10-08 override D-A1 (#7036 S→M, #6203 XS→S) | CR-1 | **RECORDED** — for the Stage 13 retrospective |
| **DEV-3** | **D-Version re-determination `v4.74` → `v4.75`**: the sibling `telemetry-is-computable` claimed `v4.74`; the Commit-0 version half re-verified `v4.75` free and equal to next-free | the hub's recorded determination on #8239 | **APPLIED** — § Commit-0 Version Re-Verify Record |
| **DEV-4** | **`.github/workflows/commit-parser-clean.yml` — `CONDITIONAL:commit-scan-ships-as-new-workflow` — NOT DELIVERED.** Gate 1 decision D-2 option A folded the commit-message scan into the already-required `Commit-message depersonalization gate` job, so no new workflow (and no unregistered context) is added; the sibling condition `commit-scan-folded-into-required-job` fired | PA-003 (D-2 option A); #7036 design D-S5-1 | **RECORDED** |
| **DEV-5** | **The tools-inventory row the Stage-4 matrix did not carry.** `core/deploy/tools/README.md` owes one row for every new top-level tool in the same change (its coverage rule; Arm E of the self-test coverage engine). #7036, #6179 and #6203 each add or change one. Second recorded occurrence of the omission at Stage 4 | #7036 design (part 2, Blast Radius); review V8 | **APPLIED** — § File Change Matrix |
| **DEV-6** | **Matrix deltas from the refined designs, as the scope-lock accepted them:** #7036 +6 / −3 (the sanctioned session narrows to one skill surface); #7418 +2 (a committed suite and its labeled fixture); #7423 four conditional rows do not fire (provisional — a bounded revision follows); #6179 six conditional rows fire, +2 new (`core/deploy/tools/README.md`, `core/deploy/tools/lint_release_corpus.py`); #6203 12 conditional mode rows fire, 4 withdrawn, +2; #7491 +3, the hook row dropped, +1 pin consequence (the decision record's number, DEV-20), +1 sibling-reconcile path (`deployment-cycle-time.md`, DEV-21); #6888 one new tool, +3 rows (the eight-path matrix; provisional — a bounded revision follows); #6855 the six matcher rows do not fire, +1 with C-1 (`core/ADRs/README.md`) | Collective Review scope-lock; the carry-forward comments | **APPLIED** — § File Change Matrix |
| **DEV-7** | **Rows dropped without delivery (EDIT rows; recorded for traceability):** `release/skills/release-executor/SKILL.md`, `packages/release-executor.skill` and its sidecar (a scope-neutral mention, D-S5-6); `release/references/pipeline/stage-06-engineering.md`, `release/governance/release-process.md` and `release/tools/automated-closeout.sh` as #7036 restatements (a homonym and two plain mentions — `automated-closeout.sh` stays in the matrix for #6888's comment block); `core/deploy/tools/_frontmatter.py`, `core/deploy/tools/fixtures/issue-body-anchors/targets/fx-gamma.sh`, `core/deploy/tools/path-leak-patterns.sh`, `release/tools/lib/frontmatter-strip.sh` (CR-22); #7423's `core/rules/bypass-mode-readiness/_cross-cutting.md`, `core/rules/bypass-mode-readiness.md`, `core/rules/doc-link-maintenance.md`, `core/standards/doc-link-maintenance-protocol.md`; #6855's six `matchers-widened` rows; #7491's `core/hooks/git-post-merge-deploy.sh`, `update.sh`, `core/deploy/orchestrate.sh`; #6888's `stage-09-plan-review.md`, `pipeline-event-log-schema.md`, `.gitattributes`; `core/config/allowlists/script-execution-allowlist.txt` (no new shell script); `CONTRIBUTING.md` (CR-6 keeps the ratified scope) | the designs, as the scope-lock accepted them | **RECORDED** |
| **DEV-8** | **Risk R-4 reworded:** a pushed commit message is rewritable by a lease-protected push (the design's correction), and that push class is excluded on the shared release branch under multi-chip activity (review F-1 with ADR-052), so the rewrite is single-writer-only and, under P0, the operator's call. The recurrence count is the measured series, not one instance (review P-1) | #7036 design (Phase 0.5); review F-1, P-1; scope-lock record on #8239 | **APPLIED** — § Risk Register |
| **DEV-9** | **Risks R-9 and R-10 reworded** per CR-8 and CR-9 (budgets three-fold, F-3, the job-level limits with C-3's values) and per #7036's narrowed sanctioned session with CR-17 riding it | CR-8, CR-9, CR-17 | **APPLIED** — § Risk Register |
| **DEV-10** | **#7418's verification rows reworded per ADR-207 and ADR-208:** as the design posted them, one row named two commands and could never read PASS, two put a runnable command beside an undeclared reader's claim, and two named no command the verifier runs and read as SKIP. At Commit 0 each row carries one command, the reader's limbs are marked, and the interpreter runs are declared deferred to their runner. The same reading is applied to #7036's rows; #7423's rows carry it into that card's revision | #7418 review addendum (Minor); #7423 review addendum (Minor) | **APPLIED** — § Verification Plan |
| **DEV-11** | **R-5 — the stamped-deploy row takes the B4 form.** The approved plan named the bare stamped form, which #7491's change refuses; § Delivery Strategy and § Operational Deployment Manifest carry the B4 form, and the hook-bundle refresh row is removed (no card edits a hook source) | lock condition R-5; #7491 design R-5 | **APPLIED** |
| **DEV-12** | **#7036 review (#8276) Minor findings, not decided at Stage 6:** F-2 (a line-by-line verdict over hard-wrapped prose; the split shape measured 0 of 5,465 commits); F-3 (the must-not-flag arm omits the nearest real near-miss, a keyword before a parenthesised reference); C-1 (scan every pull request, block only on release heads — not taken: CR-6 keeps release heads only); C-2 (one grammar for both self-check arms). Its addendum: ADR-162's label form (the rule-file passage carries the token under lock 2(d); the how-to keeps the design's word order); ADR-119's wording point (one of the design's three reasons for Python); ADR-167 (conditional on C-1 — moot). The correction carried in the #7418 addendum: ADR-174 (Edit 6c's undated history sentence — the P-1 rewrite states the trap as what the parser does, in the present tense) and ADR-202 (the self-check result line is an observable, not a required rendering — proposed, not authored) | scope-lock: "Minor findings … go to the release plan's deviation log at Commit 0" | **RECORDED** — carried to Stage 9 |
| **DEV-13** | **#7418 review (#8278) Minor findings:** P-1 (the comparison behind three-fold measures the wrong cost); P-2 (`AL-LOW`, advisory — the invariant's reach is one workflow file); F-2 (a re-derivation trigger with no reader); F-3 (folded, CR-8); C-2 (folded); C-3 (taken, CR-9). Its addendum: ADR-207/208 (applied, DEV-10); ADR-119 (cited, per the record) | scope-lock record on #8243 | **RECORDED** — P-1, P-2 and F-2 carried to Stage 9 |
| **DEV-14** | **#7423 review (#8279) Minor findings:** P-2 (moot under D-6 option (b), CR-11); F-2 (the shared suite pins two callers' wording — open); F-3 and F-4 (folded); C-2 (taken, CR-26). Its addendum's verification-row reading — into the revision | scope-lock record on #8247 | **RECORDED** — F-2 carried to the revision and Stage 9 |
| **DEV-15** | **#6179 review (#8281) Minor findings:** P-2, F-1, F-2, F-3, F-4 and C-3 (folded); C-2 (take the registrations before the card lands — not taken, CR-14) | scope-lock record on #8251 | **RECORDED** |
| **DEV-16** | **#6203 review (#8287) Minor findings:** P-2, F-2, F-3, F-4, F-5 and C-2 (folded); P-3 (the oversize predicate — size S recorded as kept-as-one, CR-1); C-1 (conditional on warn-first — moot under Q3); C-3 (pin the deployed copy's mode — recorded, not recommended) | scope-lock record on #8255 | **RECORDED** |
| **DEV-17** | **Edge E10 — the disposition token at Commit 0.** The `Close-keyword leak detection` row of the registration-disposition table reads **REGISTER** at the branch base (`core/standards/gate-efficacy-standard.md:382`); #6179's locked design corrects the context to advisory and holds it (CR-13), recording `CORRECT-THEN-HOLD`. #7036's register row binds to that row by reference, so the token is re-read when the late register commit lands | #7036 design D-S5-7; CR-13 | **RECORDED** |
| **DEV-18** | **#7491 review (#8282) Minor findings:** P-1 (folded, CR-16); C-2 (taken, CR-15); F-3 (taken as CR-17, in #7036's sanctioned session); P-3 (one consumer mislabels a mirror-only row set as a failed deploy) and F-4 (one variable missing from the test's safety layer) — not named by the lock; four cosmetic items recorded with the review | scope-lock record on #8259 | **RECORDED** — P-3 and F-4 carried to Stage 9 |
| **DEV-19** | **#6888 review (#8285) Minor findings:** P-4, P-5, F-4, F-5 and C-3 (folded); C-4 (a head-side sentinel — not taken, CR-18) | scope-lock record on #8263 | **RECORDED** |
| **DEV-20** | **#7491's decision-record number.** Bound at Commit 0 against the mainline anchor as the design specifies: `python3 release/tools/renumber-adr.py --detect` reads ANCHOR 216 on `origin/main`, NEXT-FREE 217, and 217 and 218 claimed branch-only by #7919 (detection only, never binds). The matrix row keeps the `ADR-NNN` placeholder form; whichever release merges second renumbers | #7491 design Change 7 | **RECORDED** |
| **DEV-21** | **The sibling-merged-first reconcile.** `telemetry-is-computable` merged first (`ff3eecdf`), so this release reconciles one sentence of `release/references/standards/deployment-cycle-time.md` § 4 and refreshes the two embedded data-flow artifacts that sibling authored in that file (§ 2 and § 3.1; no separate artifact file was added — the sibling's merged diff adds 8 files, none an artifact) | #7491 scope-lock record (fold-in); carry-forward 6084324580 | **APPLIED** — § File Change Matrix |
| **DEV-22** | **#6855 review (#8289) Minor findings:** P-2, F-2 and F-4 (folded); F-5 (folded through CR-25's reworded opening); C-2 (the rejected direction at full strength — recorded for the follow-on card, CR-3) | scope-lock record on #8267 | **RECORDED** |
| **DEV-23** | **Lock condition 2(d) — the token.** "One runner-label token" reads as one token form in both passages: `**Runner: NONE — a registered named gap.**`, the form #6855's design grounded. #6855's third criterion's count therefore reads 2 once both passages land, as its scope-lock record states | lock condition 2(d); #6855 design (Evidence-Grounding) | **APPLIED** — § Verification Plan (#6855 AC-3) |

---

## Documentation Impact

| Issue | Declared docs (the body's Documentation Impact field) | Status at Commit 0 | Lands in |
|---|---|---|---|
| #7036 | the discipline's name and scope — `core/rules/git-workflow.md`, `release/references/how-to/hub-spoke-bridge.md` and the downstream restatements | pending | card 1 |
| #7418 | None — no documentation impact (rationale: CI-internal guard and step timeouts; no K1 document describes them) | NONE | — |
| #7423 | the graduation-form statement — home settled by the bounded revision (the generated rule fragment's rows do not fire; `core/standards/gate-efficacy-standard.md` § Flip-decision status) | pending (provisional) | card 3 or the late commit |
| #6179 | `core/standards/gate-efficacy-standard.md` — the vocabulary's falsifiability against branch protection and the registration-disposition table | pending | the late commit |
| #6203 | None expected | NONE | — |
| #7491 | `release/references/pipeline/stage-12-execute.md` Phase B4 and C2; `core/rules/skill-deployment.md` | pending | card 6 |
| #6888 | the stage references name who reads a darkened branch and what it blocks | pending (provisional) | card 7 |
| #6855 | `core/rules/git-workflow.md` § Repository-Integrity Gates — the declaration-obligation row | pending | card 8 |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification, extended at Stages 7, 8 and 12.*

| Check | Result |
|---|---|
| **Commit-0 version half** | Both fetches exit 0; the adapter's dry-run recomputes **`v4.75`** for bump-class `minor` at `20197085`; the slot is free on the tag, Release and ledger arms (probe record above). **No HALT** |
| **Commit-0 manifest half** | Recorded in the Commit-0 interim output on #8239 (run after this file was written and before it was committed) |
| **CIAC lint** | Recorded in the Commit-0 interim output on #8239 |
| **Baseline pin** | `4babbba9..20197085`: 61 commits, 39 files, 10 matrix paths (probe record in § Cross-PR Overlap Audit) |
| **In-flight roster** | 1 sibling, `minor`, recomputing `v4.75`; EDITSET ∩ FCM = 12 paths |
| **R-10 pre-flight** | PROCEED — § Commit-0 Version Re-Verify Record → pre-flight |

---

## Change Description

*Authored at Stage 6 Phase C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, started by card 1 and extended by each later card, before the Stage-9 draft→ready transition. Not authored at Commit 0: no card has landed, so there is no outcome to describe yet.*

---

## Issue References

The eight content members of this milestone are transitioned to closed at Stage 13 by the close-out on the merged PR, not by an auto-close keyword in the PR body or a commit message.

- References **#7036** — the parser-clean discipline named PR bodies only; this release names all three parser inputs and enforces the commit-message arm on release heads.
- References **#7418** — the install-tests timeout guard enumerated four suites; this release derives the population and bounds every suite step.
- References **#7423** — the shared warn emitter printed a graduation form its own checks forbid; this release lets each caller's form through a closed token.
- References **#6179** — declared-required contexts and live branch protection disagreed; this release reconciles the class and registers four contexts at Stage 12.
- References **#6203** — one CLI shipped non-executable; this release checks the whole tool-mode class at deploy time and pre-merge.
- References **#7491** — the first deploy after a release merge was unstamped; this release makes the Stage-12 deploy stamp its targets.
- References **#6888** — a sibling merge could darken a branch unseen; this release flags it at the event.
- References **#6855** — the declaration-obligation rule claimed every marker class; this release narrows it to the one its matchers enforce.
- **#8160, #8238–#8289 and #8239–#8274** — the Stage-4, Stage-5 (designs and reviews), Stage-6 and release-scoped hub sub-tasks carrying the plan source, the designs, their reviews, the decision records and the scope-lock records.
- **#7919** — the open sibling release `controls-fail-loud`, co-contender for the version slot and owner of CR-4's merge-order note.
- **#8092, #8048, #7670, #7490, #6852, #6356, #5287, #8143, #7026, #8237** — the coordination cards named in § Scope → Exclusions.
