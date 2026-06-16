<!-- reference-durability: allow-link -->
# PPM Intake Governance

## Purpose

Canonical reference for how the **PPM Agent** applies intake-governance discipline to a **new request that lands on an already-loaded managed portfolio** — a new project/initiative request surfaced in a transcript or intake artifact, or an explicit "should we take this on?" ask. This document is the **doc-of-record** for two things the PPM Agent owns at the in-flight intake surface:

- **(a)** the **capacity-aware intake-routing rule** — the accept / flag / trade-off decision on a new request scored against the portfolio's current effective capacity and utilization band (§3);
- **(b)** the **trade-off-analysis output contract** — the explicit "if this comes in, what gives?" package the agent emits when accepting the request would push the portfolio near or over its capacity ceiling (§4).

Everything the agent *consumes* to make those two decisions — the WSJF formula and its Cost-of-Delay component model, the business-case tiers, the demand-source taxonomy, the Cost-of-Delay elicitation prompts, and the effective-capacity formula plus the utilization bands — is **owned canonically elsewhere and referenced by role here, never re-derived** (§1, §2, §5). This document is the **application layer**; the policy and data layers live in the intake desk's intake-governance reference and in the delivery-engine capacity model.

**Front-door vs. downstream twin (the framing that places this doc).** The intake desk scores and tiers demand **at the front door**, before it is a committed work item ([`../../intake-desk/references/intake-governance.md`](../../intake-desk/references/intake-governance.md)). The PPM Agent applies the **same** WSJF and the **same** governance vocabulary **downstream**, to a request landing on a portfolio that already carries committed work — and adds the capacity-aware routing and trade-off layer that is genuinely the PPM Agent's job. This is the structural-twin completion the intake desk's intake-governance §8 already names: the front-door surface (intake desk) and the downstream surface (PPM Agent) are two points of one prioritization discipline. The PPM Agent's other downstream-prioritization reference, [`escalation-thresholds.md`](escalation-thresholds.md), is the RAID-side twin of this same pattern (it references delivery-engine's canonical risk scale and adds only the routing layer); this document is its intake-side counterpart.

**Boundary note (load-bearing — prevents axis collision).** A **business-case tier is an investment/funding axis**, a **demand-source tag is an origin axis**, and **capacity-aware routing is a supply axis** — all three are orthogonal to one another and to the work-item altitude/type. A single in-flight request has all of them: a Tier-2 project-class demand, tagged Strategic, that on acceptance would move the portfolio into the Amber capacity band. State each as a separate attribute; do not fold one into another, and do not re-derive any of the three rubrics here (they are referenced in §1 and §2).

**Consumed by:** PPM Agent SKILL.md — the intake-governance pass (keyed to the "new request landing on the portfolio" trigger), surfaced through the **existing** output Sections 5 (Decisions needed) for the tier/WSJF-ranked accept/defer decision, 6 (Top risks) when over-capacity, and 8 (Tracker update instructions) to log the scored item. No new top-level output Section is introduced.

> **Why the line-1 `allow-link` marker is present (and must stay).** This file is K1 codified-knowledge (it lives under `*/skills/*/references/`), which makes it durable corpus. It carries net-new markdown links to cross-skill sources — the references to the intake desk's `intake-governance.md`, the delivery-engine `capacity-model.md`, `sprint-defaults.md`, and `framework-catalog.md` in this Purpose and below. The Reference Durability Standard flags any markdown link on a net-new line in a durable-corpus file as a **Class L** finding; the sanctioned suppressor for Class L is exactly the line-1 `<!-- reference-durability: allow-link -->` marker. That marker is **mandatory here, not stylistic** (the reference-durability CI workflow is a required status check). Do **not** remove it to "match the sibling ppm-agent refs" (most carry no cross-skill links) — `escalation-thresholds.md` carries it for the same reason; this file does too, and the standard, not the directory, governs.

---

## 1. Business-Case Tier + Demand Source — referenced, not re-derived

The PPM Agent tags each in-flight intake request with a **business-case tier** and a **demand-source tag**. Both rubrics are **owned by the intake desk** and consumed here by role — this document restates neither.

- **Business-case tier (Tier 1 / Tier 2 / Tier 3).** Owned by [`../../intake-desk/references/intake-governance.md`](../../intake-desk/references/intake-governance.md) §1 (the deterministic tier partition keyed to funding/effort magnitude). The PPM Agent reads that partition and assigns the request its tier; it does not define a second partition. A request below the project threshold (a bug or task-altitude item) is Tier 1 by that rule.
- **Demand-source tag (6-type MECE taxonomy).** Owned by the same document, §4 (Strategic/planned · Operational/BAU · Defect/corrective · Regulatory/compliance · Stakeholder request/enhancement · Technical/debt & risk reduction). The PPM Agent tags the request with exactly one source, applying the canonical §4 MECE tie-break ("tag by what is driving the work") when a request reads as two — referenced, not re-derived.

