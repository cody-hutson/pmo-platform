# Release Execution Checklist

## Purpose

This checklist governs the execution sequence for PMO platform releases. The release-executor skill (Mode A) follows this checklist step-by-step during Stage 12 (Execute). Every step has a verification criterion that must be satisfied before proceeding.

## Pre-Execution Checklist

All items must be verified PASS before execution begins. Any FAIL blocks execution.

| # | Check | Verification Method | PASS Criterion | FAIL Action |
|---|-------|-------------------|---------------|-------------|
| 1 | **PR approved** | `gh pr view [PR#] --json reviewDecision` | At least 1 approval; no changes-requested | Return to Stage 9 (Plan Review) |
| 2 | **PR metadata complete** | `gh pr view [PR#] --json milestone,labels,assignees,projectItems` | Milestone set, labels present, assignee set, project linked | Return to Stage 6 (Engineering) to add metadata |
| 3 | **No merge conflicts** | `gh pr view [PR#] --json mergeable` | mergeable = MERGEABLE | Resolve conflicts on release branch; re-request review |
| 4 | **CI checks passing** | `gh pr checks [PR#]` | All required checks pass | Fix failing checks; do not merge |
| 5 | **Release plan reviewed** | Release plan file exists at `release/releases/plans/vX.Y_RELEASE_PLAN.md` | Plan exists and has "Status: Approved" | Return to Stage 9 |
| 6 | **Rollback plan documented** | Rollback section in release plan | Rollback strategy specified per issue and whole-release | Document rollback before proceeding |
| 7 | **Deployment targets identified** | Operational Deployment Manifest in release plan | All Layer 2 targets listed with mechanism | Add manifest before proceeding |
| 8 | **Communication plan** | Stage 12 communication requirements reviewed | Stakeholders notified of deployment window (if applicable) | Draft and send notification |

## Tiered Quality-Gate Ladder

After the 8 Pre-Execution checks above pass, run the **three-tier quality-gate ladder**
defined canonically in the `## Quality-Gate Ladder` section in `SKILL.md` **before Step 1
(Merge PR to Main)**. The ladder fires **in order and short-circuits** — the first
failure HALTs the run, so a Tier-1 failure prevents Tier 2 and Tier 3 from executing and
**no merge happens**. This is the live (git-native) entry point; Mode A Step 5 is the
Cowork-lineage entry point — both consume the same SKILL.md ladder definition.

**Scope:** the release's changed files — `git diff --name-only main...<release-branch>`.
Compute the changed-file set once and pass it to both T1 and T2.

| Tier | Run | PASS | FAIL (halts; no merge) |
|---|---|---|---|
| **T1 — Schema validation** (hard fail) | `python3 core/deploy/tools/lint_release_corpus.py --check schema` (+ assert the frontmatter field set `name`/`description`/`version`/`license` on each changed `SKILL.md`) | exit 0 | non-zero exit, OR any changed skill missing a required frontmatter field → emit T1 finding, HALT |
| **T2 — Cross-reference integrity** (hard fail) | `python3 core/deploy/tools/check-doc-links.py --target-paths '<changed-files>' --require-targets` (broken-refs mode) | exit 0 | **exit 1** (broken cross-ref/anchor/deleted-target) OR **exit 3** (target surface unverifiable — `--require-targets` forces zero-yield to fail, never a false clean) → emit T2 finding, HALT |
| **T3 — Stakeholder approval** (human gate) | `AskUserQuestion` GO/NO-GO presenting the T1+T2 PASS evidence + the release diff | operator GO | operator NO-GO / Cancel → HALT (no merge). The agent **cannot** self-satisfy this gate. |

On any FAIL, emit the 5-field finding record from `SKILL.md` § Quality-Gate Ladder
(`what failed` / `where` / `evidence` / `what to fix` / `short-circuit`) naming which
tier failed and which downstream tiers were skipped; do not proceed to Step 1.

**Progressive-rollout dispatch (per-gate `rollout-cycle`).** Each gate Tier carries a
`rollout-cycle` (the column on the ladder table in `SKILL.md` § Quality-Gate Ladder;
default `enforce`). Before treating a Tier's would-fail as a hard FAIL, read its
`rollout-cycle` and dispatch per `references/progressive-rollout.md`:

| `rollout-cycle` | On a Tier would-fail | Short-circuits the ladder? |
|---|---|---|
| `enforce` | emit the 5-field finding, **HALT, no merge** | **Yes** — downstream Tiers do NOT run |
| `warn` | append a hit to `core/hooks/<tier-id>-rollout-log.jsonl` AND surface an operator-facing ⚠ notice | **No** — the ladder continues to the next Tier |
| `shadow` | append a hit to `core/hooks/<tier-id>-rollout-log.jsonl`, silently | **No** — the ladder continues to the next Tier |

