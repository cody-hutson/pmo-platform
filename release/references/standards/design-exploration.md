---
title: Design-Exploration Protocol — Stage 5 Phase A4 Micro-Protocol
purpose: A Stage-5 Solutioning micro-protocol that inserts divergent alternative generation then convergent narrowing BEFORE the trade-off matrix, so design alternatives are genuinely generated and eliminated against hard constraints rather than retrofitted to satisfy the "≥3 alternatives" exit check. Closes the gap where the design-review checklist demands multiple alternatives but no protocol governs how they are generated and narrowed.
type: standard
reversibility: CHEAP / Confidence HIGH
consumers: "release/references/pipeline/stage-05-solutioning.md Phase A4 (cited as canonical for the generation→narrowing step); release/references/how-to/hub-spoke-bridge.md Stage-5 Chip Pattern (the chip directs the spoke to run this protocol before the trade-off matrix); release/references/templates/design-review-checklist.md Section 4 check 4.3 (this protocol satisfies the ≥3-alternatives requirement by construction)"
parallel_to: "solutioning-output-template.md (sibling release-pipeline Stage-5 process standard — that one owns the OUTPUT comment frame, this one owns the generation→narrowing micro-protocol); triage-design-rereview.md (sibling release-pipeline Stage-5 standard)"
---
<!-- reference-durability: allow-version-ref -->

# Design-Exploration Protocol — Stage 5 Phase A4 Micro-Protocol

## 1. Purpose + Activation

The platform's Stage 5 design surface jumps to *evaluation* without a governed *generation* step. The design-review checklist requires that a Stage-5 design evaluate at least three alternatives, but that is an exit check on the ADR — it inspects the finished design for alternatives, it does not govern how the alternatives come to exist. The within-spoke opposing-view ceremony (one counter-design) is a single-counter discipline, not a fan-out generator. The consequence: a spoke can anchor on its first solution, retrofit two thin alternatives to satisfy the exit check, and pass — with the anchoring bias never surfaced.

