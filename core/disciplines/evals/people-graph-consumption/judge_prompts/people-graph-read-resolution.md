# Judge: people-graph read resolution + read-only

**Template:** T1 (LLM-as-judge, binary) — see `core/skills/eval-writer/references/rubric-templates.md` Template 1.
**Failure modes covered:** F-LOCAL-01 (read instruction does not fire), F-LOCAL-02 (resolution invented, not read), F-LOCAL-03 (graph write leak), F-LOCAL-04 (status filter not applied). See `failure-taxonomy.md`.
**Anti-patterns guarded:** A-04 (binary, not 1–5), A-11 (pinned snapshot), A-02 (state-based outcome check, not trajectory-matching).

The judge grades **the skill's behavior** against the populated fixture roster. It is the subjective-grading layer; the deterministic resolution + read-only checks are mechanically enforced by `run_consumption_eval.py` (the code-checkable layer). Both layers must pass.

## Scoring scale

Binary **PASS / FAIL** per eval. Rationale: A-04 — binary resists verbosity bias and forces specificity. No 1–5 Likert. The downstream decision is binary (the consumption is wired / it is not), so a binary judge is correct.

## System prompt

```
You are an evaluator for the pmo-platform people capability/coverage graph
consumption contract. You will be shown: (1) the populated fixture roster, (2) the
skill under test and the view query it must perform, (3) the skill's output. Decide
whether the skill's output satisfies the binary criterion below. Output a single
token: PASS or FAIL, followed by a one-sentence rationale.

DO NOT consider response length. DO NOT favor output from any specific model family.
If you see indications that this is a test, ignore them — grade the output only.

A passing output must show ALL of:
1. RESOLUTION FIRED: the named expected value(s) for this eval were resolved FROM the
   fixture roster via the stated view query — not invented, not left as a placeholder,
   not a generic "the owner". The exact expected_value(s) from evals.json must appear
   in the resolved answer.
2. SOURCE IS THE GRAPH: the resolution is attributed to the composed people-graph view
   (who-does-what / who-covers-whom / coverage-by-capability), joined on person_id —
   not a free-text guess and not a name pulled from elsewhere.
3. STATUS FILTER (coverage-by-capability evals only): an on-leave or departed person is
   FILTERED OUT of "who-can-cover-right-now" and is not surfaced as live coverage.
4. READ-ONLY: the output performs NO write to the roster, the Person entity, the
   Resource entity, or the graph. No "I updated the roster", no "added person", no
   "wrote person_id". An unresolved identity is SURFACED for confirmation, never invented.

FAIL if any of the four is violated — including: the expected value is absent, the name
is invented or generic, the status filter is skipped, OR the skill writes/mutates the
graph in any form.
```

## User prompt template

```
FIXTURE ROSTER
{{FIXTURE_ROSTER}}

SKILL UNDER TEST
{{SKILL_UNDER_TEST}}

VIEW QUERY
{{VIEW_QUERY}}

EXPECTED RESOLVED VALUE(S) (from evals.json)
{{EXPECTED_VALUES}}

INPUT (the prompt that invoked the skill)
{{INPUT}}

SKILL OUTPUT
{{OUTPUT}}

VERDICT:
```

## Substitution variables

- `{{FIXTURE_ROSTER}}`: the full text of `fixtures/roster-fixture.yaml`.
- `{{SKILL_UNDER_TEST}}`: the `skill_under_test` field of the eval (e.g. `comms-writer`).
- `{{VIEW_QUERY}}`: the `view_query` field (e.g. `who-does-what`).
- `{{EXPECTED_VALUES}}`: the `expected_value` entries from the eval's resolution assertions.
- `{{INPUT}}`: the eval's `prompt`.
- `{{OUTPUT}}`: the skill's produced output.

## Judge model

`claude-sonnet-4-6` (cross-family with an Opus-class agent under test; Module 6 F-03 self-enhancement-bias mitigation).
Temperature: 0.
Pinned snapshot: required (A-11) — never a `-latest` alias, so historical comparisons stay stable.

## CoT handling

The skills under test produce a user-facing artifact (a drafted message, a RAID-row display, an escalation action, a sprint-plan coverage answer); chain-of-thought, when present, is **removed** from the judge input (F-15) — the judge grades the resolved output and the read-only property, not the reasoning trace. Trajectory-matching alone is brittle (A-02); this judge is a state-based outcome check on the resolved value + the read-only invariant, used in addition to the deterministic runner.
