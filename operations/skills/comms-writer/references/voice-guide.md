# Voice Guide — PMO Communications

## Purpose

This guide defines the communication voice for all PMO-produced communications.
The comms-writer skill reads this file on first invocation and applies its rules
to every output. The voice is the TPM's established voice: direct, action-oriented,
evidence-grounded, and audience-calibrated.

---

## Core Voice Principles

### 1. Audience-First

Every communication starts with the question: "What does this reader need to
decide or do after reading this?" The answer shapes content, depth, tone, and
format. A communication that informs without enabling action is status theater.

### 2. Evidence-Grounded

Every factual claim is traceable. Dates come from PROJECT.md or carry-forward
trackers. Statuses come from source artifacts. Opinions are labeled as
recommendations. Unknowns stay unknown — they do not become hedged assertions.

### 3. Decision-Enabling

Communications exist to drive decisions and actions, not to demonstrate effort.
Lead with the recommendation or ask. Provide supporting evidence second.
Close with what the reader needs to do and by when.

---

## Tone Calibration Matrix

Tone varies by audience tier. The same underlying information is reframed — not
diluted or inflated — for each audience.

| Audience Tier | Tone | Depth | Framing | Opening Pattern | Closing Pattern |
|---------------|------|-------|---------|-----------------|-----------------|
| **Executive** (VP+, CIO, Sponsor) | Crisp, confident, recommendation-led | Headlines only; drill-down available on request | Business impact, investment decisions, strategic risk | "Recommendation: [action]." or "Decision needed: [choice] by [date]." | "Ask: [specific decision/action] by [date]." |
| **Steering Committee** | Structured, balanced, evidence-backed | Key metrics + risk summary + decisions needed | Health indicators, milestone progress, escalation items | "[Project]: [status summary in one sentence]." | "Decisions requested: [numbered list]." |
| **Project Team** (PM peers, tech leads) | Direct, operational, collaborative | Full operational detail; dependencies, blockers, timelines | Workstream-level progress, technical constraints, action items | "[Topic]: here's where we are and what's next." | "Action items: [owner + deadline per item]." |
| **End Users** (org-wide) | Plain language, empathetic, clear instructions | What changes, when, and what to do — nothing else | Personal impact, dates, specific actions, support channels | "Starting [date], [what changes in plain terms]." | "Questions? Contact [channel]." |
| **Vendor / Consultant** | Professional, precise, contractual awareness | Scope-relevant detail; no internal politics or budget sensitivity | Deliverables, timelines, dependencies, acceptance criteria | "[Subject]: [purpose of communication]." | "Please confirm [specific deliverable/date] by [deadline]." |

---

## Formality Spectrum

Communications exist on a formality spectrum. Match the format to the channel and
context — not to personal preference.

| Level | Channel | Characteristics | When to Use |
|-------|---------|----------------|-------------|
| **Formal Report** | Confluence, PDF, Email attachment | Structured sections, version-controlled, baselined, approval routing | Gate reviews, SteerCo packages, compliance documentation, baselined communications |
| **Executive Brief** | Email body, slide deck | 1 page max, headline-driven, RAG indicators, decision framing | Status updates to VP+, investment requests, escalation summaries |
| **Structured Update** | Email body | Subject line with prefix, numbered sections, action items with owners/dates, signature block | Weekly status, meeting recaps, cross-functional coordination |
| **Team Update** | Email or Teams channel | Briefer structure, operational language, assumes shared context | Sprint updates, workstream coordination, dependency alerts |
| **Teams Message** | Teams DM or channel | Conversational, no formal structure, reads like a human typed it | Quick coordination, clarifying questions, informal check-ins, time-sensitive asks |

**Transition rules:**
- When a Teams thread grows beyond 3 exchanges on a decision topic, move to email (creates a record).
- When an email chain exceeds 5 replies, schedule a meeting (synchronous resolution needed).
- When a meeting produces decisions or action items, produce a recap email (asynchronous record).

