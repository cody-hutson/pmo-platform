# Type Map (the work-item type registry)

This file is the intake-desk type registry: it maps each work-item type to its
issue-template path, its altitude-emphasis, and its type-landing criteria. The
elicitation loop reads the type set, the hierarchy, and the landing criteria from
here — never inline in SKILL.md.

**The `.yml` templates are the living source of truth for the field set.** This
file does NOT restate the per-type field lists. Each `.github/ISSUE_TEMPLATE/<type>.yml`
already carries stable, machine-readable structure — every field has a `type:`
(`input` / `textarea` / `dropdown`), an `id:`, a `label:`, a `validations.required:`
flag, and the form carries a top-level `labels:` array. The required field set, the
dropdown options, and the default labels are declared there, not here.

## Field-derivation contract

The required-field set for each type is **derived at use time** from its
`.github/ISSUE_TEMPLATE/<type>.yml`: read the form's fields where
`validations.required: true`, plus the dropdown `options:` and the top-level
`labels:`. Do NOT transcribe the field list into this file — it goes stale on every
template edit. **This file maps type → template path + altitude-emphasis + landing
criteria; the template owns the fields.**

In practice the desk is an LLM agent, so "derive the required fields by reading
`improvement.yml`'s `required: true` fields" is an instruction it executes by reading
the file at use time — there is no parser to build. At render time (Phase 4), read the
matching template, capture every `required: true` field (or mark it `[ASSUMPTION –
CONFIRM]` for a deferrable field, or "None — …" where the template allows it), and read
the template's `labels:` array for the default label set. The dropdown carriage
mechanics (how a freeform-body create carries a required dropdown value) live in
`references/output-contract.md`.

## The current work-item types

Three types. Keyed to the issue-form templates under `.github/ISSUE_TEMPLATE/`.

| Type | Template (field source) | When to choose it |
|---|---|---|
| `improvement` | `.github/ISSUE_TEMPLATE/improvement.yml` | A proposal with a specific change you can name. Spans story / feature / initiative altitudes via field emphasis until a first-class story/initiative type ships. |
| `bug` | `.github/ISSUE_TEMPLATE/bug.yml` | A finding of the form "X is broken" rather than "we should add/change X". |
| `observation` | `.github/ISSUE_TEMPLATE/observation.yml` | A gap or drift where "what good looks like" fits in one sentence and the next action is "look at it / investigate" rather than a specific change. The placeholder tier. |

## Why there is no `adr` type

No `adr` type — authoring an ADR is an architecture act, not intake. The full
rationale (intake authors a typed work item; architecture authors ADRs — disjoint
verbs) lives with the component boundary in the intake-front-door-architectural-boundary
ADR (see § Provenance).

## Type-landing criteria ("have we landed on the right type?")

A binary, per-type checklist the Phase 2 → 3 type-landing gate evaluates. This is
what makes "landed on the right type" agent-executable rather than vibes. Hold the
type provisional through Phase 3; re-route if the evidence shifts.

| Candidate type | Landed when ALL are true | Common mis-land (re-route to) |
|---|---|---|
| **bug** | (a) Describes broken existing behavior (not a missing capability); (b) there is an expected vs actual delta; (c) a reproduction path exists or can be narrated. | A "bug" that is really a never-supported capability → **improvement**. |
| **improvement** | (a) Proposes a named change/addition (capability, protocol, structure, doc, tracker, routing); (b) framed as WHAT/outcome, not a mechanism; (c) altitude-field-emphasis identified (story → AC+value; initiative → outcomes+domain+child-callout). | An item with no namable change and a one-sentence "what good looks like" → **observation**. An improvement that is really three unrelated changes → still ONE improvement at the container altitude with the split noted in the body, not auto-split. |
| **observation** | (a) A gap/drift/friction is stated; (b) "what good looks like" fits in one sentence; (c) the next action is "look at it / investigate," not a specific change the user can name now. | An observation the user can turn into a named change after one or two questions → **improvement**. |

## The intake hierarchy (altitude → type emphasis)

Until a first-class story/initiative type ships, both story-equivalent and
initiative-equivalent items map to `improvement`; the desk differentiates by
altitude-driven field emphasis and records the intended granularity in the body.