**Why referenced, not restated.** The tier partition and the demand taxonomy each have exactly one canonical home so they cannot drift. Re-authoring them here would create a second source of a single rubric (the "register, don't re-derive" duplicate-source discipline) — the same reason the intake desk's own document references the altitude model rather than copying it.

---

## 2. WSJF / Cost of Delay — referenced, not re-derived

The WSJF formula (`WSJF = CoD ÷ Job Size`), its Cost-of-Delay component model (User-Business Value + Time Criticality + Risk Reduction / Opportunity Enablement), and the relative Fibonacci scoring scale are **owned canonically** by [`../../intake-desk/references/intake-governance.md`](../../intake-desk/references/intake-governance.md) §2, which is the platform's single registered home of the formula (registered against the "Cost of Delay (Reinertsen 2009)" lineage in [`../../../../core/specs/framework-catalog.md`](../../../../core/specs/framework-catalog.md)). The Cost-of-Delay **elicitation prompts** — the conversational source for the component values when the PPM Agent must populate them from a transcript — are owned by §6 of that same document.

**The PPM Agent scores an in-flight intake request against that rubric; it does not define a second formula.** This is the explicit cross-skill contract: the intake desk's §2 cross-skill note states that *other surfaces reference the name, they do not re-derive a competing formula* — this document is one of those surfaces, and it honors that note. When the PPM Agent must populate the four CoD inputs from an artifact, it uses the §6 elicitation prompts as the conversational source and applies the §6 "unresolved input → owned assumption, never a fabricated score" rule (see the negative-path table in §4).

**What this satisfies.** Each in-flight intake request receives a WSJF value with its CoD components and Job-Size inputs shown — by *consuming* the canonical rubric, not by re-stating it under this skill. A reference-by-role pointer is the documented home for the formula *as the PPM Agent applies it*; the formula's definition stays at its single canonical home.

---

## 3. Capacity-Aware Intake-Routing Rule (NET-NEW — this document's contribution)

This is the genuinely-new value the PPM Agent adds at the in-flight surface: a deterministic accept / flag / trade-off decision on a **new** request, scored against the portfolio's **current** effective capacity. The capacity rubric itself is referenced, not re-derived; the *routing rule over it* is owned here.

**The capacity rubric this rule reads (referenced, read-only):**

- **Effective capacity** — the multiplicative `Nominal × FF × CS(N) × allocation` chain, owned by [`../../delivery-engine/references/capacity-model.md`](../../delivery-engine/references/capacity-model.md) §1 (with the focus factor and the context-switch penalties at §2–§3). The PPM Agent reads the portfolio's effective supply from this model; it does not compute a second capacity figure.
- **Demand-supply utilization band** — owned by the same model, §9: **🟢 Green ≤ 0.85 / 🟡 Amber 0.85–1.00 / 🔴 Red > 1.00** (demand-supply ratio). The Green ceiling of 0.85 is itself anchored to the planned-utilization cap in [`../../delivery-engine/references/sprint-defaults.md`](../../delivery-engine/references/sprint-defaults.md) §1.2 (planned utilization 75%, valid range 70–85%, hard cap 85%).

**The routing rule (deterministic over the referenced band):**

| Resulting band on acceptance | What the new request would do to utilization | PPM Agent action |
|---|---|---|
| **🟢 Green (≤ 0.85)** | The portfolio absorbs the request with headroom intact | Route the accept/sequence decision to **Section 5** with the request's WSJF and tier; no capacity flag |
| **🟡 Amber (0.85–1.00)** | Accepting the request moves the portfolio to/over the planned-utilization cap (the 75–85% planned band / the 0.85 demand-supply boundary) — the reserve is being consumed | **Flag "near capacity"** and **trigger the trade-off package (§4)**; surface to **Section 5 / Section 6** |
| **🔴 Red (> 1.00)** | Accepting the request would over-commit the portfolio — committed demand would exceed effective supply | The **trade-off package (§4) is mandatory**; the accept decision is surfaced to **Section 5 / Section 6** as an explicit de-commit / re-scope / hold choice — **never a silent over-commit** |

