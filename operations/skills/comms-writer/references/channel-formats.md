<!-- reference-durability: allow-link -->
# Channel Formats — PMO Communications

## Purpose

This file defines the communication channel inventory, format specifications per
channel, channel selection decision model, ceremony-to-channel mapping, and status
aggregation cadences. The comms-writer skill reads this file when formatting
communications for a specific channel.

---

## 1. Communication Channel Inventory

| Channel | Formality | Record Type | Audience Scale | Latency | Best For |
|---------|-----------|------------|----------------|---------|----------|
| **Email** | Medium-High | Persistent, searchable, forwardable | 1-to-few or 1-to-many | Async (hours) | Decisions, action items, formal status, recaps, escalations |
| **Teams Message** | Low-Medium | Semi-persistent, conversational | 1-to-1 or small channel | Near-sync (minutes) | Quick coordination, clarifications, informal check-ins, time-sensitive asks |
| **Teams Channel Post** | Medium | Persistent within channel, discoverable | Team or workstream | Async (hours) | Workstream updates, shared reference, team-scoped announcements |
| **Confluence** | High | Version-controlled, structured, linkable | Many (reference audience) | Async (days) | Documentation, process guides, artifact publication, knowledge base |
| **Presentation (Slides)** | High | Snapshot, visual, non-interactive | Meeting audience | Sync (live) | SteerCo packages, executive briefings, gate review evidence, training |
| **Verbal (Meeting)** | Variable | No record unless minuted | Meeting attendees | Sync (real-time) | Discussion, negotiation, complex decisions, relationship building |

### Channel Constraint Rules

- **Decisions must have a written record.** If a decision is made verbally (meeting,
  hallway conversation), it must be documented in email or Confluence within 24 hours.
  Undocumented decisions are not decisions — they are conversations.
- **Action items must be in a persistent channel.** Teams messages for action items are
  acceptable only if the action is immediate (<4 hours). Otherwise, email or tracker.
- **Sensitive information follows data classification.** See Section 6 (Compliance Rules
  reference) for what can appear in each channel.
- **No channel switching mid-thread without bridging.** If a discussion moves from Teams
  to email, the email must summarize the Teams context. The recipient should not need
  to find the Teams thread.

---

## 2. Channel Selection Decision Model

Resolve channel selection by evaluating four factors. When factors conflict, the
highest-priority factor (top of list) wins.

| Priority | Factor | Leans Toward Formal (Email/Confluence/Presentation) | Leans Toward Informal (Teams/Verbal) |
|----------|--------|-----------------------------------------------------|--------------------------------------|
| 1 | **Record requirement** | Audit trail required; decision must be documented; compliance mandate | No documentation requirement; ephemeral coordination |
| 2 | **Audience formality** | Executive, Steering, external/vendor stakeholders | Project team, direct peers, established working relationships |
| 3 | **Urgency** | Standard cadence; planned communication | Time-sensitive (<4 hours); blocking issue; needs immediate response |
| 4 | **Content complexity** | Structured data, multiple topics, attachments, tables | Single question, brief status, binary ask |

### Decision Tree

```
Is a formal record required (audit, compliance, decision documentation)?
├── YES → Email or Confluence
│   ├── Is it a living reference document? → Confluence
│   └── Is it a point-in-time communication? → Email
└── NO
    ├── Is the audience executive or external? → Email (even if informal content)
    └── Is the audience project team or internal peer?
        ├── Is it urgent (<4 hours) or a single quick question? → Teams Message
        ├── Is it a team-scoped update? → Teams Channel Post
        └── Is it a multi-topic update with action items? → Email
```

### Escalation Channel Rules

| Escalation Target | Channel | Format |
|-------------------|---------|--------|
| Peer PM / Tech Lead | Teams first, then email if >1 exchange | Conversational with specific ask |
| Program Manager / RTE | Email with CC to PM | SIOR structure per [sior-escalation-protocol.md](../../../../core/standards/sior-escalation-protocol.md) |
| Steering Committee / Sponsor | Email with formal structure | Escalation (SIOR) format — see [sior-escalation-protocol.md](../../../../core/standards/sior-escalation-protocol.md) and the comms-writer Escalation type |
| Vendor | Email (contractual record) | Professional, precise, deliverable-referenced |

---

## 3. Format Specifications per Channel

### Email Format

