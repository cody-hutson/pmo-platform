---
version: freshness-gate-measures-then-blocks
date: 2026-09-05
type: note
issues: ["#4332", "#5242", "#5897", "#5500", "#6181", "#6998"]
pr: "#7007"
links:
  plan: release/releases/plans/freshness-gate-measures-then-blocks_RELEASE_PLAN.md
  log_anchor: "#freshness-gate-measures-then-blocks-version-less"
reversibility-tier: CHEAP
themes: ["cluster:release-pipeline", "cluster:governance-enforcement"]
summary: "The check on deployed skill packages now really compares each against its source, and one that does not match can no longer be merged."
requires_action: true
breaking: false
components: ["skill-package-freshness gate", "deploy.sh Check 7", "dependabot", "SECURITY.md", "skill-deployment.md", "gate-criteria-spec.md"]
followups: ["#6417"]
---

# A stale skill package can no longer reach the main branch

2026-09-05 · freshness-gate-measures-then-blocks

The check that confirms every deployed skill package still matches the source it was built from was reporting success without comparing anything, because it was missing a library it needed and the failure was discarded before anyone could see it. It now installs what it needs, compares all 55 packages, says so plainly when it cannot compare, and stops a merge when a package is out of date.

## What you need to do

1. When you change a skill — its instructions or anything under its references folder — rebuild that skill's package and commit the rebuilt package alongside your change, in the same pull request. A change that leaves the package behind will now stop at the check instead of merging.
2. If an automated dependency-update pull request is blocked by this check, follow the self-service remediation steps now published in the repository's security policy. You do not need to wait for a maintainer.

## What changed for everyone using the platform

- **The package check compares packages again, instead of reporting success having compared none.** The comparison step needed a library the automated run never installed; the resulting error was swallowed twice, and the run finished green with 0 of 55 packages actually compared. The library is now installed, and a run that cannot compare stops loudly instead of finishing quietly. *Why it matters:* a green result on this check now means the comparison genuinely ran, so you can rely on it instead of re-checking by hand.

- **A package that no longer matches its source stops the merge.** The check was previously advisory — it recorded a mismatch and let the merge proceed. It is now a required check and blocks. *Why it matters:* the six packages that had to be rebuilt by hand after they drifted onto the main branch cannot accumulate that way again.

- **"I could not measure this" is now a real answer, distinct from "everything is current".** When the comparison cannot run for part of the roster, the check reports that outage as its own outcome and names the cause, rather than reporting the unmeasured packages as up to date. *Why it matters:* an environment problem now reads as an environment problem instead of disguising itself as a clean result.

- **Automated security updates have a documented way through.** Registering a blocking check would otherwise have stranded automated dependency updates, which cannot rebuild a package themselves. A published, self-service remediation path ships ahead of the check becoming required, and covers out-of-band fix branches too. *Why it matters:* a security update is no longer stuck behind a check it has no way to satisfy.

- **The written descriptions of this check now match what it does.** Five separate places described the check's behaviour, and they disagreed with each other and with the code. They now state the behaviour actually in force, including in the rule file consulted when someone writes a new acceptance criterion. *Why it matters:* someone writing a criterion against this check reads the same behaviour the check performs.

## Known limits

- **A stale package can still land behind a simultaneous merge.** Requiring branches to be up to date before merging would close that path; that setting was deliberately left unchanged in this release, so the gap remains open and is tracked rather than claimed as fixed.
- **Exactly one of six safety switches graduated.** The other five still only record a finding without stopping anything, and none of them has a deadline written anywhere the repository can check.
- **The updated rule file has not been copied into a running workspace.** The rule source on the main branch carries the new statement of this check's behaviour, but the deployed copy an agent actually reads is byte-identical to the pre-release text. Verified by comparing checksums; copying it across is a separate operator step that has not been performed.
- **The library version is pinned in three separate places with no shared source.** They can drift apart independently. A single shared definition is the durable fix and is the next candidate, not part of this release.
- **This release records no timing measurements.** The two data points a delivery-time figure is computed from were never written for this release, so the figure is genuinely absent rather than zero.
- **Expect this check to take longer, not less.** It now performs 55 real package rebuilds where it previously performed 55 immediate failures. The slower run is the fix working.

