<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-025 — SIOR escalation canonicalization: single-source protocol doc + link-reference consumption"
status: Accepted
date: 2026-06-13
release: sior-escalation-discipline-across-the-comms-triage-technical
deciders: "cody-hutson (operator) + Stage 5 Solutioning spoke (#913)"
tags: [skill-suite, escalation, single-source, reference-doc, consumption-mechanism]
source_observations:
  - "SIOR (Situation/Impact/Options/Recommendation) escalation format existed inline in 8 locations at survey baseline main @ d7b6a59 (2026-06-13) with divergent structure: delivery-engine/references/dependency-rules.md §4.2 (4-column S/I/O/R table), delivery-engine/references/raid-templates.md §7 (full fenced template with 5-axis Impact + pro/con/cost Options), ppm-agent/references/proactive-follow-up-tracking.md (4-bullet S/I/O/R list), ppm-agent/references/push-to-resolve.md (inline prose + 'Escalation Without SIOR' anti-pattern), and comms-writer/SKILL.md Escalation type (S/I/Ask/Options — conflating Ask with the decision and omitting Recommendation entirely), plus narrative references in core/specs/engagement-charter.md, core/standards/output-format.md, and release/skills/pmo-skill-editor/references/suite-contracts.md. The 2026-04-18 skill review flagged 'Type 5 escalation missing SIOR Recommendation component (P1 gap).' No single canonical SIOR source or severity-threshold policy existed; each consumer implied its own."
---

# ADR-025 — SIOR escalation canonicalization: single-source protocol doc + link-reference consumption

## Status

Accepted — operator-ratified at the sior-escalation-discipline-across-the-comms-triage-technical
Collective Review scope-lock (the Stage 5 N-way-consistency gate per
[`README.md`](README.md) § Status enum). Renumbered from the Stage 5 spec's ADR-024 draft: the
in-flight PR #911 (`parallel-launch-quota-budget-gate`) claims `release/ADRs/ADR-024-…`, so this
release's ADR lands at ADR-025 to avoid a merge collision (`release/ADRs/` tops at ADR-021 on `main`;
core holds ADR-022/023; #911 claims 024). The number was re-confirmed against both `main` and PR #911
at Stage 6 commit time.

## Context

SIOR escalation discipline (Situation / Impact / Options / Recommendation) is principal-level
escalation format per KB C01 Governance §2.3. At survey baseline it lived inline in 8 files with
divergent structure (see `source_observations`), with **no single canonical source** and **no shared
severity-threshold policy** — each consumer implied its own threshold rule, and comms-writer's variant
omitted the Recommendation outright (the 2026-04-18 P1 gap). The milestone decomposes into #179
(keystone — authors the shared doc + comms-writer reference implementation), #178 (ppm-agent), #177
(pmo-technical-analyst), and #934 (delivery-engine — folded in at Stage 5 discovery). Two design forks
surfaced at Stage 4 and were deferred to Stage 5: (1) where the canonical doc lives + how consumers
consume it; (2) how the decision-owner mapping resolves an owner given that no structured authority
field exists.

## Decision

**1. Canonical home.** Author `core/standards/sior-escalation-protocol.md` as the single source for
the SIOR format, the severity-threshold policy, escalation-class examples, and the decision-owner-mapping
pattern. `core/standards/` per the ADR-007 core-module boundary (cross-skill reference standards);
`*-protocol.md` suffix per the existing format/procedure-spec convention. The doc is **presentation-neutral**
(content/structure, not rendering) so a future dual-format model can layer on it without changing it.

**2. Consumption mechanism = LINK-REFERENCE** (not `TEMPLATE_SYNC_MAP` injection). Consumers reference
the canonical by relative markdown link; the canonical is NOT injected into any skill's packaged
`references/`. Rationale: no consumer needs the spec offline-in-package; link-reference keeps the
canonical out of `skills/*/references/` so it never enters the Check 13b same-basename collision
surface, requires no `deploy.sh` change and no `.skill` rebuild for injection, and eliminates the only
cross-issue file contention (all four issues touching `deploy.sh`) the Stage 4 plan flagged.

