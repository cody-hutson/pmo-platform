---
version: release-version-stamping
date: 2026-06-20
type: note
issues: ["#1643"]
pr: "#1693"
links:
  log_anchor: "#release-version-stamping-version-less"
reversibility-tier: CHEAP
themes: ["cluster:process-protocol"]
summary: "The release pipeline now stamps the platform version file at every release cut, and a deploy-time check stops it from silently falling behind — so the \"update available\" banner stays accurate."
requires_action: false
breaking: false
components: ["automated-closeout.sh", "stage-13-close.md", "deploy.sh", ".version"]
followups: []
---

# The platform version file now stays accurate after a release

2026-06-20 · release-version-stamping

The platform tracks its own version in a single file (`.version`), and a session-start check compares that file against the latest published release to tell you when an update is available. That file had stopped being updated when a release shipped, so it was frozen several versions behind — which made the check show a permanent "update available" message that no update could ever clear, because the out-of-date value was baked in at the source. This release corrects the stale value, makes updating that file an owned step of every release close-out, and adds a check that fails the build if the file ever drifts behind the shipped release line again.

> **Skip the rest** unless you run platform releases or read release notes for what changed in the pipeline.

## Who this affects

- The workspace operator and anyone who runs the release pipeline. Everyone else sees only the indirect benefit: the "update available" banner now reflects reality.

## What changed for everyone using the platform

- **The version banner is accurate again.** The version file now matches the shipped release line, so the session-start "update available" check no longer reports a phantom update that running an update can't clear. *Why it matters:* you can trust the banner — when it says an update is available, there really is one.
- **Stamping the version is now an owned release step, not a manual habit.** The release close-out automation writes the version file as part of the close, and the close-out process documentation lists it in the required output set. *Why it matters:* the bump can no longer be silently forgotten release after release, which is exactly how the file fell behind in the first place.
- **A guard against silent drift.** A deploy-time check fails if the version file falls two or more versions behind the latest release, while still tolerating the brief one-version gap that is normal between cutting a release and finishing its close-out. *Why it matters:* a regression of this exact bug is caught by the build instead of surfacing later as a confusing perpetual banner.

## Known limits

- The drift check anchors on the latest reachable release tag. A release that is tagged but whose published GitHub Release was never created is a related close-out-completeness gap handled separately; this release scopes the version-file ownership and its drift guard.

Report issues at https://github.com/cody-hutson/pmo-platform/issues with the `cluster: process-protocol` label.

## Reversibility

CHEAP / HIGH confidence. A single `git revert -m 1` of the release pull request reverses the change. The new close-out step and the new drift check are additive (the check ships warn-tolerant for the legitimate one-version window), there is no data migration, and the change deploys nothing — so there is nothing to re-sync after a revert. Standard rollback window.

---

### Operator and engineering detail

**The defect (#1643)** — The repo-root `.version` is the platform's version source-of-truth; `update.sh` derives an install-time snapshot from it (per ADR-017) but does not author it, and `core/hooks/notify-version-skew.sh` reads it at session start to compute the skew banner. The file had frozen at `v2.08` *inside* the `v2.09` and `v2.10` tags (`git show v2.10:.version` → `v2.08`), because the bump was an unwritten manual habit that became permanently absent once Stage 13 was automated (`automated-closeout.sh` never referenced `.version`). The result was a perpetual "update available" no `git pull`/`update.sh` could clear, since the stale value is committed at the source and `update.sh` only re-propagates it. Classification: PROC + HAND — a silent contract gap at an automation-migration boundary.

**The three-layer fix** — **(L1)** corrected the stale value so `.version` tracks the shipped release line on `main`. **(L2)** made the stamp an owned Stage 13 step: a new `phase_bump_version` in `release/tools/automated-closeout.sh` writes `.version = $VERSION` and adds it to the chore-commit staging list (idempotent on re-run; previewed under `--dry-run`), and `release/references/pipeline/stage-13-close.md` now declares `.version` in the Stage 13 output set and its Phase B commit mechanism, with a `docs/UPDATE.md` clarification that `.version` is release-cut-owned. **(L3)** added `core/deploy/deploy.sh` **Check 39**, which asserts `.version` equals the latest reachable release tag — it FAILs when `.version` is two or more minors behind and PASSES once corrected, while tolerating the legitimate one-version Stage 12→13 window as a WARN rather than a FAIL. Regression coverage lives in `core/deploy/tests/test_version_stamping.sh`, wired into the suite via `.github/workflows/install-tests.yml` (fails against the buggy state, passes after the fix).

**Version-less identity** — The milestone `release-version-stamping` (Release Class A — Routine) ships **version-less** per the operator's Stage 4 decision (2026-06-20), following the `public-flip-install-blockers` / `intake-elicitation-skill` / `domain-aware-stage5-design` / `memory-to-corpus-codification` / `cross-reference-integrity-ci` precedents — no `vX.Y` is assigned to this release, no signed-annotated tag is cut, and no GitHub Release is published; the tag-cut and GitHub-Release steps are deliberately omitted and their absence is not a close defect. Deploy no-op — the changed set is release-tooling plus governance/reference corpus plus one regression test plus one CI-workflow wiring plus the `.version` source file, with no `SKILL.md` and no `packages/` touched. This Stage 13 corpus close-out was hand-authored because `automated-closeout.sh` is version-keyed and cannot run for a version-less release (the documented Phase-B chore-PR mechanism).

For full implementation detail see the [RELEASE_LOG.md entry](../../RELEASE_LOG.md#release-version-stamping-version-less).

### References

- Milestone: [release-version-stamping](https://github.com/cody-hutson/pmo-platform/milestone/221)
- Integration PR: [#1693](https://github.com/cody-hutson/pmo-platform/pull/1693) at `1d1c0ec2ed3475be4403f5d606fd5a05f7501e11`
- Issue: [#1643](https://github.com/cody-hutson/pmo-platform/issues/1643)
