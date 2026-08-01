<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# CHANGELOG_ARCHIVE-_unversioned

Archive segment of [`CHANGELOG.md`](CHANGELOG.md) — the **_unversioned** release family.

This file is the same record as its parent ledger, relocated. It is a **Vital**
record under `core/governance/RECORDS_POLICY.md`, retained permanently, and it
inherits its parent's class: a segment is a disposition *destination*, never
itself a disposition *source*. Nothing here is a lesser record for having aged
out of the working set.

It lives in the same directory as its parent deliberately, so `grep -r` over
that directory still finds this content exactly as it did before the move. Each
entry below retains its heading in the parent ledger, with a pointer here.

Entries are appended by `release/tools/sweep-release-corpus.py`; the file is
append-only and is never itself swept.

---
## [declarative-gating-model] - 2026-06-24

Declarative cross-methodology gate conditions — a work-item type-pack gate can now depend on a *related* item's workflow status, or on an *aggregate over a set* of related items (a Kanban WIP limit), instead of only the item's own fields. Version-less (theme-named); research-led; additive (the meta-schema stays v1).

### Added

- **Related-item-status gates.** A gate can depend on the workflow status of a related work item — a child Story can't be groomed to `ready` until its parent Epic is design-approved; a Story can't leave `ready` while a blocking Spike isn't `done`. The condition resolves across the relationship you declare (parent/child, depends-on, blocks).
- **Set-aggregate gates.** A gate can depend on an aggregate over a set of related items — most importantly a Kanban WIP limit ("no more than N items in-progress at once") — making pull/flow limits first-class instead of inexpressible. Mutually-gating loops are detected and refused rather than deadlocking.

[Full notes](release/releases/notes/declarative-gating-model_RELEASE_NOTES.md)

## [public-flip-depersonalization-enforcement] - 2026-06-21

Public-flip depersonalization + path-portability enforcement — the public repo's depersonalization/portability boundary moves from manual vigilance to standing, warn-mode-initial guards. Version-less (theme-named).

### Added

- **Path-portability + depersonalization-token build checks.** `deploy.sh` Check 43 flags non-portable machine paths (`/Users//home`, bare operator-instance paths) in tracked scripts; Check 44 enforces the `[OPERATOR_*]` token registry and ratchets against reintroduced private GitHub-Projects IDs. Both consume a shared `path-leak-patterns.sh` primitive.
- **Runtime guards (warn-mode-initial).** A gh-issue-ops path-leak hook scans `gh issue/pr` bodies (including `--body-file` content) for operator-local paths before they post to the public repo; a draft-file hook plus a `repo-integrity` CI gate keep draft/scratch content out of the tracked corpus.
- **GitHub-Projects token vocabulary.** Six `[OPERATOR_PROJECTS_*]`/board tokens registered in the depersonalization spec §1.1 with an `operator.toml [projects]` home.

### Changed

- **`operator.toml` lossless round-trip.** The setup writer preserves operator-added sections verbatim instead of dropping them on rewrite.
- **`[OPERATOR_JIRA]` → `{{JIRA_BASE_URL}}`.** The Jira base is a localized value (DC3), not an identity token.
- **Orphan path-variable convergence.** The residual `PMO_INSTANCE_PATH` fallthrough converges onto `${CLAUDE_WORKSPACE_ROOT}` per ADR-017/ADR-032.

## [parallel-launch-quota-budget-gate] - 2026-06-14

Version-less release (no `vMAJOR.MINOR` assigned; ships under the slug `parallel-launch-quota-budget-gate`, which is also the signed git tag and the GitHub Release tag). Running several release tasks in parallel used to launch them blind to the operator's remaining usage window, so a batch could fail partway through once the window was exhausted; the release pipeline now estimates a parallel batch's cost and checks it against the remaining window before launching, and re-checks before each wave rather than only once at planning time.

### Added

