---
title: Release Plan — worktree-sessions-reach-in-repo-homes (worktree sessions reach the main checkout's in-repo homes)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.15, equal to the Stage-4 provisional; the concrete number binds at the Stage-12 atomic claim)
milestone: worktree-sessions-reach-in-repo-homes
release_class: novel
reversibility: MODERATE / Confidence HIGH — one guard hook arm, its suite, the rule and the standards that state it, and two hub-procedure slices, on one branch, one pull request and one merge. The ignore-rule pair ships in its own commit so a rollback can keep it. The deployed hook needs a redeploy after a revert. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `worktree-sessions-reach-in-repo-homes`

**Milestone:** `worktree-sessions-reach-in-repo-homes` (milestone 449). Three cards: **#8019** (the main-checkout carve-out in the rule and the hook), **#7503** (a spoke-run audit's output survives its worktree) and **#7929** (the hub writes its resume state ahead of each action). The Stage-4 planning sub-task **#9149** carries the plan (comment 7230768180), the plan-gate Decision Recorded (comment 7230835095) and the Collective Review scope-lock Decision Recorded (comment 7234037568). The Stage-5 designs are on **#9154** (#8019), **#9161** (#7503) and **#9168** (#7929); their adversarial reviews are on **#9198**, **#9199** and **#9200**. The Stage-6 Engineering sub-tasks are **#9155** (#8019), **#9163** (#7503) and **#9169** (#7929). This file is Engineering Commit 0, written by the #8019 Engineering spoke.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.15`**, equal to the D-Version determination (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/worktree-sessions-reach-in-repo-homes`, cut from `origin/main` at `8ed5e273`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial**: Commit 0, then #8019 → #7503 → #7929, one Engineering spoke at a time. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9149 and is amended, in precedence order highest first, by: the Collective Review scope-lock Decision Recorded (D-CR1 approve with adjusts; D-7 A′; D-S36 A; D-Rollback); the three adversarial reviews as the scope-lock adopted them; the three Stage-5 designs with the hub's consumption notes; then the Stage-4 plan and its gate record (D1 approve; D-LocalState C; D-ReleaseClass novel; D-7502 leave out and record). Where the plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a guard hook's behaviour changes inside existing structure, with its rule text, per the Bump-Class Selection Guide's row "Protocol text addition or modification". No new skill and no new governance file. The rule-computed next-free re-verified at Engineering Commit 0 is `v5.15`. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-28 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub, spoke-built Stage 6) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) |
| **Branch** | `release/worktree-sessions-reach-in-repo-homes` |
| **PR** | opened in **draft** at Stage 6 by the #8019 Engineering spoke |
| **Milestone** | `worktree-sessions-reach-in-repo-homes` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-27, domain: governance }`

The dominant class is governance (the rule and standards rows); the secondary class is software (the hook and its test suite).

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0 (2026-11-28T04:3xZ, Saturday): `origin/main` = `8ed5e273`, equal to the release base. The highest version tag is `v5.14` (`a46f143f`).
2. Recomputed next-free for bump-class `minor` through the version-claim adapter (`release/tools/claim-version.sh --bump minor --sha 8ed5e273 --dry-run`): **`v5.15`**.
3. `v5.15` is not in the claimed set (no remote tag `refs/tags/v5.15`; control: the same read returns `refs/tags/v5.14`) and equals the recomputed next-free: **PROCEED**. The tag arm binds.

**In-flight sibling observed at Commit 0.** The Stage-4 roster below is the pinned n=0 measurement at `8ed5e273`. Since then one sibling has pushed: `release/issue-body-is-the-scope-of-record`, head `3f815a63`, with draft pull request #9201. Its bump-class is not read here (UNRESOLVABLE at this rung); any sibling declaring `minor` from the same anchor recomputes the same next-free, and the Stage-12 atomic claim settles it. Its declared overlap with this release is `release/references/how-to/hub-spoke-bridge.md`, in a different section (§ Contention Map). Stage 9 Phase A6.6 re-measures the population.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp worktree-sessions-reach-in-repo-homes` — run after this file was written and before its commit; the result is recorded in the Engineering Commit 0 message.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | under § Header |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan | § Verification Plan |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | Stage 4 `8ed5e273` (read 2026-11-27T23:52Z); branch cut at `8ed5e273`; the window between them is empty |

## Summary (30 seconds)

