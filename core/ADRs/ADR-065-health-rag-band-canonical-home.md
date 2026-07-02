<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-065 — Health-RAG band canonical home: channel-formats.md is the retained owner; the metric registry stays the referencing index; the watermelon concept is single-sourced to watermelon-detection.md"
status: Accepted
date: 2026-07-01
release: 105-knowledge-corpus-tail-closeout
tags: [health-rag, canonical-home, metric-registry, channel-formats, watermelon, duplicate-source-discipline, operations, cross-module, placement-correctness]
source_observations:
  - "Originating gap (#930): v1.18 added the canonical metric-registry.md (#271) and watermelon-detection.md (#270), but the formula-driven health-RAG bands (SPI/CPI/Risk/Scope) + a watermelon-detection rule were already defined inline in operations/skills/comms-writer/references/channel-formats.md § RAG Threshold Standards, and the word 'watermelon' appears across a spread of corpus files. The observation flagged the canonical bands living in a comms-writer doc as a placement smell and asked for a short ADR to record the canonical-home decision."
  - "Live-state reconciliation (Stage 5 survey, 2026-07-01): the reference direction is ALREADY one-directional — metric-registry.md:12 self-declares as an INDEX that REFERENCES channel-formats.md § RAG Threshold Standards for the project schedule/budget/risk/scope bands, and channel-formats.md carries NO edge back to the registry (grep: metric-registry|weekly-status-rollup/references/metric in channel-formats.md → 0 matches). No reference cycle exists in live state; the A6.5 adversarial review (PR-1) proved the 'break the R1 cycle' framing rested on a future-conditional of a candidate edit, not a present-state anomaly. The load-bearing, sound premise is placement-correctness: the bands are owned in a doc whose Purpose disclaims metric governance while a self-declared metric INDEX references them."
  - "Watermelon-usage split (live grep, 2026-07-01): the W1–W8 signal SET is already single-sourced to core/skills/pmo-qa-auditor/references/watermelon-detection.md ('the canonical home of the watermelon signal set'), and its consumers (weekly-status-rollup, pmo-portfolio-manager, pmo-qa-auditor detectors) already REFERENCE it — no fork exists. The remaining 'watermelon' mentions are the generic green-outside/red-inside anti-pattern TERM in prose (passing mentions, analogies, and a legitimately-distinct failure-mode catalog entry), not forks of the signal set."
---

# ADR-065 — Health-RAG band canonical home (channel-formats.md retained as owner; watermelon single-sourced)

## Status

