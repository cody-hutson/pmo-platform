<!-- Eval fixture — sanitized synthetic project state, v2 extended-modes case. No real stakeholder names. -->
# Fixture: hypercare-window project state (v2 modes — comms / plan / raid / sources)

A synthetic single-project state captured during the hypercare window after go-live. Stakeholder names are sanitized placeholders (`[OWNER-F]`, `[OWNER-G]`, `[VENDOR-Y]`). Seeded drift is annotated in HTML comments so the judge has ground truth; a real run would not carry these annotations. This is the third project state in the bank (pre-cutover, UAT-degraded, hypercare-window), and it seeds the four v2 modes.

**Run condition (MCP probe at run start):** `Confluence OK · Jira OK · Smartsheet OK · SharePoint (no connector)`. No connector is unreachable in this fixture (the degradation path is exercised by `uat-window-mcp-degraded.md`); SharePoint still has no MCP and is the standing missing-but-expected source for the `sources` mode.

## PROJECT.md (local)

```
Project: Synthetic-Hypercare
Phase: Hypercare
Go-Live: Monday April 13, 2026            <!-- CLEAN day-of-week: April 13 2026 is a Monday -->
Hypercare exit: Friday April 24, 2026     <!-- CLEAN day-of-week: April 24 2026 is a Friday -->
Source sync — Confluence last synced: 2026-04-02   <!-- SEEDED-DRIFT sources: Confluence hypercare page was updated 2026-04-20 (below); local sync timestamp is 18 days stale -> external-source freshness drift -->
Source sync — Jira last synced: 2026-04-22          <!-- CLEAN: matches Jira's recent activity -->
Test Tracker: SharePoint (Hypercare Scoreboard)     <!-- SharePoint has no MCP: content unverifiable, link-only; sources mode lists it missing-but-expected -->
```

## Communications Tracker (local, 04-PMO-Operations/) — for `comms` mode

```
COM-031  Go-live exec brief        Status: SENT    Sent: 2026-04-13  Response: NONE   Needs-response: YES   <!-- SEEDED-DRIFT comms: SENT 11 days ago, response expected, none received, no follow-up logged -> stale-SENT awaiting response -->
COM-032  Hypercare daily digest    Status: SENT    Sent: 2026-04-23  Response: N/A    Needs-response: NO    <!-- CLEAN: recent, no response needed -> must NOT be flagged -->
COM-033  Phase-2 kickoff invite     Status: DRAFT   Drafted: 2026-04-08  <!-- SEEDED-DRIFT comms: DRAFT for an event whose date (April 13 go-live window) has passed -> obsolete-DRAFT -->
COM-034  Vendor SLA reminder        Status: READY   Drafted: 2026-04-21  <!-- SEEDED-DRIFT comms: READY but never sent; 3 days unsent past its intended send window -> unsent-READY -->
```

## Hypercare Plan (local artifact, named plan) — for `plan <name>` mode

```
Plan: Hypercare Plan (Synthetic-Hypercare)
Promised:
  - Daily defect triage stand-up through hypercare exit (April 24)   <!-- reflected: carry-forward tracker shows HC-002 daily triage active -> CLEAN, no delta -->
  - War-room staffing rota published by April 15                     <!-- SEEDED-DRIFT plan: no tracker entry, no Confluence rota page -> plan-promised-but-not-reflected delta -->
  - Hypercare exit report drafted by April 22                        <!-- SEEDED-DRIFT plan: tracker shows no exit-report artifact; today is past April 22 in fixture-time -> closure-delta -->
```

## RAID Log (local, 04-PMO-Operations/) — for `raid` mode

```
R-PROJ-040  Risk   "Performance may be impacted under peak load"   Owner: (empty)        Mitigation: (none)   Status: Open      Last-reviewed: 2026-04-20  <!-- SEEDED-DRIFT raid: PASSIVE VOICE ("may be impacted" — no actor) AND missing owner AND missing mitigation -> three guardrail violations on one entry -->
R-PROJ-041  Risk   "[VENDOR-Y] misses the SLA credit deadline, delaying the true-up"   Owner: [OWNER-F]   Mitigation: "Escalate to vendor TAM by April 20; track credit in finance log"   Status: Open   Last-reviewed: 2026-04-22  <!-- CLEAN: active-voice, named owner, named mitigation, recently reviewed -> must NOT be flagged -->
R-PROJ-038  Issue  "Defect DEF-019 blocks the exit report"   Owner: [OWNER-G]   Mitigation: "Hotfix in regression"   Status: Open   Last-reviewed: 2026-03-05   <!-- SEEDED-DRIFT raid: Last-reviewed 2026-03-05 is >30 days before the hypercare window -> STALE entry (auto-escalate per >30d rule) -->
```

