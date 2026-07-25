---
title: As-Built Architecture-Conformance Audit — Dimension Rubric
purpose: The content SSOT for pmo-qa-auditor Mode I (as-built architecture-conformance audit) — the scored dimension set the audit grades delivered work against, the severity banding, the no-governing-baseline cap, and the fragmentation threshold.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# As-Built Architecture-Conformance Audit — Dimension Rubric (Mode I content SSOT)

> Mode I (`architecture-conformance-mode-spec.md`) consumes this file verbatim — the
> dimension set, the 1–5 anchors, the severity bands, the `no-governing-baseline` cap, and
> the fragmentation threshold all live here and nowhere else. When-to-run authority is
> `release/references/protocols/architecture-conformance-cadence.md`. Re-tuning any band or
> dimension is an edit to THIS file only (governed edit; continuity per the cadence doc §5).

## 1. Conformance dimension set (baseline priority: ADR PRIMARY, cross-chain index SECONDARY)

Each delivered item is scored on the dimensions below. Dimension 1 (ADR-decision conformance)
is the **PRIMARY, discriminating** dimension — the ADR corpus is unit-matched to
platform-engineering deliveries (one decision per record). Dimensions 2–4 are **SECONDARY
routing dimensions** — they apply only when the delivery maps to a management chain in the
cross-chain index, and they degrade to `no-governing-baseline` for a delivery that maps to no
chain (a coverage signal, not a low score — §3). Dimension 5 is the **cross-release**
dimension (the fragmentation lens the per-ticket forward gate is blind to). Chain rows are
referenced by **chain name** (not column position) so the rubric does not couple to the
cross-chain index's table shape.

| # | Dimension | Baseline source (content cite) | Priority |
|---|---|---|---|
| 1 | **ADR-decision conformance** — the delivery honors any ADR governing its capability/surface | the ADR corpus (`core/ADRs/` + `release/ADRs/`) | **PRIMARY** |
| 2 | **Chain-model conformance** — the delivery honors the governing data model / entity of the management chain it maps to | `cross-chain-architecture-map.md` — the mapped chain's *governing data model / entity* cell (by chain name) | secondary |
| 3 | **Chain-flow conformance** — the delivery follows the mapped chain's flow / escalation path | `cross-chain-architecture-map.md` — the mapped chain's *flow / escalation path* cell (by chain name) | secondary |
| 4 | **Chain-gate conformance** — the delivery respects the mapped chain's holding gate / check | `cross-chain-architecture-map.md` — the mapped chain's *holding gate / check* cell (by chain name); `architecture-overview.md` for the narrative baseline | secondary |
| 5 | **Cross-release consistency** — this delivery's cited architecture agrees with sibling deliveries on the same capability key (the fragmentation dimension) | the delivered-item set (mode-spec §2) + the ADR citations that make divergence citable (mode-spec §4b) | cross-item |

5 dimensions is the reconciled set (§4), not a cap — roster changes are governed by the
cadence-doc §5 continuity rule (note additions, rationale for removals, in the run's
SUMMARY.md). Dimension 5 is **confidence-bounded by construction**: it can only see
divergence where ADR/chain citations expose it (mode-spec §4b stated limitation), so its
findings are candidate-grade, never deterministic.

## 2. Scoring anchors (1–5)

**Generic spine** (every dimension specializes this): **1 non-conformant** · **2 partial** ·
**3 conformant-unverified** · **4 conformant-evidenced** · **5 conformant + cross-release-
consistent**. Per-dimension cells specialize each level to an **observable state**; the
example evidence source for any cell is the dimension's §1 baseline-source doc (plus the
mechanical check — a grep, an ADR-citation search, a capability-key group read — that shows
the state). Scores are RECORDED observational data under the cadence §5 continuity rule,
never gate verdicts.

**Worked example — Dim 1 ADR-decision conformance, level 1:** "the delivery's touched surface
is governed by a resolvable ADR, and the delivery contradicts that ADR's decision (evidence:
the ADR `path:line` + the delivering commit/PR showing the divergent choice)."

**Worked example — Dim 5 Cross-release consistency, level 1:** "≥2 deliveries under one
capability key cite divergent architectures with no reconciliation (evidence: the two ADR
citations + the shared capability key) — a fragmentation *candidate* (§3 threshold)."

| # | Dimension | 1 — non-conformant | 2 — partial | 3 — conformant-unverified | 4 — conformant-evidenced | 5 — conformant + cross-release-consistent |
|---|---|---|---|---|---|---|
| 1 | ADR-decision conformance | Delivery contradicts a resolvable governing ADR | Delivery honors part of the ADR; a sub-decision diverges | An ADR governs the surface; conformance asserted but no delivered evidence resolves it | Delivery honors the governing ADR with resolvable evidence | Honors the ADR AND is consistent with sibling deliveries under the same key |
| 2 | Chain-model conformance | Delivery violates the chain's governing data model / entity | Delivery honors part of the chain model; one entity/field diverges | Delivery maps to a chain; model conformance asserted, unverified | Delivery honors the chain's data model with resolvable evidence | Chain-model-conformant AND consistent with siblings on the key |
| 3 | Chain-flow conformance | Delivery bypasses / contradicts the chain's flow-escalation path | Delivery follows part of the flow; one hop diverges | Maps to a chain; flow conformance asserted, unverified | Follows the chain flow with resolvable evidence | Flow-conformant AND cross-release-consistent |
| 4 | Chain-gate conformance | Delivery evades the chain's holding gate / check | Delivery respects part of the gate; one check bypassed | Maps to a chain; gate conformance asserted, unverified | Respects the chain gate with resolvable evidence | Gate-conformant AND cross-release-consistent |
| 5 | Cross-release consistency | ≥2 deliveries under the key cite divergent architectures, unreconciled (fragmentation candidate) | Deliveries under the key partially diverge; one cites, one is silent | Single delivery under the key (nothing to compare) OR architecture-followed unknown for members | Members under the key cite the same architecture, evidenced | All members cite one architecture, cross-release-consistent + reconciled |