| Altitude (BABOK requirement level) | Run / Change | Type | Field emphasis |
|---|---|---|---|
| Initiative / portfolio (business requirement) | Change | `improvement` | Outcomes, domain context, **child-decomposition callout in body** |
| Feature / story (stakeholder requirement) | Change | `improvement` | Acceptance criteria, value (Proposed Change as an outcome) |
| Task / small change (solution requirement) | Change or Run | `improvement` | Atomic change, named files, verifiable AC |
| Broken behavior (solution requirement) | Run | `bug` | Reproduction, environment |
| Migration / rollout (transition requirement) | Change | `improvement` | Transition steps, cutover, rollback |
| Thin / not-yet-authorable | either | `observation` | What is missing, what good looks like (one sentence) |

Story vs initiative differentiate by altitude-driven field emphasis within
`improvement` (story → AC + value; initiative → outcomes + domain + child-callout)
until a first-class type ships. The candidate child work of a container is a body
decomposition callout for later slicing — never auto-created as child items.

## Enabled type-pack resolution (the lock-in seam)

Distinct from the **intake form** chosen in § The current work-item types above
(`improvement` / `bug` / `observation` — what the desk elicits), the downstream
work-item `type:` **label** (the Agile kind: `story` / `task` / `epic` / …) is assigned
at Triage by resolving the deployment's **enabled type-pack** — never hard-coded in this
corpus file (the kind *values* are operator-local K4 config, not public package content). Resolution follows the
work-organization mapping framework's Layer-4 (K4, operator-local) precedence:

1. Read the deployment's `delivery_approach` (operator config / `PROJECT.md`). If it
   enables a type-pack, that pack is the source of the work-item `type:` set, the
   **intake-form → `type:` mapping**, and the per-kind landing criteria — read **per
   invocation** (kinds are deployment-mutable), never cached across calls.
2. If no pack is enabled, only the canonical intake categories below apply
   (`improvement` / `bug` / `observation`) and no work-item `type:` is assigned.

This is the seam that keeps new arrivals **born-typed**: when a pack is enabled, every
triaged item lands with its work-item `type:` from the pack's mapping, so the backlog
does not drift untyped. The mechanism is methodology-neutral — the Agile/Scrum (or any)
kind values live in the operator-local pack (per the intake front-door architectural
boundary, see § Provenance); this file supplies only the resolution rule. The type
registry portion this couples to is the platform's declarative work-item type system;
see § Forward-coupling.

## Forward-coupling (the platform type registry)

The platform's declarative work-item type system is the registry this file's type
portion couples to. Its grammar — the type-pack meta-schema — is the work-item
type-pack meta-schema doc (`core/schemas/work-item-type-schema.md`), in which a
work-item **kind** is declared as data (a `kind_id` + `display_name` +
`methodology_projection` + `fields` + versioned `criteria` + `relationships` +
`lifecycle_behavior`), projecting onto the general hierarchy via the
work-organization mapping framework's Layer-2 map. When a deployment declares its
kinds in a type-pack, the **type registry portion of this file** (the type set,
their templates, the when-to-choose cues, and the landing criteria) is sourced from
that pack rather than restated here — read **per invocation**, never cached across
calls (kinds are project-level mutable). The meta-schema's grammar, EAD
materialization, the custom-kind escape hatch, and the registry-read contract are
the platform mechanism; this file is the prototyped intake consumer of it.

The field-derivation contract is unaffected — it always derives the required-field
set from whatever source is current (the issue-form `.yml` templates today; a
declared kind's `fields.kind_specific[]` once a deployment's type-pack supplies
them). The architectural boundary and the downstream handoff contract this skill
establishes are governed by the intake-front-door-architectural-boundary ADR (see
§ Provenance) and are independent of the type-registry shape — the *registry* is
repointed (an implementation detail), the front-door boundary is not.

## Provenance

This block is the single designated home for issue and ADR identifiers cited by this
file.

- Architectural boundary + downstream handoff decision record: ADR-016 (intake front door architectural boundary).
- Forward-coupled work-item type system (later repoints the type registry): #409.
