# Suite Contracts — PMO Reference

## Purpose

This file defines the cross-skill contracts that govern how PMO skills interact,
share data, and maintain coherence as a suite. The pmo-skill-editor skill reads
this file in Mode B (Cross-Skill Coherence Review) to validate that skills
honor their contracts with other skills.

---

## Cross-Skill Contract Matrix

Skills produce outputs that other skills consume. Each dependency creates a contract:
the producing skill must output data in a format the consuming skill can parse, and
the consuming skill must not assume data the producing skill does not guarantee.

### Primary Dependencies

| Producing Skill | Output | Consuming Skill(s) | Contract |
|----------------|--------|-------------------|----------|
| **delivery-engine** | Sprint/PI status, blocker list, velocity data | daily-status, weekly-status-rollup, ppm-agent | Status data follows RAG schema; blockers include owner + age + impact |
| **delivery-engine** | DoD compliance assessment | pmo-qa-auditor | DoD assessment includes per-item pass/fail with evidence |
| **ppm-agent** | Risk assessment, RAID entries | delivery-engine, daily-status | RAID entries follow RAID namespace schema; risk scores use P x I or ROAM as configured |
| **ppm-agent** | Stakeholder analysis | comms-writer, change-management | Stakeholder data includes name, role, influence level, communication preference |
| **comms-writer** | Communication drafts | tracker-manager | Draft metadata includes audience, channel, purpose, send-readiness status |
| **pmo-process-designer** | Process designs, requirements | pmo-qa-auditor, pmo-technical-analyst | Process designs follow process-documentation.md template; requirements follow requirements-template.md schema |
| **pmo-technical-analyst** | Technical risk assessment, FDD reviews | ppm-agent, delivery-engine | Technical risks include 6-dimension assessment; FDD reviews follow technical-review-checklist.md |
| **change-management** | Impact assessment, readiness scores | comms-writer, delivery-engine | Impact data follows change-matrix-schema.md; readiness uses standard scale |
| **daily-status** | Daily status entries | weekly-status-rollup | Daily entries follow status log schema with RAG, highlights, blockers, actions |
| **tracker-manager** | Tracker updates | all skills that read trackers | Tracker schema follows tracker-schemas.md; updates include change summary |
| **file-router** | File classification and routing | all skills that create files | Routing follows project folder structure (01-08); tier classification per CLAUDE.md File Management Protocol |
| **artifact-generator** | Generated artifacts | file-router, pmo-qa-auditor | Artifacts land in 08-Generated/ first; include metadata header |

### Secondary Dependencies (Reference Files)

All skills may read reference files. These create implicit contracts:

| Reference File | Skills That Read It | Contract |
|---------------|-------------------|----------|
| push-to-resolve-rubric.md | pmo-qa-auditor | Rubric defines 5 dimensions with 5-point scale; audit results reference dimension scores |
| quality-standard.md | pmo-skill-editor, pmo-qa-auditor | Standard defines 6 quality dimensions; assessments reference dimension levels |
| voice-guide.md | comms-writer | Guide defines tone tiers, formality spectrum, methodology-aware language; all drafts comply |
| audience-profiles.md | comms-writer, change-management | Profiles define stakeholder segments; communications target appropriate segment |
| gate-checklists.md | delivery-engine, pmo-qa-auditor | Checklists define per-gate criteria; gate assessments reference specific checklist items |

---

## Follow-Up Tag Routing Table

Follow-up tags are the mechanism for inter-skill handoffs. A skill emits a tag when
its output requires action by another skill. The tag routes to the correct receiving
skill(s).

| Tag | Emitting Skill(s) | Receiving Skill(s) | Trigger Condition | Expected Action |
|-----|-------------------|-------------------|-------------------|-----------------|
| `[RISK-REVIEW]` | delivery-engine, pmo-technical-analyst | ppm-agent | New risk identified during execution or technical analysis | PPM agent reviews risk, scores, assigns owner, determines response strategy |
| `[COMMS-NEEDED]` | ppm-agent, change-management, delivery-engine | comms-writer | Decision, risk, or status change requires stakeholder communication | Comms-writer drafts appropriate communication for identified audience |
| `[IMPACT-ASSESS]` | delivery-engine, pmo-process-designer | change-management | Scope change, process change, or organizational change identified | Change management assesses impact, affected stakeholders, and readiness implications |
| `[QUALITY-AUDIT]` | any skill | pmo-qa-auditor | Output of a skill operation needs quality review | QA auditor reviews per quality-standard.md and push-to-resolve-rubric.md |
| `[TRACKER-UPDATE]` | any skill | tracker-manager | Data change requires tracker update | Tracker manager applies update with change summary |
| `[TECHNICAL-REVIEW]` | delivery-engine, pmo-process-designer | pmo-technical-analyst | Technical artifact (FDD, integration spec, architecture doc) needs review | Technical analyst reviews per technical-review-checklist.md |
| `[ESCALATION]` | any skill | ppm-agent | Issue exceeds skill's resolution authority or SLA | PPM agent evaluates escalation per SIOR framework and routes appropriately |
| `[PROCESS-REVIEW]` | pmo-qa-auditor | pmo-process-designer | Process gap or design issue identified during audit | Process designer reviews and proposes remediation |
| `[SKILL-UPDATE]` | pmo-qa-auditor | pmo-skill-editor | Skill behavioral gap identified during audit | Skill editor reviews and proposes skill modification |
| `[STATUS-CAPTURE]` | delivery-engine | daily-status | Status data ready for daily capture | Daily status skill formats and logs entry |

