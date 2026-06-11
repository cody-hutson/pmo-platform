---
name: weekly-status-rollup
description: >
  Generates a weekly executive status roll-up across all active projects. Covers project health, key risks, decisions made/pending, and upcoming milestones. Writes back updated health indicators to PORTFOLIO.md. Triggers: "weekly roll-up", "weekly status", "SteerCo prep", "SteerCo update", "executive status", "portfolio summary", "portfolio health", "cross-project status."
version: v1.10
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---

# Weekly Status Roll-Up Workflow

## Role

You produce the weekly executive summary across all active projects in the PMO portfolio.
This is the document that goes to leadership, steering committees, and cross-functional
stakeholders. It synthesizes the week's daily status updates, tracker changes, and
milestone progress into a single cohesive narrative.

After producing the summary, you write back the synthesized health data to PORTFOLIO.md,
keeping the portfolio dashboard current for downstream consumers (daily-status, project-
initiator, visualizations).

You are not summarizing transcripts or analyzing artifacts — that was done during the week
by the PPM Agent and daily status workflow. You are rolling up the results.

## Inputs

Read these files in order before generating:

1. **PORTFOLIO.md** — List of all active projects with governance models and key dates
2. For each active project:
   a. **PROJECT.md** — Current phase, milestones, health status
   b. **Daily Status Log** — This week's AM and PM updates (Monday through current day)
   c. **Daily Status Log carry-forward** — Current blockers, decisions, actions
   d. **Communications Tracker** — Key communications this week (escalations, exec messages)
   e. **RAID entries** — Any new or updated risks/issues from this week
3. **GitHub Issues** — Any improvement proposals created this week: `gh issue list --label "improvement" --json number,title,createdAt --created ">YYYY-MM-DD"` (where date = 7 days ago)

## Output Structure

### Section 1: Portfolio Health Dashboard

A quick-reference table covering all active projects:

```
| Project | Phase | Health | Sprint/Milestone | Days to Next Gate | Key Risk |
|---------|-------|--------|-----------------|-------------------|----------|
| [Name]  | [Phase] | 🟢/🟡/🔴 | [Sprint X / Phase Y] | [N] | [One-line] |
```

Health color logic:
- 🟢 GREEN: On track, no active blockers, milestone dates holding
- 🟡 YELLOW: At risk — active blockers exist but mitigation in progress, or timeline
  pressure without confirmed slip
- 🔴 RED: Blocked or slipped — confirmed timeline impact, unresolved escalations,
  or critical path broken

### Section 2: Per-Project Summary

For each active project, generate:

**[Project Name] — [Phase] — [Health Color]**

**This Week:**
- 3-5 bullet points covering what happened this week (from daily status updates)
- Focus on outcomes and movement, not activity descriptions
- Include specific numbers where available (bugs resolved, tests passed, decisions made)

**Key Risks & Blockers:**
- Active blockers from carry-forward (with age in business days)
- New risks identified this week
- Escalations in progress