| Element | Specification |
|---------|--------------|
| **Subject line** | Prefix + descriptive topic + date when applicable. Prefixes: `[RECAP]`, `[ACTION REQUIRED]`, `[FYI]`, `[DECISION NEEDED]`, `[ESCALATION]` |
| **Recipients** | To: decision-makers and action owners. CC: stakeholders who need visibility. BCC: rare, only for broad distribution where reply-all is undesirable. Every recipient has a rationale. |
| **Opening sentence** | The point. What this is about and why the reader cares. No pleasantries. |
| **Body structure** | Max 3 sentences per paragraph. One idea per paragraph. Tables for structured data. Bold for action items (owner + deadline). |
| **Action items** | Format: `MM/DD/YY — @Owner: Action description.` Bolded. Grouped in a dedicated section when >2 items. |
| **Length limits** | Executive: <250 words body. Structured update: <500 words. Detailed recap: <750 words. If longer, attach a document and summarize in body. |
| **Signature** | `[OPERATOR_NAME], Senior Program Manager. [OPERATOR_PHONE]` on external and formal internal emails. |
| **Attachments** | Referenced in body before appearing as attachment. Never send attachments without context. |

### Teams Message Format

| Element | Specification |
|---------|--------------|
| **Structure** | No formal structure. Reads like a human typed it. Conversational. |
| **Length** | 1-3 sentences for simple asks. Up to 1 short paragraph for context + ask. |
| **Formatting** | Minimal. Bold for the specific ask if buried in context. No tables (use email). |
| **Action items** | Inline: "Can you [action] by [date]?" No formal action item formatting. |
| **Thread discipline** | Reply in thread, not new message, for ongoing topics. Start new thread for new topics. |
| **Escalation** | If thread exceeds 3 exchanges on a decision topic, move to email. State: "Moving this to email for a clearer record." |

### Confluence Format

| Element | Specification |
|---------|--------------|
| **Page structure** | Title, purpose statement, table of contents (auto-generated for >3 sections), structured sections with headers. |
| **Section mapping** | Every update specifies: "This updates [Page Name] → [Section]." |
| **Change summary** | What changed, why, source, stakeholder document impact. Goes in the page's own dedicated "Change Log" section at the bottom — durable state belongs in the record's structure. **Not a free choice between a comment and the section:** per [`core/disciplines/external-seam-conduct.md`](../../../../core/disciplines/external-seam-conduct.md) § 1, a page comment is warranted only when it **addresses a person** *and* **carries an ask or an answer**. A change summary written to no reader in particular is a register entry, and it belongs on the page. Where a change genuinely needs a person's attention, the comment carries the ask and the Change Log still carries the state. |
| **Tables** | Use Confluence table macros. Markdown tables acceptable in copy/paste blocks from comms-writer. |
| **Version control** | Confluence provides native versioning. Add a manual version note for significant changes: "v2.1 — Updated go-live dates per SteerCo decision 3/28." |
| **Labels** | Apply Confluence labels for discoverability: project name, document type, status (draft/approved/active/archived). |

### Presentation (Slide) Format

| Element | Specification |
|---------|--------------|
| **Structure** | Title slide → Executive summary (1 slide) → Content slides → Decision/Ask slide. Max 10 slides for SteerCo; max 5 for executive brief. |
| **Content density** | Max 6 bullet points per slide. Max 25 words per bullet. One key message per slide. |
| **Data visualization** | RAG indicators, trend lines, milestone timelines. No raw data tables — summarize and reference source. |
| **Speaker notes** | Include talking points and supporting detail that does not belong on the slide face. |

### Meeting Agenda Format

The meeting-agenda output format — the six required agenda elements (Subject /
Attendees with rationale / one-sentence Goal / Agenda items with `@Name` owners + time
allocations + sub-items / Pre-read / Logistics) and the formality-calibration rule — is
defined by the canonical output-format spec
[`meeting-agenda-format.md`](../../../../core/standards/meeting-agenda-format.md). That
spec is the single source; this section carries no inline element definition.

### Meeting Recap Format

The meeting-recap output format — the `[RECAP] [Meeting Name] — [date]` subject
convention, the recipients rule, the fixed body order Decisions (attributed) → Action
Items (owner + deadline + deliverable) → Notes → Key Roadblocks (if any), and the
timeliness (within 4 business hours / same-day standard) + distribution rules — is
defined by the canonical output-format spec
[`meeting-recap-format.md`](../../../../core/standards/meeting-recap-format.md). That
spec is the single source; this section carries no inline format table.

---

## 4. Ceremony-to-Channel Mapping

Ceremonies produce defined communication outputs through specific channels.

### Portfolio Ceremonies (Strategic Cadence)

| Ceremony | Cadence | Duration | Primary Channel | Communication Output |
|----------|---------|----------|----------------|---------------------|
| Strategic Planning Session | Annual | 1-2 days | Presentation + Confluence | Strategic direction document; portfolio roadmap update |
| Portfolio Review Board | Monthly | 1.5-2 hrs | Presentation + Email recap | Go/kill/hold decisions; portfolio health dashboard |
| Investment Committee | Monthly | 1-1.5 hrs | Presentation + Email | Investment decisions; funding approvals/rejections |
| Quarterly Business Review | Quarterly | 60-90 min per BU | Presentation + Email recap | Business unit performance; strategic alignment assessment |

