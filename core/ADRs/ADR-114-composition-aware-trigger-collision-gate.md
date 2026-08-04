<!-- reference-durability: allow-link -->
---
title: ADR-114 — Composition-aware trigger-collision gate — linkage suppresses WATCH, never ESCALATE
status: Proposed
date: 2026-08-04
release: skill-suite-conformance-and-usability-ac
deciders: "Workspace owner (Collective Review scope-lock, Q1 — CR-1 full package accepted); design authored at Stage 5 Solutioning, adversarially reviewed at Phase A6.5, implemented and re-measured at Stage 6 Engineering"
tags: [architecture, skills, routing, trigger-collision, deploy-check, registry, composition, dormant-capability, reversibility-cheap]
source_observations:
  - "A suite-wide run of the trigger-audit harness over all 55 audit-population skills returned ESCALATE with a maximum Jaccard of 0.733 across 1485 pairs. Four pairs sat at or above the 0.30 ESCALATE threshold and six in the WATCH band. The collisions were predominantly a role-Specialist against the function-skill it composes."
  - "Every one of the four ESCALATE pairs carries a DEPENDS_ON edge in the skill registry. A gate that skipped composition-linked pairs outright would therefore suppress 4 of 4 findings — 100% — and report PASS on the very corpus that motivated it. Of the six WATCH pairs only one was composition-linked, so the naive skip removes exactly the findings the gate exists to raise and retains exactly the ones it treats as lower priority."
  - "Scoring all 1485 pairs and cross-classifying them against the registry's DEPENDS_ON edges shows the benign composition-linked overlap topping out at 0.211 while every composition-linked defect sits at 0.300 or above. The two populations separate at the boundary the tool's existing bands already use, so no new numeric constant is required to express the rule. The separation is supported by five composition-linked observations at or above 0.20 — four defects and one non-defect — so it is corroboration for a rule chosen on other grounds, not a calibrated threshold."
  - "Raising the numeric threshold for composition-linked pairs was tested as an alternative and fails on the data: any elevation above 0.30 loses the 0.300 and 0.333 defects, which are precisely the pairs the motivating work item names as ESCALATE."
  - "Exempting a pair band produces a suppressed set that no one can re-check unless it is printed. Six composition-linked pairs currently sit within 0.034 of the exempted band's floor, and a uniform-template rewrite of role triggers was measured to produce new pairs at 0.278 — inside that band. The argument for exempting is that the suppressed set is benign, and that claim is only falsifiable if the gate emits what it suppressed."
---

# ADR-114 — Composition-aware trigger-collision gate — linkage suppresses WATCH, never ESCALATE

## Status

Proposed.

## Context

A role-Specialist skill composes a function-skill rather than absorbing it (ADR-019), and the registry stores that relationship as a `DEPENDS_ON` edge alongside a `kind` discriminator (ADR-038). One consequence is that a role and its engine *legitimately* share subject-matter vocabulary — a project manager and the delivery engine it invokes are both about backlogs, sprints, and readiness. Their `description:` trigger phrases will therefore overlap to some degree no matter how carefully they are written.

The platform now wires the cross-skill trigger-collision detector as a standing gate on `deploy.sh --check`. That forces a question the detector never had to answer while it was run by hand: how should the gate treat an overlap between two skills that are *supposed* to be related?

Three forces pull against each other.

**A gate that ignores composition re-flags benign pairs forever.** Every run would surface the same role↔engine overlaps. The predictable outcomes are alert fatigue, and — worse — pressure to degrade genuinely good trigger phrasing in order to chase a metric.

**A gate that skips composition-linked pairs is dormant on arrival.** This is not a theoretical risk; it is what the measurement shows. The composition edge *co-varies with the defect class* on this corpus: all four ESCALATE pairs are `DEPENDS_ON` pairs. A skip predicate would suppress 100% of the gate's own findings and print PASS over a corpus carrying a 0.733 collision. Shipping a check that cannot fail is the dormant-capability failure this platform has repeatedly paid for, and it would arrive wearing a verdict line.

**A gate that suppresses silently cannot be audited.** Whatever the exemption rule is, its whole justification is a claim about the suppressed set — that those pairs are benign. A claim about a set nobody can enumerate after the fact is not a claim that can be checked.

## Decision