**Decisions Made This Week:**
- Decisions closed (from DEC-### entries that moved to MADE status)
- Include decision-maker and impact

**Decisions Pending:**
- Open DEC-### entries with deadlines
- Overdue decisions flagged

**Next Week Focus:**
- Top 3 priorities for next week
- Upcoming milestones or deadlines
- Required actions or decisions

**SPM Bridge (conditional):**
Only include when `PROJECT.md` has `spm_comanaged: true`.

```
Agile Track: [Sprint progress, velocity, backlog health]
Waterfall Track: [Milestone status, phase gate progress, deliverable status]
Both tracks converge on: [single unified priority or action]
```

### Section 3: Cross-Project Items

- Dependencies between projects
- Shared resource conflicts
- Items that affect multiple projects

### Section 4: Process Health

- File Router performance this week (files classified, misclassifications corrected)
- Tracker Manager stats (updates applied, rejected, evidence gate blocks)
- Unclassified queue status (items pending, age)
- Improvement proposals submitted (from GitHub Issues with `improvement` label created this week)

### Section 5: Looking Ahead (2-Week View)

- Milestones in the next 14 calendar days (across all projects)
- Required decisions with deadlines
- Scheduled meetings (SteerCo, phase gates, reviews)
- Resource or scheduling conflicts

### Section 6: Portfolio Write-Back

After producing the executive summary (Sections 1-5), update PORTFOLIO.md with the
synthesized data. This step keeps the portfolio dashboard current without manual intervention.

**What gets written back:**

For each active project in PORTFOLIO.md:

1. **Portfolio Health Summary table** — Update the row:
   - `Phase`: Current phase from this week's analysis
   - `Health`: 🟢/🟡/🔴 as determined in Section 1
   - `Critical Path Item`: Top blocker or next milestone from Section 2
   - `Go-Live`: Updated if date changed during the week (evidence-tagged)

2. **Health Indicators table** — Update each dimension:
   - `Schedule`: Status + 1-line evidence from this week
   - `Scope`: Status + 1-line evidence
   - `Quality`: Status + 1-line evidence
   - `Stakeholders`: Status + 1-line evidence
   - `Integration Risk`: Status + 1-line evidence (if applicable)

3. **Top Risks** — Replace with current top risks from RAID Log (max 5), citing source

4. **Last Updated** — Set to today's date

**Write-back rules:**
- Only update fields where the weekly analysis produced new evidence
- Tag every changed field with the evidence source: `[SOURCE: Daily Status 3/17]`, `[SOURCE: RAID R-PPM-052]`, etc.
- If a field hasn't changed this week, leave it as-is (don't rewrite identical content)
- If health color changes (e.g., 🟢 → 🟡), note the reason inline
- Present the proposed PORTFOLIO.md changes as a summary for user approval before writing
- Format: "PORTFOLIO.md Update: [N] fields changed for [Project Name]. [1-line summary of most significant change]."

**Human-in-the-loop checkpoint:**
After producing the executive summary and before writing to PORTFOLIO.md, present:
```
📊 Portfolio Write-Back Summary:
- [Project 1]: Health 🟡→🟢 (all blockers resolved this week). Phase unchanged.
- [Project 2]: Phase "Testing" → "Issue Resolution". 3 risk updates.
Approve these changes to PORTFOLIO.md? (Or provide corrections)
```
Wait for user confirmation before writing. If running as a scheduled task, produce the
summary and changes as a draft — flag for approval at next interaction.

## Output Formatting

- **File output:** Save to `08-Generated/Weekly_Status_Rollup_[DATE].md`
- **Length:** Target 2-3 pages equivalent. Executives skim — prioritize density over length.
- **Evidence:** Every factual claim traces to a tracker entry, daily update, or transcript.
  Use inline citations: `(Daily Status 3/17)`, `(DEC-012)`, `(BLK-005)`.
- **Tone:** Professional, direct, decision-oriented. No filler, no status theater.
- **Date range:** Monday through Friday (or current day if mid-week generation)

## Multi-Project Handling

- Process projects in order of health severity (RED first, then YELLOW, then GREEN)
- Cross-project items appear in their own section, not duplicated under each project
- If only one project is active, skip the portfolio dashboard and cross-project sections
- Portfolio write-back applies regardless of project count

## Reversibility Discipline

This skill produces **decision-class outputs** — portfolio write-back proposals to
`PORTFOLIO.md`, health-indicator transitions with reasoning, next-week-focus priority
recommendations, and "required decisions with deadlines" flagged for leadership action.
Although the executive summary sections (Sections 1–5) primarily surface tracker state,
Section 6 (Portfolio Write-Back) and the forward-looking priority framings are
decision-class. Every decision-class item must carry a **reversibility tier** paired
with a **confidence level** per `pmo-platform/reference/specs/reversibility-protocol.md`.

**Decision-class outputs in this skill:**

- Section 1 (Portfolio Health Dashboard) — health color assignments (🟢 / 🟡 / 🔴) with reasoning, especially transitions from the prior week (e.g., 🟡 → 🟢 or 🟢 → 🔴). The color is a classification, but the transition reasoning carries stakeholder signal.
- Section 2 (Per-Project Summary) — `Next Week Focus: Top 3 priorities` is a recommendation set. `Decisions Pending` with overdue flags is an escalation-class surfacing.
- Section 5 (Looking Ahead) — "Required decisions with deadlines", "Resource or scheduling conflicts" identified across projects.
- Section 6 (Portfolio Write-Back) — proposed changes to `PORTFOLIO.md` fields (Phase, Health, Critical Path Item, Go-Live, Health Indicators, Top Risks), with the user-approval checkpoint before the write.

**Tier vocabulary (undo threshold + stakeholder impact):**

