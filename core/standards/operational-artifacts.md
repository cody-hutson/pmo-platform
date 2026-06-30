---
title: Operational Artifacts Reference
purpose: The authoritative inventory of the platform's operational artifacts — their lifecycle patterns, tier classifications, cross-artifact dependencies, and stage-artifact mappings that skills read during processing.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: every skill that reads/writes/updates an operational artifact during processing; the stage-artifact mappings in the pipeline; tracker-manager and artifact-generator
---
# Operational Artifacts Reference

## Purpose

This document provides the authoritative inventory of operational artifacts on the PMO platform, their lifecycle patterns, tier classifications, cross-artifact dependencies, and stage-artifact mappings. Skills reference this document to determine which artifacts to read, write, or update during processing.

## Artifact Inventory

### Core Operational Artifacts

| Artifact | Purpose | Update Cadence | Owner Role | Tier | Lifecycle Pattern |
|----------|---------|---------------|-----------|------|------------------|
| **Daily Status Log** | Running record of daily processing outputs, decisions, and actions | Daily | PM / Agent | Tier 2 (Auto-write) | Living Document |
| **Communications Tracker** | Log of all stakeholder communications sent and received | Per communication event | PM / Agent | Tier 2 (Auto-write) | Living Document |
| **Open Meetings Tracker** | Register of scheduled meetings with purpose, attendees, and action items | Per meeting event | PM / Agent | Tier 2 (Auto-write) | Living Document |
| **Transcript Register** | Index of processed meeting transcripts with key decisions and action items | Per transcript processed | PM / Agent | Tier 2 (Auto-write) | Living Document |
| **RAID Log** | Risk, Assumption, Issue, Dependency register with severity, owner, and status | Per event + weekly review | PM | Tier 1 (Approval required) | Living Document |
| **Project Plan** | Scope, timeline, milestones, resource allocation, dependencies | Per change event + monthly review | PM | Tier 1 (Approval required) | Baselined Document |
| **Status Report** | Point-in-time snapshot of project health for stakeholders | Weekly or per cadence | PM / Agent | Tier 1 (Approval required) | Point-in-Time Snapshot |
| **Test Plan** | Test strategy, scope, approach, schedule, entry/exit criteria | Per phase + change events | QA Lead | Tier 1 (Approval required) | Baselined Document |
| **Carry-Forward Tracker** | Tracks items carrying across processing cycles (unresolved actions, pending decisions) | Per processing cycle | PM / Agent | Tier 2 (Auto-write) | Living Document |
| **Meeting Follow-Up Record** | Discrete actionable follow-up emitted from meeting processing (What / Who / When / Why / Unblocking + lifecycle state + `source_meeting`); homed in Open Meetings / Carry-Forward / RAID — distinct from the recap, which references it by ID | Per meeting event | PM / Agent | Tier 2 (Auto-write; RAID-routed = Tier 1) | Living Document |

### Governance Artifacts (Platform-Level)

| Artifact | Purpose | Update Cadence | Tier | Lifecycle Pattern |
|----------|---------|---------------|------|------------------|
| **PROJECT.md** | Project context file — phase, team, dates, systems, key artifacts | Per processing cycle | Tier 4 (Drift detection) | Living Document |
| **PMO.md** | Program governance — cross-project rules, skill protocols | When protocols evolve | Tier 4 (Drift detection) | Baselined Document |
| **PORTFOLIO.md** | Cross-project health snapshot | After any project state change | Tier 4 (Drift detection) | Living Document |
| **SESSION_STATE.md** | Session handoff state between sessions | Per session end | Tier 2 (Auto-write) | Living Document |
| **IMPROVEMENTS.md** | Continuous improvement backlog | On every gap/improvement identified | Tier 2 (Auto-write) | Living Document |

### Recap ↔ Follow-Up boundary

The meeting recap (a Point-in-Time communication) and meeting follow-up records (Living tracked records) are **distinct artifacts with distinct lifecycles and homes**. The recap *references* follow-up records by stable ID (`FU-MTG-NNN`); the tracker is the system of record for follow-up state. "Open follow-ups from meeting X" is answered by querying the tracker on `source_meeting`, never by parsing the recap. The recap renders a read-only reference projection (ID · action · owner · state-as-of-recap-date); it never owns or duplicates mutable follow-up state. This is the canonical home for the boundary contract that comms-writer (Meeting recap type), the meeting-recap output-format spec, and ppm-agent meeting processing all cite.

## Artifact Lifecycle Patterns

| Pattern | Characteristics | Versioning | Update Authorization | Examples |
|---------|----------------|-----------|---------------------|----------|
| **Living Document** | Always reflects current state; change history tracked continuously; never "final" | Continuous; no baseline version | Per tier: Tier 1 = approval, Tier 2 = auto-write | RAID Log, trackers, registers, backlog |
| **Point-in-Time Snapshot** | Created at a specific moment; immutable after creation; historical record | Date-based; never modified after creation | Created per cadence; immutable | Status reports, gate review records, PI reports |
| **Baselined Document** | Requires formal change request for modification; version-controlled | Semantic versioning (Major.Minor.Patch) | Change control process; Tier 1 approval | Project plan, scope statement, test plan, governance docs |

