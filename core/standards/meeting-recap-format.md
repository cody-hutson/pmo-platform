---
title: Meeting Recap Output-Format Spec
purpose: The output-format spec defining the structure and field semantics of every PMO-produced meeting recap — decisions, next actions with owners and dates, context, and roadblocks.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: comms-writer (recap mode); ppm-agent (transcript-to-recap); any skill producing a post-meeting recap artifact
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Meeting Recap Output-Format Spec

> **Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
> **Canonical home** for the meeting-recap output format — the `[RECAP]` subject convention, the
> recipients rule, the four-section body order, and the timeliness + distribution rules. Consumed by
> comms-writer (Meeting recap type — the reference implementation) and comms-writer's
> `references/channel-formats.md` (Meeting Recap Format table). This doc is the **single source**;
> consumers reference it by relative link rather than re-defining the format (per
> [duplicate-source-discipline.md](duplicate-source-discipline.md) §1 option 2 — consolidate to a
> canonical source). It is an output-format *specification* for a finished communication, not a fill-in
> template.

## Purpose

A meeting recap is a finished post-meeting communication that records what was decided, what will happen
next (and who owns it, by when), the supporting context, and any roadblocks — sent promptly to the people
who need it. This spec defines the structure and field semantics every PMO-produced recap carries so the
recap reads as a complete, send-ready communication. The recap the consumer produces IS this format.

## Format Spec

Every recap carries a subject line, a recipients rule, and a four-section body in a fixed order.

### Subject line

`[RECAP] [Meeting Name] — [date]`

The `[RECAP]` prefix is mandatory and leads the subject line; it makes the communication scannable and
filterable in an inbox. The meeting name and date follow.

### Recipients

Meeting attendees **plus** stakeholders identified during the meeting as needing visibility. Recipient
selection is part of the recap, not an afterthought.

### Body — four sections, in this order

| Order | Section | Content | Rule |
|---|---|---|---|
| 1 | **Decisions** | What was agreed, **attributed to the decision-maker**. | Each decision names who made it; an unattributed decision is a note, not a decision. |
| 2 | **Action Items** | Each with owner, deadline, and specific deliverable. Format: `MM/DD/YY — @Owner: Action description.` | Every action item has an owner and a deadline; an action with neither is an orphan. |
| 3 | **Notes** | Supporting context, technical constraints, open questions. | Carries the context a reader needs to understand the decisions and actions. |
| 4 | **Key Roadblocks** *(if applicable)* | What is blocking progress. | Conditional — present only when a roadblock exists; named explicitly when it does. |

The order is fixed: **Decisions → Action Items → Notes → Key Roadblocks**. A recap leads with decisions
and actions (the load-bearing content), then context, then blockers.

## 5-Second-Scan Design (human-behavior-aware)

A recap is read by a busy recipient who needs to know **what was decided and what they now own** in a
5-second scan. The fixed body order above already embodies the first scan principle (decisions and
actions lead, before context); these scan principles govern the rest:

1. **Decision/ask-first.** Decisions and the reader's action items surface **above the fold** — the
   fixed Decisions → Action Items order is exactly this principle. Context (Notes) and blockers follow;
   they never precede the decisions and actions.
2. **Inline-summary hard rule.** No recap references a raw transcript or long source as a **bare link** —
   every referenced source carries an **inline 1–3 sentence summary**. The reader must never open the
   source to learn what the recap is telling them. *(The single most load-bearing scan principle.)*
3. **Owner-tagged, dated actions.** Every Action Item carries an `@Owner` and a deadline in the
   `MM/DD/YY — @Owner: …` form (already required); an action with neither fails the scan test.
4. **Above-the-fold ask.** Any action the reader personally owns is identifiable in the first screen,
   not buried in Notes.

