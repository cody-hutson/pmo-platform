<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# CHANGELOG_ARCHIVE-v2

Archive segment of [`CHANGELOG.md`](CHANGELOG.md) — the **v2** release family.

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
