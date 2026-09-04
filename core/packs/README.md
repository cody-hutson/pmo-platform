---
title: Type Packs (core/packs/)
purpose: README for core/packs/ — defines the type-pack unit in its three roles (base, archetype, kit), the work-item kinds / label contributions / gates each carries, and the layout, inheritance and composition model.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Type Packs (`core/packs/`)

A **type pack** is the plug-and-play unit that bundles work-item kinds, label
contributions and gates as one selectable manifest. It comes in three forms, and the
form is declared by the pack's own `role` rather than inferred from what it contains:
a **base** pack (the shared, non-kind-bearing root), a **methodology pack** (`role =
"archetype"` — one delivery-approach archetype's kinds, criteria and gates), and a
**work-item kit** (`role = "kit"` — a kind set a deployment selects *independently of
the methodology it runs*, naming no archetype at all).

Packs ship as **best-practice defaults** (codified, universal knowledge); a deployment
**selects** packs via operator configuration and **overrides** them per project. A
project's own declared kinds are instance configuration and are never authored into
this tracked corpus. The grammar every pack conforms to is the work-item type-pack
meta-schema; the kit role, its neutrality mechanism and its composition position are
decided in [ADR-180](../ADRs/ADR-180-work-item-kit-first-class-unit.md).

## Layout

One directory per pack, each holding a single `pack.toml`. Three forms live here,
one per `role`:

- `_common/pack.toml` — the shared **base** pack (`role = "base"`): archetype-invariant
  label-group contributions every kind-bearing pack inherits. It carries no work-item
  kinds and no work-status machine.
- `<archetype>/pack.toml` — one **methodology pack** per archetype (for example
  `scrum`, `kanban`), each `role = "archetype"`, declaring `extends = "_common"` and
  carrying only its deltas: its kinds, its criteria, its gates.
- `<kit>/pack.toml` — a **work-item kit** (`role = "kit"`), archetype-neutral
  (`applies_to = "*"`), discriminated by `kit_class`, carrying the kinds its class
  requires and MAY declare `extends = "_common"`. A kit names no archetype at any
  level: neither its header nor any of its kinds. None ships in this corpus today —
  a kit is deployment data, and this row states the layout an authoring deployment
  follows.

**Test fixtures never live here.** The licensed-kind reader unions the kinds declared
by *every* directory under `core/packs/` that holds a `pack.toml` — no allowlist, no
naming filter, no underscore-prefix skip — so a fixture placed here would be absorbed
into the live gate's kind vocabulary. Fixture packs live under
`core/deploy/tests/fixtures/packs/` and are read through the conformance tool's
explicit pack-root argument instead. That reader, and every other consumer of what a
pack declares, is enumerated in
[`../references/reference/work-item-type-consumer-map.md`](../references/reference/work-item-type-consumer-map.md).

## The `role` and `extends` model

A pack declares a `role`, and the role decides three things: whether the pack bears
kinds, what its `applies_to` value must be, and where it sits in the composition
order. There are three roles.

This section is also the file's single definition of the **composition order** — the
sequence in which packs merge and the rule that decides a collision. It is stated once,
below, and cited rather than restated wherever else it is needed.

| `role` | `applies_to` | Bears kinds? | May declare `extends`? | May be an `extends` target? |
|---|---|---|---|---|
| `base` | MUST be `*` | **No** — forbidden | No — a base is the inheritance root | Yes (the only role that may) |
| `archetype` *(the default when omitted)* | MUST name an archetype; MUST NOT be `*` | Yes — at least one | Yes, naming a `base` pack | No |
| `kit` | MUST be `*` | Yes — selected by `kit_class` | Yes, naming a `base` pack | No |

**Kind-bearing follows from the role, never from naming an archetype.** That sentence
is the whole decoupling: before the kit role existed, declaring kinds and naming a
methodology were the same act, so a kind set that spanned methodologies was not
expressible. `extends` is inheritance, not composition — a pack that extends the base
declares only what differs from it, the same delta-inheritance contract the type
grammar uses for custom kinds and the project schema uses for custom methodologies,
lifted one altitude from kind to pack.

`role` is **not a closed set**. It has just gone from two members to three, which is
the proof; a consumer that branches exhaustively on role values will be wrong at the
next widening.

### The kit, as a unit

A **work-item kit** is a pack that bears kinds without naming an archetype. Four
properties define it, and they are non-severable — a pack holding three of them is not
a kit:

1. **`role = "kit"`** — the discriminator. A kit is a third value of the existing role
   field, not a new unit, not a facet nested inside a methodology pack, and not a
   second grammar.
2. **`applies_to = "*"`** — methodology-neutral at the pack level.
3. **Neutral at the kind level too.** Each of a kit's kinds sets
   `methodology_projection.archetype = "*"`. This is the property that carries the
   capability: a pack that were neutral only in its header, while every one of its
   kinds still named an archetype, would validate cleanly and deliver nothing. `"*"`
   declares the *absence* of a methodology-map row rather than naming one, so a kit's
   kinds assert their level directly and anchor into no map row.
4. **`kit_class`** — which facet the kit must carry. Its v1 value is `work-item`,
   whose facet is the kind set. The domain is **open**: a future `field` or `workflow`
   kit registers a class and the requiredness rule for its own facet, with no role
   change and no re-opening of the kinds rule. An unrecognized class is reported as a
   caveat naming the value, never as an error.

A kit types work at the Work-Item level. It does not introduce, rename or re-tier any
organizational level — every kind's `base` is the constant `Work Item`, and the
container tiers belong to the frozen entity model.

### Composition order

The composition order is fixed by pack **role**, and this is the file's single
statement of it:

`_common` (the base) → the selected archetype pack(s) → the selected kit → the
project's own instance-level override.

Later in that order wins, with the same merge model the grammar already defines for
overrides: **most-specific-wins, field-level merge, default-as-base**. On a colliding
`kind_id` the kit therefore wins over an archetype pack, and a project's own override
wins over the kit. A base pack occupies the first position as the inheritance root and
contributes no kinds of its own, so it never participates in a `kind_id` collision.

Selecting no kit is an ordinary state, not a degraded one: it is the pre-kit
arrangement, which is what keeps the kit role additive for every existing deployment.
Which kit a deployment selects, how that selection resolves, and why the order above
is a property of role rather than of the configuration rung a pack was selected at,
are documented in the kit-selection section that follows this one.

### The shipped packs are left as-is

No shipped pack is migrated by the kit extension, and each is left as-is for a stated
reason rather than by omission:

| Pack | Disposition | Reason it is left as-is |
|---|---|---|
| `_common` | **left as-is** | `role = "base"` with `applies_to = "*"` is exactly what the widened rule requires of a base pack, and it declares no kinds, which the two-level requiredness rule now states as a prohibition rather than an option. Both of its header values stay correct with no edit. |
| `scrum` | **left as-is** | `role = "archetype"` with `applies_to = "Scrum"` satisfies the widened rule, including the new restriction that an archetype pack must not claim neutrality. Its three kinds are archetype-keyed by design and remain so — a methodology pack's kinds still name their archetype. |
| `kanban` | **left as-is** | Same grounds as `scrum`: `role = "archetype"`, `applies_to = "Kanban"`, one archetype-keyed kind. |

The reason is stated here, in the pack corpus's own governing document, rather than in
each pack's header comment — a header comment would state it alongside the pack and
break the byte-identity the extension guarantees for every shipped pack. All three
files are byte-identical to their pre-change state.

## Kit selection and precedence

A deployment runs **one methodology** and tracks **one work-item kit**, and it chooses
them independently. Both choices are ordinary configuration: one field each, resolved
by the platform's existing five-rung cascade (`OPERATIONS.md` § Platform-Config
Resolution Protocol), and neither field is read by the other's resolution. Selecting a
kit changes only which kinds the deployment tracks.