**A pair of skills carrying a `DEPENDS_ON` edge in `core/skills/registry.md` — in either direction — is exempt from the trigger-collision gate's WATCH band, and is subject to its ESCALATE band unchanged.** Non-linked pairs remain subject to both bands.

Four properties of this decision are load-bearing:

1. **ESCALATE is never suppressed for any pair, for any reason.** Composition explains a *degree* of shared vocabulary; it never explains two skills competing outright for the same request. This is the clause that keeps the gate live: on the corpus that motivated it, the gate's day-one output under this rule is `ESCALATE 4 · WATCH 5`, not silence.

2. **No new numeric constant is introduced.** The rule reuses the tool's existing thresholds and changes only *which band applies to which class of pair*. There is no magic number to re-tune as the corpus grows, and therefore no calibration to drift. This — not the observed gap in the data — is the decision's primary justification; the measured separation at the band boundary is corroboration that the reuse is well-placed, and it rests on a thin sample.

3. **`RELATES_TO` does not confer exemption.** It is a soft catalogue affinity, not the compose-not-absorb relationship. Only `DEPENDS_ON` is read.

4. **The exemption is emitted, never silent.** The gate prints an `EXEMPT:` line naming the count and the exempted pairs on every run, pass or fail. The rule opens a blind interval between the WATCH floor and the ESCALATE threshold for exactly the class of pair the convention is reshaping, so the ledger of what was suppressed is part of the decision rather than an add-on to it.

This makes the registry's `dependencies` column a **load-bearing input to a deploy-time gate** — a new cross-artifact contract. `registry.md` was previously a catalogue and a routing view; it is now also a gate input, and an edge deleted from it silently widens what the gate reports.

## Consequences

**Positive.** The gate is live on its first run rather than green-by-construction. Benign role↔engine overlap stops generating recurring noise, so the finding list stays worth reading. Reusing the existing bands means the rule survives corpus growth without re-tuning. The `EXEMPT:` line keeps the central claim falsifiable after ship.

**Negative, and stated plainly.** A composition-linked pair that genuinely collides *within* the exempted interval is reported as a pass. That interval is reachable: several composition-linked pairs sit just below its floor today, and a careless uniform rewrite of role triggers was measured to land new pairs inside it. The mitigation is the `EXEMPT:` emitter — the pair still prints with its score, so the suppression is visible to a reader even though it does not raise a finding. It is a deliberate trade of a *silent* miss for a *logged* one, not the elimination of the miss.

**Negative.** Deleting or mistyping a `DEPENDS_ON` edge changes gate behaviour from a file that reads like documentation. The gate refuses to run composition-aware without a registry path resolving to a real file with parseable edges, and fails loud rather than degrading to a non-composition-aware run, but a *partially* wrong edge set still degrades quietly in the widening direction — the gate would report more, not fewer, findings, which is the safe direction to fail.

**Negative.** Two skills whose relationship is real but recorded as `RELATES_TO` will be flagged in the WATCH band. That is intended: the fix is to correct the edge if it is genuinely a composition, or to fix the triggers if it is not.

## Reversibility

**CHEAP.** The rule is a band predicate in one function plus one emitter line. Reverting means deleting the predicate; the gate falls back to flagging both bands for every pair, which is noisier but never less safe. No data migration, no schema change, no threshold change. Confidence: **HIGH** — the decision's grounding was independently re-measured at Stage 5, re-measured again by an adversarial reviewer who reproduced the suppression figure exactly, and re-measured a third time at implementation against the live corpus.

## Related ADRs

- **ADR-019** — role-Specialists compose function-skills rather than absorbing them. This is the reason shared vocabulary between a role and its engine is expected rather than defective, and therefore the reason a composition-aware rule is warranted at all.
- **ADR-038** — the registry as CMDB; establishes the `kind` discriminator and the `dependencies` column this gate reads. That ADR scopes `dependencies` to configuration-management edges; this ADR extends it to a gate input.
- **ADR-008** — `deploy.sh` per-module arrays as the single roster source of truth. The gate's audit population is built from those arrays rather than from a filesystem glob or a second manifest.
- **ADR-068** — settled the sibling-versus-extend question for the adjacent ownership-collision detector, ruling that the trigger-routing Jaccard harness stays independent. That ruling is why this gate extends the existing harness rather than introducing a parallel one.
- **ADR-084** — the harness's zero-dependency contract and its fixing of the lexical primitives as the single metric source. Preserved: the primitives' signatures are unchanged and the implementation stays standard-library only.
