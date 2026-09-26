---
title: Release Plan — telemetry-is-computable (every event-log telemetry value is computed or an explicit N/A that names its reason)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.70; the concrete number binds at the Stage-12 atomic claim)
milestone: telemetry-is-computable
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH — every slice reverts CHEAP (read-models, two writer-gate arms, one cutover value, a close-out read path, stage and standard text) and `git revert -m 1` of the merge restores `main`; the qualifications are in § Rollback Strategy — rows written under the new tools stay in the append-only event log, the armed `(l)` gate owes the Close-Class-Telemetry field from merge, and a claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `telemetry-is-computable`

**Milestone:** `telemetry-is-computable` (ms#341). Stage-4 planning sub-task **#7681** carries the approved three-part plan and every decision record this file transcribes (D-Version, the Stage-4 plan gate, the Collective Review scope-lock, the re-classification to `cross-cutting` and the D-Version re-render to `v4.70`). The Stage-5 designs are on **#7731–#7737**, their Phase A6.5 adversarial reviews on **#7871–#7875, #7885 and #7886**, and #4219's delta design is on **#7896** (open, not rendered at Commit 0). The Stage-6 Engineering sub-tasks are **#7738–#7744**; this file is Engineering Commit 0, authored by #7738's spoke.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.70`**. Recorded as a determination at the Stage-4 gate, where the allocation rule computed `v4.69`; `egress-hook-batch` then claimed `v4.69`, and the operator re-rendered D-Version to `v4.70` at Engineering entry. The concrete version binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the release-version stamp placeholder. Both halves of the Commit-0 re-verify ran — § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one branch `release/telemetry-is-computable`, one pull request opened in **draft** at Commit 0, one merge into `main`. **Concurrency posture:** **P0 fully serial** — seven slices in § Implementation Sequence order, one commit per slice, pushed as it lands; no force-push under any posture.

**Release class:** `cross-cutting` — re-classified from `novel` at the Collective Review scope-lock; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #7681 (three parts) and every decision record on #7681, plus the D-Retro-Owner record imported onto #7731. The File Change Matrix, Contention Map, Cross-Issue Acceptance Criteria, Verification Plan, Evidence Grounding, Tier-A declarations, Stage 9 Disclosures and Deviation Log carry the scope-lock's amendments, drawn from the seven Stage-5 designs, their Phase A6.5 reviews and the rendered blocks of the seven Stage-6 sub-tasks. **Where a design and a decision record differ, the decision record wins; each such ambiguity is recorded in § Deviation Log.** Every thread comment consumed is `OWNER`-authored (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version: protocol text plus tool fixes; no new skill or governance file). Provisional display v4.70 (re-rendered from v4.69 at Engineering entry); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-09-25 (Friday) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) and slices 1 (#5586) and 2 (#7432) landed; slices 3–7 pending |
| **Branch** | `release/telemetry-is-computable` |
| **PR** | #7901 — draft, opened at Engineering Commit 0 (SINGLE topology); it transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `telemetry-is-computable` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-24, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every row targets an internal platform artifact, and the File Change Matrix is dominated by `release/tools/*` read-models and writers and `core/deploy/deploy.sh`, with governance and standards text secondary. Transcribed unchanged from the Stage-4 D-ReleaseClass block (Phase A1.5) and carried unchanged by every Stage-5 design (§ 5.7).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1–3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `35dbf418` (`35dbf41847df2c1deab792d2944e46ac6ddd26fd`, the merge of the `v4.69` Stage-13 chore). The branch was created from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 35dbf41847df2c1deab792d2944e46ac6ddd26fd --bump minor --dry-run` (the adapter's own `anchor()` and `claimed_set()`; no tag pushed) | **`v4.70`** (exit 0; "would claim v4.70 (no tag pushed)") — equal to the planned version |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin                                  (tag arm — binds)
             gh api repos/<owner>/<repo>/releases --paginate --jq '.[].tag_name'   (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md           (ledger arm)
             each filtered for the v4.70 slot
Denominator: 426 ls-remote lines; 212 published Releases (paginated, so not truncated);
             the ledger at origin/main, 2618 lines
Control - sensitivity: the same three readers on the v4.69 slot — tag v4.69 (peeled 40cec0c7),
             Release v4.69, and the v4.69 ledger row (egress-hook-batch, VERIFIED) at line 249.
             Every arm resolves and returns non-zero, so a zero on the v4.70 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple has
             no near-miss class the probe must reject
Extraction:  the full ls-remote output, the full Release list and the full ledger read from
             origin/main (never the worktree copy)
Result:      0 occupants of the (4,70) slot on every arm
Verdict:     CLEAN — v4.70 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** two sibling release branches with draft pull requests, both bump-class `minor` and both recomputing `v4.70` (§ Cross-PR Overlap Audit → In-Flight Release Roster). Merge order arbitrates the slot at the Stage-12 compare-and-swap; no sibling has claimed, so this is an enumeration, not a collision.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp telemetry-is-computable`, run after this file was written and before it was committed; required exit 0. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal release-version stamp placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1..5`; CIAC-6 void) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (with the scope-lock amendments and the seven-card AC baseline) | § Verification Plan |
| 5 | Release-version stamp manifest (the placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA) | § Cross-PR Overlap Audit → Baseline SHA |

### Commit-0 pre-flight (risk R7 — the sanctioned-session path)

#7738's body asks for this before slice 1: confirm that the `pmo-skill-editor` Mode A sanctioned session is invocable and that the Check 10 editor-trailer convention will be met. Run read-only at Commit 0:

- `release/skills/pmo-skill-editor/SKILL.md` carries `## Mode A — Edit` (`:100`) and the editor-audit-trail trailer rule (`:509`); the deployed user-local copy of the skill is present, so the session is invocable.
- `release/skills/release-hub/SKILL.md` carries `skill_discipline_migrated_v10_2: true` (`version: v4.46`), so the skill gate binds both playbook edits (slices 6 and 7) to the sanctioned session.
- `core/deploy/deploy.sh` Check 10 (`:8545-8583`) reads only the last non-merge commit touching a migrated skill's **`SKILL.md`**, so a playbook-only edit leaves it unarmed for `release-hub`. If a session bumps `release-hub`'s `version:` (#5467's design, F13), its Mode A commit carries the `Skill-Editor-Audit-Trail:` trailer and that slice adds the `SKILL.md` row to the matrix (DEV-15).
- **Verdict: PROCEED.** R7's early warning is discharged at Commit 0 with no edit.

---

## Scope

### Issues Included

Seven content members — the capability slice kept at the Stage-4 gate (D-Scope B). 22 raw points; 0 in-release build edges; 2 in-release release gates (#6252 on #5553 and on #5467, satisfied by the single merge); 9 relational edges against the N−1 = 6 cohesion floor.

| # | Issue | Title | Priority | Size | Labels |
|---|---|---|---|---|---|
| 1 | #5586 | Close-class telemetry: three indicators read N/A on every release because the close-out caller never passes --retro | P2 | M | improvement · cluster: process-protocol · project:pipeline · type:task |
| 2 | #7432 | check-event-record-integrity C4 joins action items on the bare AI id, so a stale row passes whenever another release shares it | P2 | M | bug |
| 3 | #4219 | compute-front-cluster-telemetry I6 filter is subtype-blind and inflates plan-survival | P3 | S (re-assessed by the delta design) | bug · cluster: eval-quality · project:pipeline · type:bug |
| 4 | #5245 | Arm the Check 48 Close-Class-Telemetry sub-check from a known-good row (ships inert as __none__) | P3 | S | improvement · cluster: eval-quality · project:pipeline |
| 5 | #5553 | A package-only deploy is dropped from T_DEPLOY and reported as targets did not succeed | P3 | S | bug · project:platform-quality · type:bug |
| 6 | #5467 | compute-cycle-time anchors T_GO on any plan-review-go row, so a Stage-7 hub row inflates Cycle-Time 2.71x undetected | P3 | M | bug · project:platform-quality · type:bug |
| 7 | #6252 | T_GO emission is not bound at the stage that renders it, and close-out discards the missing-anchor reason | P3 | M | bug · project:platform-quality |

**Acceptance criteria.** Each criterion's single home is its issue body; § Verification Plan binds each by ordinal and never restates it. The bodies stay historical: the scope-lock's amendments to #5586's, #5467's and #6252's criteria are carried in the bound verification rows.

### Exclusions

- **Left the milestone at the Stage-4 gate** (D-Scope B, dispositioned as amend with the 30% churn-threshold override): #4228, #4741, #4742 and #5193 — to the approved queue under epic #6618, named for the next Stage-3 cycle as the slice "a declared verification can actually fail". Every Stage-4 row for them is recorded NOT DELIVERED (DEV-9).
- **Sibling card:** #7730 binds Stage 7–8 verdict emission (D-6252-Scope a).
- **Cross-release couplings (coordination, not relocation):** #5586 ↔ #6892 (closeout-verification-rows-consistent, ms#395; hold K); #7432 is a release gate for #6205 (ledger-and-log-agree, ms#418).
- **Explicit non-scope:** historical release records (every past Cycle-Time and Close-Class-Telemetry field, every past plan and note) are never rewritten; the operator-instance pipeline event log is append-only and gains no backfilled row; Check 61 (`release/tools/check-emission-contract-subset.sh` and its asserted set) is reused, not extended.

---

## Decision Record

### Stage-4 plan gate (operator, 2026-09-24)

| ID | Decision | Operator choice |
|---|---|---|
| D-Scope | Over-band bundle (38 raw / 44 effective against 15–25) | **Split by sub-capability (B)**, dispositioned as amend with the 30% churn-threshold override recorded; the four eval-quality cards leave via `[BUNDLE DEFER]` |
| D-ReleaseClass | Release Class | `novel` (trigger b) — superseded by the scope-lock re-classification below |
| D-6252-Scope | #6252's scope | **Narrow #6252** and open a sibling card for Stage 7–8 verdict-emission binding (#7730) |
| Plan approval | Stage-4 plan + Release Outcome Statement | **Approve as briefed**; the Outcome published as the milestone's verbatim H3 |
| D-C (standing directive) | Branch topology | SINGLE — one branch, one PR, one merge |
| D-Concurrency (standing) | Stage-6 posture | P0 — fully serial |
| D-Coordination (standing) | #5586 ↔ #6892 and the file contention with ms#395 / ms#334 | Keep both cards in place; merge the releases adjacently, the later one re-baselining `automated-closeout.sh` |

### D-Version (recorded determination) and its re-render

- **At the Stage-4 gate:** versioned · bump-class `minor` · provisional `v4.69` (`anchor()` = `v4.68`; the claimed set held no `v4.69`). CHEAP / HIGH.
- **Re-rendered at Engineering entry (operator, 2026-09-25):** `egress-hook-batch` claimed `v4.69` (its tag and its ledger row are on `main`), so this release plans at **`v4.70`**, the allocation rule's next-free value for a minor bump. The plan keeps its stamp placeholder and the Stage-12 atomic claim decides the final number; `closeout-verification-rows-consistent` displays a provisional `v4.70` too, and whichever release claims first takes it. CHEAP.

### D-Retro-Owner — hold K (imported onto #7731)

The operator's decision on #7682 (ms#395): **#6892 owns** the Stage 13 § A7.2 register-producer move, the phase-6.8 `--retro` wiring and the declared precondition; **#5586 narrows to its part 2** — the reader side: `compute-close-class-telemetry.sh`, the phase-6.8 disposition block (not `_cct_args`), `close-class-telemetry.md`, the regression suite and the smoke workflow. The disposition of #5586's AC-1, AC-2 and AC-4 was carried to the scope-lock.

### Collective Review scope-lock (operator, 2026-09-25)

**Verdict:** approved with adjustments. Scope locked through Stage 9. #4219 re-opened for a delta design before its Stage 6 slice.

| # | Rendered decision |
|---|---|
| 1 | **#5586:** Design A. Change 3 item 5 dropped (`close-class-telemetry.md:90` belongs to #6892 under ms#395's Plan amendment 1). Arm (d2) verdict-agnostic. AC-1 removed (delivered by #6892 under hold K); AC-2 graded on a register-present fixture as a non-regression criterion; AC-4 reworded to reach the live call sites. Review FM-1/CD-1, FM-3 and FM-5 adopted |
| 2 | **#6252 D6252-surface = S-B**, with the review's riders: DIVERGENT worded as a disagreement carrying the tool's `--iso` anchors (PR-1), the invocation key pinned (FM-3), only the class and exit code of a NOT-EVALUATED result in the public chore-PR body (FM-4). CIAC-2's predicate reworded (Tier 1 [ADJUST]) |
| 3 | **`compute-cycle-time.sh`'s exit-1 contract:** the query tool's exit status is checked at `:330` (#5553's slice) and `:313` (#5467's slice), with an arm on an empty evals directory. #6252 adds INT-4 and CY-13 and inverts CY-6, so a negative delta renders as a non-value. `t_go_na_reason` is factored with CG arms |
| 4 | **#7432 D7432-keyform (A):** the close gate states that `<release>:<AI-id>` limb-(c) keys are reported, not blocking, until ms#410's parser lands — one sentence in #6252's sanctioned playbook session. CD-2 routed to #6872 |
| 5 | **The Tier-A data-flow trigger:** a modified schema or output-format file with cross-component flow activates it. #4219 declares its marker at Commit 0; #5586, #7432 and #5553 re-check theirs then (§ Tier-A Activated Design Artifacts) |
| 6 | **#5553 D5553-admit (B)**, with the review's CD-1 reason form (rule plus producer) before Stage 6. #5553 owns `deployment-cycle-time.md` § 4.1. Review PR-2 and PR-3 land at Commit 0 (slice 5's change specification below), with the CR-9 DORA parity arm. Finding 5 relayed to #5467's Stage 6; CD-2 routed with F6 |
| 7 | **#5467:** D5467-identity (B), D5467-history and D5467-help (b). Review PR-1's restatement (21 computing / 4 changing / 17 unchanged / 4 new-reason N/A), with `release-bundle-and-sequence-gates` added to AC-1. FM-1: a destination for every refused class, and F8 adopted now. FM-2's provenance-first wording. Item 4b points at `hub-session-continuity.md` § 3.2; the Stage 7/8 rows routed to #7730 |
| 8 | **#5245 D5245-anchor = `v4.55`**, frozen at the scope-lock (review CD-1; CIAC-4 reads as 0 unnamed `(l)` findings). The Tier 2 [SCOPE CHANGE] adding `automated-closeout.sh` Test 15 accepted (Changes 1 and 2 in one commit), with FM-1's three wording fixes, OS-17b in this slice and the anchor sweep in the Deviation Log |
| 9 | **#7432 D7432-legacy (A)** with CD-1 (limb (c) keyed on every AI row), FM-3 and FM-4; DC-4 kept. **#4219's validator** enforced from day one. **#6252 D6252-bind (B1)** with FM-2's precedence sentence and a typed read-back; AC-3 reports three rates; AC-4 re-graded on the live counterexample; Phase C1 exercised at this release's own Stage 9 |
| 10 | **The milestone goal:** the AFTER statement is kept, and #4219 adds the I11/I15 stage terms in-slice (Tier 2 [SCOPE CHANGE]). The remaining residuals go to Stage 9 as explicit disclosures (§ Stage 9 Disclosures) |
| 11 | **N9 (I6's population):** I6 and its durable text are relabelled to cards carrying a per-issue Stage-4 gate decision, and the grain is fixed at its source in #4219's slice — the Stage-4 gate emits a per-issue `d-class` row (issue subject) for each carried card (`stage-04-planning.md` § 11), with FM-1's removal-disposition clause (Tier 2 [SCOPE CHANGE]) |
| 12 | **#6252 D6252-s12 (C-S) and D6252-remedy (C-R), both in full.** With `stage-04-planning.md` (#4219), four `pipeline/stage-*.md` files are in the write set, so the release is re-classified `novel` → `cross-cutting` |
| 13 | **Cross-milestone relays:** all seven posted — to #6892, the R3 wording to ms#395 and ms#334, #6872, #6205, #4318, #7730 and #6871 |

**N-way consistency — every disagreement row cleared or overridden:** N1 by decision 4 · **N2 overridden** (DEV-1) · N3 by decisions 2 and 12 · N4 by decision 2 · N5 and N6 by decision 1 · N7 by decision 5 · N8 by decision 3 · N9 by decision 11.

**Overrides and bookkeeping:** evidence grounding — the identifier-naming BLOCKs in all seven designs are overridden, with grounding entries required at Commit 0 (§ Evidence Grounding; DEV-3); band — under `cross-cutting` the effective points exceed 15–25, accepted by operator override (DEV-2); upstream compatibility — no conflicts, and each D-decision rendered reads "N/A — does not modify a skill-authoring surface"; Contention Map — ms#334 #6871's edit of `automated-closeout.sh:1753`, inside `phase_read_state` directly above #6252's region, is added (§ Contention Map); Minor review findings go to the Deviation Log, one row per review, and the routed items are filed through intake at Stage 13 (DEV-6, DEV-7, DEV-8, DEV-11 and DEV-12a..DEV-12c).

**The delta design for #4219** (Stage 5 re-opened for one card, sub-task #7896): the I11/I15 stage terms (review CD-2(a)), the I6 relabel (CD-1), and the Stage-4 per-issue emission with FM-1's removal clause (`stage-04-planning.md` § 11). The delta design and its Phase A6.5 review run before slice 3; slices 1 and 2 proceed meanwhile. The delta re-assesses #4219's size, and the band recompute is refreshed with it.

### Re-classification (operator, 2026-09-25)

`[RECLASSIFY novel → cross-cutting]` — the File Change Matrix declares changes to four `pipeline/stage-*.md` files: `stage-04-planning.md` (#4219's per-issue Stage-4 emission), `stage-09-plan-review.md` (#6252's Phase C1), `stage-12-execute.md` (#6252's C-S) and `stage-13-close.md` (#6252's C-R). That fires `cross-cutting` trigger (a), which outranks `novel`'s trigger (b). `effective_pts: raw 22 × 1.3 = 29` — over the band, accepted by operator override (DEV-2).

### Stage-5 decisions — the rendered set

| ID | Rendered |
|---|---|
| D5586-owner | Design A (Register-B split; no convention fallback; detector keyed on frozen vocabulary); the caller wiring is #6892's (hold K) |
| D7432-legacy · D7432-keyform | (A) literal-key join graded by the one § 4.1 cutover, with the indeterminate-key note · (A) `<release>:<AI-id>` |
| D4219-filter · D4219-writer · D4219-posture | (B) the `d-class` allow-list · `validate_row_identity`, one `case` arm per governed pair · enforce from day one |
| D5245-anchor · D5245-fixtures | `v4.55`, frozen · (a) the Test 15 fixtures carry all three members |
| D5553-admit · D5553-reason | (B) admit nothing new; name every excluded subtype · a pure `t_deploy_na_reason` over an explicit partition, rendered in the rule-plus-producer form |
| D5467-identity · D5467-history · D5467-help | (B) full-identity selection plus a writer arm · the 48 non-identity rows accepted as historical in a schema convention block · (b) the self-terminating `--help` renderer |
| D6252-bind · D6252-surface · D6252-s12 · D6252-remedy | (B1) Phase C1 in stage-09 · S-B with the riders · C-S adopted · C-R adopted |

---

## Dependency Graph

**Build-dependency edges inside the bundle: 0.** Declared edges, native `blocked-by` edges and the Stage-4 reads agree (the Stage-4 dependency graph on #7681, part 2).

**Release-gate couplings** (gated on, not blocked by; satisfied by the single merge):

| Gated card | Gated on | Why shipping first would do harm |
|---|---|---|
| #6252 | #5553 | #6252 surfaces the tool's N/A reason; before #5553 that reason is the false "targets did not succeed" on 9 of 33 deploying releases, written into an append-only record |
| #6252 | #5467 | Same channel: before #5467 a surfaced T_GO reason carries the actor-blind MIN |

**Edges crossing milestones:** #7432 → #6205 (ms#418; native `blocks`, a release gate for #6205's AC) · #5586 ↔ #6892 (ms#395; coordination — "keep separate, ship together"). The full cross-milestone map is the milestone description's Parallelization Map, not restated here.

#### Topologically Sorted Sequence

Stage-4 Kahn order (`tie_breaker_key` = priority rank, then issue number), restricted to the seven kept cards; positions are the Stage-4 eleven-card positions. The gate's Tier-1 edits have since set P3 on the four cards that read "unset"; the relative order is unchanged.

| Position | Issue | Priority (at Stage 4) | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 3 | #5586 | P2 | bundled | (none — root) | — |
| 4 | #7432 | P2 | bundled | (none — root) | — |
| 5 | #4219 | P3 | bundled | (none — root) | — |
| 8 | #5245 | unset | bundled | (none — root) | — |
| 9 | #5467 | unset | bundled | (none — root) | — |
| 10 | #5553 | unset | bundled | (none — root) | — |
| 11 | #6252 | unset | bundled | (none — root) | — |

**Critical path:** none — the bundle has no dependency edges (chain length 0). **Leverage:** #7432 has one transitive dependent outside the bundle (#6205).

---

## Implementation Sequence

**Topology:** D-C SINGLE, one branch, P0 fully serial. The order follows doctrine § 9 layers (foundation → infrastructure → skill-core/protocol), then `tie_breaker_key`, with one contention override on `compute-cycle-time.sh`: #5553 before #5467, the smaller change first, per the owner's RCA correction on #5553. Every acceptance-criterion arm is observed RED before its fix, then GREEN.

| # | Slice | Stage-6 sub-task | Layer | Execution path | Why here |
|---|---|---|---|---|---|
| **0** | Engineering Commit 0 — this file | #7738 | — | ordinary Engineering spoke | The plan, with the Commit-0 re-verify (steps 1–3, then 3b) and the R7 pre-flight |
| **1** | #5586 | #7738 | infrastructure | ordinary Engineering spoke | P2. Moves the field's value domain before #5245 measures the arming set |
| **2** | #7432 | #7739 | infrastructure | ordinary Engineering spoke | P2. Highest external leverage (the release gate for #6205) |
| **3** | #4219 | #7740 | infrastructure | ordinary Engineering spoke | P3. First writer edit; builds the design on #7733 plus the rendered delta on #7896 |
| **4** | #5245 | #7741 | infrastructure | ordinary Engineering spoke | Arms `(l)` after #5586's value domain is known |
| **5** | #5553 | #7742 | infrastructure | ordinary Engineering spoke | The smaller change on the contended `compute-cycle-time.sh` goes first; lands the shared `--help` renderer |
| **6** | #5467 | #7743 | infrastructure | ordinary spoke for the tool, schema, standard and writer rows; **sanctioned session** (`pmo-skill-editor` Mode A) for the playbook, with the package rebuild inside it | T_GO identity on the same script |
| **7** | #6252 | #7744 | skill-core/protocol | ordinary spoke for stage-09, the close-out, the standard, C-S and C-R; its **own sanctioned session**, after #5467's, for the playbook and the package | Synthesis: surfaces the #5553 and #5467 diagnostics; lands last |

**Change specifications.** Each is the Stage-4 change specification of the card as its Stage-5 design refines it and the scope-lock amends it; the design comment is the spec anchor each slice reads directly. Line anchors are `8e0ee084` positions; every matrix path is unchanged at the branch base `35dbf418` (§ Cross-PR Overlap Audit), and each slice re-anchors by content after the slices before it.

- **Slice 1 — #5586** · M · design on #7731 (comment 5827212907), amended by scope-lock decision 1 under hold K.
  - **Reader side only.** The caller wiring at `automated-closeout.sh` `_cct_args` (`:3141`), the § A7.2 register-producer move and the phase-6.8 precondition WARN are #6892's; this slice does not edit `_cct_args`.
  - `release/tools/compute-close-class-telemetry.sh`: register-slot resolution for the three register-fed slots (I1 `:1006`, I2 `:1021`, I5 `:1086`), split into a path-state function holding the only `-f` test and a pure slot renderer, with Indicator 5 rendering from the retro resolution instead of re-testing the path (review #7871 FM-3). A caller that supplied no path renders the Register B `NOT-EVALUATED — … — this is not a clean result` state (PV-7); a supplied path holding no register keeps its bytes (`N/A — no retro register found`). The unimplemented convention-fallback promise at `:76-78` is corrected, not implemented, with the header's line count unchanged (so `usage()`'s `4,145p` range and the external `:218` citation stay valid). No exit code is added. Test 9 and the `--json` state fields per the design.
  - `release/tools/automated-closeout.sh`: the phase-6.8 disposition (`:3196-3206`) gains a detector keyed on the frozen vocabulary `retro-conformance NOT-EVALUATED`, evaluated on every grammar-conformant line outside the vacuity branch as a non-fatal note (review #7871 FM-1 / CD-1); the `:3198` wording; Test 4c.6 gains the omission stub and arms, with arm (d2) **verdict-agnostic** — it asserts the omission disposition text only — and a measured-line arm; the `:15682` self-test summary.
  - `release/references/standards/close-class-telemetry.md`: the value-domain edits — § 2; § 3.2's two emit examples (the design's Change 3 items 3 and 4); § 4 Indicators 1, 2 and 5; § 5 rows 1, 2 and 5 and the explicit-N/A clause (item 12, which reads "an unmeasured indicator" — review #7871 FM-5); the calibration clauses; § 7's CLI and exit-code bullets; v1.02 → v1.03 with its Version History row. **The line-90 emit-sentence rewrite (Change 3 item 5) is dropped — it is #6892's.**
  - `release/tools/tests/test_close_class_telemetry.sh`: GROUP E — arm presence (E1), the mutation-extraction control (E2a), the RO/RA sensitivity arm (E2b) — plus a structural binding arm that counts each live call site exactly once, with its `mutate()` control (review #7871 FM-4, carried by AC-4's wording).
  - `.github/workflows/release-tooling-smoke.yml`: the suite's arm count made count-free at `:45` and `:590`; the stale group list at `:609-611` replaced by a pointer to the suite header.
  - The Tier-A data-flow artifact declared in § Tier-A Activated Design Artifacts.
  - **Cross-release:** phase 6.8 is shared with #6892; whichever release merges second re-baselines it.
- **Slice 2 — #7432** · M · design on #7732 (comment 5827313304), amended by scope-lock decisions 4 and 9.
  - `release/tools/check-event-record-integrity.sh`: C4 joins on (release, id) in the index, all three limbs and the denominator. One helper derives the release key — a log row's `version` column verbatim (schema § 2a rung 1); a ledger's hub-state directory name — for the C5 key, the C4 key and the join. A version-form (legacy) key joins only under its literal value and is graded by the single § 4.1 `integrity_cutover` (D7432-legacy A); it is never re-keyed through § 2a rung 3. Limb (c) is keyed `<release>:<AI-id>` (D7432-keyform A) and dated by its own rows; its ledger-key set is built from every AI row the ledger carries, not only the C5-well-formed ones (review #7872 CD-1); a separate limb-(c) denominator line (FM-3); a straddling arm pins the dating rule (FM-4); DC-4's report-only indeterminate-key note is kept.
  - Seven ADD fixtures (the collision and collision-control logs and trees) and four prose-only fixture edits (no table row touched; C3's SHA1 join reads rows only).
  - The schema is **not** edited — the § 2a / § 4.1 rule is reused, which takes #7432 out of the schema's contention.
  - The close-gate sentence (`<release>:<AI-id>` limb-(c) keys reported, not blocking, until #6872's parser lands) lands in #6252's playbook session (slice 7), not here.
- **Slice 3 — #4219** · S (re-assessed by the delta design) · design on #7733 (comment 5827745512) plus the delta design on #7896, which renders before this slice.
  - `release/tools/compute-front-cluster-telemetry.sh`: I6 selects the plan-class subtype `d-class` (an allow-list, D4219-filter B), excluding `milestone:*`; self-test arms P1–P3 (P3, a non-plan sibling subtype, pins the allow-list); one summary line.
  - `release/tools/append-pipeline-event.sh`: `validate_row_identity` — one `case` arm per governed (event type, event subtype) pair; a stage-4 `decision`/`delegation` row must carry `milestone:#N` — called after the enum checks and enforced from day one (exit 1, no row written); the self-test's reject, accept and wiring arms.
  - `release/references/standards/pipeline-event-log-schema.md` § 3: the delegation MUST paragraph — rule kept, rationale rewritten, an `Enforcement:` line citing the validator; no pipe character, no table row, no column-3 token.
  - `release/references/standards/phase-telemetry-front-cluster.md`: `:26`, `:54`, `:123` and `:221` (FM2).
  - **CONDITIONAL:D4219-delta** (Tier 2 [SCOPE CHANGE], scope-lock decisions 10 and 11): the I11/I15 stage terms in the tool, with their definitions and FM rows reconciled in the standard (review #7873 CD-2(a)); the I6 relabel — `PLAN_SUBTYPES`, the schema paragraph and the standard's text name the population as cards carrying a per-issue Stage-4 gate decision (review CD-1); the per-issue Stage-4 gate `d-class` emission (issue subject), with FM-1's removal-disposition clause, in `stage-04-planning.md` § 11. The slice updates these rows when the delta renders: a fired row is promoted in the same commit, and a row that does not fire is recorded.
  - The Tier-A data-flow marker declared at Commit 0 (§ Tier-A Activated Design Artifacts).
- **Slice 4 — #5245** · S · design on #7734 (comment 5830150095), amended by scope-lock decision 8.
  - `core/deploy/deploy.sh`: `cc_telemetry_cutoff` `__none__` → **`v4.55`** (`:1994`), frozen at the scope-lock (the design's trap-4 move-forward branch is dropped; review #7874 CD-1); the narrative and re-dormant-line reconciliation; the #1290 group hermeticity pins; new OS arms — OS-17b (CIAC-4's control, with #5586's strings), OS-22 (denominator), OS-23 (sibling-claim stability) and OS-24 (armed default); review #7874 FM-1's three wording fixes (the 1b record sentence, "all FOUR cutoffs" at `:17150`, the 2e claim); and the `:1826` gate-side twin of "every rate slot resolved N/A" (review #7871 FM-5, adopted at the scope-lock; DEV-6).
  - `release/tools/automated-closeout.sh` (the Tier 2 growth): Test 15 group m (m2-control, m5 and m10 fixtures carry all three members — D5245-fixtures (a)), the `(j.1)` comment at `:9944-9945` and the `:15713` claim line. Changes 1 and 2 land in one commit.
  - The anchor sweep is recorded in the Deviation Log (DEV-16).
- **Slice 5 — #5553** · S · design on #7735 (comment 5830550955), amended by scope-lock decisions 3 and 6.
  - `release/tools/compute-cycle-time.sh`: the anchor set stays `{deploy-skill, deploy-harness}` (D5553-admit B). A pure `t_deploy_na_reason` over an explicit partition (`TD_ANCHOR_SUBTYPES` / `TD_EXCLUDED_SUBTYPES`) with three causes — none, failed, excluded — naming every excluded subtype with its tally in the rule-plus-producer form (review #7875 CD-1; the emitter-only variant is acceptable); arms CR-1..CR-8, CR-9 (the DORA tuple parity arm, review FM-2) and U-1. The query tool's exit status is checked at `:330` (die, exit 1) with a CR arm on an empty evals directory (review FM-1, decision 3). The shared self-terminating `--help` renderer (E2) lands here; #5467 skips its copy. The premise (E1) states the anchor as § 1 does — Stage 12 completion of skill and harness deploys — not as "the release's change reaching the runtime" (review PR-3 (ii)).
  - `core/deploy/deploy.sh`: comment-only — the consumer note `:6715-6723` and the non-emission inventory `:6842-6848`.
  - `release/references/standards/deployment-cycle-time.md`: § 2.1 (`:38`), § 4 (`:77`, the cause table) and § 4.1 (`:87-89`, S3 as written; this card owns § 4.1). (B)'s rationale is stated on its forward-looking ground — the carrier writes a resolved mirror row on every stamped invocation, so admission would make every stamped content-only release compute — and `v4.55` moves out of "correctly N/A" into (B)'s false negatives with `v4.54`, `v4.58` and `one-system-of-record-per-element` (review PR-2). The None cause gains its third limb, and § 4.1's "no longer structural" statement the same carve-out: a release whose change reached the runtime through a carrier that writes no `deployment-status` row — the hook tier and composition surfaces (review PR-3 (i) and (iii)).
  - The two DORA rows (`compute-dora-metrics.sh`, `dora-telemetry.md`) do not fire (DEV-10).
- **Slice 6 — #5467** · M · design on #7736 (comment 5830306598), amended by scope-lock decisions 3 and 7.
  - `release/tools/compute-cycle-time.sh`: T_GO selected by its full identity — `gate-outcome` / `plan-review-go` / stage `"9"` / actor `operator` — through `select_go_anchor_rows` and `go_anchor_ts` (MIN within the identity). No row of that identity → N/A with its own reason, factored into `t_go_na_reason` beside `go_anchor_ts` with CG arms and worded as an observed fact under the tool's join keys (review #7885 FM-3); the query tool's exit status checked at `:313`; the contract `:12` and its WHY block; HELP-1. Skip change 1c (slice 5 landed the renderer) and the comment half of 1f (#5553's Finding 5).
  - `release/tools/append-pipeline-event.sh`: one arm in #4219's `validate_row_identity`, which gains an optional `actor` parameter, refusing `gate-outcome/plan-review-go` at any other stage or actor, enforced from day one. The refusal message opens with provenance (review FM-2) and names a destination for every refused class (FM-1); the `plan-review-no-go` arm (F8) is adopted now.
  - `release/references/standards/pipeline-event-log-schema.md` § 3: one MUST-sentence convention block — the 48 non-identity rows accepted as historical (D5467-history) and each refused class's destination named; no pipe character, no table, no column-3 token (the #4220 trap).
  - `release/references/standards/deployment-cycle-time.md`: the Tier-A marker on the § 2 table, `:30`, `:37`, FM1 `:163` and FM4 `:166`.
  - `release/skills/release-hub/references/orchestration-playbook.md` (**sanctioned session**): `:160-164` and one paragraph after the EMISSION-CONTRACT END marker; item 4b points at `hub-session-continuity.md` § 3.2 (review PR-2); the Stage 7/8 rows went to #7730.
  - `packages/release-hub.skill` and its `.sha256` sidecar: rebuilt inside the session with `bash core/deploy/tools/build-skill-packages.sh release-hub` (Check 7).
  - `core/deploy/deploy.sh` is **not** edited: Check 61 is reused unchanged.
  - The replay is restated as 21 computing releases — 4 change, 17 are unchanged, 4 carry the new N/A reason (review PR-1).
  - The grounding entry for the T_GO reason string: § Evidence Grounding.
- **Slice 7 — #6252** · M · design on #7737 (comment 5830991586), amended by scope-lock decisions 2, 3, 4, 9 and 12.
  - `release/references/pipeline/stage-09-plan-review.md`: Phase C1 (D6252-bind B1) — the decision record, the verdict's `gate-outcome` row (stage 9, actor `operator`; `plan-review-go` for GO and GO WITH CONDITIONS, `plan-review-no-go` for NO-GO) and its typed read-back (`--event-type gate-outcome --event-subtype <plan-review-go or plan-review-no-go> --stage 9`), as one action before the gate sub-task closes, with review #7886 FM-2's precedence sentence (the verdict's row is `gate-outcome`, never `decision`/`d-class`, although the verdict is rendered through a Decision Briefing); the § 11 table; the Tier-A process-flow artifact. Phase C1 is exercised at this release's own Stage 9.
  - `release/tools/automated-closeout.sh`: `read_state` (S-B) captures stderr with the phase-6.6 sentinel idiom and carries the tool's `N/A (<reason>)` verbatim into the report, the JSON and the chore-PR body, in four states (value · `N/A (<reason>)` · `N/A — DEGRADED` · `NOT-EVALUATED`). A read-only field verdict — `CONFORMANT` / `DIVERGENT` / `ABSENT` / `NOT-EVALUATED` — never a gate and never a rewrite: DIVERGENT is worded as a disagreement carrying the tool's `--iso` anchors (review PR-1), the invocation key is pinned (FM-3), and only the class and exit code of a NOT-EVALUATED result reach the public chore-PR body (FM-4). INT-4 and CY-13 are added; CY-6 is inverted so a negative delta renders as a non-value (FM-1, decision 3). Mind ms#334 #6871's adjacent edit at `:1753` inside `phase_read_state`.
  - `release/references/standards/deployment-cycle-time.md`: `:61-65`, `:73` (the § 3.1 verbatim rule and its carriage table), `:83`, one FM1 `:163` cell, `:144`, `:155` and `:184`. § 4.1 is #5553's — never both.
  - `release/skills/release-hub/references/orchestration-playbook.md` (**its own sanctioned session**, after #5467's): the Procedure 5 sentence after "NEVER auto-crossed." (`:357`) and one pointer paragraph after the EMISSION-CONTRACT END marker (the `stage-9-go` row stays `MUST`); plus scope-lock decision 4's close-gate sentence.
  - `packages/release-hub.skill` and its `.sha256` sidecar: rebuilt in that session.
  - **C-S (D6252-s12):** `release/references/pipeline/stage-12-execute.md:129` and `:133` — the Stage-12 template's `N/A` form becomes the tool's own reason, verbatim (DEV-20).
  - **C-R (D6252-remedy):** `core/deploy/deploy.sh:19261` and `release/references/pipeline/stage-13-close.md:173` — Check 61's remedy text gains the no-backfill clause for `gate-outcome/plan-review-go`.
  - Check 61 is reused unchanged; `check-emission-contract-subset.sh` is not extended.
  - The grounding entry for the CONFORMANT/DIVERGENT vocabulary: § Evidence Grounding.

**A2 container determination (for each slice's spoke).** Every card's decomposition is multi-file and structure-changing, so the threshold predicate selects the GitHub sub-issue container; the per-card Stage-6 sub-tasks the hub scaffolded (#7738–#7744) are that container, with the change units enumerated in § File Change Matrix.

---

## Stage Applicability Matrix

**Stage 5 (activation-criteria matrix, `planning-solutioning-handoff.md` § 4):**

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #5586 | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ACTIVATE | Which false-premise holder the fix owns |
| #7432 | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | New fixtures. Join-key and legacy rule |
| #4219 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | Writer-side validation contract. The RCA offers two filter options |
| #5245 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | Anchor identifier form. Candidate anchors |
| #5553 | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | ACTIVATE | Count vs exclude. The DORA / standard anchor-set blast radius |
| #5467 | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | Playbook. Identity contract. Selector and gate options |
| #6252 | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | Playbook. Emission-binding contract. Reuse Check 61 vs extend |

**Release-level rollup: ACTIVATE.** Collective Review fired and scope-locked on 2026-09-25.

| Stage | #5586 | #7432 | #4219 | #5245 | #5553 | #5467 | #6252 | Basis |
|---|---|---|---|---|---|---|---|---|
| **5 — Solutioning** | APPLY (#7731; review #7871) | APPLY (#7732; #7872) | APPLY (#7733; #7873) + delta (#7896) | APPLY (#7734; #7874) | APPLY (#7735; #7875) | APPLY (#7736; #7885) | APPLY (#7737; #7886) | T3 · T4 · T6 fire; scope-lock 2026-09-25 |
| **6 — Engineering** | APPLY (#7738) | APPLY (#7739) | APPLY (#7740) | APPLY (#7741) | APPLY (#7742) | APPLY (#7743) | APPLY (#7744) | P0, § Implementation Sequence order |
| **7 — Dev Testing** | APPLY (#7745) | APPLY (#7746) | APPLY (#7747) | APPLY (#7748) | APPLY (#7749) | APPLY (#7751) | APPLY (#7753) | Runtime-suite rows 4 (`release/tools/*`) and 2 (`core/deploy/deploy.sh`) |
| **8 — QA** | APPLY (#7755) | APPLY (#7757) | APPLY (#7759) | APPLY (#7761) | APPLY (#7763) | APPLY (#7765) | APPLY (#7767) | Every card changes a telemetry value, a gate or a writer contract |
| **9 — Plan Review** | APPLY (#7769, release-scoped) | | | | | | | **Deep** (`cross-cutting`); Phase C1 exercised on this release's own GO |
| **10 — Dry Run** | COMPRESS (#7771, closed) | | | | | | | Git-native release (Stage Compression) |
| **11 — Snapshot** | COMPRESS (#7774, closed) | | | | | | | Git history is the snapshot |
| **12 — Execute** | APPLY (#7777) | | | | | | | Merge + atomic claim (versioned) + `release-hub` deploy, verified by content |
| **13 — Close** | APPLY (#7779) | | | | | | | 30-day outcome window; the seven cards are transitioned to closed at Stage 13 |

No stage is skipped for any card.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction and grouped by slice. A path edited by more than one card is listed under each card; § Contention Map carries the per-file writer set. Every conditional row carries its `CONDITIONAL:<token>` inline.

```
# ── Release corpus (Engineering Commit 0) ──
release/releases/plans/telemetry-is-computable_RELEASE_PLAN.md  ADD

# ── #5586 · slice 1 (reader side, under hold K) ──
release/tools/compute-close-class-telemetry.sh  EDIT
release/tools/automated-closeout.sh  EDIT
release/references/standards/close-class-telemetry.md  EDIT
release/tools/tests/test_close_class_telemetry.sh  EDIT
.github/workflows/release-tooling-smoke.yml  EDIT

# ── #7432 · slice 2 (twelve files; the schema row is dropped) ──
release/tools/check-event-record-integrity.sh  EDIT
release/tools/tests/fixtures/event-record/log-c4-collision.md  ADD
release/tools/tests/fixtures/event-record/log-c4-collision-control.md  ADD
release/tools/tests/fixtures/event-record/c4-collision-tree/fixture-c4-rel-a/action-items.md  ADD
release/tools/tests/fixtures/event-record/c4-collision-tree/fixture-c4-rel-b/action-items.md  ADD
release/tools/tests/fixtures/event-record/c4-collision-tree-control/fixture-c4-rel-a/action-items.md  ADD
release/tools/tests/fixtures/event-record/c4-collision-tree-control/fixture-c4-rel-b/action-items.md  ADD
release/tools/tests/fixtures/event-record/c4-collision-tree-control/v0.92/action-items.md  ADD
release/tools/tests/fixtures/event-record/log-clean.md  EDIT
release/tools/tests/fixtures/event-record/ledger-clean.md  EDIT
release/tools/tests/fixtures/event-record/ledger-state-divergent.md  EDIT
release/tools/tests/fixtures/event-record/hub-state-tree/fixture-clean-release/action-items.md  EDIT

# ── #4219 · slice 3 (its rows as they stand in the design on #7733) ──
release/tools/compute-front-cluster-telemetry.sh  EDIT
release/tools/append-pipeline-event.sh  EDIT
release/references/standards/pipeline-event-log-schema.md  EDIT
release/references/standards/phase-telemetry-front-cluster.md  EDIT

# ── #4219 · the three delta-design expansion rows, CONDITIONAL:D4219-delta (delta design on #7896) ──
# the I11/I15 stage terms
release/tools/compute-front-cluster-telemetry.sh  EDIT  CONDITIONAL:D4219-delta
# the I6 relabel and its durable text (the constant and the schema paragraph ride the rows above)
release/references/standards/phase-telemetry-front-cluster.md  EDIT  CONDITIONAL:D4219-delta
# the per-issue Stage-4 gate emission with the removal-disposition clause, section 11
release/references/pipeline/stage-04-planning.md  EDIT  CONDITIONAL:D4219-delta

# ── #5245 · slice 4 (plus the Tier 2 growth into the close-out Test 15 group m) ──
core/deploy/deploy.sh  EDIT
release/tools/automated-closeout.sh  EDIT

# ── #5553 · slice 5 ──
release/tools/compute-cycle-time.sh  EDIT
core/deploy/deploy.sh  EDIT
release/references/standards/deployment-cycle-time.md  EDIT

# ── #5467 · slice 6 (the playbook row and the package pair in a sanctioned session) ──
release/tools/compute-cycle-time.sh  EDIT
release/references/standards/deployment-cycle-time.md  EDIT
release/references/standards/pipeline-event-log-schema.md  EDIT
release/skills/release-hub/references/orchestration-playbook.md  EDIT
release/tools/append-pipeline-event.sh  EDIT
packages/release-hub.skill  EDIT
packages/release-hub.skill.sha256  EDIT

# ── #6252 · slice 7 (the playbook row and the package pair in its own sanctioned session) ──
release/references/pipeline/stage-09-plan-review.md  EDIT
release/skills/release-hub/references/orchestration-playbook.md  EDIT
release/tools/automated-closeout.sh  EDIT
release/references/standards/deployment-cycle-time.md  EDIT
packages/release-hub.skill  EDIT
packages/release-hub.skill.sha256  EDIT
# C-S — the Stage-12 Cycle-Time template, lines 129 and 133
release/references/pipeline/stage-12-execute.md  EDIT
# C-R — the Check 61 remedy text, deploy.sh line 19261 and stage-13-close.md line 173
core/deploy/deploy.sh  EDIT
release/references/pipeline/stage-13-close.md  EDIT
```

- **Matrix size:** 32 distinct paths — 8 ADD (this plan and #7432's seven fixtures) and 24 EDIT, one of them (`stage-04-planning.md`) conditional. Every EDIT path exists at the branch base and every ADD path is absent (probe in § Verification Evidence).
- **Resolved conditional rows are not carried.** The Stage-4 matrix's `CONDITIONAL:D5553-admit` (2 rows), `CONDITIONAL:D6252-widen` (3 rows) and `CONDITIONAL:D-Scope-keep-all` rows (with their `D4741-taxonomy`, `D4741-tool`, `D4742-rubric-pointer` and `D4228-adr-edit` rows) all resolved false; § Deviation Log records each NOT DELIVERED (DEV-9, DEV-10). `CONDITIONAL:D5467-writer-gate` fired and is promoted (the writer row under #5467); `CONDITIONAL:D5467-check61` and `CONDITIONAL:D7432-legacy` (the schema) resolved false.
- **Package cascade, resolved against the roster:** `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` with the 32 paths on stdin names `release-hub` only; the 29 paths other than the playbook and the package pair name none (control: `release/skills/release-planner/references/release-plan-template.md` → `release-planner`). Only the playbook stales a package, and its package pair is declared in both sanctioned slices.
- **No new executable.** Every ADD row is this plan or a markdown fixture, so the new-executable companion obligation (an allowlist row and CI wiring) does not fire.
- **No ADR** is authored in this release (every Stage-5 design recorded its skip rationale), so no ADR-number slot is contended and no index regeneration is owed: `ADR index: N/A — this release adds no record under release/ADRs/`.
- **No path moves** — the intents are ADD and EDIT only; no rename, relocate or delete, so the mover set is empty.

#### Read-only inputs

```
release/tools/query-pipeline-event.sh  READ
release/tools/check-emission-contract-subset.sh  READ
core/deploy/allowlists/decision-emission-asserted-set.txt  READ
release/tools/produce-learnings-register.sh  READ
release/tools/compute-middle-cluster-telemetry.sh  READ
release/references/templates/release-learnings-register-template.md  READ
core/standards/hub-session-continuity.md  READ
release/references/standards/runtime-suite-selection-map.md  READ
```

`compute-middle-cluster-telemetry.sh` I24 consumes `plan-review-go` subjects without a stage predicate — read, not in scope (§ Stage 9 Disclosures). `hub-session-continuity.md` § 3.2 is where #5467's playbook item 4b points; it is read, not changed.

#### Release-wide explicit non-scope

```
release/releases/RELEASE_LOG*.md  NOT EDITED
release/releases/notes/  NOT EDITED
release/releases/plans/v*/  NOT EDITED
release/tools/check-emission-contract-subset.sh  NOT EDITED
release/tools/compute-dora-metrics.sh  NOT EDITED
release/references/standards/dora-telemetry.md  NOT EDITED
```

Historical records are never rewritten — every past Cycle-Time and Close-Class-Telemetry field, including the three inflated Cycle-Time values D5467-history accepts, and every archived ledger segment. The operator-instance pipeline event log is append-only (schema § 4.1): no historical row is rewritten or backfilled. Check 61 is reused, not extended.

---

## Agent-Editability Read

Transcribed from the Stage-4 derivation (controls read at `8e0ee084`; the deployed hook copies byte-identical to `core/hooks/`) and extended to the rows the scope-lock added. Neither control file is among the 18 files changed between `8e0ee084` and the branch base `35dbf418`, so the derivation holds at Commit 0.

- **Tier-0 floor** (`core/hooks/block-autonomy-ceiling.sh`, `BLOCK-AUTONOMY-001`): projected onto tracked paths it names `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md`. **No write-set path intersects them.**
- **Sanctioned-session gate** (`core/hooks/block-skill-direct-edit.sh`): `SKILL_SCOPE_RE` matches `<module>/skills/<name>/SKILL.md` and `references/*.md` of an armed skill; `release-hub` is armed and not on the exemption list. **One write-set path matches: the playbook.**

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #5467, #6252 | `release/skills/release-hub/references/orchestration-playbook.md` | no | yes (regex ✓ · armed ✓ · not exempt ✓) | sanctioned-session-required | sanctioned-session-required | `pmo-skill-editor` Mode A — one session per card, #5467's first |
| #5467, #6252 | `packages/release-hub.skill`, `.sha256` | no | build product — takes its source's class | sanctioned-session-required | ↑ | produced by `build-skill-packages.sh release-hub` inside each session |
| #5467 | the tool, the writer, the schema, the standard | no | no (regex ✗) | unconstrained | ↑ | the same session, or an ordinary Engineering spoke for these rows |
| #6252 | stage-09, stage-12 (C-S), stage-13 (C-R), `deploy.sh` (C-R), the close-out, the standard | no | no (regex ✗) | unconstrained | ↑ | ordinary Engineering spoke |
| #5586 · #7432 · #4219 · #5245 · #5553 | every row in their slices, including #5586's suite and smoke workflow, #7432's fixtures, #4219's conditional `stage-04-planning.md` row and #5245's close-out row | no | no (regex ✗) | unconstrained | unconstrained | ordinary Engineering spoke |

**Sequencing consequence:** two sanctioned sessions touch one file (the playbook), in order — #5467 at slice 6, then #6252 at slice 7. "Unconstrained" means no control refuses the write; it never means the change is ungoverned.

---

## Contention Map

### Within-release contention (derived from § File Change Matrix)

| File | Writers (slice order) | Intent mix | Severity | Recommendation |
|---|---|---|---|---|
| `release/tools/automated-closeout.sh` | #5586 (phase-6.8 disposition, Test 4c.6, the `:15682` summary) · #5245 (Test 15 group m, the `(j.1)` comment, the `:15713` claim line) · #6252 (`read_state` and its helper, the chore-PR block, Test 4h.2 group CY, one claim line) | edit×3 | MULTI-WAY | Separate functions; serial P0 makes each a re-anchor, never a conflict. CIAC-5 grades the integration |
| `core/deploy/deploy.sh` | #5245 (the Check 48 `cc_telemetry_cutoff`, its narrative, the OS arms, the #1290 pins, `:1826`) · #5553 (comment-only `:6715-6723`, `:6842-6848`) · #6252 (C-R, the Check 61 remedy line `:19261`) | edit×3 | MULTI-WAY | Separate regions. #5467 does not edit it (Check 61 reused unchanged) |
| `release/references/standards/deployment-cycle-time.md` | #5553 (§ 2.1, § 4, § 4.1 — the § 4.1 owner) · #5467 (the § 2 Tier-A marker, `:30`, `:37`, FM1 `:163`, FM4 `:166`) · #6252 (`:61-65`, `:73` and the § 3.1 table, `:83`, one FM1 `:163` cell, `:144`, `:155`, `:184`) | edit×3 | MULTI-WAY | One review pass. FM1 `:163` is one line whose cells #5467 and #6252 each own; add no pipe character inside a cell |
| `release/tools/compute-cycle-time.sh` | #5553 · #5467 | edit×2 | BINARY | #5553 first (the smaller change; it lands the shared `--help` renderer, which #5467 skips); both edit the N/A block → CIAC-2 |
| `release/references/standards/pipeline-event-log-schema.md` | #4219 (the § 3 delegation paragraph, plus its relabel under CONDITIONAL:D4219-delta) · #5467 (one § 3 convention block) | edit×2 | BINARY | Different § 3 paragraphs; no table row and no column-3 token (the #4220 trap) → CIAC-3. #7432 no longer edits the schema |
| `release/tools/append-pipeline-event.sh` | #4219 (`validate_row_identity`, its call, its self-test) · #5467 (one arm and the optional `actor` parameter) | edit×2 | BINARY | One validator mechanism → CIAC-3's one-validator line |
| `release/skills/release-hub/references/orchestration-playbook.md` + `packages/release-hub.skill` + `.sha256` | #5467 · #6252 | edit×2 | BINARY | Two sequential sanctioned sessions; rebuild the package in each |
| `release/tools/compute-front-cluster-telemetry.sh` · `release/references/standards/phase-telemetry-front-cluster.md` · `release/references/pipeline/stage-04-planning.md` | #4219 (with its CONDITIONAL:D4219-delta rows) | edit×1 | NONE | — |

Every other matrix path has a single writer.

### Cross-release contention (the scope-lock's Contention Map at Commit 0)

| Surface | Writers in this release | Writers in other milestones | Disposition |
|---|---|---|---|
| `release/tools/automated-closeout.sh` | **three:** #5586 (phase 6.8) · #5245 (Test 15) · #6252 (`read_state`) | ms#395's #6892 (phase 6.8; its release PR #7895 is open and edits the file now) · ms#334's #6871 (the adjacent `:1753` edit inside `phase_read_state`, directly above #6252's region) | Serialize the merges; the later release re-baselines; keep edits inside the named functions |
| `packages/release-hub.skill` (+ `.sha256`) | rebuilt by #5467 and #6252 | rebuilt by ms#334's #6237 | Whichever merges second rebuilds from its merged source (Check 7) |
| `release/references/standards/close-class-telemetry.md` | #5586 (the value-domain edits, including § 3.2's two emit examples) | ms#395's #6892 (the § 3.2 `:90` emit sentence, unconditional under its Plan amendment 1) | Disjoint lines; the later merge re-baselines (review #7871 PR-1) |
| `release/references/pipeline/stage-13-close.md` | #6252 (C-R, `:173`) | ms#395 (PR #7895 edits the file now) | Disjoint lines expected; the later merge re-baselines |
| `release/references/pipeline/stage-04-planning.md` | #4219 (CONDITIONAL:D4219-delta, § 11) | ms#405 (PR #7839 edits the file now) | Only if the delta fires; the later merge re-baselines |

The last two rows come from the Commit-0 roster read (§ In-Flight Release Roster). The remaining cross-milestone edges are the milestone description's Parallelization Map (recorded 2026-09-24); they are not restated here.

---

## Cross-PR Overlap Audit

### Baseline SHA

**`8e0ee084`** (`8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d`) — the Stage-4 Phase A0 audit-start pin (2026-09-25T02:55Z), transcribed unchanged as Survival-Set row 9. The Stage-9 revalidation predicate (and Stage-12 A.5's) is `git log 8e0ee084..origin/main --name-status --find-renames`, intersected with this release's matrix paths.

**Engineering Commit-0 branch base:** `35dbf418` (`35dbf41847df2c1deab792d2944e46ac6ddd26fd`), the merge of the `v4.69` Stage-13 chore PR #7888. The window between the two touches no matrix path:

```
Probe:       git diff --name-only 8e0ee084 35dbf418, intersected with the 32 matrix paths (grep -F -x -f)
Denominator: 35 commits and 18 changed files (the v4.69 release and its Stage-12/13 chores); 32 matrix paths
Control - sensitivity: the same intersection with release/releases/RELEASE_LOG.md appended to the
             pattern list → 1 hit (the probe sees a changed path when one is listed)
Control - specificity: NOT TRIGGERED — the match is whole-line and literal (-F -x), so a partial-path
             near-miss is excluded by construction
Extraction:  the full 18-line name list; the full 32-line path list
Result:      0
Verdict:     CLEAN — no commit between the Stage-4 pin and the branch base touches a file this release changes
```

So a Stage-9 G-PR8 read against the pin sees those commits as divergence that touches no release file.

### Open PRs and recently merged PRs

- **Stage 4 (at the pin):** 1 open PR, #7638 (`egress-hook-batch`); its files ∩ this matrix = ∅ for every unconditional row.
- **At Commit 0:** 2 open PRs (`gh pr list --state open --limit 500` → 2 rows), both release siblings — § In-Flight Release Roster. `egress-hook-batch` merged as `v4.69` (PR #7638, merge `40cec0c7`) with its Stage-12 and Stage-13 chores (#7867, #7888) — none of their files is a matrix path (probe above).

### Structural sub-audit

N/A — the matrix intents are {ADD, EDIT}: 0 renames, relocates or deletes, so the mover set is empty.

### In-Flight Release Roster

**Stage-4 measurement (transcribed):** measured at `8e0ee084` · 2026-09-25T03:30Z · population n=1.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `egress-hook-batch` | `#7638` | `48708621` | `minor` | `v4.69` | `v4.69` | — (∅; conditional ADR slot) |

That sibling has since merged and claimed `v4.69`.

**Commit-0 re-read** (a pinned measurement carrying no verdict; Stage 9 Phase A6.6 re-measures the population): measured at `35dbf418` · 2026-09-25T18:55Z · population n=2 (open PRs with a `release/*` head, drafts included, plus remote `release/*` heads with no PR, minus this release; `git ls-remote --heads origin 'release/*'` → 2 heads, both with a PR).

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `closeout-verification-rows-consistent` | `#7895` | `0f446cb4` | `minor` | `v4.70` | `v4.70` | `release/tools/automated-closeout.sh`, `release/references/pipeline/stage-13-close.md` |
| `verifier-grades-what-plans-declare` | `#7839` | `aa8cd0d3` | `minor` | `v4.69` (stale — claimed by `egress-hook-batch`) | `v4.70` | `release/references/pipeline/stage-04-planning.md` (this plan's CONDITIONAL:D4219-delta row) |

Both siblings recompute this release's slot, so all three are co-contenders for `v4.70`; merge order arbitrates at the Stage-12 compare-and-swap. #7839 also edits `release/tools/verify-release-plan.sh` — not a matrix path, but the executor that grades this plan's Verification Plan and CIACs — so a merge before this release's Stage 9 changes how its rows grade (R2).

---

## Integration Points

| Surface | Writers in this release | Consumers that must keep working |
|---|---|---|
| `compute-cycle-time.sh` (T_GO / T_DEPLOY / N/A reasons) | #5553, #5467 | `automated-closeout.sh` `read_state` (#6252) · the Stage-12 B5 author (§ 3.1 rule, C-S) · Stage-13 A6 `cycle-time-baseline.md` · the RELEASE_LOG `**Cycle-Time:**` field |
| `pipeline-event-log-schema.md` (§ 3 enum and convention blocks, § 4.1 `integrity_cutover:`, § 11.8.1 registry) | #4219, #5467 | `append-pipeline-event.sh` `parse_schema_enum` / `parse_schema_labels` (a column-3 backtick becomes a subtype — the #4220 trap) · `check-event-record-integrity.sh` (the one-line § 4.1 key) |
| `append-pipeline-event.sh` (the writer and its `validate_row_identity`) | #4219, #5467 | every pipeline emitter at every stage — the scripted emitters pass other (stage, type) pairs and are inert by construction; the hub's hand-emitted rows meet the refusals, whose messages name the destination |
| `automated-closeout.sh` (Deployment-Log field readers and writers) | #5586, #5245, #6252 | reads the `deploy.sh` `cc_telemetry_cutoff` seam through `_resolve_telemetry_cutoff`; arming makes the telemetry field an owed Stage-13 output |
| `orchestration-playbook.md` (EMISSION-CONTRACT; the close gate) | #5467, #6252 | Check 61's asserted set · `check-emission-contract-subset.sh` · the deployed `release-hub` skill |
| The T_DEPLOY anchor set | #5553 (named exclusion; the set unchanged) | `compute-dora-metrics.sh:198` (the same set; CR-9 parity) · `deployment-cycle-time.md` · the `deploy.sh:6715` consumer note |
| The Close-Class-Telemetry field grammar | #5586 (value domain), #5245 (arming) | Check 48 l-3 / l-3a · the close-out's pre-write checks (`:3066`, `:3080`) |

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | Keep-all size (38 raw / 44 effective) | — | — | **Resolved at the Stage-4 gate** (D-Scope B); the residual over-band (29 effective under `cross-cutting`) is accepted by operator override (DEV-2) | operator |
| R2 | Cross-release collisions on `automated-closeout.sh` and `deploy.sh`: ms#395's PR #7895 is open and edits the close-out and `stage-13-close.md`; ms#334 plans the same files; ms#405's PR #7839 edits `stage-04-planning.md` and the plan executor | High | Medium | Serialize the merges; the later release re-baselines; Stage 9 A6.5 / A6.6 re-measure; keep edits inside the named functions; re-run the plan executor on the merged `main` at Stage 7 and Stage 9 | hub |
| R3 | #5586 is a half-fix without #6892: after merge, production indicators 1, 2 and 5 read NOT-EVALUATED (no longer the clean-absence N/A) until #6892 wires `--retro` | High | Medium | Hold K; AC-1 removed from this release; AC-2 graded as non-regression; merge the two releases adjacently | operator / hub |
| R4 | #5467's selector turns T_GO to N/A for a GO recorded by the hub, or by the operator at another stage | Medium | Medium | CIAC-1 aligns the emitter identity (#6252's Phase C1) with the selector; the writer arm refuses a mis-typed GO at write time; the new N/A reason names the identity miss | Engineering |
| R5 | The #4220 trap: a backticked token in schema § 3 column 3 becomes a subtype the writer accepts | Medium | High | Convention blocks only; CIAC-3 runs both self-tests and the phantom-subtype control | Engineering |
| R6 | Writer-gate blast radius: #4219's and #5467's arms run at **every** emitter; an over-broad predicate refuses legitimate rows mid-release | Medium | High | Must-not-flag arms for every live shape (#4219: 38 accept arms, 0 of 7,474 live rows refused; #5467: exactly the 48 non-identity rows refused, 0 of 7,372 others); each arm keyed on the full (type, subtype) pair | Engineering |
| R7 | The first sanctioned-session edit is at slice 6, so a gate or trailer miss surfaces late | Low | Medium | **Discharged at Commit 0** — § Commit-0 Version Re-Verify Record → pre-flight | hub |
| R8 | Arming `(l)` raises standing findings | Medium | Medium | Anchor `v4.55`: 15 VERIFIED rows in scope with 0 findings at design time, prefix-safe; frozen with no re-anchoring; a finding that lands before merge is recorded as named and accepted (CIAC-4 reads 0 **unnamed** findings). After merge, Lane 1 blocks an absent field only on a CLI-dispatched close; a version-less close has no Lane 1, and a vacuous field passes Lane 1 and is a Lane-2 (l-3a) finding — so a gh-degraded or hand-assembled close can land a permanent finding (review #7874 PR-1) | Engineering |
| R9 | Reflexive loop: this release's own Stage 9/12/13 run the pre-merge procedures, and its own Cycle-Time and close-class fields come from the new code at close | Low | Low | Do not count them as validation; baselines are pinned; Phase C1 is exercised on this release's own GO by operator decision | hub |
| R10 | Shared version slot `v4.70` with two in-flight siblings | High (slot) | Low | Commit-0 re-verify (clean); the Stage-12 atomic claim arbitrates; no ADR in this release, so no ADR slot | Engineering |
| R11 | Quota | Medium | Medium | The Stage-5 wave ran; Stages 7 and 8 are 7-wide; Checkpoint B re-validates at every launch | operator |
| R12 | #6252 AC-1's behavioural arm cannot be graded inside this release | High | Low | The deferred arm is recorded; the static binding is verified now | hub |
| R13 | Keep-all ADR-065 / template-sync edits | — | — | **Resolved** — they left with #4228 | operator |
| R14 | Rollback leaves rows written under the new tools in place (append-only) | Low | Low | Accepted — the rows are correct records | — |
| R15 | The writer-refusal transition: this release's own post-merge Stage-12/13 hub emits are the first under #5467's arm (12 of the 48 refused rows were Stage-12/13 notes), and in-flight hubs keep the old playbook text until the deploy (review #7885 FM-1) | Medium | Medium | A named destination for every refused class, in the schema block and in the refusal message; the `plan-review-no-go` arm adopted now | Engineering / hub |
| R16 | Hand-written release-level markers typed `deploy-skill` still anchor T_DEPLOY (7 of 21 computing values); no card here refuses such a row | High | Medium | Disclosed at Stage 9 (§ Stage 9 Disclosures); #6252's DIVERGENT is worded as a disagreement, never as a field defect | hub |
| R17 | Phase 6.8's verdict contract is shared with #6892, which is scope-locked in ms#395 | Medium | Medium | Arm (d2) verdict-agnostic; #6892 owns `_cct_args` and the `:90` sentence; the second merge re-baselines | Engineering |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential (P0), in § Implementation Sequence order |
| **Commit strategy** | Commit 0 = this plan; one commit per slice, each acceptance-criterion arm observed RED before its fix; #5245's Changes 1 and 2 in one commit; `fix(dt):` commits on iteration. Messages carry the `release(telemetry-is-computable):` prefix and name the card |
| **Review approach** | Single PR (D-C SINGLE), opened in draft at Commit 0 → ready-for-review at the Stage-9 gate. Parser-clean body: the seven cards appear in the Issue References block as `References`, and they are transitioned to closed at Stage 13 |
| **Deployment mechanism** | Git merge, then `./deploy.sh --deploy release-hub --release telemetry-is-computable` (the release-stamped deploy emits this release's own `deployment-status` rows). The `release-hub` package is rebuilt in each slice that edits the playbook (Check 7) |
| **Stacked-base cleanup posture** | n/a (single branch) |

---

## Verification Plan

Every method cell carries its probe literally, reproducible from the cell alone. A method whose command is a `bash …` tool run is not executed by the plan-driven executor `release/tools/verify-release-plan.sh`, whose runnable-verb set is closed to read-only queries by design; such a row reads SKIP or ERROR there, and its mechanical guarantee lives in the tool's own CI-invoked self-test. The issue bodies stay historical: the scope-lock's amendments are carried in the bound rows below (DEV-18).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #5586 | AC-1 | `[DEFERRED — removed from this release at the Collective Review scope-lock: #6892 delivers the caller wiring under hold K and grades it on that release with its own argv-recording arm]` | not graded in this release · the Stage-4 probe `grep -cE -- '--retro' release/tools/automated-closeout.sh` reads 0 at the branch base (control: `grep -c 'compute-close-class-telemetry'` → 14) and cannot see an array-built call |
| #5586 | AC-2 | `bash release/tools/compute-close-class-telemetry.sh --self-test` (its register-present arms), and a run of the same tool with `--retro release/references/templates/release-learnings-register-template.md` — a register-present fixture | indicators 1, 2 and 5 computed: `10/10 (1.00)`, `0/2 (0.00)`, `present` · graded as a **non-regression** criterion: this release does not change the computed path, and production clearance needs #6892 (hold K) |
| #5586 | AC-3 | two fixtures: flag omitted; flag supplied with the file missing | two distinct values, each non-empty |
| #5586 | AC-4 | `bash release/tools/tests/test_close_class_telemetry.sh` — GROUP E: the resolver mutant (E2b) and the structural binding arm over the live call sites, each with its `mutate()` control | the omission/absence split reverted at the resolver, or at any live call site, turns exactly one arm RED · the pre-fix literals count 0 after the fix |
| #7432 | AC-1 | `bash release/tools/check-event-record-integrity.sh --self-test` with new collision arms | release A's stale `AI-001` is reported · control: A with its own matching event → 0 findings |
| #7432 | AC-2 | same, one collision arm per limb | 3 of 3 limbs report |
| #7432 | AC-3 | `bash release/tools/check-event-record-integrity.sh --surface=both` before and after, with per-release attribution | before/after counts printed; legacy rows graded by the stated §2a/§4.1 rule |
| #7432 | AC-4 | same run; U5 limb 3: the must-not-flag arm at `--surface=both` **and** at a `--since` instant | denominator reads "(release, id) pairs"; the must-not-flag arm is 0 at both parameters |
| #4219 | AC-1 | `bash release/tools/compute-front-cluster-telemetry.sh --self-test` with a new arm: a stage-4 `decision/delegation` row with subject `sub-task:#N` | plan-survival stays `0.5` · control: the same arm on the pre-fix `:221` filter → `0.67` (RED) |
| #4219 | AC-2 | `bash release/tools/append-pipeline-event.sh --self-test` with a new arm emitting stage-4 `delegation` with subject `sub-task:#N` | non-zero exit, no row · control: subject `milestone:#N` → accepted |
| #4219 | AC-3 | `grep -n 'milestone:#N' release/references/standards/pipeline-event-log-schema.md` near `:248`, and read `phase-telemetry-front-cluster.md:123` | both name the enforcing validator and the subtype exclusion |
| #5245 | AC-1 | `bash core/deploy/deploy.sh --check-close-completeness` | `(l)` arm row named, in-scope ≥ 1 · control: `CLOSE_COMPLETENESS_TELEMETRY_CUTOFF=__none__` → re-dormant line, 0 in scope |
| #5245 | AC-2 | same run, plus a `deploy.sh --self-test` pre-anchor fixture row without the field | 0 `(l)` findings · control: a post-anchor fixture row missing the field → exactly 1 finding |
| #5245 | AC-3 | same run output | denominator (in-scope VERIFIED rows) printed |
| #5245 | AC-4 | read the anchor definition, plus a self-test arm in which a sibling claims the next version slot | anchor and armed row unchanged |
| #5553 | AC-1 | `bash release/tools/compute-cycle-time.sh one-system-of-record-per-element --iso 2>&1` | computed, or an N/A naming the excluded subtype. The phrase `did not succeed` count = 0 · control: CT-2 escalated-row fixture still yields the failed-targets reason (count ≥ 1) |
| #5553 | AC-2 | re-run over the 9 recorded live occasions (5 package-only + 4 rules-mirror-only) | 9 of 9 carry the correct verdict · control: the 24 releases with eligible rows are unchanged |
| #5553 | AC-3 | `bash release/tools/compute-cycle-time.sh --self-test` (CT-3/CT-3b updated per D5553 — rendered (B), so they stay as shipped and arms CR-1 and CR-2 carry the package-only vs skill-bearing discrimination) | package-only and skill-bearing verdicts differ |
| #5553 | AC-4 | `grep -n 'near-impossible' release/tools/compute-cycle-time.sh core/deploy/deploy.sh` — expect 0 after the fix | 0 · control: at `8e0ee084` the same probe → 2 (both holders; still 2 at the branch base) |
| #5467 | AC-1 | `bash release/tools/compute-cycle-time.sh hub-spoke-execution-safety --iso` and `bash release/tools/compute-cycle-time.sh release-bundle-and-sequence-gates --iso` | `T_GO=2026-08-08T03:50:14Z; … delta=46056s` and `T_GO=2026-08-04T22:54:26Z; T_DEPLOY=2026-08-04T23:22:59Z; delta=1713s` (171046 s at the pin) · the full replay reads 21 computing releases: 4 change, 17 are unchanged, and 4 carry the new N/A reason |
| #5467 | AC-2 | `bash release/tools/compute-cycle-time.sh --self-test` with a new T_GO group: an earlier hub Stage-7 row and an operator Stage-4 row before an operator Stage-9 row | the Stage-9 ts wins · control: a single-row release is unchanged · RED: the pre-fix MIN picks the earliest |
| #5467 | AC-3 | re-measure the `plan-review-go` actor/stage census at Engineering; read the disposition text | census recorded against 153/105/26/22 at `8e0ee084`; disposition = accepted-historical |
| #5467 | AC-4 | `grep -n 'plan-review-go' release/references/pipeline/stage-09-plan-review.md release/skills/release-hub/references/orchestration-playbook.md release/references/standards/pipeline-event-log-schema.md release/references/standards/deployment-cycle-time.md` + `bash release/tools/append-pipeline-event.sh --self-test` | each surface states Stage 9 + operator; subtype set unchanged; self-test PASS |
| #6252 | AC-1 | `grep -n 'append-pipeline-event' release/references/pipeline/stage-09-plan-review.md`. Behavioural: PRE/POST `query-pipeline-event.sh --release <slug> --event-type gate-outcome --event-subtype plan-review-go --stage 9 --count` at the **next** release's Stage 9 | ≥ 1 binding line; POST = PRE + 1 `[behavioural arm deferred — reflexive loop: this release's own Stage 9 runs the pre-merge procedure]` |
| #6252 | AC-2 | `bash release/tools/automated-closeout.sh --self-test` with a missing-anchor fixture (under S-B the close-out's own surfaces carry the line: the chore-PR `## Cycle time` block, the report and the JSON — group CY) | the Cycle-Time line names the missing anchor with the tool's reason · control: a computed fixture → plain value |
| #6252 | AC-3 | `[DEFERRED — the rates can only fall over releases that close after merge]` three counts over post-cutover VERIFIED releases, re-baselined at Stage 4 and extended at the scope-lock: no T_GO anchor as `compute-cycle-time.sh` resolves it; no `plan-review-go` row of any identity (the Check-61 rate); no (stage 9, operator) row | baseline 9/77, 10/77 and 11/77 at `1c3f17db` (the Check-61 rate equals the Stage-4 pin's 10/77); v4.0 is named as a miss only the detector sees (a join-key artifact) |
| #6252 | AC-4 | re-graded on the live counterexample: `grep -c 'deployment-status' release/tools/automated-closeout.sh` — expect 0 (this card adds no emitter); and `bash release/tools/compute-cycle-time.sh hub-spoke-run-and-planning-discipline --iso`, read against that release's own owed-but-not-performed propagation record | 0 · control: `grep -c 'event-subtype'` on the same file → 6 · the counterexample is recorded, not passed: hand-emitted `deploy-skill` rows anchor a value for a release whose propagation was never performed, so the criterion is graded on the property this card owns (it adds no emitter) — the grade REINTERPRET-WITH-RATIONALE or FLAG-UPSTREAM is Stage 8's (DEV-14) |

**AC baseline** (re-read at Commit 0; the Stage-4 baseline was read at `8e0ee084`, before the gate's Tier-1 body edits authored #4219's three criteria — the other six counts are unchanged):

`ac_baseline: { #4219: 3, #5245: 4, #5467: 4, #5553: 4, #5586: 4, #6252: 4, #7432: 4, read_at: 35dbf418 }`

#5586's criteria are an ordered list; its ordinals bind the same way.

### Release-Level Verification

- [ ] Runtime suites per `release/references/standards/runtime-suite-selection-map.md`: row 4 — `python3 release/tools/check-selftest-coverage.py --run` (every edited `release/tools/*`); row 2 — the deploy suite, for `core/deploy/deploy.sh`; row 6 — suite-skip for the stage and standard text
- [ ] `bash core/deploy/deploy.sh --self-test` (groups DE, DS and close-completeness, including OS-17b and OS-22..OS-24)
- [ ] `bash release/tools/tests/test_close_class_telemetry.sh` — the smoke workflow's close-class step, with GROUP E
- [ ] Skill-package freshness after each sanctioned session: `bash core/deploy/deploy.sh --check-package-freshness` (Check 7)
- [ ] CIAC-1..CIAC-5 (CIAC-6 is void)
- [ ] Design artifacts: each row of § Tier-A Activated Design Artifacts carries its embedded declaration marker, and every path it depicts resolves

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#5467 × #6252 on the T_GO identity):** the (stage, actor, subtype) identity that `compute-cycle-time.sh` selects as T_GO equals the identity instructed by the Stage-9 emission step, declared by the EMISSION-CONTRACT `stage-9-go` row and stated by the schema constraint. *Shared surface:* `compute-cycle-time.sh` T_GO selector · `stage-09-plan-review.md` GO step + §11 · `orchestration-playbook.md` EMISSION-CONTRACT · `pipeline-event-log-schema.md`. *Method:* `bash release/tools/compute-cycle-time.sh --self-test` (T_GO identity group PASS) and `bash release/tools/compute-cycle-time.sh hub-spoke-execution-safety --iso` → `T_GO=2026-08-08T03:50:14Z` (control at `8e0ee084`: `2026-08-07T05:59:47Z`), plus `grep -n 'plan-review-go' release/references/pipeline/stage-09-plan-review.md release/references/standards/pipeline-event-log-schema.md release/skills/release-hub/references/orchestration-playbook.md` → each names Stage 9 and `operator`. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5553 × #5467 × #6252 on the N/A-reason channel):** every N/A cause is one distinct reason, emitted once by `compute-cycle-time.sh`. `automated-closeout.sh` carries that reason verbatim into every surface it writes (report, JSON, chore-PR body) and reports whether the Deployment-Log `**Cycle-Time:**` line — authored from the tool's own line per `deployment-cycle-time.md` § 3.1 — carries it. No release whose deploy rows are all `resolved` is called "did not succeed". *Shared surface:* `compute-cycle-time.sh:344-368` · `automated-closeout.sh` `read_state` · `deployment-cycle-time.md` § 3.1 · the Deployment-Log `**Cycle-Time:**` line. *Method:* `bash release/tools/compute-cycle-time.sh one-system-of-record-per-element --iso 2>&1 | grep -c 'did not succeed'` → 0 · control: the CT-2 escalated-row arm of `bash release/tools/compute-cycle-time.sh --self-test` still emits the failed-targets reason; and `bash release/tools/automated-closeout.sh --self-test` (missing-anchor fixture) PASS. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#4219 × #5467 × #7432 on the schema's machine-read surfaces):** after every schema edit, the writer derives the same event-type and subtype enum (no phantom subtype from a backticked §3 col-3 token), `integrity_cutover:` stays one single-line key, both consumers' self-tests pass, and the writer carries exactly one row-identity validator, which #5467's arm extends rather than duplicates. *Shared surface:* `pipeline-event-log-schema.md` §3 table · §4.1 key · §11.8.1 registry; `append-pipeline-event.sh` `validate_row_identity`; `check-event-record-integrity.sh`. *Method:* `bash release/tools/append-pipeline-event.sh --self-test` → PASS (it asserts its fallback against the schema table) · `bash release/tools/check-event-record-integrity.sh --self-test` → PASS · `grep -c '^integrity_cutover:' release/references/standards/pipeline-event-log-schema.md` → 1 · `grep -c '^validate_row_identity() {' release/tools/append-pipeline-event.sh` → 1. The "no phantom subtype" part is a null claim, so it carries a control: `bash release/tools/append-pipeline-event.sh --dry-run` with a bogus subtype must be rejected (non-zero). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#5586 × #5245 on the Close-Class-Telemetry field):** with `(l)` armed at the `v4.55` anchor (frozen at the scope-lock) and #5586's caller-omission value in place, `deploy.sh --check-close-completeness` reports 0 unnamed `(l)` findings plus its denominator over the in-scope rows — a finding that lands between the scope-lock and the merge is recorded as a named, accepted finding, never a re-anchor. A row carrying the new caller-omission value in every rate slot is still flagged by l-3a — the new value is N/A-class to the gate, never a ratio. *Shared surface:* the field's value domain (`compute-close-class-telemetry.sh`) · `deploy.sh` Check 48 `(l)` l-3/l-3a · the `cc_telemetry_cutoff` seam. *Method:* `bash core/deploy/deploy.sh --check-close-completeness` → 0 unnamed `(l)` findings, denominator ≥ 1 · control: the `bash core/deploy/deploy.sh --self-test` l-3a arm with the new value in every slot (OS-17b) → exactly 1 finding. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#5586 × #6252 × #5245 on `automated-closeout.sh` integration):** the close-out self-test passes with all three changes integrated. That includes the Test 15 m* arms, which read the now-armed seam line. *Shared surface:* `automated-closeout.sh` phase 6.8 · `read_state` · `_resolve_telemetry_cutoff`. *Method:* `bash release/tools/automated-closeout.sh --self-test` → exit 0 · control: the existing m1 sensitivity arm (`automated-closeout.sh:15151`) fails if the seam's line shape changes. *Graded at Stage 9 QC3.5 on the merged PR.*

**Void criterion:** the sixth Stage-4 criterion (#4741 × #6252 × #5586 on the close-out record) was `CONDITIONAL:D-Scope-keep-all`; its condition resolved false at the Stage-4 gate (#4741 left the milestone), so it is void and not graded (DEV-9).

**Population enumerated** for cross-issue cohesion: shared file, shared function or seam, shared test harness, shared record schema, shared doc surface. All five live CIACs sit inside the seven cards.

---

## Quota Budget

**Verdict:** **WARN** (option B, the rendered composition), per `quota-budget-protocol.md` Checkpoint A, recorded at Stage 4; keep-all read FAIL and was not taken.
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 7 designs + 7 adversarial reviews (+ #4219's delta design and its review, re-opened at the scope-lock) · Stage 7: 7 · Stage 8: 7.
**Per-spoke cost estimate:** size-bucket ordinal band — `size:S` lowest (#4219, #5245, #5553), `size:M` low–moderate (#5467, #5586, #6252, #7432). Source: heuristic, plus the one recorded absolute datum — about 5% of a 5-hour window per full-depth spoke and about 2.3% per compact reviewer `[INFERRED; single datum; CALIBRATE-AFTER-3]` — treated as floors, because the design spokes read scripts of 20k and 16k lines.
**Assumed/stated remaining usage-window envelope:** UNSTATED at hub start → conservative default (`W_max` = 2).
**Estimated cumulative draw % (worst parallel batch — Stage 5):** ≈ 51%; Stages 7 and 8 ≈ 35% each.
**Routing:** WARN → window-aware launch timing. Stage 6 is serial (P0).
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary, rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API axis at runtime (§ 4.3b); Checkpoint A stays usage-window-only. The bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`cross-cutting`** — re-classified from `novel` at the Collective Review scope-lock (operator, 2026-09-25). Trigger (a) fires: the File Change Matrix declares changes to four `pipeline/stage-*.md` files — `stage-04-planning.md` (#4219's per-issue Stage-4 emission), `stage-09-plan-review.md` (#6252's Phase C1), `stage-12-execute.md` (#6252's C-S) and `stage-13-close.md` (#6252's C-R) — and multi-trigger resolution picks it over `novel`'s trigger (b). Trigger (a) still fires on the three unconditional stage files should the delta design not take `stage-04-planning.md`.

- **Differentiation posture:** Engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.
- **Size bound:** `effective_pts: raw 22 × 1.3 = 29 — split (> 25; accepted by operator override at the Collective Review scope-lock, deviation logged) vs band 15-25`. The recompute is refreshed when #4219's delta design re-assesses its size (DEV-2).
- **History:** `routine` (as bundled) → `novel` (Stage-4 gate, D-ReleaseClass) → `cross-cutting` (scope-lock).

---

## Release Outcome Statement

The operator-approved statement, verbatim from the milestone description:

**AFTER** — Every telemetry value the pipeline computes from its event log — cycle time, plan survival, the close-class indicators and the action-item integrity join — reads either a correctly computed value or an explicit N/A that names its reason. Each selects its rows by full identity (stage, actor, subtype, release), and the close-class telemetry gate asserts over real rows instead of shipping inert.

**BEFORE** — Several of those values are wrong and nothing flags it: cycle time inflates up to 40× when a non-Stage-9 row carries the GO subtype, package- and rules-mirror-only deploys read as "targets did not succeed", and three close-class indicators read N/A on every release. Plan survival counts delegation rows, the integrity join hides a stale action item whenever two releases share its id, and the telemetry gate is armed against nothing.

**Success Indicator:** Replaying the event log at merge yields the three inflated cycle times at their Stage-9-anchored values, correct verdicts for the nine misreported deploying releases, and computed close-class indicators 1, 2 and 5 on a close with a learnings register present — each paired with its control arm.

The residuals the AFTER statement names but this release does not cover are disclosed in § Stage 9 Disclosures; the Success Indicator's count is reconciled with the replay in DEV-17.

---

## Evidence Grounding

**Identifier-level override (Collective Review scope-lock, operator, 2026-09-25).** The identifier-naming BLOCKs in all seven Stage-5 designs are overridden: the names are new within each card's own namespace and join no shared scheme. Two grounding entries are required at Commit 0, and follow.

### Canonicalization: #5467's T_GO N/A reason string

**Current-state enumeration:**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| `compute-cycle-time.sh` — T_GO, no GO row at all | `no gate-outcome/plan-review-go event for $VERSION` | 1 emitter line | `release/tools/compute-cycle-time.sh:353` |
| `compute-cycle-time.sh` — T_DEPLOY, rows exist but none eligible (the sibling shape) | `<n> deployment-status row(s) exist for $VERSION but NONE is an anchor-eligible …` | 1 | `:356` |
| `compute-cycle-time.sh` — T_DEPLOY, no row | `no deployment-status/deploy-skill or deploy-harness event for $VERSION` | 1 | `:358` |
| the stderr join | `Cycle-Time: N/A (<reasons joined by "; ">)` | 1 | `:361` |
| the release records (hand-copied field text) | the no-GO reason quoted in Cycle-Time fields | 32 lines in 5 ledger files | `RELEASE_LOG.md` and four archive segments |
| the design's new identity-miss reason (the design on #7736, change 1f) | `<n> gate-outcome/plan-review-go row(s) exist for $VERSION but NONE is the Stage-9 GO anchor (stage 9, actor operator) …` | 0 (new) | the survey below |

**Survey command:** `git grep -n -F 'no gate-outcome/plan-review-go event for' -- ':!release/releases/**'` · `git grep -n -F 'but NONE is' -- ':!release/releases/**'` · `git grep -c -F 'NONE is the Stage-9 GO anchor'`
**Survey date:** 2026-09-25 at commit `35dbf418`
**Survey denominator:** 1,573 tracked files outside `release/releases/` (`git ls-files -- ':!release/releases/**'`); 33 lines tree-wide carry the no-GO reason, 32 of them in release records
**Survey control:** `'but NONE is'` outside the release records → observed 1 (`:356`), so the survey sees the sibling shape; the new token → 0 tree-wide

**Canonical choice:** the design's identity-miss reason, factored into `t_go_na_reason` beside `go_anchor_ts` and graded by group CG (scope-lock decision 3; review #7885 FM-3). It takes the sibling `:356` shape — count, subtype, "but NONE is", the identity — and the no-rows reason at `:353` stays byte-for-byte. Neither carries a pipe character, an internal `; ` or the phrase "did not succeed". The slice may word the miss as an observed fact under the tool's join keys (review FM-3) within that shape.

**Canonical-choice justification** (documented rationale): CIAC-2 (every N/A cause is one distinct reason, emitted once by the tool); the tool's own rule that its N/A causes are different facts (the comment above `:353`); the sibling precedent at `:356`.

**Out-of-scope drift detected during survey:** the release records hold the no-GO reason as hand-copied field text (32 lines) — historical, never rewritten (release-wide non-scope; accepted residual). Downstream, the Deployment-Log field is hand-authored by the Stage-12 author; #6252's § 3.1 verbatim rule and C-S govern it (in this release).

### Canonicalization: #6252's CONFORMANT / DIVERGENT field-verdict vocabulary

**Current-state enumeration:**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the mirror-pair parity check | the verdict set PARITY · DIVERGENT · UNPARSEABLE · NOT-EVALUATED | 1 verdict set | `core/deploy/tools/check-mirror-pair-parity.py:81` |
| the decision-confidence protocol | CONVERGENT · DIVERGENT · UNGROUNDED | 1 | `core/specs/decision-confidence-protocol.md` (`:67` names `CONVERGENT`) |
| the hook-refresh discriminator | DIVERGENT as a verdict member | 1 | `core/ADRs/ADR-203-hook-refresh-discriminator-composition.md`; `core/deploy/deploy.sh` |
| `DIVERGENT`, whole word, outside release records | — | 14 files / 49 lines | the survey below |
| `CONFORMANT`, whole word, same scope | prose and test labels, and the close-out's field-key vocabulary ("NON-CONFORMANT qualified Outcome key") | 9 files / 26 lines | the survey; `release/tools/automated-closeout.sh:2521` |
| `ABSENT` | a field-key resolver class (CANONICAL · QUALIFIED · UNPARSEABLE · DUPLICATE · ABSENT · UNREADABLE) | 1 resolver | `automated-closeout.sh:2374` |
| `NOT-EVALUATED` | the PV-7a Register B token with its mandated clause | 1 closed set | `core/disciplines/review-discipline-principles.md` § 8 (`:486`, `:488`) |

**Survey command:** `git grep -c -w -F 'DIVERGENT' -- ':!release/releases/**'` and the same for `CONFORMANT`
**Survey date:** 2026-09-25 at commit `35dbf418`
**Survey denominator:** 1,573 tracked files outside `release/releases/`
**Survey control:** the DIVERGENT verdict member at `check-mirror-pair-parity.py:81` → observed (the probe reads it); the disagreement wording review #7886 PR-1 prescribes (`the field and the tool …`) → 0 tree-wide (new)

**Canonical choice:** the close-out's read-only Cycle-Time field verdict is `CONFORMANT` · `DIVERGENT` · `ABSENT` · `NOT-EVALUATED`. DIVERGENT is worded as a disagreement between the field and the tool's current value, carrying the tool's `--iso` anchors (PR-1); ABSENT reuses the resolver's class; NOT-EVALUATED is the PV-7a token.

**Canonical-choice justification** (documented rationale): reuse of shipped vocabularies — DIVERGENT is an established verdict member in three surfaces, ABSENT is the resolver's own class, NOT-EVALUATED is PV-7a's closed Register B set — and the design on #7737, Canonicalization 2.

**Out-of-scope drift detected during survey:** DIVERGENT's pair partner varies across surfaces — PARITY in the mirror-pair check, CONVERGENT in the decision-confidence protocol, CONFORMANT here. Accepted residual under the identifier-level override above: the name is new within the card's own namespace and joins no shared scheme.

---

## Tier-A Activated Design Artifacts

Scope-lock decision 5 reads the data-flow trigger of `core/standards/design-artifact-standard.md` § 7 as "a modified schema or output-format file with cross-component flow activates it". #4219 declares its artifact at Commit 0; #5586, #7432 and #5553 are re-checked here under that reading; #5467 and #6252 are as designed; #5245 is as designed (checked, not activated). A declaration names its marker in prose rather than reproducing it, so this file is never counted as a marker's host.

| Card | Artifact path | Flow class | Trigger | Tier | G-CL6 obligation |
|---|---|---|---|---|---|
| #4219 | `release/references/standards/pipeline-event-log-schema.md` § 3 — the stage-4 `delegation` identity paragraph (embedded; its declaration marker, flow class `data-flow`, depicting `release/tools/append-pipeline-event.sh` and `release/tools/compute-front-cluster-telemetry.sh`, is authored in slice 3) | data-flow | #4219 modifies a schema file with cross-component flow: the hub's hand-emitted delegation rows and the scripted emitters → the writer's `validate_row_identity` → the append-only log → I6, the query tool and the integrity checker (review #7873 PR-4, adopted) | A — new; declared at Commit 0; the delta design may widen what it depicts to `stage-04-planning.md` § 11 | Stage 13 G-CL6 confirms the embedded artifact exists with its marker, is non-trivially changed on the branch and depicts only resolving paths |
| #5586 | `release/references/standards/close-class-telemetry.md` — the register-fed slots' states (embedded, authored in slice 1 in a region #6892 does not edit — § 5 rather than § 3.2; flow class `data-flow`, depicting `release/tools/compute-close-class-telemetry.sh`, `release/tools/automated-closeout.sh` and `core/deploy/deploy.sh`) | data-flow | **Re-check: ACTIVATES.** #5586 modifies an output-format standard — the `**Close-Class-Telemetry:**` field's value domain — whose value crosses components: the tool emits it → phase 6.8 writes and dispositions it → the RELEASE_LOG field → Check 48 l-3 / l-3a grade it. The design recorded "not activated" under the earlier reading | A — new | as above |
| #5553 | — (depicted by the two `deployment-cycle-time.md` artifacts below) | data-flow | **Re-check: ACTIVATES, discharged without a third artifact (DEV-13).** #5553 modifies an output-format standard with cross-component flow; its § 2.1 edit sits inside #5467's § 2 anchor-identity region (§ 2 through § 2.2), and its § 4 cause table is the reason vocabulary #6252's § 3.1 carriage table carries | B — refresh of the two artifacts | both artifacts' refresh obligations count #5553's edits |
| #7432 | — | — | **Re-check: NOT ACTIVATED** under the decision record's "output-format **file**" reading: its only non-fixture file is a producer tool, the schema is not edited, the fixtures are test-only (Tier-C), and the close-gate sentence that documents its key form lands in #6252's playbook session. The rendered block on #7739 words the trigger "a modified output format"; the decision record governs (DEV-13) | — | — |
| #5467 | `release/references/standards/deployment-cycle-time.md` § 2 — the anchor-identity artifact (a marker on the existing producer→consumer table; its region runs through § 2.2) | data-flow | Modifies a schema file and a contract standard with cross-component flow: the Stage-9 GO producer → the writer gate → the log → the T_GO reader, Check 61 and the close-out | A — an existing table, declared | Stage 13: the region is touched by more than 3 lines (#5467 and #5553 both edit § 2) |
| #6252 | `release/references/pipeline/stage-09-plan-review.md` Phase C1 — the Stage-9 verdict-recording Mermaid flow | agent-process | ≥ 2 actors and a gate (the read-back) | A — new | refresh when Phase C1 changes |
| #6252 | `release/references/standards/deployment-cycle-time.md` § 3.1 — the N/A-reason carriage table | data-flow | An output-format standard with ≥ 2 producer / consumer entities | A — new | refresh when the carriage changes |
| #5245 | — | — | As designed: checked, not activated (a cutover value, comments and test arms; no schema, contract or output-format file) | — | — |

**Existing artifacts in the write set.** Two embedded artifacts already live in `release/references/pipeline/stage-13-close.md` — the close-class resolution decision tree (`:126`) and the Layer-1 dual-write emit sequence (`:330`, which also depicts `stage-12-execute.md`). #6252's C-R edit (`stage-13-close.md:173`, the Check 61 remedy text) and C-S edit (`stage-12-execute.md:129`, `:133`, the Cycle-Time template line) change content neither artifact depicts, so no Tier-B refresh is owed by them `[INFERRED — read of both artifacts at the branch base; slice 7 re-checks the declared regions when it edits]`.

---

## Rollback Strategy

| Issue | Rollback Method | Rollback Complexity |
|---|---|---|
| #4219, #5467 (the writer arms) | `git revert` the slice | CHEAP. Rows the gate refused were never written; rows written meanwhile stay (append-only, harmless) |
| #5245 | `git revert`; the latch returns to `__none__` (or `=__none__` at runtime) | CHEAP |
| #5553, #5586, #7432 | `git revert` the slice | CHEAP (read-models, one disposition block, tests; no data mutation) |
| #6252 | `git revert`; the binding returns to playbook-only; C-S and C-R are text | CHEAP. Emitted rows stay |
| Whole release | `git revert -m 1 <merge>`, then redeploy `release-hub` | MODERATE. The claimed version tag is **retained and recorded**, never deleted (tag retention); the armed `(l)` gate's findings on rows closed meanwhile stay as records |

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `release/skills/release-hub/` (the playbook) + `packages/release-hub.skill` | the user-local skills mirror + the Cowork install | `./deploy.sh --deploy release-hub --release telemetry-is-computable` | `./deploy.sh --check` Checks 1/2/7/12/13 green for `release-hub` |
| 2 | `release/tools/*`, `core/deploy/deploy.sh` | none (repository-resident) | merge | Stage-12 `deploy.sh --check`; the Check 48 `(l)` arm line reads armed at LOG row `v4.55` |

**Repository-only surfaces** (no deployed copy to sync): the four stage specs, the four standards, the fixtures, the regression suite and `.github/workflows/release-tooling-smoke.yml` (CI).

**`deliverable_state: deployed-copy-synced`** — reached at Stage 12 when row 1 verifies by content.

### Schema Migrations

N/A — enumerated over {event-log columns, the subtype enum, the payload registries, the RELEASE_LOG field grammar}; none changes shape: #5586's new value fits the existing `.+` slot grammar, #4219's and #5467's rules are convention blocks with no enum change, and #7432's keys are report-side.

---

## Stage 9 Disclosures

The AFTER statement's residuals that this release does not cover (scope-lock decision 10), stated so the Stage-9 goal-conformance check (A7) reads them as disclosed, not missed.

| # | Residual | What stays true after merge | Source |
|---|---|---|---|
| 1 | **I1 / I4** (front cluster) | Both are computed on `g1-g2` gate-outcome rows written off their Stage-2 home (15 of 15 in the 30 days to the review), so neither measures triage | review #7885 FM-1 and CD-1 (the per-subtype home-stage table, routed to the next telemetry slice) |
| 2 | **I22 / I24 and the decision-outcome join** | They read `plan-review-go` by subtype alone (`compute-middle-cluster-telemetry.sh:178-196`; `decision-outcome-tracking.md:149-153`); #5467's writer arm stops new pollution, but the 48 historical rows still count | the design on #7736, F9 |
| 3 | **T_DEPLOY's hand-written note anchors** | Release-level completion notes typed `deploy-skill` still anchor T_DEPLOY (7 of 21 computing values; 43 of 56 hand-written `deployment-status` rows are release-level markers). No card here refuses one | the design on #7735, Finding 8; reviews #7875 PR-1, #7885 FM-1, #7886 PR-1 (R-b routed) |
| 4 | **Hook-tier deploys** | A release whose deploy reached the runtime through the hook refresh or composition surfaces emits no `deployment-status` row, so it has no T_DEPLOY anchor and is missing from DORA's frequency — the subtype enum has no member for either target (`egress-hook-batch`, `v4.69`, is the live instance) | review #7875 PR-3 (iv); the owner's 2026-09-25 sibling-evidence comment on #6252 |
| 5 | **Indicator 3** (`carry_forward_closure_rate`) | Its unmeasured states still render in the clean-absence register: a failed read reads as a genuine zero | review #7871 FM-5 (routed to intake) |

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **N2 override (verbatim):** "**Override:** convention PV-7 `NOT-EVALUATED` wording accepted as diverged because the divergent text ships in ms#395's scope-locked release; the relay asks them to align. Deviation logged for Stage 13 retrospective." | Collective Review scope-lock, N-way table row N2 | **RECORDED** — for the Stage 13 retrospective |
| **DEV-2** | **Band override:** under `cross-cutting` the size reads `effective_pts: raw 22 × 1.3 = 29`, over the 15–25 band (> 25: split); the operator accepted it at the scope-lock. #4219's delta design re-assesses its size and the recompute is refreshed then | Collective Review scope-lock (overrides); the re-classification record | **RECORDED** — for the Stage 13 retrospective |
| **DEV-3** | **Evidence-grounding override:** the identifier-naming BLOCKs in all seven designs are overridden (names new within each card's namespace, joining no shared scheme); grounding entries for #5467's T_GO reason string and #6252's CONFORMANT/DIVERGENT vocabulary are required at Commit 0 | Collective Review scope-lock (overrides) | **APPLIED** — § Evidence Grounding |
| **DEV-4** | **Re-classification `novel` → `cross-cutting`** (trigger (a): four stage files) | The re-classification record on #7681 | **APPLIED** — § Release Class declaration |
| **DEV-5** | **D-Version re-render `v4.69` → `v4.70`** at Engineering entry (`egress-hook-batch` claimed `v4.69`); the Commit-0 version half re-verified `v4.70` free and equal to next-free | The D-Version re-render record on #7681 | **APPLIED** — § Commit-0 Version Re-Verify Record |
| **DEV-6** | **Phase A6.5 review of #5586's design** — review #7871, comment 5830791935. Majors PR-1 and FM-2 dispositioned by scope-lock decision 1 (FM-2's relay posted under decision 13). Minor findings: FM-1 with CD-1, FM-3, FM-4, FM-5 | Scope-lock decision 1 | **ADOPTED** — FM-1/CD-1 and FM-3 in slice 1; FM-4 through AC-4's wording (slice 1); FM-5 whole: item 12's wording (slice 1) and the `deploy.sh:1826` twin (slice 4). **ROUTED → intake at Stage 13:** FM-5's Indicator-3 class (also Stage 9 disclosure 5), and FM-2(c)'s `stage-13-close.md:68` count re-route. The rendered block on #7738 names only FM-5's item-12 wording; the decision record adopts FM-5 whole and governs |
| **DEV-7** | **Phase A6.5 review of #7432's design** — review #7872, comment 5831069228. Major FM-1/CD-1 dispositioned by decision 9. Minor findings: PR-1, PR-2, FM-2, FM-3, FM-4, CD-2 | Scope-lock decisions 4, 9 and 13 | **ADOPTED:** FM-3 and FM-4 in slice 2; PR-1 decided by decision 4 (the close-gate sentence, slice 7). **RELAYED:** PR-2 to #6205; FM-2 with CD-2 to #6872 |
| **DEV-8** | **Phase A6.5 review of #4219's design** — review #7873, comment 5831290249. Majors PR-1, PR-2, CD-1 and CD-2 (and FM-1's clause) dispositioned by decisions 10 and 11 into the delta design on #7896. Minor findings: PR-3, PR-4 | Scope-lock decisions 5, 10 and 11 | **ADOPTED:** PR-4, as the Tier-A declaration at Commit 0. **ROUTED → intake at Stage 13:** PR-3 — the scope-lock rendered no in-slice disposition for it; if slice 3 reconciles it while editing that tool's header, the slice records it absorbed |
| **DEV-9** | **`CONDITIONAL:D-Scope-keep-all` — NOT DELIVERED.** Every Stage-4 row for #4228, #4741, #4742 and #5193 (the `D-Scope-keep-all` rows and their `D4741-taxonomy`, `D4741-tool`, `D4742-rubric-pointer` and `D4228-adr-edit` rows — among them the conditional ADDs `core/skills/pmo-qa-auditor/evals/*surface-selection*` and `release/tools/outcome-window-*.sh`) and the sixth criterion. The condition resolved false at the Stage-4 gate (D-Scope B): the four cards left the milestone | The Stage-4 plan-gate record (D-Scope) | **RECORDED** — the rows are not transcribed into § File Change Matrix; their verification rows and the criterion are void |
| **DEV-10** | **`CONDITIONAL:D5553-admit` (2 rows) and `CONDITIONAL:D6252-widen` (3 rows) — NOT DELIVERED.** D5553-admit resolved false at the scope-lock (B: name, do not admit), so `release/tools/compute-dora-metrics.sh` and `release/references/standards/dora-telemetry.md` are untouched; D6252-widen resolved false at the Stage-4 gate (D-6252-Scope a; the sibling card #7730), so `stage-07-dev-testing.md`, `stage-08-qa-testing.md` and `hub-spoke-bridge.md` are untouched | Scope-lock decision 6; the Stage-4 plan-gate record | **RECORDED** |
| **DEV-11** | **Phase A6.5 review of #5553's design** — review #7875, comment 5831514696. Major PR-1/CD-1 dispositioned by decision 6. Minor findings: PR-2, PR-3, FM-1, FM-2, CD-2 | Scope-lock decisions 3 and 6 | **ADOPTED at Commit 0:** PR-2 and PR-3 (i)–(iii) as slice 5's change-specification wording. **ADOPTED in slice 5:** FM-1 (the `:330` exit check with its empty-evals arm) and FM-2 (the CR-9 DORA parity arm). **ROUTED → intake at Stage 13:** CD-2 with F6; PR-3 (iv), the hook-tier and composition-surface emission gap (also Stage 9 disclosure 4) |
| **DEV-12a** | **Phase A6.5 review of #5245's design** — review #7874, comment 5831451771. Findings PR-1, FM-1 and CD-1, each Minor (aggregate Minor) | Scope-lock decisions 8 and 13 | **ADOPTED:** FM-1's three wording fixes and CD-1 (the `v4.55` anchor, frozen at the scope-lock) in slice 4. **RELAYED:** PR-1's reworded R3 relay to ms#395 and ms#334 (decision 13; its Lane-1 restatement is carried in R8) |
| **DEV-12b** | **Phase A6.5 review of #5467's design** — review #7885, comment 5831764850. Majors PR-1 and FM-1 dispositioned by decision 7. Below Major: PR-2 and CD-1 (Minor), FM-2 and FM-3 (no severity stated; not among the review's two Majors) | Scope-lock decisions 3 and 7 | **ADOPTED in slice 6:** PR-2 (item 4b points at `hub-session-continuity.md` § 3.2), FM-2 (the refusal message opens with provenance — decision 7) and FM-3 (`t_go_na_reason` with CG arms, and the `:313` exit check — decision 3). **ROUTED → intake at Stage 13:** CD-1, the per-subtype home-stage table (also Stage 9 disclosure 1) |
| **DEV-12c** | **Phase A6.5 review of #6252's design** — review #7886, comment 5834019858. Majors PR-1, PR-2, FM-1 and FM-2 dispositioned by decisions 2, 3, 9 and 12; Major CD-1 not adopted — decision 2 renders S-B, which the review names the safer choice for this release, with CD-1 the end-state once R-b lands. Minor: PR-3, FM-3, FM-4 | Scope-lock decisions 2, 3, 9 and 12 | **ADOPTED in slice 7:** PR-3 (AC-3's three rates), FM-3 and FM-4 (decision 2). **ROUTED → intake at Stage 13:** R-a (the `hub-session-continuity.md` precedence note and `:172`, outside the write set) and R-b (keeping release-level markers off the anchor subtypes; Stage 9 disclosure 3). CD-1 is recorded here, not routed on its own: the review makes it adoptable only once R-b lands |
| **DEV-13** | **Tier-A re-check readings.** (a) #7432: the rendered block on #7739 words the trigger "a modified output format with cross-component flow"; the decision record reads "a modified schema or output-format **file**". Applied the decision record — not activated; if the looser reading is intended, the natural host is the close-gate sentence in #6252's playbook session. (b) #5553: activates, and is discharged by the two artifacts #5467 and #6252 declare over the same file rather than by a third artifact | The brief's precedence rule (the decision record over a rendered block) | **RECORDED** — surfaced to the hub |
| **DEV-14** | **#6252 AC-4's grade.** The scope-lock re-grades AC-4 "on the live counterexample" but names neither of the review's two admissible grades (FLAG-UPSTREAM, or REINTERPRET-WITH-RATIONALE scoped to "this card adds no emitter"). The row records the counterexample and leaves the grade to Stage 8 | Scope-lock decision 9; review #7886 PR-1 | **RECORDED** — surfaced to the hub |
| **DEV-15** | **#5467's F13 — the `release-hub` `SKILL.md` row is not added at Commit 0.** A `version:` bump is the sanctioned editor's call; if slice 6 or 7 bumps it, that slice adds `release/skills/release-hub/SKILL.md` as an EDIT row (Tier 1) and its Mode A commit carries the editor trailer (Check 10) | The design on #7736, F13; the Commit-0 pre-flight | **RECORDED** |
| **DEV-16** | **#5245's anchor sweep** (scope-lock decision 8): in-scope rows / standing `(l)` findings per candidate anchor at `40cec0c7` — `v4.03` 74/23 · `v4.21` 56/5 · `v4.22` 55/4 · `v4.48` 26/4 · `v4.49` 24/3 · `v4.50` 22/2 · `v4.53` 18/1 · `v4.54` 17/1 · **`v4.55` 15/0** · `v4.68` 1/0 · `v4.69` no row. `v4.55` is the oldest cutoff with zero standing findings and prefixes exactly one ledger row; re-measured 15/0 at `1c3f17db`. Frozen at the scope-lock | Scope-lock decision 8 | **RECORDED** |
| **DEV-17** | **The Success Indicator says "the three inflated cycle times"; the replay changes four.** Review #7885 PR-1 found a fourth computing value that changes (`release-bundle-and-sequence-gates`, `v4.07`: 171046 s → 1713 s under the identity selector). The scope-lock adopted the restatement, added the release to #5467's AC-1 and kept the operator's AFTER statement; the Success Indicator is the operator's text and is kept verbatim | Scope-lock decisions 7 and 10 | **RECORDED** — Stage 9 A7 reads the indicator against AC-1's four |
| **DEV-18** | **Verification Plan amendments** (the issue bodies stay historical): #5586 AC-1 removed from this release's grading (a `[DEFERRED]` row keeps its binding), AC-2 graded on a register-present fixture as non-regression, AC-4 reaches the live call sites; #5467 AC-1 adds `release-bundle-and-sequence-gates`; #6252 AC-3 reports three rates (its deferral marker moved into the method cell), and AC-4 is re-graded on the live counterexample. Transcription aids, changing no criterion: two method cells name their rendered decision (#5553 AC-3 under D5553-admit (B); #6252 AC-2 under S-B); the two null-expectation cells (#5553 AC-4, #6252 AC-4) carry the executor's `expect 0` phrasing, so the plan-driven executor grades the count rather than the matcher's exit status | Scope-lock decisions 1, 2, 6, 7 and 9; AC-Binding limb 1 | **APPLIED** — § Verification Plan |
| **DEV-19** | **The Commit-0 pre-flight ran read-only at Commit 0.** #7738's body asks for it ("Run AI-001's pre-flight first"); the Commit-0 brief is silent on it | #7738's body; risk R7 | **RECORDED** — § Commit-0 Version Re-Verify Record → pre-flight |
| **DEV-20** | **C-S line anchor.** The design cites `stage-12-execute.md:131` for the second template line; at the branch base that line (content: "or `N/A` for content-only releases …") is `:133`, as the rendered block on #7744 states | The rendered block on #7744 | **RECORDED** — slice 7 anchors by content |
| **DEV-21** | **Matrix growth beyond the Stage-4 matrix, from the refined designs:** #5586's regression suite and smoke workflow; #5245's `automated-closeout.sh` row (Tier 2); #6252's C-S (`stage-12-execute.md`) and C-R (`deploy.sh`, `stage-13-close.md`); #7432's twelve-file refinement, with its schema row dropped; #4219's three `CONDITIONAL:D4219-delta` rows; #5467's writer row promoted from `CONDITIONAL:D5467-writer-gate` (D5467-identity B) while `CONDITIONAL:D5467-check61` resolved false. The Stage-4 fence label "(unconditional)" is not carried, because the matrix parser reads any label containing "conditional" as a conditional marker | Collective Review scope-lock; the rendered blocks on #7738–#7744 | **APPLIED** — § File Change Matrix |
| **DEV-22** | **Checkpoint B quota override.** Checkpoint B rendered DEFER at the first Stage-6 slice launch (usage-window axis: the weekly window was near its tail), and the operator overrode it to PROCEED for the Stage-6 slices, launched serially at `W_max` 1 until the weekly limit | The operator's quota-budget decision on 2026-09-26, recorded as a stage-6 `decision/d-class` event (`quota-budget-protocol.md` § 4.5 requires an override to be deviation-logged) | **RECORDED** — for the Stage 13 retrospective |
| **DEV-23** | **Slice 1 — where the Not-evaluated emit example sits.** The design (Change 3 item 4) places it after § 3.2's Degraded emit block, where it would abut the § 3.2 emit-mechanism sentence that #6892 rewrites. It sits after the N/A emit instead, the example it contrasts with, so the two releases' edits stay separated by unchanged lines and the later merge re-baselines cleanly | Minor adjustment (Stage 6 B3), under scope-lock decision 1's ownership of that sentence | **APPLIED** — slice-1 commit `5d726d4e` |
| **DEV-24** | **Slice 1 — the A2 container.** § Implementation Sequence names the hub's per-card Stage-6 sub-tasks as the container. Evaluated from slice 1's five matrix rows alone, the Phase A2 predicate selects the GitHub sub-issue container (five file-level units, but multi-file, structure-changing work), so the change units are eight sub-issues under #5586 — the five changes plus the sync, plan-update and verification sub-tasks — each marked closed with its landing SHA, beside the card's stage sub-task #7738 | The slice-1 brief; `stage-06-engineering.md` Phase A2 | **APPLIED** — sub-issues #7911–#7918 |
| **DEV-25** | **Slice 1 — implementation refinements inside the adopted findings.** (a) FM-3's split is `register_path_state` (the only `-f` test) and the pure `register_slot_render`, which refuses a state outside its closed domain; Test 9 asserts the refusal. (b) FM-4's binding arm counts seven bound sites — the five live calls of the two functions and the two emission bindings that carry an unresolved slot into the field — and three pre-fix literals. Its control runs both ways: the call-site mutant reddens only the binding arm while its own `--self-test` stays green, and the resolver mutant reddens only the self-test while the binding arm reads clean. (c) The phase-6.8 omission note names `compute-close-class-telemetry.sh` rather than "the producer", a word the design keeps for the register's own producer (review #7871, cosmetic 4), and it rides the phase's existing detail variable, so no `mark_phase` line changes. (d) Every Test 9 failure message opens `self-test: register-resolution`, which settles the review's cosmetic 2 in favour of the verbatim text E2b greps. (e) Test 4c.6's measured control gains an omission-note specificity check, and arm (d3) carries a floor proving it took the measured path | Minor adjustments (Stage 6 B3), within review #7871 FM-3, FM-4 and CD-1 as scope-lock decision 1 adopts them | **APPLIED** — slice-1 commits `a85f231c` and `f3529dab` |
| **DEV-26** | **Slice 2 — implementation refinements inside the adopted findings.** (a) The fixtures carry rows beyond the design's Changes 2–8 to host the adopted arms: an AI-005 row one column short on `c4-collision-tree/fixture-c4-rel-b`, whose release emitted AI-005 (CD-1), and an AI-006 pair with one row before the self-test's MID cutover and one after, with no row in the collision tree and a `done` row in the control tree (FM-4). The collision log grows from 8 rows to 11, the control log's two appended rows move to `10:00:08Z` and `10:00:09Z` so both logs stay chronological, and the control tree's `fixture-c4-rel-a` AI-001 `resolved_at` moves with them. (b) FM-3's separate line is a report label, `C4c`, with its own denominator line and its own JSON denominator. Every finding line and JSON finding still names the check `C4`, so the close gate's `C4 <release>:…` grouping is unchanged. (c) Under CD-1 the C5 exclusion binds limbs (a) and (b) only. The header's C5-precondition paragraph and the runtime exclusion note now say so, and the note adds that limb (c) still reads those rows' ids (review #7872 CD-1's principal-vs-junior point). (d) The agreeing control and the `--surface=ledger` SKIPPED arm assert both C4 lines: once limb (c) prints on its own line, a false limb-(c) finding no longer moves the ledger-row line. (e) The A2 container, as in DEV-24: sub-issues #7921–#7927 under #7432 | Minor adjustments (Stage 6 B3), within review #7872 CD-1, FM-3 and FM-4 as scope-lock decision 9 adopts them; `stage-06-engineering.md` Phase A2 for (e) | **APPLIED** — slice-2 commits `75ce7445` and `e2d72f93` |

---

## Documentation Impact

| Issue | Declared docs (the body's Documentation Impact field) | Status (as each slice lands) | Lands in |
|---|---|---|---|
| #5586 | `release/references/standards/close-class-telemetry.md` — the value domain gains the caller-omission value | **UPDATED** — v1.03 at `5d726d4e` | slice 1 |
| #7432 | the tool's usage text, if it describes C4's join; no change to the close gate's documented predicate | **UPDATED** at `e2d72f93` — the tool header's Checks block states the (release, id) join, with the legacy rule and limb (c)'s own population and date; the `--help` range (header lines 12–36, usage and flags) does not describe the join and is byte-identical. The close gate's predicate is not edited | slice 2 |
| #4219 | `pipeline-event-log-schema.md` (the delegation MUST cites its enforcer) · `phase-telemetry-front-cluster.md` (the I6 definition) | pending | slice 3 |
| #5245 | none declared — the body carries no Documentation Impact field; the slice edits code comments and test text only | NONE | — |
| #5553 | `deployment-cycle-time.md` (the T_DEPLOY anchor set and its exclusion diagnostic) · `dora-telemetry.md` only if D5553 admitted — it did not | pending | slice 5 |
| #5467 | `deployment-cycle-time.md` (the T_GO definition) · `pipeline-event-log-schema.md` (the convention block) · `orchestration-playbook.md` (the EARLIEST-row note and the stage-local verdict guidance) | pending | slice 6 |
| #6252 | `stage-09-plan-review.md` (the emit step) · `deployment-cycle-time.md` (the stale instrumentation-gap paragraph) | pending | slice 7 |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification, extended at Stages 7, 8 and 12.*

| Check | Result |
|---|---|
| **Commit-0 version half** | Both fetches exit 0; the adapter's dry-run recomputes **`v4.70`** for bump-class `minor` at `35dbf418`; the slot is free on all three claimed-set arms (probe record above). **No HALT** |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp telemetry-is-computable` → **exit 0**, *"verify-stamp OK — telemetry-is-computable carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised"* (its pre-flight: the manifest stales 0 packages). Control: the same verb on a slug with no plan (`telemetry-is-computable-zz`) → exit 1, `NO PRE-CLAIM PLAN`. Exactly one literal placeholder in this file (the Header `**Version**` cell) |
| **Plan-driven executor at Commit 0 (hermetic)** | `release/tools/verify-release-plan.sh --root=<stub> --format=md --stage4-comment <the Stage-4 plan comment, parts 1–3> release/releases/plans/telemetry-is-computable_RELEASE_PLAN.md`, pre-commit, where the stub is a `git archive` of the branch head plus this file, with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` replaced by inert stubs (the deploy stub exits non-zero so no sync row can read PASS). Roll-up: **9 PASS / 3 FAIL / 9 SKIP / 16 ERROR — over 27 per-issue row(s); 2 declared-deferred**; exit 3 |
| **Executor parse** | 27 per-issue records indexed (the AC baseline's 27); 0 `table-unindexable`, 0 `parity-error`, 0 `method-cell-empty`; CIAC-1..CIAC-5 indexed (the void sixth criterion correctly absent); PROV-PRESENCE and PROV-GRAMMAR PASS (Form X, date 2026-09-24). **By construction at Commit 0:** 15 rows whose method is a `bash` tool run or a prose read report `unclassified-method`, and FCM-COVERAGE reports `diff-unresolvable` (the stub has no git history); 1 FAIL is the inert deploy stub (#5245 AC-1 routes to its sync family); 2 FAILs are pre-implementation RED (#6252 AC-1, and #5553 AC-4, which reads 1 on the stub because the inert `deploy.sh` drops the second holder). The PASS rows are presence probes that hold before implementation; none is evidence for a slice |
| **Matrix parse** | The executor's own matrix parser, through its test seam on an out-of-corpus copy of this file with a synthetic delivered set: declared 60 · interpreted 60 · obligations 8 · excluded 14 · conditional ADD 0 · uninterpreted 0 · pathless 0 → FCM-COVERAGE PASS, and the 8 ADD rows each match. Control: the same copy with one row's verb removed → uninterpreted 1 (SKIP) |
| **Survival rows 1–5 (independent read)** | The executor's PROV-DELTA row reads `prov-no-loss`, but on this host it is a **broken probe**: a mutant copy of this file with the stamp placeholder removed also reads `prov-no-loss`, because BSD awk rejects the multi-line `-v have=` value (three `newline in string` errors). Re-derived with the executor's own five patterns, line-wise: the Stage-4 comment carries all 5 elements (label 1 · File Change Matrix 5 · CIAC 14 · Verification Plan 2 · stamp 1) and this file carries all 5 (label 1 · File Change Matrix 11 · CIAC 19 · Verification Plan 7 · stamp 1) — 0 lost |
| **Matrix paths** | 32 distinct paths: the 24 EDIT paths exist at `35dbf418` and the 8 ADD paths are absent (a per-path existence read of the whole list) |
| **Baseline pin** | `8e0ee084..35dbf418`: 35 commits, 18 files, 0 matrix paths (probe record in § Cross-PR Overlap Audit) |
| **In-flight roster** | 2 siblings, both `minor`, both recomputing `v4.70`; EDITSET ∩ FCM = 2 paths (#7895) and 1 conditional path (#7839) |
| **R7 pre-flight** | PROCEED — § Commit-0 Version Re-Verify Record → pre-flight |
| **Slice 1 (#5586) — commits** | `a85f231c` (the tool and GROUP E) · `f3529dab` (the close-out's phase 6.8 and Test 4c.6) · `5d726d4e` (the standard at v1.03 and the smoke workflow) · `6135b7f0` (GROUP E reads its findings through here-strings, after the SIGPIPE-idiom gate flagged three pipes into a quiet reader) · the slice's final commit (this plan). Change units: sub-issues #7911–#7918 under #5586, each marked closed with its landing SHA (DEV-24) |
| **Slice 1 — #5586 AC-3** | **RED** on the unmodified tool: `compute-close-class-telemetry.sh v9.99 --milestone 341` with `--retro` omitted and with `--retro` naming a missing file emitted byte-identical 409-byte lines (control: the register-present run differs). **GREEN** after the fix: 661 and 409 bytes, both non-empty and distinct; the absent line's slots 1, 2 and 5 are byte-identical to the pre-fix line (control: the omitted and absent slots differ). The tool's Test 9 asserts the same inequality in-process |
| **Slice 1 — #5586 AC-4** | **RED** on the unmodified tool: `bash release/tools/tests/test_close_class_telemetry.sh` → PASS 20 / FAIL 4 (E1 absent; E2a and E4a extraction controls BROKEN, anchor found 0 times; E3 seven bound sites missing and three pre-fix literals present; groups A–D 20 of 20 green). **GREEN**: PASS 28 / FAIL 0 — the resolver mutant fails on the RO/RA inequality (E2b) while the binding predicate reads clean on it (E2c); the call-site mutant reddens the binding predicate at the Indicator-5 site (E4b) while its own self-test stays green (E4c) |
| **Slice 1 — #5586 AC-2 (non-regression)** | `--retro release/references/templates/release-learnings-register-template.md` → `10/10 (1.00)`, `0/2 (0.00)`, `present` before and after the fix; slots 1, 2 and 5 byte-identical. Slot 6 moved (19/41 → 19/49) with the milestone's live sub-task population, because this slice's eight sub-issues joined it — not with the tool |
| **Slice 1 — #5586 AC-1** | `[DEFERRED]` to #6892 under hold K; not graded in this release |
| **Slice 1 — regression** | The tool's `--self-test` → exit 0, reporting the register-resolution line. `bash release/tools/automated-closeout.sh --self-test` (CIAC-5's method) → `FAIL (2 failures)`, exactly arms (d2) and (d3), with the arms in and phase 6.8 unchanged; exit 0 with 0 FAIL lines after the phase change. Runtime-suite row 4, `python3 release/tools/check-selftest-coverage.py --run` (sandbox `none (read-only)`, so no `HOME` override): the `ubuntu` partition 74 of 74 and the `macos` partition (which holds `automated-closeout.sh`) 3 of 3 — 77 of 77 discovered self-tests pass |
| **Slice 1 — `test-run` event** | One row: stage 6, `test-run` / `suite-pass`, actor `spoke:#7738`, subject #5586, payload `suite:discovered-tool-self-tests; selected-by:glob-4; pass:77; fail:0; env:none-read-only; sha:5d726d4e; slice:1`. `query-pipeline-event.sh --release telemetry-is-computable --stage 6 --count` read 8 before and 9 after (+1); `--payload-contains 'sha:5d726d4e; slice:1'` reads the row back (1); control: the same token with `-zz` appended → 0 |
| **Slice 1 — doc links** | `python3 core/deploy/tools/check-doc-links.py --target-paths release/references/standards/close-class-telemetry.md,release/releases/plans/telemetry-is-computable_RELEASE_PLAN.md --require-targets` → 0 broken (19 links in the standard, 0 in this plan). Control: a planted link to a missing file in a stub-root copy of the standard → exactly 1 finding |
| **Slice 1 — package freshness** | The six changed paths on stdin to `core/deploy/tools/build-skill-packages.sh --skills-for-paths` → 0 skills, so no package pair is owed and the matrix does not grow. Control: `release/skills/release-planner/references/release-plan-template.md` → `release-planner`; the argv form returns empty, as documented. ADR index: N/A — this release adds no record under `release/ADRs/` |
| **Slice 1 — Tier-A artifact** | `close-class-telemetry.md` § 5.1 carries the declaration marker (flow class `data-flow`, name `close-class-register-slot-states`), found by the design-artifact standard's discovery query; its three `depicts` paths resolve; the enum lint reads 0 out-of-enum markers |
| **Slice 1 — stamp** | `release/tools/claim-version.sh --verify-stamp telemetry-is-computable` → exit 0 (plan-only manifest, 0 packages staled); control: `telemetry-is-computable-zz` → exit 1, `NO PRE-CLAIM PLAN`. Exactly one literal placeholder remains, in the Header `**Version**` cell |
| **Slice 1 — plan executor (hermetic)** | `release/tools/verify-release-plan.sh --root=<stub> --format=md release/releases/plans/telemetry-is-computable_RELEASE_PLAN.md`, the stub a `git archive` of `5d726d4e` with inert `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh`: **8 PASS / 3 FAIL / 10 SKIP / 16 ERROR — over 27 per-issue row(s); 2 declared-deferred** (exit 3). One row differs from Commit 0: with no Stage-4 comment supplied, PROV-DELTA is a named SKIP rather than a PASS. The 3 FAILs are the Commit-0 rows (#5245 AC-1 on the inert deploy stub, #5553 AC-4, #6252 AC-1); #5586's four rows read SKIP or ERROR by construction and are graded by the direct runs above |
| **Slice 2 (#7432) — commits** | `75ce7445` (the seven ADD fixtures) · `e2d72f93` (the tool and the four prose-only fixture edits) · `04f8c900` (this plan's slice-2 rows) · the slice's final commit (a wording correction to one of those rows). Change units: sub-issues #7921–#7927 under #7432, each marked closed with its landing SHA (DEV-26) |
| **Slice 2 — #7432 AC-1** | **RED** with the new fixtures and arms on the unchanged engine: `bash release/tools/check-event-record-integrity.sh --self-test` → 55/83. The limb-(b) arm for `fixture-c4-rel-a` AI-001 fails at PAST, MID and FUTURE, because a bare-id join lets `fixture-c4-rel-b`'s terminal event satisfy A's stale row; the AC-1 control's "the other release's finding remains" fails too, because A's AI-003 row hides B's. **GREEN**: 83/83. A's stale AI-001 is reported under its own release's key, and with A's own terminal event present (the control log against the same tree) nothing is reported for A in either bucket, while B's finding remains |
| **Slice 2 — #7432 AC-2** | **RED**: the limb (a), (b) and (c) collision arms fail at all three cutovers (9 arms). **GREEN**: 3 of 3 limbs report at PAST, MID and FUTURE; every near-miss is silent in both buckets at every cutover; a glob-shaped ledger root keys like the tree |
| **Slice 2 — #7432 AC-3** | One read-only snapshot of the live log and ledgers (7,950 log rows; 100 hub-state directories, 90 ledgers, 1,954 action-item rows, 1,904 of them well-formed at 13 fields), with the pre-fix and the fixed tool each run once at `--surface=both`. C4 **348 VIOLATION + 301 LEGACY → 680 + 701**, over 1,904 well-formed ledger rows, joined against 74 bare ids before and 935 (release, id) pairs after. After, by limb: (a) 467 + 553, (b) 207 + 119, (c) 6 + 29. Per-release attribution: releases carrying a ledger-limb VIOLATION 12 → 23; releases carrying a limb-(c) VIOLATION 0 → 2; releases carrying any C4 finding 17 → 54. 0 ledger-row findings clear under the new join (control: 408 clean → (a) and 289 clean → (b)). Legacy rows by the stated § 2a / § 4.1 rule: 8 version-form keys join under their literal value only, 4 of them INDETERMINATE (`v3.75`, `v3.93`, `v3.97`, `v3.98`), and every legacy-keyed finding reports LEGACY — the 254 version-form rows (27 values) all predate the cutover, the latest at `2026-08-05T19:22:31Z` (control: the latest slug row is `2026-09-26T01:42:09Z`). Self-test RED → GREEN: the `v0.92` LEGACY-at-MID arm, the two legacy-note bracket arms and the PV-7 NOT-EVALUATED arm |
| **Slice 2 — #7432 AC-4** | Self-test: the C4 line reads "joined against 8 distinct (release, id) pair(s) in the log" (pre-fix: "6 distinct AI id(s)", RED); every must-not-flag arm reads 0 at `--surface=both` at PAST, MID and FUTURE (the instant `--since` sets); the agreeing control reads 0 violation(s) + 0 legacy on both C4 lines at PAST and FUTURE; `--surface=ledger` reports both lines SKIPPED. Live and read-only (the real log and ledgers; nothing written): the denominator reads "1904 well-formed ledger rows joined against 935 distinct (release, id) pair(s) in the log", beside a C4c line over the same 935 pairs. The must-not-flag key `hub-emits-state-gates-read:L53` (AI-001 `superseded`, with its own release's `action-item-superseded` event) is absent from both buckets at `--surface=both` and at `--surface=both --since 2020-01-01T00:00:00Z`; sensitivity: `adr-corpus-integrity:L64` (AI-012 `superseded`, no terminal event of its own) is a VIOLATION at both |
| **Slice 2 — the adopted review findings** | Mutation probes, one anchor replaced per mutant and the full `--self-test` run: CD-1 reverted (ledger keys from C5-well-formed rows only) → 79/83, the AI-005 near-miss failing at every cutover; FM-3 reverted (limb (c) tallied on the ledger-row line) → 81/83; FM-4's neighbours — a pair dated by its earliest row, or by its first row → 81/83 each, killed by the MID straddle arm; limb (c) undated → 78/83; the pooled bare-id index for limbs (a) and (b) → 75/83. **One neighbour survives by construction:** dating by the latest row reads 83/83, because on datable rows "any row at or after the cutover" and "the latest row at or after it" are one predicate; they part only on an undatable row that sorts below a datable one, which no fixture carries. On the same snapshot the fixed tool without CD-1 reads 686 VIOLATION + 711 LEGACY (limb (c) 12 + 39), the design's figures; with CD-1, 680 + 701 (limb (c) 6 + 29), review #7872's revised figures |
| **Slice 2 — measured claims** | The design predicted 16 RED of its own arms and 68 assertions. Observed: its own arms read 16 RED on the unchanged engine, as measured; the suite carries 83 assertions — the design's 68 plus 15 for the three adopted findings (CD-1 7, FM-3 5, FM-4 3), which add 12 RED of their own (28 RED in all). Post-cutover C4 VIOLATION: **680**, equal to the figure the review revised from 686 |
| **Slice 2 — regression** | The tool's `--self-test` → 83/83, exit 0. Runtime-suite row 4, `python3 release/tools/check-selftest-coverage.py --run` (sandbox `none (read-only)`, so no `HOME` override): the `ubuntu` partition, which holds this tool, **73 of 74**, and the `macos` partition 3 of 3 — **76 of 77**. The one failure is a runner error outside this slice: `cleanup-orphan-state.sh`'s PR-map identity arm read an empty PR map while the account's GraphQL pool read 0 of 5,000 (it was not re-run, to spare the shared pool; slice 1 recorded the same partition at 74 of 74). `shellcheck -S warning`: 0 findings before and after. The added shell lines carry 0 pipes into a short-circuiting reader (control: the same pattern over the whole file matches 3 pre-existing lines). `usage()`'s 12–36 range is byte-identical |
| **Slice 2 — `test-run` event** | One row: stage 6, `test-run` / `suite-fail`, actor `spoke:#7739`, subject #7432, outcome `escalated`, payload `suite:discovered-tool-self-tests; selected-by:glob-4; pass:76; fail:1; env:none-read-only; sha:e2d72f93; reason:runner-error; failed:cleanup-orphan-state; slice:2` — the `suite-fail` + `reason:runner-error` form the selection map's § 4 prescribes for an infrastructure error. `query-pipeline-event.sh --release telemetry-is-computable --stage 6 --count` read 11 before and 12 after (+1); `--payload-contains 'sha:e2d72f93; reason:runner-error'` reads the row back (1); control: the same token with `-zz` appended → 0 |
| **Slice 2 — doc links** | `python3 core/deploy/tools/check-doc-links.py --target-paths <the eleven changed fixture files>,release/releases/plans/telemetry-is-computable_RELEASE_PLAN.md --require-targets` → 0 broken (the fixtures and this plan carry no markdown link). Controls on a stub-root copy of one fixture: a planted link to a missing file → exactly 1 finding; a planted link to an existing file → 0 |
| **Slice 2 — package freshness** | The thirteen changed paths on stdin to `core/deploy/tools/build-skill-packages.sh --skills-for-paths` → 0 skills, so no package pair is owed and the matrix does not grow. Controls: the same thirteen plus the `release-hub` playbook → `release-hub`; `release/skills/release-planner/references/release-plan-template.md` → `release-planner`; the argv form returns empty, as documented. ADR index: N/A — this release adds no record under `release/ADRs/` |
| **Slice 2 — Tier-A** | NOT ACTIVATED, per DEV-13's decision-record reading: FM-3's `C4c` line changes the report shape of a producer tool, not an output-format file, and the schema is not edited. No artifact is authored |
| **Slice 2 — stamp** | `release/tools/claim-version.sh --verify-stamp telemetry-is-computable` → exit 0 (plan-only manifest, 0 packages staled); control: `telemetry-is-computable-zz` → exit 1, `NO PRE-CLAIM PLAN`. Exactly one literal placeholder remains, in the Header `**Version**` cell |
| **Slice 2 — plan executor (hermetic)** | `release/tools/verify-release-plan.sh --root=<stub> --format=md release/releases/plans/telemetry-is-computable_RELEASE_PLAN.md`, the stub a `git archive` of `e2d72f93` with inert `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh`: **8 PASS / 3 FAIL / 10 SKIP / 16 ERROR — over 27 per-issue row(s); 2 declared-deferred** (exit 3), the same roll-up as slice 1. The 3 FAILs are the Commit-0 rows (#5245 AC-1 on the inert deploy stub, #5553 AC-4, #6252 AC-1). #7432's four rows read ERROR (`unclassified-method`) by construction and are graded by the direct runs above. CIAC-3 reads PASS on the stub; its writer half ran against the inert writer stub, so only its tool half is evidence here |

---

## Change Description

*Authored at Stage 6 Phase C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, before the Stage-9 draft→ready transition. Not authored at Commit 0: no slice has landed, so there is no outcome to describe yet.*

---

## Issue References

The seven content members of this milestone are transitioned to closed at Stage 13 by the close-out on the merged PR, not by an auto-close keyword in the PR body.

- **#5586** — close-class indicators 1, 2 and 5 read N/A on every release; this release separates a caller omission from a genuinely absent register (the reader side; the caller wiring is #6892's under hold K).
- **#7432** — C4 joins action items on the bare AI id; this release joins on (release, id).
- **#4219** — the I6 plan-survival filter is subtype-blind; this release selects the plan-class subtype and gates stage-4 delegation subjects at the writer.
- **#5245** — Check 48's Close-Class-Telemetry sub-check ships inert; this release arms it at `v4.55`.
- **#5553** — a package-only deploy is dropped from T_DEPLOY and misreported; this release names every excluded subtype.
- **#5467** — T_GO anchors on any `plan-review-go` row; this release selects by full identity and gates the identity at the writer.
- **#6252** — T_GO emission is not bound at Stage 9 and the close-out discards the N/A reason; this release binds the emission and carries the reason verbatim.
- **#6892** — the co-shipped partner in `closeout-verification-rows-consistent` (ms#395) that owns the phase-6.8 `--retro` wiring.
- **#6205** — the ledger-and-log-agree card (ms#418) for which #7432 is a release gate.
- **#6872** — ms#410's parser, until which `<release>:<AI-id>` limb-(c) keys are reported, not blocking.
- **#7730** — the sibling card binding Stage 7–8 verdict emission.
- **#6871, #6237 and #4318** — ms#334's adjacent work: the `automated-closeout.sh:1753` edit, the `release-hub` package rebuild, and the Check 48 exit contract.
- **#6618** — the epic holding the four cards that left the milestone.
- **#7681, #7731–#7737, #7871–#7875, #7885, #7886, #7896 and #7738–#7744** — the Stage-4, Stage-5 (designs, reviews and the #4219 delta) and Stage-6 hub sub-tasks carrying the plan source, the designs, their reviews and the decision records.
