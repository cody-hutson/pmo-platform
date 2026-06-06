---
title: ADR-016 — intake front door as a distinct architectural component (boundary + downstream handoff contract)
status: Accepted
date: 2026-06-06
release: intake-elicitation-skill
deciders: "operator + Stage 5 Solutioning (design, rev 2) + operator PR review (2026-06-06)"
tags: [skill, intake, architecture, component-boundary, handoff-contract, front-door]
source_observations:
  - "A conversational intake skill needs an architectural decision recorded: what component does it establish, where is its boundary against adjacent skills, and what does it hand off downstream. (Stage 5 Re-Solutioning rev 2.)"
  - "An intake front door must not author ADRs — ADRs are an architecture act. The dropped-ADR-type decision is a boundary statement: intake elicits work to be done; architecture authors decision records."
  - "Intake emits unknowns it cannot resolve as owned, stage-tagged assumptions for progressive downstream closure; this is the handoff contract a downstream consumer relies on, distinct from any per-type-registry mechanism."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-016 — intake front door as a distinct architectural component

## Status

Accepted at the intake-elicitation-skill Stage 5 Collective Review scope-lock and
confirmed at the operator's PR review (2026-06-06). Per the core-ADR convention, this
decision is captured as a committed ADR document rather than a tracked issue, and is
authored as a file alongside the [`intake-desk`](../../operations/skills/intake-desk/SKILL.md)
implementation in the same release.

