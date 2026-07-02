<!-- reference-durability: allow-link -->
# Evidence Quality Standards

## Purpose

Every factual claim in agent output must be traceable to an evidence source. This standard defines the labels, hierarchy, tagging rules, freshness policy, and quality scoring that ensure outputs are trustworthy and auditable.

## Evidence Quality Labels

Five labels classify every factual claim by its epistemic status:

| Label | Definition | Usage Example | Trust Level |
|-------|-----------|--------------|-------------|
| **[SOURCE]** | Verified from an authoritative source (artifact, document, system of record, user statement) | "Go-live date is April 10, 2026 [SOURCE: PROJECT.md §Timeline]" | Highest |
| **[INFERRED]** | Derived from evidence through logical reasoning, but not directly stated in any source | "Based on the 2-week sprint cadence and 8 remaining sprints, the earliest completion is June 15 [INFERRED: sprint cadence from PROJECT.md + backlog count from tracker]" | High |
| **[ASSUMPTION -- CONFIRM]** | Unverified claim with a proposed answer requiring human confirmation | "Vendor response SLA is 48 hours [ASSUMPTION -- CONFIRM: based on typical enterprise SLA; verify against vendor contract]" | Medium — requires confirmation |
| **[CONTEXT]** | Background information that provides framing but is not a decision-driving claim | "ERP implementations typically take 12-18 months [CONTEXT: industry benchmark]" | Informational |
| **[RECOMMENDED]** | Agent recommendation based on analysis, clearly distinguished from fact | "Recommend scheduling UAT for Sprint 8 to allow 2-week buffer before go-live [RECOMMENDED: based on timeline analysis]" | Agent judgment — not fact |

## Evidence Hierarchy

When multiple evidence sources exist, prefer higher-trust sources:

| Rank | Source Type | Description | Example |
|------|-----------|-------------|---------|
| 1 | **Direct observation** | Data read directly from the system of record or artifact | File content, tracker state, system output |
| 2 | **Artifact reference** | Verified reference to a specific artifact, section, and version | "PROJECT.md §Timeline, updated 2026-03-28" |
| 3 | **Cross-reference inference** | Conclusion drawn by combining data from multiple verified sources | "Sprint cadence (PROJECT.md) × remaining items (tracker) = timeline" |
| 4 | **Domain knowledge** | Established professional knowledge applicable to the context | Industry benchmarks, methodology standards, published research |
| 5 | **Assumption** | Unverified belief requiring confirmation | Any claim not supported by ranks 1-4 |

**Conflict resolution:** When two sources disagree, surface the conflict to the human rather than silently choosing one. Format: "Source A states X; Source B states Y. Recommend verifying with [authoritative source]."

## Tagging Rules

### What Must Be Tagged

| Content Type | Tagging Requirement | Example |
|-------------|--------------------|---------|
| Dates (deadlines, milestones, go-live) | MUST cite source artifact | "Go-live: April 10, 2026 [SOURCE: PROJECT.md]" |
| Owners (who is responsible) | MUST cite source artifact or user confirmation | "PM: <owner-name> [SOURCE: RACI matrix v2.1]" |
| Statuses (RAG, completion %) | MUST cite source artifact or calculation method | "SPI: 0.94 [SOURCE: EVM tracker, March 28 snapshot]" |
| Decisions (what was decided) | MUST cite meeting transcript, email, or governance record | "Approved by Steering Committee [SOURCE: SC minutes, March 25]" |
| Metrics and numbers | MUST cite source and collection date | "Velocity: 38 pts/sprint [SOURCE: Jira, 3-sprint rolling avg as of March 28]" |
| Recommendations | MUST use [RECOMMENDED] label | "[RECOMMENDED: Reduce sprint scope by 20% to recover schedule]" |
| Industry benchmarks | Use [CONTEXT] label with source | "Typical ERP implementation: 12-18 months [CONTEXT: Gartner benchmark 2024]" |
| Unverified claims | MUST use [ASSUMPTION -- CONFIRM] with proposed answer | "Budget authority threshold: $50K [ASSUMPTION -- CONFIRM: verify governance charter]" |

