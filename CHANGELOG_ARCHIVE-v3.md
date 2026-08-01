<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# CHANGELOG_ARCHIVE-v3

Archive segment of [`CHANGELOG.md`](CHANGELOG.md) — the **v3** release family.

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

## [v3.20] - 2026-06-07

Release-pipeline self-checks now fail loud on a broken path instead of passing green, and bundle planning parses real-world issue formats reliably.

### Fixed

- **The release pipeline catches its own broken checks now.** The self-checks that verify the platform's release records (and the broader deploy-check family) exit with an error when a path they depend on does not resolve, instead of silently reporting success. *Why it matters:* a misconfigured or moved file can no longer hide behind a green check. ([#83](https://github.com/cody-hutson/pmo-platform/issues/83), [#85](https://github.com/cody-hutson/pmo-platform/issues/85), [#459](https://github.com/cody-hutson/pmo-platform/issues/459))
- **The release-close tool only uses labels that exist.** A release-pipeline step that files a follow-up issue no longer references a label that was never created in the project, removing a latent failure that would surface the first time the step ran. ([#425](https://github.com/cody-hutson/pmo-platform/issues/425))

### Changed

- **Release planning reads real-world issue formats reliably.** The tool that groups open issues into a release now parses the heterogeneous ways issue bodies are written (varied section headings, missing optional sections) and reaches the ≥90% clean-parse target on the live bundle-ready set. *Why it matters:* fewer items are dropped or mis-grouped at planning time. ([#291](https://github.com/cody-hutson/pmo-platform/issues/291))

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
