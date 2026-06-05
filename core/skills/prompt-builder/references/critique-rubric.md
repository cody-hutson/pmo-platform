# Critique Rubric

Use this rubric to find the highest-leverage issues in a draft prompt. Don't
mechanically grade against every dimension — pick the 3–6 issues that will
*actually* change the model's output if fixed.

The rubric is grouped by **what most often goes wrong**. Skim each group, name
issues that apply, skip groups that don't.

---

## Group 1: Clarity of intent

**Question to ask:** Could a colleague with no context follow this prompt and
know what to do?

| Issue | Look for |
|---|---|
| Goal is implicit | The prompt describes a situation but doesn't state what to produce |
| Goal is buried | The actual ask is in line 12 of a 15-line prompt |
| Multiple competing goals | "Summarize and analyze and recommend and format" — pick one or sequence them |
| Vague verbs | "Help with", "look at", "deal with" — replace with specific actions |
| "Best", "good", "appropriate" | Subjective adjectives without criteria — specify what makes something good |

---

## Group 2: Context calibration

**Question to ask:** Does the prompt give the model the context it needs without
flooding it with context it doesn't?

| Issue | Look for |
|---|---|
| Missing audience | The prompt doesn't say who the output is for |
| Missing purpose | The prompt doesn't say what the output will be used for |
| Backstory bloat | 8 sentences of "for context, our team has been…" that don't change the answer |
| Wrong context level | Talking to the model as if it knows internal jargon, or over-explaining basics |
| Unstated constraints | "Should fit on one page" / "must avoid mentioning vendor X" not in the prompt |

---

## Group 3: Output specification

**Question to ask:** If you ran this prompt 10 times, would the outputs have
the same shape?

| Issue | Look for |
|---|---|
| No format spec | Prompt asks for "a summary" without specifying length, structure, or shape |
| Vague length | "Concise" / "detailed" without numbers |
| Missing structure | Output needs sections/fields/keys but the prompt doesn't say so |
| Inconsistent format cues | Asks for "a list" but example shows a paragraph |
| No example when fiddly | Format is non-obvious (specific JSON shape, specific table structure) and there's no example |

---

## Group 4: Inputs and grounding

**Question to ask:** Does the model have what it needs to produce a *true*
answer, and does it know what to do when it doesn't?

| Issue | Look for |
|---|---|
| Missing inputs | Prompt asks the model to summarize a document but the document isn't included |
| Inputs not tagged | Documents/data inline with instructions, no XML wrapper, model can't tell them apart |
| No "if not in source" instruction | Prompt invites hallucination by not allowing uncertainty |
| Wrong input order | Input pasted before the instructions — model may treat it as instructions |
| Pseudo-inputs | "Imagine you have access to our CRM" — actual access vs. hypothetical isn't clear |

---

## Group 5: Model-specific tuning

**Question to ask:** Is this prompt calibrated to how the current Claude model
actually behaves?

| Issue | Look for |
|---|---|
| Assumes too-literal generalization | "Use this format" without saying "for every section" — Opus 4.7 won't generalize |
| Vague verbosity guidance | "Concise" without a number — model defaults to its own calibration |
| Negative-only instructions | "Don't be flowery" — replace with positive guidance |
| Defensive over-specification | 12 "MUST NEVER" rules where one principle would do |
| Tool instructions missing | If the prompt expects tool use, it should explicitly invite it |
| Wrong place for instructions | Task buried in system prompt; or role description in user message |

---

## Group 6: Outcome simulation

**Question to ask:** If I picture the actual response this prompt will produce
when run against a realistic input, will that response serve what the user said
they wanted?

This is the most important group. Structural quality and outcome quality are
not the same thing. A prompt with all the right sections, XML tags, and length
caps can still produce a response that misses the user's actual decision —
buries the verdict, hedges where they wanted commitment, expands where they
wanted compression.

| Issue | Look for |
|---|---|
| Output would bury the verdict | The prompt asks for many sections without saying which one carries the decision — model defaults to even weighting |
| Output would hedge where user wanted commitment | No instruction forcing a labeled choice (FORWARD / KILL / GO / NO-GO) — model defaults to "consider both sides" |
| Output would expand where user wanted compression | Many required fields without a length cap — model produces thorough but unscan­nable response |
| Output would silently drop user's load-bearing constraint | Constraint mentioned in setup but never wired into output spec (e.g. budget freeze referenced in context but not flagged at the pricing section) |
| Output would miss the user's actual workflow context | Prompt produces a deep document when user is doing 3-5/week triage, or a one-liner when user needs deep-review depth |
| Output would feel right but be wrong on the most decision-relevant fact | No grounding instruction; model fills load-bearing claims (pricing, dates, ownership) from training-data plausibility |

