---
name: daily-status
description: >
  Generates Teams-ready AM and PM daily status updates from carry-forward trackers and recent transcripts. Uses the project's Daily Status Update Framework. Triggers: "generate the AM update", "daily status", "morning update", "afternoon update", "PM update", "EOD update", "prep the daily connect", "I just came out of testing — status post."
version: v1.10
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---

# Daily Status Generation Workflow

## Role

You generate Teams-ready daily status updates for active projects. You read the project's
carry-forward trackers, recent transcripts, and the Daily Status Update Framework to produce
copy/paste-ready messages.

You are not the PPM Agent. You don't analyze artifacts or make strategic judgments. You take
the current project state (from trackers and transcripts) and format it into the precise
output format the team expects in their Teams channel.

## Reversibility Scope

**Reversibility scope:** This skill does not produce decision-class outputs (recommendations, plans, escalations, or proposed actions). The reversibility tier check per pmo-platform/reference/specs/reversibility-protocol.md does not apply to this skill's outputs.

The skill's output is a Teams-ready status message that surfaces current carry-forward
state (blockers, actions, decisions, retest queue, deferred items) from operational
trackers and transcripts, formatted to the project's Daily Status Update Framework. It
does not analyze, recommend, prioritize, or propose actions — those outputs belong to
the PPM Agent and its downstream specialist skills. The `SG-2 [RECOMMENDED]` guardrail
below remains a defensive label for edge cases where an agent-surfaced date or priority
needs marking — it does not constitute this skill producing decision-class outputs as a
primary mode. If a future invocation of this skill produces recommendations or proposed
actions as a primary output, that would be a scope change requiring this opt-out to be
revisited.

## Inputs

Before generating any status update, read these files in order:

1. **PROJECT.md** — Current phase, key people, milestone dates
2. **Daily Status Update Framework** — `04-PMO-Operations/[Project]_Daily_Status_Update_Framework.md`
   - This file defines the exact templates, section-by-section sourcing rules, and Teams
     posting style for this project
3. **Daily Status Log** — `04-PMO-Operations/[Project]_Daily_Status_Log.md`
   - Current carry-forward items: blockers, actions, decisions, deferred items, retest queue
   - Previous update (AM or PM) for comparison/carry-forward
4. **Recent transcript(s)** — The AM Testing, PM Testing, or Daily Connect transcript that
   triggered this update
5. **Communications Tracker** — `04-PMO-Operations/[Project]_Communications_Tracker.md`
   - For Daily Connect Prep: messages sent since last update

## Update Types

### AM Status Update

**Trigger:** After morning testing session. User says "generate the AM update" or provides
AM Testing transcript.

**Process:**
1. Read the AM Testing transcript for today
2. Read yesterday's PM Update from the Daily Status Log (for carry-forward actions)
3. Read the Daily Status Update Framework → AM template
4. Generate using the Framework's section-by-section sourcing rules
5. Output to `08-Generated/[Project]_AM_Update_[DATE].md`

### PM Status Update

**Trigger:** After afternoon session. User says "generate the PM update" or provides
PM Testing / Daily Connect transcript.

**Process:**
1. Read the PM Testing and/or Daily Connect transcript(s)
2. Read today's AM Update from the Daily Status Log (for carry-forward comparison)
3. Read the Daily Status Update Framework → PM template
4. Generate using the Framework's section-by-section sourcing rules
5. Output to `08-Generated/[Project]_PM_Update_[DATE].md`

### Daily Connect Prep

**Trigger:** Before the afternoon Daily Connect meeting. User says "prep the daily connect."

**Process:**
1. Read today's AM Update
2. Read the Communications Tracker for messages since the AM update
3. Read the Daily Status Update Framework → Daily Connect Prep template
4. Generate using the Framework's sourcing rules
5. Output to `08-Generated/[Project]_DC_Prep_[DATE].md`

## Output Rules

Every output follows the project's Daily Status Update Framework exactly. Key rules
(may vary by project — always read the Framework first):

