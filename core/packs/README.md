---
title: Methodology Packs (core/packs/)
purpose: README for core/packs/ — defines the methodology-pack unit (per-archetype work-item kinds, label contributions, and gates) and the pack layout and inheritance model.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Methodology Packs (`core/packs/`)

A **methodology pack** is the plug-and-play unit that bundles, per delivery-approach
archetype, a methodology's work-item kinds, its label contributions, and its gates.
Packs ship as **best-practice defaults** (codified, universal knowledge); a deployment
**selects** a pack via operator configuration and **overrides** it per project. A
project's own declared kinds are instance configuration and are never authored into
this tracked corpus.

## Layout

- `_common/pack.toml` — the shared **base** pack (`role = "base"`): archetype-invariant
  label-group contributions every archetype pack inherits. It carries no work-item
  kinds and no work-status machine.
- `<archetype>/pack.toml` — one pack per archetype (for example `scrum`, `kanban`),
  each `role = "archetype"`, declaring `extends = "_common"` and carrying only its
  deltas: its kinds, its criteria, its gates.

## The `role` and `extends` model

A pack declares a `role`: `base` (a non-kind-bearing shared pack) or `archetype` (the
default — a normal pack that declares kinds for one archetype). Only an `archetype`
pack sets `extends`, naming the `base` pack it inherits from; it then declares only
what differs. This reuses the platform's existing convention for conditionally-required
fields — the same pattern the work-item type grammar already uses for custom kinds and
the project schema uses for custom methodologies.

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
