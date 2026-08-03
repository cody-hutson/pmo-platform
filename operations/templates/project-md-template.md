---
artifact_type: template
template_family: PROJECT.md scaffolding
domain: project
canonical_path: operations/templates/project-md-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-05
updated: 2026-08-03
generated_by: release-pipeline v4.06
reviewer: N/A
canon: PMBOK 7 §Planning Performance Domain
canon_compat: none
version: "v4.06"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a scaffolded PROJECT.md instance — an instance starts at the second H1 below ("# PROJECT.md — {{PROJECT_NAME}}"); the first H1 and the paragraph under it are authoring guidance for the Project Initiator skill and are not rendered either. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the PROJECT.md scaffolding family (template-taxonomy.md §3.4 carries no plugin cross-ref; the family takes no §6 row per §2.1 F4). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# PROJECT.md Template

This is the generic template used by the Project Initiator skill. Variables in `{{BRACKETS}}`
are replaced by the skill during project scaffolding. Conditional sections are marked with
`{{IF condition}}...{{ENDIF}}` blocks — the skill includes or omits them based on inputs.

---

# PROJECT.md — {{PROJECT_NAME}}

**Status:** `ACTIVE`
**Last updated:** {{CREATION_DATE}}
**last_synced_with_confluence:** {{CREATION_DATE}}

---

## Project Summary

{{PROJECT_DESCRIPTION}}

**Implementation partner:** {{IMPLEMENTATION_PARTNER}}
**Go-live target:** {{GO_LIVE_TARGET}}
**Current phase:** {{CURRENT_PHASE}}
**Governance model:** {{GOVERNANCE_MODEL}}
**Dual-framing enabled:** {{DUAL_FRAMING_ENABLED}}
{{IF INVESTMENT_CLASS}}
**Investment class:** {{INVESTMENT_CLASS}}
{{ENDIF}}

<!--
OPTIONAL FIELD — `investment_class`. One of `Run` | `Grow` | `Transform` (portfolio
investment classification: Run-the-business / Grow / Transform). This field is OPTIONAL —
omit the whole `{{IF INVESTMENT_CLASS}}` block when the operator has not classified the
project. When the field is ABSENT, downstream consumers (e.g., weekly-status-rollup Section 7.3
Portfolio R-G-T Allocation) class the project as **`Unclassified`** and surface it as a
coverage gap — they never heuristically auto-bucket it from phase or project-type. The field
is read, never invented. (NOTE: investment_class is NOT the capacity-model.md §5 60/20/20
capacity effort-split — a different concept that shares the same digits.)
-->


{{IF GOVERNANCE_MODEL == Agile OR Hybrid}}
### Sprint Tracking

| Sprint | Dates | Goal | Status |
|--------|-------|------|--------|
| Sprint 1 | {{ASSUMPTION – CONFIRM}} | {{ASSUMPTION – CONFIRM}} | Not Started |

