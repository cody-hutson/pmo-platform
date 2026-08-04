<!-- reference-durability: allow-link -->
---
title: ADR-028 — Operations skills consume core safety-control references via-public-api, not by fork
status: Accepted
date: 2026-06-15
release: 02-FNH-est-lifecycle-status-hardening (v2.01)
deciders: "Cody Hutson (decision adopted 2026-06-15 at the v2.01 Collective Review scope-lock)"
tags: [architecture, skill, cross-module, safety-control, watermelon, via-public-api, fork-avoidance, reversibility]
source_observations:
  - "weekly-status-rollup (#256) needs the 8-signal watermelon set to scan portfolio projects for green-outside/red-inside status. The complete W1-W8 set is already authored and owned by core/skills/pmo-qa-auditor/references/watermelon-detection.md, which self-declares it is 'the canonical home of the watermelon signal set' with severity tiers, false-positive filters, and a verdict-composition algorithm."
  - "The Stage-4 plan recommended a roll-up-LOCAL COPY of the signals 'for module independence.' The Stage-5 design dissented: the operations -> core direction is explicitly enumerated as permitted in operations/README.md, and ADR-007 treats markdown-doc-link cross-module references as accepted cohesion (only code-import cycles are a BLOCKER) — so the reference is pre-authorized and a local copy would fork an owned safety control."
  - "The two docs are already bidirectionally coupled: watermelon-detection.md references metric-registry.md (owned by weekly-status-rollup) for every threshold its signals key off, and metric-registry.md's Consumers table already names watermelon-detection.md. A third forked surface would diverge on a green-masking control the moment the qa-auditor refines a signal, and skill-deployment.md Check 13b (shared-reference collision detection) flags a basename carried by two skills."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-028 — Operations skills consume core safety-control references via-public-api, not by fork

## Status

Accepted. The operator adopted the decision at the v2.01 (`02-FNH-est-lifecycle-status-hardening`)
Collective Review scope-lock on 2026-06-15, reversing the Stage-4 plan's local-copy recommendation
in favor of the Stage-5 design's via-public-api recommendation. This ADR is the committed record of
that adopted decision (convention-consistent with ADR-023's operator-adopted → ratified-at-gate
pattern). It is authored at Stage 6 per the ADR-007 precedent of Stage-6 ADR authoring.

**Renumbered 2026-06-18: ADR-024 → ADR-028.** This ADR was originally filed as ADR-024 but
collided with the earlier `release/ADRs/ADR-024-cross-release-impact-model.md` (2026-06-13), which
had correctly claimed 024 as the next-free slot platform-wide. Per the platform-wide-monotonic
numbering rule (`core/ADRs/README.md` § Naming convention), the later claimant is renumbered to the
next free slot (028); the decision content is unchanged. See #1345 (observation) and #1352
(resolution + CI guard).

## Context

`weekly-status-rollup` (an **operations**-module skill) adds a portfolio watermelon scan that runs
the 8-signal set (W1–W8) to catch a project that is green-on-the-outside-red-on-the-inside. That
signal set already exists — fully specified, with severity tiers, false-positive filters, and a
verdict-composition algorithm — in `core/skills/pmo-qa-auditor/references/watermelon-detection.md`,
which self-declares it is **the canonical home of the watermelon signal set**. The `pmo-qa-auditor`
(a **core**-module skill) *applies* these signals as the platform's watermelon backstop.

The Stage-4 plan recommended a roll-up-**local copy** of the signal set "for module independence."
That framing overstates the cost and mis-locates the risk:

- The `operations → core` direction is **explicitly permitted** —
  [`operations/README.md` § Cross-Module Dependencies](../../operations/README.md) enumerates
  `core/skills/pmo-qa-auditor` as a permitted reference ("output audits").
- [ADR-007](ADR-007-core-module-boundary.md)'s architectural invariant is **0 code-import cycles**;
  a markdown-doc-link / role-name reference is **accepted cohesion**, not a boundary violation. The
  reference is *pre-authorized* — it creates no new edge type.
- The two docs are **already bidirectionally coupled**: `watermelon-detection.md` references
  `metric-registry.md` (owned by `weekly-status-rollup`) for every threshold its signals key off,
  and `metric-registry.md`'s Consumers table already names `watermelon-detection.md`. The coupling
  exists and is governed by duplicate-source-discipline (one owner per threshold).

