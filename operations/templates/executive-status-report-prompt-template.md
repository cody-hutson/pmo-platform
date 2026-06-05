# Executive Status Report Prompt — {{PROJECT_NAME}}

**Purpose:** Template for generating leadership-ready status reports.
**Audience:** Executive sponsors, SteerCo, SPM leadership
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

{{IF SPM_CO_MANAGED == Yes}}
## SPM Frame (Waterfall View)

When producing this report for SPM stakeholders, additionally include:
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