**Current sprint:** Sprint 1
**Velocity:** Not yet established
**Jira board:** [{{JIRA_PROJECT_KEY}} Board](https://{{JIRA_BASE_URL}}/jira/software/c/projects/{{JIRA_PROJECT_KEY}}/boards/)
{{ENDIF}}

{{IF GOVERNANCE_MODEL == Waterfall OR Hybrid}}
### Phase-Gate Timeline

| Phase | Planned Dates | Status | Gate Criteria |
|-------|--------------|--------|--------------|
| Initiation | {{ASSUMPTION – CONFIRM}} | In Progress | Charter approved, stakeholders identified |
| Planning | {{ASSUMPTION – CONFIRM}} | Not Started | Requirements baselined, schedule approved |
| Execution | {{ASSUMPTION – CONFIRM}} | Not Started | Deliverables complete, testing passed |
| Go-Live | {{GO_LIVE_TARGET}} | Not Started | Cutover checklist complete, readiness confirmed |
| Hypercare | Post go-live | Not Started | Stabilization criteria met |
{{ENDIF}}

## Key People

| Person | Role | Comm Style / Notes |
|--------|------|-------------------|
| [OPERATOR_NAME] | Senior Program Manager (TPM) | The user. Decision authority on PMO operations. |
| {{SPONSOR_NAME}} | Executive Sponsor | {{SPONSOR_NOTES}} |
| {{TECH_LEAD_NAME}} | Technical Lead | {{TECH_LEAD_NOTES}} |
{{ADDITIONAL_STAKEHOLDERS}}

{{IF IMPLEMENTATION_PARTNER != None}}
**Vendor labeling rule:** All {{IMPLEMENTATION_PARTNER}} consultants must be labeled "({{PARTNER_ABBREVIATION}})" consistently.
{{ENDIF}}

## Systems Involved

{{SYSTEMS_LIST}}

## Technical Domain

{{TECHNICAL_DOMAIN_NOTES}}

## Jira Project

{{IF GOVERNANCE_MODEL == Agile OR Hybrid}}
- **Project key:** {{JIRA_PROJECT_KEY}}
- **Board:** [{{JIRA_PROJECT_KEY}} Board](https://{{JIRA_BASE_URL}}/jira/software/c/projects/{{JIRA_PROJECT_KEY}}/boards/)
- **Bug naming:** {{JIRA_PROJECT_KEY}}-### (e.g., {{JIRA_PROJECT_KEY}}-001)
- **Priority levels:** P1 Critical, P2 High, P3 Moderate, P4 Low
{{ENDIF}}

{{IF GOVERNANCE_MODEL == Waterfall}}
- **Tracking tool:** Smartsheet (exported CSV/XLSX for analysis)
- **Milestone tracker:** {{ASSUMPTION – CONFIRM: Smartsheet URL or location}}
{{ENDIF}}

## Operational Artifacts (04-PMO-Operations)

| Artifact | Purpose | Current State |
|----------|---------|---------------|
| `{{PROJECT_PREFIX}}_Daily_Status_Log.md` | Carry-forward tracker. Single source of truth for what's open. | Initialized — empty |
| `{{PROJECT_PREFIX}}_Communications_Tracker.md` | Outbound messages (MSG-##), lifecycle tiers, response tracking. | Initialized — empty |
| `{{PROJECT_PREFIX}}_Open_Meetings_Tracker.md` | Meeting packages (MTG-##), scheduling status. | Initialized — empty |
| `{{PROJECT_PREFIX}}_Transcript_Register.md` | Transcript processing log with tags and summaries. | Initialized — empty |
| `{{PROJECT_PREFIX}}_Daily_Status_Update_Framework.md` | Prompt templates for status updates. | Initialized — customize for meeting cadence |
| `Executive_Status_Report_Prompt.md` | Prompt template for leadership reports. | Initialized |
| `{{PROJECT_PREFIX}}_RAID_Log.csv` | Risks, assumptions, issues, dependencies. | Initialized — empty |
| `Key Terms Glossary.csv` | Project terminology. | Initialized — empty |
{{IF GOVERNANCE_MODEL == Agile OR Hybrid}}
| `{{PROJECT_PREFIX}}_Sprint_Tracker.md` | Sprint planning, velocity, capacity tracking. | Initialized — empty |
{{ENDIF}}
{{IF GOVERNANCE_MODEL == Waterfall}}
| `{{PROJECT_PREFIX}}_Milestone_Tracker.md` | Phase-gate milestone tracking with evidence. | Initialized — empty |
{{ENDIF}}
{{IF DUAL_FRAMING_ENABLED == Yes}}
| `{{PROJECT_PREFIX}}_Dual_Framing_Bridge.md` | Milestone-to-sprint mapping, dual-frame status. | Initialized — empty |
{{ENDIF}}

## Governance Links

- **Confluence space:** {{CONFLUENCE_SPACE}}
{{IF GOVERNANCE_MODEL == Agile OR Hybrid}}
- **Jira board:** [{{JIRA_PROJECT_KEY}} Board](https://{{JIRA_BASE_URL}}/jira/software/c/projects/{{JIRA_PROJECT_KEY}}/boards/)
{{ENDIF}}
{{IF DUAL_FRAMING_ENABLED == Yes}}
- **SharePoint folder:** {{ASSUMPTION – CONFIRM: SharePoint URL}}
- **Smartsheet:** {{ASSUMPTION – CONFIRM: Smartsheet URL}}
{{ENDIF}}

## File Conventions

- **Transcripts** preserve original filenames. Sub-folders in 05-Transcripts/ match meeting cadence.
- **Operational artifacts** (`.md`) in `04-PMO-Operations/` are the working copies — Claude edits these directly (Tier 2).
- **Governance artifacts** in `01-Governance/` are Tier 1 — Claude proposes changes, user approves.

## MCP Connector Configuration

{{IF GOVERNANCE_MODEL == Agile OR Hybrid}}
- **Jira:** Project key `{{JIRA_PROJECT_KEY}}` — verify MCP connector has access
{{ENDIF}}
- **Confluence:** Space key `{{CONFLUENCE_SPACE}}` — verify MCP connector has access
{{IF GOOGLE_DRIVE_CONNECTED}}
- **Google Drive:** Transcript folder configured for automated ingestion
{{ENDIF}}

## Sync Tracking

| Field | Value |
|-------|-------|
| last_synced_with_confluence | {{CREATION_DATE}} |
| sync_check_threshold | 3 business days |
| sync_direction | Bidirectional (Confluence ↔ PROJECT.md) |

When `last_synced_with_confluence` exceeds the threshold, Claude flags a sync check as part
of daily processing output. The user decides sync direction:
- **Confluence → PROJECT.md:** Someone updated Confluence directly
- **PROJECT.md → Confluence:** Claude detected a needed update from artifact processing
