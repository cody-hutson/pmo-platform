<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Decision-confidence relationship posture — extend-and-compose across the decision-quality layer, not a standalone discipline
status: Proposed (flips to Accepted at the Stage 9 review)
date: 2026-06-27
release: 97-knowledge-and-decision-confidence
deciders: "Workspace owner (architecture ratified at the Stage 9 review); design authored at Stage 5 Solutioning, ADR authored at Stage 6 via PR per the core-ADR Stage-6-authoring convention"
tags: [architecture, decision-confidence, compose, extend, decision-quality-layer, no-shadow-ssot, reversibility, autonomy, discovery, reversibility-cheap]
---

# ADR-047 — Decision-confidence relationship posture: extend-and-compose, not standalone

## Status

**Proposed** — flips to Accepted at the Stage 9 review.

Number **renumbered from a Stage-5 ADR-047 (proposed as ADR-046)** — the contiguous global sequence advanced while this decision was in design: a sibling release claimed **ADR-046** (`roadmap-instance-in-repo-home`) on the mainline during this release's window. `release/tools/check-adr-numbers.py` confirms **047** as the next gap-free number after 046. The provisional number binds atomically at Stage 12; if a further sibling claims 047 before merge, this ADR renumbers up to the next gap-free value and records the renumber here (the ADR-029 / ADR-032 / ADR-033 renumber-provenance precedent).

The slug `decision-confidence-compose-posture` is disambiguated deliberately from `ADR-043-staleness-confidence-canonical-representation` — that ADR's "confidence" is *artifact-staleness* confidence (how out-of-date a source is); **this** ADR's "confidence" is *agent self-competence* confidence (how grounded a pending decision is). Distinct referents, distinct slugs.

## Context

The platform has a decision-quality layer of meta-protocol documents — each owns one axis of how an agent should act well, and each already composes its siblings without inheritance (every layer doc declares `parallel_to:` peers and cites rather than copies). An agent facing a non-obvious decision — *proceed now, pause to learn, or escalate?* — needs a mechanism that combines those axes into a single pre-action gate. The mechanism is genuinely new on two axes:

