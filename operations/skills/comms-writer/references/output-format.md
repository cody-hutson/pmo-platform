# Standard Output Format

## Purpose

This document defines the standard output structure that all skills follow when producing output. Consistent structure enables the user to scan any skill output with the same mental model, find key information in predictable locations, and trust that evidence quality and follow-up routing are systematically applied.

## Standard Output Structure

Every skill output follows this section ordering. Sections may be omitted if genuinely not applicable, but the ordering of included sections is fixed.

| # | Section | Required | Content | Location Rule |
|---|---------|----------|---------|-------------|
| 1 | **Header** | Always | Mode, inputs, timestamp, processing context | First section — always |
| 2 | **Summary** | Always | 2-4 sentence executive summary: what was processed, key findings, critical actions | Immediately after header |
| 3 | **Domain-Specific Body** | Always | Skill-specific analysis, recommendations, artifacts | Main body |
| 4 | **RAID Updates** | When applicable | New or modified Risk, Assumption, Issue, Dependency entries | After body, before next actions |
| 5 | **Follow-Up Tags** | When applicable | Structured tags per follow-up-tags.md for cross-skill routing | After RAID updates |
| 6 | **Next Actions** | Always | 5-phase proactive next steps (Immediate, Short-term, Upcoming gates, Risk mitigations, Strategic opportunities) | Last substantive section |
| 7 | **Metadata** | Always | Processing stats, evidence quality summary, assumption count | Final section |

## Section Specifications

### 1. Header

```markdown
## [Skill Name] — [Mode Name]

| Field | Value |
|-------|-------|
| **Mode** | [Mode identifier] |
| **Inputs** | [What was processed: transcript, query, artifact, etc.] |
| **Timestamp** | [YYYY-MM-DD (Day) HH:MM] |
| **Project** | [Active project name] |
| **Processing Context** | [Brief description of what triggered this processing] |
```

### 2. Summary

- 2-4 sentences maximum
- Lead with the most important finding or action — not background
- Include quantified status where available (numbers, dates, percentages)
- End with the single most important next action
- Evidence tagged: at least 1 `[SOURCE]` or `[INFERRED]` reference

**Example:**
> Sprint 7 velocity dropped to 28 points (from 35 average) due to vendor integration blocker [SOURCE: Jira sprint report, March 28]. Three RAID items require attention: R-042 (vendor delay, now materialized as I-019), I-020 (test environment access), D-015 (API specification pending). Recommend immediate vendor escalation per SIOR format [RECOMMENDED].

### 3. Domain-Specific Body

Structure varies by skill. Key rules:
- **Organize by decision relevance**, not chronology — most actionable items first
- **Evidence tagging throughout** — every factual claim tagged per evidence-quality.md
- **Tables over prose** for structured data (comparisons, inventories, status lists)
- **Bold key findings** within paragraphs
- **No orphan recommendations** — every recommendation links to evidence and action

### 4. RAID Updates

When processing identifies new or changed RAID items:

```markdown
### RAID Updates

| Type | ID | Description | Severity | Owner | Status | Source |
|------|-----|------------|----------|-------|--------|--------|
| Risk | R-042 | Vendor integration delay may impact Sprint 8 | High | [Owner] | Monitoring → Materialized | [SOURCE: vendor email, March 28] |
| Issue | I-019 | Vendor delay confirmed: 5 business days | High | [Owner] | New | [SOURCE: vendor PM confirmation] |
```

Tier 1 rule: RAID Log updates are proposed here but require user approval before writing to the RAID Log artifact.

### 5. Follow-Up Tags

When processing identifies actions for other skills:

```markdown
### Follow-Up Tags

[DELIVERY: Sprint 8 scope reassessment needed due to vendor delay]
- Context: Vendor integration delayed 5 days; Sprint 8 commitment at risk
- Source: ppm-agent daily processing, March 28
- Scope: Assess impact on Sprint 8 backlog; recommend scope reduction or capacity reallocation
- Inputs: Sprint 8 backlog, vendor dependency map, velocity data
- Constraints: Sprint 8 starts April 1; decision needed by March 30

[COMMS: Stakeholder update on vendor delay impact]
- Context: Vendor delay materialized; project timeline may shift
- Source: ppm-agent daily processing, March 28
- Scope: Draft stakeholder communication per communications plan cadence
- Inputs: Vendor delay details, impact assessment, mitigation plan
- Constraints: Steering committee meeting April 2; update needed before then
```

