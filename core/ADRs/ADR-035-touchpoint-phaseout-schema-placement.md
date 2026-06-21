<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-035 — Operator-touchpoint inventory + phase-out-plan schema — tracked in core/schemas/, instance operator-local, validated by deploy.sh Check 39
status: Accepted
date: 2026-06-20
release: 71-autonomy-phaseout-foundation (v2.12)
deciders: "Workspace owner (operator-adopted at the 71-autonomy-phaseout-foundation Collective Review scope-lock); design authored at Stage 5 Solutioning (the Principal Engineer — Architecture Assessment + Research-Methodology Design spoke, #165); ADR materialized at Stage 6 per the ADR-007 / ADR-028 / ADR-033 / ADR-034 Stage-6 ADR-authoring precedent"
tags: [architecture, governance, artifact-class, file-placement, schema, autonomy-phaseout, deploy-check, reversibility]
source_observations:
  - "#165 Stage-5 finding: the deliverable spans three artifacts across two management classes — a touchpoint-inventory schema, a phase-out-plan schema, and a populated instance (≥13 inventory rows + 3 CHEAP pilot phase-out rows). The schemas are reusable grammar (universal — every deployment's pipeline has touchpoints); the populated instance is one operator's specific touchpoints, phases, dates, and pilot selections. The K1-grammar / K4-instance split (already used by work-item-type-schema.md and entity-field-schemas.md) is the established pattern this follows."
  - "#165 Stage-5 finding: core/schemas/ is defined (README) as 'the typed-format definitions that agents and gates validate documents and handoffs against' — exactly what a touchpoint/phase-out schema is (a field-set contract a structural check validates an instance against). core/standards/ hosts normative 'what good looks like' rules, not contracts. The grounding for the schemas-home 'gates validate against' claim becomes true at ship via a minimal deploy.sh --check structural validator."
---

# ADR-035 — Operator-touchpoint inventory + phase-out-plan schema: tracked schema, operator-local instance, Check 39 validator

## Status

**Accepted.** Operator-adopted at the Collective Review scope-lock for `71-autonomy-phaseout-foundation` (v2.12). Design authored at Stage 5 Solutioning (the Principal Engineer — Architecture Assessment + Research-Methodology Design spoke, parent task `#165`); ADR materialized at Stage 6 post-build per the ADR-007 / ADR-028 / ADR-033 / ADR-034 Stage-6 ADR-authoring precedent. Ships in the v2.12 release PR (reviewed at Stage 9, Deep per the `novel` release class). The next gap-free ADR number after 034 is 035 (`check-adr-numbers.py` enforces platform-wide-unique, gap-free numbering; ADR-034 is the companion `#164` progressive-rollout-convention placement decision).

## Context

`#165` produces three artifacts: a **touchpoint-inventory schema** (the 16-field grammar enumerating where humans gate the pipeline), a **phase-out-plan schema** (the per-pilot planning overlay — success criteria, SLO, FMEA risks, rollback path, phase sequence — keyed on the inventory's `touchpoint_id`), and a **populated instance** (≥13 inventory rows + 3 CHEAP pilot phase-out rows + a phase-state roll-up matrix).

Three placement / mechanism questions arise:

1. **Which tracked tree for the schema** — `core/schemas/` or `core/standards/`?
2. **One combined schema doc or two files** — the inventory and phase-out schemas are coupled by a foreign key (`touchpoint_id`); does the coupling argue for one doc?
3. **Does the populated instance go tracked or operator-local**, and how is the schemas-home "gates validate against" grounding made true at ship?

The bounding constraints: the `.gitignore` seam git-ignores `personal/`, `pmo-instance/`, and the three `*/governance/roadmaps/` trees; ADR-012 de-scoped roadmap *instances* to operator-local authoring while retaining the roadmap *framework* as tracked convention; the companion `#164` progressive-rollout convention (`core/standards/progressive-rollout-convention.md`) owns the phase enum this schema's `current_phase` consumes.

## Decision

1. **Both schemas → one combined doc in `core/schemas/`** at `core/schemas/touchpoint-phaseout-schema.md`. `core/schemas/` is defined (its README) as "the typed-format definitions that agents and gates validate documents and handoffs against" — the touchpoint/phase-out schemas are exactly that (a field-set contract a structural check validates an instance against). `core/standards/` hosts normative rules ("what good looks like"), not contracts. Peer precedent: `entity-field-schemas.md` and `work-item-type-schema.md` are field-set schemas in `core/schemas/`. **One combined doc, not two**, because the two schemas are one coherent contract — the phase-out plan's rows key on the inventory's `touchpoint_id`; splitting them would force a cross-file foreign-key seam with no offsetting benefit.

2. **The populated instance → operator-local** (the git-ignored operator-instance / roadmaps seam), never committed. The instance carries one operator's specific touchpoints, phases, dates, and pilot selections — operator-instance planning data, the same class ADR-012 de-scoped. Only the *grammar* is tracked (template purity — the template downloader receives the reusable contract, not one operator's touchpoint data). Consequently AC1/AC3/AC5 are satisfied by spoke evidence against the instance, not by a PR diff.

