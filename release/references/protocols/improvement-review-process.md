# Improvement Review Process — PMO Cowork Platform

**Version:** 1.0
**Effective Date:** 2026-03-18
**Last Updated:** 2026-03-18

---

## Overview

This document defines the weekly continuous improvement review process for the PMO Cowork Platform. Its purpose is to systematically evaluate, triage, and disposition improvement proposals identified during implementation.

---

## Process Cadence

**Review Day:** Thursday, 10:00 AM (weekly)
**Review Duration:** 30–45 minutes
**Review Window:** All proposals submitted by EOD Wednesday are included in Thursday's review
**Next Action Deadline:** Friday EOD (decisions communicated, implementation items queued)

---

## Who Participates

- **Primary Reviewer:** Workspace Owner
- **Secondary Inputs:** Phase leads and skill developers (async prior to review, if needed)
- **Scribe:** Claude Code (documents decisions, updates IMPROVEMENTS.md)

---

## Triage Framework

All proposals are triaged by severity and assigned a disposition:

| Severity | Definition | SLA | Action |
|----------|-----------|-----|--------|
| **P1** | Blocks go-live or introduces critical risk | Immediate decision | Fast-track implementation or reject with justification |
| **P2** | Improves quality, consistency, or maintainability; no blocker | Next sprint or backlog | Queue for scheduled implementation or defer to future phase |
| **P3** | Nice-to-have; improves UX or efficiency | Backlog | Approve for future work or reject if low ROI |

---

## Decision Outcomes

Each proposal receives one of the following decisions:

### Approved → Implement
- **Meaning:** Proposal accepted. Ready to implement immediately or in next sprint.
- **Action:** Move status to `Approved`. Assign implementation target (e.g., "Phase 5 sprint 2" or "Phase 6").
- **Owner:** Assigned to phase lead or skill developer with clear success criteria.

### Approved → Defer
- **Meaning:** Proposal is sound but deferred to a future phase due to timeline or priority constraints.
- **Action:** Move status to `Deferred`. Document deferral reason and target phase.
- **Owner:** Add to Phase N backlog with justification.

### Rejected
- **Meaning:** Proposal rejected due to scope, priority, or ROI concerns.
- **Action:** Move status to `Rejected`. Document rejection reason clearly.
- **Owner:** Close the item; cite in post-mortem if similar proposals recur.

---

## Review Checklist

Before Thursday review, Claude verifies each proposal contains:

- [ ] Severity level (P1, P2, or P3)
- [ ] Category (Skill Update, Structure, Protocol, Routing Rules, or Tracker Schema)
- [ ] Clear description of the improvement
- [ ] Evidence source (regression test, carried item, or observation) with [SOURCE] citation
- [ ] Proposed change (specific file, before/after if applicable)
- [ ] Impact assessment (what improves, what is affected)

**If a proposal is incomplete**, Claude flags it async and author has until Wednesday EOD to revise. Incomplete proposals are reviewed in the following week.

---

## Update Protocol

After each Thursday review, Claude updates IMPROVEMENTS.md within 2 hours:

1. **Status Update:** All reviewed proposals move from `Proposed` → `Approved`, `Deferred`, or `Rejected`.
2. **Decision Date:** Record the Thursday date.
3. **Notes:** Summarize [OPERATOR_NAME]'s feedback or deferral reason.
4. **Backlog Sync:** Any `Approved` or `Deferred` items are added to the relevant phase backlog (if not already tracked).

---

## Escalation for P1 Items

P1 proposals may be escalated for immediate decision outside the Thursday cadence if:
- They block go-live.
- They emerge from critical regression findings.
- They introduce dependency risks.

**Escalation process:**
1. Flag item in IMPROVEMENTS.md with **[URGENT]** prefix in title.
2. Notify [OPERATOR_NAME] directly (email or message).
3. Decision target: 24 hours.
4. Update status immediately upon decision.

---

## Tracking Implementation

Once approved, implementation progress is tracked in the relevant phase backlog:

- **Phase 5 sprint** (ongoing): Items assigned to Phase 5 are tracked in the Phase 5 sprint plan.
- **Future phase**: Items deferred to Phase 6+ are logged in `/Projects/[Project Name]/PROJECT.md` under "Backlog/Future Work."

---

## Post-Closure Review (After Go-Live)

After go-live (Phase 6 or later):

- Continue weekly Thursday reviews for incoming feedback.
- Shift focus from "design gaps" (Phase 1-5) to "operational improvements" (hypercare, UX enhancements, process optimization).
- Archive closed proposals (>30 days old) to `/Projects/[Project Name]/_Archive/improvements-archive.md`.

---

## Roles & Responsibilities

| Role | Responsibility |
|------|-----------------|
| **[OPERATOR_NAME] (Owner)** | Make triage decisions; provide feedback; sign off on implementations |
| **Phase Lead** | Propose improvements; provide context on feasibility; lead implementation if assigned |
| **Skill Developer** | Propose improvements from skill-building experience; implement assigned improvements |
| **Claude (Scribe)** | Prepare agenda; document decisions; update IMPROVEMENTS.md; track implementation |

---

## Templates & Reference

### Improvement Proposal Template

```markdown
### IMP-XXX — [Title]
- **Severity:** P1 / P2 / P3
- **Category:** Skill Update / Structure / Protocol / Routing Rules / Tracker Schema
- **Description:** [What is the improvement?]
- **Evidence:** [What triggered it? Include [SOURCE] citations]
- **Proposed Change:** [Specific file(s) and change description]
- **Impact:** Improves: [what gets better]. Affected: [what is touched].
- **Status:** Proposed
- **Decision Date:** —
- **Notes:** —
```

### IMPROVEMENTS.md Location

`/sessions/cool-gallant-volta/mnt/Claude/Projects/IMPROVEMENTS.md`

---

## Metrics (Future)

Once the process is established, these metrics are tracked:

- **Weekly throughput:** Number of proposals reviewed per week.
- **Average decision time:** Time from proposal submission to decision.
- **Implementation rate:** % of approved items actually implemented.
- **Rejection rate:** % of proposals rejected; track reasons.

---

## Document Control

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-03-18 | Claude Code | Initial process definition |

---

## Questions or Changes?

Contact the workspace owner or raise a meta-improvement proposal in IMPROVEMENTS.md (prefix: **IMP-PROCESS-**).
