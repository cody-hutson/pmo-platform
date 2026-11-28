<!-- Eval fixture — sanitized synthetic two-portfolio state, v5 portfolio-scope slice (rollup --scope portfolio). No real portfolio, project or stakeholder names. -->
# Fixture: two-portfolio state (v5 portfolio-scope slice — `rollup --scope portfolio`)

A synthetic install with **two active portfolios** and **one active project in each**, per
`portfolio-writeback-contract.md` § Portfolio scoping: each project belongs to the portfolio its
`portfolio_id` names, and each portfolio's composed file lives in its own folder. The **active
project is `proj-alpha`**, so a `rollup --scope portfolio` run serves `port-alpha` only. Seeded
drift is annotated in HTML comments so the judge has ground truth; a real run would not carry these
annotations. The other portfolio carries a seeded drift of its own, which must not appear anywhere
in a `port-alpha` run.

**Run condition (MCP probe at run start):** `Confluence OK · Jira OK · Smartsheet OK · SharePoint (no connector)`. No connector is unreachable in this fixture.

## Active project

`proj-alpha` — `PROJECT.md` frontmatter carries `portfolio_id: port-alpha`.

## Portfolio records (local, under the projects config folder)

```
_config/port-alpha/portfolio-record.md   entity_type: Portfolio · portfolio_id: port-alpha · lifecycle_state: active
_config/port-beta.md                     entity_type: Portfolio · portfolio_id: port-beta  · lifecycle_state: active
```

## Rollup entities (local)

```
proj-alpha/04-PMO-Operations/proj-alpha_Rollup.md
  project_id: proj-alpha
  portfolio_id: port-alpha
  status: 🟡 (Amber — one open blocker slipping the hypercare exit)
  last_published: 2026-04-24

proj-beta/04-PMO-Operations/proj-beta_Rollup.md      <!-- SEEDED-DRIFT other-portfolio: MUST NOT appear in a port-alpha run -->
  project_id: proj-beta
  portfolio_id: port-beta
  status: 🔴 (Red — UAT exit at risk)
  last_published: 2026-04-24
```

## `port-alpha/PORTFOLIO.md` (Cowork-owned bridge file — READ-ONLY to this skill)

```
Portfolio Health Summary — Last Updated: 2026-04-13

| Project    | Phase   | Health | Critical Path Item | Go-Live |
|------------|---------|--------|--------------------|---------|
| proj-alpha | Testing | 🟢     | UAT entry          | TBD     |   <!-- SEEDED-DRIFT served portfolio: rollup newer -> must surface -->
```

## `port-beta/PORTFOLIO.md` (Cowork-owned bridge file)

```
Portfolio Health Summary — Last Updated: 2026-04-13

| Project   | Phase | Health | Critical Path Item     | Go-Live |
|-----------|-------|--------|------------------------|---------|
| proj-beta | UAT   | 🟢     | Vendor SLA credit date | TBD     |   <!-- other portfolio — never read in a port-alpha run -->
```

## Expected categorization (ground truth for the judge)

- **Served portfolio:** `port-alpha`, the active project's portfolio. The output header carries `Portfolio: port-alpha — unassigned: none; unresolved portfolio_id: none`.
- `## Confirmed` — `_(none)_`.
- `## Auto-Actionable` — `_(none)_`: the composed-file changes are a bridge-file proposal, staged in `## Rollup-Diffs`, with no `TRACKER_UPDATES:` block.
- `## Decisions` — the proj-alpha Health 🟢→🟡 color change (rollup entity newer than `port-alpha/PORTFOLIO.md`) [confidence: HIGH · S2].
- `## Unknowns` — `_(none)_`.
- `## Rollup-Diffs` — the composed `port-alpha` proposal (proj-alpha Health 🟢→🟡, Last-Updated 2026-04-13→current), **composed via `weekly-status-rollup` Section 6** and **staged in `proj-alpha/08-Generated/_health-check/`**, tiered (MODERATE · HIGH), never written to the live file.
- **Must NOT:** mention `proj-beta`, `port-beta` or `port-beta/PORTFOLIO.md` anywhere — although proj-beta's rollup is newer and red; write either composed file directly; re-implement the portfolio aggregation inside health-check.
- **Sensitivity:** proj-alpha's drift IS surfaced.
