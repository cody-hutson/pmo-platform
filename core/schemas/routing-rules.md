---
title: File Routing Rules
purpose: Defines the classification patterns the File Router uses to identify file types and route them to target folders — a self-updating ruleset corrected when a user fixes a misclassification.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: file-router (classification + routing); the self-update path when a user corrects a misclassification; the auto-write folder routing
---
# File Routing Rules

## Purpose
Defines classification patterns used by the File Router to identify file types, determine target folders, and route files correctly. This file is self-updating: when a user corrects a misclassification, the File Router proposes an update to this file.

## Classification Strategy (Three Layers)

### Layer 1: Content Analysis (Most Reliable)
Read the first 100 lines. Look for structural indicators:
- Meeting headers, participant lists → Transcript
- Jira column structures (Key, Summary, Status, Priority) → Jira Export
- FDD section headers (Functional Design, Business Rules) → FDD
- Email forwarding patterns (From:, To:, Subject:, FW:, RE:) → Email
- Process flow descriptions, swim lanes → Process Flow
- Test case structures (Test ID, Steps, Expected, Actual) → Test Plan

### Layer 2: Project Identification (For Multi-Project)
Match content against all active PROJECT.md files:
- Participant names from Key People table
- Jira ticket references (project key pattern, e.g., ATP-###)
- System names from Systems Involved section
- Project-specific terminology from Technical Domain section

### Layer 3: Filename Pattern Matching (Secondary Signal)
Never use as sole classifier. Supports Layer 1/2 findings.

## Confidence Thresholds

| Confidence | Threshold | Action |
|-----------|-----------|--------|
| High | ≥90% | Auto-route. No approval for 05/06/08 folders. Approval required for 01-04, 07. |
| Medium | 60-89% | Propose route with reasoning. User confirms or corrects. |
| Low | <60% | Route to 08-Generated/_unclassified/. Add to unclassified queue. |

## File Classification Rules

### Transcripts (→ 05-Transcripts/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Filename: `AM Testing YYYY-MM-DD*` | AM-Testing/ | +20% | Morning testing session, QA discussion |
| Filename: `PM Testing YYYY-MM-DD*` | PM-Testing/ | +20% | Afternoon testing session |
| Filename: `Daily Connect YYYY-MM-DD*` | Daily-Connects/ | +20% | Daily standup, status round-robin |
| Filename: `*Weekly [Ss]tatus [Rr]eport*` | Weekly-Status/ | +20% | Weekly cadence, cross-team updates |
| Filename: `*[Mm]onday [Tt]ouch [Bb]ase*` | Touch-Base/ | +20% | Touch base format, planning |
| Filename: `*SteerCo*` or `*Steering*` | Topic-Sessions/ | +15% | Steering committee, executive review |
| Content: Speaker labels + timestamps | (determine from content) | +30% | Standard transcript format |
| Content: "Transcription Export" suffix | (determine from content) | +25% | Sembly export format |
| Default transcript (no pattern match) | Topic-Sessions/ | — | Fallback for transcripts |

### Emails (→ 06-Emails/ or 06-Comms-Digests/)

| Pattern | Target | Confidence | Content Indicators |
|---------|--------|-----------|-------------------|
| Filename: `FW_*` or `RE_*` | 06-Emails/ | High | Forwarded/replied email |
| Filename: `QA*UAT*status*` (PDF) | 06-Emails/ | High | QA/UAT status report email |
| Content: From:/To:/Subject: headers | 06-Emails/ | +25% | Email format |
| Content: Daily digest format | 06-Comms-Digests/ | +25% | End-of-day summary |

### Design Documents (→ 02-Design/)

| Pattern | Sub-folder | Confidence | Content Indicators |
|---------|-----------|-----------|-------------------|
| Filename: `FDD*` or `*Functional Design*` | FDDs/ | High | FDD section structure |
| Content: Business rules, system behavior | FDDs/ | +20% | Functional specification |
| Filename: `*Process Flow*` | Process Flows/ | High | Flow diagrams, swim lanes |
| Content: Training objectives, learning | Training/ | +20% | Training material |

### Governance (→ 01-Governance/)

| Pattern | Confidence | Content Indicators |
|---------|-----------|-------------------|
| Filename: `*Cutover*` or `*Go-Live*` | High | Cutover checklist, go-live plan |
| Filename: `*Communication Plan*` | High | Stakeholder comm plan |
| Filename: `*Decision Deck*` | High | Decision log or deck |
| Content: Phase gates, milestones, approval workflow | +20% | Governance document |

### Testing (→ 03-Testing/)

| Pattern | Sub-folder | Confidence | Content Indicators |
|---------|-----------|-----------|-------------------|
| Jira export (CSV with Key, Summary, Status columns) | Jira Export/ | High | Jira data structure |
| Filename: `*Test Plan*` or `*Test Exit*` | (root) | High | Test documentation |
| Content: Test case IDs, steps, expected/actual | (root) | +20% | Test artifact |

### Reference (→ 07-Reference/)

| Pattern | Confidence | Content Indicators |
|---------|-----------|-------------------|
| Filename: `*SOP*` or `*Runbook*` | High | Standard operating procedure |
| Content: Step-by-step procedure, operational guide | +15% | Reference material |
| Filename: `*Glossary*` or `*Key Terms*` | High | Terminology reference |

### Change Management (→ 02-Design/Training/ or 01-Governance/)

| Pattern | Target | Confidence | Content Indicators |
|---------|--------|-----------|-------------------|
| Content: Impact assessment, role impact matrix | 02-Design/ | +20% | Change management artifact |
| Content: Training plan, hypercare | 02-Design/Training/ | +20% | Training/readiness |

## Special Rules

### Single-Source Recording Detection
When a transcript shows only one speaker but content references multiple viewpoints, decisions by different people, or uses "we discussed" / "the team agreed" → Flag as [SINGLE-SOURCE RECORDING]. Extract participants from content mentions, not speaker attribution.

### Unclassified Queue Management
Files in 08-Generated/_unclassified/:
- Queue file lists each item with: filename, attempted classification, why confidence was low
- User reviews periodically (prompted during daily processing)
- Each correction → proposed routing rule update
- Transcripts UNASSIGNED for >3 business days → escalated flag in daily output

### Transcript Processing Trigger
After routing a transcript, prompt: "This transcript may trigger operational updates. Process through PPM Agent?"

## Self-Update Protocol

When a user corrects a misclassification:
1. Record the correction: original classification → correct classification
2. Identify what signal was missing or misread
3. Propose a new rule or rule modification to this file
4. File the proposal as a GitHub Issue via the `improvement.yml` template (or `observation.yml` for an under-specified observation)
5. On approval: update this file, test with similar past files if available

## Version History
| Date | Change | Evidence |
|------|--------|---------|
| 2026-03-18 | Initial creation from v3 implementation plan | Phase 1, Task 1.1 |