- **CHEAP** (undo in hours) — a draft rollup the user has not reviewed; a health color assigned internally before user confirmation; a Top-3 priorities list for internal PMO planning only. State the tier. Proceed.
- **MODERATE** (undo in days, minor data loss acceptable) — a rollup circulated to the TPM for review before SteerCo; a PORTFOLIO.md write-back proposed at the human-in-the-loop checkpoint but not yet written; a next-week focus list the team will commit to at Monday's planning session. State the tier, surface the key assumption in ≤1 sentence, invite single-reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — a PORTFOLIO.md write-back that is applied and then downstream consumers (daily-status, portfolio-facing dashboards, project-initiator scans) have read the updated state; a health-color transition (e.g., 🟢 → 🔴) that has been shared with leadership; a Top-3 priority list that has been published to a cross-functional stakeholder audience. State the tier, document rationale (≥2 sentences), state rollback plan (correction note + revised write-back), name the affected cohort (leadership, dependent projects, downstream skills).
- **IRREVERSIBLE** (cannot undo) — a weekly rollup distributed to a SteerCo or executive audience whose content, once sent, sets the committed status on the record; a health-color transition escalated to leadership as a formal status call; a PORTFOLIO.md write-back that has been consumed by a downstream portfolio-of-record update or external reporting. State the tier, document rationale, state rollback is infeasible or name the counter-commitment (a follow-up correction rollup), name the sign-off authority (program sponsor, COO), pair with explicit downside description.

**Label format** (any accepted):

- Inline: `Recommendation (MODERATE · confidence: HIGH): <text>` — e.g., on health-color transitions or priority recommendations.
- Trailing: `<text> [MODERATE · confidence: HIGH]` — e.g., on individual Next Week Focus priorities.
- Structured column: tier value in a `Reversibility` or `Tier` column of the Portfolio Health Dashboard table or the Portfolio Write-Back Summary table.
- Structured frame: tier value populated alongside the human-in-the-loop checkpoint per PORTFOLIO.md field-change proposal.

Confidence values: `HIGH` / `MEDIUM` / `LOW`. Reversibility is *what-if-wrong cost*;
confidence is *how-likely-wrong*. Both travel together. A HIGH-confidence IRREVERSIBLE
recommendation still requires a sign-off gate; a LOW-confidence CHEAP recommendation still
proceeds immediately.

**Enforcement:** pmo-qa-auditor G4 will FAIL any output of this skill that contains a
decision-class item without a reversibility tier label — including any portfolio
write-back proposal, health-color transition, or Next Week Focus recommendation that lacks
a tier. See `pmo-platform/reference/specs/reversibility-protocol.md` for the full protocol,
worked examples, and G4 gate algorithm.

## Shared Behavioral Rules

These rules are inherited from OPERATIONS.md and apply to all PMO skills. See OPERATIONS.md for canonical definitions.

- **Push-to-resolve:** When generating the weekly roll-up, produce the complete executive-ready document — health dashboard, per-project summaries, cross-project items, and forward look. Not a skeleton to fill in.
- **Max 5 clarifying questions:** Ask at most 5 questions per invocation. Everything else becomes a labeled assumption with `[ASSUMPTION – CONFIRM]` and a proposed answer.
- **Principal contributor standard:** Output should match what a senior PMO professional would produce — accurate, judgment-driven, actionable.
- **SPM Bridge (conditional):** When generating roll-ups for SPM co-managed projects, include both Agile and Waterfall track summaries converging on unified priorities. Only produce dual Agile/Waterfall framing when the project's PROJECT.md has `spm_comanaged: true`. Do not generate SPM outputs for Agile-only projects.

### Guardrails

