# Release Plan: dependabot-prs-merge-without-bypass — the depersonalization gate gives a Dependabot run a measured verdict

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — a new decision record plus a behavior change in a required CI gate. The concrete number binds only at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-10-16 (Friday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing — Stage 6 Engineering complete: Commit 0 (plan + decision record), the library and fixture suite (RED), Gate 1 (GREEN), and the documentation and label surfaces. Owed before Stage 9: the Phase A6.5 adversarial review and the Collective Review of the Stage-5 design |
| **Branch** | release/dependabot-prs-merge-without-bypass |
| **PR** | opened in **draft** immediately after the Stage-6 commits; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | dependabot-prs-merge-without-bypass |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-10-16, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every row of the matrix targets an internal `pmo-platform` artifact. Security dominates (a C6 personal-data CI gate and the secrets-handling policy), with software (a shell library and its fixture suite) and governance (a rules paragraph, a label pack row) secondary.

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Labels |
|---|-------|-------|----------|----------|--------|
| 1 | #8092 | Dependabot security PRs cannot merge without an admin bypass | P2 | bug | bug, cluster: security, status: approved, project:platform-quality |

**Scope narrowing (triage, operator-approved 2026-10-16):** defects 2 (the depersonalization gate fails every run Dependabot starts) and 3 (the `dependabot` label does not exist), plus the `SECURITY.md` reconciliation. Defect 1, the required close-out smoke context that never reports on a path-filtered pull request, is owned by #6179 in the `ci-wiring-and-required-checks` release (draft PR #8305). Acceptance criteria 1 and 2 belong to that defect.

### Dependency Graph

Per ADR-1 — Kahn's BFS topological sort, priority-desc → issue-asc tie-breaker.

#### Topologically Sorted Sequence

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #8092 | P2 | bundled | (none — root) | — |

#### Artifact Relationship Graph

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #8092 | GENERATES | core/ADRs/ADR-217-depersonalization-gate-scans-bot-runs.md | #8092 → file | File Change Matrix (Create) |
| #8092 | GENERATES | release/releases/plans/dependabot-prs-merge-without-bypass_RELEASE_PLAN.md | #8092 → file | File Change Matrix (Create) |

No issue→issue edges: a single-issue bundle.

### File Change Matrix

| File Path | Issues | Change Type | Risk |
|-----------|--------|------------|------|
| release/releases/plans/dependabot-prs-merge-without-bypass_RELEASE_PLAN.md | #8092 | Create | Low |
| core/ADRs/ADR-217-depersonalization-gate-scans-bot-runs.md | #8092 | Create | Low |
| release/tools/lib/deciders-carveout.sh | #8092 | Modify | Medium |
| release/tools/tests/test_deciders_carveout.sh | #8092 | Modify | Low |
| .github/workflows/repo-integrity.yml | #8092 | Modify | High |
| core/rules/git-workflow.md | #8092 | Modify | Low |
| core/standards/secrets-handling-policy.md | #8092 | Modify | Low |
| SECURITY.md | #8092 | Modify | Low |
| core/packs/_common/pack.toml | #8092 | Modify | Low |

Machine-readable form — one path per line, `<path>  <verb>`, fence-delimited for deterministic extraction:

```
# ── #8092 — the depersonalization gate gives a Dependabot run a measured verdict; the dependabot label ──
release/releases/plans/dependabot-prs-merge-without-bypass_RELEASE_PLAN.md          add
core/ADRs/ADR-217-depersonalization-gate-scans-bot-runs.md                          add
release/tools/lib/deciders-carveout.sh                                              edit
release/tools/tests/test_deciders_carveout.sh                                       edit
.github/workflows/repo-integrity.yml                                                edit
core/rules/git-workflow.md                                                          edit
core/standards/secrets-handling-policy.md                                           edit
SECURITY.md                                                                         edit
core/packs/_common/pack.toml                                                        edit
```

`.github/workflows/repo-integrity.yml` is High because Gate 1 is a branch-protection required check: a defect there either blocks every pull request or passes one unscanned. Only the Gate 1 job is edited.

### File Contention Map

| File | Issues | Intent Mix | Severity | Recommendation |
|---|---|---|---|---|
| No file contention detected | — | — | NONE | single-issue bundle |

**Parse-quality:** 1 issue parsed cleanly · 0 deferred · 0 parse-failed.

**Cross-PR (outside this bundle), recorded for Stage 12:** #8305 edits `.github/workflows/repo-integrity.yml` (a header block and a new trailing job) and `core/rules/git-workflow.md` (one line in § Repository-Integrity Gates). Neither hunk overlaps Gate 1 or the CI-configuration paragraph this release rewrites. Weak contention: whichever lands second rebases.

### Cross-Milestone Dependency Validation

N/A — enumerated over native `blocked-by` / `blocking` edges and the body's Dependencies field; #8092 has neither, so no edge exists to check.

### Bundle Refresh State

N/A — enumerated over triggers T1–T4; the milestone was created on 2026-10-16 with its one issue, and no refresh check has run since.

### Exclusions

- Defect 1 of #8092 (acceptance criteria 1 and 2): owned by #6179 / `ci-wiring-and-required-checks`, per the ownership note recorded on #8092 on 2026-10-08.
- The `deploy.sh --check` detector for the two-store coupling (design D-5): an optional follow-up, not in scope.
- The ORPHAN live labels `dependencies` and `javascript`: label-parity hygiene owned by the parity gate's owner, not this release.

## Implementation Sequence

### Issue #8092: Dependabot security PRs cannot merge without an admin bypass

**Change Specification** (Solutioning-level; the Stage-5 design on #8092 is the authority, its "Output for Stage 6" table the file spec):

- **Commit 0:** this plan and the decision record `{{ADR:depersonalization-gate-scans-bot-runs}}` (D-1 option B, D-2 (b), D-3).
- **`release/tools/lib/deciders-carveout.sh`:** add `identity_preflight <is_canonical> <identity>` (prints `OK` or `FAIL`) and `resolve_operator_literals <is_canonical> <fork_opted_out> <owner> <identity>` (prints one literal per line, owner first). Explicit parameters, no caller globals. Widen the header to "shared decisions for the depersonalization gate"; rewrite the empty-not-carved rationale (now empty only on an opted-out fork).
- **`release/tools/tests/test_deciders_carveout.sh`:** fixture arms (a)–(f) per the design, the two new functions added to the definition guard, and the header's agreement-scope note rewritten (both gates now resolve the handle from the repository owner).
- **`.github/workflows/repo-integrity.yml`, Gate 1 only:** bind `REPO_OWNER` from `github.repository_owner` through `env:`; step 0 calls `identity_preflight`, same message, same position before the scope filter; step 2 resolves literals through `resolve_operator_literals` and sets the handle literal to the owner on every run that resolves literals; the actor exemption is deleted and the bot flag survives only for a summary notice; an empty literal set on canonical is `::error` + `exit 1`, a fork is unchanged.
- **`core/rules/git-workflow.md`:** the § Repository-Integrity Gates "CI configuration (one-time)" paragraph only. A mirror pair: `./deploy.sh --deploy` after merge; Check 9 confirms the mirror.
- **`core/standards/secrets-handling-policy.md`:** §2 one mapping-rule note (Actions store canonical, Dependabot store mirror); §5 the C6 row gains the two-store update procedure for `OPERATOR_IDENTITY` and `COLLABORATOR_NAMES`.
- **`SECURITY.md`:** § Automated Security PRs — the three required checks a Dependabot PR can fail, each with its remedy; "no secrets" corrected to "only Dependabot secrets"; the labeling statements kept true.
- **`core/packs/_common/pack.toml`:** one Provenance `[[labels]]` row for `dependabot`.

- **Acceptance criteria:** the six on #8092; in scope here are AC-3 through AC-6.
- **Estimated complexity:** Medium.
- **Dependencies:** None.

### Agent-Editability Read

**Derivation** — controls read at commit `20197085`:
- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh` — every `case` block whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: 2 block(s) observed. Arms:
  - `"${PRIMARY_ROOT}/CLAUDE.md"` · `"${PRIMARY_ROOT}/projects/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/.claude/settings.json"` · `"${PRIMARY_ROOT}/.claude/hooks/"*` · `"${PRIMARY_ROOT}/.claude/rules/"*`
  - `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`
- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|------|----------------|----------|--------------|-----------|-----------|----------------|
| #8092 | release/releases/plans/dependabot-prs-merge-without-bypass_RELEASE_PLAN.md | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | core/ADRs/ADR-217-depersonalization-gate-scans-bot-runs.md | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | release/tools/lib/deciders-carveout.sh | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | release/tools/tests/test_deciders_carveout.sh | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | .github/workflows/repo-integrity.yml | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | core/rules/git-workflow.md | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | core/standards/secrets-handling-policy.md | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | SECURITY.md | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8092 | core/packs/_common/pack.toml | no | no | unconstrained | unconstrained | ordinary Engineering spoke |

`core/rules/git-workflow.md` is the repository source; its deployed mirror under `.claude/rules/` is written by `./deploy.sh --deploy` at Stage 12, not by this branch. The two out-of-tree steps (the Dependabot-store secret and the label create) are operator-executed after merge.

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| 1 | The Dependabot-store secret is set before this change merges: the configuration check passes, the old exemption empties the literal set, and every Dependabot run passes unscanned | Med | High | The secret step is handed to the operator only after merge; the rollback order deletes it before any revert | Operator |
| 2 | A Gate 1 regression blocks every pull request or passes one unscanned | Low | High | Fixture arm (e) asserts the new resolution is byte-identical to the old one for a human run; this PR's own gate run observes it live before merge | Engineering |
| 3 | Value drift between the two secret stores (one store updated, the other not) is silent on bot runs | Low | Med | §5 two-store update procedure; detector deferred as an optional follow-up (design D-5) | Operator |
| 4 | #8305 lands first and its edits to the same two files conflict on rebase | Low | Low | Hunks are disjoint; rebase on whichever lands second | Engineering |
| 5 | The ADR number is claimed on the mainline first | Med | Low | Cited by slug token; `renumber-adr.py` moves the record at merge | Engineering |

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential |
| **Commit strategy** | Grouped commits: Commit 0 (plan + ADR), then library + suite, then Gate 1, then documentation + label |
| **Review approach** | Single PR for entire release |
| **Deployment mechanism** | Git merge + `./deploy.sh --deploy` (rules mirror) + two operator out-of-tree steps |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A); no stacked bases planned |

**Sub-task container:** PR-body checklist. Deviation, stated: the A2 threshold predicate counts eight file-level units, above the ≤5 checklist bound, so the default is GitHub sub-issues. The checklist is used because the release is one issue with one design, executed by one session on one branch; per-unit sub-issues would add persistent tracker records with no independent closure state. The special rows (sync, plan update, verification) are kept.

## Verification Plan

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #8092 | AC-1 | [DEFERRED — defect 1, owned by #6179 in the ci-wiring-and-required-checks release] | Verified by that release |
| #8092 | AC-2 | [DEFERRED — defect 1, owned by #6179 in the ci-wiring-and-required-checks release] | Verified by that release |
| #8092 | AC-3 | Run `bash release/tools/tests/test_deciders_carveout.sh` and read fixture arm (a): a bot's run on canonical with identity set resolves the owner plus the identity lines. Post-merge, after the operator's secret step: read the `Depersonalization gate` on the bot's own commit of the next Dependabot PR | Suite exits 0 with arm (a) PASS; post-merge, the gate reports success on the bot commit with a scan, not a skip |
| #8092 | AC-4 | Run `bash release/tools/tests/test_deciders_carveout.sh` and read fixture arms (b) and (c): identity unset on canonical returns `FAIL` for a human run and for a bot's run | Both arms PASS · control: arm (d), a fork opted out with identity unset, returns `OK` |
| #8092 | AC-5 | `grep -c 'name = "dependabot"' core/packs/_common/pack.toml` ≥ 1. Post-merge, after the operator runs the `--emit-fix` label create: read the labels and comments on the next Dependabot PR | 1; post-merge, the PR carries `dependabot` and `cluster: security` with no "labels could not be found" comment |
| #8092 | AC-6 | `grep -c 'only Dependabot secrets' SECURITY.md` ≥ 1 | 1, and § Automated Security PRs carries the three-row table naming the freshness gate, the depersonalization gate and the close-out smoke check, each with its remedy |

**AC baseline** — per-issue criterion counts as read at plan time.

`ac_baseline: { #8092: 6, read_at: 20197085 }`

### Release-Level Verification

Per verification-checklist.md:
- [ ] File Integrity — the nine files in the File Change Matrix and no others (`git diff --name-only origin/main...HEAD`)
- [ ] Content Correctness — `bash release/tools/tests/test_deciders_carveout.sh` exits 0, with the baseline 33 assertions still passing plus the new arms
- [ ] Cross-Reference Validity — the bot-exemption restatement sweep from the design (`git grep -nE "bot-authored|bot push|bot-triggered|bot actor|bot-skip|BOT-SKIP|operator-self (matching|dimension) is skipped|authored by a bot"` over `core/ release/references/ release/governance/ release/tools/ SECURITY.md .github/`, excluding `release/releases/`) reads pre 7 lines / post 0
- [ ] Skill Invocation — N/A — enumerated over the File Change Matrix; no SKILL.md or skill `references/` file is touched
- [ ] Output Contract Compliance — the PR's own `Depersonalization gate` run is green (fixture arm (e) observed live: actor = owner, identity set, C6 files changed)

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #8092 | `gh secret delete OPERATOR_IDENTITY --app dependabot` **first**, then `git revert` the merge | Low — the order is the whole procedure: reverting first restores the exemption beside a present mirror, a silent pass on every Dependabot run |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | A documentation surface is wrong | Revert the documentation commit only; the gate change stands |
| **Full Restore** | Gate 1 misbehaves on main | Delete the Dependabot-store mirror, then revert the merge commit per rollback-protocol.md |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per rollback-protocol.md |

The `dependabot` label is kept on rollback: harmless once declared. If it is dropped instead, withdraw the pack row in the same change.

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | core/rules/git-workflow.md | `<deploy-root>/.claude/rules/git-workflow.md` | `./deploy.sh --deploy` (rules mirror) | `./deploy.sh --check` Check 9 reports the mirror in sync |
| 2 | `OPERATOR_IDENTITY` (Actions store, canonical) | Dependabot secret store | Operator, after merge only: `gh secret set OPERATOR_IDENTITY --app dependabot` | `gh secret list --app dependabot` lists it; the next Dependabot PR's gate passes on the bot commit |
| 3 | core/packs/_common/pack.toml `dependabot` row | Repository label | Operator: `python3 core/deploy/tools/check-label-parity.py --emit-fix`, then its `gh label create` block | `check-label-parity.py` no longer reports `dependabot` MISSING |

### Schema Migrations (if applicable)

N/A — enumerated over the pack-manifest schema, the label grammar and the workflow inputs; the pack row is additive inside an existing group, and no schema or grammar changes.

## Deviation Log

| # | Deviation | Source | Disposition |
|---|---|---|---|
| **DEV-1** | A third library function, `literal_set_verdict <is_canonical> <pattern-file>`, decides the empty-literal-set branch. The design named two functions and left D-3 inline in the workflow. Lifting it lets fixture arm (f) grade the D-3 failure as effect rather than as workflow text, which is D-4's own reason for extending the library | Stage 6, Tier 1 | **APPLIED** |
| **DEV-2** | Gate 1 asserts, right after sourcing the library, that every decision it calls is defined, and fails closed otherwise. Each decision is read through `$(...)`, so a missing function would read as an empty verdict and fall through to a pass. The `literal_set_verdict` case also fails on an unrecognised token | Stage 6, Tier 1 | **APPLIED** |
| **DEV-3** | The `dependabot` label description is 98 characters, not the design's longer text, because GitHub caps a label description at 100 and the parity gate compares descriptions exactly; the `.github/dependabot.yml` pointer lives in `applied_at` | Stage 6, Tier 1 | **APPLIED** |
| **DEV-4** | Sub-task container: PR-body checklist rather than sub-issues (see § Delivery Strategy) | Stage 6, Tier 1 | **APPLIED** |
| **DEV-5** | The bundle, the milestone and Stage 4 were authored directly, not through the Stage-3 and Stage-4 skills; Mode R readiness and the Parallelization Map were not run. The Phase A6.5 adversarial review and the Collective Review of the Stage-5 design remain owed before Stage 9 | Operator's single-issue-milestone choice, 2026-10-16 | **RECORDED** — owed |

## Verification Evidence

(Populated after Stage 12 execution — see verification-checklist.md for format)

**Stage 6 self-verification (pre-merge):**
- Fixture suite: RED 50/56 at the library commit against the previous Gate 1 (the five call-shape bindings and the actor negative arm), GREEN 56/56 with the Gate 1 change; the pre-change baseline was 33/33. The new regexes were cross-checked under BSD grep: each binding matches the branch once and `origin/main` zero times; the actor negative arm reads branch 0, `origin/main` 2, fixture 2.
- Local replay of Gate 1's run block (bash 3.2, with only the `mapfile` line shimmed): a bot's run with the identity set now BLOCKS an added handle and an added email, and passes clean content with a scan; a missing mirror and a missing human secret both fail loud; an opted-out fork passes empty; a library missing a function fails closed. The same replay of `origin/main`'s block passes the bot's handle and email additions, which is the silent pass the decision record names.
- Bot-exemption restatement sweep: pre 7 / post 0 over the design's population.
- `verify-release-plan.sh`: 7 PASS / 0 FAIL / 0 ERROR (AC-1 and AC-2 declared deferred; AC-3 and AC-4 UNRUNNABLE here, graded by the suite in CI).
- `deploy.sh --check-required-subset`: all 4 load-bearing checks pass. `check-adr-numbers.py`: PASS. ADR durability lint on the new record with `--diff-base origin/main`: 0 findings. actionlint: the same 7 info-level findings as `origin/main`, none new. `check-label-parity.py`: `dependabot` MISSING (created by the operator after merge); the `dependencies` and `javascript` ORPHANs unchanged.

## Deployment Execution Log

(Populated during Stage 12 — see execution-checklist.md)

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

### Outcome

A Dependabot pull request now gets a real `Depersonalization gate` verdict on the bot's own run, with no maintainer push. The gate scans every run on the same literals, whoever started it: the handle comes from the repository owner, and the name and email from `OPERATOR_IDENTITY`, which the operator mirrors into the Dependabot secret store after merge. The silent pass behind the old red, where a bot's run scanned nothing, is gone: an empty literal set on canonical now fails.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #8092 | Defects 2 and 3 plus the `SECURITY.md` reconciliation; defect 1 (AC-1, AC-2) stays with the required-checks release | PARTIAL — in-scope work DONE; AC-3 and AC-5 are confirmed live on the first Dependabot PR after the operator's two post-merge steps |

### Key decisions (when applicable; omit this sub-section when no D-decisions were rendered)

- **D-1:** option B, mirror the secret and delete the actor exemption (operator, 2026-10-16). The only option that gives a bot's run the human verdict and keeps a fail-loud arm on bot runs.
- **D-2:** handle from the repository owner on every run, the resolution the ADR durability gate already uses.
- **D-3:** an empty literal set on canonical fails; a fork keeps notice + pass.
- **D-6:** create `dependabot` as a Provenance row (operator, 2026-10-16).

### Reversibility

**CHEAP — HIGH confidence.** Delete the Dependabot-store mirror first (`gh secret delete OPERATOR_IDENTITY --app dependabot`), then `git revert` the merge; the reverse order restores the exemption beside a present mirror, a silent pass on every Dependabot run. The live label is MODERATE once it has carriers.

### Downstream impact

- After merge, two operator steps, in this order and never before merge: `gh secret set OPERATOR_IDENTITY --app dependabot`, then the `gh label create` that `python3 core/deploy/tools/check-label-parity.py --emit-fix` renders. Then `./deploy.sh --deploy` refreshes the rules mirror.
- The `Close-out automation smoke (macOS)` row in `SECURITY.md` is rewritten by whichever of this release and the required-checks release lands second.
- Optional follow-up: a `deploy.sh --check` detector comparing the two secret stores (design D-5).

### Cross-references

- Release plan: this file, top section
- Milestone: dependabot-prs-merge-without-bypass
- Decision record: `{{ADR:depersonalization-gate-scans-bot-runs}}`
