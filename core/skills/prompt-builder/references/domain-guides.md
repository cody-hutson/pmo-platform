# Domain Guides

The shape of a "good prompt" depends entirely on what kind of prompt it is.
A prompt that's perfect for a SKILL.md body is wrong for an everyday Claude
ask, and vice versa. This file gives the target-type-specific shape.

Read the section that matches the **target type** identified during mode detection.

---

## Target type 1: Everyday Claude prompt

A one-shot or short conversational prompt to Claude (in chat, in a script, in
an API call). Optimized for fast iteration and direct results.

### Shape

```
[Goal — one sentence, lead with what you want]

[Context — 1–2 sentences: who I am, what I'm doing, what makes this specific]

[Inputs — paste documents, data, or state here, wrapped in tags if multi-line]

[Output spec — format, length, structure, what to include or exclude]

[Optional: one example of the desired output]
```

### Heuristics

- **Lead with the goal.** First sentence should make the ask unambiguous.
- **Add only the context that changes the answer.** No backstory for its own sake.
- **Specify the output format.** "Bullet list of 5 items" or "single paragraph"
  is enough. JSON or table only when downstream needs it.
- **Use XML tags for any input longer than ~3 lines.** `<transcript>...</transcript>`,
  `<email>...</email>`. This lets the model separate "the thing" from "instructions".
- **Skip the example** when format is obvious. Add an example when format is
  fiddly, voice matters, or the first attempt produced the wrong shape.

### Example

**Less effective:**
> "Can you help me with this email? It's kind of long and I want to make sure I'm
> hitting the right notes for my boss."

**More effective:**
> "Tighten this email for my VP. Goal: she should know what decision I need from her
> by Thursday and what's at stake. Cut anything that doesn't serve that. Keep my
> direct voice — no 'I hope you're doing well'.
>
> <email>
> [paste email here]
> </email>
>
> Return: the rewritten email, then 1–2 lines on what you cut and why."

---

## Target type 2: SKILL.md body

The markdown instructions that load into context when a skill triggers. Long-form,
opinionated, structured. Follows the [Anthropic skills convention](https://github.com/anthropics/skills).

### Shape

```
---
name: skill-name
description: >
  [Trigger description — see Target type 3 below]
---

# Skill Name

## Role
[Who is the skill / what perspective does the model take]

## Operating principles
[3–6 named principles that govern how the skill behaves across cases]

## [Mode detection or task-type detection]
[How to decide what flavor of work this is, since most skills cover several modes]

## Workflow
[Step-by-step, but explained — not just commands]

## Output format
[The exact shape of what the skill produces]

## Quality bar / READY criteria
[How the skill knows it's done]

## Reference docs
[Pointers to references/ files with when-to-read guidance]

## Guardrails
[Hard rejections and anti-patterns — but explain the why]
```

### Heuristics

- **Imperative voice.** "Read X first." "Identify Y." Not "you should" / "you might".
- **Explain the why for every constraint.** Today's models are smart; rote
  "MUST" / "NEVER" produces brittle behavior. Reasoning produces robust behavior.
- **Mode/type detection up front.** Most skills cover several variants. Make the
  branching logic explicit — usually as a table of signals → mode.
- **Push references to `references/`.** Anything over ~500 lines should spill.
  Reference files load on demand, SKILL.md body loads every invocation.
- **Patterns over examples.** If the same concept will be applied dozens of
  times, give the pattern. If it's a single tricky case, give an example.
- **Guardrails explain failure modes**, not just rules. "Don't strip the user's
  voice" + "if the original was casual, the rewrite stays casual" beats just
  "PRESERVE VOICE."
- **Output format is explicit.** Show the exact structure the skill produces,
  ideally as a code block.

### Anti-patterns specific to SKILL.md bodies

- Walls of ALL CAPS rules without reasoning
- Output specs that say "appropriate format" instead of showing the format
- Reference files that aren't pointed at from SKILL.md (the model won't find them)
- 800-line SKILL.md bodies that should have been 300 + references

---

## Target type 3: Skill description (YAML frontmatter)

The `description:` field in SKILL.md frontmatter. This is the **only** thing
the model sees when deciding whether to invoke the skill. Triggering depends
almost entirely on this field.

### Shape

```yaml
description: >
  [What the skill does — 1 sentence].
  [What kinds of inputs it handles, what it produces].
  [Specific user phrases and contexts that should trigger it — list 4–8].
  [Optional: when NOT to trigger, only if there's a known confusion case].
```

### Required techniques

