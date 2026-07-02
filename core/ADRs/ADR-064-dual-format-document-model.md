<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-064 — Dual-format document model as a net-new governing standard, with artifact-generator (not comms-writer) as the translation-map executor"
status: Accepted
date: 2026-07-01
release: v3.47-tracker-comms-session-config
deciders: "operator (confirmed 2026-07-01) + Stage 5 Solutioning spoke + independent adversarial review"
tags: [architecture, standard, dual-format, artifact-entity, executor-selection, skill-boundary, rendering, drift-detection]
source_observations:
  - "The RAID Log already ships a concrete dual-format instance (tracker-schemas.md §'Confluence Dual-Format Model' — local CSV source + Confluence stakeholder view stripping RAID_ID/Date_Opened/Date_Closed/Section) but no GOVERNING model generalizes it: grep -rln 'dual-format|Confluence Dual-Format' matched the RAID instance + release provenance only; no spec references a governing dual-format model (net-new)."
  - "The dual-format model governs two human/stakeholder representations of one source and their drift — orthogonal to the EAD mechanism, which derives a machine-schema (raid-log.schema.json) from an entity (one representation, validated). EAD = entity->schema (validation); dual-format = source->target (rendering + sync). The model cites EAD as the reason it does NOT touch the machine-schema, not as overlap."
  - "Executor candidates for AC#3 were comms-writer XOR artifact-generator. artifact-generator is the owning-agent creator of the Artifact entity (project-entity-model.md §6), already carries an 'updates an existing file -> present a diff summary' path (its render + drift surface), and stages to 08-Generated/ for the Tier-1 approval the RAID Log requires. comms-writer owns no entity (a message is not a tracked Artifact CI) and has no source-artifact-diff path."
  - "Routing the executor to artifact-generator eliminates the soft comms-writer contention with #239 (which edits comms-writer's 2-day stalled-comm rule) entirely — comms-writer is not modified by #234."
  - "Drift-detection reuses the Artifact Register (Tracker 6) Current Version / Last Updated columns rather than a new render-log tracker (pre-creation governance check: a governed home already exists)."
---

# ADR-064 — Dual-format document model as a net-new governing standard, with artifact-generator (not comms-writer) as the translation-map executor

## Status

Accepted. The committed record of the Stage-5 D-Design decision for the v3.47 slice (milestone
23-tracker-comms-session-config, #234), scope-locked at Collective Review 2026-07-01.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/` (global max = ADR-063 at the
authoring commit; contiguity enforced by `release/tools/check-adr-numbers.py`). Referenced downstream **by
slug**, never by number. Extended or reversed only by a successor / superseding ADR — never by in-place
edit.

## Context

The RAID Log ships a concrete dual-format instance (a local CSV source of truth plus a Confluence
stakeholder view that strips internal operational fields), but no *governing model* generalizes it. Without
one, the next artifact that needs a dual-format representation (Daily Status, the Communications Tracker)
would re-invent the strip-fields seam — a duplicate-source-discipline violation. #234 asks for the reusable
architecture: a source definition, a per-target translation map, and version/drift tracking. #233 (the
RAID container decision) is the first consumer and sequences immediately after #234.

Two design questions had to be settled:

1. **Form and placement of the model** — a net-new governing spec, or an extension of an existing surface
   (`frontmatter-schema.md` Domain A/B/C, or the EAD entity-derivation)?
2. **Which skill executes the translation map** — AC#3 scoped it to `comms-writer` XOR `artifact-generator`.

## Decision

**1. A net-new K1 governing standard** at `core/standards/dual-format-document-model.md`, defining three
durable, parameterized structures — a source-definition schema, a per-target translation-map schema, and a
version/drift-tracking rule keyed on the Artifact Register (Tracker 6). The model **binds to the Artifact
entity** (`project-entity-model.md` §4 entity 9) via its existing reconciliation seam (`domain` +
`content_lifecycle_pattern`) — no new entity field, no parallel concept. It **does not** touch any
artifact's machine-schema: EAD (entity→schema, validation) and this model (source→target, rendering + sync)
are orthogonal axes; the model cites EAD as the reason it leaves the machine-schema untouched.

**2. The translation-map executor is `artifact-generator`, not `comms-writer`.** artifact-generator is the
owning-agent creator of the Artifact entity, already carries a "render an existing file → present a diff
summary" path, and stages to `08-Generated/` for the Tier-1 approval a stakeholder view of a Tier-1
artifact requires. comms-writer's "no internal IDs in stakeholder output" rule is a *rule the translation
map encodes* (the map's `exclude` list), **not** a reason to make the message-writer the render engine. The
model's drift tracking reuses the Artifact Register's existing `Current Version` / `Last Updated` columns
rather than a new render-log tracker.

## Alternatives considered

- **Executor = comms-writer.** Rejected. comms-writer owns no entity (a sent message is not a tracked
  Artifact CI), produces an ephemeral message rather than a version-tracked file, and has no
  source-artifact-diff path for drift detection. It would also **retain** the soft contention with #239
  (which edits comms-writer's stalled-comm rule). MODERATE reversibility, MEDIUM confidence, misaligned with
  Artifact-entity ownership.
- **Executor = both (map executable by either skill).** Rejected. AC#3 specifies XOR; making the map
  executable by both splits the render contract across two skills → spec debt. Over-broad. LOW confidence.
- **No governing model — leave the one RAID instance as-is.** Rejected. The card names two next consumers
  plus the immediate #233 dependency; a second artifact needing dual-format with no governing seam re-invents
  the strip rule (duplicate-source-discipline violation). The model is the register-once home.
- **Extend `frontmatter-schema.md` / reuse EAD.** Rejected as overlap. EAD derives a machine-schema from an
  entity (validation); the dual-format model governs two stakeholder representations of one source and their
  drift (rendering + sync). Orthogonal — the model cites EAD, does not extend it.

## Consequences

- **artifact-generator** gains a dual-format rendering mode (reads a source + its map, applies
  `field_rules`, stages the target view to `08-Generated/`, records the render stamp) and a matching
  domain-specific failure mode enforcing `orphan_guard: reject` (a stakeholder view with no live source is
  rejected/flagged, not published).
- **The soft #234↔#239 contention on `comms-writer/SKILL.md` is eliminated** — comms-writer is not modified
  by #234; #239 is the sole editor.
- **#233 instances the model** by binding its source-definition `container` field (resolved to `csv` under
  #233's Option B) and using the `raid-log--stakeholder-csv` map for the stakeholder rendering — no bespoke
  export path.
- **No new tracker** — drift keys on the Artifact Register (Tracker 6).
- **Reversibility MODERATE / Confidence HIGH** — additive spec + opt-in maps; no existing artifact loses a
  capability. Revert = remove the spec + the artifact-generator mode + the two cross-reference notes.
