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
- For SPM co-managed projects: include a one-line SPM summary at the top of each update