**Scale note (deviation, documented):** 1–5 (not binary/1–4) matches Mode F's precedent — the
scores are RECORDED observational data (never gate verdicts), the anchors are behavioral
states, and the characterization fixtures pin drift (±1). Not a gate carve-out — Mode I emits
zero gate verdicts.

## 3. Severity banding (SSOT) + no-governing-baseline cap + fragmentation threshold

**Severity band (maps a dimension score + blast radius → severity):**

| Dimension score | Blast radius | Severity |
|---|---|---|
| 1 (non-conformant) | governed chain / ADR-load-bearing / cross-cutting surface | **CRITICAL** |
| 1 (non-conformant) | single skill / doc surface | **HIGH** |
| 2 (partial) | any load-bearing surface | **HIGH** |
| 2 (partial) | single non-load-bearing surface | **MEDIUM** |
| 3 (conformant-unverified) | any | **LOW** (observation — verify) |
| 4–5 (conformant) | any | none (conformant — recorded, no finding) |

Severity is CRITICAL/HIGH/MEDIUM/LOW (review-discipline §5, reused verbatim). The severity is
set from the **observed divergence on its own axis**; the baseline-existence **confidence tag**
(HIGH/MEDIUM/LOW, mode-spec §5) rides alongside and **never lowers** the severity.

**HIGH-severity × LOW-confidence rule (orthogonality — do not dilute).** A score-1/score-2
divergence on a load-bearing surface is HIGH or CRITICAL **even when** the baseline mapping is
LOW-confidence (present-but-ambiguous which ADR/chain applies). It is surfaced as
`severity: HIGH · confidence: LOW` for operator triage — **never** demoted to MEDIUM because
the baseline is uncertain. Epistemic uncertainty about *which* baseline applies is not
evidence the divergence is minor.

**The `no-governing-baseline` cap (bounds SEVERITY, not VOLUME).** A delivery with no
resolvable ADR and no chain mapping yields a `no-governing-baseline` classification, **capped
at MEDIUM severity** and tagged `coverage-signal` — a baseline-gap observation, not a
conformance-defect. The cap governs **severity only**. The **cardinality** is bounded
separately by the mode-spec §5 volume control (aggregate all `no-governing-baseline`
deliveries into **one** coverage-gap summary row — count + list — and fire the signal only for
deliveries that touched an architecture-load-bearing surface). The cap and the volume control
are distinct mechanisms; both apply.

**Fragmentation threshold (dimension 5).** A capability-key group spanning **≥2 releases**
where **≥2 members cite divergent architectures** (different ADR, different chain-model, or one
established a baseline a sibling ignored) yields **exactly one** cross-release-fragmentation
finding for that group — never one-per-member, never zero for a real divergence. The finding
carries `detection: candidate (ADR-citation-bounded)` (mode-spec §4b): the threshold fires
only where citations expose the divergence; un-ADR'd members whose architecture-followed is
unknown cannot be assessed and are recorded as such, not silently counted as conformant.

## 4. Reconciliation record (design provenance)

Sources: the ADR corpus (PRIMARY baseline) + the cross-chain architecture index (SECONDARY
routing aid, referenced by chain name) + `architecture-overview.md` (narrative baseline);
reconciled against Mode F's process-fitness rubric:

- **vs Mode F** — Mode F scores THE PIPELINE per discipline against external delivery-process
  frames (PMBOK/DORA/…); Mode I scores DELIVERED WORK per delivery against the platform's
  OWN internal architecture. Different unit of analysis (delivered-work-vs-internal-
  architecture, not pipeline-vs-external-methodology) → no duplication; the two audit
  different objects against different baselines.
- **Baseline priority (CD-A)** — the ADR corpus is PRIMARY (per-decision, unit-matched to
  per-delivery conformance, discriminating); the cross-chain index is SECONDARY (per-chain,
  navigational — a routing aid for World-B operational-chain deliveries, too coarse to
  discriminate among dozens of World-A platform-engineering deliveries). This inverts a
  naïve "index-primary" reading and de-risks the dependency on the index landing first: a
  delivery with no chain mapping degrades to `no-governing-baseline` gracefully.
- **Coupling minimization** — dimensions 2–4 reference cross-chain rows by **chain name**
  (a stable key), not by column position, so a change to the index's table shape does not
  silently invalidate the rubric.
- **Dimension 5 honesty** — the fragmentation dimension is confidence-bounded by construction
  (the release record does not carry architecture-followed; only ADR citations expose
  divergence), so its findings are candidate-grade. This is a stated limitation, not a hidden
  weakness.

Full reconciliation record: the release's Stage 5 Solutioning design record for the Mode I
slice (this file is its committed output).