### The two selection fields

| Axis | Global default | Project override | Resolves to |
|---|---|---|---|
| Methodology | `operator.toml` `[methodology].default_delivery_approach` | `PROJECT.md` frontmatter `delivery_approach:` | an archetype name |
| Work-item kit | `operator.toml` `[methodology].default_work_item_kit` | `PROJECT.md` frontmatter `work_item_kit:` | a `role = "kit"` pack's `pack_id` |

Resolution is the cascade's ordinary rule: the value at the highest-precedence rung
that sets the field, falling through to the global default. **Selecting no kit is a
valid state**, not an error — a deployment that sets neither field behaves exactly as
it did before kits existed, which is what keeps the kit role additive.

Which kits exist is deployment data. Neither field enumerates its own value domain,
and nothing else may either.

### The axes do not interact

The methodology lookup reads `delivery_approach`; the kit lookup reads
`work_item_kit`. Neither reads the other's field, and neither field appears in the
other's resolution. Changing the selected methodology therefore leaves the resolved
kit unchanged, and changing the selected kit leaves the resolved methodology
unchanged. That is a structural property of two independent lookups, not a behaviour
each consumer must remember to preserve.

What makes it hold on the pack side is that a kit is neutral at both levels — its
header is `applies_to = "*"` and each of its kinds sets
`methodology_projection.archetype = "*"` — which is what lets one kit be eligible
under every archetype. A pack that claims the `kit` role while naming a concrete
archetype defeats the property: it is eligible under that archetype only, so the set
of kits a deployment can select would then depend on the methodology it runs. The
grammar forbids that shape outright, and `--validate-packs` rejects it.