- **A usage-window check before parallel work launches.** Before firing a batch of parallel tasks, the pipeline estimates its cost against the remaining usage window and either proceeds, runs the tasks serially, holds the batch for the next window, or trims per-task cost. *Why it matters:* a batch no longer half-completes and then fails on a depleted window — you get a recommended course of action up front instead of started-but-failed work to recover. ([#23](https://github.com/cody-hutson/pmo-platform/issues/23))
- **The check runs before every wave, not just at planning.** The budget is estimated once at release planning and re-validated before each parallel wave, accounting for work done in between and elapsed window time. *Why it matters:* a window that was fine at planning but has since been drawn down is caught before the next batch launches, not after it fails. ([#23](https://github.com/cody-hutson/pmo-platform/issues/23))
- **A record of what each launch reserved.** Parallel launches can record an entry noting the estimated cost reserved against the window. *Why it matters:* budget estimates get more accurate over time as real launch costs accumulate, grounding future checks in observed cost rather than a fixed guess. ([#24](https://github.com/cody-hutson/pmo-platform/issues/24))

### Changed

- **The constraint is named correctly — a usage window, not a rate limit.** An overrun is routed to the mitigations that address a cumulative usage limit (run serially, defer, or reduce scope); in-prompt staggering is documented as a rate-limit-only defense, not the usage-window fix. *Why it matters:* the fix you are offered matches the real problem, rather than a timing tweak that does not move a cumulative-usage limit. ([#24](https://github.com/cody-hutson/pmo-platform/issues/24))

[Full notes](release/releases/notes/parallel-launch-quota-budget-gate_RELEASE_NOTES.md)

## [cross-reference-integrity-ci] - 2026-06-13

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release). The reference-integrity rules the pre-commit hook applies locally now also run as warn-mode checks when a pull request opens.

### Added

- **Broken intra-repo links are now caught when a pull request opens.** A new link-check runs the same link-resolution engine the deploy step already uses, over the same files. *Why it matters:* a dead cross-reference is surfaced while it is still easy to fix, instead of at deploy time. ([#169](https://github.com/cody-hutson/pmo-platform/issues/169))
- **A stale skill-count claim or a live legacy IMP-XXX reference added to a skill spec is now caught on a pull request.** *Why it matters:* the platform's documentation can't quietly drift out of sync with how many skills actually ship. ([#130](https://github.com/cody-hutson/pmo-platform/issues/130))

### Fixed

- **The positional issue-reference check now agrees exactly with the pre-commit hook.** The pull-request check now uses the same line-position logic as the hook. *Why it matters:* the same reference passes or is flagged the same way whether it is checked on your machine or on the pull request. ([#314](https://github.com/cody-hutson/pmo-platform/issues/314))

[Full notes](release/releases/notes/cross-reference-integrity-ci_RELEASE_NOTES.md)

## [memory-to-corpus-codification] - 2026-06-10

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release) — a verification-only close-out of the memory-to-corpus codification scope. All nine targeted behavioral rules (five workspace guardrails + four git-workflow rules) were verified already present in the tracked corpus with their provenance recorded; the three now-redundant operator memory files were archived and retired from the operator memory store; and the tickets and milestone description were reconciled to live state. No user-visible behavior changes. Shipped single-branch via one [release pull request](https://github.com/cody-hutson/pmo-platform/pull/604) (the release-tracking corpus records the PR and merge SHA).

[Full notes](release/releases/notes/memory-to-corpus-codification_RELEASE_NOTES.md)

## [domain-aware-stage5-design] - 2026-06-07

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release) — Stage 5/7 design becomes domain-aware instead of assuming every deliverable is a pmo-platform markdown file. Shipped single-branch via one [release pull request](https://github.com/cody-hutson/pmo-platform/pull/503) (the release-tracking corpus records the PR and merge SHA).

### Added

- **Design now starts with a real "generate options, then narrow" step.** Stage 5 design runs a governed exploration step — generate candidate approaches, eliminate the weak ones with reasons, then score the survivors on a trade-off matrix — before the trade-off matrix that used to be the de-facto starting point. *Why it matters:* the requirement for "at least three alternatives" is now backed by an actual generation step instead of being asserted after a single approach was already chosen. ([#1](https://github.com/cody-hutson/pmo-platform/issues/1))
- **Per-domain best-practice guides (software and governance).** The first two domain guides land, each stating where its practices apply and where they do not, so design can be checked against the right body of practice for the work's domain. *Why it matters:* design guidance is no longer one-size-fits-all — software work is assessed against software practice, governance work against governance practice. ([#1](https://github.com/cody-hutson/pmo-platform/issues/1))
- **A design review criterion for domain best-practice.** The design-review checklist and the Dev-Testing review now assess a design against its target domain's authoritative practice, with an explicit "not assessed" flag when no guide exists yet rather than a silent pass. *Why it matters:* a design that ignores its domain's established practice is caught in review, and a gap in guide coverage is surfaced honestly instead of hidden. ([#346](https://github.com/cody-hutson/pmo-platform/issues/346))

### Changed

- **Impact analysis is chosen to fit the work's domain.** Stage 5 now selects the impact-analysis method per domain — the existing markdown dependency scan stays the default for documentation and governance work, while code, component, and solution domains can use a fan-out method suited to them, with a documented opt-out. *Why it matters:* impact analysis on non-documentation work is no longer forced through a markdown-tree scan that does not fit it. ([#345](https://github.com/cody-hutson/pmo-platform/issues/345))

## [intake-elicitation-skill] - 2026-06-06

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release) — a conversational intake front door. Shipped single-branch via one [release pull request](https://github.com/cody-hutson/pmo-platform/pull/424) (the release-tracking corpus records the PR and merge SHA).

### Added

- **A conversational intake skill, `intake-desk`.** A guided front door that turns a half-formed idea into a well-formed, correctly-typed, correctly-placed work item logged to the tracker — never a scratch file. It meets the idea at any altitude (a single bug or a portfolio initiative), proposes the work-item type and its place in the intake hierarchy and re-routes if the idea is reclassified, elicits only the fields that type and level need (a bug's reproduction/environment; a story's acceptance criteria/value; an initiative's outcomes/domain), applies the 5-test rule live as the stop condition, captures one item per request (a container's child work is a body callout for later slicing), and emits to the tracker only after an explicit confirm. *Why it matters:* intake is no longer cold form-filling against a static template — ideas arrive correctly typed and placed instead of under- or over-defined. ([#412](https://github.com/cody-hutson/pmo-platform/issues/412))

## [public-flip-install-blockers] - 2026-06-04

Version-less release (no `vMAJOR.MINOR` assigned, no git tag) — fresh-install & onboarding blockers gating the private→public flip. Shipped single-branch via one [release pull request](https://github.com/cody-hutson/pmo-platform/pull/627) (the release-tracking corpus records the PR and merge SHA).

### Fixed

- **Fresh install deploys the full skill roster, not zero skills.** Phase 2 skill deployment used release change-detection (an empty diff on a clean clone deployed nothing) instead of a full-roster deploy; a fresh install now deploys the complete skill roster, including manual-mode `.skill`-package installation. *Why it matters:* this was the launch blocker — a brand-new public user got zero skills. ([#606](https://github.com/cody-hutson/pmo-platform/issues/606), [#144](https://github.com/cody-hutson/pmo-platform/issues/144))
- **Skill deploy no longer hard-fails without a Cowork session.** A machine with no active Cowork path previously hard-failed and never reached the user-local skill mirror; a `COWORK_AVAILABLE` flag-guard now deploys the user-local roster, so a session-less install reaches exit 0 with the full roster instead of exit 1 with zero skills. ([#607](https://github.com/cody-hutson/pmo-platform/issues/607))
- **Sandbox overrides honored through skill deployment.** The documented `--workspace-root` / `--config-root` overrides were Phase-1-only; they are now honored in Phase 2 skill deployment, so a sandboxed deploy stays inside the sandbox. ([#611](https://github.com/cody-hutson/pmo-platform/issues/611))
- **`validate-install.sh` false-positives repaired.** The A5 check no longer flags legitimate managed-document vocabulary as unresolved tokens, and A9 now checks the `$HOME` install skills path instead of the workspace path. ([#608](https://github.com/cody-hutson/pmo-platform/issues/608), [#609](https://github.com/cody-hutson/pmo-platform/issues/609))
- **`deploy.sh --check` no longer false-DRIFTs sync-map references, and `--warn` exits 0.** ([#610](https://github.com/cody-hutson/pmo-platform/issues/610))
- **Managed-section tamper detection wired into update.** `update.sh` now detects managed-section tampering via a two-hash scheme and writes the documented tamper backup before overwriting, and exits with the documented no-change code (64) when there is nothing to apply. *Why it matters:* a hand-edited managed section is detected and preserved instead of silently clobbered. ([#612](https://github.com/cody-hutson/pmo-platform/issues/612), [#613](https://github.com/cody-hutson/pmo-platform/issues/613))
- **Version-skew notifier repaired and wired.** The `notify-version-skew.sh` hook was non-functional (a repo-root path bug) and not wired into the settings template; it now resolves `.version` from two candidate locations, ships a snapshot via the workspace-setup and update scripts, is wired into the session-start hook, and has a regression test in CI. ([#632](https://github.com/cody-hutson/pmo-platform/issues/632))

### Added

- **Config-first install-path resolution ladder.** `detect_install_path()` resolves via a config-first ladder reading the operator config, with structured terminal output, replacing the session-tiebreaker heuristic; the hardcoded fallback session-path and a literal session identifier that could reference an orphaned session are removed (ADR-013). ([#233](https://github.com/cody-hutson/pmo-platform/issues/233), [#243](https://github.com/cody-hutson/pmo-platform/issues/243))

### Changed

- **Count and `.version` reconciliation.** The deploy skill-list count and the skill-deployment "custom" count are reconciled to one convention; the composition-surface count drift is reconciled and CI install-tests run the full suite rather than a subset; and `.version` is reconciled to the latest-tag (v3.x) scheme with the public-flip tagging convention documented (independent of this version-less release). ([#242](https://github.com/cody-hutson/pmo-platform/issues/242), [#615](https://github.com/cody-hutson/pmo-platform/issues/615), [#614](https://github.com/cody-hutson/pmo-platform/issues/614))