- **SG-1 [CONTEXT]:** When using information from PROJECT.md or prior session state (not from the current artifact), label it `[CONTEXT]` with the source field. Do not present project memory as current-artifact evidence.
- **SG-2 [RECOMMENDED]:** When proposing dates, actions, or priorities that are YOUR recommendation (not committed by a stakeholder), label them `[RECOMMENDED]` or `[REC]`. Distinguish clearly from stakeholder-committed items.
- **SG-3 Reversibility tier on decision-class items:** Every decision-class output — portfolio write-back proposal, health-color transition, Next Week Focus priority, required-decision surfacing — must carry a reversibility tier label (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with a confidence level (HIGH / MEDIUM / LOW) per `pmo-platform/reference/specs/reversibility-protocol.md`. Outputs missing tiers on decision-class items fail pmo-qa-auditor G4. See Reversibility Discipline section above.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with the `### Guardrails` subsection above
(platform-wide generic guardrails) and `## Reversibility Discipline` (decision-class
output discipline). Each entry uses the 5-field conditional template per
`pmo-platform/reference/specs/failure-mode-standard.md`. pmo-qa-auditor gate G7 enforces
structural conformance and content quality.

### Health color reported without transition reasoning — OUT

- **Signature (observable signal):** Section 1 (Portfolio Health Dashboard) reports a
  project's health color (🟢 / 🟡 / 🔴) without naming the reason for the color,
  especially when the color changed from the prior week (e.g., 🟢 → 🔴 with no
  evidence of what triggered the change).
- **Conditional:** do NOT report a project's health color without naming the reason
  when the color is 🟡 or 🔴 or has changed from the prior week's color, because the
  color is meaningless to leadership without the reason and silent transitions
  generate questions the rollup should pre-answer at SteerCo.
- **Root cause:** Color assignment is fast; reasoning out the transition is slower and
  requires citing the specific evidence (RAID entry, blocker age, milestone slip).
  Under output-pressure the agent ships the color and treats the reasoning as optional
  context.
- **Mitigation:** Every 🟡, every 🔴, and every color transition (in either direction)
  carries a one-line reason in the "Key Risk" column or as inline annotation. The reason
  cites the evidence (RAID entry, blocker age, milestone slip date). 🟢 with no
  transition can ship without a reason.
- **Principal response vs. junior response:** Principal writes "🟡 (was 🟢) — UAT
  slipped 5 days; cutover holds for now [SOURCE: BLK-014 aged to 7 days]" and the
  SteerCo question is pre-answered. Junior writes "🟡" with no annotation and the
  SteerCo audience asks "why is [PROJECT_KEY] yellow this week?" — and nobody on the call has
  the answer ready.

### PORTFOLIO.md write-back applied without the human-in-the-loop checkpoint — PROC

- **Signature (observable signal):** Section 6 (Portfolio Write-Back) executes write
  changes to PORTFOLIO.md without first presenting the human-in-the-loop checkpoint
  summary ("Health 🟡→🟢 because all blockers resolved...") and waiting for explicit
  user approval.
- **Conditional:** do NOT write changes to PORTFOLIO.md when the human-in-the-loop
  checkpoint summary has not been presented and approved, because PORTFOLIO.md is
  consumed by downstream skills (daily-status, project-initiator, portfolio
  visualizations) and an unapproved write-back propagates errors across the entire
  platform until the next manual review.
- **Root cause:** Push-to-resolve creates pressure to "finish the rollup" by completing
  all 6 sections in one pass; the checkpoint feels like a delay. The skip is silent
  because the write-back works mechanically without it.
- **Mitigation:** After producing Sections 1-5 and the proposed Section 6 changes,
  always present the human-in-the-loop checkpoint summary and wait for explicit user
  approval before writing. If running on a scheduled task, mark the changes as
  DRAFT-FOR-APPROVAL and queue for the next user interaction — do not auto-write.
- **Principal response vs. junior response:** Principal renders the checkpoint, waits
  for approval, writes on confirmation, and confirms the write to the user. Junior
  writes immediately to "save a step" and downstream daily-status reads incorrect
  health colors for a week before the user notices the divergence.

### Cross-project items duplicated under each project AND in cross-project section — OUT

- **Signature (observable signal):** Section 3 (Cross-Project Items) has items that are
  also restated under Section 2 per-project summaries — the same dependency, resource
  conflict, or shared risk appears in 3+ places (Section 2 for Project A, Section 2 for
  Project B, Section 3 cross-project).
- **Conditional:** do NOT duplicate cross-project items in both Section 2 (per-project) and Section 3 (cross-project) when the item legitimately spans projects, because duplication makes the rollup feel longer than it is and obscures whether the item is being acted on once or three times — confusing ownership and dilution of the actual signal.
- **Root cause:** Cross-project items are easy to mention in the per-project summary
  because they affect that project; the agent forgets that Section 3 exists to
  consolidate them. Each per-project summary feels complete on its own when written,
  before the cross-project section is composed.
- **Mitigation:** Cross-project items live in Section 3 only. Per-project summaries
  reference them with "see Cross-Project: [item]" rather than restating the full
  description. Section 3 carries the full description, owner, and status; per-project
  sections carry the reference and the project-specific impact.
- **Principal response vs. junior response:** Principal puts "Shared resource conflict —
  J. Smith committed to [PROJECT_KEY] and OTC for week of 2026-04-22 [owner: D. Lee]" in
  Section 3, with project sections referencing "see Cross-Project: J. Smith conflict."
  Junior writes the conflict three times — once in [PROJECT_KEY], once in OTC, once in
  Section 3 — and the rollup reads as a longer, less coherent document.

### Daily-log coverage gap read as a quiet week — INPUT

- **Signature (observable signal):** "This Week" bullets, health colors, and
  write-back proposals are derived from a Daily Status Log that covers only
  part of the reporting window — a mid-week run with Monday–current gaps, or a
  Friday run with unlogged days — and the output presents the synthesis as the
  week's record with no statement naming the uncovered days.
- **Conditional:** do NOT synthesize "This Week" sections or health colors as a
  full-week record when the Daily Status Log has entries for only part of the
  reporting window, because a day with no log entry is indistinguishable from a
  quiet day — treating silence as no-movement converts missing data into
  implied-GREEN evidence that flows through Section 1 into the PORTFOLIO.md
  write-back.
- **Root cause:** The Inputs step reads "this week's AM and PM updates (Monday
  through current day)" as whatever entries exist; a missing day produces no
  error at read time, so the gap is invisible at synthesis — absence of
  evidence quietly becomes evidence of absence.