So the "fires in order and short-circuits on first failure" rule above is scoped to
`enforce` gates: a `shadow` or `warn` gate observes (and, for `warn`, notices) and the
ladder proceeds; only an `enforce` gate halts the run and skips the remaining Tiers.
Default to `enforce` on an absent or unparseable `rollout-cycle` — an unmarked gate keeps
its blocking teeth (fail-safe). A `shadow`/`warn` Tier that would-fail does NOT flip the
Pre-Execution table's "Any FAIL blocks execution" gate; only an `enforce` Tier does.

> **Pre-apply vs. at-deploy.** These gates run **pre-apply** (before merge). `deploy.sh
> --check` runs the same instruments (`lint_release_corpus.py`, `check-doc-links.py`)
> **at deploy time** — the ladder is *earlier* in the pipeline, not duplicative by
> accident.

## Execution Steps

### Step 1: Merge PR to Main

```bash
# Verify clean state
git checkout main && git pull origin main

# Merge PR (squash or merge per release plan)
gh pr merge [PR#] --merge --delete-branch

# Verify merge
git pull origin main
git log --oneline -5  # Confirm merge commit present
```

**Verification:** Merge commit visible in `git log`. PR status = "Merged" in GitHub.

### Step 2: Tag Release

```bash
# Create signed-annotated version tag (repo enforces tag.gpgsign=true; never bypass signing per core/rules/git-workflow.md)
git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<n>" vX.Y "$MERGE_SHA"

# Push tag to remote
git push origin vX.Y
```

**Verification:** Tag visible on GitHub. `git tag --list 'vX.Y'` returns the tag. `git cat-file -t refs/tags/vX.Y` returns `tag` (not `commit`) — confirms annotated form.

### Step 3: Deploy Changed Skills (if applicable)

For each skill changed in the release (identified via `git diff main~1 main -- release/skills/`):

```bash
# Deploy via S-2 direct copy
cp release/skills/[skill-name]/SKILL.md \
   "[COWORK_INSTALL_PATH_BASE]/local-agent-mode-sessions/skills-plugin/[SESSION_UUID]/[SESSION_UUID]/skills/[skill-name]/SKILL.md"
```

**Verification per skill:**
- File exists at installed path
- `diff` between repo source and installed copy shows no differences
- Skill invocable in Cowork (manual verification by user)

### Step 4: Execute Operational Deployment Manifest

For each item in the Operational Deployment Manifest (Layer 2 file propagation, schema migrations, content syncs):

| Mechanism | Execution | Verification |
|-----------|-----------|-------------|
| **File propagation (copy)** | `cp [source] [target]` | `diff [source] [target]` shows no differences |
| **Schema migration** | Execute migration per manifest instructions | Content assertion: expected structure/content present |
| **Content sync** | Copy or merge content per manifest instructions | Diff-based: target matches expected state |

**Verification:** Each manifest entry marked PASS or FAIL with timestamp.

### Step 5: Update State Anchors

Update GitHub Projects fields for all release issues:

```bash
# For each issue in the release
gh project item-edit --project-id [PROJECT_ID] --id [ITEM_ID] \
   --field-id [STATUS_FIELD] --single-select-option-id [DONE_OPTION]
gh project item-edit --project-id [PROJECT_ID] --id [ITEM_ID] \
   --field-id [STAGE_FIELD] --single-select-option-id [EXECUTE_OPTION]
```

**Verification:** `gh project item-list` confirms all release issues show Status=Done, Stage=12-Execute.

## Post-Execution Verification

| # | Check | Verification Method | PASS Criterion |
|---|-------|-------------------|---------------|
| 1 | **Main branch clean** | `git status` on main | Clean working tree; no uncommitted changes |
| 2 | **Tag exists on remote** | `gh release view vX.Y` or `git ls-remote --tags origin vX.Y` | Tag present |
| 3 | **Skills deployed** (if applicable) | `diff` repo vs. installed for each changed skill | No differences |
| 4 | **Manifest items verified** | Each manifest entry checked | All PASS |
| 5 | **State anchors updated** | GitHub Projects fields verified | All issues at correct status/stage |
| 6 | **No regression** | Spot-check: invoke 1-2 changed skills in Cowork | Expected behavior observed |

## Deployment Strategy Selection (PMO Platform)

The PMO platform uses a constrained set of deployment strategies:

| Component | Strategy | Rationale |
|-----------|----------|-----------|
| **Git-tracked files** (Layer 1) | Git merge to main | Standard; git history provides rollback |
| **Skill files** (Layer 1 → Layer 2 copy) | S-2 direct copy | Established mechanism; simplest automated approach |
| **GitHub configuration** (Projects, labels, milestones) | GitHub API calls | No rollback mechanism; verify before executing |
| **Layer 2 operational files** | Direct copy per manifest | Verify via diff |

## Failure and Rollback

If any post-execution verification fails:

1. **Assess severity:** Is the failure isolated (one skill, one manifest item) or systemic (merge broke main)?
2. **Isolated failure:** Fix forward — correct the specific file/skill and re-verify
3. **Systemic failure:** Rollback via `git revert [merge-commit]` — see rollback-protocol.md
4. **Document:** Log failure in release plan's Verification Evidence section with root cause
