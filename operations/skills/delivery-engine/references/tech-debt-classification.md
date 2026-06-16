<!-- reference-durability: allow-link -->
<!-- provenance: EXTERNAL-FRAMEWORK (Fowler quadrant) + IN-CORPUS-ADOPTED (CoD) + REASONED-DESIGN (sort tie-break) -->

# Tech-Debt Classification

## Purpose

This document is the canonical source of **tech-debt classification and prioritization** for the delivery-engine skill — how every tech-debt item is placed in a **Fowler quadrant** (intent × awareness), how its **Cost of Delay (CoD)** is scored as a tech-debt *lens* over the platform-canonical CoD components, and how the two combine into the **(quadrant × CoD) sort** that orders the tech-debt slice and fills the under-floor capacity deficit. It is read by **Mode D (Sprint Planning)**: Mode D reads the quadrant rubric (§1) when classifying each in-plan tech-debt item, the CoD scoring lens (§2) when quantifying per-item Cost of Delay with a confidence tier, and the (quadrant × CoD) lexicographic sort (§3) when ordering the tech-debt slice and pulling the top-ranked items into the tech-debt allocation up to the floor.

This doc owns the tech-debt **classification + ranking discipline**. It does **not** own — and does **not restate** — the values and contracts it consumes:

- the **CoD component model** — `CoD = User-Business Value + Time Criticality + Risk Reduction / Opportunity Enablement (RR|OE)`, Fibonacci-scored `{1,2,3,5,8,13,20}`, feeding `WSJF = CoD ÷ Job Size` — is owned by [`intake-governance.md`](../../intake-desk/references/intake-governance.md) §2 (the platform-canonical, single registered home, registered in [`framework-catalog.md`](../../../../core/specs/framework-catalog.md) as "Cost of Delay (Reinertsen 2009)"); this doc references the components **by role** and never re-derives a competing formula;
- the **capacity floor → ranking contract** — floor % / allocation ratio / under-floor deficit / aged-item set — is owned by [`tech-debt-capacity.md`](tech-debt-capacity.md) (#366); this doc reads the four named outputs **by role**, ranks items to fill the deficit, and never re-derives the floor;
- the **>90-day aging disposition** (escalate / reclassify) is owned by [`tech-debt-capacity.md`](tech-debt-capacity.md) §2 (adopted in turn from the `SKILL.md` Mode A backlog-scan aging tier); this doc consumes the aged-item set as a **ranking input**, it does not re-derive the threshold.

**Sibling relationship.** This doc is the topical home for tech-debt **classification + ranking**. Its siblings own adjacent axes: [`estimation-standards.md`](estimation-standards.md) owns **estimation** (the focus-factor table, the buffer three-zone model, the buffer-consumption RAG §4.1, the milestone-variance SPI RAG §7); [`capacity-model.md`](capacity-model.md) owns the **supply** calculation (effective capacity, context-switching, the 60/20/20 split); [`tech-debt-capacity.md`](tech-debt-capacity.md) owns the tech-debt **budget/floor** (#366 — the allocation-ratio floor-RAG, the aged-debt disposition, the rework-rate alert); **this doc (`tech-debt-classification.md`) owns the tech-debt *classification/ranking*** (the Fowler quadrant, the CoD lens, the (quadrant × CoD) sort); and [`intake-governance.md`](../../intake-desk/references/intake-governance.md) §2 owns the **canonical CoD/WSJF formula** the CoD lens references by role. Where this doc needs the CoD components, the floor contract, or the aging threshold, it references each by its role and does not restate the value — the same single-source seam the cohort docs hold for the focus factor.

**Content provenance (the honest three-way split).** The **Fowler quadrant model (§1)** is **EXTERNAL-framework-grounded** — Fowler, *Technical Debt Quadrant* (2009 bliki), newly registered in [`framework-catalog.md`](../../../../core/specs/framework-catalog.md) ("Fowler Technical Debt Quadrant" row, distinct from the existing YAGNI "Fowler design heuristics" row). The **Cost of Delay (§2)** is **adopted by reference** — the in-corpus canonical CoD component model from `intake-governance.md` §2, expressed here as a tech-debt scoring lens, never re-derived. The **(quadrant × CoD) sort tie-break ordinal (§3)** is **reasoned-design** — the CoD-primary ordering follows the registered WSJF economic-sequencing doctrine (HIGH confidence); the 4-way quadrant tie-break order is reasoned from Fowler's own quadrant-urgency semantics (MEDIUM confidence, Fowler-urgency-anchored, not a directly-quoted value). This split (one external-registered, one in-corpus-adopted, one reasoned-ordinal) is the doc's grounding posture.

---

## 1. Fowler Quadrant Classification

Every tech-debt item is placed in **exactly one** of four quadrants on the **intent × awareness** axes (Reckless | Prudent × Deliberate | Inadvertent). The quadrant gives the *type-urgency* of the debt — the differential-prioritization signal that uniform "tech debt" treatment loses. This model is registered in [`framework-catalog.md`](../../../../core/specs/framework-catalog.md) (the "Fowler Technical Debt Quadrant" row — distinct from the YAGNI "Fowler design heuristics" row).

| Quadrant | Axis (intent × awareness) | Reading | Prioritization tilt |
|---|---|---|---|
| **Reckless / Deliberate** | Knew better, shipped wrong anyway | Highest-urgency debt — a conscious bad-practice shortcut ("no time for design") | **Surfaces first** when paired with high CoD |
| **Prudent / Deliberate** | Chose velocity, understands the cost, owns it | Managed, owned residual ("we must ship now and deal with the consequences") — pay down when CoD warrants | Mid — ranked by CoD |
| **Reckless / Inadvertent** | Didn't know better — a skill/knowledge gap | Education-needed; the *item* is paid down by CoD, the *pattern* needs a capability fix (route to RAID) | Mid — ranked by CoD; pattern → RAID |
| **Prudent / Inadvertent** | "Now we know how we should have done it" — learned too late | Refactor when context demands; lowest standalone urgency | Lowest — ranked by CoD |

### 1.1 Classification method

- **Place every tech-debt item in exactly one quadrant** by reading the item's intent (was the shortcut a conscious choice — *Deliberate* — or unintended — *Inadvertent*?) and awareness (did the team know the better practice at the time — *Reckless* if they knew and shipped wrong, *Prudent* if the choice was informed and owned).
- **Pattern routing.** A **Reckless / Inadvertent** classification names a *capability gap*, not just a debt item — route the underlying pattern to RAID (per [`raid-templates.md`](raid-templates.md)) so the recurrence is addressed, while the item itself is still paid down by its (quadrant × CoD) rank.
- **Negative path — `unclassified` (never default-to-a-quadrant).** When an item's intent or awareness is **not determinable** from available context, do **NOT** guess a quadrant — a wrong quadrant mis-ranks the item. Emit:

  ```
  quadrant: unclassified — intent/awareness not determinable; classify before prioritizing
  ```

  and **exclude the item from the ranked fill** until it is classified. Defaulting an undeterminable item into a quadrant is forbidden (it is the §1 condition behind the Domain-Specific Failure Mode in `SKILL.md`).

---

## 2. Cost of Delay (tech-debt lens)

**The CoD formula is NOT defined here.** Cost of Delay is the platform-canonical component model owned by [`intake-governance.md`](../../intake-desk/references/intake-governance.md) §2: `CoD = User-Business Value + Time Criticality + Risk Reduction / Opportunity Enablement (RR|OE)`, each component scored on the **relative Fibonacci scale `{1,2,3,5,8,13,20}`** (scored relatively across the candidate set), the three components summed. This doc **references those components and their scale by role** and does not restate the formula — the "register, don't re-derive" duplicate-source discipline that `intake-governance.md` §2's own cross-skill consistency note binds delivery-engine to.

**The CoD here is the same CoD as `intake-governance.md` §2.** This is the WSJF *numerator*. This doc applies CoD to **intra-tech-debt-slice ranking only** (§3). Full **WSJF (`CoD ÷ Job Size`) for cross-portfolio sequencing stays intake-desk's job** (and is consumed by ppm-agent's WSJF intake scoring) — this doc does not compute portfolio WSJF. Job Size (remediation effort for a debt item) is available as a secondary efficiency tie-break, but the headline ranking is **(quadrant × CoD)** per the AC, not full WSJF.

### 2.1 Tech-debt scoring lens (how a debt item scores each canonical component)

The issue's speed/risk/operational framing is **not a competing CoD formula** — it is the *lens* for scoring the canonical components for a debt item:

| Canonical CoD component (`intake-governance.md` §2) | Tech-debt scoring lens (how a debt item scores this component) |
|---|---|
| **User-Business Value** | Value *unblocked* by paying the debt — features / throughput the debt currently suppresses (the "speed cost: blocks N features/sprint" framing) |
| **Time Criticality** | How fast the debt's cost is *rising* — compounding interest, an approaching forcing event, a dependency clock (the rising-cost axis behind "operational cost: recurring monthly impact"; aging an item raises this component) |
| **Risk Reduction / Opportunity Enablement (RR\|OE)** | Incident / operational risk the debt carries — `probability × incident severity`, plus the recurring operational drag retired by fixing it (the "risk cost" + "operational cost" framing) |

CoD for a debt item = **sum of the three components** (canonical), scored relatively per the candidate debt set.

### 2.2 Confidence tier (the mitigation for speculative CoD)

Every per-item CoD value carries a **confidence tier** — the mechanism for honest scoring when measured inputs are absent:

| Tier | Meaning |
|---|---|
| **HIGH** | Measured / instrumented (incident data, captured operational cost, observed throughput suppression) |
| **MEDIUM** | Inferred from a comparable item or a reasoned estimate with partial data |
| **LOW** | Estimated from context only, no measured input |

**A CoD value is REQUIRED for every tech-debt item — even at LOW confidence.** The tier is the mitigation, not an excuse to skip.

**Negative path — CoD not measurable.** When the measured inputs (incident probability/severity, recurring operational cost) are **not instrumented**, score the canonical components at **LOW confidence from available context** — do **NOT** fabricate a HIGH-confidence number, and do **NOT** skip CoD (the AC requires a CoD value per item even at LOW confidence). This mirrors `tech-debt-capacity.md` §3's not-computable posture for rework rate: name the confidence honestly, never fabricate.

---

## 3. (Quadrant × CoD) Sort Weighting

The tech-debt slice is ordered by a **lexicographic sort**, NOT an invented numeric quadrant-weight multiplier. CoD (the registered economic measure) is the **primary** key; the Fowler quadrant is the **tie-break / tilt** within a CoD band. This keeps CoD primary — consistent with the WSJF economic-sequencing doctrine (`intake-governance.md` §2: higher CoD = higher economic priority) — while the quadrant adds the type-urgency tilt the model exists to provide, **without minting unfalsifiable quadrant-weight constants**.

**Decision rule** (reusing the cohort's `WHEN…THEN…` decision-rule format):

- **WHEN** ranking two debt items **THEN** order by **CoD descending** (primary key).
- **WHEN** two items' CoD are within one Fibonacci step (a tie band) **THEN** break the tie by **quadrant urgency**: Reckless/Deliberate → Prudent/Deliberate → Reckless/Inadvertent → Prudent/Inadvertent.
- **WHEN** a Reckless/Deliberate item carries high CoD **THEN** it surfaces at the top (both keys agree — the AC case: a Reckless/Deliberate high-CoD item ranks above a Prudent/Inadvertent low-CoD item).

**Tilt note (the one soft modeling choice).** The quadrant tie-break is **ordinal**, not a numeric multiplier — this avoids minting four unfalsifiable weight constants. CoD stays the cardinal economic primary; quadrant is the ordinal tilt within a CoD tie band.

**Naming guard (normative).** Name this the **"tech-debt rank"** / the **"(quadrant × CoD) sort"** — **NEVER "debt score."** A single fabricated cardinal "debt score" would imply a numeric quadrant×CoD product that this model deliberately does not compute (the "×" reads as *combine*, not *arithmetically multiply*). This mirrors the cohort naming-guard technique (the `tech-debt-capacity.md` "tech-debt floor, never debt budget overage / debt RAG" guard, and the estimation "milestone variance, never Schedule Variance" guard).

---

## Consumes: #366 Floor → Ranking Contract

This section is the **consumer side** of the floor → ranking contract that [`tech-debt-capacity.md`](tech-debt-capacity.md) (#366) owns (its "Floor → Ranking Contract" section). #366 sets the **budget**; this doc ranks what fills it. This doc reads four named outputs from `tech-debt-capacity.md` **by role** and does **NOT** re-derive the floor or restate #366's parameters:

| # | Output (owned by `tech-debt-capacity.md`) | What this doc does with it |
|---|---|---|
| **(a)** | **Floor %** — the per-sprint floor (by role from `sprint-defaults.md` §1.2; the 15% non-negotiable minimum, referenced never restated) | The target line the ranking fills items up to |
| **(b)** | **Allocation ratio** — tech-debt-allocated ÷ sprint capacity | The current fill level against the floor |
| **(c)** | **Under-floor deficit** — `max(0, floor − allocation-ratio) × sprint capacity` | The capacity the ranked list must fill |
| **(d)** | **Aged-item set** — items >90 days, each pre-dispositioned escalate/reclassify | A ranking input: aged candidates pulled into the deficit fill |

**Contract semantics.** This doc ranks tech-debt items **(quadrant × CoD)** and the **ranked list fills the under-floor deficit (c) up to the floor (a)** — the highest-rank items are pulled into the tech-debt slice until the deficit is consumed. The **aged-item set (d)** feeds the ranking as a priority input: an aged item (>90d) enters the ranking with its #366 disposition, and aging naturally raises its **Time Criticality** component (§2.1) → raises its CoD → raises its rank, so **no separate aging-weight is needed**. This doc does **NOT** re-derive the floor, the deficit, or the aging threshold — the ownership seam is: `tech-debt-capacity.md` owns the *budget/floor*; `tech-debt-classification.md` (this doc) owns the *classification/ranking*.

**Negative path — #366's contract outputs absent.** When the floor / deficit have **not been computed** (e.g., the capacity floor check has not run for the plan), the ranking is **still produced** (the (quadrant × CoD) sort orders the debt items), but the **fill target is unknown** — state this and recommend running the tech-debt capacity-floor check (Mode D's `tech-debt-capacity.md` §1 behavior) first. The ranking sorts; only the deficit-fill is deferred.

---

## Applicability

Per [`applicability-framework.md`](../../../../core/disciplines/applicability-framework.md).
The tech-debt classification + ranking disciplines below are a **contextual** practice (org-scale +
methodology axes) — they apply to the tech-debt backlog of a *managed delivery team* running
time-boxed sprints, not to the single-operator platform running the PMO.

- **Universality:** contextual            # org-scale axis + methodology axis
- **Applies when:** the tech-debt backlog being classified/ranked is that of a **managed
  delivery team** (`org_scale ∈ {small-team, multi-team}`) on a time-boxed track
  (`delivery_approach ∈ {Scrum, XP, SAFe, Hybrid (iterative), Custom (timeboxed)}`) — the
  agile/SPM squads a TPM plans for in Mode D, whose tech-debt slice is floored by
  `tech-debt-capacity.md` and ranked here.
- **Contraindicated when:** **CI-5** — do **NOT** apply the Fowler quadrant classification, the
  CoD ranking, or the (quadrant × CoD) deficit-fill to the **single-operator PMO's own
  throughput** (the operator is not a sprint team; the platform's own improvement allocation is
  governed by its release process, not by a sprint tech-debt slice); also **CI-4** for the
  per-sprint deficit-fill mechanics on non-time-boxed (Waterfall/PRINCE2) tracks, where
  tech-debt paydown is phase-scheduled rather than sprint-allocated (calibrate via the
  `delivery_approach` enum, consistent with `tech-debt-capacity.md` §1).
- **On conflict:** `decision-discipline.md` M1 (contextual localization); co-manifestation
  when `spm_comanaged: true` — produce both the agile ranking framing and the phase-gate
  framing rather than forcing one.

---

## Version History

| Version | Change |
|---------|--------|
| v2.01 | Initial — Fowler quadrant classification (§1, the 4 quadrants Reckless/Prudent × Deliberate/Inadvertent + the `unclassified` negative path; registered in `framework-catalog.md` as "Fowler Technical Debt Quadrant"), Cost-of-Delay tech-debt lens (§2, CoD components referenced by role from `intake-governance.md` §2 — not re-derived — with the per-item HIGH/MEDIUM/LOW confidence tier + not-measurable negative path), the (quadrant × CoD) lexicographic sort (§3, CoD-descending primary + quadrant ordinal tie-break + the "tech-debt rank, never debt score" naming guard), and the consumer side of #366's floor → ranking contract (ranks items to fill the under-floor deficit up to the floor; floor referenced by role, never re-derived). Created for #180 per Stage-5 design #1219. |
