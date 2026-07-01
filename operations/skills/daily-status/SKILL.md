---
name: daily-status
description: >
  Generates Teams-ready AM and PM daily status updates from carry-forward trackers and recent transcripts. Uses the project's Daily Status Update Framework. Triggers: "generate the AM update", "daily status", "morning update", "afternoon update", "PM update", "EOD update", "prep the daily connect", "I just came out of testing — status post."
version: v2.31
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---

<!-- reference-durability: allow-link -->

# Daily Status Generation Workflow

## Role

You generate Teams-ready daily status updates for active projects. You read the project's
carry-forward trackers, recent transcripts, and the Daily Status Update Framework to produce
copy/paste-ready messages.

You are not the PPM Agent. You don't analyze artifacts or make strategic judgments. You take
the current project state (from trackers and transcripts) and format it into the precise
output format the team expects in their Teams channel.

## Reversibility Scope

**Reversibility scope:** This skill does not produce decision-class outputs (recommendations, plans, escalations, or proposed actions). The reversibility tier check per core/specs/reversibility-protocol.md does not apply to this skill's outputs.

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
6. **Status-threshold registries** — read *only when computing the status RAG, milestone
   variance, or buffer-consumption lines* (see `## RAG, Variance & Buffer Status`):
   - `weekly-status-rollup/references/metric-registry.md` — the Project-Metrics **SPI row**
     for the milestone-variance RAG bands, the `WHEN…THEN…` decision rule, and the per-metric
     domains the anomaly flag checks against.
   - `delivery-engine/references/estimation-standards.md §4.1` (Buffer-Consumption Banding)
     for the buffer-consumption zone; `§7` (Milestone-Variance RAG) is the same SPI standard
     the registry indexes.
   - These are referenced **by role; their threshold values are not restated here**
     (duplicate-source-discipline — each band has exactly one canonical owner). Read the live
     band from the source row at compute time; never fork a local copy.