- **Temporal** — it fires *mid-activity*, between entry-time discovery (pre-artifact) and post-failure root-cause analysis (post-defect). It is the **mid node** in the `discovery → [decision-confidence] → RCA` triad. Root-cause-analysis is the temporal complement that closes that triad; it is named here for placement but is not one of the five relationship-table layer docs below (the scope of this decision fixes the table at exactly the five docs that own the mechanism's load-bearing primitives or supply its reusable scaffolding).
- **Audience** — it is an **agent-self** go/no-go (does the agent have grounds to act?), distinct from the operator-briefing audience the existing decision docs assume.

No single existing layer doc owns that (temporal × audience) cell. Every primitive the mechanism needs, however, already exists in fragments across the layer: the agent self-assessment axis (the reversibility protocol's confidence pairing), the gap-closing-action vocabulary (the discovery discipline's knowability triage), the go/no-go harness and the ceremony guards that keep a pause load-bearing (the decision discipline), and the recovery control-flow taxonomy (the autonomous-execution model's Retry / Escalate / Rollback). The mechanism's design constraint is therefore a *relationship* decision: which of these docs does it **extend**, and which does it **compose** — without copying any of them into a shadow source of truth.

A Research spike recommended a COMPOSE posture as **non-binding input**; this ADR is the binding decision that records the posture and its per-doc consequences. The companion specification authored in the same release operationalizes the mechanism (the signal, the threshold matrix, the bounded pause-to-learn loop) and must agree cell-for-cell with the relationship table below.

## Decision

The agent decision-confidence mechanism is realized as **extend-and-compose across the existing decision-quality layer — not as a standalone discipline.** Because no single layer doc owns the (temporal × audience) cell, the mechanism (1) **extends** the two docs that own its load-bearing primitives and (2) **composes** the three that supply reusable scaffolding it must not duplicate.

### Per-doc relationship table

Each row states the **posture** (EXTEND vs COMPOSE), **what the mechanism takes from** the doc, and **what (if anything) changes in** the doc. EXTEND rows carry a file-edit consequence; those edits are **executed downstream by the Create-stage gate slice (a separate single-writer work item), not by this ADR** — the ADR *records the decision to extend*; it does not author the diff. COMPOSE rows are cite-only (no edit to that doc in this release).

| # | Layer doc | Posture | What the mechanism TAKES FROM it | What CHANGES in it |
|---|-----------|---------|----------------------------------|--------------------|
| 1 | `core/specs/reversibility-protocol.md` | **EXTEND** | The `confidence: HIGH/MEDIUM/LOW` axis (§ Confidence Pairing) — the one existing genuine agent-self-assessment dimension — and the tier × ceremony scaling model (§ Process Weight by Tier). | Promote `confidence` from a **passive operator-calibration label** to an **active self-gate**: a low-confidence reading on a not-trivially-reversible action triggers the pause-to-learn loop instead of silently proceeding. Additive — existing label semantics are unchanged for current consumers; the gate is the new leg. *(Edit owned by the downstream Create slice, single-writer; this ADR records the decision, not the diff.)* |
| 2 | `core/disciplines/autonomous-execution-model.md` | **EXTEND** | The Retry / Escalate / Rollback **control-flow taxonomy**, the directed-cascade composition model, and the Autonomous Execution Disposition (when-to-act-vs-surface). | Register a **confidence-driven, pre-action trigger** as a **3rd sibling to Retry and Escalate** whose default resolution is *pause-to-learn-myself*, **not** escalate-to-operator. Retry is failure-anchored; Escalate is ambiguity-to-operator-anchored; the new sibling is **competence-anchored and self-closing**. Strictly additive — a new trigger class plus a composition row; no existing pattern is mutated. *(Edit owned by the downstream Create slice, single-writer, additive-only.)* |
| 3 | `core/disciplines/decision-discipline.md` | **COMPOSE** | The go/no-go **harness** — the Three Mechanisms (Localization / Opposing-View / Pattern-Cache) and the ceremony-management guards (§ 5) that keep a pause load-bearing rather than theater — sited as a "pause-to-close-gap" branch off its operator-escalation path (the § 5 escalation guard today knows only escalate-to-operator). | **Nothing.** Cite-only. The mechanism reuses the harness and guards verbatim; the decision discipline is operator-audience and stays so. |
| 4 | `core/disciplines/discovery-discipline.md` | **COMPOSE** | § 2.5 **knowability triage** (knowable-now → fetch · knowable-later → spike · knowable-only-by-operating → ship-and-observe) as the **"how I close the gap once I pause"** sub-routine, and the § 6 anti-theater posture (discovery-without-output is theater → the pause must externalize a named gap). | **Nothing.** Cite-only. Discovery is entry-time / pre-artifact (a different temporal anchor); this mechanism is its **mid-activity** complement and imports its vocabulary by reference. |
| 5 | `core/specs/autonomy-tiers.md` | **COMPOSE (orthogonal)** | The Tier 0–3 WHO-acts authorization signature — as the **second scaling axis** for the confidence threshold (threshold = f(reversibility tier × autonomy tier); no clean global numeric cutoff exists). | **Nothing.** Cite-only, orthogonal. A Tier-2/3 (authorized) action can **still** be paused by a low competence-confidence reading; autonomy gates on authorization / visibility / reversibility, never on confidence — the two compose alongside without overlap. |

### Rationale — the two rejected alternatives

- **Reject STANDALONE.** The four needed primitives already exist in fragments — the self-confidence axis (reversibility protocol § Confidence Pairing), the gap-closing-action vocabulary (discovery discipline § 2.5), the go/no-go harness plus ceremony guards (decision discipline § 2 / § 5), and the recovery control-flow taxonomy (autonomous-execution model Retry / Escalate / Rollback). A standalone doc would **copy** them and **drift** — the no-shadow-SSOT failure that the memory-architecture ADRs named for memory surfaces, applied here to disciplines: a shadow copy can diverge the moment its owner refines a primitive, and an agent reading the copy lets it silently override the owner.
- **Reject PURE-EXTEND-INTO-ONE-DOC.** The capability is genuinely new on the temporal **and** audience axes; folding it wholesale into any single doc mis-files it. Into the reversibility protocol it erases the control-flow-trigger nature; into the autonomous-execution model it erases the confidence-axis nature. No single doc is the right sole home, which is exactly why the mechanism spans an extend-pair plus a compose-trio.
- **Accept EXTEND-AND-COMPOSE.** This matches the platform's established meta-protocol composition pattern — every layer doc already declares `parallel_to:` siblings and composes without inheritance. The two EXTEND edits are additive and single-writer; the three COMPOSE relationships are cite-only.

## Consequences

- **One mechanism, no shadow source of truth.** The mechanism binds five existing docs rather than copying any of them. The drift vector a standalone doc would have introduced is closed by construction: each primitive stays single-home, and the mechanism references it.
- **Two additive downstream edits are now decided, not yet executed.** The reversibility-protocol label→gate promotion and the autonomous-execution-model 3rd-sibling registration are **recorded here as decisions** and **executed by the downstream Create slice** as additive, single-writer edits. The ADR and the companion spec precede those edits; the Create slice cites this ADR rather than re-deciding. A divergence between this table and the eventual edits is a Stage-9 coherence finding (ADR ↔ spec ↔ spine reviewed together).
- **The spine-edit blast radius travels with the Create slice, not this ADR.** The reversibility protocol is a widely-referenced spine doc; the *edit* to it carries that blast radius and is governed under the Create slice (additive-only, single-writer, Stage-9-reviewed, `deploy.sh --check` post-edit). The decision *to extend* — recorded here — is itself CHEAP and reversible.
- **Doc-only at this version.** This ADR plus the companion spec are additive governance; no executable surface changes in this work item. The gate's live wiring into a named consumer is the Create slice's responsibility.

## Reversibility

**CHEAP / Confidence HIGH.** This ADR is additive governance — `git revert -m 1` removes it with no downstream contract to unwind (the EXTEND edits it records live in a separate work item and revert independently). Confidence is HIGH that extend-and-compose is the right posture: every needed primitive already exists in a single-home doc, the platform's layer docs already compose without inheritance, and a standalone alternative would reintroduce the shadow-SSOT drift the platform has repeatedly chosen against.

## Related ADRs

- [ADR-019 — Specialists compose, not absorb](ADR-019-specialists-compose-not-absorb.md): the same compose-not-absorb principle at the skill layer that this ADR applies at the decision-quality-doc layer — reuse a capability by reference, never by fork.
- [ADR-029 — Memory SSOT model — corpus-SSOT for codified Knowledge](ADR-029-memory-corpus-ssot-boundary.md): the no-shadow-SSOT invariant whose drift reasoning the reject-standalone rationale reuses (applied to disciplines rather than memory surfaces).
- [ADR-043 — Staleness-confidence canonical representation](ADR-043-staleness-confidence-canonical-representation.md): the **other** "confidence" ADR — artifact-staleness confidence, a distinct referent from this ADR's agent-competence confidence; named here to anchor the slug disambiguation.

## Provenance

Decision lineage, for audit only — not load-bearing on the posture above (the decision reads version-agnostically).

- #1612 — the decision-confidence Research spike that produced the COMPOSE posture and the hard design constraints (non-binding input; this ADR is the binding decision).
- #2283 — the Define task (spec + ADR) under which this decision was authored; carries the COMPOSE recipe and the per-doc relationship posture.
- #2287 — the Define ST2 sub-task that scoped this ADR (the compose/extend/standalone decision + the five-doc relationship table).
- #2286 — the Define ST1 sub-task and its companion `decision-confidence-protocol.md` spec, which operationalizes this posture and must agree cell-for-cell with the relationship table.
- #2288 — the downstream Create slice that executes the two recorded EXTEND edits (the reversibility-protocol label→gate promotion and the autonomous-execution-model 3rd-sibling registration) as additive, single-writer changes.
