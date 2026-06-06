---
title: ADR-016 — intake-elicitor type-registry parameterization seam (forward-coupled to the work-item type system)
status: Accepted
date: 2026-06-06
release: intake-elicitation-skill
deciders: "operator + Stage 5 Solutioning (design) + Stage 5 Phase A6.5 Adversarial Design Review + Stage 5 Collective Review scope-lock (2026-06-06)"
tags: [skill, intake, parameterization, type-registry, forward-coupling, canonicalization]
source_observations:
  - "Stage 5 Solutioning (#412 design) — the intake-elicitor must elicit type- and level-specific fields against the work-item type set, but the work-item type system (#409) that would define that set is status:proposed and unshipped"
  - "AC5 [ADJUST] (Stage 4 Planning, #414) — AC5's 'binds to the #409 type registry' was re-read as 'binds to the current 4-type set via a #409-ready parameterization seam'; binding to the unshipped registry is forbidden as intake-substrate drift"
  - "Current-state survey at 2fa2240 — exactly four issue-form templates exist (.github/ISSUE_TEMPLATE/{improvement,bug,observation,adr}.yml); #409 is state OPEN, milestone null, status:proposed"
  - "Stage 5 Phase A6.5 Adversarial Design Review — verified the seam premise (do not bind to unshipped #409; bind to the current 4 via a flat table) is correct, not rejected; flat table is sufficient for the 4 current types (each is a flat field enumeration, not a conditional graph)"
  - "Stage 5 Collective Review scope-lock (2026-06-06) — design ACCEPT-WITH-CONDITIONS; ADR to be authored as a core/ADRs/ file alongside the implementation, consistent with ADR-005/006/008/011/013/014"
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-016 — intake-elicitor type-registry parameterization seam

## Status