---

## Active Voice Requirements

PMO communications use active voice. Passive voice obscures accountability.

| Pattern | Passive (Reject) | Active (Use) |
|---------|------------------|--------------|
| Status reporting | "The milestone was completed." | "The team completed the milestone on 4/1." |
| Risk surfacing | "It has been identified that..." | "We identified a risk: [description]." |
| Action assignment | "Testing should be performed by..." | "@[COLLEAGUE_E]: complete UAT by 4/10." |
| Decision reporting | "It was decided that..." | "[COLLEAGUE_A] approved the revised timeline on 3/28." |
| Escalation | "It is recommended that..." | "I recommend we [action] because [reason]." |
| Blocker description | "Progress has been impacted by..." | "[Vendor] missed the 3/25 deliverable, blocking integration testing." |

**One exception:** Use passive voice only when the actor is genuinely unknown or
when deliberately de-personalizing a sensitive issue for political reasons. In that
case, label the choice: "[deliberate passive — political sensitivity]" in working
notes, not in the sent communication.

---

## Plain Language Guidelines

All communications default to plain language. Technical precision is added only
when the audience requires it and will use it.

| Jargon | Plain Equivalent | When Jargon Is Acceptable |
|--------|-----------------|---------------------------|
| SPI / CPI | Schedule health / Budget health | Project team status reports; SteerCo with EVM-literate audience |
| Sprint velocity | Team delivery rate | Agile project team communications only |
| Blocker | Issue preventing progress | Always acceptable in project team context |
| UAT | User testing / Final testing | After first use with definition; always spelled out for end users |
| Go-live | Launch / System available | Acceptable after first-use definition in end-user comms |
| Burndown | Work remaining trend | Project team only |
| WIP limit | Work-in-progress cap | Project team only |
| RAID | Risks, actions, issues, decisions | Always spell out on first use outside project team |
| PI Planning | Program planning session | SAFe-context teams only |
| CCB | Change review board | Governance-context only; spell out for all audiences |

**Rule:** If a term would require explanation to a new team member with 2 years of
general business experience, it is jargon. Translate it or define it on first use.

---

## Methodology-Aware Language Rules

When communicating about projects that use a specific delivery approach, match the
vocabulary to the audience's methodology context. Do not use Agile jargon with
Waterfall stakeholders or vice versa.

| Concept | Agile / Scrum Term | Waterfall / Traditional Term | SAFe Term | Neutral Term (Use When Uncertain) |
|---------|-------------------|------------------------------|-----------|----------------------------------|
| Work period | Sprint | Phase | Program Increment (PI) | Delivery cycle |
| Work items | Stories / Tasks | Deliverables / Work packages | Features / Stories | Work items |
| Progress check | Sprint Review | Phase gate review | System Demo | Progress review |
| Requirements | Product Backlog | BRD / SRS / FRD | Program Backlog | Requirements |
| Approval | Definition of Done | Gate approval / Sign-off | PI Objective acceptance | Acceptance criteria met |
| Scope change | Backlog refinement | Change request (CR) | PI re-planning | Scope adjustment |
| Health metric | Velocity / Burndown | SPI / CPI / EVM | PI Predictability | Delivery health |
| Risk discussion | Sprint Retrospective | Risk review meeting | Inspect & Adapt | Lessons learned |
| Status artifact | Sprint board / Burndown | Status report / Gantt | Program board / ART dashboard | Status update |
| Plan artifact | Sprint Backlog | Project plan / WBS | PI Plan | Delivery plan |

**Dual-Framing bridge rule:** When `dual_framing_enabled: true`, the same data must be expressed in
both vocabularies. Use the neutral column as the bridge term when a single
communication serves both audiences, then provide approach-specific detail in
labeled sections.

**Anti-pattern — methodology language barrier:** If a stakeholder says "I don't
understand your status report," the first diagnosis is vocabulary mismatch, not
insufficient data. Reframe using their methodology's terms before adding more content.

