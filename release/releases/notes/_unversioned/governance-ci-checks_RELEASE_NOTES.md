---
version: governance-ci-checks (version-less)
date: 2026-07-22
type: note
issues: ["#1039", "#1490", "#2106", "#2219", "#2682", "#2685", "#3009"]
pr: "#3662"
links:
  plan: release/releases/plans/governance-ci-checks_RELEASE_PLAN.md
  log_anchor: "#deployment-log-governance-ci-checks"
reversibility-tier: MODERATE
themes: ["cluster:gate-handoff", "cluster:process-protocol", "project:governance-hygiene"]
summary: "Six classes of governance drift now have machine checks that report them, and 23 decision records stuck awaiting a closed review were corrected."
requires_action: false
breaking: false
components: ["deploy.sh --check", "link-check.yml", "repo-integrity.yml", "label-taxonomy.md", "ADR corpus"]
followups: ["#3706", "#3707", "#3708", "#3709", "#3710", "#3711"]
---

# Governance rules now check themselves at build and merge time

2026-07-22 · governance-ci-checks

Six kinds of governance drift that previously reached the main branch and were only caught by someone noticing — mislabeled work items, milestone descriptions that had fallen out of step with what was actually in them, epics filed under other epics, dead links in parts of the repository nothing scanned, and decision records left saying "Proposed" long after the review that was meant to approve them had closed — now each have a check that reports them. Every new check is logged but not blocking on this release, so nothing you do today starts failing.

> **Skip the rest** unless you run the deploy check, open pull requests against this repository, or maintain milestone descriptions and work-item labels.

## Who this affects

- Anyone who runs the deploy check or reads its output.
- Anyone opening a pull request against the platform repository (two of the new checks run there).
- Anyone who writes milestone descriptions, labels work items, or authors architecture decision records.

Nobody else has to do anything. No skill behavior, project artifact, or status output changes.

## What changed for everyone using the platform

- **Epics filed under other epics, and stale hierarchy descriptions, are now reported.** The deploy check reads both the written hierarchy rules across the normative documentation and the live parent-child links on the backlog, and reports where either disagrees with the model. *Why it matters:* a mis-parented epic used to be found by someone scrolling the backlog; it now shows up in a check you already run, with the specific pair of item numbers named.
- **Milestone descriptions are reconciled against what the milestone actually contains.** The check compares the cards a milestone's scope section names against its live membership and reports both directions of drift — named but not a member, member but never named. *Why it matters:* a scope list that quietly went stale stops reading as authoritative, so planning from a milestone description no longer means planning from a description nobody re-checked.
- **Label integrity checks now cover every kind of work item, not just improvements.** The status-label checks previously read only items labeled as improvements; they now read all open intake, with epics and pipeline stage markers explicitly exempt because they are containers rather than lifecycle items. *Why it matters:* a bug or observation missing its status label used to be invisible to the check, and the widened scope catches it without flooding you with findings about every epic.
- **Broken documentation links get caught in parts of the repository that were never scanned, and both link checkers finally agree.** Coverage extends to the decision-record tree, the deploy tooling tree, the repository-root documents, and the workflow directory; separately, the two checkers that scan for broken links now read a single shared scope list and a single shared ignore list, so they can no longer return different answers about the same files. *Why it matters:* a link that broke because someone deleted its target is now found wherever it lives, and a clean result from one checker means the same thing as a clean result from the other.
- **The deploy check roster can no longer silently lose a check.** A new check asserts that every check defined in the deploy script also announces itself when it runs, and vice versa. *Why it matters:* a check that stopped announcing itself used to disappear from the visible run while still looking present in the source, so a run could read complete while a check had quietly gone missing.
- **Decision records that were waiting on a review that already closed now say what they mean.** Twenty-three architecture decision records that had been left reading "Proposed" after their approving review closed were corrected, and a new close-out step plus a standing report keep the gap from re-opening. A separate check reports decision records carrying a hardcoded commit reference, a hardcoded population count, or an operator identifier. *Why it matters:* reading a decision record now tells you whether the decision was actually made, instead of leaving you to work out whether "Proposed" is current or just stale.

## Known limits

- **Nothing is enforced yet.** Every check in this release reports rather than blocks, and no mode file ships that would change that. Turning any of them into a blocking check is a separate, deliberate step after a review period, and one of them is additionally gated on a decision-record cleanup that has not started.
- **The milestone-to-epic membership check has nothing to enforce against today.** None of the open milestones currently declares an owning epic in the format the check reads, so its blocking half reports zero and stays inert until milestone descriptions adopt the marker. The check states this in its output rather than reading as a silent pass.
- **One real hierarchy finding is live and unresolved.** The backlog contains one epic parented to another epic. Whether that is drift or a legitimate sub-epic is an open question about the hierarchy model itself, not a defect in the check.
- **Two decision records were deliberately left as "Proposed."** One is superseded in part, so the right corrected value needs a judgment call; the other carries no approval promise at all, so there is nothing to reconcile. Both are recorded rather than quietly flipped.
- **Coverage of the hierarchy-description check is narrower than it looks.** It does not scan one module directory, and an apostrophe in ordinary prose can hide an assertion from it, so its clean result is not yet strong evidence of a clean corpus.

Report issues at https://github.com/cody-hutson/pmo-platform/issues.

## Reversibility

**MODERATE / HIGH confidence.** The six check mechanisms are additive and revert cleanly — each was built as its own commit so any one can be removed without touching the others. The twenty-three decision-record status corrections are a data change to governance files and were deliberately kept in a commit separate from the mechanisms, so a mechanism can be reverted without unwinding the audit; reverting the corrections themselves would restore twenty-three records to a state already established as inaccurate. No migration, no schema change to existing consumers, no user-visible default altered. Whole-release rollback is a revert of the integration merge.

