---
version: hub-spoke-run-and-planning-discipline
date: 2026-09-03
type: note
issues: ["#5833", "#5084", "#5505", "#6596", "#6597", "#6598", "#6599"]
pr: "#6634"
links:
  plan: release/releases/plans/_unversioned/hub-spoke-run-and-planning-discipline_RELEASE_PLAN.md
  log_anchor: "#hub-spoke-run-and-planning-discipline-version-less"
reversibility-tier: CHEAP
themes: ["project:pipeline"]
summary: "The version marker behind the update notice can no longer move backwards, and more edits now stop for operator approval."
requires_action: false
breaking: false
components: ["version-grammar", "Stage 13 Close", "Stage 4 Planning", "autonomy-tiers.md", "finops-usage-extractor", "hub-spoke-bridge.md"]
followups: ["#6617", "#6236", "#6601"]
---

# Update notices stay accurate, and more edits now pause for approval

2026-09-03 · hub-spoke-run-and-planning-discipline

The marker that tells you whether your workspace is up to date can no longer be moved backwards by a release that finishes out of order, so an "update available" notice now reflects what you actually have. Separately, the test that decides whether a change counts as governance stopped carrying a short built-in list of files, which means an agent now stops for your approval on more edits than it used to.

## What changed for everyone using the platform

- **Update notices no longer go stale because a release closed out of order.** The file recording the platform's shipped version is now only ever moved forward — a release finishing after a newer one already landed leaves it alone instead of writing an older value over it. *Why it matters:* the update notice you see at the start of a session reflects the version you actually have, instead of reappearing because a marker moved backwards behind you.

- **The Releases page keeps pointing at the newest release.** Publishing a release now works out explicitly whether it should take the "Latest" badge, and declines it whenever the release currently holding the badge is newer. Previously the decision was left to a default that picks by date and version. *Why it matters:* the badge people follow to find the current release stops being pulled backwards by an older version that happens to publish late.

- **More edits now stop and ask you first.** The test deciding whether a change counts as governance no longer carries its own list of three files — it reads the governed set from the rule that defines it, which reaches surfaces that list never named, including edits to the deployed hook and rule surfaces. *Why it matters:* an agent will now pause for your sign-off on some edits it previously made on its own, and the change is a widening rather than a restatement.

- **Usage figures stop silently dropping releases that carry no version number.** Usage roll-up matched run directories on a leading version number, so every release identified by its name instead was left out of attribution entirely — dropped rather than reported as zero. *Why it matters:* usage and cost figures now count those releases, so the totals you read are no longer quietly short.

- **Release planning records what an agent may edit before the work starts.** Planning now classifies each item's write paths as unconstrained, needing a sanctioned session, or reserved for you, and carries that classification into the plan and the work items built from it. *Why it matters:* work only you can perform is visible while the plan is being written, instead of surfacing when someone is already part-way through building it.

## Known limits

