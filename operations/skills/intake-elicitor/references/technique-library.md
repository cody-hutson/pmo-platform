# Technique Library

Elicitation technique cards, grounded in the IIBA BABOK Guide v3 Techniques chapter and adapted to a single-user,
asynchronous, agent-mediated context (one user, no live workshop room, the agent cannot observe a system directly).
Each card states what the technique is, when to apply it, and the single-user-async adaptation. The loop that draws
on these cards is in `references/elicitation-loop.md`; the per-type field targets are in `references/type-map.md`.

The goal of choosing a technique is to capture the right field set for the type and altitude with the fewest, sharpest
questions — never to run a long interview for its own sake (the 5-test is the stop condition, per the loop reference).

## Technique cards

### Structured / semi-structured interview (BABOK Interviews)

- **What:** predefined open-ended questions per type and level; semi-structured allows follow-ups as answers reveal
  new threads.
- **When:** every Mode A elicitation — this is the default technique. The question set is the required-field map for
  the identified type in `references/type-map.md`.
- **Single-user-async adaptation:** ask in small batches (respect the max-5-questions guardrail); prefer one sharp
  question that resolves a field over three that circle it. Echo back what you captured so the user can correct it.

### Laddering (requirements-clarification technique)

- **What:** "Why does that matter?" / "What would that enable?" to climb from a stated solution to the underlying
  need (up-laddering), or "What concretely would that require?" to descend from a goal to deliverables
  (down-laddering).
- **When:** up-ladder when the user states a solution but the problem (the WHAT) is unclear — climb to the need so
  the item is framed as WHAT, not HOW. Down-ladder when an initiative is stated but its concrete deliverables are
  vague — climb down to the child items.
- **Single-user-async adaptation:** one ladder rung per message; name the rung ("stepping up a level: what problem
  does that solve?") so the user follows the move.

### Document analysis (BABOK Document Analysis)

- **What:** extract latent requirements from an artifact the user references — a transcript, an FDD, a prior issue,
  a spec.
- **When:** the user points at an existing artifact rather than describing the idea fresh. Read the artifact, extract
  the candidate fields, and confirm them back rather than re-asking from scratch. (If the user wants an *existing*
  artifact processed and pushed to resolution — a transcript triaged, a backlog swept — that is ppm-agent's surface,
  not this skill's; defer.)
- **Single-user-async adaptation:** quote the artifact lines you derived a field from, so the user can correct a
  misread.

### Workshop-of-one / scenario walk (BABOK Workshops, adapted)

- **What:** walk the user through a concrete usage scenario to surface unstated acceptance criteria and value.
- **When:** a story's value or acceptance criteria are fuzzy. "Walk me through what a user does, step by step, and
  what they'd see at the end" surfaces the AC the user has but has not stated.
- **Single-user-async adaptation:** a single narrated scenario stands in for the multi-stakeholder workshop; turn
  each step the user names into a candidate acceptance-criterion predicate.

### Observation-by-proxy (BABOK Observation, adapted)

- **What:** since the agent cannot observe a running system directly, ask the user to narrate the current state or
  reproduction path step by step.
- **When:** a bug's reproduction or environment is incomplete. "Tell me exactly what you did, in order, and what you
  saw — including the exact command and the exact error" recovers the reproduction and environment fields.
- **Single-user-async adaptation:** the user's narration is the proxy for direct observation; press for exactness
  (verbatim error text, exact branch/SHA) because the agent cannot fill the gap itself.

## Technique selector (altitude × type → primary technique)

| Identified type / altitude | Primary technique(s) | Why |
|---|---|---|
| `bug` (broken behavior) | Observation-by-proxy + interview | Reproduction and environment are narration-recovered; the rest is field-by-field interview. |
| `improvement` — story/feature | Workshop-of-one + interview | The scenario walk surfaces acceptance criteria and value; the interview fills the remaining fields. |
| `improvement` — initiative | Laddering (down) + document analysis | Down-laddering surfaces the child deliverables; document analysis mines any referenced strategy/roadmap artifact. |
| `improvement` — solution stated, problem unclear | Laddering (up) + interview | Up-laddering reframes a stated HOW as the underlying WHAT before any fields are committed. |
| `observation` | Interview (3-question) | The placeholder tier needs only what-is-missing, what-good-looks-like, and the file pointer. |
| `adr` | Interview + laddering | Interview captures context/drivers/options; laddering tests whether each "option" is genuinely distinct. |
| User points at an existing artifact | Document analysis (then confirm) | Extract from the artifact, confirm back; do not re-interview from scratch. |

When the type re-routes mid-elicitation (per the loop's re-routing rule), switch the primary technique to match the
new type — for example, a "bug" that re-routes to an `improvement` switches from observation-by-proxy to
workshop-of-one or laddering.