- **Outcome.** Worktree and spoke sessions write the main checkout's in-repo git-ignored homes and nothing else there; a spoke-run audit's output survives its worktree; the rule and the hook state the same carve-out; and the hub writes resume state ahead of each action.
- **#8019 — the carve-out.** The main-checkout write boundary for the file-write tools is `BLOCK-DESTRUCTIVE-019` in `core/hooks/block-destructive.sh`. It already admits `/analysis/<sub>/` and `/roadmaps/<name>`. This release adds a fourth exemption, a subfolder of `/local-state/` (the tracked `README.md` and any dot-leading entry at the top of the home excluded), in both of the hook's views; adds a parity arm holding the hook's static set equal to the placement standard's registered-homes table (ADR-231 D1); ships the `/local-state/*` + `!/local-state/README.md` ignore pair (D-LocalState C), in its own commit; amends `core/rules/git-workflow.md` § Primary Checkout Discipline; and records the S-36 ruling (D-S36 A).
- **Channel scope (D-7 A′).** Inside the three homes, in their exact shapes, a write is sanctioned on any channel for a session whose file tools reach the main checkout; the file-write channel is the one enforced. An Agent-tool isolated spoke writes the homes on no channel: its output reaches a home through the hub's promotion. A write any control refused is never re-attempted through the shell.
- **#7503 — hub promotion.** An isolated audit spoke stages its output inside its own worktree, and the hub promotes the dated folder to the main checkout's analysis home before removing the worktree (design D-1 C, ratified).
- **#7929 — write-ahead resume state.** `core/standards/hub-session-continuity.md` states the cadence and the resume state's contents, and names the resume pointer as a member of the placement standard's S-01.
- **Scope is hard-locked through Stage 9.** A later change is a governed override: a Decision Briefing with an impact assessment and a deviation-log entry.

## Phase A0 — Triage→Design Re-Review (transcribed)

- **G-PL5 cache-read: MISS** (no marker-bearing comment); PT-1..4 re-run in full, subsumption included. `rows_source: re-derived`.
- **#8019:** re-scope-changed. Affected Files corrected to the hook that decides the channel; the criteria cover all three registered homes; AC-5 (parity), AC-6 (S-36) and AC-7 (ignore pair) added. Operator-confirmed at the plan gate.
- **#7503:** re-scope-changed. The resolver and hook halves shipped after filing; the rule, the standard and spoke reachability remain open; AC-2's method declared as reproduction-and-observe.
- **#7929:** admit-still-valid; AC-3 names the resume pointer as a member of S-01.
- **No C3 fired, so no Tier 0.** No open issue duplicates or subsumes a card.

## Dependency Graph

```
#8019 ──DEPENDS_ON (FS)──▶ #7503   (#7503 AC-1 is worded against #8019's carve-out)
#7503 ──DEPENDS_ON (FS, hub-promotion branch: fired)──▶ #7929   (the spoke-return checkpoint; CIAC-3)
#8019 ── release-gate, not a build edge ──▶ #8022 (milestone in-repo-home-is-guarded; README and commit guard)
```

