# Stage 11: Snapshot

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## Classification: PLATFORM-SATISFIED

## 1. Purpose
Capture pre-change state for rollback capability. **How the platform satisfies this:** Git history automatically preserves every prior state. The commit immediately before the merge IS the snapshot. `git revert` restores any prior state without manual intervention.

**Deferred Items (mid-pipeline) — pass-through:** This stage is PLATFORM-SATISFIED and exposes no `## 7. Stage-Transition Gate`, so it performs no per-gate "Deferred Items" accounting. Any mid-pipeline deferred item whose target stage falls at or after this point passes through the compressed Stage 9→12 path to the next real gate (Stage 12 Execute), which carries the incoming-deferred-items accounting clause per deferred-item-tracking.md §13.8.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation | Satisfaction Mechanism |
|---|---|---|---|
| Purpose | Code freeze; final build; release candidate tagging | Git branch contains the complete release candidate | PR branch = release candidate; merge to main = "build" |
| Governance Focus | Release candidate validation | PR review (Stage 9) validates the release candidate | Stages 7-8-9 quality gates validate before merge |
| Artifact Inputs | Release candidate, build environment | PR ready for merge | Git branch with committed changes |
| Artifact Outputs | Tagged release branch, final build, release notes | Git tag + merge commit + PR description | Automated by git workflow |

Key compression: Ref Model assumes creating build artifacts, freezing code, and establishing rollback baseline. For a git-native platform, every commit is a snapshot. Every tag is a release candidate marker. `git revert` is the rollback mechanism.

## 3. Persona

**Classification:** ABSENT — PLATFORM-SATISFIED (canon-conformant).

No explicit persona for the canonical compressed path — the platform mechanism (git history IS snapshot) satisfies the stage purpose. Explicit "Release Engineer — Snapshot Verifier" persona activates only on non-compressed exception cases (see §10 Retro table).

> **Persona card:** see [`release-personas.md §Stage 11`](../specs/release-personas.md) for the canonical PLATFORM-SATISFIED declaration including activation criteria for non-compressed exception cases.

## 8. Automation Level
Tier 1 (Auto) — git version control provides snapshots automatically. No agent or human action required.

## 9. Gap Summary
No gaps spawned. Platform satisfaction is complete for the current git-native deployment model.

## 10. Retro

**When Stage 11 Would NOT Compress:**

| Scenario | Why Snapshot Needed | Example |
|---|---|---|
| Layer 2 files with no git history | Git doesn't track these; no automatic rollback | Operational trackers, session state, project files |
| Database state changes | Git tracks schema code, not data state | Pre-migration database backup needed |
| External system configurations | Third-party system state not in git | API gateway configs, DNS records, CDN rules |
| Binary artifacts | Large binaries may not be in git | Compiled packages, Docker images, model weights |
| Multi-system coordinated releases | Need snapshot of ALL systems, not just git | Snapshot each system independently before cutover |

**Rollback Mechanism:**

| Method | Scope | Speed | Risk |
|---|---|---|---|
| `git revert` (single commit) | Single commit | Seconds | Creates new commit; clean history |
| `git revert` (merge commit with `-m 1`) | Entire release (merge) | Seconds | Reverts all changes in the release |
| Re-deploy previous skill versions | Skill files only | Minutes | Requires copy from prior git state to installed path |

Destructive reset commands blocked by platform settings (`<OPERATOR_INSTANCE_CLAUDE_SETTINGS>` deny rules). Only forward-moving rollback (`git revert`) permitted, preserving the audit trail.

**Framework dimensions touched:** State Persistence (git history is snapshot). Per [execution-framework.md](../../../core/disciplines/execution-framework.md). Appended at stage end per the PLATFORM-SATISFIED convention used for Stage 10.
