<!-- reference-durability: allow-link -->
# Health-Check Mode Intents

The queryable 4-intent declarations for every health-check mode. Each mode declares exactly four intent dimensions: `trigger_intent` (the operator situation that should fire it), `decision_intent` (the question it answers), `output_intent` (what the operator does with the result), and `confidence_intent` (where it is assertive vs. cautious). The SKILL.md `## Modes` section is the authority for which modes are implemented; this doc carries the full declarations once.

**All nine modes are implemented.** Modes 1–3 are the foundation drift-core (the v1 slice); modes 4–7 are the extended set (the v2 slice); mode 8 (`rollup`) is the on-demand rollup-invocation mode (the v3 slice); mode 9 (`structure`) is the entity-completeness audit (the v4 slice) — all filled into the same locked contract. The slice labels record provenance, not implementation status.

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
status: "Implemented (v2 slice)."
```

## Mode 5 — `plan <name>` (v2)

```yaml
mode_plan:
  trigger_intent:    "A plan or playbook finished, or its window closed, and I need to know whether the trackers reflect what it promised."
  decision_intent:   "What is the plan-promised vs trackers-reflected delta for one named plan?"
  output_intent:     "A closure-delta matrix for the named plan."
  confidence_intent: "Cautious — the plan may have been deliberately superseded."
audits: "A single named plan. Takes a plan-name arg; prompts 'which plan?' when none is given — no silent default."
status: "Implemented (v2 slice)."
```

## Mode 6 — `raid` (v2)

```yaml
mode_raid:
  trigger_intent:    "Pre-RAID-review, or after a major event, and I need the RAID log's drift state."
  decision_intent:   "Where is RAID-log drift — closure candidates, orphan IDs?"
  output_intent:     "A RAID-hygiene action list."
  confidence_intent: "Cautious — closing a risk needs evidence."
audits: "The RAID Log. Enforces RAID guardrails: no passive risk voice; name owner + mitigation; flag stale entries."
status: "Implemented (v2 slice)."
```

## Mode 7 — `sources` (v2)

```yaml
mode_sources:
  trigger_intent:    "A Confluence-driven decision is pending and I need to know whether the external sources are fresh."
  decision_intent:   "Where is external-source freshness drift vs PROJECT.md sync timestamps?"
  output_intent:     "A freshness matrix + a sync-direction recommendation + a canonical-source inventory."
  confidence_intent: "Assertive on staleness; cautious on conflict resolution."
audits: "The canonical-source set. Emits the source-of-truth inventory and explicitly flags missing-but-expected sources (the graceful-degradation surface, e.g. SharePoint has no MCP)."
status: "Implemented (v2 slice)."
```

## Mode 8 — `rollup` (v3)

```yaml
mode_rollup:
  trigger_intent:    "I need to refresh a rollup on demand — up-to-portfolio or down-through one project — rather than wait for the scheduled cadence."
  decision_intent:   "Is the rollup surface current — does PORTFOLIO.md match the composed per-project rollup entities (portfolio), or does one project's rollup entity match its sub-entities (project)?"
  output_intent:     "A 5-section punch list; portfolio composition is routed to weekly-status-rollup and staged in 08-Generated/_health-check/; project refresh emits TRACKER_UPDATES for the rollup entity."
  confidence_intent: "Assertive on rollup-entity freshness drift; cautious on composed portfolio health (routes the write to weekly-status-rollup)."
audits: "The project↔portfolio rollup contract on demand. `--scope portfolio` audits per-project rollup-entity freshness vs PORTFOLIO.md and composes the PORTFOLIO.md proposal via weekly-status-rollup Section 6 (compose-not-absorb), staged in 08-Generated/_health-check/. `--scope project --depth full|status` refreshes one project's rollup entity from a Milestones/RAID/Plans/Resources sub-entity scan, routed via TRACKER_UPDATES. Arg-required and excluded from the full sweep. Contract-tolerant when the rollup entity / portfolio-writeback contract is absent (surfaces a ## Unknowns coverage-gap). See references/rollup-mode.md."
status: "Implemented (v3 slice)."
```

## Mode 9 — `structure` (v4)

```yaml
mode_structure:
  trigger_intent:    "A high-stakes decision is pending and I need to know whether this project's DATA is complete enough to trust — not whether it drifted, but whether the records, fields and links exist at all."
  decision_intent:   "Is every required entity present, every required field populated, and every required relationship valid, per the frozen entity model and field schemas?"
  output_intent:     "A 0-100 completeness score with a three-factor breakdown and a named coverage envelope, plus per-violation findings naming the rule ID, entity and field."
  confidence_intent: "Assertive on auto-graded L1/L2 schema rules; cautious on subjective completeness (never asserts 'enough' of anything); refuses to score what it could not measure."
audits: "The schema-conformance axis, for each entity in the derived expected set: (a) entity present at its declared storage_tier home, (b) required fields populated, (c) required relationships resolve. Population is entity RECORDS, never files (the project-entity-model boundary axiom). Reports MM-0 = MM-1 x MM-2 x MM-3 as a single 0-100 number — the metrics are defined in the migration-enforcement protocol and cited here, never redefined — with MM-1 and MM-2 rendered n/d and MM-3 rendered as its per-project STATE (composed/partial/monolith) — MM-3 is Composed-Index Conformance, not a link ratio and not 'relationships valid', so rendering it n/d is a defect — a mandatory entity-type coverage line, a list-form unpopulated-tier banner, and UNMEASURED rather than 0% for any factor that could not be measured. Rule authority is cited by rule ID from entity-field-schemas.md; no rule text and no rule count is copied. Every violation names rule ID + entity + field/relationship — a bare count is not a finding. Takes --scope <project> only. See references/structure-mode.md."
status: "Implemented (v4 slice)."
```

## Declared `full`-sweep membership

`full` (mode 1) sweeps the modes declaring membership below. **This table is the authority** — `SKILL.md` states the rule and carries no list of exceptions, so adding a mode means adding a row here rather than editing prose in two places. A mode is a member unless it (a) requires an argument `full` cannot supply, or (b) audits a different axis from the drift axis `full` sweeps.

| Mode | `full_sweep_member` | Reason when false |
|---|---|---|
| `full` | n/a | it *is* the sweep |
| `timeline` | yes | — |
| `attribution` | yes | — |
| `comms` | yes | — |
| `plan <name>` | **no** | (a) arg-required — needs a named plan `full` cannot supply; `full` audits the project, not one named plan |
| `raid` | yes | — |
| `sources` | yes | — |
| `rollup` | **no** | (a) arg-required — needs `--scope` direction (and `--depth`); it is a compose/refresh operation, not a drift audit |
| `structure` | **no** | (b) different axis — audits schema conformance (record vs frozen schema), not drift (tracked state vs canonical sources). Folding it in would report one underlying gap under two or three framings in a single report |
