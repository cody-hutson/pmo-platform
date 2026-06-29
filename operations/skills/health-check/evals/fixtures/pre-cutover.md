<!-- Eval fixture — sanitized synthetic project state. No real stakeholder names. -->
# Fixture: pre-cutover project state

A synthetic single-project state captured the week before a cutover. Stakeholder names are sanitized placeholders (`[OWNER-A]`, `[OWNER-B]`, `[VENDOR-X]`). Seeded drift is annotated in HTML comments so the judge has ground truth; a real run would not carry these annotations.

## PROJECT.md (local)

```
Project: Synthetic-Cutover
Phase: Pre-Cutover
Go-Live: Thursday April 2, 2026          <!-- SEEDED-DRIFT timeline: April 2 2026 is a WEDNESDAY (day-of-week mismatch) AND Jira due date below says April 9 -->
Cutover Owner: [OWNER-A]                  <!-- SEEDED-DRIFT attribution: Confluence on-call page (below) names [OWNER-B] as the new cutover owner -->
UAT Lead: [OWNER-C]                       <!-- CLEAN: agrees with Jira + tracker; must NOT be flagged -->
Test Tracker: SharePoint (Cutover Scoreboard)  <!-- SharePoint has no MCP: content unverifiable, link-only -->
```

## Carry-forward tracker (local, 04-PMO-Operations/)

```
BLK-014  Cutover dry-run sign-off       Owner: (empty)          <!-- SEEDED-DRIFT attribution: no owner of record; no canonical source names one -> Unknowns -->
BLK-021  Data migration validation      Owner: [OWNER-C]        Due: April 1, 2026   <!-- CLEAN -->
Go-Live date referenced: April 2, 2026   <!-- agrees with PROJECT.md but disagrees with Jira (April 9) -> multi-source disagreement -->
```

## Jira (MCP-primary) — set yesterday

```
GO-LIVE epic due date: 2026-04-09        <!-- SEEDED-DRIFT full/timeline: disagrees with PROJECT.md + tracker (April 2); Jira is more recent -> flag LOCAL for update, S2, two-source corroboration (Jira + Smartsheet) -> Auto-Actionable -->
UAT epic assignee: [OWNER-C]             <!-- CLEAN: agrees with PROJECT.md UAT Lead -->
```

## Smartsheet (MCP-primary) — live tracker

```
Cutover date: 2026-04-09                 <!-- agrees with Jira; corroborates the April 9 date -> HIGH confidence on the date-drift finding -->
```

## Confluence (MCP-primary) — on-call page, updated this week

```
Cutover Owner (on-call): [OWNER-B]       <!-- SEEDED-DRIFT attribution: newer source names [OWNER-B]; PROJECT.md still says [OWNER-A] -> replacement candidate, MEDIUM, Decisions -->
```

## Expected categorization (ground truth for the judge)

- `## Confirmed` — UAT Lead = [OWNER-C] (Jira + PROJECT.md agree, recent); BLK-021 owner.
- `## Auto-Actionable` — Go-Live/Cutover date: PROJECT.md + carry-forward say April 2, but Jira + Smartsheet (more recent, two sources agree) say April 9 → `[confidence: HIGH · S2]` propose tracker update; emits a `TRACKER_UPDATES:` block.
- `## Decisions` — Cutover Owner: Confluence on-call (newer) names [OWNER-B], PROJECT.md says [OWNER-A] → `[confidence: MEDIUM · S2]` replacement candidate. Day-of-week mismatch: "Thursday April 2" but April 2 is a Wednesday → `[confidence: HIGH · S2]` verify intended date.
- `## Unknowns` — BLK-014 owner empty; no canonical source names one → searched Jira assignee, tracker owner, on-call page; could not link.
- `## Rollup-Diffs` — PROJECT.md Go-Live April 2 → April 9 staged in `08-Generated/_health-check/` (diff-only, MODERATE · HIGH), never auto-written.
- **Must NOT flag:** UAT Lead, BLK-021 (seeded-clean).