---

### Operator and engineering detail

**Six gates, one branch, one merge.** The release shipped as a single pull request built in four serialized waves — the four deploy-check slices (Checks 55, 56, the in-place Check 16 widen, and 57), then the dead-reference coverage extension, then the decision-record ratification mechanism (G-CL9 plus advisory Check 58), then a dev-testing rework wave. All six mechanisms ship warn-mode-first per the release's own cross-issue acceptance criterion; no `.mode` file is committed, so the shared `warn` default governs. Live findings volume on merge day: 8 status-label rows, 1 hierarchy row, 13 membership-reconciliation rows, 24 decision-record advisory rows — every one non-blocking by design, and the honest statement of what this release enforces today is: nothing yet.

**Three checks were verified against their own release.** Check 57 (extraction contract) landed after the other deploy-check slices specifically so the release's own new checks would be its first test data — `DEFBLOCKS 58 / RETIRED {15,24} / EMITTERS 56 / COUNT 0`, and it held again after the later wave re-edited the same file. The retired-reserved carve-out is detected structurally from the source header, never hardcoded, so a future retirement is picked up without editing the checker.

**Dev testing caught two real defects in work this release introduced, and both were fixed before merge.** The doc-link scope was single-sourced across both callers while the *allowlist* stayed split, taking the deploy-time baseline from 0 to 84 findings while CI stayed at 0 — a measured regression the build-side "clean baseline" evidence had missed because it was measured on the CI path only. The fix made `--allowlist` repeatable and union-ordered so the tracked base layers under the operator-instance file; measured after, deploy-time returned to 0. Separately, the hierarchy check's documented exemption format was structurally unreachable in both accepted spellings, and its self-test passed vacuously — it would still have passed with the loader deleted. Both axes were fixed and the suite de-vacuumed by mutation testing (gut the loader, confirm the new cases fail), taking the self-test from 15 to 21 cases.

**One dev-testing diagnosis did not survive verification, and the record says so.** A finding predicted that widening the membership check's basis to all issue states would lift precision from roughly 17% to near-complete by removing closed-card false positives. Resolving every reference individually showed only one of eleven flags was explained by closure; seven referenced items belong to no milestone at all and three belong to a different milestone — all genuine divergences. The fix is still correct and was applied, but it buys about one finding rather than ten, and the corrected causal reading is recorded rather than the predicted one.

**Scope changed mid-release, twice, in opposite directions.** The decision-record durability lint was pulled *out* of this milestone at plan review and relocated to the decision-record conformance milestone, then retagged back *in* by operator decision at the plan-review gate after it had been built on this branch — the milestone assignment was corrected to match where the work landed rather than the reverse. The conformance milestone now holds a single remaining member. Separately, one slice's premise died before build: its parity target had been removed rather than cleaned by an earlier commit, so it was re-scoped to assert its contract entirely inside the deploy script with no documentation-side marker, honoring the earlier removal instead of re-creating the duplicate surface it had eliminated.

**The decision-record corrections were surgical by mandate.** Twenty-three files, twenty-three insertions, twenty-three deletions, every changed line a status line — no section reordering, no header rewrites, no reflow — so the pending structural conformance sweep rebases over them rather than colliding. Supersession annotations dropped from status text are preserved verbatim in each record's dedicated frontmatter field. A coordination note recording the corrected set is posted on the conformance issue so that sweep does not restore a stale value during normalization.

**Version identity.** This release is version-less by recorded determination — the milestone is theme-named with no version component, so no version slot was contended for and no tag was claimed. Six prior releases in the log carry the same identity form.

For full implementation detail see the [RELEASE_LOG.md entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md#deployment-log-governance-ci-checks) and [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/governance-ci-checks_RELEASE_PLAN.md).

### References

- Milestone: [governance-ci-checks](https://github.com/cody-hutson/pmo-platform/milestone/266)
- Integration PR: [#3662](https://github.com/cody-hutson/pmo-platform/pull/3662) at `f0d95a58baeb67f7bbabf565259e6c128b79b153`
- Closed issues: [#1039](https://github.com/cody-hutson/pmo-platform/issues/1039) · [#1490](https://github.com/cody-hutson/pmo-platform/issues/1490) · [#2106](https://github.com/cody-hutson/pmo-platform/issues/2106) · [#2219](https://github.com/cody-hutson/pmo-platform/issues/2219) · [#2682](https://github.com/cody-hutson/pmo-platform/issues/2682) · [#2685](https://github.com/cody-hutson/pmo-platform/issues/2685) · [#3009](https://github.com/cody-hutson/pmo-platform/issues/3009)
- Follow-up: [#3706](https://github.com/cody-hutson/pmo-platform/issues/3706) (hierarchy-check recall gaps) · [#3707](https://github.com/cody-hutson/pmo-platform/issues/3707) (two gates disagree on the decision-record identifier carve-out) · [#3708](https://github.com/cody-hutson/pmo-platform/issues/3708) (unmeasured recall on the hardcoded-count rule) · [#3709](https://github.com/cody-hutson/pmo-platform/issues/3709) (stage markers ship without their label) · [#3710](https://github.com/cody-hutson/pmo-platform/issues/3710) (allowlist name no longer matches its role) · [#3711](https://github.com/cody-hutson/pmo-platform/issues/3711) (membership check does not split its two divergence sub-classes)
