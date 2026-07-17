<!-- Eval fixture — sanitized synthetic portfolio state, v3 rollup mode (--scope portfolio). No real stakeholder names. -->
# Fixture: two-project portfolio state (v3 rollup mode — `--scope portfolio`)

A synthetic **portfolio** state with **two active projects**, each carrying a per-project
rollup entity, plus a PORTFOLIO.md that has partially drifted from those entities.
Stakeholder names are sanitized placeholders (`[OWNER-H]`, `[OWNER-J]`). Seeded drift is
annotated in HTML comments so the judge has ground truth; a real run would not carry these
annotations. This fixture exercises the up-to-portfolio compose direction: the rollup mode
audits per-project rollup-entity freshness vs PORTFOLIO.md, then routes the PORTFOLIO.md
composition to `weekly-status-rollup` Section 6 and stages the proposal — it never writes
PORTFOLIO.md directly.

**Run condition (MCP probe at run start):** `Confluence OK · Jira OK · Smartsheet OK · SharePoint (no connector)`. No connector is unreachable in this fixture.

## Project Alpha — rollup entity (local, Synthetic-Alpha/04-PMO-Operations/Synthetic-Alpha_Rollup.md)

```
status: 🟡 (Amber — one open blocker slipping the hypercare exit)   <!-- rollup entity refreshed 2026-04-24 -->
top_risks: [ "R-ALPHA-004 defect backlog above exit threshold" ]
key_dependencies: [ "Beta UAT sign-off feeds Alpha's integration test" ]
capacity_signal: "war-room fully staffed through exit"
milestone_delta: "Hypercare exit slipped Friday April 24 -> not yet re-baselined"
completeness_score: 0.9
last_published: 2026-04-24
```

## Project Beta — rollup entity (local, Synthetic-Beta/04-PMO-Operations/Synthetic-Beta_Rollup.md)

```
status: 🟢 (Green — UAT on track)                                   <!-- rollup entity refreshed 2026-04-24 -->
top_risks: [ "R-BETA-002 vendor SLA credit deadline" ]
key_dependencies: [ "none blocking this cycle" ]
capacity_signal: "nominal"
milestone_delta: "UAT exit on plan for Friday April 24"
completeness_score: 0.95
last_published: 2026-04-24
```

## PORTFOLIO.md (Cowork-owned Layer-3 bridge file — READ-ONLY to this skill)

```
Portfolio Health Summary — Last Updated: 2026-04-13

| Project          | Phase     | Health | Critical Path Item                 | Go-Live |
|------------------|-----------|--------|------------------------------------|---------|
| Synthetic-Alpha  | Testing   | 🟢     | UAT entry                          | TBD     |   <!-- SEEDED-DRIFT rollup: Alpha's rollup entity (2026-04-24) says Phase Hypercare + Health 🟡; PORTFOLIO.md (last updated 2026-04-13) still shows Testing + 🟢 -> freshness drift, PORTFOLIO.md lags the rollup entity -->
| Synthetic-Beta   | UAT       | 🟢     | Vendor SLA credit deadline         | TBD     |   <!-- CLEAN: matches Beta's rollup entity (UAT, 🟢) -> must NOT be flagged -->
```

## Confluence / Jira / Smartsheet (MCP-primary) — reachable

```
(No portfolio-level source of truth beyond the per-project rollup entities; PORTFOLIO.md is composed FROM them.)
```

## Expected categorization (ground truth for the judge)

- `## Confirmed` — Synthetic-Beta portfolio row is current vs Beta's rollup entity (Phase UAT, Health 🟢 agree) → no action.
- `## Auto-Actionable` — `_(none)_` for the portfolio compose: the PORTFOLIO.md field changes are a **bridge-file proposal**, not a project-tracker update, so they do NOT emit a `TRACKER_UPDATES:` block here; they are staged in `## Rollup-Diffs`.
- `## Decisions` — (optional) the Alpha Health 🟢→🟡 color change may carry a reversibility tier + confidence if surfaced as a decision-class item.
- `## Unknowns` — `_(none)_` (both projects have rollup entities present in this fixture).
- `## Rollup-Diffs` — the composed **PORTFOLIO.md proposal** (Synthetic-Alpha: Phase Testing→Hypercare, Health 🟢→🟡, Last-Updated 2026-04-13→current) — **composed via `weekly-status-rollup` Section 6**, re-homed and **staged in `08-Generated/_health-check/`**, tiered (MODERATE · HIGH), **never written to the live PORTFOLIO.md**.
- **Compose-not-absorb:** the composition is **routed to `weekly-status-rollup`**, not re-derived inside health-check.
- **Must NOT:** write PORTFOLIO.md directly; flag the clean Synthetic-Beta row; re-implement the portfolio aggregation inside health-check.
