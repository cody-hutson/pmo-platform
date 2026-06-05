# release/releases/plans/ — release plan files

Per-release Stage 4 release plans live here, one file per release: `vX.Y_RELEASE_PLAN.md`.

## File naming

`vX.Y_RELEASE_PLAN.md` where `vX.Y` is the release version matching the GitHub Milestone slug suffix (e.g., `v1.0_RELEASE_PLAN.md` for Milestone `v1.0-initial`).

## Authoring contract

- **Authored by:** Stage 4 release-planning spoke (Procedure 0 in [`../../references/how-to/hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md))
- **Committed by:** Determined by the D-C Branch Topology decision gate:
  - **D-C SINGLE topology** (default): Engineering Commit 0 on the release branch
  - **D-C OPTION-A topology** (per-issue branches): Stage 4 release-plan chore PR landing on main BEFORE per-issue sub-task scaffolding
- **Read by:** All per-issue Stage 5/6/7/8 spokes; the hub Procedure 1 scaffolding; the operator at Stage 9 plan review

## Contents per file

Stage 4 spoke produces the plan with these sections (see [`../../references/pipeline/stage-04-planning.md`](../../references/pipeline/stage-04-planning.md) for the full spec):

- Summary (30 seconds)
- Dependency Graph
- Implementation Sequence
- Stage Applicability Matrix
- Contention Map
- Risk Register
- Operator Decisions / D-Gate blocks
- Release Class declaration
- Recommendations

## Classification

**UNIVERSAL-PUBLIC** per [`../../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md). Every per-issue Stage 5/6/7/8 spoke session reads the plan to ground its work; spokes run in isolated worktrees and cannot see operator-local files — git is the substrate that makes hub-spoke coordination work.
