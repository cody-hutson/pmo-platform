---
title: ADR-019 — Specialists compose (not absorb) shared function-skills
status: Accepted
date: 2026-06-08
release: skill-suite-architecture-spine
deciders: "operator (decision adopted 2026-06-06) + Stage 5 Solutioning spoke"
tags: [architecture, skill, role-skills, composition, decomposition-axis, skill-boundary, specialists]
source_observations:
  - "The platform has 22 function-decomposed skills (named by what they do — comms-writer, tracker-manager, release-planner). The approved role-skills suite is role-decomposed (named by who they emulate — Principal Engineer, QA Lead, Release Manager). Building the role suite on top of the function-skills without reconciling the decomposition axis duplicates capability. (skills-architecture roadmap §4.2 Move 1.)"
  - "Four named overlap pairs make the collision concrete: Release Manager <-> release-planner+release-executor; Principal Engineer <-> pmo-technical-analyst; QA Lead <-> pmo-qa-auditor+build-reviewer; Portfolio Manager <-> ppm-agent+weekly-status-rollup. All seven function-skills exist in the live tree (verified core/+release/+operations/)."
  - "The composition substrate already exists: cascade rule C1 (depth bound: max 2) at agent-handoff-framework.md and the Skill Chaining Protocol (C1-C7 + 4-skill allowlist) in OPERATIONS.md. A role that composes shared skills via skill-chaining keeps routing depth <=2 by construction; a role that re-implements shared logic violates the decision."
  - "Operator adopted the decision 2026-06-06: role-skills are thin Specialists that COMPOSE shared function-skills, do not absorb them; a role MAY span several Specialists, split per the skill-boundary test (distinct trigger surface AND distinct write-scope AND distinct primary role)."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-019 — Specialists compose (not absorb) shared function-skills

## Status

