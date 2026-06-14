<!-- reference-durability: allow-link -->
# Intake Governance

## Purpose

Canonical reference for how the intake desk attaches **portfolio-prioritization governance** to an intake item once that item is a **fundable unit of demand** (a project or initiative). The intake desk is the platform's single intake front door; its conversational elicitation loop (`elicitation-loop.md`) turns one half-formed idea into one well-formed, correctly-typed work item. This document is the **policy layer the desk consults beside that loop** — the scoring, SLA, and demand-discipline rules the desk applies when an item carries enough investment weight to need a business case. It is the **doc-of-record** for six things the intake desk owns:

- **(a)** the platform's **WSJF formula** and its component-scoring rubric (§2);
- **(b)** the **business-case tier** partition — Tier 1 / Tier 2 / Tier 3 — and its placement rule (§1);
- **(c)** the **intake-triage SLA** table keyed to business-case tier (§3);
- **(d)** the **6-type demand-source taxonomy** (§4);
- **(e)** the **intake-side application** of the rubber-stamp anti-pattern (the `>95%` approval-rate signal) as a demand-discipline health check (§5);
- **(f)** the **Cost-of-Delay elicitation prompts** the desk uses to populate the WSJF inputs conversationally (§6).

**References (this document does NOT re-derive these):**

- **Cost of Delay** *as a framework* — owned by the framework registry [`framework-catalog.md`](../../../../core/specs/framework-catalog.md) ("Cost of Delay (Reinertsen 2009)" row). This document operationalizes that framework into the WSJF formula; the framework's provenance and version anchor stay at the catalog.
- **The rubber-stamp `>95%` / 10–20%-kill thresholds** — owned by [`gate-checklists.md`](../../delivery-engine/references/gate-checklists.md) (delivery-engine, "Rubber-stamping" anti-pattern). §5 **reuses** those numbers for the intake surface; it does not mint a second threshold.
- **The "Demand flooding" intake anti-pattern + the intake-WIP / T-shirt-sizing remediation** — owned by [`backlog-health.md`](../../delivery-engine/references/backlog-health.md) (delivery-engine). §3 and §5 **compose with** that signal; they do not restate it.
- **The altitude / work-item-type classification** — owned by the intake desk's own [`elicitation-loop.md`](elicitation-loop.md) (altitude model, 5-test, WHAT/HOW boundary) and [`type-map.md`](type-map.md) (altitude → type table). This document **references** that classification; it does not duplicate it.

**Consumed by:** intake-desk SKILL.md (a Reference-files row points here) and the elicitation loop's Phase 2/3 (`elicitation-loop.md`) when the landed item is a fundable demand unit — at that point the desk attaches a business-case tier, a WSJF estimate, and a triage SLA to the item before it confirms and emits.

