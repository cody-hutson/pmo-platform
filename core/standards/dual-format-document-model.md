---
title: Dual-Format Document Model
purpose: The governing model for an operational artifact (the agent-native source of truth) and its stakeholder-facing rendering — a source definition, a per-target translation map (field include/exclude/rename + format), and a version/drift-tracking rule — so the two representations stay in sync and drift between them is detected rather than discovered.
type: standard
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
consumers: artifact-generator (translation-map executor — renders the stakeholder view from the source); Stage 5/9 review of any dual-format artifact; tracker-manager (RAID Log source container + agent-native surface)
---
<!-- reference-durability: allow-link -->
# Dual-Format Document Model

> **Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
> **Canonical home** for the dual-format document model: the source-definition schema, the per-target
> translation-map schema, and the version/drift-tracking rule. This generalizes the already-shipped
> RAID-Confluence dual-format instance (`core/schemas/tracker-schemas.md` §"Confluence Dual-Format
> Model") into a reusable architecture, so the next artifact that needs dual-format (Daily Status,
> Communications Tracker) gets the seam without re-inventing the strip-fields rule. This doc is the
> **single source** for the model; the RAID instance is referenced by relative link as the
> proof-of-concept rather than re-stated (per [duplicate-source-discipline.md](duplicate-source-discipline.md)).

## Purpose

Many operational artifacts have two representations: an **agent-native source of truth** (the version
all skills read and write for processing, querying, and lifecycle management) and a **stakeholder-facing
rendering** (the version a human audience sees — a Confluence page, a stakeholder CSV export, a Teams
message). Today the RAID Log ships a concrete instance of this pattern; what has not existed is the
*governing model* that generalizes it. This document defines that model as three durable, parameterized
structures — a **source definition**, a **per-target translation map**, and a **version/drift-tracking
rule** — so any artifact can declare its source and one map per target system, and drift between the two
is flagged rather than silently accumulated.

The model binds to the **Artifact entity** ([`project-entity-model.md`](../disciplines/project-entity-model.md)
§4 entity 9) via that entity's existing reconciliation seam (`domain` + `content_lifecycle_pattern`) — it
is not a parallel concept. It **does not** touch an artifact's machine-schema: the EAD mechanism
(Entity→Artifact-Schema Derivation) derives a validation schema from an entity (one representation,
validated); this model governs two human/stakeholder representations of the same source and the drift
between them. Those are orthogonal axes — EAD = entity→schema (validation); dual-format = source→target
(rendering + sync).

## Source-definition schema

Declares the agent-native source of truth for a dual-format artifact. One source definition per artifact.

```yaml
source:
  artifact: <artifact_title>            # binds to the Artifact entity's artifact_title
  artifact_type: <Type Taxonomy value>  # = frontmatter-schema Type Taxonomy (referenced, not redefined)
  container: <csv | md-table | json>    # the on-disk format of the SOURCE
  domain: <A | B | C>                   # Artifact entity reconciliation seam (frontmatter Domain A/B/C)
  content_lifecycle_pattern: <Baselined | Living | Hybrid>   # Axis-2 (mirrors domain)
  schema_ref: <path | null>             # machine-schema if entity-derived (e.g., raid-log.schema.json); null if none
  fields: [<field-name>, ...]           # the authoritative field roster (source of the include/exclude decisions)
```

- `domain` and `content_lifecycle_pattern` **are** the Artifact entity's reconciliation-seam fields — the
  same names the entity already uses, not new ones.
- `schema_ref` is non-null **only** when the artifact is entity-derived and has a machine-schema; the
  machine-schema is the agent-native *validation* surface and is unaffected by the container choice.

## Per-target translation-map schema

One map per `(source × target-system)`; the executor (artifact-generator) applies it to render the
stakeholder view from the source. The map is the ONLY rendering path — a stakeholder view is never
produced by a bespoke, hand-written export.

```yaml
translation_map:
  map_id: <source-slug>--<target-slug>       # e.g., raid-log--stakeholder-csv
  source_ref: <source.artifact>              # the source-definition this map renders FROM
  target_system: <confluence | csv-export | teams | md>
  target_format: <markdown-table | csv | confluence-storage | prose>
  field_rules:                               # per-field include/exclude/rename
    exclude: [<field>, ...]                  # internal-only fields stripped from the target
    rename: { <source-field>: <target-label>, ... }
    include_order: [<target-label>, ...]     # optional explicit column order for the target
  orphan_guard: reject                       # failure-mode: render REJECTS if source_ref has no live source
  render_stamp_field: <Artifact Register column>   # where the render version/date is recorded (drift key)
```