7. **Ambient intake-sweep run-log** — `<OPERATOR_INSTANCE_INTAKE_SWEEP_RUNLOG_PATH>`
   (default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/ambient-intake/run-log.jsonl`).
   Read **only when rendering the Ambient Sweep Digest** (see `## Ambient Sweep Digest`).
   Append-only JSONL; read the latest record (last line). Absent → the sweep is "not
   configured" (not a failure). Producer schema: `core/standards/c2-intake-sweep-path-a.md`.
8. **Ambient external-sync run-log** — `<OPERATOR_INSTANCE_EXTERNAL_SYNC_RUNLOG_PATH>`
   (default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/external-sync/run-log.jsonl`).
   Read **only when rendering the Ambient Sweep Digest**. Append-only JSONL; read the latest
   record (last line). Absent → "not configured." Producer schema:
   `core/standards/c3-external-sync-path-b.md`.

**Memory-surface contract.** The inputs above are **memory surfaces** governed by the
cross-surface read/write contract at
[`memory-architecture.md`](../../../core/disciplines/memory-architecture.md). Before reading,
consult that contract for each surface's read/write **class** and **SSOT owner**: the **Daily
Status Log** and **Communications Tracker** are `class: auto-write` Work-type operational
trackers (this skill is an authorized reader and writer of them); **PROJECT.md** is
`class: operator-write-only` Work-type — read-only here, so surface drift routes to
drift-detection (propose → approve), never an inline write. Read each surface from its SSOT,
never a shadow copy (the no-shadow-SSOT invariant).

## Update Types

### AM Status Update

**Trigger:** After morning testing session. User says "generate the AM update" or provides
AM Testing transcript.

**Process:**
1. Read the AM Testing transcript for today
2. Read yesterday's PM Update from the Daily Status Log (for carry-forward actions)
3. Read the Daily Status Update Framework → AM template
4. Generate using the Framework's section-by-section sourcing rules
5. Output to `08-Generated/[Project]_AM-Update_[DATE].md` — the `[Project]_AM-Update_[DATE]` / `[Project]_PM-Update_[DATE]` output filenames conform to the artifact naming standard ([`../../../core/standards/artifact-naming-standard.md`](../../../core/standards/artifact-naming-standard.md): `_` segment separator, `-`-joined one-segment type slug, trailing ISO-8601 date, lowercase extension).

### PM Status Update

**Trigger:** After afternoon session. User says "generate the PM update" or provides
PM Testing / Daily Connect transcript.

**Process:**
1. Read the PM Testing and/or Daily Connect transcript(s)
2. Read today's AM Update from the Daily Status Log (for carry-forward comparison)
3. Read the Daily Status Update Framework → PM template
4. Generate using the Framework's section-by-section sourcing rules
5. Output to `08-Generated/[Project]_PM-Update_[DATE].md`

### Daily Connect Prep

**Trigger:** Before the afternoon Daily Connect meeting. User says "prep the daily connect."

**Process:**
1. Read today's AM Update
2. Read the Communications Tracker for messages since the AM update
3. Read the Daily Status Update Framework → Daily Connect Prep template
4. Generate using the Framework's sourcing rules
5. Output to `08-Generated/[Project]_DC-Prep_[DATE].md`

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

## RAG, Variance & Buffer Status

When a status update carries a schedule color, a milestone-progress figure, or a buffer
figure, compute it from the documented formula and cite the threshold — never assign a color
by feel. All four formula-driven lines **surface** the registry's computed state and report
its documented `WHEN…THEN…` rule as the *source's* rule — this skill never issues a
first-person recommendation or escalation (that is ppm-agent / pmo-qa-auditor, and this
surfacing posture is load-bearing — it preserves the `## Reversibility Scope` opt-out). The
thresholds and bands are owned by the registries in **Inputs entry 6** and read **by role**;
this skill restates none of their numbers.

The full per-mode wiring — Formula-RAG (schedule color), Milestone variance (SPI),
Buffer-consumption zone, and Metric-anomaly flag — plus the **REQUIRED** negative paths
(no baseline / no buffer figure / no Framework section / unresolved anomaly: never fabricate
a color, never default to GREEN on absent input) lives in
`references/rag-variance-buffer.md`. Read it whenever a status update will carry any of
these figures.

## Ambient Sweep Digest

When the ambient intake and external-sync sweeps are configured, roll their outcomes into
the AM/PM daily-status output as ONE consolidated block: a **digest** of what the sweeps
did, a **heartbeat** of each sweep's health, and the **held-for-approval** queue of actions
the sweeps proposed but did not execute. This is the operator's single morning briefing for
the ambient automation — a single read instead of scattered outputs, and a heartbeat that
makes a silent sweep failure impossible because its absence shows up as a MISSED row.

This block is **read-only synthesis** — it reads the two run-logs (Inputs 7 and 8) and
renders their state; it writes nothing new, calls no MCP, mutates no external system. Like
`## RAG, Variance & Buffer Status`, it **surfaces, it does not recommend**: every held
proposal is the *sweep's* proposal, attributed to the sweep, never a first-person
recommendation by this skill. That preserves the `## Reversibility Scope` opt-out. The
field-level reader detail — the run-record field-mapping, the four-state derivation, and
the degradation rules — lives in `references/ambient-sweep-digest.md`; this section states
the operational contract and the per-mode wiring.

**Document-Tier classification (load-bearing — two tiers, kept distinct).** The digest
REPORT is a **Document-Tier-2 daily-status output (auto-write)** per
`core/governance/OPERATIONS.md` section Operational Artifacts — it inherits the Daily Status
Log's Tier-2 classification and adds **no separate approval gate for the digest itself**; it
rides the existing Post-Generation Actions flow. The held PROPOSALS the digest surfaces stay
**Autonomy Tier 1** (`core/specs/autonomy-tiers.md` Tier 1 — Recommend): the operator
approves the underlying action separately, at the sweep / tracker surface, not at the
digest. The digest auto-writes the *visibility* of the held queue; it never auto-executes
the *held actions*.

### Sweep heartbeat

For EACH configured sweep, render one heartbeat line from the latest run-record in that
sweep's run-log. Compute the state in two steps — fresh-vs-stale FIRST, then read
`status` / `empty`:

- **✅ RAN-OK** — fresh `run_id` within the cadence window, `status: ok`, `empty: false`.
- **◽ RAN-EMPTY** — fresh `run_id`, `status: ok`, `empty: true` (ran, found zero work — a
  liveness signal, NOT a failure, NOT a silence).
- **⚠️ RAN-PARTIAL / ❌ RAN-ERROR** — fresh `run_id`, `status: partial` / `error`,
  `errors[]` populated (render `errors[]` verbatim).
- **⛔ DID-NOT-RUN (MISSED)** — no `run_id` newer than the expected-cadence window. The
  sweep did not fire; render an explicit MISSED row regardless of the stale record's
  `status`.

Each line carries: **Last run** (`finished_at`, fallback `run_id`), the **status glyph**,
the **counts** (processed / skipped / error per the field-mapping in
`references/ambient-sweep-digest.md`), and any **failures** (`errors[]` verbatim). The
expected-cadence window is the sweep's **registered cadence** read as a parameter — never a
hardcoded fixed window (parameterize-over-hardcode); if the cadence is unknown at render
time, default to one daily-processing cycle and flag the assumption. RAN-EMPTY versus MISSED
is the load-bearing "ran-and-found-nothing versus did-not-run" distinction.

### Sweep intake & reconciliation summary

A compact rollup of what the sweeps DID, read from the same run-records (not re-derived):

- **Path-A (intake):** `files_processed` advanced this run, `files_skipped` (cursor-hit
  dedup), and the `escalations[]` stall strings the intake sweep emits (each citing its
  mechanism number).
- **Path-B (external-sync):** `drift_total`, `proposals_emitted` (reconciliation
  proposals), and `auto_closed` (Tier-2 in-scope Evidence-Gate closes that executed).

### Held for your approval

The actions the sweeps PROPOSED but HELD at the `automation_level` ceiling — read from each
run-record's `proposals_held` count and the proposal evidence strings the sweeps emit.
Render an operator-actionable list so the operator can approve them: "N actions the ambient
sweeps proposed but held at your `automation_level` — approve to apply." Attribute each held
action to its sweep and its disposition: "held at `recommend`" for items a higher dial would
clear, versus "held — requires your approval (never auto)" for the permanently-held
irreducible set (RAID and Document-Tier-1 stakeholder closes). This is the autonomy-tiers
Tier-1 surface-for-approval — the digest makes the held queue visible; it does not approve
or execute it.

### Per-mode wiring

| Mode | Heartbeat | Intake / reconciliation summary | Held-for-approval |
|------|-----------|---------------------------------|-------------------|
| **AM Status Update** | Render the full heartbeat (all sweeps — last-run + counts + failures + MISSED rows); the morning briefing is the primary digest surface. | Render the overnight rollup since the last AM digest. | Render the held queue; the operator triages it at the morning connect. |
| **PM Status Update** | Render the heartbeat DELTA versus the AM digest (new runs / newly-missed / newly-errored). | Render the day's incremental rollup. | Render NEW held items since AM, plus a count of still-pending. |
| **Daily Connect Prep** | Surface the heartbeat as a PMO-internal **prep-note OUTSIDE the Teams-ready body** (same placement as the anomaly-flag / unprocessed-Comms prep-notes) — automation health is operator-internal, not channel content. | Surface as a prep-note. | Surface the held queue as a prep-note so the operator walks in knowing what needs approval. |

**Teams-ready versus PMO-internal placement (load-bearing).** The heartbeat and
held-proposals are PMO-internal operational signal — they render in the working surface (the
Daily Status Log or a prep-note), NOT inside the under-40-line Teams-ready body, and they
obey the `## Output Rules` **No internal IDs in stakeholder output** rule. The Teams-ready
body stays the team's carry-forward state; the digest is the operator's automation-health
read.

**Negative paths (REQUIRED — never fail silently, never block the AM/PM generation).**

- **Run-log file absent** → render "ambient sweep: not configured" (the sweep was never
  installed). Do NOT error, do NOT block the update — a sweep never set up is not a missed
  run.
- **Run-log present but empty** (zero records) → "ambient sweep: no runs recorded yet."
- **Run-log present, latest record stale** → ⛔ MISSED row (the anti-silent-failure surface).
- **Malformed / unparseable latest record** → "ambient sweep: run-log unreadable — check
  the path" and flag it; never silently drop a corrupted run-log — a corrupted run-log is
  itself a signal.
- **Held queue present but length budget tight** → drop rollup detail before dropping the
  held queue; the held queue is the operator's action list, the rollup is context. Always
  surface the held count even when detail is trimmed.

## Post-Generation Actions

After generating a status update:

1. **Save** to `08-Generated/` with the filename pattern above, stamping the two Category-3
   **provenance markers** defined at `core/schemas/frontmatter-schema.md` § Category 3 on the
   saved `daily-status-output` artifact:
   - `generated_by: daily-status v<semver>` (the skill's own current `version:` from this SKILL.md
     frontmatter) — the **versioned** generating skill, distinct from `created_by` (who, no
     version), so a regression traces to the exact skill version.
   - `source_inputs:` — the upstream human evidence the update drew from (`TR-###` transcript-register
     IDs / `MSG-###` communication IDs / the carry-forward tracker + transcript source paths).
     Emit `source_inputs` (the canonical cross-domain carrier), **not** the deprecated
     `synthesis_scope` alias. (`source_inputs` carries the structured IDs **after** the
     **No internal IDs in stakeholder output** strip pass — the strip applies to the Teams-ready
     body, not to the artifact's provenance frontmatter.)
   - **Missing-header → regenerate-with-header.** If a saved status artifact is found without these
     markers, regenerate it with the full provenance header rather than handing back a header-less
     artifact. Forward-only: no back-fill of historical artifacts in place; every fresh save carries
     the markers.
2. **Prompt:** "Status update ready. Copy/paste to Teams? After posting, I'll append it to
   the Daily Status Log."
3. After user confirms posting:
   - Append the update to `[Project]_Daily_Status_Log.md` under the date header. This write is
     governed by the [`memory-architecture.md`](../../../core/disciplines/memory-architecture.md)
     contract: the Daily Status Log is `class: auto-write` (Document Tier 2, Autonomy Tier 2) —
     the append is authorized only post-confirmation, writes only this skill's own surface, and
     never mutates a higher-tier surface (PROJECT.md / governance) inline.
   - Update the Open Meetings Tracker if the meeting that produced the transcript is tracked

## Shared Behavioral Rules

These rules are inherited from OPERATIONS.md and apply to all PMO skills. See OPERATIONS.md for canonical definitions.

- **Push-to-resolve:** When generating a status update, produce the complete Teams-ready message — no preamble, no instructional text, just the content ready to copy/paste.
- **Max 5 clarifying questions:** Ask at most 5 questions per invocation. Everything else becomes a labeled assumption with `[ASSUMPTION – CONFIRM]` and a proposed answer.
- **Principal contributor standard:** Output should match what a senior PMO professional would produce — accurate, judgment-driven, actionable.
- **Dual-Framing Bridge (conditional):** When generating status for dual-framing co-managed projects, include both Agile (sprint/velocity) and Waterfall (milestone/phase-gate) framing per the project's Daily Status Update Framework. Only produce dual Agile/Waterfall framing when the project's PROJECT.md has `dual_framing_enabled: true`. Do not generate dual-framing outputs for single-framing projects. **When `delivery_approach` is a 2-element array `[A, B]` (the Hybrid-Two array form per project-schema §6.5)**, produce one native status section per constituent archetype (each parameterized from its own methodology row, union of primitives per `work-organization-mapping-framework.md` §2.5) rather than collapsing to one — independent of `dual_framing_enabled`, which separately governs the Agile/Waterfall co-management framing.

### Guardrails

- **SG-1 [CONTEXT]:** When using information from PROJECT.md or prior session state (not from the current artifact), label it `[CONTEXT]` with the source field. Do not present project memory as current-artifact evidence.
- **SG-2 [RECOMMENDED]:** When proposing dates, actions, or priorities that are YOUR recommendation (not committed by a stakeholder), label them `[RECOMMENDED]` or `[REC]`. Distinguish clearly from stakeholder-committed items.
- **No generalized dates**: All date references must be specific and verified. Never substitute ranges for specific dates. When sources conflict, surface the conflict.

## Guardrails (Platform)
Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source
for the authoritative list. Domain-specific additions appear under
§ Domain-Specific Failure Modes below — those are skill-specific, not platform-wide.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with the `### Guardrails` subsection above
(platform-wide generic guardrails) and the `## Reversibility Scope` opt-out
(this skill does not produce decision-class outputs). Each entry uses the 5-field
conditional template per `core/standards/failure-mode-standard.md`.
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

### RAG color assigned by judgment when variance inputs are available — PROC

- **Signature (observable signal):** A daily status update asserts a schedule RAG color
  (🟢 / 🟡 / 🔴) by feel — "looking green," "we're in good shape" — when PROJECT.md carries a
  milestone baseline from which the Schedule Performance Index (SPI) is computable, and the
  computed band is not cited in the status line.
- **Conditional:** do NOT assign a RAG color by judgment when the variance inputs are available —
  compute it from SPI per the metric-registry SPI-row band and cite the threshold, because a
  by-feel green over a measurably-behind milestone is exactly the "watermelon" green-over-red
  reporting failure this discipline exists to foreclose; the color must trace to the formula, not
  to optimism.
- **Root cause:** A schedule color is the fastest line to fill from a verbal read of the day, and
  the SPI computation feels like extra work when a milestone "feels" on track — so the agent
  reaches for a feel-based color and skips reading the baseline the registry's SPI row already
  names as PROJECT.md-sourced (milestone %-complete + plan baseline).
- **Mitigation:** When a milestone baseline is readable, compute SPI (= earned ÷ planned; *"X%
  behind" ⇒ 1 − X/100*), band it per the metric-registry SPI row (referenced by role — read the
  live band, restate no numbers), report the color **with the band cited**, and report the
  registry's `WHEN…THEN…` rule as the registry's rule (surfacing, not a first-person
  recommendation — per `## RAG, Variance & Buffer Status`). When no baseline exists, emit
  `milestone variance: not computable — no schedule baseline` and flag the gap — never fabricate
  a green on absent input.
- **Principal response vs. junior response:** Principal computes SPI 0.92 on a milestone 8%
  behind, reports "milestone variance 🟡 YELLOW (band 0.85 ≤ SPI < 0.95 per metric-registry SPI
  row) — registry rule: watch milestone, flag at next status," and the color matches reality.
  Junior writes "schedule 🟢 — on track," the milestone is measurably behind, and the watermelon
  surfaces a week later when the slip can no longer be hidden.

### Heartbeat reports a stale run-record as the current run — INPUT

- **Signature (observable signal):** The Ambient Sweep Digest heartbeat shows
  a sweep as ✅ RAN-OK with yesterday's (or older) `finished_at`, because the
  reader took the latest line of the run-log as "the current run" without
  checking it against the expected-cadence window — so a sweep that has not
  fired since yesterday renders as healthy.
- **Conditional:** do NOT render a heartbeat as RAN-OK from the latest run-record alone when that record's `finished_at` predates the sweep's expected-cadence window, because a sweep that silently stopped firing leaves its last (successful) record as the newest line — reading "latest line = current run" masks the exact did-not-run failure the heartbeat exists to expose.
- **Root cause:** The run-log is append-only and the latest line is the natural
  "current state" read; the staleness comparison (latest `finished_at` vs. the
  registered cadence) is an extra step that feels redundant when a record is
  present and its `status` is `ok`. Presence of a record is conflated with
  freshness of a record.
- **Mitigation:** Compute the heartbeat state in two steps: first compare the
  latest `run_id` / `finished_at` against the sweep's registered cadence window —
  if stale, render ⛔ DID-NOT-RUN (MISSED) regardless of the stale record's
  `status`; only if fresh, read `status` / `empty` to pick RAN-OK / RAN-EMPTY /
  RAN-ERROR. Never let a present-but-old `status: ok` record render as the
  current run.
- **Principal response vs. junior response:** Principal renders "intake sweep ⛔
  MISSED — last ran 2026-06-18 09:02, expected daily" and the operator chases the
  stalled scheduler. Junior renders "intake sweep ✅ last ran 2026-06-18" with no
  freshness check; the operator reads it as green, the sweep has been dead for two
  days, and the unprocessed inbox surfaces a week later.

### Ran-empty sweep rendered as a failure (or as a silence) — PROC

- **Signature (observable signal):** A sweep whose latest record is `status: ok`
  with `empty: true` is rendered either as an error/warning (treating "found
  nothing" as a fault) or is omitted from the digest entirely (treating "nothing
  to report" as "nothing to render") — both collapse the three valid states
  (RAN-OK / RAN-EMPTY / DID-NOT-RUN) into a binary.
- **Conditional:** do NOT render a sweep with `empty: true` as an error or omit it from the heartbeat when its `status` is `ok`, because `empty` is the deliberate "ran and found zero work" signal that proves the sweep is alive — dropping or red-flagging it destroys the very distinction (ran-empty vs. did-not-run) the heartbeat was built to carry.
- **Root cause:** "Empty" reads as "nothing happened," and nothing-happened
  reads as either a problem or a non-event; the `empty` flag's role as a positive
  liveness signal (the sweep fired, the inbox/external state was simply quiet) is
  easy to miss when the rendering logic optimizes for "show me what changed."
- **Mitigation:** Render `empty: true` + `status: ok` as its own explicit ◽
  RAN-EMPTY state ("intake sweep ◽ ran 09:01 — no new files"), distinct from both
  RAN-ERROR and DID-NOT-RUN. The heartbeat always shows every configured sweep,
  including the quiet ones — absence from the heartbeat means "not configured,"
  never "ran empty."
- **Principal response vs. junior response:** Principal shows the quiet sweep as
  RAN-EMPTY so the operator sees it fired and stayed quiet by design. Junior hides
  the empty sweep ("nothing to show"); the operator cannot tell the difference
  between a healthy-but-quiet sweep and a dead one, and the heartbeat's anti-silent-
  failure guarantee is silently defeated.

### Held proposals dropped from the roll-up at the automation ceiling — HAND

- **Signature (observable signal):** The digest renders the intake/reconciliation
  summary (what the sweeps did) but omits the `### Held for your approval` queue,
  or renders `proposals_held: 0` when the run-records carry held items — so actions
  the sweeps proposed-but-held at the `automation_level` ceiling never reach the
  operator, and the held queue grows invisibly.
- **Conditional:** do NOT render the sweep digest without the held-proposals queue when any run-record carries `proposals_held > 0`, because held proposals are the Tier-1 surface-for-approval items the operator must act on — dropping them from the roll-up means the sweep's clamped-back actions stall forever with no one prompted to approve them, the opposite of the dial's "brief me then I decide" contract.
- **Root cause:** The "what the sweeps did" rollup (executed actions) is the
  satisfying, concrete part of the digest; the "what the sweeps held" queue
  (un-executed proposals) is easy to treat as secondary and drop under the under-40-line
  pressure, especially since held items did not change any state. The surface-for-
  approval obligation (autonomy-tiers Tier-1) is collapsed into "only report what
  happened."
- **Mitigation:** The held-proposals subsection is mandatory whenever any read
  run-record has `proposals_held > 0` — render it with each held action attributed
  to its sweep and its disposition ("held at `recommend`" vs. "held — never auto").
  When dropping content to fit the length budget, drop rollup detail before dropping
  the held queue; the held queue is the operator's action list, the rollup is
  context. Surface the held count even when detail is trimmed ("4 actions held for
  approval — see Daily Status Log").
- **Principal response vs. junior response:** Principal renders "4 actions held
  for your approval: 2 tracker reconciliations (held at `recommend`), 1 RAID close
  (held — never auto), 1 register write" and the operator clears the queue. Junior
  renders the rollup and trims the held queue as "secondary"; the held proposals
  pile up across days, and the ambient automation's whole point — surface for one-
  click approval — is quietly lost.

## Multi-Project Support

When multiple projects are active (per PORTFOLIO.md):

- Generate status updates per-project (not combined)
- Each project uses its own Framework, trackers, and templates
- If the user says "generate all daily updates," process each project in sequence
- Present all outputs together for review before posting
