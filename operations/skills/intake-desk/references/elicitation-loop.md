# Elicitation Loop

The mechanics of Mode A (the four-phase elicitation loop), the phase gates, the
type-landing criteria, the altitude model, and the 5-test rule that Mode B applies
and Mode A enforces live. Grounded in the IIBA BABOK Guide v3 Elicitation and
Collaboration knowledge area (Prepare → Conduct → Confirm) and its Requirements
Classification Schema (business / stakeholder / solution / transition requirement
levels). The technique cards the loop draws on live in
`references/technique-library.md`; the type registry and the field-derivation
contract live in `references/type-map.md`; the emission contract lives in
`references/output-contract.md`.

## Phase gates (binary, agent-executable)

Each phase boundary is a gate the agent evaluates as a binary checklist before
advancing — written so the loop runs consistently, not "use judgment." Advance
only when the checklist passes; otherwise take the "if not met" action.

| From → To | Gate name | Advance ONLY when (binary checklist) | If not met |
|---|---|---|---|
| Phase 1 → 2 | **Altitude gate** | (a) An altitude is named (run-the-business vs change-the-business, then the specific level); (b) it is recorded as confirmed-by-user OR flagged `[ASSUMPTION – CONFIRM]` (never silently assumed). | Ask one altitude-disambiguating question (not a battery), or record the assumption and proceed. |
| Phase 2 → 3 | **Type-landing gate** | All of: (a) one type proposed from `references/type-map.md` with a one-line "why this type" rationale; (b) the type-landing criteria (in `references/type-map.md`) pass for that type; (c) the user has not contradicted it; (d) the type is held provisional (re-route allowed through Phase 3). | Re-run type selection; if genuinely ambiguous, name the contenders and record the chosen one as `[ASSUMPTION – CONFIRM]` for triage. |
| Phase 3 → 4 | **Clarity gate** (the stop condition) | The 5-test (T1–T5) passes for this type at this altitude AND every unresolved point is captured as either a deferred `[ASSUMPTION – CONFIRM]` or an owned handoff item — not left silent. | Continue eliciting the specific failing test only; do not open new lines past intake-ready (over-elicitation guard). |
| Phase 4 → emit | **Confirm gate** | The user returns an explicit binary approval via AskUserQuestion on the rendered item. | Do not emit. Revise per the user's edit and re-present, or fall back to the copy/paste body. |

## The altitude model (assume → confirm → carry)

Users enter intake at different altitudes. Meet them where they are — by proposing
an assumed altitude and confirming it, not by silently classifying. Folds the
run-the-business vs change-the-business entry cut and the unresolved-altitude carry.

| Step | Behavior |
|---|---|
| **Entry self-ID** | Open with run-the-business vs change-the-business — the coarse cut users generally can self-identify. Run-the-business ≈ operational / keep-the-lights-on; change-the-business ≈ initiatives / features / improvements. |
| **Assumed altitude** | From the entry cut plus the user's framing, propose an assumed specific altitude (initiative / story / task / bug) and state it back. The proposal is an assumption, explicitly labeled, not a silent classification. Example: "this reads like change-the-business work — a new capability — at roughly an initiative level; does that match?" |
| **Confirm** | Ask the user to confirm or correct the assumed altitude. This is a good AskUserQuestion candidate when the choice is discrete. |
| **Unresolved → flagged assumption** | If the user genuinely does not know and the agent cannot align, the altitude remains `[ASSUMPTION – CONFIRM]` in the item, carried to a human reviewer at triage. The loop proceeds at the best-guess altitude rather than stalling. |
| **Sort to container** | With user confirmation, sort the item to its place in the intake hierarchy (the altitude → type-emphasis table in `references/type-map.md`). |

Altitude maps to the BABOK Requirements Classification Schema: business requirement
(initiative / portfolio) → stakeholder requirement (feature / story) → solution
requirement (task / bug) → transition requirement (migration / rollout). The
altitude → type-emphasis table lives in `references/type-map.md`.