A local copy does not remove the coupling; it adds a **third surface** — a forked signal-set — on
top of the existing two-way link. The moment the `pmo-qa-auditor` refines a signal (e.g., tightens
W3's false-positive filter), the roll-up's copy silently diverges, and on a **green-masking control**
divergence is the exact failure the control exists to prevent. `skill-deployment.md` Check 13b
(shared-reference collision detection) would additionally flag a `watermelon-detection.md` basename
carried by two skills.

This is the cross-module-consumption analogue of [ADR-023](ADR-023-skill-sourcing-coupling-posture.md)
(which governs the skill ↔ *Anthropic* sourcing axis): ADR-023's own-with-harvest default exists to
keep a single owned source of truth; this ADR applies the same single-owner principle to the
operations ↔ core *safety-control* consumption axis.

## Decision

**An operations skill that needs a core safety-control reference consumes it via-public-api by
role-name — it does NOT fork (copy) the control into a module-local file.**

Concretely, for `weekly-status-rollup` #256: the roll-up's Section 7 Watermelon Scan names the
signal set by role ("run the 8-signal watermelon scan W1–W8 per `watermelon-detection.md`, owned by
`pmo-qa-auditor`") and consumes the verdict-composition rule **by reference**. It does **not** restate
or copy the W1–W8 signals. `metric-registry.md` (owned by the roll-up) records the reciprocal note
that the signal set now has two active consumers — the auditor and the roll-up — both reading the
single canonical home.

The rule generalizes: a **safety control** owned in `core/` (a green-masking detector, an
evidence-integrity check, a guardrail definition) is consumed by an operations skill through the
documented `operations → core` Public API as a markdown-doc-link / role-name reference, never
forked. This holds because:

1. **The direction is pre-authorized.** `operations → core` references are enumerated-permitted
   (`operations/README.md`) and are accepted cohesion under ADR-007 (only code-import cycles are a
   BLOCKER). There is no boundary cost to pay.
2. **A fork creates guaranteed drift on the exact thing the control protects.** Two definitions of
   "what is a watermelon" diverge silently; a green-masking control that diverges fails open.
3. **Single-owner discipline is the platform default.** Duplicate-source-discipline and Check 13b
   already treat a same-basename reference carried by two skills as a collision to resolve, not a
   feature.

**Module-independence is preserved without a copy.** A role-name reference does not create a
code-import cycle (the only thing ADR-007 forbids), and extraction-readiness is unaffected: if
`weekly-status-rollup` were ever extracted, the reference resolves through the documented Public API
exactly as `metric-registry.md`'s existing outbound references do today. Independence is an
architectural-invariant question (cycles), not a "zero references" question.

## Consequences

### Positive

- The platform keeps **one definition** of each core safety control; an operations consumer cannot
  silently diverge from the canonical detector it depends on.
- A green-masking control (the watermelon set) cannot **fail open** through a stale forked copy — the
  consumer always reads the current signal definitions and verdict rule.
- The cross-module consumption posture becomes a **declared, auditable property** (the reference
  shows up in the consumer's `## Reference docs` as a via-public-api entry), so drift between modules
  is visible at deploy time, consistent with the modular-monolith API-contract discipline.
- No new gate or vocabulary: the rule rides the existing `operations/README.md` permitted-reference
  list and ADR-007's accepted-cohesion classification.

### Negative / cost

- The operations consumer carries a **cross-module documentary dependency** on a core reference — if
  the core doc is renamed or relocated, the consumer's link must be re-pointed. Mitigated by the
  deploy-time link checks and the `## Reference docs` declaration that surfaces the dependency.
- The single-owner constraint means an operations skill **cannot locally tune** a core safety control
  to its own needs; a needed change must be made in the core owner (where both consumers see it) —
  which is the intended behavior for a shared safety control, not a defect.

## Reversibility

**MODERATE / Confidence HIGH.** Reversal is a new superseding ADR plus, if a fork were ever chosen,
materializing the local copy and resolving the resulting Check 13b collision. Pre-application the
change is CHEAP (it documents the recommended posture the #256 build already follows); it crosses to
MODERATE once additional operations skills cite this ADR for their own core-control consumption.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| **(A) Consume the core safety control via-public-api by role-name; no local copy (this ADR)** | **Chosen** | The `operations → core` direction is pre-authorized (accepted cohesion, no code-import cycle); keeps one canonical owner of a green-masking control; module-independence is preserved because independence is a cycles question, not a zero-references question. |
| **(B) Roll-up-local copy of the W1–W8 signals (the Stage-4 recommendation)** | Rejected | Forks an owned safety control → two definitions of "watermelon" that diverge the moment the owner refines a signal; a green-masking control that diverges fails open; triggers a Check 13b shared-reference collision; adds a third surface to an already-coupled pair without removing the coupling. |
| **(C) Move the signal set to a neutral shared location owned by neither skill** | Rejected | Relocates a control the `pmo-qa-auditor` legitimately owns and applies; manufactures a new shared-ownership surface and a migration for no benefit the via-public-api reference does not already provide; contradicts the "relocate nothing" preference established in ADR-022. |

## Related ADRs

- [ADR-007 — Core module boundary lock-in](ADR-007-core-module-boundary.md) — the **substrate**:
  this ADR is an application of ADR-007's accepted-cohesion classification (markdown-doc-link /
  narrative-mention `operations → core` references are permitted; only code-import cycles are a
  BLOCKER) to the specific case of a shared safety control.
- [ADR-023 — Skill sourcing-coupling posture](ADR-023-skill-sourcing-coupling-posture.md) — the
  **sibling axis**: ADR-023 governs skill ↔ Anthropic sourcing (own-with-harvest default); this ADR
  governs the operations ↔ core *internal* consumption of a safety control. Both express the same
  single-owner-of-truth principle on different axes.
- [ADR-019 — Specialists compose, not absorb](ADR-019-specialists-compose-not-absorb.md) — the
  composition discipline: the roll-up **composes** the qa-auditor's signal set by reference rather
  than **absorbing** (copying) it, consistent with ADR-019's compose-not-absorb posture.

## References

The issue and initiative numbers below are provenance; the prose above leads with self-describing
roles so the meaning survives renumbering. This block is the designated reference home.

- The weekly-status-rollup watermelon + metric-governance card this ADR governs: #256.
- The milestone bundling this card: `02-FNH-est-lifecycle-status-hardening` (#212), release v2.01.
- The Stage-5 solutioning design that recommended the via-public-api posture (reversing the
  Stage-4 local-copy recommendation): #1223.
- The canonical safety-control reference consumed via-public-api:
  `core/skills/pmo-qa-auditor/references/watermelon-detection.md` (the watermelon-detection consumer
  link is tracked as #270 in `metric-registry.md`'s References block).
- The sibling sourcing-posture ADR this one parallels: ADR-023 (record #762).
