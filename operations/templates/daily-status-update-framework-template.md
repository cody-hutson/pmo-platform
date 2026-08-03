---
artifact_type: template
template_family: Daily Status Update Framework
domain: project
canonical_path: operations/templates/daily-status-update-framework-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-05
updated: 2026-08-03
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Measurement Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a rendered [Project]_Daily_Status_Update_Framework.md instance — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the Daily Status Update Framework family (template-taxonomy.md §3.7; §6 row 7 records "no direct plugin" — the Status report canon is consumed by the weekly-status-rollup PMO skill). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# {{PROJECT_NAME}} Daily Status Update Framework

**Purpose:** Prompt templates for generating Teams-ready status updates.
**Phase:** {{CURRENT_PHASE}}
**Last updated:** {{CREATION_DATE}}

---

## AM Update Template

### Input Context
- Read: `{{PROJECT_PREFIX}}_Daily_Status_Log.md` (carry-forward section)
- Read: Previous day's PM transcript or notes (if available)
- Read: Any overnight email updates in `06-Emails/`

### Output Format
```
{{PROJECT_NAME}} — AM Update ({{DATE}})

🔴 BLOCKERS
[List blockers with owner and gate impact]

⏳ DECISIONS PENDING
[List decisions with owner and deadline]

📋 TODAY'S FOCUS
[Top 3-5 priorities for the day]

📌 KEY ACTIONS DUE TODAY
[Person-by-person action items due today]

ℹ️ FYI
[Non-blocking items worth noting]
```

---

## PM Update Template

### Input Context
- Read: `{{PROJECT_PREFIX}}_Daily_Status_Log.md` (carry-forward section)
- Read: Today's AM/PM testing transcripts (if available)
- Read: Today's daily connect transcript (if available)

### Output Format
```
{{PROJECT_NAME}} — PM Update ({{DATE}})

✅ RESOLVED TODAY
[Items closed with evidence]

🔴 BLOCKERS (updated)
[Current blockers — what changed since AM]

⏳ DECISIONS PENDING (updated)
[Decisions — any progress today?]

📋 OVERNIGHT / TOMORROW
[What's expected overnight, what's queued for tomorrow AM]

📌 UPDATED ACTIONS
[New or changed actions from today's sessions]
```

---

## Daily Connect Prep Template

### Input Context
- Read: `{{PROJECT_PREFIX}}_Daily_Status_Log.md` (carry-forward section)
- Read: Today's AM update

### Output Format
```
{{PROJECT_NAME}} — Daily Connect Agenda ({{DATE}})

1. Blocker Status Check (5 min)
   [Each blocker: status, owner, what we need]

2. Decision Items (5 min)
   [Decisions that need discussion or escalation]

3. Testing Status (5 min)
   [Today's test results, retest queue status]

4. Open Items / Round Table (5 min)
   [Anything not covered above]
```

---

## Customization Notes

- Adapt emoji usage to team preference (some teams prefer plain text)
- Meeting cadence sub-sections should match the project's actual meeting schedule
- Phase-specific sections may be added as the project progresses (e.g., cutover countdown, hypercare metrics)
- For Waterfall projects: replace sprint references with phase-gate references
- For dual-framing co-managed projects (`dual_framing_enabled: true`): include a one-line Sponsor view summary at the top of each update
