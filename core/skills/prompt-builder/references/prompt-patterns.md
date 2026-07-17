---
title: Prompt Patterns — Baseline Reference
purpose: A baseline reference of Anthropic prompting best-practice patterns for prompt-builder — the fallback when live WebFetch fails and the cross-check when live guidance conflicts.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Prompt Patterns — Baseline Reference

**Last reviewed**: 2026-04-18
**Source**: Anthropic prompting best practices documentation
**Use**: Fallback when live `WebFetch` fails. Cross-check when live guidance contradicts.

This is a baseline snapshot. The skill should refresh from
`https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices`
on each invocation. Use this file only as a fallback or to sanity-check the live results.

---

## Foundational techniques (model-agnostic, still current)

### 1. Be clear and direct

Treat Claude as a brilliant new employee who lacks context on your norms. The
more precisely you describe what you want, the better the output. **Golden rule:**
show your prompt to a colleague with no context. If they'd be confused, Claude
will be too.

- Be specific about desired output format and constraints.
- Use numbered or bulleted steps when order matters.
- State the scope explicitly ("apply to every section, not just the first").

### 2. Add context and motivation

Explain *why*, not just *what*. Models with theory of mind handle edge cases
better when they understand the underlying intent.

- Why does this format matter?
- Who is the eventual reader of the output?
- What downstream system will consume it?

### 3. Use examples (multishot prompting)

Examples are one of the highest-leverage techniques.

- **One-shot first.** Add a single example of the desired output. Most of the
  time this is enough.
- **Few-shot if needed.** Add 2–3 more examples only if the one-shot didn't
  produce the right shape.
- **Positive examples beat negative.** Show what you want, not what you don't.
- Wrap examples in `<example>` tags so they're visually and structurally
  distinct from instructions.

### 4. Use XML tags for structure

Claude was trained with XML in its data and responds well to it. Use tags to:

- Separate inputs from instructions: `<document>...</document>`, `<input>...</input>`
- Mark examples: `<example>...</example>`
- Group related instructions: `<rules>...</rules>`
- Identify the section the model should respond in: `<response>...</response>`

XML tags also make prompts easier for humans to read and maintain.

### 5. Give Claude time to think (chain of thought)

For multi-step reasoning, ask the model to think before answering.

- "Think step by step before giving your final answer."
- "Before responding, list the considerations, then write the final response in `<answer>` tags."
- For complex tasks, structure the thinking explicitly: "First identify X. Then
  evaluate Y. Then produce Z."

### 6. Use system vs. user prompts deliberately

- **System prompt**: role, persona, tools, high-level scene-setting
- **User prompt**: the actual task instructions, the inputs, the output spec

Claude follows instructions in the user message slightly more reliably than in
the system message. Don't bury the actual task in the system prompt.

### 7. Specify output constraints explicitly

Vague constraints produce variable output. Specific constraints produce
predictable output.

- "Summarize in exactly 3 sentences, each under 20 words" beats "summarize concisely"
- "Return as a JSON object with keys `name`, `email`, `role`" beats "extract structured data"
- "Begin your response with `## Summary`" beats "use markdown headers"

### 8. Allow uncertainty explicitly

Give the model permission to say "I don't know" or "I'm not sure". This reduces
hallucination significantly.

- "If the answer isn't in the provided document, say 'Not in source'."
- "If you're uncertain, label your response `[LOW CONFIDENCE]`."

### 9. Prefill responses

You can pre-fill the start of the model's response to constrain format or
character voice. Especially useful for:

- Forcing a specific output format (start with `{` for JSON)
- Maintaining a persona ("As Claude the chef, I would say:")
- Skipping pleasantries (start the response directly with content)

---

## Model-specific notes for Claude Opus 4.7 (current)

### Literal instruction following

Opus 4.7 follows instructions more literally than 4.6. It will not silently
generalize from one item to another. **State scope explicitly.**

- ✅ "Apply this formatting to every section in the document."
- ❌ "Use this format." (4.7 may apply only to the first section)

### Verbosity calibration

Opus 4.7 calibrates output length to its judgment of task complexity. Simple
asks get short answers; open-ended asks get long ones. If you need a specific
length, **say so explicitly**.

- "Keep responses to under 200 words."
- "Provide concise, focused answers. Skip non-essential context."

### Effort levels

When using the API directly, the `effort` parameter (`low`, `medium`, `high`,
`xhigh`, `max`) controls reasoning depth.

- `xhigh`: best for coding and agentic work
- `high`: minimum for intelligence-sensitive use cases
- `medium`: cost-sensitive
- `low`: scoped, latency-sensitive

If you see shallow reasoning at low/medium, raise effort instead of prompting
around it.

### Tool use triggering

Opus 4.7 uses tools less often than 4.6 by default — it reasons more. If you
want more tool use, be explicit:

> "When the user asks about current data, use the `web_search` tool. Do not rely
> on training data for time-sensitive information."

### Tone

Opus 4.7 is more direct and opinionated than 4.6, with less validation-forward
phrasing. If you want a warmer voice, prompt for it explicitly:

> "Use a warm, collaborative tone. Acknowledge the user's framing before answering."

### Subagent spawning

Opus 4.7 spawns fewer subagents by default. For agentic systems, instruct
explicitly when to fan out:

> "Spawn multiple subagents in the same turn when fanning out across items.
> Do not spawn a subagent for work you can complete in a single response."

---

## Anti-patterns (things to avoid in prompts)

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| "Don't be verbose" | Negative instructions are weaker than positive | "Keep responses under 150 words" |
| "Use your best judgment" | Models default to average | Specify the criteria explicitly |
| "Be helpful" | No information content | Replace with concrete behaviors |
| `[INSERT X HERE]` placeholders | Models will fill them with hallucinations | Either fill them or label as required input |
| Burying the task in a system prompt wall | Instructions get diluted | Move task instructions to user message |
| One mega-prompt with 12 different jobs | Context interference, lower per-task quality | Chain prompts — one job per prompt |
| Pure negative examples ("don't write like this") | Reinforces the pattern you don't want | Show the pattern you do want |
| Hard caps without reason ("MUST NEVER") | Brittle, hard for model to handle edge cases | Explain the underlying principle so it can generalize |

---

## When to use which technique

| Situation | First lever | Second lever |
|---|---|---|
| Output format is wrong | Add explicit format spec | Add a one-shot example |
| Output is too verbose | "Concise responses, under N words" | Prefill start of response |
| Output is too short | Raise effort level (API), or "go deep on each section" | Add `<thinking>` step |
| Model misunderstands intent | Add context/motivation | Add a one-shot example |
| Model invents facts | Allow uncertainty + ground in `<document>` | Add "if not in source, say so" |
| Multi-step reasoning fails | Add chain-of-thought structure | Decompose into multiple prompts |
| Persona drifts | Use system prompt for role; prefill responses | Few-shot examples of in-character output |
| Tool use too sparse | Explicit instruction for when to use tools | Raise effort level |
