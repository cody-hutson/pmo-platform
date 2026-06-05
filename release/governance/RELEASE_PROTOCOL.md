# RELEASE_PROTOCOL.md — Platform Release Management

**Effective:** 2026-03-19
**Scope:** All governance changes across the workspace (CLAUDE.md, OPERATIONS.md, PORTFOLIO.md, SESSION_STATE.md, RELEASE_PROTOCOL.md, skills, folder structure, protocols)
**Owner:** [OPERATOR_NAME]
**Status:** Production

---

## Purpose

Defines the lifecycle for platform changes — from improvement intake through implementation to verification. This protocol governs how the workspace itself evolves and applies to all governance file modifications, skill updates, and structural changes.

Separated from OPERATIONS.md because the release process governs the entire workspace, not just PMO project management. OPERATIONS.md defines how projects are managed; this file defines how the platform changes.

---

## File Structure

```
Projects/_governance/
├── OPERATIONS.md                ← Operational protocols and cross-project rules
├── RELEASE_PROTOCOL.md          ← This file. How changes are managed.
├── Releases/
│   ├── RELEASE_LOG.md           ← Version history (Recent 5 + full history)
│   ├── _snapshots/              ← Pre-change file backups (rolling 15-release window)
│   │   └── [version]/           ← One folder per release
│   ├── _archive/                ← Release plan files pruned beyond 15-release window
│   ├── v5.0_RELEASE_PLAN.md    ← One flat file per release (also contains
│   ├── v5.1_RELEASE_PLAN.md       archived IMP entries from Close step)
│   └── ...

Projects/
├── _Skill-Packages/             ← Skill file lifecycle (see Skill Build Protocol)
│   ├── [skill].skill            ← Production .skill packages (one per skill)
│   ├── _working/[version]/      ← Release build staging (transient)
│   └── _previous/[skill]/       ← One-deep previous version (overwrite model)
```

**Naming convention:** `[version]_RELEASE_PLAN.md` — no subfolders per release.

---

## Lifecycle

1. **Intake** — Skill identifies gap → creates a GitHub Issue with structured fields (status: Proposed)
2. **Triage** — User reviews weekly → Approve, Reject, or Defer each item
3. **Bundle** — User groups approved items into a release (e.g., v5.1). System generates `[version]_RELEASE_PLAN.md` with full implementation details per IMP.
4. **Plan review** — User reviews/iterates the plan before execution
5. **Dry run** — Before execution, produce a diff preview for every affected file (see "Dry-Run Protocol" below). User reviews actual content changes — not just the plan description — and confirms execution. This step cannot be skipped.
6. **Snapshot** — Create timestamped copies of all files that will be modified (see "Pre-Change Snapshot Protocol" below). Snapshots provide rollback capability if the release introduces a regression.
7. **Execute** — Changes implemented per plan. Each issue status → In Progress → Implemented
8. **Close** — (a) Close GitHub Issues with verification evidence and release version. (b) Add release summary row to RELEASE_LOG.md Recent Releases section. If Recent Releases exceeds 5 entries, move the oldest entry to the Release History table. (c) If the release modified skill files, execute the Skill Build Protocol's rebuild and cleanup steps. (d) Author or verify the user-facing release note at `release/releases/notes/vX.Y_RELEASE_NOTES.md` per [`release/references/standards/release-notes-standard.md`](../references/standards/release-notes-standard.md) — distinct artifact and audience from `RELEASE_LOG.md` (engineering audit trail). Milestone close gates on note presence + structural lint pass per the release-notes standard. Release plan file serves as implementation audit trail. (e) A "Gate-Passage Proof" comment is recorded on the Stage 13 Close sub-task before Milestone close per the gate-passage-proof protocol. The comment lists each gated output with its verification command result, creating single-glance audit evidence durable in the sub-task comment thread. Operational mechanism: [`release/references/how-to/hub-spoke-bridge.md`](../references/how-to/hub-spoke-bridge.md) Procedure 7 §Gate-passage proof recording. *Cutover discipline: Applies to all releases going forward.*
9. **Verify** — Optional QA audit or regression test. Release marked VERIFIED in RELEASE_LOG.md.

---

## Change Description Protocol

A `## Change Description` section is embedded in every release plan FILE (`release/releases/plans/vX.Y_RELEASE_PLAN.md`) to provide an operator-readable, git-resident, pre-merge summary of what the release delivers. The section is authored by the Stage 6 release-engineering spoke as part of PR creation and is visible at Stage 9 Plan Review in the PR diff.