These two techniques tested as the highest-leverage levers in evaluation.
Both are non-negotiable — every skill description rewrite must include them.

1. **Verbatim phrase mirroring.** Quote the user's *actual* trigger phrases
   inside the description, character-for-character. If the user says
   "Claude doesn't trigger on 'show me Q4 revenue trends'", the rewritten
   description must contain that exact string. Models match on string
   similarity — the closer the description text is to what users actually
   type, the more reliably it triggers.

2. **At least one explicit negative example.** Name a specific case where the
   skill should *not* trigger. Not a category ("don't trigger for general
   knowledge"), an instance ("do not trigger for 'what was US GDP in 2023'").
   Negative examples pin the exclusion in a way that prose framing cannot —
   they make the skill robust to lookalike queries that would otherwise
   over-trigger.

### Heuristics

- **Lead with what it does**, not what it is. "Builds…" not "Is a tool that…"
- **Be slightly pushy about triggering.** Claude has a strong tendency to
  *under*-trigger skills. Phrases like "use whenever the user asks for…" and
  "even if they don't explicitly say…" raise trigger rates.
- **List concrete user phrases, not abstract categories.** "Help me write a
  prompt for…" is more useful than "prompt engineering tasks".
- **Include adjacent contexts that should trigger.** If the user shares a
  block of text that *is* a prompt and asks for any feedback, that should
  trigger — even though they didn't say the word "improve".
- **Keep it under ~150 words.** Longer descriptions don't help triggering and
  may hurt because the model skims.
- **Avoid keyword salad.** Don't list 30 verbs. List 4–8 specific phrases that
  are realistic things a user would type.
- **Test with the description optimizer** (`scripts/run_loop.py` in `release/skills/pmo-skill-refiner/`, the preserved eval/optimization harness).

### Example

**Less effective:**
```yaml
description: A skill for prompt engineering. Helps with prompts.
```

**More effective:**
```yaml
description: >
  Builds and improves prompts of every kind — everyday Claude prompts, SKILL.md
  instruction bodies, skill descriptions, and agent/system prompts. Use whenever
  the user asks for help writing, improving, rewriting, critiquing, or scoping
  a prompt — including phrases like "help me write a prompt for…", "improve
  this prompt", "make this better", "what's wrong with this prompt", or
  whenever the user shares a block of text that is clearly an LLM prompt and
  asks for any kind of feedback.
```

---

## Target type 4: Agent / system prompt

A long-form prompt for a custom agent, subagent, or system message. Reads like
a contract: what the agent is, what it can do, what it must not do, how it
reports back.

### Shape

```
# [Agent Name]

You are [role]. You serve [user/system]. Your job is [specific scope].

## Capabilities
[What the agent can do — tools, knowledge, output types]

## Operating principles
[3–6 principles that govern judgment calls]

## When to ask vs. when to proceed
[Explicit decision tree for the gray area]

## Output format
[The exact structure of what the agent returns]

## Constraints
[What the agent must not do — and why]

## Edge cases
[Specific scenarios the agent will hit and how to handle them]
```

### Heuristics

- **Define scope sharply.** Agents fail when scope is ambiguous. "You answer
  questions about X" is weaker than "You answer questions about X. You do not
  answer questions about Y, even if asked. When asked about Y, respond with
  '[escape phrase]'."
- **Specify the contract for handoffs.** What does the agent receive? What
  does it return? In what format? With what metadata?
- **Tell the agent when to ask vs. proceed.** Most agent failures are over-asking
  (paralysis) or under-asking (silent assumptions). Make the rule explicit.
- **Constraints with reasoning.** "Don't fabricate dates" + "if a date isn't
  provided in the input, label it `[NEEDS_INPUT]` and proceed with structure"
  beats "NEVER MAKE UP DATES."
- **Output format is exact.** Agents that ship into pipelines need byte-exact
  output. Specify the structure as a code block. If JSON, specify keys, types,
  and which are required.
- **Account for the model's literal interpretation.** Opus 4.7 follows
  instructions literally. State the scope of every rule explicitly.

---

## Cross-cutting: when to add an example

Add a one-shot example when:
- Format is fiddly (JSON with specific keys, table with specific columns)
- Voice/tone matters (matching a specific writing style)
- The first attempt produced the wrong shape

Skip the example when:
- Format is obvious from the spec ("bullet list of 5 items")
- The example would be longer than the rest of the prompt
- You're already explaining the format clearly in prose

When you add an example, wrap it in `<example>` tags so the model knows it's
illustration, not instruction.
