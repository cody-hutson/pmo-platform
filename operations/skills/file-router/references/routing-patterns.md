# Routing Patterns — File Classification Rules

This file is the complete reference for all file classification patterns used by the File Router.
It is self-updating: when a user corrects a misclassification, the File Router proposes an update
to this file via the IMPROVEMENTS.md workflow.

**Version:** 1.0
**Last updated:** 2026-03-18

---

## Transcripts (→ 05-Transcripts/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Filename: `AM Testing YYYY-MM-DD*` | AM-Testing/ | +20% | Morning testing session, QA discussion |
| Filename: `PM Testing YYYY-MM-DD*` | PM-Testing/ | +20% | Afternoon testing session |
| Filename: `Daily Connect YYYY-MM-DD*` | Daily-Connects/ | +20% | Daily standup, status round-robin |
| Filename: `*Weekly [Ss]tatus [Rr]eport*` | Weekly-Status/ | +20% | Weekly cadence, cross-team updates |
| Filename: `*[Mm]onday [Tt]ouch [Bb]ase*` | Touch-Base/ | +20% | Touch base format, planning discussion |
| Filename: `*SteerCo*` or `*Steering*` | Topic-Sessions/ | +15% | Steering committee, executive review |
| Content: Speaker labels + timestamps | (determine from content) | +30% | Standard transcript format |
| Content: "Transcription Export" suffix | (determine from content) | +25% | Sembly export format |
| Default transcript (no pattern match) | Topic-Sessions/ | — | Fallback for recognized transcripts |

## Emails (→ 06-Emails/)

| Pattern | Target | Confidence Boost | Content Indicators |
|---------|--------|-----------------|-------------------|
| Filename: `FW_*` or `RE_*` | 06-Emails/ | +15% | Forwarded/replied email |
| Filename: `QA*UAT*status*` (PDF) | 06-Emails/ | +15% | QA/UAT status report email |
| Content: From:/To:/Subject: headers | 06-Emails/ | +25% | Email format |
| Content: Daily digest format | 06-Emails/ | +20% | End-of-day summary |

## Design Documents (→ 02-Design/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Filename: `FDD*` or `*Functional Design*` | FDDs/ | +15% | FDD section structure |
| Content: Business rules, system behavior, functional specs | FDDs/ | +20% | Functional specification |
| Filename: `*Process Flow*` | Process Flows/ | +15% | Flow diagrams, swim lanes |
| Content: Training objectives, learning outcomes | Training/ | +20% | Training material |

## Governance (→ 01-Governance/)

| Pattern | Confidence Boost | Content Indicators |
|---------|-----------------|-------------------|
| Filename: `*Cutover*` or `*Go-Live*` | +15% | Cutover checklist, go-live plan |
| Filename: `*Communication Plan*` | +15% | Stakeholder comm plan |
| Filename: `*Decision Deck*` | +15% | Decision log or deck |
| Content: Phase gates, milestones, approval workflow | +20% | Governance document |

## Testing (→ 03-Testing/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Jira export (CSV with Key, Summary, Status columns) | Jira Export/ | +25% | Jira data structure |
| Filename: `*Test Plan*` or `*Test Exit*` | (root) | +15% | Test documentation |
| Content: Test case IDs, steps, expected/actual | (root) | +20% | Test artifact |

## Reference (→ 07-Reference/)

| Pattern | Confidence Boost | Content Indicators |
|---------|-----------------|-------------------|
| Filename: `*SOP*` or `*Runbook*` | +15% | Standard operating procedure |
| Content: Step-by-step procedure, operational guide | +15% | Reference material |
| Filename: `*Glossary*` or `*Key Terms*` | +15% | Terminology reference |

## Change Management (→ 02-Design/ or 01-Governance/)

| Pattern | Target | Confidence Boost | Content Indicators |
|---------|--------|-----------------|-------------------|
| Content: Impact assessment, role impact matrix | 02-Design/ | +20% | Change management artifact |
| Content: Training plan, hypercare plan | 02-Design/Training/ | +20% | Training/readiness |
| Content: Readiness checklist, adoption tracking | 01-Governance/ | +15% | Go-live readiness |

## PMO Operations (→ 04-PMO-Operations/)

| Pattern | Confidence Boost | Content Indicators |
|---------|-----------------|-------------------|
| Content: Carry-forward items, blocker tracking | +20% | Status log format |
| Content: MSG-### entries, communication tracking | +20% | Communications tracker |
| Content: MTG-### entries, meeting scheduling | +20% | Meetings tracker |

---

## Special Rules

### Single-Source Recording Detection
When a transcript shows only one speaker but content references multiple viewpoints:
- Flag as `[SINGLE-SOURCE RECORDING]`
- Extract participants from content mentions, not speaker attribution
- Note in Transcript Register entry

### Non-Project Files
Files that match no active project and contain no project-related content:
- 1:1 meetings, personal discussions, general company meetings
- Route to `Non-Project/` folder at workspace root
- Or discard per user preference setting

### Ambiguous Multi-Project Files
Files referencing multiple projects (cross-project meetings, shared resources):
- Present all matching projects with confidence scores
- User selects primary project
- Note cross-references in routing summary

---

## Version History

| Date | Change | Evidence |
|------|--------|---------|
| 2026-03-18 | Initial creation from Phase 1 routing-rules.md | Phase 2, Task 2.1 |
