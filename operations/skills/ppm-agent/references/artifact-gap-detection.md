# Artifact Gap Detection Rules

## Purpose

Artifact gap detection is a systematic check that runs during ppm-agent processing to identify missing, stale, or incomplete artifacts. Gaps are classified by severity and routed for resolution per push-to-resolve principles.

## Gap Detection Rules by Phase

### Phase Gate Artifact Checklists

Each project phase has a minimum set of artifacts that must exist. Absence of any artifact is a gap.

| Phase | Gate Name | Required Artifacts | Optional (Recommended) |
|-------|-----------|-------------------|----------------------|
| **Initiation** | Project Kickoff Gate | Project Charter/Plan (draft), RAID Log (initialized), Stakeholder Map, RACI matrix | Communications Plan (draft), Resource Plan (draft) |
| **Planning** | Planning Complete Gate | Project Plan (baselined), Resource Plan, Communications Plan, Test Strategy, RAID Log (populated) | Dependency Map, Training Plan (draft) |
| **Sprint Execution** | Sprint DoR (per sprint) | Sprint Backlog, Sprint Goal, Acceptance Criteria per PBI | Refinement pipeline (2+ sprints ahead) |
| **Development Complete** | DoD Gate | Code reviewed, Tests passing (>=80% coverage), Integration tests passing, DoD checklist signed | ADRs for significant decisions |
| **QA** | QA Gate | Test Report, Coverage evidence, Defect density report | Regression suite results, Performance test results |
| **Release Readiness** | Go/No-Go Gate | QA Sign-off, Deployment Runbook (tested), Rollback Plan (documented), Data Migration Plan (if applicable) | Communication plan for go-live, Hypercare plan |
| **Go-Live** | Production Gate | UAT Sign-off, Production Smoke Test results, Post-deployment monitoring configured, Backup completed | Change champion activation evidence |
| **Post-Implementation** | PIR Gate | Post-Implementation Review document, Lessons Learned log | Adoption metrics baseline |
| **Closure** | Project Closure Gate | Deliverable Acceptance record, Final Cost Report, Archived documentation, Lessons Learned (final) | Knowledge transfer evidence |

### Non-Negotiable Artifacts (Never Compress)

These artifacts must exist before their respective gates regardless of schedule pressure:

1. RAID Log (before any gate)
2. Rollback Plan (before deployment)
3. Backup evidence (before deployment)
4. UAT Sign-off (before go-live)
5. Post-deployment monitoring configuration (before go-live)
6. Security review evidence (before go-live)

## Gap Severity Classification

| Severity | Definition | Action Required | Resolution Timeline |
|----------|-----------|----------------|-------------------|
| **Critical** | Blocks gate passage; missing artifact is a non-negotiable prerequisite | Immediate: Stop processing and surface to user. Cannot proceed past gate. | Before gate review |
| **Major** | Does not block gate but creates significant risk if unresolved | Flag with remediation plan: Surface to user with recommended action and timeline | Within current processing cycle |
| **Minor** | Administrative gap; low risk but should be addressed | Log for improvement: Add to carry-forward tracker for next cycle | Within 2 processing cycles |

### Severity Decision Logic

| Question | If Yes | If No |
|----------|--------|-------|
| Does the gate checklist list this artifact as required? | Severity >= Major | Check next question |
| Is this artifact in the non-negotiable list? | Severity = Critical | Check next question |
| Does another artifact reference this one? (cross-reference dependency) | Severity = Major | Check next question |
| Would a stakeholder expect this artifact to exist at this phase? | Severity = Minor | Not a gap — document as intentional omission if needed |

## Staleness Detection

An artifact that exists but hasn't been updated is potentially worse than a missing one — it creates false confidence.

| Artifact Type | Staleness Threshold | Detection Signal | Action |
|--------------|-------------------|-----------------|--------|
| **Living Documents** (RAID Log, trackers) | >5 business days without update | Last modified date older than threshold | Flag: "STALE: [Artifact] last updated [date]. Review for currency." |
| **Baselined Documents** (Project Plan) | >20 business days without review note | No review annotation in the period | Flag: "REVIEW DUE: [Artifact] not reviewed since [date]." |
| **Point-in-Time Snapshots** (Status Reports) | Missed cadence (e.g., weekly report not produced) | Expected snapshot date passed without creation | Flag: "MISSING SNAPSHOT: [Artifact] expected [date], not found." |
| **Context Files** (PROJECT.md) | >2 business days without update during active processing | SESSION_STATE.md fresher than PROJECT.md during active phase | Flag: "DRIFT RISK: PROJECT.md may be stale relative to session state." |

### Staleness Escalation

| Staleness Duration | Severity Escalation |
|-------------------|-------------------|
| 1x threshold | Minor: Flag for review |
| 2x threshold | Major: Surface to user with remediation recommendation |
| 3x threshold | Critical: Block processing that depends on this artifact until refreshed |

## Cross-Reference Validation

When one artifact references another, validate that the referenced artifact exists and is current.

| Reference Pattern | Validation Rule | Gap Type if Failed |
|------------------|----------------|-------------------|
| RAID Log entry references a mitigation plan | Mitigation plan artifact must exist and be current | Major: Mitigation plan missing |
| Status Report cites a metric | Metric source must be verifiable (tracker, tool, calculation) | Minor: Metric unverifiable |
| Project Plan references a dependency | Dependency must appear in RAID Log or Dependency Map | Major: Untracked dependency |
| Test Plan references requirements | Requirements artifact must exist with version matching test plan baseline | Major: Requirements traceability broken |
| Communications Plan references stakeholder groups | Stakeholder Map must exist and be current | Minor: Stakeholder map stale |
| Deployment Runbook references environment | Environment configuration must be documented | Major: Undocumented environment |

## Expected vs. Actual Artifact Inventory Template

For each phase gate review, generate an inventory comparison:

```
## Artifact Inventory: [Phase] Gate Review — [Date]

| # | Expected Artifact | Status | Location | Last Updated | Gap Severity |
|---|-------------------|--------|----------|-------------|-------------|
| 1 | [Artifact name] | Present / Missing / Stale | [Path or N/A] | [Date or N/A] | None / Minor / Major / Critical |
| 2 | ... | ... | ... | ... | ... |

### Gap Summary
- Critical gaps: [count] — [list]
- Major gaps: [count] — [list]
- Minor gaps: [count] — [list]
- Gate recommendation: PASS / PASS WITH CONDITIONS / FAIL
```

**Gate recommendation logic:**
- Any Critical gap = FAIL (no exceptions)
- 2+ Major gaps = FAIL
- 1 Major gap = PASS WITH CONDITIONS (remediation plan required, deadline set)
- Minor gaps only = PASS (logged for improvement)

## Integration with Processing Cycle

Gap detection runs at three points during standard processing:

1. **Session start:** Check governance artifacts (PROJECT.md, RAID Log, SESSION_STATE.md) for staleness
2. **Daily processing:** Check operational artifacts (Daily Status Log, trackers) for currency
3. **Gate approach:** Run full phase checklist when a gate review is imminent (within 5 business days)
