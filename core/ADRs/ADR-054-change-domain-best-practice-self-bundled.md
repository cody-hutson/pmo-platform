---
title: Change-domain best-practice stays self-bundled in change-management; framework-catalog is its registry (no shared domain-best-practices/change.md)
status: Proposed
tags: [domain-best-practice, change-management, framework-catalog, duplicate-source-discipline, adr-019-composition, self-bundled, single-source]
---
<!-- reference-durability: allow-link -->

# ADR-054 — Change-domain best-practice stays self-bundled in change-management; framework-catalog is its registry (no shared domain-best-practices/change.md)

## Status

Proposed (skill-anchoring release). Authored at Stage 6 alongside the artifacts it governs, per the core-ADR convention (a decision captured as a committed ADR document written in the same release as the artifact it governs).

**Deciders:** operator · **Date:** 2026-06-30

## Context

The platform codifies a per-domain best-practice posture (the Build-Philosophy "Best Practice per Domain" value). Three K1 shared best-practice guides exist under `core/standards/domain-best-practices/` — `software.md`, `governance.md`, `process.md` — each a universal design-time anchor that one-or-more **peer designer skills** cite by reference (ADR-019 compose-by-reference). The software guide is the precedent: it is skill-wired because **five** software-domain specialists consume it as a shared anchor; the shared-guide form earns its keep precisely when **multiple peer consumers** would otherwise each carry a private copy of the same domain practice.

The change domain is differently shaped. Its methodology body — ADKAR, Kotter 8-Step, Lewin 3-Stage, Bridges Transition, McKinsey 7-S — is **already single-sourced and in-platform-codified** inside `operations/skills/change-management/references/` (one dedicated reference doc per framework), and **already registered** in `core/specs/framework-catalog.md` (five EXTERNAL rows, `canonical_doc` paths populated as of the `pmo-skill-reference-substrate` release). There is exactly **one** change-domain consumer of this body — the `pmo-ocm-lead` specialist — and it does not cite the references directly: it composes the `change-management` function-skill (ADR-019) and reaches the methodology suite **transitively** through that composition. The "multiple peer consumers" condition that justifies a shared extracted guide is **absent** here.

The open question this ADR resolves: should the change domain get a fourth shared guide — `core/standards/domain-best-practices/change.md` — to sit alongside software/governance/process for surface symmetry?

## Decision

**No shared `domain-best-practices/change.md` is created.** The change-domain best-practice body **stays self-bundled** in `change-management/references/` (its single source), and `framework-catalog.md` is its **registry**. The decision rests on three grounds:

1. **Cite-not-restate (single-source discipline).** The frameworks are already in-platform-codified in dedicated reference docs. A shared `change.md` would either restate that body (a second source to keep in sync — the exact drift target `duplicate-source-discipline.md` forbids) or be a thin pointer file that adds a hop without adding a consumer. Per `duplicate-source-discipline.md`, an extracted guide must earn itself by serving consumers a private copy would otherwise duplicate; here it would not.

2. **The catalog already provides the single registry.** `framework-catalog.md` is the platform's registry surface for codified frameworks; the five change rows already discharge the "where is this domain's practice registered" question. A second registry (a guide's `frameworks_cited` list) would duplicate the catalog's role.

3. **The sole consumer reaches the body transitively (ADR-019).** `pmo-ocm-lead` composes `change-management`; it does **not** need — and should **not** add — a direct shared-guide cite. A direct cite would (a) re-introduce a second source path to the same body and (b) take the ADR-019-discouraged direct path where a compose-by-reference path already exists. The composition seam is the correct and only access path.

`pmo-ocm-lead/SKILL.md` is therefore left **intentionally unchanged** by this decision: adding a direct best-practice cite to it would violate this ADR's own grounds (2) and (3).

## Reversal trigger

Revisit this decision and **promote the change-domain body to a shared `domain-best-practices/change.md` guide** IF a **second *peer* change-domain *designer* skill** is introduced (i.e., a second consumer that would design against the change methodologies directly, not merely compose `change-management`). That is the "multiple peer consumers" condition the software-guide precedent rests on; when it holds for the change domain, the shared-guide form earns its keep and the cite-not-restate calculus flips. Until then, the self-bundled form is single-source-optimal.

## Options considered

| # | Option | Trade-off | Verdict |
|---|---|---|---|
| A | **Self-bundled in `change-management/references/`; `framework-catalog.md` is the registry; no shared guide** (chosen) | Single source preserved; zero new pointer/restate surface; the one consumer reaches the body via ADR-019 composition; surface asymmetry vs the three shared guides is cosmetic, not a governance gap. | **CHOSEN** — single-source-optimal; the shared-guide form has no peer-consumer to serve, so it would be pure drift surface. |
| B | Create a shared `domain-best-practices/change.md` for symmetry with software/governance/process | Visual parity in the `domain-best-practices/` set, but either restates the codified body (second source / drift target) or is a thin pointer adding a hop with no consumer; would invite a direct `pmo-ocm-lead` cite that bypasses the ADR-019 composition path. | Rejected — symmetry is not a consumer; violates cite-not-restate and the ADR-019 single-access-path posture. |
| C | Add a direct best-practice cite to `pmo-ocm-lead/SKILL.md` (point it at the references or the catalog) | Makes the change-domain anchor explicit on the consumer, but introduces a second access path to a body already reached transitively, against ADR-019. | Rejected — the composition seam already provides access; a direct cite is a redundant, discouraged path. |

## Consequences

- **Positive:** the change methodology body keeps a single source; `framework-catalog.md` remains the one registry; `pmo-ocm-lead` keeps its clean ADR-019 composition path with no redundant cite; the Build-Philosophy matrix can name the enforcer (`framework-catalog` + the `change-management` reference suite, skill-self-bundled) without a fourth guide file to maintain.
- **Negative / residual:** the `domain-best-practices/` set is asymmetric (three guides, change handled differently) — a cosmetic, not load-bearing, difference; the Build-Philosophy "BP — change" row records the self-bundled handling so the asymmetry is **named, not silent**. The decision is re-openable by the stated Reversal trigger if a second peer change-designer skill appears.
- **Reversibility CHEAP** (no file created; the position is recorded in this ADR + one matrix row + two one-line cites; revertable in one PR). **Confidence HIGH** (composes `duplicate-source-discipline.md`, the `framework-catalog.md` registry, and ADR-019 — no new primitive invented; the software-guide precedent supplies the peer-consumer test directly).

## Composition

Composes [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md) (the cite-not-restate / register-or-remove rule this decision applies), the [`framework-catalog.md`](../specs/framework-catalog.md) registry (the change rows that satisfy registration), and [ADR-019](ADR-019-specialists-compose-not-absorb.md) (compose-by-reference — the transitive access path `pmo-ocm-lead` uses). Recorded as a "BP — change" acknowledgement row in [`build-philosophy.md`](../disciplines/build-philosophy.md) (§Coverage matrix + §Enforcer citations), and cited as the registered-source pointer in [`change-management/SKILL.md`](../../operations/skills/change-management/SKILL.md) `## Reference docs`.