Accepted — operator-ratified at this release's Collective Review scope-lock (the Status-enum gate the core-ADR README names: "Operator-ratified at Collective Review or equivalent gate"). Authored at Stage 6 per the Stage-6 ADR-authoring precedent (core-module-boundary → operations-consume-via-public-api → memory-corpus-SSOT → methodology-conditional-activation → substrate-vs-canonical).

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/`, resolved at the authoring commit with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. Referenced downstream **by slug**, never by number. Extended or reversed only by a **successor / superseding ADR** — never by an in-place edit of this record.

**Deliberate `deciders`-field omission.** This ADR is authored **without** a `deciders` frontmatter field, pending #1487/#1488 (the literal-name `deciders` convention is not yet ratified). The core-ADR README frontmatter template lists `deciders`; this ADR is a deliberate exception to that template until #1487/#1488 resolve. The omission is not a defect — do not add the field before the convention lands.

## Context

The formula-driven health-RAG bands — **Schedule (SPI)**, **Budget (CPI)**, **Risk**, and **Scope** — plus the transparent worst-component roll-up rule are defined inline in `operations/skills/comms-writer/references/channel-formats.md` § RAG Threshold Standards. The self-declared canonical cross-level metric **INDEX**, `operations/skills/weekly-status-rollup/references/metric-registry.md`, **references** those bands (its Project Metrics rows carry `referenced:channel-formats.md:NNN` provenance and it names `channel-formats.md` as the band owner at its INDEX declaration).

Two framings of #930 were carried into design:

1. A **placement-correctness** framing — the canonical health bands live in a *comms-format* doc whose Purpose ("communication channel inventory, format specifications, status-aggregation cadences") disclaims metric governance, while a doc that self-declares as the canonical metric INDEX references them. This is the "placement smell" the observation names, and it is **real** (verified: `channel-formats.md` Purpose carries no metric-governance claim; `metric-registry.md` self-declares as the cross-level index).
2. A **reference-cycle** framing — that making `channel-formats.md` reference the registry (AC-2 read literally) while the registry still references `channel-formats.md` would create a `channel-formats → metric-registry → channel-formats` cycle, and that breaking it is the load-bearing design act.

The adversarial design review (Stage 5 Phase A6.5, PR-1) **rejected the reference-cycle framing as a live premise**: a grep of `channel-formats.md` for any edge to the registry returns zero matches — the only live edge is the one-directional `metric-registry → channel-formats`. **No cycle exists in current state.** The "cycle" is a future-conditional that would arise only from a candidate edit (making channel-formats reference the registry while leaving the back-reference), not a present anomaly. It is a property any correct design must AVOID CREATING, not a live requirement to satisfy — trivially true of a lighter design that never introduces the reverse edge.

Independently, the observation asked to single-source the **watermelon** concept to `watermelon-detection.md`. The live corpus already keeps two usages cleanly separate:
- **Usage class 1 — the W1–W8 signal set:** already single-sourced to `watermelon-detection.md` (self-declared canonical home); its consumers reference it, none fork it. AC-3's "one definition + references, no forked re-definition" is already met for the signal set.
- **Usage class 2 — the generic green-outside/red-inside anti-pattern term:** prose mentions, analogies, and a legitimately-distinct failure-mode catalog entry (`failure-mode-standard.md` "Watermelon RAG acceptance — INPUT", which `watermelon-detection.md` reciprocally cross-references). These are not forks of the signal set and must not be mechanically rewritten — a passing mention of an anti-pattern is not a second definition needing single-sourcing.

## Decision

**`operations/skills/comms-writer/references/channel-formats.md` § RAG Threshold Standards is the canonical home of the health-RAG bands (Schedule/SPI, Budget/CPI, Risk, Scope) and the transparent worst-component roll-up rule. It is retained as the owner; the bands are NOT moved.**

Concretely:

1. **`channel-formats.md` stays the band owner.** No ownership move. The bands are defined once, there, and every consumer references them from that home.
2. **`metric-registry.md` remains the INDEX that references those bands** (`referenced:channel-formats.md:NNN` provenance on its Project Metrics rows; the band-owner bullet at its INDEX declaration). This is the existing, correct, one-directional reference posture — the registry is the single place a reader consults to find *which* metric drives a color at *which* level, and it points at the band's owning doc for the SPI/CPI/Risk/Scope numbers. No back-reference is added from `channel-formats.md` to the registry, so **no reference cycle is created** — consistent with the live one-directional edge the A6.5 review verified.
3. **The watermelon *concept* is single-sourced to `core/skills/pmo-qa-auditor/references/watermelon-detection.md`.** The W1–W8 signal set already lives there and is consumed by reference (no fork). The prose sites that come closest to a *second definition or expansion* of the detection concept carry a **see-also pointer** to that canonical home; passing mentions and analogies are left untouched (over-rewriting them would be scope-creep — a mention is not a fork).

**AC-2 is relaxed by operator decision (Option A′).** #930's AC-2 as literally worded expected `channel-formats.md` to *reference* the canonical home rather than define the bands inline. Under the retained-owner decision that phrasing does not apply (channel-formats IS the home). Per distill-intent-not-remediation, the AC-2 *intent* — a single canonical home for the bands, no scattered forks — is served: the bands have exactly one home (`channel-formats.md`), the registry references it, and no forked band definition survives. AC-2 is recorded as satisfied in spirit ("canonical ownership documented + watermelon single-sourced"), not by the literal "channel-formats references the home" mechanic.

**The rationale is placement-correctness + literal-intent AC satisfaction — NOT "break the R1 cycle."** There is no live cycle to break (A6.5 PR-1). The decision to keep `channel-formats.md` as owner is a conscious choice to accept the current placement (bands in the comms-format doc) rather than pay a ~15-site ownership-move cascade for a K1-hygiene good, given that the existing reference graph is already acyclic and single-owner.

## Alternatives Considered

- **(A) Move ownership to `metric-registry.md`; `channel-formats.md` references it; delete the registry's back-references.** REJECTED at the Collective-Review scope-lock in favor of the lighter Option A′. The move would satisfy AC-2 literally and place the bands in the self-declared metric INDEX (a genuine placement-correctness good), but it is a MODERATE ~15-site reference-repoint cascade across 4 skills / 2 modules whose headline "break the cycle" justification does not hold (no live cycle). It also under-scopes a real value-fork at `estimation-standards.md` §7 (see Consequences / FM-1). Given the existing graph is already acyclic and single-owner, the cascade buys placement-correctness only — the operator chose not to pay it this release.
- **(C) New shared `core/standards/health-rag-bands.md`; both `channel-formats.md` and `metric-registry.md` reference it.** REJECTED under reuse-first / minimal-addition — a self-declared canonical home already exists; the bar for a new governance file is *necessary*, not *plausible*.
- **Mechanically rewrite every "watermelon" prose mention to reference `watermelon-detection.md`.** REJECTED — the signal set is already single-sourced (no fork); the remaining mentions are passing references, analogies, and a distinct failure-mode catalog entry. Rewriting them would be over-reach against the surgical-edit / minimal-change discipline.

## Consequences

- **+ One canonical band home, acyclic single-owner graph, recorded.** The band ownership question #930 raised is now settled and citable: `channel-formats.md` owns; `metric-registry.md` indexes; the edge is one-directional. Future readers stop re-deriving the ownership direction.
- **+ Watermelon concept single-sourced.** The signal set stays single-sourced to `watermelon-detection.md`; the prose sites that expand the concept now point at it; no fork survives.
- **− Placement smell accepted, not fixed.** The bands still live in a comms-format doc rather than the metric INDEX. This is a conscious LOW-cost residual (the reference graph is correct; only the *home doc's topic* is arguably off). Should a future release want the bands in the metric registry, Option (A) remains available as a follow-on ownership move — but it is not urgent (no cycle, no fork).
- **− FM-1 residual (`estimation-standards.md` §7).** `operations/skills/delivery-engine/references/estimation-standards.md` §7 (Milestone-Variance RAG) restates the SPI bands inline (🟢 ≥0.95 / 🟡 0.85–0.94 / 🔴 <0.85) with an explicit "adopted by reference from the platform-canonical Schedule-RAG standard in the comms-writer reference doc" anchoring note. Under Option A′ that anchoring note points at the **retained** canonical owner and remains valid — it is an explicitly-provenanced co-located restatement, not a silent orphaned fork (the ownership-move failure mode FM-1 warned of does not arise because there is no move). Converting the inline table to a pure pointer is a reference-durability hygiene improvement **outside the LIGHT #930 scope** (it is a delivery-engine estimation-standards concern) — filed as a follow-on `improvement.yml`, not folded into this release.

## Reversibility

**CHEAP / Confidence HIGH.** The decision RECORDS a retained-owner posture (no file content moves) plus two additive see-also pointers. `git revert` of the release PR restores prior state — no data migration, no routing primitive / schema / executable touched, band values byte-unchanged.

## Related ADRs

- **ADR-028** (operations consume core safety-controls via-public-api) — establishes the one-owner-of-truth posture for the co-located watermelon *signal set* and notes the two docs are bidirectionally coupled through `metric-registry.md`. ADR-065 records that the *band* half of that coupling is already single-direction (registry → channel-formats) and keeps it that way, single-sourcing the watermelon *concept* consistently with ADR-028's single-sourcing of the signal set.
- **ADR-007** (cross-module doc-link posture) — the operations↔operations and operations→core reference edges ADR-065 relies on are sanctioned markdown-doc-links, not code edges.