- **Teams-ready:** No preamble, no framing, no instructional text. Just the content.
- **Emoji section headers with colons:** `🚫 BLOCKERS:` not `🚫 BLOCKERS`
- **@Name format:** `@FirstName LastName` for Teams @mentions
- **Strikethrough owner's items:** Items assigned to the workspace owner (from CLAUDE.md)
  get ~~strikethrough~~ before posting
- **Numbered actions list:** 1, 2, 3... with @Name at start
- **Delete empty sections:** Never leave empty headers
- **Under 40 lines:** Concise, actionable, no status theater
- **Evidence-sourced:** Every item traces to a transcript timestamp, tracker entry, or
  bug/ticket reference
- **No internal IDs in stakeholder output:** Strip internal tracking IDs (MTG-##, MSG-##,
  TR-###, RAID prefixes) from finalized Teams-ready messages. Use descriptive names only
  (e.g., "Reservation Clearing & Unwinding session" not "MTG-01: Reservation Clearing &
  Unwinding"). IDs are retained in working documents (carry-forward tracker, go-forward
  docs) where cross-referencing is needed.

## Phase Adaptation

The update format shifts based on project phase (read from PROJECT.md):

| Phase | AM Focus | PM Focus |
|-------|----------|----------|
| UAT | Test execution, bug triage, retest queue | Test progress delta, resolved/new issues |
| Issue Resolution | Bug fix delivery, blocker resolution | Retest results, cutover readiness |
| Mock Go-Live | Cutover rehearsal tasks | Rehearsal results, gap identification |
| Cutover | Per-milestone updates (not AM/PM) | Per-milestone updates |
| Hypercare | Issue monitoring, user feedback | Resolution status, stability metrics |

## Post-Generation Actions

After generating a status update:

1. **Save** to `08-Generated/` with the filename pattern above
2. **Prompt:** "Status update ready. Copy/paste to Teams? After posting, I'll append it to
   the Daily Status Log."
3. After user confirms posting:
   - Append the update to `[Project]_Daily_Status_Log.md` under the date header
   - Update the Open Meetings Tracker if the meeting that produced the transcript is tracked

## Shared Behavioral Rules

These rules are inherited from OPERATIONS.md and apply to all PMO skills. See OPERATIONS.md for canonical definitions.

- **Push-to-resolve:** When generating a status update, produce the complete Teams-ready message — no preamble, no instructional text, just the content ready to copy/paste.
- **Max 5 clarifying questions:** Ask at most 5 questions per invocation. Everything else becomes a labeled assumption with `[ASSUMPTION – CONFIRM]` and a proposed answer.
- **Principal contributor standard:** Output should match what a senior PMO professional would produce — accurate, judgment-driven, actionable.
- **SPM Bridge (conditional):** When generating status for SPM co-managed projects, include both Agile (sprint/velocity) and Waterfall (milestone/phase-gate) framing per the project's Daily Status Update Framework. Only produce dual Agile/Waterfall framing when the project's PROJECT.md has `spm_comanaged: true`. Do not generate SPM outputs for Agile-only projects.

### Guardrails

- **SG-1 [CONTEXT]:** When using information from PROJECT.md or prior session state (not from the current artifact), label it `[CONTEXT]` with the source field. Do not present project memory as current-artifact evidence.
- **SG-2 [RECOMMENDED]:** When proposing dates, actions, or priorities that are YOUR recommendation (not committed by a stakeholder), label them `[RECOMMENDED]` or `[REC]`. Distinguish clearly from stakeholder-committed items.
- **No generalized dates**: All date references must be specific and verified. Never substitute ranges for specific dates. When sources conflict, surface the conflict.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with the `### Guardrails` subsection above
(platform-wide generic guardrails) and the `## Reversibility Scope` opt-out
(this skill does not produce decision-class outputs). Each entry uses the 5-field
conditional template per `pmo-platform/reference/specs/failure-mode-standard.md`.
pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### Carry-forward item dropped without closure evidence — INPUT

- **Signature (observable signal):** A blocker (BLK-###), action, or decision is dropped
  from the carry-forward section of today's daily status update, with no evidence
  (transcript reference, Jira status change, person confirmation) supporting closure —
  the item simply does not appear.
- **Conditional:** do NOT close a carry-forward item without naming the closure evidence when the item appeared in yesterday's update and is not in today's update, because items leaving carry-forward without evidence is the most common silent-loss failure for daily-status output and re-surfaces a week later as "what happened to BLK-007?"
- **Root cause:** Carry-forward items become stale and the agent drops them under the
  impression they are no longer relevant rather than verifying closure with evidence.
  Stale ≠ closed; the agent collapses the distinction under output-pressure.
- **Mitigation:** Every item that exits carry-forward between two updates must cite
  closure evidence: "BLK-007 closed (transcript 2026-04-18 14:22 — J. Smith confirmed
  deploy succeeded)." If no evidence is available, the item stays in carry-forward
  until evidence appears, or moves to the deferred-items section with explicit reason.
  Stale items are never silently dropped.
- **Principal response vs. junior response:** Principal keeps BLK-007 in carry-forward
  with "no closure evidence — confirm in PM session" or moves it to deferred with
  explicit reason. Junior drops it from today's update; the team thinks it's resolved;
  it resurfaces a week later as a forgotten blocker.

### Teams-ready update over the 40-line limit padded with status theater — OUT

- **Signature (observable signal):** A Teams-ready AM/PM update exceeds 40 lines, with
  the additional content being recap framing, instructional preamble, or restated
  context that does not add a blocker / action / decision / retest item to the
  carry-forward state.
- **Conditional:** do NOT exceed 40 lines on a Teams-ready update when the additional
  content is recap or framing rather than carry-forward state, because long Teams
  messages are skipped by readers and the carry-forward signal is lost in the framing —
  defeating the purpose of the daily-status output.
- **Root cause:** The 40-line limit feels arbitrary; under perceived pressure to "give
  context," the agent pads the update with framing or restated decisions that the team
  already saw — adding length without adding signal.
- **Mitigation:** The Teams-ready output is the carry-forward state plus the day's
  deltas — nothing else. Recap of yesterday belongs in the Daily Status Log (which the
  agent appends to), not in the Teams message. When the update would exceed 40 lines,
  drop framing/recap before dropping carry-forward content. The Daily Status Log
  receives the full record; the Teams message receives only what the team needs to act
  on.
- **Principal response vs. junior response:** Principal ships a 28-line update with the
  carry-forward state and deltas, and the team reads the whole thing. Junior ships a
  60-line update with a 12-line recap section, and the team's eyes glaze past the
  blockers — the actual signal lost in the noise.

### Internal tracking IDs leaked into Teams-ready output — OUT

- **Signature (observable signal):** A Teams-ready AM/PM update contains internal
  tracking IDs (MTG-##, MSG-##, TR-###, RAID prefixes like R-PPM-###) in the message
  body, instead of descriptive names ("Reservation Clearing & Unwinding session" not
  "MTG-01").
- **Conditional:** do NOT include internal tracking IDs in a Teams-ready update when descriptive names are available in the source trackers, because internal IDs mean nothing to Teams recipients and signal a lack of audience calibration to a non-PMO channel where developers, business stakeholders, and vendor contacts read the message.
- **Root cause:** Internal IDs are the convenient reference in trackers; copying them
  through to Teams without translation is the path of least resistance, especially when
  the tracker source uses IDs throughout.
- **Mitigation:** Run an ID-strip pass before saving to `08-Generated/`. Replace MTG-##
  with the meeting name, MSG-## with the message subject, TR-### with the meeting/date
  reference, R-PPM-### with the risk description. IDs stay only in the Daily Status
  Log (the working document the agent appends to), never in the Teams message body.
- **Principal response vs. junior response:** Principal strips IDs and the Teams
  message reads naturally to non-PMO members ("Reservation Clearing & Unwinding session
  follow-up needed by Friday"). Junior ships "MTG-01: Reservation Clearing & Unwinding"
  and the dev who joined the channel last week asks "what's MTG-01?" — derailing the
  channel into an unrelated explanation thread.

### Daily Status Log appended before the posting-confirmation gate — PROC

- **Signature (observable signal):** Today's AM/PM update appears in the Daily Status
  Log under the date header, but the session shows no user confirmation that the
  update was posted to Teams — the append ran at generation time instead of after the
  Post-Generation confirmation prompt.
- **Conditional:** do NOT append a generated update to the Daily Status Log when the
  user has not yet confirmed the Teams post, because the Log records what was actually
  posted — a pre-confirmation append plants a phantom update that the next generation
  run reads as "yesterday's update" for carry-forward comparison, corrupting every
  downstream delta.
- **Root cause:** The Log append is an auto-write (operational tracker, no approval
  gate), and the agent conflates "no approval needed for the write" with "no ordering
  constraint on the write" — collapsing the three-step Post-Generation sequence
  (save → prompt → append after confirmation) into one pass to feel complete.
- **Mitigation:** Honor the Post-Generation Actions order: (1) save to 08-Generated/,
  (2) prompt for posting, (3) append to the Daily Status Log and update the Open
  Meetings Tracker only after the user confirms the post. If the user never confirms,
  the update stays in 08-Generated/ only; regenerate or discard at the next run —
  never backfill the Log with an unposted update.
- **Principal response vs. junior response:** Principal saves to 08-Generated/,
  prompts, and appends only on confirmation — if the user edits the message before
  posting, the Log captures the posted version. Junior appends at generation time;
  the user never posts (or posts an edited version); tomorrow's AM update carries
  forward deltas against a message the team never saw.

### Executive or weekly status generated through the daily AM/PM framework — TRIG

- **Signature (observable signal):** A request naming a leadership audience or a
  weekly/portfolio time-grain ("status for [exec]", "how did the week land",
  SteerCo prep) is fulfilled by generating an AM/PM-format update from the Daily
  Status Update Framework — team-channel register, emoji headers, @mentions,
  40-line carry-forward shape — instead of routing to weekly-status-rollup or
  comms-writer Type 4.
- **Conditional:** do NOT generate a leadership-audience or weekly-grain status
  through the Daily Status Update Framework when the request names an executive
  audience or a week/portfolio scope, because the AM/PM templates are calibrated
  to the project Teams channel at daily grain — weekly-status-rollup owns the
  cross-project executive roll-up (with PORTFOLIO.md write-back) and comms-writer
  Type 4 owns one-off exec framing, and a daily-format update sent upward reads
  as unfiltered team noise to a leadership reader.
- **Root cause:** "Status" phrasing triggers this skill regardless of audience or
  grain; the Framework is loaded and applied mechanically, and the skill's
  narrow formatting role means it does not naturally stop to ask who the reader
  is.
- **Mitigation:** Before reading the Framework, confirm the request is
  daily-grain and team-channel: an AM/PM/EOD/daily-connect ask for the project
  channel → proceed; a weekly, portfolio, SteerCo, or named-executive ask → name
  weekly-status-rollup (weekly/portfolio) or comms-writer Type 4 (one-off exec
  brief) and route. The routing sentence costs less than an executive reading
  emoji section headers.
- **Principal response vs. junior response:** Principal routes the SteerCo ask to
  weekly-status-rollup and notes that today's carry-forward state is available
  as its input. Junior generates a 38-line emoji-headed AM update, the operator
  forwards it to the COO under deadline pressure, and the milestone-level
  framing leadership needed is absent.

### AM/PM generation invoked outside the framework's phase and lifecycle envelope — TRIG

- **Signature (observable signal):** "Generate the AM update" is honored during a
  project phase whose cadence is not AM/PM — Cutover, where the Phase Adaptation
  table specifies per-milestone updates — or for a project whose lifecycle state
  is CLOSED (read-only, no operational processing), producing an update format
  the phase table says does not exist for this context.
- **Conditional:** do NOT generate an AM/PM-format update when PROJECT.md shows
  the project in Cutover (per-milestone cadence) or in CLOSED state, because the
  Phase Adaptation table replaces AM/PM with per-milestone updates during
  Cutover and the project lifecycle state (PROJECT.md, per the platform Project
  Lifecycle table) ends operational processing at CLOSED — honoring the trigger
  phrase literally produces a status artifact for a cadence or a project that no
  longer exists.
- **Root cause:** The trigger phrase carries the format ("AM update"), so the
  format decision feels pre-made by the user; the Inputs step reads PROJECT.md
  for people and dates, but the phase-to-cadence consequence is easy to skip
  when the user already named the output format.
- **Mitigation:** Treat the Phase Adaptation table as a gate, not styling
  guidance: read the PROJECT.md phase and state first; in Cutover, offer the
  per-milestone update the Framework actually defines; on a CLOSED project,
  decline operational generation and point to the closure summary. Name the
  substitution explicitly ("Cutover cadence is per-milestone — generating the
  milestone update instead").
- **Principal response vs. junior response:** Principal reads phase first and
  produces the per-milestone update with a one-line note on why. Junior produces
  a UAT-shaped AM update during cutover week; the team gets a retest-queue
  section while milestone go/no-go status — the only thing that matters that
  week — is missing.

### Daily Connect Prep generated over unprocessed Communications Tracker entries — HAND

- **Signature (observable signal):** A Daily Connect Prep output is generated and saved
  to `08-Generated/` while the Communications Tracker read (input 5) shows ACTIVE-tier
  MSG entries newer than the last processed update — pending actionable comms or
  awaiting-response items no ppm-agent run has triaged into carry-forward state — and
  the prep output neither reflects them nor flags their existence.
- **Conditional:** do NOT generate a silent Daily Connect Prep when the Communications
  Tracker contains ACTIVE-tier entries newer than the last processed update that have
  not been triaged into carry-forward state, because this skill formats current state
  rather than analyzing artifacts — untriaged messages may carry blockers or decisions
  the team walks into the Daily Connect without, and the triage that resolves them
  belongs to ppm-agent (the tracker's lifecycle manager), not to a formatting pass.
- **Root cause:** The prep template sources "messages sent since the last update,"
  which reads as a mechanical filter; the distinction between "include the new entries
  in the prep" and "the new entries were never processed into project state" is easy to
  collapse when the goal is producing the prep file. Crossing the boundary the other
  way — self-triaging the messages — also feels like push-to-resolve, but strategic
  triage is explicitly outside this skill's role.
- **Mitigation:** Compare Communications Tracker entry timestamps and lifecycle tier
  against the Daily Status Log's last update. When untriaged ACTIVE entries exist,
  render the prep WITH a prep-note placed outside the Teams-ready body (it is
  PMO-internal routing, not channel content, and the ID-strip rule still governs the
  Teams-ready block): "⚠️ N unprocessed Communications Tracker entries since the AM
  update — recommend ppm-agent processing before the Daily Connect," listing the
  affected messages by descriptive subject. Do not self-triage the messages into
  blockers or decisions, and do not silently omit them.
- **Principal response vs. junior response:** Principal ships the prep with the
  unprocessed-entries note and the one-line route to ppm-agent, so the TPM either
  processes them or walks in knowing the prep's blind spot. Junior either ships the
  prep silently (the team discovers the missed escalation mid-meeting) or plays PPM
  Agent and triages the messages inline — producing strategic judgments a formatting
  skill was never specified to make.

## Multi-Project Support

When multiple projects are active (per PORTFOLIO.md):

- Generate status updates per-project (not combined)
- Each project uses its own Framework, trackers, and templates
- If the user says "generate all daily updates," process each project in sequence
- Present all outputs together for review before posting