## Confluence (MCP-primary) — hypercare page, updated 2026-04-20

```
Hypercare page last edited: 2026-04-20    <!-- newer than PROJECT.md's recorded Confluence sync (2026-04-02) -> sources mode: external newer than recorded sync, flag the local sync timestamp stale, S2 -->
(no war-room staffing rota page present)  <!-- corroborates the plan-mode war-room rota gap -->
```

## Jira (MCP-primary) — reachable

```
Open risk tickets: RISK-PERF (maps to R-PROJ-040), RISK-SLA (maps to R-PROJ-041)   <!-- both risks have Jira tickets; neither resolves the owner/mitigation gap on R-PROJ-040 -->
```

## Smartsheet (MCP-primary) — live tracker

```
Hypercare exit date: 2026-04-24           <!-- agrees with PROJECT.md (Friday April 24) -> CLEAN -->
```

## Expected categorization (ground truth for the judge)

### `comms` mode
- `## Auto-Actionable` — COM-031 stale-SENT (sent April 13, 11 days, response expected, none): two-source corroborated (tracker + no Confluence response record), recent enough to act → `[confidence: HIGH · S2]` propose a follow-up/close-status update; emits a `TRACKER_UPDATES:` block (status only, routed to `/comms-writer`). COM-034 unsent-READY past its window → `[confidence: HIGH · S1]` flag to send or supersede.
- `## Decisions` — COM-033 obsolete-DRAFT (Phase-2 kickoff for a passed window): obsolete-vs-reschedule is an operator call → `[confidence: MEDIUM · S2]`.
- **Must NOT flag:** COM-032 (recent, no response needed).

### `plan Hypercare` mode
- `## Auto-Actionable` — War-room staffing rota promised by April 15, no tracker entry + no Confluence rota page (two sources agree it is absent) → `[confidence: HIGH · S2]` flag the gap.
- `## Decisions` — Hypercare exit report promised by April 22, not drafted; may have been deliberately deferred → `[confidence: MEDIUM · S2]`.
- `## Confirmed` — Daily defect triage stand-up (HC-002 active in the tracker) → `[confidence: HIGH · S0]`.
- **No-arg behavior (separate assertion):** `plan` invoked with no name returns an actionable "which plan?" prompt and does NOT default to a plan.

### `raid` mode
- `## Decisions` — R-PROJ-040: passive-voice risk ("may be impacted", no actor) + missing owner + missing mitigation → `[confidence: HIGH · S2]` three guardrail violations; operator must name an owner + mitigation and re-voice. R-PROJ-038: stale (last reviewed March 5, >30d) → `[confidence: HIGH · S2]` closure-or-refresh candidate (auto-escalate per the >30d rule).
- **Must NOT flag:** R-PROJ-041 (active-voice, owner named, mitigation named, recently reviewed).
- `raid` never auto-applies a closure — closing a risk needs evidence (cautious bias); RAID findings route to `## Decisions`, not `## Auto-Actionable`, unless a two-source-corroborated mechanical fix exists.

### `sources` mode
- Emits a **canonical-source inventory** naming the source-of-truth set (Confluence / Jira / Smartsheet / SharePoint + the local set) with a per-source freshness verdict.
- `## Auto-Actionable` — Confluence sync timestamp in PROJECT.md (April 2) is stale vs the live page (edited April 20) → `[confidence: HIGH · S2]` propose updating the recorded sync timestamp.
- `## Unknowns` / inventory flag — SharePoint listed as **missing-but-expected** (no MCP connector): content unverifiable, link-only — NOT asserted fresh.
- `## Confirmed` — Jira sync (April 22) current; Smartsheet exit date agrees.
```
