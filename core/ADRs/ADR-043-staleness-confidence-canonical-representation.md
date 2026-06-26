---
title: Staleness-confidence canonical representation — ordinal depth bands backed by an optional projected score
status: Proposed
tags: [staleness-confidence, representation-standard, ordinal-scale, cross-mechanism, depth-axis]
---
<!-- reference-durability: allow-link -->

# ADR-043 — Staleness-confidence canonical representation: ordinal depth bands backed by an optional projected score

## Status

Proposed — ratified at the ticket-information-architecture Stage 9 GO. Authored at Stage 6 alongside the canonical spec it records, per the core-ADR convention (a decision captured as a committed ADR document written in the same release as the artifact it governs).

## Context

The platform expresses confidence in staleness in five mutually-incompatible shapes across independent ticket-facing mechanisms: a binary currency check, a 3-tier context-drift severity, a 3-class mid-pipeline drift verdict, a typed premise-rejection taxonomy (PT-1..PT-4), and exactly one weighted graduated score. The only graduated score is scoped to the document ecosystem and is a **time-decay** metric — every term is a "days since X" delta — so it measures *how long* something has gone untouched (recency-magnitude), not *what kind* of staleness it is (depth). Because no ticket-facing shape encodes staleness depth, an operator cannot tell a trivial drift (a stale path token whose premise still holds) from structural rot (the premise is gone, files relocated) from the signal shape alone.

The representation choice is non-obvious and **reverses the originating issue's stated lean** ("the graduated score is the natural candidate to generalize from"). That reversal warrants a recorded rationale per the ADR-as-design-document escape-hatch / ceremony test in [`canonical-form-discipline.md` §3.3](../disciplines/canonical-form-discipline.md): producing the durable artifact here adds decision value, not ceremony.

## Decision

Staleness-confidence is represented by an **ordinal depth scale** of four bands — S0-NONE / S1-SUPERFICIAL / S2-SUBSTANTIVE / S3-STRUCTURAL — canonicalized in [`core/specs/staleness-confidence-standard.md`](../specs/staleness-confidence-standard.md). Every mechanism maps its states onto a band; the band is the legible surface an operator reads.

A **continuous score is a projection onto the scale, never the scale itself.** A mechanism that already computes a continuous score (the weighted time-decay score, the only one today) additionally carries it and defines a documented score→band projection rule; mechanisms that are natively discrete map directly to a band with no score obligation. The time-decay formula is **cited, not redefined** — it stays owned by its source spec; the new standard adds only the band cut-points.

**Cause taxonomies are orthogonal sub-classifications, not points on the scale.** The PT-1..PT-4 premise-rejection taxonomy fires only at a premise-level (C3) finding, so all four PTs project onto the single S3-STRUCTURAL band and carry an orthogonal cause tag (*why* the structural problem exists); they do not span S0..S2.

**Binary and age-only signals self-report at most a mid-depth band; structural depth requires a premise/path finding, never the bare signal.** A binary mechanism maps to a single band that its signal alone determines; escalation to S3 is a posture-layer move, not a second judgment hidden inside the representation. Elapsed-time signals cap at S2 — age alone never implies S3.

## Consequences

- Operators gain a single depth vocabulary that separates trivial drift from structural rot — the distinction the originating gap exists to close.
- Five consumer surfaces gain one inbound reference line each pointing at the canonical band mapping; the mapping table lives once in the standard and is never duplicated.
- The time-decay score keeps its continuous signal (and its histogram) while projecting onto a band; no mechanism is forced into a foreign shape.
- The score→band projection rule is the only rule-based projection; every discrete mechanism is a total function of its source signal, so two readers bin the same signal identically.
- **Reversibility: MODERATE / Confidence: HIGH.** The bands are a vocabulary (re-mapping a row is a doc edit — CHEAP); the single score-projection rule is MODERATE but isolated to one mechanism, so the blast radius of a reversal is one rule, not five. Each consumer edit is a one-line reference removal, so rollback is mechanical. Confidence is HIGH on the depth-axis reframing (grounded in the formula being all-time-terms) and MEDIUM on the exact score cut-points (the 2×-threshold default is reasoned and calibratable).

## Alternatives considered

| Option | Decision | Rationale |
|---|---|---|
| **Graduated score as the canonical scale** (generalize the time-decay formula platform-wide) | Rejected | Canonicalizes the time-magnitude axis, not the depth axis the operator needs; a high recency score does not imply structural depth. Forces invented math onto the four natively-discrete mechanisms (there is no natural float for a premise-rejection cause). |
| **Pure ordinal enum** (bands only, no score) | Rejected | Strands the one mechanism that already ships a continuous, histogram-able signal — flattening its score to a band discards real information the health report already surfaces. |
| **Hybrid — ordinal bands backed by an optional projected score** | **Accepted** | Clean discrete mapping for the four discrete mechanisms *plus* a single isolated score-retention rule for the one mechanism that has a score. Marginal cost over the pure enum is one projection rule; marginal benefit is preserving a shipped capability and leaving a forward path for any future score-bearing mechanism. |

## Boundary

This standard governs the **representation** of staleness-confidence (the shared scale a detector uses to report how deeply a signal is stale). It does **not** govern the **response posture** (what an agent does once a signal is classified). Response posture is owned by [`reconcile-dont-annotate.md`](../disciplines/reconcile-dont-annotate.md). The two compose: a detector emits a band (representation); the reconcile-vs-annotate decision consumes the band to choose the response (posture). This ADR — and the standard it records — defines the band; it never prescribes the action.

## Related ADRs

- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — the one-owner-of-truth / cite-don't-duplicate posture this decision applies to the time-decay formula (cited from its source spec, not restated in the new standard).