**Distinct artifact.** This section is NOT the user-facing release note (which lives at `release/releases/notes/vX.Y_RELEASE_NOTES.md`, authored at Stage 13 Close per [`release/references/standards/release-notes-standard.md`](../references/standards/release-notes-standard.md)). The Change Description targets the operator at pre-merge time with engineering-OK voice; the release note targets non-technical platform users at post-merge time with voice-constrained framing per the release-notes standard. Both artifacts ship per release; they reference each other but do not substitute.

**Three-artifact chain.** The Change Description complements the Stage 3 Release Outcome Statement (authored at Stage 3 Phase B3 and embedded in the GitHub Milestone description as `### Release Outcome Statement` H3 per [`release/references/specs/release-outcome-statement-template.md`](../references/specs/release-outcome-statement-template.md)) — Outcome anchors pre-execution intent (future-tense capability statement); Change Description summarizes post-implementation delivery (past/present-tense engineering narrative); release notes target end users at post-merge time. Each artifact answers a different question for a different audience at a different point in the release lifecycle.

**Trigger stage.** Stage 6 (release-engineering spoke), as part of PR creation. The section is appended to the release plan FILE on the release branch BEFORE the PR is marked ready-for-review. If Stage 7/8 surface material changes (Tier 1 [ADJUST] fix commits that change which issues land or which D-decisions stand), the section is refreshed in a subsequent commit on the release branch using the existing release-plan-FILE-update discipline.