## "Over-defined" is relative to altitude

Over-definition differs by altitude. The clarity gate reads this rule to decide what
counts as "beyond intake-ready":

- **Initiative / business altitude:** over-defined = the item commits child-level
  mechanism or task breakdown (the children belong in later slicing); intake-ready =
  outcomes + domain + a callout that decomposition follows.
- **Story / stakeholder altitude:** over-defined = the item commits an implementation
  mechanism (algorithm, data structure, file-internal pattern) at intake;
  intake-ready = acceptance criteria + value + WHAT-framed proposed change.
- **Task / solution altitude (including bug):** more detail is expected — exact
  reproduction, environment, affected files; over-defined here means prescribing the
  fix's internal design (the HOW), not capturing reproduction precision.

The single test the agent applies: **over-definition = detail that belongs to a later
stage at this altitude** (slicing for initiatives; Solutioning for stories and tasks),
captured as if it were intake's job. This is symmetric to under-definition; both are
quality failures the 5-test catches.

## The four-phase loop (Mode A)

### Phase 1 — Meet at altitude (BABOK Prepare for Elicitation, adapted)

Detect the user's framing and propose an assumed altitude per the altitude model
above — open with run-the-business vs change-the-business, propose a specific
altitude, state it back, and confirm. If the user cannot align, carry the altitude
as a flagged `[ASSUMPTION – CONFIRM]` to triage; do not stall. Pass the altitude
gate before advancing.

### Phase 2 — Identify type and place in the hierarchy (BABOK Conduct, classification step)

Propose the work-item type from the registry in `references/type-map.md` and its
place in the intake hierarchy. State the proposed type and why ("this is a `bug`
because it describes broken behavior, not a missing capability"). Evaluate the
type-landing criteria (in `references/type-map.md`) for that type before advancing.

**One work item per request.** Capture the idea at its right altitude and create
exactly one item — do not auto-decompose. When the idea is a container (an
initiative or epic-equivalent), the candidate child work (discovery / research /
integration / development / testing / rollout, etc.) is noted in the body as a
decomposition callout for later agents to validate and slice. Slicing rules already
exist elsewhere in the platform; intake surfaces the breakdown, it does not perform
it. (Worked example: a "customer self-service pickup tool" stays one item; the
discovery / research / integration / dev / testing breakdown is a body callout for
later slicing, not N child issues.) Get user confirmation on the container framing.

**Re-routing rule.** Treat the type as provisional through Phase 3. As elicitation
develops, if the user's answers reclassify the item, re-route explicitly and say
why — do not lock the first guess. Common re-routes:

- A "bug" that is actually a missing capability → re-route to `improvement`.
- A "task" that is actually three unrelated changes → still ONE improvement at the
  container altitude with the split noted in the body for later slicing (T1 informs
  the callout); do not auto-split into separate items at intake.
- A thin item that cannot reach intake-ready → route to `observation` (the
  placeholder tier).

The re-route is the correct behavior, not a failure. Announce it in one line and
reset to the new type's field set.

### Phase 3 — Elicit type/level fields + re-elicit unclear (BABOK Conduct, the techniques)

Ask for the field set THIS type at THIS altitude requires, per
`references/type-map.md` (which derives the required fields, dropdown options, and
default labels at use time from each type's `.github/ISSUE_TEMPLATE/<type>.yml` —
never a duplicated inline list), using the domain-adaptive technique selector in
`references/technique-library.md`. Apply the 5-test rule live (see below) so the
emerging item is neither under- nor over-defined for its altitude.

**Re-elicit any unclear item once, following the define process.** If a captured
field is vague, ambiguous, or fails a test, loop back on that specific field and
re-elicit it — do not paper over it or carry a vibe forward. An assumption is the
fallback when the user genuinely cannot resolve the field now, not the first resort.

**Enforce the WHAT/HOW boundary live.** Intake commits WHAT (problem, constraints,
observable outcome, acceptance criteria); HOW (algorithm, data structure,
file-internal pattern) is Stage 5 Solutioning's job. If the user prescribes a
mechanism, record it as `[ASSUMPTION – CONFIRM] mechanism deferred to Stage 5`
rather than baking it into the item. The signal of an over-specified contribution
is pseudocode, a named implementation pattern, a line-level surgical directive, or
an algorithm-step description — capture the underlying need, defer the mechanism.

**Assumptions become owned handoff items (see § Assumptions-as-owned-handoff-items).**
Each `[ASSUMPTION – CONFIRM]` the loop emits is tagged with the stage that owns it
and lands in the body for progressive downstream closure — not left as a loose
annotation, and never fabricated or silently dropped.

#### Clarity-based exit (no hard follow-up limit)

The exit criterion is **the 5-test passing for the type at this altitude** (the
clarity gate), not a question count. There is no hard "Max 5 questions" cap as an
exit here — that platform guardrail survives only as cadence discipline (small
batches, sharp questions, echo back what was captured). Use the go-deeper-vs-stop
guidance:

- **Go deeper when:** a required field is still missing or vague; an acceptance
  criterion is not yet a verifiable predicate; the type is still genuinely
  ambiguous; or an `[ASSUMPTION – CONFIRM]` could be cheaply resolved by one more
  question and resolving it materially de-risks downstream rework.
- **Stop when:** the 5-test passes for the type/altitude AND remaining unknowns are
  legitimately downstream (deferred-with-marker or owned handoff items).

The balance: avoid over-determinate rigidity (do not interrogate to exhaustion) while
capturing enough that downstream rework is not forced (some work legitimately needs
more detail). The altitude-relative over-definition rule above is what makes this
pathing clear.

### Phase 4 — Confirm and emit (BABOK Confirm Elicitation Results)

Render the item body against the identified type's field set (derived from the
template per `references/type-map.md`), including the owned-assumption block. Run
the 5-test as the clarity gate. Present the rendered body plus the 5-test verdict.
**Obtain an explicit binary approval via AskUserQuestion** (the confirm gate; see
`references/output-contract.md`). Only on approval, emit per
`references/output-contract.md`. For a container, the decomposition callout is shown
in the rendered body before approval — never auto-created as child items.

