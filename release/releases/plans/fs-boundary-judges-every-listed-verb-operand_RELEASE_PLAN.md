---
title: Release Plan — fs-boundary-judges-every-listed-verb-operand (the filesystem-boundary guard examines a listed verb's operand at six more positions)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.15, equal to the Stage-4 provisional; the concrete number binds at the Stage-12 atomic claim)
milestone: fs-boundary-judges-every-listed-verb-operand
release_class: novel
reversibility: MODERATE / Confidence HIGH — one guard hook, its suite, a second suite's old-shape copy, its readiness fragment, the generated registry and three cited process pages on one branch, one pull request and one merge; each slice reverts as one commit before merge, and the deployed hook needs a second operator refresh after a revert. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `fs-boundary-judges-every-listed-verb-operand`

**Milestone:** `fs-boundary-judges-every-listed-verb-operand`. One card, **#8547** (P1, size:L): BLOCK-FS-BOUNDARY-001 and -002 in `core/hooks/block-fs-boundary.sh` never examined a listed verb's operand at six command positions, so an out-of-root literal operand there passed with no refusal and no record at every mode. The Stage-4 planning sub-task **#9148** carries the approved plan (two parts) and the Stage-4 gate's Decision Recorded. The Stage-5 design is on **#9188**: the original output, an independent adversarial review, the operator's Phase B Decision Recorded, and **revision 1** (four parts), which supersedes the original for Stage 6. The Stage-6 Engineering sub-task is **#9189**, decomposed into sub-issues #9247–#9256. This file is Engineering Commit 0.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.15`**, equal to the D-Version determination (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/fs-boundary-judges-every-listed-verb-operand`, cut from `origin/main` at `8ed5e273`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial**: Commit 0, then the RED commit, then the refactor and the three GREEN slices, then the documents commit, in the order of § Implementation Sequence. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9148 and is amended, in order, by: the Stage-4 gate's Decision Recorded (the plan approved as written; D-ReleaseClass `novel`; the Release Outcome Statement draft approved; D-Version minor as a recorded determination; D-C SINGLE and P0 as recorded determinations), then the operator's Stage-5 Phase B Decision Recorded (D1 revise the design first; D2 close both the class-5 residual and the inverted-mask face on this guard; D3 accept the here-document body over-block; D4 accept the structural blast-radius tier), then Stage-5 revision 1. Where the plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a guard hook's behaviour changes inside its existing rules, with its suite and readiness text, the same shape as the recent hook releases. The rule-computed next-free re-verified at Engineering Commit 0 is `v5.15`. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-28 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub; Stage 6 built by one Engineering spoke) |
| **Status** | Executing — Stage 6 Engineering complete (release PR #9257 in draft); next Stage 7 Dev Testing |
| **Branch** | `release/fs-boundary-judges-every-listed-verb-operand` |
| **PR** | #9257, opened in **draft** at Stage 6 right after Engineering Commit 0 |
| **Milestone** | `fs-boundary-judges-every-listed-verb-operand` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-27, domain: software }`

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0 (2026-11-28, before 06:38Z): `origin/main` = `8ed5e273`, unchanged since the Stage-4 baseline; the highest version tag is `v5.14`.
2. Recomputed next-free for bump-class `minor` through the version-claim adapter (`release/tools/claim-version.sh --bump minor --sha 8ed5e273 --dry-run`): **`v5.15`**.
3. `v5.15` is not in the claimed set (no `v5.15*` tag) and equals the recomputed next-free: **PROCEED**. The tag arm binds. Three sibling `release/*` heads are now on the remote (`issue-body-is-the-scope-of-record`, `rollups-select-projects-by-portfolio`, `worktree-sessions-reach-in-repo-homes`); none has claimed a tag, so the shared slot is a serialization point at the atomic claim, not at this rung (R-08).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp fs-boundary-judges-every-listed-verb-operand` — exit recorded in the Engineering Commit 0 message.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | under § Header |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix (as amended in § Deviation Log) |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria (none: one card) |
| 4 | Verification Plan | § Verification Plan |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | `8ed5e273` (Stage 4, Stage 5 revision 1 and this branch's cut point are the same commit) |

## Summary (30 seconds)

- **The defect reproduces in full on the baseline.** At six positions an out-of-root literal operand of a listed read verb and of a listed write verb is admitted with no rule verdict and no record: after a redirection operator that carries an ampersand (class 1); on a continuation line (class 2); with the verb word written in quotes (class 4); behind a listed prefix word while an unbalanced quote switches the shared canonicalizer off (class 5); after a redirection operator that carries a pipe; and after a process substitution. Class 3 belongs to another card. [SOURCE: Stage 4 E-1; Stage 5 revision 1 E-3, baseline column]
- **Design (Stage 5 revision 1): an add-only second pass inside the guard; the shared canonicalizer is not edited.** After both verb loops have judged the command exactly as today, the second pass reads the command again in readings the first pass does not make, and hands every verb-and-word pair the first pass did not hand over to the same per-operand disposition, with the same rule IDs and messages. It can only add a refusal or a record.
- **Zero refuse-to-allow movement, by construction and measured.** The first pass's lines stay byte-identical where the suite keys on them; a copy with the second pass off returned the baseline's verdict on every measured row; the differential arm in the suite is the release's zero.
- **One ADR** (`core/ADRs/ADR-242-fs-boundary-second-pass-reads-skipped-operands.md`, `Proposed`), cited in prose by its slug token.
- **Declared and pinned, not closed:** a `case` inside a process-substitution body whose subject holds a quoted blank (a residual for the operator to accept at Stage 9 GO with a named successor owner); a here-document body read with its redirection operators and continuations joined (a declared over-block, accepted by the operator's D3).

## Phase A0 — Triage→Design Re-Review

Carried from the Stage-4 plan unchanged: G-PL5 MISS (no briefing; rows derived); G-PL1 reference currency PASS; G-PL2 crisping PASS; G-PL3 placement SKIP (the base is `origin/main` itself); G-PL4 empirical repro **admit-still-valid** — all six positions reproduce at `8ed5e273` with the card's magnitude. Every AC row classifies C1 or C2; no premise moved, so there is no Tier 0. The `[ASSUMPTION – CONFIRM]` in the card's Affected Files (the fix location for classes 4 and 5) is closed by Stage 5: guard-local (revision 1, D-S1).

## Dependency Graph

- **Within the release:** one card, no edges.
- **Native edges on #8547:** `blocked_by` 0, `blocking` 0. Parent epic #8387 (the evergreen defect flow).
- **External order constraints (soft, by sequencing; neither is a dependency edge):** before the cards #8836 and #8837 (both touch this guard, and #8836 the canonicalizer); beside the sibling milestone `worktree-sessions-reach-in-repo-homes`, which shares no source file with this release, only the generated registry and the process-catalog citations into it.

```
#8387 (epic, evergreen) ──parent──▶ #8547 (this release)
#8547 ──merge-order: before──▶ #8836, #8837 (unmilestoned; the shared walk)
#8547 ◀──file-contention (generated registry, process-catalog citations)──▶ #8019 (sibling milestone 449)
```

## Implementation Sequence

One card, one branch, one release PR, the commits in this order (Stage 5 revision 1, Output for Stage 6). Every commit's suite is green except the RED commit's new arms, which stay red until the slice that owns each one. Each GREEN slice lands the measured prototype's code with the readings of later slices present but switched off, and the slice that owns a reading switches it on. Concrete bypass spellings live only in the suite's payloads; commit messages, the PR body and this file state positions at class level.

| Step | Commit | Content | Gate |
|---|---|---|---|
| 0 | Engineering Commit 0 (#9247) | this file, after the version re-verify; `claim-version.sh --verify-stamp`; the hook-suite floor read by the full runner; the ADR (`Proposed`), its number from `renumber-adr.py --detect` immediately before creation | stamp exit 0; floor recorded |
| 1 | RED (#9248) | the position, near-miss (with the emptied-allowlist warn pairing), must-not-refuse, inverted-mask, differential and cost arms; every existing arm untouched; the differential's recorded-verdict arm runs against the shipped hook | every new position, inverted-mask, near-miss-pairing, post-verdict and cost arm red; every must-not-refuse arm and every existing arm green |
| 2 | refactor (#9249) | the per-operand disposition moved into one function, its lines byte-identical; the seen bookkeeping; one source for the verb lists; the top-level bookkeeping block | the runner reads exactly step 1's red set; the pre-verdict arm green |
| 3 | classes 1 and 2, the pipe form (#9250) | the second pass with the redirection join and the joined readings on, the completion discipline, the stand-down with its warn-log record and the canary gate; the reading-off, superset and injection copies; the two flipped pins re-expressed; the two continuation pairs re-pointed; the GHSA suite's old-shape copy of this guard runs with the second pass off | that slice's arms green, every existing arm green |
| 4 | classes 4 and 5, the inverted-mask faces (#9251) | the quote-removed verb comparison, the scanner repair and the mask-free reading switched on, with their off copies; the unavailable-mask pin's exit pair re-pointed | as above |
| 5 | process substitution (#9252) | the process-substitution carry and its case rule switched on, with their off copies, the case pairing arm and the pinned residual | every arm green; the full runner at or above the floor |
| 6 | documents (#9253) | the three fragment edits, with the classifier anchor phrases byte-intact; the registry regenerated by `core/deploy/tools/build-hook-registry.py`, never hand-edited; the moved process-catalog citations rewritten in the same commit with a pre/post sweep | `check-registry-currency.sh`, `check-citation-anchors.sh` and Check 14 clean |
| — | Phase C | the Change Description, the Documentation Impact rows, the Verification Evidence, the full runner at the final head | the floor met |

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | 9 Plan Review | 10 / 11 | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|
| #8547 | **APPLY** (run, then revision 1 after the adversarial review and the Phase B ruling) | APPLY | **APPLY.** Functional change to a security guard; the suite runs in both layouts, and both hook-harness CI jobs are read | **APPLY.** Six positions × two verb classes, per-criterion verdicts | APPLY (Deep, by class) | **COMPRESS** (git-native release: the PR diff is the dry run) | APPLY | APPLY |

## Contention Map

**Within the release:** one card, so no within-release contention.

**Cross-release, at the A4 baseline** (`8ed5e273`, 2026-11-28T00:02:51Z), carried from Stage 4:

| Other work | Overlap with this release | Overlap class | Resolution |
|---|---|---|---|
| Milestone 449 `worktree-sessions-reach-in-repo-homes` (#8019) | no shared source file; its hook edit regenerates the same generated registry, and both regenerations move the same process-catalog citations | line-range-overlap on a generated file | merge order: this release first; the second to merge re-syncs, regenerates with the builder and re-rewrites the citations — never a hand merge of the generated file |
| #8836, #8837 (unmilestoned) | the same guard file; the canonicalizer is shared | planned-later | this release merges first; their Stage 4 re-baselines against this release's merged guard |

## Cross-PR Overlap Audit

### Baseline SHA

`8ed5e273` (`origin/main`, 2026-11-28T00:02:51Z). Open-PR contention at the baseline: none. Recently-merged contention on the write set: the guard's last five commits, all on `main` at the baseline and part of the measured blob `589b114d`.

### In-Flight Release Roster

**Measured at:** `8ed5e273` · `2026-11-28T00:02:51Z` · **Population:** n=0 sibling(s) in flight at the Stage-4 baseline (0 open PRs, 0 remote `release/*` heads). **Re-read at Engineering Commit 0 (2026-11-28, before 06:38Z):** three sibling `release/*` heads are now on the remote — `issue-body-is-the-scope-of-record`, `rollups-select-projects-by-portfolio` and `worktree-sessions-reach-in-repo-homes` (the last is milestone 449 above). The two others carry an ADR at the same detected number this release uses (each a branch-only claim; the number binds at merge and a collision is reconciled at the Stage-12 claim by `renumber-adr.py`, R-S6). Stage 9 Phase A6.6 re-measures this population before GO.

## File Change Matrix

There are **5 EDIT rows and 2 ADD rows** that are unconditional (the GHSA long-input suite promoted from its conditional row in the slice that delivers it), plus CONDITIONAL rows. No row is a delete. The mover set is empty.

```
# ── release-wide (always delivered) ──
core/hooks/block-fs-boundary.sh  EDIT
core/hooks/tests/block-fs-boundary.test.sh  EDIT
core/rules/bypass-mode-readiness/block-fs-boundary.md  EDIT
core/rules/bypass-mode-readiness.md  EDIT
release/releases/plans/fs-boundary-judges-every-listed-verb-operand_RELEASE_PLAN.md  ADD
core/ADRs/ADR-242-fs-boundary-second-pass-reads-skipped-operands.md  ADD
core/hooks/tests/ghsa-xxjm-long-input-matchers.test.sh  EDIT
# ── CONDITIONAL ──
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/lib/command-position.awk  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/block-destructive.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/block-egress.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/block-rm-prefer-trash.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/tests/command-position-fp-control.test.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/tests/block-destructive.test.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/tests/block-egress.test.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/tests/block-rm-prefer-trash.test.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/hooks/tests/hook-fail-closed.test.sh  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/rules/bypass-mode-readiness/_cross-cutting.md  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/rules/bypass-mode-readiness/block-destructive.md  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/rules/bypass-mode-readiness/block-egress.md  EDIT
CONDITIONAL:FIX-IN-CANONICALIZER core/rules/bypass-mode-readiness/block-rm-prefer-trash.md  EDIT
CONDITIONAL:REGISTRY-LINES-SHIFT core/process-catalog/engineering-harness/flip-gate-to-enforce.md  EDIT
CONDITIONAL:REGISTRY-LINES-SHIFT core/process-catalog/engineering-harness/graduate-gate-modes.md  EDIT
CONDITIONAL:REGISTRY-LINES-SHIFT core/process-catalog/engineering-harness/review-warn-log-drains.md  EDIT
CONDITIONAL:NEW-SUITE-FILE core/hooks/tests/*.test.sh  ADD
```

How each conditional row stands after Stage 5 (revision 1, Fired CONDITIONAL rows), and the rules for generated and read-only files:

- **Generated file.** `core/rules/bypass-mode-readiness.md` is generated from the fragments by `core/deploy/tools/build-hook-registry.py` and is never hand-edited.
- **`STAGE5-ADR` fired** and is promoted to the unconditional ADR row above at this commit (DEV-1).
- **`MATCHER-SHAPE` fired** on a broader trigger than its text states, a Tier 1 [ADJUST] by the operator's recorded determination: `matches()` is unchanged, but the GHSA suite's old-shape copy of this guard must also run with the second pass off. Promoted to the unconditional rows in the commit that delivers the edit (DEV-2).
- **`REGISTRY-LINES-SHIFT` fired** by Stage 5's prediction, and was measured in the documents commit not to move any citation: the fragment's edits replace text inside two existing lines, so the regenerated registry keeps its line count and every cited line its number. The three process-catalog files are not delivered (DEV-12).
- **`FIX-IN-CANONICALIZER` and `NEW-SUITE-FILE` did not fire** (DEV-4): no canonicalizer edit, and the new arms go in the existing suite to reuse its helpers.

**Read-only inputs (NOT EDITED):** `core/hooks/lib/command-position.awk` (run unchanged on transformed copies of the command); the guard-local walks in `core/hooks/block-rm-prefer-trash.sh` and `core/hooks/block-destructive.sh` (precedent sources); `core/hooks/tests/setup-ci-layout.sh` and `core/hooks/tests/test-runner.sh` (the harness); `core/hooks/tests/linux-known-failures.txt` and `core/hooks/tests/fixtures/walk-payload-corpus.txt` (outside the matrix; a known-failures row would be a Tier 2 [SCOPE CHANGE]); the deployed hook tree (refreshed by the operator at Stage 12).

**Domain classification** (A3, from the matrix): every row is internal hook code, its suites, its readiness text, a generated registry, cited process pages or a decision record. The dominant class is software; every file is internal, so sourcing is exempt.

## Agent-Editability Read

Carried from Stage 4 (controls read at `8ed5e273`): no write-set path intersects the Tier-0 floor, and no path is under the sanctioned-session gate (conjunct 1 is false for every path). Every row is **unconstrained**, executed by an ordinary Engineering spoke; the generated registry is written only through its builder. The fragment's deployed mirror under the workspace-root rules directory is floored and is laid down by the operator's deploy at Stage 12, never by an agent write.

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner stage |
|---|---|---|---|---|---|
| R-01 | Canonicalizer blast radius | — | — | retired by design: the canonicalizer is not edited (D-S1); its three sibling suites are unchanged on the prototype | 5 |
| R-02 | Over-block | Medium | Medium | near-miss arms at all six positions with an emptied-allowlist reach pairing; the differential; the declared here-document body over-block accepted by D3, read in the warn-mode shakedown before any flip | 5, 8 |
| R-03 | Test-pin re-expression | Certain | Medium | the two expansion-bearing pins at the redirection and continuation positions are re-expressed as refusals in the GREEN commit that flips them (D-S10, DEV-5); their copies re-keyed; the two copies that existed only for their record dimension removed | 6, 7 |
| R-04 | Process substitution has no precedent | Medium | Medium | sequenced last; case-aware body count; one declared, pinned residual | 5, 6 |
| R-05 | Generated registry and line citations | Near-certain | Low | the documents commit rewrites the moved citations with a pre/post sweep | 6 |
| R-06 | The sibling merges first | Medium | Low–Medium | re-sync with `git merge origin/main`, regenerate the registry, rewrite the citations, re-run the full suite in both layouts | 9, 12 |
| R-07 | Downstream rebase cost (#8836, #8837) | Certain | Low | merge order fixed: this release first | — |
| R-08 | Shared provisional version slot | Medium | Low | the Commit-0 re-verify and the atomic claim arbitrate | 6, 12 |
| R-09 | Hook cost: a slow hook fails open | Low | High | the second pass adds canonicalizer runs only on triggering shapes (at most six), each over a copy no longer than twice the command; a ratio arm and a 160 KB arm hold the multiple; the second pass starts after every first-pass verdict, so a timeout can lose only an added refusal | 5, 7 |
| R-10 | Class 5 on the canonicalizer's fail direction | — | — | closed on this guard by the scanner-repair and mask-free readings (D2 of the Phase B ruling) | 5 |
| R-11 | Rollback has two steps | — | — | Rollback Strategy below | 12 |
| R-12 | The sibling's harness overlap is unconfirmed | Low | Low | re-read the sibling's File Change Matrix when it posts | 9 |
| R-S1 | Contention: milestone 449 regenerates the registry first | — | Low | as R-06 | 9, 12 |
| R-S2 | The declared body over-block fires in the shakedown | — | Low | the `INPUT-NOT-EVALUATED` and `-001`/`-002` rows are read before any flip; a second-pass-only quoted-body exemption is the follow-up | 13 |
| R-S3 | A deployed copy out of step after a revert | — | Low | the carrier refresh plus Check 79 | 12 |
| R-S4 | The Linux job (bash 5, gawk) reds a new arm, the injection arms in particular | — | Medium | fix the arm or the mechanism; a known-failures row is Tier 2 | 7 |
| R-S5 | Cost on a large command carrying several triggering shapes | — | Low | the ratio and 160 KB arms; reuse of the first pass's canonical text; the single-byte neutral map | 7 |
| R-S6 | ADR number: a sibling claims the detected slot first | Medium | Low | the number binds at the Stage-12 claim; a collision is renumbered losslessly; prose cites the slug token | 12 |

## Cross-Issue Acceptance Criteria

None. A Cross-Issue Acceptance Criterion spans two or more issues, and this release has one: the population enumerated was {#8547}, so no cross-issue cohesion constraint exists.

## Verification Plan

**AC baseline.** #8547 carries **6** criteria, read at plan time against `8ed5e273` (issue revision 2026-11-22T00:14:02Z) and re-read at Engineering Commit 0: still 6. A count that no longer matches 6 is the signal to re-bind the rows below.

**Suite floor — where it lives and what it is.** "Documented floor" has no standing home in the hook, the suite, the runner or the fragment, so this plan is the floor's record. The floor is **0 FAIL, and an AGGREGATE at or above the count the full runner reads at Engineering Commit 0**, in both layouts.

- **Engineering Commit 0 reading** (the checkout-site layout built by `bash core/hooks/tests/setup-ci-layout.sh` from the worktree root, then `bash .claude/hooks/tests/test-runner.sh`, at `8ed5e273`): `AGGREGATE: PASS=5446  FAIL=1`, runner exit 1, over 30 suites, 2026-11-28 06:39Z → 07:35Z alongside other sessions' runners; `block-fs-boundary.test.sh` read 322 of 322. The one FAIL, `LAYOUT-FRESH-01` in `setup-ci-layout.test.sh`, was this spoke's own interference with the reading, not a property of the Commit-0 tree: a source suite file the layout copies was overwritten while the runner ran, and git-ignored probe files sat in the layout's tests directory. With the source restored and the probes moved out, that suite reads 32 of 32 on the Commit-0 tree. **The binding floor is AGGREGATE ≥ 5447 with FAIL = 0**: 5447 is the arm count this runner read, and equals Stage 4's provisional pre-change reading (5447 PASS, 0 FAIL). Every later runner reading is taken with no source edit and no probe file in the layout while it runs.

**Two-layout requirement at Stages 7 and 8.** The full suite runs twice, and both runs must meet the floor: (a) the sandboxed CI layout, read from the PR's `install-tests.yml` hook-suite jobs (macOS and Linux) unless a sandbox is placed at an allowlisted site; (b) the checkout layout, run agent-side. A red timed arm is read with its measured time and the host load before it is called a flake. If milestone 449 merges first (R-06), this release re-syncs, regenerates the registry, rewrites the moved citations and re-runs both layouts before Stage 9.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8547 | AC-1 | `grep -c -F "FSB-POS1-" core/hooks/tests/block-fs-boundary.test.sh` at least 24 | one line per class-1 form: the 20 redirection operators carrying an ampersand (bash and zsh, `!` twins included), a named descriptor, the leading form bare, after and before a wrapper, and the form after a misread shift; each form expanded across the four verb roles and both sides in the corpus, two roles pinned per form; red at the RED commit, refused under -001/-002 with one block record from the slice that lands the redirection join; graded by the suite in both hook-harness jobs |
| #8547 | AC-2 | `grep -c -F "FSB-POS2-" core/hooks/tests/block-fs-boundary.test.sh` at least 10 | one line per class-2 form, the comment-before-a-continuation form among them; the must-not-refuse comment-ending-in-a-backslash shape is its own arm (FSB-NM-commentcont); red at the RED commit |
| #8547 | AC-3 | `grep -c -E "FSB-POS[45]-" core/hooks/tests/block-fs-boundary.test.sh` at least 36 | 16 class-4 forms and the class-5 grid: five prefix runs, a `then` keyword and three quoted prefix runs, each across the four desync sources, plus the quoted-verb, leading-redirection and two further-mark forms; red at the RED commit; no class-5 residual |
| #8547 | AC-4 | `grep -c -E "FSB-POSP[RS]-" core/hooks/tests/block-fs-boundary.test.sh` at least 23 | the pipe-carrying forms (bash and zsh) and the process-substitution forms, both case forms among them; the case-subject residual is pinned admitted (FSB-PS-CASE-RESID); red at the RED commit |
| #8547 | AC-5 | `grep -c -F "FSBDIFF-" core/hooks/tests/block-fs-boundary.test.sh` at least 7 | the recorded-verdict differential: ROWS, REC-PRE, REC-POST, NOMOVE (criterion 5's zero), DECLARED and the seeded-copy controls; the near-miss twins (FSB-NEAR*) with their emptied-allowlist pairing and the must-not-refuse shapes (FSB-NM-*) · control: FSBDIFF-DET-fires reports a seeded refusal-to-admit move |
| #8547 | AC-6 | declared, verification deferred to core/rules/bypass-mode-readiness/block-fs-boundary.md (the G2 coverage boundary names all six positions as examined), core/deploy/tools/check-registry-currency.sh (the generated registry is current) and core/hooks/tests/test-runner.sh (the full suite at the floor above, both layouts) | the fragment states the measured reach; the registry check is clean; the runner reports 0 FAIL with an AGGREGATE at or above the Commit-0 count |

**Re-binding.** Rows AC-1..AC-5 were re-bound in the RED commit, which names the arms, to label-presence probes over the suite; the suite's own CI run in both hook-harness jobs grades the arms' behaviour. AC-6 stays declared-deferred to the documents commit and the final runner reading. Amending a criterion obliges updating its bound row in the same change.

**Release-level verification.** `release/tools/verify-release-plan.sh` on this file; `core/deploy/tools/check-registry-currency.sh`; `core/deploy/tools/check-citation-anchors.sh`; the doc-link check (Check 14) over the changed markdown; the full hook runner at the final head against the floor; both hook-harness CI jobs read, with a red Linux arm fixed in the arm or the mechanism, never by a `linux-known-failures.txt` row.

## Delivery Strategy · Rollback Strategy

- **Delivery.** One branch, one PR titled `release(fs-boundary-judges-every-listed-verb-operand): …`, opened in draft right after this commit so every later commit gets its own CI run. Its body's Issue References block carries the one closing reference for #8547, and nowhere else does a close-family verb meet an issue number. Commits are signed, slug-prefixed and carry the work item as the trailing `(#8547)`; the commit-message close-keyword check runs before every push, and every push uses the detached-HEAD refspec. Merge at Stage 12 under the atomic version claim, after CI is fully green: never `--admin`, never red. The operator refreshes the deployed hook tree from their own terminal at Stage 12 (`docs/scripts/setup-workspace.sh --refresh-hooks`, which has no agent-invocable allowlist row); the hub then verifies Check 79 (deployed equals source).
- **Per-slice rollback, before merge.** Revert one commit; a GREEN slice's arms then read red again by design. The fragment and the registry are regenerated in the same revert.
- **Whole-release rollback, after merge.** Revert the merge on `main` through a revert PR; the operator re-runs the carrier, or `--restore-hooks` to the pre-release generation; the hub re-verifies Check 79. The version tag is retained and the rollback recorded (Tag Retention).
- **Reversibility.** MODERATE overall, because of the deployed-copy second step; CHEAP per slice before merge; each reading has a one-line off switch and the second pass as a whole has one. Confidence HIGH.

## Quota Budget

- **Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A).
- **Parallel-eligible spokes per parallel stage** (from the Stage Applicability Matrix): Stage 5: 1 · Stage 7: 1 · Stage 8: 1. Every launch is a singleton.
- **Per-spoke cost estimate:** the `size:L` ordinal band (moderate–high), from the size-bucket heuristic; no telemetry medians exist for this bucket.
- **Assumed remaining usage-window envelope:** not stated at hub start, so the conservative default applies. A singleton batch cannot reach the 50 % band on the ordinal heuristic. [ASSUMPTION – CONFIRM: no absolute figure exists until telemetry medians do]
- **Note.** Checkpoint B re-validates at every `Agent`-tool launch and gates the host-API axis at runtime; three same-day hubs share one account window, which only Checkpoint B can see. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Release Outcome Statement

**AFTER** — The filesystem-boundary guard examines the operand of each of its listed read and write verbs at the six command positions where it did not, so an out-of-root literal path there is refused at enforce and recorded at warn, exactly as at the head of a command. In-root paths at those positions stay admitted, and the readiness fragment states the reach as measured.
**BEFORE** — At six positions (after a redirection carrying an ampersand or a pipe, on a continuation line, after a process substitution, with the verb quoted, and behind a prefix word while an unbalanced quote switches the canonicalizer off), an out-of-root literal operand of a listed verb passes with no refusal and no record, at every mode.
**Actor(s):** hub + Standard-density spokes (Stages 5–8)
**Success Indicator:** at Stage 13, the guard's suite carries a red-before arm per position and verb class, each refused on the merged hook, with the full hook suite at 0 FAIL in both layouts.
**Limb owners:** examined at the six positions → #8547 · in-root near misses stay admitted → #8547 · readiness fragment states the measured reach → #8547

## Release Class declaration

**`novel`** (D-ReleaseClass, rendered at the Stage-4 gate). `routine` fails its own trigger (a P1, size:L card); `hotfix` is a misfit (a pre-existing defect, and Light Stage-9 review is thin for a security-guard change); `cross-cutting` does not fire. Differentiation posture: engagement density **Standard**; Stage 9 review depth **Deep**; Stage 5 activation bias **ALL**; Stage 13 outcome window **30-day**.

## Operator Decisions (D-Gate Block)

Rendered at the Stage-4 gate (2026-11-28) on the Stage-4 plan's D-Gate block:

- **D-ReleaseClass** — (B) `novel` (recommended). Reversibility CHEAP / Confidence HIGH.
- **D-Version** — a recorded determination, not a gate: bump class `minor`, provisional next-free `v5.15`; re-verified at this commit.
- **D-C Branch Topology** — a recorded determination: SINGLE.
- **D-Concurrency Posture** — recorded at the undeclared default: P0, fully serial.

The Stage-5 open questions (the fix location per position, one build or two, the process-substitution boundary, the letter-case face) were Stage 5's decisions, settled in revision 1: all six positions guard-local in an add-only second pass (D-S1); one build (D-S2); the case-aware crossing rule (D-S3); the letter-case face stays with #8837 (D-S4).

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-28)

Recorded on #9148: **D1** the release plan approved as written; **D2** D-ReleaseClass `novel`; **D3** the Release Outcome Statement draft approved as written. Per-card disposition: #8547 carried. Recorded determinations: D-Version minor (`v5.15` provisional), D-C SINGLE, D-Concurrency P0; Stages 7 and 8 run the hook suite in both layouts.

### Stage 5 Phase B design sign-off (operator, 2026-11-28)

Recorded on #9188: **D1** revise the design first (one Stage 5 revision folding in the adversarial dispositions; Stage 6 builds from that single specification); **D2** close both the class-5 residual and the adjacent balanced-but-inverted quote-mask face on this guard, with a card on the shared canonicalizer's scanner for its other consumers recorded for the Stage 9 filing step; **D3** accept the quoted here-document body reading as a declared over-block (warn-mode shakedown first); **D4** accept the structural blast-radius tier with the Stage 5 content triage. Recorded determinations: `MATCHER-SHAPE` fires on a broader trigger and is a Tier 1 [ADJUST] recorded in this Deviation Log; a verb word only an evaluation produces stays a declared limit; the scanner card, the separate-word redirection target, the first pass's walk read with no completion line, and the partially quoted prefix word are held for the Stage 9 filing step. The hub determined that revision 1 needs no second adversarial review.

## Deviation Log

| ID | Stage | Deviation | Decision |
|---|---|---|---|
| DEV-1 | 6 | `CONDITIONAL:STAGE5-ADR` fired and is promoted to `core/ADRs/ADR-242-fs-boundary-second-pass-reads-skipped-operands.md ADD` at this commit. The number is `renumber-adr.py --detect`'s NEXT-FREE, re-run immediately before creation (`ANCHOR 241`, `NEXT-FREE 242`; on this tree the file reads `BINDS`, and the same file at 243 reads `WOULD-GAP`). Two sibling release branches each carry a branch-only claim on 242; the number binds at merge and a collision is reconciled at the Stage-12 claim (R-S6) | Stage 5 revision 1, Fired CONDITIONAL rows |
| DEV-2 | 5 → 6 | `CONDITIONAL:MATCHER-SHAPE` fires on a broader trigger than its text states: `matches()` is unchanged and still carries exactly one here-string matcher line, but the GHSA long-input suite's old-shape copy of this guard must also set `readonly FSB_PASS2=1  # M-FSB-PASS2` to `=0`, because the second pass refuses the long form without `matches()`. The path is a declared row, so the write set does not grow. **Tier 1 [ADJUST]**; promoted in the commit that delivers the edit | operator, Stage 5 Phase B recorded determination |
| DEV-3 | 5 → 6 | `CONDITIONAL:REGISTRY-LINES-SHIFT` fired: the restated coverage boundary changes the fragment's length, so the process-catalog citations after this guard's registry section shift. Promoted in the documents commit | Stage 5 revision 1 |
| DEV-4 | 5 | `CONDITIONAL:FIX-IN-CANONICALIZER` (13 rows) and `CONDITIONAL:NEW-SUITE-FILE` did not fire: no canonicalizer edit (D-S1), and the new arms go in the existing suite to reuse its helpers. NOT DELIVERED: the conditional new-suite row `core/hooks/tests/*.test.sh` (no new suite file is added) | Stage 5 revision 1 |
| DEV-5 | 5 → 6 | **D-S10:** the two pins that flip with the fix (`XFORM-POS-03` and `XFORM-POS-04`, an expansion-bearing operand at the redirection and continuation positions) are re-expressed as refusals in the GREEN commit that flips them, not in the RED commit Stage 4's sequence named. **Tier 1 [ADJUST]** | Stage 5 revision 1, D-S10 |
| DEV-6 | 5 → 6 | FM-5's "name the stand-down record where the flip decision reads" is met in the guard's own readiness fragment, which the cross-cutting Shakedown checklist's fs-boundary row already points the reviewer to; `core/rules/bypass-mode-readiness/_cross-cutting.md` and `core/hooks/tests/hook-fail-closed.test.sh` stay unedited (both are `FIX-IN-CANONICALIZER` rows only) | Stage 5 revision 1, Fired CONDITIONAL rows |
| DEV-7 | 6 | The out-of-root operand of every new arm is `/opt/other/notes.txt`, not the other-user home path `xform_shape`'s liveness check uses: the repository's pre-commit PII guard refuses a newly added `/Users/<name>/` shape in any added line, and the suite's EXT-POS arms already use this operand for the same reason. **Tier 1 [ADJUST]** | Engineering, recorded determination |
| DEV-8 | 6 | The differential's table carries two columns beyond the seven revision 1 names (id, position, role, side, pre, post, command): a tag (`over` for the declared over-block, `sepredir` for the superset's designed exception) and the pinned roles. A position form is one line expanded at load across the four roles and both sides, its `pre`/`post` stated once per form (one value, four per-role values, or `P` for the plain rule); the explicit rows carry the faces, breadth and here-document rows. `FSBDIFF-ROWS` reads the expanded rows. Each row is run once per copy, and the arms read those observations; the two copies of the shipped hook the passes run through are asserted byte-identical to it. **Tier 1 [ADJUST]** | Engineering |
| DEV-9 | 6 | Two class-2 forms (a wrapper continued before the verb, and a wrapper's option continued) are already examined by the first pass (the verb starts a physical line), so they are corpus rows recorded refused before and after and carry no pin; every pin is a row the pre-fix hook admits, so the RED commit's pins are red. **Tier 1 [ADJUST]** | Engineering |
| DEV-10 | 6 | The XFORM section's closing RESIDUAL line counted four positions the token walk never examines; from the slice that lands the redirection join and the joined readings, two of them (the expansion-bearing pins at those positions) are refused, so the line counts two positions neither pass examines. Revision 1's sweep did not list that line. **Tier 1 [ADJUST]** | Engineering |
| DEV-11 | 6 | zsh's `=verb` spelling of class 4 closes in the slice that lands the second pass, not in the class-4 slice: the walk drops one leading `=` before the verb lookup whether or not the quote-removed comparison is on, as the measured prototype does (its quote-removal switch-off reopens the quoted forms, not this one; the `=`-strip copy is what reopens it) | Engineering, recorded |
| DEV-12 | 6 | `CONDITIONAL:REGISTRY-LINES-SHIFT` fired by prediction but moves no citation: the three fragment edits replace text inside two existing lines of the fragment, so the regenerated registry is 1036 lines before and after and differs only on those two lines (531 and 549); each of the eight process-catalog line anchors resolves to the same content before and after (pre/post sweep: 6 distinct cited lines, 8 anchors, 0 moved). NOT DELIVERED: `core/process-catalog/engineering-harness/flip-gate-to-enforce.md`, `core/process-catalog/engineering-harness/graduate-gate-modes.md`, `core/process-catalog/engineering-harness/review-warn-log-drains.md` (no citation to rewrite). **Tier 1 [ADJUST]** — the write set shrinks | Engineering, measured |

## Verification Evidence

### Slice gates

Each gate ran the runner (`bash .claude/hooks/tests/test-runner.sh`) on the default-site layout rebuilt by `bash core/hooks/tests/setup-ci-layout.sh` from the slice's tree, with the suites outside the slice moved out of the layout's tests directory for that run. The runner forwards only FAIL lines, so a slice's red set is read by label.

| Slice | Commit | Gate the slice owes | Reading |
|---|---|---|---|
| C0 | `699a9f1a` | stamp manifest; the floor | `verify-stamp OK`; full runner 5446 PASS / 1 FAIL, the one FAIL this spoke's own mid-run interference (§ Verification Plan); binding floor 5447 with 0 FAIL |
| C1 RED | `0c5628cc` | new position, inverted-mask, near-miss-pairing, post-verdict and cost arms red; must-not-refuse and existing arms green | guard suite 1090 arms: 606 PASS, 484 FAIL, every FAIL a new FSB-* or FSBDIFF-REC-POST arm; 0 existing arms red; FSBDIFF-REC-PRE, -ROWS, -NOMOVE, -DECLARED and the seeded-copy controls green; the SIGPIPE-idiom gate's own script over the delta: clean |
| C2 refactor | `7afce5a2` | exactly C1's red set; REC-PRE green | 1090 arms: 606 / 484, the red set identical to C1's by label |
| C3 | `f13e60df` | the slice's arms green, every existing arm green | guard suite 1410: 1118 PASS / 292 FAIL, the remaining red only class 4, class 5 and process-substitution arms, the inverted-mask and five adjacent faces, two cost arms and REC-POST; 0 existing arms red (the re-expressed pins and re-pointed pairs included); GHSA long-input suite 37 / 37 |
| C4 | `27e78123` | as above | guard suite 1490: 1437 / 53, the remaining red only the process-substitution arms and REC-POST |
| C5 | `6b2aad1e` | every arm green | guard suite 1506 / 1506; false-positive control 198 / 198; GHSA long-input 37 / 37; fail-closed 75 / 75 |
| C6 documents | the documents commit | registry, citations, doc links; the classifier arms on the new text | `build-hook-registry.py --check` in sync; `check-registry-currency.sh` 0 FAIL; `check-citation-anchors.sh` 0 findings; the doc-link check over the changed markdown 0 broken; guard suite on the new fragment and registry 1506 of 1506 (the XFORM-DOC and MODEOFF-REC classifiers read the new fragment and registry) |

### C4 self-verification

- **Plan verifier.** `release/tools/verify-release-plan.sh` on this file: 12 PASS, 0 FAIL, 2 SKIP, 0 ERROR over 14 records — AC-1 to AC-5 PASS on their label-presence probes, AC-6 declared-deferred to the final runner, FCM-COVERAGE and FCM-1 to FCM-3 PASS, the provenance label PASS, PROV-DELTA SKIP (no Stage 4 comment supplied).
- **Registry and citations.** As in the C6 row; the eight process-catalog line anchors into the registry resolve to the same six lines before and after the regeneration (DEV-12).
- **Final full runner.** Read at the final head after this commit, in the checkout-site layout with no source edit and no probe file in the layout while it ran; its AGGREGATE is recorded in the pull request's Verification Evidence and in the Stage 6 output comment, against the floor above.
- **Sync (C3): N/A for an agent.** The deployed hook tree and the deployed rules mirror are refreshed by the operator at Stage 12 (`docs/scripts/setup-workspace.sh --refresh-hooks`, which has no agent-invocable allowlist row, and `./deploy.sh --deploy`); the hub then reads Check 79.
- **Deliverable state.** The guard, its suites, its fragment and the registry: `deployed-copy-synced`, the propagation owned by the Stage 12 operator refresh. `core/ADRs/ADR-242-fs-boundary-second-pass-reads-skipped-operands.md`: `artifact-accepted` — Artifact-Acceptance Record: the record exists at its canonical path on the release branch with `status: Proposed`; acceptance is its Stage 13 ratification.
- **ADR index: N/A** — this release adds no record under `release/ADRs/` (its record is under `core/ADRs/`, whose README has no projector).
- **Skill packages: N/A** — the full write set, piped to `build-skill-packages.sh --skills-for-paths` on stdin, names no skill (control: a release skill's `SKILL.md` names that skill).
- **Runtime-suite event.** The runtime suite for this change is the hook harness; its readings are the rows above and the final runner. The `test-run` event row lives in the operator-instance pipeline event log, which this worktree session does not write; the hub emits it from this record.

## Change Description

### Outcome

The filesystem-boundary guard (`core/hooks/block-fs-boundary.sh`, BLOCK-FS-BOUNDARY-001 and -002) now examines a listed read or write verb's operand at six command positions where its token walk never handed the operand over: after a redirection operator that carries an ampersand, on a continuation line, with the verb word written in quotes, behind a listed prefix word while an unbalanced quote switches the shared canonicalizer off, after a redirection operator that carries a pipe, and after a process substitution. An out-of-root literal operand there is refused under the plain form's rule at `enforce` and recorded at `warn`, as at the head of a command; the in-root twin stays admitted. It does this with an add-only second pass that runs after every first-pass verdict, so it can only add a refusal or a record.

### Issues resolved

| # | Outcome | Status |
|---|---|---|
| #8547 | All six positions refused under `-001`/`-002` with one record, each beside a copy of the hook whose reading is off; the in-root twins admitted; a verb at a plain command start hidden by an inverted quote mask closed on this guard too; zero refuse-to-allow movements in the suite's recorded-verdict differential; one declared, pinned residual (a `case` inside a process-substitution body whose subject holds a quoted blank) | DONE (residual for the Stage 9 GO) |

### Key decisions

- **Design B, add-only second pass, guard-local** (Stage 5 D-S1, signed off at Phase B): the shared canonicalizer is run unchanged on transformed copies of the command, so no other consumer's verdict moves; the first pass's lines are byte-identical where the suite keys on them.
- **Completion is proven, not inferred** (D-S12, the Phase B ruling's scope): one command substitution with errexit re-armed, flag-checked helpers, a counted header on the walk's input, a completion line printed last; a reading that does not complete is refused at `enforce` and, at `warn`, stands down with an `INPUT-NOT-EVALUATED` warn-log record.
- **Close both unbalanced-quote faces here** (Phase B D2): the scanner-repair reading on its shape trigger and the mask-free reading under its original gate; the canonicalizer scanner card for its other consumers is held for the Stage 9 filing step.
- **Here-document body over-block accepted** (Phase B D3), read in the warn-mode shakedown before any flip.
- **Structural blast-radius tier accepted** with the Stage 5 content triage (Phase B D4).
- **The GHSA long-input suite's old-shape copy runs with the second pass off** (the recorded `MATCHER-SHAPE` determination, Tier 1 [ADJUST], DEV-2): `matches()` is unchanged, and the arm then reads the matcher alone.
- **Pins that flip are re-expressed in the commit that flips them** (D-S10, Tier 1 [ADJUST], DEV-5): `XFORM-POS-03` and `-04` became refusals at G2 under `-003` in the redirection-and-continuation slice, each paired through the copy whose reading is off.

### What the suite now holds

- 1506 arms in the guard's suite (322 before): a recorded-verdict corpus of 1048 rows — 117 position forms across four verb roles and both sides (936 rows) and 112 explicit rows for the inverted-mask and adjacent faces, the case residual, the must-not-refuse shapes, a breadth sample and the here-document rows — with a pin and a near-miss pin for two roles of every position form the pre-fix hook admits.
- Each reading has a one-line off switch, and a shape-guarded copy with that reading off reopens exactly the positions it serves; five injection copies prove a reading that does not complete is refused at `enforce` and stands down with its record at `warn`.
- Two cost arms hold the second pass's multiple flat across size and two 160 KB refusals inside the suite's budget.

### Reversibility

MODERATE / Confidence HIGH — revert the merge on `main`, then the operator refreshes the deployed hook tree; before merge each slice reverts as one commit, each reading has a one-line off switch, and the second pass as a whole has one.

### Downstream impact

- The cards #8836 and #8837 re-baseline against this merged guard (merge order: this release first); the ADR names the canonicalizer's opt-in view seam as the lift-up path for these readings, owned by the shared-walk card family.
- Milestone 449 (`worktree-sessions-reach-in-repo-homes`) regenerates the same registry after this release merges, and re-checks the process-catalog line citations into it.
- Held for the Stage 9 filing step: the shared canonicalizer scanner card (five scanner-divergence sources), the separate-word redirection target, the first pass's walk read with no completion line, and the partially quoted prefix word; and the process-substitution case residual, which reaches the operator at the Stage 9 GO with a named successor owner.
- The deployed hook tree is refreshed by the operator at Stage 12; the hub then reads Check 79.

### Cross-references

- Release plan: this file (`release/releases/plans/fs-boundary-judges-every-listed-verb-operand_RELEASE_PLAN.md`).
- Milestone: `fs-boundary-judges-every-listed-verb-operand`.
- Decision record: `core/ADRs/ADR-242-fs-boundary-second-pass-reads-skipped-operands.md` (`Proposed`).
- User-facing release notes: authored at Stage 13 under `release/releases/notes/`.
