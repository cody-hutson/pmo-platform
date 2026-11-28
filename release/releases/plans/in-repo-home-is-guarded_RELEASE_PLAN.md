---
title: Release Plan — in-repo-home-is-guarded (the in-repo ignored homes are guarded against a commit, and leak-risk files get one permission policy)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.15, equal to the Stage-4 provisional; the concrete number binds at the Stage-12 atomic claim)
milestone: in-repo-home-is-guarded
release_class: novel
reversibility: MODERATE / Confidence HIGH — one release branch, one pull request and one merge; the required context is de-registered before any revert, then the merge is reverted with a mainline revert; leak-risk modes set by the release stay at the more protective setting; a claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `in-repo-home-is-guarded`

**Milestone:** `in-repo-home-is-guarded` (milestone 450), epic #8005. Three cards: **#8022** (ship `/local-state/` with its README and guard the in-repo homes against a commit), **#8023** (every check that walks the repository tree skips the homes) and **#8024** (one permission policy for leak-risk files, set at install and update and reported by the install validator). The Stage-4 planning sub-task **#9203** carries the approved plan (comment 7233557920, part 1/2, and comment 7233559410, part 2/2) and the Stage-4 gate's Decision Recorded (comment 7234042856). The Stage-5 designs are on **#9205** (#8022), **#9209** (#8023) and **#9213** (#8024); their Phase A6.5 adversarial reviews are on **#9235** (#8022), **#9236** (#8023) and **#9234** (#8024); the Collective Review scope-lock Decision Recorded is on #9205 (comment 7236696308). The Stage-6 Engineering sub-tasks are **#9206** (#8022), with the #8023 and #8024 slices following serially. This file is Engineering Commit 0, landed by the #8022 Engineering spoke.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.15`**, equal to the D-Version determination (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/in-repo-home-is-guarded`, cut from `origin/main` at `8ed5e273`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial**: Commit 0, then the #8022 slice, then #8023, then #8024, each by its own Engineering spoke after the previous one returns. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9203 and is amended, in order, by: the Stage-4 gate's Decision Recorded (plan approved as recommended; D-GuardScope (A); D-RequiredCheck (B); D-ReleaseClass `novel`; D-Version minor as a recorded determination; D-C SINGLE; P0), then the three Stage-5 designs and their adversarial reviews as the Collective Review adopted them, then the Collective Review scope-lock Decision Recorded. Where the plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. The #8022 rows of the File Change Matrix and the Verification Plan are amended to its design's resolved set, the #8023 rows to its Stage-5 inventory as the Collective Review amended it, and the #8024 rows to its Stage-5 design as the Collective Review amended it, each by that card's Engineering spoke. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): hook, check and installer behaviour inside the existing structure, with no new skill and no new governance file. The rule-computed next-free re-verified at Engineering Commit 0 is `v5.15`. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-28 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub, Engineering spokes at Stage 6) |
| **Status** | Executing — Stage 6 Engineering complete for #8022, #8023 and #8024; the release PR stays in draft for Stage 7 |
| **Branch** | `release/in-repo-home-is-guarded` |
| **PR** | opened in **draft** at Stage 6 |
| **Milestone** | `in-repo-home-is-guarded` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-27, domain: software }`

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0: `origin/main` = `8ed5e273`; the highest version tag is `v5.14`.
2. Recomputed next-free for bump-class `minor` through the version-claim adapter (`release/tools/claim-version.sh --bump minor --sha 8ed5e273 --dry-run`): **`v5.15`**.
3. `v5.15` is not in the claimed set (`git ls-remote --tags origin 'refs/tags/v5.15*'` returned nothing) and equals the recomputed next-free: **PROCEED**. The tag arm binds. Four `release/*` siblings are in flight beside this branch (`fs-boundary-judges-every-listed-verb-operand`, `issue-body-is-the-scope-of-record`, `rollups-select-projects-by-portfolio`, `worktree-sessions-reach-in-repo-homes`); a branch carries no claim, and the shared provisional is settled by the Stage-12 atomic claim.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp in-repo-home-is-guarded` — recorded in the Engineering Commit 0 message.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | under § Header |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix (as amended in § Deviation Log) |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan | § Verification Plan |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | Stage 4 `8ed5e273`; branch cut at `8ed5e273` (no window between them) |

## Summary (30 seconds)

- **Verdict: CONDITIONAL.** The plan can be built. Before Stage 5 fan-out the operator needs to confirm one G-PL4 re-scope (#8023) and render two decisions (D-GuardScope, D-RequiredCheck). No premise is rejected and no C3 fired, so there is no Tier 0 hold.
- **#8022 is buildable now and ship-gated on the sibling release** `[SOURCE: the Decision Recorded comment on #9149 and the #8019 Stage-5 design on #9154]`. The ignore pair `/local-state/*` + `!/local-state/README.md` belongs to `worktree-sessions-reach-in-repo-homes` under its operator decision D-LocalState C. That sibling's Stage-5 design also keeps **both** narrower lines in `.gitignore` (`/local-state/telemetry/*` and `/local-state/process-catalog/*`; the card names only one). So this release leaves `.gitignore` alone, and AC-1 becomes a verification row that reads RED (baseline 0) until the sibling's pair reaches this branch. This is a recorded release-gate, not a click-gate (D-HomeOrder below).
- **#8022 has three design facts its body predates:**
  - Git has one pre-commit slot. The installer links it to the PII guard and never replaces a foreign hook.
  - The PII guard has a warn/enforce/off dial, and the new guard must not inherit it.
  - Pre-commit does not run on merge, cherry-pick, rebase or commit-tree. The push-time backstop (`git-pre-push-pii.sh`) arrived in the bundling window. The host stays a Stage-5 decision; both branches are planned.
- **The guard's scope is a judgment call.** The card and ADR-231's class table say the guard covers `/local-state/`. The placement standard's § Protections says "a commit guard … over every registered home". That makes D-GuardScope.
- **"Required" is a host setting** `[SOURCE: main's branch protection, 24 required contexts, none for this job]`. The CI job is planned. Registering its context is an operator step, and the gate-posture reconciler constrains the header posture around it. That makes D-RequiredCheck.
- **#8023's AC-2 carries no control arm, so it can pass while testing nothing.** A static census at `8ed5e273` found no walker run by `deploy.sh --check` that reaches the repository-root homes, and none in the three files the card names `[INFERRED: a pattern census, not an inventory]`. The probe does not see a `find` whose root arrives through a variable, or a walker reached only through a callee. Root walkers do exist outside the deploy checks: the plan verifier's glob-pathspec resolver and the context-budget auditor's agents scan. The re-scope rests on the missing control arm, which holds whatever the inventory finds: **re-scope-changed**, operator confirms.
- **#8024's defect still reproduces, and its evidence is stale** `[SOURCE: mode bits by stat, 2026-11-27]`. The registered scan list now reads 0600 (the card said 0644), as does a second, unregistered one. The roster, its clarification queue and two backups read 0644; `scan.sh` reads 0755. No folder holds only leak-risk content today: the governed home is absent and today's container (0755) is mixed. The standard already names the policy, so the card's Documentation Impact is already delivered.
- **Composition:** 10 raw points, below the 15–25 band. The epic records why this milestone stands alone. Recorded as a finding only.
- **Proposed class:** `novel`. **Version:** recorded determination; WV-1 → `versioned`, bump-class `minor`, provisional display `v5.15`, shared with two minor siblings. **Topology / posture:** SINGLE / P0. **Quota:** WARN, because six hubs share one usage window.

## Phase A0 — Triage→Design Re-Review and stage-entry gates

**G-PL5 cache-read: MISS. Reason: no marker-bearing comment.** Sub-task #9203 had 0 comments at read time, which matches the hub's statement. PT-1..4 ran in full, subsumption included. `rows_source: re-derived`.

**Baseline pin:**
- `origin/main` = release base = `8ed5e273`, read at 2026-11-28T03:46Z (Friday 2026-11-27 local).
- Bundling base `7813457d`: 148 commits and 396 name-status rows to the pin.
- The cards' filing base `35dbf418`: 1,817 commits to the pin.

**Files this plan touches that moved in the bundling window:**
- `core/hooks/git-pre-commit-pii.sh` (+377 lines)
- `core/hooks/git-pre-push-pii.sh` (new, 151 lines)
- `docs/scripts/setup-workspace.sh` (+161)
- `docs/scripts/validate-install.sh` (+148)
- `core/deploy/deploy.sh` (+29)
- `update.sh` (+5)
- `core/standards/gate-efficacy-standard.md` (+5)

Most of this is the PII-guard wiring work (GHSA-c748: the guard wired as pre-commit and pre-push, validate-install A3d/A3e).

### #8022

`issue_number: #8022` · `release_milestone: in-repo-home-is-guarded` · `stage: 4` · `spoke_author: Stage-4 planning spoke (release-planner Mode B)` · `re_review_date: 2026-11-27` · `issue_body_revision: 2026-11-28T00:22:47Z` · `triage_decision_date: 2026-09-28` · `effort_tier: complex` (it reaches three or more governance files)

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC-1: fresh clone has `local-state/README.md`; `git check-ignore` reports `local-state/release-runs/x.md` ignored | `review-discipline-principles.md` § 8 PV-1/PV-2: a verification row needs a baseline that is RED today and a control arm | `[SOURCE: check-ignore and .gitignore at the pin]` At the pin, `git check-ignore --no-index` returns nothing for `local-state/release-runs/x.md` and `local-state/README.md`. `local-state/telemetry/x` matches `.gitignore` L81. Controls `analysis/sub/x` (L173) and `roadmaps/x` (L25) match. Whole-line `/local-state/*` count is 0 (control: whole-line `/analysis/*` is 1). `[SOURCE: #9154 design]` The sibling's #8019 Stage-5 design puts the pair after `!/analysis/README.md` and keeps both narrower lines (its D-3) | The operator's recorded pattern *dependency vs release gate*: separate a build-blocking predecessor from a ship-gating one. The `release-usage-measured-right` plan's deviation DEV-35 held a step because the home was not yet writable, the same ship-gate shape | C2 | AC-1 is graded after `worktree-sessions-reach-in-repo-homes` merges. The Affected Files line "this card may absorb the narrower `/local-state/telemetry/*` line" is foreclosed: there are two narrower lines and the sibling keeps both |
| AC-2: `git add -f` under `local-state/` makes the pre-commit guard fail the commit | DP-8 Security (`build-philosophy.md:53`): a control fails closed when it cannot evaluate its rule | `[SOURCE: setup-workspace.sh, git-pre-commit-pii.sh, git-pre-push-pii.sh at the pin]` `wire_pii_git_hook` links `.git/hooks/pre-commit` to `core/hooks/git-pre-commit-pii.sh` and leaves a foreign hook in place. The PII guard reads a warn/enforce/off dial, warn when unset (S-31). The installer's comment: git runs pre-commit only for `git commit`; merge, cherry-pick, revert, rebase, stash and commit-tree skip it, and `git-pre-push-pii.sh` re-runs the guard with `--commits`. Agents are denied `--no-verify` (BLOCK-DESTRUCTIVE-024); a person is not. Probe: `local-state` appears 0 times in the PII guard (control: `needle` 57), 0 in the pre-push guard, and 0 in any workflow (control: `analysis` in `repo-integrity.yml` 2) | The epic's 2026-10-08 live instance: a session branch on the public remote carried 22 committed files of release working state. The commit path is real. ADR-165 records that a git-hook home already exists in `core/hooks/`, with one install path | C2 | The guard fails whatever the PII dial reads. Add a push-time arm, so a merge or cherry-pick carrying a home file is caught before it leaves the machine. Affected Files gain `core/hooks/git-pre-push-pii.sh` and the two guards' test suites |
| AC-3: a PR adding a non-README file under `local-state/` fails a **required** CI check | `gate-efficacy-standard.md` § Requirement (b): a declaration never claims an enforcement the surface cannot deliver | `[SOURCE: branch-protection read; gate-efficacy § Declared-required contexts]` Main carries 24 required contexts and none for this job. A declaration reading `advisory` is off the registration track; a gate whose registration waits on a decision carries a HOLD row while its header reads `advisory`. The reconciler reads a `required` header on an unregistered context as UNREGISTERED, and a registered context that nothing declares as UNDECLARED. Registration is a repository-settings act no pull request can perform | The SIGPIPE-idiom and PV-7 jobs shipped `advisory` (enforcing, not yet blocking) for the same reason, and their posture notes record it | C2 | Split AC-3 in two. (a) The job fails a fixture PR, reports on every pull request, and declares its posture honestly. (b) The operator registers the context, read back from branch protection. Timing is D-RequiredCheck |
| AC-4: a README-only commit passes guard and check (near-miss) | `review-discipline-principles.md` § 1 Rule 15: the specificity arm must be able to fail | `[SOURCE: #9154 design]` On macOS `core.ignorecase=true`, so the README negation also un-ignores `local-state/readme.md`. The tracked path is exact-case | The sibling's design withholds `README.md` in any case spelling at its hook for the same reason | C2 | Keep the arm. Add a case-variant arm: a commit adding `local-state/readme.md` fails |
| (absent) the guard covers every registered home | `decision-discipline.md` § 2.1 Mechanism 1 (Localization Check): reconcile a card against the governing surface it predates | `[SOURCE: placement standard L127, L263; ADR-231 class table]` The standard § Protections: "a commit guard, at pre-commit and in CI, over every registered home, a forced add included". References: "the commit guard over the in-repo homes". ADR-231 class table: "for `/local-state/`, also a commit guard". The two governing surfaces differ in scope | The card was filed 2026-09-28, before both surfaces (2026-11-05 and 2026-11-07) | C2 | Scope set by **D-GuardScope** |
| (absent) the documentation cascade | `rename-reference-cascade.md` § 3: a stated state is a reference that moves with the state | `[SOURCE: the three files at the pin]` `architecture-overview.md` L147 says the home is "not yet provisioned". Placement standard L127 says "until the guard ships the rule is the only protection". `git-workflow.md` § Repository-Integrity Gates says "the blocking set is the three tabulated below", which goes stale if the context is registered | `[SOURCE: #9154 design]` The sibling's design keeps the L147 line explicitly for #8022 | C2 | Add these rows to the File Change Matrix (L127 and L263 are shared with the sibling; see Contention) |
| (absent) the draft-file controls | `failure-mode-standard.md`: a control's firing on a sanctioned shape is a named, expected event, not a surprise | `[SOURCE: block-draft-files.sh L48; repo-integrity.yml draft-file job]` `local-state/README.md` sits outside the governed roots `^(core\|release\|operations\|packages\|docs\|\.github)/` that BLOCK-DRAFT-001 (warn) and the CI Draft-file gate (`WARN_MODE='true'`) admit. Neither admits `analysis/README.md` or `roadmaps/README.md` either | The two existing home READMEs are tracked, so the gate's added-file scope never re-reads them; a new one is read | C2 | Expected warn-mode firing. A CONDITIONAL row admits registered-home READMEs in both controls; otherwise it is an accepted residual (see Recommendations) |
| Risk: a guard that also blocks README edits | Rule 15: the near-miss is the specificity arm | The fourth criterion's near-miss covers it | The roadmaps home's arm in the sibling's hook withholds its README for the same reason | C1 | — |

### #8023

`issue_number: #8023` · `release_milestone: in-repo-home-is-guarded` · `stage: 4` · `spoke_author: Stage-4 planning spoke (release-planner Mode B)` · `re_review_date: 2026-11-27` · `issue_body_revision: 2026-11-21T23:45:38Z` · `triage_decision_date: 2026-09-28` · `effort_tier: standard`

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| Description: "checks that walk the tree with `find` or a recursive grep would read every file in `/local-state/`" | `decision-discipline.md` § 2.1.1: re-verify a snapshot premise against live state before planning around it | `[INFERRED: a static pattern census at 8ed5e273, R-W1 to R-W7 in Evidence; not an inventory]` <br>• The 11 `find`-from-root constructs run inside a temp or package directory, at `-maxdepth 1`, in CI only, or once in `release/tools/verify-release-plan.sh` (`cd "$REPO_ROOT" && find . -path ./.git -prune -o -path "./$pat" -print`, the scope-assertion glob resolver). <br>• There are 0 recursive greps from the root. <br>• The two recursive globs are Checks 42 and 50, each bound to module subtrees. <br>• The three shared corpus walkers (`compose-portfolio.py`, `stamp-node-frontmatter.py`, `build-doc-index.py`) scan a `--root` they are given (the projects tree by default for the stamp tool), and `deploy.sh` invokes none of them (0 call sites; control: `check-doc-links.py` 3). <br>• The enumeration-drift, mirror-pair-parity and selftest-coverage tools read `git ls-files` under a git root and walk only a non-git root. <br>• `check-work-hierarchy.py` walks `core`, `release` and `operations`. <br>• Check 14's scope list reaches no home (`*.md` is root-level only). <br>• A second pass found one more root walker outside the deploy checks: the context-budget auditor's agents scan (`find "$repo_root" -path '*/skills/*/agents/*.md'`). <br>**Unseen by the probe:** a `find` whose root arrives through a variable, and a walker reached only through a callee | The card's Evidence records only that no exclusion exists, not that a walker reaches the homes | C2 | Re-scope (G-PL4 below). The protection stays a standing obligation (ADR-231 D1 accepted cost; placement standard § Protections). The live gaps are the root walkers named here, whatever else the inventory finds, and the absence of a test that keeps the invariant true |
| AC-1: each check in the Stage-5 walker inventory skips the homes or walks tracked files only | `review-discipline-principles.md` § 1 Rule 3: a clean claim needs positive evidence per member | The inventory is owned by Stage 5 (the card's assumption). R-W1 to R-W7 are its seed | No prior inventory exists: the card's own evidence is an absence finding | C1 | For each walker the inventory states its root and why it cannot reach a home, so a reader can falsify it |
| AC-2: 1,000 planted files under `local-state/`; `deploy.sh --check` findings unchanged | `stage-04-planning.md` AC-Binding Limb 2: a null result carries a control arm on the same instrument | `[INFERRED]` On the census, the predicate already holds on `main`, so it grades MET while testing nothing. `[SOURCE: placement register S-05]` `deploy.sh --check` is also not hermetic on an operator install: it writes warn logs into today's container, and its exit status usually reflects mirror drift | The operator's recorded pattern *structured probe with a control arm*: a zero is a broken probe until its control returns non-zero | C2 | The method is a fixture copy, never a real checkout's homes. Compare finding lines, not exit codes. Add a sensitivity arm: the same fixture with one walker that reads the homes must show a difference |
| AC-3: a similarly named tracked path (`docs/local-state-notes.md`) is still walked | Rule 15: the specificity arm | `[SOURCE: tracked index at the pin]` No tracked path contains `local-state` (0 paths; control: `analysis`, 8 paths), so the near-miss path must be created by the fixture | The card names its own near-miss; no prior cycle tested one | C1 | — |
| Affected Files: `deploy.sh`, `check-doc-links.py`, `check-canonical-structure.sh`, a new test | DP-4 Simplicity (`build-philosophy.md:51`): no edit without a defect to remedy | `check-canonical-structure.sh` iterates the skill roster, and its one `find` reads a skill's `references/` folder. `check-doc-links.py` expands only the shared scope list, and both of its callers (Check 14, `link-check.yml`) read the same list and the same tracked base allowlist | The doc-link protocol records that the tracked base allowlist holds only archive-subtree entries, and that a native engine skip is preferred over an allowlist entry | C2 | All three become CONDITIONAL on the inventory. Add `release/tools/verify-release-plan.sh` (CONDITIONAL). If `check-doc-links.py` changes, its `--self-test` stays green and the two callers' scopes stay identical |
| Risk: an exclusion too broad hides tracked files | Rule 15 | The near-miss arm covers it | The card names it; no prior cycle shipped an exclusion here | C1 | — |

### #8024

`issue_number: #8024` · `release_milestone: in-repo-home-is-guarded` · `stage: 4` · `spoke_author: Stage-4 planning spoke (release-planner Mode B)` · `re_review_date: 2026-11-27` · `issue_body_revision: 2026-11-21T23:45:44Z` · `triage_decision_date: 2026-09-28` · `effort_tier: standard` (it touches the installer)

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| Evidence: one scan list 0600; the other scan list and the roster 0644 | `decision-discipline.md` § 2.1.1: re-verify a snapshot | `[SOURCE: mode bits by stat at the pin date; no file content read]` Today's container `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` reads 0755, with 28 top-level entries of mixed classes: <br>• S-08: the registered scan list at 0600, its backup at 0644 <br>• A second scan list that no register row names: 0600 <br>• S-09: the roster at 0644, its backup at 0644 <br>• S-10: the clarification queue at 0644 <br>• S-15: `scan.sh` at 0755 <br>• The leak-risk home `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` is absent | The card's 2026-09-27 inventory; the epic's 2026-10-27 re-count found a third backup at 0644 beside a 0600 list | C2 | Refresh the Evidence. The defect (no single policy) still reproduces |
| AC-1: after install or update, every leak-risk file 0600 and folder 0700 | DP-8 Security (`build-philosophy.md:53`); `reversibility-protocol.md` tiers | `[SOURCE: placement register; installer and update.sh at the pin]` <br>**Population:** the register's Leak-risk rows are S-08, S-09, S-10, S-15, S-19, S-33, S-40 and S-46, resolved through today's pointers (`pmo_localized_needles`, `pmo_people_roster`, the roster-adjacent queue, and the rest). <br>**Scaffolds:** they copy with `cp` and set no mode (`scaffold_localized_needles` / `scaffold_localized_roster` in the installer, `scaffold_needles` / `scaffold_roster` in `update.sh`). `chmod 600` appears 2 times in the installer, for `operator.toml` only, and 0 times in `update.sh`. <br>**No leak-risk-only folder:** none exists until the installer milestone provisions the home (#8027) and the migration milestone moves files (#8032). <br>**`scan.sh`:** it is executable, and 0600 would strip its exec bit. <br>**S-40:** `update.sh` writes the pre-update container copy itself, so this card's own surface creates a leak-risk folder | The epic's design says leak-risk and working state sharing one folder is the root of today's mixed protection, so a policy applied to the folder rather than per file reproduces that cause | C2 | Name the population by the register's Leak-risk rows, not a file list. Stage 5 decides three things: <br>(a) the folder limb's target today: a fixture, the governed home once it exists, or the mixed container under the standard's more-protective-class rule <br>(b) `scan.sh` <br>(c) whether S-40's copy is in scope here or with #8027 |
| AC-2: `validate-install` reports a leak-risk file at 0644 | Rule 15: the sensitivity arm is the 0644 fixture | `[SOURCE: validate-install.sh at the pin]` No mode check exists (its A-checks cover layout, hook wiring and settings). #8028 has removed this limb from its own first criterion | The 2026-10-02 backlog check recorded the two cards' de-duplication on both bodies | C1 | — |
| AC-3: a working-state file under `/local-state/` keeps its mode (near-miss) | Rule 15: the specificity arm | `[SOURCE: placement register S-45, S-47]` No tracked writer defaults into `/local-state/` today (S-45 takes an explicit `--out-dir`; S-47 an explicit `--overlay-root`) | The card names its own near-miss | C1 | Fixture-only |
| Documentation Impact: the standard's protection column names the policy | `rename-reference-cascade.md` § 3: a stated state moves with the state | `[SOURCE: placement standard L35, L129]` Already true: the class table and § Protections state "mode 0700 on each folder and mode 0600 on each file, backups included" | The placement-rules release wrote the policy into the standard ahead of its delivery | C2 | Verify only. The delivery cell ("The permission policy from the in-repo-home-is-guarded milestone") moves to present tense |
| Proposed change: set modes at install and update | DP-3 Maintainability (`build-philosophy.md:50`): extend before create | `[SOURCE: lib-instance-path.sh; #8020 Affected Files]` The resolver accessors exist in `core/deploy/lib-instance-path.sh`, and the one-resolver release (#8020) edits that file | The epic's record: resolution diverges across consumers whenever each one builds its own path | C2 | Consume the existing accessors and add no resolver function to `lib-instance-path.sh` |

**Subsumption (PT-2) across the complete open population.**
- Population: 733 open issues (698 non-sub-task), read with `--limit 5000`, so not truncated.
- No open issue duplicates or subsumes a card.
- Overlapping scope, by term: `local-state` 20 issues (the epic's slices); "forced add" 2 (#8005, #8022); commit guard 7; tree walk 2 (#8005, #8023); 0600/0700 4 (#5740, #8005, #8024, #8032).
- Neighbours:
  - #8028 deconflicts itself from #8024.
  - #7198 names a pre-commit guard as one candidate remedy for per-check mode files (related, not subsumed).
  - #9004 builds on #8022.
  - #8027 and #8032 are downstream.
- **No C3 fired, so there is no Tier 0.** The § 3.1 freshness-check does not apply, because no PT-2 citation was made.

**Ticket–architecture reconciliation.** All three cards were filed 2026-09-28 at `35dbf418`, before the placement standard (2026-11-05) and ADR-231 (Accepted 2026-11-07). They are reconciled through the C2 deltas above:
- the guard's scope (standard vs ADR);
- the leak-risk population (the register);
- the policy wording (already in the standard);
- the ignore pair (moved to the sibling release).

*Architecture lens (advisory):* the one new component is the guard. Reuse-first points at the existing git-hook home and its single install path (ADR-165) rather than a second home.

**A0.5 / G-PL1 (AC currency): FAIL → Tier 1 [ADJUST].**
- #8022: the absorb clause is stale, AC-3 cannot be met inside one PR, and the push channel is missing.
- #8023: the named walkers do not reach the homes, and AC-2 carries no control.
- #8024: the Evidence is stale and the folder target is undefined.

**A0.6 / G-PL2 (crisping):**
- #8022: G1-02 pass; G1-04 pass, with the host deferred; G1-05 fail (AC-3 cannot be graded on the PR).
- #8023: G1-02 pass; G1-04 fail (files); G1-05 fail (AC-2 is a null with no control).
- #8024: G1-02 pass; G1-04 pass; G1-05 pass, with the folder target undefined.

All three route to operator-gated body refinement. The literal deltas are under Recommendations.

**A0.7 / G-PL3 (placement forward-check): SKIP.**
- `git log 8ed5e273..origin/main --name-status --find-renames` returns 0 rows (release base equals `main`).
- Control: the same classifier over `7813457d..8ed5e273` returns 396 rows. Its one directory-crossing rename is a plan claim-rename (`plans/` → `plans/v5/`), out of scope, and no delete row is in scope.

**A0.8 / G-PL4 (empirical repro), against pinned `8ed5e273`:**

| Card | Class | Runnable check | Verdict |
|---|---|---|---|
| #8022 | general | AC-1's `check-ignore` read and the guard-absence probes (AC-2 row) | **admit-still-valid.** Already narrowed on 2026-11-28; the guard is absent (0 hits, against controls 57 and 2) |
| #8023 | general (no drift label) | Re-derived from the headline: the walker census R-W1 to R-W7 | **re-scope-changed.** AC-2 carries no control arm, so it grades MET on `main` `[INFERRED]`. The named files carry no walker that reaches a home, and root walkers sit elsewhere. Operator confirmation is required before fan-out |
| #8024 | general | Mode bits, read with `stat` | **admit-still-valid**, with an Evidence refresh. The roster and the other files still read 0644; one scan list moved to 0600 |

**Parallelization-Map currency: map absent → Tier 1 [ADJUST].** The milestone description has no `## Parallelization Map`, no `## Release Class`, no `Release-identity mode:` line, and no `### Release Outcome Statement` H3 (it carries plain `Outcome:` / `Before:` lines). The epic's delivery guide requires all of these. Drafts are under Recommendations, for the hub's PATCH.

**A0 currency decision (decision-confidence gate).**
- Signal: **CONVERGENT.** The A0.5 mismatches, the G-PL4 repros and the standard and ADR reads name the same deltas.
- A7 outcome: **amend** (body deltas, membership unchanged), at its existing operator-routed authority.
- Not run: T1's automated detector (`deploy.sh` Check 53), because this is a read-only spoke and T4 fires by construction of this pass.

**Pattern-cache scan.** Six recorded operator patterns apply, cited by name:
- dependency vs release gate (D-HomeOrder);
- verify before recommend (G-PL4 on #8023);
- assertions over prose, RED then GREEN (every AC row starts RED);
- structured probe with a control arm (the census);
- never subvert a locked control (the guard fails closed; no bypass path is planned);
- reuse first (the existing git-hook home).

No operator correction occurred in this run, so no observation was logged.

## Dependency Graph

**Native edges:**
- #8022 ← #8017 and #8024 ← #8017. #8017 is closed (milestone `placement-rules-and-adr`), so both edges are satisfied.
- #8023 has none.
- Outward: #8022 blocks #8027 and #9004; #8024 blocks #8032.
- Inside the milestone: **0**. Probe: the `blocked_by`/`blocking` endpoints for all three cards. Control: #8022 returns three edges, so the read is live.

| From | To | Artifact relationship | Scheduling | Basis |
|---|---|---|---|---|
| #8023 | #8022 | DEPENDS_ON, soft (CONDITIONAL: one shared home list) | FS | #8023's exclusion and #8022's guard name the same home set (CIAC-1); the card says "Related: #8022" |
| #8024 | #8022 | none | — | Its near-miss plants a fixture file; no build edge |
| #8022 (AC-1) | `worktree-sessions-reach-in-repo-homes` (#8019) | release-gate, not a build edge | — | The ignore pair ships there (D-LocalState C) |
| wave-6 cutover (#8034) | this release | release-gate | — | No switch flips a writer into `/local-state/` before the home and its guard are on `main`. `one-resolver-and-release-tool-routing` keeps its switch off by its own exit test, so there is no merge-order constraint with it |
| wave 3 (#8025, #8026) | this release | planned order (shared files) | — | The epic's milestone map: `deploy.sh`, `git-pre-commit-pii.sh`, `repo-integrity.yml` |

**Critical path:**
- `[DEGRADED-MODE: typed-dep substrate absent; chain length is unweighted edge count; lead/lag NOT modeled]`
- Chain: #8022 → #8023, 1 edge (conditional).
- Algorithm: DP-DAG longest path.

**G3-07 Status: PASS.** Two inbound edges were checked (#8017, in a closed milestone), with 0 cross-milestone violations and 0 cycles.

**Integration points:**
- **IP-1:** the guard's home set ⇄ the placement standard § Registered in-repo git-ignored homes ⇄ the sibling's -019 static set and its parity arm.
- **IP-2:** the guard ⇄ `wire_pii_git_hook` and validate-install A3d/A3e.
- **IP-3:** the CI job ⇄ branch protection ⇄ the gate-efficacy disposition table ⇄ `git-workflow.md` § Repository-Integrity Gates.
- **IP-4:** the tree-walk invariant ⇄ Check 14 and `link-check.yml` (one scope list, one tracked allowlist).
- **IP-5:** the installer and update mode pass ⇄ the validate-install finding ⇄ placement standard § Protections.
- **IP-6:** `local-state/README.md` ⇄ the draft-file controls.

## Implementation Sequence

One branch, one release PR, slices committed in this order.

0. **Engineering Commit 0:** the plan file. The first Stage-6 spoke re-verifies the version, then runs `release/tools/claim-version.sh --verify-stamp in-repo-home-is-guarded` before committing.
1. **#8022:**
   - (a) RED arms first: the guard suite (`T8022-G*` forced add per guarded home, `T8022-N*` near-miss, `T8022-P*` push arm if Stage 5 places one) and the CI job's fixture self-test (`T8022-C*`).
   - (b) `local-state/README.md`, written to the idiom in the placement standard: what it admits, that everything else is ignored, and which standard governs it. Workspace-rooted links only.
   - (c) The guard, on the Stage-5 host.
   - (d) The CI job in `repo-integrity.yml`, its `gate-efficacy:` header (posture per D-RequiredCheck), the gate-coverage register row and the registration-disposition row.
   - (e) The documentation cascade: placement standard L127 and L263, `architecture-overview.md` L147, the `git-workflow.md` gates table if fired, and the hook registry fragment (regenerated) if fired.
2. **#8023:**
   - (a) The Stage-5 walker inventory, recorded in the design.
   - (b) The RED fixture with its sensitivity arm.
   - (c) A fix for each walker that reaches a home; the plan verifier's root `find` is the one known today.
   - (d) The regression test and its allowlist and roster rows.
3. **#8024:**
   - (a) RED arms: an install fixture with mixed modes, the validate-install 0644 finding, and the near-miss.
   - (b) The mode pass in the installer and `update.sh`.
   - (c) The validate-install check.
   - (d) The placement standard's Leak-risk delivery cell.

Rationale:
- #8022 defines the guarded-home set that #8023 consumes.
- #8024 is independent and last, per the milestone's own sequence.
- The three cards edit one § Protections table, so they serialize in this order on one branch.

### #8022 slice order, as designed (Stage 5 design on #9205, as amended at the Collective Review)

The #8022 slice lands as commits in this order, each pushed when it is coherent. Messages carry the trailing `(#8022)`, never a close-family verb before a number.

1. **Tests first (RED-1).** `core/hooks/tests/git-pre-commit-homes.test.sh` alone. RED-1 is run against the tree with no detector and its expected failures are named in the spoke's output.
2. **The detector and its call sites.** `core/hooks/git-pre-commit-homes.sh`, the two call sites in `core/hooks/git-pre-commit-pii.sh` (the staged call placed ahead of the PII guard's bypass exit, per D-Bypass C), and one geometry copy line in each of the three existing PII suites. RED-2's naive variants run in the working tree before the commit; then GREEN.
3. **The README.** `local-state/README.md`. `BLOCK-DRAFT-001` (warn) is expected on its write and recorded.
4. **CI.** The `repo-integrity.yml` header block, the `In-repo home content gate` job and one count-free comment; the `pii-push-scan.yml` header, file list and summary wording.
5. **Governance and documentation.** The gate-efficacy rows, the placement standard, `architecture-overview.md`, `git-workflow.md` § Repository-Integrity Gates, and the D-Bypass C decision record (status `Proposed`).
6. **Catalog.** The two controls-register rows, then the generator's build and its checks, never a hand edit of a generated file.

### #8023 slice order, as designed (Stage 5 design on #9209, as amended at the Collective Review)

The #8023 slice lands as commits in this order after the #8022 slice, each pushed when it is coherent. Messages carry the trailing `(#8023)`, never a close-family verb before a number.

1. **The plan.** These #8023 rows of § File Change Matrix and § Verification Plan, and their § Deviation Log rows.
2. **Tests first (RED).** `core/deploy/tests/test_tree_walk_skips_homes.sh` with its four allowlist forms and its `REGRESSION_MEMBERS` row. It runs through the install regression suite, and its RED run is read against the tree with no walker changed.
3. **The verifier.** The scope glob resolver reads the git index; the FCM first-segment enum gains its two missing top-level directories, with suite arm A14 RED before and GREEN after.
4. **The import tracer.** Tracked-first scan list with the empty-index fallback, root resolution from its own checkout, its marker, and the domain suite's header.
5. **The doc tracer.** Root resolution from its own checkout and its marker, and the protocol's `--root` cell.
6. **The budget scan.** Rooted at the three module trees, with the skill package rebuilt by its build tool in the same commit.
7. **The durability copy.** repo-next copied from the git index plus `.git`.
8. **The placement standard.** The tree-walk clause of the § Protections working-state cell.

### #8024 slice order, as designed (Stage 5 design on #9213, as amended at the Collective Review)

The #8024 slice lands as commits in this order after the #8023 slice, each pushed when it is coherent. Messages carry the trailing `(#8024)`, never a close-family verb before a number, and name leak-risk surfaces by register row, never by file name.

1. **The plan.** These #8024 rows of § File Change Matrix and § Verification Plan, their § Deviation Log rows, § Named Residuals and § Operational Deployment Manifest.
2. **Tests first (RED).** `core/deploy/tests/test_leak_risk_modes.sh` with its four allowlist forms and its `REGRESSION_MEMBERS` row, and the T8024-V arms in `core/deploy/tests/test_validate_install.sh`. The new suite runs through the install regression suite; its RED run, and the validator suite's, are read against the tree with no library.
3. **The library.** `core/deploy/lib-leak-risk-modes.sh`.
4. **The creation sites and the passes.** The six scaffold copies and the extractor's `touch` under `umask 077`; the installer's Section 15f pass; the update path's Phase 2.5f pass, its S-40 copy created at the policy, and its exit-reduction term.
5. **The validator.** Check A11 and the Mode A count cascade.
6. **The placement standard.** The § Protections Leak-risk delivery cell, and register row S-48.
7. **The Change Description and the pull-request body**, for all three slices.

### Agent-Editability Read

**Derivation:** controls read at commit `8ed5e273`.
- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh`, every `case "$ABS_TARGET"` block whose arms invoke `always_block "BLOCK-AUTONOMY-001"`. 2 blocks observed; 8 `BLOCK-AUTONOMY-001` mentions in the file.
  - Block 1 (lines 856–872), arms verbatim:
    - `"${PRIMARY_ROOT}/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/projects/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"`
    - `"${PRIMARY_ROOT}/.claude/settings.json"`
    - `"${PRIMARY_ROOT}/.claude/hooks/"*`
    - `"${PRIMARY_ROOT}/.claude/rules/"*`
  - Block 2 (lines 901–914, the membership stage): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`
  - Projected onto the tracked index at the pin (2,400 files), the surviving floor is 3 files: `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md`. No tracked file is named `CLAUDE.md`. The workspace-root, settings, `.claude/hooks/` and `.claude/rules/` arms name untracked or deployed surfaces and are discarded. No write-set path matches.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`.
  - `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`
  - Arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`
  - Exemption list: `undetermined`. It was not read, and it decides nothing here, because no write-set path passes conjunct 1.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #8022 | `local-state/README.md` | no | no (fails conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8022 | `core/hooks/git-pre-commit-pii.sh`, `git-pre-push-pii.sh`, `git-pre-commit-*.sh`, `block-draft-files.sh`, `block-destructive.sh`, `core/hooks/tests/*` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8022 | `.github/workflows/repo-integrity.yml` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8022 | placement and gate-efficacy standards, `architecture-overview.md`, `core/rules/git-workflow.md`, `core/rules/bypass-mode-readiness/*` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8022 / #8024 | `docs/scripts/setup-workspace.sh`, `docs/scripts/validate-install.sh`, `update.sh`, `core/deploy/tests/*` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8023 | `release/tools/verify-release-plan.sh`, `blast-radius.sh`, `domain-blast-radius.sh` and their suites and fixtures, `release/references/protocols/blast-radius-protocol.md`, `core/skills/context-budget-auditor/scripts/measure-context-budget.sh` and its package, `core/deploy/tests/*`, the placement standard, the allowlist and roster rows (resolved set, DEV-20) | no | no (conjunct 1: a skill `scripts/` path is outside `SKILL_SCOPE_RE`) | unconstrained | unconstrained | ordinary Engineering spoke |

Notes:
- No path in the write set is Tier-0-floored or skill-gated. An `unconstrained` row means no control refuses the write; it does not mean the change is ungoverned.
- One expected firing outside these two controls: BLOCK-DRAFT-001 (warn posture) on the Write of `local-state/README.md`, because the path sits outside the hook's governed roots. Record it; do not route around it.

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | 9–13 |
|---|---|---|---|---|---|
| #8022 | **APPLY:** the guard host, D-GuardScope's shared list, push arm, CI job posture, a security control | APPLY | APPLY (hook harness macOS and Linux; install regression if wiring changes) | APPLY | release-scoped |
| #8023 | **APPLY:** walker inventory and fixture design with its sensitivity arm | APPLY | APPLY | APPLY | release-scoped |
| #8024 | **APPLY:** population source, folder limb today, `scan.sh`, S-40 | APPLY | APPLY (install regression suite) | APPLY | release-scoped |

Stages 7 and 8 run for every card: REDUCE at most, never skip (operator stance). Stages 10 and 11 compress, per the git-native release norm. Procedure 1 scaffolds 3 × (5, 6, 7, 8) per-issue sub-tasks plus the release-scoped 9–13.

## Contention Map

**Within the release:**

| File | Cards | Severity | Resolution |
|---|---|---|---|
| `core/standards/instance-data-placement-standard.md` § Protections (L127 working state in-repo: guard and tree walk; L129 leak-risk) and References (L263–L265) | #8022, #8023, #8024 | BINARY: one table, adjacent rows | Serial, in sequence order |
| `docs/scripts/setup-workspace.sh`, `docs/scripts/validate-install.sh` | #8024; #8022 only on the separate-script branch | BINARY (conditional) | Serial: #8022 first |
| `core/config/allowlists/script-execution-allowlist.txt`, `core/deploy/tests/run-install-regression.sh` | #8023, #8024 (if a new test) | append-pattern | Serial |
| `core/deploy/tests/test_validate_install.sh` | #8024; #8022 (conditional wiring arm) | BINARY (conditional) | Serial |

Parse quality: 3 cards parsed, 0 deferred, 0 parse-failed (Affected Files present on 3 of 3).

**Cross-release.** Population: the five sibling hubs named by the hub plus `install-wires-what-it-ships`.

| Sibling | Overlap with this release | Class | Resolution |
|---|---|---|---|
| `worktree-sessions-reach-in-repo-homes` (#8019, #7503, #7929; Stage 5) | Placement standard L127 (both rewrite the same § Protections cell) and L263 (the References line for #8022). `gate-efficacy-standard.md` (its D-6 register row and our rows in the same register). `.gitignore` (theirs; ours NOT EDITED). `core/rules/git-workflow.md` (theirs § Primary Checkout Discipline; ours § Repository-Integrity Gates, conditional). `_cross-cutting.md` and the generated registry, plus `block-destructive.sh` (conditional on our side) | line-range overlap on L127/L263; append-pattern on the register; section-disjoint on the rule | **Release-gate (D-HomeOrder).** Merge after it and re-baseline the two placement-standard lines. Regenerate the registry, never hand-merge |
| `one-resolver-and-release-tool-routing` (#8020, #8021; Stage 4, no plan yet) | Its declared files (`lib-instance-path.sh`, the config template and schema, `test_lib_instance_path.sh`, release tools) ∩ ours = none while #8024 adds no resolver function | none | Release-gate on the wave-6 flip, not on its merge |
| `issue-body-is-the-scope-of-record` (#7970; PR #9201, draft, head `dd36fbed`) | Its 11 head files ∩ our matrix = none | none | Once merged, its "contract sections edited in place" rule governs how the Tier 1 body edits are applied |
| `fs-boundary-judges-every-listed-verb-operand` (#8547) | `core/rules/bypass-mode-readiness.md` (generated); `block-destructive.sh` and `_cross-cutting.md` (conditional on both sides) | append-pattern on the generated registry | Regenerate after merge |
| `rollups-select-projects-by-portfolio` (#8478) | `core/deploy/deploy.sh` (theirs CONDITIONAL:RESOLVER-IN, ours conditional on the inventory). Both leave `build-doc-index.py` unedited | conditional × conditional | Serialize only if both fire |
| `install-wires-what-it-ships` (#7213, #5750, #5633, #5073; open, 0 closed, no sub-tasks) | Declared: `setup-workspace.sh`, `update.sh`, `deploy.sh` | declared-scope overlap; no hub running | Not started. Whichever starts second re-baselines (the epic's guide requires recording this in the Parallelization Map) |

**Hot files (first-parent merges in the last 30 days / all-time commits):**
- `gate-efficacy-standard.md`: 11 / 187
- `instance-data-placement-standard.md`: 3 / 11
- `setup-workspace.sh`: 2 / 59
- `validate-install.sh`: 2 / 23
- `repo-integrity.yml`: 1 / 62
- `git-workflow.md`: 1 / 43
- `update.sh`: 1 / 28
- `git-pre-commit-pii.sh`: 1 / 8

**Cross-PR overlap audit:**
- Open PRs: **1** (#9201, draft). Its head diff ∩ our matrix = 0 paths. Control: the merged-PR query returns #9145.
- Recently merged in scope (`7813457d..8ed5e273`): the PII guard wiring commits (pre-commit and pre-push wired on install and update; validate-install A3d/A3e; the install suite kept inside its CI step) touch `git-pre-commit-pii.sh`, `git-pre-push-pii.sh`, `setup-workspace.sh`, `validate-install.sh` and `update.sh`.
- `overlap_class`: `single-pr` for each file against the open population.

### In-Flight Release Roster

**Measured at:** `8ed5e273` · `2026-11-28T03:46:17Z` · **Population:** n=1 sibling with a head. Remote `release/*` heads: one. Control: the `main` head row returned. The other four sibling hubs have no head.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `issue-body-is-the-scope-of-record` | `#9201` | `dd36fbed` | `minor` | none on the PR (slug-primary branch) | `v5.15` [INFERRED: next-free minor over anchor `v5.14`] | — |

- **Structural sub-audit:** suppressed. The matrix declares no rename, relocation or delete, so the mover-set is empty.
- **Sibling-merge trigger:** re-run `git log 8ed5e273..origin/main --name-status --find-renames` against this release's write set at Stage 9 entry. The expected merge order puts this release fifth, after the sibling that ships the ignore pair.

## File Change Matrix

The release is the #8022 rows below, as its Stage-5 design resolved them, the #8023 rows as its Stage-5 inventory and the Collective Review resolved them, and the #8024 rows as its Stage-5 design and the Collective Review resolved them. Each spoke promoted or retired its own card's CONDITIONAL rows in its slice, and recorded the change in § Deviation Log.

```
# ── #8022 — always delivered (the Stage-5 design's resolved set, as amended at the Collective Review) ──
local-state/README.md                                            add
core/hooks/git-pre-commit-homes.sh                               add    # the detector (100755); its home set is a static set inside it
core/hooks/tests/git-pre-commit-homes.test.sh                    add    # the new hook suite (100755)
core/hooks/git-pre-commit-pii.sh                                 edit   # two call sites (the staged one ahead of the bypass exit) and a header paragraph
core/hooks/tests/git-pre-commit-pii.test.sh                      edit   # one geometry copy line
core/hooks/tests/git-pre-commit-pii-env-inputs.test.sh           edit   # one geometry copy line in arm_setup
core/hooks/tests/git-pre-push-pii.test.sh                        edit   # geometry copy lines at GEOM and SEED
.github/workflows/repo-integrity.yml                             edit   # the In-repo home content gate job, its gate-efficacy header, one count-free comment
.github/workflows/pii-push-scan.yml                              edit   # header invariant clause, file-presence list, summary wording
core/standards/gate-efficacy-standard.md                         edit   # gate-coverage row, REGISTER disposition row, one count-free cell, Version History row
core/standards/instance-data-placement-standard.md               edit   # § Protections working-state cell; one paragraph in § Registered in-repo git-ignored homes
core/disciplines/architecture-overview.md                        edit   # the /local-state/ tree line
core/rules/git-workflow.md                                       edit   # § Repository-Integrity Gates: the count dropped, every registered gate tabled (mirror-pair source)
core/ADRs/ADR-242-commit-time-home-guard-runs-under-hook-bypass.md add    # D-Bypass C decision record, status Proposed; 242 is the renumber tool's binding next-free (DEV-15)
core/process-catalog/definitions/controls-register.tsv           edit   # two rows (the commit guard and the CI job)
core/process-catalog/definitions/pack.json                       edit   # highest_minted_id raised to the two new control IDs (DEV-16)
core/process-catalog/views/                                      edit   # regenerated by the catalog generator, never by hand
release/releases/plans/in-repo-home-is-guarded_RELEASE_PLAN.md   add    # Engineering Commit 0
# ── #8023 — always delivered (the Stage-5 inventory's resolved set, as amended at the Collective Review) ──
core/deploy/tests/test_tree_walk_skips_homes.sh                  add    # the fixture test (100755): clean against planted, mutant sensitivity, near-miss, empty-index, non-git-parent and census arms
core/config/allowlists/script-execution-allowlist.txt            edit   # four invocation forms for the new test
core/deploy/tests/run-install-regression.sh                      edit   # one REGRESSION_MEMBERS row — CI wiring: "Install/onboarding/update regression suite (macOS)"
release/tools/verify-release-plan.sh                             edit   # ROOT-WALKER-FIX fired: the scope glob resolver reads the git index; the FCM first-segment enum gains its two missing top-level directories (DEV-27)
release/tools/tests/test_verify_release_plan.sh                  edit   # one arm: a registered home's README ADD is interpreted (DEV-27)
release/tools/tests/fixtures/fcm-home-readme.md                  add    # that arm's plan fixture
release/tools/tests/fixtures/fcm-diff-home-readme.tsv            add    # that arm's diff seam
release/tools/domain-blast-radius.sh                             edit   # tracked-first scan list with the empty-index fallback; an omitted root resolves to its own checkout first
release/tools/tests/test_domain_blast_radius.sh                  edit   # header comment only: the enumerated git calls
release/tools/blast-radius.sh                                    edit   # an omitted root resolves to its own checkout first; one marker on the fallback walk
release/references/protocols/blast-radius-protocol.md            edit   # the --root default cell (cascade of the root order, DEV-21)
core/skills/context-budget-auditor/scripts/measure-context-budget.sh  edit   # the agents scan rooted at the three module trees
packages/context-budget-auditor.skill                            edit   # regenerated by build-skill-packages.sh, never by hand
packages/context-budget-auditor.skill.sha256                     edit   # regenerated with it
core/deploy/tests/test_upgrade_config_durability.sh              edit   # repo-next copied from the git index plus .git
core/standards/instance-data-placement-standard.md               edit   # § Protections working-state cell: the tree-walk clause only, after the #8022 edit
# ── #8023 — CONDITIONAL rows resolved NOT FIRED (Stage-5 inventory) ──
core/deploy/deploy.sh                                            NOT EDITED   # CONDITIONAL:INVENTORY-NAMES-DEPLOY-WALKER did not fire: every walker is S, D1 or X
core/deploy/tools/check-doc-links.py                             NOT EDITED   # CONDITIONAL:INVENTORY-NAMES-DOC-LINKS did not fire: S; Check 14 and link-check.yml scope untouched
core/deploy/tools/check-canonical-structure.sh                   NOT EDITED   # CONDITIONAL:INVENTORY-NAMES-CANONICAL did not fire: S, a skill's references/
core/deploy/allowlists/selftest-coverage-manifest.txt            NOT EDITED   # CONDITIONAL:NEW-SELFTEST-TOOL did not fire: the new test dispatches no --self-test
# ── #8024 — always delivered (the Stage-5 design's resolved set, as amended at the Collective Review) ──
core/deploy/lib-leak-risk-modes.sh                               add    # the population, the setter and the read-only findings; files 0600, folders 0700, S-15 included (D-ScanExec B)
docs/scripts/setup-workspace.sh                                  edit   # the Section 15f pass in fresh_install and rebootstrap; two scaffold copies under umask 077
update.sh                                                        edit   # the Phase 2.5f pass; the S-40 copy created at the policy, uncounted; two scaffold copies; the exit-reduction term
install.sh                                                       edit   # two fallback scaffold copies under umask 077 (DEV-29)
core/deploy/extract-roster-needles.sh                            edit   # the S-08 touch under umask 077, the seventh creation site (adversarial PR-3, DEV-35)
docs/scripts/validate-install.sh                                 edit   # check A11 INSTALL-LEAK-RISK-MODES in both Mode A sub-modes; the count cascade
core/deploy/tests/test_validate_install.sh                       edit   # the T8024-V arms and new_leak_arm; arm 5 copies the library (PR-2); one count-free line
core/deploy/tests/test_leak_risk_modes.sh                        add    # CONDITIONAL:NEW-INSTALL-MODE-TEST fired (100755)
core/config/allowlists/script-execution-allowlist.txt            edit   # four invocation forms for the new suite
core/deploy/tests/run-install-regression.sh                      edit   # one REGRESSION_MEMBERS row — CI wiring: "Install/onboarding/update regression suite (macOS)"
core/standards/instance-data-placement-standard.md               edit   # § Protections Leak-risk delivery cell in the present tense; register row S-48 for the second PII scan list (CD-2)
# ── #8024 — CONDITIONAL rows resolved NOT FIRED ──
core/deploy/tests/test_install_end_to_end.sh                     NOT EDITED   # CONDITIONAL:INSTALL-ARM-IN-E2E did not fire: it installs from the real checkout, so the /local-state/ near-miss cannot be planted there
.github/workflows/install-tests.yml                              NOT EDITED   # CONDITIONAL:REGRESSION-STEP-BUDGET did not fire: it fires above about 101 minutes on either gating step (adversarial FM-4, DEV-38)
```


### Read-only inputs

```
core/ADRs/ADR-231-non-tracked-data-homed-by-risk-class.md        READ
core/deploy/lib-instance-path.sh                                 READ
core/deploy/allowlists/doc-link-target-paths.txt                 READ
core/deploy/allowlists/skip-doc-link-check-ci.txt                READ
.github/workflows/gate-posture-reconciliation.yml                READ
core/hooks/block-autonomy-ceiling.sh                             READ
core/hooks/block-skill-direct-edit.sh                            READ
```

### Release-wide explicit non-scope

```
.gitignore                                   NOT EDITED   # the pair and both narrower lines belong to worktree-sessions-reach-in-repo-homes (D-LocalState C, its D-3)
core/deploy/lib-instance-path.sh             NOT EDITED   # the one-resolver release's file; #8024 uses its existing accessors
core/deploy/tools/_frontmatter.py            NOT EDITED   # its three corpus walkers scan a given root (projects tree by default); deploy.sh invokes none
core/config/operator.toml.template           NOT EDITED
core/hooks/git-pre-push-pii.sh               NOT EDITED   # #8022 GUARD-PUSH-ARM fired for the test only: the hook already runs the PII guard with --commits, which now runs the home guard
core/deploy/tests/test_git_hooks_install.sh  NOT EDITED   # #8022 GUARD-SEPARATE-SCRIPT wiring rows did not fire: no new link; a missing detector refuses at the next commit, naming the file
core/rules/bypass-mode-readiness/_cross-cutting.md  NOT EDITED   # #8022 REGISTRY-NAMES-GUARD did not fire (D-Registry)
core/rules/bypass-mode-readiness.md          NOT EDITED   # #8022 REGISTRY-NAMES-GUARD did not fire (D-Registry); generated
core/hooks/block-destructive.sh              NOT EDITED   # #8022 NO-VERIFY-RATIONALE-NAMES-GUARD did not fire (D-Registry)
core/hooks/block-draft-files.sh              NOT EDITED   # #8022 DRAFT-GATE-ADMITS-HOME-README did not fire (D-DraftGate: an accepted residual)
core/hooks/tests/block-draft-files.test.sh   NOT EDITED   # #8022 DRAFT-GATE-ADMITS-HOME-README did not fire
```

Notes on the matrix:
- **Fired conditionals, promoted here.** For #8022 the Stage-5 host decision (H-B, a sibling detector) fired GUARD-SEPARATE-SCRIPT for the detector and its suite, GUARD-IN-PII-HOOK for the PII guard's call sites and its suite, GUARD-PUSH-ARM for the pre-push suite only, and CONTEXT-DECLARED-REQUIRED (D-RequiredCheck B). Each is promoted to a concrete row above. The design added the env-inputs suite, `pii-push-scan.yml` and the controls register with its regenerated views. The Collective Review's D-Bypass C added the decision record. The rows that did not fire are in the non-scope block above, each with its reason.
- **Mirror pairs.** `core/rules/git-workflow.md` and `core/rules/bypass-mode-readiness.md` are mirror-pair sources: edit the source only. Any new link in them to a target outside the mirrored set uses the leading-`/` form.
- **New executables.** `core/hooks/git-pre-commit-homes.sh` is run by git (through the PII guard), by CI and by its own suite, never at an agent's command position, so it carries no script-execution allowlist row; its suite is covered by the existing `core/hooks/tests/*.test.sh` rows and is executed by the hook test runner's `*.test.sh` glob in the `Hook test harness (macOS)` and `(Linux)` jobs. A new `core/deploy/tests/test_*.sh` needs its own four rows, which is why the allowlist row above is a #8023 row.
- **Regenerated files.** `bypass-mode-readiness.md`, the selftest manifest and the process-catalog views are regenerated by their tools. Never hand-merge them.
- **Line numbers.** The placement standard's line numbers are read at the pin and move once the sibling release merges; its same-cell edits reconcile at the Stage-9 merge from `main`.
- **The README** must not carry a bare issue reference outside a reference block (the issue-reference gate reads every changed markdown file).
- `domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-27, domain: software }` — dominant class software (the guard, the CI job, the installer and the validator); secondary class governance (the placement and gate-efficacy standards).

## Risk Register

| # | Risk | Severity / likelihood | Mitigation | Owner stage |
|---|---|---|---|---|
| R1 | The guard inherits the PII guard's warn/off dial and silently stops blocking | HIGH / MEDIUM | The guard fails whatever the dial reads. A test arm runs with the dial at warn and at off | 5–7 |
| R2 | Pre-commit does not run on merge, cherry-pick, rebase or commit-tree, and a person can pass `--no-verify`, so home content reaches a branch | HIGH / MEDIUM | A push-time arm through the pre-push guard. The CI job is the one control a local bypass cannot skip | 5–6 |
| R3 | Registering the new context blocks every open sibling PR until it runs CI on a merge ref that includes the job | MEDIUM / HIGH | Under D-RequiredCheck (B), register in the same Stage-12 sequence as the merge, and tell in-flight hubs that a fresh push or a merge from `main` is needed | 12 |
| R4 | The reconciler reads UNREGISTERED on this PR from the header flip until registration, or UNDECLARED repository-wide under option (A) | MEDIUM / HIGH | D-RequiredCheck (B) confines the reading to this PR. It is read and recorded at merge (advisory, non-blocking) | 9–12 |
| R5 | This release is ready before the sibling that ships the pair has merged | MEDIUM / MEDIUM | Hold at Stage 12 (D-HomeOrder). Tier 2 only if the sibling stalls | 9–12 |
| R6 | Same-cell edits to the placement standard with the sibling (L127, L263) | MEDIUM / HIGH | Merge after it. Re-baseline the cells when merging `main` in, before the Stage 9 re-check | 9, 12 |
| R7 | #8023's exit test passes on `main` and tests nothing | HIGH / HIGH without the re-scope | The sensitivity arm required in the AC-2 delta | 5–7 |
| R8 | An exclusion that is too broad hides tracked files: the README, or a similarly named path | MEDIUM / LOW | Near-miss arms; the README is excepted | 6–7 |
| R9 | The guard's home list drifts from the registered-homes table, becoming a third copy beside the sibling's -019 static set | MEDIUM / MEDIUM | One shared list or a parity arm with a mutated-table control (CIAC-1). The new-surface check (#8029) later co-owns parity | 5–7 |
| R10 | The mode pass changes working state in the mixed container, or strips `scan.sh`'s exec bit | MEDIUM / MEDIUM | Population from the register's Leak-risk rows. Stage 5 decides the folder limb and `scan.sh`. Near-miss arm | 5–7 |
| R11 | `local-state/README.md` trips the draft-file hook and CI gate (warn) | LOW / CERTAIN | CONDITIONAL regex row, or accept as a recorded residual | 6, 9 |
| R12 | The post-merge fast-forward of the main checkout fails if an untracked `local-state/README.md` exists there (none today; the hub's read found no `local-state/`, control `analysis/` present) | MEDIUM / LOW | A pre-merge read of the main checkout at Stage 12; never discard operator files | 12 |
| R13 | A fixture that copies the repository plants files in the wrong tree, or `deploy.sh --check` writes into the operator's container during a test | MEDIUM / LOW | Sandbox roots only, `git status --porcelain` before and after, never stage leftovers | 6–8 |
| R14 | Below-band composition: 10 raw points carry a full pipeline's fixed overhead | LOW / CERTAIN | Finding only (the epic records why the milestone stays alone) | B |
| R15 | AC ordinals shift once the Tier 1 edits split AC-3 | LOW / CERTAIN | Re-bind the verification rows in the same change | B, 6 |
| R16 | The D-Bypass C exception departs from the uniform bypass convention every other platform hook and git hook follows, so a reader who knows the convention mispredicts the commit-time guard | LOW / MEDIUM | The decision record states the one exception and its escape hatch; the PII guard's header, the detector's header and the gate-coverage row name it; outside the matrix the readiness registry's uniform-bypass statement is flagged, not edited | 6, 9 |
| R17 | The decision record's number collides with a sibling release's branch claim, or reads as a gap to the required ADR-number integrity gate | LOW / HIGH | The renumber tool's binding oracle at authoring; the merge-time renumber moves the later claimant and appends a provenance note | 6, 12 |


## Delivery Strategy · Rollback Strategy · Test Strategy

**Rollback strategy.**
1. **De-register the context first**, before reverting the job. A required context that no longer reports blocks every PR.
2. Revert the single release merge with a mainline revert.
3. Re-run `docs/scripts/setup-workspace.sh --refresh-hooks` if the guard's wiring changed.
4. Leak-risk modes are not reverted by the revert. They stay at the more protective setting, which is harmless.
5. The version tag is retained (tag retention).

Reversibility **MODERATE** · confidence HIGH.

**Delivery strategy.**
- D-C topology **SINGLE**: one release branch, one PR, slices as commits in the order above.
- Posture **P0**, serial.
- No force-push.
- The version stays unclaimed until the Stage-12 atomic claim.

**Test strategy.**
- **Guard:** guard suites build their own scratch repository with a linked pre-commit hook (the pattern `git-pre-commit-pii-env-inputs.test.sh` already uses). They never touch a real checkout's `local-state/`. Read `git status --porcelain` before and after every harness run.
- **Hook harness:** both the macOS and the Linux legs must stay green, with the Linux known-failure list unchanged.
- **CI job:** the job carries its own `--self-test`-style fixture arms, sensitivity and specificity, as the sibling gates in `repo-integrity.yml` do.
- **#8023:** the fixture runs on a sandbox copy and compares finding lines.
- **#8024:** its arms run in the install regression suite, which is a required check on `main`.

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8022 × #8023 on the in-repo home set):** the tree-walk invariant excludes every home in the placement standard's registered in-repo homes table, and the commit guard covers the set D-GuardScope selects. Wherever the two sets share a home, both read it from one list, never from two copies. *Method:* declared, verification deferred to #8022 AC-2 and #8023 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*

Considered and dropped: a CIAC over the placement standard's § Protections wording. Its only gradable probe reads #8022's clause alone, so it would grade the other two cards' limbs MET without reading them. The wording is carried by the File Change Matrix rows instead.



**Collective Review reading of CIAC-1.** CIAC-1 counts as met when no walker carries its own home list and the test is the list's only reader (adversarial review PR-2 on #9236). The one list is the static set inside `core/hooks/git-pre-commit-homes.sh`, read with `--print-homes`; #8023's reader appends `/` to each name.

**CIAC lint (G4-06), re-read on this committed file at Engineering Commit 0:** recorded in the Engineering Commit 0 message and in the spoke's output.


## Verification Plan

### Per-Issue Verification

**AC baseline**, read at `8ed5e273`: #8022 has 4 ACs (body 2026-11-28T00:22:47Z), #8023 has 3 (2026-11-21T23:45:38Z), #8024 has 3 (2026-11-21T23:45:44Z). The Tier 1 deltas split #8022 AC-3 into AC-3 and AC-5; the rows are re-bound in that change. **Re-read at Engineering Commit 0** (2026-11-28, against `8ed5e273`): #8022 has 5 (body 2026-11-28T08:37:31Z), #8023 has 3 (2026-11-28T08:37:32Z), #8024 has 3 (2026-11-28T08:37:34Z) — 11 in all. The #8022 rows below are bound to its Stage-5 design's arm labels (§ Deviation Log); the #8023 and #8024 rows are bound by their own spokes.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8022 | AC-1 | `grep -c -x -F "/local-state/*" .gitignore` at least 1 [READER-GRADED — a fresh clone lists local-state/README.md, and git check-ignore reports local-state/release-runs/x.md as ignored] | ≥1. Baseline 0 (control: whole-line `/analysis/*` = 1). An expected FAIL through Stages 6–8 until the sibling's pair reaches this branch by a merge from `main`. No spoke adds the pair to turn it green: grading it MET is a Stage 9 or Stage 12 event |
| #8022 | AC-2 | `grep -c -F "T8022-G4" core/hooks/tests/git-pre-commit-homes.test.sh` at least 4 [READER-GRADED — the forced-add arms T8022-G1 to G7b, the dial arms G4a to G4c with their G4d control and the bypass arm G6a, graded by the Hook test harness CI jobs] | the forced add is refused under each guarded home, under `off`, `warn` and `enforce`, and with `CLAUDE_HOOK_BYPASS` set; G4d accepted |
| #8022 | AC-3 | `grep -c -F "In-repo home content gate" .github/workflows/repo-integrity.yml` at least 2 [READER-GRADED — the job's committed self-test arms T8022-C1 to C17 run first on every pull request to main, and the job reports green on the release PR head] | ≥2 (baseline 0): the header and the job's name line at least |
| #8022 | AC-4 | `grep -c -F "T8022-N2" core/hooks/tests/git-pre-commit-homes.test.sh` at least 1 [READER-GRADED — the near-miss arms T8022-N1 to N7 in the hook suite and C4, C8 and C10 in the self-test] | a README-only commit passes the guard and the job's predicate; `local-state/readme.md` fails both |
| #8022 | AC-5 | [DEFERRED — read back main's required status-check contexts after the operator registers the In-repo home content gate at Stage 12, and again at Stage 13] | the context is present (baseline absent) |
| #8023 | AC-1 | `grep -c -F "T8023-K1" core/deploy/tests/test_tree_walk_skips_homes.sh` at least 1 [READER-GRADED — the Stage-5 walker inventory, one row per walker with its root and class, read against the diffs of the five changed walkers (the verifier's glob resolver, the import tracer and the durability copy enumerate the git index; the budget scan is rooted at the three module trees; both tracers resolve an omitted root to their own checkout), with the census arms T8023-K1 and T8023-K2 reading 0 unmarked and 0 stale] | every inventoried walker skips the homes or reads tracked files only; the durability copy is graded here |
| #8023 | AC-2 | `grep -c -F "T8023-M" core/deploy/tests/test_tree_walk_skips_homes.sh` at least 4 [READER-GRADED — the install regression suite's member line for this test reads 0 failed: T8023-S1 to S4 equal on the planted fixture, T8023-M1 to M4 differ, T8023-A3 and A4 equal from a non-git parent, T8023-E3 non-empty] | the walkers the test runs report the clean findings with 1,000 files planted per home; each mutant reports a difference |
| #8023 | AC-3 | `grep -c -F "T8023-N" core/deploy/tests/test_tree_walk_skips_homes.sh` at least 4 [READER-GRADED — T8023-N1 to N4 pass on the clean and the planted fixture] | each similarly named tracked path is still walked |
| #8024 | AC-1 | `grep -c -F "T8024-I1" core/deploy/tests/test_leak_risk_modes.sh` at least 1 [READER-GRADED — the install regression suite's member line for this test reads 0 failed: the install arms T8024-I0 to I6, the update arms T8024-U1 to U5, the surfaces-only arm T8024-S1, the creation-site arms T8024-F1 to F3 and X1, and the population arms T8024-L0 to L9] | after install and after a full update, every file the Leak-risk register rows name at a path the install path resolves, backups included, reads 0600, and every S-40 copy reads 0700 on each folder and 0600 on each file; `--surfaces-only` runs no pass |
| #8024 | AC-2 | `grep -c -F "T8024-V1" core/deploy/tests/test_validate_install.sh` at least 1 [READER-GRADED — the arms T8024-V1 to V12, run by the install regression suite and directly] | V1 prints `[A11] FAIL` naming S-09 and 644; any group or other bit FAILs A11, and an owner-only deviation is an INFO beside a PASS |
| #8024 | AC-3 | `grep -c -F "T8024-N1" core/deploy/tests/test_leak_risk_modes.sh` at least 1 [READER-GRADED — the near-miss arms T8024-N1 to N5, at library level, after the install and after an update, and T8024-V3] | the 0640 working-state file under `/local-state/` and its 0750 folder keep their modes |

No row expects a null result: enumerated over the 11 per-issue rows and the one CIAC. Stage 6 C4 self-verification runs `release/tools/verify-release-plan.sh` on the committed plan.

## Quota Budget

**Verdict:** WARN (per `quota-budget-protocol.md` Checkpoint A, with the localization override below).
**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: 3 · Stage 7: 3 · Stage 8: 3
**Per-spoke cost estimate:** ordinal band low–moderate, low–moderate and lowest (size M, M, S), at roughly 5–8 % of a 5-hour window per spoke (source: heuristic; no telemetry medians).
**Assumed/stated remaining usage-window envelope:** unstated, so the conservative default of 50 % remaining applies.
**Estimated cumulative draw % (worst parallel batch):** Stage 5 × 3 ≈ 15–24 % of the window, about 30–48 % of the default envelope.
**Routing:** By arithmetic alone that is PASS. It is rendered WARN because six release hubs draw on the same account's window at once, so the default envelope is not a conservative stand-in for this run (decision-discipline Mechanism 1, Localization Check). Plan window-aware launches, and serialize Stage 5 if Checkpoint B reads less than about 50 % remaining at launch.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch, wave or singleton, at runtime, and is the load-bearing gate. A wave gets PROCEED/SERIALIZE/DEFER/REDUCE-scope; a singleton gets PROCEED/DEFER. STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API axis (DEFER-dominant), which Checkpoint A deliberately does not carry. Bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

## Parallelization Map (recorded 2026-11-27)

- **Verdict:** serialize after `worktree-sessions-reach-in-repo-homes`; expected merge position fifth of the six hubs started 2026-11-27, before `one-resolver-and-release-tool-routing`.
- **Release-gate:** after `worktree-sessions-reach-in-repo-homes` (#8019 ships the `/local-state/*` + `!/local-state/README.md` ignore pair; #8022's first criterion verifies it). If this release reaches Stage 12 first, the ordering goes to the operator at the Stage-12 Execute gate.
- **Soft edges (file contention, no hard edge):** with `worktree-sessions-reach-in-repo-homes` — line-range overlap on the placement standard's § Protections and References lines, append pattern on the gate-efficacy register, the regenerated hook registry (regenerate after merge, never hand-merge); with `fs-boundary-judges-every-listed-verb-operand` — the regenerated hook registry; with `rollups-select-projects-by-portfolio` — `core/deploy/deploy.sh`, only if both sides' conditional rows fire.
- **Coordination edge:** `one-resolver-and-release-tool-routing` keeps its switch off until this release's home and guard are on `main`; no merge-order edge with it.
- **Not started:** `install-wires-what-it-ships` declares overlapping install files (`setup-workspace.sh`, `update.sh`, `deploy.sh`); whichever starts second re-baselines.
- **Hard edges:** #8022 ← #8017 and #8024 ← #8017, satisfied (closed). Outward: #8027 ← #8022, #9004 ← #8022, #8032 ← #8024. Planned order before wave 3 of #8005 (shared files). No Tier-S edge (empty mover-set).
- **Reconfirm** with the `gh issue list --milestone … --jq` scan at Stage 9 entry.

## Release Outcome Statement

The milestone description carries this statement as approved at the Stage-4 gate; the hub wrote it there in Phase B, with "the guarded homes" read as the three registered in-repo homes (D-GuardScope A). The Stage-4 draft follows.

```markdown
### Release Outcome Statement

**AFTER** — Every in-repo ignored home is protected against a commit: `/local-state/` ships with a tracked README, and a commit guard and a CI check on every pull request refuse any file staged under the guarded homes other than their READMEs, a forced add included. The checks that walk the repository tree are inventoried, none reads a home's contents, and a regression test fails when one does. Leak-risk files get one permission policy, set at install and update and reported by the install validator.

**BEFORE** — No `/local-state/` README exists, and nothing stops a forced stage into an in-repo ignored home. No check proves that tree walkers skip the homes, and one root walker does not. Leak-risk files carry mixed modes, the installer sets none, and the install validator reports none.

**Actor(s):** Stage 6 Engineering spokes; the operator for the branch-protection registration.

**Success Indicator:** At Stage 13 the guard's forced-add arm and the CI job's fixture arm are green on `main`, the job's context reads as required in `main`'s branch protection, and validate-install reports a 0644 roster on a fixture.

**Limb owners:** README ships → #8022 · contents ignored → #8019 · commit guard and CI check → #8022 · tree walkers skip the homes → #8023 · one leak-risk permission policy, set and reported → #8024
```

It is reconciled with the milestone's current `Outcome:` line. The "ignored contents" limb now belongs to #8019 in the sibling release (template § 3.5: a limb the release does not deliver names the work item that carries it). "The guarded homes" reads per D-GuardScope.

## Release Class declaration

**Class: `novel`**, rendered at the Stage-4 gate (D-ReleaseClass). Trigger novel (b) fires: the plan carries D-class decisions (D-GuardScope, D-RequiredCheck). No cross-cutting trigger fires: no stage spec changes, no rule-defining surface, and one conditional in-bundle edge.

Differentiation posture:

- Engagement density **Standard**
- Stage 9 review depth **Deep**
- Stage 5 activation bias **ALL**
- Stage 13 outcome window **30-day**

## Operator Decisions (D-Gate Block)

Register note: every `design-principle-register.md` entry reads `last_verified_date: 2026-07-27`, more than 90 days old, so the citations below carry that staleness.

### D-GuardScope: Which homes does the commit guard cover?
**Gate input:** The placement standard § Protections (L127, "over every registered home") and its References (L263) against the card and ADR-231's class table ("for `/local-state/`"). The `/analysis/` and `/roadmaps/` homes carry ignore pairs today and no guard.
**Gate decision:**
- **(A)** Every registered in-repo home (`/local-state/`, `/analysis/`, `/roadmaps/`), each README excepted, from one list that #8023 also reads. *(recommended)*
- **(B)** `/local-state/` only. Amend the standard's two sentences to say so; the other two homes rely on their ignore rules alone.
- **(C)** `/local-state/` now, and record the other two homes as a follow-up. The standard stays as written until then.

**Blocks:** #8022 Stage 5 (the guard's list) and #8023 Stage 5 (CIAC-1).
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A):
  - ALIGNED DP-8 Security (`core/disciplines/build-philosophy.md:53`): a forced add is refused at every home the register lists.
  - ALIGNED DP-3 Maintainability (`:50`), provided the list is shared, with a parity arm against the table. Otherwise **CONFLICT.**: a third copy of the home set; mitigation: one shared list or a parity arm (R9).
  - ALIGNED DP-4 Simplicity (`:51`): the smallest change meeting the governing standard.
- (B):
  - **CONFLICT.** DP-8 Security: a forced add into `/analysis/` or `/roadmaps/` stays unguarded. Mitigation: record it as an accepted residual in the standard. The register default is EXPENSIVE, so this needs operator sign-off, which this gate is.
  - ALIGNED DP-4.
- (C):
  - **CONFLICT.** DP-3: the standard keeps stating a protection nothing delivers. Mitigation: a follow-up item, plus temporal wording in the standard.
  - **CONFLICT.** DP-8, as in (B).

**Reversibility / Confidence:** MODERATE / MEDIUM (widening or narrowing the list later is a code and test edit).
**Recommendation:** (A).

### D-RequiredCheck: When is the job's context registered, and what does its header declare until then?
**Gate input:**
- #8022 AC-3.
- gate-efficacy § Declared-required contexts: an `advisory` header is off the registration track, and a gate awaiting registration carries a HOLD row while its header reads `advisory`.
- The reconciler's UNREGISTERED class (a `required` header on an unregistered context) and UNDECLARED class (a registered context no declaration names).
- 24 contexts are registered on `main` today, and five sibling hubs are in flight.

**Common to (A) and (B):** once the context is registered, every open pull request whose latest run lacks the job is blocked until it runs CI again on a merge ref that includes the job. Sibling hubs reach this anyway when they merge `main` before their own Stage 9 and 12 re-checks. A plain re-run of an old run may not pick the job up `[ASSUMPTION – CONFIRM: a re-run reuses the run's original merge commit; plan on a fresh push or a merge from main]`.

**Gate decision:**
- **(A) Register after the merge.** The release PR ships the job, enforcing, with an `advisory` header and a HOLD row whose ending condition is "the operator registers the context at Stage 12". The operator registers right after the merge. A second tracked change then flips the header to `required`, flips the row to REGISTER and adds the `git-workflow.md` gates-table row.
  - Costs: a second PR after the milestone's one release PR. The reconciler reads UNDECLARED on every pull request in the repository, every hub's included, from registration until that change merges.
- **(B) Register immediately before the merge.** The release PR declares `required`, with a REGISTER row and the `git-workflow.md` row. The operator registers at Stage 12 once the job has reported green on the PR head, the reconciler is re-run green, and the PR merges.
  - Costs: the reconciler reads UNREGISTERED on this one PR from the commit that flips the header until registration. That reading is advisory, and it is read and recorded at merge. Sibling merges are hard-blocked in the minutes between registration and this merge, because their merge refs cannot carry the job yet.
  - One PR, as the delivery strategy states.
- **(C) Hold for a named condition.** Ship `advisory` with a HOLD row naming a condition, such as a specificity reading over a window of pull-request runs. Re-word AC-3 to "fails a CI check". Registration and the header flip come later, as their own operator step and change.

**Blocks:** #8022 Stage 6 (the header and disposition row), the Stage-12 sequence and AC-5's grading.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A):
  - **CONFLICT.** DP-5 Stability (`build-philosophy.md:52`): the repository-wide UNDECLARED window. Mitigation: land the flip as the first change after merge.
  - **CONFLICT.** DP-4 Simplicity (`:51`): a second PR for one milestone. Mitigation: none inside this option.
- (B):
  - **CONFLICT.** DP-5: the PR declares a registration before it happens (UNREGISTERED on this PR). Mitigation: register at the last moment, re-run the reconciler, and record the reading at merge. The register default is EXPENSIVE, so this needs operator sign-off, which this gate is.
  - ALIGNED DP-7 Track-all-edits (`:56`): one PR carries the whole change.
- (C):
  - ALIGNED DP-5.
  - **CONFLICT.** DP-8 Security (`:53`): the CI arm does not block a merge until the condition clears. Mitigation: the HOLD row names its ending condition and owner.

**Reversibility / Confidence:** CHEAP / MEDIUM (registration is reversible in settings; see the rollback ordering).
**Recommendation:** **(B).** It is the one-PR option, and its red reading is confined to this release's own PR. Registration is an operator action under every option; no spoke performs it.

### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Triggers per `release-class-taxonomy.md`.
- Fired: novel (b), ≥1 D-class decision (D-GuardScope, D-RequiredCheck).
- Not fired:
  - novel (a): a README is not a new reference doc, schema or skill.
  - cross-cutting (a): 0 stage files.
  - cross-cutting (b): 0 of the 6 rule-defining surfaces; `git-workflow.md` is not in the set.
  - cross-cutting (c): 1 conditional in-bundle edge.
  - routine (a): fails, because all three cards are P2.

**Gate decision:** (A) routine, (B) novel, (C) cross-cutting, (D) hotfix.
**Blocks:** the milestone-description `## Release Class` block and the per-class posture.
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A — no design-principle scope_predicate matches this option's change surface.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **(B) novel.** Engagement Standard · Stage 9 depth Deep · Stage 5 ALL · Stage 13 window 30-day. The hub-injected default and the epic's milestone map both say `novel`.

### D-Concurrency Posture: Stage-6 parallelism posture
**Gate input:**
- The A4 contention map: one § Protections table shared by all three cards, plus the shared installer and validator.
- `overlap_class` is `single-pr` throughout.
- D-C topology is SINGLE.
- One wave.

**Gate decision:** P0 fully serial, or a non-serial posture per `parallelism-posture-taxonomy.md`.
**Blocks:** Stage-6 dispatch.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A — no design-principle scope_predicate matches this option's change surface.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **P0.** No force-push under any posture.

**Recorded determinations (rule-computed, not gates):**
- **D-Version.**
  - WV-1: the guard, the CI job, the installer and the validator change behaviour, so the release is `versioned`.
  - Bump-class **minor**: hook, check and installer behaviour inside existing structure; no new skill and no new governance file.
  - Anchor `v5.14`, from the remote tags (235 `vX.Y` tags read by `ls-remote`).
  - Provisional display `v5.15`. Two minor siblings share the anchor and one sibling is `major`, so the number is recomputed at Engineering Commit 0 and claimed at Stage 12 by `release/tools/claim-version.sh`.
  - The Header `**Version**` cell carries the double-brace release-version placeholder, and the bump-class sits in the `**Bump Class**` row.
  - Escalation only on a (B) or (C) valve condition, and none is present.
- **D-C topology: SINGLE** (hub expectation; operator stance).
- **D-HomeOrder** (sibling ordering; framework-resolved by D-LocalState C plus the dependency-vs-release-gate pattern):
  - (i) **The sibling merges first** (expected order): this branch merges `main` before the Stage 9 re-check, the AC-1 row turns GREEN, and the placement standard's L127/L263 are re-baselined.
  - (ii) **This release reaches Stage 12 first:** the AC-1 row is still RED (baseline 0), so hold the Stage-12 merge for the sibling.
  - Escalation, only if the sibling stalls: a Tier 2 [SCOPE CHANGE] to the operator. Either carry the sibling's identical pair (same text, same position after `!/analysis/README.md`) with the second merger dropping its duplicate, or keep holding. The operator re-renders D-LocalState.
  - This release does not carry the pair on its own authority.

## Recommendations

1. **Tier 1 [ADJUST] — #8022 body** (operator-gated; the hub applies it):
   - **Affected Files:**
     - The `.gitignore` line reads: "not edited — the `/local-state/*` + `!/local-state/README.md` pair ships in `worktree-sessions-reach-in-repo-homes`, which keeps both narrower lines (`/local-state/telemetry/*`, `/local-state/process-catalog/*`)".
     - The guard line reads: "`core/hooks/git-pre-commit-pii.sh` (git's one pre-commit slot) or a guard it runs; `core/hooks/git-pre-push-pii.sh` for a push-time arm; their test suites".
     - Add `core/standards/gate-efficacy-standard.md`, `core/standards/instance-data-placement-standard.md` (§ Protections and References) and `core/disciplines/architecture-overview.md`.
   - **AC-1:** "Verify, after `worktree-sessions-reach-in-repo-homes` merges, that …" (rest unchanged).
   - **AC-2:** "predicate: staging a file under a guarded home with `git add -f` makes the commit guard fail the commit whatever the PII guard's mode dial reads; method: a guard test."
   - **AC-3:** "predicate: a pull request whose diff adds any file under a guarded home other than its README fails the CI check, which reports on every pull request; method: a workflow fixture run."
   - **New AC-5:** "Verify that the operator has registered the CI check's context as required on `main`; method: a read-back of branch protection at Stage 13."
   - **AC-4:** add "and a commit adding `local-state/readme.md` fails".
   - **Scope sentence:** "the guarded homes" per D-GuardScope.
   - CHEAP · HIGH.
2. **Tier 1 [ADJUST] — #8023 body** (operator-confirmed G-PL4 re-scope):
   - **Evidence:** add "[INFERRED: a static pattern census at `8ed5e273` found no walker run by `deploy.sh --check` that reaches the repository-root homes. It found root walkers outside the deploy checks: the plan verifier's glob-pathspec resolver and the context-budget auditor's agents scan. The census does not resolve variable roots or callees; the Stage-5 inventory does]".
   - **Affected Files:** the three named files become "conditional on the Stage-5 inventory"; add `release/tools/verify-release-plan.sh`, `core/deploy/tests/` (a new test) and its script-execution allowlist rows.
   - **AC-2:** "predicate: with 1,000 files planted under `local-state/` in a fixture copy, the inventoried walkers report the same findings as on a clean copy, and the same fixture with one walker that reads the homes reports a difference; method: a fixture run comparing finding lines, never a real checkout's homes."
   - MODERATE · HIGH.
3. **Tier 1 [ADJUST] — #8024 body:**
   - **Evidence:** refresh with the mode bits above (register rows, not file names): the registered scan list 0600; a second, unregistered scan list 0600; the roster, its clarification queue and two backups 0644; `scan.sh` 0755; the container 0755; the leak-risk home absent.
   - **AC-1:** "every file the placement standard's Leak-risk register rows name, at its current path, is mode 0600, and every folder that holds only leak-risk content is 0700".
   - **Documentation Impact:** "verify — the standard already names the policy; move its § Protections delivery cell to present tense".
   - **Notes:** "use the existing accessors in `lib-instance-path.sh`; add no resolver function there".
   - CHEAP · HIGH.
4. **D-GuardScope:** (A). **D-RequiredCheck:** (B). **D-ReleaseClass:** (B) novel. **D-Concurrency Posture:** P0. The rendered gates are above.
5. **Milestone description blocks for the hub's Phase B3 PATCH (drafts):**
   - `Release-identity mode: versioned · when-to-version: WV-1`
   - `## Release Class`:

     ```
     Class: novel
     Rationale: novel (b) fires (two D-class decisions); no cross-cutting trigger.
     Differentiation posture:
       - Engagement density: Standard
       - Stage 9 review depth: Deep
       - Stage 5 activation bias: ALL
       - Stage 13 outcome-window: 30-day
     ```
   - `### Release Outcome Statement`, as drafted above, replacing the plain `Outcome:` / `Before:` lines.
   - `## Parallelization Map (recorded 2026-11-27)`:
     - Release-gate after `worktree-sessions-reach-in-repo-homes` (#8019's ignore pair; AC-1 verification).
     - Line-range overlap with it on the placement standard's § Protections and References lines, and append-pattern on the gate-efficacy register.
     - Release-gate before the wave-6 cutover flip; `one-resolver-and-release-tool-routing` keeps its switch off, so no merge-order edge with it.
     - Planned order before wave 3 (shared files).
     - Native edges to wave 4 (#8027 ← #8022; #8032 ← #8024).
     - `install-wires-what-it-ships` is not started and declares overlapping install files; whichever starts second re-baselines.
     - No Tier-S edge (empty mover-set).
     - Reconfirm with the `gh issue list --milestone … --jq` scan at Stage 9.
6. **Out-of-scope discoveries:**
   - **(a)** A second PII scan list named in `.gitignore` sits in today's container at 0600 and no surface-register row names it. That is a new-surface-checklist gap for the placement standard's owner. Severity Minor · `follow-up: privacy`.
   - **(b)** The draft-file controls do not admit the tracked READMEs of the registered homes. If the CONDITIONAL row does not fire, this is a gate over-firing on a sanctioned shape. Severity Cosmetic · `follow-up: none · bug`.
   - **(c)** A root walker run from the main checkout also descends into `.claude/worktrees/`, which costs more than the homes. This is inside #8023's capability, so it goes into its Stage-5 inventory, not to a new item.
7. **Below-band finding.** 10 raw points (about 12 effective as novel) sits below the 15–25 band, so the fixed per-release cost is spread over few points. The epic records that adding this milestone to any neighbour takes that one past 25.
8. **Per-issue closure at Stage 13:** mark #8022, #8023 and #8024 as closed at Stage 13, each after its acceptance criteria are graded MET. AC-5 is graded after the operator's registration.

**Canonical-checklist attestation:**
- **Ran:**
  - A0: G-PL5 (MISS), PT-1..4 with subsumption, ticket–architecture reconciliation, and the advisory lens.
  - A0.5, A0.6, A0.7 (SKIP with control), A0.8, the Parallelization-Map check and the A0 confidence gate.
  - A1, A1.5 (Form X), A2, A3 and A3.5.
  - A4: within-release, cross-PR, the roster (n=1), the structural sub-audit (suppressed) and the sibling-merge trigger (scheduled).
  - A5, with the CIAC lint run, and A6.
- **N/A with reason:** T1's Check 53 (read-only spoke); Phase B (the operator's).

## Evidence (Stage 4)

- Run directory: `${SCRATCH_BASE}/spoke-4-9203-yVddte`
- Worktree: the hub's session worktree on `release/in-repo-home-is-guarded`, HEAD = `origin/main` = `8ed5e273`. Not the primary checkout.
- **Probe records** (instrument · denominator · control arm):
  - **R-W1:** `find`-from-root constructs, by a python scan over 262 non-test tracked code files: 11. Control: the same scan over `core/deploy`, `release/tools`, `.github/workflows` and `core/hooks`, tests included (594 files), found 19 `find`, 20 recursive-grep, 8 `os.walk` and 23 `rglob` constructs, plus 58 `git ls-files` uses.
  - **R-W2:** recursive grep from the root: 0. Control: R-W1's 20 recursive greps, every one scoped to a subtree or the memory folder.
  - **R-W3:** `glob(..., recursive=True)`: 2, both bound in Checks 42 and 50 to module subtrees (read in `deploy.sh`).
  - **R-W4:** the corpus walkers' root: `stamp-node-frontmatter.py` defaults `--root` to the operations projects tree; `build-doc-index.py` and `compose-portfolio.py` require `--root`. `deploy.sh` call sites for the three: 0 (control: `check-doc-links.py` 3).
  - **R-W5:** tracked-first walkers: enumeration-drift, mirror-pair-parity and selftest-coverage read `git ls-files` under a git root.
  - **R-W6:** the plan verifier's root `find`: `release/tools/verify-release-plan.sh`, at the scope-assertion glob resolver.
  - **R-W7:** a second pass for `os.walk`, `rglob`, `**` globs and variable-rooted `find` over the 37 non-test code files outside the first scan's four directories (`docs/scripts`, skill scripts, `update.sh`, `install.sh`). 29 hits. One is a root walker: the context-budget auditor's agents scan. Two installer `os.walk` sites (`setup-workspace.sh`) have roots for Stage 5 to read.
  - **Blind spots, stated:** none of these passes resolves a root that arrives through a variable, or follows a walker reached only through a callee. Stage 5's inventory closes both.
  - **`check-ignore` probe:** `local-state/x` paths not ignored; controls matched.
  - **Guard absence:** 0 / 0 / 0, against controls 57 and 2.
  - **Placement baselines:** "until the guard ships" 1, "a forced add included" 1; architecture-overview "not yet provisioned" 1.
  - **`stat` mode bits** on the registered leak-risk surfaces (counts above).
  - **Open issues:** 733 under `--limit 5000`, not truncated.
  - **Native-dependency endpoints:** live (control: #8022 has 3 edges).
  - **Remote heads:** 1 `release/*` plus `main`.
  - **Tags:** 235 `vX.Y`.
- **Mode-bit read discipline:** names and modes only, by `stat`. No leak-risk file content was opened. Backup files are referred to by register row, not by name.
- **Not read:** the deployed skill-editor exemption list. It decides nothing here (conjunct 1 fails for every write-set path).
- **Run-directory deviation:** one probe redirected a `git show` copy of a tracked hook source (public content) to a fixed path in the system temp folder outside the run directory. It was not read back and not posted. Recorded here per the run-directory discipline.
- **Sibling surfaces read** (trusted owner-authored comments only):
  - `worktree-sessions-reach-in-repo-homes`: the Stage-4 plan, the "Decision Recorded" and gate comments on #9149, and the #8019 Stage-5 design and its hub consumption on #9154.
  - The Stage-4 plans of `rollups-select-projects-by-portfolio`, `issue-body-is-the-scope-of-record` and `fs-boundary-judges-every-listed-verb-operand`.
  - The Affected Files of #8020 and #8021.
  - PR #9201's head file list.
- **Hub claims re-grounded:**
  - Claim 4 holds: no `local-state/` in the primary (the hub's read). There are 22 tracked files naming `local-state`, of which the code readers and writers are `.gitignore` (2 narrower rules), the telemetry resolver in `lib-instance-path.sh` and its test, the process-catalog generator's self-test fixtures, and the config template and schema. No tracked writer defaults into the home.
  - Claim 7 is refined: both scan lists now read 0600.

Control firings:
- `core/hooks/block-destructive.sh` BLOCK-DESTRUCTIVE-022 refused one pre-post scan command. It invoked `core/deploy/tools/path-leak-patterns.sh` through a shell variable holding the worktree path, which the hook cannot resolve to an allowlist entry. The objection was to the spelling, so I took the retry the control names: the same script by its literal repository-relative path, run from the worktree root. Nothing else was changed, and nothing ran under the refused command.

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-27)

Recorded on #9203 (comment 7234042856): **D1** — the release plan, the Release Outcome Statement draft, the G-PL4 re-scope of #8023 and the Tier-1 body edits to all three cards approved; **D-GuardScope (A)** — every registered in-repo home, each README excepted, from one list #8023 shares; **D-RequiredCheck (B)** — the release PR declares `required`, and the operator registers the context at Stage 12 once the job is green on the PR head, re-runs the reconciler green, then merges; **D-ReleaseClass `novel`**. Recorded determinations: D-Version minor (provisional `v5.15`), D-C SINGLE, posture P0. Deferred to the Stage-12 Execute gate, only if it arises: D-HomeOrder.

### Stage 5 Collective Review scope lock (operator, 2026-11-28)

Recorded on #9205 (comment 7236696308): **CR-1** — scope-lock with the recommended disposition for every bundled item; **D-Bypass (#8022) C** — the commit-time check runs even under the bypass, and the push-time check honours it; **D-CIArm (#8022) A + squash-merge** — the CI job reads the merge tree, and its refusal prescribes removing the file and squash-merging the pull request; **D-ScanExec (#8024)** — the S-15 scan script is run as `bash <path>`, so 0600. Bundled under CR-1: #8023 D-8023-WalkerSet A, D-RegressionGuard B and its AC-2 wording; #8024 D-FolderLimb A, D-S40Scope A, its AC-1 wording, CD-2 and CD-3; and CIAC-1's reading. Hub determinations: the home list is a static set inside `core/hooks/git-pre-commit-homes.sh`, read with `--print-homes`; D-GitWorkflowDrift is reconciled in this change. Folded into the Stage-6 specs: #8022 adversarial FM-1 (partial-commit arms) and FM-2 (the squash-merge remedy sentence), and the #8023 and #8024 items the record lists.

## Deviation Log

| ID | Stage | Deviation | Decision |
|---|---|---|---|
| DEV-1 | 4 | #8022's AC-3 is split into AC-3 (the job fails a fixture and reports on every pull request) and AC-5 (the operator's registration, read back from branch protection); AC-4 gains the `local-state/readme.md` case arm; AC-1 becomes a verification after the sibling release merges. The AC baseline for #8022 moves from 4 to 5 | operator, Stage-4 gate (D1) |
| DEV-2 | 5 | #8022's host is H-B, a sibling detector `core/hooks/git-pre-commit-homes.sh` that the PII guard runs at its two input points (staged at pre-commit; `--commits` when the pre-push hook runs the guard) and that the CI job runs directly. GUARD-SEPARATE-SCRIPT, GUARD-IN-PII-HOOK, GUARD-PUSH-ARM (for the pre-push suite only) and CONTEXT-DECLARED-REQUIRED fire and are promoted to concrete rows in § File Change Matrix. The GUARD-SEPARATE-SCRIPT wiring rows (`setup-workspace.sh`, `validate-install.sh`, `test_git_hooks_install.sh`) do not fire for #8022; `setup-workspace.sh` and `validate-install.sh` stay #8024 rows | #8022 Stage-5 design; Collective Review |
| DEV-3 | 5 | #8022 rows added beyond the Stage-4 matrix: `core/hooks/tests/git-pre-commit-pii-env-inputs.test.sh` (the PII guard now needs its sibling in that suite's geometry), `.github/workflows/pii-push-scan.yml` (its scan now also reports in-repo home content), and `core/process-catalog/definitions/controls-register.tsv` with its regenerated views (two rows) | #8022 Stage-5 design |
| DEV-4 | 5 | #8022 conditionals that did not fire: REGISTRY-NAMES-GUARD and NO-VERIFY-RATIONALE-NAMES-GUARD (D-Registry: the registry indexes `block-*` hooks and its git-hook prose stays true), DRAFT-GATE-ADMITS-HOME-README (D-DraftGate: `BLOCK-DRAFT-001` and the Draft-file gate, both warn, report `local-state/README.md`; an accepted residual) | #8022 Stage-5 design |
| DEV-5 | 5 | **D-Bypass C.** The commit-time (staged) call into the home detector runs even when `CLAUDE_HOOK_BYPASS` is set: it sits ahead of the PII guard's bypass exit. The push-time path keeps honouring the bypass, so `git-pre-push-pii.sh` is not restructured. The operator's escape hatch is the hook-skip flag, which agents are denied. The design's drafted decision record, written for option A, is adapted to C and lands with status `Proposed`, adding its ADD row. Arm G6a flips to refused; G6c (a bypass `commit-tree` commit followed by a push, accepted) is the recorded residual | operator, Collective Review |
| DEV-6 | 5 | **D-CIArm A + squash-merge remedy.** The CI job reads the pull request's merge tree. Its refusal prescribes removing the file and squash-merging the pull request, so the commit that added it is dropped (adversarial FM-2) | operator, Collective Review |
| DEV-7 | 5 | **Adversarial FM-1.** Partial-commit arms G7a (a commit naming only a non-home path while a forced home path sits in the real index is accepted) and G7b (a commit naming the home path is refused), and RED-2 variant V6 (the staged read with `GIT_INDEX_FILE` unset), are added; RED-1 is re-counted from the suite as written | Collective Review (folded into the Stage-6 spec) |
| DEV-8 | 5 | **Adversarial PR-1 wording.** Wherever the design's text said the required CI job catches what a bypass lets through, the shipped text states that the local hook layers are the only layer before publication, and that the CI job keeps home content off `main` but does not stop a branch being published | Collective Review |
| DEV-9 | 5 | **D-GitWorkflowDrift.** `core/rules/git-workflow.md` § Repository-Integrity Gates drops its stale "three" count and tables every gate branch protection registers from this workflow, the ADR-number integrity gate included, plus the new job's row | hub determination at the Collective Review (Tier 1 [ADJUST]) |
| DEV-10 | 5 | **Home list.** The home set is a static set inside `core/hooks/git-pre-commit-homes.sh`. `--print-homes` prints one bare name per line (#8023's reader appends `/`), and `--check-parity` holds it equal to the placement standard's § Registered in-repo git-ignored homes table | hub determination at the Collective Review |
| DEV-11 | 5 | CIAC-1 counts as met when no walker carries its own home list and the test is the list's only reader (adversarial PR-2 on #9236) | Collective Review (CR-1) |
| DEV-12 | 6 | The #8022 rows of § Verification Plan are re-bound to the design's arm labels (AC-Binding: an amended criterion updates its bound row in the same change) | #8022 Engineering spoke |
| DEV-13 | 6 | The #8023 and #8024 rows of § File Change Matrix and § Verification Plan stay as Stage 4 planned them. Their Collective Review amendments (#8023: D-8023-WalkerSet A, D-RegressionGuard B and its widened census, the AC-2 wording; #8024: D-FolderLimb A, D-S40Scope A, D-ScanExec at 0600, the AC-1 wording, CD-2, CD-3) change their resolved sets, and each card's own Engineering spoke amends its rows in its slice | #8022 Engineering spoke (hub instruction) |
| DEV-14 | 6 | The placement-standard edits are written against `main`'s current text. The sibling release `worktree-sessions-reach-in-repo-homes` rewrites the same § Protections cell and the paragraph after the homes table; the two reconcile at the Stage-9 merge from `main` | #8022 Engineering spoke (hub instruction; plan R6) |
| DEV-15 | 6 | **The decision record takes ADR-242, not 243.** The hub's instruction was to take the number from `release/tools/renumber-adr.py --detect` and also exclude every number an open sibling release branch holds; three sibling branches hold 242. The tool's binding oracle at authoring read anchor 241 and next-free 242 (with 242 a branch-only claim, which never binds), and the required ADR-number integrity gate refuses a gap, so 243 would have turned that required context red on this pull request until a sibling's 242 reached `main`. 242 keeps the gate green; whichever claimant merges later is moved by the renumbering tool at merge time, as ADR-241's own provenance records. Outside the record and this plan, the record is cited by its slug token (`commit-time-home-guard-runs-under-hook-bypass`, in the double-brace ADR form the Stage-12 stamp resolves), so a mainline citation of another 242 merged into the same file cannot be mis-rewritten. Tier 1 [ADJUST] | #8022 Engineering spoke |
| DEV-16 | 6 | `core/process-catalog/definitions/pack.json` joins the matrix: the catalog's minting rule raises `highest_minted_id` in the change that mints a control ID, and the page-validation check refuses C-456 and C-457 (rule R2) until it does. Tier 1 [ADJUST] | #8022 Engineering spoke |
| DEV-17 | 6 | Arm T8022-W3 added beyond the design: with the detector missing, a benign commit under `CLAUDE_HOOK_BYPASS` is refused, because under D-Bypass C the commit-time check cannot be skipped by the bypass and a check that cannot run fails closed. The suite also carries T8022-G6c (the push-time residual, accepted), T8022-G7a and T8022-G7b (FM-1), and T8022-Z1 (the source checkout's status is unchanged), so it has 40 arms; RED-1 measured 31 FAIL and 9 PASS. Tier 1 [ADJUST] | #8022 Engineering spoke |
| DEV-18 | 6 | The `fcm-delivery` family cannot interpret the `local-state/README.md` ADD row: its path recognizer's first-segment set names `core`, `operations`, `release`, `docs`, `packages`, `projects`, `roadmaps`, `.github` and `.claude`, and neither `local-state` nor a top-level file. Three rows read as uninterpreted (that README, `update.sh` and `.gitignore`), so FCM-COVERAGE reads SKIP. The verifier is a #8023 conditional row; the gap is recorded for the hub, not repaired here | #8022 Engineering spoke (finding) |
| DEV-19 | 6 | The In-repo home content gate went red on its first CI run: the job runs the guard by its repository-relative path, and the self-test re-invoked itself by that relative path from inside its scratch repository, so every arm exited 127. The self-test now takes its own path absolute, and arm T8022-C1 runs it the way CI does (RED 39/40 against the previous guard, GREEN 40/40). The source_observations card number in the decision record was moved out too, because the Issue-reference validity gate does not read frontmatter as a reference block | #8022 Engineering spoke (self-repair, Retry pattern) |
| DEV-20 | 6 | **#8023 File Change Matrix resolved** to its Stage-5 inventory as the Collective Review amended it (D-8023-WalkerSet A). CONDITIONAL:ROOT-WALKER-FIX fires for the verifier; the deploy, doc-link, canonical-structure and selftest-manifest conditionals do not fire. Inventory additions: the import tracer and its suite header, the budget scan with its regenerated package and sidecar, and the durability copy. `release/tools/blast-radius.sh` becomes an unconditional behavioural edit (its root resolution), not the design's one marker comment; `release/tools/tests/test_verify_release_plan.sh` flips from not edited to edited, with two fixture files (DEV-27); the placement standard joins the #8023 rows. Tier 1 [ADJUST] | #8023 Engineering spoke |
| DEV-21 | 6 | **Root order for both tracers** (adversarial CD-1(a)): `--root`, then the working directory's git toplevel, then the toplevel of the script's own checkout, and only then the working directory. "Before any working-directory fallback" is read as preceding the `pwd` fallback: a working directory inside another work tree still selects that work tree, as before. Cascade: both tracers' usage text, the domain suite's enumerated git calls, and the `--root` default cell of `release/references/protocols/blast-radius-protocol.md` (outside the design's matrix, added). Arms T8023-A3 and T8023-A4 run both tracers from a non-git parent of the fixture with no `--root`. Tier 1 [ADJUST] | Collective Review (CR-1) |
| DEV-22 | 6 | **Adversarial FM-2.** The import tracer's tracked branch requires a non-empty index list; an empty one (a non-git copy nested in a work tree) falls back to the walk, as the sibling tracer's empty-list branch does, so the tracer never reports zero importers over an empty population. Arms T8023-E3 (the nested copy is scanned) and T8023-E3M (a mutant without the fallback is caught) | Collective Review (folded into the Stage-6 spec) |
| DEV-23 | 6 | **Marker wording.** Neither tracer's marker claims "non-git root only": after DEV-22 each fallback walk runs for any root whose index lists nothing, and each marker says so. The verifier's marker keeps "non-git root only", because its index branch takes every work tree. Each tracer's marker landed in the same commit as that tracer's root-resolution fix, never before it. The verifier's marker landed with its index branch, one commit before the tracer fixes: the Collective Review clause (no such marker before the fix) is read as covering the two tracer fallbacks, the only ones the ancestor-root case reaches | Collective Review (FM-1); #8023 Engineering spoke |
| DEV-24 | 6 | **Census widened** (adversarial FM-4): K1 takes `-L`/`-H`/`-P` and a `/` after the operand; K3 takes `-r` and `-a`; K7 takes the `tar -C <root> .` form; K8 takes `copytree(` and `Path(<root>).rglob(`. The sensitivity input carries at least two spellings per shape (18 tagged lines, the expected count derived from the tags), the specificity input a subtree twin of each spelling, and the coverage claim is an enumeration with a stated boundary (other variable names, arguments, computed paths, callees, and other spellings are the inventory's, not the census's). Over the tracked code at the slice's base the widened census reads the same 5 unmarked hits | Collective Review (CR-1) |
| DEV-25 | 6 | **Home list** (adversarial PR-3): the test's `homes_list` runs `core/hooks/git-pre-commit-homes.sh --print-homes` and appends `/` to each name; `HOME_LIST_REL` is that detector path. INT-1 reads: outside comments the test names no registered home literally, and T8023-F2's `homes=<k>` equals the number of names `--print-homes` prints | hub determination at the Collective Review |
| DEV-26 | 6 | **Adversarial PR-4.** The design's reason for E over A on the budget scan is corrected: A keeps the filesystem walk on a non-git root, so it would not zero the agents row. E is chosen because the script's roster already pins the three module trees and every tracked agent file sits under them. The decision is unchanged | Collective Review (folded into the Stage-6 spec) |
| DEV-27 | 6 | **DEV-18 resolved.** The `fcm-delivery` first-segment enum gains `analysis` and `local-state`, so it lists every top-level directory the repository tracks: its modules, `docs`, `packages`, `.github`, and the three in-repo homes, each tracked as its README. It is a path-recognition list, not a home list under CIAC-1: it carries no README exception, excludes nothing, and no walk reads it, and a home missing from it degrades to an uninterpreted row (FCM-COVERAGE non-PASS), never a silent pass. The plan's two top-level-file rows (`update.sh`, `.gitignore`) stay uninterpreted by design (arm A13 pins a top-level row with no directory as uninterpreted), so FCM-COVERAGE still reads SKIP on this plan. New suite arm A14, RED before the enum change and GREEN after. Tier 1 [ADJUST] | #8022 finding, routed to the #8023 slice by the hub |
| DEV-28 | 6 | **Adversarial FM-3 wording.** The placement standard's tree-walk clause states only what holds and what the test enforces, scoped to the walkers the test runs: they skip the homes by reading the git index or by rooting below the repository root, and the test fails when one of them reads a home, or when a new root walk of the shapes it lists appears unmarked. The design's first clause ("every tree walker ... enumerates the git index or a named subtree") is not written, because the inventory's ignore-bound, root-listing, outside-the-repository, CI-only and sweep rows do neither | Collective Review (CR-1) |
| DEV-29 | 6 | **#8024 File Change Matrix resolved** to its Stage-5 design as the Collective Review amended it. CONDITIONAL:NEW-INSTALL-MODE-TEST fires (`core/deploy/tests/test_leak_risk_modes.sh`); INSTALL-ARM-IN-E2E and REGRESSION-STEP-BUDGET do not. Rows added beyond the Stage-4 matrix: the library, `install.sh` (its two fallback scaffolds are creation sites; design item 10), the extractor (DEV-35), the placement standard, and the new suite's allowlist and roster rows. Tier 1 [ADJUST] | #8024 Engineering spoke |
| DEV-30 | 6 | **D-ScanExec B.** The S-15 script is run as `bash <path>`, so it takes 0600 like every other leak-risk file. The library carries one file mode and one folder mode and no executable kind; the design's S-15 clause in the § Protections cell is not written; arms T8024-I2, L3, U1 and V6 expect 0600 | operator, Collective Review |
| DEV-31 | 6 | **CD-2.** The second PII scan list, the S-15 script's needle file, joins the population as register row **S-48** (Leak-risk, source `design`), through the five steps of the standard's new-surface checklist: classified Leak-risk as an operator scan list (§ Classifying a surface, question 3); registered with no path token, so no token-registry row; no provisioning step, because the operator places it and nothing writes it; protected by the permission policy this release delivers; validated by A11 and by the reads recorded in the spoke output. Its leaf is the one the tracked `.gitignore` scan-list line already names; the library's backup predicate covers its dot-prefixed form. Everywhere outside the register row it is named by row | Collective Review (CR-1) |
| DEV-32 | 6 | **CD-3.** The setter stays exact (0600 for a file, 0700 for a folder). The validator's A11 FAILs a leak-risk file or folder that has any group or other permission bit, and reports any other deviation from the exact mode (a 0400 file, for instance) as an INFO beside its verdict. Arms T8024-L6b and T8024-V11 | Collective Review (CR-1) |
| DEV-33 | 6 | **Adversarial FM-1.** Every public library function returns 0 whatever a `find` or a `chmod` does, so a host under `set -Eeuo pipefail` is never stopped by the pass; a failure is a counter and a `WARN-LEAK-RISK-MODE:` line on stderr. "Changed" is read from the post-state: a member counts as changed only when a re-read shows fewer off-policy entries than before, and a member still off the policy counts as failed, so a `chmod` that returns 0 and changes nothing is a failure, never a change, and a failure alone never sets the update path's change flag. The folder pass runs batched and then once more per folder in pre-order, so a folder made readable is descended in the same pass. Arms: T8024-L8 (a no-op `chmod`), L9 (an unreadable folder chain), E1 to E3 (the contract under `set -Eeuo pipefail`), and the immutable-file arms T8024-I6 and U1, which require the install to exit 0, the update to reach its hook-refresh phase, a warning naming the file, and A11 to FAIL naming it | Collective Review (folded into the Stage-6 spec) |
| DEV-34 | 6 | **Adversarial PR-2.** A11 SKIPs only when the instance resolver is absent from the source repository too, the shape of every pre-existing validator fixture; with the resolver present and the leak-risk library absent it FAILs ("cannot be evaluated"). The design's V7 is split into V7a (SKIP) and V7b (FAIL), and arm 5 of `test_validate_install.sh`, which copies the resolver into its fixture, copies the library too | Collective Review (folded into the Stage-6 spec) |
| DEV-35 | 6 | **Adversarial PR-3.** `core/deploy/extract-roster-needles.sh` creates S-08 with `touch` when it is absent, so that `touch` runs under `umask 077` as the seventh creation site, with arm T8024-X1 and a mutant sensitivity arm. The runtime writers of S-09 and S-10 between updates are a named residual (§ Named Residuals) | Collective Review (folded into the Stage-6 spec) |
| DEV-36 | 6 | **Adversarial PR-5.** T8024-N3 is worded as a glob-width guard: the S-40 pattern does not reach an S-41-shaped copy. S-41's conditional Leak-risk content is a named residual for the installer milestone | Collective Review (folded into the Stage-6 spec) |
| DEV-37 | 6 | **Adversarial FM-3.** The S-40 walk is measured on a fixture the size of the largest live copy (about 139,000 files in about 21,800 folders) by the opt-in arm T8024-P1, which runs only when `T8024_MEASURE_FILES` is set. Measured on the Stage-6 machine at 139,000 files in 23,307 folders, every entry off the policy: the findings pass 7.8 s, the enforce pass 13.9 s, and the findings pass at the policy 8.0 s. The walk's cost bound is the installer milestone's S-40 retention rule (§ Named Residuals) | Collective Review (folded into the Stage-6 spec) |
| DEV-38 | 6 | **Adversarial FM-4.** CONDITIONAL:REGRESSION-STEP-BUDGET fires above about 101 minutes on either gating step of `.github/workflows/install-tests.yml` — the main regression step and the fresh-HOME step, each budgeted at 135 minutes with a third of headroom. When it fires, both step budgets and the job limit are re-derived by the job header's rule. Locally the new suite's real install took 8 s and each real update 8 to 12 s; the two CI steps' durations are read on the release PR's CI run at Stage 7 | Collective Review (folded into the Stage-6 spec) |
| DEV-39 | 6 | **Adversarial FM-5.** The register-parity arm T8024-L0 parses rows with `S-[0-9]+`, and its sensitivity arm plants S-100 | Collective Review (folded into the Stage-6 spec) |
| DEV-40 | 6 | **Adversarial PR-1 (AL-LOW).** The library's header lists the literals it composes outside the resolver (the S-10, S-15, S-33 and S-48 leaves, the backup-name predicate and the S-40 folder glob) as repoint targets for the one-resolver release; the hub records that obligation against that release. D1 stands | Collective Review (PR-1 recorded obligation) |
| DEV-41 | 6 | **Cascade N/A rows.** `core/process-catalog/engineering-harness/validate-install.md` (its Mode A count and check list, lines 25 and 46) and `install-platform.md` (line 72) will not list A11 or the new count; both are outside the matrix, stale already, and their citations are rewritten at Stage 12 | Collective Review (the adversarial review's cascade rows) |
| DEV-42 | 6 | **Test-design additions beyond the design, each within its arms' intent.** The four override variables are unset at the top of `test_validate_install.sh` rather than per call; the creation-site arms (T8024-F1 to F3) run every scaffold copy of the three scripts, extracted, against an empty sandbox, each with a mutant that drops the `umask 077` wrapper and must create at 0644; leaf-source parity arms (T8024-L2b) hold the library's composed leaves equal to the template, register row, `deploy.sh` line and `.gitignore` line each one copies; T8024-V11 (an owner-only INFO) and V12 (S-48 at 0644 FAILs) are added; T8024-S1 pins that `--surfaces-only` runs no pass. Tier 1 [ADJUST] | #8024 Engineering spoke |
| DEV-43 | 6 | **Self-repair (Retry pattern), test-only.** The first green run of the install regression suite read the new suite at 120 passed, 2 failed: T8024-L0's own sensitivity and specificity arms tested membership with a `case` statement inside a command substitution, which bash 3.2 misparses. The parity logic was right (it reported S-100 unhandled); the arms now use a helper. Four arms in the suite as first written (L3, L4, L6 and L6b) also read the library's counters from a subshell; that was found by reading, before the green run | #8024 Engineering spoke |

## Named Residuals

What this release leaves for a later one, each with its owner. Every residual is a known gap, not a defect of this release.

| # | Residual | Why it is left | Owner |
|---|---|---|---|
| NR-1 | The governed leak-risk home, and any copy of it an operator made by hand, gets no mode from the pass (D-FolderLimb A). S-46 lives only there | No accessor resolves the home, and provisioning it at the policy is the installer milestone's | install-provisions-every-home (#8027) |
| NR-2 | S-19, an embargoed security-fix run, gets no mode | No install-time path: a run's class is resolvable only once the resolver takes it as an argument | one-resolver-and-release-tool-routing (#8020), then the migration milestone (#8032) |
| NR-3 | S-41 copies keep their modes, although an S-41 copy is Leak-risk while it holds an allowlist copy that carries an operator identifier (adversarial PR-5) | S-41's class is Working state in the register, and its home and split are the installer milestone's | install-provisions-every-home (#8027) |
| NR-4 | Between updates, a file the operator's tools rewrite (the roster and its clarification queue among them) takes whatever mode its writer leaves; A11 reports it, and the next full update repairs it (adversarial PR-3) | The runtime writers are agent or operator edits outside the platform's scripts | the migration milestone (#8032), which moves them under the leak-risk home |
| NR-5 | The pass walks every S-40 copy on every full update and every validator run, and the copies accumulate one full container copy per update (adversarial FM-3) | Retention of S-40 is the installer milestone's decision; the measured cost is in DEV-37 | install-provisions-every-home (#8027) |
| NR-6 | The library composes six literals outside the resolver (adversarial PR-1, DEV-40) | D1: this release adds no resolver function | one-resolver-and-release-tool-routing (#8020) |
| NR-7 | S-10 is resolved beside the container, not beside a roster that `PMO_PEOPLE_ROSTER` moved elsewhere | The register row and the queue template both place it in the container | one-resolver-and-release-tool-routing (#8020) |
| NR-8 | A member that is a symbolic link is neither followed nor reported | Following a link would let the pass change a file outside the population | no owner yet; held for the Stage-9 filing step |
| NR-9 | The Windows install and update proxies set no POSIX modes | The platform has no Windows install path that the policy could reach | — |
| NR-10 | The `.gitignore` stray-copy backstop matches the scan lists' and the roster's exact names only, not their backup forms | `.gitignore` belongs to the sibling release; held for the Stage-9 filing step | Stage-9 filing step (`follow-up: privacy`) |

## Operational Deployment Manifest

Layer-2 activation for Stage 12. The default propagation carrier, `./update.sh --surfaces-only`, runs no leak-risk mode pass, and `core/deploy/deploy.sh --deploy` does not either, so the policy reaches an existing install only through a full update.

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/deploy/lib-leak-risk-modes.sh`, `update.sh` | the operator's install: the Leak-risk primaries, their backups and the S-40 copies | update: `./update.sh` (full) — activates the leak-risk mode pass; the first run tightens the Leak-risk primaries, their backups and the S-40 copies | validate-install A11 PASS |
| 2 | `core/config/allowlists/script-execution-allowlist.txt` | the deployed hook-tier allowlist | the Stage-12 deploy | the new suite's four invocation forms are present in the deployed copy |

## Verification Evidence

Populated after Stage 12 execution. Stage 6 self-verification for each slice is recorded in the release pull request's `### Verification Evidence` block and on that card's Stage-6 sub-task.

## Deployment Execution Log

Populated during Stage 12.

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | | |
| Merge PR | | | |
| Tag release | | | |
| Skill deployment | | | |
| Manifest execution | | | |
| State anchor update | | | |
| Post-execution verification | | | |

## Change Description

Authored by the last Stage 6 Engineering spoke at pull-request completion, per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol. It is distinct from the user-facing release note, which is written at Stage 13 Close.

### Outcome

The three registered in-repo git-ignored homes (`/local-state/`, `/analysis/` and `/roadmaps/`) are now guarded against a commit. `/local-state/` ships with its tracked README; a commit guard refuses any path under a home other than its README, a forced add included, at pre-commit and over every commit a push would publish; and a new required CI job, the In-repo home content gate, keeps home content off `main`. The repository tree walkers that read a home now read the git index or root below the repository root, and a regression test fails when one reads a home. Leak-risk files get one permission policy — 0600 on each file and 0700 on each folder, the pre-update container copies included — set at install and at every full update, and reported by the install validator's new check A11.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #8022 | `/local-state/` ships with its README; `core/hooks/git-pre-commit-homes.sh` refuses home content at commit and at push, and the In-repo home content gate refuses it on every pull request | DONE — AC-1 reads red until the sibling release's ignore pair reaches this branch, and AC-5 is the operator's Stage-12 registration |
| #8023 | The verifier's glob resolver, the import tracer, the context-budget agents scan and the durability copy no longer read a home; `core/deploy/tests/test_tree_walk_skips_homes.sh` fails when a walker it runs does | DONE |
| #8024 | `core/deploy/lib-leak-risk-modes.sh` sets every Leak-risk register row's files to 0600 and folders to 0700 at install and full update; validate-install A11 fails any group or other permission bit | DONE |

### Key decisions

Rendered in § Operator Decisions — rendered and recorded in § Deviation Log.

- **D-GuardScope (A):** the guard covers every registered in-repo home, each README excepted, from one static list the tree-walk test also reads.
- **D-RequiredCheck (B):** the job's header declares `required`; the operator registers the context at Stage 12 once it is green on the head, then merges.
- **D-Bypass (C):** the commit-time check runs even under `CLAUDE_HOOK_BYPASS`, and the push-time check honours it. The decision record is ADR-242, status `Proposed`.
- **D-CIArm (A + squash-merge):** the CI job reads the merge tree, and its refusal prescribes removing the file and squash-merging.
- **D-8023-WalkerSet (A):** all four home-reaching walkers change, and both tracers resolve an omitted root from their own checkout before the working directory.
- **D-ScanExec (B):** the S-15 script is run as `bash <path>`, so it is 0600 like every other leak-risk file.
- **D-FolderLimb (A) and D-S40Scope (A):** the folder limb reaches the S-40 copies, which are created at the policy and repaired; the governed leak-risk home is the installer milestone's.
- **CD-2 and CD-3:** the second PII scan list gets register row S-48; the validator fails a group or other bit, and the setter stays exact.

### Reversibility

**MODERATE — HIGH confidence.** De-register the In-repo home content gate's required context first, then revert the release merge with a mainline revert; the leak-risk modes this release set stay at the more protective setting, and a claimed version tag is retained.

### Downstream impact

- **Stage 12:** the operator registers `In-repo home content gate` as a required context. Each open pull request whose latest run lacks the job then needs a fresh push or a merge from `main`.
- **Existing installs:** one full `./update.sh` after the merge tightens the leak-risk files (§ Operational Deployment Manifest row 1). Until it runs, validate-install A11 FAILs, and in its default `all` mode Mode B is skipped.
- **Merge order:** ship-gated on `worktree-sessions-reach-in-repo-homes`, which ships the `/local-state/` ignore pair. Same-cell edits to the placement standard reconcile at the Stage-9 merge from `main`.
- **Carried forward:** the installer milestone inherits the leak-risk home at the policy, the S-40 and S-41 homes and S-40 retention (NR-1, NR-3, NR-5). The one-resolver release inherits the library's six repoint targets (NR-6).
- **Held for the Stage-9 filing step:** the stray-copy backstop's exact-name matching, the script-execution guard's misfire on `find -path` operands, and its interpreter-subprocess coverage gap.

### Cross-references

- Release plan: this file, top section.
- Milestone: `in-repo-home-is-guarded`.
- User-facing release notes: written at Stage 13 Close under `release/releases/notes/`, per `release/references/standards/release-notes-standard.md`.
