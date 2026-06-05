# Proactive Follow-Up Tracking Protocol

## Purpose

Follow-up tracking turns identified actions into resolved outcomes. This document defines how follow-ups are generated, tracked through their lifecycle, aged, and escalated. The core principle: the agent creates follow-ups with full context (owner, deadline, unblocking conditions) — not just notes that something needs attention.

## Follow-Up Lifecycle

| State | Definition | Entry Condition | Exit Condition |
|-------|-----------|----------------|---------------|
| **Created** | Follow-up identified during processing with owner, deadline, and context assigned | Agent identifies action during any processing activity | Owner acknowledged or deadline set |
| **Assigned** | Owner confirmed; follow-up visible in tracking | Owner identified (may be agent, user, or external party) | Work begins on the follow-up |
| **In Progress** | Active work underway toward resolution | Owner has begun action | Resolution achieved or escalation triggered |
| **Completed** | Follow-up resolved; outcome documented | Action taken, result verified | Removed from active tracking |
| **Escalated** | Follow-up could not be resolved at current level; elevated | Escalation trigger met (see below) | Resolution at escalated level or deferral |
| **Deferred** | Follow-up intentionally postponed with documented reason and reactivation trigger | User decision to defer with stated conditions | Reactivation condition met → returns to Created |

## Proactive Generation Rules

Follow-ups are generated automatically when any of these conditions are detected during processing:

| Trigger | Follow-Up Generated | Priority |
|---------|-------------------|----------|
| **Unresolved action item** in transcript or meeting notes | Follow-up with owner, action, deadline extracted from transcript | Per item urgency |
| **Risk materialized** (RAID issue created from risk) | Follow-up for mitigation execution with owner and timeline | High |
| **Decision pending** identified but not resolved in session | Follow-up with decision needed, decision maker, deadline, and decision inputs | Per decision urgency |
| **Commitment made** by stakeholder in meeting or email | Follow-up to verify commitment fulfilled by stated deadline | Per commitment timeline |
| **Approaching deadline** (<5 business days to milestone or gate) | Proactive readiness check follow-up for gate prerequisites | High |
| **Stale artifact** detected (per artifact-gap-detection.md thresholds) | Follow-up for artifact refresh with owner and staleness details | Per staleness severity |
| **Communication gap** (stakeholder update overdue per communications plan cadence) | Follow-up to draft and send stakeholder communication | Medium |
| **Dependency at risk** (upstream deliverable approaching deadline without confirmation) | Follow-up to verify dependency status with providing team/vendor | High |

**Generation format:** Each generated follow-up includes:
- **What:** Specific action to be taken (not vague)
- **Who:** Owner (named individual or role)
- **When:** Deadline (specific date, day-of-week validated)
- **Why:** Context linking to source (transcript reference, RAID entry, meeting date)
- **Unblocking conditions:** What must happen before this can be resolved (if applicable)

## Follow-Up Aging Rules

| Age Category | Threshold | Visual Signal | Agent Behavior |
|-------------|-----------|--------------|---------------|
| **New** | 0-2 business days | Normal | Track; include in daily processing |
| **Aging** | 2-5 business days | Warning flag | Mention in daily status; check for blockers |
| **Overdue** | >5 business days past deadline | Alert flag | Surface in daily status with escalation recommendation |
| **Stale** | >10 business days past deadline | Critical flag | Escalation trigger (see below); explicit user attention required |

**Aging clock:** Starts from the follow-up's deadline date, not creation date. Follow-ups without deadlines age from creation date and are flagged for deadline assignment after 3 business days.

## Escalation Triggers

Escalation occurs automatically when any of these conditions are met:

| Trigger | Escalation Action | SIOR Required |
|---------|------------------|---------------|
| **Overdue + High Priority** | Surface to user with impact analysis and recommended action | Yes |
| **Blocked + No Resolution Path** | Surface blocker with options for unblocking | Yes |
| **Repeated Deferrals** (same follow-up deferred 2+ times) | Surface pattern to user; recommend resolution or explicit cancellation | Yes |
| **Cascade Risk** (follow-up delay impacts downstream milestone) | Surface dependency chain and impact timeline | Yes |
| **Owner Unresponsive** (no progress update in 2x the expected timeframe) | Surface to user for re-assignment or direct engagement | Yes |

**SIOR format for escalation:**
- **Situation:** What is the follow-up and its current state
- **Impact:** What happens if it remains unresolved (quantified where possible)
- **Options:** 2-3 viable resolution paths
- **Recommendation:** Which option the agent recommends and why

## 5-Phase Proactive Next Steps Model

Every processing output includes proactive next steps organized in five phases:

| Phase | Horizon | Content | Example |
|-------|---------|---------|---------|
| **1. Immediate Actions** | Today / next 24 hours | Actions that can and should be taken now | "Send vendor follow-up email on integration timeline" |
| **2. Short-Term Follow-Ups** | This week (2-5 business days) | Actions needed within the current work week | "Schedule UAT kickoff meeting for Thursday" |
| **3. Upcoming Gates** | Next 2 weeks (5-10 business days) | Approaching decision points, gates, or milestones | "Sprint 8 planning on April 8 — backlog refinement needed by April 6" |
| **4. Risk Mitigations** | Active monitoring items | Risks being monitored with trigger conditions | "Vendor delay risk: if no response by April 3, activate contingency plan" |
| **5. Strategic Opportunities** | Longer horizon / proactive improvements | Opportunities to improve delivery, stakeholder engagement, or process | "Recommend scheduling a mid-project retrospective to capture lessons before Phase 3" |

**Phase assignment rules:**
- Phase 1 items must be actionable today — no "begin planning" language
- Phase 2-3 items have specific dates (day-of-week validated)
- Phase 4 items have explicit trigger conditions, not vague monitoring language
- Phase 5 items are optional — only include when genuine opportunities exist; do not pad

## Integration with Daily Processing

Follow-up tracking integrates into the daily processing cycle:

1. **Start of cycle:** Load active follow-ups from carry-forward tracker
2. **During processing:** Generate new follow-ups per generation rules; update status of existing follow-ups based on new information
3. **End of cycle:** Age all follow-ups; trigger escalations; produce 5-phase next steps; update carry-forward tracker
4. **Output:** Follow-up summary section in daily status output with counts by state and aging category
