<!-- reference-durability: allow-link -->
# Health-Check Mode Intents

The queryable 4-intent declarations for every health-check mode. Each mode declares exactly four intent dimensions: `trigger_intent` (the operator situation that should fire it), `decision_intent` (the question it answers), `output_intent` (what the operator does with the result), and `confidence_intent` (where it is assertive vs. cautious). The SKILL.md `## Modes` section is the authority for which modes are implemented; this doc carries the full declarations once.

**v1 implements modes 1–3.** Modes 4–7 are declared here so the contract is complete and the v2 slice fills their bodies into the already-locked shape; **they are not implemented in v1.**

## Mode 1 — `full` (v1)

```yaml
mode_full:
  trigger_intent:    "A high-stakes decision is pending — a cutover, a go-live, an exec brief — and I need to know the total drift state before I act."
  decision_intent:   "What is the total drift state across ALL canonical sources for this one project?"
  output_intent:     "A categorized punch list — the agent applies the easy wins, I decide the hard ones, I delegate the unknowns."
  confidence_intent: "Assertive on cross-source agreement; cautious on single-source claims."
audits: "The union of all per-mode surfaces — runs every other mode's checks and merges their findings into one 5-section report. The default invocation."
```

## Mode 2 — `timeline` (v1)

```yaml
mode_timeline:
  trigger_intent:    "Dates moved or a milestone slipped, and I need to know which tracked dates are now stale."
  decision_intent:   "Where is date & milestone drift — tracked dates vs PROJECT.md / carry-forward / the canonical schedule?"
  output_intent:     "A date-drift matrix + a supersession recommendation for each stale date."
  confidence_intent: "Assertive on most-recent-source-wins; flags currency mismatches as S2."
audits: "Every surfaced date. Validates day-of-week on each date (a wrong weekday is itself a finding) and refuses generalized ranges (CLAUDE.md guardrails). A tracked date no longer matching its canonical source is an S2-SUBSTANTIVE currency mismatch."
```

## Mode 3 — `attribution` (v1)

```yaml
mode_attribution:
  trigger_intent:    "An org change, a role transition, or a vendor swap happened, and I need to know whose recorded ownership is now wrong."
  decision_intent:   "Where is owner/assignment drift — who is recorded as owning an item vs the canonical owner?"
  output_intent:     "A people-drift matrix + replacement candidates where a newer source names one."
  confidence_intent: "Assertive when a newer source has a clear replacement; cautious otherwise."
audits: "Every item's owner. Flags any missing or unverifiable owner (no-fabricated-owners guardrail). Never invents a replacement; proposes one only when a newer canonical source names it, else surfaces the gap."
```

## Mode 4 — `comms` (v2)

```yaml
mode_comms:
  trigger_intent:    "Pre-cascade, or just after a burst of major communications, and I need to know which comms are stale."
  decision_intent:   "What is the lifecycle state of all comms — stale-SENT, obsolete-DRAFT, unsent-READY?"
  output_intent:     "A comms-hygiene action list."
  confidence_intent: "Assertive on lifecycle transitions; cautious on inferring a response."
audits: "The Communications Tracker vs sent/draft/ready state; closes stale items via /comms-writer (status only)."
status: "Declared — implemented in the v2 slice."
```

## Mode 5 — `plan <name>` (v2)

```yaml
mode_plan:
  trigger_intent:    "A plan or playbook finished, or its window closed, and I need to know whether the trackers reflect what it promised."
  decision_intent:   "What is the plan-promised vs trackers-reflected delta for one named plan?"
  output_intent:     "A closure-delta matrix for the named plan."
  confidence_intent: "Cautious — the plan may have been deliberately superseded."
audits: "A single named plan. Takes a plan-name arg; prompts 'which plan?' when none is given — no silent default."
status: "Declared — implemented in the v2 slice."
```

## Mode 6 — `raid` (v2)

```yaml
mode_raid:
  trigger_intent:    "Pre-RAID-review, or after a major event, and I need the RAID log's drift state."
  decision_intent:   "Where is RAID-log drift — closure candidates, orphan IDs?"
  output_intent:     "A RAID-hygiene action list."
  confidence_intent: "Cautious — closing a risk needs evidence."
audits: "The RAID Log. Enforces RAID guardrails: no passive risk voice; name owner + mitigation; flag stale entries."
status: "Declared — implemented in the v2 slice."
```

## Mode 7 — `sources` (v2)

```yaml
mode_sources:
  trigger_intent:    "A Confluence-driven decision is pending and I need to know whether the external sources are fresh."
  decision_intent:   "Where is external-source freshness drift vs PROJECT.md sync timestamps?"
  output_intent:     "A freshness matrix + a sync-direction recommendation + a canonical-source inventory."
  confidence_intent: "Assertive on staleness; cautious on conflict resolution."
audits: "The canonical-source set. Emits the source-of-truth inventory and explicitly flags missing-but-expected sources (the graceful-degradation surface, e.g. SharePoint has no MCP)."
status: "Declared — implemented in the v2 slice."
```