- Native edges inside the milestone: 0. Outward: #8019 is blocked by #8016 (closed; satisfied).
- Critical path: #8019 → #7503 → #7929, 2 edges. `[DEGRADED-MODE: typed-dep substrate absent; chain length is unweighted edge count; lead/lag NOT modeled]`
- **G3-07: PASS** — 1 inbound edge checked (#8016, closed milestone), 0 cross-milestone violations, 0 cycles.

## Implementation Sequence

Single branch, one release PR, slices committed in this order (P0 serial). Commit messages carry the trailing work-item reference and never a close-family verb.

0. **Engineering Commit 0** — this file, after the version re-verify and `claim-version.sh --verify-stamp`.
1. **#8019** (Stage-6 sub-task #9155):
   - **C1** — the `T8019-*` test arms (43). Then **RED-1**: 14 named failures against the unchanged hook.
   - **C2a** — the `.gitignore` pair `/local-state/*` + `!/local-state/README.md`, and the two narrower rules' comment rewordings. On its own, so a rollback can keep it (FM-3).
   - **C2b** — the `-019` local-state arms in both views and their comment; the placement standard's carve-out cell and its parity sentence. Then **RED-2** in the working tree only (never committed), then **GREEN**.
   - **C3** — `core/rules/git-workflow.md` § Primary Checkout Discipline, and clause (c) of `release/references/how-to/hub-spoke-bridge.md` § Worktree discipline (D-5 A).
   - **C4** — the hook fragment and `_cross-cutting.md`, then `build-hook-registry.py` and its `--check`.
   - **C5** — the cascade rows, then the process-catalog build and `build --check`.
   - **C6** — the S-36 row (D-S36 A), then the gate-coverage register row (D-6 A) with the catalog anchor rewrite and its checks, in that one commit.
2. **#7503** (sub-task #9163): the hub-promotion branch (D-1 C) — `analysis-workspace-standard.md` § 1.1, the bridge's Procedure 4b and isolation row, and `spoke-launch.md` in a sanctioned `pmo-skill-editor` session. Inherits 1's rule text.
3. **#7929** (sub-task #9169): the cadence, the resume-state contents and the resume-pointer home in `hub-session-continuity.md`; the hub-state README; the bridge's Procedure 0b clause; its register row after #8019's; the release-hub playbook clauses and `version:` bump in a sanctioned session (D-5 B); one `release-hub` package rebuild after the last release-hub source edit.

Rationale: every later slice inherits #8019's rule; #7929 is ordered last so its spoke-return checkpoint can name #7503's step.

### Agent-Editability Read (transcribed)

Controls read at `8ed5e273`: the Tier-0 floor (`core/hooks/block-autonomy-ceiling.sh`, `BLOCK-AUTONOMY-001` blocks; surviving tracked floor `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md`, `release/governance/RELEASE_PROTOCOL.md`) and the sanctioned-session gate (`core/hooks/block-skill-direct-edit.sh`; exemption list holds the refiner self-test canary only).

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| #8019 | the hook, its suite, the rules and their fragments, the standards, `operating-model.md`, `lib-instance-path.sh`, process-catalog rows, `.gitignore`, the bridge, `operator.toml.template` | no | no | unconstrained | ordinary Engineering spoke |
| #7503 | `analysis-workspace-standard.md`, `hub-spoke-bridge.md` | no | no | sanctioned-session-required | ordinary Engineering spoke |
| #7503 | `release/skills/release-hub/references/spoke-launch.md` | no | yes | sanctioned-session-required | `sanctioned-session: pmo-skill-editor Mode A (Targeted edit)` |
| #7929 | `hub-session-continuity.md`, `release/releases/hub-state/README.md`, `hub-spoke-bridge.md`, `gate-efficacy-standard.md` | no | no | sanctioned-session-required | ordinary Engineering spoke |
| #7929 | `release/skills/release-hub/SKILL.md`, `references/orchestration-playbook.md` | no | yes | sanctioned-session-required | `sanctioned-session: pmo-skill-editor Mode A (Targeted edit)` |
| #7503 / #7929 | `packages/release-hub.skill` and its `.sha256` | no | build product | class of its source | rebuilt by `build-skill-packages.sh` after the sanctioned edit |

No path in the write set is Tier-0-floored. `-019`'s worktree arm admits every Write/Edit inside the release worktree.

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | 9–13 |
|---|---|---|---|---|---|
| #8019 | APPLY — security-relevant guard widening; D-LocalState keying; parity design; S-36 | APPLY | APPLY (full hook suite; Linux CI) | APPLY | release-scoped |
| #7503 | APPLY — mechanism D-decision; harness-limit discriminating check | APPLY | APPLY | APPLY (reproduction-and-observe for AC-2, hub-executed at Stage-8 entry) | release-scoped |
| #7929 | APPLY — resume-pointer home and template decision | APPLY | APPLY | APPLY | release-scoped |

Stages 7 and 8 run for every card; REDUCE at most, never skip. Stages 10 and 11 compress per the git-native release norm.

## Contention Map

**Within the release (all serial, #8019 → #7503 → #7929):**

| File | Cards | Resolution |
|---|---|---|
| `release/references/how-to/hub-spoke-bridge.md` | #8019 (§ Worktree discipline clause (c), D-5 A), #7503 (isolation row, Procedure 4b), #7929 (Procedure 0b clause) | serial; disjoint sections |
| `core/standards/gate-efficacy-standard.md` | #8019 (parity row, D-6 A), #7929 (its row after #8019's) | serial; each slice runs the catalog anchor rewrite in its own commit |
| `core/process-catalog/engineering-harness/*.md` (generated anchors) | #8019, #7929 | regenerated by `anchors resolve --write`, never hand-edited |
| `release/skills/release-hub/*` and `packages/release-hub.skill` | #7503, #7929 | one rebuild after the last release-hub source edit |

**Cross-release, by declared scope** (measured at Stage 4; re-measured at Stage 9):

| Sibling | Overlap | Note |
|---|---|---|
| `fs-boundary-judges-every-listed-verb-operand` | `core/rules/bypass-mode-readiness.md` (generated); the hook test runner (different suites) | regenerate after merge, never hand-merge |
| `issue-body-is-the-scope-of-record` (draft PR #9201, pushed after the Stage-4 pin) | `release/references/how-to/hub-spoke-bridge.md`, a different section | merge order puts this release last |
| `rollups-select-projects-by-portfolio` | none | — |
| `in-repo-home-is-guarded` (#8022/#8023/#8024; not started) | the `/local-state/` premise; its README and commit guard | release-gate only; the ignore pair moved into this release (D-LocalState C) |

### In-Flight Release Roster

**Measured at:** `8ed5e273` · `2026-11-27T23:52:37Z` · **Population:** n=0 sibling(s): none in flight at `8ed5e273` / 2026-11-27T23:52:37Z. Remote heads: `main` only (control: the `main` head row returned). The Commit-0 observation of one later sibling is recorded in § Commit-0 Version Re-Verify Record and does not amend this pinned measurement.

## File Change Matrix

Every Stage-4 condition was decided at Stage 5 or at the Collective Review scope-lock; fired rows are promoted below and unfired rows are listed as explicit non-scope. The release is **1 ADD + EDIT rows**, no delete.

```
# ── release record ──
release/releases/plans/worktree-sessions-reach-in-repo-homes_RELEASE_PLAN.md  add
# ── #8019 ──
core/hooks/block-destructive.sh  edit
core/hooks/tests/block-destructive.test.sh  edit
core/standards/instance-data-placement-standard.md  edit
core/rules/git-workflow.md  edit
core/rules/bypass-mode-readiness/block-destructive.md  edit
core/rules/bypass-mode-readiness/_cross-cutting.md  edit
core/rules/bypass-mode-readiness.md  edit
core/standards/depersonalization-spec.md  edit
core/deploy/lib-instance-path.sh  edit
core/disciplines/operating-model.md  edit
core/process-catalog/definitions/controls-register.tsv  edit
core/process-catalog/views/controls-hook-rule.md  edit
core/process-catalog/views/controls-prose-rule.md  edit
core/config/operator.toml.template  edit
release/references/how-to/hub-spoke-bridge.md  edit
core/standards/gate-efficacy-standard.md  edit
# ── #7503 ──
core/standards/analysis-workspace-standard.md  edit
release/skills/release-hub/references/spoke-launch.md  edit
# ── #7929 ──
core/standards/hub-session-continuity.md  edit
release/releases/hub-state/README.md  edit
release/skills/release-hub/references/orchestration-playbook.md  edit
release/skills/release-hub/SKILL.md  edit
core/process-catalog/engineering-harness/flip-gate-to-enforce.md  edit
core/process-catalog/engineering-harness/graduate-gate-modes.md  edit
core/process-catalog/engineering-harness/review-warn-log-drains.md  edit
# ── #7503 and #7929 (one rebuild) ──
packages/release-hub.skill  edit
packages/release-hub.skill.sha256  edit
```

Notes on the matrix:
- **Two repository-root rows sit outside the fence**, because the matrix extractor reads only paths under the repository's named top-level folders: the root `.gitignore` is **edit** (#8019, commit C2a: the `/local-state/*` + `!/local-state/README.md` pair and two comment rewordings), and `local-state/README.md` is **NOT EDITED** (#8022's). Neither is an add, so the declared-vs-delivered check loses no obligation.
- The hook registry is regenerated from its fragments by the hook-registry builder; the two process-catalog views by the catalog builder's `build`; the engineering-harness pages by its `anchors resolve --write`. None is hand-edited. The engineering-harness rows are declared under #7929, whose design measured them; #8019's register row may move the same anchors in its own commit.
- `core/rules/git-workflow.md` and `core/rules/bypass-mode-readiness.md` are mirror-pair sources: edit the source only. Any new link to a target outside the mirrored set uses the leading-`/` form.
- `core/config/operator.toml.template` is a sweep row added by the #8019 adversarial review (FM-5): one consumer comment restates the read-only primary.
- No new shell script is added, so the script-allowlist companion obligation does not fire. No schema file. No path move.

#### Read-only inputs

```
core/ADRs/ADR-231-non-tracked-data-homed-by-risk-class.md  READ
core/hooks/block-autonomy-ceiling.sh  READ
core/hooks/block-fs-boundary.sh  READ
core/hooks/tests/setup-ci-layout.sh  READ
core/hooks/tests/test-runner.sh  READ
release/references/how-to/implementation-execution-pattern.md  READ
```

#### Release-wide explicit non-scope

```
core/hooks/block-fs-boundary.sh  NOT EDITED
core/hooks/lib/platform-membership.sh  NOT EDITED
core/hooks/block-autonomy-ceiling.sh  NOT EDITED
core/standards/skill-workspace-location.md  NOT EDITED
core/standards/hub-action-tracking.md  NOT EDITED
release/releases/hub-state/resume.md.template  NOT EDITED
core/deploy/composition-surface-manifest.sh  NOT EDITED
core/deploy/allowlists/hub-state-enum-parity-map.txt  NOT EDITED
core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md  NOT EDITED
core/skills/pmo-qa-auditor/references/architecture-conformance-mode-spec.md  NOT EDITED
core/skills/pmo-qa-auditor/references/fitness-audit-mode-spec.md  NOT EDITED
packages/pmo-qa-auditor.skill  NOT EDITED
```

Why each is out: the filesystem-boundary family, the membership library and the autonomy ceiling carry no home arm (ADR-231 D1 channel scope); the home's README and the commit guard are #8022's; the skill-workspace location standard stays as is under D-S36 A; the resume template, the composition manifest, the parity map and the action-tracking standard do not fire under #7929's D-3 A and D-4 A; the pmo-qa-auditor mode specs and package do not fire under #7503's D-4 A (the direct-write branch was not chosen); the implementation-execution pattern keeps its read-only sentence (FM-5 sweep row, PRESERVE: it concerns doing implementation work in the primary).

## Risk Register

| ID | Risk | Severity / likelihood | Mitigation / disposition | Owner stage |
|---|---|---|---|---|
| R1 | The edit lands in the wrong hook, so the new arm passes while the real gate is unchanged | HIGH / LOW | Affected Files corrected; the RED arms fail against main's `block-destructive.sh` | 6 |
| R2 | `/local-state/` admitted while un-ignored; a session-written `local-state/README.md` blocks #8022's fast-forward | HIGH / MEDIUM | D-LocalState C: subfolder-keyed arm, README and dot withholds, and the ignore pair ships in this release | 6, 12 |
| R3 | Self-governing hook: the deployed copy governs every session until Stage 12; a bare-checkout harness run leaves an untracked leftover | MEDIUM / HIGH | The worktree layout runs this branch's hook; `git status --porcelain` before and after every harness run; never stage the leftover | 6–8 |
| R4 | Isolated spokes are refused by the harness outside their worktree | HIGH / OBSERVED | Hub-promotion branch for #7503 (independent of the result); A′ bounds the rule by session shape | 5, 6 |
| R5 | Overclaim: prose says "every other write stays denied" while the shell channel is unguarded | MEDIUM / HIGH | The rule states ADR-231 D1's channel scope and A′ | 6 |
| R6 | Merge contention on the regenerated registry, the catalog views and the bridge with concurrent releases | MEDIUM / HIGH | Merge last; regenerate rather than hand-merge; Stage 9 A6.5 re-check | 9, 12 |
| R7 | New suite arms fail on the Linux leg | MEDIUM / LOW | Stage 7 reads the Linux job; register a known failure only with a filed defect | 7 |
| R8 | The parity check is vacuous | MEDIUM / MEDIUM | Mutated-table controls (P2, P3), hook mutants in both views (P4, P4b) and a specificity arm (P5); an inert mutant FAILs | 6–7 |
| R9 | Below-band composition: 10 raw points carry a full pipeline's fixed overhead | LOW / CERTAIN | A finding only; the operator ruled the composition stands | — |
| R10 | Rollback leaves data: files written into the homes after deploy persist after a revert, and reverting the ignore pair would un-ignore them | LOW / LOW | The ignore pair ships in its own commit and is kept by a rollback; D-Rollback's ordered re-keying | 12–13 |
| R11 | AC ordinals shift after the Tier-1 deltas | LOW / CERTAIN | Rows re-bound in § Verification Plan at Commit 0 | 6 |
| R12 | The Stage-12 deploy carries every hook change since the last deploy | LOW / CERTAIN | The Stage-12 deploy record names each deployed hook change | 12 |
| R13 | A guard outside the platform refuses a worktree session's file-tool write into a home (the #8019 review's FM-1; the hub's R4m probe was allowed for a new file, and the pre-existing-file Edit axis is untested) | MEDIUM / MEDIUM | The rule calls the carve-out a permission, not a reachability promise, for every worktree-rooted session; a refusal is reported, never routed around through the shell; the Stage-13 live probe names its session shape and both tools, and a refusal from outside the platform is a finding routed to the operator, not a rollback event | 6, 13 |

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8019 × #7503 on the -019 static set):** the release's hook revision admits a spoke-shaped Write to the exact analysis destination shape that #7503's standard names for a spoke-run audit. *Method:* `grep -c -F "T8019-CIAC1" core/hooks/tests/block-destructive.test.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* The arm's behavior is graded by the hook-harness CI jobs.
- [ ] **CIAC-2 (#8019 × #7503 on `git-workflow.md` § Primary Checkout Discipline and `analysis-workspace-standard.md` § 1):** the rule's carve-out and the analysis standard's write path name the same analysis shape (`/analysis/<sub>/`) and the same file-write channel scope. *Method:* declared, verification deferred to #8019 AC-4 and #7503 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#7503 × #7929 on the hub's spoke-return step):** a hub resuming after a cut-off can locate the audit output of every spoke that returned before the cut-off, whether promoted to the main checkout's home or still awaiting promotion. *Method:* declared, verification deferred to #7503 AC-2 and #7929 AC-2. *Graded at Stage 9 QC3.5 on the merged PR.*

**Lint (G4-06).** CIAC-LINT-SUMMARY recorded at Commit 0 in § Verification Evidence.

## Verification Plan

**AC baseline.** At Stage 4 (bodies read 2026-11-21, against `8ed5e273`): #8019 4 · #7503 3 · #7929 3. The plan-gate Tier-1 deltas added #8019 AC-5, AC-6 and AC-7, so the rows below are re-bound to the amended ordinals at Commit 0.

`ac_baseline: { #8019: 7, #7503: 3, #7929: 3, read_at: 8ed5e273d301f80bb0e281222e06a22432090ebb }`

**Revised suite targets (adversarial review FM-4, adopted at scope-lock).** 43 `T8019-*` arms. RED-1 expects 14 named failures against the unchanged hook (P4b is INERT before the change). GREEN on macOS: `block-destructive.test.sh` 2,474/2,474 and aggregate 5,482/5,482. Linux: 2,471 with 6 registered, aggregate 5,480, 20 FAIL all registered, `KNOWN-FAILURES: GREEN`.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8019 | AC-1 | `grep -c -F "T8019-A" core/hooks/tests/block-destructive.test.sh` at least 7 | A1–A7 present; A1–A5 red against the unchanged hook; behaviour graded by the hook-harness CI jobs |
| #8019 | AC-2 | `grep -c -F "T8019-D" core/hooks/tests/block-destructive.test.sh` at least 16 [READER-GRADED — `git-workflow.md` names the shell channel as outside the enforcement and states A′] | D1–D16 present and passing; RED-2 recorded |
| #8019 | AC-3 | `grep -c -F "T8019-S" core/hooks/tests/block-destructive.test.sh` at least 5 | S1–S5 present, with an Agent-tool worktree payload cwd |
| #8019 | AC-4 | `grep -c -F "/local-state/<sub>/" core/rules/git-workflow.md` at least 1 [READER-GRADED — the three homes, the file-write channel scope, A′, the reach caveat and the amended spawned-spoke clause] | ≥1 (baseline 0) |
| #8019 | AC-5 | `grep -c -F "T8019-P" core/hooks/tests/block-destructive.test.sh` at least 6 | P1–P5 and P4b present; P1 reads AGREE and each mutant reads DISAGREE |
| #8019 | AC-6 | `grep -c -F "S-36" core/standards/instance-data-placement-standard.md` at least 1 [READER-GRADED — the S-36 row states the operator's D-S36 ruling and its residual] | ≥1; the wording records the ruling |
| #8019 | AC-7 | `grep -c -F "!/local-state/README.md" .gitignore` at least 1 [READER-GRADED — `git check-ignore` from the repository root matches a subfolder path under the home and does not match its README, recorded in the Stage-6 evidence] | ≥1 (baseline 0) |
| #7503 | AC-1 | `grep -c -i "spoke" core/standards/analysis-workspace-standard.md` at least 1 [READER-GRADED — a governed destination for a spawned spoke's audit output is named, with the hub's promotion for an isolated spoke] | ≥1 (baseline 0) |
| #7503 | AC-2 | [DEFERRED — reproduction-and-observe at Stage 8 entry, hub-executed: an isolated spoke runs one audit mode, its worktree is removed, and the dated folder is listed at the main checkout's analysis home] | dated folder present |
| #7503 | AC-3 | `grep -c -F "/analysis/*" .gitignore` at least 1 | ≥1 (baseline 1, non-regression) |
| #7929 | AC-1 | `grep -c -i "before each spoke launch" core/standards/hub-session-continuity.md` at least 1 | ≥1 (baseline 0) |
| #7929 | AC-2 | `grep -c -i "died" core/standards/hub-session-continuity.md` at least 1 [READER-GRADED — the resume state names the stage and gate, the next action, and every spoke in flight with its died-test] | ≥1 (baseline 0) |
| #7929 | AC-3 | `grep -c -i "resume pointer" core/standards/hub-session-continuity.md` at least 1 [READER-GRADED — a home outside the status-only ledger, named as a member of S-01, with its class, governed home and today's token] | ≥1 (baseline 0) |

At Commit 0 most rows read FAIL by design: no arm or text carrying them exists yet. They turn PASS as each slice lands.

**Release-level verification.** `python3 core/deploy/tools/build-hook-registry.py --check` and `python3 core/deploy/tools/build-process-catalog.py build --check` exit 0; the CIAC lint is re-read at Stage-6 entry and at Stage 9; the Stage-13 live probe (below) is the first live proof of the arm.

## Delivery Strategy · Rollback Strategy

- **Delivery.** One branch, one PR, slices as commits in the order above, P0 serial, no force-push. The version stays unclaimed until the Stage-12 atomic claim. The deployed hook governs every session until the Stage-12 deploy (`deploy.sh --deploy`).
- **Test strategy for a self-governing hook.** Stages 6 and 7 run this branch's hook from the release worktree root (`bash core/hooks/tests/setup-ci-layout.sh`, then `bash .claude/hooks/tests/test-runner.sh`). No session may test `/local-state/` against the main checkout before deploy. The first live proof is post-deploy at Stage 13: from a named session shape (a main session rooted in a session worktree), a `Write` and an `Edit` to `<main>/local-state/<sub>/probe` are allowed and a write to `<main>/core/<probe>` is refused, then the probe file goes to trash.
- **Rollback trigger (operator, D-Rollback, adopted at scope-lock).** Roll back if the Stage-13 live probe shows a file write to `<main>/core/<probe>` allowed. Within 7 days of deploy, if `git status --porcelain -- local-state/` in the main checkout lists a path: a README is trashed, any other path means the ignore rule is fixed, and only then is the merge reverted. Trigger (b) is measured by `git log --all --name-only` plus `git ls-files`, searched for `resume-pointer`. A refusal from outside the platform at the live probe is a functional finding routed to the operator, not a trigger event (R13).
- **The sibling cards' drafted triggers.** #7503: roll back its slice if, in either of the next two releases that run an audit spoke, one folder a spoke reported `written` or `staged` is absent from the home at that release's Stage-13 close, or any audit spoke writes a main-checkout path outside `analysis/<subfolder>/`. #7929: roll back its slice if, in either of the next two releases whose hub resumes at least once, (a) a resumed hub repeats an action whose output already existed because it trusted the pointer, or (b) a resume pointer appears in a tracked file or a pushed branch. The scope-lock record does not restate these two cards' windows, so the two-release window stands as their designs drafted it [ASSUMPTION – CONFIRM].
- **Mechanics.** Revert the #8019 hook and rule commits on `main` and keep the ignore-pair commit (FM-3); redeploy (`deploy.sh --deploy`), which restores the prior `-019` static set. Per-card: revert that card's slice commits; for #7503 and #7929, rebuild `packages/release-hub.skill`. The version tag is retained (Tag Retention).
- **Reversibility.** MODERATE overall, because of the deployed-copy second step. CHEAP per slice before merge. Confidence HIGH.

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: 3 · Stage 7: 3 · Stage 8: 3
**Per-spoke cost estimate:** ordinal band M, M, S (low–moderate, lowest), roughly 5–8 % of a 5-hour window per spoke (source: heuristic; no telemetry medians)
**Assumed/stated remaining usage-window envelope:** unstated at the plan gate; the conservative default of 50 % remaining applies
**Estimated cumulative draw % (worst parallel batch):** Stage 5 × 3 ≈ 15–24 %, about 30–48 % of the default envelope
**Routing:** PASS: proceed in parallel; serialize Stage 5 if the stated envelope is under about 48 % at launch
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API quota (`core`/`graphql` pools), combined DEFER-dominant (§ 4.3b). Checkpoint A stays usage-window-only (§ 3.1). Bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

## Parallelization Map (recorded 2026-11-27)

Serialize after `fs-boundary-judges-every-listed-verb-operand` and `issue-body-is-the-scope-of-record` (append-pattern and section-disjoint file contention; no hard edges); release-gate edge to `in-repo-home-is-guarded` (#8022); no Tier-S edge (empty mover-set); hard edge #8019 ← #8016 satisfied. Reconfirmed by the milestone scan at Stage 9.

## Release Outcome Statement

Worktree and spoke sessions write the main checkout's in-repo ignored homes and nothing else there, a spoke-run audit's output survives its worktree, the rule and the hook state the same carve-out, and the hub writes resume state ahead of each action.

## Release Class declaration

- **Class:** `novel` (D-ReleaseClass, operator, plan gate).
- **Fired:** novel (b), a Stage-5 D-decision (#7503's mechanism; D-LocalState keying). **Not fired:** cross-cutting (a), (b) and (c); routine (a) fails because two cards are P2.
- **Differentiation:** engagement Standard · Stage 9 depth Deep · Stage 5 ALL · Stage 13 window 30-day.
- **Release-identity mode:** versioned · when-to-version: WV-1 (a hook's behaviour changes).

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-28)

D1 approve (the plan, the Release Outcome Statement draft, the re-scope of #8019 and #7503, the Tier-1 body edits); **D-LocalState C** (subfolder-keyed arm, and this release ships the `/local-state/` ignore pair); **D-ReleaseClass** `novel`; **D-7502** leave out and record its re-home. Recorded determinations: D-Version minor (provisional `v5.15`, recomputed at Commit 0, claimed at Stage 12); D-C SINGLE; posture P0.

### Collective Review scope-lock (operator, 2026-11-28)

- **D-CR1 approve with adjusts.** The three cards lock as designed; every adversarial finding enters Stage 6 as a literal change. Ratified: #8019 D-1 to D-4 and the hub's D-5 and D-6; #7503 D-1 C, D-2 A, D-3 A, D-4 A and D-6 A; #7929 D-1 B, D-2 A, D-3 A, D-4 A, D-5 B, D-6 and D-7 A.
- **D-7 A′.** Any channel inside the homes, in their exact shapes, for a session whose file tools reach the main checkout. An Agent-tool isolated spoke writes the homes on no channel; its output reaches a home through the hub's promotion. A write any control refused is never re-attempted through the shell.
- **D-S36 A.** The skill-iteration workspace home is left out of the registered homes by ruling; the S-36 row records the ruling and the residual.
- **D-Rollback.** The numeric trigger with a 7-day window, re-keyed (§ Delivery Strategy · Rollback Strategy).

## Deviation Log

| ID | Stage | Deviation | Basis |
|---|---|---|---|
| DEV-1 | 6 (Commit 0) | The Verification Plan is re-bound to #8019's seven criteria (AC-5, AC-6 and AC-7 added at the plan gate) and to the revised suite targets (43 arms, RED-1 14) | AC-Binding: amending a criterion obliges updating its bound row; review FM-4 |
| DEV-2 | 6 (Commit 0) | The File Change Matrix promotes every fired Stage-4 conditional row and adds the rows the designs and reviews added: `controls-prose-rule.md` (C-319), the bridge (D-5 A), `gate-efficacy-standard.md` (D-6 A), `.gitignore` (D-LocalState C), `operator.toml.template` (FM-5), the engineering-harness anchor pages (#7929's design), `release-hub/SKILL.md` and the playbook (D-5 B) | Stage-4 § 6 authoring contract rule 5 |
| DEV-3 | 6 (Commit 0) | #8019's commit C2 splits into C2a (the ignore pair) and C2b (the arms) | review FM-3, adopted at scope-lock |
| DEV-4 | 6 (Commit 0) | The Rollback Strategy carries the operator's numeric trigger in place of the Stage-4 qualitative one | D-Rollback |
| DEV-5 | 6 (Commit 0) | The design's AC-7 method (`git check-ignore` with an exit-status echo) is not a shape the plan verifier runs; the row's designated command is a `grep` on `.gitignore`, and the `check-ignore` result is a reader-graded limb recorded in the Stage-6 evidence | the plan verifier's executable shapes |
| DEV-6 | 6 (#8019) | The rule applies D-7 A′ beyond the shell paragraph: the carve-out bullet names "a main session, or a spoke launched without worktree isolation" where the design wrote "a main session or a spawned spoke", and the spawned-spoke bullet and the C-319 statement say an Agent-tool isolated spoke writes the homes on no channel | D-7 A′ is the top-precedence record; the design literal predates it |
| DEV-7 | 6 (#8019) | The regenerated hook registry moved 8 catalog line citations in the three engineering-harness pages, so commit C4 carries their anchor rewrite; the register row in C6 moved 10 more, rewritten in C6 | the catalog citation gate |
| DEV-8 | 6 (#8019) | RED-2 ran through the hook test runner rather than the suite alone: exporting the runner's scope-guard root in a session command is refused by `BLOCK-DESTRUCTIVE-023`, and without it a direct suite run reads the hooks as out of scope | a control firing, recorded in the Stage-6 output; the runner is the sanctioned path |
| DEV-9 | 6 (#8019) | A2 container: the threshold predicate selects the sub-issue container (more than five units, multi-file). The decomposition is the scaffolded Stage-6 sub-task #9155 plus the commit slices C1 to C6, listed as a checklist in the release PR body; no further sub-issues were created | the per-issue Stage-6 sub-task is the container Procedure 1 scaffolds |
| DEV-10 | 6 (#8019) | The `## Change Description` section (Stage 6 C1) is owed by the release's last Engineering slice (#7929), because the #7503 and #7929 slices are not yet built | Stage 6 C1 is authored before the PR is marked ready, at Stage 9 |

## Verification Evidence

Populated by each Engineering slice; § Commit 0 is this file's own.

### Commit 0

- Version half: PROCEED (`v5.15`; § Commit-0 Version Re-Verify Record).
- Manifest half and the CIAC lint: recorded in the Engineering Commit 0 message and in the #8019 Stage-6 output on #9155.

### #8019 (commits C1 to C6)

- **RED-1** (C1 against the unchanged hook): `block-destructive.test.sh` 2,474 assertions, 14 FAIL, exactly A1–A5, S1, MSG1, L5–L7, P1, P4, P4b and P5.
- **RED-2** (working tree only, never committed; the naive arms were undone by edit): an any-path arm with no withholds failed 16 (D4–D10, D16, S5, MSG1, L2–L4, P1, P4b, P5); a subfolder arm with no withholds failed 4 (D7, D10, MSG1, L3).
- **GREEN** on macOS from the worktree root, 30 suites: `block-destructive.test.sh` 2,474/2,474, aggregate 5,490/5,490, 0 FAIL. The block-destructive count equals the revised target; the aggregate is 8 above the 5,482 target, every one of them a PASS outside block-destructive, not reconciled per suite here. Linux was not run locally; the release PR's Linux job is its reading.
- **AC-7:** `git check-ignore` from the repository root — `local-state/zz-ac7/x` ignored (exit 0, by `/local-state/*`), `local-state/README.md` not ignored (exit 1, the negation), and the near-miss `local-state-x/y` not ignored (exit 1).
- **Registry and catalog:** `build-hook-registry.py --check` in sync; `build-process-catalog.py build --check`, `anchors resolve --check` and `check-process-catalog.py --pattern-arm not-run` each exit 0.
- **Doc links:** `check-doc-links.py` over the six changed markdown rule and reference files reports no broken reference (control: its `--self-test`, 12 fixtures).
- **Skill-package freshness:** `build-skill-packages.sh --skills-for-paths` over the 21 paths in the release diff names no skill (control: the release-hub skill file names `release-hub`).
- **Cascade sweep:** 16 superseded phrasings over the 14 cascade files, read by the same program at both revisions, total 24 on `origin/main` and 0 at the C6 head.
- **ADR index:** N/A — this release adds no record under `release/ADRs/` (as of #8019's slices).