Report issues at the [pmo-platform issue tracker](https://github.com/cody-hutson/pmo-platform/issues).

## Reversibility

CHEAP / HIGH confidence. Each part reverts independently and the order matters: remove the required-check registration first, then return the safety switch to its previous setting, then revert the code. Reverting the code first, while the check is still required and still blocking, would leave every open pull request in the repository failing — the check runs on all of them, not only those that touch skills.

---

### Operator and engineering detail

**The green was unfalsifiable, not merely wrong.** The content arm's staged rebuild imports the packager, which imports its validator, which imports PyYAML — and the workflow installed no dependency. The `ImportError` was absorbed at two levels, so the verdict fell through to the mtime fallback, which is inert on a fresh checkout where every file carries the same clone timestamp. The result was `FRESH 55` computed from zero content comparisons. `FRESH 55` and "measured nothing" were the same observable, which is why no amount of reviewing the advisory log could ever have surfaced it: the sentinel's stated graduation precondition — a three-day log review with zero false positives — was unfalsifiable rather than unmet, because the arm that would populate that log had never executed. The flip was authorised on a positive falsification test substituted for the passive review window: seed a stale package, watch the check turn red while it is still non-required, restore byte-exact, watch it turn green, then merge and register.

**The third verdict token is an additive member of an existing one-line protocol.** `_c7_compute_verdict` echoes exactly one line, and every caller maps it. The new token withholds a verdict rather than reporting a clean one — the stale counter is absent, not zero — and precedence is `STALE > NOT-EVALUATED > FRESH`, so a real finding is never suppressed by a measurement outage and every blocking behaviour that predates the token survives byte-for-byte. Under the previous sentinel setting the outage is advisory on its own exit code, distinct from the stale advisory, so no caller can conflate "stale" with "unmeasured"; under the current setting an unmeasured roster blocks. The protocol as it now stands:

```
FRESH <n>                                    all n rostered packages content-fresh
STALE <count> <csv>                          count + comma-separated stale skills
NOT-EVALUATED <unmeasured> <total> <reason>  the content arm did not conclude for
                                             <unmeasured> of <total> rostered skills;
                                             a WITHHELD verdict, never a clean one
precedence: STALE > NOT-EVALUATED > FRESH
```

**Only one of the workflow's two names is registrable, and the wrong one is the file's first line.** The workflow file declares `name:` twice — a workflow-level key reading `Skill package content-freshness (pre-merge gate)` and a job-level key reading `Pre-merge .skill package content-freshness gate`. GitHub reports the job name as the check-run name, so the job-level string is the only registrable context; across 77 check runs at the measured anchor the workflow-level string appeared zero times, on a probe whose fabricated control also returned zero and whose live-context control returned true. Registering the workflow-level string would have produced a well-formed required check that no run ever reports under, and therefore protects nothing. Cite the structural position — `jobs:` → `skill-package-freshness:` → `name:` — rather than a line number, which drifts.

**Registration deliberately followed the merge.** The release repairs the very gate its own pull request passes through, so the seeded-stale proof ran while the check was still non-required: a red non-required check cannot block the merge, which is precisely why the proof runs there. Registration is an out-of-tree branch-protection change and nothing in the release's own diff performs it; the branch now carries ten required contexts, unchanged in every other setting.

**The regrowth claim was corrected rather than re-asserted.** The prior remediation's Part B was never built — retired as "superseded in substance" against a gate whose content arm did not work — and Part C was relaxed on the same premise. The governance limb of that false coverage claim is corrected in place, with its control arm recorded so a zero reading cannot be mistaken for an unresolved path.

**Dependency ingress was closed before the gate became required, not after.** Automated dependency updates and out-of-band fix branches both stale a package while passing every other control, and neither can rebuild one. Auto-rebuild was rejected on three verified blockers rather than on cost: the release ships block-with-documented-remediation instead. The npm ecosystem is registered with its version-update limit set to zero, which makes the security policy's labelling claims true and the npm surface discoverable without adding pull requests that would themselves stale a package. The admin-merge exception is written down and framed as non-routine, conditioned on a recorded rationale — and it is not a silent bypass, because the workflow also runs on pushes to the main branch, so a bypassed merge reddens the branch on the next run and the rebuild is still owed.

**Close shape for this release.** Identity is the capability slug and no version key is claimed, so six close outputs are inapplicable by construction rather than skipped: no version tag, no published GitHub Release (which anchors on that tag), no changelog section (there is no version key to head it — the projector itself refuses the emit rather than inventing a slug-keyed entry), no version-marker stamp, no close-class telemetry field (its cutover ships inert), and no rebuilt package (the release's twelve changed paths stale zero packages — measured against the packager's own query mode, with control arms returning one and six). Each is recorded as a not-produced marker with its reason in the deployment log rather than left as a silence.

For full implementation detail see the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md) and [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/freshness-gate-measures-then-blocks_RELEASE_PLAN.md).

### References

- Milestone: [freshness-gate-measures-then-blocks](https://github.com/cody-hutson/pmo-platform/milestone/385)
- Integration PR: [#7007](https://github.com/cody-hutson/pmo-platform/pull/7007) at `fade77d1`
- Closed issues: [#4332](https://github.com/cody-hutson/pmo-platform/issues/4332) · [#5242](https://github.com/cody-hutson/pmo-platform/issues/5242) · [#5897](https://github.com/cody-hutson/pmo-platform/issues/5897) · [#5500](https://github.com/cody-hutson/pmo-platform/issues/5500) · [#6181](https://github.com/cody-hutson/pmo-platform/issues/6181) · [#6998](https://github.com/cody-hutson/pmo-platform/issues/6998)
- Follow-up: [#6417](https://github.com/cody-hutson/pmo-platform/issues/6417) (the remaining five safety switches carry no repository-derivable graduation deadline; this release resolves the class for exactly one of them by substituting a positive falsification test for a passive review window)