### Program Ceremonies (PI Cadence)

| Ceremony | Cadence | Duration | Primary Channel | Communication Output |
|----------|---------|----------|----------------|---------------------|
| PI Planning | Every 8-12 weeks | 2 full days | Verbal + Confluence + Program Board | PI Objectives; program board; dependency commitments |
| Scrum of Scrums / ART Sync | Weekly | 30-60 min | Teams Channel + Email (escalations only) | Cross-team dependency status; impediment escalations |
| Inspect & Adapt | End of PI | 3-4 hrs | Confluence + Email recap | PI performance metrics; improvement backlog items |
| Steering Committee | Monthly | 1-1.5 hrs | Presentation + Email recap | Health status; decisions; escalation resolutions; risk acceptance |

### Project Ceremonies (Sprint Cadence)

| Ceremony | Cadence | Duration | Primary Channel | Communication Output |
|----------|---------|----------|----------------|---------------------|
| Sprint Planning | Per sprint | ~2 hrs/wk of sprint | Teams Channel or Confluence | Sprint goal; sprint backlog; capacity commitment |
| Daily Standup | Daily | 15 min strict | Verbal (no written output) | Impediment identification only — not a status report |
| Sprint Review / Demo | Per sprint | ~1 hr/wk of sprint | Verbal + Email recap to stakeholders | Working increment demonstration; stakeholder feedback |
| Sprint Retrospective | Per sprint | ~45 min/wk of sprint | Confluence (action items only) | Improvement actions; process adjustments |

### Cross-Cutting Ceremonies

| Ceremony | Cadence | Duration | Primary Channel | Communication Output |
|----------|---------|----------|----------------|---------------------|
| Architecture Review Board | Monthly + ad hoc | 1-2 hrs | Confluence + Email | Architecture decisions (ADRs); technical standards |
| Release Readiness / Go-No-Go | Per release | 1-2 hrs | Presentation + Email | Go/No-Go decision; readiness assessment across 9 dimensions |
| Post-Implementation Review | 1-4 wks post-deploy | 1-2 hrs | Confluence + Email recap | Objectives vs. actuals; lessons learned; improvement actions |
| Community of Practice | Monthly | 1 hr | Confluence + Teams Channel | Knowledge sharing; practice standards; cross-team learning |

---

## 5. Information Radiator Design Principles

Information radiators are persistent, visible displays of current project state.
They replace status requests with self-service information access.

### Design Rules

1. **Audience-matched.** The radiator serves a specific audience. A team burndown
   is not an executive dashboard. Design for the consumer, not the producer.
2. **Real-time or clearly dated.** Radiators must show either live data or a
   prominent "Last updated: [timestamp]" indicator. Stale radiators are worse
   than no radiators — they create false confidence.
3. **Glanceable.** A new viewer should understand the overall state in 15 seconds.
   Detailed drill-down is available but not required for the headline assessment.
4. **Decision-enabling.** Every metric displayed must answer the question: "What
   decision would change based on this number?" If no decision changes, remove it.
5. **Distributed-team adaptation.** Physical boards work for co-located teams.
   Distributed teams need digital equivalents with equivalent visibility (not
   buried in a tool that requires 5 clicks to reach).

### Radiator Types by Level

| Level | Radiator | Key Content | Refresh |
|-------|----------|-------------|---------|
| Team | Sprint/Kanban board | Work items, WIP, blockers, burndown/CFD | Real-time (tool-driven) |
| Project | Status dashboard | RAG indicators, milestone timeline, risk summary, action items | Weekly |
| Program | Program board / ART dashboard | Cross-project dependencies, aggregate health, PI progress | Biweekly |
| Portfolio | Portfolio heat map | Strategic alignment, health distribution, investment allocation | Monthly |
| Executive | Executive dashboard | Investment-to-value ratio, top risks, theme distribution | Monthly/Quarterly |

---

## 6. Five-Level Status Aggregation

Status information aggregates through five levels. Each level adds decision
context — it does not merely summarize the level below.

| Level | Key Metrics | Artifact | Cadence | Owner | Decision It Enables |
|-------|------------|----------|---------|-------|-------------------|
| **Team** | Velocity, burndown, WIP, cycle time | Sprint board | Daily | Scrum Master / Tech Lead | "Are we on track for the sprint goal?" |
| **Project** | SV, CV, SPI, CPI, risk count, milestone % | Status report + RAG | Weekly | Project Manager | "Are we on track for the milestone? Do we need to escalate?" |
| **Program** | Cross-project dependencies, aggregate budget, utilization | Program dashboard | Biweekly | Program Manager | "Are dependencies resolved? Is resource allocation balanced?" |
| **Portfolio** | Strategic alignment, health distribution, aggregate ROI | Portfolio heat map | Monthly | Portfolio Manager | "Are we investing in the right things? Should we kill/hold anything?" |
| **Executive** | Investment-to-value ratio, top risks, theme distribution | Executive dashboard | Monthly/Quarterly | CIO / Sponsor | "Is the portfolio delivering strategic value? What needs my intervention?" |

