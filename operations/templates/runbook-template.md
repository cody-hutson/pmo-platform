---
artifact_type: template
template_family: Runbook
domain: software
canonical_path: operations/templates/runbook-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: Google SRE §Runbook Design
canon_compat: plugin-aligned
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered runbook instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5(a)): `plugin-aligned` records the ANTICIPATED alignment path at DRAFT — authoritative only at an APPROVED transition. Registry basis: plugin `operations:runbook` (SOPs + recurring task documentation) is the registered cross-ref for the Runbook family per template-taxonomy.md §6 row 2 + §7 localization audit trail (inventory dated 2026-05-10); this template carries actionable per-condition steps, verification, and escalation per that registered convention. Live-plugin check 2026-07-03/04: the engineering:*/operations:*/product-management:* plugin suites are NOT installed in this workspace and NOT present in the marketplace roster — alignment is registry-anticipated, not live-verified. P5 re-evaluates against the live plugin at any future APPROVED transition. -->

# {{SERVICE_OR_SYSTEM}} Runbook — {{CONDITION_OR_PROCEDURE}}

**Canon:** Google SRE Workbook §Runbook Design (secondary: ITIL Service Operation §Operations Management) — registered as the Runbook-family canon in [`template-taxonomy.md` §6 row 2](../../core/standards/template-taxonomy.md).
**Owner (service / on-call owner):** {{RUNBOOK_OWNER}}
**Severity when triggered:** {{SEVERITY — e.g., SEV-1…SEV-4}}
**Last reviewed:** {{LAST_REVIEWED_DATE}} · **Last tested:** {{LAST_TESTED_DATE}}

---

## Overview

{{WHAT — one paragraph: the condition or procedure this runbook covers, the service/system it applies to, and the user/business impact while the condition persists.}}

## Trigger Conditions

| Trigger | Source | Threshold / Signal | Severity |
|---|---|---|---|
| {{ALERT_OR_SYMPTOM}} | {{MONITOR_DASHBOARD_OR_REPORT}} | {{THRESHOLD}} | {{SEVERITY}} |
| {{ASSUMPTION – CONFIRM}} | | | |

## Prerequisites

- **Access:** {{REQUIRED_ACCESS — accounts, roles, permissions}}
- **Tools:** {{REQUIRED_TOOLS — CLIs, consoles, VPN}}
- **Safety notes:** {{SAFETY — every destructive step in this runbook and its guard}}

## Diagnosis

Confirm the condition before mitigating — do not act on the alert alone.

1. {{DIAGNOSIS_STEP_1 — imperative; exact command or console path}}
   - **Expected when condition present:** {{OBSERVABLE_1}}
2. {{DIAGNOSIS_STEP_2}}
   - **Expected when condition present:** {{OBSERVABLE_2}}

If diagnosis does NOT confirm the condition: {{FALSE_POSITIVE_ROUTE — where to route instead}}.

## Mitigation Procedure

One action per step, imperative voice, copy-pasteable where possible, each with its expected result.

1. {{STEP_1}}

   ```
   {{COMMAND_1}}
   ```

   - **Expected result:** {{RESULT_1}}
2. {{STEP_2}}
   - **Expected result:** {{RESULT_2}}

## Verification

1. {{VERIFY_STEP — confirm the condition is resolved, not merely quiet}}
2. {{VERIFY_SIGNAL — the monitoring signal that should return to normal, and how long to watch it}}

## Rollback

{{ROLLBACK — how to undo the mitigation if it worsens the situation; call out explicitly any step that is irreversible.}}

## Escalation

| Condition | Escalate to | Channel | When |
|---|---|---|---|
| {{ESCALATION_CONDITION — e.g., a mitigation step fails, or no progress within the timebox}} | {{ROLE_OR_TEAM}} | {{CHANNEL}} | {{TIMEBOX}} |

## References

- Dashboards: {{DASHBOARD_LINKS}}
- Related runbooks: {{RELATED_RUNBOOKS}}
- Related postmortems / known incidents: {{POSTMORTEM_REFS}}

---

### Authoring rules (template guidance — delete this section from rendered instances)

1. **One runbook per alert/condition** — the responder should land on exactly the steps for the page they received (Google SRE §Runbook Design).
2. **Steps are imperative, verified, and copy-pasteable**; every step states its expected result so divergence is detected immediately.
3. **Runbooks rot** — bump *Last reviewed* at every review; re-test and bump *Last tested* after any material change to the underlying system.
4. **A runbook is not a substitute for judgment** — if a step's output surprises you, stop and escalate.