Accepted (operator-adopted at the skill-suite-architecture-spine Collective Review
scope-lock; that release activated Stage 5 with two or more Solutioning issues, so
Collective Review fired as the ratification gate per the
[Nygard status convention](README.md#status-enum), and the skill-suite-architecture-spine
milestone reached closure on 2026-06-08). The decision itself was operator-adopted on
2026-06-06; this ADR is the committed record of that adopted decision.

Provenance: the decision was operator-adopted on 2026-06-06 (recorded on the
adopting decision-record intake for the role-skill suite); this ADR is the committed
record of that adopted decision, authored per the core-ADR convention. The
decision-adoption date (2026-06-06) and this ADR's authoring date (2026-06-08) are
distinct: the ADR transcribes an already-made decision, it does not re-decide it. The
status transcription from Proposed to Accepted was reconciled under the ADR-019
ratification-tracking work item after the ratifying review had already closed.

## Context

The platform decomposes its skills along two different axes, and the two axes
collide.

- The **22 function-decomposed skills** are named by *what they do* — `comms-writer`,
  `tracker-manager`, `release-planner`, and the rest. Each owns one function and is
  the single source of that function.
- The approved **role-decomposed** suite is named by *who it emulates* — Principal
  Engineer, QA Lead, Release Manager, Portfolio Manager, and the other reference-model
  roles.

The problem is precise: building the role suite *on top of* the function-skills
**without reconciling the decomposition axis duplicates capability**. A role-skill
that re-implements a function the platform already owns forks the source of that
function and lets two skills drift apart.

Four named overlap pairs make the collision concrete. All seven function-skills are
present in the live tree, spread across all three modules:

- **Release Manager** overlaps `release-planner` + `release-executor` (both in
  `release/skills/`).
- **Principal Engineer** overlaps `pmo-technical-analyst` (in `operations/skills/`).
- **QA Lead** overlaps `pmo-qa-auditor` (in `core/skills/`) + `build-reviewer` (in
  `release/skills/`).
- **Portfolio Manager** overlaps `ppm-agent` + `weekly-status-rollup` (both in
  `operations/skills/`).

Because the overlap pairs span all three modules (`operations/`, `release/`, `core/`),
the decomposition-axis decision governs role-skills across the whole platform — it is
a cross-module, platform-architecture decision, not a single-module one.

The composition substrate the decision rests on already exists. The **Skill Chaining
Protocol** (cascade rules C1-C7 + the 4-skill allowlist) in
[`OPERATIONS.md`](../governance/OPERATIONS.md) lets one skill invoke another at
runtime; specifically, cascade rule **C1 (depth bound: max 2)** at
[`agent-handoff-framework.md`](../standards/agent-handoff-framework.md) sets
`cascade_depth` at the invoker and refuses an invocation when `cascade_depth >= 2`.
That existing machinery is what makes "compose, don't absorb" mechanically
enforceable rather than aspirational.

The decision clears the ADR threshold per the decision-discipline: it is non-obvious
(it sets the decomposition axis for the entire role-skill build) and cross-cutting
(it governs role-skills across both consumer modules).

## Decision

**Specialists are role-named; Organizers and Orchestrators are function-named shared
machinery.** Role-skills are authored as **thin Specialists that COMPOSE the existing
shared function-skills** — they do **not** absorb or duplicate them. The discipline is
"compose, don't over-absorb": a Specialist reaches the function it needs by invoking
the function-skill that already owns it, leaving that function-skill the single source
of its function.

**A role MAY span several Specialist skills**, but only within logical reason. A role
splits into more than one Specialist only when the **skill-boundary test** holds — and
all three conjuncts must hold together:

1. **distinct trigger surface** — the would-be second Specialist answers a materially
   different set of invocation triggers, AND
2. **distinct write-scope** — it writes to a different set of artifacts / output
   surfaces, AND
3. **distinct primary role** — it occupies a different primary role in the work, not a
   variation of the same one.

If any conjunct fails, the capability belongs in the existing Specialist (or the
existing function-skill), not in a new one.

The composition mechanism is explicit and load-bearing: a Specialist composes a shared
function-skill by **invoking** it through skill-chaining (cascade-scope / allowlist),
**not** by copying that function-skill's logic into the Specialist's own `SKILL.md`.
This invocation-not-absorption distinction is the rule the rest of this ADR depends on.

## Consequences

### Positive

- The role-skill build gains a **binding decomposition rule**: capability is not
  re-implemented per role; the function-skills remain the single source of their
  function, and overlap is resolved once rather than re-litigated per role.
- **Routing depth stays <=2 by construction.** Because a role composes shared skills
  via skill-chaining rather than re-implementing them, the cascade never exceeds the
  existing **C1 depth bound (max 2)** already enforced at
  [`agent-handoff-framework.md`](../standards/agent-handoff-framework.md) — this ADR
  *relies on* C1 and does not coin a new bound.
- Overlap is **reconciled once** — EXTEND an existing skill versus build a new one —
  instead of being duplicated across the suite.

### Negative / cost

- The role-skill build is **gated** on this decision plus the skill-pipeline alignment
  audit (which reconciles the *specific* overlapping pairs — see the reconciliation
  venue below). Gating adds a sequencing constraint; this is the intended control, and
  the audit ships in the same release.
- The skill-boundary test introduces a **review obligation**: every new Specialist must
  be checked against the three conjuncts (distinct trigger surface AND write-scope AND
  primary role), and **a role-skill that re-implements shared Organizer/Orchestrator
  logic FAILS review**. This becomes a review criterion for the auditor and the build
  reviewer. The cost is mitigated: the test is a three-conjunct checklist, mechanically
  applicable rather than a judgment call.

### Reconciliation venue

Overlapping role/function pairs are reconciled at the skill-pipeline alignment audit —
never duplicated. This ADR records the *principle*; that audit performs the
pair-by-pair reconciliation (EXTEND existing versus build new) for the four named
overlap pairs, citing this ADR as its governing principle. The relationship is a soft
forward-reference: the audit cites this ADR; this ADR does **not** consume the audit's
output and does not depend on it landing first. The audit is named in the References
block below.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| **(A) Compose — thin Specialists invoke shared function-skills (this ADR)** | **Chosen** | Keeps each function-skill the single source of its function; resolves overlap once; routing depth stays <=2 under the existing C1 bound; the skill-boundary test bounds Specialist proliferation. |
| **(B) Absorb — each role-skill re-implements the functions it needs** | Rejected | Forks the source of every absorbed function; two skills drift apart over time; explodes maintenance (every function lives in N places); defeats the single-source property the 22 function-skills exist to provide. |
| **(C) No ADR — leave the decomposition axis implicit** | Rejected | The role-skill build is large and cross-cutting; without a recorded rule, each role-skill author re-derives (or fails to derive) the compose-not-absorb discipline, and the overlap pairs get duplicated piecemeal with no review gate to catch it. |

## Reversibility

**MODERATE / Confidence HIGH.** The decision is referenced by the role-skill build's
authoring discipline and becomes a review gate; re-drawing the decomposition axis after
Specialists are built is a multi-surface change, because every role-skill's composition
structure rests on it. It introduces no data migration and no schema change.
Pre-build — before any Specialist is authored against the rule — the change is CHEAP;
it crosses to MODERATE at the first role-skill authored under the rule, since from that
point a reversal re-casts that skill's composition structure.

## Related ADRs

- [ADR-004 — Five-Function Spine](ADR-004-five-function-spine.md) — establishes that
  role skills compose against the Primary Function name as a stable vocabulary. This
  ADR is the decomposition-axis rule that operationalizes *how* they compose: thin
  Specialists over shared function-skills. Direct upstream.
- [ADR-006 — Skill-to-module map](ADR-006-skill-to-module-map.md) — the 22-skill /
  3-module partition that this ADR's "22 function-skills" Context rests on; the
  function-skills a Specialist composes are exactly that roster.
- [ADR-016 — intake front door as a distinct architectural component](ADR-016-intake-front-door-architectural-boundary.md)
  — sibling skill-architecture boundary ADR; the same verb-disjoint-component
  discipline (intake authors, ppm-agent processes, architecture authors ADRs) that this
  ADR extends to the role-versus-function axis.
- Cascade rule **C1 (depth bound: max 2)** at
  [`agent-handoff-framework.md`](../standards/agent-handoff-framework.md) — not an ADR,
  but the load-bearing mechanism: the `cascade_depth >= 2` refusal that makes the
  "routing depth <=2" consequence enforceable. This ADR cites C1; it does not modify it.

## References

The issue and initiative numbers below are provenance for this record; the prose above
leads with self-describing roles so the meaning survives renumbering. This block is the
designated reference home.

- The skill-pipeline alignment audit — the reconciliation venue that performs the
  pair-by-pair EXTEND-versus-build-new reconciliation citing this ADR as its governing
  principle: #2.
- The role-skill suite epic and its phase tickets — the downstream build this ADR
  gates: #284 (and the per-phase role-skill tickets it tracks).
- The adopting decision-record intake — where the operator adopted the decision on
  2026-06-06: #406.
