<!-- Eval fixture — sanitized synthetic project state, MCP-degradation case. No real stakeholder names. -->
# Fixture: UAT-window state with an unavailable MCP (ADR-050 degradation case)

A synthetic single-project state captured mid-UAT, with **Jira unreachable at run time**. Stakeholder names are sanitized placeholders. This fixture exercises the ADR-050 graceful-degradation contract: an uncross-validatable finding must cap at MEDIUM and never enter `## Auto-Actionable`, and the header banner must fire.

## Run condition

```
MCP probe at run start: Confluence OK · Jira UNREACHABLE · Smartsheet OK · SharePoint (no connector)
```

Expected header banner: `[MCP UNAVAILABLE: Jira] — findings limited to local sources` (and SharePoint carries its own link-only note).

## PROJECT.md (local)

```
Project: Synthetic-UAT
Phase: UAT
UAT exit date: Friday April 17, 2026     <!-- CLEAN day-of-week: April 17 2026 is a Friday -->
Defect owner: [OWNER-D]                   <!-- SEEDED-DRIFT attribution, single-source: the only corroborating source would be Jira assignee, which is UNREACHABLE -> must cap at MEDIUM, route to Decisions, NOT Auto-Actionable -->
```

## Carry-forward tracker (local, 04-PMO-Operations/)

```
DEF-007  Open defect triage    Owner: [OWNER-E]   <!-- disagrees with PROJECT.md defect owner [OWNER-D]; the tiebreaker (Jira assignee) is UNREACHABLE -> cannot resolve, MEDIUM, Decisions -->
UAT exit date referenced: April 17, 2026          <!-- agrees with PROJECT.md; Smartsheet (below) also agrees -> two LOCAL+MCP sources agree, HIGH, Confirmed -->
```

## Smartsheet (MCP-primary) — reachable

```
UAT exit: 2026-04-17                      <!-- agrees with PROJECT.md + tracker -> the UAT exit date is HIGH/S0, Confirmed -->
```

## Confluence (MCP-primary) — reachable

```
(no defect-owner statement on the UAT page)   <!-- so the defect-owner disagreement has no audience-facing tiebreaker either -->
```

## Expected categorization (ground truth for the judge)

- **Header** — `[MCP UNAVAILABLE: Jira] — findings limited to local sources` MUST be present.
- `## Confirmed` — UAT exit date April 17 (PROJECT.md + tracker + Smartsheet agree; April 17 2026 is correctly a Friday) → `[confidence: HIGH · S0]`.
- `## Decisions` — Defect owner: PROJECT.md says [OWNER-D], tracker says [OWNER-E]; the only tiebreaker (Jira assignee) was unreachable → `[confidence: MEDIUM · S2]` (capped — NOT HIGH), operator decides. Inline tag `[MCP UNAVAILABLE: Jira]`.
- `## Auto-Actionable` — **MUST be empty / `_(none)_` for the defect-owner finding.** The single-source-because-degraded finding must NOT appear here. (If the judge sees the defect-owner item in `## Auto-Actionable`, the case FAILS — this is the headline assertion.)
- `## Unknowns`, `## Rollup-Diffs` — `_(none)_` for this fixture.
- **Headline assertion (degradation):** the uncross-validatable finding capped at MEDIUM + routed to `## Decisions`, the banner fired, and nothing degraded into auto-action.
