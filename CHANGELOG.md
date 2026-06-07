# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
adapted for pmo-platform's release-milestone numbering (`vMAJOR.MINOR`).

## [Unreleased]

## [domain-aware-stage5-design] - 2026-06-07

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release) — Stage 5/7 design becomes domain-aware instead of assuming every deliverable is a pmo-platform markdown file. Shipped single-branch via one [release pull request](https://github.com/cody-hutson/pmo-platform/pull/503) (the release-tracking corpus records the PR and merge SHA).

### Added

- **Design now starts with a real "generate options, then narrow" step.** Stage 5 design runs a governed exploration step — generate candidate approaches, eliminate the weak ones with reasons, then score the survivors on a trade-off matrix — before the trade-off matrix that used to be the de-facto starting point. *Why it matters:* the requirement for "at least three alternatives" is now backed by an actual generation step instead of being asserted after a single approach was already chosen. ([#1](https://github.com/cody-hutson/pmo-platform/issues/1))
- **Per-domain best-practice guides (software and governance).** The first two domain guides land, each stating where its practices apply and where they do not, so design can be checked against the right body of practice for the work's domain. *Why it matters:* design guidance is no longer one-size-fits-all — software work is assessed against software practice, governance work against governance practice. ([#1](https://github.com/cody-hutson/pmo-platform/issues/1))
- **A design review criterion for domain best-practice.** The design-review checklist and the Dev-Testing review now assess a design against its target domain's authoritative practice, with an explicit "not assessed" flag when no guide exists yet rather than a silent pass. *Why it matters:* a design that ignores its domain's established practice is caught in review, and a gap in guide coverage is surfaced honestly instead of hidden. ([#346](https://github.com/cody-hutson/pmo-platform/issues/346))

### Changed

- **Impact analysis is chosen to fit the work's domain.** Stage 5 now selects the impact-analysis method per domain — the existing markdown dependency scan stays the default for documentation and governance work, while code, component, and solution domains can use a fan-out method suited to them, with a documented opt-out. *Why it matters:* impact analysis on non-documentation work is no longer forced through a markdown-tree scan that does not fit it. ([#345](https://github.com/cody-hutson/pmo-platform/issues/345))

## [v3.20] - 2026-06-07

Release-pipeline self-checks now fail loud on a broken path instead of passing green, and bundle planning parses real-world issue formats reliably.

### Fixed

- **The release pipeline catches its own broken checks now.** The self-checks that verify the platform's release records (and the broader deploy-check family) exit with an error when a path they depend on does not resolve, instead of silently reporting success. *Why it matters:* a misconfigured or moved file can no longer hide behind a green check. ([#83](https://github.com/cody-hutson/pmo-platform/issues/83), [#85](https://github.com/cody-hutson/pmo-platform/issues/85), [#459](https://github.com/cody-hutson/pmo-platform/issues/459))
- **The release-close tool only uses labels that exist.** A release-pipeline step that files a follow-up issue no longer references a label that was never created in the project, removing a latent failure that would surface the first time the step ran. ([#425](https://github.com/cody-hutson/pmo-platform/issues/425))

### Changed

- **Release planning reads real-world issue formats reliably.** The tool that groups open issues into a release now parses the heterogeneous ways issue bodies are written (varied section headings, missing optional sections) and reaches the ≥90% clean-parse target on the live bundle-ready set. *Why it matters:* fewer items are dropped or mis-grouped at planning time. ([#291](https://github.com/cody-hutson/pmo-platform/issues/291))

## [v1.06] - 2026-06-06

Dev Testing and QA reviews get one shared fix-now/defer/accept disposition framework, with a stricter QA rule and a Stage-5 script-allowlist guard.

[Full notes](release/releases/notes/v1.06_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.06)

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

## [v3.19] - 2026-06-03

### Added

- **Release-corpus completeness gate.** A deploy-check now iterates every release row in the release log and asserts its matching index row, digest entry, and release-notes file all exist, so a release can no longer close with only a log row while the other corpus artifacts are silently missing. Warn-mode initial. *Why it matters:* the documented "produce all four corpus artifacts at close" convention becomes a mechanical guard instead of a reviewer's memory.
- **CI smoke gate for the close-out tooling.** Any change to the release tooling (or the release-log schema) now runs the close-out script's offline self-test and corpus-path resolution probe, plus a precision probe proving the path gate fails on a deliberately-broken path. *Why it matters:* the close-out automation can no longer rot unexercised across a repo migration — a broken release tool fails the pull request that introduces it rather than surfacing at the next release.

### Changed

- **Close-out completeness is outcome-bound.** A release must close with its complete enumerated output set verified on the main branch; the automated close-out is the mandated mechanism, hand-assembling the corpus row-by-row is prohibited, and a documented chore-pull-request fallback covers the cases where the automated preflight legitimately blocks. An operator merge-ahead is now an explicit, supported close path that does not waive the close outputs. *Why it matters:* every recent incomplete close came from a release merged directly and then improvised — binding the outcome and naming the fallback keeps the close both complete and always satisfiable.

### Fixed

- **Close-out script hardening.** The milestone-slug extractor is now schema-aware (it reads the slug column on the current log schema instead of the version column), and the script degrades gracefully under a locked or headless credential store — failing fast with a clear message instead of hanging on a credential prompt with no terminal.
- **Orphan-branch cleanup actually removes branches.** The cleanup tool's apply mode now executes the branch removal it reports (previously a no-op), includes the sibling close-out chore branches in its release-close scope, prunes stale remote-tracking references left after server-side merge deletions, and verifies after applying — reclassifying any survivor as skipped-with-reason rather than silently claiming success.

## [v3.18] - 2026-06-03

### Added

- **Reference-durability authoring standard plus a three-primitive enforcement spine.** A new standard codifies a durability ladder — an unconditional prose rule outranks a self-describing boundary, which in turn outranks a registry entry, a version label, an issue number, and a bare commit hash or URL — alongside a self-containment test for the governance corpus. A write-time harness hook and a deploy-check (both warn-mode initial), backed by a hard CI gate, flag net-new markdown links, version-cutover clauses, and load-bearing bare issue numbers on a pull request's added lines. *Why it matters:* links, version-cutover apparatus, and load-bearing issue numbers all rot on the events the platform routinely performs — a renumber, a repository migration, a history rewrite — so catching their accretion at authoring, deploy, and pull-request time keeps the governance corpus self-contained, with detection precision pinned by a checked-in fixture of labeled cases so the detector cannot silently regress into a no-op.
- **Three pull-request-time repository-integrity gates.** A new CI workflow adds three jobs, each scanning only a pull request's net-new added lines. Depersonalization flags operator or collaborator personal data in the governance domains, exempting both the files where identifying information is legitimately required and the release-tracking corpus. Issue-reference validity requires every issue reference to resolve to a real issue in this repository and to sit in a designated reference block or carry an inline provenance marker. Dead-file references flags markdown link and image targets that do not exist. *Why it matters:* the three highest-value public-readiness integrity checks now run on every pull request, teach the rule in their own failure output, and carry per-line override markers for legitimate exceptions — so repository integrity is enforced mechanically at the point of change rather than resting on reviewer attention.

## [v1.04] - 2026-06-02

### Added

- **Stage 4 currency + crisping gates.** Stage 4 Planning now runs two mandatory named entry gates — Phase A0.5 reconciles each issue's acceptance-criteria context against current platform state, and Phase A0.6 routes weak or stale issue bodies to a crisping pre-gate before plan-design. *Why it matters:* stale references and weak bodies are caught structurally at planning entry instead of depending on a prompt. ([#42](https://github.com/cody-hutson/pmo-platform/issues/42))
- **Release-plan versioning protocol.** The release plan is a single committed file whose revisions are git commits (git history is the version trail — no in-file version number), with an explicit rule for when a mid-flight change requires re-planning versus a minor adjustment. *Why it matters:* plan changes are auditable through git rather than silently overwritten. ([#337](https://github.com/cody-hutson/pmo-platform/issues/337))
- **Analysis-class methodology-design persona variant.** Analysis-class releases (research-artifact deliverables) get a Stage 5 Research-Methodology Design persona variant with its own gate criteria and a Stage 5→6 handoff schema — not a new pipeline stage (ADR-011, Option B). *Why it matters:* research methodology gets first-class design treatment without stretching the architecture-assessment persona or changing the 13-stage pipeline. ([#517](https://github.com/cody-hutson/pmo-platform/issues/517))

## [v1.03] - 2026-06-02

### Added

- **Domain best-practice sourcing-or-flag step.** Planning now either sources authoritative external guidance for the release's domain or attaches a machine-readable provenance marker recording an unsourced gap, a date, and a one-line reason; the marker carries through Solutioning and is verified at Dev Testing. Pipeline-internal releases are exempt and record an explicit exemption marker. *Why it matters:* a release on an unfamiliar domain can no longer proceed silently on assumed knowledge — the gap is filled or visibly recorded.
- **Standing milestone Parallelization Map.** Every milestone now carries a dated map in its description recording which other in-flight milestones it can run alongside, which hard-block it, and which are only loosely coupled, reconfirmed at Bundle and at Planning entry. *Why it matters:* operators stop re-deriving the parallelization answer by hand on every ask; one durable artifact answers it and is kept current.

### Changed

- **Cascading-rebundle protocol.** Moving a milestone's namesake-defining work to a different milestone now triggers re-evaluation of the milestone it left — amend, re-bundle, or defer — instead of leaving a stale namesake with no remaining work. *Why it matters:* milestones stay honest about what they actually contain after their defining work is reassigned.
- **Release-corpus authoring standard.** Governance and release-corpus entries authored from this release forward are link-free and version-reference-free, described by capability rather than by issue or PR citation, so each entry stands on its own when read in isolation.

## [v1.02] - 2026-06-02

### Added

- **Triage cadence.** Stage 2 triage now runs on a defined rhythm integrated with the release cycle, with a separate fast-path for P1 items and a batch cadence for everything else. *Why it matters:* filed Issues get a predictable time-to-first-look instead of an ad-hoc triage pass. ([#347](https://github.com/cody-hutson/pmo-platform/issues/347))
- **Pattern-review rhythm for observations.** Recurring observations feed a scheduled Pattern Review with a draft-then-execute flow (release-planner Mode D draft + release-executor Mode G execute). *Why it matters:* repeated signals turn into action on a rhythm instead of accumulating unreviewed. ([#183](https://github.com/cody-hutson/pmo-platform/issues/183))
- **Management-task triage category.** Triage explicitly recognizes management-tasks (coordination, scheduling, decisions) as a distinct output category. *Why it matters:* coordination items no longer get mis-filed as engineering work. ([#343](https://github.com/cody-hutson/pmo-platform/issues/343))

### Changed

- **Bundle planning validates the roadmap.** Stage 3 bundle composition now validates the bundle against the active roadmap's Now/Next/Later (gate G3-13 + Phase A9.5) before approval. *Why it matters:* a bundle that drifts from current roadmap intent is caught at planning time, before engineering effort is spent. ([#38](https://github.com/cody-hutson/pmo-platform/issues/38))

## [v1.01] - 2026-06-01

### Changed

- **Symmetric intake-tier routing.** Filing an Issue now routes by content shape (observation vs. proposal — both tiers carry positive triggers), not by one-way fallback. Observation tier is no longer a fallback for unsatisfied improvement-tier. (#66)
- **Stage 12 tag command** rewritten to signed-annotated form (`git tag -a -m "..." v<X.Y> "$MERGE_SHA"`) matching repo `tag.gpgsign=true` policy across 7 file locations in the governance corpus. R-A scope expansion adopted at Stage 5 Collective Review. (#101)
- **Stage 4 baseline-pin extended** with mid-pipeline divergence checkpoint G-PR8 — Stage 7/8 entry warn-only + Stage 9 Phase A6.5 HALT-eligible (Tier 2 [SCOPE CHANGE]) when release-plan File Change Matrix files are touched on main during the subject release's window. (#105)

### Added

- **Anti-pattern D** at intake-style-guide § 4 — AC bullets containing temporal phrasing (`30-day rescore`, `60-day adoption`, etc.) route to Notes-tier monitoring commitments instead of AC. Six phrasing-pattern templates + rewrite formula. (#237)
- **AC-Drift Handling Protocol** at release-process.md § Inter-Stage Feedback Protocol — H4 with 6 H5 subsections (Cutover, Planning-side detection, QA-side interpretation, Verdict-selection criteria, Composition, Calibration). 3-verdict closed enum: `N/A-WITH-RATIONALE` / `REINTERPRET-WITH-RATIONALE` / `FLAG-UPSTREAM`. Defense-in-depth with Planning-side AC-currency check at Stage 4 Phase A0. (#274)

