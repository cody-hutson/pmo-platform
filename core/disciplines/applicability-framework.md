---
title: Applicability Framework — context fit, contraindications, conflict resolution
purpose: The platform's reference model for WHEN a codified practice applies, WHEN it is contraindicated, and HOW to resolve conflicts between competing practices — grounded in realist evaluation and the universality axis. Reference content M1 (decision-discipline.md) consults; introduces zero new runtime machinery.
type: reference
source: ""
applies_to: "M1 consumers — hub-spoke-bridge.md (Decision Briefing Localization Check), release-personas.md (Stage 4), future release-planner / principal-engineer skills (forward-only)"
reversibility: CHEAP / Confidence HIGH
adr: ""
consumes: " knowledge-architecture.md (universality axis, parameterization seam, §4 register L4 → CI-1, operating-model.md=K2);  operating-model.md (K2 mediator);  methodology-parameterization-v1.md (one Context axis);  corpus-curation.md (evidence-tier tiebreak — referenced, not defined)"
composes_with: " decision-discipline.md (provider/consumer, one-directional — decision-discipline.md UNEDITED; four-leg proof §6)"
glossary_anchor: " umbrella body Glossary (canonical terms: Contraindication, Universality axis, Evidence-based practice — verbatim source; this doc USES, does not redefine)"
---

# Applicability Framework

This document is the platform's classification of **when a codified practice applies, when it does not, and how to resolve conflicts** between competing practices in the [COMPANY_X] single-operator PMO context. It composes with — and does **not** restate — [`decision-discipline.md`](../disciplines/decision-discipline.md) (, the runtime interrogation *procedure*), [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (, the knowledge *taxonomy* this framework consumes as grounding), [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) (, *one* applicability axis), and [`operating-model.md`](../disciplines/operating-model.md) (, the K2 OOM model home).