## Assumptions-as-owned-handoff-items

Every `[ASSUMPTION – CONFIRM]` the desk emits is a typed, owned handoff item in the
body, not a loose annotation — captured for progressive closure by the right
downstream agent.

- **Shape.** Render each assumption as a body line of the form:
  `[ASSUMPTION – CONFIRM] <the assumption> — owner: <stage> — to close: <what evidence/decision resolves it>`
  where `<stage>` is one of the named downstream owners: **root-cause / research /
  dependency / design / architecture / slicing / estimation / resourcing**, or
  **triage** for an unresolved altitude.
- **Where they land.** In the item body — in the type's natural field (e.g. an
  improvement's Affected Files carries `[ASSUMPTION – CONFIRM] TBD — identified in
  Planning`; a deferred mechanism carries `[ASSUMPTION – CONFIRM] mechanism deferred
  to Stage 5`) and/or in a dedicated **"Open assumptions (owned for downstream
  closure)"** block when there are several. This keeps the assumptions visible and
  routable rather than buried.
- **Re-elicit-unclear first.** Before emitting an assumption, re-elicit the unclear
  item once (per the define process). An assumption is the fallback when the user
  genuinely cannot resolve it now, not the first resort.
- **The desk does NOT investigate-or-close them.** Intake's job is to emit
  well-formed owned assumptions; the mechanics of who picks them up and how they
  close are a separate downstream convention, out of this skill's scope. The
  `references/output-contract.md` states this boundary.

## The 5-test rule (T1–T5)

Apply these five binary tests at authoring time. Mode B runs them once against a
user-supplied draft; Mode A re-runs them after each elicited field and treats them
as the clarity-gate stop condition. If all five pass for the type/altitude →
intake-ready. If any fails → re-elicit that field, defer the relevant part to Stage 5,
note a container split in the body, or route to `observation` per the failure routing
below.

| # | Test | Pass if |
|---|---|---|
| T1 | Atomic? Could this be reverted by a single revert — one cohesive change? | Yes. If two or more unrelated changes, keep ONE item at the container altitude and note the candidate split in the body for later slicing (do not auto-split at intake). |
| T2 | Determinate design? Is there a single reasonable implementation, or is the design boundary deferred to Solutioning explicitly? | Single, OR the design is deferred with an explicit `[ASSUMPTION – CONFIRM]`. If the author is secretly assuming a design without naming it, fail. |
| T3 | Verifiable AC? Can a fresh agent check each acceptance-criterion predicate by reading a file, running a command, or inspecting an output? | Yes — each AC is a predicate. If any AC is a vibe ("works correctly", "improves flow"), fail. |
| T4 | File pointer? Does the proposed change name at least one specific file/section, OR explicitly say `[ASSUMPTION – CONFIRM] TBD — identified in Planning`? | Yes — directional or deferred-with-marker, not silent. |
| T5 | Risk surfaced? Are the known risks, cross-issue conflicts, or concurrent-work conflicts named (even a one-liner), OR an explicit "None identified"? | Yes — risks named if they exist, or an explicit declaration. Silent = fail. |

### Failure routing

- T1 fails → keep ONE item at the container altitude and render the candidate
  breakdown as a decomposition callout in the body for later slicing; the desk does
  not auto-create child items.
- T2 fails → do not commit a design at intake; mark any design assumption
  `[ASSUMPTION – CONFIRM] mechanism deferred to Stage 5` (an owned assumption). The
  item is still intake-ready; Solutioning will activate.
- T3, T4, or T5 fails and the user cannot fix it after one re-elicitation → route to
  `observation` (the lightweight placeholder tier); explicitly stage the finding as
  a placeholder. Triage promotes it to `improvement` later when enough context
  exists. This is the correct route — never force a thin `improvement` past a failing
  test.

### The stop condition (over-elicitation guard)

The 5-test is the stop condition, not a starting point for more questions. The moment
all five pass for the current type and altitude and remaining unknowns are downstream
(deferred-with-marker or owned handoff items), move to Phase 4 (Confirm and emit).
After they pass, offer once ("anything else to add?"), then emit. Continuing to elicit
"nice to have" detail past intake-ready produces an over-defined item and a fatigued
user — apply the altitude-relative over-definition rule to recognize it.

## WHAT-framing rewrites (used by Mode B and by Phase 3)

When an item commits a HOW that belongs at Stage 5, rewrite it in WHAT framing: state
the observable outcome the system must produce, the constraints that bound it, and
the directional file pointer; let Solutioning choose the mechanism. Examples of the
move:

- "Change line 42 of the auth module to X" → "Header parsing returns undefined when
  the proxy strips the field; affected: the auth module's header-resolution path
  (precise scope identified in Planning); acceptance: a request without the header
  returns 401, not 500."
- "Use the visitor pattern to walk the tree" → "Tree traversal must support pluggable
  per-node behavior so the linter, formatter, and resolver share traversal logic;
  acceptance: each caller subscribes to at least one node-type handler and the same
  tree is walked by all three without re-parsing."
- "Loop over the array, filter by status, then map to strings" → "The status panel
  must show only active items, formatted per the display schema; acceptance: inactive
  items are not rendered; rendered items match the schema field set."

The general test for over-definition: if the proposed change contains pseudocode, a
named pattern without an `[ASSUMPTION – CONFIRM]` marker, a line-level surgical
directive, file-internal naming presented as a design choice, or a specific algorithm
description, T2 fails — rewrite using the formula above and defer the mechanism as an
owned assumption.