### Where Tags Go

- **Inline tagging:** Tags appear at the end of the claim they qualify, within the same sentence or immediately after.
- **Table cells:** Tag appears in the cell or in a footnote column.
- **Section-level tagging:** When an entire section draws from a single source, tag the section header: "## Timeline [SOURCE: PROJECT.md §Timeline, updated 2026-03-28]"

### Assumptions Must Include Proposed Answers

Every `[ASSUMPTION -- CONFIRM]` tag MUST include:
1. The assumed value (never blank, never `[TBD]`)
2. The reasoning behind the assumption
3. What source would confirm or refute it

**Correct:** "Sprint velocity: 35 points [ASSUMPTION -- CONFIRM: based on team size × industry average of 7 pts/person; verify against actual sprint data in Jira]"

**Incorrect:** "Sprint velocity: [TBD] [ASSUMPTION -- CONFIRM]"

## Evidence Freshness

| Age Category | Threshold | Treatment |
|-------------|-----------|-----------|
| **Current** | Updated within 2 business days | Use without flag |
| **Aging** | 2-5 business days since last update | Flag: "Data as of [date] — verify current state" |
| **Stale** | >5 business days since last update | Flag: "STALE DATA — last updated [date]. Verify before using for decisions." |
| **Expired** | >10 business days since last update | Do not use for decision-driving claims without re-verification |

**Date validation rule:** All date references in communications and status outputs must use specific verified dates, not generalized ranges. "April 10" not "week of April 6." When a date cannot be verified against an authoritative source (PROJECT.md, tracker, user confirmation), stop and ask — do not generalize.

**Day-of-week validation:** All date references must include day-of-week validation. If a date falls on a weekend or holiday, flag the discrepancy.

## Quality Scoring

### Evidence Density

Minimum evidence density per output section:

| Output Type | Minimum Tagged Claims Per Paragraph | Minimum Per Section |
|-------------|-------------------------------------|---------------------|
| Status report | 1 per paragraph | 3 per section |
| RAID update | 1 per entry | N/A (entry-level) |
| Decision recommendation | 2 per paragraph | 5 per section |
| Stakeholder communication | 1 per paragraph | 2 per section |
| Operational tracker update | 1 per entry | N/A (entry-level) |

### Assumption Ratio

The assumption ratio measures the proportion of claims tagged as `[ASSUMPTION -- CONFIRM]` vs. total tagged claims in a section:

| Ratio | Status | Action |
|-------|--------|--------|
| 0-10% | Healthy | Output is well-grounded in evidence |
| 10-20% | Acceptable | Normal for early-stage or information-sparse contexts |
| 20-40% | Caution | Flag section as "evidence-light — requires additional verification" |
| >40% | NOT READY | Do not present to stakeholders without additional evidence gathering |

### Watermelon Detection Integration

The **canonical definition of the watermelon (green-outside/red-inside) concept and the
full detection signal set (W1–W8)** live in [`watermelon-detection.md`](../../../../core/skills/pmo-qa-auditor/references/watermelon-detection.md)
(owned by `pmo-qa-auditor`) — one owner per concept, per duplicate-source-discipline (ADR-065).
The signals below are the **evidence-quality-specific** lens on that concept (which evidence-quality
failures surface a watermelon), not a fork of the signal set.

Evidence quality is the primary defense against watermelon reporting (green outside, red inside). Detection signals that indicate evidence quality failure:

| Signal | Evidence Quality Root Cause |
|--------|---------------------------|
| Status always "on track" despite recurring issues | Self-reported RAG without [SOURCE] tagging to objective metrics |
| Zero open risks | Risk log not updated — freshness violation |
| 100% task completion but features slipping | Evidence gap: task completion tracked but feature completion not cross-referenced |
| Milestone dates not aging | Dates reported without [SOURCE] cross-reference to actual progress data |

**Countermeasure:** System-calculated RAG from objective metrics, not self-reported. Every RAG status must have a [SOURCE] tag pointing to the metric that drives it.
