---
artifact_type: template
template_family: Executive Status Report Prompt
domain: project
canonical_path: operations/templates/executive-status-report-prompt-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-05
updated: 2026-08-03
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Measurement Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered [Project]_Executive_Status_Report_Prompt.md instance — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Executive Status Report Prompt family (template-taxonomy.md §3.7; §6 row 7 records "no direct plugin" — the Status report canon is consumed by the weekly-status-rollup PMO skill). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# Executive Status Report Prompt — {{PROJECT_NAME}}

**Purpose:** Template for generating leadership-ready status reports.
**Audience:** Executive sponsors, SteerCo, Sponsor leadership
**Cadence:** Weekly or as requested
**Last updated:** {{CREATION_DATE}}

---

## Input Context
- Read: `{{PROJECT_PREFIX}}_Daily_Status_Log.md` (full carry-forward)
- Read: `{{PROJECT_PREFIX}}_RAID_Log.csv` (open risks and issues)
- Read: `PORTFOLIO.md` (cross-project context)
- Read: This week's transcripts (for evidence of progress/blockers)

## Output Format

```
# {{PROJECT_NAME}} — Executive Status Report
**Week of:** {{WEEK_START}} – {{WEEK_END}}
**Prepared by:** [OPERATOR_NAME], Senior Program Manager

## Overall Health: 🟢/🟡/🔴

### Summary (3-5 sentences)
[What happened this week, where we are, what's next]

### Schedule
| Milestone | Target | Status | Notes |
|-----------|--------|--------|-------|

### Key Decisions Made
| Decision | Date | Made By | Impact |
|----------|------|---------|--------|

### Decisions Needed
| Decision | Deadline | Owner | Impact if Delayed |
|----------|----------|-------|------------------|

### Top Risks
| Risk | Severity | Mitigation | Owner |
|------|----------|-----------|-------|

### Blockers Requiring Executive Action
[Only items that need sponsor/SteerCo intervention]

### Next Week Preview
[Top 3-5 items for next week]
```

{{IF DUAL_FRAMING_ENABLED == Yes}}
## Sponsor Frame (Waterfall View)

When producing this report for Sponsor view stakeholders, additionally include:
- Phase-gate status (which gate, % complete, gate review date)
- Milestone burn-down (planned vs. actual)
- Deliverable completion status
- Vendor performance summary (if applicable)
{{ENDIF}}

---

## Quality Rules
- Every claim must cite evidence (transcript, Jira ticket, email)
- Health color must match evidence — no optimistic coloring
- Decisions must name the decision-maker, not just "the team decided"
- Risks must have named owners and concrete mitigations, not "we will monitor"
