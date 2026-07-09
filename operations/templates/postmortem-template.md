---
artifact_type: template
template_family: Postmortem
domain: software
canonical_path: operations/templates/postmortem-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: Google SRE Workbook §Postmortem Culture
canon_compat: plugin-aligned
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered postmortem instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5(a)): `plugin-aligned` records the ANTICIPATED alignment path at DRAFT — authoritative only at an APPROVED transition. Registry basis: plugin `engineering:incident-response` is the registered cross-ref for the Postmortem family per template-taxonomy.md §6 row 6 + §7 localization audit trail (inventory dated 2026-05-10); this template carries the Google SRE §Postmortem Culture structure. Live-plugin check 2026-07-03/04: the engineering:*/operations:*/product-management:* plugin suites are NOT installed in this workspace and NOT present in the marketplace roster — alignment is registry-anticipated, not live-verified. P5 re-evaluates against the live plugin at any future APPROVED transition. -->

# Postmortem: {{INCIDENT_TITLE}}

**Purpose:** Blameless record of an incident — impact, causes, and the actions that prevent recurrence — so the system improves and individuals are never the root cause.
**Canon:** Google SRE Workbook §Postmortem Culture — binding per `core/standards/template-taxonomy.md` §6 row 6 (Anthropic `engineering:incident-response` plugin cross-referenced there; availability re-verified at promotion, L4 gate P5).
**Incident date:** {{INCIDENT_DATE}} · **Authors:** {{AUTHORS}} · **Reviewers:** {{REVIEWERS}} · **Status:** {{DRAFT | IN REVIEW | REVIEWED | ACTION ITEMS COMPLETE}} · **Tracking:** {{TRACKING_REF}}

> **Blameless discipline (SRE):** assume everyone acted with good intent on the information they had. Name systems, gaps, and incentives — never individuals — as causes.

---

## Summary

{{SUMMARY}} <!-- 2-4 sentences: what happened, how bad, how long, current state. -->

## Impact

{{IMPACT}} <!-- Duration; users/systems/projects affected; quantified where possible (requests failed, hours lost, commitments missed). -->

## Root Causes

- {{ROOT_CAUSE_1}} <!-- Systemic and blameless; keep asking why until a process/system answer, not a person. -->

## Trigger

{{TRIGGER}} <!-- The proximate event that turned latent conditions into impact. -->

## Detection

{{DETECTION}} <!-- How it was noticed (alert / user report / luck), time-to-detect, and whether detection should have fired earlier. -->

## Resolution

{{RESOLUTION}} <!-- What ended the impact (mitigation vs fix), and when. -->

## Action Items

| # | Action | Type | Owner | Priority | Tracking | Status |
|---|---|---|---|---|---|---|
| 1 | {{ACTION_1}} | {{PREVENT/MITIGATE/DETECT/PROCESS}} | {{OWNER_1}} | {{P1-P4}} | {{TRACKING_REF_1}} | {{OPEN/DONE}} |
| {{ASSUMPTION – CONFIRM}} | | | | | | |

## Lessons Learned

**What went well:**
- {{WENT_WELL_1}}

**What went wrong:**
- {{WENT_WRONG_1}}

**Where we got lucky:**
- {{GOT_LUCKY_1}}

## Timeline

| Time ({{TIMEZONE}}) | Event |
|---|---|
| {{HH:MM}} | {{EVENT_1}} |

## Supporting Information

{{SUPPORTING_INFO}} <!-- Links to logs, dashboards, chat threads, related incidents. -->
