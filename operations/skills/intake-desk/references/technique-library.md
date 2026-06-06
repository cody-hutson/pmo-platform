# Technique Library

Elicitation technique cards, grounded in the IIBA BABOK Guide v3 Techniques chapter
and adapted to a single-user, asynchronous, agent-mediated context (one user, no
live workshop room, the agent cannot observe a system directly). Each card states
what the technique is, when to apply it, and the single-user-async adaptation. The
loop that draws on these cards is in `references/elicitation-loop.md`; the per-type
field targets are derived from the templates per `references/type-map.md`.

The goal of choosing a technique is to capture the right field set for the type and
altitude with the fewest, sharpest questions — never to run a long interview for its
own sake. The 5-test passing for the type/altitude (the clarity gate) is the stop
condition, per the loop reference; the cadence discipline is small batches of sharp
questions, not a hard question count.

## Extensibility contract

This selector is extensible. New domains, topics, and techniques are added by
appending rows to the selector and technique cards below; the loop reads the
selector, never a hardcoded technique-per-type mapping. The BABOK set is the base
(domain-general requirements-elicitation techniques) and remains the floor; per-domain
catalogs (functional / technical / design / advertising, and others as the platform's
intake surface grows) are added over time. The MVP ships the general / functional /
technical / design rows with the BABOK technique cards; the advertising / GTM row is
a documented placeholder demonstrating the extension point, not a built-out catalog.

## Technique cards (BABOK base)

### Structured / semi-structured interview (BABOK Interviews)

- **What:** predefined open-ended questions per type and level; semi-structured
  allows follow-ups as answers reveal new threads.
- **When:** every Mode A elicitation — this is the default technique. The question
  set is the required-field map for the identified type, derived from the template
  per `references/type-map.md`.
- **Single-user-async adaptation:** ask in small batches (cadence discipline — sharp
  questions, no hard count); prefer one sharp question that resolves a field over
  three that circle it. Echo back what you captured so the user can correct it.

### Laddering (requirements-clarification technique)

- **What:** "Why does that matter?" / "What would that enable?" to climb from a
  stated solution to the underlying need (up-laddering), or "What concretely would
  that require?" to descend from a goal to deliverables (down-laddering).
- **When:** up-ladder when the user states a solution but the problem (the WHAT) is
  unclear — climb to the need so the item is framed as WHAT, not HOW. Down-ladder
  when an initiative is stated but its concrete deliverables are vague — climb down
  to the candidate child work (which becomes a body decomposition callout, not N
  child items).
- **Single-user-async adaptation:** one ladder rung per message; name the rung
  ("stepping up a level: what problem does that solve?") so the user follows the move.

### Document analysis (BABOK Document Analysis)

- **What:** extract latent requirements from an artifact the user references — a
  transcript, an FDD, a prior work item, a spec, a log.
- **When:** the user points at an existing artifact rather than describing the idea
  fresh. Read the artifact, extract the candidate fields, and confirm them back rather
  than re-asking from scratch. (If the user wants an existing artifact processed and
  pushed to resolution — a transcript triaged, a backlog swept — that is ppm-agent's
  surface, not this skill's; defer.)
- **Single-user-async adaptation:** quote the artifact lines you derived a field from,
  so the user can correct a misread.

### Workshop-of-one / scenario walk (BABOK Workshops, adapted)

- **What:** walk the user through a concrete usage scenario to surface unstated
  acceptance criteria and value.
- **When:** a story's value or acceptance criteria are fuzzy, or a design/UX
  experience gap needs its journey walked. "Walk me through what a user does, step by
  step, and what they'd see at the end" surfaces the criteria the user has but has not
  stated.
- **Single-user-async adaptation:** a single narrated scenario stands in for the
  multi-stakeholder workshop; turn each step the user names into a candidate
  acceptance-criterion predicate.

### Observation-by-proxy (BABOK Observation, adapted)

- **What:** since the agent cannot observe a running system directly, ask the user to
  narrate the current state or reproduction path step by step.
- **When:** a bug's reproduction or environment is incomplete, or a technical/systems
  issue's specifics need recovering. "Tell me exactly what you did, in order, and what
  you saw — including the exact command and the exact error" recovers the reproduction
  and environment fields.
- **Single-user-async adaptation:** the user's narration is the proxy for direct
  observation; press for exactness (verbatim error text, exact branch/SHA) because the
  agent cannot fill the gap itself.

## Domain-adaptive technique selector (domain × topic × altitude → technique)

The selector is a 3-axis lookup so the agent picks the right technique for the
situation and user — not a fixed technique-per-type mapping. Match the most specific
domain row that applies; fall back to the general row otherwise.

| Domain (extensible) | Topic / level cue | Primary technique(s) | Why |
|---|---|---|---|
| (general / default) | any | Interview + the altitude-matched primary below | The BABOK base; always available. |
| **functional / process** | a workflow or business-rule gap | Workshop-of-one (scenario walk) + laddering(up) | Surfaces the process steps and the underlying need behind a stated solution. |
| **technical / systems** | a defect, integration, or data-shape issue | Observation-by-proxy + document analysis | Narrated reproduction + mining a referenced spec/log recovers the technical specifics (a structured-payload failure and a UI defect need different probes). |
| **design / UX** | an experience or interaction gap | Workshop-of-one (walk the user journey) + laddering(down) | Walks the experience to surface unstated acceptance criteria. |
| **advertising / GTM** *(future)* | a campaign / message / audience ask | (catalog TBD — future extension) | Placeholder row demonstrating the extension point. |

### Altitude-matched primary (within the general row)

| Identified type / altitude | Primary technique(s) | Why |
|---|---|---|
| `bug` (broken behavior) | Observation-by-proxy + interview | Reproduction and environment are narration-recovered; the rest is field-by-field interview. |
| `improvement` — story/feature | Workshop-of-one + interview | The scenario walk surfaces acceptance criteria and value; the interview fills the remaining fields. |
| `improvement` — initiative | Laddering (down) + document analysis | Down-laddering surfaces the candidate child work (a body callout); document analysis mines any referenced strategy/roadmap artifact. |
| `improvement` — solution stated, problem unclear | Laddering (up) + interview | Up-laddering reframes a stated HOW as the underlying WHAT before any fields are committed. |
| `observation` | Interview (3-question) | The placeholder tier needs only what-is-missing, what-good-looks-like, and the file pointer. |
| User points at an existing artifact | Document analysis (then confirm) | Extract from the artifact, confirm back; do not re-interview from scratch. |

When the type re-routes mid-elicitation (per the loop's re-routing rule), switch the
primary technique to match the new type — for example, a "bug" that re-routes to an
`improvement` switches from observation-by-proxy to workshop-of-one or laddering.