---

## Structural Conventions

### Subject Lines

| Type | Pattern | Example |
|------|---------|---------|
| Status update | [PROJECT] Status — [date] | [PROJECT_KEY] Status — 2026-04-02 |
| Recap | [RECAP] [Meeting Name] — [date] | [RECAP] [PROJECT_KEY] SteerCo — 2026-04-02 |
| Action required | [ACTION REQUIRED] [Topic] — Due [date] | [ACTION REQUIRED] UAT Sign-off — Due 2026-04-10 |
| Decision needed | [DECISION NEEDED] [Topic] | [DECISION NEEDED] Go-Live Date Revision |
| FYI | [FYI] [Topic] | [FYI] [PROJECT_KEY] Training Schedule Published |
| Escalation | [ESCALATION] [Topic] | [ESCALATION] Vendor Deliverable Delay — Integration at Risk |

### Paragraph Structure

- **Maximum 3 sentences per paragraph** in email body.
- **One idea per paragraph.** If a paragraph covers two topics, split it.
- **Tables over prose** for any structured data (dates, owners, statuses, comparisons).
- **Bold for action items** — owner name and deadline always bolded.
- **Numbered lists for sequential actions.** Bullet lists for non-sequential items.

### Signature Block

Standard: `[OPERATOR_NAME], Senior Program Manager. [OPERATOR_PHONE]`

Used on all external emails and formal internal emails. Omitted on Teams messages
and informal internal threads.

---

## Anti-Patterns

| Anti-Pattern | What It Looks Like | Why It Fails | Correction |
|-------------|-------------------|-------------|------------|
| **Jargon leakage** | Sprint velocity metrics in a COO status update | Audience cannot parse; creates distance instead of understanding | Use methodology-aware language table; match vocabulary to audience context |
| **Passive voice in status** | "The deliverable was delayed" | Obscures who is responsible; weakens accountability signal | "Vendor X missed the 3/25 deadline" — name the actor |
| **Urgency inflation** | "URGENT" on routine updates; "CRITICAL" on medium-risk items | Desensitizes readers; real urgency gets ignored | Reserve URGENT/CRITICAL for items that genuinely block delivery within 48 hours |
| **Status theater** | Three paragraphs describing completed work with no decisions or asks | Reader learns nothing actionable; wastes attention budget | Every communication must have a purpose: decision, action, or material awareness shift |
| **"I hope you're doing well"** | Opening pleasantry before the point | Wastes the most valuable real estate (first sentence); signals the content is not urgent | Open with the point. First sentence = what this is about and why the reader cares. |
| **Hedge stacking** | "We might potentially be able to possibly..." | Destroys confidence; reader cannot determine what is actually true | One hedge per claim maximum. "We expect June 15 (85% confidence)" not "We might be able to target sometime around mid-June" |
| **Template residue** | "[INSERT STAKEHOLDER NAME]" in sent communication | Signals carelessness; undermines credibility | Every gap must be a named information need or the draft is NOT READY |
| **Wall of text** | 500-word paragraph with no structure | Reader skips it; buried action items are missed | Max 3 sentences per paragraph; tables for structured data; bold for action items |
| **Metric dumping** | 15 KPIs with no interpretation | Reader cannot determine what matters | Max 5 metrics per communication; each includes "so what?" interpretation |

---

## Decision Logic: Choosing Voice Parameters

When producing a communication, resolve these four questions in order:

1. **Who is the audience?** → Sets tone tier from Tone Calibration Matrix
2. **What channel?** → Sets formality level from Formality Spectrum
3. **What methodology context?** → Sets vocabulary from Methodology-Aware Language Rules
4. **What is the purpose?** → Sets structure from Communication Types (in SKILL.md)

When parameters conflict (e.g., formal audience but Teams channel), the channel
wins for formality and the audience wins for depth and vocabulary. A Teams message
to an executive is conversational in structure but still decision-enabling in content.
