---
title: Facilitation Techniques — Retrospective Domain
purpose: The retrospective lifecycle-domain file of the facilitation-techniques corpus. Carries the facilitation techniques an operator runs when a team reflects on a completed iteration — surfaced by delivery-engine Mode E (Execution Control) when a retrospective is in scope. Cards conform to the 9-field schema defined in the corpus index (README.md).
type: standard
reversibility: CHEAP / Confidence HIGH
domain: facilitation
lifecycle_phase: retrospective
framework_version_anchor: "v2.22"
consumers: "operations/skills/delivery-engine/SKILL.md Mode E (Execution Control — retro context hook) — the surfacing trigger consults this file's cards for the retrospective domain; also reached via pmo-scrum-master Mode 3 (Ceremony Support), which composes delivery-engine Mode E"
owner: "Workspace owner ([OPERATOR_NAME])"
---
<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->

# Facilitation Techniques — Retrospective Domain

Techniques for facilitating a team that is reflecting on a completed iteration — surfacing what to keep, what to change, and the concrete actions that carry into the next iteration. Each card conforms to the 9-field schema in [the corpus index](README.md). `delivery-engine` Mode E consults this file when an execution-control input references a retrospective to facilitate, and surfaces at most one technique that fits the in-scope activity, the project methodology, and is not contraindicated — silent otherwise.

These techniques are the *facilitation* layer of the retrospective — how the group structures its reflection in the room. They are distinct from, and compose with, the RAID/action-routing the consumer already owns: the technique governs how the team arrives at its observations and actions; the consumer routes the resulting retro actions to the Mode G RAID namespace (`A-DE-###`) with owner and due date. A retro that names a *cause* worth understanding (not just an action) routes to the RCA method (`core/disciplines/root-cause-analysis.md`) — these techniques do not replace cause analysis.

## 4Ls (Liked / Learned / Lacked / Longed-for)

| Field | Value |
|---|---|
| **name** | 4Ls (Liked / Learned / Lacked / Longed-for) |
| **lifecycle_phase** | retrospective |
| **methodology_compatibility** | Scrum / Kanban / SAFe / any iterative cadence. Methodology-neutral as a reflection frame; fits any cadence that closes an iteration with a look-back. Not a fit for a predictive Waterfall lifecycle's phase-gate review, which is a milestone sign-off, not a team reflection. |
| **what_it_is** | A structured-reflection retrospective format. The team populates four quadrants — **Liked** (what went well and was satisfying), **Learned** (new knowledge or insight gained), **Lacked** (what was missing that would have helped), **Longed-for** (what the team wished it had) — then clusters and discusses the themes before converting them into a small set of actions. The four lenses deliberately pull both affect (Liked) and capability gaps (Lacked / Longed-for) into the same frame so the discussion is balanced rather than complaint-led. |
| **when_to_use** | A regular end-of-iteration retrospective where the team needs a balanced reflection frame across what worked and what was missing — especially when recent retros have drifted into either pure positivity or pure complaint, and a four-lens structure rebalances the conversation. Best when the team has shared context on the iteration and enough psychological safety to name what it *lacked* and *longed-for* candidly. |
| **when_NOT_to_use** | Do NOT surface for a very small team or a single-incident retro where a focused timeline (what happened, in order) fits better than a four-quadrant sweep — the quadrants add ceremony with no gain when there is one event to dissect. Do NOT use when the team needs to **understand the cause of a specific failure** first: route that to the RCA method (a structured-reflection frame surfaces symptoms, not root causes). Do NOT use when there is no time to convert the quadrants into tracked actions — a 4Ls board with no resulting actions is reflection theater. |
| **participants_time_materials** | *Who:* the whole delivery team (the people who did the work) + a facilitator; a Scrum Master or the operator facilitating. A manager's presence can suppress candor on the Lacked/Longed-for lenses — weigh attendance. *Typical duration:* ~45–60 minutes for a sprint-length iteration (≈10 min populate, ≈20–25 min cluster + discuss, ≈10–15 min decide actions). *Materials:* a board (physical wall with four labeled quadrants and sticky notes, or a virtual retro board) and a way to capture the agreed actions into the tracker. |
| **steps_or_source_pointer** | Canonical source — Mary Gorman & Ellen Gottesdiener, the "4Ls" retrospective technique (EBG Consulting; widely documented in Agile retrospective practice). Steps are not re-derived here (anti-maintenance-debt): the four-quadrant frame is well-documented and stable in its canonical source. |
| **evidence_tier** | `established` — a canonical, widely-adopted structured-retrospective format with a stable primary source. |

## Start / Stop / Continue

| Field | Value |
|---|---|
| **name** | Start / Stop / Continue |
| **lifecycle_phase** | retrospective |
| **methodology_compatibility** | Scrum / Kanban / SAFe / any iterative cadence. Methodology-neutral; the action-first frame fits any team running a look-back. Not a fit for a predictive Waterfall phase-gate sign-off. |
| **what_it_is** | A fast, action-oriented retrospective format. The team answers three direct questions — what should we **Start** doing, what should we **Stop** doing, what should we **Continue** doing — and each answer is already shaped as a candidate action. Because the format frames every contribution as a behavioral change (or an explicit keep), it converts directly into a tracked retro-action list with minimal translation. |
| **when_to_use** | A time-boxed retrospective where the team needs to move quickly to concrete behavioral changes — the value is the *action set*, not an extended exploration. Strong fit for a team that already understands what happened and needs to decide what to do differently next iteration, and for shorter retros where a full four-lens sweep would not fit the time-box. |
| **when_NOT_to_use** | Do NOT surface when the team needs to **understand a failure's cause before deciding what to change** — jumping straight to Start/Stop/Continue produces actions that treat symptoms; route the cause work to the RCA method (`core/disciplines/root-cause-analysis.md`) first, then run the action frame. Do NOT use when the team needs space to surface and process *how the iteration felt* (morale, friction, what was missing) — the action-first frame skips the reflective lenses a format like 4Ls provides. Do NOT use when no one will own the resulting actions — an action-shaped retro with unowned actions is no better than no retro. |
| **participants_time_materials** | *Who:* the whole delivery team + a facilitator. *Typical duration:* ~20–30 minutes for a sprint-length iteration — the fastest of the common retro frames. *Materials:* three labeled columns (Start / Stop / Continue) on a physical or virtual board, and a way to capture the agreed actions into the tracker with an owner per action. |
| **steps_or_source_pointer** | Canonical source — standard Agile retrospective practice; cross-ref Esther Derby & Diana Larsen, *Agile Retrospectives: Making Good Teams Great* (Pragmatic Bookshelf, 2006), the "Decide What to Do" stage. Steps not re-derived (anti-maintenance-debt): the three-bucket frame is well-documented and stable. |
| **evidence_tier** | `established` — a canonical, widely-adopted action-oriented retrospective format with a stable primary source. |

## Provenance

Seeded in the v2.33 release as part of the Activity-Techniques Library increment that ships the Retrospective and Planning facilitation domains. The remaining lifecycle domains are deferred per the corpus index domain manifest; the tracking story for the remaining-domains decompose is recorded in the corpus index References block.