**The "near capacity" trigger reconciliation (load-bearing — read this).** The originating acceptance criterion phrases the capacity flag as "near / over **80%** utilization." `capacity-model.md` has **no 80% utilization threshold** — its demand-supply bands enter Amber at **0.85**, and `sprint-defaults.md` §1.2 caps planned utilization at **75% (range 70–85%)**; the only "80%" in the capacity model is the `CS(4) = 0.80` context-switch multiplier, which is a productivity figure, not a utilization threshold. This document therefore **flags against the canonical Amber band (demand-supply ratio ≥ 0.85, or planned utilization at/over the 75–85% planned cap), reading the live value from `capacity-model.md` §9 and `sprint-defaults.md` §1.2 by role, and treats the acceptance criterion's "80%" as the operator's *intent* ("warn before the ceiling")** — which the canonical 75% planned cap and the 0.85 Amber entry already express. No unanchored 80% constant is introduced (the config-field and duplicate-source disciplines forbid minting a near-duplicate threshold one notch below the canonical 0.85). The flag fires as utilization approaches/exceeds the canonical cap; the over-ceiling Red reading forces the trade-off.

**Application rule (normative).** Read the portfolio's effective capacity (§1 of the capacity model) and current demand-supply band (§9) before rendering the accept/defer decision. When acceptance would move the band into Amber or push planned utilization to/over the cap, the flag fires and the trade-off package is produced; when it would move the band into Red, the trade-off is mandatory and the accept decision is surfaced as an explicit choice. A Red reading is never a status note — it is a forcing function.

---

## 4. Trade-Off-Analysis Output Contract (NET-NEW — this document's contribution)

When the near/over-capacity flag (§3) fires, the PPM Agent's output contains an **explicit trade-off package** — the "if this comes in, what gives?" analysis — surfaced through the existing Section 5 (Decisions needed) decision-package contract, escalated to Section 6 (Top risks) when the band is Red. The package has three required parts:

| Part | Content |
|---|---|
| **What the new request displaces** | The currently-committed item(s) whose WSJF is **lower** than the new request's. The new request only enters ahead of work it out-prioritizes economically — WSJF economic-sequencing decides what gives, not arrival order. If no committed item scores lower, the trade-off is "hold the new request or add capacity," not "displace lower-value work." |
| **The explicit choice** | Framed as a decision package per Section 5: *"to take request X (WSJF n), defer / de-scope committed item Y (WSJF m); or hold X."* Carries a reversibility tier and confidence per the skill's Reversibility Discipline. |
| **The capacity arithmetic** | Current effective capacity, the request's Job-Size draw, and the resulting utilization/band — each sourced from `capacity-model.md` by role, shown inline so the decision is a definite result, not an assertion. |

**Why the trade-off is forced, not optional.** An over-capacity intake accepted silently is an over-commit the portfolio cannot honor from current effective supply — the exact pathology the demand-supply Red band (`capacity-model.md` §9) exists to surface. Forcing the trade-off at intake makes the displacement explicit and economically grounded (lower-WSJF work yields to higher-WSJF work) rather than letting the newest request crowd the queue by recency. This is the intake-side application of the same "if we do this, what do we stop?" MoSCoW discipline the intake desk's intake-governance §5 prescribes for the front-door surface.

**Negative paths (required — every behavior defaults explicitly on absent input; never fabricate):**

| Condition | PPM Agent behavior |
|---|---|
| **Capacity data unavailable** (no `capacity-model.md` inputs / current portfolio utilization not determinable) | Do **not** fabricate a utilization number. Emit `[ASSUMPTION – CONFIRM] current utilization not determinable — owner: TPM — to close: provide team/sprint capacity`, **score WSJF anyway** (it is capacity-independent), and state that the trade-off cannot be computed until utilization is known. The WSJF score, tier, and demand tag still emit. |
| **CoD components not scorable from the artifact** | Score at LOW confidence from available context per the intake desk's `intake-governance.md` §6 "unresolved input → owned assumption, never a fabricated score" rule (referenced). **Never skip the WSJF value** — a value is always emitted, even at LOW confidence, with the assumption owned. |
| **Demand source ambiguous** (reads as two of the six types) | Apply the canonical §4 MECE tie-break ("tag by what is driving the work"); state the driver in one line when the tag is non-obvious. Referenced, not re-derived. |
| **Request is not a fundable demand unit** (a bug or task-altitude item below the project threshold) | Business-case tier is **Tier 1** (§1); the full WSJF / capacity-route / trade-off pass is a **no-op beyond the tier tag** — this is correct, not an error (mirrors the canonical Tier-1 "no formal case" rule). |