- **The version-marker guard is not exercised by this release's own close.** This release is identified by its name rather than a version number, so the step that writes the version marker is skipped here. The guard ships covered by a purpose-built test fixture instead of by this close, which means a defect in it would first appear at a later out-of-order release.
- **One planning criterion ships knowingly unmet.** The agent-editability demonstration could not run — no item in this release carries the reserved-for-you classification — and a second criterion assumed a design that was not chosen.
- **A governance question is left open on purpose.** Whether writing to the portfolio and session-state files is reserved for you is answered inconsistently by three documents. This release names the disagreement and points readers at all three rather than picking a winner. One operator override record is still outstanding.
- **Four rebuilt skill packages are on the main branch but not yet copied into an install.** The packages ship with the release; copying them into a running workspace is a separate operator step and has not been performed.
- **Four planning checks could not be evaluated.** They are written as `python3` invocations, which the verifier deliberately refuses to execute as a read-only-execution boundary. Widening that allowlist is not the fix; the gap is tracked as [#6236](https://github.com/cody-hutson/pmo-platform/issues/6236).

Report issues at the [pmo-platform issue tracker](https://github.com/cody-hutson/pmo-platform/issues).

## Reversibility

CHEAP / HIGH confidence. Reverting the single merge commit restores the prior behaviour — the release adds no deletes and no renames, migrates no data, and holds no state outside the repository. The four rebuilt skill packages are regenerated from the restored sources on the next deploy. The one asymmetry is the version-marker guard above: because this release's own close does not run it, a defect there would surface later than the revert window, even though the revert itself stays cheap.

---

### Operator and engineering detail

**Hub-side staging gains a governed home and a lifecycle** — Run-Directory Discipline previously bound spokes only, leaving hub-authored comment bodies staged with no declared location or end-of-life. A `staging/` member now sits inside the per-release hub-state run directory, its run key is determinate, and its lifecycle ends at the release-close cleanup step where the hub reports it for operator disposition — nothing deletes it automatically. Two gate-coverage register rows record the enforcement honestly: one wired half, and one named gap.

**The version stamp is monotone, not merely idempotent** — the stamp phase now compares through the version-grammar helper rather than a string comparison (which ranks `v4.9` above `v4.10`) and no-ops whenever the recorded version is equal to or higher than the one closing. Surface-1 publication resolves the `--latest` badge explicitly at every construction site, withholding it on every verdict except a genuine advance, because a badge wrongly taken regresses consumers silently while a badge declined is recoverable with one edit. The superseded "idempotent" framing is gone from the specs and the chip pattern as well as the code.

**Stage-4 planning reads agent-editability** — a new planning phase derives the Tier-0 floor and the sanctioned-session gate from the hooks that enforce them, at a named commit, and records a per-path table. Per-path rows are retained rather than collapsed into the card class, and a `delete` row is recorded out-of-scope as a destructive-control class. The classification is transported into the sub-task and the engineering brief, and scaffolded in the release-plan template. The two remediation homes the original design deferred — late-add stamping, and the brief-time editability pre-flight with its currency dimension — land in the same run.

The new required plan block carries this shape, one row per write path:

```
| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
| #N   | [path]         | yes/no   | yes/no       | tier-0-floored          | (most-constrained  | operator-executed |
|      |                |          |              | sanctioned-session-req. |  of this card's    | sanctioned-session |
|      |                |          |              | unconstrained           |  rows)             | ordinary spoke    |
```

**The governed set is cited, not restated** — all three enumerations in the autonomy-tier spec now route to their authority. The spec separates two questions it had been answering as one: what is *governed* (decided by the source rule) versus what is *mechanically blocked* (decided by the hook's registry entry). One acceptance limb ships deliberately unmet: declaring the hook authoritative would drop two charter-named governance files out of the governed set, so the release names the three-way conflict in place instead of fabricating a resolution.

**The run key is spelled one way** — hub-state run directories are keyed on the milestone slug at every corpus site, so a consumer filtering on one form no longer drops the other. The resolver reads the slug form first and treats the small number of version-keyed directories that predate the convention as read-only.

**Usage attribution binds its worktree column from the file header** — roll-up now parses the milestone slug and resolves slug-primary release branches, with fixtures covering the slug, malformed, collision-peer and managed-fence cases plus a shadowing guard.

**Close shape for this release** — identity is the capability slug and no version key is claimed, so five close outputs are inapplicable by construction rather than skipped: no version tag, no published GitHub Release (which anchors on that tag), no CHANGELOG section (there is no version key to head it), no version-marker stamp, and no close-class telemetry field (its cutover is not armed). Each is recorded as a not-produced marker with its reason in the deployment log rather than left as a silence.

For full implementation detail see the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md) and [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/_unversioned/hub-spoke-run-and-planning-discipline_RELEASE_PLAN.md).

### References

- Milestone: [hub-spoke-run-and-planning-discipline](https://github.com/cody-hutson/pmo-platform/milestone/367)
- Integration PR: [#6634](https://github.com/cody-hutson/pmo-platform/pull/6634) at `a683230d`
- Closed issues: [#5833](https://github.com/cody-hutson/pmo-platform/issues/5833) · [#5084](https://github.com/cody-hutson/pmo-platform/issues/5084) · [#5505](https://github.com/cody-hutson/pmo-platform/issues/5505) · [#6596](https://github.com/cody-hutson/pmo-platform/issues/6596) · [#6597](https://github.com/cody-hutson/pmo-platform/issues/6597) · [#6598](https://github.com/cody-hutson/pmo-platform/issues/6598) · [#6599](https://github.com/cody-hutson/pmo-platform/issues/6599)
- Follow-up: [#6617](https://github.com/cody-hutson/pmo-platform/issues/6617) (decision record for the editability derivation) · [#6236](https://github.com/cody-hutson/pmo-platform/issues/6236) (verifier cannot evaluate `python3` criteria) · [#6601](https://github.com/cody-hutson/pmo-platform/issues/6601) (engineering sub-task complete in substance)