**The property is executable, not just asserted.** `check-work-hierarchy.py --resolve
<archetype> [--kit <pack_id>] [--k4 <pack_id>]` reports which packs are eligible and
which pack each resolved kind came from, so "varying one axis leaves the other's
eligible set unchanged" is a claim a reader can run rather than one they must trust.
Both flags take values that are **already resolved**; the tool reads no configuration
file and is not a second resolver.

### Selection is not composition

Selection chooses *which* packs apply. **Composition** decides *whose declaration
wins* when two chosen packs declare the same `kind_id`. They are different operations
and they are decided by different things.

Composition order, the merge model, and the collision rule are defined once in
[`## The role and extends model`](#the-role-and-extends-model) above and are not
restated here.

**That order is fixed by pack role. It is not derived from the configuration rung at
which a pack was selected.** A reader who knows the five-rung cascade will expect the
opposite — that a kit selected at the individual rung outranks a kind declared at the
project rung. It does not. The cascade resolves *which* kit; composition resolves
*whose declaration wins*. A project's own override beats the kit regardless of the
rung the kit was selected at, and a kit beats an archetype pack for the same reason:
its position in the composition order, not its position in the cascade.

This is also why the resolver takes the project-level override **by name**. A pack's
K4-ness is its *location* — Layer 2, `projects/` — and nothing inside the pack file
marks it, so an order inferred from the file alone could not compute that position at
all. Passing the already-resolved override as an argument is what makes the documented
precedence executable rather than merely stated.

### A selection resolves, or it fails loudly

A selection naming a pack that is not there, or naming a pack that is not a kit, is an
**error** — never a quiet fall-through to "no kit selected".

The reason is that those two states are otherwise the *same observation*: both leave a
resolution with no kit-attributed kinds. A deployment whose `default_work_item_kit`
holds a typo would then look exactly like a deployment that deliberately selected
nothing, and the typo would survive indefinitely because everything downstream still
works. Making the failure loud is what separates them.

There is deliberately **no joint-emptiness rule**. A *conforming* work-item kit is
mandatorily kind-bearing, so a deployment that selects one and licenses no archetype
pack resolves the kit's own kinds. A resolution that contributes no kinds is reported
as a measured zero, not an error.

**The states that can produce that zero are enumerated below rather than counted, and
the method is stated with them.** An earlier form of this paragraph asserted instead
that the set was *unchanged from before kits existed*. That is an exhaustiveness claim,
no enumeration backed it, and it is false: the last row below is reachable only because
`role = "kit"` exists. *Method:* each state was constructed as a pack root and run
against the shipped resolver, every subject arm paired with a control over the **same**
root that must return a non-zero count — so a zero here is a measured absence and not a
dead reader.

| State producing an empty resolution | Introduced by the kit? |
|---|---|
| a base pack only | **no** — reachable before kits; `BASE` row, `COUNT 0` |
| archetype packs present, none matching the resolved archetype | **no** — reachable before kits; `EXCLUDED` row, `COUNT 0` (control: the same root under the matching archetype, `COUNT 1`) |
| a kit whose `kit_class` is **unregistered**, declaring no kinds | **yes** — the OPEN class domain working as designed; validates with a `PACK-P08` caveat naming the offending value, then resolves `ELIGIBLE` with `COUNT 0` |
| a kit **welded to one archetype at its header**, selected under a non-matching archetype | **yes** |

The last row is the one the "unchanged set" claim missed. Executed: a `role = "kit"`
pack whose header sets `applies_to = "Scrum"`, under `--resolve Kanban`, prints its
`EXCLUDED` row and `COUNT 0` at exit 0 — the *selection* resolves, because both
`SEL-RESOLVE` limbs hold (the pack is present in the read root, and it is a kit) — while
the control, the same pack under `--resolve Scrum`, prints `COUNT 1`.

**The conclusion is unchanged, and the behaviour is deliberate rather than a defect.**
The empty resolution is loud about its cause — the `EXCLUDED` row names the pack and
states that neither eligibility limb held — and `--validate-packs` rejects that pack
outright under `PACK-P05` (`role = "kit"` requires `applies_to = "*"`), so the state is
unreachable in a conforming corpus. No joint-emptiness rule is added on the selection
axis; the constraint that binds it is `SEL-RESOLVE` above.

## What lives where

- **Work-status** is owned by the entity layer (the Axis-1 base machine); a kind
  inherits it and refines it only if it genuinely narrows or extends the machine. A
  pack never declares its own state machine.
- **Label groups and rules** are the label-taxonomy grammar's job; a pack only
  *contributes* label instances into a grammar-owned group. The shipped packs carry
  the authoritative per-pack label rows in their `[[labels]]` facet (relocated from
  `label-taxonomy.md` by the label-cleave).
- The **grammar** every `pack.toml` conforms to (the meta-schema) lives in the
  work-item type-pack meta-schema. The packs here are **instances** of that grammar.
- **Which of a pack's declarations a methodology owns, and which the platform fixes
  regardless of configuration**, is decided by the configurable/fixed boundary at
  [`../schemas/work-item-type-schema.md` §1.5](../schemas/work-item-type-schema.md#the-configurable-fixed-boundary).
  It carries the configurable and fixed enumerations, the explicit placement of
  readiness and done, and the ordered test an author applies to a **new** candidate
  field or criterion. **Rules are defined there and are not restated here** — this is
  the pointer discipline this file already applies to the grammar itself. Where that
  boundary names an invariant no gate enforces, the gap is registered as a row in the
  gate-coverage register in
  [`../standards/gate-efficacy-standard.md`](../standards/gate-efficacy-standard.md),
  each carrying its declared observable; §1.5 points at those rows rather than
  copying them, and so does this line.
- The **best-practice content** in each pack is sourced from the archetype's
  authoritative body of practice (for example the Scrum Guide, INVEST, the Kanban
  Method) — never reverse-engineered from any one deployment's issue tracker.
  **Each declaration says so in the manifest**, through the `source` key the
  grammar requires on every criteria check entry and every kind-specific field
  declaration, and on a `[kinds.criteria.*]` or `[kinds.fields]` table whose
  array is present and empty — where it states the practice basis for the
  emptiness. Two worked lines: at the entry altitude,
  `source = "Scrum Guide 2020 — Definition of Done"`; at the block altitude,
  `source = "Kanban Method (Anderson 2010) — no readiness practice is prescribed at card level"`.
  **The value convention — and it is a convention, not a grammar rule.** Name the
  work, its edition or year, and the locator where the work has one. The locator
  is deliberately not mandated: INVEST is a six-letter acronym with no sections,
  so a required section separator would forbid an authentic citation of it —
  `source = "INVEST (Wake 2003) — V, Valuable"` is a complete citation exactly as
  it stands. What the value must never be is a repository path, an issue
  template, a label name, or this deployment's own tracker: a declaration whose
  stated origin is the deployment that consumes it has recorded a local
  convention, which is the thing this key exists to tell apart from a body of
  practice. Requiredness, the two altitudes and the no-inheritance rule are
  defined in the grammar and **are not restated here**; read its boundary
  statement alongside them, which says that `source` makes a provenance claim
  visible and locatable and does not make it true — checking a value against the
  work it names is a person's job, and no gate does it.
- **Organizational tiers** are owned by the entity layer; a pack — a kit included —
  types the work and never redefines them. Portfolio, Program, Project and
  Milestone/Workstream are container entities with their own identity, lifecycle and
  membership edges, declared in
  [`../disciplines/project-entity-model.md`](../disciplines/project-entity-model.md).
  That roster is cited here and deliberately not reproduced: it has consumers of its
  own, and a second copy would drift from the one that governs. Why the boundary
  holds by construction is stated once in [`The kit, as a unit`](#the-kit-as-a-unit)
  above and is not re-derived here. Two consequences sit on this side of it. A kit
  that groups work declares a **grouping kind at the Work-Item level** — a grouping
  label, never a new level — carried declaratively by
  `methodology_projection.level_role` rather than inferred from a label name. And a
  rollup reaches a container tier through that tier's own `portfolio_id` /
  `program_id` / `project_id` classifier, never through a kind declared there — which
  is why covering every organizational level needs no kind above the Work-Item one.