**Semantic versioning for baselined documents:**
- Major = Fundamental change (scope, timeline, budget >10%)
- Minor = Clarification, non-material change
- Patch = Typo, formatting only

**Sacred rule:** Never overwrite — always create new version. Preserve full change history.

## Tier Classification

| Tier | Name | Write Authorization | Agent Behavior | Examples |
|------|------|-------------------|---------------|----------|
| **Tier 1** | Stakeholder-Facing | Approval required | Agent proposes changes; waits for human approval before writing | RAID Log, Project Plan, Test Plan, Status Report, FDDs, Comms Plan |
| **Tier 2** | Operational Trackers | Auto-write | Agent writes updates directly; confirms write to user after | Daily Status Log, Communications Tracker, Transcript Register, SESSION_STATE.md |
| **Tier 3** | New Files | Auto-route with approval | New uploads classified and routed; transcripts auto-write; tracker updates need approval | Uploaded documents, new transcripts |
| **Tier 4** | Context Files | Drift detection | When evidence contradicts a context file, agent flags discrepancy and proposes update | PROJECT.md, PMO.md, CLAUDE.md |

**Auto-write folders:** 05-Transcripts/, 06-Emails/, 08-Generated/ — agent writes freely. All other folders require user approval.

**08-Generated/ staging area:** All agent-generated artifacts land here first. Promoted to target folder only on user approval. Auto-archived after 10 business days if unreviewed.

## Cross-Artifact Dependency Map

Artifacts feed each other in predictable patterns. Understanding these dependencies prevents orphaned updates and ensures cascade awareness.

| Source Artifact | Feeds Into | Dependency Type | Cascade Rule |
|----------------|-----------|----------------|-------------|
| Meeting Transcript | Transcript Register | Content extraction | New transcript → register update (auto) |
| Meeting Transcript | RAID Log | Action item / risk extraction | New risks/issues → RAID update (Tier 1 approval) |
| Meeting Transcript | Communications Tracker | Communication record | Meeting recorded → tracker update (auto) |
| Meeting Transcript | Carry-Forward Tracker | Unresolved action items | Open items → carry-forward update (auto) |
| Meeting Transcript / Meeting (held) | Meeting Follow-Up Record | Actionable follow-up extraction | Held meeting → discrete follow-up records (owner + deadline only); the recap references them by ID, never owns their state (auto; RAID-routed = Tier 1 approval) |
| RAID Log | Status Report | Risk/issue summary | RAID changes → status report refresh (next cadence) |
| RAID Log | Project Plan | Timeline/scope impact | Critical risk materialized → plan review (Tier 1 approval) |
| Daily Status Log | Weekly Status Rollup | Daily aggregation | Daily entries → weekly rollup (per cadence) |
| Carry-Forward Tracker | Daily Status Log | Unresolved items | Carry-forward items → daily processing inputs |
| PROJECT.md | All operational artifacts | Context baseline | PROJECT.md change → review all artifact assumptions |

## Stage-Artifact Mapping

Which artifacts are produced or updated at each lifecycle stage:

| Universal Stage | Artifacts Produced | Artifacts Updated |
|----------------|-------------------|-------------------|
| **Intake** | Intake form, initial business case | Portfolio backlog |
| **Triage** | Triage decision record | RAID Log (if risks identified), Portfolio backlog |
| **Planning** | Project Plan (baseline), Resource plan | RAID Log, Dependency map |
| **Solutioning** | Design documents, ADRs | Project Plan (if scope refined), RAID Log |
| **Engineering** | Code, configuration, implementation artifacts | Daily Status Log, RAID Log, Sprint backlog |
| **Dev Testing** | Test results, defect reports | RAID Log, Quality metrics |
| **QA Testing** | QA report, acceptance evidence | RAID Log, Test Plan (results section) |
| **Plan Review** | Review decision record | Status Report, RAID Log |
| **Execute (Deploy)** | Deployment log, release notes | Status Report, Communications Tracker |
| **Verify** | Verification results | RAID Log, Status Report |
| **Close** | Lessons learned, final status report, closure record | All artifacts (final state archived) |

## Gap Detection Reference

Expected artifacts by project phase — used for artifact gap detection:

| Phase | Minimum Required Artifacts | Critical Gap Signal |
|-------|--------------------------|-------------------|
| **Initiation** | Project Plan (draft), RAID Log, Stakeholder Map | Missing RAID Log = governance gap |
| **Planning** | Project Plan (baselined), Resource Plan, Communications Plan, Test Strategy | Missing Test Strategy = quality gap |
| **Execution** | Daily Status Log, RAID Log (active), Sprint Backlog, Communications Tracker | Missing Daily Status = visibility gap |
| **Testing** | Test Plan, Test Results, Defect Log | Missing Defect Log = quality tracking gap |
| **Deployment** | Deployment Plan, Rollback Plan, Release Notes | Missing Rollback Plan = safety-critical gap |
| **Closure** | Lessons Learned, Final Status, Closure Record | Missing Lessons Learned = learning gap |