### RAG Threshold Standards

RAG indicators must be formula-driven, not self-reported. Self-reported RAG
enables watermelon reporting (green outside, red inside).

| Indicator | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Schedule (SPI)** | >= 0.95 | 0.85 - 0.94 | < 0.85 |
| **Budget (CPI)** | >= 0.95 | 0.85 - 0.94 | < 0.85 |
| **Risk** | No high/critical open risks | 1-2 high risks with active mitigation | Any critical risk without mitigation OR 3+ high risks |
| **Scope** | No approved CRs impacting baseline | Minor CRs approved; baseline adjustable | Major scope change; baseline integrity compromised |

**Watermelon detection rule:** When a project reports Green at the project level
but component-level RAGs show Amber or Red, flag immediately. Require
component-level RAGs that roll up transparently to the project-level RAG.

> This is the comms-side one-line heuristic. The **canonical definition of the
> watermelon (green-outside/red-inside) concept and the full detection signal set
> (W1–W8)** live in [`watermelon-detection.md`](../../../../core/skills/pmo-qa-auditor/references/watermelon-detection.md)
> (owned by `pmo-qa-auditor`) — one owner per concept, per duplicate-source-discipline
> (ADR-065). This rule is a consumer of that concept, not a second definition of it.

### Methodology Variation: Status Cadence

| Approach | Primary Executive Mechanism | Status Cadence | Key Format Difference |
|----------|---------------------------|---------------|----------------------|
| **Waterfall** | Steering Committee + EVM dashboards | Monthly formal status | SPI/CPI as primary health indicators |
| **Scrum** | Sprint Review (working software) | Per-sprint | Working increment is the status artifact; Sprint Review is NOT a gate |
| **Kanban** | Operations Review + Monte Carlo forecasting | Monthly | Probabilistic forecasts replace deterministic milestones |
| **SAFe** | Strategic Portfolio Review + flow dashboards | Quarterly (portfolio) / per-PI (program) | PI Predictability as primary health indicator |
| **PRINCE2** | Highlight Reports (regular) + Exception Reports (tolerance breach) | Biweekly/monthly | Exception-based: reports trigger only when tolerance is breached |
| **Lean** | A3 reports + bowling charts | Per issue / monthly | A3 as concise problem-solving format ("2-3 minutes to assess quality") |
| **Hybrid** | Sprint demos (delivery) + gate reports (governance) | Dual-track: per-sprint + per-phase | PM translates between sprint metrics and gate language |

### Four-Dimension Universal Health Reporting

For organizations with mixed delivery approaches, these four dimensions normalize
cross-approach comparison to a common scale:

| Dimension | Waterfall Metric | Scrum Metric | Kanban Metric | SAFe Metric |
|-----------|-----------------|--------------|---------------|-------------|
| **Schedule Health** | SPI | Sprint goal % achieved | Cycle time vs. SLE | PI Predictability |
| **Budget Health** | CPI | Cost per story point | Cost per item | Lean budget adherence |
| **Quality Health** | Defect density at gate | Escaped defects per sprint | Defect cycle time | Built-in quality metrics |
| **Value Health** | % milestones achieved | Business Value points | Throughput of high-priority items | PI Objectives % achieved |

All four dimensions aggregate to a common 1-5 scale or RAG for portfolio-level
comparison.

---

## Applicability

Per [`applicability-framework.md`](../../../../core/disciplines/applicability-framework.md). Exec-briefing and external-channel formats are a **contextual** (stakeholder-axis) practice; internal Teams/email formats are universal.

### Applicability (per applicability-framework.md)
- **Universality:** contextual            # §938 axis position — stakeholder-axis
- **Applies when:** `stakeholder_complexity ∈ {single-external, multi-stakeholder}` for exec-briefing / external-channel formats; `ALL` for internal Teams/email formats
- **Contraindicated when:** **CI-2** (external-stakeholder briefing / exec-comms / escalation protocols — `stakeholder_complexity = internal-only`); also **CI-3** if a format mandates formal-audit packaging where `regulatory_posture ∈ {none, internal-governance}` and evidence is absent
- **On conflict:** §4 rung 2 (lex specialis) — the channel format whose APPLIES-WHEN predicate most specifically matches the audience wins; §4 rung 5 (escalate to operator via decision-discipline.md M1 G4) on genuine internal-vs-external audience ambiguity
- **Evidence tier:** ref `corpus-curation.md`; tiebreak input only — not defined here
