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

## The two-tier type registry

The registry has two tiers. **Tier 1 — the methodology-resolved kind registry:**
when the intake scope resolves a methodology (the elicitation loop's
methodology-resolution step), the kind set is derived at use time per the
kind-derivation contract below. **Tier 2 — the invariant intake tier:** the three
template-keyed types below are always available — cross-cutting types (`bug`,
`observation`) at every tier, and the whole registry when no methodology resolves.

### The invariant tier

Three template-keyed types, keyed to the issue-form templates under
`.github/ISSUE_TEMPLATE/`.

| Type | Template (field source) | When to choose it |
|---|---|---|
| `improvement` | `.github/ISSUE_TEMPLATE/improvement.yml` | A proposal with a specific change you can name. Spans story / feature / initiative altitudes via field emphasis until a first-class story/initiative type ships. |
| `bug` | `.github/ISSUE_TEMPLATE/bug.yml` | A finding of the form "X is broken" rather than "we should add/change X". |
| `observation` | `.github/ISSUE_TEMPLATE/observation.yml` | A gap or drift where "what good looks like" fits in one sentence and the next action is "look at it / investigate" rather than a specific change. The placeholder tier. |

## Kind-derivation contract (the methodology-resolved tier)

The kind set is **derived at use time — never transcribed here** (the same
living-source discipline as the field-derivation contract above). It is derived
from **two independently-resolved selectors, not one**: the methodology `M`
resolved at the loop's methodology-resolution step, and the **work-item kit** `K`
resolved on its own configuration axis. Either may be unresolved; neither reads
the other. A kit is a pack that bears kinds while naming **no** archetype
(`role = "kit"`, `applies_to = "*"`, and every kind's
`methodology_projection.archetype = "*"`), so it contributes to the registry for
**every** `M`, including none.

Reading this contract as single-axis is the failure it is written to prevent: a
derivation parameterized on `M` alone silently drops a kit's kinds at whichever
rung it matches, with no error and no gate. Source precedence per invocation,
over the pair `(M, K)`:

