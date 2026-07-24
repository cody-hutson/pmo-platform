---
version: governance-ci-gates
date: 2026-07-24
type: note
issues: ["#1632", "#1485", "#1484", "#2656", "#1486", "#3795"]
pr: "#3799"
links:
  plan: release/releases/plans/governance-ci-gates_RELEASE_PLAN.md
  log_anchor: "#deployment-log-governance-ci-gates"
reversibility-tier: MODERATE
themes: ["cluster:process-protocol"]
summary: "Load-bearing governance checks now run on the pull request as reporting gates; the switch to actually blocking a bad merge is a deliberate later step."
requires_action: false
breaking: false
components: ["deploy.sh", "gate-criteria-spec.md", "gate-efficacy-standard.md", "CI workflows"]
followups: ["#3804"]
---

# Governance checks now run at the pull request, not just after a merge lands

2026-07-24 · governance-ci-gates

Several structural checks that used to run only on the operator's machine — after a change was already merged — now also run automatically on the pull request that proposes the change. For now they report what they find without blocking, so nothing you merge today is stopped by them; the switch to actually blocking a bad merge is a deliberate later step.

> **Skip the rest** unless you open pull requests against this repository or run platform releases.

## Who this affects

- Anyone who opens a pull request against this repository, and the workspace operator who runs releases. Project and operations work is unaffected — no skill behavior changes.

## What changed for everyone using the platform

- **Four governance checks now also run on the pull request.** The checks that confirm the release history is complete, that a skill's packaged copy is up to date with its source, and that the load-bearing pre-merge check battery passed now run automatically when a pull request is opened — not only later on the operator's machine. *Why it matters:* a problem these checks catch shows up on the proposed change itself, while it is still easy to fix, instead of after it has already landed on the main line.
- **The new checks report, they do not block yet.** Every new check is logged but not blocking for now, so no pull request is stopped by this release. *Why it matters:* each check can prove itself clean on real changes before anyone makes it mandatory, so it never blocks work on a false alarm during its trial period.
- **A confusing overlap in the gate rulebook is resolved.** One gate-criterion identifier had drifted to three different meanings across the documentation; it now means one thing everywhere ("acceptance criteria are measurable"). *Why it matters:* anyone reading the gate rules gets one unambiguous definition instead of three that silently disagree.
- **A previously-dead check is now wired up.** A close-out completeness check that existed but that nothing ever ran now has the automation that calls it. *Why it matters:* the check can finally do its job instead of sitting unused.

## Known limits

- The new checks are logged but not blocking during their trial period; making any of them actually stop a merge is a separate, deliberate step (a one-line switch plus a repository branch-protection change).
- The enforce-flip backlog is recorded but no check was flipped to blocking in this release: the evidence needed to confirm a check is safe to enforce lives in operator-only logs that an automated pull-request check cannot read, and the group is still reporting findings at scale.
- One related cleanup — other stale gate-criterion identifiers on the same rules — is tracked separately (#3804) and not addressed here.

Report issues at https://github.com/cody-hutson/pmo-platform/issues.

## Reversibility

**MODERATE** · confidence **HIGH**. The whole release reverts as a single `git revert -m 1` of the release pull request — every new gate is reporting-only, so a revert blocks nothing and re-syncs nothing (the change deploys no skill behavior). The tier is MODERATE rather than cheap only because of the one future surface this release sets up but does not itself pull: turning any gate into a blocking requirement is an operator-side branch-protection change, reversible by removing the requirement. Standard rollback window.

---

### Operator and engineering detail

**What was promoted, and how (#1485 / #1484 / #2656 / #3795).** Four load-bearing `deploy.sh --check` verifiers — the required-subset / hook-registry-index runner (#1485), release-corpus completeness (Check 32, #1484), `.skill` package content-freshness (Check 7, #2656), and the folded close-completeness gate (#3795) — gained thin-caller pre-merge CI workflows, each warn-mode-initial. The implementation keeps a single verdict engine per check: each `_cNN_compute_verdict` body in `deploy.sh` is shared by both the inline deploy-time `--check` block and its CI probe (CIAC-2), so the deploy-time verdicts stay byte-identical and no predicate is re-encoded in workflow YAML. #2656 also registers a new gate criterion, G6-06, for the package-freshness gate. Full audit detail in the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md#deployment-log-governance-ci-gates) and [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/governance-ci-gates_RELEASE_PLAN.md).

**The G3-05 criterion-ID collision (#1632).** The Gate-3 criterion identifier `G3-05` had drifted to three meanings across the corpus (a pre-renumber-rot artifact). Every live surface — the eval-writer stage-gate playbook, the stage I/O contracts, and a third surface in the operating model — was reconciled to the canonical "AC are measurable", which the eval-writer skill's own eval suite already expected, so the playbook is now consistent with both the gate spec and the skill. The stale sibling-ID mis-citations (G3-04 / G3-06) on the same constructs are a distinct rot class with ambiguous canonical mappings and are tracked as a follow-up (#3804), not re-mapped here.

**Enforce-flip deferred by design (#1486).** The decision ledger for the reporting-only check cohort ships with every flip deferred. The flip mechanism (`resolve_check_mode "<id>" "enforce"`) is already in-tree and proven on other checks; the deferral is evidence-based — the shakedown-drain signal lives in operator-instance, git-ignored logs that a pull-request agent cannot read, and a green snapshot on the current tree is not the drain criterion. The cohort is still reporting findings at scale, so flipping now would risk blocking on an unproven gate.

**Sample block — what the new gate annotation looks like (§2.8).** This release adds a shape someone must produce or read — a per-check `.enforce` sentinel file and a `# gate-efficacy:` posture annotation on the promoted check — so per the sample-block mandate, here is one realistic instance of the annotation and its sentinel:

```
# in core/deploy/deploy.sh, on the check being promoted to a required gate:
# gate-efficacy: posture=required
_c32_compute_verdict() { ...; }

# .github/release-corpus-completeness.enforce   (per-gate sentinel; this release ships "warn")
warn
```

**Version-less identity.** The milestone `93-governance-ci-gates` ships version-less / theme-named per the operator's Stage-4 decision, following the `cross-reference-integrity-ci` / `release-version-stamping` / `public-flip-*` precedents — no `vX.Y` is assigned, no signed-annotated tag is cut, and no GitHub Release is published; the tag-cut and GitHub-Release steps are deliberately omitted and their absence is not a close defect. This Stage 13 corpus close-out was hand-assembled via the documented Phase-B chore-PR mechanism because the close-out automation is version-keyed and cannot run for a pure-alpha slug.

### References

- Milestone: [93-governance-ci-gates](https://github.com/cody-hutson/pmo-platform/milestone/236)
- Integration PR: [#3799](https://github.com/cody-hutson/pmo-platform/pull/3799) at `18292527`
- Closed issues: [#1632](https://github.com/cody-hutson/pmo-platform/issues/1632) · [#1485](https://github.com/cody-hutson/pmo-platform/issues/1485) · [#1484](https://github.com/cody-hutson/pmo-platform/issues/1484) · [#2656](https://github.com/cody-hutson/pmo-platform/issues/2656) · [#1486](https://github.com/cody-hutson/pmo-platform/issues/1486) · [#3795](https://github.com/cody-hutson/pmo-platform/issues/3795)
- Follow-up: [#3804](https://github.com/cody-hutson/pmo-platform/issues/3804) (stale G3-04 / G3-06 sibling-ID mis-citations)