- `field_rules.exclude` / `field_rules.rename` are a direct realization of "field include/exclude/rename".
- `orphan_guard: reject` is the do-NOT failure mode (see § Failure mode below).
- `render_stamp_field` binds the render version/date to the **Artifact Register** (Tracker 6) columns — the
  drift key (see § Version/drift-tracking rule).

## Version/drift-tracking rule

Drift tracking **reuses the Artifact Register** (Tracker 6, `core/schemas/tracker-schemas.md`) — it does
**not** add a new tracker. A parallel "render-log" tracker would duplicate a governed home (the Artifact
Register already carries `Current Version` + `Last Updated` + `Baseline Status` per artifact CI).

- **On render:** artifact-generator records the source's `Current Version` + `Last Updated` (from the
  source's Artifact Register row) as the **render stamp** on the produced target — a metadata header for a
  staged file, or a recorded render date for an external target such as Confluence.
- **Drift is detected** when EITHER:
  1. the source's Artifact-Register `Last Updated` is **newer** than the target's recorded render stamp
     (source changed, target not re-rendered); OR
  2. a target field is present that the map's `field_rules` (exclude/rename) does not permit (target
     diverged from the map).
- **On drift:** raise a drift flag through the Artifact Health Check surface (the `stale artifacts` /
  `lifecycle-debt` rows artifact-generator already produces) — surfaced for operator review, not silently
  reconciled.

## Failure mode — orphan rendering (do NOT)

Do **NOT** publish a stakeholder view whose `source_ref` resolves to no live source (the source file is
absent, or has no Artifact Register row). `orphan_guard: reject` requires the render to **halt and flag**
in that case — a stakeholder view without a live source is rejected/flagged, never silently emitted.
Rendering an orphan target would produce a stakeholder-facing document with no authoritative source behind
it, defeating the drift-detection the model exists to provide. The executor
([`artifact-generator/SKILL.md`](../../operations/skills/artifact-generator/SKILL.md)) carries the matching
domain-specific failure-mode entry enforcing this.

## Artifact-entity binding

A dual-format Artifact's source/target pair is governed by this model via the **Artifact entity's existing
reconciliation seam** — `domain` + `content_lifecycle_pattern`
([`project-entity-model.md`](../disciplines/project-entity-model.md) §4 entity 9). The model adds no new
entity field and introduces no parallel concept: the `source` block's `domain` / `content_lifecycle_pattern`
ARE the entity's seam fields, and the executor is the entity's owning-agent creator (artifact-generator).

## Worked example — `raid-log--stakeholder-csv`

The RAID Log is the first artifact instanced against this model. Its source container is **CSV** (retained;
the JSON machine-schema `raid-log.schema.json` is the agent-native validation surface — the CSV is its
persistence dialect), and the stakeholder rendering is the existing strip-internal-fields rule, now
formalized as a translation map:

```yaml
source:
  artifact: RAID Log
  artifact_type: RAID Log
  container: csv
  domain: B
  content_lifecycle_pattern: Living
  schema_ref: core/schemas/raid-log.schema.json
  fields: [RAID_ID, RAID Category, Description, Impact, Owner, Priority, Status,
           Action Plan, Due Date, Date Opened, Date Closed, Closure Comments, Tags, Section]

translation_map:
  map_id: raid-log--stakeholder-csv
  source_ref: RAID Log
  target_system: csv-export | confluence
  target_format: csv | confluence-storage
  field_rules:
    exclude: [RAID_ID, Date Opened, Date Closed, Section]   # the existing strip rule, verbatim
  orphan_guard: reject
  render_stamp_field: Artifact Register (Current Version / Last Updated)
```

The `exclude` list is exactly the internal-operational-fields strip already stated in the RAID instance
(RAID_ID, Date_Opened, Date_Closed, Section). The on-demand stakeholder CSV/Confluence view is produced by
**artifact-generator** applying this map — not by a bespoke export path in tracker-manager.

## Proof-of-concept reference

The concrete instance this model generalizes is the RAID Log's dual-format handling in
[`core/schemas/tracker-schemas.md`](../schemas/tracker-schemas.md) §"Confluence Dual-Format Model" — a local
CSV source of truth plus a Confluence stakeholder view that strips the internal operational fields. That
section is the **proof-of-concept**; this model names and generalizes it (source-definition → per-target map
→ version/drift rule). The RAID rules are referenced here, not restated — the tracker-schemas section
remains the operational home for the RAID instance's specifics.
