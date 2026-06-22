# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
adapted for pmo-platform's release-milestone numbering (`vMAJOR.MINOR`).

## [Unreleased]

## [v2.18] - 2026-06-21

The `Hybrid` methodology is now defined cleanly as a user-configurable combination of two archetypes, decoupled from the operator-specific "SPM" co-management arrangement; dual-framing behavior is unchanged.

### Added

- **Hybrid is now a user-configurable two-archetype combination.** `delivery_approach` accepts a two-element array — `[Scrum, Kanban]`, `[Waterfall, XP]`, any two distinct archetypes — declaring a project that runs both methodologies side by side and reports status in both native framings. The literal `Hybrid` value is retained for backward-compatibility, and a one-line array is now the explicit forward-looking declaration instead of dropping to the heavyweight `Custom` block for what is really a two-archetype selection.

### Changed

- **`Hybrid` is decoupled from co-management.** The `Hybrid` methodology classification no longer names the operator-specific "SPM" co-management arrangement — the two were conflated, and they are now documented as orthogonal across the schema, governance, and methodology specs. A Hybrid project may run with or without co-management; a non-Hybrid project may enable co-management independently.
- **The `spm_comanaged` field is renamed `dual_framing_enabled`.** The trigger for dual Agile/Waterfall status framing now carries an operator-agnostic name. A live `PROJECT.md` carrying the legacy `spm_comanaged` key is still accepted — a deprecation shim reads it, emits a one-line warning, and treats it as `dual_framing_enabled` — so the rename is non-breaking. The operator token "SPM" survives only as operator-local configuration.
- **The "SPM Bridge" is renamed the "Dual-Framing Bridge".** The co-managed status artifact and its template, governance clause, and registry entries are renamed operator-agnostically, with role-based audience labels ("PMO view" / "Sponsor view"). The dual-framing output it produces is unchanged.

### Deprecated

- **The `spm_comanaged` frontmatter key.** Renamed to `dual_framing_enabled`. The legacy key is still read via a deprecation shim (with a one-line warning); shim removal is deferred to a future milestone once live project files have migrated.

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

<one-sentence ≤140 chars; plain language; agent-search target>

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