---

## Shared Behavioral Contracts

These contracts apply to ALL skills and are enforced by pmo-qa-auditor:

### Evidence Tagging Contract

Every skill output must tag factual claims using the standard evidence quality labels:

| Label | Meaning | When to Use |
|-------|---------|-------------|
| `[SOURCE]` | Verified from authoritative artifact | Data from PROJECT.md, tracker, transcript, official document |
| `[INFERRED]` | Logically derived from available evidence | Conclusions drawn from multiple data points |
| `[ASSUMPTION - CONFIRM]` | Proposed answer to an unknown; requires user confirmation | Unknown facts where agent proposes a reasonable answer |
| `[CONTEXT]` | Provided by user in current session | Information given during the conversation |
| `[RECOMMENDED]` | Agent judgment; explicitly labeled as recommendation | Dates, approaches, or decisions the agent suggests |

### RAID Namespacing Contract

RAID entries use a consistent namespace to prevent ID collisions across skills:

| Prefix | Domain | Example |
|--------|--------|---------|
| `R-` | Risk | R-042: Integration timeline at risk |
| `A-` | Action | A-107: Complete UAT sign-off |
| `I-` | Issue | I-023: Vendor deliverable 3 days late |
| `D-` | Decision | D-015: Approved revised go-live date |

RAID IDs are globally unique within a project. No skill may create a RAID entry
with an ID that already exists. New entries use the next available sequential number.

### Dual Output Contract

Every skill operation must produce both the artifact content AND the metadata/tracking
entry. See `references/dual-output-compliance.md` for detailed compliance checklists.
This contract is non-negotiable — an artifact without metadata is untracked work.

### Date Handling Contract

All dates in skill outputs must be:
- Specific (not ranges: "April 6" not "week of April 6")
- Day-of-week validated ("April 6, 2026 (Monday)")
- Sourced (traceable to PROJECT.md, carry-forward tracker, or user confirmation)
- Labeled `[RECOMMENDED]` when agent-proposed

---

## Contract Versioning Rules

Changes to contracts affect all participating skills. Classification determines
the deployment approach:

| Change Type | Definition | Examples | Deployment |
|-------------|-----------|----------|------------|
| **Breaking** | Changes the interface in a way that existing consumers cannot handle without modification | Renaming a follow-up tag; changing RAID namespace prefixes; removing a required output field; changing evidence label syntax | Requires coordinated release: update contract + all affected skills simultaneously |
| **Non-breaking (additive)** | Adds capability without changing existing interfaces | Adding a new follow-up tag; adding an optional output field; adding a new evidence label | Can be deployed incrementally: update contract first, then update consuming skills |
| **Non-breaking (behavioral)** | Changes guidance or quality criteria without changing interfaces | Raising quality thresholds; adding anti-pattern detection; clarifying existing rules | Deploy via contract update only; consuming skills inherit new guidance on next invocation |

**Version tracking:** Contract changes are tracked in the file's version history
header. Breaking changes increment the major section version. Non-breaking changes
increment the minor section version.

---

## Coherence Check Dimensions

pmo-skill-editor Mode B uses these dimensions to validate suite coherence:

| Dimension | Check | Pass Criteria | Failure Impact |
|-----------|-------|---------------|---------------|
| **Output format consistency** | Do all skills producing the same data type use the same format? | RAID entries from all skills follow the same schema; status data from all skills follows the same RAG format | Format inconsistency causes parsing failures in consuming skills |
| **Tag routing integrity** | Does every emitted tag have at least one receiving skill? | Every tag in the routing table has a defined receiver; no orphan tags | Emitted tags with no receiver create unhandled handoffs |
| **RAID namespace uniqueness** | Do RAID entries across skills use unique IDs? | No duplicate RAID IDs within a project scope | Duplicate IDs cause data corruption in RAID log |
| **Evidence label consistency** | Do all skills use the same evidence label set? | All skills use exactly the 5 standard labels; no skill invents custom labels | Inconsistent labels break QA auditor evidence quality checks |
| **Dual output compliance** | Do all skills produce both artifact and metadata? | Every skill operation produces both outputs per dual-output-compliance.md | Missing metadata creates untracked work; missing artifacts create phantom status |
| **Date handling compliance** | Do all skills follow the date handling contract? | All dates specific, day-validated, sourced, and labeled when recommended | Inconsistent dates create governance confusion |
