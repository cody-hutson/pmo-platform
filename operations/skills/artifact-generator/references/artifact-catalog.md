## Artifact Catalog

The complete catalog of artifacts this skill can produce, organized by category. Each entry
includes the artifact type, typical target folder, and the specialist skill (if any) that
provides domain depth.

This catalog is scoped to **PMO-unique artifacts** — 28 artifacts in 6 categories. Technical
documentation (API docs, README, architecture docs, runbooks, onboarding guides, technical
reference) and PRD / feature-spec artifacts (PRDs, new-feature user stories, acceptance-criteria
docs, success-metric definitions) are **out of scope**: route them per
`references/tech-doc-routing.md` and `references/prd-routing.md` (the routing references and the
"which artifact skill to call" decision tree are authored in the wrapper-mode slice). The
purpose-built Anthropic skills (`engineering/documentation`, `product-management/feature-spec`)
produce those artifacts; the Wrapper Mode re-ingests their output under PMO metadata staging.

### Project Governance → 01-Governance/

| Artifact | Description | Specialist Skill |
|----------|-------------|-----------------|
| Project Overview | One-page project summary: scope, timeline, stakeholders, governance model | — (self-produced) |
| Decision Deck | Structured decision log with options, tradeoffs, recommendations, outcomes | — (self-produced) |
| Executive Readout | Formal executive briefing document with health, risks, decisions | — (self-produced) |
| RAID Log | Consolidated Risks / Assumptions / Issues / Dependencies log | Delivery Engine |
| Project Charter | Project authorization: objectives, scope, governance, sponsor | — (self-produced) |

### Change Management → 01-Governance/Change-Management/

| Artifact | Description | Specialist Skill |
|----------|-------------|-----------------|
| Communication Plan | Stakeholder communication matrix: audience, cadence, channel, owner | Comms Writer |
| Change Impact Assessment | Who is affected, how, what support they need | Change Management |
| Training Plan | Training scope, audience, schedule, materials, delivery method | Change Management |
| Hypercare Plan | Post-go-live support plan: duration, escalation paths, metrics | Change Management |
| Role Impact Matrix | Per-role impact analysis: process changes, system changes, training needs | Change Management |
| Readiness Checklist | Pre-go-live readiness validation across all dimensions | Change Management |
| Change Matrix | Cross-workstream change-event inventory: change, owner, status, target date | Change Management |

### Cutover / Deployment → 01-Governance/

| Artifact | Description | Specialist Skill |
|----------|-------------|-----------------|
| Cutover Plan | Go-live execution plan: sequence, roles, rollback triggers, communication timeline | Delivery Engine |
| Go/No-Go Checklist | Pre-deployment readiness gate: criteria, status, owner, evidence | Delivery Engine |
| Readiness Assessment | Stakeholder and system readiness evaluation across all workstreams | Change Management |

### Operations / Status → 04-PMO-Operations/

| Artifact | Description | Specialist Skill |
|----------|-------------|-----------------|
| Daily Status Update | AM/PM formatted status for Teams posting | Daily Status |
| Meeting Follow-Ups / Action Register | Discrete, trackable follow-up records (What/Who/When/Why/Unblocking + lifecycle state + `source_meeting`) emitted from meeting processing into Open Meetings / Carry-Forward / RAID. Living records — separate lifecycle and home from the recap, which references them by ID | PPM Agent (emit) / Tracker Manager (write) |
| Weekly Status Roll-Up | Cross-project weekly summary for leadership | Weekly Roll-Up |
| Sprint Review Summary | Sprint outcomes, velocity, carry-over, next sprint outlook | Delivery Engine |
| Retrospective Notes | Structured retrospective: what worked, what didn't, action items | — (self-produced) |
| Phase Gate Review Package | Formal phase gate deliverable package for approval | — (self-produced) |

### Waterfall Governance → varies

| Artifact | Description | Specialist Skill |
|----------|-------------|-----------------|
| Milestone Status Report | Phase-gate milestone tracking with status and dependencies | Delivery Engine |
| Deliverable Tracker | Deliverable inventory with completion status and ownership | Delivery Engine |
| Gantt Update Narrative | Written narrative explaining timeline changes and impacts | — (self-produced) |

### Comms-adjacent (routed through comms-writer) → 06-Emails/ or inline

| Artifact | Description | Specialist Skill |
|----------|-------------|-----------------|
| Meeting Agenda | Structured agenda with objectives, timeboxes, pre-reads, attendees | Comms Writer |
| Meeting Recap | Post-meeting **communication**: decisions, reference view of follow-up records, attendees. Point-in-time; references follow-up records by ID, does not own them | Comms Writer |
| Escalation Draft | Escalation package: issue, impact, ask, timeline, recipient | Comms Writer |
| Training Announcement | Go-live or training session announcement with logistics | Comms Writer |