Accepted at the intake-elicitation-skill Stage 5 Collective Review scope-lock (2026-06-06). Per the core-ADR
convention, this decision is captured as a committed ADR document rather than a GitHub issue, and is authored as a
file alongside the [`intake-elicitor`](../../operations/skills/intake-elicitor/SKILL.md) implementation in the same
release. Forward-coupled to the work-item type system (#409); this ADR is the cross-issue design contract the #409
implementer must honor.

## Context

`#412` introduces a conversational intake-elicitation skill
(`intake-elicitor`) that must elicit type- and level-specific fields against the platform's work-item type set — a
bug needs reproduction and environment, a story needs acceptance criteria and value, an initiative needs outcomes and
domain. The natural source of that type set, its hierarchy, and its per-type/per-level required fields is the
**work-item type system** proposed in `#409`.

But #409 is `status: proposed` and unshipped (verified at commit `2fa2240`: state OPEN, milestone null). The MVP must
therefore bind to **today's** four work-item types — `improvement`, `bug`, `observation`, `adr` (keyed to the four
`.github/ISSUE_TEMPLATE/*.yml` files) — while staying forward-compatible with #409 so that when the type system lands
it does not force a rewrite of the skill. Binding the skill's loop directly to #409 now would author against a
non-existent artifact, which is the intake-substrate-drift failure mode and is explicitly forbidden by the Stage 4
AC5 [ADJUST] (re-read AC5's "binds to the #409 type registry" as "binds to the current 4-type set via a #409-ready
parameterization seam").

The decision is **non-obvious** (how to bind an MVP to a type set while staying forward-compatible with an unshipped
registry) and **forward-coupled to another tracked issue** (#409) — a cross-issue design contract a future spoke must
honor. Both conditions clear the ADR threshold per [`decision-discipline.md`](../disciplines/decision-discipline.md).

## Decision Drivers

- **Parameterize over hardcode** (CLAUDE.md) — a value or set that will change (the type set, the per-type field
  maps) must reference a single source rather than be embedded inline per type.
- **Intake-substrate-drift discipline** — do not author against a substrate (the #409 registry) that has not shipped.
- **AC5** — additional types must require no skill rewrite (the parameterization is the mechanism that satisfies it).
- **The soft #409 coupling** declared in #412 — #412 was designed to ship before #409 and to deepen as #409 lands.

## Decision

**The type set, the intake hierarchy, and the per-type/per-level required-field maps live in a single data table —
[`operations/skills/intake-elicitor/references/type-map.md`](../../operations/skills/intake-elicitor/references/type-map.md)
— that the elicitation loop reads. The SKILL.md loop is table-driven and references "the type registry" abstractly;
it never branches per-type inline.**

Concretely:

1. **The seam is the file `references/type-map.md`.** Today it enumerates the four shipped types keyed to the four
   issue-form templates, plus the altitude-to-type-emphasis hierarchy and the per-type required-field maps.
2. **The SKILL.md never hardcodes per-type logic.** It points at `references/type-map.md` as the registry source and
   reads the field maps from there. A reader changing the type set edits the table, not the skill body.
3. **#409 repoints or extends the table.** When the work-item type system lands, it replaces or extends
   `references/type-map.md` (or repoints the one-line registry source in SKILL.md). No loop rewrite is required — that
   is the design intent of the seam.

## Options considered

| Option | Decision | Rejection rationale |
|---|---|---|
| **(B) A `references/type-map.md` registry table the loop reads, with a documented contract that #409 repoints/extends it** | **Chosen** | Satisfies parameterize-over-hardcode and AC5 (type growth is a single-file edit, no skill rewrite); the four current types' field requirements are flat enumerations a table expresses faithfully; the seam is additive — #409 populates it later. |
| (A) Inline per-type elicitation logic in SKILL.md | Rejected | Violates parameterize-over-hardcode; every new type forces a SKILL.md rewrite; over-fits the loop to today's four types. |
| (C) Bind directly to the unshipped #409 registry now | Rejected | Authors against a non-existent artifact — the intake-substrate-drift failure mode; the Stage 4 AC5 [ADJUST] explicitly forbids it. |

## Consequences

### Positive

- **#412 ships before #409.** The skill is unblocked by the unshipped type system; it binds to today's substrate.
- **#409 plugs in additively.** When the type system lands, it repoints/extends one file; the skill's loop is
  untouched.
- **Type growth is a single-file edit.** Adding a type is a `type-map.md` change, not a skill rewrite — AC5 holds.
- **The loop stays table-driven.** No per-type inline branches accumulate in SKILL.md as the type set grows.

### Negative

- **Deliberate forward-debt.** If #409's registry shape diverges materially from a flat markdown table — for example
  if it introduces conditional field-maps (field B required only when field A = X) or cross-type relationship/
  hierarchy edges — the seam may need a structured schema rather than a markdown table. In that case
  `references/type-map.md` is rewritten once (bounded, single-file). The seam does not *break* when #409 lands; at
  worst it is repointed to a richer file. This is accepted, anticipated forward-debt, not accidental coupling.

## Reversibility

**CHEAP / Confidence HIGH.** The seam is additive: a single data file plus an abstract reference in SKILL.md. If the
design must change (because #409's shape diverges, or the seam is abandoned), the fix is a single-file rewrite of
`references/type-map.md` and at most a one-line edit to the SKILL.md registry-source pointer. No data migration, no
downstream consumer beyond #409 (which is unshipped and will consume the seam by design).

## Related ADRs

- [ADR-008](ADR-008-deploy-sh-per-module-array-design.md) — per-module skill arrays; `intake-elicitor` registers in
  `OPERATIONS_SKILLS`, the surface this skill is deployed through.
- [ADR-012](ADR-012-roadmap-instance-descope.md) — establishes the parameterization-seam pattern at the
  roadmap-instance layer (operator-local authoring against a retained framework); ADR-016 applies the same
  parameterize-the-instance, retain-the-frame discipline at the work-item-type layer.

## Related Issues

- `#412` — the conversational intake-elicitation skill (this release).
- `#409` — the work-item type system (forward-coupled; later repoints `type-map.md`).
- `#414` — Stage 4 Release Planning (the AC5 [ADJUST] that frames the seam).
- `#417` — Stage 5 Solutioning (the design that recommends this ADR).
- Milestone: intake-elicitation-skill (#109).