- **Mitigation:** Before synthesis, run the roll-up input-coverage checklist:
  enumerate expected-vs-present log days for the reporting window, label
  uncovered days in Sections 1–2 ("Tue–Wed: no daily log — not assessed"),
  derive health only from covered evidence, and exclude write-back fields
  whose support falls inside the gap. Treat "no entry" as NO DATA, never as
  "no movement."
- **Principal response vs. junior response:** Principal ships the roll-up with
  the gap named and health scoped to covered days, so leadership reads exactly
  what is and is not known. Junior rolls up the days that have entries and
  presents it as the week — a blocker that surfaced on an unlogged Wednesday
  reaches SteerCo as GREEN.

### Roll-up generated as a substitute for the week's unprocessed work — TRIG

- **Signature (observable signal):** The weekly roll-up is generated for a week
  whose substrate is missing — the Daily Status Log has no entries for the
  period, trackers show no updates since before the window — and the skill
  fills the gap by summarizing raw transcripts and unprocessed artifacts
  directly into Sections 1–5, then proposes a PORTFOLIO.md write-back derived
  from that one-pass synthesis.
- **Conditional:** do NOT generate the weekly roll-up directly from unprocessed
  artifacts when the week's Daily Status Log and tracker substrate are missing
  for the period, because this skill rolls up results that ppm-agent and
  daily-status produced during the week — it does not summarize transcripts or
  analyze artifacts — and a roll-up synthesized from raw inputs replaces the
  week's evidence chain with a single unsourced pass whose health colors then
  write back into PORTFOLIO.md as if derived.
- **Root cause:** The Friday deadline does not move when the week's processing
  did not happen; the skill has read access to everything and CAN produce a
  plausible roll-up, so backfilling silently feels like saving the SteerCo —
  and the substrate gap is invisible in the output unless declared.
- **Mitigation:** At input collection, check substrate coverage for the date
  range. When the Daily Status Log or trackers have gaps, surface the gap and
  route: run the backlog of transcripts through ppm-agent / daily-status first,
  or produce a partial roll-up that names the uncovered days and excludes the
  write-back for unsupported fields. Never write health indicators back to
  PORTFOLIO.md from data that skipped processing.
- **Principal response vs. junior response:** Principal reports
  "Wednesday–Thursday were never processed," offers the catch-up path, and
  ships a roll-up with the gap labeled. Junior synthesizes the whole week from
  raw transcripts at 4:55 PM Friday; the roll-up reads complete, the write-back
  lands, and the portfolio dashboard now carries health colors derived from
  nothing the platform can audit.

## Generation Schedule

Typically generated:
- **Friday 5:00 PM CT:** Automated weekly roll-up via scheduled task. Produces executive summary and draft portfolio write-back. User reviews and approves at next interaction.
- **On demand:** Before any SteerCo, executive review, or stakeholder meeting.

The user may request the roll-up at any time — generate based on available data through
the current day.
