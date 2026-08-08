<!-- derived-surface: source=release/releases/notes/*_RELEASE_NOTES.md (frontmatter `summary:` SEED) · projector=core/deploy/tools/generate_release_index.py · anchor=close-out (a required CLI argument, never sampled by the projector) · repo slug is a required CLI argument, never read from the environment or operator config · contract=release/references/standards/release-corpus-schema.md § Derived-Surface Contract · custody: provenance holds at EMISSION; a historical entry edited afterwards is this file's own content · NEVER REGENERATED WHOLE -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
adapted for pmo-platform's release-milestone numbering (`vMAJOR.MINOR`).

**Date anchor — close-out event (UTC).** The date in each `## [vX.Y] - <date>`
heading dates the **Stage-13 close-out run**, derived from the release note's
frontmatter `date:` and therefore sampled once per close-out run in UTC. It is
**not** the merge date: `release/releases/RELEASE_LOG.md` and
`release/releases/RELEASE_INDEX.md` carry the merge anchor, so a release whose
close-out crossed a UTC midnight reads a day later here — the two anchors
working, not a contradiction. Taxonomy and format rules:
[`core/standards/date-variable-convention.md` § Emission-Time Anchors](core/standards/date-variable-convention.md).
Entries predating this declaration are grandfathered — anchors are declared
forward, never backfilled.

## [Unreleased]

## [v4.16] - 2026-08-08

The delivery-status labels the platform had only declared on paper now exist for real, and the pipeline applies one of them when engineering starts.

[Full notes](release/releases/notes/v4.16_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.16)

## [v4.15] - 2026-08-08

Installing and updating the platform no longer discards the settings you already chose, and a fresh install can run unattended.

[Full notes](release/releases/notes/v4.15_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.15)

## [v4.14] - 2026-08-07

Deploy-time gates now measure what they claim and judge only the release being deployed, not the whole backlog.

[Full notes](release/releases/notes/v4.14_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.14)

## [v4.13] - 2026-08-07

Every self-check the platform advertises now runs automatically, and three checks that were quietly missing things were repaired.

[Full notes](release/releases/notes/v4.13_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.13)

## [v4.12] - 2026-08-05

Published release pages now match the notes they came from, and every release records its own delivery rate and learnings.

[Full notes](release/releases/notes/v4.12_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.12)

## [v4.11] - 2026-08-05

Every decision record now meets one standard, the list of them is generated rather than typed, and two changes can add records at once.

[Full notes](release/releases/notes/v4.11_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.11)

## [v4.10] - 2026-08-05

Overlapping skill triggers are separated and held apart by a standing check, and skills stop asserting things about themselves that are no longer true.

[Full notes](release/releases/notes/v4.10_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.10)

## [v4.09] - 2026-08-05

Four agent-behavior disciplines become checkable rules, and a checkpoint index makes an already-held rule fire at the moment it is needed.

[Full notes](release/releases/notes/v4.09_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.09)

## [v4.08] - 2026-08-05

Release records, telemetry and planning now wait for the one moment a version is claimed — and the cycle-time measurement finally produces a number.

[Full notes](release/releases/notes/v4.08_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.08)

## [v4.07] - 2026-08-04

A release bundle closes to new work once planning starts, and four bundling checks that silently did nothing now actually run.

[Full notes](release/releases/notes/v4.07_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.07)

## [v4.06] - 2026-08-03

The release history stops being four hand-kept copies of one fact, and the file that holds it is 81% smaller without losing a byte.

[Full notes](release/releases/notes/v4.06_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.06)

## [v4.05] - 2026-08-02

Claims the documentation makes about itself — counts, citations, verified results — are now checked by something rather than trusted.

[Full notes](release/releases/notes/v4.05_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.05)

## [v4.04] - 2026-08-01

Six of ten trackers were silently refusing writes and now work; five checks that reported success while proving nothing were made able to fail.

[Full notes](release/releases/notes/v4.04_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.04)

## [v4.03] - 2026-08-01

Every shipped release now appears in all four release records, and the check that confirms it runs instead of silently skipping.

[Full notes](release/releases/notes/v4.03_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.03)

## [v4.02] - 2026-07-31

Release close-out now reports what is true after the work is done, stops skipping delivered work, and refuses to guess when it cannot see.

[Full notes](release/releases/notes/v4.02_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.02)

## [v4.01] - 2026-07-30

The end-of-session learning retro can now actually run, and the decision health-check has a settled home.

[Full notes](release/releases/notes/v4.01_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.01)

## [v4.0] - 2026-07-29

You can now see where agent token spend goes, get an estimate for planned work when there is enough history to support one, and measure estimates against what actually happened.

[Full notes](release/releases/notes/v4.0_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v4.0)

## [v3.100] - 2026-07-29

The release pipeline can now record the decisions it makes, including the automatic ones, and trace each record back to the release it came from.

[Full notes](release/releases/notes/v3.100_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.100)

## [v3.99] - 2026-07-29

Release runs now state how reversible each decision is, brief you before every prompt, and open every turn with where they stand.

[Full notes](release/releases/notes/v3.99_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.99)

## [v3.98] - 2026-07-28

Milestone readiness checks now catch work another epic already owns and problems that do not hold up, and render the result as a map.

[Full notes](release/releases/notes/v3.98_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.98)

## [v3.97] - 2026-07-27

Portability becomes the platform's seventh first-class engineering value, giving work that connects to outside systems a named standard to be reviewed against.

[Full notes](release/releases/notes/v3.97_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.97)

## [v3.96] - 2026-07-26

A new finops-usage-extractor skill measures agent token spend from local session data and attributes it to the owning work item.

[Full notes](release/releases/notes/v3.96_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.96)

## [v3.95] - 2026-07-26

Operators can now set runtime posture — the Stage-2 backlog-decision surface, security-hook activation, and spoke model/effort — through canonical config that survives updates, and the config keys v2.00's features already referenced now exist with documented defaults.

[Full notes](release/releases/notes/v3.95_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.95)

## [v3.94] - 2026-07-26

Four new checks harden how the pipeline accepts, builds, and extends work — and stop trusting the stated author of an issue body.

[Full notes](release/releases/notes/v3.94_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.94)

## [v3.93] - 2026-07-25

Release version numbers now bind at merge-claim time, not at planning — a release keeps its capability-slug identity until it ships, ending the early-bound-number collisions and re-version churn that hit concurrent releases.

[Full notes](release/releases/notes/v3.93_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.93)

## [v3.92] - 2026-07-25

A new architecture-conformance audit checks delivered work against the platform's own architecture, alongside a cross-chain index that maps every management chain to its governing model, flow, and gate, and a consolidated actor-model baseline.

[Full notes](release/releases/notes/v3.92_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.92)

## [v3.91] - 2026-07-25

Windows can now install and update the platform without a bash prerequisite (dry-run today), a new doctor command diagnoses install problems, and work-tracking supports multiple destinations with a guardrail that keeps private content out of public trackers.

[Full notes](release/releases/notes/v3.91_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.91)

## [v3.90] - 2026-07-25

The release-impact analysis tool now returns accurate, path-true consumer counts and flags scripts that hard-code a moved directory's path.

[Full notes](release/releases/notes/v3.90_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.90)

## [v3.89] - 2026-07-25

Two ready-to-use planning templates (Change Impact Matrix, Training Plan) for go-lives and upgrades, plus a RAID-log template header fix.

[Full notes](release/releases/notes/v3.89_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.89)

## [v3.88] - 2026-07-25

Six deploy/tooling/test defect fixes: a false --check drift alarm, skill-count roster drift, a flaky test, doc naming, an XSS-sink refactor, and an honest CLAUDE.md maintenance contract.

[Full notes](release/releases/notes/v3.88_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.88)

## [v3.87] - 2026-07-24

Design diagrams and process flows embedded in the docs are now labeled with a findable marker, so the full set can be listed and checked for gaps.

[Full notes](release/releases/notes/v3.87_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.87)

## [v3.86] - 2026-07-24

Trackers and status roll-ups now match your project's methodology, and stale analysis artifacts are detected instead of assumed.

[Full notes](release/releases/notes/v3.86_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.86)

## [v3.85] - 2026-07-24

Release close-out now verifies the published notes page, rebuilds changed skill packages, and requires a sample for format changes.

[Full notes](release/releases/notes/v3.85_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.85)

## [v3.84] - 2026-07-24

Concurrent releases no longer collide when updating shared release records, and a release without a version number is now a first-class option.

[Full notes](release/releases/notes/v3.84_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.84)

## [v3.83] - 2026-07-22

Adds internal measurement of release close-out quality and ships a session-learning sensor that is present but not yet switched on.

[Full notes](release/releases/notes/v3.83_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.83)

## [v3.82] - 2026-07-22

Exec briefs state a concrete consequence, status updates cite the entries behind them, and escalations read the stakeholder register.

[Full notes](release/releases/notes/v3.82_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.82)

## [v3.81] - 2026-07-22

Releases named by theme instead of a version number now leave a complete record, and every tool judges a version number by the same rule.

[Full notes](release/releases/notes/v3.81_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.81)

## [v3.80] - 2026-07-22

Hardens the release close-out machinery so theme-named releases finish cleanly and more close-out defects are caught in CI.

[Full notes](release/releases/notes/v3.80_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.80)

## [v3.79] - 2026-07-17

Both doc-link checkers now follow one rule and give the same verdict, and the deploy tooling keeps one copy of its logic instead of two.

[Full notes](release/releases/notes/v3.79_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.79)

## [v3.78] - 2026-07-17

The portfolio view is now assembled from each project's published rollup, with freshness and risk checks so Green cannot mask a failing project.

[Full notes](release/releases/notes/v3.78_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.78)

## [v3.77] - 2026-07-17

On-demand `health-check` rollups, a semantic skill-routing conflict audit, and a clarified SKILL.md sizing rule that stops compliant multi-mode skills reading as oversized.

[Full notes](release/releases/notes/v3.77_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.77)

## [v3.76] - 2026-07-17

The platform knowledge base is self-orienting: every `core/` reference doc carries a standard frontmatter header (enforced corpus-wide), the self-audit checklist + a duplicated threshold set point at real locations, `[PROJECT_KEY]` is classified example-data, and the product vision + install model (ADR-083) are codified.

[Full notes](release/releases/notes/v3.76_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.76)

## [v3.75] - 2026-07-17

Findings become a first-class data-model entity with one accountable owner, and a new `deploy.sh` check guards against skill-output ownership collisions.

[Full notes](release/releases/notes/v3.75_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.75)

## [v3.74] - 2026-07-12

Automated regression checks now lock in two recent build-security fixes (a fail-open safety hook and the eval-viewer XSS hole), and Security becomes a first-class value in the platform's engineering charter.

[Full notes](release/releases/notes/v3.74_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.74)

## [v3.73.1] - 2026-07-12

Hotfix so `update.sh` refreshes deployed security hooks — hook and helper fixes (like the v3.73 hardening) now reach workspaces you already installed.

[Full notes](release/releases/notes/v3.73.1_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.73.1)

## [v3.73] - 2026-07-12

Security patch fixing a hook fail-open and three eval-review-tool issues (out-of-workspace file read, secret embedding, unauthenticated write).

[Full notes](release/releases/notes/v3.73_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.73)

## [v3.71] - 2026-07-12

New projects use one simpler five-folder set and a single inbox that auto-files dropped documents; existing projects keep working.

[Full notes](release/releases/notes/v3.71_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.71)

## [v3.70] - 2026-07-12

Internal release-pipeline hardening — a freshness gate re-checks bundled work against live main before building, and agent write-access is constrained. Day-to-day use is unchanged.

[Full notes](release/releases/notes/v3.70_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.70)

## [v3.69.1] - 2026-07-11

Security patch: the PreToolUse hook perimeter no longer fails open when `jq` cannot be resolved, stored XSS is closed in the eval-review tool, and the shared hook helper now deploys with the hooks that need it.

### Security

- **Hooks fail closed when a dependency is missing.** The PreToolUse security hooks permitted the action instead of blocking it when `jq` was unresolvable under the pinned PATH — silently disabling the perimeter on documented Homebrew installs. All twelve hooks now resolve `jq` through a shared absolute-path helper and fail closed in enforce mode. A second fail-open (`..` traversal permitted when `python3` was unavailable) was closed in the same pass. ([GHSA-9cjm-v22x-4x33](https://github.com/cody-hutson/pmo-platform/security/advisories/GHSA-9cjm-v22x-4x33))
- **Stored XSS closed in the eval-review tool.** Attacker-influenced eval output reached HTML render sinks unescaped; each sink now escapes at the point of render, with transport escaping and spreadsheet-hyperlink sanitization behind it. ([GHSA-rw36-5pf9-w2vc](https://github.com/cody-hutson/pmo-platform/security/advisories/GHSA-rw36-5pf9-w2vc))

### Fixed

- **The hook hardening now reaches installed workspaces.** The shared helper the hardened hooks depend on was not copied into the deployed hook directory, so the fix would have shipped without taking effect on any install. ([pull request 3384](https://github.com/cody-hutson/pmo-platform/pull/3384))

[Full notes](release/releases/notes/v3.69.1_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.69.1)

## [v3.69] - 2026-07-11

Routine maintenance clearing accumulated deploy-check drift — stale skill packages rebuilt, a governance file deduplicated, validation back to green.

[Full notes](release/releases/notes/v3.69_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.69)

## [v3.68] - 2026-07-10

Release quality checks now run as automated evals at the dev-test and acceptance stages, escalating to you only on failure.

[Full notes](release/releases/notes/v3.68_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.68)

## [v3.67] - 2026-07-10

Intake now adapts to your project's methodology — file Epics and Stories directly with the right type applied, and split methodology per space.

- Added Epic and Story intake templates that stamp the correct work-item type at submission, and wired intake-desk to resolve the configured methodology and render its matching work breakdown and item kinds.
- Added optional per-space `operational_methodology` / `release_methodology` fields, a determinate type-to-template routing rule, and the cross-cutting control-field mechanism in the work-item type schema (ADR-077) — all additive and backward-compatible.

[Full notes](release/releases/notes/v3.67_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.67)

## [v3.66] - 2026-07-09

Engineers now start architecture decisions, runbooks, design docs, RFCs, PRDs, postmortems, and test plans from canonical templates instead of a blank page, and the document catalog that lists them has no remaining gaps.

- Added seven software-domain document templates under `operations/templates/` — ADR, Runbook, Design doc (FDD/TDD/HLD/LLD variants), RFC, PRD, Postmortem, Test plan — each anchored to its recognized industry standard and carrying a 15-field provenance header at `review_status: DRAFT`.
- Completed the template catalog in `template-taxonomy.md`: flipped the seven `(none — gap)` entries to their new template files and added a ninth §6 canon-table row for the Test-plan family, with the table's counts and reconciliation prose swept to match.

## [v3.65.1] - 2026-07-04

The release pipeline now ignores issue and PR comments from accounts outside the trusted set, so a stranger's comment can't be read as pipeline instructions.

[Full notes](release/releases/notes/v3.65.1_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.65.1)

## [v3.65] - 2026-07-04

The release pipeline now exercises a release's deliverables — running verifications as acceptance evidence — instead of only reading their source.

[Full notes](release/releases/notes/v3.65_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.65)

## [v3.64] - 2026-07-03

QA can now grade a release against the acceptance criteria written on its GitHub issues — scoring each criterion and rolling it up into one acceptance verdict — and the skill auditor gained a check that catches a skill quietly losing its ask-the-user fallback.

[Full notes](release/releases/notes/v3.64_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.64)

## [v3.63] - 2026-07-03

The release pipeline now uses GitHub's own PR-review surfaces (draft→ready lifecycle, review comments as a feedback channel, review-decision state as an advisory signal), and the release-manager skills are back in sync with the pipeline they drive.

[Full notes](release/releases/notes/v3.63_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.63)

## [v3.62] - 2026-07-03

Recording an architecture decision is now low-friction: a canonical guide, a helper that scaffolds the record for you, and a complete decision index.

[Full notes](release/releases/notes/v3.62_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.62)

## [v3.61] - 2026-07-03

Ships the tooling to classify project documents and build a queryable index; the live-document backfill is deferred to a follow-up.

[Full notes](release/releases/notes/v3.61_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.61)

## [v3.60] - 2026-07-03

### Added
- **Methodology packs.** A delivery methodology (Scrum, Kanban, or your own) is now a swappable `core/packs/` manifest — copy, edit, or add an archetype as a thin delta. *Why it matters:* changing or adding a delivery method is a config edit, not a platform code change. ([#1968](https://github.com/cody-hutson/pmo-platform/issues/1968))
- **Methodology-neutral label grammar.** Universal label rules live in one place; each pack contributes its own labels bound to its kinds. *Why it matters:* a methodology's labels can't drift from the platform's shared rules. ([#1970](https://github.com/cody-hutson/pmo-platform/issues/1970))

Foundation release — the packs aren't read by the skills yet ([#2021](https://github.com/cody-hutson/pmo-platform/issues/2021)).

[Full notes](release/releases/notes/v3.60_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.60)

## [v3.59] - 2026-07-03

Docs, backlog, and release-plan folders now follow one structural vocabulary, with a written git-tracking policy.

[Full notes](release/releases/notes/v3.59_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.59)

## [v3.58] - 2026-07-02

A parameterized System-Specialist template stands up a principal-level specialist for any specific system (WMS/ERP/CRM) from one reusable learn-a-system method.

[Full notes](release/releases/notes/v3.58_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.58)

## [v3.57] - 2026-07-02

Impact analysis now follows the code import graph for software changes, and git-native releases no longer dead-end at the dry-run halt.

[Full notes](release/releases/notes/v3.57_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.57)

## [v3.56] - 2026-07-02

Stage 3 Bundling becomes a self-triggering composer with automated milestone-position derivation and a first-class version-less release-identity mode.

[Full notes](release/releases/notes/v3.56_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.56)

## [v3.53] - 2026-07-02

ADRs get a canonical frontmatter schema doc; the durability lint stops flagging hex colors; the operator name is permitted in ADR deciders.

[Full notes](release/releases/notes/v3.53_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.53)

## [v3.52] - 2026-07-02

The eval framework is now complete — the refiner scripts have automated test coverage, the stage-gate eval sets are runnable, and QA can catch contradictions across a chain of dependent work before final review.

[Full notes](release/releases/notes/v3.52_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.52)

## [v3.51] - 2026-07-02

RAID staleness escalation and the tier-2 support skill now cite their canonical source docs instead of a divergent threshold and a missing reference.

[Full notes](release/releases/notes/v3.51_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.51)

## [v3.50] - 2026-07-02

The release pipeline can now evaluate every stage transition from its own written gate specs — completing the stage-gate criteria surface so a run needs no out-of-spec operator knowledge.

[Full notes](release/releases/notes/v3.50_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.50)

## [v3.49] - 2026-07-02

The file router now governs every direction a file can move — inbound, staging, promotion, and cross-project — instead of only inbound arrivals; intake checks for an existing owner before creating a duplicate container, and can auto-log low-touch items on its own when you've raised your automation level.

[Full notes](release/releases/notes/v3.49_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.49)

## [v3.48] - 2026-07-02

The design-before-slicing gate now follows your declared delivery method (design-first for Scrum-style, phase-gate for Waterfall, no sprint-slice gate for Kanban) via a new advisory criterion G3-18; an agent will no longer make large destructive changes off a rough note without first checking the source of record and confirming with you; and project-health colour bands get a single defined home instead of being restated in several places. Closes the last three items of two knowledge-corpus cleanup epics.

[Full notes](release/releases/notes/v3.48_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.48)

## [v3.47] - 2026-07-02

The PMO's operational data — trackers, corrections, session focus, and stakeholder communications — becomes agent-native and self-maintaining: one source per artifact, stakeholder views rendered from it, and comms that escalate themselves when they go unanswered.

[Full notes](release/releases/notes/v3.47_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.47)

## [v3.45] - 2026-07-01

The release pipeline's own reference docs now spell out what each stage is for, and the Stage-9 mid-pipeline divergence check is listed in the gate registry it was already running under.

[Full notes](release/releases/notes/v3.45_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.45)

## [v3.44] - 2026-07-01

Stage-2 triage of the improvement backlog now runs as a skill: one command enriches every proposed issue and returns a single triage summary, so the operator renders one verdict per issue instead of approving each step by hand.

[Full notes](release/releases/notes/v3.44_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.44)

## [v3.43] - 2026-07-01

Five spoke-execution safety properties are now enforced by construction, so a pipeline spoke can no longer drift from the issue it was launched to work on, wander to the wrong checkout, run without a signing key, push unsafely under parallel work, or run outside the security-hook net. These are guardrails on the platform's own release automation; they do not change any project-facing workflow.

### Added
- A spoke-entry substrate-drift check that compares an issue's body claims against live state and emits a structured drift report, so a spoke building from a stale issue body is caught up front instead of silently producing stale work.
- A signing-key pre-flight (`ssh-add -l`) before the platform spawns any commit-producing automation, so it no longer starts work that would fail at the commit step when no key is loaded.
- A decision record (ADR-062) establishing that when a canonical specification and an issue body disagree, the specification wins and the issue body stays as historical record.

### Changed
- The platform's automation-safety hook now recognizes the correct project-repository worktree path, closing a latent gap where it could have blocked legitimate edits once the stricter enforcement mode is switched on.
- The rules that govern how automated spokes run now forbid them from changing directory into, or writing to, the operator's primary checkout, and add a session-start guard against non-code sessions accidentally creating a work branch on the platform repository.

[Full notes](release/releases/notes/v3.43_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.43)

## [v3.42] - 2026-07-01

The branch-cleanup script now actually reaps squash-merged release and chore branches, reports one row per branch, and deletes merged branches without --force — instead of finding nothing on this squash-merging repo.

[Full notes](release/releases/notes/v3.42_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.42)

## [v3.41] - 2026-07-01

Two new skill-measurement auditors ship, and the whole skill catalog gets a structural-hygiene pass so every skill follows the same section and heading conventions. Nothing changes in the day-to-day workflow — the measurement skills are opt-in and the hygiene work is a consistency cleanup.

### Added
- A context-budget auditor skill that measures how many tokens the loaded platform components (skills, rules, schemas) consume across the context window, so you can see which components are heaviest.
- A skill-compliance auditor skill that measures how accurately skills trigger — how often the right skill fires and how often the wrong one does — turning trigger accuracy into a number you can track.

### Changed
- Every skill now uses the same conventions for its safety-rules section and its mode headings, so skills read and behave more predictably and the catalog can be checked for conformance in one pass.

The two auditors are measurement tools you invoke deliberately; they report numbers and do not change any skill's behavior. The compliance auditor's deeper cross-skill routing-conflict scan ships as a specification this release, with the implementing code tracked as a follow-up.

[Full notes](release/releases/notes/v3.41_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.41)

## [v3.40] - 2026-07-01

Four stale documentation references are drained from the internal reference corpus — places where the written guidance had fallen out of step with how the platform works. Nothing changes in how anyone uses the platform; every change is a wording or consistency correction, and all existing guards and historical records are preserved.

### Fixed
- The doc-link maintenance protocol (§8) now names the shared warn-log it actually writes to, instead of a drifted log surface.
- The genuine capital-P `Projects/` prose references in both OPERATIONS files are lowercased to the canonical `projects/` form; a changelog line naming the historical casing is left intact as an accurate record.
- The last live "log to IMPROVEMENTS.md / IMP-###" Self-Update-Protocol instruction in the routing rules is drained and routed to the current GitHub-Issues intake.
- The project-path placeholder is unified to the canonical `projects/[Project]/` form across the schema docs and the `project-initiator` skill.

Documentation-only drainage — no behavior, schema, or runtime-check change. The migrated `project-initiator` skill's compiled package was rebuilt so the shipped artifact matches its updated text.

[Full notes](release/releases/notes/v3.40_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.40)

## [v3.38] - 2026-07-01

The release pipeline's own rules get three small, additive precision fixes across the planning, design, and engineering stages — sharpening release-identity and frozen-spec handling so problems are caught earlier instead of surfacing late at deploy. Nothing changes in how anyone uses the platform; all three are wording and checklist additions to the internal release-pipeline reference corpus.

### Added
- Stage-4 placement forward-check (Phase A0.7 / G-PL3) in the planning reference plus a governance summary in the release-process reference — a pre-planning check for directory-crossing renames and in-scope deletions on the mainline since the release branch's base, closing the "release cut before a structural reorg → new-file placement collides at deploy" pattern.
- Stage-6 commit-group traceability note (documented simplification — advisory, not enforced) after Phase B1 in the engineering reference, plus an enforcement-posture sentence in the sub-task-methodology standard.
- Stage-5 frozen-spec prose-vs-artifact precision rule as a required-when-triggered block in the solutioning-output-template's Blast Radius section (with a DEFERRED escape), plus a routing pointer in the Stage-5 solutioning reference.

### Changed
- A stale target-path in the milestone description (`templates/` → the real `standards/` home) was corrected into the release plan's change matrix at Stage 4.

`novel`-class; three file-disjoint cards on one branch / one merge. Re-versioned forward v3.37 → v3.38 at the Stage-12 pre-merge freeness check (a concurrent sibling release claimed v3.37 first). Additive — CHEAP / `git revert -m 1`; no skill or `.skill` package touched.

[Full notes](release/releases/notes/v3.38_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.38)

## [v3.37] - 2026-06-30

Shared project facts now live in one place, and `PROJECT.md` links to them instead of repeating them. A new shared `projects/_pmo/` area holds one consistent page per entity — people, systems, vendors, workstreams, decisions, and cross-project dependencies — and `PROJECT.md` becomes a thin composed wiki-link index that links out to those pages rather than restating the same facts in every project. Plans (communications, training, hypercare, cutover, change-management) become typed sub-entities with relationship typing. Existing projects are not moved by this release; migrating a live project's overview to the linked-index format is a separate, deferred, per-project step.

### Added
- Shared `projects/_pmo/{people,systems,vendors,workstreams,decisions,dependencies}/` layout with six entity-page templates (Person / System / Vendor / Workstream / Decision / cross-project Dependency & Conflict), aligned to ADR-040 `person_id` + people-roster.
- `project-initiator` Mode A `_pmo/` bootstrap step and Step-3 composed-index template-ref swap.
- Composed-index PROJECT.md template (≤50-line thin wiki-link index) plus a 4-step live-migration protocol with a backwards-compatibility consumer table.

### Changed
- Plans modeled as typed sub-entities (comms / training / hypercare / cutover / change-mgmt) with relationship typing; the deferred `plan_type` G5 enum membership resolved and `plan_subtype` dropped.

`novel`-class; three stories on one branch / one merge. AC-5 live-project migration DEFERRED (capability shipped; gated POC migration is a follow-up). No re-version. Additive — CHEAP / `git revert -m 1`.

[Full notes](release/releases/notes/v3.37_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.37)

## [v3.36] - 2026-07-01

The four process-domain specialist skills — Scrum Master, Release Train Engineer, Business Analyst, and Product Owner — now ground their work in a shared process best-practice guide (`core/standards/domain-best-practices/process.md`) via a compose-by-reference `## Reference docs` pointer (ADR-019; no content absorption). The first three single-anchor to the process guide; the Product Owner dual-anchors to BOTH the process and governance guides, mirroring the dual-anchor Technical Program Manager. This completes the anchoring sequence after v3.30 (software) and v3.33 (governance). The release also adds a net-new support-domain best-practice guide (`core/standards/domain-best-practices/support.md`) covering ITIL 4, tiered incident and escalation practice, and SRE, registered in the framework catalog; and records the change-domain decision to keep its best-practice content self-bundled with the change-management skill — no shared guide, the OCM lead reaching the suite transitively via composition — captured in ADR-057 (`Proposed`) with a reversal trigger and a build-philosophy coverage-matrix row. `routine`-class; six cards on one branch / one merge; no re-version. Additive — CHEAP / `git revert -m 1`.

[Full notes](release/releases/notes/v3.36_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.36)

## [v3.35] - 2026-06-30

Record handling, file/folder naming, and `08-Generated/` cleanup are now governed. A new records-management policy (`core/governance/RECORDS_POLICY.md`) defines ISO 15489-1 retention, four-class classification, disposition, and authenticity; a new artifact-naming standard (`core/standards/artifact-naming-standard.md`) gives PM artifacts and project folders one POSIX-safe naming convention with a controlled type vocabulary, explicit folder rules, and a validation regex, wired into the seven emitting skills plus a `pmo-qa-auditor` check; a new `generated-cleanup` skill runs `08-Generated/` cleanup under an unconditional approval gate, grouping candidates by lifecycle state and archiving to `_archived/`; and `project-initiator` now validates project folder names at creation, rejecting `_`-prefixed, special-character, and non-human-readable names against the new standard. `novel`-class; four cards on one branch / one merge. Re-versioned forward v3.34 → v3.35 at the Stage-12 atomic claim (a concurrent telemetry release claimed v3.34 first; branch name retained). Additive — CHEAP / `git revert -m 1`.

[Full notes](release/releases/notes/v3.35_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.35)

## [v3.34] - 2026-06-30

The release pipeline now measures itself — DORA-4 delivery metrics and Close-class observability, computed per release from tracked schemas.

[Full notes](release/releases/notes/v3.34_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.34)

## [v3.33] - 2026-06-30

The six governance-domain specialist skills (project manager, program manager, program coordinator, portfolio manager, knowledge manager, release planner) now cite one shared governance best-practice guide (PMBOK 7th, PRINCE2, SECI, Diátaxis) as their design-time anchor instead of asserting practices ad-hoc — via compose-by-reference pointers, with no content copied into the skills. This is the governance-domain sequel to v3.30's software-domain anchoring; two of the three domain guides are now skill-wired, with only the process guide pending. Additive reference wiring; no behavior, command, or workflow changes.

[Full notes](release/releases/notes/v3.33_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.33)

## [v3.32] - 2026-06-30

The release hub now conforms to the platform autonomy model: it stops re-asking the operator to approve actions it is already authorized to take, and it reads the full-phase-scope rule from the stage specs so a directed phase runs to its boundary.

[Full notes](release/releases/notes/v3.32_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.32)

## [v3.30] - 2026-06-30

The five software-domain specialist skills (architect, principal engineer, software engineer, DevOps/SRE, technical program manager) now cite one shared software best-practice guide as their design-time anchor instead of asserting practices ad-hoc — via compose-by-reference pointers, with no content copied into the skills. The build-philosophy coverage map was corrected so it no longer claims skill-grounding that didn't exist (the software row is marked wired; governance and process remain pending their sibling releases). Additive reference wiring; no behavior, command, or workflow changes.

[Full notes](release/releases/notes/v3.30_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.30)

## [v3.27] - 2026-06-30

Platform-reference docs now have a single, written frontmatter standard. It says what YAML metadata each kind of doc (standard, schema, spec, discipline, rule, …) must carry — title, purpose, type, status, reversibility, plus a couple of fields that depend on the doc's class. About 140 framework reference docs that had no frontmatter were backfilled to match, and a new CI check enforces the standard on the governance-class docs (Tier A) and warns everywhere else, so the corpus stays consistent going forward.

[Full notes](release/releases/notes/v3.27_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.27)

## [v3.26] - 2026-06-29

Three new PR-time guardrails catch governance drift before it lands — a governance-file-map check, a Projects/ casing check, and a platform-convention linter — plus hardening of the existing cross-reference checks. All three ship in warn-mode first, so nothing breaks while they settle in.

[Full notes](release/releases/notes/v3.26_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.26)

## [v3.24] - 2026-06-30

A new `release-hub` skill: the whole-release control plane. Point it at a milestone and it drives that milestone through the release pipeline by composing the per-stage skills — it owns the sequencing and the readiness-gating between stages, but never does the stage work itself. Two modes: a Milestone Readiness pre-flight that gives one GO / NO-GO on whether a bundled milestone is ready to start (with a per-finding disposition list), and an Orchestrate Release mode that runs the full hub-and-spoke release end to end, stopping for you only at the named pipeline checkpoints. Additive net-new skill that composes existing stage skills and adds no new autonomous mutation surface; no change to any existing skill, schema, or stored artifact. novel class.

### Added

- **`release-hub` skill — whole-release orchestrator.** A new skill takes a milestone and drives it through the release pipeline by composing the per-stage skills, owning the sequencing and the readiness-gating while delegating the stage work to the stage skills. *Why it matters:* a release run is coordinated end to end from one place, so the stages run in the right order and the operator is gated only at the real decision points instead of having to hand-drive every stage. ([#2212](https://github.com/cody-hutson/pmo-platform/issues/2212))
- **Milestone Readiness pre-flight (Mode R).** Before a release run is committed, the skill composes triage/duplicate, staleness/architecture, dependency, and bundle-coherence checks into a single GO / NO-GO verdict with a per-finding disposition. *Why it matters:* a milestone that is not actually ready — stale tickets, unresolved dependencies, an incoherent bundle — is caught up front rather than failing partway through the pipeline. ([#2115](https://github.com/cody-hutson/pmo-platform/issues/2115))
- **Orchestrate Release end-to-end (Mode O).** The skill runs the full hub-and-spoke release: it spawns the per-stage spokes in order and gates the operator only at the named checkpoints (plan-review GO/NO-GO and execute). *Why it matters:* the operator approves the plan once and the run proceeds through the stages on that authorization, instead of opening a fresh approval gate at every phase. ([#2212](https://github.com/cody-hutson/pmo-platform/issues/2212))

## [v3.23] - 2026-06-30

A new `health-check` skill: run it on a project to get an evidence-backed answer to "is this project's tracked state still accurate?" It audits one project for drift between the state you track and its canonical sources (Confluence, Jira, Smartsheet, SharePoint, plus your local trackers and PROJECT.md) and returns a categorized punch list — confirmed-current, safe-to-fix, needs-a-decision, could-not-verify, and proposed portfolio-file edits — that is never applied automatically. Seven modes scope the question (whole project, timeline, ownership, comms, a named plan, RAID, or your source inventory). Additive net-new skill plus one decision record (ADR-051); no change to any existing skill, schema, or stored artifact — and because the skill only reads and recommends, running it cannot change project state. novel class.

### Added

- **`health-check` skill — on-demand project drift audit.** A new intent-driven skill audits one project for drift between its tracked state and its canonical sources and emits a fixed five-section punch list (Confirmed / Auto-Actionable / Decisions / Unknowns / Rollup-Diffs); nothing is auto-applied — auto-actionable items stage a tracker-update block for your approval, and portfolio-file edits are diff-only. ([#1125](https://github.com/cody-hutson/pmo-platform/issues/1125))
- **Seven health-check modes.** `full` (whole project), `timeline` (dates/milestones with day-of-week validation), `attribution` (owners), `comms` (communications coverage), `plan <name>` (one named plan), `raid` (RAID-log guardrails), and `sources` (canonical-source inventory with per-source freshness). ([#1126](https://github.com/cody-hutson/pmo-platform/issues/1126))
- **ADR-051 — canonical source set + graceful degradation.** Records the MCP-primary / local-fallback source set and the graceful-degradation contract: an unreachable connector continues the run local-only with a banner, and a finding that could not be cross-validated is never promoted to auto-actionable. ([#1125](https://github.com/cody-hutson/pmo-platform/issues/1125))

[Full notes](release/releases/notes/v3.23_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.23)

## [v3.22] - 2026-06-29

PMBOK artifact coverage plus three additive PROJECT.md frontmatter axes, with no change to any existing project until the new fields are filled in: a project can now declare what kind of deliverable it produces (`deliverable_type`, separate from how it is governed), its team's org structure (`org_structure_type`), and its team roster by reference (`team_roster`, references only — no names stored in the file); and five ready-made PMBOK artifact templates (charter, lessons-learned, change-log, RACI, stakeholder-register) ship with the platform. Additive schema and template additions — no data migration, no stored-content move, no breaking change. cross-cutting class.

### Added

- **Deliverable-type axis on PROJECT.md.** A project can now declare what kind of deliverable it produces (`software`, `governance`, `web`, `data`, `process`, or a custom value), separate from how it is run, so the platform can tailor its readiness checks to the kind of work being delivered instead of applying one generic bar. ([#351](https://github.com/cody-hutson/pmo-platform/issues/351))
- **Org-structure and team-roster fields on PROJECT.md.** Two new optional fields let a project record its organizational shape and its team membership (by reference) in its own frontmatter, turning org shape and team into structured data the platform can read rather than free text in prose. ([#262](https://github.com/cody-hutson/pmo-platform/issues/262))
- **Five PMBOK artifact templates.** Ready-made project charter, lessons-learned, change-log, RACI, and stakeholder-register templates ship with the platform, so standard artifacts generate from a consistent governed starting point. ([#206](https://github.com/cody-hutson/pmo-platform/issues/206))

[Full notes](release/releases/notes/v3.22_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.22)

## [v3.21] - 2026-06-29

Terminology and controlled-vocabulary canonicalization with no user-visible behavior change: the platform's terminology glossary is refreshed for AI-agent comprehension (discoverable frontmatter, the Role term anchored to the Autonomy-Tier framework, and first-class actor terms — Hub, Spoke, Skill, Sub-agent), the tier-disambiguation table is extended to cover Hierarchy Tier, and canonical Initiative/Roadmap definitions are added and reconciled with the live `epic:*` label namespace via a new decision record (ADR-049). Documentation / governance only — no data migration, no stored-content move, no schema or runtime change. novel class. Re-versioned v2.42 → v3.21 at the Stage-12 atomic claim (v3.20 mainline-spine frontier).

### Added

- **First-class actor terms in the glossary.** The terminology glossary now defines Hub, Spoke, Skill, and Sub-agent as first-class terms (plus discoverable frontmatter and the Role term anchored to the Autonomy-Tier framework), so an agent reading the corpus cold can resolve who-acts-at-which-tier from the glossary alone. ([#68](https://github.com/cody-hutson/pmo-platform/issues/68))
- **Canonical Initiative and Roadmap terms.** Initiative (a multi-milestone grouping theme) and Roadmap (an architected path across milestones) are now canonical glossary terms, reconciled with the initiative-roadmap framework and the live `epic:*` label namespace, with a new decision record (ADR-049) capturing the canonical vocabulary and the `initiative:` → `epic:`/`project:` label mapping. ([#432](https://github.com/cody-hutson/pmo-platform/issues/432))

### Changed

- **Tier-disambiguation table extended to cover Hierarchy Tier.** The tier-disambiguation table in the autonomy-tiers spec now covers Hierarchy Tier alongside the other named tier conventions, stating each convention's disposition so the overlapping "tier" terms are resolvable from one table. ([#128](https://github.com/cody-hutson/pmo-platform/issues/128))

[Full notes](release/releases/notes/v3.21_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v3.21)

## [v2.41] - 2026-06-29

Internal governance-hygiene release with no user-visible behavior change: the root-cause-analysis method is wired by citation to every process surface that owns a failure, the release hub's rule-computed version-numbering step stops surfacing as an operator click-gate, and two reference-document accuracy issues are corrected. Documentation / governance / skill-text only — no data migration, no stored-content move, no schema or runtime change. routine class.

### Changed

- **Root-cause-analysis method wired to every failure-owning surface.** The root-cause-analysis method is now bound by citation to the surfaces its own trigger table already named — `ppm-agent`, `pmo-devops-sre`, and the failure-owning pipeline stage(s) — so root-cause work is invoked or handed off consistently rather than only where it was first wired. ([#1883](https://github.com/cody-hutson/pmo-platform/issues/1883))
- **Version-numbering step reframed as a recorded determination.** The release hub's rule-computed version number is now recorded as a determination by default instead of being surfaced as an operator click-gate, escalating to a gate only for a deliberate version-less / forced-collision close-out or a concurrent slot claim. ([#1918](https://github.com/cody-hutson/pmo-platform/issues/1918))

### Fixed

- **Reference-document accuracy.** Corrected an extinct directory path in the practice-efficacy framework, a malformed table cell in the handoff-coordinator spec, and enumerated every PR-time corpus-integrity gate and its override marker in the ADR README. ([#1562](https://github.com/cody-hutson/pmo-platform/issues/1562), [#2218](https://github.com/cody-hutson/pmo-platform/issues/2218))

[Full notes](release/releases/notes/v2.41_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.41)

## [v2.40] - 2026-06-29

Transcript and meeting processing is formalized: the implicit transcript-handling flow is named as one pipeline with explicit automation boundaries — routine tracker updates flow, stakeholder-facing and risk-bearing changes stop for approval, and action items surface for you to dispose instead of being logged on your behalf — while meetings gain a governed lifecycle state and meeting materials are redesigned for a 5-second scan. Formalizes existing flow and adds one tracker field plus scannable meeting materials; no data migration, no stored-content move, no new project-facing primitive. routine class.

### Added
- **Named transcript pipeline with explicit automation tiers.** The transcript flow is named as one pipeline (Entry → Routing → Core-Tracker → PPM → Stakeholder-Review → Action-Triage), and its outputs are sorted into three tiers — auto-write trackers flow without a prompt, stakeholder-facing and RAID changes stop for your approval, and action items are surfaced for you to dispose and never auto-logged. *Why it matters:* routine updates stop nagging you while anything stakeholder-visible or risk-bearing still stops for review, and nothing is committed on your behalf. ([#237](https://github.com/cody-hutson/pmo-platform/issues/237), [#1157](https://github.com/cody-hutson/pmo-platform/issues/1157))
- **Governed lifecycle state on the Open Meetings Tracker.** Meetings now carry a governed lifecycle state (`scheduled → held | cancelled`) with defined transitions, while the tracker keeps its familiar status labels. *Why it matters:* meetings move through stages with a traceable, consistent state instead of an ad-hoc status. ([#243](https://github.com/cody-hutson/pmo-platform/issues/243))

### Changed
- **Meeting materials redesigned for a 5-second scan.** Pre-reads, agendas, invites, and context blocks are rebuilt so you can absorb what a meeting needs from you at a glance — no pre-read points at a raw transcript without an inline summary. *Why it matters:* you get what a meeting requires without opening source files to reconstruct context. ([#1158](https://github.com/cody-hutson/pmo-platform/issues/1158))

[Full notes](release/releases/notes/v2.40_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.40)

## [v2.39] - 2026-06-29

The platform now audits itself on a defined schedule instead of only when someone remembers, and it starts keeping a record of where the agent's advice differed from your decision. Additive throughout — two new audit-cadence protocols, one new optional record type with a read-only look-back, and a small pipeline-reference edit; no data migration, no stored-content move, no change to any project-facing surface. novel class.

### Added

- **The platform's self-audits now run on a defined schedule.** Two kinds of health check — whether the release process still matches established delivery practices, and whether the documentation structure is still sound — each gain a written rule for when to re-run them: specific triggering events plus a 90-day fallback. *Why it matters:* platform health gets re-checked on a dependable rhythm instead of only after drift becomes a visible problem. ([#167](https://github.com/cody-hutson/pmo-platform/issues/167), [#168](https://github.com/cody-hutson/pmo-platform/issues/168))
- **The platform now records where its advice and your decision differed.** At decision points, the platform can log the agent's recommendation next to the choice you actually made and why they differed, and a look-back view summarizes those differences across recent releases. *Why it matters:* recurring gaps between the platform's judgment and yours surface unprompted instead of being lost between sessions. ([#46](https://github.com/cody-hutson/pmo-platform/issues/46))

### Changed

- **All three of the platform's audit types are now discoverable from any one of them.** The two new schedules and the existing feature-vs-toolkit audit now cross-reference each other as one connected set. *Why it matters:* finding one audit's schedule leads you to all of them, so no kind of health checking gets overlooked. ([#167](https://github.com/cody-hutson/pmo-platform/issues/167), [#168](https://github.com/cody-hutson/pmo-platform/issues/168))

[Full notes](release/releases/notes/v2.39_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.39)

## [v2.38] - 2026-06-28

The automated release close-out now finishes a release reliably and deterministically: every close-out record gets written, the published release page is bound to the right code, and stuck or false-pass closes are fixed.

[Full notes](release/releases/notes/v2.38_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.38)

## [v2.37] - 2026-06-28

Published release notes can no longer silently drift from the note we wrote — the release-notes close-out is hardened so the public release page matches the in-repo note and the close-out checks run no matter how a release is finished. Additive throughout: standard / governance / lint / check edits plus one founding decision record; no data migration, no stored-content move, no change to any project-facing surface. routine class.

### Added
- **Scaffold-independent close-completeness check.** A finished release is now verified to have produced its full set of close-out records, independent of how the work was tracked, so an abbreviated checklist can no longer quietly skip a step. *Why it matters:* releases are reported "done" only when they are actually complete. ([#1290](https://github.com/cody-hutson/pmo-platform/issues/1290))
- **More release-note defects caught before publish.** The note check now also catches a release page whose title is missing its version and links that work in the repo but break on the published page. *Why it matters:* you get a correctly-titled page with links that resolve. ([#2120](https://github.com/cody-hutson/pmo-platform/issues/2120))

### Changed
- **The published release page now stays faithful to the source note.** A release page is rebuilt directly from the source note on publish, with an after-the-fact check that the two match. *Why it matters:* a note correction actually reaches the page people read instead of going stale. ([#2085](https://github.com/cody-hutson/pmo-platform/issues/2085))
- **Release notes are checked the same way no matter how a release is finished.** The note quality check now runs on every close path, not only the scripted one. *Why it matters:* a release closed by hand can no longer ship a note that skips the checks. ([#2082](https://github.com/cody-hutson/pmo-platform/issues/2082))

## [v2.36] - 2026-06-28

Triage and bundling now follow written signals instead of being re-figured each release — several judgment calls the release pipeline made fresh on every run (how an approved ticket's structure is treated downstream, how priority is read, when related issues are grouped, how sub-tasks are tracked) are written down as standing rules, and one repeatedly hand-derived step becomes a tracked tool. Additive throughout — spec/governance/schema edits plus one new tool; no data migration, no stored-content move, no behavior change to any project-facing surface. novel class.

### Added

- **The native-dependency mirror is now a tracked tool.** The Stage-2 step that maps native dependency edges, previously re-derived on every run, is promoted to a tracked tool with a fixture test. *Why it matters:* the dependency mirror runs the same way every release instead of being re-figured by hand each time. ([#662](https://github.com/cody-hutson/pmo-platform/issues/662))

### Changed

- **An approved ticket now counts as direction, not a fixed blueprint.** The pipeline states that approving a ticket signs off on the problem and outcome — not the ticket's proposed structure, which a later design step is free to confirm or rework. *Why it matters:* you can approve a good idea without locking in the first guess at how to build it. ([#500](https://github.com/cody-hutson/pmo-platform/issues/500))
- **Priority is read as two separate things, not one blurred score.** Triage separates how urgent something is from how valuable it is, with how many other items depend on it as a third signal — without hardwiring any scoring method. *Why it matters:* urgent-but-low-value and valuable-but-can-wait items are no longer flattened into the same "priority." ([#283](https://github.com/cody-hutson/pmo-platform/issues/283))
- **Related issues get grouped on a written threshold.** There is now a stated rule for when a set of related issues is large or connected enough to be tracked as a group, and which grouping mechanism to use. *Why it matters:* clusters of related work get a tracking home consistently instead of by chance. ([#280](https://github.com/cody-hutson/pmo-platform/issues/280))
- **New-track placement rationale fires per milestone, behind a gate.** The Stage-3 rationale for placing work on a new track now fires per milestone rather than once per major track, with an enforcing gate. *Why it matters:* each milestone's placement decision is justified on its own terms rather than inheriting one blanket rationale. ([#292](https://github.com/cody-hutson/pmo-platform/issues/292))
- **Sub-task breakdown follows a stated threshold.** The choice between formal sub-issues and a lighter in-PR checklist for breaking a work item down now has a defined trigger. *Why it matters:* small items stop being over-tracked and large ones stop being under-tracked. ([#225](https://github.com/cody-hutson/pmo-platform/issues/225))

[Full notes](release/releases/notes/v2.36_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.36)

## [v2.35] - 2026-06-27

Agents that calibrate their own confidence before they act — a written protocol gives an agent a way to decide, at a non-obvious decision point, whether to proceed now, pause to learn, or escalate, based on whether independent cross-checks agree (never on self-reported confidence) and scaled to how costly being wrong would be. The first live consumer is the release pipeline's bundle currency-check. Additive throughout — a new spec, a new ADR, and four edits that wire the gate into existing disciplines and one pipeline stage; no data migration and no stored-content move. routine class.

### Added

- **A confidence gate that decides proceed, pause-to-learn, or escalate.** A new protocol gives an agent a grounded way to decide whether to act on a non-obvious decision: it reads a signal from whether independent cross-checks agree, whether the missing fact can be named, and how weak the supporting evidence is — never from self-reported confidence — and selects the action from a reversibility-by-autonomy matrix instead of one global cutoff. *Why it matters:* the same uncertainty proceeds on a trivially-reversible action but pauses or escalates on a costly one, so agents stop both over-pausing on cheap calls and barreling ahead on expensive ones. ([#2286](https://github.com/cody-hutson/pmo-platform/issues/2286), [#2288](https://github.com/cody-hutson/pmo-platform/issues/2288))
- **A bounded pause-to-learn step that has to actually learn something.** When the gate says pause, the agent runs a short, capped loop that fetches one new piece of outside information, re-checks, and then either proceeds, routes the gap to a spike, or escalates — it cannot loop forever or "pause" without fetching anything. *Why it matters:* a pause becomes a real gap-close with a guaranteed exit, not an open-ended stall dressed up as diligence. ([#2288](https://github.com/cody-hutson/pmo-platform/issues/2288), [#2290](https://github.com/cody-hutson/pmo-platform/issues/2290))
- **The release pipeline's bundle currency-check now runs the gate.** The Stage-4 check that decides whether to leave a bundled release alone, amend it, re-bundle it, or defer it now runs the proceed-vs-pause gate before rendering that call. *Why it matters:* a low-confidence currency call on a costly re-bundle pauses to re-read the canonical state first, rather than committing on weak grounds. ([#2289](https://github.com/cody-hutson/pmo-platform/issues/2289))

[Full notes](release/releases/notes/v2.35_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.35)

## [v2.34] - 2026-06-28

Knowledge and decision confidence — the corpus gains the design-time and capture-time scaffolding that makes knowledge land in the right place and stay current: a written set of evaluative lenses for sizing and routing new work, a scope dimension that records what altitude a learning came from, two more facilitation-technique domains, and a skill that keeps the living roadmap current as issues arrive; a long-standing knowledge-eviction gap is also closed. Additive throughout — new and edited reference docs, a new skill, and one build-check extension; no data migration and no stored-content move. routine class.

### Added

- **A written set of design-time lenses for sizing and routing new work.** A new reference doc names the cross-cutting questions to ask when scoping a piece of work — is it the right skill, the right method, and the right altitude, and is it universal or install-specific — and wires them in as a design check. *Why it matters:* new work gets classified the same way every time instead of relying on recall, so it lands in the right place. ([#1102](https://github.com/cody-hutson/pmo-platform/issues/1102))
- **Learnings now record the scope they came from.** The knowledge model gains an organizational-altitude axis (from a single unit of work up to the whole organization) that sits alongside the existing universality tiers, plus a defined way for lower-scope learnings to roll up to the next scope. *Why it matters:* a captured learning now says at what scope of work it was generated, so related learnings can be aggregated rather than read in isolation. ([#564](https://github.com/cody-hutson/pmo-platform/issues/564))
- **Two more facilitation-technique domains are catalogued.** The facilitation-techniques corpus adds the retrospective and planning domains on top of the existing estimation foundation, surfaced through the same delivery-engine trigger. *Why it matters:* technique surfacing now covers more of the delivery lifecycle, not just estimation. ([#1945](https://github.com/cody-hutson/pmo-platform/issues/1945))
- **A skill that keeps the living roadmap current as issues arrive.** A new roadmap-curator skill classifies new and changed issues against the established initiative set, updates the roadmap, and surfaces drift — with a separate operator-triggered mode for a full re-baseline. *Why it matters:* the roadmap stays sequenced and current as work arrives instead of drifting back into an unsequenced pile. ([#453](https://github.com/cody-hutson/pmo-platform/issues/453))

### Fixed

- **Evicting a codified note no longer leaves dead links or stranded notes behind.** The knowledge-eviction lifecycle now re-points or drops links to an evicted note and reconciles notes against their tracking issue at close, and the build validation reports both gaps. *Why it matters:* retiring a note that has been folded into the corpus no longer leaves links that go nowhere or notes that can never be retired. ([#2214](https://github.com/cody-hutson/pmo-platform/issues/2214))

[Full notes](release/releases/notes/v2.34_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.34)

## [v2.33] - 2026-06-27

Roadmaps get a shipped in-repo home, and "initiative" labels are reframed as a grouping rather than a hierarchy tier. Additive — a new git-ignored `/roadmaps/` folder (ships on install, survives updates), a token-default rewire to it across the SSOT surfaces, and a one-line label-taxonomy reframe; existing roadmaps migrate by copy with no history effect. ADR-046 supersedes-in-part ADR-012 + ADR-017. routine class.

### Added

- **Roadmaps now have a shipped in-repo home.** A `/roadmaps/` folder is present on a fresh clone (folder + README tracked, instances git-ignored) and survives updates (absent from the regeneration manifest). The `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token now defaults to it across the registry + config, and is still repointable. *Why it matters:* operators have a known, plug-and-play place for roadmap instances that updates never overwrite. ([#416](https://github.com/cody-hutson/pmo-platform/issues/416))

### Changed

- **"Initiative" labels read as a grouping, not a hierarchy tier.** `label-taxonomy.md §Initiative Labels` is reframed and now cites the single source of the work-item hierarchy. *Why it matters:* the docs no longer imply a container level the platform doesn't have. ([#1038](https://github.com/cody-hutson/pmo-platform/issues/1038))

[Full notes](release/releases/notes/v2.33_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.33)

## [v2.32] - 2026-06-27

Skill-registry identity and currency — the skill catalog (`registry.md`) now checks itself against the skills actually deployed, so a missing, extra, or dangling catalog entry fails the build instead of drifting unnoticed; and several docs that pointed at a catalog file which never shipped are corrected to point at the real registry. Additive build check plus corrected citations — no data migration and no stored-content move. routine class; four drifted skill packages (build-reviewer, pmo-architect, pmo-skill-editor, pmo-skill-refiner) rebuilt at release-cut.

### Added

- **The skill catalog is now checked against the deployed skills.** The build validation compares every catalog entry against the live skill roster in both directions and confirms each entry points at a skill that exists. *Why it matters:* a forgotten catalog entry now stops the build instead of letting the catalog quietly go out of date. ([#1811](https://github.com/cody-hutson/pmo-platform/issues/1811))
- **A second, gentler check watches each entry's recorded details.** For role-specialist entries, the build also compares the recorded modes and composition against the skill itself and logs any mismatch (reported, not yet blocking). *Why it matters:* the catalog stays trustworthy as a description of each skill, not just a list of names. ([#1658](https://github.com/cody-hutson/pmo-platform/issues/1658))

### Fixed

- **Docs that pointed at a catalog file which never shipped now point at the real registry.** Several reference docs and skills cited a `dependency-graph.md` that was never created; they now cite the live `registry.md`. *Why it matters:* following one of those references used to lead to a dead end. ([#1211](https://github.com/cody-hutson/pmo-platform/issues/1211))

[Full notes](release/releases/notes/v2.32_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.32)

## [v2.31] - 2026-06-27

Knowledge-management discipline — the platform's memory gets one written rulebook saying, for every place it stores a fact, which place is the source of truth and who may change it; and the quality audit starts reporting documentation that has gone stale or is missing. Additive throughout — new and edited documentation plus two reviewed skill edits, no data migration and no stored-content move. novel class; the two edited skills (pmo-qa-auditor, daily-status) have packages rebuilt at release-cut.

### Added

- **The quality audit now reports stale and missing documentation.** The platform health audit gained a knowledge-management scan that produces two new reports — one ranking documentation overdue for review, one listing documentation gaps — alongside its existing findings. *Why it matters:* drifted or absent reference docs surface in the audit for you to triage instead of sitting unnoticed until something breaks. ([#249](https://github.com/cody-hutson/pmo-platform/issues/249))
- **One written rulebook for where each kind of fact lives.** A new reference doc lists every place the platform stores information and, for each one, which place is the source of truth and who may write to it. *Why it matters:* when the same fact could appear in more than one place, agents read it from the one authoritative place, so a stale copy cannot quietly override the real value. ([#1074](https://github.com/cody-hutson/pmo-platform/issues/1074))

### Changed

- **Behavioral corrections now get a scheduled review instead of piling up forever.** Corrections you give are reviewed on the platform's existing pattern-review rhythm — a recurring one becomes a permanent rule, an obsolete one is retired, and the rest stay active. *Why it matters:* the corrections list stays current rather than growing without bound and silently shadowing the platform's own rules. ([#1076](https://github.com/cody-hutson/pmo-platform/issues/1076))

[Full notes](release/releases/notes/v2.31_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.31)

## [v2.30] - 2026-06-26

Stale internal links across the platform's docs and skill files are corrected to their current locations.

[Full notes](release/releases/notes/v2.30_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.30)

## [v2.29] - 2026-06-26

Corpus-drift reconciliation — ten places where a reference or governance doc had drifted from its canonical source (a stale rule count, a divergent list, an old field name, an imprecise term, an incomplete check enumeration, and a duplicate file) are corrected so the docs say what the platform actually does. Documentation and governance accuracy only — no skill behavior, schema, or runtime-check change. routine class; the two text-edited skills (build-reviewer, pmo-skill-editor) have packages rebuilt at release-cut.

### Changed

- **The configuration field for delivery method reads `delivery_approach` everywhere.** The navigation-layer schema's last reference to the old `methodology` field name now matches the canonical `delivery_approach` used in PROJECT.md. *Why it matters:* the field name in the docs matches the field you actually set, with no stale alias to second-guess. ([#857](https://github.com/cody-hutson/pmo-platform/issues/857))
- **The deploy-check reference points at the live check list instead of a frozen copy.** The `skill-deployment.md` Drift Check section stopped listing checks by hand (a list that had fallen behind) and now tells you how to read the current checks from `deploy.sh`. *Why it matters:* the reference can no longer name a different set of checks than the one that actually runs. ([#2095](https://github.com/cody-hutson/pmo-platform/issues/2095))

[Full notes](release/releases/notes/v2.29_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.29)

## [v2.28] - 2026-06-26

Generated-vs-source provenance — when a skill writes a generated artifact, the artifact's frontmatter now records which skill and version produced it and what upstream evidence it drew from, plus a stable identifier, so generated content is traceable to its source and cleanly distinguished from human-authored artifacts. novel class; additive throughout (every field is optional, forward-only no back-fill); the five changed-skill packages rebuilt at release-cut.

### Added

- **Generated artifacts carry their own origin stamp.** A new artifact written by a skill now records the producing skill and its version in its frontmatter. *Why it matters:* you can tell which skill made a file and which version of it without inferring from the filename or folder. ([#205](https://github.com/cody-hutson/pmo-platform/issues/205))
- **Generated artifacts list the evidence behind them.** An artifact now records the upstream inputs it drew from — the transcripts, messages, or files it was built on. *Why it matters:* you can trace a generated file back to its sources to check or re-derive it. ([#205](https://github.com/cody-hutson/pmo-platform/issues/205))
- **Each generated artifact gets a stable identifier.** A generated artifact now carries a filename-independent identifier of its own. *Why it matters:* the file stays referenceable even if it is later renamed or moved. ([#205](https://github.com/cody-hutson/pmo-platform/issues/205))

[Full notes](release/releases/notes/v2.28_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.28)

## [v2.27] - 2026-06-26

Ticket information architecture — how a ticket carries confidence, how its title reads, and how its information is structured all get sharper. One four-level staleness scale replaces five incompatible formats so "how stale, and how deeply" means the same thing everywhere; work-item titles drop the redundant type prefix and become readable from the issue list alone, behind a logged-but-not-blocking floor that leaves legacy issues untouched; and a documented three-layer ticket information model adds a pipeline-Stage column to the backlog view. cross-cutting class; additive throughout; the two changed-skill packages rebuilt at release-cut.

### Added

- **One staleness scale instead of five.** Staleness-confidence is now expressed in one four-level vocabulary — current, cosmetic drift, currency-in-question, or structural rot — that every staleness check maps onto, so it means the same thing everywhere it appears, with a new architecture decision record explaining the choice.
- **A documented model for how tickets carry information.** A new spec defines the three layers a ticket carries — the body as source of truth, comments and sub-issues as the per-stage review trail, and Projects fields, labels, and Milestones as the machine-readable pipeline position — and the backlog triage view gains a Stage column so bundled work no longer collapses into one undifferentiated group.

### Changed

- **"Old" no longer reads as "broken".** Staleness now separates how long something has gone untouched from what kind of staleness it is — age alone never gets labelled as structural rot — so the top band means a real premise-level problem, not just elapsed time.
- **Work-item titles you can read from the list.** New issues drop the `[Category]:` / `[Bug]:` title prefix — type now lives on the label and the title spends its space on what changed — with a floor check that keeps a title from being a bare slug or a single word. The check is logged-but-not-blocking for existing prefixed issues, so nothing fails and no bulk rename is forced.

[Full notes](release/releases/notes/v2.27_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.27)

## [v2.25] - 2026-06-26

Hub-spoke orchestration discipline — the orchestration failure-modes the platform learned by trial-and-error are codified into the bridge reference the hub reads at runtime, so a class of cross-ticket, cascade, and chip-safety failures is caught at authoring time rather than after a failed check or a mis-routed spoke. A paired empirical suite pins the subagent hook-inheritance behavior with a standing regression. Novel class; additive throughout (no skill files changed); two disjoint single-writer spokes.

### Added

- **Cascade-completeness on spoke launch.** When a spoke's spec changes a count, an enumeration, or a threshold, the hub now prompts it to enumerate every stale occurrence of that value — so a number changed in one place no longer leaves matching stale copies elsewhere.
- **A necessity / value-add check on spoke recommendations.** The hub now weighs whether a spoke's recommendation actually adds value before adopting it, rather than rubber-stamping an accurate-but-inert one.
- **Four orchestration disciplines moved from notes into the corpus.** Verbatim chip-source, treating issues (not chat blocks) as the spoke contract, hook-safe git idioms, and concurrent-spoke contention recovery now live in the reference the hub consults, not in scattered operator notes.
- **An empirical hook-inheritance suite.** A continuous-integration regression layer plus an operator probe layer plus a new deploy-check report the real behavior of subagent hook inheritance — with the finding pinned so it cannot silently regress.

### Changed

- **A mid-build cross-ticket scope-detection rule.** When work on one item touches the scope of another mid-build, the hub now detects it and escalates rather than letting the cross-ticket change land silently — anchored by a new architecture decision record.
- **A durable-corpus de-fragile authoring pre-check.** Reference content authored during a build is now checked for fragile constructs before it lands, at both the orchestration bridge and the reference-durability standard.

[Full notes](release/releases/notes/v2.25_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.25)

## [v2.26] - 2026-06-26

People-graph activation — the functional people-graph that shipped structurally in v2.23 is now active on a fresh install: install and update seed the operator-instance people-roster create-once (never-clobber) at three sites behind a new single-resolution accessor; GETTING_STARTED documents the adoption path and the per-tier owner-to-Person reference flow; and a binary-judge eval verifies the four consuming skills resolve read-only from a populated roster. routine class; additive; activation layer only. The filled roster stays out-of-tree and gitignored.

## [v2.23] - 2026-06-26

Functional people-graph — PMO agents now resolve people from one maintained, never-committed people-graph instead of per-project free-text names; the four leadership-owner fields become typed person references; and the filled roster stays out of the repository by construction. Novel class; additive; functional-coordination only — explicitly not an HR or performance system.

### Added

- **A maintained people-graph that agents read from.** Skills that need a person's name, the owner of a project, or who-covers-whom now read from one maintained people-graph — a closed-allow-list roster composed at read time with the existing Person and Resource entities into a capability-and-coverage view that answers who-does-what, who-covers-whom, and coverage-by-capability.
- **A never-committed roster with a de-identified template.** The actual roster lives outside the repository and is protected from accidental commit by out-of-tree placement, a gitignore backstop, and a pre-commit name scan; only a de-identified template ships in the repo, so personal data stays out of the codebase by construction.

### Changed

- **Leadership owners are now typed person references.** The project, portfolio, and program owner fields and the initiative-sponsor field move from free text to a structured reference to a person, with a defined fallback for people outside the roster — so an owner resolves to a real, consistent person instead of an unparseable string.

[Full notes](release/releases/notes/v2.23_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.23)

## [v2.22] - 2026-06-25

Comms-and-facilitation reference substrate — meeting agendas and recaps now follow one canonical format instead of copies spread across skills, a recap points to tracked follow-up records rather than being their only home, and facilitation techniques get a reference library a delivery skill can surface in context. Novel class; additive; QA PASS on all 3 cards, 0 defects.

### Added

- **One canonical meeting-agenda format.** Agenda requests follow a single canonical definition — the six required parts (subject, attendees with rationale, a one-sentence goal, numbered items with owners and time, pre-read, logistics) — authored once and single-sourced out of `comms-writer`, so it cannot drift between skills.
- **One canonical meeting-recap format.** Recaps follow a fixed order — Decisions, Action Items, Notes, Key Roadblocks — with a `[RECAP]` subject line, so the most decision-relevant content is always in the same place.
- **A facilitation-techniques reference library.** A governed library of facilitation techniques ships seeded with its first area, estimation, and a delivery skill can suggest a relevant technique in context.

### Changed

- **Recaps point to follow-ups instead of holding them.** A recap now references discrete, trackable follow-up records rather than being their sole container, so an action item lives as a record that can be followed to closure.

[Full notes](release/releases/notes/v2.22_RELEASE_NOTES.md)

## [declarative-gating-model] - 2026-06-24

Declarative cross-methodology gate conditions — a work-item type-pack gate can now depend on a *related* item's workflow status, or on an *aggregate over a set* of related items (a Kanban WIP limit), instead of only the item's own fields. Version-less (theme-named); research-led; additive (the meta-schema stays v1).

### Added

- **Related-item-status gates.** A gate can depend on the workflow status of a related work item — a child Story can't be groomed to `ready` until its parent Epic is design-approved; a Story can't leave `ready` while a blocking Spike isn't `done`. The condition resolves across the relationship you declare (parent/child, depends-on, blocks).
- **Set-aggregate gates.** A gate can depend on an aggregate over a set of related items — most importantly a Kanban WIP limit ("no more than N items in-progress at once") — making pull/flow limits first-class instead of inexpressible. Mutually-gating loops are detected and refused rather than deadlocking.

[Full notes](release/releases/notes/declarative-gating-model_RELEASE_NOTES.md)

## [v2.20] - 2026-06-23

Field-lifecycle and CMDB automation — the platform's entity fields now have a governed lifecycle (who may write which field, at which stage, driven by agents), the artifact-state model is reconciled onto one canonical lifecycle, and the skill registry becomes the platform's configuration-management catalog with a per-project Artifact Register. A project-tracking integrity sweep adds dormancy and overdue-decision detection with an evidence-backed gate. Cross-cutting; QA ACCEPT (~48/48 acceptance criteria, 0 defects). *(Numbering note: `v2.20` was tagged after `v2.21` — a concurrent release claimed the higher number first and the operator kept `v2.20` for this one; the claim order is non-monotonic by version and self-heals on the next allocation.)*

### Added

- **Agent-driven entity lifecycle automation (G8).** Per-entity state transitions are now agent-driven, with shared and portfolio-scoped lifecycle transition protocols defining the legal moves and a canonical lifecycle-state vocabulary. Skills emit and consume these transitions (ppm-agent, tracker-manager, artifact-generator, and the other active branchers).
- **The G10 field-lifecycle write-permission matrix.** A matrix declares which agent may write which field, for which entity, at which stage — and the Agent Write Permissions table is aligned to it, so the permission picture is single-sourced.
- **The skill registry is now the platform CMDB.** `core/skills/registry.md` is evolved into the single configuration-management catalog: every deployed skill is a configuration item carrying lifecycle-state, dependency, and owner axes (version and roster-existence are cited from the skill files and the deploy script, never duplicated). A new per-project **Artifact Register** template lands alongside it. Recorded in **ADR-038**, which supersedes part 4 of ADR-035 (and preserves its other decisions); the skill-router classifies against a role-Specialist-filtered view so routing stays unambiguous.
- **Project-tracking integrity sweep.** delivery-engine now detects dormant work items (10 business days) and overdue decisions (3–5 business days) and enforces evidence-backed phase-gate completion.

### Changed

- **The artifact-state model is reconciled onto the canonical lifecycle.** What used to be a separate `artifact_state` is reconciled into the canonical `lifecycle_state` + Domain model (with a `promotion_state` carve-out for the staging→promoted axis), and artifact-generator and artifact-lint are migrated onto the reconciled model. The transitional dual-read path is removed. A new `artifact-workflow-protocol.md` documents the workflow.

[Full notes](release/releases/notes/v2.20_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.20)

## [v2.21] - 2026-06-23

Decision-rendering standardization — when the release hub reaches a decision point (a go/no-go, a version choice, a scope-lock) it now loads the relevant specs first, lays out the full option space before asking, and scores each option against the platform's design principles. Cross-cutting; 3 cards; non-breaking. *(Numbering note: `v2.21` was claimed before `v2.20` — the two releases landed close together and the claim order is non-monotonic by version.)*

### Added

- **Decision briefings show the full picture first.** Before a decision prompt appears, the hub reads every spec the decision rests on, prints the complete briefing in chat, and lays out the full option space — including the option your own past preference implies — so no better option surfaces after you have already answered.
- **Design-principle conformance scoring.** A new design-principle register (Scalability, Maintainability, Simplicity, Stability, and the rest) lets the hub mark each option ALIGNED with or in CONFLICT with a named principle; a conflict with a high-stakes principle is flagged for your sign-off rather than quietly accepted.
- **Standing per-decision-type instructions.** You can set directives per decision type (for example, "always offer a 'defer to next release' option and show the rollback path"); these only ever add to what the hub surfaces, never hide an option or dimension.

[Full notes](release/releases/notes/v2.21_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.21)

## [v2.19] - 2026-06-22

Co-management governance cleanup — finishes de-broadcasting the operator-specific naming from the public codebase (a follow-up to v2.18) and single-sources the dual-framing status rule. The legacy co-management compatibility shim is retired, the residual integration field names are genericized to `co_management_*`, and the Dual-Framing Bridge rule now lives in one place (`OPERATIONS.md`) instead of a redundant copy in the workspace director. Dual Agile/Waterfall framing behavior is unchanged. Minor (the shim removal is a back-compat contract change), not a patch.

### Changed

- **The Dual-Framing Bridge rule is single-sourced in `OPERATIONS.md`.** The redundant copy in the workspace director (`CLAUDE.md`) is removed and every reference now points at the one authoritative home — closing the duplicate-source drift that had let the two copies disagree. Re-run `update.sh` to re-render your workspace `CLAUDE.md`; your project settings and personal additions are preserved.
- **The co-management integration field names are genericized** to `co_management_smartsheet_id` / `co_management_sharepoint_folder`, completing the operator-agnostic rename begun in v2.18.

### Removed

- **The legacy co-management compatibility shim is retired.** The pre-v2.18 setting name is no longer read. **Migration:** if a `PROJECT.md` still carries the old key, rename that one line to `dual_framing_enabled` (identical on/off meaning). Projects already on `dual_framing_enabled`, and projects without co-management, need no action.

## [v2.18.1] - 2026-06-22

Operator-instance path decoupling — the operator needle/instance path resolves through one resolver (`CLAUDE_WORKSPACE_ROOT` per ADR-032), with a `.env`-style template + create-once scaffold, persistence across update, and a fail-closed PII guard (warn-mode-initial). Patch off v2.18; non-breaking.

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

## [v2.18] - 2026-06-21

The `Hybrid` methodology is now defined cleanly as a user-configurable combination of two archetypes, decoupled from the co-management arrangement it was previously tied to; dual-framing behavior is unchanged.

### Added

- **Hybrid is now a user-configurable two-archetype combination.** `delivery_approach` accepts a two-element array — `[Scrum, Kanban]`, `[Waterfall, XP]`, any two distinct archetypes — declaring a project that runs both methodologies side by side and reports status in both native framings. The literal `Hybrid` value is retained for backward-compatibility, and a one-line array is now the explicit forward-looking declaration instead of dropping to the heavyweight `Custom` block for what is really a two-archetype selection.

### Changed

- **`Hybrid` is decoupled from co-management.** The `Hybrid` methodology classification no longer names an operator-specific co-management arrangement — the two were conflated, and they are now documented as orthogonal across the schema, governance, and methodology specs. A Hybrid project may run with or without co-management; a non-Hybrid project may enable co-management independently.
- **The legacy co-management field is renamed `dual_framing_enabled`.** The trigger for dual Agile/Waterfall status framing now carries an operator-agnostic name. A live `PROJECT.md` carrying the legacy co-management key is still accepted — a deprecation shim reads it, emits a one-line warning, and treats it as `dual_framing_enabled` — so the rename is non-breaking. The operator-specific token survives only as operator-local configuration.
- **The dual-framing status artifact is renamed the "Dual-Framing Bridge".** The co-managed status artifact and its template, governance clause, and registry entries are renamed operator-agnostically, with role-based audience labels ("PMO view" / "Sponsor view"). The dual-framing output it produces is unchanged.

### Deprecated

- **The legacy co-management frontmatter key.** Renamed to `dual_framing_enabled`. The legacy key is still read via a deprecation shim (with a one-line warning); shim removal is deferred to a future milestone once live project files have migrated.

## [v2.17] - 2026-06-21

### Added

- **Abstraction-altitude forcing function (Stage 4/5).** Every new capability is now interrogated for its abstraction altitude — does it extend an existing platform seam (`[adapters]`, a module boundary, a config surface), or solve point-wise? — as a forcing function rather than aspirational prose. A Stage-4 obligation requires naming the seam a structural design extends (or justifying a point solution with a cited seam-search); design-exploration gains an `altitude` distinctness axis (point-fix / extend-seam / new-abstraction) with a ≥2-band rule on new-mechanism designs; and a blocking design-review §4.7 seam-composition gate fails a design that does not discharge the seam question.
- **`HOST-BINDING-LEAK` leakage class + detector.** Hardcoding a host tool (`gh` / `git` / a host API) as *the* canonical mechanism in universal governance — where the operation belongs behind an adapter seam — is now a registered leakage class (the host-axis sibling of the path-portability class), with a warn-mode `deploy.sh` Check 42 detector.

### Changed

- The Stage-5 adversarial design review may now flag a pre-decided premise that sits at the wrong abstraction altitude as an advisory finding (with an explicit no-autonomous-reversal guard), routed to Collective Review — opening the one previously-estopped independent surface that can see a mis-framed premise.
- The `release/` pipeline specs now cross-reference the `[adapters].repo_host` host-operation seam, making it discoverable from within the release module.

## [v2.16] - 2026-06-21

A release now claims its version number atomically when it merges instead of reserving it early, so two releases in flight can no longer silently collide on a number.

### Added
- **Releases claim their version at the finish line.** A release's version number is now claimed atomically at the merge tag (defer-to-merge + compare-and-swap against the live published set) instead of reserved at Stage 4, so when two releases are open at once neither silently overwrites the other's slot. *Why it matters:* a release you are shipping can no longer quietly lose its version to a faster one that merged first — the number it ends up with is the number that actually got locked. ([#1697](https://github.com/cody-hutson/pmo-platform/issues/1697), [#1675](https://github.com/cody-hutson/pmo-platform/issues/1675), [#1673](https://github.com/cody-hutson/pmo-platform/issues/1673))
- **Version-claiming is defined host-agnostically.** The mechanism is a config-selected `repo_host` adapter exposing four operations (anchor / claimed-set / atomic-claim / lineage), with GitHub/git shipped as the v1 reference adapter and other hosts gated on their own adapter tickets. *Why it matters:* the determinism contract is tool-agnostic, so the platform is not hard-wired to one release host. ([#1676](https://github.com/cody-hutson/pmo-platform/issues/1676), [#65](https://github.com/cody-hutson/pmo-platform/issues/65), [#66](https://github.com/cody-hutson/pmo-platform/issues/66), [#1674](https://github.com/cody-hutson/pmo-platform/issues/1674))
- **Collisions are now detectable and auditable.** A pre-merge CI freeness gate flags a contended version before merge, a machine-readable re-version ledger records every collision, and a recovery doctrine covers reclaiming the next free number. *Why it matters:* if two releases still race for the same number, the loser is told to recompute and re-claim rather than silently overwriting, and the event is on the record. ([#769](https://github.com/cody-hutson/pmo-platform/issues/769), [#1008](https://github.com/cody-hutson/pmo-platform/issues/1008), [#1677](https://github.com/cody-hutson/pmo-platform/issues/1677), [#1678](https://github.com/cody-hutson/pmo-platform/issues/1678), [#1679](https://github.com/cody-hutson/pmo-platform/issues/1679), [#1092](https://github.com/cody-hutson/pmo-platform/issues/1092))

[Full notes](release/releases/notes/v2.16_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.16)

## [v2.15] - 2026-06-20

The PMO role-Specialist suite is now GA — five Release-to-Sustain role agents and a capstone router that sends a role-shaped request to the Specialist that owns it.

### Added
- **The role-Specialist suite is GA and addressable as one unit.** The nineteen role-Specialists (fourteen prior-wave + five new) are now a single, routable suite. *Why it matters:* you can reach for any delivery role by name and get its full perspective, not a generic function output. ([#181](https://github.com/cody-hutson/pmo-platform/issues/181))
- **A router sends a role-shaped request to the right Specialist.** Ask "which role handles this?" and the capstone `pmo-skill-router` matches the request to the one Specialist that owns the work, reading the new `core/skills/registry.md` logical skill registry. *Why it matters:* you do not have to know the skill catalogue — routing changes by editing one registry file, never the router. ([#181](https://github.com/cody-hutson/pmo-platform/issues/181), [#1564](https://github.com/cody-hutson/pmo-platform/issues/1564))
- **The Release-to-Sustain roles are now first-class agents.** A Release Manager owns the release tail (go/no-go, deploy, close-out); Tier-1 Support triages and resolves known issues; Tier-2 Support root-causes the novel ones and writes the runbook; the OCM Lead drives a go-live's organizational change; the Knowledge Manager captures and files knowledge assets. *Why it matters:* the seats that carry a delivery effort from ship through steady-state are covered, each composing the platform's function-skills rather than re-implementing them. ([#1120](https://github.com/cody-hutson/pmo-platform/issues/1120), [#1121](https://github.com/cody-hutson/pmo-platform/issues/1121), [#1122](https://github.com/cody-hutson/pmo-platform/issues/1122), [#1123](https://github.com/cody-hutson/pmo-platform/issues/1123), [#1124](https://github.com/cody-hutson/pmo-platform/issues/1124))

[Full notes](release/releases/notes/v2.15_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.15)

## [v2.12] - 2026-06-21

Filing and grading a work item now checks more of its form at intake, keeps body-stated priority in sync with the tracker, and lets you tag an improvement's domain.

[Full notes](release/releases/notes/v2.12_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.12)

## [v2.14] - 2026-06-21

### Added
- **Progressive-rollout convention.** One named convention now governs how a pipeline change is introduced, watched, enforced, and eventually retired (`shadow → warn → enforce → removed`), lifted from scattered per-mechanism homes into a single canonical document. *Why it matters:* the language and structure for rolling out and sunsetting a change are consistent instead of reinvented each time. ([#164](https://github.com/cody-hutson/pmo-platform/issues/164))
- **Touchpoint + phase-out schema.** A schema for inventorying every place a human is still in the loop and planning each one's retirement (with FMEA risk fields), plus a non-blocking deploy check that validates a local instance's structure. *Why it matters:* phase-out planning has a defined structure, and a malformed inventory surfaces as a warning rather than passing silently. ([#165](https://github.com/cody-hutson/pmo-platform/issues/165))

[Full notes](release/releases/notes/v2.14_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.14)

## [v2.13] - 2026-06-20

Finding-disposition and deferral handling become uniform across the pipeline — behavioral acceptance criteria survive the gates intact, requirements-clarity rejects route upstream, and deferred items gain validity criteria plus a re-evaluation cadence.

[Full notes](release/releases/notes/v2.13_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.13)

## [v2.11] - 2026-06-20

Twelve principal-level role-Specialist agents — Product Owner, Business Analyst, Program/Project/Portfolio Manager, Scrum Master, Release Train Engineer, Principal/Software Engineer, Architect, QA Lead, DevOps/SRE — each composing the platform's existing function-skills.

[Full notes](release/releases/notes/v2.11_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.11)

## [v2.10] - 2026-06-20

Two agent editing disciplines are codified — canonical-form application and reconcile-don't-annotate — wired into the decision discipline.

[Full notes](release/releases/notes/v2.10_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.10)

## [v2.09] - 2026-06-20

Health pass on the deploy and release tooling: several checks and scripts that were silently skipping or failing opaquely now work as intended. Eleven surgical fixes to the platform's own deploy and release scripts; all additive or corrective, nothing you invoke directly and nothing you need to do.

### Fixed

- **A deploy check that quietly skipped its own job now runs.** The rules-mirror sync check was pointed at a folder that no longer exists, so it silently skipped instead of comparing; it now compares the real pair. *Why it matters:* a rules file drifting out of sync with its deployed copy is caught at deploy time instead of going unnoticed. ([#1104](https://github.com/cody-hutson/pmo-platform/issues/1104))
- **Copy failures during deploy now say what actually went wrong.** A failed copy into a read-only location reported a generic message; it now reports the actionable root cause. *Why it matters:* a failed deploy points you at the fix instead of leaving you to guess. ([#984](https://github.com/cody-hutson/pmo-platform/issues/984))
- **Repository maintenance scripts work again after the folder reorganization.** Scripts that compute release metrics, summarize release learnings, and detect change blast-radius were looking for pre-reorganization folders and quietly did nothing; they now resolve the current paths. *Why it matters:* the cleanup and reporting that runs around each release does its job instead of silently no-op-ing. ([#400](https://github.com/cody-hutson/pmo-platform/issues/400), [#758](https://github.com/cody-hutson/pmo-platform/issues/758), [#760](https://github.com/cody-hutson/pmo-platform/issues/760))
- **The end-of-release cleanup now catches the branches it was missing.** It did not recognize version-prefixed release branches or agent worktrees; it now matches them. *Why it matters:* stale release branches and worktrees get cleaned up instead of piling up. ([#1089](https://github.com/cody-hutson/pmo-platform/issues/1089))

### Added

- **A framework-catalog path-resolution check** ships logged-but-not-blocking, surfacing stale catalog entries as warnings until it is later turned on to block. ([#661](https://github.com/cody-hutson/pmo-platform/issues/661))

[Full notes](release/releases/notes/v2.09_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.09)

## [v2.04] - 2026-06-20

Every release can now close with a structured retrospective and lessons-learned write-up, authored from a single template that ships with the platform — a blameless retrospective and a lessons-learned ceremony combined in one file. The template landed on top of a ratified decision about which release records are public capability and which are the maintainer's own local working history. This release decides that split and ships the template; physically moving the maintainer's history out of the shared copy is captured as a separate follow-up and changes nothing you observe today. Everything is additive.

### Added

- **A close-out retrospective template.** Each release can be closed with one combined template that walks a blameless retrospective (what went well, what we learned, what we'd change) and a lessons-learned write-up (situation, outcome, lessons, next-cycle actions). *Why it matters:* the end-of-release reflection has a ready structure to fill in instead of being assembled from scratch or skipped. ([#360](https://github.com/cody-hutson/pmo-platform/issues/360), [#361](https://github.com/cody-hutson/pmo-platform/issues/361))
- **A decided home for each release record.** The close-out step names the template and states that the filled-in copy is written to your own local workspace, not committed to the shared platform (ADR-032). *Why it matters:* your release reflections stay local, and a fresh install ships the blank template without anyone else's release history. ([#1412](https://github.com/cody-hutson/pmo-platform/issues/1412))

[Full notes](release/releases/notes/v2.04_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.04)

## [v2.07] - 2026-06-20

The daily processing cycle no longer has to be launched by hand. Scheduled sweeps watch an inbox and your trackers — capturing, classifying, and proposing updates — all bounded by a single plain-language dial (`off` / `recommend` / `bounded_auto`) you set in your config; the dial is a ceiling, and the human-only decisions stay human-only no matter where you set it. A consolidated daily digest reports what every sweep did, with a heartbeat so a sweep that quietly stops can't go unnoticed, and a new runtime guardrail enforces the ceiling (shipped logged-but-not-blocking; you turn it on after a short trial). This release requires action: run `update.sh`, set your `automation_level`, and later flip `.autonomy-mode` from `warn` to `enforce`.

### Added

- **One dial controls how far ambient automation can act.** A new `automation_level` setting (`off` / `recommend` / `bounded_auto`) in your config is a ceiling on everything the automation does — any action's real permission is the lower of your dial and that action's own limit. *Why it matters:* you govern the autonomy of the whole intake pipeline from one place, and the human-only decisions are never unlocked. ([#322](https://github.com/cody-hutson/pmo-platform/issues/322))
- **Intake can run on a schedule.** Scheduled sweeps watch an inbox and your transcripts/emails (Path A) and your Jira/Confluence/Smartsheet trackers (Path B), proposing tracker closes only when the supporting evidence is present. *Why it matters:* routine processing happens on a cadence without you launching it, and a close never fires without its evidence. ([#1160](https://github.com/cody-hutson/pmo-platform/issues/1160), [#1161](https://github.com/cody-hutson/pmo-platform/issues/1161))
- **A watched inbox no longer ingests the same thing twice.** The inbox drop-zone tracks what it has already seen with a content fingerprint. *Why it matters:* dropping a file in for processing is safe to repeat. ([#1159](https://github.com/cody-hutson/pmo-platform/issues/1159))
- **One daily digest reports every sweep, with a heartbeat.** All sweep activity rolls up into the daily status digest, which carries a sweep-health heartbeat. *Why it matters:* a sweep that silently stops shows up as a missing heartbeat instead of going unnoticed. ([#1162](https://github.com/cody-hutson/pmo-platform/issues/1162))
- **A runtime guardrail enforces the ceiling.** A new check inspects each action against your dial and blocks anything above the ceiling in the highest-stakes categories (governance and cross-domain changes); it ships logged-but-not-blocking until you flip it on (ADR-031). *Why it matters:* the dial actually stops above-ceiling actions once enforced, not just advises. ([#1163](https://github.com/cody-hutson/pmo-platform/issues/1163))

[Full notes](release/releases/notes/v2.07_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.07)

## [v2.08] - 2026-06-20

The platform's generated-artifact surface — the staging area where AI-generated artifacts land and the folders they get promoted into — now has a lineage graph and a graph-integrity lint. Generated artifacts can record which artifact they came from and which they replace, and a new recommend-only skill scans that surface for duplicates, orphans, stale drafts, displaced files, and version chains, surfacing each for operator approval instead of letting them silently pile up. The lint never moves or deletes anything — every action it proposes is operator-approved. Everything is additive: a new skill and new optional metadata fields, with no existing field, file, or behaviour removed or renamed.

### Added

- **A lineage graph for generated artifacts.** Generated artifacts can now record their lineage with three optional fields — which artifact they derive from, a grouping topic for near-duplicate detection, and which artifact they supersede — across both formal-baseline and synthesis artifacts, with a clear table separating lineage (links between generated artifacts) from provenance (the upstream human evidence). *Why it matters:* parent-child and replacement relationships between AI-generated artifacts now survive the session that created them, so duplicates and superseded versions can be detected later. ([#334](https://github.com/cody-hutson/pmo-platform/issues/334))
- **A recommend-only lint for the generated-artifact surface.** A new skill scans the staging area and promoted folders and runs five graph-integrity checks — orphan, sibling-duplicate, stale-draft, displaced-content, and version-chain — staging a single report with a proposed action and an undo-cost rating for each finding. It performs no file moves and no deletes; the operator approves every action. *Why it matters:* duplicate, orphaned, stale, or misfiled generated artifacts are surfaced for review instead of silently accumulating. ([#1165](https://github.com/cody-hutson/pmo-platform/issues/1165))

[Full notes](release/releases/notes/v2.08_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.08)

## [v2.06] - 2026-06-20

The platform's automated integrity checks now carry a written contract: a passing check must confirm the real thing it claims by inspecting actual content, never a stand-in signal — starting with a package-freshness check that compared file timestamps (which an ordinary checkout silently resets) and now compares the package's contents. The hook documentation was also restructured so two changes to the platform's security hooks can land at once without colliding. Four cards; everything is additive — no existing rule, setting, or behaviour is removed or renamed. A follow-up point release (v2.06.1) repaired two deploy-script detection bugs the new content checks exposed.

### Added

- **Gate-efficacy contract for automated checks.** Every integrity check now must confirm what it claims by inspecting the real content behind it, and must state whether it blocks a change or is advisory; the package-freshness check was converted from a timestamp comparison to a content comparison. *Why it matters:* a check that passes is now a check you can trust — a stale package can no longer slip through green. ([#1101](https://github.com/cody-hutson/pmo-platform/issues/1101))
- **Skill-structure check now also runs on every pull request.** A structural check that previously ran only at deploy time now runs in continuous integration too, sharing a single source so the two cannot disagree. *Why it matters:* a structural problem in a skill is caught at the pull-request stage instead of a later deploy. ([#673](https://github.com/cody-hutson/pmo-platform/issues/673))
- **Per-hook security-hook documentation with a generated index.** The security-hook reference moved from one large shared file to one small file per hook, with the combined reference rebuilt automatically and a check that flags any hook left undocumented (ADR-030). *Why it matters:* two hardening changes can now land at the same time without colliding on one file, and the hook list can no longer drift out of sync with the hooks that exist. ([#18](https://github.com/cody-hutson/pmo-platform/issues/18))
- **Recorded decision against a redundant pre-commit layer.** A spike evaluated adding a pre-commit safety layer and concluded it is not needed, since the protections are already enforced earlier; closed with a residual-risk note rather than code. *Why it matters:* the platform records the deliberate non-change instead of leaving the question open. ([#90](https://github.com/cody-hutson/pmo-platform/issues/90))

[Full notes](release/releases/notes/v2.06_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.06)

## [v2.05] - 2026-06-19

A cluster of working agreements that had guided the platform's agents from session to session now live in the platform's own rules, and a new architecture decision defines how knowledge moves from an agent's memory into the durable corpus — and how the redundant copy is cleaned up once it lands.

[Full notes](release/releases/notes/v2.05_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.05)

## [v2.03] - 2026-06-18

A repeatable factory for building role-scoped agent skills from a single structured "feeding document" now exists end to end, and the first two role agents built on it ship: a Technical Program Manager and a Program Coordinator. Two skill-build cards; everything is additive — no existing skill, setting, or behaviour is removed or renamed.

### Added

- **Two new role agents.** A Technical Program Manager agent (composes the technical-review and delivery skills) ties a program's technical risk to its delivery plan, and a Program Coordinator agent (composes the tracker and daily-status skills) keeps a program's trackers and status cadence in lockstep. *Why it matters:* you can ask for a program-level technical-readiness read or a tracker-to-status coherence check directly instead of assembling it by hand. ([#185](https://github.com/cody-hutson/pmo-platform/issues/185))
- **Role-skill factory foundation.** The skill builder accepts a single feeding document describing a role and produces the skill from it, drawing on five new shared building-block files, with the 14-section feeding-document format locked so later role agents build against a stable contract. *Why it matters:* the next role agents arrive faster and more uniformly because the plumbing every role build depends on is in place and proven. ([#186](https://github.com/cody-hutson/pmo-platform/issues/186))

[Full notes](release/releases/notes/v2.03_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.03)

## [v2.02] - 2026-06-18

The release pipeline's bundling stage now enforces capacity and sizing as gates rather than written guidance: an oversize milestone is caught and routed to a split or tighter merge, a poorly-parsing release plan is held before it advances, capacity is weighed by release ceremony, and the release log records per-release velocity. Four governance/spec/schema cards; everything is additive — no existing setting, field, or behaviour is removed or renamed.

### Added

- **Per-milestone size gate.** Bundle planning sums a milestone's story points and checks the total against its size band; an oversize milestone is routed to a split or a tighter merge at a named gate (G3-15) instead of proceeding. *Why it matters:* an oversize bundle is surfaced for a decision at planning time rather than discovered after the work is in flight. ([#294](https://github.com/cody-hutson/pmo-platform/issues/294))
- **Mode-A parse-rate gate.** The release planner's dependency-graph output is held at a named gate (G3-14) until it parses at or above 90% of the eligible items, unless an operator override is recorded. *Why it matters:* a low-confidence dependency graph no longer reaches bundle and planning approval unguarded. ([#293](https://github.com/cody-hutson/pmo-platform/issues/293))
- **Risk-weighted release-capacity model.** The bundle capacity check counts a higher-ceremony release's story points for more against the same target band, using per-release-class weights, with the rounding mode pinned and the sizing guidance consolidated into one source (ADR-027). *Why it matters:* a heavier, higher-risk release is sized closer to its real cost instead of being treated like a routine one of equal raw point count. ([#290](https://github.com/cody-hutson/pmo-platform/issues/290))
- **Release velocity tracking.** Each release now records its planned-versus-delivered points, files changed, and work allocation in the release log, next to the existing cycle-time field. *Why it matters:* the platform accumulates the actuals it needs to re-tune the capacity weights from real delivery data after a few releases. ([#281](https://github.com/cody-hutson/pmo-platform/issues/281))

[Full notes](release/releases/notes/v2.02_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.02)

## [v2.01] - 2026-06-16

Seven existing skills gain enforcement with no new skill added: the delivery engine enforces estimation discipline, a 15-stage lifecycle and a 10-gate ladder and classifies tech debt; the PPM agent governs and scores intake; the tracker manager de-duplicates RAID entries; the weekly roll-up scans for projects that look green but aren't; daily status drives its colour from a formula; and the process designer and technical analyst score requirement and design quality. Every change is additive — nothing is removed or renamed.

### Added

- **Delivery-engine estimation enforcement.** Estimates are checked against a buffer-and-variance standard instead of being accepted as-is. *Why it matters:* a missing buffer or out-of-variance estimate is flagged when you run the check, not discovered mid-sprint. ([#264](https://github.com/cody-hutson/pmo-platform/issues/264))
- **15-stage lifecycle tracking with a 10-gate ladder.** Each item is placed on a 15-stage lifecycle and run through a ten-gate check returning pass / conditional / fail at each gate between the stages. *Why it matters:* you can see which stage an item is at and which gate is holding it instead of inferring progress from status text. ([#265](https://github.com/cody-hutson/pmo-platform/issues/265), [#266](https://github.com/cody-hutson/pmo-platform/issues/266))
- **Tech-debt classification, ranking, and capacity floor.** The delivery engine applies a Fowler-quadrant classification and a Cost-of-Delay ranking and checks tech-debt work against a reserved-capacity floor with an aging read; an absent rework-input yields "not computable" rather than a fabricated rate. *Why it matters:* you get a defensible debt-paydown order and an honest gap instead of an invented figure. ([#366](https://github.com/cody-hutson/pmo-platform/issues/366), [#180](https://github.com/cody-hutson/pmo-platform/issues/180))
- **PPM-agent intake governance and scoring.** Incoming work runs through an intake-governance check and a WSJF priority score, and the agent detects the delivery org model and escalates stale RAID items. *Why it matters:* intake is prioritised on a consistent basis and an aging risk or issue is surfaced instead of sitting past its review date. ([#253](https://github.com/cody-hutson/pmo-platform/issues/253), [#254](https://github.com/cody-hutson/pmo-platform/issues/254))
- **Tracker-manager RAID deduplication and cascade detection.** RAID updates are checked for near-duplicates above a similarity threshold and for cascade relationships between entries. *Why it matters:* the same risk logged twice in different words is caught before it clutters the register, and linked entries are surfaced together. ([#251](https://github.com/cody-hutson/pmo-platform/issues/251))
- **Weekly roll-up watermelon scan and metric governance.** The roll-up runs the platform's eight-signal watermelon scan — reusing the single owned copy of those signals rather than its own fork — plus a metric-governance check. *Why it matters:* a project reporting green while its underlying signals are red is flagged before that status reaches the steering audience. ([#256](https://github.com/cody-hutson/pmo-platform/issues/256))
- **Formula-driven daily-status RAG and buffer tracking.** The red/amber/green rating is computed from defined inputs and buffer consumption is tracked alongside it. *Why it matters:* the status colour is reproducible from the numbers instead of varying as a day-to-day judgement call. ([#260](https://github.com/cody-hutson/pmo-platform/issues/260))
- **Requirement and design quality scoring.** The process designer scores requirements against INVEST, checks acceptance criteria are in Given-When-Then form, and classifies non-functional requirements against ISO/IEC 25010; the technical analyst treats accepted design decisions as immutable, scores design-document quality, and reads Accelerate/DORA delivery metrics. *Why it matters:* a weak requirement or under-specified design is caught with a stated rubric rather than left to a reviewer to notice. ([#263](https://github.com/cody-hutson/pmo-platform/issues/263), [#259](https://github.com/cody-hutson/pmo-platform/issues/259))

[Full notes](release/releases/notes/v2.01_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.01)

## [v2.00] - 2026-06-15

Five existing skills gain deeper capability with no new skill added: change-management now tracks adoption and runs tiered hypercare with SLA compliance, the release executor checks a release against an ordered gate ladder before it applies and can roll a new gate out gradually, the QA auditor runs an eight-signal failure-mode battery with a RACI check, the release planner labels how a plan's artifacts relate, and the artifact generator stamps every artifact with a canonical lifecycle state and flags stale ones. Everything is additive except one contained field rename inside the artifact generator's own output.

### Added

- **Change-management adoption tracking.** A new Adoption Tracking mode surfaces an ADKAR barrier assessment, training-timing validation, champion-ratio and sponsor-coverage reads, and a change-fatigue and outcome-measurement read. *Why it matters:* you can see where adoption is actually stalling instead of inferring it from a static plan. ([#1127](https://github.com/cody-hutson/pmo-platform/issues/1127), [#1128](https://github.com/cody-hutson/pmo-platform/issues/1128), [#1129](https://github.com/cody-hutson/pmo-platform/issues/1129))
- **Tiered hypercare with SLA compliance.** The hypercare mode classifies each incident into one of three risk tiers, records its open and resolve times, and produces a per-tier met-versus-breached compliance report; an open SLA breach now blocks hypercare exit. *Why it matters:* you can prove whether hypercare commitments are being met, and a go-live cannot quietly close hypercare over an open breach. ([#1130](https://github.com/cody-hutson/pmo-platform/issues/1130), [#1131](https://github.com/cody-hutson/pmo-platform/issues/1131))
- **Ordered pre-apply quality-gate ladder for releases.** The release executor runs a three-step ladder — schema validation, then cross-reference integrity, then stakeholder approval — that fires in order and stops at the first hard failure, with an actionable reason. *Why it matters:* a release that would not pass its own checks is stopped before it changes anything. ([#244](https://github.com/cody-hutson/pmo-platform/issues/244))
- **Gradual rollout for release gates.** Each release gate carries an observe-only, notice-only, or blocking setting, so a new gate can run silently and log what it would catch, then warn, then block — the move to blocking being an explicit operator decision. *Why it matters:* a new gate proves itself on real releases before it can ever block one. ([#245](https://github.com/cody-hutson/pmo-platform/issues/245))
- **Documented release close-out.** The close-release mode now audits open issues as a blocking finding and reports carry-forward and deferred items as a named close-out output every time. *Why it matters:* a release cannot close over open issues silently, and nothing scoped-but-unshipped is dropped. ([#212](https://github.com/cody-hutson/pmo-platform/issues/212))
- **QA failure-mode detector battery and RACI gate.** The QA auditor screens an output against eight named failure signals (automation complacency, faceless PMO, echo chamber, quality drift, single-point-of-failure, breadth burnout, AI hallucination, trust erosion) and flags a responsibility assignment with no single accountable owner. *Why it matters:* recurring ways an output goes wrong are caught by name with a stated threshold rather than left to a reviewer to notice. ([#248](https://github.com/cody-hutson/pmo-platform/issues/248))
- **Typed artifact linking in release plans.** A generated release plan labels each edge in its dependency view with one of four relationship types — generates, depends-on, blocks, or supersedes — using the platform's existing relationship vocabulary. *Why it matters:* you read how a release's pieces relate at a glance instead of inferring the graph by hand. ([#246](https://github.com/cody-hutson/pmo-platform/issues/246))
- **Artifact lifecycle states and zombie detection.** Every generated artifact is stamped with a canonical lifecycle state (draft → reviewed → approved → promoted → archived), and the health check flags artifacts left unreferenced beyond 30 days while still in a live state, listing them in a documentation-debt register. *Why it matters:* you can tell where an artifact sits in its life and surface stale ones instead of discovering them by accident. ([#252](https://github.com/cody-hutson/pmo-platform/issues/252))

### Changed

- **Generated-artifact state field renamed to `artifact_state`.** The field recording an artifact's lifecycle state on generated artifacts is now `artifact_state` (previously `status`), aligned to the platform-canonical five-state vocabulary. *Why it matters:* the change is contained to the artifact generator's own output and no other skill reads that value, so nothing downstream needs updating. ([#252](https://github.com/cody-hutson/pmo-platform/issues/252))

[Full notes](release/releases/notes/v2.00_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v2.00)

## [v1.24] - 2026-06-14

The triage assistant's automated backlog-hygiene checks — finding issues with an orphaned (rejected or missing) dependency, and finding P1 work blocked by lower-priority work — were silently returning nothing because of a shell-parsing bug, so those problems went unsurfaced even when present. The bug is fixed and the checks now return correct results. A stale cross-reference in the release-process documentation was also corrected.

### Fixed

- Triage's orphaned-dependency check (Pattern 1b) was silently returning nothing; it now reads each issue's dependency list correctly and flags issues waiting on a rejected or missing dependency. ([#309](https://github.com/cody-hutson/pmo-platform/issues/309))
- Triage's P1-blocked-by-lower escalation check (Pattern 2a) hit the same parsing bug and returned nothing; it now extracts each issue's priority correctly and flags a Critical (P1) item blocked by lower-priority work. ([#309](https://github.com/cody-hutson/pmo-platform/issues/309))
- A stale cross-reference in `release-process.md` named the wrong section of the triage spec for the "stale issues" check; it now points to the correct `Phase A6.5 Pattern (1a)`. ([#309](https://github.com/cody-hutson/pmo-platform/issues/309))

[Full notes](release/releases/notes/v1.24_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.24)

## [v1.23] - 2026-06-14

The change-management skill becomes a pluggable toolkit of five change methodologies — ADKAR, Kotter's 8-Step, Lewin's 3-Stage, the Bridges Transition Model, and McKinsey 7-S — with a selection step that picks the right one (or combination) for a given change. ADKAR's scale, previously defined twice, is consolidated to one source of truth. An intake-governance standard (tiering, WSJF, SLAs, demand taxonomy) ships for the intake desk, and a cross-pipeline sub-task methodology reference documents how sub-tasks are used across the pipeline.

### Added

- Four codified change methodologies for change-management — Kotter 8-Step, Lewin 3-Stage, Bridges Transition Model, McKinsey 7-S — each registered in the framework catalog.
- A methodology-selection mechanism (a `methodology-selection.md` selector + a SKILL.md Step 2.5) that picks the applicable methodology or combination per change context, or honors an explicit user choice.
- An intake-governance reference standard for intake-desk: business-case tiering, a WSJF prioritization formula, intake SLAs, a six-type demand taxonomy, and anti-pattern detection.
- A cross-pipeline sub-task methodology best-practices reference standard.

### Changed

- ADKAR's 1-5 scale and barrier-point rule consolidated into `adkar-framework.md` as the single source of truth; `impact-assessment.md` and `readiness-checklist.md` now reference it.
- `change-management` and `intake-desk` skill versions bumped to v1.23.
- `framework-catalog.md` gains the four methodology rows plus ADKAR and Cost-of-Delay `canonical_doc` pointers.

[Full notes](release/releases/notes/v1.23_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.23)

## [v1.22] - 2026-06-14

The deploy and governance toolchain is repaired across eleven defects on its most-edited file plus one folded-in same-class fix. Checks that used to crash on a counting step, swallow a read-only install error then fail opaquely later, clip a configured path at a `#`, or crash on a non-English character now run cleanly and report what they find, and a new check flags when a multi-mode skill's modes drift out of recognizability.

### Added

- **A check for multi-mode skill drift.** A new deploy check confirms each skill offering multiple modes still exposes them in a machine-recognizable way, and flags one that has drifted. *Why it matters:* a skill whose modes can no longer be detected is surfaced before it causes a mode-routing surprise, rather than failing silently later. ([#26](https://github.com/cody-hutson/pmo-platform/issues/26))

### Fixed

- **The deploy check no longer crashes on its own counting step.** Two governance checks counted matches in a way that could emit two values and fail with a math error; both now capture a single number. *Why it matters:* the deploy check completes and reports its findings instead of aborting with a `syntax error in expression`. ([#76](https://github.com/cody-hutson/pmo-platform/issues/76), [#1058](https://github.com/cody-hutson/pmo-platform/issues/1058))
- **A read-only leftover from a prior install is handled and explained.** Deploy used to hide a read-only-orphan failure then fail later with an unrelated error; it now clears the leftover where it can and otherwise reports the real cause and the fix. *Why it matters:* a failed deploy names the read-only leftover instead of an unrelated downstream error. ([#88](https://github.com/cody-hutson/pmo-platform/issues/88))
- **A configured install path containing a `#` is read in full.** The install-path reader used to cut the value off at the first `#`; it now reads the whole quoted path. *Why it matters:* an install path that legitimately contains a `#` is honored instead of silently truncated. ([#332](https://github.com/cody-hutson/pmo-platform/issues/332))
- **The dependency-graph tool no longer crashes on non-English characters.** The blast-radius tool failed with an "illegal byte sequence" error on any non-ASCII file; it now sorts those files cleanly. *Why it matters:* a file with an accented name or non-English content can be analyzed instead of crashing the tool. ([#92](https://github.com/cody-hutson/pmo-platform/issues/92))
- **The `--report` view matches the `--check` view.** A governance check that ran under `--check` was missing from the `--report` summary; the report now carries the same pass/fail row. *Why it matters:* the report you use for close-out evidence reflects the checks the deploy actually ran. ([#104](https://github.com/cody-hutson/pmo-platform/issues/104))

[Full notes](release/releases/notes/v1.22_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.22)

## [v1.21] - 2026-06-14

Two new automated quality gates ship, both starting in a logged-but-not-blocking mode while they settle in. One confirms that a starter template still carries every section its format rules require, so a template cannot quietly fall out of step with its own schema; the other scans a change for leftover old values after a rename or restructure, catching the case where some occurrences got updated and some were missed.

### Added

- **Starter templates are checked against their own format rules.** A new gate confirms each template governed by a schema carries every section that schema requires, and flags one that has drifted; the Open Meetings tracker template — the first divergence caught — was reconciled to its schema in the same release. *Why it matters:* a project scaffolded from a template gets the structure the format actually calls for, instead of a stale template that quietly lost a section. ([#318](https://github.com/cody-hutson/pmo-platform/issues/318))
- **Leftover old values after a rename or restructure are now caught.** The quality auditor gained a check that scans the changed files in a piece of work for occurrences of an old value a rename or restructure was supposed to sweep, and flags any it missed. *Why it matters:* a rename that updated most references but missed a few is surfaced rather than left as a half-renamed change to be discovered later. ([#79](https://github.com/cody-hutson/pmo-platform/issues/79))

[Full notes](release/releases/notes/v1.21_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.21)

## [parallel-launch-quota-budget-gate] - 2026-06-14

Version-less release (no `vMAJOR.MINOR` assigned; ships under the slug `parallel-launch-quota-budget-gate`, which is also the signed git tag and the GitHub Release tag). Running several release tasks in parallel used to launch them blind to the operator's remaining usage window, so a batch could fail partway through once the window was exhausted; the release pipeline now estimates a parallel batch's cost and checks it against the remaining window before launching, and re-checks before each wave rather than only once at planning time.

### Added

- **A usage-window check before parallel work launches.** Before firing a batch of parallel tasks, the pipeline estimates its cost against the remaining usage window and either proceeds, runs the tasks serially, holds the batch for the next window, or trims per-task cost. *Why it matters:* a batch no longer half-completes and then fails on a depleted window — you get a recommended course of action up front instead of started-but-failed work to recover. ([#23](https://github.com/cody-hutson/pmo-platform/issues/23))
- **The check runs before every wave, not just at planning.** The budget is estimated once at release planning and re-validated before each parallel wave, accounting for work done in between and elapsed window time. *Why it matters:* a window that was fine at planning but has since been drawn down is caught before the next batch launches, not after it fails. ([#23](https://github.com/cody-hutson/pmo-platform/issues/23))
- **A record of what each launch reserved.** Parallel launches can record an entry noting the estimated cost reserved against the window. *Why it matters:* budget estimates get more accurate over time as real launch costs accumulate, grounding future checks in observed cost rather than a fixed guess. ([#24](https://github.com/cody-hutson/pmo-platform/issues/24))

### Changed

- **The constraint is named correctly — a usage window, not a rate limit.** An overrun is routed to the mitigations that address a cumulative usage limit (run serially, defer, or reduce scope); in-prompt staggering is documented as a rate-limit-only defense, not the usage-window fix. *Why it matters:* the fix you are offered matches the real problem, rather than a timing tweak that does not move a cumulative-usage limit. ([#24](https://github.com/cody-hutson/pmo-platform/issues/24))

[Full notes](release/releases/notes/parallel-launch-quota-budget-gate_RELEASE_NOTES.md)

## [v1.20] - 2026-06-14

Health colors and RAID escalations used to depend on which skill produced them and how each one decided where the lines were. This release writes those lines down once — the thresholds that turn a metric green, yellow, or red, and the ages at which an open risk or issue is warned and then escalated — and has every skill read from the same place, so the same project situation produces the same color and the same escalation no matter which part of the platform reports it.

### Added

- **One agreed set of health thresholds.** A single index now records which measure drives a health color at which level, where its green / yellow / red lines fall, and what each color tells you to do. *Why it matters:* a project that is eight percent behind schedule comes back the same color every time, instead of green from one skill and yellow from another. ([#271](https://github.com/cody-hutson/pmo-platform/issues/271))
- **"Green on the outside, red on the inside" status is now caught.** The quality auditor has a defined set of checks for a status reported green while the evidence underneath is amber or red. *Why it matters:* a health roll-up that looks fine but hides a slipping schedule or overdue risks gets flagged for you instead of passing review. ([#270](https://github.com/cody-hutson/pmo-platform/issues/270))
- **Stale risks and issues escalate on their own.** An open RAID item now has agreed ages at which it is first flagged and then escalated — an issue at 14 and 30 days, a risk at 30 and 60 — naming the owner and the threshold it crossed. *Why it matters:* a risk sitting open for two months surfaces a recommended escalation on its own instead of quietly aging until someone notices. ([#261](https://github.com/cody-hutson/pmo-platform/issues/261))
- **Escalation routing reads from the same agreed thresholds.** How a scored risk or issue is routed to an escalation tier, and the ages that trigger escalation, are defined in one place the others cite. *Why it matters:* how severe an item must be to escalate, and how long it can sit before it does, are the same everywhere rather than re-decided skill by skill. ([#269](https://github.com/cody-hutson/pmo-platform/issues/269))

[Full notes](release/releases/notes/v1.20_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.20)

## [v1.19] - 2026-06-14

When a skill raised a Critical or High issue, it used to name the problem and hand the analysis back to you. It now states the situation, what it blocks, the realistic options, and a recommended course of action with a confidence level — pointed at a named decision owner — and it reads the same way whether the escalation came from a status update, a project review, a technical review, or a delivery/RAID surface.

### Added

- **Escalations carry a recommendation, not just a problem.** A raised Critical or High issue now states the situation, the impact, the options, and a recommended option with a confidence level. *Why it matters:* you get the platform's judgment of what to do — not a "here is a problem, you decide" handoff that leaves the analysis on your desk. ([#179](https://github.com/cody-hutson/pmo-platform/issues/179))
- **Escalations point at a named decision owner.** Each escalation is routed to the person who owns the decision, drawn from the project's people list; when no owner can be determined, it routes to the program manager with a flag. *Why it matters:* an escalation lands with someone who can act on it instead of stalling unassigned. ([#177](https://github.com/cody-hutson/pmo-platform/issues/177))

### Changed

- **The recommendation and the ask are kept separate.** The recommendation states what the platform thinks is right; any deadline-bearing ask rides alongside it rather than replacing it. *Why it matters:* you can ratify or override a clear recommendation instead of reverse-engineering one from a bare request to decide. ([#179](https://github.com/cody-hutson/pmo-platform/issues/179))
- **One consistent escalation format across the skills.** Status updates, project reviews, technical reviews, and delivery/RAID escalations now share a single format and the same severity rule for when to escalate. *Why it matters:* an escalation reads the same way and applies the same threshold no matter which part of the platform raised it. ([#178](https://github.com/cody-hutson/pmo-platform/issues/178), [#934](https://github.com/cody-hutson/pmo-platform/issues/934))

[Full notes](release/releases/notes/v1.19_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.19)

## [v1.18] - 2026-06-14

The release pipeline used to plan and approve each release on its own. It now holds a model of every release in flight or planned and checks each new one against that set, so two releases that would move or rename the same files are caught up front and run one-at-a-time instead of colliding partway through. This is a foundation change inside the pipeline; nothing changes in how you use the platform.

### Added

- **Releases that would clash are now caught before they break each other.** When one release moves or renames files another release depends on, the pipeline detects the clash up front and runs the two in order rather than in parallel. *Why it matters:* a release no longer fails partway through because a sibling release quietly moved the ground under it — the conflict surfaces at planning time, not as a broken merge late in the process. ([#87](https://github.com/cody-hutson/pmo-platform/issues/87))

### Changed

- **An approval to ship is re-checked if the ground shifts before it ships.** A go-ahead to release is recorded against the exact state it was approved against and re-checked if another release lands first. *Why it matters:* a release is only shipped against the state it was actually reviewed on, so an approval that has gone stale is caught instead of acted on as if still valid. ([#87](https://github.com/cody-hutson/pmo-platform/issues/87))

[Full notes](release/releases/notes/v1.18_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.18)

## [v1.17] - 2026-06-14

The two skills that draft your communications and project artifacts are refocused on PMO-unique work, and the commodity drafting an Anthropic skill does well is handed off to it at design time so the PMO skills carry no live dependency on it. The comms skill now owns executive briefs and stakeholder emails directly, the artifact skill has a tighter catalog plus a routing tree, and a duplicate architecture-decision record is renumbered.

### Added

- **The comms skill now owns executive briefs and stakeholder emails.** It produces both in the right voice in one step, without reaching for an outside skill while you use it, because that voice was built into the skill ahead of time. *Why it matters:* an exec brief or stakeholder email comes out with no setup and does not depend on any outside skill being available when you ask. ([#173](https://github.com/cody-hutson/pmo-platform/issues/173))
- **A routing decision now picks the right drafting path for each artifact request.** A decision tree routes a request to the PMO catalog when the work is PMO-specific and to a commodity drafting path otherwise. *Why it matters:* each request lands with the tool best suited to it without you having to know which skill owns what. ([#175](https://github.com/cody-hutson/pmo-platform/issues/175))

### Changed

- **The comms skill is focused on six PMO-unique communication types.** It keeps the rules that make its output principal-grade — audience calibration, escalation discipline, and the no-status-theater guardrails — and drops scope it never needed to own. *Why it matters:* the skill does PMO-specific communications well instead of spreading across commodity drafting another tool handles better. ([#174](https://github.com/cody-hutson/pmo-platform/issues/174))
- **The artifact catalog is tighter and clearer.** The artifact skill now lists the project artifacts that are genuinely PMO-specific and hands commodity drafting to a separate path. *Why it matters:* you see a focused menu of what the PMO skill is built to produce, instead of a long list mixing PMO-specific work with generic documents. ([#176](https://github.com/cody-hutson/pmo-platform/issues/176))

### Fixed

- **A duplicate architecture-decision record number is resolved.** Two records shared the same identifier; the skill-sourcing record is renumbered so each decision record has a unique, stable number. *Why it matters:* references to these decision records resolve to a single, unambiguous document. ([#791](https://github.com/cody-hutson/pmo-platform/issues/791))

[Full notes](release/releases/notes/v1.17_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.17)

## [v1.15] - 2026-06-13

The platform now measures and improves the quality of its own agents: a quality auditor that checks for base-vs-build compatibility drift on a regular cadence, a data-driven target for how many failure modes a complex skill should document, a single root-cause method anyone can invoke on a defect, and a playbook for migrating between approaches. A verified triage reconciles a month-old quality audit to current state.

### Added

- **The quality auditor can now run a platform-health audit on a cadence.** A new `platform-health` mode checks for compatibility drift between the underlying model behavior and what the platform's skills assume, and runs on a registered schedule rather than only on request. *Why it matters:* drift that would silently degrade agent quality gets caught on a regular cadence instead of surfacing as a surprise. ([#358](https://github.com/cody-hutson/pmo-platform/issues/358))
- **A single root-cause method is now available to invoke on a defect.** Root-cause analysis is now a named, invokable method with defined steps and handoff points from intake and the pipeline. *Why it matters:* defects get a consistent, repeatable diagnosis instead of an ad-hoc one that varies by who looks at it. ([#754](https://github.com/cody-hutson/pmo-platform/issues/754))
- **A migration playbook is now available.** A new playbook lays out how to move between approaches with a defined intake and pipeline handoff. *Why it matters:* a migration has a referenceable, repeatable path instead of being reinvented each time. ([#754](https://github.com/cody-hutson/pmo-platform/issues/754))

### Changed

- **Skill authoring now targets a data-driven number of failure modes, not just a floor.** The failure-mode standard now states a target range (6–10 for complex skills) instead of only a minimum of three. *Why it matters:* complex skills get failure-mode coverage sized to their real risk surface, so the auditor's coaching points authors at an evidence-based target rather than the bare minimum. ([#359](https://github.com/cody-hutson/pmo-platform/issues/359))

[Full notes](release/releases/notes/v1.15_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.15)

## [v1.14] - 2026-06-13

The platform's operator-configurable choices now resolve from one declared surface with a documented precedence order and a catalog of every field, and a new onboarding map lays out the whole clone-to-working-install journey and where each host choice plugs in. This is the adapter-config foundation the host adapters compose into.

### Added

- **Every platform configuration field is now discoverable in one place.** A single catalog lists each configurable field — what it does, its default, and where to set it — and a resolver decides the effective value from a clear precedence order (a per-project setting wins over a global default; an individual override wins over a project setting). *Why it matters:* you can see and change what is configurable without reading every governance file. ([#22](https://github.com/cody-hutson/pmo-platform/issues/22))
- **A whole-journey onboarding map is now available.** A new map orders the path from cloning the repository to a working install and names four uniform extension points where each host choice — code repository, ticketing, knowledge base, and AI tool — plugs in. *Why it matters:* a new user has one place that shows the full arc and exactly where their own systems attach. ([#703](https://github.com/cody-hutson/pmo-platform/issues/703))

### Changed

- **Configuration is split into two surfaces by concern.** Your environment and identity live on one surface; tunable platform behavior lives on another. *Why it matters:* the security-sensitive identity settings stay separate from the freely-tunable behavior settings, so the two are governed and changed independently. ([#22](https://github.com/cody-hutson/pmo-platform/issues/22))

[Full notes](release/releases/notes/v1.14_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.14)

## [v1.13] - 2026-06-13

Re-versioned from v1.12: this release was planned and built as `v1.12`, but the concurrent `corpus-durability-enforcement` release claimed v1.12 first, so the canonical version is v1.13 (the signed v1.13 tag points at this release's merge commit). Runtime code tests now run in CI and gate releases, test results are machine-readable in the pipeline, and the platform gains its first standing install/onboarding/update regression suite.

### Added

- **A standing install, onboarding, and update regression suite now runs at release time.** A new sandboxed suite performs a fresh install, checks no configuration placeholders are left unresolved, verifies file links and references in the deployed tree, confirms a two-phase deploy, and checks user configuration survives a simulated version upgrade. *Why it matters:* install and onboarding breakage that only shows up on a clean machine is caught by a repeatable suite before a release ships. ([#706](https://github.com/cody-hutson/pmo-platform/issues/706))
- **Runtime test results are now machine-readable in the pipeline.** Test outcomes are recorded as a structured `test-run` entry in the pipeline event log and carried in the Dev-Testing-to-QA handoff, instead of living only in raw CI logs. *Why it matters:* downstream reviewers and agents can see whether a release's code tests passed without digging through Actions output. ([#430](https://github.com/cody-hutson/pmo-platform/issues/430))

### Fixed

- **The platform's runtime code tests now run in CI and gate pull requests.** The committed deploy-layer and hook-layer test suites, which previously ran in no automated workflow, now run on every pull request and fail it if a test breaks, regardless of where the repository is checked out; a manifest-count assertion that could silently re-rot is now derived from the manifest. *Why it matters:* a change that breaks the deploy or hook behavior is caught on the pull request instead of slipping through to a release. ([#319](https://github.com/cody-hutson/pmo-platform/issues/319))

### Changed

- **A changed code path now maps to the test suite that gates it.** Dev Testing has a documented rule connecting a changed runtime code area to the suite that must run for it, plus a step that runs it. *Why it matters:* there is no longer a guessing game about which tests cover a given code change — the gating suite is named and run. ([#430](https://github.com/cody-hutson/pmo-platform/issues/430))

[Full notes](release/releases/notes/v1.13_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.13)

## [v1.12] - 2026-06-13

### Added

- **A reintroduced duplicate of a shared reference is now caught at deploy time.** The deploy self-check fails if the same shared reference is found copied back into a skill, whether the copy is identical or has been edited to differ. *Why it matters:* the single-source guarantee is enforced mechanically instead of relying on memory. ([#316](https://github.com/cody-hutson/pmo-platform/issues/316))
- **Raw GitHub issue, pull-request, and milestone URLs are flagged outside the release ledger.** A new check flags a raw `github.com/.../issues`, `/pull`, or `/milestone` URL in any tracked file except the release-tracking files where such references belong. *Why it matters:* those URLs break on a renumber or a repository move, so keeping them out of durable docs keeps those docs readable years later. Logged as a warning for now. ([#311](https://github.com/cody-hutson/pmo-platform/issues/311))

### Changed

- **Shared reference content now has one canonical source.** The two reference files that several skills each carried their own identical copy of now live once under the shared standards area and are injected into every consuming skill at deploy time. *Why it matters:* the copies can no longer silently fall out of sync — a fix made once reaches every skill. ([#316](https://github.com/cody-hutson/pmo-platform/issues/316))

[Full notes](release/releases/notes/v1.12_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.12)

## [cross-reference-integrity-ci] - 2026-06-13

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release). The reference-integrity rules the pre-commit hook applies locally now also run as warn-mode checks when a pull request opens.

### Added

- **Broken intra-repo links are now caught when a pull request opens.** A new link-check runs the same link-resolution engine the deploy step already uses, over the same files. *Why it matters:* a dead cross-reference is surfaced while it is still easy to fix, instead of at deploy time. ([#169](https://github.com/cody-hutson/pmo-platform/issues/169))
- **A stale skill-count claim or a live legacy IMP-XXX reference added to a skill spec is now caught on a pull request.** *Why it matters:* the platform's documentation can't quietly drift out of sync with how many skills actually ship. ([#130](https://github.com/cody-hutson/pmo-platform/issues/130))

### Fixed

- **The positional issue-reference check now agrees exactly with the pre-commit hook.** The pull-request check now uses the same line-position logic as the hook. *Why it matters:* the same reference passes or is flagged the same way whether it is checked on your machine or on the pull request. ([#314](https://github.com/cody-hutson/pmo-platform/issues/314))

[Full notes](release/releases/notes/cross-reference-integrity-ci_RELEASE_NOTES.md)

## [v1.11] - 2026-06-12

### Added

- **The workspace cleanup sweep can no longer delete the worktree it is running from.** Its own runtime worktree is classified as protected and survives every apply, including a forced one. *Why it matters:* a cleanup launched from inside a worktree can't destroy its own session mid-run. ([#333](https://github.com/cody-hutson/pmo-platform/issues/333))
- **Worktrees held by any live process are off-limits to the sweep.** An all-process working-directory scan skips live-held worktrees, re-checks seconds before each removal, and blocks the affected removals rather than guessing when the scan is unavailable (decision record ADR-021). *Why it matters:* a concurrent session's workspace can't be deleted out from under it — the safety degrades toward refusal, never toward deletion. ([#326](https://github.com/cody-hutson/pmo-platform/issues/326))

### Fixed

- **One apply pass now reaches a clean workspace.** Branches freed by the same run's worktree removals are removed in that run through one bounded re-evaluation, instead of surviving for a second invocation. *Why it matters:* no more running the sweep twice. ([#53](https://github.com/cody-hutson/pmo-platform/issues/53))

[Full notes](release/releases/notes/v1.11_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.11)

## [v1.10] - 2026-06-12

Failure-mode coverage completes across the whole skill catalog: every one of the 23 skills now documents at least one domain-specific failure mode in each of the five categories — wrong-invocation, bad-input, skipped-step, output-shape, and handoff. 45 new entries (each written against the skill's real working surface and LLM-quality-graded before merge) close every remaining gap, with the biggest upgrades on the boundary behaviors: wrong-invocation coverage rose from roughly half the catalog to all of it, handoff coverage from two-thirds to all of it. Two high-volume skills gained reference checklists (project-setup scaffold verification; weekly roll-up input coverage), every modified skill carries a current version field — including three that previously had none — and all 22 deployed skills shipped with rebuilt packages. Additions-only: no existing entry, mode, or contract was changed.

[Full notes](release/releases/notes/v1.10_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.10)

## [v1.09] - 2026-06-11

The agent-to-script promotion framework lands: a five-rung promotion ladder (AS0–AS4, decision record ADR-020) now governs when repeated agent work earns a script and what a script owes once it exists — evidence triggers and counter-signals gate each promotion, judgment-class steps promote only their evidence-gathering substrate, and every promoted script ships with its point-of-use citation in the same pull request. Grounded in a completed census of all 71 tracked scripts and a ranked 8-candidate opportunity inventory.

[Full notes](release/releases/notes/v1.09_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.09)

## [memory-to-corpus-codification] - 2026-06-10

Version-less release (no `vMAJOR.MINOR` assigned, no git tag, no GitHub Release) — a verification-only close-out of the memory-to-corpus codification scope. All nine targeted behavioral rules (five workspace guardrails + four git-workflow rules) were verified already present in the tracked corpus with their provenance recorded; the three now-redundant operator memory files were archived and retired from the operator memory store; and the tickets and milestone description were reconciled to live state. No user-visible behavior changes. Shipped single-branch via one [release pull request](https://github.com/cody-hutson/pmo-platform/pull/604) (the release-tracking corpus records the PR and merge SHA).

[Full notes](release/releases/notes/memory-to-corpus-codification_RELEASE_NOTES.md)

## [v1.08] - 2026-06-08

The skill-suite architecture spine lands: every role-named skill now has a binding architectural rule — Specialists compose shared function-skills rather than re-implementing them (ADR-019) — backed by a codified skill↔pipeline alignment standard, and the pmo-skill-refiner factory now fails loudly if its wrapped Anthropic scaffolder drifts in format instead of silently degrading.

[Full notes](release/releases/notes/v1.08_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.08)

## [v1.07] - 2026-06-07

The work-item type layer lands as a methodology-agnostic, best-practice template — a thin generic Work Item entity beneath Milestone/Workstream, a domain-neutral work-organization mapping framework, and a declarative type-pack meta-schema — so a user brings their own work types and an agent understands their work structure by nature.

[Full notes](release/releases/notes/v1.07_RELEASE_NOTES.md) · [Release](https://github.com/cody-hutson/pmo-platform/releases/tag/v1.07)

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

