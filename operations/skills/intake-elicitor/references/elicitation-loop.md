# Elicitation Loop

The mechanics of Mode A (the four-phase elicitation loop) and the 5-test rule that Mode B applies and Mode A
enforces live. Grounded in the IIBA BABOK Guide v3 Elicitation and Collaboration knowledge area (Prepare → Conduct →
Confirm) and its Requirements Classification Schema (business / stakeholder / solution / transition requirement
levels). The technique cards the loop draws on live in `references/technique-library.md`; the type set and per-type
field maps live in `references/type-map.md`; the emission contract lives in `references/output-contract.md`.

## The altitude model

Users enter intake at different altitudes. Meet them where they are; do not force a portfolio initiative down to a
task, and do not inflate a one-line bug into an epic. Altitude maps to the BABOK Requirements Classification Schema:

| Entry altitude | BABOK requirement level | Typical work-item shape |
|---|---|---|
| Portfolio initiative / program | Business requirement | An `improvement` framed as an initiative — outcomes, domain context, child decomposition |
| Feature / story | Stakeholder requirement | An `improvement` framed as a story — acceptance criteria, value |
| Task / bug | Solution requirement | A `bug` (broken behavior) or a small `improvement` |
| Migration / rollout / cutover | Transition requirement | An `improvement` framed around the transition steps |

State the detected altitude back to the user in phase 1 and proceed from there.

## The four-phase loop (Mode A)

### Phase 1 — Meet at altitude (BABOK Prepare for Elicitation, adapted)

Detect the user's entry altitude from their framing. Name it ("this reads like a portfolio-level initiative" /
"this sounds like a single bug"). Do not silently re-pitch the altitude up or down. If the framing is genuinely
ambiguous, ask one altitude-disambiguating question, not a battery.

### Phase 2 — Identify type and place in the hierarchy (BABOK Conduct, classification step)

Propose the work-item type from the registry in `references/type-map.md` and its place in the intake hierarchy.
State the proposed type and why ("this is a `bug` because it describes broken behavior, not a missing capability").

**Re-routing rule.** Treat the type as provisional through phase 3. As elicitation develops, if the user's answers
reclassify the item, re-route explicitly and say why — do not lock the first guess. Common re-routes:

- A "bug" that is actually a missing capability → re-route to `improvement`.
- A "task" that is actually three unrelated changes → split (T1 fails); surface the split, do not flatten.
- An "idea" that is actually a design decision needing a record → re-route to `adr`.
- A thin item that cannot reach intake-ready → route to `observation` (the placeholder tier).

The re-route is the correct behavior, not a failure. Announce it in one line and reset to the new type's field set.

### Phase 3 — Elicit type/level fields (BABOK Conduct, the techniques)

Ask for the field set THIS type at THIS level requires, per `references/type-map.md`, using the techniques in
`references/technique-library.md`. Apply the 5-test rule live (see below) so the emerging item is neither under- nor
over-defined.

**Enforce the WHAT/HOW boundary live.** Intake commits WHAT (problem, constraints, observable outcome, acceptance
criteria); HOW (algorithm, data structure, file-internal pattern) is Stage 5 Solutioning's job. If the user
prescribes a mechanism, record it as `[ASSUMPTION – CONFIRM] mechanism deferred to Stage 5` rather than baking it
into the item. The signal of an over-specified contribution is pseudocode, a named implementation pattern, a
line-level surgical directive, or an algorithm-step description — capture the underlying need, defer the mechanism.

### Phase 4 — Confirm and emit (BABOK Confirm Elicitation Results)

Render the issue body against the identified type's template. Run the 5-test as a gate. Present the rendered body
plus the 5-test verdict. Obtain explicit user confirmation. Then emit per `references/output-contract.md`. For a
container type (an initiative or epic-equivalent), surface the decomposition (the child items) before emit — do not
auto-create the children (that is an unauthorized cascade; the human files them, or a future mode does).

## The 5-test rule (T1–T5)

Apply these five binary tests at authoring time. Mode B runs them once against a user-supplied draft; Mode A re-runs
them after each elicited field and treats them as the stop condition. If all five pass → intake-ready. If any fails →
defer the relevant part to Stage 5, split the item, or route to `observation` per the failure routing below.

| # | Test | Pass if |
|---|---|---|
| T1 | Atomic? Could this be reverted by a single revert — one cohesive change? | Yes. If two or more unrelated changes, split into separate items with a parent tracking item. |
| T2 | Determinate design? Is there a single reasonable implementation, or is the design boundary deferred to Solutioning explicitly? | Single, OR the design is deferred with an explicit `[ASSUMPTION – CONFIRM]`. If the author is secretly assuming a design without naming it, fail. |
| T3 | Verifiable AC? Can a fresh agent check each acceptance-criterion predicate by reading a file, running a command, or inspecting an output? | Yes — each AC is a predicate. If any AC is a vibe ("works correctly", "improves flow"), fail. |
| T4 | File pointer? Does the proposed change name at least one specific file/section, OR explicitly say `[ASSUMPTION – CONFIRM] TBD — identified in Planning`? | Yes — directional or deferred-with-marker, not silent. |
| T5 | Risk surfaced? Are the known risks, cross-issue conflicts, or concurrent-work conflicts named (even a one-liner), OR an explicit "None identified"? | Yes — risks named if they exist, or an explicit declaration. Silent = fail. |

### Failure routing

- T1 fails → split into multiple items with a parent tracking item; the author commits the split rationale.
- T2 fails → do not commit a design at intake; mark any design assumption `[ASSUMPTION – CONFIRM]` and note "HOW
  deferred to Stage 5 Solutioning." The item is still intake-ready; Solutioning will activate.
- T3, T4, or T5 fails and the user cannot fix it at authoring time → route to `observation` (the lightweight
  placeholder tier); explicitly stage the finding as a placeholder. Triage promotes it to `improvement` later when
  enough context exists. This is the correct route — never force a thin `improvement` past a failing test.

### The stop condition (over-elicitation guard)

The 5-test is the stop condition, not a starting point for more questions. The moment all five pass for the current
type and level, move to phase 4 (Confirm and emit). After they pass, offer once ("anything else to add?"), then emit.
Continuing to elicit "nice to have" detail past intake-ready produces an over-defined item and a fatigued user —
over-definition is a named quality failure symmetric to under-definition.

## WHAT-framing rewrites (used by Mode B and by phase 3)

When an item commits a HOW that belongs at Stage 5, rewrite it in WHAT framing: state the observable outcome the
system must produce, the constraints that bound it, and the directional file pointer; let Solutioning choose the
mechanism. Examples of the move:

- "Change line 42 of the auth module to X" → "Header parsing returns undefined when the proxy strips the field;
  affected: the auth module's header-resolution path (precise scope identified in Planning); acceptance: a request
  without the header returns 401, not 500."
- "Use the visitor pattern to walk the tree" → "Tree traversal must support pluggable per-node behavior so the
  linter, formatter, and resolver share traversal logic; acceptance: each caller subscribes to at least one node-type
  handler and the same tree is walked by all three without re-parsing."
- "Loop over the array, filter by status, then map to strings" → "The status panel must show only active items,
  formatted per the display schema; acceptance: inactive items are not rendered; rendered items match the schema
  field set."

The general test for over-definition: if the proposed change contains pseudocode, a named pattern without an
`[ASSUMPTION – CONFIRM]` marker, a line-level surgical directive, file-internal naming presented as a design choice,
or a specific algorithm description, T2 fails — rewrite using the formula above.
