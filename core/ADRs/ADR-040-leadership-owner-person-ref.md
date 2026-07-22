---
title: Leadership-owner fields are typed Person refs with an external free-text fallback
status: Accepted
tags: [entity-model, people-graph, leadership-owner, tier-2-scope-change, person-ref]
---

# ADR-040 — Leadership-owner fields are typed Person refs with an external free-text fallback

## Status

Proposed — ratified at the functional-people-graph Stage 9 GO. That operator GO renders
the **Tier-2 SCOPE CHANGE** authorization required by the FROZEN-roster / frozen-field
clause of [`project-entity-model.md` §4](../disciplines/project-entity-model.md#4-entity-definitions-19)
("any change requires reopening the establishing issue via a Tier-2 SCOPE CHANGE") and
the [`entity-field-schemas.md` §8](../schemas/entity-field-schemas.md) freeze clause
("field-list changes require reopening via a Tier-2 SCOPE CHANGE; validation-rule changes
are owned here"). Per the core-ADR convention, this decision is captured as a committed ADR
document authored alongside the entity-model and field-schema edits in the same release.

## Context

The frozen 18-entity model grounds the operational-owner axis on Person with typed FK
rules (RAID owner, Resource, Workstream lead, Decision-maker, Meeting attendees, System
owner, Vendor contact, Cross-Project Resource Conflict) but leaves the LEADERSHIP axis —
`Project.project_owner`, `Portfolio.portfolio_owner`, `Program.program_owner`,
`StrategicInitiative.sponsor` — as four free-text `string` fields. Free-text owners cannot
be deduplicated against the Person identity anchor, cannot answer leadership/sponsorship
queries, and re-introduce the misspelling/duplicate problem the people graph exists to
eliminate. Leadership owners are frequently internal roster people, but a sponsor in
particular is often a legitimately EXTERNAL party (a client executive, a vendor-side owner)
who is not in the operator's Person roster and must not be forced into a fake Person record.

## Decision

The four leadership-owner fields are lifted from `string` to **`ref → Person.person_id`,
with an optional `<field>_external` free-text fallback** for non-roster (external) people.
Four cross-entity FK rules are added (the leadership axis joins the existing operational
axis on the `person_id` anchor).

Three invariants govern the change:

1. **Mutual exclusion (L1 — single-record).** For each leadership field, *exactly one* of
   {`<field>` ref, `<field>_external` free-text} is populated. Both-populated is a malformed
   write (BLOCK-WRITE). This makes the two-source ambiguity unrepresentable rather than
   resolved-by-read-convention; read precedence is moot because the both-set state is
   unreachable. The original required-presence guarantee moves to this invariant: a
   leadership record must have exactly one of the pair populated (as strict as the prior
   `present ∧ non-empty`).

2. **Field-conditional on-unresolved disposition (L2 — cross-record).** When the `ref` slot
   is populated but does not resolve to a Person → **BLOCK-WRITE** (the value was meant to be
   an internal roster person; a dangling ref is malformed, the same posture as the required
   internal-identity FKs). When the `<field>_external` slot is the populated one →
   **WARN-HEALTH** (an unverified external label surfaces in a health report, not a hard
   block). The disposition follows *which slot is filled*, not a fixed per-field tier — so
   the soft tier never silently admits a mis-typed internal owner/sponsor, including for
   `sponsor`, whose modal value is external but whose mis-typed-internal case must still
   block.

3. **Additive migration, no silent drop.** Existing free-text owner values migrate by
   resolve-by-name against the Person roster: a value that resolves to a unique Person
   becomes the ref; a value with zero matches, or with ≥2 ambiguous matches, routes to the
   operator clarification queue (add as a Person, or record as external fallback) and is
   never silently dropped and never auto-picked / first-matched. The change is additive — the
   ref is the new primary and the external fallback preserves any external/unmigrated value —
   so no existing reader of these fields breaks.

The committed schema-example and the public de-identified roster template carry the
`<field>_external` slot only as an obviously-synthetic placeholder token (e.g.
`[EXTERNAL_SPONSOR_NAME]`), never a realistic external name; this placeholder discipline
rests on the self-containment / depersonalization review of committed surfaces (the
token-allow markers do not cover an arbitrary external person's name).

## Consequences

- The leadership and operational owner axes are unified on the `person_id` anchor; the
  people graph answers leadership/sponsorship queries from grounded refs.
- A legitimately-external sponsor/owner is representable without a fake Person.
- **Reversibility is EXPENSIVE once a consumer hard-binds the ref** — a reader that treats
  the field as a resolved ref must be unwound by re-free-texting every consumed reference if
  the decision is reversed. The two invariants above are therefore fixed before any consumer
  is wired; the change may land unconsumed (additive) at MODERATE reversibility and only
  reaches EXPENSIVE when a reader binds.
- This is a frozen-schema Tier-2 SCOPE CHANGE to the entity model, of the same class as the
  roster 17→18 work-item-entity addition (ADR-018) and the RAID Item `impact`/`action_plan`
  field promotion (the 2026-05-16 Option-A amendment) — both prior Tier-2 typed-field changes
  to existing/added entities. The affected entity surfaces are RE-FROZEN with this amendment
  in effect.

## Alternatives considered

| Option | Decision | Rationale |
|---|---|---|
| **Hard ref, no fallback** | Rejected | Blocks a legitimate external sponsor/owner until a fake Person is created — fails the external-coverage requirement. |
| **Leave as free-text + soft health-check** | Rejected | No grounded ref, no dedup; does not deliver the queryable leadership graph that motivates the change. |
| **Two independently-optional fields with implied ref-precedence** | Rejected | Implied precedence forces every reader to re-derive it and drift; making both-set unrepresentable (the mutual-exclusion invariant) closes the ambiguity at the schema, not the consumer. |

## Related ADRs

- [ADR-018](ADR-018-work-item-type-layer.md) — the roster 17→18 work-item-entity addition;
  the apt Tier-2 SCOPE CHANGE precedent (same change-class: a typed-field change to the
  frozen entity model, authorized by an operator Stage 9 GO). Its own precedent — the
  2026-05-16 RAID Item `impact`/`action_plan` field promotion — is the second Tier-2
  precedent this decision cites.
- The Two-Axis Entity Lifecycle ADR (ratified at Collective Review, 2026-05-16) — the entity
  model whose frozen leadership fields this decision type-lifts.