This protocol closes that gap. It makes *generation-then-narrowing* a named, gated micro-protocol that runs **inside Stage 5 Phase A4, BEFORE the trade-off matrix**. The trade-off matrix stays exactly where it is in the causal chain (it feeds the ADR's opposing view); this protocol adds the two steps that belong upstream of it.

**Activation.** The protocol fires inside Phase A4 WHEN a decision-class design choice with **two or more candidate approaches** is in scope — surfaced by the multiple-approaches activation trigger from the planning→solutioning handoff, OR by the Phase A1 scope-assessment finding genuine design latitude.

**Omission (the non-ceremony signal).** The protocol is OMITTED — and that omission is correct, not a skipped step — when the design has a single forced approach (no genuine latitude exists). Omitting a generation ceremony for a forced-single-approach design is the same omission discipline the cascade-completeness sweep and the doc-corpus-reorg ref-form enumeration follow: the ceremony fires only when its trigger predicate holds, and its absence under a non-triggering condition is the honest signal, not a gap. A spoke that omits the protocol records a one-line omission rationale ("single forced approach — no design latitude; generation omitted per the non-ceremony signal").

## 2. Step 1 — Divergent generation (mind-map)

Generate **three or more genuinely distinct candidate approaches** — not one real candidate plus two straw alternatives built to lose. This is the divergent step: widen before narrowing.

Structure the output as a candidate table:

| Candidate | One-line mechanism | Seed rationale |
|---|---|---|
| Approach A | how it works in one line | why it is a live option |
| Approach B | … | … |
| Approach C | … | … |

**The "distinct" test (borrowed from the adversarial counter-design axes for consistency):** each candidate must differ from the others on at least one of {mechanism, blast radius, reversibility, placement}. Two candidates that differ only cosmetically are one candidate — collapse them and generate a genuinely different third. The test is what prevents straw-alternative retrofitting: a straw alternative fails the distinctness test because it was constructed to be dominated, not to be different.

A mind-map framing is the recommended generation aid: start from the problem at the center, branch to mechanism families, and expand each family into a concrete candidate. The deliverable is the candidate table, not the mind-map itself.

## 3. Step 2 — Convergent narrowing (elimination)

Eliminate candidates against **hard constraints first**, before any scoring. The convergent step kills candidates that cannot survive a constraint breach, so the trade-off matrix scores only live options.

Hard-constraint classes (eliminate on a breach of any):
- **Governance conformance** — the candidate violates a shipped protocol, a guardrail, or the knowledge-architecture placement model.
- **Blast-radius ceiling** — the candidate's impact exceeds the change's risk budget (a structural-tier change where a behavioral-tier solution exists).
- **Irreversibility** — the candidate is an expensive or irreversible one-way door where a cheaper-to-reverse candidate achieves the same outcome.

Record a **one-line kill-reason** for each eliminated candidate:

| Candidate | Eliminated? | Kill-reason (the breached hard constraint) |
|---|---|---|
| Approach A | survives | — |
| Approach B | eliminated | breaches <named hard constraint> |
| Approach C | survives | — |

**Elimination is not scoring.** A candidate dies on a *constraint breach*, never on a close score — a candidate that merely scores slightly lower survives to the matrix, because the matrix is where comparative scoring happens. Conflating elimination with low scoring collapses the two steps and defeats the purpose: the matrix never sees the option that was quietly scored out.

**At least two survivors** proceed to the matrix. If narrowing leaves fewer than two survivors, the design genuinely has a forced single approach after constraints — record that finding (it retroactively validates the omission signal of §1 for the constrained sub-decision) and proceed to specification without a matrix.

Recording kill-reasons is also **why-not traceability**: the eliminated candidates and their kill-reasons are knowledge the platform captures (the knowledge-management capture discipline), so a later reviewer or a future release sees which options were considered and why each was rejected, rather than re-deriving them.

## 4. Step 3 — Trade-off matrix (the EXISTING entry point, now downstream)

The surviving candidates are scored on the **canonical axes already used by the adversarial counter-design schema** — REUSE these axes; do not invent a new axis set:

| Surviving candidate | Reversibility (CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE) | Confidence (HIGH/MED/LOW) | Blast radius | Upstream-compat |
|---|---|---|---|---|
| Approach A | … | … | … | … |
| Approach C | … | … | … | … |

The matrix output feeds two existing surfaces:
- the **ADR's opposing-view** — the chosen design plus the strongest surviving alternative and why it was not chosen; and
- the **design-review checklist's ≥3-alternatives check** — which this protocol now **satisfies by construction** rather than by retrofit. Because Step 1 generated three or more genuinely distinct candidates and Step 2 recorded the kill-reasons, the exit check inspects a real generation history, not three alternatives reverse-engineered to make the pre-chosen design look considered.

## 5. Composition with Phase A4 / A5 / A6.5

This protocol is **A4's opening move**, not a replacement for A4. The Phase A4 sequence becomes: run design-exploration (generation → narrowing → matrix) → THEN specify the surviving approach out (the existing A4 work: exact structure/naming/layout + implementability + debt flags + the cascade-completeness sweep). The trade-off matrix stays where it has always been in the causal chain — feeding the A5 ADR — and this protocol adds the two steps before it.

- **With Phase A5 (ADR drafting):** the matrix's strongest losing candidate becomes the ADR's opposing view; the kill-reasons from Step 2 become the ADR's "alternatives considered and rejected" content. The ADR is richer because the generation history is real.
- **With Phase A6.5 (independent adversarial design review):** the adversarial reviewer's counter-design findings are downstream and independent of this protocol. A counter-design the reviewer proposes that this protocol's Step 1 already generated and Step 2 eliminated is answered by the recorded kill-reason; a counter-design that this protocol did NOT generate is a signal that Step 1's divergence was too narrow — a legitimate adversarial finding the reviewer should raise. The two compose: this protocol widens generation up front; the adversarial review tests whether the widening was wide enough.

## 6. AC5 Worked Example — generation → elimination → matrix

This worked example uses **this protocol's own milestone's home-selection decision** as the case (self-demonstrating, zero contention with any other file — the same self-demonstration pattern the corpus-curation standard uses for its source-taxonomy table). The decision: where does this very `design-exploration.md` file live?

**Step 1 — Divergent generation (mind-map → candidate table):**

| Candidate | One-line mechanism | Seed rationale |
|---|---|---|
| `core/disciplines/` | place it beside the universal cross-module disciplines (decision / discovery / review / corpus-curation / applicability / knowledge-architecture) | it is a design discipline |
| `core/standards/` | place it beside the universal K1 standards (design-artifact, evidence-grounding, framework-corpus) | it is a standard |
| `release/references/standards/` | place it beside the release-pipeline process standards (solutioning-output-template, triage-design-rereview) | it is Stage-5 process machinery |

The three candidates pass the distinctness test — they differ on **placement** (and on the implied **blast radius** of cross-module vs release-local consumption).

**Step 2 — Convergent narrowing (elimination against hard constraints):**

| Candidate | Eliminated? | Kill-reason (the breached hard constraint) |
|---|---|---|
| `core/disciplines/` | eliminated | governance conformance: the `core/disciplines/` home is reserved for *universal cross-module disciplines* consumed across operations AND release modules; this protocol is consumed ONLY by Stage-5 release spokes, so placing it there mis-states its scope (a placement-model breach) |
| `core/standards/` | survives | — |
| `release/references/standards/` | survives | — |

One candidate eliminated on a constraint breach; two survivors proceed. (Note this is elimination, not scoring — `core/disciplines/` did not "score lower," it breached the placement-scope constraint.)

**Step 3 — Trade-off matrix (the two survivors):**

| Surviving candidate | Reversibility | Confidence | Blast radius | Upstream-compat |
|---|---|---|---|---|
| `core/standards/` | MODERATE (cross-refs would need a sweep to move later) | HIGH | wider — implies cross-module kernel consumption | fine, but over-broad for a release-local tool |
| `release/references/standards/` | MODERATE | HIGH | narrow — release-pipeline-local, matches actual consumers | exact: sibling to `solutioning-output-template.md`, the existing Stage-5 output standard |

**Decision:** `release/references/standards/design-exploration.md` — it is consumed only by Stage-5 release spokes (activation is Phase A4; its peer is the Stage-5 output-template standard already in that directory), and the narrow release-local blast radius matches the actual consumer set. The matrix's losing candidate (`core/standards/`) and the reason it lost (over-broad scope for a release-local tool) is exactly the opposing-view content the ADR carries.

This worked example demonstrates all three steps end-to-end on a real decision the milestone actually made.

## 7. Process-flow artifact (Tier-A)

This protocol defines an agent-process flow with a gate (the elimination step) and a clear sequence, and it is cited as canonical by the Stage-5 Phase A4 spec — so it activates the Tier-A process-flow artifact requirement. The flow, as an ASCII flow-block (the source-of-truth format for an agent-process flow per the design-artifact standard):

```
                 ┌─────────────────────────────────────────────┐
                 │  Phase A4 entry: design choice in scope      │
                 └───────────────────────┬─────────────────────┘
                                         │
                          ┌──────────────▼──────────────┐
                          │  GATE: ≥2 candidate          │
                          │  approaches exist?           │
                          └───────┬──────────────┬───────┘
                              NO  │              │ YES
                  ┌───────────────▼──┐      ┌────▼───────────────────────┐
                  │ OMIT protocol     │      │ Step 1 — Divergent          │
                  │ (record one-line  │      │ generation (mind-map):      │
                  │  omission         │      │ ≥3 distinct candidates;     │
                  │  rationale) →     │      │ distinctness test on        │
                  │  specify the      │      │ {mechanism, blast radius,   │
                  │  forced approach  │      │  reversibility, placement}  │
                  └───────────────────┘      └────────────┬───────────────┘
                                                          │
                                            ┌─────────────▼───────────────┐
                                            │ Step 2 — Convergent narrowing │
                                            │ (elimination): kill on a HARD │
                                            │ constraint breach, one-line   │
                                            │ kill-reason each; NOT scoring  │
                                            └─────────────┬───────────────┘
                                                          │
                                       ┌──────────────────▼──────────────────┐
                                       │ GATE: ≥2 survivors?                   │
                                       └──────┬──────────────────────┬────────┘
                                          NO  │                      │ YES
                          ┌─────────────────▼──┐        ┌────────────▼────────────────┐
                          │ forced single after │        │ Step 3 — Trade-off matrix    │
                          │ constraints →        │        │ (canonical axes: Reversibility│
                          │ record finding;      │        │ × Confidence × Blast radius  │
                          │ specify; no matrix   │        │ × Upstream-compat)           │
                          └──────────────────────┘        └────────────┬────────────────┘
                                                                       │
                                                       ┌───────────────▼───────────────┐
                                                       │ Output → A5 ADR opposing view  │
                                                       │ + design-review 4.3 (satisfied │
                                                       │ by construction) → specify the │
                                                       │ surviving approach out (A4)    │
                                                       └────────────────────────────────┘
```

This artifact is declared in the release plan's "Tier-A activated design artifacts" section, where the Stage 13 close-out reads it to scope artifact-refresh detection.

## 8. Cutover

The design-exploration protocol applies to all releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the protocol shipping in a release cannot fire on its own Stage 5 authoring without creating a reflexive-pipeline loop; the introducing release's own Stage 5 outputs use pre-rule discipline. (The introducing release's own Stage 5 is the proof of this exemption in action: it was produced under the pre-existing rules, with generation→narrowing applied informally in the home-selection decision of §6 but not gated by the not-yet-shipped protocol.) All releases that entered Stage 5 prior to the introducing release are also exempt. This matches the introducing-release-exempt reflexive-pipeline discipline used by the cascade-completeness sweep, the design-artifact production step, and the framework-corpus discipline.