**Scan test (acceptance check).** Before a recap is send-ready it must pass: *the decisions and the
reader's owned actions are identifiable in ≤5 seconds; they sit above the fold; every source reference
carries an inline summary (no bare links); every action item is owner-tagged and dated.* The scan bar
is calibrated per audience (exec / team / technical) in the consumer's
[`references/audience-profiles.md`](../../operations/skills/comms-writer/references/audience-profiles.md).

## Timeliness and Distribution

- **Timeliness.** Sent within **4 business hours** of meeting end. **Same-day is the standard.**
- **Distribution.** Meeting attendees + the stakeholders identified during the meeting as needing
  visibility (the recipients rule above).

## Anti-Patterns

- **Fill-in placeholder tokens** (INSERT / TBD / ADD-DETAILS-style brackets) — a recap is a finished
  communication. Every gap is a specific, named information need, never a blank template token. This
  inherits the comms-writer hard guardrail.
- **Unattributed decisions** — every decision names its decision-maker; "it was decided" with no owner is
  status theater.
- **Orphan action items** — every action item carries an owner and a deadline in the
  `MM/DD/YY — @Owner: …` form.
- **Status-theater recap** — a long recap with no decisions and no action items is information-sharing
  without a purpose; every recap surfaces decisions and/or actions.
- **Bare-link source reference** — a recap that points at a transcript or long doc as a bare link with no
  inline 1–3 sentence summary forces the reader to open the source; inline the summary, then the link.
- **Backstory-before-decisions** — opening with narrative/context while the decisions sit below the fold;
  the fixed Decisions → Action Items → Notes order exists to prevent this. Decisions and actions lead.

## Consumers

| Consumer | Surface | Relationship |
|---|---|---|
| comms-writer | Meeting recap type (SKILL.md) | **Reference implementation** — its recap output IS this format. |
| comms-writer | `references/channel-formats.md` — Meeting Recap Format | References this doc as the single source (no inline format table remains). |

## Recap ↔ Follow-Up Record Boundary

A meeting recap is a point-in-time communication. It is **NOT** the system of record for meeting
follow-ups. Discrete, actionable follow-ups (owner **AND** deadline) are emitted as trackable
follow-up records into their tracker home (Open Meetings Tracker / Carry-Forward Tracker / RAID
Log) by ppm-agent meeting processing, per
[`proactive-follow-up-tracking.md`](../../operations/skills/ppm-agent/references/proactive-follow-up-tracking.md)
and the recap ↔ follow-up boundary in [`operational-artifacts.md`](operational-artifacts.md). The
recap and the follow-up records are **two artifacts, two lifecycles, two homes**: the recap is a
Point-in-Time Snapshot frozen at send; the records are Living tracked records mutated through their
own lifecycle.

In the recap, the **Action Items** section renders a **reference view** of those records — it does
not own their state:

- Each line cites the record's stable ID: `FU-MTG-NNN — @Owner — <one-line action> — <state as-of recap date>`.
- The recap states explicitly: **live follow-up status is maintained in the tracker; the list below
  is a snapshot as of the recap date.**
- "Open follow-ups from this meeting and their current status" is answerable by querying the tracker
  on `source_meeting`, **WITHOUT** parsing this recap.

The recap **references** follow-up records by ID; it never **duplicates** or owns their mutable state.
A recap that carries a mutable status column the reader is expected to trust as current is the
anti-pattern this boundary exists to prevent.

Internal `FU-MTG-NNN` IDs are **stripped** from stakeholder-facing sends per the comms-writer
No-internal-IDs rule — substitute the descriptive action line; the ID is retained only in the
working / tracker-linked copy.

## Cross-references

- [meeting-agenda-format.md](meeting-agenda-format.md) — the sibling output-format spec for the pre-meeting agenda.
- [duplicate-source-discipline.md](duplicate-source-discipline.md) — §1 option 2 (consolidate to canonical source); this doc is the single source the consumers' pointers resolve to.
- [sior-escalation-protocol.md](sior-escalation-protocol.md) — the sibling canonical output-format spec in this folder; the same single-source-plus-pointer model.