1. **The operator's/project's own type-pack (K4) wins.** When the deployment
   declares kinds in a type-pack conforming to the meta-schema
   (`core/schemas/work-item-type-schema.md`), the declared kinds ARE the registry
   — a field-level merge over the shipped defaults, per the override model in
   `core/disciplines/work-organization-mapping-framework.md` § 4.1. **Which
   declared kinds are in scope depends on the pack's `role`, not on `M` alone:**
   a `role = "archetype"` pack is the registry for **its own archetype**, so it
   is in scope when its `applies_to` equals `M`; a `role = "kit"` pack is
   **archetype-neutral and joins on every `M`**, so it is in scope whenever that
   kit is the resolved `K` — including when no methodology resolved at all. Both
   forms are read at this rung and their kinds union; on a colliding `kind_id`
   the K4 pack's own declaration wins, which is what "K4 wins" means.

   > This rung is the higher-precedence of the two archetype-scoped joins in
   > this contract, and it expresses its scoping in prose (*"the registry for
   > their archetype"*) rather than in the `applies_to` token — which is why a
   > token census over this file finds only the rung below. Repairing rung 2
   > alone would leave the winning rung dropping a kit's kinds.
2. **Else the selected shipped packs (K1 defaults).** Read `kinds[]` from the
   **eligible** packs under `core/packs/`: each kind's `kind_id`,
   `display_name`, `fields` (core-inherit + `kind_specific`),
   `relationships.allowed_types`, and `methodology_projection` (the
   hierarchy-level anchor). **A pack is eligible when either limb holds** —
   (a) its `applies_to` equals `M` (the byte-identical archetype join), **OR**
   (b) its `applies_to` is `*` **AND** its `role` is `kit` and it is the
   resolved `K`. Both limbs are load-bearing: limb (b) without the `role`
   conjunct would also admit the shared base pack, which bears no kinds, and
   limb (b)'s `applies_to` conjunct alone would admit a `role = "archetype"`
   pack that claimed neutrality — a shape the grammar now forbids outright.
   Eligible packs' kinds **union**; on a colliding `kind_id` the kit wins over
   an archetype pack, per the composition order the pack corpus documents.
   Hybrid-Two `[A, B]` selects the union of both constituents' packs;
   Custom-with-base selects the base archetype's pack as the default the custom
   block overrides. The shipped pack set is **open** — never treat the present
   set as exhaustive.

   > **The eligibility predicate above is executable, and the executable form is
   > the oracle.** `python3 core/deploy/tools/check-work-hierarchy.py --resolve
   > <archetype> [--pack-root <dir>]` prints the eligible pack set and the kind
   > union, each row tagged by role. Read it rather than re-deriving this
   > paragraph by eye when the two disagree; this prose is the contract and that
   > command is how the contract is checked. It resolves eligibility and the
   > union only — *which* kit `K` a deployment selected is resolved on the
   > configuration axis, upstream of this rung.
3. **Else the Layer-2 map fallback (catalogued, pack-less archetypes).** An
   archetype catalogued in the work-organization-mapping-framework Layer-2 map
   with no shipped pack derives its kind set from the map's Work-Item-level
   name(s) facet, plus the Layer-3 best-practice default schema where one is
   shipped — flagged `[methodology-pack: none shipped for <archetype>; kinds
   derived from the Layer-2 map]`.
4. **Else the invariant tier (the floor).** No methodology resolved (or a
   Custom-null block that cannot supply a kind set): the invariant tier above,
   with the explicit unresolved caveat. This is the pre-methodology behavior,
   preserved.

Derived **per invocation, never cached across calls** — kinds are project-level
mutable. Cross-cutting intake types (`bug`, `observation`) remain reachable at
every rung: a defect under any archetype may land as the invariant `bug` when the
resolved pack(s) declare no defect kind.

## Kind ↔ label ↔ level binding (the intake binding table)

One binding table covers the kind set the desk types with and the labels the
intake path stamps — derived per invocation from the resolved registry:

| Binding column | Rule |
|---|---|
| Kind | a `kind_id` from the derivation above (or an invariant-tier type) |
| Label stamped at intake | `type:<kind_id>` for a resolved kind (the label the selected pack contributes via its `[[labels]]` facet, `projects_kind`-joined — one `type:*` label per issue per the label-taxonomy grammar); the template's `labels:` array for an invariant-tier type |
| Hierarchy level | the kind's `methodology_projection.general_level` (every finest-execution kind is Work-Item level; grouping kinds are Work-Item-level grouping labels, never new levels) |
| Relations the desk may propose | `BELONGS_TO` (placement) · `DEPENDS_ON` / `BLOCKS` (ordering) — intersected with the kind's declared `relationships.allowed_types` where the pack declares one; never an invented edge; never a grouping-of-groupings |
| Emission template | the type→template routing in force (the intake-style-guide's type→template rule): a resolved kind with a **dedicated kind form** under `.github/ISSUE_TEMPLATE/` emits there — the form's basename equals the `kind_id` and its `labels:` array stamps `type:<kind_id>` + `status: proposed` structurally at submission (the same `projects_kind` join the pack's `[[labels]]` rows declare); a resolved kind with **no dedicated form** emits on the interim `.github/ISSUE_TEMPLATE/improvement.yml` vehicle, with the kind carried as its `type:*` label per `references/output-contract.md` § Structured-field carriage; the invariant types keep their own templates |

> **Worked example (illustration of the derivation — not a shipped default; the
> desk renders whichever archetype the config resolves).** A scope resolving the
> Scrum archetype selects `core/packs/scrum/pack.toml`: kinds `epic` / `story` /
> `task` → labels `type:epic` / `type:story` / `type:task` → all Work-Item level
> (`epic` is a grouping kind — it contains stories as a backlog grouping, it is
> not a nestable level) → a story-altitude item lands as `story`, a task-altitude
> item as `task`, a defect as the invariant `bug`; an epic-to-epic containment is
> never proposed.
> Emission: the `epic` and `story` kinds carry dedicated forms (`epic.yml` / `story.yml` —
> basename = kind_id; the forms stamp `type:epic` / `type:story`); `task` has no dedicated
> form and emits on the interim `improvement.yml` vehicle with `type:task` carried by the
> intake path.

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
Under a resolved methodology, each altitude projects onto the derived registry's
kind at that level (a container-altitude item lands as the resolved grouping
kind; a story-altitude item as the resolved commit-unit kind; defects on the
resolved defect kind or the invariant `bug`); the table above is the invariant
floor that projection overlays.

## The platform type registry (live coupling)

The declarative work-item type system this registry couples to is **shipped**: the
type-pack meta-schema (`core/schemas/work-item-type-schema.md`) is the grammar —
a work-item **kind** declared as data (`kind_id` + `display_name` +
`methodology_projection` + `fields` + versioned `criteria` + `relationships` +
`lifecycle_behavior`), projecting onto the general hierarchy via the
work-organization mapping framework's Layer-2 map — and the shipped methodology
packs under `core/packs/` are its first instances. The kind-derivation contract
above IS the coupling in operation: a deployment's own type-pack (K4) overrides;
the selected shipped pack(s) are the K1 defaults; the registry is read **per
invocation**, never cached across calls (kinds are project-level mutable).

The field-derivation contract is unaffected — it always derives the required-field
set from whatever source is current (the issue-form `.yml` templates for the
invariant tier; a resolved kind's `fields.kind_specific[]` when the registry
derives from a pack or type-pack). The architectural boundary and the downstream handoff contract this skill
establishes are governed by the intake-front-door-architectural-boundary ADR (see
§ Provenance) and are independent of the type-registry shape — the *registry* is
repointed (an implementation detail), the front-door boundary is not.

## Provenance

This block is the single designated home for issue and ADR identifiers cited by this
file.

- Architectural boundary + downstream handoff decision record: ADR-016 (intake front door architectural boundary).
- Declarative work-item type system (shipped; the meta-schema this registry derives from): #409.
- Methodology-pack composing unit + selection seam (packs at `core/packs/`, selected per the resolved methodology): ADR-069. Pack composition grammar (the `[[labels]]` facet, `projects_kind` join): ADR-070.