**Section heading.** `## Change Description` (verbatim, per the originating issue's acceptance criteria AC1).

**Location.** Appended at the bottom of the release plan FILE, after the "Verification Evidence" section and "Deployment Execution Log" section. No subfolders; no new file class.

**Required sub-sections (in order):**

| § | Sub-section | Required? | Length | Content |
|---|---|---|---|---|
| 1 | **Outcome** | Required | 2-3 sentences | What this release delivers in plain-but-engineering-OK language. Lead with operator-facing capability. |
| 2 | **Issues resolved** | Required | Table | Per-row: `# / one-line outcome / status (DONE / PARTIAL / DEFERRED)`. Operator-readable per-line outcome. |
| 3 | **Key decisions** | Conditional (omit when no D-decisions rendered) | Bullet list | Per D-decision: verdict + one-line rationale; link to release plan § Hub-Rendered D-Decisions row. |
| 4 | **Reversibility** | Required | One sentence | Tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) + confidence (HIGH / MEDIUM / LOW) + rollback mechanism. Maps to [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "Reversibility discipline." |
| 5 | **Downstream impact** | Required | Bullet list | What this release enables in the next release; affected surfaces; carry-forward items. |
| 6 | **Cross-references** | Required | Bullet list | Links to: release plan top, milestone (GitHub URL), user-facing release notes path. |

**Length target.** ~60 lines (40 lines minimum, 100 lines maximum). Single-screen-readable target for operator scan at Stage 9 Plan Review.

**Voice rules.**

1. **Operator-facing, engineering-OK.** Engineering nouns, internal IDs, skill names, file paths permitted. The operator reads SKILL.md files; the audience contract permits engineering language.
2. **Specificity rule.** No "various improvements," no "minor enhancements," no quality adjectives without measurement.
3. **Fabricate-or-omit.** Omit a sub-section rather than fill it with generalized content. The conditional Key decisions sub-section is omitted when no D-decisions are rendered; do not invent.
4. **No marketing voice.** No enthusiasm, no customer quotes, no named credit fabrication.
5. **Reversibility sub-section is mandatory.** Every release has a reversibility posture; this sub-section is never omitted.
6. **No strikethrough.** Per [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "No strikethrough in generated artifacts."

**Template.** The Change Description section template lives at [`release/skills/release-planner/references/release-plan-template.md`](../skills/release-planner/references/release-plan-template.md) as part of the release plan template. The Stage 6 spoke fills in placeholders during PR creation.

**Backfill.** Existing release plans (before the cutover) do not need retroactive Change Description sections. The protocol applies prospectively.

**Cutover discipline:** Applies to all releases going forward.

**Reversibility (of this protocol).** CHEAP / HIGH confidence — `git revert` on the release PR reverses the protocol section + template addition + Stage 6 cross-references cleanly; existing Change Description sections (one per post-cutover release) remain as historical record.

**Origin.** Operator observation 2026-04-21: difficulty understanding what agents are building to close gaps.

---

## Versioning (Semantic)

- **Major (X.0):** New skills, structural changes, protocol rewrites
- **Minor (X.Y):** Skill updates, reference doc changes, tracker schema changes
- **Patch (X.Y.Z):** Typos, small corrections, documentation fixes

### Versioning Decision Table

| Change Type | Version Bump | Rationale |
|-------------|-------------|-----------|
| New skill added to the suite | **Major** | New capability changes what the platform can do |
| New governance file created | **Major** | Structural change to workspace architecture |
| Skill behavioral change (new mode, altered processing logic) | **Major** | Changes how an existing skill operates; may affect downstream flows |
| Governance file structural rewrite | **Major** | High-impact change to platform rules |
| Skill configuration update (description, trigger phrases, reference docs) | **Minor** | Changes inputs/documentation but not core behavior |
| Protocol text addition or modification | **Minor** | New rules or rule changes within existing structure |
| Tracker schema change | **Minor** | Data structure change within existing trackers |
| Reference document addition or update | **Minor** | Supporting material, not core behavior |
| Typo fix, formatting correction | **Patch** | No behavioral or structural impact |
| Documentation wording clarification (no rule change) | **Patch** | Improves clarity without changing meaning |

---

## IMP Entry Requirements

Every IMP entry must contain enough information to generate a detailed implementation plan without re-reading the original conversation. Required fields: Description, Evidence, Affected Files, Proposed Change, Dependencies, Acceptance Criteria.

---

## Implementation Plan Format

When a release is planned, generate `Releases/[version]_RELEASE_PLAN.md` documenting: what files change, what specific changes, what sequence, why each change (traced back to IMP evidence), and acceptance criteria per item.

**Bundle composition doctrine.** The release-bundle's composition (WHAT belongs in the release and WHY those items cohere as a shippable unit) follows the 7-step vertical capability slice methodology per [`release/references/standards/bundle-composition-doctrine.md`](../references/standards/bundle-composition-doctrine.md). The doctrine codifies: 7-step method (Name capability AFTER/BEFORE → list tickets → walk dep graph backward → check older milestones → size-check at 15-25 pts target → declare internal sequence → declare external deps ≤ 2); tight-merge mechanics for oversized parents (split + re-merge only with internal dep edges); naming convention (`v<MAJOR>.<NN-padded>-<capability-slug>`); 6 worked-example composition shapes (capability-slice / hotfix / audit-driven / cleanup-debt / new-track-inaugural / subsumption-fission); milestone description required-fields schema (Outcome + Class + Scope + Internal sequence + Dep Exceptions + A6 conditional + Amendment Log conditional + Bundle Composition Frame optional). **Current default frame per platform config:** F1 SAFe Feature-Slicing + Vertical Slice methodology; frame is swappable on milestone-creation and milestone-update via the unified pmo-platform global config mechanism per a forthcoming enhancement without rewriting doctrine prose. Implementation plan generation reads doctrine-derived fields from the milestone description (per `release-planner` SKILL.md Mode B persistence). **Cutover discipline:** Applies to all releases going forward.

### Lifecycle Definition Requirement

For every new file, folder, or data structure introduced in a release, the implementation plan **must** include a Lifecycle Definition answering these six questions:

1. **Growth pattern** — How does this artifact grow over time? (e.g., "one entry per release," "grows with project count," "fixed size")
2. **Size discipline** — Is there a cap? What happens when exceeded? (e.g., "120-line cap, overwrite model," "< 500 lines, extract to references/")
3. **Cleanup trigger** — What triggers maintenance? (e.g., "after each release," "every 30 days," "N/A — permanent")
4. **Archive path** — Where does content go when it ages out? (e.g., "Releases/_snapshots/," "move to Archive/," "delete after promotion")
5. **Ownership** — Who is responsible for maintenance? (e.g., "platform-level," "project-scoped — project owner," "skill-specific")
6. **Exit conditions** — When is this artifact retired? (e.g., "when the project closes," "when superseded by v2," "never — permanent infrastructure")

Plans that introduce new artifacts without lifecycle definitions are **rejected during review** as incomplete. This requirement applies to all new files, folders, reference documents, skills, trackers, and data structures — not just governance files.

Existing artifacts created before this requirement are grandfathered but should have lifecycle definitions added when they are next modified in a release.

### Release Scope Validation

Every release change manifest (the list of files modified in a release plan) must pass boundary validation before execution:

1. **No Layer 2 paths in release manifests.** Release plans govern Layer 1 (platform) files. If a release plan lists a file under `Projects/` (Layer 2) or `<OPERATOR_INSTANCE_SKILLS_PATH>/` (Layer 2 deployment target), the plan must be corrected before proceeding. Exception: bridge files (Layer 3) may appear in release manifests when the change is to their schema or structure — not their operational content.
2. **Skill Build Protocol handles deployment.** When a release modifies skill source files (Layer 1, in `release/skills/`), the Skill Build Protocol stages files for user-mediated copy to `<OPERATOR_INSTANCE_SKILLS_PATH>/` (Layer 2). The release manifest lists the Layer 1 source path, not the Layer 2 deployment target.
3. **Validation timing.** Scope validation runs during plan review (Step 4) and again during dry-run (Step 5). Both gates must pass.

---

## Dry-Run Protocol

Before executing any approved release, the agent produces a diff preview for every affected file. The user reviews actual content changes — not just the plan description — before confirming execution.

**Required for:** All releases that modify governance files (CLAUDE.md, OPERATIONS.md, PORTFOLIO.md, SESSION_STATE.md, RELEASE_PROTOCOL.md), skill files (SKILL.md), or protocols. Exempt: operational file updates (Tier 2/3) that follow their own approval flow.

**Diff preview format per file:**
1. **File path** and section being modified
2. **Before block:** The exact current content (with line numbers) that will be replaced or removed
3. **After block:** The exact new content that will be written
4. **Context:** 5 lines above and below the change for surrounding awareness
5. **Conflict check:** Flag any potential conflicts with adjacent rules, existing guardrails, or other IMP items in the same release
6. **Impact note:** Which skills, protocols, or processing flows are affected by this specific change

**For complex releases (5+ file changes or structural changes), also include:**
7. **Cross-file impact assessment:** How changes in one file affect behavior defined in another
8. **Regression risk identification:** Specific scenarios where the change could break existing behavior

**Rules:**
- The dry-run step cannot be skipped — it is a mandatory part of the release lifecycle.
- The user must explicitly confirm after reviewing the diff preview: "proceed" or "approved" or equivalent.
- If the user requests modifications to the diff, iterate the preview until approved.
- Diff previews are included in the release plan file (appended as a "Dry-Run Record" section) for audit trail.

---

## Pre-Change Snapshot Protocol

Before executing any release, create timestamped copies of all files that will be modified. Snapshots provide a clean rollback point if a release introduces a regression.

**Storage:** `Releases/_snapshots/[version]/[filename]_pre_[version].md`

Example: Before v5.1 modifies PMO.md → create `Releases/_snapshots/v5.1/PMO_pre_v5.1.md`

**Rules:**
1. Snapshot every file listed in the release plan's "Affected Files" before any modifications begin.
2. Snapshots are read-only reference — never modified after creation.
3. For files under 500 lines: snapshot the entire file.
4. For files over 500 lines: snapshot the entire file (storage is cheap; partial snapshots risk incomplete rollback).
5. The snapshot step occurs after dry-run approval and before execution begins. No file is modified until all snapshots are confirmed written.

**Retention policy:**
Snapshots follow a rolling-window retention model to prevent unbounded growth:
1. **Active window — last 15 releases:** Full snapshots retained. These are the "hot rollback" targets for regressions. At current release velocity, 15 releases covers approximately 2-3 weeks of active development.
2. **Beyond 15 releases:** Snapshot folders are pruned. The release plan file (which contains before/after diffs in the Dry-Run Record) serves as the permanent audit trail — it documents *what changed* without storing full file copies indefinitely.
3. **Pruning trigger:** During the Snapshot step (Step 6) of each new release, check `Releases/_snapshots/`. If more than 15 release version folders exist, delete the oldest. This keeps the snapshot directory at a constant size of ~15 versions.
4. **Rollback exception:** Any snapshot folder tied to a release marked `ROLLED BACK` in RELEASE_LOG.md is exempt from pruning and retained until the rollback is fully resolved and the release is re-closed.
5. **Manual override:** The user may mark any snapshot folder as `RETAIN` (add a `_RETAIN` file to the folder) to exempt it from automatic pruning indefinitely.
6. **Release plan file retention:** Release plan files follow the same rolling 15-release window. When more than 15 release plan files exist in `Releases/`, the oldest are moved to `Releases/_archive/`. RELEASE_LOG.md (which contains the complete release history in its Release History table) serves as the permanent index for finding archived release plans.

**Rollback protocol:**
If a regression is detected post-release:
1. Identify the affected file(s) and the release that introduced the regression.
2. If the release is within the active window (last 15): retrieve the pre-change snapshot from `Releases/_snapshots/[version]/`.
3. If the release is older than the active window: use the Dry-Run Record in the release plan file to reconstruct the pre-change state, or check if the nearest available snapshot can serve as a baseline.
4. Diff the current file against the snapshot (or reconstructed state) to isolate the regression.
5. Propose rollback (restore snapshot content) or targeted fix.
6. User approves rollback or fix.
7. Document the rollback in RELEASE_LOG.md with: release version, file(s) rolled back, reason, and date.

**Verification:** After creating snapshots, confirm each file exists at the expected path before proceeding to Execute. If any snapshot write fails, halt the release.

---

## Skill Build Protocol

When a release modifies skill files (SKILL.md or reference files), the agent cannot write
directly to `.skills/skills/` (read-only filesystem). This protocol standardizes the build,
staging, delivery, and confirmation lifecycle for skill file updates.

**Infrastructure:** `Projects/_Skill-Packages/` serves as the single home for all skill file
lifecycle stages:

```
_Skill-Packages/
├── [skill-name].skill              ← Production .skill packages
│                                      (one per skill, canonical name)
├── _working/                        ← Release build staging
│   └── [version]/
│       └── [skill-name]/
│           ├── SKILL.md             ← Complete rebuilt skill file
│           └── references/          ← If reference files also changed
└── _previous/                       ← One-deep previous version
    └── [skill-name]/                   (overwrite model)
        └── SKILL.md
```

**Build lifecycle (executed during Step 7 — Execute):**

1. **Build:** For each skill modified in the release, agent reads the current installed file
   from `.skills/skills/[skill-name]/SKILL.md`, applies all changes from the release plan,
   and writes the **complete rebuilt file** to
   `_Skill-Packages/_working/[version]/[skill-name]/SKILL.md`.
   No "insert after line X" instructions. No partial diffs. Complete files only.
   If reference files are also modified, include them in the same skill subfolder.
   Each rebuilt file sets the `version:` field in frontmatter to the release version (e.g., `version: v6.3`). Add the field if missing; update if present. No content (comments, whitespace, or markup) may appear before the opening `---` frontmatter delimiter — this breaks YAML parsing.

2. **Archive previous version:** Agent copies the current installed version (from
   `.skills/skills/[skill-name]/SKILL.md`) to
   `_Skill-Packages/_previous/[skill-name]/SKILL.md`, overwriting whatever was there.
   One-deep only; no version accumulation. This preserves the pre-update version before
   the user overwrites it in Step 4.
   (On the first-ever update cycle for a skill, `_previous/` will be empty — this step
   creates the initial entry.)

3. **Present:** Agent links each staged file via `computer://` with explicit copy instruction:
   "Copy `_Skill-Packages/_working/[version]/[skill-name]/SKILL.md`
   → `.skills/skills/[skill-name]/SKILL.md`"

4. **User confirms "saved to skills":** User copies files to `.skills/skills/` and confirms
   completion. This is the gate — no downstream steps execute until the user confirms.

5. **Rebuild .skill package:** Agent rebuilds the `.skill` package for each updated skill
   and places it at `_Skill-Packages/[skill-name].skill` (production, canonical name,
   no version suffix), overwriting the previous package.

6. **Clean working directory:** Remove `_Skill-Packages/_working/[version]/` after all
   skills are confirmed saved and packages rebuilt.

**Version tracking:** The `version:` field in each skill's frontmatter records which release last modified it (e.g., `version: v6.3`). During drift detection, the agent can compare this field against RELEASE_LOG.md to confirm skills are current. The `version:` field is not a recognized Claude Code frontmatter field — it is inert metadata for platform tracking purposes. It does not affect skill behavior, invocation, or display.

**Post-copy verification checklist (included in each release plan that modifies skills):**
For each modified skill:
- [ ] `_working/[version]/[skill-name]/SKILL.md` staged with complete rebuilt content
- [ ] `_previous/[skill-name]/SKILL.md` contains the pre-update version
- [ ] User confirmed "saved to skills"
- [ ] `_Skill-Packages/[skill-name].skill` rebuilt and current
- [ ] `_working/[version]/` cleaned

**Retention:**
- `_working/` is transient — cleaned after each release's "saved to skills" cycle.
- `_previous/` is overwrite-only — always contains exactly the last replaced version per skill.
- Production `.skill` packages at top level are permanent and current.