Provenance: `intake-desk` skill (#412), milestone intake-elicitation-skill (#109);
forward-coupled to the work-item type system (#409).

## Context

The platform is introducing a conversational intake skill, `intake-desk`, that takes a
half-formed idea — at any altitude — and produces a well-formed, correctly-typed,
correctly-placed work item logged to the work tracker. Before this, intake was cold
form-filling against static templates: no component owned the
*elaborate-an-idea-into-a-typed-item* function, and the absence of that front door had
already produced an improvised scratch file committed in the wrong place.

Standing up that front door raises an architectural question, not merely an
implementation one: **what component does it establish, where is its boundary against
the adjacent skills, and what does it hand off to the stages downstream of it?** The
decision is non-obvious (it delineates several components and sets a downstream
contract) and cross-cutting (a downstream consumer — triage, ppm-agent, slicing —
relies on what the front door emits), which clears the ADR threshold per
[`decision-discipline.md`](../disciplines/decision-discipline.md).

(An earlier framing of this ADR treated the decision as a type-registry parameterization
seam. That framing is superseded: the durable architectural decision is the **component
boundary and the handoff contract**, not the table mechanism by which the skill binds to
the current work-item types. The type-binding mechanism is an implementation detail
governed by the skill's own reference files; this ADR governs the architecture.)

## Decision

**Introducing the conversational intake front door (`intake-desk`) establishes a distinct
architectural component at the head of the work-item lifecycle, with a clear boundary
against the adjacent skills and an explicit handoff contract to triage and the downstream
stages.**

Concretely, the decision has three parts.

### 1. Intake/elicitation is a distinct architectural component

`intake-desk` is the front door of the work-item lifecycle: the component that owns
turning a raw idea into a typed, well-formed, correctly-placed work item. No prior
component owned this function.

### 2. The component boundary (stated as verbs, not examples)

The boundary is clean because the components' verbs are disjoint:

| Component | Owns (verb class) | Does NOT do |
|---|---|---|
| **`intake-desk`** | **Authors** a typed, well-formed work item from a raw idea — the front door. | Process existing artifacts; scaffold projects; author decision records. |
| **`ppm-agent`** | **Processes existing** artifacts across project and release surfaces (transcripts, RAID, status, exports) and pushes existing items to resolution. | Author a new item from a raw idea via guided elicitation. |
| **`project-initiator`** | **Structures new project folders** for the toolkit to use, and **archives closed projects** from rollups. | Produce a single work item; elicit requirements for a backlog item. |
| **architecture** (not a single skill) | **Authors ADRs / design decisions.** | (Conversely) is not authored by intake — `intake-desk` does not author ADRs. |

`intake-desk` sits **upstream** of `ppm-agent` for the items it authors — its output is
**one** input `ppm-agent` may later process, not `ppm-agent`'s sole upstream (`ppm-agent`
also processes existing project- and release-side artifacts that never passed through the
front door) — and is **orthogonal** to `project-initiator` (item-level vs project-level). The
last row is the durable statement of the dropped-`adr`-type decision: an intake front
door elicits **work to be done** (improvement / bug / observation), not design decisions
already made. When an intake conversation surfaces that a decision needs recording, the
front door notes it and hands off to architecture; it does not author the ADR.

### 3. The handoff contract to triage / downstream

The front door emits a typed work item plus:

- **Owned assumption items.** Every unknown the front door cannot resolve from the user
  (after one re-elicitation) is emitted as a stage-owned assumption in the body —
  `[ASSUMPTION – CONFIRM] <assumption> — owner: <stage> — to close: <evidence/decision>`
  — where `<stage>` is one of root-cause / research / dependency / design / architecture /
  slicing / estimation / resourcing, or **triage** for an unresolved altitude. Downstream
  stages close these progressively. The front door **emits** owned assumptions; the
  convention for who picks each one up and how it closes is a separate downstream design,
  not part of this ADR. The front door never fabricates a value and never silently drops
  an unknown.
- **A body decomposition callout, not auto-created children.** For a container idea (an
  initiative or epic-equivalent), the candidate child work is surfaced in the body for
  later slicing — the front door creates exactly **one** work item per request and never
  auto-decomposes into child items (slicing is a later, dedicated stage with its own
  rules).

This is the contract a downstream consumer (triage, `ppm-agent`, slicing) relies on.

## Options considered

| Option | Decision | Rationale |
|---|---|---|
| **(C) Record the component boundary + handoff contract (this ADR)** | **Chosen** | The front-door-as-component decision is non-obvious and cross-cutting: it delineates four components by disjoint verbs and sets a downstream handoff contract that triage and slicing depend on. |
| (B) Record a type-registry parameterization seam | Superseded | The durable architectural decision is the component boundary, not the table mechanism by which the skill binds to the current work-item types; the binding mechanism is an implementation detail in the skill's reference files. |
| (A) No ADR | Rejected | Leaves the component boundary and the downstream handoff contract undocumented — exactly the cross-cutting decision an ADR exists to capture. |

## Consequences

### Positive

- **A named front door exists.** The work-item lifecycle gains an owner for the
  elaborate-an-idea function; the originating defect (a scratch file for lack of a funnel)
  cannot recur, because the front door's only persistence paths are a logged item or a
  copy/paste body.
- **The boundary is verb-disjoint and durable.** Authoring vs processing vs scaffolding
  vs decision-recording are distinct; the delineation does not drift as examples change.
- **Downstream gets a typed handoff.** Triage and slicing receive a typed item with
  stage-owned assumptions and a decomposition callout, rather than raw or under-specified
  intake.

### Negative

- **The boundary is referenced by several surfaces.** The skill's `description:`, the
  handoff contract, and any future `ppm-agent`/triage consumer all rest on this
  delineation; re-drawing it touches more than one surface. This is why the reversibility
  tier is MODERATE rather than CHEAP.

## Reversibility

**MODERATE / Confidence HIGH.** The component boundary is referenced by the skill's
trigger description, the handoff contract, and any downstream consumer that relies on the
emitted shape; re-drawing it is a multi-surface change rather than a single-file edit. The
decision does not introduce a data migration or a schema change.

## Forward-coupling

When the platform's work-item type system lands, it extends the type set the front door
binds to. The component boundary and the handoff contract recorded here are **unaffected**
— they concern *which component authors* and *what it hands off*, not *what the type
registry looks like*. The type system (recorded in § Status provenance as a
forward-coupled item) is not this ADR's thesis.

## Related ADRs

- [ADR-008](ADR-008-deploy-sh-per-module-array-design.md) — per-module skill arrays;
  `intake-desk` registers in `OPERATIONS_SKILLS`, the surface this skill is deployed
  through.
- [ADR-012](ADR-012-roadmap-instance-descope.md) — establishes the
  parameterize-the-instance / retain-the-frame discipline at the roadmap-instance layer;
  the same discipline lets the front door bind to the current work-item types while the
  component boundary stays fixed.
