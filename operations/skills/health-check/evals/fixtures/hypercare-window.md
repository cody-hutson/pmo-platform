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

## Entity records (local, entity-first layer) — for `structure` mode

Records shown as their field sets, not as files — the audited population is entity records. Three
DISTINCT structural shapes are seeded so no two cases share one datum.

```
Project  PRJ-SYNHC        entity_type: Project     id: synthetic-hypercare
                          status: Hypercare        content_lifecycle_pattern: Living
                          owning_agent: health-check   created_date: 2026-03-02
                          <!-- CLEAN E1: the structurally-required Project record is present and well-formed -> the audit RUNS -->

Person   PER-011          entity_type: Person      id: per-011
                          lifecycle_state: active  content_lifecycle_pattern: Living
                          owning_agent: project-initiator   created_date: 2026-02-11
                          <!-- CLEAN, and LOAD-BEARING: this record makes the cross-project-shared tier POPULATED.
                               Without it every Person reference would be a tier gap; with it, an unresolvable
                               Person reference is a genuine record defect. It is the discriminator for shape 2. -->

RAID Item R-PROJ-040      entity_type: RAID Item   id: r-proj-040
                          lifecycle_state: open    created_date: 2026-04-18
                          owner_person_id:                       <!-- SEEDED SHAPE 1 (empty required field): an EMPTY SLOT.
                               Presence failure only. An empty slot instantiates NO relationship rule, so it counts
                               ONCE in the fields factor (MM-2) and must NOT also be counted in MM-3. -->
                          content_lifecycle_pattern:             <!-- SEEDED (derivable): the frozen schema pins exactly one
                               value for this entity, so the correct value IS derivable -> ## Auto-Actionable + TRACKER_UPDATES:.
                               Contrast with the empty owner above, which is NOT derivable -> ## Decisions. -->

RAID Item R-PROJ-038      entity_type: RAID Item   id: r-proj-038
                          lifecycle_state: open    created_date: 2026-03-05
                          owner_person_id: per-902               <!-- SEEDED SHAPE 2 (broken relationship): POPULATED but names a
                               Person id with no record, WHILE the cross-project-shared tier holds PER-011. A genuine
                               dangling reference -> a record defect in ## Decisions, NOT a coverage gap. -->

RAID Item R-PROJ-041      entity_type: RAID Item   id: r-proj-041
                          lifecycle_state: open    created_date: 2026-04-01
                          owner_person_id: per-011               <!-- CLEAN: resolves, precisely BECAUSE the tier is populated -->
                          content_lifecycle_pattern: Living      owning_agent: delivery-engine
                          <!-- CLEAN across all three limbs -> must NOT be flagged by structure mode -->

Meeting  MTG-104          entity_type: Meeting     id: mtg-104
                          lifecycle_state: held    created_date: 2026-04-16
                          content_lifecycle_pattern: Living      owning_agent: ppm-agent
                          relationships: [ { type: GENERATES, target: dec-206 } ]
                          <!-- SEEDED SHAPE 3 (missing entity): a TYPED EDGE to an absent entity. No Decision record
                               instantiates dec-206 -> referenced-but-absent, a contradiction finding at S3. -->

Cross-Project Dependency  <!-- NO RECORD OF THIS TYPE EXISTS, and the portfolio-level tier holds none either.
                               A reference into that tier is unresolvable BY TIER, not by record -> routing row 1:
                               ## Unknowns, excluded from the denominator, named in the coverage note.
                               This is the specificity control for shape 2 — the two must not be conflated. -->
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

### `structure` mode

Audits all three limbs — (a) entity present, (b) required fields populated, (c) required relationships valid — over the entity-record layer above.

- `## Decisions` — **R-PROJ-040 `owner_person_id` empty** → `[confidence: HIGH · S2]` naming rule ID + entity + field; the correct value is **not derivable** from the frozen schema, so it stays here despite HIGH confidence. **Counted once, in the fields factor only** — an empty slot instantiates no relationship rule.
- `## Decisions` — **R-PROJ-038 `owner_person_id` names a Person id with no record** while the cross-project-shared tier **is** populated → `[confidence: MEDIUM · S2]` a genuine dangling reference (a record defect, not a coverage gap).
- `## Decisions` — **MTG-104 `relationships[0].target` names a Decision record that does not exist** → `[confidence: HIGH · S3]` referenced-but-absent; `S3` is reached in-rule because a reference asserting a nonexistent record is a contradiction finding.
- `## Auto-Actionable` — **R-PROJ-040 `content_lifecycle_pattern` absent**, and the frozen schema pins exactly one value for this entity → the correct value **is** derivable → `TRACKER_UPDATES:` block. This is the derivability discriminator against the first item.
- `## Unknowns` — **Cross-Project Dependency references unresolvable because the portfolio-level tier holds no record of that type** → excluded from the denominator and **named** in the coverage note; **not** reported as a per-record contradiction (routing row 1 outranks the per-record rows).
- `## Confirmed` — **R-PROJ-041** clean across all three limbs; its Person reference resolves.
- **Score render (mandatory):** `MM-0` as a single 0–100 number with `MM-1` / `MM-2` / `MM-3` each as `n/d`, plus the **entity-type coverage line** (types in denominator vs excluded). The tier banner is a **list** and, with all three tiers holding records here, may legitimately be silent — the type line still renders, and its absence is a FAIL.
- **Must NOT flag:** R-PROJ-041 (clean); any optional field left blank; the seeded-clean COM-032 and the `comms`/`raid`/`sources` items, which belong to other modes.
- **Out of contract:** no stalled-migration escalation is emitted — that seam is reserved and unimplemented. Any stall dimension mentioned reads `UNMEASURED` with its precondition named.