Terminology is locked verbatim to the ** umbrella Glossary** (the umbrella body IS the canonical glossary per 's anti-maintenance-debt rule). The terms **Contraindication**, **Universality axis**, and **Evidence-based practice** are USED here, not redefined ([§7 Boundaries](#boundaries)).

The framework's load-bearing move: **a practice's applicability surface = its [ universality-axis](../disciplines/knowledge-architecture.md#universality-axis) position + a contraindication set**, where contraindications are the [ parameterization seam](../disciplines/knowledge-architecture.md#parameterization-seam) **run forward**. Zero new runtime machinery — this is reference *content* the existing M1 decision procedure consults.

---

## §1 Realist Grounding {#cmo}

**Citation (locked — AC3 "cite source/edition"):** Pawson, R. & Tilley, N. (1997). *Realistic Evaluation*. London: SAGE Publications (**1st edition**). The Context-Mechanism-Outcome (CMO) construct and the realist question *"what works for whom under what conditions"* are taken from this source. Refinement reference: Pawson, R. (2006). *Evidence-Based Policy: A Realist Perspective*. London: SAGE Publications — ties realist causation to evidence-based practice (the bridge to [§4](#precedence-ladder) rung 3's evidence-tier tiebreak and the glossary "Evidence-based practice" term, Pfeffer & Sutton).

Realist evaluation rejects the question *"does practice P work?"* in favor of *"for whom, in what context, does P produce its intended outcome — and where does it misfire or do harm?"*. Applied **reflexively to the platform's own knowledge corpus**, the CMO construct maps 1:1 onto 's universality axis — it is *grounding*, not a competing model:

| Realist element | Platform binding |  axis binding |
|---|---|---|
| **Context (C)** | org scale · methodology (`delivery_approach`) · regulatory posture · team structure · stakeholder complexity · OOM (/K2) · institutional facts (K3) | the **contextual** pole of the [universality axis](../disciplines/knowledge-architecture.md#universality-axis) |
| **Mechanism (M)** | a codified practice — a [K1](../disciplines/knowledge-architecture.md#k1-codified) corpus entry (protocol, gate, ceremony, rubric) | the **universal** pole ([K1](../disciplines/knowledge-architecture.md#k1-codified)) |
| **Outcome (O)** | M produces intended value · misfires (null) · or does harm (negative) in C | n/a — this is the evaluative judgment |

- **Positive applicability** ([§2](#applicability-profile)) = the set of CMO configurations where M→O is positive.
- **Contraindication** ([§3](#contraindication-catalog)) = a context C where M→O is null/negative — *structurally, a [parameterization-seam](../disciplines/knowledge-architecture.md#parameterization-seam) breach run forward*.
- **Conflict resolution** ([§4](#precedence-ladder)) = two mechanisms M_a, M_b both firing in C with competing O — resolved by the precedence ladder.

This framework *falls out of* 's universality axis rather than competing with it: a **universal** practice is one whose CMO holds for *any* PMO-platform deployment; a **contextual** practice's CMO holds only for specific C. Per the [ 2×2](../disciplines/knowledge-architecture.md#axis-2x2), `applicability-framework.md` itself is **Universal + Custom** ("the bulk of the corpus" — PMO-built, applies to any PMO-platform instance).

---

## §2 Positive Applicability — the Applicability Profile {#applicability-profile}

Every codified practice ([K1](../disciplines/knowledge-architecture.md#k1-codified) entry) carries an **Applicability Profile**: a declared CMO statement. The Context dimensions (the realist "for whom / under what conditions"):

| Context dimension | Values | Source-of-truth (K-tier) | Notes |
|---|---|---|---|
| **Org scale** | single-operator · small-team · multi-team · enterprise | [K2](../disciplines/knowledge-architecture.md#k2-oom) ([operating-model.md](../disciplines/operating-model.md)) + CLAUDE.md § Workspace Owner | [COMPANY_X] = single-operator PMO |
| **Delivery methodology** | per `delivery_approach` enum (Scrum/Kanban/XP/Waterfall/PRINCE2/SAFe/Hybrid/Custom) |  | the one axis  already parameterizes — **USE, do not restate** |
| **Regulatory posture** | none · internal-governance · external-audited · regulated-industry | [K3](../disciplines/knowledge-architecture.md#k3-institutional) (PROJECT.md / CLAUDE.md) | gates research-grade-evidence + formal-audit practices |
| **Team structure** | single-operator-HITL · reviewer-pair · multi-role-board | [K2](../disciplines/knowledge-architecture.md#k2-oom) | the [§938 §4 register L4](../disciplines/knowledge-architecture.md#local-context-leakage-register) datum; mediates reviewer-pair-required practices |
| **Stakeholder complexity** | internal-only · single-external · multi-stakeholder | [K3](../disciplines/knowledge-architecture.md#k3-institutional) (PROJECT.md) | gates exec-briefing / comms-escalation protocols |
| **OOM cadence** | continuous · sprint-boxed · phase-gated | [K2](../disciplines/knowledge-architecture.md#k2-oom) ([operating-model.md](../disciplines/operating-model.md)) | composes with  release-cadence table |

**Profile schema (deterministic — implementation-ready):**

```
Applicability Profile (for practice P):
  UNIVERSALITY:          universal | contextual    # the  axis position
  APPLIES-WHEN:          <Context predicate over the dimensions above; "ALL" for universal practices>
  CONTRAINDICATED-WHEN:  <list of Contraindication Catalog IDs (§3) + any local seam>
  EVIDENCE-TIER:         <defer to  corpus-curation.md; conflict tiebreak input only — NOT defined here>
  RESOLUTION-ON-CONFLICT: <pointer to the §4 precedence-ladder rung that governs P's typical conflicts>
```

A **universal** practice (the bulk of the corpus per the [ 2×2](../disciplines/knowledge-architecture.md#axis-2x2)) has `APPLIES-WHEN: ALL` and an empty contraindication set **unless it embeds a latent seam assumption** ([§3](#contraindication-catalog)). A **contextual** practice declares an explicit Context predicate. This makes *"does P apply in context C?"* a **decidable predicate evaluation**, not interpretation.

---

## §3 Contraindications — the parameterization seam, run forward {#contraindication-catalog}

**The load-bearing reframe (consumes 's seam directly):**  defines the **parameterization seam** = the K1↔K2/K3 boundary where CLAUDE.md "Parameterize over hardcode" bites; its [§4 leakage register](../disciplines/knowledge-architecture.md#local-context-leakage-register) catalogs *current* breaches. **A contraindication is the same seam evaluated prospectively:** a [K1](../disciplines/knowledge-architecture.md#k1-codified) practice that embeds an assumption about K2/K3 context is **contraindicated** in any deployment where that assumption resolves false.

Formally: practice P has a latent contraindication iff P's text presumes a Context value `v` for dimension `D` (an implicit K2/K3 binding) without parameterizing it. **P is contraindicated wherever D ≠ v.**

**Canonical worked example — the [ §4 register L4](../disciplines/knowledge-architecture.md#local-context-leakage-register) datum the taxonomy contract hands forward to :**

> `eval-writer/references/playbook-per-skill.md:38` — *"**HITL present:** yes ([OPERATOR_NAME] reviews outputs). **This is always yes for pmo-platform.**"* (full L4 datum: lines `:38,44,139`, classified `TRUE-LEAK` / K2 in [knowledge-architecture.md §4](../disciplines/knowledge-architecture.md#local-context-leakage-register)).

This is a [K2](../disciplines/knowledge-architecture.md#k2-oom) OOM datum (single-operator HITL) **hardcoded as universal**. The subtle point the framework operationalizes: eval-writer's claim is *factually true for [COMPANY_X]* — the defect is **not the value but that it is asserted universally instead of consumed as a K2-mediated Context input**. This is precisely the distinction 's authorship axis cannot see (the leak is **custom + contextual**; per 's *custom ≠ contextual* proof at [knowledge-architecture.md §2](../disciplines/knowledge-architecture.md#axis-2x2)). The contraindication rubric formalizes the fix: any K1 practice asserting a reviewer/approver chain is **contraindicated when `team_structure ≠ single-operator-HITL`** *and* is a latent seam breach **when it asserts the value rather than reading it from [K2](../disciplines/knowledge-architecture.md#k2-oom)**.

**Contraindication Catalog (initial; extensible durable structure — seeded from the [ §4 register](../disciplines/knowledge-architecture.md#local-context-leakage-register) + the  intake's worked cases):**

| ID | Contraindicated practice class | Fires when (Context predicate) | K-tier mediator | Seam-breach signature |
|---|---|---|---|---|
| **CI-1** | reviewer-pair / multi-person approval-chain practices | `team_structure = single-operator-HITL` | [K2](../disciplines/knowledge-architecture.md#k2-oom) | "a reviewer approves", "second approver", "peer review gate" embedded without K2 read — **the [§938 L4](../disciplines/knowledge-architecture.md#local-context-leakage-register) formalization** |
| **CI-2** | external-stakeholder briefing / exec-comms / escalation protocols | `stakeholder_complexity = internal-only` | [K3](../disciplines/knowledge-architecture.md#k3-institutional) | exec-briefing ceremony with no external audience |
| **CI-3** | research-grade-evidence / formal-audit-required practices | `regulatory_posture ∈ {none, internal-governance}` AND evidence absent | [K3](../disciplines/knowledge-architecture.md#k3-institutional) | mandatory formal audit where lightweight self-review suffices |
| **CI-4** | sprint / velocity ceremonies | `delivery_methodology ∈ {Waterfall, PRINCE2}` (non-time-boxed) | [K2](../disciplines/knowledge-architecture.md#k2-oom) | sprint-planning applied to a phase-gated track |
| **CI-5** | multi-team coordination / cross-squad sync practices | `org_scale = single-operator` | [K2](../disciplines/knowledge-architecture.md#k2-oom) | standup / scrum-of-scrums in a one-person PMO |

**CI-1 is the [§938 §4 register L4](../disciplines/knowledge-architecture.md#local-context-leakage-register) formalization** — the explicit hand-off the  taxonomy contract makes to  ("also an  applicability concern", per the L4 register row). The catalog is a **durable structure** (CLAUDE.md "prefer durable structures over static examples"): rows are added as the corpus surfaces new seam classes; it is **not** a per-practice file (anti-maintenance-debt compliant per the durable-structure ADR).

**K2/K3-mediation statement:** every Contraindication's Context predicate is evaluated against a K2/K3 source-of-truth — never a K1-embedded literal. The K2 OOM *model* home is [`operating-model.md`](../disciplines/operating-model.md); the K2/K3 *values* are CLAUDE.md § Workspace Owner parameters (per the [ placement model](../disciplines/knowledge-architecture.md#placement-model)). A practice that reads its Context input from these sources is **seam-correct**; one that hardcodes the value is the L4 class.

---

## §4 Conflict Resolution — the precedence ladder {#precedence-ladder}

When two practices M_a, M_b both fire in context C with competing outcomes, resolve by this **precedence ladder** (first decisive rung wins). Every rung composes with an existing mechanism — **zero new runtime machinery**:

1. **Contextual localization (rung 1).** If the OOM ([K2](../disciplines/knowledge-architecture.md#k2-oom)) makes one practice's Context predicate match C more *specifically*, it localizes the other. This **is** [`decision-discipline.md`](../disciplines/decision-discipline.md) M1's reconciliation — this framework supplies the *content* ("which practice the OOM makes precedent"); M1 supplies the *procedure* (force the reconciliation in the Decision Briefing). Composition, not contradiction (proof: [§6](#composition-901)). Cross-ref: `decision-discipline.md §2.1`.
2. **Specificity precedence — *lex specialis* (rung 2).** The practice whose declared `APPLIES-WHEN` predicate more specifically matches C beats the more general one. Borrowed from the legal interpretive canon *lex specialis derogat legi generali* (named + attributed — rigorous, not folk-reasoning).
3. **Evidence-tier tiebreak (rung 3).** Equal specificity → the practice with the stronger evidence tier wins. Evidence tiers are **defined by ** ([`corpus-curation.md`](../disciplines/corpus-curation.md)); this framework *references* them as a tiebreak input — it does **not** define an evidence taxonomy (one-source-one-truth; one-directional cross-ref, resolves with 's Stage 5 at Collective Review).
4. **Co-manifestation (rung 4 — generalizes the SPM Bridge).** If the OOM legitimately runs *both* contexts (e.g., `spm_comanaged: true` → an Agile track AND a Waterfall track), the resolution is **produce both framings**, not pick one. This **names and generalizes** [CLAUDE.md § SPM Bridge](<OPERATOR_INSTANCE_CLAUDE_MD>) (the  intake's `[SOURCE]` evidence: "ad-hoc, not generalized to other practice conflicts" — now generalized to any dual-legitimate-context conflict). Composes with [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) when the dual context is methodological.
5. **Escalation (rung 5 — terminal).** Equal specificity, equal evidence, genuinely competing outcomes, single legitimate context → **escalate to operator** via [`decision-discipline.md`](../disciplines/decision-discipline.md) M1 G4 "I don't know" honest-answer. Composes with 's existing escalation guard; introduces no new escalation channel. Cross-ref: `decision-discipline.md §2.1`.

Every rung routes through or reinforces an existing mechanism (M1, evidence tiers, methodology axis, CLAUDE.md SPM Bridge). This is the structural guarantee of the no-contradiction AC: the framework is reference *content* the existing decision procedure consults, never a parallel runtime.

---

## §5 Rubric Template {#rubric-template}

The reusable applicability rubric — a **parameterized structure**, not prose. Skill reference docs **embed an instantiated rubric** (not a separate file per practice — anti-maintenance-debt compliant). Copy-paste template:

```
### Applicability (per applicability-framework.md)
- **Universality:** universal | contextual            # §938 axis position
- **Applies when:** <Context predicate | ALL>
- **Contraindicated when:** <Contraindication Catalog IDs (§3) + any local seam>
- **On conflict:** <precedence-ladder rung (§4) that governs this practice's typical conflicts>
- **Evidence tier:** <ref  corpus-curation.md; tiebreak input only>
```

**Demonstrated in** (≥2 skill reference docs, per AC item 4 — disjoint from 's self-demonstration in `corpus-curation.md`): [`delivery-engine/references/sprint-defaults.md`](../../operations/skills/delivery-engine/references/sprint-defaults.md) (CI-4 methodology-axis instance) and [`comms-writer/references/channel-formats.md`](../../operations/skills/comms-writer/references/channel-formats.md) (CI-2 stakeholder-axis instance). Both demonstration-target skills are `skill_discipline_migrated_v10_2: true` — their `references/` edits route via `pmo-skill-editor` Mode A per the skill-discipline enforcement layer (a PMO governance mechanism, not an upstream conflict; see the Upstream-compatibility ADR).

---

## §6 Composition with decision-discipline.md  {#composition-901}

**Claim:** `applicability-framework.md`  and [`decision-discipline.md`](../disciplines/decision-discipline.md) (, CLOSED) **compose; they do not contradict.** Proof, four independent legs:

1. **Different artifact layers.**  is a *runtime interrogation procedure* (M1/M2/M3 templates filled per Decision Briefing).  is *reference content* (criteria / contraindications / ladder) the M1 step **consults** when the decision class is "should practice P apply in context C?". A procedure and the data it reads cannot contradict — they compose by construction.
2. **Exact existing precedent.** `decision-discipline.md §7.4` already codifies this pattern for: is "one concrete M1 application at the D-decision-content level; the briefing-level Localization Check operates at the consumer-recommendation level — complementary, not redundant."  is the analogue at the **practice-applicability** content level — the same composition class already blessed by the  deliverable's own text.
3. **Zero mechanism collision.**  adds/modifies/removes **zero** M1/M2/M3 templates, **zero** §3 triage rows, **zero** §5 ceremony guards, **zero** §4 pattern-cache schema. It is consulted *by* M1; it does not re-implement M1. Precedence-ladder rungs 1 and 5 explicitly *route through* M1 reconciliation and M1 G4 escalation — reinforcing, not competing.
4. **Operator-sanctioned scope partition.**  assigns  → scope **4.5**,  → scope **4.1/4.2/4.3** — deliberately separated by the initiative umbrella.  occupies the parallel *content* slot, not 's *procedural* slot.

**Binding direction (one-directional — keeps composition clean):** `applicability-framework.md` cites `decision-discipline.md §2.1` as its runtime invocation point. **`decision-discipline.md` requires ZERO edit and is UNEDITED by .** A future optional `decision-discipline.md §7.5` symmetric cross-ref (mirroring §7.4 for ) would tighten bidirectionality but is **out of  scope** — editing the CLOSED  deliverable is exactly the contradiction-risk surface the AC guards. Composition is clean *without* it (one-directional binding is sufficient). Tracked as an optional operator/Collective-Review follow-up, **not** a  edit.

---

## §7 Boundaries {#boundaries}

| Boundary | Relationship | Action |
|---|---|---|
|  — [`decision-discipline.md`](../disciplines/decision-discipline.md) (runtime procedure) | **Satisfied.**  owns the *procedure* (M1/M2/M3 interrogation); this doc owns the *content* M1 consults for the practice-applicability sub-class. Provider/consumer; one-directional ([§6](#composition-901)). | Compose; **decision-discipline.md UNEDITED**. |
|  — [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) (one axis) |  owns the **methodology** applicability axis (`delivery_approach` enum); this doc owns the **general** model — methodology is *one* Context dimension ([§2](#applicability-profile)). | Cite + USE; do not restate the enum. |
|  — [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (consumed grounding) | Hard-dep (internal G0). This doc consumes the [universality axis](../disciplines/knowledge-architecture.md#universality-axis), [2×2](../disciplines/knowledge-architecture.md#axis-2x2), [parameterization seam](../disciplines/knowledge-architecture.md#parameterization-seam), [K1–K5](../disciplines/knowledge-architecture.md#k1-codified), and [§4 register L4 → CI-1](../disciplines/knowledge-architecture.md#local-context-leakage-register). | Consume by stable anchor; redefine nothing. |
|  — [`operating-model.md`](../disciplines/operating-model.md) (K2 model home) | The K2 OOM *model* lives in operating-model.md; K2/K3 *values* are CLAUDE.md parameters. This doc references K2 as the contraindication *mediator*. | Cite K2 home; do not restate the OOM. |
| **[`terminology-glossary.md`](../specs/terminology-glossary.md)** — disjoint methodology glossary | Carries Area/Domain/Function/Process/Stage/WBS/Scope — **no** applicability/contraindication/realist terms. No collision; the  umbrella body owns "Contraindication"/"Universality axis". | Cross-reference; redefine nothing. |
| **** — forward consumer (hard-dep +) | Forward-only; consumes this doc's stable anchors. Out of this release. | **No action** — flagged for the forward-consumer hub. |
