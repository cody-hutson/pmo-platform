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
| Phase 2 → 3 | **Type-landing gate** | All of: (a) one type proposed from `references/type-map.md` with a one-line "why this type" rationale; (b) the type-landing criteria (in `references/type-map.md`) pass for that type; (c) the user has not contradicted it; (d) the type is held provisional (re-route allowed through Phase 3); (e) **for a container altitude only** — the container-altitude existing-owner scan (see § Phase 2) has run and any plausible existing owner has been surfaced to the user (leaf altitudes — story / task / bug: N/A, they advance directly); (f) the methodology-resolution step (§ Phase 2) has run for this invocation and the proposed type is a member of the derived kind registry — a resolved-methodology kind or an invariant-tier type; an unresolved methodology is carried as an explicit caveat, never a silent archetype default. | Re-run type selection; if genuinely ambiguous, name the contenders and record the chosen one as `[ASSUMPTION – CONFIRM]` for triage. If a container's existing-owner scan surfaced a match and the user chose enrich, do not advance to Phase 3 — deliver the comment-ready enrichment block for the existing owner instead. |
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

**Methodology-resolution step (runs first, before the type proposal).** Resolve the
active methodology for the intake scope and derive this invocation's kind registry:

1. **Scope.** The intake scope is the active project context when one is loaded
   (its `PROJECT.md` is the project-rung surface); otherwise the deployment scope
   (the operator-config default). The Phase-1 domain cut has already routed away
   project-operational items; this step fires for the work items the desk owns.
2. **Resolve the value — cite the platform resolver, never re-implement it.** The
   effective value of a methodology field for a scope resolves via the 5-rung
   cascade in `core/governance/OPERATIONS.md` § Platform-Config Resolution Protocol
   (Rule 1: global default → portfolio → program → project → individual,
   most-specific wins; Rule 2 default-fallback). **Field order: read
   `operational_methodology` first — the per-space operations field (intake is an
   operations-space act; a value set at any rung wins over `delivery_approach` at
   any rung). When no rung sets it, fall back to `delivery_approach`** (project-rung
   value: the `PROJECT.md` field per the Methodology Awareness Protocol; rung-1
   floor: `operator.toml [methodology].default_delivery_approach`).
   `release_methodology` is never read at intake — it governs the release
   pipeline's own delivery flow downstream, not work-item vocabulary at the desk.
3. **Branch per the skill-consumption pattern** (`methodology-parameterization-v1.md`
   § 5 — cited, not restated): CASE 1 single archetype · CASE 1-ARRAY Hybrid-Two
   `[A, B]` (the union of both constituents' registries) · CASE 2 Custom-with-base
   (the base archetype's registry as the default the block overrides) · CASE 3
   Custom-null (the block directly; when it cannot supply a kind set, proceed
   methodology-agnostic WITH an explicit caveat — never silently default to any
   archetype).
4. **Derive the kind registry** per the kind-derivation contract in
   `references/type-map.md` (operator type-pack override → selected methodology
   pack(s) → Layer-2 map fallback → the invariant tier; the derivation order lives
   there, not here).
5. **Resolve once per invocation; never cache across invocations** — the fields are
   project-level mutable (Methodology Awareness Protocol Rule 1).
6. **Unresolved is a caveat, not a default.** When neither field resolves at any
   rung, use the documented consumer fallback: the methodology-neutral invariant
   registry, logging `[platform-config: methodology unresolved; using the neutral
   intake registry]` in the run output.

This step is the interactive loop's resolution surface (Modes A and B consume it;
the ambient path keeps its own narrower implied-type contract).

**Place and relate per the mapping framework (the § 4.2 consumer contract).** With
the registry derived, Phase 2 executes the place-and-relate procedure of
`core/disciplines/work-organization-mapping-framework.md` § 4.2 (cited, not
restated): resolve the proposed kind to its hierarchy level via its
`methodology_projection` (pack kinds) or the Layer-2 row (map-derived kinds) —
under every methodology the finest execution unit lands at the **Work Item level**;
intermediate names (an Epic-equivalent, a WBS-summary) are **grouping kinds at the
Work-Item level, never new hierarchy levels**. **Place** = the item attaches to its
Milestone / Workstream parent via `BELONGS_TO` (the rollup edge). **Relate** =
propose edges only from the built relationship vocabulary — `BELONGS_TO` for
containment, `DEPENDS_ON` / `BLOCKS` for ordering — and, when the resolved kind
declares `relationships.allowed_types`, only from that declared subset. Never
invent an edge type; never propose a grouping-of-groupings (an Epic-equivalent
contained by another Epic-equivalent). **Caveat-on-gap:** a kind that cannot be
mapped and has no parent hint is placed at Work-Item level under the active
Milestone and flagged as an inferred placement — never silently mis-leveled, never
a fabricated parent (§ 4.2 step 5).

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

**Container-altitude existing-owner scan (containers only).** Before advancing a
**new container** (an initiative / epic-equivalent — the Initiative/portfolio
altitude that maps to `improvement` with a child-decomposition callout per
`references/type-map.md`) past the type-landing gate, scan the work tracker for an
existing owner of the same capability surface — a scoped search on the container's
key terms (GitHub MVP: `gh issue list --search "<container key terms>" --state open`,
and check the milestones for already-owned scope). This scan is **altitude-gated to
containers**: story-, task-, and bug-altitude items do **not** run it and advance
directly to Phase 3 (the between-clarity-and-confirm tracker scan in SKILL.md failure
mode "Work item filed without consulting existing tracker state" is their duplicate
backstop) — the container scan fires earlier, at container-framing time, because a
duplicated initiative strands a whole workstream and is the costliest duplicate to
unwind after its fields are elicited. On a plausible match, surface it as a single
question and **re-route to enrichment** ("possible existing owner: an open
initiative / epic with matching scope — frame a new container anyway / enrich the
existing owner"); on "enrich," stop the container loop and deliver the captured
framing as a comment-ready block for the existing owner rather than proceeding to
elicit a duplicate container's fields. This applies the CLAUDE.md **Pre-creation
governance check** issue-creation duplicate-discipline (enrich an existing owner
rather than restate its scope in a parallel issue) at the container gate. The scan
running and any match being surfaced is a **hard condition** on the container's
type-landing advance; the enrich-vs-new **decision** stays the user's.

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
`references/technique-library.md`. For a methodology-resolved kind, compose the
field ask from the kind's declared field set (the inherited Work-Item core plus the
kind's `kind_specific` fields, per the kind-derivation contract in
`references/type-map.md`); the emission template's required structured fields still
ride per the field-derivation contract, and the 5-test remains the invariant
clarity gate either way. Apply the 5-test rule live (see below) so the
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

**Registry conformance rides the 5-test when a methodology resolves.** Mode B's
readiness check and Mode A's clarity gate also verify the item's type is a member
of the derived kind registry; a well-formed draft carrying an off-registry type
returns the re-type recommendation (the resolved kind at the draft's altitude)
alongside the 5-test verdict.

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
