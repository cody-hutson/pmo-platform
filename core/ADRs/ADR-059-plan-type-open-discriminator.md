<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: plan_type is an OPEN discriminator that fills the deferred enum — no second sub-type field
status: Accepted
date: 2026-06-30
release: 21-shared-entity-storage-layout
deciders: "[operator]"
tags: [entity-field-schemas, plan-type, open-discriminator, lifecycle-extension, work-item-type-layer, reversibility-cheap]
---

# ADR-059 — `plan_type` is an OPEN discriminator that fills the deferred enum

## Status

**Proposed** — flips to Accepted at the Stage 9 review.

Number **059** — the originating release plan and the Stage-5 decision record (#2627) named **053**, but the global ADR sequence spans both `core/ADRs/` and `release/ADRs/` (one sequence; `check-adr-numbers.py` enforces it): `ADR-053` was taken in `core/ADRs/` (`ADR-053-pre-gate-eligibility-forcing-function.md`, v3.31), and 054/055/056 were already claimed in `release/ADRs/`. Reassigned to the next gap-free slot **059** at Engineering time (the same collision-reassignment the #362 ADR used). Binds atomically at Stage 12.

## Context

`entity-field-schemas.md` §3.4 (Plan entity) shipped `plan_type` as a **required discriminator with its value domain explicitly deferred** — `[ASSUMPTION–CONFIRM @ G5]`: presence enforceable now, membership owned by a later gate (G5). The originating story (#159) was titled around a *new* `plan_subtype` field, but the corpus already reserved `plan_type` with that deferred membership. Shipping a second discriminator would duplicate the contract (two fields, one concept) and violate duplicate-source-discipline.

Three forks had to settle. **(1) One field or two:** fill `plan_type`'s deferred enum, or add a parallel `plan_subtype`? **(2) Enum shape:** closed (exactly the recognized subtypes) or open (recognized-or-well-formed)? **(3) Per-subtype lifecycle:** a new state machine per subtype, or an extension of the one base machine?

## Decision

**`plan_type` is the single discriminator; #159 *fills* its deferred membership as an OPEN registry; `plan_subtype` is dropped; per-subtype lifecycle is a subtype-conditioned extension of the V-PLN-05 base machine, not a new machine.**

1. **Fill, do not fork — forced by duplicate-source-discipline.** #159 resolves `plan_type`'s `[ASSUMPTION–CONFIRM @ G5]` by registering the value set in a new `entity-field-schemas.md` §3.4a (the six go-live subtypes `comms` / `training` / `hypercare` / `cutover` / `change-management` / `raid`, plus the §5.5-inventory anchors `release` / `implementation` / `project` / `test`). A second `plan_subtype` field is rejected — it would shadow the same contract.

2. **OPEN discriminator, not closed — per the ADR-018 OPEN-discriminator family.** `plan_type` joins the same OPEN-discriminator pattern as `Work Item.work_item_type` (membership @ the C2 type layer) and `Cross-Project Dependency.dependency_kind` (membership @ G3-G4): the registered rows are the enforceable V-PLN-02 membership set; the `<extension slot>` row is the documented seam, and an unregistered-but-well-formed value WARNs at health-check rather than blocking. Presence stays required (an OPEN tail never relaxes presence — NT-PLN-3).

3. **Lifecycle is a base-machine extension, not a new machine.** The per-subtype operational-terminals (`training:delivered`, `cutover:executed`, `hypercare:closed`) are admitted as **optional pre-`archived`** states *for those subtypes only* — a subtype-conditioned extension of the V-PLN-05 base `draft → approved → active → superseded → archived`, NOT a replacement machine. Registering a new in-scope state machine in `lifecycle-states-canonical.md` §3 is DEFER-G8; this release adds only the §5 Cross-Machine Collision rows (`Plan-closed` / `Plan-delivered` / `Plan-executed`).

4. **RAID Log ≠ RAID Item.** `plan_type: raid` names the **RAID Log** (a Plan-class register). It does not alias the RAID-Item entity (`entity-field-schemas.md` §3.6), which is a *row* inside that Log. The two are distinct entities; the discriminator value is the container.

## Alternatives Considered

- **Add a parallel `plan_subtype` field** — rejected: duplicates the `plan_type` contract (two fields, one concept), violating duplicate-source-discipline; the deferred-membership socket already exists and is the correct fill point.
- **Closed enum (exactly the six subtypes)** — rejected: the §5.5 inventory already documents four more values (`release` / `implementation` / `project` / `test`), and the OPEN-discriminator family (ADR-018) is the established precedent; a closed enum would be the lone closed sibling and would force a governed schema edit for every new plan kind. Tightening an open enum later is additive; loosening a closed one is the painful direction.
- **A new state machine per subtype** — rejected: it would orphan three machines outside the registered set and fragment the Plan lifecycle; a base-machine extension keeps one machine with subtype-conditioned terminals and defers §3 registration to G8 where the whole entity Axis-1 family registers together (no half-registration).

## Consequences

- `plan_type` membership is enforceable (V-PLN-02 is no longer deferred); the plan→comms→RAID generation chain is machine-resolvable via the new X-34 (`GENERATES`) / X-35 (`DEPENDS_ON`) typed-edge rules and the §3.4b relationship matrix.
- Six per-subtype templates land under `operations/templates/plan-templates/`; `artifact-generator` and `change-management` carry a `plan_type` recognition contract (change-management binds `plan_type: change-management`).
- The X-rule range extends X-33 → X-35; the count cascade is swept across the AC build-checklist, the §4 header/coverage assertion, and the handoff.
- `plan_subtype` is retired (a one-line superseded note in `template-storage.md`); the §5.5 inventory's deferred-G5 anchors become documented OPEN-tail examples.
- §3-registration of the per-subtype operational-terminals remains DEFER-G8 — a documented, intentional residual (only the §5 collision rows ship now).

## Reversibility

**CHEAP / Confidence HIGH.** The change is a schema-doc edit + new template files + two SKILL.md recognition contracts — all git-tracked, all revertible by the single release PR. No live data is migrated under this ADR (the Plan entity's persistence shape is unchanged; only its discriminator membership is resolved). The OPEN sub-choice is the lower-regret default (tightening later is additive validation). Confidence HIGH that fill-not-fork and OPEN-discriminator are correct — both were forced by named constraints (duplicate-source-discipline; the ADR-018 OPEN-discriminator family + the §5.5 inventory precedent), not by preference.

## Related ADRs

- **ADR-018** (work-item type layer) — supplies the OPEN-discriminator convention `plan_type` joins; `Work Item.work_item_type` is the sibling deferred-membership discriminator.
- **ADR-040** (leadership-owner Person ref) — sibling additive entity-field type-lift in the same schema; precedent for resolving a deferred field without breaking readers.
- **ADR-058** (`_pmo/` entity-page SSOT) — same milestone; the entity pages a typed Plan's relationships resolve against.