To apply this group, do the following:

1. Read the rewritten prompt as if you were Claude about to execute it.
2. Picture the realistic response — what shape, what length, where the verdict
   would land, which fields would dominate.
3. Compare that imagined response against the user's stated goal (what they
   said they wanted to *do* with the output, not just what they asked for).
4. If there's a gap, fix the prompt before shipping. The fix is usually one
   of: add a length cap, name the load-bearing field explicitly, force a
   labeled verdict, wire the constraint into the output spec, or add a
   grounding instruction.

This is the hardest group to apply mechanically because it requires simulating
the model's response. Do it anyway — the gap between "well-formed prompt" and
"prompt that produces the right answer" is where prompt engineering actually
lives.

### Named-problem mechanism check

When the user has *explicitly named* one or more problems with the current
prompt ("the output drops the strikethrough rule", "the BLOCKERS section bloats
with stale items", "[COLLEAGUE_A] is bouncing off the 5-page output"), the rewrite
must do more than reference those problems — it must install a concrete,
executable mechanism that solves each one. List each user-named problem and
name the specific mechanism in your rewrite that handles it. A generic
statement fails this check; an algorithmic mechanism passes.

| User says | ❌ Generic (fails) | ✅ Mechanism (passes) |
|---|---|---|
| "strikethrough gets dropped on my own action items" | "The rewrite reinforces the strikethrough rule." | "Added pre-return self-check: before returning, scan all action items; for each item whose owner matches the workspace owner, wrap in `~~…~~` if not already wrapped." |
| "BLOCKERS section bloats with stale stuff" | "The rewrite improves BLOCKERS handling." | "Added two-pass algorithm: pass 1 carries forward yesterday's blockers and filters by staleness (drop if >2 business days without movement); pass 2 pulls fresh blockers from today's transcript; dedupe; output 'None flagged' when empty instead of padding." |
| "[COLLEAGUE_A] is bouncing off 5-page exec docs" | "The rewrite is more concise for leadership." | "Tiered output: Layer 1 capped at 350 words with explicit promotion rule (include only if leadership input needed within 5 business days, OR health moved, OR go-live gating); Layer 2 uncapped for deeper readers." |

Why this matters: the skill's natural failure mode is to *identify* problems in
the critique but then install polish in the rewrite — better structure, tighter
formatting, cleaner XML — without installing the specific algorithmic mechanism
that solves each named problem. Polish is real value, but when the user named
a specific problem, they're signaling where the load-bearing fix needs to be.
Match the fix to the named problem.

Run this check last, after the rest of the rubric. If any user-named problem
doesn't have a named mechanism beside it in your rewrite, go back and add one
before shipping.

---

## Group 7: Anti-patterns and structural issues

**Question to ask:** Are there structural problems that would be obvious to a
prompt engineer reviewing this?

| Issue | Look for |
|---|---|
| `[INSERT X]` placeholders | The model will fill them with hallucinations |
| Multiple jobs in one prompt | "Summarize, then analyze, then write a memo" — chain instead |
| Pure negative examples | "Bad output: …" without showing good output |
| Conflicting instructions | "Be concise" and "explain in detail" both present |
| Unmarked assumptions | Prompt assumes the model knows things that aren't given |
| Hard caps without escape valve | "Always do X" with no handling of cases where X is impossible |

---

## How to phrase a critique point

A good critique point has three parts:

1. **What's wrong** — name the issue specifically
2. **Why it matters here** — connect it to *this* prompt's goal
3. **Implicit fix** — the rewrite should solve it

**Examples:**

- "**Goal is implicit.** The prompt describes the situation (you have a
  transcript, you have stakeholders) but never states what the model should
  produce. The rewrite leads with 'Produce a 5-bullet recap…'."

- "**Output spec is missing.** You asked for 'a summary' without specifying
  length or structure — the model will pick its own. Since this is going to
  [COLLEAGUE_A], the rewrite specifies '3 sentences, exec-friendly, action items
  bolded'."

- "**Negative-only guidance.** 'Don't be too verbose' is weaker than 'Keep it
  under 150 words'. The rewrite uses the explicit cap."

Keep critique points **short**. The user is going to skim them and read the
rewrite. The critique exists to make the rewrite legible — not to be the
deliverable.
