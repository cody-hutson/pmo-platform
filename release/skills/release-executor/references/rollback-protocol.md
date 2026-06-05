# Rollback Protocol

## Purpose

This document defines the rollback strategies, decision model, execution procedures, and communication requirements for PMO platform releases. Rollback plan existence is a non-negotiable gate — every release must have a documented rollback strategy before execution begins.

## Five Rollback Strategies

| # | Strategy | Mechanism | Speed | When to Use | Data Impact |
|---|----------|----------|-------|-------------|-------------|
| 1 | **Feature Flag Toggle** | Disable feature via configuration toggle | Milliseconds | Feature flags were used in deployment; feature is independently toggleable | None — code remains deployed but inactive |
| 2 | **Blue-Green Switch** | Route traffic to previous environment | Seconds | Blue-green deployment architecture exists; previous environment is intact | None — previous environment state preserved |
| 3 | **Partial Revert** | `git revert` of specific commits | Minutes | Only specific files/changes need reverting; other release changes are valid | May need targeted Layer 2 file restoration |
| 4 | **Full Restore** | `git revert` of merge commit (entire release) | Minutes-hours | Multiple entangled changes all need reverting; cannot isolate the problem | Requires full Layer 2 file rollback per manifest |
| 5 | **Forward Fix** | Deploy a targeted fix on main without reverting | Variable | Rollback is riskier than fixing forward; problem is small and well-understood | Fix addresses the specific issue only |

## PMO Platform Rollback Profile

The PMO platform is git-native. This constrains the rollback strategy set:

| Component | Available Strategies | Primary Strategy | Rationale |
|-----------|---------------------|-----------------|-----------|
| **Git-tracked files (Layer 1)** | Partial Revert, Full Restore, Forward Fix | Partial Revert | Git revert of specific commits is targeted and auditable |
| **Skill files (Layer 1 → Layer 2)** | Re-copy from prior version, Forward Fix | Re-copy from git history | `git show vX.(Y-1):release/skills/[name]/SKILL.md > [installed-path]` |
| **GitHub configuration** (labels, milestones, project fields) | Manual restoration, Forward Fix | Forward Fix | No automated rollback for GitHub API changes; fix forward is safer |
| **Layer 2 operational files** | Re-copy from backup/prior version, Forward Fix | Forward Fix | Layer 2 files are operational; forward fix preferred over state restoration |

**Strategies NOT available for PMO platform:**
- Feature Flag Toggle — platform does not use feature flags (governance files are not feature-flagged)
- Blue-Green Switch — no dual-environment architecture

## Rollback Decision Model

When a post-deployment issue is detected, use this decision tree:

```
Issue Detected
  │
  ├─ Is production (main branch) broken? ────── YES ──→ How many files affected?
  │                                                         │
  │                                                         ├─ 1-3 files ──→ PARTIAL REVERT
  │                                                         │
  │                                                         └─ 4+ files or entangled changes ──→ FULL RESTORE
  │
  └─ Is production functional but incorrect? ── YES ──→ Is the fix well-understood?
                                                           │
                                                           ├─ YES, small fix ──→ FORWARD FIX
                                                           │
                                                           └─ NO, root cause unclear ──→ PARTIAL REVERT
                                                               (revert while investigating)
```

**Severity × Blast Radius Decision Matrix:**

| | Blast Radius: Low (1-2 files) | Blast Radius: Medium (3-5 files) | Blast Radius: High (6+ files) |
|---|---|---|---|
| **Severity: Critical** (main broken) | Partial Revert | Partial Revert | Full Restore |
| **Severity: High** (functionality incorrect) | Forward Fix | Partial Revert | Full Restore |
| **Severity: Medium** (cosmetic/minor) | Forward Fix | Forward Fix | Forward Fix |
| **Severity: Low** (improvement opportunity) | Log for next release | Log for next release | Log for next release |

## Execution Procedures

### Partial Revert

```bash
# 1. Identify the commit(s) to revert
git log --oneline main

# 2. Revert specific commit(s)
git revert [commit-hash] --no-edit

# 3. Push revert to main
git push origin main

# 4. Re-deploy affected skills (if any)
cp release/skills/[name]/SKILL.md "[INSTALLED_PATH]/[name]/SKILL.md"

# 5. Verify revert
git diff HEAD~2..HEAD  # Confirm revert changes are correct
```

### Full Restore (Revert Merge Commit)

```bash
# 1. Identify the merge commit
git log --oneline --merges main

# 2. Revert the merge commit (specify parent)
git revert -m 1 [merge-commit-hash] --no-edit

# 3. Push revert to main
git push origin main

# 4. Re-deploy ALL skills changed in the release
# (use original release plan's file change matrix)

# 5. Rollback Layer 2 files per manifest
# For each manifest entry, restore from prior version

# 6. Verify full restore
git diff vX.(Y-1)..HEAD  # Should show only the revert commit
```

### Forward Fix

```bash
# 1. Create fix branch
git checkout -b fix/vX.Y-[description] main

# 2. Apply targeted fix
# (edit specific files)

# 3. Commit and push
git add [specific-files]
git commit -m "fix: [description] (#issue-number)"
git push -u origin fix/vX.Y-[description]

# 4. Create PR with expedited review
gh pr create --title "fix: [description]" \
  --body "Fixes issue discovered in vX.Y deployment. ..." \
  --milestone "vX.Y" --label "fix,urgent"

# 5. Merge after review (expedited)
# 6. Deploy fix per standard execution checklist
```

## Post-Rollback Verification

After any rollback, verify:

| # | Check | Method | PASS Criterion |
|---|-------|--------|---------------|
| 1 | Main branch state correct | `git log --oneline -5` | Revert commit visible; HEAD at expected state |
| 2 | Skill files restored | `diff` repo vs. installed for reverted skills | No differences from expected state |
| 3 | Layer 2 files restored (if applicable) | `diff` or content check per manifest | Content matches pre-release state |
| 4 | No secondary breakage | Spot-check 2-3 skills not part of the rollback | Normal behavior |
| 5 | GitHub state consistent | Check issue/milestone/label state | Consistent with rollback (reopen issues if auto-closed by reverted PR) |

## Communication Requirements

| Timing | Audience | Content | Channel |
|--------|---------|---------|---------|
| **Rollback initiated** | User (workspace owner) | What failed, which strategy selected, estimated timeline | Session output |
| **Rollback completed** | User | What was rolled back, verification results, root cause (if known) | Session output |
| **Root cause identified** | User + release plan | Root cause analysis, prevention plan, forward fix timeline | Release plan update |

## Rollback Trigger Criteria

Define these in the release plan BEFORE execution:

| Trigger | Threshold | Strategy |
|---------|-----------|----------|
| Skill invocation failure | Any changed skill fails to load | Partial Revert (skill-specific) |
| Cross-reference breakage | Any broken reference detected post-deployment | Forward Fix |
| Main branch regression | `git status` shows unexpected state | Full Restore |
| Verification dimension failure | Dimension 1-3 FAIL per verification-checklist.md | Per decision model above |
| User-reported issue | User reports unexpected behavior post-deployment | Assess per decision model |
