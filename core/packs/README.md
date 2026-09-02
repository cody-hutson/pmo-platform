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
decided in [ADR-170](../ADRs/ADR-170-work-item-kit-first-class-unit.md).

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
- The **best-practice content** in each pack is sourced from the archetype's
  authoritative body of practice (for example the Scrum Guide, INVEST, the Kanban
  Method) — never reverse-engineered from any one deployment's issue tracker.
