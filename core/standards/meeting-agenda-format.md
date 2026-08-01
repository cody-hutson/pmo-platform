---
title: Meeting Agenda Output-Format Spec
purpose: The output-format spec defining the structure and field semantics of every PMO-produced meeting agenda — purpose, attendees, coverage, prep, and join details.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: comms-writer (agenda mode); artifact-generator; any skill producing a pre-meeting agenda artifact
---
<!-- reference-durability: allow-link -->
# Meeting Agenda Output-Format Spec

> **Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
> **Canonical home** for the meeting-agenda output format — the six required agenda elements, their
> field semantics, and the formality-calibration rule. Consumed by comms-writer (Meeting agenda type —
> the reference implementation), comms-writer's `references/channel-formats.md` (Meeting Agenda Format
> table), and tracker-manager's `references/tracker-schemas.md` (the Open Meetings Tracker `MTG-###`
> `Agenda` field). This doc is the **single source**; consumers reference it by relative link rather than
> re-defining the format (per [duplicate-source-discipline.md](duplicate-source-discipline.md) §1 option 2
> — consolidate to a canonical source). It is an output-format *specification* for a finished
> communication, not a fill-in template.

## Purpose

A meeting agenda is a finished pre-meeting communication that tells attendees what the session is for,
who is in the room and why, what will be covered (and by whom, in what order, for how long), what to
prepare, and how to join. This spec defines the structure and field semantics every PMO-produced agenda
carries so the agenda reads as a complete, send-ready communication — not a blank template with
fill-in placeholders. The agenda the consumer produces IS this format; the consumer never re-derives
the element set.

## Format Spec — Six Required Agenda Elements

Every agenda contains six named elements, in this order. The six are mandatory; an agenda missing any
one is not conformant.

| # | Element | Content | Rule |
|---|---|---|---|
| 1 | **Subject line** | Descriptive of the session purpose, not just the meeting name. | Names the outcome the session drives, so the invite is self-explaining in an inbox. |
| 2 | **Attendees** | Required vs. optional, each with a rationale. | Every attendee has a stated reason for being required or optional — no unexplained invitee. |
| 3 | **Goal statement** | One sentence describing the session outcome. | Exactly the outcome the meeting produces; if the goal cannot be stated in one sentence, the meeting scope is unclear. |
| 4 | **Agenda items** | Numbered or lettered; owners tagged via `@Name`; time allocations when appropriate; sub-items for complex topics. | Each item is owned and (where useful) time-boxed; complex topics carry sub-items so the discussion has structure. |
| 5 | **Pre-read / preparation requirements** | What attendees need to review or prepare before the session — listed explicitly, linked, with the specific sections to focus on. | "Please review X before the meeting" names the artifact and the focus; never a vague "come prepared." |
| 6 | **Meeting logistics** | Teams link placeholder, dial-in reference, recording notice if applicable. | The join path is present even when the link is a placeholder the sender fills at send time. |

## Formality Calibration

Calibrate the agenda's formality to the meeting type. The six elements are always present; their weight
and rendering vary:

| Meeting type | Rendering |
|---|---|
| **Cross-functional technical session** | Structured numbered items with `@Name`-tagged owners and time allocations per item; sub-items for complex topics. |
| **Quick internal sync** | Brief discussion points rather than a heavily-structured numbered list; owners and a light goal still present. |
| **Refinement session** | A detailed loop structure (e.g., item → discussion → decision → next item) reflecting the iterative nature of the ceremony. |

The calibration scales the *form*; it never drops a required element. A quick sync still has a subject,
a one-sentence goal, attendees with rationale, the discussion points (the agenda-items element in light
form), any pre-read, and a join path.

## 5-Second-Scan Design (human-behavior-aware)

A meeting agenda is read by a busy recipient skimming an inbox. It must communicate **what the meeting
needs from them** in a 5-second scan. The six required elements above are present; these four scan
principles govern *how they are ordered and rendered* so the agenda is absorbable at a glance:

1. **Decision/ask-first.** Lead with the decision to be made or "what we need from you," not the
   backstory. The goal statement and any decision/ask surface **above the fold** (in the first screen of
   the invite), before context or history.
2. **Inline-summary hard rule.** No agenda or pre-read references a raw transcript or long source as a
   **bare link** — every referenced source carries an **inline 1–3 sentence summary** of what it says
   and why it matters. The recipient must never have to open the source to reconstruct context before
   the meeting. *(This is the single most load-bearing scan principle.)*
3. **Time-boxed, owner-tagged items.** Each agenda item carries an `@Owner` **and** a time allocation
   (element 4 made mandatory by the scan bar — owner + time-box are not optional polish; an un-owned or
   un-timed item fails the scan test).
4. **Above-the-fold ask.** "What we need from you" — the decision, approval, or input the meeting
   requires — surfaces above the fold, never buried after the agenda list.

**Scan test (acceptance check).** Before an agenda is send-ready it must pass: *the decision/ask is
identifiable in ≤5 seconds; the ask is above the fold; every source reference carries an inline
summary (no bare links); every agenda item is owner-tagged and time-boxed.* The scan bar is calibrated
per audience (exec / team / technical) in the consumer's
[`references/audience-profiles.md`](../../operations/skills/comms-writer/references/audience-profiles.md).

## Anti-Patterns

- **Fill-in placeholder tokens** (INSERT / TBD / ADD-DETAILS-style brackets) — an agenda is a finished
  communication. Every gap is a specific, named information need ("NEEDS: confirmed attendee list from
  the meeting owner"), never a blank template token. This inherits the comms-writer hard guardrail.
- **Unowned agenda items** — every agenda item carries an `@Name` owner; an item with no owner has no one
  accountable to lead it.
- **Goal stated as a topic, not an outcome** — "Discuss the integration" is a topic; "Agree the
  integration cutover sequence and owner" is an outcome. The goal statement names the outcome.
- **Bare-link pre-read** — a pre-read that references a transcript or long doc as a bare link with no
  inline 1–3 sentence summary forces the reader to open the source to reconstruct context, defeating the
  5-second scan. Inline the summary; the link follows it.
- **Backstory-before-ask** — opening with context/history while the decision or ask is buried below the
  fold. The reader scans top-down and abandons before reaching the ask. Lead with the decision/ask.
- **Un-timed agenda item** — an item with no time allocation; an un-timed agenda overruns. Each item is
  time-boxed.

## Consumers

| Consumer | Surface | Relationship |
|---|---|---|
| comms-writer | Meeting agenda type (SKILL.md) | **Reference implementation** — its agenda output IS this format. |
| comms-writer | `references/channel-formats.md` — Meeting Agenda Format | References this doc as the single source (no inline element definition remains). |
| tracker-manager | `core/schemas/tracker-schemas.md` **and** its skill-local half `references/tracker-schemas.md` — Open Meetings Tracker `MTG-###` `Agenda` field | References this doc for the agenda-field structure (cross-consistent with the canonical element set). The two files are a **registered complementary pair** (`core/deploy/allowlists/complementary-reference-pairs.txt`) whose § Tracker 3 is a declared *shared* section, so the pointer is stated in **both** halves — a pointer present in only one half is a drift finding, not a division of labour. |

## Cross-references

- [meeting-recap-format.md](meeting-recap-format.md) — the sibling output-format spec for the post-meeting recap.
- [duplicate-source-discipline.md](duplicate-source-discipline.md) — §1 option 2 (consolidate to canonical source); this doc is the single source the consumers' pointers resolve to.
- [sior-escalation-protocol.md](sior-escalation-protocol.md) — the sibling canonical output-format spec in this folder; the same single-source-plus-pointer model.