3. **`current_phase` references `#164`'s phase enum by name**, not by a hard-coded value list. The progressive-rollout convention is the single home of the phase vocabulary; this schema consumes it by reference (parameterize-over-hardcode; register-or-remove). A `#164` D-PhaseNames change propagates without re-authoring this schema. The schema also carries a subject-disambiguation note (CDF-1): it reuses `#164`'s phase *values* to describe the **touchpoint's** automation state — the inverse-autonomy reading of the convention's mechanism-rollout ladder (`enforce` = the human still gates; `removed` = the gate is automated/retired).

4. **A minimal `deploy.sh --check` structural validator (Check 39)** makes the schemas-home "gates validate against" grounding true at ship. Check 39 validates an instance structurally (field presence + type/enum shape — not the content of the operator's judgment). It **skips cleanly when the instance is absent** (the instance is operator-local / git-ignored, so it does not exist in a fresh clone or CI — mirroring Check 13's "deploy never run → skip, don't double-fail" posture). It ships **warn-mode-initial** through the shared deploy-check mode machinery (`flag_warn_or_issue` / `deploy-check.mode`), dogfooding the `shadow`/`warn` phase of the very convention this release ships; flip to `enforce` after the shakedown window.

## Consequences

- (+) The template downloader receives the reusable contract, not one operator's touchpoint data — template purity preserved.
- (+) Consistent with the established K1-grammar / K4-instance pattern (`work-item-type-schema.md`, `entity-field-schemas.md`) and with ADR-012's operator-local-instance posture.
- (+) The `release-class-taxonomy.md` future-sibling block (which reserved the touchpoint-inventory composition surface) resolves to a tracked schema — the one tracked-corpus reciprocity edge closes.
- (+) `current_phase` cannot drift from `#164`'s enum by construction (reference-by-name), and Check 39 catches an instance that uses an out-of-enum phase value.
- (−) `#165`'s PR is "thin": the tracked half is one schema doc + one README index row + one taxonomy reciprocity line + the Check 39 block. The instance + 3 pilot rows + the AC4 roadmap edit are spoke-evidenced-only, so Stage 13 closure must cite both surfaces (the PR diff AND the sub-task evidence comment).
- (−) Check 39 runs against an operator-local instance, not a PR diff — so in CI / a fresh clone it always SKIPs (by design). Its enforcement value accrues on the operator's machine once an instance exists.

## Reversibility

**CHEAP** (HIGH confidence). The tracked half reverts via a PR revert (one new schema doc, one README index row, one taxonomy line, one deploy.sh check block). The operator-local instance is an operator file delete. No tracked consumer depends on the schema except the `release-class-taxonomy.md` future-sibling line, which reverts in the same PR. Check 39 is additive and warn-mode-initial, so its removal cannot break a previously-green check.

## Related ADRs

- ADR-034 — the companion `#164` decision: the pipeline-wide progressive-rollout convention (lift-and-extend the executor model, add the terminal `removed` phase). This schema's `current_phase` consumes that convention's enum — the load-bearing consistency contract between the two `71-autonomy-phaseout-foundation` deliverables.
- ADR-012 — roadmap-instance de-scope: establishes the operator-local-instance posture this ADR applies to the populated touchpoint inventory.
- ADR-018 — the work-item type-layer (K1-grammar / K4-instance split): the pattern precedent for tracking the grammar while keeping instances operator-local.
- ADR-007 — core module boundary: places schema content under `core/schemas/`.

### Source(s)

- `#164` — pipeline-wide progressive-rollout convention; owns the phase enum this schema's `current_phase` references by name.
- `#165` — operator-touchpoint inventory + phase-out-plan schema (units 1+2); the parent task this ADR records.