### 6. Next Actions

Organized in 5 phases per proactive-follow-up-tracking.md:

```markdown
### Next Actions

**Phase 1 — Immediate (today):**
1. Send vendor escalation email per SIOR format [DELIVERY]
2. Update RAID Log with I-019 (pending approval)

**Phase 2 — Short-term (this week):**
3. Schedule Sprint 8 scope review meeting for March 30
4. Draft stakeholder update for steering committee [COMMS]

**Phase 3 — Upcoming gates (next 2 weeks):**
5. Sprint 8 planning: April 1 — backlog refinement needed by March 31
6. UAT kickoff: April 8 — test plan review needed by April 4

**Phase 4 — Risk mitigations (active monitoring):**
7. Vendor delay: if no resolution by April 3, activate contingency plan (parallel development path)

**Phase 5 — Strategic opportunities:**
8. Recommend mid-project retrospective before Phase 3 to capture vendor management lessons
```

Each action item is specific (what, who implied or stated, when with day-of-week validated), not vague ("follow up on things").

### 7. Metadata

```markdown
---
**Processing metadata:**
- Evidence density: [N tagged claims / M paragraphs = ratio]
- Assumption ratio: [N assumptions / M total claims = %]
- Follow-up tags emitted: [count by type]
- RAID updates proposed: [count by type]
- Files written: [list of files written during processing, if any]
- Files proposed: [list of files proposed but awaiting approval, if any]
```

## Formatting Standards

| Standard | Rule | Rationale |
|----------|------|-----------|
| **Markdown** | All output in GitHub-Flavored Markdown | Universal rendering; git-compatible |
| **Tables** | Use tables for structured data with 3+ items; aligned columns | Scannable; comparable |
| **Lists** | Numbered for sequences/actions; bulleted for unordered sets | Distinguishes ordered from unordered |
| **Bold** | Key findings, critical dates, important names within prose | Enables scan-reading |
| **Blockquotes** | Direct quotes from sources; before/after diff content | Visual separation of quoted material |
| **Headers** | H2 for major sections; H3 for subsections; H4 for sub-subsections | Consistent hierarchy |
| **No strikethrough** | Never use ~~strikethrough~~ in generated artifacts | Per CLAUDE.md quality standard |
| **No emojis** | Never use emojis unless explicitly requested | Per universal preferences |

## Evidence Tagging Integration

Evidence tags are placed inline within the text, per evidence-quality.md:

- **In prose:** Tag at end of the claim sentence: "Go-live is April 10 [SOURCE: PROJECT.md]."
- **In tables:** Tag in the cell or in a dedicated Source column
- **In section headers:** When entire section draws from one source: "## Timeline [SOURCE: PROJECT.md §Timeline]"

## Copy/Paste Readiness

When output includes artifacts intended for external systems (email drafts, Teams messages, status updates):

| Rule | Requirement |
|------|------------|
| **Self-contained** | Paste-ready sections must not reference other sections ("see above"); all context included |
| **Format-appropriate** | Email drafts in email format; Teams messages in Teams format; not markdown tables in email |
| **No evidence tags** | External-facing paste blocks strip evidence tags (they're internal quality markers) |
| **Clearly delimited** | Paste blocks wrapped in a "Copy/Paste Ready" header with clear start/end markers |

## File Output Rules

Per CLAUDE.md write-first-speak-second principle:

1. **Write to file first** — produce the artifact in the target location
2. **Confirm write success** — verify the file was written
3. **Then present to user** — only after confirmed write, report what was done
4. **Never report success for unexecuted writes** — if a write fails, report the failure

**Dual output:** Every processing cycle produces both:
- **Artifact:** The file(s) written or proposed
- **Metadata:** The processing output with summary, RAID, tags, next actions

## Length Guidelines

| Output Type | Target Length | Rationale |
|-------------|-------------|-----------|
| Daily status processing | 500-1,500 words | Balance detail with scanability |
| Transcript processing | 300-800 words per transcript | Extract key items; not full recap |
| Strategic analysis | 1,000-3,000 words | Depth proportional to complexity |
| Stakeholder communication draft | 200-500 words | Concise; audience-appropriate |
| Weekly rollup | 800-2,000 words | Aggregation across daily outputs |
