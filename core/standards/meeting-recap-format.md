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

## Consumers

| Consumer | Surface | Relationship |
|---|---|---|
| comms-writer | Meeting recap type (SKILL.md) | **Reference implementation** — its recap output IS this format. |
| comms-writer | `references/channel-formats.md` — Meeting Recap Format | References this doc as the single source (no inline format table remains). |

## Recap ↔ Follow-Up Record Boundary

*(Reserved — populated by #378 at Engineering.)*

## Cross-references

- [meeting-agenda-format.md](meeting-agenda-format.md) — the sibling output-format spec for the pre-meeting agenda.
- [duplicate-source-discipline.md](duplicate-source-discipline.md) — §1 option 2 (consolidate to canonical source); this doc is the single source the consumers' pointers resolve to.
- [sior-escalation-protocol.md](sior-escalation-protocol.md) — the sibling canonical output-format spec in this folder; the same single-source-plus-pointer model.