---

## 5. Cross-Skill Contract

This section makes the cross-skill dependencies visible at deploy time, per the modular-monolith public-API discipline, and enumerates the maintenance couplings.

**Inbound references (consumed here, owned elsewhere — referenced, not copied):**

- [`../../intake-desk/references/intake-governance.md`](../../intake-desk/references/intake-governance.md) — the WSJF formula + CoD components + Fibonacci scale (§2), the CoD elicitation prompts (§6), the business-case tier partition (§1), the demand-source taxonomy (§4), and the front-door MoSCoW "what do we stop?" discipline (§5). All consumed by role in this document's §1, §2, and §4.
- [`../../delivery-engine/references/capacity-model.md`](../../delivery-engine/references/capacity-model.md) — the effective-capacity formula (§1), the context-switch penalties (§3), and the demand-supply RAG bands (§9). Read-only by role in §3.
- [`../../delivery-engine/references/sprint-defaults.md`](../../delivery-engine/references/sprint-defaults.md) — the planned-utilization cap (75%, range 70–85%, §1.2) the §3 routing rule reads. Read-only by role.
- [`../../../../core/specs/framework-catalog.md`](../../../../core/specs/framework-catalog.md) — the "Cost of Delay (Reinertsen 2009)" framework lineage the WSJF formula rides; the catalog's `canonical_doc` points at the intake desk's `intake-governance.md`, not here. Referenced for provenance only.

**Vocabulary-consistency note (the three-surface CoD/WSJF seam).** Three surfaces reference Cost of Delay / WSJF across the platform, and **all three resolve to the intake desk's `intake-governance.md` §2; none re-derives the formula:**

- **intake desk** (`intake-governance.md`) — the **canonical owner**: scores demand **at the front door** before it is a committed work item, and owns the formula, the CoD component model, the scoring scale, the business-case tiers, and the demand-source taxonomy.
- **PPM Agent** (this document) — applies that same WSJF to **a request landing on an already-loaded managed portfolio**, and adds the **capacity-aware routing + trade-off layer** (the downstream half of the front-door/downstream twin).
- **delivery-engine** (`capacity-model.md` / its tech-debt ranking) — applies Cost of Delay (the WSJF numerator) to **intra-tech-debt-slice ranking**; it does **not** compute portfolio WSJF — that is the intake surfaces' job.

The boundary, stated once: **intake desk = front-door demand scoring; PPM Agent = in-flight portfolio-intake scoring + capacity routing + trade-off; delivery-engine = tech-debt-slice CoD ranking.** Three application points, one canonical formula.

**Maintenance couplings (honor on any change to the source):**

1. **Formula or rubric re-tune.** If the intake desk's `intake-governance.md` re-tunes the WSJF formula, the CoD component model, the scoring scale, the tier partition, or the demand-source taxonomy, this document inherits the change automatically (it references, it does not copy) — no edit here is required, but the reference targets (§1, §2) must continue to resolve.
2. **Capacity-band re-tune.** If `capacity-model.md` §9 re-tunes the demand-supply RAG bands, or `sprint-defaults.md` §1.2 re-tunes the planned-utilization cap, the §3 routing rule inherits the new band automatically (it reads the live value by role). Re-run the link-resolution check if either file moves.
3. **Source relocation.** If the WSJF formula is ever promoted to a kernel location (for example a future `core/standards/`), or the capacity model moves, re-point the references in §1/§2/§3 and this section to the new home and re-run the link-resolution check.

---

## Provenance

- **Origin:** created to give the PPM Agent a codified home for the **capacity-aware intake-routing rule** and the **trade-off-analysis output contract** at the in-flight intake surface (PMO Upscale gap analysis, Domain 2 — the highest-scored gap). The governance rubrics it applies — WSJF/CoD, business-case tiers, demand-source taxonomy, capacity bands — are owned canonically by the intake desk's `intake-governance.md` and the delivery-engine `capacity-model.md` and are consumed here by role, not re-derived.
- **Twin relationship:** this document is the intake-side counterpart of [`escalation-thresholds.md`](escalation-thresholds.md) (the RAID-side downstream-prioritization reference). Both reference a canonical scale owned by another skill and add only the PPM-Agent routing layer on top.
- **Naming rationale:** named `ppm-intake-governance.md` (not `intake-governance.md`) so the basename is distinct from the intake desk's canonical front-door policy document — the two are genuinely different content (front-door demand-funnel policy vs. in-flight portfolio-intake application), and a shared basename would mislabel them as the same document.