**3. Single-source consolidation.** The canonical doc is the single source per
`duplicate-source-discipline.md` §1 option 2; the divergent inline copies reconcile to it
(cross-references replace re-definitions): ppm-agent's two inline copies at #178's Stage 6;
delivery-engine's two at #934's Stage 6; narrative SIOR mentions remain as valid pointers.

**4. Severity-threshold policy (set once here, referenced by #178/#177/#934):** CRITICAL = always;
HIGH = SIOR + stakeholder-authority check; MEDIUM = conditional-on-blocks-downstream; LOW = no.
The MEDIUM rule is the concrete "blocks a downstream deliverable/milestone/dependency" predicate
(not "optional"), resolving the #178/#177 MEDIUM ambiguity.

**5. Decision-owner mapping = read free-text `## Key People` + warn-and-route-to-PgM** when authority
data is absent (no structured `decision_owner`/`authority` field exists — verified;
`template-taxonomy.md` future-gap, `project-md-template.md` free-text only). A structured
authority schema is deferred to a separate future ticket; the mapping upgrades to read it when it ships.

## Consequences

**Positive:** one canonical SIOR source ends the divergence + the missing-Recommendation gap; a shared
threshold policy makes the suite emit consistent escalations; link-reference is the lowest-surface
mechanism (no deploy/package/Check-13b churn, no cross-issue contention); presentation-neutrality
preserves the dual-format option; graceful-degradation owner mapping ships against live state with
no schema dependency.

**Negative:** (a) consumers resolve a link rather than reading a bundled copy — acceptable since none
needs offline access; (b) the inline copies in delivery-engine remain un-reconciled until #934 lands —
acceptable, they keep working (no breaking change); (c) decision-owner mapping is free-text-bound
until a structured field ships — mitigated by the warn-and-route path.

## Reversibility

CHEAP. Additive: `git revert` of the release merge removes the canonical doc + the link edits +
the contract edit atomically; no data migration; net-new doc deletion is clean (no prior consumers).
Re-selecting injection later is a CHEAP follow-up (add `TEMPLATE_SYNC_MAP` entries + rebuild packages).

## Alternatives Considered

- **(A) link-reference + `core/standards/` home (selected).** Lowest surface; no Check-13b exposure; zero cross-issue contention.
- **(B) `TEMPLATE_SYNC_MAP` injection** — REJECTED. Buys only offline-in-package availability (unneeded); adds deploy.sh + package rebuilds + Check-7/13 surface; re-introduces the single cross-issue `deploy.sh` contention.
- **(C) copy-into-each-skill, unregistered** — REJECTED. Governance debt by construction (`duplicate-source-discipline.md` §1 violation); exactly the unregistered-duplicate failure Check 13b exists to catch.
- **(D) home in `core/specs/`** — REJECTED. `specs/` holds catalog/enum specs (failure-mode, reversibility-protocol, label-taxonomy); a cross-skill reference *standard* belongs in `standards/` (peer to evidence-grounding-standard.md).
- **(E) structured `decision_owner` schema now** — REJECTED for this release. Tier-2 scope change; expands a doc release into a schema release; deferred to a follow-up ticket.

## Related ADRs

- [ADR-007](../../core/ADRs/ADR-007-core-module-boundary.md) — core-module boundary placing cross-skill standards in `core/standards/`.
- [ADR-023](../../core/ADRs/ADR-023-skill-sourcing-coupling-posture.md) — own-with-harvest posture (comms-writer owns its escalation generation first-party; this ADR governs the shared *format*, orthogonal to sourcing).
- Composition: `duplicate-source-discipline.md` §1 (single-source rule this ADR applies).