**Boundary note (load-bearing — prevents axis collision).** A **business-case tier is an investment/funding axis that is orthogonal to the altitude axis.** Altitude (initiative / story / task / bug, per `elicitation-loop.md`) answers *"how big is the idea, and what type is it?"*; business-case tier answers *"what governance weight does this demand carry?"* A single intake item has **both** — a project-altitude `improvement` is also a Tier-2 business-case demand. State the tier as a separate attribute; do not fold it into the altitude model or re-derive the altitude model here. (This mirrors `escalation-thresholds.md` §3's "age is an orthogonal axis, not a modifier of the score.")

> **Why the line-1 `allow-link` marker is present (and must stay).** This file is K1 codified-knowledge (it lives under `*/skills/*/references/`), which makes it durable corpus. It carries net-new markdown links to cross-skill sources — the references to `framework-catalog.md`, `gate-checklists.md`, and `backlog-health.md` in this Purpose and below. The Reference Durability Standard flags any markdown link on a net-new line in a durable-corpus file as a **Class L** finding; the sanctioned suppressor for Class L is exactly the line-1 `<!-- reference-durability: allow-link -->` marker. That marker is **mandatory here, not stylistic** (the reference-durability CI workflow is a required status check). Do **not** remove it to "match the sibling intake-desk refs" (none of `elicitation-loop.md` / `output-contract.md` / `type-map.md` / `technique-library.md` carry it) — those siblings carry no cross-skill links; this file does, and the standard, not the directory, governs.

---

## 1. Business-Case Tiering

The first canonical contribution: a deterministic partition that assigns every fundable intake item a **business-case tier**, which fixes the rigor of the case the desk requires and the SLA it commits to (§3). The tier is a **total, disjoint partition** keyed to a primary band (effort/cost or funding magnitude): every item lands in exactly one tier, with no gaps and no overlaps.

| Tier | Name | Trigger band (primary: effort/cost or funding magnitude) | Business-case rigor required | Approval authority |
|---|---|---|---|---|
| **Tier 1** | Lightweight / standard demand | Small, run-rate, or below the project threshold (single-team, bounded effort; no dedicated funding) | One-line value statement + acceptance criteria; no formal case | Service / intake owner |
| **Tier 2** | **Project-class demand** | **A funded, budgeted project: an initiative that crosses the project threshold but sits below portfolio scale** | **WSJF estimate (§2) + Cost-of-Delay components + a brief written business case** | **PMO / Program ([OPERATOR_NAME])** |
| **Tier 3** | Portfolio / major-investment demand | Cross-portfolio, major capital, or strategically load-bearing | Full business case + portfolio review | Portfolio / Steering |

**Deterministic placement rule:** `tier = band_of(<primary funding/effort signal>)`. The band edges are non-overlapping, so the classification is reproducible and is not a judgment call.

**`[budget]` → Tier 2 binding (the acceptance-criteria anchor).** A `[budget]` intake request denotes a **funded project at project scale** — it crosses the project threshold (it has dedicated budget, so it is more than run-rate Tier-1 work) but does not reach portfolio scale (it is not cross-portfolio or major capital). **A `[budget]` project is a Tier-2 (project-class) demand by definition.** This mapping is stated as a rule, not inferred per-conversation, so the desk classifies it the same way every time.

**Where the tier attaches in the loop.** The tier is set at or after the Phase 2 type-landing gate of the elicitation loop ([`elicitation-loop.md`](elicitation-loop.md)) — once altitude is known and the item has landed as a container/initiative-altitude `improvement` (per the altitude → type table in [`type-map.md`](type-map.md)). The desk reads the altitude from the loop; it does not re-derive altitude here.

---

## 2. WSJF Formula

The central canonicalization. WSJF (Weighted Shortest Job First) is the economic-sequencing model the platform uses to rank fundable demand. Before this document, "WSJF" appeared across the corpus only as a *framework name* and a *named sequencing technique* — the formula itself was never defined. This section is its canonical definition. The platform adopts the SAFe / Reinertsen formula:

```
WSJF = Cost of Delay (CoD) ÷ Job Size

where  CoD = User-Business Value + Time Criticality + Risk Reduction / Opportunity Enablement (RR|OE)
```

A **higher WSJF means higher economic priority** (do it first): high value that decays quickly, achievable in a small job, sequences ahead of low value in a large job.

**Component-scoring rubric.** Each of the four inputs is scored on the **relative Fibonacci scale `{1, 2, 3, 5, 8, 13, 20}`** (the SAFe-standard relative scale), scored *relatively across the candidate set under consideration* — not on an absolute unit. The three CoD components are summed; Job Size is the divisor.

| Component | What it captures | Scoring prompt (relative across the candidate set) |
|---|---|---|
| **User-Business Value** | The value of having it — revenue, cost saved, user pain relieved | "How much value, relative to the other things in the queue?" |
| **Time Criticality** | How fast the value decays — deadlines, market windows, dependency clocks | "Does the value drop if we wait? Is there a fixed window?" |
| **Risk Reduction / Opportunity Enablement (RR\|OE)** | Risk retired or future work unblocked | "Does this reduce a risk or unlock otherwise-blocked work?" |
| **Job Size** | Relative effort to deliver (the divisor) | "Rough relative effort vs. the other candidates — relative size, not hours?" |

**Worked example (mandatory — makes the estimate reproducible).** For a `[budget]` project, scored relatively: User-Business Value = **8**, Time Criticality = **5**, RR|OE = **3**, Job Size = **13**.

```
CoD  = 8 + 5 + 3          = 16
WSJF = CoD ÷ Job Size
     = 16 ÷ 13            ≈ 1.23
```

So this `[budget]` project estimates to **WSJF ≈ 1.23**. The arithmetic is shown inline so the estimate is a definite result; the specific values are illustrative (the desk scores them relatively per candidate set), but a worked sum is always produced.

**Cross-skill consistency note.** This is the **platform-canonical WSJF**. Where delivery-engine says "apply WSJF for sequencing" ([`backlog-health.md`](../../delivery-engine/references/backlog-health.md)) and where the requirements / process-designer references name "WSJF" as a prioritization option, those names now resolve to *this* definition. This document is the single registered home of the formula — other surfaces reference the name, they do not re-derive a competing formula (the "register, don't re-derive" duplicate-source discipline).

**Framework-catalog coupling.** WSJF rides the existing "Cost of Delay (Reinertsen 2009)" lineage registered in [`framework-catalog.md`](../../../../core/specs/framework-catalog.md); that row's `canonical_doc` points here, since this document operationalizes Cost of Delay into the WSJF formula. The framework's *provenance* (edition, version anchor, review cadence) stays at the catalog — this document owns the *operational formula*, not the framework citation. The maintenance coupling is recorded in §8.

---

## 3. Intake SLAs

The desk's commitment for how fast an intake item gets a triage disposition, keyed to the item's business-case tier.

| Business-case tier | Triage SLA (intake logged → triage disposition rendered) |
|---|---|
| Tier 1 — lightweight | 5 business days |
| **Tier 2 — project-class** | **3 business days** |
| Tier 3 — portfolio | 1–2 business days (expedited — the investment size warrants a fast disposition) |

**`[budget]` → 3-day binding.** A `[budget]` project is Tier 2 (§1), so its triage SLA is **3 business days**. This is stated as a hard row so the SLA is deterministic, not negotiated per item.

**What "triage SLA" means (the clock).** The clock **starts** when the intake item is logged (the desk emits it to the work tracker per `output-contract.md`) and **stops** when a triage disposition is rendered against it. Measured in **business days**. The SLA is a *time-to-triage-decision* commitment, not a time-to-delivery commitment.

**The health metric this SLA is measured against.** A chronically rising time-to-triage is the **"Demand flooding"** signal owned by delivery-engine [`backlog-health.md`](../../delivery-engine/references/backlog-health.md) ("average triage time exceeding SLA"). This SLA is the threshold that signal is measured against; the signal and its volume-side remediation (intake WIP limits, T-shirt sizing) live there — this document composes with it, it does not restate it.

**SLA-breach handling.** A single breach is an operational miss; a *chronic* breach is a demand-discipline signal — route it to the health check in §5 (a flooded *and* undiscriminating funnel is the compound failure).

---

## 4. Demand-Source Taxonomy

A 6-type classification of where intake demand originates, so the desk can tag each item's demand source. The tag feeds prioritization (different sources score very differently on the CoD components) and the anti-pattern distribution check in §5. The six types are **mutually exclusive and collectively exhaustive (MECE)** — every intake item maps to exactly one.

| # | Demand source | What it is | Typical type / altitude emphasis (per `type-map.md`) |
|---|---|---|---|
| 1 | **Strategic / planned** | Roadmap-driven initiatives, OKRs, deliberate change-the-business investment | initiative-altitude `improvement` |
| 2 | **Operational / BAU (run-the-business)** | Keep-the-lights-on, recurring operational work | task-altitude `improvement` (run) |
| 3 | **Defect / corrective** | Something is broken and needs fixing | `bug` |
| 4 | **Regulatory / compliance** | Mandated by policy, law, or audit | `improvement` (often Time-Criticality-high) |
| 5 | **Stakeholder request / enhancement** | Ad-hoc feature or change asks from stakeholders | story-altitude `improvement` |
| 6 | **Technical / debt & risk reduction** | Refactoring, debt paydown, risk mitigation | `improvement` (RR\|OE-driven) |

**Tie to the altitude model (compose, don't duplicate).** The "type / altitude emphasis" column references the altitude → type table in [`type-map.md`](type-map.md). The demand source is an **additional tag** on the item — it does not replace the work-item type or the altitude; an item has all three.

**MECE + tie-break rule.** Every intake item maps to **exactly one** demand source. When an item could read as two (the common case is a compliance-driven defect), tag it by **what is driving the work**: a defect that exists only because a regulator mandated the fix tags as **#4 Regulatory** (the mandate is the driver); a defect surfaced through normal operation tags as **#3 Defect**. State the driver in one line when the tag is non-obvious.

The count is fixed at **six** by the standard ITSM/PPM demand-management taxonomy and by the originating acceptance criteria ("demand source taxonomy (6 types)"). A coarser 3-type run/change/defect cut loses the regulatory and debt-reduction distinctions that drive differentiated CoD scoring; a per-stakeholder list is not collectively exhaustive — six is the MECE set that maps cleanly onto the altitude → type table.

---

## 5. Anti-Pattern Detection: the `>95%` approval-rate signal (REUSE, do not re-derive)

The intake-side demand-discipline health check. The platform already owns the rubber-stamp threshold; this section **reuses it for the intake surface** rather than minting a competing number.

- **Signal:** an intake approval rate **`>95%`** (almost nothing is rejected, deferred, or recycled at intake) indicates **rubber-stamping** — the demand funnel is not discriminating, so prioritization is theater. A front door that approves everything is not governing intake.
- **Healthy target (reused verbatim from [`gate-checklists.md`](../../delivery-engine/references/gate-checklists.md)):** a healthy decision distribution **kills or recycles 10–20%** of intake demand. **Track the decision distribution**, do not merely count approvals.
- **Reuse is explicit, not re-derived.** The `>95%` rubber-stamp threshold and the 10–20% healthy-kill target are **adopted from `gate-checklists.md` for the intake surface; they are not re-derived here.** The gate-checklists entry frames the pathology at the *phase gate*; this is the same pathology one stage earlier, at *demand intake*. Reusing the single source prevents two `>95%` definitions from drifting apart.
- **Compose with "Demand flooding" (the sibling signal).** `gate-checklists.md` owns the *discrimination* pathology (this `>95%` signal); [`backlog-health.md`](../../delivery-engine/references/backlog-health.md) owns the *volume* pathology ("Demand flooding"). A **high approval rate plus a rising triage-SLA breach (§3) together** mean the funnel is both flooded and undiscriminating — the compound demand-discipline failure.
- **Remediation:** publish explicit intake **kill / defer criteria**; require **"if we do this, what do we stop?"** for every new fundable item (the MoSCoW discipline `backlog-health.md` prescribes); apply a **WIP limit on the intake queue**. The aim is a discriminating funnel, not a faster rubber stamp.

---

## 6. Cost-of-Delay Elicitation Prompts

The conversational bridge between the desk's *elicitation* nature and the *scoring* §2 needs. When an item is Tier 2 or Tier 3, the desk populates the three CoD components (and Job Size) by asking — these are the prompts, aligned to the BABOK elicitation discipline the desk already uses ([`technique-library.md`](technique-library.md)).

| CoD component | Elicitation prompt (what the desk asks) |
|---|---|
| **User-Business Value** | "Who benefits, and how much — revenue, cost saved, user pain relieved? Relative to the other things in the queue?" |
| **Time Criticality** | "Does the value decay if we wait? Is there a deadline, a market window, or a dependency clock?" |
| **Risk Reduction / Opportunity Enablement** | "Does doing this reduce a risk, or unlock future work that is otherwise blocked?" |
| **Job Size** | "Rough relative effort versus the other candidates — not hours, relative size?" |

**WHAT/HOW boundary (consistent with the desk's doctrine).** These prompts elicit *value and size inputs* (WHAT), not solution mechanism (HOW). Mechanism stays deferred to Stage 5 Solutioning per the desk's WHAT/HOW boundary (`elicitation-loop.md`).

**Unresolved input → owned assumption, never a fabricated score.** If a component cannot be scored from the conversation, render it as an owned handoff (`[ASSUMPTION – CONFIRM] <the input> — owner: <stage> — to close: <what resolves it>`) per the desk's existing assumption-handoff pattern — never invent a confident number.

**One-batch cadence.** Apply the desk's cadence discipline (small batches, one sharp question over three that circle, per the SKILL.md guardrails) — CoD scoring is four inputs, not a question battery.

---

## 7. Acceptance-Criteria Trace

The worked, end-to-end trace for the acceptance-criteria scenario, modeled on the mandatory worked examples in `escalation-thresholds.md` §2/§4. It is the load-bearing artifact that proves the three acceptance-criteria outputs each fall out of a deterministic rule rather than a judgment call. Trace uses a `[PROJECT_KEY]` placeholder, not a real project key.

> **Acceptance-criteria trace (worked example, mandatory).** A user presents a **`[budget]` project** intake request for `[PROJECT_KEY]`.
> 1. **Altitude / type** (per [`elicitation-loop.md`](elicitation-loop.md) + [`type-map.md`](type-map.md)): a change-the-business initiative → initiative-altitude → `improvement` container.
> 2. **Business-case tier** (§1): a funded project crossing the project threshold but below portfolio scale → **Tier 2 (project-class)** — a `[budget]` project is Tier 2 by definition. ✓
> 3. **WSJF estimate** (§2): User-Business Value 8 + Time Criticality 5 + RR|OE 3 = CoD **16**; Job Size **13** → WSJF = 16 ÷ 13 ≈ **1.23**. ✓
> 4. **Triage SLA** (§3): Tier 2 → **3 business days**. ✓
>
> **Result:** Tier 2 · WSJF ≈ 1.23 · 3-business-day triage SLA — the three acceptance-criteria outputs, each from a deterministic rule, not judgment.

This trace is the verification artifact for Stage 7 Dev Testing: present a `[budget]` intake request and confirm the desk drives **Tier 2 classification + a WSJF estimate (with a worked sum) + a 3-day triage SLA**.

---

## 8. Cross-Skill Contract

This section makes the cross-skill dependencies visible at deploy time, per the modular-monolith public-API discipline, and enumerates the maintenance couplings.

**Inbound references (consumed here, owned elsewhere — referenced, not copied):**

- [`framework-catalog.md`](../../../../core/specs/framework-catalog.md) — Cost of Delay framework provenance and version anchor (this document operationalizes it into the WSJF formula; the catalog's CoD `canonical_doc` points here).
- [`gate-checklists.md`](../../delivery-engine/references/gate-checklists.md) — the `>95%` rubber-stamp threshold and the 10–20% healthy-kill target, reused verbatim by §5.
- [`backlog-health.md`](../../delivery-engine/references/backlog-health.md) — the "Demand flooding" anti-pattern and the intake-WIP / T-shirt-sizing remediation that §3 and §5 compose with; also the "apply WSJF for sequencing" reference §2's formula resolves.
- [`elicitation-loop.md`](elicitation-loop.md) + [`type-map.md`](type-map.md) — the altitude model and the altitude → type table that §1, §4, and §7 reference rather than re-derive.

**Adjacent (non-overlapping) prioritization surface — front-door vs. downstream.** The intake desk scores and tiers demand **at the front door** (this document). The PPM Agent's [`escalation-thresholds.md`](../../ppm-agent/references/escalation-thresholds.md) scores and escalates RAID exposure **downstream**, after work is in flight. These are the **structural twins** of one prioritization discipline applied at two points in the lifecycle — intake scores incoming demand; the PPM Agent escalates in-flight risk — and they are deliberately kept separate (per the intake-front-door boundary). This document's tier partition (§1) follows the same deterministic-partition pattern `escalation-thresholds.md` §2 establishes.

**Maintenance couplings (honor on any change to the source):**

1. **Threshold re-tune.** If `gate-checklists.md` re-tunes the `>95%` rubber-stamp threshold or the 10–20% healthy-kill target, re-sync §5 so the intake surface and the phase-gate surface do not diverge.
2. **Formula promotion.** If the WSJF formula or its scoring scale is ever promoted to a kernel location (for example a future `core/standards/`), re-point the references in §2 and this section to the new home and re-run the link-resolution check. This is the forcing function to convert the formula's home into a more durable kernel registry once a second/third consumer appears (delivery-engine already references "WSJF" — a future consumer is plausible).
3. **Framework-catalog coupling.** The [`framework-catalog.md`](../../../../core/specs/framework-catalog.md) "Cost of Delay (Reinertsen 2009)" row carries `canonical_doc` pointing here. If this document moves or is renamed, re-point that catalog row (a Check-18 registry edit).

---

## Provenance

- **Fulfills:** the intake-governance reference deliverable (#268) within the pmo-skill-reference-substrate milestone (#129).
- **Owner:** intake-desk, per the 2026-06-14 operator consolidation directive — all intake work consolidates to the intake desk as the single intake front door. This supersedes the milestone #129 description's earlier "PPM agent" framing for intake governance.
- **Architectural scope:** the intake desk's component boundary is defined in [ADR-016 (intake front-door architectural boundary)](../../../../core/ADRs/ADR-016-intake-front-door-architectural-boundary.md); this governance layer sits within that boundary — it is policy the desk *consults*, not a new front door.
- **Origin:** created to canonicalize the intake-governance content (business-case tiering, WSJF formula, intake SLAs, demand-source taxonomy, intake rubber-stamp signal, Cost-of-Delay prompts) the platform had no codified home for (PMO Upscale gap analysis, Domain 2 — highest-scored gap).
